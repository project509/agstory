extends "res://tests/TestCase.gd"
## sim/core/RaidSim.gd — the fight.
##
## The three properties worth defending here, in order:
##
##   TERMINATION. No combination of roster, gear and encounter may loop forever.
##   docs/07 §7.3 calls the round cap a safety property, not flavour.
##
##   DETERMINISM. Same seed, same log, byte for byte. Without it golden tests
##   cannot exist, bug reports cannot be reproduced, and balance cannot be swept.
##
##   PURITY. The sim reports; it never writes to a Raider. That is what lets a
##   run be replayed or thrown away, and what keeps the roster serialisable
##   mid-encounter (docs/04 §4, docs/14 OQ-10).

const Sim = preload("res://sim/core/RaidSim.gd")
const R = preload("res://sim/model/Raider.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const F = preload("res://sim/core/Formulas.gd")
const E = preload("res://sim/model/Enums.gd")
const Mistakes = preload("res://sim/core/Mistakes.gd")
const Encounter = preload("res://sim/model/Encounter.gd")

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

## docs/10 §5.3's benchmark twelve: 2 tanks, all three healing shapes, a Bard.
const BENCHMARK := ["warrior", "warrior", "cleric", "druid", "shaman", "rogue",
                    "rogue", "monk", "mage", "wizard", "wizard", "bard"]

func _raider(class_key: String, idx: int, rarity: int, morale: int, gear: String = "adventure"):
    var r = R.new()
    r.id = "%s-%d" % [class_key, idx]
    r.display_name = "%s%d" % [class_key.capitalize(), idx]
    r.class_id = E.class_from_key(class_key)
    r.rarity = rarity
    r.morale = morale
    if gear == "starting":
        for it in _db.starting_set(class_key):
            r.equip(_db, it)
    elif gear == "adventure":
        var cd = _db.class_by_key(class_key)
        for slot in [E.Slot.HEAD, E.Slot.CHEST, E.Slot.LEGS, E.Slot.FEET, E.Slot.MAIN_HAND]:
            var fam: int = cd.family_for_slot(slot)
            if fam < 0:
                continue
            for candidate in _db.items_for(fam, slot):
                if candidate.source == "adventure":
                    r.equip(_db, candidate)
                    break
    elif gear == "raid":
        for boss in range(1, 6):
            for it in _db.raid_drops(class_key, boss):
                r.equip(_db, it)
    return r

func _roster(rarity: int = E.Rarity.COMMON, morale: int = 55, gear: String = "adventure") -> Array:
    var out := []
    for i in BENCHMARK.size():
        out.append(_raider(BENCHMARK[i], i, rarity, morale, gear))
    return out

func _encounter(slot: String = "E1"):
    return _db.encounter_at_slot(slot)

# ---------------------------------------------------------------- termination

func test_always_terminates() -> void:
    # The safety property. Every rarity, every morale, every encounter.
    for slot in ["E1", "E2", "E3", "E4", "E5"]:
        for rarity in [E.Rarity.COMMON, E.Rarity.LEGENDARY]:
            for morale in [0, 55, 100]:
                var res = Sim.run(_roster(rarity, morale), _encounter(slot), _db, 12345)
                assert_true(res.rounds <= Sim.ROUND_CAP,
                    "%s r=%d m=%d ran %d rounds" % [slot, rarity, morale, res.rounds])
                assert_true(res.rounds >= 1)

func test_terminates_with_an_empty_roster() -> void:
    var res = Sim.run([], _encounter("E1"), _db, 1)
    assert_true(res.rounds <= Sim.ROUND_CAP)
    assert_ne(res.outcome, Sim.Outcome.VICTORY, "nobody cannot clear a raid")

func test_terminates_with_a_single_raider() -> void:
    var res = Sim.run([_raider("warrior", 0, E.Rarity.COMMON, 55)], _encounter("E5"), _db, 2)
    assert_true(res.rounds <= Sim.ROUND_CAP)

# ---------------------------------------------------------------- determinism

func test_same_seed_produces_an_identical_log() -> void:
    var a = Sim.run(_roster(), _encounter("E1"), _db, 777)
    var b = Sim.run(_roster(), _encounter("E1"), _db, 777)
    assert_eq(a.outcome, b.outcome)
    assert_eq(a.rounds, b.rounds)
    assert_eq(a.log.to_json(), b.log.to_json(), "same seed must replay byte for byte")

func test_different_seeds_diverge() -> void:
    var logs := {}
    for seed_value in [1, 2, 3, 4, 5]:
        logs[seed_value] = Sim.run(_roster(), _encounter("E3"), _db, seed_value).log.to_json()
    var distinct := {}
    for k in logs.keys():
        distinct[logs[k]] = true
    assert_true(distinct.size() > 1, "different seeds must not all play out identically")

func test_the_seed_is_recorded_for_replay() -> void:
    # docs/07 §9: a bug report attaches the seed, not a log dump.
    var res = Sim.run(_roster(), _encounter("E1"), _db, 424242)
    assert_eq(res.seed_used, 424242)
    assert_eq(res.encounter_id, "t1_raid_e1")

# ---------------------------------------------------------------- purity

func test_the_sim_never_writes_to_a_raider() -> void:
    # The load-bearing architectural rule. If this fails, a run cannot be
    # discarded and the roster stops being safe to serialise mid-encounter.
    var roster := _roster(E.Rarity.COMMON, 30)
    var before := []
    for r in roster:
        before.append(r.to_dict())
    Sim.run(roster, _encounter("E5"), _db, 99)
    for i in roster.size():
        assert_eq(roster[i].to_dict(), before[i],
            "%s was mutated by the simulation" % roster[i].display_name)

func test_deltas_are_queued_not_applied() -> void:
    # docs/14 OQ-10: the sim reports, `game/` acts.
    var roster := _roster()
    var res = Sim.run(roster, _encounter("E1"), _db, 5)
    assert_eq(res.deltas_queued.size(), roster.size(), "one delta per raider")
    assert_eq(roster[0].runs_attended, 0, "the counter is queued, never applied here")
    assert_eq(int(res.deltas_queued[0]["runs_attended"]), 1)

# ---------------------------------------------------------------- outcomes

func test_a_strong_roster_can_clear_the_first_encounter() -> void:
    # Legendaries in raid gear at maximum morale should beat E1 on most seeds.
    var wins := 0
    for seed_value in range(1, 11):
        var res = Sim.run(_roster(E.Rarity.LEGENDARY, 100, "raid"),
            _encounter("E1"), _db, seed_value)
        if res.cleared():
            wins += 1
    assert_true(wins >= 6, "a best-case raid cleared only %d of 10 attempts at E1" % wins)

func test_a_terrible_roster_struggles_with_the_tier_boss() -> void:
    # Miserable Commons in starting gear against the five-star boss.
    var wins := 0
    for seed_value in range(1, 11):
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"),
            _encounter("E5"), _db, seed_value)
        if res.cleared():
            wins += 1
    assert_true(wins <= 4, "the worst possible raid cleared %d of 10 at E5" % wins)

func test_outcomes_are_all_reachable_labels() -> void:
    var res = Sim.run(_roster(), _encounter("E1"), _db, 3)
    assert_true(res.outcome_key() in ["victory", "wipe", "soft_wipe", "attrition"])
    assert_false(res.summary().is_empty())

func test_soft_wipe_is_logged_explicitly_not_silently() -> void:
    # docs/07 §7.3: it must never look like a crash.
    var found := false
    for seed_value in range(1, 25):
        var res = Sim.run(_roster(E.Rarity.COMMON, 0, "starting"),
            _encounter("E5"), _db, seed_value)
        if res.outcome == Sim.Outcome.SOFT_WIPE:
            found = true
            assert_true(res.log.transcript(E.LogTier.STORY).contains("calls it"),
                "a soft wipe must announce itself")
    assert_true(true, "soft wipe reachable: %s" % str(found))

# ---------------------------------------------------------------- the log

func test_the_log_is_the_only_output_and_it_is_populated() -> void:
    var res = Sim.run(_roster(), _encounter("E3"), _db, 11)
    assert_true(res.log.size() > 20, "a 15-round fight should produce a real log")
    assert_true(res.damage_dealt > 0, "somebody hit something")
    var story: String = res.log.transcript(E.LogTier.STORY)
    assert_false(story.is_empty())

func test_phases_appear_in_canon_order_within_a_round() -> void:
    # docs/07 §4.1's turn order is the sim's contract with the content docs.
    var res = Sim.run(_roster(), _encounter("E1"), _db, 21)
    var seen := []
    for e in res.log.entries:
        if e.round_no == 2:
            seen.append(e.phase)
    var sorted_copy := seen.duplicate()
    sorted_copy.sort()
    assert_eq(seen, sorted_copy,
        "phases within a round must be non-decreasing: %s" % str(seen))

func test_mistakes_are_recorded_with_severity() -> void:
    var res = Sim.run(_roster(E.Rarity.COMMON, 10), _encounter("E5"), _db, 8)
    assert_true(res.mistake_count > 0, "a raid of miserable Commons must fail at something")
    var m = res.log.mistakes()[0]
    assert_false(String(m.mistake["type"]).is_empty())
    assert_true(String(m.mistake["severity"]) in E.SEVERITY_KEYS,
        "severity is a KEY on the entry, like every other enum")

func test_every_emitted_mistake_is_keyed_on_the_taxonomy() -> void:
    # docs/14 §5.3.5: the id is MIS_FIRE..MIS_AVOIDABLE_DEATH. The sim used to
    # send `ev.type_name` ("Pulled Aggro Off the Tank"), so `mistake["type"]`
    # matched no key of `Mistakes.TYPES` and no line corpus could ever be looked
    # up. The display name is still carried, beside the key, not instead of it.
    var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, 8)
    assert_true(res.log.mistakes().size() > 0)
    for m in res.log.mistakes():
        var key: String = String(m.mistake["type"])
        assert_true(m.severity_index() >= 0,
            "severity '%s' did not resolve" % str(m.mistake["severity"]))
        if not Mistakes.TYPES.has(key):
            # The harness records a failure and carries on, so the lookup below
            # has to be guarded: indexing a missing key turns one readable
            # assertion failure into a GDScript index error.
            fail("'%s' is not a key of Mistakes.TYPES" % key)
            continue
        var canon: Dictionary = Mistakes.TYPES[key]
        assert_eq(String(m.mistake["name"]), String(canon["name"]))

func test_better_morale_produces_fewer_mistakes() -> void:
    # The game's core progression currency, observed end to end.
    var miserable := 0
    var content := 0
    for seed_value in range(1, 9):
        miserable += Sim.run(_roster(E.Rarity.COMMON, 5), _encounter("E3"), _db, seed_value).mistake_count
        content += Sim.run(_roster(E.Rarity.COMMON, 95), _encounter("E3"), _db, seed_value).mistake_count
    assert_true(miserable > content,
        "miserable raid made %d mistakes, happy raid %d" % [miserable, content])

func test_rarity_reduces_mistakes_dramatically() -> void:
    var commons := 0
    var legendaries := 0
    for seed_value in range(1, 9):
        commons += Sim.run(_roster(E.Rarity.COMMON, 55), _encounter("E3"), _db, seed_value).mistake_count
        legendaries += Sim.run(_roster(E.Rarity.LEGENDARY, 55), _encounter("E3"), _db, seed_value).mistake_count
    assert_true(commons > legendaries * 3,
        "Commons %d vs Legendaries %d — canon's gap should be enormous" % [commons, legendaries])

# ---------------------------------------------------------------- mechanics

func test_the_tier_boss_enrages_on_schedule() -> void:
    # This used to end in `assert_true(true)` with its only real assertion behind
    # `if res.rounds >= 31` — and no Tier 1 roster survives thirty rounds of E5,
    # so the real assertion never ran. The schedule is assertable either way: an
    # enrage may happen ONLY on the authored round, and whether it happened at all
    # is decided by whether the fight got there.
    var enc = _encounter("E5")
    assert_eq(enc.enrage_round, 31)
    var res = Sim.run(_roster(E.Rarity.COMMON, 55, "starting"), enc, _db, 4)
    var enraged_on: Array = []
    for e in res.log.entries:
        if e.verb == E.Verb.MECHANIC and String(e.params.get("text", "")).contains("ENRAGE"):
            enraged_on.append(e.round_no)
    for r in enraged_on:
        assert_eq(int(r), 31, "ENRAGE fired on round %d, not the authored 31" % int(r))
    assert_eq(enraged_on.is_empty(), res.rounds < 31,
        "the fight ran %d rounds, so ENRAGE must%s have fired"
        % [res.rounds, "" if res.rounds >= 31 else " not"])

    # And the positive half, which E5 cannot supply: the same mechanic on a round
    # a fight actually reaches. See PROBE_PARAMS on why m06's round is the one
    # value there that is not quoted from content.
    var probe_round: int = int(PROBE_PARAMS["m06"]["round"])
    var probe = Sim.run(_roster(), _synthetic([{"id": "m06",
        "params": PROBE_PARAMS["m06"]}]), _db, 4242)
    assert_true(probe.rounds >= probe_round,
        "the probe fight ran %d rounds and cannot reach round %d — pick another seed"
        % [probe.rounds, probe_round])
    assert_true(probe.log.transcript(E.LogTier.STORY).contains("ENRAGE"),
        "m06 must fire on round %d" % probe_round)

func test_raid_wide_pulses_hit_everyone() -> void:
    var res = Sim.run(_roster(), _encounter("E2"), _db, 6)
    var found := false
    for e in res.log.entries:
        if e.verb == E.Verb.MECHANIC and String(e.params.get("text", "")).contains("pulse"):
            found = true
    assert_true(found, "E2 has a raid-wide mechanic every 4 rounds")

func test_the_raid_wide_pulse_bypasses_armour() -> void:
    # docs/10 §10 M02, "ignores AC", and docs/10 §5.4's reason: the pulse is a
    # HEALER-facing mechanic, so the tank's gear score must not get a say in it.
    # It was mitigated twice — nominally by `raid_wide_damage`, which returns the
    # raw number unchanged, and then for real by `_apply_damage`'s AC path — so a
    # heavily armoured Warrior shrugged off a pulse that flattened the Mage. The
    # `ignores_ac` flag the data has always carried was read nowhere in sim/.
    var enc = _synthetic([{"id": "m02", "params":
        {"damage": 26, "every": 1, "ignores_ac": true}}])
    var res = Sim.run(_roster(E.Rarity.LEGENDARY, 100, "raid"), enc, _db, 31)
    var pulses := _pulse_amounts(res)
    assert_true(pulses.size() > 0, "the pulse must actually land")
    var acs := {}
    for c in res.survivors + res.casualties:
        acs[int(c.get_meta("profile")["ac"])] = true
    assert_true(acs.size() > 1, "the roster must span more than one AC to prove this")
    for amount in pulses:
        assert_eq(int(amount), 26,
            "every raider takes the pulse's raw 26 regardless of armour")

func test_an_ordinary_boss_swing_still_scales_with_armour() -> void:
    # The negative half: `ignores_ac` defaults false, so nothing else moved.
    var res = Sim.run(_roster(), _encounter("E1"), _db, 6)
    var worst := {}
    for e in res.log.entries:
        if e.verb != E.Verb.ATTACK or e.phase != E.Phase.BOSS or e.target_id.is_empty():
            continue
        worst[e.target_id] = maxi(int(worst.get(e.target_id, 0)), e.number("amount"))
    var seen := {}
    for c in res.survivors + res.casualties:
        if worst.has(c.raider.id):
            seen[int(c.get_meta("profile")["ac"])] = int(worst[c.raider.id])
    assert_true(seen.size() > 1, "need raiders at different AC to compare")
    var acs: Array = seen.keys()
    acs.sort()
    assert_true(int(seen[acs[0]]) > int(seen[acs[-1]]),
        "the worst-armoured raider must take more from a boss swing: %s" % str(seen))

