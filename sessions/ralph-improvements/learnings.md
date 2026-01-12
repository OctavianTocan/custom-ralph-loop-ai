# Learnings: Ralph Improvements

Session: ralph-improvements
Branch: ralph-improvements

---

## RALPH-001 - Add --help and --version flags to ralph.sh
Date: 2026-01-12 17:15
Status: COMPLETED

### What Was Done
- Created tests/test-ralph-flags.sh with 13 comprehensive test cases
- Implemented --help and --version flags in ralph.sh
- Added show_help() and show_version() functions
- Used git describe for dynamic version detection
- Added pre-scan loop to handle flags before argument parsing

### Files Changed
- tests/test-ralph-flags.sh: New test file with 13 test cases
- ralph.sh: Added VERSION variable, show_help(), show_version(), and flag pre-scan loop

### Learnings
- **Flag handling order**: Flags like --help/--version must be handled BEFORE session resolution to exit immediately
- **Pre-scan pattern**: Using a for loop to check for specific flags before the main argument parser ensures they're handled first regardless of argument position
- **Git version detection**: Using `git describe --tags` provides automatic version info, falling back to hardcoded version if git isn't available
- **Test-first success**: Writing tests first caught the requirement that flags must exit with code 0 (success)
- **Test helper patterns**: Using test_start(), assert_* functions, and test_pass() provides clean test output

### Applicable To Future Tasks
- RALPH-002 (init subcommand): Will use similar pre-scan pattern for subcommands
- All future CLI flags: Use the pre-scan loop pattern to add new flags
- All tasks: Test-first development caught edge cases early (exit codes, output format)

### Tags
cli-flags: help-version
testing: test-first-success
patterns: flag-pre-scan
