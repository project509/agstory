"""Paint a painted-in detail OUT of a scene plate (an inpainter).

Written for the reference crops' baked speech bubbles: the concepts painted
their bubbles into the scene, SceneStage drew its own at the same spots and
hid/showed them, so the painted ones had to go or they never disappeared. Those
mockup crops are gone — every scene stands on a BARE plate now (STAGE-13,
RULES-10) — but the tool is the same one STAGE-14 / PIPE-10
name for the aerial's airship (a ~160x140 sky patch behind a cut sprite) and for
any other painted detail a bare plate turns out to carry. For each spot the
script finds the bubble's real extent (cream body + dark rim + tail), or takes
an explicit box, then searches the neighbourhood for the offset whose
surrounding ring best matches the hole's ring — the cheapest inpainting that
works on repeating wall, shelf, sky and floor texture — and copies that block in
with a feathered seam. Reads art/src/bg/<name>_raw.png, writes
game/assets/bg/<name>.png.

  python tools/art/patch_bubbles.py stage_town 1180,40,160,140

A spot is x,y of a painted bubble's top-left (the cream body is found from
there; the kit's frame is 40x44 and the search window is generous), or an
explicit x,y,w,h box for anything else painted in that must go; add dx,dy to
name the source block yourself when the best match drags a figure along.
"""
import sys
import numpy as np
from PIL import Image

RING, BLEND, PAD = 3, 0, 3   # no feather: it mixed the rim back in


def bubble_box(a, x, y):
    """Bounding box of the painted bubble near (x, y): cream body pixels plus
    the dark rim/tail pixels that touch them, within a generous window."""
    win = a[max(0, y - 8):y + 48, max(0, x - 8):x + 48, :3]
    cream = (win[..., 0] > 195) & (win[..., 1] > 170) & (win[..., 2] > 130) & (win[..., 2] < 235)
    ys, xs = np.nonzero(cream)
    if len(xs) == 0:
        return x, y, 33, 40
    x0, x1 = xs.min() + max(0, x - 8), xs.max() + max(0, x - 8)
    y0, y1 = ys.min() + max(0, y - 8), ys.max() + max(0, y - 8)
    return x0 - PAD, y0 - PAD, (x1 - x0 + 1) + 2 * PAD, (y1 - y0 + 1) + 2 * PAD + 6  # +6: the tail


def ring(a, x, y, w, h):
    top = a[y - RING:y, x - RING:x + w + RING]
    bot = a[y + h:y + h + RING, x - RING:x + w + RING]
    left = a[y:y + h, x - RING:x]
    right = a[y:y + h, x + w:x + w + RING]
    return np.concatenate([top.ravel(), bot.ravel(), left.ravel(), right.ravel()])


def best_offset(a, x, y, w, h):
    target = ring(a, x, y, w, h)
    best, best_d = None, 1e18
    H, W = a.shape[:2]
    for dy in range(-72, 73, 4):
        for dx in range(-120, 121, 4):
            if abs(dx) < w + RING and abs(dy) < h + RING:
                continue                                   # would sample the hole itself
            sx, sy = x + dx, y + dy
            if sx - RING < 0 or sy - RING < 0 or sx + w + RING > W or sy + h + RING > H:
                continue
            d = np.abs(ring(a, sx, sy, w, h) - target).mean()
            if d < best_d:
                best, best_d = (dx, dy), d
    return best, best_d


def patch(a, x, y, w, h, dx, dy, blend=BLEND):
    """Copy the block at (x+dx, y+dy) over (x, y); `blend` feathers the seam over
    that many pixels against what is already there (0 for a bubble, whose rim
    would bleed back in; a few px for a plain box on open texture)."""
    src = a[y + dy:y + dy + h, x + dx:x + dx + w].copy()
    dst = a[y:y + h, x:x + w]
    for i in range(blend):
        t = (i + 1) / (BLEND + 1)
        src[:, i] = dst[:, i] * (1 - t) + src[:, i] * t
        src[:, w - 1 - i] = dst[:, w - 1 - i] * (1 - t) + src[:, w - 1 - i] * t
        src[i, :] = dst[i, :] * (1 - t) + src[i, :] * t
        src[h - 1 - i, :] = dst[h - 1 - i, :] * (1 - t) + src[h - 1 - i, :] * t
    a[y:y + h, x:x + w] = src


def main(argv):
    name, spots = argv[0], argv[1:]
    a = np.asarray(Image.open(f"art/src/bg/{name}_raw.png").convert("RGBA")).astype(float)
    # Edge-replicate a ring's width so a box on the plate's border still has a
    # full ring to match against; trimmed again before saving.
    a = np.pad(a, ((RING, RING), (RING, RING), (0, 0)), mode="edge")
    for s in spots:
        parts = [int(v) for v in s.split(",")]
        if len(parts) >= 4:                       # an explicit box: x,y,w,h[,dx,dy]
            bx, by, bw, bh = parts[0] + RING, parts[1] + RING, parts[2], parts[3]
        else:
            bx, by, bw, bh = bubble_box(a, parts[0] + RING, parts[1] + RING)
        if len(parts) == 6:                       # a chosen source, when the best match copies a figure
            (dx, dy), d = (parts[4], parts[5]), float("nan")
        else:
            (dx, dy), d = best_offset(a, bx, by, bw, bh)
        patch(a, bx, by, bw, bh, dx, dy, 5 if len(parts) >= 4 else 0)
        print(f"  {s}: box {bx},{by} {bw}x{bh}  from ({dx:+d},{dy:+d}) seam {d:.1f}")
    a = a[RING:-RING, RING:-RING]
    Image.fromarray(a.clip(0, 255).astype(np.uint8)).save(f"game/assets/bg/{name}.png")
    print("PATCHED", name, len(spots), "bubbles")


if __name__ == "__main__":
    main(sys.argv[1:])
