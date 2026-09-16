extends "res://tests/TestCase.gd"
## W2-RESULTS (build/plan/artaudit/00-plan.md §3): the post-mortem reconciles
## the party by name, and the loot column never offers what it does not have.
##
## Mounts the real Results scene on the reference fixture — the wipe
## (`Fixture.apply(state, null, true)`, the twelve dead at E5) and the clear
## (`Fixture.apply_clear`, Adventure 0 by the squad the game hands you) — and
## reads it the way every screen test does: `Label.text` and `Button.text`,
## plus a few node NAMES the screen promises (`ByRaider`, `Headline`, `Stamp`,
## `RankSigil`, the kit strip's `PagerPrev` / `PagerNext`).
##
## The autoload GameState is borrowed and put back in `after_each`, content
## included (LESSONS: a state left with content changes what `new_game()` does
## for the next file).

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Results = preload("res://game/screens/Results.gd")
const Fixture = preload("res://tools/fixture_reference.gd")
const EventLog = preload("res://sim/core/EventLog.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Scenarios = preload("res://tests/golden/Scenarios.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const DB = preload("res://sim/content/ContentDB.gd")

const RESULTS := "res://game/screens/Results.tscn"
const RAID_PREP := "res://game/screens/RaidPrep.tscn"
## The one-click default's text on a page with nothing to give (a wipe): the
## plain control with its reason. With drops pending it is the crimson commit
## "Give as Suggested — N drops" (UI-36) and is found by NAME below.
const SUGGESTED := "Suggested — give everything"

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


func _host() -> Control:
    var h := Control.new()
    h.name = "TestHost"
    h.size = Vector2(1536, 1024)
    _root.add_child(h)
    _made.append(h)
    return h


## The screen, mounted on a state the fixture has just written.
func _mount() -> Control:
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    assert_true(r.goto(RESULTS), "the report must mount")
    return r.current_screen()


func _wiped():
    _ensure_autoloads()
    var st = _state()
    Fixture.apply(st, null, true)
    assert_ne(st.last_result, null, "the raid fixture records an attempt")
    return st


func _cleared():
    _ensure_autoloads()
    var st = _state()
    var seed_used: int = Fixture.apply_clear(st)
    assert_true(seed_used >= 0, "the clear fixture must find a clearing seed")
    assert_true(st.last_result != null and st.last_result.cleared(),
        "…and the recorded attempt is the clear")
    return st


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


func _find_button(n: Node, text: String) -> Button:
    if n is Button and (n as Button).text == text:
        return n as Button
    for c in n.get_children():
        var f := _find_button(c, text)
        if f != null:
            return f
    return null


func _find_named(n: Node, name: String, out: Array = []) -> Array:
    if String(n.name) == name:
        out.append(n)
    for c in n.get_children():
        _find_named(c, name, out)
    return out


func _first_named(n: Node, name: String) -> Node:
    var all := _find_named(n, name)
    return all[0] if not all.is_empty() else null


## The Label directly under a `Widgets.reasoned` box, or null when enabled.
func _reason_of(b: Button) -> Label:
    if b == null or b.get_parent() == null:
        return null
    return b.get_parent().get_node_or_null("Reason") as Label


# ---------------------------------------------------------------- the tally

func test_the_report_tallies_every_party_member_by_name() -> void:
    var st = _wiped()
    var screen := _mount()
    var printed: Array = _texts(screen)
    assert_true(printed.has("By raider"), "the tally has its section head")
    var table := _first_named(screen, "ByRaider")
    assert_ne(table, null, "the tally is the node named ByRaider")
    var names: Array = []
    for l in _find_named(table, "Name"):
        names.append((l as Label).text)
    assert_eq(names.size(), st.last_party.size(),
        "one name Label per party member: %s" % str(names))
    for r in st.last_party:
        assert_true(names.has(String(r.display_name)),
            "%s went and must be on the tally" % r.display_name)


func test_the_tally_is_sorted_worst_offender_first_and_agrees_with_the_log() -> void:
    var st = _wiped()
    var screen := _mount()
    var table := _first_named(screen, "ByRaider")
    var counts: Array = []
    for l in _find_named(table, "Mistakes"):
        counts.append(int((l as Label).text))
    assert_eq(counts.size(), st.last_party.size())
    for i in range(1, counts.size()):
        assert_true(int(counts[i]) <= int(counts[i - 1]),
            "mistakes must run high to low: %s" % str(counts))
    var total := 0
    for c in counts:
        total += int(c)
    assert_eq(total, int(st.last_result.mistake_count),
        "the column sums to the account's own count")
    # Every one of the twelve fell on the fixture's raid, and the row says so.
    var states: Array = []
    for l in _find_named(table, "State"):
        states.append((l as Label).text)
    assert_eq(states.count("Fallen"), int(st.last_result.casualties.size()))
    assert_eq(states.count("Stood"), int(st.last_result.survivors.size()))


func test_the_wipe_cost_is_written_per_raider_in_signed_figures() -> void:
    var st = _wiped()
    var screen := _mount()
    var table := _first_named(screen, "ByRaider")
    var hits: Dictionary = st.last_wipe_penalty
    assert_false(hits.is_empty(), "the fixture's wipe charges morale")
    var deltas: Array = []
    for l in _find_named(table, "Morale"):
        deltas.append((l as Label).text)
    assert_eq(deltas.size(), st.last_party.size())
    for d in deltas:
        assert_true(String(d).begins_with("-"),
            "a wipe delta is signed negative, never a bare number: %s" % d)


# ---------------------------------------------------------------- the loot column

func test_suggested_is_disabled_with_its_reason_on_a_wipe() -> void:
    var st = _wiped()
    assert_true(st.pending_loot.is_empty(), "a wipe drops nothing (the fixture's premise)")
    var screen := _mount()
    var b := _find_button(screen, SUGGESTED)
    assert_ne(b, null, "the control is still there, as a Button")
    assert_true(b.disabled, "…disabled, because there is nothing to give")
    var why := _reason_of(b)
    assert_ne(why, null, "docs/13 §7: a locked control states its reason in a Label")
    assert_true(why.text.contains("Nothing dropped"), why.text)
    assert_eq(_find_button(screen, "Sell all unusable  (+0 G)"), null,
        "nothing to sell means no sell-all control at all")


func test_suggested_is_enabled_on_a_clear_and_hands_everything_out() -> void:
    var st = _cleared()
    assert_false(st.pending_loot.is_empty(), "Adventure 0 pays its trinket")
    var screen := _mount()
    var b := _first_named(screen, "Suggested") as Button
    assert_ne(b, null)
    # UI-36: with drops pending the one-click default is the page's ONE commit
    # — the crimson CTA, named for what it gives; test_full_loop presses it by
    # the substring "Suggested", so the word keeps its capital.
    assert_eq(b.text, "Give as Suggested — 1 drop", b.text)
    assert_eq(b.theme_type_variation, &"ButtonCta", "the split is the crimson commit")
    assert_false(b.disabled, "with loot pending the one-click default is live")
    assert_eq(_reason_of(b), null, "an enabled control carries no reason line")
    assert_ne(_find_button(screen, "Give"), null, "the hand-out row has its override")
    assert_true(screen.default_focus() == b, "UI-33: the split is where the keyboard lands on a clear")
    b.pressed.emit()
    assert_true(st.pending_loot.is_empty(), "Suggested gives everything out")
    var after := _find_button(screen, SUGGESTED)
    assert_ne(after, null, "the control is rebuilt with the rows, as the plain control")
    assert_true(after.disabled, "…and now says why it cannot be pressed again")
    assert_true(_reason_of(after).text.contains("Nothing left to hand out"),
        _reason_of(after).text)
    assert_eq(screen.default_focus(), null, "nothing to commit: the router falls back to reading order")


func test_both_exits_stay_enabled_and_the_asserted_strings_hold() -> void:
    _wiped()
    var screen := _mount()
    for text in ["Return to town", "Back to the board"]:
        var b := _find_button(screen, text)
        assert_ne(b, null, text)
        assert_false(b.disabled, "%s is always open" % text)
        assert_eq(b.focus_mode, Control.FOCUS_ALL)
    var printed := "\n".join(PackedStringArray(_texts(screen)))
    for must in ["Rounds", "Mistakes", "What happened", "The fallen", "Loot"]:
        assert_true(printed.contains(must), must)
    assert_false(printed.contains("See how it ended"))


# ---------------------------------------------------------------- stamps, sigil, strip

func test_the_wipe_headline_and_the_fallen_are_leaning_stamps() -> void:
    var st = _wiped()
    var screen := _mount()
    var head := _first_named(screen, "Headline") as Control
    assert_ne(head, null, "the wipe headline is the kit's stamp box")
    assert_true(head is PanelContainer)
    var word := head.get_child(0) as Label
    # The word is the outcome's (a loss is "It's a wipe!", a soft wipe "Called
    # it. Barely." …); which one the fixture's seed lands on is the sim's.
    assert_eq(word.text, screen._outcome_word(st.last_result), "the text stays a Label")
    assert_true(word.text.length() > 0)
    assert_true(absf(head.rotation_degrees) >= 2.0 and absf(head.rotation_degrees) <= 7.0,
        "docs/13 §7: rotated 2-7°, got %f" % head.rotation_degrees)
    # The strip's first page carries four of the party, the fallen among them
    # each stamped — counted off the party's own order, not off a total wipe.
    var strip := _first_named(screen, "RosterStrip")
    assert_ne(strip, null, "the party rides in Cards.roster_strip")
    var stamps: Array = _find_named(strip, "Stamp")
    var fallen_ids := {}
    for c in st.last_result.casualties:
        fallen_ids[String(c.raider.id)] = true
    var on_page := 0
    for i in mini(4, st.last_party.size()):
        if fallen_ids.has(String(st.last_party[i].id)):
            on_page += 1
    assert_true(on_page > 0, "the fixture's raid loses somebody on its first page")
    assert_eq(stamps.size(), on_page, "one FALLEN stamp per fallen card on the page")
    for s in stamps:
        assert_eq(((s as Control).get_child(0) as Label).text, "FALLEN")
        assert_true(absf((s as Control).rotation_degrees) >= 2.0)


func test_the_pager_is_the_kit_pair_not_a_stacked_column() -> void:
    _wiped()
    var screen := _mount()
    var strip := _first_named(screen, "RosterStrip")
    var prev: Array = _find_named(strip, "PagerPrev")
    var next: Array = _find_named(strip, "PagerNext")
    assert_eq(prev.size(), 1)
    assert_eq(next.size(), 1)
    var p := prev[0] as Control
    var n := next[0] as Control
    assert_true(is_equal_approx(p.position.y, n.position.y),
        "the arrows sit on one line, either side of the cards, not one over the other")
    assert_true(p.position.x < n.position.x)
    for arrow in [p, n]:
        assert_eq((arrow as BaseButton).focus_mode, Control.FOCUS_ALL)
        assert_false((arrow as BaseButton).disabled)


func test_the_day_line_carries_the_rank_sigil_and_keeps_its_label() -> void:
    var st = _wiped()
    var screen := _mount()
    var sigil := _first_named(screen, "RankSigil") as TextureRect
    assert_ne(sigil, null, "COMBAT-18: the rank sigil files the day line")
    assert_ne(sigil.texture, null)
    var expected := "Day %d  ·  %s" % [st.day, st.rank_name()]
    assert_true(_texts(screen).has(expected), "the Label the tests read is untouched: " + expected)


# ---------------------------------------------------------------- story rows

func _mistake(log, actor_name: String, actor_id: String, round_no: int,
        caused_by: String = "", depth: int = 0, joke: String = ""):
    var r = preload("res://sim/model/Raider.gd").new()
    r.id = actor_id
    r.display_name = actor_name
    r.class_id = Enums.class_from_key("rogue")
    var combatant = preload("res://sim/model/Combatant.gd").create(r, _state().content, 0)
    return log.emit_mistake(round_no, Enums.Phase.DPS, combatant, "MIS_AGGRO",
        "Pulled Aggro Off the Tank", Enums.severity_key(Enums.Severity.SEVERE),
        caused_by, depth, "MIS_AGGRO.01", joke)


func test_a_knock_on_mistake_is_indented_under_the_one_that_set_it_up() -> void:
    _wiped()
    var screen := _mount()
    var log = EventLog.new()
    var parent = _mistake(log, "Greg", "id-greg", 1)
    var child = _mistake(log, "Tiny", "id-tiny", 2, Results._mistake_id(parent), 1)
    screen._mistake_index = Results._index_mistakes([parent, child])
    var row: Control = screen._story_row(child)
    _made.append(row)
    assert_true(row is MarginContainer, "a cascaded row is indented")
    assert_eq(int(row.get_theme_constant("margin_left")), 18, "18px per link of the chain")
    var texts: Array = _texts(row)
    assert_eq(texts.size(), 2, str(texts))
    assert_true(String(texts[1]).begins_with("→ set up by Greg's Pulled Aggro Off the Tank"),
        String(texts[1]))
    # A first-order mistake is not indented and prints no cause.
    var plain: Control = screen._story_row(parent)
    _made.append(plain)
    assert_false(plain is MarginContainer)
    assert_eq(_texts(plain).size(), 1, "header only, no joke, no cause")


func test_a_story_row_carries_the_log_glyph_not_a_dot() -> void:
    _wiped()
    var screen := _mount()
    var log = EventLog.new()
    var e = _mistake(log, "Greg", "id-greg", 1, "", 0, "Greg chased a number.")
    var row: Control = screen._story_row(e)
    _made.append(row)
    var texts: Array = _texts(row)
    assert_eq(texts.size(), 2, "test_log_player's contract: the header and the quote")
    var line: Control = row.get_child(0)
    assert_true(line is HBoxContainer)
    var badge := line.get_child(0)
    assert_true(badge is TextureRect, "COMBAT-06: the badge is the icon grid's glyph")
    assert_ne((badge as TextureRect).texture, null)


func test_the_comedy_line_switch_names_one_of_its_readings() -> void:
    # Q12b was ruled (docs/15 BL-139): the line stays on every page as the
    # notice's epigraph. The constant records which reading ships.
    assert_true(["epigraph", "as_built", "promise"].has(Results.COMEDY_LINE), Results.COMEDY_LINE)
    assert_eq(Results.COMEDY_LINE, "epigraph", "BL-139's reading is the shipped one")
    assert_eq(Results.EPIGRAPH_EYEBROW, "The notice said:")


# ---------------------------------------------------------------- the goldens on the page

## A state whose last attempt is one of the golden scenarios, re-run (the sim
## is a pure function of the roster, the encounter and the seed, and the
## goldens pin that), so the page under test is a fight whose facts are known.
func _golden(name: String):
    _ensure_autoloads()
    var st = _state()
    var db = DB.load_all()
    st.reset()
    st.set_content(db)
    st.new_game("Golden Guild", 31)
    var spec: Dictionary = Scenarios.SCENARIOS[name]
    var roster: Array = Scenarios.build_roster(spec, db)
    var enc = db.encounter_at_slot(String(spec["encounter"]))
    var res = RaidSim.run(roster, enc, db, int(spec["seed"]))
    st.last_result = res
    st.last_party = roster.duplicate()
    st.selected_encounter_id = String(enc.id)
    return st


func test_the_wipe_headline_names_the_culprit_and_the_mistake() -> void:
    # LOOP-12 / docs/01 §6.4: "a post-mortem naming the raider at fault, the
    # specific mistake". The golden's cause is known ("It traces back to
    # Cindy — Healed a Corpse, round 4"); the sentence is read off the same
    # entry, so this asserts the fact, not the golden's wording.
    var st = _golden("e5_miserable_commons")
    var res = st.last_result
    assert_false(res.cleared(), "the worst case is a loss")
    var cause: Dictionary = res.wipe_cause
    assert_false(cause.is_empty(), "the sim named a culprit for this golden")
    var e = res.log.entries[int(cause["entry_seq"])]
    var screen := _mount()
    var line := _first_named(screen, "WipeCause") as Label
    assert_ne(line, null, "the sentence under the stamp is the Label named WipeCause")
    assert_true(line.text.begins_with("Round %d: " % int(e.round_no)), line.text)
    assert_true(line.text.contains(String(e.actor_name)), "names the actor: " + line.text)
    assert_true(line.text.contains(String(e.mistake_name())), "names the mistake: " + line.text)
    assert_eq(String(cause["mistake_type"]), String(e.mistake.get("type", "")),
        "the entry the report read is the one the cause names")
    var quip := String(e.joke()).strip_edges()
    if not quip.is_empty():
        assert_true(line.text.contains(quip), "and quotes the excuse: " + line.text)
    # The culprit's tally row wears the stamp, nobody else's does.
    var stamps: Array = _find_named(screen, "CulpritStamp")
    assert_eq(stamps.size(), 1, "one stamp on the tally")
    var row: Node = stamps[0].get_parent()
    assert_eq((row.get_node("Name") as Label).text, String(e.actor_name),
        "…on the row of the raider the wipe traces back to")
    assert_eq(((stamps[0] as Control).get_child(0) as Label).text, "WIPE")


func test_a_loss_nobody_caused_says_so() -> void:
    var st = _wiped()
    st.last_result.wipe_cause = {}
    var screen := _mount()
    var line := _first_named(screen, "WipeCause") as Label
    assert_ne(line, null)
    assert_eq(line.text, Results.NOBODY_LINE)
    assert_eq(_find_named(screen, "CulpritStamp").size(), 0, "no culprit, no stamp")


func test_a_clear_tallies_the_reputation_the_town_heard() -> void:
    # LOOP-13: the "Reputation +N" cell is the same pure call GameState's
    # award makes, fed the clear's number (the first here).
    var st = _golden("e5_first_clear")
    assert_true(st.last_result.cleared(), "the first-clear golden clears")
    var enc = st.content.encounter(st.last_result.encounter_id)
    var screen := _mount()
    var want: int = Reputation.award_for(enc, 1, st.highest_unlocked_tier(), st.stalled)
    assert_true(want > 0, "E5's first clear pays reputation")
    assert_true(_texts(screen).has("Reputation +%d" % want),
        "the tally has the cell: %s" % str(_texts(screen)))
    assert_eq(Results.reputation_earned(st, enc), want)
    assert_eq(_find_named(screen, "WipeCause").size(), 0, "a clear has no cause sentence")


func test_a_wipe_tallies_no_reputation_cell() -> void:
    _wiped()
    var screen := _mount()
    for t in _texts(screen):
        assert_false(String(t).begins_with("Reputation +"), "a wipe pays nothing and prints nothing: " + String(t))


# ---------------------------------------------------------------- try again

func test_try_again_is_the_wipes_default_focus_and_re_chalks_the_encounter() -> void:
    # UI-37 / docs/13 §11.4 ("`Try again` is left and default-focused"), the
    # attempts ruling: the button is the crimson commit with docs/01's cost
    # under it, and pressing it lands on prep with the same encounter pinned.
    # Driven through the AUTOLOAD router, which is the one the screen uses.
    assert_true(Results.TRY_AGAIN, "the attempts ruling: unlimited, so Try again ships")
    var st = _wiped()
    var enc_id: String = st.last_result.encounter_id
    var host := _host()
    var r = _root.get_node("ScreenRouter")
    r.register_host(host)
    assert_true(r.goto(RESULTS))
    var screen: Control = r.current_screen()
    var retry := _find_button(screen, "Try again")
    assert_ne(retry, null, "the wipe page offers Try again")
    assert_false(retry.disabled)
    assert_eq(retry.focus_mode, Control.FOCUS_ALL)
    assert_true(String(retry.theme_type_variation).begins_with("ButtonCta"), "crimson: the page's one commit")
    assert_true(screen.default_focus() == retry, "…and default-focused")
    assert_true(Router.initial_focus_target(screen) == retry, "the router asks the screen first")
    assert_true(_texts(screen).has(Results.TRY_AGAIN_COST), "the cost line under it, as a Label")
    for text in ["Return to town", "Back to the board"]:
        assert_ne(_find_button(screen, text), null, text + " still stands beside it")
    st.selected_encounter_id = ""
    retry.pressed.emit()
    assert_eq(r.current_path(), RAID_PREP, "Try again lands on prep")
    assert_eq(String(st.selected_encounter_id), enc_id, "with the same encounter pinned")
    assert_true("
".join(PackedStringArray(_texts(r.current_screen()))).contains("Verdict"),
        "prep is built on it")
    r.register_host(null)


func test_a_clear_offers_no_try_again() -> void:
    _cleared()
    var screen := _mount()
    assert_eq(_find_button(screen, "Try again"), null, "a clear is not tried again from here")
