extends "res://tests/TestCase.gd"
## W1-ICONS: one icon grid, one generator, one lookup (00-plan §2).
##
## The contract has three sides and this file holds them against each other:
##   1. game/ui/Icons.gd — the size table and `at(role, key)`;
##   2. game/assets/ui/icons/grid/icons.json — the manifest gen_icons.lua writes
##      with every file it emitted (name, role, key, file, w, h);
##   3. the PNGs on disk, read RAW with Image.load_from_file (never the imported
##      .ctex, whose fix_alpha_border rewrites transparent pixels) for their
##      size and pixels, and through `Icons.at()` for the texture the game gets.
## Every key list a screen will iterate (Enums.CLASS_KEYS, MECHANIC_KEYS,
## REPUTATION_KEYS, SLOT_KEYS, Comfort's furnishings, enemies.json's ranks, the
## state/log/building/emote lists on Icons.gd) is walked, so a key the sim
## grows without a glyph fails here by name.

const Icons = preload("res://game/ui/Icons.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Comfort = preload("res://sim/core/Comfort.gd")

const ICONS_GD := "res://game/ui/Icons.gd"
const GEN := "res://tools/aseprite/gen_icons.lua"
const ENEMIES_JSON := "res://game/assets/enemies/enemies.json"
const CHIP_FILL := Color("020B12")   # Palette.SURFACE_CHIP: what the rank sigil sits on
const NEW_PROVISIONS := ["whetstone_kit", "mana_draught", "guild_feast"]
const OLD_PROVISIONS := ["minor_healing_potion", "potion_of_steady_hands", "rally_flask", "unknown"]
## Grid names whose top-level namesake is a manifest hand crop left in place (J2).
const SHADOWED_CROPS := ["class_warrior"]

var _manifest: Dictionary = {}


func before_each() -> void:
    _manifest = _json(Icons.MANIFEST)


# ---------------------------------------------------------------- helpers

func _json(path: String) -> Dictionary:
    var text: String = FileAccess.get_file_as_string(path)
    assert_true(text.length() > 0, "%s could not be read" % path)
    var parsed = JSON.parse_string(text)
    assert_true(parsed is Dictionary, "%s did not parse as an object" % path)
    return parsed if parsed is Dictionary else {}


func _raw(path: String) -> Image:
    var img := Image.load_from_file(ProjectSettings.globalize_path(path))
    assert_true(img != null and not img.is_empty(), "%s did not decode" % path)
    if img == null:
        return Image.create(1, 1, false, Image.FORMAT_RGBA8)
    img.convert(Image.FORMAT_RGBA8)
    return img


## Every (role, key) resolves to a file of the role's cell size, raw and imported.
func _check(role: String, key: String) -> void:
    var cell := Icons.size(role)
    assert_true(cell > 0, "role %s has no size" % role)
    var p: String = Icons.path(role, key)
    assert_true(p != "", "Icons.path(%s, %s) found no file" % [role, key])
    if p == "":
        return
    var img := _raw(p)
    assert_eq(img.get_size(), Vector2i(cell, cell), "%s is not %dx%d" % [p, cell, cell])
    var tex: Texture2D = Icons.at(role, key)
    assert_true(tex != null, "Icons.at(%s, %s) returned null" % [role, key])
    if tex != null:
        assert_eq(tex.get_size(), Vector2(cell, cell), "Icons.at(%s, %s) texture is not the cell" % [role, key])


func _pngs_under(dir: String) -> Array[String]:
    var out: Array[String] = []
    for f in DirAccess.get_files_at(dir):
        if String(f).ends_with(".png"):
            out.append(dir.path_join(String(f)))
    for d in DirAccess.get_directories_at(dir):
        out.append_array(_pngs_under(dir.path_join(String(d))))
    out.sort()
    return out


func _lin(v: float) -> float:
    return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)


## WCAG relative luminance (the same pipeline tools/art/cvd.py measures with).
func _lum(c: Color) -> float:
    return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


func _contrast(a: Color, b: Color) -> float:
    var la := _lum(a)
    var lb := _lum(b)
    return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


# ---------------------------------------------------------------- the size table

