# Decisions and source gaps

Labels: **SOURCE-CONFIRMED** (stated by the brief or the existing contract), **DERIVED-UX** (presentation or navigation built from supported data), **PROPOSED-EXTENSION** (shown in mockups, not guaranteed by a contract), **BLOCKED-BY-CONTRACT** (cannot operate until the service supports it).

## What "contract" means in this repository

There is no real API in the app yet. `lib/core/config/backend_mode.dart` sets `kUseDemoBackend = true`; `accountApiProvider` defaults to `UnavailableAccountApi`, and the only data behind the screens is `lib/data/demo/*` plus the fictional mock businesses. There is no OpenAPI client, no project, lead-event or engagement API, and I could not find the Architecture v2.4 / September 2026 addendum or the 100-page blueprint in the workspace. The rules in the brief are therefore the only source for behaviour, and the data layer is a new repository interface (`DevBuildRepository`, `lib/features/devbuild/db_repository.dart`) that the screens call. It has two implementations:

- `DemoDevBuildRepository`: in memory, fictional data, used only while `kUseDemoBackend` is true. It states what the real service would do (status after submit, re-review after editing an approved project, idempotent writes, ownership checks) so the screens can be reviewed.
- `UnavailableDevBuildRepository`: every call fails like an offline request, so every screen shows its error/retry state. This is what ships if the demo switch is turned off before a real implementation exists.

`DbCapabilities` reports what the contract supports. Everything false is shown as unavailable in the UI and never faked.

## Source-confirmed (from the brief)

| Decision | Where |
|---|---|
| Exactly four customer categories: developers, construction, architecture, interior & exterior | `ProType`, `db_discovery.dart` |
| Customer nav stays Home / Explore / Activity / Account; no fifth tab | `db_routes.dart` nests discovery under `/app/explore/...` and workspace under `/app/account/...` inside the existing shell |
| Only approved businesses are public | `DemoDevBuildRepository.professionals`, test `directory rules` |
| Developers appear only with at least one approved project matching the query | same |
| Developer pins use approved project coordinates; other firms use office coordinates | `dbMapDataProvider` |
| Only developers have project create/edit; other roles are blocked in the route guard and in the repository | `DbGuard(developerOnly)`, `_requireOrg` + `hasProjects` |
| Pending, rejected, resubmission, suspended and awaiting-second-approval grants never open the workspace and route to verification status | `workspaceAccessOf`, `DbGuard` |
| Project statuses are mapped from server values; unknown values are kept and never shown as approved | `projectStatusFromServer`, `ProjectStatus.unknown` |
| After submit the UI says "Submitted for review", never "Published" | `DbSubmittedScreen` follows the returned status |
| Metric units for `land_sqm` / `area_sqm` | `ProjectDraft.toPayload` |
| Reviews are shown only when published; averages and counts come from the server | `DbReviewsScreen`, no client-side averaging |
| No review replies, no in-app chat, no CRM statuses | no such control exists |
| Writes carry an idempotency key; the same key never creates a second record | `saveProject`, `resubmitProject`, test `same idempotency key` |

## Derived UX

