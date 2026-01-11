#!/bin/bash
# Install Ralph hooks for Cursor integration
# This script sets up Cursor's hooks system to work with Ralph

set -e

# Colors
C='\033[0;36m'
G='\033[0;32m'
Y='\033[1;33m'
R='\033[0;31m'
N='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${C}╔════════════════════════════════════════════════════════════════════════╗${N}"
echo -e "${C}║${N}              ${BOLD}Ralph - Cursor Hooks Installation${N}              ${C}║${N}"
echo -e "${C}╚════════════════════════════════════════════════════════════════════════╝${N}"
echo ""

# Check if cursor-config exists
if [[ ! -d "$SCRIPT_DIR/cursor-config" ]]; then
  echo -e "${R}Error:${N} cursor-config/ directory not found!"
  echo "Make sure you're running this from the Ralph directory."
  exit 1
fi

# Check if .cursor directory exists, create if not
CURSOR_DIR="$SCRIPT_DIR/.cursor"
if [[ ! -d "$CURSOR_DIR" ]]; then
  echo -e "${Y}Creating${N} .cursor/ directory..."
  mkdir -p "$CURSOR_DIR"
fi

# Check if hooks.json already exists
if [[ -f "$CURSOR_DIR/hooks.json" ]]; then
  echo -e "${Y}Warning:${N} .cursor/hooks.json already exists."
  read -p "Overwrite? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping hooks.json..."
  else
    cp "$SCRIPT_DIR/cursor-config/hooks.json" "$CURSOR_DIR/hooks.json"
    echo -e "${G}✓${N} Updated hooks.json"
  fi
else
  cp "$SCRIPT_DIR/cursor-config/hooks.json" "$CURSOR_DIR/hooks.json"
  echo -e "${G}✓${N} Installed hooks.json"
fi

# Create hooks directory
HOOKS_DIR="$CURSOR_DIR/hooks"
if [[ ! -d "$HOOKS_DIR" ]]; then
  mkdir -p "$HOOKS_DIR"
  echo -e "${G}✓${N} Created .cursor/hooks/ directory"
fi

# Copy hook scripts
echo ""
echo "Installing hook scripts..."

for hook in validate-command.sh log-command.sh track-edit.sh on-stop.sh; do
  if [[ -f "$SCRIPT_DIR/cursor-config/hooks/$hook" ]]; then
    cp "$SCRIPT_DIR/cursor-config/hooks/$hook" "$HOOKS_DIR/$hook"
    chmod +x "$HOOKS_DIR/$hook"
    echo -e "  ${G}✓${N} $hook"
  else
    echo -e "  ${Y}!${N} $hook not found in cursor-config/hooks/"
  fi
done

echo ""
echo -e "${C}╔════════════════════════════════════════════════════════════════════════╗${N}"
echo -e "${C}║${N}                    ${BOLD}Installation Complete${N}                    ${C}║${N}"
echo -e "${C}╚════════════════════════════════════════════════════════════════════════╝${N}"
echo ""
echo "Cursor hooks installed to:"
echo "  .cursor/hooks.json"
echo "  .cursor/hooks/*.sh"
echo ""
echo "The hooks will:"
echo "  • Log commands and file edits to Ralph session logs"
echo "  • Support auto-continue for Ralph loop iterations"
echo "  • (Optional) Validate dangerous commands before execution"
echo ""
echo -e "${Y}Note:${N} To enable command blocking, edit .cursor/hooks/validate-command.sh"
echo "      and uncomment the safety patterns you want to enforce."
echo ""
