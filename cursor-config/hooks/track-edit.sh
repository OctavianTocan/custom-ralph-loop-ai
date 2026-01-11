#!/bin/bash
# Ralph Hook: Track file edits for session logging
# Receives JSON input via stdin after file edit completes
#
# Input: { "file_path": "...", "edits": [...], ... }
# Output: (none required, but must exit 0)

# Read JSON input
INPUT=$(cat)

# Find active Ralph session log
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Look for active session
RALPH_LOG=""
if [[ -d "$PROJECT_ROOT/sessions" ]]; then
  RALPH_LOG=$(find "$PROJECT_ROOT/sessions" -name "ralph.log" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
fi

# If we found an active session, log the edit
if [[ -n "$RALPH_LOG" && -f "$RALPH_LOG" ]]; then
  # Extract file path
  if command -v jq &> /dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // ""')
    NUM_EDITS=$(echo "$INPUT" | jq -r '.edits | length // 0')
  else
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    NUM_EDITS="?"
  fi

  # Get just the filename
  BASENAME=$(basename "$FILE_PATH")

  # Log in a format consistent with Ralph's other runners
  echo "[edit] $BASENAME ok" >> "$RALPH_LOG"
fi

# Always exit 0 to not block the agent
exit 0
