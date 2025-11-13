# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Badgetizr is a tool that automatically adds customizable badges to GitHub pull requests to increase team productivity. It's distributed as both a Homebrew tap and a GitHub Action.

## Core Architecture

### Main Components
- `badgetizr` - Main bash script that orchestrates badge creation
- `utils.sh` - Helper functions and utilities (defines version, help text)
- `.badgetizr.yml` - Configuration file defining badge types and settings
- `action.yml` - GitHub Action configuration for CI/CD integration
- `Formula/badgetizr.rb` - Homebrew formula for package distribution

### Badge Types Supported
1. **Ticket Badge** - Extracts and links ticket IDs from PR titles using regex patterns
2. **WIP Badge** - Shows when PR title contains "WIP"
3. **Base Branch Badge** - Displays target branch information
4. **CI Badge** - Shows build status with configurable build numbers and URLs
5. **Dynamic Badge** - Custom badges based on PR body content patterns (e.g., task checklists)

### Configuration System
- Uses YAML configuration files (`.badgetizr.yml` by default)
- Each badge type has `enabled` flag and customizable `settings`
- Supports regex pattern matching with `sed_pattern` for dynamic content extraction
- Badge appearance customizable: color, label, logo (from simpleicons.org), URLs

## Common Development Commands

### Running Badgetizr
```bash
# Basic usage with default config
./badgetizr --pr-id=123

# With custom configuration
./badgetizr -c custom.yml --pr-id=123

# With CI integration parameters
./badgetizr --pr-id=123 --pr-destination-branch=master --pr-build-number=456 --pr-build-url="https://..."

# Show version
./badgetizr -v

# Show help
./badgetizr -h
```

### Development Setup
```bash
# Install dependencies (done by configure script)
./configure

# Test locally (requires GITHUB_TOKEN)
export GITHUB_TOKEN="your_token"
./badgetizr --pr-id=123
```

### Publishing (Maintainers Only)
```bash
# Automated release process - updates version everywhere
./publish.sh 1.5.5
```

### Creating Pull Requests (Claude and Contributors)

**IMPORTANT**: When creating pull requests, always use the PR template located at `.github/pull_request_template.md`.

#### For Claude Code (GitHub Workflow)
When Claude creates a PR from an issue, it MUST:
1. Read the PR template: `.github/pull_request_template.md`
2. Use the template structure for the PR body
3. Fill in the checklist items appropriately
4. Include the GitHub Issue ID in the PR title: `[GH-XXX] Clear description`
5. If testing on GitLab was done, include the MR link in the "GitLab Testing" section

Example PR body structure:
```markdown
## Comments
- [Brief description of changes]

## Checklist
- [x] The PR starts by `[GH-43] Add integration tests`
- [ ] I have added WIP to my PR title if needed
- [ ] I have tested on GitLab and added the MR link below

## GitLab Testing
**GitLab MR Link**: [Link if applicable]
```

#### For Manual Contributions
- Always create a feature branch: `feat/GH-XXX_description`
- Use the PR template when creating the PR
- Reference the related issue in the PR title
- Test on both GitHub and GitLab when possible

## Dependencies

### Required Tools
- `gh` (GitHub CLI) - for PR interaction
- `yq` - for YAML configuration parsing
- Standard bash utilities: `sed`, `curl`, `awk`

### Installation Handled By
- **GitHub Action**: Automatically installs via `action.yml` steps
- **Homebrew**: Dependencies declared in `Formula/badgetizr.rb`
- **Manual**: Run `./configure` script

## Key Integration Points

