#!/bin/bash

# GitLab provider implementation using glab CLI

provider_get_pr_info() {
    local mr_id="$1"
    local field="$2"

    case "$field" in
        "title")
            glab mr view "$mr_id" --repo="$CI_PROJECT_PATH" --output json 2>/dev/null | jq -r '.title // empty'
            ;;
        "body")
            # Get description and remove existing badgetizr comments
            glab mr view "$mr_id" --repo="$CI_PROJECT_PATH" --output json 2>/dev/null | jq -r '.description // ""' | sed '/<!--begin:badgetizr-->/,/<!--end:badgetizr-->/d'
            ;;
        "both")
            local title=$(glab mr view "$mr_id" --repo="$CI_PROJECT_PATH" --output json 2>/dev/null | jq -r '.title // empty')
            local body=$(glab mr view "$mr_id" --repo="$CI_PROJECT_PATH" --output json 2>/dev/null | jq -r '.description // ""' | sed '/<!--begin:badgetizr-->/,/<!--end:badgetizr-->/d')
            echo "TITLE:$title"
            echo "BODY:$body"
            ;;
        *)
            echo "❌ Unknown field: $field. You can investigate and open a pull request if you know why."
            return 1
            ;;
    esac
}

provider_update_pr_description() {
    local mr_id="$1"
    local new_body="$2"

    glab mr update "$mr_id" --description "$new_body" --repo="$CI_PROJECT_PATH" 2>/dev/null
}

provider_add_pr_label() {
    local mr_id="$1"
    local label_name="$2"

    echo "🏷️  Adding GitLab label: $label_name"

    # Check if label already exists with proper colors (avoid recreation)
    if glab label list --repo="$CI_PROJECT_PATH" 2>/dev/null | grep -F "$label_name" >/dev/null 2>&1; then
        # Label exists, just add it normally
        if glab mr update "$mr_id" --label "$label_name" --repo="$CI_PROJECT_PATH" 2>/dev/null; then
            echo "✅ Label '$label_name' added successfully"
            return 0
        else
            return 1
        fi
    else
        # Label doesn't exist, force creation with colors
        echo "⚠️  Label '$label_name' doesn't exist, will create with proper colors"
        return 1
    fi
}

provider_remove_pr_label() {
    local mr_id="$1"
    local label_name="$2"

    echo "🏷️  Removing GitLab label: $label_name"

    if glab mr update "$mr_id" --unlabel "$label_name" --repo="$CI_PROJECT_PATH" 2>/dev/null; then
        echo "✅ Label '$label_name' removed successfully"
    else
        echo "ℹ️  Label '$label_name' was not present on this MR"
    fi
}

provider_create_pr_label() {
    local label_name="$1"
    local hex_color="$2"
    local description="$3"

    echo "⚠️  Label '$label_name' doesn't exist, creating it..."

    # GitLab expects color with # prefix
    local gitlab_color="#$hex_color"

    # Delete label first if it exists, then recreate with correct colors
    echo "🗑️  Deleting existing label '$label_name'..."
    glab label delete "$label_name" --repo="$CI_PROJECT_PATH" 2>/dev/null || true

    echo "🔧 Creating label: glab label create --name \"$label_name\" --color \"$gitlab_color\" --description \"$description\" --repo=\"$CI_PROJECT_PATH\""
    local result=$(glab label create --name "$label_name" --color "$gitlab_color" --description "$description" --repo="$CI_PROJECT_PATH" 2>&1)
    local exit_code=$?

    echo "🐛 glab exit code: $exit_code"
    echo "🐛 glab output: $result"

    if [[ "$result" == *"Label already exists"* ]]; then
        echo "ℹ️  Label '$label_name' already exists (shouldn't happen after delete)"
        return 0
    elif [[ $exit_code -eq 0 ]]; then
        echo "✅ Label '$label_name' created successfully"
        return 0
    else
        echo "❌ Failed to create label '$label_name' - exit code: $exit_code"
        return 1
    fi
}

provider_get_destination_branch() {
    local mr_id="$1"

    glab mr view "$mr_id" --repo="$CI_PROJECT_PATH" --output json 2>/dev/null | jq -r '.target_branch // empty'
}

provider_test_auth() {
    echo "🔐 Testing GitLab authentication..."

    # glab supports multiple token environment variables
    if [[ -n "$GITLAB_TOKEN" ]]; then
        echo "🔍 Found GITLAB_TOKEN environment variable"
    elif [[ -n "$GITLAB_ACCESS_TOKEN" ]]; then
        echo "🔍 Found GITLAB_ACCESS_TOKEN, setting GITLAB_TOKEN"
        export GITLAB_TOKEN="$GITLAB_ACCESS_TOKEN"
    elif [[ -n "$GL_TOKEN" ]]; then
        echo "🔍 Found GL_TOKEN, setting GITLAB_TOKEN"
        export GITLAB_TOKEN="$GL_TOKEN"
    fi

    # Test with GitLab API directly
    if curl -s -H "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/user" >/dev/null 2>&1; then
        echo "✅ GitLab authentication is working"
        return 0
    else
        echo "❌ GitLab authentication failed. Please run: glab auth login"
        echo "   Or set a valid GITLAB_TOKEN environment variable"
        return 1
    fi
}