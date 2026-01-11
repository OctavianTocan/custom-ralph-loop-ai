#!/bin/bash
set -e

# Ralph Autonomous Coding Loop
# Usage: ./ralph.sh [iterations] [--session session-name] [--force]
#        Or: ralph [iterations] [--session session-name] [--force] (if installed)
# Output goes to ralph.log in session directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX_ITERATIONS=10
SESSION_DIR=""
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --session)
      SESSION_DIR="$2"
      shift 2
      ;;
    --force|-f)
      FORCE=true
      shift
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
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

  if [[ ! -f "$SESSION_DIR/prd.json" ]]; then
    echo "Session not found: $SESSION_DIR"
    echo "Available sessions:"
    ls -1 "$SCRIPT_DIR/sessions/" 2>/dev/null || echo "  (none)"
    exit 1
  fi
else
  SESSION_DIR="$SCRIPT_DIR"
fi

LOG_FILE="$SESSION_DIR/ralph.log"
LOCK_FILE="$SESSION_DIR/.ralph.lock"
PROGRESS_FILE="$SESSION_DIR/progress.txt"

# Initialize progress.txt if it doesn't exist
if [[ ! -f "$PROGRESS_FILE" ]]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "" >> "$PROGRESS_FILE"
  echo "## Codebase Patterns" >> "$PROGRESS_FILE"
  echo "" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
  echo "" >> "$PROGRESS_FILE"
fi

# ============================================================================
# LOCK FILE MECHANISM - Prevent multiple Ralph loops
# ============================================================================
cleanup_lock() {
  rm -f "$LOCK_FILE" 2>/dev/null || true
}

check_existing_ralph() {
  if [[ -f "$LOCK_FILE" ]]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [[ -n "$LOCK_PID" ]] && kill -0 "$LOCK_PID" 2>/dev/null; then
      echo ""
      echo "============================================================================"
      echo "  ERROR: Ralph is already running for this session!"
      echo "============================================================================"
      echo ""
      echo "  Session: $(basename "$SESSION_DIR")"
      echo "  PID:     $LOCK_PID"
      echo ""
      echo "  Options:"
      echo "    1. Wait for the current run to finish"
      echo "    2. Kill it:  kill $LOCK_PID"
      echo "    3. Force:    ./ralph.sh --session $(basename "$SESSION_DIR") --force"
      echo ""
      echo "  Status:  ./status.sh"
      echo ""
      echo "============================================================================"
      exit 1
    else
      # Stale lock file - process no longer exists
      echo "Removing stale lock file (PID $LOCK_PID no longer running)"
      rm -f "$LOCK_FILE"
    fi
  fi
}

# Check for existing Ralph unless --force
if [[ "$FORCE" != true ]]; then
  check_existing_ralph
fi

# Create lock file with our PID
echo $$ > "$LOCK_FILE"
trap cleanup_lock EXIT INT TERM

# ============================================================================
# AGENT DETECTION
# ============================================================================
AGENT="claude"
MODEL=""
if command -v jq &> /dev/null && [[ -f "$SESSION_DIR/prd.json" ]]; then
  AGENT=$(jq -r '.agent // "claude"' "$SESSION_DIR/prd.json" 2>/dev/null || echo "claude")
  MODEL=$(jq -r '.model // ""' "$SESSION_DIR/prd.json" 2>/dev/null || echo "")
elif [[ -f "$SESSION_DIR/prd.json" ]]; then
  AGENT=$(grep -o '"agent"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_DIR/prd.json" 2>/dev/null | sed 's/.*"agent"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "claude")
  MODEL=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_DIR/prd.json" 2>/dev/null | sed 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
fi

# Validate agent
case "$AGENT" in
  claude|codex|opencode|cursor)
    ;;
  *)
    echo "Warning: Unknown agent '$AGENT', defaulting to 'claude'" >&2
    AGENT="claude"
    ;;
esac

RUNNERS_DIR="$SCRIPT_DIR/runners"
RUNNER_SCRIPT="$RUNNERS_DIR/run-$AGENT.sh"

if [[ ! -f "$RUNNER_SCRIPT" ]]; then
  echo "Error: Runner script not found: $RUNNER_SCRIPT" >&2
  exit 1
fi

# Check if the selected agent's CLI is available
case "$AGENT" in
  claude)
    command -v claude &> /dev/null || echo "Warning: Claude CLI not found." >&2
    ;;
  codex)
    command -v codex &> /dev/null || echo "Warning: Codex CLI not found." >&2
    ;;
  opencode)
    command -v opencode &> /dev/null || echo "Warning: OpenCode CLI not found." >&2
    ;;
  cursor)
    command -v cursor &> /dev/null || echo "Warning: Cursor CLI not found." >&2
    ;;
esac

# ============================================================================
# BRANCH ENFORCEMENT - Ensure session is on the correct branch
# ============================================================================
BRANCH_NAME=""
if command -v jq &> /dev/null && [[ -f "$SESSION_DIR/prd.json" ]]; then
  BRANCH_NAME=$(jq -r '.branchName // ""' "$SESSION_DIR/prd.json" 2>/dev/null || echo "")
