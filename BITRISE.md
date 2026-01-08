# Bitrise Integration Guide

This guide provides detailed instructions for integrating Badgetizr with Bitrise CI/CD for both macOS and Linux stacks.

## Overview

Badgetizr is available as a Bitrise step that automatically installs dependencies and runs the badge generation tool on your pull/merge requests.

**Two installation methods:**
- 🏪 **Official Bitrise StepLib** (recommended) - Simple syntax, auto-updates
- 🔧 **Custom Git Step** - Direct from repository, version locked

## Quick Start

### Step 1: Add the Step

**Option A: Official StepLib (Recommended)**

```yaml
workflows:
  primary:
    steps:
      - git-clone: {}
      - badgetizr@3.0.3:
          title: Run Badgetizr
          inputs:
            - pr_id: $BITRISE_PULL_REQUEST
            - configuration: .badgetizr.yml
            - pr_destination_branch: $BITRISEIO_GIT_BRANCH_DEST
            - pr_build_number: $BITRISE_BUILD_NUMBER
            - pr_build_url: $BITRISE_BUILD_URL
            - github_token: $GITHUB_TOKEN
```

**Option B: Custom Git Step**

```yaml
workflows:
  primary:
    steps:
      - git-clone: {}
      - git::https://github.com/aiKrice/homebrew-badgetizr.git@3.0.3:
          title: Run Badgetizr
          inputs:
            - pr_id: $BITRISE_PULL_REQUEST
            - configuration: .badgetizr.yml
            - pr_destination_branch: $BITRISEIO_GIT_BRANCH_DEST
            - pr_build_number: $BITRISE_BUILD_NUMBER
            - pr_build_url: $BITRISE_BUILD_URL
            - github_token: $GITHUB_TOKEN
```

### Step 2: Configure Secrets

In your Bitrise app settings, add the required secrets:

- **GITHUB_TOKEN**: Your GitHub Personal Access Token (for GitHub PRs)
- **GITLAB_TOKEN**: Your GitLab Personal Access Token (for GitLab MRs)

## Supported Platforms

- ✅ macOS stacks
- ✅ Linux stacks

Both platforms are fully supported with automatic dependency installation.

## Input Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `pr_id` | Pull/Merge Request ID | ✅ Yes | - |
| `configuration` | Path to configuration file | No | `.badgetizr.yml` |
| `pr_destination_branch` | Target branch for the PR/MR | Conditional* | - |
| `pr_build_number` | Build number for CI badge | Conditional* | - |
| `pr_build_url` | URL to build page | Conditional* | - |
| `ci_status` | CI status (started/passed/warning/failed) | No | - |
| `ci_text` | Custom text for CI badge | No | - |
| `provider` | Force provider (github/gitlab) | No | Auto-detected |
| `github_token` | GitHub authentication token | Conditional** | - |
| `gitlab_token` | GitLab authentication token | Conditional** | - |
| `gitlab_host` | GitLab instance hostname | No | gitlab.com |
| `badgetizr_version` | Version to use | No | 3.0.3 |

\* Required depending on which badges are enabled in your configuration
\*\* At least one token is required based on your provider

## Environment Variables

The step uses the following Bitrise environment variables:

- `$BITRISE_PULL_REQUEST` - The PR/MR number
- `$BITRISEIO_GIT_BRANCH_DEST` - The target branch name
- `$BITRISE_BUILD_NUMBER` - The build number
- `$BITRISE_BUILD_URL` - The build URL
- `$BITRISE_SOURCE_DIR` - The source directory

## Examples

### GitHub Pull Requests

**Using Official StepLib:**
```yaml
- badgetizr@3.0.3:
    title: Add GitHub PR Badges
    inputs:
      - pr_id: $BITRISE_PULL_REQUEST
      - configuration: .badgetizr.yml
      - pr_destination_branch: $BITRISEIO_GIT_BRANCH_DEST
      - pr_build_number: $BITRISE_BUILD_NUMBER
      - pr_build_url: $BITRISE_BUILD_URL
      - github_token: $GITHUB_TOKEN
      - provider: github
```

**Using Custom Git Step:**
```yaml
- git::https://github.com/aiKrice/homebrew-badgetizr.git@3.0.3:
    title: Add GitHub PR Badges
    inputs:
      - pr_id: $BITRISE_PULL_REQUEST
      - configuration: .badgetizr.yml
      - pr_destination_branch: $BITRISEIO_GIT_BRANCH_DEST
      - pr_build_number: $BITRISE_BUILD_NUMBER
      - pr_build_url: $BITRISE_BUILD_URL
      - github_token: $GITHUB_TOKEN
      - provider: github
```

### GitLab Merge Requests

**Using Official StepLib:**
```yaml
- badgetizr@3.0.3:
    title: Add GitLab MR Badges
    inputs:
      - pr_id: $BITRISE_PULL_REQUEST
      - configuration: .badgetizr.yml
      - pr_destination_branch: $BITRISEIO_GIT_BRANCH_DEST
      - pr_build_number: $BITRISE_BUILD_NUMBER
      - pr_build_url: $BITRISE_BUILD_URL
      - gitlab_token: $GITLAB_TOKEN
      - provider: gitlab
```

**Using Custom Git Step:**
```yaml
- git::https://github.com/aiKrice/homebrew-badgetizr.git@3.0.3:
    title: Add GitLab MR Badges
    inputs:
      - pr_id: $BITRISE_PULL_REQUEST
      - configuration: .badgetizr.yml
      - pr_destination_branch: $BITRISEIO_GIT_BRANCH_DEST
      - pr_build_number: $BITRISE_BUILD_NUMBER
      - pr_build_url: $BITRISE_BUILD_URL
      - gitlab_token: $GITLAB_TOKEN
      - gitlab_host: gitlab.com
      - provider: gitlab
```

