# Confirmed workflows: implementation report

Brief: seven confirmed feature areas, built on the approved design (see `docs/design/DESIGN_REFERENCE.md`).
Sources for rules: the monorepo architecture v2.6 (`aqarati/docs`, read only). No backend was touched or
assumed. Everything that talks to a service goes through a repository contract with an "unavailable"
implementation (production wiring answers "could not reach the service") and a labelled in-memory demo.

## Where each feature lives

| # | Feature | Routes | Source |
|---|---|---|---|
| 1 | Agent: My Listings (list, add, edit, pause, resume, renew) | `/agent/listings`, `/new`, `/:id`, `/:id/edit` | `lib/features/listings/` |
| 2 | Agent: Leads (contact and viewing requests, Call, confirm / decline) | `/agent/leads`, `/agent/leads/:id` | `lib/features/leads/` |
| 3 | Development company: project enquiries | `/workspace/enquiries`, `/:id` | same module, `LeadScope.developer` |
| 4 | Service companies: service requests | `/workspace/requests`, `/:id` | same module, `LeadScope.service` |
| 5 | Admin: verification queue | `/verification`, `/verification/:id` | `lib/admin/admin_verification_screens.dart` |
| 6 | Admin: listing moderation and e-Broker | `/moderation`, `/moderation/:id` | `lib/admin/admin_moderation_screens.dart` |
| 7 | Admin: Ads & Sponsors, plus the customer banner | `/ads`, `/ads/new`, `/ads/:id/edit`; banner on Home | `lib/admin/admin_ads_screens.dart`, `lib/features/ads/` |

Entry points: the Agent home "My listings" and "Leads" tiles; a "Project enquiries" row on the
Development home; a "Service requests" row on the Construction, Architecture and Interior homes.
Customer navigation is unchanged (Home, Explore, Activity, Account).

The admin console is its own entry point, `lib/admin_main.dart`, built with
`flutter build web -t lib/admin_main.dart --output build/web_admin`. It lives in the same Flutter
package so it reuses the exact tokens, components, motion and banner. The customer app never imports
`lib/admin/` (a test scans every file for it), so admin code is not in the customer bundle.

## Behaviour that matters

- **Listings.** Status pill always mirrors the record. New and returned listings go to review; an edit to a
  live listing keeps it live with "changes in review" (change set). Pause asks first and only the response
  changes the card; a failed pause leaves it live. Ownership: another agent's id shows "not yours" on
  open and on edit. Duplicate title deed is refused. Photos: JPG/PNG by signature, kept ones survive an edit.
  Room fields show only for property types that have rooms.
- **Leads.** Start empty. Call opens the dialler and claims nothing more; no number means no button and a
  reason. A viewing request is answered through the viewing lifecycle (confirm or decline) and a failure
  leaves it "requested". A lead that is not in the caller's inbox shows "not in your inbox".
  Each inbox is closed to every other role.
- **Admin sign-in.** Login, then the one-time code, then the console; the router refuses every protected
  address before both steps. A wrong email and a wrong password give the same message. An ended session
  returns to sign-in with the reason.
- **Decisions.** Reason code required to reject or request resubmission; "Other" needs a note. A fresh code
  (step-up) confirms each decision. Developers need two approvals from two different people. The 30-minute
  claim lock keeps a second reviewer out. Approving a listing with missing mandatory information is blocked.
  A failure leaves the item as it was. Auditors are read-only.
- **e-Broker.** Shown as its own source. The page shows the agreed disclosure text and whether acceptance
  was recorded; it adds no fee, payment or commission.
- **Ads.** Drafts are never served; send for review, a senior reviewer approves, then it is live inside its
  schedule. Editing a live banner sends it back to draft. Pause, resume and order change what is served.
  The preview is the customer banner component. The customer banner shows nothing when there is nothing
  eligible or the service is unreachable, never to a signed-out visitor, and rotates every 5 seconds.
  It is pinned at the top of every signed-in screen by one frame around the app (`AQBannerFrame`); see
  `FINAL_GAP_AUDIT.md` for the route rules.

## Assumptions to confirm (not invented rules, but gaps in the source)

1. **Pause is not in the listing contract.** Documented lifecycle: sold / rented / withdrawn, renew, expiry
   at 90 days. "Paused" is the client-confirmed addition; the contract needs a pause/resume transition.
   `ListingRepository.supportsPause` is false for the unconnected service, so the app never calls pause or
   resume and says nothing was changed; only the demo answers true.
2. **Which edits count as a material change** to a live listing (the change-set rule) is not specified.
3. **Admin permission matrix (Ch. 47) is not in the repository.** The console's proposal: Reviewer and
   Senior and Super decide; Senior and Super give the second approval and manage / review ads; Auditor reads.
4. **Ad review by two people** is not specified for ads, so none is enforced.
5. **Lead and enquiry statuses** beyond the viewing lifecycle are not defined, so none are shown.
6. **Report and decision reason codes** use the 12 documented codes; the per-queue subsets are a front-end choice.
7. **Sponsored banner placement.** Resolved in the final audit: one banner, pinned at the top of every
   signed-in screen. Result lists ask for `results_in_feed` ads first and fall back to `home_top`.
8. **Listing attribute matrix (section 27.5) is not in the repository**; room fields use a front-end default.
9. **Admin copy is English only.**

## Missing API contracts (exact operations needed)

| Area | Needed |
|---|---|
| Listings | `GET /properties?mine`, `POST /properties`, `PATCH /properties/:id`, pause/resume transition, `POST /properties/:id/images` |
| Leads | list and detail per role scope, host-side `PATCH /viewings/:id` (confirm, decline), enquiry and request records |
| Admin | `/admin/*` auth with TOTP and step-up, queue claim/release, decisions, document stream, listing review |
| Ads | `GET /ads?placement=`, `POST /ads/:id/events`, `GET/POST/PATCH /admin/ads`, ad review decision |

## Not verified

Real devices, screen readers, any real backend, document streaming, push, and the admin console behind
its network allow-list and real TOTP. The demo shows `DEMO` where it simulates.
