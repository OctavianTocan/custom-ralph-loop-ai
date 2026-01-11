# Examples

This guide provides real-world examples showing how to use Ralph workflows from start to finish.

## Example 1: Improving Test Coverage on a New Project

You have a React component library with 45% test coverage and want to get to 85%.

### Step 1: Create the Session

```bash
mkdir -p .ralph/sessions/coverage-sprint
cp .ralph/examples/prd.test-coverage.example .ralph/sessions/coverage-sprint/prd.json
```

### Step 2: Configure the PRD

Edit `.ralph/sessions/coverage-sprint/prd.json`:

```json
{
  "branchName": "ralph/test-coverage",
  "workflow": "test-coverage",
  "agent": "claude",
  "model": "sonnet",
  "coverageCommand": "pnpm test --coverage",
  "coverageTarget": 85,
  "validationCommands": {
    "test": "pnpm test --coverage"
  },
  "userStories": [
    {
      "id": "COV-000",
      "title": "Improve test coverage to 85%",
      "acceptanceCriteria": [
        "Run coverage command to identify uncovered user-facing behavior",
        "Write exactly ONE meaningful test per iteration (not coverage-only tests)",
        "Test validates real user behavior with clear assertions",
        "Re-run coverage after test and record old/new % in progress.txt",
        "Commit with format: test(<area>): <user-facing behavior>",
        "When coverage >= target, set passes: true and output <promise>COMPLETE</promise>",
        "Do NOT continue after reaching target"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Focus on quality: one well-written test validating real behavior is worth more than ten tests that just hit lines."
    }
  ]
}
```

### Step 3: Check Current Coverage

```bash
pnpm test --coverage
# Output: 45.32% coverage
```

### Step 4: Run Ralph

```bash
.ralph/ralph.sh 25 --session coverage-sprint --workflow test-coverage
```

**What Ralph does:**
1. Runs coverage command
2. Identifies uncovered user-facing behavior (e.g., "Button onClick handler not tested")
3. Writes ONE meaningful test
4. Re-runs coverage (now 48.15%)
5. Records in progress.txt: "Coverage: 45.32% → 48.15%"
6. Commits: `test(button): validate onClick handler triggers callback`
7. Repeats...

### Step 5: Monitor Progress

```bash
# Watch log in real-time
tail -f .ralph/sessions/coverage-sprint/ralph.log

# Check coverage progress
cat .ralph/sessions/coverage-sprint/progress.txt | grep "Coverage:"

# View test commits
git log --oneline --grep="^test"
```

### Step 6: Review Results

```bash
# Checkout the branch
git checkout ralph/test-coverage

# View all test commits
git log --oneline --all --grep="^test"

# Example output:
# 5a3f2b1 test(button): validate onClick handler triggers callback
# 7c9d4e2 test(input): verify value updates on user typing
# 2f8a1c3 test(modal): confirm close button hides modal
# ...

# Check final coverage
pnpm test --coverage
# Output: 85.42% coverage ✓
```

### Expected Outcome

- **Start:** 45% coverage
- **End:** 85%+ coverage
- **Commits:** ~15-20 test commits (one per iteration)
- **Time:** ~2-3 hours of autonomous work
- **Quality:** Each test validates real user behavior, not just line coverage

---

## Example 2: Incremental Test Coverage on Existing Codebase

You're working on a large Express API with 60% coverage. You want to improve specific areas.

### Step 1: Focus on a Specific Area

Instead of improving all coverage, target a specific module:

```bash
mkdir -p .ralph/sessions/auth-coverage
cp .ralph/examples/prd.test-coverage.example .ralph/sessions/auth-coverage/prd.json
```

### Step 2: Configure for Specific Module

Edit `.ralph/sessions/auth-coverage/prd.json`:

```json
{
  "branchName": "ralph/auth-test-coverage",
  "workflow": "test-coverage",
  "agent": "claude",
  "model": "sonnet",
  "coverageCommand": "pnpm test -- src/auth --coverage",
  "coverageTarget": 90,
  "validationCommands": {
    "test": "pnpm test -- src/auth --coverage",
    "typecheck": "pnpm typecheck"
  },
  "userStories": [
    {
      "id": "COV-AUTH",
      "title": "Improve auth module test coverage to 90%",
      "acceptanceCriteria": [
        "Run coverage command to identify uncovered user-facing behavior",
        "Write exactly ONE meaningful test per iteration",
        "Test validates real user behavior with clear assertions",
        "Re-run coverage after test and record old/new % in progress.txt",
        "Commit with format: test(auth): <user-facing behavior>",
        "When coverage >= target, set passes: true and output <promise>COMPLETE</promise>"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Focus on auth module only. Each test should validate security-critical behavior like token validation, permission checks, or password hashing."
    }
  ]
}
```

