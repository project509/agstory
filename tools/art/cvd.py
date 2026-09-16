#!/usr/bin/env python3
"""cvd — simulate colour-vision deficiency on a screenshot, and measure it.

docs/13 §13 makes this a BLOCKING QA item, in its own words: "Simulate every
screen under protanopia, deuteranopia, tritanopia and full greyscale. Adjacent
morale bands must remain distinguishable by lightness alone (§8.3 gives ~7 L*
per step)." docs/13 §4.5 item 3 repeats the greyscale half of it. Nothing in the
repo did either, so the blocking item had never once been run.

Two things are needed to satisfy that sentence and this tool does both:

  RENDER      the four simulated images, so a human can look at a screen the way
              a player with each deficiency sees it.
  MEASURE     the separation that actually carries the information. A picture
              proves nothing on its own — the previous palette audit
              (art/ref/specs/04-palette.md §7) was WCAG-luminance only and
              passed a red/amber/green ramp that §8.3 rejects by name.

  python tools/art/cvd.py <shot.png> [--out report_dir]
                          [--region x,y,w,h] [--mask x,y,w,h ...]
                          [--swatch x,y,w,h ...] [--ramp "#hex,#hex,..."]

--swatch names a rect whose mean colour is one step of a ramp (a morale chip, a
success figure). Give them in ramp order; the tool reports the L* separation
between ADJACENT swatches under each simulation, which is §13's criterion.
--ramp does the same for colours given directly, so `Palette.BAND_FILL_CVD` can
be checked without rendering anything; --ink adds the matching ink per step and
reports docs/13 §8.3's fill-vs-ink promise ("guaranteed >= 4.5:1 against each
other"). Pass `-` as the shot to measure a ramp with no screenshot at all.

Pipeline: Brettel/Viénot. sRGB -> LINEAR RGB -> Smith-Pokorny LMS -> collapse the
dichromat's missing axis -> back. Two traps cost a rewrite here and both are worth
naming, because a plausible-looking wrong answer is the failure mode of this whole
tool:

  1. The famous 2.02344 / 0.494207 / 0.801109 matrices are LMS-space, NOT
     linear-RGB. Applying them straight to RGB (a common copy-paste) turns pure
     red into bright yellow under deuteranopia — a deuteranope sees dark olive.
     The first draft of this file did exactly that and it inflated every score.
  2. It must run on LINEAR light. On gamma-encoded bytes the projection lands in
     the wrong place and exaggerates the deficiency.

Cross-check: linear red (1,0,0) through the deuteranope path must land on
(0.2928, 0.2928, 0) — libDaltonLens's tabulated Viénot-1999 deutan matrix,
row-multiplied, gives (0.29275, 0.29275, -0.02234). `--selftest` asserts it.

THE SAME PIPELINE EXISTS IN tests/unit/test_palette_cvd.gd. That duplication is
deliberate: the test must run inside the engine with no Python, and the tool must
run over a screenshot with no engine. If you change one, change both — the test
asserts the same red-to-olive landmark so a divergence shows up as a failure.
"""
import sys, os, json
from PIL import Image
import numpy as np

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Smith-Pokorny cone fundamentals for sRGB primaries, as published with the
# Viénot/Brettel/Mollon method. Linear RGB in, LMS out.
RGB_TO_LMS = np.array([
    [17.8824, 43.5161, 4.11935],
    [3.45565, 27.1554, 3.86714],
    [0.0299566, 0.184309, 1.46709]], dtype=np.float64)

LMS_TO_RGB = np.array([
    [0.0809444479, -0.130504409, 0.116721066],
    [-0.0102485335, 0.0540193266, -0.113614708],
    [-0.000365296938, -0.00412161469, 0.693511405]], dtype=np.float64)

# Each dichromacy loses one cone; the lost response is reconstructed from the two
# that remain, which is the "collapse onto the confusion plane" step. Coefficients
# are Viénot, Brettel & Mollon (1999).
PROJECT = {
    # L is missing: L' = 2.02344 M - 2.52581 S
    "protanope": ("L", np.array([0.0, 2.02344, -2.52581])),
    # M is missing: M' = 0.494207 L + 1.24827 S
    "deuteranope": ("M", np.array([0.494207, 0.0, 1.24827])),
    # S is missing: S' = -0.395913 L + 0.801109 M
    "tritanope": ("S", np.array([-0.395913, 0.801109, 0.0])),
}
CONE_ROW = {"L": 0, "M": 1, "S": 2}

# Rec.709, the same weights WCAG relative luminance uses (docs/13 §13 contrast).
LUMA = np.array([0.2126, 0.7152, 0.0722], dtype=np.float64)