### Self-Managed GitLab

```yaml
- git::https://github.com/aiKrice/homebrew-badgetizr.git@3.0.3:
    title: Add GitLab MR Badges
    inputs:
      - pr_id: $BITRISE_PULL_REQUEST
      - pr_destination_branch: $BITRISEIO_GIT_BRANCH_DEST
      - pr_build_number: $BITRISE_BUILD_NUMBER
      - pr_build_url: $BITRISE_BUILD_URL
      - gitlab_token: $GITLAB_TOKEN
      - gitlab_host: gitlab.example.com
      - provider: gitlab
```

### With CI Status - Automatic Mode (Recommended)

**Best practice:** Use `ci_status: automatic` as the **final step** in your workflow to automatically detect the build status.

```yaml
workflows:
  primary:
    steps:
      - git-clone: {}
      - script:
          title: Build
          inputs:
            - content: |
                #!/bin/bash
                npm run build
      - script:
          title: Test
          inputs:
            - content: |
                #!/bin/bash
                npm test
      - badgetizr@3.0.3:
          title: Update PR Badges
          inputs:
            - pr_id: $BITRISE_PULL_REQUEST
            - pr_build_number: $BITRISE_BUILD_NUMBER
            - pr_build_url: $BITRISE_BUILD_URL
            - ci_status: automatic  # ← Automatically detects passed/failed
            - github_token: $GITHUB_TOKEN
```

**How it works:**
- ✅ **Passed (green)**: All previous steps succeeded
- ❌ **Failed (red)**: Any previous step failed
- Uses `$BITRISE_BUILD_STATUS` and `$BITRISE_PIPELINE_BUILD_STATUS`

**⚠️ Critical placement rule:**
- MUST be the **last step** in your workflow
- If placed earlier, it won't reflect the final build status
- Don't add steps after badgetizr with `automatic` mode

---

### With CI Status - Manual Mode

**Use case:** For complex workflows where you want fine-grained control or intermediate status updates.

```yaml
workflows:
  primary:
    steps:
      - git-clone: {}
      - badgetizr@3.0.3:
          title: Badges - Started
          inputs:
            - pr_id: $BITRISE_PULL_REQUEST
            - pr_build_url: $BITRISE_BUILD_URL
            - ci_status: started  # Yellow badge: build in progress
            - github_token: $GITHUB_TOKEN

      - script:
          title: Build
          inputs:
            - content: npm run build

      - script:
          title: Test
          inputs:
            - content: npm test

      - badgetizr@3.0.3:
          title: Badges - Completed
          inputs:
            - pr_id: $BITRISE_PULL_REQUEST
            - pr_build_url: $BITRISE_BUILD_URL
            - ci_status: passed  # Green badge: manually set
            - github_token: $GITHUB_TOKEN
```

**Manual status options:**
- `started` - Yellow (use at workflow start)
- `passed` - Green (success)
- `warning` - Orange (success with warnings)
- `failed` - Red (failure)

---

### Automatic vs Manual: When to Use Each

| Scenario | Recommended Mode | Why |
|----------|-----------------|-----|
| Simple linear workflow | **automatic** | Simplest, most reliable |
| Want final status only | **automatic** | One step, no manual tracking |
| Complex multi-stage pipeline | **manual** | Fine-grained control at each stage |
| Show "in progress" at start | **manual** (`started`) | User feedback during long builds |
| Custom status logic | **manual** | Full control over badge color/text |

## Configuration File

Create a `.badgetizr.yml` file in your repository root to configure which badges to display. See the main [README](README.md) for badge configuration options.

Example `.badgetizr.yml`:

```yaml
badge_wip:
  enabled: "true"
  settings:
    label: "WIP"
    color: "yellow"
    logo: "vlcmediaplayer"

badge_ci:
  enabled: "true"
  settings:
    label: "Build"
    logo: "bitrise"
    color: "purple"

badge_base_branch:
  enabled: "true"
  settings:
    base_branch: "main"
    color: "orange"
```

## How It Works

1. **Clone**: The step clones the badgetizr repository at the specified version
2. **Dependencies**: Automatically installs required tools (yq, jq, gh/glab CLI)
3. **Execute**: Runs badgetizr with your configuration
4. **Cleanup**: Removes temporary files after execution

## Platform-Specific Notes

### macOS

- Uses Homebrew for dependency installation
- Installs GitHub CLI via `brew install gh`
- Installs GitLab CLI via `brew install glab`

### Linux

- Uses direct downloads for dependency installation
- Downloads yq binary from GitHub releases
- Installs jq via apt-get
- Installs gh/glab CLIs from official sources

## Troubleshooting

### PR ID is Empty

Ensure your workflow is triggered by a pull request event. `$BITRISE_PULL_REQUEST` is only available for PR builds.

### Authentication Errors

- Verify your tokens are correctly added to Bitrise Secrets
- Check token permissions (needs read/write access to pull requests)
- For GitLab, ensure `GITLAB_HOST` is set correctly for self-managed instances

### Dependencies Not Installing

- Check build logs for permission errors
- Ensure the stack has internet access
- Verify the stack type (macOS/Linux) supports the installation method

## Icon

The Bitrise step icon should be a 256x256 PNG image. You can create one from the logo:

```bash
# Resize the existing logo.png (1024x1024) to 256x256
convert logo.png -resize 256x256 assets/icon.png
```

Or use the existing `logo.png` and Bitrise will automatically resize it.

## Support

For issues or questions:
- Open an issue: https://github.com/aiKrice/homebrew-badgetizr/issues
- See the main troubleshooting guide: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Version History

- **2.3.0** - Initial Bitrise support with macOS and Linux stacks
