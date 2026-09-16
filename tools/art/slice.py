#!/usr/bin/env python3
"""slice - cut individual sprites out of the reference asset sheets.

The four asset sheets each hide their sprites behind a different background, so
keying is per-sheet, not global:
    alpha   0f2ce34a  (real alpha, the cleanest source)
    white   0718af5b, bbb8018d
    dark    de1918ac  (~#000913)

Connected components are labelled with a two-pass union-find in pure numpy -
scipy is not a dependency of this project and adding one for a build-time
script is not worth it.

  python tools/art/slice.py islands SHEET --key alpha|white|dark [--thresh N]
         [--region x,y,w,h] [--min-area N] [--pad N] [--json out.json]
  python tools/art/slice.py cut --manifest m.json --out DIR
  python tools/art/slice.py grid SHEET --origin x,y --cell WxH --count CxR
         --out DIR --name PREFIX
  python tools/art/slice.py sheet DIR --out sheet.png --json sheet.json [--cols N]

"islands" discovers, "cut" extracts a reviewed manifest, "grid" handles the
regular tile blocks, "sheet" repacks loose PNGs into an atlas for Godot.
"""
import sys, os, json, argparse
from PIL import Image
import numpy as np

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def resolve(p):
    return p if os.path.isabs(p) else os.path.join(ROOT, p)


def foreground(im, key, thresh):
    """Boolean mask of 'this pixel is art, not background'."""
    a = np.asarray(im.convert("RGBA"))
    if key == "alpha":
        return a[..., 3] > thresh
    lum = a[..., :3].astype(np.float32).mean(axis=2)
    if key == "white":
        return lum < (255 - thresh)
    if key == "dark":
        return lum > thresh
    raise SystemExit("unknown key: " + str(key))


def label(mask):
    """Two-pass 8-connected components with union-find. Returns (labels, count)."""
    h, w = mask.shape
    lab = np.zeros((h, w), dtype=np.int32)
    parent = [0]

    def find(x):
        root = x
        while parent[root] != root:
            root = parent[root]
        while parent[x] != root:          # path compression keeps this near-linear
            parent[x], x = root, parent[x]
        return root

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[max(ra, rb)] = min(ra, rb)

    nxt = 1
    for y in range(h):
        row = mask[y]
        lrow = lab[y]
        prev = mask[y - 1] if y else None
        lprev = lab[y - 1] if y else None
        for x in range(w):
            if not row[x]:
                continue
            n = []
            if x and row[x - 1]:
                n.append(lrow[x - 1])
            if y:
                for dx in (-1, 0, 1):
                    xx = x + dx
                    if 0 <= xx < w and prev[xx]:
                        n.append(lprev[xx])
            if not n:
                parent.append(nxt)
                lrow[x] = nxt
                nxt += 1
            else:
                m = min(n)
                lrow[x] = m
                for v in n:
                    union(m, v)
    if nxt == 1:
        return lab, 0
    remap = np.zeros(nxt, dtype=np.int32)
    seen = {}
    for i in range(1, nxt):
        r = find(i)
        if r not in seen:
            seen[r] = len(seen) + 1
        remap[i] = seen[r]
    return remap[lab], len(seen)


