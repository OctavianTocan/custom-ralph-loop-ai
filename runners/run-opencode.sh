#!/bin/bash
# OpenCode runner for Ralph
# Usage: run-opencode.sh <prompt-file> <log-file> [session-dir] [model]
# Reads prompt from file, outputs to log file

set -e

PROMPT_FILE="$1"
LOG_FILE="$2"
SESSION_DIR="${3:-$(pwd)}"
MODEL="$4"

if [[ -z "$PROMPT_FILE" || -z "$LOG_FILE" ]]; then
  echo "Usage: run-opencode.sh <prompt-file> <log-file> [session-dir] [model]" >&2
  exit 1
fi

# Check if opencode CLI is available
if ! command -v opencode &> /dev/null; then
  echo "" >&2
  echo "❌ Error: OpenCode CLI not found!" >&2
  echo "" >&2
  echo "To install OpenCode CLI:" >&2
  echo "  npm install -g @opencode-ai/cli" >&2
  echo "" >&2
  echo "You'll also need to configure a provider (Anthropic, OpenAI, etc.):" >&2
  echo "  See: https://opencode.ai/docs" >&2
  echo "" >&2
  echo "After installation, verify with: opencode --version" >&2
  echo "" >&2
  exit 1
fi

# Read prompt content
PROMPT_CONTENT=$(cat "$PROMPT_FILE")

# Ensure OpenCode config exists in session directory
CONFIG_FILE="$SESSION_DIR/opencode.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="$SCRIPT_DIR/../agent-configs/opencode.json"

if [[ ! -f "$CONFIG_FILE" && -f "$DEFAULT_CONFIG" ]]; then
  cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
fi

# Run opencode with JSON format for parsing
# OpenCode takes prompt as argument, not stdin
# Add --model flag if model is specified
# Change to session directory to ensure config is picked up
if [[ -n "$MODEL" ]]; then
  (cd "$SESSION_DIR" && opencode run --format json --model "$MODEL" "$PROMPT_CONTENT" 2>&1 | tee -a "$LOG_FILE" || true)
else
  (cd "$SESSION_DIR" && opencode run --format json "$PROMPT_CONTENT" 2>&1 | tee -a "$LOG_FILE" || true)
fi
