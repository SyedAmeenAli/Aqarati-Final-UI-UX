# AQARATI: audit of the six public signup paths

Read-only audit. No application source file was changed. The only files written are the two documents in `docs/signup_audit/`.

- Audit date: 2026-10-15
- Repository: `aqarati-app` (Flutter), branch `main`, HEAD `ff12824`
- Backend: none. Everything below runs on the in-memory demo (`lib/core/config/backend_mode.dart`: `kUseDemoBackend = true`; `lib/data/demo/demo_backend.dart`).

## 0. What was inspected, and what was not

### Inspected (all read)

| Source | Location | Notes |
|---|---|---|
| Flutter app source | `lib/features/entry`, `lib/features/flow`, `lib/core/aq`, `lib/core/domain/account_models.dart`, `lib/data/api/account_api.dart`, `lib/data/demo/*`, `lib/core/router/app_router.dart`, `lib/core/localization/flow_strings.dart`, `lib/features/devbuild/*` (handoff only) | Read in full for the signup journey. |
| Tests | `test/flow_logic_test.dart`, `onboarding_experience_test.dart`, `document_controller_test.dart`, `aq_components_test.dart`, `intro_preferences_test.dart`, `devbuild_workspace_test.dart` (grep) | The first five were **run today: 45 passed, 0 failed** (log kept in the scratchpad, not in the repo). |
| Architecture document | `../aqarati/docs/architecture/AQARATI_Complete_System_Architecture_v2.6.pdf` (text extracted with `pdftotext`) and `../aqarati/docs/product/roles-and-signup.md`, `docs/decisions/open-decisions.md`, `docs/architecture/06-identity-and-verification.md` | Sections used: §19.2 to §19.9 (role experiences), §30.1 (`POST /auth/sign-up`), §44 to §49 (auth, verification, documents). |
| Earlier audit | `ONBOARDING_AUDIT_REPORT.md` (2026-10-07, commit `a710be4`) | Used as history only. Several of its findings are now fixed; see section 7.4. |
| Image folders | `Desktop/Phone Images Aqariti` (24 PNG/JPG), `Desktop/figma aqarati` (895 PDFs), `Desktop/Final Figma Aqarati` (brand PDFs), `Desktop/aqarati onboaring image` (47 JPG), `docs/development_building/REFERENCE_IMAGE_INDEX.md`, `assets/` | Section 6. |
| Live inspection | Release web build of `ff12824`, Chromium via Playwright, 393 x 852, light theme, English. Script: `scratchpad/vw/signup_walk.js` and `signup_walk2.js`. | All six paths were walked from `/signup/<path>` to OTP and the "account active" screen. The five business paths were then walked on to the verification intro and the document list. Synthetic test values only. |

### Not available or not done

- **Architecture v2.4 was not found.** The only architecture file in the workspace is **v2.6** (and its markdown summaries). v2.6 is treated as the source of truth, as the repository's own `CLAUDE.md` says. Nothing here claims to have read v2.4.
- The "AQARATI frontend implementation / master blueprint" PDF named in earlier memory notes (`AQARATI_Final_Frontend_Backend_Master_Blueprint_100pp.pdf`) was not found in the workspace this time. It was not used.
- No Figma file was opened online. Only the exported PDFs on the Desktop were read.
- Not tested at all: real devices, VoiceOver, TalkBack, haptics, a real keyboard, the native file picker, SMS, Firebase, any backend.
- Not inspected today: dark theme and Arabic/RTL layout of the signup screens, 320 px and 430 px widths, the review / submitted / status / resubmission / approved screens (they are unreachable in a default build without the QA flag `--dart-define=REVIEW_TOOLS=true`, and the web file picker cannot be scripted). Earlier baseline browser walks of those screens exist (`ONBOARDING_AUDIT_REPORT.md`) but are older than the last polish pass.

## 1. Executive summary

- All **six paths exist and are reachable**. They share **one form** (`SignupFormScreen`) driven by one config table (`roleConfigs`), one OTP flow, one account-active screen and one verification chain. The paths differ only in: the optional business step, the document list, the four-eyes rule, and the post-approval destination.
- The **user-to-shop path is complete** up to the buyer home, and matches the architecture.
- **Real Estate Agent**: signup, OTP and documents match the architecture (photo ID, agent licence with expiry, supporting document, agency name). The **post-approval Agent workspace and the Agent / Buyer role switcher do not exist.** Worse, the workspace handoff screen lists three capabilities ("Switch between Buyer and Agent", "Create and manage listings", "Manage viewing availability") that are not built.
- **Construction, Property Development, Building Architecture, Interior & Exterior Design**: signup, OTP, documents and the Development & Building workspace exist. The signup form is **missing fields the architecture lists for company paths**: a company physical address (stated as **required** for Architecture and Interior & Exterior), and a separate company email (the architecture lists both a contact email and a "Username (company email)"). Municipal licence **expiry is not tracked**, although the architecture tracks "Licence, CR".
- **Consent versions** (`terms_version`, `privacy_version`) are not captured. The password blocklist (10,000 entries, §44) is not implemented. The reason-code list in the app (3 codes) is not the architecture's 12.
- There is **no real backend, no session restore and no route guard.** The deployed Vercel site is built from the same code, so it runs on the demo too (the demo OTP `123456` is therefore expected to work there; not tested on the live URL).
- **The existing visual references cannot be used as they are.** The six journey sheets in `Phone Images Aqariti` contain many fields that are in no architecture section (RERA number, years of experience, areas of operation, specialisations, company type, company size, year established, registered address with legal entity type, optional company profile documents, and more) and show a different document set for the agent. The purpose-selection reference shows six *different* purposes. The verified-workspace reference is green and invents Listings / Inquiries / Insights. The `figma aqarati` PDFs are the old red-theme design. See sections 6 and 7.
- Screen counts per path (section 2.2): User 8 screens (7 verified), Agent 21 (9 verified, 3 partial, 8 not verified, 1 missing), Construction 21 (8 / 4 / 9 / 0), Development 21 (8 / 4 / 9 / 0), Architecture 21 (7 / 4 / 10 / 0), Interior & Exterior 21 (8 / 4 / 9 / 0).
- **Decisions needed before reference images can be finalised: section 7.2 (D1 to D13).** The most important are D1 (company email), D2 (company address), D3 (CR and licence numbers at signup) and D5 (Agent workspace).

