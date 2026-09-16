extends "res://tests/TestCase.gd"
## data/classes.json — structure, and agreement with both canon and Enums.
##
## The important checks here are cross-validations, not spot checks:
##   * every family a class references must list that class as a claimant in
##     Enums.FAMILY_CLAIMANTS (which is itself checked against the ideaboard
##     matrix in test_enums.gd) — so classes.json cannot drift from canon
##   * base_hp plus the real canon armor totals must reproduce docs/08 §6's
##     published totals, so the HP table and the item tables stay consistent

const E = preload("res://sim/model/Enums.gd")

const PATH := "res://data/classes.json"

var _data: Dictionary = {}
var _classes: Array = []

func before_each() -> void:
    if not _data.is_empty():
        return
    var text := FileAccess.get_file_as_string(PATH)
    var parsed = JSON.parse_string(text)
    if parsed == null:
        fail("could not parse %s" % PATH)
        return
    _data = parsed
    _classes = _data.get("classes", [])

func _by_key(key: String) -> Dictionary:
    for c in _classes:
        if c.get("key", "") == key:
            return c
    return {}

# ---------------------------------------------------------------- shape

func test_file_parses_and_has_nine_classes() -> void:
    assert_eq(_data.get("schema_version", 0), 1)
    assert_eq(_classes.size(), 9, "canon defines exactly nine classes")

func test_keys_match_enums_exactly_and_in_order() -> void:
    var keys := []
    for c in _classes:
        keys.append(c.get("key", ""))
    assert_eq(keys, E.CLASS_KEYS,
        "classes.json order must match Enums.CLASS_KEYS so enum values index it directly")

func test_display_names_match_enums() -> void:
    for i in _classes.size():
        assert_eq(_classes[i].get("name", ""), E.CLASS_NAMES[i])

func test_every_class_has_all_required_fields() -> void:
    var required := ["key", "name", "role", "role_group", "description",
        "base_hp", "primary_stat", "secondary_stats", "families",
        "two_handed", "dual_wield"]
    for c in _classes:
        for field in required:
            assert_true(c.has(field), "%s missing field '%s'" % [c.get("key", "?"), field])

# ---------------------------------------------------------------- key validity

func test_all_referenced_keys_resolve_in_enums() -> void:
    # A typo anywhere here must be caught at content-validation time, not by a
    # confusing crash three systems downstream.
    for c in _classes:
        var k: String = c["key"]
        assert_true(E.class_from_key(k) >= 0, "unknown class key %s" % k)
        assert_true(E.role_from_key(c["role"]) >= 0, "%s: unknown role %s" % [k, c["role"]])
        assert_true(E.role_group_from_key(c["role_group"]) >= 0,
            "%s: unknown role_group %s" % [k, c["role_group"]])
        assert_true(E.stat_from_key(c["primary_stat"]) >= 0,
            "%s: unknown primary_stat %s" % [k, c["primary_stat"]])
        for s in c["secondary_stats"]:
            assert_true(E.stat_from_key(s) >= 0, "%s: unknown secondary stat %s" % [k, s])
        for slot_name in c["families"].keys():
            var fam = c["families"][slot_name]
            if fam == null:
                continue
            assert_true(E.family_from_key(fam) >= 0,
                "%s: unknown family %s in slot %s" % [k, fam, slot_name])

func test_role_matches_its_declared_group() -> void:
    for c in _classes:
        var role := E.role_from_key(c["role"])
        var declared := E.role_group_from_key(c["role_group"])
        assert_eq(E.role_group_of(role), declared,
            "%s: role %s belongs to group %s, not %s"
                % [c["key"], c["role"], E.role_group_name_of(E.role_group_of(role)), c["role_group"]])

# ---------------------------------------------------------------- canon matrix

