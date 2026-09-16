extends "res://tests/TestCase.gd"
## The app shell: router, and the two screens that exist.
##
## These mount real scenes into the real tree rather than testing the scripts in
## isolation, because the failure this must catch is "the game boots to a black
## window" — which only happens when scene, script and autoload disagree.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const TownScript = preload("res://game/screens/Town.gd")
const Enums = preload("res://sim/model/Enums.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const Cards = preload("res://game/ui/Cards.gd")
const DB = preload("res://sim/content/ContentDB.gd")

const CompletionScript = preload("res://game/screens/Completion.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")

const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const TOWN := "res://game/screens/Town.tscn"
const BOOT := "res://game/ui/Boot.tscn"
const BOARD := "res://game/screens/AdventureBoard.tscn"
const COMPLETION := "res://game/screens/Completion.tscn"
const RESULTS := "res://game/screens/Results.tscn"
const GUILDHALL := "res://game/screens/Guildhall.tscn"

var _root: Node = null
var _made: Array = []


func before_each() -> void:
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

## The autoloads the screens look up. Under `--script` the project's autoloads
## may not be instantiated, so provide them rather than skipping the test.
func _ensure_autoloads() -> void:
    if _root == null:
        return
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
    _root.add_child(h)
    _made.append(h)
    return h

## Every Label text in a subtree, so a test can assert what the screen actually
## prints without depending on node paths that layout changes will churn.
func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out

func _joined(n: Node) -> String:
    return "\n".join(PackedStringArray(_texts(n)))

# ---------------------------------------------------------------- scenes exist

func test_the_main_scene_and_its_first_two_screens_exist() -> void:
    # project.godot points run/main_scene at Boot. If any of these is missing the
    # game launches to nothing, which no other test would notice.
    for path in [BOOT, MAIN_MENU, TOWN]:
        assert_true(ResourceLoader.exists(path), "missing scene %s" % path)

func test_screen_exists_reports_honestly() -> void:
    assert_true(Router.screen_exists(TOWN))
    assert_false(Router.screen_exists("res://game/screens/NoSuchScreen.tscn"))

# ---------------------------------------------------------------- router

func test_navigation_without_a_host_fails_loudly() -> void:
    # A router that silently drops goto() produces a black window and no error.
    var r = Router.new()
    _made.append(r)
    var failures: Array = []
    r.navigation_failed.connect(func(p: String, why: String) -> void:
        failures.append("%s: %s" % [p, why]))
    assert_false(r.has_host())
    assert_false(r.goto(MAIN_MENU))
    assert_eq(failures.size(), 1, "a failed navigation must report why")
    assert_eq(r.depth(), 0)

func test_goto_mounts_a_screen_and_replaces_the_stack() -> void:
    _ensure_autoloads()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    assert_true(r.goto(MAIN_MENU))
    assert_eq(r.current_path(), MAIN_MENU)
    assert_eq(r.depth(), 1)
    assert_true(r.current_screen() is Control)
    assert_true(r.goto(TOWN))
    assert_eq(r.depth(), 1, "goto replaces the stack rather than growing it")
    assert_eq(r.current_path(), TOWN)

func test_push_and_pop_walk_the_stack() -> void:
    _ensure_autoloads()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(MAIN_MENU)
    assert_true(r.push(TOWN))
    assert_eq(r.depth(), 2)
    assert_eq(r.current_path(), TOWN)
    assert_true(r.pop())
    assert_eq(r.depth(), 1)
    assert_eq(r.current_path(), MAIN_MENU)

func test_pop_at_the_root_refuses_rather_than_emptying_the_window() -> void:
    _ensure_autoloads()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(MAIN_MENU)
    assert_false(r.pop(), "the router must never leave the player on no screen")
    assert_eq(r.depth(), 1)
    assert_eq(r.current_path(), MAIN_MENU)

func test_a_failed_navigation_leaves_the_current_screen_up() -> void:
    _ensure_autoloads()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(MAIN_MENU)
    assert_false(r.goto("res://game/screens/Nope.tscn"))
    assert_eq(r.current_path(), MAIN_MENU, "a bad goto must not blank the window")
    assert_true(is_instance_valid(r.current_screen()))

func test_only_one_screen_is_mounted_at_a_time() -> void:
    # free() rather than queue_free() in the router: a deferred free would leave
    # two screens overlapping until idle, which reads as a rendering bug.
    _ensure_autoloads()
    var r = Router.new()
    _made.append(r)
    var host := _host()
    r.register_host(host)
    r.goto(MAIN_MENU)
    r.goto(TOWN)
    assert_eq(host.get_child_count(), 1)

# ---------------------------------------------------------------- main menu

func test_the_main_menu_offers_a_working_new_guild() -> void:
    _ensure_autoloads()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(MAIN_MENU)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("A Guild Story"), "the title must be on screen")
    assert_true(printed.contains("New Guild"), "the primary action must exist")
    assert_true(printed.contains("Continue"))
    assert_true(printed.contains("Quit"))

func test_continue_says_why_when_there_is_nothing_to_continue() -> void:
    # docs/13 §7: a disabled control is never a mystery. docs/14 §7.1's header-first read
    # exists so this screen can say the reason instead of crashing on a bad save.
    _ensure_autoloads()
    SaveGame.purge_all()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(MAIN_MENU)
    assert_true(_joined(r.current_screen()).contains("No saved guild found."),
        _joined(r.current_screen()))

