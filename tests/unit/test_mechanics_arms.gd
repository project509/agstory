extends "res://tests/TestCase.gd"
## docs/10 §10's mechanic vocabulary as a CONTRACT on sim/core/RaidSim.gd.
##
## Three things live here, and each one reads the fight through the EVENT LOG
## rather than through the combatants, because the log is the only output the
## sim has (docs/07 §10) and the goldens are built on it:
##
##   THE STATIC DISPATCH GUARD. `_apply_scheduled_mechanics` is a `match` with
##   one arm per `Enums.Mechanic` entry. test_raid_sim.gd probes the same fact
##   behaviourally (run with and without each mechanic, compare logs); this one
##   reads the source, so the two can never both be fooled the same way — an arm
##   whose params default to off leaves the probe log identical and passes the
##   behaviour probe, and a behaviour that lands outside the match passes this
##   one. `MECHANICS_WITHOUT_AN_ARM` is the explicit allow-list: it is EMPTY,
##   because all twelve have arms, and it stays here so a thirteenth enum entry
##   without an arm turns this file red rather than silently doing nothing.
##
##   M11 FRONTAL CLEAVE and M12 ESCALATING SWING in the log, on a synthetic
##   encounter configured with each, and their ABSENCE on the same encounter
##   without them — a mechanic nobody configured leaves no trace.
##
## The audit rows (`m5-m11-frontal-cleave`, `m5-m12-escalating-swing`,
## `m5-mechanic-dispatch-guard`) were written against a tree with three arms;
## the arms landed with the mech-arms slice (build/plan/report-mech-arms.md) and
## these tests are the second, independent hold on them.

