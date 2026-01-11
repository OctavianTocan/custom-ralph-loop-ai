# Ralph Wiggum - Autonomous AI Coding Loop

## Quick Start

Ralph is an autonomous AI coding loop that ships features while you sleep.

```bash
# 1. Install Ralph
cp -r ralph/ .ralph/
chmod +x .ralph/ralph.sh .ralph/status.sh .ralph/stop.sh .ralph/runners/*.sh

# 2. Install commands (optional but recommended)
cp ralph/commands/ralph:setup.md .claude/commands/  # For Claude Code
# Or: cp ralph/commands/ralph:setup.md .cursor/commands/  # For Cursor

# 3. Create a session with /ralph:setup command
/ralph:setup "Add user authentication system"

# 4. Run Ralph
.ralph/ralph.sh 25 --session my-feature
# Or: pnpm ralph 25 --session my-feature (if added to package.json)

# 5. Wake up to completed work
git checkout ralph/your-feature
git log --oneline
```

## Session Structure

Each Ralph run creates an isolated session directory:

```
{ralph-directory}/              # Wherever you placed Ralph (.ralph/, scripts/ralph/, etc.)
├── ralph.sh                    # Main script
├── prompt.md                   # Shared agent instructions
├── README.md                   # This file
├── prd.json.example            # Template for new PRDs
├── commands/                   # Optional commands for Claude Code/Cursor
│   ├── ralph:setup.md          # Interactive PRD creation command
│   └── ralph:run.md            # Run Ralph command
├── runners/                    # Agent runners
│   ├── run-claude.sh
│   ├── run-codex.sh
│   ├── run-cursor.sh
│   └── run-opencode.sh
└── sessions/                   # Created automatically
    └── {session-name}/          # Each session is self-contained
        ├── prd.json            # Task definitions and status
        ├── progress.txt        # Codebase patterns and gotchas
        ├── learnings.md        # Accumulated learnings
        └── ralph.log           # Execution log
```

**Benefits:**
- **Non-destructive**: Previous sessions are preserved for reference
- **Auditable**: Review any past Ralph run's progress and learnings
- **Compound knowledge**: Learnings from each session feed into docs/solutions/

## How It Works

Ralph is an autonomous AI coding system that iteratively implements tasks from a PRD (prd.json). The key innovation is using fresh context windows for each iteration while persisting memory through git commits and text files.

**The Loop:**

1. Ralph reads session files (prd.json, progress.txt, learnings.md)
2. **Reads learnings.md** to apply patterns from previous tasks
3. Picks highest-priority task where `passes: false`
4. Runs agent with fresh context window
5. Agent implements the task
6. Runs ALL validation commands (typecheck, lint, test, build)
7. **Re-runs if ANY validation fails** (up to 5 attempts)
8. Commits if ALL validations pass
9. **Appends learning entry to learnings.md**
10. Updates prd.json with `passes: true`
11. Logs summary to progress.txt
12. Repeats until all tasks complete
13. **Invokes /compound to document solutions**

**Memory Persistence:**

