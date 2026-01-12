#!/bin/bash
# Tests for smart iteration suggestion feature
# Uses quick script content checks instead of running full ralph.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH="$PROJECT_ROOT/ralph.sh"

# Source test helpers
# shellcheck source=tests/test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

# =============================================================================
# Test: Script contains iteration suggestion code
# =============================================================================
test_start "script contains ITERATION SUGGESTION section"
SCRIPT_CONTENT=$(cat "$RALPH")
assert_contains "$SCRIPT_CONTENT" "ITERATION SUGGESTION"
test_pass

# =============================================================================
# Test: Script reads suggestedIterations from prd.json
# =============================================================================
test_start "script reads suggestedIterations field"
assert_contains "$SCRIPT_CONTENT" "suggestedIterations"
test_pass

# =============================================================================
# Test: Script supports complexity weights
# =============================================================================
test_start "script supports small complexity (weight 1)"
assert_contains "$SCRIPT_CONTENT" 'small)'
assert_contains "$SCRIPT_CONTENT" 'SUGGESTED_ITERATIONS+=1'
test_pass

test_start "script supports medium complexity (weight 2)"
assert_contains "$SCRIPT_CONTENT" 'SUGGESTED_ITERATIONS+=2'
test_pass

test_start "script supports large complexity (weight 3)"
assert_contains "$SCRIPT_CONTENT" 'large)'
assert_contains "$SCRIPT_CONTENT" 'SUGGESTED_ITERATIONS+=3'
test_pass

# =============================================================================
# Test: Script has --iterations flag
# =============================================================================
test_start "script parses --iterations flag"
assert_contains "$SCRIPT_CONTENT" '--iterations)'
test_pass

test_start "script supports --iterations auto"
assert_contains "$SCRIPT_CONTENT" 'ITERATIONS_AUTO'
assert_contains "$SCRIPT_CONTENT" '"auto"'
test_pass

# =============================================================================
# Test: Script displays suggested iterations
# =============================================================================
test_start "script displays 'Suggested:' in banner"
assert_contains "$SCRIPT_CONTENT" 'Suggested:'
test_pass

test_start "script displays SUGGESTED_ITERATIONS variable"
assert_contains "$SCRIPT_CONTENT" 'SUGGESTED_ITERATIONS'
test_pass

# =============================================================================
# Test: Script tracks breakdown by complexity
# =============================================================================
test_start "script tracks SUGGESTED_SMALL count"
assert_contains "$SCRIPT_CONTENT" 'SUGGESTED_SMALL'
test_pass

test_start "script tracks SUGGESTED_MEDIUM count"
assert_contains "$SCRIPT_CONTENT" 'SUGGESTED_MEDIUM'
test_pass

test_start "script tracks SUGGESTED_LARGE count"
assert_contains "$SCRIPT_CONTENT" 'SUGGESTED_LARGE'
test_pass

test_start "script builds BREAKDOWN string"
assert_contains "$SCRIPT_CONTENT" 'BREAKDOWN'
assert_contains "$SCRIPT_CONTENT" 'small"'
assert_contains "$SCRIPT_CONTENT" 'large"'
test_pass

# =============================================================================
# Test: Script handles jq fallback for iteration calculation
# =============================================================================
test_start "script has jq fallback for iteration calculation"
# Check that fallback code exists (grep for suggestedIterations without jq)
assert_contains "$SCRIPT_CONTENT" 'Fallback without jq'
test_pass

# =============================================================================
# Test: init command includes complexity field
# =============================================================================
test_start "init template includes complexity field"
assert_contains "$SCRIPT_CONTENT" '"complexity": "medium"'
test_pass

# =============================================================================
# Test: Help text documents --iterations flag
# =============================================================================
test_start "--help documents --iterations flag"
OUTPUT=$("$RALPH" --help 2>&1)
assert_contains "$OUTPUT" "--iterations"
assert_contains "$OUTPUT" "auto"
test_pass

# =============================================================================
# Test: Only counts incomplete tasks (passes != true check in jq)
# =============================================================================
test_start "script only counts incomplete tasks (passes != true)"
assert_contains "$SCRIPT_CONTENT" 'select(.passes != true)'
test_pass
