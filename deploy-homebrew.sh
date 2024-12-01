#!/bin/bash

# The script deploy-homebrew.sh is used to release the tool to the homebrew repository.
# It will create a tag, update the formula and create a PR.

# Configuration
REPOSITORY="aiKrice/homebrew-badgetizr"
FORMULA_PATH="Formula/badgetizr.rb"
VERSION="$1"

red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
purple='\033[1;35m'
cyan='\033[1;36m'
white='\033[1;37m'
orange='\033[38;5;208m'
reset='\033[0m'

function fail_if_error() {
    if [ $? -ne 0 ]; then
        echo -e ""
        echo -e "${red}🔴 Error${reset}: $1"
        exit 1
    fi
}

if [ -z "$VERSION" ]; then
  echo "❌ Please provide a version (example: ./release.sh 1.1.3). Please respect the semantic versioning notation."
  exit 1
fi

# Step 1: Create the release
echo "🟡 [Step 1/5] Switching to master..."
git switch master
git pull
git merge develop --no-ff --no-edit --no-verify
fail_if_error "Failed to merge develop into master"
echo "🟢 [Step 1/5] Master is updated."
git push --no-verify

echo "🟡 [Step 2/5] Creating the release tag..."
git tag -a "$VERSION" -m "Release $VERSION"
git push origin "$VERSION" --no-verify
gh release create $VERSION --generate-notes --verify-tag
echo "🟢 [Step 2/5] Github release created"

# Step 2: Download the archive and calculate SHA256 for Homebrew
echo "🟡 [Step 3/5] Downloading the archive..."
ARCHIVE_URL="https://github.com/$REPOSITORY/archive/refs/tags/$VERSION.tar.gz"
curl -L -o "badgetizr-$VERSION.tar.gz" "$ARCHIVE_URL" > /dev/null
fail_if_error "Failed to download the archive"
echo "🟢 [Step 3/5] Archive downloaded."
SHA256=$(shasum -a 256 "badgetizr-$VERSION.tar.gz" | awk '{print $1}')
echo "🟢 SHA256 generated: $SHA256"

# Step 3: Update the formula
sed -i "" -E \
  -e "s#(url \").*(\".*)#\1$ARCHIVE_URL\2#" \
  -e "s#(sha256 \").*(\".*)#\1$SHA256\2#" \
  "$FORMULA_PATH"

# Step 4: Commit and push
echo "🟡 [Step 4/5] Committing the formula..."
git add "$FORMULA_PATH"
git commit -m "Update formula for version $VERSION"
fail_if_error "Failed to commit the formula"
git push --no-verify
fail_if_error "Failed to push the formula"
echo "🟢 [Step 4/5] Formula pushed."
# Step 5: Backmerge to develop
echo "🟡 [Step 5/5] Switching to develop..."
git switch develop
fail_if_error "Failed to switch to develop. Please check if you have to stash some changes."
git pull
fail_if_error "Failed to pull develop"
git merge master --no-ff --no-edit --no-verify
fail_if_error "Failed to backmerge to develop"
git push --no-verify
echo "🟢 [Step 5/5] Develop is updated."

rm badgetizr-$VERSION.tar.gz
echo "🚀 Done"
