extends "res://tests/TestCase.gd"
## The campaign ladder, which is now one implementation with two callers.
##
## `game/screens/AdventureBoard.gd` DRAWS it and `tools/playtest.gd` WALKS it, and
## until audit M6-PLAY-01 both rules lived inside the screen — so a harness could
## only have reimplemented them, and a harness that proves a different ladder
## completable proves nothing about the game. The extraction into `RaidPlan` is
## what makes the playtest worth running; these tests are what keep it honest.
##
## The rules themselves are canon's, not this file's:
##   * order — "Adventure 0 … Adventure 1 …" (raw notes, *Adventure's Board*), so
##     the tutorials come first, then the tier's Adventures, then its Raid;
##   * tiers come from the RANK (✅ CANON: "New Tiers can be unlocked by gaining
##     reputations with the town"), never from a hardcoded 1;
##   * a rung opens when every earlier one is RESOLVED, not cleared — canon lets
##     the player skip a tutorial, and a gate counting only clears would make
##     "skip" mean "soft-lock the campaign".

const RaidPlan = preload("res://game/core/RaidPlan.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Reputation = preload("res://sim/core/Reputation.gd")

var _db = null
var _made: Array = []


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []

func _state():
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Ladder", 77)
    return s

func _slots(state) -> Array:
    var out: Array = []
    for e in RaidPlan.ladder(state):
        out.append(String(e.slot))
    return out


# ---------------------------------------------------------------- the order

func test_the_ladder_is_canons_own_order() -> void:
    var s = _state()
    assert_eq(_slots(s), ["A0", "TR", "A1", "A2", "A3", "E1", "E2", "E3", "E4", "E5"],
        "tutorials, then the tier's Adventures, then its Raid")

func test_an_empty_campaign_has_no_ladder() -> void:
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    assert_eq(RaidPlan.ladder(s), [], "no content, no missions, and no crash")


# ---------------------------------------------------------------- the gate

func test_only_the_first_rung_is_open_to_a_new_guild() -> void:
    var s = _state()
    var open_now: Array = []
    for e in RaidPlan.ladder(s):
        if RaidPlan.locked_reason(s, e).is_empty():
            open_now.append(String(e.slot))
    assert_eq(open_now, ["A0"], "the campaign is strictly ordered")

func test_a_locked_rung_names_the_one_in_front_of_it() -> void:
    # docs/13 §7: a shut door says why, and says it in a sentence — and the
    # sentence names the rung as the board does, "Adventure 0", never by the
    # slot code "A0" a new player has never been told the meaning of (LOOP-03).
    var s = _state()
    var first = RaidPlan.ladder(s)[0]
    var second = RaidPlan.ladder(s)[1]
    assert_eq(String(first.slot), "A0")
    assert_eq(RaidPlan.locked_reason(s, second), "Clear Adventure 0 first.")
    assert_false(RaidPlan.locked_reason(s, second).contains("A0"),
        "the slot code stays off the sentence")

func test_clearing_a_rung_opens_exactly_the_next_one() -> void:
    var s = _state()
    var ladder: Array = RaidPlan.ladder(s)
    s.cleared[String(ladder[0].id)] = 1
    assert_eq(RaidPlan.locked_reason(s, ladder[1]), "")
    assert_eq(RaidPlan.locked_reason(s, ladder[2]),
        "Clear %s first." % String(ladder[1].display_name))

func test_the_next_open_mission_is_the_first_unresolved_rung() -> void:
    var s = _state()
    assert_eq(String(RaidPlan.next_open_mission(s).slot), "A0")
    s.cleared[String(RaidPlan.ladder(s)[0].id)] = 1
    assert_eq(String(RaidPlan.next_open_mission(s).slot), "TR")

func test_a_walked_out_ladder_offers_nothing() -> void:
    var s = _state()
    for e in RaidPlan.ladder(s):
        s.cleared[String(e.id)] = 1
    assert_eq(RaidPlan.next_open_mission(s), null,
        "a finished campaign has no next mission, and asking is not an error")


# ------------------------------------------------------- the skip, and why

func test_a_skipped_tutorial_leaves_the_board_and_unblocks_what_is_behind_it() -> void:
    # docs/15 Q-90: "Skip is permanent — the mission leaves the board." The rung
    # behind it must open, or "skip" would mean "soft-lock the campaign" — which
    # is the bug the RESOLVED-not-cleared rule exists to prevent.
    var s = _state()
    var first = RaidPlan.ladder(s)[0]
    assert_true(Reputation.is_tutorial_slot(String(first.slot)),
        "precondition: the first rung is a tutorial")
    assert_true(s.skip_tutorial(String(first.id)))
    assert_false(_slots(s).has(String(first.slot)), "the mission is gone from the board")
    assert_eq(String(RaidPlan.next_open_mission(s).slot), "TR",
        "and the rung behind it is open rather than waiting forever")


# ---------------------------------------------------------------- the party

func test_an_adventure_fields_six_and_a_raid_twelve() -> void:
    # Reading the rulebook instead of the encounter once let the game send twelve
    # on a six-person Adventure, which doubles the party DPS its HP was sized
    # against (docs/10 §3).
    var s = _state()
    for e in RaidPlan.ladder(s):
        var party: Array = RaidPlan.suggest_party(s, e, _db)
        assert_eq(party.size(), mini(int(e.party_size), s.roster.size()),
            "%s fields %d" % [String(e.slot), int(e.party_size)])

func test_the_ordinary_suggestion_is_the_happiest_available() -> void:
    var s = _state()
    var raid = null
    for e in RaidPlan.ladder(s):
        if String(e.slot) == "E1":
            raid = e
    var party: Array = RaidPlan.suggest_party(s, raid, _db)
    for i in range(1, party.size()):
        assert_true(party[i - 1].morale >= party[i].morale,
            "highest morale first — the default worth arguing with")

func test_a_tutorial_squad_is_built_around_its_own_teaching_payload() -> void:
    # docs/10 §9.1 calls both tutorial parties pre-made, and it matters: the
    # Tutorial Raid's whole payload is M01 Tank Swap, which a squad with no tank
    # cannot be taught by. Seeding by morale alone could hand it six DPS.
    var s = _state()
    var tr = null
    for e in RaidPlan.ladder(s):
        if String(e.slot) == "TR":
            tr = e
    var party: Array = RaidPlan.suggest_party(s, tr, _db)
    var tanks := 0
    for r in party:
        var cd = _db.class_of(r.class_id)
        if cd != null and int(cd.role_group) == Enums.RoleGroup.TANK:
            tanks += 1
    assert_true(tanks >= RaidPlan.tanks_required(tr),
        "the squad must be able to perform the thing the tutorial teaches: %d tank(s)"
            % tanks)

func test_asking_for_a_party_without_a_guild_is_not_an_error() -> void:
    assert_eq(RaidPlan.suggest_party(null, null), [])
