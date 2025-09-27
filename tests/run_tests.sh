#!/usr/bin/env bash

# HyprSnap Test Suite
# This script runs various tests to verify core functionality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Print with color
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Test function
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    
    ((TESTS_RUN++))
    print_color "$YELLOW" "\nRunning test: $test_name"
    
    if eval "$test_cmd"; then
        print_color "$GREEN" "✓ Test passed: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        print_color "$RED" "✗ Test failed: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Environment tests
test_environment() {
    # Test Wayland session
    run_test "Wayland Session Check" '
        [[ "$XDG_SESSION_TYPE" == "wayland" ]] || 
        { echo "Error: Not running in Wayland session"; exit 1; }
    '
    
    # Test dependencies
    run_test "Dependencies Check" '
        deps=("wf-recorder" "ffmpeg" "slurp" "dunst")
        missing=()
        for dep in "${deps[@]}"; do
            command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
        done
        [ ${#missing[@]} -eq 0 ] || 
        { echo "Missing dependencies: ${missing[*]}"; exit 1; }
    '
}

# Configuration tests
test_configuration() {
    # Test config directory
    run_test "Config Directory Check" '
        config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hyprsnap"
        [ -d "$config_dir" ] || mkdir -p "$config_dir"
    '
    
    # Test config file
    run_test "Config File Check" '
        config_file="${XDG_CONFIG_HOME:-$HOME/.config}/hyprsnap/config.yaml"
        [ -f "$config_file" ] || touch "$config_file"
    '
}

# Functionality tests
test_functionality() {
    # Test help output
    run_test "Help Command" '
        ../hyprsnap.sh --help 2>&1 | grep -q "Usage:"
    '
    
    # Test version output
    run_test "Version Command" '
        ../hyprsnap.sh --version 2>&1 | grep -q "HyprSnap v"
    '
}

# Performance tests
test_performance() {
    # Test temporary directory cleanup
    run_test "Temp Directory Cleanup" '
        temp_dir="/tmp/hyprsnap"
        [ ! -d "$temp_dir" ] || rm -rf "$temp_dir"
        mkdir -p "$temp_dir"
        touch "$temp_dir/test_file"
        ../hyprsnap.sh cleanup 2>/dev/null || true
        [ ! -f "$temp_dir/test_file" ]
    '
}

# Run all tests
main() {
    print_color "$YELLOW" "Starting HyprSnap test suite..."
    
    # Run test categories
    test_environment
    test_configuration
    test_functionality
    test_performance
    
    # Print summary
    echo
    print_color "$YELLOW" "Test Summary:"
    print_color "$GREEN" "✓ Passed: $TESTS_PASSED"
    print_color "$RED" "✗ Failed: $TESTS_FAILED"
    echo "Total tests: $TESTS_RUN"
    
    # Exit with failure if any tests failed
    [ "$TESTS_FAILED" -eq 0 ]
}

# Run main function
main "$@" 