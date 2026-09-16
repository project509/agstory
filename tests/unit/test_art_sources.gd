extends "res://tests/TestCase.gd"
## Every PNG the game ships under game/assets/{ui/icons,enemies,portraits} has a source it can
## be regenerated from (PIPE-13 tier 1, PIPE-17; docs/12 §7.1: "If a PNG is the only copy of
## something, that thing does not exist").
##
## Three kinds of source count, and each one is a table this file can read:
##   1. a generator's emit list — the names each script writes, transcribed below and cited by
##      file (tools/aseprite/gen_items.lua, gen_icons.lua, tools/art/derive_busts.py);
##   2. a `ui_crop` row in art/ref/manifests/all.json (concept file + x,y,w,h, plus `ships`, the
##      game path) — `tools/art/slice.py cut` re-cuts it byte-identically, and this file proves
##      the pixels from the sheet itself, unless the row says `reproducible: false` and why;
##   3. a rank in game/assets/enemies/enemies.json — tools/art/place_enemies.py copies the named
##      export over the rank name, and the shipped bytes must equal the export's.
## The lists are explicit on purpose: a PNG no table names fails here BY NAME, which is the
## moment to record where it came from, not later when a palette move cannot reach it.

const MANIFEST := "res://art/ref/manifests/all.json"
const ENEMIES_JSON := "res://game/assets/enemies/enemies.json"
const PLACE_SCRIPT := "res://tools/art/place_enemies.py"
const WALK := ["res://game/assets/ui/icons", "res://game/assets/ui/icons/grid", "res://game/assets/enemies", "res://game/assets/enemies/anim", "res://game/assets/portraits"]

## tools/art/gen_icons.lua — W0-LIB moves it to tools/aseprite/ in the same wave, so either path
## satisfies the existence check. Emit list: gen_icons.lua `emit(spr, ...)` calls.
const GEN_ICONS_PATHS := ["res://tools/aseprite/gen_icons.lua", "res://tools/art/gen_icons.lua"]
## W1-ICONS: the generator writes its own emit list (name, role, key, file, cell) and verify.sh
## stage 2b byte-gates it, so the grid is read from there rather than transcribed by hand.
const GEN_ICONS_MANIFEST := "res://game/assets/ui/icons/grid/icons.json"
const GEN_ICONS := [
    "face_0", "face_1", "face_2", "face_3", "face_4", "face_5", "face_6", "face_7", "face_8", "face_9",
    "slot_main_hand", "slot_off_hand", "slot_head", "slot_chest", "slot_legs", "slot_feet", "slot_trinket",
    "item_minor_healing_potion", "item_potion_of_steady_hands", "item_rally_flask", "item_unknown",
    "rank_unknown", "rank_known", "rank_respected", "rank_established", "rank_renowned", "rank_legendary",
    "arrow_left", "arrow_right", "fast_forward_24", "cog_24",
]
## tools/aseprite/gen_items.lua — `item_<slot>_<material>` for every entry of its `shapes` table.
const GEN_ITEMS_PATH := "res://tools/aseprite/gen_items.lua"
const GEN_ITEMS := [
    "item_head_iron", "item_head_leather", "item_head_cloth", "item_head_eyepatch", "item_head_headband",
    "item_chest_cloth", "item_chest_leather",
    "item_legs_cloth", "item_legs_iron", "item_legs_leather",
    "item_feet_cloth", "item_feet_iron", "item_feet_leather",
    "item_off_hand_cloth", "item_off_hand_instr", "item_off_hand_iron", "item_off_hand_leather",
    "item_weapon_dagger", "item_weapon_mace", "item_weapon_staff_arc", "item_weapon_staff_druid",
    "item_weapon_staff_fire", "item_weapon_staff_wood", "item_weapon_totem",
    "item_trinket_armor", "item_trinket_health", "item_trinket_mana", "item_trinket_power",
]
## tools/art/derive_busts.py — `save(a, key)` writes game/assets/portraits/class_<key>.png.
const DERIVE_BUSTS_PATH := "res://tools/art/derive_busts.py"
const DERIVE_BUSTS := ["class_monk", "class_druid", "class_bard", "class_wizard", "class_shaman"]

