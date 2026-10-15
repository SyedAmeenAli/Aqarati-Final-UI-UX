# Signup interaction matrix

Source key: SOURCE / DERIVED / PENDING / FUTURE. Backend: DEMO = `kUseDemoBackend` simulation, nothing real is created.
Evidence key: T = automated test (`test/signup_paths_test.dart` unless named), B = Chromium walk of 2026-10-15 (see the readiness checklist for widths, themes, languages), none = not verified.

| Control | Action / destination | State change | Backend | Source | Evidence |
|---|---|---|---|---|---|
| Purpose card (x6) | Selects that path | Exactly one selected; others deselect; tagline appears | none (intent only) | SOURCE | T, B |
| Purpose Continue | Opens `/signup/<path>` for the selected card | Disabled until a card is chosen | none | SOURCE | T (disabled state), B |
| Purpose Back | `/entry` | none | none | DERIVED | B |
| Skip on Purpose | Not offered | n/a | n/a | PENDING (policy) | T (no Skip) |
| Form Next | Validates the step, then advances | Step index +1, draft saved | none | SOURCE | T (validation), B |
| Form Back | Previous step, or Purpose from step 1 | Values kept | none | SOURCE | B |
| Phone field | `+968` plus 8 digits | Error under field if not 8 digits | none | SOURCE | T |
| Company email | Required on company paths; becomes the sign-in email | Error under field | DEMO | SOURCE | T, B (error and entry, EN/AR) |
| Company address | Required for architecture and interior/exterior, optional otherwise | Error under field when required and empty | DEMO | SOURCE | T, B |
| Service type (Interior / Exterior / Both) | Required for interior/exterior | Value kept | DEMO | SOURCE | T |
| Password show/hide | Toggles visibility | Local only | none | DERIVED | B |
| Password rules | Live list: 8+ characters, an uppercase letter, a number | Folds to one line when met | none | SOURCE (§44) | T |
| Password blocklist | Not implemented | n/a | needs service | PENDING | none |
| Consent checkbox | Required to create the account | Error if unchecked | none | SOURCE | T |
| Terms / Privacy links | `/legal/terms`, `/legal/privacy` | none | none | DERIVED | B |
| Create account | Submits once, then `/otp` | `submitting` blocks a second tap; form kept on failure | DEMO | SOURCE | B |
| OTP entry | 6 digits, demo code `123456` | Verifies, then account-active | DEMO | SOURCE | B |
| OTP resend | 60 s cooldown | Counter; limits in `otp_state.dart` | DEMO | SOURCE | `otp` tests (earlier) |
| Account active > Add documents | Verification intro | Account active is not business approval | DEMO | SOURCE | B |
| Document tile | Expiry date first (CR-type documents), then the file picker; status, replace, preview | Rejected if not PDF/JPG/PNG by signature | DEMO (no upload service) | SOURCE | `document_controller_test.dart`, B (chooser, valid PDF, invalid file rejected) |
| Review application (documents screen) | Refreshes status, opens `/onboarding/review` | Review shows the uploaded documents; Submit enabled when none are missing | DEMO | SOURCE | T (fails without the fix), B |
| Submit application | `/onboarding/submitted` | Reference shown, status Under review | DEMO | SOURCE | B (all five business paths) |
| Status, resubmission, approved, summary, activation | Unreachable in a default build | n/a | DEMO / `REVIEW_TOOLS` | SOURCE | earlier tests only; not re-walked |
| Agent workspace and Agent/Buyer switch | Not built | n/a | n/a | PENDING (D5) | none |
