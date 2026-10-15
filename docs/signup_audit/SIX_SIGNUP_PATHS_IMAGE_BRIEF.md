# AQARATI signup: visual reference brief for image generation

Companion to `SIX_SIGNUP_PATHS_AUDIT.md` (same folder). The audit holds the evidence; this file says what to draw.

Rules for whoever generates the images:

- **Draw what the app does and what the architecture requires. Do not add fields.** Anything marked **UNRESOLVED** must be drawn as a clearly labelled placeholder row ("decision pending: D#") or left out. Do not fill it with a guess.
- The existing sheets in `Desktop/Phone Images Aqariti` are **style references only**. They contain fields that are in no source (RERA number, years of experience, areas of operation, specialisations, company type and size, year established, alternate phone, position, website, optional company-profile uploads), a different agent document set, a green workspace theme, and "Skip" buttons. Do not copy their fields.
- The `Desktop/figma aqarati` PDFs are the old red design. Do not use them.
- Example values (names, numbers, dates) must be obviously fictional ("Example Company LLC", "Example Person"). No real people, companies, phone numbers, CR numbers or licence numbers. No fabricated reference numbers presented as real: if a reference is shown, label it "Reference (example)".
- All copy below is the app's current English copy from `lib/core/localization/flow_strings.dart` and `entry_strings.dart`. Arabic is **draft** in the same files and needs native review before it appears in a final image.

## A. Visual system (read from the code, not invented)

Source files: `lib/core/aq/aq_tokens.dart`, `aq_typography.dart`, `aq_auth_scaffold.dart`; `pubspec.yaml` (fonts); `assets/`.

### A.1 Colour tokens

| Token | Light | Dark |
|---|---|---|
| background | `#EDE1D4` | `#1A1613` |
| surface (glass, 72% alpha) | `#B8FBF7F1` | `#B8272019` |
| surfaceRaised | `#FBF7F1` | `#2A231D` |
| surfaceSelected | `#F6EADB` | `#3A2E24` |
| ink | `#2D2823` | `#F1E8DB` |
| inkSoft | `#655C52` | `#C3B6A5` |
| inkFaint | `#766B60` | `#93877A` |
| hairline | `#655C52` at 20% | `#F1E8DB` at 20% |
| accent | `#825C3F` (mocha) | `#B98A64` (bronze) |
| accentDeep | `#674830` | `#D1A47F` |
| onAccent | `#FFFFFF` | `#1A1613` |
| accentDisabled | `#B09A86` | `#6B5545` |
| danger | `#A2402E` | `#E08A78` |
| success | `#4C6B38` | `#9DB98A` |
| warning | `#8A5A1F` | `#D9A86A` |

The brief for this audit described the light accent as "terracotta or restrained red". **The tokens say mocha brown (`#825C3F`).** Use the tokens. Do not use red or green for primary actions.

### A.2 Type, shape, space

- Fonts, all bundled in `assets/fonts`: **Fraunces** (editorial display, Latin), **Plus Jakarta Sans** (UI text), **IBM Plex Sans Arabic** (Arabic; editorial sizes are scaled to 0.92 in Arabic).
- Radius: small 10, medium 18, large 28 (primary button, pills, segmented control).
- Spacing: 4-point scale (4, 8, 12, 16, 20, 24, 32, 40, 48); screen gutter 24; maximum content width 520.
- Heights: tap target 48, field 56, primary button 56. Icon sizes 18 / 22 / 26 / 28.
- Elevation: none, subtle, floating, modal (shadow colour `#2D2823` at 6%, 10%, 15%).
- Motion: 110 / 180 / 260 / 340 / 380 / 640 / 700 ms, ease-out-cubic standard. Collapses to zero with reduced motion.
- Icons: the 42-icon family in `assets/icons/aq` (agent, construction, development, architecture, interior, home, check, lock, shield, verified, info, phone, pin, calendar, clock, and others). Do not mix in other icon styles.

### A.3 Logo and backdrop

