#!/bin/bash
set -e

# Ralph Autonomous Coding Loop
# Usage: ./ralph.sh [iterations] [--session session-name] [--force]
#        Or: ./ralph.sh session-name [iterations] [--force]
# Output goes to ralph.log in session directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX_ITERATIONS=10
SESSION_DIR=""
FORCE=false
WORKFLOW=""
VERSION="1.0.0"

# ============================================================================
# Handle --help and --version flags FIRST (before session resolution)
# ============================================================================
show_help() {
  cat <<EOF
Ralph Autonomous Coding Loop

Usage:
  ralph.sh [iterations] --session <name> [options]
  ralph.sh <session-name> [iterations] [options]

Options:
  --session <name>    Session name (from sessions/ directory)
  --iterations <n>    Number of iterations (or 'auto' for suggested count)
  --force, -f         Force start even if session is running
  --workflow <name>   Use workflow from .claude/workflows/
  --help, -h          Show this help message
  --version, -v       Show version information

Examples:
  ralph.sh 25 --session my-feature
  ralph.sh my-feature 25
  ralph.sh --session my-feature --force
  ralph.sh --session my-feature --iterations auto

Available sessions:
EOF
  if [[ -d "$SCRIPT_DIR/sessions" ]]; then
    ls -1 "$SCRIPT_DIR/sessions/" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
  else
    echo "  (none)"
  fi
  echo ""
}

show_version() {
  # Try to get version from git tags
  if command -v git &> /dev/null && [[ -d "$SCRIPT_DIR/.git" ]]; then
    GIT_VERSION=$(git -C "$SCRIPT_DIR" describe --tags 2>/dev/null || git -C "$SCRIPT_DIR" log -1 --format="%h" 2>/dev/null || echo "")
    if [[ -n "$GIT_VERSION" ]]; then
      echo "ralph-ai-coding-loop $GIT_VERSION"
      exit 0
    fi
  fi
  # Fallback to hardcoded version
  echo "ralph-ai-coding-loop v$VERSION"
}

# ============================================================================
# Handle init subcommand FIRST (before session resolution)
# ============================================================================
if [[ "$1" == "init" ]]; then
  SESSION_NAME="$2"

  if [[ -z "$SESSION_NAME" ]]; then
    echo "Error: Session name required"
    echo "Usage: ralph.sh init <session-name>"
    exit 1
  fi

  SESSION_PATH="$SCRIPT_DIR/sessions/$SESSION_NAME"

  # Check if session already exists
  if [[ -d "$SESSION_PATH" ]]; then
    echo "Error: Session '$SESSION_NAME' already exists at $SESSION_PATH"
    exit 1
  fi

  # Create session directory
  mkdir -p "$SESSION_PATH"

  # Generate template prd.json
  cat > "$SESSION_PATH/prd.json" <<'EOF'
{
  "branchName": "ralph/SESSION_NAME",
  "agent": "claude",
  "model": "sonnet",
  "validationCommands": {},
  "userStories": [
    {
      "id": "STORY-001",
      "title": "First task to implement",
      "acceptanceCriteria": [
        "Describe what success looks like",
        "Add measurable criteria"
      ],
      "priority": 1,
      "complexity": "medium",
      "passes": false
    }
  ]
}
EOF

  # Replace placeholder with actual session name (portable for macOS and Linux)
  sed "s/SESSION_NAME/$SESSION_NAME/g" "$SESSION_PATH/prd.json" > "$SESSION_PATH/prd.json.tmp"
  mv "$SESSION_PATH/prd.json.tmp" "$SESSION_PATH/prd.json"

  # Create progress.txt
  cat > "$SESSION_PATH/progress.txt" <<EOF
# Ralph Progress Log

Session: $SESSION_NAME
Location: sessions/$SESSION_NAME/
Branch: ralph/$SESSION_NAME

---

## Codebase Patterns

(Add discovered patterns here)

---
EOF

  # Create learnings.md
  cat > "$SESSION_PATH/learnings.md" <<EOF
# Learnings: $SESSION_NAME

Session: $SESSION_NAME
Branch: ralph/$SESSION_NAME

---
EOF

  echo ""
  echo "Session created: $SESSION_NAME"
  echo ""
  echo "Next steps:"
  echo "  1. Edit sessions/$SESSION_NAME/prd.json to define your tasks"
  echo "  2. Run: ./ralph.sh --session $SESSION_NAME"
  echo ""

  exit 0
