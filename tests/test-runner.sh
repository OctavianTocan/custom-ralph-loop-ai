#!/bin/bash
# Simple bash test runner for Ralph Cursor hooks
# Usage: ./tests/test-runner.sh [test-file.sh]
#
# If no test file specified, runs all test-*.sh files in tests/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize counters
export TOTAL_TESTS=0
export PASSED_TESTS=0
export FAILED_TESTS=0
export SKIPPED_TESTS=0

# Source test helper functions
source "$SCRIPT_DIR/test-helpers.sh"

# Run a test file
run_test_file() {
  local test_file="$1"
  local test_name=$(basename "$test_file" .sh)

  echo ""
  echo -e "${CYAN}Running: $test_name${NC}"
  echo "  ──────────────────────────────────────"

  # Source the test file to run its tests
  # shellcheck source=/dev/null
  source "$test_file"
}

# Main
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${BOLD}Ralph Cursor Hooks Test Suite${NC}              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════╝${NC}"

if [[ -n "$1" ]]; then
  # Run specific test file
  if [[ -f "$1" ]]; then
    run_test_file "$1"
  elif [[ -f "$SCRIPT_DIR/$1" ]]; then
    run_test_file "$SCRIPT_DIR/$1"
  else
    echo -e "${RED}Error: Test file not found: $1${NC}"
    exit 1
  fi
else
  # Run all test files
  for test_file in "$SCRIPT_DIR"/test-*.sh; do
    if [[ -f "$test_file" && "$(basename "$test_file")" != "test-runner.sh" && "$(basename "$test_file")" != "test-helpers.sh" ]]; then
      run_test_file "$test_file"
    fi
  done
fi

# Summary
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Test Summary:${NC}"
echo -e "  Total:   $TOTAL_TESTS"
echo -e "  ${GREEN}Passed:  $PASSED_TESTS${NC}"
if [[ $FAILED_TESTS -gt 0 ]]; then
  echo -e "  ${RED}Failed:  $FAILED_TESTS${NC}"
fi
if [[ $SKIPPED_TESTS -gt 0 ]]; then
  echo -e "  ${YELLOW}Skipped: $SKIPPED_TESTS${NC}"
fi
echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Exit with failure if any tests failed
if [[ $FAILED_TESTS -gt 0 ]]; then
  exit 1
fi

exit 0
