#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 1 ]; then
  echo "Error: iterations must be a positive integer."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is required to run the Claude sandbox."
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "Warning: pnpm is not installed; coverage commands may fail." >&2
fi

for (( i = 1; i <= $1; i++ )); do
  prompt=$(cat << 'EOF'
@test-coverage-progress.txt
WHAT MAKES A GREAT TEST:
A great test covers behavior users depend on. It tests a feature that, if broken, would frustrate or block users.
It validates real workflows not implementation details. It catches regressions before users do.
Do NOT write tests just to increase coverage. Use coverage as a guide to find UNTESTED USER-FACING BEHAVIOR.
If uncovered code is not worth testing (boilerplate, unreachable error branches, internal plumbing),
add /* v8 ignore next */ or /* v8 ignore start */ comments instead of writing low-value tests.

PROCESS:
1. Run pnpm coverage to see which files have low coverage.
2. Read the uncovered lines and identify the most important USER-FACING FEATURE that lacks tests.
Prioritize: error handling users will hit, CLI commands, git operations, file parsing.
Deprioritize: internal utilities, edge cases users won't encounter, boilerplate.
3. Write ONE meaningful test that validates the feature works correctly for users.
4. Run pnpm coverage again. Coverage should increase as a side effect of testing real behavior.
5. Commit with message: test(<file>): <describe the user behavior being tested>
6. Append super-concise notes to test-coverage-progress.txt: what you tested, coverage %, any learnings.

ONLY WRITE ONE TEST PER ITERATION.
If statement coverage reaches 100%, output <promise>COMPLETE</promise>.
EOF
  )

  if ! result=$(docker sandbox run claude "$prompt"); then
    echo "Error: claude sandbox run failed on iteration $i." >&2
    exit 1
  fi

  echo "$result"
  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "100% coverage reached, exiting."
    if command -v tt >/dev/null 2>&1; then
      tt notify "AI Hero CLI: 100% coverage after $i iterations" || true
    fi
    exit 0
  fi
done
