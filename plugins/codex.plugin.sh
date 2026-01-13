#!/bin/bash

get_metadata() {
  cat <<'EOF'
name=codex
description=OpenAI Codex CLI runner with full-auto execution
models=gpt-5.1, gpt-5.2-codex, gpt-4o (optional)
requires_model=false
auto_approval=--full-auto
EOF
}

validate_config() {
  # Codex supports optional model configuration
  return 0
}

build_command() {
  local prompt_file="$1"
  local log_file="$2"
  local session_dir="$3"
  local model="$4"

  local root_dir
  root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local runner="$root_dir/runners/run-codex.sh"

  echo "$runner"
  echo "$prompt_file"
  echo "$log_file"
  echo "$session_dir"
  echo "$model"
}

get_auto_approval() {
  echo "--full-auto"
}
