# AQARATI final gap audit (second pass)

Date 2026-10-28. Branch `main`, HEAD `e0a6bc3`. Nothing is committed, pushed or deployed. Backend, database and `aqarati/` untouched.
This replaces the first audit. Where the client's latest instruction differs from older notes, the latest instruction wins.

States: **CV** Complete and verified · **IV** Implemented but not fully verified · **P** Partial · **M** Missing · **BA** Blocked by a missing API · **BD** Blocked by a specific unresolved product decision.
"Verified" means walked in headless Chromium (Playwright, accessibility tree) and/or covered by tests. Nothing is connected to a real service; everything not marked otherwise is demo-only and labelled.

## Results of this pass

| Gate | Result |
|---|---|
| `flutter test` | 782 passed, 0 failed |
| `flutter analyze` | 57 items, no errors. The earlier baseline was 41. The extra 16 are `curly_braces` lints created when I ran `dart format` over all of `lib/core` by mistake (22 untouched files re-wrapped). Reverting them was blocked, so see "Cleanup you should run" |
| Builds | `build/web` (customer), `build/web_review` (QA), `build/web_admin` (admin): each has `AssetManifest.bin`, `FontManifest.json`, `main.dart.js`; no admin or QA sample code in `build/web` or `build/web_admin` |
| Browser checks | Playwright against the QA bundles; result files `docs/readiness/evidence/browser/j*_results.json`, screenshots beside them |

## Priority 1: sponsored banner (corrected)

The app-wide `AQBannerFrame` is **removed**. The banner is now mounted in exactly one place: the User to Shop Home, passed to `AQHero(belowHeader:)` so it sits under the header row (logo, location, account) and above the greeting and hero. A test scans `lib/` and fails if anything else mounts `SponsoredBannerSlot`, and the admin console never mounts the live slot.

- Size: a compact card, fixed **92 px** (thumbnail, `SPONSORED · name`, one-line title, one-line body, "Learn more"), text capped at 120 %, one line each so a rotating ad never moves the page; on screens under 350 px wide the sponsor name and the button word give way to the title.
- Empty state: no banner and **no space** (the slot owns its own padding). Verified: with no ads the customer Home differs from the deployed approved build only where the new `?` sits (0.8 % of pixels).
- Admin preview: `SponsoredBannerView`, the same widget, shown only inside the console form.
- Browser (widths 320, 360, 390, 412, 430): exactly one banner, 92 px tall, below the header; rotation keeps banner and hero still; **24 other screens show none** (Explore, Activity, Account, categories, results, map, property details, viewing booking, Development & Building, maintenance, notifications, login, entry, delete account, agent and company workspaces, all five other role homes). The position relative to the hero is confirmed by screenshot (`j10_home_*.png`) and by `test/home_banner_test.dart`, not by a DOM measurement.

## What was built in this pass

| Item | State | Routes and components | Evidence | Still needs |
|---|---|---|---|---|
| Contextual `?` explainer | CV | `AQHelpButton` / `showAQHelp` (`lib/core/aq/aq_help.dart`) on the Home "Browse Properties" header and the property types screen | 5 widget tests (open, close, selection kept, label, Arabic RTL, 200 % text); browser: opens, closes to the same Home. Found and fixed: the sheet's button sat under the bottom nav, now on the root navigator | Arabic copy is draft |
| Buyer profile | IV | `/app/account/profile`, `/edit`; one new row on Account | 8 tests; browser: empty, validation, failed save keeps typing, retry, cancel asks first. Editable: first and last name only; phone and email are verified identity, shown read-only | Profile API. Saves are kept on the device and labelled |
| Maintenance provider invitation and workspace | IV | `/provider/invite`, `/provider`, `/provider/requests/:id`; `provider_repository.dart` | 18 tests; browser: invalid, expired, used, valid invitation; setup; under review; QA verify; request detail; failed confirm never shows confirmed. **Open issue**: in the browser the Try again after that failed confirm did not bring the request back, while the same flow passes in `provider_workspace_test` | Invitation, verification and request APIs. No public provider signup. No calendar or timing promise |
| AqaratiBroker | IV | `/broker`, `/broker/list`, `/broker/:id`; Home card and Explore banner now open it | 9 tests; browser: intro (badge meaning, "not Aqary e-Broker"), directory, profile, Call opens `tel:` and claims no outcome, listing → existing viewing request, no phone / not found. Public demo has **no brokers** (none invented); QA build adds two labelled samples | Broker directory and approval API; the extra vetting is open (decision list) |
| Engagements (client side) | IV | `/business/:id/engage`, `/engagements`, `/engagements/:id`; request button on professional profiles | 20 tests; browser: rules shown, request, waiting, professional confirms, review offered. Edge states: duplicate, related account, unavailable, error with retry, expired (14 days), declined, cancelled | Engagement API. Kept apart from viewings and maintenance |
| Reviews | IV | `/review/:kind/:id`, `/reviews`, report sheet; the old explainer screen is no longer used | Browser: refusals, 10 character rule, preview, failed send keeps text, pending moderation (never "published"), publish, edit locked until allowed, edit re-enters moderation. Report sheet: reason required, failure, sent, already reported (tests; a Report review action is on each review of a professional, but the demo roster has no reviews, so the sheet was not opened in the browser) | Review and moderation API; report reason codes are a front-end proposal |
| Customer Aqary e-Broker | IV | `/sell`, `/sell/new`, `/sell/:id`, `/sell/:id/edit`; entries on the property types screen and the profile | 15 tests (rules, duplicate deed, fee acceptance required, resubmission only when changes were requested, foreign submission denied, failures change nothing). Browser: intro with the approved sentence and "nothing is charged or paid in the app", empty-form errors. **The filled form, failed send and resubmission were not driven in the browser** (long form defeated the script); tests cover them | Listing API. **Decision 26** (`aqarati/docs/decisions/open-decisions.md`): proposed "one disclosed rate up to 2 %, fixed per listing at approval; offline invoice", owner Founder, with brokerage licensing on hold. The app shows only "Aqary Real Estate fees will apply up to 2%", records acceptance, calculates nothing, takes no payment. Only the rate, invoice and approval-time fixing are undecided; they need no screen here |