func test_continue_offers_the_guild_by_name_once_one_is_saved() -> void:
    _ensure_autoloads()
    SaveGame.purge_all()
    var st = _state()
    st.set_content(DB.load_all())
    st.new_game("Saved Guild")
    assert_eq(SaveGame.save_slot(0, st), "")

    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(MAIN_MENU)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("Continue — Saved Guild"),
        "the menu must name the guild it would open: %s" % printed)
    SaveGame.purge_all()
    # This file's other tests use a CONTENTLESS GameState — `new_game()` on one with
    # content builds the starting twelve, and "Roster 0 of 15" three tests later depends
    # on it not having. Put the autoload back the way it was found.
    st.reset()
    st.content = null

# ---------------------------------------------------------------- town

func test_the_town_prints_the_guild_the_player_just_started() -> void:
    _ensure_autoloads()
    var st = _state()
    st.new_game("Test Guild")
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(TOWN)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("Test Guild"), "the desk strip names the guild")
    assert_true(printed.contains("60 G"), "docs/01 §8.0's opening balance, on screen")
    assert_true(printed.contains("Day 1"))
    assert_true(printed.contains("Roster 0 of 15"),
        "docs/04 §12.1: an Unknown guild's cap is 15")
    assert_true(printed.contains("Unknown"), "canon: you start at Unknown")
    st.reset()

func test_the_town_lists_exactly_the_five_canon_buildings() -> void:
    # docs/02 §2.3: five canon buildings, no sprawl — a sixth needs one cut.
    assert_eq(TownScript.BUILDINGS.size(), 5)
    var names := []
    for b in TownScript.BUILDINGS:
        names.append(String(b["name"]))
    assert_eq(names, ["Guildhall", "Tavern", "Market", "Blacksmith",
        "Adventure's Board"])

func test_the_board_keeps_canons_own_spelling() -> void:
    # Canon writes "Adventure's Board", not "Adventurer's Board" (docs/02 §3.1).
    var found := false
    for b in TownScript.BUILDINGS:
        if String(b["id"]) == "board":
            found = true
            assert_eq(String(b["name"]), "Adventure's Board")
    assert_true(found, "the Adventure's Board must be in the town")

func test_the_board_shows_what_the_next_rank_will_open() -> void:
    # docs/03 §7 and ✅ CANON "New Tiers can be unlocked by gaining reputations with
    # the town". A ladder the player cannot see the next rung of is not a ladder.
    _ensure_autoloads()
    var st = _state()
    st.new_game("Standing Test")
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(BOARD)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("Unknown"), "the rank the guild actually holds")
    assert_true(printed.contains("120 more to Known"),
        "docs/03 §6.4's first threshold, counted down: %s" % printed)
    # LOOP-06: the promise names a tier only when THIS BUILD mounts it. A
    # contentless state mounts nothing, so what Known buys here is the
    # "more of the same" line, never "Raid 2" — the sentence the player earned
    # Known with must not be false on arrival.
    assert_false(printed.contains("Raid 2"),
        "no tier-2 raid is mounted, so none may be promised: %s" % printed)
    assert_true(printed.contains("more of the same, better paid"),
        "and it still says what the rank buys: %s" % printed)
    st.reset()

func test_the_board_promises_a_tier_only_when_the_build_mounts_it() -> void:
    # LOOP-06 with real content: docs/03 §7 opens Raid 2 at Known, but
    # `ContentDB` mounts only named tiers (docs/15 BL-69) and tiers 2-5 are
    # pending. At Known the standing line therefore names no "Adventure 2";
    # when the words land and tier 2 mounts, the original sentence returns
    # on its own (the guard asks the content, not a flag).
    _ensure_autoloads()
    var st = _state()
    st.set_content(DB.load_all())
    st.new_game("Known Guild")
    st.reputation_rank = Enums.ReputationRank.KNOWN
    st.reputation_points = 120
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(BOARD)
    var printed := _joined(r.current_screen())
    # Flat, not conditional (LESSONS: a test that branches on whether the work
    # exists is not a gate): tier 3 is pending today. The day W9-TIERS mounts
    # it this goes red and is retargeted to "Adventure 3 and Raid 3" — which
    # is the guard proving its other half.
    assert_true(st.content.raid_encounters(3).is_empty(), "precondition: tier 3 unmounted")
    assert_false(printed.contains("Adventure 3"),
        "tier 3 is not mounted, so Respected may not promise it: %s" % printed)
    assert_false(printed.contains("Adventure 2"), printed)
    assert_true(printed.contains("more of the same, better paid"), printed)
    st.reset()
    st.content = null

func test_the_board_tells_the_player_when_the_catchup_valve_is_open() -> void:
    # docs/03 §8.1 M3 doubles adventure reputation while the player is stuck. A
    # mitigation the player cannot see does not mitigate anything.
    _ensure_autoloads()
    var st = _state()
    st.new_game("Stall Test")
    st.stalled = true
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(BOARD)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("double reputation"),
        "the board must say the adventures are paying double: %s" % printed)
    st.reset()

func test_the_blacksmith_is_gated_because_canon_calls_it_a_maybe() -> void:
    # docs/14 §5.2: the game must boot and be completable with every flag off.
    for b in TownScript.BUILDINGS:
        if String(b["id"]) == "blacksmith":
            assert_eq(String(b["flag"]), "blacksmith",
                "the canon Maybe must sit behind a feature flag")

