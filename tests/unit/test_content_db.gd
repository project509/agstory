extends "res://tests/TestCase.gd"
## sim/content/ContentDB.gd
##
## Three parts. The first loads the REAL content and asserts it is clean — that
## is the regression guard for every data file at once. The second feeds the
## validator deliberately broken content and asserts it complains, because a
## validator nobody has seen fail is just an expensive no-op. The third mounts a
## synthetic second tier and asserts the two do not collide, which is docs/16 §7
## X2.8's precondition: a tier must be authorable without an engineering change.

const DB = preload("res://sim/content/ContentDB.gd")
const E = preload("res://sim/model/Enums.gd")

const TMP_DIR := "user://test_content"

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

# ---------------------------------------------------------------- real content

func test_real_content_loads_without_a_single_error() -> void:
    assert_true(_db.is_valid(), _db.error_report())

func test_the_tutorial_file_is_mounted_and_indexed() -> void:
    # docs/10 §9's two onboarding rungs load through the ordinary encounter
    # path — the same record shape at a smaller party size — so they land in the
    # same "<tier>:<slot>" index and the board needs no special case.
    var tutorials: Array = _db.tutorial_encounters(1)
    assert_eq(tutorials.size(), 2, _db.error_report())
    assert_eq(tutorials[0].slot, "A0", "canon's order is Adventure 0 first")
    assert_eq(tutorials[1].slot, "TR")
    assert_eq(_db.encounter_at(1, "A0"), tutorials[0])
    assert_eq(_db.encounter_at_slot("TR"), tutorials[1])
    assert_eq(_db.tutorial_encounters(2).size(), 0,
        "a tier with no tutorials answers empty rather than borrowing Tier 1's")

func test_tutorials_are_authored_once_for_the_whole_game_not_once_per_tier() -> void:
    # They are in DEFAULT_PATHS beside the tier-0 starting gear, not in
    # `tier_paths`, because docs/10 §9 gives the ladder exactly two tutorials and
    # Tier 2 does not repeat them. If they moved into `tier_paths`, every tier
    # above the first would report a missing file forever.
    var paths: Dictionary = DB.default_paths()
    assert_true(paths.has("tutorials"), "the tutorial file must be mounted")
    assert_true(FileAccess.file_exists(String(paths["tutorials"])))
    for entry in paths["tiers"]:
        assert_false((entry as Dictionary).has("tutorials"),
            "a tier manifest must not carry a tutorial file")

func test_all_nine_classes_indexed_in_canon_order() -> void:
    assert_eq(_db.classes.size(), 9)
    for i in E.CLASS_KEYS.size():
        assert_eq(_db.classes[i].key, E.CLASS_KEYS[i], "class order at %d" % i)
        assert_eq(_db.class_of(i).key, E.CLASS_KEYS[i])
    assert_eq(_db.class_by_key("shaman").base_hp, 75)
    assert_eq(_db.class_by_key("nope"), null)

## Every item file the manifest mounts, in load order.
func _item_files() -> Array:
    var paths: Dictionary = DB.default_paths()
    # Tier 0 is two files, not one: starting gear, and docs/09 §10.2 G12's pair
    # of tutorial trinkets (docs/15 BL-77). Read off the manifest rather than
    # named here, so a third tier-0 file is counted the day it mounts.
    var out: Array = [String(paths["starting"]), String(paths["tutorial_items"])]
    for entry in paths["tiers"]:
        out.append(String(entry["adventure"]))
        out.append(String(entry["raid"]))
    return out


func _declared_items(path: String) -> Array:
    var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    return doc.get("items", [])


func test_every_item_every_mounted_file_declares_is_indexed() -> void:
    # Per-file counts, never one magic total: the day a tier lands the total
    # moves, and re-editing a number here would be the engineering change
    # docs/16 §7 X2.8 forbids. The sum is asserted too, so an item indexed from
    # nowhere is caught as well as one silently dropped by the validator.
    var files: Array = _item_files()
    assert_true(files.size() >= 3, "the manifest should name Tier 1's three item files")
    var total := 0
    for path in files:
        var declared: Array = _declared_items(path)
        assert_true(declared.size() > 0, "%s declares no items" % path)
        var indexed := 0
        for entry in declared:
            if _db.item(String(entry.get("id", ""))) != null:
                indexed += 1
        assert_eq(indexed, declared.size(), "%s: every declared item indexed" % path)
        total += declared.size()
    assert_eq(_db.items.size(), total, "no item indexed from outside a mounted file")
    assert_ne(_db.item("ITM_T0_START_WARBARD_HEAD"), null)
    assert_ne(_db.item("ITM_T1_ADV_WARBARD_CHEST"), null)
    assert_ne(_db.item("ITM_T1_RAID_SHIELD_OH"), null)
    assert_eq(_db.item("ITM_NOPE"), null)

