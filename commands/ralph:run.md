---
name: ralph-run
description: Start or continue a Ralph autonomous coding session
argument-hint: "[session-name] [iterations]"
---

Run:

```bash
# If Ralph is in .ralph/:
.ralph/ralph.sh $ARGUMENTS

# Or if added to package.json:
pnpm ralph $ARGUMENTS
```

Examples:
- `.ralph/ralph.sh 25 --session extension-react19-tooling`
- `.ralph/ralph.sh --session extension-react19-tooling`
- `pnpm ralph 25 --session extension-react19-tooling` (if using package.json script)
