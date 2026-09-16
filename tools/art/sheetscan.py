"""sheetscan.py - connected-component island finder for the reference asset sheets.

No scipy / no cv2 dependency: the labelling is a self-contained two-pass
union-find over the foreground mask (8-connected).

Usage:
    python tools/art/sheetscan.py <sheet.png> [--alpha N | --white N] [--dilate N]
"""
import sys
import numpy as np
from PIL import Image


# ---------------------------------------------------------------- union-find
class DSU:
    def __init__(self):
        self.p = [0]

    def new(self):
        self.p.append(len(self.p))
        return len(self.p) - 1

    def find(self, a):
        p = self.p
        r = a
        while p[r] != r:
            r = p[r]
        while p[a] != r:
            p[a], a = r, p[a]
        return r

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            if ra > rb:
                ra, rb = rb, ra
            self.p[rb] = ra


def label(mask):
    """8-connected labelling. mask: bool HxW. returns (labels int32 HxW, n)."""
    h, w = mask.shape
    lab = np.zeros((h, w), np.int32)
    dsu = DSU()
    for y in range(h):
        row = mask[y]
        if not row.any():
            continue
        prev = lab[y - 1] if y else None
        cur = lab[y]
        xs = np.flatnonzero(row)
        for x in xs:
            n = []
            if x and cur[x - 1]:
                n.append(cur[x - 1])
            if prev is not None:
                for dx in (-1, 0, 1):
                    xx = x + dx
                    if 0 <= xx < w and prev[xx]:
                        n.append(prev[xx])
            if not n:
                cur[x] = dsu.new()
            else:
                m = min(n)
                cur[x] = m
                for o in n:
                    dsu.union(m, o)
    # resolve
    p = np.array([dsu.find(i) for i in range(len(dsu.p))], np.int32)
    remap = {}
    out = np.zeros(len(p), np.int32)
    for i in range(1, len(p)):
        r = p[i]
        if r not in remap:
            remap[r] = len(remap) + 1
        out[i] = remap[r]
    return out[lab], len(remap)


def dilate(mask, r):
    if r <= 0:
        return mask
    m = mask.copy()
    for _ in range(r):
        n = m.copy()
        n[1:, :] |= m[:-1, :]
        n[:-1, :] |= m[1:, :]
        n[:, 1:] |= m[:, :-1]
        n[:, :-1] |= m[:, 1:]
        m = n
    return m


def boxes(mask, dil=0, min_px=8):
    """Returns list of (x, y, w, h, pixel_count) for each island of `mask`,
    grown by `dil` for the labelling only (boxes are trimmed back to `mask`)."""
    lab, n = label(dilate(mask, dil))
    res = []
    for i in range(1, n + 1):
        sel = (lab == i) & mask
        if sel.sum() < min_px:
            continue
        ys, xs = np.nonzero(sel)
        res.append((int(xs.min()), int(ys.min()),
                    int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1),
                    int(sel.sum())))
    res.sort(key=lambda b: (b[1], b[0]))
    return res


def fg_mask(path, alpha=96, white=None):
    im = Image.open(path)
    a = np.array(im.convert('RGBA'))
    if white is not None:
        rgb = a[:, :, :3].astype(np.int16)
        return rgb.min(axis=2) < white
    return a[:, :, 3] >= alpha


if __name__ == '__main__':
    p = sys.argv[1]
    kw = {}
    if '--white' in sys.argv:
        kw['white'] = int(sys.argv[sys.argv.index('--white') + 1])
    if '--alpha' in sys.argv:
        kw['alpha'] = int(sys.argv[sys.argv.index('--alpha') + 1])
    d = int(sys.argv[sys.argv.index('--dilate') + 1]) if '--dilate' in sys.argv else 0
    m = fg_mask(p, **kw)
    bs = boxes(m, d)
    print(f'{len(bs)} islands')
    for b in bs[:400]:
        print(b)
