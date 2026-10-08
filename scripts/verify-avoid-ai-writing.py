#!/usr/bin/env python3
"""Verify the shared writing skill offline, without changing the package or settings."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


PACKAGE_PATH = Path("shared/skills/avoid-ai-writing")
REQUIRED_FILES = (
    "SKILL.md", "README.md", "LICENSE", "NOTICE.md", "provenance.json",
    "agents/openai.yaml", "references/patterns.md", "references/headlines.md",
    "detector/CATEGORIES.md", "detector/patterns.js", "detector/validate.js",
    "scripts/check-style.js", "scripts/markdown-prose.js",
    "scripts/normalize-quotes.js", "examples/README.md",
    "examples/prose.json", "examples/technical.json",
)
JAVASCRIPT_FILES = (
    "detector/patterns.js", "detector/validate.js", "scripts/check-style.js",
    "scripts/markdown-prose.js", "scripts/normalize-quotes.js",
)
PROTECTED_FILES = ("LICENSE", "NOTICE.md")

SMOKE_CHECK = r"""
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = process.argv[2];
const detector = require(path.join(root, 'detector/patterns.js'));
const validator = require(path.join(root, 'detector/validate.js'));
const style = require(path.join(root, 'scripts/check-style.js'));
const normalizer = require(path.join(root, 'scripts/normalize-quotes.js'));
const noisy = detector.analyzeText('In order to leverage robust solutions, it is important to note the future looks bright.');
assert.ok(noisy.issues.length > 0, 'detector must flag known patterns');
assert.equal(detector.analyzeText('Open the file.').issues.length, 0, 'simple instruction must stay clean');
const original = '# Sync notes\n\nUse the existing process for 7 files.\n\n`node --version`\n';
const rewritten = '# Sync notes\n\nCheck the current process for 7 files.\n\n`node --version`\n';
assert.ok(original.includes('\n\n'), 'validator fixture must have real Markdown paragraph boundaries');
assert.ok(validator.validate(original, rewritten, { residualPolicy: 'warn' }).ok, 'preserved rewrite must pass');
assert.ok(validator.validate(original, rewritten.replace('7', '8'), { residualPolicy: 'warn' }).warnings.some(issue => issue.code === 'number-missing'), 'number changes must be reported for review');
assert.equal(validator.validate(original, rewritten.replace('node --version', 'node --help'), { residualPolicy: 'warn' }).ok, false, 'code damage must fail');
for (const name of ['prose', 'technical']) {
  const configPath = style.resolveConfig(name);
  assert.equal(configPath, path.join(root, 'examples', `${name}.json`));
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const result = style.check('Open the file.', config.mechanics);
  assert.equal(result.hard.length, 0, `${name} mechanics must accept plain prose`);
  assert.equal(result.warnings.length, 0, `${name} mechanics must be recognized`);
}
assert.ok(style.check('“Quoted text” e.g. an example.', { quotes: 'straight', latinAbbrev: 'never' }).hard.length >= 2, 'style violations must be visible');
assert.equal(style.check('`“quoted” e.g.`', { quotes: 'straight', latinAbbrev: 'never' }).hard.length, 0, 'style must ignore code');
const source = '“Editable prose.”\n\n```js\nconst x = "“protected”";\n```\n';
const expected = '"Editable prose."\n\n```js\nconst x = "“protected”";\n```\n';
assert.ok(source.includes('\n```js\n'), 'normalizer fixture must contain a real fenced code block');
assert.equal(normalizer.normalize(source, 'straight'), expected, 'normalizer must retain code');
assert.equal(normalizer.normalize(expected, 'straight'), expected, 'normalizer must be idempotent');
"""


class VerificationError(Exception):
    """A failed package or runtime check with an actionable message."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VerificationError(message)


def read_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"{path}: expected a JSON object")
    return value


def check_link(link: Path, expected: Path, *, relative: bool) -> None:
    require(link.is_symlink(), f"{link}: expected a symlink")
    if relative:
        require(not os.path.isabs(os.readlink(link)), f"{link}: alias must be relative")
    try:
        target = link.resolve(strict=True)
    except (OSError, RuntimeError) as error:
        raise VerificationError(f"{link}: broken alias ({error})") from error
    require(target == expected, f"{link}: resolves to {target}, expected {expected}")


