#!/usr/bin/env bash
set -euo pipefail

command_input="${CLAUDE_TOOL_INPUT:-}"

if [ -z "$command_input" ]; then
  exit 0
fi

blocked=0

warn_if_matches() {
  local pattern="$1"
  local message="$2"

  if printf '%s\n' "$command_input" | grep -qiE "$pattern"; then
    printf 'WARN: %s\n' "$message" >&2
  fi
}

block_if_matches() {
  local pattern="$1"
  local message="$2"

  if printf '%s\n' "$command_input" | grep -qiE "$pattern"; then
    printf 'BLOCKED: %s\n' "$message" >&2
    blocked=1
  fi
}

warn_if_matches '(npm|pnpm|yarn|cargo) publish' 'This publishes externally. Confirm with the user first.'
warn_if_matches 'docker push|gh release create|git tag' 'This creates an external release artifact. Confirm with the user first.'
block_if_matches 'vercel( |$).*--prod|vercel deploy --prod|fly deploy|railway (up|deploy)|netlify deploy --prod' 'This targets production deployment. Blocked — get explicit user approval.'
block_if_matches 'terraform apply|kubectl apply|helm upgrade|helm install' 'This changes live infrastructure. Blocked — get explicit user approval.'
block_if_matches 'supabase db push|prisma db push|drizzle-kit push|rails db:migrate' 'This mutates a database or schema. Blocked — get explicit user approval.'
warn_if_matches 'git push (origin )?(main|master)\b' 'This pushes to the default branch. Confirm with the user first.'

if [ "$blocked" -eq 1 ]; then
  exit 2
fi

exit 0
