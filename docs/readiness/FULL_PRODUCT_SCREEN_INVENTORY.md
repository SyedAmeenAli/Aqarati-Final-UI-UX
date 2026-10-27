# Full product screen inventory

Updated 2026-10-16 from the actual repository (`aqarati-app`, branch `main`, HEAD `5a27396`, with uncommitted work). The route list was extracted from the router source (78 routes now; 74 before this pass), plus screens reached without a route.

Status words: **implemented & verified** (source, tests and a browser walk agree), **implemented not verified**, **partial**, **missing**, **demo-only** (works on an in-memory repository), **blocked by API**, **decision needed**.

Evidence: T = automated test file; B = Chromium route or flow walk on 2026-10-15/16 (QA build); M = the 26-screen layout matrix (`app_matrix_test.dart`: 320 light, 320 dark, Arabic 360, 200% text, Arabic dark 430). Counts of screens are given only for routes found in the source, not for products that are not in this repository.

## 1. Entry, identity and signup

| Screen | Route | File | Status | Notes | Evidence |
|---|---|---|---|---|---|
| Entry / launch film | `/entry` | `entry/screens/onboarding_entry_screen.dart` | implemented & verified | No version gate or forced-update screen exists | T intro, B |
| Purpose selection (six paths) | `/onboarding/purpose` | `entry/screens/purpose_selection_screen.dart` | implemented & verified | Exactly six cards, single select | T `signup_paths`, `onboarding_experience`, B |
| Signup form (six role paths) | `/signup/user|agent|construction|development|architecture|interior-exterior` | `flow/screens/signup_form_screen.dart` | implemented & verified (demo) | Company email and address added; decisions D3 open | T, B |
| Phone OTP | `/otp` | `flow/screens/otp_screens.dart` | demo-only | Limits are simulated | T, B |
| Email verification | `/verify-email` | `flow/screens/email_verification_screen.dart` | implemented not verified | | T partial |
| Account active | `/account/active` | `flow/screens/otp_screens.dart` | demo-only | | T, B |
| Login | `/login` | `flow/screens/auth_screens.dart` | demo-only | No real auth; no session restore | M, B |
| Forgot / reset password | `/forgot-password`, `/reset-password` | `flow/screens/auth_screens.dart` | demo-only | | M, B |
| Terms, Privacy | `/legal/terms`, `/legal/privacy` | `flow/screens/legal_screens.dart` | partial | Placeholder text; no consent versions | M, B |
| Invitation acceptance (maintenance provider) | none | none | missing | Admin-invited path; needs invite API and provider workspace | none |
| Forced update / version gate | none | none | missing | Needs config API | none |

## 2. Business verification

| Screen | Route | File | Status | Evidence |
|---|---|---|---|---|
| Verification intro | `/onboarding/verification-intro` | `flow/screens/verification_onboarding_screens.dart` | demo-only | B |
| Documents | `/onboarding/documents` | same | demo-only (picker, signature check, expiry; no real storage) | T `document_controller`, B |
| Review, Submitted | `/onboarding/review`, `/onboarding/submitted` | same | demo-only; review refresh bug fixed | T, B |
| Status (all grant states) | `/verification` | `flow/screens/verification_status_screens.dart` | implemented not verified for all states in a default browser; buyers are redirected home | T `app_audit`, `onboarding_experience` |
| Application details | `/verification/details` | same | implemented not verified | T partial |
| Resubmission, review, resubmitted | `/verification/resubmit*` | same | demo-only | T partial |
| Approved, summary, activation | `/verification/approved`, `/verification/summary`, `/workspace/activation` | `flow/screens/approval_screens.dart` | implemented not verified (QA-only reachability) | T partial |

## 3. Home, Explore, Search, Properties

