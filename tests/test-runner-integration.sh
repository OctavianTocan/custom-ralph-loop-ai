#!/bin/bash
# Integration tests for run-claude.sh with stream-json and pretty-printer
# Tests that the runner properly pipes claude output through ralph-pretty-print.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNNER="$PROJECT_ROOT/runners/run-claude.sh"
PRETTY_PRINTER="$PROJECT_ROOT/ralph-pretty-print.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures/stream-json-samples"

# Source test helpers
source "$SCRIPT_DIR/test-helpers.sh"

# =============================================================================
# Setup: Create mock claude binary for testing
# =============================================================================
TEMP_BIN=$(mktemp -d)
MOCK_CLAUDE="$TEMP_BIN/claude"

# Create mock claude that outputs fixture JSONL
cat > "$MOCK_CLAUDE" << 'EOF'
#!/bin/bash
# Mock claude binary for testing
# Outputs stream-json fixture based on args

# Parse flags
OUTPUT_FORMAT="text"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-format)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Output fixture data based on format
if [[ "$OUTPUT_FORMAT" == "stream-json" ]]; then
  # Output realistic stream-json events
  cat << 'JSONL'
{"type":"assistant","message":{"content":[{"type":"thinking","thinking":"Let me analyze the requirements and plan my approach..."}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_01","name":"Read","input":{"file_path":"/home/user/config.json"}}]}}
{"type":"result","subtype":"success","result":"{\n  \"version\": \"1.0.0\",\n  \"name\": \"test-app\"\n}"}
{"type":"assistant","message":{"content":[{"type":"thinking","thinking":"The config needs to be updated to version 2.0.0"}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_02","name":"Edit","input":{"file_path":"/home/user/config.json","old_string":"\"version\": \"1.0.0\"","new_string":"\"version\": \"2.0.0\""}}]}}
{"type":"result","subtype":"success","result":"File edited successfully"}
{"type":"assistant","message":{"content":[{"type":"text","text":"I've updated the version to 2.0.0 in the config file."}]}}
JSONL
else
  # Output plain text (fallback)
  echo "I've updated the version to 2.0.0 in the config file."
fi
EOF

chmod +x "$MOCK_CLAUDE"

# Add mock claude to PATH for tests
export PATH="$TEMP_BIN:$PATH"

# Cleanup function
cleanup_mock() {
  rm -rf "$TEMP_BIN"
}
trap cleanup_mock EXIT

# =============================================================================
# Test: Runner exists and is executable
# =============================================================================
test_start "run-claude.sh exists and is executable"
assert_file_exists "$RUNNER"
assert_file_executable "$RUNNER"
test_pass

# =============================================================================
# Test: Mock claude outputs stream-json when called with --output-format
# =============================================================================
test_start "mock claude outputs stream-json with correct flag"
OUTPUT=$(claude --output-format stream-json -p 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_contains "$OUTPUT" '"type":"assistant"'
assert_contains "$OUTPUT" '"type":"thinking"'
assert_contains "$OUTPUT" '"type":"tool_use"'
test_pass

# =============================================================================
# Test: Runner with stream-json shows thinking emoji
# =============================================================================
test_start "runner output shows 🤔 emoji for thinking blocks"
TEMP_PROMPT=$(mktemp)
TEMP_LOG=$(mktemp)
echo "Test prompt" > "$TEMP_PROMPT"

# Run the runner
OUTPUT=$("$RUNNER" "$TEMP_PROMPT" "$TEMP_LOG" 2>&1)
EXIT_CODE=$?

# Check output contains thinking emoji
assert_contains "$OUTPUT" "🤔"

rm -f "$TEMP_PROMPT" "$TEMP_LOG"
test_pass

# =============================================================================
# Test: Runner output shows tool emoji for tool calls
# =============================================================================
test_start "runner output shows 🔧 emoji for tool calls"
TEMP_PROMPT=$(mktemp)
TEMP_LOG=$(mktemp)
echo "Test prompt" > "$TEMP_PROMPT"

OUTPUT=$("$RUNNER" "$TEMP_PROMPT" "$TEMP_LOG" 2>&1)

# Check for tool emoji and tool names
assert_contains "$OUTPUT" "🔧"
assert_contains "$OUTPUT" "Read"
assert_contains "$OUTPUT" "Edit"

rm -f "$TEMP_PROMPT" "$TEMP_LOG"
test_pass

# =============================================================================
# Test: Runner output shows text emoji for assistant responses
# =============================================================================
test_start "runner output shows 💬 emoji for text responses"
TEMP_PROMPT=$(mktemp)
TEMP_LOG=$(mktemp)
echo "Test prompt" > "$TEMP_PROMPT"

OUTPUT=$("$RUNNER" "$TEMP_PROMPT" "$TEMP_LOG" 2>&1)

# Check for text emoji and content
assert_contains "$OUTPUT" "💬"
assert_contains "$OUTPUT" "updated the version to 2.0.0"

rm -f "$TEMP_PROMPT" "$TEMP_LOG"
test_pass

# =============================================================================
# Test: Log file contains raw JSON (not pretty-printed)
# =============================================================================
test_start "log file contains raw JSON, not pretty-printed output"
TEMP_PROMPT=$(mktemp)
TEMP_LOG=$(mktemp)
echo "Test prompt" > "$TEMP_PROMPT"

"$RUNNER" "$TEMP_PROMPT" "$TEMP_LOG" > /dev/null 2>&1

# Log should contain raw JSON
LOG_CONTENT=$(cat "$TEMP_LOG")
assert_contains "$LOG_CONTENT" '"type":"assistant"'
assert_contains "$LOG_CONTENT" '"type":"thinking"'
# Log should NOT contain emojis (those are only for terminal display)
assert_not_contains "$LOG_CONTENT" "🤔"
assert_not_contains "$LOG_CONTENT" "🔧"

rm -f "$TEMP_PROMPT" "$TEMP_LOG"
test_pass

# =============================================================================
# Test: Runner handles case where pretty-printer is missing (fallback)
# =============================================================================
test_start "runner gracefully handles missing pretty-printer"
TEMP_PROMPT=$(mktemp)
TEMP_LOG=$(mktemp)
echo "Test prompt" > "$TEMP_PROMPT"

# Temporarily rename pretty-printer to simulate it being missing
if [[ -f "$PRETTY_PRINTER" ]]; then
  mv "$PRETTY_PRINTER" "$PRETTY_PRINTER.backup"

  # Run should still work (fallback to raw output)
  OUTPUT=$("$RUNNER" "$TEMP_PROMPT" "$TEMP_LOG" 2>&1)
  EXIT_CODE=$?

  # Should succeed even without pretty-printer
  assert_exit_code 0 $EXIT_CODE
  # Output should contain JSON (not pretty-printed)
  assert_contains "$OUTPUT" '"type":"assistant"'

  # Restore pretty-printer
  mv "$PRETTY_PRINTER.backup" "$PRETTY_PRINTER"
else
  test_skip "pretty-printer not found, cannot test fallback"
fi

rm -f "$TEMP_PROMPT" "$TEMP_LOG"
test_pass

# =============================================================================
# Test: RALPH_JSON_OUTPUT=true still works (backwards compatibility)
# =============================================================================
test_start "RALPH_JSON_OUTPUT=true environment variable still works"
TEMP_PROMPT=$(mktemp)
TEMP_LOG=$(mktemp)
echo "Test prompt" > "$TEMP_PROMPT"

# Create mock claude that respects --output-format json
cat > "$MOCK_CLAUDE" << 'EOF'
#!/bin/bash
# Check for json format
if [[ "$*" == *"--output-format json"* ]]; then
  echo '{"result":"Test response","total_cost_usd":0.001,"is_error":false}'
else
  echo "Test response"
fi
EOF
chmod +x "$MOCK_CLAUDE"

# Run with RALPH_JSON_OUTPUT=true
OUTPUT=$(RALPH_JSON_OUTPUT=true "$RUNNER" "$TEMP_PROMPT" "$TEMP_LOG" 2>&1)

# Should contain cost info
assert_contains "$OUTPUT" "Cost:"

rm -f "$TEMP_PROMPT" "$TEMP_LOG"
test_pass