## 2. Status matrix

Status vocabulary (as requested): IMPLEMENTED AND VERIFIED, IMPLEMENTED NOT VERIFIED, PARTIAL, PLACEHOLDER / DEMO, MISSING, BLOCKED BY CONTRACT, SOURCE DECISION NEEDED.

How "verified" is used here: the screen **rendered correctly in today's browser walk or in a passing widget test, and its logic is covered by a passing test or is trivially visible in the walk**. A screen with a known gap against the source is PARTIAL even if it renders. Where several statuses apply, the primary one is shown and the rest are in the notes. Every screen's data comes from the demo backend; that is a separate fact (column "Backend" in section 3), not folded into these statuses.

### 2.1 Shared screens

| ID | Screen | Route | Class and file | Status | Evidence / gap |
|---|---|---|---|---|---|
| C1 | Entry / Welcome | `/entry` | `OnboardingEntryScreen`, `lib/features/entry/screens/onboarding_entry_screen.dart` | PARTIAL | Create account and Login work. **Google and Apple buttons do nothing real**: `signInWithProvider` returns `AuthUnavailable` in both demo and real repositories; a snackbar says it is not connected (BLOCKED BY CONTRACT). No widget test. |
| C2 | Purpose selection | `/onboarding/purpose` | `PurposeSelectionScreen`, `purpose_selection_screen.dart`; options `lib/features/entry/models/signup_purpose.dart` | IMPLEMENTED AND VERIFIED | `onboarding_experience_test.dart`: Continue disabled until a role is chosen; no clipping at 375 and 430 wide at 2.0x text; `flow_logic_test.dart`: exactly six options. Choosing a role then `context.push(option.route)`. |
| C3 | Phone verification (OTP) | `/otp` | `OtpScreen`, `lib/features/flow/screens/otp_screens.dart`; state `lib/features/flow/state/otp_state.dart` | IMPLEMENTED AND VERIFIED | `flow_logic_test.dart` (wrong code, right code, resend obeys server cooldown); `onboarding_experience_test.dart` (change number resets and requests a new code; fits at 2.0x with "Wrong number?"); reached and passed with the demo code in today's walk for all six paths. Real SMS is BLOCKED BY CONTRACT. |
| C4 | Account active | `/account/active` | `AccountActiveScreen`, `otp_screens.dart` | IMPLEMENTED AND VERIFIED | Fits at 2.0x (test); seen today for all six paths. Buyer copy: "You can now browse, search and book on AQARATI." Business copy: "This is not yet an approved business role: add your documents so we can verify it." |
| B1 | Verification intro | `/onboarding/verification-intro` | `VerificationIntroScreen`, `verification_onboarding_screens.dart` | IMPLEMENTED AND VERIFIED | Walked today on all five business paths; lists that role's own documents. No widget test. |
| B2 | Document upload | `/onboarding/documents` | `DocumentOnboardingScreen` + `DocumentUploadTile`, `verification_onboarding_screens.dart`, `lib/features/flow/widgets/document_upload_tile.dart`; state `document_state.dart` | see section 2.2 | `document_controller_test.dart` (4) and `flow_logic_test.dart` (file signature, isolated failure) pass. Walked today. Per-role status differs. |
| B3 | Application review | `/onboarding/review` | `ApplicationReviewScreen` | IMPLEMENTED, NOT VERIFIED | Needs documents received; no widget test; not reached today. |
| B4 | Application submitted | `/onboarding/submitted` | `ApplicationSubmittedScreen` | IMPLEMENTED, NOT VERIFIED | Says "submitted for verification", never "approved". Reference number `AQ-...` is generated in the demo, not by a server. |
| B5 | Verification status | `/verification` | `VerificationStatusScreen`, `verification_status_screens.dart` | PARTIAL | All six grant states are drawn; none is widget-tested. Gaps: **rejected has no next action** (architecture: re-apply allowed 30 days after rejection); **suspended has no support route**. |
| B6 | Application details | `/verification/details` | `ApplicationDetailsScreen` | IMPLEMENTED, NOT VERIFIED | |
| B7 | Replace documents | `/verification/resubmit` | `ResubmissionScreen` | IMPLEMENTED, NOT VERIFIED | Logic test passes: targets are rejected, expired and missing documents. Screen not rendered in any test. |
| B8 | Review changes | `/verification/resubmit/review` | `ResubmitReviewScreen` | IMPLEMENTED, NOT VERIFIED | Logic test passes: only truly accepted documents are "Already approved". |
| B9 | Resubmitted | `/verification/resubmitted` | `ResubmittedScreen` | IMPLEMENTED, NOT VERIFIED | |
| B10 | Approved | `/verification/approved` | `ApprovedScreen`, `approval_screens.dart` | IMPLEMENTED, NOT VERIFIED | Self-guards: redirects to `/verification` unless the server grant is approved. Reachable only via the demo simulator. |
| B11 | Verified summary | `/verification/summary` | `VerifiedSummaryScreen` | IMPLEMENTED, NOT VERIFIED | |
| B12 | Workspace activation | `/workspace/activation` | `WorkspaceActivationScreen` | per path | Lists `workspaceCaps(purpose)`. CTA goes to `/app/account/workspace` for the four business types, to `/app/home` otherwise. |
| B13 | Role destination | `/app/home`, `/app/account/workspace` | `HomeTab` / `AccountTab` in `lib/features/workspace/aq_app_shell.dart`; workspace in `lib/features/devbuild/*` | per path | The workspace is the Development & Building module (screens #59 to #86). |

Side screens (not counted in the path totals):

| ID | Screen | Route | Status | Notes |
|---|---|---|---|---|
| E1 | Email verification | `/verify-email` (`EmailVerificationScreen`) | IMPLEMENTED, NOT VERIFIED | Reached from the account-active screen ("Verify your email"). Never blocks the journey. Only the email-mask helper is tested. |
| L1, L2 | Terms of Use, Privacy Policy | `/legal/terms`, `/legal/privacy` (`LegalScreen`) | PLACEHOLDER / DEMO | A shell. The legal text must be supplied by AQARATI; none is invented. Opened with `push` over the form so nothing is lost. |
| A1 to A3 | Login, Forgot password, Reset password | `/login`, `/forgot-password`, `/reset-password?oobCode=` | IMPLEMENTED, NOT VERIFIED | Reached from the entry and from the signup conflict card. They are not signup paths; listed because the conflict recovery links to them. |

### 2.2 Per-path counts

Each path's list is: C1, C2, its signup steps, C3, C4, B1 to B13. Statuses use the abbreviations V = IMPLEMENTED AND VERIFIED, P = PARTIAL, N = IMPLEMENTED, NOT VERIFIED, M = MISSING.

| Path | Screens | V | P | N | M | Screens that are PARTIAL or MISSING, and why |
|---|---|---|---|---|---|---|
| 1. User to Shop | 8 | 7 | 1 | 0 | 0 | C1 Entry (social buttons). Steps: You, Contact, Account. Destination = buyer home (V: rendered today, `home_smoke_test`). |
| 2. Real Estate Agent | 21 | 9 | 3 | 8 | 1 | C1; B5 Status; B12 Activation (promises three agent capabilities that do not exist); **B13 Agent workspace and role switcher: MISSING**. Signup has 4 steps (You, Contact, Agency, Account), all V. Documents V. |
| 3. Construction Company | 21 | 8 | 4 | 9 | 0 | C1; business step (no address, no company email); B2 Documents (municipal licence expiry not tracked); B5. Workspace V (browser walk and tests in earlier sessions). |
| 4. Property Development | 21 | 8 | 4 | 9 | 0 | C1; business step (same gaps); B2 Documents (Activity licence(s) is one upload slot, the architecture says plural); B5 (the four-eyes "awaiting second approval" state is drawn but not rendered in any signup test). Workspace V. |
| 5. Building Architecture | 21 | 7 | 4 | 10 | 0 | C1; business step (**address is stated as required**); B2 (municipal licence expiry); B5. Workspace is N: the architecture type shares the professional code path but was never opened in a test or browser walk. |
| 6. Interior & Exterior | 21 | 8 | 4 | 9 | 0 | C1; business step (service type present; address missing); B2; B5. Workspace V (widget test builds it at three text scales). The chosen service type is **not carried into the demo workspace profile** (demo-only). |

Totals counted from the rows above: V 47, P 20, N 45, M 1 over 113 screen entries, where C1 to C4 and B1 to B11 repeat in every path.

## 3. Detailed journey and screen inventory

### 3.1 Common mechanics (apply to every path)

- **Routes.** `signupPurposeOptions` (`signup_purpose.dart`) defines the six routes, and `app_router.dart` lines 44 to 45 register one `GoRoute` for each: `/signup/user`, `/signup/agent`, `/signup/construction`, `/signup/development`, `/signup/architecture`, `/signup/interior-exterior`. Each builds `SignupFormScreen(purpose: ...)`.
- **Order after signup.** `/otp` then `/account/active`. Buyer: "Go to home" to `/app/home`. Business: "Add documents" to `/onboarding/verification-intro` then `/onboarding/documents` then `/onboarding/review` then `/onboarding/submitted` then `/verification`.
- **Progress rail** (`lib/features/flow/widgets/journey.dart`). Stage count is the real length of each journey: User 3 (Account, Phone, Ready); Agent, Construction, Architecture, Interior & Exterior 4 (Your details, Agency or Business or Practice, Documents, Review); Development 5 (adds Verification). Test `journey (contextual progress)` checks this. The rail label reads `<Role> · <Stage>`.
- **Form steps** (`signup_state.dart`, `stepsFor`): `you`, `contact`, optional `business`, `account`. User has 3 steps; every other path 4.
- **Draft.** `SignupDraftStore` saves ordinary fields and the step index to local storage on every change (`signupDraft.<purpose>`); never passwords or documents (test `draft JSON never contains passwords or documents`). Email and phone are stored in plain text on the device. The draft is cleared after a successful `signUp`. Back moves one step, then leaves to `/onboarding/purpose`. **Observation, not tested:** after a successful signup, going Back from `/otp` returns to an empty signup form (the draft was cleared) while the account already exists; re-submitting would hit the conflict card with real Firebase.
- **Submit.** `SignupController.submit`: validate the account step, `authRepositoryProvider.createUserWithEmail(email, password)`, then `accountApiProvider.signUp(purpose, values)`, clear the draft, go to `/otp`. Errors map to a banner: conflict (with a recovery card: Sign in, Forgot password, Use another email), validation, network, unavailable, generic. The form values are kept on failure. Double submit: `AQPrimaryButton(loading: true)` ignores taps (test `primary button: loading blocks taps`); the controller itself has no in-flight guard.
- **Validation** (`validateStep`): first name and last name required (`common.required`); phone `^[79]\d{7}$` after removing spaces (`err.phone`); email `^[^\s@]+@[^\s@]+\.[^\s@]{2,}$` (`err.email`); business name or agency name required where configured; service type required for Interior & Exterior; password at least 8 characters, one uppercase, one digit, no special character needed (`err.passwordRules`); confirm must match (`err.passwordMismatch`); consent required (`err.consent`).
- **Documents** (`document_state.dart`): PDF, JPG or PNG checked by file signature, maximum 10 MB checked before the file is read, one independent controller per document (progress, processing, success, failed, retry reusing the in-memory buffer, replace, rejected). A tracked document needs an expiry date chosen before the file picker opens (`document_upload_tile.dart`, `_start`). The expiry date picker allows today up to 20 years ahead.
- **OTP** (`otp_state.dart`): auto-sends on open; 6 digits; server-seeded resend cooldown; expiry countdown; states notSent, sending, sent, verifying, verified, invalid, expired, rateLimited, error; "Wrong number?" sheet to change the number; success then automatic continuation (1.1 s, 0.3 s with reduced motion). The demo uses a 30 s cooldown, 3 sends per 15 minutes, 5 wrong attempts, 15 minute expiry.
- **Guards and session.** `app_router.dart` has `initialLocation: '/entry'` and **no `redirect`**; `lib/main.dart` does not call `getMe` at launch. A signed-in user is shown the entry again; `/verification`, `/onboarding/*` and `/app/*` open by URL without a session and fail only through `meProvider` errors.
- **Backend column.** For every screen below: DEMO. `accountApiProvider` defaults to `UnavailableAccountApi` (every call throws a network error) and is overridden by `DemoAccountApi` only while `kUseDemoBackend` is true.

### 3.2 Path 1: User to Shop

Entry point: `/onboarding/purpose`, tile "User to Shop" (icon `home`, tagline "Find your place in Oman.").

| # | Screen | Fields and actions | Required | Validation / states | Source rule | Result |
|---|---|---|---|---|---|---|
| 1 | Form step 1, "Let's start with you." (`signup.q.you`) | First name; Last name | both | "This field is required." per field | §19.2 | OK |
| 2 | Form step 2, "Where can we reach you?" | Email; Mobile number (fixed +968, hint `9X XXX XXX`) | both | `err.email`; `err.phone` | §19.2 (Username is the email) | OK. Phone rule is stricter than the spec (section 7.3). |
| 3 | Form step 3, "Secure your account." | Password; Confirm password; live requirement list; consent row with Terms and Privacy links; note "No documents are needed to sign up." | all | policy; mismatch; consent; submitting state; conflict card | §44, §19.2 | OK |
| 4 | `/otp` | 6-digit code; Resend; Wrong number? | code | see 3.1 | §44 | OK (demo) |
| 5 | `/account/active` | "Your account is active"; Go to home; Verify your email | | | §19.2: buyer role active after OTP | OK |
| 6 | `/app/home` | Buyer home | | | §19.2 | OK |

Documents: none, correct. Grant: none (`grant` stays null, `routeForSession` goes to `/app/home`). No business wording or verification prompt appears anywhere on this path (checked in `roleConfigs` and in the walk).

### 3.3 Path 2: Real Estate Agent

Entry: tile "Real Estate Agent" (icon `agent`, tagline "Build trust around every property you represent."). Rail: Your details, Agency, Documents, Review.

| # | Screen | Fields | Result against source (§19.3) |
|---|---|---|---|
| 1 to 2 | You, Contact | as path 1 | OK |
| 3 | "Tell us about your agency." | **Agency / brokerage name** (required) + info banner "You will upload your documents after your phone is verified." | OK (§19.3 lists agency / brokerage name). The architecture's API sketch has no licence-number field for agents; none is collected. |
| 4 | Account | as path 1 | OK |
| 5 | OTP, Account active | business copy | OK |
| 6 | Verification intro | why, what we check, **required documents: Photo ID, Agent licence, Supporting document**, what happens next | OK |
| 7 | Documents | Photo ID (required); **Agent licence (required, expiry date required before upload)**; Supporting document (required) | OK. Matches §49.3 including expiry on the agent licence (`DocumentKind.tracksExpiry`). Verified in the walk. |
| 8 | Review, Submitted, Status, Details, Resubmission (3 screens), Approved, Summary | generic | present, not verified today |
| 9 | Workspace activation | caps list `ws.cap.agent.1..3` | **PARTIAL: lists "Switch between Buyer and Agent", "Create and manage listings", "Manage viewing availability". None exists.** CTA goes to `/app/home`. |
| 10 | Agent workspace + RoleSwitcher | | **MISSING.** §19.3: before approval "buyer home + banner", after approval "RoleSwitcher Agent <-> Buyer", "Agent workspace: create and manage own listings and viewings". The app shows a verification card on the buyer home (`_sessionSections` in `aq_app_shell.dart`) and the account page has no workspace button for agents (`proTypeOfPurpose` is null for the agent). |

Other agent facts: licence expiry reminders at 30 and 7 days and grant to resubmission on expiry (§19.3, §48) are server behaviours; the client computes `expiringSoon` at 30 days and shows `Expired · replace` (`expiryStatusOf`). Notifications are not built.

### 3.4 Path 3: Construction Company

Entry: tile "Construction Company" (icon `construction`, tagline "Put your company where Oman builds."). Rail: Your details, Business, Documents, Review.

| # | Screen | Fields | Result against source (§19.5) |
|---|---|---|---|
| 1 to 2 | You, Contact | first and last name; email; mobile | Matches "Contact First Name, Last Name, Phone, Email". |
| 3 | "Tell us about your company." | **Business name** only | **PARTIAL.** §19.5 also lists **Company Physical Address** and **Username (company email)**; neither exists. The API sketch (§30.1) includes `organization{name, address, cr_number, licence_number}`. |
| 4 | Account | as path 1 | OK |
| 5 | Documents | **CR certificate (required, expiry)**, **Municipal licence (required, no expiry field)** | **PARTIAL.** Document set is exactly right and **no Activity Licence is required** (confirmed decision, §19.5; test asserts it). §49.3 lists expiry tracked for "Licences, CR, activity"; the app tracks CR only. Confirmed in the walk: the municipal licence tile has no "Set expiry date". |
| 6 | Verification chain | generic | as path 2 |
| 7 | Activation and workspace | caps `ws.cap.pro.*` | OK. Workspace: dashboard, company profile, contact activity, reviews, engagements, portfolio, no project wizard. Verified in browser (role "construction") and tests in earlier sessions. |

### 3.5 Path 4: Property Development Company

Entry: tile "Property Development Company" (icon `development`, tagline "Bring your developments into a trusted property ecosystem."). Rail has 5 stages; the extra one is Verification (four-eyes).

| # | Screen | Fields | Result against source (§19.6) |
|---|---|---|---|
| 1 to 2 | You, Contact | as path 3 | |
| 3 | Business | Business name only | **PARTIAL** (address and company email, as path 3). §19.6 says logo and project details come after approval, which is how the app works (project wizard in the workspace). |
| 4 | Account | | OK |
| 5 | Intro | adds the line "Development companies go through a two-step review: a reviewer first, then a senior reviewer." | OK |
| 6 | Documents | **Official corporate registration (required, expiry)**, **CR certificate (required, expiry)**, **Activity licence(s) (required, single slot)**, **Developer licence (required, expiry)** | **PARTIAL.** Four documents match §49.3. "Activity Licence(s)" is plural in the source and one upload tile in the app. The app also tracks expiry on the official corporate registration; §49.3 lists "Developer Licence, CR". |
| 7 | Status | states: under review, **awaiting second approval** (only when `cfg.fourEyes`), approved, resubmission, rejected, suspended | The four-eyes state is distinct (`ReviewStage.awaitingSecondApproval`, timeline adds "Awaiting second approval"). Drawn in code; **not rendered in any signup test** (only the workspace gate is tested in `devbuild_*_test.dart`). |
| 8 | Workspace | full D&B module including the five-step project wizard | V (browser walk, 225-test suite as of 2026-10-12). |

### 3.6 Path 5: Building Architecture

Entry: tile "Building Architecture" (icon `architecture`, tagline "Let your practice be discovered."). Rail: Your details, Practice, Documents, Review. Business step copy: "Tell us about your practice."

Same shape as path 3. §19.7 states **Company Physical Address (required)**; the app has none, so the business step is PARTIAL. Documents: CR certificate (expiry), Municipal licence (no expiry), PARTIAL as path 3. Workspace type `architecture`: shares the professional code path; **not opened in any test or browser walk** (N).

### 3.7 Path 6: Interior & Exterior Design

Entry: tile "Interior & Exterior Design" (icon `interior`, tagline "Show the work behind the spaces."). Rail: Your details, Practice, Documents, Review.

| # | Screen | Fields | Result against source (§19.8) |
|---|---|---|---|
| 3 | "Tell us about your practice." | Business name; **Service type: Interior / Exterior / Both** (required segmented control) | Service type is correct and distinct (separate enum `InteriorExteriorServiceType`, separate purpose, separate route; not merged with architecture). **PARTIAL** because the required Company Physical Address and company email are missing. Confirmed in the walk. |
| 5 | Documents | CR certificate (expiry), Municipal licence (no expiry) | PARTIAL as path 3 |
| 7 | Workspace | professional workspace; filters by service type exist in discovery | V by widget test. **Demo limitation:** `DemoAccountApi.signUp` and `DemoBackendState` do not store the service type, and `myProfessional` in `db_repository.dart` builds the profile without it, so the choice made at signup does not appear in the demo workspace profile. A real API receives `service_type`. |

## 4. Implementation references

| Concern | File | Symbol |
|---|---|---|
| Six options, routes, taglines | `lib/features/entry/models/signup_purpose.dart` | `SignupPurpose`, `signupPurposeOptions` |
| Role configuration (fields, documents, four-eyes) | `lib/core/domain/account_models.dart:52` | `roleConfigs`, `RoleFormConfig`, `DocumentKind.tracksExpiry` (line 25) |
| Form | `lib/features/flow/screens/signup_form_screen.dart` | `SignupFormScreen` |
| Validation, draft, submit | `lib/features/flow/state/signup_state.dart` | `validateStep`, `SignupDraftStore`, `SignupController` |
| OTP | `lib/features/flow/screens/otp_screens.dart`, `state/otp_state.dart` | `OtpScreen`, `OtpController`, `AccountActiveScreen` |
| Documents | `state/document_state.dart`, `widgets/document_upload_tile.dart`, `widgets/document_preview.dart` | `DocumentController`, `DocumentUploadTile` |
| Verification screens | `screens/verification_onboarding_screens.dart`, `screens/verification_status_screens.dart`, `screens/approval_screens.dart` | see 2.1 |
| Progress rail | `widgets/journey.dart` | `journeyStages`, `journeyProgress` |
| API contract (client view) | `lib/data/api/account_api.dart` | `AccountApi`, `UnavailableAccountApi` |
| Demo backend | `lib/data/demo/demo_backend.dart`, `lib/core/config/backend_mode.dart` | `DemoAccountApi`, `kUseDemoBackend` |
| Routing | `lib/core/router/app_router.dart` | routes lines 37 to 60 |
| Copy (English and draft Arabic) | `lib/core/localization/flow_strings.dart`, `entry_strings.dart` | |
| Post-approval destinations | `lib/features/workspace/aq_app_shell.dart`, `lib/features/devbuild/db_routes.dart`, `db_models.dart` (`proTypeOfPurpose`) | |

## 5. Test evidence and gaps

### 5.1 Run today

`flutter test test/flow_logic_test.dart test/onboarding_experience_test.dart test/document_controller_test.dart test/aq_components_test.dart test/intro_preferences_test.dart` finished with exit code 0: **45 tests passed**.

| Test | What it actually verifies |
|---|---|
| `flow_logic_test`: six paths with role configs | `signupPurposeOptions.length == 6`, each has a config |
| `flow_logic_test`: required documents follow the source | User none; Agent three documents; Construction, Architecture and Interior & Exterior CR + municipal only; no Activity Licence for construction; Development four-eyes; Interior & Exterior has the service type; agent licence tracks expiry |
| `flow_logic_test`: step validation, password policy, draft JSON, file signature | pure functions |
| `flow_logic_test`: OTP, business account stays draft, isolated upload failure, login routing, expiry status | state machines against the demo API |
| `onboarding_experience_test`: journey length and stage mapping, every stage label has English and Arabic, document status mapping, resubmission targets and grouping, workspace caps, OTP change number, email mask, routes exist, reduced motion, purpose screen, document tile, signup steps (agent, user) at 1.5x and 2.0x on 360 x 640, OTP and account-active at 2.0x | mix of logic and widget builds |
| `document_controller_test` | happy path keeps no bytes in state; retry without re-pick; wrong type and oversize rejected before upload; cancel restores the phase |
| `aq_components_test` | primary button loading blocks taps; text field error; OTP field completes at six digits; segmented control |

### 5.2 Not covered by any test

- Completing a signup form, submitting, and arriving at `/otp` (no widget or integration test does this).
- Rendering of `ApplicationReviewScreen`, `ApplicationSubmittedScreen`, `VerificationStatusScreen` (any state), `ApplicationDetailsScreen`, `ResubmissionScreen`, `ResubmitReviewScreen`, `ResubmittedScreen`, `ApprovedScreen`, `VerifiedSummaryScreen`, `WorkspaceActivationScreen`, `OnboardingEntryScreen`, `EmailVerificationScreen`.
- Signup in dark theme, in Arabic/RTL, or on the five company paths.
- The four-eyes status rendering.
- Anything against a real backend.

### 5.3 Walk evidence (today)

Chromium, 393 x 852, light, English, release web build, demo backend. For each of the six paths: step screens, account step with a valid password and consent, `Create account`, OTP (demo code), account-active. For the five business paths: verification intro and the document list at the top of the page. Observed and consistent with section 3. Not observed: review, submit, status, resubmission, approval (not reachable in a default build, see section 0).

## 6. Existing image and asset inventory

### 6.1 `Desktop/Phone Images Aqariti` (24 files; some are byte-identical duplicates)

All are **light-mode, English, mocha/brown** with a warm Omani photographic background. None is dark mode or Arabic. Most are **composite sheets of 10 to 12 phone frames**, not one screen per file. All carry the logo at the top, so the logo is generated art, not the approved master SVG; **do not reuse those logo renders.**

| File | Depicts | Class | Matches current app and authoritative rules? |
|---|---|---|---|
| `AqArati Oman Property Welcome Screen.png` (853 x 1844) | Entry: logo, headline, Create account, Login, Google and Apple, language. Shows a four-dot pager and "Skip". | screen reference | **Differs**: the app has no pager and no Skip (removed on purpose). Otherwise the app was built from it. |
| `AQARATI Premium Property Onboarding.png` (853 x 1844) | "What brings you to AQARATI?" with **Find a Property, Find Professionals, Home Maintenance, List a Property, Join as a Professional, Other**; `1/3`, "Skip". | screen reference, **outdated** | **Contradicts**: the six real paths are User to Shop, Real Estate Agent, Construction, Property Development, Building Architecture, Interior & Exterior. The user's own screenshot of the current app (six cards) matches the code. Needs a new image. |
| `Oman-Inspired Account Creation Screen.png` (853 x 1844) | User signup: first and last name, phone with flag, email, password, terms checkbox, `02/03`, "Skip". Password hint "letters, numbers and symbols". | screen reference | **Differs**: one screen with everything (the app uses 3 steps), no Confirm password, "Skip", and a symbol rule that contradicts the confirmed policy. |
| `Aqarati Account Success in Oman.png` (853 x 1844) | "Account Created Successfully / Phone Verified", `03/03`, "Continue to Explore". | screen reference | Buyer only. No business variant ("active, not yet an approved business role"). |
| `AQARATI Agent Signup Journey.png` (+ `(1)` duplicate, 1024 x 1536) | Agent: intro, personal details with **password on the same screen**, "Agent Business Details" with **RERA licence number, agency email, agency phone, years of experience, areas of operation, specialisation**, "Areas & Specialization" photo grids, **documents: RERA licence, Civil ID / Passport, Agency Trade Licence, optional profile photo**, review and submit. | journey sheet | **Contradicts the architecture** (§19.3, §49.3): required documents are Photo ID, Agent licence (with expiry), supporting document. RERA, trade licence, years, areas, specialisation, agency email and phone are in no source section. |
| `AQARATI Construction Signup Flow.png` (+ dup) | Construction: intro, company info (CR number, registration date, company type, size), contact (representative, **position**, alternate phone, website), business details (years, areas, services), documents (CR, municipal, **optional company profile**), review, submitted, under review, verified. | journey sheet | **Contradicts the fields**: invented company type, size, registration date, position, alternate phone, website, services. Document set (CR + municipal) is correct. Has no company address. |
| `AQARATI Property Development Signup Flow.png` | Developer: company info (trading name, company type, size, year established, **head office location**), **official registration details (CR number, issue and expiry date, registered address, legal entity type)**, business details (focus, ongoing / completed projects, website), four documents + optional (profile, portfolio, financials), review, submitted, under review. | journey sheet | Four required documents match. **Many fields are not in the architecture.** It is the only sheet showing a registered address. No "awaiting second approval" frame. |
| `AQARATI Architecture Signup Journey.png` | Architecture, same shape as construction, plus specialisations. | journey sheet | As construction. Skip button. |
| `Aqarati Design Firm Signup Flow.png` | Interior & Exterior: as architecture; "Services & Specializations" instead of a **service type of Interior / Exterior / Both**. | journey sheet | **Contradicts §19.8**: the required service type control (Interior / Exterior / Both) does not appear. |
| `AQARATI OTP Verification Flow UI.png` (+ dup) | 12 OTP states: start, sent, entering, incorrect, resend, too many attempts, success, expired, trouble, rate limit, auto-continue, "Welcome" next step. | state sheet | Good reference for the state set. Differs: lockout "15 minutes", "5 OTP requests per hour", "Contact Support", and a "Complete Profile" step are not in the architecture or the app. Architecture rules (§44 and the rate-limit table): 60 s cooldown per phone, 3 sends per 15 minutes, 10 per day, 5 wrong attempts, 15 minute validity. |
| `AQARATI Business Verification Flow.png` (+ dup) | Why we verify, what we verify, required documents, file guidelines, upload, review, submitting, submitted, data secure. | state sheet | Matches the construction document set. Shows "Authorized Representative" and "Business Information" items and "Additional documents may be required" that the model does not have. Not role-specific. |
| `AQARATI Verification Pending App Flow.png` (+ dup) | Submitted, status, submitted documents, application details, process, notifications, "We're reviewing", what happens next, "Additional information required (7 days)", "Almost there". | state sheet | Partly matches. "7 days to respond", notifications list, "Contact Support" and "Estimated completion" have no source. |
| `AQARATI Resubmission Flow UI Mockup.png` | Resubmission required, feedback, document details (needs update, expired), upload new document, updated, review changes, resubmitted, status timeline. | state sheet | Good fit for the rejected / expired document flow. Shows "Business Information" and "Authorized Representative" sections as approved, which the model does not have. |
| `AQARATI Verified Workspace UI Collage.png` | "You're Verified", summary, verified documents, workspace ready, dashboard, create listing, inquiries, public profile preview. | collage | **Green** CTAs and bottom bar (off-brand), invented dashboard counts, Listings / Inquiries / Insights / Portfolio, and a five-item bottom bar. Do not use. The correct handoff is the Development & Building workspace (screens #59 to #86). |
| `AQARATI Reset Password Screen.png`, `Luxury Real Estate Password Reset UI.png`, `Aqārati Luxury Login in Oman.png`, `Luxury Property OTP Verification.png`, `Contemporary_residence_with_arch…_2K_20261007021313.jpg` | login, reset password, OTP, photograph | screen / photo | Not opened one by one (names and sizes only). The photograph is a backdrop, not a UI reference. |

### 6.2 `Desktop/figma aqarati` (895 PDFs, one per frame)

Old design: red accent and button, a serif display face (earlier project notes call it Cormorant; not checked), a "one special character" password rule, and a "Full name / Email or phone" signup. Opened to classify: `create-account.pdf`, `25.13-owner-verification.pdf`, `44.29-onboarding-welcome.pdf`. **Superseded legacy references. Do not use for signup.** Notable names: `create-account*`, `otp*`, `sign-in*`, `identity-verification`, `26.xx` verification hub frames, `44.29` to `44.32` onboarding, `50.05-business-verification`. None depicts the six role paths.

### 6.3 Other

- `Desktop/Final Figma Aqarati`: brand and design-system PDFs (logo master, clear space, typography S06/S07, colour S08/S09, spacing, radius, elevation, iconography, "AQARATI — INFORMATION ARCHITECTURE & NAVIGATION.pdf", numbered frame folders 01 to 24). Brand source. **Not opened in this audit**, apart from confirming the file names; token values below come from the code, not from these PDFs.
- `Desktop/aqarati onboaring image`: 47 stock photographs (villas, interiors, Muscat). Backdrops only, no UI.
- `docs/development_building/REFERENCE_IMAGE_INDEX.md`: 45 images for the Development & Building module (screens #59 to #86). **They do not cover signup or onboarding.**
- `assets/entry/oman_terrace_2k.jpg` is the backdrop the AQ auth scaffold uses; `assets/logo/aqarati_master.svg` is the master logo the app draws; `assets/icons/aq/*.svg` is the 42-icon set (agent, construction, development, architecture, interior, home, check, lock, shield, verified, info, plus others).

## 7. Mismatches and source conflicts

### 7.1 Architecture versus implementation

| # | Architecture says (v2.6) | App does | Classification |
|---|---|---|---|
| 1 | Paths 3 to 6: **Company Physical Address** (§19.5 to §19.8; "required" for Architecture and Interior & Exterior) | No address field anywhere in signup | **SOURCE DECISION NEEDED** (D2) and PARTIAL |
| 2 | Paths 3 to 6: contact **Email** *and* **Username (company email)** | One email, used as the Firebase username | SOURCE DECISION NEEDED (D1) |
| 3 | `POST /auth/sign-up`: `consent{terms_version, privacy_version}`, `locale`, `organization{name, address, cr_number, licence_number}`, `service_type`. "Exact field list per role TO BE FINALIZED" | Consent is a boolean; no locale; no CR or licence number; business name only | BLOCKED BY CONTRACT (D3, D7) |
| 4 | §49.3 expiry tracked: construction "Licences, CR, activity"; architecture and interior "Licence, CR" | Tracked: agent licence, CR, official corporate registration, developer licence. **Municipal and activity licences are not tracked** | PARTIAL (D4) |
| 5 | Developer: "Activity Licence(s)" | One upload slot | PARTIAL (D8) |
| 6 | Agent: RoleSwitcher Agent <-> Buyer; agent workspace | Not built; handoff screen promises it | MISSING (D5) |
| 7 | Phone: "+968 + 8 digits" | Requires the 8 digits to start with 7 or 9, and the error text only says "Enter an 8-digit Oman mobile number." | App stricter than source, and the message does not explain the rule (D6) |
| 8 | 12 reason codes (§50.2, closed list: `DOC_UNREADABLE`, `DOC_WRONG_TYPE`, `NAME_MISMATCH`, `EXPIRED`, `NOT_ON_REGISTRY`, `LICENCE_CATEGORY_MISMATCH`, `OWNER_MISMATCH`, `DUPLICATE_LISTING`, `PHOTOS_MISMATCH`, `CALL_FAILED`, `INCOMPLETE_SUBMISSION`, `OTHER`) | Strings exist for `DOC_UNREADABLE`, `DOC_EXPIRED`, `DOC_MISMATCH`, unknown. `DOC_EXPIRED` and `DOC_MISMATCH` are **not** codes in the architecture | MISMATCH (D9) |
| 9 | Re-application allowed 30 days after rejection | Rejected state has no action | MISSING (D10) |
| 10 | Password policy includes a 10,000-entry blocklist in clients | Not implemented (no blocklist in `lib`) | MISSING |
| 11 | `users` roles: buyer after OTP, seller after approval | Modelled as `AccountState` and `GrantState` | consistent |
| 12 | Four-eyes for developers only | `ReviewStage.awaitingSecondApproval` gated by `cfg.fourEyes` | consistent |
| 13 | Construction: no separate Activity Licence | Not required, with a code comment and a test | consistent |
| 14 | Service type Interior / Exterior / Both on path 6 only | Present, distinct | consistent |

### 7.2 Decisions needed before the image briefs can be final

| ID | Question | Why it blocks |
|---|---|---|
| D1 | Are the contact email and the company login email the same field or two? | Changes the contact step and the account step on paths 3 to 6. |
| D2 | Company physical address: free text, or governorate / wilayat / area, or map pin; collected at signup or in the profile? Required on all four company paths or only on 5 and 6? | The company business-step image cannot be drawn without it. The workspace already has a location step (#73) with governorate, wilayat and area. |
| D3 | Are CR number and licence number typed at signup, or read by the reviewer from the uploaded documents? | Same screen. |
| D4 | Does the municipal licence carry an expiry date, as §49.3 implies? | Changes the construction, architecture and interior document tiles. |
| D5 | Is the Agent workspace and role switcher in scope now? | Without a decision, the agent activation and destination screens cannot be specified. |
| D6 | Phone rule: any 8 digits, or only those starting 7 or 9? | Error copy and examples. |
| D7 | Consent: are terms and privacy versions shown or only recorded? | Legal text and versions come from AQARATI. |
| D8 | Several activity licences: multiple files per document? | Developer documents tile. |
| D9 | Reason-code list and the user-facing text per code | Rejected and resubmission screens. |
| D10 | Re-apply after 30 days: where does it appear? | Rejected state. |
| D11 | Which architecture version is current? The task says v2.4; the repository holds v2.6. | Whole audit. |
| D12 | Native Arabic review of the draft Arabic copy | Arabic images. |
| D13 | Should the extra fields shown in the existing journey sheets (RERA number, years, areas, company type and size, and so on) be dropped? The architecture does not include them. | Do not carry them into new images unless a source adds them. |

### 7.3 Conflicts between references

- Purpose screen: image shows six other purposes; the code and the architecture show the six roles.
- Password hint: image says symbols; confirmed policy has no symbol rule; old Figma PDFs say "one special character".
- Agent documents: image (RERA, Civil ID, Trade Licence) versus architecture (Photo ID, Agent Licence, supporting document).
- Colour: collage uses green; the app and brand use mocha.
- "Contact Support", "Skip", notification lists, 7-day response windows: in images, in no source.

### 7.4 Earlier audit (2026-10-07) versus today

Fixed since then (verified by reading code today): Terms and Privacy links, change-number path, email verification screen, OTP expiry countdown, expired and missing documents as resubmission targets, "Already approved" labelling, entry pager and Skip removal, legacy onboarding route removed, journey rail, role-aware handoff, conflict recovery card.
Still open (verified today): no real Firebase or API (`kUseDemoBackend = true`), no session restore, no route guards, Google and Apple unavailable, no Agent workspace, signup draft stores email and phone in plain text, native Arabic review pending, nothing tested on a device.

## 8. Confirmed versus proposed or blocked

**Confirmed (matches the source and verified):** six paths and routes; one-form architecture; user path end to end to buyer home; agent signup fields and documents; construction, architecture and interior document sets (without expiry rule); developer four documents and four-eyes state model; interior service type Interior / Exterior / Both as a distinct field; password policy; OTP rules the client can express; document upload rules (types by signature, 10 MB, per-file state); authentication versus verification wording (active is not approved).

**Proposed or blocked:**
- BLOCKED BY CONTRACT: real Firebase and API, SMS, social sign-in, consent versions, locale, organization fields, reference numbers from the server, `changePhone` endpoint (frontend assumption, flagged in `account_api.dart`).
- SOURCE DECISION NEEDED: D1 to D13 above.
- PLACEHOLDER / DEMO: legal text, OTP code `123456`, reference number, all verification outcomes (simulator only behind `REVIEW_TOOLS`), service type persistence.
- MISSING: Agent workspace, role switcher, password blocklist, 30-day re-apply, municipal expiry, company address and company email.

## 9. Reference images ChatGPT should generate

Notation: each image is a **light and dark pair**; key screens also get an **Arabic RTL pair**. Format: 393 x 852 phone frames, **one screen or one small family per image**, not 10-frame collages (the existing sheets are hard to implement from). Full field lists and states are in `SIX_SIGNUP_PATHS_IMAGE_BRIEF.md`.

| ID | Image | Paths | Status of dependency |
|---|---|---|---|
| SU-01 | Purpose selection, six roles, selected state, Continue | all | Ready. The current reference is wrong. |
| SU-02 | Form component kit: field default / focus / filled / error / valid, phone field, segmented control, password with live requirements, consent row, conflict card, loading button | all | Ready |
| SU-03 | Steps "About you" and "Where can we reach you?" with rail variants (3, 4 and 5 stages) | all | Ready, except D6 for the phone error copy |
| SU-04 | Step "Secure your account" in two variants (no documents / documents later), plus submitting and conflict states | all | Ready, except D7 |
| SU-05A | Business step, agency / brokerage name | Agent | Ready |
| SU-05B | Business step, company | Construction, Development, Architecture | **Blocked by D1, D2, D3** |
| SU-05C | Business step, company + service type Interior / Exterior / Both | Interior & Exterior | **Blocked by D1, D2, D3** |
| SU-06 | Account active, business variant ("not yet an approved business role"); and Email verification | 5 business paths; all | Ready |
| SU-07A | Documents, agent (photo ID, agent licence with expiry, supporting document) | Agent | Ready |
| SU-07B | Documents, CR + municipal licence (one image with three role labels) | Construction, Architecture, Interior & Exterior | **Blocked by D4** (expiry on the municipal licence) |
| SU-07D | Documents, developer (four documents, four-eyes banner) | Development | **Blocked by D8** |
| SU-08 | Application review, role variants (agent, company, company with service type) | 5 business paths | Ready |
| SU-09 | Status: under review (all), **awaiting second approval** (developer), rejected, suspended | 5 business paths | Rejected and suspended wait on D9 and D10 |
| SU-10 | Resubmission: rejected, expired, missing documents; review changes; resubmitted. Adjust the existing sheet to the document-only model. | 5 business paths | Wait on D9 |
| SU-11 | Approved and verified summary in mocha, per role | 5 business paths | Ready |
| SU-12 | Workspace activation: Professional (construction, architecture, interior), Developer | 4 company paths | Ready. **Agent variant blocked by D5.** |

Do **not** generate: a new Entry image (the app already exists and the one reference differs only by the removed pager), a new OTP sheet (the existing 12-state sheet is a usable reference; add only a "Wrong number?" sheet if wanted), or any Agent workspace image until D5 is decided.

## 10. Recommended generation order

1. SU-01 Purpose selection (fixes the only reference that shows the wrong paths).
2. SU-02 Form kit.
3. SU-03 About you and Contact.
4. SU-04 Account and consent.
5. SU-05A Agent business step.
6. SU-07A Agent documents.
7. SU-06 Account active (business) and email verification.
8. SU-08 Review.
9. SU-09 Status states (under review, awaiting second approval).
10. SU-11 Approved and summary.
11. SU-12 Activation (Professional and Developer).
12. After D1 to D4 and D8 are answered: SU-05B, SU-05C, SU-07B, SU-07D.
13. After D9 and D10: SU-09 rejected and suspended, SU-10 resubmission.
14. After D5: Agent activation and workspace.

## 11. Completion checklist for the implementation that follows

- [ ] Answer D1 to D13 and record the answers in `docs/signup_audit/`.
- [ ] Add the company address (and company email if D1 says so) to `RoleFormConfig`, `SignupFormValues`, the form, validation, drafts and `AccountApi.signUp`.
- [ ] Decide and implement municipal licence expiry (`DocumentKind.tracksExpiry`).
- [ ] Support several activity licences, or document the single-slot decision.
- [ ] Record consent versions; send `locale`.
- [ ] Add the password blocklist (shared with `packages/` in the main repository).
- [ ] Align reason codes with the closed list of 12 in §50.2 and add user-facing text.
- [ ] Add the 30-day re-apply path for rejected applications.
- [ ] Decide the Agent workspace; if yes, build it and remove the three unbuilt promises from `workspaceCaps` until it exists.
- [ ] Persist the Interior & Exterior service type in the demo repository (and confirm the real contract).
- [ ] Route guards and session restore (`redirect`, `getMe` at launch).
- [ ] Replace the demo backend with Firebase and the Aqarati API; turn `kUseDemoBackend` off for any shipped build.
- [ ] Tests: complete a signup to `/otp` for each path; render the review, submitted, status (all six states, including four-eyes), details, resubmission, approved, summary and activation screens; dark theme and Arabic/RTL for the signup steps; 320 and 430 px.
- [ ] Native Arabic review of every string in `flow_strings.dart`.
- [ ] Device QA: iOS and Android, VoiceOver and TalkBack, keyboard, file picker.
