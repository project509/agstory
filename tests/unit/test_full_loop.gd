extends "res://tests/TestCase.gd"
## THE MILESTONE GATE: play the whole game headlessly, by pressing its buttons.
##
## Every other test in this suite calls a method. This one finds the actual
## `Button` a player would click, checks it is enabled, and emits `pressed` — so
## it exercises the WIRING, not just the state machine underneath it. Twice now a
## defect has been invisible to component tests and obvious the moment something
## asserted an outcome a player would notice:
##
##   the loot system handed out no weapons at all, while every test about drop
##   pools, roll counts and payouts passed
##   the 4x reveal batched a mistake with ordinary lines, which docs/13 §11.2
##   forbids in terms
##
## So this walks the loop the backlog's M2 gate describes — boot, town, prep,
## raid, results, town — with the real router, the real autoloads, the real sim
## and real loot.

const RouterScript = preload("res://game/core/ScreenRouter.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Loot = preload("res://sim/core/Loot.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")
const Reputation = preload("res://sim/core/Reputation.gd")

const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const TOWN := "res://game/screens/Town.tscn"
const BOARD := "res://game/screens/AdventureBoard.tscn"
const PREP := "res://game/screens/RaidPrep.tscn"
const RAID_VIEW := "res://game/screens/RaidView.tscn"
const RESULTS := "res://game/screens/Results.tscn"

var _db = null
var _host: Control = null
var _router = null
var _state = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    var root := _root()
    _host = Control.new()
    root.add_child(_host)
    _state = root.get_node_or_null("GameState")
    _router = root.get_node_or_null("ScreenRouter")
    _state.reset()
    _state.set_content(_db)
    _router.register_host(_host)

func after_each() -> void:
    if _state != null:
        _state.reset()
        _state.set_content(null)
    if is_instance_valid(_host):
        if _host.get_parent() != null:
            _host.get_parent().remove_child(_host)
        _host.free()
    _host = null

func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null

func _screen():
    return _router.current_screen()

## Every Button in the current screen, in tree order.
func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out

## Press the first ENABLED button whose label contains `text`. Returns false when
## there is no such button, which is what makes a dead end a test failure rather
## than a silent no-op.
func _press(text: String) -> bool:
    for b in _buttons(_screen()):
        if b.disabled:
            continue
        if b.text.contains(text):
            b.pressed.emit()
            return true
    return false

func _must_press(text: String) -> void:
    assert_true(_press(text), "no enabled button matching '%s' on %s"
        % [text, _router.current_path()])

func _labels() -> Array:
    var out: Array = []
    for b in _buttons(_screen()):
        out.append("%s%s" % [b.text, " (disabled)" if b.disabled else ""])
    return out

# ---------------------------------------------------------------- the on-ramp

## Canon's board opens on "Adventure 0", not on Adventure 1: "Adventure 0 - 1
## Trash mob … Adventure 1 - a few trash encounters and a mini boss". So every
## walk that wants A1 has to get past the two tutorials first.
##
## The lazy fix would have been to stop gating A1 on them, which would delete
## the ordering that makes the board a progression bar (AdventureBoard's
## `_locked_reason` states that intent in its own comment). Instead the walks do
## what a player does — and canon gives the player two ways through, so both are
## exercised: the flagship walk PLAYS Adventure 0, and the farming laps SKIP,
## which is also the regression test for the skipped-tutorial soft-lock.
func _open_board() -> void:
    if _router.current_path() != BOARD:
        _router.goto(TOWN)
        _must_press("Adventure's Board")

## Press "Skip the tutorial" twice. The board's default selection is the first
## rung the guild can take, so after skipping Adventure 0 the paper lands on the
## Tutorial Raid and the second press is on the same screen — and between the two
## presses the board must be warning about TR's OWN trinket, not A0's (docs/10
## §9.3: the copy names the forfeited item and its stat; audit M5-TUT-14 clause 2).
## A blind second press would pass with the warning still reading "Power".
func _skip_the_tutorials() -> void:
    _open_board()
    _must_press("Skip the tutorial")
    assert_false(_state.onboarding_complete, "one skip is not onboarding")
    var page := ""
    for l in _all_text(_screen()):
        page += l + "\n"
    assert_true(page.contains("Cracked Charm of Health"),
        "after A0 is skipped the warning must name the Tutorial Raid's trinket — got:\n%s"
        % page)
    assert_true(page.contains("+2 HP"), "…and its stat (docs/09 §10.2 G12)")
    _must_press("Skip the tutorial")
    assert_false(_press("Skip the tutorial"),
        "two tutorials, two skips, and nothing left to skip")
    assert_true(_state.onboarding_complete,
        "skipping both tutorials must complete onboarding — docs/05 §6.3")

## Farm one rung by pressing its button until it falls. Returns the encounter.
func _clear_rung(fragment: String):
    var enc = null
    for _lap in 25:
        _open_board()
        _must_press(fragment)
        assert_eq(_router.current_path(), PREP, "%s must open prep" % fragment)
        enc = _db.encounter(_state.selected_encounter_id)
        assert_ne(enc, null, "the board must choose a real encounter for '%s'" % fragment)
        _must_press("Depart")
        # docs/01 §9 unlocks Skip only after a clear, so a first visit WATCHES.
        _screen().player().advance(1000.0)
        _must_press("The report")
        # docs/09 §10.2 / docs/10 §9.3: a tutorial's FIRST clear hands over exactly
        # one crap trinket — a fixed grant, not a roll. Asserted here, before
        # "Suggested" consumes it, on the lap the rung first falls; nothing else in
        # this file fails if `_grant_tutorial_trinket` hands over nothing (M5-TUT-14).
        var first_clear: bool = _state.has_cleared(enc.id) and _state.clear_count(enc.id) == 1
        if first_clear and Reputation.is_tutorial_slot(String(enc.slot)):
            assert_eq(_state.pending_loot.size(), 1,
                "%s's first clear must grant exactly one tutorial trinket" % enc.slot)
        if _state.pending_loot.size() > 0:
            _press("Suggested")
        _must_press("Return to town")
        if _state.has_cleared(enc.id):
            return enc
        _rest_until_ready()
    assert_true(false, "%s never cleared in 25 laps" % fragment)
    return enc

# ---------------------------------------------------------------- the walk

func test_the_whole_loop_is_playable_by_pressing_buttons() -> void:
    # 1 — the menu a launched game lands on.
    assert_true(_router.goto(MAIN_MENU), "the main menu must open")
    assert_false(_state.active, "no guild exists before New Guild is pressed")

    # 2 — start a guild.
    _must_press("New Guild")
    assert_eq(_router.current_path(), TOWN, "New Guild lands in the town")
    assert_true(_state.active)
    assert_eq(_state.roster.size(), Enums.RAID_SIZE,
        "docs/15 BL-23: a new guild is handed the benchmark twelve")
    assert_eq(_state.gold, 60, "docs/01 §8.0 Q-13's opening purse")

    # 3 — the town to the board.
    _must_press("Adventure's Board")
    assert_eq(_router.current_path(), BOARD)

    # 4 — take the first rung. Everything above it is gated, so the only enabled
    #     mission button IS the on-ramp — and canon's on-ramp is Adventure 0,
    #     the tutorial, not Adventure 1 (docs/10 §9, docs/01 §3.3).
    var a1_gated := false
    for l in _labels():
        if l.contains("A1") and l.contains("disabled"):
            a1_gated = true
    assert_true(a1_gated,
        "A1 must be gated behind the tutorials — got %s" % str(_labels()))
    _must_press("A0")
    assert_eq(_router.current_path(), PREP)
    var enc = _db.encounter(_state.selected_encounter_id)
    assert_ne(enc, null, "the board must have chosen a real encounter")
    assert_eq(enc.slot, "A0")

    # 5 — prep opens with a suggested party sized for THIS encounter.
    var prep = _screen()
    assert_eq(prep.chalked_ids().size(), enc.party_size,
        "docs/10 §3: an Adventure fields %d, not a raid's twelve" % enc.party_size)

    # 6 — depart. This runs the real sim.
    var attempts_before: int = _state.attempt_count(enc.id)
    _must_press("Depart")
    assert_eq(_state.attempt_count(enc.id), attempts_before + 1,
        "departing must record an attempt")
    assert_ne(_state.last_result, null, "and produce a result")
    assert_eq(_router.current_path(), RAID_VIEW,
        "docs/13 §11: the raid is watched before it is filed")

    # 7 — read the account.
    var view = _screen()
    assert_true(view.player().total() > 0, "the attempt wrote an account")
    # docs/01 §9 locks Skip until this encounter has been cleared once, so a
    # first-time player WATCHES. Advancing the player is that watching; pressing
    # the button here would be testing a control the player does not yet have.
    assert_false(_press("Skip to the end"),
        "docs/01 §9: skip must be locked on an encounter never cleared")
    view.player().advance(1000.0)
    assert_true(view.player().is_finished(), "the account can be read to its end")

    # 8 — file the report.
    _must_press("The report")
    assert_eq(_router.current_path(), RESULTS)

    # 9 — hand out whatever dropped, then go home. A tutorial's reward is a
    #     FIXED grant of docs/09 §10.2's crap trinket rather than a roll off the
    #     Adventure pool (which would pay it real Adventure charms), so the
    #     assertion is EXACTLY one item — "at most one" was green with the grant
    #     resolving to nothing at all (audit M5-TUT-14 clause 3).
    var cleared: bool = _state.last_result.cleared()
    if cleared:
        assert_eq(_state.pending_loot.size(), 1,
            "Adventure 0 pays exactly one crap trinket, never a pull's worth and never nothing")
        _must_press("Suggested")
    _must_press("Return to town")
    assert_eq(_router.current_path(), TOWN, "the loop closes back in the town")

    # 10 — and the ladder responded. A cleared tutorial opens the next rung;
    #      an attempted one does not.
    _open_board()
    var tr_open := false
    for l in _labels():
        if l.contains("TR") and not l.contains("disabled"):
            tr_open = true
    assert_eq(tr_open, cleared,
        "the Tutorial Raid opens on a cleared A0 and not before — got %s"
        % str(_labels()))

func test_the_ladder_opens_once_the_tutorials_are_played() -> void:
    # The rest of the milestone gate, on the path a player who actually plays
    # the tutorials takes: A0, then TR, then Adventure 1.
    #
    # THIS SPLIT IS THE ACCEPTED SHAPE of audit M5-TUT-14's clause 1. The flagship
    # walk above plays ONE un-farmed lap of A0 and asserts everything a first
    # attempt can promise; a single attempt is not guaranteed to clear, so
    # "and then TR, and then A1" has to farm through `_clear_rung`, and folding
    # twenty-five laps of each into the flagship would bury its assertions
    # under the retry loop. The two together are the whole loop.
    _router.goto(MAIN_MENU)
    _must_press("New Guild")
    var a0 = _clear_rung("A0")
    assert_eq(a0.slot, "A0")
    assert_eq(a0.party_size, 4, "docs/10 §9.1: Adventure 0 fields four")
    assert_false(_state.onboarding_complete, "one tutorial is not onboarding")
    var tr = _clear_rung("TR")
    assert_eq(tr.slot, "TR")
    assert_eq(tr.party_size, 6, "docs/10 §9.1: the Tutorial Raid fields six")
    assert_true(_state.onboarding_complete,
        "clearing both tutorials arms docs/05 §6.3's disband rule")
    _open_board()
    _must_press("A1")
    assert_eq(_router.current_path(), PREP)
    assert_eq(_db.encounter(_state.selected_encounter_id).slot, "A1",
        "the ladder must reach Adventure 1 once the tutorials are done")

func test_the_tutorials_can_be_skipped_with_a_warning() -> void:
    # Canon: "Tutorials can be skip, but will offer a special loot piece that is
    # easy, players will be warned that they will miss out on reward".
    # docs/10 §9.3 makes that two requirements — the copy must NAME the item and
    # its stat, and must say plainly that it is not good.
    _router.goto(MAIN_MENU)
    _must_press("New Guild")
    _open_board()
    var page := ""
    for l in _all_text(_screen()):
        page += l + "\n"
    assert_true(page.contains("Cracked Charm of Power"),
        "the warning must name the forfeited item — got:\n%s" % page)
    assert_true(page.contains("+1 Power"), "…and its stat")
    assert_true(page.contains("not a good trinket"),
        "docs/10 §9.3: honesty is the joke")

    _skip_the_tutorials()

    # THE SOFT-LOCK REGRESSION. The ladder gate asks `rung_resolved`, not
    # `has_cleared`, so a skipped tutorial opens what is behind it instead of
    # locking the whole board forever.
    _open_board()
    _must_press("A1")
    assert_eq(_db.encounter(_state.selected_encounter_id).slot, "A1",
        "a skipped tutorial must not brick the rung behind it")
    # docs/15 Q-90: skip is permanent and the mission leaves the board.
    _router.goto(BOARD)
    for l in _labels():
        assert_false(l.begins_with("A0"), "a skipped tutorial leaves the board")

func test_the_loop_can_be_walked_twice() -> void:
    # A loop that only works once is not a loop. The second lap also exercises
    # repeat-clear payout decay and a roster that is no longer bare.
    _walk_one_lap()
    var gold_after_one: int = _state.gold
    var day_one_attempts: int = _state.attempt_count(_first_adventure_rung().id)
    _walk_one_lap()
    assert_eq(_state.attempt_count(_first_adventure_rung().id), day_one_attempts + 1,
        "the second lap must record its own attempt")
    assert_true(_state.gold >= gold_after_one - 1,
        "a second lap must not cost the guild money")

## The first rung of the ADVENTURE tier — A1. Not the first rung of the board,
## which is Adventure 0 now that the tutorials are authored.
func _first_adventure_rung():
    return _db.adventure_encounters(1)[0]

func _walk_one_lap() -> void:
    if not _state.active:
        _router.goto(MAIN_MENU)
        _must_press("New Guild")
    else:
        _router.goto(TOWN)
    _must_press("Adventure's Board")
    # A1 sits behind the two tutorials now. These laps are about the Adventure
    # tier — repeat payout decay, a roster that is no longer bare — so they take
    # canon's other route past the on-ramp and skip it, in one press each. The
    # played route is covered by `test_the_ladder_opens_once_the_tutorials_are_played`.
    if not _state.onboarding_complete:
        _skip_the_tutorials()
    _must_press("A1")
    _must_press("Depart")
    # Watch it rather than skip: docs/01 §9 only unlocks skipping after a clear,
    # so a lap that pressed Skip would fail on the very first lap.
    _screen().player().advance(1000.0)
    _must_press("The report")
    if _state.pending_loot.size() > 0:
        _press("Suggested")
    _must_press("Return to town")
    _rest_until_ready()


## docs/05 §4: a Day Tick fires on an attempt "or explicitly rests in town", and
## resting is the recovery half of that. A player who wipes rests before trying
## again; one who does not spirals, because a wipe costs a Common 10.8 morale
## against 1.125 a tick of drift (docs/15 BL-34). A farming test that never rests
## is testing a player who refuses to.
func _rest_until_ready() -> void:
    for _i in 40:
        if _state.roster.is_empty():
            return
        var total := 0.0
        for r in _state.roster:
            total += float(r.morale)
        if total / float(_state.roster.size()) >= 44.0:
            return
        _state.rest_in_town()

# ---------------------------------------------------------------- no dead ends

func test_no_screen_in_the_loop_is_a_dead_end() -> void:
    # The quality bar forbids a dead-end screen. Every screen the loop reaches
    # must offer at least one ENABLED control that leaves it.
    _router.goto(MAIN_MENU)
    _must_press("New Guild")

    var visited := [TOWN]
    _must_press("Adventure's Board")
    visited.append(BOARD)
    # The first rung a new guild is offered, which is now the tutorial.
    _must_press("A0")
    visited.append(PREP)
    _must_press("Depart")
    visited.append(RAID_VIEW)
    _screen().player().advance(1000.0)
    _must_press("The report")
    visited.append(RESULTS)

    for path in visited:
        _router.goto(path)
        var enabled := 0
        for b in _buttons(_screen()):
            if not b.disabled:
                enabled += 1
        assert_true(enabled > 0,
            "%s offers no enabled control at all" % path)

func test_every_disabled_control_explains_itself() -> void:
    # docs/13 §7: a disabled control is never a mystery. A screen may disable a
    # button, but the page must then say why somewhere on it.
    _router.goto(MAIN_MENU)
    var disabled := 0
    for b in _buttons(_screen()):
        if b.disabled:
            disabled += 1
    if disabled > 0:
        var text := ""
        for l in _all_text(_screen()):
            text += l + "\n"
        assert_true(text.contains("not in this version yet")
            or text.contains("No saved guild found."),
            "a disabled menu entry must carry its reason")

func _all_text(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _all_text(c, out)
    return out

# ---------------------------------------------------------------- party size

func test_an_adventure_fields_six_and_a_raid_fields_twelve() -> void:
    # docs/10 §3, and the bug this gate caught: raid prep chalked twelve for
    # every mission, so a player would have sent a full raid on a six-person
    # Adventure — doubling the party DPS the HP in docs/08 §9.1a was derived
    # against, and quietly trivialising the entire on-ramp.
    assert_eq(RaidPlan.party_size(_db.encounter_at_slot("A1")), 6)
    assert_eq(RaidPlan.party_size(_db.encounter_at_slot("A3")), 6)
    assert_eq(RaidPlan.party_size(_db.encounter_at_slot("E1")), Enums.RAID_SIZE)
    assert_eq(RaidPlan.party_size(null), Enums.RAID_SIZE, "the fallback is a raid")

func test_prep_chalks_to_the_encounters_own_party_size() -> void:
    _router.goto(MAIN_MENU)
    _must_press("New Guild")
    for slot in ["A1", "E1"]:
        _state.selected_encounter_id = _db.encounter_at_slot(slot).id
        _router.goto(PREP)
        assert_eq(_screen().chalked_ids().size(),
            _db.encounter_at_slot(slot).party_size,
            "%s should chalk its own party size" % slot)

func test_the_comp_readout_counts_against_the_right_target() -> void:
    var six := RaidPlan.analyse([], _db, _db.encounter_at_slot("A1"))
    assert_eq(int(six["slots_required"]), 6)
    assert_eq(int(six["healers_recommended"]), 1,
        "docs/10 §8 derived A3's healing against ONE healer, and docs/15 BL-29 "
        + "held that constant when it rescaled the raid-wide magnitude")
    var twelve := RaidPlan.analyse([], _db, _db.encounter_at_slot("E1"))
    assert_eq(int(twelve["slots_required"]), Enums.RAID_SIZE)
    assert_eq(int(twelve["healers_recommended"]), 3, "docs/06 §6.5's raid default")

# ---------------------------------------------------------------- progression

func test_clearing_the_first_rung_unlocks_the_second() -> void:
    # The board is a progression bar (docs/02 §2.2), so a clear has to open
    # something. Farm A1 until it falls, then check A2 is offered.
    _router.goto(MAIN_MENU)
    _must_press("New Guild")
    var a1 = _first_adventure_rung()

    var cleared := false
    for _lap in 25:
        _walk_one_lap()
        if _state.has_cleared(a1.id):
            cleared = true
            break
    assert_true(cleared, "A1 must be clearable — docs/15 BL-27")

    _router.goto(BOARD)
    var labels := _labels()
    var a2_open := false
    for l in labels:
        if l.contains("A2") and not l.contains("disabled"):
            a2_open = true
    assert_true(a2_open, "clearing A1 must open A2 — got %s" % str(labels))

func test_a_clear_pays_the_documented_gold() -> void:
    _router.goto(MAIN_MENU)
    _must_press("New Guild")
    var a1 = _first_adventure_rung()
    var before: int = _state.gold
    var cleared := false
    for _lap in 25:
        var gold_at_lap_start: int = _state.gold
        _walk_one_lap()
        if _state.has_cleared(a1.id):
            cleared = true
            assert_eq(_state.gold, gold_at_lap_start + Loot.payout(a1, 0),
                "the first clear pays docs/11 §F2's rate")
            break
    assert_true(cleared)
    assert_true(_state.gold > before, "clearing must leave the guild richer")
