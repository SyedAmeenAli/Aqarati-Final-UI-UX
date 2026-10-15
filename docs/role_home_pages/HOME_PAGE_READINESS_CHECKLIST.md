# Role home readiness checklist

Updated 2026-10-16. Demo backend only; no real device, screen reader, haptics, backend or deployment testing. Screenshots are in the session scratchpad (`vw/hw/`), not in the repository.

## Results

| Check | Result |
|---|---|
| `flutter test` | 351 passed, 0 failed (97 in `test/role_home_test.dart`) |
| `flutter analyze` | 0 errors; 42 info/warning items, all in older code (the one raised in the new code was fixed) |
| Production build | `build/web`, built 01:26 on 2026-10-16 from the final source; bundle contains the new home copy |
| QA build | `build/web_review` (`--dart-define=REVIEW_TOOLS=true`), built 01:06; sessions chosen with `?session=<name>` |

## Browser coverage (Chromium, QA build)

| Home | 320 | 360 | 393 | 412 | 430 | Dark | Arabic RTL | Interactions |
|---|---|---|---|---|---|---|---|---|
| Agent | yes | yes | yes | yes | yes | yes | yes | switch both ways, listings note, Viewings to Activity |
| Construction | yes | yes | yes | yes | yes | yes | yes | company profile card opens the editor |
| Developer | yes | yes | yes | yes | yes | yes | yes | Add project opens the wizard, Manage projects opens the list |
| Architecture | yes | yes | yes | yes | yes | yes (Arabic dark too) | yes | index Reviews opens the reviews screen |
| Interior & Exterior | yes | yes | yes | yes | yes | yes (Arabic dark too) | yes | choosing Exterior opens the profile editor |
| Buyer | 393 only | n/a | yes | n/a | n/a | not walked | not walked | banner and switcher cases below |

320, 360, 412, 430 px were captured in light English only. Dark and Arabic were captured at 393 px. The theme and language were switched through the app's own Account tab, not the browser setting.

Guards (Chromium, text checks on the live page): rejected, suspended, resubmission-required, pending and agent-pending sessions all show the buyer home plus the "not approved yet" banner and none of the agent, developer or studio content. The pending banner opens `/verification`. A plain buyer shows no banner. An approved agent shows the switcher. A developer shows Add project.

## Automated coverage (`test/role_home_test.dart`)

- Role resolution: guests, unverified accounts, buyers; each approved company type; every company home distinct; agent default, switch to buyer and back; all unapproved states for every business purpose resolve to the buyer home with the real grant and review stage kept.
- Distinct homes: headlines and hierarchies differ; construction and architecture have no project tools, tenders or bids; interior shows the model's service type for all three values; developer pipeline shows only the owner's records, counts come from data, filters use real status; empty states.
- Agent: working switcher in both directions, honest tiles never navigate, Viewings opens Activity, unapproved agents see no tools and no switcher.
- Guards: every company type crossed with pending, resubmission, rejected and suspended; awaiting second approval stays its own state.
- Rendering: five roles at 320, 360, 412, 430 px in light and dark; Arabic RTL and 200% text; reduced motion; buyer home at 320, 360, 393 px in English and Arabic and at 200% text in Arabic.
- Copy: every new string has English and Arabic; no digits in the copy (no mock figures).

## Per home

| Home | Completeness | Notes |
|---|---|---|
| Buyer | Existing and complete | Now also carries the agent switcher or a status banner. Fixed an Arabic / 200% text overflow in the section header. |
| Agent | Built | Listings and contact activity are honest "not connected" states (no API). |
| Construction | Built | Company-profile home. Contact and reviews depend on APIs that are not connected. |
| Developer | Built on the existing project module | Reuses the wizard, status screens and guard. |
| Architecture | Built | Portfolio publishing gated. |
| Interior & Exterior | Built | Service type is now persisted from sign-up in the demo (it was not before). Portfolio and moodboard gated. |

## Remaining gaps and blockers

- No listing service, contact-event service or professional-engagement service is connected: the agent workspace is mostly explanatory until they exist.
- Profile edit stores nothing in the demo, so bio and location show "Not added yet".
- Own-organisation reviews are not wired to a list on Home.
- Invest is not a transaction type in the model, so the buyer home keeps Buy / Rent.
- Business tabs from the references are not implemented (see the audit).
- Arabic copy is draft and needs native review.
- Not walked in Chromium: other widths in dark or Arabic; the buyer home in dark and Arabic; the status screens that follow submission.
- The approved-agent QA session, `?session=` runtime switching and the extra QA sessions exist only in builds made with `REVIEW_TOOLS=true`.
