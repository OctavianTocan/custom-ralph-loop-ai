#!/bin/bash
# Ralph Session Initialization Functions
# Handles creation of new Ralph sessions

init_session() {
  local script_dir="$1"
  local session_name="$2"
  
  if [[ -z "$session_name" ]]; then
    echo "Error: Session name required"
    echo "Usage: ralph.sh init <session-name>"
    return 1
  fi

  local session_path="$script_dir/sessions/$session_name"

  # Check if session already exists
  if [[ -d "$session_path" ]]; then
    echo "Error: Session '$session_name' already exists at $session_path"
    return 1
  fi

  # Create session directory
  mkdir -p "$session_path"

  # Generate template prd.json
  cat > "$session_path/prd.json" <<'EOF'
{
  "branchName": "ralph/SESSION_NAME",
  "agent": "claude",
  "model": "sonnet",
  "validationCommands": {},
  "userStories": [
    {
      "id": "STORY-001",
      "title": "First task to implement",
      "acceptanceCriteria": [
        "Describe what success looks like",
        "Add measurable criteria"
      ],
      "priority": 1,
      "complexity": "medium",
      "passes": false
    }
  ]
}
EOF

  # Replace placeholder with actual session name (portable for macOS and Linux)
  sed "s/SESSION_NAME/$session_name/g" "$session_path/prd.json" > "$session_path/prd.json.tmp"
  mv "$session_path/prd.json.tmp" "$session_path/prd.json"

  # Create progress.txt
  cat > "$session_path/progress.txt" <<EOF
# Ralph Progress Log

Session: $session_name
Location: sessions/$session_name/
Branch: ralph/$session_name

---

## Codebase Patterns

(Add discovered patterns here)

---
EOF

  # Create learnings.md
  cat > "$session_path/learnings.md" <<EOF
# Learnings: $session_name

Session: $session_name
Branch: ralph/$session_name

---
EOF

  echo ""
  echo "Session created: $session_name"
  echo ""
  echo "Next steps:"
  echo "  1. Edit sessions/$session_name/prd.json to define your tasks"
  echo "  2. Run: ./ralph.sh --session $session_name"
  echo ""

  return 0
}

init_progress_file() {
  local progress_file="$1"
  
  if [[ ! -f "$progress_file" ]]; then
    echo "# Ralph Progress Log" > "$progress_file"
    echo "Started: $(date)" >> "$progress_file"
    echo "" >> "$progress_file"
    echo "## Codebase Patterns" >> "$progress_file"
    echo "" >> "$progress_file"
    echo "---" >> "$progress_file"
    echo "" >> "$progress_file"
  fi
}
