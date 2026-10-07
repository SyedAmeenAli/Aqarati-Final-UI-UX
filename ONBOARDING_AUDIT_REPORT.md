# AQARATI — Onboarding Production Audit Report

Audit only. No code modified. Date 2026-10-07. Commit audited: `a710be4` (main).
Scope: startup film → final onboarding/workspace handoff. Nothing outside it.

## 0. Audit limits (read first)

- **Source 1 (Architecture v2.4) was NOT available to me in this session.** I only had the 100-page *Final Frontend/Backend Master Blueprint* (text extract). Every "architecture" verdict below is against that blueprint. Where v2.4 could differ, marked `[verify v2.4]`.
- Figma file not opened this session. Visual identity checked against the logo PDFs and reference PNG zip supplied earlier. Visual-match claims are judgement from earlier side-by-side review, not a fresh pixel diff.
- **Everything was run on the Flutter WEB build in desktop Chromium (Playwright).** Nothing ran on iOS, Android, simulator or emulator. Haptics, native splash, native file picker, real keyboard, VoiceOver/TalkBack, text scaling, real video decoding performance: **NOT TESTED**.
- Percentages are my estimates from evidence, not measurements.

Evidence run now: `flutter analyze` → 9 info, 0 warning, 0 error. `flutter test` → 22/22 pass. Web release build → OK. Playwright walks at 375×812, 393×852, 430×932.

---

## A. Executive summary

| Metric | Est. |
|---|---|
| Overall onboarding completion (real, incl. integration) | **~55%** |
| Visual completion | 80% |
| Functional completion (against the simulated API contract) | 70% |
| Functional completion (against a real backend) | **0%** — no real integration exists |
| Architecture compliance (vs blueprint) | 70% |
| **Production readiness** | **~20%** |
| iOS interaction quality (web-tested only) | 62% |
| Error-state completeness | 55% |
| Accessibility | 50% (semantics present, never tested with a screen reader) |
| RTL | 85% (web-verified, copy is draft) |
| Dark mode | 80% |
| Responsive | 80% |

**Overall status: PARTIALLY READY** (UI + client state machines are solid; integration layer is absent).
Why: screens, states, copy, tokens, RTL, dark are largely built and consistent. But there is no Firebase SDK, no HTTP client, no real API. The whole journey runs on an in-memory demo (`lib/data/demo/*`) that is **enabled by a hard-coded constant and ships in release builds** (the live Vercel site runs on it). No session restore, no route guards, no role-specific workspace. It cannot ship.

---

## B. Screen inventory

Legend: ✔ yes, ◐ partial, ✘ no. "Func." = works against the demo contract. "Prod." = ready to ship as-is.

| # | Screen / State | Exists | Route | File | Func. | Visual | Arch. | Prod. | Sev | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Startup film | ✔ | overlay | `core/startup/intro_host.dart` | ✔ web | ✔ | ✔ | ◐ | P2 | Web only tested. Native splash gaps (C). |
| 2 | Startup → Entry transition | ✔ | overlay | `intro_host.dart`, `logo_handoff.dart` | ✔ web | ✔ | ✔ | ◐ | P3 | Animated handoff (C). Device untested. |
| 3 | Entry | ✔ | `/entry` | `entry/screens/onboarding_entry_screen.dart` | ◐ | ✔ | ◐ | ✘ | P1 | Google/Apple non-functional; fake 4-dot pager; Skip leaves flow. |
| 4 | Purpose | ✔ | `/onboarding/purpose` | `purpose_selection_screen.dart` | ✔ | ✔ | ✔ | ◐ | P3 | Six exact paths. Tile text clipped at 375/430. |
| 5 | Account creation | ✔ | `/signup/{user,agent,construction,development,architecture,interior-exterior}` | `flow/screens/signup_form_screen.dart` | ✔ demo | ✔ | ✔ | ✘ | P1 | Terms/Privacy not linked. Fake auth underneath. |
| 6 | OTP | ✔ | `/otp` | `otp_screens.dart`, `otp_state.dart` | ✔ demo | ✔ | ◐ | ✘ | P1 | State machine good; see H. |
| 7 | Account success | ✔ | `/account/active` | `otp_screens.dart` `AccountActiveScreen` | ✔ | ✔ | ✔ | ◐ | P3 | Back goes to `/entry`. |
| 8 | Login | ✔ | `/login` | `auth_screens.dart` `LoginScreen` | ✔ demo | ✔ | ◐ | ✘ | P0 | Not Firebase. |
| 9 | Forgot password | ✔ | `/forgot-password` | `auth_screens.dart` | ✔ demo | ✔ | ✔ | ✘ | P0 | Demo only; email-only ✔. |
| 10 | Reset password | ✔ | `/reset-password?oobCode=` | `auth_screens.dart` | ✔ demo | ✔ | ✔ | ✘ | P0 | Keyed by oobCode; demo treats `expired` literal. |
| 11 | User to Shop | ✔ | `/signup/user` | same form, 2 steps | ✔ | ✔ | ✔ | ✘ | P1 | No docs ✔. Active → `/app/home`. |
| 12 | Agent | ✔ | `/signup/agent` | same | ✔ | ✔ | ◐ | ✘ | P1 | See L1. |
| 13 | Construction | ✔ | `/signup/construction` | same | ✔ | ✔ | ✔ | ✘ | P1 | |
| 14 | Development | ✔ | `/signup/development` | same | ✔ | ✔ | ✔ | ✘ | P1 | Four-eyes ✔. |
| 15 | Architecture | ✔ | `/signup/architecture` | same | ✔ | ✔ | ✔ | ✘ | P1 | |
| 16 | Interior & Exterior | ✔ | `/signup/interior-exterior` | same | ✔ | ✔ | ◐ | ✘ | P1 | Extra Interior/Exterior/Both field `[verify v2.4]`. |
| 17 | Verification intro | ✔ | `/onboarding/verification-intro` | `verification_onboarding_screens.dart` | ✔ | ✔ | ✔ | ◐ | P3 | |
| 18 | Document upload | ✔ | `/onboarding/documents` | same + `widgets/document_upload_tile.dart` | ✔ demo | ✔ | ✔ | ✘ | P1 | Upload is simulated. |
| 19 | Document review | ✔ | `/onboarding/review` | same | ✔ | ✔ | ✔ | ◐ | P3 | |
| 20 | Submission | ✔ | `/onboarding/submitted` | same | ✔ | ✔ | ✔ | ◐ | P3 | |
| 21 | Pending verification | ✔ | `/verification` | `verification_status_screens.dart` | ✔ | ✔ | ✔ | ◐ | P2 | No support/help. |
| 22 | Application details | ✔ | `/verification/details` | same | ✔ | ✔ | ◐ | ◐ | P3 | No reviewer note field beyond reason code. |
| 23 | Resubmission required | ✔ | `/verification` (state) + `/verification/resubmit` | same | ◐ | ✔ | ◐ | ✘ | P1 | Only `rejected` docs handled. |
| 24 | Document replacement | ✔ | `/verification/resubmit` | same | ◐ | ✔ | ◐ | ✘ | P1 | |
| 25 | Review changes | ✔ | `/verification/resubmit/review` | same | ◐ | ✔ | ✘ | ✘ | P1 | Mislabels "Already approved". |
| 26 | Resubmission confirmation | ✔ | `/verification/resubmitted` | same | ✔ | ✔ | ✔ | ◐ | P3 | |
| 27 | Approved / Verified | ✔ | `/verification/approved` | `approval_screens.dart` | ✔ | ✔ | ✔ | ◐ | P3 | Self-guards on `grant==approved`. |
| 28 | Verified summary | ✔ | `/verification/summary` | same | ✔ | ✔ | ✔ | ◐ | P3 | |
| 29 | Workspace handoff | ◐ | `/workspace/activation` → `/app/home` | `approval_screens.dart`, `workspace/aq_app_shell.dart` | ◐ | ✔ | ✘ | ✘ | P1 | Generic shell for every role. |

