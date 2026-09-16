extends "res://tests/TestCase.gd"
## sim/model/Stats.gd
##
## The canon-fidelity block is the point of this file: summing the real
## ideaboard armor pieces must reproduce the printed totals exactly. If these
## ever fail, either the transcription or the stat model is wrong — fix the
## code, never the expected numbers.

const S = preload("res://sim/model/Stats.gd")
const E = preload("res://sim/model/Enums.gd")

# ---------------------------------------------------------------- arithmetic

func test_default_is_empty() -> void:
    var s = S.new()
    assert_true(s.is_empty())
    assert_eq(s.ac, 0)
    assert_eq(s.describe(), "—", "an empty block reads as the ideaboard's em-dash")

func test_add_is_non_mutating() -> void:
    var a = S.new(3, 3)
    var b = S.new(5, 6)
    var c = a.add(b)
    assert_eq(c.ac, 8)
    assert_eq(c.hp, 9)
    assert_eq(a.ac, 3, "add() must not mutate the receiver")
    assert_eq(b.ac, 5, "add() must not mutate the argument")

func test_accumulate_mutates_in_place() -> void:
    var a = S.new(1, 2, 3, 4, 5)
    a.accumulate(S.new(10, 20, 30, 40, 50))
    assert_eq([a.ac, a.hp, a.power, a.mana, a.damage], [11, 22, 33, 44, 55])

func test_subtract_for_gear_swap_preview() -> void:
    var equipped = S.new(3, 3, 0, 0, 0)
    var candidate = S.new(5, 5, 1, 0, 0)
    var delta = candidate.subtract(equipped)
    assert_eq(delta.describe(), "2 AC / +2 HP / +1 Power")

func test_scaled() -> void:
    var s = S.new(1, 2, 3, 4, 5).scaled(3)
    assert_eq([s.ac, s.hp, s.power, s.mana, s.damage], [3, 6, 9, 12, 15])

func test_sum_ignores_nulls() -> void:
    var total = S.sum([S.new(1, 1), null, S.new(2, 2)])
    assert_eq(total.ac, 3)
    assert_eq(total.hp, 3)
    assert_eq(S.sum([]).is_empty(), true)

func test_duplicate_is_independent() -> void:
    var a = S.new(4, 4)
    var b = a.duplicate_stats()
    b.accumulate(S.new(1, 1))
    assert_eq(a.ac, 4, "duplicate must not alias")
    assert_eq(b.ac, 5)

func test_equals() -> void:
    assert_true(S.new(1, 2, 3, 4, 5).equals(S.new(1, 2, 3, 4, 5)))
    assert_false(S.new(1, 2, 3, 4, 5).equals(S.new(1, 2, 3, 4, 6)))
    assert_false(S.new().equals(null))

# ---------------------------------------------------------------- access

func test_get_and_set_by_stat_kind() -> void:
    var s = S.new()
    for kind in E.StatKind.values():
        s.set_stat(kind, kind + 10)
    for kind in E.StatKind.values():
        assert_eq(s.get_stat(kind), kind + 10, "stat %s" % E.stat_key(kind))
    assert_eq(s.get_stat(-1), 0, "unknown stat kind reads as zero")

# ---------------------------------------------------------------- serialization

func test_to_dict_omits_zeroes_like_the_ideaboard() -> void:
    # Adventure armor carries no Power; the ideaboard prints "—". An absent key
    # means the item does not carry that stat.
    var d = S.new(3, 3).to_dict()
    assert_eq(d, {"ac": 3, "hp": 3})
    assert_false(d.has("power"))

func test_to_dict_can_include_zeroes() -> void:
    var d = S.new(1).to_dict(true)
    assert_eq(d.size(), 5)
    assert_eq(d["mana"], 0)

func test_round_trip_through_dict() -> void:
    var original = S.new(7, 9, 2, 0, 0)
    var errors := []
    var restored = S.from_dict(original.to_dict(), errors)
    assert_true(restored.equals(original))
    assert_eq(errors.size(), 0)

func test_from_dict_rejects_unknown_keys() -> void:
    # A typo in a content file must fail validation loudly rather than shipping
    # an item that quietly has no armour on it.
    var errors := []
    var s = S.from_dict({"armor": 5, "hp": 3}, errors, "items_t1/raiders_helm")
    assert_eq(errors.size(), 1, "unknown key must be reported")
    assert_true(errors[0].contains("armor"), "error names the offending key")
    assert_true(errors[0].contains("items_t1/raiders_helm"), "error carries context")
    assert_eq(s.hp, 3, "valid keys still parse")