func test_each_tier_carries_the_canon_adventure_item_count() -> void:
    # docs/10 §12.2: 28 Adventure item records per tier, ✅ CANON for Tier 1 and
    # held constant per tier. Loops the manifest, so a new tier is checked too.
    for entry in DB.default_paths()["tiers"]:
        assert_eq(_declared_items(String(entry["adventure"])).size(), 28,
            "tier %d Adventure item count" % int(entry["tier"]))

func test_tier_and_source_normalised_from_the_file() -> void:
    assert_eq(_db.item("ITM_T0_START_WARBARD_HEAD").tier, 0)
    assert_eq(_db.item("ITM_T0_START_WARBARD_HEAD").source, "start")
    assert_eq(_db.item("ITM_T1_ADV_WARBARD_CHEST").tier, 1)
    assert_eq(_db.item("ITM_T1_ADV_WARBARD_CHEST").source, "adventure")
    assert_eq(_db.item("ITM_T1_RAID_SHIELD_OH").source, "raid")

func test_drop_encounter_normalised_from_boss_field() -> void:
    assert_eq(_db.item("ITM_T1_RAID_SHIELD_OH").drop_encounter, 5)
    assert_eq(_db.item("ITM_T1_RAID_WARBARD_FEET").drop_encounter, 1)
    assert_eq(_db.item("ITM_T0_START_WARBARD_HEAD").drop_encounter, -1,
        "starting gear does not drop from an encounter")

func test_eligibility_is_derived_not_stored() -> void:
    var helm = _db.item("ITM_T1_RAID_WARBARD_HEAD")
    assert_true(helm.can_be_used_by(E.CharClass.WARRIOR))
    assert_true(helm.can_be_used_by(E.CharClass.BARD))
    assert_false(helm.can_be_used_by(E.CharClass.MAGE))
    var trinket = _db.item("ITM_T1_RAID_UNIV_TRINKET_MANA")
    assert_eq(trinket.demand(), 9, "trinkets are the nine-way contention family")
    assert_eq(trinket.eligible_classes().size(), 9)

func test_starting_sets_resolved_to_items() -> void:
    for key in E.CLASS_KEYS:
        var set_items: Array = _db.starting_set(key)
        assert_eq(set_items.size(), 4, "%s starting set" % key)
    var warrior_ac := 0
    for it in _db.starting_set("warrior"):
        warrior_ac += it.stats.ac
    assert_eq(warrior_ac, 7, "canon Warrior starting AC")

func test_raid_tables_resolved_by_encounter() -> void:
    for key in E.CLASS_KEYS:
        for boss in range(1, 6):
            assert_true(_db.raid_drops(key, boss).size() > 0,
                "%s receives nothing at encounter %d" % [key, boss])
    var b5: Array = _db.raid_drops("warrior", 5)
    assert_eq(b5.size(), 1)
    assert_eq(b5[0].id, "ITM_T1_RAID_SHIELD_OH")

func test_trinket_pool_loaded() -> void:
    assert_eq(_db.trinket_pool.size(), 4)
    for it in _db.trinket_pool:
        assert_eq(it.family, E.ItemFamily.UNIVERSAL_TRINKET)

func test_items_for_class_slot() -> void:
    # A Warrior's head options across every loaded tier: starting, adventure, raid.
    var heads: Array = _db.items_for_class_slot(E.CharClass.WARRIOR, E.Slot.HEAD)
    assert_eq(heads.size(), 3, "Worn Iron Cap, Iron Adventurer's Helm, Raider's Helm")
    # A Mage has no off-hand at all.
    assert_eq(_db.items_for_class_slot(E.CharClass.MAGE, E.Slot.OFF_HAND).size(), 0)

func test_best_in_slot_stats_matches_canon_totals() -> void:
    # Warrior BiS across the raid tier, armor + shield.
    var w = _db.best_in_slot_stats("warrior")
    assert_eq(w.ac, 28, "21 armor + 7 shield")
    assert_eq(w.hp, 32)
    # Best-in-slot spans every slot, not just armour: 27 Mana of armour,
    # +5 from the Boss 2 Tome, +19 from the Boss 5 Cleric Weapon.
    var c = _db.best_in_slot_stats("cleric")
    assert_eq(c.mana, 27 + 5 + 19, "cleric full best-in-slot Mana")

func test_class_def_helpers() -> void:
    var mage = _db.class_by_key("mage")
    assert_false(mage.has_off_hand(), "Mage is two-handed")
    assert_eq(mage.available_slots().size(), 6, "all seven slots minus off-hand")
    assert_true(_db.class_by_key("cleric").is_healer())
    assert_true(_db.class_by_key("warrior").is_tank())
    assert_eq(_db.class_by_key("warrior").role_name(), "Main Tank")
    var rogue = _db.class_by_key("rogue")
    assert_eq(rogue.family_for_slot(E.Slot.OFF_HAND), rogue.family_for_slot(E.Slot.MAIN_HAND),
        "Rogue dual-wields one family")

func test_rarity_multipliers_load_neutral() -> void:
    for r in E.all_rarities():
        assert_almost(_db.hp_multiplier_for(r), 1.0, 0.0001)

# ---------------------------------------------------------------- the validator

func _write(name: String, data: Dictionary) -> String:
    DirAccess.make_dir_recursive_absolute(TMP_DIR)
    var path := "%s/%s" % [TMP_DIR, name]
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(data))
    f.close()
    return path

## Load real content but with one file swapped for a broken one. A key that
## names a per-tier file lands in Tier 1's manifest entry, and the manifest is
## trimmed to that one tier so these fixtures stay pointed at the rung they
## were written for however many tiers later ship.
func _load_with(overrides: Dictionary):
    var paths: Dictionary = DB.default_paths()
    var tier1: Dictionary = (paths["tiers"][0] as Dictionary).duplicate()
    for k in overrides.keys():
        if tier1.has(k):
            tier1[k] = overrides[k]
        else:
            paths[k] = overrides[k]
    paths["tiers"] = [tier1]
    return DB.load_all(paths)

func _has_error_containing(db, needle: String) -> bool:
    for e in db.errors:
        if e.contains(needle):
            return true
    return false

func test_missing_file_is_reported_not_crashed() -> void:
    var db = _load_with({"classes": "res://data/does_not_exist.json"})
    assert_false(db.is_valid())
    assert_true(_has_error_containing(db, "file not found"), db.error_report())

func test_malformed_json_is_reported() -> void:
    DirAccess.make_dir_recursive_absolute(TMP_DIR)
    var path := "%s/bad.json" % TMP_DIR
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string("{ this is not json ")
    f.close()
    var db = _load_with({"classes": path})
    assert_false(db.is_valid())
    assert_true(_has_error_containing(db, "not valid JSON"), db.error_report())

func test_unknown_class_key_reported() -> void:
    var path := _write("cls_badkey.json", {
        "classes": [{"key": "paladin", "name": "Paladin", "role": "main_tank",
            "role_group": "tank", "base_hp": 100, "primary_stat": "ac",
            "secondary_stats": [], "families": {}, "two_handed": false, "dual_wield": false}],
        "rarity_hp_multiplier": {"common": 1.0, "uncommon": 1.0, "rare": 1.0,
            "epic": 1.0, "legendary": 1.0},
    })
    var db = _load_with({"classes": path})
    assert_true(_has_error_containing(db, "unknown class key 'paladin'"), db.error_report())

func test_role_group_mismatch_reported() -> void:
    var cls = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
    cls["classes"][0]["role_group"] = "healer"   # Warrior is a tank
    var path := _write("cls_mismatch.json", cls)
    var db = _load_with({"classes": path})
    assert_true(_has_error_containing(db, "does not belong to group"), db.error_report())

func test_family_that_does_not_claim_the_class_reported() -> void:
    var cls = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
    cls["classes"][0]["families"]["body"] = "healer_armor"   # Warrior cannot wear this
    var path := _write("cls_badfam.json", cls)
    var db = _load_with({"classes": path})
    assert_true(_has_error_containing(db, "does not claim this class"), db.error_report())

func test_two_handed_class_with_offhand_reported() -> void:
    var cls = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
    for c in cls["classes"]:
        if c["key"] == "mage":
            c["families"]["off_hand"] = "healer_off_hand"
    var path := _write("cls_2h_oh.json", cls)
    var db = _load_with({"classes": path})
    assert_true(_has_error_containing(db, "must have a null off_hand"), db.error_report())

func test_duplicate_item_id_reported() -> void:
    var adv = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_t1_adventure.json"))
    adv["items"].append(adv["items"][0].duplicate(true))
    var path := _write("adv_dupe.json", adv)
    var db = _load_with({"adventure": path})
    assert_true(_has_error_containing(db, "duplicate item id"), db.error_report())

func test_unknown_stat_key_reported() -> void:
    var adv = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_t1_adventure.json"))
    adv["items"][0]["stats"] = {"armour": 3}
    var path := _write("adv_badstat.json", adv)
    var db = _load_with({"adventure": path})
    assert_true(_has_error_containing(db, "unknown stat key"), db.error_report())

func test_non_canon_item_without_a_note_reported() -> void:
    var adv = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_t1_adventure.json"))
    adv["items"][0]["canon"] = false
    adv["items"][0].erase("note")
    var path := _write("adv_nonote.json", adv)
    var db = _load_with({"adventure": path})
    assert_true(_has_error_containing(db, "must cite their derivation"), db.error_report())

func test_starting_set_pointing_at_a_missing_item_reported() -> void:
    var st = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_starting.json"))
    st["starting_sets"]["warrior"][0] = "ITM_T0_START_DOES_NOT_EXIST"
    var path := _write("start_missing.json", st)
    var db = _load_with({"starting": path})
    assert_true(_has_error_containing(db, "unknown item"), db.error_report())

func test_raid_table_handing_a_class_gear_it_cannot_wear_reported() -> void:
    var raid = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_t1_raid.json"))
    raid["class_tables"]["mage"]["3"] = ["ITM_T1_RAID_WARBARD_HEAD"]
    var path := _write("raid_badgear.json", raid)
    var db = _load_with({"raid": path})
    assert_true(_has_error_containing(db, "cannot equip"), db.error_report())

func test_encounter_with_no_drops_reported() -> void:
    var raid = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_t1_raid.json"))
    raid["class_tables"]["mage"]["3"] = []
    var path := _write("raid_empty.json", raid)
    var db = _load_with({"raid": path})
    assert_true(_has_error_containing(db, "nothing drops at encounter 3"), db.error_report())

func test_errors_accumulate_rather_than_stopping_at_the_first() -> void:
    # One bad item must not hide the next. The report should carry both.
    var adv = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_t1_adventure.json"))
    adv["items"][0]["stats"] = {"armour": 3}
    adv["items"][1]["slot"] = "cloak"
    var path := _write("adv_two_faults.json", adv)
    var db = _load_with({"adventure": path})
    assert_true(db.errors.size() >= 2, "expected at least two errors, got: %s" % db.error_report())
    assert_true(_has_error_containing(db, "unknown stat key"))
    assert_true(_has_error_containing(db, "unknown slot"))

func test_error_report_is_readable() -> void:
    assert_true(_db.error_report().begins_with("content OK"))
    var db = _load_with({"classes": "res://data/nope.json"})
    assert_true(db.error_report().contains("content FAILED"))

# ---------------------------------------------------------------- two tiers

## How much every synthetic Tier 2 stat is raised. One point is enough to make
## "Tier 2 is strictly better" checkable without pretending to be a balance
## curve — the real per-tier scaling is a later, doc-derived item.
const T2_STAT_BUMP := 1

## Derive a Tier 2 file from a Tier 1 one: ids remapped, header retiered, every
## stat a point higher. Ids carry their tier by convention (docs/09 §12.1), so
## one text substitution retiers the records AND the cross-references that
## point at them — the class tables and trinket pool follow for free.
##
## This is deliberately NOT canon Tier 2 content and never touches data/. It
## exists to prove the loader can hold two tiers at once.
func _retiered_to_two(path: String) -> Dictionary:
    var raw := FileAccess.get_file_as_string(path)
    raw = raw.replace("ITM_T1_", "ITM_T2_").replace("t1_", "t2_")
    var doc: Dictionary = JSON.parse_string(raw)
    doc["tier"] = 2
    for entry in doc.get("items", []):
        entry["tier"] = 2
        var stats: Dictionary = entry.get("stats", {})
        for key in stats.keys():
            stats[key] = int(stats[key]) + T2_STAT_BUMP
    for entry in doc.get("encounters", []):
        entry["tier"] = 2
    return doc


## Tier 1 as shipped plus the synthetic Tier 2, mounted through the manifest.
## Tier 1 plus the REAL Tier 2, loaded by name.
##
## This used to mount a COPY of Tier 1 re-stamped as tier 2, because tier 2 did
## not exist. It does now, and the copy stopped being usable the moment the tier
## rules landed: a tier identical to the one below it fails the ladder check at
## every slot, correctly. Loading the real files is also the better test — it is
## the two-tier case the game will actually be in.
##
## `tier_paths(2)` rather than `default_paths()`: docs/15 BL-69 keeps a tier
## whose words are pending out of the DEFAULT set, and this test is about the
## index, not about what ships.
func _two_tier_db():
    var paths: Dictionary = DB.default_paths()
    var t1: Dictionary = paths["tiers"][0]
    paths["tiers"] = [t1, DB.tier_paths(2)]
    return DB.load_all(paths)

func test_two_tiers_load_side_by_side() -> void:
    var db = _two_tier_db()
    assert_true(db.is_valid(), db.error_report())
    assert_eq(db.tiers.size(), 2)
    assert_eq(db.tiers[1], 2)
    # The regression this whole item exists for: before the index carried the
    # tier, mounting Tier 2 emptied Tier 1's board instead of extending it.
    assert_eq(db.adventure_encounters(1).size(), 3, "Tier 1 Adventure rungs survive Tier 2")
    assert_eq(db.adventure_encounters(2).size(), 3)
    assert_eq(db.raid_encounters(1).size(), 5, "Tier 1 Raid rungs survive Tier 2")
    assert_eq(db.raid_encounters(2).size(), 5)
    assert_eq(db.items.size(), _db.items.size() + 76, "28 Adventure + 48 Raid items arrive")
    # And the ladder rule the real files have to satisfy to be mounted at all.
    assert_eq(DB.tier_rule_problems({1: db.raid_encounters(1), 2: db.raid_encounters(2)}).size(),
        0, "the real Tier 2 must beat Tier 1 slot by slot")

func test_the_encounter_index_is_keyed_by_tier_and_slot() -> void:
    var db = _two_tier_db()
    assert_eq(db.encounter_at(1, "E1").id, "t1_raid_e1")
    assert_eq(db.encounter_at(2, "E1").id, "t2_raid_e1")
    assert_eq(db.encounter_at(2, "E1").tier, 2)
    assert_eq(db.encounter_at(2, "A3").id, "t2_adv_a3")
    assert_eq(db.encounter_at(3, "E1"), null, "an unauthored tier resolves to nothing")
    # The shim the rest of the tree calls still means Tier 1, deliberately.
    assert_eq(db.encounter_at_slot("E1").id, "t1_raid_e1")
    assert_eq(db.encounter_at_slot("E5"), db.encounter_at(1, "E5"))

func test_raid_tables_and_best_in_slot_are_tier_scoped() -> void:
    var db = _two_tier_db()
    assert_eq(db.raid_drops("warrior", 5)[0].id, "ITM_T1_RAID_SHIELD_OH",
        "the tier defaults to 1 for every caller that predates tiers")
    assert_eq(db.raid_drops("warrior", 5, 2)[0].id, "ITM_T2_RAID_SHIELD_OH")
    assert_eq(db.raid_drops("warrior", 5, 3), [], "an unauthored tier drops nothing")
    var t1_ac: int = db.best_in_slot_stats("warrior", 1).ac
    var t2_ac: int = db.best_in_slot_stats("warrior", 2).ac
    assert_eq(t1_ac, 28, "Tier 1 best-in-slot is unmoved by Tier 2 loading")
    assert_true(t2_ac > t1_ac, "Tier 2 BiS %d should beat Tier 1's %d" % [t2_ac, t1_ac])

