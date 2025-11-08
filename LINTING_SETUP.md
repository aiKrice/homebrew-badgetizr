# ShellCheck Linting Setup

This document provides instructions for integrating ShellCheck linting into the Badgetizr CI/CD workflow.

## Overview

ShellCheck is now configured for this project to ensure shell script quality and consistency. The configuration files have been created, but the GitHub Actions workflow needs manual modification due to permission constraints.

## Files Added

1. **`.shellcheckrc`** - ShellCheck configuration file
   - Enables all optional checks for maximum code quality
   - Disables only SC2034 (unused variables) for configuration variables
   - Sets severity to 'style' to catch all issues
   - Configures source path resolution for sourced files

2. **`CLAUDE.md`** - Instructions for Claude Code
   - Ensures Claude runs ShellCheck before committing shell script changes
   - Provides common issue fixes and development workflow
   - Documents future pre-commit hook roadmap item

## GitHub Actions Workflow Integration

### Step 1: Install ShellCheck

Add ShellCheck installation to the dependency installation step in `.github/workflows/badgetizr.yml`:

```yaml
- name: Install dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y bats jq cmake g++ pkg-config libcurl4-openssl-dev libelf-dev libdw-dev binutils-dev libiberty-dev shellcheck
```

Note: Just add `shellcheck` to the end of the existing package list on line 43.

### Step 2: Add Linting Steps

Insert these steps **after** line 60 (after "Add kcov to PATH") and **before** line 62 (before "Badgetizr - Running Unit Tests"):

```yaml
      - name: Badgetizr - Linting
        uses: aiKrice/homebrew-badgetizr@2.4.0
        with:
          pr_id: ${{ github.event.pull_request.number }}
          configuration: .badgetizr.yml
          pr_destination_branch: ${{ github.event.pull_request.base.ref }}
          pr_build_number: ${{ github.run_id }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          ci_status: "started"
          ci_text: "Linting"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Run ShellCheck linting
        run: |
          echo "Running ShellCheck on all shell files..."
          shellcheck *.sh providers/*.sh
          echo "✅ ShellCheck passed!"

      - name: Badgetizr - Linting Complete
        if: success()
        uses: aiKrice/homebrew-badgetizr@2.4.0
        with:
          pr_id: ${{ github.event.pull_request.number }}
          configuration: .badgetizr.yml
          pr_destination_branch: ${{ github.event.pull_request.base.ref }}
          pr_build_number: ${{ github.run_id }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          ci_status: "passed"
          ci_text: "Linting Complete"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Badgetizr - Linting Failed
        if: failure()
        uses: aiKrice/homebrew-badgetizr@2.4.0
        with:
          pr_id: ${{ github.event.pull_request.number }}
          configuration: .badgetizr.yml
          pr_destination_branch: ${{ github.event.pull_request.base.ref }}
          pr_build_number: ${{ github.run_id }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          ci_status: "failed"
          ci_text: "Linting Failed"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## How It Works

1. **Badgetizr - Linting**: Updates the PR with "Linting" status badge (in progress)
2. **Run ShellCheck linting**: Executes ShellCheck on all shell files
   - If ShellCheck finds issues, the step fails
   - The failure is caught by the conditional steps below
3. **Badgetizr - Linting Complete** (on success): Updates badge to show linting passed
4. **Badgetizr - Linting Failed** (on failure): Updates badge to show "Linting Failed" with error status

## Error Handling

- If linting **fails**: The workflow continues but the Badgetizr badge shows "Linting Failed" in red
- The overall CI **will fail** because the ShellCheck step returns a non-zero exit code
- This ensures developers must fix linting issues before merging

## Local Development

Developers can run ShellCheck locally before pushing:

```bash
# Install ShellCheck
# Ubuntu/Debian: sudo apt-get install shellcheck
# macOS: brew install shellcheck

# Run linting
shellcheck *.sh providers/*.sh

# Or use the helper command (if you create one)
make lint  # (you could add this to a Makefile)
```

## Claude Code Integration

With `CLAUDE.md` in place, Claude Code will automatically:
1. Run ShellCheck before committing shell script changes
2. Fix linting issues
3. Only commit when linting passes

This ensures high code quality even when using AI assistance.

## Future: Pre-commit Hook

As mentioned in the issue, a future enhancement is to add a Git pre-commit hook that runs ShellCheck automatically.

### Implementation (Future)

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit hook to run ShellCheck

echo "Running ShellCheck..."

# Get list of staged .sh files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$')

if [ -n "$STAGED_FILES" ]; then
    # Run shellcheck on staged files
    if ! shellcheck $STAGED_FILES; then
        echo "❌ ShellCheck failed. Please fix the issues before committing."
        exit 1
    fi
fi

echo "✅ ShellCheck passed!"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

**Note**: Git hooks are not committed to the repository. Each developer would need to set this up locally, or we could provide a setup script.

## Configuration Details

The `.shellcheckrc` file is configured with:

- **Severity**: `style` - Catches all issues including style recommendations
- **Shell**: `bash` - Assumes Bash shell
- **Enabled checks**: All optional checks enabled
- **Disabled checks**: Only SC2034 (unused variables) for config variables
- **Source path**: `SCRIPTDIR` - Helps resolve sourced files

These settings are restrictive but practical for maintaining high code quality.

## Testing

After making the workflow changes, test by:

1. Creating a PR with intentional ShellCheck violations
2. Verify the linting step catches the issues
3. Verify the Badgetizr badge shows "Linting Failed"
4. Fix the issues and verify the badge updates to "Linting Complete"

## Resources

- [ShellCheck GitHub](https://github.com/koalaman/shellcheck)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [ShellCheck Online](https://www.shellcheck.net/) - Test scripts in your browser
