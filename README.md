## nvidia-acceleration-on-ubuntu

Enable hardware acceleration for NVIDIA graphics on Ubuntu Linux.

* [What's included](#whats-included)
* [Requirements and preparation](#requirements)
* [Install VA-API drivers for NVIDIA graphics](#install-va-drivers)
* [Install Microsoft core fonts](#install-mscorefonts)
* [Install Chromium and derivatives](#install-chromium)
* [Install Firefox as a .deb package](#install-firefox)
* [Review Firefox settings](#firefox-settings)
* [High DPI support](#high-dpi-support)
* [Enable Wayland Display Server](#enable-wayland)
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

This repo was created and tested for NVIDIA graphics on Ubuntu 20.04.4 (Focal) running Xorg (x11). The NVIDIA proprietary driver version 470.57 or higher is required via "Software & Updates" > "Additional Drivers".

In addition, enable modeset for the `nvidia-drm` module. This is a requirement for the NVDEC-enabled VA driver. Look for `nvidia-graphics-drivers-kms.conf` under `/etc/modprobe.d/`. Skip this step if present.

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

**Note:** Enable composition pipeline only if you experience stutters.

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
git clone https://github.com/marioroy/nvidia-acceleration-on-ubuntu
cd nvidia-acceleration-on-ubuntu
sudo bash build-all
```

Or become root and run each script individually and orderly starting with `000-install-dependencies`. Finally, run `ldconfig`.

```bash
sudo root
cd scripts

./000-install-dependencies      # Installs build dependencies
./100-build-libva               # Installs recent VA-API libraries in /usr/local/lib
./200-build-nv-codec-headers    # Installs FFmpeg version of NVIDIA codec header files
./210-build-vaapi-nvidia        # Installs NVDEC-enabled VA-API driver, for Firefox
./220-build-vdpau-va-driver-v9  # Installs VDPAU-enabled VA-API driver, for Google Chrome and derivatives

ldconfig                        # Refresh the dynamic linker cache
exit                            # Exit sudo; remaining steps must run as the normal user
```

The `builddir` folder (once created) serves as a cache folder. Remove `builddir` entirely or the correspondent `*.tar.gz` file(s) to re-fetch/clone from the internet. I'm hoping that the build process succeeds for you as it does for me. However, I may have a package installed that's missing in `000-install-dependencies`. Please reach out if that's the case.

Verify each VA-API driver with `vainfo`.

```bash
LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=nvdec vainfo

LIBVA_DRIVERS_PATH=/usr/local/lib/dri LIBVA_DRIVER_NAME=vdpau vainfo
```

### <a id="install-mscorefonts">Install Microsoft core fonts

A fresh Ubuntu installation will not have the Microsoft fonts Arial and Times New Roman installed. Fortunately, there is an installer package to simplify the process. It requires accepting a couple license agreements. So do this from the terminal. The core font installer does not include the Calibri and Cambria fonts, which are the default fonts in the latest version of Microsoft Office. Google developed Carlito and Caladea fonts that are metric-compatible with the proprietary fonts.

```bash
sudo apt update
sudo apt install -y ttf-mscorefonts-installer
sudo apt install -y fonts-crosextra-carlito fonts-crosextra-caladea
```

That will fetch, extract, and install the Microsoft core fonts Andale Mono, Arial, Arial Black, Comic Sans MS, Courier New, Georgia, Impact, Times New Roman, Trebuchet MS, and Verdana; including Google fonts Carlito and Caladea.

After you log out and log in or relaunch the application these fonts will be available in your system. In Firefox, if you want to match the fonts used by Google Chrome, go to "Settings" > "Fonts and Colors" > "Advanced..." and change the Serif and Sans-serif fonts to "Times New Roman" and "Arial" respectively.

### <a id="install-chromium">Install Chromium and derivatives

The `install` folder includes scripts for installing various browsers. Each script installs a desktop-file and corresponding launch-script to your `~/.local/share/applications` and `~/bin` folders, respectively. This allows further customizations inside launch-scripts without impacting the global environment. For example, Firefox uses the NVDEC-enabled VA driver whereas Brave, Google-Chrome, Opera, and Vivaldi use the VDPAU-enabled VA driver.

**Note:** Hardware video acceleration does not work in Ungoogled-Chromium.

```bash
cd install
./install-brave
./install-chromium       # Installs Ungoogled-Chromium
./install-firefox        # Installs desktop file/launch script
./install-google-chrome
./install-opera
./install-vivaldi
```

**desktop files**

The `Exec` lines refer to launch scripts residing in `$HOME/bin/`.

```bash
$ ls -1 ~/.local/share/applications
brave-browser.desktop
chromium.desktop
firefox.desktop
google-chrome.desktop
opera.desktop
vivaldi-stable.desktop
```

**launch scripts**

Scripts set `LIBVA_DRIVER_NAME` to `nvdec` or `vdpau`, depending on the browser.

```bash
$ ls -1 ~/bin
run-brave
run-chromium
run-firefox
run-google-chrome
run-opera
run-vivaldi
```

### <a id="install-firefox">Install Firefox as a .deb package

Hardware acceleration will not work with Firefox if installed as a snap application (Ubuntu 21.10, 22.04). Instead, install Firefox as a .deb package.

1. Remove the Firefox snap application and associated dep package if installed.

```bash
sudo snap remove --purge firefox
sudo apt autoremove firefox
```

2. Add the Mozilla team PPA to the list of software sources.

```bash
sudo add-apt-repository ppa:mozillateam/ppa
```

3. Change the Firefox package priority to ensure the PPA version is preferred.

```bash
sudo tee /etc/apt/preferences.d/mozilla-firefox >/dev/null <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
```

4. Ensure future Firefox upgrades install automatically.

```bash
sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox >/dev/null <<'EOF'
Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";
EOF
```

5. Install Firefox via apt.

```bash
sudo apt update
sudo apt install firefox
```

### <a id="firefox-settings">Review Firefox settings

Below are the minimum settings applied via "about:config" to enable hardware acceleration. The `media.rdd-ffmpeg.enable` flag must be enabled for h264ify or enhanced-h264ify to work along with VP9. Basically, this allows you to choose to play videos via the h264ify extension or VP9 media by disabling h264ify and enjoy beyond 1080P playback.

```text
Required, enables hardware acceleration using VA-API.
media.ffmpeg.vaapi.enabled                     true

Required, enables hardware VA-API decoding support for WebRTC (e.g. Google Meet).
media.navigator.mediadatadecoder_vpx_enabled   true

Required, for HW acceleration to work using NVIDIA 470 series drivers.
widget.dmabuf.force-enabled                    true

Required, leave this setting true to use the internal decoders for VP8/VP9.
media.ffvpx.enabled                            true

Optional, or false if prefer external FFmpeg including LD_LIBRARY_PATH set.
media.ffvpx.enabled                            false

Optional, disables AV1 content; ensure false if graphics lacks support.
media.av1.enabled                              false

---
The rest are defaults or not set and kept here as informative knownledge.

Enable software render if you want to render on the CPU instead of GPU.
Preferably, leave this setting false since webrender on the GPU is needed
to decode videos in hardware.
gfx.webrender.software                         false

Do not add xrender if missing or set to false or click on the trash icon.
This is a legacy setting that shouldn't be used as it disables WebRender.
gfx.xrender.enabled                            false

Ensure false so to be on a supported code path for using WebRender.
layers.acceleration.force-enabled              false

Ensure enabled, default since Firefox 97.
media.rdd-ffmpeg.enabled                       true
media.rdd-process.enabled                      true
```

Run the install script for Firefox if missed in the prior section.

```bash
cd install
sudo bash install-firefox    # installs desktop-file and launch-script
```

Re-launch Firefox, if running, to spawn via `~/bin/run-firefox` enabling hardware acceleration.

### <a id="high-dpi-support">High DPI Support

First, run gnome-tweaks and adjust "Fonts" > "Scaling Factor". Enter a floating value or press the `+` or `-` buttons until reaching the screen DPI divided by 96. For example, a 109 DPI screen divided by 96 equals 1.14 for the scaling factor rounded to 2 decimal places. That will update the `Xft.dpi` value, preferably matching the screen DPI. Subsequently, adjust the font size to 11 or 10 for "Interface Text", "Document Text", and "Legacy Window Titles"; size 13 or 12 for Monospace Text.

```bash
sudo apt update                    # as super user
sudo apt install -y gnome-tweaks

gnome-tweaks                       # as normal user
xrdb -query                        # Xft.dpi: 109
```

The launch scripts for Chromium-based browsers set the scale-factor automatically, based on the `Xft.dpi` value. You may find that the right edge of the window is not straight all the way to the top. Simply edit the `~/bin/run-*` launch script and adjust the width in 2 pixels increment until a straight edge.

### <a id="enable-wayland">Enable Wayland Display Server

This requires NVIDIA driver 470.x, minimally. Ensure dependencies are installed.

```bash
cat /proc/driver/nvidia/version

sudo apt update
sudo apt install -y xwayland libegl1 libwayland-egl1 libwayland-dev
sudo apt install -y libnvidia-egl-wayland1 libnvidia-egl-wayland-dev
sudo apt install -y libva-wayland2 libxcb-dri3-dev libxcb-present-dev
```

Edit the `/etc/gdm3/custom.conf` file and comment out the line `WaylandEnable=false`.

```text
#WaylandEnable=false
```

Mask the system udev rule responsible for disabling Wayland in GNOME Display Manager.

```bash
sudo ln -sf /dev/null /etc/udev/rules.d/61-gdm.rules
```

Mutter, when used as a Wayland display server, requires the experimental feature `kms-modifiers` through `gsettings`.

```bash
gsettings get org.gnome.mutter experimental-features
gsettings set org.gnome.mutter experimental-features '["kms-modifiers"]'
```

Reboot the machine.

When prompted for your password, click on the gears icon in the lower right hand corner of the login screen and select "Gnome on Wayland". To revert back to `x11`, log out and select "Gnome" on the login screen.

### <a id="watch-hdr-content">Watch HDR content

To play HDR content, see `youtube-play` inside the extras folder.

### <a id="epilogue">Epilogue

Depending on the quality of the video (1080p60 or lesser), the video codec may sometimes not decode on the GPU. For example, AV1 codec. A workaround is to try installing the `enhanced-h264ify` extension to make YouTube stream H.264 videos instead, but also allow VP8/VP9 via the extension settings. To disable AV1 altogether; in Firefox, go to `about:config` and set `media.av1.enabled` to `false`. That will fall back to using another codec such as VP9. Install the `Not yet, AV1` extension for Google Chrome and like browsers.

Running the install script again will not overwrite or remove the associated launch script placed in the `~/bin/` folder, to preserve customizations. Ditto for the uninstall scripts. Copy updated bin script manually.

```bash
cd nvidia-acceleration-on-ubuntu/bin
cp run-firefox ~/bin/.
```

Hardware acceleration is broken in Firefox 102 for NVIDIA graphics. Install a recent [beta](https://ftp.mozilla.org/pub/firefox/releases) to `~/firefox` or wait for the OS vendor to update to the next major release. The `~/bin/run-firefix` script now defaults to launching `~/firefox/firefox` otherwise `/usr/bin/firefox`. Remove the `~/firefox` folder once Firefox 103 is released and installed via `sudo apt upgrade`. Review Firefox settings in the event a new profile is created. Set `media.ffmpeg.vaapi.enabled` to `true`. Optionally, set `media.av1.enabled` to `false` if AV1 is not supported by your graphics card.

```bash
cd ~/Downloads
wget https://ftp.mozilla.org/pub/firefox/releases/103.0b7/linux-x86_64/en-US/firefox-103.0b7.tar.bz2
tar xjf firefox-103.0b7.tar.bz2 -C ~/
```

Some things are still broken in Wayland using the NVIDIA proprietary driver; i.e. nvidia-settings and VDPAU-enabled VA driver not working. Please **do not** send PRs regarding Wayland.

Updates are automatic, by default, in "Software & Updates" > "Updates". Or check manually.

```bash
sudo apt update
sudo apt upgrade
```

Widevine may not work in Chromium (Ungoogled-Chrome) and Opera. This includes h264/aac not working in Opera. To resolve the issue, run the `fix-widevine` script found inside the `bin` folder. It requires Google Chrome on the system as the script makes a symbolic link to Google's `WidevineCdm` folder. The fix for opera is more involved, requiring `libffmpeg.so` from the web. Periodically run the script whenever Opera is updated. Update the WidevineCdm component using Google Chrome, where it resides.

```bash
sudo ./fix-widevine   # as super user
```

Restart Chromium and/or Opera. Chromium may requires 2 restarts.

### Acknowledgement

Thank you, @xtknight for the initial [VP9](https://github.com/xtknight/vdpau-va-driver-vp9) acceleration bits. Likewise and thank you, @xuanruiqi for the [VP9-update](https://github.com/xuanruiqi/vdpau-va-driver-vp9) to include additional fixes. Finally, thank you @elFarto for the [NVDEC-enabled](https://github.com/elFarto/nvidia-vaapi-driver) driver. Both drivers can co-exist with few tweaks to the installation process.

