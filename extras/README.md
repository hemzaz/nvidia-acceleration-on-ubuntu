## youtube-play

A YouTube complementary player for YouTube Downloader.

The player script was created to test `nvdec` and `nvenc` hardware acceleration using NVIDIA graphics.

### Requirements

Install FFmpeg and Python PIP.

```bash
sudo app update
sudo app install -y ffmpeg python3-pip
```

Next, install the YouTube downloader script [yt-dlp](https://github.com/yt-dlp/yt-dlp) as a normal user. The files are placed in `~/.local/bin/`.

```bash
pip3 install --user --upgrade yt-dlp
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

### See also, repo using mpv

https://github.com/marioroy/youtube-play

