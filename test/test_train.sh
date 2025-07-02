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

    echo "$help_output" | grep -q '\--dataset-dir'
    assert_success "[ $? -eq 0 ]" "Help mentions --dataset-dir option"

    echo "$help_output" | grep -q '\--accelerator'
    assert_success "[ $? -eq 0 ]" "Help mentions --accelerator option"

    echo "$help_output" | grep -q '\--devices'
    assert_success "[ $? -eq 0 ]" "Help mentions --devices option"

    echo "$help_output" | grep -q '\--validation-split'
    assert_success "[ $? -eq 0 ]" "Help mentions --validation-split option"

    echo "$help_output" | grep -q '\--batch-size'
    assert_success "[ $? -eq 0 ]" "Help mentions --batch-size option"

    echo "$help_output" | grep -q '\--max-epochs'
    assert_success "[ $? -eq 0 ]" "Help mentions --max-epochs option"

    echo "$help_output" | grep -q '\--precision'
    assert_success "[ $? -eq 0 ]" "Help mentions --precision option"

    echo "$help_output" | grep -q '\--quality'
    assert_success "[ $? -eq 0 ]" "Help mentions --quality option"

    echo "$help_output" | grep -q '\--resume-from-checkpoint'
    assert_success "[ $? -eq 0 ]" "Help mentions --resume-from-checkpoint option"
}

test_missing_required_arguments() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local output

    output=$(run_train --accelerator gpu 2>&1 || true)
    echo "$output" | grep -q 'dataset-dir parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing dataset-dir shows error"
}

test_invalid_paths() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local output

    output=$(run_train --dataset-dir /tmp/doesnotexist 2>&1 || true)
    echo "$output" | grep -q 'does not exist'
    assert_success "[ $? -eq 0 ]" "Invalid dataset-dir path shows error"
}

test_invalid_enum_values() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local temp_dir=$(create_temp_dir "dataset")
    local output

    output=$(run_train --dataset-dir "$temp_dir" --accelerator potato 2>&1 || true)
    echo "$output" | grep -q 'Invalid accelerator'
    assert_success "[ $? -eq 0 ]" "Invalid accelerator value shows error"

    output=$(run_train --dataset-dir "$temp_dir" --precision 99 2>&1 || true)
    echo "$output" | grep -q 'Invalid precision'
    assert_success "[ $? -eq 0 ]" "Invalid precision value shows error"

    output=$(run_train --dataset-dir "$temp_dir" --quality ultra 2>&1 || true)
    echo "$output" | grep -q 'Invalid quality'
    assert_success "[ $? -eq 0 ]" "Invalid quality value shows error"

    rm -rf "$temp_dir"
}

test_invalid_options() {
    cd "$SCRIPT_DIR/src"
    . ./train.sh
    local temp_dir=$(create_temp_dir "dataset")
    local output

    output=$(run_train --dataset-dir "$temp_dir" --invalid-option 2>&1 || true)
    echo "$output" | grep -q 'Unknown option'
    assert_success "[ $? -eq 0 ]" "Invalid option shows error"

    rm -rf "$temp_dir"
}

run_all_tests() {
    echo "🚀 Starting tests for train.sh"
    echo "=================================="
    run_test "Test help output" test_help_output
    run_test "Test missing required arguments" test_missing_required_arguments
    run_test "Test invalid paths" test_invalid_paths
    run_test "Test invalid enum values" test_invalid_enum_values
    run_test "Test invalid options" test_invalid_options
    cleanup_temp_files
    test_summary
}

if [ "${0##*/}" = "test_train.sh" ]; then
    run_all_tests
fi 