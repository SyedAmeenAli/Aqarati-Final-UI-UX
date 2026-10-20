# Motion interaction matrix

Evidence key: T = automated test (`test/motion_test.dart` unless named), B = Chromium capture on 2026-10-16 (QA build, demo backend). "Reduced" = behaviour when the system asks for reduced motion.

| Interaction | Motion | Timing | Reduced | Evidence |
|---|---|---|---|---|
| Route push | Slide 20 px from the logical forward side (right LTR, left RTL) plus fade; page below drifts 6 px and fades | 300 ms in, 260 ms out, ease-out / ease-in-out | Fade only | T (LTR and RTL direction, pop reverses) |
| Route pop | Same motion reversed | 260 ms | Fade only | T |
| Main tab change | Fade-through (old clears, new fades in); no travel | 180 ms | Instant | T, B (mid-frame shows no overlap) |
| Tab indicator | One pill slides to the selected tab; selected icon scales 0.92 to 1.0; colours fade | 180 ms | Instant | T (indicator travels), B |
| Button press | Scale to 0.98 down, back to 1.0 | 100 ms down, 160 ms up | Pressed state kept, zero duration | T |
| Disabled button | No response to press | n/a | n/a | T |
| Card and tile press | Scale to 0.985 (shared `AQPressable`) | 100 / 160 ms | Zero duration | existing tests |
| Theme change (Account) | Whole AQ palette interpolates; Material theme uses the same duration and curve; route, scroll, form values, role preserved | 340 ms, ease-in-out | 100 ms | T (interpolation, state preserved), B (page colour sampled: 227, 138, 41, 40) |
| Buyer / Agent switch | Thumb slides (220 ms); page fades with an 8 px rise | 220 ms | No rise | T (existing role-home tests), B |
| Status banner (unapproved) | Reveals with fade and rise once | 240 ms | Instant | T (banner shows, no business content); the reveal itself is not asserted |
| Signup Next / Back | Body slides 14 px in the direction of travel (mirrors in RTL) with fade; height eases | 240 ms | Instant swap | T (LTR, RTL, values survive, invalid Next stays) |
| Invalid submit | Error row fades in; step and values kept | 180 ms | Instant | T |
| Documents hint | Folds away when every document is in | 220 ms | Instant | Existing document tests; not captured in the browser this pass |
| Favourite heart | Pops once 0.9, 1.08, 1.0 on a real change; colour fades; no animation on first build; no loop | 260 ms | Static | T |
| Bottom sheets | Rise with ease-out, leave with ease-in; scrim fades | 320 / 240 ms | Platform default off | code path used by both sheets |
| Dialog (photo viewer) | Fade over 200 ms | 200 ms | n/a | code only |
| Project filter chips | Selected border and fill animate; list swaps with a fade | 180 / 200 ms | Zero | role-home tests (filter); not captured in the browser this pass |
| Role-home entry | Header, hero, cards fade and rise once, 45 ms stagger capped at five | 240 ms plus stagger | Skipped | role-home tests (reduced motion) |

## Not animated on purpose

- Anything implying success before the operation returns: no optimistic status changes, no success checks for unavailable services.
- Counters, unread badges and metrics (none exist).
- Role-home tiles for unavailable services (they expand an explanation in place; they never navigate).
