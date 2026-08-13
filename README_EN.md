# SoundAnchor

SoundAnchor is a lightweight, event-driven macOS menu bar utility that prevents Bluetooth headphone output from falling back to low-quality HFP/HSP call audio when macOS selects the headset microphone.

[Download the latest release](https://github.com/xincheng1237/SoundAnchor/releases/latest) · [Chinese README](README.md)

> **Beta notice:** v0.1.0 is ad-hoc signed and not yet notarized by Apple. On first launch, you may need to Control-click the app and choose **Open**, or allow it under **System Settings → Privacy & Security**.

## Features

- Event-driven Core Audio monitoring with no idle polling
- Protects only while Bluetooth output is active by default
- Lets you choose any available input as the anchored microphone
- Supports pause, repair now, and launch at login
- Can hide its menu bar item while protection continues in the background
- Fully local: no network access, telemetry, recording, or audio inspection
- Universal binary for Apple Silicon and Intel Macs; macOS 13 or later
- Native English and Simplified Chinese interface that follows the macOS language setting

## How it works

SoundAnchor listens for changes to the default input, default output, and Core Audio device list. When Bluetooth output is active and the default input moves away from the selected device, SoundAnchor immediately restores the anchored input. It does no polling while idle.

## Build from source

```bash
git clone https://github.com/xincheng1237/SoundAnchor.git
cd SoundAnchor
swift test
./scripts/build-app.sh
```

The build script creates a universal app and a DMG under `dist/`.

See [Troubleshooting](docs/TROUBLESHOOTING.md), [Privacy](PRIVACY.md), [Security](SECURITY.md), and [Contributing](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 SoundAnchor contributors
