# AQARATI design reference (extracted from the code)

Everything below is read from the running source, not from a mock-up. New screens use these values
through the shared components; none of them introduces a value of its own.

Sources: `lib/core/aq/aq_tokens.dart`, `aq_typography.dart`, `aq_primitives.dart`, `aq_forms.dart`,
`aq_scene.dart`, `lib/features/viewing/widgets/viewing_scaffold.dart`, `viewing_components.dart`,
`lib/features/devbuild/db_widgets.dart`, `lib/features/workspace/aq_home.dart`.

## Colour (light, then dark)

| Role | Light | Dark |
|---|---|---|
| background | `#EDE1D4` | `#1A1613` |
| surface (resting, translucent) | `#FBF7F1` at 72% | `#272019` at 72% |
| surfaceRaised (cards, sheets, bars) | `#FBF7F1` | `#2A231D` |
| surfaceSelected | `#F6EADB` | `#3A2E24` |
| ink / inkSoft / inkFaint | `#2D2823` / `#655C52` / `#766B60` | `#F1E8DB` / `#C3B6A5` / `#93877A` |
| hairline | `#655C52` at 20% | `#F1E8DB` at 20% |
| accent / accentDeep / onAccent | `#825C3F` / `#674830` / white | `#B98A64` / `#D1A47F` / `#1A1613` |
| danger / success / warning | `#A2402E` / `#4C6B38` / `#8A5A1F` | `#E08A78` / `#9DB98A` / `#D9A86A` |

Status never relies on colour alone: every pill is an icon plus text (`AQStatusPill`, which has the
same shape as the viewing and project chips).

## Type

Fraunces for editorial display and headlines, Plus Jakarta Sans for UI and body, IBM Plex Sans Arabic
for RTL (all bundled). Scale: display 46/38/32, headline 28/24/20, title 18/16/14, body 17/15/13,
label 16/13/11. Read through `AQTypography.of(context, AQText.x, soft: …)` only.

## Shape, space, size

- Radii: small 10 (chips, tags), medium 18 (buttons, fields, tiles), large 28 (cards, sheets).
- Spacing: 4-point rhythm (4, 8, 12, 16, 20, 24, 32, 40, 48), page gutter 24, content width max 520.
- Controls: tap target 48, button 56 (compact 50), field 56.
- Elevation: none, subtle, floating, modal (warm shadow `#2D2823`). Cards use a hairline border, not a shadow.
- Icons: one family, 24-point grid, 1.6 stroke, round caps (`assets/icons/aq/*.svg`), sizes 18/22/26/28.

## Components reused for the new work

| Need | Existing component |
|---|---|
| Full-screen page with title, back, pinned action bar | `AQViewingScaffold`, `AQBottomActionBar`, `AQBarSecondaryButton` |
| Buttons | `AQPrimaryButton`, `AQSecondaryButton`, `AQTextButton`, `AQIconButton` |
| Fields | `AQTextField`, `AQPasswordField`, `AQOtpField`, `AQCheckRow`, `DbSelectField` (sheet picker), `DbFieldFrame` |
| Filter chips | `DbPillRow` |
| Cards and rows | `AQSurface`; `AgentListingCard` and `LeadCard` follow `AQResultCard` (photograph on the leading edge, then type line, title, place, facts, price) |
| Notices, empty, error | `AQNoticeCard`, `AQEmptyViewingState`, `AQErrorBanner`, `DbNotice`, `DbErrorCard`, skeletons |
| Confirmation | `showAQSheet` (customer app), `Dialog` on the same surfaces (admin web) |
| Sponsored banner | `AQBanner`, wrapped by `SponsoredBannerView`; the admin preview renders this very widget |
| Demo marker | `AQDemoNotice` |

## Motion (all from `AQMotion`)

Press 100 ms down / 160 ms up (scale 0.98), icon 180, sheet 320 in / 240 out, dialog 200, form step
240, state change 220, route 300 with 20 px travel (mirrors in RTL), theme 340. Reduced motion
shortens or removes movement (`AQMotion.scaled`, `AQAnimatedSize`). New screens add no timings of
their own: list swaps use `AnimatedSwitcher(AQMotion.fast)`, forms use `AnimatedSize(AQMotion.fast)`.

## What was added to shared code, and why

| Change | Reason |
|---|---|
| `AQStatusPill` (`lib/core/aq/aq_status.dart`) | One pill for listing, lead, moderation and ad statuses, same metrics as the existing chips. |
| `AQBanner.imageBytes` and https images | Lets the admin preview a picked banner without a second banner component. The look is unchanged. |
| `AQBannerFrame` (`lib/features/ads/sponsored_banner.dart`) | The one place the sponsored banner is placed: pinned at the top of every signed-in screen, above the page. With no eligible ad the tree is the same and takes no room (tested; pixel-identical to the approved build in a browser). |
| `AQChoiceTile` skip chip | Demo-only shortcut on the purpose screen; hidden outside the demo backend. |

Admin web console: a sidebar from 960 px, a top bar with tab pills below that; tables become one
card per record below 720 px. It uses the same tokens, so it reads as AQARATI, not as a template.
