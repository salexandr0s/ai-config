#!/usr/bin/env bash
set -euo pipefail

# dev-format — format all files for current project type
# Auto-detects project type from lock files and config.

if [ -f "Cargo.toml" ]; then
  echo "==> Formatting Rust project"
  cargo fmt
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  echo "==> Formatting Python project"
  if command -v ruff >/dev/null 2>&1; then
    ruff format .
  elif command -v black >/dev/null 2>&1; then
    black .
  else
    echo "Warning: No Python formatter found (install ruff or black)" >&2
  fi
elif [ -f "package.json" ]; then
  echo "==> Formatting Node project"
  if grep -q '"format"' package.json 2>/dev/null; then
    # Detect package manager
    if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
      bun run format
    elif [ -f "pnpm-lock.yaml" ]; then
      pnpm run format
    else
      npm run format
    fi
  elif command -v prettier >/dev/null 2>&1 || [ -f "node_modules/.bin/prettier" ]; then
    npx prettier --write .
  else
    echo "Warning: No format script or prettier found" >&2
  fi
else
  echo "Error: Could not detect project type." >&2
  exit 1
fi

echo "==> dev-format complete."
