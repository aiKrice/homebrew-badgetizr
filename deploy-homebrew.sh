#!/bin/bash

# The script deploy-homebrew.sh is used to release the tool to the homebrew repository.
# It will create a tag, update the formula and create a PR.

# Configuration
REPOSITORY="aiKrice/homebrew-badgetizr"
FORMULA_PATH="Formula/badgetizr.rb"
VERSION="$1"

if [ -z "$VERSION" ]; then
  echo "❌ Please provide a version (example: ./release.sh 1.1.3). Please respect the semantic versioning notation."
  exit 1
fi

# Step 1: Create the release
git switch master
git pull
git merge develop --no-ff --no-edit --no-verify
echo "🟢 Develop merged into master"
git push --no-verify

echo "🟡 Creating the release tag"
git tag -a "$VERSION" -m "Release $VERSION"
git push origin "$VERSION" --no-verify
gh release create $VERSION --generate-notes --verify-tag
echo "🟢 Github release created"

# Step 2: Download the archive and calculate SHA256 for Homebrew
ARCHIVE_URL="https://github.com/$REPOSITORY/archive/refs/tags/$VERSION.tar.gz"
curl -L -o "badgetizr-$VERSION.tar.gz" "$ARCHIVE_URL"
SHA256=$(shasum -a 256 "badgetizr-$VERSION.tar.gz" | awk '{print $1}')
echo "🟢 SHA256 generated: $SHA256"

# Step 3: Update the formula
sed -i "" -E \
  -e "s#(url \").*(\".*)#\1$ARCHIVE_URL\2#" \
  -e "s#(sha256 \").*(\".*)#\1$SHA256\2#" \
  "$FORMULA_PATH"

# Step 4: Commit and push
git add "$FORMULA_PATH"
git commit -m "Update formula for version $VERSION"
git push --no-verify

# Step 5: Backmerge to develop
git switch develop
git pull
git merge master --no-ff --no-edit --no-verify
git push --no-verify
echo "🟢 Backmerged to develop"

echo "🚀 Done"