## The seven confirmed features (unchanged routes; re-checked)

| Feature | State | New this pass |
|---|---|---|
| Agent My Listings | CV (demo) | pause blocked by the contract (service must add a pause operation); not re-driven |
| Agent Leads, development enquiries, service requests | CV (demo) | **failure state walked**: a failed Confirm shows "Its status did not change", status stays Requested, retry confirms |
| Admin verification | CV (demo) | **failure state walked**: a failed decision says nothing was changed; the same decision then goes through |
| Admin moderation and e-Broker | CV (demo) | failure state covered by tests only |
| Admin Ads & Sponsors | CV (demo) | **Resume, Move up, Move down now walked in the browser.** Root cause was in the accessibility tree: the action cell was one merged node with the row's full box, so a click opened the editor. Fixed with a container for the action cell and stable keys; also fixes assistive technology reaching the buttons. Create, validate, preview, submit, approve, pause, resume, reorder, live-edit warning: 16 checks |

## Six public roles (Priority 8)

`j11_signup.js`, 6 roles × 8 checks, all passing: the form opens for that role; an empty first step is refused; going Back keeps what was typed; the path reaches its end state (User to Shop: "Your account is active"; the five business roles: "Application submitted … Under review", not approval); the right screen follows; **approved-only screens stay closed** while under review (agent listings refused); sign out returns to the start; afterwards Home is the guest Home (guests may browse by design) with no workspace and no banner. Limits: documents were marked received with the QA "mark all documents received" control, not uploaded; the OTP is the demo code. Session expiry and real browser Back history were not exercised.

## Network failures, accessibility, responsive (Priority 10)

Walked with a QA-only switch (`localStorage.aq_fail = 1`, read only in `REVIEW_TOOLS` builds, `lib/core/config/qa_faults*.dart`): profile save, review send, provider confirm, lead viewing answer, admin verification decision. Not walked: listing save, pause, moderation, ad create or reorder (tests only). Accessibility fixes found by driving the tree: admin dialogs (Close and code field unreachable), the Ads action buttons, the help sheet hidden under the bottom nav. No screen reader, keyboard-only or device pass was done; the accessibility tree is not an assistive-technology evaluation. New screens are in `test/new_screens_matrix_test.dart` (narrow widths, dark, Arabic RTL, 200 % text) alongside the earlier ones; Home with the banner is included.

## Reference assets (Priority 11)

`REFERENCE_ASSET_INDEX.csv` (76 boards) and the notes below. **Classification used the file names and the pack's own index; I did not review the 76 images panel by panel.** Findings that matter: the "Members & Permissions" and organisation-members boards conflict with the architecture (single-owner business profiles, staff roles removed), so they were not built; 39 engagement and review boards repeat one flow with generated sample ratings and wording, which must not be copied (a rating before a confirmed engagement, or an instantly published review, breaks the rules); mixed boards are not specifications.

## Master brief: remaining state

| Item | State |
|---|---|
| Notification preferences and push | BA (inbox is built) |
| Real authentication, session restore, guards | BA |
| Listing pause and resume | BA (contract has no operation) |
| Admin permission matrix (Ch. 47) | BD (role proposal in the console) |
| e-Broker rate, invoice and fee fixing | BD (decision 26) |
| Members and permissions (organisation) | BD (conflicts with the architecture) |
| Screen-reader, keyboard-only, real device | not done |
| Dark and Arabic of the new screens in a browser | IV (layout matrix only) |

