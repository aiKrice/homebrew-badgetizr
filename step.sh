#!/bin/bash
set -e

# Cleanup trap handler
TEMP_DIR=""
cleanup() {
    if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}
trap cleanup EXIT

echo "🚀 Starting Badgetizr for Bitrise"

# Validate required inputs
if [[ -z "${pr_id}" ]]; then
    echo "❌ Error: pr_id is required"
    exit 1
fi

# Validate authentication token
if [[ -z "${github_token}" ]] && [[ -z "${gitlab_token}" ]]; then
    echo "❌ Error: No authentication token provided"
    echo "   Please configure GITHUB_TOKEN or GITLAB_TOKEN in Bitrise Secrets"
    echo "   See: https://github.com/aiKrice/homebrew-badgetizr/blob/master/BITRISE.md#step-2-configure-secrets"
    exit 1
fi

# Badgetizr version (matches step version)
BADGETIZR_VERSION="3.0.0"

echo "📦 Badgetizr version: ${BADGETIZR_VERSION}"

# Create a local bin directory for tools (user-writable)
LOCAL_BIN="${HOME}/.local/bin"
mkdir -p "${LOCAL_BIN}"
export PATH="${LOCAL_BIN}:${PATH}"

# Detect OS and install dependencies
if [[ "${OSTYPE}" == "darwin"* ]]; then
    echo "🍎 Running on macOS"
    OS_TYPE="macos"
    # yq is pre-installed on Bitrise macOS stacks
else
    echo "🐧 Running on Linux"
    OS_TYPE="linux"

    # Install yq for Linux (latest version)
    if ! command -v yq &> /dev/null; then
        echo "📥 Installing yq..."
        wget -qO "${LOCAL_BIN}/yq" https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        chmod +x "${LOCAL_BIN}/yq"
    fi
fi

# Install provider CLIs based on provider setting or auto-detection
PROVIDER="${provider}"

# Set up authentication tokens
if [[ -n "${github_token}" ]]; then
    export GITHUB_TOKEN="${github_token}"
    export GH_TOKEN="${github_token}"
fi

if [[ -n "${gitlab_token}" ]]; then
    export GITLAB_TOKEN="${gitlab_token}"
fi

if [[ -n "${gitlab_host}" ]]; then
    export GITLAB_HOST="${gitlab_host}"
fi

# Install GitHub CLI if needed
if [[ "${PROVIDER}" == "github" ]] || [[ -z "${PROVIDER}" ]]; then
    if ! command -v gh &> /dev/null; then
        echo "📥 Installing GitHub CLI..."
        if [[ "${OS_TYPE}" == "macos" ]]; then
            brew install gh
        else
            # Linux installation - download binary directly
            GH_VERSION="2.83.1"
            curl -sSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp
            mv "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" "${LOCAL_BIN}/gh"
            chmod +x "${LOCAL_BIN}/gh"
            rm -rf "/tmp/gh_${GH_VERSION}_linux_amd64"
        fi
    fi
fi

# Install GitLab CLI if needed
if [[ "${PROVIDER}" == "gitlab" ]] || [[ -z "${PROVIDER}" ]]; then
    if ! command -v glab &> /dev/null; then
        echo "📥 Installing GitLab CLI..."
        GLAB_VERSION="1.78.3"
        if [[ "${OS_TYPE}" == "macos" ]]; then
            brew install glab
        else
            # Linux installation - download binary directly
            curl -sSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp
            mv /tmp/bin/glab "${LOCAL_BIN}/glab"
            chmod +x "${LOCAL_BIN}/glab"
            rm -rf /tmp/bin
        fi
    fi
fi

# Download and extract badgetizr
echo "📥 Downloading Badgetizr v${BADGETIZR_VERSION}..."
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

curl -sSL "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/${BADGETIZR_VERSION}.tar.gz" | tar -xz
cd homebrew-badgetizr-*

echo "🔧 Configuring Badgetizr..."

# Build the command arguments
ARGS=()

# Add configuration file
if [[ -n "${configuration}" ]]; then
    # Make path absolute if it's relative (relative to original workspace)
    if [[ "${configuration}" != /* ]]; then
        # shellcheck disable=SC2154
        configuration="${BITRISE_SOURCE_DIR}/${configuration}"
    fi
    ARGS+=("-c" "${configuration}")
fi

# Add PR ID (required)
ARGS+=("--pr-id=${pr_id}")

# Add optional parameters
if [[ -n "${pr_destination_branch}" ]]; then
    ARGS+=("--pr-destination-branch=${pr_destination_branch}")
fi

if [[ -n "${pr_build_number}" ]]; then
    ARGS+=("--pr-build-number=${pr_build_number}")
fi

if [[ -n "${pr_build_url}" ]]; then
    ARGS+=("--pr-build-url=${pr_build_url}")
fi

if [[ -n "${ci_status}" ]]; then
    ARGS+=("--ci-status=${ci_status}")
fi

if [[ -n "${ci_text}" ]]; then
    ARGS+=("--ci-text=${ci_text}")
fi

if [[ -n "${provider}" ]]; then
    ARGS+=("--provider=${provider}")
fi

# Execute badgetizr from the source directory
echo "🎯 Running Badgetizr with arguments: ${ARGS[*]}"
BADGETIZR_PATH="$(pwd)/badgetizr"
# shellcheck disable=SC2154
cd "${BITRISE_SOURCE_DIR}"
"${BADGETIZR_PATH}" "${ARGS[@]}"

echo "✅ Badgetizr completed successfully!"
