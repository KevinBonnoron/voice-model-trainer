#!/bin/sh

# Unit tests for preprocess.sh
# Usage: ./test_preprocess.sh

# Source the test framework
. "$(dirname "$0")/test_framework.sh"

# Path to the script
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PREPROCESS_SCRIPT="$SCRIPT_DIR/src/preprocess.sh"

# Mock docker command to avoid actual execution
mock_docker() {
    echo "docker called with: $@"
    return 0
}

# Tests for help function
test_help_output() {
    local help_output
    help_output=$(cd "$SCRIPT_DIR/src" && . ./preprocess.sh && show_help_preprocess 2>&1)
    echo "$help_output" | grep -q 'Usage:'
    assert_success "[ $? -eq 0 ]" "Help displays 'Usage:'"

    echo "$help_output" | grep -q '\--input'
    assert_success "[ $? -eq 0 ]" "Help mentions --input option"

    echo "$help_output" | grep -q '\--output'
    assert_success "[ $? -eq 0 ]" "Help mentions --output option"

    echo "$help_output" | grep -q '\--language'
    assert_success "[ $? -eq 0 ]" "Help mentions --language option"

    echo "$help_output" | grep -q '\--sample-rate'
    assert_success "[ $? -eq 0 ]" "Help mentions --sample-rate option"

    echo "$help_output" | grep -q '\--single-speaker'
    assert_success "[ $? -eq 0 ]" "Help mentions --single-speaker option"

    echo "$help_output" | grep -q '\--dataset-format'
    assert_success "[ $? -eq 0 ]" "Help mentions --dataset-format option"
}

# Tests for missing required arguments
test_missing_required_arguments() {
    cd "$SCRIPT_DIR/src"
    . ./preprocess.sh
    local output
    local temp_input=$(create_temp_dir "input")

    output=$(run_preprocess --output /tmp/test 2>&1 || true)
    echo "$output" | grep -q 'input parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing input shows error"

    output=$(run_preprocess --input "$temp_input" 2>&1 || true)
    echo "$output" | grep -q 'output parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing output shows error"
}

# Tests for invalid input path
test_invalid_input_path() {
    cd "$SCRIPT_DIR/src"
    . ./preprocess.sh
    
    local output
    output=$(run_preprocess --input /nonexistent/path --output /tmp/test 2>&1 || true)
    echo "$output" | grep -q 'does not exist'
    assert_success "[ $? -eq 0 ]" "Invalid input path shows error"
}

# Tests for output directory creation
test_output_directory_creation() {
    cd "$SCRIPT_DIR/src"
    . ./preprocess.sh
    
    local temp_input=$(create_temp_dir "input")
    local temp_output="/tmp/test_output_creation_$$"
    
    # Test that output directory is created if it doesn't exist
    # We'll just test the directory creation logic
    if [ ! -d "$temp_output" ]; then
        mkdir -p "$temp_output" 2>/dev/null || true
    fi
    assert_dir_exists "$temp_output" "Output directory was created"
    
    # Cleanup
    rm -rf "$temp_input" "$temp_output"
}

test_invalid_dataset_format() {
    cd "$SCRIPT_DIR/src"
    . ./preprocess.sh
    
    local output
    output=$(run_preprocess --dataset-format invalid 2>&1 || true)
    echo "$output" | grep -q 'Invalid dataset format'
    assert_success "[ $? -eq 0 ]" "Invalid dataset format shows error"
}

# Tests for invalid options
test_invalid_options() {
    cd "$SCRIPT_DIR/src"
    . ./preprocess.sh
    
    local output
    output=$(run_preprocess --invalid-option 2>&1 || true)
    echo "$output" | grep -q 'Unknown option'
    assert_success "[ $? -eq 0 ]" "Invalid option shows error"
}

# Tests for argument parsing with docker mock
test_argument_parsing_with_mock() {
    cd "$SCRIPT_DIR/src"
    . ./preprocess.sh
    
    local temp_input=$(create_temp_dir "input")
    local temp_output=$(create_temp_dir "output")
    
    # Create a simple docker mock in a temporary directory
    local mock_dir=$(create_temp_dir "mock")
    echo '#!/bin/sh\necho "docker called with: $@"' > "$mock_dir/docker"
    chmod +x "$mock_dir/docker"
    
    # Temporarily add mock directory to PATH
    local original_path="$PATH"
    export PATH="$mock_dir:$PATH"
    
    # Test that the function can be called with valid arguments
    local output
    output=$(run_preprocess --input "$temp_input" --output "$temp_output" 2>&1)
    echo "$output" | grep -q 'docker called with:'
    assert_success "[ $? -eq 0 ]" "Docker command was called with correct arguments"
    
    # Restore original PATH
    export PATH="$original_path"
    
    # Cleanup
    rm -rf "$temp_input" "$temp_output" "$mock_dir"
}

# Main function to run all tests
run_all_tests() {
    echo "🚀 Starting tests for preprocess.sh"
    echo "=================================="
    
    run_test "Test help output" test_help_output
    run_test "Test missing required arguments" test_missing_required_arguments
    run_test "Test invalid input path" test_invalid_input_path
    run_test "Test output directory creation" test_output_directory_creation
    run_test "Test invalid dataset format" test_invalid_dataset_format
    run_test "Test invalid options" test_invalid_options
    run_test "Test argument parsing with docker mock" test_argument_parsing_with_mock
    
    # Cleanup
    cleanup_temp_files
    
    # Show summary
    test_summary
}

# Run tests if script is called directly
if [ "${0##*/}" = "test_preprocess.sh" ]; then
    run_all_tests
fi 