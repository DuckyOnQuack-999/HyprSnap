#!/usr/bin/env bash

# Error handling module for HyprSnap
# Provides enhanced error management and logging capabilities

# Error severity levels
declare -rA ERROR_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARNING]=2
    [ERROR]=3
    [CRITICAL]=4
)

# Current log level (default to INFO)
LOG_LEVEL=${LOG_LEVEL:-"INFO"}

# Log file path
LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hyprsnap/hyprsnap.log"

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
}

# Log message with timestamp and severity
log_message() {
    local severity=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if we should log this message based on severity
    if [[ ${ERROR_LEVELS[$severity]} -ge ${ERROR_LEVELS[$LOG_LEVEL]} ]]; then
        echo "[$timestamp] [$severity] $message" >> "$LOG_FILE"
        
        # Also output to stderr for errors and critical issues
        if [[ $severity == "ERROR" || $severity == "CRITICAL" ]]; then
            echo "[$severity] $message" >&2
        fi
    fi
}

# Error handling function
handle_error() {
    local error_code=$1
    local error_message=$2
    local severity=${3:-"ERROR"}
    local should_exit=${4:-true}
    
    log_message "$severity" "$error_message"
    
    if [[ $should_exit == true ]]; then
        exit "$error_code"
    fi
    
    return "$error_code"
}

# Validate file path security with realpath resolution to prevent TOCTOU and traversal attacks
is_safe_path() {
    local path=$1
    
    # Basic path traversal check (kept for early detection)
    if [[ "$path" =~ \.\./ || "$path" =~ /\.\./ ]]; then
        return 1
    fi
    
    # Resolve path to absolute canonical form to prevent symlink attacks
    local resolved_path
    if ! resolved_path=$(realpath -m -- "$path" 2>/dev/null); then
        # If realpath fails, fall back to the original path but log the issue
        log_message "WARNING" "Failed to resolve path: $path"
        resolved_path="$path"
    fi
    
    # Define allowed directories with more comprehensive coverage
    local allowed_dirs=(
        "$HOME"
        "/tmp"
        "${XDG_CONFIG_HOME:-$HOME/.config}"
        "${XDG_CACHE_HOME:-$HOME/.cache}"
        "${XDG_DATA_HOME:-$HOME/.local/share}"
        "$HOME/Pictures"
        "$HOME/Videos"
        "$HOME/Documents"
    )
    
    # Check if resolved path is within allowed directories using realpath for consistency
    for dir in "${allowed_dirs[@]}"; do
        local resolved_dir
        if resolved_dir=$(realpath -m -- "$dir" 2>/dev/null); then
            # Use resolved paths for comparison to prevent bypass via symlinks
            if [[ "$resolved_path" == "$resolved_dir"* ]]; then
                return 0
            fi
        fi
    done
    
    log_message "WARNING" "Path not in allowed directories: $resolved_path"
    return 1
}

# Secure file operation wrapper
secure_file_operation() {
    local file=$1
    local operation=$2
    
    # Validate file path
    if ! is_safe_path "$file"; then
        handle_error 1 "Invalid file path: $file" "ERROR"
        return 1
    fi
    
    # Create secure temporary file
    local temp_file=$(mktemp -p "${TEMP_DIR:-/tmp}" -t "hyprsnap.XXXXXXXX")
    trap 'rm -f "$temp_file"' EXIT
    
    # Perform operation
    case $operation in
        "read")
            if [[ ! -r "$file" ]]; then
                handle_error 1 "Cannot read file: $file" "ERROR"
                return 1
            fi
            cat "$file" > "$temp_file"
            ;;
        "write")
            if [[ ! -w "$(dirname "$file")" ]]; then
                handle_error 1 "Cannot write to directory: $(dirname "$file")" "ERROR"
                return 1
            fi
            cat "$temp_file" > "$file"
            ;;
        *)
            handle_error 1 "Invalid operation: $operation" "ERROR"
            return 1
            ;;
    esac
    
    return 0
}

# Cleanup function
cleanup() {
    local exit_code=$?
    
    # Remove temporary files
    if [[ -d "${TEMP_DIR:-/tmp/hyprsnap}" ]]; then
        find "${TEMP_DIR:-/tmp/hyprsnap}" -type f -name "hyprsnap.*" -mmin +60 -delete
    fi
    
    # Log cleanup
    log_message "INFO" "Cleanup completed with exit code: $exit_code"
    
    exit "$exit_code"
}

# Set up cleanup trap
trap cleanup EXIT

# Ensure consistent error severity handling across modules
validate_severity() {
    local severity=$1
    
    if [[ ! -v ERROR_LEVELS[$severity] ]]; then
        # Default to ERROR if invalid severity provided
        echo "ERROR"
        return 1
    fi
    
    echo "$severity"
    return 0
}

# Enhanced error handler with consistent formatting
handle_error_ex() {
    local error_code=$1
    local error_message=$2
    local severity=${3:-"ERROR"}
    local context=${4:-""}
    local should_exit=${5:-true}
    
    # Validate and normalize severity
    severity=$(validate_severity "$severity")
    
    # Add context to message if provided
    if [[ -n "$context" ]]; then
        error_message="[$context] $error_message"
    fi
    
    log_message "$severity" "$error_message"
    
    # Send to notification system if available and severity warrants it
    if [[ $severity == "ERROR" || $severity == "CRITICAL" ]] && command -v notify-send >/dev/null; then
        notify-send -u critical "HyprSnap Error" "$error_message" 2>/dev/null || true
    fi
    
    if [[ $should_exit == true ]]; then
        exit "$error_code"
    fi
    
    return "$error_code"
}

# Initialize logging when script is sourced
init_logging
