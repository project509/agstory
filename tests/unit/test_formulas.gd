extends "res://tests/TestCase.gd"
## sim/core/Formulas.gd — the arithmetic every other number quotes.
##
## Most of these are docs/08's own worked examples. The valuable ones are the
## cross-checks: docs/10 §5.4 and §7.5 publish tank-take and mitigation figures
## computed from these formulas by hand, so if the code and the content tables
## ever disagree, one of them is wrong and these fail. That is the whole point
## of having a single owner for the arithmetic.

const F = preload("res://sim/core/Formulas.gd")
const Rng = preload("res://sim/core/Rng.gd")
const E = preload("res://sim/model/Enums.gd")

# ---------------------------------------------------------------- mitigation

func test_mitigation_curve_matches_doc_08_reading_3() -> void:
    # mitigation = (AC*2) / ((AC*2) + 60), capped at 0.75
    assert_almost(F.mitigation(17), 0.3617, 0.0005, "tank at Raid 1 entry")
    assert_almost(F.mitigation(23), 0.4340, 0.0005, "tank fully geared")
    assert_almost(F.mitigation(8), 0.2105, 0.0005, "Mage in Adventure gear")
    assert_almost(F.mitigation(13), 0.3023, 0.0005, "Wizard in Raid gear")
    assert_almost(F.mitigation(0), 0.0, 0.0001, "no armour, no mitigation")

func test_mitigation_is_capped() -> void:
    # Without a cap, tiers 4-5 AC would trivialise every earlier fight.
    assert_almost(F.mitigation(100000), F.MITIGATION_CAP, 0.0001)
    assert_true(F.mitigation(500) <= F.MITIGATION_CAP)

func test_mitigation_rises_monotonically_with_ac() -> void:
    var prev := -1.0
    for ac in range(0, 40):
        var m := F.mitigation(ac)
        assert_true(m >= prev, "mitigation must not fall as AC rises (AC %d)" % ac)
        prev = m

func test_tank_take_matches_doc_10_escalation_table() -> void:
    # docs/10 §5.4 publishes these by hand from docs/08 §9.3's raw swings.
    # [tank AC, raw per round, expected post-mitigation per round]
    var rows := [
        [17, 55.0, 35.1], [18, 58.0, 36.2], [19, 62.0, 38.0],
        [21, 68.0, 40.0], [23, 74.0, 41.9],
    ]
    for row in rows:
        var ac: int = row[0]
        var raw: float = row[1]
        var got := raw * (1.0 - F.mitigation(ac))
        assert_almost(got, row[2], 0.15,
            "AC %d vs %.0f raw should land near %.1f" % [ac, raw, row[2]])

func test_cloth_take_matches_doc_10_table() -> void:
    # The same table's "post-mit/swing on a Mage (8 AC)" column — the number that
    # shows why one-swing bosses are the deadliest shape for cloth.
    assert_almost(55.0 * (1.0 - F.mitigation(8)), 43.4, 0.15, "E1 swing on a Mage")
    assert_almost(58.0 * (1.0 - F.mitigation(8)), 45.8, 0.15, "E2 swing on a Mage")
    assert_almost(37.0 * (1.0 - F.mitigation(8)), 29.2, 0.15, "E5 split swing on a Mage")

func test_worked_failure_trace_from_doc_10() -> void:
    # docs/10 §7.5's trace, the one written for a programmer to check.
    # A retargeted E5 swing onto a fully ramped Wizard at 13 AC.
    assert_eq(F.damage_after_ac(37.0, 13), 26, "37 raw on 13 AC")
    # The same swing on the 23 AC tank it was meant for.
    assert_eq(F.damage_after_ac(37.0, 23), 21, "37 raw on 23 AC")
    # Two swings on the tank is the sustainable 41.9/round.
    assert_eq(F.damage_after_ac(37.0, 23) * 2, 42)

func test_damage_is_floored_at_one() -> void:
    # A landed hit never does nothing, no matter the armour.
    assert_eq(F.damage_after_ac(1.0, 200), 1)
    assert_true(F.damage_after_ac(0.4, 0) >= 1)

func test_raid_wide_damage_ignores_armour() -> void:
    # docs/10 §5.4: pressure must land on healer throughput, not on tank gear.
    assert_eq(F.raid_wide_damage(26.0), 26)
    assert_eq(F.raid_wide_damage(28.0), 28)

func test_alternate_ac_readings_are_implemented_not_stubs() -> void:
    # The OPEN in docs/08 §3 is resolvable by changing one constant, so the
    # other readings have to actually work.
    assert_true(F.AcReading.FLAT_TWO_PER_POINT != F.AcReading.CURVE)
    # docs/10 §5.4 states a 30 AC Warrior mitigates 50% under this reading —
    # comfortably below the cap, which is what leaves headroom for tiers 2-5.
    assert_almost(F.mitigation(30), 0.50, 0.005, "30 AC is half, not the cap")
    assert_true(F.mitigation(30) < F.MITIGATION_CAP,
        "Tier 1 must not already be sitting on the mitigation ceiling")

