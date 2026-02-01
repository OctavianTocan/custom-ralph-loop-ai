#!/bin/bash
# Ralph Configuration Loading Functions
# Loads agent, model, workflow, and branch configuration from prd.json

load_agent_config() {
  local session_dir="$1"
  local agent_var="$2"
  local model_var="$3"
  
  local agent="claude"
  local model=""
  
  if command -v jq &> /dev/null && [[ -f "$session_dir/prd.json" ]]; then
    agent=$(jq -r '.agent // "claude"' "$session_dir/prd.json" 2>/dev/null || echo "claude")
    model=$(jq -r '.model // ""' "$session_dir/prd.json" 2>/dev/null || echo "")
  elif [[ -f "$session_dir/prd.json" ]]; then
    agent=$(grep -o '"agent"[[:space:]]*:[[:space:]]*"[^"]*"' "$session_dir/prd.json" 2>/dev/null | sed 's/.*"agent"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "claude")
    model=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$session_dir/prd.json" 2>/dev/null | sed 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
  fi
  
  eval "$agent_var='$agent'"
  eval "$model_var='$model'"
}

load_workflow_config() {
  local session_dir="$1"
  local workflow_cli="$2"
  local workflow_var="$3"
  
  local workflow="$workflow_cli"
  
  # Read workflow from prd.json if not specified via CLI
  if [[ -z "$workflow" ]]; then
    if command -v jq &> /dev/null && [[ -f "$session_dir/prd.json" ]]; then
      workflow=$(jq -r '.workflow // ""' "$session_dir/prd.json" 2>/dev/null || echo "")
    elif [[ -f "$session_dir/prd.json" ]]; then
      workflow=$(grep -o '"workflow"[[:space:]]*:[[:space:]]*"[^"]*"' "$session_dir/prd.json" 2>/dev/null | sed 's/.*"workflow"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
    fi
  fi
  
  eval "$workflow_var='$workflow'"
}

validate_workflow() {
  local workflow="$1"
  local script_dir="$2"
  
  if [[ -z "$workflow" ]]; then
    return 0
  fi
  
  local workflow_prompt_file="$script_dir/workflows/$workflow/prompt.md"
  if [[ ! -f "$workflow_prompt_file" ]]; then
    echo ""
    echo "============================================================================"
    echo "  ERROR: Workflow prompt not found: $workflow"
    echo "============================================================================"
    echo ""
    echo "  Expected: $workflow_prompt_file"
    echo ""
    echo "  Available workflows:"
    if [[ -d "$script_dir/workflows" ]]; then
      ls -1 "$script_dir/workflows/" 2>/dev/null | sed 's/^/    - /' || echo "    (none)"
    else
      echo "    (none - workflows/ directory does not exist)"
    fi
    echo ""
    echo "============================================================================"
    return 1
  fi
  
  return 0
}

load_workflow_prompt() {
  local workflow="$1"
  local script_dir="$2"
  
  if [[ -n "$workflow" ]]; then
    cat "$script_dir/workflows/$workflow/prompt.md"
  fi
}

load_branch_config() {
  local session_dir="$1"
  local branch_var="$2"
  
  local branch_name=""
  
  if command -v jq &> /dev/null && [[ -f "$session_dir/prd.json" ]]; then
    branch_name=$(jq -r '.branchName // ""' "$session_dir/prd.json" 2>/dev/null || echo "")
  elif [[ -f "$session_dir/prd.json" ]]; then
    branch_name=$(grep -o '"branchName"[[:space:]]*:[[:space:]]*"[^"]*"' "$session_dir/prd.json" 2>/dev/null | sed 's/.*"branchName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
  fi
  
  eval "$branch_var='$branch_name'"
}

validate_branch() {
  local branch_name="$1"
  local session_dir="$2"
  
  if [[ -z "$branch_name" ]]; then
    echo ""
    echo "============================================================================"
    echo "  ERROR: branchName not found in prd.json"
    echo "============================================================================"
    echo ""
    echo "  Session: $session_dir/prd.json"
    echo ""
    echo "  Please add a branchName field to your prd.json:"
    echo '  "branchName": "ralph/your-feature-name"'
    echo ""
    echo "============================================================================"
    return 1
  fi
  
  return 0
}

checkout_branch() {
  local branch_name="$1"
  local log_file="$2"
  
  echo "Checking out branch: $branch_name"
  
  # Check if branch exists
  if git rev-parse --verify "$branch_name" &> /dev/null; then
    # Branch exists, check it out
    if ! git checkout "$branch_name" 2>&1 | tee -a "$log_file"; then
      echo ""
      echo "============================================================================"
      echo "  ERROR: Failed to checkout branch: $branch_name"
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
      echo "    git checkout $branch_name"
      echo ""
      echo "============================================================================"
      return 1
    fi
  else
    # Branch doesn't exist, create it
    if ! git checkout -b "$branch_name" 2>&1 | tee -a "$log_file"; then
      echo ""
      echo "============================================================================"
      echo "  ERROR: Failed to create branch: $branch_name"
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
      return 1
    fi
  fi
  
  echo "Successfully on branch: $branch_name"
  echo ""
  return 0
}

check_agent_cli() {
  local agent="$1"
  
  case "$agent" in
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
}