Sub-states present: OTP (notSent, sending, sent, verifying, verified, invalid, expired, rateLimited, error), documents (idle, selecting, uploading, processing, success, failed, retrying, rejected), grants (draft, pending, approved, resubmission, rejected, suspended), review stage (underReview, awaitingSecondApproval).

---

## C. Startup experience

**Native splash**
- Android: `res/drawable/launch_background.xml` = solid `#EDE1D4`, no logo. `values-night/styles.xml` LaunchTheme parent `Theme.Black` but window background is the same ivory drawable. **No `values-v31` / `windowSplashScreen*` resources** → Android 12+ ignores `windowBackground` and shows the system splash (app icon on default colour). Severity P2. NOT TESTED on device.
- iOS: `LaunchScreen.storyboard` background `0.929/0.882/0.831` (= `#EDE1D4`); `LaunchImage*.png` are 68-byte placeholders (effectively blank). Plain ivory, no logo. NOT TESTED on device.
- Net: native splash is colour-matched but logo-less. Acceptable, not premium.

**Startup film**
- Asset `assets/branding/aqarati_intro.mp4`: 10.00 s, 1080×1920, H.264 High, 24 fps, ~834 kb/s, silent (audio removed). Poster `aqarati_intro_poster.jpg`, last frame `aqarati_intro_last.jpg`.
- Playback: `video_player`, volume 0, no loop, `mixWithOthers`. Poster shown instantly, video fades in on first frame (`_firstFrame`).
- First-run: `AqaratiIntroPreferences` (SharedPreferences key `hasCompletedAqaratiIntro`). Written **only** on a finished film (`isCompleted` or position ≥ duration−120 ms) or the reduced-motion bypass. Playback error → poster, 900 ms, **never persisted**. Replay: never after completion; no debug replay.
- Lifecycle: pauses on `paused/inactive`, resumes on `resumed` (`_IntroFilmState.didChangeAppLifecycleState`).
- Reduced motion: `MediaQuery.disableAnimations` → no film, 220 ms fade, counts as complete.
- Gaps: not tested on device; decoding on low-end Android unknown; **legacy `assets/branding/aqarati_startup.mp4` (10.8 MB) still bundled** and referenced by unused `core/widgets/aqarati_startup_video.dart`. Severity P3.

**Logo handoff — what it really does:** *animated handoff, not a fade, not a hard cut.* `LogoHandoff.compute` uses measured geometry (film logo bbox x268–864 / y568–1224 of 1080×1920; entry SVG aspect 484/440, art fill 0.975). At the end the live video is paused and **swapped for a still of its own last frame** (`_handoff`), then the still is scaled + translated over 700 ms (easeInOutCubic) onto the entry logo position while fading out (fade starts at 55%). Entry content reveals 280 ms after handoff starts. Web filmstrip shows continuous motion, no jump. Registration against the live vector is close, not pixel-proven. Device smoothness NOT TESTED. Verdict: **seamless on web, acceptable pending device test.** Prior lag fixed by still-swap + `precacheImage` of entry background and last frame.

---

## D. Entry / Welcome