func test_from_dict_rejects_non_numbers_and_fractions() -> void:
    var errors := []
    S.from_dict({"ac": "five"}, errors)
    assert_eq(errors.size(), 1)
    var errors2 := []
    S.from_dict({"ac": 2.5}, errors2)
    assert_eq(errors2.size(), 1, "canon stats are whole numbers")
    var errors3 := []
    var ok = S.from_dict({"ac": 3.0}, errors3)
    assert_eq(errors3.size(), 0, "JSON may deliver whole numbers as floats")
    assert_eq(ok.ac, 3)

# ---------------------------------------------------------------- display

func test_describe_matches_ideaboard_phrasing() -> void:
    # Canon writes e.g. "Raider's Helm — 5 AC / +5 HP / +1 Power"
    assert_eq(S.new(5, 5, 1).describe(), "5 AC / +5 HP / +1 Power")
    assert_eq(S.new(0, 0, 0, 0, 6).describe(), "+6 Damage")
    assert_eq(S.new(2, 0, 0, 5).describe(), "2 AC / +5 Mana")

# ================================================================
# CANON FIDELITY — ideaboard §2 and §3. Do not adjust these numbers.
# ================================================================

func _armor(pieces: Array):
    return S.sum(pieces)

func test_canon_warrior_bard_adventure_armor_totals() -> void:
    # ideaboard §2.1: Helm 3/+3, Cuirass 5/+6, Greaves 4/+4, Boots 3/+3
    var total = _armor([S.new(3, 3), S.new(5, 6), S.new(4, 4), S.new(3, 3)])
    assert_eq(total.ac, 15, "Warrior/Bard adventure AC total")
    assert_eq(total.hp, 16, "Warrior/Bard adventure HP total")
    assert_eq(total.power, 0, "no Power on Tier 1 Adventure armor")
    assert_eq(total.mana, 0)

func test_canon_monk_adventure_armor_totals() -> void:
    # ideaboard §2.2: Ironbound Headband 4/+2, Vest 4/+5, Leggings 3/+4, Boots 3/+3
    var total = _armor([S.new(4, 2), S.new(4, 5), S.new(3, 4), S.new(3, 3)])
    assert_eq(total.ac, 14, "Monk total")
    assert_eq(total.hp, 14)

func test_canon_rogue_adventure_armor_totals() -> void:
    # Same body as Monk, but Reinforced Rogue Eyepatch 3/+2 instead of 4/+2
    var total = _armor([S.new(3, 2), S.new(4, 5), S.new(3, 4), S.new(3, 3)])
    assert_eq(total.ac, 13, "Rogue total")
    assert_eq(total.hp, 14, "Rogue and Monk share the same HP total")

func test_canon_healer_adventure_armor_totals() -> void:
    # ideaboard §2.3: Circlet 2/+2/+3, Robe 3/+5/+5, Leggings 2/+3/+3, Shoes 2/+2/+2
    var total = _armor([
        S.new(2, 2, 0, 3), S.new(3, 5, 0, 5), S.new(2, 3, 0, 3), S.new(2, 2, 0, 2),
    ])
    assert_eq(total.ac, 9, "Healer total AC")
    assert_eq(total.hp, 12, "Healer total HP")
    assert_eq(total.mana, 13, "Healer total Mana")

func test_canon_mage_wizard_adventure_armor_totals() -> void:
    # ideaboard §2.4: Cap 2/+2/+4, Robe 2/+4/+6, Leggings 2/+2/+4, Slippers 2/+2/+3
    var total = _armor([
        S.new(2, 2, 0, 4), S.new(2, 4, 0, 6), S.new(2, 2, 0, 4), S.new(2, 2, 0, 3),
    ])
    assert_eq(total.ac, 8, "Mage/Wizard total AC")
    assert_eq(total.hp, 10)
    assert_eq(total.mana, 17, "the highest Mana total in Tier 1 Adventure")

func test_canon_adventure_ac_ordering_across_armor_families() -> void:
    # The five families must stay ordered 15 > 14 > 13 > 9 > 8. This ordering is
    # the whole armor-weight design; an itemization change that inverts it is a bug.
    var totals := [15, 14, 13, 9, 8]
    for i in range(totals.size() - 1):
        assert_true(totals[i] > totals[i + 1], "armor family AC ordering")

