#!/usr/bin/env bash

#===================================================================================
# HyprSnap - Modern Linux Screen Capture Suite
#===================================================================================
#
# A lightning-fast screen capture tool for modern Linux desktops
# Version: 2.0.0
#
# Author: DuckyOnQuack-999 (https://github.com/DuckyOnQuack-999)
# License: MIT
# Repository: https://github.com/DuckyOnQuack-999/HyprSnap
#
# Features:
# - Screenshot capture (full, area, window)
# - Screen recording (GIF, MP4, WebM)
# - Image editing and optimization
# - Batch processing
# - Hardware acceleration
# - Wayland compositor support
# - Modern notification system
#===================================================================================

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source modules
source "$SCRIPT_DIR/utils/error.sh"
source "$SCRIPT_DIR/utils/config.sh"
source "$SCRIPT_DIR/core/screenshot.sh"
source "$SCRIPT_DIR/core/recording.sh"

# Version
VERSION="2.0.0"

# Help message
show_help() {
    cat <<EOF
HyprSnap v$VERSION - Modern Linux Screen Capture Suite

Usage: hyprsnap [command] [options]

Commands:
  shot              Take a screenshot
  record           Record screen
  edit             Edit image/recording
  batch            Batch process files
  init             Initialize configuration
  cleanup          Clean up temporary files

Global Options:
  -h, --help       Show this help message
  -v, --version    Show version information
  -d, --debug      Enable debug mode

Screenshot Options (hyprsnap shot):
  --format FORMAT  Set format: png|jpg|webp (default: png)
  --quality N      Set quality 1-100 (default: 90)
  -o, --output     Set output file
  [full|area|window]  Screenshot type (default: full)

Recording Options (hyprsnap record):
  --format FORMAT  Set format: gif|mp4|webm (default: gif)
  --fps N          Set frame rate (default: 30)
  --quality N      Set quality 1-51 for video (default: 23)
  --duration N     Set duration in seconds (default: infinite)
  --audio          Enable audio recording
  --hw             Enable hardware acceleration
  -o, --output     Set output file
  [full|area|window]  Recording type (default: full)

Examples:
  hyprsnap shot --format png --quality 90 --output screenshot.png area
  hyprsnap record --format mp4 --fps 30 --quality 23 --hw --audio --duration 10 --output recording.mp4
  hyprsnap edit -i image.png -f blur
  hyprsnap batch -i input/ -o output/ --format webp --quality 80
EOF
}

# Parse screenshot-specific options
parse_shot_opts() {
    local shot_format="${SCREENSHOT_FORMAT:-png}"
    local shot_quality="${DEFAULT_QUALITY:-90}"
    local output=""
    local shot_type="FULL"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format)
                shot_format="$2"
                shift 2
                ;;
            --quality)
                shot_quality="$2"
                shift 2
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            full|area|window)
                shot_type="${1^^}"
                shift
                ;;
            *)
                echo "Unknown shot option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set default output path if not specified
    if [[ -z "$output" ]]; then
        output="$SAVE_DIR/screenshot.$shot_format"
    fi
    
    take_screenshot "$shot_type" "$output" "$shot_format" "$shot_quality"
}

# Parse recording-specific options
parse_record_opts() {
    local record_format="gif"
    local record_fps="${DEFAULT_FPS:-30}"
    local record_quality="${DEFAULT_QUALITY:-23}"
    local duration="0"
    local audio="false"
    local hw_accel="false"
    local output=""
    local record_type="FULL"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format)
                record_format="$2"
                shift 2
                ;;
            --fps)
                record_fps="$2"
                shift 2
                ;;
            --quality)
                record_quality="$2"
                shift 2
                ;;
            --duration)
                duration="$2"
                shift 2
                ;;
            --audio)
                audio="true"
                shift
                ;;
            --hw)
                hw_accel="true"
                shift
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            full|area|window)
                record_type="${1^^}"
                shift
                ;;
            *)
                echo "Unknown record option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set default output path if not specified
    if [[ -z "$output" ]]; then
        if [[ "$record_format" == "gif" ]]; then
            output="$GIF_DIR/recording.$record_format"
        else
            output="$VIDEO_DIR/recording.$record_format"
        fi
    fi
    
    record_screen "$record_type" "$output" "$duration" "$record_format" "$record_fps" "$record_quality" "$audio" "$hw_accel"
}

# Parse batch-specific options
parse_batch_opts() {
    local input_dir=""
    local output_dir=""
    local batch_format="${SCREENSHOT_FORMAT:-png}"
    local batch_quality="${DEFAULT_QUALITY:-80}"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input)
                input_dir="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            --format)
                batch_format="$2"
                shift 2
                ;;
            --quality)
                batch_quality="$2"
                shift 2
                ;;
            *)
                echo "Unknown batch option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$input_dir" || -z "$output_dir" ]]; then
        echo "Error: Both input (-i) and output (-o) directories are required for batch processing" >&2
        exit 1
    fi
    
    batch_process "$input_dir" "$output_dir" "$batch_format" "$batch_quality"
}

# Parse edit-specific options
parse_edit_opts() {
    local image=""
    local filter=""
    local params=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input)
                image="$2"
                shift 2
                ;;
            -f|--filter)
                filter="$2"
                shift 2
                ;;
            -p|--params)
                params="$2"
                shift 2
                ;;
            *)
                echo "Unknown edit option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$image" || -z "$filter" ]]; then
        echo "Error: Both input image (-i) and filter (-f) are required for editing" >&2
        exit 1
    fi
    
    apply_filter "$image" "$filter" "$params"
}

# Parse command line arguments
parse_args() {
    local command=""
    
    # Parse global options first
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "HyprSnap v$VERSION"
                exit 0
                ;;
            -d|--debug)
                DEBUG=1
                shift
                ;;
            shot|record|edit|batch|init|cleanup)
                command="$1"
                shift
                break  # Stop processing global options when we hit a command
                ;;
            *)
                echo "Unknown global option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
    
    # Execute command with remaining arguments
    case $command in
        shot)
            parse_shot_opts "$@"
            ;;
        record)
            parse_record_opts "$@"
            ;;
        edit)
            parse_edit_opts "$@"
            ;;
        batch)
            parse_batch_opts "$@"
            ;;
        init)
            init_config
            ;;
        cleanup)
            cleanup
            ;;
        "")
            echo "Error: No command specified" >&2
            show_help
            exit 1
            ;;
        *)
            echo "Error: Unknown command: $command" >&2
            show_help
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Initialize configuration
    init_config
    
    # Parse command line arguments
parse_args "$@"
}

# Run main function
main "$@"