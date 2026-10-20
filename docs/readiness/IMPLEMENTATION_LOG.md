# Full-app readiness: implementation log

## 2026-10-16

Plan followed: preserve, audit motion, audit the whole app, fix supported functionality, test, document. Nothing was committed, pushed or deployed. No packages were added.

### 1. Preserved
Branch `main`, HEAD `5a27396`. Backup before any edit: full `git diff` of uncommitted work (721 lines, reverse-applies cleanly) plus copies of every changed file, in the session scratchpad (`backup_2026-10-16_motion/`). Five files differ only in line endings and were left alone.

### 2. Motion
The motion pack had already been implemented in the previous pass (uncommitted); this pass verified it in source, then closed the remaining gap: eight routes still used the platform-default transition. All routes now use `AQRoute` (guarded by a test), and Compare became a real route.

### 3. Whole-app audit
Method: source sweep (modules, routes, dead callbacks, placeholders, mock-data use), a Chromium walk of 32 routes, three interactive flows (viewing booking end to end, save and reload, search), and a new layout matrix test.

### 4. Fixes
| Finding | Fix | Files |
|---|---|---|
| Eight routes on the platform transition | `pageBuilder` with `AQRoute.forward` | `lib/core/router/app_router.dart` |
| Compare opened by a raw `MaterialPageRoute` | Route `/compare?ids=` | `app_router.dart`, `saved_screen.dart` |
| Buyer opening `/verification` saw "Add your documents" | Redirect home when the role has no documents | `verification_status_screens.dart` |
| Filter bar overflow at 320 px | Stack under 360 px | `aq_filter_sheet.dart` |
| Business profile overflow at 200% text (rating row, section headers) | Flexible and scaled actions | `aq_business_profile.dart` |
| Top-bar action overflow at 200% text (Login) | Flexible and scaled action | `aq_scene.dart` |
| "Recent searches" pre-filled with sample entries | Starts empty | `app_state_providers.dart` |
| Saved properties and recents lost on reload | Local persistence | `lib/data/repositories/local_persistence.dart`, `main.dart` |
| No visible DEMO marker (promised by `backend_mode.dart`) | `AQDemoNotice` on Account, viewing requested, role homes | `lib/core/aq/aq_demo.dart`, `aq_app_shell.dart`, `viewing_status_screens.dart`, `role_home_widgets.dart` |

### 5. Tests added
`test/app_matrix_test.dart` (105: 21 screens x 5 configurations) and `test/app_audit_test.dart` (8: route family, Compare route, buyer verification redirect, persistence, demo notice). Previous total 374; now 487.

### 6. Results
487 tests pass; analyzer 0 errors, 41 items (baseline 42); fresh builds `build/web` 14:26 and `build/web_review` 14:27; Chromium evidence as listed in the interaction matrix.

### 7. Not done
Aqary e-Broker, notifications and account deletion (no source and an open decision or missing API: see the source-gap report); business tabs; per-tab scroll preservation; saved-search persistence; real backend; device and screen-reader testing; committing or pushing.

## 2026-10-16 (later): product-gap pass

Brief: the Master Product Screen Gap Audit. Established the real inventory from the source (78 routes), then built the missing front-end screens that could be built honestly.

### Built
| Item | Files |
|---|---|
| Maintenance booking (requester side): models, repository contract with demo and unavailable implementations, request form with review step, detail with cancel, list | `lib/features/maintenance/*` |
| Activity switch (Viewings, Maintenance) | `lib/features/activity/activity_screen.dart`, router |
| Notifications inbox built from real state, deep links, read state, unread count on Account | `lib/features/notifications/notifications.dart`, `lib/data/repositories/local_persistence.dart` |
| Account deletion flow and the `deleteAccount` contract (unavailable in production wiring, simulated in the demo) | `lib/features/account/delete_account_screen.dart`, `lib/data/api/account_api.dart`, `lib/data/demo/demo_backend.dart` |
| Shared copy (English and draft Arabic) | `lib/core/localization/product_strings.dart` |
| Raw `Navigator.push` screens now use the shared transition | `lib/core/aq/aq_scene.dart` (`AQRoute.route`) |
| "Request a booking" on maintenance provider profiles | `lib/features/business/aq_business_profile.dart` |

### Tests
`test/product_flows_test.dart` (24) and the layout matrix extended to 26 screens (130 checks). Total 536 passing.

### Not built, and why
Aqary e-Broker (fee model undecided, no listing API); provider-side maintenance workspace and invitation acceptance (no API); push notifications and preferences (no service); real account deletion and step-up re-authentication (endpoint not confirmed); AqaratiBroker programme screens (decision pending); review composer and engagement flow (needs the engagement API); the Admin Web Console (a separate app that does not exist yet); version gate and forced update.
