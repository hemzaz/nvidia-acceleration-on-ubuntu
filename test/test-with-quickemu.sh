#!/usr/bin/env bash
# test-with-quickemu.sh - Test NVIDIA acceleration implementation in a VM
# This script sets up a test VM with NVIDIA GPU passthrough using Quickemu

set -euo pipefail

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Print functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for required tools
check_dependencies() {
  log "Checking for required dependencies..."
  
  if ! command -v quickemu &> /dev/null; then
    error "quickemu is not installed. Please install it first."
    echo "Installation instructions: https://github.com/quickemu-project/quickemu"
    exit 1
  fi
  
  if ! command -v virt-viewer &> /dev/null; then
    warn "virt-viewer not found. Install for a better VM display experience."
    echo "sudo apt install virt-viewer"
  fi
  
  success "Required dependencies found"
}

# Create VM configuration
create_vm_config() {
  local vm_dir="$1"
  
  mkdir -p "$vm_dir"
  
  log "Creating VM configuration..."
  cat > "$vm_dir/ubuntu-test.conf" <<EOF
# Ubuntu VM for NVIDIA acceleration testing
cpu_cores="4"
ram="8"
disk_size="50G"
iso_url="https://releases.ubuntu.com/22.04/ubuntu-22.04.4-desktop-amd64.iso"
guest_os="linux"
display="sdl"
# NVIDIA GPU passthrough (update PCI address for your system)
gpu_passthrough="true"
pci_devices="0000:01:00.0,0000:01:00.1" # Update with your NVIDIA GPU PCI address

# Additional configuration
boot="efi"
secureboot="off"
EOF

  success "VM configuration created at $vm_dir/ubuntu-test.conf"
  warn "Please update the PCI device address in the config to match your NVIDIA GPU"
  echo "  Run 'lspci | grep -i nvidia' to find your GPU's PCI address"
}

