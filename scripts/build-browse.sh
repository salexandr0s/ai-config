#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../browse"

command -v bun >/dev/null || {
  echo "Bun required. Install: curl -fsSL https://bun.sh/install | bash"
  exit 1
}

bun install
bun build --compile src/cli.ts --outfile dist/browse

git rev-parse HEAD > dist/.version 2>/dev/null || echo "dev" > dist/.version

echo "Browse daemon built: $(pwd)/dist/browse"