### GitHub Action Usage
```yaml
- name: Run Badgetizr
  uses: aiKrice/homebrew-badgetizr@1.5.4
  with:
    pr_id: ${{ github.event.pull_request.number }}
    configuration: .badgetizr.yml
    pr_destination_branch: ${{ github.event.pull_request.base.ref }}
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Homebrew Distribution
- Formula located in `Formula/badgetizr.rb`
- Installs symlink from `libexec/badgetizr` to `bin/badgetizr`
- SHA256 checksum required for tarball verification

## Release Process

The `publish.sh` script automates:
1. Version bumping in `utils.sh`, `README.md`, workflow files
2. Git branch management (develop → master)
3. GitHub release creation with auto-generated notes
4. Homebrew formula SHA256 calculation and update
5. Automatic backmerge to develop branch

## Environment Variables

- `GITHUB_TOKEN` or `GH_TOKEN` - Required for GitHub API access
- Configuration passed via command-line arguments to the main script

## Recent Development Notes

### Homebrew Formula Fix (Fixed in v1.5.5)
- **Problem**: `badgetizr` script couldn't find `utils.sh` after Homebrew installation
- **Root Cause**: Homebrew was creating a symlink without setting `UTILS_PATH` environment variable
- **Solution**: Modified `Formula/badgetizr.rb` to use `write_env_script` instead of `install_symlink`
```ruby
# Before (broken)
bin.install_symlink libexec/"badgetizr"

# After (working)
(bin/"badgetizr").write_env_script libexec/"badgetizr", UTILS_PATH: libexec/"utils.sh"
```

### WIP Badge Labelized Feature (Added in v1.6.0)
- **Feature**: Automatically add/remove GitHub labels when WIP badges are shown/hidden
- **Implementation**:
  - New functions in `utils.sh`: `add_label_to_pull_request()` and `remove_label_from_pull_request()`
  - New config field: `badge_wip.settings.labelized` (optional)
  - Behavior:
    - PR title contains "WIP" → Badge shown + Label added
    - PR title without "WIP" → Badge hidden + Label removed
    - Missing labels are auto-created with appropriate colors
- **Usage**: Add `labelized: "work in progress"` to WIP badge config

### GitHub Action vs Homebrew Dependencies
- **GitHub Action**: Uses native package managers (`apt-get` for Linux, `brew` for macOS)
- **Homebrew Formula**: Uses `depends_on "gh"` and `depends_on "yq"`
- **Reasoning**: GitHub Actions need portability across runners (ubuntu-latest, macos-latest), while Homebrew formula only needs to work with Homebrew ecosystem

### Project Structure Insights
- **Branch Strategy**: `develop` for development, `master` for releases
- **Release Process**: Must be done in sequence (tag → archive → SHA256 → formula update) due to GitHub's archive generation
- **Badge Processing**: All badges collected in `all_badges` variable, then wrapped in `<!--begin:badgetizr-->` comments
- **Configuration**: Uses `yq` for YAML parsing with fallback defaults (e.g., `// "yellow"`)

### Key Functions Location
- **Badge logic**: In main `badgetizr` script (lines 140-220 approx)
- **Utility functions**: In `utils.sh` (help, version, label management)
- **GitHub API calls**: Uses `gh pr edit` and `gh pr view` commands
- **Pattern matching**: Uses `sed -n -E` for regex extraction

### Common Pitfalls to Avoid
- **Never use Homebrew in GitHub Actions** for Linux compatibility
- **Always test both badge creation and removal** for labelized features
- **SHA256 must be calculated after tag creation** - cannot be done in one step
- **Badge regex patterns must include capture groups** `()` for extraction
- **Color mapping**: Badge colors → GitHub label hex colors handled in utility functions

### Version Management
- Version stored in `utils.sh` as `BADGETIZR_VERSION`
- `publish.sh` automatically updates version in: `utils.sh`, `README.md`, `action.yml`, `Formula/badgetizr.rb`
- GitHub Action version should match latest release tag

## Future Enhancement Ideas

### 🚀 Core Improvements

#### 1. Dynamic CI Badge Status
Currently the CI badge is static. Could be made truly dynamic:
- ✅ Success (green)
- ❌ Failed (red)
- 🟡 Running (orange)
- ⏸️ Pending (gray)

**Implementation**: Query CI API status and update badge color accordingly.

#### 2. Review Status Badge
Track code review progress:
- 👀 Needs review
- ✅ Approved
- 🔄 Changes requested
- 📝 Review in progress

**Implementation**: Parse PR/MR review data from GitHub/GitLab APIs.

#### 3. Code Coverage Badge
Integration with coverage tools like CodeCov:
- 📊 Coverage: 85%
- 🎯 Coverage increase: +3%

**Implementation**: API integration with coverage services.

### 🔧 UX Improvements

#### 4. Global Configuration
Replace per-project `.badgetizr.yml` with:
- User/organization-level configuration
- Reusable badge templates
- Inheritance hierarchy (global → org → project)

#### 5. Webhook Integration
Replace manual CI triggering with:
- GitHub/GitLab webhook endpoints
- Automatic badge updates on PR/MR events
- Real-time badge synchronization

#### 6. PR Size Badge
Automatic categorization based on diff size:
- 🐭 Small (< 100 lines)
- 🐘 Large (> 500 lines)
- 🦣 Huge (> 1000 lines)

**Implementation**: Parse `git diff --stat` or use provider APIs.

### 💡 Creative Features

#### 7. Hotfix Detection Badge
Automatic detection of hotfix PRs:
- 🚨 Hotfix (when branch comes from `main`/`master`)
- 🔥 Emergency (based on keywords)

**Implementation**: Branch analysis and keyword detection.

#### 8. Dependencies Badge
Security and maintenance awareness:
- 🔒 Security updates available
- 📦 Dependencies up to date
- ⚠️ Vulnerabilities detected

**Implementation**: Integration with dependency scanners (Dependabot, Snyk, etc.).

#### 9. Team Badge
Show team ownership:
- 👥 Team: Frontend
- 🏗️ Team: Platform
- 🔐 Team: Security

**Implementation**: CODEOWNERS file parsing or team assignment APIs.

### 🎯 Most Impactful Next Steps
1. **Dynamic CI Badge** - High impact, moderate complexity
2. **Review Status Badge** - High value for team productivity
3. **PR Size Badge** - Simple implementation, immediate value
4. **Webhook Integration** - Reduces friction significantly

## Recent Major Updates (v2.0.0)

### GitLab Support Implementation (Added in v2.0.0)
- **Feature**: Complete GitLab support with provider pattern architecture
- **Implementation**:
  - New `providers/` directory with modular provider system
  - `providers/gitlab.sh` with full GitLab CLI (`glab`) integration
  - `providers/github.sh` maintaining GitHub CLI (`gh`) functionality
  - `providers/provider_utils.sh` for common interface and auto-detection
  - Provider detection based on `git remote get-url origin`
- **Authentication**: Support for multiple GitLab token variables (`GITLAB_TOKEN`, `GITLAB_ACCESS_TOKEN`, `GL_TOKEN`)
- **Label Management**: Full GitLab label CRUD operations with space handling
- **CLI Validation**: Automatic check for required CLI tools (`gh`/`glab`) with helpful error messages

### Documentation Complete Restructure (v2.0.0)
- **Modular Documentation**: Split into separate focused files:
  - `BADGES.md` - Complete badge documentation with examples
  - `TROUBLESHOOTING.md` - Comprehensive troubleshooting guide
  - `CONTRIBUTING.md` - Detailed contribution guidelines
  - `PUBLISHING.md` - Maintainer release documentation
- **README.md Improvements**:
  - Table of contents with navigation links
  - Overview sections with links to detailed guides
  - Visual badge previews in quick reference tables
  - Support section with Ko-fi integration
- **Installation Documentation**: Clear instructions for all platforms (Homebrew, GitHub Actions, GitLab CI, Manual)
- **Usage Examples**: Platform-specific examples with live project references

### Enhanced Configuration System (v2.0.0)
- **Improved configure script**: Intelligent platform detection with helpful next-step suggestions
- **Updated example config**: `.badgetizr.yml.example` with default values and comprehensive comments
- **Homebrew Formula**: Added `glab` dependency for complete out-of-the-box experience

### Release Automation Improvements (v2.0.0)
- **publish.sh updates**: Now handles all new documentation files automatically
- **Version management**: Automated updates across README badges, GitLab CI examples, and all docs
- **Global sed patterns**: Fixed GitLab CI version references with global flag

## Testing Infrastructure ✅ COMPLETED (v2.4.0)

The project now has comprehensive test coverage with **110 tests (100% passing)**:

**Test Structure**:
- `tests/unit/` - Unit tests for utilities and badge logic (26 tests)
- `tests/integration/` - Integration tests for badges, providers, and labels (84 tests)
- `tests/helpers/` - Test helpers and custom assertions
- `tests/mocks/` - Mock implementations for gh and glab CLI tools

**Test Coverage Areas**:
- ✅ Badge generation (WIP, Hotfix, CI, Ticket, Branch)
- ✅ Provider abstraction (GitHub and GitLab)
- ✅ Label management (labelized feature)
- ✅ Configuration parsing and CLI arguments
- ✅ Provider detection and authentication
- ✅ CI/CD integration with kcov coverage reporting

**Running Tests**:
```bash
# Run all tests
bats tests/**/*.bats

# Run specific test suite
bats tests/unit/*.bats
bats tests/integration/*.bats

# Run with coverage (CI)
kcov --exclude-pattern=/usr,/tmp coverage bats tests
```

## V2 Roadmap - Next Priorities

### 🔧 Code Quality & CI/CD Improvements (High Priority)

#### 1. ShellCheck Integration ✅ COMPLETED
- ✅ **ShellCheck linter configuration added**
  - `.shellcheckrc` with comprehensive linting rules
  - Configured to be restrictive but practical
  - Catches style issues, warnings, and errors
- ✅ **Documentation added**
  - `LINTING_SETUP.md` with GitHub Actions workflow integration guide
  - Instructions for running ShellCheck locally
  - Common issues and fixes documented
- [ ] **CI workflow integration** (pending)
  - Add shellcheck step to GitHub Actions
  - Run before tests to catch issues early
  - Update Badgetizr badge on linting failure
- [ ] **Pre-commit Git hook** (future enhancement)
  - Automatic ShellCheck on commit
  - Prevent committing code with linting issues

**For Claude Code Contributors:**
Before committing changes to shell scripts (`.sh` files, `badgetizr`):
1. Run: `shellcheck *.sh providers/*.sh badgetizr`
2. Fix all errors and warnings
3. Test changes to ensure functionality preserved
4. See `LINTING_SETUP.md` for detailed guidance

#### 2. Danger Integration
- [ ] **Setup Danger for PR automation**
  - Add Dangerfile with custom rules
  - Integrate with GitHub Actions workflow
  - Automatic PR feedback for:
    - Test coverage changes
    - ShellCheck violations
    - Large PR warnings
    - Missing documentation updates
    - Changelog reminders
  - Link to relevant CI artifacts (coverage reports, test results)

#### 3. Docker Image Distribution
- [ ] **Create official Docker image**
  - Multi-stage Dockerfile with minimal footprint
  - Include all dependencies (gh, glab, yq, jq)
  - Support for both GitHub and GitLab
  - Published to Docker Hub and GitHub Container Registry
  - Version tags matching releases
  - Usage example:
    ```bash
    docker run -e GITHUB_TOKEN=$GITHUB_TOKEN \
      aikrice/badgetizr:latest \
      --pr-id=123 --configuration=/config/.badgetizr.yml
    ```
  - Benefits:
    - Consistent environment across platforms
    - No dependency installation needed
    - Easy integration with any CI/CD system
    - Isolated execution

#### 4. Bitrise Step Implementation
- [ ] **Create official Bitrise workflow step**
  - Target: iOS, Android, React Native, Flutter developers
  - Create `step.yml` with Bitrise step specification
  - Map Bitrise environment variables:
    - `$BITRISE_PULL_REQUEST` → `--pr-id`
    - `$BITRISEIO_GIT_BRANCH_DEST` → `--pr-destination-branch`
    - `$BITRISE_BUILD_NUMBER` → `--pr-build-number`
    - `$BITRISE_BUILD_URL` → `--pr-build-url`
  - Support both GitHub and GitLab repositories
  - Add step icon (512x512 PNG) and branding
  - Submit to Bitrise Step Library
  - Documentation:
    - Add Bitrise section to README.md
    - Create example `bitrise.yml` configuration
    - Add Bitrise badge to README header

### 🚀 Feature Enhancements (Future Versions)
- [ ] **Configuration Generator**: `badgetizr --init` command with interactive setup
- [ ] **Provider Extension**: Support for additional platforms (Azure DevOps, Bitbucket)
- [ ] **Badge Templates**: Reusable badge configurations and inheritance
- [ ] **Real-time CI Status**: Dynamic badge updates based on actual CI status
- [ ] **Webhook Integration**: Automatic updates without manual CI triggers