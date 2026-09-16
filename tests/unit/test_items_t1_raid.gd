extends "res://tests/TestCase.gd"
## data/items_t1_raid.json — the Tier 1 Raid loot tables, all nine classes.
##
## This is the largest canon transcription in the project (48 items), and the
## one most likely to be silently corrupted, because canon reuses display names
## across genuinely different items: three "Basic Raid Staff" at 10/11/12
## damage, three "Raider's Leggings" at different AC, two identical "Raider's
## Boots" in different families. Ids are identity here; names are not.

const E = preload("res://sim/model/Enums.gd")
const S = preload("res://sim/model/Stats.gd")

const PATH := "res://data/items_t1_raid.json"
const ADV_PATH := "res://data/items_t1_adventure.json"
const CLASSES_PATH := "res://data/classes.json"

var _data: Dictionary = {}
var _items: Array = []
var _by_id: Dictionary = {}
var _tables: Dictionary = {}
var _classes: Array = []

func before_each() -> void:
    if not _items.is_empty():
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    var cparsed = JSON.parse_string(FileAccess.get_file_as_string(CLASSES_PATH))
    if parsed == null or cparsed == null:
        fail("could not parse content")
        return
    _data = parsed
    _items = _data.get("items", [])
    _tables = _data.get("class_tables", {})
    _classes = cparsed.get("classes", [])
    for it in _items:
        _by_id[it["id"]] = it

func _st(id: String):
    var errors := []
    var s = S.from_dict(_by_id[id].get("stats", {}), errors, id)
    if errors.size() > 0:
        fail("%s: %s" % [id, str(errors)])
    return s

## Everything a class receives across Boss 1-5, flattened.
func _all_drops(class_key: String) -> Array:
    var out := []
    var t: Dictionary = _tables[class_key]
    for b in ["1", "2", "3", "4", "5"]:
        for id in t.get(b, []):
            out.append(id)
    return out

## Armor a class ends the tier wearing, one item per slot. Where canon gives two
## items for one slot (Monk and Rogue heads), the later boss wins.
func _best_armor(class_key: String) -> Dictionary:
    var best := {}
    var t: Dictionary = _tables[class_key]
    for b in ["1", "2", "3", "4", "5"]:
        for id in t.get(b, []):
            var it: Dictionary = _by_id[id]
            if it["slot"] in ["head", "chest", "legs", "feet"]:
                best[it["slot"]] = id
    return best

# ---------------------------------------------------------------- structure

func test_parses_with_expected_shape() -> void:
    assert_eq(_data.get("tier", -1), 1)
    assert_eq(_items.size(), 48, "Tier 1 Raid item count")
    assert_eq(_tables.size(), 9, "one loot table per class")

func test_ids_unique_and_well_formed() -> void:
    var re := RegEx.new()
    re.compile("^ITM_T1_RAID_[A-Z0-9]+(_[A-Z0-9]+)*$")
    var seen := {}
    for it in _items:
        assert_false(seen.has(it["id"]), "duplicate id %s" % it["id"])
        seen[it["id"]] = true
        assert_true(re.search(it["id"]) != null, "malformed id %s" % it["id"])

func test_keys_resolve_and_stats_parse() -> void:
    for it in _items:
        assert_true(E.slot_from_key(it["slot"]) >= 0, "%s bad slot" % it["id"])
        assert_true(E.family_from_key(it["family"]) >= 0, "%s bad family" % it["id"])
        assert_in_range(it["boss"], 1, 5, "%s boss number" % it["id"])
        var errors := []
        S.from_dict(it["stats"], errors, it["id"])
        assert_eq(errors.size(), 0, "%s: %s" % [it["id"], str(errors)])
        assert_false(_st(it["id"]).is_empty(), "%s carries no stats" % it["id"])

func test_class_tables_reference_real_items() -> void:
    for class_key in _tables.keys():
        for id in _all_drops(class_key):
            assert_true(_by_id.has(id), "%s references unknown %s" % [class_key, id])

func test_every_item_is_reachable_from_some_table() -> void:
    var used := {}
    for class_key in _tables.keys():
        for id in _all_drops(class_key):
            used[id] = true
    for id in _data.get("boss5_trinket_pool", []):
        used[id] = true
    for it in _items:
        assert_true(used.has(it["id"]), "%s is authored but nothing drops it" % it["id"])