# ------------------------------------------------- every AcReading, three ACs
#
# DW-B2. `mitigation()` used to return a bare 0.0 under both flat readings, so
# two of the four selectable settings produced a game with literally no armour
# and nothing failed. These pin all four readings at the same three canon AC
# values — a Mage's 8, a Warrior's 15, a shielded raid tank's 28 (docs/08 §3.1's
# own table) — so no future edit to the switch can zero anyone's armour quietly.

const _READINGS := [F.AcReading.CURVE, F.AcReading.FLAT_TWO_PER_POINT,
    F.AcReading.FLAT_HALF_AC, F.AcReading.DIVISOR]

## The fraction a hit of `raw` actually loses, measured off the one function
## that implements every reading. For the flat readings this is the only
## honest way to state a mitigation figure at all.
func _mit_at(reading: int, raw: float, ac: int) -> float:
    return 1.0 - (float(F.damage_after_ac_under(reading, raw, ac)) / raw)

func test_reading_3_curve_mitigation_at_three_ac_values() -> void:
    # docs/08 §3.3's published table for AC_K = 60.
    assert_almost(F.mitigation_under(F.AcReading.CURVE, 8), 0.2105, 0.0005, "Mage 8 AC")
    assert_almost(F.mitigation_under(F.AcReading.CURVE, 15), 0.3333, 0.0005, "Warrior 15 AC")
    assert_almost(F.mitigation_under(F.AcReading.CURVE, 28), 0.4828, 0.0005, "tank + Shield")

func test_reading_1_flat_two_per_point_mitigation_at_three_ac_values() -> void:
    # No constant fraction exists, so the reading refuses rather than answering
    # zero — that refusal is the fix for DW-B2.
    assert_true(is_nan(F.mitigation_under(F.AcReading.FLAT_TWO_PER_POINT, 15)),
        "a flat reading has no f(ac) mitigation and must say so")
    # Measured against §3.2's window proof: 47 raw is the T1 Adventure swing
    # that kills the 15 AC tank in 8, and it takes the 8 AC Mage in 2.4.
    var r := F.AcReading.FLAT_TWO_PER_POINT
    assert_eq(F.damage_after_ac_under(r, 47.0, 8), 31, "Mage takes 47 - 16")
    assert_eq(F.damage_after_ac_under(r, 47.0, 15), 17, "Warrior takes 47 - 30")
    assert_eq(F.damage_after_ac_under(r, 47.0, 28), 5, "28 AC out-armours the hit: 10% floor")
    assert_almost(_mit_at(r, 47.0, 8), 0.3404, 0.0005)
    assert_almost(_mit_at(r, 47.0, 15), 0.6383, 0.0005)
    assert_almost(_mit_at(r, 47.0, 28), 0.8936, 0.0005)
    # §3.2's T1 Raid row, the one that rejected this reading: 75 raw kills the
    # tank in 8 and the Mage in 1.65.
    assert_eq(F.damage_after_ac_under(r, 75.0, 28), 19)
    assert_eq(F.damage_after_ac_under(r, 75.0, 13), 49)

func test_reading_1b_flat_half_ac_mitigation_at_three_ac_values() -> void:
    var r := F.AcReading.FLAT_HALF_AC
    assert_true(is_nan(F.mitigation_under(r, 15)), "still flat, still no f(ac)")
    assert_eq(F.damage_after_ac_under(r, 47.0, 8), 43, "docs/08 §3.3: Mage reduction 4")
    assert_eq(F.damage_after_ac_under(r, 47.0, 15), 40, "docs/08 §3.3: Warrior reduction 7")
    assert_eq(F.damage_after_ac_under(r, 47.0, 28), 33, "reduction 14")
    assert_almost(_mit_at(r, 47.0, 8), 0.0851, 0.0005)
    assert_almost(_mit_at(r, 47.0, 15), 0.1489, 0.0005)
    assert_almost(_mit_at(r, 47.0, 28), 0.2979, 0.0005)
    # docs/08 §3.3's own complaint about this reading, made executable: the
    # canon 1-point Warrior/Monk gap vanishes under floor(AC / 2).
    assert_eq(F.damage_after_ac_under(r, 47.0, 14), F.damage_after_ac_under(r, 47.0, 15))
    # docs/08 §3.3 writes `max(raw - floor(AC/2), ceil(raw * MIN_HIT_FRACTION))`
    # for this reading exactly as for Reading 1. The floor used to be a bare 1
    # here, which is a different reading from the published one.
    assert_eq(F.damage_after_ac_under(r, 40.0, 200), 4, "10% of 40, not 1")