- Use the approved master logo exactly: `assets/logo/aqarati_master.svg`. Do not redraw, recolour (other than the app's own dark-mode mapping), stretch or add effects. The logos inside the existing PNG sheets are generated art, not the master: do not reuse them.
- Backdrop on auth screens: `assets/entry/oman_terrace_2k.jpg` under a warm wash so text stays legible. The **dark-mode treatment of the backdrop was not inspected**; draw it with the dark `background` and `surface` tokens and mark it "to confirm".

### A.4 Auth screen skeleton (every screen below unless stated)

Top to bottom, at 393 x 852:

1. Status bar; back chevron at the top left (48 px target). The login screen also has a text action at the top right; signup screens do not.
2. Master logo, centred, about 104 px wide. (Screens that celebrate a state may drop the logo or enlarge it.)
3. **Progress rail**: equal bars, filled up to the current stage, and a small caption `<Role name> · <Stage name>` in `inkSoft`.
4. Title in Fraunces (display), optional subtitle in Plus Jakarta Sans `inkSoft`.
5. Fields on `surfaceRaised`, radius 18, height 56, **label inside the field at the top**, value below.
6. A fixed bottom area: info banner or error banner above, then the primary button (accent, pill radius, label left-centre and a chevron at the right), then a one-line footnote with a lock icon: "Your answers are saved on this device (never your password or documents)."

**Rail length per path (real):** User to Shop 3 bars (Account, Phone, Ready). Real Estate Agent, Construction, Building Architecture, Interior & Exterior: 4 bars (Your details, Agency or Business or Practice, Documents, Review). Property Development: 5 bars (adds Verification).

### A.5 Arabic and dark

- Mirror every layout for RTL: back chevron at the right, rail fills right to left, chevron on the primary button points left, text right-aligned. The phone number and OTP digits stay left-to-right inside an LTR island.
- Existing references have no dark or Arabic versions. Every image below is requested as a **light + dark pair**; Arabic RTL pairs only for the screens marked (AR).
- Arabic role names (draft): مستخدم للتسوّق، وسيط عقاري، شركة مقاولات، شركة تطوير عقاري، العمارة والتصميم الإنشائي، التصميم الداخلي والخارجي.

## B. Images to generate, in order

For each image: purpose, where it sits, the exact content, states, rules, code, and what exists already.

---

### SU-01 Purpose selection (AR)

- **Purpose:** choose one of the six public signup paths.
- **Entry / exit:** from Entry (Create an Account) to `/onboarding/purpose`; Continue pushes the chosen role's signup route.
- **Header:** back chevron; logo; no rail.
- **Content:** title "What brings you to AQARATI?" with subtitle "Choose your main purpose to personalize your experience." Six selectable cards in two columns, each with an AQ icon, a title, a full description (never cut with an ellipsis), and a chevron:

| Card | Icon | Description |
|---|---|---|
| User to Shop | `home` | Browse, discover and use AQARATI as a buyer. |
| Real Estate Agent | `agent` | Join AQARATI as a licensed real estate agent. |
| Construction Company | `construction` | Register your construction business on AQARATI. |
| Property Development Company | `development` | Present your development company and projects. |
| Building Architecture | `architecture` | Register your architecture practice on AQARATI. |
| Interior & Exterior Design | `interior` | Register your interior and exterior design practice. |

- **States:** nothing selected (Continue disabled, `accentDisabled`); one selected (card on `surfaceSelected` with an accent outline, and the role's tagline shown, e.g. "Build trust around every property you represent."; Continue enabled); a failure snackbar variant is not needed.
- **Rules:** exactly these six. **No** Maintenance Provider, AqaratiBroker, "Other", "Find a Property", "Home Maintenance", "List a Property", or "Join as a Professional". No "Skip". No step counter such as 1/3.
- **Code:** `PurposeSelectionScreen`, `signup_purpose.dart`. **Existing reference:** `AQARATI Premium Property Onboarding.png`, which is wrong (see audit 6.1). Replace it.
- **Generate:** yes, first.

---

### SU-02 Form component kit

- **Purpose:** one sheet so field styling is not redrawn on every screen.
- **Content (all shown in light and dark):** text field in default, focused, filled and valid (check), and error (message below in `danger`, with an icon so colour is not the only signal); phone field (fixed "+968" prefix, hint "9X XXX XXX", LTR); password field (show / hide control); password requirement list with three rows ("At least 8 characters", "One uppercase letter", "One number") in unmet and met states, and the collapsed success line "Your password meets the requirements."; segmented control with three options (Interior, Exterior, Both) unselected and selected; consent row with the text "I agree to the AQARATI Terms of Use and Privacy Policy." with two underlined links, unchecked, checked and error; info banner and error banner; primary button in enabled, disabled and loading states; account conflict card (see SU-04).
- **Code:** `lib/core/aq/aq_forms.dart`, `aq_primitives.dart`.
- **Generate:** yes.

---

### SU-03 "About you" and "Where can we reach you?" (AR)

- **Purpose:** the first two steps, identical for all six paths.
- **Content:**
  - Step "About you": title "Let's start with you."; subtitle = the chosen role's tagline (first step only); fields **First name**, **Last name** (both required).
  - Step "Contact": title "Where can we reach you?"; fields **Email**, **Mobile number** (fixed +968, 8 digits).
  - Primary button "Next".
- **Rail variants to show:** User to Shop (3 bars, caption "User to Shop · Account"); Agent (4 bars, "Real Estate Agent · Agency"); Development (5 bars). One example per rail length is enough; the rest differ only by caption.
- **States:** empty; focused; filled valid; error ("This field is required." on both name fields; "Enter a valid email address."; phone: the app's text is "Enter an 8-digit Oman mobile number." and **the rule behind it is UNRESOLVED (D6)**: the app also rejects 8-digit numbers that do not start with 7 or 9, which the text does not say, while the architecture says only "+968 + 8 digits").
- **Rules:** no password here (it is on the last step). No "Skip". No "Full name" single field.
- **Code:** `signup_form_screen.dart`, steps `you` and `contact`.
- **Existing reference:** `Oman-Inspired Account Creation Screen.png` puts everything on one screen: do not follow it.
- **Generate:** yes.

---

### SU-04 "Secure your account" (consent step)

- **Purpose:** last signup step. Two variants.
- **Content:** title "Secure your account."; **Password**; live requirement list (collapses to "Your password meets the requirements."); **Confirm password**; consent row; a note: variant A (User to Shop) "No documents are needed to sign up."; variant B (business paths) "You will upload your documents after your phone is verified."; primary button **"Create account"**; footnote about the local draft.
- **States to draw:** empty; password typed with partial requirements; all met; password rule error ("Use at least 8 characters, including one uppercase letter and one number."); mismatch error ("Passwords do not match."); consent error ("Please accept to continue."); **submitting** (button spinner, fields frozen); **conflict card** replacing the banner: title "You already have an AQARATI account.", body "Sign in, reset your password, or use a different email.", three text buttons "Sign in", "Forgot password", "Use another email"; network error banner.
- **UNRESOLVED:** whether the consent row must show terms and privacy **versions** (D7). Until decided, draw the row without a version number.
- **Rules:** the password policy is 8 or more characters, one uppercase letter, one number, **no special-character requirement**. Do not draw "mix of letters, numbers and symbols".
- **Code:** `signup_form_screen.dart` (`account` step, `_ConflictCard`). **Generate:** yes.

---

### SU-05A Business step: Real Estate Agent

- **Content:** title "Tell us about your agency."; one field **Agency / brokerage name** (required); info banner "You will upload your documents after your phone is verified."; "Next".
- **Rail:** 4 bars, caption "Real Estate Agent · Agency".
- **Rules:** nothing else. No RERA number, years of experience, areas of operation, specialisation, agency email or agency phone (not in §19.3).
- **Code:** `signup_form_screen.dart` (`business`, `cfg.hasAgencyName`). **Generate:** yes.

### SU-05B Business step: company (Construction, Development, Architecture)

- **Title:** Construction and Development: "Tell us about your company." Architecture: "Tell us about your practice."
- **Built today:** one field **Business name** (required) and the documents-later banner.
- **Required by the architecture (§19.5 to §19.7) and missing in the app: UNRESOLVED:**
  - **Company physical address** (required for Architecture; listed for Construction and Development). Format undecided (D2): free text, governorate / wilayat / area, or map pin.
  - **Company email**, separate from the contact email (D1).
  - **CR number and licence number** if typed at signup rather than read from documents (D3).
- **Instruction:** draw the Business name field, then **placeholder rows** labelled "Company address (decision pending D2)" and "Company email (decision pending D1)". Do not invent labels, formats, dropdown options or hints. Do not add company type, size, year established, head office, website, position, alternate phone or services.
- **Generate:** **no, not until D1 to D3 are answered.**

### SU-05C Business step: Interior & Exterior Design

- Same as SU-05B plus **Service type**, a required segmented control with three options **Interior / Exterior / Both**, placed under Business name, with an error state ("Required").
- Title "Tell us about your practice." Caption "Interior & Exterior Design · Practice".
- Service type is **confirmed** (§19.8). The address and email rows are UNRESOLVED as in SU-05B.
- **Rules:** do not replace Service type with "Services & Specializations" (as the existing Design Firm sheet does). Do not merge this with Architecture.
- **Generate:** no, until D1 to D3.

---

### SU-06 Account active (business) and Email verification (AR)

- **Account active, business variant:** no back button (nothing sensible behind it); rail unchanged from the form, so for business paths the caption is still the business stage ("Real Estate Agent · Agency", "Construction Company · Business", and so on); large check; title "Your account is active"; body "Your account is active. This is not yet an approved business role: add your documents so we can verify it."; primary "Add documents"; text link "Verify your email"; info banner "Your details are protected and used only to set up your account."
- **Buyer variant already has an existing reference** (`Aqarati Account Success in Oman.png`); redraw it only to match the real copy ("Go to home", "You can now browse, search and book on AQARATI.", no `03/03`).
- **Email verification screen:** title "Verify your email"; "We sent a verification link to" + masked address (first letter, dots, domain); body "Check your inbox and open the link. It may take a minute to arrive."; buttons "I've verified", "Resend email" (cooldown "Resend in {s}s"), "Change email"; states sending, sent, verified ("Email verified" / "Thanks. Your email is confirmed."), not yet ("Not verified yet. Open the link in the email, then try again."), failure ("We could not send the email. Please try again."); sheet "Use a different email" with "Update and resend". It never blocks the journey.
- **Code:** `AccountActiveScreen`, `EmailVerificationScreen`. **Generate:** yes (no existing reference for these two).

---

### OTP: no new generation required

`AQARATI OTP Verification Flow UI.png` is a usable state sheet. When using it, **drop** these elements: "Too Many Attempts: try again in 15 minutes", "5 OTP requests per hour", "Need Help? Contact Support", the "Complete Profile" next-step card. Real rules: 60 s resend cooldown, 3 sends per 15 minutes, 10 per day, 5 wrong attempts, 15 minute validity. The "Is this the right number?" sheet (Keep this number / Edit number / Update and send a code) has no reference; add it only if asked.

---

### SU-07A Documents: Real Estate Agent

- **Entry:** Add documents, then "Verify your business" intro, then this screen. **Rail:** 4 bars, caption "Real Estate Agent · Documents". Title "Your documents"; subtitle "Upload each document. Each one is sent and checked on its own."
- **Three tiles**, each with the badge "Required", a one-line description, a status row, the note "PDF, JPG or PNG · up to 10 MB" and a "Choose file" button:
  1. **Photo ID**: "A clear photo of your valid ID."
  2. **Agent licence**: "Your current real estate agent licence." **Has "Set expiry date"; the date must be set before the file picker opens.**
  3. **Supporting document**: "Any document that supports your application."
- **Bottom:** "Review application" (disabled until all three are received) with the hint "Upload every required document to submit."
- **Tile states to show once each:** Not uploaded; Checking file; Uploading {p}%; Scanning; "Received · pending review"; Upload failed (with Retry); "Needs replacing" (with the reviewer reason); "Expired · replace"; "Upload required"; Verified. Each state has an icon and text, never colour alone.
- **Rules:** documents are **not** RERA licence, Civil ID / Passport, Agency Trade Licence or profile photo.
- **Code:** `DocumentOnboardingScreen`, `DocumentUploadTile`. **Generate:** yes.

### SU-07B Documents: Construction, Building Architecture, Interior & Exterior

- One image with the role caption changed. Two tiles: **CR certificate** ("Your commercial registration certificate.", expiry date), **Municipal licence** ("Your current municipal licence.").
- **UNRESOLVED (D4):** the architecture says expiry is tracked for "Licence, CR". The app tracks CR only, so the municipal licence tile has no expiry control today. Draw the municipal tile **with** a "Set expiry date" row marked "decision pending D4", or hold this image.
- **Rules:** no Activity Licence for Construction (confirmed). No optional "Company profile" upload (it is in the existing sheets but not in the source).
- **Generate:** hold until D4.

### SU-07D Documents: Property Development

- Banner at the top: "Development companies go through a two-step review: a reviewer first, then a senior reviewer."
- Four tiles: **Official corporate registration** (expiry), **CR certificate** (expiry), **Activity licence(s)**, **Developer licence** (expiry).
- **UNRESOLVED (D8):** the architecture says "Activity Licence(s)"; the app has one upload slot. Draw one tile unless D8 says otherwise; do not draw an "Add another licence" link or the optional Company Profile, Project Portfolio and Financial Statements uploads shown in the existing sheet.
- **Generate:** hold until D8.

---

### SU-08 Application review (AR)

- **Content:** title "Almost there."; subtitle "Check everything before you submit."; sections, each a card:
  - "Your details": Role (e.g. "Real Estate Agent"), Mobile ("+968 •••• 1234" masked).
  - "Business": Name (agency or business name). **Interior & Exterior: the service type is not shown on the built screen; confirm with the design owner before drawing it** (UNRESOLVED, not a product requirement).
  - "Documents" with an "Edit" link: one row per required document with its status badge and file name, tappable to preview.
  - "Consent": "You accepted the Terms of Use and Privacy Policy when you created your account."
  - When complete, a green-tinted note: "Ready to submit" / "Everything required is in. Submit when you're ready."
- **Bottom:** "Submit application" (disabled until all documents received, with "Upload every required document to submit."); loading state; error banner.
- **Variants:** Agent, company, company-with-service-type (the document rows differ).
- **Code:** `ApplicationReviewScreen`. **Generate:** yes.

---

### SU-09 Verification status states

Common structure: no back button (root of the onboarding area); rail at the last stage; a status badge; headline; body; timeline where relevant; document rows; one primary action or "Refresh status"; text link "View application".

| State | Headline | Body | Action |
|---|---|---|---|
| Draft | Add your documents | Your documents have not been submitted yet. Add them to start verification. | Add documents |
| Under review | Your application is under review | Your documents are with our reviewers. We will notify you when there is an update. | Refresh status; "Nothing is needed from you right now" |
| **Awaiting second approval (Development only)** | Awaiting second approval | A first reviewer has approved your submission. A senior reviewer completes the final approval. | Refresh status. Timeline: Submitted, Under review, **Awaiting second approval** (current), Approved. |
| Resubmission required | Resubmission required | Some documents need to be replaced. Your other details are kept. | Replace documents |
| Rejected | Application not approved | This request was not approved. See the reason below. | **UNRESOLVED (D10): re-application after 30 days** |
| Suspended | Role suspended | This role is suspended. Business capabilities and related content are not available while it is suspended. | none today (support route undecided) |
| Approved | You are verified | Your business role is approved. | Continue |

- Timeline for non-developers has three steps (Submitted, Under review, Approved); the developer path has four.
- **Reason text (D9):** reason codes come from a closed list of 12 in §50.2. The app's own text covers three codes only. Draw the reason block with a placeholder "Reason shown here". Do not invent reason wording.
- **Also draw:** "Application submitted" confirmation (title "Application submitted"; body "Your application has been submitted for verification. We will notify you when there is an update."; "Reference" line labelled as an example; status badge; "View application status").
- **Rules:** no "Estimated 1 to 3 business days", no notification list, no "Contact Support", no 7-day response window, unless a source adds them.
- **Code:** `VerificationStatusScreen`, `ApplicationSubmittedScreen`, `ApplicationDetailsScreen`. **Generate:** Under review, Awaiting second approval, Draft, Submitted: yes. Rejected, Suspended: after D9 and D10.

---

### SU-10 Resubmission

- Screens: "Replace documents" (title; "Only the documents below need replacing. Everything else stays as submitted."; one tile per target with the reviewer's reason; other documents listed as read-only rows); "Review changes" (sections "Updated", "Already approved" (only truly accepted documents), "Still under review"); button "Resubmit application"; "Application resubmitted" confirmation (with "What changed").
- **Targets** are documents that were rejected, expired or missing. Do not show "Business Information" or "Authorized Representative" as approvable sections (the model has documents only).
- **Existing reference:** `AQARATI Resubmission Flow UI Mockup.png` is a reasonable style base. Redraw to the document-only model.
- **Generate:** after D9.

---

### SU-11 Approved and Verified summary (AR)

- **Approved:** large drawn check with a warm bloom behind it; master logo; title "You are verified"; subtitle "Your business has been approved on AQARATI."; four lines that arrive in sequence: "Documents verified", "Business approved", "Profile activated", "Professional workspace ready"; button "Continue". Quiet and restrained, no confetti.
- **Verified summary:** title "Verified profile"; card "Verified business" (business name, role, "Verified on" date, "Profile status: Active"); card "Verified documents" with rows; button "Enter workspace".
- **Rules:** mocha accent, not green. No dashboard counts, no "Create Your First Listing", no "Inquiries" list, no "View Public Profile".
- **Code:** `ApprovedScreen`, `VerifiedSummaryScreen`. **Generate:** yes.

---

### SU-12 Workspace activation

- **Content:** title = "Your {Workspace} Workspace is ready" (Construction, Developer, Architecture, Design); subtitle "{Role} · Here is what your approved role unlocks."; one card with check rows; button "Open workspace".
- **Rows (current copy):** Professional (Construction, Architecture, Interior & Exterior): "Your company profile is visible in the directory"; "Keep your profile and documents up to date". Developer: "Your developer profile is live"; "Create and manage your own projects (each is reviewed)".
- **Destination:** the Development & Building workspace (dashboard, company profile, contact activity, reviews, engagements, portfolio; developers also get Projects and the five-step project wizard). Those screens already have references (#59 to #86).
- **Agent variant: UNRESOLVED (D5).** The current copy promises "Switch between Buyer and Agent", "Create and manage listings", "Manage viewing availability", and none of it exists. **Do not generate an Agent activation or workspace image until D5 is answered.** If the decision is to build it, the source (§19.3) describes only: buyer home with a banner before approval; a RoleSwitcher between Agent and Buyer after approval; an agent workspace to create and manage own listings and viewings.
- **Code:** `WorkspaceActivationScreen`. **Generate:** Professional and Developer variants yes; Agent held.

---

## C. Shared components, so images are not duplicated

| Component | Appears in | Draw once in |
|---|---|---|
| Auth skeleton (logo, rail, title, bottom bar) | all | SU-02 and any one screen |
| Text field, phone field, password field, requirement list, segmented control, consent row | SU-03, SU-04, SU-05* | SU-02 |
| Document tile (all states) | SU-07*, SU-10 | SU-07A |
| Status badge (7 variants) | SU-09, SU-11 | SU-09 |
| Timeline (3 or 4 steps) | SU-09 | SU-09 |
| Review section card and document row | SU-08, SU-10, SU-11 | SU-08 |
| Info banner, error banner, conflict card | most | SU-02 |

## D. Decisions that must be answered first (copied from the audit)

D1 company email versus contact email. D2 company address format. D3 CR and licence numbers at signup. D4 municipal licence expiry. D5 Agent workspace. D6 phone prefix rule. D7 consent versions. D8 several activity licences. D9 reason-code list and text. D10 re-application after 30 days. D11 architecture version (task said v2.4, repository has v2.6). D12 native Arabic review. D13 whether the extra fields in the old sheets are dropped (recommendation from the sources: drop them).

## E. What is not covered by this brief

Login, forgot password and reset password (not signup paths); the Entry and OTP screens (see the notes above); the Development & Building customer and workspace screens #59 to #86 (they have their own index in `docs/development_building/REFERENCE_IMAGE_INDEX.md`); Maintenance Provider and AqaratiBroker onboarding (different rules, not public signup).
