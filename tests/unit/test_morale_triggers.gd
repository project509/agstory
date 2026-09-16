extends "res://tests/TestCase.gd"
## docs/05 §7's trigger table, and §7.6's anti-farm audit as assertions.
##
## §7 exists for a stated reason: "canon names three sources ... and says the rest
## comes from backstories. A build needs the full trigger list with caps, or
## morale becomes farmable and every raider parks at 100." §7.6 then lists five
## specific exploits and what blocks each. Those five are tests here, because a
## cap nobody checks is a comment.

const Morale = preload("res://sim/core/Morale.gd")
const Ledger = preload("res://sim/core/MoraleLedger.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")

var _ledger = null

func before_each() -> void:
    _ledger = Ledger.new()

func _r(rarity: int = Enums.Rarity.COMMON, morale: int = 50, id: String = "r1"):
    var r = Raider.new()
    r.id = id
    r.display_name = id.capitalize()
    r.class_id = Enums.CharClass.WARRIOR
    r.rarity = rarity
    Morale.set_morale(r, float(morale))
    return r

# ---------------------------------------------------------------- the table

func test_every_documented_trigger_exists() -> void:
    # docs/05 §7.1-§7.4, every row. A missing trigger is a morale source the
    # game silently does not have.
    for id in ["cleared", "first_boss_kill", "wipe", "wipe_caused", "knocked_out",
            "avenged", "brought", "benched", "benched_wishlist", "peer_left",
            "peer_left_same_class", "peer_dismissed", "rank_up", "loot_upgrade",
            "loot_wishlist", "loot_sidegrade", "passed_over",
            "passed_over_wishlist", "wishlist_sold", "comfort_item", "training",
            "quest_completed"]:
        assert_true(Morale.trigger_exists(id), "missing trigger '%s'" % id)

func test_the_documented_deltas_are_the_ones_used() -> void:
    # Pre-resilience values, straight from docs/05 §7's tables.
    var expected := {
        "cleared": 6.0, "first_boss_kill": 10.0, "wipe": -8.0,
        "wipe_caused": -4.0, "knocked_out": -3.0, "avenged": 3.0,
        "brought": 3.0, "benched": -2.0, "benched_wishlist": -4.0,
        "peer_left": -4.0, "peer_left_same_class": -6.0, "peer_dismissed": -2.0,
        "rank_up": 5.0, "loot_upgrade": 5.0, "loot_wishlist": 12.0,
        "loot_sidegrade": 0.0, "passed_over": -3.0,
        "passed_over_wishlist": -5.0, "wishlist_sold": -7.0,
        "comfort_item": 8.0, "training": 2.0, "quest_completed": 3.0,
    }
    for id in expected:
        assert_almost(Morale.trigger_delta(id), float(expected[id]), 0.001,
            "%s delta" % id)

func test_an_unknown_trigger_changes_nothing() -> void:
    var r = _r()
    var before: int = r.morale
    assert_almost(Morale.apply(r, "not_a_trigger", _ledger), 0.0)
    assert_eq(r.morale, before)

func test_clutter_grants_no_morale() -> void:
    # docs/05 §7.3: "Received an item that is not an upgrade — 0 — No morale
    # from clutter."
    var r = _r()
    var before: int = r.morale
    assert_almost(Morale.apply(r, "loot_sidegrade", _ledger), 0.0)
    assert_eq(r.morale, before)

# ---------------------------------------------------------------- resilience

func test_deltas_are_scaled_by_rarity_not_applied_raw() -> void:
    # docs/05 §7: "All deltas below are pre-resilience; §8 scales them per
    # rarity." A Common feels a wipe 1.35x, a Legendary 0.40x.
    var common = _r(Enums.Rarity.COMMON, 60, "c")
    var legendary = _r(Enums.Rarity.LEGENDARY, 60, "l")
    var c_applied := Morale.apply(common, "wipe", Ledger.new())
    var l_applied := Morale.apply(legendary, "wipe", Ledger.new())
    assert_almost(c_applied, -8.0 * 1.35, 0.01)
    assert_almost(l_applied, -8.0 * 0.40, 0.01)
    assert_true(absf(c_applied) > absf(l_applied) * 3.0,
        "canon: you should not worry about losing higher-tier raiders")

