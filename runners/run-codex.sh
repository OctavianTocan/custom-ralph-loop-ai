#!/bin/bash
# OpenAI Codex CLI runner for Ralph
# Usage: run-codex.sh <prompt-file> <log-file> [session-dir] [model]
# Reads prompt from file, outputs to log file

set -e

PROMPT_FILE="$1"
LOG_FILE="$2"
SESSION_DIR="$3"
MODEL="$4"

if [[ -z "$PROMPT_FILE" || -z "$LOG_FILE" ]]; then
  echo "Usage: run-codex.sh <prompt-file> <log-file> [session-dir] [model]" >&2
  exit 1
fi

# Check if codex CLI is available
if ! command -v codex &> /dev/null; then
  echo "" >&2
  echo "❌ Error: OpenAI Codex CLI not found!" >&2
  echo "" >&2
  echo "To install Codex CLI:" >&2
  echo "  npm install -g @openai/codex-cli" >&2
  echo "" >&2
  echo "You'll also need to set your OpenAI API key:" >&2
  echo "  export OPENAI_API_KEY=your_api_key_here" >&2
  echo "" >&2
  echo "After installation, verify with: codex --version" >&2
  echo "" >&2
  exit 1
fi

# Read prompt content
PROMPT_CONTENT=$(cat "$PROMPT_FILE")

# Run codex exec with --full-auto for autonomous execution
# Add --model flag if model is specified
# Use - to read prompt from stdin
if [[ -n "$MODEL" ]]; then
  echo "$PROMPT_CONTENT" | codex exec --full-auto --model "$MODEL" - 2>&1 | tee -a "$LOG_FILE" || true
else
  echo "$PROMPT_CONTENT" | codex exec --full-auto - 2>&1 | tee -a "$LOG_FILE" || true
fi
