# Usage Guide

Complete guide for using Ralph in your projects.

## Creating a Session

### Option A: Using `/ralph:setup` Command (Recommended)

If you installed the commands (see [INSTALLATION.md](INSTALLATION.md)):

```
/ralph:setup "Add user authentication system"
```

This will:
1. Search `docs/solutions/` for relevant patterns (if it exists)
2. Ask clarifying questions about the feature
3. Help break down tasks into atomic, measurable items
4. Create a session directory with `prd.json`, `progress.txt`, and `learnings.md`

### Option B: Manual Creation

```bash
# Create session directory
mkdir -p .ralph/sessions/my-feature

# Copy example PRD
cp .ralph/examples/prd.json.example .ralph/sessions/my-feature/prd.json

# Edit prd.json with your tasks
nano .ralph/sessions/my-feature/prd.json
```

**Note:** If you used `/ralph:setup`, the session files (`progress.txt` and `learnings.md`) are created automatically. You only need to initialize them manually if creating sessions without the command.

## Running Ralph

### Basic Usage

```bash
# Direct script usage
.ralph/ralph.sh 25 --session my-feature

# With package.json script
pnpm ralph 25 --session my-feature

# Using command (if installed)
/ralph:run my-feature 25
```

### Arguments

- `[iterations]` - Maximum number of iterations (default: 10)
- `--session <name>` - Session name (required)
- `--workflow <name>` - Workflow to use (optional, can also be specified in prd.json)
- `--force` - Force run even if another instance is running

### Examples

```bash
# Run 25 iterations on my-feature session
.ralph/ralph.sh 25 --session my-feature

# Run with default 10 iterations
.ralph/ralph.sh --session my-feature

# Run with test-coverage workflow
.ralph/ralph.sh 25 --session my-feature --workflow test-coverage

# Force run (overrides lock)
.ralph/ralph.sh --session my-feature --force
```

## Monitoring Progress

### Check Status

```bash
# Using script
.ralph/status.sh

# With package.json
pnpm ralph:status

# Check specific session
.ralph/status.sh --session my-feature
```

Shows:
- Running processes (Ralph loop, agent)
- Current session
- Progress (completed/total tasks)
- Current task being worked on
- Recent log entries

### Watch Logs

```bash
# Watch real-time log
tail -f .ralph/sessions/my-feature/ralph.log

# View last 50 lines
tail -50 .ralph/sessions/my-feature/ralph.log
```

### View Learnings

```bash
# View accumulated learnings
cat .ralph/sessions/my-feature/learnings.md

# Watch learnings accumulate
tail -f .ralph/sessions/my-feature/learnings.md
```

### View Progress

```bash
# View codebase patterns and progress
cat .ralph/sessions/my-feature/progress.txt

# Watch progress accumulate
tail -f .ralph/sessions/my-feature/progress.txt
```

## Stopping Ralph

### Graceful Stop

```bash
# Using script
.ralph/stop.sh

# With package.json
pnpm ralph:stop

# Stop specific session
.ralph/stop.sh --session my-feature
```

### Force Stop

```bash
# Find Ralph process
ps aux | grep ralph.sh

# Kill process
kill <PID>

# Or kill all Ralph processes
.ralph/stop.sh
```

## Reviewing Results

After Ralph completes:

```bash
# Checkout the feature branch
git checkout ralph/your-feature-name

# Review commits
git log --oneline

# View commit details
git show <commit-hash>

# View learnings from this session
cat .ralph/sessions/my-feature/learnings.md

# View final compound documentation (if /compound was invoked)
ls docs/solutions/

# Verify validation passes
pnpm typecheck
pnpm test
```

## Session Management

### List Sessions

```bash
ls .ralph/sessions/
```

### View Session PRD

```bash
cat .ralph/sessions/my-feature/prd.json | jq '.userStories[] | {id, title, passes}'
```

### Edit Session PRD

```bash
nano .ralph/sessions/my-feature/prd.json
```

### Resume Incomplete Session

If Ralph stopped before completing all tasks:

```bash
# Just run again - Ralph will pick up where it left off
.ralph/ralph.sh 25 --session my-feature
```

Ralph reads `prd.json` and only works on tasks where `passes: false`.

## Using Workflows

### Test Coverage Workflow

The `test-coverage` workflow helps you incrementally improve test coverage by writing exactly one meaningful test per iteration.

**Setup:**

1. Copy the example PRD:
```bash
cp .ralph/examples/prd.test-coverage.example .ralph/sessions/my-coverage/prd.json
```

2. Edit the PRD to configure your coverage command and target:
```json
{
  "workflow": "test-coverage",
  "coverageCommand": "pnpm test --coverage",
  "coverageTarget": 85,
  "validationCommands": {
    "test": "pnpm test --coverage"
  }
}
```

3. Run Ralph with the workflow:
```bash
.ralph/ralph.sh 25 --session my-coverage --workflow test-coverage
```

**How it works:**
- Each iteration, Ralph runs your coverage command to find uncovered user-facing behavior
- Writes exactly ONE meaningful test (not coverage-only tests)
- Re-runs coverage and records old/new % in progress.txt
- Commits with format: `test(<area>): <user-facing behavior>`
- Stops automatically when coverage ≥ target

**Note:** The workflow enforces quality over quantity. One well-written test that validates real user behavior is worth more than ten tests that just hit lines of code.

### Custom Workflows

You can create custom workflows by adding a prompt file:

```bash
mkdir -p .ralph/workflows/my-workflow
echo "# My Workflow Instructions" > .ralph/workflows/my-workflow/prompt.md
```

Then run with `--workflow my-workflow`.

## Common Workflows

### Starting a New Feature

```bash
# 1. Create session
/ralph:setup "Add user profile page"

# 2. Review generated PRD
cat .ralph/sessions/my-feature/prd.json

# 3. Edit if needed
nano .ralph/sessions/my-feature/prd.json

# 4. Run Ralph
.ralph/ralph.sh 25 --session my-feature

# 5. Monitor progress
tail -f .ralph/sessions/my-feature/ralph.log
```

### Continuing Existing Session

```bash
# Check status
.ralph/status.sh --session my-feature

# Continue from where it left off
.ralph/ralph.sh 25 --session my-feature
```

### Debugging Failed Task

```bash
# View log for errors
tail -100 .ralph/sessions/my-feature/ralph.log

# Check what was attempted
git log --oneline -5

# Manually fix the issue
# Then mark task as complete in prd.json
nano .ralph/sessions/my-feature/prd.json
# Set passes: true for the failed task

# Continue Ralph
.ralph/ralph.sh 25 --session my-feature
```

## Best Practices

1. **Start small**: First session should be 3-5 tasks
2. **Monitor first run**: Watch logs to understand Ralph's behavior
3. **Review commits**: Always review what Ralph did before merging
4. **Use learnings**: Read `learnings.md` to understand patterns discovered
5. **Break down tasks**: If tasks are too large, split them in the PRD

## See Also

- [WRITING-PRDS.md](WRITING-PRDS.md) - How to create effective PRDs
- [CONFIGURATION.md](CONFIGURATION.md) - PRD structure and options
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
