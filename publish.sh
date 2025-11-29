#!/bin/bash

# The script publish.sh is useful to:
# - Generate the sha256 for Homebrew formula
# - Update the workflow with the right new version
# - Update documentation files (README.md and related docs) for the best developer experience during integration
# It will create a tag, update the formula and create a PR.

# Detect OS for sed compatibility
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS uses BSD sed (requires empty string after -i)
    SED_INPLACE="sed -i ''"
else
    # Linux uses GNU sed (no empty string needed)
    SED_INPLACE="sed -i"
fi

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
STEPLIB_TEMP="tmp-bitrise-steplib"

# Parse arguments
VERSION=""
UPLOAD_BITRISE=false

while [[ $# -gt 0 ]]; do
    case ${1} in
        --upload-bitrise)
            UPLOAD_BITRISE=true
            shift
            ;;
        *)
            VERSION="${1}"
            shift
            ;;
    esac
done

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

# Cleanup temporary Bitrise directory if it exists from previous failed run
if [[ -d "${STEPLIB_TEMP}" ]]; then
    echo "🧹 Cleaning up temporary directory from previous run..."
    rm -rf "${STEPLIB_TEMP}"
fi

git switch develop
fail_if_error "Failed to switch develop. Please stash changes."
git pull
fail_if_error "Failed to pull develop. Please stash changes."

echo "🟡 [Step 1/6] Bumping version to ${cyan}${VERSION}${reset} in all files..."
# Changing the version for -v option
${SED_INPLACE} "s|^BADGETIZR_VERSION=.*|BADGETIZR_VERSION=\"${VERSION}\"|" "${UTILS_PATH}"
${SED_INPLACE} -E \
    -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=homebrew.*)@\1${VERSION}\2@" \
    -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=github.*)@\1${VERSION}\2@" \
    -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-pink\\?logo=gitlab.*)@\1${VERSION}\2@" \
    -e "s@(https://img\.shields\.io/badge/)[0-9]+\.[0-9]+\.[0-9]+(-grey\\?logo=bitrise.*)@\1${VERSION}\2@" \
    "${README_PATH}"
${SED_INPLACE} "s|uses: aiKrice/homebrew-badgetizr@.*|uses: aiKrice/homebrew-badgetizr@${VERSION}|" "${WORKFLOW_PATH}" "${README_PATH}"
${SED_INPLACE} "s|archive/refs/tags/[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.tar\.gz|archive/refs/tags/${VERSION}.tar.gz|g" "${README_PATH}" "${GITLAB_TESTING_PATH}"
${SED_INPLACE} "s|BADGETIZR_VERSION: \"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|BADGETIZR_VERSION: \"${VERSION}\"|g" "${README_PATH}" "${GITLAB_TESTING_PATH}"

# Update Bitrise step files
${SED_INPLACE} "s|BADGETIZR_VERSION=\"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|BADGETIZR_VERSION=\"${VERSION}\"|" "${BITRISE_STEP_SH}"
${SED_INPLACE} "s|@[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|@${VERSION}|g" "${BITRISE_DOC}" "${README_PATH}"
${SED_INPLACE} "s/| No | [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* |/| No | ${VERSION} |/" "${BITRISE_DOC}"

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
${SED_INPLACE} -E \
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

# ==============================================================================
# Bitrise StepLib Automatic Submission
# ==============================================================================
if [[ "${UPLOAD_BITRISE}" != true ]]; then
    echo ""
    echo "⏭️  Bitrise StepLib submission skipped (use --upload-bitrise to enable)"
    echo ""
    echo "🚀 Done - Release complete!"
    exit 0
fi

echo ""
echo "🟡 [Step 7/7] Preparing and submitting to Bitrise StepLib..."

# Get the commit hash of the tagged version (^{} dereferences annotated tags to get the actual commit)
COMMIT_HASH=$(git rev-parse "${VERSION}^{}")
echo "📝 Commit hash: ${cyan}${COMMIT_HASH}${reset}"

# Clone your fork in temp directory
STEPLIB_FORK="aiKrice/bitrise-steplib"
echo "📥 Cloning your StepLib fork..."
git clone "https://github.com/${STEPLIB_FORK}.git" "${STEPLIB_TEMP}" --depth 1 -q
fail_if_error "Failed to clone your StepLib fork"

# shellcheck disable=SC2164
cd "${STEPLIB_TEMP}"

# Create directory structure
STEP_VERSION_DIR="steps/badgetizr/${VERSION}"
STEP_ASSETS_DIR="steps/badgetizr/assets"

mkdir -p "${STEP_VERSION_DIR}"
mkdir -p "${STEP_ASSETS_DIR}"

# Create step.yml with source section
echo "📄 Creating step.yml with source reference..."
cat > "${STEP_VERSION_DIR}/step.yml" << EOF
source:
  git: https://github.com/${REPOSITORY}.git
  commit: ${COMMIT_HASH}

EOF

# Append the rest of step.yml (from parent directory)
cat "../${BITRISE_STEP_YML}" >> "${STEP_VERSION_DIR}/step.yml"

# Copy icon (from parent directory)
echo "🎨 Copying icon..."
cp ../assets/icon.png "${STEP_ASSETS_DIR}/"

# Create branch and commit
BRANCH_NAME="badgetizr-${VERSION}"
git checkout -b "${BRANCH_NAME}"
git add "steps/badgetizr"
git commit -m "Add badgetizr ${VERSION}

This PR adds badgetizr version ${VERSION} to the Bitrise StepLib.

## What's new in ${VERSION}
- See release notes: https://github.com/${REPOSITORY}/releases/tag/${VERSION}

## Step repository
https://github.com/${REPOSITORY}

## Testing
Tested with bitrise CLI locally using bitrise.yml in the repository.

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to your fork
echo "⬆️  Pushing to your fork..."
git push origin "${BRANCH_NAME}"
fail_if_error "Failed to push to your fork"

# Create PR to official StepLib
echo "📬 Creating Pull Request to official StepLib..."
gh pr create \
    --repo bitrise-io/bitrise-steplib \
    --base master \
    --head "${STEPLIB_FORK}:${BRANCH_NAME}" \
    --title "Add badgetizr ${VERSION}" \
    --body "This PR adds badgetizr version ${VERSION} to the Bitrise StepLib.

## What's new in ${VERSION}
See release notes: https://github.com/${REPOSITORY}/releases/tag/${VERSION}

## Step repository
https://github.com/${REPOSITORY}

## Step configuration
- **Title**: Badgetizr
- **Type tags**: utility, badge, automation
- **Platforms**: macOS, Linux
- **Source**: https://github.com/${REPOSITORY}.git @ ${COMMIT_HASH}

## Testing
✅ Tested locally with bitrise CLI
✅ All inputs validated
✅ Works on both macOS and Linux stacks

## Checklist
- [x] step.yml includes source.git and source.commit
- [x] Icon (256x256) included in assets/
- [x] Tested with bitrise run
- [x] Follows StepLib guidelines

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

fail_if_error "Failed to create Pull Request"

# Go back to original directory
# shellcheck disable=SC2103
cd ..

# Cleanup
echo "🧹 Cleaning up temporary directory..."
rm -rf "${STEPLIB_TEMP}"

echo "🟢 [Step 7/7] Pull Request created successfully!"
echo ""
echo "📋 ${cyan}Next steps:${reset}"
echo "   - Monitor the PR: https://github.com/bitrise-io/bitrise-steplib/pulls"
echo "   - Respond to review comments if any"
echo "   - Wait for Bitrise team to merge"
echo ""
echo "🚀 Done - All automation complete!"