func test_a_backstory_tag_scales_a_delta_by_the_documented_factors() -> void:
    # docs/05 §7.5 allows exactly two: 1.5x or 0.5x, "for example a hates_wiping
    # tag on the wipe row".
    assert_almost(Morale.TAG_AMPLIFY, 1.5)
    assert_almost(Morale.TAG_DAMPEN, 0.5)
    var hates = _r(Enums.Rarity.RARE, 60, "h")
    var shrugs = _r(Enums.Rarity.RARE, 60, "s")
    var a := Morale.apply(hates, "wipe", Ledger.new(), "", Morale.TAG_AMPLIFY)
    var b := Morale.apply(shrugs, "wipe", Ledger.new(), "", Morale.TAG_DAMPEN)
    assert_almost(a, -12.0, 0.01, "a Rare takes 1.0x, so 1.5 x -8")
    assert_almost(b, -4.0, 0.01)

# ---------------------------------------------------------------- caps

func test_once_per_tick_fires_once_per_tick() -> void:
    # docs/05 §7.1: the clear bonus is "Once per encounter-set per Day Tick".
    var r = _r(Enums.Rarity.RARE, 40)
    assert_almost(Morale.apply(r, "cleared", _ledger), 6.0, 0.01)
    assert_almost(Morale.apply(r, "cleared", _ledger), 0.0, 0.01,
        "a second clear in the same tick grants nothing")
    _ledger.advance_tick()
    assert_almost(Morale.apply(r, "cleared", _ledger), 6.0, 0.01,
        "and the next tick grants it again")

func test_the_first_boss_kill_is_once_per_boss_per_raider_forever() -> void:
    # docs/05 §7.1, and §7.6 names the exploit it blocks: "Farm first-boss-kill
    # bonuses across alt raiders — once per boss PER RAIDER, permanent."
    var r = _r(Enums.Rarity.RARE, 40)
    assert_almost(Morale.apply(r, "first_boss_kill", _ledger, "boss_5"), 10.0, 0.01)
    assert_almost(Morale.apply(r, "first_boss_kill", _ledger, "boss_5"), 0.0, 0.01)
    _ledger.advance_tick()
    _ledger.begin_session()
    assert_almost(Morale.apply(r, "first_boss_kill", _ledger, "boss_5"), 0.0, 0.01,
        "permanently once — a new tick does not reopen it")
    assert_almost(Morale.apply(r, "first_boss_kill", _ledger, "boss_4"), 10.0, 0.01,
        "but a different boss is a different first kill")

func test_wipe_damage_is_capped_per_attempt_session() -> void:
    # docs/05 §7.1: "Wipe, raider participated — -8 — Max -16 per raid attempt
    # session." A Rare takes 1.0x, so exactly two wipes fill the cap.
    var r = _r(Enums.Rarity.RARE, 90)
    assert_almost(Morale.apply(r, "wipe", _ledger), -8.0, 0.01)
    assert_almost(Morale.apply(r, "wipe", _ledger), -8.0, 0.01)
    assert_almost(Morale.apply(r, "wipe", _ledger), 0.0, 0.01,
        "the third wipe in one session is free")
    _ledger.begin_session()
    assert_almost(Morale.apply(r, "wipe", _ledger), -8.0, 0.01,
        "a new attempt is a new session")

