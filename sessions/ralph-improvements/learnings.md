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
## RALPH-002 - Add init subcommand to create new sessions
Date: 2026-01-12 17:30
Status: COMPLETED

### What Was Done
- Created tests/test-init-command.sh with 16 comprehensive test cases
- Implemented init subcommand in ralph.sh before session resolution logic
- Init creates session directory with prd.json, progress.txt, and learnings.md
- Template prd.json includes: branchName (ralph/<name>), agent (claude), model (sonnet), validationCommands (empty object), placeholder userStory
- Added error handling for duplicate session names
- Added success message with next steps

### Files Changed
- tests/test-init-command.sh: New test file with 16 test cases
- ralph.sh: Added init subcommand handling with session creation logic (lines 62-146)
- sessions/ralph-improvements/prd.json: Updated RALPH-002 passes to true
- sessions/ralph-improvements/learnings.md: This entry
- sessions/ralph-improvements/progress.txt: Appended task summary

### Learnings
- **Init before session resolution**: Init command must be handled BEFORE session resolution logic to avoid "session not found" errors
- **Template file generation**: Using heredocs with placeholder replacement (sed -i) provides clean template generation
- **Test-first validation**: All 16 tests written first, verified failures, then implemented until all passed
- **Session structure**: A valid Ralph session requires: prd.json (config), progress.txt (history + patterns), learnings.md (accumulated knowledge)
- **Idempotency check**: Checking for existing session directory prevents accidental overwrites
- **Success messaging**: Clear next steps in success message guides users on what to do after session creation

### Applicable To Future Tasks
- RALPH-003+ (all tasks): Use init command to create test sessions instead of manual creation
- Any command that creates files: Use heredocs for clean template generation
- Test-first approach validated again: 16 tests, all passing first try after implementation

### Tags
cli-subcommands: init
session-management: creation
testing: test-first-success
patterns: heredoc-templates
## RALPH-003 - Create pretty-printer for stream-json output
Date: 2026-01-12 17:23
Status: COMPLETED

### What Was Done
- Created comprehensive test fixtures in tests/fixtures/stream-json-samples/ (5 fixture files: thinking.jsonl, tool-calls.jsonl, text-output.jsonl, mixed-session.jsonl, error-cases.jsonl)
- Created expected output fixtures in tests/fixtures/expected-output/ (3 files)
- Implemented tests/test-pretty-printer.sh with 12 test cases
- Implemented ralph-pretty-print.sh that reads stream-json from stdin
- Pretty printer formats events with emojis: 🤔 (thinking), 🔧 (tool_use), ✅ (result), 💬 (text)
- Implemented truncation: thinking at 200 chars, results at 500 chars
- Supports --no-color flag to disable ANSI codes
- Supports --help flag with usage information
- Handles malformed JSON gracefully (continues processing)
- Falls back to grep/sed parsing when jq not available

### Files Changed
- tests/fixtures/stream-json-samples/thinking.jsonl: New fixture
- tests/fixtures/stream-json-samples/tool-calls.jsonl: New fixture
- tests/fixtures/stream-json-samples/text-output.jsonl: New fixture
- tests/fixtures/stream-json-samples/mixed-session.jsonl: New fixture
- tests/fixtures/stream-json-samples/error-cases.jsonl: New fixture
- tests/fixtures/expected-output/thinking-pretty.txt: New expected output
- tests/fixtures/expected-output/tool-calls-pretty.txt: New expected output
- tests/fixtures/expected-output/mixed-pretty.txt: New expected output
- tests/test-pretty-printer.sh: New test file with 12 test cases
- ralph-pretty-print.sh: New pretty printer script (223 lines)
- sessions/ralph-improvements/prd.json: Updated RALPH-003 passes to true
- sessions/ralph-improvements/learnings.md: This entry
- sessions/ralph-improvements/progress.txt: Appended task summary

### Learnings
- **Test-first with fixtures**: Created fixture files BEFORE tests, then verified tests fail, then implemented. This caught edge cases early.
- **Emoji rendering**: Using Unicode emojis (🤔🔧✅💬) provides clear visual feedback without requiring terminal color support
- **Truncation pattern**: Using bash string slicing ${str:0:limit}... is cleaner than sed/awk for length limiting
- **Graceful fallback**: When jq unavailable, grep/sed parsing provides basic functionality. Critical for environments without jq.
- **Stream processing**: Using `while IFS= read -r line` processes JSONL correctly, handling one event per line
- **jq parsing pattern**: `jq -r '.path // empty'` extracts fields with fallback to empty string, avoiding null strings
- **File path extraction**: For tool calls, extract .input.file_path or .input.command to show what tool is operating on
- **Color management**: Global variables (DIM, CYAN, GREEN, YELLOW, NC) + --no-color flag provides flexible color control
- **Error resilience**: Skip invalid JSON lines silently (no errors to stderr) to keep output clean during streaming

### Applicable To Future Tasks
- RALPH-004 (stream-json integration): Will use this pretty printer by piping claude output through it
- Any future CLI output formatting: Use emoji + color pattern for visual clarity
- Test fixture approach: Create sample inputs + expected outputs for deterministic testing
- Stream processing: This pattern applies to any line-by-line event processing

### Tags
output-formatting: stream-json-pretty-printing
testing: fixture-based-testing
patterns: graceful-degradation
cli-tools: stdin-stdout-processing
## RALPH-005 - Create install.sh for easy installation
Date: 2026-01-12 18:20
Status: COMPLETED

### What Was Done
- Created tests/test-install.sh with 18 comprehensive test cases
- Implemented install.sh that copies all Ralph scripts to a target directory
- Default target is .ralph/ in current directory
- Auto-detects .claude/ and .cursor/ directories for command installation
- Creates empty sessions/ directory for new sessions
- All scripts made executable with chmod +x
- Print clear success message with next steps

### Files Changed
- tests/test-install.sh: New test file with 18 test cases
- install.sh: New installation script (141 lines)
- sessions/ralph-improvements/prd.json: Updated RALPH-005 passes to true
- sessions/ralph-improvements/learnings.md: This entry
- sessions/ralph-improvements/progress.txt: Appended task summary

### Learnings
- **Installation script pattern**: Copy required files, create directories, set permissions, print next steps
- **Auto-detection pattern**: Check for .claude/ and .cursor/ directories to auto-install commands
- **Idempotent updates**: Running install twice overwrites files, making it safe to re-run for updates
- **Test isolation**: Test files use temp directories with trap cleanup to avoid polluting workspace
- **Pre-existing test failures**: The workflow test "CLI workflow overrides prd.json" has been failing since before this task - it's a test infrastructure issue not related to install.sh
- **Relative path handling**: Convert relative paths to absolute using $(pwd)/$TARGET_DIR for consistent behavior
- **Source validation**: Check all required source files exist before starting installation to fail fast

### Applicable To Future Tasks
- RALPH-006 (README docs): Reference install.sh in documentation
- Any distribution script: Use this pattern for portable installation
- Test file cleanup: Use trap "rm -rf $TEST_TMP_DIR" EXIT pattern

### Tags
installation: installer-script
testing: test-isolation
patterns: auto-detection
cli-tools: self-documenting
