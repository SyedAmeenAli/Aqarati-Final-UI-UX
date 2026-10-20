# Motion audit and implementation log

Date: 2026-10-16. Branch `main`. HEAD at the start was `5a27396` (already pushed), not `ff12824` as the brief assumed. The working tree held only five line-ending-only files before this work. Nothing was committed, pushed or deployed. No packages were added.

## Audit: what already existed

| Area | Before |
|---|---|
| Tokens | `AQMotion` (micro 110, fast 180, standard 260, slow 380, page 340, hero, reveal, curves) and `reduced()` / `scaled()`; reduced motion honoured in about 80 places |
| Routes | `AQRoute.forward` (vertical 3% rise plus scale, not direction-aware), `sheet`, `hero`, `fade` |
| Tabs | four tab pages used `NoTransitionPage` (no transition); nav pill only faded its background colour |
| Press | `AQPressable` 0.985 over 110 ms both ways; buttons used the same |
| Theme | Material widgets interpolated (default 200 ms), but every AQ surface reads `AQColors.of(context)`, a pair of constants chosen by brightness, so **AQ surfaces, text, borders and icons snapped** |
| Forms | text field focus, validity icon and error row already animated; the OTP field had a nudge; the signup step body swapped with no transition; the project wizard already used an `AnimatedSwitcher` |
| Sheets and dialogs | two bottom sheets already used an `AnimationStyle` (380 ms, spring); one dialog used the default |
| Hearts | the icon swapped with no animation (two places) |
| Skeletons | static (no shimmer), so nothing loops |
| Loading to role home | already a skeleton, then a crossfade (from the role-home work) |

## Gaps found

1. Theme change snapped for all AQ surfaces.
2. Route push was vertical, not logical-direction, and did not mirror in RTL.
3. Tabs switched with no transition; the nav indicator did not move.
4. Step changes in the signup form had no transition and no direction.
5. Hearts did not animate.
6. Press release was as fast as press; buttons used 0.985, not 0.98.
7. The "upload every document" hint vanished abruptly when the last document arrived.
8. A latent bug: `AnimatedSize` asserts when its duration is zero and its size changes, which is exactly what reduced motion produced.

## Implemented

| Change | Files |
|---|---|
| Brief tokens added to `AQMotion`: `tapDown` 100, `tapUp` 160, `icon` 180, `page` 300 (was 340), `sheet` 320, `sheetReverse` 240, `dialog` 200, `formStep` 240, `theme` 340, `themeReduced` 100, `state` 220, `routeTravel` 20 px, `stepTravel` 14 px | `lib/core/aq/aq_tokens.dart` |
| **Animated palette**: `AQColors.lerp`, `AQColorScope`, `AQThemeTransition`. `AQColors.of` returns the interpolated palette, so the in-app theme change fades every AQ surface together. Material's own theme animation uses the same duration and curve. Route, scroll, form values and role are untouched. Reduced motion: 100 ms | `aq_tokens.dart`, `lib/main.dart` |
| Push: horizontal slide from the logical forward side (right in LTR, left in RTL), 20 px, with fade; the page underneath drifts 6 px and fades; pop plays the reverse | `aq_scene.dart` (`AQRoute.forward`) |
| Tabs: fade-through (old content clears first, new fades in second); no travel | `aq_scene.dart` (`AQRoute.tab`), `app_router.dart` (4 pages) |
| Nav: one indicator that slides to the selected tab (mirrors in RTL), selected icon scale 0.92 to 1.0, icon and label colour fade | `aq_scene.dart` (`AQGlassNav`) |
| Press: 100 ms down, 160 ms release; buttons press to 0.98 | `aq_primitives.dart` |
| `AQStepSwitcher`: directional slide (14 px) and fade, RTL aware, values live outside; used by the signup form | `aq_scene.dart`, `signup_form_screen.dart` |
| `AQHeart`: pops once (0.9, 1.08, 1.0) only when the saved state changes; colour fades; static under reduced motion | `aq_scene.dart`, `aq_home.dart`, `property_detail_screen.dart` |
| `AQAnimatedSize`: reduced-motion safe replacement used everywhere `AnimatedSize` appeared | `aq_scene.dart` and 5 call sites |
| Documents screen: the prerequisite hint folds away smoothly when the last document is in | `verification_onboarding_screens.dart` |
| Role switch: fade plus 8 px rise (none under reduced motion); status banner reveals instead of appearing | `role_home_screen.dart` |
| Sheets and dialog: consistent family (sheet 320/240 ease-out/ease-in, dialog 200 ms) | `aq_scene.dart`, `aq_filter_sheet.dart`, `aq_business_profile.dart` |

## Deliberately not changed

- Tab scroll state is not preserved per tab. That needs a router restructure (a stateful shell), and the brief says "where the architecture allows". Documented as a gap.
- Hero transitions: none added. The 10 existing `Hero` widgets stay.
- No shimmer was added to skeletons (they are static, which already satisfies "stop on data and reduced motion").
- A "review CTA that appears when available": the documents and review buttons are always present and enabled or disabled. The disabled-to-enabled colour change and the folding hint are animated; the button is not inserted and removed, so it never covers fields.
- No new toast, badge or counter animations: there are no unread counts or live metrics to animate.

## Verification

See the readiness checklist. 374 tests pass (23 new in `test/motion_test.dart`); analyzer 41 items against a baseline of 42 (one removed, none added); fresh production build; Chromium captures.
