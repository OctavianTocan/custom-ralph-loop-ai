#!/bin/bash
# Tests for install-cursor-hooks.sh
# Tests installation script behavior including idempotency

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SCRIPT="$PROJECT_ROOT/install-cursor-hooks.sh"

# Create a temporary test environment
TEST_TMP_DIR=$(mktemp -d)
trap "rm -rf $TEST_TMP_DIR" EXIT

# =============================================================================
# Helper: Create a mock Ralph project structure
# =============================================================================
create_mock_project() {
  local project_dir="$1"
  mkdir -p "$project_dir/cursor-config/hooks"

  # Copy cursor-config from real project
  cp -r "$PROJECT_ROOT/cursor-config/"* "$project_dir/cursor-config/"

  # Copy install script
  cp "$INSTALL_SCRIPT" "$project_dir/install-cursor-hooks.sh"
  chmod +x "$project_dir/install-cursor-hooks.sh"
}

# =============================================================================
# Test: Install script creates .cursor directory
# =============================================================================
test_start "creates .cursor directory if not exists"
MOCK_PROJECT="$TEST_TMP_DIR/project1"
create_mock_project "$MOCK_PROJECT"

# Run install (answer 'y' if prompted)
cd "$MOCK_PROJECT"
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1
EXIT_CODE=$?

assert_dir_exists "$MOCK_PROJECT/.cursor"
test_pass

# =============================================================================
# Test: Install script creates hooks directory
# =============================================================================
test_start "creates .cursor/hooks directory"
MOCK_PROJECT="$TEST_TMP_DIR/project2"
create_mock_project "$MOCK_PROJECT"

cd "$MOCK_PROJECT"
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1

assert_dir_exists "$MOCK_PROJECT/.cursor/hooks"
test_pass

# =============================================================================
# Test: Install script copies hooks.json
# =============================================================================
test_start "copies hooks.json to .cursor/"
MOCK_PROJECT="$TEST_TMP_DIR/project3"
create_mock_project "$MOCK_PROJECT"

cd "$MOCK_PROJECT"
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1

assert_file_exists "$MOCK_PROJECT/.cursor/hooks.json"
test_pass

# =============================================================================
# Test: Install script copies all hook scripts
# =============================================================================
test_start "copies all hook scripts to .cursor/hooks/"
MOCK_PROJECT="$TEST_TMP_DIR/project4"
create_mock_project "$MOCK_PROJECT"

cd "$MOCK_PROJECT"
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1

assert_file_exists "$MOCK_PROJECT/.cursor/hooks/validate-command.sh"
assert_file_exists "$MOCK_PROJECT/.cursor/hooks/log-command.sh"
assert_file_exists "$MOCK_PROJECT/.cursor/hooks/track-edit.sh"
assert_file_exists "$MOCK_PROJECT/.cursor/hooks/on-stop.sh"
test_pass

# =============================================================================
# Test: Hook scripts are made executable
# =============================================================================
test_start "makes hook scripts executable"
MOCK_PROJECT="$TEST_TMP_DIR/project5"
create_mock_project "$MOCK_PROJECT"

cd "$MOCK_PROJECT"
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1

assert_file_executable "$MOCK_PROJECT/.cursor/hooks/validate-command.sh"
assert_file_executable "$MOCK_PROJECT/.cursor/hooks/log-command.sh"
assert_file_executable "$MOCK_PROJECT/.cursor/hooks/track-edit.sh"
assert_file_executable "$MOCK_PROJECT/.cursor/hooks/on-stop.sh"
test_pass

# =============================================================================
# Test: Idempotency - running twice produces same result
# =============================================================================
test_start "installation is idempotent (running twice works)"
MOCK_PROJECT="$TEST_TMP_DIR/project6"
create_mock_project "$MOCK_PROJECT"

cd "$MOCK_PROJECT"
# First install
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1
EXIT_CODE1=$?

