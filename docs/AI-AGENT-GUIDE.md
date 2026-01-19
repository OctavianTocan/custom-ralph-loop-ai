# AI Agent Guide: Creating PRDs for Ralph

This guide is specifically designed for AI agents (Claude, Cursor, ChatGPT, etc.) helping users create Product Requirements Documents (PRDs) for the Ralph Autonomous AI Coding Loop.

## Quick Reference

When a user asks you to help them create a Ralph PRD or set up a Ralph session:

1. **Use the `/ralph:setup` command** if available (in Claude Code or Cursor)
2. **Or follow this guide** to manually create a high-quality PRD

## What is Ralph?

Ralph is an autonomous AI coding system that:
- Runs iteratively with fresh context windows
- Implements one task at a time
- Validates each task (typecheck, lint, test, build)
- Commits only when all validations pass
- Learns from each task to improve future work

**Your role:** Help users create PRDs that Ralph can execute successfully.

## Step-by-Step: Creating a PRD

### Step 1: Understand the Feature

Ask clarifying questions:
- "What's the high-level goal?"
- "What files/components should this integrate with?"
- "What validation commands should run?" (typecheck, test, lint, build)
- "Which AI agent CLI do you have?" (claude, codex, opencode, cursor)
- "Do you want to specify a model?" (optional for most agents, required for cursor)

### Step 2: Break Into Atomic Tasks

**Each task must:**
- ✅ Fit in one AI context window (5-15 minutes)
- ✅ Have ONE clear responsibility
- ✅ Be independently testable
- ❌ NOT span multiple features or components

**Good task examples:**
- "Create LoginButton component"
- "Add GET /users API endpoint"
- "Add formatDate() utility function"
- "Fix bug in form validation"

**Bad task examples:**
- "Build entire authentication system" (too big)
- "Implement complete dashboard" (too vague)
- "Improve performance" (not measurable)

**How to break down large features:**
```
Instead of: "Build user authentication"
Break into:
1. Create auth context (priority: 1)
2. Add login form component (priority: 2)
3. Add logout button (priority: 3)
4. Add protected route wrapper (priority: 4)
5. Add login/logout tests (priority: 5)
```

### Step 3: Write Measurable Acceptance Criteria

**Good criteria (objective, verifiable):**
```json
{
  "acceptanceCriteria": [
    "File exists: apps/web/src/components/LoginForm.tsx",
    "Has props: { email: string, password: string, onSubmit: () => void }",
    "Renders form with email and password inputs",
    "Shows error message when email is invalid",
    "typecheck passes",
    "test passes: pnpm test -- LoginForm"
  ]
}
```

**Bad criteria (vague, subjective):**
```json
{
  "acceptanceCriteria": [
    "Users can log in",           // How do we verify?
    "UI looks professional",      // Subjective
    "Performance is good",        // Not measurable
    "Code is clean"              // Subjective
  ]
}
```

**Acceptance criteria checklist:**
- [ ] Can be automatically verified?
- [ ] Includes specific file paths?
- [ ] Includes validation commands (typecheck, test, lint)?
- [ ] Clear pass/fail conditions?
- [ ] No subjective terms (good, clean, professional)?

### Step 4: Set Priority Order

Use priority numbers to express dependencies (lower = runs first):

```json
{
  "userStories": [
    {
      "id": "AUTH-001",
      "title": "Create auth context",
      "priority": 1  // Runs first
    },
    {
      "id": "AUTH-002", 
      "title": "Add login form",
      "priority": 2  // Needs context from AUTH-001
    },
    {
      "id": "AUTH-003",
      "title": "Add logout button", 
      "priority": 3  // Needs context from AUTH-001
    }
  ]
}
```

**Rule:** If task B depends on task A, give B a higher priority number.

### Step 5: Configure Validation Commands

Ralph runs these after each task. All must pass before committing.

**Monorepo example:**
```json
{
  "validationCommands": {
    "typecheck": "turbo run typecheck",
    "test": "pnpm test",
    "build": "pnpm build"
  }
}
```

**Single package example:**
```json
{
  "validationCommands": {
    "typecheck": "pnpm --filter @my/package typecheck",
    "test": "pnpm --filter @my/package test"
  }
}
```

**Minimal example:**
```json
{
  "validationCommands": {
    "typecheck": "pnpm typecheck"
  }
}
```

Ask the user what commands to run. Common ones: `typecheck`, `test`, `lint`, `build`.

### Step 6: Choose Agent and Model

**Agent options:**
- `claude` - Claude Code CLI (default, well-integrated)
- `codex` - OpenAI Codex CLI
- `opencode` - OpenCode CLI (provider flexibility)
- `cursor` - Cursor CLI (**requires model to be specified**)