## The plan's rank -> export table (00-plan.md §W0-MANIFEST); enemies.json must say the same.
const RANKS := {
    "boss_main": "sludge_maw_leviathan",
    "boss_main_2": "void_colossus_core",
    "boss_mini": "boss_spiked_crawler",
    "boss_mini_2": "boss_stone_brute",
    "boss_elite": "boss_flame_brute",
    "boss_trash": "void_tentacle_a",
}


# ---------------------------------------------------------------- helpers

func _json(path: String) -> Dictionary:
    var text: String = FileAccess.get_file_as_string(path)
    assert_true(text.length() > 0, "%s could not be read" % path)
    var parsed = JSON.parse_string(text)
    assert_true(parsed is Dictionary, "%s did not parse as an object" % path)
    return parsed if parsed is Dictionary else {}


func _pngs(dir: String) -> Array[String]:
    var out: Array[String] = []
    for f in DirAccess.get_files_at(dir):
        var name := String(f)
        if name.ends_with(".png"):
            out.append(dir.path_join(name))
    out.sort()
    return out


func _ui_crop_rows() -> Array:
    var rows: Array = []
    for e in _json(MANIFEST).get("entries", []):
        if e is Dictionary and String(e.get("category", "")) == "ui_crop":
            rows.append(e)
    return rows


## Reads the PNG file itself, never the imported texture: the importer's
## `process/fix_alpha_border` rewrites transparent pixels, and the concept sheets under
## ideaboard/ sit behind a .gdignore that stops the importer, not FileAccess.
func _raw(path: String) -> Image:
    var img := Image.load_from_file(ProjectSettings.globalize_path(path))
    assert_true(img != null and not img.is_empty(), "%s did not decode" % path)
    return img


func _first_existing(paths: Array) -> String:
    for p in paths:
        if FileAccess.file_exists(String(p)):
            return String(p)
    return ""


# ---------------------------------------------------------------- the walk

func test_every_shipped_png_names_its_source() -> void:
    assert_true(_first_existing(GEN_ICONS_PATHS) != "", "gen_icons.lua is at neither path")
    assert_true(FileAccess.file_exists(GEN_ITEMS_PATH), GEN_ITEMS_PATH + " is gone")
    assert_true(FileAccess.file_exists(DERIVE_BUSTS_PATH), DERIVE_BUSTS_PATH + " is gone")

    var crops := {}
    for row in _ui_crop_rows():
        crops["res://" + String(row.get("ships", ""))] = row
    var ranks: Dictionary = _json(ENEMIES_JSON).get("ranks", {})
    var emitted := {}
    for row in _json(GEN_ICONS_MANIFEST).get("files", []):
        emitted[String(row.get("name", ""))] = true
    assert_true(emitted.has("class_warrior") and emitted.has("rank_unknown"), "gen_icons' manifest is empty")

    var seen: Array[String] = []
    var orphans: Array[String] = []
    for dir_v in WALK:
        var dir := String(dir_v)
        assert_true(DirAccess.dir_exists_absolute(dir), dir + " is missing")
        for path in _pngs(dir):
            seen.append(path)
            var base := path.get_file().get_basename()
            var sourced := false
            if dir.ends_with("icons") or dir.ends_with("grid"):
                sourced = base in GEN_ICONS or base in GEN_ITEMS or emitted.has(base)
            elif dir.ends_with("portraits"):
                sourced = base in DERIVE_BUSTS
            elif dir.ends_with("enemies/anim"):
                # W3-ENEMIES: a strip is sourced when a rank's row names it (gen_boss_anims.lua).
                for rank_key in ranks:
                    var rr: Dictionary = ranks[rank_key]
                    if path.ends_with("/" + String(rr.get("strip", "-"))) or path.ends_with("/" + String(rr.get("glow", "-"))):
                        sourced = true
            elif dir.ends_with("enemies"):
                sourced = ranks.has(base)
            if not sourced and crops.has(path):
                sourced = true
            if not sourced:
                orphans.append(path)
    # The walk is only proof if it actually saw the tree (LESSONS: anchor on something real).
    assert_true("res://game/assets/ui/icons/rank_unknown.png" in seen, "the icons walk saw nothing")
    assert_true("res://game/assets/ui/icons/grid/class_warrior.png" in seen, "the grid walk saw nothing")
    assert_true("res://game/assets/enemies/boss_main.png" in seen, "the enemies walk saw nothing")
    assert_true("res://game/assets/portraits/bork.png" in seen, "the portraits walk saw nothing")
    assert_eq(orphans.size(), 0, "PNGs with no generator, manifest rect or enemies.json rank: %s" % [orphans])


