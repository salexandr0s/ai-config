#!/usr/bin/env bash
set -euo pipefail

# dev-verify — full quality check (lint + typecheck + tests)
# Auto-detects project type from lock files and config.
# Usage: dev-verify [--quick]

QUICK=false
if [ "${1:-}" = "--quick" ]; then
  QUICK=true
fi

# Detect project type
if [ -f "Cargo.toml" ]; then
  echo "==> Detected Rust project"
  cargo check
  cargo clippy -- -D warnings
  if [ "$QUICK" = false ]; then
    cargo test
  fi
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  echo "==> Detected Python project"
  if command -v ruff >/dev/null 2>&1; then
    ruff check .
  fi
  if command -v mypy >/dev/null 2>&1; then
    mypy .
  fi
  if [ "$QUICK" = false ]; then
    if command -v pytest >/dev/null 2>&1; then
      pytest
    fi
  fi
elif [ -f "package.json" ]; then
  echo "==> Detected Node project"

  # Detect package manager
  if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    PM="bun"
  elif [ -f "pnpm-lock.yaml" ]; then
    PM="pnpm"
  elif [ -f "yarn.lock" ]; then
    PM="yarn"
  else
    PM="npm"
  fi
  echo "    Package manager: $PM"

  # Helper: check if a script exists in package.json
  has_script() {
    if command -v jq >/dev/null 2>&1; then
      jq -e ".scripts.\"$1\"" package.json >/dev/null 2>&1
    else
      # Fallback: check scripts block with python3
      python3 -c "import json; s=json.load(open('package.json')).get('scripts',{}); exit(0 if '$1' in s else 1)" 2>/dev/null
    fi
  }

  # Install deps if node_modules missing
  if [ ! -d "node_modules" ]; then
    echo "==> Installing dependencies..."
    $PM install
  fi

  # Typecheck
  if has_script typecheck; then
    echo "==> Running typecheck..."
    $PM run typecheck
  elif [ -f "tsconfig.json" ]; then
    echo "==> Running tsc --noEmit..."
    npx tsc --noEmit
  fi

  # Lint
  if has_script lint; then
    echo "==> Running lint..."
    $PM run lint
  fi

  # Tests
  if [ "$QUICK" = false ]; then
    if has_script test; then
      echo "==> Running tests..."
      $PM run test
    fi
  else
    echo "==> Skipping tests (--quick)"
  fi
else
  echo "Error: Could not detect project type." >&2
  echo "Expected one of: Cargo.toml, pyproject.toml, package.json" >&2
  exit 1
fi

echo ""
echo "==> dev-verify complete$([ "$QUICK" = true ] && echo ' (quick mode)' || echo '')."
