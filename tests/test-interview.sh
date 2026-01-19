#!/bin/bash

# Test ralph-interview.sh functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "Testing ralph-interview.sh"
echo "================================"

# Test 1: Check script exists and is executable
test_start "Script exists and is executable"
assert_file_exists "$SCRIPT_DIR/../ralph-interview.sh"
assert_file_executable "$SCRIPT_DIR/../ralph-interview.sh"
test_pass

# Test 2: Check script has proper shebang
test_start "Script has proper shebang"
FIRST_LINE=$(head -n1 "$SCRIPT_DIR/../ralph-interview.sh")
assert_equals "#!/bin/bash" "$FIRST_LINE"
test_pass

# Test 3: Check helper functions exist
test_start "Helper functions are defined"
grep -q "^print_header()" "$SCRIPT_DIR/../ralph-interview.sh"
assert_success
grep -q "^print_section()" "$SCRIPT_DIR/../ralph-interview.sh"
assert_success
grep -q "^ask_question()" "$SCRIPT_DIR/../ralph-interview.sh"
assert_success
test_pass

# Test 4: Check script syntax is valid
test_start "Script syntax is valid"
bash -n "$SCRIPT_DIR/../ralph-interview.sh" 2>/dev/null
assert_success
test_pass

# Test 5: Verify command file exists
test_start "Command file exists"
assert_file_exists "$SCRIPT_DIR/../commands/ralph:interview.md"
test_pass

# Test 6: Check command file in ralph directory
test_start "Ralph directory has command file"
assert_file_exists "$SCRIPT_DIR/../ralph/commands/ralph:interview.md"
test_pass

# Test 7: Verify command file has required sections
test_start "Command file has required sections"
COMMAND_FILE="$SCRIPT_DIR/../commands/ralph:interview.md"
grep -q "Interview Flow" "$COMMAND_FILE"
assert_success
grep -q "Interview Guidelines" "$COMMAND_FILE"
assert_success
grep -q "PRD Generation" "$COMMAND_FILE"
assert_success
test_pass

# Test 8: Check documentation updates
test_start "README.md mentions interview feature"
grep -q "ralph-interview\|/ralph:interview" "$SCRIPT_DIR/../README.md"
assert_success
test_pass

test_start "USAGE.md mentions interview feature"
grep -q "ralph-interview\|/ralph:interview" "$SCRIPT_DIR/../docs/USAGE.md"
assert_success
test_pass

# Test 9: Verify script creates proper directory structure
test_start "Script variables reference correct paths"
grep -q "SESSION_DIR=.*sessions/" "$SCRIPT_DIR/../ralph-interview.sh"
assert_success
test_pass

# Test 10: Check JSON generation logic
test_start "Script includes JSON generation"
grep -q "prd.json" "$SCRIPT_DIR/../ralph-interview.sh"
assert_success
test_pass

# Summary
echo ""
echo "================================"
echo "Test Summary:"
echo "  Total:   $TOTAL_TESTS"
echo "  Passed:  $PASSED_TESTS"
echo "  Failed:  $FAILED_TESTS"
echo "  Skipped: $SKIPPED_TESTS"

if [[ $FAILED_TESTS -eq 0 ]]; then
  echo "All tests passed! ✓"
  exit 0
else
  echo "Some tests failed! ✗"
  exit 1
fi
