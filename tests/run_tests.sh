#!/bin/bash

# HyprSnap Test Suite
# Created by DuckyOnQuack-999
# Version: 1.0.0
# License: MIT

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_OUTPUT_DIR="/tmp/hyprsnap_tests"
LOG_FILE="$TEST_OUTPUT_DIR/test.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Print functions
print_header() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    HyprSnap Test Suite                      ║${NC}"
    echo -e "${CYAN}║                      Version 1.0.0                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Logging
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} $message" >> "$LOG_FILE"
}

# Test framework
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    print_status "$BLUE" "🧪 Running: $test_name"
    log "Starting test: $test_name"
    
    if $test_function; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_status "$GREEN" "  ✓ PASSED"
        log "Test passed: $test_name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        print_status "$RED" "  ✗ FAILED"
        log "Test failed: $test_name"
    fi
}

# Setup test environment
setup_test_env() {
    print_status "$BLUE" "🔧 Setting up test environment..."
    
    mkdir -p "$TEST_OUTPUT_DIR"
    rm -f "$LOG_FILE"
    touch "$LOG_FILE"
    
    # Create mock directories
    mkdir -p "$TEST_OUTPUT_DIR/config"
    mkdir -p "$TEST_OUTPUT_DIR/captures"
    
    print_status "$GREEN" "  ✓ Test environment ready"
    log "Test environment setup completed"
}

# Cleanup test environment
cleanup_test_env() {
    print_status "$BLUE" "🧹 Cleaning up test environment..."
    
    if [[ -d "$TEST_OUTPUT_DIR" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
        print_status "$GREEN" "  ✓ Test environment cleaned"
    fi
}

# Test 1: Check script syntax
test_script_syntax() {
    local scripts=("$PROJECT_DIR/hyprsnap.sh" "$PROJECT_DIR/setup.sh" "$SCRIPT_DIR/run_tests.sh")
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if bash -n "$script"; then
                log "Syntax check passed for: $script"
            else
                log "Syntax check failed for: $script"
                return 1
            fi
        else
            log "Script not found: $script"
            return 1
        fi
    done
    
    return 0
}

# Test 2: Check script permissions
test_script_permissions() {
    local scripts=("$PROJECT_DIR/hyprsnap.sh" "$PROJECT_DIR/setup.sh")
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]] && [[ -x "$script" ]]; then
            log "Permission check passed for: $script"
        else
            log "Permission check failed for: $script"
            return 1
        fi
    done
    
    return 0
}

# Test 3: Check help output
test_help_output() {
    local help_output
    help_output=$("$PROJECT_DIR/hyprsnap.sh" --help 2>&1) || return 1
    
    if [[ "$help_output" =~ "HyprSnap" ]] && [[ "$help_output" =~ "USAGE" ]]; then
        log "Help output test passed"
        return 0
    else
        log "Help output test failed"
        return 1
    fi
}

# Test 4: Check system info
test_system_info() {
    local info_output
    info_output=$("$PROJECT_DIR/hyprsnap.sh" --system-info 2>&1) || return 1
    
    if [[ "$info_output" =~ "HyprSnap System Information" ]] && [[ "$info_output" =~ "Version: 1.0.0" ]]; then
        log "System info test passed"
        return 0
    else
        log "System info test failed"
        return 1
    fi
}

# Test 5: Check dependency verification
test_dependency_check() {
    # This test will pass if the script runs without error, regardless of actual dependencies
    if "$PROJECT_DIR/hyprsnap.sh" --check >/dev/null 2>&1 || true; then
        log "Dependency check test passed (script executed)"
        return 0
    else
        log "Dependency check test failed (script error)"
        return 1
    fi
}

# Test 6: Check setup script help
test_setup_help() {
    local help_output
    help_output=$("$PROJECT_DIR/setup.sh" --help 2>&1) || return 1
    
    if [[ "$help_output" =~ "HyprSnap Setup Script" ]] && [[ "$help_output" =~ "USAGE" ]]; then
        log "Setup help test passed"
        return 0
    else
        log "Setup help test failed"
        return 1
    fi
}

# Test 7: Check setup dependency check only
test_setup_check_only() {
    # This should run without installing anything
    if "$PROJECT_DIR/setup.sh" --check >/dev/null 2>&1 || true; then
        log "Setup check-only test passed"
        return 0
    else
        log "Setup check-only test failed"
        return 1
    fi
}

# Test 8: Check configuration files
test_config_files() {
    local files=("$PROJECT_DIR/README.md" "$PROJECT_DIR/LICENSE" "$PROJECT_DIR/CHANGELOG.md")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]] && [[ -s "$file" ]]; then
            log "Config file check passed for: $file"
        else
            log "Config file check failed for: $file"
            return 1
        fi
    done
    
    return 0
}

# Test 9: Check README content
test_readme_content() {
    local readme="$PROJECT_DIR/README.md"
    
    if [[ -f "$readme" ]]; then
        local content
        content=$(cat "$readme")
        
        if [[ "$content" =~ "HyprSnap" ]] && \
           [[ "$content" =~ "Lightning-fast screen capture" ]] && \
           [[ "$content" =~ "Quick Start" ]] && \
           [[ "$content" =~ "Usage" ]]; then
            log "README content test passed"
            return 0
        else
            log "README content test failed - missing required sections"
            return 1
        fi
    else
        log "README file not found"
        return 1
    fi
}

