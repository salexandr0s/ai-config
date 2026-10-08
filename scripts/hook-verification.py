#!/usr/bin/env python3
"""Track tool edits and run bounded, local checks when an agent stops."""

import argparse
import ast
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time

CODE_SUFFIXES = {
    ".c", ".cc", ".cpp", ".cs", ".css", ".go", ".h", ".html", ".java",
    ".ipynb", ".js", ".json", ".jsonc", ".jsx", ".kt", ".m", ".mjs", ".cjs",
    ".php", ".pl", ".py", ".rb", ".rs", ".sh", ".sql", ".svelte",
    ".swift", ".toml", ".ts", ".tsx", ".vue", ".xml", ".yaml", ".yml", ".zsh",
}
CODE_NAMES = {"Makefile", "Dockerfile", "Justfile", "Gemfile", "Rakefile"}
CHECK_TIMEOUT = 120


def is_code(name):
    return Path(name).suffix in CODE_SUFFIXES or Path(name).name in CODE_NAMES


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_hash(path):
    try:
        if path.is_symlink():
            return digest(os.readlink(path).encode())
        return digest(path.read_bytes())
    except (FileNotFoundError, IsADirectoryError):
        return None


def git(root, *args):
    result = subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True, timeout=15,
    )
    return result.stdout if result.returncode == 0 else None


def repo_root(path):
    location = path if path.is_dir() else path.parent
    while not location.exists() and location != location.parent:
        location = location.parent
    output = git(location, "rev-parse", "--show-toplevel")
    return Path(os.fsdecode(output).strip()).resolve() if output else None


def resolve_path(value, cwd):
    path = Path(value).expanduser()
    return path if path.is_absolute() else cwd / path


def event_locations(payload):
    """Resolve explicit edit paths and simple shell workdirs without home scans."""
    cwd = Path(payload.get("cwd") or os.getcwd()).expanduser().resolve()
    tool_input = payload.get("tool_input") or {}
    if isinstance(tool_input, str):
        tool_input = {"patch": tool_input}
    locations = [cwd]
    files = []
    for key in ("cwd", "workdir"):
        if tool_input.get(key):
            cwd = resolve_path(tool_input[key], cwd).resolve()
            locations.append(cwd)
    for key in ("file_path", "path", "notebook_path"):
        if isinstance(tool_input.get(key), str):
            files.append(resolve_path(tool_input[key], cwd))
    patch = tool_input.get("patch") or tool_input.get("input") or tool_input.get("command") or ""
    if isinstance(patch, str):
        for name in re.findall(r"^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$", patch, re.M):
            files.append(resolve_path(name, cwd))
    command = tool_input.get("command") or ""
    if isinstance(command, str):
        try:
            lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|")
            lexer.whitespace_split = True
            tokens = list(lexer)
            for index, token in enumerate(tokens[:-1]):
                if token in ("cd", "-C"):
                    locations.append(resolve_path(tokens[index + 1], cwd))
        except ValueError:
            pass
    locations.extend(files)
    roots = {root for location in locations if (root := repo_root(location))}
    return roots, files


def snapshot(root, explicit_files=()):
    head = git(root, "rev-parse", "HEAD")
    status = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    if status is None:
        raise RuntimeError(f"cannot inspect Git working tree in {root}")
    names = set()
    entries = iter(status.split(b"\0"))
    for entry in entries:
        if not entry:
            continue
        names.add(os.fsdecode(entry[3:]))
        if b"R" in entry[:2] or b"C" in entry[:2]:
            names.add(os.fsdecode(next(entries)))
    for path in explicit_files:
        try:
            names.add(str(path.resolve().relative_to(root)))
        except ValueError:
            pass
    return {
        "head": os.fsdecode(head).strip() if head else None,
        "files": {name: file_hash(root / name) for name in names if is_code(name)},
    }


def changed_paths(root, before, after):
    changed = []
    candidates = before["files"].keys() | after["files"].keys()
    if before["head"] != after["head"] and after["head"]:
        if before["head"]:
            output = git(root, "diff", "--name-only", "-z", before["head"], after["head"])
        else:
            output = git(root, "ls-tree", "-r", "--name-only", "-z", after["head"])
        candidates.update(name for name in os.fsdecode(output or b"").split("\0") if is_code(name))
    for name in candidates:
        old_hash = before["files"].get(name)
        if name not in before["files"] and before["head"]:
            content = git(root, "show", f"{before['head']}:{name}")
            old_hash = digest(content) if content is not None else None
        if old_hash != file_hash(root / name):
            changed.append(name)
    return changed


def tool_key(payload):
    return str(payload.get("tool_use_id") or payload.get("tool_call_id") or "latest")


