#!/usr/bin/env bash

# HyprSnap Dependency Installation Script
# Installs both Python and system dependencies

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_color "$RED" "This script should not be run as root"
        exit 1
    fi
}

# Install Python dependencies
install_python_deps() {
    print_color "$BLUE" "Installing Python dependencies..."
    
    # Check if pip is available
    if ! command -v pip3 >/dev/null 2>&1; then
        print_color "$YELLOW" "pip3 not found, installing..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y python3-pip
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed python-pip
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y python3-pip
        else
            print_color "$RED" "Cannot install pip3 automatically. Please install it manually."
            exit 1
        fi
    fi
    
    # Install Python packages
    pip3 install -r requirements.txt --user
    
    print_color "$GREEN" "Python dependencies installed successfully"
}

# Install system dependencies
install_system_deps() {
    print_color "$BLUE" "Installing system dependencies..."
    
    # Detect distribution
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            arch|manjaro)
                print_color "$GREEN" "Detected Arch-based distribution"
                sudo pacman -S --needed \
                    yq jq grim slurp wf-recorder ffmpeg imagemagick \
                    optipng jpegoptim libwebp gifsicle \
                    python-pip python-yaml python-markdown \
                    python-pillow python-requests python-flask \
                    python-flask-cors python-websockets
                ;;
            ubuntu|debian)
                print_color "$GREEN" "Detected Debian-based distribution"
                sudo apt update
                sudo apt install -y \
                    yq jq grim slurp wf-recorder ffmpeg imagemagick \
                    optipng jpegoptim webp gifsicle \
                    python3-pip python3-yaml python3-markdown \
                    python3-pil python3-requests python3-flask \
                    python3-flask-cors python3-websockets \
                    libmagic1 python3-magic
                ;;
            fedora)
                print_color "$GREEN" "Detected Fedora"
                sudo dnf install -y \
                    yq jq grim slurp wf-recorder ffmpeg ImageMagick \
                    optipng jpegoptim libwebp gifsicle \
                    python3-pip python3-PyYAML python3-markdown \
                    python3-Pillow python3-requests python3-flask \
                    python3-flask-cors python3-websockets \
                    file-libs python3-magic
                ;;
            *)
                print_color "$YELLOW" "Unsupported distribution: $ID"
                print_color "$YELLOW" "Please install the following packages manually:"
                echo "  - yq, jq (YAML/JSON processors)"
                echo "  - grim, slurp (Wayland screenshot tools)"
                echo "  - wf-recorder (Wayland screen recorder)"
                echo "  - ffmpeg (video processing)"
                echo "  - imagemagick (image processing)"
                echo "  - optipng, jpegoptim, libwebp, gifsicle (optimization tools)"
                echo "  - Python packages from requirements.txt"
                ;;
        esac
    else
        print_color "$RED" "Cannot detect distribution. Please install dependencies manually."
        exit 1
    fi
    
    print_color "$GREEN" "System dependencies installed successfully"
}

# Verify installation
verify_installation() {
    print_color "$BLUE" "Verifying installation..."
    
    local missing=()
    
    # Check Python modules
    python3 -c "
import sys
modules = ['chardet', 'magic', 'markdown', 'yaml', 'PIL', 'requests', 'flask', 'flask_cors', 'websockets']
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
" || missing+=("Python modules")
    
    # Check system tools
    local tools=("yq" "jq" "grim" "slurp" "wf-recorder" "ffmpeg" "convert" "optipng" "jpegoptim" "cwebp" "gifsicle")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_color "$GREEN" "All dependencies verified successfully!"
        return 0
    else
        print_color "$RED" "Missing dependencies: ${missing[*]}"
        return 1
    fi
}

# Main installation process
main() {
    print_color "$GREEN" "Starting HyprSnap dependency installation..."
    
    check_root
    install_python_deps
    install_system_deps
    
    if verify_installation; then
        print_color "$GREEN" "Installation completed successfully!"
        print_color "$BLUE" "You can now run HyprSnap with: ./hyprsnap.sh"
    else
        print_color "$RED" "Installation completed with errors. Please check missing dependencies."
        exit 1
    fi
}

# Run main installation
main "$@"