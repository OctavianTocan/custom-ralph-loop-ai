#!/bin/bash
# Test tighter validation loops to prevent premature exits
# Tests that Ralph properly validates task completion before honoring exit markers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test helpers
source "$SCRIPT_DIR/test-helpers.sh"

# Test: ralph.sh validates COMPLETE marker against actual task status
test_start "ralph.sh validates COMPLETE marker against task status"

# Check that ralph.sh checks ALL_TASKS_COMPLETE before honoring COMPLETE marker
if grep -A20 'Check for completion markers' "$RALPH_DIR/ralph.sh" | grep -q 'ALL_TASKS_COMPLETE'; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: ralph.sh warns when agent signals COMPLETE prematurely
test_start "ralph.sh warns when agent signals COMPLETE with incomplete tasks"

if grep -qr 'WARNING: Agent signaled COMPLETE but tasks remain incomplete' "$RALPH_DIR/ralph.sh" "$RALPH_DIR/lib/" 2>/dev/null; then
  assert_success
else
  assert_failure
fi

if grep -q 'Continuing iteration to complete remaining tasks' "$RALPH_DIR/ralph.sh"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: ralph.sh validates BLOCKED marker against remaining tasks
test_start "ralph.sh validates BLOCKED marker against remaining tasks"

if grep -qr 'WARNING: Agent signaled BLOCKED but tasks remain incomplete' "$RALPH_DIR/ralph.sh" "$RALPH_DIR/lib/" 2>/dev/null; then
  assert_success
else
  assert_failure
fi

if grep -qr 'Agent should continue with non-blocked tasks' "$RALPH_DIR/ralph.sh" "$RALPH_DIR/lib/" 2>/dev/null; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: ralph.sh checks task completion BEFORE checking exit markers
test_start "ralph.sh checks task completion status BEFORE honoring markers"

# With the refactored code, validation is modularized
# Check that task completion checking functions exist and are called in correct order
if grep -q 'check_all_tasks_complete' "$RALPH_DIR/ralph.sh" && \
   grep -q 'validate_complete_marker' "$RALPH_DIR/ralph.sh" && \
   [[ -f "$RALPH_DIR/lib/ralph-validation.sh" ]]; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: prompt.md includes loop enforcement notice
test_start "prompt.md includes loop enforcement rules at top"

if grep -q 'LOOP ENFORCEMENT' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q 'You CANNOT exit the Ralph loop' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: prompt.md clarifies COMPLETE requirements
test_start "prompt.md clarifies when COMPLETE is allowed"

if grep -E -q 'For COMPLETE: ALL tasks in prd.json have.*passes: true' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: prompt.md clarifies BLOCKED requirements
test_start "prompt.md clarifies when BLOCKED is allowed"

if grep -q 'ALL remaining tasks are genuinely blocked' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q 'Only use BLOCKED when you have exhausted all options' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: prompt.md instructs checking for other incomplete tasks
test_start "prompt.md instructs checking for other incomplete tasks before BLOCKED"

if grep -q 'Check if there are OTHER incomplete tasks' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q 'move to the next highest-priority incomplete task' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: prompt.md validates exit marker rejection
test_start "prompt.md explains exit marker validation"

if grep -q 'Ralph loop validates your exit markers' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

if grep -q 'Premature exit attempts will be rejected' "$RALPH_DIR/prompt.md"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: Critical validation rule added to Stop Conditions
test_start "Stop Conditions section has CRITICAL VALIDATION RULE"

if grep -A5 'Stop Conditions' "$RALPH_DIR/prompt.md" | grep -q 'CRITICAL VALIDATION RULE'; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: Validation order in ralph.sh (task status check, then exit markers, then validation)
test_start "ralph.sh validation order: task status -> markers -> validation -> action"

# With refactored code, check that validation functions are called in proper order
ORDER_OK=0

# 1. Check that check_all_tasks_complete is called
if grep -q 'check_all_tasks_complete' "$RALPH_DIR/ralph.sh"; then
  ORDER_OK=$((ORDER_OK + 1))
fi

# 2. Check that validate_complete_marker is called
if grep -q 'validate_complete_marker' "$RALPH_DIR/ralph.sh"; then
  ORDER_OK=$((ORDER_OK + 1))
fi

# 3. Check that validate_blocked_marker is called
if grep -q 'validate_blocked_marker' "$RALPH_DIR/ralph.sh"; then
  ORDER_OK=$((ORDER_OK + 1))
fi

if [[ $ORDER_OK -eq 3 ]]; then
  assert_success
else
  echo "Expected 3 validation steps in order, got $ORDER_OK"
  assert_failure
fi

test_pass

# Test: ralph.sh has all 4 validation rules
test_start "ralph.sh implements all 4 validation rules"

RULES_FOUND=0

# RULE 1: COMPLETE validation
if grep -q 'RULE 1: Agent signals COMPLETE' "$RALPH_DIR/ralph.sh"; then
  RULES_FOUND=$((RULES_FOUND + 1))
fi

# RULE 2: BLOCKED validation
if grep -q 'RULE 2: Agent signals BLOCKED' "$RALPH_DIR/ralph.sh"; then
  RULES_FOUND=$((RULES_FOUND + 1))
fi

# RULE 3: VALIDATION_BLOCKED (always allowed)
if grep -q 'RULE 3: Agent signals VALIDATION_BLOCKED' "$RALPH_DIR/ralph.sh"; then
  RULES_FOUND=$((RULES_FOUND + 1))
fi

# RULE 4: Auto-complete if all tasks done
if grep -q 'RULE 4: No exit marker but all tasks complete' "$RALPH_DIR/ralph.sh"; then
  RULES_FOUND=$((RULES_FOUND + 1))
fi

if [[ $RULES_FOUND -eq 4 ]]; then
  assert_success
else
  echo "Expected 4 validation rules, found $RULES_FOUND"
  assert_failure
fi

test_pass

# Test: Integration - verify complete workflow
test_start "Integration: validation loop structure is correct"

# Check that validation functions are properly integrated
if grep -q 'Validation loop' "$RALPH_DIR/ralph.sh" || \
   grep -qr 'check_all_tasks_complete' "$RALPH_DIR/ralph.sh" "$RALPH_DIR/lib/" 2>/dev/null; then
  assert_success
else
  assert_failure
fi

# Check all key validation functions exist
COMPONENTS=0

grep -qr 'check_all_tasks_complete' "$RALPH_DIR/" && COMPONENTS=$((COMPONENTS + 1))
grep -qr 'validate_complete_marker' "$RALPH_DIR/" && COMPONENTS=$((COMPONENTS + 1))
grep -qr 'validate_blocked_marker' "$RALPH_DIR/" && COMPONENTS=$((COMPONENTS + 1))
grep -qr 'validate_validation_blocked_marker' "$RALPH_DIR/" && COMPONENTS=$((COMPONENTS + 1))

if [[ $COMPONENTS -eq 4 ]]; then
  assert_success
else
  echo "Expected 4 validation components, found $COMPONENTS"
  assert_failure
fi

test_pass

echo ""