func test_canon_starting_armor_ac_totals() -> void:
    # raw notes, *Starting armor for common recruits*
    var expected := {
        "warrior": [[1, 3, 2, 1], 7], "bard": [[1, 3, 2, 1], 7],
        "monk": [[2, 2, 1, 1], 6], "rogue": [[1, 2, 1, 1], 5],
        "cleric": [[1, 2, 1, 1], 5], "druid": [[1, 2, 1, 1], 5],
        "shaman": [[1, 2, 1, 1], 5], "mage": [[1, 1, 1, 1], 4],
        "wizard": [[1, 1, 1, 1], 4],
    }
    for cls in expected.keys():
        var pieces: Array = expected[cls][0]
        var want: int = expected[cls][1]
        var blocks := []
        for ac_value in pieces:
            blocks.append(S.new(ac_value))
        assert_eq(S.sum(blocks).ac, want, "%s starting AC" % cls)

func test_canon_tier1_raid_warrior_full_set() -> void:
    # ideaboard §3.1 — Helm 5/+5/+1, Cuirass 7/+9/+2, Greaves 5/+6/+1,
    # Boots 4/+4, Warrior Shield 7/+8/+1
    var armor_only = S.sum([S.new(5, 5, 1), S.new(7, 9, 2), S.new(5, 6, 1), S.new(4, 4)])
    assert_eq(armor_only.ac, 21, "four raid armor pieces (docs/09 §8.11 cites 21 AC)")
    assert_eq(armor_only.hp, 24)
    assert_eq(armor_only.power, 4)

    var with_shield = armor_only.add(S.new(7, 8, 1))
    assert_eq(with_shield.ac, 28, "docs/09 cites 28 AC with the Boss 5 shield")
    assert_eq(with_shield.hp, 32)
    assert_eq(with_shield.power, 5)

func test_canon_tier1_raid_beats_adventure_for_every_family() -> void:
    # Raid gear must strictly out-stat Adventure gear or the loot ladder inverts.
    var warrior_adv = 15
    var warrior_raid = S.sum([S.new(5, 5, 1), S.new(7, 9, 2), S.new(5, 6, 1), S.new(4, 4)]).ac
    assert_true(warrior_raid > warrior_adv, "Warrior raid AC %d must beat adventure %d"
        % [warrior_raid, warrior_adv])

    # Healer: Circlet 3/+4/+7, Vestments 4/+7/+10, Leggings 3/+4/+6, Shoes 3/+4/+4
    var healer_raid = S.sum([
        S.new(3, 4, 0, 7), S.new(4, 7, 0, 10), S.new(3, 4, 0, 6), S.new(3, 4, 0, 4),
    ])
    assert_eq(healer_raid.ac, 13)
    assert_eq(healer_raid.hp, 19)
    assert_eq(healer_raid.mana, 27)
    assert_true(healer_raid.ac > 9 and healer_raid.mana > 13, "healer raid beats adventure")

func test_canon_weapon_damage_values() -> void:
    # raw notes, *Weapons*; ideaboard §3 raid weapon rows.
    assert_eq(S.new(0, 0, 0, 0, 5).damage, 5, "Iron Adventurer's Sword")
    assert_eq(S.new(0, 0, 0, 0, 9).damage, 9, "Iron Adventurer's Staff (Monk)")
    assert_eq(S.new(0, 0, 0, 0, 10).damage, 10, "Apprentice's Firestaff / Arcstaff")
    # Rogue dual-wields: two Basic Raid Daggers at +4 each.
    assert_eq(S.sum([S.new(0, 0, 0, 0, 4), S.new(0, 0, 0, 0, 4)]).damage, 8,
        "Rogue's two hands total +8 at Boss 1")
    assert_eq(S.sum([S.new(0, 0, 0, 0, 6), S.new(0, 0, 0, 0, 6)]).damage, 12,
        "Rogue's two Strong Raid Daggers total +12")

func test_canon_trinket_values() -> void:
    # raw notes, *Trinkets* — Tier 1 Adventure.
    assert_eq(S.new(0, 7).hp, 7, "Adventure's Charm of Health")
    assert_eq(S.new(2).ac, 2, "Adventure's Charm of Armor")
    assert_eq(S.new(0, 0, 0, 10).mana, 10, "Adventure's Charm of Mana")
    assert_eq(S.new(0, 0, 2).power, 2, "Adventures Charm of Power")

func test_canon_bard_instrument_mana() -> void:
    # ideaboard §3.2 — the Bard's Boss 5 capstone is +20 Mana, the single
    # largest Mana value in Tier 1. docs/06 flags what it should do as OPEN.
    assert_eq(S.new(0, 0, 0, 20).mana, 20, "Bard Instrument")