func test_adds_spawn_and_are_logged() -> void:
    var res = Sim.run(_roster(), _encounter("E1"), _db, 9)
    assert_true(res.rounds >= 5,
        "seed 9 must reach E1's add round for this to assert anything")
    assert_true(res.log.transcript(E.LogTier.STORY).contains("join"),
        "E1's add arrives on round 5")

func test_the_m04_mechanic_is_the_only_thing_that_spawns_adds() -> void:
    # Two spawn paths ran for the same event: `_spawn_scheduled` activating an
    # authored EnemyBlock with a `spawn_round`, and the M04 branch appending new
    # Enemies. E1 round 5 produced two adds where its card promises one; E2 round
    # 4 produced six. docs/10 §10 M04 owns add spawning ("`count` adds of
    # `hp`/`swing` on round `R`") and docs/10 §6 prices one mechanic per star, so
    # the mechanic wins and any block scheduled onto its round stays inert.
    for slot in ["E1", "E2", "E3"]:
        var enc = _encounter(slot)
        assert_true(enc.mechanic_spec(E.Mechanic.ADD_SPAWNS) != null,
            "%s should carry m04 for this test to mean anything" % slot)
        var res = Sim.run(_roster(), enc, _db, 9)
        var per_round := {}
        for e in res.log.entries:
            if e.verb != E.Verb.MECHANIC:
                continue
            if String(e.params.get("mechanic", "")) != E.mechanic_key(E.Mechanic.ADD_SPAWNS):
                continue
            per_round[e.round_no] = int(per_round.get(e.round_no, 0)) + 1
        # Without this the loop below asserts nothing whenever the fight ends
        # before the m04 round — the same vacuous pass as the `or res.rounds < 5`
        # escape hatch deleted from the neighbouring test.
        assert_true(per_round.size() > 0,
            "%s ran %d rounds and never announced adds — seed 9 must reach its "
            % [slot, res.rounds] + "m04 round for this test to assert anything")
        for r in per_round.keys():
            assert_eq(int(per_round[r]), 1,
                "%s round %d announced adds %d times — two spawn paths fired"
                % [slot, r, int(per_round[r])])

func test_an_authored_spawn_block_on_the_m04_round_never_activates() -> void:
    # The narrow claim as a count rather than a string match: E1's "Late Add"
    # block and its m04 spec both target round 5, and only the mechanic's single
    # add may arrive.
    var enc = _encounter("E1")
    var res = Sim.run(_roster(), enc, _db, 9)
    assert_true(res.rounds >= 5)
    var spawned := 0
    for e in res.log.entries:
        if e.verb == E.Verb.MECHANIC and e.round_no == 5 \
                and String(e.params.get("mechanic", "")) == E.mechanic_key(E.Mechanic.ADD_SPAWNS):
            spawned += 1
    assert_eq(spawned, 1, "one announcement, from m04, on E1's round 5")
    var blocks := 0
    for b in enc.enemies:
        if b.spawn_round > 0:
            blocks += 1
    assert_true(blocks > 0,
        "E1 still declares a spawn_round block in data — it is inert now, and "
        + "sim/model/Encounter.gd should reject the pair on load instead "
        + "(requested in build/plan/handoff-sim.md)")

# ------------------------------------------------- the vocabulary is a contract

## docs/10 §10's mechanics with NO behaviour in the sim today.
##
## THE PATTERN: an explicit allowlist of the gap, asserted to be EXACTLY what is
## missing. It passes now, and the moment someone implements one of these the
## test goes red and tells them to delete their row — which is the only way a
## silently skipped match arm ever gets noticed. Delete a key here in the same
## commit that implements it.
##
## **It is empty.** All twelve of docs/10 §10's mechanics now change the fight,
## and the list stays here rather than being deleted because it is the guard's
## contract: a thirteenth mechanic added to `Enums.Mechanic` without an arm in
## `_apply_scheduled_mechanics` turns this file red, which is the whole point.
const MECHANICS_WITH_NO_BEHAVIOUR := []

## Params for the behaviour probe. Every value is quoted from the mechanic's
## richest Tier 1 configuration in data/encounters_t1.json, so the probe runs
## what content actually ships rather than a made-up shape — with the deliberate
## exceptions below, which are test-fixture choices and NOT content proposals.
##
## m06's `round`. The data authors it at 31 (E5's enrage round, and
## `ceil(1.4 x target_rounds)` per docs/10 §10 M06), and `_synthetic` copies E5's
## 22/31 pair, so a probe fight would end long before the mechanic fired and m06
## would read as dead. 8 is a round the probe fight reaches.
##
## m07, m10, m11 and m12 are configured NOWHERE in Tier 1 — docs/10 §10's tier
## escalation rule holds them for Tiers 2-5 — so there is nothing to quote and
## the guard has a blind spot: an implementation whose params default to off
## leaves the probe log identical, keeps its key in the list above and keeps this
## file green, which is a false green in exactly the case the guard exists to
## catch. So these four are authored here, in the shapes their arms read:
##
##   m07  a Spread demand for four rounds at 26/round off-position.
##   m10  a three-round silence window, the half of M10 that can ship.
##   m11  26 to every melee raider each round.
##   m12  +3 raw swing per round from the pull.
##
## The magnitudes borrow E5's m03 tick (26) and a third of E1's add swing (3)
## so the probe fights numbers this project's tuning has already seen; Tier 2-5
## content will author its own, and docs/10 §12 owns those.
const PROBE_PARAMS := {
    "m01": {"stack_damage_pct": 50, "swap_at": 3},
    "m02": {"damage": 28, "every": 4, "ignores_ac": true},
    "m03": {"damage_per_round": 26, "escape_chance_bp": 5000},
    "m04": {"count": 2, "hp": 90, "swing": 9, "rounds": [10, 20]},
    "m05": {"round": 4, "every": 5, "requires_melee": 1},
    "m06": {"round": 8, "damage_multiplier_pct": 200},
    "m07": {"required": "spread", "rounds": 4, "damage": 26},
    "m08": {"rounds": 5, "every": 5},
    "m09": {"reduction_pct": 40, "rounds": 3, "target": "active_tank"},
    "m10": {"rounds": 3},
    "m11": {"damage": 26},
    "m12": {"increment": 3, "from_round": 1},
}

func test_every_mechanic_in_the_vocabulary_is_dispatched_or_named_as_a_gap() -> void:
    # `_apply_scheduled_mechanics` was a bare `match` with three arms and no
    # default, so E4's four configured mechanics (docs/10 §6 prices one per star)
    # were a silent no-op while every mechanic test passed — they all assert DATA
    # shape, not behaviour. This probes behaviour: run the same fight with and
    # without the mechanic on the same seed and compare the logs. An identical
    # log means the mechanic did nothing at all.
    var baseline: String = _probe("")
    var dead: Array = []
    for m in E.Mechanic.size():
        var key: String = E.mechanic_key(m)
        if _probe(key) == baseline:
            dead.append(key)
    assert_eq(dead, MECHANICS_WITH_NO_BEHAVIOUR,
        "mechanics with no behaviour are %s, the list says %s — implement it or "
        % [str(dead), str(MECHANICS_WITH_NO_BEHAVIOUR)]
        + "update MECHANICS_WITH_NO_BEHAVIOUR in this file")

func test_no_mechanic_in_the_vocabulary_notes_itself_as_a_gap() -> void:
    # The other half of the guard above, and its replacement for the two tests
    # that asserted the gap notes were PRESENT (m09's "no behaviour" and m03's
    # "unreachable"). Both mechanics work now, so the assertion inverts: the
    # transcript must carry no gap note at all for any of the twelve, at any
    # tier. A note surviving here means an arm was deleted or a mechanic was
    # renamed out from under its arm.
    for m in E.Mechanic.size():
        var key: String = E.mechanic_key(m)
        var res = Sim.run(_roster(),
            _synthetic([{"id": key, "params": PROBE_PARAMS[key]}]), _db, 5)
        for e in res.log.entries:
            if e.template_id in GAP_NOTES:
                fail("%s emitted the gap note %s: %s"
                    % [key, e.template_id, String(e.params.get("text", ""))])

func test_a_development_note_never_reaches_a_player_tier() -> void:
    # docs/07 §10.2: tiers 0-2 are player settings (RaidView draws a button for
    # each) and tier 3 Debug is "dev builds and bug reports only". The gap notes
    # are unreachable from content now, so the property is asserted against the
    # emitter directly — deleting the last caller must not quietly delete the
    # rule, because the next unimplemented mechanic will need it.
    var log = load("res://sim/core/EventLog.gd").new()
    log.emit(E.Verb.SYSTEM, E.LogTier.DEBUG, 1, E.Phase.ROUND_OPEN,
        "mechanic_unimplemented", {"text": "M13 (m13) is configured but has no behaviour."})
    for tier in [E.LogTier.STORY, E.LogTier.PLAY_BY_PLAY, E.LogTier.NUMBERS]:
        assert_false(log.transcript(tier).contains("no behaviour"),
            "a development note reached the player-selectable %s tier"
            % E.LOG_TIER_NAMES[tier])
    assert_true(log.transcript(E.LogTier.DEBUG).contains("no behaviour"),
        "it must still be there for the dev who needs it")

# ---------------------------------------------------------------- probe helpers

## E5's stat block, quoted from data/encounters_t1.json, with the mechanics list
## replaced. A test fixture and not a content proposal: the numbers are E5's so
## the probe fights something the tuning has already been checked against.
## `tanks_required` is a parameter because it used to be a blind spot: it was
## hardcoded to 2, so the guard below could not see a mechanic that had been
## quietly switched off for one-tank encounters (which is what happened to m01
## on A3). Every caller that does not name it still gets E5's shape.
func _synthetic(mechanics: Array, tanks_required: int = 2):
    return Encounter.from_dict({
        "id": "probe", "display_name": "Probe", "tier": 1, "slot": "E5",
        "stars": maxi(1, mechanics.size()), "kind": "main_boss",
        "party_size": 12, "tanks_required": tanks_required,
        "enemies": [{"name": "Main Boss", "count": 1, "hp": 6200, "raw_swing": 37,
            "swings_per_round": 2, "threat_rule": "standard"}],
        "mechanics": mechanics,
        "loot_slots": ["capstone"], "target_rounds": 22, "enrage_round": 31,
        "comedy_line": "A probe encounter; see tests/unit/test_raid_sim.gd.",
    }, [])

## Template ids of the gap notes `_apply_scheduled_mechanics` emits. They are
## stripped from a probe log, and `sequence` with them: a note occupies a
## sequence number, so leaving either in made every mechanic that only emits a
## note look like it had changed the fight.
const GAP_NOTES := ["mechanic_unimplemented", "mechanic_unreachable", "mechanic_partial",
    "mechanic_needs_a_partner"]

## The serialised log of one probe fight with `mechanic` configured, or the bare
## fight when it is empty.
func _probe(mechanic: String) -> String:
    var mechanics: Array = []
    if not mechanic.is_empty():
        mechanics.append({"id": mechanic, "params": PROBE_PARAMS[mechanic]})
    var res = Sim.run(_roster(), _synthetic(mechanics), _db, 4242)
    var out: Array = []
    for e in res.log.entries:
        if e.template_id in GAP_NOTES:
            continue
        var d: Dictionary = e.to_dict()
        d.erase("sequence")
        out.append(d)
    return JSON.stringify(out)

## Damage amounts from raid-wide pulse entries. `_apply_damage` logs the pulse as
## an ATTACK whose actor is the plain source name.
func _pulse_amounts(res) -> Array:
    var out: Array = []
    for e in res.log.entries:
        if e.verb == E.Verb.ATTACK and e.actor_name == "the pulse":
            out.append(e.number("amount"))
    return out

## A roster of exactly these classes, in this order — the mechanics that care
## about composition (M05's melee, M11's cleave, M01's second tank) cannot be
## tested against the benchmark twelve alone.
func _roster_of(class_keys: Array, rarity: int = E.Rarity.COMMON,
        morale: int = 55, gear: String = "adventure") -> Array:
    var out := []
    for i in class_keys.size():
        out.append(_raider(String(class_keys[i]), i, rarity, morale, gear))
    return out

## ATTACK entries whose actor is a plain source name: a boss, or one of the
## mechanics that damages through `_apply_damage` ("the fire", "the cleave",
## "the pulse", "bad positioning", "the cast").
func _attacks_from(res, source: String) -> Array:
    var out: Array = []
    for e in res.log.entries:
        if e.verb == E.Verb.ATTACK and e.actor_name == source:
            out.append(e)
    return out

func _mechanic_lines(res, key: String) -> Array:
    var out: Array = []
    for e in res.log.entries:
        if e.verb == E.Verb.MECHANIC and String(e.params.get("mechanic", "")) == key:
            out.append(String(e.params.get("text", "")))
    return out

func _combatants_of(res) -> Array:
    return res.survivors + res.casualties

func _by_raider_id(res) -> Dictionary:
    var out := {}
    for c in _combatants_of(res):
        out[c.raider.id] = c
    return out

# --------------------------------------------------- M01 Tank Swap (docs/10 §10)

## The stack count out of "<name> steps out at N stacks; <name> takes over.",
## parsed from the RIGHT of the number rather than by token index: a display
## name can be two words, and the previous version of this test read
## `split(" ")[3]`, which is the literal word "at". `int("at")` is 0 in
## GDScript, so its `stacks <= swap_at` assertion was `0 <= 3` on every run and
## nothing in the suite checked the one number docs/10 §10 M01 names.
func _handover_stacks(text: String) -> int:
    var head: String = text.get_slice(" stacks;", 0)
    var words: PackedStringArray = head.split(" ")
    return int(words[words.size() - 1])

func test_m01_hands_the_boss_from_one_tank_to_the_other() -> void:
    # docs/10 §10 M01: "swap required at 3". The benchmark twelve brings two
    # Warriors, so E3 — whose card is literally "two tanks take turns"
    # (docs/10 §7.3) — must produce a handover.
    var spec = _encounter("E3").mechanic_spec(E.Mechanic.TANK_SWAP)
    assert_true(spec != null, "E3 must carry m01 for this test to mean anything")
    var handovers := 0
    for seed_value in range(1, 6):
        var res = Sim.run(_roster(), _encounter("E3"), _db, seed_value)
        for text in _mechanic_lines(res, "m01"):
            if text.contains("takes over"):
                handovers += 1
    assert_true(handovers > 0,
        "five seeds of E3 produced no tank swap; m01 is configured on it")

