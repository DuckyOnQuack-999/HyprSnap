#!/bin/bash

# HyprSnap Setup Script
# Created by DuckyOnQuack-999
# Version: 1.0.0
# License: MIT

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/hyprsnap"
CAPTURE_DIR="$HOME/Pictures/HyprSnap"
DESKTOP_FILE="$HOME/.local/share/applications/hyprsnap.desktop"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Flags
DEBUG_MODE=false
CHECK_ONLY=false

# Print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo
    print_status "$CYAN" "╔══════════════════════════════════════════════════════════════╗"
    print_status "$CYAN" "║                        HyprSnap Setup                       ║"
    print_status "$CYAN" "║              Lightning-fast screen capture suite            ║"
    print_status "$CYAN" "║                     Version 1.0.0                           ║"
    print_status "$CYAN" "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    else
        echo "unknown"
    fi
}

# Check if running on Wayland
check_wayland() {
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        return 0
    elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        return 0
    else
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    local optional_missing=()
    
    # Core dependencies
    local core_deps=("wf-recorder" "ffmpeg" "slurp")
    
    # Optional dependencies
    local optional_deps=("dunstify" "wl-copy" "xclip")
    
    print_status "$BLUE" "🔍 Checking dependencies..."
    
    for dep in "${core_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            print_status "$GREEN" "  ✓ $dep"
        else
            print_status "$RED" "  ✗ $dep (required)"
            missing_deps+=("$dep")
        fi
    done
    
    for dep in "${optional_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            print_status "$GREEN" "  ✓ $dep"
        else
            print_status "$YELLOW" "  ⚠ $dep (optional)"
            optional_missing+=("$dep")
        fi
    done
    
    # Check for at least one clipboard tool
    if ! command -v wl-copy >/dev/null 2>&1 && ! command -v xclip >/dev/null 2>&1; then
        print_status "$YELLOW" "  ⚠ No clipboard tool found (wl-copy or xclip recommended)"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_status "$RED" "❌ Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        print_status "$YELLOW" "⚠️  Missing optional dependencies: ${optional_missing[*]}"
    fi
    
    print_status "$GREEN" "✅ All required dependencies satisfied!"
    return 0
}

# Install dependencies based on distribution
install_dependencies() {
    local distro
    distro=$(detect_distro)
    
    print_status "$BLUE" "🚀 Installing dependencies for $distro..."
    
    case "$distro" in
        arch|manjaro)
            print_status "$BLUE" "Using pacman..."
            if command -v yay >/dev/null 2>&1; then
                yay -S --needed wf-recorder ffmpeg slurp libnotify wl-clipboard xclip
            elif command -v paru >/dev/null 2>&1; then
                paru -S --needed wf-recorder ffmpeg slurp libnotify wl-clipboard xclip
            else
                sudo pacman -S --needed wf-recorder ffmpeg slurp libnotify wl-clipboard xclip
            fi
            ;;
        ubuntu|debian)
            print_status "$BLUE" "Using apt..."
            sudo apt update
            sudo apt install -y wf-recorder ffmpeg slurp libnotify-bin wl-clipboard xclip
            ;;
        fedora)
            print_status "$BLUE" "Using dnf..."
            sudo dnf install -y wf-recorder ffmpeg slurp libnotify wl-clipboard xclip
            ;;
        opensuse*)
            print_status "$BLUE" "Using zypper..."
            sudo zypper install -y wf-recorder ffmpeg slurp libnotify-tools wl-clipboard xclip
            ;;
        *)
            print_status "$YELLOW" "⚠️  Unknown distribution. Please install dependencies manually:"
            echo "  - wf-recorder"
            echo "  - ffmpeg"
            echo "  - slurp"
            echo "  - libnotify (dunstify)"
            echo "  - wl-clipboard (wl-copy)"
            echo "  - xclip"
            return 1
            ;;
    esac
    
    print_status "$GREEN" "✅ Dependencies installed successfully!"
}