fi

# Check for --help or --version BEFORE parsing other arguments
for arg in "$@"; do
  case "$arg" in
    --help|-h)
      show_help
      exit 0
      ;;
    --version|-v)
      show_version
      exit 0
      ;;
  esac
done

# Parse arguments
ITERATIONS_AUTO=false
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
    --workflow)
      WORKFLOW="$2"
      shift 2
      ;;
    --iterations)
      if [[ "$2" == "auto" ]]; then
        ITERATIONS_AUTO=true
      else
        MAX_ITERATIONS="$2"
      fi
      shift 2
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      elif [[ -z "$SESSION_DIR" ]]; then
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
  # Read workflow from prd.json if not specified via CLI
  if [[ -z "$WORKFLOW" ]]; then
    WORKFLOW=$(jq -r '.workflow // ""' "$SESSION_DIR/prd.json" 2>/dev/null || echo "")
  fi
elif [[ -f "$SESSION_DIR/prd.json" ]]; then
  AGENT=$(grep -o '"agent"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_DIR/prd.json" 2>/dev/null | sed 's/.*"agent"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "claude")
  MODEL=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_DIR/prd.json" 2>/dev/null | sed 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
  # Read workflow from prd.json if not specified via CLI
  if [[ -z "$WORKFLOW" ]]; then
    WORKFLOW=$(grep -o '"workflow"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_DIR/prd.json" 2>/dev/null | sed 's/.*"workflow"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
  fi
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
# WORKFLOW VALIDATION
# ============================================================================
WORKFLOW_PROMPT=""
if [[ -n "$WORKFLOW" ]]; then
  WORKFLOW_PROMPT_FILE="$SCRIPT_DIR/workflows/$WORKFLOW/prompt.md"
  if [[ ! -f "$WORKFLOW_PROMPT_FILE" ]]; then
    echo ""
    echo "============================================================================"
    echo "  ERROR: Workflow prompt not found: $WORKFLOW"
    echo "============================================================================"
    echo ""
    echo "  Expected: $WORKFLOW_PROMPT_FILE"
    echo ""
    echo "  Available workflows:"
    if [[ -d "$SCRIPT_DIR/workflows" ]]; then
      ls -1 "$SCRIPT_DIR/workflows/" 2>/dev/null | sed 's/^/    - /' || echo "    (none)"
    else
      echo "    (none - workflows/ directory does not exist)"
    fi
    echo ""
    echo "============================================================================"
    exit 1
  fi
  WORKFLOW_PROMPT=$(cat "$WORKFLOW_PROMPT_FILE")
fi

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
# ITERATION SUGGESTION
# ============================================================================
SUGGESTED_ITERATIONS=0
SUGGESTED_SMALL=0
SUGGESTED_MEDIUM=0
SUGGESTED_LARGE=0

if command -v jq &> /dev/null; then
  # Check for explicit suggestedIterations first
  explicit_suggested=$(jq -r '.suggestedIterations // empty' "$SESSION_DIR/prd.json" 2>/dev/null)
  if [[ -n "$explicit_suggested" && "$explicit_suggested" != "null" ]]; then
    SUGGESTED_ITERATIONS="$explicit_suggested"
  else
    # Calculate from userStories complexity (only incomplete tasks)
    while IFS= read -r complexity; do
      case "$complexity" in
        small) ((SUGGESTED_SMALL++)) || true; ((SUGGESTED_ITERATIONS+=1)) || true ;;
        large) ((SUGGESTED_LARGE++)) || true; ((SUGGESTED_ITERATIONS+=3)) || true ;;
        *) ((SUGGESTED_MEDIUM++)) || true; ((SUGGESTED_ITERATIONS+=2)) || true ;;  # default is medium
      esac
    done < <(jq -r '.userStories[] | select(.passes != true) | .complexity // "medium"' "$SESSION_DIR/prd.json" 2>/dev/null)
  fi
else
  # Fallback without jq - check for suggestedIterations
  explicit_suggested=$(grep -o '"suggestedIterations"[[:space:]]*:[[:space:]]*[0-9]*' "$SESSION_DIR/prd.json" 2>/dev/null | grep -o '[0-9]*' | head -1)
  if [[ -n "$explicit_suggested" ]]; then
    SUGGESTED_ITERATIONS="$explicit_suggested"
  else
    # Count tasks by complexity (simplified without jq)
    task_count=$(grep -c '"passes"[[:space:]]*:[[:space:]]*false' "$SESSION_DIR/prd.json" 2>/dev/null || echo "0")
    SUGGESTED_ITERATIONS=$((task_count * 2))  # Default to medium complexity
  fi