func test_reading_2_divisor_mitigation_at_three_ac_values() -> void:
    var r := F.AcReading.DIVISOR
    assert_almost(F.mitigation_under(r, 8), 0.7500, 0.0005, "divide by 4")
    assert_almost(F.mitigation_under(r, 15), 0.8667, 0.0005, "divide by 7.5")
    assert_almost(F.mitigation_under(r, 28), 0.9286, 0.0005, "divide by 14")
    # MITIGATION_CAP belongs to Reading 3 only. Capping this one at 0.75 broke
    # §3.2's window proof, which is the arithmetic that rejected the reading —
    # a rejected option has to stay reproducible or the rejection is unchecked.
    assert_true(F.mitigation_under(r, 15) > F.MITIGATION_CAP)
    assert_eq(F.damage_after_ac_under(r, 127.5, 15), 17, "§3.2 T1 Adventure tank")
    assert_eq(F.damage_after_ac_under(r, 127.5, 8), 32, "§3.2 T1 Adventure Mage, 31.9")
    assert_eq(F.damage_after_ac_under(r, 266.0, 28), 19, "§3.2 T1 Raid tank")
    assert_eq(F.damage_after_ac_under(r, 266.0, 13), 41, "§3.2 T1 Raid Mage, 40.9")
    # docs/08's "a 0 AC recruit divides by zero" con is guarded, not reproduced.
    assert_eq(F.damage_after_ac_under(r, 40.0, 0), 40, "no armour, no division")
    assert_eq(F.damage_after_ac_under(r, 40.0, 1), 40, "AC below 2 must not amplify")

func test_no_reading_can_silently_report_no_armour() -> void:
    # The DW-B2 defect in one assertion: a reading either states a real constant
    # fraction or refuses with NAN. A bare 0.0 reads to every caller as "this
    # raider is wearing nothing", and that is what shipped for two of the four.
    for reading in _READINGS:
        var r: int = reading
        var m := F.mitigation_under(r, 15)
        assert_false(m == 0.0, "reading %d reports a 15 AC tank as unarmoured" % r)
        if F.reading_is_proportional(r):
            assert_true(m > 0.0, "reading %d must mitigate a 15 AC tank" % r)
        else:
            assert_true(is_nan(m), "flat reading %d must refuse, not answer" % r)
        # However it is expressed, armour must reduce the hit under every reading.
        assert_true(F.damage_after_ac_under(r, 47.0, 15) < F.damage_after_ac_under(r, 47.0, 0),
            "reading %d gives 15 AC no benefit at all" % r)

func test_every_reading_is_monotonic_in_ac() -> void:
    for reading in _READINGS:
        var r: int = reading
        var prev := 999999
        for ac in range(0, 40):
            var dealt := F.damage_after_ac_under(r, 60.0, ac)
            assert_true(dealt <= prev,
                "reading %d: damage rose from %d at AC %d" % [r, prev, ac])
            prev = dealt

func test_mitigation_helpers_cannot_diverge_from_damage_after_ac() -> void:
    # The two entry points must describe the same armour. This is the guard that
    # would have caught DW-B2: under a flat reading `mitigation()` said 0.0
    # while `damage_after_ac()` was subtracting 30, and nothing compared them.
    for raw in [12.0, 37.0, 55.0, 127.5]:
        for ac in [0, 8, 15, 23, 28]:
            var dealt := F.damage_after_ac(raw, ac)
            var via_at := int(round(raw * (1.0 - F.mitigation_at(raw, ac))))
            assert_eq(via_at, dealt, "mitigation_at disagrees at %.1f raw / %d AC" % [raw, ac])
            if F.reading_is_proportional(F.AC_READING):
                var via_const := int(round(raw * (1.0 - F.mitigation(ac))))
                assert_true(absi(via_const - dealt) <= 1,
                    "mitigation(%d) disagrees with damage_after_ac at %.1f raw" % [ac, raw])

func test_no_reading_can_diverge_from_its_own_mitigation_fraction() -> void:
    # The same convergence check as above, but under all four readings rather
    # than only the live one — which is the divergence class DW-B2 is actually
    # about. `mitigation_under` and `damage_after_ac_under` are two separately
    # written expressions: Reading 2 is `1 - 1/max(1, ac/2)` in one and
    # `raw / max(1, ac/2)` in the other, and until this loop existed nothing but
    # their own hardcoded literals held them together.
    #
    # docs/08 §3.1's canon AC values, and §3.2's window-proof raws.
    for reading in _READINGS:
        var r: int = reading
        for ac in [8, 15, 28]:
            var m := F.mitigation_under(r, ac)
            if F.reading_is_proportional(r):
                for raw in [12.0, 37.0, 47.0, 127.5]:
                    # docs/08 §3.3's Reading 3 line includes the §8.4 floor.
                    var expect := maxi(1, int(round(raw * (1.0 - m))))
                    assert_eq(expect, F.damage_after_ac_under(r, raw, ac),
                        "reading %d: the constant fraction at %d AC does not reproduce"
                        % [r, ac] + " damage_after_ac_under at %.1f raw" % raw)
            else:
                # A flat reading refuses (NAN) precisely because no constant
                # fraction exists, so prove that here rather than trusting it:
                # a fixed subtraction is a far larger share of a small hit.
                assert_true(is_nan(m), "flat reading %d must refuse" % r)
                var small := _mit_at(r, 12.0, ac)
                var large := _mit_at(r, 127.5, ac)
                assert_true(small > large + 0.05,
                    "reading %d at %d AC looks proportional (%.4f vs %.4f) — if it"
                    % [r, ac, small, large] + " really is, mitigation_under must answer")

