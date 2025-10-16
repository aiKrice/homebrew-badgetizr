# Contributing

We welcome contributions to Badgetizr! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

## Getting Started

1. **Fork the repository** and clone it locally:
   ```bash
   git clone https://github.com/your-username/homebrew-badgetizr.git
   cd homebrew-badgetizr
   ```

2. **Set up your development environment**:
   ```bash
   # Install dependencies
   ./configure

   # Set up authentication
   export GITHUB_TOKEN="your_github_token"     # For GitHub testing
   export GITLAB_TOKEN="your_gitlab_token"     # For GitLab testing
   ```

3. **Install test dependencies**:
   ```bash
   # Install bats-core for running tests
   brew install bats-core   # macOS/Linux with Homebrew
   # or
   npm install -g bats      # Using npm
   ```

4. **Run unit tests**:
   ```bash
   # Run all tests
   ./run_tests.sh

   # Run specific test file
   bats tests/test_utils.bats

   # Run with verbose output
   bats -t tests/
   ```

5. **Test your changes locally**:
   ```bash
   # Test with a GitHub PR
   ./badgetizr --pr-id=123

   # Test with custom configuration
   ./badgetizr -c test-config.yml --pr-id=123

   # Test GitLab integration
   ./badgetizr --provider=gitlab --pr-id=456
   ```

## Development Guidelines

### Code Standards
- Follow existing bash scripting conventions
- Use meaningful variable names and comments
- Test both GitHub and GitLab providers when making changes
- Ensure backwards compatibility with existing configurations

### Testing Requirements

#### Unit Tests
All code changes should include or update unit tests:
- Write tests for new functions and features
- Update existing tests when modifying behavior
- Ensure all tests pass before submitting a PR
- Tests are located in the `tests/` directory
- Use bats-core framework for bash testing

**Run tests before submitting:**
```bash
./run_tests.sh
```

#### Integration Tests
- Test your changes with real PRs on both GitHub and GitLab
- Verify badge generation works correctly
- Check that configuration parsing handles edge cases
- Test authentication with different token types

#### GitLab Integration Testing
For detailed instructions on testing Badgetizr with GitLab CI/CD:
- **Full GitLab testing guide**: See [`GITLAB-TESTING.md`](./GITLAB-TESTING.md) in this repository
- **Test project**: Use the [GitLab test project](https://gitlab.com/chris-saez/badgetizr-integration) for integration testing
- **CI/CD Pipeline**: Follow the provided `.gitlab-ci.yml` template to test merge request workflows

### Pull Request Process

**Important**: When opening a pull request, you must generate badges in your own PR by running Badgetizr locally:

```bash
# Configure authentication
export GITHUB_TOKEN="your_github_token"

# Run Badgetizr on your PR
./badgetizr --pr-id=YOUR_PR_NUMBER
```

This demonstrates that your changes work correctly and follows our "eat your own dog food" philosophy.

## Contributing Areas

We welcome contributions in these areas:

### 🐛 Bug Fixes
- Authentication issues
- Badge rendering problems
- Configuration parsing errors
- Provider-specific bugs

### ✨ New Features
- Additional badge types
- New CI/CD platform support
- Enhanced configuration options
- Improved error handling

### 📚 Documentation
- README improvements
- Configuration examples
- Troubleshooting guides
- API documentation

### 🧪 Testing
- Unit tests for bash functions
- Integration tests with real repositories
- Cross-platform compatibility testing
- Performance improvements

## Reporting Issues

When reporting bugs, please include:
- Badgetizr version (`./badgetizr -v`)
- Platform (GitHub/GitLab)
- Configuration file (sanitized)
- Command used and expected vs actual output
- Error messages or logs

## Feature Requests

For new features, please:
- Check existing issues first
- Describe the use case and benefit
- Provide examples of desired behavior
- Consider implementation complexity