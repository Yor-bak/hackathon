#!/bin/zsh
# Compila Memorias para el simulador sin necesitar un .xcodeproj (para revisión rápida).
# En Xcode: File > New > App (SwiftUI) y arrastra la carpeta Memorias/*.swift.
set -e
cd "$(dirname "$0")"
OUT=build/Memorias.app
rm -rf build && mkdir -p $OUT
xcrun --sdk iphonesimulator swiftc -swift-version 5 -parse-as-library \
  -target arm64-apple-ios17.0-simulator -O \
  -o $OUT/Memorias Memorias/*.swift
cp Memorias/Resources/* $OUT/ 2>/dev/null || true
cat > $OUT/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>mx.memorias.app</string>
<key>CFBundleExecutable</key><string>Memorias</string>
<key>CFBundleName</key><string>Memorias</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1</string>
<key>CFBundleVersion</key><string>1</string>
<key>MinimumOSVersion</key><string>17.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
<key>UILaunchScreen</key><dict/>
<key>UISupportedInterfaceOrientations</key><array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>
<key>UISupportedInterfaceOrientations~ipad</key><array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>
<key>CFBundleDevelopmentRegion</key><string>es</string>
</dict></plist>
EOF
codesign --force --sign - $OUT
echo "OK: $OUT"