func test_mitigation_at_agrees_with_the_damage_floor_below_one_raw() -> void:
    # Below 1 raw, docs/08 §8.4's floor deals more than the hit was worth, so
    # the honest fraction goes NEGATIVE. That is deliberate: it is the only
    # value under which the helper and `damage_after_ac` still describe the same
    # armour, and a clamp at 0.0 would re-create DW-B2 in the other direction.
    for ac in [0, 8, 15, 28]:
        for raw in [0.25, 0.5, 0.75, 1.0, 2.0]:
            var dealt := F.damage_after_ac(raw, ac)
            assert_eq(int(round(raw * (1.0 - F.mitigation_at(raw, ac)))), dealt,
                "mitigation_at disagrees at %.2f raw / %d AC" % [raw, ac])
    assert_almost(F.mitigation_at(0.5, 0), -1.0, 0.0001,
        "0.5 raw floored to 1 damage is -100% mitigation, reported as such")
    # `raw == 0` is the documented seam: no fraction of nothing to report, while
    # the floor still answers for a landed hit.
    assert_eq(F.mitigation_at(0.0, 15), 0.0)
    assert_eq(F.damage_after_ac(0.0, 15), 1)

func test_an_unknown_reading_int_is_guarded_at_both_entry_points() -> void:
    # Both fall-throughs deliberately push_error — the two stderr lines this
    # test prints ARE the assertion. `mitigation_under` used to fall off the end
    # of its match and return a bare NAN, which is exactly what a legitimate
    # flat reading returns, so a typo'd reading looked like Reading 1.
    var bogus := 99
    assert_false(_READINGS.has(bogus), "99 must stay outside AcReading")
    assert_eq(F.damage_after_ac_under(bogus, 47.0, 15), 47,
        "an unknown reading must fall back to unmitigated damage, not invent armour")
    assert_true(is_nan(F.mitigation_under(bogus, 15)),
        "and must report no fraction at all")

# ---------------------------------------------------------------- melee

func test_rogue_melee_worked_example() -> void:
    # docs/08 §8.2: T1 Raid Rogue, Strong Raid Daggers +6/+6, Power +5.
    #   main = (6*1.00 + 5) * 0.95 = 10.45
    #   off  = (6*0.75 + 5) * 0.95 =  9.03
    #   round = 2 * (10.45 + 9.03) = 38.96
    var dps := F.melee_damage_per_round(E.CharClass.ROGUE, 6, 6, 5, true)
    assert_almost(dps, 38.95, 0.05, "Rogue round output")

func test_power_is_added_once_per_swing_not_once_per_round() -> void:
    # docs/08 §8.2 calls this out: it is what makes Raid-tier Power meaningful.
    var no_power := F.melee_damage_per_round(E.CharClass.WARRIOR, 8, 0, 0, false)
    var with_power := F.melee_damage_per_round(E.CharClass.WARRIOR, 8, 0, 5, false)
    assert_almost(with_power - no_power, 10.0, 0.01,
        "5 Power across 2 swings is +10, not +5")

func test_dual_wield_offhand_is_discounted() -> void:
    var single := F.melee_damage_per_round(E.CharClass.ROGUE, 6, 6, 5, false)
    var dual := F.melee_damage_per_round(E.CharClass.ROGUE, 6, 6, 5, true)
    assert_true(dual > single, "a second weapon must help")
    assert_true(dual < single * 2.0, "but the off hand is discounted, not free")

func test_non_melee_classes_deal_no_melee_damage() -> void:
    for cls in [E.CharClass.MAGE, E.CharClass.WIZARD, E.CharClass.CLERIC,
                E.CharClass.DRUID, E.CharClass.SHAMAN]:
        assert_almost(F.melee_damage_per_round(cls, 10, 0, 10, false), 0.0, 0.001,
            "%s should not melee" % E.class_name_of(cls))

func test_class_melee_ordering_matches_canon_roles() -> void:
    # Monk is canon "High DPS"; Rogue melee DPS; Bard support, so lowest.
    assert_true(F.CLASS_MELEE_COEF[E.CharClass.MONK] > F.CLASS_MELEE_COEF[E.CharClass.WARRIOR])
    assert_true(F.CLASS_MELEE_COEF[E.CharClass.WARRIOR] > F.CLASS_MELEE_COEF[E.CharClass.ROGUE])
    assert_true(F.CLASS_MELEE_COEF[E.CharClass.ROGUE] > F.CLASS_MELEE_COEF[E.CharClass.BARD])

# ---------------------------------------------------------------- spells

func test_wizard_spell_worked_example() -> void:
    # docs/08 §8.3: Strong Raid Staff +16, 44 Mana.
    #   power = 16 + (44 * 0.35) = 31.4 ; cast = 31.4 * 1.60 = 50.24
    assert_almost(F.spell_power(16, 44), 31.4, 0.01)
    assert_almost(F.spell_damage(E.CharClass.WIZARD, 16, 44), 50.24, 0.05)