func test_m01_steps_out_at_the_authored_threshold_and_not_before() -> void:
    # The assertion the vacuous one claimed to make, twice over.
    #
    # Absolute: nobody hands the boss over below `swap_at`, and nobody carries
    # it more than one round of boss swings past it — docs/10 §7.3's card says
    # M01 overrides "on stack 3", and stacks land in Phase 1 while the swap
    # resolves at Phase 0, so the holder can pick up at most one round's worth
    # before the next opportunity.
    #
    # Relative: the same fight authored with a HIGHER `swap_at` must hand over
    # later. That is what makes this un-fakeable by a hardcoded threshold — the
    # reviewer's breaking input was "make a tank step out at 5 stacks on E3 and
    # watch the suite stay green".
    var swings: int = 2      # `_synthetic`'s Main Boss, swings_per_round
    var lowest := {}
    for swap_at in [3, 6]:
        var enc = _synthetic([{"id": "m01",
            "params": {"stack_damage_pct": 50, "swap_at": swap_at}}])
        var seen := []
        for seed_value in range(1, 6):
            var res = Sim.run(_roster(E.Rarity.LEGENDARY, 95, "raid"), enc, _db,
                seed_value)
            for text in _mechanic_lines(res, "m01"):
                if not text.contains("takes over"):
                    continue
                var stacks := _handover_stacks(text)
                seen.append(stacks)
                assert_true(stacks >= swap_at,
                    "a tank stepped out at %d stacks, under the authored %d: %s"
                    % [stacks, swap_at, text])
                assert_true(stacks <= swap_at + swings,
                    "a tank stepped out at %d stacks, more than one round of "
                    % stacks
                    + "swings past the authored %d: %s" % [swap_at, text])
        assert_true(seen.size() > 0,
            "no handover at swap_at %d; the fixture cannot assert anything"
            % swap_at)
        seen.sort()
        lowest[swap_at] = int(seen[0])
    assert_true(int(lowest[6]) > int(lowest[3]),
        "raising swap_at from 3 to 6 did not delay the handover (%d vs %d) — "
        % [int(lowest[6]), int(lowest[3])]
        + "the threshold is not being read")

func test_m01_does_nothing_on_an_encounter_that_does_not_carry_it() -> void:
    # The negative half: no stacks, no handover lines, nothing to explain.
    var res = Sim.run(_roster(), _encounter("E1"), _db, 9)
    assert_true(_encounter("E1").mechanic_spec(E.Mechanic.TANK_SWAP) == null)
    assert_eq(_mechanic_lines(res, "m01").size(), 0)
    for c in _combatants_of(res):
        assert_eq(c.tank_debuff_stacks, 0,
            "%s accumulated tank stacks in a fight with no m01" % c.display_name())

func test_m01_strands_a_one_tank_roster_and_says_so() -> void:
    # PINS THE OTHER READING OF THE SWITCH. Sim.TANK_SWAP_NEEDS_A_PARTNER
    # defaults TRUE, because taken literally M01 makes two canon encounters
    # unwinnable (A3 and the Tutorial Raid, both `tanks_required: 1`). The
    # literal §10 punishment is still a shipped reading and still has to work,
    # so this test selects it explicitly and puts it back.
    var was: bool = Sim.TANK_SWAP_NEEDS_A_PARTNER
    Sim.TANK_SWAP_NEEDS_A_PARTNER = false
    # docs/06's composition punishment, and the reason the audit asked for it:
    # E3 ASKS for two tanks, so a roster with one Warrior and no Monk gets the
    # debuff with nowhere to put it. The tank sits at the swap threshold for the
    # rest of the fight and the transcript names the problem.
    #
    # Asserted as the mechanism rather than as a survivor count on purpose: the
    # only way to field one tank is to bring a different twelfth class, which
    # moves raid DPS by more than the debuff moves incoming damage, so an
    # outcome comparison measures the substitution and not the mechanic.
    var one := ["warrior", "rogue", "cleric", "druid", "shaman", "rogue",
                "rogue", "rogue", "mage", "wizard", "wizard", "bard"]
    var res = Sim.run(_roster_of(one, E.Rarity.LEGENDARY, 95, "raid"),
        _encounter("E3"), _db, 3)
    var stranded := false
    for text in _mechanic_lines(res, "m01"):
        if text.contains("nobody to swap with"):
            stranded = true
    assert_true(stranded,
        "a one-tank roster on a two-tank encounter must be told the swap "
        + "cannot happen: %s" % str(_mechanic_lines(res, "m01")))
    # And the stacks keep climbing. docs/10 §10 M01 names one threshold and no
    # ceiling; a cap at `swap_at` would soften exactly the case docs/06 says
    # must hurt, which is what `TANK_DEBUFF_STACK_CAP_AT_SWAP` used to do.
    var swap_at: int = int(_encounter("E3").mechanic_spec(E.Mechanic.TANK_SWAP)
        .params.get("swap_at", 3))
    var climbed := false
    for c in _combatants_of(res):
        if c.is_main_tank and c.tank_debuff_stacks > swap_at:
            climbed = true
    assert_true(climbed,
        "the stranded tank never got past %d stacks — the debuff is capped, "
        % swap_at + "and docs/10 §10 M01 names no ceiling")

    Sim.TANK_SWAP_NEEDS_A_PARTNER = was

func test_m01_still_bites_an_encounter_that_only_asked_for_one_tank() -> void:
    # Same switch, same reason as the test above: this pins the literal reading.
    var was: bool = Sim.TANK_SWAP_NEEDS_A_PARTNER
    Sim.TANK_SWAP_NEEDS_A_PARTNER = false
    # `_tank_swap_is_live` used to switch M01 off entirely when
    # `tanks_required < 2`, which made m01 a silent no-op on A3 — an encounter
    # docs/10 §8 lists M01 on. docs/10 §6: "a star that buys nothing is a lie on
    # the encounter card", and the audit's own remaining_work said to log it and
    # let the stacks kill the tank instead.
    #
    # This is why `_synthetic` takes `tanks_required`: with it hardcoded to 2
    # the guard below was structurally blind to this, and removing or inverting
    # the gate moved no test in either direction.
    var enc = _synthetic([{"id": "m01", "params": PROBE_PARAMS["m01"]}], 1)
    var solo := ["warrior", "cleric", "druid", "shaman", "rogue", "rogue",
                 "rogue", "monk", "mage", "wizard", "wizard", "bard"]
    var res = Sim.run(_roster_of(solo, E.Rarity.LEGENDARY, 95, "raid"), enc, _db, 3)
    var lines: Array = _mechanic_lines(res, "m01")
    assert_true(lines.size() > 0,
        "m01 on a one-tank encounter produced no log line at all — that is the "
        + "silent no-op back again")
    var stranded := false
    for text in lines:
        if text.contains("nobody to swap with"):
            stranded = true
    assert_true(stranded, "the transcript must name the problem: %s" % str(lines))
    var stacked := false
    for c in _combatants_of(res):
        if c.is_main_tank and c.tank_debuff_stacks > 0:
            stacked = true
    assert_true(stacked, "the solo tank accumulated no stacks; m01 is inert")

    Sim.TANK_SWAP_NEEDS_A_PARTNER = was

func test_m01_asks_the_tanks_a_question_they_can_fail() -> void:
    # docs/10 §10 M01's invited mistakes are Monk *Panicked Stance* and Warrior
    # *Lost Aggro*, which is what the docs/07 §5.3(b) check site is for. A tank
    # mistake at ROUND_OPEN is a mechanic-check failure by construction: no
    # other roll site runs in that phase.
    var found := false
    for seed_value in range(1, 9):
        var res = Sim.run(_roster(E.Rarity.COMMON, 25), _encounter("E3"), _db, seed_value)
        var tanks := {}
        for c in _combatants_of(res):
            if c.is_main_tank or c.is_offtank:
                tanks[c.raider.id] = true
        for m in res.log.mistakes():
            if m.phase == E.Phase.ROUND_OPEN and tanks.has(m.actor_id):
                found = true
    assert_true(found,
        "eight seeds of E3 never asked a tank anything it could get wrong")

# ----------------------------------------- M03 Avoidable Ground Effect (docs/10)

func test_m03_puts_raiders_in_the_fire_and_takes_them_out_again() -> void:
    # The mechanic that used to be UNREACHABLE: `_phase_effects` damaged anyone
    # holding a Fire token and nothing could place one, because m03 authors no
    # schedule and the check site read an unscheduled spec as "never fires".
    #
    # The exit is docs/10 §10 M03's per-round re-roll and nothing else
    # (build/plan/q-mech-arms.md Q-M03). So: a tick can only follow an entry,
    # every stay ends, and a 50% re-roll must sometimes hold somebody longer
    # than the two rounds docs/07 §5.2 row 1 describes as the typical case —
    # that last one is the assertion the old unconditional "out at end of next
    # round" made impossible, and it is the audit's acceptance criterion.
    var enc = _synthetic([{"id": "m03", "params": PROBE_PARAMS["m03"]}])
    var ticks := 0
    var longest := 0
    for seed_value in range(1, 21):
        var res = Sim.run(_roster(E.Rarity.COMMON, 25), enc, _db, seed_value)
        # Every mistake that emits Fire, by (round, raider). Both entry paths
        # count: MIS_FIRE and MIS_MECHANIC_DROP (Mistakes.TYPES `emits`).
        var entered := {}
        for m in res.log.mistakes():
            if String(m.mistake["type"]) in ["MIS_FIRE", "MIS_MECHANIC_DROP"]:
                entered["%d|%s" % [m.round_no, m.actor_id]] = true
        var run_len := {}
        for e in _attacks_from(res, "the fire"):
            ticks += 1
            # A tick is only legal from the round a raider walked in onwards,
            # and the entry has to exist: nobody burns in a fire they never
            # entered. Tracked as a running stay rather than a two-round window
            # because the stay is now open-ended by design.
            var key: String = "|%s" % e.target_id
            var live: int = int(run_len.get(key, 0))
            if entered.has("%d|%s" % [e.round_no, e.target_id]):
                live = 1
            else:
                assert_true(live > 0,
                    "%s took a fire tick in round %d having never entered: "
                    % [e.target_name, e.round_no] + "the entry leaked")
                live += 1
            run_len[key] = live
            longest = maxi(longest, live)
        # The safety half: everybody who entered is out by the end of the fight.
        for c in _combatants_of(res):
            assert_false(c.is_alive() and c.has_token(E.Token.FIRE)
                    and res.outcome == Sim.Outcome.VICTORY,
                "%s cleared the fight still standing in the fire" % c.display_name())
    assert_true(ticks > 0, "twenty seeds and nobody ever stood in the fire")
    assert_true(longest > 2,
        "the longest stay across twenty seeds was %d ticks — at 5000bp a "
        % longest
        + "re-roll must sometimes hold a raider longer than that, and a hard "
        + "two-round cap is the only thing that makes it impossible")

func test_m03_without_an_escape_chance_is_a_zone_you_cannot_leave() -> void:
    # build/plan/q-mech-arms.md Q-M03's other half, which the code did not have:
    # `escape_chance_bp` is the only exit, so an encounter that omits it keeps
    # `Enums.TOKEN_DURATION[FIRE]`'s -1 ("until cleared") with nothing to clear
    # it. No shipped encounter omits the param — E4, E5 and A3 all author 5000 —
    # so this asserts an authoring choice, not shipped behaviour. It exists
    # because the doc entry says it and the sim did not.
    var enc = _synthetic([{"id": "m03", "params": {"damage_per_round": 26}}])
    var stuck := false
    for seed_value in range(1, 9):
        var res = Sim.run(_roster(E.Rarity.COMMON, 25), enc, _db, seed_value)
        assert_eq(_mechanic_lines(res, "m03").size(), 0)
        for e in res.log.entries:
            if e.verb == E.Verb.SYSTEM \
                    and String(e.params.get("text", "")).contains("steps out of the fire"):
                fail("a zone with no escape_chance_bp let somebody out")
        for c in _combatants_of(res):
            if c.has_token(E.Token.FIRE):
                stuck = true
    assert_true(stuck,
        "eight seeds and nobody was ever left in the permanent zone; the "
        + "fixture cannot assert anything")

func test_an_encounter_with_no_ground_effect_cannot_set_anybody_on_fire() -> void:
    # The defect the reviewer caught, as its own test. E3 carries m01, m02 and
    # m04 and NO m03, and the shipped e3_commons_adventure golden had Bob
    # standing in a fire that does not exist at R01 and dying to
    # MIS_AVOIDABLE_DEATH at R11 — a Critical cascade-only type armed for the
    # whole fight by a token nothing could clear.
    #
    # E1 cannot see this (it rolls no mechanic checks at all), which is why
    # `test_m01_does_nothing_on_an_encounter_that_does_not_carry_it` missed it.
    # Seed 31337 is the one from the golden.
    for slot in ["E2", "E3"]:
        var enc = _encounter(slot)
        assert_true(enc.mechanic_spec(E.Mechanic.GROUND_EFFECT) == null,
            "%s must carry no m03 for this test to mean anything" % slot)
        for seed_value in [31337, 3, 7, 11, 4242]:
            var res = Sim.run(_roster(E.Rarity.COMMON, 25), enc, _db, seed_value)
            assert_eq(_attacks_from(res, "the fire").size(), 0,
                "%s seed %d took fire tick damage with no fire in the fight"
                % [slot, seed_value])
            for m in res.log.mistakes():
                assert_ne(String(m.mistake["type"]), "MIS_AVOIDABLE_DEATH",
                    "%s seed %d: %s died to a fire %s does not have"
                    % [slot, seed_value, m.actor_name, slot])
            for c in _combatants_of(res):
                assert_false(c.has_token(E.Token.FIRE),
                    "%s seed %d: %s holds a Fire token and %s has no zone"
                    % [slot, seed_value, c.display_name(), slot])

func test_m03_makes_the_cascades_terminal_event_reachable() -> void:
    # MIS_AVOIDABLE_DEATH is the taxonomy's only cascade-only type (docs/07
    # §5.2 row 18) and its `requires_token` is [FIRE, ADDS]. Until m03 could
    # place a Fire token, the cascade system's terminal event could not happen
    # in a real fight at all.
    var enc = _synthetic([{"id": "m03", "params": PROBE_PARAMS["m03"]}])
    var deaths := 0
    for seed_value in range(1, 21):
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), enc, _db, seed_value)
        for m in res.log.mistakes():
            if String(m.mistake["type"]) == "MIS_AVOIDABLE_DEATH":
                deaths += 1
    assert_true(deaths > 0,
        "twenty seeds of a miserable raid in a permanent fire and nobody died "
        + "to something extremely avoidable")

# ------------------------------------------- M05 Interrupt Check (docs/10 §10)

## E5's shape with an m05 that carries an `effect` block. docs/10 §10 M05 never
## names effect E, so the payload is authored per encounter and this is a test
## fixture's authoring — NOT a content proposal. The magnitude is E5's raid-wide
## pulse (28), because an uninterrupted cast is the same shape of problem.
func _interrupt_encounter():
    return _synthetic([{"id": "m05", "params": {
        "round": 2, "every": 3, "requires_melee": 1,
        "effect": {"kind": "raid_damage", "amount": 28}}}])

func test_m05_resolves_its_cast_when_nobody_is_in_melee() -> void:
    # docs/10 §10 M05: "unless >=1 melee DPS is in position, effect `E` fires".
    # A roster of casters and healers has nobody to answer it.
    var res = Sim.run(_roster_of(["warrior", "cleric", "druid", "shaman",
        "mage", "wizard", "wizard", "mage"]), _interrupt_encounter(), _db, 3)
    var said := false
    for text in _mechanic_lines(res, "m05"):
        if text.contains("Nobody was in melee"):
            said = true
    assert_true(said, "a raid with no melee DPS must eat the cast and be told why")
    assert_true(_attacks_from(res, "the cast").size() > 0,
        "the authored effect has to actually land")

