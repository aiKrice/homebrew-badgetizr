#!/bin/zsh

# The script publish.sh is useful to:
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
GITLAB_TESTING_PATH="GITLAB-TESTING.md"
BITRISE_STEP_YML="step.yml"
BITRISE_STEP_SH="step.sh"
BITRISE_DOC="BITRISE.md"
VERSION="$1"

red='\e[1;31m'
cyan='\e[1;36m'
reset='\e[0m'

function fail_if_error() {
    if [[ $? -ne 0 ]]; then
        echo -e ""
        echo -e "${red}🔴 Error${reset}: $1"
        exit 1
    fi
}

if [[ -z "${VERSION}" ]]; then
    echo -e "❌ Please provide a ${cyan}version${reset} (example: ./release.sh ${cyan}1.1.3${reset}). Please respect the semantic versioning notation."
    exit 1
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo -e "❌ Please provide a ${cyan}GitHub Token${reset} Example: export GITHUB_TOKEN=...."
    exit 1
fi

git switch develop
fail_if_error "Failed to switch develop. Please stash changes."
git pull
fail_if_error "Failed to pull develop. Please stash changes."

echo "🟡 [Step 1/6] Bumping version to ${cyan}${VERSION}${reset} in all files..."
# Changing the version for -v option
sed -i '' "s|^BADGETIZR_VERSION=.*|BADGETIZR_VERSION=\"${VERSION}\"|" "${UTILS_PATH}"
sed -i '' -E \
    -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-darkgreen\\?logo=homebrew.*)@\1${VERSION}\2@" \
    -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=github.*)@\1${VERSION}\2@" \
    -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-pink\\?logo=gitlab.*)@\1${VERSION}\2@" \
    -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-purple\\?logo=bitrise.*)@\1${VERSION}\2@" \
    "${README_PATH}"
sed -i '' "s|uses: aiKrice/homebrew-badgetizr@.*|uses: aiKrice/homebrew-badgetizr@${VERSION}|" "${WORKFLOW_PATH}" "${README_PATH}"
sed -i '' "s|archive/refs/tags/[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.tar\.gz|archive/refs/tags/${VERSION}.tar.gz|g" "${README_PATH}" "${GITLAB_TESTING_PATH}"
sed -i '' "s|BADGETIZR_VERSION: \"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|BADGETIZR_VERSION: \"${VERSION}\"|g" "${README_PATH}" "${GITLAB_TESTING_PATH}"

# Update Bitrise step files
sed -i '' "s|default_value: \"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|default_value: \"${VERSION}\"|" "${BITRISE_STEP_YML}"
sed -i '' "s|badgetizr_version:-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*}|badgetizr_version:-${VERSION}}|" "${BITRISE_STEP_SH}"
sed -i '' "s|@[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|@${VERSION}|g" "${BITRISE_DOC}" "${README_PATH}"
sed -i '' "s/| No | [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* |/| No | ${VERSION} |/" "${BITRISE_DOC}"

git add "${UTILS_PATH}" "${WORKFLOW_PATH}" "${README_PATH}" "${BADGES_PATH}" "${TROUBLESHOOTING_PATH}" "${CONTRIBUTING_PATH}" "${PUBLISHING_PATH}" "${GITLAB_TESTING_PATH}" "${BITRISE_STEP_YML}" "${BITRISE_STEP_SH}" "${BITRISE_DOC}"
git commit --no-verify -m "Bump version to ${VERSION} for -v option"
git push
echo "🟢 [Step 1/6] Version bumped and pushed to develop."

echo "🟡 [Step 2/6] Switching to master..."
git switch master
git pull
git merge develop --no-ff --no-edit --no-verify
fail_if_error "Failed to merge develop into master"
echo "🟢 [Step 2/6] Master is updated."
git push --no-verify

echo "🟡 [Step 3/6] Creating the release tag ${cyan}${VERSION}${reset}..."
git tag -a "${VERSION}" -m "Release ${VERSION}"
git push origin "${VERSION}" --no-verify
fail_if_error "Failed to push tag ${VERSION}"
echo "🟢 [Step 3/6] Tag pushed, creating GitHub release..."
gh release create "${VERSION}" --title "${VERSION}" --generate-notes --verify-tag --latest
fail_if_error "Failed to create GitHub release"
echo "🟢 [Step 3/6] GitHub release created successfully"
echo "📦 GitHub Marketplace: Release will appear automatically (action.yml detected)"

# Download the archive and calculate SHA256 for Homebrew
ARCHIVE_URL="https://github.com/${REPOSITORY}/archive/refs/tags/${VERSION}.tar.gz"
echo "🟡 [Step 4/6] Downloading the archive ${ARCHIVE_URL}..."

curl -L -o "badgetizr-${VERSION}.tar.gz" "${ARCHIVE_URL}" > /dev/null
fail_if_error "Failed to download the archive"
echo "🟢 [Step 4/6] Archive downloaded."
SHA256=$(shasum -a 256 "badgetizr-${VERSION}.tar.gz" | awk '{print $1}')
echo -e "🟢 SHA256 generated: ${cyan}${SHA256}${reset}"

# Update the formula
sed -i "" -E \
    -e "s#(url \").*(\".*)#\1${ARCHIVE_URL}\2#" \
    -e "s#(sha256 \").*(\".*)#\1${SHA256}\2#" \
    "${FORMULA_PATH}"

# Commit and push
echo "🟡 [Step 5/6] Committing the bump of the files..."
git add "${FORMULA_PATH}"
git commit --no-verify -m "Bump version ${VERSION}"
fail_if_error "Failed to commit the bump"
git push --no-verify
fail_if_error "Failed to push the bump"
echo "🟢 [Step 5/6] Bump pushed."

# Backmerge to develop
echo "🟡 [Step 6/6] Switching to develop..."
git switch develop
fail_if_error "Failed to switch to develop. Please check if you have to stash some changes."
git pull
fail_if_error "Failed to pull develop"
git merge master --no-ff --no-edit --no-verify
fail_if_error "Failed to backmerge to develop"
git push --no-verify
echo "🟢 [Step 6/6] Develop is updated."

rm "badgetizr-${VERSION}.tar.gz"
echo "🚀 Done"
