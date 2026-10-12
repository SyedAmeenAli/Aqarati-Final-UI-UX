# Interaction matrix

Every visible control in Development & Building, what it does, when it is enabled, what happens on failure, and the test that covers it. Test names refer to `test/devbuild_discovery_test.dart` (D) and `test/devbuild_workspace_test.dart` (W). "—" in the test column means covered only by the screen building without error (all screens are built at 1x and 2x text) and by browser QA.

Context rules that apply to every screen: routes carry the entity id (`/build/pro/:id`, `/build/project/:id`, `/workspace/projects/:id`), the category/search/location/service/sort are carried in the results URL, Back uses `aqBack` to the previous entry (or a meaningful fallback on deep link), and a missing or stale id shows a not-found state instead of an empty page.

## A. Customer discovery

### #59 Development & Building home — `/app/explore/build`
| Control | Enabled | Action / next state | Failure | Test |
|---|---|---|---|---|
| Back arrow (hero) | always | `aqBack` → Explore | — | — |
| Search field + keyboard submit | always | `/app/explore/build/results?q=…` | — | — |
| Clear (×) in search | when text | clears text | — | — |
| Category tile ×4 | always | `/app/explore/build/results?cat=<type>` | — | D: home category opens that category |
| Featured banner "Explore project" | only when an approved project exists | `/build/project/:id` | section hidden on empty; skeleton while loading | D: home builds |
| Verified professionals "View all" | always | results (no filter) | — | — |
| Professional card | list non-empty | `/build/pro/:id` | error card with retry; empty note | D |
| Closing banner | always | `/app/explore/build/categories` | — | — |

### #60 Categories — `/app/explore/build/categories`
| Control | Enabled | Action | Failure | Test |
|---|---|---|---|---|
| Back | always | `aqBack` → D&B home | — | — |
| Category card ×4 | always | results `?cat=` | — | D: categories build |
| Interior / Exterior / Both pills | always | results `?cat=interiorExterior&svc=` | — | — |
| "Approved businesses only" line | not interactive (info) | — | — | — |

### #61 / #62 Results list and map — `/app/explore/build/results`
| Control | Enabled | Action | Failure | Test |
|---|---|---|---|---|
| Back | always | `aqBack` → categories | — | — |
| Category pills (All + 4) | always | re-queries, resets paging, clears service filter if not interior | error card + retry | D |
| Search field + submit | always | applies text to the same query | — | D: empty search |
| Location | always | governorate sheet (All of Oman + 11) | — | — |
| Service type | only for Interior & Exterior | sheet: All / Interior / Exterior / Both | — | — |
| Sort | always | sheet: Relevance / Highest rated / Name | — | — |
| List / Map toggle | always | same query and filters | map error card, empty-map note | D |
| Card | always | `/build/pro/:id`; in map mode first tap selects and recentres, selected card opens | — | D: opens a profile |
| Map pin (native, keyed) | map configured | selects the result | "Map unavailable" view on native without a key; web shows region + pins note | — |
| Show more | when `hasMore` | widens page size, keeps current list while loading | inline error with retry | D: pagination reports more |
| Clear all | when empty and filters/search/category set | resets to the unfiltered query | — | D: empty search |

### #63 Professional profile — `/build/pro/:id`
| Control | Enabled | Action | Failure | Test |
|---|---|---|---|---|
| Back (over cover) | always | `aqBack` → D&B home | — | — |
| Cover swipe | >1 photo | PageView, counter from real count | — | — |
| Tabs Overview / Projects (developers only) / Reviews | always | crossfade, same entity | per-tab error + retry | D: profile builds |
| Read more / less | long bio | expands in place | — | — |
| Projects tab: card | projects exist | `/build/project/:id` | empty note | D |
| Projects tab: View all | >4 projects | `/build/pro/:id/projects` | — | — |
| Reviews tab: See all reviews | always | `/build/pro/:id/reviews` | — | — |
| Contact | profile has phone or WhatsApp **and** session | sign-in prompt for guests, else contact sheet | disabled with footnote when no contact details | D: opens a profile |
| Contact sheet: Copy number | per number | copies, closes, snackbar; logs a lead event only if `caps.leadEvents` | — | — |

### #64 Reviews — `/build/pro/:id/reviews`
| Control | Enabled | Action | Failure | Test |
|---|---|---|---|---|
| Back | always | `aqBack` → profile | — | — |
| Star filter pills | reviews returned | client-filters the returned published reviews | filter-empty note | — |
| (no reply/report/helpful) | n/a | not built (no contract) | — | — |

### #65 Developer projects — `/build/pro/:id/projects`
| Back | always | `aqBack` → profile | — | — |
| Type pills | >1 type | filters approved projects | — | — |
| Project card | always | `/build/project/:id` | empty/err states | D |

### #66 Project detail — `/build/project/:id`
| Back | always | `aqBack` → developer profile | not-found state | D |
| Developer row | developer resolves | `/build/pro/:orgId` | — | — |
| Gallery strip / See all | project has approved media | `/build/project/:id/gallery?i=` | explanatory note when none | D: gallery |
| Contact developer | developer has contact details and session | contact sheet | disabled + footnote | — |
| Schedule a Viewing | never shown (no eligible listing link in the model) | — | — | — |

### #67 Gallery — `/build/project/:id/gallery`
| Close | always | `aqBack` → project | — | — |
| Swipe / pinch | media exists | pages, zoom to 4×, counter | per-image error text | D: viewer |
| No media | — | explicit empty state | — | D |

## B. Developer workspace

Guard (all workspace routes): signed out → sign-in prompt; not a business → explanation; onboarding → "Continue verification"; pending / awaiting second / resubmission / rejected / suspended → status badge, message and "View application status" (`/verification`); approved non-developer on a developer route → "only available to approved property developers". Tests: W `route guards` (8).

### #68 Dashboard — `/app/account/workspace`
| Back | always | → Account | — | — |
| Project count tiles | not interactive | counts derived from returned projects | error card | W: dashboard |
| Recent project card | projects exist | `/workspace/projects/:id` | — | — |
| Add new project | developer | `/workspace/projects/new` | — | W |
| Manage projects / View all | developer | `/app/account/workspace/projects` | — | — |
| Company profile / Contact activity / Reviews / Engagements tiles | always | each workspace page | unavailable text where capability is false | W |
| Portfolio tile | non-developers only | `/app/account/workspace/portfolio` | — | W: professional firm |

### #69 / #76 My projects — `/app/account/workspace/projects`
| Add new project | always | wizard | — | W |
| Search | always | filters returned list | — | W |
| Status pills | always | filter by status | — | W: lists, filters |
| Card | always | `/workspace/projects/:id` | denied / error / empty states | W |
| ⋮ menu | always | sheet: View status, Edit (only if status allows, else the reason) | — | W |

### #75 Confirmation — `/workspace/projects/:id/submitted`
| Content | headline follows the returned status (under review / draft / other) | — | error + retry | W: wizard journey, save draft |
| Back to my projects / View project status / Add another project | always | navigate | — | W |

### #70–#74 Wizard — `/workspace/projects/new`
| Step circles | earlier steps only | jump back, values kept | — | W |
| Back (top and bottom) | always | previous step; on step 1 asks before discarding unsaved changes | — | W: leave prompt |
| Save draft (top bar) | new or draft projects | saves a draft, confirmation says "Draft saved" | inline error with retry, draft kept | W |
| Save & continue | step valid | validates and advances | inline field errors | W |
| Project type / beds / baths / governorate / wilayat | wilayat after governorate | choice sheets | — | W |
| Land and built-up area, coordinates | always | numeric input, Western or Arabic-Indic digits | field errors | D: draft validation |
| Photos & amenities | disabled | explained as unavailable | — | W |
| Review: Edit per group | always | jumps to that step, values kept | — | W |
| Submit for review | all required fields | idempotent save, then confirmation | server field errors jump to the step; network error keeps the draft | W |

### #76 / #82 Status and feedback — `/workspace/projects/:id`
| Status banner | not interactive | label + meaning | — | W |
| Reviewer feedback | changes requested or rejected | shown exactly as received | "did not include details" if empty | W |
| Edit project | status allows | wizard (`/edit`) | route refuses other statuses | W |
| Resubmit for review | changes requested only | confirm sheet then idempotent resubmit → confirmation | error with retry | W |
| (review tools only) Simulate buttons | `REVIEW_TOOLS` and demo repository | changes demo status | — | — |

### #83 Edit — `/workspace/projects/:id/edit?step=n`
Prefilled from the stored project, status chip visible, approved projects say changes go back to review, other statuses refused. Tests W: editing reopens prefilled; repository edit-approved.

## C. Professional workspace

| Screen | Control | Behaviour | Test |
|---|---|---|---|
| #77 Dashboard | same page as #68 for non-developers | no project actions, Portfolio tile | W |
| #78 Company profile `/app/account/workspace/profile` | bio, service type (interior/exterior only), governorate, phone, WhatsApp | name and type read-only (from verified documents); phone validation; Save → "waiting for review" status page; media upload shown disabled | W |
| #84 Review status `/app/account/workspace/profile/status` | verification badge, last save state | no invented history | W |
| #79 Contact activity `/app/account/workspace/leads` | list rows → detail | unavailable state when `caps.leadEvents` is false | W |
| #80 Event detail `/workspace/leads/:id` | channel, target, time | no chat, budget or CRM actions | W |
| #81 Reviews `/app/account/workspace/reviews` | star filter | published only, no reply | W |
| #85 Engagements `/app/account/workspace/engagements`, `/workspace/engagements/:id` | list, detail, Confirm completed (confirm sheet → repository) | unavailable state when `caps.engagements` is false | W |
| #86 Portfolio `/app/account/workspace/portfolio` | Add portfolio work | disabled, reason shown, approved profile media shown if any | W |

## Motion

Route changes use `AQRoute.forward` / `AQRoute.hero`; wizard steps fade and slide 4% over `AQMotion.standard`; pills, stepper and status transitions animate with `AQMotion.scaled`, which becomes zero when the platform asks to reduce motion. No looping animation is used.

## Listing pages rebuilt in the stabilisation pass

| Page | Controls | Result / honest state |
|---|---|---|
| Enquiry | name, email, phone, message, Save enquiry | Validation errors per field; valid input is saved on this device; result says it has not been delivered |
| Make offer | amount (OMR), acknowledgement, Save offer | Both required; saved on this device; result says it has not been delivered |
| Photo gallery | swipe, pinch zoom, Photos/Video pills (only if videos exist), back | Real count; empty state when no media; no share or floor-plan control |
| Compare | two or more properties, View property | Real values only; "Nothing to compare" when empty |
| Write a review | back | Explains that reviews open after a both-sides-confirmed engagement; no form |
| Property types | four type cards | Two columns, full descriptions |
| Bottom tab bar | Home, Explore, Activity, Account | Tapping the current tab returns to its root; works from deep pages |
