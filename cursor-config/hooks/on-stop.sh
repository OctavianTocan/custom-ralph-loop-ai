#!/bin/bash
# Ralph Hook: Handle agent stop - check for task completion
# Receives JSON input via stdin when agent stops
#
# Input: { "conversation_id": "...", "generation_id": "...", ... }
# Output: { "followup_message": "..." } - optional, to auto-continue
#
# This hook can trigger follow-up messages (max 5 per conversation)
# for Ralph's multi-iteration loop pattern.

# Read JSON input
INPUT=$(cat)

# Find active Ralph session
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Look for active session directory
SESSION_DIR=""
if [[ -d "$PROJECT_ROOT/sessions" ]]; then
  LATEST_SESSION=$(ls -t "$PROJECT_ROOT/sessions/" 2>/dev/null | head -1)
  if [[ -n "$LATEST_SESSION" ]]; then
    SESSION_DIR="$PROJECT_ROOT/sessions/$LATEST_SESSION"
  fi
fi

# Check if we should auto-continue (Ralph loop behavior)
# This requires a special marker file that ralph.sh would create
AUTO_CONTINUE_FILE="$SESSION_DIR/.ralph-auto-continue"

if [[ -f "$AUTO_CONTINUE_FILE" ]]; then
  # Read the continuation prompt
  CONTINUE_PROMPT=$(cat "$AUTO_CONTINUE_FILE")

  # Remove the marker to prevent infinite loops
  rm -f "$AUTO_CONTINUE_FILE"

  # Return a follow-up message to continue the loop
  if command -v jq &> /dev/null; then
    echo "{\"followup_message\": $(echo "$CONTINUE_PROMPT" | jq -Rs .)}"
  else
    # Escape the prompt for JSON
    ESCAPED=$(echo "$CONTINUE_PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')
    echo "{\"followup_message\": \"$ESCAPED\"}"
  fi
else
  # No follow-up needed
  echo '{}'
fi

exit 0
