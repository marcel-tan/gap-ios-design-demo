# DEMO.md — running the Gap iOS demo live

Everything below was run on macOS with Xcode 26.6 (iOS 26.5 Simulator runtime, "iPhone 17").
Deployment target is iOS 17, so any iOS 17+ iPhone simulator works — swap the device name if needed.

## Build

```bash
git clone <this repo> && cd gap-ios-design-demo
brew install xcodegen && xcodegen generate
xcodebuild build \
  -project Gap.xcodeproj -scheme Gap \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -derivedDataPath build/DerivedData
```

`Gap.xcodeproj` is generated from `project.yml` and not checked in: run
`brew install xcodegen && xcodegen generate` once after cloning (and after editing `project.yml`). The only third-party dependency
(Kingfisher, async image loading + cache) is resolved by SwiftPM on first build.

If `xcodebuild` cannot find the runtime for a device that `xcrun simctl list devices available`
shows, pin it in the destination (`name=iPhone 17,OS=26.5`) or repair the SDK mapping with
`xcrun simctl runtime match set iphoneos26.5 <runtime build>`. If two simulators share a name, use
`-destination "platform=iOS Simulator,id=<UDID>"`.

## Run in the simulator

```bash
xcrun simctl boot "iPhone 17" 2>/dev/null || true
open -a Simulator
xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/Gap.app
xcrun simctl launch booted com.marceltan.demo.gap
```

`scripts/run-sim.sh [args]` does the build + install + launch in one step (`SIM_UDID=...` or
`SIM_DEVICE=...` to pick a device).

Launch arguments (append to `simctl launch` or `run-sim.sh`):

| argument           | effect                                                                                    |
|--------------------|-------------------------------------------------------------------------------------------|
| `-resetOnboarding` | show onboarding again; clears wishlist, My Store, recent searches, brand and Encore points |
| `-skipOnboarding`  | mark onboarding complete and land on Home                                                 |
| `-resetState`      | clear persisted state without forcing onboarding                                          |
| `-uiTesting`       | shorten splash and "placing order" delays                                                 |
| `-seedBag`         | pre-load the fall outfit (cardigan M, '90s jeans 28, denim jacket M) into an empty bag     |
| `-figmaOverlay`    | show a tappable Figma node-id badge on every screen (see docs/figma-nodes.md)              |

Wishlist, My Store, recent searches, selected brand, Encore points, the bag (lines + promo + pickup
preference) and order history all persist in `UserDefaults`; `-resetState` clears everything.

Screenshots: `xcrun simctl io booted screenshot shot.png`, or regenerate the whole set in
`docs/screenshots/` with `scripts/capture-screenshots.sh` (runs the opt-in `ScreenshotTourTests`).

## The golden path

Ordering a fall outfit for in-store pickup (PRD §5; Figma S01 → S12):

1. Splash → Onboarding → **Skip** (or **Continue**).
2. Home → *Good evening, Gwenyth · encore Premier · 2,124 pts* → **Fall Layers** hero →
   **Build your fall outfit** rail.
3. Tap **CashSoft Crop Cardigan** → PDP (Modern Red) → size **M** → **Add to Bag** → Item Added → **Continue shopping**.
4. Back → tap **Low Rise '90s Loose Jeans** → size **28** → **Add to Bag** → **Continue shopping**.
5. Header magnifier → search `Icon Denim Jacket` → PDP → size **M** → **Add to Bag** → **View Bag**.
6. Bag → three lines, subtotal **$239.85** → promo **FALL25** → **−$59.96** → total **$194.28** → **Checkout**.
7. Checkout defaults to **Pick up in store · Gap Sainte-Catherine (0.8 km)** and the saved
   *Gap Good Rewards Mastercard •••• 4021* → **Place Order · $194.28**.
8. Confirmation → `Order #GP…`, **+194 Encore points**, pickup store and *Ready today by 6 pm* →
   **View Purchase History** → the order shows the same $194.28 total.

Other entry points: **GAP ▾** wordmark → brand switcher; **Shop** → Fall Edit card / departments;
**Offers** → FALL25 card applies the code to the bag; heart → Wishlist; Account → My Store → Store Locator.

## Tests

Unit tests only (fast, ~10 s after the build):

```bash
xcodebuild test -project Gap.xcodeproj -scheme Gap \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -derivedDataPath build/DerivedData -only-testing:GapTests
```

UI tests only:

```bash
xcodebuild test -project Gap.xcodeproj -scheme Gap \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -derivedDataPath build/DerivedData -only-testing:GapUITests/GapUITests
```

Everything (what CI runs):

```bash
xcodebuild test -project Gap.xcodeproj -scheme Gap \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -derivedDataPath build/DerivedData
```

CI (`.github/workflows/ci.yml`) runs the same on `macos-latest` for every PR and push to `main`,
uploading the `.xcresult` bundle on failure.

## Promo codes

| code       | effect                                    |
|------------|-------------------------------------------|
| `FALL25`   | 25 % off the merchandise subtotal (golden path) |
| `YOURS`    | 30 % off the merchandise subtotal          |
| `ENCORE20` | 20 % off the merchandise subtotal          |
| `SHIPFREE` | free standard shipping (normally $7 under $50) |

Tax (8 %) is estimated on the discounted subtotal; in-store pickup is always free; Encore points are earned
at 1 point per dollar charged (the golden-path order earns 194).
