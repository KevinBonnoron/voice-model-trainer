#!/bin/sh

# Unit tests for augment.sh
# Usage: ./test_augment.sh

. "$(dirname "$0")/test_framework.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

test_help_output() {
    local help_output
    help_output=$(cd "$SCRIPT_DIR/src" && . ./augment.sh && show_help_augment 2>&1)
    echo "$help_output" | grep -q 'Usage:'
    assert_success "[ $? -eq 0 ]" "Help displays 'Usage:'"

    echo "$help_output" | grep -q '\--input'
    assert_success "[ $? -eq 0 ]" "Help mentions --input option"

    echo "$help_output" | grep -q '\--output'
    assert_success "[ $? -eq 0 ]" "Help mentions --output option"

    echo "$help_output" | grep -q '\--num-augmentations'
    assert_success "[ $? -eq 0 ]" "Help mentions --num-augmentations option"
}

test_missing_required_arguments() {
    cd "$SCRIPT_DIR/src"
    . ./augment.sh
    local output

    output=$(run_augment --num-augmentations 3 2>&1 || true)
    echo "$output" | grep -q 'input parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing input shows error"

    local temp_dir=$(create_temp_dir "input")
    output=$(run_augment --input "$temp_dir" 2>&1 || true)
    echo "$output" | grep -q 'output parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing output shows error"

    rm -rf "$temp_dir"
}

test_invalid_paths() {
    cd "$SCRIPT_DIR/src"
    . ./augment.sh
    local output

    output=$(run_augment --input /tmp/doesnotexist --output /tmp/out 2>&1 || true)
    echo "$output" | grep -q 'does not exist'
    assert_success "[ $? -eq 0 ]" "Invalid input path shows error"
}

test_output_directory_creation() {
    cd "$SCRIPT_DIR/src"
    . ./augment.sh
    local temp_input=$(create_temp_dir "input")
    local temp_output="/tmp/test_augment_output_$$"
    if [ -d "$temp_output" ]; then rm -rf "$temp_output"; fi
    ( run_augment --input "$temp_input" --output "$temp_output" 2>/dev/null ) || true
    assert_dir_exists "$temp_output" "Output directory was created"
    rm -rf "$temp_input" "$temp_output"
}

test_invalid_options() {
    cd "$SCRIPT_DIR/src"
    . ./augment.sh
    local output

    output=$(run_augment --invalid-option 2>&1 || true)
    echo "$output" | grep -q 'Unknown option'
    assert_success "[ $? -eq 0 ]" "Invalid option shows error"
}

run_all_tests() {
    echo "🚀 Starting tests for augment.sh"
    echo "=================================="
    run_test "Test help output" test_help_output
    run_test "Test missing required arguments" test_missing_required_arguments
    run_test "Test invalid paths" test_invalid_paths
    run_test "Test output directory creation" test_output_directory_creation
    run_test "Test invalid options" test_invalid_options
    cleanup_temp_files
    test_summary
}

if [ "${0##*/}" = "test_augment.sh" ]; then
    run_all_tests
fi
