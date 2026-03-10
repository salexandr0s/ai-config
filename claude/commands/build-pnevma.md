Run the Pnevma build cycle with diagnosis and recovery.

Context: $ARGUMENTS

Prerequisites: Must be in ~/GitHub/pnevma or a subdirectory.

1. PRE-FLIGHT:
   - Verify: `rustc --version`, `cargo --version`, `zig version`, `xcodebuild -version`
   - Check ~/GitHub/.memory/pitfalls/\_active.md for known Pnevma build issues

2. BUILD (in order):
   a. `just check` — fmt + clippy + tests + audit
   b. `just xcode-build` — Swift app (depends on rust lib)

   On failure at any step:
   - Read error output carefully
   - Check if it matches a known pitfall
   - Attempt fix
   - Re-run the failed step only
   - If fix doesn't work: report with full error context

3. POST-BUILD:
   - Report which steps passed/failed
   - If all green: "Build green. Ready for testing."
   - If failures: detailed error + suggested next steps

4. If $ARGUMENTS contains "release":
   - Use `just release` instead of debug builds
   - Run `cargo audit` for vulnerability scan
   - Report any accepted risks from .cargo/audit.toml

Rules:

- Never skip clippy warnings — fix them
- If xcframework is missing, point to `docs/ghostty-build.md` for Ghostty build instructions
- Log new FFI-related failures to pitfalls if not already there
