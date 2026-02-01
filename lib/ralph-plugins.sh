#!/bin/bash
# Ralph Plugin Management Functions
# Handles plugin discovery, metadata extraction, and validation

get_plugin_metadata() {
  local plugin_file="$1"
  [[ -f "$plugin_file" ]] || return 1
  bash -c "source \"$plugin_file\" && get_metadata" 2>/dev/null || true
}

get_plugin_field() {
  local metadata="$1"
  local field="$2"
  while IFS='=' read -r key value; do
    if [[ "$key" == "$field" ]]; then
      echo "$value"
      return 0
    fi
  done <<< "$metadata"
}

get_plugin_path_for_agent() {
  local agent="$1"
  local plugins_dir="$2"
  local candidate="$plugins_dir/$agent.plugin.sh"
  if [[ -f "$candidate" ]]; then
    echo "$candidate"
  fi
}

show_available_agents() {
  local plugins_dir="$1"
  echo ""
  echo "Available agents (plugins):"

  shopt -s nullglob
  local found=0
  for plugin in "$plugins_dir"/*.plugin.sh; do
    local metadata name description models requires auto_approval
    metadata=$(get_plugin_metadata "$plugin" || true)
    name=$(get_plugin_field "$metadata" "name")
    description=$(get_plugin_field "$metadata" "description")
    models=$(get_plugin_field "$metadata" "models")
    requires=$(get_plugin_field "$metadata" "requires_model")
    auto_approval=$(get_plugin_field "$metadata" "auto_approval")

    [[ -n "$name" ]] || continue
    found=1

    echo "  - $name: ${description:-No description provided}"
    [[ -n "$models" ]] && echo "    Models: $models"
    if [[ "$requires" == "true" ]]; then
      echo "    Requires model in prd.json"
    fi
    [[ -n "$auto_approval" ]] && echo "    Auto-approval: $auto_approval"
  done
  shopt -u nullglob

  if [[ $found -eq 0 ]]; then
    echo "  (no plugins found in $plugins_dir)"
  fi
}

validate_plugin() {
  local plugin_file="$1"
  local agent="$2"
  local plugins_dir="$3"
  local session_dir="$4"
  local model="$5"
  
  if [[ "$plugin_file" != "$plugins_dir/"* || "$(basename "$plugin_file")" != "$agent.plugin.sh" || ! -f "$plugin_file" ]]; then
    echo "Error: Invalid plugin path for agent '$agent': $plugin_file" >&2
    return 1
  fi
  
  # shellcheck source=/dev/null
  source "$plugin_file"
  
  if declare -f validate_config >/dev/null 2>&1; then
    if ! validate_config "$session_dir/prd.json" "$model"; then
      echo "Plugin validation failed for agent '$agent'" >&2
      return 1
    fi
  fi
  
  return 0
}

run_agent_command() {
  local prompt_file="$1"
  local log_file="$2"
  local session_dir="$3"
  local model="$4"
  local plugin_loaded="$5"
  local runner_script="$6"
  local agent="$7"

  if [[ "$plugin_loaded" == true ]] && declare -f build_command >/dev/null 2>&1; then
    local PLUGIN_CMD=()
    mapfile -t PLUGIN_CMD < <(build_command "$prompt_file" "$log_file" "$session_dir" "$model")
    if [[ ${#PLUGIN_CMD[@]} -eq 0 ]]; then
      echo "Error: Plugin '$agent' did not return a command to execute" >&2
      return 1
    fi
    "${PLUGIN_CMD[@]}" || true
    return
  fi

  "$runner_script" "$prompt_file" "$log_file" "$session_dir" "$model" || true
}