func test_unbuilt_buildings_are_disabled_with_a_reason_not_hidden() -> void:
    # docs/13 §7 forbids a disabled control that is a mystery. Every canon building now
    # has a screen except the Blacksmith, which canon itself calls a "Maybe" and which
    # docs/02 §8 keeps behind a feature flag.
    _ensure_autoloads()
    var st = _state()
    st.new_game("Doors Test")
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(TOWN)
    var printed := _joined(r.current_screen())
    for name in ["Guildhall", "Tavern", "Market", "Adventure's Board"]:
        assert_true(printed.contains(name), "%s must be on the square" % name)
    assert_true(printed.contains(_smithy_blurb()),
        "and the Blacksmith must say why it is shut, in its own words: %s" % printed)
    st.reset()

## The shut Blacksmith's sentence — the building's `blurb`, the ONE source
## (CRITIC-C4; ship plan §6 #10's default: out of 1.0, an in-world non-promise).
## Read off BUILDINGS rather than typed here, so the designer's own line (Q-13)
## replaces it in one place. The copy lint (tools/lint_copy.sh) is what keeps
## a word about the build out of it.
func _smithy_blurb() -> String:
    for b in TownScript.BUILDINGS:
        if String(b["id"]) == "blacksmith":
            return String(b["blurb"])
    return ""

func test_the_smithys_sentence_is_in_world_and_names_no_build() -> void:
    # LOOP-02 / UI-01: the plate used to read "Canon lists this one as a maybe.
    # Disabled in this build." — developer-English on the first screen.
    var blurb := _smithy_blurb()
    assert_true(blurb.length() > 0, "the shut plate carries a sentence")
    for word in ["canon", "build", "maybe", "version", "construction"]:
        assert_false(blurb.to_lower().contains(word),
            "the Blacksmith's sentence must not say '%s': %s" % [word, blurb])
    var printed := _town_text("In World", Enums.ReputationRank.UNKNOWN, 60, false)
    assert_true(printed.contains(blurb), printed)


# ------------------------------------- docs/03 §7's town column, on the screen

## Every assertion below differs only in the standing the guild holds, the purse it
## holds it with and whether the canon Maybe is switched on. The scaffolding is the
## same four lines each time and the string printed is the whole point, so it is
## folded up here rather than copied five times.
func _town_text(guild: String, rank: int, gold: int, smithy: bool) -> String:
    _ensure_autoloads()
    var st = _state()
    st.new_game(guild)
    st.reputation_rank = rank
    st.gold = gold
    st.flags["blacksmith"] = smithy
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(TOWN)
    var printed := _joined(r.current_screen())
    st.reset()
    return printed

func _find_button(n: Node, text: String):
    if n is Button and (n as Button).text == text:
        return n
    for c in n.get_children():
        var found = _find_button(c, text)
        if found != null:
            return found
    return null

func test_the_smithy_names_the_rank_that_opens_it() -> void:
    # docs/03 §7 makes "Blacksmith opens" the whole of Respected's town column, and
    # docs/02 §11 puts the building's own L1 behind that rank. Before this the town
    # screen never read the rank at all, so no building on it was ever rank-gated.
    var printed := _town_text("Rank Gate", Enums.ReputationRank.UNKNOWN, 999, true)
    assert_true(printed.contains("Reach Respected"),
        "the shut door must name the rank that opens it: %s" % printed)
    assert_false(printed.contains("Disabled in this build"),
        "and must not still claim the flag is off")

func test_a_respected_guild_is_quoted_the_smithys_price_instead() -> void:
    # docs/11 §8.4: rank first, then price, each naming its own number. Meeting the
    # rank has to visibly change the sentence or it looks like it bought nothing.
    var printed := _town_text("Price Gate", Enums.ReputationRank.RESPECTED, 60, true)
    assert_true(printed.contains("Costs 300 G"),
        "docs/02 §11 prices Blacksmith L1 at 300 G: %s" % printed)
    assert_false(printed.contains("Reach Respected"),
        "the rank is no longer what is blocking")

func test_a_flagged_off_smithy_is_absent_rather_than_rank_locked() -> void:
    # The gate order, pinned. docs/14 §5.2's flag decides whether the building is in
    # this build at all, so it is asked before the rank: telling an Unknown guild to
    # "Reach Respected" for a smithy the executable does not contain is a gate that
    # lies about what meeting it would do.
    var printed := _town_text("Flag Off", Enums.ReputationRank.UNKNOWN, 999, false)
    assert_true(printed.contains(_smithy_blurb()), printed)
    assert_false(printed.contains("Reach Respected"),
        "a flag-off build must not promise the rank would open it: %s" % printed)

func test_a_met_rank_stops_taking_the_blame_for_a_missing_screen() -> void:
    # There is no Blacksmith screen yet. Once flag, rank and price are all satisfied
    # the reason must fall through to the honest one, or the rank gate becomes the
    # permanent excuse for unbuilt work and nobody notices the screen is missing.
    var printed := _town_text("Open Gate", Enums.ReputationRank.RESPECTED, 999, true)
    assert_true(printed.contains("Not built in this version yet."), printed)
    assert_false(printed.contains("Costs 300 G"))

func test_a_shut_door_is_a_disabled_button_whose_reason_is_printed() -> void:
    # docs/13 §7 forbids a disabled control that is a mystery, and a reason carried
    # only by a tooltip is invisible to a keyboard player and to these tests alike.
    _ensure_autoloads()
    var st = _state()
    st.new_game("Label Not Tooltip")
    st.flags["blacksmith"] = true
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(TOWN)
    var screen := r.current_screen()
    var btn = _find_button(screen, "Blacksmith")
    assert_ne(btn, null, "the callout must still be on the square, not hidden")
    assert_true((btn as Button).disabled, "and it must not be pressable")
    assert_true(_joined(screen).contains("Reach Respected"),
        "with its reason in text the tests and a screen reader can both see")
    st.reset()

