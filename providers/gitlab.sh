#!/bin/bash

# GitLab provider implementation using glab CLI
# shellcheck disable=SC2154  # CI_PROJECT_PATH is a GitLab CI environment variable

provider_get_pr_info() {
    local mr_id="$1"

    # Fetch both title and description in a single call for efficiency
    glab mr view "${mr_id}" --repo="${CI_PROJECT_PATH}" --output json 2> /dev/null
}

provider_update_pr_description() {
    local mr_id="$1"
    local new_body="$2"

    glab mr update "${mr_id}" --description "${new_body}" --repo="${CI_PROJECT_PATH}" 2> /dev/null
}

provider_add_pr_label() {
    local mr_id="$1"
    local label_name="$2"

    echo "🏷️  Adding GitLab label: ${label_name}"

    if glab mr update "${mr_id}" --label "${label_name}" --repo="${CI_PROJECT_PATH}" 2> /dev/null; then
        echo "✅ Label '${label_name}' added successfully"
        return 0
    else
        return 1
    fi
}

provider_remove_pr_label() {
    local mr_id="$1"
    local label_name="$2"

    echo "🏷️  Removing GitLab label: ${label_name}"

    if glab mr update "${mr_id}" --unlabel "${label_name}" --repo="${CI_PROJECT_PATH}" 2> /dev/null; then
        echo "✅ Label '${label_name}' removed successfully"
    else
        echo "ℹ️  Label '${label_name}' was not present on this MR"
    fi
}

provider_create_pr_label() {
    local label_name="$1"
    local hex_color="$2"
    local description="$3"

    # GitLab expects color with # prefix
    local gitlab_color="#${hex_color}"

    # Check if label already exists with correct description
    local existing_description
    existing_description=$(glab label list --output json --repo="${CI_PROJECT_PATH}" 2> /dev/null |
        yq -r ".[] | select(.name==\"${label_name}\") | .description" 2> /dev/null)

    if [[ -n "${existing_description}" ]]; then
        if [[ "${existing_description}" == "${description}" ]]; then
            echo "ℹ️  Label '${label_name}' already exists with correct description"
            return 0
        else
            echo "⚠️  Label '${label_name}' exists but with different description"
            echo "    Existing: '${existing_description}'"
            echo "    Expected: '${description}'"
            echo "    Using existing label to avoid conflicts"
            return 0
        fi
    fi

    # Label doesn't exist, create it
    echo "🔧 Creating label '${label_name}' with color ${gitlab_color}"
    local result
    result=$(glab label create --name "${label_name}" --color "${gitlab_color}" --description "${description}" --repo="${CI_PROJECT_PATH}" 2>&1)
    local exit_code=$?

    if [[ "${result}" == *"Label already exists"* ]] || [[ ${exit_code} -eq 0 ]]; then
        echo "✅ Label '${label_name}' created successfully"
        return 0
    else
        echo "❌ Failed to create label '${label_name}' - exit code: ${exit_code}"
        return 1
    fi
}

provider_get_destination_branch() {
    local mr_id="$1"

    glab mr view "${mr_id}" --repo="${CI_PROJECT_PATH}" --output json 2> /dev/null | yq -r '.target_branch'
}

provider_test_auth() {
    echo "🔐 Testing GitLab authentication..."

    # glab supports multiple token environment variables
    if [[ -n "${GITLAB_TOKEN}" ]]; then
        echo "🔍 Found GITLAB_TOKEN environment variable"
    elif [[ -n "${GITLAB_ACCESS_TOKEN}" ]]; then
        echo "🔍 Found GITLAB_ACCESS_TOKEN, setting GITLAB_TOKEN"
        export GITLAB_TOKEN="${GITLAB_ACCESS_TOKEN}"
    elif [[ -n "${GL_TOKEN}" ]]; then
        echo "🔍 Found GL_TOKEN, setting GITLAB_TOKEN"
        export GITLAB_TOKEN="${GL_TOKEN}"
    fi

    # Determine GitLab host (supports self-managed instances)
    local gitlab_host="${GITLAB_HOST:-gitlab.com}"
    echo "🔍 Using GitLab host: ${gitlab_host}"

    # Configure glab for self-managed instances
    if [[ "${gitlab_host}" != "gitlab.com" ]]; then
        echo "🔧 Configuring glab for self-managed GitLab instance..."
        export GITLAB_HOST="${gitlab_host}"
        glab auth status --hostname "${gitlab_host}" > /dev/null 2>&1 || {
            echo "⚙️  Authenticating glab with ${gitlab_host}..."
            echo "${GITLAB_TOKEN}" | glab auth login --hostname "${gitlab_host}" --stdin > /dev/null 2>&1
        }
    fi

    # Test with GitLab API directly
    if curl -s -H "Authorization: Bearer ${GITLAB_TOKEN}" "https://${gitlab_host}/api/v4/user" > /dev/null 2>&1; then
        echo "✅ GitLab authentication is working"
        return 0
    else
        echo "❌ GitLab authentication failed. Please run: glab auth login"
        echo "   Or set a valid GITLAB_TOKEN environment variable"
        if [[ "${gitlab_host}" != "gitlab.com" ]]; then
            echo "   For self-managed GitLab, ensure GITLAB_HOST is set correctly"
        fi
        return 1
    fi
}

provider_is_label_managed() {
    local label_name="$1"

    # Fetch label description from GitLab
    local description
    description=$(glab label list --output json --repo="${CI_PROJECT_PATH}" 2> /dev/null |
        yq -r ".[] | select(.name==\"${label_name}\") | .description" 2> /dev/null)

    # Check if description matches exactly
    # shellcheck disable=SC2154  # BADGETIZR_LABEL_DESCRIPTION is defined in provider_utils.sh
    [[ "${description}" == "${BADGETIZR_LABEL_DESCRIPTION}" ]]
}
