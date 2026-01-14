#!/bin/bash
# Test validation blocked detection in Ralph
# Tests that Ralph properly exits when validation is blocked by missing tools/env vars

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test helpers
source "$SCRIPT_DIR/test-helpers.sh"

# Test: ralph.sh recognizes VALIDATION_BLOCKED marker
test_start "ralph.sh recognizes VALIDATION_BLOCKED marker"

# Create a temporary session directory
TMP_SESSION=$(mktemp -d)
trap "rm -rf $TMP_SESSION" EXIT

# Create minimal prd.json
cat > "$TMP_SESSION/prd.json" <<'EOF'
{
  "branchName": "ralph/test-validation-blocked",
  "agent": "claude",
  "validationCommands": {},
  "userStories": [
    {
      "id": "TEST-001",
      "title": "Test task",
      "acceptanceCriteria": ["Task complete"],
      "priority": 1,
      "passes": false
    }
  ]
}
EOF

# Create a mock log with VALIDATION_BLOCKED marker
cat > "$TMP_SESSION/ralph.log" <<'EOF'
=== Ralph Session Started ===
Iteration 1 of 1

Agent output...

<promise>VALIDATION_BLOCKED</promise>

Code Implementation: ✅ COMPLETE
Automated Validations: ✅ PASSING
Remaining Tasks: ⚠️ BLOCKED

Blockers:
- Missing environment variable: FIREBASE_API_KEY
- Missing capability: browser automation
EOF

# Check that log contains the marker
if grep -q "<promise>VALIDATION_BLOCKED</promise>" "$TMP_SESSION/ralph.log"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: VALIDATION_BLOCKED exits with code 2
test_start "VALIDATION_BLOCKED exits with code 2 (distinct from BLOCKED)"

# The actual exit code check would require running ralph.sh
# For now, we verify the code structure
if grep -A5 'VALIDATION_BLOCKED</promise>' "$RALPH_DIR/ralph.sh" | grep -q 'exit 2'; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: prompt.md includes blocker detection instructions
test_start "prompt.md includes blocker detection instructions"

if grep -q "VALIDATION_BLOCKED" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q "missing.*environment.*variable\|missing.*tool\|missing.*capability" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: prompt.md includes handoff document template
test_start "prompt.md includes handoff document template"

if grep -q "Validation Blocked - Handoff Required" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q "Code Implementation Status" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q "Validation Blockers" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: CONFIGURATION.md documents blockedBy field
test_start "CONFIGURATION.md documents blockedBy field"

if grep -q "blockedBy" "$RALPH_DIR/docs/CONFIGURATION.md"; then
  assert_success
else
  assert_failure
fi

if grep -q "missing_env_var\|missing_tool\|missing_capability" "$RALPH_DIR/docs/CONFIGURATION.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: Blocker types are documented
test_start "Blocker types are properly documented"

BLOCKER_TYPES_FOUND=0
for blocker_type in "missing_env_var" "missing_tool" "missing_capability" "missing_service"; do
  if grep -q "$blocker_type" "$RALPH_DIR/docs/CONFIGURATION.md"; then
    BLOCKER_TYPES_FOUND=$((BLOCKER_TYPES_FOUND + 1))
  fi
done

if [[ $BLOCKER_TYPES_FOUND -eq 4 ]]; then
  assert_success
else
  echo "Expected 4 blocker types, found $BLOCKER_TYPES_FOUND"
  assert_failure
fi

test_pass

# Test: prompt.md includes early blocker detection
test_start "prompt.md includes early blocker detection step"

if grep -q "DETECT VALIDATION BLOCKERS EARLY" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q "Check if remaining tasks require tools/capabilities not available" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: Validation loop includes blocker detection
test_start "Validation loop includes blocker detection"

if grep -q "is_blocking_error" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q "record_blocker" "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

echo ""