### Step 3: Run with Specific Target

```bash
.ralph/ralph.sh 15 --session auth-coverage --workflow test-coverage
```

### Expected Test Commits

```text
test(auth): verify JWT token expiration rejects old tokens
test(auth): confirm invalid passwords fail authentication
test(auth): validate refresh token rotation on reuse
test(auth): ensure unauthorized users cannot access protected routes
test(auth): verify password reset tokens expire after use
```

---

## Example 3: Daily Test Coverage Improvement Routine

Set up a recurring workflow to improve coverage a little each day.

### Step 1: Create Reusable Session

```bash
mkdir -p .ralph/sessions/daily-coverage
cat > .ralph/sessions/daily-coverage/prd.json << 'EOF'
{
  "branchName": "ralph/daily-coverage",
  "workflow": "test-coverage",
  "agent": "claude",
  "model": "sonnet",
  "coverageCommand": "pnpm test --coverage",
  "coverageTarget": 80,
  "validationCommands": {
    "test": "pnpm test --coverage"
  },
  "userStories": [
    {
      "id": "COV-DAILY",
      "title": "Daily test coverage improvement",
      "acceptanceCriteria": [
        "Run coverage command to identify uncovered user-facing behavior",
        "Write exactly ONE meaningful test per iteration",
        "Test validates real user behavior with clear assertions",
        "Re-run coverage after test and record old/new % in progress.txt",
        "Commit with format: test(<area>): <user-facing behavior>",
        "When coverage >= target, set passes: true and output <promise>COMPLETE</promise>"
      ],
      "priority": 1,
      "passes": false
    }
  ]
}
EOF
```

### Step 2: Run Short Sessions Daily

```bash
# Morning: 5 iterations (~15 minutes)
.ralph/ralph.sh 5 --session daily-coverage --workflow test-coverage

# Evening: 5 more iterations
.ralph/ralph.sh 5 --session daily-coverage --workflow test-coverage
```

### Step 3: Reset for Next Day (Optional)

If you want to start fresh each day:

```bash
# Merge yesterday's tests
git checkout main
git merge ralph/daily-coverage

# Reset the session
rm .ralph/sessions/daily-coverage/progress.txt
rm .ralph/sessions/daily-coverage/learnings.md
# Edit prd.json to set passes: false
```

---

## Example 4: Testing CI/CD Integration

Use the test-coverage workflow in your CI pipeline.

### Step 1: Create CI Config

`.github/workflows/improve-coverage.yml`:

```yaml
name: Improve Test Coverage

on:
  schedule:
    - cron: '0 2 * * *'  # Run nightly at 2 AM
  workflow_dispatch:     # Allow manual trigger

jobs:
  improve-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: pnpm install
      
      - name: Setup Ralph
        run: |
          mkdir -p .ralph/sessions/ci-coverage
          cp examples/prd.test-coverage.example .ralph/sessions/ci-coverage/prd.json
      
      - name: Run Ralph coverage improvement
        run: |
          .ralph/ralph.sh 10 --session ci-coverage --workflow test-coverage
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          branch: ralph/nightly-coverage
          title: 'test: improve test coverage (automated)'
          body: |
            Automated test coverage improvement via Ralph workflow.
            
            See commits for specific tests added.
          commit-message: 'test: automated coverage improvement'
```

---

## Example 5: Team Workflow - Coverage Sprint

Your team dedicates a sprint to improving test coverage.

### Team Setup

Each developer takes a different module:

**Developer A (Frontend Components):**
```bash
mkdir -p .ralph/sessions/ui-coverage
# Configure coverageCommand: "pnpm test -- src/components --coverage"
# coverageTarget: 85
.ralph/ralph.sh 20 --session ui-coverage --workflow test-coverage
```

**Developer B (API Routes):**
```bash
mkdir -p .ralph/sessions/api-coverage
# Configure coverageCommand: "pnpm test -- src/api --coverage"
# coverageTarget: 90
.ralph/ralph.sh 20 --session api-coverage --workflow test-coverage
```

**Developer C (Utilities):**
```bash
mkdir -p .ralph/sessions/utils-coverage
# Configure coverageCommand: "pnpm test -- src/utils --coverage"
# coverageTarget: 95
.ralph/ralph.sh 20 --session utils-coverage --workflow test-coverage
```