fi

# Use suggested if --iterations auto was specified
if [[ "$ITERATIONS_AUTO" == true && -n "$SUGGESTED_ITERATIONS" && "$SUGGESTED_ITERATIONS" -gt 0 ]]; then
  MAX_ITERATIONS="$SUGGESTED_ITERATIONS"
fi

# Build breakdown string
BREAKDOWN=""
if [[ $SUGGESTED_SMALL -gt 0 || $SUGGESTED_MEDIUM -gt 0 || $SUGGESTED_LARGE -gt 0 ]]; then
  parts=()
  [[ $SUGGESTED_SMALL -gt 0 ]] && parts+=("$SUGGESTED_SMALL small")
  [[ $SUGGESTED_MEDIUM -gt 0 ]] && parts+=("$SUGGESTED_MEDIUM medium")
  [[ $SUGGESTED_LARGE -gt 0 ]] && parts+=("$SUGGESTED_LARGE large")
  BREAKDOWN=$(IFS=', '; echo "${parts[*]}")
fi

# ============================================================================
# STARTUP BANNER
# ============================================================================
C='\033[0;36m'
G='\033[0;32m'
Y='\033[1;33m'
D='\033[2m'
N='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${C}========================================================================${N}"
echo -e "${BOLD}${G}RALPH${N} ${D}AUTONOMOUS CODING LOOP${N}"
echo -e "${C}========================================================================${N}"
echo ""
echo -e "  ${BOLD}Session:${N}    ${C}$(basename "$SESSION_DIR")${N}"
echo -e "  ${BOLD}Agent:${N}      ${G}$AGENT${N}"
[[ -n "$MODEL" ]] && echo -e "  ${BOLD}Model:${N}      ${Y}$MODEL${N}"
echo -e "  ${BOLD}Iterations:${N} ${BOLD}$MAX_ITERATIONS${N}"
if [[ -n "$SUGGESTED_ITERATIONS" && "$SUGGESTED_ITERATIONS" -gt 0 ]]; then
  if [[ -n "$BREAKDOWN" ]]; then
    echo -e "  ${BOLD}Suggested:${N}  ${Y}$SUGGESTED_ITERATIONS${N} ${D}($BREAKDOWN)${N}"
  else
    echo -e "  ${BOLD}Suggested:${N}  ${Y}$SUGGESTED_ITERATIONS${N}"
  fi
fi
echo -e "  ${BOLD}PID:${N}        ${D}$$${N}"
echo ""
echo -e "  ${BOLD}Monitor:${N}    ${D}tail -f${N} $LOG_FILE"
echo -e "  ${BOLD}Status:${N}     ${D}./status.sh${N}"
echo -e "  ${BOLD}Watch:${N}      ${D}./watch.sh${N}"
echo -e "  ${BOLD}Stop:${N}       ${D}kill $$${N}"
echo ""
echo -e "${C}========================================================================${N}"
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
C='\033[0;36m'
N='\033[0m'
BOLD='\033[1m'

for i in $(seq 1 $MAX_ITERATIONS); do
  # Capture most recent iteration log (before writing new header) so restarts can resume faster
  LAST_ITERATION_CONTEXT=""
  if [[ -f "$LOG_FILE" ]]; then
    LAST_ITERATION_LINE=$(grep -n 'Iteration [0-9]\+ of [0-9]\+' "$LOG_FILE" | tail -1 | cut -d: -f1)
    if [[ -n "$LAST_ITERATION_LINE" ]]; then
      LAST_ITERATION_CONTEXT=$(tail -n +"$LAST_ITERATION_LINE" "$LOG_FILE")
    else
      LAST_ITERATION_CONTEXT=$(cat "$LOG_FILE")
    fi

    LAST_ITERATION_CONTEXT=$(printf '%s\n' "$LAST_ITERATION_CONTEXT" | tail -n 200)
  fi

  echo ""
  echo -e "${C}========================================================================${N}" | tee -a "$LOG_FILE"
  echo -e "${C}Iteration $i of $MAX_ITERATIONS${N}  $(date)" | tee -a "$LOG_FILE"
  echo -e "${C}========================================================================${N}" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"

  PROMPT="# Session Context

