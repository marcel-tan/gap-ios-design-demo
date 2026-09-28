# Figma ↔ SwiftUI node registry

File: [Gap iOS — Design Demo](https://www.figma.com/design/2amCWqHqUoNvHtOQUxtd7I) (key `2amCWqHqUoNvHtOQUxtd7I`).
Every screen-level SwiftUI view conforms to `FigmaTraced` and exposes `static let figmaNode` (see
`Gap/Design/FigmaNode.swift`). Launch the app with `-figmaOverlay` to show a tappable node badge on each
screen; XCUITests can read the node id from the view's accessibility value (`figma:<id>`).

Link format: `https://www.figma.com/design/2amCWqHqUoNvHtOQUxtd7I?node-id=<id with ':' → '-'>`.

## Pages

| Page | Node | Contents |
|---|---|---|
| 01 Wireframes & Flow | `0:1` | 14 low-fi screens + golden-path legend (docs/wireframes.md) |
| 02 Foundations & Components | `1:4` | Colour/space variables, text styles, component library |
| 03 Screens & Prototype | `1:5` | Hi-fi screens, uploaded imagery, prototype flow |

## Screens

| # | Screen | SwiftUI view | Hi-fi node (page 03) | Wireframe node (page 01) |
|---|---|---|---|---|
| S01 | Onboarding | `OnboardingView` | `17:699` | `5:2` |
| S02 | Home | `HomeView` | `17:730` | `5:46` |
| S03 | Brand switcher | `BrandSwitcherView` | `17:822` | `5:104` |
| S04 | Shop | `ShopView` | `17:1011` | `5:126` |
| S05 | Product listing | `ProductListView` | `17:1136` | `5:160` |
| S06 | Product detail | `ProductDetailView` | _pending_ | `5:193` |
| S07 | Item added | `AddedToBagSheet` | _pending_ | `5:246` |
| S08 | Bag | `BagView` | _pending_ | `5:311` |
| S09 | Checkout | `CheckoutView` | _pending_ | `5:373` |
| S10 | Store locator | `StoreLocatorView` | _pending_ | `5:409` |
| S11 | Order confirmation | `OrderConfirmationView` | _pending_ | `5:444` |
| S12 | Account / Encore | `AccountView` | _pending_ | `5:472` |
| S13 | Offers | `OffersView` | _pending_ | `5:513` |
| S14 | Search | `SearchView` | _pending_ | `5:272` |

`FigmaScreens` in code points at the hi-fi node where one exists and at the wireframe node otherwise;
flip the id when the remaining hi-fi screens land (scripts are prepared in the design workflow and
blocked only by the Figma Starter plan's MCP call limit).

## Components (page 02)

| Component | Node | SwiftUI |
|---|---|---|
| Logo / Gap wordmark | `15:3` | `Wordmark`, `BrandLogo` (renders `GapWordmark.pdf`, never re-typeset) |
| Button (primary / outline / disabled) | `15:13` | `PrimaryButton`, `OutlineButton` |
| Chip | `15:19` | `Chip` |
| Size chip | `15:27` | `Chip` (`minWidth: Theme.Sizes.sizeChipMinWidth`) |
| Colour swatch | `15:35` | `ColorSwatch` in `ProductDetailView` |
| Tab bar (floating pill) | `15:141` | `FloatingTabBar` |
| Nav header | `15:143` | `StoreHeader` / system nav bar |
| Search bar | `15:150` | `HomeView.searchBar`, `SearchView` |
| Product card | `15:205` | `ProductTile`, `ProductRailCard` |
| Bag line item | `15:207` | `BagLineRow` |
| Store row | `15:241` | `StoreRow` in `StoreLocatorView`, `CheckoutView.pickupSection` |
| Offer card | `15:243` | `OfferCard` in `OffersView` |
| Encore card | `15:259` | `AccountView` encore card, `OrderConfirmationView` points banner |
| Promo field | `15:267` | `BagView.promoField` |
| Summary row | `15:279` | `OrderSummaryView` |
| Brand badge | `15:299` | `BrandLogo` |
| Sheet | `15:301` | `.presentationDetents` sheets (Brand switcher, Item added, Filters) |
| Status bar / Home indicator | `15:305` / `15:320` | system |

## Foundations → `Theme.swift`

| Figma variable / style | Value | Swift |
|---|---|---|
| color/navy | `#002868` | `Theme.Colors.navy` |
| color/ink | `#141414` | `Theme.Colors.ink` |
| color/canvas | `#F6F6F4` | `Theme.Colors.canvas` |
| color/hairline | `#E4E4E1` | `Theme.Colors.hairline` |
| color/text-secondary | `#6B6B6B` | `Theme.Colors.textSecondary` |
| color/sale | `#B3261E` | `Theme.Colors.sale` |
| color/success | `#1E7A43` | `Theme.Colors.success` |
| color/encore-gold | `#C8A45C` | `Theme.Colors.encoreGold` |
| color/encore-dark | `#0E1B3A` | `Theme.Colors.encoreDark` |
| space/4 … space/32 | 4, 8, 12, 16, 24, 32 | `Theme.Spacing.*` |
| radius/none · radius/sheet · radius/pill | 0 · 12 · 999 | `Theme.Radius.card/button`, `.sheet`, `.chip` |
| Display/Hero (Playfair Display 34) | serif | `Theme.Typography.heroTitle` (New York) |
| Title/Screen (Inter Semi Bold 22) | | `Theme.Typography.screenTitle` |
| Title/Section (Inter Semi Bold 18) | | `Theme.Typography.sectionTitle` |
| Body (Inter 15) / Body Strong | | `Theme.Typography.body` / `.bodyStrong` |
| Label/Tracked (Inter Medium 11, +8 %) | | `.trackedLabel()` |
| Caption (Inter 12) | | `Theme.Typography.caption` |

## Imagery (page 03, section `12:2`)

| Node | Product |
|---|---|
| `8:2`, `8:5` | Low Rise '90s Loose Jeans |
| `8:3`, `8:7` | CashSoft Crop Cardigan |
| `8:4`, `8:6` | Icon Denim Jacket |
| `13:2` | Official Gap wordmark (from `design/brand/GapWordmark.pdf`) |
