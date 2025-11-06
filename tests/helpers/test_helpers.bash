#!/bin/bash
# Common test helper functions for badgetizr tests

# Get the project root directory
get_project_root() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
}

# Setup test environment
setup_test_env() {
    export PROJECT_ROOT="$(get_project_root)"
    export BADGETIZR_SCRIPT="$PROJECT_ROOT/badgetizr"
    export UTILS_SCRIPT="$PROJECT_ROOT/utils.sh"
    export TEST_CONFIG="$PROJECT_ROOT/tests/fixtures/test-config.yml"

    # Create temp directory for test artifacts
    export TEST_TEMP_DIR="$(mktemp -d)"

    # Setup PATH to include mocks
    export PATH="$PROJECT_ROOT/tests/mocks:$PATH"
}

# Cleanup test environment
cleanup_test_env() {
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi

    # Cleanup mock directories
    mock_gh_cleanup 2>/dev/null || true
    mock_glab_cleanup 2>/dev/null || true
}

# Load badgetizr functions without executing the script
load_badgetizr_functions() {
    # Source utils.sh first
    if [ -f "$UTILS_SCRIPT" ]; then
        source "$UTILS_SCRIPT"
    fi

    # Source provider utils
    if [ -f "$PROJECT_ROOT/providers/provider_utils.sh" ]; then
        source "$PROJECT_ROOT/providers/provider_utils.sh"
    fi
}

# Create a temporary config file
create_temp_config() {
    local config_content="$1"
    local config_file="$TEST_TEMP_DIR/test-config.yml"

    echo "$config_content" > "$config_file"
    echo "$config_file"
}

# Get default test config
get_default_test_config() {
    cat <<EOF
badge_ci:
  enabled: "true"
  settings:
    label_color: "black"
    label: "Build"
    logo: "github"
    color: darkgreen

badge_ticket:
  enabled: "true"
  settings:
    color: "black"
    label: "Issue"
    sed_pattern: '.*\[GH-([0-9]+)\].*'
    url: "https://github.com/test/repo/issues/%s"
    logo: "github"

badge_base_branch:
  enabled: "true"
  settings:
    color: "orange"
    label: "Base Branch"
    base_branch: "develop"

badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    logo: "vlcmediaplayer"

badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"

badge_dynamic:
  enabled: "false"
  settings:
    patterns: []
EOF
}

# Mock git command
mock_git() {
    git() {
        case "$1" in
            remote)
                if [ "$2" = "get-url" ]; then
                    echo "${MOCK_GIT_REMOTE:-https://github.com/test/repo.git}"
                fi
                ;;
            rev-parse)
                if [ "$2" = "--abbrev-ref" ] && [ "$3" = "HEAD" ]; then
                    echo "${MOCK_GIT_BRANCH:-main}"
                fi
                ;;
            *)
                command git "$@"
                ;;
        esac
    }
    export -f git
}

# Unmock git command
unmock_git() {
    unset -f git
}

# Wait for file to be created (with timeout)
wait_for_file() {
    local file="$1"
    local timeout="${2:-5}"
    local elapsed=0

    while [ ! -f "$file" ] && [ $elapsed -lt $timeout ]; do
        sleep 0.1
        elapsed=$((elapsed + 1))
    done

    [ -f "$file" ]
}

# Extract badges from PR description
extract_badges_section() {
    local pr_description="$1"

    echo "$pr_description" | sed -n '/<!--begin:badgetizr-->/,/<!--end:badgetizr-->/p'
}

# Count badges in output
count_badges() {
    local output="$1"

    echo "$output" | grep -o 'shields.io' | wc -l | tr -d ' '
}

# Get badge URL by type
get_badge_url_by_type() {
    local output="$1"
    local badge_type="$2"

    case "$badge_type" in
        wip)
            echo "$output" | grep -o 'https://[^ ]*shields.io[^ ]*WIP[^ ]*'
            ;;
        hotfix)
            echo "$output" | grep -o 'https://[^ ]*shields.io[^ ]*HOTFIX[^ ]*'
            ;;
        ci)
            echo "$output" | grep -o 'https://[^ ]*shields.io[^ ]*Build[^ ]*'
            ;;
        *)
            echo ""
            ;;
    esac
}

# Validate badge URL format
validate_badge_url() {
    local url="$1"

    # Check if it's a shields.io URL
    if ! echo "$url" | grep -q "shields.io"; then
        return 1
    fi

    # Check if it has required format: /badge/text-color
    if ! echo "$url" | grep -qE "/badge/[^-]+-[a-z]+"; then
        return 1
    fi

    return 0
}

# Create PR description fixture
create_pr_description_fixture() {
    local fixture_name="$1"
    local content="$2"

    local fixture_file="$PROJECT_ROOT/tests/fixtures/pr-descriptions/${fixture_name}.txt"
    echo "$content" > "$fixture_file"
    echo "$fixture_file"
}

# Load PR description fixture
load_pr_description_fixture() {
    local fixture_name="$1"
    local fixture_file="$PROJECT_ROOT/tests/fixtures/pr-descriptions/${fixture_name}.txt"

    if [ -f "$fixture_file" ]; then
        cat "$fixture_file"
    else
        echo ""
    fi
}

# Simulate badgetizr execution with mocks
simulate_badgetizr_run() {
    local pr_id="$1"
    local config_file="${2:-$TEST_CONFIG}"
    local additional_args="${3:-}"

    # Run badgetizr with mocked environment
    bash "$BADGETIZR_SCRIPT" \
        -c "$config_file" \
        --pr-id="$pr_id" \
        $additional_args
}

# Debug helper: print all mock state
debug_print_mock_state() {
    echo "=== Mock State ==="
    echo "PR Title: $MOCK_PR_TITLE"
    echo "PR Body: $MOCK_PR_BODY"
    echo "PR Base: $MOCK_PR_BASE_BRANCH"
    echo "PR Head: $MOCK_PR_HEAD_BRANCH"
    echo "PR State: $MOCK_PR_STATE"
    echo "PR Labels: $MOCK_PR_LABELS"

    if [ -d "/tmp/mock_gh_responses" ]; then
        echo "=== Mock Actions ==="
        [ -f "/tmp/mock_gh_responses/added_labels.txt" ] && \
            echo "Added labels:" && cat "/tmp/mock_gh_responses/added_labels.txt"
        [ -f "/tmp/mock_gh_responses/removed_labels.txt" ] && \
            echo "Removed labels:" && cat "/tmp/mock_gh_responses/removed_labels.txt"
        [ -f "/tmp/mock_gh_responses/created_labels.txt" ] && \
            echo "Created labels:" && cat "/tmp/mock_gh_responses/created_labels.txt"
    fi
    echo "=================="
}

# Export all helper functions
export -f get_project_root
export -f setup_test_env
export -f cleanup_test_env
export -f load_badgetizr_functions
export -f create_temp_config
export -f get_default_test_config
export -f mock_git
export -f unmock_git
export -f wait_for_file
export -f extract_badges_section
export -f count_badges
export -f get_badge_url_by_type
export -f validate_badge_url
export -f create_pr_description_fixture
export -f load_pr_description_fixture
export -f simulate_badgetizr_run
export -f debug_print_mock_state
