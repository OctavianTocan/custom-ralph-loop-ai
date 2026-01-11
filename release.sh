#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="custom-ralph-loop-ai"
PACKAGE_NAME="ralph"

echo -e "${GREEN}🚀 Ralph Release Automation${NC}\n"

# Check for required tools
command -v gh >/dev/null 2>&1 || { echo -e "${RED}Error: gh CLI not found${NC}"; exit 1; }
command -v tar >/dev/null 2>&1 || { echo -e "${RED}Error: tar not found${NC}"; exit 1; }
command -v zip >/dev/null 2>&1 || { echo -e "${RED}Error: zip not found${NC}"; exit 1; }

# Get version from user or argument
if [ $# -eq 0 ]; then
    read -p "Enter version (e.g., 1.0.1): " VERSION
else
    VERSION="$1"
fi

# Validate version format
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Version must be in format X.Y.Z${NC}"
    exit 1
fi

TAG="v${VERSION}"

echo -e "${YELLOW}📋 Creating release ${TAG}...${NC}\n"

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${RED}Error: Tag ${TAG} already exists${NC}"
    exit 1
fi

# Get the last tag for comparison
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LAST_TAG" ]; then
    COMMIT_RANGE="HEAD"
    echo -e "${YELLOW}No previous tags found. Using all commits.${NC}"
else
    COMMIT_RANGE="${LAST_TAG}..HEAD"
    echo -e "${YELLOW}Comparing ${LAST_TAG}..HEAD${NC}\n"
fi

# Generate diff summary
echo -e "${BLUE}📊 Analyzing changes...${NC}"
DIFF_STATS=$(git diff --stat "$COMMIT_RANGE" 2>/dev/null || git diff --stat HEAD)
COMMIT_LOG=$(git log --pretty=format:"- %s" "$COMMIT_RANGE" 2>/dev/null || git log --pretty=format:"- %s" HEAD~5..HEAD)
DETAILED_DIFF=$(git diff --cached "$COMMIT_RANGE" 2>/dev/null || git diff HEAD~5..HEAD || echo "No diff available")

# Use Cursor AI to generate release notes
if command -v cursor-agent >/dev/null 2>&1 && [ -n "${CURSOR_API_KEY:-}" ]; then
    echo -e "${BLUE}🤖 Generating AI release notes with Cursor...${NC}"
    
    # Create temporary file with diff context
    CONTEXT_FILE=$(mktemp)
    cat > "$CONTEXT_FILE" << EOF
You are generating release notes for version ${VERSION} of Ralph - an autonomous AI coding loop system.

Previous version: ${LAST_TAG:-None (first release)}

COMMIT MESSAGES:
${COMMIT_LOG}

FILE STATISTICS:
${DIFF_STATS}

Generate concise, user-focused release notes in markdown format with:

1. A brief summary paragraph (2-3 sentences) explaining what this release brings
2. Key changes organized by category (use emojis):
   - ✨ Features (new capabilities)
   - 🐛 Fixes (bug fixes)
   - 📚 Documentation (doc improvements)
   - 🔧 Improvements (enhancements, refactors)
   - ⚠️  Breaking Changes (if any)

3. Keep it concise - users want to quickly understand what changed
4. Focus on user impact, not implementation details
5. Use bullet points within each category

DO NOT include a title or version number (it will be added separately).
DO NOT include generic fluff like "We're excited to announce..."
EOF

    # Run cursor-agent in headless mode
    AI_NOTES=$(cursor-agent -p --output-format text "$(cat "$CONTEXT_FILE")" 2>/dev/null || echo "")
    rm "$CONTEXT_FILE"
    
    if [ -n "$AI_NOTES" ]; then
        echo -e "${GREEN}✓ AI release notes generated${NC}\n"
        RELEASE_NOTES="$AI_NOTES"
    else
        echo -e "${YELLOW}⚠️  AI generation failed, using manual format${NC}\n"
        RELEASE_NOTES="## Changes

${COMMIT_LOG}

## Statistics

\`\`\`
${DIFF_STATS}
\`\`\`"
    fi
else
    if ! command -v cursor-agent >/dev/null 2>&1; then
        echo -e "${YELLOW}ℹ️  cursor-agent CLI not found, using basic format${NC}"
        echo -e "${YELLOW}    Install: curl https://cursor.com/install -fsSL | bash${NC}\n"
    elif [ -z "${CURSOR_API_KEY:-}" ]; then
        echo -e "${YELLOW}ℹ️  CURSOR_API_KEY not set, using basic format${NC}"
        echo -e "${YELLOW}    Get key from: https://cursor.com/dashboard?tab=background-agents${NC}\n"
    fi
    
    RELEASE_NOTES="## Changes

${COMMIT_LOG}

## Statistics

\`\`\`
${DIFF_STATS}
\`\`\`"
fi

# Add footer to release notes
if [ -n "$LAST_TAG" ]; then
    CHANGELOG_LINK="https://github.com/OctavianTocan/${REPO_NAME}/compare/${LAST_TAG}...${TAG}"
else
    CHANGELOG_LINK="https://github.com/OctavianTocan/${REPO_NAME}/commits/${TAG}"
fi

RELEASE_NOTES="${RELEASE_NOTES}

---

**Full Changelog**: ${CHANGELOG_LINK}

Co-Authored-By: Warp <agent@warp.dev>"

# Create packages
echo -e "${BLUE}📦 Creating release packages...${NC}"

# Create tarball
TAR_FILE="${PACKAGE_NAME}-v${VERSION}.tar.gz"
tar -czf "/tmp/${TAR_FILE}" \
    --exclude='.git' \
    --exclude='.ralph/sessions' \
    --exclude='node_modules' \
    --exclude='*.log' \
    --exclude='*.tar.gz' \
    --exclude='*.zip' \
    -C "$(pwd)" .
mv "/tmp/${TAR_FILE}" .
echo -e "${GREEN}✓ Created ${TAR_FILE}${NC}"

# Create zip
ZIP_FILE="${PACKAGE_NAME}-v${VERSION}.zip"
zip -qr "${ZIP_FILE}" . \
    -x '*.git*' \
    -x '*/.ralph/sessions/*' \
    -x '*/node_modules/*' \
    -x '*.log' \
    -x '*.tar.gz' \
    -x '*.zip'
echo -e "${GREEN}✓ Created ${ZIP_FILE}${NC}"

# Show release notes preview
echo -e "\n${YELLOW}📝 Release Notes Preview:${NC}"
echo -e "────────────────────────────────────────"
echo -e "$RELEASE_NOTES"
echo -e "────────────────────────────────────────\n"

# Confirm release
read -p "Create release ${TAG}? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Release cancelled. Cleaning up packages...${NC}"
    rm -f "${TAR_FILE}" "${ZIP_FILE}"
    exit 0
fi

# Create git tag
echo -e "\n${BLUE}🏷️  Creating git tag...${NC}"
git tag -a "$TAG" -m "Release ${TAG}"
git push origin "$TAG"
echo -e "${GREEN}✓ Tag ${TAG} pushed${NC}"

# Create GitHub release
echo -e "\n${BLUE}🚀 Creating GitHub release...${NC}"
RELEASE_URL=$(gh release create "$TAG" \
    --title "${PACKAGE_NAME} ${TAG}" \
    --notes "$RELEASE_NOTES" \
    "${TAR_FILE}" \
    "${ZIP_FILE}")

echo -e "\n${GREEN}✅ Release ${TAG} created successfully!${NC}"
echo -e "${GREEN}🔗 ${RELEASE_URL}${NC}\n"

# Cleanup
echo -e "${BLUE}🧹 Cleaning up local packages...${NC}"
rm -f "${TAR_FILE}" "${ZIP_FILE}"

echo -e "${GREEN}✨ Done!${NC}"
