# Ralph Wiggum - Autonomous AI Coding Loop

Ralph is an autonomous AI coding system that implements features while you sleep. Each task is completed, validated, committed, and then Ralph moves to the next task — all without human intervention.

## Quick Start

```bash
# 1. Install
cp -r ralph/ .ralph/
chmod +x .ralph/ralph.sh .ralph/status.sh .ralph/stop.sh .ralph/runners/*.sh

# 2. Install commands (optional)
cp ralph/commands/ralph:setup.md .claude/commands/  # Claude Code
# Or: cp ralph/commands/ralph:setup.md .cursor/commands/  # Cursor

# 3. Create session
/ralph:setup "Add user authentication system"

# 4. Run Ralph
.ralph/ralph.sh 25 --session my-feature

# 5. Review results
git checkout ralph/your-feature
git log --oneline
```

## How It Works

Ralph runs iteratively with fresh context windows for each task, persisting memory through:
- **Git commits** — Each completed task is atomically committed
- **progress.txt** — Accumulated codebase patterns and gotchas
- **learnings.md** — Structured lessons from each task (prevents trial-and-error)
- **prd.json** — Task status, updated in real-time

**The Loop:**
1. Read session files (prd.json, progress.txt, learnings.md)
2. Pick highest-priority incomplete task
3. Implement with fresh context
4. Run ALL validation commands (typecheck, lint, test, build)
5. Retry up to 5 times if validation fails
6. Commit if all validations pass
7. Append learning to learnings.md
8. Update prd.json status
9. Repeat until complete

See [docs/USAGE.md](docs/USAGE.md) for detailed workflow.

## Installation

### Requirements

- **Bash** (macOS, Linux, WSL)
- **Git** (for branch management and commits)
- **jq** (optional, for JSON parsing)
- **AI Agent CLI**: `claude`, `codex`, `opencode`, or `cursor`

### Steps

1. **Copy Ralph to your project:**
   ```bash
   cp -r ralph/ .ralph/
   chmod +x .ralph/ralph.sh .ralph/status.sh .ralph/stop.sh .ralph/runners/*.sh
   ```

2. **Add to package.json (optional):**
   ```json
   {
     "scripts": {
       "ralph": ".ralph/ralph.sh",
       "ralph:status": ".ralph/status.sh",
       "ralph:stop": ".ralph/stop.sh"
     }
   }
   ```

3. **Install commands (optional):**
   ```bash
   # For Claude Code
   cp ralph/commands/ralph:setup.md .claude/commands/
   cp ralph/commands/ralph:run.md .claude/commands/
   
   # For Cursor
   cp ralph/commands/ralph:setup.md .cursor/commands/
   cp ralph/commands/ralph:run.md .cursor/commands/
   ```

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for detailed installation guide.

## Usage

### Create a Session

**Option A: Using `/ralph:setup` command (recommended)**
```
/ralph:setup "Add user authentication system"
```

**Option B: Manual creation**
```bash
mkdir -p .ralph/sessions/my-feature
cp .ralph/examples/prd.json.example .ralph/sessions/my-feature/prd.json
# Edit prd.json with your tasks
```

### Run Ralph

```bash
# Direct usage
.ralph/ralph.sh 25 --session my-feature

# Or with package.json script
pnpm ralph 25 --session my-feature

# Or using command
/ralph:run my-feature 25
```

### Monitor Progress

```bash
# Check status
.ralph/status.sh

# Watch log
tail -f .ralph/sessions/my-feature/ralph.log

# View learnings
cat .ralph/sessions/my-feature/learnings.md
```

### Stop Ralph

```bash
.ralph/stop.sh
# Or: pnpm ralph:stop
```

See [docs/USAGE.md](docs/USAGE.md) for complete usage guide.

## Writing Good PRDs

### Task Sizing

✅ **Right size** (5-15 minutes):
- Single component (e.g., "Add LoginButton")
- Single API endpoint (e.g., "GET /users")
- Single utility function (e.g., "formatDate()")
- Fix one specific bug

❌ **Too big**:
- "Build entire auth system"
- "Implement complete dashboard"
- "Migrate all components"

### Acceptance Criteria

✅ **Good** (measurable, verifiable):
- "File exists: apps/web/src/components/LoginForm.tsx"
- "Has props: { email: string, password: string }"
- "typecheck passes"
- "test passes: pnpm test -- LoginForm"

