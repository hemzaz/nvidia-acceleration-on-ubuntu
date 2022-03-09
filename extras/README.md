## youtube-play

A YouTube complementary player for YouTube Downloader.

This requires NVIDIA graphics to run. The script was created to test `nvdec` and `nvenc` hardware acceleration. Another use-case is playing HDR content from YouTube.

### Requirements

Install FFmpeg and Python PIP.

```bash
sudo app update
sudo app install -y ffmpeg python3-pip
```

Next, run the following command as a normal user. That will install the YouTube downloader script [yt-dlp](https://github.com/yt-dlp/yt-dlp) to `~/.local/bin/`.

```bash
pip3 install --user --upgrade yt-dlp
```

### Usage

The YouTube URL is "Best 8k HDR of 2020 Dolby Vision".

```bash
youtube-play URL -F, --list-formats
youtube-play https://youtu.be/Jz9TdfXlTgs -F
youtube-play https://youtu.be/Jz9TdfXlTgs --list-formats

youtube-play URL [VIDEO_FORMAT_CODE]
youtube-play https://youtu.be/Jz9TdfXlTgs      # 720p (vp9/HDR preferred)
youtube-play https://youtu.be/Jz9TdfXlTgs 136  # 720p avc1 FPS 24
youtube-play https://youtu.be/Jz9TdfXlTgs 247  # 720p vp9  FPS 24
youtube-play https://youtu.be/Jz9TdfXlTgs 698  # 720p av01 FPS 24 HDR
youtube-play https://youtu.be/Jz9TdfXlTgs 334  # 720p vp9  FPS 24 HDR
```

This YouTube URL is "Switzerland in 8K ULTRA HD HDR - Heaven of Earth".

```bash
youtube-play URL [VIDEO_FORMAT_CODE]
youtube-play https://youtu.be/linlz7-Pnvw      # 720p (vp9/HDR preferred)
youtube-play https://youtu.be/linlz7-Pnvw 136  # 720p avc1 FPS 30
youtube-play https://youtu.be/linlz7-Pnvw 247  # 720p vp9  FPS 30
youtube-play https://youtu.be/linlz7-Pnvw 698  # 720p av01 FPS 60 HDR
youtube-play https://youtu.be/linlz7-Pnvw 334  # 720p vp9  FPS 60 HDR
```

You can control the playing process while playing a video using interactive commands.

```text
f            toggle full screen
p, SPACE     pause
q, ESCAPE    quit
```

