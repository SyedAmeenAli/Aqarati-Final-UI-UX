# AQARATI full-product readiness checklist

See `FULL_PRODUCT_SCREEN_INVENTORY.md` for the per-route inventory.

Updated 2026-10-16. Branch `main`, HEAD `5a27396` (pushed). All work since then is uncommitted; a backup patch and file copies were taken first (session scratchpad, `backup_2026-10-16_motion/`, patch reverse-applies cleanly).

**Verdict: a complete, honest front-end demo; not a production release.** Every data and action path runs on in-memory demo repositories (`kUseDemoBackend = true`). No real authentication, session restore, route guards, project, lead, engagement, viewing, listing or profile persistence exists.

Status key. **Verified**: source, automated tests and a browser walk agree. **Partial**: works, with named gaps. **Blocked**: needs a backend contract or a product decision. **Not built**: no source. **Untested**: not exercised here.

## Release gate (this pass)

| Check | Result |
|---|---|
| `flutter test` | 536 passed, 0 failed |
| `flutter analyze` | 0 errors, 41 info/warning items (baseline at the start of this pass: 41; none added) |
| Production build | `build/web`, 18:25 on 2026-10-16 |
| QA build | `build/web_review` (`REVIEW_TOOLS=true`; sessions via `?session=`), 18:26 |
| Browser | Chromium (Playwright) against the QA build; see the interaction matrix. No real device, no screen reader, no live-site test |
| Git | Nothing committed, pushed or deployed in this pass |
| Not run | Repository-wide `dart format` (deliberately: the repo is not formatter-clean and it creates noise) |

## Modules

| # | Module | Status | Evidence | Open items |
|---|---|---|---|---|
| 1 | Signup and verification (six paths) | Partial | Signup to "submitted" walked for five business paths at 393 px light; 28+ signup tests; layout tests | Status, approved and activation screens not reached in a default browser build; Arabic upload and submit not walked; no password blocklist or consent versions; decisions D3, D4, D8, D9, D10, D11 open; no real backend |
| 2 | Account recovery | Partial | Login, forgot and reset screens render at all matrix configurations | Demo auth only; no real email or session |
| 3 | Six role homes | Verified (front end) | 97 role-home tests; Chromium walk, five widths, dark, Arabic, guards | Business data is demo; listing, contact and engagement services absent (honestly gated) |
| 4 | Home and Explore | Verified (layout) | Browser walk; matrix at five configurations; home smoke tests | Property data is mock data (`mock_property_data.dart`) |
| 5 | Global search and results | Partial | `search_filters_test` (11), matrix, browser | Mock data; search groups properties, professionals and maintenance |
| 6 | Four property markets and types | Partial | Residential, Commercial, Agriculture, Industrial tiles and type screen; browser | Buy and Rent only: the model has no Invest type; Sell is the e-Broker flow (not built) |
| 7 | Property results, map, filters, sort, detail, favourites | Verified (layout and behaviour) | `listing_pages_test`, `search_filters_test`, matrix; favourites now persist (see below) | Map is a keyless embed; data is mock |
| 8 | Property contact: enquire, offer, compare | Partial, honest | Both screens say the item is "saved on this device" and "not delivered"; Compare is now a real route | Delivery to owners is not connected (documented) |
| 9 | Aqary e-Broker (selling and fee disclosure) | Not built (decision needed) | No source; fee model is an open decision (item 26) | Needs a product decision and a listing API; never to be merged with AqaratiBroker |
| 10 | Viewings | Partial | Browser: availability, slot, review, "Your request is with the host"; `viewing_logic_test` (6), matrix | Host responses are simulated (QA flag only); no real API; seeded sample viewings exist only in the QA build |
| 11 | Activity tab | Partial | Viewings and Maintenance behind one switch (tests, browser, matrix) | Both lists are demo-backed |
| 12 | Notifications | Partial (in-app inbox) | Inbox built from real viewing, maintenance and verification state, deep links, read state kept on the device, honest empty and error states (tests, browser, matrix) | No push delivery, no preferences: need a service and a product decision |
| 13 | Account and settings | Partial | Language, theme, saved, tools, notifications row with a real unread count, sign out, demo notice, account deletion flow | Deletion endpoint and step-up re-authentication are not confirmed; no buyer profile editing, members or devices |
| 14 | Development & Building (customer side) | Verified (front end) | 75 tests; browser | Demo roster; real directory API absent |
| 15 | Developer project workflow | Partial | Wizard, status, filters tested (40 workspace tests) | Demo repository; no media or amenities contract |
| 16 | AqaratiBroker | Partial | Home card opens the professionals directory | No dedicated programme or vetting flow |
| 17 | Maintenance | Partial (requester side built) | Discovery, provider profile with "Request a booking", request form, review step, send, detail with cancel, list in Activity, status copy for all five states (10 tests, browser end to end) | Provider-side confirm, decline and complete need the provider workspace and an API (QA controls only) |
| 18 | Loan calculator | Verified | `calculator_test` (7), matrix, browser; disclaimer shown | Client-side estimate only, by design |
| 19 | Reviews | Partial | Viewing review entry and an eligibility explainer screen | No write form for business reviews (by design until engagement is confirmed); moderation states depend on an API |
| 20 | Motion system | Verified | 23 motion tests; browser frames; theme fade measured | Tab scroll position not preserved |
| 21 | Arabic / RTL | Partial | 21 main screens at Arabic 360 and 430 px (matrix); role homes; signup | Arabic copy is draft and needs native review; not every screen walked in a browser |
| 22 | Accessibility | Untested on device | Semantics labels, 200% text matrix, reduced-motion tests | No screen-reader or keyboard-only pass |
| 23 | Authentication, session restore, route guards | Blocked | Router has no `redirect` guards (only `/viewings`) | Needs real auth |

## Added in the product-gap pass (2026-10-16, later)

- Maintenance booking lifecycle (requester side), Activity switch, notifications inbox, account deletion flow.
- Every screen opened with `Navigator.push` (gallery, offer, enquiry, business review) now uses the shared transition; no raw platform routes remain (guarded by a test).
- 49 new tests (`product_flows_test.dart`, 24; matrix grew to 130 checks).
- Separate products: the Admin Web Console is not built (the monorepo's `apps/admin-web` holds README files only).

## What the earlier pass fixed (all verified by tests, and in Chromium where noted)

- Eight core routes (property detail, search, saved, calculators, professionals, business) used the platform default transition; all routes now use the shared family (guarded by a test).
- Compare opened through a raw platform route; it is now `/compare`.
- A plain buyer opening `/verification` saw a business-style "Add your documents" status; they are now sent home.
- Layout bugs found by the new matrix: filter bar at 320 px; business profile rows at 200% text; the top-bar action at 200% text; the buyer home section header in Arabic at 200% text.
- "Recent searches" was pre-filled with sample entries that looked like the user's history; it now starts empty.
- Saved properties and recent searches were lost on reload; they now persist on the device (verified: saved, reloaded, still saved).
- A visible DEMO notice (the one the backend-mode contract promises) now appears on the Account tab, the viewing-requested screen and every role home.

## Not verified in this pass

Real devices; screen readers; keyboard-only use; the live site; every screen in dark and Arabic in a browser (layout is covered by the test matrix, not by screenshots); the signup status, approved and activation screens in a default build; real backend behaviour (token expiry, retries, duplicate submission against a server).
