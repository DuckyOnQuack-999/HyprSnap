#!/usr/bin/env bash

# Configuration module for HyprSnap
# Provides enhanced configuration management and validation

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

# Validate configuration values
validate_config() {
    local config_file=$1
    
    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        handle_error 1 "Configuration file not found: $config_file" "ERROR"
        return 1
    }
    
    # Validate FPS
    local fps=$(yq e '.default_fps' "$config_file")
    if ! [[ "$fps" =~ ^[0-9]+$ ]] || ((10#$fps < 1)) || ((10#$fps > 60)); then
        handle_error 1 "Invalid FPS value: $fps" "ERROR"
        return 1
    fi
    
    # Validate quality
    local quality=$(yq e '.default_quality' "$config_file")
    if ! [[ "$quality" =~ ^[0-9]+$ ]] || ((10#$quality < 1)) || ((10#$quality > 100)); then
        handle_error 1 "Invalid quality value: $quality" "ERROR"
        return 1
    fi
    
    # Validate screenshot format
    local format=$(yq e '.screenshot_format' "$config_file")
    if [[ ! "$format" =~ ^(png|jpg|webp)$ ]]; then
        handle_error 1 "Invalid screenshot format: $format" "ERROR"
        return 1
    fi
    
    # Validate max threads
    local threads=$(yq e '.max_threads' "$config_file")
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
    
    # Load configuration values
    DEFAULT_FPS=$(yq e '.default_fps' "$CONFIG_FILE")
    DEFAULT_QUALITY=$(yq e '.default_quality' "$CONFIG_FILE")
    SAVE_DIR=$(yq e '.save_directory' "$CONFIG_FILE")
    GIF_DIR=$(yq e '.gif_directory' "$CONFIG_FILE")
    VIDEO_DIR=$(yq e '.video_directory' "$CONFIG_FILE")
    DEBUG_ENABLED=$(yq e '.debug_enabled' "$CONFIG_FILE")
    NOTIFICATIONS_ENABLED=$(yq e '.notifications_enabled' "$CONFIG_FILE")
    FFMPEG_CODEC=$(yq e '.ffmpeg_codec' "$CONFIG_FILE")
    SCREENSHOT_FORMAT=$(yq e '.screenshot_format' "$CONFIG_FILE")
    MAX_THREADS=$(yq e '.max_threads' "$CONFIG_FILE")
    OPTIMIZE_BY_DEFAULT=$(yq e '.optimize_by_default' "$CONFIG_FILE")
    CLEANUP_OLDER_THAN=$(yq e '.cleanup_older_than' "$CONFIG_FILE")
    
    # Export variables
    export DEFAULT_FPS DEFAULT_QUALITY SAVE_DIR GIF_DIR VIDEO_DIR DEBUG_ENABLED
    export NOTIFICATIONS_ENABLED FFMPEG_CODEC SCREENSHOT_FORMAT MAX_THREADS
    export OPTIMIZE_BY_DEFAULT CLEANUP_OLDER_THAN
    
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