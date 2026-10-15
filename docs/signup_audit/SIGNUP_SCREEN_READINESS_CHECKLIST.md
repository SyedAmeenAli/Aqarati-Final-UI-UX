# Signup screen readiness checklist

Updated 2026-10-15. `[x]` = done and verified as stated. `[ ]` = not done or not verified. Everything was run on the demo backend (`kUseDemoBackend = true`) in Chromium on this machine and in `flutter test`. Nothing was tested on a real device or against a real backend.

Screenshots: session scratchpad, `vw/sw3/` (about 170 PNGs named `<path>-<width>-<theme>-<lang>-<step>.png`). They are not in the repository.

## Browser walk results (Chromium, 2026-10-15, synthetic values, demo OTP)

Flow tested: `/signup/<path>` through contact (phone `71234567`, a 7-leading number), business step, account, OTP `123456`, account-active, then for business paths: verification intro, documents (real file chooser, expiry date, a valid minimal PDF), Review application, Submit, "Application submitted".

| Path | 393 light EN | Result |
|---|---|---|
| User to Shop | yes | reaches account-active; no documents by design |
| Real Estate Agent | yes | 3 documents uploaded, review, submitted |
| Construction | yes | email + optional address, 2 documents, submitted |
| Property Development | yes (viewport 393x1500 so all four tiles fit) | 4 documents uploaded, review, submitted |
| Building Architecture | yes | required email + address, 2 documents, submitted |
| Interior & Exterior | yes | required email + address + service type, 2 documents, submitted |

Other conditions (Architecture and Interior & Exterior only, the two paths with required company fields):

| Condition | Result |
|---|---|
| 320, 360, 412, 430 px, light, English | Architecture reaches submitted at all four; Interior & Exterior also at 320 px |
| Dark theme (real `AQ_THEME=dark` build) | Both paths reach submitted; business step and documents screens checked visually |
| Arabic / RTL, 393 px | Business step (with the new fields and errors), contact and account steps render RTL; walk reached the documents screen. **Not verified in Arabic:** uploading documents, review, submitted (my script matched English button names only) |
| Business-step validation in the browser | Empty company email shows "Enter a valid email address."; empty required address shows "This field is required." (architecture, English and Arabic) |
| Invalid file | A text file named `test.pdf` is rejected with "Use a PDF, JPG or PNG file." (signature check works) |

Not covered: the screens after "Application submitted" (status, resubmission, approved, summary, activation) were not re-walked; they cannot be reached in a default build. Agent and Construction/Development/Interior at 320 to 430 px were not walked (only Architecture, plus Interior at 320). Arabic was not walked on the other five paths. No device, screen reader, haptics or backend testing.

## Automated
- [x] `flutter test`: 254 passed (29 in `test/signup_paths_test.dart`)
- [x] `flutter analyze`: no errors; 41 info/warning items, same as before
- [x] Production web build succeeded

## Behaviour
- [x] SU-01: six cards, exact copy, single selection, Continue gated
- [x] Phone: `+968` plus exactly 8 digits, no 7/9 rule (test + browser)
- [x] Company email required and used as sign-in email on the four company paths
- [x] Company address required for architecture and interior/exterior, optional for construction and development
- [x] Documents to review hand-off fixed (see implementation log) and covered by a test
- [ ] Password blocklist (PENDING, needs a service)
- [ ] Consent versions and locale sent with sign-up (PENDING, D7)

## Per path
| Path | Form | Documents | Submit |
|---|---|---|---|
| User to Shop | verified | n/a | n/a |
| Real Estate Agent | verified | verified (3) | verified |
| Construction | verified | verified (2) | verified |
| Property Development | verified | verified (4, one Activity Licence slot, see D8) | verified |
| Building Architecture | verified | verified (2) | verified |
| Interior & Exterior | verified | verified (2) | verified |

## Observations to look at (not changed)
- On the documents screen the accessibility label of a lower tile's upload button was the whole tile text ("Municipal licence. Not uploaded ...") instead of "Choose file". Visually correct; worth a screen-reader check.
- The review screen shows role, masked mobile, business name and documents. It does not list company email or address. The source does not require it; left as is.

## Open decisions still blocking work
Municipal licence expiry (D4), multiple activity licences (D8), reason codes (D9), 30-day re-apply (D10), Agent workspace scope (D5), CR/licence numbers at signup (D3), architecture version (D11). Details are in the audit, section 7.2.

## Missing reference images
SU-05B, SU-05C, SU-07B, SU-07D, rejected/suspended states, SU-10 and Agent activation. See the image brief.
