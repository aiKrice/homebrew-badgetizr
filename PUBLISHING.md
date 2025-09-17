# Publishing (for maintainers)

Badgetizr uses an automated release process that handles version bumping, GitHub releases, Homebrew formula updates, and branch management.

## Prerequisites

- **Access**: Maintainer access to the repository
- **Authentication**: `GITHUB_TOKEN` environment variable set
- **Branch**: Must be on `develop` branch with clean working directory

## Release Process

Use the automated `publish.sh` script with semantic versioning:

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_github_token"

# Run the publish script with the new version
./publish.sh 1.5.6
```

## What the Script Does

The publish script automates the complete release process:

### 1. Version Updates
- Updates `BADGETIZR_VERSION` in `utils.sh`
- Updates version badges in `README.md`
- Updates GitHub Action version references
- Updates GitLab CI integration examples

### 2. Branch Management
```bash
develop → master → tag → release
```
- Merges `develop` into `master`
- Creates and pushes version tag
- Creates GitHub release with auto-generated notes

### 3. Homebrew Formula Update
- Downloads the new release archive
- Calculates SHA256 checksum
- Updates `Formula/badgetizr.rb` with new URL and checksum
- Commits and pushes formula changes

### 4. Cleanup
- Backmerges `master` to `develop`
- Removes temporary files
- Confirms successful completion

## Manual Steps (if needed)

If the automated script fails, you can perform these steps manually:

### Update Version
```bash
# Update version in utils.sh
sed -i '' 's/BADGETIZR_VERSION=".*"/BADGETIZR_VERSION="1.5.6"/' utils.sh

# Update README badges and examples
# Update action.yml version references
```

### Create Release
```bash
git switch master
git merge develop --no-ff
git tag -a "1.5.6" -m "Release 1.5.6"
git push origin 1.5.6
gh release create 1.5.6 --generate-notes
```

### Update Homebrew Formula
```bash
# Download archive and calculate SHA256
curl -L -o "badgetizr-1.5.6.tar.gz" "https://github.com/aiKrice/homebrew-badgetizr/archive/refs/tags/1.5.6.tar.gz"
shasum -a 256 "badgetizr-1.5.6.tar.gz"

# Update Formula/badgetizr.rb with new URL and SHA256
# Commit and push changes
```

## Versioning Guidelines

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., `1.5.6`)
- **Major**: Breaking changes or major new features
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes, documentation updates

## Troubleshooting Releases

If the publish script fails:

1. **Check working directory**: Must be clean
2. **Verify GitHub token**: Must have push and release permissions
3. **Check network connectivity**: Required for GitHub API calls
4. **Manual cleanup**: May need to manually revert changes and restart

## Post-Release Checklist

- [ ] Verify GitHub release created successfully
- [ ] Test Homebrew installation: `brew install aiKrice/badgetizr/badgetizr`
- [ ] Confirm GitHub Action marketplace reflects new version
- [ ] Update any dependent repositories or documentation