func test_the_town_says_what_the_next_rank_opens() -> void:
    # docs/03 §7's Town-unlock column had one caller before this — a test — so the
    # rank was a word with no promise attached. The Adventure's Board already prints
    # the Content column; this is the town half of the same table.
    var printed := _town_text("Promise", Enums.ReputationRank.UNKNOWN, 60, false)
    assert_true(printed.contains("Next at Known"), printed)
    assert_true(printed.contains("Quest board"),
        "and it must name what Known actually opens: %s" % printed)

func test_the_town_never_promises_a_building_the_build_ships_off() -> void:
    # LOOP-06 / CRITIC-C4: docs/03 §7's Respected row is "Blacksmith opens", and
    # the Blacksmith flag ships off (ship plan §6 #10). A Known guild used to be
    # told "Next at Respected: Blacksmith opens." by an executable that does
    # not contain one. The row is read through `town_unlock_for_build`, which
    # drops the flagged-off building — and with the flag ON the promise returns.
    var off := _town_text("Honest Town", Enums.ReputationRank.KNOWN, 60, false)
    assert_true(off.contains("Next at Respected"), off)
    assert_false(off.contains("Blacksmith opens"),
        "a flag-off build must not promise the smithy: %s" % off)
    assert_true(off.contains("Next at Respected: better rates at the Market."),
        "what a rank always buys, when nothing in town opens: %s" % off)
    var on := _town_text("Smithy Town", Enums.ReputationRank.KNOWN, 60, true)
    assert_true(on.contains("Blacksmith opens"),
        "with the flag on docs/03 §7's own line is back: %s" % on)
    # Established's row keeps its Guildhall half and loses its Blacksmith half.
    var later := _town_text("Half Row", Enums.ReputationRank.RESPECTED, 60, false)
    assert_true(later.contains("Guildhall facility upgrade II"), later)
    assert_false(later.contains("Blacksmith tier 2"), later)

func test_the_town_unlock_rows_are_ids_the_sim_can_filter() -> void:
    # M3-TUNE-05's shape: every town_unlock item names one of docs/02 §2.3's
    # buildings (or none), so the filter above is a lookup, never string
    # surgery — and the prose docs/03 §7 prints is the items joined.
    var Reputation = load("res://sim/core/Reputation.gd")
    var Buildings = load("res://sim/core/Buildings.gd")
    for rank in Enums.REPUTATION_KEYS.size():
        var items: Array = Reputation.town_unlock_items(rank)
        assert_true(items.size() > 0, "rank %d names what it opens" % rank)
        for item in items:
            var b := String(item["building"])
            assert_true(b.is_empty() or Buildings.LADDERS.has(b),
                "'%s' is not a docs/02 building id" % b)
    assert_eq(Reputation.town_unlock(Enums.ReputationRank.KNOWN),
        "Guildhall facility upgrade I; Quest board", "docs/03 §7's prose, joined")
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.RESPECTED,
        {"blacksmith": false}), "", "Respected opens nothing this build mounts")
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.RESPECTED,
        {"blacksmith": true}), "Blacksmith opens")
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.RESPECTED, {}),
        "Blacksmith opens", "a building with no flag in the map is always kept")

func test_a_legendary_guild_is_not_promised_a_seventh_rank() -> void:
    # docs/03 §7's table clamps, so asking it for the rank above Legendary hands back
    # Legendary's own row. Printed as a promise it would be a ladder that never ends.
    var printed := _town_text("Topped Out", Enums.ReputationRank.LEGENDARY, 60, false)
    assert_true(printed.contains("the highest standing there is"), printed)
    assert_true(printed.contains("Guildhall facility upgrade IV"),
        "and it still prints Legendary's own row: %s" % printed)
    assert_false(printed.contains("Next at"), "but not as something still ahead")

func test_the_boards_level_is_printed_and_moves_with_the_rank() -> void:
    # ✅ CANON "New Tiers can be unlocked by gaining reputations with the town."
    # docs/02 §11 prices the Board's rungs at 0 for that reason; until now nothing
    # advanced them and nothing read them, so the ladder was data with no effect.
    var unknown := _town_text("Board One", Enums.ReputationRank.UNKNOWN, 60, false)
    assert_true(unknown.contains("Level 1 of 3"), unknown)
    assert_true(unknown.contains("reputation raises this, not gold"),
        "and it must say which currency climbs it: %s" % unknown)
    var respected := _town_text("Board Three", Enums.ReputationRank.RESPECTED, 60, false)
    assert_true(respected.contains("Level 3 of 3"),
        "docs/02 §11 puts the Board's top rung at Respected: %s" % respected)

func test_a_reasoned_button_is_disabled_and_carries_its_reason() -> void:
    var box := Widgets.button_with_reason("Continue", "No saved guild found.")
    _made.append(box)
    var btn := Widgets.button_of(box)
    assert_ne(btn, null, "button_of must find the button it made")
    assert_true(btn.disabled)
    assert_true(_joined(box).contains("No saved guild found."))

func test_a_button_with_no_reason_is_enabled() -> void:
    var box := Widgets.button_with_reason("Go", "")
    _made.append(box)
    assert_false(Widgets.button_of(box).disabled)