❌ **Bad** (vague):
- "Users can log in"
- "UI looks good"
- "Performance is improved"

### Priority

Express dependencies via priority numbers (lower = runs first):

```json
{
  "userStories": [
    { "id": "AUTH-001", "title": "Create auth context", "priority": 1 },
    { "id": "AUTH-002", "title": "Add login form", "priority": 2 },
    { "id": "AUTH-003", "title": "Add logout button", "priority": 3 }
  ]
}
```

See [docs/WRITING-PRDS.md](docs/WRITING-PRDS.md) for complete PRD writing guide.

## Configuration

### PRD Structure

```json
{
  "branchName": "ralph/feature-name",
  "agent": "claude",
  "model": "sonnet",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "lint": "pnpm lint",
    "test": "pnpm test",
    "build": "pnpm build"
  },
  "userStories": [
    {
      "id": "FEAT-001",
      "title": "Task title",
      "acceptanceCriteria": ["Measurable criteria"],
      "priority": 1,
      "passes": false,
      "notes": "Optional context"
    }
  ]
}
```

### Supported Agents

- `claude` - Claude Code CLI (default)
- `codex` - OpenAI Codex CLI
- `opencode` - OpenCode CLI
- `cursor` - Cursor CLI (requires `model` field)

See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for detailed configuration options.

## Cursor Integration

If you're using Cursor, Ralph supports Cursor's hooks system for enhanced integration:

```bash
# Install hooks automatically
./install-cursor-hooks.sh

# Or manually:
cp cursor-config/hooks.json .cursor/hooks.json
cp -r cursor-config/hooks/ .cursor/hooks/
chmod +x .cursor/hooks/*.sh
```

This enables:
- **Command validation** — Block dangerous commands before execution
- **Session logging** — Track all commands and file edits
- **Auto-continue** — Support for Ralph's multi-iteration loop pattern

### Claude CLI Environment Variables

When using the `claude` agent, you can configure behavior via environment variables:

```bash
# Use fallback model when primary is overloaded
RALPH_FALLBACK_MODEL=haiku ./ralph.sh 25 --session my-feature

# Enable JSON output for cost tracking
RALPH_JSON_OUTPUT=true ./ralph.sh 25 --session my-feature

# Ephemeral mode (no session persistence)
RALPH_EPHEMERAL=true ./ralph.sh 25 --session my-feature

# Append custom system prompt instructions
RALPH_SYSTEM_PROMPT_APPEND="Focus on TypeScript best practices" ./ralph.sh 25 --session my-feature
```

## Troubleshooting

**Ralph stuck on a task?**
- Check `progress.txt` for error logs
- Review commits: `git log --oneline`
- Break task into smaller subtasks
- Manually fix and mark task as `passes: true`

**Validation keeps failing?**
- Run validation manually: `pnpm typecheck && pnpm test`
- Fix issues locally
- Restart Ralph

**Need to pause Ralph?**
```bash
.ralph/stop.sh
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

## Key Concepts

### Fresh Context + Persistent Memory

Each iteration uses a fresh AI context window (focused, efficient) while memory persists through:
- Git commits (code history)
- progress.txt (codebase patterns)
- learnings.md (structured learnings)

This prevents context bloat while enabling knowledge compounding.

### Learning Loop

Ralph reads `learnings.md` before each task and appends new learnings after completion. Example: Task learns "WXT publicDir must be 'assets/' not 'public/'" → Next task reads learnings → Applies pattern without trial-and-error.

### Validation-First

Ralph runs ALL validation commands after each task. If ANY fail, it retries up to 5 times before marking as blocked. Only commits when ALL validations pass.

## Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed setup instructions
- [Usage Guide](docs/USAGE.md) - Complete workflow and commands
- [Writing PRDs](docs/WRITING-PRDS.md) - How to create effective PRDs
- [Configuration](docs/CONFIGURATION.md) - PRD structure and options
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Release Process](docs/RELEASING.md) - Creating releases with AI-generated notes
- [Portability](docs/PORTABLE.md) - How Ralph works portably
- [Changes](docs/CHANGES.md) - Change log

## Examples

See `examples/prd.json.example` for a complete PRD template.

## License

Ralph is open source. Use it freely in your projects.

## References

- Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/)
- Inspired by autonomous AI coding loops
