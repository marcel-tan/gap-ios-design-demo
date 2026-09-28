#!/usr/bin/env bash
# Build, install and launch the app on an iPhone simulator.
# Usage: scripts/run-sim.sh [extra launch arguments, e.g. -resetOnboarding | -skipOnboarding]
# Env:   SIM_UDID (preferred) or SIM_DEVICE (default "iPhone 17") selects the simulator.
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID="com.marceltan.demo.gap"
DERIVED="build/DerivedData"

if [ -n "${SIM_UDID:-}" ]; then
  DEST="platform=iOS Simulator,id=$SIM_UDID"
  TARGET="$SIM_UDID"
else
  DEVICE="${SIM_DEVICE:-iPhone 17}"
  DEST="platform=iOS Simulator,name=$DEVICE"
  TARGET="$DEVICE"
fi

xcodebuild build \
  -project Gap.xcodeproj \
  -scheme Gap \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -quiet

xcrun simctl bootstatus "$TARGET" -b >/dev/null
xcrun simctl terminate "$TARGET" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$TARGET" "$DERIVED/Build/Products/Debug-iphonesimulator/Gap.app"
xcrun simctl launch "$TARGET" "$BUNDLE_ID" "$@"
open -a Simulator
