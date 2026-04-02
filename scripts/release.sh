#!/usr/bin/env bash
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 0.2.5
#
# Bumps MARKETING_VERSION in the Xcode project, commits, and tags.

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    echo "Usage: $0 <version>  (e.g. 0.2.5)"
    exit 1
fi

PBXPROJ="Manifest.xcodeproj/project.pbxproj"

if [[ ! -f "$PBXPROJ" ]]; then
    echo "Error: $PBXPROJ not found. Run this script from the repo root."
    exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: uncommitted changes present. Commit or stash them first."
    exit 1
fi

# Bump version in project file
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = ${VERSION};/g" "$PBXPROJ"

echo "→ Bumped MARKETING_VERSION to ${VERSION}"

git add "$PBXPROJ"
git commit -m "chore: bump version to ${VERSION}"
git tag "v${VERSION}" -m "Version ${VERSION}"

echo "→ Committed and tagged v${VERSION}"
echo ""
echo "To push: git push origin main && git push origin v${VERSION}"
