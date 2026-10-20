# Motion readiness checklist

Updated 2026-10-16. Demo backend only. No real device, screen reader, haptics or deployment testing. Stills cannot prove timing, so durations and directions are proven by tests; browser captures show real frames in flight.

## Results

| Check | Result |
|---|---|
| `flutter test` | 374 passed, 0 failed (23 new in `test/motion_test.dart`) |
| `flutter analyze` | 0 errors, 41 info or warning items. Baseline at the start was 42 (same command); one item raised by earlier role-home code was fixed and none were added. The items in touched files are old patterns (for example `curly_braces_in_flow_control_structures` in `db_profile.dart`). |
| Production build | `build/web`, 03:05 on 2026-10-16, from the final source |
| QA build | `build/web_review`, 03:02 (sessions via `?session=`) |

## Acceptance criteria

| Criterion | Status | Evidence |
|---|---|---|
| Pushes animate in a consistent logical direction and pops reverse | Done | T, LTR and RTL |
| Main tabs: fast indicator and content transition | Done (scroll state per tab not preserved, see gaps) | T, B |
| Sheets, dialogs animate and dismiss in reverse | Done for the existing two sheets and one dialog | code, not separately captured |
| Buttons give immediate pressed feedback; disabled ones do not respond | Done | T |
| Hero used only where stable | Unchanged (10 existing) | n/a |
| Review and submit CTA: no jump or overlay | Hint folds smoothly; button is always present and enabled or disabled | code and existing document tests; not captured in the browser this pass |
| Wizard and signup steps, errors | Signup form done; project wizard already had a switcher (unchanged) | T |
| Light to dark animates all surfaces | Done | T (palette interpolation), B (page colour 227, 138, 41, 40) |
| Theme change keeps route, role, form values, scroll | Done | T (text and scroll offset preserved) |
| In-app setting drives it, not the OS | Done (`themeModeProvider`) | code |
| Six role homes keep their distinct layouts and permissions | Unchanged | role-home tests all still pass |
| Buyer / Agent switch animates and works both ways | Done | role-home tests, B |
| Non-approved accounts never flash business content | Unchanged (skeleton, then buyer home) | role-home tests |
| Missing services stay honestly unavailable | Unchanged | role-home tests |
| Reduced motion reduces nonessential movement | Done (tokens, routes, steps, hearts, press, theme 100 ms) | T |
| Arabic RTL direction | Done for routes, steps, nav indicator | T (routes, steps), indicator uses a start-aligned position |
| 320 to 430 px and large text without overflow | Existing role-home and form tests still pass; no new layout was added except the nav indicator (inside the same bar) | tests |
| No ticker leaks, duplicate submits, stuck loading | New controllers (`AQThemeTransition`, `AQHeart`) are disposed; zero-duration `AnimatedSize` bug fixed | tests |

## QA capture set

| # | Capture | Status |
|---|---|---|
| 1 | Buyer home light, dark, Arabic | Light and dark earlier (role homes); this pass sampled the theme fade. Arabic buyer home not re-captured |
| 2 | Explore to results to detail push and pop | Direction proven by tests; not captured on screen |
| 3 | Filter sheet open, apply, dismiss | Not captured |
| 4 | Buyer to Agent both ways | Captured (frames in flight) |
| 5 | Agent blocked surfaces | Unchanged, covered by role-home tests |
| 6 | Construction home to company profile | Covered earlier |
| 7 | Developer filter and wizard step | Filter in tests; project wizard step not re-captured |
| 8 | Invalid form, fix, CTA | Tests; document hint not captured this pass |
| 9 | Project submission success and failure | Not applicable (no new work) |
| 10 | Company profile edit, unsupported save | Unchanged |
| 11 | Theme change on a populated page and inside a form | Populated page captured and sampled; inside a form proven by test (values and scroll preserved) |
| 12 | Reduced motion run | Tests (not a recorded browser run) |
| 13 | 320 px and 200% text on the tightest role home | Covered by existing role-home tests |

Real browser outputs: theme sampling and frames in `vw/mo/` (session scratchpad, not in the repository). Everything else is test evidence. Mockups were not used as evidence.

## Gaps and blockers

- Tab scroll state is not preserved when switching tabs (needs a stateful shell route).
- The theme sampler for Arabic did not run (script label mismatch); RTL behaviour of the theme is direction-independent and routes and steps are tested in RTL.
- Sheets and the dialog were harmonised in code but not exercised in the browser this pass.
- No Hero, parallax, shimmer, toast or counter work (no matching supported data or features).
- No real-device, screen-reader or deployment testing.
