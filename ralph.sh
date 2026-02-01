#!/bin/bash
set -e

# Ralph Autonomous Coding Loop - Main Script
# Usage: ./ralph.sh [iterations] [--session session-name] [--force]
#        Or: ./ralph.sh session-name [iterations] [--force]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR/plugins"
LIB_DIR="$SCRIPT_DIR/lib"
MAX_ITERATIONS=10
SESSION_DIR=""
FORCE=false
LIST_AGENTS=false
WORKFLOW=""
VERSION="1.0.0"

# Source library modules
source "$LIB_DIR/ralph-help.sh"
source "$LIB_DIR/ralph-plugins.sh"
source "$LIB_DIR/ralph-session.sh"
source "$LIB_DIR/ralph-lock.sh"
source "$LIB_DIR/ralph-config.sh"
source "$LIB_DIR/ralph-validation.sh"
source "$LIB_DIR/ralph-display.sh"

# Handle --help and --version flags FIRST (before session resolution)
for arg in "$@"; do
  case "$arg" in
    --help|-h)
      show_help "$SCRIPT_DIR"
      exit 0
      ;;
    --version|-v)
      show_version "$SCRIPT_DIR" "$VERSION"
      exit 0
      ;;
  esac
done

# Handle init subcommand FIRST (before session resolution)
if [[ "$1" == "init" ]]; then
  init_session "$SCRIPT_DIR" "$2"
  exit $?
fi

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
    --list-agents)
      LIST_AGENTS=true
      shift
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

# Handle plugin listing early
if [[ "$LIST_AGENTS" == true ]]; then
  show_available_agents "$PLUGINS_DIR"
  exit 0
fi

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
init_progress_file "$PROGRESS_FILE"

# Lock file mechanism - Prevent multiple Ralph loops
if [[ "$FORCE" != true ]]; then
  check_existing_ralph "$LOCK_FILE" "$SESSION_DIR" || exit 1
fi

create_lock_file "$LOCK_FILE"
trap "cleanup_lock \"$LOCK_FILE\"" EXIT INT TERM

# Agent detection
AGENT=""
MODEL=""
load_agent_config "$SESSION_DIR" AGENT MODEL
load_workflow_config "$SESSION_DIR" "$WORKFLOW" WORKFLOW

PLUGIN_FILE=""
case "$AGENT" in
  claude|codex|opencode|cursor)
    ;;
  *)
    PLUGIN_FILE=$(get_plugin_path_for_agent "$AGENT" "$PLUGINS_DIR")
    if [[ -z "$PLUGIN_FILE" ]]; then
      echo "Warning: Unknown agent '$AGENT', defaulting to 'claude'" >&2
      AGENT="claude"
    fi
    ;;
esac
[[ -n "$PLUGIN_FILE" ]] || PLUGIN_FILE=$(get_plugin_path_for_agent "$AGENT" "$PLUGINS_DIR")
PLUGIN_LOADED=false

RUNNERS_DIR="$SCRIPT_DIR/runners"
RUNNER_SCRIPT="$RUNNERS_DIR/run-$AGENT.sh"

if [[ ! -f "$RUNNER_SCRIPT" ]]; then
  if [[ -n "$PLUGIN_FILE" ]]; then
    echo "Warning: Runner script not found, using plugin command: $RUNNER_SCRIPT" >&2
  else
    echo "Error: Runner script not found: $RUNNER_SCRIPT" >&2
    exit 1
  fi
fi

check_agent_cli "$AGENT"

# Plugin validation
if [[ -n "$PLUGIN_FILE" ]]; then
  if validate_plugin "$PLUGIN_FILE" "$AGENT" "$PLUGINS_DIR" "$SESSION_DIR" "$MODEL"; then
    PLUGIN_LOADED=true
  else
    exit 1
  fi
fi

# Workflow validation
validate_workflow "$WORKFLOW" "$SCRIPT_DIR" || exit 1
WORKFLOW_PROMPT=$(load_workflow_prompt "$WORKFLOW" "$SCRIPT_DIR")

# Branch enforcement
BRANCH_NAME=""
load_branch_config "$SESSION_DIR" BRANCH_NAME
validate_branch "$BRANCH_NAME" "$SESSION_DIR" || exit 1
checkout_branch "$BRANCH_NAME" "$LOG_FILE" || exit 1

# Iteration suggestion
SUGGESTED_ITERATIONS=0
SUGGESTED_SMALL=0
SUGGESTED_MEDIUM=0
SUGGESTED_LARGE=0
calculate_suggested_iterations "$SESSION_DIR" SUGGESTED_ITERATIONS SUGGESTED_SMALL SUGGESTED_MEDIUM SUGGESTED_LARGE

