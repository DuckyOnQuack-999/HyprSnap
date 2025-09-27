#!/usr/bin/env bash

# Recording module for HyprSnap
# Provides enhanced screen recording capabilities with support for multiple formats and hardware acceleration

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../utils/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/config.sh"

# Recording types
declare -rA RECORDING_TYPES=(
    [FULL]="full"
    [AREA]="area"
    [WINDOW]="window"
)

# Supported formats
declare -rA SUPPORTED_FORMATS=(
    [GIF]="gif"
    [MP4]="mp4"
    [WEBM]="webm"
)

# Take a screen recording
record_screen() {
    local type=$1
    local output=$2
    local duration=${3:-0}
    local format=${4:-"gif"}
    local fps=${5:-$DEFAULT_FPS}
    local quality=${6:-$DEFAULT_QUALITY}
    local audio=${7:-false}
    local hw_accel=${8:-false}
    
    # Validate recording type
    if [[ ! -v RECORDING_TYPES[$type] ]]; then
        handle_error 1 "Invalid recording type: $type" "ERROR"
        return 1
    fi
    
    # Validate output path
    if ! is_safe_path "$output"; then
        handle_error 1 "Invalid output path: $output" "ERROR"
        return 1
    fi
    
    # Validate format
    if [[ ! -v SUPPORTED_FORMATS[$format] ]]; then
        handle_error 1 "Unsupported format: $format" "ERROR"
        return 1
    fi
    
    # Create temporary directory
    local temp_dir=$(mktemp -d -p "${TEMP_DIR:-/tmp}" "hyprsnap.XXXXXXXX")
    trap 'rm -rf "$temp_dir"' EXIT
    
    # Detect session type: Wayland vs X11
    local session_type="${XDG_SESSION_TYPE:-wayland}"
    local screen_info
    
    # Get screen dimensions with cross-compositor support
    case $type in
        "FULL")
            if command -v hyprctl > /dev/null 2>&1; then
                # Hyprland
                screen_info=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x),\(.y) \(.width)x\(.height)"')
            elif command -v swaymsg > /dev/null 2>&1; then
                # Sway
                screen_info=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')
            else
                # Generic Wayland fallback
                screen_info=""
            fi
            ;;
        "AREA")
            # slurp works across all Wayland compositors
            screen_info=$(slurp)
            ;;
        "WINDOW")
            if command -v hyprctl > /dev/null 2>&1; then
                # Hyprland
                screen_info=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            elif command -v swaymsg > /dev/null 2>&1; then
                # Sway
                screen_info=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
            else
                # Interactive fallback
                screen_info=$(slurp)
            fi
            ;;
    esac
    
    # Wayland-first recording approach
    if [[ "$session_type" == "wayland" ]]; then
        # Use wf-recorder for Wayland capture
        local raw_recording="${temp_dir}/capture.mkv"
        local base_cmd=(wf-recorder -f "$raw_recording" -r "$fps")
        
        # Add geometry if available
        if [[ -n "$screen_info" ]]; then
            base_cmd+=(-g "$screen_info")
        fi
        
        # Add audio if requested
        if [[ $audio == true ]]; then
            base_cmd+=(--audio)
        fi
        
        # Start wf-recorder with duration support
        if [[ $duration -gt 0 ]]; then
            timeout "${duration}s" "${base_cmd[@]}" || true
        else
            "${base_cmd[@]}"
        fi
        
        # Transcode to requested format with hardware acceleration support
        case $format in
            "gif")
                if ! ffmpeg -y -i "$raw_recording" -vf "fps=$fps,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$output"; then
                    handle_error 1 "Failed to convert to GIF" "ERROR"
                    return 1
                fi
                ;;
            "mp4")
                if [[ $hw_accel == true ]]; then
                    # Try VAAPI first (Intel/AMD), then NVENC (NVIDIA), then software
                    if ffmpeg -y -hwaccel vaapi -vaapi_device /dev/dri/renderD128 -i "$raw_recording" -vf 'format=nv12,hwupload' -c:v h264_vaapi -qp 23 -pix_fmt nv12 "$output"; then
                        : # Success with VAAPI
                    elif ffmpeg -y -i "$raw_recording" -c:v h264_nvenc -preset p4 -rc vbr -cq 23 -pix_fmt yuv420p "$output"; then
                        : # Success with NVENC
                    else
                        # Software fallback
                        ffmpeg -y -i "$raw_recording" -c:v libx264 -crf 23 -preset medium -pix_fmt yuv420p "$output"
                    fi
                else
                    # Software encoding
                    ffmpeg -y -i "$raw_recording" -c:v libx264 -crf 23 -preset medium -pix_fmt yuv420p "$output"
                fi
                
                if [[ $? -ne 0 ]]; then
                    handle_error 1 "Failed to convert to MP4" "ERROR"
                    return 1
                fi
                ;;
            "webm")
                if ! ffmpeg -y -i "$raw_recording" -c:v libvpx-vp9 -crf "$quality" -b:v 0 -c:a libopus -b:a 128k "$output"; then
                    handle_error 1 "Failed to convert to WebM" "ERROR"
                    return 1
                fi
                ;;
        esac
    else
        # X11 fallback using traditional ffmpeg approach
        local ffmpeg_opts=(
            "-f x11grab"
            "-video_size $(echo "$screen_info" | cut -d+ -f1)"
            "-framerate $fps"
            "-i :0.0+$(echo "$screen_info" | cut -d+ -f2,3 | tr '+' ',')"
        )
        
        # Add audio if requested
        if [[ $audio == true ]]; then
            ffmpeg_opts+=(
                "-f alsa"
                "-i default"
                "-c:a aac"
                "-b:a 128k"
            )
        fi
        
        # Add hardware acceleration if requested
        if [[ $hw_accel == true ]]; then
            ffmpeg_opts+=(
                "-c:v h264_nvenc"
                "-preset p1"
                "-tune hq"
            )
        else
            ffmpeg_opts+=(
                "-c:v ${FFMPEG_CODEC:-libx264}"
                "-preset ultrafast"
                "-crf $quality"
            )
        fi
        
        # Add format-specific options
        case $format in
            "gif")
                ffmpeg_opts+=(
                    "-vf split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
                    "-f gif"
                )
                ;;
            "mp4")
                ffmpeg_opts+=(
                    "-pix_fmt yuv420p"
                    "-f mp4"
                )
                ;;
            "webm")
                ffmpeg_opts+=(
                    "-c:v libvpx-vp9"
                    "-crf $quality"
                    "-b:v 0"
                    "-f webm"
                )
                ;;
        esac
        
        # Add duration if specified
        if [[ $duration -gt 0 ]]; then
            ffmpeg_opts+=("-t $duration")
        fi
        
        # Start recording
        if ! ffmpeg "${ffmpeg_opts[@]}" "$output"; then
            handle_error 1 "Failed to record screen" "ERROR"
            return 1
        fi
    fi
    
    # Optimize if enabled
    if [[ $OPTIMIZE_BY_DEFAULT == "true" ]]; then
        optimize_recording "$output" "$format"
    fi
    
    log_message "INFO" "Recording saved to $output"
    return 0
}