func test_palette_maps_every_rarity_and_clamps_out_of_range() -> void:
    assert_eq(Palette.RARITY.size(), Enums.RARITY_KEYS.size(),
        "one colour per canon rarity")
    for r in Enums.all_rarities():
        assert_ne(Palette.rarity_color(r), Palette.TEXT_MUTED)
    assert_eq(Palette.rarity_color(-1), Palette.TEXT_MUTED)
    assert_eq(Palette.rarity_color(99), Palette.TEXT_MUTED)

func test_morale_colour_moves_through_the_at_risk_end() -> void:
    assert_eq(Palette.morale_color(14), Palette.DANGER, "canon's Steve at 14 is red")
    assert_eq(Palette.morale_color(45), Palette.CAUTION)
    assert_eq(Palette.morale_color(90), Palette.POSITIVE)

func test_no_pure_black_or_white_in_the_palette() -> void:
    # docs/12 §4.2 rule 4: #000000 and #FFFFFF are banned from the palette.
    # The reference palette's tokens (art/ref/specs/04); the paper-era aliases
    # were removed with the last converted screen.
    var all := [Palette.GROUND_PAGE, Palette.GROUND_FRAME, Palette.GROUND_RAIL,
        Palette.SURFACE_PANEL, Palette.SURFACE_INSET, Palette.EDGE_SLATE,
        Palette.EDGE_BRONZE, Palette.TEXT_TITLE, Palette.TEXT_BODY,
        Palette.TEXT_MUTED, Palette.TEXT_SLATE, Palette.CTA_TOP, Palette.DANGER,
        Palette.CAUTION, Palette.POSITIVE, Palette.ACCENT_GOLD]
    all.append_array(Palette.RARITY)
    for c in all:
        assert_ne(Color(c).to_html(false), "000000", "pure black is banned")
        assert_ne(Color(c).to_html(false), "ffffff", "pure white is banned")

# ------------------------------------------------------- S17, the completion screen

## docs/13 §5 S17 (spec in §9.5), propagated from docs/10 §13 row 1 by docs/15
## BL-73. The screen is a REPORT and a door back to town — docs/15 Q-88 rules
## that the save continues past the beat — so what these tests pin is that every
## figure on it comes from the campaign, that it fires exactly once, and that the
## way out leads home.
##
## A guild reaches it only after clearing the last encounter of the last tier,
## which no shipped save can do yet (tier 5's words are pending, docs/15 BL-69).
## So the state is set here directly. That is the honest shape of the claim: the
## screen is built and tested against the beat the engine already sets.

func _finished_guild(day: int = 91):
    var st = _state()
    st.new_game("Ashfall Company")
    st.day = day
    st.completed = true
    st.completed_on_day = day
    st.completion_seen = false
    return st

func test_the_ending_reports_the_run_it_is_about() -> void:
    _ensure_autoloads()
    var st = _finished_guild()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(COMPLETION)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("Ashfall Company"), "the guild is named: %s" % printed)
    assert_true(printed.contains("day 91"), "the day the campaign ended is printed")
    assert_true(printed.contains(st.rank_name()), "and the rank it ended at")
    assert_true(printed.contains("Gold in the strongbox"), "the run's tally is on it")
    st.reset()

func test_the_legendary_denominator_is_the_class_list() -> void:
    # docs/10 §13 row 2's collection meter. Nine is never typed: it is the length
    # of the class list, so the meter cannot drift away from canon's
    # "1 Legendary per class" if a class is ever added or cut.
    _ensure_autoloads()
    var st = _finished_guild()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(COMPLETION)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("Legendaries 0 of %d" % Enums.CLASS_KEYS.size()),
        "the meter reads against the class list: %s" % printed)
    st.reset()

func test_the_beat_is_spent_on_arrival_not_on_exit() -> void:
    # docs/15 BL-73: a player who closes the game while reading their ending has
    # seen it. Flipping the flag on the button press would replay it at them.
    _ensure_autoloads()
    var st = _finished_guild()
    assert_false(st.completion_seen, "precondition: the beat has not been shown")
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(COMPLETION)
    assert_true(st.completion_seen, "building the screen spends the beat")
    st.reset()

func test_the_town_is_reachable_from_the_ending() -> void:
    # The save continues, so the ending has exactly one exit and it goes home.
    #
    # The AUTOLOAD router, not a local one: the button is wired to whatever
    # `Services.router()` finds, so driving a locally constructed Router would
    # watch the press land somewhere else and report a false pass.
    _ensure_autoloads()
    var st = _finished_guild()
    var r = _root.get_node_or_null("ScreenRouter")
    r.register_host(_host())
    r.goto(COMPLETION)
    var back = _find_button(r.current_screen(), "Back to town — the guild carries on")
    assert_true(back != null, "the one continue button must be on the screen")
    back.pressed.emit()
    assert_eq(r.current_path(), TOWN, "and it returns to the town")
    st.reset()

func test_the_credits_block_is_read_from_the_file_and_printed_verbatim() -> void:
    # docs/15 BL-73: who the game credits is a person's signature — the register
    # question and audit M5-END-4 are both named in data/credits.json itself — so
    # the screen prints what that file says and invents nothing. Until the roll is
    # signed off, what it says is one status line.
    _ensure_autoloads()
    var lines: Array = CompletionScript.credit_lines()
    var st = _finished_guild()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(COMPLETION)
    var printed := _joined(r.current_screen())
    for line in lines:
        if String(line).is_empty():
            continue
        assert_true(printed.contains(String(line)),
            "the screen must print the file's line verbatim: %s" % String(line))
    st.reset()

