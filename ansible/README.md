# NVIDIA Acceleration on Ubuntu - Ansible Implementation

This directory contains the Ansible implementation for setting up NVIDIA hardware acceleration on Ubuntu Linux. The implementation provides a more robust, idempotent, and maintainable approach to installing and configuring the necessary components.

## Requirements

- Ubuntu/Debian-based system
- NVIDIA GPU with proprietary drivers installed (minimum version 470.57+)
- Ansible 2.9+ installed on the system
- Root/sudo access

## Installation

### Quick Installation

To quickly install with default settings:

```bash
sudo ./install-with-ansible
```

### Advanced Installation

For more control over the installation process:

```bash
# Install only specific components
sudo ./install-with-ansible --tags dependencies,libva,nvcodec,vaapi_nvidia

# Skip browser setup
sudo ./install-with-ansible --skip-tags browsers

# Install with CUDA support
sudo ./install-with-ansible --extra-vars "with_cuda=true"

# Install only specific browsers
sudo ./install-with-ansible --extra-vars "browsers=['firefox','chromium']"
```

## Playbook Structure

- `install.yml`: Main playbook that orchestrates the entire installation
- `group_vars/all.yml`: Global variables and configuration settings

### Roles

1. **common**: Base setup and environment preparation
2. **dependencies**: Installs all required dependencies
3. **nvidia_detection**: Detects and validates NVIDIA driver installation
4. **libva**: Builds and installs libva libraries
5. **nvcodec**: Builds and installs NVIDIA codec headers
6. **vaapi_nvidia**: Builds and installs NVIDIA VA-API driver
7. **vdpau_driver**: Builds and installs VDPAU-to-VA-API bridge
8. **cuda**: Optional CUDA integration
9. **browsers**: Sets up browser launch scripts with hardware acceleration
10. **verification**: Verifies the installation

## Browser Integration

The `browsers` role creates:

- Hardware-accelerated launch scripts in `~/bin/`
- Desktop entries in `~/.local/share/applications/`

Supported browsers:
- Firefox
- Chromium
- Google Chrome
- Brave Browser
- Opera
- Vivaldi

Each browser is configured with the appropriate hardware acceleration flags based on the installed drivers and the display server in use (X11 or Wayland).

## Customization

Edit `group_vars/all.yml` to customize installation parameters:

- `with_cuda`: Enable/disable CUDA support
- `browsers_to_install`: Specify which browsers to configure
- `cleanup_after_install`: Remove build files after installation
- `validate_installation`: Run validation checks after installation

## Verification

To verify your installation after running the playbook:

```bash
# Check if NVDEC driver is installed
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=nvdec vainfo

# Check if VDPAU driver is installed
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=vdpau vainfo
```

## Troubleshooting

If hardware acceleration is not working properly:

1. Verify that your NVIDIA driver version meets the minimum requirement (470.57+)
2. Check if the drivers are properly installed in `/usr/local/lib/dri/`
3. Make sure your browser is launched using the provided scripts in `~/bin/`
4. For Chromium-based browsers, you can verify hardware acceleration at `chrome://gpu`
5. For DRM-protected content (Netflix, etc.), you may need to run `sudo ./bin/fix-widevine`

## Manual Installation

If you prefer to install components manually, you can run individual roles:

```bash
cd ansible
sudo ansible-playbook install.yml --tags dependencies
sudo ansible-playbook install.yml --tags nvidia,libva,nvcodec
sudo ansible-playbook install.yml --tags vaapi_nvidia,vdpau
ansible-playbook install.yml --tags browsers --skip-become
```