func test_mage_is_per_target() -> void:
    # docs/08 §8.3: 18.2 on one target, 91 across five. Canon calls the Mage an
    # AoE caster, so its output is a function of how many things it can hit.
    assert_almost(F.spell_damage(E.CharClass.MAGE, 15, 44), 18.24, 0.05)
    assert_almost(F.spell_damage_total(E.CharClass.MAGE, 15, 44, 5), 91.2, 0.2)

func test_wizard_beats_mage_single_target_by_a_wide_margin() -> void:
    # Canon: Wizard "Very high single-target DPS"; Mage "AoE".
    var wiz := F.spell_damage(E.CharClass.WIZARD, 16, 44)
    var mage := F.spell_damage(E.CharClass.MAGE, 15, 44)
    assert_true(wiz > mage * 2.5, "single target should be the Wizard's whole identity")

func test_bard_deals_no_spell_damage() -> void:
    # Bard songs are docs/06's, not spell damage.
    assert_almost(F.spell_damage(E.CharClass.BARD, 20, 40), 0.0, 0.001)

# ---------------------------------------------------------------- healing

func test_adventure_healer_worked_example() -> void:
    # docs/08 §8.5: heal_base 14, 23 Mana -> heal_power 32.4
    assert_almost(F.heal_power(14, 23), 32.4, 0.01)
    assert_eq(F.cleric_heal(14, 23), 32, "single target, rounded once")
    assert_eq(F.druid_raid_heal(14, 23), 8, "32.4 * 0.25 per raider")
    assert_eq(F.shaman_chain_heal(14, 23), [21, 21, 11], "medium, medium, small")

func test_raid_healer_worked_example() -> void:
    # docs/08 §8.5: heal_base 22, 42 Mana -> heal_power 55.6
    assert_almost(F.heal_power(22, 42), 55.6, 0.01)
    assert_eq(F.cleric_heal(22, 42), 56)
    assert_eq(F.druid_raid_heal(22, 42), 14)
    var chain: Array = F.shaman_chain_heal(22, 42)
    assert_eq(chain[0], 36)
    assert_eq(chain[2], 19, "the third bounce is the small one")

func test_shaman_chain_is_canon_medium_medium_small() -> void:
    var chain: Array = F.shaman_chain_heal(20, 40)
    assert_eq(chain.size(), 3, "canon describes exactly three bounces")
    assert_eq(chain[0], chain[1], "medium then medium — the same size")
    assert_true(chain[2] < chain[1], "then small")

func test_a_weaponless_healer_still_heals_something() -> void:
    # docs/15 BL-27. This test previously asserted `cleric_heal(0, 0) == 1` — it
    # encoded the bug as expected behaviour while its own comment explained why
    # the behaviour was wrong. Canon starting armour carries no weapon and no
    # Mana, so a purely gear-derived heal was exactly zero and every healer in a
    # fresh guild was decorative. HEAL_FLOOR is what fixes it.
    assert_eq(F.cleric_heal(0, 0), F.HEAL_FLOOR,
        "a weaponless, 0-Mana healer falls back to the class floor")
    assert_true(F.HEAL_FLOOR > 1, "the floor has to be worth casting")

func test_the_heal_floor_never_raises_a_geared_healer() -> void:
    # The floor is a FLOOR, not an addend. This is the property that let BL-27 be
    # fixed without moving a single validated geared number — E5's 22-round
    # first clear is byte-identical across this change.
    assert_eq(F.cleric_heal(14, 0), 14, "a real weapon dominates the floor exactly")
    assert_eq(F.cleric_heal(14, 23), int(round(14.0 + 23.0 * F.MANA_TO_HEAL)),
        "docs/08 §8.5's formula is untouched above the floor")

func test_the_unarmed_floor_applies_to_the_main_hand_only() -> void:
    # An empty off-hand must stay empty, or every dual-wielder would gain a
    # phantom second weapon they never picked up.
    assert_eq(F.effective_main_damage(0), F.UNARMED_DAMAGE)
    assert_eq(F.effective_main_damage(5), 5, "a real weapon is never reduced")
    var unarmed := F.melee_damage_per_round(E.CharClass.ROGUE, 0, 0, 0, true)
    var one_handed := F.melee_damage_per_round(E.CharClass.ROGUE, 0, 0, 0, false)
    assert_eq(unarmed, one_handed,
        "an empty off-hand contributes nothing even for a dual-wielder")

func test_the_floors_are_a_fraction_of_the_first_real_item() -> void:
    # The first weapon a raider ever picks up must be a visible upgrade, or the
    # floor has quietly become the progression.
    assert_true(F.UNARMED_DAMAGE < 5,
        "the Tier 1 Adventure sword is +5 damage; unarmed must be clearly worse")
    assert_true(F.HEAL_FLOOR < 14,
        "the Tier 1 Adventure healing weapon is heal_base 14")

func test_druid_throughput_is_large_only_because_the_raid_is_twelve() -> void:
    # docs/08 §8.5 flags this for the balance pass: it is an artifact of raid
    # size, not power, and only realises when everyone is damaged.
    var per_target := F.druid_raid_heal(22, 42)
    assert_true(per_target * E.RAID_SIZE > F.cleric_heal(22, 42),
        "total raid throughput exceeds a single-target heal")
    assert_true(per_target < F.cleric_heal(22, 42),
        "but per raider it is much smaller — canon calls it a small heal")
    assert_true(F.DRUID_RAID_COEF <= 0.30,
        "docs/08 warns against raising this without re-checking the AoE budget")

