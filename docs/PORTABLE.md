# Making Ralph Portable

This document explains how Ralph is designed to be portable and work in any project.

## Portability Principles

1. **No Hard-Coded Paths**: All paths are relative to the script location
2. **No Project Assumptions**: Works with any package manager, structure, or tooling
3. **Self-Contained**: All files stay together in one directory
4. **Zero Configuration**: Works out of the box, no config files needed

## How Paths Work

Ralph uses `SCRIPT_DIR` to determine its location:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

Everything is relative to this:
- Sessions: `$SCRIPT_DIR/sessions/`
- Runners: `$SCRIPT_DIR/runners/`
- Prompt: `$SCRIPT_DIR/prompt.md`

**Result**: Works whether Ralph is in `.ralph/`, `scripts/ralph/`, `/opt/ralph/`, or anywhere else.

## Removing Project-Specific References

### In prompt.md

✅ **Generic** (portable):
- "Read prd.json from session directory"
- "Run validation commands from prd.json"
- "Use your project's package manager"

❌ **Project-Specific** (removed):
- `.claude/ralph/sessions/` paths
- `pnpm --filter chrome_extension_next` commands
- Project-specific package names

### In ralph.sh

✅ **Generic** (portable):
- `$SCRIPT_DIR` for all paths
- Generic error messages
- Works with any git repository

❌ **Project-Specific** (removed):
- References to `pnpm ralph:status` (now `./status.sh`)
- Hard-coded directory paths

## Installation Flexibility

Ralph can be installed in multiple ways:

### Option 1: In Project Root
```
project/
├── .ralph/
│   ├── ralph.sh
│   └── ...
└── package.json
```

### Option 2: In Scripts Directory
```
project/
├── scripts/
│   └── ralph/
│       ├── ralph.sh
│       └── ...
└── package.json
```

### Option 3: Standalone
```
/opt/ralph/
├── ralph.sh
└── ...

project/
└── .ralph -> /opt/ralph  # Symlink
```

All work the same way!

## What Makes It Portable

1. **Relative Paths**: Everything uses `$SCRIPT_DIR`
2. **No Assumptions**: Doesn't assume package manager, structure, or tools
3. **Configurable**: Validation commands come from `prd.json`, not hard-coded
4. **Agent Agnostic**: Supports multiple agents, user chooses in `prd.json`
5. **Git Agnostic**: Works with any git workflow (just needs git)

## Testing Portability

To verify Ralph is portable:

1. **Copy to new location:**
   ```bash
   cp -r ralph/ /tmp/test-ralph/
   ```

2. **Create test session:**
   ```bash
   mkdir -p /tmp/test-ralph/sessions/test
   cp /tmp/test-ralph/examples/prd.json.example /tmp/test-ralph/sessions/test/prd.json
   ```

3. **Run from new location:**
   ```bash
   cd /tmp/test-ralph/
   ./ralph.sh 1 --session test
   ```

4. **Should work identically** regardless of where it's located!

## For GitHub Distribution

When publishing to GitHub:

1. ✅ Include all files in `ralph/` directory
2. ✅ Include `README.md` with complete installation and usage (merged INSTALL.md)
3. ✅ Include `PORTABLE.md` (this file) explaining portability
4. ✅ Include `commands/` directory for optional Claude Code/Cursor commands
5. ❌ Don't include `sessions/` directory (user creates their own)
6. ❌ Don't include project-specific examples

## Customization Points

Users can customize without modifying core files:

1. **Validation Commands**: Set in `prd.json.validationCommands`
2. **Agent Selection**: Set in `prd.json.agent`
3. **Prompt Instructions**: Modify `prompt.md` for project-specific patterns
4. **Custom Runners**: Add new runners in `runners/` directory

All customization is additive - core functionality remains portable.
