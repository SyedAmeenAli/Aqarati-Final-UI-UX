# Implementation log

Chronological, concise. Commands and results are what was actually run.

## Starting state

- Repository: `aqarati-app` (Flutter, Riverpod 2.6, go_router 14). `git status` was clean at `7051b2f`.
- Existing: AQ design system (`lib/core/aq`), customer shell with four tabs, Home/Explore/Properties, search, map, professionals directory (brokers, maintenance and the four D&B categories mixed), business profile, saved, calculators, viewing flow, sign-up / OTP / documents / verification flow with a demo backend.
- Not present: any project, lead-event, engagement or portfolio data layer; any real API; the architecture addendum and blueprint documents.

## Steps

1. Read the three master prompts (the `.md` and the two `.txt` copies are the same task; the `(2).txt` adds the "every control must work" and animation sections, which are what was followed). Extracted `business and development.zip` (45 PNGs) to a scratch folder, opened the key references, and wrote `REFERENCE_IMAGE_INDEX.md`.
2. Audited the repo: found the data and role seams (`meProvider`, `MeSession.purpose/grant/stage`, `GrantState`, `ReviewStage`, `AQStatusBadge`, shell nav logic, map widget, `aqRequireSession`).
3. Domain and data layer: `db_models.dart` (types, statuses, draft and validation, Oman governorate/wilayat taxonomy), `db_repository.dart` (interface, demo and offline implementations, capabilities, providers, access gate).
4. Customer discovery screens and routes (#59–#67), Explore/Home/search entry points re-pointed at them.
5. Workspace: guard, dashboard, My Projects, status and feedback, wizard, confirmation, company profile, contact activity, reviews, engagements, portfolio (#68–#86).
6. Strings in `db_strings.dart` merged into `FlowStrings` (English plus draft Arabic), all keys checked by script against usage.
7. Tests: `test/devbuild_discovery_test.dart`, `test/devbuild_workspace_test.dart`.
8. Browser QA on a release web build at 393×852 (light, dark, Arabic) and a real end-to-end run in Chromium: dashboard → add project → five steps → submit → confirmation → list → status.

## Bugs found by the work and fixed

| Found by | Bug | Fix |
|---|---|---|
| Widget test | Home carousel overflowed with a fixed height | `IntrinsicHeight` row instead of a fixed-height list |
| Widget test | Dashboard Column was not scrollable (guard returned a bare Column) | wrap in `DbShellPage` |
| Widget test | `AQStatusBadge` overflows at wide fonts | `DbFit` wrapper |
| Widget test | Review row and star strip overflowed at 2× text | `Wrap` and `FittedBox` |
| Widget test | Top-bar "Save draft" overflowed at 2× text | moved into the step header row |
| Widget test | Tests hung on the demo repository's simulated latency | `lag` parameter, tests use zero |
| Browser QA | Submit spun forever on web: `Random().nextInt(1 << 32)` is `nextInt(0)` under dart2js | `nextInt(0x7fffffff)`, key creation moved inside `try` |
| Browser QA | A draft with no location showed a stray "," and an empty pin row | `locationLabel` ignores empty parts; rows hidden when empty |
| Browser QA | "1 projects" | singular string |
| Browser QA | Status filter pills wrapped to two rows | horizontal scroll row |
| Review | Clipboard failure was reported as success | failure shows "Couldn't copy" |

## Validation commands

| Command | Result |
|---|---|
| `flutter analyze` | no errors; one pre-existing warning (`_Action` unused in `aq_home.dart`) |
| `flutter test test/devbuild_discovery_test.dart` | 29 passed |
| `flutter test test/devbuild_workspace_test.dart` | 51 passed |
| `flutter test` (whole suite) | 158 passed |
| `flutter build web --release --pwa-strategy=none --dart-define=REVIEW_TOOLS=true --dart-define=REVIEW_SESSION=developer -o build/web_qa` (and `AQ_THEME=dark` to `web_qad`) | built |

## Not done / not verified

- No device, VoiceOver or TalkBack testing. No haptics testing.
- The native Google map and its pins were not seen (needs `GOOGLE_MAPS_CONFIGURED` and a key); on web the embed shows the region, not pins.
- Arabic copy is draft and needs native review; wilayat names stay in English.
- Items listed under BLOCKED-BY-CONTRACT in `DECISIONS_AND_SOURCE_GAPS.md` are screens with honest unavailable states, not working features.
- The work was done by Claude alone. The workspace instructions ask for a Claude + Antigravity split on substantial work; I did not run the Antigravity wrapper for this task.

## Stabilisation pass (2026-10-12)

Goal: close the three known browser bugs with tests, audit the Git tree, and regress screens #59–#86 in a real browser. Everything below was run; nothing is claimed that was not.

### The three browser bugs

| Bug | Root cause | Fix | Evidence |
|---|---|---|---|
| Submit spun forever on web | `Random().nextInt(1 << 32)`: dart2js folds `1 << 32` to `0`, so `nextInt(0)` throws `RangeError: max must be in range 0 < max ≤ 2^32, was 0`, and the key was built outside the `try`, so `_busy` never cleared | `dbNewIdempotencyKey` uses `nextInt(0x7fffffff)`; key creation inside the `try`; `_save` now returns immediately while a request is in flight; a server validation error drops the key so the next attempt is a new request, a network failure keeps it so a retry is the same request | Reproduced in dart2js with a 6-line program (VM prints a number, `dart compile js` build prints the RangeError). Tests: key format/uniqueness (5000), success, failure then retry with the same key and one project, three taps while in flight send one write, repository replays a repeated key. Browser: full create→submit journey passes in Chromium at 320, 360 and 393 px. |
| Stray comma / empty pin row for a draft with no location | `locationLabel` joined empty parts | `DbProject.locationLabel` skips blank parts; location rows are hidden when empty | Tests: empty, each partial combination, complete, all 8 combinations never start/end with or double a comma, status page with a bare draft shows no comma. Browser: draft with no location viewed. |
| Wizard progress on narrow phones | Reproduced by building the wizard at 320, 360, 393 and 412 px: the five circles, connectors and caption fit and are accurate at every width; the real defect was the bottom bar, where "Save & continue" wrapped to two lines beside Back at 360 | Bottom bar stacks (primary above Back) below 380 px | Tests: 4 widths × 2 text scales × 5 steps assert five distinct non-overlapping circles inside the screen and the full caption `Step n of 5: <name>`. Browser: screenshots of steps 1–2 at all four widths. |

### Other defects found by the browser regression

| Defect | Fix |
|---|---|
| `Add new project`, `Edit project` and the project menu icon loaded `assets/icons/aq/plus.svg`, `edit.svg`, `more.svg`, which did not exist (404, invisible icon) | Added the three SVGs in the existing icon style; test scans devbuild sources and fails if any icon name passed to an AQ component has no asset |
| Choice sheets opened from pages inside the shell sat under the glass tab bar | `showAQSheet` gets an optional `useRootNavigator` (default false, no change for existing callers); all devbuild sheets use it |
| D&B pages showed the Home/Explore property-area chip in the hero, a second "location" control that does not filter the directory | `AQHero(showLocation:)` (default true); hidden on the three discovery pages |
| Two "Add new project" buttons on an empty My Projects page | Removed the duplicate |
| Result cards broke "Construction" mid-word at 320 px | Narrower photo below 360 px |
| Contact sheet wrapped a phone number onto three lines at 320 px | Number scales down on one line |

### Git audit

- At the start of the pass `git status` listed 12 modified files. For each, `git show HEAD:<file>` and the working copy were both run through `dart format`; all 12 were identical, so all 12 were formatting only. A byte-for-byte backup and a patch were made first (scratch folder), then the 12 files were restored from `HEAD`. `git diff --quiet` is clean; `git status` can still list them because of a CRLF stat-cache quirk on this machine.
- Commits `add5038`, `a0e37c7`, `5c5ac58` contained formatting noise in `flow_strings.dart` (≈990 lines) and `app_router.dart` (≈390 lines). Formatting both parent and HEAD versions and diffing showed the real changes are 3 lines and 3 lines. The history was not rewritten. A new commit restores the pre-existing formatting and keeps only those functional lines.
- Nothing was pushed, reset or force-pushed.

### Verification run in this pass

See the table at the end of `SCREEN_READINESS_CHECKLIST.md` for browsers and viewports, and the final report for counts.
