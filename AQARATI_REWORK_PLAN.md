# AQARATI Rework Plan

Ordered by dependency, not by feature glamour. Each phase blocks the next — do not skip ahead.

## Phase 1 — Design system correction (blocks everything)
Files: `core/theme/*`, new `core/widgets/aqarati_card.dart`, `aqarati_sheet.dart`, `aqarati_dialog.dart`, `aqarati_status_pill.dart`, `aqarati_list_row.dart`.
Work: audit token values against actual Figma frames pixel-by-pixel (not from memory); build the missing shared primitives so no future screen touches raw `Card`/`ListTile`/`AlertDialog` again.
Risk: requires the user to re-share crisp (non-filmstrip) reference PNGs per component, not per screen.
Output: a component gallery screen (debug-only route) showing every AQARATI primitive side by side for one-shot visual approval before touching real screens.

## Phase 2 — Core navigation
Files: `core/router/app_router.dart`.
Work: migrate every `Navigator.push` screen into `go_router` as real named paths (nested under the shell where appropriate). Decide once: which screens get bottom-nav persistence vs. full-screen push.
Risk: go_router path collisions with existing `/business/:id` etc.; needs careful `ShellRoute` nesting for tab-preserving pushes (Saved -> Compare, Profile -> Settings tree).

## Phase 3 — Core property journey
Screens: Home, Search Results, Filter Sheet, Property Detail, Gallery, Map.
Rebuild `PropertyCard` first (Phase 1 output) then re-point all 4 usages at it. Requires real property photos — asset brief already delivered to user (152-prompt doc), blocked on those files arriving.

## Phase 4 — Owner journey
Screens: Owner Dashboard, Property Creation wizard (8 steps).
Rebuild each wizard step against its specific reference frame instead of one generic `Column` of `TextField`s.

## Phase 5 — Professional ecosystem
Screens: Professional Discovery, Business Profile, Project/Service detail (not yet built at all — confirmed absent from file tree).
Risk: Project/Service detail screens don't exist yet; need reference PNGs before starting, not spec text.

## Phase 6 — Transaction system
Screens: Enquiry, Make Offer, Book Viewing, My Enquiries, Quote, Payments (not yet built — confirmed absent).
Payments has zero implementation currently despite being in the original 80-section spec; needs reference PNGs.

## Phase 7 — My Home
Screens: My Home hub, Documents (built this session), Maintenance/Expenses/Renovations/Providers/Warranty/History (currently snackbar stubs, confirmed in `my_home_screen.dart`).

## Phase 8 — Settings / THEQA / security
Already closest to reference (built from pasted PNGs this session). Work here is componentization only: re-point existing Settings/Security/Privacy/Help/Account-switch screens at Phase 1's `AqaratiCard`/`AqaratiListRow` instead of raw `Card`/`ListTile`. Also: wire missing THEQA states (Pending/Cancelled/Expired/Unavailable as distinct screens, not collapsed into "failed").

## Phase 9 — Global states
Empty/Error/Loading/Skeleton across every screen — audit which screens are missing which state (many currently only implement the happy path).

## Phase 10 — Visual QA
For every screen touched in Phases 1-9: reference PNG side by side with a same-viewport Flutter screenshot, written diff note, fix, re-screenshot. No screen exits its phase without this pair on file.

---

## Keep / Refactor / Rebuild / Delete

**KEEP**: `Money` value object, model/enum layer, repository/provider pattern, `AqaratiButton`, auth-gate-sheet pattern, verification 3-track separation, currency enforcement.

**REFACTOR**: `BusinessCard`, `VerificationBadge`, `AqaratiSearchField`, states.dart trio, all Settings-cluster screens (logic stays, chrome swaps to new primitives).

**REBUILD**: `PropertyCard` (no image path, stock icons, default Card), Map screen (fake canvas, not a map), Owner wizard steps (generic form), Compare screen (plain Row, not measured against reference).

**DELETE**: nothing wholesale yet — no dead/duplicate screens found, but the icon set (`Icons.*` throughout) needs a project-wide find-replace once a real icon family is sourced, not a screen-by-screen patch.

## Blockers before Phase 3+ can start for real
1. Real property/business/location photography — 152-prompt brief already handed to user, not yet returned.
2. Crisp per-screen or per-component reference PNGs for: Project detail, Service detail, Payments, Quote — these screens don't exist in the codebase yet and no reference has been supplied for them at readable resolution.
3. A sourced or drawn icon family to replace `Icons.*` — none exists yet, not even a shortlist.
