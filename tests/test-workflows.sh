#!/bin/bash
# Tests for workflow functionality in ralph.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(dirname "$SCRIPT_DIR")"

# Source test helpers
source "$SCRIPT_DIR/test-helpers.sh"

# Setup: Create temporary session directory
setup_test_session() {
  local session_name="$1"
  local session_dir="$RALPH_DIR/sessions/$session_name"
  mkdir -p "$session_dir"
  echo "$session_dir"
}

# Teardown: Remove test session
teardown_test_session() {
  local session_name="$1"
  rm -rf "$RALPH_DIR/sessions/$session_name"
}

# Test 1: Workflow flag is parsed correctly
test_start "workflow flag parsing"
output=$("$RALPH_DIR/ralph.sh" 1 --workflow test-coverage 2>&1 || true)
# Should fail because no session, but should not complain about workflow parsing
assert_not_contains "$output" "invalid option" "Should not report invalid option for --workflow"
test_pass

# Test 2: Invalid workflow shows clear error
test_start "invalid workflow error message"
output=$("$RALPH_DIR/ralph.sh" 1 --workflow nonexistent-workflow 2>&1 || true)
assert_contains "$output" "ERROR: Workflow prompt not found" "Should show workflow not found error"
assert_contains "$output" "Available workflows:" "Should list available workflows"
test_pass

# Test 3: Valid workflow file exists
test_start "test-coverage workflow exists"
assert_file_exists "$RALPH_DIR/workflows/test-coverage/prompt.md" "test-coverage workflow prompt should exist"
test_pass

# Test 4: Workflow prompt is valid markdown
test_start "test-coverage prompt is valid"
prompt_content=$(cat "$RALPH_DIR/workflows/test-coverage/prompt.md")
assert_contains "$prompt_content" "Test Coverage Workflow" "Prompt should have title"
assert_contains "$prompt_content" "one meaningful test" "Prompt should enforce one test per iteration"
assert_contains "$prompt_content" "coverageTarget" "Prompt should reference coverage target"
test_pass

# Test 5: PRD template example exists and is valid JSON
test_start "test-coverage PRD example exists and valid"
assert_file_exists "$RALPH_DIR/examples/prd.test-coverage.example" "PRD example should exist"
prd_content=$(cat "$RALPH_DIR/examples/prd.test-coverage.example")
assert_valid_json "$prd_content" "PRD example should be valid JSON"
test_pass

# Test 6: PRD template has required workflow fields
test_start "PRD template has workflow fields"
if command -v jq &> /dev/null; then
  prd_content=$(cat "$RALPH_DIR/examples/prd.test-coverage.example")
  workflow=$(echo "$prd_content" | jq -r '.workflow')
  coverage_cmd=$(echo "$prd_content" | jq -r '.coverageCommand')
  coverage_target=$(echo "$prd_content" | jq -r '.coverageTarget')
  
  assert_equals "test-coverage" "$workflow" "Workflow field should be test-coverage"
  assert_contains "$coverage_cmd" "test" "Coverage command should contain 'test'"
  assert_contains "$coverage_target" "85" "Coverage target should be specified"
else
  test_skip "jq not available"
fi
test_pass

# Test 7: Workflow from prd.json is read correctly
test_start "workflow read from prd.json"
session_dir=$(setup_test_session "test-workflow-read")
cat > "$session_dir/prd.json" << 'EOF'
{
  "branchName": "test/workflow",
  "workflow": "test-coverage",
  "agent": "claude",
  "validationCommands": {},
  "userStories": []
}
EOF

# Run ralph.sh with this session (will fail early but should parse workflow)
output=$(cd "$RALPH_DIR" && timeout 2 ./ralph.sh 1 --session test-workflow-read 2>&1 || true)

# Should not show workflow error since it's valid
assert_not_contains "$output" "ERROR: Workflow prompt not found" "Should not error on valid workflow in prd.json"

teardown_test_session "test-workflow-read"
test_pass

# Test 8: CLI workflow flag overrides prd.json workflow
test_start "CLI workflow overrides prd.json"
session_dir=$(setup_test_session "test-workflow-override")
cat > "$session_dir/prd.json" << 'EOF'
{
  "branchName": "test/override",
  "workflow": "test-coverage",
  "agent": "claude",
  "validationCommands": {},
  "userStories": []
}
EOF

# Use a nonexistent workflow via CLI - should override and show error
output=$(cd "$RALPH_DIR" && ./ralph.sh 1 --session test-workflow-override --workflow nonexistent 2>&1 || true)
assert_contains "$output" "ERROR: Workflow prompt not found: nonexistent" "CLI workflow should override prd.json"

teardown_test_session "test-workflow-override"
test_pass

# Test 9: No workflow specified works normally
test_start "no workflow specified (normal mode)"
session_dir=$(setup_test_session "test-no-workflow")
cat > "$session_dir/prd.json" << 'EOF'
{
  "branchName": "test/no-workflow",
  "agent": "claude",
  "validationCommands": {},
  "userStories": []
}
EOF

# Run without workflow - should work (will fail on other validation but not workflow-related)
output=$(cd "$RALPH_DIR" && timeout 2 ./ralph.sh 1 --session test-no-workflow 2>&1 || true)
assert_not_contains "$output" "ERROR: Workflow prompt not found" "Should not error when no workflow specified"

teardown_test_session "test-no-workflow"
test_pass

# Test 10: Workflow directory structure is correct
test_start "workflows directory structure"
assert_dir_exists "$RALPH_DIR/workflows" "workflows directory should exist"
assert_dir_exists "$RALPH_DIR/workflows/test-coverage" "test-coverage directory should exist"
test_pass

# Test 11: prompt.md allows test: commits
test_start "base prompt allows test: commits"
prompt_content=$(cat "$RALPH_DIR/prompt.md")
assert_contains "$prompt_content" "test:" "Base prompt should mention test: commits"
test_pass

# Test 12: Commands directory has updated setup
test_start "setup command supports workflows"
setup_content=$(cat "$RALPH_DIR/commands/ralph:setup.md")
assert_contains "$setup_content" "workflow" "Setup command should mention workflows"
assert_contains "$setup_content" "test-coverage" "Setup command should reference test-coverage workflow"
test_pass

# Test 13: ralph/commands exists for distribution
test_start "ralph/commands directory exists"
assert_dir_exists "$RALPH_DIR/ralph/commands" "ralph/commands should exist for distribution"
test_pass

echo ""
echo "Workflow tests completed"
