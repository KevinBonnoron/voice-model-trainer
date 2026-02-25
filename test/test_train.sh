#!/bin/sh

# Unit tests for train.sh
# Usage: ./test_train.sh

. "$(dirname "$0")/test_framework.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

test_help_output() {
    local help_output
    help_output=$(cd "$SCRIPT_DIR/src" && . ./train.sh && show_help_train 2>&1)
    echo "$help_output" | grep -q 'Usage:'
    assert_success "[ $? -eq 0 ]" "Help displays 'Usage:'"

    echo "$help_output" | grep -q '\--input'
    assert_success "[ $? -eq 0 ]" "Help mentions --input option"

    echo "$help_output" | grep -q '\--output'
    assert_success "[ $? -eq 0 ]" "Help mentions --output option"

    echo "$help_output" | grep -q '\--voice-name'
    assert_success "[ $? -eq 0 ]" "Help mentions --voice-name option"

    echo "$help_output" | grep -q '\--espeak-voice'
    assert_success "[ $? -eq 0 ]" "Help mentions --espeak-voice option"

    echo "$help_output" | grep -q '\--sample-rate'
    assert_success "[ $? -eq 0 ]" "Help mentions --sample-rate option"

    echo "$help_output" | grep -q '\--accelerator'
    assert_success "[ $? -eq 0 ]" "Help mentions --accelerator option"

    echo "$help_output" | grep -q '\--devices'
    assert_success "[ $? -eq 0 ]" "Help mentions --devices option"

    echo "$help_output" | grep -q '\--validation-split'
    assert_success "[ $? -eq 0 ]" "Help mentions --validation-split option"

    echo "$help_output" | grep -q '\--batch-size'
    assert_success "[ $? -eq 0 ]" "Help mentions --batch-size option"

    echo "$help_output" | grep -q '\--num-workers'
    assert_success "[ $? -eq 0 ]" "Help mentions --num-workers option"

    echo "$help_output" | grep -q '\--max-epochs'
    assert_success "[ $? -eq 0 ]" "Help mentions --max-epochs option"

    echo "$help_output" | grep -q '\--precision'
    assert_success "[ $? -eq 0 ]" "Help mentions --precision option"

    echo "$help_output" | grep -q '\--resume-from-checkpoint'
    assert_success "[ $? -eq 0 ]" "Help mentions --resume-from-checkpoint option"
}

test_missing_required_arguments() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local output

    output=$(run_train --accelerator gpu 2>&1 || true)
    echo "$output" | grep -q 'input parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing input shows error"

    local temp_dir=$(create_temp_dir "input")
    output=$(run_train --input "$temp_dir" 2>&1 || true)
    echo "$output" | grep -q 'output parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing output shows error"

    local temp_output=$(create_temp_dir "output")
    output=$(run_train --input "$temp_dir" --output "$temp_output" 2>&1 || true)
    echo "$output" | grep -q 'voice-name parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing voice-name shows error"

    rm -rf "$temp_dir" "$temp_output"
}

test_invalid_paths() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local output

    output=$(run_train --input /tmp/doesnotexist 2>&1 || true)
    echo "$output" | grep -q 'does not exist'
    assert_success "[ $? -eq 0 ]" "Invalid input path shows error"
}

test_invalid_enum_values() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local temp_dir=$(create_temp_dir "input")
    local output

    output=$(run_train --input "$temp_dir" --accelerator potato 2>&1 || true)
    echo "$output" | grep -q 'Invalid accelerator'
    assert_success "[ $? -eq 0 ]" "Invalid accelerator value shows error"

    output=$(run_train --input "$temp_dir" --precision 99 2>&1 || true)
    echo "$output" | grep -q 'Invalid precision'
    assert_success "[ $? -eq 0 ]" "Invalid precision value shows error"

    rm -rf "$temp_dir"
}

test_invalid_options() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local temp_dir=$(create_temp_dir "input")
    local output

    output=$(run_train --input "$temp_dir" --invalid-option 2>&1 || true)
    echo "$output" | grep -q 'Unknown option'
    assert_success "[ $? -eq 0 ]" "Invalid option shows error"

    rm -rf "$temp_dir"
}

test_output_directory_creation() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local temp_input=$(create_temp_dir "input")
    local temp_output="/tmp/test_train_output_$$"
    if [ -d "$temp_output" ]; then rm -rf "$temp_output"; fi
    ( run_train --input "$temp_input" --output "$temp_output" --voice-name test 2>/dev/null ) || true
    assert_dir_exists "$temp_output" "Output directory was created"
    rm -rf "$temp_input" "$temp_output"
}

run_all_tests() {
    echo "🚀 Starting tests for train.sh"
    echo "=================================="
    run_test "Test help output" test_help_output
    run_test "Test missing required arguments" test_missing_required_arguments
    run_test "Test invalid paths" test_invalid_paths
    run_test "Test invalid enum values" test_invalid_enum_values
    run_test "Test invalid options" test_invalid_options
    run_test "Test output directory creation" test_output_directory_creation
    cleanup_temp_files
    test_summary
}

if [ "${0##*/}" = "test_train.sh" ]; then
    run_all_tests
fi
