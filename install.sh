#!/bin/bash
# Ralph Installation Script
# Installs Ralph to a target directory (default: .ralph/)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Help and usage
# ============================================================================
show_help() {
  cat <<EOF
Ralph Installation Script

Usage:
  ./install.sh [target-directory]
  ./install.sh --help

Arguments:
  target-directory    Where to install Ralph (default: .ralph/)

Options:
  --help, -h          Show this help message

What gets installed:
  - ralph.sh          Main orchestrator script
  - status.sh         Session status viewer
  - stop.sh           Stop running sessions
  - watch.sh          Real-time log monitoring
  - ralph-pretty-print.sh  Stream-json formatter
  - prompt.md         Agent instructions
  - runners/          Agent runner scripts
  - sessions/         Empty sessions directory

Auto-detected integrations:
  - If .claude/ exists: copies commands to .claude/commands/
  - If .cursor/ exists: copies commands to .cursor/commands/

Examples:
  ./install.sh                  # Install to .ralph/
  ./install.sh my-ralph         # Install to my-ralph/
  ./install.sh ~/tools/ralph    # Install to absolute path

EOF
}

# Check for help flag
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
  exit 0
fi

# ============================================================================
# Configuration
# ============================================================================
TARGET_DIR="${1:-.ralph}"

# Convert to absolute path if relative
if [[ ! "$TARGET_DIR" =~ ^/ ]]; then
  TARGET_DIR="$(pwd)/$TARGET_DIR"
fi

# ============================================================================
# Validation
# ============================================================================
# Check source files exist
REQUIRED_FILES=(
  "ralph.sh"
  "status.sh"
  "stop.sh"
  "watch.sh"
  "ralph-pretty-print.sh"
  "prompt.md"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
    echo "Error: Required file not found: $SCRIPT_DIR/$file"
    echo "Please run install.sh from the Ralph repository directory."
    exit 1
  fi
done

if [[ ! -d "$SCRIPT_DIR/runners" ]]; then
  echo "Error: runners/ directory not found in $SCRIPT_DIR"
  exit 1
fi

# Check runners directory has .sh files
shopt -s nullglob
runner_files=("$SCRIPT_DIR/runners/"*.sh)
shopt -u nullglob
if [[ ${#runner_files[@]} -eq 0 ]]; then
  echo "Error: No .sh files found in $SCRIPT_DIR/runners/"
  exit 1
fi

# ============================================================================
# Installation
# ============================================================================
echo ""
echo "Installing Ralph to: $TARGET_DIR"
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy main scripts
echo "  Copying scripts..."
cp "$SCRIPT_DIR/ralph.sh" "$TARGET_DIR/"
cp "$SCRIPT_DIR/status.sh" "$TARGET_DIR/"
cp "$SCRIPT_DIR/stop.sh" "$TARGET_DIR/"
cp "$SCRIPT_DIR/watch.sh" "$TARGET_DIR/"
cp "$SCRIPT_DIR/ralph-pretty-print.sh" "$TARGET_DIR/"
cp "$SCRIPT_DIR/prompt.md" "$TARGET_DIR/"

# Copy runners directory
echo "  Copying runners..."
mkdir -p "$TARGET_DIR/runners"
cp "$SCRIPT_DIR/runners/"*.sh "$TARGET_DIR/runners/"

# Create sessions directory
echo "  Creating sessions directory..."
mkdir -p "$TARGET_DIR/sessions"

# Make all scripts executable
echo "  Setting permissions..."
chmod +x "$TARGET_DIR/"*.sh
chmod +x "$TARGET_DIR/runners/"*.sh

# ============================================================================
# Auto-detect and install to .claude/ and .cursor/
# ============================================================================
INSTALL_ROOT="$(dirname "$TARGET_DIR")"
if [[ "$TARGET_DIR" == "$(pwd)/.ralph" ]]; then
  INSTALL_ROOT="$(pwd)"
fi

# Install to .claude/commands/ if .claude/ exists
if [[ -d "$INSTALL_ROOT/.claude" ]]; then
  echo "  Detected .claude/ - installing commands..."
  mkdir -p "$INSTALL_ROOT/.claude/commands"
  if [[ -d "$SCRIPT_DIR/commands" ]]; then
    cp "$SCRIPT_DIR/commands/"*.md "$INSTALL_ROOT/.claude/commands/" 2>/dev/null || true
  fi
fi

# Install to .cursor/commands/ if .cursor/ exists
if [[ -d "$INSTALL_ROOT/.cursor" ]]; then
  echo "  Detected .cursor/ - installing commands..."
  mkdir -p "$INSTALL_ROOT/.cursor/commands"
  if [[ -d "$SCRIPT_DIR/commands" ]]; then
    cp "$SCRIPT_DIR/commands/"*.md "$INSTALL_ROOT/.cursor/commands/" 2>/dev/null || true
  fi
fi

# ============================================================================
# Success message
# ============================================================================
# Get relative path for display
DISPLAY_PATH="$TARGET_DIR"
if [[ "$TARGET_DIR" == "$(pwd)/"* ]]; then
  DISPLAY_PATH="${TARGET_DIR#$(pwd)/}"
fi

echo ""
echo "============================================================================"
echo "  Ralph installed successfully to: $DISPLAY_PATH"
echo "============================================================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Create a new session:"
echo "     cd $DISPLAY_PATH && ./ralph.sh init my-feature"
echo ""
echo "  2. Edit your PRD:"
echo "     Edit $DISPLAY_PATH/sessions/my-feature/prd.json"
echo ""
echo "  3. Start Ralph:"
echo "     cd $DISPLAY_PATH && ./ralph.sh --session my-feature 10"
echo ""
echo "  4. Monitor progress:"
echo "     cd $DISPLAY_PATH && ./status.sh --session my-feature"
echo ""
echo "Documentation: https://github.com/anthropics/ralph"
echo ""
