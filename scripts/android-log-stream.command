#!/usr/bin/env bash

set -uo pipefail

SDK_PATH="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
ADB="$SDK_PATH/platform-tools/adb"

if [[ ! -x "$ADB" ]]; then
  echo "adb was not found at: $ADB" >&2
  read -r -p "Press Return to close."
  exit 1
fi

echo "Waiting for the Android emulator…"
"$ADB" wait-for-device

echo "Streaming MediaLab Android logs. Press Ctrl-C to stop."
echo

"$ADB" logcat -v color AndroidRuntime:E System.out:I '*:S'