func test_a_partial_allowance_is_granted_not_refused() -> void:
    # A cap should clip the last delta, not discard it — otherwise the cap is a
    # cliff and the arithmetic stops matching the doc's stated maximum.
    var r = _r(Enums.Rarity.RARE, 90)
    Morale.apply(r, "knocked_out", _ledger)          # -3, cap is -6
    Morale.apply(r, "knocked_out", _ledger)          # -3, cap now full
    var third := Morale.apply(r, "knocked_out", _ledger)
    assert_almost(third, 0.0, 0.01)
    # Now a rarity that overshoots: a Common takes 1.35x, so -4.05 each.
    var common = _r(Enums.Rarity.COMMON, 90, "c2")
    var ledger2 = Ledger.new()
    var first := Morale.apply(common, "knocked_out", ledger2)
    var second := Morale.apply(common, "knocked_out", ledger2)
    assert_almost(absf(first) + absf(second), 6.0, 0.01,
        "the cap is -6 in total, so the second is clipped to fit")

func test_the_comfort_item_cooldown_is_two_ticks() -> void:
    # docs/05 §7.4: "One comfort item per raider per 2 Day Ticks", which §7.6
    # names as the block on "Spam comfort items with gold".
    var r = _r(Enums.Rarity.RARE, 40)
    assert_almost(Morale.apply(r, "comfort_item", _ledger), 8.0, 0.01)
    _ledger.advance_tick()
    assert_almost(Morale.apply(r, "comfort_item", _ledger), 0.0, 0.01,
        "one tick later is still inside the cooldown")
    _ledger.advance_tick()
    assert_almost(Morale.apply(r, "comfort_item", _ledger), 8.0, 0.01,
        "two ticks later it is available again")

func test_the_wishlist_grant_cooldown_is_three_ticks() -> void:
    # docs/05 §7.3: "Max one wishlist grant per raider per 3 Day Ticks."
    var r = _r(Enums.Rarity.RARE, 20)
    assert_almost(Morale.apply(r, "loot_wishlist", _ledger), 12.0, 0.01)
    for _i in 2:
        _ledger.advance_tick()
        assert_almost(Morale.apply(r, "loot_wishlist", _ledger), 0.0, 0.01)
    _ledger.advance_tick()
    assert_almost(Morale.apply(r, "loot_wishlist", _ledger), 12.0, 0.01)

func test_benching_is_capped_over_a_rolling_seven_tick_window() -> void:
    # docs/05 §7.2: "max -6 per 7 ticks". A Rare takes 1.0x, so three benchings
    # fill it and the fourth is free until the window rolls off.
    var r = _r(Enums.Rarity.RARE, 90)
    for _i in 3:
        assert_almost(Morale.apply(r, "benched", _ledger), -2.0, 0.01)
        _ledger.advance_tick()
    assert_almost(Morale.apply(r, "benched", _ledger), 0.0, 0.01,
        "the window is full")
    for _i in 6:
        _ledger.advance_tick()
    assert_true(Morale.apply(r, "benched", _ledger) < 0.0,
        "once the oldest entries age out, benching bites again")

func test_selling_a_wishlisted_item_is_deliberately_uncapped() -> void:
    # docs/05 §7.3: "-7 — Not capped — this is the player choosing gold over a
    # person." The absence of a cap is the design.
    var r = _r(Enums.Rarity.RARE, 90)
    for _i in 3:
        assert_almost(Morale.apply(r, "wishlist_sold", _ledger), -7.0, 0.01)

# ---------------------------------------------------------------- §7.6 audit

