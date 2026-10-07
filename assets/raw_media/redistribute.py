import os, shutil, re

ASSETS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNASSIGNED = os.path.join(ASSETS, "unassigned")

files = sorted(os.listdir(UNASSIGNED))

def has(name, *kws):
    n = name.lower()
    return any(k in n for k in kws)

rules = [
    # (predicate, dest_rel, cap)
    (lambda f: has(f, "villa_side_elevation", "villa_entrance_and_driveway", "villas_along_omani_coastline",
                      "modern_residential_villa_in_oman", "modern_villa_exterior_photography",
                      "modern_villa_garden_landscaping", "spacious_living_room_in_villa",
                      "sunlit_living_room_interior", "open_family_kitchen_in_villa",
                      "private_pool_closeup", "villa_garden_and_pool_view", "aerial_drone_photography_of_villa"),
     "properties/p1", 8),
    (lambda f: has(f, "villa_front_entrance_with_garden", "villa_garden_landscaping_photo",
                      "contemporary_omani_villas_exteri", "modern_omani_villa_architectural",
                      "beachfront_property_exterior_arc", "third_bedroom_in_villa", "kids_bedroom_with_bunk_beds",
                      "outdoor_majlis_at_contemporary_home", "outdoor_majlis_of_contemporary_home",
                      "family_lounge_interior_photography", "master_bedroom_with_sea_view"),
     "properties/p4", 10),
    (lambda f: has(f, "second_bedroom_with_desk", "second_family_lounge_interior_de", "home_office_interior_photography",
                      "master_bedroom_interior_photography", "master_bedroom_real_estate_photo",
                      "master_ensuite_bathroom_interior", "master_ensuite_with_bathtub", "modern_bathroom_interior_photograph",
                      "modern_living_and_dining_room"),
     "properties/p5", 6),
    (lambda f: has(f, "main_bathroom_with_shower_bathtub", "family_bathroom_with_double_vanity",
                      "maids_room_utility_photography", "master_walkin_closet_photography",
                      "interior_staircase_in_residentia", "entrance_hall_with_wooden_accents",
                      "garden_lounge_seating_area"),
     "properties/p1", 6),
    (lambda f: has(f, "residential_building_constructio", "residential_development_architec",
                      "finished_residential_building_ex", "building_entrance_photography"),
     "businesses/b2", 4),
    (lambda f: has(f, "residential_development_garden_a", "rooftop_deck_architectural_photo",
                      "stone_arched_doorway_architecture", "glass_frontage_at_dusk",
                      "modern_office_lobby_interior", "modern_residential_building_gym_",
                      "contemporary_residential_interio", "courtyard_exterior_residential_p",
                      "interior_wall_with_shadows_and"),
     "businesses/b1", 6),
    (lambda f: has(f, "aerial_photograph_of_residential", "covered_parking_area_at_villa", "covered_parking_beside_villa"),
     "properties/p1", 2),
]

manifest = []
used = set()
for predicate, dest, cap in rules:
    count = 0
    for f in files:
        if f in used or count >= cap:
            continue
        if predicate(f):
            dest_dir = os.path.join(ASSETS, dest)
            os.makedirs(dest_dir, exist_ok=True)
            existing = len([x for x in os.listdir(dest_dir) if os.path.isfile(os.path.join(dest_dir, x))])
            ext = os.path.splitext(f)[1]
            safe = re.sub(r"[^A-Za-z0-9_]", "", os.path.splitext(f)[0])[:40]
            new_name = f"{existing+1:02d}_{safe}{ext}"
            shutil.move(os.path.join(UNASSIGNED, f), os.path.join(dest_dir, new_name))
            manifest.append((f, dest + "/" + new_name))
            used.add(f)
            count += 1

remaining = [f for f in os.listdir(UNASSIGNED)]
print("moved", len(manifest), "remaining unassigned:", len(remaining))
for f in remaining:
    print(" -", f)

with open(os.path.join(ASSETS, "ASSET_MANIFEST_RAW2.txt"), "w", encoding="utf-8") as out:
    for orig, new in manifest:
        out.write(f"{orig} -> {new}\n")
