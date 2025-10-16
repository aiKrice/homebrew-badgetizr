# Bitrise Integration Guide

This guide provides detailed instructions for integrating Badgetizr with Bitrise CI/CD for both macOS and Linux stacks.

## Overview

Badgetizr is available as a custom Bitrise step that automatically installs dependencies and runs the badge generation tool on your pull/merge requests.

## Quick Start

### Step 1: Add the Custom Step

Add the Badgetizr custom step to your `bitrise.yml` workflow:

```yaml
workflows:
  primary:
    steps:
      - git-clone: {}
      - git::https://github.com/aiKrice/homebrew-badgetizr.git@2.3.0:
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
| `badgetizr_version` | Version to use | No | 2.3.0 |

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

```yaml
- git::https://github.com/aiKrice/homebrew-badgetizr.git@2.3.0:
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

```yaml
- git::https://github.com/aiKrice/homebrew-badgetizr.git@2.3.0:
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
- git::https://github.com/aiKrice/homebrew-badgetizr.git@2.3.0:
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

### With CI Status

```yaml
- git::https://github.com/aiKrice/homebrew-badgetizr.git@2.3.0:
    title: Add Badges - Started
    inputs:
      - pr_id: $BITRISE_PULL_REQUEST
      - pr_build_url: $BITRISE_BUILD_URL
      - ci_status: started
      - github_token: $GITHUB_TOKEN

# ... your build steps ...

- git::https://github.com/aiKrice/homebrew-badgetizr.git@2.3.0:
    title: Add Badges - Passed
    inputs:
      - pr_id: $BITRISE_PULL_REQUEST
      - pr_build_url: $BITRISE_BUILD_URL
      - ci_status: passed
      - github_token: $GITHUB_TOKEN
```

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
