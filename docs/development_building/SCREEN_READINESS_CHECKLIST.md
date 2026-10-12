# Screen readiness checklist: #59–#86

Legend. **Built**: implemented and routed. **Tests**: widget/unit tests (D = `devbuild_discovery_test.dart`, W = `devbuild_workspace_test.dart`); every screen is also built at 1× and 2× text, and the main ones in dark and Arabic. **Browser**: opened in a release web build at 393×852 and looked at (L light, D dark, AR Arabic). **Data**: where the content comes from today. Nothing here was tested on a device.

"Demo" data means `DemoDevBuildRepository` (fictional, in memory, active only while `kUseDemoBackend` is true). "Gated" means the screen exists and shows an explicit unavailable state because the contract is not confirmed (see `DECISIONS_AND_SOURCE_GAPS.md`).

| # | Screen | Route | Files | Data | Label | States covered | Tests | Browser |
|---|---|---|---|---|---|---|---|---|
| 59 | D&B home | `/app/explore/build` | `db_discovery.dart` | demo | DERIVED-UX | loading skeleton, empty (featured hidden), error + retry | D | L D |
| 60 | Categories | `/app/explore/build/categories` | `db_discovery.dart` | static | SOURCE-CONFIRMED (four categories) | static | D | L |
| 61 | Results list | `/app/explore/build/results` | `db_discovery.dart`, `db_widgets.dart` | demo | DERIVED-UX | loading, empty with clear, error + retry, paging | D | L D AR |
| 62 | Results map | same, `view=map` | `db_discovery.dart` | demo | DERIVED-UX | loading, no coordinates, error; web shows region (no pins), native needs a map key | D (builds), not seen on native | L D |
| 63 | Professional profile | `/build/pro/:id` | `db_profile.dart` | demo | DERIVED-UX | loading, not found, error, no contact details, guest sign-in prompt | D, W | L |
| 64 | Reviews | `/build/pro/:id/reviews` | `db_profile.dart` | demo (one business has fictional reviews) | SOURCE-CONFIRMED (published only) | empty, "text soon", filter empty, error | D | D |
| 65 | Developer projects | `/build/pro/:id/projects` | `db_profile.dart` | demo | DERIVED-UX | empty, filter by type, error | D | not opened |
| 66 | Project detail | `/build/project/:id` | `db_profile.dart` | demo | DERIVED-UX | not found, error, no map, no media note | D | L |
| 67 | Project gallery | `/build/project/:id/gallery` | `db_profile.dart` | none today (no project media in the model) | PROPOSED-EXTENSION | viewer with real count (tested with a fake repository), empty state | D | empty state only |
| 68 | Developer dashboard | `/app/account/workspace` | `db_workspace.dart` | demo | DERIVED-UX | guard gates (7), loading, error, no projects | W | L |
| 69 | My projects | `/app/account/workspace/projects` | `db_projects.dart` | demo | DERIVED-UX | empty, filter, search, denied, error | W | L (empty and with one project) |
| 70 | Add project: basic | `/workspace/projects/new` | `db_wizard.dart` | draft | DERIVED-UX | validation, leave prompt | W | L |
| 71 | Add project: details | same, step 2 | `db_wizard.dart` | draft | SOURCE-CONFIRMED fields only | conditional fields by type, validation | D, W | L |
| 72 | Add project: media | same, step 3 | `db_wizard.dart` | none | BLOCKED-BY-CONTRACT | disabled with reason | W | L |
| 73 | Add project: location | same, step 4 | `db_wizard.dart` | draft + taxonomy | DERIVED-UX (pin placement not built) | validation, coordinate pair/range | D, W | L |
| 74 | Add project: review | same, step 5 | `db_wizard.dart` | draft | DERIVED-UX | missing fields, edit links, submit loading and failure | W | L |
| 75 | Submission confirmation | `/workspace/projects/:id/submitted` | `db_projects.dart` | repository result | SOURCE-CONFIRMED | follows returned status (review / draft / other), error | W | L |
| 76 | Project status & management | `/workspace/projects/:id`, list filters | `db_projects.dart` | demo | DERIVED-UX | each status, no actions where not allowed | W | L |
| 77 | Professional dashboard | `/app/account/workspace` | `db_workspace.dart` | demo | DERIVED-UX | no project actions, Portfolio tile | W | not opened |
| 78 | Company profile | `/app/account/workspace/profile` | `db_pro_tools.dart` | demo | DERIVED-UX | validation, save, error | W | L |
| 79 | Contact activity | `/app/account/workspace/leads` | `db_pro_tools.dart` | none (no listing contract) | BLOCKED-BY-CONTRACT | gated, empty, list (fake repo) | W | L |
| 80 | Contact event detail | `/workspace/leads/:id` | `db_pro_tools.dart` | none | BLOCKED-BY-CONTRACT | not found, detail (fake repo) | W | not opened |
| 81 | Business reviews | `/app/account/workspace/reviews` | `db_pro_tools.dart` | demo | SOURCE-CONFIRMED (published only, no reply) | empty, filter | W | L |
| 82 | Review feedback & resubmission | `/workspace/projects/:id` | `db_projects.dart` | demo | DERIVED-UX | feedback shown verbatim, empty feedback, resubmit confirm and error | W | L |
| 83 | Edit existing project | `/workspace/projects/:id/edit?step=n` | `db_wizard.dart` | demo | DERIVED-UX | prefilled, status shown, refused when not editable | W | not opened |
| 84 | Profile review status | `/app/account/workspace/profile/status` | `db_pro_tools.dart` | session state | DERIVED-UX (no history) | none saved, awaiting review | W | not opened |
| 85 | Engagement confirmation | `/app/account/workspace/engagements`, `/workspace/engagements/:id` | `db_pro_tools.dart` | none | BLOCKED-BY-CONTRACT | gated, confirm flow (fake repository) | W | L (gated) |
| 86 | Portfolio | `/app/account/workspace/portfolio` | `db_pro_tools.dart` | none | PROPOSED-EXTENSION | empty, add disabled with reason, developer note | W | L (developer note) |

## Cross-cutting

| Item | Status |
|---|---|
| Customer nav stays Home / Explore / Activity / Account | Done. Discovery sits under Explore, workspace under Account, both inside the existing shell. |
| Role guards | Done and tested for signed out, customer, onboarding, pending, awaiting second approval, resubmission, rejected, suspended, wrong role. Repository re-checks ownership (tested). |
| Light and dark | Widget tests build the main screens in dark; browser QA viewed dark for home, results, map and reviews. |
| Arabic / RTL | Widget tests build home and workspace in Arabic; browser QA viewed Arabic results. Copy is draft. |
| Large text | Every screen is built at 2× in tests. |
| Reduced motion | One wizard test with `disableAnimations`. No looping animation exists. |
| Accessibility | Labels on icon-only controls, status never colour-only, 44–48 px targets, live regions for counts. Not tested with VoiceOver or TalkBack. |
| Main docs | Only these five files under `docs/development_building/` were added. |

## Known gaps

- Screens marked "not opened" in the Browser column were not viewed in a browser; they are covered by widget tests only.
- Native Google map pins were not seen.
- Everything listed under BLOCKED-BY-CONTRACT is an honest placeholder, not a working feature.
