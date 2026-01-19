# Interactive Interview Example

This document shows an example interaction with Ralph's interactive interview feature.

## Using the CLI Script

```bash
$ ./ralph-interview.sh

========================================================================
RALPH INTERACTIVE INTERVIEW
========================================================================

Welcome! I'll ask you some questions to understand your requirements,
then I'll generate a PRD (Product Requirements Document) that Ralph can execute.

This should take about 5-10 minutes.


📋 Session Information

❓ What would you like to call this session?
> user-authentication

✓ Session: 2026-01-19-user-authentication


🎯 Feature Description

❓ What feature or task would you like Ralph to implement?
> Add user authentication with email and password

ℹ Feature: Add user authentication with email and password

❓ What's the high-level goal of this work? [Implement Add user authentication with email and password]
> Enable users to sign up and log in securely

❓ Are there existing files or components this should integrate with? (optional)
> No, starting from scratch


✅ Validation Commands

Ralph will run these commands after each task to ensure quality.

❓ Run typecheck? [Y/n]
> y

❓ Typecheck command: [pnpm typecheck]
> pnpm typecheck

❓ Run linter? [Y/n]
> y

❓ Lint command: [pnpm lint]
> pnpm lint

❓ Run tests? [Y/n]
> y

❓ Test command: [pnpm test]
> pnpm test

❓ Run build? [Y/n]
> n


🤖 Agent Selection

Available agents:
  - claude (default, well-integrated)
  - codex (OpenAI models)
  - opencode (provider flexibility)
  - cursor (Cursor-specific, requires model)

❓ Which agent would you like to use? [claude]
> claude

✓ Agent: claude

❓ Model (optional, leave blank for default):
> sonnet

✓ Model: sonnet


📝 Task Breakdown

Let's break down the feature into atomic tasks (5-15 minutes each).

Based on your description, I suggest these tasks:

  1. [Main implementation task]
  2. [Add tests]
  3. [Update documentation]

❓ Would you like to define tasks manually? [y/N]
> y

Enter tasks one by one. Press Enter with empty title to finish.

❓ Task 1 title:
> Install and configure authentication dependencies

  Acceptance criteria (one per line, blank line when done):
  > Dependencies installed: next-auth, bcryptjs
  > Configuration file created: auth.config.ts
  > Environment variables documented in .env.example
  >

  ❓ Complexity (small/medium/large): [medium]
  > small

❓ Task 2 title:
> Create authentication API routes

  Acceptance criteria (one per line, blank line when done):
  > API route exists: /api/auth/[...nextauth]/route.ts
  > Supports email/password provider
  > Session handling configured
  > Typecheck passes
  >

  ❓ Complexity (small/medium/large): [medium]
  > medium

❓ Task 3 title:
> Create login component

  Acceptance criteria (one per line, blank line when done):
  > Component exists: components/LoginForm.tsx
  > Has email and password fields
  > Form validation implemented
  > Handles auth errors gracefully
  > Typecheck passes
  >

  ❓ Complexity (small/medium/large): [medium]
  > medium

❓ Task 4 title:
> Create signup component

  Acceptance criteria (one per line, blank line when done):
  > Component exists: components/SignupForm.tsx
  > Password confirmation field
  > Email validation
  > Account creation works
  > Typecheck passes
  >

  ❓ Complexity (small/medium/large): [medium]
  > medium

❓ Task 5 title:
> Add authentication tests

  Acceptance criteria (one per line, blank line when done):
  > Tests for login flow
  > Tests for signup flow
  > Tests for session management
  > All tests pass
  >

  ❓ Complexity (small/medium/large): [medium]
  > medium

❓ Task 6 title:
>

✓ Defined 5 tasks


📋 Review

Session: 2026-01-19-user-authentication
Feature: Add user authentication with email and password
Agent: claude
Model: sonnet
Tasks: 5

❓ Does this look correct? [Y/n]
> y


🔨 Generating Session Files

✓ Created prd.json
✓ Created progress.txt
✓ Created learnings.md


========================================================================
✅ SESSION CREATED
========================================================================

Session files created successfully!

Location: ./sessions/2026-01-19-user-authentication

Files:
  📝 prd.json      - Task definitions
  📋 progress.txt  - Codebase patterns
  📚 learnings.md  - Accumulated learnings

Next steps:

  # Start Ralph
  ./ralph.sh 25 --session 2026-01-19-user-authentication

  # Monitor progress
  tail -f ./sessions/2026-01-19-user-authentication/ralph.log

  # Check status
  ./status.sh

  # View learnings
  cat ./sessions/2026-01-19-user-authentication/learnings.md

Tips:
  - Ralph runs autonomously, implementing tasks one by one
  - Each task is validated before committing
  - Progress is saved in real-time
  - You can stop with: ./stop.sh

Happy coding! 🚀
```

