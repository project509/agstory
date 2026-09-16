"""Composite a scene JSON the way SceneStage will draw it, without booting Godot.

Authoring `game/assets/scenes/*.json` is placing pixels by typing numbers: a
figure's feet, a fire's base, a lantern's glow. Booting the game to check a
number is slow, and `tools/shot.gd` can only shoot a scene once a SCREEN has
been converted to use it — which is the step after this one. So this draws the
same stack with PIL: plate, props, actors, an approximation of the lights, the
water and crystal quads, the boss, and outlines where the bubbles will sit.

It is an approximation on purpose, and in exactly two places: `PointLight2D`
with `BLEND_MODE_ADD` is drawn as an additive soft disc (the engine's falloff
is the texture's, and the texture is the same `light_soft.png`, so the shape is
right and the response curve is not), and the glow pass is not run at all —
emissive props read brighter in game than they do here. Everything geometric —
what covers what, where a figure's feet land, whether a bubble sits on a face,
whether a pulse rect is under the boss plate — is exact, and that is what the
numbers in the JSON are for.

    python tools/art/preview_scene.py                 # every scene
    python tools/art/preview_scene.py stage_camp      # one, by name
    python tools/art/preview_scene.py --frame 2       # a later animation frame
    python tools/art/preview_scene.py stage_arena_cave --view raidview --marks
                                                      # cropped to RaidView's band,
                                                      # its chrome rects drawn,
                                                      # the fight's marks drawn
                                                      # with 2x stand-ins

`--view raidview|raidprep|results` crops to that screen's stage rect (the
offsets are the screens' own constants, copied here — RaidView.gd ARENA_OFFSET /
STAGE_H, RaidPrep.gd ARENA_OFFSET + host, Results.gd ARENA_OFFSET) and overlays
the chrome that sits on the stage (header, OBJECTIVE, BOSS_PLATE, the control
row, the strip) so an author can see what the plate's own light lands under.
`--marks` draws the scene's `marks`: the party ranks as feet ticks with a 2x
stand-in figure on each, the boss floor rect with the boss slice on its mark
(from game/assets/enemies/enemies.json, `boss_main` unless `--boss <rank>`).
Pulse rects are drawn as the soft additive glow SceneStage's shader makes of
them (feather 0.35); shimmer rects as dashed outlines.

`--animated` (W4-LIFE) renders the scene at a run of TIMES rather than one frame
index — the props on their fps, the walkers along their `paths`, the rotors
turned, the flyers along their splines — and writes an animated GIF plus a
four-frame filmstrip PNG (t = 0, 1.5, 3, 4.5 s at half size) so the motion can
be read from a still. The path arithmetic is SceneStage's, copied: a polyline
by arc length, ping-pong unless `loop`, a Catmull-Rom spline sampled 12 to a
segment for the flyers.

Writes build/preview/<name>[.<view>].png (gitignored scratch); with
`--animated`, build/preview/<name>.anim.gif and <name>.anim.png.
"""
import argparse
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

SCENES = "game/assets/scenes"
ENEMIES = "game/assets/enemies"
OUT = "build/preview"
RES = "res://"

# The screens' stage rects and the chrome over them, in SCREEN pixels. The
# offset is what the screen adds to plate coordinates (stage.position); the
# view band is `size` rows of plate starting at -offset. Copied from the
# screens' constants (they are not importable from Python); a change there is a
# change here.
VIEWS = {
    "raidview": {
        "offset": (0, -280), "size": (1536, 735),
        "chrome": [
            ("HEADER", (0, 0, 352, 64)),
            ("OBJECTIVE", (0, 88, 352, 106)),
            ("BOSS_PLATE", (931, 53, 384, 65)),
            ("CONTROLS L", (4, 675, 588, 45)),
            ("CONTROLS R", (1150, 675, 368, 45)),
        ],
    },
    "results": {
        "offset": (0, -280), "size": (1536, 735),
        "chrome": [("HEADER", (0, 0, 352, 64)), ("BOSS_PLATE", (931, 53, 384, 65))],
    },
    "raidprep": {
        # RaidPrep mounts the stage inside a host at (208, 80) sized 928x640 and
        # offsets it by (-30, -120); the band below is in HOST pixels.
        "offset": (-30, -120), "size": (928, 640),
        "chrome": [],
    },
}


