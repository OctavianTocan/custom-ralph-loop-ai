#!/bin/bash
# Ralph Status Checker - Enhanced Display
# Usage: ./status.sh [--session session-name] [--full]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --session)
      SESSION_DIR="$2"
      shift 2
      ;;
    --full|-f)
      # Reserved for future use: full mode with extended output
      shift
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

# Colors
G='\033[0;32m'  # Green
Y='\033[1;33m'   # Yellow
R='\033[0;31m'   # Red
B='\033[0;34m'   # Blue
C='\033[0;36m'   # Cyan
M='\033[0;35m'   # Magenta
D='\033[2m'      # Dim
N='\033[0m'      # Reset
BOLD='\033[1m'   # Bold

# ASCII Art Header
print_header() {
  echo ""
  echo -e "${BOLD}${C}========================================================================${N}"
  echo -e "${BOLD}${G}RALPH${N} ${D}AUTONOMOUS CODING LOOP${N}"
  echo -e "${BOLD}${C}========================================================================${N}"
  echo ""
}

# Box drawing helper
box_top() {
  echo -e "${D}┌────────────────────────────────────────────────────────────────────────┐${N}"
}

box_mid() {
  echo -e "${D}├────────────────────────────────────────────────────────────────────────┤${N}"
}

box_bottom() {
  echo -e "${D}└────────────────────────────────────────────────────────────────────────┘${N}"
}

# Format time duration
format_duration() {
  local seconds=$1
  if [[ $seconds -lt 60 ]]; then
    echo "${seconds}s"
  elif [[ $seconds -lt 3600 ]]; then
    local mins=$((seconds / 60))
    local secs=$((seconds % 60))
    echo "${mins}m ${secs}s"
  else
    local hours=$((seconds / 3600))
    local mins=$(((seconds % 3600) / 60))
    echo "${hours}h ${mins}m"
  fi
}

# Get session start time
get_session_start() {
  local log_file="$1"
  if [[ -f "$log_file" ]]; then
    grep -m1 "Ralph Session Started" "$log_file" | sed 's/.*Started: //' | head -1
  fi
}

# Calculate elapsed time
get_elapsed_time() {
  local start_time="$1"
  if [[ -n "$start_time" ]]; then
    # Portable date parsing for both Linux and macOS
    local start_epoch=""
    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS: date -j -f format string
      start_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" +%s 2>/dev/null || echo "")
    else
      # Linux: date -d string
      start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "")
    fi
    if [[ -n "$start_epoch" ]]; then
      local now_epoch=$(date +%s)
      echo $((now_epoch - start_epoch))
    fi
  fi
}

# Get phase information
get_phase_info() {
  local prd_file="$1"
  if [[ ! -f "$prd_file" ]] || ! command -v jq &> /dev/null; then
    return
  fi

  # Extract unique phases from story IDs
  local phases=$(jq -r '.userStories[].id' "$prd_file" 2>/dev/null | \
    sed 's/-.*$//' | sort -u)

  echo "$phases"
}

# Count stories per phase
count_phase_stories() {
  local prd_file="$1"
  local phase="$2"

  if command -v jq &> /dev/null; then
    jq -r --arg phase "$phase" '[.userStories[] | select(.id | startswith($phase + "-"))] | length' "$prd_file" 2>/dev/null
  else
    grep -c "\"id\"[[:space:]]*:[[:space:]]*\"${phase}-" "$prd_file" 2>/dev/null || echo "0"
  fi
}

# Count completed stories per phase
count_phase_completed() {
  local prd_file="$1"
  local phase="$2"

  if command -v jq &> /dev/null; then
    jq -r --arg phase "$phase" '[.userStories[] | select(.id | startswith($phase + "-") and .passes == true)] | length' "$prd_file" 2>/dev/null
  else
    grep -c "\"id\"[[:space:]]*:[[:space:]]*\"${phase}-.*\"passes\"[[:space:]]*:[[:space:]]*true" "$prd_file" 2>/dev/null || echo "0"
  fi
}

# Get recent commits
get_recent_commits() {
  local count=${1:-5}
  git log --oneline --no-decorate -n "$count" 2>/dev/null | head -n "$count"
}

# Get PR information
get_pr_info() {
  local session_dir="$1"
  local prs_file="$session_dir/prs.json"

  if [[ -f "$prs_file" ]] && command -v jq &> /dev/null; then
    local total=$(jq '.summary.prsCreated // 0' "$prs_file" 2>/dev/null)
    local open=$(jq '.summary.prsOpen // 0' "$prs_file" 2>/dev/null)
    echo "$total|$open"
  fi
}

print_header

# Check if Ralph is running
RALPH_PID=$(pgrep -f "ralph.sh" 2>/dev/null | head -1)
CURSOR_PID=$(pgrep -f "cursor.*agent.*-p" 2>/dev/null | head -1)
CODE_PID=$(pgrep -f "claude.*-p" 2>/dev/null | head -1)
AGENT_PID="${CURSOR_PID:-${CODE_PID}}"

