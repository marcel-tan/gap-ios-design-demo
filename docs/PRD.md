# Gap iOS Design Demo — Product Requirements Document

| | |
|---|---|
| **Product** | Gap iOS app (design-first demo replica) |
| **Repo** | https://github.com/marcel-tan/gap-ios-design-demo |
| **Figma** | https://www.figma.com/design/2amCWqHqUoNvHtOQUxtd7I (Gap iOS Design Demo) |
| **Reference app** | Gap: Apparel, Denim and More — https://apps.apple.com/us/app/gap-apparel-denim-and-more/id326347260 |
| **Status** | Draft v1.0 — 2026-09-28 |
| **Owner** | Marcel Tan |
| **Golden path** | Order a fall outfit (cardigan + '90s loose jeans + denim jacket) for in-store pickup |

---

## 1. Summary

Build a native SwiftUI iPhone app that reproduces the core shopping experience of the official Gap iOS app, using official Gap brand assets, and demonstrates a **design-first delivery process**: PRD → wireframes → Figma hi-fi design + clickable prototype → SwiftUI implementation that references Figma design nodes.

The demo is scoped to one end-to-end flow — a returning Encore member assembles a fall outfit, applies a promo code, chooses store pickup, places the order and sees it reflected in her account. Every screen in that flow is designed in Figma before it is coded, and every SwiftUI view carries a `figmaNode` reference back to its design node.

## 2. Goals and non-goals

### Goals
1. **Realistic Gap look and feel** — official wordmark, navy `#002868`, editorial photography, floating pill tab bar, serif wordmark in the tab bar, brand switcher, Encore rewards.
2. **Complete golden path** — launch → home → browse → PDP → add ×3 → bag → promo → checkout → pick a store → confirm → account. No dead ends.
3. **Design traceability** — each user story maps to a Figma node and to a Swift view (see `docs/figma-nodes.md`).
4. **Runs offline** on an iPhone Simulator with bundled catalog data; product imagery loads from gap.com CDN with local placeholders when offline.
5. **Automated proof** — XCTest unit tests for bag/pricing logic and one XCUITest that walks the golden path; CI on `macos-latest`.

### Non-goals
- Real authentication, payments, inventory or order APIs (all mocked in-app).
- Android, iPad, watchOS, widgets, push notifications.
- Full catalog parity with gap.com; ~95 styles bundled is sufficient.
- Localization beyond en-US.

## 3. Users and persona

**Gwenyth, 34, Montréal** — Encore *Premier* member, 2,124 points. Shops Gap 4–6× a year, mostly denim and layers. Prefers to pick up in store on her way home. Uses Face ID, dark mode off, iPhone 15 Pro.

Secondary: **Guest shopper** (not signed in) — can browse and add to bag; is prompted to sign in / continue as guest at checkout. Only the sign-in nudge is in scope; the guest checkout branch is out of scope for v1.

## 4. Golden path — "Order a fall outfit"

| # | Step | Screen | Outcome |
|---|------|--------|---------|
| 1 | Launch app for the first time | Splash → Onboarding | Full-bleed editorial image, GAP wordmark, "Shop now" |
| 2 | Land on Home | Home | "Good evening, Gwenyth", search bar, **Fall Layers** hero, "Build your fall outfit" module, floating tab bar |
| 3 | Tap **Fall Layers → Shop the edit** | Product Listing (Fall Edit) | 2-column grid, filter/sort chips, 12+ products |
| 4 | Tap **CashSoft Crop Cardigan** | Product Detail | Image pager, ♥, $69.95, ★4.5 (208), colour swatches, size chips, "Matching Set" pill |
| 5 | Pick colour *Modern Red*, size *M*, tap **Add to Bag** | Item Added sheet | Confirms line item, "Complete the look" carousel shows jeans + jacket |
| 6 | Tap **Low Rise '90s Loose Jeans** in "Complete the look" | Product Detail | $79.95, *Light Blue Indigo*, ★4.3 (52) |
| 7 | Pick size *28*, **Add to Bag** | Item Added sheet | Bag badge = 2 |
| 8 | Tap search, type "denim jacket", pick **Icon Denim Jacket** | Search → Product Detail | $89.95, *Medium Indigo*, ★4.8 (708) |
| 9 | Pick size *M*, **Add to Bag** → **View Bag** | Bag | 3 line items, subtotal **$239.85** |
| 10 | Enter promo **FALL25** | Bag | −$59.96 promo line, "FALL25 applied" success state |
| 11 | Tap **Checkout** | Checkout | Delivery method segmented: *Ship* / *Pick up in store* (selected) |
| 12 | Tap **Choose store** | Store Locator | Map + list, brand filter chips; select **Gap Sainte-Catherine (0.8 km)** |
| 13 | Review payment (saved Visa ••4242), tap **Place order** | Checkout | Loading → Confirmation |
| 14 | Order confirmed | Order Confirmation | Order **#GAP-2026-0928**, pickup ready-by time, **+194 Encore points**, "Continue shopping" |
| 15 | Tap **Account** tab | Account / Encore | Points now **2,318**, Purchase History shows "Ready for pickup · 3 items" |

**Pricing worked example** (promo before tax, 8% demo tax rate, pickup is free):

```
Cardigan            69.95
'90s Loose Jeans    79.95
Icon Denim Jacket   89.95
Subtotal           239.85
FALL25 (25%)       -59.96
Pickup               0.00
Tax (8%)            14.39
Total              194.28   → earns 194 Encore points (1 pt / $1)
```

## 5. Screen inventory

| ID | Screen | Reference | In golden path |
|----|--------|-----------|----------------|
| S01 | Splash / Onboarding | App Store shot 1 | ✔ |
| S02 | Home | App Store shot 2 | ✔ |
| S03 | Brand switcher (tab-bar logo tap) | App Store shot 3 | — |
| S04 | Shop (departments + categories) | Official app | — |
| S05 | Product Listing (PLP) | Official app | ✔ |
| S06 | Product Detail (PDP) | App Store shot 4 | ✔ |
| S07 | Item Added sheet | Official app | ✔ |
| S08 | Bag | Official app | ✔ |
| S09 | Checkout | Official app | ✔ |
| S10 | Store Locator | App Store shot 6 | ✔ |
| S11 | Order Confirmation | Official app | ✔ |
| S12 | Account / Encore | App Store shot 5 | ✔ |
| S13 | Offers | Official app | — |
| S14 | Search results / Wishlist | Official app | ✔ (search) |

## 6. User stories

Format: *As a … I want … so that …* with acceptance criteria (AC). Priority: **P0** = required for golden path, **P1** = required for demo realism, **P2** = nice to have.

### Epic A — Discover

**A1 · Onboarding (P0)**
As a first-time user I want a branded welcome so that I recognise Gap immediately.
- AC1 Full-bleed editorial photo with gradient scrim; GAP wordmark (official asset) centred in the lower third.
- AC2 Primary CTA "Shop now"; secondary "Sign in".
- AC3 Shown once; `-resetOnboarding` launch arg shows it again; `-skipOnboarding` suppresses it.

**A2 · Home greeting (P0)**
As Gwenyth I want to be greeted by name so that the app feels personal.
- AC1 Header shows "Good evening, Gwenyth" (time-of-day aware: morning/afternoon/evening) and "Encore Premier" sub-label.
- AC2 Guest state shows "Welcome" / "Sign in".

**A3 · Home search bar (P0)**
As a shopper I want a persistent search bar with a barcode icon so I can jump straight to a product.
- AC1 Search field placeholder "Search Gap"; barcode glyph at trailing edge (visual only).
- AC2 Tapping opens Search (S14) with keyboard focused.

**A4 · Seasonal hero (P0)**
As a shopper I want a Fall Layers hero so I can enter the seasonal edit in one tap.
- AC1 Hero image (denim jacket editorial) with headline "Fall Layers" and CTA "Shop the edit".
- AC2 "Build your fall outfit" module lists the three golden-path products as horizontally scrolling cards with "Add" buttons.

**A5 · Brand switcher (P1)**
As a shopper I want to tap the GAP logo in the tab bar to see Athleta, Old Navy, Banana Republic and Gap so I can switch brands like the real app.
- AC1 Bottom sheet lists four brands with round logo badges (Gap uses official wordmark; other brands use text badges).
- AC2 Selecting a brand re-themes the header accent and filters the catalog; Gap is default.

**A6 · Floating tab bar (P0)**
As a shopper I want the floating pill tab bar so the app feels like the real Gap app.
- AC1 Pill with shadow, 16 pt inset from edges, items: **GAP logo**, Shop, Offers, Bag, Account.
- AC2 Bag item shows a count badge; badge animates on add.

### Epic B — Browse

**B1 · Shop departments (P1)**
As a shopper I want Women / Men / Girls / Boys / Baby & Toddler tabs and category lists so I can browse the way the real app does.
- AC1 Segmented department chips; category list with counts.

**B2 · Product listing (P0)**
As a shopper I want a 2-column grid with price, sale price, rating and colour count so I can compare quickly.
- AC1 Card: 3:4 image, name (2 lines max), price (red if on sale with strikethrough original), ★ rating + count, "+N colours".
- AC2 Sort (Featured, Price ↓, Price ↑, Rating) and Filter (size, colour, price) chips.
- AC3 Heart on card toggles wishlist.

**B3 · Search (P0)**
As a shopper I want type-ahead search so I can find the Icon Denim Jacket.
- AC1 Results update per keystroke against name, category and colour name.
- AC2 Recent searches and "Trending: denim jacket, cardigan, loose jeans" shown on empty query.

### Epic C — Decide

**C1 · Product detail (P0)**
As a shopper I want an image pager, price, rating, colour and size pickers so I can choose the right variant.
- AC1 Paged images with dot indicator; ♥ top-right; share icon in nav bar; title in nav bar.
- AC2 "Matching Set" pill overlays the pager when the product has a companion.
- AC3 Colour swatches (selected has ring); size chips (out-of-stock struck through); "Size guide" link.
- AC4 Sticky "Add to Bag" CTA (navy) above the tab bar; disabled until a size is chosen.
- AC5 Details, fabric & care, reviews sections collapsible.

**C2 · Item added sheet (P0)**
As a shopper I want confirmation when I add an item so I can keep shopping or go to my bag.
- AC1 Sheet shows thumbnail, name, colour/size, price; CTAs "View Bag" and "Continue shopping".
- AC2 "Complete the look" carousel shows the other golden-path items.

**C3 · Wishlist (P2)**
As a shopper I want to save favourites so I can come back later.
- AC1 Heart toggles persist across launches; Wishlist grid reachable from Account.

### Epic D — Bag

**D1 · Bag review (P0)**
As a shopper I want to see line items with thumbnails, variant, quantity stepper and remove so I can adjust my order.
- AC1 Line item: 80 × 106 thumbnail, name, colour · size, price, − / qty / + stepper, "Remove".
- AC2 Empty state with illustration and "Start shopping".

**D2 · Promo code (P0)**
As a shopper I want to apply FALL25 so I get 25 % off.
- AC1 Promo field with "Apply"; valid code shows green success row and discount line; invalid shows inline red error.
- AC2 Codes: `FALL25` (25 %), `YOURS` (30 %), `ENCORE20` (20 %, members only), `SHIPFREE` (free shipping).

**D3 · Order summary (P0)**
As a shopper I want an itemised summary so I know what I'll pay.
- AC1 Subtotal, promo, delivery, estimated tax (8 %), total; "Checkout" CTA with total in label.

### Epic E — Checkout

**E1 · Delivery method (P0)**
As Gwenyth I want to choose "Pick up in store" so I can collect on my way home.
- AC1 Segmented control Ship / Pick up in store; pickup shows store card or "Choose store" CTA.

**E2 · Store locator (P0)**
As a shopper I want a map and list of nearby stores filtered by brand so I can choose the closest Gap.
- AC1 Map with pins (MapKit), "My Location" row, brand filter chips (Gap, Old Navy, Banana Republic, Athleta), list rows with distance, address, hours, radio selection.
- AC2 Selecting a store returns to Checkout with the store card filled.

**E3 · Payment & place order (P0)**
As Gwenyth I want my saved card pre-selected so I can place the order in one tap.
- AC1 Payment card row (Visa ••4242), contact row (email/phone), "Place order · $194.28" CTA.
- AC2 Loading state ≥ 600 ms, then Confirmation; bag cleared.

**E4 · Order confirmation (P0)**
As a shopper I want an order number, pickup instructions and my points earned so I trust the purchase went through.
- AC1 Checkmark animation, "Thanks, Gwenyth", order # `GAP-2026-0928`, store name + "Ready today by 6 pm", line items, "+194 Encore points", CTAs "View order" / "Continue shopping".

### Epic F — Account & rewards

**F1 · Encore header (P0)**
As Gwenyth I want to see my tier and points so I know my status.
- AC1 Denim editorial header with "Good evening, Gwenyth", *encore* wordmark, "Premier Member", points (updated after order).

**F2 · Purchase history (P0)**
As Gwenyth I want to see my latest order so I can check pickup status.
- AC1 Horizontal cards: thumbnail, "Ready for pickup · 3 items", date, "Details".
- AC2 Order Details shows full receipt.

**F3 · Encore offers & market (P1)**
As a member I want to see offers and Encore Market items so I can redeem rewards.
- AC1 "Encore Offers" horizontal cards with "View code"; "Encore Market" grid of 2 reward tiles.

**F4 · Offers tab (P1)**
As a shopper I want an Offers tab so I can find codes like FALL25.
- AC1 Offer cards (eyebrow, title, body, code chip with "Copy", expiry); tapping "Apply in bag" pre-fills the promo field.

## 7. Functional requirements (cross-cutting)

- FR1 Catalog, categories, offers and stores are bundled JSON; loaded into an `@Observable` `Catalog`.
- FR2 Bag, wishlist, onboarding flag and last order persist in `UserDefaults` (JSON-encoded); `-resetState` clears them.
- FR3 Images via Kingfisher with fade-in and a brand-canvas placeholder; broken URLs fall back to a neutral placeholder — the UI must never show a blank white square.
- FR4 All navigation uses `NavigationStack` with a type-safe `Route` enum; tab bar is custom (not `TabView` default chrome).
- FR5 Every screen-level view exposes `static let figmaNode: FigmaNode` (file key + node id + name) used by the QA overlay and `docs/figma-nodes.md`.
- FR6 `-uiTesting` launch arg disables animations and seeds Gwenyth's account.

## 8. Non-functional requirements

- iOS 17+, iPhone only, portrait; Swift 5.9, SwiftUI, Observation framework.
- Cold start to Home < 1.5 s on Simulator; scroll at 60 fps with 100 product cards.
- Dynamic Type up to XL without truncating prices or CTAs; VoiceOver labels for every tappable.
- Contrast ≥ 4.5:1 for body text; CTAs ≥ 3:1.
- Light mode required; dark mode acceptable but not designed in v1.

## 9. Brand & design constraints

- Official Gap wordmark (`design/brand/GapWordmark.pdf`) is the only logo rendering; never re-typeset it.
- Palette: Navy `#002868`, Ink `#141414`, Canvas `#F6F6F4`, Hairline `#E4E4E1`, Sale `#B3261E`, Success `#1E7A43`, Encore Gold `#C8A45C`, Encore Dark `#0E1B3A`.
- Type: system SF Pro (Inter in Figma as the closest open equivalent); headline weights Semi Bold; body Regular; editorial hero headline uses a high-contrast serif (Playfair Display in Figma / New York in iOS).
- Radii: 0 on imagery and CTAs (Gap uses square corners), 999 on pill tab bar and chips, 12 on sheets.
- Spacing scale: 4, 8, 12, 16, 24, 32.

## 10. Data

Bundled from the existing demo catalog (95 styles / 473 colourways), 8 Montréal-area stores, 6 offers. Golden-path SKUs:

| Product | ID | Colour | Price | Rating |
|---|---|---|---|---|
| CashSoft Crop Cardigan | gap-800546 | Modern Red | $69.95 | 4.5 (208) |
| Low Rise '90s Loose Jeans | gap-815642 | Light Blue Indigo | $79.95 | 4.3 (52) |
| Icon Denim Jacket | gap-797118 | Medium Indigo | $89.95 | 4.8 (708) |

## 11. Analytics events (mocked, logged to console)

`app_open`, `onboarding_complete`, `hero_tap`, `plp_view`, `pdp_view`, `add_to_bag`, `promo_applied`, `checkout_start`, `store_selected`, `order_placed`, `account_view`.

## 12. Success metrics for the demo

- Golden path completes in ≤ 15 taps on a fresh install.
- 100 % of P0 stories have a Figma node and a Swift view (traceability table complete).
- Side-by-side Figma vs Simulator screenshots for the 12 golden-path screens with no visible layout deltas > 4 pt.
- CI green on `macos-latest`: unit tests + XCUITest golden path.

## 13. Open questions

1. Should the guest checkout branch be designed (greyed) in Figma even though it is out of scope for code? *(Default: yes, as a single annotated frame.)*
2. Tax rate — 8 % flat is a placeholder; confirm if a Québec-realistic 14.975 % is preferred for the demo narrative.
3. Should Old Navy / Banana Republic / Athleta logos be reproduced, or shown as text badges to avoid third-party asset licensing? *(Default: text badges.)*

## 14. Traceability

See `docs/figma-nodes.md` (generated during Phase 3) for Story → Figma node → Swift view mapping.