### Merge Strategy

Each developer reviews their generated tests, then creates PRs:

```bash
# Review tests
git checkout ralph/ui-coverage
git log --oneline

# Create PR
gh pr create --base main --head ralph/ui-coverage \
  --title "test: improve UI component coverage to 85%" \
  --body "Automated via Ralph test-coverage workflow. See individual commits for test details."
```

---

## Example 6: Custom Coverage Reporting

Enhance the workflow with custom coverage tracking.

### Step 1: Add Coverage Tracking Script

`scripts/track-coverage.sh`:

```bash
#!/bin/bash
OUTPUT=$(pnpm test --coverage 2>&1)
COVERAGE=$(echo "$OUTPUT" | grep "All files" | awk '{print $10}')
echo "$(date '+%Y-%m-%d %H:%M:%S'): $COVERAGE" >> .ralph/sessions/coverage-history.log
echo "$COVERAGE"
```

### Step 2: Update PRD

```json
{
  "coverageCommand": "./scripts/track-coverage.sh",
  "coverageTarget": 85,
  ...
}
```

### Step 3: Visualize Progress

```bash
# View coverage over time
cat .ralph/sessions/coverage-history.log

# Output:
# 2026-01-10 09:00:00: 45.32%
# 2026-01-10 09:15:00: 48.51%
# 2026-01-10 09:30:00: 51.23%
# ...
# 2026-01-10 14:45:00: 85.12%
```

---

## Common Patterns

### Pattern 1: Verify Before Committing

Before running Ralph overnight, do a short trial:

```bash
# Trial run: 3 iterations
.ralph/ralph.sh 3 --session coverage-sprint --workflow test-coverage

# Review generated tests
git log --oneline -3

# If quality looks good, run full session
.ralph/ralph.sh 25 --session coverage-sprint --workflow test-coverage
```

### Pattern 2: Focus on Critical Paths First

Prioritize high-value areas:

```bash
# Session 1: Auth (security-critical)
.ralph/ralph.sh 10 --session auth-coverage --workflow test-coverage

# Session 2: Payment (business-critical)
.ralph/ralph.sh 10 --session payment-coverage --workflow test-coverage

# Session 3: UI (user-facing)
.ralph/ralph.sh 10 --session ui-coverage --workflow test-coverage
```

### Pattern 3: Stop and Review Frequently

For sensitive codebases:

```bash
# Run 5 iterations
.ralph/ralph.sh 5 --session coverage --workflow test-coverage

# Review tests
git log --oneline -5

# Continue if satisfied
.ralph/ralph.sh 5 --session coverage --workflow test-coverage
```

---

## Troubleshooting Examples

### Issue: Coverage Not Increasing

**Symptom:** Ralph writes tests but coverage stays the same.

**Solution:** Check if tests are actually running:

```bash
# Verify coverage command works
pnpm test --coverage

# Check if new tests are included
pnpm test -- path/to/new/test.spec.ts

# Update PRD if needed
nano .ralph/sessions/coverage/prd.json
# Add to validationCommands:
# "test": "pnpm test --coverage --run"
```

### Issue: Tests Too Simple

**Symptom:** Ralph writes tests like `expect(true).toBe(true)`.

**Solution:** Update the workflow notes in your PRD:

```json
{
  "userStories": [
    {
      "notes": "CRITICAL: Do NOT write trivial tests. Each test must validate REAL user-facing behavior with meaningful assertions. Examples of BAD tests: expect(true).toBe(true), expect(component).toBeDefined(). Examples of GOOD tests: expect(button.onclick()).toHaveBeenCalledWith(expectedData), expect(api.response).toEqual({status: 200, data: [...]})"
    }
  ]
}
```

### Issue: Workflow Stops Early

**Symptom:** Ralph marks task complete before reaching target.

**Solution:** Ensure COV-000 story has `passes: false` and workflow enforces continuation:

```json
{
  "userStories": [
    {
      "id": "COV-000",
      "passes": false,
      "acceptanceCriteria": [
        "When coverage >= target, set passes: true and output <promise>COMPLETE</promise>",
        "Do NOT continue after reaching target"
      ]
    }
  ]
}
```

---

## See Also

- [USAGE.md](USAGE.md) - Complete usage guide
- [CONFIGURATION.md](CONFIGURATION.md) - PRD configuration reference
- [WRITING-PRDS.md](WRITING-PRDS.md) - How to write effective PRDs
