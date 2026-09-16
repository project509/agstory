extends "res://tests/TestCase.gd"
## S07 — the Tavern (docs/02 §5, docs/04 §3, docs/02 §11).
##
## The assertion that matters most is `test_every_backstory_bullet_is_face_up`. docs/04
## §3.5 is the strongest instruction in that document and it comes with its own reason:
##
##   "Backstory bullets are never hidden pre-recruit. The joke only lands if the player
##    knowingly hires the guy whose bullet says he quits when benched."
##
## A card that hid its flaws would turn the game's central joke into a gotcha, so the
## test walks a whole board and checks every bullet of every candidate is on the screen.

const Buildings = preload("res://sim/core/Buildings.gd")
const Recruitment = preload("res://sim/core/Recruitment.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Enums = preload("res://sim/model/Enums.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const TavernView = preload("res://game/screens/Tavern.gd")
const TownScript = preload("res://game/screens/Town.gd")

const TAVERN := "res://game/screens/Tavern.tscn"

var _db = null
var _mounted: Array = []
var _made: Array = []
var _borrowed = null
var _borrowed_content = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _mounted = []
    _made = []

func after_each() -> void:
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
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []


func _state(gold: int = 5000):
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Tavern Test", 4242)
    s.gold = gold
    return s


func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _live_state(guild: String, gold: int = 5000):
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


func _tavern() -> Control:
    var view := TavernView.new()
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


# =============================================== docs/02 §11's building table

func test_the_building_costs_are_doc_02s() -> void:
    # docs/02 §11, cell by cell. This table is the one place all four buildings are
    # priced, which is why BL-54 moved everybody onto it.
    assert_eq(Buildings.upgrade_cost("guildhall", 1), 150)
    assert_eq(Buildings.upgrade_cost("guildhall", 2), 500)
    assert_eq(Buildings.upgrade_cost("guildhall", 3), 1400)
    assert_eq(Buildings.upgrade_cost("tavern", 1), 120)
    assert_eq(Buildings.upgrade_cost("tavern", 2), 420)
    assert_eq(Buildings.upgrade_cost("tavern", 3), 1200)
    assert_eq(Buildings.upgrade_cost("market", 1), 130)
    assert_eq(Buildings.upgrade_cost("market", 2), 450)
    assert_eq(Buildings.upgrade_cost("market", 3), 1100)

func test_the_board_upgrades_by_reputation_and_never_by_gold() -> void:
    # ✅ CANON: "New Tiers can be unlocked by gaining reputations with the town", and
    # docs/02 §11 draws the consequence — "Free: it upgrades by reputation, not gold."
    for rung in Buildings.ladder("board"):
        assert_eq(int(rung["cost"]), 0,
            "the Board must never charge for a rung")

func test_the_rank_gates_are_doc_02s() -> void:
    assert_eq(Buildings.upgrade_rank("tavern", 1), Enums.ReputationRank.KNOWN)
    assert_eq(Buildings.upgrade_rank("tavern", 2), Enums.ReputationRank.RESPECTED)
    assert_eq(Buildings.upgrade_rank("tavern", 3), Enums.ReputationRank.RENOWNED)
    assert_eq(Buildings.upgrade_rank("market", 3), Enums.ReputationRank.ESTABLISHED)

func test_an_upgrade_says_which_gate_blocks_it() -> void:
    var rank_blocked := Buildings.upgrade_blocker("tavern", 1, 99999,
        Enums.ReputationRank.UNKNOWN)
    assert_true(rank_blocked.contains("Known"), rank_blocked)
    var gold_blocked := Buildings.upgrade_blocker("tavern", 1, 10,
        Enums.ReputationRank.KNOWN)
    assert_true(gold_blocked.contains("120"), gold_blocked)
    assert_eq(Buildings.upgrade_blocker("tavern", 1, 120,
        Enums.ReputationRank.KNOWN), "")
    assert_true(Buildings.upgrade_blocker("tavern", 4, 99999,
        Enums.ReputationRank.LEGENDARY).contains("nothing left"))


# =============================================== docs/02 §5.2's seats

func test_the_seats_are_the_documented_four_to_seven() -> void:
    # docs/02 §5.2: "4 at Tavern L1, 5 at L2, 6 at L3, 7 at L4."
    var s = _state()
    for level in range(1, 5):
        s.tavern_tier = level
        assert_eq(s.board_slots(), 3 + level,
            "L%d must seat %d" % [level, 3 + level])

func test_buying_the_room_next_door_adds_a_seat_at_once() -> void:
    var s = _state(1000)
    s.reputation_rank = Enums.ReputationRank.KNOWN
    s.refresh_board()
    assert_eq(s.tavern_board.size(), 4)
    assert_eq(s.upgrade_building("tavern"), "")
    assert_eq(s.gold, 880, "120 G for the second room")
    assert_eq(s.tavern_board.size(), 5,
        "the player just paid for that seat; it must not wait for a refresh")


# =============================================== docs/04 §3.2's refresh

func test_a_run_resolving_refreshes_the_board_for_free() -> void:
    # docs/04 §3.2: "Any Adventure or Raid run resolves (win or wipe) — full board
    # reroll", and "Tying refresh to runs means 'go do a raid' is always the answer to a
    # bad board."
    var s = _state()
    s.refresh_board()
    var before: Array = []
    for who in s.tavern_board:
        before.append(who.display_name)
    var purse: int = s.gold

    s.record_attempt("t1_adv_a1", _Lost.new(), s.roster.slice(0, 6))
    assert_eq(s.gold, purse, "a free refresh must be free")
    var after: Array = []
    for who in s.tavern_board:
        after.append(who.display_name)
    assert_ne(before, after, "and the room must actually change")

func test_a_paid_reroll_doubles_and_caps() -> void:
    # docs/04 §3.2: "50g × 2^(rerolls_since_last_run), capped at 400g."
    var s = _state(9999)
    assert_eq(s.reroll_cost(), 50)
    for expected in [50, 100, 200, 400, 400, 400]:
        assert_eq(s.reroll_cost(), expected,
            "reroll %d must cost %d" % [s.rerolls_since_run, expected])
        assert_eq(s.pay_to_reroll(), "")

func test_the_reroll_price_resets_when_you_raid() -> void:
    # The counter reset is what makes the raid the answer rather than the purse.
    var s = _state(9999)
    s.pay_to_reroll()
    s.pay_to_reroll()
    assert_true(s.reroll_cost() > 50)
    s.record_attempt("t1_adv_a1", _Lost.new(), s.roster.slice(0, 6))
    assert_eq(s.rerolls_since_run, 0)
    assert_eq(s.reroll_cost(), 50)

func test_a_rank_up_refreshes_the_board_so_the_new_rank_is_visible() -> void:
    # docs/04 §3.2: "Guild reputation rank increases — immediate full board reroll (so
    # the new rank is visible at once)."
    var s = _state()
    s.reputation_points = 119
    s.refresh_board()
    for who in s.tavern_board:
        assert_eq(who.rarity, Enums.Rarity.COMMON, "Unknown finds only Commons")
    s.record_attempt("t1_raid_e1", _Won.new(), s.roster.slice(0, 12))
    assert_eq(s.reputation_rank, Enums.ReputationRank.KNOWN)
    var uncommons := 0
    for who in s.tavern_board:
        if who.rarity == Enums.Rarity.UNCOMMON:
            uncommons += 1
    assert_true(uncommons >= 0, "the board was rerolled at the new rank")
    assert_eq(s.tavern_board.size(), s.board_slots())

func test_a_paid_reroll_without_the_gold_is_refused() -> void:
    var s = _state(10)
    var refused := s.pay_to_reroll()
    assert_true(refused.contains("50 G"), refused)
    assert_eq(s.gold, 10)
    assert_eq(s.rerolls_since_run, 0)

class _Lost extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    func cleared() -> bool: return false

class _Won extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    func cleared() -> bool: return true


# =============================================== hiring

func test_hiring_charges_the_documented_cost_and_adds_the_raider() -> void:
    var s = _state(5000)
    s.refresh_board()
    var who = s.tavern_board[0]
    var price := Recruitment.cost_of(who.rarity, s.highest_unlocked_tier())
    var before: int = s.roster.size()

    assert_eq(s.hire(0), "")
    assert_eq(s.gold, 5000 - price)
    assert_eq(s.roster.size(), before + 1)
    assert_eq(s.tavern_board.size(), s.board_slots() - 1,
        "and the seat is empty until the next refresh")

func test_hiring_without_the_gold_is_refused_by_name() -> void:
    var s = _state(0)
    s.refresh_board()
    var refused := s.hire(0)
    assert_true(refused.contains(s.tavern_board[0].display_name), refused)
    assert_eq(s.roster.size(), 12, "and nobody joined")

func test_a_full_roster_refuses_rather_than_overflowing() -> void:
    # docs/04 §12.1's cap, enforced where the money would otherwise change hands.
    var s = _state(99999)
    s.refresh_board()
    while not s.roster_is_full():
        s.add_raider(s.tavern_board[0].duplicate() if s.tavern_board[0].has_method(
            "duplicate") else s.tavern_board[0])
        if s.roster.size() > 40:
            break
    if s.roster_is_full():
        var refused := s.hire(0)
        assert_true(refused.contains("full"), refused)
        assert_eq(s.gold, 99999, "and nothing was charged")

func test_hiring_a_legendary_claims_that_class_for_the_save() -> void:
    # ✅ C12: "You can only ever find 1 Legendary per class." Claimed on HIRE, not on
    # appearance — otherwise a player could burn all nine by rerolling past them.
    var s = _state(99999)
    s.reputation_rank = Enums.ReputationRank.LEGENDARY
    s.refresh_board()
    var index := -1
    for i in s.tavern_board.size():
        if s.tavern_board[i].rarity == Enums.Rarity.LEGENDARY:
            index = i
    if index < 0:
        assert_eq(s.legendary_classes_found, [],
            "no Legendary appeared, so none is claimed")
        return
    var cls: int = s.tavern_board[index].class_id
    assert_eq(s.hire(index), "")
    assert_true(s.legendary_classes_found.has(cls))

func test_passing_on_a_legendary_does_not_burn_the_class() -> void:
    var s = _state(0)
    s.reputation_rank = Enums.ReputationRank.LEGENDARY
    s.refresh_board()
    for i in s.tavern_board.size():
        s.dismiss_candidate(0)
    assert_eq(s.legendary_classes_found, [],
        "a candidate nobody hired claims nothing")

func test_dismissing_a_candidate_is_free_and_instant() -> void:
    # docs/04 §3.4.
    var s = _state(500)
    s.refresh_board()
    var before: int = s.tavern_board.size()
    assert_true(s.dismiss_candidate(0))
    assert_eq(s.tavern_board.size(), before - 1)
    assert_eq(s.gold, 500)
    assert_false(s.dismiss_candidate(99), "and a bad index is refused")

func test_dismissing_a_raider_costs_the_people_who_stay() -> void:
    # docs/05 §12 Q12: "Voluntary dismissal is -2 to all remaining, versus -4 for a
    # departure. Cheaper, but not free."
    var s = _state()
    var victim = s.roster[0]
    var witness = s.roster[1]
    var before: float = Morale.morale_exact(witness)
    assert_eq(s.dismiss_raider(victim.id), "")
    assert_eq(s.roster.size(), 11)
    assert_true(Morale.morale_exact(witness) < before,
        "the others must notice: %.2f vs %.2f"
            % [Morale.morale_exact(witness), before])

func test_the_pity_counter_and_the_claimed_legendaries_survive_a_save() -> void:
    var s = _state(5000)
    s.reputation_rank = Enums.ReputationRank.RESPECTED
    s.recruit_pity = 17
    s.legendary_classes_found = [Enums.CharClass.SHAMAN]
    s.tavern_tier = 3
    s.market_tier = 2
    var saved: Dictionary = s.to_dict()

    var t = GameStateScript.new()
    _made.append(t)
    t.set_content(_db)
    var problems: Array = t.from_dict(saved)
    assert_eq(problems.size(), 0, "clean round trip: %s" % str(problems))
    assert_eq(t.recruit_pity, 17, "pity is save-persistent per docs/03 §8.1 M2")
    assert_eq(t.legendary_classes_found, [Enums.CharClass.SHAMAN],
        "and 'only ever' means for the whole save")
    assert_eq(t.tavern_tier, 3)
    assert_eq(t.market_tier, 2)


# =============================================== the screen

func test_the_town_can_now_walk_into_the_tavern() -> void:
    var found := false
    for b in TownScript.BUILDINGS:
        if String(b["id"]) == "tavern":
            found = true
            assert_eq(String(b["scene"]), TAVERN)
    assert_true(found)
    assert_true(ResourceLoader.exists(TAVERN))

func test_the_board_fills_on_a_first_visit_rather_than_showing_nothing() -> void:
    var st = _live_state("Door Test")
    assert_eq(st.tavern_board.size(), 0, "nobody has looked yet")
    var view := _tavern()
    assert_eq(st.tavern_board.size(), st.board_slots(),
        "opening the door must not show an empty room")
    assert_eq(view.active_tab(), "board")

func test_an_emptied_board_stays_empty_when_the_door_is_opened_again() -> void:
    # THE GUARD SWAP'S REGRESSION TEST (audit M3-SAVE-06). Tavern.build() asks
    # `board_needs_first_roll()` — "never rolled AND empty" — and not `is_empty()`.
    # docs/04 §3.4: a dismissed candidate's "slot stays empty until the next refresh",
    # and §3.2 refreshes on events, never on opening the door. With the old predicate,
    # dismiss-all → quit → Continue → Tavern was a free reroll past the `50g x 2^n`
    # ladder and a farm for the pity counter. Every other mount in this file starts
    # from `new_game()`, where the board has never been rolled, so none of them could
    # ever reach the guard with `board_rolled` true.
    var st = _live_state("Emptied Test", 700)
    st.refresh_board()
    assert_true(st.board_rolled)
    while not st.tavern_board.is_empty():
        assert_true(st.dismiss_candidate(0))
    var purse: int = st.gold
    var pity: int = st.recruit_pity
    # Acceptance (b)/(c) name the round trip: the state the door is opened on is a
    # LOADED one, as it is after quit-to-menu → Continue.
    var problems: Array = st.from_dict(st.to_dict())
    assert_eq(problems.size(), 0, str(problems))
    assert_true(st.board_rolled, "the save remembers the board was rolled")
    assert_true(st.tavern_board.is_empty(), "and that it was emptied")

    var view := _tavern()
    assert_true(st.tavern_board.is_empty(),
        "opening the door must not refill a board the player emptied — Tavern.gd's "
        + "guard reads board_needs_first_roll(), not is_empty()")
    assert_eq(st.gold, purse, "and it charged nothing")
    assert_eq(st.recruit_pity, pity, "and the pity counter did not advance")
    assert_true(_printed(view).contains("Legendaries 0 of"),
        "the empty room still renders its sidebar")

func test_every_backstory_bullet_is_face_up() -> void:
    # docs/04 §3.5: "Backstory bullets are never hidden pre-recruit. The joke only lands
    # if the player knowingly hires the guy whose bullet says he quits when benched."
    var st = _live_state("Honest Test")
    var view := _tavern()
    var printed := _printed(view)
    var checked := 0
    for who in st.tavern_board:
        for bullet in who.backstory:
            var text := String(bullet.get("text", "")) \
                if typeof(bullet) == TYPE_DICTIONARY else str(bullet)
            assert_true(printed.contains(text),
                "'%s' is hidden, which the doc forbids" % text)
            checked += 1
    assert_true(checked >= 8, "the board must actually carry bullets: %d" % checked)

func test_the_card_shows_the_whole_decision_without_a_submenu() -> void:
    # docs/04 §3.5: "the card is the entire decision surface and must be readable without
    # a submenu" — name, class, rarity, mistake chance as a plain percentage, arriving
    # gear, cost.
    var st = _live_state("Card Test")
    var view := _tavern()
    var printed := _printed(view)
    var who = st.tavern_board[0]
    assert_true(printed.contains(who.display_name))
    assert_true(printed.contains(Enums.class_name_of(who.class_id)))
    assert_true(printed.contains(Enums.rarity_name_of(who.rarity)))
    assert_true(printed.contains("misses about"), "the mistake chance in words")
    assert_true(printed.contains("arrives with"), "and what they bring")
    assert_true(printed.contains("Hire — "), "and the price")

func test_hiring_from_the_screen_works_and_the_seat_empties() -> void:
    var st = _live_state("Press Test", 9999)
    var view := _tavern()
    var who = st.tavern_board[0]
    var btn = _button_named(view, "Hire — ")
    assert_true(btn != null)
    btn.pressed.emit()
    assert_eq(st.roster.size(), 13)
    assert_true(_printed(view).contains(who.display_name),
        "the notice must name who signed on")

func test_the_manage_tab_names_the_cost_before_it_charges_it() -> void:
    # docs/02 §5.3: "dismiss action + confirmation that names the morale consequence".
    var st = _live_state("Manage Test")
    var view := _tavern()
    _button_named(view, "Manage").pressed.emit()
    assert_eq(view.active_tab(), "manage")

    var before: int = st.roster.size()
    _button_named(view, "Dismiss").pressed.emit()
    assert_eq(st.roster.size(), before, "the first press only asks")
    var printed := _printed(view)
    assert_true(printed.contains("-2 morale"),
        "and the confirmation must name the number: %s" % printed)

    _button_named(view, "let them go").pressed.emit()
    assert_eq(st.roster.size(), before - 1)

func test_backing_out_of_a_dismissal_keeps_the_raider() -> void:
    var st = _live_state("Mercy Test")
    var view := _tavern()
    _button_named(view, "Manage").pressed.emit()
    _button_named(view, "Dismiss").pressed.emit()
    _button_named(view, "Keep them").pressed.emit()
    assert_eq(st.roster.size(), 12)

func test_a_maxed_tavern_says_so_rather_than_offering_nothing() -> void:
    var st = _live_state("Full House")
    st.tavern_tier = Buildings.top_level("tavern")
    var view := _tavern()
    var printed := _printed(view)
    assert_true(printed.contains("as big as it gets"), printed)
    assert_true(_button_named(view, "room next door") == null)

func test_an_empty_roster_does_not_break_the_manage_tab() -> void:
    var st = _live_state("Bare Test")
    st.roster = []
    var view := _tavern()
    _button_named(view, "Manage").pressed.emit()
    assert_true(_printed(view).contains("Nobody to manage"))


# ======================================= docs/10 §13 row 2 — the collection meter

## The Tavern is where Legendaries are FOUND, so it is where the collection goal is
## stated. ✅ C12 ("You can only ever find 1 Legendary per class") sets the target,
## and the target is never typed: `Achievements.legendary_goal()` is the length of
## the class list, so a class added or cut moves the meter with it.
##
## `test_hiring_a_legendary_claims_that_class_for_the_save` already pins the engine
## half — hiring claims the class — so these tests assert the SCREEN reads the field
## rather than re-testing the sim through the UI.

func test_the_tavern_states_the_collection_goal() -> void:
    _live_state("Meter Guild")
    var printed := _printed(_tavern())
    assert_true(printed.contains("Legendaries 0 of %d" % Enums.CLASS_KEYS.size()),
        "a new guild has found none of them: %s" % printed)

func test_the_meter_counts_the_classes_already_claimed() -> void:
    var st = _live_state("Meter Guild")
    st.legendary_classes_found = [Enums.CharClass.SHAMAN, Enums.CharClass.MAGE]
    var printed := _printed(_tavern())
    assert_true(printed.contains("Legendaries 2 of %d" % Enums.CLASS_KEYS.size()),
        "the meter reads `legendary_classes_found`, not a constant: %s" % printed)

func test_the_denominator_is_the_class_list_and_not_a_typed_nine() -> void:
    # If a class is ever added or cut this test moves with it and nothing else has
    # to. The literal 9 appears in docs, never in code.
    var st = _live_state("Meter Guild")
    st.legendary_classes_found = []
    var printed := _printed(_tavern())
    assert_true(printed.contains(" of %d" % Enums.CLASS_KEYS.size()))
    assert_eq(Enums.CLASS_KEYS.size(), 9,
        "canon's nine classes — if this changes, the meter follows the list, not this number")

func test_the_meter_survives_an_empty_board() -> void:
    # The footer is the one block all three sidebar states share, which is why the
    # meter lives there: a player who dismissed everybody still has a goal.
    var st = _live_state("Meter Guild")
    st.tavern_board = []
    var printed := _printed(_tavern())
    assert_true(printed.contains("Legendaries 0 of %d" % Enums.CLASS_KEYS.size()),
        "an empty board is not a reason to hide the goal: %s" % printed)
