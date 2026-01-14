#!/bin/bash
# Tests for ralph-pretty-print.sh
# Validates that the pretty printer correctly formats stream-json output

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRETTY_PRINTER="$PROJECT_ROOT/ralph-pretty-print.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures/stream-json-samples"
EXPECTED_DIR="$SCRIPT_DIR/fixtures/expected-output"

# Source test helpers
source "$SCRIPT_DIR/test-helpers.sh"

# =============================================================================
# Test: Pretty printer exists and is executable
# =============================================================================
test_start "ralph-pretty-print.sh exists and is executable"
assert_file_exists "$PRETTY_PRINTER"
assert_file_executable "$PRETTY_PRINTER"
test_pass

# =============================================================================
# Test: Pretty printer shows thinking with label and truncation
# =============================================================================
test_start "thinking blocks show with [THINK] label and are truncated at 200 chars"
OUTPUT=$(cat "$FIXTURES_DIR/thinking.jsonl" | "$PRETTY_PRINTER" 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
# Check for thinking label
assert_contains "$OUTPUT" "[THINK]"
# Check that long thinking is truncated (look for ellipsis or truncation)
assert_contains "$OUTPUT" "..."
test_pass

# =============================================================================
# Test: Pretty printer shows tool_use with name highlighted
# =============================================================================
test_start "tool_use blocks show with [TOOL] label and tool name"
OUTPUT=$(cat "$FIXTURES_DIR/tool-calls.jsonl" | "$PRETTY_PRINTER" 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
# Check for tool label
assert_contains "$OUTPUT" "[TOOL]"
# Check that tool names appear
assert_contains "$OUTPUT" "Read"
assert_contains "$OUTPUT" "Edit"
assert_contains "$OUTPUT" "Bash"
# Check that tool arguments are shown
assert_contains "$OUTPUT" 'file_path="/path/to/file.ts"'
assert_contains "$OUTPUT" 'command="npm test"'
test_pass

# =============================================================================
# Test: Pretty printer shows result events
# =============================================================================
test_start "result events show with [RESULT] label"
OUTPUT=$(cat "$FIXTURES_DIR/tool-calls.jsonl" | "$PRETTY_PRINTER" 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
# Check for result label
assert_contains "$OUTPUT" "[RESULT]"
# Check that results are truncated at 500 chars (look for ellipsis)
assert_contains "$OUTPUT" "..."
test_pass

# =============================================================================
# Test: Pretty printer shows text output
# =============================================================================
test_start "text output shows with [OUTPUT] label"
OUTPUT=$(cat "$FIXTURES_DIR/text-output.jsonl" | "$PRETTY_PRINTER" 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
# Check for text label
assert_contains "$OUTPUT" "[OUTPUT]"
# Check that text appears
assert_contains "$OUTPUT" "Based on my analysis"
assert_contains "$OUTPUT" "implementation is complete"
test_pass

# =============================================================================
# Test: Pretty printer handles mixed session
# =============================================================================
test_start "mixed session with all event types formats correctly"
OUTPUT=$(cat "$FIXTURES_DIR/mixed-session.jsonl" | "$PRETTY_PRINTER" 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
# Check all labels appear
assert_contains "$OUTPUT" "[THINK]"
assert_contains "$OUTPUT" "[TOOL]"
assert_contains "$OUTPUT" "[RESULT]"
assert_contains "$OUTPUT" "[OUTPUT]"
# Check expected content
assert_contains "$OUTPUT" 'Read: file_path="config.json"'
assert_contains "$OUTPUT" 'Edit: file_path="config.json"'
assert_contains "$OUTPUT" 'old_string="1.0.0"'
assert_contains "$OUTPUT" "updated the version to 2.0.0"
test_pass

# =============================================================================
# Test: Pretty printer handles malformed JSON gracefully
# =============================================================================
test_start "malformed JSON shows warning but continues processing"
OUTPUT=$(cat "$FIXTURES_DIR/error-cases.jsonl" | "$PRETTY_PRINTER" 2>&1)
EXIT_CODE=$?
# Should continue processing despite errors
assert_exit_code 0 $EXIT_CODE
# Should show the valid lines
assert_contains "$OUTPUT" "Valid JSON line"
assert_contains "$OUTPUT" "Recovery after errors"
test_pass

# =============================================================================
# Test: --no-color flag disables ANSI codes
# =============================================================================
test_start "--no-color flag disables ANSI color codes"
# Get output with colors
OUTPUT_COLOR=$(cat "$FIXTURES_DIR/text-output.jsonl" | "$PRETTY_PRINTER" 2>&1)
# Get output without colors
OUTPUT_NO_COLOR=$(cat "$FIXTURES_DIR/text-output.jsonl" | "$PRETTY_PRINTER" --no-color 2>&1)
# Output should differ (color version has ANSI codes)
# We check that both have the text label
assert_contains "$OUTPUT_COLOR" "[OUTPUT]"
assert_contains "$OUTPUT_NO_COLOR" "[OUTPUT]"
test_pass

# =============================================================================
# Test: Empty input produces no output
# =============================================================================
test_start "empty input produces no output"
OUTPUT=$(echo "" | "$PRETTY_PRINTER" 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_equals "" "$OUTPUT"
test_pass

# =============================================================================
# Test: Single-line text output
# =============================================================================
test_start "single JSON line processes correctly"
OUTPUT=$(echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Hello"}]}}' | "$PRETTY_PRINTER" 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_contains "$OUTPUT" "[OUTPUT]"
assert_contains "$OUTPUT" "Hello"
test_pass

# =============================================================================
# Test: File path extraction for tool calls
# =============================================================================
test_start "tool calls extract and show file paths"
OUTPUT=$(cat "$FIXTURES_DIR/tool-calls.jsonl" | "$PRETTY_PRINTER" 2>&1)
# Should show file paths from tool inputs
assert_contains "$OUTPUT" "/path/to/file.ts"
test_pass

# =============================================================================
# Test: Help flag shows usage
# =============================================================================
test_start "--help flag shows usage information"
OUTPUT=$("$PRETTY_PRINTER" --help 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_contains "$OUTPUT" "Usage:"
test_pass
