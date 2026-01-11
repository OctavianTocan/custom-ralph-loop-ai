#!/bin/bash
# Test helper functions for Ralph Cursor hooks tests
# This file is sourced by individual test files

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Global test state (read/write by runner and test files)
: "${TOTAL_TESTS:=0}"
: "${PASSED_TESTS:=0}"
: "${FAILED_TESTS:=0}"
: "${SKIPPED_TESTS:=0}"

# Current test state
CURRENT_TEST=""
TEST_FAILED=0

# Begin a test
test_start() {
  CURRENT_TEST="$1"
  TEST_FAILED=0
  ((TOTAL_TESTS++)) || true
  echo -n "  Testing: $CURRENT_TEST ... "
}

# Assert that last command succeeded
assert_success() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    Expected success, got exit code $exit_code"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Assert that last command failed
assert_failure() {
  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    Expected failure, got success"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Assert string equality
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected '$expected' but got '$actual'}"

  if [[ "$expected" != "$actual" ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    $message"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Assert string contains substring
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Expected to contain '$needle'}"

  if [[ "$haystack" != *"$needle"* ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    $message"
    echo "    Actual: $haystack"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Assert string does not contain substring
assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Expected NOT to contain '$needle'}"

  if [[ "$haystack" == *"$needle"* ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    $message"
    echo "    Actual: $haystack"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Assert file exists
assert_file_exists() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    Expected file to exist: $file"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Assert file is executable
assert_file_executable() {
  local file="$1"
  if [[ ! -x "$file" ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    Expected file to be executable: $file"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Assert directory exists
assert_dir_exists() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    Expected directory to exist: $dir"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Assert JSON is valid
assert_valid_json() {
  local json="$1"
  if command -v jq &> /dev/null; then
    if ! echo "$json" | jq . &> /dev/null; then
      echo -e "${RED}FAIL${NC}"
      echo "    Expected valid JSON, got: $json"
      TEST_FAILED=1
      ((FAILED_TESTS++)) || true
      return 1
    fi
  else
    # Basic JSON validation without jq
    if [[ ! "$json" =~ ^\{.*\}$ ]]; then
      echo -e "${RED}FAIL${NC}"
      echo "    Expected valid JSON object, got: $json"
      TEST_FAILED=1
      ((FAILED_TESTS++)) || true
      return 1
    fi
  fi
}

# Assert exit code equals expected
assert_exit_code() {
  local expected="$1"
  local actual="$2"
  if [[ "$expected" != "$actual" ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "    Expected exit code $expected, got $actual"
    TEST_FAILED=1
    ((FAILED_TESTS++)) || true
    return 1
  fi
}

# Mark test as passed (call at end of successful test)
test_pass() {
  if [[ $TEST_FAILED -eq 0 ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED_TESTS++)) || true
  fi
}

# Skip a test
test_skip() {
  local reason="${1:-No reason given}"
  echo -e "${YELLOW}SKIP${NC} ($reason)"
  ((SKIPPED_TESTS++)) || true
  ((TOTAL_TESTS--)) || true
}
