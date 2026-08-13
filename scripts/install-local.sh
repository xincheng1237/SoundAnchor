#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="声锚 SoundAnchor"
SOURCE="$ROOT/dist/$APP_NAME.app"
DESTINATION="$HOME/Applications/$APP_NAME.app"

if [[ ! -d "$SOURCE" ]]; then
  "$ROOT/scripts/build-app.sh"
fi

pkill -x SoundAnchor 2>/dev/null || true
for _ in {1..20}; do
  pgrep -x SoundAnchor >/dev/null || break
  sleep 0.1
done

mkdir -p "$HOME/Applications"
rm -rf "$DESTINATION"
ditto "$SOURCE" "$DESTINATION"
xattr -cr "$DESTINATION"
codesign --verify --deep --strict "$DESTINATION"
open "$DESTINATION"

echo "$DESTINATION"
