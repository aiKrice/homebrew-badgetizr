#!/bin/bash
# Mock GitLab CLI (glab) for testing
# Usage: Source this file to override glab commands

# Mock responses storage
export MOCK_GLAB_RESPONSES_DIR="${MOCK_GLAB_RESPONSES_DIR:-/tmp/mock_glab_responses}"
mkdir -p "$MOCK_GLAB_RESPONSES_DIR"

# Mock MR info
MOCK_MR_TITLE="${MOCK_MR_TITLE:-Test MR Title}"
MOCK_MR_DESCRIPTION="${MOCK_MR_DESCRIPTION:-Test MR description content}"
MOCK_MR_TARGET_BRANCH="${MOCK_MR_TARGET_BRANCH:-main}"
MOCK_MR_SOURCE_BRANCH="${MOCK_MR_SOURCE_BRANCH:-feature/test}"
MOCK_MR_STATE="${MOCK_MR_STATE:-opened}"

# Mock labels
MOCK_MR_LABELS="${MOCK_MR_LABELS:-}"

# Mock auth status
MOCK_GLAB_AUTH_SUCCESS="${MOCK_GLAB_AUTH_SUCCESS:-true}"

# Mock glab command
glab() {
    local subcommand="$1"
    shift

    case "$subcommand" in
        mr)
            glab_mr "$@"
            ;;
        auth)
            glab_auth "$@"
            ;;
        label)
            glab_label "$@"
            ;;
        *)
            echo "mock_glab: Unknown command: $subcommand" >&2
            return 1
            ;;
    esac
}

glab_mr() {
    local action="$1"
    shift

    case "$action" in
        view)
            glab_mr_view "$@"
            ;;
        update)
            glab_mr_update "$@"
            ;;
        label)
            glab_mr_label "$@"
            ;;
        *)
            echo "mock_glab mr: Unknown action: $action" >&2
            return 1
            ;;
    esac
}

glab_mr_view() {
    # Parse arguments
    local mr_number=""
    local format=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -F|--format|--output)
                format="$2"
                shift 2
                ;;
            --repo)
                # Skip repo argument
                shift 2
                ;;
            *)
                mr_number="$1"
                shift
                ;;
        esac
    done

    # Return mock data based on format
    case "$format" in
        json)
            cat <<JSON
{
  "title": "$MOCK_MR_TITLE",
  "description": "$MOCK_MR_DESCRIPTION",
  "target_branch": "$MOCK_MR_TARGET_BRANCH",
  "source_branch": "$MOCK_MR_SOURCE_BRANCH",
  "state": "$MOCK_MR_STATE",
  "labels": []
}
JSON
            ;;
        *)
            # Default text format
            cat <<TEXT
Title: $MOCK_MR_TITLE
Description: $MOCK_MR_DESCRIPTION
Target Branch: $MOCK_MR_TARGET_BRANCH
Source Branch: $MOCK_MR_SOURCE_BRANCH
State: $MOCK_MR_STATE
TEXT
            ;;
    esac
}

glab_mr_update() {
    local mr_number=""
    local new_description=""
    local label_to_add=""
    local label_to_remove=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --description|-d)
                new_description="$2"
                shift 2
                ;;
            --label|-l)
                label_to_add="$2"
                shift 2
                ;;
            --unlabel)
                label_to_remove="$2"
                shift 2
                ;;
            --repo)
                # Skip repo argument
                shift 2
                ;;
            *)
                mr_number="$1"
                shift
                ;;
        esac
    done

    # Update mock MR description if provided
    if [ -n "$new_description" ]; then
        MOCK_MR_DESCRIPTION="$new_description"
        echo "$new_description" > "$MOCK_GLAB_RESPONSES_DIR/mr_description.txt"
    fi

    # Track label additions
    if [ -n "$label_to_add" ]; then
        echo "$label_to_add" >> "$MOCK_GLAB_RESPONSES_DIR/added_labels.txt"
    fi

    # Track label removals
    if [ -n "$label_to_remove" ]; then
        echo "$label_to_remove" >> "$MOCK_GLAB_RESPONSES_DIR/removed_labels.txt"
    fi

    return 0
}

glab_mr_label() {
    local mr_number=""
    local labels_to_add=()
    local labels_to_remove=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --add|-a)
                IFS=',' read -ra labels_to_add <<< "$2"
                shift 2
                ;;
            --remove|-r)
                IFS=',' read -ra labels_to_remove <<< "$2"
                shift 2
                ;;
            *)
                mr_number="$1"
                shift
                ;;
        esac
    done

    # Track label changes
    for label in "${labels_to_add[@]}"; do
        echo "$label" >> "$MOCK_GLAB_RESPONSES_DIR/added_labels.txt"
    done

    for label in "${labels_to_remove[@]}"; do
        echo "$label" >> "$MOCK_GLAB_RESPONSES_DIR/removed_labels.txt"
    done

    return 0
}

glab_auth() {
    local action="$1"
    shift

    case "$action" in
        status)
            if [ "$MOCK_GLAB_AUTH_SUCCESS" = "true" ]; then
                echo "✓ Logged in to gitlab.com as testuser"
                return 0
            else
                echo "✗ Not logged in" >&2
                return 1
            fi
            ;;
        *)
            echo "mock_glab auth: Unknown action: $action" >&2
            return 1
            ;;
    esac
}

glab_label() {
    local action="$1"
    shift

    case "$action" in
        create)
            # Mock label creation
            local label_name=""
            local color=""

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --name|-n)
                        label_name="$2"
                        shift 2
                        ;;
                    --color|-c)
                        color="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done

            echo "$label_name" >> "$MOCK_GLAB_RESPONSES_DIR/created_labels.txt"
            return 0
            ;;
        list)
            # Return list of created labels
            if [ -f "$MOCK_GLAB_RESPONSES_DIR/created_labels.txt" ]; then
                cat "$MOCK_GLAB_RESPONSES_DIR/created_labels.txt"
            fi
            return 0
            ;;
        *)
            echo "mock_glab label: Unknown action: $action" >&2
            return 1
            ;;
    esac
}

# Export functions so they're available in subshells
export -f glab
export -f glab_mr
export -f glab_mr_view
export -f glab_mr_update
export -f glab_mr_label
export -f glab_auth
export -f glab_label

# Cleanup function
mock_glab_cleanup() {
    rm -rf "$MOCK_GLAB_RESPONSES_DIR"
}

export -f mock_glab_cleanup
