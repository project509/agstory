extends "res://tests/TestCase.gd"
## The comedy corpus, as the simulation actually uses it.
##
## `sim/content/MistakeLines.gd` validates its own SHAPE — coverage, budget,
## uniqueness, resolvable tokens, one sentence, no mechanic-explaining — and it
## did all of that against a corpus nothing called. 228 authored lines, a
## deterministic picker, a shuffle bag, and no joke had ever reached a log.
##
## So these tests are deliberately end-to-end: they run real raids and read what
## came out. docs/16 R-3 names "the comedy does not land" the project's top risk
## and a human owns FUNNY (build/plan/q-comedy.md); what a machine can own is
## "there is a line, it names the right person, and it is not the same line
## twice", and that is what is asserted here.

const Sim = preload("res://sim/core/RaidSim.gd")
const Lines = preload("res://sim/content/MistakeLines.gd")
const Mistakes = preload("res://sim/core/Mistakes.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const R = preload("res://sim/model/Raider.gd")
const E = preload("res://sim/model/Enums.gd")

var _db = null
var _pool = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    if _pool == null:
        _pool = Lines.load_from()

## docs/10 §5.3's benchmark twelve, the roster every other sim test measures.
const BENCHMARK := ["warrior", "warrior", "cleric", "druid", "shaman", "rogue",
                    "rogue", "monk", "mage", "wizard", "wizard", "bard"]

## Canon's own names where it gave them (docs/03 §5.6 forbids inventing more),
## so the `{actor}` substitution is visible in the assertions below.
const NAMES := ["Bob", "Dave", "Cindy", "Fern", "Natsuna", "Greg",
                "Pip", "Kel", "Steve", "Wanda", "Zed", "Lyra"]

func _roster(rarity: int = E.Rarity.COMMON, morale: int = 25) -> Array:
    var out := []
    for i in BENCHMARK.size():
        var r = R.new()
        r.id = "g%02d" % i
        r.display_name = NAMES[i]
        r.class_id = E.class_from_key(BENCHMARK[i])
        r.rarity = rarity
        r.morale = morale
        var cd = _db.class_by_key(BENCHMARK[i])
        for slot in [E.Slot.HEAD, E.Slot.CHEST, E.Slot.LEGS, E.Slot.FEET,
                     E.Slot.MAIN_HAND]:
            var fam: int = cd.family_for_slot(slot)
            if fam < 0:
                continue
            for candidate in _db.items_for(fam, slot):
                if candidate.source == "adventure":
                    r.equip(_db, candidate)
                    break
        out.append(r)
    return out

## A fight with plenty to laugh at.
func _run(seed_value: int = 5150, slot: String = "E5"):
    return Sim.run(_roster(), _db.encounter_at_slot(slot), _db, seed_value)

# ---------------------------------------------------------------- the corpus

func test_the_corpus_loads_and_validates() -> void:
    # Its own validators, run once here so a corpus problem fails as a comedy
    # test rather than as a mysterious empty string in a raid log.
    assert_true(_pool.is_valid(), _pool.error_report())
    assert_eq(_pool.types.size(), Mistakes.TYPES.size(),
        "docs/14 §5.4 assertion 7: every type in the taxonomy has lines")

# ------------------------------------------------- the sim actually uses it

func test_a_real_raid_produces_a_joke_for_every_mistake() -> void:
    # The whole point. Before this wiring `ev.log_line` was always "" and every
    # render site treated that as "no line", so the corpus was dead weight.
    var res = _run()
    var mistakes: Array = res.log.mistakes()
    assert_true(mistakes.size() > 0, "E5 at morale 25 must go wrong somewhere")
    for m in mistakes:
        assert_false(m.joke().is_empty(),
            "%s's %s came out with no line at all"
            % [m.actor_name, String(m.mistake["type"])])
        assert_false(String(m.mistake["template"]).is_empty(),
            "docs/07 §5.1: the entry carries WHICH variant was drawn")

func test_no_line_reaches_the_log_with_an_unresolved_placeholder() -> void:
    # `{actor}` is the only token the corpus is allowed (MistakeLines.ALLOWED_TOKENS)
    # and a `{target}` slipping in would be a crash waiting for one specific
    # fight. This is the runtime half of that guarantee: whatever the picker
    # drew, no braces survive into the log.
    for seed_value in [1, 5150, 31337, 4242]:
        for slot in ["E1", "E3", "E5"]:
            var res = _run(seed_value, slot)
            for m in res.log.mistakes():
                var quip: String = m.joke()
                assert_false(quip.contains("{"),
                    "unresolved placeholder in %s: %s" % [m.actor_name, quip])
                assert_false(quip.contains("}"), quip)

func test_the_line_names_the_raider_who_made_the_mistake() -> void:
    # docs/07 §10.3 rule 2, end to end: the corpus requires at least one
    # `{actor}` per line, so every rendered line has to contain that raider's
    # display name and nobody else's.
    var res = _run()
    var names := {}
    for n in NAMES:
        names[n] = true
    for m in res.log.mistakes():
        assert_true(m.joke().contains(m.actor_name),
            "'%s' never names %s" % [m.joke(), m.actor_name])
        for other in names.keys():
            if String(other) == m.actor_name:
                continue
            assert_false(m.joke().contains(String(other)),
                "'%s' names %s as well as %s" % [m.joke(), other, m.actor_name])

func test_the_joke_reaches_the_story_transcript() -> void:
    # docs/07 §10.3's sample block puts the joke under its header, and the
    # golden `story` arrays are the only cheap review surface the corpus gets.
    var res = _run()
    var story: String = res.log.transcript(E.LogTier.STORY)
    var first: String = res.log.mistakes()[0].joke()
    assert_true(story.contains(first),
        "the drawn line has to be visible in the Story tier: %s" % first)

# ---------------------------------------------------------------- the bag

func test_a_bad_raid_does_not_print_the_same_joke_twice_running() -> void:
    # docs/07 §5.5 already stops a TYPE repeating in consecutive rounds; this is
    # the half the player notices — the taxonomy line is a header, the joke is
    # the sentence being read. The shuffle bag deals each type's deck before it
    # reshuffles, and never puts the same id back-to-back across a wrap.
    var res = Sim.run(_roster(E.Rarity.COMMON, 5), _db.encounter_at_slot("E5"), _db, 77)
    var last := {}
    var checked := 0
    for m in res.log.mistakes():
        var type_id: String = String(m.mistake["type"])
        var variant: String = String(m.mistake["template"])
        if variant.is_empty():
            continue
        if last.has(type_id):
            assert_ne(variant, String(last[type_id]),
                "%s drew %s twice in a row" % [type_id, variant])
            checked += 1
        last[type_id] = variant
    assert_true(checked > 3,
        "only %d consecutive pairs to compare; pick a messier fight" % checked)

func test_the_same_seed_draws_the_same_jokes() -> void:
    # The bag takes an Rng derived from the master seed, so the comedy is part
    # of the replay guarantee (docs/14 §8) rather than an afterthought.
    var a = _run(999)
    var b = _run(999)
    var first: Array = []
    var second: Array = []
    for m in a.log.mistakes():
        first.append(m.joke())
    for m in b.log.mistakes():
        second.append(m.joke())
    assert_eq(first, second, "same seed, same jokes")

func test_a_different_seed_draws_different_jokes() -> void:
    var a: Array = []
    var b: Array = []
    for m in _run(1).log.mistakes():
        a.append(m.joke())
    for m in _run(2).log.mistakes():
        b.append(m.joke())
    assert_ne(a, b, "the corpus must not be a fixed sequence")

## A corpus that has nothing to say. `Bag.draw` asks the pool for variants and
## returns `{}` the moment the list is empty, consuming ZERO draws from its rng
## — so a run against this pool draws no jokes at all, and a run against the
## real corpus draws one per mistake. That difference is the whole experiment
## below; it is the only way to vary joke volume without touching the sim.
class _SilentPool extends RefCounted:
    func variants_for(_type_id: String, _severity: int = -1,
            _class_key: String = "") -> Array:
        return []
    func legendary_variants_for(_def_id: String, _type_id: String = "") -> Array:
        return []

func test_drawing_a_line_moves_no_simulation_outcome() -> void:
    # `Rng.derive` is a pure function of the master seed and consumes no draws
    # from the parent stream, which is what lets the comedy be added to a
    # shipped simulation without moving a single number.
    #
    # This used to run `_run()` twice on the SAME seed and compare, which is a
    # replay-determinism test wearing an inertness test's name: it passes
    # whether the bag draws from a derived stream or from the master one, and
    # it contained the literal tautology `assert_eq(res.rounds, res.rounds)`.
    #
    # The real experiment holds the seed fixed and varies the JOKE VOLUME —
    # zero draws against a silent corpus, one per mistake against the real one.
    # If the bag shared the master stream, the quiet run's rolls would all land
    # one draw earlier and the two fights would diverge immediately.
    var real = Sim._lines()      # populate the content cache before borrowing it
    var quiet = null
    Sim._lines_pool = _SilentPool.new()
    # No assertions inside the swap: a failure here must not leave the cache
    # holding a silent corpus for every test that runs after this one.
    quiet = _run(4242)
    Sim._lines_pool = real
    var loud = _run(4242)

    var quiet_jokes := 0
    for m in quiet.log.mistakes():
        if not m.joke().is_empty():
            quiet_jokes += 1
    var loud_jokes := 0
    for m in loud.log.mistakes():
        if not m.joke().is_empty():
            loud_jokes += 1
    assert_eq(quiet_jokes, 0, "the silent corpus still produced lines")
    assert_true(loud_jokes > 3,
        "only %d jokes in the loud run; the two runs barely differ" % loud_jokes)

    assert_eq(quiet.rounds, loud.rounds, "the fight ran a different length")
    assert_eq(quiet.damage_dealt, loud.damage_dealt)
    assert_eq(quiet.healing_done, loud.healing_done)
    assert_eq(quiet.mistake_count, loud.mistake_count)
    assert_eq(quiet.survivors.size(), loud.survivors.size())
    assert_eq(quiet.outcome, loud.outcome)

func test_the_same_seed_replays_exactly() -> void:
    # The determinism half, which the test above used to be doing under the
    # wrong name (docs/14 §8).
    var res = _run()
    var replay = _run()
    assert_eq(res.log.to_json().sha256_text(), replay.log.to_json().sha256_text())

# ---------------------------------------------------------------- coverage

func test_every_type_that_fires_in_a_real_fight_has_something_to_say() -> void:
    # The corpus validates coverage of the TAXONOMY; this checks coverage of
    # what actually happens, which is the set the player will ever read.
    var seen := {}
    for seed_value in range(1, 13):
        for slot in ["E1", "E2", "E3", "E4", "E5"]:
            for m in _run(seed_value, slot).log.mistakes():
                var type_id: String = String(m.mistake["type"])
                if not seen.has(type_id):
                    seen[type_id] = m.joke()
    assert_true(seen.size() >= 8,
        "only %d distinct mistake types fired across the tier" % seen.size())
    for type_id in seen.keys():
        assert_false(String(seen[type_id]).is_empty(),
            "%s fires in play and drew no line" % type_id)