## Using the AI Command

When using Claude Code or Cursor, simply type:

```
/ralph:interview
```

The AI will conduct a conversational interview with you, asking questions about:
- What you want to build
- Validation commands
- Agent/model preferences
- Task breakdown
- Acceptance criteria

Then it will automatically generate the PRD and session files for you.

## Generated Files

After the interview, you'll have:

### prd.json
```json
{
  "branchName": "ralph/user-authentication",
  "agent": "claude",
  "model": "sonnet",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "lint": "pnpm lint",
    "test": "pnpm test"
  },
  "userStories": [
    {
      "id": "TASK-001",
      "title": "Install and configure authentication dependencies",
      "acceptanceCriteria": [
        "Dependencies installed: next-auth, bcryptjs",
        "Configuration file created: auth.config.ts",
        "Environment variables documented in .env.example"
      ],
      "priority": 1,
      "complexity": "small",
      "passes": false
    },
    {
      "id": "TASK-002",
      "title": "Create authentication API routes",
      "acceptanceCriteria": [
        "API route exists: /api/auth/[...nextauth]/route.ts",
        "Supports email/password provider",
        "Session handling configured",
        "Typecheck passes"
      ],
      "priority": 2,
      "complexity": "medium",
      "passes": false
    },
    {
      "id": "TASK-003",
      "title": "Create login component",
      "acceptanceCriteria": [
        "Component exists: components/LoginForm.tsx",
        "Has email and password fields",
        "Form validation implemented",
        "Handles auth errors gracefully",
        "Typecheck passes"
      ],
      "priority": 3,
      "complexity": "medium",
      "passes": false
    },
    {
      "id": "TASK-004",
      "title": "Create signup component",
      "acceptanceCriteria": [
        "Component exists: components/SignupForm.tsx",
        "Password confirmation field",
        "Email validation",
        "Account creation works",
        "Typecheck passes"
      ],
      "priority": 4,
      "complexity": "medium",
      "passes": false
    },
    {
      "id": "TASK-005",
      "title": "Add authentication tests",
      "acceptanceCriteria": [
        "Tests for login flow",
        "Tests for signup flow",
        "Tests for session management",
        "All tests pass"
      ],
      "priority": 5,
      "complexity": "medium",
      "passes": false
    }
  ]
}
```

### progress.txt
```markdown
# Ralph Progress Log

Session: 2026-01-19-user-authentication
Feature: Add user authentication with email and password
Goal: Enable users to sign up and log in securely
Branch: ralph/user-authentication
Created: Sun Jan 19 10:16:00 UTC 2026

---

## Codebase Patterns

(Ralph will discover patterns here during execution)

---
```

### learnings.md
```markdown
# Learnings: 2026-01-19-user-authentication

Session: 2026-01-19-user-authentication
Feature: Add user authentication with email and password
Branch: ralph/user-authentication
Created: Sun Jan 19 10:16:00 UTC 2026

---

(Ralph will append learnings here after each completed task)
```

## Running Ralph

After the interview completes, start Ralph:

```bash
./ralph.sh 25 --session 2026-01-19-user-authentication
```

Ralph will:
1. Read the generated PRD
2. Implement tasks one by one
3. Run validation after each task
4. Commit when validation passes
5. Learn from each task and apply those learnings to future tasks

## Benefits

- **No manual PRD writing**: Just answer questions
- **Guided task breakdown**: Ralph suggests appropriate task sizes
- **Measurable acceptance criteria**: Enforces objective, verifiable criteria
- **Proper validation**: Ensures quality gates are configured
- **Ready to run**: Session is immediately executable
