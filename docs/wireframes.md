# Wireframe specification

Low-fidelity wireframes live in Figma → **01 Wireframes & Flow**
(https://www.figma.com/design/2amCWqHqUoNvHtOQUxtd7I?node-id=0-1).
Each frame is 393 × 852 (iPhone 15 Pro logical points). Numbered navy badges are the
golden-path order from PRD §4. This document is the written contract for those frames;
the hi-fi screens on **03 Screens & Prototype** must keep the same information hierarchy.

## Global chrome

| Element | Spec |
|---|---|
| Status bar | System, 47 pt safe area top |
| Nav bar | 44 pt; back chevron leading, centred title (Headline), trailing action |
| Floating tab bar | Pill 361 × 64, 16 pt inset, bottom 32 pt from edge; drop shadow y4 / blur 12 / 15 %. Items: **GAP logo (44 pt navy circle with wordmark)**, Shop, Offers, Bag (badge), Account. Icon 20 pt, label 11 pt |
| Primary CTA | Full width − 32, 52 pt, navy fill, white Label/CTA, square corners |
| Chips | Pill, 30–36 pt tall, 1 pt ink stroke; selected = ink fill / white text |
| Sheets | Top radius 12, grab handle, dimmed scrim 55 % |
| Content inset | 16 pt horizontal |

## Screens

| ID | Figma node | Regions (top → bottom) | Primary action | Exits |
|---|---|---|---|---|
| S01 Onboarding | `5:4` | Full-bleed photo · gradient scrim · GAP wordmark (200 × 90 at y 560) · "Shop now" CTA (y 700) · "Sign in" text button | Shop now → S02 | Sign in (mock) |
| S02 Home | `5:18` | Greeting + Encore tier · search field + barcode · Fall Layers hero 393 × 300 with headline + "Shop the edit" pill · "Build your fall outfit" 3-card rail with "+ Add" · New arrivals rail · tab bar | Shop the edit → S05 | Search → S14, Add → S07, tab bar |
| S03 Brand switcher | `5:63` | Dimmed home · sheet 420 pt · "Our brands" · 4 rows (56 pt badge + name), Gap checked | Select brand → re-theme, dismiss | Tap scrim |
| S04 Shop | `5:91` | Department chips (Women selected) · category list rows 56 pt with chevrons | Row → S05 | Tab bar |
| S05 PLP | `5:143` | Nav "Fall Edit" · Filter / Sort chips + count · 2-col grid, card 176 × 235 image + name + price + rating + colours + ♡ | Card → S06 | Filter/Sort sheets (v1: static) |
| S06 PDP | `5:193` | Nav with title + share · image pager 440 pt with ♥ and "Matching Set" pill · dots · price + rating · colour label + swatches (28 pt) · size label + guide + 6 chips · sticky "Add to Bag · $" CTA above tab bar · (scroll: details, fabric, reviews) | Add to Bag → S07 | Back, ♥ |
| S07 Item added | `5:246` | Sheet 470 pt · "✓ Added to bag" · thumb 72 × 96 + name/variant/price · "View Bag (n)" CTA · "Continue shopping" · "Complete the look" 3-tile rail | View Bag → S08 | Continue → dismiss; tile → S06 |
| S14 Search | `5:272` | Search field focused · "Results for … (n)" · 2-col grid · keyboard | Card → S06 | Cancel |
| S08 Bag | `5:311` | Nav "Bag (3)" · line items 106 pt (thumb 80 × 106, name, variant, qty stepper, Remove, price) · promo field + Apply · success row · summary (Subtotal / Promo / Pickup / Est. tax / Total) · "Checkout · $" CTA | Checkout → S09 | Stepper, Remove, tab bar |
| S09 Checkout | `5:373` | Delivery segmented (Ship / Pick up in store) · store card or "Choose store" · Contact · Payment card · Order summary · legal · "Place order · $" CTA | Place order → S11 | Change store → S10 |
| S10 Store locator | `5:409` | Nav "STORE LOCATOR" · My Location row + locate · map 300 pt · 4 brand badges (56 pt) · store rows 72 pt (radio, distance, name, address/hours) · "Pick up here" CTA | Pick up here → S09 | Back |
| S11 Confirmation | `5:444` | Check badge 72 pt · "Thanks, Gwenyth!" · order # · pickup card · Encore points card · items list · "View order" CTA · "Continue shopping" | Continue → S02 | View order → order detail (S12 sub-screen) |
| S12 Account | `5:472` | Denim header 280 pt with greeting, *encore*, tier, points · Purchase History rail (card 329 × 100) · Encore Offers rail · Encore Market 2-tile grid · tab bar | Details → order detail | View more / View all (static) |
| S13 Offers | `5:513` | Nav "Offers" · offer cards 184 pt (eyebrow, title, code chip, Copy, expiry, "Apply in bag") | Apply in bag → S08 with promo prefilled | Copy |

## Interaction notes

- Adding to bag animates the Bag badge (scale 1 → 1.3 → 1, 250 ms) and presents S07 as a medium detent sheet.
- Promo validation is inline; invalid code shakes the field and shows Sale-red helper text.
- Store selection is a radio list; the CTA label updates to "Pick up here" once a row is selected.
- Place order shows a 600 ms progress state on the CTA before pushing S11 and clearing the bag.
- S11 → Account tab shows updated points via a count-up animation.

## Out of scope for wireframes

Guest checkout branch, filter/sort sheets contents, review list, size guide, order detail full receipt (covered in hi-fi only as a single frame).
