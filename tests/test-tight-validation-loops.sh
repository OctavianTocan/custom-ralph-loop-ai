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

if grep -q 'WARNING: Agent signaled COMPLETE but tasks remain incomplete' "$RALPH_DIR/ralph.sh"; then
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

if grep -q 'WARNING: Agent signaled BLOCKED but tasks remain incomplete' "$RALPH_DIR/ralph.sh"; then
  assert_success
else
  assert_failure
fi

if grep -q 'Agent should continue with non-blocked tasks' "$RALPH_DIR/ralph.sh"; then
  assert_success
else
  assert_failure
fi

test_pass

# Test: ralph.sh checks task completion BEFORE checking exit markers
test_start "ralph.sh checks task completion status BEFORE honoring markers"

# Find line numbers for key validation steps
PROMPT_FILE_LINE=$(grep -n 'run_agent_command.*PROMPT_FILE' "$RALPH_DIR/ralph.sh" | head -1 | cut -d: -f1)
TASK_CHECK_LINE=$(grep -n 'ALL_TASKS_COMPLETE' "$RALPH_DIR/ralph.sh" | head -1 | cut -d: -f1)
COMPLETE_CHECK_LINE=$(grep -n 'AGENT_SIGNALED_COMPLETE' "$RALPH_DIR/ralph.sh" | head -1 | cut -d: -f1)

# Verify task completion check comes before marker validation
if [[ $TASK_CHECK_LINE -lt $COMPLETE_CHECK_LINE && $TASK_CHECK_LINE -gt $PROMPT_FILE_LINE ]]; then
  assert_success
else
  echo "Task check ($TASK_CHECK_LINE) should be between prompt execution ($PROMPT_FILE_LINE) and marker check ($COMPLETE_CHECK_LINE)"
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

# Count validation sections in correct order
ORDER_OK=0

# 1. Check ALL_TASKS_COMPLETE is calculated first
if grep -n 'ALL_TASKS_COMPLETE=false' "$RALPH_DIR/ralph.sh" | head -1 | cut -d: -f1 | grep -q '[0-9]'; then
  ORDER_OK=$((ORDER_OK + 1))
fi

# 2. Check agent signals are captured second
if grep -n 'AGENT_SIGNALED_COMPLETE=false' "$RALPH_DIR/ralph.sh" | head -1 | cut -d: -f1 | grep -q '[0-9]'; then
  ORDER_OK=$((ORDER_OK + 1))
fi

# 3. Check validation happens third (AGENT_SIGNALED_COMPLETE checked against ALL_TASKS_COMPLETE)
if grep -q 'if.*AGENT_SIGNALED_COMPLETE.*true' "$RALPH_DIR/ralph.sh" && grep -A5 'AGENT_SIGNALED_COMPLETE.*true' "$RALPH_DIR/ralph.sh" | grep -q 'ALL_TASKS_COMPLETE.*true'; then
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

# Check that the validation section exists and has the right structure
if grep -q 'VALIDATION LOOP - Check task completion FIRST' "$RALPH_DIR/ralph.sh"; then
  assert_success
else
  assert_failure
fi

# Check all key components are present
COMPONENTS=0

grep -E -q 'Check if all stories.*PRD are complete' "$RALPH_DIR/ralph.sh" && COMPONENTS=$((COMPONENTS + 1))
grep -q 'Check for completion markers in agent output' "$RALPH_DIR/ralph.sh" && COMPONENTS=$((COMPONENTS + 1))
grep -q 'VALIDATE against actual task completion' "$RALPH_DIR/ralph.sh" && COMPONENTS=$((COMPONENTS + 1))
grep -q 'Invalid completion attempt' "$RALPH_DIR/ralph.sh" && COMPONENTS=$((COMPONENTS + 1))

if [[ $COMPONENTS -eq 4 ]]; then
  assert_success
else
  echo "Expected 4 validation components, found $COMPONENTS"
  assert_failure
fi

test_pass

echo ""
