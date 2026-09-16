"""Class busts for the five classes the reference never drew.

The four reference busts (bork/tiny/gruk/spoof — warrior/rogue/cleric/mage)
are the only portrait art at the right density and finish. The hand-authored
and upscaled attempts were rejected (art/export/portraits_rejected/), so the
remaining classes are DERIVED: a reference bust with its defining regions
re-hued in HSV — the luminance stays, so the painted shading survives — plus
a few drawn pixels for the silhouette (a leaf, a feather). Palette swaps are
how pixel games have always stretched a cast; the faces repeat, the classes
read.

  monk    <- bork   scalp shaved to skin, beard -> brown, plate flattened
                    into a saffron robe (the metal's shine compressed away)
  wizard  <- spoof  hat and robe -> violet, hair -> grey, a painted white
                    beard and moustache, a star on the hat
  druid   <- tiny   green hood -> moss, leaf pixels at the brow
  bard    <- spoof  blue hat -> wine, a gold feather
  shaman  <- gruk   steel helm -> bone mask, teal paint

Writes game/assets/portraits/class_<key>.png at the reference's 90x94.
"""
import numpy as np
from PIL import Image
import colorsys

SRC = "game/assets/portraits/"


def to_hsv(a):
    r, g, b = a[..., 0] / 255, a[..., 1] / 255, a[..., 2] / 255
    mx, mn = np.max(a[..., :3], axis=-1) / 255, np.min(a[..., :3], axis=-1) / 255
    v = mx
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    d = np.maximum(mx - mn, 1e-6)
    h = np.zeros_like(v)
    h = np.where(mx == r, ((g - b) / d) % 6, h)
    h = np.where(mx == g, (b - r) / d + 2, h)
    h = np.where(mx == b, (r - g) / d + 4, h)
    h = np.where(mx - mn < 1e-6, 0, h) / 6.0
    return h, s, v


def from_hsv(h, s, v):
    out = np.zeros(h.shape + (3,), float)
    for idx in np.ndindex(h.shape):
        out[idx] = colorsys.hsv_to_rgb(h[idx] % 1.0, min(1, max(0, s[idx])), min(1, max(0, v[idx])))
    return (out * 255).round().astype(np.uint8)


def in_hue(h, lo, hi):
    return (h >= lo) & (h <= hi) if lo <= hi else (h >= lo) | (h <= hi)


def rehue(a, mask, hue, sat=None, val_mul=1.0, val_add=0.0):
    h, s, v = to_hsv(a)
    h2 = np.where(mask, hue, h)
    s2 = np.where(mask, sat if sat is not None else s, s)
    v2 = np.where(mask, np.clip(v * val_mul + val_add, 0, 1), v)
    rgb = from_hsv(h2, s2, v2)
    out = a.copy()
    out[..., :3] = rgb
    return out


def repaint(a, mask, rgb, lo=0.35, hi=0.95, sat_mul=1.0):
    """Recolour `mask` to `rgb`, keeping the region's own shading: its value
    range is normalised into [lo, hi] so metal highlights can be flattened
    (small hi-lo) or kept (wide)."""
    h, s, v = to_hsv(a)
    th, ts, tv = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    vv = v[mask]
    vmin, vmax = (vv.min(), vv.max()) if vv.size else (0, 1)
    span = max(1e-6, vmax - vmin)
    out = a.copy()
    h2 = np.where(mask, th, h)
    s2 = np.where(mask, np.clip(ts * sat_mul, 0, 1), s)
    v2 = np.where(mask, lo + (hi - lo) * (v - vmin) / span, v)
    out[..., :3] = from_hsv(h2, s2, v2)
    return out


def stamp(a, x0, y0, rows, palette, cell=2):
    """Paint a character grid at (x0, y0) in `cell`-px blocks; '.' leaves the
    pixel alone. The busts are 2x art, so features are drawn in 2px cells."""
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != ".":
                block(a, x0 + i * cell, y0 + j * cell, palette[ch], cell, cell)


def block(a, x, y, rgb, w=2, h=2):
    for dx in range(w):
        for dy in range(h):
            px(a, x + dx, y + dy, rgb)


def load(name):
    return np.asarray(Image.open(SRC + name + ".png").convert("RGBA")).astype(float)


def save(a, key):
    Image.fromarray(a.astype(np.uint8), "RGBA").save(SRC + f"class_{key}.png")
    print("  class_%s.png" % key)


def px(a, x, y, rgb):
    if 0 <= y < a.shape[0] and 0 <= x < a.shape[1]:
        a[y, x, :3] = rgb
        a[y, x, 3] = 255


def main():
    # ---- bork: warrior. Red-orange hair/beard (hue ~0.02–0.09, saturated),
    # grey plate (low saturation, mid value), skin (hue ~0.05–0.1, lighter, less sat).
    bork = load("bork")
    h, s, v = to_hsv(bork)
    alpha = bork[..., 3] > 0
    hair = alpha & in_hue(h, 0.0, 0.09) & (s > 0.55) & (v > 0.35)
    skin = alpha & in_hue(h, 0.04, 0.12) & (s > 0.25) & (s <= 0.55) & (v > 0.5)
    plate = alpha & (s < 0.22) & (v > 0.2) & (v < 0.85) & ~hair & ~skin
    # keep the dark backdrop ring (the bust's own plate) untouched: it is low value
    plate &= v > 0.28
    ys = np.arange(bork.shape[0])[:, None] * np.ones_like(hair, dtype=int)
    skin_rgb = tuple(int(c) for c in np.median(bork[skin][:, :3], axis=0))
    # MONK: canon's Monk wears a headband, so the monk is bork with brown hair,
    # a saffron cloth robe (the plate's value range compressed so the metal
    # stops shining) and an orange headband stamped across the brow, knotted
    # at the right with two tails. Shaving the painted hair by mask was tried
    # three ways and always left a halo or ate the brows; this keeps the paint.
    monk = repaint(bork, hair, (118, 76, 42), 0.22, 0.72)                 # brown
    monk = repaint(monk, plate, (242, 152, 62), 0.46, 0.90, 1.0)           # saffron cloth
    band, band_d, band_l = (232, 132, 40), (150, 78, 22), (250, 178, 96)
    pal = {"B": band, "d": band_d, "l": band_l}
    stamp(monk, 34, 27, ["dlllBBBBBBBBBBBBBd", "dBBBBBBBBBBBBBBddd"], pal)     # the band, on the brow
    stamp(monk, 68, 25, ["dBd", "BlB", "dBd"], pal)                           # the knot
    stamp(monk, 72, 29, ["Bd..", ".Bd.", "..Bd", "...d"], pal)                # a tail
    stamp(monk, 72, 27, ["..Bd", "...B", "....", "...."], pal)                # the other
    save(monk, "monk")

    # WIZARD: the mage grown old. From spoof (below) — see there.

    # ---- tiny: rogue, green hood (hue 0.2–0.45).    # ---- tiny: rogue, green hood (hue 0.2–0.45).
    tiny = load("tiny")
    h, s, v = to_hsv(tiny)
    alpha = tiny[..., 3] > 0
    hood = alpha & in_hue(h, 0.18, 0.48) & (s > 0.25)
    druid = rehue(tiny, hood, 0.09, 0.55, 0.8)                 # bark brown hood
    # moss and a leaf sprig at the brow (drawn, 2x pixels)
    leaf, moss = (126, 176, 76), (72, 118, 52)
    for (x, y) in [(38, 12), (40, 12), (36, 14), (38, 14), (40, 14), (42, 14), (38, 16), (40, 16)]:
        for dx in (0, 1):
            for dy in (0, 1):
                px(druid, x + dx, y + dy, leaf)
    for (x, y) in [(44, 16), (46, 18), (34, 16), (32, 18)]:
        for dx in (0, 1):
            for dy in (0, 1):
                px(druid, x + dx, y + dy, moss)
    save(druid, "druid")

    # ---- spoof: mage, blue hat/robe (hue 0.55–0.72).
    spoof = load("spoof")
    h, s, v = to_hsv(spoof)
    alpha = spoof[..., 3] > 0
    blue = alpha & in_hue(h, 0.52, 0.74) & (s > 0.3)
    bard = rehue(spoof, blue, 0.90, 0.6, 0.95)                 # wine
    gold, gold_d = (240, 196, 80), (170, 130, 40)
    # a feather sweeping up-right from the hat band
    for i, (x, y) in enumerate([(56, 20), (58, 18), (60, 16), (62, 14), (64, 12), (66, 10), (68, 8)]):
        for dx in (0, 1):
            for dy in (0, 1):
                px(bard, x + dx, y + dy, gold if i % 2 == 0 else gold_d)
        px(bard, x, y + 2, gold_d); px(bard, x + 1, y + 2, gold_d)
    save(bard, "bard")

    # WIZARD: spoof grown old. Hat and robe to violet-grey (the backdrop is
    # blue too, so the mask needs value), the hair under the brim to grey, a
    # pixel beard and moustache stamped in 2px cells, a star on the hat.
    ys = np.arange(spoof.shape[0])[:, None] * np.ones_like(blue, dtype=int)
    cloth = blue & (v > 0.28)
    wiz = repaint(spoof, cloth, (98, 76, 140), 0.22, 0.80)                 # violet-grey
    xs = np.arange(spoof.shape[1])[None, :] * np.ones_like(blue, dtype=int)
    side = ((xs < 44) | (xs > 64)) & (ys > 30) & (ys < 47)
    hair_sp = alpha & side & in_hue(h, 0.95, 0.12) & (s > 0.3) & (v > 0.15) & (v <= 0.45)
    wiz = repaint(wiz, hair_sp, (160, 162, 172), 0.32, 0.72, 0.15)        # grey
    W_, w_, g_ = (236, 236, 240), (196, 198, 206), (140, 144, 156)
    pal = {"W": W_, "w": w_, "g": g_}
    stamp(wiz, 44, 48, ["wW....Ww"], pal)                                  # moustache, mouth between
    stamp(wiz, 42, 52, [
        "..wwwwwwww..",
        ".wwWWWWWWww.",
        ".wgWWWWWWwg.",
        "..gwWWWWwg..",
        "..gwWWWWwg..",
        "...gwWWwg...",
        "....gwwg....",
        ".....gg.....",
    ], pal)
    star, star_d = (240, 196, 80), (170, 130, 40)
    stamp(wiz, 30, 8, [
        "..S..",
        ".sSs.",
        "SSSSS",
        ".sSs.",
        "..S..",
    ], {"S": star, "s": star_d})
    save(wiz, "wizard")

    # ---- gruk: cleric, steel helm (low sat, high value).
    gruk = load("gruk")
    h, s, v = to_hsv(gruk)
    alpha = gruk[..., 3] > 0
    steel = alpha & (s < 0.25) & (v > 0.45)
    shaman = rehue(gruk, steel, 0.11, 0.35, 0.92)              # bone
    teal = (64, 168, 160)
    # paint: two teal bars under the eye line (reference eye rows ~ y 44–48)
    for (x, y) in [(30, 50), (32, 50), (34, 50), (52, 50), (54, 50), (56, 50)]:
        for dx in (0, 1):
            for dy in (0, 1):
                px(shaman, x + dx, y + dy, teal)
    save(shaman, "shaman")

    # contact sheet
    names = ["bork", "monk", "wizard", "tiny", "druid", "spoof", "bard", "gruk", "shaman"]
    ims = [Image.open(SRC + (n if n in ("bork", "tiny", "spoof", "gruk") else "class_" + n) + ".png").convert("RGBA") for n in names]
    Z = 2
    sheet = Image.new("RGBA", (len(ims) * (90 * Z + 8), 94 * Z + 8), (12, 21, 29, 255))
    for i, im in enumerate(ims):
        sheet.alpha_composite(im.resize((90 * Z, 94 * Z), Image.NEAREST), (4 + i * (90 * Z + 8), 4))
    sheet.save("build/_busts_derived.png")
    print("DERIVE_BUSTS OK")


if __name__ == "__main__":
    main()
