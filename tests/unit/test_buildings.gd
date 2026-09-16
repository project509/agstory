extends "res://tests/TestCase.gd"
## docs/02 §11's building unlock and cost table, and the two questions the town square
## asks of it that a building screen never does: "is this standing at all" and "can gold
## buy this rung."
##
## The Market's and the Guildhall's rows are asserted where their own screens are tested
## (test_market.gd, test_tavern.gd). This file exists for the two rows those files have no
## reason to look at — the Blacksmith, which is the only building the player has to buy
## into existence, and the Adventure's Board, whose rungs cost nothing and are therefore
## the only ones a price check cannot refuse.

const Buildings = preload("res://sim/core/Buildings.gd")
const Enums = preload("res://sim/model/Enums.gd")

const ALL := ["guildhall", "tavern", "market", "blacksmith", "board"]


# =============================================== the Blacksmith's rows

func test_the_blacksmith_carries_the_three_rows_docs_02_11_prices() -> void:
    # docs/02 §11: "Blacksmith L1 | Respected | 300 G", "L2 | Established | 700 G",
    # "L3 | Renowned | 1,600 G". Three levels, not four — docs/02 §7.1's cap rule
    # ("upgrade cap = Blacksmith level", +3 at the top) has no use for a fourth.
    var rungs := Buildings.ladder("blacksmith")
    assert_eq(rungs.size(), 3, "§11 gives the Blacksmith exactly three rows")
    assert_eq(Buildings.top_level("blacksmith"), 3)
    var expected := [
        [1, Enums.ReputationRank.RESPECTED, 300],
        [2, Enums.ReputationRank.ESTABLISHED, 700],
        [3, Enums.ReputationRank.RENOWNED, 1600],
    ]
    for i in range(expected.size()):
        var row: Array = expected[i]
        var rung: Dictionary = rungs[i]
        assert_eq(int(rung["level"]), int(row[0]))
        assert_eq(int(rung["rank"]), int(row[1]),
            "L%d's gate is docs/03 §7's own column" % int(row[0]))
        assert_eq(int(rung["cost"]), int(row[2]), "L%d's price" % int(row[0]))

func test_the_blacksmiths_upper_rungs_are_ordinary_upgrades() -> void:
    # The level-1 row is the unusual one; L2 and L3 must still answer the same lookups
    # every other building's rungs answer, or the Blacksmith screen (when it exists)
    # needs its own arithmetic.
    assert_eq(Buildings.upgrade_cost("blacksmith", 0), 300, "buying it standing at all")
    assert_eq(Buildings.upgrade_cost("blacksmith", 1), 700)
    assert_eq(Buildings.upgrade_cost("blacksmith", 2), 1600)
    assert_eq(Buildings.upgrade_cost("blacksmith", 3), -1, "there is no fourth rung")
    assert_eq(Buildings.upgrade_rank("blacksmith", 1), Enums.ReputationRank.ESTABLISHED)
    assert_eq(Buildings.upgrade_rank("blacksmith", 2), Enums.ReputationRank.RENOWNED)


# =============================================== standing at all

func test_the_blacksmith_is_the_one_building_not_standing_at_the_start() -> void:
    # docs/02 §11 marks the other four "Unknown (start)" at 0 G, and docs/03 §7's own
    # note says why: canon's core loop needs all four from minute one. The Blacksmith's
    # level 1 is a purchase, so a new guild stands at level 0 — not level 1.
    assert_eq(Buildings.base_level("blacksmith"), 0)
    for id in ["guildhall", "tavern", "market", "board"]:
        assert_eq(Buildings.base_level(String(id)), 1,
            "%s is open at Unknown for nothing" % String(id))

func test_a_building_the_table_never_heard_of_is_assumed_standing() -> void:
    # A missing row must not read as a demolished building: the screens' own default
    # for an unknown id has always been level 1 and this keeps it that way.
    assert_eq(Buildings.base_level("mystery_hall"), 1)
    assert_eq(Buildings.entry_blocker("mystery_hall", 0, 0), "")

func test_an_unknown_guild_is_told_which_rank_opens_the_smithy() -> void:
    # docs/03 §7 makes "Blacksmith opens" the whole of Respected's town column, so the
    # gate must name Respected and not merely refuse.
    var why := Buildings.entry_blocker(
        "blacksmith", 999999, Enums.ReputationRank.UNKNOWN)
    assert_true(why.contains("Reach Respected"), why)
    assert_true(why.contains("Unknown"), "and it names the standing held: %s" % why)

func test_a_respected_guild_is_quoted_the_price_instead() -> void:
    # docs/11 §8.4: the screen must show WHICH of the two gates is blocking. Once the
    # rank is met the sentence has to change, or meeting it looks like it did nothing.
    var poor := Buildings.entry_blocker(
        "blacksmith", 60, Enums.ReputationRank.RESPECTED)
    assert_eq(poor, "Costs 300 G — you have 60.")
    assert_eq(Buildings.entry_blocker(
        "blacksmith", 300, Enums.ReputationRank.RESPECTED), "",
        "300 G at Respected buys it")

