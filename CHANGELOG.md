# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-01-11

### Added
- Initial release of the Ralph autonomous AI coding system.
- Autonomous task execution loop that iteratively implements features with fresh context windows.
- Persistent progress tracking via git commits, `progress.txt`, and `learnings.md`.
- Validation pipeline that runs typecheck, lint, test, and build after each task.
- Learning loop to accumulate knowledge and reduce trial-and-error across tasks.
- Multi-agent support for multiple AI CLIs (e.g. Claude, Codex, OpenCode, Cursor).
- Core Ralph scripts: `ralph.sh`, `status.sh`, `stop.sh`.
- Agent runners for multiple AI command-line interfaces.
- Example PRD templates and command integrations for supported editors.

### Documentation
- [Installation Guide](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/INSTALLATION.md)
- [Usage Guide](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/USAGE.md)
- [Writing PRDs](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/WRITING-PRDS.md)
- [Configuration](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/CONFIGURATION.md)
- [Troubleshooting](https://github.com/OctavianTocan/custom-ralph-loop-ai/blob/master/docs/TROUBLESHOOTING.md)

### Credits
- Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

**Full changelog**: https://github.com/OctavianTocan/custom-ralph-loop-ai/commits/v1.0.0