func test_every_referenced_family_claims_that_class() -> void:
    # The cross-validation that keeps classes.json honest: Enums.FAMILY_CLAIMANTS
    # is verified against the ideaboard matrix in test_enums.gd, so if a class
    # here references a family that does not claim it, one of the two is wrong.
    for c in _classes:
        var cc := E.class_from_key(c["key"])
        for slot_name in c["families"].keys():
            var fam_key = c["families"][slot_name]
            if fam_key == null:
                continue
            var fam := E.family_from_key(fam_key)
            assert_true(E.class_can_use_family(cc, fam),
                "%s references family '%s' for %s but that family does not claim it"
                    % [c["key"], fam_key, slot_name])

func test_two_handed_classes_have_no_off_hand() -> void:
    # Canon matrix: Monk, Mage and Wizard show "—" in the Off Hand column.
    var expected_two_handed := ["monk", "mage", "wizard"]
    for c in _classes:
        var is_2h: bool = c["two_handed"]
        var has_oh = c["families"]["off_hand"] != null
        if c["key"] in expected_two_handed:
            assert_true(is_2h, "%s should be two-handed per the canon matrix" % c["key"])
        else:
            assert_false(is_2h, "%s should not be two-handed" % c["key"])
        assert_eq(is_2h, not has_oh,
            "%s: a two-handed class must have a null off_hand and vice versa" % c["key"])

func test_only_rogue_dual_wields() -> void:
    # Canon matrix: Rogue is the only class with the same 1H family in both hands.
    for c in _classes:
        if c["key"] == "rogue":
            assert_true(c["dual_wield"])
            assert_eq(c["families"]["main_hand"], c["families"]["off_hand"],
                "Rogue dual-wields the shared Warrior/Rogue/Bard 1H family")
        else:
            assert_false(c["dual_wield"], "%s must not dual wield" % c["key"])

func test_healers_share_head_and_body_family() -> void:
    # Canon: Healer armor is the only family where the head is shared by three classes.
    for key in ["cleric", "druid", "shaman"]:
        var c := _by_key(key)
        assert_eq(c["families"]["head"], "healer_armor")
        assert_eq(c["families"]["body"], "healer_armor")
    # ...and each healer has its own class-specific weapon.
    assert_eq(_by_key("cleric")["families"]["main_hand"], "cleric_weapon")
    assert_eq(_by_key("druid")["families"]["main_hand"], "druid_weapon")
    assert_eq(_by_key("shaman")["families"]["main_hand"], "shaman_weapon")

func test_head_slot_asymmetry_resolved_to_shared() -> void:
    # docs/15 BL-19: the canon slot matrix and the canon item tables disagree.
    # The matrix gives Warrior its own head family; every item table ships one
    # shared helm. Resolved in favour of the item tables, so both wear the same
    # head family and neither has an unfillable slot.
    assert_eq(_by_key("warrior")["families"]["head"], "warrior_bard_head")
    assert_eq(_by_key("bard")["families"]["head"], "warrior_bard_head")
    # ...but their body armor is genuinely shared.
    assert_eq(_by_key("warrior")["families"]["body"], "warrior_bard_armor")
    assert_eq(_by_key("bard")["families"]["body"], "warrior_bard_armor")

# ---------------------------------------------------------------- HP

func test_base_hp_matches_doc_08_table() -> void:
    var expected := {
        "warrior": 120, "monk": 100, "bard": 90, "rogue": 85,
        "cleric": 75, "druid": 75, "shaman": 75, "mage": 65, "wizard": 65,
    }
    for key in expected.keys():
        assert_eq(_by_key(key)["base_hp"], expected[key], "%s base HP" % key)

func test_base_hp_plus_canon_armor_reproduces_doc_08_totals() -> void:
    # docs/08 §6 publishes "+ T1 Adventure armor -> Total". Those armor HP values
    # are CANON (ideaboard §2), so this pins the HP table to the item tables.
    var armor_hp := {
        "warrior": 16, "bard": 16, "monk": 14, "rogue": 14,
        "cleric": 12, "druid": 12, "shaman": 12, "mage": 10, "wizard": 10,
    }
    var expected_total := {
        "warrior": 136, "monk": 114, "bard": 106, "rogue": 99,
        "cleric": 87, "druid": 87, "shaman": 87, "mage": 75, "wizard": 75,
    }
    for key in expected_total.keys():
        var got: int = _by_key(key)["base_hp"] + armor_hp[key]
        assert_eq(got, expected_total[key], "%s geared HP total" % key)

