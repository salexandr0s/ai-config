#!/usr/bin/env python3
"""Apply the existing release, deployment, infrastructure and database policy.

Inspect literal shell commands, not text mentioning commands. This is a small
heuristic, not a shell interpreter/security boundary: aliases, variable-built
commands, sourced/external scripts, interpreter code, and remote commands cannot
be resolved. It never executes the inspected text. Literal shell -c programs,
command substitutions, and shell heredocs are inspected; other heredoc contents
are data (their unquoted shell substitutions are still inspected).
"""

import json
import os
import re
import shlex
import sys


SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
HEREDOC = re.compile(r"<<(-?)[ \t]*(?:'([^']+)'|\"([^\"]+)\"|([^\s;|&<>]+))")


def words(source):
    try:
        return shlex.split(source, comments=True, posix=True)
    except ValueError:
        return []


def executable(argv):
    """Remove common literal execution wrappers, preserving read-only queries."""
    argv = list(argv)
    while argv:
        while argv and ASSIGNMENT.match(argv[0]):
            argv.pop(0)
        if not argv:
            break
        name = os.path.basename(argv[0])
        if name in {"then", "do", "else", "if", "elif", "!"}:
            argv.pop(0)
            continue
        if name in {"env", "sudo", "command", "exec", "npx"}:
            argv.pop(0)
            if name == "command" and argv[:1] in (["-v"], ["-V"]):
                return []
            value_options = {"-u", "--unset", "-C", "--chdir"} if name == "env" else set()
            if name == "sudo":
                value_options = {"-u", "--user", "-g", "--group", "-h", "--host", "-p", "--prompt"}
            if name == "exec":
                value_options = {"-a"}
            while argv and argv[0].startswith("-"):
                option = argv.pop(0)
                if option == "--":
                    break
                if option in value_options and argv:
                    argv.pop(0)
            continue
        if name in {"pnpm", "npm", "yarn"} and argv[1:2] in (["exec"], ["dlx"]):
            argv = argv[2:]
            while argv and argv[0] in {"--", "-y", "--yes", "--no-install"}:
                argv.pop(0)
            continue
        argv[0] = name.split("@", 1)[0]
        break
    return argv


def substitution_end(source, start):
    """Find the closing parenthesis of $(...), respecting literal quoted text."""
    nesting, quote, index = 1, "", start
    while index < len(source):
        char = source[index]
        if char == "\\" and quote != "'":
            index += 2
            continue
        if source.startswith("$(", index) and quote != "'":
            index = substitution_end(source, index + 2) + 1
            continue
        if quote:
            if char == quote:
                quote = ""
        elif char in "'\"":
            quote = char
        elif char == "(":
            nesting += 1
        elif char == ")":
            nesting -= 1
            if nesting == 0:
                return index
        index += 1
    return len(source)


def shell_commands(source, depth=0, expansions_only=False):
    """Split unquoted shell operators; retain quoted arguments for shlex."""
    if depth > 12:
        return
    index, quote, buffer, heredocs = 0, "", "", []
    while index < len(source):
        char = source[index]
        if char == "\\" and quote != "'":
            buffer += source[index:index + 2]
            index += 2
            continue
        if source.startswith("$(", index) and quote != "'":
            end = substitution_end(source, index + 2)
            yield from shell_commands(source[index + 2:end], depth + 1)
            buffer += "__substitution__"
            index = end + 1
            continue
        if char == "`" and quote != "'":
            end = index + 1
            while end < len(source) and source[end] != "`":
                end += 2 if source[end] == "\\" else 1
            yield from shell_commands(source[index + 1:end], depth + 1)
            buffer += "__substitution__"
            index = end + 1
            continue
        if expansions_only:
            # Quotes in an unquoted heredoc body are ordinary data: even
            # '$(command)' expands. Only the delimiter disables expansion.
            index += 1
            continue
        if quote:
            buffer += char
            if char == quote:
                quote = ""
            index += 1
            continue
        if char in "'\"":
            quote = char
            buffer += char
        elif char == "#" and (not buffer or buffer[-1].isspace()):
            end = source.find("\n", index)
            index = len(source) if end < 0 else end
            continue
        elif source.startswith("<<", index):
            match = HEREDOC.match(source, index)
            if match:
                heredocs.append((match.group(2) or match.group(3) or match.group(4),
                                 bool(match.group(1)), bool(match.group(2) or match.group(3))))
                index = match.end()
                buffer += " "
                continue
            buffer += char
        elif char in ";|&\n()":
            argv = executable(words(buffer))
            if argv and not expansions_only:
                yield argv
            buffer = ""
            if char == "\n" and heredocs:
                index += 1
                for delimiter, strip_tabs, quoted in heredocs:
                    body = ""
                    while index < len(source):
                        end = source.find("\n", index)
                        end = len(source) if end < 0 else end
                        line = source[index:end]
                        index = end + 1
                        if (line.lstrip("\t") if strip_tabs else line) == delimiter:
                            break
                        body += line + "\n"
                    is_shell = bool(argv and argv[0] in SHELLS)
                    if is_shell or not quoted:
                        yield from shell_commands(body, depth + 1, expansions_only=not is_shell)
                heredocs = []
                continue
        else:
            buffer += char
        index += 1
    if not expansions_only:
        argv = executable(words(buffer))
        if argv:
            yield argv


