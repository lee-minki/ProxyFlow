#!/bin/bash
# ProxyFlow 빌드 및 패키징 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
DIST_DIR="$PROJECT_DIR/dist"
APP_NAME="ProxyFlow"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

# 버전 정보 가져오기
VERSION=$(grep -E "static let patch = " "$PROJECT_DIR/ProxyFlow/AppVersion.swift" | grep -oE '[0-9]+')
MAJOR=$(grep -E "static let major = " "$PROJECT_DIR/ProxyFlow/AppVersion.swift" | grep -oE '[0-9]+')
MINOR=$(grep -E "static let minor = " "$PROJECT_DIR/ProxyFlow/AppVersion.swift" | grep -oE '[0-9]+')
FULL_VERSION="$MAJOR.$MINOR.$VERSION"

echo "🔨 Building ProxyFlow v$FULL_VERSION..."

# 릴리즈 빌드
swift build -c release

# dist 폴더 정리 및 생성
rm -rf "$DIST_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 실행 파일 복사
cp "$PROJECT_DIR/.build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Info.plist 생성
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.proxyflow.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$FULL_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

# PkgInfo 생성
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "✅ App bundle created: $APP_BUNDLE"

# ZIP 파일 생성
cd "$DIST_DIR"
ZIP_NAME="$APP_NAME-v$FULL_VERSION.zip"
zip -r "$ZIP_NAME" "$APP_NAME.app"
echo "📦 ZIP created: $DIST_DIR/$ZIP_NAME"

# DMG 생성 (선택사항)
if command -v create-dmg &> /dev/null; then
    DMG_NAME="$APP_NAME-v$FULL_VERSION.dmg"
    create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 150 185 \
        --app-drop-link 450 185 \
        "$DMG_NAME" \
        "$APP_NAME.app"
    echo "💿 DMG created: $DIST_DIR/$DMG_NAME"
else
    echo "ℹ️  create-dmg not installed. Skipping DMG creation."
    echo "   Install with: brew install create-dmg"
fi

echo ""
echo "🎉 Build complete!"
echo "   Version: v$FULL_VERSION"
echo "   App: $APP_BUNDLE"
echo "   ZIP: $DIST_DIR/$ZIP_NAME"