def cmd_islands(a):
    im = Image.open(resolve(a.sheet))
    ox = oy = 0
    if a.region:
        ox, oy, rw, rh = [int(v) for v in a.region.split(",")]
        im = im.crop((ox, oy, ox + rw, oy + rh))
    mask = foreground(im, a.key, a.thresh)
    lab, n = label(mask)
    out = []
    for i in range(1, n + 1):
        ys, xs = np.where(lab == i)
        if xs.size < a.min_area:
            continue
        x0, x1, y0, y1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
        out.append({
            "index": len(out),
            "x": x0 + ox - a.pad, "y": y0 + oy - a.pad,
            "w": (x1 - x0 + 1) + a.pad * 2, "h": (y1 - y0 + 1) + a.pad * 2,
            "area": int(xs.size),
        })
    out.sort(key=lambda r: (r["y"] // 16, r["x"]))
    for i, r in enumerate(out):
        r["index"] = i
    print("%d islands  key=%s thresh=%d min_area=%d" % (len(out), a.key, a.thresh, a.min_area))
    if out:
        sizes = sorted(r["w"] * r["h"] for r in out)
        print("  area  min=%d median=%d max=%d" % (sizes[0], sizes[len(sizes) // 2], sizes[-1]))
        ws = sorted(set(r["w"] for r in out))[:12]
        hs = sorted(set(r["h"] for r in out))[:12]
        print("  widths(first12)=" + str(ws))
        print("  heights(first12)=" + str(hs))
    if a.json:
        with open(resolve(a.json), "w") as f:
            json.dump({"sheet": a.sheet, "key": a.key, "thresh": a.thresh,
                       "islands": out}, f, indent=1)
        print("  wrote " + a.json)
    else:
        for r in out[:40]:
            print("   ", r)


def cmd_cut(a):
    man = json.load(open(resolve(a.manifest)))
    top = man if isinstance(man, dict) else {}
    entries = top.get("entries", man if isinstance(man, list) else top.get("islands", []))
    os.makedirs(resolve(a.out), exist_ok=True)
    cache = {}
    n = 0
    for e in entries:
        sp = e.get("sheet", top.get("sheet"))
        if sp is None:
            raise SystemExit("entry has no sheet and manifest has no default")
        if sp not in cache:
            cache[sp] = Image.open(resolve(sp)).convert("RGBA")
        im = cache[sp]
        sub = im.crop((e["x"], e["y"], e["x"] + e["w"], e["y"] + e["h"]))
        key = e.get("key", top.get("key"))
        if key:
            th = e.get("thresh", top.get("thresh", 16))
            keep = foreground(sub, key, th)
            arr = np.asarray(sub).copy()
            if key == "alpha":
                arr[..., 3] = np.where(keep, arr[..., 3], 0)
            else:
                arr[..., 3] = np.where(keep, 255, 0)
            sub = Image.fromarray(arr)
        cat = e.get("category", "misc")
        d = os.path.join(resolve(a.out), cat)
        os.makedirs(d, exist_ok=True)
        name = e.get("proposed_name") or e.get("name") or ("%s_%03d" % (cat, e.get("index", n)))
        sub.save(os.path.join(d, name + ".png"))
        n += 1
    print("cut %d sprites into %s" % (n, a.out))


def cmd_grid(a):
    im = Image.open(resolve(a.sheet)).convert("RGBA")
    ox, oy = [int(v) for v in a.origin.split(",")]
    cw, ch = [int(v) for v in a.cell.split("x")]
    cols, rows = [int(v) for v in a.count.split("x")]
    outdir = resolve(a.out)
    os.makedirs(outdir, exist_ok=True)
    n = 0
    for r in range(rows):
        for c in range(cols):
            x, y = ox + c * cw, oy + r * ch
            sub = im.crop((x, y, x + cw, y + ch))
            if int(np.asarray(sub)[..., 3].max()) == 0:
                continue
            sub.save(os.path.join(outdir, "%s_%02d_%02d.png" % (a.name, r, c)))
            n += 1
    print("cut %d/%d grid cells into %s" % (n, cols * rows, a.out))


def cmd_sheet(a):
    d = resolve(a.dir)
    files = sorted(f for f in os.listdir(d) if f.endswith(".png"))
    ims = [Image.open(os.path.join(d, f)).convert("RGBA") for f in files]
    if not ims:
        raise SystemExit("no pngs in " + d)
    cw = max(i.width for i in ims)
    ch = max(i.height for i in ims)
    cols = a.cols or int(np.ceil(np.sqrt(len(ims))))
    rows = int(np.ceil(len(ims) / cols))
    out = Image.new("RGBA", (cols * cw, rows * ch), (0, 0, 0, 0))
    meta = []
    for i, (f, im) in enumerate(zip(files, ims)):
        x, y = (i % cols) * cw, (i // cols) * ch
        out.paste(im, (x + (cw - im.width) // 2, y + (ch - im.height) // 2))
        meta.append({"name": os.path.splitext(f)[0], "x": x, "y": y, "w": cw, "h": ch})
    out.save(resolve(a.out))
    if a.json:
        json.dump({"cell": [cw, ch], "cols": cols, "rows": rows, "frames": meta},
                  open(resolve(a.json), "w"), indent=1)
    print("packed %d sprites -> %s (%dx%d of %dx%d)" % (len(ims), a.out, cols, rows, cw, ch))


p = argparse.ArgumentParser(description=__doc__,
                            formatter_class=argparse.RawDescriptionHelpFormatter)
sub = p.add_subparsers(dest="cmd", required=True)

q = sub.add_parser("islands")
q.set_defaults(fn=cmd_islands)
q.add_argument("sheet")
q.add_argument("--key", required=True)
q.add_argument("--thresh", type=int, default=16)
q.add_argument("--region")
q.add_argument("--min-area", type=int, default=24)
q.add_argument("--pad", type=int, default=0)
q.add_argument("--json")

q = sub.add_parser("cut")
q.set_defaults(fn=cmd_cut)
q.add_argument("--manifest", required=True)
q.add_argument("--out", required=True)

q = sub.add_parser("grid")
q.set_defaults(fn=cmd_grid)
q.add_argument("sheet")
q.add_argument("--origin", required=True)
q.add_argument("--cell", required=True)
q.add_argument("--count", required=True)
q.add_argument("--out", required=True)
q.add_argument("--name", default="tile")

q = sub.add_parser("sheet")
q.set_defaults(fn=cmd_sheet)
q.add_argument("dir")
q.add_argument("--out", required=True)
q.add_argument("--json")
q.add_argument("--cols", type=int)

if __name__ == "__main__":
    args = p.parse_args()
    args.fn(args)
