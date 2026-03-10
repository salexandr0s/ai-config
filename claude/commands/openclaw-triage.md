Run OpenClaw/ClawControl health diagnostics and propose fixes.

Context: $ARGUMENTS

1. GATEWAY CHECK:
   - Is the OpenClaw gateway running? `curl -s http://127.0.0.1:18789/health`
   - If down: check process list, suggest restart command

2. AGENT HEALTH:
   - Check agent heartbeat status
   - Check cron jobs: `crontab -l | grep -i openclaw`
   - Check for stale lock files or zombie processes

3. AUTH/TOKEN STATUS:
   - Check OAuth token expiry (if token files exist in ~/.openclaw/secrets/)
   - Check API key validity where possible

4. DATA INTEGRITY:
   - Check workflow DB state (SQLite queries if path is known)
   - Check memory-agent wiring (QMD collections status)
   - Run `qmd search "health" -c memory` for recent health-related notes

5. UPSTREAM COMPATIBILITY (if $ARGUMENTS mentions "upgrade" or "version"):
   - Fetch/read upstream OpenClaw release notes
   - Scan ClawControl code for breakage risk
   - Produce fix plan + test checklist

6. REPORT:

   ## OpenClaw Triage Report

   ### Status: Healthy / Degraded / Down

   ### Findings
   - [each finding with status and recommended action]

   ### Immediate Actions
   - [commands to run, in order]

   ### Follow-ups
   - [things to monitor or investigate later]
