# Configuration Reference

Complete reference for configuring Ralph and PRDs.

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

## Fields

### Top-Level Fields

| Field | Required | Description |
|-------|----------|-------------|
| `branchName` | ✅ Yes | Git branch to create/use |
| `agent` | ❌ No | AI agent to use (defaults to `"claude"`) |
| `model` | ❌ No* | Model to use (format depends on agent, *required for cursor) |
| `validationCommands` | ✅ Yes | Commands to run after each task |
| `userStories` | ✅ Yes | Array of tasks to complete |

### User Story Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | ✅ Yes | Unique identifier (e.g., FEAT-001, UTIL-002) |
| `title` | ✅ Yes | Human-readable description |
| `acceptanceCriteria` | ✅ Yes | Array of verifiable requirements |
| `priority` | ✅ Yes | Number (lower = runs first) |
| `passes` | ✅ Yes | Boolean (false = not done, true = completed) |
| `notes` | ❌ No | Optional additional context for the AI |

## Agent Configuration

### Supported Agents

| Agent | CLI Command | Auto-Approval | Requirements |
|-------|-------------|---------------|--------------|
| **Claude Code** | `claude` | `--dangerously-skip-permissions` | Claude CLI installed and authenticated |
| **OpenAI Codex** | `codex` | `--full-auto` | Codex CLI installed, `OPENAI_API_KEY` set |
| **OpenCode** | `opencode` | Config file (`permission.edit: "allow"`) | OpenCode CLI installed, provider configured |
| **Cursor** | `cursor` | Full write in non-interactive mode | Cursor CLI installed, model specified in prd.json |

### Model Formats

**Claude:**
```json
{
  "agent": "claude",
  "model": "sonnet"  // or "opus", or full name
}
```

**Codex:**
```json
{
  "agent": "codex",
  "model": "gpt-5.1"  // or "gpt-5.2-codex", etc.
}
```

**OpenCode:**
```json
{
  "agent": "opencode",
  "model": "anthropic/claude-3-5-sonnet-20241022"  // provider/model format
}
```

**Cursor:**
```json
{
  "agent": "cursor",
  "model": "claude-sonnet-4-20250514"  // REQUIRED - must be specified
}
```

**Important:** If `agent` is `"cursor"`, the `model` field is **MANDATORY**.

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

Ralph runs these in order after each task. If any fail, the task is retried (up to 5 attempts).

### Command Order

Ralph runs validation commands in this order:
1. `typecheck` - TypeScript compilation
2. `lint` - Code style and quality
3. `test` - Unit and integration tests
4. `build` - Full build (often with timeout)

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

## Session Files

Each session directory contains:

- `prd.json` - Task definitions and status (updated by Ralph)
- `progress.txt` - Codebase patterns and task summaries (appended by Ralph)
- `learnings.md` - Structured learnings from each task (appended by Ralph)
- `ralph.log` - Execution log (created by Ralph)

## Customization

### Change Session Location

Sessions are stored relative to the script directory. To use a different location, modify `ralph.sh`:

```bash
# In ralph.sh, change:
SESSION_DIR="$SCRIPT_DIR/sessions/$SESSION_DIR"

# To:
SESSION_DIR="/path/to/your/sessions/$SESSION_DIR"
```

### Customize Prompt

Edit `prompt.md` to add project-specific instructions or patterns.

### Add Custom Agent

Create a new runner script in `runners/run-{agent}.sh` following the pattern of existing runners.

## Environment Variables

Ralph doesn't require any environment variables. Agent CLIs handle their own authentication:
- Claude: Uses Claude CLI authentication
- Codex: Uses `OPENAI_API_KEY` environment variable
- OpenCode: Uses OpenCode configuration
- Cursor: Uses Cursor CLI authentication

## See Also

- [WRITING-PRDS.md](WRITING-PRDS.md) - How to write effective PRDs
- [USAGE.md](USAGE.md) - How to use Ralph with PRDs