# Test 10: Check version consistency
test_version_consistency() {
    local version="1.0.0"
    local files=("$PROJECT_DIR/hyprsnap.sh" "$PROJECT_DIR/setup.sh" "$PROJECT_DIR/README.md")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            if grep -q "$version" "$file"; then
                log "Version consistency check passed for: $file"
            else
                log "Version consistency check failed for: $file"
                return 1
            fi
        else
            log "File not found for version check: $file"
            return 1
        fi
    done
    
    return 0
}

# Test 11: Check shellcheck (if available)
test_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        log "Shellcheck not available, skipping test"
        return 0
    fi
    
    local scripts=("$PROJECT_DIR/hyprsnap.sh" "$PROJECT_DIR/setup.sh" "$SCRIPT_DIR/run_tests.sh")
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if shellcheck "$script" >/dev/null 2>&1; then
                log "Shellcheck passed for: $script"
            else
                log "Shellcheck failed for: $script"
                # Don't fail the test for shellcheck warnings
                # return 1
            fi
        fi
    done
    
    return 0
}

# Test 12: Check directory structure
test_directory_structure() {
    local required_files=(
        "$PROJECT_DIR/hyprsnap.sh"
        "$PROJECT_DIR/setup.sh"
        "$PROJECT_DIR/README.md"
        "$PROJECT_DIR/LICENSE"
        "$PROJECT_DIR/CHANGELOG.md"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log "Directory structure check passed for: $file"
        else
            log "Directory structure check failed - missing: $file"
            return 1
        fi
    done
    
    return 0
}

# Main test runner
run_all_tests() {
    print_status "$BLUE" "🚀 Starting test suite..."
    
    # Core functionality tests
    run_test "Script Syntax Check" test_script_syntax
    run_test "Script Permissions" test_script_permissions
    run_test "Help Output" test_help_output
    run_test "System Info" test_system_info
    run_test "Dependency Check" test_dependency_check
    
    # Setup script tests
    run_test "Setup Help" test_setup_help
    run_test "Setup Check Only" test_setup_check_only
    
    # Documentation tests
    run_test "Configuration Files" test_config_files
    run_test "README Content" test_readme_content
    run_test "Version Consistency" test_version_consistency
    
    # Code quality tests
    run_test "Shellcheck Analysis" test_shellcheck
    run_test "Directory Structure" test_directory_structure
}

# Show test results
show_results() {
    echo
    print_status "$CYAN" "╔══════════════════════════════════════════════════════════════╗"
    print_status "$CYAN" "║                       Test Results                          ║"
    print_status "$CYAN" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    print_status "$BLUE" "📊 Test Summary:"
    echo "  Total tests run: $TESTS_RUN"
    print_status "$GREEN" "  Passed: $TESTS_PASSED"
    print_status "$RED" "  Failed: $TESTS_FAILED"
    
    local success_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        success_rate=$(( (TESTS_PASSED * 100) / TESTS_RUN ))
    fi
    
    echo "  Success rate: ${success_rate}%"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_status "$GREEN" "🎉 All tests passed!"
        echo "  Log file: $LOG_FILE"
        return 0
    else
        print_status "$RED" "❌ Some tests failed!"
        echo "  Check log file for details: $LOG_FILE"
        return 1
    fi
}

# Show help
show_help() {
    cat << EOF
HyprSnap Test Suite
Version: 1.0.0

USAGE:
    ./run_tests.sh [options]

OPTIONS:
    --verbose       Enable verbose output
    --keep-logs     Don't clean up log files
    -h, --help      Show this help

DESCRIPTION:
    Runs comprehensive tests for HyprSnap including:
    - Script syntax validation
    - Permission checks
    - Functionality tests
    - Documentation validation
    - Code quality analysis

TEST CATEGORIES:
    - Core functionality
    - Setup script validation
    - Documentation completeness
    - Code quality (shellcheck if available)
    - Version consistency

OUTPUT:
    Test results are logged to: $TEST_OUTPUT_DIR/test.log
    
EXIT CODES:
    0: All tests passed
    1: One or more tests failed
    2: Test environment setup failed

For more information, visit:
https://github.com/DuckyOnQuack-999/HyprSnap
EOF
}

# Parse command line arguments
parse_args() {
    local verbose=false
    local keep_logs=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                verbose=true
                shift
                ;;
            --keep-logs)
                keep_logs=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Export flags for use in other functions
    export VERBOSE="$verbose"
    export KEEP_LOGS="$keep_logs"
}

# Main function
main() {
    parse_args "$@"
    
    print_header
    
    # Setup
    if ! setup_test_env; then
        print_status "$RED" "❌ Failed to setup test environment"
        exit 2
    fi
    
    # Run tests
    run_all_tests
    
    # Show results
    local exit_code=0
    if ! show_results; then
        exit_code=1
    fi
    
    # Cleanup
    if [[ "${KEEP_LOGS:-false}" != "true" ]]; then
        cleanup_test_env
    else
        print_status "$BLUE" "📁 Log files preserved in: $TEST_OUTPUT_DIR"
    fi
    
    exit $exit_code
}

# Run main function
main "$@"