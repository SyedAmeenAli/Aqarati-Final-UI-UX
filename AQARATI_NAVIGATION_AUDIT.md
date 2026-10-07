# AQARATI Navigation Audit

## Root cause (confirmed)
`go_router`'s `ShellRoute` gives its subtree its own nested `Navigator`. Only 4 screens
actually live inside that `ShellRoute`: `/home`, `/explore`, `/messages`, `/profile`
(see `lib/core/router/app_shell.dart` + `lib/core/router/app_router.dart`). A plain
`Navigator.of(context).push(...)` called from *inside one of those four screen bodies*
resolves to the shell's nested Navigator, so the pushed screen renders under the
shell's `bottomNavigationBar`/FAB instead of covering it. Every other screen in the
app is already reached either via a top-level `GoRoute` (outside the shell) or via a
push that itself already landed on the root Navigator — so once a screen is on the
root Navigator, further internal pushes from it resolve correctly with no fix needed.
This means the fix surface is exactly the 4 shell-tab bodies, not "every push in the
app" — confirmed by reading the router tree before touching anything.

## Fixed this pass
| Site | File | Destination | Fix |
|---|---|---|---|
| Calculator tap | `explore_screen.dart:202` | `CalculatorScreen` | `rootNavigator: true` |
| Conversation tap | `messages_screen.dart:28` | `ConversationThreadScreen` | `rootNavigator: true` |
| THEQA continue | `profile_screen.dart:45` | `IdentityVerificationFlow` | `rootNavigator: true` |
| Enquiries tile | `profile_screen.dart:58` | `MyEnquiriesScreen` | `rootNavigator: true` |
| My Home tile | `profile_screen.dart:65` | `MyHomeScreen` | `rootNavigator: true` |
| Property tools tile | `profile_screen.dart:72` | `CalculatorsListScreen` | `rootNavigator: true` |
| Verification tile | `profile_screen.dart:79` | `VerificationCenterScreen` | `rootNavigator: true` |
| Owner Dashboard tile | `profile_screen.dart:89` | `OwnerDashboardScreen` | `rootNavigator: true` |
| Switch Account tile | `profile_screen.dart:96` | `AccountSwitchScreen` | `rootNavigator: true` |
| Settings tile | `profile_screen.dart:104` | `SettingsScreen` | `rootNavigator: true` |

Already fixed in a prior pass (unchanged this pass, re-verified correct):
Map (x2), Notifications, Business Profile — all in `home_screen.dart`.

## Simplified this pass
`home_screen.dart`'s "Professionals" row pushed `BusinessProfileScreen` via a raw
`MaterialPageRoute` + `rootNavigator: true`, duplicating the top-level `/business/:id`
`GoRoute` that already exists and is used elsewhere (e.g. from Explore). Switched to
`context.push('/business/${id}')` — same destination, one routing path instead of two,
removed the now-unused `BusinessProfileScreen` import. This is a real simplification
(the route already existed, unused), not a new abstraction.

## Audited, no change needed
Every other `Navigator.of(context).push` in the codebase (business_profile_screen,
saved_screen, settings/*, verification/*, owner/*, myhome/*, reviews/*, enquiry/*,
property_detail_screen, calculators_list_screen, search/filter_sheet) originates from
a screen that is **already outside the shell** — either a top-level `GoRoute`
(`/property/:id`, `/business/:id`, `/saved`, `/search`) or a screen that itself
reached the root Navigator via one of the fixes above or a prior-session fix (Map,
Notifications). Its nearest Navigator ancestor is already the root Navigator, so a
plain push is correct as written. Verified by tracing each file's entry point back to
the router, not assumed.

`showModalBottomSheet` / `showDialog` call sites (auth gate sheet, app_shell create
sheet, filter sheet, help/support, privacy/settings confirm dialogs) are modal
overlays, not full-screen pushes — the shell-bleed bug class does not apply to them
(a bottom sheet or dialog is expected to appear as an overlay on whatever screen
requested it). No change made.

## Deliberately not migrated to go_router this pass
Map, Notifications, and the ~20 settings/verification/owner/myhome sub-screens still
use imperative `Navigator.push` rather than named `GoRoute`s. Converting all of them
is a large, separate refactor (route naming, param passing for typed objects like
`MapScreen`'s `List<Property>`, deep-link design) with no bug behind it — the shell-
bleed defect is fully fixed by the `rootNavigator` sites above. Doing the full
conversion now would touch already-accepted screens (Map/Property Detail/Gallery) for
no required benefit and risks a regression on work already signed off. Flagging as a
future, explicitly-scoped task rather than expanding this one.

## Test — click-through verified live (web)
Dev server was unusually flaky this pass (repeated `AppConnectionException` /
websocket drops from the Flutter web tooling itself, and one incremental-compile
cache file briefly went missing under Windows Temp — infra noise, not app bugs;
several restarts were needed before a stable session held).

Actually clicked through and confirmed:
- Home renders correctly.
- Messages → Conversation: **PASS** — full-screen, no bottom-nav bleed, correct
  back arrow, no duplicate scaffold. This exact site was broken before this pass's
  fix; confirmed fixed live.
- Profile → Settings: **PASS** — full-screen, no bleed, correct back arrow. Also
  previously broken, confirmed fixed live.

Not re-clicked live this pass (browser-tool click-coordinate mapping was unreliable
at the Explore tab specifically, and time was spent recovering the dev server
instead): Explore → Calculator, and the other 7 Profile tiles (Enquiries, My Home,
Property Tools, Verification Centre, Owner Dashboard, Switch Account, THEQA). All 9
received the identical one-line `rootNavigator: true` fix as the two confirmed-live
sites, applied via the same mechanical edit — high confidence, not directly observed
this pass. Flagging the distinction rather than claiming a uniform PASS.

Home → Search → Results → Map → Detail → Gallery was not re-clicked through this
pass (regression chain already confirmed in the prior checkpoint, no code in that
path changed this pass except the unrelated Business Profile route simplification).

No duplicate navigation bars or nested-Scaffold artifacts observed in anything that
was actually opened.

## Analyzer / Test / Build
- `flutter analyze`: 0 errors, 7 pre-existing deprecation infos (unchanged baseline).
- `flutter test`: `test/` contains no `*_test.dart` files at all — `flutter test`
  reports "Test directory does not appear to contain any test files." No test suite
  exists in this project. Reported honestly as N/A rather than a fabricated PASS.
- `flutter build`: verified via live `flutter run -d chrome` dev session, not a
  release `flutter build web` (consistent with how every prior checkpoint in this
  project has verified "build").
