#!/bin/bash
# Ralph Stop Script
# Usage: ./stop.sh [--session session-name]
#        Or: pnpm ralph:stop [--session session-name] (if added to package.json)
# Stops all ralph processes, or only those for a specific session

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DIR=""
SESSION_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --session)
      SESSION_NAME="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Resolve session directory if specified
if [[ -n "$SESSION_NAME" ]]; then
  if [[ ! "$SESSION_NAME" =~ ^/ && ! "$SESSION_NAME" =~ ^\./ ]]; then
    SESSION_DIR="$SCRIPT_DIR/sessions/$SESSION_NAME"
  else
    SESSION_DIR="$SESSION_NAME"
  fi

  if [[ ! -d "$SESSION_DIR" ]]; then
    echo "Error: Session not found: $SESSION_NAME"
    echo ""
    echo "Available sessions:"
    ls -1 "$SCRIPT_DIR/sessions/" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
    exit 1
  fi
fi

# Colors
G='\033[0;32m'
R='\033[0;31m'
Y='\033[1;33m'
N='\033[0m'
BOLD='\033[1m'

echo ""
echo "============================================================================"
echo "                          RALPH STOP"
echo "============================================================================"
echo ""

if [[ -n "$SESSION_NAME" ]]; then
  echo -e "  ${BOLD}Target:${N} Session '$SESSION_NAME'"
  echo ""
  
  # Kill processes for this specific session
  SESSION_PATH=$(realpath "$SESSION_DIR" 2>/dev/null || echo "$SESSION_DIR")
  
  # Find PIDs matching this session
  PIDS=$(ps aux | grep -E "(ralph\.sh|run-cursor\.sh|cursor.*agent)" | grep -v grep | grep -F "$SESSION_PATH" | awk '{print $2}' | sort -u)
  
  if [[ -z "$PIDS" ]]; then
    echo -e "  ${Y}No running processes found for this session${N}"
  else
    echo -e "  ${BOLD}Found processes:${N}"
    ps aux | grep -E "(ralph\.sh|run-cursor\.sh|cursor.*agent)" | grep -v grep | grep -F "$SESSION_PATH" | awk '{printf "    PID %-8s %s\n", $2, substr($0, index($0,$11))}'
    echo ""
    
    # Kill them
    echo -e "  ${BOLD}Stopping...${N}"
    echo "$PIDS" | xargs kill -9 2>/dev/null || true
    sleep 0.5
    
    # Verify
    REMAINING=$(ps aux | grep -E "(ralph\.sh|run-cursor\.sh|cursor.*agent)" | grep -v grep | grep -F "$SESSION_PATH" | awk '{print $2}' | wc -l)
    if [[ "$REMAINING" -eq 0 ]]; then
      echo -e "  ${G}✓ All processes stopped${N}"
    else
      echo -e "  ${Y}Warning: Some processes may still be running${N}"
    fi
  fi
  
  # Clean up lock file
  LOCK_FILE="$SESSION_DIR/.ralph.lock"
  if [[ -f "$LOCK_FILE" ]]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if ! kill -0 "$LOCK_PID" 2>/dev/null; then
      rm -f "$LOCK_FILE"
      echo -e "  ${G}✓ Removed stale lock file${N}"
    else
      echo -e "  ${Y}Lock file still exists (process may not have cleaned up)${N}"
      rm -f "$LOCK_FILE"
    fi
  fi
  
else
  echo -e "  ${BOLD}Target:${N} All ralph processes"
  echo ""
  
  # Find all ralph-related PIDs
  PIDS=$(ps aux | grep -iE "(ralph\.sh|run-cursor\.sh|cursor.*agent.*ralph)" | grep -v grep | awk '{print $2}' | sort -u)
  
  if [[ -z "$PIDS" ]]; then
    echo -e "  ${Y}No ralph processes found${N}"
  else
    echo -e "  ${BOLD}Found processes:${N}"
    ps aux | grep -iE "(ralph\.sh|run-cursor\.sh|cursor.*agent.*ralph)" | grep -v grep | awk '{printf "    PID %-8s %s\n", $2, substr($0, index($0,$11))}'
    echo ""
    
    # Kill them
    echo -e "  ${BOLD}Stopping...${N}"
    echo "$PIDS" | xargs kill -9 2>/dev/null || true
    sleep 0.5
    
    # Verify
    REMAINING=$(ps aux | grep -iE "(ralph\.sh|run-cursor\.sh|cursor.*agent.*ralph)" | grep -v grep | wc -l)
    if [[ "$REMAINING" -eq 0 ]]; then
      echo -e "  ${G}✓ All processes stopped${N}"
    else
      echo -e "  ${Y}Warning: $REMAINING processes may still be running${N}"
    fi
  fi
  
  # Clean up all stale lock files
  echo ""
  echo -e "  ${BOLD}Cleaning up lock files...${N}"
  STALE_LOCKS=0
  for LOCK_FILE in "$SCRIPT_DIR/sessions"/*/.ralph.lock; do
    if [[ -f "$LOCK_FILE" ]]; then
      LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
      if ! kill -0 "$LOCK_PID" 2>/dev/null 2>/dev/null; then
        rm -f "$LOCK_FILE"
        STALE_LOCKS=$((STALE_LOCKS + 1))
      fi
    fi
  done
  
  if [[ "$STALE_LOCKS" -gt 0 ]]; then
    echo -e "  ${G}✓ Removed $STALE_LOCKS stale lock file(s)${N}"
  else
    echo -e "  ${Y}No stale lock files found${N}"
  fi
fi

echo ""
echo "============================================================================"
echo ""
