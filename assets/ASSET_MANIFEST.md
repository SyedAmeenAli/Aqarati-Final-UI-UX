# AQARATI Asset Manifest

Source: `Sep 27 - 18_08.zip` (165 files: 158 JPG ~1376×768, 7 MP4). Original filenames were AI-generated content descriptions, not property-ID-tagged, and did not 1:1 match the 6 demo location names already in `mock_property_data.dart` (no "Al Mouj", "Qurum", "Al Khoudh", "Salalah", "Al Khuwair" or "Ruwi" appear literally in any filename — the set uses Nizwa/Seeb/Sohar/Sur/Khasab/Al Buraimi/Muscat instead). Per instruction, assets were mapped intelligently by visual content rather than forced onto mismatched place names; property location *labels* in the app are unchanged and remain fictional/coherent, images are generic villa/apartment/plot/commercial photography assigned by content type, not literal geotagging.

All 158 JPGs were kept (none deleted). 13 fell outside every keyword rule and remain in `assets/unassigned/` as spare stock, not wired into any screen yet — flagged below, not silently discarded.

## Property image folders (`assets/properties/pN/`)

| Property | Folder | Count | Content |
|---|---|---|---|
| p1 — 4-Bedroom Villa in Al Mouj (flagship, highest gallery depth) | `properties/p1/` | 37 (curated 9 wired) | Waterfront/marina villa exterior, pool, living/dining, bedrooms, kitchens |
| p1 video | `properties/p1/video/` | 7 (all wired) | Drone exterior, entrance walkthrough, living room, kitchen/dining, master bedroom, pool/marina reveal, exterior walkthrough |
| p2 — Sea-View Apartment in Qurum | `properties/p2/` | 8 (curated 6 wired) | Apartment balcony, sea-facing balcony, building exterior, open living/dining |
| p3 — Residential Plot in Al Khoudh | `properties/p3/` | 5 (all wired) | Aerial plot, vacant land, survey stake, street frontage |
| p4 — Modern Family Villa in Salalah | `properties/p4/` | 22 (curated 10 wired) | Family villa exterior/garden, guest annex, majlis, extra bedrooms |
| p5 — 2-Bedroom Apartment in Al Khuwair | `properties/p5/` | 18 (curated 8 wired) | Apartment interiors/exteriors distinct from p2, second bedroom, kitchen |
| p6 — Commercial Shop in Ruwi | `properties/p6/` | 5 (all wired) | Empty retail interior, commercial strip, shop utility area |

## Business portfolio folders (`assets/businesses/bN/`)

| Business | Folder | Count | Content |
|---|---|---|---|
| b1 — Wadi Architecture | `businesses/b1/` | 14 (curated 6 wired) | Architectural detail studies, facades, atriums, courtyards |
| b2 — Namaa Construction | `businesses/b2/` | 9 (curated 5 wired) | Construction sites, tower cranes, concrete structure, handover |
| b3 — Maysan Design Studio | `businesses/b3/` | 6 (all wired) | Interior design — bathrooms, styled bedroom, reading nook |
| b4 — Rawaq Maintenance Services | `businesses/b4/` | 6 (all wired) | Maintenance technicians, plumbing, painting, garden upkeep |

## Location / lifestyle (`assets/location/`)

15 images — Muscat skyline/corniche/Old Muscat, Nizwa fort, Sohar coast, Sur coast, Khasab coastline, Al Buraimi streetscape, desert dune/sand/terrain. Not yet wired into any screen (Explore location tiles are the intended destination, not built this pass).

## Unassigned / spare (`assets/unassigned/`)

13 files, mostly rare duplicates or architecturally ambiguous shots (e.g. covered parking beside villa, walk-in closet, second lounge, stone archway, coastline collage). Kept on disk, not deleted, not wired — available for future gallery depth if a screen needs more variety later.

## Video manifest (7 MP4, all currently assigned to p1 only)

| File | Content | Intended use |
|---|---|---|
| `01_Drone_footage_of_villa_exterior.mp4` | Aerial exterior reveal | Gallery hero video |
| `02_Kitchen_and_dining_walkthrough_v.mp4` | Kitchen/dining walkthrough | Gallery "Interior" video tab |
| `03_Master_bedroom_walkthrough_villa.mp4` | Master bedroom walkthrough | Gallery "Bedroom" video tab |
| `04_Villa_entrance_walkthrough_video.mp4` | Entrance/driveway walkthrough | Gallery "Exterior" video tab |
| `05_Villa_exterior_walkthrough_shot.mp4` | Exterior walkthrough | Gallery "Exterior" video tab (alt) |
| `06_Villa_living_room_walkthrough.mp4` | Living room walkthrough | Gallery "Interior" video tab (alt) |
| `07_Villa_pool_and_marina_reveal.mp4` | Pool/marina reveal | Gallery hero video (alt) |

Only p1 has video because it is the only property the reference design treats as the "master prototype" gallery (per Figma frame `20.26-master-prototype` / `21.26-gallery-prototype`); other properties get photo-only galleries, matching the reference's stated behavior for non-flagship listings (`21.21-gallery-unavailable` state covers the no-video case).

## What's wired this pass vs. what's still pending

Wired (this session): `Property.imageUrls` populated for all 6 properties, `Property.videoUrls` (new field) for p1, `Business.galleryUrls` populated for all 4 businesses, `PropertyCard` and Property Detail hero rebuilt to render these real images with `BoxFit.cover`.

Not yet wired: Gallery screen's video playback (needs `video_player` package decision — flagged in the phase report, not silently skipped), Explore screen's location tiles (the 15 `location/` images), Business Profile portfolio grid (still placeholder icon grid), Owner property-creation photo-upload step (still a bare upload button, no preview of these assets).
