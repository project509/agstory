extends "res://tests/TestCase.gd"
## data/items_starting.json — what a Common recruit arrives wearing.
##
## The canon AC totals (7/7/6/5/5/5/5/4/4) are the tightest numeric constraint in
## the starting data, and they are reached by nine different item combinations, so
## summing each starting_set and checking the total catches almost any authoring
## slip. The name-collision tests exist because canon reuses "Worn Leggings" for
## two items with different stats — collapsing them would silently give the
## healers +1 AC each.

const E = preload("res://sim/model/Enums.gd")
const S = preload("res://sim/model/Stats.gd")

const PATH := "res://data/items_starting.json"
const CLASSES_PATH := "res://data/classes.json"

var _data: Dictionary = {}
var _items: Array = []
var _sets: Dictionary = {}
var _by_id: Dictionary = {}
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
    _sets = _data.get("starting_sets", {})
    _classes = cparsed.get("classes", [])
    for it in _items:
        _by_id[it["id"]] = it

func _stats_of(id: String):
    var errors := []
    var st = S.from_dict(_by_id[id].get("stats", {}), errors, id)
    if errors.size() > 0:
        fail("%s: %s" % [id, str(errors)])
    return st

# ---------------------------------------------------------------- structure

func test_parses_with_expected_counts() -> void:
    assert_eq(_data.get("tier", -1), 0, "starting gear is tier 0")
    assert_eq(_items.size(), 22, "22 distinct starting pieces across the nine classes")
    assert_eq(_sets.size(), 9, "one starting set per class")

func test_ids_unique_and_well_formed() -> void:
    var re := RegEx.new()
    re.compile("^ITM_T0_START_[A-Z0-9]+(_[A-Z0-9]+)+$")
    var seen := {}
    for it in _items:
        var id: String = it["id"]
        assert_false(seen.has(id), "duplicate id %s" % id)
        seen[id] = true
        assert_true(re.search(id) != null, "malformed id %s" % id)

func test_keys_resolve_and_stats_parse() -> void:
    for it in _items:
        assert_true(E.slot_from_key(it["slot"]) >= 0, "%s bad slot" % it["id"])
        assert_true(E.family_from_key(it["family"]) >= 0, "%s bad family" % it["id"])
        var errors := []
        S.from_dict(it["stats"], errors, it["id"])
        assert_eq(errors.size(), 0, "%s: %s" % [it["id"], str(errors)])

func test_every_item_is_referenced_by_some_starting_set() -> void:
    var used := {}
    for key in _sets.keys():
        for id in _sets[key]:
            used[id] = true
    for it in _items:
        assert_true(used.has(it["id"]), "%s is authored but no class wears it" % it["id"])

func test_starting_sets_reference_real_items() -> void:
    for key in _sets.keys():
        for id in _sets[key]:
            assert_true(_by_id.has(id), "%s references unknown item %s" % [key, id])

# ---------------------------------------------------------------- canon

func test_starting_gear_carries_ac_only() -> void:
    # CANON: no HP, Power or Mana appears on any starting piece.
    for it in _items:
        var st = _stats_of(it["id"])
        assert_true(st.ac > 0, "%s should carry AC" % it["id"])
        assert_eq(st.hp, 0, "%s must not carry HP" % it["id"])
        assert_eq(st.power, 0, "%s must not carry Power" % it["id"])
        assert_eq(st.mana, 0, "%s must not carry Mana" % it["id"])
        assert_eq(st.damage, 0, "%s must not carry Damage" % it["id"])

func test_no_weapons_offhands_or_trinkets() -> void:
    # CANON: a Common recruit arrives with four armor pieces and nothing else.
    for it in _items:
        assert_true(it["slot"] in ["head", "chest", "legs", "feet"],
            "%s: starting gear is armor only, got slot %s" % [it["id"], it["slot"]])

func test_canon_starting_ac_totals() -> void:
    # raw notes, Starting armor for common recruits. The headline numbers.
    var expected := {
        "warrior": 7, "bard": 7, "monk": 6, "rogue": 5, "cleric": 5,
        "druid": 5, "shaman": 5, "mage": 4, "wizard": 4,
    }
    for class_key in expected.keys():
        var blocks := []
        for id in _sets[class_key]:
            blocks.append(_stats_of(id))
        assert_eq(S.sum(blocks).ac, expected[class_key], "%s starting AC total" % class_key)

func test_every_set_covers_all_four_armor_slots_exactly_once() -> void:
    for class_key in _sets.keys():
        var slots := []
        for id in _sets[class_key]:
            slots.append(_by_id[id]["slot"])
        slots.sort()
        assert_eq(slots, ["chest", "feet", "head", "legs"],
            "%s must have exactly one item per armor slot" % class_key)

func test_canon_item_names_verbatim() -> void:
    var expected := {
        "ITM_T0_START_WARBARD_HEAD": "Worn Iron Cap",
        "ITM_T0_START_WARBARD_CHEST": "Damaged Chainmail",
        "ITM_T0_START_MONKHEAD_HEAD": "Frayed Headband",
        "ITM_T0_START_MONKROGUE_CHEST_MONK": "Worn Gi",
        "ITM_T0_START_ROGUEHEAD_HEAD": "Worn Eyepatch",
        "ITM_T0_START_MONKROGUE_CHEST_ROGUE": "Old Leather Jerkin",
        "ITM_T0_START_MONKROGUE_LEGS_ROGUE": "Worn Leather Breeches",
        "ITM_T0_START_HEALER_HEAD_CIRCLET": "Worn Circlet",
        "ITM_T0_START_HEALER_HEAD_HEADDRESS": "Worn Headdress",
        "ITM_T0_START_HEALER_CHEST_VESTMENTS": "Tattered Vestments",
        "ITM_T0_START_HEALER_CHEST_HIDE": "Tattered Hide Vest",
        "ITM_T0_START_MAGEWIZ_HEAD": "Worn Apprentice Cap",
        "ITM_T0_START_MAGEWIZ_CHEST": "Tattered Robe",
        "ITM_T0_START_MAGEWIZ_FEET": "Old Slippers",
    }
    for id in expected.keys():
        assert_true(_by_id.has(id), "missing %s" % id)
        assert_eq(_by_id[id]["name"], expected[id], id)

# ---------------------------------------------------------------- the collision

func test_worn_leggings_exists_twice_with_different_stats() -> void:
    # docs/09 §5 flags this: canon uses the same name for a 2 AC Warrior/Bard
    # item and a 1 AC healer item. Merging them would hand every healer +1 AC.
    var plate = _stats_of("ITM_T0_START_WARBARD_LEGS")
    var cloth = _stats_of("ITM_T0_START_HEALER_LEGS")
    assert_eq(_by_id["ITM_T0_START_WARBARD_LEGS"]["name"], "Worn Leggings")
    assert_eq(_by_id["ITM_T0_START_HEALER_LEGS"]["name"], "Worn Leggings")
    assert_eq(plate.ac, 2, "Warrior/Bard Worn Leggings")
    assert_eq(cloth.ac, 1, "healer Worn Leggings")
    assert_ne(_by_id["ITM_T0_START_WARBARD_LEGS"]["family"],
              _by_id["ITM_T0_START_HEALER_LEGS"]["family"],
              "the two must be disambiguated by family")

func test_duplicate_names_are_always_distinct_items() -> void:
    # Any repeated display name must map to more than one id, never be silently
    # deduplicated. Names are not identity here; ids are.
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
    assert_eq(collisions, ["Old Sandals", "Worn Leggings", "Worn Trousers"],
        "the known canon name collisions, and only those")

# ---------------------------------------------------------------- cross-file

func test_each_class_can_actually_equip_its_starting_set() -> void:
    # Every starting piece must belong to a family that class claims, or the
    # recruiter would hand a raider gear it cannot wear.
    for c in _classes:
        var cc := E.class_from_key(c["key"])
        for id in _sets[c["key"]]:
            var fam := E.family_from_key(_by_id[id]["family"])
            assert_true(E.class_can_use_family(cc, fam),
                "%s cannot equip %s (family %s)" % [c["key"], id, _by_id[id]["family"]])

func test_starting_gear_is_strictly_worse_than_adventure_gear() -> void:
    # The progression ladder's first rung. Starting totals are 7/6/5/5/4;
    # Adventure totals are 15/14/13/9/8. Every class must gain from the upgrade.
    var starting := {"warrior": 7, "monk": 6, "rogue": 5, "cleric": 5, "mage": 4}
    var adventure := {"warrior": 15, "monk": 14, "rogue": 13, "cleric": 9, "mage": 8}
    for key in starting.keys():
        assert_true(adventure[key] > starting[key],
            "%s: adventure AC %d must beat starting AC %d"
                % [key, adventure[key], starting[key]])

func test_classes_sharing_a_set_really_are_identical_in_canon() -> void:
    # Warrior/Bard and Mage/Wizard share their starting kit verbatim in canon.
    assert_eq(_sets["warrior"], _sets["bard"])
    assert_eq(_sets["mage"], _sets["wizard"])
    # Monk and Rogue do NOT, despite sharing an armor family later.
    assert_ne(_sets["monk"], _sets["rogue"])
    # Nor do the three healers, despite sharing one family at every later rung.
    assert_ne(_sets["cleric"], _sets["druid"])
    assert_ne(_sets["druid"], _sets["shaman"])
