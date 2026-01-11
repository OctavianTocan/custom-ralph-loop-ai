#!/bin/bash
# Ralph Status Checker
# Usage: ./status.sh [--session session-name]
#        Or: pnpm ralph:status [--session session-name] (if added to package.json)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --session)
      SESSION_DIR="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Colors
G='\033[0;32m'
Y='\033[1;33m'
R='\033[0;31m'
B='\033[0;34m'
C='\033[0;36m'
D='\033[2m'
N='\033[0m'
BOLD='\033[1m'

echo ""
echo "============================================================================"
echo "                          RALPH STATUS"
echo "============================================================================"
echo ""

# Check if Ralph is running
RALPH_PID=$(pgrep -f "ralph.sh" 2>/dev/null | head -1)
CURSOR_PID=$(pgrep -f "cursor.*agent.*-p" 2>/dev/null | head -1)

if [[ -n "$RALPH_PID" ]]; then
  echo -e "  Loop:   ${G}RUNNING${N} (PID: $RALPH_PID)"
else
  echo -e "  Loop:   ${D}stopped${N}"
fi

if [[ -n "$CURSOR_PID" ]]; then
  echo -e "  Agent:  ${G}ACTIVE${N} (PID: $CURSOR_PID)"
else
  echo -e "  Agent:  ${D}idle${N}"
fi

echo ""

# Find active session
if [[ -z "$SESSION_DIR" ]]; then
  LATEST_SESSION=$(ls -t "$SCRIPT_DIR/sessions/" 2>/dev/null | head -1)
  if [[ -n "$LATEST_SESSION" && -d "$SCRIPT_DIR/sessions/$LATEST_SESSION" ]]; then
    SESSION_DIR="$SCRIPT_DIR/sessions/$LATEST_SESSION"
  fi
fi

if [[ -n "$SESSION_DIR" && -f "$SESSION_DIR/prd.json" ]]; then
  SESSION_NAME=$(basename "$SESSION_DIR")
  echo -e "  ${BOLD}Session:${N} $SESSION_NAME"
  echo ""
  
  # Count tasks
  if command -v jq &> /dev/null; then
    TOTAL=$(jq '.userStories | length' "$SESSION_DIR/prd.json" 2>/dev/null)
    COMPLETED=$(jq '[.userStories[] | select(.passes == true)] | length' "$SESSION_DIR/prd.json" 2>/dev/null)
    PENDING=$((TOTAL - COMPLETED))
    
    if [[ $TOTAL -gt 0 ]]; then
      PCT=$((COMPLETED * 100 / TOTAL))
      BAR_WIDTH=50
      FILLED=$((PCT * BAR_WIDTH / 100))
      EMPTY=$((BAR_WIDTH - FILLED))
      
      echo -e "  ${BOLD}Progress:${N}"
      printf "  ["
      printf "${G}%${FILLED}s${N}" | tr ' ' '#'
      printf "${D}%${EMPTY}s${N}" | tr ' ' '-'
      printf "] %d%% (%d/%d)\n" "$PCT" "$COMPLETED" "$TOTAL"
      
      if [[ "$COMPLETED" -eq "$TOTAL" ]]; then
        echo -e "  ${G}✓ ALL STORIES COMPLETE${N}"
      fi
      echo ""
    fi
    
    # Current task
    CURRENT_ID=$(jq -r '[.userStories[] | select(.passes == false)] | .[0].id // empty' "$SESSION_DIR/prd.json" 2>/dev/null)
    CURRENT_TITLE=$(jq -r '[.userStories[] | select(.passes == false)] | .[0].title // empty' "$SESSION_DIR/prd.json" 2>/dev/null)
    if [[ -n "$CURRENT_ID" ]]; then
      echo -e "  ${BOLD}Current:${N}"
      echo -e "  ${B}$CURRENT_ID${N}: $CURRENT_TITLE"
      echo ""
    fi
  fi
  
  # Last log entries (clean)
  if [[ -f "$SESSION_DIR/ralph.log" ]]; then
    echo -e "  ${BOLD}Recent:${N}"
    tail -8 "$SESSION_DIR/ralph.log" | grep -v "^$" | head -6 | sed 's/^/  /'
    echo ""
  fi
  
  # Check for lock file
  if [[ -f "$SESSION_DIR/.ralph.lock" ]]; then
    LOCK_PID=$(cat "$SESSION_DIR/.ralph.lock" 2>/dev/null)
    if kill -0 "$LOCK_PID" 2>/dev/null; then
      echo -e "  ${BOLD}Lock:${N} Active (PID: $LOCK_PID)"
    else
      echo -e "  ${BOLD}Lock:${N} ${Y}Stale${N} (PID: $LOCK_PID - not running)"
    fi
    echo ""
  fi
  
  echo -e "  ${BOLD}Commands:${N}"
  echo "  tail -f $SESSION_DIR/ralph.log"
  [[ -n "$RALPH_PID" ]] && echo "  kill $RALPH_PID  # stop ralph"
  
else
  echo -e "  ${Y}No active session found${N}"
  echo ""
  echo "  Available sessions:"
  ls -1 "$SCRIPT_DIR/sessions/" 2>/dev/null | sed 's/^/    /' || echo "    (none)"
fi

echo ""
echo "============================================================================"
echo ""
