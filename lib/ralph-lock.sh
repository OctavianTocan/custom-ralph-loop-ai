#!/bin/bash
# Ralph Lock File Management Functions
# Prevents multiple Ralph instances from running simultaneously

cleanup_lock() {
  local lock_file="$1"
  rm -f "$lock_file" 2>/dev/null || true
}

check_existing_ralph() {
  local lock_file="$1"
  local session_dir="$2"
  
  if [[ -f "$lock_file" ]]; then
    local lock_pid
    lock_pid=$(cat "$lock_file" 2>/dev/null)
    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
      echo ""
      echo "============================================================================"
      echo "  ERROR: Ralph is already running for this session!"
      echo "============================================================================"
      echo ""
      echo "  Session: $(basename "$session_dir")"
      echo "  PID:     $lock_pid"
      echo ""
      echo "  Options:"
      echo "    1. Wait for the current run to finish"
      echo "    2. Kill it:  kill $lock_pid"
      echo "    3. Force:    ./ralph.sh --session $(basename "$session_dir") --force"
      echo ""
      echo "  Status:  ./status.sh"
      echo ""
      echo "============================================================================"
      return 1
    else
      # Stale lock file - process no longer exists
      echo "Removing stale lock file (PID $lock_pid no longer running)"
      rm -f "$lock_file"
    fi
  fi
  
  return 0
}

create_lock_file() {
  local lock_file="$1"
  echo $$ > "$lock_file"
}
