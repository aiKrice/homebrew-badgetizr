# Badge Documentation

Complete guide to all badge types supported by Badgetizr.

## Table of Contents

- [Overview](#overview)
- [Configuration File](#configuration-file)
- [Available Badge Types](#available-badge-types)
  - [🎫 Ticket Badge](#-ticket-badge)
  - [⚠️ Work In Progress (WIP) Badge](#%EF%B8%8F-work-in-progress-wip-badge)
  - [🚨 Hotfix Badge](#-hotfix-badge)
  - [📊 Dynamic Badges](#-dynamic-badges)
  - [🌿 Branch Badge](#-branch-badge)
  - [🚀 CI Badge](#-ci-badge)
  - [✅ Ready for Approval Badge](#-ready-for-approval-badge)
- [Badge Styling](#badge-styling)
- [Troubleshooting](#troubleshooting)

## Overview

Badgetizr supports multiple badge types that can be enabled and customized individually. All badges support custom icons from [Simple Icons](https://simpleicons.org/) - use the icon slug from the website in your configuration.

## Configuration File

- **Default location**: `.badgetizr.yml` in your project root
- **Custom location**: Use `-c path/to/config.yml`
- **Example file**: See `.badgetizr.yml.example` in the repository

```bash
# Use default configuration
badgetizr --pr-id=123

# Use custom configuration
badgetizr -c my-config.yml --pr-id=123
```

## Available Badge Types

### 🎫 Ticket Badge

Extracts ticket IDs from PR titles and creates clickable badges linking to your ticket system.

**Status**: Disabled by default
**Example**: `feat(ABC-123): Add new feature` → ![JIRA-ABC-123](https://img.shields.io/badge/JIRA-ABC--123-blue?logo=jirasoftware)

#### Configuration

```yaml
badge_ticket:
  enabled: "true"
  settings:
    color: "blue"
    label: "JIRA"
    logo: "jirasoftware"
    sed_pattern: '.*\(([^)]+)\).*'
    url: "https://yourproject.atlassian.net/browse/%s"
```

#### Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `color` | Badge color | `blue` | No |
| `label` | Badge label text | `JIRA` | No |
| `logo` | Simple Icons slug | `jirasoftware` | No |
| `sed_pattern` | Regex to extract ticket ID (requires capture group) | `.*\(([^)]+)\).*` | No |
| `url` | URL template (`%s` replaced with ticket ID) | Atlassian URL | Yes |

#### Common Regex Patterns

**To match `[GH-123]` format:**
```yaml
sed_pattern: '.*\[GH-([0-9]+)\].*'
```

**To match `feat(GH-123):` format (conventional commits):**
```yaml
sed_pattern: '.*\(GH-([0-9]+)\):.*'
```

### ⚠️ Work In Progress (WIP) Badge

Automatically detects "WIP" in PR titles (case-insensitive) and displays a warning badge.

**Status**: Enabled by default
**Example**: `WIP: Fix bug` → ![WIP](https://img.shields.io/badge/WIP-yellow?logo=vlcmediaplayer)

#### Configuration

```yaml
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    logo: "vlcmediaplayer"
    labelized: "work in progress"  # Optional: auto-manage GitHub/GitLab labels
```

#### Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `color` | Badge color | `yellow` | No |
| `label` | Badge text | `WIP` | No |
| `logo` | Simple Icons slug | `vlcmediaplayer` | No |
| `labelized` | Auto-manage platform labels | - | No |

#### Label Management

When `labelized` is configured, automatically adds/removes the specified label on the PR:
- **WIP detected**: Badge shown + Label added
- **No WIP**: Badge hidden + Label removed
- **Missing labels**: Auto-created with appropriate colors

### 🚨 Hotfix Badge

Automatically detects when a PR targets `main` or `master` branches and displays a hotfix warning badge.

**Status**: Disabled by default
**Example**: PR to `main` → ![HOTFIX](https://img.shields.io/badge/HOTFIX-red?logoColor=white&color=red)

#### Configuration

```yaml
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
    labelized: "Hotfix"  # Optional: auto-manage GitHub/GitLab labels
```

#### Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `color` | Badge background color | `red` | No |
| `text_color` | Badge text color | `white` | No |
| `label` | Badge text | `HOTFIX` | No |
| `labelized` | Auto-manage platform labels | - | No |

#### Detection Logic

- **Automatic detection**: Badge appears when PR targets `main` or `master` branch
- **No configuration needed**: Branch detection is hardcoded for simplicity
- **Cross-platform**: Works on both GitHub and GitLab

#### Label Management

When `labelized` is configured, automatically adds/removes the specified label:
- **Hotfix detected**: Badge shown + Red label added
- **Regular PR**: Badge hidden + Label removed
- **Label color**: Always red (non-customizable for consistency)

### 📊 Dynamic Badges

Creates badges based on patterns found in PR descriptions, perfect for tracking task completion.

**Status**: Disabled by default
**Example**: `- [x] Tests added` → ![Tests-Done](https://img.shields.io/badge/Tests-Done-green)

#### Configuration

```yaml
badge_dynamic:
  enabled: "true"
  settings:
    patterns:
      - sed_pattern: "(- \\[x\\] Tests added)"
        label: "Tests"
        value: "Done"
        color: "green"
      - sed_pattern: "(- \\[ \\] Tests added)"
        label: "Tests"
        value: "Pending"
        color: "orange"
```

#### Pattern Settings

Each pattern in the `patterns` array supports:

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `sed_pattern` | Regex pattern (requires capture group) | - | Yes |
| `label` | Badge label | - | Yes |
| `value` | Badge value/status | - | Yes |
| `color` | Badge color | `grey` | No |

#### Common Use Cases

**Task Checklists**:
```yaml
patterns:
  - sed_pattern: "(- \\[x\\] Documentation updated)"
    label: "Docs"
    value: "Updated"
    color: "green"
```

**Review Status**:
```yaml
patterns:
  - sed_pattern: "(Reviewed by: @\\w+)"
    label: "Review"
    value: "Complete"
    color: "blue"
```

### 🌿 Branch Badge

Highlights when a PR targets a branch other than the configured default.

**Status**: Disabled by default
**Example**: PR to `main` → ![Target-main](https://img.shields.io/badge/Target-main-orange)

#### Configuration

```yaml
badge_base_branch:
  enabled: "true"
  settings:
    base_branch: "develop"
    color: "orange"
    label: "Target"
```

#### Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `base_branch` | Expected default branch | `develop` | No |
| `color` | Badge color | `orange` | No |
| `label` | Badge label | `Target` | No |

#### Requirements

- **CLI Parameter**: `--pr-destination-branch` (required when enabled)
- **Behavior**: Only shows badge when target branch differs from `base_branch`

### 🚀 CI Badge

Displays CI status and build information with direct links to CI pipeline runs. Supports both static builds and dynamic status updates during pipeline execution.

**Status**: Disabled by default
**Example**: ![Build-456](https://img.shields.io/badge/456-ignored?label=Build&color=darkgreen&logo=github)

#### Configuration

```yaml
badge_ci:
  enabled: "true"
  settings:
    label_color: "black"
    label: "Build"
    logo: "github"
    color: "darkgreen"  # Used for static builds when no status provided
```

#### Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `color` | Badge color for static builds | `purple` | No |
| `label_color` | Label background color | `black` | No |
| `label` | Badge label text | `CI` | No |
| `logo` | Simple Icons slug | `github` | No |

#### CLI Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `--pr-build-url` | Build URL (badge is always clickable) | Yes |
| `--pr-build-number` | Build number (for static or passed/failed) | No |
| `--ci-status` | Status: `started`, `passed`, `warning`, `failed` | No |
| `--ci-text` | Custom text for badge | No |

#### Usage Examples

##### Command Line Usage

```bash
# Static build badge (shows build number)
badgetizr --pr-id=123 \
  --pr-build-number=456 \
  --pr-build-url="https://ci.example.com/builds/456"

# CI status with custom text (intermediate steps)
badgetizr --pr-id=123 \
  --ci-status=started \
  --ci-text="Installing Dependencies" \
  --pr-build-url="https://ci.example.com/builds/456"

# CI final status with build number
badgetizr --pr-id=123 \
  --ci-status=passed \
  --pr-build-number=456 \
  --pr-build-url="https://ci.example.com/builds/456"

# CI final status with custom text (no build number)
badgetizr --pr-id=123 \
  --ci-status=failed \
  --ci-text="Tests Failed" \
  --pr-build-url="https://ci.example.com/builds/456"
```

##### GitHub Actions Workflow

```yaml
name: CI Pipeline with Status Updates

on: [pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      # CI Started
      - name: Update CI Status - Started
        uses: aiKrice/homebrew-badgetizr@latest
        with:
          pr_id: ${{ github.event.pull_request.number }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          ci_status: "started"
          ci_text: "Installing Dependencies"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Build steps
      - name: Install Dependencies
        run: npm install

      # Update status during tests
      - name: Update CI Status - Testing
        uses: aiKrice/homebrew-badgetizr@latest
        with:
          pr_id: ${{ github.event.pull_request.number }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          ci_status: "started"
          ci_text: "Running Tests"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Run Tests
        run: npm test

      # Final status with build number
      - name: CI Success
        if: success()
        uses: aiKrice/homebrew-badgetizr@latest
        with:
          pr_id: ${{ github.event.pull_request.number }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          pr_build_number: ${{ github.run_id }}
          ci_status: "passed"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: CI Failed
        if: failure()
        uses: aiKrice/homebrew-badgetizr@latest
        with:
          pr_id: ${{ github.event.pull_request.number }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          pr_build_number: ${{ github.run_id }}
          ci_status: "failed"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Status Colors

- `started` → ![yellow](https://img.shields.io/badge/status-yellow-yellow)
- `passed` → ![darkgreen](https://img.shields.io/badge/status-darkgreen-darkgreen)
- `warning` → ![orange](https://img.shields.io/badge/status-orange-orange)
- `failed` → ![red](https://img.shields.io/badge/status-red-red)

#### Badge Behavior

**Text Display Logic:**
- **started/warning**: Uses `--ci-text` if provided, otherwise status name
- **passed/failed**: Uses `--pr-build-number` if provided, otherwise `--ci-text`, otherwise status name
- **Static mode**: Uses `--pr-build-number` (required) with configured color

**Badge is always clickable** and links to `--pr-build-url`

### ✅ Ready for Approval Badge

Automatically tracks checkbox completion status in PR descriptions and displays a badge when all checkboxes are completed. Also manages labels accordingly.

**Status**: Disabled by default
**Example**: When all checkboxes are checked → ![Ready](https://img.shields.io/badge/Ready-green?logo=checkmark) + Label "Ready for Approval" is added

#### Configuration

```yaml
badge_ready_for_approval:
  enabled: "true"
  settings:
    color: "green"
    label: "Ready"
    logo: "checkmark"
    labelized: "Ready for Approval"  # Optional: auto-manage GitHub/GitLab labels
```

#### Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `color` | Badge color | `green` | No |
| `label` | Badge text | `Ready` | No |
| `logo` | Simple Icons slug | `checkmark` | No |
| `labelized` | Auto-manage platform labels | - | No |

#### Detection Logic

- **Scans PR body** for checkbox patterns: `- [ ]` (unchecked) and `- [x]` (checked)
- **All checkboxes checked**: Badge displayed + Label added (green color)
- **Unchecked checkboxes exist**: Badge hidden + Label removed
- **No configuration needed**: Checkbox detection is automatic

#### Label Management

When `labelized` is configured, automatically adds/removes the specified label:
- **All checkboxes completed**: Label added with green color
- **Pending checkboxes**: Label removed
- **Missing labels**: Auto-created with green color and appropriate description

#### Use Cases

**Task Completion Tracking**:
```markdown
## Checklist
- [x] Code reviewed
- [ ] Tests added
- [x] Documentation updated
```
Result: Label "Ready for Approval" removed (1 unchecked item)

**Ready for Review**:
```markdown
## Checklist
- [x] Code reviewed
- [x] Tests added
- [x] Documentation updated
```
Result: Label "Ready for Approval" added (all items completed)