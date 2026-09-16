extends "res://tests/TestCase.gd"
## Every PNG under game/assets/vfx exists at the geometry its generator wrote it at, read
## through game/assets/vfx/vfx.json (W1-VFX; PIPE-02, STAGE-12, STAGE-14, PIPE-10).
##
## The manifest is written by tools/aseprite/gen_vfx.lua (build_art.sh --check byte-gates it
## with every Lua-generated PNG); this file holds the PNGs to it, holds the six combat strips
## and the three fires to the sizes 00-plan §W1-VFX fixes (the fire geometry is what every
## scene JSON's `frame_w` was authored against, so it is pinned by number here, not read from
## the scenes — W1-STAGE owns those), reads STAGE-12's "painted, not speckled" acceptance off
## the fire pixels themselves, and checks the cloud layers tile in x. A PNG the manifest does
## not name fails BY NAME, which is the moment to record where it came from.

const VFX_DIR := "res://game/assets/vfx/"
const MANIFEST := VFX_DIR + "vfx.json"

## 00-plan §W1-VFX: PIPE-02's names and sizes win (CRITIC-C04), sized for 2x figures.
## name: [frames, frame_w, frame_h]
const COMBAT := {
    "fx_spark_hit": [4, 32, 32],
    "fx_slash_arc": [5, 64, 48],
    "fx_bolt_arcane": [4, 24, 48],
    "fx_bolt_trail": [1, 8, 2],
    "fx_heal_sparkle": [6, 32, 32],
    "fx_burst_impact": [5, 64, 64],
    "fx_poof_smoke": [5, 48, 48],
}
## Re-authored at IDENTICAL geometry (STAGE-12): 512x56, 320x52, 96x24 on disk.
const FIRE := {
    "fire_hearth": [8, 64, 56],
    "fire_camp": [8, 40, 52],
    "fire_torch": [6, 16, 24],
}
const FIRE_MAX_COLOURS := 6        # STAGE-12's acceptance: painted bands, not speckle
const FIRE_MAX_COMPONENTS := 4     # ...and one silhouette, not a scatter of sparks
const CLOUDS := ["clouds_far", "clouds_near"]
const CLOUD_SIZE := Vector2i(1536, 220)


# ---------------------------------------------------------------- helpers

func _manifest() -> Dictionary:
    var text: String = FileAccess.get_file_as_string(MANIFEST)
    assert_true(text.length() > 0, "%s could not be read" % MANIFEST)
    var parsed = JSON.parse_string(text)
    assert_true(parsed is Dictionary and (parsed as Dictionary).has("strips"), "%s did not parse" % MANIFEST)
    if parsed is Dictionary and parsed.has("strips"):
        return parsed["strips"]
    return {}


func _image(name: String) -> Image:
    var path := VFX_DIR + name + ".png"
    if not ResourceLoader.exists(path):
        fail("%s does not exist" % path)
        return null
    var tex: Texture2D = load(path)
    var img := tex.get_image()
    if img == null:
        fail("%s: no image to read" % path)
        return null
    return img


func _pngs() -> Array[String]:
    var out: Array[String] = []
    for f in DirAccess.get_files_at(VFX_DIR):
        var n := String(f)
        if n.ends_with(".png"):
            out.append(n.get_basename())
    out.sort()
    return out


## Distinct non-transparent colours and 4-connected components of one frame.
func _frame_stats(img: Image, x0: int, w: int) -> Dictionary:
    var h := img.get_height()
    var colours := {}
    var seen := PackedByteArray()
    seen.resize(w * h)
    var components := 0
    for y in h:
        for x in w:
            var c := img.get_pixel(x0 + x, y)
            if c.a <= 0.0:
                continue
            colours[c.to_rgba32()] = true
            if seen[y * w + x] == 1:
                continue
            components += 1
            var stack: Array[int] = [y * w + x]
            seen[y * w + x] = 1
            while not stack.is_empty():
                var i: int = stack.pop_back()
                var cx := i % w
                var cy := i / w
                for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
                    var nx: int = cx + d[0]
                    var ny: int = cy + d[1]
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    var j := ny * w + nx
                    if seen[j] == 1 or img.get_pixel(x0 + nx, ny).a <= 0.0:
                        continue
                    seen[j] = 1
                    stack.append(j)
    return {"colours": colours.size(), "components": components}