func test_size_table_matches_the_generators_manifest() -> void:
    var roles: Dictionary = _manifest.get("roles", {})
    assert_eq(roles.keys().size(), Icons.SIZES.keys().size(), "manifest roles vs Icons.SIZES")
    for role in Icons.SIZES.keys():
        assert_true(roles.has(role), "manifest has no role " + String(role))
        assert_eq(int(roles.get(role, 0)), Icons.size(String(role)), "cell size of " + String(role))
        assert_true(Icons.PREFIX.has(role), "no prefix for role " + String(role))
    assert_eq(Icons.size("nope"), 0, "an unknown role is size 0")
    # the grid the plan fixes (CRITIC-G07)
    assert_eq(Icons.size("class"), 16)
    assert_eq(Icons.size("log"), 22)
    assert_eq(Icons.size("state"), 24)
    assert_eq(Icons.size("mech"), 24)
    assert_eq(Icons.size("rank"), 28)
    assert_eq(Icons.size("building"), 32)
    assert_eq(Icons.size("sigil"), 48)


# ---------------------------------------------------------------- the key lists

func test_every_class_has_a_glyph_and_the_warrior_switch_is_swords() -> void:
    for k in Enums.CLASS_KEYS:
        _check("class", String(k))
    assert_eq(Icons.WARRIOR_GLYPH, "swords", "Q18 default")
    assert_eq(Icons.file_name("class", "warrior"), "class_warrior")
    _check("class", "warrior_shield")   # the other reading, emitted beside it


func test_every_mechanic_has_a_plate_under_both_spellings() -> void:
    assert_eq(Enums.MECHANIC_KEYS.size(), 12)
    for i in Enums.MECHANIC_KEYS.size():
        var mkey := String(Enums.MECHANIC_KEYS[i])
        var file_key := String(Enums.Mechanic.keys()[i]).to_lower()
        assert_eq(Icons.mech_key(mkey), file_key, mkey + " -> file spelling")
        assert_eq(Icons.mech_key(file_key), file_key, file_key + " round-trips")
        _check("mech", mkey)
        assert_eq(Icons.path("mech", mkey), Icons.path("mech", file_key), "one file for both spellings")
        # RaidView.gd loads ICON + "mech_%s.png" by the enum spelling: the file stays at the top level
        assert_eq(Icons.path("mech", mkey), Icons.DIR + "mech_" + file_key + ".png", "mech_* stays where RaidView loads it")
    assert_eq(Icons.mech_key("m99"), "", "an unknown mechanic key is empty, not a guess")


func test_every_state_log_building_emote_has_its_file() -> void:
    assert_eq(Icons.STATE_KEYS.size(), 8)
    for k in Icons.STATE_KEYS:
        _check("state", String(k))
    assert_eq(Icons.LOG_KINDS.size(), 12)
    for k in Icons.LOG_KINDS:
        _check("log", String(k))
    assert_eq(Icons.BUILDING_KEYS.size(), 5)
    for k in Icons.BUILDING_KEYS:
        _check("building", String(k))
    assert_eq(Icons.EMOTE_KEYS.size(), 10)
    for k in Icons.EMOTE_KEYS:
        _check("emote", String(k))
    for k in Icons.EMPTY_KEYS:
        _check("empty", String(k))


func test_every_rank_sigil_keeps_its_path_and_its_rim_reads_on_the_chip() -> void:
    assert_eq(Enums.REPUTATION_KEYS.size(), 6)
    for k in Enums.REPUTATION_KEYS:
        var key := String(k)
        _check("rank", key)
        # Frame.gd:431 loads icons + "rank_%s.png" — the re-author keeps the name and the top level
        assert_eq(Icons.path("rank", key), Icons.DIR + "rank_" + key + ".png")
        var img := _raw(Icons.path("rank", key))
        var ring := 0
        var worst := 99.0
        for y in img.get_height():
            for x in img.get_width():
                var c := img.get_pixel(x, y)
                if c.a < 0.999:
                    continue
                var on_ring := false
                for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
                    var n: Vector2i = Vector2i(x, y) + d
                    if n.x < 0 or n.y < 0 or n.x >= img.get_width() or n.y >= img.get_height():
                        on_ring = true
                    elif img.get_pixel(n.x, n.y).a < 0.999:
                        on_ring = true
                if on_ring:
                    ring += 1
                    worst = minf(worst, _contrast(c, CHIP_FILL))
        assert_true(ring > 40, "rank_%s has no outline ring" % key)
        assert_true(worst >= 3.0, "rank_%s rim contrast vs #020B12 is %.2f:1 (KIT-16 wants >= 3:1)" % [key, worst])


