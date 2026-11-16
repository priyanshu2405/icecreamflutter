#!/usr/bin/env bash
# One-time setup: creates the android/ and ios/ platform folders, installs the
# Lick It app icons + launch screens and sets the app name. Safe to run more than once.
set -e
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not on your PATH."
  echo "Install it from https://docs.flutter.dev/get-started/install and run this again."
  exit 1
fi

echo "==> Creating Android & iOS project files (your lib/ code is not touched)"
flutter create --platforms=android,ios --org com.lickit --project-name lick_it .

MANIFEST=android/app/src/main/AndroidManifest.xml

echo "==> Installing Waffle Buddy app icons & launch screens (Android adaptive/round/themed icon, iOS icon set)"
cp -R app_icon/platform/android/. android/
rm -f ios/Runner/Assets.xcassets/AppIcon.appiconset/*
cp -R app_icon/platform/ios/. ios/
if ! grep -q 'android:roundIcon' "$MANIFEST"; then
  perl -0pi -e 's#android:icon="\@mipmap/ic_launcher"#android:icon="\@mipmap/ic_launcher"\n        android:roundIcon="\@mipmap/ic_launcher_round"#' "$MANIFEST"
fi

echo "==> Setting app name to \"Lick It\""
sed -i.bak 's/android:label="lick_it"/android:label="Lick It"/' "$MANIFEST" && rm -f "$MANIFEST.bak"
if [ -x /usr/libexec/PlistBuddy ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Lick It" ios/Runner/Info.plist || true
fi

echo "==> Allowing network access (INTERNET permission; plain http only in debug builds for local testing)"
if ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
fi
cat > android/app/src/debug/AndroidManifest.xml <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application android:usesCleartextTraffic="true"/>
</manifest>
XML
if [ -x /usr/libexec/PlistBuddy ]; then
  /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSAllowsLocalNetworking bool true" ios/Runner/Info.plist 2>/dev/null || true
fi

echo "==> Location permission (\"Use my current location\" on the delivery address map)"
if ! grep -q 'android.permission.ACCESS_FINE_LOCATION' "$MANIFEST"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\n    <application#' "$MANIFEST"
fi
if [ -x /usr/libexec/PlistBuddy ]; then
  /usr/libexec/PlistBuddy -c "Add :NSLocationWhenInUseUsageDescription string 'Lick It uses your location to fill in your delivery address and find the nearest store.'" ios/Runner/Info.plist 2>/dev/null || true
fi

echo "==> Getting packages"
flutter pub get

echo ""
echo "Backend address: edit lib/config/api_config.dart (or use --dart-define=API_BASE_URL=...)\nDone! Plug in a phone (or start an emulator/simulator) and run:  flutter run"
