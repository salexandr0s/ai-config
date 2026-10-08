# Avoid AI writing

This is ai-config's shared writing skill for Claude Code and Codex. It reviews
English prose, titles, and headings, then edits within the scope you request.
The full rulebook is in [SKILL.md](SKILL.md) and [references/](references/).

## Use in Claude Code and Codex

Start a fresh chat after installation so the tool can discover the skill.

| Tool | Invocation |
| --- | --- |
| Claude Code | `/avoid-ai-writing scan this, don't rewrite` |
| Codex | `$avoid-ai-writing scan this, don't rewrite` |

Replace the request with `rewrite this in a warmer voice`, `review these titles`,
or `edit draft.md in place` as needed. Detection reports findings; rewrite and
edit requests authorize changes within their stated scope. Codex's
`agents/openai.yaml` keeps `allow_implicit_invocation: false`.

The bundled tools require **Node.js 18 or newer**. The verification helper also
requires Python 3.10 or newer. This package has no dependencies to install,
package-manager setup, or TypeScript configuration.

## Where the skill lives

ai-config stores one source package and links both tools to it:

```text
ai-config/
├── shared/skills/avoid-ai-writing/       # source package; edit here
│   ├── SKILL.md                        # editing contract and workflow
│   ├── agents/openai.yaml              # Codex display and invocation metadata
│   ├── references/                     # rulebook and title guidance
│   ├── detector/                       # pattern analysis and preservation checks
│   ├── scripts/                        # style checks and quote normalization
│   ├── examples/                       # house-style examples
│   ├── provenance.json                 # import pins and local revision
│   ├── LICENSE                         # unchanged MIT license
│   └── NOTICE.md                       # unchanged upstream attribution
├── claude/skills/avoid-ai-writing -> ../../shared/skills/avoid-ai-writing
└── codex/skills/avoid-ai-writing  -> ../../shared/skills/avoid-ai-writing
```

The installed global links are `~/.claude/skills/avoid-ai-writing` and
`~/.codex/skills/avoid-ai-writing`; each points through its ai-config tool alias
to this source. Relative repository aliases survive a checkout move. After
moving the checkout, repoint the global links to its new absolute location.

Use the [ai-config installation guide](../../../README.md#installation) for a
new machine. Review skill changes in `shared/skills/avoid-ai-writing/`; installed
tools see them through the links. Keep draft documents, custom house-style files,
original snapshots, and temporary validator output in the document's project or
a temporary directory outside this skill. They are user content and should not
be bundled with the shared rules.

## What checks can establish

Titles should identify their subject, a supported point, or a concrete action or
question. A model must read the source and context to judge title specificity,
audience fit, factual support, and whether a replacement preserves the writer's
meaning. These checks do not add a detector category or mechanically certify a
title.

The detector identifies patterns worth reviewing. The validator checks selected
forms of preservation, including recognized closed mapping-style YAML
frontmatter. Other YAML forms require manual review. The style checker checks
configured mechanics and reports advisory findings; the normalizer adjusts quote
marks in editable prose.
Passing these checks does not establish semantic fidelity, house-guide
compliance, or who wrote the text. Their inherited rules are calibrated for
English.

## Verify this package

From the ai-config root, run:

```bash
python3 -B scripts/verify-avoid-ai-writing.py
python3 -B scripts/verify-avoid-ai-writing.py --check-installed
```

The first command is offline and leaves the package and settings unchanged.
Regression tests use disposable temporary files. It checks the bundle, relative
aliases, metadata, provenance, license and notice hashes, both JSON examples,
all five JavaScript files' syntax, and detector, validator, style, and normalizer
behavior. It also runs the repository's tool regression tests when present.
The second command additionally checks the two installed global links and
reports the paths it checked. Use `--claude-link PATH` and `--codex-link PATH`
with `--check-installed` to check other explicitly chosen links.

Package regression tests run with:

```bash
python3 -B -m unittest discover -s tests -p 'test_avoid_ai_writing_package.py'
```

The full upstream test harness and CI are outside this subset. These local
checks cover packaging and selected tool behavior; editorial title judgments
still need review against representative source text. Run this helper for skill
verification. Running the whole ai-config installer changes global configuration
and is unnecessary for verification.

## Maintain the import

[provenance.json](provenance.json) records the immediate imported repository
([salexandr0s/avoid-ai-writing](https://github.com/salexandr0s/avoid-ai-writing),
commit `1416dfd0388fb338f43d248d5f262fa44eefe4b2`) and canonical source
([conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing),
commit `5a5cf6a45331384d4ff68f1f6ce50da24da0da4c`). The imported version is
`3.37.0`; ai-config's local revision is recorded separately. Local changes cover
the editing contract, title guidance, display copy, documentation, protected
content handling, and whitespace cleanup. `NOTICE.md` retains the canonical
author and packaging credits, including descriptions of the broader upstream
package that are outside this subset. `.git` and `.gitignore` were omitted from
the import.

To review an update:

1. Fetch the candidate source into a temporary directory outside ai-config and
   record its exact commit. Compare it with the recorded import pins.
2. Review the changes file by file. Keep ai-config's editing policy, title
   guidance, display metadata, documentation, tool fixes, and regression tests.
   Import only reviewed changes into this shared package.
3. Preserve the MIT license and attribution notice. If an upstream release
   legitimately changes either, review the attribution change before updating
   the protected file's hash in `provenance.json`.
4. Update the source pins and imported version only when the imported source
   changes. Increment `local_revision` for a reviewed local release, and update
   `local_modifications` to describe the retained differences.
5. Run the package verifier and regression tests, review the diff and
   representative title edits, and record the result before committing.

Do not overwrite this package wholesale from upstream or clone another copy
into a tool's skill directory. Manual review preserves one shared source and
the local policy that both tools use.
