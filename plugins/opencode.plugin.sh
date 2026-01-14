#!/bin/bash

get_metadata() {
  cat <<'EOF'
name=opencode
description=OpenCode CLI with JSON output for tool calls
models=provider/model (optional)
requires_model=false
auto_approval=permission.edit=allow
EOF
}

validate_config() {
  # Ensure session directory is passed for config scaffolding
  return 0
}

build_command() {
  local prompt_file="$1"
  local log_file="$2"
  local session_dir="${3:-$(pwd)}"
  local model="$4"

  local root_dir
  root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local runner="$root_dir/runners/run-opencode.sh"

  echo "$runner"
  echo "$prompt_file"
  echo "$log_file"
  echo "$session_dir"
  echo "$model"
}

get_auto_approval() {
  echo "permission.edit=allow"
}
