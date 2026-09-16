extends "res://tests/TestCase.gd"
## The Adventure tier (docs/10 §8), and the measured reason it cannot yet be won.

const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Formulas = preload("res://sim/core/Formulas.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Scenarios = preload("res://tests/golden/Scenarios.gd")
const Encounter = preload("res://sim/model/Encounter.gd")

## The measured nominal party DPS at each gear stage (docs/15 BL-28), replacing
## docs/10 §8's ~88 — which was half of STAGE A (full Adventure gear) and which
## the doc itself flagged as an upper bound because Adventures are played below
## stage A. Measured with docs/08 §9.1's own nominal method on the benchmark six.
##
## Each rung is sized for the gear the rung before it dropped, which is exactly
## the rule docs/08 §9.2 already applies to the raid tier.
const STAGE_DPS := {"A1": 16.5, "A2": 54.9, "A3": 58.2}

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

func _adv(slot: String):
    for e in _db.adventure_encounters(1):
        if e.slot == slot:
            return e
    return null

# ---------------------------------------------------------------- shape

func test_the_adventure_tier_loads() -> void:
    var all: Array = _db.adventure_encounters(1)
    assert_eq(all.size(), 3,
        "canon: 'a few trash encounters and a mini boss' — docs/10 §8 makes it 3")
    assert_eq(all[0].slot, "A1")
    assert_eq(all[2].slot, "A3")

func test_content_still_validates_with_adventures_added() -> void:
    assert_true(_db.is_valid(), _db.error_report())

func test_adventures_are_half_headcount_with_one_tank() -> void:
    # docs/10 §3. Six slots makes an Adventure a ROSTER puzzle rather than a
    # gear puzzle: you cannot bring one of everything.
    for e in _db.adventure_encounters(1):
        assert_eq(e.party_size, 6, "%s party size" % e.slot)
        assert_eq(e.tanks_required, 1, "%s tanks required" % e.slot)
        assert_true(e.party_size < Enums.RAID_SIZE,
            "an Adventure must be smaller than a raid")

func test_the_ladder_climbs_two_trash_then_a_mini_boss() -> void:
    # canon: "a few trash encounters and a mini boss".
    assert_eq(_adv("A1").kind, Enums.EncounterKind.TRASH)
    assert_eq(_adv("A2").kind, Enums.EncounterKind.HARD_TRASH)
    assert_eq(_adv("A3").kind, Enums.EncounterKind.MINI_BOSS)
    for slot in ["A1", "A2", "A3"]:
        assert_ne(_adv(slot).kind, Enums.EncounterKind.MAIN_BOSS,
            "docs/10 §3: an Adventure tops out below a Raid — no main boss")

func test_stars_climb_one_to_three() -> void:
    assert_eq(_adv("A1").stars, 1)
    assert_eq(_adv("A2").stars, 2)
    assert_eq(_adv("A3").stars, 3)

# ---------------------------------------------------------------- canon numbers

func test_hp_matches_the_re_derived_table() -> void:
    # RE-DERIVED from the measured stages (docs/15 BL-28). docs/10 §8's printed
    # 705 / 880 / 1055 came from ~88/round, which was 5.3x too high for A1 — and
    # the doc said so itself: "88 is an upper bound ... ask doc 08 for the stage."
    assert_eq(_adv("A1").total_hp(), 135)
    assert_eq(_adv("A2").total_hp(), 550)
    assert_eq(_adv("A3").total_hp(), 700)

func test_each_row_is_sized_for_the_gear_the_rung_before_it_dropped() -> void:
    # hp_total = stage_dps x target_rounds, applied PER ENCOUNTER at that rung's
    # OWN gear stage. Sizing every rung against one figure is what made docs/10
    # §8's table wrong; this is the check that keeps it honest.
    for e in _db.adventure_encounters(1):
        var dps: float = float(STAGE_DPS[e.slot])
        var expected: int = int(round(dps * float(e.target_rounds)))
        assert_true(absi(e.total_hp() - expected) <= 6,
            "%s: %d HP is not ~%.1f/rd x %d rounds (= %d)"
            % [e.slot, e.total_hp(), dps, e.target_rounds, expected])

func test_the_first_weapon_is_the_biggest_upgrade_in_the_tier() -> void:
    # Measured: 16.5 -> 54.9/round when A1's weapon lands, a 3.3x jump. That is
    # the correct progression beat for a guild that started with no weapon at
    # all, and it is why canon's "1-2 pieces of basic adventure gear" matters so
    # much at Unknown rank.
    assert_true(float(STAGE_DPS["A2"]) > float(STAGE_DPS["A1"]) * 3.0,
        "the first weapon should roughly triple a bare-handed party's output")

func test_the_tier_still_spans_thirty_target_rounds() -> void:
    # docs/10 §8's round budget is unchanged; only the HP that backs it moved.
    var rounds := 0
    for e in _db.adventure_encounters(1):
        rounds += e.target_rounds
    assert_eq(rounds, 30, "8 + 10 + 12")

func test_enemy_counts_and_swings_match_the_table() -> void:
    # Counts and SWINGS are docs/10 §8's, untouched. Only per-enemy HP moved.
    var expected := {
        "A1": {"count": 3, "hp": 45, "swing": 9, "per_round": 1},
        "A2": {"count": 2, "hp": 275, "swing": 19, "per_round": 1},
        "A3": {"count": 1, "hp": 700, "swing": 25, "per_round": 2},
    }
    for slot in expected:
        var e = _adv(slot)
        var spec: Dictionary = expected[slot]
        assert_eq(e.enemies.size(), 1, "%s should declare one enemy block" % slot)
        var blk = e.enemies[0]
        assert_eq(blk.count, int(spec["count"]), "%s count" % slot)
        assert_eq(blk.hp, int(spec["hp"]), "%s per-enemy hp" % slot)
        assert_eq(blk.raw_swing, int(spec["swing"]), "%s raw swing" % slot)
        assert_eq(blk.swings_per_round, int(spec["per_round"]), "%s swings" % slot)

## docs/10 §8's own "Unhealed clock" column — the pressure each rung intends.
const INTENDED_CLOCK := {"A1": 5.5, "A2": 4.3, "A3": 3.5}

## What that rung's tank is actually wearing when it is fought, which is the gear
## the rung BEFORE it dropped (docs/10 §8's loot column).
const STAGE_ADDS := {
    "A1": [], "A2": ["feet", "main_hand"], "A3": ["feet", "main_hand", "legs"],
}

func _stage_equipped(key: String, slot: String, morale: int = 55):
    var r = _starting(key, morale)
    var cd = _db.class_by_key(key)
    for slot_key in STAGE_ADDS[slot]:
        var s: int = Enums.slot_from_key(String(slot_key))
        var fam: int = cd.family_for_slot(s)
        if fam < 0:
            continue
        for cand in _db.items_for(fam, s):
            if cand.source == "adventure":
                r.equip(_db, cand)
                break
    return r

func test_every_rung_hits_its_intended_tank_clock_at_its_own_stage() -> void:
    # docs/15 BL-30. docs/08 §9.3's rule is
    #     boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK x (1 - mitigation))
    # and docs/10 §8 applied it at 7 AC / 120 HP for ALL THREE rungs, while its
    # own loot column says each rung is fought in the gear the one before it
    # dropped. That inverted the tier's difficulty curve: measured A1 50%,
    # A2 65%, A3 90% — the ★★★ mini boss was the easiest fight in the tier.
    #
    # This DERIVES each swing from the doc's formula at the real stage rather
    # than hardcoding a number, so it cannot drift and it explains itself.
    # A1 needs no correction: it is the one rung genuinely fought at stage 0,
    # which is why the doc got A1 right and only A2 and A3 wrong.
    for slot in ["A1", "A2", "A3"]:
        var e = _adv(slot)
        var tank = _stage_equipped("warrior", slot)
        var ac: int = tank.gear_stats(_db).ac
        var mit := Formulas.mitigation(ac)
        var clock: float = float(INTENDED_CLOCK[slot])
        var needed := float(tank.max_hp(_db)) / (clock * (1.0 - mit))
        var blk = e.enemies[0]
        var authored := float(blk.raw_swing * blk.swings_per_round * blk.count)
        assert_true(absf(authored - needed) <= 2.0,
            "%s: %d raw/round against %.1f needed for a %.1f-round clock at %d AC"
            % [slot, int(authored), needed, clock, ac]
            + " — recompute at the stage it is fought, never soften it")

## Clear rate for a rung, fielded at ITS OWN stage's gear and Content morale.
func _stage_clear_rate(slot: String) -> float:
    var party: Array = []
    for key in ["warrior", "cleric", "rogue", "rogue", "wizard", "mage"]:
        party.append(_stage_equipped(key, slot))
    var cleared := 0
    for i in 24:
        if RaidSim.run(party, _adv(slot), _db, 1000 + i * 7919).cleared():
            cleared += 1
    return float(cleared) / 24.0

func test_the_mini_boss_is_the_hardest_fight_in_the_tier() -> void:
    # The point of docs/15 BL-30. A3 is ★★★ and gates Raid 1; if it clears more
    # often than the ★ trash pull, the tier's star ratings are decoration.
    var a1 := _stage_clear_rate("A1")
    var a3 := _stage_clear_rate("A3")
    assert_true(a3 < a1,
        "A3 (%.0f%%) must be harder than A1 (%.0f%%)" % [a3 * 100.0, a1 * 100.0])

## A3 IS CURRENTLY A WALL, AND THIS TEST PINS IT RATHER THAN HIDING IT.
##
## Until the twelve mechanics were armed, A3's three of them did nothing, and
## the rung cleared on its boss autoattacks alone. Armed, it clears 0 of 24
## seeds at its own gear stage and Content morale. Measured one mechanic at a
## time on an A3-shaped encounter:
##
##     none  24/24     m01 only  0/24     m02 only  3/24     m03 only  9/24
##
## So docs/10 §8 sized A3's clock against the boss swings and nothing else
## (§8's own table derives `raw/rd` purely from `tank_max_hp / (clock ×
## (1 − mitigation))`), then gave the rung three mechanics on a party of six
## with one tank and one healer. Two canon requirements now collide: docs/10 §8
## says A3 carries M01+M02+M03, while docs/16 X3.1 wants the full ladder
## shippable and docs/10 §3 calls a low clear rate "a gate rather than a wall".
##
## This is a BALANCE decision and the build loop does not get to make it —
## docs/15 records exactly one number ever changed on judgement alone (BL-29) and
## the bar is that there stays exactly one. So the finding is pinned here, with
## its measurement, in the shape this project already uses for a debt it must
## not lose (see LIES_OWED in test_project_hygiene.gd): the test asserts the
## defect is STILL present. The day a designer retunes A3 — or rules that M01
## does not belong on a one-tank rung — this fails and asks to be turned back
## into the assertion it wants to be.
func test_the_mini_boss_is_currently_a_wall_and_that_is_recorded() -> void:
    var rate := _stage_clear_rate("A3")
    assert_eq(rate, 0.0,
        "A3 now clears %.0f%% of 24 seeds. If that is deliberate, restore this "
        % (rate * 100.0)
        + "to `assert_true(rate > 0.0)` and say so in docs/15; if it is not, "
        + "A3's mechanics or its clock need a designer, not a loop.")


func test_enrage_follows_the_validated_rule() -> void:
    # ceil(1.4 x target_rounds), the rule ContentDB validates and every Tier 1
    # raid encounter already follows.
    for e in _db.adventure_encounters(1):
        assert_eq(e.enrage_round, int(ceil(1.4 * float(e.target_rounds))),
            "%s enrage" % e.slot)

func test_every_adventure_carries_a_comedy_line() -> void:
    # docs/10 §6 requires one on every encounter; the board prints it.
    for e in _db.adventure_encounters(1):
        assert_true(e.comedy_line.length() >= Encounter.COMEDY_LINE_MIN,
            "%s has no comedy line" % e.slot)

func test_adventures_drop_adventure_slots_not_raid_capstones() -> void:
    # docs/10 §3: Adventure gear is the Adventure's payout and the prerequisite
    # for the Raid of the same tier.
    var seen := {}
    for e in _db.adventure_encounters(1):
        for slot in e.loot_slots:
            seen[String(slot)] = true
    for wanted in ["feet", "legs", "head", "chest"]:
        assert_true(seen.has(wanted),
            "the Adventure tier must hand out %s" % wanted)
    assert_false(seen.has("capstone"), "capstones are Raid Boss 5 only")

# ---------------------------------------------------- the measured blocker

func _starting(class_key: String, morale: int = 45):
    var r = Raider.new()
    r.id = "s_" + class_key
    r.display_name = class_key.capitalize()
    r.class_id = Enums.class_from_key(class_key)
    r.rarity = Enums.Rarity.COMMON
    r.morale = morale
    for it in _db.starting_set(class_key):
        r.equip(_db, it)
    return r

func test_canon_starting_gear_is_four_armour_pieces_and_no_weapon() -> void:
    # ✅ CANON, raw notes: "Starting armor for common recruits" — armour only.
    # docs/10 §8 states the consequence plainly: "canon gives common recruits no
    # weapon at all".
    for key in ["warrior", "cleric", "mage"]:
        var set_items: Array = _db.starting_set(key)
        assert_eq(set_items.size(), 4, "%s starting set size" % key)
        for it in set_items:
            assert_true(it.is_armor(), "%s: %s is not armour" % [key, it.id])

func test_a_starting_healer_now_heals_something() -> void:
    # This replaces test_a_starting_healer_heals_nothing_which_is_the_real_blocker,
    # which existed to pin the docs/15 BL-27 defect. The floor has landed.
    var cleric = _starting("cleric")
    var gear = cleric.gear_stats(_db)
    assert_eq(gear.mana, 0, "canon starting armour still carries no Mana")
    assert_eq(Formulas.cleric_heal(0, gear.mana), Formulas.HEAL_FLOOR,
        "a weaponless healer falls back to the class floor, not to zero")

func test_the_first_adventure_is_winnable_in_canon_starting_armour() -> void:
    # THE POINT OF THE WHOLE TIER. A1 is the only rung played in pure starting
    # armour, and it is what hands out the first weapon. If this cannot be won,
    # the game has no on-ramp and nothing beyond it is reachable.
    var comp := ["warrior", "cleric", "rogue", "rogue", "wizard", "mage"]
    var party: Array = []
    for key in comp:
        party.append(_starting(key, 55))
    var cleared := 0
    for i in 20:
        if RaidSim.run(party, _adv("A1"), _db, 1000 + i * 7919).cleared():
            cleared += 1
    assert_true(cleared >= 5,
        "a fresh guild must be able to clear its first mission — got %d/20"
        % cleared)

func test_the_opening_rung_is_still_a_real_fight() -> void:
    # docs/01 §7.2 gives hour one the beat "these people are idiots" with failure
    # meaning "Comedy". A1 must be winnable, not a formality — a 100% clear on
    # the first mission of a game called It's A Wipe! would be the wrong joke.
    var comp := ["warrior", "cleric", "rogue", "rogue", "wizard", "mage"]
    var party: Array = []
    for key in comp:
        party.append(_starting(key, 55))
    var cleared := 0
    for i in 20:
        if RaidSim.run(party, _adv("A1"), _db, 1000 + i * 7919).cleared():
            cleared += 1
    assert_true(cleared <= 17, "A1 should still bite sometimes — got %d/20" % cleared)

# ------------------ docs/08 §9.1a's two middle stages, built at last (M6-BAL-01)

## `tests/golden/Scenarios.gd` could build four gear rungs — starting, adventure,
## raid_entry, raid — and neither of §9.1a's intermediate Adventure stages was
## among them. So `tools/balance_sweep.gd` could only BRACKET the Adventure
## ladder: no cell in 1,872 runs sat on the stage a rung is actually sized for,
## which is the one number that answers "is this rung fair". Both stages exist
## now and the sweep's Adventure table marks that diagonal.
##
## §9.1a lists each stage's contents item by item, and these tests hold the
## contents rather than the measured output — the 16.5 / 54.9 / 58.2 figures are
## already pinned above in `STAGE_DPS`, and re-deriving them here would be a
## second implementation of the same measurement.

const MIDDLE_STAGES := ["after_a1", "after_a2"]


func _party(gear: String) -> Array:
    return Scenarios.build_roster({
        "class_keys": Scenarios.BENCHMARK, "rarity": Enums.Rarity.COMMON,
        "morale": 55, "gear": gear,
    }, _db)


## `Raider.equipment` is slot -> item id, and it is the field rather than `gear`
## — worth saying, because `gear` is what the SPEC dictionaries call the rung and
## reaching for `r.gear` here reads perfectly and is a different thing entirely.
func _equipped_slots(r) -> Array:
    var out: Array = []
    for slot in r.equipment:
        out.append(int(slot))
    out.sort()
    return out


func test_the_two_middle_stages_build_at_all() -> void:
    for gear in MIDDLE_STAGES:
        var party: Array = _party(gear)
        assert_eq(party.size(), Scenarios.BENCHMARK.size(),
            "%s must build the benchmark party" % gear)


func test_after_a1_is_starting_armour_plus_feet_and_the_first_weapon() -> void:
    # §9.1a, quoted: "+ Adventure `feet` + first weapon". The weapon is the whole
    # point — §9.1a calls it "the largest single upgrade in the game", 16.5 to
    # 54.9 from one item per raider.
    var base: Array = _party("starting")
    var mid: Array = _party("after_a1")
    for i in mid.size():
        var gained: Array = []
        for slot in _equipped_slots(mid[i]):
            if not _equipped_slots(base[i]).has(slot):
                gained.append(slot)
        assert_true(gained.has(Enums.Slot.MAIN_HAND),
            "%s gains a weapon at after_a1" % Scenarios.BENCHMARK[i])


func test_after_a2_adds_exactly_the_legs() -> void:
    # "+ Adventure `legs`", and nothing else — which is why 54.9 only moves to
    # 58.2. A stage that quietly picked up a second piece would make A3 look
    # fairer than it is.
    var mid: Array = _party("after_a1")
    var late: Array = _party("after_a2")
    for i in late.size():
        var before := _equipped_slots(mid[i])
        for slot in _equipped_slots(late[i]):
            assert_true(before.has(slot) or slot == Enums.Slot.LEGS,
                "after_a2 added slot %d, and §9.1a only lists legs" % int(slot))


func test_no_charm_at_the_intermediate_stages() -> void:
    # §9.1a lists each stage's contents and a trinket is not among them. Wearing
    # one would make the swept party stronger than the party 54.9 and 58.2 were
    # measured on — the same category of error as sweeping Boss 5 in its own
    # capstone.
    for gear in MIDDLE_STAGES:
        for r in _party(gear):
            assert_false(r.equipment.has(Enums.Slot.TRINKET),
                "%s must not wear a charm" % gear)


func test_the_stages_are_strictly_a_ladder() -> void:
    # The property the sweep depends on: each stage is at least as equipped as
    # the one before it, everywhere. If this inverts, the Adventure table's
    # diagonal stops meaning anything.
    var rungs := ["starting", "after_a1", "after_a2", "adventure"]
    for step in range(1, rungs.size()):
        var lower: Array = _party(rungs[step - 1])
        var upper: Array = _party(rungs[step])
        for i in upper.size():
            assert_true(_equipped_slots(upper[i]).size()
                    >= _equipped_slots(lower[i]).size(),
                "%s must not be less equipped than %s for %s"
                    % [rungs[step], rungs[step - 1], Scenarios.BENCHMARK[i]])


func test_the_sweep_meets_every_rung_at_its_own_stage() -> void:
    # docs/15 BL-28's map, which `tools/balance_sweep.gd` now holds as
    # ADVENTURE_STAGE and marks with a star. The two files must agree or the
    # starred cell is the wrong cell.
    var sweep := FileAccess.get_file_as_string("res://tools/balance_sweep.gd")
    assert_true(sweep.contains('ADVENTURE_STAGE := {"A1": "starting", "A2": "after_a1", "A3": "after_a2"}'),
        "the sweep's stage map must match STAGE_DPS's rungs")
    for gear in MIDDLE_STAGES:
        assert_true(sweep.contains('"%s"' % gear),
            "the sweep must actually sweep %s" % gear)
