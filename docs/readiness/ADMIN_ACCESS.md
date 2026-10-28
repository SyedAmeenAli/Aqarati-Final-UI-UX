# Admin Console access and demo mode

## Route
The Admin Web Console is part of the same web build as the customer app. It lives at the hash route **`#/admin`** (for example `https://<site>/#/admin`). It has its own sign-in, its own sidebar navigation and its own routes inside that page; it never shares the customer or agent navigation.

- Opening `#/admin` directly (or refreshing on it) shows the admin sign-in. The inner console router does not write to the browser address, so the address stays `#/admin` (`_QuietRouteInformationProvider` in `lib/admin/admin_app.dart`).
- The console is not a sign-up role and not a tab. The customer and agent log-in screens carry one small text link, **Admin Console →** (`lib/features/entry/admin_link.dart`), which opens `#/admin`. If `AQARATI_ADMIN_URL` was set at build time the link opens that address instead.
- **Back to AQARATI** on the console sign-in returns to the customer entry.
- Entry point for a separately hosted console still exists: `lib/admin_main.dart` (`flutter build web -t lib/admin_main.dart`). It is optional; nothing depends on it.

## What the console contains (`lib/admin/`)
| Area | Route | What it does (prototype) |
| --- | --- | --- |
| Sign-in | `/login`, `/code` | Email + password, then an illustrative one-time code step |
| Overview | `/overview` | Counts that open their queues; recent administrative activity |
| Accounts | `/accounts`, `/accounts/:id` | 14 sample accounts (customers, agents, four professional kinds); search, role and status filters; account detail; set active / under review / suspended with confirmation and an optional note |
| Verification | `/verification…` | Review queue and decisions for professional accounts (existing) |
| Listing moderation | `/moderation…` | Moderation queue and actions (existing) |
| Ads & Sponsors | `/ads…` | Sponsored placements: create, pause, resume, reorder (existing) |
| Reports | `/reports`, `/reports/:id` | Complaints against listings and accounts; filter; resolve or dismiss with a note, reopen |
| Activity log | `/audit` | Everything changed in this session, newest first |

Every change asks for confirmation first and is written to the Activity log. Nothing leaves the browser.

## More modules (all fictional, in memory, every change confirmed and logged)
`/m/listings`, `/m/brokers`, `/m/projects`, `/m/construction`, `/m/design`, `/m/maintenance`, `/m/viewings`, `/m/content`, `/m/announcements`, `/analytics` (counts from the demo records; invented figures are labelled "Sample figure") and `/settings` (profile, session, sign out). Ads & Sponsors adds an audience (which Home shows the banner), search, and a preview that says where the button goes.

## One-tap demo entry
In a demo-enabled build the sign-in shows **Open the demo console**, which signs in as the demo super admin through the same simulated sign-in and code. It does not exist in a normal build.

## What it is not
- Sign-in and the one-time code are **simulated**. They protect nothing. The console says so on its sign-in page ("Prototype only. Sign-in and the one-time code on this page are simulated; they do not protect anything.").
- No backend, no database, no real roles or permissions. State lives in memory and resets on reload.
- Status changes, resolutions, ad changes and moderation decisions affect only the sample data in the console. They do not reach the customer or agent apps, except the sponsored placements the demo store already feeds to the customer feed.
- e-Broker submissions made in the same browser session appear in the moderation queue as e-Broker records; the decision shows in the customer's Activity. State resets on reload.

## Demo accounts only in an explicitly enabled preview build
`kDemoMode = kUseDemoBackend && AQARATI_DEMO_MODE` (default **off**). In a normal build the console sign-in shows **no** demo accounts, password or code ("Demo accounts are shown only in a build made for previews."). In a preview build it lists the sample reviewer accounts, the sample password and the sample code, and shows the "DEMO DATA" marker.

```bash
flutter build web --release --dart-define=AQARATI_DEMO_MODE=true --dart-define=REVIEW_TOOLS=true --output build/web_demo
```

## Vercel (truthful status)
- The console is included in the single web build, so a Vercel deployment of that build serves `#/admin` with no second project.
- **Verified in this repository:** a local production build (`build/web`, default flags) served over HTTP shows the admin sign-in at `#/admin`, keeps it on refresh, and still serves the customer entry (`#/entry`) from the same build.
- **Not verified:** the deployed Vercel URL. No deployment was made in this change and the Vercel project settings (build command, defines) were not inspected or changed. Do not describe the console as live on Vercel until `#/admin` has been opened on the deployed address after the next approved deploy.
- A Vercel build made without `AQARATI_DEMO_MODE=true` shows the sign-in but no demo accounts, so a reviewer cannot sign in to it. To let a reviewer in, deploy a preview build with the define above.

## Demo mode ("Skip for Demo")
Off by default. A normal or production build has no skip buttons anywhere (sign-up screens or purpose screen). With `AQARATI_DEMO_MODE=true`, User to Shop and Real Estate Agent sign-up show **Skip for Demo**, and the purpose screen shows per-role Skip chips (agent, and the four professional roles). They only replace the simulated session, then show "Demo mode: no account was created, registered or verified." They never bypass the Admin Console sign-in.

In a preview build the four professional workspaces also show sample contact activity, sample engagements (confirmable locally) and sample portfolio images. In a normal build those pages say plainly that the service is not available.

## Troubleshooting
- Blank page on a static host: stop any server holding the output folder before `flutter build web` and check `assets/AssetManifest.bin` exists.
- Sign-in will not accept the sample credentials: the build was made without `AQARATI_DEMO_MODE=true`.
