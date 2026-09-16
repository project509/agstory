extends "res://tests/TestCase.gd"
## sim/model/Enums.gd — canon fidelity of the shared vocabulary.
##
## The heavyweight test here is test_family_claimants_reproduce_the_canon_matrix:
## it rebuilds the ideaboard equipment matrix out of FAMILY_CLAIMANTS and checks
## it cell for cell. That matrix decides who competes for every drop, so an error
## in it would quietly corrupt loot routing everywhere.

const E = preload("res://sim/model/Enums.gd")

# ---------------------------------------------------------------- shape

func test_nine_canon_classes() -> void:
    assert_eq(E.CLASS_KEYS.size(), 9, "canon lists exactly nine classes")
    assert_eq(E.CLASS_NAMES.size(), 9)
    var expected := ["Warrior", "Monk", "Rogue", "Cleric", "Druid", "Shaman", "Bard", "Mage", "Wizard"]
    for i in expected.size():
        assert_eq(E.CLASS_NAMES[i], expected[i], "class %d" % i)

func test_five_rarities_in_ascending_quality() -> void:
    assert_eq(E.RARITY_KEYS.size(), 5)
    assert_eq(E.RARITY_NAMES, ["Common", "Uncommon", "Rare", "Epic", "Legendary"])
    assert_true(E.Rarity.COMMON < E.Rarity.LEGENDARY, "rarity must order low to high")

func test_seven_slots_exactly() -> void:
    # docs/09 §3.2: seven slots, no more — one tier fully gears a raider.
    assert_eq(E.SLOT_KEYS.size(), 7)
    assert_eq(E.SLOT_KEYS, ["main_hand", "off_hand", "head", "chest", "legs", "feet", "trinket"])
    assert_eq(E.BODY_SLOTS.size(), 3, "chest/legs/feet are the collapsed matrix column")
    assert_eq(E.ARMOR_SLOTS.size(), 4)

func test_five_item_stats() -> void:
    assert_eq(E.STAT_KEYS, ["ac", "hp", "power", "mana", "damage"])
    assert_eq(E.STAT_NAMES[E.StatKind.AC], "AC")
    assert_eq(E.STAT_NAMES[E.StatKind.MANA], "Mana")

func test_canon_role_strings_verbatim() -> void:
    # Canon: raw notes, Classes table. These strings are shown to the player and
    # are quoted in the design docs; they must not drift.
    assert_eq(E.ROLE_NAMES[E.Role.MAIN_TANK], "Main Tank")
    assert_eq(E.ROLE_NAMES[E.Role.MELEE_DPS_OFFTANK], "Melee DPS / Offtank")
    assert_eq(E.ROLE_NAMES[E.Role.MAIN_TANK_HEALER], "Main Tank Healer")
    assert_eq(E.ROLE_NAMES[E.Role.RAID_HEALER], "Raid Healer")
    assert_eq(E.ROLE_NAMES[E.Role.CHAIN_HEALER], "Chain Healer")
    assert_eq(E.ROLE_NAMES[E.Role.AOE_CASTER], "AoE Caster")
    assert_eq(E.ROLE_NAMES[E.Role.SINGLE_TARGET_CASTER], "Single-Target Caster")
    assert_eq(E.ROLE_NAMES[E.Role.SUPPORT], "Support")
    assert_eq(E.ROLE_KEYS.size(), 9, "one canon role per class")

func test_six_reputation_ranks_starting_unknown() -> void:
    # Canon: "You start at: Unknown", then Known, Respected, Established,
    # Renowned, Legendary.
    assert_eq(E.REPUTATION_NAMES,
        ["Unknown", "Known", "Respected", "Established", "Renowned", "Legendary"])
    assert_eq(E.ReputationRank.UNKNOWN, 0, "the ladder must start at Unknown")
    assert_eq(E.REPUTATION_KEYS.size(), 6)

func test_encounter_kinds_and_stars() -> void:
    assert_eq(E.ENCOUNTER_KIND_KEYS.size(), 4)
    # Canon raid layout: encounters 1..5 carry 1..5 stars.
    for n in range(1, 6):
        assert_eq(E.ENCOUNTER_STARS[n], n, "encounter %d star rating" % n)

# ---------------------------------------------------------------- integrity