| Screen | Route | File | Status | Evidence |
|---|---|---|---|---|
| Role-aware home (six) | `/app/home` | `role_home/*`, `workspace/aq_home.dart` | implemented & verified (front end) | T `role_home` 97, B, M |
| Explore | `/app/explore` | `workspace/aq_explore.dart` | implemented & verified (layout), mock data | B, M, T |
| Search start, results | `/search/start`, `/search` | `search/aq_search.dart` | implemented & verified (layout), mock data | T `search_filters`, B, M |
| Property types / markets | `/properties` | `search/aq_property_types.dart` | partial | Four markets present; Invest not in the model (decision needed) | B, M |
| Results list | `/properties/all` | `workspace/aq_home.dart` | implemented & verified (layout), mock data | B, M |
| Results map | `/map` | `search/aq_map.dart` | implemented not verified on a device (keyless embed) | B, M |
| Property detail | `/property/:id` | `property/property_detail_screen.dart` | implemented & verified (layout), mock data | B, M, T |
| Gallery, Enquiry, Offer | none (pushed with the shared transition) | `property/property_gallery_screen.dart`, `enquiry/*` | partial: honest "saved on this device, not delivered" | T `listing_pages` |
| Compare | `/compare` | `compare/compare_screen.dart` | implemented | T |
| Saved | `/saved` | `saved/saved_screen.dart` | implemented & verified; saved ids persist on the device | T, B |
| Listing submission, review, lifecycle | none | none | missing | Needs owner/agent listing API and the e-Broker decision |
| Aqary e-Broker (sell) | none | none | missing, decision needed (fee model #26) | none |

## 4. Viewings and Activity

| Screen | Route | File | Status | Evidence |
|---|---|---|---|---|
| Activity (viewings and maintenance switch) | `/app/activity` | `activity/activity_screen.dart`, `viewing/screens/my_viewings_screen.dart` | implemented & verified (demo) | T `product_flows`, B, M |
| Availability, slot, review, conflict | `/property/:id/viewing[...]` | `viewing/screens/viewing_schedule_screens.dart` | demo-only; verified to "requested" | T `viewing_logic` 6, B, M |
| Requested, confirmed, declined, reschedule, cancel, cancelled, completed, review entry, detail | `/viewings/:id[...]` | `viewing/screens/*` | demo-only (host answers simulated, QA only) | T, B partial |

## 5. Maintenance (new in this pass)

| Screen | Route | File | Status | Evidence |
|---|---|---|---|---|
| Provider discovery | `/professionals?cat=maintenance`, home tiles | `business/aq_professionals.dart` | implemented & verified (mock data) | B, M |
| Provider profile with "Request a booking" | `/business/:id` | `business/aq_business_profile.dart` | implemented & verified | B, M |
| Booking request (form, review, send) | `/business/:id/book` | `maintenance/maintenance_screens.dart` | demo-only; verified end to end | T `product_flows` (10), B, M |
| Request detail, cancel, status timeline copy | `/bookings/:id` | same | demo-only | T, B |
| Requests list | Activity > Maintenance | same | demo-only | T, B |
| Provider-side (confirm, decline, complete) | none | QA controls only | missing, blocked by API (provider workspace) | none |
| Review after completion | pushes the eligibility explainer | `reviews/review_screen.dart` | partial (explains the rule; no composer) | T partial |

## 6. Notifications and account

| Screen | Route | File | Status | Evidence |
|---|---|---|---|---|
| Notification inbox | `/notifications` | `notifications/notifications.dart` | partial: in-app inbox built from real viewing, maintenance and verification state; deep links; read state kept on the device | T, B, M |
| Notification delivery (push), preferences | none | none | missing, blocked by API | none |
| Account overview | `/app/account` | `workspace/aq_app_shell.dart` | partial | M, B |
| Delete account (info, confirm, working, result) | `/account/delete` | `account/delete_account_screen.dart` | partial: UI complete; the real endpoint is not confirmed so production wiring reports "nothing was deleted" | T (4), M |
| Edit personal profile, organisation members, devices and sessions | none | none | missing | needs APIs |
| Language, theme | in Account | | implemented & verified | B, T motion |

## 7. Professionals, Development & Building, workspaces

| Screen | Route | File | Status | Evidence |
|---|---|---|---|---|
| D&B home, categories, results (list and map) | `/app/explore/build[...]` | `devbuild/db_discovery.dart` | demo-only roster; verified | T 75, B, M |
| Company profile, reviews, projects, project detail, gallery | `/build/pro/:id[...]`, `/build/project/:id[...]` | `devbuild/db_profile.dart` | demo-only | T, B |
| Business workspace dashboard | `/app/account/workspace` | `devbuild/db_workspace.dart` | demo-only | T |
| Projects list, wizard, status, submitted | `/app/account/workspace/projects`, `/workspace/projects/*` | `devbuild/db_projects.dart`, `db_wizard.dart` | demo-only; media and amenities blocked | T 40, B (wizard opens) |
| Profile edit and status | `/app/account/workspace/profile[...]` | `devbuild/db_pro_tools.dart` | partial: not persisted | T, B |
| Leads, lead detail | `/app/account/workspace/leads`, `/workspace/leads/:id` | same | blocked by API | T |
| Business reviews | `/app/account/workspace/reviews` | same | partial | T |
| Engagements and detail | `/app/account/workspace/engagements`, `/workspace/engagements/:id` | same | blocked by API | T |
| Portfolio | `/app/account/workspace/portfolio` | same | blocked, proposed | T |
| AqaratiBroker | home card to `/professionals` | | partial: no dedicated programme screens; decision pending | B |

## 8. Tools

| Screen | Route | Status | Evidence |
|---|---|---|---|
| Calculators list and three calculators | `/calculators`, `/calculators/:id` | implemented & verified (disclaimer shown) | T 7, B, M |

## 9. Separate products (not in this app)

| Product | Status | Evidence |
|---|---|---|
| Admin Web Console (`aqarati-admin-web`) | **missing**: the sibling monorepo `aqarati/apps/admin-web` contains README files only (18 files, 0 code files) | file count |
| Backend API | exists separately: `aqarati/apps/api` has 105 non-README files including database migrations; it was **not inspected** in this pass and no contracts from it were assumed | file count |

## Totals (from the source, not estimates)

78 routes in the Flutter router; 26 screens in the layout matrix; every route renders without error in the QA build. Screens that are `missing`: e-Broker sell flow and listing lifecycle, notification push and preferences, profile and organisation members and devices, invitation acceptance, version gate, admin console, provider-side maintenance workspace. Everything marked demo-only needs real services before release.

## 10. Confirmed workflows (added 2026-10-27)

See `CONFIRMED_WORKFLOWS_IMPLEMENTATION.md` for behaviour, assumptions and missing contracts.

| Screen | Route | Status | Evidence |
|---|---|---|---|
| My listings (filters, cards, states) | `/agent/listings` | implemented, demo-only | T `agent_listings` |
| Add / edit listing | `/agent/listings/new`, `/:id/edit` | implemented, demo-only | T |
| Listing detail, pause, resume, renew | `/agent/listings/:id` | implemented, demo-only; pause needs a contract transition | T |
| Agent leads and detail (Call, confirm / decline viewing) | `/agent/leads`, `/:id` | implemented, empty until a lead service exists | T `leads` |
| Project enquiries | `/workspace/enquiries`, `/:id` | implemented, empty until a lead service exists | T |
| Service requests | `/workspace/requests`, `/:id` | implemented, empty until a lead service exists | T |
| Sponsored banner on Home | pinned under the hero | implemented; hidden when empty or unreachable | T `sponsored_banner` |
| Admin sign-in, one-time code, step-up | `/login`, `/code` | implemented, demo-only (separate build) | T `admin_console` |
| Verification queue and detail | `/verification`, `/:id` | implemented, demo-only | T |
| Listing moderation and e-Broker review | `/moderation`, `/:id` | implemented, demo-only | T |
| Ads & Sponsors list, create, edit, preview, review | `/ads`, `/new`, `/:id/edit` | implemented, demo-only | T |

Admin Web Console: no longer "not built". It is a separate entry point in this package
(`lib/admin_main.dart`); the monorepo's `apps/admin-web` folder is still a README scaffold and the
console can move there once a shared design package exists.