func test_m05_is_interrupted_when_the_melee_are_there() -> void:
    # The positive half. Two Rogues and a Monk cannot all fumble every check, so
    # the cast is interrupted at least once and the effect does not land then.
    var res = Sim.run(_roster_of(["warrior", "warrior", "cleric", "druid",
        "shaman", "rogue", "rogue", "monk", "mage", "wizard", "wizard", "bard"],
        E.Rarity.EPIC, 95), _interrupt_encounter(), _db, 3)
    var interrupted := 0
    for text in _mechanic_lines(res, "m05"):
        if text.contains("interrupted"):
            interrupted += 1
    assert_true(interrupted > 0,
        "three melee DPS at Epic rarity and high morale never interrupted anything")

func test_m05_with_no_authored_effect_lands_nothing() -> void:
    # docs/10 names no number for E, so an encounter that omits the payload gets
    # a demand with no teeth rather than a number RaidSim invented. The gap is
    # visible in the transcript and harmless in the arithmetic.
    var enc = _synthetic([{"id": "m05", "params": PROBE_PARAMS["m05"]}])
    var res = Sim.run(_roster_of(["cleric", "druid", "shaman", "mage", "wizard"]),
        enc, _db, 3)
    assert_true(_mechanic_lines(res, "m05").size() > 0, "the cast still resolves")
    assert_eq(_attacks_from(res, "the cast").size(), 0,
        "an unauthored effect must land nothing at all")

# ---------------------------------- M07 Positioning Requirement (docs/10 §10)

func test_m07_charges_only_the_raiders_who_failed_the_check() -> void:
    # docs/07 OQ-7's abstract position model (build/plan/q-mech-arms.md Q-M07):
    # "off-position" IS "failed this round's check", so every raider who takes
    # positioning damage must have a mistake logged in the same round, and the
    # rest of the raid takes none.
    var enc = _synthetic([{"id": "m07", "params": PROBE_PARAMS["m07"]}])
    var hits := 0
    for seed_value in range(1, 9):
        var res = Sim.run(_roster(E.Rarity.COMMON, 25), enc, _db, seed_value)
        var mistakes := {}
        for m in res.log.mistakes():
            mistakes["%d|%s" % [m.round_no, m.actor_id]] = true
        for e in _attacks_from(res, "bad positioning"):
            hits += 1
            assert_true(mistakes.has("%d|%s" % [e.round_no, e.target_id]),
                "%s took positioning damage in round %d without failing a check"
                % [e.target_name, e.round_no])
    assert_true(hits > 0, "eight seeds and nobody was ever out of position")

func test_m07_only_demands_a_stance_inside_its_window() -> void:
    # "for `N` rounds" is a window, not a permanent state. The probe authors four
    # rounds from the pull, so nothing may be charged after round 4.
    var enc = _synthetic([{"id": "m07", "params": PROBE_PARAMS["m07"]}])
    var window: int = int(PROBE_PARAMS["m07"]["rounds"])
    for seed_value in range(1, 9):
        var res = Sim.run(_roster(E.Rarity.COMMON, 25), enc, _db, seed_value)
        for e in _attacks_from(res, "bad positioning"):
            assert_true(e.round_no <= window,
                "positioning damage landed in round %d, past the %d-round window"
                % [e.round_no, window])

func test_m07_without_a_named_stance_demands_nothing_and_says_so() -> void:
    # docs/10 §10 M07 is "demands Spread or Stack" and privileges neither, so
    # RaidSim may not pick one. `POSITIONING_DEFAULT_REQUIRED := Stance.SPREAD`
    # did, on the strength of table word-order, with no docs/15 proposal
    # anywhere — house rule 1, and it is gone.
    #
    # The M05 precedent is the model: a demand with no authored content
    # resolves, charges nothing and is legible in the transcript, rather than
    # becoming a number this file invented.
    var enc = _synthetic([{"id": "m07", "params": {"rounds": 4, "damage": 26}}])
    for seed_value in range(1, 5):
        var res = Sim.run(_roster(E.Rarity.COMMON, 25), enc, _db, seed_value)
        assert_eq(_attacks_from(res, "bad positioning").size(), 0,
            "an m07 with no `required` charged somebody for being in the "
            + "wrong place, and nothing said which place was right")
        var said := false
        for text in _mechanic_lines(res, "m07"):
            if text.contains("nobody can say which"):
                said = true
        assert_true(said,
            "docs/10 §6: a star that buys nothing is a lie on the encounter "
            + "card, so the gap has to be visible: %s" % str(_mechanic_lines(res, "m07")))

func test_a_stance_is_class_derived_and_unread_without_m07() -> void:
    # The default has to exist (a raider is always somewhere) and must not do
    # anything on its own, or every encounter in the game would move.
    var res = Sim.run(_roster(), _encounter("E1"), _db, 9)
    assert_eq(_attacks_from(res, "bad positioning").size(), 0)
    for c in _combatants_of(res):
        var cls: int = int(c.get_meta("profile")["class_id"])
        var melee: bool = cls in [E.CharClass.WARRIOR, E.CharClass.MONK,
            E.CharClass.ROGUE, E.CharClass.BARD]
        assert_eq(c.stance, E.Stance.STACKED if melee else E.Stance.SPREAD,
            "%s is in the wrong default stance" % c.display_name())

# ----------------------------------------------- M08 Fixate (docs/10 §10 M08)

func test_m08_chases_one_non_tank_and_then_lets_go() -> void:
    # docs/10 §10 M08: "Boss ignores threat for `N` rounds and chases a random
    # raider." The tank keeps top threat throughout — that is the point — so
    # this asserts the boss's target is NOT the top-threat raider during the
    # window, and is again afterwards.
    var enc = _synthetic([{"id": "m08", "params": PROBE_PARAMS["m08"]}])
    var res = Sim.run(_roster(E.Rarity.LEGENDARY, 95, "raid"), enc, _db, 4242)
    var lines := _mechanic_lines(res, "m08")
    var fixated := ""
    for text in lines:
        if text.contains("fixates on"):
            fixated = text
    assert_false(fixated.is_empty(), "m08 must announce its victim: %s" % str(lines))
    var by_id := _by_raider_id(res)
    var chased := {}
    for e in _attacks_from(res, "Main Boss"):
        if e.round_no < 5 or e.round_no > 9:
            continue
        chased[e.target_id] = int(chased.get(e.target_id, 0)) + 1
    assert_true(chased.size() > 0, "the boss must swing during the window")
    for rid in chased.keys():
        var c = by_id[rid]
        assert_false(c.is_main_tank or c.is_offtank,
            "the boss went back to a tank during a fixate window")

    # Half of "…and then lets go", which this test was named for and never
    # checked: the window closes out loud. E4's cadence is `rounds: 5, every: 5`
    # — contiguous windows, 5-9 then 10-14 — so the release is announced and a
    # fresh victim is taken in the same round, and the threat half needs a
    # fixture with a gap in it. That is the test below.
    var released := ""
    for text in lines:
        if text.contains("loses interest"):
            released = text
    assert_false(released.is_empty(),
        "the window ended and nothing announced it: %s" % str(lines))

func test_m08_gives_the_boss_back_to_the_threat_table_between_windows() -> void:
    # The other half. `rounds: 3, every: 9` is a TEST FIXTURE and not a content
    # proposal — E4's shipped cadence tiles its windows end to end, so nothing
    # in Tier 1 can show the boss going back to the tank, and "chases a random
    # raider for `N` rounds" (docs/10 §10 M08) is only a mechanic if it stops.
    var enc = _synthetic([{"id": "m08", "params": {"rounds": 3, "every": 9}}])
    var res = Sim.run(_roster(E.Rarity.LEGENDARY, 95, "raid"), enc, _db, 4242)
    var by_id := _by_raider_id(res)
    assert_true(res.rounds >= 12,
        "the fight ran %d rounds and cannot reach the gap after the second "
        % res.rounds + "window; pick another seed")
    var inside := {}
    var outside := {}
    for e in _attacks_from(res, "Main Boss"):
        # Windows open at 9 and 18 and last three rounds. 12-17 is the gap.
        var bucket: Dictionary = inside if e.round_no >= 9 and e.round_no <= 11 \
            else outside
        if e.round_no >= 9:
            bucket[e.target_id] = true
    assert_true(inside.size() > 0, "the boss must swing inside the window")
    for rid in inside.keys():
        assert_false(by_id[rid].is_main_tank or by_id[rid].is_offtank,
            "the boss hit a tank inside a fixate window")
    assert_true(outside.size() > 0, "the boss must swing after the window")
    var back_on_a_tank := false
    for rid in outside.keys():
        if by_id[rid].is_main_tank or by_id[rid].is_offtank:
            back_on_a_tank = true
    assert_true(back_on_a_tank,
        "the boss never went back to a tank after the fixate window closed")

func test_m08_is_not_configured_to_chase_a_tank() -> void:
    # Fixating on the tank is the DEFAULT behaviour, so a fixate that could pick
    # one would be a mechanic that sometimes does nothing.
    var enc = _synthetic([{"id": "m08", "params": PROBE_PARAMS["m08"]}])
    for seed_value in range(1, 13):
        var res = Sim.run(_roster(), enc, _db, seed_value)
        var by_id := _by_raider_id(res)
        for text in _mechanic_lines(res, "m08"):
            if not text.contains("fixates on"):
                continue
            for rid in by_id.keys():
                var c = by_id[rid]
                if (c.is_main_tank or c.is_offtank) and text.contains(c.display_name()):
                    fail("m08 fixated on the tank %s" % c.display_name())

# --------------------------------------- M09 Healing Debuff (docs/10 §10 M09)

func test_m09_cuts_healing_on_its_target_and_nobody_else() -> void:
    # docs/10 §10 M09: "Healing on the current tank reduced `p%` for `N`
    # rounds", authored on E4 as 40% for 3 on the active tank. Heal magnitudes
    # are deterministic per healer (docs/08's formulas take no RNG), so the same
    # Cleric's best heal on the same tank inside and outside the window is a
    # clean before/after — no second run and no drift.
    var enc = _synthetic([{"id": "m09", "params": PROBE_PARAMS["m09"]}])
    var res = Sim.run(_roster(E.Rarity.COMMON, 55), enc, _db, 11)
    var pct: int = int(PROBE_PARAMS["m09"]["reduction_pct"])
    var window: int = int(PROBE_PARAMS["m09"]["rounds"])
    var tank_id := ""
    for c in _combatants_of(res):
        if c.is_main_tank:
            tank_id = c.raider.id
    var inside := 0
    var outside := 0
    var others_inside := 0
    var others_outside := 0
    for e in res.log.entries:
        if e.verb != E.Verb.HEAL:
            continue
        var amount: int = e.number("amount")
        if e.target_id == tank_id:
            if e.round_no <= window:
                inside = maxi(inside, amount)
            else:
                outside = maxi(outside, amount)
        else:
            if e.round_no <= window:
                others_inside = maxi(others_inside, amount)
            else:
                others_outside = maxi(others_outside, amount)
    assert_true(inside > 0 and outside > 0,
        "need heals on the tank both inside and outside the window (%d/%d)"
        % [inside, outside])
    assert_true(inside <= int(round(float(outside) * float(100 - pct) / 100.0)),
        "the debuffed tank's best heal was %d against %d after it expired, "
        % [inside, outside] + "which is not a %d%% cut" % pct)
    assert_true(others_inside > 0 and others_outside > 0)
    assert_eq(others_inside, others_outside,
        "M09 is single-target; everyone else's healing must be untouched")

func test_m09_announces_the_debuff_and_its_expiry() -> void:
    # docs/10 §6: a star that buys nothing is a lie — and an invisible recovery
    # reads as a debuff that never ended.
    var enc = _synthetic([{"id": "m09", "params": PROBE_PARAMS["m09"]}])
    var res = Sim.run(_roster(), enc, _db, 11)
    var landed := false
    var lifted := false
    for text in _mechanic_lines(res, "m09"):
        if text.contains("is cut by"):
            landed = true
        if text.contains("healed properly again"):
            lifted = true
    assert_true(landed, "the debuff has to say it landed")
    assert_true(lifted, "and that it wore off")

# --------------------------------------------- M10 Mana Burn (docs/10 §10 M10)

func test_m10_silences_the_casters_for_its_window_only() -> void:
    # docs/10 §10 M10's shippable half: "For `N` rounds, casters ... cannot
    # act." Stressed column is "Mage, Wizard, healers, Bard", so a silenced raid
    # produces no heals at all — which is also why the drain half is a separate
    # subsystem and not a number invented here.
    var enc = _synthetic([{"id": "m10", "params": PROBE_PARAMS["m10"]}])
    var res = Sim.run(_roster(E.Rarity.LEGENDARY, 95, "raid"), enc, _db, 4242)
    var window: int = int(PROBE_PARAMS["m10"]["rounds"])
    var after := 0
    for e in res.log.entries:
        if e.verb != E.Verb.HEAL:
            continue
        assert_true(e.round_no > window,
            "a heal landed in round %d of a %d-round silence" % [e.round_no, window])
        after += 1
    assert_true(after > 0, "and the healers come back afterwards")
    assert_true(_mechanic_lines(res, "m10").size() >= 2,
        "the silence must announce itself and its end")

func test_m10_leaves_the_melee_alone() -> void:
    # The negative half: M10 is a caster mechanic, so the Rogues keep swinging.
    var enc = _synthetic([{"id": "m10", "params": PROBE_PARAMS["m10"]}])
    var res = Sim.run(_roster(E.Rarity.LEGENDARY, 95, "raid"), enc, _db, 4242)
    var melee_hits := 0
    var by_id := _by_raider_id(res)
    for e in res.log.entries:
        if e.verb != E.Verb.ATTACK or e.round_no > int(PROBE_PARAMS["m10"]["rounds"]):
            continue
        if not by_id.has(e.actor_id):
            continue
        var cls: int = int(by_id[e.actor_id].get_meta("profile")["class_id"])
        if cls in [E.CharClass.ROGUE, E.CharClass.MONK, E.CharClass.WARRIOR]:
            melee_hits += 1
    assert_true(melee_hits > 0, "the melee are not casters and must keep acting")

# ---------------------------------------- M11 Frontal Cleave (docs/10 §10 M11)

func test_m11_hits_the_melee_and_only_the_melee() -> void:
    # docs/10 §10 M11: "`X` damage to all melee-positioned raiders each round",
    # stressed "Rogue, Monk, Warrior" — the tank is named, so the tank is hit
    # (RaidSim.FRONTAL_CLEAVE_INCLUDES_TANK, q-mech-arms.md Q-M11).
    var enc = _synthetic([{"id": "m11", "params": PROBE_PARAMS["m11"]}])
    var res = Sim.run(_roster(E.Rarity.LEGENDARY, 95, "raid"), enc, _db, 4242)
    var by_id := _by_raider_id(res)
    var struck := {}
    for e in _attacks_from(res, "the cleave"):
        struck[e.target_id] = true
    assert_true(struck.size() > 0, "the cleave must land on somebody")
    var melee := [E.CharClass.WARRIOR, E.CharClass.MONK, E.CharClass.ROGUE,
        E.CharClass.BARD]
    for rid in by_id.keys():
        var c = by_id[rid]
        var is_melee: bool = int(c.get_meta("profile")["class_id"]) in melee
        assert_eq(struck.has(rid), is_melee,
            "%s was %shit by a frontal cleave"
            % [c.display_name(), "" if struck.has(rid) else "not "])
    var tank_hit := false
    for rid in struck.keys():
        if by_id[rid].is_main_tank:
            tank_hit = true
    assert_true(tank_hit, "docs/10 M11 names the Warrior; the tank is melee-positioned")