# ---------------------------------------------------------------- variance

func test_variance_ships_off_and_consumes_no_rng() -> void:
    # docs/08 §8.6 recommends shipping deterministic: the drama comes from
    # mistake rolls and morale, not damage dice, and a readable log makes
    # "why did we wipe" answerable. Critically, a draw taken here would shift
    # every downstream roll and invalidate golden files.
    var rng = Rng.new(42)
    assert_almost(F.apply_variance(100.0, rng), 100.0, 0.0001)
    assert_eq(rng.draws, 0, "variance must not consume the RNG stream while off")

func test_variance_constants_are_the_conservative_default() -> void:
    assert_almost(F.DAMAGE_VARIANCE, 0.0, 0.0001)
    assert_eq(F.CRIT_CHANCE_BP, 0)

# ---------------------------------------------------------------- threat

func test_warrior_threat_worked_example() -> void:
    # docs/08 §8.7 sanity check: 30.0 damage x 3.00 = 90 threat per round.
    assert_almost(F.threat_from(E.CharClass.WARRIOR, 30.0), 90.0, 0.01)

func test_a_tank_out_threatens_the_best_dps_by_arithmetic_alone() -> void:
    # docs/08 §8.7: a tank should never lose aggro to arithmetic, only to a
    # mistake or a mechanic. That is the correct feel for this game.
    var warrior := F.threat_from(E.CharClass.WARRIOR, 30.0)
    var wizard := F.threat_from(E.CharClass.WIZARD, 50.2)
    var rogue := F.threat_from(E.CharClass.ROGUE, 46.6)
    assert_true(warrior > wizard, "the Warrior must lead the highest-DPS class")
    assert_almost(warrior / wizard, 1.79, 0.05, "docs/08 cites 1.79x")
    assert_true(warrior > rogue)

func test_healing_generates_threat_but_less_than_damage() -> void:
    assert_almost(F.threat_from(E.CharClass.CLERIC, 0.0, 55.6), 27.8, 0.05)
    assert_almost(F.threat_from(E.CharClass.CLERIC, 100.0), 0.0, 0.001,
        "healers generate no damage-side threat")

func test_tank_lead_taunt_and_the_pull_are_the_docs_numbers() -> void:
    # docs/07 §8.1-8.2 (W7-SIM-EFFECTS): Tank Lead 1.30, Taunt 1.10 x highest,
    # and MIS_AGGRO past the offender's own retarget bar.
    assert_almost(F.TANK_LEAD_RATIO, 1.30, 0.0001)
    assert_almost(F.TAUNT_RATIO, 1.10, 0.0001)
    assert_true(F.tank_lead_held(130.0, 100.0), "at exactly 1.30x the tank is stable")
    assert_false(F.tank_lead_held(129.0, 100.0))
    assert_true(F.tank_lead_held(0.0, 0.0), "nobody has threat: nothing to lose")
    assert_eq(F.taunt_threat(100.0), 111, "ceil(110) + 1: strictly past the melee bar")
    assert_true(F.should_retarget(float(F.taunt_threat(100.0)), 100.0, true),
        "a taunt always brings the boss back")
    assert_eq(F.taunt_threat(0.0), 1)
    assert_eq(F.aggro_pull_threat(100.0, true), 111)
    assert_eq(F.aggro_pull_threat(100.0, false), 131)
    for top in [1.0, 37.0, 100.0, 999.0]:
        for melee in [true, false]:
            assert_true(F.should_retarget(float(F.aggro_pull_threat(top, melee)), top, melee),
                "a pull at top %.0f (melee %s) clears the bar" % [top, str(melee)])
    assert_almost(F.retarget_threshold(true), F.TAUNT_THRESHOLD_MELEE, 0.0001)
    assert_almost(F.retarget_threshold(false), F.TAUNT_THRESHOLD_RANGED, 0.0001)

func test_retarget_thresholds() -> void:
    # Ranged candidates need a bigger lead to pull, which protects casters.
    assert_false(F.should_retarget(105.0, 100.0, true), "5% is not enough in melee")
    assert_true(F.should_retarget(111.0, 100.0, true), "11% pulls in melee")
    assert_false(F.should_retarget(120.0, 100.0, false), "20% is not enough at range")
    assert_true(F.should_retarget(131.0, 100.0, false), "31% pulls at range")

# ---------------------------------------------------------------- policy

func test_the_dps_tax_is_the_progression_currency() -> void:
    # docs/08 §8.8: a raid of Content Commons runs at 78% of nominal; Very Happy
    # Epics at ~97.5%. That 19.5-point spread is the game's core progression and
    # it costs nothing in stats.
    assert_almost(F.effective_output(100.0, 0.22), 78.0, 0.01, "Content Commons")
    assert_almost(F.effective_output(100.0, 0.025), 97.5, 0.01, "Very Happy Epics")
    assert_almost(F.effective_output(100.0, 0.0), 100.0, 0.01)

