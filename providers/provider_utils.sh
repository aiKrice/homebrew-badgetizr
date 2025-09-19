#!/bin/bash

# Provider detection and common interface
detect_provider() {
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [[ "$remote_url" =~ github\.com ]]; then
        echo "github"
    elif [[ "$remote_url" =~ gitlab\.com ]] || [[ "$remote_url" =~ gitlab\. ]]; then
        echo "gitlab"
    else
        echo "github"  # Default fallback
    fi
}

# Load the appropriate provider (uses BASE_PATH from main script)
load_provider() {
    local provider="$1"
    local provider_file="$BASE_PATH/providers/${provider}.sh"

    if [[ -f "$provider_file" ]]; then
        source "$provider_file"
        echo "🔗 Loaded $provider provider"
    else
        echo "❌ Provider $provider not found at $provider_file"
        exit 1
    fi
}

# Common interface functions (must be implemented by each provider)
get_pr_info() {
    provider_get_pr_info "$@"
}

update_pr_description() {
    provider_update_pr_description "$@"
}

add_pr_label() {
    provider_add_pr_label "$@"
}

remove_pr_label() {
    provider_remove_pr_label "$@"
}

create_pr_label() {
    provider_create_pr_label "$@"
}

test_provider_auth() {
    provider_test_auth "$@"
}

get_destination_branch() {
    provider_get_destination_branch "$@"
}

check_provider_cli() {
    local provider="$1"

    case "$provider" in
        "github")
            if ! command -v gh &> /dev/null; then
                echo "❌ Error: GitHub CLI (gh) is not installed"
                echo "📝 Install it with:"
                echo "   - macOS: brew install gh"
                echo "   - Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
                echo "   - Or run: ./configure"
                return 1
            fi
            ;;
        "gitlab")
            if ! command -v glab &> /dev/null; then
                echo "❌ Error: GitLab CLI (glab) is not installed"
                echo "📝 Install it from: https://gitlab.com/gitlab-org/cli/-/releases"
                echo "   - Or run: ./configure"
                return 1
            fi
            ;;
        *)
            echo "❌ Error: Unknown provider '$provider'"
            return 1
            ;;
    esac

    echo "✅ $provider CLI is available"
    return 0
}