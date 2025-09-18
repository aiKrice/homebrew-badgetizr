#!/bin/zsh

# The script publish.sh is usefull to:
# - Generate the sha256 for Homebrew formula
# - Update the workflow with the right new version
# - Update documentation files (README.md and related docs) for the best developer experience during integration
# It will create a tag, update the formula and create a PR.

# Configuration
REPOSITORY="aiKrice/homebrew-badgetizr"
FORMULA_PATH="Formula/badgetizr.rb"
WORKFLOW_PATH=".github/workflows/badgetizr.yml"
UTILS_PATH="utils.sh"
README_PATH="README.md"
BADGES_PATH="BADGES.md"
TROUBLESHOOTING_PATH="TROUBLESHOOTING.md"
CONTRIBUTING_PATH="CONTRIBUTING.md"
PUBLISHING_PATH="PUBLISHING.md"
VERSION="$1"

red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
purple='\e[1;35m'
cyan='\e[1;36m'
white='\e[1;37m'
orange='\e[38;5;208m'
reset='\e[0m'

function fail_if_error() {
    if [ $? -ne 0 ]; then
        echo -e ""
        echo -e "${red}🔴 Error${reset}: $1"
        exit 1
    fi
}

if [ -z "$VERSION" ]; then
  echo -e "❌ Please provide a ${cyan}version${reset} (example: ./release.sh ${cyan}1.1.3${reset}). Please respect the semantic versioning notation."
  exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "❌ Please provide a ${cyan}GthubToken${reset} Exemple export GITHUB_TOKEN=...."
  exit 1
fi 

git switch develop
fail_if_error "Failed to switch develop. Please stash changes."
git pull
fail_if_error "Failed to pull develop. Please stash changes."

# Changing the version for -v option
sed -i '' "s|^BADGETIZR_VERSION=.*|BADGETIZR_VERSION=\"$VERSION\"|" "$UTILS_PATH"
sed -i '' -E \
  -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-darkgreen\\?logo=homebrew.*)@\1${VERSION}\2@" \
  -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=github.*)@\1${VERSION}\2@" \
  -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-pink\\?logo=gitlab.*)@\1${VERSION}\2@" \
  "$README_PATH"
sed -i '' "s|uses: aiKrice/homebrew-badgetizr@.*|uses: aiKrice/homebrew-badgetizr@${VERSION}|" "$WORKFLOW_PATH" "$README_PATH"
sed -i '' "s|archive/refs/tags/[0-9]\+\.[0-9]\+\.[0-9]\+\.tar\.gz|archive/refs/tags/${VERSION}.tar.gz|g" "$README_PATH"

git add "$UTILS_PATH" "$WORKFLOW_PATH" "$README_PATH" "$BADGES_PATH" "$TROUBLESHOOTING_PATH" "$CONTRIBUTING_PATH" "$PUBLISHING_PATH"
git commit -m "Bump version to $VERSION for -v option"
git push
# Step 1: Create the release
echo "🟡 [Step 1/5] Switching to master..."
git switch master
git pull
git merge develop --no-ff --no-edit --no-verify
fail_if_error "Failed to merge develop into master"
echo "🟢 [Step 1/5] Master is updated."
git push --no-verify

echo "🟡 [Step 2/5] Creating the release tag ${cyan}$VERSION${reset}..."
git tag -a "$VERSION" -m "Release $VERSION"
git push origin "$VERSION" --no-verify
gh release create $VERSION --generate-notes --verify-tag
echo "🟢 [Step 2/5] Github release created"

# Step 2: Download the archive and calculate SHA256 for Homebrew
ARCHIVE_URL="https://github.com/$REPOSITORY/archive/refs/tags/$VERSION.tar.gz"
echo "🟡 [Step 3/5] Downloading the archive $ARCHIVE_URL..."

curl -L -o "badgetizr-$VERSION.tar.gz" "$ARCHIVE_URL" > /dev/null
fail_if_error "Failed to download the archive"
echo "🟢 [Step 3/5] Archive downloaded."
SHA256=$(shasum -a 256 "badgetizr-$VERSION.tar.gz" | awk '{print $1}')
echo -e "🟢 SHA256 generated: ${cyan}$SHA256${reset}"

# Step 3: Update the formula
sed -i "" -E \
  -e "s#(url \").*(\".*)#\1$ARCHIVE_URL\2#" \
  -e "s#(sha256 \").*(\".*)#\1$SHA256\2#" \
  "$FORMULA_PATH"

# Step 4: Commit and push
echo "🟡 [Step 4/5] Commiting the bump of the files..."
git add "$FORMULA_PATH"
git commit -m "Bump version $VERSION"
fail_if_error "Failed to commit the bump"
git push --no-verify
fail_if_error "Failed to push the bump"
echo "🟢 [Step 4/5] Bump pushed."

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
