#!/bin/bash
# Mock responses for common scenarios
# Source this file to set up predefined test scenarios

# Scenario: WIP PR
setup_wip_pr() {
    export MOCK_PR_TITLE="[WIP] Add new feature"
    export MOCK_PR_BODY="This is a work in progress PR"
    export MOCK_PR_BASE_BRANCH="develop"
    export MOCK_PR_HEAD_BRANCH="feature/wip-test"
    export MOCK_PR_STATE="open"
    export MOCK_PR_LABELS=""
}

# Scenario: Hotfix PR
setup_hotfix_pr() {
    export MOCK_PR_TITLE="[HOTFIX] Fix critical bug"
    export MOCK_PR_BODY="Emergency fix for production issue"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="hotfix/critical-fix"
    export MOCK_PR_STATE="open"
    export MOCK_PR_LABELS=""
}

# Scenario: PR with ticket ID
setup_ticket_pr() {
    export MOCK_PR_TITLE="feat(ABC-123): Add user authentication"
    export MOCK_PR_BODY="Implements user authentication with JWT"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="feature/auth"
    export MOCK_PR_STATE="open"
    export MOCK_PR_LABELS=""
}

# Scenario: PR with dynamic badges (checkboxes)
setup_dynamic_pr() {
    export MOCK_PR_TITLE="Add feature with checklist"
    export MOCK_PR_BODY="## Checklist
- [ ] The PR starts by
- [ ] I have added WIP
- [x] Tests added
- [x] Documentation updated"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="feature/checklist"
    export MOCK_PR_STATE="open"
    export MOCK_PR_LABELS=""
}

# Scenario: PR targeting non-default branch
setup_branch_target_pr() {
    export MOCK_PR_TITLE="Feature for release branch"
    export MOCK_PR_BODY="Adding feature to release branch"
    export MOCK_PR_BASE_BRANCH="release/v2.0"
    export MOCK_PR_HEAD_BRANCH="feature/new-feature"
    export MOCK_PR_STATE="open"
    export MOCK_PR_LABELS=""
}

# Scenario: PR with existing labels
setup_labeled_pr() {
    export MOCK_PR_TITLE="PR with labels"
    export MOCK_PR_BODY="Testing label management"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="feature/labels"
    export MOCK_PR_STATE="open"
    export MOCK_PR_LABELS="bug,enhancement"
}

# Scenario: CI statuses
setup_ci_started() {
    export CI_STATUS="started"
    export CI_TEXT="Running tests"
}

setup_ci_passed() {
    export CI_STATUS="passed"
    export CI_TEXT="All tests passed"
}

setup_ci_failed() {
    export CI_STATUS="failed"
    export CI_TEXT="Tests failed"
}

# GitLab scenarios (MR instead of PR)
setup_wip_mr() {
    export MOCK_MR_TITLE="WIP: Add new feature"
    export MOCK_MR_DESCRIPTION="This is a work in progress MR"
    export MOCK_MR_TARGET_BRANCH="develop"
    export MOCK_MR_SOURCE_BRANCH="feature/wip-test"
    export MOCK_MR_STATE="opened"
    export MOCK_MR_LABELS=""
}

setup_hotfix_mr() {
    export MOCK_MR_TITLE="HOTFIX: Fix critical bug"
    export MOCK_MR_DESCRIPTION="Emergency fix for production issue"
    export MOCK_MR_TARGET_BRANCH="develop"
    export MOCK_MR_SOURCE_BRANCH="hotfix/critical-fix"
    export MOCK_MR_STATE="opened"
    export MOCK_MR_LABELS=""
}

# Reset all mock variables
reset_mocks() {
    unset MOCK_PR_TITLE MOCK_PR_BODY MOCK_PR_BASE_BRANCH MOCK_PR_HEAD_BRANCH MOCK_PR_STATE MOCK_PR_LABELS
    unset MOCK_MR_TITLE MOCK_MR_DESCRIPTION MOCK_MR_TARGET_BRANCH MOCK_MR_SOURCE_BRANCH MOCK_MR_STATE MOCK_MR_LABELS
    unset CI_STATUS CI_TEXT
    export MOCK_AUTH_SUCCESS="true"
    export MOCK_GLAB_AUTH_SUCCESS="true"
}

# Export all setup functions
export -f setup_wip_pr
export -f setup_hotfix_pr
export -f setup_ticket_pr
export -f setup_dynamic_pr
export -f setup_branch_target_pr
export -f setup_labeled_pr
export -f setup_ci_started
export -f setup_ci_passed
export -f setup_ci_failed
export -f setup_wip_mr
export -f setup_hotfix_mr
export -f reset_mocks