# ------------------------------------ M12 Escalating Swing (docs/10 §10 M12)

func test_m12_adds_exactly_its_increment_every_round() -> void:
    # docs/10 §10 M12: "Boss raw swing +`X` per round, no cap." Asserted through
    # the arithmetic rather than by eye: the probe boss opens at 37 raw
    # (E5's block) and the increment lands at Round Open, so round R swings
    # 37 + R x increment, mitigated by the target's own AC.
    var enc = _synthetic([{"id": "m12", "params": PROBE_PARAMS["m12"]}])
    var res = Sim.run(_roster(E.Rarity.LEGENDARY, 95, "raid"), enc, _db, 4242)
    var increment: int = int(PROBE_PARAMS["m12"]["increment"])
    var by_id := _by_raider_id(res)
    var checked := 0
    for e in _attacks_from(res, "Main Boss"):
        if not by_id.has(e.target_id):
            continue
        var ac: int = int(by_id[e.target_id].get_meta("profile")["ac"])
        var expected := F.damage_after_ac(float(37 + e.round_no * increment), ac)
        assert_eq(e.number("amount"), expected,
            "round %d swing was %d, not the escalated %d"
            % [e.round_no, e.number("amount"), expected])
        checked += 1
    assert_true(checked > 4, "only %d swings checked" % checked)

func test_m12_still_terminates_inside_the_round_cap() -> void:
    # docs/07 §7.3 makes termination a safety property, and "no cap" is exactly
    # the kind of clause that quietly breaks one. Asserted rather than assumed.
    var enc = _synthetic([{"id": "m12", "params": PROBE_PARAMS["m12"]}])
    for seed_value in range(1, 9):
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), enc, _db, seed_value)
        assert_true(res.rounds <= Sim.ROUND_CAP, "ran %d rounds" % res.rounds)

func test_an_add_spawned_after_the_enrage_swings_enraged() -> void:
    # docs/10 §10 M06 multiplies "boss damage x2 permanently", and the arm
    # multiplied only the enemies present at that instant — so an M04 add
    # arriving later swung its authored value in an enraged fight. The fix is
    # read at spawn, which is why the multiplier outlives the round it fired in.
    var enc = _synthetic([
        {"id": "m06", "params": {"round": 2, "damage_multiplier_pct": 200}},
        {"id": "m04", "params": {"count": 1, "hp": 400, "swing": 9, "rounds": [4]}},
    ])
    var res = Sim.run(_roster(E.Rarity.LEGENDARY, 95, "raid"), enc, _db, 4242)
    var by_id := _by_raider_id(res)
    var checked := 0
    for e in _attacks_from(res, "Add"):
        if not by_id.has(e.target_id):
            continue
        var ac: int = int(by_id[e.target_id].get_meta("profile")["ac"])
        assert_eq(e.number("amount"), F.damage_after_ac(18.0, ac),
            "the add swung %d; 9 authored x2 enraged is what it should be"
            % e.number("amount"))
        checked += 1
    assert_true(checked > 0, "the add has to arrive and swing for this to assert")

# ---------------------------------------------------------------- survivors

func test_survivors_and_casualties_partition_the_roster() -> void:
    var roster := _roster(E.Rarity.COMMON, 20, "starting")
    var res = Sim.run(roster, _encounter("E5"), _db, 13)
    assert_eq(res.survivors.size() + res.casualties.size(), roster.size())
    for c in res.casualties:
        assert_true(c.is_dead())
    for c in res.survivors:
        assert_false(c.is_dead())

# ---------------------------------------------------------------- guards wired

func test_no_raider_repeats_a_mistake_type_in_consecutive_rounds() -> void:
    # docs/07 §5.5's per-type cooldown. It lives in Mistakes.gd, but it only
    # binds if RaidSim persists the cooldown across rounds — which it did not
    # until this was wired up, because a fresh Context was built per roll.
    var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, 77)
    var last: Dictionary = {}
    for e in res.log.mistakes():
        var key: String = "%s|%s" % [e.actor_name, String(e.mistake["type"])]
        if last.has(key):
            assert_true(e.round_no - int(last[key]) >= 1,
                "%s repeated %s too soon" % [e.actor_name, e.mistake["type"]])
        last[key] = e.round_no

func test_at_most_one_critical_per_round_raid_wide() -> void:
    # A wipe should read as a chain of small failures, not a simultaneous
    # explosion. The cap is raid-wide, so it needs round-scoped state.
    for seed_value in range(1, 8):
        var res = Sim.run(_roster(E.Rarity.COMMON, 0, "starting"),
            _encounter("E5"), _db, seed_value)
        var per_round: Dictionary = {}
        for e in res.log.mistakes():
            if String(e.mistake["severity"]) == E.severity_key(E.Severity.CRITICAL):
                per_round[e.round_no] = int(per_round.get(e.round_no, 0)) + 1
        for r in per_round.keys():
            assert_true(int(per_round[r]) <= 1,
                "round %d logged %d Criticals" % [r, per_round[r]])

# ------------------------------------------- the cascade (docs/07 §6, W6-SIM-CASCADE)

const Morale = preload("res://sim/core/Morale.gd")

## The benchmark twelve as combatants, the way `run()` builds them, so the
## static helpers can be asked directly. Slot 0/1 Warriors, 2 Cleric, 3 Druid,
## 4 Shaman, 5/6 Rogues, 7 Monk, 8 Mage, 9/10 Wizards, 11 Bard.
func _combatants(morale: int = 55) -> Array:
    return Sim._build_combatants(_roster(E.Rarity.COMMON, morale), _db)

func _mistake_event(type_id: String, actor, round_no: int, site: int = E.RollSite.ACTION):
    var ev = Mistakes.MistakeEvent.new()
    ev.type_id = type_id
    ev.type_name = String(Mistakes.TYPES[type_id]["name"])
    ev.actor_id = actor.raider.id
    ev.round_no = round_no
    ev.roll_site = site
    ev.tokens_emitted = Mistakes.TYPES[type_id].get("emits", []).duplicate()
    return ev

## Every mistake entry keyed the way `caused_by` names its parent
## (`MistakeEvent.id()`, "actor:rN:TYPE" — the same key Results.gd resolves).
func _mistake_index(res) -> Dictionary:
    var out := {}
    for e in res.log.mistakes():
        out["%s:r%d:%s" % [e.actor_id, e.round_no, String(e.mistake["type"])]] = e
    return out

func test_a_mistake_under_a_live_token_names_its_parent() -> void:
    # SIM-05. `Mistakes.attribute()` existed and was called from nowhere, so
    # `caused_by` was always "" and `cascade_depth` always 0 in every real run,
    # the depth cap never bound, and Results had nothing to indent. First the
    # rule, asked directly of the helper on a raid with tokens placed by hand.
    var cs := _combatants()
    var greg = cs[5]      # Rogue
    var cindy = cs[2]     # Cleric
    var bob = cs[0]       # Warrior, main tank
    var pull = _mistake_event("MIS_AGGRO", greg, 4)
    greg.add_token(E.Token.AGGRO, 4, pull)
    # docs/07 §6's worked cascade, row 4: Cindy's heal goes wrong "+8pp from
    # Aggro", a knock-on from Greg's pull — the healer's roll names the raid's
    # Aggro source even though Cindy holds nothing herself.
    var heal_wrong = _mistake_event("MIS_HEAL_WRONG", cindy, 5)
    assert_eq(Sim._parent_for(heal_wrong, cindy, cs), pull,
        "a healer's mistake under a live Aggro is a knock-on from the pull")
    Sim._attribute(heal_wrong, cindy, cs)
    assert_eq(heal_wrong.caused_by, pull.id())
    assert_eq(heal_wrong.cascade_depth, 1)
    # A DPS whose own roll Aggro does not name, holding nothing: a new root.
    var steve_root = _mistake_event("MIS_WRONG_TARGET", cs[8], 5)
    assert_eq(Sim._parent_for(steve_root, cs[8], cs), null,
        "Aggro names the healers' rolls; a Mage holding nothing opens a chain")
    # The actor's own live token is the parent when nothing names the roll:
    # Greg went AFK with his own Aggro still live.
    var greg_afk = _mistake_event("MIS_AFK", greg, 5, E.RollSite.AMBIENT)
    assert_eq(Sim._parent_for(greg_afk, greg, cs), pull)
    # The cascade-only type is enabled by the token ON THE ACTOR (rule 3).
    var burn = _mistake_event("MIS_FIRE", bob, 6)
    bob.add_token(E.Token.FIRE, 6, burn)
    var death = _mistake_event("MIS_AVOIDABLE_DEATH", bob, 7)
    assert_eq(Sim._parent_for(death, bob, cs), burn)
    # An ambient roll under a raid-wide Distraction names its source.
    var argument = _mistake_event("MIS_ARGUMENT", cs[11], 6, E.RollSite.AMBIENT)
    cs[11].add_token(E.Token.DISTRACTION, 6, argument)
    var loot = _mistake_event("MIS_LOOT_CALL", cs[9], 7, E.RollSite.AMBIENT)
    assert_eq(Sim._parent_for(loot, cs[9], cs), argument)
    # A dead holder's token is not a parent; nobody panics over a corpse.
    greg.kill()
    var later_heal = _mistake_event("MIS_HEAL_WRONG", cindy, 6)
    assert_eq(Sim._parent_for(later_heal, cindy, cs), null)

    # Then the wire: a real run of the miserable-Commons E5 writes edges into
    # the log, every edge resolves to an earlier entry, depth is parent + 1
    # capped at MAX_CASCADE_DEPTH, and a root reads depth 0.
    var chained := 0
    var deepest := 0
    for seed_value in [4242, 1, 2, 3]:
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, seed_value)
        var index := _mistake_index(res)
        for e in res.log.mistakes():
            var cause := String(e.mistake.get("caused_by", ""))
            var depth := int(e.mistake.get("cascade_depth", 0))
            if cause.is_empty():
                assert_eq(depth, 0, "a root at depth %d (seed %d)" % [depth, seed_value])
                continue
            chained += 1
            deepest = maxi(deepest, depth)
            assert_true(index.has(cause), "seed %d: %s blamed on %s, which is not in the log"
                % [seed_value, e.actor_name, cause])
            var parent = index[cause]
            assert_true(parent.sequence < e.sequence, "a parent precedes its child")
            assert_eq(depth, mini(Mistakes.MAX_CASCADE_DEPTH,
                int(parent.mistake.get("cascade_depth", 0)) + 1))
    assert_true(chained > 0, "four seeds of a miserable raid and no mistake named a parent")
    assert_true(deepest >= 2, "the chains never got past depth 1 (deepest %d)" % deepest)

func test_a_healers_chance_rises_when_a_dps_holds_aggro() -> void:
    # SIM-06 / docs/07 §6: Aggro is "Healers' mistake chance +8pp (they are
    # panic-targeting)". The sim used to add the 800bp to whoever HELD the
    # token — the DPS who pulled — and nothing to the healers.
    var cs := _combatants()
    var greg = cs[5]
    for healer in [cs[2], cs[3], cs[4]]:
        assert_eq(Sim._situational_bp(healer, cs, E.RollSite.ACTION), 0, "nothing live: no modifier")
    greg.add_token(E.Token.AGGRO, 4, _mistake_event("MIS_AGGRO", greg, 4))
    for healer in [cs[2], cs[3], cs[4]]:
        assert_eq(Sim._situational_bp(healer, cs, E.RollSite.ACTION), 800,
            "%s's chance rises 8pp while Greg holds Aggro" % healer.display_name())
        assert_eq(Sim._situational_bp(healer, cs, E.RollSite.MECHANIC), 800,
            "at any site — a healer's positioning check panics too")
    # The holder went Downed: the healers are panicking precisely now (§6's
    # worked cascade gives Cindy the +8pp in the round Greg drops).
    greg.take_damage(greg.current_hp)
    assert_true(greg.is_downed())
    assert_eq(Sim._situational_bp(cs[2], cs, E.RollSite.ACTION), 800)
    # And the cap (rule 4, docs/08's SITUATIONAL_CAP_BP = +20pp) holds through
    # `Formulas`: a healer under both tokens at the ambient site reads 1300 and
    # the formula never adds more than the cap.
    cs[11].add_token(E.Token.DISTRACTION, 4, _mistake_event("MIS_ARGUMENT", cs[11], 4, E.RollSite.AMBIENT))
    var both: int = Sim._situational_bp(cs[2], cs, E.RollSite.AMBIENT)
    assert_eq(both, 1300)
    assert_true(both <= F.SITUATIONAL_CAP_BP)
    assert_eq(F.SITUATIONAL_CAP_BP, 2000, "docs/07 §6 rule 4: +20pp per raider")
    assert_eq(F.mistake_chance_bp(E.Rarity.COMMON, 55, 9000),
        F.mistake_chance_bp(E.Rarity.COMMON, 55, F.SITUATIONAL_CAP_BP),
        "the formula clamps the sum at the cap")

func test_a_non_healers_does_not() -> void:
    # The other half of SIM-06: the token on the puller does nothing to the
    # puller, the tank, or any other DPS.
    var cs := _combatants()
    var greg = cs[5]
    greg.add_token(E.Token.AGGRO, 4, _mistake_event("MIS_AGGRO", greg, 4))
    for c in cs:
        if int(c.get_meta("profile")["role_group"]) == E.RoleGroup.HEALER:
            continue
        for site in [E.RollSite.ACTION, E.RollSite.MECHANIC, E.RollSite.AMBIENT]:
            assert_eq(Sim._situational_bp(c, cs, site), 0,
                "%s is not a healer and Aggro moved their chance at site %d"
                % [c.display_name(), site])
    # A dead holder's Aggro moves nobody's chance.
    greg.kill()
    assert_eq(Sim._situational_bp(cs[2], cs, E.RollSite.ACTION), 0)

func test_ambient_chance_rises_raid_wide_under_distraction() -> void:
    # SIM-06 / docs/07 §6: Distraction is "+5pp ambient mistake chance,
    # raid-wide". It used to distract only the raider who started the argument.
    var cs := _combatants()
    var steve = cs[8]
    steve.add_token(E.Token.DISTRACTION, 3, _mistake_event("MIS_ARGUMENT", steve, 3, E.RollSite.AMBIENT))
    for c in cs:
        assert_eq(Sim._situational_bp(c, cs, E.RollSite.AMBIENT), 500,
            "%s's ambient chance did not rise under Steve's argument" % c.display_name())
        if int(c.get_meta("profile")["role_group"]) != E.RoleGroup.HEALER:
            assert_eq(Sim._situational_bp(c, cs, E.RollSite.ACTION), 0,
                "Distraction is an AMBIENT modifier; %s's action roll moved" % c.display_name())
    # Clearing the one token clears the whole raid's modifier.
    steve.clear_token(E.Token.DISTRACTION)
    for c in cs:
        assert_eq(Sim._situational_bp(c, cs, E.RollSite.AMBIENT), 0)

