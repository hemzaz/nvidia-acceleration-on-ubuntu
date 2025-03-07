#!/usr/bin/env bash
# Common functions for NVIDIA acceleration scripts
# This file provides shared utilities for consistent error handling and security

# Error handling function that prints error message and exits with code
fail() {
    echo "ERROR: $1" >&2
    exit "${2:-1}"  # Default to exit code 1 if not specified
}

# Warning function that prints warning but continues execution
warn() {
    echo "WARNING: $1" >&2
}

# Info function for standardized messaging
info() {
    echo "INFO: $1"
}

# Success function for standardized messaging
success() {
    echo "SUCCESS: $1"
}

# Check if running as root
check_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        if [[ "$1" == "required" ]]; then
            return 0  # Success, root is required and we are root
        else
            fail "This script should not be run as root" 2
        fi
    else
        if [[ "$1" == "required" ]]; then
            fail "This script must be run as root" 2
        else
            return 0  # Success, non-root is required and we are non-root
        fi
    fi
}

# Check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        if [[ "$2" == "install" ]]; then
            info "Installing required command: $1"
            sudo apt update -y && sudo apt install -y "$1" || fail "Failed to install $1"
        else
            fail "Required command not found: $1" 127
        fi
    fi
}

# Check for NVIDIA GPU and drivers
check_nvidia() {
    if ! lsmod | grep -q "^nvidia "; then
        warn "NVIDIA kernel module not loaded. Hardware acceleration may not work."
        return 1
    fi
    
    if ! command -v nvidia-settings &> /dev/null; then
        warn "nvidia-settings not found. Hardware acceleration may not work."
        return 1
    fi
    
    # Check driver version meets minimum requirement
    if command -v nvidia-settings &> /dev/null; then
        version=$(/usr/bin/nvidia-settings --version | grep -o "version.*" | cut -d' ' -f2 | cut -d'.' -f1)
        if [[ -z "$version" ]]; then
            warn "Could not determine NVIDIA driver version"
            return 1
        fi
        
        if [[ "$version" -lt 470 ]]; then
            warn "NVIDIA driver version $version is below recommended minimum (470)"
            return 1
        fi
    fi
    
    return 0
}

# Check if VA-API drivers are installed
check_vaapi() {
    local driver_type="$1"  # nvdec or vdpau
    
    if [[ ! -f "/usr/local/lib/dri/${driver_type}_drv_video.so" ]]; then
        warn "${driver_type} VA-API driver not found"
        return 1
    fi
    
    return 0
}

# Create directory safely
make_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || fail "Failed to create directory: $dir"
    fi
    
    # Check if we can write to the directory
    if [[ ! -w "$dir" ]]; then
        fail "Cannot write to directory: $dir"
    fi
}

# Download file securely
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"
    
    info "Downloading $description from $url"
    
    # Ensure directory exists
    make_directory "$(dirname "$output")"
    
    # Download with security options
    if command -v curl &> /dev/null; then
        if ! curl --fail --tlsv1.2 --proto =https --connect-timeout 30 -s -L -o "$output" "$url"; then
            fail "Failed to download $description"
        fi
    elif command -v wget &> /dev/null; then
        if ! wget --https-only --secure-protocol=TLSv1_2 -q --timeout=30 -O "$output" "$url"; then
            fail "Failed to download $description"
        fi
    else
        fail "Neither curl nor wget is available for download"
    fi
    
    # Verify download was successful
    if [[ ! -s "$output" ]]; then
        fail "Downloaded $description is empty"
    fi
}

# Verify file exists before copying
safe_copy() {
    local src="$1"
    local dst="$2"
    
    # Check source exists
    if [[ ! -f "$src" ]]; then
        fail "Source file does not exist: $src"
    fi
    
    # Ensure target directory exists
    make_directory "$(dirname "$dst")"
    
    # Copy file
    cp -f "$src" "$dst" || fail "Failed to copy file from $src to $dst"
}

# Safely execute a command with error handling
safe_exec() {
    "$@" || fail "Command failed: $*"
}

# Check if a browser is installed
check_browser() {
    local browser="$1"
    
    case "$browser" in
        brave)
            command -v brave-browser-stable &> /dev/null
            ;;
        chromium)
            command -v chromium &> /dev/null
            ;;
        firefox)
            command -v firefox &> /dev/null || [[ -x ~/firefox/firefox ]]
            ;;
        chrome)
            command -v google-chrome-stable &> /dev/null
            ;;
        opera)
            command -v opera &> /dev/null
            ;;
        vivaldi)
            command -v vivaldi-stable &> /dev/null
            ;;
        *)
            fail "Unknown browser: $browser"
            ;;
    esac
    
    return $?
}

# Test VA-API driver functionality
test_vaapi() {
    local driver="${1:-nvdec}"
    
    if ! command -v vainfo &> /dev/null; then
        warn "vainfo command not found, cannot test VA-API drivers"
        return 1
    fi
    
    info "Testing VA-API with $driver driver..."
    
    # Run vainfo with the specified driver
    LIBVA_DRIVERS_PATH=/usr/local/lib/dri:/usr/lib/x86_64-linux-gnu/dri \
    LIBVA_DRIVER_NAME="$driver" \
    vainfo
    
    # Check if any supported profiles were found
    if LIBVA_DRIVERS_PATH=/usr/local/lib/dri:/usr/lib/x86_64-linux-gnu/dri \
       LIBVA_DRIVER_NAME="$driver" \
       vainfo 2>&1 | grep -q "number of supported profiles: 0"; then
        warn "No supported profiles found for $driver driver"
        return 1
    fi
    
    # Check for any errors reported by vainfo
    if LIBVA_DRIVERS_PATH=/usr/local/lib/dri:/usr/lib/x86_64-linux-gnu/dri \
       LIBVA_DRIVER_NAME="$driver" \
       vainfo 2>&1 | grep -q -i "error"; then
        warn "Errors detected when testing $driver driver"
        return 1
    fi
    
    success "$driver VA-API driver is working"
    return 0
}

# Detect display server type
detect_display_server() {
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        echo "wayland"
    else
        echo "x11"
    fi
}

# Calculate display scaling factor
get_scale_factor() {
    local scale
    
    scale=$(xrdb -query Xft.dpi 2>/dev/null | awk '/^Xft.dpi:/ {printf("%.9f", $2 / 96)}')
    
    if [[ -z "$scale" ]]; then
        echo "1.000000000"  # Default if not detected
    else
        echo "$scale"
    fi
}

# Get nvidia-settings version
get_nvidia_version() {
    if command -v nvidia-settings &> /dev/null; then
        nvidia-settings --version | grep -o "version.*" | cut -d' ' -f2
    else
        echo "not installed"
    fi
}