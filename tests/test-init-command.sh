#!/bin/bash
# Tests for ./ralph.sh init command
# Tests session directory and file creation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH="$PROJECT_ROOT/ralph.sh"

# Source test helpers
# shellcheck source=tests/test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

# Create a temporary test environment
TEST_TMP_DIR=$(mktemp -d)
trap "rm -rf $TEST_TMP_DIR" EXIT

# Change to temp directory for testing
cd "$TEST_TMP_DIR" || exit 1

# Copy ralph.sh to temp directory
cp "$RALPH" ./ralph.sh
mkdir -p sessions

# =============================================================================
# Test: init creates session directory
# =============================================================================
test_start "init creates sessions/my-feature/ directory"
./ralph.sh init my-feature > /dev/null 2>&1
assert_dir_exists "sessions/my-feature"
test_pass

# =============================================================================
# Test: init creates prd.json with valid JSON
# =============================================================================
test_start "init creates prd.json with valid JSON"
PRD_CONTENT=$(cat sessions/my-feature/prd.json)
assert_valid_json "$PRD_CONTENT"
test_pass

# =============================================================================
# Test: prd.json contains required fields
# =============================================================================
test_start "prd.json contains branchName field"
assert_contains "$PRD_CONTENT" '"branchName"'
test_pass

test_start "prd.json contains agent field"
assert_contains "$PRD_CONTENT" '"agent"'
test_pass

test_start "prd.json contains model field"
assert_contains "$PRD_CONTENT" '"model"'
test_pass

test_start "prd.json contains validationCommands field"
assert_contains "$PRD_CONTENT" '"validationCommands"'
test_pass

test_start "prd.json contains userStories field"
assert_contains "$PRD_CONTENT" '"userStories"'
test_pass

# =============================================================================
# Test: prd.json branchName defaults to ralph/<name>
# =============================================================================
test_start "prd.json branchName defaults to 'ralph/my-feature'"
if command -v jq &> /dev/null; then
  BRANCH_NAME=$(echo "$PRD_CONTENT" | jq -r '.branchName')
  assert_equals "ralph/my-feature" "$BRANCH_NAME"
else
  # Fallback without jq
  assert_contains "$PRD_CONTENT" '"branchName": "ralph/my-feature"'
fi
test_pass

# =============================================================================
# Test: init creates progress.txt with header
# =============================================================================
test_start "init creates progress.txt with header"
assert_file_exists "sessions/my-feature/progress.txt"
PROGRESS_CONTENT=$(cat sessions/my-feature/progress.txt)
assert_contains "$PROGRESS_CONTENT" "Session:"
test_pass

# =============================================================================
# Test: init creates learnings.md with header
# =============================================================================
test_start "init creates learnings.md with header"
assert_file_exists "sessions/my-feature/learnings.md"
LEARNINGS_CONTENT=$(cat sessions/my-feature/learnings.md)
assert_contains "$LEARNINGS_CONTENT" "Learnings:"
test_pass

# =============================================================================
# Test: Running init twice on same name shows error
# =============================================================================
test_start "running init twice on same name shows error"
OUTPUT=$(./ralph.sh init my-feature 2>&1 || true)
assert_contains "$OUTPUT" "exists"
test_pass

# =============================================================================
# Test: init shows success message with next steps
# =============================================================================
test_start "init shows success message"
rm -rf sessions/another-feature
OUTPUT=$(./ralph.sh init another-feature 2>&1)
assert_contains "$OUTPUT" "Session created"
assert_contains "$OUTPUT" "another-feature"
test_pass

# =============================================================================
# Test: init with different name creates new session
# =============================================================================
test_start "init creates different session directory"
assert_dir_exists "sessions/another-feature"
assert_file_exists "sessions/another-feature/prd.json"
test_pass

# =============================================================================
# Test: prd.json agent defaults to claude
# =============================================================================
test_start "prd.json agent defaults to 'claude'"
PRD2_CONTENT=$(cat sessions/another-feature/prd.json)
if command -v jq &> /dev/null; then
  AGENT=$(echo "$PRD2_CONTENT" | jq -r '.agent')
  assert_equals "claude" "$AGENT"
else
  # Fallback without jq
  assert_contains "$PRD2_CONTENT" '"agent": "claude"'
fi
test_pass

# =============================================================================
# Test: prd.json model defaults to sonnet
# =============================================================================
test_start "prd.json model defaults to 'sonnet'"
if command -v jq &> /dev/null; then
  MODEL=$(echo "$PRD2_CONTENT" | jq -r '.model')
  assert_equals "sonnet" "$MODEL"
else
  # Fallback without jq
  assert_contains "$PRD2_CONTENT" '"model": "sonnet"'
fi
test_pass

# =============================================================================
# Test: prd.json has placeholder userStory
# =============================================================================
test_start "prd.json contains placeholder userStory"
assert_contains "$PRD2_CONTENT" '"id"'
assert_contains "$PRD2_CONTENT" '"title"'
assert_contains "$PRD2_CONTENT" '"acceptanceCriteria"'
assert_contains "$PRD2_CONTENT" '"priority"'
assert_contains "$PRD2_CONTENT" '"passes"'
test_pass