const Sim = preload("res://sim/core/RaidSim.gd")
const R = preload("res://sim/model/Raider.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const F = preload("res://sim/core/Formulas.gd")
const E = preload("res://sim/model/Enums.gd")
const Encounter = preload("res://sim/model/Encounter.gd")
const Consumables = preload("res://sim/core/Consumables.gd")

const RAIDSIM_PATH := "res://sim/core/RaidSim.gd"

## docs/10 §10 mechanics with NO dispatch arm in `_apply_scheduled_mechanics`.
## Empty. Delete a key from here in the same commit that gives it an arm; add
## one only when an enum entry lands before its behaviour does, so the gap is
## documented rather than hidden.
const MECHANICS_WITHOUT_AN_ARM: Array = []

## docs/10 §5.3's benchmark twelve, the same shape test_raid_sim.gd fights with.
const BENCHMARK := ["warrior", "warrior", "cleric", "druid", "shaman", "rogue",
                    "rogue", "monk", "mage", "wizard", "wizard", "bard"]

## E5's stat block with the mechanics list replaced — a test fixture, not a
## content proposal (test_raid_sim.gd::_synthetic is the original).
const BOSS_RAW := 37

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

# ---------------------------------------------------------------- fixtures

func _raider(class_key: String, idx: int):
    var r = R.new()
    r.id = "%s-%d" % [class_key, idx]
    r.display_name = "%s%d" % [class_key.capitalize(), idx]
    r.class_id = E.class_from_key(class_key)
    r.rarity = E.Rarity.LEGENDARY
    r.morale = 95
    for boss in range(1, 6):
        for it in _db.raid_drops(class_key, boss):
            r.equip(_db, it)
    return r

func _roster() -> Array:
    var out := []
    for i in BENCHMARK.size():
        out.append(_raider(BENCHMARK[i], i))
    return out

func _synthetic(mechanics: Array):
    return Encounter.from_dict({
        "id": "probe", "display_name": "Probe", "tier": 1, "slot": "E5",
        "stars": maxi(1, mechanics.size()), "kind": "main_boss",
        "party_size": 12, "tanks_required": 2,
        "enemies": [{"name": "Main Boss", "count": 1, "hp": 6200, "raw_swing": BOSS_RAW,
            "swings_per_round": 2, "threat_rule": "standard"}],
        "mechanics": mechanics,
        "loot_slots": ["capstone"], "target_rounds": 22, "enrage_round": 31,
        "comedy_line": "A probe encounter; see tests/unit/test_mechanics_arms.gd.",
    }, [])

func _mechanic_entries(res, key: String) -> Array:
    var out: Array = []
    for e in res.log.entries:
        if e.verb == E.Verb.MECHANIC and String(e.params.get("mechanic", "")) == key:
            out.append(e)
    return out

func _attacks_from(res, source: String) -> Array:
    var out: Array = []
    for e in res.log.entries:
        if e.verb == E.Verb.ATTACK and e.actor_name == source:
            out.append(e)
    return out

func _by_raider_id(res) -> Dictionary:
    var out := {}
    for c in res.survivors + res.casualties:
        out[c.raider.id] = c
    return out

# --------------------------------------------------- the static dispatch guard

## The body of `_apply_scheduled_mechanics`, from its `static func` line to the
## next top-level `static func`.
func _dispatch_body() -> String:
    var f := FileAccess.open(RAIDSIM_PATH, FileAccess.READ)
    assert_ne(f, null, "RaidSim.gd must be readable for the source guard")
    var src: String = f.get_as_text()
    var start := src.find("static func _apply_scheduled_mechanics(")
    assert_true(start >= 0, "_apply_scheduled_mechanics has been renamed or removed")
    var end := src.find("\nstatic func ", start + 1)
    return src.substr(start, (end if end > 0 else src.length()) - start)

func test_every_mechanic_in_the_vocabulary_has_a_literal_dispatch_arm() -> void:
    var body := _dispatch_body()
    assert_true(body.contains("match spec.mechanic:"),
        "the dispatch is a match on the spec's mechanic; anything else needs a new guard")
    var names: Array = E.Mechanic.keys()
    assert_eq(names.size(), E.MECHANIC_KEYS.size(), "one key per enum entry")
    var missing: Array = []
    for i in names.size():
        if not body.contains("Enums.Mechanic.%s" % names[i]):
            missing.append(E.mechanic_key(i))
    assert_eq(missing, MECHANICS_WITHOUT_AN_ARM,
        "mechanics with no dispatch arm are %s, the allow-list says %s — write the arm "
        % [str(missing), str(MECHANICS_WITHOUT_AN_ARM)]
        + "or add the key to MECHANICS_WITHOUT_AN_ARM in this file")

func test_a_thirteenth_mechanic_would_name_itself_as_a_gap() -> void:
    # The default arm is what turns "no arm" into a DEBUG-tier line instead of
    # silence (docs/10 §6: a star that buys nothing is a lie on the card).
    var body := _dispatch_body()
    assert_true(body.contains("_:"), "the match needs a default arm")
    assert_true(body.contains("mechanic_unimplemented"),
        "the default arm must note the gap by its template id")

func test_the_allow_list_only_names_real_mechanics() -> void:
    for key in MECHANICS_WITHOUT_AN_ARM:
        assert_true(E.mechanic_from_key(String(key)) >= 0,
            "%s is not a docs/10 §10 mechanic key" % key)

# ---------------------------------------------- M11 Frontal Cleave in the log

const CLEAVE := {"id": "m11", "params": {"damage": 26}}

func test_m11_cleaves_every_living_melee_raider_every_round() -> void:
    # docs/10 §10 M11: "`X` damage to all melee-positioned raiders each round".
    # "In front of the boss" is the melee predicate (Consumables.MELEE_CLASSES),
    # tank included (RaidSim.FRONTAL_CLEAVE_INCLUDES_TANK, q-W5-SIM.md).
    var res = Sim.run(_roster(), _synthetic([CLEAVE]), _db, 4242)
    var by_id := _by_raider_id(res)
    var melee_ids := {}
    for rid in by_id.keys():
        if Consumables.is_melee_class(int(by_id[rid].get_meta("profile")["class_id"])):
            melee_ids[rid] = true
    assert_true(melee_ids.size() >= 4, "the benchmark twelve field at least four melee")
    var announced := _mechanic_entries(res, "m11")
    assert_eq(announced.size(), res.rounds,
        "one cleave line per round: %d lines over %d rounds" % [announced.size(), res.rounds])
    var struck_by_round := {}
    for e in _attacks_from(res, "the cleave"):
        assert_true(melee_ids.has(e.target_id),
            "%s is not melee and was cleaved on round %d" % [e.target_id, e.round_no])
        if not struck_by_round.has(e.round_no):
            struck_by_round[e.round_no] = {}
        struck_by_round[e.round_no][e.target_id] = true
    # Round 1: nobody is down yet, so every melee raider is in front of it.
    assert_eq(struck_by_round.get(1, {}).size(), melee_ids.size(),
        "round 1 must cleave all %d melee raiders" % melee_ids.size())
    assert_true(Sim.FRONTAL_CLEAVE_INCLUDES_TANK, "the tank is melee-positioned (docs/10 M11 names the Warrior)")

func test_m11_leaves_no_trace_on_an_encounter_that_does_not_carry_it() -> void:
    var res = Sim.run(_roster(), _synthetic([]), _db, 4242)
    assert_eq(_mechanic_entries(res, "m11").size(), 0)
    assert_eq(_attacks_from(res, "the cleave").size(), 0)
    # And "byte-identical to before" for the real content is tests/unit/
    # test_golden.gd's job; here the bare fight is at least a pure replay.
    var again = Sim.run(_roster(), _synthetic([]), _db, 4242)
    assert_eq(res.log.to_json(), again.log.to_json())

# ------------------------------------------- M12 Escalating Swing in the log

const ESCALATE := {"id": "m12", "params": {"increment": 3, "from_round": 1}}

func test_m12_round_ten_swings_exactly_nine_increments_harder_than_round_one() -> void:
    # docs/10 §10 M12: "Boss raw swing +`X` per round, no cap". The tick lands
    # at Round Open, so round R swings BOSS_RAW + R x increment before armour;
    # asserted from the log against the target's own AC, on the audit row's
    # exact acceptance: round 10 exceeds round 1 by 9 x increment before AC.
    var res = Sim.run(_roster(), _synthetic([ESCALATE]), _db, 4242)
    assert_true(res.rounds >= 10, "the probe fight must reach round 10 (%d)" % res.rounds)
    var inc: int = int(ESCALATE["params"]["increment"])
    var by_id := _by_raider_id(res)
    var seen := {}
    for e in _attacks_from(res, "Main Boss"):
        if not by_id.has(e.target_id):
            continue
        var ac: int = int(by_id[e.target_id].get_meta("profile")["ac"])
        assert_eq(e.number("amount"), F.damage_after_ac(float(BOSS_RAW + e.round_no * inc), ac),
            "round %d swing %d is not BOSS_RAW + %d x %d after AC %d"
            % [e.round_no, e.number("amount"), e.round_no, inc, ac])
        seen[e.round_no] = {"ac": ac, "amount": e.number("amount")}
    assert_true(seen.has(1) and seen.has(10), "swings on rounds 1 and 10 are needed")
    var raw_1: int = BOSS_RAW + 1 * inc
    var raw_10: int = BOSS_RAW + 10 * inc
    assert_eq(raw_10 - raw_1, 9 * inc, "nine increments between round 1 and round 10")
    assert_eq(int(seen[10]["amount"]), F.damage_after_ac(float(raw_10), int(seen[10]["ac"])))

func test_m12_announces_on_its_cadence_not_every_round() -> void:
    # "No cap" is honoured; the LINE is rationed (RaidSim.ESCALATION_ANNOUNCE_EVERY)
    # so a twenty-round fight is not twenty identical story beats.
    var res = Sim.run(_roster(), _synthetic([ESCALATE]), _db, 4242)
    var rounds_announced: Array = []
    for e in _mechanic_entries(res, "m12"):
        rounds_announced.append(e.round_no)
    assert_true(rounds_announced.has(1), "the first tick is announced")
    for r in rounds_announced:
        assert_true(r == 1 or r % Sim.ESCALATION_ANNOUNCE_EVERY == 0,
            "round %d announced off the cadence" % r)
    assert_true(rounds_announced.size() < res.rounds, "not every round is a line")
    assert_true(res.rounds <= Sim.ROUND_CAP, "docs/07 §7.3: no cap on the swing, a cap on the fight")

func test_m12_leaves_no_trace_on_an_encounter_that_does_not_carry_it() -> void:
    var res = Sim.run(_roster(), _synthetic([]), _db, 4242)
    assert_eq(_mechanic_entries(res, "m12").size(), 0)
    var by_id := _by_raider_id(res)
    for e in _attacks_from(res, "Main Boss"):
        if not by_id.has(e.target_id):
            continue
        var ac: int = int(by_id[e.target_id].get_meta("profile")["ac"])
        assert_eq(e.number("amount"), F.damage_after_ac(float(BOSS_RAW), ac),
            "round %d: the swing moved with no m12 configured" % e.round_no)
