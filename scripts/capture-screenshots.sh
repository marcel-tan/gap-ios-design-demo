#!/usr/bin/env bash
# Drives every screen with the ScreenshotTourTests XCUITest and writes PNGs.
#
#   scripts/capture-screenshots.sh [output-dir]
#
# Defaults: docs/screenshots. SIM_UDID or SIM_DEVICE (default "iPhone 17") selects the simulator.
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p build
OUT="$(mkdir -p "${1:-docs/screenshots}" && cd "${1:-docs/screenshots}" && pwd)"

if [ -n "${SIM_UDID:-}" ]; then
  DEST="platform=iOS Simulator,id=$SIM_UDID"
else
  DEST="platform=iOS Simulator,name=${SIM_DEVICE:-iPhone 17}"
fi

TEST_RUNNER_SCREENSHOT_DIR="$OUT" xcodebuild test \
  -project Gap.xcodeproj \
  -scheme Gap \
  -destination "$DEST" \
  -derivedDataPath build/DerivedData \
  -only-testing:GapUITests/ScreenshotTourTests \
  2>&1 | tee build/screenshots.log | grep -E "error:|failed|Executed|\*\* TEST" || true
STATUS=${PIPESTATUS[0]}

ls -1 "$OUT"/*.png
exit "$STATUS"
