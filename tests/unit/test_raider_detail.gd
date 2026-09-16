extends "res://tests/TestCase.gd"
## S05 — Raider detail, and docs/13 OQ-4's two-click morale repair.
##
## docs/13 §5 gives S05 four contents and one action: "gear paper-doll, backstory
## bullets, wishlist, morale history", entered from "S04 row", primary action "Equip /
## apply comfort item".
##
## Three of the four are built (the wishlist is out of 1.0 — ship plan §6 #59) and the
## assertion that matters most here is `test_a_starter_shows_their_backstory_and_no_word_
## about_a_module` (LOOP-17 / UI-27): the bullets are data/backstories.json's, drawn on
## day one, and the page says nothing about a module a player does not have.

const Comfort = preload("res://sim/core/Comfort.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Loot = preload("res://sim/core/Loot.gd")
const Enums = preload("res://sim/model/Enums.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const DetailView = preload("res://game/screens/RaiderDetail.gd")
const RosterView = preload("res://game/screens/Roster.gd")

const DETAIL := "res://game/screens/RaiderDetail.tscn"

var _db = null
var _mounted: Array = []
var _borrowed = null
var _borrowed_content = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _mounted = []

func after_each() -> void:
    # Teardown in `after_each`, never at the end of a test body: a failed assertion
    # aborts the body, and a borrowed autoload left dirty breaks later files.
    if _borrowed != null and is_instance_valid(_borrowed):
        _borrowed.reset()
        _borrowed.content = _borrowed_content
        _borrowed = null
        _borrowed_content = null
    for n in _mounted:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _mounted = []


func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _live_state(guild: String, gold: int = 500):
    var root := _root()
    var st = root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        root.add_child(st)
        _mounted.append(st)
    else:
        _borrowed = st
        _borrowed_content = st.content
    if root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        root.add_child(rt)
        _mounted.append(rt)
    if root.get_node_or_null("GameSettings") == null:
        var gs = SettingsScript.new()
        gs.name = "GameSettings"
        root.add_child(gs)
        _mounted.append(gs)
    st.reset()
    st.set_content(_db)
    st.new_game(guild)
    st.gold = gold
    return st


func _detail() -> Control:
    var view := DetailView.new()
    _root().add_child(view)
    _mounted.append(view)
    view.build()
    return view


func _roster() -> Control:
    var view := RosterView.new()
    _root().add_child(view)
    _mounted.append(view)
    view.build()
    return view


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _labels(c, out)
    return out


func _printed(n: Node) -> String:
    return "\n".join(PackedStringArray(_labels(n)))


func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out


func _button_named(n: Node, fragment: String):
    for b in _buttons(n):
        if (b as Button).text.contains(fragment):
            return b
    return null


func _named(n: Node, name: String) -> Node:
    if String(n.name) == name:
        return n
    for c in n.get_children():
        var hit := _named(c, name)
        if hit != null:
            return hit
    return null


# =============================================== the screen exists and renders

func test_the_scene_exists_so_the_roster_can_reach_it() -> void:
    assert_true(ResourceLoader.exists(DETAIL))

func test_the_headline_is_canons_own_roster_line() -> void:
    # ✅ CANON prints "Natsuna — 87 ❤️" over "Shaman — Very Happy". S05 shows one
    # raider, so it gets the same two lines at title size.
    var st = _live_state("Detail Test")
    var who = st.roster[0]
    Morale.set_morale(who, 54.0)
    st.selected_raider_id = who.id

    var view := _detail()
    var printed := _printed(view)
    assert_true(printed.contains("%s — 54" % who.display_name),
        "name, dash, morale: %s" % printed)
    assert_true(printed.contains(Enums.class_name_of(who.class_id)))
    assert_true(printed.contains(who.morale_band_name()),
        "and canon's state word")

func test_the_screen_shows_how_often_they_actually_miss() -> void:
    # docs/05 §5's mistake chance is the number morale exists to move, so it is on the
    # screen rather than implied by a colour.
    var st = _live_state("Competence Test")
    st.selected_raider_id = st.roster[0].id
    assert_true(_printed(_detail()).contains("misses about"))

func test_an_empty_guild_does_not_produce_an_empty_screen() -> void:
    var st = _live_state("Nobody Test")
    st.roster = []
    st.selected_raider_id = ""
    var printed := _printed(_detail())
    assert_true(printed.contains("Nobody selected"), printed)
    assert_true(printed.contains("Back to the roster"),
        "and there is always a way out")

func test_a_stale_selection_falls_back_rather_than_breaking() -> void:
    # A raider can leave the guild while their detail screen is in the stack.
    var st = _live_state("Stale Test")
    st.selected_raider_id = "nobody-by-that-name"
    var view := _detail()
    assert_eq(view.shown_raider_id(), String(st.roster[0].id),
        "it shows somebody real instead of nothing")


# =============================================== the paper doll

func test_the_paper_doll_lists_every_slot_the_class_can_fill() -> void:
    # docs/13 §5's "gear paper-doll", and docs/06 owns which slots a class has.
    var st = _live_state("Doll Test")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var view := _detail()
    var printed := _printed(view)

    var cd = _db.class_of(who.class_id)
    for slot in cd.available_slots():
        assert_true(printed.contains(Enums.slot_name_of(int(slot))),
            "%s must have a row" % Enums.slot_name_of(int(slot)))
    assert_true(printed.contains("empty"),
        "a starting raider has empty slots, and they must read as empty")

func test_the_totals_are_the_gear_the_raider_is_actually_wearing() -> void:
    var st = _live_state("Stats Test")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var stats = who.gear_stats(_db)
    assert_true(_printed(_detail()).contains("%d AC" % stats.ac))

func test_an_upgrade_in_the_loot_window_is_offered_with_its_delta() -> void:
    # docs/09 §14 wants the comparison on the control. The candidate is chosen by the
    # same `item_worth` the Suggested split uses, so the screen and the one-click helper
    # can never disagree about which item is the upgrade.
    var st = _live_state("Upgrade Test")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var offered = null
    for it in Loot.drop_pool(_db.encounter_at_slot("A2"), _db):
        if it.can_be_used_by(who.class_id):
            st.pending_loot.append(it)
            offered = it
            break
    if offered == null:
        return

    var view := _detail()
    var btn = _button_named(view, "Equip %s" % offered.name)
    assert_true(btn != null, "the upgrade must be offered: %s" % _printed(view))
    assert_true((btn as Button).text.contains("(+"),
        "with the delta on the button: %s" % (btn as Button).text)

    btn.pressed.emit()
    assert_true(who.item_in(_db, offered.slot) != null,
        "and pressing it puts the item on")
    assert_eq(st.pending_loot.size(), 0, "and takes it out of the window")

func test_gear_nobody_could_wear_is_not_offered() -> void:
    var st = _live_state("Misfit Test")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var misfit = null
    for it in Loot.drop_pool(_db.encounter_at_slot("A3"), _db):
        if not it.can_be_used_by(who.class_id):
            misfit = it
            break
    if misfit == null:
        return
    st.pending_loot.append(misfit)
    assert_true(_button_named(_detail(), "Equip %s" % misfit.name) == null,
        "an item this class cannot use must not have a button")


# =============================================== the quarters

func test_the_arithmetic_strip_is_here_too_because_this_is_where_it_is_read() -> void:
    # docs/02 §4.5's strip. On the Facilities tab it is a purchase pitch; here it is the
    # answer to "why is this raider unhappy", which is the question S05 is opened with.
    var st = _live_state("Strip Test")
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var printed := _printed(view)
    # In the guild's own voice (UI-27); the sum is the line's tooltip.
    assert_true(printed.contains("Settles at %d" % Morale.baseline_of(st.roster[0], 0)), printed)
    var line: Label = _named(view, "Settles") as Label
    assert_true(line != null and line.tooltip_text.contains("50 base"), "the strip is the tooltip")
    assert_true(line.tooltip_text.contains("baseline"))
    assert_true(printed.contains("Slots:"), "and the comfort slots")

func test_a_furnishing_can_be_bought_from_the_detail_screen() -> void:
    # docs/13 §5's primary action for S05 is "Equip / apply comfort item" — both halves.
    var st = _live_state("Furnish Test", 500)
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var view := _detail()
    var btn = _button_named(view, "Straw Cot")
    assert_true(btn != null, "the placeable furnishing must be offered here")
    btn.pressed.emit()
    assert_eq(st.gold, 460)
    assert_eq(who.comfort_floor, 3)

func test_the_detail_screen_is_not_a_second_market() -> void:
    # It offers what is PLACEABLE, not the whole catalogue: repeating the Market here
    # would bury the one item that would help.
    var st = _live_state("Focus Test", 9999)
    st.selected_raider_id = st.roster[0].id
    var printed := _printed(_detail())
    assert_false(printed.contains("Personal Effect"),
        "an unstocked, unplaceable item must not be listed: %s" % printed)


# =============================================== the record

func test_a_starter_shows_their_backstory_and_no_word_about_a_module() -> void:
    # LOOP-17 / UI-27 (C12-C14): every first-time raider's page used to read
    # "Backstories arrive with the Tavern; wishlists with the loot module."
    # Starters draw a backstory on day one, and the page prints the bullets —
    # and nothing about wishlists, which are out of 1.0 (ship plan §6 #59).
    var st = _live_state("Record Test")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    assert_true(who.backstory.size() > 0, "precondition: the starter drew a backstory")
    var printed := _printed(_detail())
    var first: String = String(who.backstory[0]["text"])
    assert_true(printed.contains("• " + first), "the first bullet is printed: %s" % printed)
    assert_false(printed.contains("Nothing is written down"), "not an empty state")
    for word in ["module", "arrive with", "arrives with", "wishlist", "Wants nothing"]:
        assert_false(printed.to_lower().contains(word.to_lower()),
            "the page must not say '%s': %s" % [word, printed])
    assert_true(printed.contains("Ran 0 raids"),
        "while the counters that DO exist are shown: %s" % printed)

func test_a_raider_with_nothing_written_gets_one_honest_line() -> void:
    # The rare case — a stub, an old save: one sentence, no promise about when
    # a backstory "arrives" and no wishlist line.
    var st = _live_state("Blank Test")
    var who = st.roster[0]
    who.backstory = []
    who.backstory_offset = 0
    st.selected_raider_id = who.id
    var printed := _printed(_detail())
    assert_true(printed.contains("Nothing is written down about them yet."), printed)
    for word in ["arrive with", "module", "wishlist", "Wants nothing"]:
        assert_false(printed.to_lower().contains(word.to_lower()), printed)

func test_the_quarters_line_speaks_the_guilds_voice_and_keeps_the_sum_as_a_tooltip() -> void:
    # UI-27: "50 base -5 Common +0 Guildhall +0 furnishings = 45 baseline" was
    # an equation in the sim's vocabulary; the player reads "Settles at 45 —
    # Common, no furnishings." and the arithmetic lives on the tooltip.
    var st = _live_state("Voice Test")
    var who = st.roster[0]
    who.backstory = []
    who.backstory_offset = 0
    st.selected_raider_id = who.id
    var view := _detail()
    var printed := _printed(view)
    assert_true(printed.contains("Settles at 45 — Common, no furnishings."), printed)
    assert_false(printed.contains("50 base"), "the equation is not a Label: %s" % printed)
    var line: Label = _named(view, "Settles") as Label
    assert_true(line != null, "the line is named")
    assert_true(line.tooltip_text.contains("50 base") and line.tooltip_text.contains("45 baseline"),
        "the sum is the tooltip: %s" % line.tooltip_text)
    # A furnishing moves the sentence, and a past moves the sum.
    assert_eq(st.buy_furnishing("straw_cot", who.id), "")
    who.backstory_offset = -2
    var later := _printed(_detail())
    assert_true(later.contains("Settles at 46 — Common, one furnishing."), later)


# =============================================== docs/13 OQ-4

func test_the_roster_row_carries_the_two_click_repair() -> void:
    # docs/13 OQ-4: "Allow a quick-apply from the Roster row's context action, with the
    # full slot view in Raider Detail ... It is done many times per cycle."
    var st = _live_state("Quick Test", 500)
    for r in st.roster:
        Morale.set_morale(r, 18.0)
    var view := _roster()
    var btn = _button_named(view, "Cheer up")
    assert_true(btn != null, "the quick-apply must be on the row")
    assert_false(btn.disabled, "and live for an at-risk raider")

    var before: float = Morale.morale_exact(st.roster[0])
    btn.pressed.emit()
    assert_true(Morale.morale_exact(st.roster[0]) > before,
        "one click, and they feel better")
    assert_eq(st.gold, 480, "20 G for a Hot Bath Token")

func test_the_quick_apply_has_no_morale_gate_on_either_screen() -> void:
    # LOOP-16: "They are fine." was a band the Market never applied — it sells
    # the same Hot Bath Token to the same raider at any morale — and at 45 it
    # contradicted the game. Both the roster row and the detail sidebar gate on
    # the price and the day's cap, nothing else.
    var st = _live_state("Happy Test", 500)
    for r in st.roster:
        Morale.set_morale(r, 70.0)
    var view := _roster()
    var btn = _button_named(view, "Cheer up")
    assert_false(btn.disabled, "live at 70 with gold in hand")
    assert_false(_printed(view).contains("They are fine"), _printed(view))
    st.selected_raider_id = st.roster[0].id
    var detail := _detail()
    var mine = _button_named(detail, "Cheer up")
    assert_true(mine != null and not mine.disabled, "and on the detail page")
    assert_false(_printed(detail).contains("They are fine"), _printed(detail))

func test_the_quick_apply_says_when_the_purse_is_empty() -> void:
    var st = _live_state("Broke Test", 0)
    for r in st.roster:
        Morale.set_morale(r, 12.0)
    var view := _roster()
    assert_true(_printed(view).contains("Costs 20 G"), _printed(view))

func test_the_roster_row_opens_the_detail_screen() -> void:
    # docs/13 §5: S05 is entered from "S04 row".
    var st = _live_state("Manage Test")
    var view := _roster()
    var btn = _button_named(view, "Manage")
    assert_true(btn != null, "every row must have a way in")
    assert_false(btn.disabled, "and the scene exists, so it must be live")
    btn.pressed.emit()
    assert_eq(st.selected_raider_id, String(st.roster[0].id),
        "and it selects the raider whose row was pressed")


# =============================================== morale history (BL-50)

const Raider = preload("res://sim/model/Raider.gd")


func _bare_raider(id: String = "steve"):
    var r = Raider.new()
    r.id = id
    r.display_name = id.capitalize()
    r.class_id = Enums.CharClass.MAGE
    r.rarity = Enums.Rarity.COMMON
    Morale.set_morale(r, 50.0)
    return r


func test_a_new_raider_has_no_history_to_show() -> void:
    var r = _bare_raider()
    assert_eq(r.morale_log, [])
    assert_eq(r.morale_trend(), 0, "and no trend to read from nothing")

func test_one_row_per_day_even_when_a_tick_resolves_twice() -> void:
    # docs/05 §7.2 defers peer deltas to the FOLLOWING tick, so a single day can be
    # touched by two passes. The log must still hold one row for that day, or the
    # sparkline would show a spike that never happened.
    var r = _bare_raider()
    r.record_morale_day(3, 40, "wipe")
    r.record_morale_day(3, 36, "peer_left")
    assert_eq(r.morale_log.size(), 1)
    assert_eq(int(r.morale_log[0]["morale"]), 36, "the last word on that day wins")
    assert_eq(String(r.morale_log[0]["note"]), "peer_left")

func test_the_window_holds_thirty_days_and_forgets_the_thirty_first() -> void:
    var r = _bare_raider()
    for day in range(1, 41):
        r.record_morale_day(day, 50 - day, "wipe")
    assert_eq(r.morale_log.size(), Raider.MORALE_LOG_CAP)
    assert_eq(int(r.morale_log[0]["day"]), 11, "the oldest ten fell off the front")
    assert_eq(int(r.morale_log[-1]["day"]), 40)

func test_the_trend_is_now_against_the_oldest_thing_remembered() -> void:
    var r = _bare_raider()
    r.record_morale_day(1, 60)
    r.record_morale_day(2, 55)
    r.record_morale_day(3, 42)
    assert_eq(r.morale_trend(), -18)

func test_a_day_tick_writes_the_day_it_resolved() -> void:
    var st = _live_state("History Test")
    var who = st.roster[0]
    assert_eq(who.morale_log.size(), 0)
    st.rest_in_town()
    assert_eq(who.morale_log.size(), 1, "one rest, one row")
    assert_eq(int(who.morale_log[0]["day"]), st.day)
    assert_eq(int(who.morale_log[0]["morale"]), int(who.morale),
        "and the number in the log is the number the roster shows")

func test_the_note_records_the_biggest_mover_of_the_tick() -> void:
    # A wipe is worth -8 raw against `brought`'s small positive, so the row must say
    # the wipe. One sentence, and it has to be the right one.
    var st = _live_state("Note Test")
    var party: Array = st.roster.slice(0, 6)
    st.record_attempt("t1_adv_a1", _LostResult.new(), party)
    var who = party[0]
    assert_eq(who.morale_log.size(), 1)
    assert_eq(String(who.morale_log[0]["note"]), "wipe",
        "not 'brought', which also fired: %s" % str(who.morale_log[0]))

func test_a_quiet_rest_records_no_cause() -> void:
    var st = _live_state("Quiet Test")
    var who = st.roster[0]
    Morale.set_morale(who, 30.0)
    st.rest_in_town()
    assert_eq(String(who.morale_log[0]["note"]), "",
        "drift is not an event, so there is nothing to name")

func test_a_hot_bath_shows_up_on_the_day_it_was_drunk() -> void:
    # Indulgences move morale in town, outside a Day Tick, so they record themselves.
    var st = _live_state("Bath Test", 100)
    var who = st.roster[0]
    Morale.set_morale(who, 20.0)
    assert_eq(st.use_indulgence("hot_bath", who.id), "")
    assert_eq(who.morale_log.size(), 1)
    assert_eq(String(who.morale_log[0]["note"]), "comfort_item")

func test_the_history_survives_a_save_round_trip() -> void:
    var st = _live_state("Save History")
    st.rest_in_town()
    st.rest_in_town()
    var expected: int = st.roster[0].morale_log.size()
    assert_true(expected >= 2)

    var saved: Dictionary = st.to_dict()
    var t = GameStateScript.new()
    _mounted.append(t)
    t.set_content(_db)
    var problems: Array = t.from_dict(saved)
    assert_eq(problems.size(), 0, "clean round trip: %s" % str(problems))
    assert_eq(t.roster[0].morale_log.size(), expected,
        "a history the player can read must survive a reload")
    assert_eq(int(t.roster[0].morale_log[-1]["day"]),
        int(st.roster[0].morale_log[-1]["day"]))

func test_the_spiral_reads_back_as_a_falling_line() -> void:
    # docs/15 BL-34's measurement, told as history: five unrested wipes and the screen
    # should say "falling" and name the wipes, which is the whole point of the panel.
    var st = _live_state("Spiral Test")
    var party: Array = st.roster.slice(0, 6)
    for lap in 5:
        st.record_attempt("t1_adv_a1", _LostResult.new(), party)
    var who = party[0]
    assert_true(who.morale_trend() < 0, "five wipes must read as a decline")
    st.selected_raider_id = who.id

    var printed := _printed(_detail())
    assert_true(printed.contains("falling"),
        "and the screen must say so in a word: %s" % printed)
    assert_true(printed.contains("a wipe"),
        "and name what did it, in words rather than a trigger id")
    assert_true(printed.contains("day "), "against the day it happened")

func test_the_sparkline_is_one_block_per_recorded_day() -> void:
    var st = _live_state("Spark Test")
    var who = st.roster[0]
    for i in 4:
        st.rest_in_town()
    st.selected_raider_id = who.id
    var printed := _printed(_detail())
    assert_true(printed.contains("over 4 days"),
        "the window length must be stated, not guessed at: %s" % printed)

func test_a_climbing_raider_is_told_they_are_climbing() -> void:
    var st = _live_state("Climb Test")
    var who = st.roster[0]
    Morale.set_morale(who, 10.0)
    for i in 6:
        st.rest_in_town()
    st.selected_raider_id = who.id
    assert_true(_printed(_detail()).contains("climbing"),
        "recovery must read as recovery")

class _LostResult extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    func cleared() -> bool: return false
