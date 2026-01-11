---
name: ralph-run
description: Start or continue a Ralph autonomous coding session
argument-hint: "[--session session-name] [iterations]"
---

Run:

```bash
# If Ralph is in .ralph/:
.ralph/ralph.sh $ARGUMENTS

# Or if added to package.json:
pnpm ralph $ARGUMENTS
```

Examples:
- `.ralph/ralph.sh 25 --session my-feature`
- `.ralph/ralph.sh --session my-feature`
- `pnpm ralph 25 --session my-feature` (if using package.json script)
