---
name: ralph-interview
description: Interactive PRD creation through AI-guided interview
argument-hint: "[session-name]"
---

# Ralph Interactive Interview

This command starts an interactive interview session where Ralph asks you questions to understand your requirements and automatically generates a PRD (prd.json) for you.

## Your Task

You will conduct an interactive interview with the user to gather requirements and generate a PRD automatically.

### Interview Flow

1. **Welcome & Introduction**
   - Explain what we're doing: "I'll ask you some questions to understand your requirements, then I'll generate a PRD for Ralph to execute."
   - Ask for session name if not provided: "What would you like to call this session? (e.g., 'user-authentication', 'add-dashboard')"

2. **Feature Understanding**
   - "What feature or task would you like Ralph to implement?"
   - "What's the high-level goal of this work?"
   - "Are there existing files or components this should integrate with?"

3. **Project Structure & Validation**
   - "What validation commands should Ralph run after each task?"
     - Suggest common ones: typecheck, lint, test, build
     - Ask for the actual commands (e.g., "pnpm typecheck", "npm test")
   - "Is this a monorepo? If yes, which packages are affected?"

4. **Agent & Model Preferences**
   - "Which AI agent would you like Ralph to use during execution?"
     - Options: claude (default), codex, opencode, cursor
     - Explain briefly what each offers if user is unsure
   - "Which model would you like Ralph to use?"
     - Explain this is the model Ralph will use during execution, not the interviewer
     - Provide examples based on agent selection:
       - Claude: sonnet (balanced), opus (most capable), haiku (faster)
       - Codex: gpt-5.1, gpt-5.2-codex, etc.
       - OpenCode: anthropic/claude-3-5-sonnet-20241022 (provider/model format)
       - Cursor: REQUIRED - e.g., claude-sonnet-4-20250514
     - Optional for most agents, required for cursor
     - Leave blank to use agent's default

5. **Task Breakdown**
   - "Let me break this down into atomic tasks. Each task should take 5-15 minutes."
   - Present proposed task breakdown
   - "Does this breakdown make sense? Would you like to add, remove, or modify any tasks?"

6. **Acceptance Criteria**
   - For each task, ask: "How will we know this task is complete?"
   - Guide toward measurable criteria:
     - File exists at path X
     - Function has signature Y
     - Tests pass
     - Build succeeds

7. **Dependencies & Priority**
   - "Which tasks depend on others? What order should these run in?"
   - Assign priority numbers based on dependencies

8. **Review & Confirmation**
   - Present complete PRD structure
   - "Does this look correct? Any changes needed?"

9. **Generate Session Files**
   - Create session directory: `.ralph/sessions/YYYY-MM-DD-{session-name}/`
   - Generate prd.json with all collected information
   - Create progress.txt with initial patterns
   - Create learnings.md (empty, ready for Ralph)

10. **Next Steps**
    - Show command to start Ralph: `.ralph/ralph.sh 25 --session {session-name}`
    - Show monitoring commands
    - Explain what will happen next

### Interview Guidelines

**Be conversational and friendly:**
- Use natural language, not robotic prompts
- Adapt follow-up questions based on responses
- Clarify when user seems uncertain
- Provide examples when helpful

**Keep it concise:**
- Don't ask unnecessary questions
- Infer reasonable defaults when appropriate
- Focus on non-obvious details

**Validate responses:**
- Check that commands are valid shell commands
- Verify file paths make sense
- Ensure task sizes are appropriate (5-15 min each)

**Provide guidance:**
- Suggest task breakdowns
- Recommend acceptance criteria
- Help with dependency ordering
- Share best practices

### Example Interview Transcript

```
🤖 Ralph: Hi! I'll help you create a PRD for Ralph to execute. What would you like to call this session?

👤 User: user-authentication

🤖 Ralph: Great! What feature or task would you like Ralph to implement?

👤 User: I need to add user authentication with email/password to my web app

🤖 Ralph: Perfect. What's your project structure? Do you have existing auth infrastructure I should integrate with?

👤 User: It's a Next.js app with no auth yet. I want to use NextAuth.js

🤖 Ralph: Got it. What validation commands should Ralph run after each task? For example:
   - pnpm typecheck
   - pnpm test
   - pnpm build

👤 User: pnpm typecheck and pnpm test

🤖 Ralph: Which AI agent would you like Ralph to use during execution? (claude is recommended)

👤 User: claude is fine

🤖 Ralph: Which model would you like Ralph to use?
   Common models for Claude:
   - sonnet (Claude 3.5 Sonnet - balanced)
   - opus (Claude Opus - most capable)
   - haiku (Claude Haiku - faster)
   Leave blank to use agent's default

👤 User: sonnet

🤖 Ralph: Let me break this down into tasks:
   1. Install NextAuth.js dependencies
   2. Configure NextAuth.js with email provider
   3. Create auth API routes
   4. Add login page component
   5. Add signup page component
   6. Add protected route wrapper

   Does this breakdown make sense?

👤 User: Yes, looks good

🤖 Ralph: Great! I'll generate the PRD now...

✅ Session created: .ralph/sessions/2026-01-19-user-authentication/
📝 PRD: .ralph/sessions/2026-01-19-user-authentication/prd.json

Next steps:
  .ralph/ralph.sh 25 --session 2026-01-19-user-authentication
  tail -f .ralph/sessions/2026-01-19-user-authentication/ralph.log
```

### PRD Generation

After completing the interview, generate a complete prd.json with:

```json
{
  "branchName": "ralph/session-name",
  "agent": "claude",
  "model": "sonnet",
  "validationCommands": {
    "typecheck": "pnpm typecheck",
    "test": "pnpm test"
  },
  "userStories": [
    {
      "id": "TASK-001",
      "title": "Descriptive task title",
      "acceptanceCriteria": [
        "Measurable criteria 1",
        "Measurable criteria 2"
      ],
      "priority": 1,
      "complexity": "medium",
      "passes": false,
      "notes": "Additional context"
    }
  ]
}
```

### Session Directory Structure

Create:
```
.ralph/sessions/{date}-{session-name}/
  ├── prd.json          # Generated PRD
  ├── progress.txt      # Initial patterns
  └── learnings.md      # Empty, ready for Ralph
```

### Tips

- **Task sizing:** Each task should be 5-15 minutes (one component, one function, one file)
- **Acceptance criteria:** Must be measurable and objective
- **Priority:** Lower numbers run first (express dependencies)
- **Validation:** Always include typecheck at minimum

### When to Use

Use this command when:
- Starting a new Ralph session
- You have a rough idea but need help structuring it
- You want Ralph to guide you through PRD creation
- You prefer conversational interface over manual PRD writing

### Integration with Existing Commands

This command complements:
- `/ralph:setup` - For manual PRD creation with AI assistance
- `/ralph:run` - To execute the generated PRD

The interview approach is more conversational and requires less upfront knowledge from the user.
