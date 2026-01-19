#!/bin/bash
set -e

# Ralph Interactive Interview Script
# Usage: ./ralph-interview.sh [session-name]
# Conducts an interactive CLI interview to generate a PRD for Ralph

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_NAME="$1"
DATE=$(date +%Y-%m-%d)

# Colors for better UX
C='\033[0;36m'    # Cyan
G='\033[0;32m'    # Green
Y='\033[1;33m'    # Yellow
R='\033[0;31m'    # Red
D='\033[2m'       # Dim
N='\033[0m'       # No color
BOLD='\033[1m'

# ============================================================================
# Helper Functions
# ============================================================================

# Escape JSON strings (basic escaping for quotes and backslashes)
json_escape() {
  local string="$1"
  # Escape backslashes first, then quotes
  string="${string//\\/\\\\}"
  string="${string//\"/\\\"}"
  echo "$string"
}

print_header() {
  echo ""
  echo -e "${C}========================================================================${N}"
  echo -e "${BOLD}$1${N}"
  echo -e "${C}========================================================================${N}"
  echo ""
}

print_section() {
  echo ""
  echo -e "${C}$1${N}"
  echo ""
}

print_success() {
  echo -e "${G}✓${N} $1"
}

print_error() {
  echo -e "${R}✗${N} $1"
}

print_info() {
  echo -e "${D}ℹ${N} $1"
}

ask_question() {
  local question="$1"
  local default="$2"
  local response
  
  if [[ -n "$default" ]]; then
    echo -e "${BOLD}❓ $question${N} ${D}[$default]${N}"
  else
    echo -e "${BOLD}❓ $question${N}"
  fi
  
  read -r response
  
  if [[ -z "$response" && -n "$default" ]]; then
    echo "$default"
  else
    echo "$response"
  fi
}

ask_yes_no() {
  local question="$1"
  local default="${2:-y}"
  local response
  
  if [[ "$default" == "y" ]]; then
    echo -e "${BOLD}❓ $question${N} ${D}[Y/n]${N}"
  else
    echo -e "${BOLD}❓ $question${N} ${D}[y/N]${N}"
  fi
  
  read -r response
  response="${response,,}"  # Convert to lowercase
  
  if [[ -z "$response" ]]; then
    response="$default"
  fi
  
  [[ "$response" == "y" || "$response" == "yes" ]]
}

ask_multiline() {
  local prompt="$1"
  echo -e "${BOLD}❓ $prompt${N}"
  echo -e "${D}(Enter a blank line when done)${N}"
  
  local lines=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && break
    lines+=("$line")
  done
  
  printf '%s\n' "${lines[@]}"
}

# ============================================================================
# Welcome
# ============================================================================

print_header "RALPH INTERACTIVE INTERVIEW"

cat << EOF
${D}Welcome! I'll ask you some questions to understand your requirements,
then I'll generate a PRD (Product Requirements Document) that Ralph can execute.

This should take about 5-10 minutes.${N}

EOF

# ============================================================================
# Step 1: Session Name
# ============================================================================

print_section "📋 Session Information"

if [[ -z "$SESSION_NAME" ]]; then
  SESSION_NAME=$(ask_question "What would you like to call this session?" "my-feature")
fi

