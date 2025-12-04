#!/usr/bin/env bash
# Creates a macOS Application wrapper for qutebrowser with profile picker
# Run this script after darwin-rebuild to create the app in /Applications

set -euo pipefail

APP_NAME="Qutebrowser.app"
APP_PATH="$HOME/Applications/$APP_NAME"
QB_PICKER_GUI="$HOME/.local/bin/qb-picker-gui"

echo "Creating Qutebrowser launcher app at $APP_PATH"

# Remove existing app if present
if [[ -d "$APP_PATH" ]]; then
    echo "Removing existing app..."
    rm -rf "$APP_PATH"
fi

# Create app bundle structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Create the launcher script
cat > "$APP_PATH/Contents/MacOS/qutebrowser-launcher" <<'LAUNCHER'
#!/usr/bin/env bash
# Qutebrowser launcher with profile picker

# Ensure we have a clean environment
export PATH="$HOME/.local/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin"

# Launch the GUI picker
exec "$HOME/.local/bin/qb-picker-gui" "$@"
LAUNCHER

chmod +x "$APP_PATH/Contents/MacOS/qutebrowser-launcher"

# Create Info.plist
cat > "$APP_PATH/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>qutebrowser-launcher</string>
    <key>CFBundleIdentifier</key>
    <string>org.qutebrowser.custom</string>
    <key>CFBundleName</key>
    <string>Qutebrowser</string>
    <key>CFBundleDisplayName</key>
    <string>Qutebrowser</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.12</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>HTTP URL</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>http</string>
                <string>https</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Try to find qutebrowser icon
ICON_SOURCE=""
if [[ -f "/Applications/qutebrowser.app/Contents/Resources/qutebrowser.icns" ]]; then
    ICON_SOURCE="/Applications/qutebrowser.app/Contents/Resources/qutebrowser.icns"
elif command -v qutebrowser >/dev/null 2>&1; then
    # Try to find icon from Nix store
    QB_PATH=$(which qutebrowser)
    QB_DIR=$(dirname "$QB_PATH")
    POSSIBLE_ICON=$(find "$QB_DIR/.." -name "*.icns" -o -name "*qutebrowser*.png" 2>/dev/null | head -1)
    if [[ -n "$POSSIBLE_ICON" ]]; then
        ICON_SOURCE="$POSSIBLE_ICON"
    fi
fi

# Copy icon if found
if [[ -n "$ICON_SOURCE" ]]; then
    cp "$ICON_SOURCE" "$APP_PATH/Contents/Resources/icon.icns"
    echo "Icon copied from: $ICON_SOURCE"
else
    echo "Warning: Could not find qutebrowser icon. App will use default icon."
fi

echo ""
echo "✅ Qutebrowser launcher created successfully!"
echo ""
echo "The app is located at: $APP_PATH"
echo ""
echo "Next steps:"
echo "1. You can now launch Qutebrowser from Spotlight or Applications folder"
echo "2. You'll be prompted to select a profile each time you launch"
echo "3. To set as default browser, go to System Settings > Desktop & Dock > Default web browser"
echo ""
echo "To recreate this launcher after updates, run:"
echo "  bash ~/.config/qutebrowser/create-qb-launcher.sh"
