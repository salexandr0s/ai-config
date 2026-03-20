#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../browse"

command -v bun >/dev/null || {
  echo "Bun required. Install: curl -fsSL https://bun.sh/install | bash"
  exit 1
}

bun install

mkdir -p dist

# Try compiled binary first; fall back to wrapper script if Playwright
# resists static compilation (native deps like chromium-bidi, electron)
if bun build --compile src/cli.ts --outfile dist/browse 2>/dev/null; then
  echo "  Built compiled binary: $(pwd)/dist/browse"
else
  echo "  Compiled binary failed (Playwright native deps) — creating wrapper"
  BUN_PATH="$(command -v bun)"
  cat > dist/browse <<WRAPPER
#!/usr/bin/env bash
exec "$BUN_PATH" "$(pwd)/src/cli.ts" "\$@"
WRAPPER
  chmod +x dist/browse
  echo "  Built wrapper script: $(pwd)/dist/browse"
fi

git rev-parse HEAD > dist/.version 2>/dev/null || echo "dev" > dist/.version
