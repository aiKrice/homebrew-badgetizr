<h1 align="center">
    <img src="logo.png" alt="Badgetizr Logo" width="150"/>
    <br/>
    Badgetizr

![Static Badge](https://img.shields.io/badge/3.0.3-grey?logo=homebrew&logoColor=white&label=Homebrew-tap&labelColor=darkgreen)
[![Static Badge](https://img.shields.io/badge/3.0.3-grey?logo=github&logoColor=white&label=Github-Action&labelColor=black)](https://github.com/marketplace/actions/badgetizr)
[![Static Badge](https://img.shields.io/badge/3.0.3-pink?logo=gitlab&logoColor=orange&label=Gitlab&labelColor=white)](https://gitlab.com/chris-saez/badgetizr-integration)
![Static Badge](https://img.shields.io/badge/3.0.3-grey?logo=bitrise&logoColor=white&label=Bitrise&labelColor=purple)
[![codecov](https://codecov.io/gh/aiKrice/homebrew-badgetizr/graph/badge.svg?token=4NSN7QGO0E)](https://codecov.io/gh/aiKrice/homebrew-badgetizr)
</h1>

<h2 align="center">
    Add badges to your pull requests and increase your productivity 🚀.
</h2>

<div id="header" align="center">
  <img src="badgetizr.gif" width="800"/>
</div>

---

## Table of Contents

- [What is Badgetizr?](#what-is-badgetizr)
- [Multi-Platform Support](#multi-platform-support)
- [Installation](#installation)
  - [CI/CD Integration (Automated)](#cicd-integration-automated)
    - [GitHub Actions](#github-actions)
    - [GitLab CI](#gitlab-ci)
    - [Bitrise CI](#bitrise-ci)
  - [Manual Installation](#manual-installation)
    - [Homebrew (macOS/Linux)](#homebrew-macoslinux)
    - [Direct Installation (macOS/Linux)](#direct-installation-macoslinux)
- [Usage](#usage)
  - [Command Line Options](#command-line-options)
  - [Basic Examples](#basic-examples)
  - [Provider Detection](#provider-detection)
- [Configuration](#configuration)
- [Badges](#badges)
- [Contributing](#contributing)
- [Publishing (for maintainers)](#publishing-for-maintainers)
- [Troubleshooting](#troubleshooting)
- [Support the Project](#support-the-project)

---

## What is Badgetizr?

Badgetizr automatically adds customizable badges to your GitHub and GitLab pull/merge requests to boost team productivity. With support for multiple badge types and full CI/CD integration, it helps teams:

- 🎯 **Track ticket references** automatically from PR titles
- ⚠️ **Identify work-in-progress** pull requests clearly
- 📊 **Monitor CI/CD status** without clicking through pipelines
- ✅ **Visualize completion status** of checklists and tasks
- 🎯 **Highlight target branches** for better merge awareness

## Multi-Platform Support

✅ **GitHub** - Full support via GitHub CLI
✅ **GitLab** - Full support via GitLab CLI
✅ **GitHub Actions** - Native integration
✅ **GitLab CI** - Native integration
✅ **Bitrise CI** - Custom step for macOS and Linux

## Installation

### CI/CD Integration (Automated)

#### GitHub Actions

Add this to your workflow (`.github/workflows/*.yml`):

```yaml
jobs:
  badgetizr:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Run Badgetizr
        uses: aiKrice/homebrew-badgetizr@3.0.3
        with:
          pr_id: ${{ github.event.pull_request.number }}
          configuration: .badgetizr.yml
          pr_destination_branch: ${{ github.event.pull_request.base.ref }}
          pr_build_number: ${{ github.run_id }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### GitLab CI

Add this to your `.gitlab-ci.yml`:

**Live example**: [badgetizr-integration GitLab project](https://gitlab.com/chris-saez/badgetizr-integration)

**Works for both GitLab.com and self-managed instances:**

```yaml
badgetizr:
  stage: build
  image: alpine:latest
  variables:
    BADGETIZR_VERSION: "3.0.3"
    GLAB_VERSION: "1.78.3"
    # Auto-detects: gitlab.com for SaaS, your instance for self-managed
    GITLAB_HOST: "${CI_SERVER_HOST}"
    BUILD_URL: "https://${CI_SERVER_HOST}/${CI_PROJECT_PATH}/-/pipelines/${CI_PIPELINE_ID}"
    CONFIG_PATH: "../.badgetizr.yml"
    GITLAB_TOKEN: $GITLAB_ACCESS_TOKEN
  before_script:
    - apk add --no-cache curl bash yq
    - curl -sSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp
    - mv /tmp/bin/glab /usr/local/bin/glab && chmod +x /usr/local/bin/glab
    - curl -sSL https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/${BADGETIZR_VERSION}.tar.gz | tar -xz
    - cd homebrew-badgetizr-*
    - export GITLAB_HOST="${CI_SERVER_HOST}"
  script:
    - |
      ./badgetizr -c ${CONFIG_PATH} \
      --pr-id=$CI_MERGE_REQUEST_IID \
      --pr-destination-branch=$CI_MERGE_REQUEST_TARGET_BRANCH_NAME \
      --pr-build-number=$CI_PIPELINE_ID \
      --pr-build-url=${BUILD_URL} \
      --provider=gitlab
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

**Key features:**
- ✅ **Universal**: Works for GitLab.com and self-managed instances automatically
- ✅ **Centralized variables**: Easy to update versions and paths
- ✅ **Auto-detection**: `CI_SERVER_HOST` adapts to your environment
- ✅ **Customizable**: Modify variables at the top for your setup

**For custom ports or URLs**: Replace `BUILD_URL` with your specific format (e.g., using `$CI_SERVER_PORT` or `$CI_SERVER_URL`)

#### Bitrise CI

Add the Badgetizr step to your Bitrise workflow. Works on both macOS and Linux stacks.

**📚 Complete Documentation**: See [BITRISE.md](BITRISE.md) for detailed setup instructions, troubleshooting, and advanced configuration.

**Quick Setup (Official StepLib - Recommended):**

```yaml
workflows:
  primary:
    steps:
      - git-clone: {}
      - badgetizr@3.0.3:
          title: Run Badgetizr
          inputs:
            - pr_id: $BITRISE_PULL_REQUEST
            - pr_build_url: $BITRISE_BUILD_URL
            - github_token: $GITHUB_TOKEN
```

**Alternative (Custom Git Step):**

```yaml
workflows:
  primary:
    steps:
      - git-clone: {}
      - git::https://github.com/aiKrice/homebrew-badgetizr.git@3.0.3:
          title: Run Badgetizr
          inputs:
            - pr_id: $BITRISE_PULL_REQUEST
            - pr_build_url: $BITRISE_BUILD_URL
            - github_token: $GITHUB_TOKEN
```

**Configure secrets in Bitrise:**
- Add `GITHUB_TOKEN` (for GitHub PRs) or `GITLAB_TOKEN` (for GitLab MRs) to your Bitrise Secrets

---

### Manual Installation

#### Homebrew (macOS/Linux)

```bash
# Add the tap and install
brew tap aiKrice/badgetizr
brew install aiKrice/badgetizr/badgetizr

# Configure authentication
export GITHUB_TOKEN="your_github_token"     # For GitHub
export GITLAB_TOKEN="your_gitlab_token"     # For GitLab
export GITLAB_HOST="gitlab.example.com"     # For self-managed GitLab (optional)
```

#### Direct Installation (macOS/Linux)

For systems without Homebrew or for development purposes:

```bash
# Download latest release
TAG=$(curl -s https://api.github.com/repos/aiKrice/homebrew-badgetizr/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -L -o badgetizr-latest.tar.gz "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/$TAG.tar.gz"
tar -xz --strip-components=1 -f badgetizr-latest.tar.gz

# Install runtime dependencies (gh/glab, yq)
./configure

# For contributors: install development tools (shellcheck, shfmt, bats, kcov)
./configure --contributor

# Configure authentication
export GITHUB_TOKEN="your_github_token"     # For GitHub
export GITLAB_TOKEN="your_gitlab_token"     # For GitLab
export GITLAB_HOST="gitlab.example.com"     # For self-managed GitLab (optional)
```

## Usage

### Command Line Options

```bash
badgetizr [options]
```

#### Required Options

| Option | Description |
|--------|-------------|
| `--pr-id <id>` | Specify the pull/merge request ID |

#### Optional Options

| Option | Description | Default |
|--------|-------------|---------|
| `-c <file>`, `--configuration <file>` | Path to configuration file | `.badgetizr.yml` |
| `--pr-destination-branch <branch>` | Target branch (required for branch badge) | - |
| `--pr-build-number <number>` | Build number (for passed/failed statuses or static builds) | - |
| `--pr-build-url <url>` | Build URL (required for CI badge) | - |
| `--ci-status <status>` | CI status: `started`, `passed`, `warning`, `failed` | - |
| `--ci-text <text>` | Custom text for CI badge | - |
| `--provider <provider>` | Force provider (`github` or `gitlab`) | Auto-detected |
| `-v`, `--version` | Display version | - |
| `-h`, `--help` | Display help | - |

### Basic Examples

```bash
# Minimal usage (auto-detects GitHub/GitLab)
badgetizr --pr-id=123

# With custom configuration
badgetizr -c custom.yml --pr-id=123

# Force specific provider
badgetizr --provider=gitlab --pr-id=123

# Complete example with all options
badgetizr \
  --pr-id=123 \
  --pr-destination-branch=main \
  --pr-build-number=456 \
  --pr-build-url="https://github.com/owner/repo/actions/runs/456" \
  --provider=github
```

### Provider Detection

Badgetizr automatically detects your platform:

- **GitHub**: Uses `gh` CLI with `GITHUB_TOKEN` or `GH_TOKEN`
- **GitLab**: Uses `glab` CLI with `GITLAB_TOKEN`
  - For self-managed GitLab: Set `GITLAB_HOST` environment variable
- **Auto-detection**: Based on `git remote get-url origin`
- **Manual override**: Use `--provider=github` or `--provider=gitlab`

## Configuration

Badgetizr uses a YAML configuration file to define which badges to display and their settings.

### Configuration File

- **Default location**: `.badgetizr.yml` in your project root
- **Custom location**: Use `-c path/to/config.yml`
- **Example file**: See `.badgetizr.yml.example` in the repository

```bash
# Use default configuration
badgetizr --pr-id=123

# Use custom configuration
badgetizr -c my-config.yml --pr-id=123
```

## Badges

Badgetizr supports multiple badge types that can be customized to track different aspects of your pull requests.

📖 **[Complete Badge Documentation](BADGES.md)**

### Quick Overview

| Badge Type | Default Status | Purpose | Preview | Labelized |
|-----------|----------------|---------|---------|-----------|
| 🎫 **Ticket** | Disabled | Links to ticket systems (Jira, GitHub Issues, etc.) | ![JIRA-ABC-123](https://img.shields.io/badge/JIRA-ABC--123-blue?logo=jirasoftware) | - |
| ⚠️ **WIP** | Enabled | Identifies work-in-progress pull requests | ![WIP](https://img.shields.io/badge/WIP-yellow?logo=vlcmediaplayer) | ✅ |
| 🚨 **Hotfix** | Disabled | Automatically detects PRs targeting main/master | ![HOTFIX](https://img.shields.io/badge/HOTFIX-red?logoColor=white&color=red) | ✅ |
| 📊 **Dynamic** | Disabled | Tracks checklist completion and custom patterns | ![Tests-Done](https://img.shields.io/badge/Tests-Done-darkgreen) | - |
| 🌿 **Branch** | Disabled | Highlights non-standard target branches | ![Target-main](https://img.shields.io/badge/Target-main-orange) | - |
| 🚀 **CI** | Disabled | Shows CI status and build info with clickable links | ![Build-456](https://img.shields.io/badge/456-ignored?label=Build&color=darkgreen&logo=github) | - |
| ✅ **Ready for Approval** | Disabled | Shows badge when all checkboxes are completed | ![Ready](https://img.shields.io/badge/Ready-darkgreen?logo=checkmark) | ✅ |

### Configuration

Badgetizr uses a YAML configuration file to define badge settings:

- **Default location**: `.badgetizr.yml` in your project root
- **Custom location**: Use `-c path/to/config.yml`
- **Icons**: All badges support icons from [Simple Icons](https://simpleicons.org/)

#### Multiple Configurations

Badgetizr supports different configuration files for different contexts:

```bash
# Feature development
badgetizr -c .badgetizr-feature.yml --pr-id=123

# Hotfix releases
badgetizr -c .badgetizr-hotfix.yml --pr-id=124

# Release candidates
badgetizr -c .badgetizr-release.yml --pr-id=125
```

**Example configurations:**

**`.badgetizr-hotfix.yml`** - Minimal badges for urgent fixes:
```yaml
badge_wip:
  enabled: "true"
badge_base_branch:
  enabled: "true"  # Show target branch clearly
  settings:
    base_branch: "main"
    color: "red"
    label: "HOTFIX"
# Other badges disabled for speed
```

**`.badgetizr-release.yml`** - Full validation for releases:
```yaml
badge_wip:
  enabled: "true"
badge_dynamic:
  enabled: "true"
  settings:
    patterns:
      - sed_pattern: "(- \\[x\\] Changelog updated)"
        label: "Changelog"
        value: "Updated"
        color: "green"
      - sed_pattern: "(- \\[x\\] Version bumped)"
        label: "Version"
        value: "Bumped"
        color: "blue"
      - sed_pattern: "(- \\[x\\] Tests passing)"
        label: "Tests"
        value: "Passing"
        color: "green"
```

**`.badgetizr-feature.yml`** - Standard development workflow:
```yaml
badge_wip:
  enabled: "true"
badge_ticket:
  enabled: "true"
  settings:
    sed_pattern: '.*\[FEAT-([0-9]+)\].*'
    label: "Feature"
    url: "https://yourproject.atlassian.net/browse/FEAT-%s"
badge_dynamic:
  enabled: "true"
  settings:
    patterns:
      - sed_pattern: "(- \\[x\\] Unit tests added)"
        label: "Tests"
        value: "Added"
        color: "green"
```

## Contributing

We welcome contributions to Badgetizr! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

🤝 **[Complete Contributing Guide](CONTRIBUTING.md)**

### Quick Start

| Step | Action | Command |
|------|--------|---------|
| 1️⃣ **Fork & Clone** | Fork the repository and clone locally | `git clone https://github.com/your-username/homebrew-badgetizr.git` |
| 2️⃣ **Setup** | Install dependencies and configure tokens | `./configure && export GITHUB_TOKEN="..."` |
| 3️⃣ **Test** | Test your changes with real PRs | `./badgetizr --pr-id=123` |
| 4️⃣ **PR Rule** | Run Badgetizr on your own PR | `./badgetizr --pr-id=YOUR_PR_NUMBER` |

### Contributing Areas

- 🐛 **Bug Fixes**: Authentication, badge rendering, configuration parsing
- ✨ **New Features**: Additional badge types, CI/CD platform support
- 📚 **Documentation**: README improvements, troubleshooting guides
- 🧪 **Testing**: Unit tests, integration tests, cross-platform compatibility

### Running Tests

Badgetizr includes a comprehensive test suite using [bats-core](https://github.com/bats-core/bats-core).

**Install bats-core:**
```bash
# Homebrew
brew install bats-core

# npm
npm install -g bats
```

**Run all tests:**
```bash
./run_tests.sh
```

**Run specific test file:**
```bash
bats tests/test_utils.bats
```

**Test with Homebrew:**
```bash
brew test badgetizr
```

📖 **[Complete Test Documentation](tests/README.md)**

## Publishing (for maintainers)

Automated release process for maintainers to publish new versions of Badgetizr.

📦 **[Complete Publishing Guide](PUBLISHING.md)**

### Quick Release

| Step | Action | Command |
|------|--------|---------|
| 1️⃣ **Prerequisites** | Clean develop branch + GitHub token | `git status && export GITHUB_TOKEN="..."` |
| 2️⃣ **Release** | Run automated publish script | `./publish.sh 1.5.6` |
| 3️⃣ **Verify** | Check release and Homebrew formula | `brew install aiKrice/badgetizr/badgetizr` |

### What It Does

- ✅ **Version Updates**: Updates version in all files and documentation
- ✅ **Branch Management**: Handles develop → master → tag → release flow
- ✅ **Homebrew Formula**: Calculates SHA256 and updates formula automatically
- ✅ **Cleanup**: Backmerges to develop and cleans temporary files

## Troubleshooting

Having issues? Check our comprehensive troubleshooting guide.

🔧 **[Complete Troubleshooting Guide](TROUBLESHOOTING.md)**

### Quick Help

**Authentication issues**:
- GitHub: `gh auth login` or set `GITHUB_TOKEN`
- GitLab: `glab auth login` or set `GITLAB_TOKEN`

**No badges showing**: Check configuration file and PR content matches badge criteria

**Command not found**: Install via Homebrew or run `./configure` for dependencies

## Support the Project

If Badgetizr has helped improve your team's productivity and you'd like to support its continued development, consider buying me a coffee! ☕

<div align="center">
  <a href='https://ko-fi.com/Q5Q7PPTYK' target='_blank'>
    <img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' />
  </a>
</div>

Your support helps maintain and improve Badgetizr for the community. Thank you! 🙏