# docs/13 §13's own threshold, quoted: "§8.3 gives ~7 L* per step". 5 is the
# tolerance this project checks against, not a number invented here — see
# build/plan/q-a11y-legible.md, which asks a human to confirm or move it.
MIN_DELTA_L = 5.0


def to_linear(srgb):
    """sRGB 0..1 -> linear. The 0.04045 knee is the standard, not a fudge."""
    a = np.asarray(srgb, dtype=np.float64)
    return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)


def to_srgb(lin):
    a = np.clip(np.asarray(lin, dtype=np.float64), 0.0, 1.0)
    return np.where(a <= 0.0031308, a * 12.92, 1.055 * (a ** (1.0 / 2.4)) - 0.055)


def simulate(rgb01, kind):
    """rgb01: (..., 3) sRGB in 0..1. Returns the same shape, simulated."""
    lin = to_linear(rgb01)
    if kind == "greyscale":
        y = lin @ LUMA
        out = np.stack([y, y, y], axis=-1)
    else:
        lms = lin @ RGB_TO_LMS.T
        cone, coeff = PROJECT[kind]
        lms = lms.copy()
        lms[..., CONE_ROW[cone]] = lms @ coeff
        out = lms @ LMS_TO_RGB.T
    return to_srgb(np.clip(out, 0.0, 1.0))


def selftest():
    """The landmark from the docstring: red must become dark olive, not yellow."""
    red = np.array([1.0, 0.0, 0.0])
    lin = np.array([1.0, 0.0, 0.0])          # red is already linear at full
    lms = lin @ RGB_TO_LMS.T
    lms[1] = lms @ PROJECT["deuteranope"][1]
    got = lms @ LMS_TO_RGB.T
    want = np.array([0.29275, 0.29275, -0.02234])
    err = float(np.abs(got - want).max())
    ok = err < 1e-3
    print(json.dumps({
        "linear_red_deuteranope": [round(float(v), 5) for v in got],
        "expected_vienot1999": [round(float(v), 5) for v in want],
        "max_error": round(err, 6),
        "srgb_out": "#%02X%02X%02X" % tuple(
            int(round(v * 255)) for v in to_srgb(np.clip(got, 0, 1))),
        "pass": bool(ok),
    }, indent=2))
    _ = red
    return 0 if ok else 1


def lstar(rgb01):
    """CIE L* of an sRGB colour, via relative luminance (D65, Y only)."""
    y = to_linear(rgb01) @ LUMA
    return np.where(y > 0.008856, 116.0 * np.cbrt(y) - 16.0, 903.3 * y)


def contrast(rgb_a, rgb_b):
    """WCAG contrast ratio. docs/13 §13: 4.5:1 text, 3:1 UI boundaries."""
    ya = to_linear(rgb_a) @ LUMA
    yb = to_linear(rgb_b) @ LUMA
    hi, lo = np.maximum(ya, yb), np.minimum(ya, yb)
    return (hi + 0.05) / (lo + 0.05)


def parse_hex(h):
    h = h.strip().lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], dtype=np.float64)


def ramp_report(colors, names=None):
    """Adjacent-step separation for one ramp, under every simulation.

    Reports BOTH numbers docs/13 asks about and keeps them apart: dL* is §13's
    CVD criterion ("distinguishable by lightness alone"); the contrast ratio is
    §13's contrast row, and between two adjacent ramp steps it is a diagnostic,
    not a pass/fail — three steps spanning §8.3's L* 16..80 cannot reach 3:1
    twice over (that needs 9:1 end to end and the range affords 8.6:1).
    """
    out = {}
    for kind in ["none", "protanope", "deuteranope", "tritanope", "greyscale"]:
        sim = [c if kind == "none" else simulate(c, kind) for c in colors]
        ls = [float(lstar(c)) for c in sim]
        steps = []
        for i in range(len(sim) - 1):
            steps.append({
                "pair": [
                    names[i] if names else i,
                    names[i + 1] if names else i + 1],
                "dL": round(abs(ls[i + 1] - ls[i]), 2),
                "contrast": round(float(contrast(sim[i], sim[i + 1])), 3),
            })
        worst = min([s["dL"] for s in steps], default=0.0)
        out[kind] = {
            "lstar": [round(v, 2) for v in ls],
            "monotone": all(ls[i + 1] > ls[i] for i in range(len(ls) - 1)),
            "steps": steps,
            "min_dL": round(worst, 2),
            "pass_dL": bool(worst >= MIN_DELTA_L),
        }
    return out