func test_an_unsigned_credits_roll_prints_the_guild_and_nothing_about_itself() -> void:
    # LOOP-27 / C8: the file's `status` paragraph — "The credits are not
    # written yet … recorded as docs/15 Q-21 and audit M5-END-4" — is the
    # record for the person who signs the roll, and it reached the player.
    # The screen prints the roster block and the file's non-marker `lines`;
    # with those empty, nothing else. A "[…]" line is a marker, never printed.
    var doc: Dictionary = JSON.parse_string(
        FileAccess.get_file_as_string(CompletionScript.CREDITS_PATH))
    var status := String(doc.get("status", ""))
    var lines: Array = CompletionScript.credit_lines()
    for line in lines:
        assert_false(CompletionScript.is_marker(String(line)),
            "a marker is never one of the printed lines: %s" % String(line))
        assert_false(String(line).to_lower().contains("not written"), String(line))
    assert_true(CompletionScript.is_marker("[designer credit pending]"))
    assert_false(CompletionScript.is_marker("Design: somebody"))
    _ensure_autoloads()
    var st = _finished_guild()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(COMPLETION)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("Ashfall Company"), "the guild is the roll")
    assert_false(printed.to_lower().contains("not written yet"),
        "the status paragraph is not printed: %s" % printed)
    if not status.is_empty():
        assert_false(printed.contains(status), "the file's status is for the signer")
    for word in ["docs/", "audit", "sign-off"]:
        assert_false(printed.to_lower().contains(word),
            "the ending says '%s' to the player: %s" % [word, printed])
    st.reset()

# ------------------------------------------------------- S12 routes into S17

## The beat cannot be walked past by accident: on the clear that ends the
## campaign the Results screen's two ordinary exits collapse to one crimson
## commit. docs/15 BL-73.

func _reported_attempt(st):
    # A real attempt, because Results reads the result record rather than a flag.
    var enc = st.content.encounter("t1_raid_e1")
    var party: Array = st.roster.slice(0, mini(int(enc.party_size), st.roster.size()))
    st.last_result = RaidSim.run(party, enc, st.content, 7, st.build_loadout(party))
    return st

func _results_buttons(finished: bool, seen: bool) -> String:
    _ensure_autoloads()
    var st = _state()
    st.set_content(DB.load_all())
    st.new_game("Ashfall Company")
    _reported_attempt(st)
    st.completed = finished
    st.completion_seen = seen
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(RESULTS)
    var printed := _joined(r.current_screen())
    # This file's other tests use a CONTENTLESS GameState — `new_game()` on one
    # with content builds the starting twelve, and "Roster 0 of 15" depends on it
    # not having. Put the autoload back the way it was found.
    st.reset()
    st.content = null
    return printed

func test_the_completing_clear_offers_the_ending_and_nothing_else() -> void:
    var printed := _results_buttons(true, false)
    assert_true(printed.contains("See how it ended"),
        "the ending must be the only exit on the clear that ends it: %s" % printed)
    assert_false(printed.contains("Return to town"),
        "the ordinary exits stand down so the beat cannot be missed")

func test_an_ordinary_clear_keeps_the_ordinary_exits() -> void:
    var printed := _results_buttons(false, false)
    assert_true(printed.contains("Return to town"))
    assert_true(printed.contains("Back to the board"))
    assert_false(printed.contains("See how it ended"),
        "a guild that has not finished is not shown an ending")

func test_a_seen_ending_is_not_offered_again() -> void:
    # A farm run of the last boss is not a second ending.
    var printed := _results_buttons(true, true)
    assert_false(printed.contains("See how it ended"),
        "the beat fires once: %s" % printed)
    assert_true(printed.contains("Return to town"), "and the ordinary exits come back")

func test_the_records_tab_can_reopen_the_ending() -> void:
    # A report the player can never open again is a cutscene (docs/15 BL-73).
    _ensure_autoloads()
    var st = _finished_guild()
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(GUILDHALL)
    var screen = r.current_screen()
    var tab = _find_button(screen, "Records")
    assert_true(tab != null and not tab.disabled,
        "docs/03 §7 opens the Records tab at Known — precondition for this test")
    tab.pressed.emit()
    assert_true(_find_button(screen, "Read the ending again") != null,
        "a finished guild can re-read its ending from Records: %s" % _joined(screen))
    st.reset()

func test_a_guild_that_has_not_finished_has_no_ending_to_reread() -> void:
    _ensure_autoloads()
    var st = _state()
    st.new_game("Ashfall Company")
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(GUILDHALL)
    var screen = r.current_screen()
    var tab = _find_button(screen, "Records")
    assert_true(tab != null and not tab.disabled)
    tab.pressed.emit()
    assert_true(_find_button(screen, "Read the ending again") == null,
        "the link appears only once there is an ending")
    st.reset()

# ------------------------------------------------- the post-clear surfaces (M5-END-3)

## docs/10 §13 row 2: after the last clear the continuing activity is the Legendary
## collection, the record wall, and repeat clears. Two of those three are engine
## work that was already done and invisible; these are the surfaces that say so.
##
## docs/16 R-4 calls doc 10 §13 "a standing invitation to invent an endgame" and
## lists Tier 6 and a heroic mode as CUT. So the stated goal IS the endgame's UI,
## and `test_the_board_offers_no_endgame_mode` is here to keep it that way.

