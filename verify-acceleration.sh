#!/usr/bin/env bash
# verify-acceleration.sh - Test and verify NVIDIA hardware acceleration components

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-functions.sh"

# Set colors for better output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Print header banner
header() {
    echo -e "\n${BLUE}===== $1 =====${NC}\n"
}

# Print success message
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Check if running in a terminal
if [[ -t 1 ]]; then
    USE_COLOR=true
else
    # No color codes if not running in a terminal
    GREEN=""
    RED=""
    YELLOW=""
    BLUE=""
    NC=""
fi

# Display header
header "NVIDIA Hardware Acceleration Verification Tool"
echo "This tool checks the status of hardware acceleration components on your system."
echo "$(date)"
echo ""

# Check for NVIDIA GPU and driver
header "NVIDIA Driver"
if lsmod | grep -q "^nvidia "; then
    print_success "NVIDIA kernel module is loaded"
    
    if command -v nvidia-settings &> /dev/null; then
        VERSION=$(nvidia-settings --version | grep version | awk '{print $4}')
        print_success "NVIDIA driver version: $VERSION"
        
        # Check driver version meets minimum requirement
        MAJOR_VERSION=$(echo "$VERSION" | cut -d'.' -f1)
        if [[ "$MAJOR_VERSION" -lt 470 ]]; then
            print_warning "Driver version is below recommended minimum (470)"
            print_warning "Some acceleration features may not work correctly"
        else
            print_success "Driver version meets minimum requirements (>= 470)"
            
            # Check for newer features in newer drivers
            if [[ "$MAJOR_VERSION" -ge 525 ]]; then
                print_success "Driver version supports CUDA 12 and newer features"
            elif [[ "$MAJOR_VERSION" -ge 510 ]]; then
                print_success "Driver version supports CUDA 11.6 features"
            fi
        fi
        
        # Check for nvidia-drm kernel module with modeset
        if lsmod | grep -q "nvidia_drm"; then
            print_success "nvidia_drm kernel module is loaded"
            
            if grep -q "options nvidia-drm modeset=1" /etc/modprobe.d/nvidia-drm-modeset.conf 2>/dev/null || \
               grep -q "options nvidia-drm modeset=1" /etc/modprobe.d/*.conf 2>/dev/null; then
                print_success "nvidia-drm modeset is enabled in configuration"
            else
                print_warning "nvidia-drm modeset may not be enabled in configuration"
                print_warning "Recommend adding 'options nvidia-drm modeset=1' to /etc/modprobe.d/nvidia-drm-modeset.conf"
            fi
        else
            print_error "nvidia_drm kernel module is not loaded"
            print_warning "Hardware acceleration will not work correctly"
        fi
    else
        print_error "nvidia-settings is not installed"
        print_warning "This indicates NVIDIA drivers may not be installed correctly"
    fi
else
    print_error "NVIDIA kernel module is not loaded"
    print_warning "Hardware acceleration will not work"
fi

# Check for VA-API drivers
header "VA-API Drivers"

# Check NVDEC driver
echo -e "${BLUE}Testing NVDEC driver:${NC}"
if [[ -f /usr/local/lib/dri/nvdec_drv_video.so ]]; then
    print_success "NVDEC driver is installed"
    
    # Try running vainfo with NVDEC driver
    VAINFO_OUTPUT=$(LIBVA_DRIVERS_PATH=/usr/local/lib/dri:/usr/lib/x86_64-linux-gnu/dri LIBVA_DRIVER_NAME=nvdec vainfo 2>&1)
    if echo "$VAINFO_OUTPUT" | grep -q "va_openDriver"; then
        print_success "NVDEC driver is working"
        
        # Count supported profiles
        PROFILES=$(echo "$VAINFO_OUTPUT" | grep -c "VAProfile")
        if [[ "$PROFILES" -gt 0 ]]; then
            print_success "NVDEC driver supports $PROFILES profiles"
        else
            print_warning "NVDEC driver reports no supported profiles"
        fi
    else
        print_error "NVDEC driver failed to initialize"
        echo "$VAINFO_OUTPUT" | grep -i error | head -3
    fi
else
    print_error "NVDEC driver is not installed"
    print_warning "Firefox may not use hardware acceleration correctly"
fi

# Check VDPAU driver
echo -e "\n${BLUE}Testing VDPAU driver:${NC}"
if [[ -f /usr/local/lib/dri/vdpau_drv_video.so ]]; then
    print_success "VDPAU driver is installed"
    
    # Try running vainfo with VDPAU driver
    VAINFO_OUTPUT=$(LIBVA_DRIVERS_PATH=/usr/local/lib/dri:/usr/lib/x86_64-linux-gnu/dri LIBVA_DRIVER_NAME=vdpau vainfo 2>&1)
    if echo "$VAINFO_OUTPUT" | grep -q "va_openDriver"; then
        print_success "VDPAU driver is working"
        
        # Count supported profiles
        PROFILES=$(echo "$VAINFO_OUTPUT" | grep -c "VAProfile")
        if [[ "$PROFILES" -gt 0 ]]; then
            print_success "VDPAU driver supports $PROFILES profiles"
        else
            print_warning "VDPAU driver reports no supported profiles"
        fi
    else
        print_error "VDPAU driver failed to initialize"
        echo "$VAINFO_OUTPUT" | grep -i error | head -3
    fi
else
    print_error "VDPAU driver is not installed"
    print_warning "Chromium-based browsers may not use hardware acceleration correctly"
fi

# Check browser installations
header "Browser Installations"

check_browser_installation() {
    local name="$1"
    local cmd="$2"
    local run_script="$3"
    
    echo -e "${BLUE}Checking $name:${NC}"
    if command -v "$cmd" &> /dev/null; then
        print_success "$name is installed"
        
        if [[ -f ~/bin/"$run_script" ]]; then
            print_success "Hardware acceleration launch script is installed"
        else
            print_warning "Hardware acceleration launch script is NOT installed"
            print_warning "Use install scripts to set up launch script"
        fi
    else
        print_warning "$name is not installed"
    fi
}

check_browser_installation "Brave Browser" "brave-browser-stable" "run-brave"
check_browser_installation "Chromium" "chromium" "run-chromium"
check_browser_installation "Firefox" "firefox" "run-firefox"
check_browser_installation "Google Chrome" "google-chrome-stable" "run-google-chrome"
check_browser_installation "Opera" "opera" "run-opera"
check_browser_installation "Vivaldi" "vivaldi-stable" "run-vivaldi"

# Check display server
header "Display Server"
if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    print_success "Using Wayland display server"
    print_warning "Hardware acceleration with VDPAU does not work in Wayland"
    print_warning "Firefox should work with NVDEC driver in Wayland"
else
    print_success "Using X11 display server"
    print_success "Hardware acceleration should work with both NVDEC and VDPAU drivers"
fi

# Check for Widevine support for Chromium/Opera
header "Widevine DRM Support"
if [[ -f /opt/google/chrome/WidevineCdm/manifest.json ]]; then
    print_success "Widevine CDM is installed"
    
    if [[ -d /usr/lib/chromium/WidevineCdm ]] || [[ -L /usr/lib/chromium/WidevineCdm ]]; then
        print_success "Widevine is configured for Chromium"
    else
        print_warning "Widevine is not configured for Chromium"
        print_warning "Run 'sudo ./bin/fix-widevine' to enable DRM support"
    fi
    
    if [[ -d /usr/lib/x86_64-linux-gnu/opera/lib_extra/WidevineCdm ]] || \
       [[ -L /usr/lib/x86_64-linux-gnu/opera/lib_extra/WidevineCdm ]]; then
        print_success "Widevine is configured for Opera"
    else
        if command -v opera &> /dev/null; then
            print_warning "Widevine is not configured for Opera"
            print_warning "Run 'sudo ./bin/fix-widevine' to enable DRM support"
        fi
    fi
else
    print_error "Widevine CDM is not installed"
    print_warning "Google Chrome must be installed to provide Widevine CDM"
    print_warning "Install Google Chrome and run 'sudo ./bin/fix-widevine'"
fi

# Summary
header "Summary"

# Check if all essential components are installed
if lsmod | grep -q "^nvidia " && \
   [[ -f /usr/local/lib/dri/nvdec_drv_video.so ]] && \
   [[ -f /usr/local/lib/dri/vdpau_drv_video.so ]]; then
    print_success "All hardware acceleration components are installed"
    
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        print_warning "Firefox should work with hardware acceleration in Wayland"
        print_warning "Chromium-based browsers may have issues in Wayland"
    else
        print_success "Hardware acceleration should work correctly in X11"
    fi
    
    echo ""
    echo "To use hardware acceleration, launch browsers with the scripts:"
    echo "  ~/bin/run-brave"
    echo "  ~/bin/run-chromium"
    echo "  ~/bin/run-firefox"
    echo "  ~/bin/run-google-chrome"
    echo "  ~/bin/run-opera"
    echo "  ~/bin/run-vivaldi"
else
    print_error "Hardware acceleration is not fully configured"
    echo ""
    echo "Please run these scripts to set up hardware acceleration:"
    echo "  sudo ./build-all               # Build all VA-API components"
    echo "  ./install/install-[browser]    # Install browser with acceleration"
    print_warning "Run these scripts one by one and check for errors"
    
    # Check for CUDA support
    if command -v nvcc &> /dev/null; then
        CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $5}' | sed 's/,//')
        print_success "CUDA is installed (version: $CUDA_VERSION)"
    else
        print_warning "CUDA is not installed"
        echo "For CUDA support run: sudo ./scripts/extras/300-enable-cuda-support"
    fi
fi

echo ""
echo "For troubleshooting and more advanced diagnostics, use:"
echo "  LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=nvdec vainfo"
echo ""