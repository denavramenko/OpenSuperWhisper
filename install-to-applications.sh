#!/bin/zsh
set -e

# When: after a successful local build of OpenSuperWhisper
# Why: installs the freshly built app into Applications, preferring /Applications if an
#      existing install is there, and keeps the original downloaded release as a one-time backup

BUILT_APP="build/Build/Products/Debug/OpenSuperWhisper.app"
SYSTEM_APPS="/Applications"
USER_APPS="$HOME/Applications"

if [ ! -d "$BUILT_APP" ]; then
    echo "Built app not found at $BUILT_APP"
    echo "Run ./run.sh build first."
    exit 1
fi

if pgrep -x "OpenSuperWhisper" > /dev/null; then
    echo "Quitting running OpenSuperWhisper..."
    osascript -e 'quit app "OpenSuperWhisper"' || true
    sleep 1
fi

# Prefer the location where an existing install already lives.
if [ -d "$SYSTEM_APPS/OpenSuperWhisper.app" ] || [ -d "$SYSTEM_APPS/OpenSuperWhisperDownloaded.app" ]; then
    TARGET_DIR="$SYSTEM_APPS"
elif [ -d "$USER_APPS/OpenSuperWhisper.app" ] || [ -d "$USER_APPS/OpenSuperWhisperDownloaded.app" ]; then
    TARGET_DIR="$USER_APPS"
else
    # Default to /Applications if nothing exists yet.
    TARGET_DIR="$SYSTEM_APPS"
fi

NEW_APP="$TARGET_DIR/OpenSuperWhisper.app"
BACKUP_APP="$TARGET_DIR/OpenSuperWhisperDownloaded.app"

mkdir -p "$TARGET_DIR"

if [ -d "$NEW_APP" ] && [ ! -d "$BACKUP_APP" ]; then
    echo "Renaming existing installed app to OpenSuperWhisperDownloaded.app..."
    mv "$NEW_APP" "$BACKUP_APP"
fi

if [ -d "$NEW_APP" ]; then
    echo "Removing previous local build from $NEW_APP..."
    python3 -c "import shutil, pathlib; shutil.rmtree(pathlib.Path('$NEW_APP'))"
fi

echo "Copying built app to $NEW_APP..."
cp -R "$BUILT_APP" "$NEW_APP"

echo "Ad-hoc signing installed app with entitlements..."
codesign --force --deep --sign - \
    --identifier "ru.starmel.OpenSuperWhisper" \
    --entitlements "OpenSuperWhisper/OpenSuperWhisper.entitlements" \
    "$NEW_APP"

xattr -d com.apple.quarantine "$NEW_APP" 2> /dev/null || true

echo "Installed OpenSuperWhisper.app in $TARGET_DIR"