func test_reclearing_within_one_tick_grants_one_bonus() -> void:
    # docs/05 §7.6, exploit 1: "Re-clear the tutorial raid forever for +6 — Clear
    # bonus is once per encounter-set per tick, and drift pulls it back."
    #
    # Note what this does and does NOT claim. It bounds the gain PER TICK; it does
    # not stop morale climbing over many ticks, and §7.6 is explicit that it
    # should not: the 80 ceiling is "without ongoing events", and "Band 9 is
    # reachable only by active play, for anyone. That is intentional: the top band
    # should feel earned." Clearing content every tick IS active play.
    var r = _r(Enums.Rarity.COMMON, 45)
    var before: float = Morale.morale_exact(r)
    var granted := 0.0
    for _i in 20:
        granted += Morale.apply(r, "cleared", _ledger)
    assert_almost(granted, 6.0 * 0.85, 0.01,
        "twenty re-clears in one tick pay for one, scaled by Common resilience")
    assert_true(Morale.morale_exact(r) - before < 6.0,
        "the tick's total gain is one bonus, not twenty")

func test_active_play_earns_the_top_band_slowly() -> void:
    # The other half of §7.6's intent: band 9 is reachable, but only by playing.
    # A Common gains 5.1 a tick from clearing and loses 1.125 to drift, so the
    # climb is real but gradual — it must not be instant.
    var r = _r(Enums.Rarity.COMMON, 45)
    var ticks_to_band_9 := 0
    for i in 60:
        Morale.apply(r, "cleared", _ledger)
        Morale.drift_raider(r)
        _ledger.advance_tick()
        if Enums.morale_band(r.morale) >= 9:
            ticks_to_band_9 = i + 1
            break
    assert_true(ticks_to_band_9 > 5,
        "the top band must take sustained play, not a handful of clears — took %d"
        % ticks_to_band_9)
    assert_true(ticks_to_band_9 > 0, "but it must be reachable by playing")

func test_nobody_can_park_at_one_hundred() -> void:
    # docs/05 §7.6, exploit 5: "Park the whole roster at 100 — Drift to baseline;
    # baseline caps at 50 + 12 + 10 + 8 = 80."
    var r = _r(Enums.Rarity.LEGENDARY, 100)
    for _i in 60:
        Morale.drift_raider(r, 3, Morale.BACKSTORY_OFFSET_MAX)
        _ledger.advance_tick()
    assert_eq(r.morale, 80,
        "the ceiling is the bottom of band 8, not band 9")
    assert_eq(Enums.morale_band(r.morale), 8, "Very Happy, not Loves Their Guild")

func test_the_documented_ceilings_are_exact() -> void:
    # docs/05 §7.6: "Maximum sustainable morale ... is therefore 80 (a Legendary,
    # tier 3 facilities, best backstory) ... For a Common the ceiling is 63."
    assert_eq(Morale.max_sustainable(Enums.Rarity.LEGENDARY), 80)
    assert_eq(Morale.max_sustainable(Enums.Rarity.COMMON), 63)
    assert_eq(Enums.morale_band(63), 6, "docs/05 §7.6 calls this band 6")

func test_band_nine_is_reachable_only_by_active_play() -> void:
    # docs/05 §7.6: "Band 9 (Loves Their Guild) is reachable only by active play,
    # for anyone. That is intentional: the top band should feel earned."
    for rarity in Enums.all_rarities():
        assert_true(Morale.max_sustainable(rarity) < 90,
            "%s must not idle into band 9" % Enums.rarity_key(rarity))

# ---------------------------------------------------------------- facilities

func test_the_facility_ladder_matches_the_documented_bonuses() -> void:
    # docs/05 §7.5: tiers 0-3 give +0 / +3 / +6 / +10.
    assert_eq(Morale.FACILITY_BONUS, [0, 3, 6, 10])
    for tier in 4:
        assert_eq(Morale.facility_bonus_for(tier), Morale.FACILITY_BONUS[tier])
    assert_eq(Morale.facility_bonus_for(99), 10, "clamped, not extrapolated")

func test_a_facility_upgrade_raises_the_baseline_not_the_value() -> void:
    # docs/05 §7.4: canon says "better morale values", a standing improvement,
    # "rather than a morale bonus (a one-off)".
    var base := Morale.baseline_for(Enums.Rarity.COMMON, 0)
    var upgraded := Morale.baseline_for(Enums.Rarity.COMMON,
        Morale.facility_bonus_for(3))
    assert_eq(upgraded - base, 10)

func test_the_backstory_offset_is_clamped_to_the_documented_range() -> void:
    # docs/05 §7.5 exposes "a backstory_offset in the range -8..+8 on baseline"
    # and explicitly no more than that.
    assert_eq(Morale.BACKSTORY_OFFSET_MIN, -8)
    assert_eq(Morale.BACKSTORY_OFFSET_MAX, 8)
    var high := Morale.baseline_for(Enums.Rarity.RARE, 0, 99)
    assert_eq(high, Morale.baseline_for(Enums.Rarity.RARE, 0, 8),
        "a wild offset is clamped, not honoured")

# ---------------------------------------------------------------- precision

func test_sub_one_drift_accumulates_rather_than_truncating() -> void:
    # docs/05 §4: morale is "stored as float so sub-1 drift accumulates". A
    # Common drifts 1.125 per tick; truncating to 1 would silently lose an
    # eighth of its recovery every tick.
    var r = _r(Enums.Rarity.COMMON, 40)
    for _i in 4:
        Morale.drift_raider(r)
    # 40 + 4 x 1.125 = 44.5
    assert_almost(Morale.morale_exact(r), 44.5, 0.001)
    assert_eq(r.morale, 45, "and the displayed value is that, rounded")

func test_the_displayed_morale_is_always_the_exact_value_rounded() -> void:
    var r = _r(Enums.Rarity.RARE, 50)
    Morale.set_morale(r, 61.4)
    assert_eq(r.morale, 61)
    Morale.set_morale(r, 61.6)
    assert_eq(r.morale, 62)

func test_a_raider_built_without_an_exact_value_still_works() -> void:
    # StartingRoster and every existing test assign `morale` directly, so the
    # exact value has to fall back rather than read as zero.
    var r = Raider.new()
    r.id = "legacy"
    r.rarity = Enums.Rarity.COMMON
    r.morale = 45
    assert_almost(Morale.morale_exact(r), 45.0)

func test_morale_is_clamped_at_both_ends_by_triggers() -> void:
    var low = _r(Enums.Rarity.COMMON, 2)
    Morale.apply(low, "wipe", _ledger)
    assert_true(low.morale >= Enums.MORALE_MIN)
    var high = _r(Enums.Rarity.LEGENDARY, 99, "hi")
    Morale.apply(high, "first_boss_kill", _ledger)
    assert_true(high.morale <= Enums.MORALE_MAX)

# ---------------------------------------------------------------- the ledger

func test_the_ledger_survives_a_save_round_trip() -> void:
    # A cap the player can reset by quitting to the menu is not a cap.
    var r = _r(Enums.Rarity.RARE, 40)
    Morale.apply(r, "first_boss_kill", _ledger, "boss_5")
    Morale.apply(r, "comfort_item", _ledger)
    var restored = Ledger.from_dict(_ledger.to_dict())

    assert_eq(restored.tick, _ledger.tick)
    var r2 = _r(Enums.Rarity.RARE, 40)
    assert_almost(Morale.apply(r2, "first_boss_kill", restored, "boss_5"), 0.0,
        0.001, "a permanent grant must still be spent after a reload")
    assert_almost(Morale.apply(r2, "comfort_item", restored), 0.0, 0.001,
        "and a cooldown must still be running")

func test_caps_are_tracked_per_raider() -> void:
    # Steve using a comfort item must not put Bob on cooldown.
    var steve = _r(Enums.Rarity.RARE, 40, "steve")
    var bob = _r(Enums.Rarity.RARE, 40, "bob")
    assert_almost(Morale.apply(steve, "comfort_item", _ledger), 8.0, 0.01)
    assert_almost(Morale.apply(bob, "comfort_item", _ledger), 8.0, 0.01,
        "Bob has his own cooldown")
