"""Cut a painted ROTOR out of a scene plate and patch the plate behind it (STAGE-14, W4-LIFE).

The aerial town plate paints its two windmills with their sails standing still,
and a windmill that never turns is the first thing a title screen gives away.
SceneStage's `rotor` layer spins a Sprite2D about its centre; this script makes
that sprite the plate's OWN sails — the blades and the hub, cut by a mask — and
paints the blades out of the plate underneath so nothing is drawn twice. At
rotation 0 the sprite over the patched plate is pixel-for-pixel the original
(the mask is hard-edged, the sprite carries the plate's pixels), so a
reduced-motion frame looks exactly like the painting did.

The patch is the inpainter tools/art/patch_bubbles.py names for this job, but
by diffusion rather than by a ring-matched block copy: the blades cross a
tower, a roof and a field, and no block from elsewhere fits all three. Each
masked pixel takes the mean of the clean pixels within two of it, rim inward
until the mask is full, then two 3x3 passes inside the mask soften the seams.
The result under a blade is a soft band of the colours on either side (the
same fill cv2's Telea/NS inpaint gives here, compared side by side — W4-LIFE
report), which reads as the sails' shadow once the sprite turns over it. That
is STAGE-14's "~40x40 hub patch" plus the blades.

`ROTORS` is the whole recipe (hub, blade length and width, blade angles, the
sprite canvas); it is data in this file rather than command-line numbers so the
byte check can run with no arguments. Reads art/src/bg/<plate>_raw.png — the
untouched plate, created from game/assets/bg/<plate>.png on the first run and
the source of truth after it (the same place the other raw plates live) — and
writes game/assets/bg/<plate>.png plus game/assets/vfx/life/<name>.png for each
rotor. Deterministic (no RNG, PNGs encoded without optimisation) so:

    python tools/art/patch_plate.py            # write the patched plate + the sails
    python tools/art/patch_plate.py --check    # regenerate in memory, byte-compare
                                               # with the tree; exit 1 on DIFFERS /
                                               # MISSING (build_art.sh, like gen_actors.py)
"""
import argparse
import io
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW = "art/src/bg"
BG = "game/assets/bg"
OUT = "game/assets/vfx/life"

# plate -> [rotor]. hub = the sail's axle on the plate (measured at 8x, W4-LIFE
# report); length/width in plate pixels along/across each blade; angles are the
# blades' directions in screen degrees (0 = +x, 90 = +y, i.e. down); canvas is
# the sprite's square size (the hub is its centre, so the sprite rotates about
# the axle in Godot with `centered` on and no offset).
ROTORS = {
    "stage_town": [
        {"name": "sail_a", "hub": (1337, 328), "length": 32, "width": 9,
         "angles": (43, 133, 223, 313), "hub_r": 5, "canvas": 96},
        {"name": "sail_b", "hub": (1291, 434), "length": 34, "width": 10,
         "angles": (45, 135, 225, 315), "hub_r": 5, "canvas": 96},
    ],
}


def blade_masks(shape, rotor):
    """One boolean mask per blade (a band from the hub outward) and the hub disc."""
    h, w = shape
    cx, cy = rotor["hub"]
    ys, xs = np.mgrid[0:h, 0:w]
    dx, dy = xs - cx + 0.5 - 0.5, ys - cy
    blades = []
    for ang in rotor["angles"]:
        t = np.deg2rad(ang)
        ux, uy = np.cos(t), np.sin(t)
        along = dx * ux + dy * uy
        across = -dx * uy + dy * ux
        band = (along >= -1) & (along <= rotor["length"]) & (np.abs(across) <= rotor["width"] / 2.0)
        blades.append((band, (ux, uy)))
    hub = (dx * dx + dy * dy) <= rotor["hub_r"] ** 2
    return blades, hub


