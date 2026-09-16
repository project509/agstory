"""Build the scene ACTOR strips — the figures that used to be baked into the plates.

`art/ref/specs/09-background-plates.md` §4.1 row 4 and §4.2 row 8 both say the
same thing about the people standing around a scene: *"ambient patrons — baked
in v1"*, *"ambient raiders — baked v1"*, each owing a debt (`bg-hall-patrons`,
`bg-camp-figures`). The designer paid that debt down on 2026-09-11 by supplying
BARE plates: no painted people, no baked speech, nothing static pretending to
be alive. So the figures are ours now, and they have to move.

The reference sheets already contain the frames. `tools/art/slice.py` cut 721
rects out of them into `art/export/`, and among those are real idle animations
— five frames each for the cleric, mage, rogue, ranger, warrior and knight
figures (plus a second pose set, suffixed `_b`) — and 44 single-pose townsfolk
(`variant_rNN` × four hair colours). This script turns each group into ONE
horizontal strip PNG that `game/ui/SceneStage.gd` can load exactly the way it
already loads a fire strip, plus a manifest giving the geometry.

Three things it does that matter more than they look:

1. **The feet are the anchor.** The cut rects are the reference's own bounding
   boxes, so frame 3 of a group can be two pixels shorter and three narrower
   than frame 1. Blitted naively into a strip, the figure JITTERS — it reads as
   a glitch, not a breath. Every frame is trimmed to its own alpha box and then
   planted on a common floor, aligned on the alpha centroid of its bottom rows
   rather than on the centre of its box: an extended arm widens the box on one
   side only, so box-centring would slide the whole body sideways.
   Three of the cut rects turn out to be mis-cuts rather than poses (a 31x82
   "knight" beside four 25x39 ones); a frame half again the group's median is
   dropped, by name, in the report and in the manifest.

2. **A synthesised breath for the single-pose figures.** A crowd of statues is
   what the directive is against, and there is no second frame to cut for the
   44 townsfolk. docs/12 §5.2's `idle` is 4 frames, ping-pong, 1-2 px of
   motion, and STAGE-16 found the old 2-frame 2 fps version ticking rather
   than breathing (a 2px jump twice a second at the scenes' 2x). So the breath
   is four frames at 5 fps, the sliced sets' own cadence: the pose; the frame
   above the waist moved down one pixel (the standard pixel-art breath, which
   compresses the torso by 1px and leaves the legs planted); the same with the
   shoulders already back up (only the head band still down — the exhale
   starts from the chest); the pose again. Nothing is invented about the
   DESIGN here, only about the presentation, which is this script's job.

3. **Every strip loops at least four frames.** A sliced set that lost a
   mis-cut frame (the warrior: 3 of 4) is ping-ponged (0,1,2,1) rather than
   left as a 3-beat loop, so `frames >= 4` holds for every manifest entry and
   no pose is invented.

4. **A bob walk for the figures a scene sends along a path** (TOWN-27,
   W4-LIFE). The camp's `paths` layer (game/assets/scenes/stage_camp.json,
   SceneStage.add_walker) moves a figure between points, and a figure that
   glides with planted feet reads as a chess piece. There is no walk to cut
   from the sheets, so `WALKERS` names the townsfolk that get one derived from
   the pose: four frames — the pose; the body dipped one pixel (the breath's
   compress) with the RIGHT leg lifted two; the pose; the same with the LEFT
   leg. The legs band is split at its thinnest column (the gap between the
   legs, or the middle of a robe). Written as a SECOND strip, `<key>_walk.png`
   with its own manifest row (`kind` "walk", `walk_of` the pose's key), so the
   idle strip and the 44-breath contract (tests/unit/test_scene_stage.gd) are
   untouched; SceneStage adds the strip as the actor's "walk" animation.

The keys keep the reference's own labels, including the awkward ones
(`ranger_as_rogue`, `knight_unlabelled`): a figure's label is provenance, and
which canon class a reference figure stands for is a question for whatever
screen shows a named party, not for the slicer. The manifest carries the label
so that decision can be made later, in one place, from data.

    python tools/art/gen_actors.py            # write strips + manifest
    python tools/art/gen_actors.py --check    # regenerate in memory, byte-compare with the
                                              # tree, exit 1 on DIFFERS / MISSING (build_art.sh)

Writes game/assets/actors/<key>.png and game/assets/actors/actors.json. The
PNGs are encoded without optimisation so a re-run reproduces the bytes, which
is what makes --check a gate (the Lua generators get the same treatment from
build_art.sh; this file, like gen_clouds.py, carries its own).
"""
import argparse
import io
import json
import os
import re
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = "art/export/raider"
OUT = "game/assets/actors"
MANIFEST = OUT + "/actors.json"

