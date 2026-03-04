#!/bin/bash
# Build a proper .app bundle you can double-click and drag to /Applications
set -e

echo "🔨 Building..."
swift build -c release

APP="TelegramVoiceHotkey.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/TelegramVoiceHotkey "$APP/Contents/MacOS/"

cat > "$APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TelegramVoiceHotkey</string>
    <key>CFBundleIdentifier</key>
    <string>com.funktools.telegram-voice-hotkey</string>
    <key>CFBundleName</key>
    <string>Telegram Voice Hotkey</string>
    <key>CFBundleDisplayName</key>
    <string>Telegram Voice Hotkey</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Records audio to send as voice messages to Telegram.</string>
</dict>
</plist>
EOF

echo ""
echo "✅ Built: $APP"
echo ""
echo "To install:"
echo "  cp -r TelegramVoiceHotkey.app /Applications/"
echo ""
echo "Then double-click it from /Applications or Launchpad."
