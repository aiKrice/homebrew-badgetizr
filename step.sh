#!/bin/bash
set -e

# Bitrise status constants
readonly BITRISE_STATUS_SUCCEEDED="succeeded"
readonly BITRISE_STATUS_SUCCEEDED_WITH_ABORT="succeeded_with_abort"
readonly BITRISE_BUILD_STATUS_SUCCESS=0

# CI status constants
readonly CI_STATUS_PASSED="passed"
readonly CI_STATUS_FAILED="failed"
readonly CI_STATUS_AUTOMATIC="automatic"

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
BADGETIZR_VERSION="3.0.2"

echo "📦 Badgetizr version: ${BADGETIZR_VERSION}"

# Verify dependencies (gh and glab installed by Bitrise CLI via deps section)
echo "🔍 Verifying dependencies..."

# Install yq for Linux (not in apt_get deps, installed manually)
if [[ "${OSTYPE}" != "darwin"* ]]; then
    LOCAL_BIN="${HOME}/.local/bin"
    mkdir -p "${LOCAL_BIN}"
    export PATH="${LOCAL_BIN}:${PATH}"

    if ! command -v yq &> /dev/null; then
        echo "📥 Installing yq..."
        wget -qO "${LOCAL_BIN}/yq" https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        chmod +x "${LOCAL_BIN}/yq"
    fi
fi

# Verify all required tools are available
MISSING_DEPS=()
if ! command -v yq &> /dev/null; then
    MISSING_DEPS+=("yq")
fi
if ! command -v gh &> /dev/null; then
    MISSING_DEPS+=("gh")
fi
if ! command -v glab &> /dev/null; then
    MISSING_DEPS+=("glab")
fi

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo "❌ Missing dependencies: ${MISSING_DEPS[*]}"
    echo "   These should be installed automatically by Bitrise CLI"
    exit 1
fi

echo "✅ All dependencies available"

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

# Automatic CI status detection based on Bitrise environment variables
if [[ "${ci_status}" == "${CI_STATUS_AUTOMATIC}" ]]; then
    echo "🔍 Detecting CI status automatically from Bitrise environment..."

    # Check if pipeline succeeded (only explicit success states)
    pipeline_success=false
    # shellcheck disable=SC2154
    case "${BITRISE_PIPELINE_BUILD_STATUS}" in
        "${BITRISE_STATUS_SUCCEEDED}" | "${BITRISE_STATUS_SUCCEEDED_WITH_ABORT}")
            pipeline_success=true
            ;;
        "" | *)
            # Empty or any other value (failed, aborted, etc.) = not success
            pipeline_success=false
            ;;
    esac

    # Determine final status based on pipeline and build status
    # shellcheck disable=SC2154
    if [[ "${pipeline_success}" == "true" ]] && [[ "${BITRISE_BUILD_STATUS:-1}" -eq ${BITRISE_BUILD_STATUS_SUCCESS} ]]; then
        ci_status="${CI_STATUS_PASSED}"
        echo "✅ Detected status: ${CI_STATUS_PASSED} (build: ${BITRISE_BUILD_STATUS:-1}, pipeline: ${BITRISE_PIPELINE_BUILD_STATUS:-empty})"
    else
        ci_status="${CI_STATUS_FAILED}"
        echo "❌ Detected status: ${CI_STATUS_FAILED} (build: ${BITRISE_BUILD_STATUS:-1}, pipeline: ${BITRISE_PIPELINE_BUILD_STATUS:-empty})"
    fi
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
