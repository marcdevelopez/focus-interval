# Linux Desktop Dependencies

This app relies on system libraries for the Linux desktop runner. Missing
packages can lead to silent failures (no audio, no notifications) even if the
app launches.

## Runtime requirements
- GTK 3 (Flutter Linux embed)
- libnotify (system notifications)
- GStreamer 1.0 + plugins (audio playback for MP3 assets)

## Ubuntu / Debian
```
sudo apt-get update
sudo apt-get install -y \
  libgtk-3-0 \
  libnotify4 \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav
```

## Fedora
```
sudo dnf install -y \
  gtk3 \
  libnotify \
  gstreamer1 \
  gstreamer1-plugins-base \
  gstreamer1-plugins-good \
  gstreamer1-plugins-ugly \
  gstreamer1-libav
```

## Arch / Manjaro
```
sudo pacman -S --needed \
  gtk3 \
  libnotify \
  gstreamer \
  gst-plugins-base \
  gst-plugins-good \
  gst-plugins-ugly \
  gst-libav
```

## openSUSE
```
sudo zypper install -y \
  gtk3 \
  libnotify \
  gstreamer \
  gstreamer-plugins-base \
  gstreamer-plugins-good \
  gstreamer-plugins-ugly \
  gstreamer-plugins-libav
```

## Notes
- If the app launches, GTK is already available; audio and notifications still
  require GStreamer and libnotify.
- MP3 support may require the "ugly" or "libav" plugin set depending on your
  distro. If sounds are silent, install those plugin packages.
- On Fedora, MP3 codecs often come from RPM Fusion (for
  `gstreamer1-plugins-ugly` / `gstreamer1-libav`).
- On openSUSE, MP3 codecs are commonly provided via the Packman repository (for
  `gstreamer-plugins-ugly` / `gstreamer-plugins-libav`).
- Building from source also needs common build tooling (cmake, ninja, pkg-config,
  and GTK dev headers).
- On Linux, the app runs a best-effort dependency check at startup and shows a
  warning if audio or notifications libraries are missing.

## Optional verification
- Notifications (requires `notify-send` from `libnotify-bin` or
  `libnotify-tools`):
  `notify-send "Focus Interval" "Notifications working"`
- Audio (requires GStreamer tools such as `gst-play-1.0`):
  `gst-play-1.0 /path/to/sound.mp3`