func test_trinket_pools_are_per_tier() -> void:
    var db = _two_tier_db()
    assert_eq(db.trinkets(1).size(), 4)
    assert_eq(db.trinkets(2).size(), 4)
    assert_eq(db.trinkets(1)[0].tier, 1)
    assert_eq(db.trinkets(2)[0].tier, 2)
    assert_eq(db.trinket_pool.size(), 4, "the bare pool stays Tier 1's, for its callers")

func test_the_default_manifest_finds_tiers_on_disk_not_in_code() -> void:
    # X2.8 in one assertion: nothing in ContentDB.gd names a tier. Tier N is
    # four filenames, and a tier is mounted because its files exist.
    var paths: Dictionary = DB.default_paths()
    var found: Array = paths["tiers"]
    assert_true(found.size() >= 1, "Tier 1 must be discovered")
    assert_eq(int(found[0]["tier"]), 1)
    assert_eq(found.size(), _db.tiers.size())
    for entry in found:
        for key in ["adventure", "raid", "encounters", "adventures"]:
            assert_true(FileAccess.file_exists(String(entry[key])),
                "mounted but missing: %s" % entry[key])
    assert_eq(DB.tier_paths(4)["encounters"], "res://data/encounters_t4.json")
    assert_eq(DB.tier_paths(4)["raid"], "res://data/items_t4_raid.json")

func test_a_file_mounted_at_the_wrong_tier_is_reported() -> void:
    # Tier 1's files mounted as Tier 2. A silent mount would file Raid 1 under
    # Raid 2 and drag doc 03 §6.2's obsolescence factor with it.
    var paths: Dictionary = DB.default_paths()
    var wrong: Dictionary = (paths["tiers"][0] as Dictionary).duplicate()
    wrong["tier"] = 2
    paths["tiers"] = [wrong]
    var db = DB.load_all(paths)
    assert_false(db.is_valid())
    assert_true(_has_error_containing(db, "is loaded as tier 2"), db.error_report())

func test_two_encounters_claiming_one_rung_are_reported() -> void:
    var doc: Dictionary = JSON.parse_string(
        FileAccess.get_file_as_string("res://data/encounters_t1.json"))
    var clone: Dictionary = doc["encounters"][0].duplicate(true)
    clone["id"] = "t1_raid_e1_again"
    doc["encounters"].append(clone)
    var path := _write("enc_two_e1.json", doc)
    var db = _load_with({"encounters": path})
    assert_true(_has_error_containing(db, "both claim tier 1 slot 'E1'"), db.error_report())
    assert_eq(db.encounter_at(1, "E1").id, "t1_raid_e1", "the first record keeps the rung")


# --------------------------------------------- the tier's arena (CONTENT-26, Q-96)

func test_a_tiers_named_scene_is_a_bare_name_whose_file_is_on_disk() -> void:
    # CONTENT-26's contract / docs/15 Q-96: `tier_words.json` may name the
    # plate a tier's fights are shown on, per kind. `ContentDB.tier_scene` is
    # the one reader; it answers a BARE name (the content layer knows nothing
    # of where the art lives), and every name tier 1 gives has its JSON on
    # disk — a tier that names a plate the build does not ship would send
    # `SceneStage.arena_for` at a file that is not there.
    for kind in ["adventure", "raid"]:
        var named := DB.tier_scene(1, String(kind))
        assert_ne(named, "", "tier 1 names a plate for a %s" % kind)
        assert_false(named.contains("/") or named.contains(":"),
            "a scene key is a name, never a path (%s)" % named)
        assert_true(FileAccess.file_exists("res://game/assets/scenes/%s.json" % named),
            "tier 1's %s plate %s.json is on disk" % [kind, named])
    assert_eq(DB.tier_scene(1, "raid"), "stage_arena_dungeon", "raids are underground")
    assert_eq(DB.tier_scene(1, "adventure"), "stage_arena_cave", "adventures are in the cave")
    # A pending tier names nothing and inherits the kind rule; so does a tier
    # that does not exist and a kind nobody authored.
    assert_eq(DB.tier_scene(2, "raid"), "", "tier 2 is pending and names no plate")
    assert_eq(DB.tier_scene(99, "raid"), "", "a tier with no row names no plate")
    assert_eq(DB.tier_scene(1, "picnic"), "", "an unauthored kind names no plate")
