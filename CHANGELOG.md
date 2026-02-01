# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **npm Package Support**: Ralph is now available as an npm package `@ralphie/ralph-ai-coding-loop`
  - Global installation: `npm install -g @ralphie/ralph-ai-coding-loop`
  - Local installation: `npm install --save-dev @ralphie/ralph-ai-coding-loop`
  - Bin commands: `ralph`, `ralph-status`, `ralph-stop`, `ralph-watch`
- **Package Configuration**: Added `package.json` with complete npm metadata
  - Scoped package name under `@ralphie` namespace
  - MIT license with LICENSE file
  - Node.js 14+ requirement
- **npm Publishing Controls**: Added `.npmignore` to exclude development files from npm package
- **Enhanced Documentation**: Updated README.md, INSTALLATION.md, and RELEASING.md with npm installation and publishing instructions

### Changed
- `.gitignore`: Added Node.js and npm-related exclusions (node_modules, package-lock.json, etc.)
- Installation instructions now prioritize npm installation as the recommended method

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