## Cleanup you should run (my mistake)

I ran `dart format` over `lib/core` once and re-wrapped 22 files I had not edited. These files differ from `HEAD` only by formatting; restore them if you want the diff clean:

```bash
git checkout -- $(cat docs/readiness/FORMAT_NOISE_FILES.txt)
```

(The list is in `FORMAT_NOISE_FILES.txt`.) After that `flutter analyze` returns to 41.

## APIs required later

Listings (incl. pause and resume), leads and host-side viewing answers, ads (`/ads`, events, admin), admin auth and queues, e-Broker submission and review, broker directory, maintenance provider invitation and requests, engagements and reviews (confirm, moderation, report), buyer profile, notification preferences, real authentication.

---

# Third pass (2026-10-28): provider retry, e-Broker walk, entry experiences, Properties flow

Nothing is committed, pushed or deployed. Backend and database untouched.

| Gate | Result |
|---|---|
| `flutter test` | 820 passed, 0 failed |
| `flutter analyze` | 55 items, no errors (earlier baseline 41; the extra items are `curly_braces` lints from the format-noise files, not individually recounted after this pass; none are in the new files) |
| Builds | `build/web`, `build/web_review`, `build/web_admin` complete; each has AssetManifest and FontManifest; no QA sample code in `build/web` or `build/web_admin` |
| Browser | `j14` provider retry, `j15` e-Broker walk (all steps pass), `j16` entry + Home grid + Properties flow (43 checks pass), `j10` banner exclusions (36 pass). Results in `docs/readiness/evidence/browser/j14..j16_results.json`, screenshots beside them |

## Provider "Try again" (Complete and verified in browser)

The earlier "open issue" had two causes. The old script hard-coded the retry check as a failure and never tapped the button, and the unit test covered a different case (a failed load, not a failed answer). Reproduced for real, two defects found and fixed:
1. `AQButton`, `AQTextButton`, `AQIconButton` declared a button with `excludeSemantics: true` but no tap action, so a screen reader or keyboard activation could not press any of them (an app-wide gap). Added `onTap`. `AQSlideSwitch` had the same gap; fixed.
2. `AQErrorBanner` wrapped message and button in one live-region node, so the retry button was not a separate target. The live region now wraps only the message.
3. A failed confirm no longer blanks the page when the re-read also fails; the request stays as shown, an error with its own Try again repeats the same operation, busy state blocks double taps, a conflict still re-reads.

Tests added in `provider_workspace_test.dart` (5): keep state and retry, second failure shows no confirmed state, whole connection down then back, retry answers a screen-reader tap (this one failed before the fix), repeated taps run once. Browser: failed confirm, retry while still failing, retry after recovery, confirmed.

## Customer Aqary e-Broker walk (Complete and verified in browser, demo only)

Entry from the Properties types screen, type-by-market selection, owner documents, wrong deed number refused, photo add/remove, fee sentence "Aqary Real Estate fees will apply up to 2%" only, submit refused until accepted, failed send (answers kept, "Nothing was submitted"), retry, in review and hidden from buyers with acceptance recorded, QA reviewer asks for changes, edit form pre-filled, fee notice must be accepted again, failed resubmission, resubmitted, no edit while in review. Not walked: duplicate deed (tests only). Open decision 26 unchanged (rate, offline invoice, fixing at approval); no payment, no calculation.

## Entry experiences, Home, Properties (implemented, browser verified)

- Entry: User to Shop / Real Estate Agent switch (existing `AQSlideSwitch`). Create an Account opens `/signup/user` or `/signup/agent`; Login opens `/login?as=...` with a line naming the experience; "Other businesses: create an account" keeps the six-role chooser. The choice is context only: after sign-in `routeForSession` decides from the account's own role and grant (also for Google/Apple, which used to go straight to Home); if the account does not match the chosen door, a message says so. QA stand-ins unchanged (`?session=` only in REVIEW_TOOLS builds).
- Home: 2x3 grid of six cards directly under the search bar (Properties, Development, Interior & Exterior Designer, Construction Company, Loan Calculator, Maintenance); all existing Home sections kept. Verified at 320/360/390/412/430, no overflow.
- Properties: `/properties` is now the hub (Buy, Rent, Sell, My Favorites). Buy/Rent open `/properties/categories?tx=` (four categories); a category opens `/properties/types?tx=&cat=` directly; a type opens `/properties/all?tx=&cat=&types=`. Back keeps transaction and category. Sell opens `/sell`; My Favorites opens `/saved` (not category-filtered). No Buy/Sell chooser after a category.
- Taxonomy: Residential Villa, Apartment, Residential Land; Commercial Shops, Offices, Building, Storage, Commercial Land; Industrial Land to invest, Factory; Agriculture Agricultural Land, Farmhouse. Two enum values added (`commercialLand`, `investmentLand`); the rest reuse existing types (Shops = shop, Building = commercialBuilding, Storage = warehouse, Factory = industrial, Farmhouse = farm). Found by test and fixed: Storage was not matched by the Commercial category filter.
- **Unconfirmed product rule: rent eligibility.** The documents do not say which types can be rented. `lib/features/search/browse_taxonomy.dart` treats the four land types as sale only and everything else as rentable, in one list (`kSaleOnlyTypes`). Needs product confirmation.
- Card images repeat (only a few property photos exist), e.g. Shops/Storage share one.

