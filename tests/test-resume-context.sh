#!/bin/bash
# Tests for resume context prompt injection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH="$PROJECT_ROOT/ralph.sh"

# shellcheck source=tests/test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

SCRIPT_CONTENT=$(cat "$RALPH")

test_start "script captures last iteration log for resume context"
assert_contains "$SCRIPT_CONTENT" "LAST_ITERATION_CONTEXT"
assert_contains "$SCRIPT_CONTENT" "LAST_ITERATION_LINE="
test_pass

test_start "resume context is appended to the prompt"
assert_contains "$SCRIPT_CONTENT" "Recent Ralph Iteration (resume context)"
test_pass

test_start "resume context tail limits size"
assert_contains "$SCRIPT_CONTENT" 'tail -n +"$LAST_ITERATION_LINE"'
assert_contains "$SCRIPT_CONTENT" 'tail -n 200'
test_pass
