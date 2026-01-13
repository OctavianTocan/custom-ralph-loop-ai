#!/bin/bash
# Tests for resume context prompt injection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH="$PROJECT_ROOT/ralph.sh"

# shellcheck source=tests/test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

test_start "script captures last iteration log for resume context"
grep -q "LAST_ITERATION_CONTEXT" "$RALPH"
assert_success
grep -q "LAST_ITERATION_LINE=" "$RALPH"
assert_success
test_pass

test_start "resume context is appended to the prompt"
grep -q "Recent Ralph Iteration (resume context)" "$RALPH"
assert_success
test_pass

test_start "resume context tail limits size"
grep -q 'tail -n +"$LAST_ITERATION_LINE"' "$RALPH"
assert_success
grep -q 'tail -n 200' "$RALPH"
assert_success
test_pass