# ---------------------------------------------------------------- ui_crop rows

func test_ui_crop_rows_are_well_formed() -> void:
    var rows := _ui_crop_rows()
    # 57 rows from W0-MANIFEST, less the seven badge_N event-log crops W5-TOOLS retires
    # (handoff-W5-TOOLS §1 removes their rows and files together; the floor is set so
    # the walk is proven either side of that landing, not to a count that can only go stale).
    assert_true(rows.size() >= 50, "expected at least the 50 rows W0-MANIFEST wrote less the badges, got %d" % rows.size())
    var names := {}
    var sheet_sizes := {}
    for row in rows:
        var name := String(row.get("proposed_name", ""))
        assert_false(names.has(name), "duplicate ui_crop row " + name)
        names[name] = true
        var ships := String(row.get("ships", ""))
        assert_true(ships != "", name + " has no `ships` path")
        assert_true(FileAccess.file_exists("res://" + ships), name + " ships a file that is not there: " + ships)
        assert_eq(ships.get_file().get_basename(), name, "row name and shipped basename disagree")
        var sheet := "res://" + String(row.get("sheet", ""))
        assert_true(FileAccess.file_exists(sheet), name + " names a sheet that is not there: " + sheet)
        if not sheet_sizes.has(sheet):
            sheet_sizes[sheet] = _raw(sheet).get_size()
        var size: Vector2i = sheet_sizes[sheet]
        var x := int(row.get("x", -1))
        var y := int(row.get("y", -1))
        var w := int(row.get("w", 0))
        var h := int(row.get("h", 0))
        assert_true(x >= 0 and y >= 0 and w > 0 and h > 0, name + " rect is not positive")
        assert_true(x + w <= size.x and y + h <= size.y, name + " rect leaves its sheet")
        if not bool(row.get("reproducible", true)):
            assert_true(String(row.get("note", "")).length() > 20,
                name + " is marked not reproducible and does not say why")


## The acceptance line: the concept file + rect IS the shipped PNG. Compared from the sheet
## itself (what slice.py cut reads), so a rect that drifts by one pixel fails here.
func test_reproducible_ui_crop_rows_are_the_shipped_pixels() -> void:
    var sheets := {}
    var checked := 0
    for row in _ui_crop_rows():
        if not bool(row.get("reproducible", true)):
            continue
        var name := String(row.get("proposed_name", ""))
        assert_false(row.has("key"), name + " is a pure crop and must not carry a key")
        var sheet := "res://" + String(row.get("sheet", ""))
        if not sheets.has(sheet):
            sheets[sheet] = _raw(sheet)
        var src: Image = sheets[sheet]
        var rect := Rect2i(int(row.get("x", 0)), int(row.get("y", 0)), int(row.get("w", 0)), int(row.get("h", 0)))
        var cut := src.get_region(rect)
        cut.convert(Image.FORMAT_RGBA8)
        var shipped := _raw("res://" + String(row.get("ships", "")))
        shipped.convert(Image.FORMAT_RGBA8)
        assert_eq(shipped.get_size(), rect.size, name + " shipped size != manifest rect")
        assert_true(cut.get_data() == shipped.get_data(), name + " re-cut from its sheet differs from the shipped PNG")
        checked += 1
    # 45 reproducible rows at W0-MANIFEST, 38 once the seven badge_N rows go (handoff-W5-TOOLS §1).
    assert_true(checked >= 38, "only %d reproducible rows were compared" % checked)


