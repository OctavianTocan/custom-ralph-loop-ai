#!/bin/bash
# Claude Code runner for Ralph
# Usage: run-claude.sh <prompt-file> <log-file> [session-dir] [model]
#
# Enhanced with features from Claude CLI print mode:
# - JSON output format for structured responses
# - Fallback model support
# - Session management
# - Real-time streaming with structured parsing

set -e

PROMPT_FILE="$1"
LOG_FILE="$2"
SESSION_DIR="$3"
MODEL="$4"

# Default fallback model (used when primary model is overloaded)
FALLBACK_MODEL="${RALPH_FALLBACK_MODEL:-haiku}"

if [[ -z "$PROMPT_FILE" || -z "$LOG_FILE" ]]; then
  echo "Usage: run-claude.sh <prompt-file> <log-file> [session-dir] [model]" >&2
  exit 1
fi

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
  echo "" >&2
  echo "Error: Claude CLI not found!" >&2
  echo "" >&2
  echo "To install Claude CLI:" >&2
  echo "  1. Visit: https://claude.ai/docs/cli" >&2
  echo "  2. Follow the installation instructions for your platform" >&2
  echo "" >&2
  echo "After installation, verify with: claude --version" >&2
  echo "" >&2
  exit 1
fi

# Colors for terminal output
C='\033[0;36m'
G='\033[0;32m'
Y='\033[1;33m'
D='\033[2m'
N='\033[0m'
BOLD='\033[1m'

# Enhanced separator
echo ""
echo -e "${C}========================================================================${N}"
echo -e "${BOLD}Starting Claude Agent${N}"
echo -e "${C}========================================================================${N}"
echo ""

# Build command arguments
CMD_ARGS=("-p" "--verbose" "--dangerously-skip-permissions")

# Add model if specified
if [[ -n "$MODEL" ]]; then
  CMD_ARGS+=("--model" "$MODEL")
  # Add fallback model for reliability
  CMD_ARGS+=("--fallback-model" "$FALLBACK_MODEL")
fi

# Optional: Use JSON output for structured responses (can be enabled via env var)
# This provides cost tracking, token counts, etc.
if [[ "${RALPH_JSON_OUTPUT:-false}" == "true" ]]; then
  CMD_ARGS+=("--output-format" "json")
else
  # Default: Use stream-json with pretty-printer for better visibility
  CMD_ARGS+=("--output-format" "stream-json")
fi

# Optional: Ephemeral session (no disk storage)
if [[ "${RALPH_EPHEMERAL:-false}" == "true" ]]; then
  CMD_ARGS+=("--no-session-persistence")
fi

# Optional: Custom system prompt append
if [[ -n "${RALPH_SYSTEM_PROMPT_APPEND:-}" ]]; then
  CMD_ARGS+=("--append-system-prompt" "$RALPH_SYSTEM_PROMPT_APPEND")
fi

# Find pretty-printer script (should be in same dir as ralph.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRETTY_PRINTER="$SCRIPT_DIR/ralph-pretty-print.sh"

# Run claude with prompt from file
# Output to both console and log file (real-time)
if [[ "${RALPH_JSON_OUTPUT:-false}" == "true" ]]; then
  # JSON mode: parse and display structured output
  RESULT=$(claude "${CMD_ARGS[@]}" < "$PROMPT_FILE" 2>&1)
  echo "$RESULT" >> "$LOG_FILE"

  # Extract and display key info
  if command -v jq &> /dev/null; then
    IS_ERROR=$(echo "$RESULT" | jq -r '.is_error // false')
    COST=$(echo "$RESULT" | jq -r '.total_cost_usd // "?"')
    RESULT_TEXT=$(echo "$RESULT" | jq -r '.result // ""')

    echo "$RESULT_TEXT"
    echo ""
    echo -e "${D}Cost: \$${COST}${N}"

    if [[ "$IS_ERROR" == "true" ]]; then
      echo -e "${Y}Warning: Claude reported an error${N}" | tee -a "$LOG_FILE"
    fi
  else
    echo "$RESULT"
  fi
else
  # Stream-json mode: Pipe through pretty-printer for terminal, tee raw JSON to log
  if [[ -x "$PRETTY_PRINTER" ]]; then
    # Pretty-printer available: tee raw JSON to log, pipe through pretty-printer for display
    claude "${CMD_ARGS[@]}" < "$PROMPT_FILE" 2>&1 | tee -a "$LOG_FILE" | "$PRETTY_PRINTER" || true
  else
    # Pretty-printer not found: fallback to showing raw JSON
    echo -e "${Y}Warning: ralph-pretty-print.sh not found, showing raw output${N}" >&2
    claude "${CMD_ARGS[@]}" < "$PROMPT_FILE" 2>&1 | tee -a "$LOG_FILE" || true
  fi
fi

echo ""
echo -e "${C}========================================================================${N}"
echo -e "${BOLD}Claude Agent Complete${N}"
echo -e "${C}========================================================================${N}"
echo ""
