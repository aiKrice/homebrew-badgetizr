# Git Hooks Documentation

This project uses Git hooks to automate code quality checks and improve the developer experience. The hooks are automatically configured when you run `./configure`.

## Overview

The repository includes three Git hooks that run automatically during the commit process:

1. **pre-commit** - Formats and lints shell scripts before committing
2. **prepare-commit-msg** - Auto-formats commit messages with conventional commits
3. **commit-msg** - Sends a macOS notification when commit succeeds

## Setup

### Installation

When you run `./configure`, it automatically:
- Installs all required dependencies (via Brewfile on macOS)
- Configures Git to use the `githooks/` directory
- Makes all hooks executable

```bash
./configure
```

### How It Works

The setup uses Git's `include.path` feature to load `.gitconfig`, which sets:
```ini
[core]
    hooksPath = githooks
```

This means:
- ✅ Hooks are versioned in the repository
- ✅ Updates to hooks are automatically pulled with `git pull`
- ✅ All developers use the same hooks

## Hook Details

### 1. pre-commit

**Purpose**: Automatically format and lint shell scripts before committing.

**What it does**:
1. Detects modified shell files (`.sh`, `.bash`, `badgetizr`, `configure`)
2. Runs `shfmt` to auto-format code
3. Stages the formatted changes automatically
4. Runs `shellcheck` to catch issues
5. Sends a macOS notification on failure

**Dependencies**:
- `shfmt` - Shell script formatter
- `shellcheck` - Shell script linter

**Example output**:
```
🟡 Checking 3 shell file(s)...
🟡 Running shfmt formatter...
🟢 Auto-formatted 2 file(s) and staged changes
  - badgetizr
  - utils.sh
🟡 Running shellcheck linter...
🟢 ShellCheck passed
🟢 Pre-commit checks passed
```

**On failure**:
```
🟡 Running shellcheck linter...
🔴 ✗ ShellCheck found issues:

In utils.sh line 42:
    echo $variable
         ^-- SC2086: Double quote to prevent globbing

🟡 Please fix the issues above before committing.
```

### 2. prepare-commit-msg

**Purpose**: Automatically format commit messages following conventional commits.

**What it does**:
1. Detects your branch name (e.g., `feat/GH-123_add-feature`)
2. Extracts the commit type (`feat`, `fix`, `docs`, etc.)
3. Extracts the GitHub issue number (`GH-123`)
4. Prepares your commit message: `feat(GH-123): #write description here`

**Supported commit types**:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `test` - Adding tests
- `build` - Build system changes
- `ci` - CI/CD changes
- `chore` - Other changes
- `revert` - Reverting changes

**Branch naming convention**:
```
<type>/GH-<number>_description
```

Examples:
- `feat/GH-123_add-user-auth`
- `fix/GH-456_resolve-crash`
- `docs/GH-789_update-readme`

**Commit message format**:
```
<type>(GH-<number>): <description>
```

Examples:
- `feat(GH-123): add user authentication system`
- `fix(GH-456): resolve crash on startup`
- `docs(GH-789): update README with installation steps`

**Special behavior**:
- **Amend commits**: Preserves existing message (already validated)
- **Non-conventional branches**: Lets you write message normally
- **Placeholder**: `#write description here` reminds you to add description

### 3. commit-msg

**Purpose**: Sends a macOS notification when commit succeeds.

**What it does**:
1. Reads your commit message
2. Sends a notification with the commit summary
3. Plays a success sound

**Example notification**:
```
Title: Badgetizr Commit Successful
Message: feat(GH-123): add user authentication system
Sound: Glass
```

**Requirements**:
- macOS only
- `terminal-notifier` (installed via Brewfile)

## Dependencies

### macOS (via Brewfile)

All dependencies are installed automatically with `brew bundle`:

```ruby
brew "gh"                 # GitHub CLI
brew "glab"               # GitLab CLI
brew "yq"                 # YAML processor
brew "jq"                 # JSON processor
brew "shellcheck"         # Shell linter
brew "shfmt"              # Shell formatter
brew "bats-core"          # Testing framework
brew "kcov"               # Code coverage
brew "terminal-notifier"  # macOS notifications
```