# Get file contents after first install
HOOKS_JSON_1=$(cat "$MOCK_PROJECT/.cursor/hooks.json")

# Second install (answer 'y' to overwrite)
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1
EXIT_CODE2=$?

# Get file contents after second install
HOOKS_JSON_2=$(cat "$MOCK_PROJECT/.cursor/hooks.json")

assert_equals "$HOOKS_JSON_1" "$HOOKS_JSON_2" "hooks.json should be identical after re-install"
test_pass

# =============================================================================
# Test: Respects 'n' answer to overwrite prompt
# =============================================================================
test_start "respects 'n' answer to skip overwrite"
MOCK_PROJECT="$TEST_TMP_DIR/project7"
create_mock_project "$MOCK_PROJECT"

cd "$MOCK_PROJECT"
# First install
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1

# Modify hooks.json
echo '{"modified": true}' > "$MOCK_PROJECT/.cursor/hooks.json"

# Second install, answer 'n' to skip overwrite
echo "n" | ./install-cursor-hooks.sh > /dev/null 2>&1

# Check that our modification is preserved
CONTENT=$(cat "$MOCK_PROJECT/.cursor/hooks.json")
assert_contains "$CONTENT" "modified"
test_pass

# =============================================================================
# Test: Fails gracefully when cursor-config missing
# =============================================================================
test_start "fails gracefully when cursor-config directory missing"
MOCK_PROJECT="$TEST_TMP_DIR/project8"
mkdir -p "$MOCK_PROJECT"
cp "$INSTALL_SCRIPT" "$MOCK_PROJECT/install-cursor-hooks.sh"
chmod +x "$MOCK_PROJECT/install-cursor-hooks.sh"

cd "$MOCK_PROJECT"
OUTPUT=$(./install-cursor-hooks.sh 2>&1)
EXIT_CODE=$?

# Should fail with exit code 1
assert_exit_code "1" "$EXIT_CODE"
assert_contains "$OUTPUT" "cursor-config"
test_pass

# =============================================================================
# Test: Hooks.json content is valid JSON
# =============================================================================
test_start "installed hooks.json is valid JSON"
MOCK_PROJECT="$TEST_TMP_DIR/project9"
create_mock_project "$MOCK_PROJECT"

cd "$MOCK_PROJECT"
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1

CONTENT=$(cat "$MOCK_PROJECT/.cursor/hooks.json")
assert_valid_json "$CONTENT"
test_pass

# =============================================================================
# Test: Hooks.json contains expected hook types
# =============================================================================
test_start "installed hooks.json contains all hook types"
MOCK_PROJECT="$TEST_TMP_DIR/project10"
create_mock_project "$MOCK_PROJECT"

cd "$MOCK_PROJECT"
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1

CONTENT=$(cat "$MOCK_PROJECT/.cursor/hooks.json")
assert_contains "$CONTENT" "beforeShellExecution"
assert_contains "$CONTENT" "afterShellExecution"
assert_contains "$CONTENT" "afterFileEdit"
assert_contains "$CONTENT" "stop"
test_pass

# =============================================================================
# Test: Preserves existing .cursor directory with other files
# =============================================================================
test_start "preserves existing files in .cursor directory"
MOCK_PROJECT="$TEST_TMP_DIR/project11"
create_mock_project "$MOCK_PROJECT"

# Create existing .cursor with some other files
mkdir -p "$MOCK_PROJECT/.cursor"
echo "existing content" > "$MOCK_PROJECT/.cursor/other-file.txt"

cd "$MOCK_PROJECT"
echo "y" | ./install-cursor-hooks.sh > /dev/null 2>&1

# Check our other file is preserved
assert_file_exists "$MOCK_PROJECT/.cursor/other-file.txt"
CONTENT=$(cat "$MOCK_PROJECT/.cursor/other-file.txt")
assert_equals "existing content" "$CONTENT"
test_pass