# Optimize recording
optimize_recording() {
    local recording=$1
    local format=$2
    
    # Validate recording path
    if ! is_safe_path "$recording"; then
        handle_error 1 "Invalid recording path: $recording" "ERROR"
        return 1
    fi
    
    # Optimize based on format
    case $format in
        "gif")
            if ! gifsicle -O3 "$recording" -o "${recording}.tmp" && mv "${recording}.tmp" "$recording"; then
                handle_error 1 "Failed to optimize GIF" "WARNING"
                return 1
            fi
            ;;
        "mp4")
            if ! ffmpeg -i "$recording" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k "${recording}.tmp" && mv "${recording}.tmp" "$recording"; then
                handle_error 1 "Failed to optimize MP4" "WARNING"
                return 1
            fi
            ;;
        "webm")
            if ! ffmpeg -i "$recording" -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -b:a 128k "${recording}.tmp" && mv "${recording}.tmp" "$recording"; then
                handle_error 1 "Failed to optimize WebM" "WARNING"
                return 1
            fi
            ;;
    esac
    
    log_message "INFO" "Recording optimized: $recording"
    return 0
}

# Batch process recordings
batch_process() {
    local input_dir=$1
    local output_dir=$2
    local format=${3:-"mp4"}
    local quality=${4:-$DEFAULT_QUALITY}
    
    # Validate directories
    if ! is_safe_path "$input_dir" || ! is_safe_path "$output_dir"; then
        handle_error 1 "Invalid directory path" "ERROR"
        return 1
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Process recordings in parallel
    find "$input_dir" -type f \( -name "*.gif" -o -name "*.mp4" -o -name "*.webm" \) | \
        xargs -P "$MAX_THREADS" -I{} bash -c '
            input="{}"
            output="'"$output_dir"'/$(basename "$input" | sed "s/\.[^.]*$/.'"$format"'/")"
            if [[ "$input" != "$output" ]]; then
                ffmpeg -i "$input" -c:v '"$FFMPEG_CODEC"' -crf '"$quality"' "$output"
                if [[ "'"$OPTIMIZE_BY_DEFAULT"'" == "true" ]]; then
                    optimize_recording "$output" "'"$format"'"
                fi
            fi
        '
    
    log_message "INFO" "Batch processing completed: $input_dir -> $output_dir"
    return 0
} 