## Not done in this pass (honest list)

Review report sheet in browser, listing/pause/moderation/ads failure walks, the 76-image panel review, keyboard-only/screen-reader/reduced-motion checks, Arabic and dark browser walks of the new screens (layout matrix only), motion timing audit. Agent entry through a real agent account was verified by routing tests (`routeForSession`), not a signed-in browser walk. Existing agent, lead, admin, ads features were not re-walked; their tests pass.

## Format cleanup

Backup: `docs/readiness/backup/pre_cleanup_working_tree.patch` and `untracked_files.tar`. Verified by formatting both sides: 20 of the 22 files are formatting-only (`FORMAT_NOISE_VERIFIED.txt`); `aq_forms.dart` and `aq_primitives.dart` hold real changes and must stay. Restoring is blocked by the permission rule on `git checkout`, so it was not done. Run:

```bash
git checkout -- $(cat docs/readiness/FORMAT_NOISE_VERIFIED.txt)
```

---

# Fourth pass (2026-10-28): demo mode, admin link, login spacing, preview readiness

## Rental eligibility (prototype-based, pending product confirmation)
`kSaleOnlyTypes` in `lib/features/search/browse_taxonomy.dart`: Residential Land and Commercial Land are sale only; Land to invest and Agricultural Land have rental ranges and are offered for Rent; all other types are rentable. This comes from the earlier prototype's configuration, not from an approved business rule, and the architecture documents do not restate it. Confirm against any newer product rule.

## Demo mode (Complete, verified in browser)
`AQARATI_DEMO_MODE` defaults to **false** (`lib/core/config/demo_mode.dart`). Default build: no Skip for Demo on either signup screen, no Skip chips on the purpose screen (browser-checked on a default build). Demo build (`--dart-define=AQARATI_DEMO_MODE=true`): Skip for Demo on User to Shop and Real Estate Agent signup opens that role's home on the simulated session with "Demo mode: no account was created, registered or verified." (browser-checked). The Vercel project was not reconfigured; the link serves whatever the project's own build command produces, which has no demo flag, so the hosted link has no skips. See `ADMIN_ACCESS.md`.

## Admin Console link (Complete, verified in browser)
Under Login on both login variants. On localhost it opened `http://localhost:8081/#/login`, the admin sign-in with its one-time-code step intact. On a hosted build with no `AQARATI_ADMIN_URL` it shows an explanatory sheet. No admin site is deployed; none is claimed.

## Login role pill spacing (Complete, verified in browser and by 20 tests)
Gap 2 px before, 16 px after, at 320, 360, 390, 412, 430 px, both variants. The left-edge leak from the adjacent screen was not reproduced.

## Listing status message (Complete, tested)
The one-time "Sent for review" message now shows only while the listing is still in review. Regression tests: pending to approved, to changes requested, to rejected.

## Browser verification state of the outstanding list
- Verified in browser this pass: listing save, pause, resume, edit failures and retry (`j17`); moderation failure and retry (`j20`); Ads create, submit and review failures (`j21`, first three checks and the retry that follows each).
- Not completed in browser: Ads pause, resume and reorder failures (the `j21` walk stopped after approval; the earlier `j7` walk covers the working path), review-report sheet, duplicate deed number, dark mode and Arabic walks, keyboard-only and reduced-motion checks, the 76-image review.
- Signed-in agent journey: demo-build Skip for Demo opens the agent workspace (browser); the deeper agent flows (listings, leads) were walked in earlier passes and re-run by tests.

## Gates
`flutter test`: 836 passed, 17 skipped (demo-only tests, which run with the define and pass; run `flutter test --dart-define=AQARATI_DEMO_MODE=true test/demo_admin_test.dart test/demo_skip_test.dart`). `flutter analyze`: 55, no errors. Builds `build/web` (default), `build/web_demo`, `build/web_admin` complete with manifests.

## Format cleanup
Still not restored: the permission rule blocks `git checkout`. The 20 files in `FORMAT_NOISE_VERIFIED.txt` are formatting-only (verified earlier) and are committed as they are; they can be restored later with `git checkout <last commit before> -- <files>`.
