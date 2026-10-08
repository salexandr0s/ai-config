# Avoid AI Writing: storage, titles, and preservation review

Reviewed on 2026-10-09 in `~/GitHub/ai-config`, starting from installation
commit `a6fa924`. The goal is to make the installed skill easier to maintain,
safer with user files, and more useful for prose and titles. The review covers
the complete skill and catalog, all five JavaScript tools, examples, metadata,
installation links, and the relevant live Claude/Codex configuration.

## Findings and changes

The existing shared folder is the right source of truth. Its two relative
aliases and global links already prevent package duplication. The weaknesses
are maintenance instructions, user-document storage rules, conflicting
editorial advice, and several gaps in the preservation checker.

| Priority | Finding | Improvement |
| --- | --- | --- |
| High | The package README recommends independent `.agents` clones alongside the managed installation. | Make it the local package guide and point installation to `ai-config`. |
| High | Original and rewritten scratch files have no defined location; caller-relative paths can become skill-relative paths. | Resolve user paths from the caller's project, keep owned scratch in temporary storage, and preserve requested destinations. |
| High | Title guidance assumes Brainwave branding and conflicts with the catalog's heading rule. | Add focused, general title guidance that preserves source claims, brand wording, scope, and referenced headings. |
| High | Quote inference uses a full original while output normalization excludes protected content. | Filter the original reference and rewritten scratch prose consistently; retain the complete original for preservation checks. |
| High | Whole-document house-style checks can reject protected quotes and table cells. | Check the authorized editable prose and state that scope in the report. |
| High | Markdown boundaries differ between preservation, normalization, and selected detector rules. | Align recognized mapping-style YAML and inline-code boundaries, protect BOM/dot-closed/CRLF variants, and distinguish thematic-break prose from metadata. |
| Medium | Indented-code changes produce no promised warning; home-relative paths and tracking-parameter rules need consistency. | Add conservative protection checks and exact, tested tracking carve-outs. |
| Medium | Some catalog replacements turn design intent or uncertain timing into stronger claims. | Retain intent, time, conditions, and evidence strength in replacements. |
| Medium | Runtime prose overstates research metrics and vocabulary-based authorship conclusions. | Use a short editorial limitation statement and contextual review. |
| Medium | Copied docs claim local npm/CI tests absent from this subset. | Name the actual local verification entry point and distinguish upstream tests. |
| Medium | Provenance is scattered across prose; local changes make the previous near-identical-copy claim stale. | Record both upstream sources, imported version, local revision, patch areas, and immutable attribution hashes. |
| Low | Discovery copy is long and output rules are repeated in the catalog. | Use concise descriptive metadata and one authoritative output contract. |

## Storage and folder ownership

```text
shared/skills/avoid-ai-writing/        One maintained package
  SKILL.md                           Editing and file-handling contract
  references/patterns.md              Pattern catalog and exceptions
  references/headlines.md             Titles, subjects, and section headings
  agents/openai.yaml                 Codex display and invocation policy
  detector/                          Pattern engine and preservation validator
  scripts/                           Style checks and quote normalization
  examples/                          Optional style configurations
  provenance.json                    Source lineage and local changes
  LICENSE, NOTICE.md                 Preserved attribution

claude/skills/avoid-ai-writing        Relative alias to the shared package
codex/skills/avoid-ai-writing         Relative alias to the shared package
~/.claude/skills/avoid-ai-writing      Global link to the Claude alias
~/.codex/skills/avoid-ai-writing       Global link to the Codex alias
```

User documents belong to their project or requested output location. Temporary
originals and filtered prose belong to an owned OS temporary directory. They
do not belong in the skill package. A scan does not mutate the source; a rewrite
returns prose unless saving was requested; an in-place edit retains the target's
filename and folder. Naming or title suggestions do not authorize moving files.

The reviewed update procedure should keep one package, review the chosen source
commit, retain local policy changes, preserve licensing, update provenance, and
run verification before committing. A generic updater or another copy of the
package would add maintenance work without addressing the observed problems.

## Claude and Codex compatibility

Both installations resolve to the same physical files and share the same
machine name, editing rules, examples, and tools. Codex retains
`allow_implicit_invocation: false`. Claude's invocation is `/avoid-ai-writing`;
Codex's is `$avoid-ai-writing`. The display copy can improve without breaking
those identifiers.

At audit start, the active filesystem contained 8 agents and 41 skill entries
for Claude, and 8 agents and 70 skill entries for Codex. Claude had 54 command
entries. Each tool's relevant MCP configuration listed three servers. These
counts exceed some config-editor warning heuristics, but this change introduces
no second discoverable writing skill and preserves explicit Codex invocation.
The broader skill collection is outside this goal. The skill-budget audit found
no duplicate names or stale backup skills.

Filesystem resolution and native discovery are separate checks. Codex native
`skills/list` was rechecked from the GitHub root and ai-config after the changes:
one enabled user skill, its updated display title, a 214-character description,
and no package errors. A valid Claude global link is
not proof that an already-open Claude conversation refreshed its skill list;
start a fresh conversation after these changes.

