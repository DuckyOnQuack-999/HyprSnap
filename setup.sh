#!/usr/bin/env bash

# HyprSnap Installation Script
# This script installs HyprSnap and sets up necessary configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprsnap"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprsnap"

# Print with color
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Check if running on a supported distribution
check_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|manjaro)
                print_color "$GREEN" "Detected Arch-based distribution"
                return 0
                ;;
            ubuntu|debian)
                print_color "$GREEN" "Detected Debian-based distribution"
                return 0
                ;;
            fedora)
                print_color "$GREEN" "Detected Fedora"
                return 0
                ;;
            *)
                print_color "$YELLOW" "Warning: Unsupported distribution. You may need to install dependencies manually."
                return 1
                ;;
        esac
    else
        print_color "$YELLOW" "Warning: Could not detect distribution. You may need to install dependencies manually."
        return 1
    fi
}

# Check for required dependencies
check_dependencies() {
    local missing_deps=()
    
    # Required dependencies
    local deps=("wf-recorder" "ffmpeg" "slurp" "dunst")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_color "$YELLOW" "Missing dependencies: ${missing_deps[*]}"
        
        # Attempt to install missing dependencies
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                arch|manjaro)
                    print_color "$GREEN" "Installing dependencies using pacman..."
                    sudo pacman -S --needed "${missing_deps[@]}"
                    ;;
                ubuntu|debian)
                    print_color "$GREEN" "Installing dependencies using apt..."
                    sudo apt update
                    sudo apt install -y "${missing_deps[@]}"
                    ;;
                fedora)
                    print_color "$GREEN" "Installing dependencies using dnf..."
                    sudo dnf install -y "${missing_deps[@]}"
                    ;;
                *)
                    print_color "$RED" "Please install the following dependencies manually: ${missing_deps[*]}"
                    exit 1
                    ;;
            esac
        else
            print_color "$RED" "Please install the following dependencies manually: ${missing_deps[*]}"
            exit 1
        fi
    fi
}

# Create necessary directories
create_directories() {
    mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$SHARE_DIR"
    print_color "$GREEN" "Created necessary directories"
}

# Install HyprSnap
install_hyprsnap() {
    # Copy main script
    cp hyprsnap.sh "$INSTALL_DIR/hyprsnap"
    chmod +x "$INSTALL_DIR/hyprsnap"
    
    # Copy config file if it doesn't exist
    if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
        cp config.yaml "$CONFIG_DIR/config.yaml"
    else
        print_color "$YELLOW" "Config file already exists, skipping..."
    fi
    
    print_color "$GREEN" "Installed HyprSnap successfully"
}

# Add to PATH if necessary
update_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        local shell_rc
        if [ -n "${ZSH_VERSION:-}" ]; then
            shell_rc="$HOME/.zshrc"
        else
            shell_rc="$HOME/.bashrc"
        fi
        
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_rc"
        print_color "$GREEN" "Added HyprSnap to PATH in $shell_rc"
    fi
}

# Setup Hyprland config
setup_hyprland() {
    local hyprland_conf="$HOME/.config/hypr/hyprland.conf"
    
    if [ -f "$hyprland_conf" ]; then
        # Check if bindings already exist
        if ! grep -q "hyprsnap" "$hyprland_conf"; then
            cat << EOF >> "$hyprland_conf"

# HyprSnap bindings
bind = SUPER SHIFT, R, exec, hyprsnap record
bind = SUPER SHIFT, S, exec, hyprsnap shot
bind = SUPER SHIFT, A, exec, hyprsnap area
bind = SUPER SHIFT, W, exec, hyprsnap window
EOF
            print_color "$GREEN" "Added HyprSnap keybindings to Hyprland config"
        else
            print_color "$YELLOW" "HyprSnap keybindings already exist in Hyprland config"
        fi
    else
        print_color "$YELLOW" "Hyprland config not found at $hyprland_conf"
        print_color "$YELLOW" "Please add keybindings manually to your Hyprland config"
    fi
}

# Main installation process
main() {
    print_color "$GREEN" "Starting HyprSnap installation..."
    
    check_distro
    check_dependencies
    create_directories
    install_hyprsnap
    update_path
    setup_hyprland
    
    print_color "$GREEN" "Installation complete! Please restart your shell or source your rc file."
    print_color "$GREEN" "You can now use HyprSnap with the following commands:"
    echo "  hyprsnap record  - Record GIF"
    echo "  hyprsnap shot   - Full screenshot"
    echo "  hyprsnap area   - Area screenshot"
    echo "  hyprsnap window - Window screenshot"
}

# Run main installation
main 