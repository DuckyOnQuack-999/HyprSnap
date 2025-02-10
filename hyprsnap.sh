#!/usr/bin/env bash

# HyprSnap - Modern Linux Screen Capture Suite
# Author: Your Name
# License: MIT

set -euo pipefail

# Default configuration
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprsnap"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
TEMP_DIR="/tmp/hyprsnap"
VERSION="1.0.0"

# Default values
DEFAULT_FPS=15
DEFAULT_QUALITY=80
DEFAULT_SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
DEFAULT_RECORDINGS_DIR="$HOME/Pictures/Recordings"

# Ensure required directories exist
mkdir -p "$CONFIG_DIR" "$TEMP_DIR" "$DEFAULT_SCREENSHOTS_DIR" "$DEFAULT_RECORDINGS_DIR"

# Function to check dependencies
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
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them before running HyprSnap."
        exit 1
    fi
}

# Function to check Wayland session
check_wayland() {
    if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
        echo "Error: HyprSnap requires a Wayland session."
        exit 1
    fi
}

# Function to send notifications
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    dunstify -u "$urgency" "HyprSnap: $title" "$message"
}

# Function to record GIF
record_gif() {
    local fps="$DEFAULT_FPS"
    local quality="$DEFAULT_QUALITY"
    local optimize=false
    local debug=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--fps)
                fps="$2"
                shift 2
                ;;
            -q|--quality)
                quality="$2"
                shift 2
                ;;
            -o|--optimize)
                optimize=true
                shift
                ;;
            -d|--debug)
                debug=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Get region selection using slurp
    local geometry
    geometry=$(slurp) || {
        send_notification "Error" "Region selection cancelled" "critical"
        exit 1
    }
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local temp_video="$TEMP_DIR/recording_$timestamp.mp4"
    local output_gif="$DEFAULT_RECORDINGS_DIR/recording_$timestamp.gif"
    local palette="$TEMP_DIR/palette_$timestamp.png"
    
    # Start recording notification
    send_notification "Recording" "Select a region to start recording" "normal"
    
    # Record video using wf-recorder
    wf-recorder -g "$geometry" -f "$temp_video" &
    local recorder_pid=$!
    
    # Wait for user to stop recording (Ctrl+C)
    trap 'kill $recorder_pid 2>/dev/null' INT TERM
    wait $recorder_pid || true
    trap - INT TERM
    
    send_notification "Processing" "Converting video to GIF..." "normal"
    
    # Generate optimized palette
    ffmpeg -i "$temp_video" -vf "fps=$fps,scale=iw:ih:flags=lanczos,palettegen=stats_mode=diff" "$palette"
    
    # Convert to GIF with the optimized palette
    if [ "$optimize" = true ]; then
        ffmpeg -i "$temp_video" -i "$palette" -lavfi "fps=$fps,scale=iw:ih:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" "$output_gif"
    else
        ffmpeg -i "$temp_video" -i "$palette" -lavfi "fps=$fps,scale=iw:ih:flags=lanczos [x]; [x][1:v] paletteuse" "$output_gif"
    fi
    
    # Cleanup temporary files
    rm -f "$temp_video" "$palette"
    
    send_notification "Success" "GIF saved to: $output_gif" "normal"
}

# Function to take screenshots
take_screenshot() {
    local mode="$1"
    shift
    
    local quality="$DEFAULT_QUALITY"
    local debug=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -q|--quality)
                quality="$2"
                shift 2
                ;;
            -d|--debug)
                debug=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output="$DEFAULT_SCREENSHOTS_DIR/screenshot_$timestamp.png"
    
    case "$mode" in
        area)
            local geometry
            geometry=$(slurp) || {
                send_notification "Error" "Region selection cancelled" "critical"
                exit 1
            }
            grim -g "$geometry" "$output"
            ;;
        window)
            # TODO: Implement active window screenshot
            echo "Window screenshot not implemented yet"
            exit 1
            ;;
        *)  # Full screen
            grim "$output"
            ;;
    esac
    
    send_notification "Success" "Screenshot saved to: $output" "normal"
}

# Show help message
show_help() {
    cat << EOF
HyprSnap v$VERSION - Modern Linux Screen Capture Suite

Usage: $(basename "$0") [command] [options]

Commands:
  record      Start GIF recording
  shot        Full screenshot
  area        Region screenshot
  window      Active window screenshot

Options:
  -q, --quality <1-100>   Visual fidelity level
  -f, --fps <num>         Frame rate control
  -o, --optimize          Filesize reduction
  -d, --debug            Diagnostic output
  -h, --help             Show this help message

Examples:
  $(basename "$0") record              # Record a region as GIF
  $(basename "$0") record -f 30 -o     # Record at 30fps with optimization
  $(basename "$0") area -q 100         # Take high-quality area screenshot
EOF
}

# Main function
main() {
    # Check dependencies and Wayland session
    check_dependencies
    check_wayland
    
    # Parse command
    case "${1:-}" in
        record)
            shift
            record_gif "$@"
            ;;
        shot)
            shift
            take_screenshot "full" "$@"
            ;;
        area)
            shift
            take_screenshot "area" "$@"
            ;;
        window)
            shift
            take_screenshot "window" "$@"
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Error: Unknown command. Use --help for usage information."
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 