extends "res://tests/TestCase.gd"
## sim/model/Combatant.gd — per-encounter combat state.
##
## The Downed state is the rule most worth protecting. docs/07 §4.2 resolves a
## round sequentially with boss damage in Phase 1 and healing in Phase 4, so
## without Downed a healer could never save anyone from a big hit and the clutch
## heal — one of the best moments in the genre — would be structurally
## impossible. Several tests below exist purely to keep that reachable.

const C = preload("res://sim/model/Combatant.gd")
const R = preload("res://sim/model/Raider.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const E = preload("res://sim/model/Enums.gd")

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

func _raider(class_key: String):
    var r = R.new()
    r.id = "r-%s" % class_key
    r.display_name = class_key.capitalize()
    r.class_id = E.class_from_key(class_key)
    return r

func _combatant(class_key: String = "warrior", slot: int = 0):
    return C.create(_raider(class_key), _db, slot)

# ---------------------------------------------------------------- creation

func test_created_at_full_health_from_the_raider() -> void:
    var c = _combatant("warrior")
    assert_eq(c.max_hp, 120, "Warrior base HP with no gear")
    assert_eq(c.current_hp, 120)
    assert_true(c.is_alive())
    assert_eq(c.threat, 0)
    assert_eq(c.live_tokens().size(), 0)

func test_hp_reflects_equipped_gear() -> void:
    var r = _raider("warrior")
    for id in ["ITM_T1_ADV_WARBARD_HEAD", "ITM_T1_ADV_WARBARD_CHEST",
               "ITM_T1_ADV_WARBARD_LEGS", "ITM_T1_ADV_WARBARD_FEET"]:
        r.equip(_db, _db.item(id))
    var c = C.create(r, _db, 0)
    assert_eq(c.max_hp, 136, "120 base + 16 from canon adventure armour")

# ---------------------------------------------------------------- downed

func test_reaching_zero_hp_downs_rather_than_kills() -> void:
    var c = _combatant("mage")           # 65 HP
    c.take_damage(65)
    assert_true(c.is_downed(), "zero HP must mean Downed, not Dead")
    assert_false(c.is_dead())
    assert_eq(c.current_hp, 0, "HP is pinned at zero while Downed")

func test_downed_raiders_take_no_further_damage() -> void:
    var c = _combatant("mage")
    c.take_damage(65)
    c.take_damage(10)
    assert_true(c.is_downed(), "a Downed raider cannot be damaged further")

func test_downed_is_a_valid_heal_target_but_not_a_boss_target() -> void:
    var c = _combatant("mage")
    c.take_damage(65)
    assert_true(c.is_valid_heal_target(), "healers must be able to reach them")
    assert_false(c.is_valid_boss_target(), "the boss must not keep hitting them")
    assert_false(c.can_act(), "they take no actions")

func test_the_clutch_heal_brings_them_back() -> void:
    # The moment the Downed state exists to make possible.
    var c = _combatant("mage")
    c.take_damage(65)
    assert_true(c.is_downed())
    var healed: int = c.heal(20)
    assert_true(c.is_alive(), "a heal in Phase 4 must revive a Downed raider")
    assert_eq(c.current_hp, 20, "they come back at the healed amount")
    assert_eq(healed, 20)

func test_unhealed_downed_dies_at_round_close() -> void:
    var c = _combatant("mage")
    c.take_damage(65)
    assert_true(c.confirm_death_at_round_close(), "Phase 7 confirms the death")
    assert_true(c.is_dead())
    assert_eq(c.threat, 0, "death clears threat")

func test_round_close_does_nothing_to_the_living() -> void:
    var c = _combatant("warrior")
    c.take_damage(10)
    assert_false(c.confirm_death_at_round_close())
    assert_true(c.is_alive())

func test_overkill_skips_downed_entirely() -> void:
    # docs/07 §7.1: a big enough hit is not survivable by luck.
    var c = _combatant("mage")           # 65 HP
    c.take_damage(65 + C.OVERKILL_MARGIN)
    assert_true(c.is_dead(), "overkill kills outright")
    assert_false(c.is_downed())

func test_damage_just_below_the_overkill_line_still_downs() -> void:
    var c = _combatant("mage")
    c.take_damage(65 + C.OVERKILL_MARGIN - 1)
    assert_true(c.is_downed(), "one point short of overkill leaves a heal window")

# ---------------------------------------------------------------- dead

func test_dead_raiders_cannot_be_healed() -> void:
    var c = _combatant("rogue")
    c.kill()
    assert_eq(c.heal(50), 0, "healing a corpse restores nothing")
    assert_true(c.is_dead())
    assert_false(c.is_valid_heal_target(), "that heal is MIS_HEAL_CORPSE, not an action")

func test_dead_raiders_absorb_no_damage() -> void:
    var c = _combatant("rogue")
    c.kill()
    c.take_damage(100)
    assert_eq(c.current_hp, 0)
    assert_true(c.is_dead())

# ---------------------------------------------------------------- healing

func test_healing_caps_at_max_hp() -> void:
    var c = _combatant("warrior")
    c.take_damage(30)
    var healed: int = c.heal(100)
    assert_eq(c.current_hp, 120)
    assert_eq(healed, 30, "returns the amount actually restored, not requested")

func test_healing_a_full_target_restores_nothing() -> void:
    var c = _combatant("warrior")
    assert_eq(c.heal(40), 0, "overhealing is a wasted heal, and the log should say so")

func test_negative_and_zero_amounts_are_inert() -> void:
    var c = _combatant("warrior")
    c.take_damage(0)
    c.take_damage(-5)
    assert_eq(c.current_hp, 120)
    assert_eq(c.heal(0), 0)

func test_hp_fraction() -> void:
    var c = _combatant("warrior")
    c.take_damage(60)
    assert_almost(c.hp_fraction(), 0.5, 0.001)

# ---------------------------------------------------------------- threat

func test_threat_accumulates_and_never_goes_negative() -> void:
    var c = _combatant("warrior")
    c.add_threat(100)
    c.add_threat(50)
    assert_eq(c.threat, 150)
    c.add_threat(-500)
    assert_eq(c.threat, 0, "threat floors at zero")

func test_dead_raiders_gain_no_threat() -> void:
    var c = _combatant("warrior")
    c.kill()
    c.add_threat(100)
    assert_eq(c.threat, 0)

func test_downed_raiders_hold_threat() -> void:
    # docs/07 §7.1: Downed holds threat but is not a valid target.
    var c = _combatant("warrior")
    c.add_threat(200)
    c.take_damage(120)
    assert_true(c.is_downed())
    assert_eq(c.threat, 200, "threat survives being Downed")

# ---------------------------------------------------------------- tokens

func test_aggro_token_lives_this_round_and_the_next() -> void:
    # docs/07 §6: Aggro = this round + next.
    var c = _combatant("rogue")
    c.add_token(E.Token.AGGRO, 4)
    assert_true(c.has_token(E.Token.AGGRO))
    assert_eq(c.expire_tokens(4).size(), 0, "still live in the round it was emitted")
    assert_eq(c.expire_tokens(5).size(), 0, "still live the following round")
    assert_eq(c.expire_tokens(6).size(), 1, "gone by the round after that")
    assert_false(c.has_token(E.Token.AGGRO))

func test_distraction_lasts_two_rounds() -> void:
    var c = _combatant("bard")
    c.add_token(E.Token.DISTRACTION, 1)
    c.expire_tokens(2)
    assert_true(c.has_token(E.Token.DISTRACTION))
    c.expire_tokens(3)
    assert_false(c.has_token(E.Token.DISTRACTION))

func test_fire_and_mana_persist_until_cleared() -> void:
    # Fire lasts until the raider leaves it; Mana for the rest of the encounter.
    var c = _combatant("mage")
    c.add_token(E.Token.FIRE, 1)
    c.add_token(E.Token.MANA, 1)
    for r in range(2, 40):
        c.expire_tokens(r)
    assert_true(c.has_token(E.Token.FIRE), "Fire does not time out")
    assert_true(c.has_token(E.Token.MANA), "Mana lasts the encounter")
    c.clear_token(E.Token.FIRE)
    assert_false(c.has_token(E.Token.FIRE), "stepping out clears it")

func test_refreshing_a_token_extends_never_shortens() -> void:
    var c = _combatant("warrior")
    c.add_token(E.Token.AGGRO, 4)     # live through round 5
    c.add_token(E.Token.AGGRO, 6)     # refreshed, now through round 7
    c.expire_tokens(6)
    assert_true(c.has_token(E.Token.AGGRO), "the refresh must extend it")
    c.expire_tokens(8)
    assert_false(c.has_token(E.Token.AGGRO))

func test_live_tokens_are_deterministically_ordered() -> void:
    # Golden files compare logs; token order must not wobble.
    var a = _combatant("warrior")
    a.add_token(E.Token.DISTRACTION, 1)
    a.add_token(E.Token.AGGRO, 1)
    var b = _combatant("warrior")
    b.add_token(E.Token.AGGRO, 1)
    b.add_token(E.Token.DISTRACTION, 1)
    assert_eq(a.live_tokens(), b.live_tokens(), "insertion order must not matter")

# -------------------------------------------------- docs/10 §10 mechanic state

func test_a_silence_window_stops_a_raider_acting_and_then_lets_go() -> void:
    # docs/10 §10 M10's silence half. `can_act()` with no round keeps its old
    # meaning for every caller that does not care, which is all of them except
    # the two RaidSim phases; the round is needed because the window has an end
    # and a Combatant owns no clock (house rule 6).
    var c = _combatant("mage")
    c.silenced_until = 4
    assert_true(c.can_act(), "the roundless reading is unchanged")
    assert_false(c.can_act(3), "silenced through round 4")
    assert_false(c.can_act(4))
    assert_true(c.can_act(5), "and free the round after")

func test_a_dead_raider_is_not_merely_silenced() -> void:
    var c = _combatant("mage")
    c.kill()
    assert_false(c.can_act(), "death outranks every other reason to skip")
    assert_false(c.can_act(99))

func test_the_healing_debuff_is_a_magnitude_with_an_expiry() -> void:
    # docs/10 §10 M09: "Healing on the current tank reduced `p%` for `N` rounds."
    # Zero outside the window rather than a stale percentage, so a stamp nobody
    # cleared cannot quietly halve a heal ten rounds later.
    var c = _combatant("warrior")
    assert_eq(c.effective_healing_reduction(1), 0, "nothing by default")
    c.healing_reduction_pct = 40
    c.healing_reduction_until = 6
    assert_eq(c.effective_healing_reduction(6), 40)
    assert_eq(c.effective_healing_reduction(7), 0, "the window closed")

func test_tank_duty_and_the_swap_debuff_start_clean() -> void:
    # docs/10 §10 M01. `is_main_tank` is who the raid brought; `is_active_tank`
    # is whose turn it is, and RaidSim assigns both.
    var c = _combatant("warrior")
    assert_eq(c.tank_debuff_stacks, 0)
    assert_false(c.is_active_tank)
    assert_false(c.is_main_tank)

func test_a_stance_is_one_of_two_flags_and_nothing_spatial() -> void:
    # docs/07 OQ-7, in the abstract-flags-only reading proposed in
    # build/plan/q-mech-arms.md: there is no third state and no coordinate.
    var c = _combatant("rogue")
    assert_true(c.stance in [E.Stance.SPREAD, E.Stance.STACKED])

# ---------------------------------------------------------------- persistence

func test_round_trip_preserves_the_mechanic_state_too() -> void:
    # docs/14 OQ-11 with docs/14 §8's teeth: a resumed encounter that forgot
    # these would hand the boss a fresh tank at zero stacks, drop a live silence
    # and un-debuff a healing target. A save that makes the fight easier is
    # save-scumming with extra steps.
    var r = _raider("warrior")
    var c = C.create(r, _db, 3)
    c.is_main_tank = true
    c.is_active_tank = true
    c.tank_debuff_stacks = 2
    c.stance = E.Stance.SPREAD
    c.healing_reduction_pct = 40
    c.healing_reduction_until = 9
    c.silenced_until = 5

    var back = C.from_dict(c.to_dict(), r)
    assert_true(back.is_active_tank)
    assert_eq(back.tank_debuff_stacks, 2)
    assert_eq(back.stance, E.Stance.SPREAD)
    assert_eq(back.effective_healing_reduction(9), 40)
    assert_eq(back.effective_healing_reduction(10), 0)
    assert_false(back.can_act(5), "still silenced after the reload")

func test_a_row_written_before_the_mechanic_fields_reads_back_as_a_default() -> void:
    # `stance_from_key` returns -1 for an absent key, and a stance of -1 would
    # match no demand and take M07 damage forever. An old save must not do that.
    var r = _raider("cleric")
    var back = C.from_dict({"slot_index": 1, "max_hp": 90, "current_hp": 90,
        "state": "alive", "threat": 0, "tokens": {}}, r)
    assert_eq(back.stance, E.Stance.STACKED)
    assert_eq(back.tank_debuff_stacks, 0)
    assert_eq(back.silenced_until, 0)
    assert_true(back.can_act(1))

func test_an_unrecognised_stance_key_reads_back_as_the_same_default() -> void:
    # The absent-key case above was tested and the UNRECOGNISED one was not,
    # and they disagreed: `stance_from_key` returns -1 for both, and the old
    # `maxi(0, ...)` clamped that to 0 — which is `Stance.SPREAD`, the opposite
    # of the default the same line declares. A hand-edited or forward-version
    # save came back in the wrong stance and took M07 damage for it.
    var r = _raider("cleric")
    for bad in ["foo", "", "SPREAD"]:
        var back = C.from_dict({"slot_index": 1, "max_hp": 90, "current_hp": 90,
            "state": "alive", "threat": 0, "tokens": {}, "stance": bad}, r)
        assert_eq(back.stance, E.Stance.STACKED,
            "stance %s did not fall back to the declared default" % [bad])

func test_round_trip_preserves_encounter_state() -> void:
    # docs/14 OQ-11: an encounter must be resumable mid-fight.
    var r = _raider("cleric")
    var c = C.create(r, _db, 7)
    c.take_damage(30)
    c.add_threat(120)
    c.add_token(E.Token.MANA, 3)
    c.is_main_tank = false
    c.is_offtank = true

    var back = C.from_dict(c.to_dict(), r)
    assert_eq(back.slot_index, 7)
    assert_eq(back.current_hp, c.current_hp)
    assert_eq(back.max_hp, c.max_hp)
    assert_eq(back.threat, 120)
    assert_true(back.has_token(E.Token.MANA))
    assert_true(back.is_offtank)
    assert_eq(back.state, c.state)

func test_round_trip_preserves_downed_state() -> void:
    var r = _raider("mage")
    var c = C.create(r, _db, 0)
    c.take_damage(65)
    var back = C.from_dict(c.to_dict(), r)
    assert_true(back.is_downed(), "a save mid-encounter must not resurrect anyone")

func test_the_raider_record_is_untouched_by_combat() -> void:
    # The whole reason this class exists: docs/04 §4 keeps the roster record
    # free of combat state so it stays serialisable mid-raid.
    var r = _raider("warrior")
    var c = C.create(r, _db, 0)
    c.take_damage(100)
    c.add_threat(50)
    c.kill()
    var d := r.to_dict()
    assert_false(d.has("current_hp"))
    assert_false(d.has("threat"))
    assert_false(d.has("state"))
    assert_eq(r.morale, 50, "combat did not touch morale here either")