func _column_diff(img: Image, xa: int, xb: int) -> float:
    var total := 0.0
    for y in img.get_height():
        var a := img.get_pixel(xa, y)
        var b := img.get_pixel(xb, y)
        total += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)
    return total * 255.0 / float(img.get_height() * 4)


# ---------------------------------------------------------------- the manifest

func test_the_manifest_names_every_png_and_every_row_exists() -> void:
    var strips := _manifest()
    var pngs := _pngs()
    assert_true(pngs.size() >= 14, "expected the fires, the six strips and the clouds, found %d PNGs" % pngs.size())
    var unnamed: Array[String] = []
    for n in pngs:
        if not strips.has(n):
            unnamed.append(n)
    assert_eq(unnamed.size(), 0, "PNGs no vfx.json row names: " + ", ".join(unnamed))
    var missing: Array[String] = []
    for name in strips:
        if not ResourceLoader.exists(VFX_DIR + String(name) + ".png"):
            missing.append(String(name))
    assert_eq(missing.size(), 0, "vfx.json rows with no PNG: " + ", ".join(missing))


func test_every_strip_is_frames_times_frame_w_wide() -> void:
    var strips := _manifest()
    var bad: Array[String] = []
    for name in strips:
        var row: Dictionary = strips[name]
        var frames := int(row.get("frames", 0))
        var fw := int(row.get("frame_w", 0))
        var fh := int(row.get("frame_h", 0))
        if frames < 1 or fw < 1 or fh < 1:
            bad.append("%s: row is not a strip (%d x %dx%d)" % [name, frames, fw, fh])
            continue
        if frames > 1 and float(row.get("fps", 0)) <= 0.0:
            bad.append("%s: %d frames at fps %s" % [name, frames, row.get("fps", 0)])
        var img := _image(String(name))
        if img == null:
            continue
        if img.get_width() != frames * fw or img.get_height() != fh:
            bad.append("%s: PNG is %dx%d, vfx.json says %d frames x %dx%d" % [
                name, img.get_width(), img.get_height(), frames, fw, fh])
    assert_eq(bad.size(), 0, "manifest and PNGs disagree:\n      " + "\n      ".join(bad))


func _assert_pinned(table: Dictionary, what: String) -> void:
    var strips := _manifest()
    for name in table:
        var want: Array = table[name]
        assert_true(strips.has(name), "%s %s is not in vfx.json" % [what, name])
        if not strips.has(name):
            continue
        var row: Dictionary = strips[name]
        assert_eq([int(row.get("frames", 0)), int(row.get("frame_w", 0)), int(row.get("frame_h", 0))], want,
            "%s row for %s" % [what, name])
        var img := _image(String(name))
        if img == null:
            continue
        assert_eq(img.get_width(), int(want[0]) * int(want[1]), "%s %s width" % [what, name])
        assert_eq(img.get_height(), int(want[2]), "%s %s height" % [what, name])


func test_the_six_combat_strips_are_at_the_plan_sizes() -> void:
    _assert_pinned(COMBAT, "combat strip")


func test_the_fire_geometry_is_unchanged() -> void:
    # Every scene JSON's `frame_w` and pos were authored against these; a different
    # size here is a change to game/assets/scenes, not to this file.
    _assert_pinned(FIRE, "fire strip")


# ---------------------------------------------------------------- the pixels