box_top
echo -e "${D}│${N}  ${BOLD}Status:${N}"

if [[ -n "$RALPH_PID" ]]; then
  echo -e "${D}│${N}    Loop:   ${G}●${N} ${G}RUNNING${N} ${D}(PID: $RALPH_PID)${N}"
else
  echo -e "${D}│${N}    Loop:   ${D}○${N} ${D}stopped${N}"
fi

if [[ -n "$AGENT_PID" ]]; then
  echo -e "${D}│${N}    Agent:  ${G}●${N} ${G}ACTIVE${N} ${D}(PID: $AGENT_PID)${N}"
else
  echo -e "${D}│${N}    Agent:  ${D}○${N} ${D}idle${N}"
fi

# Find active session
if [[ -z "$SESSION_DIR" ]]; then
  LATEST_SESSION=$(ls -t "$SCRIPT_DIR/sessions/" 2>/dev/null | head -1)
  if [[ -n "$LATEST_SESSION" && -d "$SCRIPT_DIR/sessions/$LATEST_SESSION" ]]; then
    SESSION_DIR="$SCRIPT_DIR/sessions/$LATEST_SESSION"
  fi
fi

if [[ -n "$SESSION_DIR" && -f "$SESSION_DIR/prd.json" ]]; then
  SESSION_NAME=$(basename "$SESSION_DIR")
  LOG_FILE="$SESSION_DIR/ralph.log"

  box_mid
  echo -e "${D}│${N}  ${BOLD}Session:${N} ${C}$SESSION_NAME${N}"

  # Session timing
  START_TIME=$(get_session_start "$LOG_FILE")
  if [[ -n "$START_TIME" ]]; then
    ELAPSED=$(get_elapsed_time "$START_TIME")
    if [[ -n "$ELAPSED" ]]; then
      DURATION=$(format_duration "$ELAPSED")
      echo -e "${D}│${N}    Started: ${D}$START_TIME${N}"
      echo -e "${D}│${N}    Runtime: ${BOLD}${Y}$DURATION${N}"
    fi
  fi

  # Count tasks
  if command -v jq &> /dev/null; then
    TOTAL=$(jq '.userStories | length' "$SESSION_DIR/prd.json" 2>/dev/null)
    COMPLETED=$(jq '[.userStories[] | select(.passes == true)] | length' "$SESSION_DIR/prd.json" 2>/dev/null)
    PENDING=$((TOTAL - COMPLETED))

    if [[ $TOTAL -gt 0 ]]; then
      PCT=$((COMPLETED * 100 / TOTAL))

      box_mid
      echo -e "${D}│${N}  ${BOLD}Progress:${N} ${G}$COMPLETED${N}/${BOLD}$TOTAL${N} stories ${D}($PCT%)${N}"

      # Enhanced progress bar
      BAR_WIDTH=40
      FILLED=$((PCT * BAR_WIDTH / 100))
      EMPTY=$((BAR_WIDTH - FILLED))

      printf "${D}│${N}    ["
      if [[ $FILLED -gt 0 ]]; then
        printf "${G}"
        printf "%${FILLED}s" | tr ' ' '█'
        printf "${N}"
      fi
      if [[ $EMPTY -gt 0 ]]; then
        printf "${D}"
        printf "%${EMPTY}s" | tr ' ' '░'
        printf "${N}"
      fi
      printf "]\n"

      if [[ "$COMPLETED" -eq "$TOTAL" ]]; then
        echo -e "${D}│${N}    ${G}✓ ALL STORIES COMPLETE${N}"
      fi

      # Phase breakdown
      PHASES=$(get_phase_info "$SESSION_DIR/prd.json")
      if [[ -n "$PHASES" ]]; then
        box_mid
        echo -e "${D}│${N}  ${BOLD}Phases:${N}"
        echo "$PHASES" | while read -r phase; do
          [[ -z "$phase" ]] && continue
          PHASE_TOTAL=$(count_phase_stories "$SESSION_DIR/prd.json" "$phase")
          PHASE_COMPLETED=$(count_phase_completed "$SESSION_DIR/prd.json" "$phase")
          PHASE_PCT=0
          if [[ "$PHASE_TOTAL" -gt 0 ]]; then
            PHASE_PCT=$((PHASE_COMPLETED * 100 / PHASE_TOTAL))
          fi

          if [[ "$PHASE_COMPLETED" -eq "$PHASE_TOTAL" ]]; then
            STATUS="${G}✓${N}"
          else
            STATUS="${Y}○${N}"
          fi

          printf "${D}│${N}    %s ${BOLD}%s${N}: ${G}%d${N}/${BOLD}%d${N} ${D}(%d%%)${N}\n" \
            "$STATUS" "$phase" "$PHASE_COMPLETED" "$PHASE_TOTAL" "$PHASE_PCT"
        done
      fi

      # PR information
      PR_INFO=$(get_pr_info "$SESSION_DIR")
      if [[ -n "$PR_INFO" ]]; then
        PR_TOTAL=$(echo "$PR_INFO" | cut -d'|' -f1)
        PR_OPEN=$(echo "$PR_INFO" | cut -d'|' -f2)
        if [[ "$PR_TOTAL" -gt 0 ]]; then
          box_mid
          echo -e "${D}│${N}  ${BOLD}Pull Requests:${N}"
          echo -e "${D}│${N}    Created: ${BOLD}$PR_TOTAL${N}"
          echo -e "${D}│${N}    Open:    ${BOLD}${Y}$PR_OPEN${N}"
        fi
      fi
    fi

    # Current task
    CURRENT_ID=$(jq -r '[.userStories[] | select(.passes == false)] | .[0].id // empty' "$SESSION_DIR/prd.json" 2>/dev/null)
    CURRENT_TITLE=$(jq -r '[.userStories[] | select(.passes == false)] | .[0].title // empty' "$SESSION_DIR/prd.json" 2>/dev/null)
    if [[ -n "$CURRENT_ID" ]]; then
      box_mid
      echo -e "${D}│${N}  ${BOLD}Current Task:${N}"
      echo -e "${D}│${N}    ${BOLD}${B}$CURRENT_ID${N}: ${C}$CURRENT_TITLE${N}"
    fi

    # Recent commits
    RECENT_COMMITS=$(get_recent_commits 3)
    if [[ -n "$RECENT_COMMITS" ]]; then
      box_mid
      echo -e "${D}│${N}  ${BOLD}Recent Commits:${N}"
      echo "$RECENT_COMMITS" | while read -r commit; do
        [[ -z "$commit" ]] && continue
        HASH=$(echo "$commit" | cut -d' ' -f1)
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo -e "${D}│${N}    ${D}$HASH${N} ${MSG}"
      done
    fi
  fi

  # Last log entries (enhanced)
  if [[ -f "$LOG_FILE" ]]; then
    box_mid
    echo -e "${D}│${N}  ${BOLD}Recent Activity:${N}"

    # Parse and format recent log entries
    tail -12 "$LOG_FILE" | grep -v "^$" | head -8 | while IFS= read -r line; do
      # Colorize different log entry types
      if echo "$line" | grep -qE "\[read\]|\[write\]|\[edit\]|\[run\]|\[search\]|\[grep\]|\[ls\]"; then
        # Tool calls
        echo -e "${D}│${N}    ${D}$line${N}"
      elif echo "$line" | grep -qE "COMPLETE|BLOCKED|ERROR"; then
        # Important status
        echo -e "${D}│${N}    ${BOLD}${Y}$line${N}"
      elif echo "$line" | grep -qE "ok|FAIL"; then
        # Validation results
        if echo "$line" | grep -q "ok"; then
          echo -e "${D}│${N}    ${G}$line${N}"
        else
          echo -e "${D}│${N}    ${R}$line${N}"
        fi
      elif echo "$line" | grep -qE "Iteration|---"; then
        # Iteration markers
        echo -e "${D}│${N}    ${BOLD}${C}$line${N}"
      else
        # Regular text
        echo -e "${D}│${N}    $line"
      fi
    done
  fi

  # Check for lock file
  if [[ -f "$SESSION_DIR/.ralph.lock" ]]; then
    LOCK_PID=$(cat "$SESSION_DIR/.ralph.lock" 2>/dev/null)
    if kill -0 "$LOCK_PID" 2>/dev/null; then
      box_mid
      echo -e "${D}│${N}  ${BOLD}Lock:${N} ${G}Active${N} ${D}(PID: $LOCK_PID)${N}"
    else
      box_mid
      echo -e "${D}│${N}  ${BOLD}Lock:${N} ${Y}Stale${N} ${D}(PID: $LOCK_PID - not running)${N}"
    fi
  fi

  box_mid
  echo -e "${D}│${N}  ${BOLD}Commands:${N}"
  echo -e "${D}│${N}    ${D}tail -f${N} $LOG_FILE"
  echo -e "${D}│${N}    ${D}./watch.sh${N}  ${D}# real-time monitoring${N}"
  [[ -n "$RALPH_PID" ]] && echo -e "${D}│${N}    ${D}kill $RALPH_PID${N}  ${D}# stop ralph${N}"

else
  box_mid
  echo -e "${D}│${N}  ${Y}No active session found${N}"
  box_mid
  echo -e "${D}│${N}  ${BOLD}Available sessions:${N}"
  ls -1 "$SCRIPT_DIR/sessions/" 2>/dev/null | sed "s/^/${D}│${N}    /" || echo -e "${D}│${N}    ${D}(none)${N}"
fi

box_bottom
echo ""