MULTI = re.compile(r"^raider_(?P<key>.+)_idle_(?P<n>\d+)\.png$")
SINGLE = re.compile(r"^raider_(?P<key>.+)_idle\.png$")

# The sliced sets are five frames of a cycle the reference drew; 5 fps gives a
# one-second loop, which is the pace a standing figure breathes at. The
# synthesised breath is four frames of the same cadence (docs/12 §5.2: idle =
# 4 frames, ping-pong), so a breath and a sliced idle run at one rate.
FPS_SLICED = 5.0
FPS_BREATH = 5.0

# Where the breath folds. Measured against the sliced sets: their moving pixels
# are all above 0.55 of the figure's height (head, shoulders, held weapon).
# HEAD is where the head band ends: the third frame keeps only that band down.
WAIST = 0.55
HEAD = 0.30

# docs/12 §5.2: an idle loops at least four frames.
MIN_FRAMES = 4

# The figures that get a derived walk (docstring §4): six townsfolk, one per
# hair colour and build, enough for the camp's paths and a few to spare.
# Adding a key here adds one strip and one manifest row; nothing else moves.
WALKERS = ["variant_r02_black", "variant_r04_brown", "variant_r06_grey",
           "variant_r09_ginger", "variant_r11_black", "variant_r12_brown"]
# A step: the body dips 1 (the breath's compress) and the swinging leg lifts 2.
# 6 fps = one and a half strides a second, an amble at the scenes' 18-24 px/s.
FPS_WALK = 6.0
WALK_LIFT = 2


def trim(im):
    """The frame's own alpha box. Returns (image, ) with the padding removed."""
    a = np.array(im)[:, :, 3]
    ys, xs = np.nonzero(a > 0)
    if len(ys) == 0:
        return im
    return im.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def foot_x(im):
    """Where the figure STANDS: the alpha centroid of its bottom rows.

    Centring on the frame's box instead makes the body slide sideways whenever
    an arm extends, because an extended arm widens the box on one side only.
    The feet are the part that must not move, so they are the anchor.
    """
    a = np.array(im)[:, :, 3]
    rows = max(3, int(round(a.shape[0] * 0.2)))
    xs = np.nonzero(a[-rows:, :].sum(axis=0) > 0)[0]
    if len(xs) == 0:
        return im.width / 2.0
    return float(xs.mean())


def plant(frames):
    """Plant every frame on one floor, feet over feet, so only the body moves."""
    feet = [foot_x(f) for f in frames]
    anchor = max(feet)
    lefts = [int(round(anchor - fx)) for fx in feet]
    w = max(l + f.width for l, f in zip(lefts, frames))
    h = max(f.height for f in frames)
    out = []
    for l, f in zip(lefts, frames):
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        canvas.paste(f, (l, h - f.height))
        out.append(canvas)
    return out, w, h


# A cut rect that is half again as big as its siblings is not a pose, it is a
# mis-cut: `raider_knight_unlabelled_idle_1` is 31x82 next to four ~25x39
# frames, `raider_rogue_idle_5` is 24x79, `raider_warrior_idle_1` is 77x51.
# Padding the whole strip up to one of those would shrink the figure inside its
# own frame and un-plant its feet. Drop them, and SAY which were dropped.
OUTLIER = 1.5


def drop_outliers(names, frames):
    if len(frames) < 3:
        return names, frames, []
    mw = float(np.median([f.width for f in frames]))
    mh = float(np.median([f.height for f in frames]))
    keep_n, keep_f, dropped = [], [], []
    for n, f in zip(names, frames):
        if f.width > mw * OUTLIER or f.height > mh * OUTLIER:
            dropped.append("%s (%dx%d vs median %dx%d)" % (n, f.width, f.height, mw, mh))
        else:
            keep_n.append(n)
            keep_f.append(f)
    return keep_n, keep_f, dropped


def shift_bands(frame, head_off, chest_off):
    """The pose with its head band and chest band moved down by whole pixels.

    Bands are pasted legs, chest, head, each where it has alpha, so a band that
    steps down lands ON the band below it (the 1px compression that IS the
    breath) and never punches a hole; the vacated top row goes transparent.
    """
    a = np.array(frame)
    h = a.shape[0]
    head = max(1, int(round(h * HEAD)))
    waist = max(head + 1, int(round(h * WAIST)))
    out = np.zeros_like(a)
    for y0, y1, off in ((waist, h, 0), (head, waist, chest_off), (0, head, head_off)):
        src = a[y0:y1]
        dst0 = y0 + off
        dst1 = min(h, dst0 + (y1 - y0))
        src = src[: dst1 - dst0]
        mask = src[:, :, 3] > 0
        out[dst0:dst1][mask] = src[mask]
    return Image.fromarray(out, "RGBA")