func test_fire_frames_are_banded_not_speckled() -> void:
    # STAGE-12's acceptance: per frame at most 6 distinct colours and at most 4
    # connected components — filled tongues with a licking outline, no scatter.
    var bad: Array[String] = []
    for name in FIRE:
        var img := _image(name)
        if img == null:
            continue
        var frames: int = FIRE[name][0]
        var fw: int = FIRE[name][1]
        for f in frames:
            var st := _frame_stats(img, f * fw, fw)
            if st["colours"] > FIRE_MAX_COLOURS or st["components"] > FIRE_MAX_COMPONENTS:
                bad.append("%s frame %d: %d colours, %d components" % [name, f, st["colours"], st["components"]])
            if st["components"] == 0:
                bad.append("%s frame %d is empty" % [name, f])
    assert_eq(bad.size(), 0, "speckled or scattered fire frames:\n      " + "\n      ".join(bad))


func test_animated_strips_change_between_frames() -> void:
    var strips := _manifest()
    var statues: Array[String] = []
    for name in strips:
        var row: Dictionary = strips[name]
        var frames := int(row.get("frames", 0))
        if frames < 2:
            continue
        var img := _image(String(name))
        if img == null:
            continue
        var fw := int(row.get("frame_w", 0))
        var moved := 0
        for y in img.get_height():
            for x in fw:
                if img.get_pixel(x, y) != img.get_pixel(fw + x, y):
                    moved += 1
        if moved == 0:
            statues.append(String(name))
    assert_eq(statues.size(), 0, "frame 2 is identical to frame 1 in: " + ", ".join(statues))


func test_the_cloud_layers_tile_in_x() -> void:
    for name in CLOUDS:
        var img := _image(name)
        if img == null:
            continue
        assert_eq(Vector2i(img.get_width(), img.get_height()), CLOUD_SIZE, "%s size" % name)
        var clear := 0
        var solid := 0
        for y in range(0, img.get_height(), 4):
            for x in range(0, img.get_width(), 8):
                var a := img.get_pixel(x, y).a
                if a <= 0.0:
                    clear += 1
                elif a > 0.4:
                    solid += 1
        assert_true(clear > 0 and solid > 0, "%s: a cloud layer needs sky between the clouds (%d clear, %d solid)" % [name, clear, solid])
        # periodic: the seam between the last column and the first is no larger a step
        # than the one between the first two columns
        var wrap := _column_diff(img, 0, img.get_width() - 1)
        var adjacent := _column_diff(img, 0, 1)
        assert_true(wrap <= maxf(6.0, 3.0 * adjacent + 2.0),
            "%s does not wrap: seam step %.2f vs adjacent %.2f" % [name, wrap, adjacent])


func test_no_authored_strip_bakes_pure_black_or_white() -> void:
    # light_soft.png is white by design (an alpha mask the light tints), so the rule
    # is read off the strips this unit authors.
    var names: Array[String] = []
    for n in COMBAT:
        names.append(n)
    for n in FIRE:
        names.append(n)
    for n in CLOUDS:
        names.append(n)
    var bad: Array[String] = []
    for name in names:
        var img := _image(name)
        if img == null:
            continue
        var hit := false
        for y in img.get_height():
            for x in img.get_width():
                var c := img.get_pixel(x, y)
                if c.a <= 0.0:
                    continue
                if (c.r >= 1.0 and c.g >= 1.0 and c.b >= 1.0) or (c.r <= 0.0 and c.g <= 0.0 and c.b <= 0.0):
                    hit = true
                    break
            if hit:
                break
        if hit:
            bad.append(name)
    assert_eq(bad.size(), 0, "pure black or white in: " + ", ".join(bad))


func test_every_vfx_png_has_an_import_sidecar() -> void:
    # A PNG without its .import is a `Failed to load` at the boot gate, not a test failure.
    var missing: Array[String] = []
    for n in _pngs():
        if not FileAccess.file_exists(VFX_DIR + n + ".png.import"):
            missing.append(n)
    assert_eq(missing.size(), 0, "no .import beside: " + ", ".join(missing))
