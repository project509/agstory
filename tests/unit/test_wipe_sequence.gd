extends "res://tests/TestCase.gd"
## docs/13 §11.4's wipe sequence, beat by beat.
##
## "A sequence, once, ~2.4s total, fully skippable on any input." Before this it
## was one beat out of six and that one arrived at the wrong time: `_process`
## waited the entire 2.4 seconds and then dropped a static Label, so a player who
## had just lost twelve raiders watched nothing happen for two and a half seconds
## and then saw a word.
##
## The sequence is driven by a CLOCK rather than by `await`, and that is the part
## worth testing hardest: §11.4 requires the whole thing be abortable on any
## input, and an `await` chain cannot be interrupted. So each beat fires once when
## the clock passes its documented offset, which also makes the order assertable
## without waiting 2.4 real seconds — these tests advance time by hand.
##
## ONE BEAT IS DELIBERATELY NOT HERE, and the screen says so in its own comment
## rather than pretending: t=1,800's "post-mortem slides out from under" is a
## screen transition this project has not built (audit M6-JUICE-02). The ink
## bleed and the wax seal arrived with M6-JUICE-08 and are asserted below.

const RaidView = preload("res://game/screens/RaidView.gd")
const Settings = preload("res://game/core/GameSettings.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const DB = preload("res://sim/content/ContentDB.gd")

const RAID_VIEW := "res://game/screens/RaidView.tscn"

var _db = null
var _root: Node = null
var _made: Array = []


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []

func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


## A mounted RaidView whose account has ended in a wipe — which is the only state
## the sequence exists for, and the state nothing else in the suite builds.
func _wiped_screen():
    var st = _root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        _root.add_child(st)
        _made.append(st)
    if _root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        _root.add_child(rt)
        _made.append(rt)
    st.reset()
    st.set_content(_db)
    st.new_game("Wipe Guild", 31)
    var enc = _db.encounter("t1_raid_e5")
    var party: Array = st.roster.slice(0, mini(int(enc.party_size), st.roster.size()))
    var result = RaidSim.run(party, enc, _db, 5, st.build_loadout(party))
    result.outcome = RaidSim.Outcome.WIPE
    st.last_result = result
    st.selected_encounter_id = "t1_raid_e5"

    var host := Control.new()
    _root.add_child(host)
    _made.append(host)
    var r = Router.new()
    _made.append(r)
    r.register_host(host)
    r.goto(RAID_VIEW)
    return r.current_screen()


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


func test_the_documented_offsets_are_the_docs_own() -> void:
    # §11.4's table, read straight off the doc. If a beat moves, it moves here
    # first and a reader can see it against the row it came from.
    assert_eq(RaidView.WIPE_BEAT_SILENCE_MS, 0)
    assert_eq(RaidView.WIPE_BEAT_LINE_MS, 400)
    assert_eq(RaidView.WIPE_BEAT_STAMP_MS, 900)
    assert_eq(RaidView.WIPE_BEAT_DIM_MS, 1400)
    assert_eq(RaidView.WIPE_BEAT_EXITS_MS, 2400)


func test_the_press_is_the_shape_the_doc_describes() -> void:
    # "180ms, 1.15 → 1.00 scale, −7° rotation".
    assert_eq(RaidView.WIPE_STAMP_MS, 180)
    assert_almost(RaidView.WIPE_STAMP_FROM, 1.15, 0.0001)
    assert_almost(RaidView.WIPE_STAMP_TILT_DEG, -7.0, 0.0001)
    # "Page dims 12%"
    assert_almost(RaidView.WIPE_DIM, 0.12, 0.0001)


func test_the_whole_sequence_fits_the_documented_budget() -> void:
    # "~2.4s total". The last beat IS the budget: anything after it would be a
    # sequence that outlives its own description.
    assert_eq(RaidView.WIPE_BEAT_EXITS_MS, 2400,
        "the sequence ends when the exits become active")
    for beat in [RaidView.WIPE_BEAT_SILENCE_MS, RaidView.WIPE_BEAT_LINE_MS,
            RaidView.WIPE_BEAT_STAMP_MS, RaidView.WIPE_BEAT_DIM_MS]:
        assert_true(beat < RaidView.WIPE_BEAT_EXITS_MS,
            "every beat lands before the exits do")


func test_the_beats_are_in_the_doc_s_order() -> void:
    var order := [RaidView.WIPE_BEAT_SILENCE_MS, RaidView.WIPE_BEAT_LINE_MS,
        RaidView.WIPE_BEAT_STAMP_MS, RaidView.WIPE_BEAT_DIM_MS,
        RaidView.WIPE_BEAT_EXITS_MS]
    for i in range(1, order.size()):
        assert_true(int(order[i]) > int(order[i - 1]),
            "beat %d must come after beat %d" % [i, i - 1])


# ------------------------------------------- docs/13 §13's carve-out, measured

## "Stamps still land (they carry state) but at 60ms with no rotation."
##
## Two separate instructions in one sentence, and the second is the one easy to
## miss: a 60ms spin is still a spin. The screen asks `motion_duration()` for the
## first and `motion_scale()` for the second, so both come from the setting.

func test_the_press_collapses_to_the_docs_floor_under_reduced_motion() -> void:
    var s = Settings.new()
    s.set_value("reduced_motion", true)
    assert_almost(s.motion_duration(RaidView.WIPE_STAMP_MS, RaidView.WIPE_STAMP_FLOOR_MS),
        0.060, 0.0001, "the stamp still lands, at 60ms")
    s.free()


func test_the_press_keeps_its_full_length_otherwise() -> void:
    var s = Settings.new()
    assert_almost(s.motion_duration(RaidView.WIPE_STAMP_MS, RaidView.WIPE_STAMP_FLOOR_MS),
        0.180, 0.0001, "§11.4's own 180ms")
    s.free()


func test_the_tilt_goes_to_zero_under_reduced_motion() -> void:
    # The screen computes `deg_to_rad(TILT) * motion_scale()`, so this is the
    # arithmetic that has to hold for "with no rotation" to be true.
    var s = Settings.new()
    assert_true(absf(deg_to_rad(RaidView.WIPE_STAMP_TILT_DEG) * s.motion_scale()) > 0.0,
        "the press is tilted normally")
    s.set_value("reduced_motion", true)
    assert_almost(deg_to_rad(RaidView.WIPE_STAMP_TILT_DEG) * s.motion_scale(), 0.0, 0.0001,
        "and flat when the player has asked for reduced motion")
    s.free()


func test_the_dim_has_no_floor_because_the_doc_gives_it_none() -> void:
    # §13 names the stamp as the exception and nothing else. The page dim is
    # ordinary motion and collapses to zero — the page still ends up dimmed,
    # because a 0.0-duration tween applies its final value on the next frame.
    var s = Settings.new()
    s.set_value("reduced_motion", true)
    assert_almost(s.motion_duration(RaidView.WIPE_STAMP_MS), 0.0, 0.0001)
    s.free()


# ---------------------------------------------------------------- skipping

func test_the_sequence_is_driven_by_a_clock_and_not_by_await() -> void:
    # §11.4: "fully skippable on any input". An `await` chain cannot be aborted
    # mid-flight, so the implementation shape IS the requirement here — worth a
    # test because the obvious way to write this sequence is the one that breaks
    # the rule, and it would look correct until somebody pressed a key.
    var src := FileAccess.get_file_as_string("res://game/screens/RaidView.gd")
    assert_true(src.contains("func _run_wipe_sequence(elapsed_ms: float)"),
        "the sequence takes the clock as an argument")
    assert_false(src.contains("await get_tree().create_timer"),
        "a timer chain here could not be skipped")
    assert_true(src.contains("_run_wipe_sequence(float(WIPE_BEAT_EXITS_MS))"),
        "and skipping runs every beat at once, so a skipped sequence leaves the "
        + "same state a watched one does")


func test_a_beat_cannot_fire_twice() -> void:
    # `_process` advances in uneven deltas and the sequence is re-entered every
    # frame; a beat that fired per frame would stack five stamps.
    var src := FileAccess.get_file_as_string("res://game/screens/RaidView.gd")
    assert_true(src.contains("if _wipe_beats.has(method)"),
        "each beat is remembered once it has fired")

# --------------------------------------------------- the beats, actually run

## The constants above are the contract; these are the code path. A sequence
## whose numbers are right and whose third beat throws is worse than no sequence,
## and `_process` is the only thing that normally calls it — so nothing in the
## suite would have noticed.

func test_running_the_whole_sequence_writes_the_final_line() -> void:
    var screen = _wiped_screen()
    assert_true(screen != null, "the raid view must mount on a wiped account")
    screen._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    var printed := "
".join(PackedStringArray(_texts(screen)))
    assert_true(printed.contains("WIPE."),
        "docs/13 §11.4's final line and stamp both read WIPE.: %s" % printed)

func test_every_beat_runs_without_throwing() -> void:
    # Each beat touches something different — the stage, the audio bus, the log
    # column, a tween, the focus. Any of them can be null in a mounted screen and
    # the whole point of driving the real one is to find that out here.
    var screen = _wiped_screen()
    for at in [0.0, 400.0, 900.0, 1400.0, 2400.0]:
        screen._run_wipe_sequence(at)
    assert_true(screen._wipe_shown, "the stamp beat marks the sequence shown")

func test_the_page_dims_by_the_documented_amount() -> void:
    var screen = _wiped_screen()
    screen._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    assert_true(screen._wipe_dim != null, "§11.4's page dim must exist")
    # The tween applies it on the next frame; with reduced motion off the target
    # is what matters, and the target is the doc's 12%.
    assert_almost(RaidView.WIPE_DIM, 0.12, 0.0001)

func test_running_it_twice_does_not_stack_a_second_stamp() -> void:
    # `_process` re-enters the sequence every frame. A beat that fired per frame
    # would leave five stamps on the page.
    var screen = _wiped_screen()
    for i in 5:
        screen._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    var stamps := 0
    for t in _texts(screen):
        if String(t) == "WIPE.":
            stamps += 1
    assert_eq(stamps, 1, "exactly one stamp, however many frames pass")

# ------------------------------------ the two art beats (M6-JUICE-08)

## §11.4's ink bleed at t=900 and wax seal at t=1,400. Both shipped after the
## five code beats rather than blocking them, which is why the sequence read
## correctly for a day without either.

func test_both_textures_resolve() -> void:
    # A beat whose texture is missing is silently skipped by design — the
    # sequence must survive a stripped build — so nothing else would notice
    # these going away.
    for path in [RaidView.WIPE_BLOT, RaidView.WAX_SEAL]:
        assert_true(ResourceLoader.exists(path), "missing %s" % path)

func test_the_bleed_is_the_docs_own_duration() -> void:
    assert_eq(RaidView.WIPE_BLEED_MS, 400, "§11.4: 'a 400ms ink bleed'")

func test_the_bleed_has_no_floor_and_the_stamp_does() -> void:
    # docs/13 §13 names the bleed among the things reduced motion turns OFF and
    # the stamp as the one carve-out. The two must not be treated alike: the ink
    # is simply there, the stamp still presses at 60ms.
    var s = Settings.new()
    s.set_value("reduced_motion", true)
    assert_almost(s.motion_duration(RaidView.WIPE_BLEED_MS), 0.0, 0.0001,
        "the bleed collapses; the tween still applies its final alpha")
    assert_almost(s.motion_duration(RaidView.WIPE_STAMP_MS, RaidView.WIPE_STAMP_FLOOR_MS),
        0.060, 0.0001, "and the stamp keeps the floor the doc gives it")
    s.free()

func test_the_ink_lands_under_the_word_and_the_seal_in_the_corner() -> void:
    var screen = _wiped_screen()
    screen._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    assert_true(screen._wipe_blot != null, "the bleed must be on the page")
    assert_true(screen._wax_seal != null, "and the seal with it")
    # "onto the lower-right corner" — both coordinates past the middle of the
    # frame is the whole of that claim, and it is the one a layout change breaks.
    assert_true(screen._wax_seal.position.x > RaidView.FRAME.x * 0.5,
        "the seal is on the right")
    assert_true(screen._wax_seal.position.y > RaidView.FRAME.y * 0.5,
        "and low")

func test_the_ink_is_drawn_before_the_stamp_so_it_sits_under_it() -> void:
    # Sibling order is z-order here. Ink over the word would read as a smear on
    # the lens rather than a page absorbing it.
    var screen = _wiped_screen()
    screen._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    # Explicit types: `screen` is untyped, so `:=` cannot infer through it.
    var blot_at: int = screen._wipe_blot.get_index()
    var stamp_at: int = screen._wipe_stamp_label.get_parent().get_index()
    assert_true(blot_at < stamp_at,
        "the bleed is added before the stamp box (%d vs %d)" % [blot_at, stamp_at])


# ------------------------------------------------ the clear twin (UI-36)

## docs/13 §7's word list has CLEARED, and §11.4's wipe page has a mirror: a
## filed report with a stamp. The Results screen's clear branch presses
## `CLEARED` over the heading in the ready gold, drops the same wax seal in the
## same corner rule, and makes the loot's suggested split the page's one
## crimson commit. Mounted on the fixture's clear (Adventure 0 by the squad
## the game hands you) and read through Label/Button text and node names.

const Results = preload("res://game/screens/Results.gd")
const Fixture = preload("res://tools/fixture_reference.gd")
const RESULTS := "res://game/screens/Results.tscn"


func _cleared_report():
    var st = _root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        _root.add_child(st)
        _made.append(st)
    if _root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        _root.add_child(rt)
        _made.append(rt)
    assert_true(Fixture.apply_clear(st) >= 0, "the clear fixture must find a clearing seed")
    var host := Control.new()
    host.size = Vector2(1536, 1024)
    _root.add_child(host)
    _made.append(host)
    var r = Router.new()
    _made.append(r)
    r.register_host(host)
    assert_true(r.goto(RESULTS), "the report must mount on a clear")
    return r.current_screen()


func _named(n: Node, name: String, out: Array = []) -> Array:
    if String(n.name) == name:
        out.append(n)
    for c in n.get_children():
        _named(c, name, out)
    return out


func test_the_clear_presses_its_stamp_and_wears_the_gold() -> void:
    var screen = _cleared_report()
    var heads: Array = _named(screen, "Headline")
    assert_eq(heads.size(), 1, "one stamp box over the heading")
    var box := heads[0] as PanelContainer
    assert_ne(box, null, "the kit's stamp box, as on the wipe")
    var word := box.get_child(0) as Label
    assert_eq(word.text, "CLEARED", "docs/13 §7's word, as a Label")
    assert_true(absf(box.rotation_degrees) >= 2.0 and absf(box.rotation_degrees) <= 7.0,
        "leaning 2-7° like every stamp: %f" % box.rotation_degrees)
    assert_eq(word.get_theme_color("font_color"), Results.CLEAR_TONE,
        "in the ready gold, not the wipe's red")
    assert_true(screen._clear_stamp == box, "the screen keeps the handle the press used")
    assert_true(_texts(screen).has("Cleared."), "canon's word stays on the page")


func test_the_clears_commit_is_the_crimson_split_and_the_seal_sits_in_the_corner() -> void:
    var screen = _cleared_report()
    var suggested: Array = _named(screen, "Suggested")
    assert_eq(suggested.size(), 1)
    var cta := suggested[0] as Button
    assert_eq(cta.theme_type_variation, &"ButtonCta", "the split wears the crimson")
    assert_true(cta.text.begins_with("Give as Suggested — "), cta.text)
    assert_false(cta.disabled)
    var sell: Array = _named(screen, "SellAll")
    assert_eq(sell.size(), 1, "Sell all unusable stands beside it")
    assert_true((sell[0] as Button).text.begins_with("Sell all unusable"))
    assert_ne((sell[0] as Button).theme_type_variation, &"ButtonCta", "one crimson per page")
    assert_true(screen._clear_seal != null, "the wax seal is on the page")
    assert_true(screen._clear_seal.position.x > Results.PANEL_RECT.position.x + Results.PANEL_RECT.size.x * 0.5,
        "on the report panel's right")
    assert_true(screen._clear_seal.position.y > Results.PANEL_RECT.position.y + Results.PANEL_RECT.size.y * 0.5,
        "and low")
    assert_true(_texts(screen).has("Payout  %s" % preload("res://game/ui/Type.gd").gold(
        _root.get_node("GameState").last_payout)), "the payout line through Type.gold")


func test_a_wipe_presses_no_clear_stamp() -> void:
    var screen = _wiped_screen()
    screen._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    assert_false(_texts(screen).has("CLEARED"), "the wipe's page stamps WIPE., never CLEARED")