func test_every_enum_has_matching_key_and_name_arrays() -> void:
    var pairs := [
        [E.CLASS_KEYS, E.CLASS_NAMES, "class"],
        [E.RARITY_KEYS, E.RARITY_NAMES, "rarity"],
        [E.SLOT_KEYS, E.SLOT_NAMES, "slot"],
        [E.STAT_KEYS, E.STAT_NAMES, "stat"],
        [E.ROLE_KEYS, E.ROLE_NAMES, "role"],
        [E.ROLE_GROUP_KEYS, E.ROLE_GROUP_NAMES, "role_group"],
        [E.FAMILY_KEYS, E.FAMILY_NAMES, "family"],
        [E.ENCOUNTER_KIND_KEYS, E.ENCOUNTER_KIND_NAMES, "encounter_kind"],
        [E.REPUTATION_KEYS, E.REPUTATION_NAMES, "reputation"],
    ]
    for p in pairs:
        assert_eq(p[0].size(), p[1].size(), "%s key/name arrays must be parallel" % p[2])

func test_keys_are_unique_and_lowercase_snake() -> void:
    var all_key_sets := [
        E.CLASS_KEYS, E.RARITY_KEYS, E.SLOT_KEYS, E.STAT_KEYS,
        E.ROLE_KEYS, E.ROLE_GROUP_KEYS, E.FAMILY_KEYS,
        E.ENCOUNTER_KIND_KEYS, E.REPUTATION_KEYS,
    ]
    for keys in all_key_sets:
        var seen := {}
        for k in keys:
            assert_false(seen.has(k), "duplicate key: %s" % k)
            seen[k] = true
            assert_eq(k, String(k).to_lower(), "keys are persistence contracts: %s" % k)
            assert_false(String(k).contains(" "), "no spaces in key: %s" % k)

func test_key_round_trip_for_every_member() -> void:
    for i in E.CLASS_KEYS.size():
        assert_eq(E.class_from_key(E.class_key(i)), i, "class round trip %d" % i)
    for i in E.RARITY_KEYS.size():
        assert_eq(E.rarity_from_key(E.rarity_key(i)), i)
    for i in E.SLOT_KEYS.size():
        assert_eq(E.slot_from_key(E.slot_key(i)), i)
    for i in E.STAT_KEYS.size():
        assert_eq(E.stat_from_key(E.stat_key(i)), i)
    for i in E.ROLE_KEYS.size():
        assert_eq(E.role_from_key(E.role_key(i)), i)
    for i in E.FAMILY_KEYS.size():
        assert_eq(E.family_from_key(E.family_key(i)), i)
    for i in E.REPUTATION_KEYS.size():
        assert_eq(E.reputation_from_key(E.reputation_key(i)), i)

func test_unknown_keys_report_failure_rather_than_defaulting() -> void:
    # Returning -1 rather than 0 matters: a typo'd content file must be a loud
    # validation error, not a silent "everyone is a Warrior".
    assert_eq(E.class_from_key("paladin"), -1)
    assert_eq(E.slot_from_key("cloak"), -1)
    assert_eq(E.family_from_key("nonsense"), -1)
    assert_eq(E.class_key(99), "")
    assert_eq(E.class_name_of(-1), "<invalid>")

# ---------------------------------------------------------------- the matrix

func test_family_claimants_reproduce_the_canon_matrix() -> void:
    # Rebuilds ideaboard §1 from FAMILY_CLAIMANTS: for each class, the exact set
    # of families it can equip. Compared against the canon matrix cell for cell.
    var expected := {
        E.CharClass.WARRIOR: [
            "wrb_one_hand", "warrior_shield", "warrior_bard_head",
            "warrior_bard_armor", "universal_trinket"],
        E.CharClass.MONK: [
            "monk_two_hand", "monk_head", "monk_rogue_armor", "universal_trinket"],
        E.CharClass.ROGUE: [
            "wrb_one_hand", "rogue_head", "monk_rogue_armor", "universal_trinket"],
        E.CharClass.CLERIC: [
            "cleric_weapon", "healer_off_hand", "healer_armor", "universal_trinket"],
        E.CharClass.DRUID: [
            "druid_weapon", "healer_off_hand", "healer_armor", "universal_trinket"],
        E.CharClass.SHAMAN: [
            "shaman_weapon", "healer_off_hand", "healer_armor", "universal_trinket"],
        E.CharClass.BARD: [
            "wrb_one_hand", "instrument", "warrior_bard_head",
            "warrior_bard_armor", "universal_trinket"],
        E.CharClass.MAGE: [
            "mage_two_hand", "mage_wizard_armor", "universal_trinket"],
        E.CharClass.WIZARD: [
            "wizard_two_hand", "mage_wizard_armor", "universal_trinket"],
    }
    for cc in expected.keys():
        var got: Array = []
        for fam in E.FAMILY_KEYS.size():
            if E.class_can_use_family(cc, fam):
                got.append(E.family_key(fam))
        got.sort()
        var want: Array = expected[cc].duplicate()
        want.sort()
        assert_eq(got, want, "families for %s" % E.class_name_of(cc))

func test_trinkets_are_the_nine_way_contention_family() -> void:
    # docs/09 §4.5: contention is deliberately front-loaded on trinkets.
    assert_eq(E.family_demand(E.ItemFamily.UNIVERSAL_TRINKET), 9)
    for cc in E.all_classes():
        assert_true(E.class_can_use_family(cc, E.ItemFamily.UNIVERSAL_TRINKET),
            "%s must be able to equip a trinket" % E.class_name_of(cc))

func test_shared_family_demands_match_the_inverse_table() -> void:
    assert_eq(E.family_demand(E.ItemFamily.WRB_ONE_HAND), 3, "Warrior, Rogue, Bard")
    assert_eq(E.family_demand(E.ItemFamily.HEALER_ARMOR), 3, "Cleric, Druid, Shaman")
    assert_eq(E.family_demand(E.ItemFamily.HEALER_OFF_HAND), 3)
    assert_eq(E.family_demand(E.ItemFamily.WARRIOR_BARD_ARMOR), 2)
    assert_eq(E.family_demand(E.ItemFamily.MONK_ROGUE_ARMOR), 2)
    assert_eq(E.family_demand(E.ItemFamily.MAGE_WIZARD_ARMOR), 2)
    assert_eq(E.family_demand(E.ItemFamily.WARRIOR_SHIELD), 1)
    assert_eq(E.family_demand(E.ItemFamily.INSTRUMENT), 1)

func test_no_family_is_orphaned() -> void:
    for fam in E.FAMILY_KEYS.size():
        assert_true(E.family_demand(fam) >= 1,
            "family %s has no claimant class" % E.family_key(fam))

# ---------------------------------------------------------------- role groups

func test_every_role_maps_to_a_group() -> void:
    for r in E.ROLE_KEYS.size():
        assert_true(E.ROLE_TO_GROUP.has(r), "role %s has no group" % E.role_key(r))

func test_role_group_buckets() -> void:
    assert_eq(E.role_group_of(E.Role.MAIN_TANK), E.RoleGroup.TANK)
    assert_eq(E.role_group_of(E.Role.MAIN_TANK_HEALER), E.RoleGroup.HEALER)
    assert_eq(E.role_group_of(E.Role.RAID_HEALER), E.RoleGroup.HEALER)
    assert_eq(E.role_group_of(E.Role.CHAIN_HEALER), E.RoleGroup.HEALER)
    assert_eq(E.role_group_of(E.Role.SUPPORT), E.RoleGroup.SUPPORT)
    assert_eq(E.role_group_of(E.Role.AOE_CASTER), E.RoleGroup.DPS)
    assert_eq(E.role_group_of(E.Role.SINGLE_TARGET_CASTER), E.RoleGroup.DPS)
    assert_eq(E.role_group_of(E.Role.MELEE_DPS), E.RoleGroup.DPS)
    # Monk is "Melee DPS / Offtank": it fills a DPS slot and offtanks situationally.
    assert_eq(E.role_group_of(E.Role.MELEE_DPS_OFFTANK), E.RoleGroup.DPS)

func test_exactly_three_healer_roles() -> void:
    # Canon gives Cleric, Druid and Shaman distinct healing styles; a 12-raider
    # comp is built around having them.
    var healers := 0
    for r in E.ROLE_KEYS.size():
        if E.role_group_of(r) == E.RoleGroup.HEALER:
            healers += 1
    assert_eq(healers, 3)

# ---------------------------------------------------------------- helpers

func test_iteration_helpers() -> void:
    assert_eq(E.all_classes().size(), 9)
    assert_eq(E.all_rarities().size(), 5)
    assert_eq(E.all_slots().size(), 7)
    assert_eq(E.all_reputation_ranks().size(), 6)
