#!/bin/bash
# Ralph Display Functions
# Banner, startup information, and iteration suggestion display

show_startup_banner() {
  local session_dir="$1"
  local agent="$2"
  local model="$3"
  local max_iterations="$4"
  local suggested_iterations="$5"
  local breakdown="$6"
  local log_file="$7"
  
  local C='\033[0;36m'
  local G='\033[0;32m'
  local Y='\033[1;33m'
  local D='\033[2m'
  local N='\033[0m'
  local BOLD='\033[1m'

  echo ""
  echo -e "${C}========================================================================${N}"
  echo -e "${BOLD}${G}RALPH${N} ${D}AUTONOMOUS CODING LOOP${N}"
  echo -e "${C}========================================================================${N}"
  echo ""
  echo -e "  ${BOLD}Session:${N}    ${C}$(basename "$session_dir")${N}"
  echo -e "  ${BOLD}Agent:${N}      ${G}$agent${N}"
  [[ -n "$model" ]] && echo -e "  ${BOLD}Model:${N}      ${Y}$model${N}"
  echo -e "  ${BOLD}Iterations:${N} ${BOLD}$max_iterations${N}"
  if [[ -n "$suggested_iterations" && "$suggested_iterations" -gt 0 ]]; then
    if [[ -n "$breakdown" ]]; then
      echo -e "  ${BOLD}Suggested:${N}  ${Y}$suggested_iterations${N} ${D}($breakdown)${N}"
    else
      echo -e "  ${BOLD}Suggested:${N}  ${Y}$suggested_iterations${N}"
    fi
  fi
  echo -e "  ${BOLD}PID:${N}        ${D}$$${N}"
  echo ""
  echo -e "  ${BOLD}Monitor:${N}    ${D}tail -f${N} $log_file"
  echo -e "  ${BOLD}Status:${N}     ${D}./status.sh${N}"
  echo -e "  ${BOLD}Watch:${N}      ${D}./watch.sh${N}"
  echo -e "  ${BOLD}Stop:${N}       ${D}kill $$${N}"
  echo ""
  echo -e "${C}========================================================================${N}"
  echo ""
}

init_log_file() {
  local log_file="$1"
  local session_dir="$2"
  local agent="$3"
  local model="$4"
  local max_iterations="$5"
  
  {
    echo "=== Ralph Session Started: $(date) ==="
    echo "Session: $session_dir"
    echo "Agent: $agent"
    [[ -n "$model" ]] && echo "Model: $model"
    echo "Max iterations: $max_iterations"
    echo "PID: $$"
    echo ""
  } > "$log_file"
}

show_iteration_header() {
  local iteration="$1"
  local max_iterations="$2"
  local log_file="$3"
  
  echo ""
  local C='\033[0;36m'
  local N='\033[0m'
  echo -e "${C}========================================================================${N}" | tee -a "$log_file"
  echo -e "${C}Iteration $iteration of $max_iterations${N}  $(date)" | tee -a "$log_file"
  echo -e "${C}========================================================================${N}" | tee -a "$log_file"
  echo "" | tee -a "$log_file"
}

show_max_iterations_reached() {
  local log_file="$1"
  
  echo "" | tee -a "$log_file"
  local Y='\033[1;33m'
  local N='\033[0m'
  echo -e "${Y}========================================================================${N}" | tee -a "$log_file"
  echo -e "${Y}MAX ITERATIONS REACHED${N}" | tee -a "$log_file"
  echo -e "Run again to continue: $(date)" | tee -a "$log_file"
  echo -e "${Y}========================================================================${N}" | tee -a "$log_file"
  echo ""
}

calculate_suggested_iterations() {
  local session_dir="$1"
  local suggested_var="$2"
  local small_var="$3"
  local medium_var="$4"
  local large_var="$5"
  
  local suggested=0
  local small=0
  local medium=0
  local large=0

  if command -v jq &> /dev/null; then
    # Check for explicit suggestedIterations first
    local explicit_suggested
    explicit_suggested=$(jq -r '.suggestedIterations // empty' "$session_dir/prd.json" 2>/dev/null)
    if [[ -n "$explicit_suggested" && "$explicit_suggested" != "null" ]]; then
      suggested="$explicit_suggested"
    else
      # Calculate from userStories complexity (only incomplete tasks)
      while IFS= read -r complexity; do
        case "$complexity" in
          small) ((small++)) || true; ((suggested+=1)) || true ;;
          large) ((large++)) || true; ((suggested+=3)) || true ;;
          *) ((medium++)) || true; ((suggested+=2)) || true ;;  # default is medium
        esac
      done < <(jq -r '.userStories[] | select(.passes != true) | .complexity // "medium"' "$session_dir/prd.json" 2>/dev/null)
    fi
  else
    # Fallback without jq - check for suggestedIterations
    local explicit_suggested
    explicit_suggested=$(grep -o '"suggestedIterations"[[:space:]]*:[[:space:]]*[0-9]*' "$session_dir/prd.json" 2>/dev/null | grep -o '[0-9]*' | head -1)
    if [[ -n "$explicit_suggested" ]]; then
      suggested="$explicit_suggested"
    else
      # Count tasks by complexity (simplified without jq)
      local task_count
      task_count=$(grep -c '"passes"[[:space:]]*:[[:space:]]*false' "$session_dir/prd.json" 2>/dev/null || echo "0")
      suggested=$((task_count * 2))  # Default to medium complexity
    fi
  fi
  
  eval "$suggested_var='$suggested'"
  eval "$small_var='$small'"
  eval "$medium_var='$medium'"
  eval "$large_var='$large'"
}

build_breakdown_string() {
  local small="$1"
  local medium="$2"
  local large="$3"
  
  if [[ $small -gt 0 || $medium -gt 0 || $large -gt 0 ]]; then
    local parts=()
    [[ $small -gt 0 ]] && parts+=("$small small")
    [[ $medium -gt 0 ]] && parts+=("$medium medium")
    [[ $large -gt 0 ]] && parts+=("$large large")
    local IFS=', '
    echo "${parts[*]}"
  fi
}
