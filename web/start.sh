#!/usr/bin/env bash

# HyprSnap Web Interface Startup Script

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

# Check if we're in the right directory
if [[ ! -f "app.py" ]]; then
    print_color "$RED" "Error: app.py not found. Please run this script from the web directory."
    exit 1
fi

# Check Python dependencies
check_python_deps() {
    local missing=()
    
    python3 -c "
import sys
modules = ['flask', 'flask_cors']
missing = []
for module in modules:
    try:
        __import__(module)
    except ImportError:
        missing.append(module)
if missing:
    print('Missing Python modules:', ', '.join(missing))
    sys.exit(1)
else:
    print('All Python modules available')
" || {
        print_color "$RED" "Missing Python dependencies. Please install:"
        print_color "$YELLOW" "pip install flask flask-cors"
        exit 1
    }
}

# Check if HyprSnap is available
check_hyprsnap() {
    local hyprsnap_path="../hyprsnap.sh"
    if [[ ! -f "$hyprsnap_path" ]]; then
        print_color "$RED" "Error: hyprsnap.sh not found at $hyprsnap_path"
        exit 1
    fi
    
    if [[ ! -x "$hyprsnap_path" ]]; then
        print_color "$YELLOW" "Making hyprsnap.sh executable..."
        chmod +x "$hyprsnap_path"
    fi
}

# Main startup
main() {
    print_color "$GREEN" "Starting HyprSnap Web Interface..."
    
    check_python_deps
    check_hyprsnap
    
    print_color "$BLUE" "Web interface will be available at: http://localhost:5000"
    print_color "$BLUE" "Press Ctrl+C to stop the server"
    
    # Start the web server
    python3 app.py --host 0.0.0.0 --port 5000
}

# Run main function
main "$@"