- Discovery pages sit inside the existing shell so the customer nav stays visible (Explore selected). Workspace pages sit inside it with Account selected. Profile, project detail, gallery, the wizard, status and confirmation pages are full screen with pinned action bars, like the existing property detail.
- Contact: the profile and project pages show a Contact action only when the profile provides a phone or WhatsApp number, and require a signed-in session (same rule as property enquiries). Without a platform dialer/URL plugin in the app, the sheet shows the number(s) with a Copy button and says so. It does not claim a call happened.
- Location filter is governorate level. The wizard uses governorate → wilayat (official divisions, `omanGovernorates`) plus an optional area name and optional coordinates (a complete pair, inside Oman's bounds).
- Wizard: draft state lives in the wizard screen, so values survive Back, step jumps from the review and the unsaved-changes prompt. Saving a draft is a top-bar action; Back/Continue are in the bottom bar like the reference.
- Edit flow reuses the wizard prefilled from the stored project and shows the current status. Approved projects use "Submit changes for review" and say that changes go back to review.
- Review-tools shortcut: with `--dart-define=REVIEW_TOOLS=true`, the project status page shows "Simulate: approved / changes requested / rejected" buttons that call `DemoDevBuildRepository.debugDecide`. With `--dart-define=REVIEW_SESSION=developer|construction|architecture|interior|pending|second|rejected` the demo starts signed in as that business. Both are off in a normal build.

## Proposed extensions and what was done

| Mockup element | Decision |
|---|---|
| Project description, cover image, highlights, amenities, estimated completion, number of units, development status | Not built. Wizard step 1 and step 3 say they arrive when the project service supports them. Nothing is sent. |
| Stats like "10+ years", "500+ homes delivered", profile views, growth, "2.4K views" | Not built. The profile shows only rating/count (server-derived), approved project count and the approved badge. |
| "Message" button on the profile | Not built (no chat). Contact only. |
| Schedule a Viewing on a project | Not built. Shown only if a project links to an eligible listing; `DbProject` carries no such link. |
| Project gallery with counts like "48 images" | Route and viewer exist. It opens only when approved media exists (`DbProject.mediaUrls`, empty today) and otherwise shows an explicit empty state. Counts come from the list. |
| Pin placement, address search, "use my location" on the location step | Not built (the map widget has no pin API; no location plugin). Optional coordinates are manual. A non-interactive preview map shows the entered point or the governorate area. |
| Street, project address, nearby landmarks | Not built. Not in the project model. |
| Lead messages, budgets, statuses (New / In Progress / Responded / Closed), unread counts, "Mark as responded" | Not built. Contact activity shows channel, target and time only. |
| Portfolio: counts, views, Add Project, categories, media library | Screen exists and shows approved profile media if any. Add is disabled with the reason. Marked PROPOSED-EXTENSION on screen. |
| Dashboard KPIs (Active Leads, Profile Views, rating tile) | Not built. Project counts by status are derived from the returned projects. |
| Engagement project value, dates, service type | Not built. Screen shows the confirmation state and the 14-day / 60-day rules from the brief, and reads state from the API when it exists. |

## BLOCKED-BY-CONTRACT (needs a decision or an API before these can be real)

1. **Project service**: create/update/resubmit/list endpoints, the exact status values, reviewer feedback shape, and project media and amenities. Until then the demo repository stands in.
2. **Lead-event listing** (`lead_events`): logging taps and listing them for the business. `caps.leadEvents` is false; the workspace shows an unavailable state and the customer-side contact sheet logs nothing.
3. **Engagement confirmation** (`professional_engagements`): list and confirm. `caps.engagements` is false; the list and detail screens show an unavailable state. The screens are implemented and tested against a repository that reports the capability.
4. **Company portfolio**: read of approved work and any write/publish flow. `caps.portfolio` is false.
5. **Published reviews with text**: the demo has a few fictional reviews for one business only. Real review bodies, the 60-day window and moderation states come from the service.
6. **Profile edit**: the endpoint and which fields are material. The demo reports "awaiting review" for every save, which is the cautious assumption.
7. **Approved logo / media upload** for profiles and project media upload rules (type, size).
8. **Wilayat Arabic names and area lists** under each wilayat. Governorate names have Arabic copy (draft); wilayat names stay in English.
9. **Platform actions**: dialing, WhatsApp deep links, directions, sharing and "use current location" need plugins the app does not include.

## Other notes

- Arabic copy for this module is draft and needs native review.
- I did not touch the backend, Firebase, infrastructure or the admin console.
- Brokers and maintenance providers stay in the existing `/professionals` directory; they are not part of Development & Building.
- The mock business "Namaa Construction" is both a developer and a builder in the shared mock data. In the directory it appears as a developer (it has approved projects); a real organisation has one professional type.
- Pre-existing formatting noise: running `dart format` over some directories reformatted unrelated files (`entry_strings.dart`, `viewing_strings.dart`, `app_shell.dart`, `demo_backend.dart`, several tests). Those changes are formatting only and are left uncommitted.

## Stabilisation decisions (2026-10-12)

- **Enquiries and offers are local.** No enquiry or offer service is in the contract, so both are stored on the device and the result page says they were not delivered. If delivery is wanted, the backend needs lead and offer endpoints; none were invented.
- **Reviews have no form.** They depend on engagements that both sides confirm, which the backend does not expose yet (see engagements blocker above).
- **Old unreachable screens were deleted** rather than restyled. Anything deleted is recoverable from commits before `8cce211`.
- **Demo phone numbers** are generated for the demo repository only and must not be mistaken for data.
- **Formatting noise** in six files (`entry_strings.dart`, `viewing_strings.dart`, `demo_backend.dart`, and three tests) is a stat-only difference with no content change; they are left untouched.
- **Proposed, not built:** in-app chat, review replies, CRM statuses and a fifth tab remain out of scope.
