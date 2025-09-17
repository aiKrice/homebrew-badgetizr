# Badge Documentation

Complete guide to all badge types supported by Badgetizr.

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

Displays build information and provides direct links to CI pipeline runs.

**Status**: Disabled by default
**Example**: ![CI-Build-123](https://img.shields.io/badge/CI-Build%20123-purple?logo=github)

#### Configuration

```yaml
badge_ci:
  enabled: "true"
  settings:
    color: "purple"
    label: "CI"
    logo: "github"
```

#### Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `color` | Badge color | `purple` | No |
| `label` | Badge text | `CI` | No |
| `logo` | Simple Icons slug | `bitrise` | No |

#### Requirements

- **CLI Parameter**: `--pr-build-number` (required when enabled)
- **CLI Parameter**: `--pr-build-url` (required when enabled)
- **Behavior**: Badge links directly to the CI run URL