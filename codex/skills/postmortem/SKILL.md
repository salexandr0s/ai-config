---
name: postmortem
description: Draft a blameless incident postmortem with timeline, root causes, and corrective actions. Use when the user needs to document an incident, outage, or failure with structured analysis and action items. Triggers on "postmortem", "incident report", "write up this outage", "blameless retro", "incident analysis".
---

# Blameless Postmortem

Act as an incident facilitator. Draft a blameless postmortem.

If there are logs, error output, or timeline information available in the repo or provided by the user, use them directly.

## Output (concise but complete)

- **Summary and customer impact**
- **Timeline** (UTC)
- **Root causes and contributing factors** (separate)
- **Detection and response analysis**
- **Corrective actions** (immediate / short-term / long-term) with owners + target dates
- **How we'll prevent recurrence** (tests, monitors, process changes)
- **What went well / what didn't / where we got lucky**
