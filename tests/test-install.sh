#!/bin/bash
# Tests for install.sh
# Tests installation to various target directories

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SCRIPT="$PROJECT_ROOT/install.sh"

# Source test helpers
# shellcheck source=tests/test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

# Create a temporary test environment
TEST_TMP_DIR=$(mktemp -d)
trap "rm -rf $TEST_TMP_DIR" EXIT

# Change to temp directory for testing
cd "$TEST_TMP_DIR" || exit 1

# Copy install.sh to temp directory (it needs to find source files)
# We'll test by running from the project root instead
INSTALL_CMD="$INSTALL_SCRIPT"

# =============================================================================
# Test: install.sh exists and is executable
# =============================================================================
test_start "install.sh exists and is executable"
assert_file_exists "$INSTALL_SCRIPT"
assert_file_executable "$INSTALL_SCRIPT"
test_pass

# =============================================================================
# Test: Default install creates .ralph/ directory
# =============================================================================
test_start "default install creates .ralph/ directory"
cd "$TEST_TMP_DIR" || exit 1
"$INSTALL_CMD" > /dev/null 2>&1
assert_dir_exists ".ralph"
test_pass

# =============================================================================
# Test: ralph.sh is copied and executable
# =============================================================================
test_start "ralph.sh is copied and executable"
assert_file_exists ".ralph/ralph.sh"
assert_file_executable ".ralph/ralph.sh"
test_pass

# =============================================================================
# Test: status.sh is copied and executable
# =============================================================================
test_start "status.sh is copied and executable"
assert_file_exists ".ralph/status.sh"
assert_file_executable ".ralph/status.sh"
test_pass

# =============================================================================
# Test: stop.sh is copied and executable
# =============================================================================
test_start "stop.sh is copied and executable"
assert_file_exists ".ralph/stop.sh"
assert_file_executable ".ralph/stop.sh"
test_pass

# =============================================================================
# Test: watch.sh is copied and executable
# =============================================================================
test_start "watch.sh is copied and executable"
assert_file_exists ".ralph/watch.sh"
assert_file_executable ".ralph/watch.sh"
test_pass

# =============================================================================
# Test: ralph-pretty-print.sh is copied and executable
# =============================================================================
test_start "ralph-pretty-print.sh is copied and executable"
assert_file_exists ".ralph/ralph-pretty-print.sh"
assert_file_executable ".ralph/ralph-pretty-print.sh"
test_pass

# =============================================================================
# Test: prompt.md is copied
# =============================================================================
test_start "prompt.md is copied"
assert_file_exists ".ralph/prompt.md"
test_pass

# =============================================================================
# Test: runners/ directory is copied
# =============================================================================
test_start "runners/ directory is copied"
assert_dir_exists ".ralph/runners"
assert_file_exists ".ralph/runners/run-claude.sh"
assert_file_executable ".ralph/runners/run-claude.sh"
test_pass

# =============================================================================
# Test: sessions/ directory is created (empty)
# =============================================================================
test_start "sessions/ directory is created"
assert_dir_exists ".ralph/sessions"
test_pass

# =============================================================================
# Test: Custom target directory works
# =============================================================================
test_start "custom target directory works"
cd "$TEST_TMP_DIR" || exit 1
rm -rf custom-ralph
"$INSTALL_CMD" custom-ralph > /dev/null 2>&1
assert_dir_exists "custom-ralph"
assert_file_exists "custom-ralph/ralph.sh"
assert_file_executable "custom-ralph/ralph.sh"
test_pass

# =============================================================================
# Test: Running install twice updates existing installation
# =============================================================================
test_start "running install twice updates existing installation"
cd "$TEST_TMP_DIR" || exit 1
# First install
"$INSTALL_CMD" update-test > /dev/null 2>&1
# Modify a file to verify it gets updated
echo "# modified" >> update-test/ralph.sh
MODIFIED_SIZE=$(wc -c < update-test/ralph.sh)
# Second install
"$INSTALL_CMD" update-test > /dev/null 2>&1
UPDATED_SIZE=$(wc -c < update-test/ralph.sh)
# File should be back to original size (without our modification)
if [[ "$UPDATED_SIZE" -lt "$MODIFIED_SIZE" ]]; then
  test_pass
else
  echo -e "${RED}FAIL${NC}"
  echo "    Expected file to be updated (smaller than modified)"
  ((FAILED_TESTS++)) || true
fi

# =============================================================================
# Test: If .claude/ exists, commands copied to .claude/commands/
# =============================================================================
test_start "commands copied to .claude/commands/ if .claude/ exists"
cd "$TEST_TMP_DIR" || exit 1
rm -rf claude-test
mkdir -p claude-test/.claude
cd claude-test || exit 1
"$INSTALL_CMD" > /dev/null 2>&1
assert_dir_exists ".claude/commands"
assert_file_exists ".claude/commands/ralph:setup.md"
assert_file_exists ".claude/commands/ralph:run.md"
test_pass

# =============================================================================
# Test: If .cursor/ exists, commands copied to .cursor/commands/
# =============================================================================
test_start "commands copied to .cursor/commands/ if .cursor/ exists"
cd "$TEST_TMP_DIR" || exit 1
rm -rf cursor-test
mkdir -p cursor-test/.cursor
cd cursor-test || exit 1
"$INSTALL_CMD" > /dev/null 2>&1
assert_dir_exists ".cursor/commands"
assert_file_exists ".cursor/commands/ralph:setup.md"
assert_file_exists ".cursor/commands/ralph:run.md"
test_pass

# =============================================================================
# Test: Install shows success message
# =============================================================================
test_start "install shows success message"
cd "$TEST_TMP_DIR" || exit 1
rm -rf success-test
OUTPUT=$("$INSTALL_CMD" success-test 2>&1)
assert_contains "$OUTPUT" "success-test"
test_pass

# =============================================================================
# Test: Install shows usage instructions
# =============================================================================
test_start "install shows usage instructions"
assert_contains "$OUTPUT" "ralph.sh"
test_pass

# =============================================================================
# Test: --help flag shows usage
# =============================================================================
test_start "--help flag shows usage"
OUTPUT=$("$INSTALL_CMD" --help 2>&1)
assert_contains "$OUTPUT" "Usage"
test_pass

# =============================================================================
# Test: Installed ralph.sh --version works
# =============================================================================
test_start "installed ralph.sh --version works"
cd "$TEST_TMP_DIR/.ralph" || exit 1
OUTPUT=$(./ralph.sh --version 2>&1)
assert_contains "$OUTPUT" "ralph"
test_pass
