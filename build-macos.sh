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
  "$project_root/macOS/Sources/LoopCore.swift" \
  "$project_root/macOS/Sources/LoopInput.swift" \
  "$project_root/macOS/Sources/NativeUI.swift" \
  "$project_root/macOS/Sources/LoopWindow.swift" \
  "$project_root/macOS/Sources/Localization.swift" \
  "$project_root/macOS/Sources/LocalizationCatalog.swift" \
  "$project_root/macOS/Sources/AppDelegate.swift" \
  "$project_root/macOS/Sources/main.swift" \
  -o "$build_root/ScheduledClicker-arm64"

swiftc -O \
  -target "x86_64-apple-macos${deployment_target}" -sdk "$sdk_path" \
  -framework AppKit -framework ApplicationServices \
  "$project_root/macOS/Sources/SchedulerCore.swift" \
  "$project_root/macOS/Sources/LoopCore.swift" \
  "$project_root/macOS/Sources/LoopInput.swift" \
  "$project_root/macOS/Sources/NativeUI.swift" \
  "$project_root/macOS/Sources/LoopWindow.swift" \
  "$project_root/macOS/Sources/Localization.swift" \
  "$project_root/macOS/Sources/LocalizationCatalog.swift" \
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
cp "$project_root/macOS/Tests/LoopCoreTests.swift" "$build_root/main.swift"
swiftc "$project_root/macOS/Sources/LoopCore.swift" "$build_root/main.swift" -o "$build_root/LoopCoreTests"
"$build_root/LoopCoreTests"
cp "$project_root/macOS/Tests/LocalizationTests.swift" "$build_root/main.swift"
swiftc -framework AppKit "$project_root/macOS/Sources/Localization.swift" "$project_root/macOS/Sources/LocalizationCatalog.swift" "$build_root/main.swift" -o "$build_root/LocalizationTests"
"$build_root/LocalizationTests"
"$executable" --self-test
"$executable" --ui-smoke-test --appearance light --screenshot "$build_root/ui-light.png"
"$executable" --ui-smoke-test --appearance dark --screenshot "$build_root/ui-dark.png"
"$executable" --loop-ui-smoke-test --appearance light --screenshot "$build_root/loop-light.png"
"$executable" --loop-ui-smoke-test --appearance dark --screenshot "$build_root/loop-dark.png"
for appearance in light dark; do
for language in zh en ja ko de; do
  "$executable" --ui-smoke-test --language "$language" --appearance "$appearance" --screenshot "$build_root/ui-$language-$appearance.png"
  "$executable" --loop-ui-smoke-test --language "$language" --appearance "$appearance" --screenshot "$build_root/loop-$language-$appearance.png"
done
done
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
