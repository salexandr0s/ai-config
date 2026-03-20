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

  # Install deps if node_modules missing
  if [ ! -d "node_modules" ]; then
    echo "==> Installing dependencies..."
    $PM install
  fi

  # Typecheck
  if grep -q '"typecheck"' package.json 2>/dev/null; then
    echo "==> Running typecheck..."
    $PM run typecheck
  elif grep -q '"tsc"' package.json 2>/dev/null || [ -f "tsconfig.json" ]; then
    echo "==> Running tsc --noEmit..."
    npx tsc --noEmit
  fi

  # Lint
  if grep -q '"lint"' package.json 2>/dev/null; then
    echo "==> Running lint..."
    $PM run lint
  fi

  # Tests
  if [ "$QUICK" = false ]; then
    if grep -q '"test"' package.json 2>/dev/null; then
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
