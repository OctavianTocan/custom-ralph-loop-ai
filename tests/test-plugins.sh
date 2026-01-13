#!/bin/bash
# Tests for plugin discovery and validation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH_SCRIPT="$PROJECT_ROOT/ralph.sh"
PLUGIN_DIR="$PROJECT_ROOT/plugins"

# Source test helpers
source "$SCRIPT_DIR/test-helpers.sh"

# =============================================================================
# Test: plugins directory exists
# =============================================================================
test_start "plugins directory exists"
assert_dir_exists "$PLUGIN_DIR"
test_pass

# =============================================================================
# Test: claude plugin exposes metadata
# =============================================================================
test_start "claude plugin exposes metadata"
METADATA=$(bash -c "source \"$PLUGIN_DIR/claude.plugin.sh\" && get_metadata")
assert_contains "$METADATA" "name=claude"
test_pass

# =============================================================================
# Test: --list-agents shows available plugins
# =============================================================================
test_start "--list-agents shows available plugins"
OUTPUT=$("$RALPH_SCRIPT" --list-agents 2>&1)
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
assert_contains "$OUTPUT" "claude"
assert_contains "$OUTPUT" "codex"
assert_contains "$OUTPUT" "opencode"
assert_contains "$OUTPUT" "cursor"
test_pass

# =============================================================================
# Test: cursor plugin validation enforces model
# =============================================================================
test_start "cursor plugin validation enforces model"
PRD_NO_MODEL=$(mktemp)
cat > "$PRD_NO_MODEL" <<'EOF'
{"agent":"cursor","branchName":"ralph/test"}
EOF
source "$PLUGIN_DIR/cursor.plugin.sh"
validate_config "$PRD_NO_MODEL" "" >/dev/null 2>&1
EXIT_CODE=$?
assert_exit_code 1 $EXIT_CODE

PRD_WITH_MODEL=$(mktemp)
cat > "$PRD_WITH_MODEL" <<'EOF'
{"agent":"cursor","branchName":"ralph/test","model":"claude-sonnet-4"}
EOF
validate_config "$PRD_WITH_MODEL" "" >/dev/null 2>&1
EXIT_CODE=$?
assert_exit_code 0 $EXIT_CODE
rm -f "$PRD_NO_MODEL" "$PRD_WITH_MODEL"
test_pass

# =============================================================================
# Test: build_command uses existing runner scripts
# =============================================================================
test_start "build_command uses existing runner scripts"
mapfile -t CMD < <(bash -c "source \"$PLUGIN_DIR/claude.plugin.sh\" && build_command /tmp/p /tmp/l /tmp/s ''")
assert_contains "${CMD[0]}" "runners/run-claude.sh"
test_pass
