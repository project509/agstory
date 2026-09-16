extends "res://tests/TestCase.gd"
## W6-AUD-BIND — the hooks docs/13 §12.4 names fire at their trigger sites, and
## the three defaults AUDIO-11 records hold (reduced motion never silences;
## Instant/skip fires no per-line hook; reduced effects and the comedy brake do
## not touch audio). Every assertion reads `Audio.tape`, never the driver: a
## headless run has no output device, so the tape is the only ear this suite
## has (M6-AUD-04's acceptance sentence).
##
## The RaidPrep cases mount the real screen through the autoload router, as
## Boot does (LESSONS), and press its Buttons — a test that calls `_on_depart()`
## still passes when the button was never connected.
##
## §8 of build/plan/handoff-W6-AUD-BIND.md appends the Widgets / Board /
## Market / Tavern cases to this file when the orchestrator applies those lines.

const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const PrepScript = preload("res://game/screens/RaidPrep.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Fixture = preload("res://tools/fixture_reference.gd")

const PREP := "res://game/screens/RaidPrep.tscn"
const PREP_SOURCE := "res://game/screens/RaidPrep.gd"
const AUDIO_SOURCE := "res://game/core/Audio.gd"
const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const TOWN := "res://game/screens/Town.tscn"

## The settings a hook must NOT read (AUDIO-11's three defaults).
const UNTOUCHED_KEYS := ["reduced_motion", "reduced_effects", "comedy_brake"]

var _db = null
var _made: Array = []
var _host: Control = null
var _saved: Dictionary = {}


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []
    _host = null
    _saved = {}
    var s := _settings()
    if s != null:
        for key in UNTOUCHED_KEYS:
            _saved[key] = s.get_value(String(key))
    var a := _audio()
    if a != null:
        a.ensure_wired()
        a.debug_tape = true
        a.tape = []


func after_each() -> void:
    var s := _settings()
    if s != null:
        for key in _saved:
            s.set_value(String(key), _saved[key])
    var a := _audio()
    if a != null:
        a.debug_tape = false
        a.tape = []
        a._first_change = false
        a.advance_duck(999.0)
        a.apply_levels()
    # The autoloads outlive this file (LESSONS): put the state back, content
    # included, or another file's empty-roster assertion depends on order.
    var st = _state()
    if st != null:
        st.reset()
        st.set_content(null)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


# ---------------------------------------------------------------- helpers

func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _audio() -> Node:
    var r := _root()
    return r.get_node_or_null("Audio") if r != null else null


func _settings() -> Node:
    var r := _root()
    return r.get_node_or_null("GameSettings") if r != null else null


func _state() -> Node:
    var r := _root()
    return r.get_node_or_null("GameState") if r != null else null


func _router() -> Node:
    var r := _root()
    return r.get_node_or_null("ScreenRouter") if r != null else null


## How many times `hook` is on the tape.
func _count(hook: String) -> int:
    var n := 0
    for row in _audio().tape:
        if String(row["hook"]) == hook:
            n += 1
    return n


## The tape's hooks in order, for an ordering assertion.
func _hooks() -> Array:
    var out: Array = []
    for row in _audio().tape:
        out.append(String(row["hook"]))
    return out


func _autoloads() -> void:
    var root := _root()
    if root.get_node_or_null("GameState") == null:
        var st = GameStateScript.new()
        st.name = "GameState"
        root.add_child(st)
        _made.append(st)
    if root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        root.add_child(rt)
        _made.append(rt)
    if root.get_node_or_null("GameSettings") == null:
        var gs = SettingsScript.new()
        gs.name = "GameSettings"
        root.add_child(gs)
        _made.append(gs)


## The reference guild (tools/fixture_reference.gd): twelve raiders, the Tier 1
## main boss selected, so prep opens with twelve chalked at a cap of twelve.
func _fixture_state():
    _autoloads()
    var st = _state()
    st.reset()
    Fixture.apply(st, _db, false)
    return st


## Mount through the REAL autoload router, as Boot does (LESSONS).
func _mount_prep():
    var root := _root()
    var r = _router()
    if _host == null:
        _host = Control.new()
        _host.size = Vector2(1536, 1024)
        root.add_child(_host)
        _made.append(_host)
        r.register_host(_host)
    assert_true(r.goto(PREP), "could not open %s" % PREP)
    # The mount's own screen change rings ui.tab; every case below is about
    # what happens AFTER the screen is on the desk.
    _audio().tape = []
    return r.current_screen()


func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out


func _button_named(n: Node, text: String):
    for b in _buttons(n):
        if (b as Button).text == text:
            return b
    return null


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


# ------------------------------------------------ the Instant / skip gate

func test_a_press_marked_not_live_is_dropped_before_the_tape() -> void:
    # docs/13 §11.2: Instant "has no reveal"; a skip lands every remaining line
    # in one frame. A per-line hook fired then is a wall of stamps, so the log's
    # call sites pass `{"live": _live}` and the gate in Audio.play drops it.
    var a := _audio()
    a.play("ui.stamp", {"live": false})
    assert_eq(a.tape.size(), 0, "live == false must tape nothing")
    a.play("ui.blot", {"live": false})
    assert_eq(a.tape.size(), 0, "the blot rides the same gate")
    a.play("ui.stamp", {"live": true})
    assert_eq(a.tape.size(), 1, "live == true tapes one")
    a.play("ui.stamp")
    assert_eq(a.tape.size(), 2, "and a call with no key is live by default")
    # The wipe's tail passes no key and fires at Instant too: one duck, once.
    a.play("ui.silence")
    assert_eq(_count("ui.silence"), 1, "ui.silence is not per-line and is never gated")
    assert_true(a.is_ducked())


func test_an_unknown_hook_is_still_refused_ahead_of_the_gate() -> void:
    # The gate must not become a way to hide a typo'd name. (push_error expected.)
    var a := _audio()
    a.play("ui.not_a_hook", {"live": false})
    a.play("ui.not_a_hook", {"live": true})
    assert_eq(a.tape.size(), 0)


# ------------------------------------------------------- AUDIO-11 defaults

func test_reduced_motion_never_silences_a_hook() -> void:
    # docs/13 §13's reduced-motion row disables the page turn and the ledger
    # close as MOTION and keeps the stamps landing; sound is not motion, so the
    # three sounds play. The page turn and the ledger close are exactly what a
    # reduced-motion player gets of those two events.
    var a := _audio()
    var s := _settings()
    s.set_value("reduced_motion", true)
    for hook in ["ui.page_turn", "ui.ledger_close", "ui.stamp", "ui.chalk"]:
        a.play(String(hook))
    assert_eq(a.tape.size(), 4, "reduced motion must not drop a hook")


func test_reduced_effects_and_the_comedy_brake_do_not_touch_audio() -> void:
    # The brake changes PACING, and pacing is what the hooks follow; reduced
    # effects gates the world layer's glow and particles, not the desk's sound.
    var a := _audio()
    var s := _settings()
    s.set_value("reduced_effects", true)
    s.set_value("comedy_brake", not bool(s.get_value("comedy_brake")))
    for hook in ["ui.stamp", "ui.blot", "ui.seal"]:
        a.play(String(hook))
    assert_eq(a.tape.size(), 3, "neither setting may drop a hook")
    # And the mechanism: the autoload reads none of the three keys at all.
    var src := FileAccess.get_file_as_string(AUDIO_SOURCE)
    assert_false(src.is_empty(), "Audio.gd must be readable")
    for key in UNTOUCHED_KEYS:
        assert_false(src.contains('"%s"' % key),
            "Audio.gd must not read the %s setting" % key)


func test_the_autoload_runs_always_so_a_pause_cannot_freeze_a_duck() -> void:
    # The duck's restore runs in `_process`; a future pause menu must not leave
    # Master at -60 dB. The players already ran ALWAYS; now the node does too.
    var a := _audio()
    assert_eq(a.process_mode, Node.PROCESS_MODE_ALWAYS)


# ------------------------------------------------------- the event binds

func test_a_day_advance_closes_the_ledger_once() -> void:
    # docs/13 §12.4: `ui.ledger_close` — "Day advance", "start of the close".
    # Bound to the EVENT (AUDIO-08): the desk does not move, so the sound is
    # the close; every Day Tick goes through GameState.advance_day().
    var a := _audio()
    _autoloads()
    var st = _state()
    assert_true(st.day_advanced.is_connected(Callable(a, "_on_day_advanced")),
        "Audio must subscribe to GameState.day_advanced itself")
    st.advance_day()
    assert_eq(_count("ui.ledger_close"), 1, "one Day Tick, one ledger close")
    assert_eq(a.tape.size(), 1, "and nothing else rings on a day advance")
    st.advance_day()
    assert_eq(_count("ui.ledger_close"), 2)


func test_the_first_screen_of_a_session_is_silent() -> void:
    # AUDIO-15: Boot routes to the main menu on the first frame, before the
    # player has touched anything; a sound the player did not cause is worse
    # than a missing one. Every change after that one is a press, and sounds.
    var a := _audio()
    _autoloads()
    var r = _router()
    assert_true(r.screen_changed.is_connected(Callable(a, "_on_screen_changed")))
    a._first_change = true
    r.screen_changed.emit(MAIN_MENU)
    assert_eq(a.tape.size(), 0, "the boot transition tapes nothing")
    r.screen_changed.emit(TOWN)
    assert_eq(_count("ui.tab"), 1, "Continue is a press, and sounds")
    r.screen_changed.emit(MAIN_MENU)
    assert_eq(_count("ui.tab"), 2, "and so is every later change")


# ------------------------------------------------------- RaidPrep's hooks

func test_a_chalk_stroke_sounds_once_on_the_clear_and_once_on_the_fill() -> void:
    # docs/13 §12.4: `ui.chalk` on a ChalkSlot fill / clear, "leading edge of
    # the stroke" — both branches of _toggle, before the redraw.
    _fixture_state()
    var view = _mount_prep()
    var ids: Array = view.chalked_ids()
    assert_eq(ids.size(), 12, "the fixture opens with twelve chalked")
    var who := String(ids[ids.size() - 1])
    view._toggle(who)
    assert_eq(_count("ui.chalk"), 1, "clearing a slot is one stroke")
    assert_eq(view.chalked_ids().size(), 11)
    _audio().tape = []
    view._toggle(who)
    assert_eq(_count("ui.chalk"), 1, "filling it again is one stroke")
    assert_eq(_count("ui.chalk_bad"), 0, "and the comp going VALID squeaks nothing")
    assert_eq(view.chalked_ids().size(), 12)


func test_a_chalk_refused_at_the_cap_squeaks_and_does_not_stroke() -> void:
    # The fixture's twelve fill a twelve-cap, so a thirteenth raider on the
    # bench is the gesture: the slot will not take, and the squeak says so
    # (AUDIO-04's chalk_bad row — the only other bad-chalk gesture).
    var st = _fixture_state()
    # Morale 1: the opening suggestion is the twelve highest, so the
    # thirteenth stays on the bench.
    var extra = Fixture._make_card(_db, {"name": "Thirteenth", "class": "rogue",
        "level": 1, "morale": 1}, 12)
    st.roster.append(extra)
    var view = _mount_prep()
    assert_eq(view.chalked_ids().size(), 12, "still twelve of twelve")
    assert_false(String(extra.id) in view.chalked_ids(), "the thirteenth is on the bench")
    view._toggle(String(extra.id))
    assert_eq(_count("ui.chalk_bad"), 1, "the refused chalk squeaks once")
    assert_eq(_count("ui.chalk"), 0, "and is not a stroke")
    assert_eq(view.chalked_ids().size(), 12, "the slot did not take")


func test_the_comp_check_turning_invalid_squeaks_once_and_only_on_the_turn() -> void:
    # docs/13 §12.4: `ui.chalk_bad` when the comp check TURNS invalid, 60 ms
    # after the slot redraw. A transition, never a state: the two HARD rows
    # are slots and tanks. Twelve of twelve with two tanks is valid; benching
    # one is the turn; benching a second is still invalid and silent; chalking
    # both back is valid again and silent.
    var st = _fixture_state()
    # The fixture's twelve carry one tank (Bork) against E5's two — its own
    # risk story, and no use for a valid->invalid turn. A second tank joins
    # the roster at morale 1 so the opening suggestion leaves him benched.
    var second_tank = Fixture._make_card(_db, {"name": "Second Tank",
        "class": "warrior", "level": 1, "morale": 1}, 12)
    st.roster.append(second_tank)
    var view = _mount_prep()
    # Make the opening comp valid by construction rather than by luck: bench
    # everyone (the tape does not matter yet), then chalk the tanks first.
    for id in view.chalked_ids().duplicate():
        view._toggle(String(id))
    assert_false(view._comp_ok, "nobody chalked is not a valid comp")
    var tanks: Array = []
    var others: Array = []
    for r in st.roster:
        if r.role_group(_db) == Enums.RoleGroup.TANK:
            tanks.append(String(r.id))
        else:
            others.append(String(r.id))
    assert_true(tanks.size() >= 2, "two tanks for E5's tanks_required")
    for id in tanks:
        view._toggle(String(id))
    for id in others:
        if view.chalked_ids().size() >= 12:
            break
        view._toggle(String(id))
    assert_eq(view.chalked_ids().size(), 12)
    assert_true(view._comp_ok, "twelve with the tanks is a valid comp")
    _audio().tape = []
    var first := String(others[0])
    var second := String(others[1])
    view._toggle(first)
    assert_eq(_count("ui.chalk_bad"), 1, "the comp TURNED invalid: one squeak")
    assert_eq(_count("ui.chalk"), 1, "beside the stroke itself")
    view._toggle(second)
    assert_eq(_count("ui.chalk_bad"), 1, "still invalid is not a turn")
    assert_eq(_count("ui.chalk"), 2)
    view._toggle(first)
    view._toggle(second)
    assert_eq(_count("ui.chalk_bad"), 1, "turning valid again is silent")
    assert_true(view._comp_ok)


func test_the_squeaks_delay_is_the_docs_60ms_on_a_tree_timer() -> void:
    # Off-tree (this runner never draws a frame and the screen has no tree to
    # time on) the squeak lands at once, so the wait itself is asserted the way
    # the wipe's beats are: the doc's number and the line that spends it. No
    # `await` anywhere in the screen (docs/13 §11.4's rule, applied here).
    assert_eq(PrepScript.CHALK_BAD_DELAY_MS, 60, "docs/13 §12.4: 60 ms after the slot redraw")
    var src := FileAccess.get_file_as_string(PREP_SOURCE)
    assert_true(src.contains("create_timer(float(CHALK_BAD_DELAY_MS) / 1000.0)"),
        "the squeak rides a tree timer of CHALK_BAD_DELAY_MS")
    assert_false(src.contains("await "), "RaidPrep.gd must not await")
    assert_false(src.contains("The party stands here"), "C29: the caption string is gone")


func test_depart_turns_the_page_once_at_the_press() -> void:
    # docs/13 §12.4: `ui.page_turn` — "Departure", "start of the turn". Bound
    # to the press (AUDIO-08): the desk does not move, so the sound is the
    # turn. Driven through the Button, as the milestone tests are (LESSONS).
    _fixture_state()
    var view = _mount_prep()
    var depart = _button_named(view, "Depart")
    assert_ne(depart, null, "Depart is a Button found by its text")
    assert_false(depart.disabled)
    depart.pressed.emit()
    assert_eq(_count("ui.page_turn"), 1, "one departure, one page turn")
    var hooks := _hooks()
    var page := hooks.find("ui.page_turn")
    var tab := hooks.find("ui.tab")
    assert_true(tab >= 0, "the account's screen change rings the tab")
    assert_true(page < tab, "the page turns before the account appears")
    # The attempt is a Day Tick, so the ledger closes in the same frame — the
    # doc's event, bound by subscription, and recorded in the unit's report as
    # the overlap for the designer's listen.
    assert_eq(_count("ui.ledger_close"), 1, "an attempt is one Day Tick")


func test_the_prep_board_says_nothing_about_an_empty_band() -> void:
    # LOOP C29: "The party stands here" over a band nobody stands on was a
    # screen admitting an unbuilt thing. Read the way every screen test reads:
    # Label.text.
    _fixture_state()
    var view = _mount_prep()
    var printed := "\n".join(PackedStringArray(_texts(view)))
    assert_false(printed.contains("The party stands here"))
    assert_false(printed.contains("party stands"))


# ------------------------------------------ handoff-W6-AUD-BIND §1-§7 (applied at the wave's close)

const Widgets = preload("res://game/ui/Widgets.gd")
const BOARD := "res://game/screens/AdventureBoard.tscn"
const MARKET := "res://game/screens/Market.tscn"
const TAVERN := "res://game/screens/Tavern.tscn"


func _mount_screen(path: String):
    var root := _root()
    var r = _router()
    if _host == null:
        _host = Control.new()
        _host.size = Vector2(1536, 1024)
        root.add_child(_host)
        _made.append(_host)
        r.register_host(_host)
    assert_true(r.goto(path), "could not open %s" % path)
    _audio().tape = []
    return r.current_screen()


func test_a_commit_press_seals_on_button_down_not_on_release() -> void:
    # docs/13 §12.4: `ui.seal` on "any WaxButton commit — on press, not release".
    var a := _audio()
    for b in [Widgets.cta("Depart", "12 of 12 chalked"), Widgets.cta_priced("Buy", 40),
            Widgets.wax_button("Hire")]:
        _made.append(b)
        a.tape = []
        (b as Button).button_down.emit()
        assert_eq(_count("ui.seal"), 1, "%s seals once on the press" % (b as Button).text)
        a.tape = []
        (b as Button).pressed.emit()
        assert_eq(_count("ui.seal"), 0, "and not again on the release")
    # A reasoned (disabled) commit: the engine emits no button_down for a
    # disabled Button under real input, so the bind is silent for free; what
    # this can assert headless is that the reason really disables it.
    var shut := Widgets.cta("Depart")
    var box = Widgets.reasoned(shut, "Chalk at least one raider.", null, 302)
    _made.append(box)
    assert_true(shut.disabled, "a reasoned CTA is disabled, so it never presses")


func test_an_in_screen_tab_press_rings_the_tab() -> void:
    var a := _audio()
    var row = Widgets.tab_row(["Roster", "Facilities", "Records"], 0)
    _made.append(row)
    var tabs: Array = Widgets.tabs_of(row)
    assert_eq(tabs.size(), 3)
    (tabs[1] as Button).pressed.emit()
    assert_eq(_count("ui.tab"), 1, "a tab press is a tab change")
    assert_eq(a.tape.size(), 1)


func test_pinning_a_different_notice_rings_the_row_select_once() -> void:
    _fixture_state()
    var view = _mount_screen(BOARD)
    var was := String(view._selected)
    var other := ""
    for id in view._notices.keys():
        if String(id) != was:
            other = String(id)
            break
    assert_ne(other, "", "the board has a second notice to pin")
    view._select(was)
    assert_eq(_count("ui.row_select"), 0, "re-pinning the pinned one is not a change")
    view._select(other)
    assert_eq(_count("ui.row_select"), 1, "pinning another is one row select")
    view._select(other)
    assert_eq(_count("ui.row_select"), 1)


func test_looking_at_another_candidate_rings_the_row_select_once() -> void:
    _fixture_state()
    var view = _mount_screen(TAVERN)
    var looks: Array = []
    for b in _buttons(view):
        if (b as Button).text == "Look":
            looks.append(b)
    assert_true(looks.size() >= 1, "the fixture's tavern board has a candidate not being looked at")
    (looks[0] as Button).pressed.emit()
    assert_eq(_count("ui.row_select"), 1, "looking at another candidate is one row select")
    var looking = _button_named(view, "Looking")
    assert_ne(looking, null)
    (looking as Button).pressed.emit()
    assert_eq(_count("ui.row_select"), 1, "re-looking at the same one is not a change")


func test_picking_a_sell_row_rings_the_row_select_once() -> void:
    # The Market opens on its Sell tab; every sell row is a Button whose text
    # begins "Sell " (`_sell_cell`). The shelf is rebuilt on every press, so
    # each press looks its Button up afresh by text. Whatever the opening
    # pick was, pressing a DIFFERENT row is one change and the same row again
    # is none.
    _fixture_state()
    var view = _mount_screen(MARKET)
    var names: Array = []
    for b in _buttons(view):
        var t := String((b as Button).text)
        # A slot row reads "Sell <item> — <price> G"; the "Sell all nobody can
        # wear — …" row and the "Sell — N G" confirm CTA also begin with "Sell "
        # and are sales, not picks.
        if t.begins_with("Sell ") and not t.begins_with("Sell all")                 and not t.begins_with("Sell — ") and not (t in names):
            names.append(t)
    assert_true(names.size() >= 2, "the fixture's market has two sell rows (%d found)" % names.size())
    _button_named(view, String(names[0])).pressed.emit()
    var after_first := _count("ui.row_select")
    assert_true(after_first <= 1, "one press is at most one row select")
    _button_named(view, String(names[1])).pressed.emit()
    assert_eq(_count("ui.row_select"), after_first + 1, "a different row is one change")
    _button_named(view, String(names[1])).pressed.emit()
    assert_eq(_count("ui.row_select"), after_first + 1, "the same row again is not a change")
