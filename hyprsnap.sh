#!/bin/bash

# HyprSnap - Lightning-fast screen capture suite for modern Linux
# Created by DuckyOnQuack-999
# Version: 1.0.0
# License: MIT

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/hyprsnap"
CAPTURE_DIR="$HOME/Pictures/HyprSnap"
GIF_DIR="$CAPTURE_DIR/Gifs"
SCREENSHOT_DIR="$CAPTURE_DIR/Screenshots"
LOG_FILE="$CONFIG_DIR/hyprsnap.log"

# Default settings
DEFAULT_QUALITY=90
DEFAULT_FPS=15
DEFAULT_OPTIMIZE=false
DEBUG_MODE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$DEBUG_MODE" == true ]] || [[ "$level" != "DEBUG" ]]; then
        echo -e "${timestamp} [$level] $message" | tee -a "$LOG_FILE"
    else
        echo "${timestamp} [$level] $message" >> "$LOG_FILE"
    fi
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    dunstify -u critical -t 5000 "HyprSnap Error" "$1"
    exit 1
}

# Success notification
success_notify() {
    log "INFO" "$1"
    dunstify -u normal -t 3000 "HyprSnap" "$1"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    local deps=("wf-recorder" "ffmpeg" "slurp" "dunstify")
    
    # Check for clipboard tools
    if ! command -v wl-copy >/dev/null 2>&1 && ! command -v xclip >/dev/null 2>&1; then
        missing_deps+=("wl-copy or xclip")
    fi
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error_exit "Missing dependencies: ${missing_deps[*]}. Please install them first."
    fi
    
    log "DEBUG" "All dependencies satisfied"
}

# Setup directories
setup_directories() {
    mkdir -p "$CONFIG_DIR" "$GIF_DIR" "$SCREENSHOT_DIR"
    touch "$LOG_FILE"
    log "DEBUG" "Directories created: $CONFIG_DIR, $GIF_DIR, $SCREENSHOT_DIR"
}

# Get system info
get_system_info() {
    echo "=== HyprSnap System Information ==="
    echo "Version: 1.0.0"
    echo "OS: $(uname -a)"
    echo "Wayland Compositor: ${XDG_CURRENT_DESKTOP:-Unknown}"
    echo "Session Type: ${XDG_SESSION_TYPE:-Unknown}"
    echo ""
    echo "Dependencies:"
    for cmd in wf-recorder ffmpeg slurp dunstify wl-copy xclip; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "  ✓ $cmd: $(command -v "$cmd")"
        else
            echo "  ✗ $cmd: Not found"
        fi
    done
    echo ""
    echo "Directories:"
    echo "  Config: $CONFIG_DIR"
    echo "  Captures: $CAPTURE_DIR"
    echo "  Logs: $LOG_FILE"
}

