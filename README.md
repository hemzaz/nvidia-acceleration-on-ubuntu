## nvidia-acceleration-on-ubuntu

Enable hardware acceleration for NVIDIA graphics on Ubuntu Linux.

* [What's included](#whats-included)
* [Requirements and preparation](#requirements)
* [Install VA-API drivers for NVIDIA graphics](#install-va-drivers)
* [Install Chromium and derivatives](#install-chromium)
* [Review Firefox settings](#firefox-settings)
* [Watch HDR content](#watch-hdr-content)
* [Epilogue](#epilogue)

### <a id="whats-included">What's included

This is an automation **how-to** for installing minimum dependencies and building two VA-API drivers for use with NVIDIA graphics.

```text
build-all  Top-level script for running all scripts inside scripts folder.
bin        Browser launch scripts to be copied to $HOME/bin/.
desktop    Desktop files to be copied to $HOME/.local/share/applications/.
extras     Complementary YouTube player for testing nvdec/nvenc.
scripts    Contains build scripts for the VA-API drivers.
install    Browser install scripts.
uninstall  Browser uninstall scripts.
```

### <a id="requirements">Requirements and preparation

This repo was created and tested for NVIDIA graphics on Ubuntu 20.04.4 (Focal) running Xorg (x11). The NVIDIA proprietary driver version 470.57 or higher is required via `Software & Updates` > `Additional Drivers`.

In addition, enable modeset for the `nvidia-drm` module. This is a requirement for the NVDEC-enabled VA driver.

```bash
sudo tee /etc/modprobe.d/enable-nvidia-modeset.conf >/dev/null <<'EOF'
options nvidia-drm modeset=1
EOF

sudo update-initramfs -u -k all
```

The `200-*` build scripts call nvidia-settings to obtain the version, but isn't installed by default.

```bash
sudo apt update
sudo apt install -y nvidia-settings
```

Optionally enable `ForceCompositionPipeline` for a smoother desktop experience (no more stutters), especially when moving-resizing a terminal window while playing a video. This can be done at the device level; for example `/etc/X11/xorg.conf.d/nvidia-device.conf`.

```bash
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/nvidia-device.conf >/dev/null <<'EOF'
options nvidia-drm modeset=1
Section "Device"
    Identifier    "Device0"
    Driver        "nvidia"
    Option        "ForceCompositionPipeline" "On"
    Option        "ForceFullCompositionPipeline" "On"
EndSection
EOF
```

Finally reboot the machine for the changes to take effect.

### <a id="install-va-drivers">Install VA-API drivers for NVIDIA graphics

The `build-all` script executes all scripts residing under the scripts folder.

```bash
git clone https://github.com/marioroy/nvaccel-on-ubuntu.git
cd nvaccel-on-ubuntu
sudo bash build-all
```

Or become root and run each script individually starting with `000-install-dependencies`.

```bash
sudo root
cd scripts

./000-install-dependencies      # Installs build dependencies
./100-build-libva               # Installs recent VA-API libraries in /usr/local/lib
./200-build-nv-codec-headers    # Installs FFmpeg version of NVIDIA codec header files
./210-build-vaapi-nvidia        # Installs NVDEC-enabled VA-API driver, for Firefox
./220-build-vdpau-va-driver-v9  # Installs VDPAU-enabled VA-API driver, for Google Chrome and derivatives

exit                            # Exit sudo; remaining steps must run as the normal user
```

The `builddir` folder (once created) serves as a cache folder. Remove the correspondent `*.tar.gz` file(s) to re-fetch/clone from the internet. I'm hoping that the build process succeeds for you as it does for me. However, I may have a package installed that's missing in `000-install-dependencies`. Please reach out if that's the case.

Verify each VA-API driver with `vainfo`.

```bash
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=nvdec vainfo

LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=vdpau vainfo
```

### <a id="install-chromium">Install Chromium and derivatives

The `install` folder includes scripts for installing various browsers. Each script installs a desktop-file and corresponding launch-script to your `~/.local/share/applications` and `~/bin` folders, respectively. This allows further customizations in launch-scripts without impacting the global environment. For example, Firefox uses the NVDEC-enabled VA driver whereas Brave-Browser, Chromium-Browser, and Google-Chrome use the VDPAU-enabled VA driver.

**Notes:** For Chromium, choose Ungoogled-Chromium or Chromium-Beta but not both. Hardware video acceleration does not work in Ungoogled-Chromium. Regarding the naming of the scripts, they match the associated desktop files and binaries for consistency.

```bash
cd install
sudo ./install-brave-browser
sudo ./install-chromium          # Installs Ungoogled-Chromium
sudo ./install-chromium-browser  # Installs Chromium-Beta with VA-API support
sudo ./install-firefox           # Installs desktop file/launch script
sudo ./install-google-chrome
```

**desktop files**

The `Exec` lines refer to launch scripts residing in `$HOME/bin/`.

```bash
$ ls -1 ~/.local/share/applications
brave-browser.desktop
chromium.desktop (or)
chromium-browser.desktop
firefox.desktop
google-chrome.desktop
```

**launch scripts**

Scripts set `LIBVA_DRIVER_NAME` to `nvdec` or `vdpau`, depending on the browser.

```bash
$ ls -1 ~/bin
run-brave-browser
run-chromium (or)
run-chromium-browser
run-firefox
run-google-chrome
```

### <a id="firefox-settings">Review Firefox settings

Below are the minimum settings applied via `about:config` to enable hardware acceleration. The `media.rdd-ffmpeg.enable` flag must be enabled for h264ify or enhanced-h264ify to work along with VP9. Basically, this allows you to choose to play videos via the h264ify extension or VP9 media by disabling h264ify and enjoy beyond 1080P playback.

```text
gfx.canvas.azure.accelerated                   true
gfx.webrender.all                              true
gfx.webrender.enabled                          true

Enable software render if you want to render on the CPU instead of GPU.
Preferably, leave this setting false since webrender on the GPU is needed
to decode videos in hardware.
gfx.webrender.software                         false

Do not add xrender if missing or set to false or click on the trash icon.
This is a legacy setting that shouldn't be used as it disables WebRender.
gfx.xrender.enabled                            false

Ensure false so to be on a supported code path for using WebRender.
layers.acceleration.force-enabled              false

media.ffmpeg.dmabuf-textures.enabled           true
media.ffmpeg.vaapi-drm-display.enabled         true
media.ffmpeg.vaapi.enabled                     true
media.ffvpx.enabled                            false

Verify enabled, necessary for the NVIDIA-NVDEC enabled driver to work.
media.rdd-process.enabled                      true

media.rdd-ffmpeg.enabled                       true
media.rdd-vpx.enabled                          false

Enable for NVIDIA 3000+ series graphics using proprietary driver
(v510+) and NVIDIA-NVDEC enabled VA-API driver (v0.0.5+).
Enable also for Intel graphics supporting AV1 decoding.
media.av1.enabled                              false

Enable FFMPEG VA-API decoding support for WebRTC on Linux.
media.navigator.mediadatadecoder_vpx_enabled   true

Enable to help get decoding to work for NVIDIA 470 driver series.
widget.dmabuf.force-enabled                    true
```

Run the install script for Firefox if missed in the prior section.

```bash
cd install
sudo bash install-firefox    # installs desktop-file and launch-script
```

Re-launch Firefox, if running, to spawn via `~/bin/run-firefox` enabling hardware acceleration.

### <a id="watch-hdr-content">Watch HDR content

To play HDR content, see `youtube-play` inside the extras folder.

### <a id="epilogue">Epilogue

Depending on the quality of the video (i.e. 1080p60 or lesser), the video codec may sometimes not decode on the GPU. For example AV1 codec. A workaround is to try installing the `enhanced-h264ify` extension to make YouTube stream H.264 videos instead, but also allow VP8/VP9 via the extension settings.

Running install again will not overwrite or remove the associated launch script placed in the `~/bin/` folder, to preserve customizations. This is true also for the uninstall scripts.

Some things are still broken in Wayland using the NVIDIA proprietary driver; i.e. nvidia-settings and VDPAU-enabled VA driver not working. Please **do not** send PRs regarding Wayland.

Updates are automatic, by default, in `Software & Updates` > `Updates`. Or check manually.

```bash
sudo apt update
sudo apt upgrade
```

Thank you, @xtknight for the initial [VP9](https://github.com/xtknight/vdpau-va-driver-vp9) acceleration bits. Likewise and thank you, @xuanruiqi for the [VP9-update](https://github.com/xuanruiqi/vdpau-va-driver-vp9) to include additional fixes. Finally, thank you @elFarto for the [NVDEC-enabled](https://github.com/elFarto/nvidia-vaapi-driver) driver. Both drivers co-exist with few tweaks to the installation process.

