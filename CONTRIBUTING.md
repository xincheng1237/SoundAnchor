# Contributing

Thanks for helping improve SoundAnchor.

## Before opening an issue

Please search existing issues and read [the troubleshooting guide](docs/TROUBLESHOOTING.md). For device-specific problems, include:

- macOS version
- Mac model and processor architecture
- Headset model and firmware version
- Current input and output device names
- Reproduction steps and expected behavior

Do not attach recordings, private system logs, account data, or other sensitive information.

## Development

Requirements: macOS 13 or later, Xcode Command Line Tools, and Swift 5.10 or later.

```bash
swift test
./scripts/build-app.sh
```

Keep the app event-driven. Changes must not add an idle polling loop, network access, analytics, or microphone-content capture.

## Pull requests

- Keep changes focused and explain the user impact.
- Add or update tests for behavior changes.
- Run `swift test` before submitting.
- Update `CHANGELOG.md` for user-visible changes.
- Do not commit `.build/`, `dist/`, local preferences, or signing credentials.