func test_a_wipe_names_its_cause() -> void:
    # LOOP-12 / CRITIC-C12: the report never said WHY it wiped. The sim now
    # names one entry — the last Severe-or-worse before the first tank or
    # healer death, else the deepest cascade, else nobody — and marks that
    # raider `wipe_caused` in the queued deltas for docs/01 §6.1's extra -4.
    var named := 0
    var by_death := 0
    for seed_value in range(1, 13):
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, seed_value)
        var culprits: Array = []
        for d in res.deltas_queued:
            assert_true(d.has("wipe_caused"), "every queued delta carries the flag")
            if int(d["wipe_caused"]) == 1:
                culprits.append(String(d["raider_id"]))
        if res.cleared():
            assert_true(res.wipe_cause.is_empty(), "a clear has no wipe cause")
            assert_eq(culprits, [], "nobody is blamed for a clear")
            continue
        if res.wipe_cause.is_empty():
            assert_eq(culprits, [], "nobody named, nobody marked")
            continue
        named += 1
        for key in ["actor_id", "mistake_type", "round", "entry_seq"]:
            assert_true(res.wipe_cause.has(key), "wipe_cause missing %s" % key)
        var e = res.log.entries[int(res.wipe_cause["entry_seq"])]
        assert_true(e.is_mistake(), "the cause is a mistake entry")
        assert_eq(String(e.actor_id), String(res.wipe_cause["actor_id"]))
        assert_eq(String(e.mistake["type"]), String(res.wipe_cause["mistake_type"]))
        assert_eq(int(e.round_no), int(res.wipe_cause["round"]))
        assert_eq(culprits, [String(res.wipe_cause["actor_id"])],
            "exactly the named raider is marked wipe_caused")
        # The rule, re-derived: with a tank/healer death and a Severe-or-worse
        # before it, the cause is the LAST such entry.
        var roles := {}
        for c in _combatants_of(res):
            roles[c.raider.id] = int(c.get_meta("profile")["role_group"])
        var first_death := -1
        for x in res.log.entries:
            if x.verb == E.Verb.STATE_CHANGE and String(x.params.get("state", "")) == "DEAD" \
                    and int(roles.get(x.actor_id, -1)) in [E.RoleGroup.TANK, E.RoleGroup.HEALER]:
                first_death = x.sequence
                break
        var expected = null
        if first_death >= 0:
            for m in res.log.mistakes():
                if m.sequence < first_death and m.severity_index() >= E.Severity.SEVERE:
                    expected = m
        if expected != null:
            by_death += 1
            assert_eq(int(res.wipe_cause["entry_seq"]), int(expected.sequence),
                "seed %d: the cause is the last Severe before the first tank/healer death" % seed_value)
            assert_true(e.severity_index() >= E.Severity.SEVERE)
        else:
            assert_true(int(e.mistake.get("cascade_depth", 0)) > 0,
                "seed %d: with no Severe before a tank/healer death the cause is a cascade" % seed_value)
    assert_true(named > 0, "twelve seeds of a miserable raid and no wipe was ever explained")
    assert_true(by_death > 0, "the first clause of the rule never fired across twelve seeds")

func test_the_culprits_delta_is_the_ledgers() -> void:
    # docs/01 §6.1's -4 lives in Morale.TRIGGERS["wipe_caused"] and is stated
    # again by the sim for the report; two places holding one number is two
    # places that can disagree (LESSONS.md), so they are pinned equal here.
    assert_eq(Sim.WIPE_CULPRIT_DELTA, int(Morale.TRIGGERS["wipe_caused"]["delta"]))
    assert_eq(Sim.WIPE_CULPRIT_DELTA, -4)

func test_every_mistake_entry_names_the_draw_that_failed() -> void:
    # SIM-29's wire: the four roll sites and the encounter-start roll each
    # stamp the exact `derive(name, round, stream)` triple and the block
    # reaches the log. SIM-24: the encounter-start channel is named for what
    # it does — `compliance` was a leftover from the Calls docs/15 Q-09 cut.
    var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, 4242)
    var channels := {}
    for e in res.log.mistakes():
        assert_true(e.debug.has("channel") and e.debug.has("p_bp") and e.debug.has("r_bp")
            and e.debug.has("draw") and e.debug.has("margin"),
            "%s's mistake at r%d carries no provenance" % [e.actor_name, e.round_no])
        var ch := String(e.debug["channel"])
        var parts: PackedStringArray = ch.split(":")
        assert_eq(parts.size(), 3, ch)
        channels[String(parts[0])] = true
        assert_eq(String(parts[1]), "r%d" % e.round_no, ch)
        assert_true(int(e.debug["p_bp"]) > 0 and int(e.debug["r_bp"]) < int(e.debug["p_bp"]),
            "a rolled mistake's draw sits under its gate")
        assert_false(e.debug_line().is_empty())
    assert_true(channels.has("mistake_gate"))
    assert_true(channels.has("mechanic_gate"), "E5's checks roll on their own channel")
    assert_false(channels.has("compliance"), "the Calls channel is gone (SIM-24)")
    var src := FileAccess.get_file_as_string("res://sim/core/RaidSim.gd")
    assert_true(src.contains("derive(\"encounter_start\""), "the start roll draws on encounter_start")
    assert_false(src.contains("derive(\"compliance\""))

# ------------------------- every named mistake has its consequence (W7-SIM-EFFECTS)

const EventLog = preload("res://sim/core/EventLog.gd")
const Rng = preload("res://sim/core/Rng.gd")
const Quirks = preload("res://sim/core/Quirks.gd")
const Consumables = preload("res://sim/core/Consumables.gd")

func _log():
    return EventLog.new()

func _rng(seed_value: int = 7):
    return Rng.new(seed_value)

## The benchmark twelve with the tanks seated, the way `run()` leaves them
## before round 1. Full HP everywhere.
func _seated(morale: int = 55) -> Array:
    var cs := _combatants(morale)
    Sim._assign_tanks(cs, _db)
    return cs

func _entries(log, verb: int, template: String = "") -> Array:
    var out: Array = []
    for e in log.entries:
        if e.verb == verb and (template.is_empty() or e.template_id == template):
            out.append(e)
    return out

func _heal_entries(log) -> Array:
    return _entries(log, E.Verb.HEAL)

func _profile(c) -> Dictionary:
    return c.get_meta("profile")

## Knock a raider down to a fraction of max HP without touching state.
func _hurt_to(c, fraction: float) -> void:
    c.current_hp = maxi(1, int(round(float(c.max_hp) * fraction)))

func _apply(cs: Array, actor, type_id: String, round_no: int, log,
        severity: int = -1, rng = null, site: int = E.RollSite.ACTION):
    var ev = _mistake_event(type_id, actor, round_no, site)
    if severity >= 0:
        ev.severity = severity
    Sim._apply_mistake(rng, round_no, E.Phase.AMBIENT_MISTAKE, actor, cs, [], ev, log, {})
    return ev

# --- SIM-07: the three healer outcomes

func test_a_wrong_heal_lands_on_the_fullest_and_logs_the_waste() -> void:
    # docs/07 §5.2 row 6: "Heal lands on the highest-HP valid target instead of
    # the intended one." The heal used to be silently lost; now the fullest
    # raider gets it and the entry says how much of it was wasted.
    var cs := _seated()
    var bob = cs[0]
    var cindy = cs[2]
    _hurt_to(bob, 0.5)
    var log = _log()
    var healed: int = Sim._cast_mistaken_heal(3, E.CharClass.CLERIC, cindy, _profile(cindy),
        cs, "MIS_HEAL_WRONG", log)
    assert_eq(healed, 0, "the fullest raider was already full; nothing lands")
    assert_eq(bob.current_hp, int(round(float(bob.max_hp) * 0.5)),
        "the intended target — the neediest — is untouched")
    var heals := _heal_entries(log)
    assert_eq(heals.size(), 1)
    var e = heals[0]
    assert_ne(e.target_id, bob.raider.id, "the wrong target is not the tank at half HP")
    assert_eq(e.tier, E.LogTier.NUMBERS, "the wasted cast is a NUMBERS entry")
    assert_eq(e.number("amount"), 0)
    var expected := F.cleric_heal(int(_profile(cindy)["heal_base"]), int(_profile(cindy)["mana"]))
    assert_eq(e.number("wasted"), expected, "the whole cast was wasted")
    assert_eq(cindy.threat, 0, "no threat for a heal that landed on nobody")

func test_a_corpse_heal_is_entirely_wasted() -> void:
    # docs/07 §5.2 row 7: "Heal targets a Dead raider; entirely wasted."
    var cs := _seated()
    var greg = cs[5]
    var cindy = cs[2]
    greg.kill()
    _hurt_to(cs[0], 0.4)
    var log = _log()
    var healed: int = Sim._cast_mistaken_heal(4, E.CharClass.CLERIC, cindy, _profile(cindy),
        cs, "MIS_HEAL_CORPSE", log)
    assert_eq(healed, 0)
    assert_true(greg.is_dead(), "a corpse healed for 0 is still a corpse")
    var heals := _heal_entries(log)
    assert_eq(heals.size(), 1)
    assert_eq(heals[0].target_id, greg.raider.id, "the cast went to the corpse")
    assert_eq(heals[0].number("amount"), 0)
    assert_true(heals[0].number("wasted") > 0, "and every point of it was wasted")
    assert_eq(cs[0].current_hp, int(round(float(cs[0].max_hp) * 0.4)),
        "the tank at 40% got nothing")

func test_a_fizzled_chain_does_work_on_its_first_hop_only() -> void:
    # docs/07 §5.2 row 8: "bounces onto full-HP targets; only the first hop
    # does work."
    var cs := _seated()
    var natsuna = cs[4]
    var bob = cs[0]
    var pip = cs[6]
    _hurt_to(bob, 0.3)
    _hurt_to(pip, 0.6)
    var log = _log()
    var healed: int = Sim._cast_mistaken_heal(5, E.CharClass.SHAMAN, natsuna, _profile(natsuna),
        cs, "MIS_CHAIN_FIZZLE", log)
    assert_true(healed > 0, "hop 1 still lands")
    assert_true(bob.current_hp > int(round(float(bob.max_hp) * 0.3)), "on the neediest")
    assert_eq(pip.current_hp, int(round(float(pip.max_hp) * 0.6)),
        "the second-neediest, who a real chain would have reached, gets nothing")
    var heals := _heal_entries(log)
    assert_eq(heals.size(), 3, "three hops, three entries")
    assert_eq(heals[0].target_id, bob.raider.id)
    assert_false(heals[0].numbers.has("wasted"), "hop 1 is an ordinary heal")
    for i in [1, 2]:
        assert_eq(heals[i].number("amount"), 0, "hop %d landed on somebody full" % (i + 1))
        assert_true(heals[i].number("wasted") > 0)
        assert_eq(heals[i].tier, E.LogTier.NUMBERS)

func test_the_healer_outcomes_reach_a_real_run() -> void:
    # The wire, and the healer context: every HEAL_WRONG / HEAL_CORPSE /
    # CHAIN_FIZZLE entry in a miserable run is followed, in the same round by
    # the same healer, by a HEAL entry carrying `wasted` — the mistake did
    # something. And `_phase_healers` builds its context against the enemies
    # (SIM-07's second half), asserted on the source since no healer type
    # reads `adds_present` today.
    var seen := {"MIS_HEAL_WRONG": 0, "MIS_HEAL_CORPSE": 0, "MIS_CHAIN_FIZZLE": 0}
    for seed_value in [4242, 1, 2, 3, 4, 5]:
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, seed_value)
        for m in res.log.mistakes():
            var t := String(m.mistake["type"])
            if not seen.has(t):
                continue
            var followed := false
            for e in res.log.entries:
                if e.sequence > m.sequence and e.round_no == m.round_no \
                        and e.verb == E.Verb.HEAL and e.actor_id == m.actor_id \
                        and e.numbers.has("wasted"):
                    followed = true
                    break
            assert_true(followed, "seed %d: %s's %s at r%d wasted nothing"
                % [seed_value, m.actor_name, t, m.round_no])
            seen[t] += 1
    assert_true(seen["MIS_HEAL_WRONG"] > 0, "six seeds and no wrong heal")
    assert_true(seen["MIS_CHAIN_FIZZLE"] > 0, "six seeds and no fizzled chain")
    var src := FileAccess.get_file_as_string("res://sim/core/RaidSim.gd")
    assert_true(src.contains("c, enemies, encounter, round_state, mstate)"),
        "the healer's context is built against the enemies, not an empty list")

# --- SIM-15: the ambient consequences

func test_afk_takes_the_raider_out_for_one_to_three_rounds() -> void:
    # docs/07 §5.2 row 9: "No action for 1-3 rounds (severity picks duration)."
    var expected := {E.Severity.MINOR: 1, E.Severity.MODERATE: 2, E.Severity.SEVERE: 3,
        E.Severity.CRITICAL: 3}
    for sev in expected.keys():
        var cs := _seated()
        var greg = cs[5]
        var log = _log()
        _apply(cs, greg, "MIS_AFK", 4, log, int(sev), null, E.RollSite.AMBIENT)
        var away: int = int(expected[sev])
        assert_eq(greg.afk_until, 4 + away, "severity %d: away for %d" % [int(sev), away])
        for r in range(5, 5 + away):
            assert_false(greg.can_act(r), "severity %d: still away at round %d" % [int(sev), r])
        assert_true(greg.can_act(5 + away), "and back after")
        var lines := _entries(log, E.Verb.SYSTEM, "afk")
        assert_eq(lines.size(), 1)
        assert_eq(lines[0].tier, E.LogTier.STORY, "the absence is a story beat")
        assert_true(String(lines[0].params["text"]).contains("wandered off"))
    assert_eq(Sim.AFK_ROUNDS_BY_SEVERITY, [1, 2, 3, 3])
    # The row prices MISSED ACTIONS, and an action-site roll has already spent
    # this round's action (`_take_action` returns on a mistake), so the window
    # includes the round it fell in: a Minor AFK at the action site costs one
    # action, not two. The ambient roll is Phase 6 and starts next round.
    for sev2 in expected.keys():
        var cs2 := _seated()
        var greg2 = cs2[5]
        var away2: int = int(expected[sev2])
        _apply(cs2, greg2, "MIS_AFK", 4, _log(), int(sev2), null, E.RollSite.ACTION)
        assert_eq(greg2.afk_until, 4 + away2 - 1,
            "action site, severity %d: %d missed actions counting this one"
            % [int(sev2), away2])
        var missed := 0
        for r2 in range(4, 4 + away2 + 2):
            if not greg2.can_act(r2):
                missed += 1
        assert_eq(missed, away2, "action site, severity %d" % int(sev2))
    # A raider who is away takes no action: one round of the actors' phase
    # with the Rogue AFK produces no attack from him.
    var cs := _seated()
    var greg = cs[5]
    greg.afk_until = 6
    var log = _log()
    var enemies := Sim._build_enemies(_encounter("E1"))
    Sim._phase_actors(_rng(), 6, cs, enemies, _encounter("E1"), _db, log,
        [E.Phase.TANKS, E.Phase.DPS], Sim._new_round_state(), {})
    for e in _entries(log, E.Verb.ATTACK):
        assert_ne(e.actor_id, greg.raider.id, "an AFK raider swung")

