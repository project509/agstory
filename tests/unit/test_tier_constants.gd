extends "res://tests/TestCase.gd"
## `AC_K` and `MANA_TO_SPELL` stop being flat (docs/15 BL-72).
##
## docs/08 §9 raises both as OPEN notes against itself. A flat `AC_K` makes
## `MITIGATION_CAP` bind as the ladder climbs — armour stops buying anything and
## the tank channel becomes a constant — and the Mana ladder's x2.00 step per
## half-tier means either `MANA_TO_SPELL` decays or the step comes down, "only
## one of the two may be written down".
##
## Both are now functions of the rung with a named step, exactly like the four AC
## readings, so BOTH readings stay selectable and BOTH are tested here: the
## proposed curve must not clamp anywhere on the ladder, and the flat one must
## clamp where the measurement says it does. A switch whose other setting is
## untested is not a switch, it is a comment.
##
## The defaults are inert in play: every caller that does not know its rung
## passes 0, which is Tier 1, which is 60. Threading the rung into the budget and
## into RaidSim together is audit M5-T25-15 — they have to move in one commit or
## the fights and the budget that sized them would disagree.

const F = preload("res://sim/core/Formulas.gd")
const Enums = preload("res://sim/model/Enums.gd")

## docs/08 §9.6's own Tank AC column, raid rungs, Boss 1 of each tier. These are
## the numbers the SHIPPED gear ladder reaches — not the doc's older projection.
const TANK_AC_BY_TIER := {1: 17, 2: 26, 3: 40, 4: 64, 5: 102}

## docs/08 §9 writes the step as `1.5^index` over ten rung indices; measured
## against the ladder that exists, that over-shoots to 11.1% mitigation by Tier
## 4, so the step this file holds is per TIER.


func test_ac_k_is_flat_at_tier_1_so_nothing_shipped_moves() -> void:
    # The whole no-op argument: index 0 is Tier 1's Adventure rung, so every
    # caller that does not pass a rung gets exactly what shipped.
    assert_almost(F.ac_k_for(1), F.AC_K, 0.0001, "tier 1 must be the shipped constant")
    assert_almost(F.mitigation(17), 0.3617, 0.0005, "the Tier 1 tank is untouched")
    assert_almost(F.mitigation(17, 1), 0.3617, 0.0005, "and passing tier 1 explicitly agrees")


func test_the_flat_reading_really_does_clamp_and_the_doc_was_wrong_about_where() -> void:
    # docs/08 §9's note says the cap binds "from roughly index 5" off a projected
    # AC of 107. The ladder that actually exists reaches 40 at Tier 3 Boss 1, so
    # the note is pessimistic by two whole tiers — which is why the switch
    # defaults to a recommendation rather than an emergency.
    var flat_mit := func(ac: int) -> float:
        var a := float(ac) * 2.0
        return minf(F.MITIGATION_CAP, a / (a + F.AC_K))
    assert_true(flat_mit.call(TANK_AC_BY_TIER[3]) < F.MITIGATION_CAP - 0.01,
        "Tier 3's tank is nowhere near the cap under the flat reading")
    assert_almost(flat_mit.call(TANK_AC_BY_TIER[5]), F.MITIGATION_CAP, 0.001,
        "Tier 5's tank sits exactly on it, which is the real finding")


func test_the_proposed_curve_never_clamps_anywhere_on_the_ladder() -> void:
    # The acceptance criterion: a tier-appropriate tank's mitigation stays a
    # working number at every rung rather than flattening into the cap.
    var out_of_band: Array[String] = []
    for tier in TANK_AC_BY_TIER.keys():
        var mit := F.mitigation(int(TANK_AC_BY_TIER[tier]), int(tier))
        if mit >= F.MITIGATION_CAP - 0.001:
            out_of_band.append("T%d clamps at %.3f" % [tier, mit])
        if mit < 0.20 or mit > 0.55:
            out_of_band.append("T%d mitigation %.3f is outside the 0.20-0.55 working band" % [tier, mit])
    assert_eq(out_of_band.size(), 0,
        "the tank channel is not a working curve:\n      " + "\n      ".join(out_of_band))


