# AQARATI Implementation Audit

Evidence-based. Every claim below checked against actual files in this repo, not memory of what was intended.

## 1. Architecture

```
lib/
  core/
    router/        go_router config + shell (bottom nav)
    theme/         colors, spacing/radius tokens, typography, ThemeData
    widgets/       7 shared components only (see Part 12)
  data/
    datasources/   3 mock data files (property, business, conversation)
    models/        ~18 plain Dart model classes + enums
    repositories/   Property/Business repos (return mock data via Future), Riverpod providers
  features/
    <18 feature folders>, one file per screen, no sub-structure
```

`core/widgets` is thin — 7 files, 583 lines total, for an app with ~45 screens. That ratio is the root cause of Part 8/32 findings: most screens hand-roll their own `Card`, `Container` decoration, `ListTile` instead of calling a shared AQARATI component, because too few shared components exist to call.

## 2. Stack (verified in pubspec.yaml)

- Flutter SDK `^3.13.3` (Dart), Flutter web (Chrome) is the only target actually run
- State: `flutter_riverpod ^2.6.1`, plain `StateProvider` — no code generation, no async notifiers
- Routing: `go_router ^14.6.2`, but only 8 of ~45 screens are registered routes (see Part 13). Everything else is `Navigator.push(MaterialPageRoute)` — invisible to go_router, no deep link, no web URL for it.
- DI: none — providers imported directly, no service locator
- Networking: none — no `http`/`dio`, no API layer at all
- Data: 100% in-memory mock (`mock_property_data.dart` etc.), session-scoped `StateProvider`s, lost on refresh
- Typography: `google_fonts` fetches Cormorant Garamond + Inter at runtime (network dependency, not bundled — will flash unstyled text or fail offline)
- Theming: single `ThemeData` in `app_theme.dart`, light only, no dark theme, no `ThemeMode` switch actually wired (Appearance screen is UI-only, doesn't touch `Theme.of`)
- Localization: `intl` + `flutter_localizations` in pubspec, **zero `.arb` files exist**. No Arabic strings, no RTL test ever run. The "Arabic-ready font pairing" comment in `app_typography.dart` describes fonts that are never loaded.
- Animation: `AnimatedContainer`/`AnimatedSwitcher` in ~3 places, no shared motion system despite `AppMotion` token class existing
- Persistence: none — `StateProvider` only, everything guest-scoped
- Error handling: `AqaratiErrorState` widget exists, wired to almost nothing (repos never actually throw)
- Testing: **0 test files** under `test/` beyond the default Flutter counter test template

## 3. Screen implementation table (sample — full list mirrors folder list above)

| Screen | Route | Implemented | Real custom UI | Interactive | Data | Figma match |
|---|---|---|---|---|---|---|
| Home | `/home` (go_router) | Yes | Partial | Yes | mock repo | Loose — category tiles/hero copy invented, not from reference |
| Search Results | `/search` (go_router) | Yes | Partial | Yes | mock repo | Filter sheet is generic bottom sheet, not the Figma filter screen |
| Property Detail | `/property/:id` (go_router) | Yes | Partial | Yes | mock repo | Gallery/video/floor-plan sections simplified vs reference |
| Saved / Compare | push only | Yes | Generic | Yes | Riverpod state | Compare screen is a plain horizontal `Row` of cards, no Figma reference followed closely |
| Owner Dashboard / Property Creation | push only | Yes | Generic | Yes | Riverpod state | 8-step wizard exists but each step is a bare `Column` of `TextField`s |
| Verification Center | push only | Yes | Generic | Partial | local state | Identity flow OK; Business Verification is `onTap: () {}` stub in places |
| Settings / Security / Privacy / Help / Documents / Reviews (this session's additions) | push only, **not in go_router** | Yes | Closer to reference (built directly from pasted PNGs) | Yes | local state | Best match in the app — built screen-by-screen from screenshots, still Material-default at the component level (`Card`, `ListTile`, `Switch`) |
| Map | push only | Placeholder | No | Fake pins on flat canvas | none | Not a map — gray `Container` with painted dots |
| Messages/Conversation | push only | Yes | Generic chat bubbles | Yes | mock | Standard `Container` bubbles, no reference followed |

**Pattern across the whole app**: every screen "exists" (route reachable, no crash), but the further back in the session it was built, the more it is an original Material-flavored layout inspired by the spec text rather than a pixel reproduction of a supplied PNG. The most recent batch (Settings/Security/Privacy/Help/Documents/Reviews) is the only set built directly against pasted screenshots, and even those use raw `Card`/`ListTile`/`Switch`/`TextField` with AQARATI colors slapped on, not true AQARATI-specific components.

## 4. Visual audit — concrete evidence

`lib/core/widgets/property_card.dart` (the single most-reused component, used on Home/Search/Saved/Compare/Map):
```dart
return Card(                              // <- default Material Card, default elevation/shape
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    ...
    Container(
      color: AppColors.sand,
      child: Icon(Icons.landscape_outlined, size: 40, color: AppColors.mist),  // <- NO property photo, ever
    ),
    ...
    Icon(Icons.bed_outlined, size: 14, ...)     // stock Material icon
    Icon(Icons.bathtub_outlined, size: 14, ...) // stock Material icon
    Icon(Icons.square_foot_outlined, size: 14, ...)
```
This is the generic-UI failure mode called out in Part 8, verified directly: every property card in the entire app renders a flat sand box with a landscape icon, never an image. Confirmed asset audit: `assets/` contains exactly one file, `assets/logo/aqarati_logo_mark.svg`. **Zero property, business, or location photos exist in the project.** (The 152-prompt image brief was delivered to the user in an earlier turn precisely because of this gap — it was never closed.)

Icons app-wide: grep of `lib/features` and `lib/core` shows exclusively `Icons.*_outlined` / `Icons.*_rounded` — the stock Material Symbols font. No custom icon set, no SVG icon family. Part 19/43 requirement ("minimal, geometric, premium iconography") is **not met**; this is Material Icons throughout, dressed in brand colors.

Buttons: `AqaratiButton` (61 lines) is a real shared component and is used consistently — this is the one component that genuinely matches "component-first" intent. Confirmed used in ~20+ screens.

Cards/Settings rows/dialogs elsewhere: raw `Card()`, `ListTile()`, `AlertDialog()`, `showModalBottomSheet` with default Material chrome, re-colored per screen rather than through a shared `AqaratiCard`/`AqaratiSheet`/`AqaratiDialog`. Confirmed in `security_screen.dart`, `privacy_screen.dart`, `about_screen.dart`, `documents_screen.dart`, `review_screen.dart` — all new this session, all hand-rolled per-screen instead of calling one shared card/sheet component (because no such shared component exists yet — see Part 12 below).

## 5. Why it diverged

1. **No component-first discipline was enforced.** `core/widgets` has 7 files. A 45-screen app referencing ~150 Figma frames needs a real `AqaratiCard`, `AqaratiSheet`, `AqaratiListRow`, `AqaratiDialog` — none exist, so every new screen (including this session's Settings/Privacy/Security/Documents batch) reinvents card/row chrome inline.
2. **Screens were built from spec text + low-res filmstrip thumbnails for most of the app**, and only the most recent batch (Settings cluster) was built against individually-legible pasted PNGs. Earlier screens (Home, Search, Property Detail, Map, Messages, Compare, Owner wizard) were written from the 80-section written spec and the *idea* of the screen, not measured against a specific reference image, because at that point in the session the images were low-res filmstrips, not individually inspectable.
3. **Zero real imagery** — every property/business card falls back to an icon-on-sand-box because no asset pipeline was ever closed. This alone makes every list/grid screen look like a generic template regardless of layout correctness.
4. **Stock Material icons used everywhere**, never replaced with a drawn/sourced icon set — cheapest path, visually reads as "Flutter default," explicitly flagged as unacceptable in Part 19/43.
5. **`go_router` only covers 8 routes**; everything else is ad hoc `Navigator.push`. This was a scaling shortcut (easier to add one more push than wire a full go_router path + shell decision), but it means half the app has no deep link and diverges structurally from a real navigation tree.
6. **No dark theme / no RTL** despite tokens implying both were planned (`AppMotion`, Arabic font comment) — those were designed for on paper, never executed, because Arabic/RTL was explicitly deferred pending `.arb` setup that never happened.

## 6. Oman / currency / verification-terminology audit

Grep of `lib/` for `AED|UAE|Dubai|Abu Dhabi|Dirham|Dhs|₹|INR|SAR|Emirates ID|KYC|DigiLocker`: **zero matches** (only false positives on a comment "0-950" and a doc ID string "AQ-LEASE"). Currency is enforced through a single `Money` value object (`lib/data/models/money.dart`) that always formats as `OMR ...` — there is no path in the code to print any other currency. **This part of the spec is actually clean.**

"KYC" is never used as user-facing copy — screens correctly say "Identity Verification," "Business Verification," "Property Verification" as three separate tracks (`verification_center_screen.dart` keeps three independent status tiles). This separation is real, not just a route existing — confirmed by `identity_verification.dart` and `property_verification.dart` being distinct model files with independent status enums.

## 7. THEQA audit

`identity_verification_flow.dart` implements: intro screen ("Continue with THEQA") -> method choice (QR / push) -> waiting state -> success -> failed. **Missing from the 48-part spec's THEQA list**: explicit Pending/Cancelled/Expired/Unavailable states as separate screens (currently collapsed into one generic "failed" state), and no explicit "Return to AQARATI" transition screen. THEQA is correctly never conflated with property or business verification (confirmed separate enums/screens). No fake government API call exists — it's a 2-second `Timer` — correctly not overclaimed as live.

## 8. Component audit (every shared widget that exists)

| Component | File | Screens using it | Matches Figma | Verdict |
|---|---|---|---|---|
| `AqaratiButton` | `core/widgets/aqarati_button.dart` | ~20+ | Reasonably | KEEP |
| `PropertyCard` | `core/widgets/property_card.dart` | Home, Search, Saved, Compare | No — default `Card`, icon-only image, stock icons | REBUILD |
| `BusinessCard` | `core/widgets/business_card.dart` | Explore/Professional discovery | Not verified against reference | REFACTOR |
| `VerificationBadge` | `core/widgets/verification_badge.dart` | PropertyCard, Compare, Business | Functionally correct (3-state), visual polish unverified | REFACTOR |
| `AqaratiSearchField` | `core/widgets/aqarati_search_field.dart` | Home, Search | Basic `TextField` wrapper | REFACTOR |
| `SectionHeader` | `core/widgets/section_header.dart` | Home | Simple, fine | KEEP |
| States (`AqaratiEmptyState`/`ErrorState`/`LoadingLine`) | `core/widgets/states.dart` | Most list screens | Functional, generic-looking | REFACTOR |
| `AqaratiCard` / `AqaratiSheet` / `AqaratiDialog` / `StatusPill` (shared) | **do not exist** | N/A | N/A | BUILD NEW |

## 9. Routing audit

Actual tree (go_router):
```
/onboarding
/saved
/search
/property/:id
/professionals
/business/:id
(shell) /home /explore /messages /profile
```
Everything else — Settings (+7 sub-screens), Security, Privacy, Help & Support, Documents (+4 sub-screens), Reviews, Verification Center (+2 flows), Calculators (+8), My Home, Owner Dashboard (+wizard), My Enquiries, Map, Compare, Messages thread, Notifications, Account Switch — is `Navigator.push`, reachable only from an in-app tap, not a URL. Auth gate (`auth_gate_sheet.dart`) is real and reused for save/enquire/offer/book — that pattern is correctly centralized and correctly returns to the attempted action, not Home (confirmed by callsite pattern `onContinue: () => <original action>`).

## 10. Status percentages (methodology stated, not vibes)

- **Visual implementation: ~30%.** Basis: 1/7 core components (`AqaratiButton`) actually matches a reasonable brand bar; the highest-traffic component (`PropertyCard`) provably renders no imagery and stock icons; only the newest ~15 screens were built against individually legible references.
- **Functional implementation: ~65%.** Basis: almost every screen is tappable, state flows through Riverpod correctly (save/enquire/offer/book all persist across screens in-session), no crashes on the paths tested this session.
- **Navigation: ~40%.** Basis: 8/45+ screens are real go_router routes; rest is push-only, no deep link, confirmed by reading `app_router.dart` directly.
- **Design-system fidelity: ~35%.** Basis: colors/spacing/type-scale tokens exist and are centralized and are used almost everywhere (good), but component layer (cards, sheets, dialogs, icons) bypasses tokens' intent by falling back to raw Material widgets.
- **Content quality: ~70%.** Basis: property/business names and copy are Oman-specific and non-generic (`Al Mouj`, `Al Khoudh`, OMR pricing); no "Find your dream home!" copy found in grep.
- **Oman localization: ~55%.** Basis: currency/geography fully clean (verified via grep), but zero Arabic/RTL execution despite being a stated requirement.
- **Architecture: ~50%.** Basis: clean model/repository/provider separation (good), but component layer thin and routing split in two systems (bad).
- **Accessibility: ~20%.** Basis: no semantic label audit ever performed, no touch-target audit, no RTL test, no text-scaling test — genuinely unknown/unverified, scored low because unverified ≠ assumed fine.
- **Production readiness: ~10%.** Basis: zero tests, zero real assets, zero backend, google_fonts network dependency unbundled, no offline behavior — this is a demo-quality prototype, correctly scoped as such per the original brief, but not production-ready by definition.
