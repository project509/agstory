extends "res://tests/TestCase.gd"
## docs/05 §6: leaving and guild disband.
##
## Canon gives two words — "may leave guild" and "may cause guild disband" — and
## §6.2 states the gap it is filling: "canon says 'may'. A programmer needs when,
## how often, and how likely." These tests hold the answer to the doc's numbers.
##
## The most important assertions here are the ones about what CANNOT happen. §6.3
## carries an absolute rule — "disband can never fire without prior warning" —
## enforced "structurally, not by convention", and a structural guarantee is only
## worth the tests that try to violate it.

const Morale = preload("res://sim/core/Morale.gd")
const Ledger = preload("res://sim/core/MoraleLedger.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Rng = preload("res://sim/core/Rng.gd")

func _r(rarity: int, morale: int, id: String = "r", strikes: int = 0):
    var r = Raider.new()
    r.id = id
    r.display_name = id.capitalize()
    r.class_id = Enums.CharClass.WARRIOR
    r.rarity = rarity
    Morale.set_morale(r, float(morale))
    r.at_risk_strikes = strikes
    return r

# ---------------------------------------------------------------- canon gates

func test_the_leave_rates_match_the_documented_table() -> void:
    # docs/05 §6.2: band 0 → 0.22, band 1 → 0.14, band 2 → 0.05, 3-9 → 0.00.
    assert_almost(Morale.LEAVE_RATE[0], 0.22)
    assert_almost(Morale.LEAVE_RATE[1], 0.14)
    assert_almost(Morale.LEAVE_RATE[2], 0.05)
    for band in range(3, 10):
        assert_almost(Morale.LEAVE_RATE[band], 0.0,
            0.00001, "band %d must be a hard zero" % band)

func test_wont_leave_is_a_hard_floor_not_a_small_number() -> void:
    # docs/05 §6.1 on band 30-40: "Departure impossible — a hard floor, not a low
    # probability." Canon's own word is "Won't leave".
    for morale in [30, 45, 60, 80, 100]:
        var r = _r(Enums.Rarity.COMMON, morale, "safe", 99)
        assert_almost(Morale.p_leave(r), 0.0, 0.00001,
            "a raider at %d must be unable to leave at all" % morale)
        assert_false(Morale.may_leave(r), "even with 99 strikes")

func test_the_leave_resilience_ladder_matches_the_doc() -> void:
    # docs/05 §6.2, and canon constrains it: "you wont have to worry about losing
    # your higher tier raiders unless you are BIG dumb".
    assert_eq(Morale.LEAVE_RESILIENCE, [1.30, 1.10, 0.85, 0.55, 0.25])

func test_the_effective_probabilities_at_upset_are_the_documented_ones() -> void:
    # docs/05 §6.2's own right-hand column: Common 18.2%, Uncommon 15.4%,
    # Rare 11.9%, Epic 7.7%, Legendary 3.5% — at band 1, Upset.
    var expected := [0.182, 0.154, 0.119, 0.077, 0.035]
    for rarity in Enums.all_rarities():
        var r = _r(rarity, 14, "u", 5)
        assert_almost(Morale.p_leave(r), expected[rarity], 0.0005,
            "%s at Upset" % Enums.rarity_key(rarity))

func test_the_worked_four_tick_expectations_hold() -> void:
    # docs/05 §6.2: "a Common left at 14 morale departs within 4 Day Ticks about
    # 55% of the time (1 - 0.818^4). A Legendary at the same value departs within
    # 4 ticks about 13% of the time — recoverable if the player reacts, which is
    # what 'unless you are BIG dumb' asks for."
    var common := 1.0 - pow(1.0 - Morale.p_leave(_r(Enums.Rarity.COMMON, 14, "c", 5)), 4.0)
    var legendary := 1.0 - pow(1.0 - Morale.p_leave(_r(Enums.Rarity.LEGENDARY, 14, "l", 5)), 4.0)
    assert_almost(common, 0.55, 0.01, "the Common's four-tick departure odds")
    assert_almost(legendary, 0.13, 0.01, "and the Legendary's")

# ---------------------------------------------------------------- hard rules

func test_a_raider_gets_one_tick_to_be_rescued() -> void:
    # docs/05 §6.2 hard rules 1 and 2 together: no departure on the tick a raider
    # first enters band 0-2, and none while at_risk_strikes is 0. Since strikes
    # reach 1 on that first tick, the effective gate is 2.
    assert_eq(Morale.MIN_STRIKES_TO_LEAVE, 2)
    var fresh = _r(Enums.Rarity.COMMON, 8, "fresh", 0)
    Morale.update_at_risk_strikes(fresh)
    assert_eq(fresh.at_risk_strikes, 1, "one strike on the tick they fall")
    assert_false(Morale.may_leave(fresh),
        "the player must get a tick to react before anyone can walk")
    Morale.update_at_risk_strikes(fresh)
    assert_true(Morale.may_leave(fresh), "and from the next tick they may")

func test_a_warning_always_precedes_a_departure() -> void:
    # docs/05 §6.2 hard rule 2, stated as "Warning always precedes departure".
    var r = _r(Enums.Rarity.COMMON, 5, "doomed", 0)
    for _i in 200:
        assert_false(Morale.rolls_to_leave(r, Rng.new(_i)),
            "nobody may leave without a strike on the board")

func test_nobody_leaves_mid_raid() -> void:
    # docs/05 §6.2 hard rule 3: "A raider mid-raid never leaves. Departure
    # resolves in town only."
    var r = _r(Enums.Rarity.COMMON, 5, "inraid", 9)
    assert_false(Morale.may_leave(r, true))
    for _i in 100:
        assert_false(Morale.rolls_to_leave(r, Rng.new(_i), true))

func test_strikes_reset_the_moment_a_raider_recovers() -> void:
    var r = _r(Enums.Rarity.COMMON, 15, "recovering", 3)
    Morale.set_morale(r, 45.0)
    assert_eq(Morale.update_at_risk_strikes(r), 0,
        "climbing out of band 2 clears the record")
    assert_false(Morale.may_leave(r))

func test_the_last_of_a_class_has_no_plot_armour() -> void:
    # docs/05 §6.2 hard rule 4: "The last raider of a class flagged required by an
    # unlocked raid still leaves. No plot armor; the player must recruit at the
    # Tavern." This is an absence rather than a feature, so the test asserts that
    # nothing about the roster's composition reaches the decision.
    var only_healer = _r(Enums.Rarity.COMMON, 5, "cleric", 5)
    only_healer.class_id = Enums.CharClass.CLERIC
    var left := false
    for i in 200:
        if Morale.rolls_to_leave(only_healer, Rng.new(i)):
            left = true
            break
    assert_true(left, "the only healer in the guild is not protected")

# ---------------------------------------------------------------- disband

func test_the_crisis_needs_a_band_zero_raider_and_a_low_average() -> void:
    # docs/05 §6.3 conditions A and B. Either alone is not enough — the doc is
    # explicit that "a run-ender that can fire off one bad raider is a rage-quit
    # generator".
    var one_miserable := [_r(Enums.Rarity.COMMON, 5, "a"),
        _r(Enums.Rarity.COMMON, 80, "b"), _r(Enums.Rarity.COMMON, 80, "c")]
    assert_false(Morale.crisis_conditions_hold(one_miserable),
        "one wretched raider in a happy guild is not a crisis")

    var low_average := [_r(Enums.Rarity.COMMON, 20, "a"),
        _r(Enums.Rarity.COMMON, 20, "b"), _r(Enums.Rarity.COMMON, 20, "c")]
    assert_false(Morale.crisis_conditions_hold(low_average),
        "a uniformly miserable guild with nobody in band 0 is not a crisis")

    var both := [_r(Enums.Rarity.COMMON, 5, "a"),
        _r(Enums.Rarity.COMMON, 20, "b"), _r(Enums.Rarity.COMMON, 20, "c")]
    assert_true(Morale.crisis_conditions_hold(both))

func test_the_crisis_average_threshold_is_the_documented_one() -> void:
    assert_eq(Morale.CRISIS_AVG_MORALE_MAX, 25)
    var just_over := [_r(Enums.Rarity.COMMON, 5, "a"), _r(Enums.Rarity.COMMON, 46, "b")]
    assert_false(Morale.crisis_conditions_hold(just_over),
        "an average of 25.5 is not below 25")

func test_strikes_reset_when_either_condition_fails() -> void:
    # docs/05 §6.3: crisis_strikes "resets to 0 on any tick where either fails".
    var healthy := [_r(Enums.Rarity.COMMON, 50, "a")]
    assert_eq(Morale.next_crisis_strikes(healthy, 4), 0)

func test_the_disband_ladder_matches_the_documented_table() -> void:
    # docs/05 §6.3: strikes 1 → 0%, 2 → 0%, 3 → 8%, 4 → 18%, 5+ → 30% flat.
    assert_almost(Morale.p_disband(1), 0.0)
    assert_almost(Morale.p_disband(2), 0.0)
    assert_almost(Morale.p_disband(3), 0.08)
    assert_almost(Morale.p_disband(4), 0.18)
    assert_almost(Morale.p_disband(5), 0.30)
    assert_almost(Morale.p_disband(9), 0.30, 0.0001, "5+ is flat, not escalating")

func test_disband_can_never_fire_without_two_full_ticks_of_warning() -> void:
    # docs/05 §6.3's ABSOLUTE RULE, which the doc says is "Enforced structurally,
    # not by convention": "At least two full Day Ticks of escalating warning
    # before any roll", via "the crisis_strikes >= 3 gate, with 0% at strikes 1-2".
    #
    # A structural guarantee is worth exactly the tests that try to break it.
    assert_eq(Morale.MIN_CRISIS_STRIKES_TO_DISBAND, 3)
    for strikes in [0, 1, 2]:
        assert_false(Morale.may_disband(strikes, true),
            "%d strikes must be unable to disband a guild" % strikes)
        for seed_value in 300:
            assert_false(Morale.rolls_to_disband(strikes, true, Rng.new(seed_value)),
                "%d strikes rolled a disband on seed %d" % [strikes, seed_value])

func test_the_modal_lands_a_tick_before_any_roll_is_possible() -> void:
    # docs/05 §6.3: the strike-2 modal is the unmissable warning, and strike 3 is
    # the first tick a roll can happen. The order matters — a modal that appeared
    # on the same tick as the first roll would not be a warning.
    assert_eq(Morale.CRISIS_MODAL_STRIKE, 2)
    assert_true(Morale.CRISIS_MODAL_STRIKE < Morale.MIN_CRISIS_STRIKES_TO_DISBAND)

func test_no_disband_during_onboarding() -> void:
    # docs/05 §6.3: "disabled until the player has completed Adventure 0 and the
    # Tutorial Raid".
    for strikes in range(0, 8):
        assert_false(Morale.may_disband(strikes, false),
            "%d strikes must not disband a guild still in onboarding" % strikes)

func test_a_collapsing_guild_does_eventually_disband() -> void:
    # The rule is that it never fires WITHOUT warning, not that it never fires.
    var fired := false
    for seed_value in 200:
        if Morale.rolls_to_disband(5, true, Rng.new(seed_value)):
            fired = true
            break
    assert_true(fired, "at 30% a sustained collapse must be able to end a guild")

# ---------------------------------------------------------------- the Day Tick

func test_the_tick_drifts_then_checks_never_the_other_way() -> void:
    # docs/05 §4: "never roll a leave check against a mid-update value." A raider
    # who drifts back out of band 2 during the tick must not then be rolled as if
    # they were still in it.
    var r = _r(Enums.Rarity.LEGENDARY, 29, "climbing", 5)
    var report := Morale.resolve_day_tick([r], Rng.new(1), {})
    # A Legendary drifts 2.25 a tick toward a baseline of 62, so 29 → 31.25,
    # which is band 3 and therefore safe.
    assert_true(r.morale >= 31, "drift resolved first")
    assert_eq(r.at_risk_strikes, 0, "and the strike record reflects the new value")
    assert_eq(report["departed"].size(), 0, "so nobody was rolled at the old value")

func test_a_departed_raider_is_reported_and_removed_from_the_survivors() -> void:
    var doomed = _r(Enums.Rarity.COMMON, 4, "doomed", 8)
    var fine = _r(Enums.Rarity.COMMON, 60, "fine")
    var found := false
    for seed_value in 200:
        var report := Morale.resolve_day_tick([doomed, fine], Rng.new(seed_value), {})
        if report["departed"].size() > 0:
            found = true
            assert_eq(report["departed"][0].id, "doomed")
            assert_eq(report["survivors"].size(), 1)
            assert_eq(report["survivors"][0].id, "fine")
            break
        Morale.set_morale(doomed, 4.0)
        doomed.at_risk_strikes = 8
    assert_true(found, "a Common at 4 morale with strikes should eventually walk")

func test_the_tick_reports_what_the_screen_needs() -> void:
    var collapsing := [_r(Enums.Rarity.COMMON, 5, "a", 9),
        _r(Enums.Rarity.COMMON, 15, "b"), _r(Enums.Rarity.COMMON, 15, "c")]
    var report := Morale.resolve_day_tick(collapsing, Rng.new(7),
        {"crisis_strikes": 1})
    for key in ["departed", "survivors", "crisis_strikes", "crisis",
            "p_disband_next", "show_crisis_modal", "disbanded"]:
        assert_true(report.has(key), "the report is missing '%s'" % key)

func test_an_empty_roster_is_not_a_crisis() -> void:
    # A disbanded guild must not immediately re-trigger its own collapse.
    assert_false(Morale.crisis_conditions_hold([]))
    var report := Morale.resolve_day_tick([], Rng.new(1), {"crisis_strikes": 4})
    assert_eq(int(report["crisis_strikes"]), 0)
    assert_false(bool(report["disbanded"]))

# ---------------------------------------------------------------- warnings

func test_the_warning_ladder_matches_the_documented_ux() -> void:
    # docs/05 §6.2's Warning UX table: 1 amber, 2 red + "AT RISK", 3+ "MAY LEAVE"
    # and pinned to the top of the roster.
    var r = _r(Enums.Rarity.COMMON, 15, "w", 0)
    assert_eq(Morale.warning_level(r), 0)
    for expected in [1, 2, 3]:
        Morale.update_at_risk_strikes(r)
        assert_eq(Morale.warning_level(r), expected)
    Morale.update_at_risk_strikes(r)
    assert_eq(Morale.warning_level(r), 3, "3+ is the top rung, not a fourth")

func test_strikes_survive_a_save_round_trip() -> void:
    # A warning the player can erase by reloading is not a warning, and it would
    # also reset the departure gate.
    var r = _r(Enums.Rarity.COMMON, 12, "saved", 2)
    r.backstory_offset = -5
    var restored = Raider.from_dict(r.to_dict())
    assert_eq(restored.at_risk_strikes, 2)
    assert_eq(restored.backstory_offset, -5)
