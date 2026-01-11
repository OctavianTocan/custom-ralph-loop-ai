# Changes for Portability

This document summarizes changes made to make Ralph portable for GitHub distribution.

## Removed Hard-Coded References

### Paths
- ❌ `.claude/ralph/sessions/` → ✅ Session directory from runtime context
- ❌ Hard-coded project paths → ✅ All paths relative to `$SCRIPT_DIR`

### Commands
- ❌ `pnpm --filter chrome_extension_next` → ✅ Generic examples with placeholders
- ❌ `pnpm ralph:status` → ✅ `./status.sh` (with fallback note)
- ❌ `pnpm ralph:stop` → ✅ `./stop.sh` (with fallback note)

### Project-Specific
- ❌ References to twinmind packages → ✅ Generic package examples
- ❌ Chrome extension specific commands → ✅ Generic monorepo/single package examples

## Added Portable Features

### Documentation
- ✅ `README.md` - Complete installation guide and documentation (merged INSTALL.md content)
- ✅ `PORTABLE.md` - Explanation of portability principles
- ✅ `CHANGES.md` - This file, documenting changes
- ✅ `commands/` directory - Optional commands for Claude Code/Cursor

### Configuration
- ✅ `.gitignore` - Ignores session logs/locks, keeps structure
- ✅ All scripts use `$SCRIPT_DIR` for relative paths

## What Stays the Same

- ✅ Core functionality unchanged
- ✅ Session structure unchanged
- ✅ PRD format unchanged
- ✅ Agent support unchanged
- ✅ Validation system unchanged

## For GitHub Release

When preparing for GitHub:

1. **Include these files:**
   - `ralph.sh` (main script)
   - `prompt.md` (agent instructions)
   - `prd.json.example` (template)
   - `README.md` (documentation)
   - `INSTALL.md` (setup guide)
   - `PORTABLE.md` (portability docs)
   - `runners/*.sh` (agent runners)
   - `status.sh` (status checker)
   - `stop.sh` (stop script)
   - `.gitignore` (git ignore rules)

2. **Don't include:**
   - `sessions/` directory (user creates their own)
   - `CLAUDE.md` (project-specific)
   - `progress.txt` (project-specific)
   - `prd.json` (project-specific)

3. **Optional:**
   - `CHANGES.md` (this file) - helpful for users understanding changes

## Testing Portability

To verify Ralph works portably:

```bash
# 1. Copy to temporary location
cp -r .claude/ralph /tmp/test-ralph

# 2. Create test session
mkdir -p /tmp/test-ralph/sessions/test
cp /tmp/test-ralph/prd.json.example /tmp/test-ralph/sessions/test/prd.json

# 3. Edit prd.json with test tasks

# 4. Run from new location
cd /tmp/test-ralph
./ralph.sh 1 --session test

# Should work identically!
```

## Migration Notes

For existing users upgrading:

- **No breaking changes** - all functionality preserved
- **Paths still work** - `$SCRIPT_DIR` handles location automatically
- **Sessions preserved** - existing sessions continue to work
- **Commands updated** - Update package.json scripts if using them