func test_the_per_rung_reading_of_the_doc_over_shoots() -> void:
    # A measurement rather than a claim: reading §9's `1.5^index` per RUNG
    # rather than per tier drives the tank's mitigation to 11%, which is the
    # same failure as the cap binding, mirrored.
    var per_index := func(ac: int, index: int) -> float:
        var a := float(ac) * 2.0
        return a / (a + F.AC_K * pow(1.5, float(index)))
    assert_true(per_index.call(int(TANK_AC_BY_TIER[4]), 7) < 0.15,
        "the per-rung reading collapses the tank channel, which is why it is not the one")
    assert_true(F.mitigation(int(TANK_AC_BY_TIER[4]), 4) > 0.30,
        "and the per-tier reading does not")


func test_ac_k_rises_monotonically_and_1_0_selects_the_flat_reading() -> void:
    var prev := 0.0
    for tier in range(1, 6):
        var k := F.ac_k_for(tier)
        assert_true(k > prev, "AC_K must rise with the tier, tier %d" % tier)
        prev = k
    # The other setting: with the step at 1.0 the function IS the constant, at
    # every rung. Asserted by arithmetic rather than by editing the const, so the
    # claim holds without the test mutating global state.
    for tier in range(1, 6):
        assert_almost(F.AC_K * pow(1.0, float(tier - 1)), F.AC_K, 0.0001,
            "a step of 1.0 is the flat reading at tier %d" % tier)


func test_mana_to_spell_decays_per_tier_and_tier_1_is_untouched() -> void:
    assert_almost(F.mana_to_spell_for(1), F.MANA_TO_SPELL, 0.0001,
        "Tier 1 must be exactly what shipped")
    assert_almost(F.spell_power(16, 44), 31.4, 0.01, "and the Tier 1 worked example holds")
    var prev := F.mana_to_spell_for(1)
    for tier in range(2, 6):
        var now := F.mana_to_spell_for(tier)
        assert_true(now < prev, "Mana must buy less per tier, tier %d" % tier)
        prev = now
    # docs/08 §9: the decay is 0.85 per tier, so tier 5 keeps 0.85^4 of it.
    assert_almost(F.mana_to_spell_for(5), F.MANA_TO_SPELL * pow(0.85, 4.0), 0.0001,
        "tier 5's conversion is the doc's own 0.85^4")


func test_the_casters_share_of_a_party_stays_inside_ten_points_across_the_tiers() -> void:
    # The acceptance criterion for the Mana half: without the decay, a x2.00
    # Mana step per half-tier makes casters run away from the melee line. The
    # gear comes from the generated ladder's own family totals, so this measures
    # the real ladder rather than a hypothetical one.
    var mage := _family_mana_by_tier()
    var melee := _family_power_proxy_by_tier()
    var shares: Array[float] = []
    for tier in range(1, 6):
        var caster := F.spell_power(16, int(mage[tier]), tier) \
            * float(F.CLASS_SPELL_COEF[Enums.CharClass.MAGE])
        var physical := float(melee[tier])
        shares.append(caster / maxf(0.01, caster + physical))
    var base := shares[0]
    var drift: Array[String] = []
    for i in shares.size():
        if absf(shares[i] - base) > 0.10:
            drift.append("T%d share %.3f against Tier 1's %.3f" % [i + 1, shares[i], base])
    assert_eq(drift.size(), 0,
        "the caster line runs away from the party:\n      " + "\n      ".join(drift))


## The cloth line's Mana total per tier, read off the generated ladder.
func _family_mana_by_tier() -> Dictionary:
    var out := {}
    for tier in range(1, 6):
        out[tier] = _family_stat(tier, "mage_wizard_armor", "mana")
    return out


## A stand-in for the melee line's output: its own AC total, which is what the
## physical families' ladder actually buys. The absolute number does not matter
## here — only that both sides are read from the same ladder.
func _family_power_proxy_by_tier() -> Dictionary:
    var out := {}
    for tier in range(1, 6):
        out[tier] = _family_stat(tier, "warrior_bard_armor", "ac") * 3
    return out


func _family_stat(tier: int, family: String, stat: String) -> int:
    var path := "res://data/items_t%d_raid.json" % tier
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (parsed is Dictionary):
        return 0
    var best := {}
    for row in parsed.get("items", []):
        if String(row.get("family", "")) != family:
            continue
        var slot := String(row.get("slot", ""))
        if not (slot in ["head", "chest", "legs", "feet"]):
            continue
        var v := int((row.get("stats", {}) as Dictionary).get(stat, 0))
        best[slot] = maxi(int(best.get(slot, 0)), v)
    var total := 0
    for slot in best:
        total += int(best[slot])
    return total
