#!/bin/bash

# GitHub provider implementation using gh CLI

provider_get_pr_info() {
    local pr_id="$1"

    # Fetch both title and body in a single call for efficiency
    gh pr view "${pr_id}" --json title,body 2>/dev/null
}

provider_update_pr_description() {
    local pr_id="$1"
    local new_body="$2"

    gh pr edit "${pr_id}" -b "${new_body}"
}

provider_add_pr_label() {
    local pr_id="$1"
    local label_name="$2"

    echo "🏷️  Adding GitHub label: ${label_name}"

    if gh pr edit "${pr_id}" --add-label "${label_name}" 2>/dev/null; then
        echo "✅ Label '${label_name}' added successfully"
        return 0
    else
        return 1
    fi
}

provider_remove_pr_label() {
    local pr_id="$1"
    local label_name="$2"

    echo "🏷️  Removing GitHub label: ${label_name}"

    if gh pr edit "${pr_id}" --remove-label "${label_name}" 2>/dev/null; then
        echo "✅ Label '${label_name}' removed successfully"
    else
        echo "ℹ️  Label '${label_name}' was not present on this PR"
    fi
}

provider_create_pr_label() {
    local label_name="$1"
    local hex_color="$2"
    local description="$3"

    echo "⚠️  Label '${label_name}' doesn't exist, creating it..."

    if gh label create "${label_name}" --color "${hex_color}" --description "${description}" 2>/dev/null; then
        echo "✅ Label '${label_name}' created successfully"
        return 0
    else
        echo "❌ Failed to create label '${label_name}'"
        return 1
    fi
}

provider_get_destination_branch() {
    local pr_id="$1"

    gh pr view "${pr_id}" --json baseRefName --jq '.baseRefName' 2>/dev/null
}

provider_test_auth() {
    echo "🔐 Testing GitHub authentication..."

    if gh auth status >/dev/null 2>&1; then
        echo "✅ GitHub authentication is working"
        return 0
    else
        echo "❌ GitHub authentication failed. Please run: gh auth login"
        echo "   Or set a valid GITHUB_TOKEN environment variable"
        return 1
    fi
}