extends "res://tests/TestCase.gd"
## The playtest's solvency invariant (audit M6-PLAY-02), on hand-built guilds.
##
## `tools/playtest.gd` is a SceneTree script, so nothing in tests/unit/ had ever
## loaded it — the harness that plays the whole campaign was the one piece of the
## build with no test of its own. `_can_still_make_progress()` is static and pure
## over a GameState precisely so it can be asked here without running a campaign:
## the question is "does THIS guild have a door left", and a guild is a fixture.

const Playtest = preload("res://tools/playtest.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Recruitment = preload("res://sim/core/Recruitment.gd")
const Economy = preload("res://sim/core/Economy.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")
const DB = preload("res://sim/content/ContentDB.gd")

var _db = null
var _s = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _s = GameStateScript.new()
    _s.reset()
    _s.set_content(_db)
    _s.new_game("Solvency", 4242)

func after_each() -> void:
    if _s != null:
        _s.free()
        _s = null


func _raider(id: String, cls: int = Enums.CharClass.WARRIOR):
    var r = Raider.new()
    r.id = id
    r.display_name = id.capitalize()
    r.class_id = cls
    r.rarity = Enums.Rarity.COMMON
    r.morale = 50
    return r


## A guild that has spent everything and lost everybody but two: nothing to field,
## nothing to hire with, nothing to sell.
func _broke_pair() -> void:
    _s.roster = []
    _s.add_raider(_raider("a"))
    _s.add_raider(_raider("b"))
    _s.gold = 0
    _s.pending_loot = []
    _s.tavern_board = []


# ---------------------------------------------------------------- the dead end

func test_two_raiders_no_gold_and_nothing_to_sell_is_named_as_stuck() -> void:
    # The fixture the audit entry names: roster=2 / gold=0 / empty inventory.
    _broke_pair()
    var why: String = Playtest._can_still_make_progress(_s, _db)
    assert_false(why.is_empty(), "a guild with no door left must be named")
    assert_true(why.contains("2 of"), "it says how short the roster is: %s" % why)
    assert_true(why.contains("0 G"), "and that the purse is empty: %s" % why)
    assert_true(why.contains("nobody on the board"), why)

func test_an_empty_roster_is_stuck_at_once() -> void:
    _s.roster = []
    _s.gold = 5000
    var why: String = Playtest._can_still_make_progress(_s, _db)
    assert_true(why.contains("roster is empty"), why)


# ---------------------------------------------------------------- the three doors

func test_a_roster_that_can_field_the_next_rung_is_solvent_with_nothing_else() -> void:
    # Door (a). The starting twelve, broke and bare, can still walk onto the board.
    _s.gold = 0
    _s.pending_loot = []
    _s.tavern_board = []
    var enc = RaidPlan.next_open_mission(_s)
    assert_ne(enc, null, "a new guild has an open rung")
    assert_true(_s.roster.size() >= int(enc.party_size))
    assert_eq(Playtest._can_still_make_progress(_s, _db), "")

func test_a_hire_the_purse_covers_is_a_door() -> void:
    # Door (b). Two raiders, but a Common on the board and the gold to sign them.
    _broke_pair()
    _s.refresh_board()
    assert_true(_s.tavern_board.size() > 0, "the board must have seats to test this")
    var cheapest := 1 << 30
    for who in _s.tavern_board:
        cheapest = mini(cheapest, Recruitment.cost_of(who.rarity, _s.highest_unlocked_tier()))
    _s.gold = cheapest - 1
    assert_false(Playtest._can_still_make_progress(_s, _db).is_empty(),
        "one coin short of the cheapest seat is still stuck")
    _s.gold = cheapest
    assert_eq(Playtest._can_still_make_progress(_s, _db), "",
        "the cheapest seat's own price opens the door")

func test_a_board_full_of_people_the_purse_cannot_cover_is_not_a_door() -> void:
    # The floor `Recruitment.cost_of(Common, 1)` is what a Common costs (docs/15
    # BL-94: doc 11's 15 G, so "one coin short" is 14 G here); the check reads the
    # seats actually on the board, because that is what `hire()` charges.
    _broke_pair()
    _s.refresh_board()
    assert_true(_s.tavern_board.size() > 0)
    _s.gold = Recruitment.cost_of(Enums.Rarity.COMMON, 1) - 1
    assert_false(Playtest._can_still_make_progress(_s, _db).is_empty())

func test_the_opening_purse_covers_a_common_hire() -> void:
    # Door (b)'s premise, wired rather than assumed: docs/01 §8.0 sized the 60 G
    # opening purse against a 15 G Common (docs/15 BL-94), so a new guild can
    # always sign at least one recruit before its first attempt. Read off the
    # two owning constants so the assertion moves if either legitimately does.
    assert_true(GameStateScript.STARTING_GOLD >= Recruitment.cost_of(Enums.Rarity.COMMON, 1),
        "the opening purse (%d G) no longer covers a Common (%d G) — doors (b) and (c) both assume it does"
            % [GameStateScript.STARTING_GOLD, Recruitment.cost_of(Enums.Rarity.COMMON, 1)])

func test_unsold_inventory_worth_a_fresh_purse_is_a_door() -> void:
    # Door (c). Nothing to field and nothing to hire with, but a shelf of loot the
    # Market would pay `STARTING_GOLD` for — docs/01 §8.0's opening purse, the
    # amount the guild was solvent on at day one.
    _broke_pair()
    var floor_gold: int = GameStateScript.STARTING_GOLD
    var worth := 0
    for item_id in _db.items:
        if worth >= floor_gold:
            break
        var it = _db.items[item_id]
        var price: int = Economy.sell_price(it, _s.reputation_rank)
        if price <= 0:
            continue
        _s.pending_loot.append(it)
        worth += price
    assert_true(worth >= floor_gold, "the content must hold %d G of sellable items" % floor_gold)
    assert_eq(Playtest._can_still_make_progress(_s, _db), "")
    # One item under the line and the door closes again.
    _s.pending_loot.pop_back()
    var why: String = Playtest._can_still_make_progress(_s, _db)
    assert_false(why.is_empty(), "less than a fresh purse of loot is not a way out")
    assert_true(why.contains("unsold inventory"), why)

func test_equipped_gear_counts_as_inventory_the_guild_could_sell() -> void:
    # `sell_equipped()` exists, so what the two survivors are WEARING is on the
    # shelf too. Dress them in the starting set and the door opens.
    _broke_pair()
    var worth := 0
    for r in _s.roster:
        for it in _db.starting_set(r.class_key()):
            if r.equip(_db, it).is_empty():
                worth += Economy.sell_price(it, _s.reputation_rank)
    assert_true(worth > 0, "the starting set must be worth something at the counter")
    assert_eq(Playtest._unsold_inventory_value(_s, _db), worth,
        "the equipped pieces are priced at the rank's sell rate, loose drops aside")
    _s.pending_loot.append(_db.starting_set("warrior")[0])
    assert_true(Playtest._unsold_inventory_value(_s, _db) > worth,
        "and a loose drop adds to the same total")


# ---------------------------------------------------------------- the wiring

func test_the_harness_asks_after_every_hire_attempt_and_rest() -> void:
    # The invariant is only as good as its call sites. Three calls in `_play()`,
    # one per verb the audit names, plus the two-bad-rests rule and the tally that
    # fails the gate.
    var src := FileAccess.get_file_as_string("res://tools/playtest.gd")
    var play_at := src.find("func _play(")
    var report_at := src.find("func _report(")
    assert_true(play_at >= 0 and report_at > play_at)
    var body := src.substr(play_at, src.find("func _stuck_on(") - play_at)
    assert_eq(body.count("_can_still_make_progress(s, db)"), 3,
        "after the hire, after the attempt, after the rest")
    assert_true(body.contains("BAD_RESTS_IS_STUCK"), "two bad rests in a row is stuck")
    assert_true(src.contains("STUCK  %d guild(s)"), "and the report tallies them")
    assert_true(src.contains("done >= need and stuck == 0"),
        "a stuck run fails the gate whatever the completion count")