# Record GIF
record_gif() {
    local quality="$DEFAULT_QUALITY"
    local fps="$DEFAULT_FPS"
    local optimize="$DEFAULT_OPTIMIZE"
    local output_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -q|--quality)
                quality="$2"
                shift 2
                ;;
            -f|--fps)
                fps="$2"
                shift 2
                ;;
            -o|--optimize)
                optimize=true
                shift
                ;;
            -d|--debug)
                DEBUG_MODE=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Validate quality
    if [[ ! "$quality" =~ ^[0-9]+$ ]] || [[ "$quality" -lt 1 ]] || [[ "$quality" -gt 100 ]]; then
        error_exit "Quality must be between 1 and 100"
    fi
    
    # Validate FPS
    if [[ ! "$fps" =~ ^[0-9]+$ ]] || [[ "$fps" -lt 1 ]] || [[ "$fps" -gt 60 ]]; then
        error_exit "FPS must be between 1 and 60"
    fi
    
    log "INFO" "Starting GIF recording with quality=$quality, fps=$fps, optimize=$optimize"
    
    # Get area selection
    local geometry
    geometry=$(slurp 2>/dev/null) || error_exit "Area selection cancelled or failed"
    
    log "DEBUG" "Selected area: $geometry"
    
    # Generate output filename
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    output_file="$GIF_DIR/hyprsnap_${timestamp}.gif"
    local temp_video="/tmp/hyprsnap_${timestamp}.mp4"
    
    # Start recording notification
    dunstify -u normal -t 2000 "HyprSnap" "Recording started! Press Super+Ctrl+C to stop"
    
    # Record video
    log "DEBUG" "Recording to temporary file: $temp_video"
    wf-recorder -g "$geometry" -f "$temp_video" -r "$fps" &
    local recorder_pid=$!
    
    # Wait for user to stop recording (you'll need to implement signal handling)
    # For now, we'll use a simple approach
    echo "Recording... Press Ctrl+C to stop"
    wait $recorder_pid || true
    
    # Check if recording was successful
    if [[ ! -f "$temp_video" ]]; then
        error_exit "Recording failed - no output file created"
    fi
    
    log "INFO" "Recording completed, converting to GIF..."
    dunstify -u normal -t 2000 "HyprSnap" "Processing GIF..."
    
    # Convert to GIF with quality settings
    local palette="/tmp/hyprsnap_palette_${timestamp}.png"
    
    # Generate palette
    if ! ffmpeg -i "$temp_video" -vf "fps=$fps,scale=-1:-1:flags=lanczos,palettegen=max_colors=256" -y "$palette" >/dev/null 2>&1; then
        rm -f "$temp_video"
        error_exit "Failed to generate color palette"
    fi
    
    # Create GIF
    local filter_complex="fps=$fps,scale=-1:-1:flags=lanczos[x];[x][1:v]paletteuse"
    if [[ "$optimize" == true ]]; then
        filter_complex="${filter_complex}=dither=bayer:bayer_scale=5:diff_mode=rectangle"
    fi
    
    if ! ffmpeg -i "$temp_video" -i "$palette" -filter_complex "$filter_complex" -y "$output_file" >/dev/null 2>&1; then
        rm -f "$temp_video" "$palette"
        error_exit "Failed to create GIF"
    fi
    
    # Cleanup
    rm -f "$temp_video" "$palette"
    
    # Get file size
    local file_size=$(du -h "$output_file" | cut -f1)
    
    log "INFO" "GIF created successfully: $output_file ($file_size)"
    success_notify "GIF saved: $(basename "$output_file") ($file_size)"
    
    # Copy to clipboard if available
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$output_file" && log "DEBUG" "GIF copied to clipboard"
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -t image/gif < "$output_file" && log "DEBUG" "GIF copied to clipboard"
    fi
    
    echo "GIF saved to: $output_file"
}

# Take screenshot (placeholder for future implementation)
take_screenshot() {
    echo "Screenshot functionality coming soon!"
    log "INFO" "Screenshot feature requested (not yet implemented)"
}

# Show help
show_help() {
    cat << EOF
HyprSnap - Lightning-fast screen capture suite for modern Linux
Version: 1.0.0

USAGE:
    ./hyprsnap.sh <command> [options]

COMMANDS:
    record              Record a GIF (default)
    shot               Take a screenshot (coming soon)
    area               Screenshot selected area (coming soon)  
    window             Screenshot active window (coming soon)
    --system-info      Display system information
    --check            Check dependencies
    -h, --help         Show this help

GIF RECORDING OPTIONS:
    -q, --quality <1-100>    Set GIF quality (default: $DEFAULT_QUALITY)
    -f, --fps <number>       Set frame rate (default: $DEFAULT_FPS)
    -o, --optimize           Enable optimization for smaller files
    -d, --debug              Enable debug output

EXAMPLES:
    ./hyprsnap.sh record                    # Basic GIF recording
    ./hyprsnap.sh record -q 95 -f 30        # High quality, 30fps
    ./hyprsnap.sh record -q 75 -o           # Optimized for sharing
    ./hyprsnap.sh --system-info             # Show system info

OUTPUT LOCATIONS:
    GIFs: $GIF_DIR
    Screenshots: $SCREENSHOT_DIR
    Logs: $LOG_FILE

For more information, visit: https://github.com/DuckyOnQuack-999/HyprSnap
EOF
}

# Main function
main() {
    # Setup
    setup_directories
    
    # Handle no arguments
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    # Parse command
    case "$1" in
        record)
            check_dependencies
            shift
            record_gif "$@"
            ;;
        shot|area|window)
            take_screenshot
            ;;
        --system-info)
            get_system_info
            ;;
        --check)
            check_dependencies
            echo "✓ All dependencies are satisfied"
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Signal handling for clean shutdown
trap 'log "INFO" "HyprSnap interrupted by user"; exit 130' INT TERM

# Run main function
main "$@"