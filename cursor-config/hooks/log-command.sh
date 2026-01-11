#!/bin/bash
# Ralph Hook: Log command execution for progress tracking
# Receives JSON input via stdin after shell command completes
#
# Input: { "command": "...", "output": "...", "duration": 1234, ... }
# Output: (none required, but must exit 0)

# Read JSON input
INPUT=$(cat)

# Find active Ralph session log
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Look for active session (most recently modified ralph.log)
RALPH_LOG=""
if [[ -d "$PROJECT_ROOT/sessions" ]]; then
  RALPH_LOG=$(find "$PROJECT_ROOT/sessions" -name "ralph.log" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
fi

# If we found an active session, log the command
if [[ -n "$RALPH_LOG" && -f "$RALPH_LOG" ]]; then
  # Extract command and duration
  if command -v jq &> /dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.command // ""')
    DURATION=$(echo "$INPUT" | jq -r '.duration // 0')
    EXIT_CODE=$(echo "$INPUT" | jq -r '.exit_code // 0')
  else
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    DURATION="?"
    EXIT_CODE="?"
  fi

  # Log in a format consistent with Ralph's other runners
  # Truncate command to 70 chars for readability
  SHORT_CMD="${COMMAND:0:70}"
  [[ ${#COMMAND} -gt 70 ]] && SHORT_CMD="${SHORT_CMD}..."

  if [[ "$EXIT_CODE" == "0" ]]; then
    echo "[run] $SHORT_CMD ok" >> "$RALPH_LOG"
  else
    echo "[run] $SHORT_CMD FAIL (exit $EXIT_CODE)" >> "$RALPH_LOG"
  fi
fi

# Always exit 0 to not block the agent
exit 0