## The twelve mechanic icons are resamples of a VFX island (commit a65cf70), which slice.py
## cannot reproduce; their rows exist for provenance and say so. W1-ICONS regenerates them.
func test_mech_icons_are_recorded_as_not_reproducible() -> void:
    var mech := 0
    for row in _ui_crop_rows():
        var name := String(row.get("proposed_name", ""))
        if not name.begins_with("mech_"):
            continue
        mech += 1
        assert_false(bool(row.get("reproducible", true)), name + " claims to be a pure crop")
        assert_true(String(row.get("note", "")).contains("W1-ICONS"), name + " does not name who regenerates it")
    assert_eq(mech, 12, "twelve mech_<key> rows")


# ---------------------------------------------------------------- enemies.json

func test_enemies_json_maps_each_rank_to_a_byte_identical_export() -> void:
    var table := _json(ENEMIES_JSON)
    var ranks: Dictionary = table.get("ranks", {})
    assert_eq(ranks.keys().size(), RANKS.size(), "six ranks")
    var boss_rows := {}
    for e in _json(MANIFEST).get("entries", []):
        if e is Dictionary and String(e.get("category", "")) == "boss":
            boss_rows[String(e.get("proposed_name", ""))] = e
    for rank_key in RANKS.keys():
        var rank := String(rank_key)
        assert_true(ranks.has(rank), "enemies.json has no rank " + rank)
        if not ranks.has(rank):
            continue
        var row: Dictionary = ranks[rank]
        var export := String(row.get("export", ""))
        assert_eq(export, String(RANKS[rank]), rank + " maps to the wrong export")
        assert_true(boss_rows.has(export), export + " has no boss row in all.json (the sheet rect)")
        var src := "res://" + String(table.get("export_dir", "")) + "/" + export + ".png"
        var dst := "res://" + String(table.get("target_dir", "")) + "/" + rank + ".png"
        assert_true(FileAccess.file_exists(src), src + " is missing")
        assert_true(FileAccess.file_exists(dst), dst + " is missing")
        var a: PackedByteArray = FileAccess.get_file_as_bytes(src)
        var b: PackedByteArray = FileAccess.get_file_as_bytes(dst)
        assert_true(a.size() > 0 and a == b, rank + ".png is not a byte copy of " + export + ".png")
        # The slots W3-ENEMIES fills, each with a typed default so a reader never meets null.
        assert_true(row.has("frame_w") and row["frame_w"] is float, rank + " frame_w slot")
        assert_true(row.has("fps") and row["fps"] is float, rank + " fps slot")
        assert_true(row.has("scale") and row["scale"] is float and float(row["scale"]) > 0.0, rank + " scale slot")
        assert_true(row.has("anchor") and row["anchor"] is Array and (row["anchor"] as Array).size() == 2, rank + " anchor slot")
        assert_true(row.has("tags") and row["tags"] is Dictionary, rank + " tags slot")


## "Built" and "armed" are different states (LESSONS): the table is only data if the hand that
## copies it exists and reads it.
func test_the_placing_script_reads_the_table() -> void:
    assert_true(FileAccess.file_exists(PLACE_SCRIPT), PLACE_SCRIPT + " is missing")
    var src: String = FileAccess.get_file_as_string(PLACE_SCRIPT)
    assert_true(src.contains("enemies.json"), "place_enemies.py does not read enemies.json")
    assert_true(src.contains("--check"), "place_enemies.py has no --check mode")
    assert_true(src.contains("filecmp"), "place_enemies.py does not compare bytes")
