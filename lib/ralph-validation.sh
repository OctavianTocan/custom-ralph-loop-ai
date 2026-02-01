#!/bin/bash
# Ralph Task Validation Functions
# Validates task completion and checks agent exit markers

check_all_tasks_complete() {
  local session_dir="$1"
  local total_var="$2"
  local passed_var="$3"
  
  local total_stories=0
  local passed_stories=0
  
  if command -v jq &> /dev/null && [[ -f "$session_dir/prd.json" ]]; then
    total_stories=$(jq '.userStories | length' "$session_dir/prd.json" 2>/dev/null || echo "0")
    passed_stories=$(jq '[.userStories[] | select(.passes == true)] | length' "$session_dir/prd.json" 2>/dev/null || echo "0")
  fi
  
  eval "$total_var='$total_stories'"
  eval "$passed_var='$passed_stories'"
  
  if [[ "$total_stories" -gt 0 && "$total_stories" == "$passed_stories" ]]; then
    return 0
  fi
  return 1
}

check_exit_marker() {
  local log_file="$1"
  local marker="$2"
  
  if tail -100 "$log_file" | grep -q "$marker"; then
    return 0
  fi
  return 1
}

validate_complete_marker() {
  local log_file="$1"
  local all_tasks_complete="$2"
  local total_stories="$3"
  local passed_stories="$4"
  
  if check_exit_marker "$log_file" "<promise>COMPLETE</promise>"; then
    if [[ "$all_tasks_complete" == true ]]; then
      # Valid completion - all tasks are done
      return 0
    else
      # Invalid completion attempt - tasks remain incomplete
      echo "" | tee -a "$log_file"
      local Y='\033[1;33m'
      local G='\033[0;32m'
      local BOLD='\033[1m'
      local N='\033[0m'
      echo -e "${Y}========================================================================${N}" | tee -a "$log_file"
      echo -e "${Y}WARNING: Agent signaled COMPLETE but tasks remain incomplete${N}" | tee -a "$log_file"
      echo -e "${Y}Progress: ${G}$passed_stories${N}/${BOLD}$total_stories${N} stories complete${N}" | tee -a "$log_file"
      echo -e "${Y}Continuing iteration to complete remaining tasks...${N}" | tee -a "$log_file"
      echo -e "${Y}========================================================================${N}" | tee -a "$log_file"
      echo "" | tee -a "$log_file"
      return 1
    fi
  fi
  return 2
}

validate_blocked_marker() {
  local log_file="$1"
  local all_tasks_complete="$2"
  local total_stories="$3"
  local passed_stories="$4"
  
  if check_exit_marker "$log_file" "<promise>BLOCKED"; then
    # If there are incomplete tasks, agent should continue with non-blocked tasks
    if [[ "$total_stories" -gt 0 && "$all_tasks_complete" != true ]]; then
      echo "" | tee -a "$log_file"
      local Y='\033[1;33m'
      local G='\033[0;32m'
      local BOLD='\033[1m'
      local N='\033[0m'
      echo -e "${Y}========================================================================${N}" | tee -a "$log_file"
      echo -e "${Y}WARNING: Agent signaled BLOCKED but tasks remain incomplete${N}" | tee -a "$log_file"
      echo -e "${Y}Progress: ${G}$passed_stories${N}/${BOLD}$total_stories${N} stories complete${N}" | tee -a "$log_file"
      echo -e "${Y}Agent should continue with non-blocked tasks...${N}" | tee -a "$log_file"
      echo -e "${Y}========================================================================${N}" | tee -a "$log_file"
      echo "" | tee -a "$log_file"
      return 1
    else
      # No tasks defined or other unexpected state - allow BLOCKED exit
      return 0
    fi
  fi
  return 2
}

validate_validation_blocked_marker() {
  local log_file="$1"
  
  if check_exit_marker "$log_file" "<promise>VALIDATION_BLOCKED</promise>"; then
    return 0
  fi
  return 2
}

exit_complete() {
  local log_file="$1"
  local total_stories="$2"
  local passed_stories="$3"
  
  echo "" | tee -a "$log_file"
  local G='\033[0;32m'
  local N='\033[0m'
  echo -e "${G}========================================================================${N}" | tee -a "$log_file"
  echo -e "${G}RALPH COMPLETE${N}" | tee -a "$log_file"
  echo -e "All $passed_stories/$total_stories stories passed" | tee -a "$log_file"
  echo -e "$(date)" | tee -a "$log_file"
  echo -e "${G}========================================================================${N}" | tee -a "$log_file"
  echo ""
  exit 0
}

exit_blocked() {
  local log_file="$1"
  
  echo "" | tee -a "$log_file"
  local R='\033[0;31m'
  local N='\033[0m'
  echo -e "${R}========================================================================${N}" | tee -a "$log_file"
  echo -e "${R}RALPH BLOCKED${N}" | tee -a "$log_file"
  echo -e "Check log file: $log_file" | tee -a "$log_file"
  echo -e "${R}========================================================================${N}" | tee -a "$log_file"
  echo ""
  exit 1
}

exit_validation_blocked() {
  local log_file="$1"
  
  echo "" | tee -a "$log_file"
  local Y='\033[1;33m'
  local N='\033[0m'
  echo -e "${Y}========================================================================${N}" | tee -a "$log_file"
  echo -e "${Y}RALPH VALIDATION BLOCKED${N}" | tee -a "$log_file"
  echo -e "${Y}Code Implementation: ✅ COMPLETE${N}" | tee -a "$log_file"
  echo -e "${Y}Validation Status:   ⚠️  BLOCKED (requires human intervention)${N}" | tee -a "$log_file"
  echo "" | tee -a "$log_file"
  echo -e "Check progress.txt for handoff document and blocker details" | tee -a "$log_file"
  echo -e "Log file: $log_file" | tee -a "$log_file"
  echo -e "${Y}========================================================================${N}" | tee -a "$log_file"
  echo ""
  exit 2
}

show_progress() {
  local log_file="$1"
  local total_stories="$2"
  local passed_stories="$3"
  
  if [[ "$total_stories" -gt 0 ]]; then
    local pct=$((passed_stories * 100 / total_stories))
    local C='\033[0;36m'
    local G='\033[0;32m'
    local BOLD='\033[1m'
    local D='\033[2m'
    local N='\033[0m'
    echo -e "${C}[Progress]${N} ${G}$passed_stories${N}/${BOLD}$total_stories${N} stories complete ${D}($pct%)${N}" | tee -a "$log_file"
  fi
}