def record_pre(state, payload):
    roots, files = event_locations(payload)
    pending = state.setdefault("before", {})
    key = tool_key(payload)
    if key in pending:
        fold_snapshots(state, pending.pop(key))
    pending[key] = {
        str(root): snapshot(root, files) for root in roots
    }


def fold_snapshots(state, before):
    dirty = state.setdefault("dirty", {})
    for location, old in before.items():
        root = Path(location)
        paths = changed_paths(root, old, snapshot(root))
        if paths:
            state.setdefault("base_heads", {}).setdefault(location, old["head"])
            dirty[location] = sorted(set(dirty.get(location, [])) | set(paths))


def record_post(state, payload):
    before = state.setdefault("before", {}).pop(tool_key(payload), {})
    fold_snapshots(state, before)


def local_tool(root, name):
    binary = root / "node_modules" / ".bin" / name
    return str(binary) if binary.is_file() and os.access(binary, os.X_OK) else None


def project_groups(root, names):
    manifests = ("package.json", "Cargo.toml", "pyproject.toml", "setup.py")
    groups = {}
    for name in names:
        directory = (root / name).parent
        if any((root / manifest).is_file() for manifest in manifests):
            directory = root
        while directory != root and not any((directory / manifest).is_file() for manifest in manifests):
            directory = directory.parent
        groups.setdefault(directory, []).append(str((root / name).relative_to(directory)))
    return groups


def check_commands(root):
    """Use existing quick scripts or installed checkers; never install tools."""
    commands, notes = [], []
    package = root / "package.json"
    if package.is_file():
        scripts = json.loads(package.read_text()).get("scripts", {})
        manager = next((name for lock, name in (
            ("bun.lock", "bun"), ("bun.lockb", "bun"),
            ("pnpm-lock.yaml", "pnpm"), ("yarn.lock", "yarn"),
        ) if (root / lock).exists()), "npm")
        selected = ["verify:quick"] if "verify:quick" in scripts else [
            name for name in ("typecheck", "lint") if name in scripts
        ]
        if selected:
            if shutil.which(manager):
                commands.extend(([manager, "run", name], f"{manager} run {name}") for name in selected)
            else:
                notes.append(f"{manager} unavailable; cannot run configured scripts")
        if "verify:quick" not in scripts:
            if "typecheck" not in scripts and not (root / "tsconfig.json").exists():
                notes.append("no TypeScript type checker configured")
            if "typecheck" not in scripts and (root / "tsconfig.json").exists():
                binary = local_tool(root, "tsc")
                if binary:
                    commands.append(([binary, "--noEmit"], "tsc --noEmit"))
                else:
                    notes.append("TypeScript configured but local tsc unavailable")
            eslint = list(root.glob("eslint.config.*")) + list(root.glob(".eslintrc*"))
            if "lint" not in scripts and eslint:
                binary = local_tool(root, "eslint")
                if binary:
                    commands.append(([binary, ".", "--quiet"], "eslint . --quiet"))
                else:
                    notes.append("ESLint configured but local eslint unavailable")
    elif (root / "Cargo.toml").is_file():
        if shutil.which("cargo"):
            commands.append((["cargo", "check", "--offline"], "cargo check --offline"))
        else:
            notes.append("cargo unavailable; cannot check Rust project")
    elif (root / "pyproject.toml").is_file() or (root / "setup.py").is_file():
        for binary in ("ruff", "mypy"):
            if shutil.which(binary):
                arguments = [binary, "check", "."] if binary == "ruff" else [binary, "."]
                commands.append((arguments, " ".join(arguments)))
        if not commands:
            notes.append("ruff and mypy unavailable; cannot run Python project checks")
    if not commands:
        notes.append("no runnable project quick checker; checking touched file syntax where supported")
    return commands, notes


def syntax_checks(root, names, deadline):
    failures = []
    supported = 0
    for name in names:
        path = root / name
        if not path.is_file():
            continue
        try:
            if path.suffix in (".json", ".ipynb"):
                json.loads(path.read_text())
            elif path.suffix == ".py":
                ast.parse(path.read_text(), filename=str(path))
            elif path.suffix == ".toml":
                import tomllib
                tomllib.loads(path.read_text())
            elif path.suffix in (".sh", ".zsh"):
                shell = "zsh" if path.suffix == ".zsh" else "bash"
                result = run_check([shell, "-n", str(path)], root, deadline)
                if result:
                    failures.append(f"{name}: {result}")
            else:
                continue
            supported += 1
        except (ValueError, SyntaxError, OSError, ImportError) as error:
            failures.append(f"{name}: {error}")
    return failures, supported


