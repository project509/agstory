extends "res://tests/TestCase.gd"
## The raid view's pacing model (docs/13 §11.2) and the screen that reads it.

const LogPlayer = preload("res://game/core/LogPlayer.gd")
const EventLog = preload("res://sim/core/EventLog.gd")
const Enums = preload("res://sim/model/Enums.gd")
const RouterScript = preload("res://game/core/ScreenRouter.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const StartingRoster = preload("res://game/core/StartingRoster.gd")
const Scenarios = preload("res://tests/golden/Scenarios.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Combatant = preload("res://sim/model/Combatant.gd")
const MistakeLines = preload("res://sim/content/MistakeLines.gd")
const Mistakes = preload("res://sim/core/Mistakes.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const RaidViewScript = preload("res://game/screens/RaidView.gd")

const RAID_VIEW := "res://game/screens/RaidView.tscn"
const RESULTS := "res://game/screens/Results.tscn"

var _db = null
var _made: Array = []

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []

func after_each() -> void:
    var root := _root()
    if root != null:
        var st = root.get_node_or_null("GameState")
        if st != null:
            st.reset()
            st.set_content(null)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []

func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null

## A log with a known shape: two ordinary lines, a minor mistake, a severe
## mistake, a death and a wipe — one of everything the pacing rules care about.
##
## Built through the same arguments `RaidSim._log_mistake` passes, and that is
## load-bearing: this fixture used to hand-write the lowercase severity key the
## sim did not emit, so every pacing test below passed while the brake was dead
## in the actual game.
func _fixture() -> Array:
    var log = EventLog.new()
    log.emit_attack(1, Enums.Phase.DPS, "Bob", "Trash", 12, 400)
    log.emit_attack(1, Enums.Phase.DPS, "Greg", "Trash", 9, 391)
    log.emit_mistake(2, Enums.Phase.DPS, "Steve", "MIS_FIRE", "Stood in the Fire",
        Enums.severity_key(Enums.Severity.MINOR))
    log.emit_mistake(3, Enums.Phase.DPS, "Steve", "MIS_FIRE", "Stood in the Fire",
        Enums.severity_key(Enums.Severity.SEVERE))
    log.emit_state_change(4, Enums.Phase.DPS, "Bob", "dead")
    log.emit_system(5, "WIPE.")
    return log.at_tier(Enums.LogTier.NUMBERS)

func _player(speed: int = LogPlayer.Speed.ONE):
    return LogPlayer.new(_fixture(), speed)

# ---------------------------------------------------------------- cadence

func test_the_documented_cadences_are_the_ones_used() -> void:
    # docs/13 §11.2, verbatim: 1x 180ms · 2x 110ms · 4x batched.
    assert_almost(float(LogPlayer.LINE_CADENCE[LogPlayer.Speed.ONE]), 0.180)
    assert_almost(float(LogPlayer.LINE_CADENCE[LogPlayer.Speed.TWO]), 0.110)
    assert_almost(float(LogPlayer.MISTAKE_HOLD[LogPlayer.Speed.ONE]), 0.700)
    assert_almost(float(LogPlayer.MISTAKE_HOLD[LogPlayer.Speed.TWO]), 0.500)
    assert_almost(float(LogPlayer.MISTAKE_HOLD[LogPlayer.Speed.FOUR]), 0.300)
    assert_almost(float(LogPlayer.ROUND_DURATION[LogPlayer.Speed.ONE]), 2.60)
    assert_almost(float(LogPlayer.ROUND_DURATION[LogPlayer.Speed.FOUR]), 0.65)

func test_a_full_round_of_phase_blocks_lands_on_the_documented_duration() -> void:
    # docs/13 §11.2 gives 4x a 0.65s round and says non-mistake lines batch per
    # phase. Eight phase blocks must therefore add up to that round.
    assert_almost(LogPlayer.PHASE_BLOCK_HOLD * 8.0,
        float(LogPlayer.ROUND_DURATION[LogPlayer.Speed.FOUR]), 0.0001,
        "a round of full phase blocks should take 0.65s at 4x")

func test_nothing_is_revealed_before_time_passes() -> void:
    var p = _player()
    assert_eq(p.revealed_count(), 0)
    assert_false(p.is_finished())

func test_lines_arrive_one_per_cadence_at_one_times() -> void:
    var p = _player()
    assert_eq(p.advance(0.0).size(), 1, "the first line lands immediately")
    assert_eq(p.advance(0.050).size(), 0, "and then the cadence holds")
    assert_eq(p.advance(0.140).size(), 1, "180ms after the first")

func test_a_long_frame_never_swallows_lines() -> void:
    # A dropped frame must delay the reveal, not delete part of the account.
    var p = _player()
    var got: Array = p.advance(10.0)
    assert_eq(got.size(), p.total(),
        "a 10s frame should reveal everything rather than one line")
    assert_true(p.is_finished())

# ---------------------------------------------------------------- mistake holds

func test_a_mistake_holds_longer_than_an_ordinary_line() -> void:
    # docs/13 §11.3: "the reveal pauses for the hold before the next line, so the
    # joke is read before the consequence lands."
    var p = _player()
    var minor = _fixture()[2]
    var ordinary = _fixture()[0]
    assert_true(p.duration_for(minor) > p.duration_for(ordinary))
    assert_almost(p.duration_for(minor), 0.700)

func test_a_mistake_hold_never_drops_below_the_floor() -> void:
    # docs/13 §11.2: "a mistake line is never below 300ms."
    for speed in [LogPlayer.Speed.ONE, LogPlayer.Speed.TWO, LogPlayer.Speed.FOUR]:
        var p = _player(speed)
        var minor = _fixture()[2]
        assert_true(p.duration_for(minor) >= LogPlayer.MISTAKE_HOLD_FLOOR,
            "speed %d held a mistake for only %.3fs" % [speed, p.duration_for(minor)])

func test_severity_reads_the_key_string_the_sim_emits() -> void:
    # EventLog.emit_mistake stores severity as a KEY, not an enum int. Reading it
    # as an int would have made every mistake "minor" and silently disabled the
    # comedy brake.
    var entries := _fixture()
    assert_eq(LogPlayer.severity_of(entries[2]), Enums.Severity.MINOR)
    assert_eq(LogPlayer.severity_of(entries[3]), Enums.Severity.SEVERE)

# ---------------------------------------------------------------- comedy brake

func test_the_comedy_brake_slows_a_severe_mistake_at_four_times() -> void:
    # docs/13 §11.2: "a joke needs a beat, and the player chose 4x to skip the
    # arithmetic, not the story."
    var p = _player(LogPlayer.Speed.FOUR)
    var entries := _fixture()
    assert_almost(p.duration_for(entries[3]), 0.700, 0.0001,
        "a severe mistake is paced as 1x even at 4x")
    assert_almost(p.duration_for(entries[2]), 0.300, 0.0001,
        "a minor mistake keeps the 4x hold")

func test_the_brake_catches_exactly_the_three_documented_things() -> void:
    var p = _player(LogPlayer.Speed.FOUR)
    var entries := _fixture()
    assert_false(p.deserves_a_beat(entries[0]), "an ordinary attack gets no beat")
    assert_false(p.deserves_a_beat(entries[2]), "a minor mistake gets no beat")
    assert_true(p.deserves_a_beat(entries[3]), "a severe mistake does")
    assert_true(p.deserves_a_beat(entries[4]), "a death does")
    assert_true(p.deserves_a_beat(entries[5]), "the wipe line does")

func test_the_brake_can_be_turned_off() -> void:
    # `Setting: comedy_brake`, default on (docs/13 §11.2).
    var p = _player(LogPlayer.Speed.FOUR)
    assert_true(p.comedy_brake, "the brake ships on")
    p.comedy_brake = false
    assert_almost(p.duration_for(_fixture()[3]), 0.300, 0.0001,
        "with the brake off a severe mistake takes the 4x hold")

func test_the_brake_is_a_no_op_at_one_times() -> void:
    var p = _player(LogPlayer.Speed.ONE)
    assert_almost(p.duration_for(_fixture()[3]), 0.700)

func test_the_comedy_brake_fires_on_a_real_simulated_raid() -> void:
    # The test the hand-written fixture above could never be: it drives the sim
    # and reads back what the sim actually emitted. Before the round trip was
    # fixed, `severity_of` returned -1 for every one of these entries, so no
    # mistake in a real raid was ever Severe and docs/13 §11.2's brake was dead
    # in the shipped game while every pacing test above stayed green.
    var spec: Dictionary = Scenarios.SCENARIOS["e5_miserable_commons"]
    var roster := Scenarios.build_roster(spec, _db)
    var enc = _db.encounter_at_slot(String(spec["encounter"]))
    var res = RaidSim.run(roster, enc, _db, int(spec["seed"]))
    var mistakes: Array = res.log.mistakes()
    assert_true(mistakes.size() > 0, "morale-5 Commons at E5 must fumble something")

    var p = LogPlayer.new(mistakes, LogPlayer.Speed.FOUR)
    var severe = null
    for e in mistakes:
        assert_true(LogPlayer.severity_of(e) >= 0,
            "round %d's %s severity did not resolve: %s"
            % [e.round_no, e.mistake["type"], str(e.mistake["severity"])])
        if LogPlayer.severity_of(e) >= Enums.Severity.SEVERE and severe == null:
            severe = e
    assert_true(severe != null, "a miserable raid must produce a Severe mistake")
    assert_almost(p.duration_for(severe), 0.700, 0.0001,
        "a Severe mistake from the sim must be paced as 1x even at 4x")

# ---------------------------------------------------------------- batching

func test_four_times_batches_a_phase_but_never_a_mistake() -> void:
    # docs/13 §11.2: at 4x "non-mistake lines appear in phase blocks", and a
    # mistake "is never batched with other lines".
    var p = _player(LogPlayer.Speed.FOUR)
    var first: Array = p.advance(0.0)
    assert_eq(first.size(), 2,
        "both round-1 attacks share a phase and should land together")
    for e in first:
        assert_false(e.is_mistake())

func test_one_times_never_batches() -> void:
    var p = _player(LogPlayer.Speed.ONE)
    assert_eq(p.advance(0.0).size(), 1, "1x reveals one line at a time")

# ---------------------------------------------------------------- controls

func test_instant_reveals_the_whole_account() -> void:
    var p = _player(LogPlayer.Speed.INSTANT)
    assert_eq(p.advance(0.0).size(), p.total())
    assert_true(p.is_finished())

func test_pause_stops_the_reveal_without_losing_position() -> void:
    var p = _player()
    p.advance(0.0)
    var at: int = p.revealed_count()
    p.paused = true
    assert_eq(p.advance(5.0).size(), 0, "a paused reader reveals nothing")
    assert_eq(p.revealed_count(), at, "and does not lose its place")
    p.paused = false
    assert_true(p.advance(1.0).size() > 0, "resuming continues from there")

func test_raising_the_speed_does_not_cut_a_pending_hold() -> void:
    # docs/13 §11.2: a mistake line "is never skipped by a speed change
    # mid-reveal". The pending timer must survive set_speed().
    var p = _player(LogPlayer.Speed.ONE)
    while not p.is_finished():
        var got: Array = p.advance(0.0)
        var was_mistake := false
        for e in got:
            if e.is_mistake():
                was_mistake = true
        if was_mistake:
            break
        p.advance(0.2)
    var before: int = p.revealed_count()
    p.set_speed(LogPlayer.Speed.FOUR)
    assert_eq(p.revealed_count(), before,
        "changing speed must not itself reveal the next line")

func test_cycling_speed_never_lands_on_instant() -> void:
    # Instant ends the reveal, so it must not be one click away from 1x.
    var p = _player()
    var seen := {}
    for _i in 8:
        seen[p.cycle_speed()] = true
    assert_false(seen.has(LogPlayer.Speed.INSTANT),
        "the cycle must stay within 1x/2x/4x")

func test_reveal_all_is_idempotent() -> void:
    var p = _player()
    p.reveal_all()
    assert_eq(p.reveal_all().size(), 0, "skipping twice must not duplicate lines")
    assert_true(p.is_finished())

func test_progress_runs_from_zero_to_one() -> void:
    var p = _player()
    assert_almost(p.progress(), 0.0)
    p.reveal_all()
    assert_almost(p.progress(), 1.0)

func test_an_empty_log_is_immediately_finished() -> void:
    var p = LogPlayer.new([], LogPlayer.Speed.ONE)
    assert_true(p.is_finished(), "no account means nothing to wait for")
    assert_eq(p.advance(1.0).size(), 0)
    assert_almost(p.progress(), 1.0)

func test_speed_never_changes_what_is_revealed_only_when() -> void:
    # docs/13 §11.2's hard constraint: "Speed affects presentation only and can
    # never affect outcome." Every speed must reach the identical line list.
    var expected: Array = []
    for e in _fixture():
        expected.append(e.sequence)
    for speed in [LogPlayer.Speed.ONE, LogPlayer.Speed.TWO,
            LogPlayer.Speed.FOUR, LogPlayer.Speed.INSTANT]:
        var p = _player(speed)
        var got: Array = []
        for _i in 200:
            for e in p.advance(0.25):
                got.append(e.sequence)
            if p.is_finished():
                break
        assert_eq(got, expected, "speed %d changed the account" % speed)

# ---------------------------------------------------------------- the screen

func _mounted_view():
    var root := _root()
    var host := Control.new()
    root.add_child(host)
    _made.append(host)
    var st = root.get_node_or_null("GameState")
    st.reset()
    st.set_content(_db)
    st.new_game("View Test")
    var enc = _db.encounter_at_slot("A1")
    st.selected_encounter_id = enc.id
    var party: Array = st.roster.slice(0, enc.party_size)
    st.record_attempt(enc.id, RaidSim.run(party, enc, _db, 4242))
    var r = root.get_node_or_null("ScreenRouter")
    r.register_host(host)
    assert_true(r.goto(RAID_VIEW), "the raid view must open")
    return r.current_screen()

func test_the_view_opens_on_play_by_play() -> void:
    # docs/13 §11.1: three verbosity buttons "defaulting to Play-by-play".
    var view = _mounted_view()
    assert_eq(view.current_tier(), Enums.LogTier.PLAY_BY_PLAY)

func test_the_view_has_an_account_to_read() -> void:
    var view = _mounted_view()
    assert_true(view.player().total() > 0, "the attempt should have produced lines")
    assert_false(view.player().is_finished(), "and it should not start finished")

func test_reading_the_account_reveals_every_line() -> void:
    var view = _mounted_view()
    var p = view.player()
    for _i in 2000:
        p.advance(0.25)
        if p.is_finished():
            break
    assert_true(p.is_finished(), "the whole account must be readable")
    assert_eq(p.revealed_count(), p.total())

func test_changing_detail_changes_how_much_there_is_to_read() -> void:
    # Story is a strict subset of Play-by-play, because tier is a filter over one
    # complete log (docs/13 §11.1).
    var view = _mounted_view()
    var play_by_play: int = view.player().total()
    view._set_tier(Enums.LogTier.STORY)
    var story: int = view.player().total()
    assert_true(story > 0, "Story must still have the beats")
    assert_true(story < play_by_play, "and be shorter than Play-by-play")
    assert_eq(view.current_tier(), Enums.LogTier.STORY)

func test_changing_detail_restarts_the_read() -> void:
    var view = _mounted_view()
    view.player().advance(2.0)
    assert_true(view.player().revealed_count() > 0)
    view._set_tier(Enums.LogTier.STORY)
    assert_eq(view.player().revealed_count(), 0,
        "a partial page at a new tier is a page that never existed")

func test_skipping_finishes_the_account() -> void:
    var view = _mounted_view()
    view._on_skip()
    assert_true(view.player().is_finished())

## Every Label and Button text in a mounted tree — the project's test contract.
## The accumulator is a separate function rather than a defaulted argument: an
## `out: Array = []` default reads as a shared-mutable-default trap even when it
## is not one, and a reader should not have to work out which.
func _texts(n: Node) -> Array:
    var out: Array = []
    _collect_texts(n, out)
    return out

func _collect_texts(n: Node, out: Array) -> void:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _collect_texts(c, out)

## One mistake entry carrying a rendered joke, shaped exactly as the sim emits
## one. The line is docs/07 §10.3's sample block verbatim, so this fixture never
## becomes a place where comedy gets invented.
func _mistake_with_a_joke():
    var r = Raider.new()
    r.id = "id-greg"
    r.display_name = "Greg"
    r.class_id = Enums.class_from_key("rogue")
    var log = EventLog.new()
    return log.emit_mistake(4, Enums.Phase.DPS, Combatant.create(r, _db, 0),
        "MIS_AGGRO", "Pulled Aggro Off the Tank",
        Enums.severity_key(Enums.Severity.SEVERE), "", 0, "MIS_AGGRO.01",
        "Greg saw a big number, chased a bigger one, and is now the big number.")

func test_the_mistake_header_names_the_severity_rather_than_a_question_mark() -> void:
    # docs/13 §11.3's header signal. With the severity written as a display Name
    # and read back as a key this printed `Greg (Rogue) — ? — …` in the shipped
    # game, and no screen test ever looked at a mistake row. W6-LOG (UI-19): the
    # TYPE leads — "Pulled Aggro Off the Tank — Greg, Severe" — because the
    # type was the part an ellipsis ate; the class is on the card.
    var view = _mounted_view()
    view._append_line(_mistake_with_a_joke())
    var printed: String = "\n".join(PackedStringArray(_texts(view)))
    assert_true(printed.contains("Pulled Aggro Off the Tank — Greg, Severe"),
        printed)
    assert_false(printed.contains("Greg (Rogue) —"), "the class is not repeated on the header")
    assert_false(printed.contains(", ?"), "the severity must resolve")

func test_the_joke_line_reaches_the_raid_view_as_a_label() -> void:
    # docs/13 §11.3: italic, indented, in quotation marks. The branch that draws
    # it read a params key nothing ever wrote, so it had never run. Asserted
    # through Label text because that is all a screen test can see (rule 2).
    var view = _mounted_view()
    view._append_line(_mistake_with_a_joke())
    var quoted: Array = []
    for t in _texts(view):
        var s := String(t)
        if s.begins_with('"') and s.ends_with('"'):
            quoted.append(s)
    assert_eq(quoted.size(), 1, str(quoted))
    assert_eq(String(quoted[0]),
        '"Greg saw a big number, chased a bigger one, and is now the big number."')

func test_the_joke_line_reaches_the_post_mortem_as_a_label() -> void:
    # The second render site. Results built every "What happened" row from
    # `describe()` and showed the header only, so the post-mortem was a list of
    # failures with all the punchlines removed.
    _mounted_view()
    var root := _root()
    var r = root.get_node_or_null("ScreenRouter")
    assert_true(r.goto(RESULTS), "the post-mortem must open")
    var results = r.current_screen()
    var row: Control = results._story_row(_mistake_with_a_joke())
    _made.append(row)
    var texts: Array = _texts(row)
    assert_eq(texts.size(), 2, "a header row and a quote row: %s" % str(texts))
    # W6-LOG (CRITIC-C2): the report prints the live log's own header, filed
    # under its round — one rule for the two reading surfaces.
    assert_eq(String(texts[0]), "[R04] Pulled Aggro Off the Tank — Greg, Severe",
        String(texts[0]))
    assert_eq(String(texts[1]),
        '"Greg saw a big number, chased a bigger one, and is now the big number."')
    assert_false(String(texts[0]).contains("\n"),
        "the header row must not carry the joke as a second line as well")

func test_a_real_raids_jokes_reach_the_screen_from_the_corpus() -> void:
    # audit M5-COMEDY-05's acceptance. The two tests above hand the screen an entry
    # with a joke already on it, so they would stay green with the sim's joke path
    # deleted. This one runs the REAL chain: the account `_mounted_view()` played
    # (A1, seed 4242), skipped through `_on_skip()` — `reveal_all()` -> `_append_line`
    # for every line — and every quoted Label read back against the corpus. Removing
    # `RaidSim._draw_joke` or `mstate["jokes"]` leaves no entry with a joke, and the
    # fixture guard below goes red before anything else does.
    var view = _mounted_view()
    view._on_skip()
    var joked: Array = []
    for e in view.player().revealed():
        if e.is_mistake() and not String(e.joke()).is_empty():
            joked.append(e)
    assert_true(joked.size() > 0,
        "the fixture must fumble with a line: A1 at seed 4242 revealed no joke — "
        + "pick a slot/seed that does (test_raid_overlays.gd asserts seed 5 carries one)")

    var corpus = MistakeLines.load_from()
    assert_true(corpus.is_valid(), corpus.error_report())
    var quoted: Array = []
    for t in _texts(view):
        var s := String(t)
        if s.length() > 2 and s.begins_with('"') and s.ends_with('"'):
            quoted.append(s.substr(1, s.length() - 2))
    assert_true(quoted.size() > 0, "docs/13 §11.3: the joke lands as a quoted line")

    # (a) every quoted line on the screen is a corpus line, filled for the actor of a
    #     revealed mistake whose template names it — not invented, not somebody else's.
    for q in quoted:
        var matched := false
        for e in joked:
            var template := String(e.mistake.get("template", ""))
            if corpus.by_id.has(template) and corpus.render(template, e.actor_name) == q:
                matched = true
        assert_true(matched, "'%s' is not a corpus line filled for its actor" % q)
    # (b) and every joke the sim drew is on the screen, which is the half that was
    #     missing for months: the branch that draws it read a key nothing wrote.
    for e in joked:
        assert_true(quoted.has(String(e.joke())),
            "round %d's %s joke never reached a Label: '%s'"
            % [e.round_no, String(e.mistake["type"]), String(e.joke())])
        assert_eq(String(e.joke()),
            MistakeLines.fill(String(corpus.by_id[String(e.mistake["template"])]["text"]),
                e.actor_name),
            "the entry's line is the corpus text with {actor} filled")

func test_the_mistake_counter_matches_the_log() -> void:
    # docs/13 §11.3's rail counter, which must agree with the account it is
    # counting rather than with a separate tally. A folded row (three raiders,
    # one line) stands for its count, so the counter counts the ACCOUNT.
    var view = _mounted_view()
    view._on_skip()
    var expected := 0
    for e in view.player().revealed():
        if e.is_mistake():
            expected += LogPlayer.count_of(e)
    assert_eq(view.mistakes_seen(), expected)
    assert_eq(expected, int(view._state.last_result.mistake_count),
        "the fold hides rows, never mistakes")


# ---------------------------------------------------------------- the fold (CONTENT-13)

## Three raiders, one round, one Minor type — the case docs/07 §5.5's fourth
## guard exists for — plus the two shapes that must NOT fold.
func _minor(log, who: String, round_no: int, type_id: String = "MIS_AFK",
        severity: int = Enums.Severity.MINOR):
    var r = Raider.new()
    r.id = "id-" + who.to_lower()
    r.display_name = who
    r.class_id = Enums.class_from_key("rogue")
    var name := "Went AFK" if type_id == "MIS_AFK" else "Stood in the Fire"
    return log.emit_mistake(round_no, Enums.Phase.DPS, Combatant.create(r, _db, 0),
        type_id, name, Enums.severity_key(severity), "", 0, type_id + ".01",
        "%s is reading something. It is not the fight." % who)

func test_identical_minor_mistakes_in_one_round_collapse() -> void:
    assert_true(LogPlayer.COLLAPSE, "docs/07 §5.5 guard 4 ships on (M5-COMEDY-10)")
    var log = EventLog.new()
    log.emit_attack(3, Enums.Phase.DPS, "Bob", "Trash", 12, 400)
    var a = _minor(log, "Greg", 3)
    var b = _minor(log, "Steve", 3)
    log.emit_attack(3, Enums.Phase.DPS, "Bob", "Trash", 9, 391)
    var c = _minor(log, "Bob", 3)
    var folded: Array = LogPlayer.collapse(log.entries)
    assert_eq(folded.size(), 3, "two attacks and ONE folded row: %d" % folded.size())
    var row = folded[2]
    assert_true(row.is_mistake(), "the fold is still a mistake entry")
    assert_eq(LogPlayer.count_of(row), 3)
    assert_eq(row.params["actors"], ["Greg", "Steve", "Bob"])
    assert_eq(row.sequence, c.sequence, "the row lands where the last member stood")
    assert_eq(row.round_no, 3)
    assert_eq(String(row.mistake["type"]), "MIS_AFK")
    assert_eq(String(row.joke()), String(c.joke()), "one joke for the folded row")
    assert_eq(LogPlayer.mistake_header(row), "Went AFK — 3 raiders, Minor")
    assert_eq(LogPlayer.actors_of(row), "Greg, Steve and Bob")
    # The originals are untouched: the fold is a display copy (docs/07 §10 rule 2).
    assert_eq(LogPlayer.count_of(a), 1)
    assert_eq(LogPlayer.count_of(b), 1)
    assert_eq(log.entries.size(), 5, "the sim's log still holds every line")
    # Idempotent: folding the folded account changes nothing.
    assert_eq(LogPlayer.collapse(folded).size(), 3)

func test_collapse_never_merges_across_rounds_or_severities() -> void:
    var log = EventLog.new()
    _minor(log, "Greg", 2)
    _minor(log, "Steve", 3)                                   # a different round
    _minor(log, "Bob", 3, "MIS_AFK", Enums.Severity.SEVERE)   # a Severe
    _minor(log, "Dave", 3, "MIS_FIRE")                        # a different type
    var folded: Array = LogPlayer.collapse(log.entries)
    assert_eq(folded.size(), 4, "nothing here is identical to anything else")
    for e in folded:
        assert_eq(LogPlayer.count_of(e), 1)
    # The same raider twice is two lines, not a count ("by different raiders").
    var twice = EventLog.new()
    _minor(twice, "Greg", 4)
    _minor(twice, "Greg", 4)
    assert_eq(LogPlayer.collapse(twice.entries).size(), 2)
    # A knock-on keeps its chain rather than vanishing into a count.
    var chain = EventLog.new()
    _minor(chain, "Greg", 5)
    var knock = _minor(chain, "Steve", 5)
    knock.mistake["caused_by"] = "id-greg:r5:MIS_AFK"
    assert_eq(LogPlayer.collapse(chain.entries).size(), 2)

func test_a_folded_row_reads_as_a_count_on_the_screen() -> void:
    var view = _mounted_view()
    var log = EventLog.new()
    _minor(log, "Greg", 9)
    _minor(log, "Steve", 9)
    _minor(log, "Bob", 9)
    var folded: Array = LogPlayer.collapse(log.entries)
    assert_eq(folded.size(), 1)
    var before: int = view.mistakes_seen()
    view._append_line(folded[0])
    var printed: String = "\n".join(PackedStringArray(_texts(view)))
    assert_true(printed.contains("Went AFK — 3 raiders, Minor"), printed)
    assert_eq(view.mistakes_seen(), before + 3, "the counter counts the account")
    var quoted := 0
    for t in _texts(view):
        if String(t) == '"Bob is reading something. It is not the fight."':
            quoted += 1
    assert_eq(quoted, 1, "one quoted line for the folded row")
    # The player folds its own account on construction, so the screen's reveal
    # and the report agree with `collapse()` without either calling it.
    var p = LogPlayer.new(log.entries, LogPlayer.Speed.ONE)
    assert_eq(p.total(), 1)
    assert_eq(p.reveal_all().size(), 1)


# ---------------------------------------------------------------- the header (UI-19)

func test_every_mistake_type_leads_its_header_and_fits_the_live_row() -> void:
    # UI-19's test: for every `Mistakes.TYPES` name the header, at Type.BODY,
    # fits the live row — `474 - 28 - blot - face - stamp` is the plan's budget
    # for ONE line. Measured (report-W6-LOG.md), four of eighteen type names
    # with a four-letter name and eight with a long one do not fit one line
    # with the stamp on it, so the live header wraps to a SECOND pitch when its
    # words need one (RaidView.HEADER_LINES) and the rule this pins is the
    # stronger one that is true: the TYPE NAME always fits the first line
    # whole, and the whole header — with the longest name the pool can build —
    # never needs a third. `RaidView.text_lines` is the screen's own break.
    var view = _mounted_view()
    var fs: Array = Widgets.font_of("LabelLog", view)
    var font: Font = fs[0]
    var px: int = int(fs[1])
    var stamp: Control = Widgets.stamp_box("MISTAKE", "danger")
    _made.append(stamp)
    var budget: float = 474.0 - 28.0 - 12.0 - 18.0 - stamp.get_combined_minimum_size().x
    var longest := _longest_pool_name()
    assert_true(longest.length() >= 15, "the pool builds long names: '%s'" % longest)
    for type_id in Mistakes.TYPES.keys():
        var type_name := String(Mistakes.TYPES[type_id]["name"])
        assert_eq(RaidViewScript.text_lines(font, px, type_name, budget), 1,
            "'%s' must fit the first line of a live row" % type_name)
        var r = Raider.new()
        r.id = "id-x"
        r.display_name = longest
        r.class_id = Enums.class_from_key("rogue")
        var log = EventLog.new()
        var e = log.emit_mistake(7, Enums.Phase.DPS, Combatant.create(r, _db, 0),
            String(type_id), type_name, Enums.severity_key(Enums.Severity.SEVERE),
            "", 0, String(type_id) + ".01", "A line.")
        var header: String = LogPlayer.mistake_header(e)
        assert_true(header.begins_with(type_name + " — "), "the type leads: " + header)
        view._append_line(e)
        var wrap = view._log_rows[view._log_rows.size() - 2]   # the header's Settle; the quote's is last
        var row: HBoxContainer = wrap.get_child(0)
        var label := row.get_child(row.get_child_count() - 1) as Label
        assert_eq(label.text, header)
        assert_eq(label.max_lines_visible, RaidViewScript.HEADER_LINES)
        assert_eq(label.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING, "never an ellipsis")
        var lines: int = RaidViewScript.text_lines(font, px, header, label.size.x)
        assert_true(lines <= RaidViewScript.HEADER_LINES,
            "'%s' needs %d lines at %.0fpx" % [header, lines, label.size.x])
        assert_eq(int(row.custom_minimum_size.y), Widgets.LOG_ROW_PITCH * lines,
            "the row is a whole number of pitches, sized to its lines")

## The longest display name the pool can produce: its longest given name plus
## its longest epithet of any form (docs/04 §7.1's shape C), read from the
## data so the test moves with the pool.
func _longest_pool_name() -> String:
    var f := FileAccess.open("res://data/names.json", FileAccess.READ)
    assert_true(f != null, "data/names.json opens")
    if f == null:
        return "Maureen of the Ninefold Path"
    var d = JSON.parse_string(f.get_as_text())
    var given := ""
    for g in d.get("given", []):
        if String(g).length() > given.length():
            given = String(g)
    var epithet := ""
    for row in d.get("epithets", []):
        if row is Dictionary:
            var t := String(row.get("text", ""))
            if t.length() > epithet.length():
                epithet = t
    return (given + " " + epithet).strip_edges()