Session directory: $SESSION_DIR

Read these files from the session directory:
- prd.json (task definitions)
- progress.txt (codebase patterns)
- learnings.md (accumulated learnings)

---

$(cat "$SCRIPT_DIR/prompt.md")"

  # Append workflow-specific prompt if workflow is specified
  if [[ -n "$WORKFLOW_PROMPT" ]]; then
    PROMPT="$PROMPT

---

# Workflow: $WORKFLOW

$WORKFLOW_PROMPT"
  fi

  # Include recent log so resumed runs pick up immediately
  if [[ -n "$LAST_ITERATION_CONTEXT" ]]; then
    PROMPT="$PROMPT

---

# Recent Ralph Iteration (resume context)
$LAST_ITERATION_CONTEXT"
  fi

  PROMPT_FILE=$(mktemp)
  echo "$PROMPT" > "$PROMPT_FILE"

  "$RUNNER_SCRIPT" "$PROMPT_FILE" "$LOG_FILE" "$SESSION_DIR" "$MODEL" || true
  rm -f "$PROMPT_FILE"

  # Check for completion markers in agent output
  if tail -100 "$LOG_FILE" | grep -q "<promise>COMPLETE</promise>"; then
    echo "" | tee -a "$LOG_FILE"
    G='\033[0;32m'
    echo -e "${G}========================================================================${N}" | tee -a "$LOG_FILE"
    echo -e "${G}RALPH COMPLETE${N}" | tee -a "$LOG_FILE"
    echo -e "Agent signaled completion: $(date)" | tee -a "$LOG_FILE"
    echo -e "${G}========================================================================${N}" | tee -a "$LOG_FILE"
    echo ""
    exit 0
  fi

  if tail -100 "$LOG_FILE" | grep -q "<promise>BLOCKED"; then
    echo "" | tee -a "$LOG_FILE"
    R='\033[0;31m'
    echo -e "${R}========================================================================${N}" | tee -a "$LOG_FILE"
    echo -e "${R}RALPH BLOCKED${N}" | tee -a "$LOG_FILE"
    echo -e "Check log file: $LOG_FILE" | tee -a "$LOG_FILE"
    echo -e "${R}========================================================================${N}" | tee -a "$LOG_FILE"
    echo ""
    exit 1
  fi

  # Check if all stories in PRD are complete (passes: true)
  if command -v jq &> /dev/null && [[ -f "$SESSION_DIR/prd.json" ]]; then
    TOTAL_STORIES=$(jq '.userStories | length' "$SESSION_DIR/prd.json" 2>/dev/null || echo "0")
    PASSED_STORIES=$(jq '[.userStories[] | select(.passes == true)] | length' "$SESSION_DIR/prd.json" 2>/dev/null || echo "0")

    if [[ "$TOTAL_STORIES" -gt 0 && "$TOTAL_STORIES" == "$PASSED_STORIES" ]]; then
      echo "" | tee -a "$LOG_FILE"
      G='\033[0;32m'
      echo -e "${G}========================================================================${N}" | tee -a "$LOG_FILE"
      echo -e "${G}RALPH COMPLETE${N}" | tee -a "$LOG_FILE"
      echo -e "All $PASSED_STORIES/$TOTAL_STORIES stories passed" | tee -a "$LOG_FILE"
      echo -e "$(date)" | tee -a "$LOG_FILE"
      echo -e "${G}========================================================================${N}" | tee -a "$LOG_FILE"
      echo ""
      exit 0
    else
      PCT=$((PASSED_STORIES * 100 / TOTAL_STORIES))
      echo -e "${C}[Progress]${N} ${G}$PASSED_STORIES${N}/${BOLD}$TOTAL_STORIES${N} stories complete ${D}($PCT%)${N}" | tee -a "$LOG_FILE"
    fi
  fi

  sleep 2
done

echo "" | tee -a "$LOG_FILE"
Y='\033[1;33m'
echo -e "${Y}========================================================================${N}" | tee -a "$LOG_FILE"
echo -e "${Y}MAX ITERATIONS REACHED${N}" | tee -a "$LOG_FILE"
echo -e "Run again to continue: $(date)" | tee -a "$LOG_FILE"
echo -e "${Y}========================================================================${N}" | tee -a "$LOG_FILE"
echo ""
exit 1
