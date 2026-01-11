# Installing Ralph in Your Project

Ralph is designed to be portable and work in any project. Follow these steps to set it up.

## Quick Install

1. **Copy Ralph to your project:**
   ```bash
   # Option 1: Clone or copy the ralph directory to your project
   cp -r ralph/ .ralph/
   
   # Option 2: Or place it anywhere you prefer
   cp -r ralph/ scripts/ralph/
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x .ralph/ralph.sh
   chmod +x .ralph/status.sh
   chmod +x .ralph/stop.sh
   chmod +x .ralph/runners/*.sh
   ```

3. **Add to your package.json (optional but recommended):**
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

4. **Or use directly:**
   ```bash
   .ralph/ralph.sh 10 --session my-feature
   ```

## Directory Structure

Ralph works from any directory structure. The only requirement is that the `ralph.sh` script and its supporting files stay together:

```
.ralph/                    # Or scripts/ralph/, or any location
├── ralph.sh               # Main script
├── prompt.md              # Agent instructions
├── prd.json.example       # PRD template
├── README.md              # Documentation
├── status.sh              # Status checker
├── stop.sh                # Stop script
├── runners/               # Agent runners
│   ├── run-claude.sh
│   ├── run-codex.sh
│   ├── run-cursor.sh
│   └── run-opencode.sh
└── sessions/              # Created automatically
    └── {session-name}/
        ├── prd.json
        ├── progress.txt
        └── learnings.md
```

## Configuration

Ralph uses relative paths based on the script location, so it works regardless of where you place it:

- **Script directory**: Determined automatically from `ralph.sh` location
- **Sessions**: Stored in `{script-dir}/sessions/`
- **Logs**: Stored in `{session-dir}/ralph.log`

No configuration files needed - everything is relative to the script.

## Usage

### Create a Session

Create a session directory with a `prd.json`:

```bash
mkdir -p .ralph/sessions/my-feature
cp .ralph/prd.json.example .ralph/sessions/my-feature/prd.json
# Edit prd.json with your tasks
```

### Run Ralph

```bash
# Using package.json script
pnpm ralph 10 --session my-feature

# Or directly
.ralph/ralph.sh 10 --session my-feature
```

### Check Status

```bash
pnpm ralph:status
# Or: .ralph/status.sh
```

### Stop Ralph

```bash
pnpm ralph:stop
# Or: .ralph/stop.sh
```

## Requirements

- **Bash**: Scripts require bash (available on macOS, Linux, WSL)
- **Git**: Required for branch management and commits
- **jq**: Optional but recommended for JSON parsing (falls back to grep/sed)
- **AI Agent CLI**: At least one of:
  - `claude` (Claude Code CLI)
  - `codex` (OpenAI Codex CLI)
  - `opencode` (OpenCode CLI)
  - `cursor` (Cursor CLI)

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

## Troubleshooting

**"Session not found"**
- Ensure `prd.json` exists in the session directory
- Check the session name matches the directory name

**"Runner script not found"**
- Ensure `runners/` directory exists relative to `ralph.sh`
- Check runner script is executable: `chmod +x runners/*.sh`

**"Agent CLI not found"**
- Install the required agent CLI (claude, codex, opencode, or cursor)
- Verify it's in your PATH: `which claude`

**"Git branch errors"**
- Ensure you're in a git repository
- Check for uncommitted changes: `git status`
- Stash changes if needed: `git stash`
