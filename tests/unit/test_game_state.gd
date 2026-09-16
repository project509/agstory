extends "res://tests/TestCase.gd"
## GameState: the campaign the player accumulates between raids.
##
## The canon-fidelity assertions here are the ones that matter — a silent drift
## in starting gold or the roster cap changes the shape of the whole early game
## and nothing else in the build would notice.

const GameStateScript = preload("res://game/core/GameState.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Enums = preload("res://sim/model/Enums.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Achievements = preload("res://sim/core/Achievements.gd")
const LegendaryPool = preload("res://sim/content/LegendaryPool.gd")
const Morale = preload("res://sim/core/Morale.gd")

var _s = null
var _db = null

func before_each() -> void:
    _s = GameStateScript.new()
    _s.reset()

func after_each() -> void:
    if _s != null:
        _s.free()
        _s = null
    # `record_attempt`, `hire` and `assign_loot` all autosave (docs/14 §7.4), so the
    # counter tests below are save-writers. Leaving a slot behind would hand the next
    # file a guild it never created.
    SaveGame.purge_all()

func _content():
    if _db == null:
        _db = DB.load_all()
    return _db

func _raider(id: String, cls: int = Enums.CharClass.WARRIOR):
    var r = Raider.new()
    r.id = id
    r.display_name = id.capitalize()
    r.class_id = cls
    r.rarity = Enums.Rarity.COMMON
    r.morale = 50
    return r

## What the sim hands back for a wiped attempt, including docs/14 OQ-10's report — the
## shape `RaidSim._queue_deltas()` builds and that `game/` is supposed to apply.
class _Result extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    var deltas_queued: Array = []
    var won: bool = false
    func cleared() -> bool: return won

func _result(party: Array, won: bool = false):
    var res := _Result.new()
    res.won = won
    for r in party:
        res.deltas_queued.append({
            "raider_id": r.id, "runs_attended": 1,
            "wipes_witnessed": 0 if won else 1, "died": false,
        })
    return res

## The largest mover of a raider's last recorded Day Tick. `_record_morale_day()` keeps
## exactly one note per tick, so this is how a test reads what actually fired.
func _last_note(r) -> String:
    if r.morale_log.is_empty():
        return ""
    return String((r.morale_log[-1] as Dictionary).get("note", ""))

# ---------------------------------------------------------------- canon fidelity

func test_starting_gold_is_the_documented_opening_balance() -> void:
    # docs/01 §8.0 Q-13: 60 G — one Common hire (15 G) plus a farm run's potions
    # (~15 G) with change. Changing this silently re-tunes the first town cycle
    # from a real decision into a formality.
    assert_eq(GameStateScript.STARTING_GOLD, 60,
        "docs/01 §8.0 Q-13 fixes the opening balance at 60 G")

func test_a_new_guild_starts_at_rank_unknown() -> void:
    # Canon, verbatim: "You start at: Unknown" (raw notes, Guild Reputation).
    assert_eq(GameStateScript.STARTING_RANK, Enums.ReputationRank.UNKNOWN)
    _s.new_game("Test Guild")
    assert_eq(_s.reputation_rank, Enums.ReputationRank.UNKNOWN)
    assert_eq(_s.rank_name(), "Unknown")

func test_roster_cap_matches_the_reputation_ladder() -> void:
    # docs/04 §12.1 is the SINGLE source of the roster cap and the driver is
    # reputation rank, not Guildhall level. One entry per canon rank, no gaps.
    assert_eq(GameStateScript.ROSTER_CAP_BY_RANK, [15, 16, 17, 18, 19, 20])
    assert_eq(GameStateScript.ROSTER_CAP_BY_RANK.size(), Enums.REPUTATION_KEYS.size(),
        "one roster cap per canon reputation rank")
    for rank in Enums.all_reputation_ranks():
        _s.reputation_rank = rank
        assert_eq(_s.roster_cap(), GameStateScript.ROSTER_CAP_BY_RANK[rank])

func test_every_cap_exceeds_the_raid_size_so_the_bench_exists() -> void:
    # docs/04 §12.1: a cap of exactly 12 deletes benching, and "the bench is
    # where the game is". This is the assertion that protects that argument.
    for cap in GameStateScript.ROSTER_CAP_BY_RANK:
        assert_true(cap > Enums.RAID_SIZE,
            "cap %d must exceed the raid size %d" % [cap, Enums.RAID_SIZE])

func test_forced_bench_matches_the_documented_column() -> void:
    # docs/04 §12.1's forced-bench column, derived rather than duplicated.
    var expected := [3, 4, 5, 6, 7, 8]
    for rank in Enums.all_reputation_ranks():
        _s.reputation_rank = rank
        assert_eq(_s.forced_bench(), expected[rank],
            "rank %s forced bench" % Enums.reputation_key(rank))

# ---------------------------------------------------------------- lifecycle

func test_new_game_seeds_a_playable_guild() -> void:
    _s.new_game("Brave Attempt")
    assert_eq(_s.guild_name, "Brave Attempt")
    assert_eq(_s.gold, 60)
    assert_eq(_s.day, 1)
    assert_true(_s.active)
    assert_eq(_s.roster.size(), 0, "a guild starts with no raiders — the Tavern hires")

func test_an_empty_guild_name_falls_back_rather_than_shipping_blank() -> void:
    _s.new_game("   ")
    assert_eq(_s.guild_name, "A Guild Story")

func test_a_fresh_state_is_not_active() -> void:
    assert_false(_s.active, "Continue must not offer a guild that does not exist")

# ---------------------------------------------------------------- gold

func test_spending_more_than_you_have_changes_nothing() -> void:
    _s.new_game("G")
    assert_false(_s.spend_gold(61))
    assert_eq(_s.gold, 60, "a refused purchase must not partially deduct")
    assert_true(_s.spend_gold(60))
    assert_eq(_s.gold, 0)

func test_gold_never_goes_negative() -> void:
    _s.new_game("G")
    _s.add_gold(-500)
    assert_eq(_s.gold, 0)

func test_spending_a_negative_amount_is_refused() -> void:
    # Otherwise "spend -100" is a free 100 gold.
    _s.new_game("G")
    assert_false(_s.spend_gold(-100))
    assert_eq(_s.gold, 60)

# ---------------------------------------------------------------- roster

func test_the_roster_stops_at_the_cap() -> void:
    _s.new_game("G")
    var cap: int = _s.roster_cap()
    for i in cap:
        assert_true(_s.add_raider(_raider("r%d" % i)), "raider %d should fit" % i)
    assert_true(_s.roster_is_full())
    assert_false(_s.add_raider(_raider("overflow")),
        "the cap is the cap — docs/04 §12.1")
    assert_eq(_s.roster.size(), cap)

func test_removing_and_finding_raiders_by_id() -> void:
    _s.new_game("G")
    _s.add_raider(_raider("steve"))
    _s.add_raider(_raider("bob"))
    assert_ne(_s.raider("steve"), null)
    assert_true(_s.remove_raider("steve"))
    assert_eq(_s.raider("steve"), null)
    assert_false(_s.remove_raider("steve"), "removing twice must report failure")
    assert_eq(_s.roster.size(), 1)

func test_can_field_a_raid_needs_the_full_twelve() -> void:
    _s.new_game("G")
    for i in Enums.RAID_SIZE - 1:
        _s.add_raider(_raider("r%d" % i))
    assert_false(_s.can_field_a_raid())
    _s.add_raider(_raider("last"))
    assert_true(_s.can_field_a_raid())

# -------------------------------------------- docs/04 §12.2: the per-raider counters
#
# Every assertion in this block was unreachable before the counters were written. The
# four fields are declared on Raider, saved, loaded — and incremented by nothing, while
# game/screens/RaiderDetail.gd printed three of them to the player.

func test_a_resolved_run_counts_the_bench_and_an_attended_run_clears_it() -> void:
    # docs/04 §12.2: "`consecutive_benched` +1 on run resolve; reset to 0 on any run
    # attended." The reset half matters as much as the increment: a streak that only ever
    # grows would suspend a Legendary's floor permanently after five quiet runs.
    _s.new_game("Bench")
    for i in 3:
        _s.add_raider(_raider("r%d" % i))
    var party: Array = [_s.roster[0]]

    _s.record_attempt("t1_adv_a1", _result(party), party)
    assert_eq(_s.roster[0].consecutive_benched, 0, "they went")
    assert_eq(_s.roster[1].consecutive_benched, 1)

    _s.record_attempt("t1_adv_a1", _result(party), party)
    assert_eq(_s.roster[1].consecutive_benched, 2, "a second run off the party")

    var everyone: Array = _s.roster.duplicate()
    _s.record_attempt("t1_adv_a1", _result(everyone), everyone)
    assert_eq(_s.roster[1].consecutive_benched, 0,
        "one attended run resets the streak — docs/04 §12.2")

func test_the_fifth_consecutive_bench_suspends_a_legendarys_floor() -> void:
    # docs/04 §11.3 condition 1: "Benched for 5 consecutive runs — reads as 'You stopped
    # using them'." It could never fire. `_refresh_big_dumb()` read a counter nobody
    # wrote, so the 40-morale floor was UNCONDITIONAL and canon's "you can only lose a
    # Legendary if you are BIG dumb" had no way to be true.
    _s.new_game("Legend")
    var hero = _raider("hero", Enums.CharClass.SHAMAN)
    hero.rarity = Enums.Rarity.LEGENDARY
    hero.legendary_def_id = "LEG_TEST"
    _s.add_raider(hero)
    for i in Enums.RAID_SIZE:
        _s.add_raider(_raider("r%d" % i))
    var party: Array = _s.roster.slice(1)

    for run in GameStateScript.BENCHED_RUNS_IS_BIG_DUMB - 1:
        _s.record_attempt("t1_adv_a1", _result(party), party)
        assert_false(hero.big_dumb_active,
            "%d benches is not yet BIG dumb" % (run + 1))
    _s.record_attempt("t1_adv_a1", _result(party), party)
    assert_eq(hero.consecutive_benched, GameStateScript.BENCHED_RUNS_IS_BIG_DUMB)
    assert_true(hero.big_dumb_active,
        "the fifth bench is the run it bites on, not the sixth")

    var everyone: Array = _s.roster.duplicate()
    _s.record_attempt("t1_adv_a1", _result(everyone), everyone)
    assert_false(hero.big_dumb_active, "and using them again lifts the suspension")

# -------------------------------------------- docs/04 §11.3 condition 4 (docs/15 BL-59)
#
# "Any of their own backstory bullets triggered 3+ times in one tier." The counter is
# `bullet_triggers`, written by `_count_bullet_triggers()` on every morale trigger a
# raider's OWN bullets listen for, scoped to `bullet_tier` and reset when
# `highest_unlocked_tier()` moves. `BULLET_TRIGGER_COUNTS_CAPPED` ships reading (ii): a
# trigger counts only when it moved the raider's morale. Nothing had ever asserted any
# of it — the condition was live in the code and untested (audit Q59-4).

## The authored Shaman, as the Tavern would hand her over. docs/04 §11.3's rules key
## off `legendary_def_id`, and her OWN bullets — `unbothered_by_wipes` and `mentor`,
## read from the definition file — are what the subscription gate and the counter see.
func _natsuna():
    var legends = LegendaryPool.load_from()
    var r = _raider("natsuna", Enums.CharClass.SHAMAN)
    r.display_name = legends.display_name(Enums.CharClass.SHAMAN)
    r.rarity = Enums.Rarity.LEGENDARY
    r.legendary_def_id = "legendary_shaman"
    r.backstory = legends.backstory_of(Enums.CharClass.SHAMAN)
    # Well above the 40 floor, so a wipe still MOVES her: a delta the floor clamps to
    # nothing is, under reading (ii), a trigger that did not happen to her.
    Morale.set_morale(r, 62.0)
    return r

func test_three_wipes_her_own_bullet_hears_in_one_tier_are_big_dumb() -> void:
    # `unbothered_by_wipes` listens for "wipe" (docs/04 §8.3, `BackstoryPool.TRIGGER_TAGS`),
    # so every wipe she attends credits that bullet. Three DIFFERENT rungs, so condition
    # #2 ("the same boss 3 times in a row") stays out of the verdict.
    _s.new_game("Bullets")
    var hero = _natsuna()
    _s.add_raider(hero)
    for i in 5:
        _s.add_raider(_raider("r%d" % i))
    var party: Array = _s.roster.duplicate()
    var rungs := ["t1_adv_a1", "t1_adv_a2", "t1_adv_a3"]
    for i in rungs.size():
        assert_false(hero.big_dumb_active, "%d wipe(s) is not yet BIG dumb" % i)
        _s.record_attempt(rungs[i], _result(party), party)
    assert_eq(_s.bullet_trigger_peak(hero.id), 3, "each wipe credited her own bullet")
    assert_true(hero.big_dumb_active, "the third is the one it bites on")
    assert_true(_s.big_dumb_reason_ids(hero.id).has("bullet_3_this_tier"),
        str(_s.big_dumb_reason_ids(hero.id)))
    assert_false(_s.big_dumb_reason_ids(hero.id).has("wiped_3"),
        "three different bosses is not condition #2")
    assert_true(_s.big_dumb_warning_line(hero.id).contains(
        "You did the one thing they told you not to"), "docs/04 §11.3's own row 4 wording")

func test_the_same_three_wipes_spread_across_a_tier_change_are_not() -> void:
    # "in one tier" is the scope, and `_refresh_big_dumb()` wipes the counts when
    # `highest_unlocked_tier()` moves: what annoyed her at Tier 1 is not evidence about
    # Tier 2. Known unlocks Tier 2 (docs/03 §7), and nothing else here changes.
    _s.new_game("Tiers")
    var hero = _natsuna()
    _s.add_raider(hero)
    for i in 5:
        _s.add_raider(_raider("r%d" % i))
    var party: Array = _s.roster.duplicate()
    _s.record_attempt("t1_adv_a1", _result(party), party)
    _s.record_attempt("t1_adv_a2", _result(party), party)
    assert_eq(_s.bullet_trigger_peak(hero.id), 2)
    assert_eq(_s.bullet_tier, 1, "the counts belong to Tier 1")

    _s.reputation_rank = Enums.ReputationRank.KNOWN
    assert_eq(_s.highest_unlocked_tier(), 2, "docs/03 §7: Known opens Tier 2")
    _s.record_attempt("t1_adv_a3", _result(party), party)
    assert_eq(_s.bullet_tier, 2, "the counter followed the tier")
    assert_eq(_s.bullet_trigger_peak(hero.id), 1,
        "the third wipe is the FIRST of the new tier, not the third of the old")
    assert_false(hero.big_dumb_active)
    assert_false(_s.big_dumb_reason_ids(hero.id).has("bullet_3_this_tier"))

func test_a_trigger_the_subscription_gate_swallows_does_not_count() -> void:
    # docs/04 §11.3's first mechanism: "an event reaches a Legendary only when one of
    # their OWN backstory bullets listens for it". "benched" is heard by
    # `hates_being_benched` and `needs_a_friend`; Natsuna carries neither, so the gate
    # returns 0 before the ledger and nothing is "triggered" — the reading (ii) the
    # switch ships. A Common who DOES carry the tag, benched beside her, is the control
    # that proves the trigger fired at all.
    _s.new_game("Deaf")
    var hero = _natsuna()
    _s.add_raider(hero)
    var control = _raider("grumbler")
    control.backstory = [{
        "tag": "hates_being_benched", "polarity": "negative", "text": "Quits when benched.",
    }]
    _s.add_raider(control)
    for i in 5:
        _s.add_raider(_raider("r%d" % i))
    var party: Array = _s.roster.slice(2)
    # Four runs benched: docs/05 §7.2's -2 lands from the second consecutive tick, so
    # the trigger FIRES three times — and four is still short of condition #1's five.
    for i in GameStateScript.BENCHED_RUNS_IS_BIG_DUMB - 1:
        _s.record_attempt("t1_adv_a1", _result(party), party)
    assert_eq(hero.consecutive_benched, GameStateScript.BENCHED_RUNS_IS_BIG_DUMB - 1)
    assert_true(_s.bullet_trigger_peak(control.id) >= 1,
        "the control's own bullet was credited, so the trigger really fired")
    assert_eq(_s.bullet_trigger_peak(hero.id), 0, "she never heard it")
    assert_false(_s.bullet_triggers.has(hero.id), "no row is opened for a swallowed event")
    assert_false(hero.big_dumb_active)
    assert_eq(_s.big_dumb_reason_ids(hero.id), [])

func test_the_sims_own_report_is_what_moves_the_run_counters() -> void:
    # docs/14 OQ-10, quoted at RaidSim's `_queue_deltas`: "the sim only reports; `game/`
    # applies these to the roster." Nothing applied them, so `deltas_queued` was read by
    # two lines of test_raid_sim.gd and by nothing in the game — and RaiderDetail's
    # "Ran 0 raids · saw 0 wipes" was the only line it could ever print.
    _s.new_game("Report")
    _s.add_raider(_raider("steve"))
    _s.add_raider(_raider("bob"))
    var party: Array = [_s.roster[0]]

    _s.record_attempt("t1_adv_a1", _result(party), party)
    assert_eq(_s.roster[0].runs_attended, 1)
    assert_eq(_s.roster[0].wipes_witnessed, 1, "the sim reported a wipe")
    assert_eq(_s.roster[1].runs_attended, 0, "the bench did not attend")

    _s.record_attempt("t1_adv_a1", _result(party, true), party)
    assert_eq(_s.roster[0].runs_attended, 2)
    assert_eq(_s.roster[0].wipes_witnessed, 1, "a clear adds no wipe")

func test_a_result_with_no_report_is_survived_rather_than_crashed_on() -> void:
    # Not every caller has a real SimResult — tools/fixture_reference.gd and the golden
    # harness both hand in stand-ins. A missing report must cost the counters, never the
    # attempt.
    _s.new_game("Partial")
    _s.add_raider(_raider("steve"))
    _s.add_raider(_raider("bob"))
    var party: Array = [_s.roster[0]]
    _s.record_attempt("t1_adv_a1", null, party)
    assert_eq(_s.roster[0].runs_attended, 0, "nothing was reported, so nothing is claimed")
    assert_eq(_s.roster[1].consecutive_benched, 1,
        "but the bench is the roster's own fact and is still counted")

func test_the_bench_costs_morale_only_from_the_second_consecutive_run() -> void:
    # docs/05 §7.2: "Benched while healthy and the raid ran — -2 ... only from the 2nd
    # consecutive benched tick." The trigger was fully specced in sim/core/Morale.gd,
    # capped, given a window and a backstory amplifier — and fired by nothing, so sitting
    # a raider out cost the player nothing at all.
    _s.new_game("Bench morale")
    for i in 3:
        _s.add_raider(_raider("r%d" % i))
    var party: Array = [_s.roster[0]]

    _s.record_attempt("t1_adv_a1", _result(party), party)
    assert_eq(_last_note(_s.roster[1]), "",
        "the first bench is the grace run docs/05 §7.2 gives")

    _s.record_attempt("t1_adv_a1", _result(party), party)
    assert_eq(_last_note(_s.roster[1]), "benched",
        "docs/05 §7.2's -2 lands from the second consecutive benched tick")

func test_assigning_a_drop_counts_toward_the_raiders_record() -> void:
    # docs/13 §5's "On record" line prints `loot_received`, and it read "took 0 drops"
    # for a raider in full raid gear.
    _s.new_game("Loot")
    _s.set_content(_content())
    var r = _raider("steve", Enums.CharClass.WARRIOR)
    _s.add_raider(r)
    var it = _content().starting_set(r.class_key())[0]
    _s.pending_loot.append(it)
    assert_true(_s.assign_loot(it.id, r.id), "the item should have been usable")
    assert_eq(r.loot_received, 1)


# -------------------------------------------- docs/04 §3: the board is campaign state

func test_the_recruit_board_survives_a_round_trip_instead_of_rerolling() -> void:
    # docs/14 §7.1's `rng_town` row states the reason in the doc itself: "Otherwise
    # reloading rerolls the recruit list." The board was in neither `to_dict()` nor
    # `from_dict()`, which made quit-to-menu → Continue → Tavern a FREE refresh past
    # docs/04 §3.2's `50g x 2^n` ladder, and a farm for the pity counter with it.
    _s.new_game("Board")
    _s.set_content(_content())
    _s.refresh_board()
    assert_true(_s.tavern_board.size() >= 4, "docs/02 §5.2: 4 seats at Tavern L1")
    var ids: Array = []
    for c in _s.tavern_board:
        ids.append(c.id)

    var other = GameStateScript.new()
    other.reset()
    other.set_content(_content())
    var problems: Array = other.from_dict(_s.to_dict())
    assert_eq(problems.size(), 0, str(problems))
    var back: Array = []
    for c in other.tavern_board:
        back.append(c.id)
    assert_eq(back, ids, "the same people are still sitting there")
    assert_false(other.board_needs_first_roll(),
        "a loaded board must not be refilled by opening the door")
    other.free()

func test_a_board_the_player_emptied_stays_empty_across_a_load() -> void:
    # docs/04 §3.4: "dismissing a candidate from the board is free and instant; the slot
    # stays empty until the next refresh." "Empty" and "never rolled" used to be the same
    # state, so an emptied board was refilled for free on the next visit.
    _s.new_game("Empty")
    _s.set_content(_content())
    _s.refresh_board()
    while not _s.tavern_board.is_empty():
        assert_true(_s.dismiss_candidate(0))

    var other = GameStateScript.new()
    other.reset()
    other.set_content(_content())
    other.from_dict(_s.to_dict())
    assert_true(other.tavern_board.is_empty())
    assert_false(other.board_needs_first_roll(),
        "an emptied board is not an unrolled one")
    other.free()

func test_an_untouched_campaign_still_gets_its_first_board_free() -> void:
    # The other half of the same rule: the first look at the Tavern must not be a dead
    # screen, and must not charge for the board nobody has seen yet.
    _s.new_game("First look")
    assert_true(_s.board_needs_first_roll())


func test_a_rest_where_the_drift_cancels_across_the_roster_is_not_a_stall() -> void:
    # The finished playtest's first real finding (W5-TESTS, seed 1000 on day 3): six
    # raiders above baseline drifting DOWN and six below drifting UP by the same step
    # leave the roster TOTAL unchanged to the fourth decimal, and the old total-based
    # "stalled" guard ended the rest after one day with the bench still short. The
    # town's rest button runs this same loop (BL-34), so the player saw it too.
    _s.new_game("Mirror")
    for i in 12:
        _s.add_raider(_raider("r%d" % i))
    var base := float(Morale.baseline_of(_s.roster[0], _s.facility_tier))
    var step: float = Morale.BASE_DRIFT * float(Morale.DRIFT_RATE[Enums.Rarity.COMMON])
    for i in 12:
        Morale.set_morale(_s.roster[i], base + step * 2.0 if i < 6 else base - step * 2.0)
    var rest: Dictionary = _s.rest_until_recovered()
    assert_ne(String(rest["reason"]), "stalled",
        "twelve raiders all moving toward the baseline is the opposite of a stall")
    assert_eq(String(rest["reason"]), "rested")
    assert_eq(int(rest["days"]), 2, "two steps below baseline is two ticks of rest")
    assert_true(bool(rest["settled"]))
    for r in _s.roster:
        assert_true(Morale.is_recovered(r, _s.facility_tier), r.display_name)

# ---------------------------------------------------------------- serialization

func test_state_survives_a_save_load_round_trip() -> void:
    _s.new_game("Round Trip")
    _s.reputation_rank = Enums.ReputationRank.RESPECTED
    _s.reputation_points = 42
    _s.day = 9
    _s.add_gold(15)
    _s.flags["blacksmith"] = true
    _s.add_raider(_raider("steve", Enums.CharClass.CLERIC))
    _s.add_raider(_raider("bob", Enums.CharClass.WIZARD))

    var d: Dictionary = _s.to_dict()

    var other = GameStateScript.new()
    other.reset()
    var problems: Array = other.from_dict(d)
    assert_eq(problems.size(), 0, "clean save must load clean: %s" % str(problems))
    assert_eq(other.guild_name, "Round Trip")
    assert_eq(other.gold, 75)
    assert_eq(other.day, 9)
    assert_eq(other.reputation_rank, Enums.ReputationRank.RESPECTED)
    assert_eq(other.reputation_points, 42)
    assert_eq(other.roster.size(), 2)
    assert_eq(other.roster[0].id, "steve")
    assert_eq(other.roster[0].class_id, Enums.CharClass.CLERIC)
    assert_true(bool(other.flags.get("blacksmith", false)))
    assert_true(other.active)
    other.free()

func test_the_save_records_its_version() -> void:
    _s.new_game("V")
    assert_eq(int(_s.to_dict()["save_version"]), GameStateScript.SAVE_VERSION)

func test_the_board_is_part_of_the_save_shape() -> void:
    # docs/14 §7.3: `save_version` is "bumped by ANY change to the save shape". The board
    # block arrived at v11, so a build that reads it can never be an earlier version.
    _s.new_game("Shape")
    var d: Dictionary = _s.to_dict()
    assert_true(d.has("tavern_board"), "docs/14 §7.1's `rng_town` row")
    assert_true(d.has("board_rolled"))
    assert_true(int(d["save_version"]) >= 11,
        "the board block is v11 or later, not %d" % int(d["save_version"]))

func test_a_save_written_before_the_board_existed_still_loads() -> void:
    # The v10 → v11 step, and the whole of it. A v10 body carries no board block, and
    # SaveGame's chain registers `10: _v10_to_v11` as a pure version STAMP — its own
    # comment says an added field "has no mapping to make", so the step moves nothing
    # and `from_dict`'s defaults do the honest work. docs/14 §7.3's rule holds: a
    # migration "may drop a field, never guess a value". `board_rolled` false is not a
    # guess — it is exactly what a v10 save can tell us, and it leaves the first look
    # free as it was. (This comment once claimed the chain had NO entry for 10; it
    # always had one, and audit M3-SAVE-06 owns the correction.)
    var problems: Array = _s.from_dict({
        "save_version": 10, "guild_name": "Old Guild", "gold": 40,
        "reputation_rank": "known",
    })
    assert_eq(problems.size(), 0, str(problems))
    assert_eq(_s.guild_name, "Old Guild")
    assert_eq(_s.gold, 40)
    assert_true(_s.tavern_board.is_empty())
    assert_false(_s.board_rolled)
    assert_true(_s.board_needs_first_roll(), "the first look still fills it")

func test_a_bad_board_entry_is_reported_rather_than_failing_the_load() -> void:
    # Same rule the roster loop follows: one unreadable candidate must not cost the guild.
    var d: Dictionary = {}
    _s.new_game("Reported")
    d = _s.to_dict()
    d["tavern_board"] = ["not an object"]
    var problems: Array = _s.from_dict(d)
    assert_eq(problems.size(), 1, "the load must say what it could not read: %s" % str(problems))
    assert_true(_s.active, "and one bad candidate must not throw away a readable save")

func test_a_future_save_is_refused_rather_than_half_read() -> void:
    # A partially-applied save is worse than a refused one: the player keeps
    # playing a guild that quietly lost half its roster.
    var problems: Array = _s.from_dict({
        "save_version": GameStateScript.SAVE_VERSION + 1, "guild_name": "From The Future",
    })
    assert_eq(problems.size(), 1)
    assert_false(_s.active, "a refused save must not become the live guild")
    assert_eq(_s.guild_name, "", "nothing from a refused save may be applied")

func test_an_unknown_rank_reports_the_problem_and_defaults() -> void:
    var problems: Array = _s.from_dict({
        "save_version": GameStateScript.SAVE_VERSION,
        "guild_name": "Odd", "reputation_rank": "archmage",
    })
    assert_eq(problems.size(), 1, "the load must say what it could not read")
    assert_eq(_s.reputation_rank, Enums.ReputationRank.UNKNOWN)
    assert_true(_s.active, "one bad field must not throw away a readable save")

func test_the_reputation_rank_survives_as_a_key_not_an_index() -> void:
    # Saving the enum's integer would silently re-rank every guild the day a
    # rank is inserted. Canon's six ranks are stable; the encoding must be too.
    _s.new_game("K")
    _s.reputation_rank = Enums.ReputationRank.RENOWNED
    assert_eq(String(_s.to_dict()["reputation_rank"]), "renowned")

# ======================= docs/11 §11.2 — the denominator the reward cap is a share OF

## Three counters that only ever RISE, because both figures that look like they
## could serve instead go down: `gold` is what is left after spending, and
## `reputation_points` is reduced by docs/03 §6.5's disband penalty. A cap
## computed from a falling number would shrink as the player played, which is the
## opposite of what docs/11 §11.2 ("~15% of lifetime income") asks for.
##
## Audit M5-QAB-5. `Achievements.coin_cap()` and `rp_cap()` have been dividing by
## `_prop()`'s zero fallback since they were written; these are what they divide.

func test_a_new_guild_has_earned_nothing() -> void:
    _s.new_game("Ledger")
    assert_eq(_s.gold_earned_lifetime, 0)
    assert_eq(_s.rp_earned_lifetime, 0)
    assert_eq(_s.items_sold_lifetime, 0)

func test_the_opening_purse_is_seed_capital_and_not_income() -> void:
    # docs/01 §8.0's 60 G is assigned in `new_game()` rather than paid through
    # `add_gold()`, so it is not counted. Two readings were available and this is
    # the one the code takes: "lifetime income" is what the guild EARNED, and a
    # board that paid out a share of the money it was handed at character creation
    # would owe a reward to a guild that has done nothing. Asserted rather than
    # left to the call site, because the other reading is defensible and somebody
    # will otherwise "fix" this by routing the opening purse through add_gold().
    _s.new_game("Ledger")
    assert_true(_s.gold > 0, "the guild starts with something")
    assert_eq(_s.gold_earned_lifetime, 0, "and has earned none of it")

func test_income_is_counted_and_spending_does_not_uncount_it() -> void:
    _s.new_game("Ledger")
    var opening: int = _s.gold
    _s.add_gold(500)
    assert_eq(_s.gold_earned_lifetime, 500, "the 500 is income")
    assert_true(_s.spend_gold(400), "and the guild can spend it")
    assert_eq(_s.gold, opening + 100, "the balance falls")
    assert_eq(_s.gold_earned_lifetime, 500,
        "but the lifetime total does not — a cap that shrank when you spent would "
        + "punish playing")

func test_a_refund_path_cannot_talk_the_denominator_up() -> void:
    # Positive amounts only. If a negative `add_gold()` were ever used as a charge,
    # its matching refund would otherwise inflate the one number the achievement
    # board's cap divides by — which is the number the board must not control.
    _s.new_game("Ledger")
    _s.add_gold(-100)
    assert_eq(_s.gold_earned_lifetime, 0, "a negative amount is not income")
    _s.add_gold(0)
    assert_eq(_s.gold_earned_lifetime, 0, "and neither is nothing")

func test_reputation_is_counted_at_the_award_not_at_the_balance() -> void:
    # docs/03 §6.5's disband penalty takes points away. It must not take away the
    # history, or the board's ~15% cap would be a share of a number the player can
    # be punished into lowering.
    _s.set_content(_content())
    _s.new_game("Ledger")
    var enc = _content().encounter("t1_raid_e1")
    _s._award_reputation(enc, 1)
    var awarded: int = _s.rp_earned_lifetime
    assert_true(awarded > 0, "clearing something must pay reputation")
    assert_eq(_s.reputation_points, awarded, "and the balance starts equal to it")
    _s.reputation_points = 0
    assert_eq(_s.rp_earned_lifetime, awarded,
        "the balance can fall to nothing and the lifetime total stays")

func test_every_sale_is_counted_because_the_buyback_shelf_forgets() -> void:
    # docs/11 §11.1's Economy entry is "Sell 100 items". `sold_recently` cannot
    # answer it: docs/02 §6.1 makes that a six-slot buy-back shelf, so it forgets
    # the seventh sale and would cap that achievement at six forever.
    _s.set_content(_content())
    _s.new_game("Ledger")
    var db = _content()
    var want: int = _s.BUY_BACK_SLOTS + 2
    var sold := 0
    for item_id in db.items:
        if sold >= want:
            break
        _s.pending_loot.append(db.items[item_id])
        if _s.sell_loot(String(item_id)) > 0:
            sold += 1
    assert_eq(sold, want, "this test needs more sales than the shelf holds")
    assert_eq(_s.items_sold_lifetime, sold, "every sale is counted")
    assert_eq(_s.sold_recently.size(), _s.BUY_BACK_SLOTS,
        "and the shelf really is the smaller of the two, or this proves nothing")

func test_the_counters_survive_a_save() -> void:
    # A cap that resets on load is not a cap.
    _s.new_game("Ledger")
    _s.add_gold(1234)
    _s.rp_earned_lifetime = 77
    _s.items_sold_lifetime = 9
    var body: Dictionary = _s.to_dict()
    var back = GameStateScript.new()
    back.from_dict(body)
    assert_eq(back.gold_earned_lifetime, 1234)
    assert_eq(back.rp_earned_lifetime, 77)
    assert_eq(back.items_sold_lifetime, 9)
    back.free()

func test_a_save_written_before_anything_counted_starts_at_zero() -> void:
    # v15's migration is a stamp on purpose. An older save recorded no history,
    # and seeding the lifetime total from the balance that is LEFT would be an
    # invented figure dressed as a recovered one — `gold` is what survived
    # spending, not what arrived.
    _s.new_game("Ledger")
    var body: Dictionary = _s.to_dict()
    body["gold"] = 5000
    body.erase("gold_earned_lifetime")
    body.erase("rp_earned_lifetime")
    body.erase("items_sold_lifetime")
    var back = GameStateScript.new()
    back.from_dict(body)
    assert_eq(back.gold, 5000, "the balance is read")
    assert_eq(back.gold_earned_lifetime, 0, "and the history is not invented from it")
    assert_eq(back.rp_earned_lifetime, 0)
    assert_eq(back.items_sold_lifetime, 0)
    back.free()

func test_the_reward_cap_finally_has_something_to_divide_by() -> void:
    # The reason all three exist. `Achievements.coin_cap()` is a share of lifetime
    # income and had been reading `_prop()`'s zero fallback since it was written,
    # which made every cap zero and every claim refusable.
    _s.new_game("Ledger")
    _s.add_gold(10000)
    var snap: Dictionary = Achievements.snapshot(_s)
    assert_eq(int(snap["gold_earned_lifetime"]), _s.gold_earned_lifetime,
        "the board reads the counter the state keeps")
    assert_true(Achievements.coin_cap(_s.gold_earned_lifetime) > 0,
        "and the cap is a real figure rather than a share of nothing")


# ---------------------------------------------------------------- v17 (W7-SAVE)

## What `gold_changed` saw of `announcing` each time it fired, so a test can
## read the flag from inside the emit rather than trust the code's word.
var _seen_announcing: Array = []

func _note_announcing(_amount: int) -> void:
    _seen_announcing.append(bool(_s.announcing))


func test_a_campaign_arriving_announces_itself_and_a_transaction_does_not() -> void:
    # AUDIO-10: `new_game()` and `from_dict()` both emit `gold_changed` so the
    # gold labels redraw, and docs/13 §12.4's coin trigger is "Gold changes",
    # which a restore is not. The flag is true INSIDE both arrival emits and
    # false the moment they are over, so the coin's listener needs no heuristic.
    _s.gold_changed.connect(_note_announcing)
    _seen_announcing = []
    _s.new_game("Arriving")
    assert_eq(_seen_announcing, [true], "new_game announces its one gold write")
    assert_false(_s.announcing, "and is quiet once the campaign is live")
    _seen_announcing = []
    _s.add_gold(7)
    assert_true(_s.spend_gold(7))
    assert_eq(_seen_announcing, [false, false], "a reward and a spend are transactions")
    var body: Dictionary = _s.to_dict()
    _seen_announcing = []
    assert_eq(_s.from_dict(body), [])
    assert_eq(_seen_announcing, [true], "a restore announces, it does not ring")
    assert_false(_s.announcing)
    _s.gold_changed.disconnect(_note_announcing)


func test_a_clear_puts_the_reputation_it_earned_on_the_feed() -> void:
    # LOOP-13: the macro loop's only currency was never shown — no "+N
    # reputation" anywhere. Every gain now writes one feed row of kind
    # `reputation`, and it starts with the number.
    _s.set_content(_content())
    _s.new_game("Heard", 4242)
    var party: Array = _s.roster.slice(0, 6)
    var rp_before: int = _s.reputation_points
    _s.record_attempt("t1_adv_a1", _result(party, true), party)
    var gained: int = _s.reputation_points - rp_before
    assert_true(gained > 0, "an Adventure 1 clear is worth reputation")
    var row: Dictionary = {}
    for entry in _s.event_feed:
        if String((entry as Dictionary).get("kind", "")) == "reputation":
            row = entry
    assert_false(row.is_empty(), "the feed has a reputation row: %s" % str(_s.event_feed))
    assert_true(String(row["text"]).begins_with("+%d" % gained),
        "and it leads with the number: '%s'" % String(row["text"]))
    assert_true(String(row["text"]).contains("the town heard"))
    _s.set_content(null)


func test_the_record_wall_pays_reputation_and_the_switch_can_turn_it_back_to_coin() -> void:
    # audit M5-QAB-4's own acceptance line, both halves: "with the flag off, no
    # claim path can change `reputation_points`; with it on, board RP over a full
    # scripted run stays under 15% of RP earned". docs/15 Q-69 RULED the flag ON;
    # off is the recorded alternative, and it has to keep working or the ruling
    # cannot be reversed by the designer without code.
    _s.set_content(_content())
    _s.new_game("Recorded", 4242)
    # `rost_one_of_each` is satisfied by the starting twelve (all nine classes).
    assert_true(_s.check_achievements().has("rost_one_of_each"),
        "the record is earned on day one")
    assert_eq(String(Achievements.record("rost_one_of_each")
        .get("reward", {}).get("kind", "")), "reputation")

    # OFF: the claim pays the type's coin figure and the town hears nothing.
    assert_true(_s.set_flag("achievement_rp", false))
    var rp_before: int = _s.reputation_points
    var gold_before: int = _s.gold
    _s.gold_earned_lifetime = 10000    # so the coin cap cannot be what refuses it
    assert_eq(_s.claim_achievement("rost_one_of_each"), "", "the claim is paid")
    assert_eq(_s.reputation_points, rp_before, "no claim path moves reputation")
    assert_eq(_s.gold - gold_before, 40, "it pays docs/11 §11.2's Roster figure")

    # ON (the shipped value): the same record pays 15 reputation, and the payment
    # is not counted as EARNED, so the faucet cannot widen its own ceiling.
    _s.new_game("Heard Of", 4242)
    assert_true(_s.flag_enabled("achievement_rp"), "true is the shipped value")
    _s.check_achievements()
    _s.rp_earned_lifetime = 400
    _s.reputation_points = 400
    var earned_before: int = _s.rp_earned_lifetime
    var points_before: int = _s.reputation_points
    assert_eq(_s.claim_achievement("rost_one_of_each"), "")
    assert_eq(_s.reputation_points - points_before, 15, "the town heard 15")
    assert_eq(_s.rp_earned_lifetime, earned_before,
        "and a claim is not earned reputation — the cap's denominator does not move")
    assert_true(Achievements.rp_paid(_s.achievements_claimed)
        <= Achievements.rp_cap(_s.rp_earned_lifetime),
        "the board stayed inside its share")
    _s.set_content(null)


func test_continue_replays_the_attempt_under_the_options_it_was_run_with() -> void:
    # Q-53 as ruled: `active_run` carries BL-113's multiplier and BL-116's puller
    # so the replay is a pure function of what was stored. `RaidSim.run` grows the
    # parameter that receives them in W8-SIM-BALANCE; until then the one door
    # (`run_attempt`) records what it was handed, and that is what is asserted.
    _s.set_content(_content())
    _s.new_game("Forgiving", 4242)
    var enc = _content().encounter("t1_adv_a1")
    assert_ne(enc, null)
    var party: Array = _s.roster.slice(0, mini(int(enc.party_size), _s.roster.size()))
    var puller := String(party[0].id)
    var opts := {"difficulty_mult": 0.75, "ninja_pulled": puller}
    var loadout: Dictionary = _s.build_loadout(party)
    var lived = _s.run_attempt(party, enc, _s.next_raid_seed(), loadout, opts)
    assert_eq(_s.last_run_opts, opts, "the door records the options it was handed")
    var record_opts: Dictionary = opts.duplicate()
    record_opts["loadout"] = loadout
    _s.record_attempt("t1_adv_a1", lived, party, record_opts)
    assert_almost(float(_s.active_run["difficulty_mult"]), 0.75)
    assert_eq(String(_s.active_run["ninja_pulled"]), puller)
    assert_eq(_s.save_now(), "")

    var other = GameStateScript.new()
    other.reset()
    other.set_content(_content())
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), other), [])
    assert_almost(float(other.active_run["difficulty_mult"]), 0.75, 0.0001,
        "the multiplier survives the disk")
    assert_eq(String(other.active_run["ninja_pulled"]), puller, "and so does the puller")
    var again = other.replay_active_run()
    assert_ne(again, null)
    assert_almost(float(other.last_run_opts["difficulty_mult"]), 0.75, 0.0001,
        "the replay runs under the stored multiplier")
    assert_eq(String(other.last_run_opts["ninja_pulled"]), puller, "and the stored puller")
    assert_eq(int(again.outcome), int(lived.outcome), "the same outcome")
    assert_eq(int(again.rounds), int(lived.rounds), "the same rounds")
    other.free()
    _s.set_content(null)
