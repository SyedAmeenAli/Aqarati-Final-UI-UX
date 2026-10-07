import os, shutil, re

SRC = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(SRC))  # aqarati-app/
DEST = os.path.join(ROOT, "assets")

files = [f for f in os.listdir(SRC) if f.lower().endswith((".jpg", ".mp4"))]

# Video walkthrough set -> all belong to the flagship villa (p1)
video_files = [f for f in files if f.lower().endswith(".mp4")]

def has(name, *kws):
    n = name.lower()
    return any(k in n for k in kws)

manifest = []

# --- Property buckets (jpg only) ---
jpgs = [f for f in files if f.lower().endswith(".jpg")]
used = set()

def take(predicate, limit=None):
    out = []
    for f in jpgs:
        if f in used:
            continue
        if predicate(f):
            out.append(f)
            if limit and len(out) >= limit:
                break
    for f in out:
        used.add(f)
    return out

# p1: 4-Bedroom Villa in Al Mouj — waterfront/marina/pool flagship villa
p1 = take(lambda f: has(f, "marina", "waterfront", "infinity_pool") , 8)
p1 += take(lambda f: has(f, "double-height_living", "entrance_foyer_and_staircase", "villa_side_elevation", "contemporary_villa_front_facade", "rooftop_terrace"), 4)

# p3: Residential Plot in Al Khoudh — land/plot only
p3 = take(lambda f: has(f, "plot", "survey_stake", "vacant"), 10)

# p6: Commercial Shop in Ruwi — retail/commercial
p6 = take(lambda f: has(f, "commercial", "retail", "shop"), 6)

# p2: Sea-View Apartment in Qurum — apartment + balcony/sea
p2 = take(lambda f: has(f, "balcony", "sea-view", "apartment_buildings_in_muscat", "shared_pool_at_apartment"), 6)
p2 += take(lambda f: has(f, "open_living_and_dining_apartment", "compact_contemporary_apartment"), 3)

# p5: 2-Bedroom Apartment in Al Khuwair — remaining apartment interiors
p5 = take(lambda f: has(f, "apartment"), 8)
p5 += take(lambda f: has(f, "second_bedroom", "modern_bedroom_photography", "galley_kitchen"), 4)

# p4: Modern Family Villa in Salalah — remaining family villa exteriors/interiors (generic, not city-specific)
p4 = take(lambda f: has(f, "family_villa", "family_house", "villa_garden", "family_garden", "villa_front_entrance",
                          "guest_annex", "villa_exterior", "modern_villa", "contemporary_villa", "residential_villa",
                          "villa_entrance", "courtyard_villa", "villas_along"), 12)

# remaining villa/interior generic photography -> top up p1 (flagship gets richest gallery)
p1 += take(lambda f: has(f, "master_bedroom", "living_room", "kitchen", "bathroom", "dining", "majlis",
                           "staircase", "closet", "wardrobe", "bedroom") and not has(f, "second_bedroom", "third_bedroom", "kids_bedroom"), 10)

# --- Business portfolio buckets ---
b2_namaa_construction = take(lambda f: has(f, "construction", "concrete", "tower_crane", "building_handover",
                                              "residential_building_construction"), 8)
b4_rawaq_maintenance = take(lambda f: has(f, "maintenance", "technician", "plumbing", "painting", "garden_maintenance"), 8)
b1_wadi_architecture = take(lambda f: has(f, "architectural", "architecture", "arch_detail", "lattice_screen",
                                             "stone_arched", "atrium"), 8)
b3_maysan_design = take(lambda f: has(f, "designer", "interior_design", "design_photograph", "styled_bedroom",
                                        "powder_room", "reading_and_work_nook"), 8)

# --- Location / lifestyle category (whatever's left that reads as a place/landscape) ---
location_kws = ("muscat", "nizwa", "sohar", "seeb", "sur_oman", "khasab", "buraimi", "desert", "old_muscat",
                "corniche", "skyline")
location = take(lambda f: has(f, *location_kws), 20)

remainder = [f for f in jpgs if f not in used]

buckets = {
    "properties/p1": p1,
    "properties/p2": p2,
    "properties/p3": p3,
    "properties/p4": p4,
    "properties/p5": p5,
    "properties/p6": p6,
    "businesses/b1": b1_wadi_architecture,
    "businesses/b2": b2_namaa_construction,
    "businesses/b3": b3_maysan_design,
    "businesses/b4": b4_rawaq_maintenance,
    "location": location,
    "unassigned": remainder,
}

for rel, flist in buckets.items():
    dest_dir = os.path.join(DEST, rel)
    os.makedirs(dest_dir, exist_ok=True)
    for i, f in enumerate(flist, 1):
        ext = os.path.splitext(f)[1]
        safe = re.sub(r"[^A-Za-z0-9_]", "", os.path.splitext(f)[0].split("_2026")[0])[:40]
        new_name = f"{i:02d}_{safe}{ext}"
        shutil.copy2(os.path.join(SRC, f), os.path.join(dest_dir, new_name))
        manifest.append((f, rel + "/" + new_name))

# videos all -> properties/p1/video
video_dir = os.path.join(DEST, "properties/p1/video")
os.makedirs(video_dir, exist_ok=True)
for i, f in enumerate(video_files, 1):
    safe = re.sub(r"[^A-Za-z0-9_]", "", os.path.splitext(f)[0].split("_2026")[0])[:40]
    new_name = f"{i:02d}_{safe}.mp4"
    shutil.copy2(os.path.join(SRC, f), os.path.join(video_dir, new_name))
    manifest.append((f, "properties/p1/video/" + new_name))

with open(os.path.join(DEST, "ASSET_MANIFEST_RAW.txt"), "w", encoding="utf-8") as out:
    for orig, new in manifest:
        out.write(f"{orig} -> {new}\n")

print("done", len(manifest), "files placed;", len(remainder), "unassigned")