func test_final_values_round_once_half_up() -> void:
    assert_eq(F.final_value(2.4), 2)
    assert_eq(F.final_value(2.5), 3)
    assert_eq(F.final_value(2.6), 3)

func test_switches_are_single_named_constants() -> void:
    # The two canon ambiguities must each be resolvable by editing one line.
    assert_eq(F.AC_READING, F.AcReading.CURVE, "docs/15 Q-01 ruled Reading 3")
    assert_eq(F.MANA_MODEL, F.ManaModel.MAGNITUDE_PLUS_FOCUS, "docs/15 Q-02 ruled Model A+")
    assert_almost(F.AC_K, 60.0, 0.001)

# ================================================================ mistakes
#
# The single most important number in the game. docs/08 §8.8 and docs/05 §5.1
# published forked models disagreeing ~2x; docs/15 Q-04/05 resolved it as
# docs/05's shape and coefficients living at docs/08's ownership location.
# These tests pin all fifty cells of docs/05 §5.4's matrix.

func _pct(rarity: int, band_morale: int) -> float:
    return F.mistake_chance(rarity, band_morale) * 100.0

func test_mistake_matrix_matches_doc_05_exactly() -> void:
    # docs/05 §5.4, rarity x band. Morale values pick the middle of each band.
    var morale_for_band := [5, 15, 25, 35, 45, 55, 65, 75, 85, 95]
    var expected := {
        E.Rarity.COMMON:    [81.6, 64.3, 49.9, 38.4, 29.8, 24.0, 20.5, 17.7, 15.4, 13.9],
        E.Rarity.UNCOMMON:  [46.5, 37.1, 29.2, 22.9, 18.2, 15.0, 13.1, 11.5, 10.3,  9.5],
        E.Rarity.RARE:      [22.4, 18.1, 14.5, 11.6,  9.4,  8.0,  7.1,  6.4,  5.8,  5.5],
        E.Rarity.EPIC:      [ 8.4,  6.9,  5.7,  4.7,  4.0,  3.5,  3.2,  3.0,  2.8,  2.6],
        E.Rarity.LEGENDARY: [2.40, 2.04, 1.74, 1.50, 1.32, 1.20, 1.13, 1.07, 1.02, 0.99],
    }
    for rarity in expected.keys():
        for band in 10:
            assert_almost(_pct(rarity, morale_for_band[band]), expected[rarity][band], 0.06,
                "%s at band %d" % [E.rarity_name_of(rarity), band])

func test_canon_legendary_is_near_one_percent() -> void:
    # The only mistake number canon actually states: "near 1% chance of mistake".
    # At best morale a Legendary lands on 0.99%, about as near as it gets.
    assert_almost(_pct(E.Rarity.LEGENDARY, 95), 0.99, 0.02)
    assert_almost(_pct(E.Rarity.LEGENDARY, 55), 1.20, 0.02, "and 1.2% at Content")

func test_content_band_is_the_unmodified_base() -> void:
    # Canon calls 50-60 "Base mistake chance", so the multiplier must vanish there.
    assert_almost(_pct(E.Rarity.COMMON, 55), 24.0, 0.02)
    assert_almost(_pct(E.Rarity.EPIC, 55), 3.5, 0.02)

func test_mistake_chance_falls_monotonically_as_morale_rises() -> void:
    for rarity in E.all_rarities():
        var prev := 101.0
        for m in [5, 15, 25, 35, 45, 55, 65, 75, 85, 95]:
            var p := _pct(rarity, m)
            assert_true(p < prev, "%s: chance must fall as morale rises (at %d)"
                % [E.rarity_name_of(rarity), m])
            prev = p

func test_sensitivity_falls_as_rarity_rises() -> void:
    # This IS canon's "legendary raiders will not be bothered by many things
    # easily", encoded in the curve rather than only in how fast morale moves.
    var order := [E.Rarity.COMMON, E.Rarity.UNCOMMON, E.Rarity.RARE,
                  E.Rarity.EPIC, E.Rarity.LEGENDARY]
    for i in range(order.size() - 1):
        assert_true(F.MISTAKE_SENSITIVITY[order[i]] > F.MISTAKE_SENSITIVITY[order[i + 1]],
            "sensitivity must fall with rarity")
    var common_swing := _pct(E.Rarity.COMMON, 5) - _pct(E.Rarity.COMMON, 95)
    var legend_swing := _pct(E.Rarity.LEGENDARY, 5) - _pct(E.Rarity.LEGENDARY, 95)
    assert_true(common_swing > legend_swing * 40.0,
        "a Common's morale swing must dwarf a Legendary's")

func test_the_curve_is_asymmetric_punishment_over_reward() -> void:
    # docs/05 §5.2: the punishment side has roughly 6x the range of the reward
    # side. Falling apart is dramatic; being adored is a modest, reliable edge.
    var base := _pct(E.Rarity.COMMON, 55)
    var worst := _pct(E.Rarity.COMMON, 5) - base
    var best := base - _pct(E.Rarity.COMMON, 95)
    assert_true(worst > best * 4.0, "punishment range must dominate reward range")

