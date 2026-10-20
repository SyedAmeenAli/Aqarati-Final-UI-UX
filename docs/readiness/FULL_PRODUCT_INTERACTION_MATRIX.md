# Full-app interaction matrix

Evidence: T = automated test, M = layout matrix (`test/app_matrix_test.dart`: 21 screens at 320 light, 320 dark, 360 Arabic RTL, 393 at 200% text, 430 dark Arabic RTL), B = Chromium walk on 2026-10-16 (QA build, demo backend), R = reduced-motion test. "Demo" means the action runs on an in-memory repository.

| Area | Control and outcome | Backend | Evidence |
|---|---|---|---|
| Home | Search entry opens search; four property tiles open results by category; Buy / Rent switch filters the featured list; Development & Building, Maintenance, Broker and Loan cards open their screens | Mock data | B, M, T |
| Home | Heart saves or removes a property, pops once, persists on the device | Local storage | T, B (saved, reloaded, still saved) |
| Explore | Category entries open properties, professionals, Development & Building | Mock data | B, M |
| Search | Start screen, results for a query, filters sheet, sort sheet, recents (empty on a fresh install) | Mock data | T (11), B, M |
| Properties | Types screen, list and map views, filters | Mock data | B, M, T |
| Property detail | Gallery swipe, Save, View on map, Read more, Make an offer, View profile, Contact, Enquire, Book viewing | Mock data | B (all present), M, T |
| Enquiry, Offer | Validate, save on the device, and state that nothing was delivered | Local only | T |
| Compare | Opens from Saved as `/compare` with the selected ids | Local | T (route), existing tests |
| Viewings | Availability, slot, review, request to "Your request is with the host"; reschedule, cancel, completed and review screens | Demo | B (to Requested), T (6), M |
| Activity | Switch between Viewings and Maintenance; My Viewings tabs (All, Upcoming, Past, Cancelled); maintenance list opens the request detail | Demo (empty in production; viewings seeded only in the QA build) | T, B, M |
| Maintenance request | Provider profile button, choose service, day and time of day, optional notes, validation, review step, send once, duplicate and failure messages, detail with cancel confirmation, status copy for requested, confirmed, declined, cancelled, completed | Demo | T (10 plus 3 detail), B (end to end), M |
| Notifications | Inbox from real viewing, maintenance and verification changes; tap marks read and opens the matching screen; Mark all as read; real unread count on the Account row; empty and error states | Local, derived | T (5), B, M |
| Delete account | Information, confirmation word plus acknowledgement, deletion attempt, result; failure keeps the person signed in; success signs out and clears saved items, recents and read state | Demo; production wiring reports unavailable | T (4), M |
| Account | Role and phone, Saved, Property tools, language, theme (animated), sign out, demo notice | Demo | B, T, M |
| Calculators | List and three calculators with disclaimer | Client-side | T (7), B, M |
| Professionals and business profile | Directory with category filters; profile with reviews, contact | Mock data | B, M |
| Development & Building | Home, categories, results (list and map), profile, projects, gallery | Demo roster | T (75), B, M |
| Login, forgot password, legal | Render and validate | Demo | B, M |
| Role homes (six) | Role-specific actions; Buyer / Agent switch; guards for non-approved grants | Demo | T (97), B |
| Signup (six paths) | Form steps, OTP, documents, review, submit | Demo | T, B |
| Motion | Route direction, tab fade-through, nav indicator, press, theme fade, step switch, heart | n/a | T (23), R, B |
| Guards | Non-approved business accounts see the buyer home plus a status banner; buyers opening `/verification` are sent home | Demo | T, B |

## Controls that are honestly unavailable (never fake an outcome)

Agent My listings and Contact activity (expand an explanation); lead events, engagements, portfolio and profile persistence (unavailable states); enquiry and offer delivery (saved on the device only, and labelled); provider-side maintenance answers (QA controls only); notification push and preferences; real account deletion (endpoint unconfirmed); Aqary e-Broker (not built).