def path_of_res(res_path):
    """res://game/... -> game/... (this script runs from the project root)."""
    return res_path[len(RES):] if res_path.startswith(RES) else res_path


def frame_of(strip_path, frame_w, index):
    strip = Image.open(strip_path).convert("RGBA")
    fw = max(1, int(frame_w))
    n = max(1, strip.width // fw)
    i = index % n
    return strip.crop((i * fw, 0, i * fw + fw, strip.height))


def paste_bottom_centre(base, sprite, x, y, scale=1.0, flip=False, tint=None):
    """SceneStage anchors a prop and an actor the same way: `pos` is the FLOOR."""
    if flip:
        sprite = sprite.transpose(Image.FLIP_LEFT_RIGHT)
    if scale != 1.0:
        sprite = sprite.resize((max(1, int(round(sprite.width * scale))),
                                max(1, int(round(sprite.height * scale)))), Image.NEAREST)
    if tint:
        t = np.array(sprite).astype(float)
        t[:, :, 0] *= tint[0]
        t[:, :, 1] *= tint[1]
        t[:, :, 2] *= tint[2]
        sprite = Image.fromarray(np.clip(t, 0, 255).astype(np.uint8), "RGBA")
    base.alpha_composite(sprite, (int(round(x - sprite.width / 2.0)),
                                  int(round(y - sprite.height))))


def add_shadow(base, x, y, width, alpha):
    """The contact ellipse SceneStage puts under every actor."""
    tex_path = "game/assets/vfx/light_soft.png"
    if not os.path.exists(tex_path):
        return
    w = max(4, int(round(width * 1.15)))
    h = max(2, int(round(width * 0.42)))
    soft = Image.open(tex_path).convert("RGBA").resize((w, h), Image.BILINEAR)
    a = np.array(soft).astype(float)
    a[:, :, 0:3] = (5, 5, 13)
    a[:, :, 3] *= alpha
    blob = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    base.alpha_composite(blob, (int(round(x - w / 2.0)), int(round(y - 2 - h / 2.0))))


def add_light(base, x, y, radius, colour, energy):
    """PointLight2D + BLEND_MODE_ADD, approximated with its own texture."""
    tex_path = "game/assets/vfx/light_soft.png"
    if not os.path.exists(tex_path):
        return
    d = max(8, int(round(radius * 2)))
    soft = Image.open(tex_path).convert("RGBA").resize((d, d), Image.BILINEAR)
    a = np.array(soft).astype(float) / 255.0
    lum = a[:, :, 3] * float(energy)
    add = np.zeros((d, d, 3), float)
    for c in range(3):
        add[:, :, c] = lum * colour[c] * 255.0
    x0, y0 = int(round(x - d / 2.0)), int(round(y - d / 2.0))
    region = base.crop((x0, y0, x0 + d, y0 + d)).convert("RGB")
    out = np.clip(np.array(region).astype(float) + add, 0, 255).astype(np.uint8)
    base.paste(Image.fromarray(out, "RGB"), (x0, y0))


def add_pulse(base, rect, colour, energy, feather=0.35):
    """SceneStage's feathered additive pulse quad (PULSE_SHADER), at base alpha."""
    x, y, w, h = [int(round(v)) for v in rect]
    if w <= 0 or h <= 0:
        return
    u = (np.arange(w) + 0.5) / w
    v = (np.arange(h) + 0.5) / h
    uu, vv = np.meshgrid(u, v)
    e = np.minimum(np.minimum(uu, 1 - uu), np.minimum(vv, 1 - vv)) / max(feather, 0.001)
    edge = np.clip(e, 0, 1)
    edge = edge * edge * (3 - 2 * edge)
    r = np.sqrt(((uu - 0.5) * 2) ** 2 + ((vv - 0.5) * 2) ** 2)
    t = np.clip((r - 0.45) / (1.05 - 0.45), 0, 1)
    radial = 1 - (t * t * (3 - 2 * t))
    alpha = energy * edge * radial
    region = base.crop((x, y, x + w, y + h)).convert("RGB")
    add = np.zeros((h, w, 3), float)
    for c in range(3):
        add[:, :, c] = alpha * colour[c] * 255.0
    out = np.clip(np.array(region).astype(float) + add, 0, 255).astype(np.uint8)
    base.paste(Image.fromarray(out, "RGB"), (x, y))


def dashed_rect(draw, rect, colour, dash=6):
    x, y, w, h = rect
    pts = [(x, y), (x + w, y), (x + w, y + h), (x, y + h), (x, y)]
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        length = max(abs(bx - ax), abs(by - ay))
        n = max(1, int(length // dash))
        for i in range(0, n, 2):
            t0, t1 = i / n, min(1.0, (i + 1) / n)
            draw.line([(ax + (bx - ax) * t0, ay + (by - ay) * t0),
                       (ax + (bx - ax) * t1, ay + (by - ay) * t1)], fill=colour, width=1)


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def actors_manifest():
    p = "game/assets/actors/actors.json"
    if not os.path.exists(p):
        return {}
    with open(p, encoding="utf-8") as f:
        return json.load(f).get("actors", {})


def boss_slice(rank):
    p = os.path.join(ENEMIES, rank + ".png")
    return Image.open(p).convert("RGBA") if os.path.exists(p) else None


# ---------------------------------------------------------------- paths (W4-LIFE)
# SceneStage's arithmetic, copied: a path is a polyline by arc length; a
# traveller is a distance along it that ping-pongs (or wraps when `loop`).

def path_of(points):
    pts = [(float(p[0]), float(p[1])) for p in points if isinstance(p, list) and len(p) >= 2]
    cum = [0.0]
    for a, b in zip(pts, pts[1:]):
        cum.append(cum[-1] + ((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5)
    return pts, cum, (cum[-1] if len(pts) > 1 else 0.0)


def along(pts, cum, s):
    """(x, y, dir_x) at arc length s."""
    if not pts:
        return 0.0, 0.0, 1.0
    if len(pts) == 1:
        return pts[0][0], pts[0][1], 1.0
    s = min(max(s, 0.0), cum[-1])
    i = 0
    while i < len(pts) - 2 and s > cum[i + 1]:
        i += 1
    seg = cum[i + 1] - cum[i]
    t = (s - cum[i]) / seg if seg > 0 else 0.0
    a, b = pts[i], pts[i + 1]
    dx = (b[0] - a[0]) / seg if seg > 0 else 1.0
    return a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, dx


def travel(total, phase, v, t, loop):
    """Arc length and direction sign after t seconds from `phase` of the way along."""
    if total <= 0:
        return 0.0, 1.0
    s = phase * total + v * t
    if loop:
        return s % total, 1.0
    s = s % (2.0 * total)
    if s > total:
        return 2.0 * total - s, -1.0
    return s, 1.0


def spline(pts, loop, per=12):
    n = len(pts)
    if n < 3:
        return list(pts)
    out = []
    segs = n if loop else n - 1
    for i in range(segs):
        p0 = pts[(i - 1 + n) % n] if loop else pts[max(i - 1, 0)]
        p1, p2 = pts[i], pts[(i + 1) % n]
        p3 = pts[(i + 2) % n] if loop else pts[min(i + 2, n - 1)]
        for k in range(per):
            t = k / per
            out.append(tuple(0.5 * (2 * p1[c] + (p2[c] - p0[c]) * t
                                    + (2 * p0[c] - 5 * p1[c] + 4 * p2[c] - p3[c]) * t * t
                                    + (3 * p1[c] - p0[c] - 3 * p2[c] + p3[c]) * t * t * t) for c in (0, 1)))
    out.append(pts[0] if loop else pts[n - 1])
    return out


def draw_walkers(base, d, manifest, figure_scale, t):
    """The `paths` layer at time t: each figure at its arc length, on its walk strip."""
    for w in d.get("paths", []):
        who = str(w.get("who", ""))
        geom = manifest.get(who)
        pts, cum, total = path_of(w.get("points", []))
        if geom is None or len(pts) < 2:
            continue
        s, sign = travel(total, float(w.get("phase", 0.0)), float(w.get("px_per_s", 18.0)), t, bool(w.get("loop", False)))
        x, y, dx = along(pts, cum, s)
        walk = manifest.get(who + "_walk")
        strip = os.path.join("game/assets/actors", (who + "_walk") if walk else who) + ".png"
        row = walk or geom
        sc = float(w.get("scale", figure_scale))
        add_shadow(base, x, y, float(geom.get("frame_w", 16)) * sc, 0.42)
        fi = int(t * float(row.get("fps", 6)))
        paste_bottom_centre(base, frame_of(strip, row.get("frame_w", 16), fi), x, y, sc, dx * sign < 0)


def draw_rotors(base, d, t):
    """The `rotor` layer: the sail sprites turned rad_per_s * t about their axle."""
    for r in d.get("rotor", []):
        tex = path_of_res(str(r.get("tex", "")))
        pos = r.get("pos", [])
        if not os.path.exists(tex) or len(pos) < 2:
            continue
        spr = Image.open(tex).convert("RGBA")
        rad = float(r.get("phase", 0.0)) + float(r.get("rad_per_s", 0.15)) * t
        # Godot's rotation is clockwise on screen (y down); PIL's is counter-clockwise.
        spr = spr.rotate(-rad * 180.0 / 3.141592653589793, resample=Image.BILINEAR, expand=False)
        base.alpha_composite(spr, (int(round(pos[0] - spr.width / 2.0)), int(round(pos[1] - spr.height / 2.0))))


def draw_flyers(base, d, t):
    """The `flyers` layer: a strip riding its spline."""
    for i, f in enumerate(d.get("flyers", [])):
        strip = path_of_res(str(f.get("strip", "")))
        pts = [(float(p[0]), float(p[1])) for p in f.get("points", []) if isinstance(p, list) and len(p) >= 2]
        if not os.path.exists(strip) or len(pts) < 2:
            continue
        loop = bool(f.get("loop", True))
        spts, cum, total = path_of([list(p) for p in spline(pts, loop)])
        s, sign = travel(total, float(f.get("phase", 0.0)), float(f.get("px_per_s", 12.0)), t, loop)
        x, y, dx = along(spts, cum, s)
        fw = int(f.get("frame_w", 12))
        sprite = frame_of(strip, fw, int(t * float(f.get("fps", 5))) + i)
        sc = float(f.get("scale", 1.0))
        if dx * sign < 0:
            sprite = sprite.transpose(Image.FLIP_LEFT_RIGHT)
        if sc != 1.0:
            sprite = sprite.resize((max(1, int(sprite.width * sc)), max(1, int(sprite.height * sc))), Image.NEAREST)
        base.alpha_composite(sprite, (int(round(x - sprite.width / 2.0)), int(round(y - sprite.height / 2.0))))


def draw_marks(base, d, boss_rank, manifest, frame):
    """The fight's blocking: party feet ticks + 2x stand-ins, the boss floor and slice."""
    marks = d.get("marks")
    if not isinstance(marks, dict):
        print("preview: no `marks` in this scene", file=sys.stderr)
        return
    draw = ImageDraw.Draw(base)
    party = marks.get("party", {})
    sc = float(party.get("scale", 1.0))
    flip = str(party.get("face", "right")) == "left"
    # One stand-in per slot, the class strips in a fixed cycle so heights vary
    # the way a real party's do.
    cycle = ["warrior", "rogue", "mage", "cleric", "warrior_b", "rogue_b", "mage_b",
             "cleric_b", "knight_unlabelled", "ranger_as_rogue", "warrior", "mage"]
    slot = 0
    ranks = party.get("ranks", [])
    for rank in sorted(ranks, key=lambda r: r.get("y", 0)):
        y = rank.get("y", 0)
        for x in rank.get("xs", []):
            who = cycle[slot % len(cycle)]
            slot += 1
            geom = manifest.get(who)
            strip = os.path.join("game/assets/actors", who + ".png")
            if geom and os.path.exists(strip):
                add_shadow(base, x, y, float(geom.get("frame_w", 16)) * sc, 0.42)
                paste_bottom_centre(base, frame_of(strip, geom.get("frame_w", 16), frame + slot),
                                    x, y, sc, flip)
            draw.line([x - 6, y, x + 6, y], fill=(255, 80, 80, 255), width=1)
            draw.line([x, y - 4, x, y + 4], fill=(255, 80, 80, 255), width=1)
    boss = marks.get("boss", {})
    floor = boss.get("floor")
    if isinstance(floor, list) and len(floor) == 4:
        draw.rectangle([floor[0], floor[1], floor[0] + floor[2], floor[1] + floor[3]],
                       outline=(255, 160, 60, 255))
    pos = boss.get("pos")
    if isinstance(pos, list) and len(pos) == 2:
        tex = boss_slice(boss_rank)
        if tex is not None:
            bsc = float(boss.get("scale", 1.0))
            add_shadow(base, pos[0], pos[1], tex.width * bsc * 0.83, 0.5)
            paste_bottom_centre(base, tex, pos[0], pos[1], bsc, bool(boss.get("flip", False)))
        draw.line([pos[0] - 8, pos[1], pos[0] + 8, pos[1]], fill=(255, 160, 60, 255), width=1)
        draw.line([pos[0], pos[1] - 6, pos[0], pos[1] + 6], fill=(255, 160, 60, 255), width=1)


def render(name, frame, annotate, view=None, marks=False, boss_rank="boss_main", t=None, save=True):
    """One still. `t` (seconds, --animated) drives every layer that moves; without it
    `frame` is the animation frame index the older flags use."""
    with open(os.path.join(SCENES, name + ".json"), encoding="utf-8") as f:
        d = json.load(f)
    plate_path = path_of_res(d.get("plate", ""))
    if not os.path.exists(plate_path):
        print("preview: %s has no plate at %s" % (name, plate_path), file=sys.stderr)
        return None
    base = Image.open(plate_path).convert("RGBA")
    figure_scale = float(d.get("figure_scale", 1.0))

    for light in d.get("lights", []):
        pos = light.get("pos", [0, 0])
        add_light(base, pos[0], pos[1], float(light.get("radius", 200)),
                  hexrgb(str(light.get("color", "#FFB060"))), float(light.get("energy", 1.0)))

    for p in d.get("props", []):
        strip = path_of_res(str(p.get("strip", "")))
        if not os.path.exists(strip):
            continue
        pos = p.get("pos", [0, 0])
        # SceneStage tints only a prop that declares `emissive`; a plate crop draws as it is.
        tint = None
        if "emissive" in p:
            em = float(p.get("emissive", 1.0))
            tint = (em, em * 0.94, em * 0.85)
        fi = (int(t * float(p.get("fps", 9))) if t is not None else frame) + int(p.get("phase", 0))
        sprite = frame_of(strip, p.get("frame_w", 16), fi)
        if str(p.get("anchor", "bottom")) == "topleft":
            base.alpha_composite(sprite, (int(pos[0]), int(pos[1])))
        else:
            paste_bottom_centre(base, sprite, pos[0], pos[1], tint=tint)

    draw_rotors(base, d, t or 0.0)

    manifest = actors_manifest()
    placed = sorted([a for a in d.get("actors", []) if isinstance(a, dict)],
                    key=lambda a: a.get("pos", [0, 0])[1])
    missing = []
    for nth, a in enumerate(placed):
        who = str(a.get("who", ""))
        geom = manifest.get(who)
        strip = os.path.join("game/assets/actors", who + ".png")
        if geom is None or not os.path.exists(strip):
            missing.append(who)
            continue
        pos = a.get("pos", [0, 0])
        tint = hexrgb(str(a["tint"])) if "tint" in a else None
        sc = float(a.get("scale", figure_scale))
        if a.get("shadow", True):
            add_shadow(base, pos[0], pos[1], float(geom.get("frame_w", 16)) * sc,
                       float(a.get("shadow_alpha", 0.42)))
        fi = (int(t * float(geom.get("fps", 5))) if t is not None else frame) + int(a.get("phase", nth))
        paste_bottom_centre(base, frame_of(strip, geom.get("frame_w", 16), fi),
                            pos[0], pos[1], sc, bool(a.get("flip", False)), tint)

    # The walkers, after the crowd (SceneStage settles their depth among it;
    # the preview draws them over — the paths are authored on open ground).
    draw_walkers(base, d, manifest, figure_scale, t or 0.0)

    # Water and crystal light, after the crowd the way SceneStage adds them.
    for pl in d.get("pulse", []):
        r = pl.get("rect", [])
        if len(r) == 4:
            add_pulse(base, r, hexrgb(str(pl.get("color", "#78C8FF"))), float(pl.get("energy", 0.16)),
                      float(pl.get("feather", 0.35)))

    draw_flyers(base, d, t or 0.0)

    if marks:
        draw_marks(base, d, boss_rank, manifest, frame)

    if annotate:
        draw = ImageDraw.Draw(base)
        for sh in d.get("shimmer", []):
            r = sh.get("rect", [])
            if len(r) == 4:
                dashed_rect(draw, r, (120, 200, 255, 255))
        for pl in d.get("pulse", []):
            r = pl.get("rect", [])
            if len(r) == 4:
                dashed_rect(draw, r, (140, 240, 255, 255), dash=3)
        for em in d.get("embers", []):
            pos = em.get("pos", [0, 0])
            draw.ellipse([pos[0] - 3, pos[1] - 3, pos[0] + 3, pos[1] + 3], outline=(255, 200, 120, 255))
        for b in d.get("bubbles", []):
            if isinstance(b, list) and len(b) >= 2:
                draw.rectangle([b[0], b[1], b[0] + 33, b[1] + 32], outline=(120, 220, 255, 255))
        sp = d.get("speech")
        if isinstance(sp, dict):
            pos, size = sp.get("pos", [0, 0]), sp.get("size", [174, 62])
            # `speaker` (TOWN-03): SceneStage hangs the plate's bottom-centre
            # 28px above that actor's head (authoring-order index), so draw it
            # there rather than at `pos`.
            speaker = sp.get("speaker", -1)
            raw = d.get("actors", [])
            if isinstance(speaker, int) and 0 <= speaker < len(raw) and isinstance(raw[speaker], dict):
                who = raw[speaker]
                geom = manifest.get(str(who.get("who", "")))
                if geom:
                    fx, fy = who.get("pos", [0, 0])
                    head_y = fy - float(geom.get("frame_h", 0)) * float(who.get("scale", figure_scale))
                    pos = [fx - size[0] / 2.0, head_y - 28 - size[1]]
                    draw.line([fx, head_y - 28, fx, head_y - 2], fill=(255, 220, 120, 255), width=1)
            draw.rectangle([pos[0], pos[1], pos[0] + size[0], pos[1] + size[1]],
                           outline=(255, 220, 120, 255))
        for a in placed:
            pos = a.get("pos", [0, 0])
            draw.line([pos[0] - 4, pos[1], pos[0] + 4, pos[1]], fill=(255, 60, 60, 255))
        for w in d.get("paths", []):
            pts, _, _ = path_of(w.get("points", []))
            if len(pts) >= 2:
                draw.line(pts, fill=(255, 160, 80, 255), width=1)
        for f in d.get("flyers", []):
            pts = [(float(p[0]), float(p[1])) for p in f.get("points", []) if isinstance(p, list) and len(p) >= 2]
            if len(pts) >= 2:
                draw.line(spline(pts, bool(f.get("loop", True))), fill=(200, 220, 255, 255), width=1)

    suffix = ""
    if view:
        cfg = VIEWS[view]
        ox, oy = cfg["offset"]
        w, h = cfg["size"]
        # The screen shows plate pixel (px, py) at screen (px + ox, py + oy).
        canvas = Image.new("RGBA", (w, h), (3, 11, 19, 255))
        canvas.alpha_composite(base, (ox, oy))
        draw = ImageDraw.Draw(canvas)
        for label, (x, y, cw, ch) in cfg["chrome"]:
            draw.rectangle([x, y, x + cw, y + ch], outline=(255, 255, 120, 255))
            draw.rectangle([x, y, x + cw, y + ch], fill=(20, 20, 30, 110))
            draw.text((x + 4, y + 3), label, fill=(255, 255, 160, 255))
        base = canvas
        suffix = "." + view

    if not save:
        return base
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, name + suffix + ".png")
    base.convert("RGB").save(out)
    print("  %-22s %d actors, %d props, %d lights, %d pulse, x%g -> %s%s" % (
        name, len(placed), len(d.get("props", [])), len(d.get("lights", [])), len(d.get("pulse", [])),
        figure_scale, out, ("   MISSING: " + ", ".join(missing)) if missing else ""))
    return out


def render_animated(name, annotate, seconds=6.0, step=0.25):
    """--animated: the scene over `seconds`, as a GIF and a four-frame filmstrip."""
    frames = [render(name, 0, annotate, t=k * step, save=False).convert("RGB")
              for k in range(int(round(seconds / step)))]
    os.makedirs(OUT, exist_ok=True)
    gif = os.path.join(OUT, name + ".anim.gif")
    small = [f.resize((f.width // 2, f.height // 2), Image.BILINEAR) for f in frames]
    small[0].save(gif, save_all=True, append_images=small[1:], duration=int(step * 1000), loop=0)
    picks = [min(int(round(sec / step)), len(small) - 1) for sec in (0.0, 1.5, 3.0, 4.5)]
    w, h = small[0].size
    sheet = Image.new("RGB", (2 * w + 4, 2 * h + 4), (255, 0, 255))
    for i, k in enumerate(picks):
        sheet.paste(small[k], ((i % 2) * (w + 4), (i // 2) * (h + 4)))
    strip = os.path.join(OUT, name + ".anim.png")
    sheet.save(strip)
    print("  %-22s %d frames over %gs -> %s, filmstrip (t=0, 1.5, 3, 4.5) -> %s" % (
        name, len(frames), seconds, gif, strip))
    return strip


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("names", nargs="*", help="scene names (default: all of them)")
    ap.add_argument("--frame", type=int, default=0, help="animation frame to draw")
    ap.add_argument("--plain", action="store_true", help="no bubble/foot/rect annotations")
    ap.add_argument("--view", choices=sorted(VIEWS), help="crop to a screen's band and draw its chrome")
    ap.add_argument("--marks", action="store_true", help="draw the scene's `marks` with 2x stand-ins")
    ap.add_argument("--boss", default="boss_main", help="enemies/<rank>.png to stand on the boss mark")
    ap.add_argument("--animated", action="store_true",
                    help="a GIF + filmstrip over six seconds (walkers, rotors, flyers, props)")
    args = ap.parse_args()
    names = args.names or sorted(
        f[:-5] for f in os.listdir(SCENES) if f.endswith(".json"))
    for n in names:
        if args.animated:
            render_animated(n, not args.plain)
        else:
            render(n, args.frame, not args.plain, args.view, args.marks, args.boss)