# Create test script to run inside VM
create_test_script() {
  local vm_dir="$1"
  
  log "Creating test script to run inside VM..."
  cat > "$vm_dir/run-test.sh" <<'EOF'
#!/usr/bin/env bash
# This script will be run inside the VM to test NVIDIA acceleration

set -euo pipefail

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${BLUE}===== NVIDIA Acceleration Test Script =====${NC}\n"

# 1. Update system
echo -e "${BLUE}Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

# 2. Install NVIDIA drivers
echo -e "${BLUE}Installing NVIDIA drivers...${NC}"
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers autoinstall

# 3. Install git and other dependencies
echo -e "${BLUE}Installing git and other dependencies...${NC}"
sudo apt install -y git curl wget build-essential

# 4. Clone the repo
echo -e "${BLUE}Cloning NVIDIA acceleration repository...${NC}"
cd ~
git clone https://github.com/marioroy/nvidia-acceleration-on-ubuntu
cd nvidia-acceleration-on-ubuntu

# 5. Install with Ansible (with various options to test)
echo -e "${BLUE}Running Ansible installation...${NC}"

# Test 1: Basic installation
echo -e "${YELLOW}Test 1: Basic installation${NC}"
sudo ./install-with-ansible --verbose
echo -e "${GREEN}Basic installation completed${NC}"

# Record system state
echo "Recording system state after basic installation..."
mkdir -p ~/test-results/basic
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=nvdec vainfo > ~/test-results/basic/vainfo-nvdec.txt 2>&1
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=vdpau vainfo > ~/test-results/basic/vainfo-vdpau.txt 2>&1
nvidia-smi > ~/test-results/basic/nvidia-smi.txt 2>&1
ls -la ~/bin > ~/test-results/basic/bin-dir.txt 2>&1
ls -la ~/.local/share/applications > ~/test-results/basic/desktop-files.txt 2>&1

# Test 2: Reset and install with CUDA
echo -e "${YELLOW}Test 2: Installing with CUDA support${NC}"
sudo rm -rf /usr/local/lib/dri/* # Clean installation
sudo ./install-with-ansible --with-cuda --verbose
echo -e "${GREEN}CUDA installation completed${NC}"

# Record system state
echo "Recording system state after CUDA installation..."
mkdir -p ~/test-results/cuda
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=nvdec vainfo > ~/test-results/cuda/vainfo-nvdec.txt 2>&1
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=vdpau vainfo > ~/test-results/cuda/vainfo-vdpau.txt 2>&1
nvidia-smi > ~/test-results/cuda/nvidia-smi.txt 2>&1
nvcc --version > ~/test-results/cuda/nvcc-version.txt 2>&1

# Test 3: Specific browser installation
echo -e "${YELLOW}Test 3: Installing specific browsers only${NC}"
sudo rm -rf /usr/local/lib/dri/* # Clean installation
sudo rm -rf ~/bin/* # Clean browser scripts
sudo rm -rf ~/.local/share/applications/* # Clean desktop files
sudo ./install-with-ansible --browser=firefox --browser=brave --verbose
echo -e "${GREEN}Browser-specific installation completed${NC}"

# Record system state
echo "Recording system state after browser-specific installation..."
mkdir -p ~/test-results/browser-specific
ls -la ~/bin > ~/test-results/browser-specific/bin-dir.txt 2>&1
ls -la ~/.local/share/applications > ~/test-results/browser-specific/desktop-files.txt 2>&1
cat ~/bin/run-firefox > ~/test-results/browser-specific/run-firefox.txt 2>&1
cat ~/bin/run-brave > ~/test-results/browser-specific/run-brave.txt 2>&1

# Test 4: Advanced tag-based installation
echo -e "${YELLOW}Test 4: Tag-based installation${NC}"
sudo rm -rf /usr/local/lib/dri/* # Clean installation
sudo ./install-with-ansible --tags=dependencies,libva,nvcodec,vaapi_nvidia --verbose
echo -e "${GREEN}Tag-based installation completed${NC}"

# Record system state
echo "Recording system state after tag-based installation..."
mkdir -p ~/test-results/tag-based
ls -la /usr/local/lib/dri > ~/test-results/tag-based/dri-contents.txt 2>&1
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=nvdec vainfo > ~/test-results/tag-based/vainfo-nvdec.txt 2>&1

# Run verify-acceleration.sh script to create comprehensive report
echo -e "${YELLOW}Running verification script...${NC}"
mkdir -p ~/test-results/verification
./verify-acceleration.sh > ~/test-results/verification/verification-report.txt 2>&1

# Create a summary report
echo -e "${BLUE}Creating test summary...${NC}"
cat > ~/test-results/summary.txt <<EOL
NVIDIA Acceleration Test Summary
===============================
Date: $(date)
System: $(lsb_release -ds)
Kernel: $(uname -r)
NVIDIA Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)

Test Results
-----------
1. Basic Installation: $([ -f ~/test-results/basic/vainfo-nvdec.txt ] && grep -q "VAProfile" ~/test-results/basic/vainfo-nvdec.txt && echo "SUCCESS" || echo "FAILURE")
2. CUDA Installation: $([ -f ~/test-results/cuda/nvcc-version.txt ] && echo "SUCCESS" || echo "FAILURE")
3. Browser Installation: $([ -f ~/test-results/browser-specific/run-firefox.txt ] && [ -f ~/test-results/browser-specific/run-brave.txt ] && echo "SUCCESS" || echo "FAILURE")
4. Tag-based Installation: $([ -f ~/test-results/tag-based/vainfo-nvdec.txt ] && grep -q "VAProfile" ~/test-results/tag-based/vainfo-nvdec.txt && echo "SUCCESS" || echo "FAILURE")

See the individual test directories for detailed reports.
EOL

echo -e "${GREEN}All tests completed! Results saved to ~/test-results/${NC}"
echo "To retrieve the test results, shut down the VM and check the shared folder."
EOF

  chmod +x "$vm_dir/run-test.sh"
  success "Test script created at $vm_dir/run-test.sh"
}

# Create instructions
create_instructions() {
  local vm_dir="$1"
  
  log "Creating instructions..."
  cat > "$vm_dir/README.txt" <<EOF
NVIDIA Acceleration Testing Instructions
=======================================

This VM is configured to test the NVIDIA acceleration Ansible implementation.

1. First, edit the ubuntu-test.conf file to set your NVIDIA GPU's PCI address
   - Run 'lspci | grep -i nvidia' on your host to find the correct address
   - Update the 'pci_devices' line in ubuntu-test.conf

2. Launch the VM:
   cd $(realpath "$vm_dir")
   quickemu --vm ubuntu-test.conf

3. After Ubuntu is installed and you've logged in:
   - Open a terminal
   - Run the test script:
     bash /media/[USERNAME]/[SHARED_VOLUME]/run-test.sh
   
4. The test script will:
   - Install NVIDIA drivers
   - Clone the repository
   - Run multiple installation tests with different options
   - Save detailed test results to ~/test-results/

5. After testing, shut down the VM and check the test-results directory
   which will be accessible in the VM's shared folder.

Note: GPU passthrough requires proper host configuration including IOMMU
      support and may not work on all systems.
EOF

  success "Instructions created at $vm_dir/README.txt"
}

# Main function
main() {
  local test_dir="${1:-./quickemu-test}"
  
  log "Setting up test environment at $test_dir"
  
  # Check dependencies
  check_dependencies
  
  # Create testing directory and files
  create_vm_config "$test_dir"
  create_test_script "$test_dir"
  create_instructions "$test_dir"
  
  success "Test environment set up successfully!"
  echo ""
  echo "Next steps:"
  echo "1. Navigate to: $test_dir"
  echo "2. Edit ubuntu-test.conf to set your NVIDIA GPU's PCI address"
  echo "3. Run: quickemu --vm ubuntu-test.conf"
  echo "4. Follow the instructions in README.txt"
}

# Run the script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi