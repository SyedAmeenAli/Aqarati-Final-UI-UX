# Role home interaction matrix

Evidence key: T = widget or unit test (`test/role_home_test.dart`), B = Chromium walk on 2026-10-16 (QA build, demo backend). All data is demo data; nothing is saved to a real account. Source: SOURCE (spec), DERIVED (follows from spec), PENDING (needs a decision or API).

## Shared

| Control | Target | Precondition | Source | Evidence |
|---|---|---|---|---|
| Home tab | `RoleHomeScreen` resolves the home | Session grant | SOURCE | T, B |
| Skeleton while the session loads | No buyer flash before a role home | none | DERIVED | T, B |
| Status banner "View application status" | `/verification` | Application exists, not approved | SOURCE | T, B (pending) |

## Agent (approved agent grant only)

| Control | Target | Source | Evidence |
|---|---|---|---|
| Buyer segment | Buyer home with the switcher still shown | SOURCE | T, B |
| Agent workspace segment | Agent home | SOURCE | T, B |
| Your agent profile card | `/verification/details` | DERIVED | B (opens) |
| My listings | Inline explanation; never navigates | PENDING (listing service) | T, B |
| Viewings | `/app/activity` | DERIVED | T, B (hash `#/app/activity`) |
| Contact activity | Inline explanation | PENDING (contact events) | T |
| Your profile | `/verification/details` | DERIVED | T |

## Construction

| Control | Target | Evidence |
|---|---|---|
| Company profile card, Identity, Presence | `/app/account/workspace/profile` | T, B |
| Directory | `/app/explore/build/results?cat=construction` | T |
| Reputation | `/app/account/workspace/reviews` | T |
| Commercial registration row | `/verification/details` | T |
| Office row, Contact row | profile editor, leads screen | T |
| Complete your profile | profile editor | B |

## Property Development (approved developer only)

| Control | Target | Evidence |
|---|---|---|
| Add project (hero or empty state) | `/workspace/projects/new` (existing wizard) | T, B (wizard opens) |
| Manage projects, View all | `/app/account/workspace/projects` | B |
| Status chips (All, Draft, Under review, Approved; Changes requested and Rejected only when present) | Filter the owner's real records, counts from data | T |
| Project card | `/workspace/projects/:id` (existing status screen) | T (renders), existing tests for the screen |

## Building Architecture

| Control | Target | Evidence |
|---|---|---|
| Index 01 to 04 | profile editor, profile editor, reviews, leads screen | B (reviews opens) |
| Edit, Complete your profile | profile editor | T |
| Essentials rows | profile, verification, reviews, leads | T (renders) |
| Public profile preview | `/app/explore/build/results?cat=architecture` | T |
| Work showcase | Note only; no action (PENDING, portfolio API) | T |

## Interior & Exterior

| Control | Target | Evidence |
|---|---|---|
| Interior / Exterior / Both selector | Shows the model's service type; another option opens the profile editor, nothing switches locally | T, B |
| Edit, Manage profile, essentials rows | profile editor, reviews, verification | B (editor opens) |
| Palette strip | Decoration only, labelled as such | T |
| Work showcase | Note only (PENDING) | T |

## Not shown anywhere

In-app chat, tenders, bids, job pipelines, revenue, profile views, enquiry counts, fabricated review totals, an admin entry, a fifth tab.