func test_the_four_canon_buildings_ask_nothing_of_a_new_guild() -> void:
    # A penniless Unknown guild must be able to walk into all four. This is docs/14
    # §5.2's "completable with every flag off" rule seen from the town square.
    for id in ["guildhall", "tavern", "market", "board"]:
        assert_eq(Buildings.entry_blocker(String(id), 0,
            Enums.ReputationRank.UNKNOWN), "",
            "%s must be enterable on day one" % String(id))


# =============================================== the Board climbs on standing

func test_only_the_board_climbs_on_reputation_alone() -> void:
    # docs/14 §5.3.7: "the validator asserts `gold_cost == 0` for every Board level."
    # Asked as a predicate rather than hard-coded to one id, so a future free ladder
    # inherits the refusal and a priced one can never be mistaken for one.
    assert_true(Buildings.is_reputation_only("board"))
    for id in ["guildhall", "tavern", "market", "blacksmith"]:
        assert_false(Buildings.is_reputation_only(String(id)),
            "%s costs gold in docs/02 §11" % String(id))
    assert_false(Buildings.is_reputation_only("mystery_hall"),
        "no ladder is not a free ladder")

func test_the_boards_level_is_the_rank_and_nothing_else() -> void:
    # ✅ CANON: "New Tiers can be unlocked by gaining reputations with the town."
    # docs/02 §11 puts L2 at Known and L3 at Respected, and there is no fourth row, so
    # the Board tops out three ranks before the ladder does.
    var expected := [1, 2, 3, 3, 3, 3]
    for rank in range(expected.size()):
        assert_eq(Buildings.reputation_level("board", rank), int(expected[rank]),
            "the Board at %s" % Enums.reputation_name_of(rank))

func test_the_boards_level_never_falls() -> void:
    # docs/03 §6.5 makes rank one-way, so a derived level must be monotonic too — a
    # level that could drop would take §9.2's exterior deltas away again, which
    # docs/02 §2.1 R3 forbids ("deltas persist — they are town state").
    var previous := 0
    for rank in range(Enums.REPUTATION_NAMES.size()):
        var level := Buildings.reputation_level("board", rank)
        assert_true(level >= previous, "the Board fell at %s"
            % Enums.reputation_name_of(rank))
        previous = level

func test_a_priced_ladder_cannot_be_derived_from_a_rank() -> void:
    # The gold half of a priced rung is the player's decision, so a rank alone proves
    # only the base level. A Legendary guild that never paid has no smithy and no
    # bigger stall, and this must not pretend otherwise.
    assert_eq(Buildings.reputation_level("market", Enums.ReputationRank.LEGENDARY), 1)
    assert_eq(Buildings.reputation_level(
        "blacksmith", Enums.ReputationRank.LEGENDARY), 0)


# =============================================== gold cannot buy a free rung

func test_a_price_check_cannot_refuse_a_free_rung() -> void:
    # This is the hole `purchase_refusal` exists to cover, asserted so that nobody
    # deletes it as redundant: a cost of 0 is always affordable, so `upgrade_blocker`
    # waves the Board's rungs through the moment the rank is met.
    assert_eq(Buildings.upgrade_blocker("board", 1, 0,
        Enums.ReputationRank.KNOWN), "",
        "a free rung passes both of the two gates")

func test_gold_can_never_buy_a_board_rung() -> void:
    var refusal := Buildings.purchase_refusal("board", 1)
    assert_true(refusal.contains("not gold"), refusal)
    assert_true(refusal.contains("Reach Known"),
        "and it quotes the rank as the price: %s" % refusal)
    assert_true(Buildings.purchase_refusal("board", 3).contains(
        "nothing left to open"), "at the top there is no rank left to name")
    for id in ["guildhall", "tavern", "market", "blacksmith"]:
        assert_eq(Buildings.purchase_refusal(String(id), 1), "",
            "gold is exactly what buys %s" % String(id))


# =============================================== the table's own shape

func test_every_ladder_starts_one_rung_above_its_base_level() -> void:
    # The invariant that keeps `entry_blocker` honest: it asks `upgrade_blocker` about
    # level 0, which is only the entry question when the first rung IS level 1.
    for id in ALL:
        var rungs := Buildings.ladder(String(id))
        assert_false(rungs.is_empty(), "%s must be in §11's table" % String(id))
        assert_eq(int(rungs[0]["level"]), Buildings.base_level(String(id)) + 1,
            "%s's first rung must be the one above where it starts" % String(id))

func test_no_ladder_skips_a_level_or_walks_a_rank_backwards() -> void:
    # docs/03 §9's load-time assertions in miniature: a rung that opened at a LOWER
    # rank than the rung beneath it would be reachable out of order, and one that
    # skipped a level would leave a §9.2 exterior delta with no level to key off.
    for id in ALL:
        var level := Buildings.base_level(String(id))
        var rank := -1
        for rung in Buildings.ladder(String(id)):
            assert_eq(int(rung["level"]), level + 1,
                "%s skips a level at %d" % [String(id), int(rung["level"])])
            level = int(rung["level"])
            assert_true(int(rung["rank"]) >= rank,
                "%s L%d opens earlier than the level below it" % [String(id), level])
            rank = int(rung["rank"])
        assert_true(level <= Buildings.MAX_LEVEL,
            "%s climbs past docs/02 §3.2's level cap of %d"
            % [String(id), Buildings.MAX_LEVEL])
