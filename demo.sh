#!/bin/bash
# Demo script to test all new Ralph features
# Run this to verify everything works

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
G='\033[0;32m'
C='\033[0;36m'
Y='\033[1;33m'
R='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${C}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${C}║${NC}              ${BOLD}Ralph Feature Demo${NC}                                     ${C}║${NC}"
echo -e "${C}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Track results
PASSED=0
FAILED=0

check() {
  local name="$1"
  local result="$2"
  if [[ "$result" == "0" ]]; then
    echo -e "  ${G}✓${NC} $name"
    ((PASSED++))
  else
    echo -e "  ${R}✗${NC} $name"
    ((FAILED++))
  fi
}

echo -e "${BOLD}1. Testing --version flag${NC}"
echo -e "${DIM}   Command: ./ralph.sh --version${NC}"
OUTPUT=$(./ralph.sh --version 2>&1)
echo -e "   ${DIM}Output: $OUTPUT${NC}"
[[ "$OUTPUT" == *"ralph-ai-coding-loop"* ]] && check "--version shows version" 0 || check "--version shows version" 1
echo ""

echo -e "${BOLD}2. Testing --help flag${NC}"
echo -e "${DIM}   Command: ./ralph.sh --help${NC}"
OUTPUT=$(./ralph.sh --help 2>&1)
[[ "$OUTPUT" == *"Usage:"* ]] && check "--help shows usage" 0 || check "--help shows usage" 1
[[ "$OUTPUT" == *"--iterations"* ]] && check "--help documents --iterations" 0 || check "--help documents --iterations" 1
[[ "$OUTPUT" == *"auto"* ]] && check "--help mentions 'auto'" 0 || check "--help mentions 'auto'" 1
echo ""

echo -e "${BOLD}3. Testing init command${NC}"
echo -e "${DIM}   Command: ./ralph.sh init demo-test${NC}"
rm -rf sessions/demo-test 2>/dev/null || true
OUTPUT=$(./ralph.sh init demo-test 2>&1)
[[ -d "sessions/demo-test" ]] && check "init creates session directory" 0 || check "init creates session directory" 1
[[ -f "sessions/demo-test/prd.json" ]] && check "init creates prd.json" 0 || check "init creates prd.json" 1
[[ -f "sessions/demo-test/progress.txt" ]] && check "init creates progress.txt" 0 || check "init creates progress.txt" 1
[[ -f "sessions/demo-test/learnings.md" ]] && check "init creates learnings.md" 0 || check "init creates learnings.md" 1

# Check prd.json content
PRD=$(cat sessions/demo-test/prd.json)
[[ "$PRD" == *'"branchName": "ralph/demo-test"'* ]] && check "prd.json has correct branchName" 0 || check "prd.json has correct branchName" 1
[[ "$PRD" == *'"complexity": "medium"'* ]] && check "prd.json includes complexity field" 0 || check "prd.json includes complexity field" 1

# Cleanup
rm -rf sessions/demo-test
echo ""

echo -e "${BOLD}4. Testing install.sh${NC}"
echo -e "${DIM}   Command: ./install.sh --help${NC}"
OUTPUT=$(./install.sh --help 2>&1)
[[ "$OUTPUT" == *"Usage:"* ]] && check "install.sh --help works" 0 || check "install.sh --help works" 1

echo -e "${DIM}   Command: ./install.sh /tmp/ralph-demo-install${NC}"
rm -rf /tmp/ralph-demo-install 2>/dev/null || true
./install.sh /tmp/ralph-demo-install > /dev/null 2>&1
[[ -f "/tmp/ralph-demo-install/ralph.sh" ]] && check "install.sh copies ralph.sh" 0 || check "install.sh copies ralph.sh" 1
[[ -x "/tmp/ralph-demo-install/ralph.sh" ]] && check "installed ralph.sh is executable" 0 || check "installed ralph.sh is executable" 1
[[ -d "/tmp/ralph-demo-install/runners" ]] && check "install.sh copies runners/" 0 || check "install.sh copies runners/" 1
[[ -d "/tmp/ralph-demo-install/sessions" ]] && check "install.sh creates sessions/" 0 || check "install.sh creates sessions/" 1

# Test installed version works
INSTALLED_VERSION=$(/tmp/ralph-demo-install/ralph.sh --version 2>&1)
[[ "$INSTALLED_VERSION" == *"ralph"* ]] && check "installed ralph.sh --version works" 0 || check "installed ralph.sh --version works" 1

# Cleanup
rm -rf /tmp/ralph-demo-install
echo ""

echo -e "${BOLD}5. Testing pretty-printer${NC}"
echo -e "${DIM}   Command: echo '{"type":"text","text":"Hello"}' | ./ralph-pretty-print.sh${NC}"
OUTPUT=$(echo '{"type":"content_block_delta","delta":{"type":"text_delta","text":"Hello World"}}' | ./ralph-pretty-print.sh --no-color 2>&1)
[[ "$OUTPUT" == *"Hello World"* ]] && check "pretty-printer formats text" 0 || check "pretty-printer formats text" 1

OUTPUT=$(./ralph-pretty-print.sh --help 2>&1)
[[ "$OUTPUT" == *"Usage:"* ]] && check "pretty-printer --help works" 0 || check "pretty-printer --help works" 1
echo ""

echo -e "${BOLD}6. Testing iteration suggestion (script content)${NC}"
SCRIPT=$(cat ralph.sh)
[[ "$SCRIPT" == *"ITERATION SUGGESTION"* ]] && check "ralph.sh has iteration suggestion section" 0 || check "ralph.sh has iteration suggestion section" 1
[[ "$SCRIPT" == *"SUGGESTED_SMALL"* ]] && check "ralph.sh tracks small complexity" 0 || check "ralph.sh tracks small complexity" 1
[[ "$SCRIPT" == *"SUGGESTED_MEDIUM"* ]] && check "ralph.sh tracks medium complexity" 0 || check "ralph.sh tracks medium complexity" 1
[[ "$SCRIPT" == *"SUGGESTED_LARGE"* ]] && check "ralph.sh tracks large complexity" 0 || check "ralph.sh tracks large complexity" 1
[[ "$SCRIPT" == *"ITERATIONS_AUTO"* ]] && check "ralph.sh supports --iterations auto" 0 || check "ralph.sh supports --iterations auto" 1
echo ""

echo -e "${BOLD}7. Running test suite${NC}"
echo -e "${DIM}   Command: ./tests/test-runner.sh${NC}"
TEST_OUTPUT=$(./tests/test-runner.sh 2>&1 | tail -5)
echo "$TEST_OUTPUT" | grep -q "Passed:" && check "test suite runs" 0 || check "test suite runs" 1
PASSED_COUNT=$(echo "$TEST_OUTPUT" | grep "Passed:" | grep -o '[0-9]*')
[[ "$PASSED_COUNT" -ge 160 ]] && check "160+ tests pass" 0 || check "160+ tests pass" 1
echo ""

# Summary
echo -e "${C}════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Summary:${NC}"
echo -e "  ${G}Passed: $PASSED${NC}"
if [[ $FAILED -gt 0 ]]; then
  echo -e "  ${R}Failed: $FAILED${NC}"
fi
echo -e "${C}════════════════════════════════════════════════════════════════════════${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo -e "${G}All features working!${NC}"
  exit 0
else
  echo -e "${R}Some features need attention.${NC}"
  exit 1
fi
