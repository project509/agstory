extends "res://tests/TestCase.gd"
## W6-LOG (build/plan/ship/00-plan.md §1): the wipe report never cuts a joke
## (UI-23), its fold snaps to a row, its rows fold like the live log's
## (CONTENT-13), and "By raider" names its columns (UI-24).
##
## Mounts the real Results scene on the reference fixture's wipe
## (`Fixture.apply(state, null, true)`, the twelve dead at E5) and reads it
## through `Label.text` and node names. Nothing in the runner is inside a
## tree, so a Label never lays out here: what is asserted is the SHAPE that
## makes the page whole on screen — every quote wraps with no trimming and
## no line cap, the full corpus line is in `Label.text`, the fold's spacer
## and its wiring exist, and the fold arithmetic lands on a row boundary —
## plus the shot (`Results --fixture=raid`) for the eye.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Results = preload("res://game/screens/Results.gd")
const Guildhall = preload("res://game/screens/Guildhall.gd")
const LogPlayer = preload("res://game/core/LogPlayer.gd")
const Fixture = preload("res://tools/fixture_reference.gd")
const EventLog = preload("res://sim/core/EventLog.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")

const RESULTS := "res://game/screens/Results.tscn"

var _root: Node = null
var _made: Array = []


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []


func after_each() -> void:
    var st = _state()
    if st != null:
        st.reset()
        st.content = null
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


# ---------------------------------------------------------------- helpers

func _ensure_autoloads() -> void:
    if _root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        _root.add_child(s)
        _made.append(s)
    if _root.get_node_or_null("ScreenRouter") == null:
        var r = Router.new()
        r.name = "ScreenRouter"
        _root.add_child(r)
        _made.append(r)


func _state():
    return _root.get_node_or_null("GameState")


func _mount() -> Control:
    var h := Control.new()
    h.name = "TestHost"
    h.size = Vector2(1536, 1024)
    _root.add_child(h)
    _made.append(h)
    var r = Router.new()
    _made.append(r)
    r.register_host(h)
    assert_true(r.goto(RESULTS), "the report must mount")
    return r.current_screen()


func _wiped():
    _ensure_autoloads()
    var st = _state()
    Fixture.apply(st, null, true)
    assert_ne(st.last_result, null, "the raid fixture records an attempt")
    return st


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


func _find_named(n: Node, name: String, out: Array = []) -> Array:
    if String(n.name) == name:
        out.append(n)
    for c in n.get_children():
        _find_named(c, name, out)
    return out


func _first_named(n: Node, name: String) -> Node:
    var all := _find_named(n, name)
    return all[0] if not all.is_empty() else null


func _labels_typed(n: Node, variation: String, out: Array = []) -> Array:
    if n is Label and String((n as Label).theme_type_variation) == variation:
        out.append(n)
    for c in n.get_children():
        _labels_typed(c, variation, out)
    return out


# ---------------------------------------------------------------- UI-23: the quotes

func test_no_quote_in_the_report_is_cut_and_every_corpus_line_is_whole() -> void:
    var st = _wiped()
    var screen := _mount()
    var rows := _first_named(screen, "ReportRows")
    assert_ne(rows, null, "the report's rows column is named ReportRows")
    var quotes: Array = _labels_typed(rows, "LabelQuote")
    assert_true(quotes.size() >= 3, "the fixture's wipe prints at least three jokes")
    for q in quotes:
        var l := q as Label
        assert_eq(l.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "the quote wraps")
        assert_eq(l.max_lines_visible, -1, "…without a line cap")
        assert_eq(l.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING, "…and never an ellipsis")
        assert_false(l.clip_text)
        assert_false(l.text.ends_with("…") or l.text.ends_with("…\""), l.text)
    # Every joke the shown account carries is on the page whole, in quotes.
    var shown: Array = LogPlayer.collapse(st.last_result.log.at_tier(Enums.LogTier.STORY))
    var texts: Array = _texts(rows)
    var joked := 0
    for e in shown.slice(0, Results.MAX_STORY_LINES):
        if e.is_mistake() and not String(e.joke()).is_empty():
            joked += 1
            assert_true(('"%s"' % String(e.joke())) in texts, "whole on the page: " + String(e.joke()))
            assert_true(("[R%02d] %s" % [int(e.round_no), LogPlayer.mistake_header(e)]) in texts,
                "the header is the live log's line, under its round")
    assert_eq(quotes.size(), joked, "one quote Label per joke shown")


