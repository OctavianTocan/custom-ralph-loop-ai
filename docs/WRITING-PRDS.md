# Writing Good PRDs

Guide to creating effective Product Requirements Documents (PRDs) for Ralph.

## PRD Structure

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

## Task Sizing

Each task must fit in one AI context window (typically 5-15 minutes of work).

### ✅ Right Size

- Single component (e.g., "Add LoginButton")
- Single API endpoint (e.g., "GET /users")
- Single utility function (e.g., "formatDate()")
- Single page/route (e.g., "/settings")
- Fix one specific bug
- Add one specific test case

### ❌ Too Big

- "Build entire auth system"
- "Implement complete dashboard"
- "Migrate all components to React"
- "Add comprehensive test suite"

### Breaking Down Large Features

**Instead of:**
```json
{
  "id": "FEAT-001",
  "title": "Build authentication system"
}
```

**Break into:**
```json
[
  { "id": "AUTH-001", "title": "Create auth context", "priority": 1 },
  { "id": "AUTH-002", "title": "Add login form", "priority": 2 },
  { "id": "AUTH-003", "title": "Add logout button", "priority": 3 },
  { "id": "AUTH-004", "title": "Add protected route wrapper", "priority": 4 }
]
```

## Acceptance Criteria

Criteria must be **measurable and verifiable**. The AI can't guess what you mean.

### ✅ Good (Measurable, Objective)

```json
{
  "acceptanceCriteria": [
    "File exists: apps/web/src/components/LoginForm.tsx",
    "Has props: { email: string, password: string, onSubmit: () => void }",
    "Renders form with email and password inputs",
    "Shows error message on invalid email",
    "typecheck passes",
    "test passes: pnpm test -- LoginForm"
  ]
}
```

### ❌ Bad (Vague, Subjective)

```json
{
  "acceptanceCriteria": [
    "Users can log in",
    "UI looks good",
    "Performance is improved",
    "Code is clean"
  ]
}
```

### Verification Examples

**File existence:**
- ✅ "File exists: apps/web/src/components/UserCard.tsx"
- ❌ "Create user card component"

**Function signatures:**
- ✅ "Has props: { user: { name: string, email: string } }"
- ❌ "Component displays user info"

**Validation:**
- ✅ "typecheck passes"
- ✅ "test passes: pnpm test -- UserCard"
- ✅ "build completes with no errors"
- ❌ "Code compiles"

**UI verification:**
- ✅ "Verify in browser: navigate to /login and confirm form renders"
- ❌ "Login form works"

## Priority Ordering

Express task dependencies using priority numbers (lower = runs first).

### Example: Authentication Feature

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

### Expressing Dependencies

If task B depends on task A, assign B a higher priority number:

```json
{
  "id": "UTIL-001",
  "title": "Add capitalize function",
  "priority": 1
},
{
  "id": "UTIL-002",
  "title": "Use capitalize in header component",
  "priority": 2  // Depends on UTIL-001
}
```

## Validation Commands

Configure validation for your project:

```json
{
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test",
    "lint": "pnpm lint",
    "build": "pnpm build"
  }
}
```

Ralph runs these in order after each task. If any fail, the task is retried.

### Monorepo Example

```json
{
  "validationCommands": {
    "typecheck": "turbo run typecheck",
    "test": "pnpm test",
    "build": "pnpm build"
  }
}
```

### Single Package Example

```json
{
  "validationCommands": {
    "typecheck": "pnpm --filter @my/package typecheck",
    "test": "pnpm --filter @my/package test"
  }
}
```

### Minimal Example

```json
{
  "validationCommands": {
    "typecheck": "pnpm typecheck"
  }
}
```

## Agent and Model Selection

### Agent Options

- `claude` - Claude Code CLI (default, well-integrated)
- `codex` - OpenAI Codex CLI
- `opencode` - OpenCode CLI (provider flexibility)
- `cursor` - Cursor CLI (requires `model` field)

### Model Selection

Format depends on agent:

- **Claude**: `sonnet`, `opus`, or full name like `claude-sonnet-4-5-20250929` (optional)
- **Codex**: `gpt-5.1`, `gpt-5.2-codex`, etc. (optional)
- **OpenCode**: `anthropic/claude-3-5-sonnet-20241022` (provider/model format, optional)
- **Cursor**: `claude-sonnet-4-20250514`, etc. (**REQUIRED** - must be specified)

**Important:** If using `cursor` agent, the `model` field is **MANDATORY**.

### Example

```json
{
  "agent": "claude",
  "model": "sonnet"
}
```

## Notes Field

Use the `notes` field to provide additional context:

```json
{
  "id": "FEAT-001",
  "title": "Add user profile component",
  "notes": "Use Tailwind classes for styling. Reference apps/web/src/components/UserCard.tsx for patterns."
}
```

Good uses:
- File locations or patterns to follow
- References to existing code
- Known gotchas or requirements
- Links to documentation

Avoid:
- Implementation details (should be in acceptance criteria)
- Vague instructions
- Duplicate information from acceptance criteria

## Complete Example

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
        "File exists: apps/web/src/components/UserProfile.tsx",
        "Has props: { user: { name: string, email: string, avatar: string } }",
        "Displays user avatar (circular, 64px)",
        "Displays user name (h1, bold)",
        "Displays email address (secondary color)",
        "typecheck passes",
        "test passes: pnpm test -- UserProfile"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Use Tailwind classes. Reference UserCard.tsx for styling patterns."
    },
    {
      "id": "PROF-002",
      "title": "Add UserProfile to profile page",
      "acceptanceCriteria": [
        "Imports UserProfile in apps/web/src/profile/page.tsx",
        "Renders UserProfile with sample user data",
        "typecheck passes"
      ],
      "priority": 2,
      "passes": false,
      "notes": "Use dummy user data for testing"
    }
  ]
}
```

## Common Patterns

### Component Creation

```json
{
  "id": "COMP-001",
  "title": "Create Button component",
  "acceptanceCriteria": [
    "File exists: components/Button.tsx",
    "Has props: { children: ReactNode, onClick: () => void, variant?: 'primary' | 'secondary' }",
    "Renders button element",
    "Applies variant styles",
    "typecheck passes"
  ]
}
```

### API Endpoint

```json
{
  "id": "API-001",
  "title": "Create GET /users endpoint",
  "acceptanceCriteria": [
    "File exists: apps/web/src/app/api/users/route.ts",
    "Returns array of users with id, name, email",
    "Returns 200 status",
    "typecheck passes",
    "test passes"
  ]
}
```

### Utility Function

```json
{
  "id": "UTIL-001",
  "title": "Add formatDate function",
  "acceptanceCriteria": [
    "Function in utils/date.ts",
    "Takes Date object or timestamp",
    "Returns formatted string (YYYY-MM-DD)",
    "Handles invalid input",
    "typecheck passes",
    "test passes"
  ]
}
```

## Tips

1. **Start small**: First PRD should have 3-5 tasks
2. **Be specific**: Include file paths, function signatures, exact requirements
3. **Test criteria**: Can you verify each criterion automatically?
4. **Order matters**: Use priority to express dependencies
5. **Review examples**: See `examples/prd.json.example` for reference

## See Also

- [CONFIGURATION.md](CONFIGURATION.md) - Complete PRD structure reference
- [USAGE.md](USAGE.md) - How to use PRDs with Ralph
