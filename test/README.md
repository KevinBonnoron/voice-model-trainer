# Shell Unit Testing Framework

This directory contains a comprehensive unit testing framework for shell scripts, specifically designed for the voice-model-trainer project.

## Overview

The testing framework provides:
- **Simple assertion functions** for common test cases
- **Color-coded output** for easy reading
- **Test organization** with individual test suites
- **Temporary file management** for isolated testing
- **Mocking capabilities** for external dependencies

## Files

- `test_framework.sh` - Core testing framework with assertion functions
- `test_run.sh` - Tests for the main `run.sh` script
- `test_preprocess.sh` - Tests for the `preprocess.sh` script
- `run_tests.sh` - Main test runner to execute all test suites
- `example_test.sh` - Example tests demonstrating framework usage

## Quick Start

### Run all tests
```bash
./test/run_tests.sh
```

### Run specific test suite
```bash
./test/run_tests.sh run        # Test run.sh only
./test/run_tests.sh preprocess # Test preprocess.sh only
```

### Run individual test file
```bash
./test/test_run.sh
./test/test_preprocess.sh
./test/example_test.sh
```

## Framework Features

### Assertion Functions

```bash
# Equality assertions
assert_equal "expected" "actual" "message"

# Success/failure assertions
assert_success "command" "message"
assert_failure "command" "message"

# File system assertions
assert_file_exists "path/to/file" "message"
assert_dir_exists "path/to/directory" "message"

# Output capture
output=$(capture_output "command")
```

### Temporary File Management

```bash
# Create temporary files/directories
temp_file=$(create_temp_file "prefix")
temp_dir=$(create_temp_dir "prefix")

# Cleanup
cleanup_temp_files
```

### Test Organization

```bash
# Define a test function
test_my_function() {
    # Test logic here
    assert_equal "expected" "actual" "description"
}

# Run the test
run_test "Test description" test_my_function
```

## Writing Your Own Tests

### 1. Create a test file
```bash
#!/bin/sh
. "$(dirname "$0")/test_framework.sh"

# Your test functions here
test_something() {
    # Test logic
}

# Main execution
run_all_tests() {
    run_test "Test description" test_something
    test_summary
}

if [ "${0##*/}" = "your_test.sh" ]; then
    run_all_tests
fi
```

### 2. Add to the test runner
Edit `run_tests.sh` and add your test suite to the `TEST_SUITES` variable:
```bash
TEST_SUITES="run preprocess your_new_suite"
```

### 3. Make it executable
```bash
chmod +x test/your_test.sh
```

## Best Practices

1. **Isolate tests** - Use temporary files and directories
2. **Mock external dependencies** - Override functions like `docker` in tests
3. **Clean up** - Always clean up temporary files
4. **Descriptive messages** - Use clear assertion messages
5. **Test edge cases** - Include error conditions and boundary cases

## Example Test Structure

```bash
test_function_name() {
    # Setup
    local temp_file=$(create_temp_file "test")
    
    # Test logic
    local result=$(your_function "arg1" "arg2")
    assert_equal "expected" "$result" "Function returns expected value"
    
    # Cleanup
    rm -f "$temp_file"
}
```

## Mocking External Commands

```bash
# Mock docker command
docker() {
    echo "docker called with: $@"
    return 0
}
export -f docker

# Your test logic here
# The mocked docker function will be used instead of the real one
```

## Output Format

Tests produce color-coded output:
- 🧪 **Yellow**: Test start
- ✅ **Green**: Test passed
- ❌ **Red**: Test failed
- 📊 **Blue**: Summary information

## Integration with CI/CD

The test framework returns appropriate exit codes:
- `0` - All tests passed
- `1` - Some tests failed

This makes it suitable for integration with CI/CD pipelines. 