func test_legendary_is_never_worse_than_epic() -> void:
    # The canon-anchored guarantee behind "you wont have to worry about losing
    # your higher tier raiders unless you are BIG dumb".
    var worst_legendary := _pct(E.Rarity.LEGENDARY, 0)
    var best_epic := _pct(E.Rarity.EPIC, 100)
    assert_true(worst_legendary < best_epic,
        "worst Legendary %.2f must beat best Epic %.2f" % [worst_legendary, best_epic])

func test_morale_can_invert_more_than_one_rarity_step() -> void:
    # Recorded consequence of the merge, NOT an accident. docs/08 §8.8 claimed
    # its coefficients guaranteed "morale can invert exactly one rarity step,
    # never two". Under docs/05's coefficients — which docs/15 Q-04/05 adopted —
    # that does not hold: a Very Upset Rare is worse than a beloved Common.
    # Logged as docs/15 BL-20. It is consistent with canon's thesis that morale
    # management is the core skill.
    var worst_rare := _pct(E.Rarity.RARE, 5)
    var best_common := _pct(E.Rarity.COMMON, 95)
    assert_true(worst_rare > best_common,
        "a miserable Rare (%.1f) is worse than a beloved Common (%.1f)"
            % [worst_rare, best_common])

func test_clamps_are_safety_rails_not_active_tuning() -> void:
    # docs/05 §5.4: no cell in the matrix is clamped. If one becomes clamped, a
    # coefficient moved and the published matrix is stale.
    for rarity in E.all_rarities():
        var lo: int = F.MISTAKE_FLOOR_BP[rarity]
        var hi: int = F.MISTAKE_CEIL_BP[rarity]
        for m in [5, 15, 25, 35, 45, 55, 65, 75, 85, 95]:
            var bp := F.mistake_chance_bp(rarity, m)
            assert_true(bp > lo and bp < hi,
                "%s at morale %d sits on a clamp (%d not inside %d..%d)"
                    % [E.rarity_name_of(rarity), m, bp, lo, hi])

func test_situational_modifiers_are_capped() -> void:
    # docs/07 §6 caps total live-token modifiers at +20 percentage points.
    var plain := F.mistake_chance_bp(E.Rarity.RARE, 55)
    var tokened := F.mistake_chance_bp(E.Rarity.RARE, 55, 800)
    assert_eq(tokened - plain, 800, "an 8pp token adds exactly 8pp")
    var absurd := F.mistake_chance_bp(E.Rarity.COMMON, 55, 999999)
    var capped := F.mistake_chance_bp(E.Rarity.COMMON, 55, F.SITUATIONAL_CAP_BP)
    assert_eq(absurd, capped, "situational modifiers cap out at +20pp")

func test_clamps_bind_once_tokens_are_involved() -> void:
    # The rails exist for exactly this: a Legendary buried in tokens still cannot
    # exceed its tier ceiling, which is canon's "not bothered by many things".
    var legendary := F.mistake_chance_bp(E.Rarity.LEGENDARY, 0, F.SITUATIONAL_CAP_BP)
    assert_eq(legendary, F.MISTAKE_CEIL_BP[E.Rarity.LEGENDARY],
        "tokens cannot push a Legendary past its tier ceiling")

func test_facility_multiplier_reduces_chance() -> void:
    var plain := F.mistake_chance_bp(E.Rarity.COMMON, 55)
    var upgraded := F.mistake_chance_bp(E.Rarity.COMMON, 55, 0, 0.9)
    assert_true(upgraded < plain, "Guildhall facilities must help")
    assert_eq(F.mistake_chance_bp(E.Rarity.COMMON, 55, 0, 1.0), plain)

func test_rarity_profile_matches_the_tables() -> void:
    var p := F.rarity_mistake_profile(E.Rarity.LEGENDARY)
    assert_almost(p["base"], 0.012, 0.0001)
    assert_almost(p["floor"], 0.009, 0.0001)
    assert_almost(p["ceiling"], 0.025, 0.0001)
    assert_almost(p["sensitivity"], 0.50, 0.0001)

func test_canon_sample_roster_mistake_rates() -> void:
    # Canon's own four raiders with real numbers attached. This is the
    # "oh no, Steve is at 14" decision made arithmetic.
    var steve := _pct(E.Rarity.COMMON, 14)
    var greg := _pct(E.Rarity.COMMON, 31)
    var bob := _pct(E.Rarity.COMMON, 54)
    var natsuna := F.mistake_chance(E.Rarity.LEGENDARY, 87) * 100.0
    assert_almost(steve, 64.3, 0.1, "Steve at 14")
    assert_almost(greg, 38.4, 0.1, "Greg at 31")
    assert_almost(bob, 24.0, 0.1, "Bob at 54")
    assert_almost(natsuna, 1.02, 0.02, "Natsuna the Legendary at 87")
    assert_true(steve > bob * 2.5, "bringing Steve is a genuinely bad idea")
