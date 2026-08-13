# SoundAnchor 0.1.0

First public beta release.

SoundAnchor prevents Bluetooth headphone output from dropping into low-quality HFP/HSP call mode when macOS automatically selects the headset microphone. It keeps the selected Mac microphone as the system input while Bluetooth output remains active.

## Highlights

- Event-driven Core Audio monitoring; no idle polling
- Selectable anchored input device
- Bluetooth-output-only protection by default
- Manual repair and launch-at-login controls
- Optional hidden menu bar mode
- Universal Apple Silicon and Intel build
- No network access, telemetry, recording, or microphone-content inspection

## Requirements

- macOS 13 or later

## Installation

1. Download `SoundAnchor-0.1.0-macOS.dmg`.
2. Open the DMG and drag **声锚 SoundAnchor** to **Applications**.
3. Launch the app and choose the Mac's built-in microphone as the anchored input.

## Beta signing notice

This build is ad-hoc signed and has not yet been notarized by Apple. On first launch, Control-click the app and choose **Open**, or allow it in **System Settings → Privacy & Security**. Only download it from this repository's official Releases page and verify the published SHA-256 checksum.
