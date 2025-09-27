#!/usr/bin/env bash

# Screenshot module for HyprSnap
# Provides enhanced screenshot capabilities with support for multiple formats and post-processing

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../utils/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"

# Screenshot types
declare -rA SCREENSHOT_TYPES=(
    [FULL]="full"
    [AREA]="area"
    [WINDOW]="window"
)

# Take a screenshot
take_screenshot() {
    local type=$1
    local output=$2
    local format=${3:-$SCREENSHOT_FORMAT}
    local quality=${4:-$DEFAULT_QUALITY}
    
    # Validate screenshot type
    if [[ ! -v SCREENSHOT_TYPES[$type] ]]; then
        handle_error 1 "Invalid screenshot type: $type" "ERROR"
        return 1
    fi
    
    # Validate output path
    if ! is_safe_path "$output"; then
        handle_error 1 "Invalid output path: $output" "ERROR"
        return 1
    fi
    
    # Create temporary file
    local temp_file=$(mktemp -p "${TEMP_DIR:-/tmp}" -t "hyprsnap.XXXXXXXX.$format")
    trap 'rm -f "$temp_file"' EXIT
    
    # Take screenshot based on type
    case $type in
        "FULL")
            if ! grim "$temp_file"; then
                handle_error 1 "Failed to capture full screenshot" "ERROR"
                return 1
            fi
            ;;
        "AREA")
            if ! grim -g "$(slurp)" "$temp_file"; then
                handle_error 1 "Failed to capture area screenshot" "ERROR"
                return 1
            fi
            ;;
        "WINDOW")
            local geo=""
            if command -v hyprctl > /dev/null 2>&1; then
                # Hyprland compositor
                geo=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            elif command -v swaymsg > /dev/null 2>&1; then
                # Sway compositor
                geo=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
            else
                # Generic Wayland fallback - interactive selection
                geo=$(slurp)
            fi
            
            if ! grim -g "$geo" "$temp_file"; then
                handle_error 1 "Failed to capture window screenshot" "ERROR"
                return 1
            fi
            ;;
    esac
    
    # Post-process image
    if [[ $format == "jpg" || $format == "webp" ]]; then
        if ! convert "$temp_file" -quality "$quality" "$output"; then
            handle_error 1 "Failed to convert image to $format" "ERROR"
            return 1
        fi
    else
        if ! cp "$temp_file" "$output"; then
            handle_error 1 "Failed to save screenshot" "ERROR"
            return 1
        fi
    fi
    
    # Optimize if enabled
    if [[ $OPTIMIZE_BY_DEFAULT == "true" ]]; then
        optimize_image "$output"
    fi
    
    log_message "INFO" "Screenshot saved to $output"
    return 0
}

# Optimize image
optimize_image() {
    local image=$1
    
    # Validate image path
    if ! is_safe_path "$image"; then
        handle_error 1 "Invalid image path: $image" "ERROR"
        return 1
    fi
    
    # Get image format
    local format=$(identify -format "%m" "$image" | tr '[:upper:]' '[:lower:]')
    
    # Optimize based on format
    case $format in
        "png")
            if ! optipng -quiet "$image"; then
                handle_error 1 "Failed to optimize PNG image" "WARNING"
                return 1
            fi
            ;;
        "jpeg"|"jpg")
            if ! jpegoptim --quiet "$image"; then
                handle_error 1 "Failed to optimize JPEG image" "WARNING"
                return 1
            fi
            ;;
        "webp")
            if ! cwebp -quiet "$image" -o "${image}.webp" && mv "${image}.webp" "$image"; then
                handle_error 1 "Failed to optimize WebP image" "WARNING"
                return 1
            fi
            ;;
    esac
    
    log_message "INFO" "Image optimized: $image"
    return 0
}

# Batch process images
batch_process() {
    local input_dir=$1
    local output_dir=$2
    local format=${3:-$SCREENSHOT_FORMAT}
    local quality=${4:-$DEFAULT_QUALITY}
    
    # Validate directories
    if ! is_safe_path "$input_dir" || ! is_safe_path "$output_dir"; then
        handle_error 1 "Invalid directory path" "ERROR"
        return 1
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Process images in parallel
    find "$input_dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.webp" \) | \
        xargs -P "$MAX_THREADS" -I{} bash -c '
            input="{}"
            output="'"$output_dir"'/$(basename "$input" | sed "s/\.[^.]*$/.'"$format"'/")"
            if [[ "$input" != "$output" ]]; then
                convert "$input" -quality '"$quality"' "$output"
                if [[ "'"$OPTIMIZE_BY_DEFAULT"'" == "true" ]]; then
                    optimize_image "$output"
                fi
            fi
        '
    
    log_message "INFO" "Batch processing completed: $input_dir -> $output_dir"
    return 0
}

# Apply image filter
apply_filter() {
    local image=$1
    local filter=$2
    local params=${3:-""}
    
    # Validate image path
    if ! is_safe_path "$image"; then
        handle_error 1 "Invalid image path: $image" "ERROR"
        return 1
    fi
    
    # Apply filter
    case $filter in
        "blur")
            if ! convert "$image" -blur "$params" "$image"; then
                handle_error 1 "Failed to apply blur filter" "ERROR"
                return 1
            fi
            ;;
        "sharpen")
            if ! convert "$image" -sharpen "$params" "$image"; then
                handle_error 1 "Failed to apply sharpen filter" "ERROR"
                return 1
            fi
            ;;
        "contrast")
            if ! convert "$image" -contrast "$params" "$image"; then
                handle_error 1 "Failed to apply contrast filter" "ERROR"
                return 1
            fi
            ;;
        *)
            handle_error 1 "Invalid filter: $filter" "ERROR"
            return 1
            ;;
    esac
    
    log_message "INFO" "Applied filter $filter to $image"
    return 0
} 