**Model format by agent:**
- **Claude:** `"sonnet"`, `"opus"`, or full name (optional)
- **Codex:** `"gpt-5.1"`, `"gpt-5.2-codex"`, etc. (optional)
- **OpenCode:** `"anthropic/claude-3-5-sonnet-20241022"` (provider/model, optional)
- **Cursor:** `"claude-sonnet-4-20250514"` (**REQUIRED**)

**Important:** If user selects `cursor` agent, you MUST ask for a model. Cursor agent will fail without it.

### Step 7: Create the PRD File

**File structure:**
```json
{
  "branchName": "ralph/feature-name",
  "agent": "claude",
  "model": "sonnet",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test"
  },
  "userStories": [
    {
      "id": "FEAT-001",
      "title": "Task title",
      "acceptanceCriteria": [
        "File exists: path/to/file.tsx",
        "Has props: { prop1: string }",
        "typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Optional context or patterns to follow"
    }
  ]
}
```

**Field reference:**
- `branchName` - Git branch to create (format: `ralph/feature-name`)
- `agent` - AI agent CLI to use (defaults to `claude`)
- `model` - Model name (optional except for cursor)
- `validationCommands` - Commands to run after each task
- `userStories` - Array of tasks
  - `id` - Unique identifier (e.g., FEAT-001, AUTH-002)
  - `title` - Short description
  - `acceptanceCriteria` - Array of verifiable requirements
  - `priority` - Number (lower runs first)
  - `passes` - Always start as `false`
  - `notes` - Optional context for the AI

### Step 8: Create Session Directory

**Session naming convention:** `YYYY-MM-DD-feature-name`

**Example:**
```bash
# Determine Ralph directory (where ralph.sh is located)
# Common locations: .ralph/, scripts/ralph/, tools/ralph/

# Create session directory
mkdir -p .ralph/sessions/2026-01-19-user-authentication/

# Create files
touch .ralph/sessions/2026-01-19-user-authentication/prd.json
touch .ralph/sessions/2026-01-19-user-authentication/progress.txt
touch .ralph/sessions/2026-01-19-user-authentication/learnings.md
```

Write the PRD to `prd.json` in the session directory.

### Step 9: Provide Usage Instructions

After creating the PRD, give the user clear instructions:

```bash
# Review the PRD
cat .ralph/sessions/2026-01-19-user-authentication/prd.json

# Edit if needed
nano .ralph/sessions/2026-01-19-user-authentication/prd.json

# Run Ralph (25 iterations)
.ralph/ralph.sh 25 --session 2026-01-19-user-authentication

# Monitor progress
tail -f .ralph/sessions/2026-01-19-user-authentication/ralph.log

# View learnings
tail -f .ralph/sessions/2026-01-19-user-authentication/learnings.md

# Check results
git checkout ralph/user-authentication
git log --oneline
```

## Common Patterns

### Pattern 1: Component Creation

```json
{
  "id": "COMP-001",
  "title": "Create UserCard component",
  "acceptanceCriteria": [
    "File exists: src/components/UserCard.tsx",
    "Has props: { user: { name: string, email: string, avatar: string } }",
    "Displays user avatar (circular, 64px)",
    "Displays user name (h1 tag)",
    "Displays email (paragraph tag, secondary color)",
    "typecheck passes",
    "test passes: pnpm test -- UserCard"
  ],
  "priority": 1,
  "passes": false,
  "notes": "Use Tailwind classes. Reference UserProfile.tsx for styling patterns."
}
```

### Pattern 2: API Endpoint

```json
{
  "id": "API-001",
  "title": "Create GET /users endpoint",
  "acceptanceCriteria": [
    "File exists: src/app/api/users/route.ts",
    "Returns array of users with id, name, email fields",
    "Returns 200 status on success",
    "Returns empty array when no users",
    "typecheck passes",
    "test passes: pnpm test -- api/users"
  ],
  "priority": 1,
  "passes": false,
  "notes": "Use Next.js App Router conventions"
}
```

### Pattern 3: Utility Function

```json
{
  "id": "UTIL-001",
  "title": "Add formatDate utility function",
  "acceptanceCriteria": [
    "File exists: src/utils/date.ts",
    "Function signature: formatDate(date: Date | number): string",
    "Returns format: YYYY-MM-DD",
    "Handles Date objects",
    "Handles timestamps (numbers)",
    "Handles invalid input (returns empty string)",
    "typecheck passes",
    "test passes: pnpm test -- utils/date"
  ],
  "priority": 1,
  "passes": false
}
```

### Pattern 4: Bug Fix

