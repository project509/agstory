extends "res://tests/TestCase.gd"
## Golden tests: the simulation must not change by accident.
##
## Every other test asserts a property. These assert the *whole outcome* of four
## fixed fights, so any behavioural change anywhere in the sim shows up here even
## when no property test notices. That is the point — the dangerous drift is the
## kind nobody wrote a test for.
##
## Each golden stores three things:
##   the summary        (outcome, rounds, mistakes, damage) — reads at a glance
##   the story lines    (what actually happened) — a reviewable diff
##   a SHA-256 of the complete event stream — catches drift the story hides
##
## WHEN ONE OF THESE FAILS, read the diff before touching anything. If the change
## was intended, regenerate deliberately:
##
##     godot --headless --path . --script res://tools/write_goldens.gd
##
## Regenerating to make a red test green, without reading what moved, defeats the
## entire mechanism.

const Scenarios = preload("res://tests/golden/Scenarios.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Sim = preload("res://sim/core/RaidSim.gd")
const E = preload("res://sim/model/Enums.gd")

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

func _load_golden(name: String) -> Dictionary:
    var path := Scenarios.golden_path(name)
    if not FileAccess.file_exists(path):
        fail("missing golden %s — run tools/write_goldens.gd" % path)
        return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if parsed == null:
        fail("golden %s is not valid JSON" % path)
        return {}
    return parsed

func _run(name: String):
    var spec: Dictionary = Scenarios.SCENARIOS[name]
    var roster := Scenarios.build_roster(spec, _db)
    var enc = _db.encounter_at_slot(String(spec["encounter"]))
    return Sim.run(roster, enc, _db, int(spec["seed"]))

# ---------------------------------------------------------------- the goldens

func test_every_scenario_has_a_golden_file() -> void:
    for name in Scenarios.names():
        assert_true(FileAccess.file_exists(Scenarios.golden_path(name)),
            "no golden for scenario '%s'" % name)

func test_summaries_match() -> void:
    for name in Scenarios.names():
        var g := _load_golden(name)
        if g.is_empty():
            continue
        var res = _run(name)
        assert_eq(res.outcome_key(), String(g["outcome"]), "%s outcome" % name)
        assert_eq(res.rounds, int(g["rounds"]), "%s rounds" % name)
        assert_eq(res.mistake_count, int(g["mistakes"]), "%s mistakes" % name)
        assert_eq(res.damage_dealt, int(g["damage_dealt"]), "%s damage" % name)
        assert_eq(res.healing_done, int(g["healing_done"]), "%s healing" % name)
        assert_eq(res.survivors.size(), int(g["survivors"]), "%s survivors" % name)

func test_full_event_streams_are_byte_identical() -> void:
    # The strict check. A single changed number anywhere moves this hash.
    for name in Scenarios.names():
        var g := _load_golden(name)
        if g.is_empty():
            continue
        var res = _run(name)
        assert_eq(res.log.size(), int(g["event_count"]), "%s event count" % name)
        assert_eq(res.log.to_json().sha256_text(), String(g["full_log_sha256"]),
            "%s: the event stream changed. Read the story diff, then regenerate "
            % name + "with tools/write_goldens.gd if the change was intended.")

func test_story_lines_match_line_for_line() -> void:
    # The readable check. When the hash moves, this says what moved.
    for name in Scenarios.names():
        var g := _load_golden(name)
        if g.is_empty():
            continue
        var res = _run(name)
        var expected: Array = g["story"]
        var actual := []
        for e in res.log.at_tier(E.LogTier.STORY):
            actual.append(e.describe())
        assert_eq(actual.size(), expected.size(), "%s story length" % name)
        for i in mini(actual.size(), expected.size()):
            assert_eq(actual[i], String(expected[i]), "%s story line %d" % [name, i])

# ---------------------------------------------------------------- sanity

func test_scenarios_span_the_real_range() -> void:
    # A golden set that only covers the middle proves very little.
    var outcomes := {}
    var mistake_counts := []
    for name in Scenarios.names():
        var g := _load_golden(name)
        if g.is_empty():
            continue
        outcomes[String(g["outcome"])] = true
        mistake_counts.append(int(g["mistakes"]))
    assert_true(outcomes.has("victory"), "at least one scenario must be winnable")
    assert_true(outcomes.size() >= 2, "the goldens must cover more than one outcome")
    mistake_counts.sort()
    assert_true(mistake_counts[-1] > mistake_counts[0] * 5,
        "the set should span competent and catastrophic rosters")

func test_the_best_case_roster_actually_clears_the_tier_boss() -> void:
    # If Legendaries in full raid gear at 95 morale cannot kill the Tier 1 boss,
    # the tuning is wrong regardless of what any other test says.
    var g := _load_golden("e5_legendaries_raid")
    assert_eq(String(g["outcome"]), "victory")
    # This scenario wears Boss 5 capstones, so it is the FARM state, not a first
    # clear — it must beat 22 rounds, because the tier gets easier to re-run once
    # you own its drops. The 22-round target belongs to the scenario below.
    assert_true(int(g["rounds"]) < 22,
        "farm gear should beat the 22-round first-clear target; got %d"
        % int(g["rounds"]))
    assert_true(int(g["mistakes"]) < 10,
        "a Legendary raid should barely fumble — got %d" % int(g["mistakes"]))

func test_the_first_clear_lands_on_the_canon_fight_length() -> void:
    # docs/08 §9.2: "the boss is fought in the gear the boss before it dropped."
    # Boss 5's DPS-at-attempt row is therefore After Boss 4 (325.0), NOT After
    # Boss 5 (329.0), and the doc sizes the fight for 22 rounds at that gear.
    #
    # This is the assertion that caught a real measurement error: the sweep used
    # to equip Boss 5 capstones for this fight, reported ~17 rounds, and that gap
    # was logged as a ~28% DPS overshoot to be tuned out. Nothing was wrong with
    # the tuning — the loadout was impossible. Measured at the gear canon
    # specifies, the fight lands on 22. Do NOT widen this band to go green: a
    # drift here means the damage model moved away from docs/08 §9.
    var g := _load_golden("e5_first_clear")
    assert_eq(String(g["outcome"]), "victory",
        "a Rare roster in Boss 1-4 gear is the intended Boss 5 first-clear raid")
    assert_in_range(int(g["rounds"]), 19, 25,
        "docs/08 §9.2 sizes Boss 5 for 22 rounds at Boss-1-4 gear; got %d"
        % int(g["rounds"]))

func test_the_worst_case_roster_does_not_clear() -> void:
    var g := _load_golden("e5_miserable_commons")
    assert_ne(String(g["outcome"]), "victory",
        "morale 5 Commons in starting gear must not beat the tier boss")

func test_the_worst_case_golden_shows_a_cascade_and_names_the_cause() -> void:
    # W6-SIM-CASCADE (SIM-05, CRITIC-C12): the miserable-Commons wipe is the
    # scenario docs/07 §6 exists for. Its golden story must carry at least one
    # knock-on edge and the sim's one-line cause, and the run behind it must
    # report `wipe_cause` — the two facts Results reads (`caused_by` for the
    # indented chain, `wipe_cause` for the headline sentence).
    var g := _load_golden("e5_miserable_commons")
    var edges := 0
    var cause_lines := 0
    for line in g["story"]:
        if String(line).contains("(after ") and String(line).contains(", depth "):
            edges += 1
        if String(line).contains("It traces back to "):
            cause_lines += 1
    assert_true(edges > 0, "no mistake in the worst-case golden names its parent")
    assert_eq(cause_lines, 1, "the story names the cause exactly once, at the end")
    assert_true(String(g["story"][g["story"].size() - 1]).contains("It traces back to "),
        "the cause is the last line of the story")
    var res = _run("e5_miserable_commons")
    assert_false(res.wipe_cause.is_empty(), "the run reports why it was lost")
    for key in ["actor_id", "mistake_type", "round", "entry_seq"]:
        assert_true(res.wipe_cause.has(key), "wipe_cause missing %s" % key)
    var named := 0
    for e in res.log.mistakes():
        if not String(e.mistake.get("caused_by", "")).is_empty():
            named += 1
    assert_true(named > 0, "no entry in the run carries caused_by")

func test_raid_entry_gear_cannot_contain_a_boss_5_drop() -> void:
    # The whole point of the raid_entry tier. If a Boss 5 capstone ever leaks
    # back into it, every first-clear measurement silently becomes a farm-run
    # measurement again — which is exactly the error this tier was added to fix,
    # and it is invisible in the round counts until someone re-derives them.
    var spec := {"rarity": E.Rarity.RARE, "morale": 55, "gear": "raid_entry"}
    var roster := Scenarios.build_roster(spec, _db)
    assert_true(roster.size() > 0, "raid_entry roster must not be empty")
    var boss5_ids := {}
    for class_key in Scenarios.BENCHMARK:
        for it in _db.raid_drops(class_key, 5):
            boss5_ids[it.id] = true
    assert_true(boss5_ids.size() > 0, "Boss 5 must actually drop something")
    for r in roster:
        for item_id in r.equipment.values():
            assert_false(boss5_ids.has(item_id),
                "raid_entry roster wears Boss 5 drop '%s' — that is gear you can "
                % item_id + "only own after killing the boss you are fighting")

func test_goldens_document_why_each_scenario_exists() -> void:
    for name in Scenarios.names():
        var g := _load_golden(name)
        if g.is_empty():
            continue
        assert_true(String(g["why"]).length() > 20,
            "%s should explain what it is protecting" % name)
