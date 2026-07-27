#!/usr/bin/env bash

set -euo pipefail

ACTION="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios"
DERIVED_DATA="$IOS_DIR/DerivedData"
DEVICE_NAME="${IOS_DEVICE:-}"
RUN_DIR="${MEDIALAB_RUN_DIR:-${TMPDIR:-/tmp}}"

if [[ "$ACTION" != "build" && "$ACTION" != "test" && "$ACTION" != "launch" ]]; then
  echo "Usage: scripts/ios.sh build|test|launch" >&2
  exit 2
fi

cd "$IOS_DIR"

if [[ "$ACTION" == "build" || "$ACTION" == "test" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate --quiet
  elif [[ ! -d "MediaLab.xcodeproj" ]]; then
    echo "MediaLab.xcodeproj is missing and XcodeGen is not installed." >&2
    exit 1
  fi

  if [[ "$ACTION" == "build" ]]; then
    xcodebuild \
      -project MediaLab.xcodeproj \
      -scheme MediaLab \
      -sdk iphonesimulator \
      -destination "generic/platform=iOS Simulator" \
      -derivedDataPath "$DERIVED_DATA" \
      CODE_SIGNING_ALLOWED=NO \
      build >/dev/null
    echo "iOS build succeeded"
    exit 0
  fi
fi

if [[ -z "$DEVICE_NAME" ]]; then
  DEVICE_NAME="$(xcrun simctl list devices available |
    awk -F '[()]' '/iPhone/ && /Shutdown|Booted/ { gsub(/^ +| +$/, "", $1); print $1; exit }')"
fi

if [[ -z "$DEVICE_NAME" ]]; then
  echo "No available iPhone simulator was found." >&2
  exit 1
fi

UDID="$(xcrun simctl list devices available |
  awk -F '[()]' -v name="$DEVICE_NAME" '$1 ~ name { print $2; exit }')"

if [[ -z "$UDID" ]]; then
  echo "iOS simulator '$DEVICE_NAME' was not found." >&2
  exit 1
fi

if [[ "$ACTION" == "test" ]]; then
  DEVICE_WAS_BOOTED=0
  if xcrun simctl list devices | awk -v udid="$UDID" 'index($0, udid) && /Booted/ { found=1 } END { exit !found }'; then
    DEVICE_WAS_BOOTED=1
  fi

  cleanup_test_device() {
    if [[ "$DEVICE_WAS_BOOTED" -eq 0 ]]; then
      xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
    fi
  }
  trap cleanup_test_device EXIT INT TERM HUP

  xcodebuild \
    -project MediaLab.xcodeproj \
    -scheme MediaLab \
    -sdk iphonesimulator \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    test >/dev/null
  echo "iOS build and tests succeeded"
  exit 0
fi

echo "$UDID" >"$RUN_DIR/ios.udid"
echo "Booting iOS: $DEVICE_NAME"
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
open -a Simulator
xcrun simctl bootstatus "$UDID" -b

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/MediaLab.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "The iOS app has not been built. Run scripts/ios.sh build first." >&2
  exit 1
fi

xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl launch "$UDID" com.example.MediaLab >/dev/null
echo "iOS launched on $DEVICE_NAME"
