#!/usr/bin/env bash
set -euo pipefail

# dev-status — git state + quick quality snapshot

echo "==> Git Status"
git status --short --branch 2>/dev/null || echo "  (not a git repository)"

echo ""
echo "==> Recent Commits"
git log --oneline -5 2>/dev/null || echo "  (no git history)"

echo ""
echo "==> Quality Snapshot"
if [ -f "Cargo.toml" ]; then
  echo "  Project: Rust"
  cargo check 2>&1 | tail -1 || true
elif [ -f "package.json" ]; then
  echo "  Project: Node"
  if [ -f "tsconfig.json" ]; then
    npx tsc --noEmit 2>&1 | tail -3 || true
  fi
elif [ -f "pyproject.toml" ]; then
  echo "  Project: Python"
  ruff check . --statistics 2>&1 | tail -3 || true
fi

echo ""
echo "==> dev-status complete."
