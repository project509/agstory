extends "res://tests/TestCase.gd"
## Item valuation and selling (docs/11 §5-§6).
##
## docs/11 §6.2 prints twelve worked prices from canon items and says of them:
## "Every stat below is quoted exactly from canon; only value and sell are ours."
## That table is reproduced here cell for cell, because it is the only check that
## the formula and the doc have not drifted apart.

const Economy = preload("res://sim/core/Economy.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Stats = preload("res://sim/model/Stats.gd")
const Item = preload("res://sim/model/Item.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const StartingRoster = preload("res://game/core/StartingRoster.gd")
const Loot = preload("res://sim/core/Loot.gd")

var _db = null
var _made: Array = []

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []

func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []

## Build a bare item with the given stats, at a given step's source/tier.
func _mk(ac: int, hp: int, power: int, mana: int, damage: int,
        source: String = "adventure", tier: int = 1):
    var it = Item.new()
    it.id = "TEST_%s_%d" % [source, tier]
    it.name = "Test Item"
    it.slot = Enums.Slot.CHEST
    it.tier = tier
    it.source = source
    it.stats = Stats.new(ac, hp, power, mana, damage)
    return it

# ---------------------------------------------------- docs/11 §6.2, cell by cell

func test_the_worked_price_table_reproduces_exactly() -> void:
    # docs/11 §6.2. Columns: canon stats -> raw -> value -> sell at Unknown (40%)
    # -> sell at Renowned (60%). Stats are canon; value and sell are the doc's.
    var rows := [
        # name, ac, hp, power, mana, damage, source, tier, raw, value, unknown, renowned
        ["Damaged Chainmail",           3, 0, 0, 0, 0,  "start",     1,  6.0,  1,  1,  1],
        ["Iron Adventurer's Cuirass",   5, 6, 0, 0, 0,  "adventure", 1, 16.0, 15,  5, 10],
        ["Iron Adventurer's Sword",     0, 0, 0, 0, 5,  "adventure", 1, 12.5, 15,  5, 10],
        ["Apprentice's Firestaff",      0, 0, 0, 0, 10, "adventure", 1, 25.0, 25, 10, 15],
        ["Blessed Adventurer's Robe",   3, 5, 0, 5, 0,  "adventure", 1, 15.0, 15,  5, 10],
        ["Adventure's Charm of Health", 0, 7, 0, 0, 0,  "adventure", 1,  7.0,  5,  1,  5],
        ["Raider's Cuirass",            7, 9, 2, 0, 0,  "raid",      1, 29.0, 55, 20, 35],
        ["Raider's Helm",               5, 5, 1, 0, 0,  "raid",      1, 18.0, 35, 15, 20],
        ["Warrior Shield",              7, 8, 1, 0, 0,  "raid",      1, 25.0, 50, 20, 30],
        ["Strong Raid Staff (Wizard)",  0, 0, 0, 0, 16, "raid",      1, 40.0, 75, 30, 45],
        ["Bard Instrument",             0, 0, 0, 20, 0, "raid",      1, 16.0, 30, 10, 20],
        ["Raider's Robe (Mage/Wizard)", 4, 6, 0, 12, 0, "raid",      1, 23.6, 45, 20, 25],
    ]
    for row in rows:
        var name: String = row[0]
        var it = _mk(int(row[1]), int(row[2]), int(row[3]), int(row[4]), int(row[5]),
            String(row[6]), int(row[7]))
        assert_almost(Economy.raw_worth(it), float(row[8]), 0.05,
            "%s raw" % name)
        assert_eq(Economy.value_of(it), int(row[9]), "%s value" % name)
        assert_eq(Economy.sell_price(it, Enums.ReputationRank.UNKNOWN),
            int(row[10]), "%s sell at Unknown" % name)
        assert_eq(Economy.sell_price(it, Enums.ReputationRank.RENOWNED),
            int(row[11]), "%s sell at Renowned" % name)

func test_the_raw_weights_are_the_documented_ones() -> void:
    # docs/11 §6.1, derived from canon's own stat definitions.
    assert_almost(Economy.W_AC, 2.0)
    assert_almost(Economy.W_HP, 1.0)
    assert_almost(Economy.W_POWER, 3.0)
    assert_almost(Economy.W_MANA, 0.8)
    assert_almost(Economy.W_DAMAGE, 2.5)

func test_the_sell_rate_ladder_is_the_documented_one() -> void:
    # docs/11 §6.1, adopted verbatim from docs/03 §7: Unknown 40% through
    # Legendary 65%, five points per rank.
    assert_eq(Economy.SELL_RATE, [0.40, 0.45, 0.50, 0.55, 0.60, 0.65])
    assert_eq(Economy.SELL_RATE.size(), Enums.REPUTATION_KEYS.size(),
        "one sell rate per canon reputation rank")

func test_the_step_ladder_alternates_adventure_then_raid() -> void:
    # docs/11 §5: Tier 1 Adventure 1, Tier 1 Raid 2, Tier 2 Adventure 3, Tier 2
    # Raid 4 — canon's own progression order.
    assert_eq(Economy.step_of(_mk(1, 0, 0, 0, 0, "start", 1)), 0)
    assert_eq(Economy.step_of(_mk(1, 0, 0, 0, 0, "adventure", 1)), 1)
    assert_eq(Economy.step_of(_mk(1, 0, 0, 0, 0, "raid", 1)), 2)
    assert_eq(Economy.step_of(_mk(1, 0, 0, 0, 0, "adventure", 2)), 3)
    assert_eq(Economy.step_of(_mk(1, 0, 0, 0, 0, "raid", 2)), 4)

func test_the_step_coefficients_match_the_documented_table() -> void:
    # docs/11 §5: 0.35 / 1.0 / 1.9 / 3.6 / 6.9, then 1.9^(n-1).
    assert_almost(Economy.value_coeff(0), 0.35)
    assert_almost(Economy.value_coeff(1), 1.0)
    assert_almost(Economy.value_coeff(2), 1.9)
    assert_almost(Economy.value_coeff(3), 3.61, 0.01, "docs/11 rounds this to 3.6")
    assert_almost(Economy.value_coeff(4), 6.859, 0.01, "docs/11 rounds this to 6.9")

# ---------------------------------------------------------------- the floor

func test_nothing_is_ever_worth_zero() -> void:
    # docs/11 §6.2: "Minimum price is 1 G, never 0 — a rounded-to-zero item still
    # sells, or the sell-all helper silently deletes inventory."
    var worthless = _mk(0, 0, 0, 0, 0, "start", 1)
    assert_eq(Economy.value_of(worthless), 1)
    for rank in Enums.all_reputation_ranks():
        assert_true(Economy.sell_price(worthless, rank) >= 1,
            "an item must never sell for nothing")

func test_the_whole_starting_kit_is_worth_one_coin() -> void:
    # docs/11 §6.2, and it is a joke with a purpose: "That the whole beginner kit
    # is worth one coin at the Market is the joke, and it is also why S1's Common
    # hire at 15 G is not an arbitrage target."
    for key in ["warrior", "cleric", "mage", "rogue"]:
        for it in _db.starting_set(key):
            assert_eq(Economy.value_of(it), 1,
                "%s should be worth exactly 1 G" % it.id)
            for rank in Enums.all_reputation_ranks():
                assert_eq(Economy.sell_price(it, rank), 1,
                    "%s at %s — no sell rate can lift the floor"
                    % [it.id, Enums.reputation_key(rank)])

func test_prices_round_to_the_nearest_five() -> void:
    # docs/11 §3.1: every price and payout rounds to the nearest 5 G.
    assert_eq(Economy.round_to_5(16.0), 15)
    assert_eq(Economy.round_to_5(18.0), 20)
    assert_eq(Economy.round_to_5(2.1), 0, "before the 1 G floor is applied")

# ---------------------------------------------------------------- monotonicity

func test_reputation_only_ever_improves_what_the_market_pays() -> void:
    # docs/03 §7's point: the town pays better as it thinks better of you.
    var it = _mk(7, 9, 2, 0, 0, "raid", 1)
    var last := 0
    for rank in Enums.all_reputation_ranks():
        var price := Economy.sell_price(it, rank)
        assert_true(price >= last,
            "%s paid less than the rank below it" % Enums.reputation_key(rank))
        last = price

func test_a_later_gear_step_is_worth_more_than_an_earlier_one() -> void:
    # If a tier inverted, farming backwards would pay better than progressing.
    var stats := [5, 6, 0, 0, 0]
    var last := 0
    for spec in [["start", 1], ["adventure", 1], ["raid", 1],
            ["adventure", 2], ["raid", 2]]:
        var it = _mk(stats[0], stats[1], stats[2], stats[3], stats[4],
            String(spec[0]), int(spec[1]))
        var v := Economy.value_of(it)
        assert_true(v > last,
            "%s tier %d did not beat the step below it" % [spec[0], spec[1]])
        last = v

func test_real_content_never_prices_below_the_starting_kit() -> void:
    # Sanity over the whole shipped item set rather than a sample.
    for id in _db.items.keys():
        var it = _db.items[id]
        if it.source == "start":
            continue
        assert_true(Economy.value_of(it) >= 1, "%s priced below the floor" % id)

# ---------------------------------------------------------------- the helper

func test_unusable_means_nobody_can_wear_it_not_nobody_wants_it() -> void:
    # docs/02 §6.3's sell-all helper must never quietly sell a sidegrade someone
    # wanted. Only gear no class present can equip is junk by definition.
    var roster := StartingRoster.build(_db, 7)
    var pool := Loot.drop_pool(_db.encounter_at_slot("A1"), _db)
    var junk := Economy.unusable_by(pool, roster)
    for it in junk:
        for r in roster:
            assert_false(it.can_be_used_by(r.class_id),
                "%s is wearable by a %s and must not be called junk"
                % [it.id, r.class_key()])

func test_the_benchmark_twelve_can_use_everything_a1_drops() -> void:
    # The benchmark comp covers all nine classes, so nothing from A1 is junk to
    # it — which is why the helper is disabled on that screen rather than
    # offering a zero-gold button.
    var roster := StartingRoster.build(_db, 7)
    var pool := Loot.drop_pool(_db.encounter_at_slot("A1"), _db)
    assert_eq(Economy.unusable_by(pool, roster).size(), 0)

func test_a_narrow_party_finds_junk() -> void:
    var roster := []
    for r in StartingRoster.build(_db, 7):
        if r.class_key() == "warrior":
            roster.append(r)
    var pool := Loot.drop_pool(_db.encounter_at_slot("A1"), _db)
    assert_true(Economy.unusable_by(pool, roster).size() > 0,
        "a warriors-only guild cannot use a Mage staff")

func test_the_total_matches_the_sum_of_its_parts() -> void:
    # The footer preview must equal what the player is actually paid.
    var pool := Loot.drop_pool(_db.encounter_at_slot("A1"), _db)
    var expected := 0
    for it in pool:
        expected += Economy.sell_price(it, Enums.ReputationRank.KNOWN)
    assert_eq(Economy.total_sell_price(pool, Enums.ReputationRank.KNOWN), expected)

# ---------------------------------------------------------------- selling

func _state_with_content():
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Market Test")
    return s

func test_selling_a_drop_pays_the_price_on_the_button() -> void:
    var s = _state_with_content()
    var it = Loot.drop_pool(_db.encounter_at_slot("A2"), _db)[0]
    s.pending_loot.append(it)
    var before: int = s.gold
    var expected := Economy.sell_price(it, s.reputation_rank)
    var paid: int = s.sell_loot(it.id)
    assert_eq(paid, expected, "the number shown must be the number paid")
    assert_eq(s.gold, before + expected)
    assert_eq(s.pending_loot.size(), 0, "and the item leaves the window")

func test_selling_something_that_is_not_pending_pays_nothing() -> void:
    var s = _state_with_content()
    var before: int = s.gold
    assert_eq(s.sell_loot("ITM_DOES_NOT_EXIST"), 0)
    assert_eq(s.gold, before)

func test_the_sell_all_helper_only_takes_what_nobody_can_wear() -> void:
    var s = _state_with_content()
    # Trim the roster to warriors so the caster gear becomes real junk.
    var warriors: Array = []
    for r in s.roster:
        if r.class_key() == "warrior":
            warriors.append(r)
    s.roster = warriors
    for it in Loot.drop_pool(_db.encounter_at_slot("A1"), _db):
        s.pending_loot.append(it)

    var expected := s.unusable_loot_value()
    assert_true(expected > 0, "a warriors-only guild should have junk to sell")
    var before: int = s.gold
    var paid: int = s.sell_unusable_loot()
    assert_eq(paid, expected, "the preview must equal the payout")
    assert_eq(s.gold, before + paid)
    for it in s.pending_loot:
        var usable := false
        for r in s.roster:
            if it.can_be_used_by(r.class_id):
                usable = true
        assert_true(usable, "%s was left behind but nobody can wear it" % it.id)

func test_the_sell_all_helper_leaves_a_broad_roster_alone() -> void:
    var s = _state_with_content()
    for it in Loot.drop_pool(_db.encounter_at_slot("A1"), _db):
        s.pending_loot.append(it)
    var before: int = s.pending_loot.size()
    assert_eq(s.unusable_loot_value(), 0)
    assert_eq(s.sell_unusable_loot(), 0)
    assert_eq(s.pending_loot.size(), before,
        "nothing the benchmark twelve can wear may be swept away")

func test_a_richer_reputation_sells_the_same_item_for_more() -> void:
    var s = _state_with_content()
    var it = Loot.drop_pool(_db.encounter_at_slot("A2"), _db)[0]
    s.pending_loot.append(it)
    var at_unknown := Economy.sell_price(it, Enums.ReputationRank.UNKNOWN)
    s.reputation_rank = Enums.ReputationRank.LEGENDARY
    var at_legendary: int = s.sell_loot(it.id)
    assert_true(at_legendary >= at_unknown,
        "a Legendary guild must not be paid less than an Unknown one")
