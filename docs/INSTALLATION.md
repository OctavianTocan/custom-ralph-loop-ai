# Installation Guide

Complete guide for installing Ralph in your project or using it standalone.

## Zero-Setup Quick Start (Recommended)

Ralph is clone-to-ready with sensible defaults:

```bash
# Clone Ralph
git clone https://github.com/OctavianTocan/ralph-ai-coding-loop.git
cd ralph-ai-coding-loop

# Bootstrap (sets permissions, creates sessions structure)
./scripts/setup.sh

# You're ready! Create your first session
./ralph.sh init my-feature
./ralph.sh 10 --session my-feature
```

That's it! No configuration files, no manual setup.

## Requirements

- **Bash**: Scripts require bash (available on macOS, Linux, WSL)
- **Git**: Required for branch management and commits
- **jq**: Optional but recommended for JSON parsing (falls back to grep/sed)
- **AI Agent CLI**: At least one of:
  - `claude` (Claude Code CLI) - https://claude.ai/docs/cli
  - `codex` (OpenAI Codex CLI)
  - `opencode` (OpenCode CLI)
  - `cursor` (Cursor CLI) - https://cursor.com/docs/cli

## Installation into Existing Project

### Automatic Installation (Recommended)

```bash
# From your project root
git clone https://github.com/OctavianTocan/ralph-ai-coding-loop.git /tmp/ralph && \
  /tmp/ralph/install.sh && \
  rm -rf /tmp/ralph
```

This automatically:
- Copies Ralph to `.ralph/`
- Sets permissions on all scripts
- Detects and installs commands for `.claude/` or `.cursor/` if present

### Manual Installation

```bash
# 1. Copy Ralph to your project
cp -r ralph/ .ralph/
chmod +x .ralph/ralph.sh .ralph/status.sh .ralph/stop.sh .ralph/runners/*.sh

# 2. Verify installation
.ralph/ralph.sh --version
```

## Installation Options

### Option 1: Project Root (Default)

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

If you manually copy files without using `install.sh` or `scripts/setup.sh`:

```bash
chmod +x .ralph/ralph.sh
chmod +x .ralph/status.sh
chmod +x .ralph/stop.sh
chmod +x .ralph/runners/*.sh
chmod +x .ralph/plugins/*.plugin.sh
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
