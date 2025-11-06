# Badgetizr Unit Tests

This directory contains unit tests for Badgetizr using [bats-core](https://github.com/bats-core/bats-core).

## Structure

```
tests/
├── README.md                    # This file
├── setup_suite.bash             # Common test setup
├── test_badgetizr.bats          # Tests for main badgetizr script
├── test_utils.bats              # Tests for utils.sh
├── test_provider_utils.bats     # Tests for provider_utils.sh
├── test_badge_logic.bats        # Tests for badge generation logic
└── fixtures/
    └── test-config.yml          # Test configuration file
```

## Running Tests

### Prerequisites

You need to have `bats-core` installed. Install it using one of these methods:

**Homebrew (macOS/Linux):**
```bash
brew install bats-core
```

**npm:**
```bash
npm install -g bats
```

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

### Run All Tests

From the project root:
```bash
bats tests/
```

Or using the test runner script (if available):
```bash
./run_tests.sh
```

### Run Specific Test File

```bash
bats tests/test_utils.bats
```

### Run with Verbose Output

```bash
bats -t tests/
```

### Run with Detailed Timing

```bash
bats --timing tests/
```

## Test Coverage

The test suite covers:

1. **Main Script (`test_badgetizr.bats`)**
   - Command-line argument parsing
   - Version display
   - Help text display
   - Error handling for missing required arguments
   - Path detection logic

2. **Utilities (`test_utils.bats`)**
   - Version variable definition
   - Help function output
   - Semantic versioning format

3. **Provider Utilities (`test_provider_utils.bats`)**
   - Provider detection (GitHub/GitLab)
   - Function existence checks
   - Mock testing for git remote detection

4. **Badge Logic (`test_badge_logic.bats`)**
   - WIP detection in PR titles
   - Badge delimiter tags
   - Hotfix branch detection
   - CI status validation
   - Checkbox counting logic

## Writing New Tests

When adding new tests, follow these guidelines:

1. **Use descriptive test names**: Test names should clearly describe what is being tested
2. **One assertion per test**: Each test should focus on a single behavior
3. **Use setup/teardown**: Common setup code goes in `setup()` and `setup_suite()`
4. **Mock external dependencies**: Use function mocking for git, gh, glab commands
5. **Test edge cases**: Include tests for error conditions and boundary cases

### Example Test

```bash
@test "descriptive test name" {
    # Arrange: Set up test data
    local input="test value"

    # Act: Execute the code being tested
    run some_function "$input"

    # Assert: Verify the results
    [ "$status" -eq 0 ]
    [ "$output" = "expected output" ]
}
```

## Continuous Integration

Tests are automatically run in GitHub Actions on:
- Push to main branches
- Pull request creation/updates
- Before creating new releases

See `.github/workflows/test.yml` for CI configuration.

## Troubleshooting

### Tests fail with "command not found"
- Ensure bats-core is properly installed
- Check that the project dependencies (yq, jq) are available

### Mock functions not working
- Ensure you export mocked functions: `export -f function_name`
- Clean up mocks in teardown: `unset -f function_name`

### Path issues
- Use `$BATS_TEST_DIRNAME` to reference the test directory
- Use absolute paths when sourcing files

## Resources

- [Bats-core Documentation](https://bats-core.readthedocs.io/)
- [Bats-core GitHub](https://github.com/bats-core/bats-core)
- [Bats Testing Tutorial](https://github.com/bats-core/bats-core#writing-tests)
