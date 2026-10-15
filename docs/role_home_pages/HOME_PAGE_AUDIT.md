# Role home pages: audit before implementation

Date: 2026-10-16. Branch `main`, HEAD `ff12824`. Sources read: both prompts and the reference pack (twelve boards, contact sheet, motion spec), the signup audit documents, `lib/` routes, shell, role resolution, the Development & Building module and its repository contract. Architecture version used: v2.6 (the only one present). The frontend blueprint PDF was not re-read.

## What existed

| Role | Home before this work |
|---|---|
| Buyer | `AQHomeScreen` (hero, search entry, four property categories, Buy / Rent switch, featured approved properties, Development & Building and Maintenance sections, Broker and Loan cards). Complete and working. |
| Agent | Nothing. The Home tab was the buyer home. No agent workspace and no Buyer / Agent switch. The activation screen promised "Create and manage listings" and "Manage viewing availability", which did not exist. |
| Construction, Architecture, Interior & Exterior | One shared `DbDashboardScreen` under Account > Workspace: identity card plus the same four tiles for all three. Not reachable from Home. |
| Developer | The same shared dashboard with a project summary block. The project wizard, status screens, lists and gating (`DbGuard`) were already built and are reused unchanged. |

Home tab for every signed-in role was the buyer home. Business users only found their workspace through Account.

## Gaps against the six references

1. Agent workspace and Buyer / Agent switch: missing.
2. Construction, Architecture, Interior & Exterior: the same generic dashboard, not three different experiences.
3. Developer: dashboard counts existed but there was no project-first home with a status pipeline.
4. Approved roles did not land on a role home. Unapproved roles got no status on Home.
5. Pre-existing layout bug found while testing: the buyer home's section header overflowed at 200% text in Arabic.

## API and contract reality (re-inspected)

| Capability | Status | Consequence in the UI |
|---|---|---|
| Listing service (create, manage, status) | No contract, no repository | Agent "My listings" and "Listing status" say it is not connected. No rows, no counts. |
| Contact / lead events | `DbCapabilities.leadEvents` false; demo returns empty | Shown as "Not connected yet". No inbox, no chat. |
| Projects (developer) | Demo repository, owner-scoped, status as returned | Pipeline uses the returned records only. |
| Profile edit | Demo accepts it as "awaiting review" but stores nothing | Bio and location show "Not added yet" until a real API stores them. |
| Reviews | Repository for published reviews exists; own-org list is not wired to the demo | Reviews tiles open the existing reviews screen; no totals are shown on Home. |
| Portfolio / moodboard | Proposed extension only | Shown as a gated note. |
| Invest transaction | `TransactionType` has buy, rent, lease; no invest | Buyer home keeps Buy / Rent. Not invented. |

## Decisions taken (and why)

- **Navigation:** the customer four tabs (Home, Explore, Activity, Account) stay for every role. The references show business tabs (Listings, Projects, Profile, Reviews), but each would need a screen that does not exist or duplicates Account. Role destinations live inside the role home instead. Derived choice, not a source requirement.
- **Role resolution** comes only from the session grant (`resolveHome`). A sign-up choice is never a grant. Any non-approved state falls back to the buyer home with a status banner.
- **Default workspace** for an approved agent is the agent workspace; the choice lasts for the app session and is not saved or sent anywhere.
- **Imagery:** existing approved app assets only (`dbTypeImage`). The reference pack's hero photos were not shipped.
- **Role accents** (copper, antique gold, clay, olive, espresso) tint small details only; surfaces, text and logo use the real tokens.
