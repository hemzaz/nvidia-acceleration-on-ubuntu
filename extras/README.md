# Extra Tools for NVIDIA Acceleration Testing

This directory contains additional tools for testing and verifying NVIDIA hardware acceleration.

## youtube-play

A YouTube complementary player for testing hardware acceleration.

The player script was created to test `nvdec` and `nvenc` hardware acceleration using NVIDIA graphics. It provides an excellent way to verify that your hardware acceleration setup is working correctly.

### Requirements

Install FFmpeg and Python PIP:

```bash
sudo apt update
sudo apt install -y ffmpeg python3-pip
```

Next, install the YouTube downloader script [yt-dlp](https://github.com/yt-dlp/yt-dlp) as a normal user. The files are placed in `~/.local/bin/`:

```bash
pip3 install --user --upgrade yt-dlp
```

### How It Works with Ansible Installation

When you install using the Ansible implementation, the script dependencies are automatically handled. The player works best after completing either:

```bash
# Full installation
sudo ./install-with-ansible

# Or with CUDA support for even better performance
sudo ./install-with-ansible --with-cuda
```

### Usage

The YouTube URL in the usage is "Best 8k HDR of 2020 Dolby Vision".

```bash
Usage:
  youtube-play URL -F, --list-formats
  youtube-play https://youtu.be/Jz9TdfXlTgs -F
  youtube-play https://youtu.be/Jz9TdfXlTgs --list-formats

  youtube-play URL [VIDEO_FORMAT_CODE]
  youtube-play https://youtu.be/Jz9TdfXlTgs      #  auto auto
  youtube-play https://youtu.be/Jz9TdfXlTgs 136  #  720p avc1
  youtube-play https://youtu.be/Jz9TdfXlTgs 247  #  720p vp9
  youtube-play https://youtu.be/Jz9TdfXlTgs 698  #  720p av01 HDR
  youtube-play https://youtu.be/Jz9TdfXlTgs 334  #  720p vp9  HDR
  youtube-play https://youtu.be/Jz9TdfXlTgs 137  # 1080p avc1
  youtube-play https://youtu.be/Jz9TdfXlTgs 248  # 1080p vp9
  youtube-play https://youtu.be/Jz9TdfXlTgs 699  # 1080p av01 HDR
  youtube-play https://youtu.be/Jz9TdfXlTgs 335  # 1080p vp9  HDR
```

You can control the playing process while playing a video using interactive commands.

```text
  f            toggle full screen
  p, SPACE     pause
  q, ESCAPE    quit
```

### See also, YouTube player using Mpv

https://github.com/marioroy/youtube-play

