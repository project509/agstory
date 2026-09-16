extends "res://tests/TestCase.gd"
## The ending (docs/10 §13 row 1, ruled in docs/15 Q-88).
##
## The game HAS one, and it is the first clear of the last encounter of the last
## tier — not a victory screen that takes the save away. "The save continues",
## so the beat is three fields rather than a mode: `completed` (ever),
## `completed_on_day` (for the report), `completion_seen` (so a reload does not
## replay somebody's ending at them).
##
## Tier 5 is not in the default content set — its words are pending and BL-69
## keeps an unnamed tier out of the shipped ladder — so these tests mount it by
## name. That is the honest shape of the claim: when the last tier is there, the
## beat fires; today a player cannot reach it, which is why `completed` is false
## in every shipped save.

const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const Achievements = preload("res://sim/core/Achievements.gd")

var _db = null
var _made: Array = []


func before_each() -> void:
    if _db == null:
        var paths: Dictionary = DB.DEFAULT_PATHS.duplicate(true)
        var found: Array = []
        for tier in range(1, 6):
            found.append(DB.tier_paths(tier))
        paths["tiers"] = found
        _db = DB.load_all(paths)


func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []


func _state():
    var s = GameStateScript.new()
    _made.append(s)
    s.set_content(_db)
    s.new_game("The Last Word", 4242)
    return s


func test_the_last_encounter_of_the_last_tier_is_the_one_that_ends_it() -> void:
    # Resolved through the record rather than by matching an id, so renaming
    # content cannot silently move the ending.
    var last = _db.encounter("t5_raid_e5")
    assert_true(last != null, "the last tier must have a last encounter")
    assert_true(Achievements.is_completion_encounter(last),
        "tier 5 E5 is the completion encounter")
    for other_id in ["t1_raid_e5", "t5_raid_e4", "t4_raid_e5"]:
        var other = _db.encounter(other_id)
        if other == null:
            continue
        assert_false(Achievements.is_completion_encounter(other),
            "%s is not the ending" % other_id)


func test_a_fresh_guild_has_not_finished() -> void:
    var s = _state()
    assert_false(s.completed, "a new guild has not completed the campaign")
    assert_eq(s.completed_on_day, 0)
    assert_false(s.completion_seen, "and has nothing to be shown")


func test_the_first_clear_of_the_last_fight_sets_the_beat() -> void:
    var s = _state()
    s.day = 91
    var enc = _db.encounter("t5_raid_e5")
    var party: Array = s.roster.slice(0, mini(int(enc.party_size), s.roster.size()))
    var result = RaidSim.run(party, enc, _db, 11, s.build_loadout(party))
    # Force the clear: this test is about the bookkeeping, and a starting roster
    # cannot beat a Tier 5 boss — which is the point of the tier existing.
    s.cleared["t5_raid_e5"] = 0
    s.record_attempt("t5_raid_e5", _won(result), party)
    assert_true(s.completed, "clearing the last fight finishes the campaign")
    assert_eq(s.completed_on_day, 91, "and records the day it happened")
    assert_false(s.completion_seen, "the beat has not been shown yet")


func test_clearing_it_again_does_not_move_the_day_or_replay_the_beat() -> void:
    # A farm run is not a second ending. `completion_seen` is what the screen
    # flips, and re-clearing must not un-flip it.
    var s = _state()
    s.day = 91
    var enc = _db.encounter("t5_raid_e5")
    var party: Array = s.roster.slice(0, mini(int(enc.party_size), s.roster.size()))
    s.record_attempt("t5_raid_e5", _won(RaidSim.run(party, enc, _db, 11, s.build_loadout(party))), party)
    s.completion_seen = true
    s.day = 120
    s.record_attempt("t5_raid_e5", _won(RaidSim.run(party, enc, _db, 12, s.build_loadout(party))), party)
    assert_eq(s.completed_on_day, 91, "the ending happened once, on its own day")
    assert_true(s.completion_seen, "and is not replayed at somebody who has seen it")


func test_clearing_an_earlier_tier_does_not_end_the_game() -> void:
    var s = _state()
    var enc = _db.encounter("t1_raid_e5")
    var party: Array = s.roster.slice(0, mini(int(enc.party_size), s.roster.size()))
    s.record_attempt("t1_raid_e5", _won(RaidSim.run(party, enc, _db, 5, s.build_loadout(party))), party)
    assert_false(s.completed, "Tier 1's boss is not the end of the game")


func test_the_beat_survives_a_save() -> void:
    # An ending you have to earn twice is not an ending.
    var s = _state()
    s.day = 91
    var enc = _db.encounter("t5_raid_e5")
    var party: Array = s.roster.slice(0, mini(int(enc.party_size), s.roster.size()))
    s.record_attempt("t5_raid_e5", _won(RaidSim.run(party, enc, _db, 11, s.build_loadout(party))), party)
    s.completion_seen = true
    var body: Dictionary = s.to_dict()
    var back = GameStateScript.new()
    _made.append(back)
    back.set_content(_db)
    back.from_dict(body)
    assert_true(back.completed, "the campaign stays finished")
    assert_eq(back.completed_on_day, 91, "on the day it finished")
    assert_true(back.completion_seen, "and the beat stays seen")


func test_the_snapshot_the_board_reads_agrees() -> void:
    # `Achievements.snapshot()` already looked for `completed` before the field
    # existed, and defaulted it to false — so a campaign-complete achievement
    # could never fire. This is the wire that was missing.
    var s = _state()
    var enc = _db.encounter("t5_raid_e5")
    var party: Array = s.roster.slice(0, mini(int(enc.party_size), s.roster.size()))
    s.record_attempt("t5_raid_e5", _won(RaidSim.run(party, enc, _db, 11, s.build_loadout(party))), party)
    assert_true(bool(Achievements.snapshot(s).get("completed", false)),
        "the board must be able to see that the campaign is finished")


## The sim decides the outcome; this forces the cleared one, because a starting
## roster cannot beat a Tier 5 boss and these tests are about what happens AFTER
## a clear rather than about whether one is plausible.
func _won(result):
    result.outcome = RaidSim.Outcome.VICTORY
    return result
