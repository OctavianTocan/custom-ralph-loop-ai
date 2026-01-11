#!/bin/bash
# Claude Code runner for Ralph
# Usage: run-claude.sh <prompt-file> <log-file> [session-dir] [model]
# Reads prompt from stdin or file, outputs to log file

set -e

PROMPT_FILE="$1"
LOG_FILE="$2"
SESSION_DIR="$3"
MODEL="$4"

if [[ -z "$PROMPT_FILE" || -z "$LOG_FILE" ]]; then
  echo "Usage: run-claude.sh <prompt-file> <log-file> [session-dir] [model]" >&2
  exit 1
fi

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
  echo "" >&2
  echo "❌ Error: Claude CLI not found!" >&2
  echo "" >&2
  echo "To install Claude CLI:" >&2
  echo "  1. Visit: https://claude.ai/docs/cli" >&2
  echo "  2. Follow the installation instructions for your platform" >&2
  echo "" >&2
  echo "After installation, verify with: claude --version" >&2
  echo "" >&2
  exit 1
fi

# Run claude, output to both console and log file (real-time)
# Add --model flag if model is specified
if [[ -n "$MODEL" ]]; then
  claude -p --dangerously-skip-permissions --model "$MODEL" < "$PROMPT_FILE" 2>&1 | tee -a "$LOG_FILE" || true
else
  claude -p --dangerously-skip-permissions < "$PROMPT_FILE" 2>&1 | tee -a "$LOG_FILE" || true
fi
