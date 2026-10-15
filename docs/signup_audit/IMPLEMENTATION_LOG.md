# Signup implementation log

Source status key: SOURCE = in architecture v2.6 or the implementation prompt; DERIVED = follows from SOURCE; PENDING = needs a decision; FUTURE = not built.

## 2026-10-15: implementation pass

Starting point: SU-01 and the shared form already existed (`PurposeSelectionScreen`, `SignupFormScreen`, `roleConfigs`). Gaps from the audit were closed where the source settles them.

| Change | Status | Files |
|---|---|---|
| Phone rule is `+968` plus exactly 8 digits. The undocumented 7/9 leading-digit rule was removed. Hint changed from `9X XXX XXX` to `XXXX XXXX`. | SOURCE | `lib/features/flow/state/signup_state.dart`, `lib/core/localization/flow_strings.dart` |
| Company email on the four company paths (construction, development, architecture, interior/exterior). Required, validated, and used as the sign-in email (the spec's "Username (company email)"). Kept separate from the contact person's email. | SOURCE (§19.5-19.8) | `account_models.dart` (`hasCompanyContact`, `companyEmail`), `signup_state.dart`, `signup_form_screen.dart` |
| Company address on the same four paths. Required for architecture and interior/exterior. Optional for construction and development, where the spec lists the field without "(required)". | SOURCE | `account_models.dart` (`companyAddressRequired`, `companyAddress`) |
| Company sign-in uses the company email; people and agents use their own email. | DERIVED | `signup_state.dart` `submit()` |
| Purpose-card copy for Building Architecture and Interior & Exterior matches the prompt exactly. | SOURCE | `signup_purpose.dart` |
| **Bug fix:** "Review application" on the documents screen now refreshes the verification status before opening the review. Before, the review showed uploaded documents as "Upload required" and Submit stayed disabled. Found in the browser walk; the new test fails without the fix. | n/a | `verification_onboarding_screens.dart` |
| 29 new tests. | n/a | `test/signup_paths_test.dart` |

Not changed (SU-01 already satisfied the prompt): six cards, no preselection, Continue disabled until a choice, single selection, no Skip, scrollable at 320 px, reduced-motion aware.

## Cleanup of formatter noise (done)

`dart format` had rewritten 22 files. Recovery, in order:
1. Backup first: full `git diff` (6,091 lines, reverse-applies cleanly) plus copies of every uncommitted file, kept outside the repo in the session scratchpad (`backup_2026-10-15/`).
2. Each file was compared with `HEAD` after ignoring whitespace and formatter-added trailing commas. 17 files were identical to HEAD under that test, so they were restored with `git restore`.
3. The four mixed files were restored, the functional edits re-applied by script, and each result matched the backed-up version under the same comparison.
4. Final diff: 6 files, 59 insertions, 12 deletions (the five functional files above plus the bug fix), apart from the six older line-ending-only files that were already modified before this work.

No commit, reset, checkout of another commit or push was used. Branch `main`, HEAD `ff12824`, unchanged.

## Verified results (2026-10-15)

| Check | Result |
|---|---|
| `flutter test` | 254 passed, 0 failed (29 new) |
| `flutter analyze` | 41 info/warning items, 0 errors; same count as before this work |
| `flutter build web --release --pwa-strategy=none -o build/web` | Built at 17:26 on 2026-10-15, after the last source change; `build/web/main.dart.js` contains the new strings ("Company email", "This is the email you will sign in with", "Register your design firm on AQARATI") |
| Dark build `--dart-define=AQ_THEME=dark -o build/web_dark` | Built, used only for the dark-mode walk |
| Chromium walk | See the readiness checklist |

Served build identity: the walk server served `build/web`; the bundle fetched over HTTP contained the new strings, and the browser showed the new company fields, the `XXXX XXXX` phone hint and the updated card copy. The Vercel deployment still holds the earlier push (`ff12824`) and does not contain this uncommitted work.
