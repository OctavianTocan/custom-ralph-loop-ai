#!/bin/bash
# Ralph Hook: Validate shell commands before execution
# Receives JSON input via stdin, outputs JSON response
#
# This hook can:
# - Allow commands to proceed
# - Deny dangerous commands
# - Ask user for confirmation
#
# Input: { "command": "...", "conversation_id": "...", ... }
# Output: { "permission": "allow"|"deny"|"ask", "user_message": "...", "agent_message": "..." }

# Read JSON input
INPUT=$(cat)

# Extract command (using jq if available, fallback to grep)
if command -v jq &> /dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.command // ""')
else
  COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# Default: allow all commands
# You can customize this to block dangerous patterns

# Example patterns to deny (uncomment to enable):
# if echo "$COMMAND" | grep -qE "rm -rf /|sudo rm|:(){:|format|mkfs"; then
#   echo '{"permission": "deny", "user_message": "Blocked potentially dangerous command", "agent_message": "This command was blocked by Ralph safety hooks."}'
#   exit 0
# fi

# Example patterns to ask confirmation:
# if echo "$COMMAND" | grep -qE "git push|npm publish|docker push"; then
#   echo '{"permission": "ask", "user_message": "Confirm: About to run a publish/push command", "agent_message": "User confirmation required."}'
#   exit 0
# fi

# Allow the command
echo '{"permission": "allow"}'
