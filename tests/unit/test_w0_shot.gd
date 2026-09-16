extends "res://tests/TestCase.gd"
## W0-SHOT: the reference fixture's two raid modes, as tools/shot.gd reads them.
## `--fixture=raid` records a WIPE at t1_raid_e5 (docs/15 M6-BAL-04: the fixture's
## twelve do not clear Tier 1); `--fixture=raid:clear` records a CLEAR of Adventure
## 0 by the party RaidPlan.suggest_party() hands this guild and returns the seed
## it used (CRITIC-G12: the Results clear branch had never been seen). Both are
## deterministic, so a shot is reproducible from its command line alone.

const Fixture = preload("res://tools/fixture_reference.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")


func after_each() -> void:
    # record_attempt autosaves (docs/14 §7.4); the runner points SAVE_DIR at a
    # test dir, so this purges only that.
    SaveGame.purge_all()


func _fresh():
    var s = GameStateScript.new()
    s.reset()
    return s


func test_the_raid_fixture_records_one_wipe_at_the_selected_encounter() -> void:
    var st = _fresh()
    Fixture.apply(st, null, true)
    assert_eq(st.attempt_count(Fixture.SELECTED_ENCOUNTER), 1, "one attempt at t1_raid_e5")
    assert_true(st.last_result != null and not st.last_result.cleared(),
        "and it is a wipe, which is why the clear branch needed its own mode")
    assert_eq(st.selected_encounter_id, Fixture.SELECTED_ENCOUNTER, "RaidView reads E5")


func test_the_clear_fixture_records_one_clear_of_adventure_zero_and_names_its_seed() -> void:
    var st = _fresh()
    var seed_used: int = Fixture.apply_clear(st)
    assert_true(seed_used >= Fixture.SEED, "a seed from SEED upward, got %d" % seed_used)
    assert_true(seed_used < Fixture.SEED + Fixture.CLEAR_MAX_SEEDS, "inside the cap")
    assert_true(st.last_result != null and st.last_result.cleared(), "the recorded attempt is a clear")
    var enc = st.content.encounter_at_slot(Fixture.CLEAR_SLOT)
    assert_true(enc != null, "content has an encounter at %s" % Fixture.CLEAR_SLOT)
    assert_eq(st.selected_encounter_id, String(enc.id), "Results reads the A0 encounter")
    assert_eq(st.attempt_count(String(enc.id)), 1, "exactly one attempt recorded")


func test_the_clear_promotes_the_guild_so_the_records_tab_opens() -> void:
    # Guildhall's Records tab is gated on rank >= Known; a wipe pays no RP, so
    # `--press="Records"` is only reachable on the clearing fixture (report J2).
    var wiped = _fresh()
    Fixture.apply(wiped, null, true)
    var cleared = _fresh()
    Fixture.apply_clear(cleared)
    assert_true(int(cleared.reputation_rank) > int(wiped.reputation_rank),
        "the clear promotes: wipe rank %d, clear rank %d" % [wiped.reputation_rank, cleared.reputation_rank])


func test_the_clear_fixture_is_deterministic() -> void:
    var a = _fresh()
    var b = _fresh()
    assert_eq(Fixture.apply_clear(a), Fixture.apply_clear(b), "same seed twice")
    assert_eq(a.gold, b.gold, "same payout twice")


# ------------------------------------------- W6-SHEETS: the states a player reaches