### Linux

On Linux, `gh`, `glab`, `shellcheck`, and `shfmt` must be installed manually (see `./configure` output for instructions).

## Troubleshooting

### Hooks not running

If hooks aren't executing:

1. Verify Git configuration:
```bash
git config --local --get-all include.path
# Should output: .gitconfig
```

2. Check hooks path:
```bash
git config --local core.hooksPath
# Should output: githooks
```

3. Re-run configure:
```bash
./configure
```

### Missing dependencies error

If you see:
```
🔴 Error: Missing required dependencies: shfmt shellcheck
🟡 Please run './configure' at the root of the project
```

**Solution**:
```bash
./configure
```

### Hooks are not executable

If hooks exist but don't run:
```bash
chmod +x githooks/*
```

### Bypassing hooks (not recommended)

In rare cases where you need to bypass hooks:
```bash
git commit --no-verify -m "emergency fix"
```

**Warning**: This skips all quality checks. Use sparingly.

## Customization

### Disabling specific hooks

To disable a hook temporarily, rename it:
```bash
mv githooks/pre-commit githooks/pre-commit.disabled
```

Re-enable:
```bash
mv githooks/pre-commit.disabled githooks/pre-commit
```

### Modifying hooks

Hooks are versioned in `githooks/`. To modify:

1. Edit the hook file (e.g., `githooks/pre-commit`)
2. Test locally
3. Commit and push
4. Other developers get updates on next `git pull`

### Adding new hooks

Git supports many hook types. To add a new hook:

1. Create file in `githooks/` (e.g., `githooks/post-checkout`)
2. Make it executable: `chmod +x githooks/post-checkout`
3. Commit and push

Available hooks:
- `pre-push` - Before pushing
- `post-checkout` - After checking out a branch
- `post-merge` - After merging
- See: https://git-scm.com/docs/githooks

## Best Practices

### For developers

1. **Always run `./configure` after cloning** - Sets up hooks and dependencies
2. **Follow branch naming convention** - Enables automatic commit formatting
3. **Don't use `--no-verify` unless absolutely necessary** - Hooks ensure quality
4. **Keep hooks fast** - They run on every commit

### For maintainers

1. **Test hooks thoroughly** - They affect all developers
2. **Keep error messages clear** - Help developers fix issues quickly
3. **Update this documentation** - When adding/modifying hooks
4. **Consider hook performance** - Slow hooks frustrate developers

## Examples

### Example workflow

```bash
# Clone and setup
git clone <repo>
cd homebrew-badgetizr
./configure

# Create feature branch
git checkout -b feat/GH-123_add-badges

# Make changes
vim badgetizr

# Commit (hooks run automatically)
git add badgetizr
git commit
# Editor opens with: feat(GH-123): #write description here
# Replace placeholder with: feat(GH-123): add dynamic badge support
# Save and close

# If shfmt auto-formatted files, they're already staged
# If shellcheck fails, fix issues and commit again
```

### Example pre-commit output

**Success case**:
```
🟡 Checking 2 shell file(s)...
🟡 Running shfmt formatter...
🟢 Auto-formatted 1 file(s) and staged changes
  - providers/github.sh
🟡 Running shellcheck linter...
🟢 ShellCheck passed
🟢 Pre-commit checks passed
```

**Failure case**:
```
🟡 Checking 1 shell file(s)...
🟡 Running shfmt formatter...
🟡 Running shellcheck linter...
🔴 ✗ ShellCheck found issues:

In badgetizr line 145:
    if [ $status == 0 ]; then
         ^-- SC2086: Double quote to prevent globbing
              ^-- SC2039: In POSIX sh, == in place of = is undefined

🟡 Please fix the issues above before committing.
```

## Additional Resources

- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [shfmt Documentation](https://github.com/mvdan/sh)