MATCHES: full-bleed Omani photo with ivory wash; logo top; editorial headline ("A Brighter Property Journey in Oman", italic clay accent); support line; Create an Account (primary); Login (secondary); Google + Apple row; language chip; safe area ok at 375/393/430.
DIFFERENCES: compact layout under 760 px height; reveal staggered.
MISSING: none visible vs reference.
INCORRECT:
- **Fake pagination.** `onboarding_entry_screen.dart:146` `_Pager(count: onboardingPages.length < 4 ? 4 : …)` draws 4 dots; `onboardingPages` has **1** entry. Four dots, one page. P2.
- **Skip → `/home`** (`onboarding_page.dart` skipRoute). Lands in the *legacy* browse app (red accent, Cormorant, Buy/Rent/**Lease**). Different brand, outside this audit, and its "Lease" conflicts with BUY/RENT/INVEST/SELL. P2.
FUNCTIONALLY FAKE:
- **Google / Apple buttons**: `signInWithProvider` returns `AuthUnavailable` in both `DemoAuthRepository` and `UnavailableAuthRepository`; tap shows snackbar "This sign-in method is not connected yet." P1.
Accessibility: buttons have `Semantics(button, label)`. Language chip semantics ✔. Keyboard n/a.

---

## E. Purpose selection

Exact six, no extras (`signup_purpose.dart`): User to Shop, Real Estate Agent, Construction Company, Property Development Company, Building Architecture, Interior & Exterior Design. Test `exactly six public sign-up paths` passes. Searched for Maintenance Provider, AqaratiBroker, Other: **not present** ✔ (code comment explains).
- Single selection ✔ (`AQChoiceTile` grid), Continue disabled until selected ✔, haptic `AQHaptics.selection` in code (NOT TESTED), no fake step count ✔.
- Defect: at 375×812 and 430×932 tile descriptions are **cut mid-sentence** ("Register your construction business on", "Present your development company and"). Fixed tile height + ellipsis-less clip. P3.
- Arabic title for Building Architecture is "العمارة والتصميم الإنشائي" (draft; native review needed).

---

## F. Account creation

`SignupController` (`signup_state.dart`): 3 steps (You, Business, Account); User to Shop skips Business.
- First/last name required ✔. Phone: `^[79]\d{7}$` + fixed `+968` prefix ✔ (7/9 prefix rule is my assumption `[verify v2.4]`). Email regex ✔. Password: `length ≥ 8`, `[A-Z]`, `\d`, **no special-char rule** ✔ (test `password policy…` passes). Confirm must match ✔. Consent checkbox required ✔.
- Submit order Firebase user → API sign-up ✔ in code; on failure form kept ✔; banner mapping for conflict/validation/network ✔.
- Persistence: `SignupDraftStore` saves ordinary fields + step to SharedPreferences, **never password/documents** (test passes). It **does store email and phone in plaintext** (localStorage on web). Not cleared on sign-out. P3.
- **Terms / Privacy are plain text** (`signup.consent`): no tappable link, no route, no document. P1 (legal).
- Keyboard: `scrollPadding bottom 160`, `resizeToAvoidBottomInset` ✔. Real keyboard NOT TESTED.

---

## G. Authentication

Traced: `SignupController.submit` → `authRepositoryProvider.createUserWithEmail` → `accountApiProvider.signUp` → OTP → `getMe`.
- Contract (`AuthRepository`, `AccountApi`) matches the documented model: credentials to Firebase only, API gets ID token, auth ≠ verification, state via GET /me.
- **Implementation behind the contract is fake.** `pubspec.yaml` has **no `firebase_auth`, `firebase_core`, `http`, `dio`**. Searched `lib`, `android/app/build.gradle*`, `ios/Runner`: no Firebase init. `main.dart:12` `overrides: kUseDemoBackend ? demoOverrides() : const []`; `backend_mode.dart` `const bool kUseDemoBackend = true;`. With the flag off, every call throws `AuthError.unavailable` / network. **P0.**
- `DemoAuthRepository` keeps the password in a plain Dart field (`DemoBackendState.password`) and compares it locally; token is the literal `'demo-id-token'`. Demo only, but it ships.
- **No session restoration.** Initial route `/entry`; no `getMe` or `currentIdToken` at launch (`grep` in `main.dart`, `startup/`, `entry/` → none). A signed-in user is shown Welcome again. P0.
- **No auth guards.** `app_router.dart` has no `redirect`/`refreshListenable`. `/verification`, `/onboarding/documents`, `/app/*` open by URL with no session; they fail only because `meProvider` errors (inline error + Retry), not a redirect to login. P0.
- Login (`LoginScreen._submit`): `signInWithEmail` → `getMe` → `routeForSession` ✔ (otp_pending → `/otp`, business draft → intro, approved → `/app/home`, else `/verification`). Not custom API password login ✔ in design. Token refresh / 401 handling: none. Sign-out: only on Account tab (out of scope screen), clears demo flag.

---

## H. OTP forensic audit

Client: `OtpController` (`otp_state.dart`), UI `OtpScreen`, field `AQOtpField` (6 boxes over one hidden input, `oneTimeCode` autofill, digits-only, length 6).

| OTP state | Exists | Actual behaviour | Expected | Correct? | Sev |
|---|---|---|---|---|---|
| 6 digits | ✔ | 6 boxes, `LengthLimitingTextInputFormatter(6)`, auto-submit at 6 | 6 | ✔ | – |
| Auto-send on open | ✔ | `initState` → `send()` | start OTP | ✔ | – |
| Valid 15 min | ◐ | Server `expiresAt` stored in state, **never used**: no countdown, no proactive expiry; expiry only discovered when verify returns `expired` | show/handle expiry | ◐ | P3 |
| 5 wrong attempts | ◐ | Demo returns `rateLimited` at ≥5; UI shows generic `otp.rateLimited` banner. **No "attempts left" feedback.** Real server behaviour unknown | server-enforced; clear message | ◐ | P3 |
| 10-min attempt reset | ✘ | not represented client-side (server rule) | server | n/a | – |
| 60 s resend cooldown | ✔ | cooldown seeded from `OtpIssued.cooldownSeconds` / `Retry-After`, local timer counts down; button disabled | 60 s from server | ✔ (demo uses **30 s**, not 60) | P4 |
| 3 sends / 15 min | ◐ | Demo enforces and throws `otpLimitReached` (retry 300 s). Client maps to `rateLimited` + cooldown | server | ◐ | – |
| 10 sends / day | ✘ | no code path or message | server + message | ✘ | P3 |
| Rate-limit response | ✔ | `rateLimited`/`otpLimitReached` → phase rateLimited, banner, ticking cooldown | ✔ | ✔ | – |
| Invalid code | ✔ | boxes shake/error, inline message, field cleared, retype enabled | ✔ | ✔ | – |
| Expired code | ✔ | phase expired, banner, field cleared, Resend available when cooldown 0 | ✔ | ✔ | – |
| Resend | ✔ | `send()`; blocked while sending/verifying/verified | ✔ | ✔ | – |
| Retry after error | ✔ | `error` phase keeps typing enabled | ✔ | ✔ | – |
| Wrong number / change number | ✘ | **no path**. Searched OTP screen + routes. Only Back → `/entry` | change number | ✘ | P2 |
| Network failure | ✔ | `common.networkError` banner | ✔ | ✔ | – |
| SMS delay | ◐ | static hint "Didn't get a code?" + resend; no delay-specific copy | helper copy | ◐ | P4 |
| Success + auto transition | ✔ | success check, `AQHaptics.success`, 1.1 s (0.3 s reduced motion) then `/account/active` | ✔ | ✔ | – |
| Paste | ◐ | hidden field accepts paste; boxes have no explicit paste affordance; iOS keyboard suggestion works via `oneTimeCode` | paste/autofill | ◐ NOT TESTED on device | P3 |
| Focus / keyboard | ◐ | tap boxes focuses hidden input; numeric keyboard | ✔ | NOT TESTED on device | – |

Backend truth: the demo is **simulated**; the real SMS provider, throttles and attempt resets are not implemented anywhere in the client (correct—server concern) but unverifiable here.

---

## I. Login

UI ✔ (email, password with show/hide, Forgot, Create-account action). Loading ✔ (`_busy` guard, no double submit). Invalid creds → generic `login.invalid` ✔ (no account enumeration). Network → `common.networkError`. Too many → `login.tooMany`. Recovery link ✔.
- **Not Firebase** at runtime (G). P0.
- Social buttons on Entry not functional (D). P1.
- Accessibility: labelled fields, 48 pt targets. Responsive ✔ 375/393/430.

## J. Password recovery

- Forgot: Firebase reset **email only**, no SMS reset ✔; same confirmation whether the account exists ✔. Demo returns success after 600 ms regardless — **fake**. P0.
- Reset: `oobCode` from URL; new + confirm, same policy ✔, mismatch ✔, match helper ✔, success state → login ✔, expired/empty code state → "request new link" ✔. Screen keyed by `oobCode` ✔. Demo only treats literal `'expired'` as expired; no real Firebase `confirmPasswordReset`. Deep-link handling for the emailed link on native (`/reset-password?oobCode`) not wired to platform links (no app-links/universal-links config found). P1.

---

## K. User to Shop

`roleConfigs[userToShop]` has no documents, no business fields. Flow: 2 signup steps → OTP → `/account/active` → button `active.home` → `/app/home`. No CR/licence/company/verification prompts anywhere ✔ (searched strings and config). Buyer capability: generic shell shows "Your account is active" + a "Property search … next phase" line — not a buyer experience. "Lease" appears only in the legacy Home reached via Skip (outside scope, conflicts with BUY/RENT/INVEST/SELL).

---

## L. Professional roles

| Role | Form fields | Documents (config) | Notes |
|---|---|---|---|
| **Agent** | first, last, phone, email, **agency name**, password | Photo ID, Agent Licence (**tracks expiry**, date required before upload), Supporting document | ✔ matches expected. Post-OTP buyer capability: only generic active state. **Buyer↔Agent switch not built** (only a string `ws.cap.agent.1`). No brokerage/licence-number field `[verify v2.4]`. |
| **Construction** | + business name | CR Certificate (expiry), Municipal Licence | ✔. Separate Activity Licence deliberately **not** required (comment in `account_models.dart`) ✔. |
| **Development** | + business name | Official Corporate Registration (expiry), CR (expiry), Activity Licence(s), Developer Licence (expiry) | ✔. `fourEyes: true`. "Under review" vs "Awaiting second approval" distinct (Q). |
| **Architecture** | + business name | CR, Municipal Licence | ✔. |
| **Interior & Exterior** | + business name + service type (Interior / Exterior / Both) | CR, Municipal Licence | ✔ docs. Service-type field `[verify v2.4]`. |

For all: submit → pending ✔ (no fake approval); approval → generic `/app/home`. No role-specific workspace exists (U). Role-specific copy for intro/status is generic except role title.

---

## M. Document upload

`DocumentController` per `DocumentKind` (family provider) in `document_state.dart`.
- Types: PDF/JPG/PNG by **signature** (`hasAllowedSignature`), not extension ✔ (test). 10 MB limit checked **before** reading bytes ✔ (oversize never loaded). Independent per-file state ✔ (test: failure isolated). Progress, processing, success, failed, retry (reuses buffer), replace, rejected ✔. Required badge ✔; optional: none defined. Expiry date picker required for tracked kinds before choosing a file ✔ (`document_upload_tile.dart:43`). Preview: **none** (filename + size only) P3.
- Bytes: private `_buffer` in controller, dropped on success; never in state/drafts ✔. No storage keys exposed (`VerificationInfo` is metadata) ✔.
- **Fake:** `DemoAccountApi.uploadDocument` simulates 5 progress ticks + "scanning"; a file named `*fail*` fails. `demoAttachAll` marks everything received. Gated by `kShowReviewTools` (off by default) but the upload itself is simulated in every build. P0 (same root as G).
- Expired status: `expiryStatusOf` computes valid/expiring/expired and tile shows it, but **expired documents do not trigger resubmission** (S). Native picker NOT TESTED. Web picker cannot be scripted.

## N. Verification intro

`VerificationIntroScreen`: why (`vintro.why`), what we check (4 bullets), role's required documents, four-eyes note for developers, CTA. Secure handling: partial (the active screen says "Your details are protected…"); **supported formats and 10 MB shown on each tile, not on the intro**; "what happens next" is not on the intro. P3.

## O. Review / submission

`ApplicationReviewScreen`: business section, documents with Edit, consent text, Submit disabled until every doc `!= notSubmitted`. Submit → `submitVerification()` → `grant=pendingVerification, stage=underReview, reference generated` → `/onboarding/submitted`. **Does not fake approval** ✔ (verified in walk and code). Upload failure not re-surfaced here (docs must already be accepted). Loading + error banner ✔.
- Reference id `AQ-…` is generated in the **client demo** (`demo_backend.dart`), not by a server. Must come from API. P1 with G.

## P. Pending verification

`_Status` (`verification_status_screens.dart`): badge, headline per grant, "Nothing is needed from you right now", timeline (Submitted w/ date → Under review → [Second approval] → Approved), documents with status, View application, Refresh. Not a generic success/loading ✔. **No support/help/contact entry** P2. Notifications on status change: none (out of scope screen, but no hook). Back button → `/entry` (Welcome) for an authenticated user. P2.

## Q. Developer special state

Distinct ✔: `ReviewStage.awaitingSecondApproval`, gated by `cfg.fourEyes` so non-developers cannot show it (test + earlier bug fixed). Separate badge, headline, body, timeline step ("Awaiting second approval" as current). Source of stage = API field in contract; demo sets via `demoAwaitSecondApproval`.

## R. Application details

Shows reference (or "pending"), submitted date+time, role, documents, status, reason; read-only with an explanation when editing is not possible; Fix action only in resubmission_required. Missing: company name row for non-business, reviewer free-text feedback (only reason codes → localized strings; unknown code → `reason.unknown`). Reason codes are **placeholders** (`DOC_UNREADABLE`, `DOC_MISMATCH`) not from a spec. P3.

## S. Resubmission

Flow ✔: status → `Replace documents` → per-tile replace → `Review changes` → `resubmit()` → `/verification/resubmitted` → pending. Does not jump to approved ✔.
Defects:
- **Only `DocumentOutcome.rejected` docs are targeted** (`ResubmissionScreen`: `where(outcome == rejected)`). **Expired** and **missing** docs never enter the replace list. P1.
- **`Already approved` is a lie.** `ResubmitReviewScreen`: `approved = documents.where((d) => !targets.contains(d.kind))` — every non-targeted doc, including *pending review*, *expired*, *not submitted*, is labelled "Already approved". Screenshots show "Already approved" over rows reading "Received · pending review". P1.
- `resubmissionTargetsProvider` is in-memory only. App restart on `/verification/resubmit/review` → `updated` empty → Confirm disabled (stuck). P2.
- `resubmit()` demo flips rejected→pendingReview without checking replacements; real API behaviour unknown. P2.

## T. Approval / verified

`ApprovedScreen`, `VerifiedSummaryScreen`: redirect to `/verification` unless `grant == approved` from the server state ✔. Subtle celebration (check + logo), verified docs, business, profile status, CTA ✔. "Approved" is **backend-driven in contract, but backend is simulated**: `demoSimulate(GrantState.approved)` is the only way to reach it, gated off by default, so in a default build approval can't be reached at all. No fake local success path in production code ✔.

## U. Workspace handoff

`WorkspaceActivationScreen` lists 2–3 capability strings per role (`ws.cap.*`) then **every role goes to `/app/home`** (`AQAppShell` with generic Home/Explore/Activity/Account). Home shows role title + verification badge. **No Agent workspace, no Buyer↔Agent switch, no developer/construction/architecture/design workspace.** Explore and Activity are empty states. No capability exposure bug found (nothing is exposed). Copy bug: developer line "Your developer profile is **live after approval**" is shown *after* approval (future tense). P3. Overall P1 (handoff target missing).

---

## V. Routing

Router `app_router.dart`: GoRouter, initial `/entry`, **no redirect/guards**.

| Route | Prev | Next | Guard | Back | Notes |
|---|---|---|---|---|---|
| `/entry` | – | `/onboarding/purpose`, `/login`, `/home` (Skip) | none | – | no session check |
| `/onboarding/purpose` | `/entry` | `/signup/*` | none | pop | |
| `/signup/*` (6) | purpose | `/otp` | none | step back, then pop | draft resume ✔ |
| `/otp` | signup/login | `/account/active` | none (no check that account is otp_pending) | `aqBack('/entry')` | reachable without signup |
| `/account/active` | `/otp` | `/onboarding/verification-intro` or `/app/home` | none | `/entry` | back to Welcome |
| `/login` | entry | `routeForSession(me)` | none | pop/`/entry` | ✔ routes by state |
| `/forgot-password`, `/reset-password` | login | login | oobCode presence | pop | no deep-link platform config |
| `/onboarding/verification-intro` | active | docs | self-redirect to `/app/home` if role has no docs | `/account/active` | |
| `/onboarding/documents` | intro | review | none on grant | back→intro | **no grant guard**: pending/approved user can open it |
| `/onboarding/review` | docs | submitted | docs complete | docs | |
| `/onboarding/submitted` | review | `/verification` | none | `/verification` | |
| `/verification` | many | details / resubmit / approved | none | **`/entry`** | |
| `/verification/details`, `/resubmit`, `/resubmit/review`, `/resubmitted` | status | status | resubmit: self-handles "none to replace" | `/verification` | |
| `/verification/approved`, `/summary`, `/workspace/activation` | status | next | **self-guard grant==approved** ✔ | prior | |
| `/app/{home,explore,activity,account}` | activation | tabs | **none** | – | open without session |
| Legacy `/home`, `/explore`, `/messages`, `/profile`, `/onboarding`, `/saved`, `/search`, `/property/:id`, `/professionals`, `/business/:id` | – | – | none | – | out of scope; `/home` reachable via Skip; `/onboarding` is the OLD flow (duplicate onboarding) |

Dead/duplicate: legacy `/onboarding` (`OnboardingFlow`) duplicates onboarding; legacy `AppShell` vs new `AQAppShell`. Resume: signup draft only; no resume of OTP/doc/verification except via `/me` after login. All `context.go` (replace) mostly; `push` for entry→purpose, login↔create.

## W. State management

Riverpod 2.6. Onboarding form: `signupControllerProvider` (autoDispose family) + SharedPreferences draft. Auth: `authRepositoryProvider` (demo). Account/verification: `meProvider`, `verificationProvider` (`FutureProvider.autoDispose`, manual `invalidate`). OTP: `otpControllerProvider` (autoDispose). Documents: `documentControllerProvider(kind)`.
Risks: (1) `autoDispose` + no persisted state → document upload state resets when leaving the screen; seeded from server status only; (2) `resubmissionTargetsProvider`/`lastResubmittedProvider` plain `StateProvider`s, lost on restart; (3) locale and theme in memory only (`localeProvider`, `themeModeProvider`) — language resets each launch; (4) demo state (`DemoBackendState`) is a second source of truth hidden in a provider override; (5) `meProvider` errors don't route anywhere.

---

## X. Design system

Genuinely implemented: `core/aq/*` tokens (colours light/dark, 3 radii, 4 elevations, motion durations/curves, spacing), 15 typography roles, bundled fonts **Fraunces, Plus Jakarta Sans, IBM Plex Sans Arabic** (assets/fonts; verified rendering with no network), warm ivory/mocha/near-black palette, approved logo (single SVG master, dark mode via `ColorMapper`), custom icon family (`assets/icons/aq`), AQ primitives/forms/scene/documents.
Partial/inconsistent: legacy `BrandColors/BrandSpace` still used by `intro_host.dart`, `logo_handoff.dart`, `BrandThemed`; legacy `core/theme/*` (red accent, Google fonts) still drives the app theme and everything reached via Skip; Google/Apple glyph SVGs are outside the AQ icon family; some hard-coded colours in `_DarkLogoColors`; `inkFaint` contrast low on some captions (file-size lines).

## Y. iOS premium feel (0–10, web-tested only)

| Area | Score | Why |
|---|---|---|
| Typography | 8 | Editorial serif + clean sans, tuned scale, Arabic face. |
| Spacing | 7.5 | Consistent 4-pt tokens; some dense lists on 375. |
| Hierarchy | 8 | Clear title/subtitle/primary pattern. |
| Touch feedback | 7 | `AQPressable` scale 0.985; no ripple; haptics untested. |
| Scrolling | **5** | `ClampingScrollPhysics` hard-coded in `AQAuthScaffold` → **no iOS rubber-banding**. |
| Keyboard | 6 | `scrollPadding`, inset resize; real keyboard untested. |
| Sheets | 7 | `showAQSheet` custom; language sheet. |
| Transitions | 6.5 | One generic route transition for everything. |
| Haptics | 6 | Wired at meaningful moments; NOT TESTED. |
| Safe areas | 7 | `SafeArea` used; notch/home-indicator untested. |
| Status bar | 7 | `AnnotatedRegion` per scaffold. |
| Navigation | 6 | Back to Welcome from authenticated screens; swipe-back is Material default, not iOS-style `CupertinoPage`. |
| Loading | 6 | `AQSkeleton` basic; inline spinners. |
| Error handling | 6 | Banners good; no offline/session states. |
| Responsiveness | 8 | Clean at 375/393/430. |

## Z. Motion / transitions

All onboarding routes use `brandPage` → `AQRoute.forward` (one shared transition). `AQRoute.fade` exists, used nowhere in onboarding.

| Transition | Current | Intended | Correct? | Quality | Fix |
|---|---|---|---|---|---|
| Film → Entry | still-swap + scale/translate/fade handoff 700 ms | shared-element | ✔ | good (web) | device test |
| Entry → Purpose | `forward` | forward | ✔ | ok | – |
| Purpose → Signup | `forward` | forward | ✔ | ok | – |
| Signup → OTP | `forward` | forward | ✔ | ok | – |
| OTP → Success | success check + 1.1 s hold + `forward` | quiet success | ✔ | good | – |
| Login → Forgot | `forward` (push) | forward | ✔ | ok | – |
| Forgot → Reset | link-driven | – | ✔ | – | – |
| Signup → Documents | `forward` via intro | forward | ✔ | ok | – |
| Documents → Review | `forward` | forward | ✔ | ok | – |
| Review → Submit | loading button → `forward` + haptic | confirm | ✔ | good | – |
| Submit → Pending | `forward` | forward | ✔ | ok | – |
| Pending → Details / Resubmission / Replacement | `forward` | forward | ✔ | generic | vary for modal-like replace |
| Resubmission → Pending | `forward` | forward | ✔ | ok | – |
| Pending → Approved | `forward` + subtle check | celebratory-quiet | ✔ | ok | – |
| Approved → Workspace | `forward` | – | ◐ | generic | role-aware reveal |
Same animation everywhere = generic but not slow (~standard 320 ms?) — not measured on device. Tab switch uses `NoTransitionPage`.

## AA. Logo

One asset `assets/logo/aqarati_master.svg`, widget `MasterLogo` (forced LTR → never mirrored ✔). Dark mode: `ColorMapper` brown shapes → `#D9B793`, ivory counters → `#1A1613` (fixes filled A/Q/R; verified at 4× zoom and against Figma reverse). Placement: top of auth screens 104 pt, centred on active/approved. Duplicate logo files: `aqarati_logo_mark.svg` (legacy widget) still present. Film logo → live vector: animated handoff (C). Risk: counters use the dark page colour, not transparent; over a photographic wash the counter shade can differ slightly from the surrounding. P4.

## AB. Responsive (web, light, English)

- 375×812: Entry fits; Purpose needs scroll and clips tile text; signup, OTP, docs, status all fit with pinned CTA; long lists fade under CTA ✔.
- 393×852: reference size; clean.
- 430×932: content capped at 520; clean; Purpose tiles still clip text.
- Also checked 375×700, 360×640, 320×568 earlier: scroll + pinned CTA hold.
Not tested: keyboard-open layouts on device, landscape, tablets, text scale >1.0.

## AC. RTL

Web-verified in Arabic light + dark: mirrored layout, back chevrons on the right, IBM Plex Sans Arabic, directional icons flip, OTP boxes LTR-digits, phone numbers forced LTR, logo unmirrored ✔. Not fake. Caveats: Arabic copy is **draft** (no native review); `intl` number formatting for dates uses Material locale.

## AD. Dark mode

Complete for onboarding screens (warm near-black `#1A1613`, ivory text, bronze accent), walked through all verification screens light/dark/AR. **App now opens light by default** (`themeModeProvider`), dark chosen in Account. Issues: some captions low contrast; legacy Skip destination has an unthemed dark scheme (stock Material). Verdict: complete for audited screens, not fake inversion.

## AE. Accessibility

Present: `Semantics` labels on buttons/fields, header semantics on titles, 48 pt min tap (`AQControl.tap`), reduced-motion respected (`AQMotion.reduced`), live regions on field errors, OTP labelled.
Not verified: VoiceOver/TalkBack order, focus order, text scale 150–200% (no clamp or test), colour contrast audit (some `inkFaint` captions look < 4.5:1), semantic grouping of timeline. Playwright could drive the web semantics tree only. Blocking for production: no tested screen-reader pass. P2.

## AF. Failure states

| Failure | Impl. | UX | Recovery | Expected | Sev |
|---|---|---|---|---|---|
| Invalid credentials | ✔ | generic banner | retype | ✔ | – |
| Too many login attempts | ✔ mapping | banner | wait | ✔ | – |
| Network (auth/api) | ✔ | banner | retry | ✔ | – |
| Email conflict at signup | ✔ | banner | edit | ✔ | – |
| OTP invalid / expired / rate-limited | ✔ | inline/banner | resend | ✔ | – |
| OTP wrong number | ✘ | – | – | change number | P2 |
| Doc wrong type / oversize | ✔ | tile error | pick again | ✔ | – |
| Doc upload fail | ✔ | per-tile retry | retry | ✔ | – |
| Submission fail | ✔ | banner | retry | ✔ | – |
| Status load fail | ✔ | `aqErrorFrame` + Retry | retry | ✔ | – |
| Offline mode / global connectivity banner | ✘ | – | – | offline notice | P3 |
| Session expired / 401 | ✘ | – | – | redirect to login | P0 |
| Forced app update | ✘ | – | – | update gate | P2 |
| Rejected/Suspended | ◐ | state shown | **no action, no support** | contact/appeal path | P2 |
| Resubmission: expired/missing docs | ✘ | – | – | include in replace list | P1 |

## AG. Fake / placeholder / mock

| File | Function | What | Ships? | Sev |
|---|---|---|---|---|
| `core/config/backend_mode.dart:12` | `kUseDemoBackend = true` | enables demo for all builds | **No** | P0 |
| `main.dart:12` | `demoOverrides()` | wires demo auth + API | **No** | P0 |
| `data/demo/demo_backend.dart` | whole file | in-memory auth, OTP `123456`, 30 s cooldown, simulated upload, generated reference, `demoSimulate*` | **No** | P0 |
| `data/demo/demo_providers.dart` | `demoOverrides` | overrides providers | No | P0 |
| `core/auth/auth_repository.dart` | `UnavailableAuthRepository` | honest failure | ok as default | – |
| `core/localization/entry_strings.dart:34` | `providerUnavailable` | "not connected yet" snackbar for Google/Apple | **No** | P1 |
| `flow_strings.dart:67` | `login.unavailable` | same | No | P1 |
| `otp_screens.dart` | `kShowReviewTools` hint | "DEMO: use code 123456" | gated off | P3 |
| `verification_onboarding_screens.dart:104` | demo link | hard-coded English "DEMO: mark all documents received" (not localised) | gated off | P3 |
| `verification_status_screens.dart` | `_DemoControls` | decision simulator | gated off | P3 |
| `flow_strings.dart:31,183` | `common.demo`, `ver.demoTitle` | demo labels | gated | P4 |
| `signup_state.dart` | reason codes | placeholder `DOC_*` codes | No | P3 |
TODO/FIXME in audited folders: **none found** (grep). `placeholder`/`coming soon` hits are in legacy `property_card.dart`, `my_home_screen.dart`, `owner/` — out of scope.

## AH. Backend boundary

Violations (all confined to `lib/data/demo`, but shipped): client holds plaintext password; client compares OTP; client transitions grants; client generates `AQ-…` reference; client sets approved. No database access, no direct storage access, no hard-coded role grants in production paths (`roleConfigs` is form/document config, not a grant). Endpoint paths come from blueprint pp. 82–83, **not verifiable against v2.4**. `signUp`, `startPhoneVerification`, `verifyPhone`, `getMe`, `uploadDocument`, `getVerification`, `submitVerification`, `resubmit` are an *abstraction*, not real HTTP.

## AI. Tests (22, all pass)

- Widget: `aq_components_test.dart` (5: button disabled/loading, text-field error, OTP completes at 6, segmented).
- Documents: `document_controller_test.dart` (4: happy path, retry isolation, type/size reject, picker cancel).
- Logic: `flow_logic_test.dart` (12: six paths, required docs, strings AR/EN, step validation, password policy, draft JSON, file signature, OTP happy/resend, business active-but-draft, upload isolation, `routeForSession`, expiry status).
- Intro: `intro_preferences_test.dart` (1).
Missing critical: route-guard/redirect tests (none exist), screen widget tests (signup, OTP, status), OTP phase table (expired/rateLimited/attempts), resubmission targets/labels, session restore, Arabic/RTL golden, dark golden, text-scale tests, integration test of full journey, intro handoff test, document-expiry flow, four-eyes visibility on UI.

## AJ. Build / analyzer

- `flutter analyze`: 9 info, 0 warn, 0 error. Audited-scope hits: `lib/core/aq/aq_forms.dart:383` `use_null_aware_elements`; a `sort_child_properties_last` hit in a signup/flow file; rest are deprecations in legacy settings (`Radio.groupValue/onChanged`, `Switch.activeColor`).
- `flutter test`: 22/22 pass.
- `flutter build web --release`: OK (default and `--dart-define=REVIEW_TOOLS=true`). Output 123 MB (assets 143 MB incl. raw property videos and legacy startup video).
- Android/iOS build, signing, `flutter run` on device, Android 12 splash, Xcode archive: **NOT TESTED**.

## AK. Scorecard (0–10)

Visual 8 · UX 7 · Functional 6 · Authentication **2** · OTP 6 · Role onboarding 7 · Documents 7 · Verification 7 · Resubmission 5 · Approval 6 · Routing **4** · Motion 7 · iOS feel 6.5 · Accessibility 5 · RTL 8 · Dark 8 · Responsive 8 · Error handling 6 · Performance 4 (unmeasured + bloat) · Testing 3 · Architecture compliance 6.
Mean = 126.5 / 21 = **6.0 / 10** (implementation quality). Production readiness is **capped by P0 blockers** (no real auth/API, no session, no guards) to **~2 / 10 ≈ 20%**. A mean alone would mislead: a polished UI over a simulated backend is not shippable.

## AL. Severity key
P0 blocker · P1 critical · P2 high · P3 medium · P4 low.

---

## AM. Full mistake list

### Authentication / architecture (P0)
1. **Demo backend ships enabled.** `kUseDemoBackend=true`, `main.dart:12`. Expected: real Firebase + API; demo only in dev flavour. Impact: any email "signs up", OTP is `123456`, approvals simulated — the public Vercel site runs this. Fix: Firebase + HTTP client, flavour/`--dart-define`, default off.
2. **No Firebase/HTTP packages.** `pubspec.yaml`. Fix: add `firebase_core/auth`, API client with ID-token interceptor.
3. **No session restoration.** No `getMe`/`currentIdToken` on launch. Fix: bootstrap provider resolving auth + `/me`, route via `routeForSession`.
4. **No router guards.** `app_router.dart` has no `redirect`. Fix: redirect by session/account/grant state; deep-link-safe.
5. **No 401/expired-session handling.** Fix: interceptor → sign-out → `/login`.

### Functional (P1)
6. Google/Apple buttons fake (`onboarding_entry_screen.dart`, auth repos). Fix: implement or hide.
7. Terms/Privacy not linked (`signup.consent`). Fix: tappable links + legal screens.
8. Resubmission ignores expired/missing docs (`ResubmissionScreen`). Fix: targets = rejected ∪ expired ∪ missing from server.
9. "Already approved" mislabel (`ResubmitReviewScreen`). Fix: group by real `outcome`.
10. Role workspaces absent; Buyer↔Agent switch absent; all roles → `/app/home`. Fix: role-aware routing after approval.
11. Password-reset deep link not wired for native (no app-links/universal-links). Fix: configure and handle.
12. Reference id and OTP/grant logic generated client-side (demo). Fix: server only.

### UX (P2)
13. Rejected/Suspended are dead ends (no support/appeal). 
14. Back buttons from authenticated screens go to `/entry` (`_Status.onBack`, `AccountActiveScreen`, `OtpScreen`).
15. No change-number path in OTP.
16. Fake 4-dot pager on Entry (`:146`).
17. Skip → legacy off-brand app with "Lease".
18. Android 12+ splash not configured; iOS launch image blank.
19. `ClampingScrollPhysics` removes iOS bounce.
20. No forced-update, no offline state.
21. Bundle bloat (143 MB assets, legacy 10.8 MB film).
22. Accessibility not validated.
23. Tests thin (no route/screen tests).

### Visual / polish (P3–P4)
24. Purpose tile text clipped at 375 and 430.
25. OTP: no expiry countdown, no attempts-left, no 10/day message.
26. Workspace copy "live after approval" shown after approval.
27. Intro lacks formats/next-steps/secure-handling summary.
28. Draft stores email/phone plaintext.
29. Reason codes are placeholders; unknown → generic.
30. Document preview missing.
31. Low-contrast `inkFaint` captions.
32. Legacy `BrandThemed`/`core/theme` still in play; duplicate legacy onboarding (`/onboarding`).
33. Dark-logo counter colour fixed, not transparent.
34. Arabic copy unreviewed.
35. Phone prefix rule `[79]` assumed.
36. One transition style everywhere.
37. Analyzer: 9 info lints.

---

## AN. What is actually done

- IMPLEMENTED: six-path purpose selection; one data-driven signup form with draft resume; password policy; OTP client state machine (all documented phases); per-document upload controllers with signature/size checks; verification status rendering for all six grants + developer second-approval; resubmission *UI flow* for rejected docs; approval screens self-guarded by server state; RTL, dark, responsive; design tokens + bundled fonts; startup film with persistence and animated handoff.
- PARTIALLY: login/forgot/reset (UI + contract, no Firebase); documents (UI real, upload simulated); workspace handoff (generic); error coverage; accessibility semantics; native splash.
- NOT IMPLEMENTED: Firebase, API client, session restore, guards, social login, Terms/Privacy, role workspaces, Buyer↔Agent switch, change number, forced update, offline state, document preview, device-tested behaviour.

## AO. What is missing (by area)

1 Startup: Android 12 splash, device test. 2 Entry: real social login, honest pager, brand-correct Skip destination. 3 Purpose: text-fit fix. 4 Account: Terms/Privacy, Firebase. 5 OTP: change number, expiry countdown, attempts left, 10/day copy. 6 Login: Firebase, session restore. 7 Recovery: Firebase email, deep links. 8 User to Shop: buyer home. 9 Agent: Buyer↔Agent switch, agent workspace. 10–13 Construction/Development/Architecture/Interior: role workspaces. 14 Documents: real upload, preview. 15 Review: server reference. 16 Submission: real API. 17 Pending: support/help, notifications. 18 Resubmission: expired/missing handling, correct grouping, persisted targets. 19 Approval: real backend state. 20 Handoff: role-specific destination.

## AP. Exact next work order

1. **P0 integration:** add Firebase + HTTP client; implement `AuthRepository` and `AccountApi` for real; set `kUseDemoBackend=false` by default (flavour).
2. **P0 session + guards:** launch bootstrap (`auth` → `/me`), GoRouter `redirect` by account/grant state, 401 handling, sign-out flow.
3. **P1 resubmission correctness:** targets from server (rejected/expired/missing), fix "Already approved", persist/derive targets.
4. **P1 legal + social:** Terms/Privacy screens + links; implement or remove Google/Apple.
5. **P1 role handoff:** role-aware post-approval destination, Buyer↔Agent switch, role workspaces entry.
6. **P1 native recovery links:** app/universal links for `oobCode`.
7. **P2 UX:** change-number in OTP, support entry on pending/rejected/suspended, correct Back targets, remove fake pager, repoint Skip.
8. **P2 platform:** Android 12 splash, iOS launch asset, bounce physics, forced-update gate, offline banner.
9. **P2 tests:** route/redirect, screen widget, OTP table, resubmission, session, RTL/dark goldens; run on devices; screen-reader pass.
10. **P2 size:** prune unused assets (legacy film, raw media).
11. **P3:** purpose tile fit, OTP expiry countdown/attempts, intro copy, copy tense fix, draft PII, previews, contrast.
12. **P4:** lints, legacy theme removal, logo counter, Arabic native review, phone-prefix rule.

## AQ. Flow maps

**Actual:** Native splash (ivory, no logo) → film (10 s, silent) → still-swap handoff → Entry (always, even if signed in) → Purpose → Signup (2–3 steps) → `createUser` (demo) → `signUp` (demo) → OTP (demo code) → Account active → [User to Shop → `/app/home` generic] / [business → Verification intro → Documents (simulated upload) → Review → Submit (demo) → Status pending (stage underReview; developer may show second approval) → Details / (resubmission_required → Replace rejected only → Review changes → Resubmit → Resubmitted → pending) → **approval only reachable via demo simulator** → Approved → Summary → Workspace activation → generic `/app/home`]. Login branch: `/login` → demo sign-in → `getMe` → `routeForSession`.

**Expected (blueprint):** Splash → film → handoff → **session bootstrap** → Entry (or straight to state route) → Purpose → Signup → Firebase user → API sign-up → OTP (server limits) → Active → [User → buyer home] / [business → intro → docs (real upload) → review → submit → pending (under review → second approval for developer) → resubmission (rejected/expired/missing) → pending → server approval → verified → summary → **role-specific workspace** (Agent w/ Buyer↔Agent, Developer, Construction, Architecture, Design)].

**Differences:** (1) no session bootstrap; (2) no Firebase/API; (3) no guards; (4) resubmission scope narrower; (5) approval reachable only by simulator; (6) one generic workspace; (7) no social login; (8) Terms unreachable; (9) native recovery link unwired; (10) Back/Skip route into Welcome/legacy.

---

## AR. Final verdict

**WHAT IS PRODUCTION READY:** design tokens + fonts; purpose list; signup form validation + password policy; document file-signature/size logic; OTP client state machine; per-document isolation; four-eyes UI gating; RTL/dark/responsive layouts; startup film persistence rules.

**WHAT IS NOT PRODUCTION READY:** auth, API, session, routing guards, social login, Terms/Privacy, resubmission scope, role workspaces, native splash/links, tests, device behaviour, accessibility validation, asset size.

**BIGGEST 10 PROBLEMS:** 1 demo backend shipped enabled · 2 no Firebase/HTTP · 3 no session restore · 4 no route guards · 5 approval unreachable without simulator · 6 resubmission ignores expired/missing · 7 "Already approved" mislabel · 8 no role workspaces / Buyer↔Agent · 9 Terms/Privacy unlinked + social buttons fake · 10 nothing run on a real device.

**BIGGEST 10 THINGS DONE WELL:** 1 clean contract (`AuthRepository`/`AccountApi`) · 2 honest OTP state machine · 3 per-document isolated controllers with signature check · 4 no bytes/passwords in drafts · 5 exact six public paths · 6 developer second-approval kept distinct · 7 one coherent design system with bundled fonts · 8 real RTL + dark · 9 animated logo handoff with persistence rules and reduced-motion · 10 approval/summary self-guarded by server state, submit never fakes approval.

**TOP 20 FIXES (priority):** 1 real Firebase auth · 2 real API client · 3 demo off by default · 4 session bootstrap · 5 router redirects · 6 401 handling · 7 resubmission targets (expired/missing) · 8 fix "Already approved" · 9 Terms/Privacy · 10 social login or remove · 11 role-aware workspace + Buyer↔Agent · 12 reset-link deep links · 13 OTP change-number · 14 support/appeal on rejected/suspended/pending · 15 fix Back targets · 16 remove fake pager + repoint Skip · 17 Android 12/iOS splash · 18 iOS scroll physics + Cupertino back swipe · 19 route/screen/OTP/resubmission tests + device + screen-reader QA · 20 prune assets, fix purpose tile clipping.

**CURRENT REAL COMPLETION %:** ~55%
**CURRENT REAL PRODUCTION READINESS %:** ~20%

**CAN THIS ONBOARDING SHIP? — NO.**
Reason: every authentication, OTP, upload, submission and approval path runs on an in-memory simulation that is switched on by a hard-coded constant and is live on the public deployment; there is no Firebase or HTTP client, no session restoration, no route protection, no role-specific workspace, and the resubmission logic has correctness gaps. The interface is strong; the product behind it is not connected.
