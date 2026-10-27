#!/usr/bin/env bash
# One-time setup for macOS/Linux. Run from the project folder: bash setup.sh
set -e
[ -f pubspec.yaml ] && [ -f lib/main.dart ] || { echo "Run from the project folder (pubspec.yaml + lib/main.dart)"; exit 1; }
for d in lib test; do [ -d "$d" ] && cp -r "$d" "${d}_backup"; done
cp pubspec.yaml pubspec.yaml.bak
flutter create --platforms=macos,linux,android,ios,web --org com.example .
for d in lib test; do [ -d "${d}_backup" ] && rm -rf "$d" && mv "${d}_backup" "$d"; done
mv pubspec.yaml.bak pubspec.yaml
flutter pub get
echo "Done. Run: flutter run -d chrome   (or macos / linux)"
