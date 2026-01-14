#!/bin/bash
# Tests for ralph.sh --help and --version flags
# Validates that flags work correctly and show expected information

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH_SCRIPT="$PROJECT_ROOT/ralph.sh"

# Source test helpers
source "$SCRIPT_DIR/test-helpers.sh"

# =============================================================================
# Test: --version flag
# =============================================================================
test_start "--version outputs version in correct format"
OUTPUT=$("$RALPH_SCRIPT" --version 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_contains "$OUTPUT" "ralph-ai-coding-loop"
test_pass

# =============================================================================
# Test: -v short flag
# =============================================================================
test_start "-v outputs same as --version"
VERSION_OUTPUT=$("$RALPH_SCRIPT" --version 2>&1)
SHORT_OUTPUT=$("$RALPH_SCRIPT" -v 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_equals "$VERSION_OUTPUT" "$SHORT_OUTPUT"
test_pass

# =============================================================================
# Test: --help flag
# =============================================================================
test_start "--help outputs usage information"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_contains "$OUTPUT" "Usage:"
assert_contains "$OUTPUT" "Options:"
assert_contains "$OUTPUT" "Examples:"
test_pass

# =============================================================================
# Test: -h short flag
# =============================================================================
test_start "-h outputs same as --help"
HELP_OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
SHORT_OUTPUT=$("$RALPH_SCRIPT" -h 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_equals "$HELP_OUTPUT" "$SHORT_OUTPUT"
test_pass

# =============================================================================
# Test: --help mentions sessions
# =============================================================================
test_start "--help mentions 'sessions' in output"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
assert_contains "$OUTPUT" "session"
test_pass

# =============================================================================
# Test: --help lists available sessions
# =============================================================================
test_start "--help lists available sessions from sessions/ directory"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
# Should contain "Available sessions:" or similar section
assert_contains "$OUTPUT" "sessions"
test_pass

# =============================================================================
# Test: --help shows --session option
# =============================================================================
test_start "--help documents --session option"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
assert_contains "$OUTPUT" "--session"
test_pass

# =============================================================================
# Test: --help shows --force option
# =============================================================================
test_start "--help documents --force option"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
assert_contains "$OUTPUT" "--force"
test_pass

# =============================================================================
# Test: --help shows --workflow option
# =============================================================================
test_start "--help documents --workflow option"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
assert_contains "$OUTPUT" "--workflow"
test_pass

# =============================================================================
# Test: --help shows --list-agents option
# =============================================================================
test_start "--help documents --list-agents option"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
assert_contains "$OUTPUT" "--list-agents"
test_pass

# =============================================================================
# Test: --help shows --help option
# =============================================================================
test_start "--help documents --help option"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
assert_contains "$OUTPUT" "--help"
test_pass

# =============================================================================
# Test: --help shows --version option
# =============================================================================
test_start "--help documents --version option"
OUTPUT=$("$RALPH_SCRIPT" --help 2>&1)
assert_contains "$OUTPUT" "--version"
test_pass

# =============================================================================
# Test: Flags exit immediately (don't start session)
# =============================================================================
test_start "--version exits immediately without starting session"
# Should complete instantly (< 1 second)
START_TIME=$(date +%s)
"$RALPH_SCRIPT" --version > /dev/null 2>&1
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [[ $DURATION -gt 2 ]]; then
  echo -e "${RED}FAIL${NC}"
  echo "    Version check took ${DURATION}s (expected < 2s)"
  TEST_FAILED=1
  ((FAILED_TESTS++)) || true
else
  test_pass
fi

test_start "--list-agents exits immediately"
START_TIME=$(date +%s)
"$RALPH_SCRIPT" --list-agents > /dev/null 2>&1
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [[ $DURATION -gt 2 ]]; then
  echo -e "${RED}FAIL${NC}"
  echo "    Agent listing took ${DURATION}s (expected < 2s)"
  TEST_FAILED=1
  ((FAILED_TESTS++)) || true
else
  test_pass
fi
test_start "--help exits immediately without starting session"
START_TIME=$(date +%s)
"$RALPH_SCRIPT" --help > /dev/null 2>&1
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [[ $DURATION -gt 2 ]]; then
  echo -e "${RED}FAIL${NC}"
  echo "    Help check took ${DURATION}s (expected < 2s)"
  TEST_FAILED=1
  ((FAILED_TESTS++)) || true
else
  test_pass
fi
