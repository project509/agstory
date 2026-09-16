#!/usr/bin/env python3
"""refdiff — measure how close a live screenshot is to its reference concept.

The bar for this project is "indistinguishable from the reference". That is only
meaningful if it is measured, so this reports several complementary numbers
rather than one, because each hides a different kind of failure:

  MAE / RMSE      raw pixel error. Sensitive to everything, including a
                  1px layout shift that a human would not notice.
  structure       gradient-domain agreement. Catches "the panel is in the wrong
                  place" while forgiving "the panel is 2 shades darker".
  layout IoU      binary edge-map overlap. This is the one that answers "is the
                  furniture in the right place", which is what actually reads
                  as wrong to a player.
  palette EMD     how far the colour distributions are apart, ignoring position.
                  Catches "right layout, wrong mood".

  python tools/art/refdiff.py <shot.png> <ref#|ref.png> [--out report_dir]
                              [--region x,y,w,h] [--mask x,y,w,h ...]

--mask excludes a rect from the score. Use it for content that legitimately
differs (a name, a number, a randomised sprite) so the score reflects design
fidelity rather than test data.
"""
import sys, os, json
from PIL import Image
import numpy as np

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONCEPTS = {
    "1": "ideaboard/Reference Concepts/Reference Concept 1.png",
    "2": "ideaboard/Reference Concepts/Reference Concept 2.png",
    "3": "ideaboard/Reference Concepts/Reference Concept 3.png",
}


def load(p):
    q = CONCEPTS.get(str(p), str(p))
    if not os.path.isabs(q):
        q = os.path.join(ROOT, q)
    return Image.open(q).convert("RGB")


def edges(g):
    gx = np.zeros_like(g); gy = np.zeros_like(g)
    gx[:, 1:] = np.abs(np.diff(g, axis=1))
    gy[1:, :] = np.abs(np.diff(g, axis=0))
    return np.hypot(gx, gy)


def main(argv):
    shot_p, ref_p = argv[0], argv[1]
    out_dir, region, masks = None, None, []
    i = 2
    while i < len(argv):
        if argv[i] == "--out":
            out_dir = argv[i + 1]; i += 2
        elif argv[i] == "--region":
            region = tuple(int(v) for v in argv[i + 1].split(",")); i += 2
        elif argv[i] == "--mask":
            masks.append(tuple(int(v) for v in argv[i + 1].split(","))); i += 2
        else:
            i += 1

    shot, ref = load(shot_p), load(ref_p)
    if shot.size != ref.size:
        print(f"SIZE MISMATCH shot={shot.size} ref={ref.size} — cannot compare honestly.")
        return 2

    a = np.asarray(shot, dtype=np.float32)
    b = np.asarray(ref, dtype=np.float32)
    h, w, _ = a.shape

    keep = np.ones((h, w), dtype=bool)
    if region:
        keep[:] = False
        x, y, rw, rh = region
        keep[y:y + rh, x:x + rw] = True
    for (x, y, mw, mh) in masks:
        keep[y:y + mh, x:x + mw] = False

    d = np.abs(a - b).mean(axis=2)
    mae = float(d[keep].mean())
    rmse = float(np.sqrt((((a - b) ** 2).mean(axis=2))[keep].mean()))

    ga = np.asarray(shot.convert("L"), dtype=np.float32)
    gb = np.asarray(ref.convert("L"), dtype=np.float32)
    ea, eb = edges(ga), edges(gb)
    denom = (np.sqrt((ea[keep] ** 2).sum()) * np.sqrt((eb[keep] ** 2).sum())) + 1e-9
    structure = float((ea[keep] * eb[keep]).sum() / denom)

    ta, tb = ea > 24, eb > 24
    inter = float((ta & tb & keep).sum())
    union = float(((ta | tb) & keep).sum()) + 1e-9
    iou = inter / union

    def hist(img):
        q = (np.asarray(img)[keep] // 16).astype(np.int32)
        idx = q[:, 0] * 256 + q[:, 1] * 16 + q[:, 2]
        hh = np.bincount(idx, minlength=4096).astype(np.float64)
        return hh / hh.sum()
    ha, hb = hist(shot), hist(ref)
    palette_l1 = float(np.abs(ha - hb).sum() / 2.0)

    close = float((d[keep] <= 8).mean())

    res = {
        "shot": shot_p, "ref": ref_p, "size": list(shot.size),
        "mae": round(mae, 3), "rmse": round(rmse, 3),
        "structure": round(structure, 4), "layout_iou": round(iou, 4),
        "palette_divergence": round(palette_l1, 4),
        "pct_pixels_within_8": round(close * 100, 2),
    }
    print(json.dumps(res, indent=2))

    verdict = ("INDISTINGUISHABLE" if iou > 0.80 and mae < 6 else
               "VERY CLOSE" if iou > 0.65 and mae < 14 else
               "RECOGNISABLY THE SAME DESIGN" if iou > 0.45 else
               "DIFFERENT")
    print(f"verdict: {verdict}")

    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
        base = os.path.splitext(os.path.basename(shot_p))[0]
        heat = np.clip(d * 3, 0, 255).astype(np.uint8)
        heat_rgb = np.stack([heat, np.zeros_like(heat), 255 - heat], axis=2)
        heat_rgb[~keep] = 0
        Image.fromarray(heat_rgb).save(os.path.join(out_dir, base + "_heat.png"))
        sbs = Image.new("RGB", (w * 2 + 8, h), (20, 20, 24))
        sbs.paste(ref, (0, 0)); sbs.paste(shot, (w + 8, 0))
        sbs.save(os.path.join(out_dir, base + "_sbs.png"))
        with open(os.path.join(out_dir, base + "_diff.json"), "w") as f:
            json.dump(res, f, indent=2)
        print(f"wrote {out_dir}/{base}_{{heat,sbs,diff}}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    sys.exit(main(sys.argv[1:]))