# Setup directories
setup_directories() {
    print_status "$BLUE" "📁 Setting up directories..."
    
    mkdir -p "$CONFIG_DIR" "$CAPTURE_DIR/Gifs" "$CAPTURE_DIR/Screenshots"
    mkdir -p "$(dirname "$DESKTOP_FILE")"
    
    print_status "$GREEN" "  ✓ Config directory: $CONFIG_DIR"
    print_status "$GREEN" "  ✓ Capture directory: $CAPTURE_DIR"
    print_status "$GREEN" "  ✓ Desktop entries directory: $(dirname "$DESKTOP_FILE")"
}

# Create desktop entry
create_desktop_entry() {
    print_status "$BLUE" "🖥️  Creating desktop entry..."
    
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=HyprSnap
Comment=Lightning-fast screen capture suite for modern Linux
Exec=$SCRIPT_DIR/hyprsnap.sh record
Icon=camera-photo
Terminal=false
Categories=Graphics;Photography;AudioVideo;
Keywords=screenshot;screen;capture;record;gif;
StartupNotify=true
MimeType=image/gif;image/png;
EOF
    
    chmod +x "$DESKTOP_FILE"
    print_status "$GREEN" "  ✓ Desktop entry created: $DESKTOP_FILE"
}

# Setup keybindings (Hyprland specific)
setup_hyprland_keybindings() {
    local hypr_config="$HOME/.config/hypr/hyprland.conf"
    
    if [[ ! -f "$hypr_config" ]]; then
        print_status "$YELLOW" "⚠️  Hyprland config not found, skipping keybinding setup"
        return
    fi
    
    print_status "$BLUE" "⌨️  Setting up Hyprland keybindings..."
    
    # Check if keybindings already exist
    if grep -q "hyprsnap" "$hypr_config"; then
        print_status "$YELLOW" "  ⚠ HyprSnap keybindings already exist"
        return
    fi
    
    # Add keybindings
    cat >> "$hypr_config" << EOF

# HyprSnap keybindings
bind = SUPER SHIFT, S, exec, $SCRIPT_DIR/hyprsnap.sh record
bind = SUPER SHIFT, G, exec, $SCRIPT_DIR/hyprsnap.sh record -q 95 -f 30
bind = SUPER SHIFT, A, exec, $SCRIPT_DIR/hyprsnap.sh record -o
EOF
    
    print_status "$GREEN" "  ✓ Hyprland keybindings added:"
    print_status "$GREEN" "    Super+Shift+S: Record GIF"
    print_status "$GREEN" "    Super+Shift+G: High-quality GIF"
    print_status "$GREEN" "    Super+Shift+A: Optimized GIF"
}

# Make scripts executable
setup_permissions() {
    print_status "$BLUE" "🔐 Setting up permissions..."
    
    chmod +x "$SCRIPT_DIR/hyprsnap.sh"
    chmod +x "$SCRIPT_DIR/setup.sh"
    
    if [[ -f "$SCRIPT_DIR/tests/run_tests.sh" ]]; then
        chmod +x "$SCRIPT_DIR/tests/run_tests.sh"
    fi
    
    print_status "$GREEN" "  ✓ Scripts made executable"
}

# Create sample config
create_sample_config() {
    local config_file="$CONFIG_DIR/config.conf"
    
    if [[ -f "$config_file" ]]; then
        print_status "$YELLOW" "  ⚠ Config file already exists: $config_file"
        return
    fi
    
    print_status "$BLUE" "⚙️  Creating sample configuration..."
    
    cat > "$config_file" << EOF
# HyprSnap Configuration
# Version: 1.0.0

# Default GIF settings
default_quality=90
default_fps=15
default_optimize=false

# Output settings
gif_dir="$CAPTURE_DIR/Gifs"
screenshot_dir="$CAPTURE_DIR/Screenshots"

# Notification settings
notifications_enabled=true
notification_duration=3000

# Debug settings
debug_mode=false
log_level=INFO
EOF
    
    print_status "$GREEN" "  ✓ Sample config created: $config_file"
}

