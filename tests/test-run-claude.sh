#!/bin/bash
# Tests for run-claude.sh runner
# Tests environment variable handling and argument parsing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNNER="$PROJECT_ROOT/runners/run-claude.sh"

# Create a temporary test environment
TEST_TMP_DIR=$(mktemp -d)
trap "rm -rf $TEST_TMP_DIR" EXIT

# =============================================================================
# Test: Shows usage when missing arguments
# =============================================================================
test_start "shows usage when missing required arguments"
OUTPUT=$("$RUNNER" 2>&1 || true)
assert_contains "$OUTPUT" "Usage:"
test_pass

test_start "shows usage with only prompt file"
OUTPUT=$("$RUNNER" /tmp/prompt.txt 2>&1 || true)
assert_contains "$OUTPUT" "Usage:"
test_pass

# =============================================================================
# Test: Fails gracefully when claude CLI not available
# =============================================================================
test_start "fails gracefully when claude CLI not found"
# Create a modified PATH without claude
MODIFIED_PATH="/usr/bin:/bin"  # Minimal PATH unlikely to have claude
OUTPUT=$(PATH="$MODIFIED_PATH" "$RUNNER" /tmp/prompt.txt /tmp/log.txt 2>&1 || true)
assert_contains "$OUTPUT" "Claude CLI not found"
test_pass

# =============================================================================
# Test: Script is executable
# =============================================================================
test_start "runner script is executable"
assert_file_executable "$RUNNER"
test_pass

# =============================================================================
# Test: Environment variable RALPH_FALLBACK_MODEL default
# =============================================================================
test_start "RALPH_FALLBACK_MODEL defaults to haiku"
# Check the script source for default value
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" 'RALPH_FALLBACK_MODEL:-haiku'
test_pass

# =============================================================================
# Test: Environment variable RALPH_JSON_OUTPUT handling
# =============================================================================
test_start "supports RALPH_JSON_OUTPUT environment variable"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" 'RALPH_JSON_OUTPUT'
assert_contains "$SCRIPT_CONTENT" '--output-format'
test_pass

# =============================================================================
# Test: Environment variable RALPH_EPHEMERAL handling
# =============================================================================
test_start "supports RALPH_EPHEMERAL environment variable"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" 'RALPH_EPHEMERAL'
assert_contains "$SCRIPT_CONTENT" '--no-session-persistence'
test_pass

# =============================================================================
# Test: Environment variable RALPH_SYSTEM_PROMPT_APPEND handling
# =============================================================================
test_start "supports RALPH_SYSTEM_PROMPT_APPEND environment variable"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" 'RALPH_SYSTEM_PROMPT_APPEND'
assert_contains "$SCRIPT_CONTENT" '--append-system-prompt'
test_pass

# =============================================================================
# Test: Uses dangerously-skip-permissions flag
# =============================================================================
test_start "uses --dangerously-skip-permissions flag"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" '--dangerously-skip-permissions'
test_pass

# =============================================================================
# Test: Supports model argument
# =============================================================================
test_start "supports model argument and fallback model"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" '--model'
assert_contains "$SCRIPT_CONTENT" '--fallback-model'
test_pass

# =============================================================================
# Test: Uses print mode (-p flag)
# =============================================================================
test_start "uses print mode (-p flag)"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" '"-p"'
test_pass

# =============================================================================
# Test: Reads prompt from file via stdin redirect
# =============================================================================
test_start "reads prompt from file via stdin redirect"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" '< "$PROMPT_FILE"'
test_pass

# =============================================================================
# Test: Logs output to log file
# =============================================================================
test_start "logs output to specified log file"
SCRIPT_CONTENT=$(cat "$RUNNER")
# Should use tee or redirect to log file
if [[ "$SCRIPT_CONTENT" == *'tee -a "$LOG_FILE"'* ]] || [[ "$SCRIPT_CONTENT" == *'>> "$LOG_FILE"'* ]]; then
  test_pass
else
  echo -e "${RED}FAIL${NC}"
  echo "    Script should log to LOG_FILE"
  TEST_FAILED=1
  ((FAILED_TESTS++))
fi

# =============================================================================
# Test: JSON output mode uses jq for parsing
# =============================================================================
test_start "JSON output mode uses jq for parsing"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" 'jq'
assert_contains "$SCRIPT_CONTENT" '.is_error'
assert_contains "$SCRIPT_CONTENT" '.total_cost_usd'
assert_contains "$SCRIPT_CONTENT" '.result'
test_pass

# =============================================================================
# Test: Handles jq not being available in JSON mode
# =============================================================================
test_start "handles jq not being available in JSON mode"
SCRIPT_CONTENT=$(cat "$RUNNER")
# Should have an else branch for when jq is not available
assert_contains "$SCRIPT_CONTENT" 'command -v jq'
test_pass

# =============================================================================
# Test: Script has proper shebang
# =============================================================================
test_start "script has proper bash shebang"
FIRST_LINE=$(head -1 "$RUNNER")
assert_equals "#!/bin/bash" "$FIRST_LINE"
test_pass

# =============================================================================
# Test: Script uses set -e for error handling
# =============================================================================
test_start "script uses set -e for error handling"
SCRIPT_CONTENT=$(cat "$RUNNER")
assert_contains "$SCRIPT_CONTENT" 'set -e'
test_pass

# =============================================================================
# Test: Provides helpful error for missing claude CLI
# =============================================================================
test_start "provides installation instructions when claude CLI missing"
OUTPUT=$(PATH="/usr/bin:/bin" "$RUNNER" /tmp/prompt.txt /tmp/log.txt 2>&1 || true)
assert_contains "$OUTPUT" "To install Claude CLI"
assert_contains "$OUTPUT" "claude.ai"
test_pass
