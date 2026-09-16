extends "res://tests/TestCase.gd"
## The wire between the achievement engine and the campaign (audit M5-QAB-6).
##
## `tests/unit/test_achievements.gd` proves the ENGINE: that the records are
## well-formed, that conditions evaluate, that the coin cap refuses rather than
## paying smaller. All of that was true and all of it was load-bearing for
## nothing, because `Achievements.evaluate()` had no caller anywhere in `game/`
## and GameState had no field to write an earned record into. Forty records read
## Locked forever, "Records 0 of 40" was what a guild that cleared the game saw,
## and no reward had ever been paid.
##
## So this file tests the WIRE, and the three things about it that are easy to get
## wrong and impossible to notice:
##
##   * an EVENT-only record is earned at the moment or never — "cleared it with
##     nobody dead" is not a fact a save can rediscover, which is why the earned
##     set is persisted rather than recomputed;
##   * a re-check can never take a record away;
##   * board coin is NOT income, or the board raises its own cap every time it
##     pays out and docs/11 §11.2's "never enough to substitute for playing
##     content" becomes a faucet that widens itself.

const GameStateScript = preload("res://game/core/GameState.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const Achievements = preload("res://sim/core/Achievements.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")

const A0 := "t1_tut_a0"

var _db = null
var _made: Array = []


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    Achievements.reset_records()

func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []
    # `record_attempt` and `claim_achievement` both autosave (docs/14 §7.4), so
    # every test here is a save-writer.
    SaveGame.purge_all()

func _state():
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("The Board", 4242)
    return s

## One attempt at `encounter_id`, forced to the outcome the test is about. The sim
## decides what really happens; these tests are about the bookkeeping AFTER a
## result, not about whether a starting roster can win.
func _attempt(s, encounter_id: String, won: bool, flawless := false):
    var enc = _db.encounter(encounter_id)
    var party: Array = s.roster.slice(0, mini(int(enc.party_size), s.roster.size()))
    var result = RaidSim.run(party, enc, _db, 11, s.build_loadout(party))
    result.outcome = RaidSim.Outcome.VICTORY if won else RaidSim.Outcome.WIPE
    if flawless:
        result.mistake_count = 0
    s.record_attempt(encounter_id, result, party)
    return result


# ---------------------------------------------------------------- earning

func test_a_fresh_guild_has_earned_nothing() -> void:
    var s = _state()
    assert_eq(s.achievements_earned, {})
    assert_eq(s.achievements_claimed, [])
    assert_eq(Achievements.earned_count(Achievements.snapshot(s)), 0)

func test_clearing_a_rung_earns_the_record_that_names_it() -> void:
    # docs/11 §11.1's first worked example, "Clear Adventure 0". Keyed by SLOT,
    # not by encounter id (docs/10 §2 note 2), which is why renaming content
    # cannot silently un-earn it.
    var s = _state()
    _attempt(s, A0, true)
    assert_true(s.achievements_earned.has("prog_adventure_0"),
        "clearing A0 must earn its record: %s" % str(s.achievements_earned.keys()))

func test_the_day_it_happened_is_what_is_written_down() -> void:
    # The one part of an earned record a snapshot cannot recompute, and the part
    # docs/02 §4.4's "wall you can read" needs.
    var s = _state()
    s.day = 42
    _attempt(s, A0, true)
    assert_eq(int(s.achievements_earned["prog_adventure_0"]), 42)

func test_a_record_is_earned_once_and_keeps_its_day() -> void:
    var s = _state()
    s.day = 7
    _attempt(s, A0, true)
    s.day = 99
    _attempt(s, A0, true)
    assert_eq(int(s.achievements_earned["prog_adventure_0"]), 7,
        "a farm run is not a second earning")

func test_a_failed_attempt_earns_the_clear_record_nothing() -> void:
    var s = _state()
    _attempt(s, A0, false)
    assert_false(s.achievements_earned.has("prog_adventure_0"))


# --------------------------------------------------- the event-only half

func test_an_event_only_record_is_earned_at_the_moment_it_happens() -> void:
    # `flawless_clear` reads the attempt and nothing else. This is the only moment
    # it can be true, which is the entire reason the earned set is persisted.
    var s = _state()
    _attempt(s, A0, true, true)
    assert_true(s.achievements_earned.has("mast_clean_sheet"),
        "a clear with no mistakes must be noticed while it is in hand: %s"
            % str(s.achievements_earned.keys()))

func test_a_bare_recheck_cannot_earn_an_event_only_record() -> void:
    # It answers "not now", never "yes" — otherwise every save point would hand
    # out every event record to a guild that never did the thing.
    var s = _state()
    s.check_achievements()
    assert_false(s.achievements_earned.has("mast_clean_sheet"))
    assert_false(s.achievements_earned.has("mast_no_one_died"))

func test_a_recheck_never_takes_an_earned_record_away() -> void:
    # The other half of the same rule: "not now" must not read as "no longer".
    var s = _state()
    _attempt(s, A0, true, true)
    var had: Array = s.achievements_earned.keys()
    assert_true(had.size() > 0, "this test needs something earned first")
    s.check_achievements()
    s.check_achievements()
    for rid in had:
        assert_true(s.achievements_earned.has(rid),
            "%s was earned and a re-check dropped it" % rid)

func test_the_board_is_told_what_was_just_earned() -> void:
    var s = _state()
    var heard: Array = []
    s.achievements_changed.connect(func(ids: Array) -> void: heard.append_array(ids))
    _attempt(s, A0, true)
    assert_true(heard.has("prog_adventure_0"),
        "the signal must carry the ids, not just fire: %s" % str(heard))


# ---------------------------------------------------------------- the save

func test_earning_survives_a_save() -> void:
    var s = _state()
    s.day = 12
    _attempt(s, A0, true)
    var body: Dictionary = s.to_dict()
    var back = GameStateScript.new()
    _made.append(back)
    back.set_content(_db)
    back.from_dict(body)
    assert_eq(int(back.achievements_earned.get("prog_adventure_0", -1)), 12,
        "a wall the player has to re-earn is not a wall")

func test_a_save_from_before_the_board_was_wired_arrives_empty() -> void:
    # v16's migration is a stamp and back-awards nothing. The snapshot-based
    # records notice again on that guild's next save point; the event-only ones
    # genuinely cannot be recovered, and awarding half of them silently would be
    # the worst of both.
    var s = _state()
    _attempt(s, A0, true)
    var body: Dictionary = s.to_dict()
    body.erase("achievements_earned")
    body.erase("achievements_claimed")
    var back = GameStateScript.new()
    _made.append(back)
    back.set_content(_db)
    back.from_dict(body)
    assert_eq(back.achievements_earned, {})
    assert_eq(back.achievements_claimed, [])


# ---------------------------------------------------------------- claiming

func test_an_unearned_record_cannot_be_claimed() -> void:
    var s = _state()
    var refusal := String(s.claim_achievement("prog_raid_1"))
    assert_true(refusal.contains("Not earned"), refusal)
    assert_eq(s.achievements_claimed, [])

func test_claiming_pays_the_reward_and_marks_it_taken() -> void:
    # prog_adventure_0 pays docs/11 §11.2's documented bundle: 5 Minor Healing
    # Potions. The cupboard is where they land.
    var s = _state()
    _attempt(s, A0, true)
    assert_true(s.achievements_earned.has("prog_adventure_0"))
    var before: int = s.consumable_count("minor_healing_potion", 1)
    assert_eq(s.claim_achievement("prog_adventure_0"), "", "the claim must succeed")
    assert_true(s.achievements_claimed.has("prog_adventure_0"))
    assert_eq(s.consumable_count("minor_healing_potion", 1), before + 5,
        "five potions, which is the figure the record carries")

func test_the_same_reward_cannot_be_taken_twice() -> void:
    var s = _state()
    _attempt(s, A0, true)
    assert_eq(s.claim_achievement("prog_adventure_0"), "")
    var refusal := String(s.claim_achievement("prog_adventure_0"))
    assert_true(refusal.contains("Already claimed"), refusal)

func test_a_claimed_record_reads_as_claimed_on_the_wall() -> void:
    var s = _state()
    _attempt(s, A0, true)
    s.claim_achievement("prog_adventure_0")
    var snap: Dictionary = Achievements.snapshot(s)
    assert_eq(Achievements.state_of("prog_adventure_0", snap), Achievements.State.CLAIMED)


# ------------------------------------------------ docs/11 §11.2's coin cap

func test_the_coin_cap_refuses_rather_than_paying_less() -> void:
    # A guild that has earned nothing has a cap of nothing, so the very first coin
    # record is refused — and the refusal names the figure and the income it is a
    # share of, because docs/13 §7 forbids a "no" the player cannot read.
    var s = _state()
    s.gold_earned_lifetime = 0
    s.achievements_earned["prog_raid_1"] = s.day
    var refusal := String(s.claim_achievement("prog_raid_1"))
    assert_true(refusal.contains("paid its share"), refusal)
    assert_eq(s.achievements_claimed, [], "and nothing was taken")

func test_board_coin_is_gold_but_not_income() -> void:
    # THE design assertion. The cap is 15% of lifetime income; if board coin fed
    # that figure the board would raise its own ceiling every time it paid, which
    # is exactly the substitution docs/11 §11.2 forbids.
    var s = _state()
    s.gold_earned_lifetime = 100000
    s.achievements_earned["prog_raid_1"] = s.day
    var purse: int = s.gold
    var income: int = s.gold_earned_lifetime
    assert_eq(s.claim_achievement("prog_raid_1"), "", "the cap is wide enough here")
    assert_true(s.gold > purse, "the coin is real")
    assert_eq(s.gold_earned_lifetime, income,
        "and it did not widen the cap it was paid under")


# ------------------------------------------------------- the other rewards

func test_a_furnishing_reward_joins_the_guild_holdings() -> void:
    var s = _state()
    s.achievements_earned["com_persistence"] = s.day
    assert_eq(s.claim_achievement("com_persistence"), "")
    assert_true(s.guild_furnishings.has("straw_cot"),
        "docs/11 §11.2's in-kind reward has to arrive somewhere: %s"
            % str(s.guild_furnishings))

func test_a_town_flag_is_remembered_without_touching_the_build_flags() -> void:
    # `flags` is docs/14 §5.2's BUILD-flag registry and refuses an id it does not
    # declare. A statue in the square is not a feature switch, and conflating the
    # two would let a reward turn the Blacksmith on.
    var s = _state()
    s.achievements_earned["rost_nine_of_nine"] = s.day
    assert_eq(s.claim_achievement("rost_nine_of_nine"), "")
    assert_true(s.town_flags.has("banner"))
    assert_false(s.flags.has("banner"), "a town decoration is not a build flag")

func test_every_reward_kind_a_record_carries_can_actually_be_paid() -> void:
    # The guard that stops a sixth reward kind being authored into the data with
    # no hand to apply it — which is the shape of the bug this whole item fixes,
    # one level down.
    var payable := ["coin", "furnishing", "reputation", "town_flag", "consumables"]
    for raw in Achievements.records():
        var rec: Dictionary = raw
        var kind := String((rec.get("reward", {}) as Dictionary).get("kind", ""))
        assert_true(kind in payable,
            "%s pays '%s', which GameState.claim_achievement() cannot apply"
                % [String(rec.get("id", "")), kind])