func test_the_board_states_the_goal_once_the_campaign_is_finished() -> void:
    _ensure_autoloads()
    var st = _state()
    st.new_game("Finished Guild")
    st.completed = true
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(BOARD)
    var printed := _joined(r.current_screen())
    assert_true(printed.contains("The campaign is finished. The guild is not."),
        "the board must say the ladder is done: %s" % printed)
    assert_true(printed.contains("Legendaries 0 of %d" % Enums.CLASS_KEYS.size()),
        "and name what is left, against the class list: %s" % printed)
    assert_true(printed.contains("Records 0 of"), "including the record wall")
    st.reset()

func test_an_unfinished_guild_is_told_about_ranks_not_endings() -> void:
    _ensure_autoloads()
    var st = _state()
    st.new_game("Working Guild")
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(BOARD)
    var printed := _joined(r.current_screen())
    assert_false(printed.contains("The campaign is finished"),
        "a guild mid-ladder has not finished anything: %s" % printed)
    st.reset()

func test_a_walked_out_ladder_says_so_on_the_hub_and_the_board() -> void:
    # LOOP-07: after Raid 1's last encounter the campaign is not `completed`
    # (that is tier 5's last clear, and tiers 2-5 are pending — docs/15 BL-69),
    # so the hub used to pin "Adventure 0 · CLEARED" as "Next mission" and the
    # board said nothing. Every tier-1 rung cleared: the Town's card prints
    # the walked-out sentence and the board names what the road is waiting on.
    _ensure_autoloads()
    var st = _state()
    st.set_content(DB.load_all())
    st.new_game("Walked Out")
    var RaidPlan = load("res://game/core/RaidPlan.gd")
    for e in RaidPlan.ladder(st):
        st.cleared[String(e.id)] = 1
    assert_eq(RaidPlan.next_open_mission(st), null, "precondition: nothing left to open")
    assert_false(bool(st.completed), "precondition: the campaign is not finished")
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(TOWN)
    var town := _joined(r.current_screen())
    assert_true(town.contains("The ladder is walked out"),
        "the hub's card must not pin a cleared rung as the next mission: %s" % town)
    assert_false(town.contains("Adventure 0"), "no cleared rung under 'Next mission'")
    r.goto(BOARD)
    var board := _joined(r.current_screen())
    assert_true(board.contains("Raid 1 is cleared. The road past it is not open yet."),
        "the board states the goal and what it waits on: %s" % board)
    assert_false(board.contains("The campaign is finished"),
        "which is not the same as the ending")
    st.reset()
    st.content = null

func test_the_board_offers_no_endgame_mode() -> void:
    # docs/10 §13's closing paragraph refuses to invent a Tier 6 or a heroic
    # difficulty, docs/00 §6.3 stops 1.0 at Raid 5, and docs/16 R-4 lists both as
    # cut. The post-clear board states a goal; it does not open a mode. This test
    # exists because the invitation to add one is standing and written down.
    _ensure_autoloads()
    var st = _state()
    st.new_game("Finished Guild")
    st.completed = true
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(BOARD)
    var printed := _joined(r.current_screen()).to_lower()
    for banned in ["tier 6", "heroic", "new game+", "prestige", "difficulty"]:
        assert_false(printed.contains(banned),
            "the post-clear board must not offer '%s'" % banned)
    st.reset()

func test_the_records_tab_carries_the_collection_meter() -> void:
    # docs/10 §13 row 2's other surface. The Guildhall is where the wall lives, so
    # the two meters are read side by side: what has been collected, what has been
    # recorded.
    _ensure_autoloads()
    var st = _state()
    st.new_game("Records Guild")
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(GUILDHALL)
    var screen = r.current_screen()
    var tab = _find_button(screen, "Records")
    assert_true(tab != null and not tab.disabled,
        "docs/03 §7 opens the Records tab at Known — precondition for this test")
    tab.pressed.emit()
    var printed := _joined(screen)
    assert_true(printed.contains("Legendaries 0 of %d" % Enums.CLASS_KEYS.size()),
        "the collection meter belongs beside the record wall: %s" % printed)
    # The tab's own heading spaces the figure wider than the one-line summary does.
    assert_true(printed.contains("Records  0 of"), "and the wall's own count")
    st.reset()

# ------------------------------------------- S14's claim control (M5-QAB-6)

## docs/14 OQ-10 splits the board in two: `Achievements` decides what is owed and
## GameState is the hand that pays. The Records tab is neither — it prints the
## reward in the board's own words and presses the hand — and until this landed it
## had a `_record_notice` field, a comment describing "Claimed 25 G, or why not",
## and no control at all.

func _records_tab(st):
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto(GUILDHALL)
    var screen = r.current_screen()
    var tab = _find_button(screen, "Records")
    assert_true(tab != null and not tab.disabled,
        "docs/03 §7 opens the Records tab at Known — precondition for this test")
    tab.pressed.emit()
    return screen

func test_an_earned_record_offers_its_claim() -> void:
    _ensure_autoloads()
    var st = _state()
    st.new_game("Board Guild")
    st.achievements_earned["prog_adventure_0"] = st.day
    var screen = _records_tab(st)
    assert_true(_find_button(screen, "Claim") != null,
        "an earned record must be claimable from the wall: %s" % _joined(screen))
    st.reset()

func test_a_locked_record_shows_its_prize_and_no_button() -> void:
    # docs/02 §4.4 makes the wall a thing you aim at, so a locked row still prints
    # what it pays — but pressing it is not on offer.
    _ensure_autoloads()
    var st = _state()
    st.new_game("Board Guild")
    var screen = _records_tab(st)
    assert_true(_find_button(screen, "Claim") == null,
        "nothing is earned, so nothing is claimable")
    assert_true(_joined(screen).contains("G"), "and the rewards are still printed")
    st.reset()

