#!/bin/sh

# Main test runner for voice-model-trainer
# Usage: ./run_tests.sh [test_suite]

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$TEST_DIR/.." && pwd)"

# Available test suites
TEST_SUITES="run augment metadata train export"

# Function to run a specific test suite
run_test_suite() {
    local suite="$1"
    local test_file="$TEST_DIR/test_${suite}.sh"
    
    if [ ! -f "$test_file" ]; then
        printf "${RED}❌ Test suite '$suite' not found: $test_file${NC}\n"
        return 1
    fi
    
    if [ ! -x "$test_file" ]; then
        printf "${YELLOW}⚠️  Making test file executable: $test_file${NC}\n"
        chmod +x "$test_file"
    fi
    
    printf "${BLUE}🔍 Running test suite: $suite${NC}\n"
    echo "=================================="
    
    if "$test_file"; then
        printf "${GREEN}✅ Test suite '$suite' completed successfully${NC}\n"
        return 0
    else
        printf "${RED}❌ Test suite '$suite' failed${NC}\n"
        return 1
    fi
}

# Function to run all test suites
run_all_tests() {
    printf "${BLUE}🚀 Running all test suites${NC}\n"
    echo "================================"
    
    local total_suites=0
    local passed_suites=0
    local failed_suites=0
    
    for suite in $TEST_SUITES; do
        total_suites=$((total_suites + 1))
        if run_test_suite "$suite"; then
            passed_suites=$((passed_suites + 1))
        else
            failed_suites=$((failed_suites + 1))
        fi
        echo
    done
    
    printf "${BLUE}📊 Test Summary:${NC}\n"
    echo "  Total suites: $total_suites"
    printf "  ${GREEN}Passed: $passed_suites${NC}\n"
    printf "  ${RED}Failed: $failed_suites${NC}\n"
    
    if [ $failed_suites -eq 0 ]; then
        printf "${GREEN}🎉 All test suites passed!${NC}\n"
        return 0
    else
        printf "${RED}💥 $failed_suites test suite(s) failed.${NC}\n"
        return 1
    fi
}

# Function to show help
show_help() {
    cat <<EOF
Usage: $0 [test_suite]

Available test suites:
$(echo "$TEST_SUITES" | tr ' ' '\n' | sed 's/^/  /')

Examples:
  $0                    # Run all test suites
  $0 run               # Run only run.sh tests
  $0 preprocess        # Run only preprocess.sh tests

EOF
}

# Main execution
case "${1:-all}" in
    all)
        run_all_tests
        ;;
    -h|--help|help)
        show_help
        ;;
    *)
        if echo "$TEST_SUITES" | grep -q "$1"; then
            run_test_suite "$1"
        else
            printf "${RED}❌ Unknown test suite: $1${NC}\n"
            echo
            show_help
            exit 1
        fi
        ;;
esac 