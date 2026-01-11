# Release Process

## Overview

Ralph supports two release workflows:
1. **Local Script** - Manual releases with AI-generated notes (recommended for personal projects)
2. **GitHub Actions** - Automated CI releases (recommended for team projects)

## Local Script Release

### Prerequisites

- `gh` CLI installed and authenticated
- `tar` and `zip` utilities
- (Optional) `cursor-agent` CLI with `CURSOR_API_KEY` for AI-generated release notes

### Setup Cursor CLI (Optional)

For AI-generated release notes:

```bash
# Install Cursor CLI
curl https://cursor.com/install -fsSL | bash

# Get API key from https://cursor.com/dashboard?tab=background-agents
export CURSOR_API_KEY="your_key_here"

# Add to your shell profile for persistence
echo 'export CURSOR_API_KEY="your_key_here"' >> ~/.bashrc
```

### Create a Release

```bash
# Interactive - prompts for version
./release.sh

# Or specify version
./release.sh 1.0.1
```

The script will:
1. Validate version format (X.Y.Z)
2. Check for uncommitted changes
3. Generate diff summary
4. Use Cursor AI to generate release notes (if available)
5. Create `.tar.gz` and `.zip` packages
6. Show preview and ask for confirmation
7. Create git tag and push
8. Create GitHub release with packages

### AI-Generated Release Notes

<cite index="2-3,2-6">When `cursor-agent` is available, the script uses print mode (`-p`) for non-interactive scripting</cite> to analyze your changes and generate user-focused release notes with:

- Brief summary of the release
- Changes organized by category (Features, Fixes, Documentation, etc.)
- Focus on user impact vs implementation details

Without Cursor CLI, it falls back to a simple changelog format.

## GitHub Actions Release

### How It Works

The GitHub Actions workflow (`.github/workflows/release.yml`) triggers automatically when you push a tag matching `v*.*.*`.

### Create a Release with CI

```bash
# Commit your changes
git add .
git commit -m "feat: add new feature"
git push

# Create and push a tag
git tag v1.0.1
git push origin v1.0.1
```

The workflow will:
1. Checkout code with full history
2. Calculate changes since last tag
3. Generate changelog from commits
4. Create release packages
5. Create GitHub release automatically

### Monitoring CI Releases

View progress at:
```
https://github.com/OctavianTocan/custom-ralph-loop-ai/actions
```

## Version Numbering

Ralph follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.x.x) - Breaking changes
- **MINOR** (x.1.x) - New features, backward compatible
- **PATCH** (x.x.1) - Bug fixes, backward compatible

Examples:
- `1.0.0` - Initial release
- `1.0.1` - Bug fix
- `1.1.0` - New feature
- `2.0.0` - Breaking change

## Which Method Should I Use?

### Use Local Script When:
- ✅ Personal projects
- ✅ You want AI-generated release notes
- ✅ You want to preview before publishing
- ✅ You want more control over the process

### Use GitHub Actions When:
- ✅ Team projects with multiple contributors
- ✅ You want fully automated releases
- ✅ You want consistent release processes
- ✅ You prefer CI/CD automation

### Use Both:
You can use both methods! The local script is great for testing, while CI ensures consistency for production releases.

## Troubleshooting

### "Tag already exists"
```bash
# Delete local tag
git tag -d v1.0.1

# Delete remote tag
git push origin :refs/tags/v1.0.1

# Try again
./release.sh 1.0.1
```

### "gh CLI not found"
```bash
# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Authenticate
gh auth login
```

### "cursor-agent not found"
This is optional. The script works without it, just with basic release notes instead of AI-generated ones.

### CI Release Failed
Check the Actions tab on GitHub for error logs. Common issues:
- Tag format doesn't match `v*.*.*`
- Insufficient permissions
- Network issues

## Examples

### Local Release with AI Notes
```bash
# Set up Cursor (one time)
export CURSOR_API_KEY="sk_..."

# Create release
./release.sh 1.0.1

# Script shows AI-generated preview:
# ✨ Features
# - Add automated release script with AI-generated notes
# 
# 📚 Documentation
# - Add comprehensive release guide
```

### CI Release
```bash
# Make changes
git add .
git commit -m "feat(core): add new validation command"
git push

# Tag and trigger release
git tag v1.1.0
git push origin v1.1.0

# GitHub Actions creates the release automatically
```

## Best Practices

1. **Test locally first** - Use the local script to validate packages before CI
2. **Write good commit messages** - They become your changelog
3. **Use conventional commits** - Makes release notes more organized
4. **Tag only from main/master** - Don't tag feature branches
5. **Review before tagging** - Once tagged, it's released (in CI mode)

## Release Checklist

Before creating a release:
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] CHANGES.md is updated (if applicable)
- [ ] Version number follows semver
- [ ] Changes are committed and pushed
- [ ] You're on the main/master branch

## Co-Authorship

Both release methods automatically include:
```
Co-Authored-By: Warp <agent@warp.dev>
```

This gives credit to AI assistance in the release process.