def inspect(source, depth=0):
    if depth > 12:
        return
    for argv in shell_commands(source):
        if argv[0] in SHELLS:
            for index, arg in enumerate(argv[1:], 1):
                if arg.startswith("-") and "c" in arg.lstrip("-") and index + 1 < len(argv):
                    yield from inspect(argv[index + 1], depth + 1)
                    break
        yield argv


def policy(argv):
    name, args = argv[0], argv[1:]
    if any(arg in {"--help", "-h", "-help"} for arg in args):
        return None
    # Only inspect the actual subcommand, not read-only arguments mentioning
    # e.g. an output named `apply`. Skip the common global option values.
    value_options = {
        "kubectl": {"--context", "--namespace", "-n", "--kubeconfig", "--server", "-s", "--user", "--cluster"},
        "helm": {"--kube-context", "--namespace", "-n", "--kubeconfig"},
        "git": {"-C", "-c", "--git-dir", "--work-tree"},
        "vercel": {"--cwd", "--scope", "--token", "-t"},
        "netlify": {"--cwd", "--site", "--auth"},
        "gh": {"--repo", "-R"},
    }.get(name, set())
    actions, index = [], 0
    while index < len(args):
        arg = args[index]
        if arg in value_options:
            index += 2
            continue
        if not arg.startswith("-"):
            actions.append(arg)
        index += 1
    vercel_read_only = {"build", "inspect", "list", "ls", "logs", "project", "projects", "env", "whoami", "help"}
    if ((name == "vercel" and "--prod" in args and (not actions or actions[0] not in vercel_read_only))
            or (name == "netlify" and actions[:1] == ["deploy"] and "--prod" in args)
            or (name == "fly" and actions[:1] == ["deploy"])
            or (name == "railway" and actions[:1] in (["up"], ["deploy"]))):
        return "request", "This targets production deployment."
    if ((name in {"terraform", "kubectl"} and actions[:1] == ["apply"])
            or (name == "helm" and actions[:1] in (["upgrade"], ["install"]))):
        return "request", "This changes live infrastructure."
    if ((name in {"supabase", "prisma"} and actions[:2] == ["db", "push"])
            or (name == "drizzle-kit" and actions[:1] == ["push"])
            or (name == "rails" and actions[:1] == ["db:migrate"])):
        return "request", "This mutates a database or schema."
    if name in {"npm", "pnpm", "yarn", "cargo"} and actions[:1] == ["publish"] and "--dry-run" not in args:
        return "warning", "This publishes externally. Confirm with the user first."
    if ((name == "docker" and actions[:1] == ["push"])
            or (name == "gh" and actions[:2] == ["release", "create"])
            or (name == "git" and actions[:1] == ["tag"] and len(actions) > 1
                and not any(arg in {"--list", "-l", "--verify", "-v", "--delete", "-d"} for arg in args))):
        return "warning", "This creates an external release artifact. Confirm with the user first."
    if name == "git" and actions[:1] == ["push"] and any(arg in {"main", "master"} for arg in actions[1:]):
        return "warning", "This pushes to the default branch. Confirm with the user first."
    return None


def main():
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        return
    if not isinstance(payload, dict) or not isinstance(payload.get("tool_input"), dict):
        return
    source = payload["tool_input"].get("command")
    if not isinstance(source, str) or not source.strip():
        return
    results = [result for argv in inspect(source) if (result := policy(argv))]
    requests = list(dict.fromkeys(message for kind, message in results if kind == "request"))
    warnings = list(dict.fromkeys(message for kind, message in results if kind == "warning"))
    output = {}
    if requests:
        decision = "ask" if sys.argv[1] == "claude" else "deny"
        reason = " ".join(requests)
        if decision == "ask":
            reason += " User approval is required for this command."
        else:
            # Codex 0.154.0 rejects `ask` and continues execution, so never emit it.
            # https://developers.openai.com/codex/hooks#pretooluse
            reason += " Blocked by ai-config: Codex hooks cannot request native approval yet. Ask the user to run this command manually."
        output["hookSpecificOutput"] = {"hookEventName": "PreToolUse",
                                        "permissionDecision": decision,
                                        "permissionDecisionReason": reason}
    if warnings:
        output["systemMessage"] = "Warnings: " + " ".join(warnings)
    if output:
        print(json.dumps(output))


if __name__ == "__main__":
    main()
