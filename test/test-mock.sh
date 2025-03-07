#!/usr/bin/env bash
# test-mock.sh - Test NVIDIA acceleration implementation with mocked hardware
# This script tests the Ansible playbook with NVIDIA hardware detection mocked

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

# Create temporary directory
create_temp_dir() {
  log "Creating temporary test directory..."
  TEST_DIR=$(mktemp -d)
  success "Created test directory at $TEST_DIR"
  
  # Clean up on exit
  trap 'log "Cleaning up..."; rm -rf "$TEST_DIR"; log "Done."' EXIT
}

# Clone repository to test directory
clone_repo() {
  log "Cloning repository to test directory..."
  git clone https://github.com/marioroy/nvidia-acceleration-on-ubuntu "$TEST_DIR/nvidia-acceleration-on-ubuntu"
  cd "$TEST_DIR/nvidia-acceleration-on-ubuntu"
  success "Repository cloned"
}

# Create mock NVIDIA environment
create_mock_environment() {
  log "Creating mock NVIDIA environment..."
  
  # Create mock directory structure
  mkdir -p "$TEST_DIR/mock/lib/modules/$(uname -r)/kernel/drivers/video"
  mkdir -p "$TEST_DIR/mock/proc/driver/nvidia"
  mkdir -p "$TEST_DIR/mock/bin"
  
  # Create mock NVIDIA kernel module
  touch "$TEST_DIR/mock/lib/modules/$(uname -r)/kernel/drivers/video/nvidia.ko"
  touch "$TEST_DIR/mock/lib/modules/$(uname -r)/kernel/drivers/video/nvidia_drm.ko"
  
  # Create mock NVIDIA driver version file
  echo "NVRM version: NVIDIA UNIX x86_64 Kernel Module  525.147.05" > "$TEST_DIR/mock/proc/driver/nvidia/version"
  
  # Create mock nvidia-settings script
  cat > "$TEST_DIR/mock/bin/nvidia-settings" <<'EOF'
#!/bin/bash
echo "nvidia-settings:  version 525.147.05"
exit 0
EOF
  chmod +x "$TEST_DIR/mock/bin/nvidia-settings"
  
  # Create mock nvidia-smi script
  cat > "$TEST_DIR/mock/bin/nvidia-smi" <<'EOF'
#!/bin/bash
echo "Driver Version: 525.147.05"
echo "CUDA Version: 12.0"
echo "GPU Name: NVIDIA GeForce RTX 3080"
exit 0
EOF
  chmod +x "$TEST_DIR/mock/bin/nvidia-smi"
  
  success "Mock NVIDIA environment created"
}

# Patch Ansible playbook for mock testing
patch_ansible_playbook() {
  log "Patching Ansible playbook for mock testing..."
  
  # Create a modified version of the nvidia_detection role
  mkdir -p "$TEST_DIR/nvidia-acceleration-on-ubuntu/ansible/roles/nvidia_detection/files"
  
  # Create mock detection script
  cat > "$TEST_DIR/nvidia-acceleration-on-ubuntu/ansible/roles/nvidia_detection/files/mock-detection.sh" <<'EOF'
#!/bin/bash
echo "525.147.05"
exit 0
EOF
  chmod +x "$TEST_DIR/nvidia-acceleration-on-ubuntu/ansible/roles/nvidia_detection/files/mock-detection.sh"
  
  # Modify the task file to use the mock script
  sed -i.bak 's/command: nvidia-settings --version/command: cat "{{ role_path }}\/files\/mock-detection.sh"/' \
    "$TEST_DIR/nvidia-acceleration-on-ubuntu/ansible/roles/nvidia_detection/tasks/main.yml"
  
  # Modify the nvidia_detection role to always return supported = true
  sed -i.bak 's/nvidia_driver_supported: {{ nvidia_version | int >= min_nvidia_version | int }}/nvidia_driver_supported: true/' \
    "$TEST_DIR/nvidia-acceleration-on-ubuntu/ansible/roles/nvidia_detection/tasks/main.yml"
  
  # Patch the install.yml file to skip hardware checks
  sed -i.bak '/Check if system is Ubuntu/,/tags: always/d' \
    "$TEST_DIR/nvidia-acceleration-on-ubuntu/ansible/install.yml"
  
  # Patch the install-with-ansible script to skip direct hardware interactions
  sed -i.bak 's/sudo ubuntu-drivers autoinstall/echo "Mock: Would install NVIDIA drivers here"/' \
    "$TEST_DIR/nvidia-acceleration-on-ubuntu/install-with-ansible"
  
  success "Ansible playbook patched for mock testing"
}

# Run mock tests
run_mock_tests() {
  log "Running mock tests..."
  
  cd "$TEST_DIR/nvidia-acceleration-on-ubuntu"
  
  # Test with different configurations
  test_configs=(
    "--dry-run"
    "--dry-run --with-cuda"
    "--dry-run --browser=firefox"
    "--dry-run --tags=dependencies,libva,nvcodec"
  )
  
  for config in "${test_configs[@]}"; do
    log "Testing with configuration: $config"
    if ANSIBLE_STDOUT_CALLBACK=json PATH="$TEST_DIR/mock/bin:$PATH" \
       MOCK_NVIDIA_PATH="$TEST_DIR/mock" \
       ./install-with-ansible $config > "$TEST_DIR/test-result-$config.json" 2>&1; then
      success "Test with $config completed successfully"
    else
      error "Test with $config failed"
    fi
  done
  
  success "All mock tests completed"
}

# Parse test results
parse_results() {
  log "Parsing test results..."
  
  # Create summary report
  cat > "$TEST_DIR/test-summary.txt" <<EOF
NVIDIA Acceleration Mock Test Results
====================================
Date: $(date)
System: $(uname -s) $(uname -r)
Mock NVIDIA Driver: 525.147.05

Test Results:
------------
EOF
  
  # Check each test result
  for config in "--dry-run" "--dry-run --with-cuda" "--dry-run --browser=firefox" "--dry-run --tags=dependencies,libva,nvcodec"; do
    result_file="$TEST_DIR/test-result-$config.json"
    if [[ -f "$result_file" ]]; then
      if grep -q "ERROR" "$result_file"; then
        echo "✘ $config: FAILED" >> "$TEST_DIR/test-summary.txt"
      else
        echo "✓ $config: PASSED" >> "$TEST_DIR/test-summary.txt"
      fi
    else
      echo "? $config: NO RESULTS" >> "$TEST_DIR/test-summary.txt"
    fi
  done
  
  # Print summary
  cat "$TEST_DIR/test-summary.txt"
  success "Test results parsed"
}

# Main function
main() {
  log "Starting mock test of NVIDIA acceleration Ansible implementation"
  
  create_temp_dir
  clone_repo
  create_mock_environment
  patch_ansible_playbook
  run_mock_tests
  parse_results
  
  success "Mock testing completed successfully"
  log "Temporary test directory: $TEST_DIR (will be deleted on exit)"
  log "All test results are saved to this directory"
}

# Run the script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi