#!/usr/bin/env python3
"""gen_clouds.py — two tileable cloud layers for the town's sky (STAGE-14, PIPE-10).

    python tools/art/gen_clouds.py            # write game/assets/vfx/clouds_far.png, clouds_near.png
    python tools/art/gen_clouds.py --check    # regenerate in memory, byte-compare with the tree, exit 1 on a diff
    python tools/art/gen_clouds.py --out DIR  # write under DIR/game/assets/vfx/ instead (the Lua `out=` shape)

Each layer is 1536x220 RGBA and PERIODIC IN X: the noise lattice wraps at the
frame width, so a UV-scroll (SceneStage.add_scroll, W2-STAGE2) never shows a
seam. `far` is thin, dense wisps at low alpha; `near` is bigger puffs at
higher alpha. The palette is not authored: it is sampled from the sky rows of
game/assets/bg/stage_town.png itself (the region STAGE-14 measured, x 600..1536,
y 0..200), so the clouds are the plate's own light and shadow — never pure
white. Shading is "lit from above": where the density falls off upward a pixel
is the top of a puff and takes the light tone; where it is denser above, the
shadow tone. Alpha is quantised to 16 steps and the tone to three levels so
the layer stays crisp over the painted plate rather than a soft blur.

Deterministic: numpy's Generator seeded per layer, pure array ops, PNG written
without optimisation, so a re-run reproduces the bytes (--check proves it).
build_art.sh --check runs only the Lua generators; this file carries its own
--check for the same reason.
"""
import io
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLATE = "game/assets/bg/stage_town.png"
OUT_DIR = "game/assets/vfx"
W, H = 1536, 220
SKY_RECT = (600, 0, 1536, 200)        # x0, y0, x1, y1 on the plate

LAYERS = {
    # name:        seed, lattice cells across (period), cell height, coverage lo/hi, alpha max, fade-in rows, fade-out from row
    # the plate's open sky is its top ~60 rows (the mountains begin under that), so both
    # layers are dense at the top and thin out well before row 200
    "clouds_far":  dict(seed=7011, nx=8, cell_h=48.0,  lo=0.50, hi=0.64, amax=0.60, fade_top=10, fade_from=70),
    "clouds_near": dict(seed=7023, nx=4, cell_h=110.0, lo=0.58, hi=0.74, amax=0.72, fade_top=4,  fade_from=100),
}


def sky_palette(plate_path):
    """(light, shadow, sky) as float RGB triples read off the plate's own sky."""
    im = Image.open(plate_path).convert("RGB")
    x0, y0, x1, y1 = SKY_RECT
    a = np.asarray(im, dtype=np.float64)[y0:y1, x0:x1].reshape(-1, 3)
    lum = a @ np.array([0.299, 0.587, 0.114])
    bright = a[lum >= np.percentile(lum, 90)].mean(axis=0)
    mid = (lum > np.percentile(lum, 25)) & (lum < np.percentile(lum, 75))
    blueish = a[mid & (a[:, 2] > a[:, 0] + 25)]
    sky = blueish.mean(axis=0) if len(blueish) else a[mid].mean(axis=0)
    light = np.minimum(bright, 244.0)                 # never pure white
    shadow = light * 0.62 + sky * 0.38
    return light, shadow, sky


def value_noise_periodic(rng, nx, cell_h):
    """Smooth value noise on a lattice `nx` cells wide that wraps at W."""
    ny = int(np.ceil(H / cell_h)) + 2
    lat = rng.random((ny, nx))
    xs = np.arange(W) * nx / W
    ys = np.arange(H) / cell_h
    xi = np.floor(xs).astype(int)
    yi = np.floor(ys).astype(int)
    xf = xs - xi
    yf = ys - yi
    sx = xf * xf * (3 - 2 * xf)
    sy = yf * yf * (3 - 2 * yf)
    x0 = xi % nx
    x1 = (xi + 1) % nx
    y0 = np.clip(yi, 0, ny - 1)
    y1 = np.clip(yi + 1, 0, ny - 1)
    a = lat[y0[:, None], x0[None, :]]
    b = lat[y0[:, None], x1[None, :]]
    c = lat[y1[:, None], x0[None, :]]
    d = lat[y1[:, None], x1[None, :]]
    top = a + (b - a) * sx[None, :]
    bot = c + (d - c) * sx[None, :]
    return top + (bot - top) * sy[:, None]


def fbm(rng, nx, cell_h, octaves=5, persistence=0.5):
    total = np.zeros((H, W))
    amp, norm = 1.0, 0.0
    for _ in range(octaves):
        total += amp * value_noise_periodic(rng, nx, cell_h)
        norm += amp
        amp *= persistence
        nx *= 2
        cell_h /= 2.0
    return total / norm


def layer(spec, light, shadow):
    rng = np.random.default_rng(spec["seed"])
    n = fbm(rng, spec["nx"], spec["cell_h"])
    n = (n - n.mean()) / (n.std() + 1e-9) * 0.18 + 0.5   # a stable contrast whatever the seed
    cov = np.clip((n - spec["lo"]) / (spec["hi"] - spec["lo"]), 0.0, 1.0)
    cov = cov * cov * (3 - 2 * cov)
    y = np.arange(H, dtype=np.float64)[:, None]
    fade_in = np.clip(y / max(1, spec["fade_top"]), 0.0, 1.0)
    fade_out = np.clip((H - y) / float(H - spec["fade_from"]), 0.0, 1.0)
    alpha = cov * fade_in * fade_out * spec["amax"]
    # lit from above: the top of a puff is where the density falls off upward
    up = np.roll(n, 3, axis=0)
    shade = np.clip((n - up) * 6.0 + 0.5, 0.0, 1.0)
    tone = np.floor(shade * 3.0).clip(0, 2)               # 0 shadow, 1 mid, 2 light
    mid = (light + shadow) / 2.0
    rgb = np.empty((H, W, 3), dtype=np.float64)
    for k, colour in enumerate((shadow, mid, light)):
        rgb[tone == k] = colour
    a8 = np.floor(alpha * 16.0) * 16.0
    a8 = np.clip(a8, 0, 240).astype(np.uint8)
    out = np.dstack([rgb.astype(np.uint8), a8])
    out[a8 == 0] = 0                                       # clear pixels carry no colour
    return out


def encode(arr):
    buf = io.BytesIO()
    Image.fromarray(arr, "RGBA").save(buf, format="PNG", optimize=False)
    return buf.getvalue()


def main(argv):
    check = "--check" in argv
    out_prefix = ""
    if "--out" in argv:
        out_prefix = argv[argv.index("--out") + 1]
    light, shadow, _sky = sky_palette(os.path.join(ROOT, PLATE))
    rc = 0
    for name, spec in LAYERS.items():
        data = encode(layer(spec, light, shadow))
        rel = os.path.join(OUT_DIR, name + ".png")
        tree = os.path.join(ROOT, rel)
        if check:
            have = open(tree, "rb").read() if os.path.exists(tree) else None
            if have == data:
                print("  agree    %s" % rel)
            else:
                print("  DIFFERS  %s" % rel if have is not None else "  MISSING  %s" % rel)
                rc = 1
            continue
        dest = os.path.join(out_prefix, rel) if out_prefix else tree
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "wb") as f:
            f.write(data)
        print("  %-58s %dx%d" % (dest, W, H))
    print("GEN_CLOUDS %s" % ("CHECK OK" if (check and rc == 0) else ("CHECK FAILED" if check else "OK")))
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