```json
{
  "id": "BUG-001",
  "title": "Fix login form not submitting on Enter key",
  "acceptanceCriteria": [
    "Identify bug in src/components/LoginForm.tsx",
    "Add onKeyDown handler to form",
    "Submits when Enter key pressed in any input field",
    "Does not submit when other keys pressed",
    "Existing submission via button still works",
    "typecheck passes",
    "test passes: pnpm test -- LoginForm"
  ],
  "priority": 1,
  "passes": false,
  "notes": "User reported: pressing Enter does nothing"
}
```

## Best Practices for AI Agents

### DO:
- ✅ Start with 3-5 tasks for first-time users
- ✅ Include file paths in acceptance criteria
- ✅ Always include "typecheck passes" in criteria
- ✅ Ask about existing validation commands
- ✅ Use priority numbers to express dependencies
- ✅ Explain the PRD structure to the user
- ✅ Provide usage instructions after creation

### DON'T:
- ❌ Create tasks that span multiple files/features
- ❌ Use vague acceptance criteria
- ❌ Forget to set `passes: false` for new tasks
- ❌ Omit validation commands
- ❌ Skip the model field for cursor agent
- ❌ Make assumptions about project structure (ask!)

## Troubleshooting

### "Tasks too big"
**Problem:** Ralph gets stuck or validation keeps failing.
**Solution:** Break tasks into smaller pieces. Each should be 5-15 minutes of work.

### "Validation never passes"
**Problem:** Tests or typecheck always fail.
**Solution:** Ensure validation commands are correct for the project. Test them manually first.

### "Dependencies wrong"
**Problem:** Tasks run in wrong order.
**Solution:** Review priority numbers. Lower number = runs first.

### "Cursor agent fails"
**Problem:** Cursor agent errors on startup.
**Solution:** Check that `model` field is specified in prd.json. Cursor requires it.

### "Acceptance criteria unclear"
**Problem:** Ralph marks task complete but it doesn't meet expectations.
**Solution:** Make criteria more specific. Include file paths, exact function signatures, validation commands.

## Complete Example

Here's a complete PRD for adding a user profile feature:

```json
{
  "branchName": "ralph/user-profile",
  "agent": "claude",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test"
  },
  "userStories": [
    {
      "id": "PROF-001",
      "title": "Create UserProfile component",
      "acceptanceCriteria": [
        "File exists: src/components/UserProfile.tsx",
        "Has props: { user: { name: string, email: string, avatar: string, bio: string } }",
        "Displays avatar (circular, 128px)",
        "Displays name (h1, bold)",
        "Displays email (secondary color)",
        "Displays bio (paragraph)",
        "typecheck passes",
        "test passes: pnpm test -- UserProfile"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Use Tailwind. Reference UserCard.tsx for styling patterns."
    },
    {
      "id": "PROF-002",
      "title": "Add UserProfile to profile page",
      "acceptanceCriteria": [
        "File modified: src/app/profile/page.tsx",
        "Imports UserProfile component",
        "Renders UserProfile with sample user data",
        "typecheck passes"
      ],
      "priority": 2,
      "passes": false,
      "notes": "Use dummy data: { name: 'John Doe', email: 'john@example.com', avatar: '/avatars/default.png', bio: 'Sample bio' }"
    },
    {
      "id": "PROF-003",
      "title": "Add edit button to UserProfile",
      "acceptanceCriteria": [
        "Adds edit button to UserProfile component",
        "Button displays pencil icon",
        "Button has onClick prop: () => void",
        "Button positioned in top-right corner",
        "typecheck passes",
        "test passes: pnpm test -- UserProfile"
      ],
      "priority": 3,
      "passes": false
    }
  ]
}
```

## Using the `/ralph:setup` Command

If available in your editor:

```
/ralph:setup "Add user profile feature"
```

The command will:
1. Interview you about the feature
2. Break it into tasks automatically
3. Generate acceptance criteria
4. Create the PRD file
5. Create the session directory
6. Provide usage instructions

This is faster than manual creation!

## Key Takeaways

1. **Task sizing matters**: 5-15 minutes per task, one responsibility
2. **Acceptance criteria must be measurable**: File paths, validation commands, specific requirements
3. **Priority expresses dependencies**: Lower number = runs first
4. **Validation commands are critical**: typecheck, test, lint, build
5. **Cursor agent needs model**: Don't forget to specify it
6. **Start small**: 3-5 tasks for first PRD

## References

- [WRITING-PRDS.md](WRITING-PRDS.md) - Detailed PRD writing guide
- [CONFIGURATION.md](CONFIGURATION.md) - Complete PRD structure reference
- [USAGE.md](USAGE.md) - How to run Ralph with PRDs
- [EXAMPLES.md](EXAMPLES.md) - Real-world examples

---

**Remember:** Your goal is to help users create PRDs that Ralph can execute successfully. Focus on atomic tasks, measurable criteria, and clear priorities.
