# Role home implementation log

## 2026-10-16

Nothing was reset, checked out or pushed. Branch `main`, HEAD `ff12824`. All work is uncommitted.

### Added (new files)

| File | Purpose |
|---|---|
| `lib/features/role_home/role_home_model.dart` | `HomeRole`, `HomeWorkspace`, `resolveHome` (pure), `homeWorkspaceProvider`, `homeResolutionProvider` |
| `lib/features/role_home/role_home_screen.dart` | The Home tab: resolves the session, skeleton while loading, crossfade between homes |
| `lib/features/role_home/role_home_widgets.dart` | Page frame, once-only staggered entry, header with the real logo, workspace switcher, status banner, tile, numbered cell, row, photo panel, chip |
| `lib/features/role_home/home_agent.dart` | Agent workspace |
| `lib/features/role_home/home_construction.dart` | Construction home |
| `lib/features/role_home/home_developer.dart` | Developer home with status pipeline |
| `lib/features/role_home/home_studio.dart` | Architecture and Interior & Exterior homes |
| `lib/features/role_home/role_home_strings.dart` | English and draft Arabic copy |
| `test/role_home_test.dart` | 97 tests |
| `docs/role_home_pages/*` | this log, audit, interaction matrix, readiness checklist |

### Changed (existing files)

| File | Change |
|---|---|
| `lib/features/workspace/aq_app_shell.dart` | Home tab shows `RoleHomeScreen` |
| `lib/features/workspace/aq_home.dart` | `AQHomeScreen` takes an optional `topSlot`; `AQSectionHeader` stacks its action under the heading at large text (fixes an overflow in Arabic at 200%) |
| `lib/core/localization/flow_strings.dart` | merges the role-home strings; agent activation copy no longer promises listing creation or viewing management (now "See your listing status when the listing service is connected" and "Open your viewing activity") |
| `lib/features/flow/screens/approval_screens.dart` | activation button opens the Home tab for every approved role |
| `lib/data/demo/demo_backend.dart`, `lib/features/devbuild/db_repository.dart` | the demo keeps the sign-up service type so the Interior & Exterior home shows the real value |
| `lib/data/demo/demo_providers.dart` | QA sessions: `agent`, `agent-pending`, `buyer`, `suspended`, `resubmission`; session can be picked at run time with `?session=` (QA flag builds only) |

### Behaviour

- Role comes only from the session grant. Anything not approved gets the buyer home plus a status banner linking to `/verification`.
- Approved agent: Buyer / Agent switch on both homes; opens in the agent workspace; the choice lasts for the app session.
- Customer four-tab navigation is unchanged for all roles.

### Bugs found and fixed on the way

- Buyer home section header overflowed at 200% text in Arabic.
- Several shared widgets overflowed in tests at 320 px or large text (photo panel, switcher, section action, agent tiles, architecture index); all now size from content.
- Agent tiles broke words mid-word at 320 px; single column on narrow screens.

### Verification

See the readiness checklist: 351 tests passing, 0 analyzer errors, fresh production build, Chromium walk of all homes (five widths, dark, Arabic, interactions, guard sessions).

### Not done

Business tabs; real listing, contact and engagement services; Invest transaction type; native Arabic review; committing or pushing.
