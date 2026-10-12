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