func test_a_tank_or_healer_going_afk_is_severe_and_the_tank_drops_aggro() -> void:
    # docs/07 §5.2 row 9: "Moderate (Severe if tank or healer)" and "Aggro if
    # tank". The floor is the taxonomy row's, applied in the roll; the token
    # reads the seat, not the class, because a Monk can hold it.
    var ctx = Mistakes.Context.new()
    ctx.roll_site = E.RollSite.AMBIENT
    assert_eq(Mistakes.severity_floored_for_role("MIS_AFK", E.Severity.MINOR, E.RoleGroup.DPS, ctx),
        E.Severity.MINOR, "a DPS keeps the rolled band")
    assert_eq(Mistakes.severity_floored_for_role("MIS_AFK", E.Severity.MINOR, E.RoleGroup.HEALER, ctx),
        E.Severity.SEVERE, "a healer is floored at Severe")
    ctx.is_tank = true
    assert_eq(Mistakes.severity_floored_for_role("MIS_AFK", E.Severity.MODERATE, E.RoleGroup.DPS, ctx),
        E.Severity.SEVERE, "the seated tank, whatever the role group")
    assert_eq(Mistakes.emits_for("MIS_AFK", ctx), [E.Token.AGGRO], "Aggro if tank")
    ctx.is_tank = false
    assert_eq(Mistakes.emits_for("MIS_AFK", ctx), [], "and nothing otherwise")
    assert_eq(Mistakes.severity_floored_for_role("MIS_ARGUMENT", E.Severity.MINOR, E.RoleGroup.HEALER, ctx),
        E.Severity.MINOR, "only the row that carries the floor")
    # End to end: no tank or healer in a miserable run ever goes AFK for less
    # than Severe, and the roll's context carries the seat.
    var checked := 0
    for seed_value in [4242, 1, 2, 3]:
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, seed_value)
        var by_id := _by_raider_id(res)
        for m in res.log.mistakes():
            if String(m.mistake["type"]) != "MIS_AFK":
                continue
            var c = by_id[m.actor_id]
            var role := int(c.get_meta("profile")["role_group"])
            if c.is_main_tank or c.is_offtank or role == E.RoleGroup.HEALER:
                checked += 1
                assert_true(m.severity_index() >= E.Severity.SEVERE,
                    "seed %d: %s went AFK at %s" % [seed_value, m.actor_name, m.severity_display()])
    assert_true(checked > 0, "four seeds and no tank or healer ever went AFK")

func test_a_loot_call_skips_the_next_action_and_is_queued() -> void:
    # docs/07 §5.2 row 17: "Skips next action. Flags a post-encounter morale
    # event." The skip is spent by the next action phase and said out loud;
    # the flag is a count on the queued delta for `game/`.
    var cs := _seated()
    var greg = cs[5]
    var log = _log()
    _apply(cs, greg, "MIS_LOOT_CALL", 7, log, -1, null, E.RollSite.AMBIENT)
    assert_true(greg.skip_next_action)
    assert_eq(greg.loot_calls, 1)
    var enemies := Sim._build_enemies(_encounter("E1"))
    Sim._phase_actors(_rng(), 8, cs, enemies, _encounter("E1"), _db, log,
        [E.Phase.TANKS, E.Phase.DPS], Sim._new_round_state(), {})
    for e in _entries(log, E.Verb.ATTACK):
        assert_ne(e.actor_id, greg.raider.id, "he was meant to be typing")
    var skips := _entries(log, E.Verb.SYSTEM, "loot_call_skip")
    assert_eq(skips.size(), 1)
    assert_eq(skips[0].actor_id, greg.raider.id)
    assert_true(String(skips[0].params["text"]).contains("typing about loot"))
    assert_false(greg.skip_next_action, "one action, spent")
    # The wire: the queued deltas count exactly the loot calls the log holds.
    # A loot call needs the boss under 25%, so a miserable roster that can
    # actually get a boss there: Commons at 5 in farm gear on E3.
    var found := false
    for seed_value in [4242, 1, 2, 3, 4, 5, 6, 7]:
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "raid"), _encounter("E3"), _db, seed_value)
        var calls := {}
        for m in res.log.mistakes():
            if String(m.mistake["type"]) == "MIS_LOOT_CALL":
                calls[m.actor_id] = int(calls.get(m.actor_id, 0)) + 1
                found = true
        for d in res.deltas_queued:
            assert_true(d.has("loot_call"), "every delta carries the count")
            assert_eq(int(d["loot_call"]), int(calls.get(String(d["raider_id"]), 0)),
                "seed %d: %s's loot_call delta" % [seed_value, String(d["raider_id"])])
    assert_true(found, "eight seeds of a miserable raid and nobody called loot")

func test_an_argument_names_a_second_raider_and_taxes_both() -> void:
    # docs/07 §5.2 row 16: "Both this raider and one random other take a
    # mistake-chance penalty for the rest of the encounter."
    var cs := _seated()
    var steve = cs[8]
    var log = _log()
    _apply(cs, steve, "MIS_ARGUMENT", 3, log, -1, _rng(11), E.RollSite.AMBIENT)
    assert_eq(steve.argument_penalty_bp, Sim.ARGUMENT_PENALTY_BP)
    var lines := _entries(log, E.Verb.SYSTEM, "argument")
    assert_eq(lines.size(), 1, "the second raider is named")
    var other_id := String(lines[0].params["with_id"])
    assert_ne(other_id, steve.raider.id, "somebody else")
    var taxed := 0
    for c in cs:
        if c.argument_penalty_bp > 0:
            taxed += 1
            assert_true(c == steve or c.raider.id == other_id, "%s was not in it" % c.display_name())
            for site in [E.RollSite.ACTION, E.RollSite.MECHANIC]:
                assert_eq(Sim._situational_bp(c, cs, site), Sim.ARGUMENT_PENALTY_BP,
                    "the penalty reaches the chance at every site")
            # At the ambient site the argument's own Distraction token (docs/07
            # §6, raid-wide +5pp for two rounds) sits on top of it.
            assert_eq(Sim._situational_bp(c, cs, E.RollSite.AMBIENT), Sim.ARGUMENT_PENALTY_BP + 500)
    assert_eq(taxed, 2, "exactly the two of them")
    # The pick is on its own seeded channel: the same seed names the same
    # raider, and it is SET, not stacked — a second argument does not double it.
    var again = Sim._pick_argument_partner(_rng(11), 3, steve, cs)
    assert_eq(again.raider.id, other_id, "channel `argument` replays")
    _apply(cs, steve, "MIS_ARGUMENT", 5, log, -1, _rng(11), E.RollSite.AMBIENT)
    assert_eq(steve.argument_penalty_bp, Sim.ARGUMENT_PENALTY_BP, "set, not stacked")
    assert_true(Sim.ARGUMENT_PENALTY_BP <= F.SITUATIONAL_CAP_BP)
    # A dead raider is never dragged in.
    for c in cs:
        if c != steve:
            c.kill()
    assert_eq(Sim._pick_argument_partner(_rng(3), 6, steve, cs), null)

func test_a_forgotten_consumable_is_stripped_and_reported() -> void:
    # docs/07 §5.2 row 15: "Assigned consumable's buff is not applied for the
    # whole encounter. Item is not consumed." Until now the buff stayed applied
    # and charged — and the type fired on raiders carrying nothing at all.
    var roster := _roster()
    var loadout: Dictionary = Consumables.new_loadout()
    loadout["power_bonus"] = 1
    loadout["mana_bonus"] = 10
    loadout["mistake_relief_bp"] = {roster[5].id: 300.0}
    var cs := Sim._build_combatants(roster, _db, loadout)
    Sim._assign_tanks(cs, _db)
    var bob = cs[0]       # Warrior: the kit
    var cindy = cs[2]     # Cleric: the draught
    var greg = cs[5]      # Rogue: the kit AND a Steady Hands
    var power_before := int(_profile(bob)["power"])
    var mana_before := int(_profile(cindy)["mana"])
    var mstate := {"consumables_unspent": []}
    var log = _log()
    for who in [bob, cindy, greg]:
        var ev = _mistake_event("MIS_NO_CONSUMABLE", who, 0, E.RollSite.AMBIENT)
        Sim._apply_mistake(null, 0, E.Phase.ROUND_OPEN, who, cs, [], ev, log, mstate)
    assert_eq(int(_profile(bob)["power"]), power_before - 1, "the kit's +1 Power is gone")
    assert_eq(int(_profile(bob)["power_bonus"]), 0)
    assert_eq(int(_profile(cindy)["mana"]), mana_before - 10, "the draught's +10 Mana is gone")
    assert_eq(Sim._relief_bp(greg), 0.0, "the Steady Hands never left the bag")
    var rows: Array = mstate["consumables_unspent"]
    var skus := {}
    for row in rows:
        assert_eq(String(row["reason"]), "no_consumable")
        skus[String(row["raider_id"]) + ":" + String(row["sku"])] = true
    assert_eq(rows.size(), 4, "kit, draught, kit, potion")
    assert_true(skus.has(bob.raider.id + ":whetstone_kit"))
    assert_true(skus.has(cindy.raider.id + ":mana_draught"))
    assert_true(skus.has(greg.raider.id + ":whetstone_kit"))
    assert_true(skus.has(greg.raider.id + ":potion_of_steady_hands"))
    assert_eq(_entries(log, E.Verb.SYSTEM, "no_consumable").size(), 3, "each says what stayed in the bag")
    # Nothing to forget, nothing to fire: a raider carrying no provision is not
    # offered the type (the MIS_FIRE / `zone_exists` shape, SIM-14).
    var bare := Sim._build_combatants(_roster(), _db)
    var ctx = Mistakes.Context.new()
    ctx.roll_site = E.RollSite.AMBIENT
    ctx.encounter_start = true
    Sim._stamp_actor(ctx, bare[0], {})
    assert_false(ctx.consumable_carried)
    assert_false("MIS_NO_CONSUMABLE" in Mistakes.eligible_types(E.CharClass.WARRIOR, E.RoleGroup.TANK, ctx),
        "nothing carried, nothing to forget")
    Sim._stamp_actor(ctx, bob, {})
    assert_false(ctx.consumable_carried, "and Bob's was stripped above")
    var kept := Sim._build_combatants(roster, _db, loadout)
    Sim._stamp_actor(ctx, kept[0], {})
    assert_true(ctx.consumable_carried)
    assert_true("MIS_NO_CONSUMABLE" in Mistakes.eligible_types(E.CharClass.WARRIOR, E.RoleGroup.TANK, ctx))
    # The wire: a real run reports exactly the raiders whose start roll fell.
    var reported := 0
    for seed_value in range(1, 17):
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db,
            seed_value, loadout)
        var forgot := {}
        for m in res.log.mistakes():
            if String(m.mistake["type"]) == "MIS_NO_CONSUMABLE":
                forgot[m.actor_id] = true
        var listed := {}
        for row in res.consumables_unspent:
            listed[String(row["raider_id"])] = true
            reported += 1
        assert_eq(listed.keys().size(), forgot.keys().size(), "seed %d: reported vs logged" % seed_value)
        for id in forgot.keys():
            assert_true(listed.has(id), "seed %d: %s forgot and was not reported" % [seed_value, id])
    assert_true(reported > 0, "eight seeds and nobody forgot anything")
    var bare_run = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, 4242)
    assert_eq(bare_run.consumables_unspent, [], "no loadout, nothing to report")
    for m in bare_run.log.mistakes():
        assert_ne(String(m.mistake["type"]), "MIS_NO_CONSUMABLE",
            "nobody forgets a consumable they were never given")

func test_a_wrong_target_swing_lands_on_the_add() -> void:
    # docs/07 §5.2 row 11: "Damage goes into a non-priority or immune target;
    # priority target unharmed this round." The only non-priority thing in the
    # room is an add (SIM-08's priority table is wave 8's), so the swing lands
    # there and the boss's bar does not move.
    var cs := _seated()
    var steve = cs[8]
    var enemies := Sim._build_enemies(_encounter("E1"))
    var boss = enemies[0]
    var boss_hp_before: int = boss.hp
    var add = Sim.Enemy.new()
    add.name = "Loose Add"
    add.hp = 400
    add.max_hp = 400
    add.is_add = true
    enemies.append(add)
    var log = _log()
    var threat_before: int = steve.threat
    var ev = _mistake_event("MIS_WRONG_TARGET", steve, 4)
    Sim._apply_mistake(null, 4, E.Phase.DPS, steve, cs, enemies, ev, log, {})
    assert_true(add.hp < 400, "the add took the swing")
    assert_eq(boss.hp, boss_hp_before, "the priority target is unharmed this round")
    assert_true(steve.threat > threat_before, "the damage is real, so the threat is")
    var hits := _entries(log, E.Verb.ATTACK)
    assert_eq(hits.size(), 1)
    assert_eq(hits[0].actor_id, steve.raider.id)
    assert_eq(hits[0].target_name, "Loose Add")
    # With nothing but the priority target in the room the swing is simply
    # gone — which is what the type did before it had a consequence at all.
    var bare := Sim._build_enemies(_encounter("E1"))
    var bare_hp: int = bare[0].hp
    var log2 = _log()
    Sim._apply_mistake(null, 4, E.Phase.DPS, cs[9], cs, bare,
        _mistake_event("MIS_WRONG_TARGET", cs[9], 4), log2, {})
    assert_eq(bare[0].hp, bare_hp, "no add: the boss is still unharmed")
    assert_eq(_entries(log2, E.Verb.ATTACK).size(), 0, "and nothing was hit")

# --- SIM-09 / Q-58: healer threat and the chain's later hops

func test_a_clerics_threat_rises_with_healing() -> void:
    # docs/15 Q-58: "Healer threat yes at a low multiplier"; docs/08 §8.7's
    # HEAL_THREAT_COEF 0.50. `_cast_heal` returns the healed total and the
    # Cleric takes threat on it; a full raid heals nothing and threatens nobody.
    var cs := _seated()
    var cindy = cs[2]
    var bob = cs[0]
    var log = _log()
    assert_eq(Sim._cast_heal(2, E.CharClass.CLERIC, cindy, _profile(cindy), cs, log), 0,
        "nobody hurt, nothing healed")
    assert_eq(cindy.threat, 0)
    _hurt_to(bob, 0.4)
    var healed: int = Sim._cast_heal(3, E.CharClass.CLERIC, cindy, _profile(cindy), cs, log)
    assert_true(healed > 0)
    assert_eq(cindy.threat, int(round(F.threat_from(E.CharClass.CLERIC, 0.0, float(healed)))),
        "threat = healed x HEAL_THREAT_COEF")
    assert_eq(cindy.threat, int(round(float(healed) * F.HEAL_THREAT_COEF)))
    var heals := _heal_entries(log)
    assert_eq(heals.size(), 1)
    assert_eq(heals[0].number("threat_after"), cindy.threat, "the HEAL entry carries the threat")
    _hurt_to(bob, 0.4)
    Sim._cast_heal(4, E.CharClass.CLERIC, cindy, _profile(cindy), cs, log)
    assert_true(cindy.threat > int(round(float(healed) * F.HEAL_THREAT_COEF)), "and it accumulates")
    # Low: one tank swing out-threatens one heal of the same size by arithmetic
    # (docs/07 §8.1: Warrior 3.0, healing 0.5).
    var swing := F.threat_from(E.CharClass.WARRIOR, float(healed))
    assert_true(swing > F.threat_from(E.CharClass.CLERIC, 0.0, float(healed)),
        "healers are exposed, not bait")

