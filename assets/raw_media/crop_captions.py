"""Crop the bottom caption strip burned into the generated stock photography.
Applied uniformly (8% of height) across every WIRED image so framing stays
consistent rather than per-image guessing. Overwrites in place."""
from PIL import Image
import os

ASSETS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

WIRED = []
for base in ["properties/p1", "properties/p2", "properties/p3", "properties/p4", "properties/p5", "properties/p6",
             "businesses/b1", "businesses/b2", "businesses/b3", "businesses/b4"]:
    d = os.path.join(ASSETS, base)
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.lower().endswith(".jpg"):
                WIRED.append(os.path.join(d, f))

CROP_FRACTION = 0.085
done = 0
for path in WIRED:
    with Image.open(path) as im:
        w, h = im.size
        new_h = int(h * (1 - CROP_FRACTION))
        cropped = im.crop((0, 0, w, new_h))
        cropped.save(path, quality=92)
        done += 1

print(f"cropped {done} images by {CROP_FRACTION*100:.1f}% off the bottom")
