#!/bin/bash
# Ralph Help and Version Display Functions
# Provides help text and version information for Ralph

show_help() {
  local script_dir="$1"
  cat <<EOF
Ralph Autonomous Coding Loop

Usage:
  ralph.sh [iterations] --session <name> [options]
  ralph.sh <session-name> [iterations] [options]

Options:
  --session <name>    Session name (from sessions/ directory)
  --iterations <n>    Number of iterations (or 'auto' for suggested count)
  --force, -f         Force start even if session is running
  --workflow <name>   Use workflow from .claude/workflows/
  --list-agents       List available agents discovered from plugins/
  --help, -h          Show this help message
  --version, -v       Show version information

Examples:
  ralph.sh 25 --session my-feature
  ralph.sh my-feature 25
  ralph.sh --session my-feature --force
  ralph.sh --session my-feature --iterations auto

Available sessions:
EOF
  if [[ -d "$script_dir/sessions" ]]; then
    ls -1 "$script_dir/sessions/" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
  else
    echo "  (none)"
  fi
  echo ""
}

show_version() {
  local script_dir="$1"
  local version="$2"
  
  # Try to get version from git tags
  if command -v git &> /dev/null && [[ -d "$script_dir/.git" ]]; then
    local git_version
    git_version=$(git -C "$script_dir" describe --tags 2>/dev/null || git -C "$script_dir" log -1 --format="%h" 2>/dev/null || echo "")
    if [[ -n "$git_version" ]]; then
      echo "ralph-ai-coding-loop $git_version"
      return 0
    fi
  fi
  # Fallback to hardcoded version
  echo "ralph-ai-coding-loop v$version"
}
