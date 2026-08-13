# Troubleshooting

## The audio still sounds like low-quality call audio

1. Open SoundAnchor and confirm **Enable audio quality protection** is checked.
2. Select the Mac's built-in microphone under **Anchored input device**.
3. Confirm the Bluetooth headset is the current output device.
4. Choose **Repair now**.
5. Quit conferencing, recording, voice-assistant, or browser applications that may explicitly request the headset microphone.

Some applications choose their own input device instead of following the macOS system default. Set the microphone inside those applications to the Mac's built-in microphone as well.

## The menu bar icon is hidden

Open **SoundAnchor** again from Applications. The settings window appears even while the background protection remains active. Enable **Show in menu bar**.

## The app does not start at login

Open settings, turn **Launch at login** off and on again, then verify the app remains in the same Applications location. Moving the app after enabling launch at login can leave the stored launch path outdated.

## macOS blocks the first launch

The current beta is not yet notarized. In Finder, Control-click SoundAnchor and choose **Open**. If macOS still blocks it, use **System Settings → Privacy & Security → Open Anyway** only if the DMG came from this repository's official Releases page and its checksum matches the published value.

## Reporting a headset compatibility issue

Include the macOS version, Mac model, headset model and firmware, input/output device names, and exact reproduction steps. Do not upload recordings or private system logs.
