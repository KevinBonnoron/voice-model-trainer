#!/bin/sh

# Unit tests for metadata.sh
# Usage: ./test_metadata.sh

. "$(dirname "$0")/test_framework.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

test_help_output() {
    local help_output
    help_output=$(cd "$SCRIPT_DIR/src" && . ./metadata.sh && show_help_metadata 2>&1)
    echo "$help_output" | grep -q 'Usage:'
    assert_success "[ $? -eq 0 ]" "Help displays 'Usage:'"

    echo "$help_output" | grep -q '\--input'
    assert_success "[ $? -eq 0 ]" "Help mentions --input option"

    echo "$help_output" | grep -q '\--output'
    assert_success "[ $? -eq 0 ]" "Help mentions --output option"

    echo "$help_output" | grep -q '\--model'
    assert_success "[ $? -eq 0 ]" "Help mentions --model option"

    echo "$help_output" | grep -q '\--language'
    assert_success "[ $? -eq 0 ]" "Help mentions --language option"

    echo "$help_output" | grep -q '\--device'
    assert_success "[ $? -eq 0 ]" "Help mentions --device option"
}

test_missing_required_arguments() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local output

    output=$( (run_metadata --output /tmp/out) 2>&1 || true)
    echo "$output" | grep -q 'input parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing input shows error"

    local temp_dir=$(create_temp_dir "input")
    output=$( (run_metadata --input "$temp_dir") 2>&1 || true)
    echo "$output" | grep -q 'output parameter is required'
    assert_success "[ $? -eq 0 ]" "Missing output shows error"

    rm -rf "$temp_dir"
}

test_invalid_paths() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local output

    output=$(run_metadata --input /tmp/doesnotexist --output /tmp/out 2>&1 || true)
    echo "$output" | grep -q 'does not exist'
    assert_success "[ $? -eq 0 ]" "Invalid input path shows error"
}

test_missing_wavs_directory() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local temp_input=$(create_temp_dir "input")
    local temp_output=$(create_temp_dir "output")

    local output
    output=$(run_metadata --input "$temp_input" --output "$temp_output" 2>&1 || true)
    echo "$output" | grep -q 'wavs.*directory not found'
    assert_success "[ $? -eq 0 ]" "Missing wavs/ directory shows error"

    rm -rf "$temp_input" "$temp_output"
}

test_empty_wavs_directory() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local temp_input=$(create_temp_dir "input")
    mkdir -p "$temp_input/wavs"
    local temp_output=$(create_temp_dir "output")

    local output
    output=$(run_metadata --input "$temp_input" --output "$temp_output" 2>&1 || true)
    echo "$output" | grep -q 'no .wav files found'
    assert_success "[ $? -eq 0 ]" "Empty wavs/ directory shows error"

    rm -rf "$temp_input" "$temp_output"
}

test_output_directory_creation() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local temp_input=$(create_temp_dir "input")
    mkdir -p "$temp_input/wavs"
    local temp_output="/tmp/test_metadata_output_$$"
    if [ -d "$temp_output" ]; then rm -rf "$temp_output"; fi
    ( run_metadata --input "$temp_input" --output "$temp_output" 2>/dev/null ) || true
    assert_dir_exists "$temp_output" "Output directory was created"
    rm -rf "$temp_input" "$temp_output"
}

test_invalid_options() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local output

    output=$(run_metadata --invalid-option 2>&1 || true)
    echo "$output" | grep -q 'Unknown option'
    assert_success "[ $? -eq 0 ]" "Invalid option shows error"
}

test_invalid_model_value() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local output

    output=$(run_metadata --model invalid 2>&1 || true)
    echo "$output" | grep -q 'Invalid model'
    assert_success "[ $? -eq 0 ]" "Invalid model value shows error"
}

test_invalid_device_value() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local output

    output=$(run_metadata --device tpu 2>&1 || true)
    echo "$output" | grep -q 'Invalid device'
    assert_success "[ $? -eq 0 ]" "Invalid device value shows error"
}

test_all_transcriptions_present() {
    cd "$SCRIPT_DIR/src"
    . ./metadata.sh
    local temp_input=$(create_temp_dir "input")
    local temp_output=$(create_temp_dir "output")
    mkdir -p "$temp_input/wavs"

    # Create dummy wav files
    touch "$temp_input/wavs/001.wav"
    touch "$temp_input/wavs/002.wav"

    # Create complete metadata.csv
    printf "001.wav|Hello world\n002.wav|Goodbye world\n" > "$temp_input/metadata.csv"

    local output
    output=$(run_metadata --input "$temp_input" --output "$temp_output" 2>&1)
    echo "$output" | grep -q 'nothing to transcribe'
    assert_success "[ $? -eq 0 ]" "All transcriptions present skips Whisper"

    assert_file_exists "$temp_output/metadata.csv" "Output metadata.csv was created"

    rm -rf "$temp_input" "$temp_output"
}

run_all_tests() {
    echo "🚀 Starting tests for metadata.sh"
    echo "=================================="
    run_test "Test help output" test_help_output
    run_test "Test missing required arguments" test_missing_required_arguments
    run_test "Test invalid paths" test_invalid_paths
    run_test "Test missing wavs directory" test_missing_wavs_directory
    run_test "Test empty wavs directory" test_empty_wavs_directory
    run_test "Test output directory creation" test_output_directory_creation
    run_test "Test invalid options" test_invalid_options
    run_test "Test invalid model value" test_invalid_model_value
    run_test "Test invalid device value" test_invalid_device_value
    run_test "Test all transcriptions present" test_all_transcriptions_present
    cleanup_temp_files
    test_summary
}

if [ "${0##*/}" = "test_metadata.sh" ]; then
    run_all_tests
fi
