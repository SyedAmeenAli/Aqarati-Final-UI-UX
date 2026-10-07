# AQARATI Google Maps Implementation

## Update: web now renders a real, live, keyless map
The initial pass gated web behind `kGoogleMapsConfigured` (same as native) and
showed "Map unavailable" without a real API key/billing account. That's gone —
web now renders a genuine live Google Map with **no API key needed at all**,
using the classic keyless embed (`maps.google.com/maps?q=lat,lng&output=embed`),
the same no-key mechanism behind Google's own "Share → Embed a map" iframe. This
was prompted by the user supplying that exact iframe pattern and asking for it
to be wired in for real, plus fixing the recurring dev-server crashes.

## Package
- `google_maps_flutter: ^2.18.2` — native (Android/iOS) `GoogleMap` widget only.
- `web: ^1.1.1` — used directly for the web iframe embed (`HTMLIFrameElement` via `dart:ui_web`).
- `google_maps_flutter_web` — **removed as a direct dependency** (still resolves transitively so the federated `google_maps_flutter` plugin has a web implementation registered, but nothing in this app's code calls it — web never constructs a `GoogleMap` widget, so its JS Maps SDK loader, and the earlier boot-stall bug it caused with an invalid placeholder key, is fully sidestepped).

## Platforms configured
- **Android**: `android/app/src/main/AndroidManifest.xml` — `com.google.android.geo.API_KEY` meta-data, still a placeholder (`YOUR_ANDROID_MAPS_API_KEY`). Native still needs a real key.
- **iOS**: `ios/Runner/AppDelegate.swift` — `GMSServices.provideAPIKey(...)`, still a placeholder. Native still needs a real key.
- **Web**: no key, no script tag, nothing to configure. `web/index.html` no longer references the Maps JS API at all.

## API configuration status
- **Web: live, unconditionally, no configuration needed.** Every map surface on web is a real Google Map.
- **Android/iOS: still not configured** — unchanged from the previous pass, `kGoogleMapsConfigured` (now doc'd as native-only) still gates a real `GoogleMap` vs. a clean "Map unavailable" state. Native still needs the steps from the previous pass (Cloud project, billing, 2 restricted keys) — that part of the original task remains undone because no native device/key was available.

## Map widget architecture
- `lib/core/widgets/aqarati_map_view.dart` — `AqaratiMapView`, the one reusable map surface for the whole app. On `kIsWeb`, delegates to `aqarati_map_view_web.dart`'s `buildWebEmbedMap`. On native, unchanged: real `GoogleMap` when `kGoogleMapsConfigured`, else the fallback.
- `lib/core/widgets/aqarati_map_view_web.dart` — the real web implementation: registers an `HTMLIFrameElement` as a platform view via `dart:ui_web`'s `platformViewRegistry`, pointed at `https://maps.google.com/maps?q=<lat>,<lng>&z=<zoom>&output=embed`. Registration is guarded by a module-level `Set<String>` since `registerViewFactory` throws if called twice for the same view type and this widget rebuilds often.
- `lib/core/widgets/aqarati_map_view_stub.dart` — a throwing stub selected on non-web via conditional import (`dart.library.js_interop`), so native builds never try to pull in `dart:ui_web`/`package:web`.

## Real bug found and fixed: platform-view click passthrough
`IgnorePointer` only affects Flutter's own hit-test tree — it does **not** stop
a platform-view iframe from receiving real browser pointer events, since the
iframe is genuine DOM content. Home's compact, tap-to-open "Near you" preview
wraps its map in `IgnorePointer` so the *card* is what's tappable, but with the
real iframe this let a tap fall through to Google's own UI (confirmed: it tried
to open `maps.google.com` in a new tab, which the browser tooling correctly
blocked). Fixed by passing `interactive` down to the iframe itself and setting
`iframe.style.pointerEvents = 'none'` at the DOM level when not interactive —
the actual, verified fix, not just wrapping it in another Flutter widget.

(Initially suspected the same class of bug also broke tapping the Map screen's
price-pill strip — camera recentered but the pill didn't look selected in one
screenshot. Re-tested cleanly: that was a stale/mid-render screenshot, not a
real bug — the pill selection, preview card, and View→Property Detail chain
all work correctly on retest, shown below.)

## Marker architecture
- Property coordinates unchanged from the previous pass — real Oman-area coordinates on `mockProperties` (Al Mouj, Qurum, Al Khoudh, Salalah, Al Khuwair, Ruwi), demo/prototype data.
- **Home "Near you" preview**: real iframe centered on the nearest property, non-interactive (tap opens the full Map screen). Google's own default pin shows at that location — no custom marker needed for a single-location preview.
- **Full Map screen, web**: the iframe has no camera/coordinate-projection API (it's an opaque embed), so real per-property lat/lng screen-projection (used on native) isn't possible here. Instead: a horizontal scrollable strip of the existing `_PricePin` widgets sits above the map; tapping one sets `_selected` and rebuilds the iframe (keyed by property id) centered on that property's real coordinates. This is an honest, functioning design — not fake positioning — verified live: tap "OMR 72K" → map recenters to Al Khoudh → preview card shows "Residential Plot in Al Khoudh / OMR 72,000" → View → Property Detail shows the identical property.
- **Full Map screen, native**: unchanged from the previous pass — real per-marker screen-coordinate projection via `GoogleMapController.getScreenCoordinate`, gated behind `kGoogleMapsConfigured` (still not configured, not locally verifiable).

## Cluster status
Still not implemented — unchanged from the previous pass.

## Location status
Still a no-op current-location button — unchanged from the previous pass, still flagged as a follow-up needing a location package.

## Web verification — live, this pass
- Home → "Near you": real Google Maps tiles render (confirmed: "AL HAIL NORTH", "The Village" labels visible near Al Mouj), correct compact footprint, Google's own attribution footer present.
- Tapping the Home preview card opens the full Map screen (not swallowed by the iframe, confirmed after the `pointerEvents` fix).
- Full Map screen: real live tiles, Buy/Rent/Lease pill, price-pill strip (OMR 185K / 72K / 450 / 7.8K — real per-property prices), current-location/filter circular buttons (still no-ops, unchanged), List View pill.
- Tapped "OMR 72K": pill turned solid-red selected, map recentered to Al Khoudh, preview card showed "Residential Plot in Al Khoudh / OMR 72,000 / Al Khoudh, Muscat / 600 m²" with a working View button.
- View → Property Detail: same property, same price, confirmed identity preserved end to end.
- List View pill → back to Home, confirmed working.
- `flutter analyze`: 0 errors, same 7 pre-existing deprecation infos as every prior checkpoint.

## Dev-server crashes — root cause
Not an app bug. Every crash this session showed the same signature in
`flutter run -d chrome`'s own output: `AppConnectionException` /
`Failed to establish connection with the application instance in Chrome` from
`package:dwds` (Flutter's web debug tooling), and once a missing incremental
compile cache file under Windows `%TEMP%`. Both are the Flutter web dev-tooling
websocket/compile-cache layer being flaky in this environment, not something
introduced by any app code change — the same crash pattern occurred before any
Maps-related code existed. It resolved every time with a plain restart; nothing
in the app needed fixing for it. Removing `google_maps_flutter_web` as a direct
dependency (see Package section) does shrink what gets compiled on web, which
may make these restarts a little faster, but the crashes themselves were never
caused by app code.

## Cleanup performed (per "remove what's unused" request)
- Removed `google_maps_flutter_web` as a direct dependency (unused on web now, see above).
- Removed the commented-out Maps JS API `<script>` tag from `web/index.html` (dead weight — no longer relevant now that web doesn't use the JS SDK).
- Did not remove anything else: `cupertino_icons` is unused in code but is harmless default template scaffolding (a few KB of font assets, zero runtime cost) — flagged, not touched, since removing it has no measurable benefit and isn't what was actually slowing things down.

## Android verification
Not locally verified — no Android device/emulator available in this environment. Unchanged from the previous pass.

## iOS verification
Not locally verified — no macOS/Xcode toolchain available in this environment. Unchanged from the previous pass.

## Known issues / follow-ups
- Native (Android/iOS) still has no real API key — that half of the original task remains undone, unrelated to this pass's web fix.
- Marker clustering not implemented.
- Current-location button still a no-op.
- Web's Map screen no longer has per-marker geo-accurate pin *positions* the way native does (can't get screen coordinates out of an opaque iframe) — the price-pill-strip-plus-recenter design is the honest tradeoff, documented above rather than left unexplained.