def run_check(command, root, deadline, allowed_codes=(0,)):
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        return f"verification exceeded {CHECK_TIMEOUT}s time budget"
    try:
        process = subprocess.Popen(
            command, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, start_new_session=True,
        )
        try:
            stdout, stderr = process.communicate(timeout=remaining)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate()
            return f"timed out within {CHECK_TIMEOUT}s verification budget"
    except OSError as error:
        return str(error)
    if process.returncode not in allowed_codes:
        output = "\n".join((stdout + stderr).splitlines()[-40:])
        return f"exit {process.returncode}\n{output}".rstrip()
    return None


def verify_stop(state, payload):
    # Failed tools and formatter timeouts may never deliver a post event.
    for before in state.pop("before", {}).values():
        fold_snapshots(state, before)
    dirty = state.get("dirty", {})
    if not dirty:
        return
    fingerprint = digest(json.dumps({
        location: {name: file_hash(Path(location) / name) for name in names}
        for location, names in sorted(dirty.items())
    }, sort_keys=True).encode())
    if fingerprint == state.get("last_checked"):
        if state.get("last_failed"):
            print("[verify] Previous verification failed and files are unchanged; repeated Stop is allowed. Report the failure explicitly.", file=sys.stderr)
        return
    deadline = time.monotonic() + CHECK_TIMEOUT
    failures, notes = [], []
    for location, names in dirty.items():
        root = Path(location)
        diff_args = ["git", "diff", "--check"]
        base = state.get("base_heads", {}).get(location)
        if base:
            diff_args.append(base)
        else:
            result = run_check(["git", "diff", "--cached", "--check", "--", *names], root, deadline)
            if result:
                failures.append(f"{root}: git diff --cached --check\n{result}")
        result = run_check([*diff_args, "--", *names], root, deadline)
        if result:
            failures.append(f"{root}: git diff --check\n{result}")
        tracked = set(os.fsdecode(git(root, "ls-files", "-z") or b"").split("\0"))
        for name in names:
            if (not base or name not in tracked) and (root / name).is_file():
                result = run_check(["git", "diff", "--no-index", "--check", "--", "/dev/null", name], root, deadline, (0, 1))
                if result:
                    failures.append(f"{root}: git diff --check for {name}\n{result}")
        for project, project_names in project_groups(root, names).items():
            try:
                commands, project_notes = check_commands(project)
            except (ValueError, OSError) as error:
                commands, project_notes = [], []
                failures.append(f"{project}: cannot read project checker configuration: {error}")
            notes.extend(f"[verify] {project}: {note}" for note in project_notes)
            for command, label in commands:
                result = run_check(command, project, deadline)
                if result:
                    failures.append(f"{project}: {label}\n{result}")
            syntax_failures, count = syntax_checks(project, project_names, deadline)
            failures.extend(f"{project}: {failure}" for failure in syntax_failures)
            if not commands and not count:
                notes.append(f"[verify] {project}: no syntax checker available for touched files; manual verification required")
    for note in notes:
        print(note, file=sys.stderr)
    state["last_checked"] = fingerprint
    state["last_failed"] = bool(failures)
    if failures:
        blocks = state.get("stop_blocks", 0) if payload.get("stop_hook_active") else 0
        reason = "Final verification failed. Fix or explicitly report these issues before claiming success:\n" + "\n\n".join(failures)
        if blocks < 2:
            state["stop_blocks"] = blocks + 1
            print(json.dumps({"decision": "block", "reason": reason}))
        else:
            print(f"[verify] Stop retry limit reached. {reason}", file=sys.stderr)
    else:
        state["dirty"] = {}
        state["base_heads"] = {}
        state["stop_blocks"] = 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--agent", required=True, choices=("claude", "codex"))
    parser.add_argument("event", choices=("pre", "post", "stop", "session-end"))
    args = parser.parse_args()
    try:
        payload = json.load(sys.stdin)
        session = payload.get("session_id")
        if not session:
            print("[verify] Missing session_id; edit tracking unavailable.", file=sys.stderr)
            return 0
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "ai-config" / "hook-verification"
        cache.mkdir(parents=True, exist_ok=True, mode=0o700)
        state_path = cache / f"{args.agent}-{digest(str(session).encode())}.json"
        with state_path.with_suffix(".lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            state = json.loads(state_path.read_text()) if state_path.exists() else {}
            if args.event == "session-end":
                state_path.unlink(missing_ok=True)
                return 0
            {"pre": record_pre, "post": record_post, "stop": verify_stop}[args.event](state, payload)
            temporary = state_path.with_suffix(".tmp")
            temporary.write_text(json.dumps(state))
            temporary.replace(state_path)
        return 0
    except (ValueError, OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"[verify] Hook could not complete: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
