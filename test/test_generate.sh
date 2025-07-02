#!/bin/sh

# Unit tests for generate.sh
# Usage: ./test_generate.sh

. "$(dirname "$0")/test_framework.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GENERATE_SCRIPT="$SCRIPT_DIR/src/generate.sh"

test_help_output() {
    local help_output
    help_output=$(cd "$SCRIPT_DIR/src" && . ./generate.sh && show_help_generate 2>&1)
    echo "$help_output" | grep -q 'Usage:'
    assert_success "[ $? -eq 0 ]" "Help displays 'Usage:'"

    echo "$help_output" | grep -q '\--output'
    assert_success "[ $? -eq 0 ]" "Help mentions --output option"

    echo "$help_output" | grep -q '\--sentences-file'
    assert_success "[ $? -eq 0 ]" "Help mentions --sentences-file option"

    echo "$help_output" | grep -q '\--checkpoint-file'
    assert_success "[ $? -eq 0 ]" "Help mentions --checkpoint-file option"
}

test_missing_required_arguments() {
    cd "$SCRIPT_DIR/src"
    . ./generate.sh
    local output
    local temp_sentences=$(create_temp_file "sentences")
    touch "$temp_sentences"

    output=$(run_generate --output /tmp/test 2>&1 || true)
    echo "$output" | grep -q 'Error: sentences-file parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing sentences-file shows error"

    output=$(run_generate --sentences-file "$temp_sentences" 2>&1 || true)
    echo "$output" | grep -q 'Error: output parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing output shows error"

    output=$(run_generate --output /tmp/test --sentences-file "$temp_sentences" 2>&1 || true)
    echo "$output" | grep -q 'Error: checkpoint-file parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing checkpoint-file shows error"
}

test_invalid_paths() {
    cd "$SCRIPT_DIR/src"
    . ./generate.sh
    local temp_output=$(create_temp_dir "output")
    local output

    output=$(run_generate --output "$temp_output" --sentences-file /tmp/doesnotexist.jsonl --checkpoint-file /tmp/doesnotexist.ckpt 2>&1 || true)
    echo "$output" | grep -q 'does not exist'
    assert_success "[ $? -eq 0 ]" "Invalid sentences-file path shows error"
    rm -rf "$temp_output"
}

test_output_directory_creation() {
    cd "$SCRIPT_DIR/src"
    . ./generate.sh
    local temp_output="/tmp/test_generate_output_$$"
    local temp_sentences=$(create_temp_file "sentences")
    local temp_ckpt=$(create_temp_file "ckpt")
    touch "$temp_sentences" "$temp_ckpt"
    if [ -d "$temp_output" ]; then rm -rf "$temp_output"; fi

    run_generate --output "$temp_output" --sentences-file "$temp_sentences" --checkpoint-file "$temp_ckpt" 2>/dev/null || true
    assert_dir_exists "$temp_output" "Output directory was created"
    rm -rf "$temp_output" "$temp_sentences" "$temp_ckpt"
}

test_invalid_options() {
    cd "$SCRIPT_DIR/src"
    . ./generate.sh
    local output

    output=$(run_generate --invalid-option 2>&1 || true)
    echo "$output" | grep -q 'Unknown option'
    assert_success "[ $? -eq 0 ]" "Invalid option shows error"
}

run_all_tests() {
    echo "🚀 Starting tests for generate.sh"
    echo "=================================="
    run_test "Test help output" test_help_output
    run_test "Test missing required arguments" test_missing_required_arguments
    run_test "Test invalid paths" test_invalid_paths
    run_test "Test output directory creation" test_output_directory_creation
    run_test "Test invalid options" test_invalid_options
    cleanup_temp_files
    test_summary
}

if [ "${0##*/}" = "test_generate.sh" ]; then
    run_all_tests
fi 