def breath_frames(frame):
    """docs/12 §5.2's idle for a single pose: 0, -1, -1 with the shoulders up, 0."""
    return [frame, shift_bands(frame, 1, 1), shift_bands(frame, 1, 0), frame.copy()]


def leg_split(a, waist):
    """The column the legs band divides at: its thinnest column near the middle
    (the gap between two legs), or the middle itself for a robe."""
    h, w = a.shape[:2]
    band = a[waist:h, :, 3] > 0
    cols = band.sum(axis=0)
    lo, hi = w // 3, w - w // 3
    if hi <= lo + 1:
        return w // 2
    best = lo + int(np.argmin(cols[lo:hi]))
    return best if cols[best] < cols[lo:hi].max() else w // 2


def stride(frame, side):
    """One step of the bob walk: the body dipped one pixel with `side`'s leg
    lifted `WALK_LIFT`. Bands are pasted where they have alpha, legs first, so
    the dipped chest lands over the lifted leg's top rows and nothing punches a
    hole; the lifted leg's vacated bottom rows go transparent (the foot is up)."""
    a = np.array(frame)
    h, w = a.shape[:2]
    head = max(1, int(round(h * HEAD)))
    waist = max(head + 1, int(round(h * WAIST)))
    mid = leg_split(a, waist)
    out = np.zeros_like(a)

    def paste(src, y0):
        y1 = min(h, y0 + src.shape[0])
        src = src[: y1 - y0]
        mask = src[:, :, 3] > 0
        out[y0:y1][mask] = src[mask]

    legs = a[waist:h]
    for x0, x1, lift in ((0, mid, WALK_LIFT if side == "left" else 0),
                         (mid, w, WALK_LIFT if side == "right" else 0)):
        part = np.zeros_like(legs)
        part[:, x0:x1] = legs[:, x0:x1]
        paste(part, waist - lift)
    paste(a[head:waist], head + 1)
    paste(a[0:head], 1)
    return Image.fromarray(out, "RGBA")


def walk_frames(frame):
    """TOWN-27's bob walk for a single pose: 0, dip + right leg up, 0, dip + left leg up."""
    return [frame, stride(frame, "right"), frame.copy(), stride(frame, "left")]


def pingpong_to(frames, n):
    """Extend a short cycle by walking it back (0,1,2,1) until it has `n` frames."""
    out = list(frames)
    if len(out) < 2:
        return out
    walk = out[-2:0:-1]                # the interior, reversed
    while len(out) < n and walk:
        out.append(walk[0])
        walk = walk[1:]
    return out


def moving_pixels(frames):
    """How many pixels actually differ across the cycle. Zero means statues."""
    if len(frames) < 2:
        return 0
    base = np.array(frames[0]).astype(int)
    worst = 0
    for f in frames[1:]:
        d = np.abs(np.array(f).astype(int) - base).sum(axis=2)
        worst = max(worst, int((d > 8).sum()))
    return worst


def groups():
    """{key: [paths in frame order]} for the multi-frame sets and the singles."""
    multi, single = {}, {}
    for name in sorted(os.listdir(os.path.join(ROOT, SRC))):
        m = MULTI.match(name)
        if m:
            multi.setdefault(m.group("key"), []).append((int(m.group("n")), name))
            continue
        s = SINGLE.match(name)
        if s:
            single[s.group("key")] = name
    for key in multi:
        multi[key] = [n for _, n in sorted(multi[key])]
    return multi, single


def encode_strip(frames):
    w, h = frames[0].width, frames[0].height
    strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * w, 0))
    buf = io.BytesIO()
    strip.save(buf, format="PNG", optimize=False)
    return buf.getvalue()


