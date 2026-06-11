#!/usr/bin/env bash
# hooks/forced-eval.sh
#
# Forced-eval hook — fires on session:start.
#
# PURPOSE
#   Without this hook, Claude Code's skill auto-trigger rate is ~20%.
#   Injecting this nudge at session start raises it to ~84% (Scott Spence, Jan 2026).
#
# HOW IT WORKS
#   Claude Code hooks receive a JSON event on stdin. This hook reads the event,
#   confirms it is a session:start event, and writes a system-level instruction
#   to stdout. Claude Code prepends that instruction to the session context before
#   the model sees the user's first message.
#
# REGISTRATION
#   This hook is registered in .claude-plugin/marketplace.json under the plugin's
#   "hooks" key:
#     "hooks": [{ "event": "session:start", "command": "./hooks/forced-eval.sh" }]
#
# PERMISSIONS
#   Must be executable: chmod +x hooks/forced-eval.sh
#
# MAINTENANCE
#   No content changes needed. If activation drops, check:
#     1. File is executable.
#     2. "forced-eval" is the first entry in the skills array in marketplace.json.
#     3. The hooks key is present and correct in marketplace.json.

set -euo pipefail

# Read the event from stdin (Claude Code passes a JSON object).
event=$(cat)

# Only act on session:start events. For any other event, exit silently.
event_type=$(echo "$event" | grep -o '"type":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")
if [ "$event_type" != "session:start" ]; then
  exit 0
fi

# Emit the forced-eval instruction. Claude Code reads this from stdout and
# prepends it to the session context as a system message.
cat <<'INSTRUCTION'
Before generating any response, evaluate whether the user's message matches the
trigger description of any installed skill. If a skill matches, follow that
skill's steps instead of responding generically. Check all installed skills,
not just those explicitly named by the user.
INSTRUCTION
