#!/bin/bash

get_metadata() {
  cat <<'EOF'
name=cursor
description=Cursor CLI agent with stream-json parsing
models=cursor model name (required)
requires_model=true
auto_approval=--approve-mcps
EOF
}

read_model_from_prd() {
  local prd_file="$1"

  if command -v jq &> /dev/null; then
    jq -r '.model // ""' "$prd_file" 2>/dev/null
  else
    grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$prd_file" 2>/dev/null | sed 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
  fi
}

validate_config() {
  local prd_file="$1"
  local model="$2"

  if [[ -z "$model" && -f "$prd_file" ]]; then
    model=$(read_model_from_prd "$prd_file")
  fi

  if [[ -z "$model" ]]; then
    echo "Error: Cursor agent requires a model in prd.json (e.g., \"claude-sonnet-4-20250514\")" >&2
    return 1
  fi

  return 0
}

build_command() {
  local prompt_file="$1"
  local log_file="$2"
  local session_dir="$3"
  local model="$4"

  local root_dir
  root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local runner="$root_dir/runners/run-cursor.sh"

  echo "$runner"
  echo "$prompt_file"
  echo "$log_file"
  echo "$session_dir"
  echo "$model"
}

get_auto_approval() {
  echo "--approve-mcps"
}
