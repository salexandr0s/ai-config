Multi-model code review — get a second opinion from another AI model.

$ARGUMENTS

---

## Modes

Detect from $ARGUMENTS:
- **review** (default): Standard code review
- **challenge**: Adversarial — find edge cases, security holes, race conditions
- **consult**: Open-ended Q&A about the diff

---

## Process

### Step 1: Get the Diff

```bash
# Staged changes
git diff --cached
# Or unstaged
git diff
# Or specific commit range from $ARGUMENTS
```

If no changes found, ask the user what to review.

### Step 2: Get API Key

```bash
# Try vault first
OPENAI_KEY=$("$HOME/.claude/claudecodex-vault.sh" get OPENAI_API_KEY 2>/dev/null || echo "")
# Fall back to environment
OPENAI_KEY="${OPENAI_KEY:-$OPENAI_API_KEY}"
```

If no key available, inform the user:
"No OpenAI API key found. Set one with: `~/.claude/claudecodex-vault.sh set OPENAI_API_KEY sk-...`"

### Step 3: Send to OpenAI

Construct the prompt based on mode:

**Review mode:**
```
Review this code diff. Focus on: correctness, security, performance, maintainability.
For each finding: severity (critical/important/minor), file:line, description, suggested fix.
```

**Challenge mode:**
```
You are an adversarial code reviewer. Your job is to break this code.
Find: edge cases that will crash, security vulnerabilities, race conditions, data corruption paths, inputs that cause unexpected behavior.
For each finding: attack vector, severity, proof of concept.
```

**Consult mode:**
```
The developer wants your opinion on this code change. Answer their question: {$ARGUMENTS after "consult"}.
If no specific question, provide: overall assessment, alternative approaches considered, long-term maintenance implications.
```

Send via curl:
```bash
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4.1",
    "messages": [
      {"role": "system", "content": "{mode-specific system prompt}"},
      {"role": "user", "content": "{the diff}"}
    ],
    "temperature": 0.3
  }'
```

### Step 4: Overlap Analysis

After receiving the OpenAI response, present:

```
## Cross-Review Results

### Mode: {review/challenge/consult}

### Agreed Findings (High Confidence)
Findings that both Claude and OpenAI flagged:
- {finding}

### Claude-Only Findings
Issues I identified that the other model didn't:
- {finding}

### OpenAI-Only Findings
Issues the other model identified that I didn't:
- {finding}

### Combined Verdict
{Overall assessment considering both perspectives}
{Recommendation: merge / revise / discuss}
```

---

## Rules

- Never send code to external APIs without the user's awareness (this command is explicit consent)
- If the diff is too large (> 10,000 tokens), summarize and send the most critical sections
- Do not send file contents that look like secrets, credentials, or .env files
- If the API call fails, show the error and suggest alternatives
