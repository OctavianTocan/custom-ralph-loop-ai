# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-01-11

# Ralph Wiggum v1.0.0 - Autonomous AI Coding Loop

## 🎉 First Release

Ralph is an autonomous AI coding system that implements features while you sleep. Each task is completed, validated, committed, and then Ralph moves to the next task — all without human intervention.

## ✨ Features

- **Autonomous Task Execution** - Runs iteratively with fresh context windows
- **Persistent Memory** - Through git commits, progress.txt, and learnings.md
- **Validation-First** - Runs typecheck, lint, test, build after each task
- **Learning Loop** - Accumulates knowledge to prevent trial-and-error
- **Multi-Agent Support** - Works with Claude, Codex, OpenCode, Cursor

## 📦 What's Included

- Core Ralph scripts (ralph.sh, status.sh, stop.sh)
- Agent runners for multiple AI CLIs
- Comprehensive documentation
- Example PRD templates
- Command integrations for Claude Code & Cursor

## 🚀 Quick Start

```bash
# Extract archive
tar -xzf ralph-v1.0.0.tar.gz
# or: unzip ralph-v1.0.0.zip

# Install
cp -r ralph/ .ralph/
chmod +x .ralph/ralph.sh .ralph/status.sh .ralph/stop.sh .ralph/runners/*.sh

# Run
.ralph/ralph.sh 25 --session my-feature
```

## 📚 Documentation

- [Installation Guide](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/INSTALLATION.md)
- [Usage Guide](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/USAGE.md)
- [Writing PRDs](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/WRITING-PRDS.md)
- [Configuration](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/CONFIGURATION.md)
- [Troubleshooting](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/TROUBLESHOOTING.md)

## 🙏 Credits

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/)

---

**Full Changelog**: https://github.com/OctavianTocan/custom-ralph-loop-ai/commits/v1.0.0
