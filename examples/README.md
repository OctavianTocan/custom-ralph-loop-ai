# Examples

This directory contains example files to help you get started with Ralph.

## Files

- `prd.json.example` - Template PRD (Product Requirements Document) showing the structure and format for defining tasks

## Usage

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
