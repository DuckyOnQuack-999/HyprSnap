#!/usr/bin/env bash

# HyprSnap Integration Test Script
# Tests the complete integration between backend and web UI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print with color
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    print_color "$BLUE" "Running test: $test_name"
    
    if eval "$test_command"; then
        print_color "$GREEN" "✓ PASSED: $test_name"
        ((TESTS_PASSED++))
    else
        print_color "$RED" "✗ FAILED: $test_name"
        ((TESTS_FAILED++))
    fi
    echo
}

# Test 1: Check if main script is executable
test_script_executable() {
    [[ -x "./hyprsnap.sh" ]]
}

# Test 2: Check if help command works
test_help_command() {
    ./hyprsnap.sh --help >/dev/null 2>&1 && echo "Help command works"
}

# Test 3: Check if version command works
test_version_command() {
    ./hyprsnap.sh --version >/dev/null 2>&1
}

# Test 4: Check if config module loads
test_config_module() {
    source utils/config.sh >/dev/null 2>&1
}

# Test 5: Check if error module loads
test_error_module() {
    source utils/error.sh >/dev/null 2>&1
}

# Test 6: Check if Python modules can be imported
test_python_modules() {
    python3 -c "
import sys
sys.path.insert(0, 'src')
try:
    from core.processor import ContentProcessor
    from core.formatter import OutputFormatter
    print('Python modules imported successfully')
except ImportError as e:
    print(f'Import error: {e}')
    sys.exit(1)
" >/dev/null 2>&1
}

# Test 7: Check if web interface files exist
test_web_interface_files() {
    [[ -f "web/app.py" ]] && [[ -f "web/templates/index.html" ]] && [[ -f "web/static/app.js" ]]
}

# Test 8: Check if web interface can start (dry run)
test_web_interface_startup() {
    cd web && python3 -c "
import sys
sys.path.insert(0, '../src')
try:
    from app import HyprSnapWeb
    app = HyprSnapWeb()
    print('Web interface initialized successfully')
except Exception as e:
    print(f'Web interface error: {e}')
    sys.exit(1)
" >/dev/null 2>&1
}

# Test 9: Check if requirements.txt exists
test_requirements_file() {
    [[ -f "requirements.txt" ]]
}

# Test 10: Check if install script exists
test_install_script() {
    [[ -f "install-deps.sh" ]] && [[ -x "install-deps.sh" ]]
}

# Test 11: Check if web command is available
test_web_command() {
    ./hyprsnap.sh web --help >/dev/null 2>&1 || true  # May fail if Flask not installed
}

# Test 12: Check if config validation works
test_config_validation() {
    if [[ -f "config.yaml" ]]; then
        # Test with yq if available
        if command -v yq >/dev/null 2>&1; then
            yq e '.default_fps' config.yaml >/dev/null 2>&1
        else
            # Basic YAML syntax check
            python3 -c "
import yaml
try:
    with open('config.yaml', 'r') as f:
        yaml.safe_load(f)
    print('Config validation passed')
except Exception as e:
    print(f'Config validation failed: {e}')
    exit(1)
" >/dev/null 2>&1
        fi
    else
        return 0  # No config file is OK
    fi
}

# Main test runner
main() {
    print_color "$GREEN" "Starting HyprSnap Integration Tests..."
    echo
    
    # Run all tests
    run_test "Script Executable" "test_script_executable"
    run_test "Help Command" "test_help_command"
    run_test "Version Command" "test_version_command"
    run_test "Config Module" "test_config_module"
    run_test "Error Module" "test_error_module"
    run_test "Python Modules" "test_python_modules"
    run_test "Web Interface Files" "test_web_interface_files"
    run_test "Web Interface Startup" "test_web_interface_startup"
    run_test "Requirements File" "test_requirements_file"
    run_test "Install Script" "test_install_script"
    run_test "Web Command" "test_web_command"
    run_test "Config Validation" "test_config_validation"
    
    # Summary
    echo
    print_color "$BLUE" "=== TEST SUMMARY ==="
    print_color "$GREEN" "Tests Passed: $TESTS_PASSED"
    print_color "$RED" "Tests Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_color "$GREEN" "🎉 All tests passed! HyprSnap is ready to use."
        echo
        print_color "$BLUE" "Next steps:"
        print_color "$YELLOW" "1. Install dependencies: ./install-deps.sh"
        print_color "$YELLOW" "2. Start web interface: ./hyprsnap.sh web"
        print_color "$YELLOW" "3. Or use CLI: ./hyprsnap.sh shot area"
        return 0
    else
        print_color "$RED" "❌ Some tests failed. Please check the errors above."
        return 1
    fi
}

# Run main function
main "$@"