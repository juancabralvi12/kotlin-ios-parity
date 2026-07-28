#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_COMMAND="$ROOT_DIR/scripts/android-log-stream.command"

if [[ ! -x "$LOG_COMMAND" ]]; then
  echo "Android log command is missing or not executable: $LOG_COMMAND" >&2
  exit 1
fi

exec "$LOG_COMMAND"
