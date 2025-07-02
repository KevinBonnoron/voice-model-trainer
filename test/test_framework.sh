#!/bin/sh

# Simple shell unit test framework
# Usage: source test_framework.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variables for tests
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0
CURRENT_TEST=""

# Start a test
start_test() {
    CURRENT_TEST="$1"
    TEST_COUNT=$((TEST_COUNT + 1))
    printf "${YELLOW}🧪 Test $TEST_COUNT: $CURRENT_TEST${NC}\n"
}

test_start() { start_test "$@"; } # Alias for backward compatibility

# Assert equality
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-$CURRENT_TEST}"
    
    if [ "$expected" = "$actual" ]; then
        printf "  ${GREEN}✅ PASS: $message${NC}\n"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        printf "  ${RED}❌ FAIL: $message${NC}\n"
        printf "    Expected: '$expected'\n"
        printf "    Actual:   '$actual'\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

# Assert command success
assert_success() {
    local command="$1"
    local message="${2:-$CURRENT_TEST}"
    
    if eval "$command" >/dev/null 2>&1; then
        printf "  ${GREEN}✅ PASS: $message${NC}\n"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        printf "  ${RED}❌ FAIL: $message${NC}\n"
        printf "    Command failed: $command\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

# Assert command failure
assert_failure() {
    local command="$1"
    local message="${2:-$CURRENT_TEST}"
    
    if ! eval "$command" >/dev/null 2>&1; then
        printf "  ${GREEN}✅ PASS: $message${NC}\n"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        printf "  ${RED}❌ FAIL: $message${NC}\n"
        printf "    Command should have failed: $command\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-$CURRENT_TEST}"
    
    if [ -f "$file" ]; then
        printf "  ${GREEN}✅ PASS: $message${NC}\n"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        printf "  ${RED}❌ FAIL: $message${NC}\n"
        printf "    File does not exist: $file\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-$CURRENT_TEST}"
    
    if [ -d "$dir" ]; then
        printf "  ${GREEN}✅ PASS: $message${NC}\n"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    else
        printf "  ${RED}❌ FAIL: $message${NC}\n"
        printf "    Directory does not exist: $dir\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

# Capture command output
capture_output() {
    local command="$1"
    eval "$command" 2>&1
}

# Run a test function and capture errors
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    start_test "$test_name"
    if eval "$test_function"; then
        printf "  ${GREEN}✅ Test completed${NC}\n"
    else
        printf "  ${RED}❌ Test failed with error${NC}\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

# Print test summary
print_summary() {
    echo
    echo "📊 Test summary:"
    echo "  Total: $TEST_COUNT"
    if [ $PASSED_COUNT -gt 0 ]; then
        printf "  ${GREEN}Passed: $PASSED_COUNT${NC}\n"
    fi
    if [ $FAILED_COUNT -gt 0 ]; then
        printf "  ${RED}Failed: $FAILED_COUNT${NC}\n"
    fi
    
    if [ $FAILED_COUNT -eq 0 ]; then
        printf "${GREEN}🎉 All tests passed!${NC}\n"
        return 0
    else
        printf "${RED}💥 $FAILED_COUNT test(s) failed.${NC}\n"
        return 1
    fi
}

test_summary() { print_summary; } # Alias for backward compatibility

# Clean up temporary files
delete_temp_files() {
    rm -rf /tmp/test_* 2>/dev/null || true
}
cleanup_temp_files() { delete_temp_files; } # Alias

# Create a temporary file
create_temp_file() {
    local prefix="${1:-test}"
    mktemp "/tmp/${prefix}_XXXXXX"
}

# Create a temporary directory
create_temp_dir() {
    local prefix="${1:-test}"
    mktemp -d "/tmp/${prefix}_XXXXXX"
} 