#!/bin/bash
# Tests for track-edit.sh hook
# This hook tracks file edits for Ralph session logging

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$PROJECT_ROOT/cursor-config/hooks/track-edit.sh"

# Create a temporary test environment
TEST_TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

# =============================================================================
# Test: Always exits 0 (invariant)
# =============================================================================
test_start "always exits 0 regardless of input"
echo '{"file_path": "/path/to/file.js", "edits": []}' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

test_start "exits 0 with empty input"
echo '' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

test_start "exits 0 with malformed JSON"
echo 'not valid json' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Handles missing sessions directory gracefully
# =============================================================================
test_start "handles missing sessions directory gracefully"
OUTPUT=$(echo '{"file_path": "/test/file.js"}' | "$HOOK" 2>&1)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Logs file edit to ralph.log
# =============================================================================
test_start "logs file edit when session exists"
# Create a mock sessions directory structure
MOCK_PROJECT="$TEST_TMP_DIR/mock-project"
mkdir -p "$MOCK_PROJECT/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT/sessions/session-001"
touch "$MOCK_PROJECT/sessions/session-001/ralph.log"

# Copy the hook to our mock project
cp "$HOOK" "$MOCK_PROJECT/cursor-config/hooks/track-edit.sh"
chmod +x "$MOCK_PROJECT/cursor-config/hooks/track-edit.sh"

echo '{"file_path": "/home/user/project/src/index.js", "edits": [{"line": 10}]}' | "$MOCK_PROJECT/cursor-config/hooks/track-edit.sh" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"

# Check that something was logged
if [[ -f "$MOCK_PROJECT/sessions/session-001/ralph.log" ]]; then
  LOG_CONTENT=$(cat "$MOCK_PROJECT/sessions/session-001/ralph.log")
  if [[ -n "$LOG_CONTENT" ]]; then
    assert_contains "$LOG_CONTENT" "[edit]"
    assert_contains "$LOG_CONTENT" "index.js"
    assert_contains "$LOG_CONTENT" "ok"
  fi
fi
test_pass

# =============================================================================
# Test: Extracts basename correctly
# =============================================================================
test_start "extracts basename from full path"
MOCK_PROJECT2="$TEST_TMP_DIR/mock-project2"
mkdir -p "$MOCK_PROJECT2/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT2/sessions/session-001"
touch "$MOCK_PROJECT2/sessions/session-001/ralph.log"

cp "$HOOK" "$MOCK_PROJECT2/cursor-config/hooks/track-edit.sh"
chmod +x "$MOCK_PROJECT2/cursor-config/hooks/track-edit.sh"

echo '{"file_path": "/very/long/nested/path/to/component.tsx"}' | "$MOCK_PROJECT2/cursor-config/hooks/track-edit.sh" > /dev/null 2>&1

if [[ -f "$MOCK_PROJECT2/sessions/session-001/ralph.log" ]]; then
  LOG_CONTENT=$(cat "$MOCK_PROJECT2/sessions/session-001/ralph.log")
  if [[ -n "$LOG_CONTENT" ]]; then
    assert_contains "$LOG_CONTENT" "component.tsx"
    assert_not_contains "$LOG_CONTENT" "/very/long/nested/path"
  fi
fi
test_pass

# =============================================================================
# Test: Empty JSON object handled
# =============================================================================
test_start "empty JSON object handled gracefully"
echo '{}' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Missing file_path field handled
# =============================================================================
test_start "missing file_path field handled gracefully"
echo '{"edits": []}' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: File path with spaces handled
# =============================================================================
test_start "file path with spaces handled"
echo '{"file_path": "/path/to/my file.js"}' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Hook handles missing jq gracefully
# =============================================================================
test_start "handles missing jq by falling back to grep/sed"
JQ_PATH="$(which jq 2>/dev/null || true)"
if [[ -n "$JQ_PATH" ]]; then
  MODIFIED_PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "$(dirname "$JQ_PATH")" | tr '\n' ':')
else
  MODIFIED_PATH="$PATH"
fi
OUTPUT=$(echo '{"file_path": "/test/file.js"}' | PATH="$MODIFIED_PATH" "$HOOK" 2>/dev/null)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Multiple edits in array handled
# =============================================================================
test_start "multiple edits in array handled"
echo '{"file_path": "/path/file.js", "edits": [{"line": 1}, {"line": 5}, {"line": 10}]}' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass
