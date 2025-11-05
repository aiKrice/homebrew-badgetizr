# Troubleshooting

Common issues and solutions when using Badgetizr.

## Authentication Issues

### GitHub Authentication Failed
```bash
❌ GitHub authentication failed. Please run: gh auth login
```

**Solutions**:
1. **GitHub CLI not authenticated**:
   ```bash
   gh auth login
   # Follow the prompts to authenticate
   ```

2. **Environment variable missing**:
   ```bash
   export GITHUB_TOKEN="your_github_token"
   # Or for GitHub Actions:
   export GH_TOKEN="${{ secrets.GITHUB_TOKEN }}"
   ```

3. **Token lacks permissions**:
   - Ensure token has `repo` and `write:discussion` scopes
   - For organization repos, verify organization access

### GitLab Authentication Failed
```bash
❌ GitLab authentication failed. Please run: glab auth login
```

**Solutions**:
1. **GitLab CLI not configured**:
   ```bash
   glab auth login
   # Follow the prompts to authenticate
   ```

2. **Environment variable missing**:
   ```bash
   export GITLAB_TOKEN="your_gitlab_token"
   # Multiple token variables are supported:
   export GITLAB_ACCESS_TOKEN="your_token"
   export GL_TOKEN="your_token"
   ```

3. **CI/CD integration**:
   ```bash
   # In GitLab CI, use project access tokens:
   variables:
     GITLAB_TOKEN: $GITLAB_ACCESS_TOKEN
   ```

## Configuration Issues

### Configuration File Not Found
```bash
🔵 .badgetizr.yml not found. Using default values.
```

**Solutions**:
1. **Create configuration file**:
   ```bash
   # Copy example configuration
   cp .badgetizr.yml.example .badgetizr.yml
   ```

2. **Use custom path**:
   ```bash
   badgetizr -c path/to/config.yml --pr-id=123
   ```

### Invalid YAML Syntax
```bash
Error: yaml: line X: found character that cannot start any token
```

**Solutions**:
1. **Validate YAML syntax**:
   ```bash
   yq eval '.badge_wip.enabled' .badgetizr.yml
   ```

2. **Common YAML issues**:
   - Use quotes for string values: `enabled: "true"`
   - Check indentation (spaces, not tabs)
   - Escape special characters in regex patterns

## Badge Generation Issues

### No Badges Appearing
**Possible Causes**:
1. **All badges disabled in configuration**
2. **PR doesn't match badge criteria** (e.g., no "WIP" in title)
3. **CLI parameters missing** for required badges

**Solutions**:
1. **Check configuration**:
   ```yaml
   badge_wip:
     enabled: "true"  # Ensure at least one badge is enabled
   ```

2. **Verify PR content**:
   - WIP badge: Title contains "WIP"
   - Ticket badge: Title matches `sed_pattern`
   - Branch badge: Target branch differs from `base_branch`

3. **Provide required parameters**:
   ```bash
   # For CI badge:
   --pr-build-number=123 --pr-build-url="https://..."

   # For branch badge:
   --pr-destination-branch=main
   ```

### Ticket Badge Not Working
```bash
🟠 No ticket id identified in the PR title. Maybe your pattern is not correct.
```

**Solutions**:
1. **Check regex pattern**:
   ```yaml
   sed_pattern: '.*\(([^)]+)\).*'  # Matches: feat(ABC-123): description
   ```

2. **Test pattern locally**:
   ```bash
   echo "feat(ABC-123): Add feature" | sed -n -E 's/.*\(([^)]+)\).*/\1/p'
   # Should output: ABC-123
   ```

3. **Common patterns**:
   ```yaml
   # For [ABC-123] format:
   sed_pattern: '.*\[([^\]]+)\].*'

   # For #123 format:
   sed_pattern: '.*#([0-9]+).*'
   ```

## CLI Issues

### Command Not Found
```bash
badgetizr: command not found
```

**Solutions**:
1. **Homebrew installation**:
   ```bash
   brew install aiKrice/badgetizr/badgetizr
   ```

2. **Manual installation**:
   ```bash
   # Ensure badgetizr is executable and in PATH
   chmod +x badgetizr
   export PATH="$PWD:$PATH"
   ```

### Missing Dependencies
```bash
yq: command not found
gh: command not found
```

**Solutions**:
1. **Install dependencies**:
   ```bash
   # Run the configure script (recommended)
   ./configure

   # Or install manually:
   # macOS
   brew install gh yq

   # Ubuntu/Linux (install mikefarah/yq, NOT apt-get yq)
   sudo apt-get install gh
   sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
   sudo chmod +x /usr/local/bin/yq
   ```

## Provider Detection Issues

### Wrong Provider Detected
```bash
🔍 Detected provider: github
# But you want GitLab
```

**Solutions**:
1. **Force provider**:
   ```bash
   badgetizr --provider=gitlab --pr-id=123
   ```

2. **Check git remote**:
   ```bash
   git remote get-url origin
   # Should show gitlab.com for GitLab detection
   ```

## CI/CD Integration Issues

### GitHub Actions Failing
**Common Issues**:
1. **Missing token permissions**:
   ```yaml
   env:
     GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # Required
   ```

2. **Incorrect PR ID**:
   ```yaml
   with:
     pr_id: ${{ github.event.pull_request.number }}  # Not issue.number
   ```

### GitLab CI Failing
**Common Issues**:
1. **Missing glab installation**:
   ```yaml
   before_script:
     - curl -sSL "https://gitlab.com/gitlab-org/cli/-/releases/v1.76.2/downloads/glab_1.76.2_linux_amd64.tar.gz" | tar -xz -C /tmp
     - mv /tmp/bin/glab /usr/local/bin/glab
   ```

2. **Token configuration**:
   ```yaml
   variables:
     GITLAB_TOKEN: $GITLAB_ACCESS_TOKEN  # Use project access token
   ```

## Getting Help

If you continue to experience issues:

1. **Check version**:
   ```bash
   ./badgetizr -v
   ```

2. **Enable debug output**:
   ```bash
   set -x  # Enable bash debugging
   ./badgetizr --pr-id=123
   ```

3. **Report issues**:
   - Include full error messages
   - Provide configuration file (sanitized)
   - Specify platform (GitHub/GitLab)
   - Include command used and expected behavior