def check_package(repo: Path) -> Path:
    """Check package structure without invoking Node or touching the home directory."""
    package = repo / PACKAGE_PATH
    require(package.is_dir() and not package.is_symlink(), f"{package}: expected source directory")
    for name in REQUIRED_FILES:
        path = package / name
        require(path.is_file() and not path.is_symlink(), f"{path}: missing required bundle file or replaced by symlink")
    for name in (".git", ".gitignore"):
        require(not os.path.lexists(package / name), f"{package / name}: excluded import path is present")

    for tool in ("claude", "codex"):
        check_link(repo / tool / "skills/avoid-ai-writing", package, relative=True)

    provenance = read_json(package / "provenance.json")
    require(provenance.get("schema_version") == 1, "provenance: unsupported schema_version")
    require(provenance.get("package") == "avoid-ai-writing", "provenance: package name mismatch")
    imported_version = provenance.get("imported_version", "")
    require(isinstance(imported_version, str) and re.fullmatch(r"\d+\.\d+\.\d+", imported_version) is not None,
            "provenance: imported_version must identify the upstream release")
    revision = provenance.get("local_revision")
    require(type(revision) is int and revision >= 1, "provenance: local_revision must be a positive integer")
    for key, repository in (
        ("immediate_source", "https://github.com/salexandr0s/avoid-ai-writing"),
        ("canonical_source", "https://github.com/conorbronsdon/avoid-ai-writing"),
    ):
        source = provenance.get(key)
        require(isinstance(source, dict), f"provenance: missing {key}")
        require(source.get("repository") == repository, f"provenance: unexpected {key} repository")
        commit = source.get("commit", "")
        require(isinstance(commit, str) and re.fullmatch(r"[0-9a-f]{40}", commit) is not None,
                f"provenance: {key} must pin a full commit")
    require(provenance.get("omitted_paths") == [".git", ".gitignore"], "provenance: omitted import paths changed")
    modifications = provenance.get("local_modifications")
    require(isinstance(modifications, list) and bool(modifications), "provenance: local modifications must be documented")
    for item in modifications:
        require(isinstance(item, dict) and bool(item.get("area")) and bool(item.get("changes")),
                "provenance: each local modification needs an area and description")
    protected = provenance.get("protected_files")
    require(isinstance(protected, dict), "provenance: protected_files must be an object")
    for name in PROTECTED_FILES:
        record = protected.get(name)
        require(isinstance(record, dict) and record.get("algorithm") == "sha256",
                f"provenance: {name} must use sha256")
        expected_hash = record.get("sha256", "")
        require(isinstance(expected_hash, str) and re.fullmatch(r"[0-9a-f]{64}", expected_hash) is not None,
                f"provenance: invalid {name} hash")
        actual_hash = hashlib.sha256((package / name).read_bytes()).hexdigest()
        require(actual_hash == expected_hash, f"{package / name}: immutable notice/license hash mismatch")

    skill = (package / "SKILL.md").read_text(encoding="utf-8")
    frontmatter = re.match(r"\A---\n(.*?)\n---(?:\n|$)", skill, re.DOTALL)
    require(frontmatter is not None, "SKILL.md: missing frontmatter")
    fields = dict(re.findall(r"^([a-z_]+):[ \t]*(.+)$", frontmatter.group(1), re.MULTILINE))
    require(fields.get("name") == "avoid-ai-writing", "SKILL.md: name mismatch")
    require(fields.get("version") == imported_version, "SKILL.md: version must match provenance imported_version")
    require(fields.get("license") == "MIT", "SKILL.md: MIT license declaration missing")
    require(bool(fields.get("description")), "SKILL.md: description missing")
    metadata = (package / "agents/openai.yaml").read_text(encoding="utf-8")
    for field in ("display_name", "short_description", "default_prompt"):
        require(re.search(rf"^  {field}:[ \t]*\S.+$", metadata, re.MULTILINE) is not None,
                f"agents/openai.yaml: missing {field}")
    require(re.search(r"^  allow_implicit_invocation: false[ \t]*$", metadata, re.MULTILINE) is not None,
            "agents/openai.yaml: explicit invocation policy changed")
    for name in ("prose", "technical"):
        config = read_json(package / "examples" / f"{name}.json")
        require(isinstance(config.get("mechanics"), dict), f"{name}.json: mechanics must be an object")
        register = config.get("register")
        require(isinstance(register, list) and all(isinstance(item, str) for item in register),
                f"{name}.json: register must be a list of strings")
    return package


def run(command: list[str], *, cwd: Path, source: str | None = None) -> str:
    try:
        result = subprocess.run(command, cwd=cwd, input=source, capture_output=True,
                                text=True, timeout=60, check=False)
    except subprocess.TimeoutExpired as error:
        raise VerificationError(f"{command[0]} check exceeded 60 seconds") from error
    if result.returncode != 0:
        details = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
        raise VerificationError(f"Command failed (exit {result.returncode}): {' '.join(command)}\n{details}")
    return result.stdout.strip()


def check_tools(repo: Path, package: Path) -> None:
    node = shutil.which("node")
    require(node is not None, "Node.js 18 or newer is required; node was not found")
    version = run([node, "--version"], cwd=repo)
    major = re.match(r"v(\d+)\.", version)
    require(major is not None and int(major.group(1)) >= 18, f"Node.js 18 or newer is required; found {version}")
    for name in JAVASCRIPT_FILES:
        run([node, "--check", str(package / name)], cwd=repo)
    print("PASS: syntax checks for all five bundled JavaScript files")
    run([node, "-", str(package)], cwd=repo, source=SMOKE_CHECK)
    print("PASS: detector, preservation validator, house-style examples, and quote normalizer smoke checks")
    test_file = repo / "tests/avoid-ai-writing-tools.test.js"
    if test_file.is_file():
        run([node, "--test", str(test_file)], cwd=repo)
        print("PASS: tests/avoid-ai-writing-tools.test.js")
    else:
        print("SKIP: repository tool regression test file is absent; upstream test harness is outside this subset")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1],
                        help="ai-config root to check (defaults to this script's repository)")
    parser.add_argument("--check-installed", action="store_true", help="also check the two global skill symlinks")
    parser.add_argument("--claude-link", type=Path, help="explicit installed Claude skill link path")
    parser.add_argument("--codex-link", type=Path, help="explicit installed Codex skill link path")
    args = parser.parse_args(argv)
    if not args.check_installed and (args.claude_link or args.codex_link):
        parser.error("--claude-link and --codex-link require --check-installed")
    try:
        repo = args.repo.expanduser().resolve(strict=True)
        package = check_package(repo)
        print(f"PASS: bundle, relative aliases, metadata, provenance, and protected notices ({package})")
        check_tools(repo, package)
        if args.check_installed:
            installed = (
                args.claude_link or Path.home() / ".claude/skills/avoid-ai-writing",
                args.codex_link or Path.home() / ".codex/skills/avoid-ai-writing",
            )
            for link in installed:
                link = link.expanduser().absolute()
                check_link(link, package, relative=False)
                print(f"PASS: installed link {link} -> {package}")
        print("Editorial title quality and semantic fidelity still require source review.")
        return 0
    except (VerificationError, OSError, ValueError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
