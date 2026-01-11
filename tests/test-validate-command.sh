#!/bin/bash
# Tests for validate-command.sh hook
# This hook validates shell commands and outputs JSON response

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$PROJECT_ROOT/cursor-config/hooks/validate-command.sh"

# =============================================================================
# Test: Valid JSON input with command field
# =============================================================================
test_start "valid JSON input returns allow permission"
OUTPUT=$(echo '{"command": "ls -la", "conversation_id": "123"}' | "$HOOK")
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
assert_contains "$OUTPUT" '"permission"'
assert_contains "$OUTPUT" '"allow"'
test_pass

# =============================================================================
# Test: Empty JSON input
# =============================================================================
test_start "empty JSON object returns allow permission"
OUTPUT=$(echo '{}' | "$HOOK")
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
assert_contains "$OUTPUT" '"permission"'
assert_contains "$OUTPUT" '"allow"'
test_pass

# =============================================================================
# Test: Empty input (no JSON)
# =============================================================================
test_start "empty input still returns valid JSON"
OUTPUT=$(echo '' | "$HOOK")
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
assert_contains "$OUTPUT" '"permission"'
test_pass

# =============================================================================
# Test: Malformed JSON input
# =============================================================================
test_start "malformed JSON input still returns valid JSON"
OUTPUT=$(echo 'not valid json at all' | "$HOOK")
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
assert_contains "$OUTPUT" '"permission"'
test_pass

# =============================================================================
# Test: JSON with special characters in command
# =============================================================================
test_start "command with special characters handled correctly"
OUTPUT=$(echo '{"command": "echo \"hello world\" | grep hello"}' | "$HOOK")
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
test_pass

# =============================================================================
# Test: Always exits 0 (invariant)
# =============================================================================
test_start "always exits 0 regardless of input"
echo '{"command": "rm -rf /"}' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"

echo 'completely invalid' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"

echo '' | "$HOOK" > /dev/null 2>&1
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
test_pass

# =============================================================================
# Test: Output is valid JSON (invariant)
# =============================================================================
test_start "output is always valid JSON"
OUTPUT1=$(echo '{"command": "ls"}' | "$HOOK")
OUTPUT2=$(echo '{}' | "$HOOK")
OUTPUT3=$(echo '' | "$HOOK")
OUTPUT4=$(echo 'garbage' | "$HOOK")

assert_valid_json "$OUTPUT1"
assert_valid_json "$OUTPUT2"
assert_valid_json "$OUTPUT3"
assert_valid_json "$OUTPUT4"
test_pass

# =============================================================================
# Test: Command with newlines in JSON
# =============================================================================
test_start "command with newlines in JSON handled"
OUTPUT=$(echo '{"command": "echo line1\nline2"}' | "$HOOK")
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
test_pass

# =============================================================================
# Test: Very long command
# =============================================================================
test_start "very long command handled correctly"
LONG_CMD=$(printf 'a%.0s' {1..1000})
OUTPUT=$(echo "{\"command\": \"$LONG_CMD\"}" | "$HOOK")
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
test_pass

# =============================================================================
# Test: Hook handles missing jq gracefully (if we can simulate)
# =============================================================================
test_start "falls back when jq is not in PATH"
# Create a modified PATH without jq
JQ_PATH="$(which jq 2>/dev/null || true)"
if [[ -n "$JQ_PATH" ]]; then
  MODIFIED_PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "$(dirname "$JQ_PATH")" | tr '\n' ':')
else
  MODIFIED_PATH="$PATH"
fi
OUTPUT=$(echo '{"command": "test"}' | PATH="$MODIFIED_PATH" "$HOOK" 2>/dev/null)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
test_pass
