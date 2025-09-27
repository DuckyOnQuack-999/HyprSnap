#!/usr/bin/env bash

# Configuration module for HyprSnap
# Provides enhanced configuration management and validation

# Prevent multiple sourcing
if [[ -n "${HYPRSNAP_CONFIG_LOADED:-}" ]]; then
    return 0
fi
export HYPRSNAP_CONFIG_LOADED=1

# Source error handling
source "$(dirname "${BASH_SOURCE[0]}")/error.sh"

# Default configuration values
declare -A DEFAULT_CONFIG=(
    [version]="2.0"
    [default_fps]="15"
    [default_quality]="80"
    [save_directory]="$HOME/Pictures/HyprSnap"
    [gif_directory]="$HOME/Pictures/HyprSnap/GIFs"
    [video_directory]="$HOME/Pictures/HyprSnap/Videos"
    [debug_enabled]="false"
    [notifications_enabled]="true"
    [ffmpeg_codec]="libx264"
    [screenshot_format]="png"
    [max_threads]="4"
    [optimize_by_default]="false"
    [cleanup_older_than]="24"
)

# Configuration file path
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hyprsnap/config.yaml"

# Check for required binaries
check_dependencies() {
    local missing_deps=()
    
    # Core tools
    command -v grim >/dev/null || missing_deps+=("grim")
    command -v slurp >/dev/null || missing_deps+=("slurp")
    command -v wf-recorder >/dev/null || missing_deps+=("wf-recorder")
    command -v ffmpeg >/dev/null || missing_deps+=("ffmpeg")
    command -v convert >/dev/null || missing_deps+=("imagemagick")
    
    # YAML parser
    if ! command -v yq >/dev/null; then
        if ! command -v jq >/dev/null; then
            missing_deps+=("yq or jq")
        fi
    fi
    
    # Optional optimization tools
    if [[ "${OPTIMIZE_BY_DEFAULT:-false}" == "true" ]]; then
        command -v optipng >/dev/null || missing_deps+=("optipng (optional)")
        command -v jpegoptim >/dev/null || missing_deps+=("jpegoptim (optional)")
        command -v cwebp >/dev/null || missing_deps+=("libwebp/cwebp (optional)")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_message "WARNING" "Missing dependencies: ${missing_deps[*]}"
        log_message "INFO" "Install missing dependencies:"
        log_message "INFO" "Arch: sudo pacman -S grim slurp wf-recorder ffmpeg imagemagick yq optipng jpegoptim libwebp"
        log_message "INFO" "Ubuntu: sudo apt install grim slurp wf-recorder ffmpeg imagemagick-6.q16 yq optipng jpegoptim webp"
    fi
    
    return 0
}