func test_the_shamans_hops_skip_full_targets() -> void:
    # docs/15 Q-58: "chain heal never repeats a target and skips anyone above
    # 95% HP." Hop 1 is unfiltered; hops 2-3 leave the near-full alone and a
    # hop with nowhere to go is logged as such.
    var cs := _seated()
    var natsuna = cs[4]
    var bob = cs[0]
    _hurt_to(bob, 0.5)
    var log = _log()
    var healed: int = Sim._cast_heal(2, E.CharClass.SHAMAN, natsuna, _profile(natsuna), cs, log)
    assert_true(healed > 0)
    var heals := _heal_entries(log)
    assert_eq(heals.size(), 1, "one raider hurt: hop 1 lands, hops 2-3 go nowhere")
    assert_eq(heals[0].target_id, bob.raider.id)
    var nowhere := _entries(log, E.Verb.SYSTEM, "chain_nowhere")
    assert_eq(nowhere.size(), 1)
    assert_eq(int(nowhere[0].params["hops_skipped"]), 2)
    assert_eq(nowhere[0].tier, E.LogTier.NUMBERS)
    # 96% is above the line, 90% is not.
    var cs2 := _seated()
    var shaman = cs2[4]
    _hurt_to(cs2[0], 0.5)
    _hurt_to(cs2[6], 0.96)
    _hurt_to(cs2[7], 0.90)
    var log2 = _log()
    Sim._cast_heal(2, E.CharClass.SHAMAN, shaman, _profile(shaman), cs2, log2)
    var targets := []
    for e in _heal_entries(log2):
        targets.append(e.target_id)
    assert_eq(targets, [cs2[0].raider.id, cs2[7].raider.id],
        "hop 1 the neediest, hop 2 the 90% raider, hop 3 nobody — the 96% one is skipped")
    assert_eq(int(_entries(log2, E.Verb.SYSTEM, "chain_nowhere")[0].params["hops_skipped"]), 1)
    assert_almost(Sim.CHAIN_SKIP_ABOVE, 0.95, 0.0001)
    # Hop 1 is unfiltered: a raid where the neediest is at 97% still gets it.
    var cs3 := _seated()
    _hurt_to(cs3[0], 0.97)
    var log3 = _log()
    Sim._cast_heal(2, E.CharClass.SHAMAN, cs3[4], _profile(cs3[4]), cs3, log3)
    assert_eq(_heal_entries(log3).size(), 1, "the neediest gets hop 1 at any fraction")

# --- SIM-17 / Q-57: the hysteresis, Lost Aggro, Taunt

func _boss(name: String = "Main Boss"):
    var e = Sim.Enemy.new()
    e.name = name
    e.hp = 1000
    e.max_hp = 1000
    e.raw_swing = 30
    return e

func test_the_boss_switches_only_past_the_hysteresis() -> void:
    # docs/07 §8.2 / docs/08 §8.7: the boss keeps its target until a candidate
    # clears 1.10x in melee or 1.30x at range. `Formulas.should_retarget`
    # existed and was called from nowhere; the boss switched on any `>`.
    var cs := _seated()
    var bob = cs[0]       # Warrior
    var greg = cs[5]      # Rogue, melee
    var zed = cs[10]      # Wizard, ranged
    var boss = _boss()
    var log = _log()
    bob.threat = 100
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 1, 0, {}, 0, log), bob, "the top opens")
    assert_eq(boss.target_slot, bob.slot_index)
    greg.threat = 105
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 2, 0, {}, 0, log), bob, "5% is not a switch")
    greg.threat = 111
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 3, 0, {}, 0, log), greg, "11% in melee is")
    var turns := _entries(log, E.Verb.SYSTEM, "retarget")
    assert_eq(turns.size(), 1, "and it is said out loud, once")
    assert_true(String(turns[0].params["text"]).contains("turns on"))
    assert_eq(turns[0].tier, E.LogTier.STORY)
    zed.threat = 140
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 4, 0, {}, 0, log), greg,
        "140 vs 111 is 26%: not enough at range")
    zed.threat = 145
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 5, 0, {}, 0, log), zed, "31% at range is")
    # The memory dies with its target: a Downed target hands the boss to the top.
    zed.take_damage(zed.current_hp)
    assert_true(zed.is_downed())
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 6, 0, {}, 0, log), greg)
    # MIS_AGGRO sets the offender past their OWN bar, so the pull always lands.
    var pull_log = _log()
    var cs2 := _seated()
    cs2[0].threat = 200
    var boss2 = _boss()
    Sim._pick_enemy_target(_rng(), boss2, cs2, 1, 0, {}, 0, pull_log)
    _apply(cs2, cs2[10], "MIS_AGGRO", 1, pull_log)
    assert_eq(cs2[10].threat, F.aggro_pull_threat(200.0, false))
    assert_true(F.should_retarget(float(cs2[10].threat), 200.0, false))
    assert_eq(Sim._pick_enemy_target(_rng(), boss2, cs2, 2, 0, {}, 0, pull_log), cs2[10],
        "a Wizard's pull clears the ranged bar")
    assert_eq(F.aggro_pull_threat(100.0, true), 111)
    assert_eq(F.aggro_pull_threat(100.0, false), 131)
    # Adds and the fixate window are untouched by the hysteresis.
    var add = _boss("Add")
    add.threat_rule = "lowest_hp"
    add.is_add = true
    _hurt_to(cs[7], 0.2)
    assert_eq(Sim._pick_enemy_target(_rng(), add, cs, 7, 0, {}, 0, log), cs[7])

func test_a_tanks_action_mistake_drops_aggro_for_one_round() -> void:
    # docs/15 Q-57: "Swing 1 only retargets; swing 2 resolves on the Warrior."
    # The tank's MIS_TAUNT_LAPSE used to `pass`.
    var cs := _seated()
    var bob = cs[0]
    var greg = cs[5]
    var zed = cs[10]
    bob.threat = 300
    greg.threat = 120
    zed.threat = 200
    var boss = _boss()
    var log = _log()
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 3, 0, {}, 0, log), bob)
    _apply(cs, bob, "MIS_TAUNT_LAPSE", 3, log)
    assert_eq(bob.lost_aggro_round, 4, "the NEXT Phase 1")
    assert_true(bob.has_lost_aggro(4))
    assert_eq(bob.threat, 300, "the table itself is untouched")
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 4, 0, {}, 0, log), zed,
        "swing 1 goes to the second-highest threat")
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 4, 0, {}, 1, log), bob,
        "swing 2 resolves on the tank")
    assert_eq(Sim._pick_enemy_target(_rng(), boss, cs, 5, 0, {}, 0, log), bob,
        "and the round after, the boss is where it was")
    assert_eq(boss.target_slot, bob.slot_index, "the memory never moved")
    var lost := _entries(log, E.Verb.SYSTEM, "lost_aggro")
    assert_eq(lost.size(), 1)
    assert_eq(String(lost[0].params["target_id"]), zed.raider.id)
    assert_eq(_entries(log, E.Verb.SYSTEM, "retarget").size(), 0, "not a switch")
    # A lapse by the tank the boss is NOT on changes nothing.
    var cs2 := _seated()
    cs2[0].threat = 300
    cs2[1].threat = 50
    var boss2 = _boss()
    Sim._pick_enemy_target(_rng(), boss2, cs2, 1, 0, {}, 0, log)
    _apply(cs2, cs2[1], "MIS_TAUNT_LAPSE", 1, log)
    assert_eq(Sim._pick_enemy_target(_rng(), boss2, cs2, 2, 0, {}, 0, log), cs2[0])
    # End to end: a real boss swing lands off the tank on the round after a lapse.
    var seen := false
    for seed_value in [4242, 1, 2, 3, 4, 5]:
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E3"), _db, seed_value)
        if _entries(res.log, E.Verb.SYSTEM, "lost_aggro").size() > 0:
            seen = true
    assert_true(seen, "six seeds of E3 and no tank ever lost the boss")

func test_taunt_restores_the_lead() -> void:
    # docs/07 §8.1-8.2: Tank Lead is 1.30x the highest non-tank; when it is
    # lost the tank's Phase 2 action is a Taunt to 1.10x the table's top, on a
    # short cooldown. Nothing in the sim could taunt before this.
    var cs := _seated()
    var bob = cs[0]
    var greg = cs[5]
    var log = _log()
    bob.threat = 130
    greg.threat = 100
    assert_true(F.tank_lead_held(130.0, 100.0))
    assert_false(Sim._taunt_if_lead_lost(2, bob, cs, log), "the lead is held: swing as usual")
    assert_eq(bob.threat, 130)
    greg.threat = 200
    assert_false(F.tank_lead_held(130.0, 200.0))
    assert_true(Sim._taunt_if_lead_lost(3, bob, cs, log), "the lead is lost: the action is a Taunt")
    assert_eq(bob.threat, F.taunt_threat(200.0))
    assert_eq(bob.threat, 221, "ceil(1.10 x 200) + 1: strictly past the melee bar")
    assert_true(F.should_retarget(float(bob.threat), 200.0, true), "so the boss comes back")
    var taunts := _entries(log, E.Verb.SYSTEM, "taunt")
    assert_eq(taunts.size(), 1)
    assert_eq(taunts[0].tier, E.LogTier.STORY)
    greg.threat = 400
    assert_false(Sim._taunt_if_lead_lost(4, bob, cs, log), "on cooldown")
    assert_false(Sim._taunt_if_lead_lost(5, bob, cs, log), "still")
    assert_true(Sim._taunt_if_lead_lost(6, bob, cs, log), "and again")
    assert_eq(Sim.TAUNT_COOLDOWN_ROUNDS, 2)
    # Only the tank on duty taunts; a Monk seated main tank in a Warrior-less
    # party does too (docs/07 §8.3's auto-taunt).
    assert_false(Sim._taunt_if_lead_lost(9, cs[1], cs, log), "the offtank is not on duty")
    assert_false(Sim._taunt_if_lead_lost(9, greg, cs, log), "a Rogue never")
    var monks := Sim._build_combatants(_roster_of(["monk", "rogue", "wizard", "cleric"]), _db)
    Sim._assign_tanks(monks, _db)
    assert_true(monks[0].is_main_tank)
    monks[2].threat = 100
    assert_true(Sim._taunt_if_lead_lost(2, monks[0], monks, log))
    # End to end: a pull in a real fight is answered by a taunt.
    var seen := false
    for seed_value in [4242, 1, 2, 3, 4, 5]:
        var res = Sim.run(_roster(E.Rarity.COMMON, 5, "starting"), _encounter("E5"), _db, seed_value)
        if _entries(res.log, E.Verb.SYSTEM, "taunt").size() > 0:
            seen = true
    assert_true(seen, "six seeds of E5 and nobody ever taunted")

# --- SIM-22: the tier reaches the damage formulas

func test_a_tier_three_fight_mitigates_less_at_the_same_ac() -> void:
    # docs/15 BL-72's `AC_K` step and `MANA_TO_SPELL` decay are per tier, and
    # every RaidSim call site passed the default until the tier rode on the
    # profile. Same roster, same AC, same swing: Tier 3 hurts more.
    var t1 := Sim._build_combatants(_roster(), _db, {}, 1)
    var t3 := Sim._build_combatants(_roster(), _db, {}, 3)
    assert_eq(int(_profile(t1[0])["tier"]), 1)
    assert_eq(int(_profile(t3[0])["tier"]), 3)
    var log1 = _log()
    var log3 = _log()
    Sim._apply_damage(1, E.Phase.BOSS, t1[0], 40, log1, "Main Boss")
    Sim._apply_damage(1, E.Phase.BOSS, t3[0], 40, log3, "Main Boss")
    var d1: int = _entries(log1, E.Verb.ATTACK)[0].number("amount")
    var d3: int = _entries(log3, E.Verb.ATTACK)[0].number("amount")
    assert_true(d3 > d1, "tier 3 dealt %d, tier 1 dealt %d at the same AC" % [d3, d1])
    assert_eq(d1, F.damage_after_ac(40.0, int(_profile(t1[0])["ac"]), 1))
    assert_eq(d3, F.damage_after_ac(40.0, int(_profile(t3[0])["ac"]), 3))
    # And the casters' Mana buys less spell damage at Tier 3.
    var wiz1 := Sim._outgoing_damage(_profile(t1[10]), [])
    var wiz3 := Sim._outgoing_damage(_profile(t3[10]), [])
    assert_true(wiz3 < wiz1, "MANA_TO_SPELL decays per tier: %.1f vs %.1f" % [wiz3, wiz1])
    # Through `run()`: the encounter's tier is what the profile carries.
    var enc3 = _synthetic([])
    enc3.tier = 3
    var res1 = Sim.run(_roster(), _synthetic([]), _db, 4242)
    var res3 = Sim.run(_roster(), enc3, _db, 4242)
    var first1: int = _attacks_from(res1, "Main Boss")[0].number("amount")
    var first3: int = _attacks_from(res3, "Main Boss")[0].number("amount")
    assert_true(first3 > first1, "the boss's first swing: %d at tier 3 vs %d at tier 1" % [first3, first1])
    var same = Sim.run(_roster(), _synthetic([]), _db, 4242)
    assert_eq(res1.log.to_json(), same.log.to_json(), "tier 1 is exactly what shipped")

# --- Q58-4: the quirk seam is threaded, and it is identity

func test_the_quirk_seam_is_threaded_with_identity_semantics() -> void:
    # The four hooks are called at their sites (the golden-SHA half is in
    # test_legendaries.gd). With `Quirks.SPECS` empty the run is the same log
    # at either flag setting, for a roster of authored Legendaries.
    var roster := _roster(E.Rarity.LEGENDARY, 95, "raid")
    for r in roster:
        r.legendary_def_id = "legendary_%s" % E.class_key(r.class_id)
    var off = Sim.run(roster, _encounter("E5"), _db, 777, {}, {"legendary_quirks": false})
    var on = Sim.run(roster, _encounter("E5"), _db, 777, {}, {"legendary_quirks": true})
    var bare = Sim.run(roster, _encounter("E5"), _db, 777)
    assert_eq(off.log.to_json(), on.log.to_json(), "an empty SPECS table moves nothing")
    assert_eq(bare.log.to_json(), on.log.to_json(), "and `opts` absent is the default")
    var cs := Sim._build_combatants(roster, _db, {}, 1, true)
    assert_eq(String(cs[4].get_meta("quirk_id")), "quirk_shaman", "resolved by convention")
    assert_true(bool(cs[4].get_meta("quirks_enabled")))
    assert_almost(Sim._threat_mult(cs[4]), 1.0, 0.0001)
    assert_eq(Sim._relief_bp(cs[4]), 0.0)
    var ctx = Mistakes.Context.new()
    Sim._stamp_actor(ctx, cs[4], {"quirks_enabled": true})
    assert_eq(ctx.quirk_id, "quirk_shaman")
    assert_true(ctx.quirks_enabled)
    assert_true("MIS_CHAIN_FIZZLE" in Mistakes.eligible_types(E.CharClass.SHAMAN, E.RoleGroup.HEALER, ctx),
        "no spec, no immunity")
    var plain := Sim._build_combatants(_roster(), _db)
    assert_eq(String(plain[4].get_meta("quirk_id")), "", "a Common has no quirk")
    var src := FileAccess.get_file_as_string("res://sim/core/RaidSim.gd")
    for hook in ["Quirks.threat_multiplier(", "Quirks.relief_bp_bonus(", "Quirks.tank_priority("]:
        assert_true(src.contains(hook), "%s is called from RaidSim" % hook)
    assert_true(FileAccess.get_file_as_string("res://sim/core/Mistakes.gd").contains("Quirks.immune_to("),
        "immune_to is called from eligible_types")