def build(check):
    if not os.path.isdir(os.path.join(ROOT, SRC)):
        print("gen_actors: no %s — run tools/art/slice.py first" % SRC, file=sys.stderr)
        return 2
    multi, single = groups()
    actors, report, files = {}, [], {}

    for key, names in sorted(multi.items()):
        frames = [trim(Image.open(os.path.join(ROOT, SRC, n)).convert("RGBA")) for n in names]
        names, frames, dropped = drop_outliers(names, frames)
        for d in dropped:
            print("  ! %-24s dropped mis-cut frame %s" % (key, d))
        frames, w, h = plant(frames)
        moved = moving_pixels(frames)
        kind = "sliced"
        padded = False
        if moved == 0:
            # A group whose frames are byte-identical is a labelling accident,
            # not an animation. Say so and give it a breath instead of shipping
            # five copies of one statue.
            frames = breath_frames(frames[0])
            w, h = frames[0].width, frames[0].height
            kind = "breath"
            moved = moving_pixels(frames)
        elif len(frames) < MIN_FRAMES:
            frames = pingpong_to(frames, MIN_FRAMES)
            padded = True
        actors[key] = {
            "frames": len(frames), "frame_w": w, "frame_h": h,
            "fps": FPS_SLICED if kind == "sliced" else FPS_BREATH,
            "kind": kind, "label": key, "moving_px": moved,
            "source": "%s/raider_%s_idle_*.png" % (SRC, key),
            "dropped_frames": dropped,
        }
        if padded:
            actors[key]["pingpong_padded"] = True
        report.append((key, kind, len(frames), w, h, moved))
        files[OUT + "/" + key + ".png"] = encode_strip(frames)

    for key, name in sorted(single.items()):
        first = trim(Image.open(os.path.join(ROOT, SRC, name)).convert("RGBA"))
        frames, w, h = plant(breath_frames(first))
        actors[key] = {
            "frames": len(frames), "frame_w": w, "frame_h": h, "fps": FPS_BREATH,
            "kind": "breath", "label": key, "moving_px": moving_pixels(frames),
            "source": "%s/%s" % (SRC, name),
        }
        report.append((key, "breath", len(frames), w, h, actors[key]["moving_px"]))
        files[OUT + "/" + key + ".png"] = encode_strip(frames)
        if key in WALKERS:
            # The walk stands on the SAME planted canvas as the idle (frame 0 of
            # the breath is the pose at the strip's own w x h), so SceneStage's
            # feet offset and shadow are one number for both animations.
            walk = walk_frames(frames[0])
            wkey = key + "_walk"
            actors[wkey] = {
                "frames": len(walk), "frame_w": w, "frame_h": h, "fps": FPS_WALK,
                "kind": "walk", "label": key, "moving_px": moving_pixels(walk),
                "source": "%s/%s" % (SRC, name), "walk_of": key,
            }
            report.append((wkey, "walk", len(walk), w, h, actors[wkey]["moving_px"]))
            files[OUT + "/" + wkey + ".png"] = encode_strip(walk)

    for key, kind, n, w, h, moved in report:
        print("  %-26s %-6s %d frames  %2dx%-2d  %4d moving px" % (key, kind, n, w, h, moved))
    print("gen_actors: %d actors (%d sliced, %d breath, %d walk)" % (
        len(actors),
        sum(1 for a in actors.values() if a["kind"] == "sliced"),
        sum(1 for a in actors.values() if a["kind"] == "breath"),
        sum(1 for a in actors.values() if a["kind"] == "walk")))

    doc = {
        "generated_by": "tools/art/gen_actors.py",
        "why": ("spec 09 §4.1 row 4 / §4.2 row 8 owed bg-hall-patrons and "
                "bg-camp-figures; the bare plates of 2026-09-11 called them in. "
                "A strip is horizontal, frames left to right, each frame "
                "bottom-centre aligned so the feet do not move. A scene places "
                "an actor by its FEET (game/ui/SceneStage.gd anchors bottom). "
                "Every idle loops >= 4 frames at 5 fps (docs/12 §5.2; STAGE-16): "
                "a `breath` is 0, -1, -1 with the shoulders up, 0 — see the "
                "generator's docstring. A `walk` row (`<key>_walk`, `walk_of` = the "
                "pose it was derived from) is a second strip SceneStage plays as that "
                "figure's walk animation on a scene's `paths` (TOWN-27, W4-LIFE): the "
                "pose, a dip with the right leg lifted, the pose, a dip with the left. "
                "build_art.sh --check gates every byte here."),
        "label_note": ("Keys are the reference sheets' own labels. Which canon "
                       "class a figure stands for is not decided here."),
        "actors": actors,
    }
    files[MANIFEST] = (json.dumps(doc, indent=1, sort_keys=True, ensure_ascii=False) + "\n").encode("utf-8")

    if check:
        rc = 0
        for rel in sorted(files):
            tree = os.path.join(ROOT, rel)
            have = open(tree, "rb").read() if os.path.exists(tree) else None
            if have == files[rel]:
                continue
            print("  %s  %s" % ("DIFFERS" if have is not None else "MISSING", rel))
            rc = 1
        print("GEN_ACTORS CHECK %s  (%d files)" % ("OK" if rc == 0 else "FAILED", len(files)))
        return rc

    os.makedirs(os.path.join(ROOT, OUT), exist_ok=True)
    for rel in sorted(files):
        with open(os.path.join(ROOT, rel), "wb") as f:
            f.write(files[rel])
    print("gen_actors: wrote %d strips + %s" % (len(files) - 1, MANIFEST))
    return 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="byte-compare with the tree, write nothing")
    sys.exit(build(ap.parse_args().check))
