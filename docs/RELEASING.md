# Release Process

## Overview

Ralph uses GitHub Actions for automated releases with AI-generated release notes powered by Cursor CLI.

## Setup

### 1. Add Cursor API Key to GitHub Secrets

1. Get your API key from [Cursor Dashboard](https://cursor.com/dashboard?tab=background-agents)
2. Go to your repo: `Settings` → `Secrets and variables` → `Actions`
3. Click `New repository secret`
4. Name: `CURSOR_API_KEY`
5. Value: Your Cursor API key
6. Click `Add secret`

## Creating a Release

When you push a tag matching `v*.*.*`, GitHub Actions automatically:

1. <cite index="12-5">Installs Cursor CLI</cite>
2. Analyzes changes since last tag
3. <cite index="12-5">Uses `cursor-agent -p` for AI-generated release notes</cite>
4. Creates `.tar.gz` and `.zip` packages
5. Publishes GitHub release

### Steps to Release

```bash
# 1. Commit your changes
git add .
git commit -m "feat: add new feature"
git push

# 2. Create and push a tag
git tag v1.0.1
git push origin v1.0.1

# 3. Watch the automation
# Visit: https://github.com/OctavianTocan/custom-ralph-loop-ai/actions
```

The workflow will automatically generate release notes using Cursor AI, analyzing your commits and changes to create user-focused documentation.

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

## AI-Generated Release Notes

The workflow <cite index="12-5">uses Cursor CLI in print mode (`-p`) with `--output-format text`</cite> to generate release notes that include:

- **Brief Summary** - What this release brings
- **Categorized Changes** - Features, fixes, documentation, improvements
- **User Impact Focus** - Benefits over implementation details
- **Emoji Tags** - Visual categorization (✨ Features, 🐛 Fixes, etc.)

If Cursor CLI fails, it falls back to a simple changelog format.

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

### Cursor API Key Not Set
The workflow will fall back to basic changelog format if `CURSOR_API_KEY` secret is not configured.

### CI Release Failed
Check the Actions tab on GitHub for error logs. Common issues:
- Tag format doesn't match `v*.*.*`
- Insufficient permissions
- Network issues

## Example Workflow

```bash
# 1. Make changes
git add .
git commit -m "feat(core): add new validation command"
git push

# 2. Tag and trigger release
git tag v1.1.0
git push origin v1.1.0

# 3. GitHub Actions automatically:
# - Installs Cursor CLI
# - Analyzes your changes with AI
# - Generates categorized release notes:
#   ✨ Features
#   - Add new validation command
#   
#   📚 Documentation  
#   - Update validation guide
# - Creates release packages
# - Publishes to GitHub Releases
```

## Best Practices

1. **Write good commit messages** - They become your AI-generated changelog
2. **Use conventional commits** - Helps AI categorize changes better
3. **Tag only from main/master** - Don't tag feature branches
4. **Review before tagging** - Once tagged, release is automatic

## Release Checklist

Before creating a release:
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Version number follows semver
- [ ] Changes are committed and pushed to main/master
- [ ] `CURSOR_API_KEY` secret is configured (for AI release notes)

## Co-Authorship

Releases automatically include:
```
Co-Authored-By: Warp <agent@warp.dev>
```

This gives credit to AI assistance in the release process.

## How It Works

The GitHub Actions workflow (`.github/workflows/release.yml`):

1. **Triggers** on tags matching `v*.*.*`
2. <cite index="12-5">**Installs Cursor CLI** via `curl https://cursor.com/install -fsS | bash`</cite>
3. **Analyzes changes** - Compares current tag with previous tag
4. <cite index="12-5">**Generates AI notes** - Uses `cursor-agent -p --output-format text`</cite> with commit messages and diff stats
5. **Creates packages** - Both `.tar.gz` and `.zip` formats
6. **Publishes release** - To GitHub Releases with generated notes
