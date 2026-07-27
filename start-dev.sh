#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--check" ]]; then
  "$ROOT_DIR/scripts/check-prerequisites.sh"
  exit $?
fi

"$ROOT_DIR/scripts/check-prerequisites.sh"

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/medialab.XXXXXX")"
export MEDIALAB_RUN_DIR="$RUN_DIR"

SERVER_PID=""
IOS_LAUNCH_PID=""
ANDROID_LAUNCH_PID=""
CLEANED_UP=0

cleanup() {
  local exit_status=$?

  if [[ "$CLEANED_UP" -eq 1 ]]; then
    return
  fi
  CLEANED_UP=1
  trap - EXIT INT TERM HUP

  echo
  echo "Stopping MediaLab…"

  for child_pid in "$IOS_LAUNCH_PID" "$ANDROID_LAUNCH_PID"; do
    if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
      kill "$child_pid" 2>/dev/null || true
    fi
  done

  if [[ -f "$RUN_DIR/ios.udid" ]]; then
    ios_udid="$(<"$RUN_DIR/ios.udid")"
    xcrun simctl terminate "$ios_udid" com.example.MediaLab >/dev/null 2>&1 || true
    xcrun simctl shutdown "$ios_udid" >/dev/null 2>&1 || true
  fi

  android_sdk_path="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
  adb_path="$android_sdk_path/platform-tools/adb"
  if [[ -x "$adb_path" && -f "$RUN_DIR/android.serial" ]]; then
    android_serial="$(<"$RUN_DIR/android.serial")"
    "$adb_path" -s "$android_serial" shell am force-stop com.example.medialab >/dev/null 2>&1 || true
    "$adb_path" -s "$android_serial" emu kill >/dev/null 2>&1 || true
  elif [[ -f "$RUN_DIR/android.emulator.pid" ]]; then
    emulator_pid="$(<"$RUN_DIR/android.emulator.pid")"
    kill "$emulator_pid" >/dev/null 2>&1 || true
  fi

  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi

  rm -f "$ROOT_DIR/backend/.server.pid"
  rm -rf "$RUN_DIR"
  osascript -e 'tell application "Simulator" to quit' >/dev/null 2>&1 || true

  if [[ "$exit_status" -eq 0 ]]; then
    echo "Backend and both simulators stopped."
  fi
}

trap cleanup EXIT
trap 'exit 130' INT TERM HUP

echo
echo "Building iOS…"
"$ROOT_DIR/scripts/ios.sh" build

echo
echo "Building Android…"
"$ROOT_DIR/scripts/android.sh" build

echo
echo "Starting backend…"
"$ROOT_DIR/scripts/server.sh" >"$ROOT_DIR/backend/.server.log" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" >"$ROOT_DIR/backend/.server.pid"

backend_ready=0
for attempt in {1..30}; do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Backend stopped unexpectedly. See backend/.server.log" >&2
    exit 1
  fi
  if curl -fsS http://localhost:8080/health >/dev/null 2>&1; then
    backend_ready=1
    break
  fi
  sleep 0.2
done

if [[ "$backend_ready" -ne 1 ]]; then
  echo "Backend did not become healthy. See backend/.server.log" >&2
  exit 1
fi
echo "Backend ready at http://localhost:8080"

echo
echo "Launching both simulators…"
"$ROOT_DIR/scripts/ios.sh" launch &
IOS_LAUNCH_PID=$!
"$ROOT_DIR/scripts/android.sh" launch &
ANDROID_LAUNCH_PID=$!

set +e
wait "$IOS_LAUNCH_PID"
IOS_STATUS=$?
IOS_LAUNCH_PID=""
wait "$ANDROID_LAUNCH_PID"
ANDROID_STATUS=$?
ANDROID_LAUNCH_PID=""
set -e

if [[ "$IOS_STATUS" -ne 0 || "$ANDROID_STATUS" -ne 0 ]]; then
  echo "Launch failed (iOS=$IOS_STATUS, Android=$ANDROID_STATUS)." >&2
  exit 1
fi

echo
echo "MediaLab is running:"
echo "  API:     http://localhost:8080"
echo "  iOS:     blank practice app"
echo "  Android: blank practice app"
echo
echo "Press Ctrl-C, close either simulator, or close this terminal to stop everything."

ios_udid="$(<"$RUN_DIR/ios.udid")"
android_serial="$(<"$RUN_DIR/android.serial")"
android_sdk_path="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
adb_path="$android_sdk_path/platform-tools/adb"

while true; do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Backend stopped unexpectedly. See backend/.server.log" >&2
    exit 1
  fi

  if ! xcrun simctl list devices |
    awk -v udid="$ios_udid" 'index($0, udid) && /Booted/ { found=1 } END { exit !found }'; then
    echo "iOS Simulator closed; stopping MediaLab."
    exit 0
  fi

  if [[ "$("$adb_path" -s "$android_serial" get-state 2>/dev/null || true)" != "device" ]]; then
    echo "Android emulator closed; stopping MediaLab."
    exit 0
  fi

  sleep 1
done
