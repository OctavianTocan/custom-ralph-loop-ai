#!/bin/bash
# Ralph Real-Time Watch Mode
# Usage: ./watch.sh [--session session-name] [--interval seconds]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DIR=""
INTERVAL=2

while [[ $# -gt 0 ]]; do
  case $1 in
    --session)
      SESSION_DIR="$2"
      shift 2
      ;;
    --interval|-i)
      INTERVAL="$2"
      shift 2
      ;;
    *)
      if [[ -z "$SESSION_DIR" ]]; then
        SESSION_DIR="$1"
      fi
      shift
      ;;
  esac
done

# Resolve session directory
if [[ -n "$SESSION_DIR" ]]; then
  if [[ ! "$SESSION_DIR" =~ ^/ && ! "$SESSION_DIR" =~ ^\./ ]]; then
    SESSION_DIR="$SCRIPT_DIR/sessions/$SESSION_DIR"
  fi
fi

# Find active session
if [[ -z "$SESSION_DIR" ]]; then
  LATEST_SESSION=$(ls -t "$SCRIPT_DIR/sessions/" 2>/dev/null | head -1)
  if [[ -n "$LATEST_SESSION" && -d "$SCRIPT_DIR/sessions/$LATEST_SESSION" ]]; then
    SESSION_DIR="$SCRIPT_DIR/sessions/$LATEST_SESSION"
  fi
fi

if [[ -z "$SESSION_DIR" || ! -f "$SESSION_DIR/prd.json" ]]; then
  echo "Error: No active session found"
  exit 1
fi

LOG_FILE="$SESSION_DIR/ralph.log"
LAST_SIZE=0

# Colors
G='\033[0;32m'
Y='\033[1;33m'
R='\033[0;31m'
C='\033[0;36m'
D='\033[2m'
N='\033[0m'
BOLD='\033[1m'

# Clear screen and show header
clear
echo -e "${BOLD}${C}========================================================================${N}"
echo -e "${BOLD}${G}RALPH${N} ${D}REAL-TIME MONITORING${N} ${D}(Ctrl+C to exit)${N}"
echo -e "${BOLD}${C}========================================================================${N}"
echo ""

# Trap Ctrl+C
trap 'echo ""; echo "Stopping watch mode..."; exit 0' INT

# Detect OS for portable stat command
if [[ "$(uname)" == "Darwin" ]]; then
  STAT_CMD="stat -f%z"
else
  STAT_CMD="stat -c%s"
fi

while true; do
  # Get current log size
  if [[ -f "$LOG_FILE" ]]; then
    CURRENT_SIZE=$($STAT_CMD "$LOG_FILE" 2>/dev/null || echo "0")

    # If log grew, show new content
    if [[ $CURRENT_SIZE -gt $LAST_SIZE ]]; then
      # Show new lines
      tail -c +$((LAST_SIZE + 1)) "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        # Colorize based on content
        if echo "$line" | grep -qE "\[read\]|\[write\]|\[edit\]|\[run\]|\[search\]|\[grep\]|\[ls\]"; then
          echo -e "${D}$line${N}"
        elif echo "$line" | grep -qE "COMPLETE|BLOCKED|ERROR"; then
          echo -e "${BOLD}${Y}$line${N}"
        elif echo "$line" | grep -qE " ok"; then
          echo -e "${G}$line${N}"
        elif echo "$line" | grep -qE "FAIL"; then
          echo -e "${R}$line${N}"
        elif echo "$line" | grep -qE "Iteration|---"; then
          echo -e "${BOLD}${C}$line${N}"
        else
          echo "$line"
        fi
      done

      LAST_SIZE=$CURRENT_SIZE
    fi
  fi

  # Note: Status updates removed - they were interfering with log streaming
  # Users can run './status.sh' in another terminal if needed

  sleep "$INTERVAL"
done