def main(argv):
    if argv[0] == "--selftest":
        return selftest()
    shot_p = argv[0]
    out_dir, region, masks, swatches, ramp, ink = None, None, [], [], None, None
    i = 1
    while i < len(argv):
        if argv[i] == "--out":
            out_dir = argv[i + 1]; i += 2
        elif argv[i] == "--region":
            region = tuple(int(v) for v in argv[i + 1].split(",")); i += 2
        elif argv[i] == "--mask":
            masks.append(tuple(int(v) for v in argv[i + 1].split(","))); i += 2
        elif argv[i] == "--swatch":
            swatches.append(tuple(int(v) for v in argv[i + 1].split(","))); i += 2
        elif argv[i] == "--ramp":
            ramp = [parse_hex(h) for h in argv[i + 1].split(",")]; i += 2
        elif argv[i] == "--ink":
            ink = [parse_hex(h) for h in argv[i + 1].split(",")]; i += 2
        else:
            i += 1

    res = {}

    # --ramp needs no image at all, so it is answered first and can stand alone.
    if ramp is not None:
        res["ramp"] = ramp_report(ramp)
        if ink is not None:
            # docs/13 §8.3's own promise about its table: "a fill and an ink
            # guaranteed >= 4.5:1 against each other". Checked, not assumed.
            pairs = []
            for idx, (f, k) in enumerate(zip(ramp, ink)):
                cr = float(contrast(f, k))
                pairs.append({"band": idx, "contrast": round(cr, 3),
                              "meets_4_5": bool(cr >= 4.5)})
            res["fill_vs_ink"] = {
                "pairs": pairs,
                "below_4_5": [p["band"] for p in pairs if not p["meets_4_5"]],
            }

    if shot_p != "-":
        p = shot_p if os.path.isabs(shot_p) else os.path.join(ROOT, shot_p)
        shot = Image.open(p).convert("RGB")
        a = np.asarray(shot, dtype=np.float64) / 255.0
        h, w, _ = a.shape

        keep = np.ones((h, w), dtype=bool)
        if region:
            keep[:] = False
            x, y, rw, rh = region
            keep[y:y + rh, x:x + rw] = True
        for (x, y, mw, mh) in masks:
            keep[y:y + mh, x:x + mw] = False

        res["shot"] = shot_p
        res["size"] = list(shot.size)

        # Per simulation: how much the image moves, and how much of its tonal
        # range survives. A screen that loses range in greyscale is a screen
        # whose state was carried by hue (docs/13 §4.5 item 3).
        per = {}
        for kind in list(PROJECT.keys()) + ["greyscale"]:
            sim = simulate(a, kind)
            shift = np.abs(sim - a).mean(axis=2)
            l_before = lstar(a[keep])
            l_after = lstar(sim[keep])
            per[kind] = {
                "mean_shift_8bit": round(float(shift[keep].mean() * 255.0), 3),
                "max_shift_8bit": round(float(shift[keep].max() * 255.0), 3),
                "lstar_range_before": round(float(l_before.max() - l_before.min()), 2),
                "lstar_range_after": round(float(l_after.max() - l_after.min()), 2),
            }
            if out_dir:
                os.makedirs(out_dir, exist_ok=True)
                base = os.path.splitext(os.path.basename(shot_p))[0]
                img = Image.fromarray((np.clip(sim, 0, 1) * 255.0).round().astype(np.uint8))
                img.save(os.path.join(out_dir, "%s_%s.png" % (base, kind)))
        res["simulations"] = per

        if swatches:
            cols, names = [], []
            for (x, y, sw, sh) in swatches:
                cols.append(a[y:y + sh, x:x + sw].reshape(-1, 3).mean(axis=0))
                names.append("%d,%d" % (x, y))
            res["swatches"] = ramp_report(cols, names)

    print(json.dumps(res, indent=2))

    # The verdict reads the strictest thing measured, so a green line means the
    # blocking item passed rather than "the tool ran".
    checked = [v for k, v in res.items() if k in ("ramp", "swatches")]
    failed = []
    for block in checked:
        for kind, r in block.items():
            if kind != "none" and not r["pass_dL"]:
                failed.append("%s min_dL=%.2f" % (kind, r["min_dL"]))
    if not checked:
        print("verdict: RENDERED ONLY — pass --swatch or --ramp to measure a ramp")
        return 0
    if failed:
        print("verdict: FAILS docs/13 §13 — " + "; ".join(failed))
        return 1
    print("verdict: SEPARABLE BY LIGHTNESS under all four simulations")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    sys.exit(main(sys.argv[1:]))
