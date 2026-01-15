# Troubleshooting

Common issues and solutions when using Ralph.

## Ralph Stuck on a Task

**Symptom:** Ralph keeps running the same task repeatedly.

**Possible causes:**
1. Validation command is failing
2. Task is too large (can't fit in one iteration)
3. Bug in the code that's not caught

**Solutions:**
- Check `progress.txt` for last learnings
- Review commits: `git log --oneline -10`
- Break task into smaller subtasks
- Check if validation command is correct
- Run validation manually: `pnpm typecheck && pnpm test`
- Manually fix the issue and mark task as `passes: true` in prd.json

## Validation Commands Failing

**Symptom:** Tasks fail at validation step with unclear errors.

**Solutions:**
```bash
# Run validation manually to see errors
pnpm typecheck
pnpm test

# Fix issues, then Ralph can continue
# Or update validationCommands in prd.json if commands are wrong
```

**Common issues:**
- Wrong command path (monorepo vs single package)
- Missing dependencies
- Pre-existing errors in codebase
- Timeout issues (add `timeout 120` for build commands)

## Branch Already Exists

**Symptom:** Ralph fails to create branch that already exists.

**Solution:**
```bash
# Delete existing branch
git branch -D ralph/your-feature

# Or checkout and work on it
git checkout ralph/your-feature
```

## Learnings Not Accumulating

**Symptom:** progress.txt doesn't update after tasks.

**Possible causes:**
1. Task failing at validation step (no commit = no update)
2. Ralph exiting early
3. File permissions issue

**Solutions:**
```bash
# Check if file is writable
test -w .ralph/sessions/my-feature/progress.txt && echo "writable" || echo "read-only"

# Check Ralph output for errors
tail -50 .ralph/sessions/my-feature/ralph.log
```

## Context Window Exhaustion

**Symptom:** Agent says "context too full" or similar.

**Solution:**
- Break tasks into smaller, more atomic units
- Focus on one specific change per task
- Use notes field to provide focused context

## Agent CLI Not Found

**Symptom:** "Warning: Claude CLI not found" or similar.

**Solutions:**
```bash
# Check if CLI is installed
which claude  # or codex, opencode, cursor

# Install missing CLI
# Claude: https://claude.ai/docs/cli
# Codex: npm install -g @openai/codex-cli
# OpenCode: npm install -g @opencode-ai/cli
# Cursor: https://cursor.com/docs/cli
```

## Lock File Issues

**Symptom:** "Ralph is already running" but process isn't actually running.

**Solution:**
```bash
# Remove stale lock file
rm .ralph/sessions/my-feature/.ralph.lock

# Or use --force flag
.ralph/ralph.sh --session my-feature --force
```

## Git Errors

**Symptom:** Branch checkout fails or commits fail.

**Solutions:**
```bash
# Check git status
git status

# Stash uncommitted changes
git stash

# Check if in git repository
git rev-parse --git-dir

# Fix git configuration if needed
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

## Session Not Found

**Symptom:** "Session not found: my-feature"

**Solutions:**
```bash
# Check if session exists
ls .ralph/sessions/

# Check if prd.json exists
ls .ralph/sessions/my-feature/prd.json

# Create session if missing
mkdir -p .ralph/sessions/my-feature
cp .ralph/examples/prd.json.example .ralph/sessions/my-feature/prd.json
```

## Tasks Not Progressing

**Symptom:** All tasks show `passes: false` but Ralph isn't working on them.

**Possible causes:**
1. All tasks marked as complete but validation failed
2. Ralph reached max iterations
3. Ralph is blocked
4. Validation requires human intervention (missing tools/env vars)

**Solutions:**
```bash
# Check task status
cat .ralph/sessions/my-feature/prd.json | jq '.userStories[] | {id, title, passes}'

# Check log for blockers
tail -100 .ralph/sessions/my-feature/ralph.log | grep -i "block\|error\|fail"

# Check for validation blocked status
tail -100 .ralph/sessions/my-feature/ralph.log | grep -i "VALIDATION_BLOCKED"

# Manually mark completed tasks
nano .ralph/sessions/my-feature/prd.json
# Set passes: true for completed tasks

# Continue Ralph
.ralph/ralph.sh 25 --session my-feature
```

## Validation Blocked (Code Complete, Needs Human)

**Symptom:** Ralph exits with "VALIDATION BLOCKED" message. Code is implemented but validation requires human intervention.

**What this means:**
- All code changes are complete and committed
- Automated validations (typecheck, lint, build) are passing
- Remaining tasks require missing tools, environment variables, or human capabilities

**Common blockers:**
1. Missing environment variables (e.g., `FIREBASE_API_KEY`)
2. Missing tools (e.g., browser automation, database access)
3. Tasks requiring human judgment (e.g., visual verification, UX testing)
4. External services not available in CI environment

**Solutions:**

1. **Check handoff document** in progress.txt:
```bash
cat .ralph/sessions/my-feature/progress.txt | grep -A 30 "Validation Blocked - Handoff Required"
```

2. **Review blockers** listed in the handoff document

3. **Resolve blockers:**
```bash
# For missing env vars
export FIREBASE_API_KEY="your-key-here"

# For missing tools
npm install -g playwright  # or other required tool

# For human verification tasks
# Open browser and manually verify the changes work as expected
```

4. **Mark validated tasks as complete:**
```json
{
  "id": "TASK-001",
  "passes": true,
  "blockedBy": null  // Remove blocker after resolving
}
```

5. **Continue or mark session complete:**
```bash
# If more work needed
.ralph/ralph.sh 5 --session my-feature

# If all tasks are verified, manually mark remaining tasks as complete
```

**Exit codes:**
- Exit 0: Session complete (all tasks passed)
- Exit 1: Blocked (cannot progress)
- Exit 2: Validation blocked (code complete, needs human)

## Build Timeout Issues

**Symptom:** Build commands hang indefinitely.

**Solution:**
Add timeout to build command in prd.json:

```json
{
  "validationCommands": {
    "build": "timeout 120 pnpm build"
  }
}
```

## Permission Denied

**Symptom:** "Permission denied" when running scripts.

**Solution:**
```bash
# Make scripts executable
chmod +x .ralph/ralph.sh
chmod +x .ralph/status.sh
chmod +x .ralph/stop.sh
chmod +x .ralph/runners/*.sh
```

## jq Not Found

**Symptom:** Warnings about jq but Ralph still works.

**Solution:**
```bash
# Install jq (optional but recommended)
# macOS
brew install jq

# Linux
sudo apt-get install jq  # Debian/Ubuntu
sudo yum install jq      # RHEL/CentOS

# Or continue without jq (Ralph falls back to grep/sed)
```

## Getting Help

If you're still stuck:

1. Check the log: `tail -100 .ralph/sessions/my-feature/ralph.log`
2. Review commits: `git log --oneline`
3. Check status: `.ralph/status.sh --session my-feature`
4. Review documentation: See [USAGE.md](USAGE.md) and [WRITING-PRDS.md](WRITING-PRDS.md)