func test_the_rest_of_the_grid() -> void:
    for k: String in ["hp", "focus"]:
        _check("bar", k)
    for k: String in OLD_PROVISIONS + NEW_PROVISIONS:
        _check("item", k)
    var furnishings: Array = Comfort.FURNISHINGS.keys() + Comfort.GUILD_FURNISHINGS.keys()
    assert_eq(furnishings.size(), 6, "one furnishing icon per Comfort key")
    for k in furnishings:
        _check("furnishing", String(k))
    var ranks: Dictionary = _json(ENEMIES_JSON).get("ranks", {})
    assert_eq(ranks.keys().size(), 6)
    for k in ranks.keys():
        _check("sigil", String(k))
    _check("lock", "16")
    for k: String in ["a", "b", "c"]:
        _check("blot", k)
    for k: String in ["left", "right", "up", "down"]:
        _check("arrow", k)
    for b in 10:
        _check("face", str(b))
    for k in Enums.SLOT_KEYS:
        _check("slot", String(k))
    for k: String in ["cog_24", "fast_forward_24"]:
        _check("control", k)


## Everything consumed today keeps its name and size (00-plan: "Regenerating an
## existing set must keep dimensions"): the top-level files, by name.
func test_legacy_names_keep_their_dimensions() -> void:
    var expect := {"rank_": 28, "mech_": 24, "face_": 24, "slot_": 32, "arrow_": 16, "cog_24": 24, "fast_forward_24": 24, "item_": 32}
    var seen := 0
    for path in _pngs_under(Icons.DIR):
        if path.begins_with(Icons.GRID):
            continue
        var base := path.get_file().get_basename()
        for prefix in expect.keys():
            if base.begins_with(String(prefix)) and not (prefix == "item_" and not (base.trim_prefix("item_") in OLD_PROVISIONS)):
                var s: int = int(expect[prefix])
                assert_eq(_raw(path).get_size(), Vector2i(s, s), base + " changed size")
                seen += 1
    # 6 rank + 12 mech + 10 face + 7 slot + 2 arrow + cog + ff + 4 potions
    assert_eq(seen, 43, "expected the 43 legacy generated files by name")
    assert_eq(_raw("res://game/assets/ui/faces.png").get_size(), Vector2i(240, 24), "faces.png strip")


# ---------------------------------------------------------------- the manifest vs the disk

func test_every_png_under_the_grid_is_in_the_manifest_and_every_row_is_on_disk() -> void:
    var files: Array = _manifest.get("files", [])
    assert_true(files.size() >= 100, "the manifest lists %d files; the grid is bigger than that" % files.size())
    var by_file := {}
    var names := {}
    for row in files:
        var name := String(row.get("name", ""))
        assert_false(names.has(name), "duplicate manifest name " + name)
        names[name] = true
        var rel := String(row.get("file", ""))
        var p := Icons.DIR + rel
        by_file[p] = row
        assert_true(FileAccess.file_exists(p), "manifest names a file that is not there: " + p)
        var role := String(row.get("role", ""))
        var w := int(row.get("w", 0))
        var h := int(row.get("h", 0))
        assert_eq(w, Icons.size(role), name + ": width is not its role's cell")
        assert_eq(h, Icons.size(role), name + ": height is not its role's cell")
        if FileAccess.file_exists(p):
            assert_eq(_raw(p).get_size(), Vector2i(w, h), name + ": PNG size vs manifest")
        # the lookup resolves the row to exactly this file
        assert_eq(Icons.path(role, String(row.get("key", ""))), p, name + ": Icons.path disagrees with the manifest")
        # no name in both directories (grid/ would shadow the top level silently) —
        # except the one hand crop the plan leaves in place (report J2): the
        # top-level class_warrior.png is all.json's 15x12 `ui_crop` row, nothing in
        # game/ loads it, and grid/ wins in Icons.path. Pin that it IS the crop
        # (not a cell-sized twin), so a second generated copy would still fail here.
        var other := (Icons.DIR if rel.begins_with("grid/") else Icons.GRID) + name + ".png"
        if SHADOWED_CROPS.has(name):
            assert_eq(other, Icons.DIR + name + ".png", name + ": the shadowed file is the top-level crop")
            if FileAccess.file_exists(other):
                assert_ne(_raw(other).get_size(), Vector2i(w, h), name + ": the top-level file is a cell-sized twin, not the hand crop")
        else:
            assert_false(FileAccess.file_exists(other), name + " exists at both levels: " + other)
    # every PNG under grid/ (recursively) is a manifest row — no orphan can hide one level down
    var grid_pngs := _pngs_under(Icons.GRID)
    assert_true(grid_pngs.size() >= 60, "the grid walk saw only %d PNGs" % grid_pngs.size())
    for p in grid_pngs:
        assert_true(by_file.has(p), "PNG under grid/ with no manifest row: " + p)
    # the manifest says who wrote it, and that generator is on disk
    assert_eq(String(_manifest.get("generator", "")), "tools/aseprite/gen_icons.lua")
    assert_true(FileAccess.file_exists(GEN), GEN + " is gone")


