"""Pre-render the wordmark and tagline (art/ref/specs/05 §"Wordmark", 01 §5, 03 §6),
and from the same lockup the exported build's first frame: the boot splash, the
square application icon and the Windows .ico (build/plan/artaudit CRITIC-G01).

There is exactly one wordmark and it never changes, so it is rendered once here
with PIL rather than shaded live: pixel-identical between game and diff, and no
shader for a gradient on fourteen letters. Grenze Gotisch at wght 600, condensed
to the reference's measured run width (the reference's blackletter is narrower
than Grenze), with 01 §5's vertical metallic ramp, a 1px warm-dark outline and
05's soft 2px drop shadow.

Writes game/assets/ui/wordmark_58.png (+ .json with baseline_y / cap_top_y),
wordmark_44.png and wordmark_tagline.png — byte-identical run to run, because
the pipeline for those three is untouched by the splash work below — and
wordmark_33.png, Concept 2's compact header mark (spec 02 §4.1: the Concept 1
mark at scale 0.76, 224x33 at x 96, baseline 48; build/plan/artaudit COMBAT-12):
the wordmark_58 parameters times 0.76, through the same render_mark(), so it is
the same drawing smaller rather than a resample of the 58. game/ui/Frame.gd's
LOCKUPS["33_compact"] places it.

Then, from the same parts:
  splash.png    1536x1024 on Palette.GROUND_PAGE: the Home lockup (01 §5 emblem +
                wordmark_58, 03 §6 tagline + trailing rule) at 2x. The emblem is
                sliced pixel art and is doubled NEAREST; the wordmark and tagline
                are re-rendered from the fonts at double size so they stay crisp
                rather than being doubled from the 1x bitmaps. Godot letterboxes
                the splash on the same colour (application/boot_splash/bg_color),
                so the image edge is invisible on any window shape.
  icon_256.png  256x256: a GROUND_PAGE plate with a 2px EDGE_BRONZE rim, corners
                rounded, the emblem at 3x NEAREST centred. The emblem is an
                opaque 82x57 crop whose own ground is within two units of
                GROUND_PAGE, so its box vanishes into the plate.
  icon.ico      256/128/64/48/32/24/16 frames of the same, for the Windows
                executable (export_presets.cfg application/icon).
The colours are read out of game/ui/Palette.gd rather than restated here.

No text beyond the pre-rendered logotype and tagline goes into any of these
(RULES-14's one exception, pending docs/15 Q16).
"""
import json
import re
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONTS = "game/assets/fonts/"
OUT = "game/assets/ui/"
PALETTE = "game/ui/Palette.gd"
TEXT = "A Guild Story"
TAGLINE_TEXT = "Questionable people. Worse decisions."
# 01 §5 samples, top to bottom: highlight, mid band, lower, bottom edge.
# The reference reads as brushed metal: bright upper half, a darker band low, a
# lit bottom edge. Sampled from Concept 1 x 104–359, y 20–60.
# Stepped, not blended: the reference is pixel art and its metal is bands.
# Each entry is (band top as a fraction of the glyph box, colour).
RAMP = [(0.00, "#F7EFDD"), (0.34, "#E9D5B8"), (0.47, "#B59A81"), (0.66, "#C9AE93"), (0.86, "#E6CBB3")]
OUTLINE = "#413D3A"
TAGLINE_INK = (0xE0, 0xE0, 0xE0, 255)      # 03 §6
RULE_INK = "#988880"                        # Frame.gd's trailing rule
# The reference's strokes are thin for a blackletter; Grenze at 600 condensed
# closes its counters. 400 keeps them open.
WEIGHT = 450

SPLASH_SIZE = (1536, 1024)
SPLASH_SCALE = 2
ICON_SIZE = 256
ICO_SIZES = [256, 128, 64, 48, 32, 24, 16]


def hexrgb(h):
    """#RRGGBB -> floats 0..1 (everything below composites in 0..1)."""
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5))


def hex8(h):
    """#RRGGBB -> 8-bit RGBA tuple."""
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


def palette(name):
    """`const NAME := Color("RRGGBB")` out of Palette.gd, as "#RRGGBB"."""
    src = open(PALETTE, encoding="utf-8").read()
    m = re.search(r'const %s := Color\("([0-9A-Fa-f]{6})"\)' % name, src)
    if not m:
        raise SystemExit("gen_wordmark: Palette.gd has no %s" % name)
    return "#" + m.group(1).upper()


def ramp_rows(h):
    rows = np.zeros((h, 3), float)
    for y in range(h):
        t = y / max(1, h - 1)
        for top, c in RAMP:
            if t >= top:
                rows[y] = hexrgb(c)
    return rows


def render_mark(size, run_width, scale=1):
    """The logotype as an RGBA image plus its metrics. `scale` is the pixel
    density: 1 is the in-game mark (every number below is the shipped
    pipeline, untouched); 2 doubles the outline, shadow and padding so the
    splash's mark is the same drawing at twice the size, not a resample."""
    font = ImageFont.truetype(FONTS + "GrenzeGotisch.ttf", size)
    try:
        font.set_variation_by_axes([WEIGHT])
    except Exception as e:                     # a static build of the face: fine
        print("  (no variation axes:", e, ")")
    ascent, descent = font.getmetrics()
    pad = 6 * scale
    W, H = int(font.getlength(TEXT)) + pad * 2, ascent + descent + pad * 2
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).text((pad, pad + ascent), TEXT, font=font, fill=255, anchor="ls")
    cap = Image.new("L", (W, H), 0)
    ImageDraw.Draw(cap).text((pad, pad + ascent), "T", font=font, fill=255, anchor="ls")
    # Condense to the reference's run width (01 §5 / 03 §6), never widen.
    l, _, r, _ = mask.getbbox()
    k = min(1.0, run_width / (r - l))
    mask = mask.resize((int(W * k), H), Image.LANCZOS)
    cap = cap.resize((int(W * k), H), Image.LANCZOS)
    m = np.asarray(mask).astype(float) / 255
    grown = mask.filter(ImageFilter.MaxFilter(2 * scale + 1))
    outline = np.asarray(grown).astype(float) / 255
    shadow = np.asarray(grown.filter(ImageFilter.GaussianBlur(1.0 * scale)))
    shadow = np.roll(shadow, 2 * scale, axis=0).astype(float) / 255 * 0.35
    h, w = m.shape
    rgba = np.zeros((h, w, 4), float)
    # shadow, then outline, then the gradient fill — each layer over the last
    rgba[..., 3] = shadow
    oc = np.array(hexrgb(OUTLINE), float)
    a_o = outline
    rgba[..., :3] = rgba[..., :3] * (1 - a_o)[..., None] + oc * a_o[..., None]
    rgba[..., 3] = rgba[..., 3] * (1 - a_o) + a_o
    ys, xs = np.nonzero(m > 0.02)
    top, bot = ys.min(), ys.max()
    fill = np.zeros((h, w, 3), float)
    fill[top:bot + 1] = ramp_rows(bot - top + 1)[:, None, :]
    rgba[..., :3] = rgba[..., :3] * (1 - m)[..., None] + fill * m[..., None]
    rgba[..., 3] = rgba[..., 3] * (1 - m) + m
    img = Image.fromarray((rgba.clip(0, 1) * 255).astype(np.uint8), "RGBA")
    bb = img.getbbox()
    img = img.crop(bb)
    meta = {"baseline_y": int(pad + ascent - bb[1]), "cap_top_y": int(cap.getbbox()[1] - bb[1]),
            "size": list(img.size), "glyph_left": int(mask.getbbox()[0] - bb[0]), "condensed": k}
    return img, meta


def wordmark(size, run_width, name):
    img, meta = render_mark(size, run_width)
    img.save(OUT + name + ".png")
    k = meta.pop("condensed")
    json.dump(meta, open(OUT + name + ".json", "w"))
    print(f"  {name}: {img.size} baseline {meta['baseline_y']} cap_top {meta['cap_top_y']} condensed x{k:.3f}")


def render_tagline(scale=1):
    # 03 §6: cap height 11, colour #E0E0E0, the humanist sans, sentence case.
    font = ImageFont.truetype(FONTS + "FiraSans-Regular.ttf", 16 * scale)
    ascent, descent = font.getmetrics()
    pad = 2 * scale
    W = int(font.getlength(TAGLINE_TEXT)) + pad * 2
    img = Image.new("RGBA", (W, ascent + descent + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(img).text((pad, pad + ascent), TAGLINE_TEXT, font=font, fill=TAGLINE_INK, anchor="ls")
    bb = img.getbbox()
    return img.crop(bb), {"baseline_y": int(pad + ascent - bb[1]), "size": list(img.crop(bb).size)}


def tagline():
    img, meta = render_tagline()
    img.save(OUT + "wordmark_tagline.png")
    json.dump(meta, open(OUT + "wordmark_tagline.json", "w"))
    print("  tagline:", img.size, "baseline", meta["baseline_y"])


# ---------------------------------------------------------------- the first frame

EMBLEM_KEY_TOL = 28   # summed |dR|+|dG|+|dB| from the crop's own ground


def emblem_on(ground):
    """emblem.png with its baked crop ground keyed to `ground`.

    The emblem is an opaque 82x57 cut of Concept 1's header: its ground is a
    noisy dark navy around (7,14,22), two to four units off GROUND_PAGE, which
    reads as a faint box on the splash and inside the icon plate. Only the
    region CONNECTED to the border is keyed (a flood from the edges), so the
    eye sockets — the same navy, but enclosed — keep the artist's pixels."""
    img = Image.open(OUT + "emblem.png").convert("RGBA")
    px = np.asarray(img).astype(int)
    h, w, _ = px.shape
    border = np.concatenate([px[0, :, :3], px[-1, :, :3], px[:, 0, :3], px[:, -1, :3]])
    key = np.median(border, axis=0)
    near = np.abs(px[..., :3] - key).sum(axis=2) <= EMBLEM_KEY_TOL
    seen = np.zeros((h, w), bool)
    stack = [(y, x) for y in range(h) for x in range(w) if (y in (0, h - 1) or x in (0, w - 1)) and near[y, x]]
    while stack:
        y, x = stack.pop()
        if seen[y, x]:
            continue
        seen[y, x] = True
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and near[ny, nx] and not seen[ny, nx]:
                stack.append((ny, nx))
    out = px.astype(np.uint8)
    out[seen] = ground
    return Image.fromarray(out, "RGBA"), int(seen.sum())


def splash():
    """The Home lockup (game/ui/Frame.gd:173-207's geometry) at 2x, centred on
    GROUND_PAGE. At 1x the emblem box is 82 wide and the wordmark starts at its
    right edge (x 22 -> 104); the tagline hangs under the wordmark on its own
    baseline with a trailing rule out to the logotype's right edge."""
    s = SPLASH_SCALE
    ground = hex8(palette("GROUND_PAGE"))
    emblem, keyed = emblem_on(ground)
    emblem = emblem.resize((emblem.width * s, emblem.height * s), Image.NEAREST)
    mark, mm = render_mark(63 * s, 305 * s, s)          # the wordmark_58 numbers, doubled
    tag, tm = render_tagline(s)
    cap_h = mm["baseline_y"] - mm["cap_top_y"]
    # 03 §6 hangs the tagline 23px under the 44-mark's baseline (cap 36); the
    # same proportion under the 58-mark's cap (41) is 26 — doubled here.
    tag_gap = round(23 * cap_h / 36 / s) * s if cap_h else 26 * s
    block_h = cap_h + tag_gap + 4 * s             # caps top .. tagline baseline + a hair
    width = emblem.width + mark.width
    x0 = (SPLASH_SIZE[0] - width) // 2
    # Optical centre: a hair above the geometric one.
    top = (SPLASH_SIZE[1] - block_h) // 2 - SPLASH_SIZE[1] // 32
    img = Image.new("RGBA", SPLASH_SIZE, ground)
    mark_x = x0 + emblem.width
    baseline = top + cap_h
    img.alpha_composite(mark, (mark_x, baseline - mm["baseline_y"]))
    tag_base = baseline + tag_gap
    img.alpha_composite(tag, (mark_x, tag_base - tm["baseline_y"]))
    # The trailing rule: 2px at baseline-6 from text.right+6 to the logotype's
    # right edge (Frame.gd), doubled.
    rule_x = mark_x + tag.width + 6 * s
    rule_r = mark_x + mark.width
    if rule_r > rule_x:
        ImageDraw.Draw(img).rectangle([rule_x, tag_base - 6 * s, rule_r - 1, tag_base - 6 * s + 2 * s - 1],
                                      fill=hex8(RULE_INK))
    # The emblem is centred on the whole caps+tagline block, as in Concept 3.
    emblem_y = top + (block_h - emblem.height) // 2
    img.alpha_composite(emblem, (x0, emblem_y))
    img.save(OUT + "splash.png")
    print(f"  splash: {img.size} lockup x {x0}..{x0 + width} caps top {top} baseline {baseline}"
          f" tagline baseline {tag_base} ground {ground[:3]} emblem px keyed {keyed}")


def _rounded_plate(size, radius, fill, rim, rim_px):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=rim)
    d.rounded_rectangle([rim_px, rim_px, size - 1 - rim_px, size - 1 - rim_px],
                        radius=max(1, radius - rim_px), fill=fill)
    return img


def icon():
    """256x256 from the emblem: a GROUND_PAGE plate, EDGE_BRONZE rim, emblem at 3x."""
    ground, rim = hex8(palette("GROUND_PAGE")), hex8(palette("EDGE_BRONZE"))
    plate = _rounded_plate(ICON_SIZE, 36, ground, rim, 2)
    emblem, _ = emblem_on(ground)
    k = max(1, min((ICON_SIZE - 8) // emblem.width, (ICON_SIZE - 8) // emblem.height))
    emblem = emblem.resize((emblem.width * k, emblem.height * k), Image.NEAREST)
    plate.alpha_composite(emblem, ((ICON_SIZE - emblem.width) // 2, (ICON_SIZE - emblem.height) // 2))
    plate.save(OUT + "icon_256.png")
    print(f"  icon_256: {plate.size} emblem x{k} at {(ICON_SIZE - emblem.width) // 2},{(ICON_SIZE - emblem.height) // 2}")
    # Every .ico frame is made here, not by Pillow's own resampler: integer
    # reductions are box-averaged, the two odd sizes Lanczos, all from the 256.
    frames = []
    for n in ICO_SIZES[1:]:
        if ICON_SIZE % n == 0:
            frames.append(plate.reduce(ICON_SIZE // n))
        else:
            frames.append(plate.resize((n, n), Image.LANCZOS))
    plate.save(OUT + "icon.ico", sizes=[(n, n) for n in ICO_SIZES], append_images=frames)
    print("  icon.ico:", ICO_SIZES)


if __name__ == "__main__":
    # Sizes chosen for the reference's CAP HEIGHT (41 / 36 px, 01 §5 and 03 §6);
    # the run width is then met by condensing.
    wordmark(63, 305, "wordmark_58")   # 03 §1: C1 run x 104–408
    wordmark(55, 276, "wordmark_44")   # 03 §6: C3 run x 97–372
    # 02 §4.1: the compact header is the C1 mark at 0.76 (224x33 over 296x43),
    # so the 58's size and run scaled by the same factor: 63 -> 48, 305 -> 232.
    # Its right edge lands at 96 + width < 352 - 8 (RaidView/Results' plate).
    wordmark(48, 232, "wordmark_33")
    tagline()
    splash()
    icon()
    print("GEN_WORDMARK OK")
