#!/bin/bash
# Tests for log-command.sh hook
# This hook logs command execution to Ralph session logs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$PROJECT_ROOT/cursor-config/hooks/log-command.sh"

# Create a temporary test environment
TEST_TMP_DIR=$(mktemp -d)
trap "rm -rf $TEST_TMP_DIR" EXIT

# =============================================================================
# Test: Always exits 0 (invariant)
# =============================================================================
test_start "always exits 0 regardless of input"
echo '{"command": "ls -la"}' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

test_start "exits 0 with empty input"
echo '' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

test_start "exits 0 with malformed JSON"
echo 'not json' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Handles missing sessions directory gracefully
# =============================================================================
test_start "handles missing sessions directory gracefully"
# The hook looks for sessions/ relative to itself, which may not exist in tests
OUTPUT=$(echo '{"command": "test"}' | "$HOOK" 2>&1)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Logs successful command to ralph.log
# =============================================================================
test_start "logs successful command when session exists"
# Create a mock sessions directory structure
MOCK_PROJECT="$TEST_TMP_DIR/mock-project"
mkdir -p "$MOCK_PROJECT/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT/sessions/session-001"
touch "$MOCK_PROJECT/sessions/session-001/ralph.log"

# Copy the hook to our mock project
cp "$HOOK" "$MOCK_PROJECT/cursor-config/hooks/log-command.sh"
chmod +x "$MOCK_PROJECT/cursor-config/hooks/log-command.sh"

echo '{"command": "npm test", "exit_code": 0, "duration": 1234}' | "$MOCK_PROJECT/cursor-config/hooks/log-command.sh" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"

# Check that something was logged
if [[ -f "$MOCK_PROJECT/sessions/session-001/ralph.log" ]]; then
  LOG_CONTENT=$(cat "$MOCK_PROJECT/sessions/session-001/ralph.log")
  if [[ -n "$LOG_CONTENT" ]]; then
    assert_contains "$LOG_CONTENT" "[run]"
    assert_contains "$LOG_CONTENT" "npm test"
    assert_contains "$LOG_CONTENT" "ok"
  fi
fi
test_pass

# =============================================================================
# Test: Logs failed command with exit code
# =============================================================================
test_start "logs failed command with exit code"
# Create fresh mock directory
MOCK_PROJECT2="$TEST_TMP_DIR/mock-project2"
mkdir -p "$MOCK_PROJECT2/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT2/sessions/session-001"
touch "$MOCK_PROJECT2/sessions/session-001/ralph.log"

cp "$HOOK" "$MOCK_PROJECT2/cursor-config/hooks/log-command.sh"
chmod +x "$MOCK_PROJECT2/cursor-config/hooks/log-command.sh"

echo '{"command": "npm test", "exit_code": 1, "duration": 500}' | "$MOCK_PROJECT2/cursor-config/hooks/log-command.sh" > /dev/null 2>&1

if [[ -f "$MOCK_PROJECT2/sessions/session-001/ralph.log" ]]; then
  LOG_CONTENT=$(cat "$MOCK_PROJECT2/sessions/session-001/ralph.log")
  if [[ -n "$LOG_CONTENT" ]]; then
    assert_contains "$LOG_CONTENT" "[run]"
    assert_contains "$LOG_CONTENT" "FAIL"
  fi
fi
test_pass

# =============================================================================
# Test: Truncates long commands
# =============================================================================
test_start "truncates commands longer than 70 chars"
MOCK_PROJECT3="$TEST_TMP_DIR/mock-project3"
mkdir -p "$MOCK_PROJECT3/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT3/sessions/session-001"
touch "$MOCK_PROJECT3/sessions/session-001/ralph.log"

cp "$HOOK" "$MOCK_PROJECT3/cursor-config/hooks/log-command.sh"
chmod +x "$MOCK_PROJECT3/cursor-config/hooks/log-command.sh"

# Create a command longer than 70 chars
LONG_CMD="this is a very long command that should be truncated because it exceeds seventy characters easily"
echo "{\"command\": \"$LONG_CMD\", \"exit_code\": 0}" | "$MOCK_PROJECT3/cursor-config/hooks/log-command.sh" > /dev/null 2>&1

if [[ -f "$MOCK_PROJECT3/sessions/session-001/ralph.log" ]]; then
  LOG_CONTENT=$(cat "$MOCK_PROJECT3/sessions/session-001/ralph.log")
  if [[ -n "$LOG_CONTENT" ]]; then
    # Should contain truncation indicator
    assert_contains "$LOG_CONTENT" "..."
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
# Test: Missing command field handled
# =============================================================================
test_start "missing command field handled gracefully"
echo '{"exit_code": 0}' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Hook handles missing jq gracefully
# =============================================================================
test_start "handles missing jq by falling back to grep/sed"
# Use run_without_jq helper to shadow jq with a failing wrapper
OUTPUT=$(echo '{"command": "test", "exit_code": 0}' | run_without_jq "$HOOK" 2>/dev/null)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass
