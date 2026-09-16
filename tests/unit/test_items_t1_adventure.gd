extends "res://tests/TestCase.gd"
## data/items_t1_adventure.json
##
## The headline test is test_equipping_each_class_reproduces_canon_totals: it
## walks classes.json, picks the items whose family that class actually claims,
## sums them through Stats, and compares against the ideaboard's printed totals.
## That exercises classes.json + items + Enums + Stats together, so a drift in
## any one of them fails here rather than surfacing as a balance mystery later.

const E = preload("res://sim/model/Enums.gd")
const S = preload("res://sim/model/Stats.gd")

const ITEMS_PATH := "res://data/items_t1_adventure.json"
const CLASSES_PATH := "res://data/classes.json"

var _items: Array = []
var _classes: Array = []
var _by_id: Dictionary = {}

func before_each() -> void:
    if not _items.is_empty():
        return
    var idata = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
    var cdata = JSON.parse_string(FileAccess.get_file_as_string(CLASSES_PATH))
    if idata == null or cdata == null:
        fail("could not parse content files")
        return
    _items = idata.get("items", [])
    _classes = cdata.get("classes", [])
    for it in _items:
        _by_id[it["id"]] = it

func _stats_of(item: Dictionary) -> Variant:
    var errors := []
    var st = S.from_dict(item.get("stats", {}), errors, item.get("id", "?"))
    if errors.size() > 0:
        fail("%s: %s" % [item.get("id", "?"), str(errors)])
    return st

func _items_in_families(families: Array, slots: Array) -> Array:
    var out := []
    for it in _items:
        if it["family"] in families and it["slot"] in slots:
            out.append(it)
    return out

func _class_by_key(key: String) -> Dictionary:
    for c in _classes:
        if c["key"] == key:
            return c
    return {}

# ---------------------------------------------------------------- structure

func test_file_parses_with_expected_item_count() -> void:
    # 17 armor + 7 weapons + 4 trinkets
    assert_eq(_items.size(), 28, "Tier 1 Adventure item count")

func test_ids_are_unique() -> void:
    var seen := {}
    for it in _items:
        var id: String = it["id"]
        assert_false(seen.has(id), "duplicate item id %s" % id)
        seen[id] = true

func test_ids_follow_the_documented_format() -> void:
    # docs/09 §12.1: ITM_T{tier}_{SOURCE}_{FAMILY}_{SLOT}[_{VARIANT}]
    var re := RegEx.new()
    re.compile("^ITM_T[0-5]_(START|ADV|RAID|VEND|QUEST)_[A-Z0-9]+(_[A-Z0-9]+)+$")
    for it in _items:
        assert_true(re.search(it["id"]) != null, "malformed id: %s" % it["id"])
        assert_true(String(it["id"]).begins_with("ITM_T1_ADV_"),
            "%s should be a Tier 1 Adventure id" % it["id"])

func test_every_item_has_required_fields() -> void:
    for it in _items:
        for field in ["id", "name", "slot", "family", "stats", "canon"]:
            assert_true(it.has(field), "%s missing '%s'" % [it.get("id", "?"), field])
        assert_false(String(it["name"]).is_empty(), "%s has an empty name" % it["id"])

func test_all_slot_and_family_keys_resolve() -> void:
    for it in _items:
        assert_true(E.slot_from_key(it["slot"]) >= 0, "%s: bad slot %s" % [it["id"], it["slot"]])
        assert_true(E.family_from_key(it["family"]) >= 0,
            "%s: bad family %s" % [it["id"], it["family"]])

func test_all_stat_blocks_parse_without_errors() -> void:
    for it in _items:
        var errors := []
        S.from_dict(it["stats"], errors, it["id"])
        assert_eq(errors.size(), 0, "%s stats: %s" % [it["id"], str(errors)])

func test_no_item_is_statless() -> void:
    for it in _items:
        assert_false(_stats_of(it).is_empty(), "%s carries no stats" % it["id"])

func test_family_and_slot_agree() -> void:
    # A head family must only appear on head items, trinkets only on trinkets, etc.
    var head_families := ["warrior_bard_head", "monk_head", "rogue_head"]
    for it in _items:
        if it["family"] in head_families:
            assert_eq(it["slot"], "head", "%s uses a head family off-slot" % it["id"])
        if it["family"] == "universal_trinket":
            assert_eq(it["slot"], "trinket", "%s" % it["id"])

# ---------------------------------------------------------------- canon fidelity

func test_canon_armor_stats_cell_for_cell() -> void:
    # ideaboard §2, transcribed exactly.
    var expected := {
        "ITM_T1_ADV_WARBARD_HEAD": [3, 3, 0, 0, 0],
        "ITM_T1_ADV_WARBARD_CHEST": [5, 6, 0, 0, 0],
        "ITM_T1_ADV_WARBARD_LEGS": [4, 4, 0, 0, 0],
        "ITM_T1_ADV_WARBARD_FEET": [3, 3, 0, 0, 0],
        "ITM_T1_ADV_MONKHEAD_HEAD": [4, 2, 0, 0, 0],
        "ITM_T1_ADV_ROGUEHEAD_HEAD": [3, 2, 0, 0, 0],
        "ITM_T1_ADV_MONKROGUE_CHEST": [4, 5, 0, 0, 0],
        "ITM_T1_ADV_MONKROGUE_LEGS": [3, 4, 0, 0, 0],
        "ITM_T1_ADV_MONKROGUE_FEET": [3, 3, 0, 0, 0],
        "ITM_T1_ADV_HEALER_HEAD": [2, 2, 0, 3, 0],
        "ITM_T1_ADV_HEALER_CHEST": [3, 5, 0, 5, 0],
        "ITM_T1_ADV_HEALER_LEGS": [2, 3, 0, 3, 0],
        "ITM_T1_ADV_HEALER_FEET": [2, 2, 0, 2, 0],
        "ITM_T1_ADV_MAGEWIZ_HEAD": [2, 2, 0, 4, 0],
        "ITM_T1_ADV_MAGEWIZ_CHEST": [2, 4, 0, 6, 0],
        "ITM_T1_ADV_MAGEWIZ_LEGS": [2, 2, 0, 4, 0],
        "ITM_T1_ADV_MAGEWIZ_FEET": [2, 2, 0, 3, 0],
    }
    for id in expected.keys():
        assert_true(_by_id.has(id), "missing canon item %s" % id)
        var st = _stats_of(_by_id[id])
        var want: Array = expected[id]
        assert_eq([st.ac, st.hp, st.power, st.mana, st.damage], want, id)

func test_canon_weapon_damage() -> void:
    assert_eq(_stats_of(_by_id["ITM_T1_ADV_W1H_MH"]).damage, 5, "Iron Adventurer's Sword")
    assert_eq(_stats_of(_by_id["ITM_T1_ADV_W2H_MONK_MH"]).damage, 9, "Iron Adventurer's Staff")
    assert_eq(_stats_of(_by_id["ITM_T1_ADV_W2H_MAGE_MH"]).damage, 10, "Apprentice's Firestaff")
    assert_eq(_stats_of(_by_id["ITM_T1_ADV_W2H_WIZ_MH"]).damage, 10, "Apprentice's Arcstaff")

func test_canon_trinkets() -> void:
    assert_eq(_stats_of(_by_id["ITM_T1_ADV_UNIV_TRINKET_HEALTH"]).hp, 7)
    assert_eq(_stats_of(_by_id["ITM_T1_ADV_UNIV_TRINKET_ARMOR"]).ac, 2)
    assert_eq(_stats_of(_by_id["ITM_T1_ADV_UNIV_TRINKET_MANA"]).mana, 10)
    assert_eq(_stats_of(_by_id["ITM_T1_ADV_UNIV_TRINKET_POWER"]).power, 2)
    assert_eq(_items_in_families(["universal_trinket"], ["trinket"]).size(), 4,
        "canon lists exactly four Adventure charms")

func test_canon_names_verbatim() -> void:
    assert_eq(_by_id["ITM_T1_ADV_WARBARD_CHEST"]["name"], "Iron Adventurer's Cuirass")
    assert_eq(_by_id["ITM_T1_ADV_MONKHEAD_HEAD"]["name"], "Ironbound Headband")
    assert_eq(_by_id["ITM_T1_ADV_HEALER_CHEST"]["name"], "Blessed Adventurer's Robe")
    assert_eq(_by_id["ITM_T1_ADV_MAGEWIZ_CHEST"]["name"], "Reinforced Spellweave Robe")
    assert_eq(_by_id["ITM_T1_ADV_W2H_MAGE_MH"]["name"], "Apprentice's Firestaff")

func test_no_adventure_offhands_exist() -> void:
    # Canon fact, not an omission: Tier 1 Adventure gear has no off-hand at all.
    # Off-hands first appear at Raid rung (Boss 2 Tome, Boss 5 Shield/Instrument).
    for it in _items:
        assert_ne(it["slot"], "off_hand",
            "%s: canon Tier 1 Adventure has no off-hand items" % it["id"])

func test_proposed_items_are_flagged_as_non_canon() -> void:
    # The three healer weapons are the only PROPOSED entries here; canon says
    # "Stats TBD until we establish the healing/Mana formulas".
    var proposed := []
    for it in _items:
        if not it["canon"]:
            proposed.append(it["id"])
    proposed.sort()
    assert_eq(proposed, [
        "ITM_T1_ADV_WPN_CLR_MH", "ITM_T1_ADV_WPN_DRU_MH", "ITM_T1_ADV_WPN_SHM_MH",
    ], "only the healer weapons should be non-canon")
    for id in proposed:
        assert_true(_by_id[id].has("note"), "%s must explain its derivation" % id)
        assert_eq(_stats_of(_by_id[id]).mana, 10, "docs/09 §10.2 G11 proposes +10 Mana")

# ---------------------------------------------------------------- integration

func test_equipping_each_class_reproduces_canon_totals() -> void:
    # Walk classes.json, gather the armor this class can actually claim, sum it,
    # and compare with the ideaboard's printed family totals.
    var expected := {
        "warrior": [15, 16, 0], "bard": [15, 16, 0],
        "monk": [14, 14, 0], "rogue": [13, 14, 0],
        "cleric": [9, 12, 13], "druid": [9, 12, 13], "shaman": [9, 12, 13],
        "mage": [8, 10, 17], "wizard": [8, 10, 17],
    }
    for class_key in expected.keys():
        var c := _class_by_key(class_key)
        assert_false(c.is_empty(), "no class %s" % class_key)
        var fams := [c["families"]["head"], c["families"]["body"]]
        var pieces := _items_in_families(fams, ["head", "chest", "legs", "feet"])
        assert_eq(pieces.size(), 4,
            "%s should have exactly one item per armor slot, got %d" % [class_key, pieces.size()])
        var blocks := []
        for p in pieces:
            blocks.append(_stats_of(p))
        var total = S.sum(blocks)
        var want: Array = expected[class_key]
        assert_eq([total.ac, total.hp, total.mana], want,
            "%s geared totals" % class_key)

func test_every_class_has_a_main_hand_available() -> void:
    for c in _classes:
        var fam: String = c["families"]["main_hand"]
        var found := _items_in_families([fam], ["main_hand"])
        assert_eq(found.size(), 1,
            "%s has %d main-hand options in family %s, expected exactly 1"
                % [c["key"], found.size(), fam])

func test_two_handed_weapons_are_flagged() -> void:
    for it in _items:
        if it["family"] in ["monk_two_hand", "mage_two_hand", "wizard_two_hand"]:
            assert_true(it.get("two_handed", false), "%s must be flagged two_handed" % it["id"])

func test_every_item_is_claimable_by_at_least_one_class() -> void:
    for it in _items:
        var fam := E.family_from_key(it["family"])
        assert_true(E.family_demand(fam) >= 1,
            "%s belongs to a family no class can use" % it["id"])
