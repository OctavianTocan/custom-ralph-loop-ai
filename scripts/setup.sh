#!/bin/bash
# Ralph Zero-Setup Bootstrap Script
# Usage: ./scripts/setup.sh
# 
# This script makes Ralph ready to run with zero configuration.
# No prompts, no manual config - just clone and go.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
G='\033[0;32m'
C='\033[0;36m'
Y='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${C}========================================================================${NC}"
echo -e "              ${BOLD}Ralph Zero-Setup Bootstrap${NC}"
echo -e "${C}========================================================================${NC}"
echo ""

cd "$REPO_ROOT"

# ============================================================================
# 1. Make all scripts executable
# ============================================================================
echo -e "${BOLD}[1/4] Setting permissions...${NC}"
chmod +x ralph.sh status.sh stop.sh watch.sh ralph-pretty-print.sh demo.sh install.sh install-cursor-hooks.sh 2>/dev/null || true
chmod +x runners/*.sh 2>/dev/null || true
chmod +x plugins/*.plugin.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
echo -e "  ${G}✓${NC} All scripts are executable"
echo ""

# ============================================================================
# 2. Create default session structure (if not exists)
# ============================================================================
echo -e "${BOLD}[2/4] Setting up session structure...${NC}"
mkdir -p sessions
touch sessions/.gitkeep

# Create a default demo session if no sessions exist
# Count directories excluding hidden directories and sessions root itself
SESSION_COUNT=$(find sessions -mindepth 1 -maxdepth 1 -type d ! -name ".*" 2>/dev/null | wc -l)
if [[ $SESSION_COUNT -eq 0 ]]; then
  echo -e "  ${Y}Creating default demo session...${NC}"
  if ./ralph.sh init quickstart >/dev/null 2>&1; then
    if [[ -f sessions/quickstart/prd.json ]]; then
      echo -e "  ${G}✓${NC} Created sessions/quickstart with example PRD"
    fi
  else
    echo -e "  ${Y}⚠${NC} Could not create demo session (might be OK)"
  fi
else
  echo -e "  ${G}✓${NC} Sessions directory ready ($SESSION_COUNT existing)"
fi
echo ""

# ============================================================================
# 3. Verify core components
# ============================================================================
echo -e "${BOLD}[3/4] Verifying installation...${NC}"

# Check ralph.sh works (capture both stdout and stderr for version output)
if VERSION=$(./ralph.sh --version 2>&1) && [[ -n "$VERSION" ]]; then
  echo -e "  ${G}✓${NC} ralph.sh: $VERSION"
else
  echo -e "  ${Y}⚠${NC} ralph.sh version check failed (might be OK)"
fi

# Check runners
RUNNER_COUNT=$(find runners -name "*.sh" 2>/dev/null | wc -l)
echo -e "  ${G}✓${NC} runners: $RUNNER_COUNT agent runners available"

# Check plugins
PLUGIN_COUNT=$(find plugins -name "*.plugin.sh" 2>/dev/null | wc -l)
echo -e "  ${G}✓${NC} plugins: $PLUGIN_COUNT agent plugins available"

# Check examples
if [[ -f "examples/prd.json.example" ]]; then
  echo -e "  ${G}✓${NC} examples: PRD templates available"
fi

echo ""

# ============================================================================
# 4. Ready to use
# ============================================================================
echo -e "${BOLD}[4/4] Bootstrap complete!${NC}"
echo ""
echo -e "${C}========================================================================${NC}"
echo -e "  ${G}${BOLD}Ralph is ready to use!${NC}"
echo -e "${C}========================================================================${NC}"
echo ""
echo -e "${BOLD}Quick Start:${NC}"
echo ""
echo -e "  1. Create a session:"
echo -e "     ${C}./ralph.sh init my-feature${NC}"
echo ""
echo -e "  2. Edit the PRD (optional):"
echo -e "     ${C}vim sessions/my-feature/prd.json${NC}"
echo ""
echo -e "  3. Run Ralph:"
echo -e "     ${C}./ralph.sh 10 --session my-feature${NC}"
echo ""
echo -e "  4. Check status:"
echo -e "     ${C}./status.sh${NC}"
echo ""
echo -e "${BOLD}Or try the demo session:${NC}"
echo -e "  ${C}./ralph.sh 5 --session quickstart${NC}"
echo ""
echo -e "${BOLD}Documentation:${NC}"
echo -e "  README.md, docs/USAGE.md, docs/INSTALLATION.md"
echo ""
