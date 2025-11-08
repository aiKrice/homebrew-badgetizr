# Parallel Test Execution Note:
# --jobs requires GNU parallel (brew install parallel) or rush (go install github.com/shenwei356/rush@latest)
# Currently not enabled due to shared mock directories (/tmp/mock_gh_responses, /tmp/mock_glab_responses)
# that would cause race conditions. Future improvement: use unique temp dirs per test.

.PHONY: test
test:
	@echo "Running all tests..."
	@bats tests/test_badgetizr.bats tests/test_provider_utils.bats tests/unit/*.bats tests/integration/*.bats

.PHONY: test-unit
test-unit:
	@echo "Running unit tests..."
	@bats tests/unit/*.bats

.PHONY: test-integration
test-integration:
	@echo "Running integration tests..."
	@bats tests/integration/*.bats tests/test_badgetizr.bats tests/test_provider_utils.bats

.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	@mkdir -p coverage
	@kcov --exclude-pattern=/usr,/tmp coverage bats tests/test_badgetizr.bats tests/test_provider_utils.bats tests/unit/*.bats tests/integration/*.bats

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make test              - Run all tests (110 tests)"
	@echo "  make test-unit         - Run unit tests only (26 tests)"
	@echo "  make test-integration  - Run integration tests only (84 tests)"
	@echo "  make test-coverage     - Run tests with kcov coverage"
	@echo "  make help              - Show this help message"
