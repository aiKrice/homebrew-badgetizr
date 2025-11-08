## Test Helpers

Common utilities and assertions for badgetizr tests.

## Files

### `assertions.bash` - Custom Test Assertions

Specialized assertions for badge testing.

**Badge Assertions:**
- `assert_badge_contains "text"` - Check badge contains specific text
- `assert_has_badgetizr_delimiters` - Check for `<!--begin/end:badgetizr-->` tags
- `assert_badge_type_exists "type"` - Check specific badge type (wip/hotfix/ci/ticket/branch)
- `assert_badge_type_not_exists "type"` - Verify badge type is absent
- `assert_badge_has_color "color"` - Check badge color

**Label Assertions:**
- `assert_label_added "label"` - Verify label was added to PR
- `assert_label_removed "label"` - Verify label was removed
- `assert_label_created "label"` - Verify label was created

**PR/MR Assertions:**
- `assert_pr_description_updated` - Check PR description was modified

**General Assertions:**
- `assert_output_matches "regex"` - Match output against regex
- `assert_file_contains "file" "text"` - Check file contents
- `assert_success` - Check exit code is 0
- `assert_failure` - Check exit code is non-zero

### `test_helpers.bash` - Helper Functions

Utilities for test setup and execution.

**Environment Setup:**
- `setup_test_env()` - Initialize test environment
- `cleanup_test_env()` - Clean up after tests
- `load_badgetizr_functions()` - Source badgetizr functions

**Configuration:**
- `create_temp_config "yaml"` - Create temporary config file
- `get_default_test_config()` - Get default test configuration

**Git Mocking:**
- `mock_git()` - Mock git commands
- `unmock_git()` - Restore git

**Badge Utilities:**
- `extract_badges_section "description"` - Extract badges from PR
- `count_badges "output"` - Count badges in output
- `get_badge_url_by_type "output" "type"` - Get specific badge URL
- `validate_badge_url "url"` - Validate badge URL format

**Execution:**
- `simulate_badgetizr_run pr_id [config] [args]` - Run badgetizr with mocks

**Debugging:**
- `debug_print_mock_state()` - Print all mock variables

## Usage Example

```bash
#!/usr/bin/env bats

load '../helpers/test_helpers'
load '../helpers/assertions'
load '../mocks/mock_gh'
load '../mocks/mock_responses'

setup() {
    setup_test_env
    source mock_gh.sh
    setup_wip_pr
}

teardown() {
    cleanup_test_env
}

@test "WIP badge is generated for WIP PR" {
    # Act
    run simulate_badgetizr_run 123

    # Assert
    assert_success
    assert_badge_type_exists "wip"
    assert_badge_has_color "yellow"
}
```

## Best Practices

1. **Always call `setup_test_env` in setup()**
2. **Always call `cleanup_test_env` in teardown()**
3. **Use predefined scenarios from `mock_responses.sh`**
4. **Use specific assertions instead of raw grep**
5. **Debug with `debug_print_mock_state` when tests fail**
