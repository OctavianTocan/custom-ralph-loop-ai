#!/bin/bash
# Tests for on-stop.sh hook
# This hook handles agent stop and can trigger auto-continue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$PROJECT_ROOT/cursor-config/hooks/on-stop.sh"

# Create a temporary test environment
TEST_TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

# =============================================================================
# Test: Always exits 0 (invariant)
# =============================================================================
test_start "always exits 0 regardless of input"
echo '{"conversation_id": "123", "generation_id": "456"}' | "$HOOK" > /dev/null 2>&1
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
# Test: Output is always valid JSON (invariant)
# =============================================================================
test_start "output is valid JSON with empty input"
OUTPUT=$(echo '' | "$HOOK" 2>&1)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
test_pass

test_start "output is valid JSON with valid input"
OUTPUT=$(echo '{"conversation_id": "123"}' | "$HOOK" 2>&1)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
test_pass

# =============================================================================
# Test: Returns empty JSON when no auto-continue marker
# =============================================================================
test_start "returns empty JSON object when no auto-continue file"
OUTPUT=$(echo '{"conversation_id": "123"}' | "$HOOK" 2>&1)
assert_valid_json "$OUTPUT"
assert_equals "{}" "$OUTPUT"
test_pass

# =============================================================================
# Test: Returns followup_message when auto-continue marker exists
# =============================================================================
test_start "returns followup_message when auto-continue file exists"
# Create a mock sessions directory with auto-continue marker
MOCK_PROJECT="$TEST_TMP_DIR/mock-project"
mkdir -p "$MOCK_PROJECT/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT/sessions/session-001"
echo "Continue with the next iteration" > "$MOCK_PROJECT/sessions/session-001/.ralph-auto-continue"

# Copy the hook to our mock project
cp "$HOOK" "$MOCK_PROJECT/cursor-config/hooks/on-stop.sh"
chmod +x "$MOCK_PROJECT/cursor-config/hooks/on-stop.sh"

OUTPUT=$(echo '{"conversation_id": "123"}' | "$MOCK_PROJECT/cursor-config/hooks/on-stop.sh" 2>&1)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
assert_contains "$OUTPUT" "followup_message"
assert_contains "$OUTPUT" "Continue with the next iteration"
test_pass

# =============================================================================
# Test: Auto-continue marker is removed after use
# =============================================================================
test_start "auto-continue marker is removed after use"
MOCK_PROJECT2="$TEST_TMP_DIR/mock-project2"
mkdir -p "$MOCK_PROJECT2/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT2/sessions/session-002"
echo "Next iteration" > "$MOCK_PROJECT2/sessions/session-002/.ralph-auto-continue"

cp "$HOOK" "$MOCK_PROJECT2/cursor-config/hooks/on-stop.sh"
chmod +x "$MOCK_PROJECT2/cursor-config/hooks/on-stop.sh"

# First call should return followup and remove the marker
echo '{"conversation_id": "123"}' | "$MOCK_PROJECT2/cursor-config/hooks/on-stop.sh" > /dev/null 2>&1

# Check marker is gone
assert_file_not_exists "$MOCK_PROJECT2/sessions/session-002/.ralph-auto-continue"
test_pass

# =============================================================================
# Test: Second call returns empty JSON after marker removed
# =============================================================================
test_start "second call returns empty JSON after marker consumed"
MOCK_PROJECT3="$TEST_TMP_DIR/mock-project3"
mkdir -p "$MOCK_PROJECT3/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT3/sessions/session-003"
echo "Continue" > "$MOCK_PROJECT3/sessions/session-003/.ralph-auto-continue"

cp "$HOOK" "$MOCK_PROJECT3/cursor-config/hooks/on-stop.sh"
chmod +x "$MOCK_PROJECT3/cursor-config/hooks/on-stop.sh"

# First call
echo '{"conversation_id": "123"}' | "$MOCK_PROJECT3/cursor-config/hooks/on-stop.sh" > /dev/null 2>&1

# Second call should return empty
OUTPUT=$(echo '{"conversation_id": "123"}' | "$MOCK_PROJECT3/cursor-config/hooks/on-stop.sh" 2>&1)
assert_equals "{}" "$OUTPUT"
test_pass

# =============================================================================
# Test: Handles missing sessions directory gracefully
# =============================================================================
test_start "handles missing sessions directory gracefully"
OUTPUT=$(echo '{"conversation_id": "123"}' | "$HOOK" 2>&1)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_valid_json "$OUTPUT"
test_pass

# =============================================================================
# Test: Handles special characters in continue prompt
# =============================================================================
test_start "handles special characters in continue prompt"
MOCK_PROJECT4="$TEST_TMP_DIR/mock-project4"
mkdir -p "$MOCK_PROJECT4/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT4/sessions/session-004"
echo 'Continue with "special" chars & symbols' > "$MOCK_PROJECT4/sessions/session-004/.ralph-auto-continue"

cp "$HOOK" "$MOCK_PROJECT4/cursor-config/hooks/on-stop.sh"
chmod +x "$MOCK_PROJECT4/cursor-config/hooks/on-stop.sh"

OUTPUT=$(echo '{"conversation_id": "123"}' | "$MOCK_PROJECT4/cursor-config/hooks/on-stop.sh" 2>&1)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
# Output should be valid JSON even with special characters
assert_valid_json "$OUTPUT"
test_pass

# =============================================================================
# Test: Hook handles missing jq gracefully
# =============================================================================
test_start "handles missing jq by falling back to sed escaping"
MOCK_PROJECT5="$TEST_TMP_DIR/mock-project5"
mkdir -p "$MOCK_PROJECT5/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT5/sessions/session-005"
echo "Continue without jq" > "$MOCK_PROJECT5/sessions/session-005/.ralph-auto-continue"

cp "$HOOK" "$MOCK_PROJECT5/cursor-config/hooks/on-stop.sh"
chmod +x "$MOCK_PROJECT5/cursor-config/hooks/on-stop.sh"

# Use run_without_jq helper to shadow jq with a failing wrapper
OUTPUT=$(echo '{"conversation_id": "123"}' | run_without_jq "$MOCK_PROJECT5/cursor-config/hooks/on-stop.sh" 2>/dev/null)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
assert_contains "$OUTPUT" "followup_message"
test_pass

# =============================================================================
# Test: Empty auto-continue file handled
# =============================================================================
test_start "empty auto-continue file handled gracefully"
MOCK_PROJECT6="$TEST_TMP_DIR/mock-project6"
mkdir -p "$MOCK_PROJECT6/cursor-config/hooks"
mkdir -p "$MOCK_PROJECT6/sessions/session-006"
touch "$MOCK_PROJECT6/sessions/session-006/.ralph-auto-continue"  # Empty file

cp "$HOOK" "$MOCK_PROJECT6/cursor-config/hooks/on-stop.sh"
chmod +x "$MOCK_PROJECT6/cursor-config/hooks/on-stop.sh"

OUTPUT=$(echo '{"conversation_id": "123"}' | "$MOCK_PROJECT6/cursor-config/hooks/on-stop.sh" 2>&1)
EXIT_CODE=$?
assert_exit_code "0" "$EXIT_CODE"
# Should still produce valid JSON
assert_valid_json "$OUTPUT"
test_pass