func test_warrior_to_mage_hp_ratio_holds_the_stated_design_intent() -> void:
    # docs/08 §6: base HP chosen so the Warrior/Mage ratio is ~1.85:1.
    var ratio := float(_by_key("warrior")["base_hp"]) / float(_by_key("mage")["base_hp"])
    assert_in_range(ratio, 1.80, 1.90, "Warrior/Mage base HP ratio was %f" % ratio)

func test_hp_ordering_follows_armor_weight() -> void:
    # Plate > leather > cloth. An edit that inverts this breaks the whole
    # survivability model before any formula is involved.
    var order := ["warrior", "monk", "bard", "rogue", "cleric", "mage"]
    for i in range(order.size() - 1):
        var a: int = _by_key(order[i])["base_hp"]
        var b: int = _by_key(order[i + 1])["base_hp"]
        assert_true(a >= b, "%s (%d) should have at least as much HP as %s (%d)"
            % [order[i], a, order[i + 1], b])

func test_mage_and_wizard_are_defensively_identical() -> void:
    # They share the identical canon armor family; they differ only on weapon damage.
    assert_eq(_by_key("mage")["base_hp"], _by_key("wizard")["base_hp"])
    assert_eq(_by_key("mage")["families"]["body"], _by_key("wizard")["families"]["body"])
    assert_eq(_by_key("mage")["families"]["head"], _by_key("wizard")["families"]["head"])
    # They differ only on the weapon.
    assert_ne(_by_key("mage")["families"]["main_hand"], _by_key("wizard")["families"]["main_hand"])

func test_rarity_hp_multipliers_all_neutral_for_first_playable() -> void:
    # docs/08 §6.1: a Legendary is better because they do not make mistakes, not
    # because they have a bigger health bar. The hook exists but ships at 1.0.
    var mult: Dictionary = _data["rarity_hp_multiplier"]
    assert_eq(mult.size(), 5, "one entry per rarity")
    for key in E.RARITY_KEYS:
        assert_true(mult.has(key), "missing rarity multiplier for %s" % key)
        assert_almost(float(mult[key]), 1.0, 0.0001,
            "%s multiplier should ship neutral" % key)

# ---------------------------------------------------------------- roles

func test_role_distribution_supports_a_twelve_raider_comp() -> void:
    # Canon: raid size 12, most fights need 2 tanks. There must be enough
    # distinct healing and tanking identity to build a comp out of.
    var groups := {}
    for c in _classes:
        var g: String = c["role_group"]
        groups[g] = groups.get(g, 0) + 1
    assert_eq(groups.get("tank", 0), 1, "Warrior is the only dedicated tank")
    assert_eq(groups.get("healer", 0), 3, "Cleric, Druid, Shaman")
    assert_eq(groups.get("support", 0), 1, "Bard")
    assert_eq(groups.get("dps", 0), 4, "Monk, Rogue, Mage, Wizard")

func test_canon_descriptions_preserved() -> void:
    assert_eq(_by_key("warrior")["description"], "High survivability, high threat")
    assert_eq(_by_key("cleric")["description"], "Efficient single-target healing")
    assert_eq(_by_key("druid")["description"], "Small heal to the entire raid every round")
    assert_eq(_by_key("monk")["description"], "High DPS + emergency tank")
    assert_eq(_by_key("mage")["description"], "Raid spell buff + AoE damage")
    assert_eq(_by_key("wizard")["description"], "Very high single-target DPS")
    assert_eq(_by_key("rogue")["description"], "Position-dependent burst DPS")