## Title and copy evaluation

Useful title review asks whether the wording helps a reader identify the
content and whether the source actually supports it. It does not require a
fixed rewrite or reject every short or conventional heading.

| Evaluation case | Required behavior |
| --- | --- |
| Generic signup slogan with a supplied publication and topic | Use the supplied facts; invent no benefit or finding. |
| Generic title without supplied subject matter | Report missing context rather than fabricate specificity. |
| Title over a small observational study | Preserve association, uncertainty, population, and conditions; add no causal claim. |
| Official campaign slogan with documented uppercase branding | Preserve protected wording and brand mechanics unless in scope. |
| Useful `Overview` heading or a heading with referenced anchors | Allow a useful conventional label; preserve references or report the additional scope needed. |
| `Designed to scale` or `may eventually support X` | Preserve design intent and time; do not claim demonstrated capability. |
| Scan naming a prose file; clean no-op rewrite | Do not mutate the file; return unchanged text and zero editing passes when appropriate. |
| Targeted prose edit beside quotes, a table, paths, and identifiers | Edit only authorized prose; use its own quote convention; preserve protected content. |

The detector refuses to score samples under ten words. Both a vague slogan and
a useful short title can therefore have zero reported issues and an unscored
result. The validator can also pass a heading change that overstates a body's
claim or leaves a generated heading anchor broken. Title quality, attribution,
claims, and anchor integrity require contextual review; passing mechanical
checks does not establish them.

## Evidence and wording accuracy

The original runtime caveat generalized detector failure rates and treated a
specific attack metric as overall detection accuracy. The BFI paper evaluates
four named tools with false-positive and false-negative measures under different
conditions; it does not justify a blanket claim about all open-source detectors.
[Artificial Writing and Automated Detection](https://bfi.uchicago.edu/wp-content/uploads/2025/09/BFI_WP_2025-116.pdf).

The adversarial paraphrasing paper reports an average reduction in true-positive
rate at a fixed 1% false-positive rate under its described attack setup. That
measure is distinct from overall accuracy.
[Adversarial Paraphrasing](https://arxiv.org/abs/2506.07001).

These metrics are unnecessary in a runtime editing instruction. The useful
rule is that writing patterns are candidates for editorial review and do not
establish authorship. Source-supported claims and justified edits matter more
than clearing a count or imitating an expected style.

## Verification and limits

The repository-level verifier checks package inventory, both relative
aliases, required references and metadata, source provenance, attribution
integrity, JSON examples, script syntax, and deterministic smoke/regression
behavior. Negative package tests demonstrate failure for a missing
file, damaged alias, or changed attribution notice. Node tests pair
protected-content mutations with unchanged and legitimate Markdown examples,
and preserve validator API, CLI exit behavior, and browser loading.

The repository has no root project manifest or configured root type-checker.
`dev-verify` cannot detect it, so the offline package verifier and targeted
regression suites are the appropriate fallback. They do not validate arbitrary
prose meaning, user authorization, attributed content, or all Markdown dialects.

The bounded YAML recognizers cover closed mapping-style headers whose first
substantive key is ASCII, dotted, hyphenated, or quoted, including preceding
blank/comment lines and nested values. Empty/comment-only headers, root scalar,
sequence or flow YAML, directives, and unquoted Unicode keys remain outside
mechanical recognition. The editing contract still protects those forms.

Detector protection is rule-specific. Its compatibility default and general
vocabulary scoring can include code; some prose rules use a code mask, and
rendered-Markdown mode additionally handles selected source regions. Fixing
delimiter boundaries does not turn it into a full document sanitizer. Review
every finding against context and protected content rather than editing code
because a vocabulary match appeared. The hyphenation rule retains conservative
masking of indented content, while the hashtag rule distinguishes list prose.
Comment and ignore-marker scanners retain their separate inline recognition.

## Results

The storage, documentation, editorial, and bounded preservation improvements
were implemented in the shared package. The machine name and explicit Codex
invocation policy remain stable. The discovery description fell from 411 to
214 characters, and the focused title guide contains 12 behavioral examples.

Final integration checks passed:

- `python3 -B scripts/verify-avoid-ai-writing.py --check-installed`: package,
  provenance, attribution, both JSON examples, five JavaScript syntax checks,
  smoke checks, 16 native tool regression groups, and both global links.
- `python3 -B -m unittest discover -s tests -p 'test_avoid_ai_writing_package.py' -v`:
  nine package tests, including relocation, damaged aliases, missing files,
  attribution changes, surfaced tool failures, and package immutability.
- Python AST parsing, metadata parsing, authored local references/anchors,
  whitespace checks, and native Codex discovery.
- Independent code review and model-only evaluation of the eight editorial
  cases above. No live Claude or Codex model-writing session was run.

Existing changes to Claude settings and Codex command rules were preserved.
Changes are committed locally; no remote source repository or deployment was
modified. Start fresh assistant conversations to refresh their skill metadata.