func test_the_report_header_wraps_too_and_prints_no_type_key() -> void:
    _wiped()
    var screen := _mount()
    var rows := _first_named(screen, "ReportRows")
    var logs: Array = _labels_typed(rows, "LabelLog")
    assert_true(logs.size() > 3)
    for l in logs:
        assert_eq((l as Label).autowrap_mode, TextServer.AUTOWRAP_WORD_SMART,
            "a report row grows to its words: " + (l as Label).text)
        assert_eq((l as Label).text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
        assert_false((l as Label).text.contains("MIS_"), "the taxonomy key never prints")


# ---------------------------------------------------------------- UI-23: the fold

func test_the_fold_snaps_to_a_row_boundary() -> void:
    _wiped()
    var screen := _mount()
    var sc := _first_named(screen, "ReportScroll")
    var spacer := _first_named(screen, "FoldSpacer")
    var rows := _first_named(screen, "ReportRows")
    assert_true(sc is ScrollContainer and spacer is Control and rows is VBoxContainer)
    assert_eq(spacer.get_parent(), sc.get_parent(), "the spacer sits beside the scroll")
    assert_true((rows as VBoxContainer).sort_children.is_connected(screen._snap_report_fold),
        "the fold is re-snapped after every sort of the rows")
    assert_false((spacer as Control).visible, "outside a tree the column never sorts")
    # The arithmetic, on row heights like the page's (a 29 header, 47-px and
    # 65-px mistake blocks): the fold is the bottom of the last row that fits
    # whole, never a slice through one.
    var heights := [29.0, 47.0, 29.0, 65.0, 29.0, 47.0, 65.0]
    var avail := 190.0
    var fold: float = Guildhall.fold_height(heights, 0.0, avail)
    var y := 0.0
    var boundaries: Array = []
    for h in heights:
        y += float(h)
        boundaries.append(y)
    assert_true(fold in boundaries, "fold %.0f is a row boundary of %s" % [fold, str(boundaries)])
    assert_true(fold <= avail and fold >= avail - 65.0, "…the last one that fits")
    assert_eq(Guildhall.fold_height([29.0, 47.0], 0.0, avail), avail, "everything fits: no fold")
    # The heights the snap measures are LINES, not blocks: a mistake's stack
    # (header + quote) contributes two, so the fold can land between them
    # rather than dropping the whole block under the fold.
    var log = EventLog.new()
    var r = Raider.new()
    r.id = "id-greg"
    r.display_name = "Greg"
    r.class_id = Enums.class_from_key("rogue")
    var e = log.emit_mistake(2, Enums.Phase.DPS, _combatant(r), "MIS_AGGRO",
        "Pulled Aggro Off the Tank", Enums.severity_key(Enums.Severity.SEVERE),
        "", 0, "MIS_AGGRO.01", "Greg chased a number.")
    var stack: Control = screen._story_row(e)
    _made.append(stack)
    (stack.get_child(0) as Control).size = Vector2(400, 29)
    (stack.get_child(1) as Control).size = Vector2(400, 36)
    var leaves: Array = []
    Results._leaf_heights(stack, leaves)
    assert_eq(leaves, [29.0, 36.0], str(leaves))
    var plain: Control = screen._story_row(log.emit_attack(1, Enums.Phase.DPS, "Bob", "Trash", 4, 90))
    _made.append(plain)
    plain.size = Vector2(400, 29)
    leaves = []
    Results._leaf_heights(plain, leaves)
    assert_eq(leaves, [29.0])


# ---------------------------------------------------------------- CONTENT-13: the fold of rows

func test_the_report_folds_identical_minor_rows_like_the_live_log() -> void:
    _wiped()
    var screen := _mount()
    var log = EventLog.new()
    for who in ["Greg", "Steve", "Bob"]:
        var r = Raider.new()
        r.id = "id-" + who.to_lower()
        r.display_name = who
        r.class_id = Enums.class_from_key("rogue")
        log.emit_mistake(6, Enums.Phase.DPS, _combatant(r), "MIS_AFK", "Went AFK",
            Enums.severity_key(Enums.Severity.MINOR), "", 0, "MIS_AFK.01",
            "%s is reading something. It is not the fight." % who)
    var folded: Array = LogPlayer.collapse(log.entries)
    assert_eq(folded.size(), 1)
    var row: Control = screen._story_row(folded[0])
    _made.append(row)
    var texts: Array = _texts(row)
    assert_eq(texts.size(), 2, str(texts))
    assert_eq(String(texts[0]), "[R06] Went AFK — 3 raiders, Minor")
    assert_eq(String(texts[1]), '"Bob is reading something. It is not the fight."')


func _combatant(r):
    var Combatant = load("res://sim/model/Combatant.gd")
    return Combatant.create(r, _state().content, 0)


# ---------------------------------------------------------------- UI-24: the tally

func test_the_by_raider_table_names_its_columns() -> void:
    _wiped()
    var screen := _mount()
    var table := _first_named(screen, "ByRaider")
    assert_ne(table, null)
    var header := _first_named(table, "TallyHeader")
    assert_ne(header, null, "the header row is named TallyHeader")
    var words: Array = _texts(header)
    assert_true(words.has("Raider") and words.has("Mistakes") and words.has("State"),
        "Raider · Mistakes · (Morale) · State: %s" % str(words))
    assert_eq(header.get_index(), 0, "the header is the first row of the tally")
    for l in header.get_children():
        if l is Label:
            assert_eq(String((l as Label).theme_type_variation), "LabelSmall")
    # UI-24: the claw is gone — the mistakes cell is the log's MISTAKE glyph.
    var marks := _find_named(table, "Mark")
    var tally := _first_named(table, "Tally")
    assert_eq(marks.size(), tally.get_child_count() - 1, "one glyph cell per row (the header has none)")
    var Icons = load("res://game/ui/Icons.gd")
    for m in marks:
        assert_eq((m as TextureRect).texture, Icons.at("log", "mistake"))
    assert_true(_find_named(table, "Blot").is_empty(), "no blot silhouette in the tally")


func test_a_flat_morale_column_collapses_into_the_mood_line() -> void:
    # The fixture's per-attempt ledger (`last_attempt_morale`, net of the wipe,
    # the KO and each raider's own clamp) is not always one number, and the
    # column shows whenever it is not; the wall UI-24 measured is the flat
    # case, built here by hand: every raider charged the same -12.
    var st = _wiped()
    var screen := _mount()
    var table := _first_named(screen, "ByRaider")
    var tally := _first_named(table, "Tally")
    var flat := {}
    for r in st.last_party:
        flat[r.id] = -12.0
    st.last_attempt_morale = flat
    st.last_wipe_penalty = flat.duplicate()
    screen._refresh_morale()
    var rows: Array = screen._by_raider(st.last_result)
    assert_eq(Results.flat_delta_of(rows), -12)
    var morale := _find_named(table, "Morale")
    assert_eq(morale.size(), rows.size(), "the per-raider figures stay in the tree")
    for l in morale:
        assert_false((l as Control).visible, "…hidden: a wall of one number says nothing")
        assert_eq((l as Label).text, "-12")
    var words: Array = _texts(_first_named(table, "TallyHeader"))
    assert_false(words.has("Morale"), "the header drops the column too")
    assert_true(words.has("Raider") and words.has("State"))
    var printed: String = "
".join(PackedStringArray(_texts(screen)))
    assert_true(printed.contains("That cost 12 morale each — %d between them." % (12 * rows.size())),
        printed)
    assert_eq(tally.get_child_count(), rows.size() + 1, "a header and one row per raider")
    # And when the deltas differ, the column shows and the header names it.
    var mixed := flat.duplicate()
    mixed[st.last_party[0].id] = -4.0
    st.last_attempt_morale = mixed
    screen._refresh_morale()
    var again: Array = screen._by_raider(st.last_result)
    assert_eq(Results.flat_delta_of(again), null)
    for l in _find_named(table, "Morale"):
        assert_true((l as Control).visible, "the column is back when it says something")
    assert_true(_texts(_first_named(table, "TallyHeader")).has("Morale"))
    assert_true("
".join(PackedStringArray(_texts(screen))).contains("morale between them."))
    assert_eq(Results.flat_delta_of([again[0]]), null, "one row is not a wall")


# ---------------------------------------------------------------- W7-REPORT: the shape of the new lines

func test_the_cause_sentence_wraps_whole_under_the_stamp() -> void:
    # LOOP-12: the sentence is a reading line (docs/13 §11.4 "readable in
    # under 15 seconds"), so like every quote on this page it wraps to its
    # words and is never trimmed — and it sits directly under the stamp box.
    _wiped()
    var screen := _mount()
    var cause := _first_named(screen, "WipeCause") as Label
    assert_ne(cause, null)
    assert_eq(cause.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
    assert_eq(cause.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
    assert_false(cause.text.is_empty())
    var head := _first_named(screen, "Headline") as Control
    assert_ne(head, null)
    assert_eq(cause.get_parent(), head.get_parent(), "in the headline's own column")
    assert_eq(cause.get_index(), head.get_index() + 1, "directly under the stamp")
    # BL-139: the eyebrow sits between the encounter's name and the quote.
    var eyebrow := _first_named(screen, "Eyebrow") as Label
    assert_ne(eyebrow, null)
    assert_eq(String(eyebrow.theme_type_variation), "LabelMuted")
    assert_eq(eyebrow.get_parent(), head.get_parent())
    var quote: Node = eyebrow.get_parent().get_child(eyebrow.get_index() + 1)
    assert_true(quote is Label and String((quote as Label).theme_type_variation) == "LabelQuote",
        "the notice's line follows its eyebrow")


func test_the_exits_flow_with_try_again_first() -> void:
    # UI-37: the wipe's commit leads the exit flow (docs/13 §11.4: "`Try
    # again` is left"), and the flow shape stays so 150% text stacks rather
    # than widening the panel.
    _wiped()
    var screen := _mount()
    var retry := _first_named(screen, "TryAgain") as Button
    assert_ne(retry, null)
    var flow := retry.get_parent()
    assert_true(flow is HFlowContainer, "the exits are a flow")
    assert_eq(retry.get_index(), 0, "Try again is left")
    var labels: Array = []
    for c in flow.get_children():
        if c is Button:
            labels.append((c as Button).text)
    assert_eq(labels, ["Try again", "Back to the board", "Return to town"])
    var cost := retry.get_node_or_null("Cost") as Label
    assert_ne(cost, null, "the cost line is the CTA's own Label")
    assert_eq(cost.text, Results.TRY_AGAIN_COST)