# Validate configuration values
validate_config() {
    local config_file=$1
    
    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        handle_error 1 "Configuration file not found: $config_file" "ERROR"
        return 1
    fi
    
    # Check yq availability
    if ! command -v yq >/dev/null; then
        log_message "WARNING" "yq command not found. Using fallback configuration."
        return 0  # Don't fail, just use defaults
    fi
    
    # Validate FPS (with fallbacks)
    local fps=$(yq e '.default_fps // 15' "$config_file")
    if ! [[ "$fps" =~ ^[0-9]+$ ]] || ((10#$fps < 1)) || ((10#$fps > 60)); then
        handle_error 1 "Invalid FPS value: $fps" "ERROR"
        return 1
    fi
    
    # Validate quality (with fallbacks)
    local quality=$(yq e '.default_quality // 80' "$config_file")
    if ! [[ "$quality" =~ ^[0-9]+$ ]] || ((10#$quality < 1)) || ((10#$quality > 100)); then
        handle_error 1 "Invalid quality value: $quality" "ERROR"
        return 1
    fi
    
    # Validate screenshot format (with fallbacks)
    local format=$(yq e '.screenshot_format // .screenshot.format // "png"' "$config_file")
    if [[ ! "$format" =~ ^(png|jpg|webp)$ ]]; then
        handle_error 1 "Invalid screenshot format: $format" "ERROR"
        return 1
    fi
    
    # Validate max threads (with fallbacks)
    local threads=$(yq e '.max_threads // .performance.max_threads // 4' "$config_file")
    if ! [[ "$threads" =~ ^[0-9]+$ ]] || ((10#$threads < 1)); then
        handle_error 1 "Invalid max_threads value: $threads" "ERROR"
        return 1
    fi
    
    return 0
}

# Load configuration
load_config() {
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Create default config if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi
    
    # Validate configuration
    if ! validate_config "$CONFIG_FILE"; then
        handle_error 1 "Configuration validation failed" "ERROR"
        return 1
    fi
    
    # Check dependencies after loading config
    check_dependencies
    
    # Load configuration values with fallbacks
    if command -v yq >/dev/null; then
        # Use yq if available
        DEFAULT_FPS=$(yq e '.default_fps // 15' "$CONFIG_FILE")
        DEFAULT_QUALITY=$(yq e '.default_quality // 80' "$CONFIG_FILE")
        SAVE_DIR=$(yq e '.save_directory // "~/Pictures/HyprSnap"' "$CONFIG_FILE")
        GIF_DIR=$(yq e '.gif_directory // "~/Pictures/HyprSnap/GIFs"' "$CONFIG_FILE")
        VIDEO_DIR=$(yq e '.video_directory // "~/Pictures/HyprSnap/Videos"' "$CONFIG_FILE")
        DEBUG_ENABLED=$(yq e '.debug_enabled // .debug.enabled // false' "$CONFIG_FILE")
        NOTIFICATIONS_ENABLED=$(yq e '.notifications_enabled // .notifications.enabled // true' "$CONFIG_FILE")
        FFMPEG_CODEC=$(yq e '.ffmpeg_codec // .ffmpeg.codec // "libx264"' "$CONFIG_FILE")
        SCREENSHOT_FORMAT=$(yq e '.screenshot_format // .screenshot.format // "png"' "$CONFIG_FILE")
        MAX_THREADS=$(yq e '.max_threads // .performance.max_threads // 4' "$CONFIG_FILE")
        TEMP_DIR=$(yq e '.temp_directory // .performance.temp_directory // "/tmp/hyprsnap"' "$CONFIG_FILE")
        CLEANUP_OLDER_THAN=$(yq e '.cleanup_older_than // .performance.cleanup_older_than // 24' "$CONFIG_FILE")
        OPTIMIZE_BY_DEFAULT=$(yq e '.optimize_by_default // false' "$CONFIG_FILE")
    else
        # Use default values when yq is not available
        DEFAULT_FPS=15
        DEFAULT_QUALITY=80
        SAVE_DIR="$HOME/Pictures/HyprSnap"
        GIF_DIR="$HOME/Pictures/HyprSnap/GIFs"
        VIDEO_DIR="$HOME/Pictures/HyprSnap/Videos"
        DEBUG_ENABLED=false
        NOTIFICATIONS_ENABLED=true
        FFMPEG_CODEC="libx264"
        SCREENSHOT_FORMAT="png"
        MAX_THREADS=4
        TEMP_DIR="/tmp/hyprsnap"
        CLEANUP_OLDER_THAN=24
        OPTIMIZE_BY_DEFAULT=false
    fi
    
    # Export variables
    export DEFAULT_FPS DEFAULT_QUALITY SAVE_DIR GIF_DIR VIDEO_DIR DEBUG_ENABLED
    export NOTIFICATIONS_ENABLED FFMPEG_CODEC SCREENSHOT_FORMAT MAX_THREADS
    export TEMP_DIR OPTIMIZE_BY_DEFAULT CLEANUP_OLDER_THAN
    
    return 0
}

# Create default configuration
create_default_config() {
    # Create YAML configuration
    cat > "$CONFIG_FILE" << EOF
version: "${DEFAULT_CONFIG[version]}"
default_fps: ${DEFAULT_CONFIG[default_fps]}
default_quality: ${DEFAULT_CONFIG[default_quality]}
save_directory: "${DEFAULT_CONFIG[save_directory]}"
gif_directory: "${DEFAULT_CONFIG[gif_directory]}"
video_directory: "${DEFAULT_CONFIG[video_directory]}"
debug_enabled: ${DEFAULT_CONFIG[debug_enabled]}
notifications_enabled: ${DEFAULT_CONFIG[notifications_enabled]}
ffmpeg_codec: "${DEFAULT_CONFIG[ffmpeg_codec]}"
screenshot_format: "${DEFAULT_CONFIG[screenshot_format]}"
max_threads: ${DEFAULT_CONFIG[max_threads]}
optimize_by_default: ${DEFAULT_CONFIG[optimize_by_default]}
cleanup_older_than: ${DEFAULT_CONFIG[cleanup_older_than]}

# Feature settings
features:
  screenshot:
    formats: ["png", "jpg", "webp"]
    quality: 90
    post_process: true
  recording:
    formats: ["gif", "mp4", "webm"]
    audio: true
    hardware_accel: true
  editing:
    filters: ["blur", "sharpen", "contrast"]
    batch: true
  upload:
    providers:
      - name: "0x0.st"
        auth: false
      - name: "imgur"
        auth: true

# Performance settings
performance:
  max_threads: 4
  temp_directory: "/tmp/hyprsnap"
  cleanup_older_than: 24
EOF
    
    log_message "INFO" "Created default configuration file at $CONFIG_FILE"
}

# Update configuration
update_config() {
    local key=$1
    local value=$2
    
    # Validate key exists
    if [[ ! -v DEFAULT_CONFIG[$key] ]]; then
        handle_error 1 "Invalid configuration key: $key" "ERROR"
        return 1
    fi
    
    # Update configuration
    yq e ".$key = \"$value\"" -i "$CONFIG_FILE"
    
    # Reload configuration
    load_config
    
    log_message "INFO" "Updated configuration: $key=$value"
    return 0
}

# Initialize configuration
init_config() {
    load_config
} 