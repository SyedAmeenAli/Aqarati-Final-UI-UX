# Onboarding: what is verified and what is not

Verified in Flutter Web (Chromium, headless) and in `flutter test` only. **No iOS or Android device, simulator or emulator run has been done.**

## Verified (web + tests)
- Film plays 10.00 s, silent; completion flag written only after the film ends, after an explicit Skip, or by the reduced-motion bypass. A quiet Skip appears after 1.4 s and fades straight into Entry.
- Film-to-Entry handoff: last-frame still scales/moves onto the live logo while Entry rises (frame sequence inspected).
- Entry has no fake pager and no Skip; Purpose descriptions are never clipped (375/430 wide, 200% text).
- Whole journey walked at 375x812, 393x852, 430x932 (light/English), 393x852 dark + Arabic, 375x812 at 200% text: signup (conversational steps), OTP + change-number sheet, account active, email verification, intro, documents, review, submitted, pending, second approval, resubmission, review changes, approved, summary, role-aware workspace, Home, legal.
- 45 tests: journey stages, document status vocabulary, resubmission targets/grouping, role-aware workspace, change-number OTP, email masking, routes (no legacy `/onboarding`), reduced motion, purpose selection, 200% text on signup/OTP/active/document tile, plus the earlier logic tests.

## Must be checked on devices before calling it done
1. **Native splash** (new, never run on a device): Android `drawable/launch_background.xml` + `drawable-v21` (ivory `#EDE1D4` + `launch_logo.png`), Android 12+ `values-v31` / `values-night-v31` (`windowSplashScreenBackground`, `splash_icon.png`), iOS `LaunchImage*.png` (logo on ivory storyboard). Confirm the logo sits sensibly before the film starts and there is no colour jump.
2. Video codec on a low-end Android (hardware decoder) and on iOS.
3. Lifecycle: background at ~6 s then resume; kill at ~4 s (replays); kill after the end (never replays).
4. System bars, notch, gesture bar, keyboard over fields, iOS rubber-band scrolling (platform scroll physics are now the default).
5. File picker (PDF/JPG/PNG) on iOS and Android; image thumbnail in the document preview sheet.
6. Haptics (selection, OTP success, document received, approval).
7. VoiceOver / TalkBack pass (Skip, consent links via custom actions, timeline, document statuses). Text scale 150% and 200% were previewed on web only.
8. OTP autofill / paste on device.

## Contract assumptions the frontend now makes (confirm with the API/Firebase owners)
- `AccountApi.changePhone(phone)`: replace the number a pending OTP was sent to ("Wrong number?").
- `AuthRepository.sendEmailVerification / isEmailVerified / currentEmail / updateEmail`: Firebase client email verification.
- Legal screens (`/legal/terms`, `/legal/privacy`) are a frontend shell. No legal text is invented; supply the approved documents.

## Still open
- Demo backend (`lib/data/demo`, `kUseDemoBackend` in `lib/core/config/backend_mode.dart`) must be replaced by Firebase Auth + the Aqarati API. Review shortcuts only exist with `--dart-define=REVIEW_TOOLS=true`.
- No session restoration, route guards or 401 handling yet (needs the real auth layer).
- Role workspaces beyond the handoff screen and the minimal `/app` shell are not built. "View Public Profile" has no destination yet.
- "Open Mail" on the email-verification screen needs a launcher plugin that is not in the project.
- Google/Apple sign-in: contract only; buttons honestly report "not connected yet".
- Arabic copy is draft and needs native review.
- Password minimum (8) and reason-code copy (`reason.*`) are placeholders until the API defines them.
- QA-only build flags: `REVIEW_TOOLS`, `AQ_THEME=dark`, `AQ_TEXT_SCALE=2.0`.

# Property viewing flow (screens 39-51)
Verified on Flutter Web only (light, dark, Arabic, 320x568 and 393x852, 200% text on the main path) plus `flutter test`. **No device run.**
- Routes: `/property/:id/viewing` (39), `/slot` (40), `/review` (41), `/conflict` (49); `/viewings/:id` (47) with `/requested` (42), `/confirmed` (43), `/declined` (44), `/reschedule` (45), `/cancel` + `/cancelled` (46), `/completed` (48), `/review` (review entry); My Viewings and its empty state (50, 51) are the Activity tab.
- Data: `ViewingRepository` is a frontend contract (availability, request, cancel, accept/decline suggestion, list, get, host). Only a **demo** implementation exists. Confirm the real API shape with the API owners. Host responses are simulated only with `--dart-define=REVIEW_TOOLS=true`, which also seeds one viewing per state.
- Not built because nothing supports them yet: Call/WhatsApp/Enquiry buttons and Add to Calendar / Get Directions (no launcher plugin), a live map (placeholder only), a request message field, a user-initiated reschedule, the review form itself (screen 48 links to an honest entry page).
- Photos are the app's own property assets; host avatars are monograms. Arabic copy is draft.
- Not checked: iOS/Android devices, VoiceOver/TalkBack, haptics, shared-image Hero flight on device, 360x640, Arabic at 200%, a pixel comparison against the reference folder.
- Known existing issue: the glass nav label "Account" clips at 200% text.
