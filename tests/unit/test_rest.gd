extends "res://tests/TestCase.gd"
## Resting in town: docs/05 §4's Day Tick as a player verb, and docs/15 BL-34's fix
## for the tedium the last iteration measured.
##
## The measurement BL-34 recorded: one wipe costs a Common 10.8 morale against 1.125
## per Day Tick of drift, so recovery is 8-10 rests — and docs/02 §4.3 works an
## example that takes ~30. The fix is one control that rests the whole stretch, not
## a bigger drift number, because raising drift would be tuning around the missing
## comfort-item lever (docs/05 §7.4) and would have to be undone later.
##
## The assertions that matter most here are about what resting must NOT become. It
## is not shelter: docs/05 §6's leave and disband checks fire on every tick of the
## loop, and the loop stops and says so rather than resting through a departure.

const Morale = preload("res://sim/core/Morale.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const RosterView = preload("res://game/screens/Roster.gd")

const GUILDHALL := "res://game/screens/Guildhall.tscn"

var _db = null
var _root: Node = null
var _made: Array = []

## The screen tests need a live `/root/GameState`, and under `--script` that node is
## shared with every other test file in the run. Borrowing it means putting it back
## exactly as found — content included, since a GameState WITH content builds a
## starting roster on `new_game()` and one without cannot.
var _borrowed = null
var _borrowed_content = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []

func after_each() -> void:
    if _borrowed != null and is_instance_valid(_borrowed):
        _borrowed.reset()
        _borrowed.content = _borrowed_content
        _borrowed = null
        _borrowed_content = null
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


func _r(rarity: int, morale: float, id: String = "r"):
    var r = Raider.new()
    r.id = id
    r.display_name = id.capitalize()
    r.class_id = Enums.CharClass.WARRIOR
    r.rarity = rarity
    Morale.set_morale(r, morale)
    return r


func _state():
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Rest Test")
    return s


# ------------------------------------------------- docs/05 §8 / docs/02 §4.3

func test_the_worked_steve_from_doc_02_reproduces() -> void:
    # docs/02 §4.3, quoted: "Guildhall L2 (`facility_bonus` +3). Steve the Mage sits
    # at 14 ✅ CANON example value; doc 05 §11.2 reads him as a Common, so his
    # `rarity_offset` is −5 and his `drift_step` is 1.125 per Day Tick. Baseline
    # before comfort items = 50 − 5 + 3 = 48 ... and ~30 ticks to reach 48."
    #
    # Building level 2 is facility TIER 1 in docs/05 §7.5's ladder (tier 0 is the
    # starting Guildhall), which is the +3 rung.
    var steve = _r(Enums.Rarity.COMMON, 14.0, "steve")
    assert_eq(Morale.baseline_of(steve, 1), 48, "50 - 5 + 3")
    assert_in_range(float(Morale.rest_ticks_for(steve, 1)), 30.0, 31.0,
        "docs/02 §4.3's own '~30 ticks to reach 48'")
    assert_false(Morale.is_recovered(steve, 1))

func test_resting_a_raider_all_the_way_takes_exactly_the_forecast_days() -> void:
    # The number the button prints has to be the number of days it then costs, or
    # the control is lying about its price.
    for rarity in Enums.all_rarities():
        var r = _r(rarity, 5.0, "r%d" % rarity)
        var forecast := Morale.rest_ticks_for(r, 0)
        for i in forecast:
            Morale.drift_raider(r, 0, 0)
        assert_true(Morale.is_recovered(r, 0),
            "%s must be settled after its forecast %d days"
                % [Enums.rarity_name_of(rarity), forecast])
        # And not a day earlier: one fewer must leave them short.
        var r2 = _r(rarity, 5.0, "s%d" % rarity)
        for i in maxi(0, forecast - 1):
            Morale.drift_raider(r2, 0, 0)
        assert_false(Morale.is_recovered(r2, 0),
            "%s must still need its last day" % Enums.rarity_name_of(rarity))

func test_a_raider_above_baseline_needs_no_rest() -> void:
    # docs/05 §11.2's note on the sign flip: above baseline, drift pulls DOWN.
    # Resting cannot help someone who is already happier than they settle at, so the
    # forecast must be zero rather than the distance back down.
    var happy = _r(Enums.Rarity.COMMON, 90.0, "natsuna")
    assert_true(Morale.is_recovered(happy, 0))
    assert_eq(Morale.rest_ticks_for(happy, 0), 0)
    assert_true(Morale.ticks_to_baseline(90.0, Enums.Rarity.COMMON, 0) > 0,
        "the two-directional helper still measures the trip down")

func test_the_roster_forecast_is_the_slowest_raider() -> void:
    # Resting stops when EVERYONE has settled, so the forecast is a max, not a mean.
    var roster := [
        _r(Enums.Rarity.LEGENDARY, 60.0, "fast"),
        _r(Enums.Rarity.COMMON, 5.0, "slow"),
        _r(Enums.Rarity.RARE, 40.0, "middle"),
    ]
    var slowest := 0
    for r in roster:
        slowest = maxi(slowest, Morale.rest_ticks_for(r, 0))
    assert_eq(Morale.rest_ticks_needed(roster, 0), slowest)
    assert_eq(Morale.rest_ticks_needed(roster, 0),
        Morale.rest_ticks_for(roster[1], 0), "the Common is the slow one")
    assert_false(Morale.roster_is_rested(roster, 0))

func test_facilities_move_the_target_so_they_lengthen_the_rest() -> void:
    # docs/05 §7.5 models a facility upgrade as a baseline SHIFT, so a better
    # Guildhall means a higher place to climb to — the rest gets longer, and ends
    # somewhere better. This is the doc's stated reading of canon's "better morale
    # values" and it must not be quietly inverted into a faster recovery.
    var plain := Morale.rest_ticks_for(_r(Enums.Rarity.COMMON, 10.0, "a"), 0)
    var housed := Morale.rest_ticks_for(_r(Enums.Rarity.COMMON, 10.0, "b"), 3)
    assert_true(housed > plain,
        "a +10 baseline is ten more points to climb: %d vs %d" % [housed, plain])
    assert_eq(Morale.baseline_of(_r(Enums.Rarity.COMMON, 10.0, "c"), 3), 55)

func test_an_empty_roster_is_rested_by_definition() -> void:
    assert_true(Morale.roster_is_rested([], 0))
    assert_eq(Morale.rest_ticks_needed([], 0), 0)


# ------------------------------------------------------------- the live control

func test_resting_until_recovered_settles_the_roster_in_the_forecast_days() -> void:
    var s = _state()
    # A guild that has just had a bad night: everyone well below baseline.
    for r in s.roster:
        Morale.set_morale(r, 32.0)
    var forecast: int = Morale.rest_ticks_needed(s.roster, s.facility_tier)
    assert_true(forecast > 1, "the fixture must actually need resting")

    var report: Dictionary = s.rest_until_recovered()
    assert_eq(String(report["reason"]), "rested")
    assert_true(bool(report["settled"]), "everyone is at their baseline")
    assert_eq(int(report["days"]), forecast,
        "the days spent must equal the days forecast")
    assert_eq(report["departed"], [], "nobody was at risk, so nobody left")
    for r in s.roster:
        assert_true(Morale.is_recovered(r, s.facility_tier),
            "%s is still short" % r.display_name)

func test_resting_advances_the_day_clock_by_the_days_it_takes() -> void:
    # docs/05 §4: a rest IS a Day Tick, so the calendar has to move with it.
    var s = _state()
    for r in s.roster:
        Morale.set_morale(r, 30.0)
    var day_before: int = s.day
    var report: Dictionary = s.rest_until_recovered()
    assert_eq(s.day, day_before + int(report["days"]))

func test_resting_when_everyone_is_settled_costs_nothing() -> void:
    # A new guild starts AT baseline (docs/05 §4's "Starting morale"), so the very
    # first thing this control must do is decline to waste the player's days.
    var s = _state()
    var report: Dictionary = s.rest_until_recovered()
    assert_eq(int(report["days"]), 0)
    assert_true(bool(report["settled"]))
    assert_eq(String(report["reason"]), "rested")

func test_resting_is_not_shelter_and_stops_when_someone_leaves() -> void:
    # docs/05 §6's leave checks fire on every tick of the loop. A multi-day rest
    # that quietly lost a raider would be the worst kind of convenience, so the loop
    # stops on the departure and names them.
    var s = _state()
    for r in s.roster:
        # Band 0-2 and already carrying a strike, so a leave check is live on the
        # very first rest tick (docs/05 §6.2's MIN_STRIKES_TO_LEAVE).
        Morale.set_morale(r, 6.0)
        r.at_risk_strikes = 5
    var started: int = s.roster.size()
    var report: Dictionary = s.rest_until_recovered()
    assert_eq(String(report["reason"]), "departure",
        "a departure must stop the rest, not be rested through")
    var departed: Array = report["departed"]
    assert_true(departed.size() > 0, "and it must say who")
    assert_eq(s.roster.size(), started - departed.size())
    assert_false(bool(report["settled"]))

func test_resting_an_empty_guild_terminates_immediately() -> void:
    var s = _state()
    s.roster = []
    var report: Dictionary = s.rest_until_recovered()
    assert_eq(int(report["days"]), 0)
    assert_eq(String(report["reason"]), "empty")

func test_the_rest_loop_is_bounded_above_every_legitimate_rest() -> void:
    # The backstop is a bug guard, not a design number. The slowest rest the game can
    # legitimately ask for is a Common at 0 morale in a tier-3 Guildhall — baseline
    # 55, drift 1.125 — which is 49 days. The limit must sit clear of that, or the
    # guard would cut a real rest short.
    var worst := Morale.rest_ticks_for(_r(Enums.Rarity.COMMON, 0.0, "worst"), 3)
    assert_eq(worst, 49)
    assert_true(GameStateScript.REST_DAY_LIMIT > worst,
        "%d must exceed the worst legitimate rest of %d"
            % [GameStateScript.REST_DAY_LIMIT, worst])

    # And the loop honours it: a roster resting from the floor never exceeds the cap.
    var s = _state()
    for r in s.roster:
        Morale.set_morale(r, 1.0)
    var report: Dictionary = s.rest_until_recovered()
    assert_true(int(report["days"]) <= GameStateScript.REST_DAY_LIMIT)

func test_the_measured_spiral_is_survivable_with_the_one_click() -> void:
    # docs/15 BL-34's original measurement: twelve unrested A1 attempts took a fresh
    # guild from 48 average morale to 1 and cost it 11 of its 12 raiders. This is the
    # same twelve laps with a single "rest until recovered" between each.
    var s = _state()
    var party: Array = s.roster.slice(0, 6)
    var lost := 0
    for lap in 12:
        s.record_attempt("t1_adv_a1", _Lost.new(), party)
        var report: Dictionary = s.rest_until_recovered()
        lost += (report["departed"] as Array).size()
        # Re-chalk from whoever is still here.
        party = s.roster.slice(0, mini(6, s.roster.size()))
        if party.is_empty():
            break
    assert_eq(lost, 0,
        "twelve straight wipes must not cost the guild anyone when it rests")
    assert_eq(s.roster.size(), 12)
    var avg := 0.0
    for r in s.roster:
        avg += Morale.morale_exact(r)
    avg /= float(s.roster.size())
    assert_in_range(avg, 40.0, 50.0,
        "and the roster ends where a Common's baseline is, not at 1")

class _Lost extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    func cleared() -> bool: return false


# ------------------------------------------------------------------- the screen

func _mounted_roster() -> Control:
    if _root.get_node_or_null("GameState") == null:
        var gs = GameStateScript.new()
        gs.name = "GameState"
        _root.add_child(gs)
        _made.append(gs)
    if _root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        _root.add_child(rt)
        _made.append(rt)
    var view := RosterView.new()
    _root.add_child(view)
    _made.append(view)
    view.build()
    return view


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


func _printed(n: Node) -> String:
    return "\n".join(PackedStringArray(_texts(n)))


## The live autoload, whether this run already had one or not.
func _live_state(guild: String):
    var st = _root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        _root.add_child(st)
        _made.append(st)
    else:
        _borrowed = st
        _borrowed_content = st.content
    st.reset()
    st.set_content(_db)
    st.new_game(guild)
    return st


func test_the_roster_offers_resting_and_prices_it_in_days() -> void:
    # ✅ CANON puts morale maintenance in the Guildhall, and this is its roster tab.
    var st = _live_state("Screen Rest")
    for r in st.roster:
        Morale.set_morale(r, 30.0)

    var view := _mounted_roster()
    var printed := _printed(view)
    assert_true(printed.contains("Rest until recovered"),
        "the one-click control must be on the screen: %s" % printed)
    assert_true(printed.contains("Rest a day"))
    var days: int = Morale.rest_ticks_needed(st.roster, st.facility_tier)
    assert_true(printed.contains("%d days of rest" % days),
        "and it must say how many days that is (%d): %s" % [days, printed])

func test_the_screen_warns_that_resting_still_rolls_the_leave_checks() -> void:
    # The difference between a convenience and a trap is one sentence.
    var st = _live_state("Screen Risk")
    for r in st.roster:
        Morale.set_morale(r, 12.0)

    var view := _mounted_roster()
    var printed := _printed(view)
    assert_true(printed.contains("rolls the leave checks"),
        "an at-risk roster must be told resting is not shelter: %s" % printed)

func test_a_settled_roster_is_told_resting_would_be_wasted() -> void:
    var st = _live_state("Screen Settled")
    assert_true(Morale.roster_is_rested(st.roster, st.facility_tier),
        "a new guild starts at baseline, so there is nothing to rest off")

    var view := _mounted_roster()
    var printed := _printed(view)
    assert_true(printed.contains("baseline"),
        "docs/13 §7 forbids a disabled control that is a mystery: %s" % printed)
