# Review Checklist

Structured 2-pass review system. CRITICAL findings block merge; INFORMATIONAL findings are advisory.

---

## Pass 1: CRITICAL (blocking)

### SQL & Data Safety

- No string interpolation in queries (use parameterized queries)
- No TOCTOU (time-of-check-to-time-of-use) in data operations
- No N+1 query patterns
- Transactions used for multi-step data mutations

### Race Conditions & Concurrency

- No shared mutable state without synchronization
- Async operations ordered correctly
- No TOCTOU in file or resource access

### LLM Output Trust Boundary

- LLM values validated before DB writes
- LLM output never used in SQL, shell commands, or file paths without sanitization
- LLM-generated HTML sanitized before rendering

### Input Validation

- User input validated before reaching DB or shell
- Zod schemas at API boundaries
- No type assertions (`as`) bypassing validation
- No unchecked property access on external data

### Error Handling

- No swallowed errors (empty catch blocks)
- No internal details leaked to clients
- Error boundaries present in UI components
- Unhandled promise rejections caught

---

## Pass 2: INFORMATIONAL (non-blocking)

### Performance

- No unnecessary re-renders (missing memo/useMemo/useCallback where needed)
- No synchronous bottlenecks in hot paths
- Database indexes exist for queried fields
- Lists and iterations bounded

### Code Quality

- No dead code or unreachable branches
- Cyclomatic complexity reasonable
- No magic values (use named constants)
- Naming is clear and consistent

### Test Gaps

- New behavior has corresponding tests
- Edge cases covered (empty input, boundary values, error paths)
- Integration points tested

### Convention Deviations

- Follows project CLAUDE.md coding style
- File naming matches conventions
- Import organization consistent

### Documentation

- Public APIs documented
- Non-obvious logic has inline comments
- Breaking changes noted in CHANGELOG