func test_the_refusal_is_printed_where_the_press_was() -> void:
    # docs/13 §7: a control that refuses says why. The coin cap is the refusal the
    # player will actually meet — a guild that has earned no income cannot be paid
    # a share of it, and docs/11 §11.2 wants that said rather than paid smaller.
    _ensure_autoloads()
    var st = _state()
    st.new_game("Board Guild")
    st.gold_earned_lifetime = 0
    st.achievements_earned["prog_raid_1"] = st.day
    var screen = _records_tab(st)
    var claim = _find_button(screen, "Claim")
    assert_true(claim != null, "precondition: the record is earned and offered")
    claim.pressed.emit()
    assert_true(_joined(screen).contains("paid its share"),
        "the board's own sentence, on the screen that asked: %s" % _joined(screen))
    st.reset()

# --------------------------- docs/13 §13's emoji-free row, on every screen that
# --------------------------- shows a morale reading (M6-A11Y-04)

## "Replaces morale glyphs with a 10-step monochrome pip figure. The integer and
## state word are unaffected."
##
## `GameSettings.morale_glyph()` implemented that from the day the option shipped
## and was read by ONE screen out of eight. Every other site reached straight past
## it to `Enums.MORALE_BAND_EMOJI`, so a player who turned the option on got a
## pip figure on the raider detail panel and emoji everywhere else — on the
## Roster, in raid prep, on the Market's comfort line and in the Guildhall's
## low-morale list. The Settings screen offered it with an empty `reason`, i.e.
## as fully live.
##
## `Cards.morale_glyph()` is the one door now and `tools/lint_motion.sh` is the
## lock. These tests are the other half: the lint proves nobody reads the table,
## and this proves the door actually swaps what it renders.

const MORALE_SCREENS := [
    "res://game/screens/Guildhall.tscn",
    "res://game/screens/Tavern.tscn",
    "res://game/screens/Market.tscn",
    "res://game/screens/RaiderDetail.tscn",
]


func _with_emoji_free(on: bool) -> Node:
    var gs = _root.get_node_or_null("GameSettings")
    if gs == null:
        gs = SettingsScript.new()
        gs.name = "GameSettings"
        _root.add_child(gs)
        _made.append(gs)
    gs.set_value("emoji_free", on)
    return gs


func _emoji_in(text: String) -> String:
    for glyph in Enums.MORALE_BAND_EMOJI:
        if text.contains(String(glyph)):
            return String(glyph)
    return ""


func test_the_pip_figure_really_is_a_substitution() -> void:
    # The helper first, on its own: same band, different rendering, and the pip
    # figure carries the band as a LENGTH so it is readable without colour.
    var gs = _with_emoji_free(false)
    var emoji := String(Cards.morale_glyph(_root, 87))
    gs.set_value("emoji_free", true)
    var pips := String(Cards.morale_glyph(_root, 87))
    assert_ne(emoji, pips, "the option must change what is drawn")
    assert_eq(_emoji_in(pips), "", "and what it draws must carry no emoji")
    assert_true(pips.length() > 0)
    gs.set_value("emoji_free", false)


func test_no_screen_shows_an_emoji_once_the_option_is_on() -> void:
    # The regression this closes: seven of eight screens ignored the setting.
    _ensure_autoloads()
    var gs = _with_emoji_free(true)
    var st = _state()
    st.set_content(DB.load_all())
    st.new_game("Pip Guild")
    st.reputation_rank = Enums.ReputationRank.KNOWN
    for path in MORALE_SCREENS:
        var r = Router.new()
        _made.append(r)
        r.register_host(_host())
        r.goto(path)
        var printed := _joined(r.current_screen())
        assert_eq(_emoji_in(printed), "",
            "%s still draws %s with emoji_free on" % [path, _emoji_in(printed)])
    gs.set_value("emoji_free", false)
    st.reset()
    st.content = null


func test_the_integer_and_the_state_word_are_unaffected() -> void:
    # docs/13 §13's promise in the same sentence, and the reason the option is
    # safe: emoji-free removes a channel the reading does not depend on. Four
    # channels minus the glyph is still three, and the two that carry the value
    # are untouched.
    _ensure_autoloads()
    var gs = _with_emoji_free(true)
    var st = _state()
    st.set_content(DB.load_all())
    st.new_game("Pip Guild")
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto("res://game/screens/Tavern.tscn")
    var printed := _joined(r.current_screen())
    var found_word := false
    for morale in [5, 15, 25, 35, 45, 55, 65, 75, 85, 95]:
        if printed.contains(Enums.morale_band_name(morale)):
            found_word = true
    assert_true(found_word, "the state word survives emoji-free mode: %s" % printed)
    gs.set_value("emoji_free", false)
    st.reset()
    st.content = null


func test_the_emoji_come_back_when_the_option_is_off() -> void:
    # A substitution, not a deletion — and proof the screens are reading the
    # setting rather than having had their glyphs removed.
    _ensure_autoloads()
    var gs = _with_emoji_free(false)
    var st = _state()
    st.set_content(DB.load_all())
    st.new_game("Emoji Guild")
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    r.goto("res://game/screens/Tavern.tscn")
    assert_ne(_emoji_in(_joined(r.current_screen())), "",
        "with the option off the Tavern shows canon's glyphs")
    st.reset()
    st.content = null