# Run system checks
run_system_checks() {
    print_status "$BLUE" "🔧 Running system checks..."
    
    # Check Wayland
    if check_wayland; then
        print_status "$GREEN" "  ✓ Wayland session detected"
    else
        print_status "$YELLOW" "  ⚠ Not running on Wayland (limited functionality)"
    fi
    
    # Check compositor
    local compositor="${XDG_CURRENT_DESKTOP:-unknown}"
    print_status "$BLUE" "  ℹ Desktop environment: $compositor"
    
    # Check available space
    local available_space
    available_space=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    print_status "$BLUE" "  ℹ Available space in home: $available_space"
    
    print_status "$GREEN" "✅ System checks completed!"
}

# Show completion message
show_completion() {
    echo
    print_status "$GREEN" "╔══════════════════════════════════════════════════════════════╗"
    print_status "$GREEN" "║                    Setup Completed! 🎉                      ║"
    print_status "$GREEN" "╚══════════════════════════════════════════════════════════════╝"
    echo
    print_status "$CYAN" "📋 Quick Start:"
    echo "  Record GIF:           ./hyprsnap.sh record"
    echo "  High quality:         ./hyprsnap.sh record -q 95 -f 30"
    echo "  Optimized for web:    ./hyprsnap.sh record -q 75 -o"
    echo "  System info:          ./hyprsnap.sh --system-info"
    echo
    print_status "$CYAN" "📁 Output locations:"
    echo "  GIFs:        $CAPTURE_DIR/Gifs"
    echo "  Screenshots: $CAPTURE_DIR/Screenshots"
    echo "  Config:      $CONFIG_DIR"
    echo
    if [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
        print_status "$CYAN" "⌨️  Keybindings (Hyprland):"
        echo "  Super+Shift+S: Record GIF"
        echo "  Super+Shift+G: High-quality GIF"
        echo "  Super+Shift+A: Optimized GIF"
        echo
    fi
    print_status "$BLUE" "📖 For more information: https://github.com/DuckyOnQuack-999/HyprSnap"
    echo
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --check)
                CHECK_ONLY=true
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
}

# Show help
show_help() {
    cat << EOF
HyprSnap Setup Script
Version: 1.0.0

USAGE:
    ./setup.sh [options]

OPTIONS:
    --debug         Enable debug output
    --check         Only check dependencies (don't install)
    -h, --help      Show this help

DESCRIPTION:
    This script sets up HyprSnap by:
    - Checking and installing dependencies
    - Creating necessary directories
    - Setting up configuration files
    - Creating desktop entries
    - Adding keybindings (Hyprland)

SUPPORTED DISTRIBUTIONS:
    - Arch Linux / Manjaro
    - Ubuntu / Debian
    - Fedora
    - openSUSE

For manual installation instructions, visit:
https://github.com/DuckyOnQuack-999/HyprSnap
EOF
}

# Main setup function
main() {
    parse_args "$@"
    
    print_header
    
    # System checks
    run_system_checks
    
    # Check dependencies
    if ! check_dependencies; then
        if [[ "$CHECK_ONLY" == true ]]; then
            exit 1
        fi
        
        print_status "$YELLOW" "🔧 Attempting to install missing dependencies..."
        if ! install_dependencies; then
            print_status "$RED" "❌ Failed to install dependencies automatically"
            print_status "$YELLOW" "Please install them manually and run setup again"
            exit 1
        fi
        
        # Verify installation
        if ! check_dependencies; then
            print_status "$RED" "❌ Dependencies still missing after installation"
            exit 1
        fi
    fi
    
    if [[ "$CHECK_ONLY" == true ]]; then
        print_status "$GREEN" "✅ All dependencies are satisfied!"
        exit 0
    fi
    
    # Setup
    setup_directories
    setup_permissions
    create_sample_config
    create_desktop_entry
    setup_hyprland_keybindings
    
    show_completion
}

# Run main function
main "$@"