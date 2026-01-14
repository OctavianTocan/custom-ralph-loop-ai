#!/bin/bash

get_metadata() {
  cat <<'EOF'
name=claude
description=Claude Code CLI with stream-json pretty-print support
models=opus,sonnet,haiku (optional)
requires_model=false
auto_approval=--dangerously-skip-permissions
EOF
}

validate_config() {
  # Claude does not require additional validation beyond standard PRD parsing
  return 0
}

build_command() {
  local prompt_file="$1"
  local log_file="$2"
  local session_dir="$3"
  local model="$4"

  local root_dir
  root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local runner="$root_dir/runners/run-claude.sh"

  echo "$runner"
  echo "$prompt_file"
  echo "$log_file"
  echo "$session_dir"
  echo "$model"
}

get_auto_approval() {
  echo "--dangerously-skip-permissions"
}