# Use suggested if --iterations auto was specified
if [[ "$ITERATIONS_AUTO" == true && -n "$SUGGESTED_ITERATIONS" && "$SUGGESTED_ITERATIONS" -gt 0 ]]; then
  MAX_ITERATIONS="$SUGGESTED_ITERATIONS"
fi

# Build breakdown string
BREAKDOWN=$(build_breakdown_string "$SUGGESTED_SMALL" "$SUGGESTED_MEDIUM" "$SUGGESTED_LARGE")

# Startup banner
show_startup_banner "$SESSION_DIR" "$AGENT" "$MODEL" "$MAX_ITERATIONS" "$SUGGESTED_ITERATIONS" "$BREAKDOWN" "$LOG_FILE"

# Initialize log
init_log_file "$LOG_FILE" "$SESSION_DIR" "$AGENT" "$MODEL" "$MAX_ITERATIONS"

# Main loop
ITERATION_PATTERN='Iteration [0-9]+ of [0-9]+'

for i in $(seq 1 $MAX_ITERATIONS); do
  # Capture most recent iteration log for resume context
  LAST_ITERATION_CONTEXT=""
  if [[ -f "$LOG_FILE" ]]; then
    LAST_ITERATION_LINE=$(awk -v pattern="$ITERATION_PATTERN" '$0 ~ pattern {line=NR} END {print line+0}' "$LOG_FILE")
    if [[ "$LAST_ITERATION_LINE" -gt 0 ]]; then
      TOTAL_LINES=$(wc -l < "$LOG_FILE")
      LAST_ITERATION_OFFSET=$((TOTAL_LINES - LAST_ITERATION_LINE + 1))
      if [[ "$LAST_ITERATION_OFFSET" -gt 200 ]]; then
        LAST_ITERATION_CONTEXT=$(tail -n 200 "$LOG_FILE")
      else
        LAST_ITERATION_CONTEXT=$(tail -n "$LAST_ITERATION_OFFSET" "$LOG_FILE")
      fi
    else
      LAST_ITERATION_CONTEXT=$(tail -n 200 "$LOG_FILE")
    fi
  fi

  show_iteration_header "$i" "$MAX_ITERATIONS" "$LOG_FILE"

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

  run_agent_command "$PROMPT_FILE" "$LOG_FILE" "$SESSION_DIR" "$MODEL" "$PLUGIN_LOADED" "$RUNNER_SCRIPT" "$AGENT"
  rm -f "$PROMPT_FILE"

  # Validation loop - Check task completion FIRST before honoring exit markers
  TOTAL_STORIES=0
  PASSED_STORIES=0
  ALL_TASKS_COMPLETE=false
  
  if check_all_tasks_complete "$SESSION_DIR" TOTAL_STORIES PASSED_STORIES; then
    ALL_TASKS_COMPLETE=true
  fi

  # RULE 1: Agent signals COMPLETE - must verify all tasks are actually complete
  validate_complete_marker "$LOG_FILE" "$ALL_TASKS_COMPLETE" "$TOTAL_STORIES" "$PASSED_STORIES"
  COMPLETE_RESULT=$?
  if [[ $COMPLETE_RESULT -eq 0 ]]; then
    exit_complete "$LOG_FILE" "$TOTAL_STORIES" "$PASSED_STORIES"
  fi

  # RULE 2: Agent signals BLOCKED - allow exit only for genuine blockers
  validate_blocked_marker "$LOG_FILE" "$ALL_TASKS_COMPLETE" "$TOTAL_STORIES" "$PASSED_STORIES"
  BLOCKED_RESULT=$?
  if [[ $BLOCKED_RESULT -eq 0 ]]; then
    exit_blocked "$LOG_FILE"
  fi

  # RULE 3: Agent signals VALIDATION_BLOCKED - allow exit (validation blockers are legitimate)
  validate_validation_blocked_marker "$LOG_FILE"
  VALIDATION_BLOCKED_RESULT=$?
  if [[ $VALIDATION_BLOCKED_RESULT -eq 0 ]]; then
    exit_validation_blocked "$LOG_FILE"
  fi

  # RULE 4: No exit marker but all tasks complete - auto-complete
  if [[ "$ALL_TASKS_COMPLETE" == true ]]; then
    exit_complete "$LOG_FILE" "$TOTAL_STORIES" "$PASSED_STORIES"
  fi

  # Show progress if tasks remain
  show_progress "$LOG_FILE" "$TOTAL_STORIES" "$PASSED_STORIES"

  sleep 2
done

show_max_iterations_reached "$LOG_FILE"
exit 1
