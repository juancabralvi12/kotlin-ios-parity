#!/usr/bin/env bash

set -u

MODE="${1:-run}"
missing=0

check_command() {
  local name="$1"
  local command_name="$2"
  if command -v "$command_name" >/dev/null 2>&1; then
    printf "✓ %s\n" "$name"
  else
    printf "✗ %s (%s not found)\n" "$name" "$command_name"
    missing=1
  fi
}

if [[ "$MODE" != "--build-only" ]]; then
  check_command "Node.js" node
  check_command "curl" curl
fi
check_command "Xcode command-line tools" xcodebuild
check_command "iOS simulator tools" xcrun
if command -v xcodegen >/dev/null 2>&1; then
  printf "✓ XcodeGen\n"
elif [[ -d "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ios/MediaLab.xcodeproj" ]]; then
  printf "✓ Generated Xcode project (XcodeGen optional)\n"
else
  printf "✗ XcodeGen (needed because the generated project is missing)\n"
  missing=1
fi

ANDROID_SDK_PATH="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
if [[ -d "$ANDROID_SDK_PATH" ]]; then
  printf "✓ Android SDK (%s)\n" "$ANDROID_SDK_PATH"
else
  printf "✗ Android SDK (expected under %s)\n" "$ANDROID_SDK_PATH"
  missing=1
fi

if [[ -d "$ANDROID_SDK_PATH/platforms/android-36" || -d "$ANDROID_SDK_PATH/platforms/android-37" ]]; then
  printf "✓ Android SDK Platform 36+\n"
else
  printf "✗ Android SDK Platform 36+\n"
  missing=1
fi

if [[ "$MODE" != "--build-only" ]]; then
  if [[ -x "$ANDROID_SDK_PATH/platform-tools/adb" && -x "$ANDROID_SDK_PATH/emulator/emulator" ]]; then
    printf "✓ Android emulator tools\n"
    if [[ -n "$("$ANDROID_SDK_PATH/emulator/emulator" -list-avds | head -n 1)" ]]; then
      printf "✓ Android virtual device\n"
    else
      printf "✗ Android virtual device (create an AVD in Android Studio)\n"
      missing=1
    fi
  else
    printf "✗ Android emulator tools\n"
    missing=1
  fi
fi

ANDROID_STUDIO_JAVA="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java"
if command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
  printf "✓ Java runtime\n"
elif [[ -x "$ANDROID_STUDIO_JAVA" ]]; then
  printf "✓ Android Studio bundled Java runtime\n"
else
  printf "✗ JDK 17+ (install Android Studio or set JAVA_HOME)\n"
  missing=1
fi

if [[ "$missing" -ne 0 ]]; then
  echo
  if [[ "$MODE" == "--build-only" ]]; then
    echo "Install the missing build prerequisites, then rerun ./build-test.sh."
  else
    echo "Install the missing prerequisites, then rerun ./start-dev.sh."
  fi
  exit 1
fi