def diffuse(a, mask, radius=2, blur_passes=2):
    """Fill `mask` in `a` (float RGBA) from its rim inward: every pass gives each
    masked pixel with a clean pixel within `radius` the mean of those pixels,
    until none is left; then `blur_passes` 3x3 means inside the mask."""
    H, W = mask.shape
    left = mask.copy()
    while left.any():
        ys, xs = np.nonzero(left)
        fills = []
        for y, x in zip(ys, xs):
            y0, y1 = max(0, y - radius), min(H, y + radius + 1)
            x0, x1 = max(0, x - radius), min(W, x + radius + 1)
            win, clean = a[y0:y1, x0:x1], ~left[y0:y1, x0:x1]
            if clean.any():
                fills.append((y, x, win[clean].mean(axis=0)))
        if not fills:
            break
        for y, x, c in fills:
            a[y, x] = c
            left[y, x] = False
    for _ in range(blur_passes):
        b = a.copy()
        for y, x in zip(*np.nonzero(mask)):
            b[y, x] = a[max(0, y - 1):y + 2, max(0, x - 1):x + 2].reshape(-1, 4).mean(axis=0)
        a = b
    return a


def cut_and_patch(plate, rotor):
    """Returns (patched plate array, sprite image) for one rotor."""
    blades, hub = blade_masks(plate.shape[:2], rotor)
    mask = hub.copy()
    for band, _ in blades:
        mask |= band
    # the sprite: the plate's own pixels inside the mask, hub at the canvas centre
    n = rotor["canvas"]
    cx, cy = rotor["hub"]
    x0, y0 = cx - n // 2, cy - n // 2
    sprite = np.zeros((n, n, 4), np.uint8)
    src = plate[y0:y0 + n, x0:x0 + n].astype(np.uint8)
    m = mask[y0:y0 + n, x0:x0 + n]
    sprite[m, :3] = src[m, :3]
    sprite[m, 3] = 255
    # the patch: the whole footprint, diffused from its rim
    a = diffuse(plate.astype(float), mask)
    return a.clip(0, 255).astype(np.uint8), Image.fromarray(sprite, "RGBA")


def encode(img):
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=False)
    return buf.getvalue()


def build(check):
    files = {}
    for plate_name, rotors in ROTORS.items():
        raw = os.path.join(ROOT, RAW, plate_name + "_raw.png")
        live = os.path.join(ROOT, BG, plate_name + ".png")
        if not os.path.exists(raw):
            if check:
                print("  MISSING  %s/%s_raw.png (the untouched plate; run without --check once)" % (RAW, plate_name))
                print("PATCH_PLATE CHECK FAILED")
                return 1
            os.makedirs(os.path.dirname(raw), exist_ok=True)
            with open(live, "rb") as f, open(raw, "wb") as g:
                g.write(f.read())
            print("  kept the untouched plate as %s/%s_raw.png" % (RAW, plate_name))
        plate = np.asarray(Image.open(raw).convert("RGBA"))
        for rotor in rotors:
            plate, sprite = cut_and_patch(plate, rotor)
            files["%s/%s.png" % (OUT, rotor["name"])] = encode(sprite)
            print("  %-10s hub %s  %d blades x %dpx  canvas %dx%d" % (
                rotor["name"], rotor["hub"], len(rotor["angles"]), rotor["length"], rotor["canvas"], rotor["canvas"]))
        # The plates ship as RGB (no alpha channel); keep that shape.
        files["%s/%s.png" % (BG, plate_name)] = encode(Image.fromarray(plate[:, :, :3], "RGB"))

    if check:
        rc = 0
        for rel in sorted(files):
            tree = os.path.join(ROOT, rel)
            have = open(tree, "rb").read() if os.path.exists(tree) else None
            if have == files[rel]:
                continue
            print("  %s  %s" % ("DIFFERS" if have is not None else "MISSING", rel))
            rc = 1
        print("PATCH_PLATE CHECK %s  (%d files)" % ("OK" if rc == 0 else "FAILED", len(files)))
        return rc

    for rel in sorted(files):
        path = os.path.join(ROOT, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(files[rel])
        print("  wrote %s" % rel)
    print("PATCH_PLATE OK  (%d files)" % len(files))
    return 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="byte-compare with the tree, write nothing")
    sys.exit(build(ap.parse_args().check))
