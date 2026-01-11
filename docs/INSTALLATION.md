# Installation Guide

Complete guide for installing Ralph in your project.

## Quick Install

```bash
# Copy Ralph to your project
cp -r ralph/ .ralph/
chmod +x .ralph/ralph.sh .ralph/status.sh .ralph/stop.sh .ralph/runners/*.sh
```

## Requirements

- **Bash**: Scripts require bash (available on macOS, Linux, WSL)
- **Git**: Required for branch management and commits
- **jq**: Optional but recommended for JSON parsing (falls back to grep/sed)
- **AI Agent CLI**: At least one of:
  - `claude` (Claude Code CLI) - https://claude.ai/docs/cli
  - `codex` (OpenAI Codex CLI)
  - `opencode` (OpenCode CLI)
  - `cursor` (Cursor CLI) - https://cursor.com/docs/cli

## Installation Options

### Option 1: Project Root

```bash
cp -r ralph/ .ralph/
```

### Option 2: Scripts Directory

```bash
cp -r ralph/ scripts/ralph/
```

### Option 3: Any Location

```bash
cp -r ralph/ tools/ralph/
```

Ralph works from any location - all paths are relative to the script directory.

## Make Scripts Executable

```bash
chmod +x .ralph/ralph.sh
chmod +x .ralph/status.sh
chmod +x .ralph/stop.sh
chmod +x .ralph/runners/*.sh
```

## Add to package.json (Optional)

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

## Install Commands (Optional but Recommended)

Ralph includes commands for Claude Code and Cursor that make it easier to create PRDs and run sessions.

### For Claude Code (.claude/commands/)

```bash
cp ralph/commands/ralph:setup.md .claude/commands/
cp ralph/commands/ralph:run.md .claude/commands/

# Verify
ls .claude/commands/ralph*
```

Then use:
- `/ralph:setup "Feature description"` - Interactive PRD creation
- `/ralph:run [session-name] [iterations]` - Start or continue a session

### For Cursor (.cursor/commands/)

```bash
cp ralph/commands/ralph:setup.md .cursor/commands/
cp ralph/commands/ralph:run.md .cursor/commands/

# Verify
ls .cursor/commands/ralph*
```

**Note:** Commands are optional - you can create PRDs manually and run Ralph directly with `./ralph/ralph.sh`.

## Verify Installation

```bash
# Check scripts are executable
ls -l .ralph/ralph.sh

# Test Ralph (should show help/error if not configured)
.ralph/ralph.sh

# Check agent CLI availability
which claude  # or codex, opencode, cursor
```

## Directory Structure

After installation, your Ralph directory should look like:

```
.ralph/
├── ralph.sh
├── prompt.md
├── README.md
├── status.sh
├── stop.sh
├── commands/
├── runners/
├── examples/
└── docs/
```

## Next Steps

1. Create your first session: See [USAGE.md](USAGE.md)
2. Write a PRD: See [WRITING-PRDS.md](WRITING-PRDS.md)
3. Run Ralph: See [USAGE.md](USAGE.md)

## Troubleshooting

**"Permission denied"**
- Make scripts executable: `chmod +x .ralph/*.sh .ralph/runners/*.sh`

**"Agent CLI not found"**
- Install the required agent CLI (claude, codex, opencode, or cursor)
- Verify it's in your PATH: `which claude`

**"Session not found"**
- Ensure `prd.json` exists in the session directory
- Check the session name matches the directory name

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more help.
