# Test Mocks

This directory contains mock implementations of external CLI tools for testing.

## Available Mocks

### `mock_gh.sh` - GitHub CLI Mock

Mocks the `gh` command for GitHub operations.

**Usage:**
```bash
source tests/mocks/mock_gh.sh

# Set mock data
export MOCK_PR_TITLE="Test PR"
export MOCK_PR_BODY="Test body"

# Use gh commands (mocked)
gh pr view 123 --json title
gh pr edit 123 --body "New body"
gh auth status
```

**Environment Variables:**
- `MOCK_PR_TITLE` - PR title
- `MOCK_PR_BODY` - PR description
- `MOCK_PR_BASE_BRANCH` - Target branch
- `MOCK_PR_HEAD_BRANCH` - Source branch
- `MOCK_PR_STATE` - PR state (open/closed)
- `MOCK_PR_LABELS` - Comma-separated labels
- `MOCK_AUTH_SUCCESS` - Auth status (true/false)

### `mock_glab.sh` - GitLab CLI Mock

Mocks the `glab` command for GitLab operations.

**Usage:**
```bash
source tests/mocks/mock_glab.sh

# Set mock data
export MOCK_MR_TITLE="Test MR"
export MOCK_MR_DESCRIPTION="Test description"

# Use glab commands (mocked)
glab mr view 123 -F json
glab mr update 123 --description "New description"
glab auth status
```

**Environment Variables:**
- `MOCK_MR_TITLE` - MR title
- `MOCK_MR_DESCRIPTION` - MR description
- `MOCK_MR_TARGET_BRANCH` - Target branch
- `MOCK_MR_SOURCE_BRANCH` - Source branch
- `MOCK_MR_STATE` - MR state (opened/merged/closed)
- `MOCK_MR_LABELS` - Comma-separated labels
- `MOCK_GLAB_AUTH_SUCCESS` - Auth status (true/false)

### `mock_responses.sh` - Predefined Scenarios

Helper functions to set up common test scenarios.

**Usage:**
```bash
source tests/mocks/mock_responses.sh

# Set up a WIP PR scenario
setup_wip_pr

# Set up a hotfix PR scenario
setup_hotfix_pr

# Reset all mocks
reset_mocks
```

**Available Scenarios:**
- `setup_wip_pr()` - WIP PR with [WIP] in title
- `setup_hotfix_pr()` - Hotfix PR from hotfix branch
- `setup_ticket_pr()` - PR with ticket ID in title
- `setup_dynamic_pr()` - PR with checkbox checklist
- `setup_branch_target_pr()` - PR targeting non-default branch
- `setup_labeled_pr()` - PR with existing labels
- `setup_ci_started()` - CI in started state
- `setup_ci_passed()` - CI in passed state
- `setup_ci_failed()` - CI in failed state
- `setup_wip_mr()` - GitLab WIP MR
- `setup_hotfix_mr()` - GitLab hotfix MR
- `reset_mocks()` - Reset all mock variables

## Example Test

```bash
#!/usr/bin/env bats

load '../mocks/mock_gh'
load '../mocks/mock_responses'

@test "badge generation for WIP PR" {
    # Arrange
    setup_wip_pr

    # Act
    run ./badgetizr --pr-id=123

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" =~ "WIP" ]]
}
```

## Tracking Mock Actions

Mocks track their actions in temporary directories:
- GitHub: `/tmp/mock_gh_responses/`
- GitLab: `/tmp/mock_glab_responses/`

**Files created:**
- `added_labels.txt` - Labels added to PR/MR
- `removed_labels.txt` - Labels removed from PR/MR
- `created_labels.txt` - New labels created
- `pr_body.txt` or `mr_description.txt` - Updated PR/MR description

**Cleanup:**
```bash
mock_gh_cleanup
mock_glab_cleanup
```

## Tips

1. **Always source mocks before tests run**
2. **Reset mocks between tests** using `reset_mocks()`
3. **Clean up temporary files** using cleanup functions in teardown
4. **Check tracked actions** by reading files in response directories
