#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")" && pwd -P)"
build_root="$project_root/.artifacts/macos"
app_root="$build_root/ScheduledClicker.app"
executable="$app_root/Contents/MacOS/ScheduledClicker"
test_executable="$build_root/SchedulerCoreTests"
archive="$project_root/dist/ScheduledClicker-macOS-universal.zip"
deployment_target="13.0"
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"

case "$build_root" in
  "$project_root"/.artifacts/macos) ;;
  *) echo "Refusing to clean unexpected build path: $build_root" >&2; exit 1 ;;
esac
if [[ -L "$project_root/.artifacts" || -L "$build_root" ]]; then
  echo "Refusing to clean a symlinked build directory." >&2
  exit 1
fi
rm -rf "$build_root"
mkdir -p "$app_root/Contents/MacOS" "$app_root/Contents/Resources" "$project_root/dist"
cp "$project_root/macOS/Info.plist" "$app_root/Contents/Info.plist"

swiftc -O \
  -target "arm64-apple-macos${deployment_target}" -sdk "$sdk_path" \
  -framework AppKit -framework ApplicationServices \
  "$project_root/macOS/Sources/SchedulerCore.swift" \
  "$project_root/macOS/Sources/AppDelegate.swift" \
  "$project_root/macOS/Sources/main.swift" \
  -o "$build_root/ScheduledClicker-arm64"

swiftc -O \
  -target "x86_64-apple-macos${deployment_target}" -sdk "$sdk_path" \
  -framework AppKit -framework ApplicationServices \
  "$project_root/macOS/Sources/SchedulerCore.swift" \
  "$project_root/macOS/Sources/AppDelegate.swift" \
  "$project_root/macOS/Sources/main.swift" \
  -o "$build_root/ScheduledClicker-x86_64"

lipo -create "$build_root/ScheduledClicker-arm64" "$build_root/ScheduledClicker-x86_64" -output "$executable"
chmod +x "$executable"

cp "$project_root/macOS/Tests/SchedulerCoreTests.swift" "$build_root/main.swift"
swiftc \
  -framework AppKit -framework ApplicationServices \
  "$project_root/macOS/Sources/SchedulerCore.swift" \
  "$build_root/main.swift" \
  -o "$test_executable"

"$test_executable"
"$executable" --self-test
plutil -lint "$app_root/Contents/Info.plist"
test "$(lipo -archs "$executable")" = "x86_64 arm64" || test "$(lipo -archs "$executable")" = "arm64 x86_64"

codesign --force --deep --sign - "$app_root"
codesign --verify --deep --strict --verbose=2 "$app_root"

rm -f "$archive"
ditto -c -k --sequesterRsrc --keepParent "$app_root" "$archive"
(
  cd "$project_root/dist"
  shasum -a 256 "ScheduledClicker-macOS-universal.zip" | tee "ScheduledClicker-macOS-universal.sha256"
)
echo "Built: $archive"
