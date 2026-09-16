#!/usr/bin/env python3
"""refkit — shared inspection helpers for the reference concepts.

The three files in ideaboard/Reference Concepts are the TARGET FRAMEBUFFER:
1536x1024, one image pixel = one game pixel. Every measurement taken here is
therefore directly a Godot layout coordinate, not a proportion to be scaled.

Usage:
  python tools/art/refkit.py crop  <ref#> <x> <y> <w> <h> [zoom] [out.png]
  python tools/art/refkit.py px    <ref#> <x> <y>            # exact RGB at a point
  python tools/art/refkit.py row   <ref#> <y> [x0] [x1]      # colour runs along a row
  python tools/art/refkit.py col   <ref#> <x> [y0] [y1]      # colour runs down a column
  python tools/art/refkit.py edges <ref#> <x0> <y0> <x1> <y1>  # strong edges in a box
  python tools/art/refkit.py pal   <ref#> [x0 y0 x1 y1] [n]  # dominant colours in a region
  python tools/art/refkit.py grid  <ref#>                     # global panel-edge detection

<ref#> is 1, 2 or 3 for the concepts, or a path to any png.
"""
import sys, os
from PIL import Image
import numpy as np

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONCEPTS = {
    "1": "ideaboard/Reference Concepts/Reference Concept 1.png",
    "2": "ideaboard/Reference Concepts/Reference Concept 2.png",
    "3": "ideaboard/Reference Concepts/Reference Concept 3.png",
}


def load(ref):
    p = CONCEPTS.get(str(ref), str(ref))
    if not os.path.isabs(p):
        p = os.path.join(ROOT, p)
    return Image.open(p).convert("RGBA")


def hx(c):
    return "#%02X%02X%02X" % (int(c[0]), int(c[1]), int(c[2]))


def cmd_crop(a):
    ref, x, y, w, h = a[0], *map(int, a[1:5])
    zoom = int(a[5]) if len(a) > 5 else 1
    out = a[6] if len(a) > 6 else "crop.png"
    im = load(ref).crop((x, y, x + w, y + h))
    if zoom > 1:
        im = im.resize((w * zoom, h * zoom), Image.NEAREST)
    im.save(out)
    print(f"{out}  {im.size[0]}x{im.size[1]}  (source {x},{y} {w}x{h} @{zoom}x)")


def cmd_px(a):
    im = np.asarray(load(a[0]))
    x, y = int(a[1]), int(a[2])
    print(f"({x},{y}) = {hx(im[y, x])}  rgba={tuple(int(v) for v in im[y,x])}")


def _runs(vals, coords):
    """Collapse a line of colours into runs, reporting each run's span."""
    out, start = [], 0
    for i in range(1, len(vals) + 1):
        if i == len(vals) or not np.array_equal(vals[i], vals[start]):
            out.append((coords[start], coords[i - 1], hx(vals[start]), i - start))
            start = i
    return out


def cmd_row(a):
    im = np.asarray(load(a[0]))
    y = int(a[1])
    x0 = int(a[2]) if len(a) > 2 else 0
    x1 = int(a[3]) if len(a) > 3 else im.shape[1]
    line = im[y, x0:x1, :3]
    for s, e, c, n in _runs(line, list(range(x0, x1))):
        if n >= 2:
            print(f"  x {s:4d}-{e:4d} ({n:3d}px) {c}")


def cmd_col(a):
    im = np.asarray(load(a[0]))
    x = int(a[1])
    y0 = int(a[2]) if len(a) > 2 else 0
    y1 = int(a[3]) if len(a) > 3 else im.shape[0]
    line = im[y0:y1, x, :3]
    for s, e, c, n in _runs(line, list(range(y0, y1))):
        if n >= 2:
            print(f"  y {s:4d}-{e:4d} ({n:3d}px) {c}")


def cmd_edges(a):
    im = np.asarray(load(a[0]).convert("L"), dtype=np.float32)
    x0, y0, x1, y1 = map(int, a[1:5])
    box = im[y0:y1, x0:x1]
    dx = np.abs(np.diff(box, axis=1)).mean(axis=0)
    dy = np.abs(np.diff(box, axis=0)).mean(axis=1)
    def peaks(d, off, axis):
        t = d.mean() + 2.5 * d.std()
        idx = np.where(d > t)[0]
        print(f"  strong {axis} edges (thr {t:.1f}): " +
              ", ".join(str(int(i) + off) for i in idx[:60]))
    peaks(dx, x0, "vertical")
    peaks(dy, y0, "horizontal")


def cmd_pal(a):
    im = np.asarray(load(a[0]))
    if len(a) >= 5:
        x0, y0, x1, y1 = map(int, a[1:5])
        im = im[y0:y1, x0:x1]
        n = int(a[5]) if len(a) > 5 else 16
    else:
        n = int(a[1]) if len(a) > 1 else 16
    rgb = im[..., :3].reshape(-1, 3)
    q = (rgb // 8 * 8).astype(np.uint8)
    cols, counts = np.unique(q, axis=0, return_counts=True)
    order = counts.argsort()[::-1][:n]
    tot = counts.sum()
    for i in order:
        print(f"  {hx(cols[i])}  {100.0*counts[i]/tot:5.2f}%")


def cmd_grid(a):
    """Find full-length panel borders: rows/cols that are near-uniform bright lines."""
    im = np.asarray(load(a[0]).convert("L"), dtype=np.float32)
    h, w = im.shape
    dy = np.abs(np.diff(im, axis=0)).mean(axis=1)
    dx = np.abs(np.diff(im, axis=1)).mean(axis=0)
    ty, tx = dy.mean() + 2 * dy.std(), dx.mean() + 2 * dx.std()
    print("  horizontal bands at y =", [int(i) for i in np.where(dy > ty)[0]][:80])
    print("  vertical   bands at x =", [int(i) for i in np.where(dx > tx)[0]][:80])


CMDS = {"crop": cmd_crop, "px": cmd_px, "row": cmd_row, "col": cmd_col,
        "edges": cmd_edges, "pal": cmd_pal, "grid": cmd_grid}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in CMDS:
        print(__doc__)
        sys.exit(1)
    CMDS[sys.argv[1]](sys.argv[2:])
