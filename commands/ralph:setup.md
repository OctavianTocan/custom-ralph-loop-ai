---
description: Create or update a Ralph session from a spec/plan file (or feature description)
trigger: /ralph:plan
arguments: [plan-file]
---

# Ralph Plan/Session Assistant

Helps you create a PRD (prd.json) for the autonomous AI coding loop, optionally backed by a spec/plan file.

> **Note:** This command implements the AI Agent Guide. For detailed best practices, see [docs/AI-AGENT-GUIDE.md](../../docs/AI-AGENT-GUIDE.md).

## Your Task

User provided: **$ARGUMENTS**

### If $ARGUMENTS is a file path (e.g., `plans/my-feature.md`):
1. Read the file using `@$ARGUMENTS` to include its contents
2. Interview the user about any missing **non-obvious** details (don't ask for things already in the spec)
3. Write the updated spec back to the same file (include all original content plus new clarifications)
4. Generate/update the session PRD from the spec

### If $ARGUMENTS is a feature description (not a file):
Guide them through creating a prd.json file as before.

### In both cases, create a prd.json file with:

1. Atomic tasks (fit in one context window, 5-15 minutes each)
2. Measurable acceptance criteria (objective, verifiable)
3. Clear priority ordering (dependencies expressed via priority numbers)
4. Appropriate validation commands for their project
5. **Optional workflow selection** (e.g., `test-coverage` for coverage-improvement sessions)

---

## Step 0: Solution Lookup (MANDATORY)

**Before analyzing the feature**, search for relevant existing solutions:

```bash
# Search docs/solutions/ for keywords from the feature description
grep -r "keyword1\|keyword2" docs/solutions/ --include="*.md" -l
```

**Extract from matching solutions:**
- Common gotchas to avoid
- Patterns that worked
- File locations of related code
- Known issues and their fixes

**Include in PRD:**
- Add relevant solution references to task `notes` fields
- Warn about known gotchas in acceptance criteria
- Reference successful patterns for similar work

**Example searches:**
- Feature: "user authentication" → `grep -r "auth\|login\|session" docs/solutions/`
- Feature: "API endpoint" → `grep -r "api\|endpoint\|route" docs/solutions/`
- Feature: "TypeScript migration" → `grep -r "typescript\|migration\|types" docs/solutions/`

This gives Ralph context about previously solved problems before starting.

---

## Step 1: Analyze the Feature

Understand what the user wants to build:

- Break down into logical chunks
- Identify dependencies (what must come first)
- Estimate size of each chunk

Ask clarifying questions if needed:

- "What's the high-level goal?"
- "Are there existing files/components this should integrate with?"
- "What validation commands should run? (typecheck, test, lint, build)"
- **"Which AI agent would you like to use? (claude, codex, opencode, cursor) - defaults to claude"**
- **"Which model would you like to use? (optional - leave blank to use agent's default)"**

## Step 2: Task Sizing Strategy

**Right size for Ralph tasks:**

- ✅ Single component (e.g., "Add LoginButton")
- ✅ Single API endpoint (e.g., "GET /users")
- ✅ Single utility function (e.g., "formatDate()")
- ✅ Single page/route (e.g., "/settings")
- ✅ Fix one specific bug
- ✅ Add one specific test case

**Too big for one task:**

- ❌ "Build entire auth system"
- ❌ "Implement complete dashboard"
- ❌ "Migrate all components to React"
- ❌ "Add comprehensive test suite"

**Break down by:**

- Components vs logic vs tests
- Features vs sub-features
- Dependencies (A must exist before B)

## Step 3: Acceptance Criteria Rules

**Good acceptance criteria (measurable, objective):**

- "File X exists at path Y"
- "Component has props: { name: string, age: number }"
- "typecheck passes"
- "test: npm test -- test-name"
- "Endpoint returns 200 status"
- "UI displays: 'Success!' message"
- "Build completes with no errors"

**Bad acceptance criteria (vague, subjective):**

- "Users can log in"
- "UI looks good"
- "Performance is better"
- "Code is clean"

**Verification examples:**

```json
// Good: Can be automatically checked
{
  "acceptanceCriteria": [
    "File exists: apps/web/src/components/LoginForm.tsx",
    "Has email and password fields (type='email', type='password')",
    "typecheck passes"
  ]
}

// Bad: Can't be automatically verified
{
  "acceptanceCriteria": [
    "Login form looks professional",
    "User experience is smooth",
    "Code is well-organized"
  ]
}
```

## Step 4: Priority Ordering

**Express dependencies via priority numbers:**

```json
{
  "userStories": [
    {
      "id": "AUTH-001",
      "title": "Create auth context",
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

**In this example:**

- AUTH-001 runs first (creates auth context)
- AUTH-002 runs second (login form depends on context)
- AUTH-003 runs third (logout button depends on context)

## Step 5: Workflow Selection (Optional)

**Ask the user if they want to use a workflow:**

- Options: none (default PRD-driven), `test-coverage`, or other workflows in `workflows/` directory
- If `test-coverage` selected:
  - Add `workflow: "test-coverage"` to prd.json
  - Add `coverageCommand` field (required, e.g., `"pnpm test --coverage"`)
  - Add `coverageTarget` field (default: 100, but ask user for their target %)
  - Include a single long-lived story (e.g., `COV-000`) with acceptance criteria that enforce "one test per iteration" and "stop when target reached"
  - Set `validationCommands.test` to the same `coverageCommand` so validation re-checks coverage

## Step 6: Agent and Model Selection

**Ask the user for their preferences:**

1. **Agent selection:**
   - Options: `claude` (default), `codex`, `opencode`, `cursor`
   - If not specified, default to `claude`
   - Explain briefly what each agent offers if user is unsure

2. **Model selection:**
   - If user wants a specific model, ask for it
   - Format depends on agent:
     - **Claude**: `sonnet`, `opus`, or full name like `claude-sonnet-4-5-20250929` (optional)
     - **Codex**: `gpt-5.1`, `gpt-5.2-codex`, etc. (optional)
     - **OpenCode**: `anthropic/claude-3-5-sonnet-20241022` (provider/model format, optional)
     - **Cursor**: `claude-sonnet-4-20250514`, etc. (**REQUIRED** - must be specified)
   - **IMPORTANT:** When `agent: "cursor"` is selected, the model field is **MANDATORY**. Cursor agent will fail without an explicit model.
   - For other agents, if not specified, each CLI will use its default model

**Example interaction:**
```
Which AI agent would you like to use?
- claude (default, well-integrated with Cursor)
- codex (OpenAI models)
- opencode (provider flexibility)
- cursor (Cursor-specific features, requires model specification)

[User selects or defaults to claude]

Which model would you like to use?
  (optional for claude/codex/opencode, REQUIRED for cursor)
[User enters model name or leaves blank for non-cursor agents]

If cursor selected and no model provided:
  ❌ ERROR: Cursor agent requires a model to be specified.
  Please provide a model (e.g., claude-sonnet-4-20250514)
```

## Step 7: Cursor Agent Validation (If Using Cursor)

**If the user selected `cursor` as the agent:**

1. **MANDATORY: Verify model is specified**
   - Check that the user provided a model value
   - If model is empty or missing:
     ```
     ❌ ERROR: Cursor agent requires a model to be specified.
     
     Example:
       "agent": "cursor",
       "model": "claude-sonnet-4-20250514"
     
     Please provide a model name.
     ```
   - Do NOT proceed without a model for cursor agent

2. **Verify Cursor CLI is available:**
   - Check: `cursor --version`
   - If not found, warn user to install Cursor CLI
   - Reference: https://cursor.com/docs/cli

3. **Add note to progress.txt:**
   - Document Cursor CLI version if available
   - Note the model being used
   - Remind that agent identifier is `cursor` (not `cursor-agent`)

**This validation ensures Ralph can successfully use the Cursor agent when executing tasks.**

## Step 8: Suggest prd.json Structure

After analyzing the feature and getting agent/model preferences, create a complete prd.json:

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
    // Your tasks here
  ]
}
```

**Note:** Include `agent` and `model` fields based on user's selection.
- For `cursor` agent: model field is **REQUIRED** (do not omit)
- For other agents: model field is optional (omit if not specified)

**validationCommands configuration:**

- **Monorepo:** Use `"typecheck": "turbo run typecheck"`
- **Single package:** Use `"typecheck": "pnpm --filter @package/name typecheck"`
- **Minimal:** Just `"typecheck": "pnpm typecheck"`
- Include all commands you want Ralph to run

## Step 9: Create Session Directory and Files

**Session naming convention:**
```
{ralph-directory}/sessions/YYYY-MM-DD-{feature-name}/
```

Example: `.ralph/sessions/2026-01-08-user-authentication/`

**Create the session:**
1. Generate session name from date + feature (kebab-case)
2. Determine Ralph directory (where ralph.sh is located, e.g., `.ralph/`, `scripts/ralph/`)
3. Create directory: `{ralph-directory}/sessions/{session-name}/`
4. Create files in that directory:
   - `prd.json` - The PRD with all tasks
   - `progress.txt` - Initialize with codebase patterns from solution lookup
   - `learnings.md` - Empty file for learning loop

Generate the complete prd.json file with:

- Meaningful branch name (lowercase, kebab-case)
- Agent selection (from Step 6)
- Model selection (from Step 6, if specified)
- Appropriate validation commands
- 3-10 tasks (start small)
- Each task atomic and measurable
- Clear priorities
- Helpful notes field with solution references from Step 0

**Initialize progress.txt with:**
- Codebase patterns discovered during solution lookup
- Known gotchas relevant to this feature
- Key file paths that will be modified

Write files to: `{ralph-directory}/sessions/{session-name}/`

**Note:** The Ralph directory is where `ralph.sh` is located. Common locations:
- `.ralph/sessions/` (if Ralph is in `.ralph/`)
- `scripts/ralph/sessions/` (if Ralph is in `scripts/ralph/`)
- Or wherever the user placed Ralph

## Step 10: Usage Instructions

After creating the session, provide usage instructions:

```bash
# Session created at:
{ralph-directory}/sessions/{session-name}/

# Review the generated PRD
cat {ralph-directory}/sessions/{session-name}/prd.json

# Adjust if needed
nano {ralph-directory}/sessions/{session-name}/prd.json

# Run Ralph with session path
{ralph-directory}/ralph.sh 25 --session {session-name}
# Or if added to package.json:
pnpm ralph 25 --session {session-name}

# Monitor progress
tail -f {ralph-directory}/sessions/{session-name}/ralph.log

# Watch learnings accumulate
tail -f {ralph-directory}/sessions/{session-name}/learnings.md

# Wake up to completed work
git checkout ralph/feature-name
git log --oneline
```

**Session artifacts preserved:**
- `prd.json` - Original PRD with task status updates
- `progress.txt` - Accumulated patterns and gotchas
- `learnings.md` - Structured learnings from each task

## Step 11: Tips and Gotchas

**Common pitfalls to avoid:**

1. **Tasks too large:**
   - Break into smaller pieces
   - Each task should take 5-15 minutes
   - Focus: one file, one component, one feature

2. **Acceptance criteria vague:**
   - Make them objective and measurable
   - Include file paths, function signatures, validation commands
   - Avoid "good", "clean", "professional"

3. **Missing validation:**
   - Always include "typecheck passes"
   - Add "test passes" if tests exist
   - Consider "build passes" for complex changes

4. **Dependencies wrong:**
   - Use priority to express ordering
   - Lower number = higher priority
   - Test: run tasks mentally in priority order

5. **Too many tasks:**
   - Start with 3-5 tasks for first Ralph session
   - Can create multiple PRDs for large features
   - Quality over quantity

## Examples

### Example 1: Add Simple Component

```json
{
  "branchName": "ralph/add-user-card",
  "agent": "claude",
  "validationCommands": {
    "typecheck": "pnpm typecheck"
  },
  "userStories": [
    {
      "id": "COMP-001",
      "title": "Create UserCard component",
      "acceptanceCriteria": [
        "File exists: apps/web/src/components/UserCard.tsx",
        "Has props: { user: { name: string, email: string } }",
        "Displays user name (h3)",
        "Displays user email (paragraph, secondary color)",
        "typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Use Tailwind classes for styling"
    },
    {
      "id": "COMP-002",
      "title": "Add UserCard to page",
      "acceptanceCriteria": [
        "Imports UserCard in apps/web/src/profile/page.tsx",
        "Renders UserCard with sample data",
        "typecheck passes"
      ],
      "priority": 2,
      "passes": false,
      "notes": "Use dummy user data for testing"
    }
  ]
}
```

### Example 2: Add API Endpoint

```json
{
  "branchName": "ralph/add-user-api",
  "agent": "codex",
  "model": "gpt-5.1",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test"
  },
  "userStories": [
    {
      "id": "API-001",
      "title": "Create GET /users endpoint",
      "acceptanceCriteria": [
        "File exists: apps/web/src/app/api/users/route.ts",
        "Returns array of users with id, name, email",
        "Returns 200 status",
        "typecheck passes",
        "test passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Use Next.js App Router route"
    },
    {
      "id": "API-002",
      "title": "Create POST /users endpoint",
      "acceptanceCriteria": [
        "Handles POST in apps/web/src/app/api/users/route.ts",
        "Accepts { name: string, email: string } body",
        "Returns created user with generated id",
        "Returns 201 status",
        "typecheck passes",
        "test passes"
      ],
      "priority": 2,
      "passes": false,
      "notes": "Validate input with Zod schema"
    }
  ]
}
```

### Example 3: Fix Bug

```json
{
  "branchName": "ralph/fix-login-bug",
  "agent": "claude",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test"
  },
  "userStories": [
    {
      "id": "BUG-001",
      "title": "Fix login form not submitting",
      "acceptanceCriteria": [
        "Identify bug in apps/web/src/components/LoginForm.tsx",
        "Fix onSubmit handler to call auth.login()",
        "Add loading state during submission",
        "Test: login form submits successfully",
        "typecheck passes",
        "test passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Check console for error: 'onSubmit not defined'"
    }
  ]
}
```

## When to Use This Command

Use `/ralph:plan` (or `/ralph:setup`) when you want to:

- Create a Ralph session from a spec/plan file
- Run Ralph on a new feature
- Convert a vague idea into a structured PRD
- Get help breaking down complex features
- Ensure tasks are atomic and measurable
- Set up proper validation commands
- Use a workflow like `test-coverage`

**Don't use** when you:

- Already have a well-defined PRD and session created
- Just want to run Ralph (use `./ralph.sh` directly)
- Need to debug existing Ralph session

## After PRD Creation

1. Review the generated prd.json
2. Edit manually if needed
3. Run: `pnpm ralph 25`
4. Monitor: `tail -f .claude/ralph/progress.txt`
5. Review: `git log --oneline` after completion

Remember: Ralph works best with small, well-defined tasks. Start simple, iterate!
