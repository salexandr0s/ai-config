# Privacy boundary and review

[Project overview](../README.md) · [Configuration guide](configuration.md)

Review date: 3 November 2026.

## Shared source and personal state

The versioned setup contains reusable defaults, blank context templates, workflow prompts, tools, and attributed skill packages. Personal context belongs in `~/.claude/USER/`; credentials, native local settings, trusted project paths, memory, sessions, caches, and session journals belong in local configuration/state directories.

The installer seeds missing personal-context files from blank templates and preserves existing user content. It does not link private USER or MEMORY directories back into the repository. Local environment files, private keys, authentication state, runtime artifacts, worktree directories, and `SESSION_HANDOFF.md` are excluded by `.gitignore`.

## Source cleanup

The review found ten filled personal-context files under `claude/user/`, plus session journals containing machine-specific operational details. The public source replaces those context files with blank reusable templates and removes the tracked session journal. Original personal content is preserved in private local backups rather than copied into public reports.

An unnecessary personal project reference in an authored audit document is generalized. Public maintainer identifiers, fictional test data, and third-party author/license attribution are retained intentionally.

Credential checks use Gitleaks with redaction; manual review covers personal prose, machine paths, private infrastructure, and operational context. Scanner results and semantic review are separate checks because a credential scanner does not identify personal goals or project notes.

## Historical cleanup

A clean current snapshot does not remove older versions from Git history. The historical review found earlier personal-context blobs, private session notes, machine home paths, and personal owner commit identities.

The prepared cleanup replaces the known personal-context blobs with approved blank templates, removes session journals throughout history, generalizes the remaining owned machine/project references, and maps owner author/committer metadata to the public GitHub noreply identity. It preserves commit count, third-party attribution, and existing coauthor credits. The latest reusable source tree is preserved.

Publishing that cleanup rewrites commit IDs and requires explicit maintainer approval. Old clones must not merge the original history back into the cleaned branch. GitHub may retain cached old-commit views or other copies after a branch rewrite; GitHub's [sensitive-data removal guide](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) explains those limits and the support process.

The repository is kept private while the historical cleanup is being reviewed. No automatic force push, credential rotation, or public visibility change is performed by the installer.

## Maintaining the boundary

Use the native local overlay or an environment/secret store for machine-specific values. Keep actual USER/MEMORY content out of source templates. Review the exact staged file list before committing, and rescan newly imported skill bundles together with their notices.

The [skill inventory](skills.md) validates package hashes, bindings, and resources. It complements the privacy review; it does not scan credential validity or approve personal data for publication.