const RaidPlan = preload("res://game/core/RaidPlan.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const Consumables = preload("res://sim/core/Consumables.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Loot = preload("res://sim/core/Loot.gd")


func test_the_new_fixture_is_day_one_as_the_menu_makes_it() -> void:
    # LOOP-01: docs/01 §8.0's new guild — the starting roster, 60 G, Day 1,
    # Unknown, Adventure 0 open, nothing on the log, and no "Lv." anywhere.
    var st = _fresh()
    Fixture.apply_new(st)
    assert_eq(st.day, 1, "Day 1")
    assert_eq(st.gold, GameStateScript.STARTING_GOLD, "docs/01 §8.0's opening purse")
    assert_eq(int(st.reputation_rank), int(Enums.ReputationRank.UNKNOWN), "rank Unknown")
    assert_eq(st.reputation_points, 0, "no reputation yet")
    assert_true(st.roster.size() > 0, "the starting roster is what the menu hands out")
    for r in st.roster:
        assert_eq(int(r.level), 0, "%s carries no level — the fixture-only 'Lv.' is gone" % r.display_name)
    assert_true(st.attempts.is_empty(), "nothing fought yet")
    assert_true(st.event_feed.is_empty(), "nothing on the log yet")
    var next = RaidPlan.next_open_mission(st)
    assert_true(next != null and String(next.slot) == "A0", "Adventure 0 is the open rung")


func test_the_play_fixture_is_a_legal_known_save_a_few_days_in() -> void:
    # UI-15: rank Known at its threshold, the log written by the clears, `level`
    # 0 everywhere, two of each consumable in the cupboard, the ladder walked
    # to Adventure 1 through record_attempt — every number derived, one set.
    var st = _fresh()
    var seeds: Dictionary = Fixture.apply_play(st)
    assert_eq(seeds.size(), Fixture.PLAY_LADDER.size(), "every rung cleared: %s" % str(seeds))
    for slot in Fixture.PLAY_LADDER:
        var enc = st.content.encounter_at_slot(String(slot))
        assert_true(enc != null, "content has %s" % slot)
        assert_eq(st.clear_count(String(enc.id)), 1, "%s cleared once" % slot)
        assert_eq(st.attempt_count(String(enc.id)), 1, "%s attempted once" % slot)
        assert_true(int(seeds.get(slot, -1)) >= Fixture.SEED, "%s's seed from SEED upward" % slot)
    assert_eq(int(st.reputation_rank), int(Enums.ReputationRank.KNOWN), "the A1 clear promoted the guild")
    assert_eq(st.reputation_points, Reputation.rp_floor(Enums.ReputationRank.KNOWN),
        "Known at its threshold exactly, so the Board's 'more to' figure is true")
    assert_eq(st.rp_earned_lifetime, st.reputation_points, "the lifetime counter agrees")
    var payouts := 0
    for slot in Fixture.PLAY_LADDER:
        payouts += Loot.payout(st.content.encounter_at_slot(String(slot)), 0)
    assert_eq(st.gold_earned_lifetime, Fixture.PLAY_PURSE + payouts, "income = the purse + the three first-clear payouts")
    assert_eq(st.day, 1 + Fixture.PLAY_LADDER.size(), "one Day Tick per attempt")
    for r in st.roster:
        assert_eq(int(r.level), 0, "%s carries no level" % r.display_name)
    for sku_id in Consumables.SKUS:
        assert_eq(st.consumable_count(String(sku_id), 1), Fixture.PLAY_STOCK,
            "two %s in the cupboard, none chalked, none spent" % sku_id)
    assert_true(st.event_feed.size() >= 6, "a six-row log: %d feed rows" % st.event_feed.size())
    var newest: String = String((st.event_feed.back() as Dictionary)["text"])
    assert_true(newest.begins_with("Cleared "), "the newest row is the A1 clear, got '%s'" % newest)
    assert_true(st.last_result != null and st.last_result.cleared(), "Results reads a clear")
    var next = RaidPlan.next_open_mission(st)
    assert_true(next != null and String(next.slot) == "A2", "Adventure 2 is the open rung")


func test_the_play_fixture_is_deterministic() -> void:
    var a = _fresh()
    var b = _fresh()
    assert_eq(Fixture.apply_play(a), Fixture.apply_play(b), "same seeds twice")
    assert_eq(a.gold, b.gold, "same purse twice")
    assert_eq(a.to_dict().hash(), b.to_dict().hash(), "the same save twice")


func test_the_reference_fixture_is_untouched_by_the_new_ones() -> void:
    # The diff_all baselines are taken on `apply`; the two new seams must not
    # have moved it. Its own oddities (Lv., 320 RP at Unknown, Day 23) are the
    # point of the split, so they are pinned here rather than "fixed".
    var st = _fresh()
    Fixture.apply(st)
    assert_eq(st.gold, Fixture.GOLD)
    assert_eq(st.day, Fixture.DAY)
    assert_eq(st.reputation_points, Fixture.REPUTATION_POINTS)
    assert_eq(int(st.roster[0].level), int(Fixture.CARDS[0]["level"]), "the concept's Lv. stays on the reference")
    assert_true(st.event_feed.is_empty(), "the reference log is empty (UI-03's fixture half lives in `play`)")
