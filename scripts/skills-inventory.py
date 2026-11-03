#!/usr/bin/env python3
"""Check the committed skill catalog and report local installation differences."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ("claude", "codex")
SKIP_DIRS = {".git", "node_modules", "__pycache__"}
SKIP_FILES = {".DS_Store"}
MANIFEST = "skills-manifest.json"
DOC = "docs/skills.md"


class InventoryError(ValueError):
    """A missing or invalid skill source or alias."""


def inside(path: Path, root: Path) -> bool:
    return path.resolve().is_relative_to(root.resolve())


def relative(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def tree(path: Path, root: Path | None = None) -> tuple[str, int]:
    """Hash names, file bytes, and literal aliases, including nested resources."""
    records = []
    for base, dirs, files in os.walk(path, followlinks=False):
        dirs[:] = sorted(name for name in dirs if name not in SKIP_DIRS)
        for name in sorted([*files, *(name for name in dirs if (Path(base) / name).is_symlink())]):
            item = Path(base) / name
            if name in SKIP_FILES:
                continue
            logical = item.relative_to(path).as_posix()
            if item.is_symlink():
                target = os.readlink(item)
                if root is not None and (os.path.isabs(target) or not item.exists() or not inside(item, root)):
                    raise InventoryError(f"Invalid relative skill alias: {logical}")
                value = "link:" + target
            else:
                executable = "x" if item.stat().st_mode & 0o111 else "-"
                value = "file:" + executable + ":" + hashlib.sha256(item.read_bytes()).hexdigest()
            records.append((logical, value))
    encoded = json.dumps(sorted(records), separators=(",", ":"), ensure_ascii=False).encode()
    return hashlib.sha256(encoded).hexdigest(), len(records)


def metadata(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.DOTALL)
    if match is None:
        raise InventoryError("SKILL.md requires YAML frontmatter")
    fields = {}
    lines = match.group(1).splitlines()
    for index, line in enumerate(lines):
        field = re.match(r"^(name|description|version|license):[ \t]*(.*)$", line)
        if field is None:
            continue
        key, value = field.groups()
        if value in {"|", ">", "|-", ">-"}:
            continuation = []
            for extra in lines[index + 1:]:
                if extra and not extra[0].isspace():
                    break
                continuation.append(extra.strip())
            value = " ".join(continuation)
        fields[key] = value.strip().strip("\"'")
    for key in ("name", "description"):
        if not fields.get(key):
            raise InventoryError(f"SKILL.md requires {key}")
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", fields["name"]):
        raise InventoryError("Skill name must use lowercase words separated by hyphens")
    return fields


def check_references(path: Path, root: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for value in re.findall(r'\]\(([^\s)]+)(?:\s+"[^"]*")?\)', text):
        if re.match(r"^[a-z]+:", value) or value.startswith(("#", "/")):
            continue
        target = value.split("#", 1)[0]
        if any(symbol in target for symbol in "<>{}"):
            continue
        destination = path.resolve().parent / target
        if not inside(destination, root) or not destination.exists():
            raise InventoryError(f"Missing or external skill reference: {target}")


def scan(root: Path) -> dict:
    root = root.resolve()
    packages = {}
    bindings = {}
    for tool in TOOLS:
        entries = []
        declared_names = set()
        for entry in sorted((root / tool / "skills").iterdir()):
            if entry.name.startswith("."):
                continue
            if not entry.is_dir() or not (entry / "SKILL.md").is_file():
                raise InventoryError(f"{tool}/{entry.name}: missing SKILL.md or broken binding")
            if not inside(entry, root) or (entry.is_symlink() and os.path.isabs(os.readlink(entry))):
                raise InventoryError(f"{tool}/{entry.name}: binding must be a relative repository alias")
            source = entry.resolve()
            path = relative(source, root)
            fields = metadata(source / "SKILL.md")
            if fields["name"] in declared_names:
                raise InventoryError(f"{tool}: duplicate declared skill name {fields['name']}")
            declared_names.add(fields["name"])
            check_references(source / "SKILL.md", root)
            digest, count = tree(source, root)
            packages[path] = {
                "path": path, "name": fields["name"], "description": fields["description"],
                "tree_sha256": digest, "files": count,
                "license_files": sorted(p.relative_to(source).as_posix() for p in source.rglob("*")
                                        if p.is_file() and p.name.lower().startswith(("license", "notice"))
                                        and not SKIP_DIRS.intersection(p.relative_to(source).parts)),
            }
            package_json = source / "package.json"
            if package_json.is_file():
                package = json.loads(package_json.read_text())
                if not isinstance(package, dict) or not isinstance(package.get("name"), str):
                    raise InventoryError(f"{path}: package.json requires a package name")
                packages[path]["package"] = {key: package[key] for key in ("name", "version", "private") if key in package}
            if fields.get("version"):
                packages[path]["version"] = fields["version"]
            if fields.get("license"):
                packages[path]["declared_license"] = fields["license"]
            entries.append({"id": entry.name, "name": fields["name"], "path": relative(entry, root), "source": path})
        bindings[tool] = entries
    used = {entry["source"] for entries in bindings.values() for entry in entries}
    for package in (root / "shared/skills").iterdir():
        if package.is_dir() and not package.name.startswith(".") and relative(package, root) not in used:
            raise InventoryError(f"Shared skill has no tool binding: {package.name}")
    return {
        "counts": {"unique_skills": len({entry["id"] for entries in bindings.values() for entry in entries}),
                   "claude_bindings": len(bindings["claude"]), "codex_bindings": len(bindings["codex"]),
                   "source_packages": len(packages), "shared_packages": sum(path.startswith("shared/") for path in packages)},
        "packages": [packages[path] for path in sorted(packages)], "bindings": bindings,
    }


def assemble(root: Path, previous: dict) -> dict:
    actual = scan(root)
    saved = {item["path"]: item for item in previous.get("packages", [])}
    for item in actual["packages"]:
        old = saved.get(item["path"], {})
        item["provenance"] = old.get("provenance", {"kind": "repository-snapshot", "upstream": None,
                                                   "note": "Existing source; no upstream revision is asserted."})
        item["license"] = old.get("license", "NOASSERTION")
        notices = dict(old.get("notice_sha256", {}))
        for name in item["license_files"]:
            notices.setdefault(name, hashlib.sha256((root / item["path"] / name).read_bytes()).hexdigest())
        for name, digest in notices.items():
            if Path(name).is_absolute() or ".." in Path(name).parts:
                raise InventoryError("Preserved notice path must stay inside its package")
            notice = root / item["path"] / name
            if not notice.is_file() or hashlib.sha256(notice.read_bytes()).hexdigest() != digest:
                raise InventoryError(f"Preserved notice changed or missing: {item['path']}/{name}")
        item["notice_sha256"] = notices
    return {"schema_version": 1, **actual, "external_skills": previous.get("external_skills", [])}


def documentation(manifest: dict) -> str:
    counts = manifest["counts"]
    lines = ["# Skill catalog", "", "[Project overview](../README.md)", "",
             f"{counts['unique_skills']} skill bindings by name, available through {counts['claude_bindings']} Claude and {counts['codex_bindings']} Codex entries. "
             f"Shared source packages: {counts['shared_packages']}. Tool-specific adaptations remain separate.", "",
             "This file is generated from `skills-manifest.json`. Run `python3 scripts/skills-inventory.py --check` to check aliases, resources and full package hashes. "
             "After an intentional source change, review the diff and run `python3 scripts/skills-inventory.py --refresh`.", "",
             "## Included skills", "", "Binding names follow the existing tool directories. Some upstream skills declare a different name in frontmatter; both are recorded in the manifest.", "",
             "| Binding | Claude | Codex | Source |", "| :--- | :---: | :---: | :--- |"]
    by_id = {}
    for tool, entries in manifest["bindings"].items():
        for entry in entries:
            by_id.setdefault(entry["id"], {})[tool] = entry["source"]
    for name, entries in sorted(by_id.items()):
        sources = sorted(set(entries.values()))
        links = " · ".join(f"[{path.split('/')[0]}](../{path})" for path in sources)
        lines.append(f"| `{name}` | {'✓' if 'claude' in entries else ''} | {'✓' if 'codex' in entries else ''} | {links} |")
    lines.extend(["", "## External skills", "", "These installed tools are accounted for but their text is not redistributed in this repository.", "",
                  "| Skill | Source | Reason |", "| :--- | :--- | :--- |"])
    for entry in manifest["external_skills"]:
        lines.append(f"| `{entry['id']}` | [{entry['source_label']}]({entry['source']}) | {entry['reason']} |")
    lines.extend(["", "## Updating and checking", "", "```sh", "python3 scripts/skills-inventory.py --check",
                  "python3 scripts/skills-inventory.py --check --installed", "```", "",
                  "The installed comparison is read-only. It lists missing repository entries, missing local bindings, and content differences without replacing local copies. "
                  "Assistant-managed hidden system skills are counted separately. Local formatter changes can produce a different package hash without changing the instructions.", "",
                  "The manifest records full package digests and preserved license files. An installed snapshot without a known upstream revision is labelled as such; no remote freshness claim is made. "
                  "`NOASSERTION` means that this catalog does not assign a license to the package. Retained upstream notices and licenses govern third-party content.", ""])
    return "\n".join(lines)


def compare_installed(root: Path, manifest: dict, homes: dict[str, Path]) -> dict:
    result = {}
    external = {entry["id"] for entry in manifest["external_skills"]}
    for tool in TOOLS:
        home = homes[tool]
        expected = {item["id"]: root / item["source"] for item in manifest["bindings"][tool]}
        local = {item.name: item for item in home.iterdir() if not item.name.startswith(".")} if home.is_dir() else {}
        different = []
        for name in sorted(local.keys() & expected.keys()):
            if not (local[name] / "SKILL.md").is_file() or tree(local[name])[0] != tree(expected[name])[0]:
                different.append(name)
        system = home / ".system"
        result[tool] = {
            "installed": len(local), "missing_from_repository": sorted(local.keys() - expected.keys() - external),
            "external_only": sorted((local.keys() - expected.keys()) & external),
            "not_installed": sorted(expected.keys() - local.keys()), "different": different,
            "system_managed": sorted(item.parent.name for item in system.glob("*/SKILL.md")) if system.is_dir() else [],
        }
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=ROOT)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="Fail if manifest or generated catalog is stale")
    mode.add_argument("--refresh", action="store_true", help="Refresh hashes and catalog, preserving provenance")
    parser.add_argument("--installed", action="store_true", help="Compare local installations without changing them")
    parser.add_argument("--claude-skills", type=Path, default=Path.home() / ".claude/skills")
    parser.add_argument("--codex-skills", type=Path, default=Path.home() / ".codex/skills")
    args = parser.parse_args()
    root = args.repo.resolve()
    try:
        path = root / MANIFEST
        previous = json.loads(path.read_text()) if path.is_file() else {}
        if previous and previous.get("schema_version") != 1:
            raise InventoryError("Unsupported manifest schema")
        current = assemble(root, previous)
        generated = documentation(current)
        if args.refresh:
            path.write_text(json.dumps(current, ensure_ascii=False, indent=2) + "\n")
            (root / DOC).parent.mkdir(parents=True, exist_ok=True)
            (root / DOC).write_text(generated)
        elif args.check:
            if previous != current:
                raise InventoryError("Skill manifest differs from source; review changes and use --refresh")
            if not (root / DOC).is_file() or (root / DOC).read_text() != generated:
                raise InventoryError("Generated skill catalog differs; use --refresh")
        output = {"status": "passed", **current["counts"]}
        if args.installed:
            output["installed"] = compare_installed(root, current, {"claude": args.claude_skills, "codex": args.codex_skills})
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return 0
    except (InventoryError, OSError, ValueError) as error:
        print(json.dumps({"status": "failed", "error": str(error)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
