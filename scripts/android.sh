#!/usr/bin/env bash

set -euo pipefail

ACTION="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
SDK_PATH="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
ADB="$SDK_PATH/platform-tools/adb"
EMULATOR="$SDK_PATH/emulator/emulator"
AVD_NAME="${ANDROID_AVD:-}"
RUN_DIR="${MEDIALAB_RUN_DIR:-${TMPDIR:-/tmp}}"

if [[ "$ACTION" != "build" && "$ACTION" != "test" && "$ACTION" != "launch" ]]; then
  echo "Usage: scripts/android.sh build|test|launch" >&2
  exit 2
fi

if [[ -z "${JAVA_HOME:-}" && -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]]; then
  export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
fi
export ANDROID_HOME="$SDK_PATH"

if [[ "$ACTION" == "build" ]]; then
  "$ANDROID_DIR/gradlew" :app:assembleDebug --console=plain
  echo "Android build succeeded"
  exit 0
fi

if [[ "$ACTION" == "test" ]]; then
  "$ANDROID_DIR/gradlew" :app:testDebugUnitTest --console=plain
  echo "Android tests succeeded"
  exit 0
fi

if [[ -z "$AVD_NAME" ]]; then
  AVD_NAME="$("$EMULATOR" -list-avds | head -n 1)"
fi
if [[ -z "$AVD_NAME" ]]; then
  echo "No Android AVD exists. Create a Pixel-class AVD in Android Studio." >&2
  exit 1
fi

"$ADB" start-server >/dev/null
SERIAL="$("$ADB" devices | awk '$1 ~ /^emulator-/ && $2 == "device" { print $1; exit }')"

if [[ -z "$SERIAL" ]]; then
  echo "Booting Android: $AVD_NAME"
  "$EMULATOR" -avd "$AVD_NAME" -netdelay none -netspeed full >"$RUN_DIR/android-emulator.log" 2>&1 &
  EMULATOR_PID=$!
  echo "$EMULATOR_PID" >"$RUN_DIR/android.emulator.pid"

  for attempt in {1..120}; do
    if ! kill -0 "$EMULATOR_PID" 2>/dev/null; then
      echo "Android emulator stopped during startup. See $RUN_DIR/android-emulator.log" >&2
      exit 1
    fi
    SERIAL="$("$ADB" devices | awk '$1 ~ /^emulator-/ { print $1; exit }')"
    if [[ -n "$SERIAL" ]]; then
      break
    fi
    sleep 1
  done
fi

if [[ -z "$SERIAL" ]]; then
  echo "Android emulator did not register with adb." >&2
  exit 1
fi

echo "$SERIAL" >"$RUN_DIR/android.serial"
"$ADB" -s "$SERIAL" wait-for-device

boot_complete=0
for attempt in {1..180}; do
  if [[ "$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; then
    boot_complete=1
    break
  fi
  sleep 1
done

if [[ "$boot_complete" -ne 1 ]]; then
  echo "Android emulator did not finish booting." >&2
  exit 1
fi

APK_PATH="$ANDROID_DIR/app/build/outputs/apk/debug/app-debug.apk"
if [[ ! -f "$APK_PATH" ]]; then
  echo "The Android app has not been built. Run scripts/android.sh build first." >&2
  exit 1
fi

"$ADB" -s "$SERIAL" install -r "$APK_PATH" >/dev/null
"$ADB" -s "$SERIAL" shell am force-stop com.example.medialab
"$ADB" -s "$SERIAL" shell am start \
  -a android.intent.action.MAIN \
  -c android.intent.category.LAUNCHER \
  -n com.example.medialab/.MainActivity >/dev/null
echo "Android launched on $AVD_NAME ($SERIAL)"