# ---------------------------------------------------------------- canon stats

func test_canon_armor_and_offhand_stats_cell_for_cell() -> void:
    # ideaboard §3, transcribed. [ac, hp, power, mana, damage]
    var expected := {
        "ITM_T1_RAID_WARBARD_FEET": [4, 4, 0, 0, 0],
        "ITM_T1_RAID_MONKROGUE_FEET": [4, 4, 0, 0, 0],
        "ITM_T1_RAID_HEALER_FEET": [3, 4, 0, 4, 0],
        "ITM_T1_RAID_MAGEWIZ_FEET": [3, 3, 0, 6, 0],
        "ITM_T1_RAID_WARBARD_LEGS": [5, 6, 1, 0, 0],
        "ITM_T1_RAID_MONKROGUE_LEGS": [5, 6, 1, 0, 0],
        "ITM_T1_RAID_HEALER_LEGS": [3, 4, 0, 6, 0],
        "ITM_T1_RAID_MAGEWIZ_LEGS": [3, 4, 0, 8, 0],
        "ITM_T1_RAID_HEALOFF_OH": [2, 0, 0, 5, 0],
        "ITM_T1_RAID_WARBARD_HEAD": [5, 5, 1, 0, 0],
        "ITM_T1_RAID_MONKHEAD_HEAD": [5, 5, 0, 0, 0],
        "ITM_T1_RAID_ROGUEHEAD_HEAD": [4, 4, 2, 0, 0],
        "ITM_T1_RAID_HEALER_HEAD": [3, 4, 0, 7, 0],
        "ITM_T1_RAID_MAGEWIZ_HEAD": [3, 3, 0, 8, 0],
        "ITM_T1_RAID_WARBARD_CHEST": [7, 9, 2, 0, 0],
        "ITM_T1_RAID_MONKROGUE_CHEST_MONK": [6, 7, 2, 0, 0],
        "ITM_T1_RAID_MONKROGUE_CHEST_ROGUE": [6, 7, 2, 0, 0],
        "ITM_T1_RAID_HEALER_CHEST": [4, 7, 0, 10, 0],
        "ITM_T1_RAID_MAGEWIZ_CHEST": [4, 6, 0, 12, 0],
        "ITM_T1_RAID_SHIELD_OH": [7, 8, 1, 0, 0],
        "ITM_T1_RAID_INSTR_OH": [0, 0, 0, 20, 0],
    }
    for id in expected.keys():
        assert_true(_by_id.has(id), "missing canon item %s" % id)
        var s = _st(id)
        assert_eq([s.ac, s.hp, s.power, s.mana, s.damage], expected[id], id)

func test_canon_weapon_damage() -> void:
    var expected := {
        "ITM_T1_RAID_W1H_MH_SWORD_BASIC": 6,
        "ITM_T1_RAID_W1H_MH_DAGGER_BASIC": 4,
        "ITM_T1_RAID_W2H_MONK_BASIC": 10,
        "ITM_T1_RAID_W2H_MAGE_BASIC": 11,
        "ITM_T1_RAID_W2H_WIZ_BASIC": 12,
        "ITM_T1_RAID_W1H_MH_SWORD_STRONG": 8,
        "ITM_T1_RAID_W1H_MH_DAGGER_STRONG": 6,
        "ITM_T1_RAID_W2H_MONK_STRONG": 14,
        "ITM_T1_RAID_W2H_MAGE_STRONG": 15,
        "ITM_T1_RAID_W2H_WIZ_STRONG": 16,
    }
    for id in expected.keys():
        assert_eq(_st(id).damage, expected[id], id)

func test_wizard_stays_exactly_one_damage_above_mage() -> void:
    # Canon holds this gap at every staff rung: 11/12 basic, 15/16 strong.
    assert_eq(_st("ITM_T1_RAID_W2H_WIZ_BASIC").damage
        - _st("ITM_T1_RAID_W2H_MAGE_BASIC").damage, 1)
    assert_eq(_st("ITM_T1_RAID_W2H_WIZ_STRONG").damage
        - _st("ITM_T1_RAID_W2H_MAGE_STRONG").damage, 1)

func test_rogue_basic_dagger_is_canon_regression_against_adventure_sword() -> void:
    # Canon's Basic Raid Dagger is +4 while the Tier 1 Adventure sword is +5, so
    # the Rogue's first raid weapon is a DOWNGRADE per hand. docs/09 OQ-11 flags
    # it as probably unintended. Pinned so nobody "fixes" it without a ruling —
    # and so the ruling, when it comes, breaks this test loudly.
    var adv = JSON.parse_string(FileAccess.get_file_as_string(ADV_PATH))
    var adv_sword := 0
    for it in adv["items"]:
        if it["id"] == "ITM_T1_ADV_W1H_MH":
            adv_sword = int(it["stats"]["damage"])
    assert_eq(adv_sword, 5, "Iron Adventurer's Sword")
    assert_eq(_st("ITM_T1_RAID_W1H_MH_DAGGER_BASIC").damage, 4,
        "canon regression: raid dagger is below the adventure sword")
    # Two hands still beat one, which is presumably why canon tolerated it.
    assert_true(_st("ITM_T1_RAID_W1H_MH_DAGGER_BASIC").damage * 2 > adv_sword,
        "dual-wielding must at least beat the single adventure sword")

# ---------------------------------------------------------------- drop pattern

func test_canon_drop_pattern_by_boss() -> void:
    # raw notes: B1 Feet, B2 Legs, B3 Head, B4 Chest, B5 class capstone.
    var slot_for_boss := {1: "feet", 2: "legs", 3: "head", 4: "chest"}
    for boss in slot_for_boss.keys():
        for it in _items:
            if it["boss"] == boss and it["slot"] in ["head", "chest", "legs", "feet"]:
                assert_eq(it["slot"], slot_for_boss[boss],
                    "%s drops at Boss %d but fills the %s slot" % [it["id"], boss, it["slot"]])

func test_every_class_gets_a_drop_from_every_boss() -> void:
    for class_key in _tables.keys():
        for b in ["1", "2", "3", "4", "5"]:
            assert_true(_tables[class_key].get(b, []).size() > 0,
                "%s receives nothing from Boss %s" % [class_key, b])

func test_only_monk_and_rogue_receive_two_heads() -> void:
    # docs/09 §10.2 / OQ-3: their Boss 3 head is superseded inside the same tier.
    for class_key in _tables.keys():
        var heads := 0
        for id in _all_drops(class_key):
            if _by_id[id]["slot"] == "head":
                heads += 1
        var want := 2 if class_key in ["monk", "rogue"] else 1
        assert_eq(heads, want, "%s head drops" % class_key)

func test_healer_offhand_drops_at_boss_two_for_all_three_healers() -> void:
    for class_key in ["cleric", "druid", "shaman"]:
        assert_true("ITM_T1_RAID_HEALOFF_OH" in _tables[class_key]["2"],
            "%s should receive the Tome at Boss 2" % class_key)

func test_trinket_pool_is_four_universal_charms() -> void:
    var pool: Array = _data["boss5_trinket_pool"]
    assert_eq(pool.size(), 4, "one pool of four charms")
    for id in pool:
        assert_eq(_by_id[id]["family"], "universal_trinket")
        assert_eq(_by_id[id]["slot"], "trinket")
        assert_eq(_by_id[id]["boss"], 5)

# ---------------------------------------------------------------- totals

func test_canon_armor_totals_match_doc_08() -> void:
    # docs/08 §6 publishes "+ T1 Raid armor" per class, computed from CANON items
    # only — so the Monk and Rogue rows use their Boss 3 head, not the proposed
    # Boss 5 capstone. [ac, hp, mana]
    var expected := {
        "warrior": [21, 24, 0], "bard": [21, 24, 0],
        "monk": [20, 22, 0], "rogue": [19, 21, 0],
        "cleric": [13, 19, 27], "druid": [13, 19, 27], "shaman": [13, 19, 27],
        "mage": [13, 16, 34], "wizard": [13, 16, 34],
    }
    for class_key in expected.keys():
        var blocks := []
        for id in _all_drops(class_key):
            var it: Dictionary = _by_id[id]
            # canon-only, and one head: skip the proposed Boss 5 heads
            if it["slot"] in ["head", "chest", "legs", "feet"] and it["canon"]:
                blocks.append(_st(id))
        var t = S.sum(blocks)
        assert_eq([t.ac, t.hp, t.mana], expected[class_key], "%s raid armor" % class_key)

func test_warrior_with_shield_reaches_the_documented_28_ac() -> void:
    var blocks := []
    for id in _all_drops("warrior"):
        var it: Dictionary = _by_id[id]
        if it["slot"] in ["head", "chest", "legs", "feet", "off_hand"]:
            blocks.append(_st(id))
    var t = S.sum(blocks)
    assert_eq(t.ac, 28, "docs/09 cites 28 AC with the Boss 5 shield")
    assert_eq(t.hp, 32)

func test_best_in_slot_covers_all_four_armor_slots() -> void:
    for class_key in _tables.keys():
        var best := _best_armor(class_key)
        var slots := best.keys()
        slots.sort()
        assert_eq(slots, ["chest", "feet", "head", "legs"],
            "%s ends the tier missing an armor slot" % class_key)

func test_raid_gear_beats_adventure_gear_for_every_class() -> void:
    var adventure_ac := {
        "warrior": 15, "bard": 15, "monk": 14, "rogue": 13,
        "cleric": 9, "druid": 9, "shaman": 9, "mage": 8, "wizard": 8,
    }
    for class_key in adventure_ac.keys():
        var blocks := []
        for slot in _best_armor(class_key).values():
            blocks.append(_st(slot))
        var raid_ac: int = S.sum(blocks).ac
        assert_true(raid_ac > adventure_ac[class_key],
            "%s: raid AC %d must beat adventure AC %d"
                % [class_key, raid_ac, adventure_ac[class_key]])

# ---------------------------------------------------------------- collisions

func test_known_name_collisions_and_only_those() -> void:
    var by_name := {}
    for it in _items:
        var n: String = it["name"]
        if not by_name.has(n):
            by_name[n] = []
        by_name[n].append(it["id"])
    var collisions := []
    for n in by_name.keys():
        if by_name[n].size() > 1:
            collisions.append(n)
    collisions.sort()
    assert_eq(collisions, [
        "Basic Healing Weapon", "Basic Raid Staff", "Raider's Boots",
        "Raider's Leggings", "Strong Healing Weapon", "Strong Raid Staff",
    ], "canon's raid-rung name collisions, and only those")

func test_colliding_staves_have_different_damage() -> void:
    # The dangerous collision: same name, three different weapons.
    var basic := [_st("ITM_T1_RAID_W2H_MONK_BASIC").damage,
                  _st("ITM_T1_RAID_W2H_MAGE_BASIC").damage,
                  _st("ITM_T1_RAID_W2H_WIZ_BASIC").damage]
    assert_eq(basic, [10, 11, 12], "three distinct 'Basic Raid Staff'")

func test_colliding_leggings_have_different_stats() -> void:
    assert_eq(_st("ITM_T1_RAID_MONKROGUE_LEGS").ac, 5)
    assert_eq(_st("ITM_T1_RAID_HEALER_LEGS").ac, 3)
    assert_eq(_st("ITM_T1_RAID_MAGEWIZ_LEGS").mana, 8)
    assert_eq(_st("ITM_T1_RAID_HEALER_LEGS").mana, 6)

# ---------------------------------------------------------------- provenance

func test_proposed_items_are_flagged_and_explained() -> void:
    # Exactly the ten gaps docs/09 §10.2 lists, expanded into concrete items.
    var proposed := []
    for it in _items:
        if not it["canon"]:
            proposed.append(it["id"])
            assert_true(it.has("note"), "%s must cite its derivation" % it["id"])
    assert_eq(proposed.size(), 17,
        "3 basic + 3 strong healer weapons, 3 healer capstones, 2 final heads, 2 staves, 4 charms")

func test_every_drop_is_equippable_by_its_class() -> void:
    for c in _classes:
        var cc := E.class_from_key(c["key"])
        for id in _all_drops(c["key"]):
            var fam := E.family_from_key(_by_id[id]["family"])
            assert_true(E.class_can_use_family(cc, fam),
                "%s is handed %s (family %s) which it cannot equip"
                    % [c["key"], id, _by_id[id]["family"]])
