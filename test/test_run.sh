#!/bin/sh

# Unit tests for run.sh
# Usage: ./test/test_run.sh

# Source the test framework
. "$(dirname "$0")/test_framework.sh"

# Path to the script
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Tests for the function normalize_command
test_normalize_command() {
    cd "$SCRIPT_DIR"
    . ./run.sh 2>&1 1>/dev/null
    
    # Test aliases for preprocess
    local result
    result=$(normalize_command "pre-process")
    assert_equal "preprocess" "$result" "normalize_command pre-process"
    
    result=$(normalize_command "pre-processing")
    assert_equal "preprocess" "$result" "normalize_command pre-processing"
    
    result=$(normalize_command "preprocessing")
    assert_equal "preprocess" "$result" "normalize_command preprocessing"
    
    # Test aliases for train
    result=$(normalize_command "training")
    assert_equal "train" "$result" "normalize_command training"
    
    # Test aliases for help
    result=$(normalize_command "-h")
    assert_equal "help" "$result" "normalize_command -h"
    
    result=$(normalize_command "--help")
    assert_equal "help" "$result" "normalize_command --help"
    
    result=$(normalize_command "help")
    assert_equal "help" "$result" "normalize_command help"
    
    result=$(normalize_command "")
    assert_equal "help" "$result" "normalize_command empty"
    
    # Test unknown command
    result=$(normalize_command "unknown")
    assert_equal "unknown" "$result" "normalize_command unknown"
}

# Tests for script existence
test_script_existence() {
    assert_file_exists "$SCRIPT_DIR/run.sh" "Main script run.sh exists"
    assert_file_exists "$SCRIPT_DIR/src/preprocess.sh" "Script preprocess.sh exists"
    assert_file_exists "$SCRIPT_DIR/src/train.sh" "Script train.sh exists"
    assert_file_exists "$SCRIPT_DIR/src/generate.sh" "Script generate.sh exists"
    assert_file_exists "$SCRIPT_DIR/src/export.sh" "Script export.sh exists"
}

# Tests for execution permissions
test_script_permissions() {
    assert_success "[ -x '$SCRIPT_DIR/run.sh' ]" "Main script is executable"
    assert_success "[ -x '$SCRIPT_DIR/src/preprocess.sh' ]" "Script preprocess.sh is executable"
    assert_success "[ -x '$SCRIPT_DIR/src/train.sh' ]" "Script train.sh is executable"
    assert_success "[ -x '$SCRIPT_DIR/src/generate.sh' ]" "Script generate.sh is executable"
    assert_success "[ -x '$SCRIPT_DIR/src/export.sh' ]" "Script export.sh is executable"
}

# Tests for help output
test_help_output() {
    local help_output
    help_output=$(cd "$SCRIPT_DIR" && ./run.sh --help 2>&1)
    echo "$help_output" | grep -q 'Usage:'
    assert_success "[ $? -eq 0 ]" "Help displays 'Usage:'"
    echo "$help_output" | grep -q 'preprocess'
    assert_success "[ $? -eq 0 ]" "Help mentions preprocess"
    echo "$help_output" | grep -q 'train'
    assert_success "[ $? -eq 0 ]" "Help mentions train"
    echo "$help_output" | grep -q 'generate'
    assert_success "[ $? -eq 0 ]" "Help mentions generate"
    echo "$help_output" | grep -q 'export'
    assert_success "[ $? -eq 0 ]" "Help mentions export"
}

# Tests for invalid commands
test_invalid_commands() {
    local output
    output=$(cd "$SCRIPT_DIR" && ./run.sh invalid_command 2>&1)
    echo "$output" | grep -q 'Unknown command'
    assert_success "[ $? -eq 0 ]" "Invalid command shows error"
}

# Tests for no arguments
test_no_arguments() {
    local output
    output=$(cd "$SCRIPT_DIR" && ./run.sh 2>&1)
    echo "$output" | grep -q 'Usage:'
    assert_success "[ $? -eq 0 ]" "No arguments displays help"
}

# Tests for script syntax
test_script_syntax() {
    # Test that the script has valid syntax
    assert_success "cd '$SCRIPT_DIR' && sh -n run.sh" "Main script has valid syntax"
    assert_success "cd '$SCRIPT_DIR/src' && sh -n preprocess.sh" "Preprocess script has valid syntax"
    assert_success "cd '$SCRIPT_DIR/src' && sh -n train.sh" "Train script has valid syntax"
    assert_success "cd '$SCRIPT_DIR/src' && sh -n generate.sh" "Generate script has valid syntax"
    assert_success "cd '$SCRIPT_DIR/src' && sh -n export.sh" "Export script has valid syntax"
}

# Main function to run all tests
run_all_tests() {
    echo "🚀 Starting tests for run.sh"
    echo "=================================="
    
    run_test "Test normalize_command function" test_normalize_command
    run_test "Test script existence" test_script_existence
    run_test "Test execution permissions" test_script_permissions
    run_test "Test help output" test_help_output
    run_test "Test invalid commands" test_invalid_commands
    run_test "Test no arguments" test_no_arguments
    run_test "Test script syntax" test_script_syntax
    
    # Cleanup
    cleanup_temp_files
    
    # Show summary
    test_summary
}

# Run tests if script is called directly
if [ "${0##*/}" = "test_run.sh" ]; then
    run_all_tests
fi 