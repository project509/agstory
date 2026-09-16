"""Regenerate the nine class portraits (90x94) and class glyphs (16x16).

    python tools/art/make_portraits.py            # writes game/assets/... + manifest
    python tools/art/make_portraits.py --preview  # also writes a 4x comparison strip

WHY: the reference supplies four named busts (bork/tiny/gruk/spoof). Canon has
nine classes, so the other faces are cut from the clean B1 chibi sheet
(art/export/raider/raider_unlabelled_r*_c*.png: 1px-pitch, alpha-clean) - head
and shoulders, NEAREST x3 so the pitch matches the reference's 2-3px, bottom-
aligned so the shoulders are clipped by the frame like the reference busts.
Every choice is data below so the set can be regenerated when a sprite changes.
"""
import json, os, sys
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "art", "export", "raider")
OUT_PORTRAIT = os.path.join(ROOT, "game", "assets", "portraits")
OUT_ICON = os.path.join(ROOT, "game", "assets", "ui", "icons")
MANIFEST = os.path.join(ROOT, "art", "ref", "manifests", "portraits.json")
W, H = 90, 94
SCALE = 4

# key -> spec. "src": sprite file (no .png); "rows": head-top-relative crop height
# in source px (bottom of bust); "shift": (dx, dy) nudges in source px;
# "edits": list of pixel edits at source res applied before scaling
# ("recolor": hue-remap by source colour class; "paint": explicit pixels).
SPECS = {
    "warrior": {"src": "raider_unlabelled_r3_c08", "rows": 23, "method": "B1 bust"},
    "monk":    {"src": "raider_unlabelled_r2_c07", "rows": 23, "method": "B1 bust"},
    "rogue":   {"src": "raider_unlabelled_r1_c11", "rows": 23, "method": "B1 bust"},
    "cleric":  {"src": "raider_unlabelled_r3_c02", "rows": 23, "method": "B1 bust"},
    "druid":   {"src": "raider_unlabelled_r3_c01", "rows": 23, "method": "B1 bust"},
    "shaman":  {"src": "raider_unlabelled_r5_c08", "rows": 23, "method": "B1 bust"},
    "bard":    {"src": "raider_unlabelled_r1_c12", "rows": 23, "method": "B1 bust"},
    "mage":    {"src": "raider_unlabelled_r3_c03", "rows": 23, "method": "B1 bust"},
    "wizard":  {"src": "raider_unlabelled_r3_c05", "rows": 23, "method": "B1 bust"},
}

def load(name):
    return np.array(Image.open(os.path.join(SRC, name + ".png")).convert("RGBA")).astype(np.int32)

def clean(a, min_blob=6, hole=(22, 17, 26)):
    """Hard alpha; drop tiny fringe speckles; refill enclosed holes (the sheet key ate
    the sprites' own dark outlines wherever they matched the navy ground)."""
    from collections import deque
    a = a.copy()
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    h, w = a.shape[:2]
    def components(mask):
        lab = np.zeros((h, w), int); n = 0; sizes = []
        for y in range(h):
            for x in range(w):
                if mask[y, x] and not lab[y, x]:
                    n += 1; q = deque([(y, x)]); lab[y, x] = n; sz = 0
                    while q:
                        cy, cx = q.popleft(); sz += 1
                        for ny, nx in ((cy+1,cx),(cy-1,cx),(cy,cx+1),(cy,cx-1)):
                            if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not lab[ny, nx]:
                                lab[ny, nx] = n; q.append((ny, nx))
                    sizes.append(sz)
        return lab, sizes
    solid = a[..., 3] == 255
    lab, sizes = components(solid)
    for i, sz in enumerate(sizes):
        if sz < min_blob:
            a[lab == i + 1, 3] = 0
    # holes: transparent regions that do not touch the image border
    clear = a[..., 3] == 0
    lab, sizes = components(clear)
    border = set(lab[0]) | set(lab[-1]) | set(lab[:, 0]) | set(lab[:, -1])
    for i in range(1, len(sizes) + 1):
        if i not in border:
            a[lab == i, :3] = hole; a[lab == i, 3] = 255
    a[a[..., 3] == 0, :3] = 0
    return a

def bust(a, rows, shift=(0, 0)):
    """Crop head+shoulders: from the first opaque row, `rows` rows down."""
    ys = np.where(a[..., 3].any(axis=1))[0]; top = int(ys[0]) + shift[1]
    crop = a[max(top, 0):top + rows]
    xs = np.where(crop[..., 3].any(axis=0))[0]
    crop = crop[:, xs[0]:xs[-1] + 1]
    return crop

def outline(a, col=(14, 12, 18)):
    """1px dark outline (source res) wherever a transparent pixel touches the body."""
    s = a[..., 3] == 255
    nb = np.zeros_like(s)
    nb[1:] |= s[:-1]; nb[:-1] |= s[1:]; nb[:, 1:] |= s[:, :-1]; nb[:, :-1] |= s[:, 1:]
    edge = nb & ~s
    out = a.copy(); out[edge, :3] = col; out[edge, 3] = 255
    return out

def relight(a):
    """Reference key light: warm and a touch brighter at the top, cooler/darker low."""
    h = a.shape[0]; out = a.astype(np.float32)
    t = np.linspace(0.0, 1.0, h)[:, None, None]
    gain = (1.06 - 0.22 * t)
    tint = np.array([1.03, 1.0, 0.96]) * (1 - t) + np.array([0.94, 0.97, 1.05]) * t
    out[..., :3] = np.clip(out[..., :3] * gain * tint, 0, 255)
    return out.astype(np.int32)

def compose(crop):
    """NEAREST x3 onto a transparent 90x94, centred, bottom-aligned (frame clips shoulders)."""
    im = Image.fromarray(crop.astype(np.uint8)).resize((crop.shape[1] * SCALE, crop.shape[0] * SCALE), Image.NEAREST)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = (W - im.width) // 2; y = H - im.height
    canvas.alpha_composite(im, (x, max(y, 0)) if y >= 0 else (x, 0))
    return canvas

def make_portrait(key, spec):
    a = clean(load(spec["src"]))
    a = outline(a)
    crop = bust(a, spec["rows"], spec.get("shift", (0, 0)))
    # cut row: re-outline the top only (bottom edge is clipped by the frame, like the reference)
    crop = relight(crop)
    return compose(crop)

def preview(portraits, path):
    refs = [Image.open(os.path.join(OUT_PORTRAIT, n + ".png")).convert("RGBA") for n in ("bork", "tiny", "gruk", "spoof")]
    ims = refs + [portraits[k] for k in SPECS]
    strip = Image.new("RGBA", (len(ims) * (W + 6) + 6, H + 12), (11, 20, 31, 255))
    for i, im in enumerate(ims):
        strip.alpha_composite(im, (6 + i * (W + 6), 6))
    strip.resize((strip.width * 3, strip.height * 3), Image.NEAREST).save(path)

def main():
    prev = "--preview" in sys.argv
    portraits = {k: make_portrait(k, s) for k, s in SPECS.items()}
    if "--dry" not in sys.argv:
        for k, im in portraits.items():
            im.save(os.path.join(OUT_PORTRAIT, f"class_{k}.png"))
    if prev:
        preview(portraits, sys.argv[sys.argv.index("--preview") + 1])

if __name__ == "__main__":
    main()