# Validate session name (convert to kebab-case)
SESSION_NAME=$(echo "$SESSION_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | tr ' ' '-')
FULL_SESSION_NAME="${DATE}-${SESSION_NAME}"
SESSION_DIR="$SCRIPT_DIR/sessions/$FULL_SESSION_NAME"

if [[ -d "$SESSION_DIR" ]]; then
  print_error "Session already exists: $FULL_SESSION_NAME"
  if ! ask_yes_no "Overwrite existing session?"; then
    echo "Aborting."
    exit 1
  fi
  rm -rf "$SESSION_DIR"
fi

print_success "Session: $FULL_SESSION_NAME"

# ============================================================================
# Step 2: Feature Description
# ============================================================================

print_section "🎯 Feature Description"

FEATURE_DESCRIPTION=$(ask_question "What feature or task would you like Ralph to implement?")
print_info "Feature: $FEATURE_DESCRIPTION"

HIGH_LEVEL_GOAL=$(ask_question "What's the high-level goal of this work?" "Implement $FEATURE_DESCRIPTION")

EXISTING_INTEGRATION=$(ask_question "Are there existing files or components this should integrate with? (optional)")

# ============================================================================
# Step 3: Validation Commands
# ============================================================================

print_section "✅ Validation Commands"

echo -e "${D}Ralph will run these commands after each task to ensure quality.${N}"
echo ""

VALIDATION_CMDS=()

if ask_yes_no "Run typecheck?"; then
  TYPECHECK_CMD=$(ask_question "Typecheck command:" "pnpm typecheck")
  VALIDATION_CMDS+=("typecheck:$TYPECHECK_CMD")
fi

if ask_yes_no "Run linter?"; then
  LINT_CMD=$(ask_question "Lint command:" "pnpm lint")
  VALIDATION_CMDS+=("lint:$LINT_CMD")
fi

if ask_yes_no "Run tests?"; then
  TEST_CMD=$(ask_question "Test command:" "pnpm test")
  VALIDATION_CMDS+=("test:$TEST_CMD")
fi

if ask_yes_no "Run build?"; then
  BUILD_CMD=$(ask_question "Build command:" "pnpm build")
  VALIDATION_CMDS+=("build:$BUILD_CMD")
fi

if [[ ${#VALIDATION_CMDS[@]} -eq 0 ]]; then
  print_info "No validation commands configured. Ralph will skip validation."
fi

# ============================================================================
# Step 4: Agent & Model Selection
# ============================================================================

print_section "🤖 Agent Selection"

echo -e "${D}Available agents:${N}"
echo "  - claude (default, well-integrated)"
echo "  - codex (OpenAI models)"
echo "  - opencode (provider flexibility)"
echo "  - cursor (Cursor-specific, requires model)"
echo ""

AGENT=$(ask_question "Which agent would you like to use?" "claude")

# Validate agent
case "$AGENT" in
  claude|codex|opencode|cursor) ;;
  *)
    print_error "Unknown agent: $AGENT. Defaulting to claude."
    AGENT="claude"
    ;;
esac

print_success "Agent: $AGENT"

MODEL=""
if [[ "$AGENT" == "cursor" ]]; then
  MODEL=$(ask_question "Model (required for cursor):" "claude-sonnet-4-20250514")
  if [[ -z "$MODEL" ]]; then
    print_error "Model is required for cursor agent"
    exit 1
  fi
else
  MODEL=$(ask_question "Model (optional, leave blank for default):")
fi

if [[ -n "$MODEL" ]]; then
  print_success "Model: $MODEL"
fi

# ============================================================================
# Step 5: Task Breakdown
# ============================================================================

print_section "📝 Task Breakdown"

echo -e "${D}Let's break down the feature into atomic tasks (5-15 minutes each).${N}"
echo ""

echo "Based on your description, I suggest these tasks:"
echo ""
echo "  1. [Main implementation task]"
echo "  2. [Add tests]"
echo "  3. [Update documentation]"
echo ""

if ! ask_yes_no "Would you like to define tasks manually?"; then
  # Use suggested breakdown
  TASKS=(
    "Implement $FEATURE_DESCRIPTION|File exists with basic structure|medium"
    "Add tests for $FEATURE_DESCRIPTION|Tests pass with good coverage|small"
    "Update documentation|README updated with new feature|small"
  )
else
  # Manual task entry
  TASKS=()
  TASK_NUM=1
  
  echo ""
  echo -e "${D}Enter tasks one by one. Press Enter with empty title to finish.${N}"
  echo ""
  
  while true; do
    TASK_TITLE=$(ask_question "Task $TASK_NUM title:")
    [[ -z "$TASK_TITLE" ]] && break
    
    echo "  Acceptance criteria (one per line, blank line when done):"
    TASK_CRITERIA=$(ask_multiline "  ")
    TASK_CRITERIA=$(echo "$TASK_CRITERIA" | paste -sd '|' -)
    
    TASK_COMPLEXITY=$(ask_question "  Complexity (small/medium/large):" "medium")
    
    TASKS+=("$TASK_TITLE|$TASK_CRITERIA|$TASK_COMPLEXITY")
    TASK_NUM=$((TASK_NUM + 1))
    echo ""
  done
fi

print_success "Defined ${#TASKS[@]} tasks"

# ============================================================================
# Step 6: Review
# ============================================================================

print_section "📋 Review"

cat << EOF
${BOLD}Session:${N} $FULL_SESSION_NAME
${BOLD}Feature:${N} $FEATURE_DESCRIPTION
${BOLD}Agent:${N} $AGENT
EOF

[[ -n "$MODEL" ]] && echo -e "${BOLD}Model:${N} $MODEL"
echo -e "${BOLD}Tasks:${N} ${#TASKS[@]}"
echo ""

if ! ask_yes_no "Does this look correct?"; then
  echo "Aborting. Please run the script again."
  exit 0
fi

# ============================================================================
# Step 7: Generate Session Files
# ============================================================================

print_section "🔨 Generating Session Files"

mkdir -p "$SESSION_DIR"

# Generate prd.json
cat > "$SESSION_DIR/prd.json" << EOF
{
  "branchName": "ralph/$SESSION_NAME",
  "agent": "$AGENT",
EOF

# Add model field if specified
if [[ -n "$MODEL" ]]; then
  cat >> "$SESSION_DIR/prd.json" << EOF
  "model": "$MODEL",
EOF
fi

# Add validation commands
cat >> "$SESSION_DIR/prd.json" << EOF
  "validationCommands": {
EOF

if [[ ${#VALIDATION_CMDS[@]} -gt 0 ]]; then
  for i in "${!VALIDATION_CMDS[@]}"; do
    IFS=':' read -r cmd_name cmd_value <<< "${VALIDATION_CMDS[$i]}"
    if [[ $i -eq $((${#VALIDATION_CMDS[@]} - 1)) ]]; then
      echo "    \"$cmd_name\": \"$cmd_value\"" >> "$SESSION_DIR/prd.json"
    else
      echo "    \"$cmd_name\": \"$cmd_value\"," >> "$SESSION_DIR/prd.json"
    fi
  done
fi

cat >> "$SESSION_DIR/prd.json" << EOF
  },
  "userStories": [
EOF

# Add tasks
for i in "${!TASKS[@]}"; do
  IFS='|' read -r title criteria complexity <<< "${TASKS[$i]}"
  
  # Escape title for JSON
  title=$(json_escape "$title")
  
  # Convert criteria to JSON array
  CRITERIA_JSON="["
  if [[ -n "$criteria" ]]; then
    IFS='|' read -ra CRITERIA_ARRAY <<< "$criteria"
    for j in "${!CRITERIA_ARRAY[@]}"; do
      escaped_criterion=$(json_escape "${CRITERIA_ARRAY[$j]}")
      CRITERIA_JSON+="\"$escaped_criterion\""
      [[ $j -lt $((${#CRITERIA_ARRAY[@]} - 1)) ]] && CRITERIA_JSON+=", "
    done
  fi
  CRITERIA_JSON+="]"
  
  TASK_ID=$(printf "TASK-%03d" $((i + 1)))
  
  cat >> "$SESSION_DIR/prd.json" << EOF
    {
      "id": "$TASK_ID",
      "title": "$title",
      "acceptanceCriteria": $CRITERIA_JSON,
      "priority": $((i + 1)),
      "complexity": "$complexity",
      "passes": false
    }
EOF
  
  [[ $i -lt $((${#TASKS[@]} - 1)) ]] && echo "," >> "$SESSION_DIR/prd.json"
done

cat >> "$SESSION_DIR/prd.json" << EOF

  ]
}
EOF

print_success "Created prd.json"

# Generate progress.txt
cat > "$SESSION_DIR/progress.txt" << EOF
# Ralph Progress Log

Session: $FULL_SESSION_NAME
Feature: $FEATURE_DESCRIPTION
Goal: $HIGH_LEVEL_GOAL
Branch: ralph/$SESSION_NAME
Created: $(date)

---

## Codebase Patterns

(Ralph will discover patterns here during execution)

---
EOF

print_success "Created progress.txt"

# Generate learnings.md
cat > "$SESSION_DIR/learnings.md" << EOF
# Learnings: $FULL_SESSION_NAME

Session: $FULL_SESSION_NAME
Feature: $FEATURE_DESCRIPTION
Branch: ralph/$SESSION_NAME
Created: $(date)

---

(Ralph will append learnings here after each completed task)
EOF

print_success "Created learnings.md"

# ============================================================================
# Step 8: Next Steps
# ============================================================================

print_header "✅ SESSION CREATED"

cat << EOF
${G}Session files created successfully!${N}

${BOLD}Location:${N} $SESSION_DIR

${BOLD}Files:${N}
  📝 prd.json      - Task definitions
  📋 progress.txt  - Codebase patterns
  📚 learnings.md  - Accumulated learnings

${BOLD}Next steps:${N}

  ${C}# Start Ralph${N}
  $SCRIPT_DIR/ralph.sh 25 --session $FULL_SESSION_NAME

  ${C}# Monitor progress${N}
  tail -f $SESSION_DIR/ralph.log

  ${C}# Check status${N}
  $SCRIPT_DIR/status.sh

  ${C}# View learnings${N}
  cat $SESSION_DIR/learnings.md

${BOLD}Tips:${N}
  - Ralph runs autonomously, implementing tasks one by one
  - Each task is validated before committing
  - Progress is saved in real-time
  - You can stop with: $SCRIPT_DIR/stop.sh

${G}Happy coding! 🚀${N}

EOF
