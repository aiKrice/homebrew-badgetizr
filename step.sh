#!/bin/bash
set -e

echo "🚀 Starting Badgetizr for Bitrise"

# Validate required inputs
if [ -z "$pr_id" ]; then
    echo "❌ Error: pr_id is required"
    exit 1
fi

# Set default version if not provided
BADGETIZR_VERSION="${badgetizr_version:-2.3.0}"

echo "📦 Badgetizr version: $BADGETIZR_VERSION"

# Detect OS and install dependencies
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Running on macOS"
    OS_TYPE="macos"

    # Install yq if not present
    if ! command -v yq &> /dev/null; then
        echo "📥 Installing yq..."
        brew install yq
    fi

    # Install jq if not present
    if ! command -v jq &> /dev/null; then
        echo "📥 Installing jq..."
        brew install jq
    fi
else
    echo "🐧 Running on Linux"
    OS_TYPE="linux"

    # Install dependencies for Linux
    echo "📥 Installing dependencies (curl, bash, yq, jq)..."

    # Install yq
    if ! command -v yq &> /dev/null; then
        YQ_VERSION="v4.35.1"
        YQ_BINARY="yq_linux_amd64"
        wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}" -O /usr/local/bin/yq
        chmod +x /usr/local/bin/yq
    fi

    # Install jq
    if ! command -v jq &> /dev/null; then
        apt-get update && apt-get install -y jq || true
    fi
fi

# Install provider CLIs based on provider setting or auto-detection
PROVIDER="${provider}"

# Set up authentication tokens
if [ -n "$github_token" ]; then
    export GITHUB_TOKEN="$github_token"
    export GH_TOKEN="$github_token"
fi

if [ -n "$gitlab_token" ]; then
    export GITLAB_TOKEN="$gitlab_token"
fi

if [ -n "$gitlab_host" ]; then
    export GITLAB_HOST="$gitlab_host"
fi

# Install GitHub CLI if needed
if [[ "$PROVIDER" == "github" ]] || [[ -z "$PROVIDER" ]]; then
    if ! command -v gh &> /dev/null; then
        echo "📥 Installing GitHub CLI..."
        if [[ "$OS_TYPE" == "macos" ]]; then
            brew install gh
        else
            # Linux installation
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            apt-get update
            apt-get install -y gh
        fi
    fi
fi

# Install GitLab CLI if needed
if [[ "$PROVIDER" == "gitlab" ]] || [[ -z "$PROVIDER" ]]; then
    if ! command -v glab &> /dev/null; then
        echo "📥 Installing GitLab CLI..."
        GLAB_VERSION="1.72.0"
        if [[ "$OS_TYPE" == "macos" ]]; then
            brew install glab
        else
            # Linux installation
            curl -sSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp
            mv /tmp/bin/glab /usr/local/bin/glab
            chmod +x /usr/local/bin/glab
        fi
    fi
fi

# Download and extract badgetizr
echo "📥 Downloading Badgetizr v${BADGETIZR_VERSION}..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

curl -sSL "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/${BADGETIZR_VERSION}.tar.gz" | tar -xz
cd homebrew-badgetizr-*

echo "🔧 Configuring Badgetizr..."

# Build the command arguments
ARGS=()

# Add configuration file
if [ -n "$configuration" ]; then
    # Make path absolute if it's relative (relative to original workspace)
    if [[ "$configuration" != /* ]]; then
        configuration="$BITRISE_SOURCE_DIR/$configuration"
    fi
    ARGS+=("-c" "$configuration")
fi

# Add PR ID (required)
ARGS+=("--pr-id=$pr_id")

# Add optional parameters
if [ -n "$pr_destination_branch" ]; then
    ARGS+=("--pr-destination-branch=$pr_destination_branch")
fi

if [ -n "$pr_build_number" ]; then
    ARGS+=("--pr-build-number=$pr_build_number")
fi

if [ -n "$pr_build_url" ]; then
    ARGS+=("--pr-build-url=$pr_build_url")
fi

if [ -n "$ci_status" ]; then
    ARGS+=("--ci-status=$ci_status")
fi

if [ -n "$ci_text" ]; then
    ARGS+=("--ci-text=$ci_text")
fi

if [ -n "$provider" ]; then
    ARGS+=("--provider=$provider")
fi

# Execute badgetizr
echo "🎯 Running Badgetizr with arguments: ${ARGS[@]}"
./badgetizr "${ARGS[@]}"

# Cleanup
cd "$BITRISE_SOURCE_DIR"
rm -rf "$TEMP_DIR"

echo "✅ Badgetizr completed successfully!"
