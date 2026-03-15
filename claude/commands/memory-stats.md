Show MEMORY system statistics and health.

Context: $ARGUMENTS

1. CHECK structure:
   - Verify ~/.claude/MEMORY/ exists with expected subdirectories
   - Report any missing directories

2. GATHER stats:
   - Directory sizes: `du -sh ~/.claude/MEMORY/*/`
   - SESSIONS: count of .jsonl files + total line count
   - SIGNALS: count of entries in ratings.jsonl and sentiment.jsonl
   - STATE: line count in events.jsonl
   - LEARNINGS: list files with line counts
   - Last rotation date from STATE/last-rotation.json

3. COMPUTE signals summary (if data exists):
   - Rating: average score from last 50 entries in ratings.jsonl
   - Sentiment: trend from last 50 entries in sentiment.jsonl
   - Sessions: total count, avg duration, most active project

4. REPORT as table:

   ```
   MEMORY System Health
   ====================
   Directory      Size     Entries
   SESSIONS/      X KB     N files
   SIGNALS/       X KB     N entries
   LEARNINGS/     X KB     N files
   STATE/         X KB     N events
   RESEARCH/      X KB     N files

   Last rotation: YYYY-MM-DD
   Rating avg: X.X (N ratings)
   Sentiment: trend (N entries)
   Top project: name (N sessions)
   ```

Rules:
- Read-only — do not modify any MEMORY files
- If MEMORY/ doesn't exist, suggest running setup-memory.sh
- Handle missing/empty files gracefully
