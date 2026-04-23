#!/usr/bin/env python3
"""Audit discoverable Codex skills and highlight likely context-budget waste."""

from __future__ import annotations

import os
import re
import subprocess
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


@dataclass
class SkillRecord:
    scope: str
    skill_dir: Path
    skill_md: Path
    name: str
    description: str

    @property
    def description_chars(self) -> int:
        return len(self.description)

    @property
    def is_backup(self) -> bool:
        return ".bak-" in self.skill_dir.name


def find_git_root(start: Path) -> Path | None:
    try:
        output = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=start,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None

    return Path(output) if output else None


def parse_frontmatter(skill_md: Path) -> tuple[str, str]:
    try:
        text = skill_md.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = skill_md.read_text(errors="ignore")

    match = FRONTMATTER_RE.match(text)
    if not match:
        return skill_md.parent.name, ""

    name = skill_md.parent.name
    description = ""

    for line in match.group(1).splitlines():
        if line.startswith("name:"):
            name = line.split(":", 1)[1].strip().strip("\"'")
        elif line.startswith("description:"):
            description = line.split(":", 1)[1].strip().strip("\"'")

    return name, description


def collect_from_root(scope: str, root: Path, pattern: str = "*/SKILL.md") -> list[SkillRecord]:
    records: list[SkillRecord] = []
    if not root.exists():
        return records

    for skill_md in sorted(root.glob(pattern)):
        skill_dir = skill_md.parent
        name, description = parse_frontmatter(skill_md)
        records.append(
            SkillRecord(
                scope=scope,
                skill_dir=skill_dir,
                skill_md=skill_md,
                name=name,
                description=description,
            )
        )
    return records


def collect_repo_scopes(start: Path) -> list[SkillRecord]:
    repo_root = find_git_root(start)
    if repo_root is None:
        return collect_from_root("repo", start / ".agents" / "skills")

    records: list[SkillRecord] = []
    current = start.resolve()
    while True:
        records.extend(collect_from_root("repo", current / ".agents" / "skills"))
        if current == repo_root:
            break
        current = current.parent
    return records


def display_path(path: Path) -> str:
    home = Path.home()
    try:
        return f"~/{path.relative_to(home)}"
    except ValueError:
        return str(path)


def main() -> int:
    cwd = Path.cwd()
    codex_home = Path(os.environ.get("CODEX_HOME", "~/.codex")).expanduser()

    records: list[SkillRecord] = []
    records.extend(collect_from_root("user-codex", codex_home / "skills"))
    records.extend(collect_from_root("system", codex_home / "skills" / ".system", pattern="*/SKILL.md"))
    records.extend(collect_from_root("user-agents", Path.home() / ".agents" / "skills"))
    records.extend(collect_repo_scopes(cwd))

    scope_counts: dict[str, int] = defaultdict(int)
    scope_chars: dict[str, int] = defaultdict(int)
    by_name: dict[str, list[SkillRecord]] = defaultdict(list)
    backups: list[SkillRecord] = []

    for record in records:
        scope_counts[record.scope] += 1
        scope_chars[record.scope] += record.description_chars
        by_name[record.name].append(record)
        if record.is_backup:
            backups.append(record)

    duplicate_groups = {name: items for name, items in by_name.items() if len(items) > 1}
    longest = sorted(records, key=lambda item: item.description_chars, reverse=True)[:10]

    print("==> Codex Skills Budget Audit")
    print(f"cwd: {display_path(cwd)}")
    repo_root = find_git_root(cwd)
    print(f"repo_root: {display_path(repo_root) if repo_root else '(none)'}")
    print("")
    print("Scope totals:")
    for scope in ("user-codex", "system", "user-agents", "repo"):
        count = scope_counts.get(scope, 0)
        chars = scope_chars.get(scope, 0)
        if count:
            avg = round(chars / count, 1)
            print(f"  - {scope:11s} {count:3d} skills | {chars:5d} desc chars | avg {avg:5.1f}")

    total_chars = sum(scope_chars.values())
    print("")
    print(f"Discoverable skills: {len(records)}")
    print(f"Duplicate names:     {len(duplicate_groups)} groups")
    print(f"Backup entries:      {len(backups)}")
    print(f"Description chars:   {total_chars}")

    if longest:
        print("")
        print("Longest descriptions:")
        for record in longest:
            print(
                f"  - {record.description_chars:4d} chars | {record.name:20s} | {display_path(record.skill_md)}"
            )

    if backups:
        print("")
        print("Cleanup candidates (.bak-* skills in active scan dirs):")
        for record in backups:
            print(f"  - {display_path(record.skill_dir)}")

        print("")
        print("Suggested [[skills.config]] disables:")
        for record in backups:
            print("[[skills.config]]")
            print(f'path = "{record.skill_md}"')
            print("enabled = false")
            print("")

    if duplicate_groups:
        print("Duplicate skill names:")
        for name in sorted(duplicate_groups):
            print(f"  - {name}")
            for record in duplicate_groups[name]:
                print(f"      {record.scope:11s} {display_path(record.skill_md)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
