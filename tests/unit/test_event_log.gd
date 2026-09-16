extends "res://tests/TestCase.gd"
## sim/core/EventLog.gd — the simulation's only output.
##
## Two properties matter more than the rest and most of these tests defend them:
##
##   The sim emits EVERYTHING, always. Verbosity is a display filter over one
##   complete log. If the sim ever emitted differently per tier, the log would
##   become a source of divergence and two players at different settings would
##   be playing different games.
##
##   `sequence` is assigned in exactly one place. Golden files compare this
##   stream, so ordering has to be a property of the code rather than of luck.

const Log = preload("res://sim/core/EventLog.gd")
const C = preload("res://sim/model/Combatant.gd")
const R = preload("res://sim/model/Raider.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const E = preload("res://sim/model/Enums.gd")

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

func _combatant(name: String, class_key: String = "warrior"):
    var r = R.new()
    r.id = "id-%s" % name.to_lower()
    r.display_name = name
    r.class_id = E.class_from_key(class_key)
    return C.create(r, _db, 0)

# ---------------------------------------------------------------- sequencing

func test_sequence_is_monotone_and_gapless() -> void:
    var log = Log.new()
    for i in 20:
        log.emit_system(i, "event %d" % i)
    for i in 20:
        assert_eq(log.entries[i].sequence, i, "sequence must not skip or repeat")

func test_sequence_survives_mixed_emitters() -> void:
    var log = Log.new()
    var bob = _combatant("Bob")
    log.emit_phase(1, E.Phase.ROUND_OPEN)
    log.emit_attack(1, E.Phase.TANKS, bob, "Boss 1", 7, 1575, 168)
    log.emit_mistake(1, E.Phase.AMBIENT_MISTAKE, bob, "MIS_TAUNT_LAPSE",
        "Forgot to Taunt", "moderate")
    log.emit_state_change(1, E.Phase.ROUND_CLOSE, bob, "DOWNED")
    var seqs := []
    for e in log.entries:
        seqs.append(e.sequence)
    assert_eq(seqs, [0, 1, 2, 3])

func test_size_and_round_helpers() -> void:
    var log = Log.new()
    log.emit_system(1, "a")
    log.emit_system(2, "b")
    log.emit_system(2, "c")
    assert_eq(log.size(), 3)
    assert_eq(log.for_round(2).size(), 2)
    assert_eq(log.last_round(), 2)

# ---------------------------------------------------------------- tiers

func test_verbosity_is_a_filter_not_a_different_emission() -> void:
    var log = Log.new()
    var bob = _combatant("Bob")
    log.emit_mistake(4, E.Phase.AMBIENT_MISTAKE, bob, "MIS_AGGRO",
        "Pulled Aggro Off the Tank", "severe")                                    # STORY
    log.emit_attack(4, E.Phase.TANKS, bob, "Boss 1", 7, 1575)                     # PLAY_BY_PLAY
    log.emit_phase(4, E.Phase.BOSS)                                               # NUMBERS

    # One complete log, regardless of what any viewer is set to.
    assert_eq(log.size(), 3, "everything is always emitted")
    assert_eq(log.at_tier(E.LogTier.STORY).size(), 1)
    assert_eq(log.at_tier(E.LogTier.PLAY_BY_PLAY).size(), 2)
    assert_eq(log.at_tier(E.LogTier.NUMBERS).size(), 3)
    assert_eq(log.at_tier(E.LogTier.DEBUG).size(), 3, "Debug shows the lot")

func test_story_tier_keeps_the_beats_of_the_fight() -> void:
    # Story is the post-mortem view: mistakes, deaths, rescues, mechanics, wipe.
    var log = Log.new()
    var greg = _combatant("Greg", "rogue")
    log.emit_attack(5, E.Phase.TANKS, greg, "Boss 1", 12, 1400)          # noise
    log.emit_mistake(5, E.Phase.DPS, greg, "MIS_AGGRO",
        "Pulled Aggro Off the Tank", "severe")
    log.emit_state_change(5, E.Phase.BOSS, greg, "DOWNED")
    log.emit_mechanic(6, E.Phase.ROUND_OPEN, E.Mechanic.ADD_SPAWNS, "An add joins the fight.")
    log.emit_system(10, "WIPE.")

    var story: Array = log.at_tier(E.LogTier.STORY)
    assert_eq(story.size(), 4, "the attack is noise; everything else is a beat")
    var verbs := []
    for e in story:
        verbs.append(e.verb)
    assert_true(E.Verb.MISTAKE in verbs)
    assert_true(E.Verb.STATE_CHANGE in verbs)
    assert_true(E.Verb.MECHANIC in verbs)
    assert_true(E.Verb.SYSTEM in verbs)

func test_mistakes_survive_every_filter() -> void:
    # They are what the player came for; no verbosity setting may hide them.
    var log = Log.new()
    log.emit_mistake(3, E.Phase.DPS, _combatant("Steve", "mage"), "MIS_BROKE_CC",
        "AoE'd the Sleeping Add", "severe")
    for tier in [E.LogTier.STORY, E.LogTier.PLAY_BY_PLAY, E.LogTier.NUMBERS, E.LogTier.DEBUG]:
        assert_eq(log.at_tier(tier).size(), 1, "mistakes visible at every tier")

# ---------------------------------------------------------------- content

func test_attack_carries_its_numbers() -> void:
    var log = Log.new()
    var bob = _combatant("Bob")
    var e = log.emit_attack(4, E.Phase.TANKS, bob, "Boss 1", 7, 1575, 168)
    assert_eq(e.number("amount"), 7)
    assert_eq(e.number("hp_after"), 1575)
    assert_eq(e.number("threat_after"), 168)
    assert_eq(e.actor_name, "Bob")
    assert_eq(e.target_name, "Boss 1", "an enemy can be a plain name")
    assert_eq(e.actor_class, E.CharClass.WARRIOR)

func test_mistake_carries_cascade_provenance() -> void:
    # docs/07 §6: a mistake caused by a live token records what caused it and how
    # deep the chain is. That is what makes a wipe read as a story.
    var log = Log.new()
    var bob = _combatant("Bob")
    var e = log.emit_mistake(4, E.Phase.TANKS, bob, "MIS_TAUNT_LAPSE",
        "Forgot to Taunt", "moderate", "greg_pulled_aggro", 1)
    assert_eq(e.mistake["type"], "MIS_TAUNT_LAPSE",
        "the stable taxonomy key, which is what a line corpus is keyed on")
    assert_eq(e.mistake["name"], "Forgot to Taunt", "and the prose beside it")
    assert_eq(e.mistake["severity"], "moderate")
    assert_eq(e.mistake["caused_by"], "greg_pulled_aggro")
    assert_eq(e.mistake["cascade_depth"], 1)
    assert_true(e.is_mistake())

func test_severity_round_trips_as_a_key_and_displays_as_a_name() -> void:
    # The bug this defends: the sim wrote the display Name ("Severe") and every
    # reader looked it up in SEVERITY_KEYS, so `severity_index()` was -1 for
    # every real mistake — docs/13 §11.2's comedy brake never fired and §11.3's
    # header printed "?". Both halves of the trip are asserted here so a future
    # emitter cannot pick the other representation and stay green.
    var log = Log.new()
    for sev in [E.Severity.MINOR, E.Severity.MODERATE, E.Severity.SEVERE,
            E.Severity.CRITICAL]:
        var e = log.emit_mistake(1, E.Phase.DPS, _combatant("Steve", "mage"),
            "MIS_AFK", "Went AFK", E.severity_key(sev))
        assert_eq(e.mistake["severity"], E.severity_key(sev),
            "stored as a key, like every other enum on the entry")
        assert_eq(e.severity_index(), sev, "and reads back as the same band")
        assert_eq(e.severity_display(), E.severity_name_of(sev))
        assert_false(e.describe().contains("?"), e.describe())

func test_a_mistake_entry_carries_the_taxonomy_key_a_corpus_is_looked_up_on() -> void:
    # docs/07 §10.1: the entry REFERENCES its line, it never inlines prose. The
    # entry used to carry only the display name, so no line corpus could ever be
    # keyed off it — the writing pass had nothing to attach to.
    var log = Log.new()
    var e = log.emit_mistake(4, E.Phase.DPS, _combatant("Greg", "rogue"),
        "MIS_AGGRO", "Pulled Aggro Off the Tank", "severe", "", 0,
        "MIS_AGGRO.01")
    assert_eq(e.mistake["type"], "MIS_AGGRO")
    assert_eq(e.mistake["template"], "MIS_AGGRO.01",
        "which variant was drawn is recorded, so the goldens pin the choice")
    assert_eq(e.mistake_name(), "Pulled Aggro Off the Tank",
        "and the header still reads as prose")

func test_the_joke_line_reaches_the_rendered_account() -> void:
    # docs/07 §10.3's sample block and docs/13 §11.3: the joke is an indented,
    # quoted second line under its header. Nothing ever wrote it, so it had never
    # appeared anywhere — not in the log, not in the post-mortem, not in a
    # golden — and no test noticed because the render branch failed silently.
    var log = Log.new()
    var greg = _combatant("Greg", "rogue")
    var e = log.emit_mistake(4, E.Phase.DPS, greg, "MIS_AGGRO",
        "Pulled Aggro Off the Tank", "severe", "", 0, "MIS_AGGRO.01",
        "Greg saw a big number, chased a bigger one, and is now the big number.")
    assert_eq(e.joke(),
        "Greg saw a big number, chased a bigger one, and is now the big number.")
    var lines: PackedStringArray = e.describe().split("\n")
    assert_eq(lines.size(), 2, e.describe())
    assert_true(String(lines[0]).contains("MISTAKE · Severe · Pulled Aggro Off the Tank"),
        String(lines[0]))
    assert_eq(String(lines[1]),
        '      "Greg saw a big number, chased a bigger one, and is now the big number."',
        "indented six spaces and quoted, exactly as docs/07 §10.3 prints it")

func test_a_mistake_with_no_line_authored_yet_serialises_as_it_always_did() -> void:
    # The corpus is unwritten (M5-COMEDY-02/03). An empty joke must not add a
    # `params` block to the entry, or every golden would carry a dead key.
    var log = Log.new()
    var e = log.emit_mistake(1, E.Phase.DPS, _combatant("Bob"), "MIS_AFK",
        "Went AFK", "minor")
    assert_eq(e.joke(), "")
    assert_false(e.to_dict().has("params"))
    assert_false(e.describe().contains("\n"), "header only, no empty quote row")

func test_entries_are_structured_not_prose() -> void:
    # The displayed string is rendered at display time; the entry itself is data.
    # That is what keeps localisation and verbosity filtering possible at all.
    var log = Log.new()
    var e = log.emit_attack(4, E.Phase.TANKS, _combatant("Bob"), "Boss 1", 7, 1575)
    var d := e.to_dict()
    assert_true(d.has("numbers"), "the amount is a field, not baked into a sentence")
    assert_true(d.has("template_id"), "the line to render is referenced, not inlined")
    assert_eq(d["verb"], "attack")

func test_debug_fields_are_absent_unless_populated() -> void:
    var log = Log.new()
    var e = log.emit_system(1, "x")
    assert_false(e.to_dict().has("debug"))
    e.debug = {"seed": "0x8A31", "channel": "mistake_gate:r4:greg", "draw": 17}
    assert_true(e.to_dict().has("debug"))

func test_a_debug_tier_mistake_entry_carries_its_provenance() -> void:
    # SIM-29 / docs/07 §10.1: the `debug` field ("seed, channel, draw index,
    # formula inputs — tier 3 only") had no producer for mistakes, so a tier-3
    # view could not say why a roll failed. `emit_mistake` takes the block the
    # sim built (`MistakeEvent.debug_dict()`), it serialises under `debug`,
    # and the entry is visible at tier DEBUG with the lot.
    var log = Log.new()
    var greg = _combatant("Greg", "rogue")
    var debug := {
        "p_bp": 1400, "r_bp": 310, "margin": 0.779, "channel": "mistake_gate:r4:5",
        "draw": 17, "weights": {"MIS_AGGRO": 15, "MIS_WRONG_TARGET": 10},
        "severity_s": 82,
    }
    var e = log.emit_mistake(4, E.Phase.DPS, greg, "MIS_AGGRO",
        "Pulled Aggro Off the Tank", "severe", "", 0, "MIS_AGGRO.01", "", debug)
    for key in ["p_bp", "r_bp", "margin", "channel", "draw", "weights", "severity_s"]:
        assert_true(e.debug.has(key), "missing %s" % key)
    assert_eq(int(e.debug["p_bp"]), 1400)
    assert_eq(int(e.debug["r_bp"]), 310)
    assert_eq(String(e.debug["channel"]), "mistake_gate:r4:5")
    assert_eq(int(e.debug["draw"]), 17)
    assert_true(e.to_dict().has("debug"), "serialised, so the goldens pin it")
    assert_eq(log.at_tier(E.LogTier.DEBUG).size(), 1)
    assert_true(log.at_tier(E.LogTier.DEBUG)[0].debug.has("p_bp"))
    # docs/07 §10.3's tier-3 line, rendered from the block.
    var line: String = e.debug_line()
    assert_true(line.contains("p=14.0 r=3.1 margin=0.779"), line)
    assert_true(line.contains("ch=mistake_gate:r4:5 draw#17"), line)
    assert_true(line.contains("MIS_AGGRO: 15"), line)
    assert_true(line.contains("-> MIS_AGGRO"), line)
    assert_true(line.contains("severity S=82"), line)
    # The Story line is untouched: the joke and the header render as before.
    assert_false(e.describe().contains("p="), "provenance never leaks into the story line")

func test_a_mistake_with_no_provenance_serialises_as_it_always_did() -> void:
    # The screen tests and older callers pass no block; nothing may change for
    # them, and `debug_line()` is "" so a tier-3 view can append it blindly.
    var log = Log.new()
    var e = log.emit_mistake(1, E.Phase.DPS, _combatant("Bob"), "MIS_AFK", "Went AFK", "minor")
    assert_false(e.to_dict().has("debug"))
    assert_eq(e.debug_line(), "")
    # A scripted mistake rolled no gate: the line says so rather than printing a number.
    var forced = log.emit_mistake(3, E.Phase.DPS, _combatant("Bob"), "MIS_AFK", "Went AFK",
        "minor", "", 0, "", "", {"p_bp": -1, "r_bp": -1, "margin": 0.0,
        "channel": "mistake_gate:r3:0", "draw": 0, "weights": {"MIS_AFK": 8}, "severity_s": -1})
    assert_true(forced.debug_line().begins_with("p=- r=- "), forced.debug_line())
    assert_true(forced.debug_line().ends_with("severity S=-"), forced.debug_line())

# ---------------------------------------------------------------- rendering

func test_fallback_rendering_is_readable_without_templates() -> void:
    # Real display goes through the template registry, but a log has to be
    # readable in tests, dev builds and bug reports with no templates loaded.
    var log = Log.new()
    var bob = _combatant("Bob")
    var greg = _combatant("Greg", "rogue")
    log.emit_attack(4, E.Phase.TANKS, bob, "Boss 1", 7, 1575)
    log.emit_mistake(4, E.Phase.DPS, greg, "MIS_AGGRO",
        "Pulled Aggro Off the Tank", "severe")
    log.emit_state_change(5, E.Phase.BOSS, greg, "DOWNED")

    var text := log.transcript(E.LogTier.PLAY_BY_PLAY)
    assert_true(text.contains("[R04] Bob hits Boss 1 for 7."), text)
    assert_true(text.contains("Greg MISTAKE"), text)
    assert_true(text.contains("Severe"), text)
    assert_true(text.contains("Pulled Aggro Off the Tank"), text)
    assert_true(text.contains("[R05] Greg is DOWNED."), text)

func test_transcript_respects_the_tier() -> void:
    var log = Log.new()
    log.emit_mistake(1, E.Phase.DPS, _combatant("Steve", "mage"), "MIS_FACEPULL",
        "Facepulled the Next Group", "severe")
    log.emit_phase(1, E.Phase.BOSS)
    assert_false(log.transcript(E.LogTier.STORY).contains("Boss"))
    assert_true(log.transcript(E.LogTier.NUMBERS).contains("Boss"))

# ---------------------------------------------------------------- aggregates

func test_sum_numbers_totals_a_field_across_the_log() -> void:
    var log = Log.new()
    var bob = _combatant("Bob")
    log.emit_attack(1, E.Phase.TANKS, bob, "Boss", 10, 100)
    log.emit_attack(2, E.Phase.TANKS, bob, "Boss", 15, 85)
    log.emit_heal(2, E.Phase.HEALERS, bob, bob, 30, 120)
    assert_eq(log.sum_numbers(E.Verb.ATTACK, "amount"), 25, "damage dealt")
    assert_eq(log.sum_numbers(E.Verb.HEAL, "amount"), 30, "healing done")

func test_mistakes_helper_collects_only_mistakes() -> void:
    var log = Log.new()
    var bob = _combatant("Bob")
    log.emit_attack(1, E.Phase.TANKS, bob, "Boss", 10, 100)
    log.emit_mistake(1, E.Phase.TANKS, bob, "MIS_TAUNT_LAPSE", "Forgot to Taunt", "moderate")
    log.emit_mistake(2, E.Phase.TANKS, bob, "MIS_AFK", "Went AFK", "minor")
    assert_eq(log.mistakes().size(), 2)

# ---------------------------------------------------------------- golden files

func test_serialises_deterministically_for_golden_comparison() -> void:
    # Two identical runs must produce byte-identical JSON, or golden tests
    # cannot exist and sim drift becomes invisible.
    var a = Log.new()
    var b = Log.new()
    for log in [a, b]:
        var bob = _combatant("Bob")
        log.emit_phase(1, E.Phase.ROUND_OPEN)
        log.emit_attack(1, E.Phase.TANKS, bob, "Boss 1", 7, 1575, 168)
        log.emit_mistake(1, E.Phase.AMBIENT_MISTAKE, bob, "MIS_TAUNT_LAPSE",
            "Forgot to Taunt", "moderate")
        log.emit_system(1, "WIPE.")
    assert_eq(a.to_json(), b.to_json(), "identical event streams must serialise identically")

func test_dict_form_carries_every_field_the_ui_needs() -> void:
    var log = Log.new()
    var e = log.emit_heal(6, E.Phase.HEALERS, _combatant("Natsuna", "shaman"),
        _combatant("Bob"), 28, 120)
    var d := e.to_dict()
    for key in ["sequence", "round", "phase", "tier", "verb",
                "actor_name", "target_name", "numbers"]:
        assert_true(d.has(key), "missing %s" % key)
    assert_eq(d["phase"], "healers")
    assert_eq(d["tier"], "play_by_play")

func test_a_canon_flavoured_fight_reads_correctly() -> void:
    # docs/07 §10.3's sample, using canon's own roster names.
    var log = Log.new()
    var bob = _combatant("Bob")
    var greg = _combatant("Greg", "rogue")
    var natsuna = _combatant("Natsuna", "shaman")
    log.emit_mistake(4, E.Phase.DPS, greg, "MIS_AGGRO",
        "Pulled Aggro Off the Tank", "severe")
    log.emit_mistake(4, E.Phase.TANKS, bob, "MIS_TAUNT_LAPSE",
        "Forgot to Taunt", "moderate", "greg_pulled_aggro", 1)
    log.emit_state_change(5, E.Phase.BOSS, greg, "DOWNED")
    log.emit_state_change(5, E.Phase.ROUND_CLOSE, greg, "DEAD")
    log.emit_heal(8, E.Phase.HEALERS, natsuna, bob, 28, 3)
    log.emit_system(10, "WIPE.")

    assert_eq(log.mistakes().size(), 2)
    assert_eq(log.mistakes()[1].mistake["cascade_depth"], 1,
        "Bob's failure was caused by Greg's — the chain is recorded")
    var story := log.transcript(E.LogTier.STORY)
    assert_true(story.contains("Greg is DEAD."), story)
    assert_true(story.contains("WIPE."), story)
    assert_false(story.contains("heals"), "the rescue heal is play-by-play, not a beat")
