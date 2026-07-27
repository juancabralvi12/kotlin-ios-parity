#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$ROOT_DIR/scripts/check-prerequisites.sh" --build-only

echo
echo "Building and testing iOS…"
"$ROOT_DIR/scripts/ios.sh" test

echo
echo "Building Android…"
"$ROOT_DIR/scripts/android.sh" build

echo
echo "Testing Android…"
"$ROOT_DIR/scripts/android.sh" test

echo
echo "Both apps built and all platform tests passed."
