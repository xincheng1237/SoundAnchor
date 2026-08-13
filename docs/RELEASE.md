# Public release checklist

The source tree is ready for an open-source beta. Before distributing a binary to other users:

1. Select and export the final app icon.
2. Sign the universal app with an Apple Developer ID Application certificate.
3. Package the app as a DMG containing an Applications shortcut, notarize it with Apple, and staple the ticket.
4. Test on a clean macOS 13, 14, and 15 account.
5. Test at least one non-Apple Bluetooth headset and one AirPods model.
6. Publish the source, privacy statement, release notes, and SHA-256 checksum.

The local development build is ad-hoc signed and is intended for the developer's own Mac. It should not be presented as a notarized public binary.
