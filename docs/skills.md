# Skill catalog

[Project overview](../README.md)

78 skill bindings by name, available through 46 Claude and 74 Codex entries. Shared source packages: 20. Tool-specific adaptations remain separate.

This file is generated from `skills-manifest.json`. Run `python3 scripts/skills-inventory.py --check` to check aliases, resources and full package hashes. After an intentional source change, review the diff and run `python3 scripts/skills-inventory.py --refresh`.

## Included skills

Binding names follow the existing tool directories. Some upstream skills declare a different name in frontmatter; both are recorded in the manifest.

| Binding | Claude | Codex | Source |
| :--- | :---: | :---: | :--- |
| `adapt` | ✓ | ✓ | [claude](../claude/skills/adapt) · [codex](../codex/skills/adapt) |
| `adr` |  | ✓ | [codex](../codex/skills/adr) |
| `animate` | ✓ | ✓ | [claude](../claude/skills/animate) · [codex](../codex/skills/animate) |
| `arrange` | ✓ | ✓ | [claude](../claude/skills/arrange) · [codex](../codex/skills/arrange) |
| `audit` |  | ✓ | [codex](../codex/skills/audit) |
| `auditdeep` |  | ✓ | [codex](../codex/skills/auditdeep) |
| `auditui` | ✓ | ✓ | [claude](../claude/skills/auditui) · [codex](../codex/skills/auditui) |
| `avoid-ai-writing` | ✓ | ✓ | [shared](../shared/skills/avoid-ai-writing) |
| `bolder` | ✓ | ✓ | [claude](../claude/skills/bolder) · [codex](../codex/skills/bolder) |
| `browse` | ✓ | ✓ | [claude](../claude/skills/browse) · [codex](../codex/skills/browse) |
| `clarify` | ✓ | ✓ | [claude](../claude/skills/clarify) · [codex](../codex/skills/clarify) |
| `cloudflare-deploy` |  | ✓ | [codex](../codex/skills/cloudflare-deploy) |
| `colorize` | ✓ | ✓ | [claude](../claude/skills/colorize) · [codex](../codex/skills/colorize) |
| `commands` |  | ✓ | [codex](../codex/skills/commands) |
| `condense` |  | ✓ | [codex](../codex/skills/condense) |
| `config-editor` |  | ✓ | [codex](../codex/skills/config-editor) |
| `critique` | ✓ | ✓ | [claude](../claude/skills/critique) · [codex](../codex/skills/critique) |
| `debug` |  | ✓ | [codex](../codex/skills/debug) |
| `deepsec` | ✓ | ✓ | [shared](../shared/skills/deepsec) |
| `delight` | ✓ | ✓ | [claude](../claude/skills/delight) · [codex](../codex/skills/delight) |
| `deploy-check` |  | ✓ | [codex](../codex/skills/deploy-check) |
| `distill` | ✓ | ✓ | [claude](../claude/skills/distill) · [codex](../codex/skills/distill) |
| `dod` |  | ✓ | [codex](../codex/skills/dod) |
| `extract` | ✓ | ✓ | [claude](../claude/skills/extract) · [codex](../codex/skills/extract) |
| `fix` |  | ✓ | [codex](../codex/skills/fix) |
| `focus` |  | ✓ | [codex](../codex/skills/focus) |
| `frontend-design` | ✓ | ✓ | [claude](../claude/skills/frontend-design) · [codex](../codex/skills/frontend-design) |
| `green` |  | ✓ | [codex](../codex/skills/green) |
| `greeniv` |  | ✓ | [codex](../codex/skills/greeniv) |
| `harden` | ✓ | ✓ | [claude](../claude/skills/harden) · [codex](../codex/skills/harden) |
| `hig-android` | ✓ | ✓ | [shared](../shared/skills/hig-android) |
| `hig-ios` | ✓ | ✓ | [shared](../shared/skills/hig-ios) |
| `hig-ipados` | ✓ | ✓ | [shared](../shared/skills/hig-ipados) |
| `hig-macos` | ✓ | ✓ | [shared](../shared/skills/hig-macos) |
| `hig-tvos` | ✓ | ✓ | [shared](../shared/skills/hig-tvos) |
| `hig-visionos` | ✓ | ✓ | [shared](../shared/skills/hig-visionos) |
| `hig-watchos` | ✓ | ✓ | [shared](../shared/skills/hig-watchos) |
| `hig-web` | ✓ | ✓ | [shared](../shared/skills/hig-web) |
| `ios-simulator-skill` | ✓ | ✓ | [shared](../shared/skills/ios-simulator-skill) |
| `lint` |  | ✓ | [codex](../codex/skills/lint) |
| `migrate-to-codex` |  | ✓ | [codex](../codex/skills/migrate-to-codex) |
| `new-project` |  | ✓ | [codex](../codex/skills/new-project) |
| `normalize` | ✓ | ✓ | [claude](../claude/skills/normalize) · [codex](../codex/skills/normalize) |
| `onboard` | ✓ | ✓ | [claude](../claude/skills/onboard) · [codex](../codex/skills/onboard) |
| `openspec-apply-change` | ✓ | ✓ | [shared](../shared/skills/openspec-apply-change) |
| `openspec-archive-change` | ✓ | ✓ | [shared](../shared/skills/openspec-archive-change) |
| `openspec-explore` | ✓ | ✓ | [claude](../claude/skills/openspec-explore) · [codex](../codex/skills/openspec-explore) |
| `openspec-propose` | ✓ | ✓ | [claude](../claude/skills/openspec-propose) · [codex](../codex/skills/openspec-propose) |
| `optimize` | ✓ | ✓ | [claude](../claude/skills/optimize) · [codex](../codex/skills/optimize) |
| `overdrive` | ✓ | ✓ | [claude](../claude/skills/overdrive) · [codex](../codex/skills/overdrive) |
| `polish` | ✓ | ✓ | [claude](../claude/skills/polish) · [codex](../codex/skills/polish) |
| `portless` | ✓ | ✓ | [shared](../shared/skills/portless) |
| `postmortem` |  | ✓ | [codex](../codex/skills/postmortem) |
| `pr` |  | ✓ | [codex](../codex/skills/pr) |
| `quieter` | ✓ | ✓ | [claude](../claude/skills/quieter) · [codex](../codex/skills/quieter) |
| `refactor` |  | ✓ | [codex](../codex/skills/refactor) |
| `release` |  | ✓ | [codex](../codex/skills/release) |
| `repo-surgeon` | ✓ | ✓ | [claude](../claude/skills/repo-surgeon) · [codex](../codex/skills/repo-surgeon) |
| `reqwording` |  | ✓ | [codex](../codex/skills/reqwording) |
| `review` |  | ✓ | [codex](../codex/skills/review) |
| `reviewdeep` |  | ✓ | [codex](../codex/skills/reviewdeep) |
| `securecoding` |  | ✓ | [codex](../codex/skills/securecoding) |
| `shadcn` | ✓ | ✓ | [shared](../shared/skills/shadcn) |
| `spec` |  | ✓ | [codex](../codex/skills/spec) |
| `stageshow` | ✓ | ✓ | [shared](../shared/skills/stageshow) |
| `status` |  | ✓ | [codex](../codex/skills/status) |
| `storygen` |  | ✓ | [codex](../codex/skills/storygen) |
| `supplychain` |  | ✓ | [codex](../codex/skills/supplychain) |
| `swift-concurrency-pro` | ✓ |  | [shared](../shared/skills/swift-concurrency-pro) |
| `swift-testing-pro` | ✓ |  | [shared](../shared/skills/swift-testing-pro) |
| `swiftui-performance-audit` | ✓ |  | [shared](../shared/skills/swiftui-performance-audit) |
| `swiftui-pro` | ✓ |  | [shared](../shared/skills/swiftui-pro) |
| `teach-impeccable` | ✓ | ✓ | [claude](../claude/skills/teach-impeccable) · [codex](../codex/skills/teach-impeccable) |
| `test` |  | ✓ | [codex](../codex/skills/test) |
| `threatmodel` |  | ✓ | [codex](../codex/skills/threatmodel) |
| `typeset` | ✓ | ✓ | [claude](../claude/skills/typeset) · [codex](../codex/skills/typeset) |
| `vercel-deploy` |  | ✓ | [codex](../codex/skills/vercel-deploy) |
| `visual-explainer` | ✓ | ✓ | [claude](../claude/skills/visual-explainer) · [codex](../codex/skills/visual-explainer) |

## External skills

These installed tools are accounted for but their text is not redistributed in this repository.

| Skill | Source | Reason |
| :--- | :--- | :--- |
| `aside-browser` | [cskwork/aside-browser-skill](https://github.com/cskwork/aside-browser-skill) | No redistribution license is supplied in the installed snapshot or the upstream repository. Keep the existing local installation outside this bundle. |

## Updating and checking

```sh
python3 scripts/skills-inventory.py --check
python3 scripts/skills-inventory.py --check --installed
```

The installed comparison is read-only. It lists missing repository entries, missing local bindings, and content differences without replacing local copies. Assistant-managed hidden system skills are counted separately. Local formatter changes can produce a different package hash without changing the instructions.

The manifest records full package digests and preserved license files. An installed snapshot without a known upstream revision is labelled as such; no remote freshness claim is made. `NOASSERTION` means that this catalog does not assign a license to the package. Retained upstream notices and licenses govern third-party content.
