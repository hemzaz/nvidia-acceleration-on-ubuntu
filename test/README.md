# Testing NVIDIA Acceleration Ansible Implementation

This directory contains scripts for testing the NVIDIA acceleration Ansible implementation in different environments.

## Available Test Scripts

### 1. Quickemu VM Test (`test-with-quickemu.sh`)

This script creates a test environment using Quickemu to run Ubuntu with NVIDIA GPU passthrough. It's designed for testing the full implementation with real hardware.

**Requirements:**
- Host machine with NVIDIA GPU
- Quickemu installed
- IOMMU and virtualization support enabled in BIOS
- Linux host with proper VFIO setup for GPU passthrough

**Usage:**
```bash
./test-with-quickemu.sh [output-dir]
```

The script will create a test environment in the specified directory (or `./quickemu-test` by default) with:
- VM configuration file
- Test script to run inside the VM
- Instructions for setting up and running the tests

**What it tests:**
- Basic installation
- Installation with CUDA support
- Browser-specific installation
- Tag-based installation
- Each test generates detailed logs for validation

### 2. Mock Test (`test-mock.sh`)

This script tests the Ansible implementation with mocked NVIDIA hardware. It's designed for syntax and logic validation without requiring real NVIDIA hardware.

**Requirements:**
- Any Linux/Unix system
- Git
- Bash

**Usage:**
```bash
./test-mock.sh
```

The script will:
- Create a temporary test directory
- Clone the repository
- Set up a mock NVIDIA environment
- Patch the Ansible playbook for mock testing
- Run multiple test configurations
- Generate test results

**What it tests:**
- Ansible syntax and structure
- Different installation configurations
- Browser role implementation
- Component dependency chains

## Using the Results

Both test scripts generate detailed logs that can be used to:
1. Verify proper installation flow
2. Check for errors or warnings
3. Validate that all components are properly installed
4. Ensure browser launch scripts and desktop files are created correctly

For real hardware validation, the Quickemu test provides the most comprehensive results.
For quick development feedback, the mock test allows rapid iteration without hardware dependency.

## Adding More Tests

To add more test configurations:
1. For `test-with-quickemu.sh`, edit the `run-test.sh` file generation section
2. For `test-mock.sh`, add new test configurations to the `test_configs` array in the `run_mock_tests` function