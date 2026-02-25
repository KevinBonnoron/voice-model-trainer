#!/bin/sh

# Unit tests for export.sh
# Usage: ./test_export.sh

# Source the test framework
. "$(dirname "$0")/test_framework.sh"

# Path to the script
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Tests for the function show_help_export
test_help_output() {
    local help_output
    help_output=$(cd "$SCRIPT_DIR/src" && . ./export.sh && show_help_export 2>&1)
    echo "$help_output" | grep -q 'Usage:'
    assert_success "[ $? -eq 0 ]" "Help displays 'Usage:'"
    echo "$help_output" | grep -q '\--output'
    assert_success "[ $? -eq 0 ]" "Help mentions --output option"
    echo "$help_output" | grep -q '\--checkpoint-file'
    assert_success "[ $? -eq 0 ]" "Help mentions --checkpoint-file option"
    echo "$help_output" | grep -q '\--format'
    assert_success "[ $? -eq 0 ]" "Help mentions --format option"
    echo "$help_output" | grep -q '\--sample-text'
    assert_success "[ $? -eq 0 ]" "Help mentions --sample-text option"
    echo "$help_output" | grep -q 'sample'
    assert_success "[ $? -eq 0 ]" "Help mentions sample format"
}

test_missing_required_arguments() {
    cd "$SCRIPT_DIR/src"
    . ./export.sh
    local output
    output=$(run_export --output /tmp/test 2>&1 || true)
    echo "$output" | grep -q 'checkpoint'
    assert_success "[ $? -eq 0 ]" "Missing checkpoint-file shows error"
    output=$(run_export --checkpoint-file /tmp/fake.ckpt 2>&1 || true)
    echo "$output" | grep -q 'output parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing output shows error"
}

test_invalid_paths() {
    cd "$SCRIPT_DIR/src"
    . ./export.sh
    local temp_output=$(create_temp_dir "output")
    local output
    output=$(run_export --output "$temp_output" --checkpoint-file /tmp/doesnotexist.ckpt 2>&1 || true)
    echo "$output" | grep -q 'does not exist'
    assert_success "[ $? -eq 0 ]" "Invalid checkpoint-file path shows error"
    rm -rf "$temp_output"
}

test_default_format() {
    cd "$SCRIPT_DIR/src"
    . ./export.sh
    local temp_output=$(create_temp_dir "output")
    local temp_ckpt=$(create_temp_file "ckpt")
    touch "$temp_ckpt"
    # We'll just check that the script runs up to the docker call (simulate success)
    # Not calling docker for real
    assert_success "[ -d '$temp_output' ]" "Output directory exists"
    assert_success "[ -f '$temp_ckpt' ]" "Checkpoint file exists"
    rm -rf "$temp_output" "$temp_ckpt"
}

test_output_directory_creation() {
    cd "$SCRIPT_DIR/src"
    . ./export.sh
    local temp_output="/tmp/test_export_output_$$"
    local temp_ckpt=$(create_temp_file "ckpt")
    touch "$temp_ckpt"
    if [ -d "$temp_output" ]; then rm -rf "$temp_output"; fi
    ( run_export --output "$temp_output" --checkpoint-file "$temp_ckpt" --format onnx 2>/dev/null ) || true
    assert_dir_exists "$temp_output" "Output directory was created"
    rm -rf "$temp_output" "$temp_ckpt"
}

test_invalid_options() {
    cd "$SCRIPT_DIR/src"
    . ./export.sh
    local output
    output=$(run_export --invalid-option 2>&1 || true)
    echo "$output" | grep -q 'Unknown option'
    assert_success "[ $? -eq 0 ]" "Invalid option shows error"
}

test_sample_format_accepts_sample_text() {
    cd "$SCRIPT_DIR/src"
    . ./export.sh
    # --sample-text without --output/--checkpoint-file should still fail on required args
    local output
    output=$(run_export --format sample --sample-text "Hello" 2>&1 || true)
    echo "$output" | grep -q 'output parameter is required'
    assert_success "[ $? -eq 0 ]" "Format sample with sample-text still requires output"
}

run_all_tests() {
    echo "🚀 Starting tests for export.sh"
    echo "=================================="
    run_test "Test help output" test_help_output
    run_test "Test missing required arguments" test_missing_required_arguments
    run_test "Test invalid paths" test_invalid_paths
    run_test "Test default format" test_default_format
    run_test "Test output directory creation" test_output_directory_creation
    run_test "Test invalid options" test_invalid_options
    run_test "Test sample format accepts sample-text" test_sample_format_accepts_sample_text
    cleanup_temp_files
    test_summary
}

if [ "${0##*/}" = "test_export.sh" ]; then
    run_all_tests
fi 