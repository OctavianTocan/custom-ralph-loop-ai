# Examples

This directory contains example files to help you get started with Ralph.

## Files

- `prd.json.example` - Template PRD (Product Requirements Document) showing the structure and format for defining tasks
- `prd.test-coverage.example` - Template PRD for the test-coverage workflow
- `prd.validation-blocking.example` - Template PRD demonstrating validation blocking feature (tasks requiring human intervention)

## Usage

### Interactive Interview (Recommended)

The easiest way to create a session is through Ralph's interactive interview:

```bash
# CLI-based interactive interview
.ralph/ralph-interview.sh

# Or use the AI command
/ralph:interview
```

Ralph will ask you questions and automatically generate a PRD. No manual editing required!

### Basic Session

Copy the example file to create a new session:

```bash
# Create a new session directory
mkdir -p .ralph/sessions/my-feature

# Copy the example PRD
cp .ralph/examples/prd.json.example .ralph/sessions/my-feature/prd.json

# Edit with your tasks
nano .ralph/sessions/my-feature/prd.json
```

Or use the `/ralph:setup` command (if installed) to interactively create a PRD.

### Test Coverage Workflow

For improving test coverage:

```bash
# Create coverage session
mkdir -p .ralph/sessions/coverage-sprint
cp .ralph/examples/prd.test-coverage.example .ralph/sessions/coverage-sprint/prd.json

# Edit coverage target and command
nano .ralph/sessions/coverage-sprint/prd.json

# Run with workflow
.ralph/ralph.sh 25 --session coverage-sprint --workflow test-coverage
```

### Validation Blocking Example

For tasks that require human intervention or external tools:

```bash
# Create session with mixed automation/human tasks
mkdir -p .ralph/sessions/webapp-ui
cp .ralph/examples/prd.validation-blocking.example .ralph/sessions/webapp-ui/prd.json

# Edit tasks as needed
nano .ralph/sessions/webapp-ui/prd.json

# Run Ralph - it will complete automated tasks and gracefully exit when blocked
.ralph/ralph.sh 25 --session webapp-ui

# After Ralph exits with VALIDATION_BLOCKED:
# 1. Check progress.txt for handoff document
# 2. Resolve blockers (set env vars, verify in browser, etc.)
# 3. Mark validated tasks as passes: true in prd.json
# 4. Continue if needed: .ralph/ralph.sh 5 --session webapp-ui
```

**Use this pattern when:**
- Tasks require browser-based visual verification
- E2E tests need environment variables not available to Ralph
- Manual QA or human judgment is required
- External services (databases, APIs) aren't accessible

## Real-World Examples

For comprehensive, end-to-end examples with detailed walkthroughs, see:

**[docs/EXAMPLES.md](../docs/EXAMPLES.md)** - Complete examples including:
- Improving test coverage on new projects
- Incremental coverage on existing codebases
- Daily coverage improvement routines
- CI/CD integration
- Team workflows and coverage sprints
- Custom coverage reporting
- Troubleshooting common issues
