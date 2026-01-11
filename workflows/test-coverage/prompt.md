# Test Coverage Workflow

You are working in the **test-coverage** workflow. Your goal is to incrementally improve test coverage by writing exactly **one meaningful test per iteration** until the target coverage is reached.

## Workflow-Specific Rules

### 1) Run Coverage First
At the start of each iteration, run the configured coverage command (from `prd.json.coverageCommand`) to identify uncovered code:
```bash
# Example (adjust based on your project)
pnpm test --coverage
# Or whatever is specified in prd.json.coverageCommand
```

Analyze the coverage report to identify the most **user-facing, important** uncovered behavior. Prioritize:
- Core business logic
- User-facing features
- Error handling paths users will encounter
- Edge cases that matter to users

**Avoid:**
- Coverage-only tests (tests that exist solely to hit lines without validating behavior)
- Internal implementation details that users never interact with
- Code that is legitimately not worth testing (e.g., trivial getters, framework boilerplate)

### 2) Write Exactly ONE Meaningful Test Per Iteration
**CRITICAL:** You must write exactly **one test** per iteration. This test should:
- Validate real user-facing behavior (not just "does this function return something")
- Have clear, descriptive test names that explain what behavior is being tested
- Include assertions that verify the behavior works correctly
- Cover edge cases or error conditions when relevant

**Good test example:**
```typescript
test('LoginForm submits credentials and handles invalid password error', async () => {
  // Test validates actual user behavior + error handling
});
```

**Bad test example:**
```typescript
test('formatDate returns a string', () => {
  // This just hits coverage without validating meaningful behavior
});
```

### 3) Re-run Coverage and Record Progress
After writing and running the test:
1. Re-run the coverage command
2. Record the **old coverage %** and **new coverage %** in `progress.txt`
3. Document what behavior you tested (not just "added test for X function")

**progress.txt entry format:**
```markdown
## [Date] - Coverage Improvement

Coverage: 67.2% → 68.5% (+1.3%)
Test added: User login with invalid password shows error message
File: apps/web/src/components/LoginForm.test.tsx
Validation: ALL PASSED
---
```

### 4) Commit Convention
Use the `test(<area>): <user-facing behavior>` commit format:

**Good commit messages:**
```
test(auth): validate login error message on invalid password
test(checkout): handle empty cart submission gracefully
test(api): return 404 when user not found
```

**Bad commit messages:**
```
test: add test for formatDate function
test: increase coverage
test: cover edge case
```

Include the story ID from `prd.json` if you want that invariant (e.g., `test(auth): [COV-000] validate login error`).

### 5) When Code Isn't Worth Testing
If you encounter code that is legitimately not worth testing (trivial code, framework boilerplate, etc.), you may use tool-specific ignore pragmas **sparingly**:

```typescript
/* istanbul ignore next */
// Or for other tools: /* c8 ignore next */
```

Document in your commit message and `progress.txt` why the code was excluded.

### 6) Stop Condition
Check `prd.json.coverageTarget` (default: 100). When the current coverage percentage is **greater than or equal to the target**:

1. Update `prd.json` and set the workflow story (`COV-000` or similar) to `passes: true`
2. Output the completion marker:
   ```
   <promise>COMPLETE</promise>
   ```
3. Do NOT continue writing more tests after reaching the target

**Example check:**
```bash
# If target is 85% and current coverage is 85.2%:
# → Set passes: true
# → Output <promise>COMPLETE</promise>
# → Stop
```

## Validation Commands
The `validationCommands` in `prd.json` should include your coverage command. Ralph will run these after each test, ensuring:
- The new test passes
- Coverage increases (or stays the same)
- No regressions

## Summary
1. Run coverage to find important uncovered behavior
2. Write **exactly one** meaningful test per iteration
3. Re-run coverage and record old/new % in `progress.txt`
4. Commit with `test(<area>): <behavior>` format
5. Stop when coverage ≥ target and output `<promise>COMPLETE</promise>`

Focus on **quality over quantity**: one well-written test that validates real user behavior is worth more than ten tests that just hit lines of code.