elif [[ -f "$SESSION_DIR/prd.json" ]]; then
  BRANCH_NAME=$(grep -o '"branchName"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_DIR/prd.json" 2>/dev/null | sed 's/.*"branchName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
fi

if [[ -z "$BRANCH_NAME" ]]; then
  echo ""
  echo "============================================================================"
  echo "  ERROR: branchName not found in prd.json"
  echo "============================================================================"
  echo ""
  echo "  Session: $SESSION_DIR/prd.json"
  echo ""
  echo "  Please add a branchName field to your prd.json:"
  echo '  "branchName": "ralph/your-feature-name"'
  echo ""
  echo "============================================================================"
  exit 1
fi

echo "Checking out branch: $BRANCH_NAME"

# Check if branch exists
if git rev-parse --verify "$BRANCH_NAME" &> /dev/null; then
  # Branch exists, check it out
  if ! git checkout "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    echo ""
    echo "============================================================================"
    echo "  ERROR: Failed to checkout branch: $BRANCH_NAME"
    echo "============================================================================"
    echo ""
    echo "  This could be due to:"
    echo "    - Uncommitted changes in the working directory"
    echo "    - Branch name conflict"
    echo "    - Git repository issues"
    echo ""
    echo "  Try:"
    echo "    git status              # Check working directory"
    echo "    git stash               # Stash uncommitted changes"
    echo "    git checkout $BRANCH_NAME"
    echo ""
    echo "============================================================================"
    exit 1
  fi
else
  # Branch doesn't exist, create it
  if ! git checkout -b "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    echo ""
    echo "============================================================================"
    echo "  ERROR: Failed to create branch: $BRANCH_NAME"
    echo "============================================================================"
    echo ""
    echo "  This could be due to:"
    echo "    - Invalid branch name"
    echo "    - Git repository issues"
    echo "    - Insufficient permissions"
    echo ""
    echo "  Try:"
    echo "    git status              # Check repository state"
    echo "    git branch              # List existing branches"
    echo ""
    echo "============================================================================"
    exit 1
  fi
fi

echo "Successfully on branch: $BRANCH_NAME"
echo ""

# ============================================================================
# STARTUP BANNER
# ============================================================================
echo ""
echo "============================================================================"
echo "  RALPH - Autonomous Coding Loop"
echo "============================================================================"
echo ""
echo "  Session:    $(basename "$SESSION_DIR")"
echo "  Agent:      $AGENT"
[[ -n "$MODEL" ]] && echo "  Model:      $MODEL"
echo "  Iterations: $MAX_ITERATIONS"
echo "  PID:        $$"
echo ""
echo "  Monitor:    tail -f $LOG_FILE"
echo "  Status:     ./status.sh"
echo "  Stop:       ./stop.sh or kill $$"
echo ""
echo "============================================================================"
echo ""

# Initialize log
{
  echo "=== Ralph Session Started: $(date) ==="
  echo "Session: $SESSION_DIR"
  echo "Agent: $AGENT"
  [[ -n "$MODEL" ]] && echo "Model: $MODEL"
  echo "Max iterations: $MAX_ITERATIONS"
  echo "PID: $$"
  echo ""
} > "$LOG_FILE"

# ============================================================================
# MAIN LOOP
# ============================================================================
for i in $(seq 1 $MAX_ITERATIONS); do
  echo "--- Iteration $i of $MAX_ITERATIONS: $(date) ---" | tee -a "$LOG_FILE"

  PROMPT="# Session Context

Session directory: $SESSION_DIR

Read these files from the session directory:
- prd.json (task definitions)
- progress.txt (codebase patterns)
- learnings.md (accumulated learnings)

---

$(cat "$SCRIPT_DIR/prompt.md")"

  PROMPT_FILE=$(mktemp)
  echo "$PROMPT" > "$PROMPT_FILE"

  "$RUNNER_SCRIPT" "$PROMPT_FILE" "$LOG_FILE" "$SESSION_DIR" "$MODEL" || true
  rm -f "$PROMPT_FILE"

  # Check for completion markers in agent output
  if tail -100 "$LOG_FILE" | grep -q "<promise>COMPLETE</promise>"; then
    echo "" | tee -a "$LOG_FILE"
    echo "=== COMPLETE (agent signaled): $(date) ===" | tee -a "$LOG_FILE"
    echo ""
    echo "============================================================================"
    echo "  RALPH COMPLETE"
    echo "============================================================================"
    exit 0
  fi

  if tail -100 "$LOG_FILE" | grep -q "<promise>BLOCKED"; then
    echo "" | tee -a "$LOG_FILE"
    echo "=== BLOCKED: $(date) ===" | tee -a "$LOG_FILE"
    echo ""
    echo "============================================================================"
    echo "  RALPH BLOCKED - Check $LOG_FILE"
    echo "============================================================================"
    exit 1
  fi

  # Check if all stories in PRD are complete (passes: true)
  if command -v jq &> /dev/null && [[ -f "$SESSION_DIR/prd.json" ]]; then
    TOTAL_STORIES=$(jq '.userStories | length' "$SESSION_DIR/prd.json" 2>/dev/null || echo "0")
    PASSED_STORIES=$(jq '[.userStories[] | select(.passes == true)] | length' "$SESSION_DIR/prd.json" 2>/dev/null || echo "0")
    
    if [[ "$TOTAL_STORIES" -gt 0 && "$TOTAL_STORIES" == "$PASSED_STORIES" ]]; then
      echo "" | tee -a "$LOG_FILE"
      echo "=== ALL PRD STORIES COMPLETE ($PASSED_STORIES/$TOTAL_STORIES): $(date) ===" | tee -a "$LOG_FILE"
      echo ""
      echo "============================================================================"
      echo "  RALPH COMPLETE - All $TOTAL_STORIES stories passed"
      echo "============================================================================"
      exit 0
    else
      echo "Progress: $PASSED_STORIES/$TOTAL_STORIES stories complete" | tee -a "$LOG_FILE"
    fi
  fi

  sleep 2
done

echo "" | tee -a "$LOG_FILE"
echo "=== Max iterations reached: $(date) ===" | tee -a "$LOG_FILE"
echo ""
echo "============================================================================"
echo "  MAX ITERATIONS REACHED - Run again to continue"
echo "============================================================================"
exit 1