- **Git commits**: Each completed task is committed with atomic messages
- **progress.txt**: Codebase patterns and task summaries
- **learnings.md**: Structured learnings with tags for categorization
- **docs/solutions/**: Final compound documentation for project knowledge base

**Why Fresh Context Matters:**

- Avoids context bloat that degrades AI performance
- Each iteration is focused and efficient
- Prevents confusion from stale information
- Patterns compound without accumulating noise

**Learning Loop:**

Ralph gets smarter with each task by reading accumulated learnings before starting and writing new learnings after completing. Example: Task M1-003 learns "WXT publicDir must be 'assets/' not 'public/'" → Task M1-004 reads learnings.md before starting → Task M1-004 applies the pattern without trial-and-error.

## Installation

### Step 1: Copy Ralph to Your Project

Ralph is designed to be portable and work in any project. Copy the `ralph/` directory to your project:

```bash
# Option 1: Place in project root
cp -r ralph/ .ralph/

# Option 2: Place in scripts directory
cp -r ralph/ scripts/ralph/

# Option 3: Any location you prefer
cp -r ralph/ tools/ralph/
```

### Step 2: Make Scripts Executable

```bash
chmod +x .ralph/ralph.sh
chmod +x .ralph/status.sh
chmod +x .ralph/stop.sh
chmod +x .ralph/runners/*.sh
```

### Step 3: Add to package.json (Optional)

Add convenience scripts to your `package.json`:

```json
{
  "scripts": {
    "ralph": ".ralph/ralph.sh",
    "ralph:status": ".ralph/status.sh",
    "ralph:stop": ".ralph/stop.sh"
  }
}
```

Then use: `pnpm ralph` or `npm run ralph`

### Step 4: Install Commands (Optional but Recommended)

Ralph includes commands for Claude Code and Cursor that make it easier to create PRDs and run sessions.

#### For Claude Code (.claude/commands/)

Copy the command files to your `.claude/commands/` directory:

```bash
# Copy commands
cp ralph/commands/ralph:setup.md .claude/commands/
cp ralph/commands/ralph:run.md .claude/commands/

# Verify
ls .claude/commands/ralph*
```

Then use:
- `/ralph:setup "Feature description"` - Interactive PRD creation
- `/ralph:run [session-name] [iterations]` - Start or continue a session

#### For Cursor (.cursor/commands/)

If you use Cursor instead of Claude Code, copy to `.cursor/commands/`:

```bash
# Copy commands
cp ralph/commands/ralph:setup.md .cursor/commands/
cp ralph/commands/ralph:run.md .cursor/commands/

# Verify
ls .cursor/commands/ralph*
```

**Note:** Commands are optional - you can create PRDs manually and run Ralph directly with `./ralph/ralph.sh`.

### Requirements

- **Bash**: Scripts require bash (available on macOS, Linux, WSL)
- **Git**: Required for branch management and commits
- **jq**: Optional but recommended for JSON parsing (falls back to grep/sed)
- **AI Agent CLI**: At least one of:
  - `claude` (Claude Code CLI) - https://claude.ai/docs/cli
  - `codex` (OpenAI Codex CLI)
  - `opencode` (OpenCode CLI)
  - `cursor` (Cursor CLI) - https://cursor.com/docs/cli

## Getting Started

### Step 1: Create Your Session

#### Option A: Using `/ralph:setup` Command (Recommended)

If you installed the commands (Step 4 above), use:

```
/ralph:setup "Add user authentication system"
```

This will:
1. Search `docs/solutions/` for relevant patterns (if it exists)
2. Ask clarifying questions about the feature
3. Help break down tasks into atomic, measurable items
4. Create a session directory with `prd.json`, `progress.txt`, and `learnings.md`

#### Option B: Manual Creation

Create a session directory with a `prd.json`:

```bash
# Create session directory
mkdir -p .ralph/sessions/my-feature

# Copy example PRD
cp .ralph/prd.json.example .ralph/sessions/my-feature/prd.json

# Edit prd.json with your tasks
nano .ralph/sessions/my-feature/prd.json
```

Edit `prd.json` with your tasks:

```json
{
  "branchName": "ralph/your-feature-name",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test"
  },
  "userStories": [
    {
      "id": "FEAT-001",
      "title": "Add user profile component",
      "acceptanceCriteria": [
        "Displays user avatar and name",
        "Has edit profile button",
        "VALIDATION: typecheck passes with exit code 0"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Use apps/web/src/components/. See docs/solutions/ui-bugs/component-patterns.md"
    }
  ]
}
```

**Note:** Include "VALIDATION: {command} passes with exit code 0" in acceptance criteria for explicit verification requirements.

**Note:** If you used `/ralph:setup`, the session files (`progress.txt` and `learnings.md`) are created automatically. You only need to initialize them manually if creating sessions without the command.

### Step 2: Run Ralph

Run Ralph on your session:

```bash
# Using the script directly
.ralph/ralph.sh 25 --session my-feature

# Or if added to package.json
pnpm ralph 25 --session my-feature

# Or using the command (if installed)
/ralph:run my-feature 25
```

Ralph will:

- Read existing learnings before each task
- Create the feature branch if it doesn't exist
- Pick tasks in priority order
- Implement, validate (ALL commands), and commit each task
- Append structured learning to learnings.md
- Stop when all tasks complete or blocked (5 attempts max)
- **Invoke /compound to document solutions on completion**

### Step 3: Review Results

After Ralph completes:

```bash
# Checkout the feature branch
git checkout ralph/your-feature-name

# Review commits
git log --oneline

# View learnings from this session
cat .ralph/sessions/my-feature/learnings.md

# View final compound documentation (if /compound was invoked)
ls docs/solutions/

# Verify validation passes
pnpm typecheck
pnpm test
```

## Writing Good User Stories

### Task Size

Each task must fit in one AI context window (typically 5-15 minutes of work).

❌ **Too big:**

- "Build entire auth system"
- "Implement complete dashboard"
- "Migrate all components to React"

✅ **Right size:**

- "Add login form"
- "Add email validation"
- "Add auth server action"
- "Create user profile component"
- "Implement save button"

### Acceptance Criteria

Criteria must be **measurable and verifiable**. The AI can't guess what you mean.

❌ **Vague:**

- "Users can log in"
- "Dashboard looks good"
- "Performance is improved"

✅ **Explicit:**

- Email/password fields
- Validates email format with regex
- Shows error message on invalid email
- typecheck passes
- Verify at localhost:3000/login

- Dashboard loads in < 2 seconds
- Has 5 widgets arranged in grid
- Each widget displays correct data
- Responsive design works on mobile
- typecheck passes

### Priority

Lower numbers = higher priority. Use this to express dependencies:

```json
{
  "userStories": [
    {
      "id": "AUTH-001",
      "title": "Add auth context",
      "priority": 1,
      "passes": false
    },
    {
      "id": "AUTH-002",
      "title": "Add login form",
      "priority": 2,
      "passes": false
    },
    {
      "id": "AUTH-003",
      "title": "Add logout button",
      "priority": 3,
      "passes": false
    }
  ]
}
```

In this example, AUTH-001 runs first, then AUTH-002 (depends on context), then AUTH-003.

### Dependencies

If task B depends on task A, assign B a higher priority number:

```json
{
  "id": "UTIL-001",
  "title": "Add capitalize function",
  "priority": 1,
  "passes": false
},
{
  "id": "UTIL-002",
  "title": "Use capitalize in header component",
  "priority": 2,
  "passes": false
}
```

Ralph will implement UTIL-001 first, then UTIL-002 will find the function already exists.

## Configuration Reference

### prd.json Structure

```json
{
  "branchName": "ralph/feature-name",
  "agent": "claude",
  "model": "sonnet",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test",
    "lint": "pnpm lint",
    "build": "pnpm build"
  },
  "userStories": [
    {
      "id": "TASK-001",
      "title": "Task title",
      "acceptanceCriteria": ["Measurable criteria 1", "Measurable criteria 2"],
      "priority": 1,
      "passes": false,
      "notes": "Optional context for AI"
    }
  ]
}
```

**Fields:**

- `branchName`: Git branch to create/use
- `agent`: AI agent to use (optional, defaults to `"claude"`). Valid values: `"claude"`, `"codex"`, `"opencode"`, `"cursor"`
- `model`: Model to use (optional). Format depends on agent:
  - **Claude**: `"sonnet"`, `"opus"`, or full name like `"claude-sonnet-4-5-20250929"`
  - **Codex**: `"gpt-5.1"`, `"gpt-5.2-codex"`, etc.
  - **OpenCode**: `"anthropic/claude-3-5-sonnet-20241022"` (includes provider prefix)
  - **Cursor**: `"gpt-5"`, `"sonnet-4"`, etc.
  If omitted, each CLI uses its default model.
- `validationCommands`: Commands to run after each task (object, keys are command names)
- `userStories`: Array of tasks to complete
  - `id`: Unique identifier (e.g., FEAT-001, UTIL-002)
  - `title`: Human-readable description
  - `acceptanceCriteria`: Array of verifiable requirements
  - `priority`: Number (lower = first)
  - `passes`: Boolean (false = not done, true = completed)
  - `notes`: Optional additional context for the AI

### validationCommands

Configure validation for your project:

```json
{
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test",
    "lint": "pnpm lint"
  }
}
```

Ralph runs these in order after each task. If any fail, the task is retried.

**Monorepo Example:**

```json
{
  "validationCommands": {
    "typecheck": "turbo run typecheck",
    "test": "pnpm test",
    "build": "pnpm build"
  }
}
```

**Single Package Example:**

```json
{
  "validationCommands": {
    "typecheck": "pnpm --filter @my/package typecheck",
    "test": "pnpm --filter @my/package test"
  }
}
```

### progress.txt Format

The progress file accumulates learnings across iterations:

```markdown
# Ralph Progress Log

Started: 2025-01-08

## Codebase Patterns

- Migrations: Use IF NOT EXISTS
- React: useRef<Timeout | null>(null)
- API: Use api.get() for data fetching

## Key Files

- packages/api/src/client.ts
- apps/web/src/components/

## [2025-01-08] - UTIL-001

- Added capitalize utility function
- Files: packages/utils/src/string.ts
  **Learnings:**
  - Export functions individually, not as default
  - Use JSDoc for all utility functions

---

## [2025-01-08] - UTIL-002

- Added truncate utility function
- Files: packages/utils/src/string.ts
  **Learnings:**
  - String methods work well with template literals
  - Edge case: empty string returns empty string

---
```

**Sections:**

- `Codebase Patterns`: Top section, Ralph updates when discovering reusable patterns
- `Key Files`: Files frequently referenced across tasks
- Task Entries: Brief summaries appended after each completed task

### learnings.md Format

The learnings file captures structured knowledge as Ralph works:

```markdown
## M1-003 - Configure assets directory
Date: 2026-01-08 14:30
Status: COMPLETED

### What Was Done
- Added assets/ directory to chrome_extension_next
- Configured publicDir in wxt.config.ts

### Files Changed
- apps/chrome_extension_next/assets/: created directory
- apps/chrome_extension_next/wxt.config.ts: added publicDir config

### Learnings
- WXT publicDir must be 'assets/' not 'public/' for extension resources
- Assets are copied to .output/chrome-mv3/ during build
- Use relative paths from assets/ in manifest.json

### Applicable To Future Tasks
- M1-004: May need to reference assets in manifest
- M2-xxx: Any tasks involving extension resources

### Tags
build-errors: wxt-configuration
---
```

**Purpose:**
- Ralph reads this before each task to apply learned patterns
- Reduces trial-and-error by leveraging session knowledge
- Tags enable categorization for final /compound invocation

### Session Completion and /compound

When all tasks complete, Ralph:

1. Aggregates learnings from `learnings.md`
2. Identifies patterns worth preserving (grouped by tags)
3. Invokes `/compound` to create documentation in `docs/solutions/`
4. Outputs final session summary with references

This closes the knowledge loop - learnings from Ralph sessions become permanent project documentation.

## Common Patterns and Gotchas

### Idempotent Migrations

When modifying database schemas, always use `IF NOT EXISTS`:

```sql
-- Bad
ALTER TABLE users ADD COLUMN email TEXT;

-- Good
ALTER TABLE users ADD COLUMN IF NOT EXISTS email TEXT;
```

This prevents errors when Ralph retries tasks.

### Avoiding Interactive Prompts

Many tools prompt for confirmation. Pipe newlines to auto-confirm:

```bash
# Bad - will hang waiting for input
npm install

# Good - auto-confirms
echo -e "\n\n\n" | npm install
```

Configure this in `validationCommands` if needed.

### Schema Changes Require Cascading Updates

When modifying a type/interface, check all usages:

```typescript
// Changed interface User
interface User {
  id: string;
  name: string;
  email: string; // Added field
}
```

Update all files that use `User`:

- Component props
- API response handlers
- Type guards
- Test mocks

### Fixing Related Files is Not Scope Creep

If typecheck fails because of a related file, fix it:

```typescript
// Task: Add User.email field
interface User {
  email: string; // Added
}

// Related file that now fails typecheck
const getUser = (id: string): User => ({
  id,
  name: "Alice",
  // Missing email field - typecheck fails
});
```

**Fix it (not scope creep):**

```typescript
const getUser = (id: string): User => ({
  id,
  name: "Alice",
  email: "alice@example.com",
});
```

This is expected and part of the task completion.

## Troubleshooting

### Ralph Stuck in Loop

**Symptom:** Ralph keeps running the same task repeatedly.

**Possible causes:**

1. Validation command is failing
2. Task is too large (can't fit in one iteration)
3. Bug in the code that's not caught

**Solutions:**

- Check progress.txt for last learnings
- Review commits for what was attempted
- Break task into smaller subtasks
- Check if validation command is correct

### Validation Commands Failing

**Symptom:** Tasks fail at validation step with unclear errors.

**Solutions:**

```bash
# Run validation manually to see errors
pnpm typecheck
pnpm test

# Fix issues, then Ralph can continue
```

### Branch Already Exists

**Symptom:** Ralph fails to create branch that already exists.

**Solution:**

```bash
# Delete existing branch
git branch -D ralph/your-feature

# Or checkout and work on it
git checkout ralph/your-feature
```

### Learnings Not Accumulating

**Symptom:** progress.txt doesn't update after tasks.

**Possible causes:**

1. Task failing at validation step (no commit = no update)
2. Ralph exiting early
3. File permissions issue

**Solutions:**

```bash
# Check if file is writable
test -w .claude/ralph/progress.txt && echo "writable" || echo "read-only"

# Check Ralph output for errors
pnpm ralph 1 2>&1 | tee ralph-debug.log
```

### Context Window Exhaustion

**Symptom:** Agent says "context too full" or similar.

**Solution:**

- Break tasks into smaller, more atomic units
- Focus on one specific change per task
- Use notes field to provide focused context

## Best Practices

### Start Small

Your first Ralph session should be simple:

- 3-5 tasks
- Each task 5-15 minutes
- Clear, measurable criteria

As you gain confidence, tackle larger features.

### Be Explicit About Acceptance Criteria

The more specific your criteria, the better Ralph performs:

❌ Vague:

- "Add user profile page"

✅ Explicit:

- Create apps/web/src/profile/page.tsx
- Display user avatar (circular, 64px)
- Display user name (h1, bold)
- Display email address (secondary color)
- Has "Edit Profile" button
- Has "Delete Account" button (red text)
- typecheck passes

### Use Priority for Dependencies

Express task ordering through priority:

```json
{
  "id": "DATA-001",
  "title": "Create User type",
  "priority": 1,
  "passes": false
},
{
  "id": "COMP-001",
  "title": "Create UserCard component",
  "priority": 2,
  "passes": false
}
```

Ralph implements DATA-001 first, then COMP-001 finds the type already exists.

### Monitor Progress via progress.txt

While Ralph runs, watch progress.txt in another terminal:

```bash
# Watch progress in real-time
tail -f .claude/ralph/progress.txt
```

This shows learnings accumulating and patterns being discovered.

### Review Commits After Ralph Completes

Always review what Ralph did:

```bash
# Checkout the feature branch
git checkout ralph/your-feature

# Review commits one by one
git log --oneline

# Show diff for each commit
git show <commit-hash>

# Review the final result
pnpm typecheck
pnpm test
pnpm build
```

## Integration with Project Standards

Ralph automatically respects your project's coding standards:

### AGENTS.md Compliance

Ralph reads and follows AGENTS.md rules:

- TypeScript best practices
- React patterns
- Testing philosophy
- Git commit conventions

### Commit Message Format

Ralph uses conventional commits:

```
feat: [ID] - [Title]
fix: [ID] - [Title]
refactor: [ID] - [Title]
```

Examples:

```
feat: AUTH-001 - Add login form
feat: UTIL-002 - Add truncate function
fix: AUTH-003 - Fix email validation regex
```

### Documentation Updates

When Ralph discovers reusable patterns, it updates AGENTS.md:

**Example:**
After implementing several API calls, Ralph might add:

```markdown
## API Patterns

When calling the backend API:

- Use `api.get()` for GET requests
- Use `api.post()` for POST requests
- Always handle 401 errors with logout()
- Wrap calls in try/catch for error handling
```

This knowledge compounds across iterations, making Ralph smarter over time.

### Validation Commands

Ralph runs your project's validation:

- `pnpm typecheck` - TypeScript errors
- `pnpm test` - Test failures
- `pnpm lint` - Linting issues
- `pnpm build` - Build errors

All configured in prd.json.

## Multi-Agent Support

Ralph supports multiple AI agent backends, allowing you to choose the best agent for each session.

### Available Agents

| Agent | CLI Command | Auto-Approval | Requirements |
|-------|-------------|---------------|--------------|
| **Claude Code** | `claude` | `--dangerously-skip-permissions` | Claude CLI installed and authenticated |
| **OpenAI Codex** | `codex` | `--full-auto` | Codex CLI installed, `OPENAI_API_KEY` set |
| **OpenCode** | `opencode` | Config file (`permission.edit: "allow"`) | OpenCode CLI installed, provider configured |
| **Cursor** | `cursor` | Full write in non-interactive mode | Cursor CLI installed, model specified in prd.json |

### Selecting an Agent

Specify the agent in your `prd.json`:

```json
{
  "branchName": "ralph/feature",
  "agent": "codex",
  "validationCommands": { ... },
  "userStories": [ ... ]
}
```

If `agent` is omitted, Ralph defaults to `"claude"` for backward compatibility.

### Agent Setup

#### Claude Code (Default)
```bash
# Install Claude CLI (if not already installed)
# See: https://claude.ai/docs/cli

# Verify installation
claude --version
```

#### OpenAI Codex CLI
```bash
# Install Codex CLI
npm install -g @openai/codex-cli

# Set API key
export OPENAI_API_KEY=your_api_key_here

# Verify installation
codex --version
```

#### OpenCode
```bash
# Install OpenCode CLI
npm install -g @opencode-ai/cli

# Configure provider (Anthropic, OpenAI, etc.)
# See: https://opencode.ai/docs

# Verify installation
opencode --version
```

Ralph automatically creates `opencode.json` in your session directory with appropriate permissions (`edit: "allow"`, `bash: "allow"`).

#### Cursor
```bash
# Install Cursor CLI
# See: https://cursor.com/docs/cli

# Verify installation
cursor --version
```

**IMPORTANT:** When using `agent: "cursor"` in prd.json, you MUST specify a model:
```json
{
  "agent": "cursor",
  "model": "claude-sonnet-4-20250514"
}
```

Omitting the model with Cursor will cause Ralph to fail. The agent identifier is `cursor`, not `cursor-agent`.

### Agent Comparison

| Feature | Claude | Codex | OpenCode | Cursor |
|---------|--------|-------|----------|--------|
| File editing | ✅ | ✅ | ✅ | ✅ |
| Command execution | ✅ | ✅ | ✅ | ✅ |
| JSON output | ❌ | ❌ | ✅ | ❌ |
| Session continuation | ❌ | ❌ | ✅ | ❌ |
| Provider flexibility | ❌ | ❌ | ✅ | ❌ |

**Recommendations:**
- **Claude**: Default choice, well-integrated with Cursor
- **Codex**: Good alternative if you prefer OpenAI models
- **OpenCode**: Best for provider flexibility and JSON parsing
- **Cursor**: Use if you want to leverage Cursor-specific features

## When NOT to Use Ralph

Ralph is a powerful tool, but not suitable for all work.

### ❌ Exploratory Work

When you're figuring out the problem space:

- "Investigate performance issues"
- "Research best approach for X"
- "Explore architecture options"

**Use Ralph after** you've explored and defined the solution.

### ❌ Major Refactors Without Clear Criteria

Large, sweeping changes need human oversight:

- "Migrate from Redux to Zustand"
- "Replace all class components with hooks"
- "Refactor entire API layer"

**Use Ralph for** small, well-scoped refactor tasks after you've planned the big picture.

### ❌ Security-Critical Code

Anything that requires careful review:

- Authentication logic
- Authorization checks
- Encryption/decryption
- Payment processing

**Use Ralph for** non-security parts, then manually review security code.

### ❌ Anything Requiring Human Review

Tasks that need subjective judgment:

- UI/UX improvements
- Accessibility improvements (beyond automated checks)
- Performance optimization (needs profiling)
- Business logic with edge cases

**Use Ralph for** mechanical parts, then review and refine manually.

### ✅ Perfect for Ralph

Well-defined, measurable tasks:

- Add specific UI component
- Implement specific API endpoint
- Add specific utility function
- Fix specific bug
- Add specific test cases
- Refactor specific file/module
- Add specific feature to existing codebase

## Advanced Usage

### Multiple Sessions for Large Features

Break large features into separate sessions:

```bash
# Create separate sessions
.claude/ralph/sessions/2026-01-08-feature-backend/
.claude/ralph/sessions/2026-01-08-feature-frontend/

# Each session has its own:
# - prd.json (tasks)
# - progress.txt (patterns)
# - learnings.md (knowledge)

# Run each session separately
# Ralph reads from the session directory

# After both complete, review learnings from each:
cat .claude/ralph/sessions/2026-01-08-feature-backend/learnings.md
cat .claude/ralph/sessions/2026-01-08-feature-frontend/learnings.md
```

**Benefit:** Each session preserves its learnings separately. You can cross-reference what worked in the backend session when debugging frontend issues.

### Custom Validation Commands

Add project-specific validation:

```json
{
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test",
    "accessibility": "pnpm run a11y",
    "bundle-size": "pnpm run check-size"
  }
}
```

### Progressive Task Complexity

Start with easy tasks, build up to complex ones:

```json
{
  "userStories": [
    {
      "id": "EASY-001",
      "title": "Add simple button",
      "priority": 1,
      "passes": false
    },
    {
      "id": "MED-001",
      "title": "Add form with validation",
      "priority": 2,
      "passes": false
    },
    {
      "id": "HARD-001",
      "title": "Add multi-step wizard",
      "priority": 3,
      "passes": false
    }
  ]
}
```

Ralph builds confidence and patterns before tackling complex tasks.

## Example Sessions

### Session 1: Adding Documentation Tasks

```bash
# Configure prd.json
cat > .claude/ralph/prd.json << 'EOF'
{
  "branchName": "ralph/documentation",
  "validationCommands": {
    "typecheck": "pnpm typecheck"
  },
  "userStories": [
    {
      "id": "DOC-001",
      "title": "Add API documentation",
      "acceptanceCriteria": [
        "Create docs/api/README.md",
        "Document all API endpoints",
        "Include example requests/responses",
        "typecheck passes"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "DOC-002",
      "title": "Add component documentation",
      "acceptanceCriteria": [
        "Create docs/components/README.md",
        "Document key components",
        "Include usage examples",
        "typecheck passes"
      ],
      "priority": 2,
      "passes": false
    }
  ]
}
EOF

# Run Ralph
pnpm ralph 10

# Review results
git checkout ralph/documentation
git log --oneline
```

### Session 2: Adding Utility Functions

```bash
cat > .claude/ralph/prd.json << 'EOF'
{
  "branchName": "ralph/string-utils",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test"
  },
  "userStories": [
    {
      "id": "UTIL-001",
      "title": "Add capitalize function",
      "acceptanceCriteria": [
        "Function in packages/utils/src/string.ts",
        "Returns string with first letter uppercase",
        "Handles empty string",
        "Has JSDoc comments",
        "typecheck passes"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "UTIL-002",
      "title": "Add truncate function",
      "acceptanceCriteria": [
        "Function in packages/utils/src/string.ts",
        "Truncates to max length with ellipsis",
        "Handles strings shorter than max",
        "Has JSDoc comments",
        "typecheck passes"
      ],
      "priority": 2,
      "passes": false
    }
  ]
}
EOF

pnpm ralph 10
```

## References

- **Original Concept:** Ralph Wiggum by Geoffrey Huntley
- **Inspiration:** [Ryan Carson's X post](https://x.com/ryancarson)
- **Video Walkthrough:** [Matt Pocock's Ralph Wiggum breakdown](https://x.com/mattpocockuk)

## FAQ

**Q: How long does each iteration take?**
A: Typically 2-5 minutes, depending on task complexity and validation speed.

**Q: What if Ralph gets stuck?**
A: Use `/loop:break` (if implemented) or Ctrl+C to stop, then review progress.txt and commits.

**Q: Can Ralph handle bugs?**
A: Yes, if the bug is well-defined with reproducible steps and acceptance criteria.

**Q: How many iterations should I use?**
A: Start with 10 for simple features, 25-50 for complex features with 10+ tasks.

**Q: Does Ralph work with any project?**
A: Yes, if you configure validationCommands correctly for your project's toolchain.

**Q: Can I run Ralph while I work on other things?**
A: Yes, Ralph is autonomous. Just check in periodically via `tail -f .claude/ralph/progress.txt`.

**Q: What if Ralph implements something wrong?**
A: Review commits after completion, fix issues, and update prd.json to reflect lessons learned.

**Q: How do I stop Ralph?**
A: Ctrl+C to stop immediately, or let it complete all tasks.

**Q: Can Ralph work with existing branches?**
A: Yes, set branchName to an existing branch. Ralph will continue from where it left off.

**Q: What happens if validation never passes?**
A: Ralph will retry until max_iterations. Check progress.txt for clues about what's blocking.

## Support

For issues or questions:

1. Check this README first
2. Review progress.txt for learnings
3. Review git commits for what was attempted
4. Check AGENTS.md for project-specific patterns
5. Manually fix the blocking issue and restart Ralph