func test_no_grid_pixel_is_pure_black_or_white() -> void:
    var checked := 0
    for p in _pngs_under(Icons.GRID):
        var img := _raw(p)
        for y in img.get_height():
            for x in img.get_width():
                var c := img.get_pixel(x, y)
                if c.a <= 0.0:
                    continue
                var pure_black := c.r < 0.004 and c.g < 0.004 and c.b < 0.004
                var pure_white := c.r > 0.996 and c.g > 0.996 and c.b > 0.996
                assert_false(pure_black or pure_white, "%s has a pure black/white pixel at %d,%d" % [p, x, y])
        checked += 1
    assert_true(checked >= 60, "checked %d files" % checked)


# ---------------------------------------------------------------- the face sheets

func test_face_sheets_exist_at_the_three_text_scales() -> void:
    var sheets: Array = _manifest.get("sheets", [])
    assert_eq(sheets.size(), 3, "faces at 100 / 125 / 150 %")
    for cell: int in [24, 30, 36]:
        var file: String = "faces.png" if cell == 24 else "faces_%d.png" % cell
        var json: String = "faces.json" if cell == 24 else "faces_%d.json" % cell
        var img := _raw("res://game/assets/ui/" + file)
        assert_eq(img.get_size(), Vector2i(cell * 10, cell), file + " is ten cells wide")
        var meta := _json("res://game/assets/ui/" + json)
        assert_eq(meta.get("size", []), [float(cell), float(cell)], json + " size")
        var frames: Array = meta.get("frames", [])
        assert_eq(frames.size(), 10, json + " has ten frames")
        for b in 10:
            var f: Dictionary = frames[b]
            assert_eq(int(f.get("band", -1)), b, json + " band order")
            assert_eq(int(f.get("x", -1)), b * cell, json + " frame x")
            assert_eq(String(f.get("name", "")), String(Enums.MORALE_BAND_NAMES[b]), json + " band name")
        # the sheet's cells are not blank: each has a coloured disc/heart
        for b in 10:
            var opaque := 0
            for y in cell:
                for x in cell:
                    if img.get_pixel(b * cell + x, y).a > 0.5:
                        opaque += 1
            assert_true(opaque > cell * cell / 3, "%s cell %d is mostly empty" % [file, b])


# ---------------------------------------------------------------- the door

func test_a_missing_icon_is_an_error_not_a_silent_null() -> void:
    assert_eq(Icons.path("class", "nope"), "")
    assert_eq(Icons.path("nope", "warrior"), "")
    assert_false(Icons.exists("class", "nope"))
    assert_true(Icons.exists("class", "warrior"))
    # push_error cannot be intercepted from a test; pin that the door says it
    var src: String = FileAccess.get_file_as_string(ICONS_GD)
    assert_true(src.contains("push_error("), "Icons.at must push_error on a missing file")
    assert_true(src.contains("static func at(role: String, key: String) -> Texture2D"), "the door's signature")
    assert_false(src.contains("class_name"), "no class_name (invariant 7/8)")
