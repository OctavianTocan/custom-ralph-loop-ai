# Examples

This directory contains example files to help you get started with Ralph.

## Files

- `prd.json.example` - Template PRD (Product Requirements Document) showing the structure and format for defining tasks
- `prd.test-coverage.example` - Template PRD for the test-coverage workflow

## Usage

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

Or use the `/ralph:plan` command (if installed) to interactively create a PRD.

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
