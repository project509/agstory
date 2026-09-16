extends "res://tests/TestCase.gd"
## Guild Reputation: the ladder, the earning rules, the loss rule, the gates
## (docs/03 §3, §6, §7, §8.1, §9).
##
## The centrepiece here is `test_the_pacing_table_reproduces_row_by_row`. docs/03
## §6.4 prints a nineteen-row expected-progress table and says of it: "this is the
## pacing the numbers in §6.1 were solved for". That makes the table the spec and
## the award formula merely its implementation — so the test walks the whole table
## through the live code and checks the RP AND the rank after every single row. If
## any award, factor or threshold drifts, one of nineteen rows moves.

const Reputation = preload("res://sim/core/Reputation.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Economy = preload("res://sim/core/Economy.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")

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


## The two fields `Reputation` reads off an encounter. Using a stand-in rather than
## the content tables is deliberate: §6.4's table spans Tiers 1-5 and Adventures
## 1-5, and only Tier 1 exists in `data/` so far.
class FakeEncounter extends RefCounted:
    var tier: int = 1
    var slot: String = "E1"

    func _init(p_slot: String, p_tier: int) -> void:
        slot = p_slot
        tier = p_tier


func _enc(slot: String, tier: int = 1):
    return FakeEncounter.new(slot, tier)


# ---------------------------------------------------------------- §3, §6.4 ladder

func test_the_ladder_is_the_six_canon_ranks() -> void:
    # ✅ CANON names all six. The enum and the threshold table must not disagree
    # about how many rungs the ladder has.
    assert_eq(Reputation.thresholds().size(), Enums.REPUTATION_KEYS.size(),
        "one RP threshold per canon rank")
    assert_eq(Enums.reputation_name_of(Enums.ReputationRank.UNKNOWN), "Unknown",
        "canon fixes Unknown as the start")

func test_the_thresholds_are_the_documented_ones() -> void:
    # docs/03 §6.4.
    assert_eq(Reputation.thresholds(), [0, 120, 400, 900, 1800, 3200])

func test_the_thresholds_are_strictly_increasing() -> void:
    # docs/03 §9's load assertion, asserted on the constants instead of on a file.
    for i in range(1, Reputation.thresholds().size()):
        assert_true(int(Reputation.thresholds()[i]) > int(Reputation.thresholds()[i - 1]),
            "threshold %d must exceed %d" % [i, i - 1])

func test_rank_is_read_off_the_band_not_the_boundary_below() -> void:
    # docs/03 §6.4's bands: Unknown 0-119, Known 120-399, and so on.
    assert_eq(Reputation.rank_for_rp(0), Enums.ReputationRank.UNKNOWN)
    assert_eq(Reputation.rank_for_rp(119), Enums.ReputationRank.UNKNOWN)
    assert_eq(Reputation.rank_for_rp(120), Enums.ReputationRank.KNOWN)
    assert_eq(Reputation.rank_for_rp(399), Enums.ReputationRank.KNOWN)
    assert_eq(Reputation.rank_for_rp(400), Enums.ReputationRank.RESPECTED)
    assert_eq(Reputation.rank_for_rp(899), Enums.ReputationRank.RESPECTED)
    assert_eq(Reputation.rank_for_rp(900), Enums.ReputationRank.ESTABLISHED)
    assert_eq(Reputation.rank_for_rp(1799), Enums.ReputationRank.ESTABLISHED)
    assert_eq(Reputation.rank_for_rp(1800), Enums.ReputationRank.RENOWNED)
    assert_eq(Reputation.rank_for_rp(3199), Enums.ReputationRank.RENOWNED)
    assert_eq(Reputation.rank_for_rp(3200), Enums.ReputationRank.LEGENDARY)
    assert_eq(Reputation.rank_for_rp(999999), Enums.ReputationRank.LEGENDARY,
        "the top rank has no ceiling")

func test_the_meter_fills_across_a_rank_and_is_full_at_legendary() -> void:
    assert_almost(Reputation.progress_in_rank(120, Enums.ReputationRank.KNOWN),
        0.0, 0.0001, "at the floor of a rank the meter is empty")
    assert_almost(Reputation.progress_in_rank(260, Enums.ReputationRank.KNOWN),
        0.5, 0.0001, "halfway from 120 to 400")
    assert_almost(Reputation.progress_in_rank(3200, Enums.ReputationRank.LEGENDARY),
        1.0, 0.0001, "Legendary has no next rung, so the meter reads full")
    assert_eq(Reputation.rp_for_next(Enums.ReputationRank.LEGENDARY), -1)
    assert_eq(Reputation.rp_for_next(Enums.ReputationRank.UNKNOWN), 120)


# ---------------------------------------------------------------- §6.1 awards

func test_the_tier_one_raid_award_table_is_canon_shaped() -> void:
    # docs/03 §6.1. First-clear column and repeat base, and the doc's own stated
    # tier total of 200 for a first full clear.
    assert_eq(Reputation.raid_awards()["E1"], [10, 2])
    assert_eq(Reputation.raid_awards()["E2"], [15, 3])
    assert_eq(Reputation.raid_awards()["E3"], [25, 5])
    assert_eq(Reputation.raid_awards()["E4"], [35, 7])
    assert_eq(Reputation.raid_awards()["E5"], [65, 13])
    assert_eq(Reputation.full_tier_bonus_pair(), [50, 10])

    var total := 0
    for slot in Reputation.raid_awards():
        total += int(Reputation.raid_awards()[slot][0])
    total += int(Reputation.full_tier_bonus_pair()[0])
    assert_eq(total, 200, "docs/03 §6.1's printed 'Raid tier total, first time'")

func test_an_adventures_rungs_sum_to_the_documented_adventure_award() -> void:
    # docs/03 §6.1 prices a whole Adventure; docs/15 BL-24 makes one board rung one
    # encounter. The split must lose nothing: three rungs, exactly the doc's total.
    var documented := {1: 25, 2: 50, 3: 75, 4: 100, 5: 125}
    for tier in documented:
        var sum_first := 0
        var sum_repeat := 0
        for slot in ["A1", "A2", "A3"]:
            var pair := Reputation.base_awards(slot, int(tier))
            sum_first += int(pair[0])
            sum_repeat += int(pair[1])
        assert_eq(sum_first, int(documented[tier]),
            "Adventure %d first-clear RP" % int(tier))
        assert_eq(sum_repeat, int(documented[tier]) / 5,
            "Adventure %d repeat base (a fifth of the first clear, per §6.1)"
                % int(tier))

func test_the_rungs_of_an_adventure_rise() -> void:
    # The boss rung must pay the most, or the board teaches the wrong lesson.
    for tier in [1, 2, 3, 4, 5]:
        var a1 := int(Reputation.base_awards("A1", tier)[0])
        var a2 := int(Reputation.base_awards("A2", tier)[0])
        var a3 := int(Reputation.base_awards("A3", tier)[0])
        assert_true(a1 < a2 and a2 < a3,
            "Adventure %d rungs must rise: %d/%d/%d" % [tier, a1, a2, a3])

func test_adventure_awards_are_not_multiplied_by_tier_a_second_time() -> void:
    # This is the trap in §6.2: the raid table is labelled "Tier 1 base awards" and
    # the adventure table is not. §6.4's pacing table settles it by pricing
    # Adventure 2 at 50 — the §6.1 number unchanged — in the same table where every
    # raid row IS multiplied. Multiplying adventures too would pay 100.
    var adv2_total := 0
    for slot in ["A1", "A2", "A3"]:
        adv2_total += Reputation.award_for(_enc(slot, 2), 1, 2)
    assert_eq(adv2_total, 50, "Adventure 2 pays 50, not 100")

    # ... while a Tier 2 raid encounter pays exactly double its Tier 1 base.
    assert_eq(Reputation.award_for(_enc("E5", 2), 1, 2), 130,
        "docs/03 §6.2: Raid Tier 2 Encounter 5 is 65 x 2")

func test_tutorials_pay_the_documented_fifteen_between_them() -> void:
    # docs/03 §6.1: Adventure 0 is 5 and the Tutorial Raid is 10, and skipping
    # forfeits the RP — "15 RP total, which is deliberately trivial".
    assert_eq(Reputation.award_for(_enc("A0", 1), 1), 5)
    assert_eq(Reputation.award_for(_enc("TR", 1), 1), 10)

func test_content_that_pays_no_reputation_pays_none() -> void:
    assert_eq(Reputation.award_for(_enc("E9", 1), 1), 0,
        "an unknown slot must pay zero rather than guess")
    assert_eq(Reputation.award_for(null, 1), 0)


# ---------------------------------------------------------------- §6.3 repeats

func test_the_worked_repeat_table_for_encounter_five_reproduces() -> void:
    # docs/03 §6.3's own worked example, `repeat_base = 13`. This is the whole
    # anti-farm curve in one assertion.
    var expected := {}
    expected[1] = 65          # the first clear pays the first-clear column
    for n in range(2, 7):
        expected[n] = 13
    for n in range(7, 12):
        expected[n] = 6
    for n in range(12, 17):
        expected[n] = 3
    for n in range(17, 23):
        expected[n] = 1
    for n in expected:
        assert_eq(Reputation.award_for(_enc("E5", 1), int(n)), int(expected[n]),
            "clear #%d of Tier 1 Encounter 5" % int(n))

func test_twenty_repeats_of_the_hardest_boss_lose_to_one_first_clear_above() -> void:
    # docs/03 §6.3's stated design contract: "Twenty repeat clears of the tier's
    # hardest boss yield 115 RP — less than one first clear of the next tier's boss
    # 5 (130 RP at Tier 2). Progression beats farming, but farming is never
    # worthless."
    var farmed := 0
    for n in range(2, 22):
        farmed += Reputation.award_for(_enc("E5", 1), n)
    assert_eq(farmed, 115, "twenty repeat clears of Tier 1 Encounter 5")
    assert_eq(Reputation.award_for(_enc("E5", 2), 1, 2), 130,
        "one first clear of Tier 2 Encounter 5")
    assert_true(farmed < 130, "progression must beat farming")

func test_repeats_floor_at_one_and_never_reach_zero() -> void:
    # docs/03 §6.3: "floors at 1 RP — never zero, so a stuck player always inches
    # forward." The floor is a catch-up mechanism, so it is load-bearing.
    for n in range(2, 200):
        assert_true(Reputation.repeat_rp(2, n) >= 1,
            "clear #%d of the cheapest content still pays" % n)
    assert_eq(Reputation.repeat_rp(13, 100), 1)


# ---------------------------------------------------------------- §6.2 factors

func test_obsolescence_only_bites_two_tiers_back() -> void:
    # docs/03 §6.2: 0.25 if encounter_tier < highest_unlocked_tier - 1.
    assert_almost(Reputation.obsolescence(3, 3), 1.0, 0.0001, "current tier")
    assert_almost(Reputation.obsolescence(2, 3), 1.0, 0.0001, "one tier back")
    assert_almost(Reputation.obsolescence(1, 3), 0.25, 0.0001, "two tiers back")
    assert_almost(Reputation.obsolescence(1, 5), 0.25, 0.0001, "four tiers back")

func test_farming_tier_one_at_the_top_of_the_ladder_pays_a_quarter() -> void:
    # The stated purpose: "Stops the player farming Raid 1 for Legendary rank."
    assert_eq(Reputation.award_for(_enc("E5", 1), 1, 5), 16,
        "65 x 1 x 0.25, floored")
    assert_eq(Reputation.full_tier_bonus(1, true, 5), 12, "50 x 1 x 0.25, floored")

func test_the_catchup_valve_doubles_adventures_and_leaves_raids_alone() -> void:
    # docs/03 §6.2: catchup "Applies to **adventure** content only" — the point of
    # M3 is to route a stuck player around the raid they cannot clear, so doubling
    # the raid would defeat it.
    var plain := Reputation.award_for(_enc("A3", 1), 1, 1, false)
    var stalled := Reputation.award_for(_enc("A3", 1), 1, 1, true)
    assert_eq(stalled, plain * 2, "adventures pay double while stalled")
    assert_eq(Reputation.award_for(_enc("E5", 1), 1, 1, true),
        Reputation.award_for(_enc("E5", 1), 1, 1, false),
        "raids are untouched by the catch-up flag")
    assert_almost(Reputation.catchup_factor(), 2.0, 0.0001)


# ---------------------------------------------------------------- §6.4 pacing

func test_the_pacing_table_reproduces_row_by_row() -> void:
    # docs/03 §6.4's nineteen-row expected-progress table, walked through the live
    # award code. Each row is [label, awards, expected row RP, expected cumulative,
    # expected rank after], where one award is [slot, tier, clear#] and a "+bonus"
    # entry is ["BONUS", tier, 0].
    #
    # `highest_unlocked_tier` is read from the rank as the game reads it, so the
    # obsolescence factor is live throughout: the table is also a proof that a
    # clean no-farm run never trips it.
    var rows := [
        ["Adventure 0 + Tutorial Raid + Adventure 1",
            [["A0", 1, 1], ["TR", 1, 1], ["A1", 1, 1], ["A2", 1, 1], ["A3", 1, 1]],
            40, 40, Enums.ReputationRank.UNKNOWN],
        ["Raid 1 — Enc 1, 2, 3",
            [["E1", 1, 1], ["E2", 1, 1], ["E3", 1, 1]],
            50, 90, Enums.ReputationRank.UNKNOWN],
        ["Raid 1 — Enc 4", [["E4", 1, 1]], 35, 125, Enums.ReputationRank.KNOWN],
        ["Raid 1 — Enc 5 + full-clear bonus",
            [["E5", 1, 1], ["BONUS", 1, 0]], 115, 240, Enums.ReputationRank.KNOWN],
        ["Adventure 2",
            [["A1", 2, 1], ["A2", 2, 1], ["A3", 2, 1]],
            50, 290, Enums.ReputationRank.KNOWN],
        ["Raid 2 (x2) — Enc 1-3",
            [["E1", 2, 1], ["E2", 2, 1], ["E3", 2, 1]],
            100, 390, Enums.ReputationRank.KNOWN],
        ["Raid 2 — Enc 4", [["E4", 2, 1]], 70, 460, Enums.ReputationRank.RESPECTED],
        ["Raid 2 — Enc 5 + bonus",
            [["E5", 2, 1], ["BONUS", 2, 0]], 230, 690,
            Enums.ReputationRank.RESPECTED],
        ["Adventure 3",
            [["A1", 3, 1], ["A2", 3, 1], ["A3", 3, 1]],
            75, 765, Enums.ReputationRank.RESPECTED],
        ["Raid 3 (x3) — Enc 1-2",
            [["E1", 3, 1], ["E2", 3, 1]], 75, 840,
            Enums.ReputationRank.RESPECTED],
        ["Raid 3 — Enc 3", [["E3", 3, 1]], 75, 915,
            Enums.ReputationRank.ESTABLISHED],
        ["Raid 3 — Enc 4, 5 + bonus",
            [["E4", 3, 1], ["E5", 3, 1], ["BONUS", 3, 0]], 450, 1365,
            Enums.ReputationRank.ESTABLISHED],
        ["Adventure 4",
            [["A1", 4, 1], ["A2", 4, 1], ["A3", 4, 1]],
            100, 1465, Enums.ReputationRank.ESTABLISHED],
        ["Raid 4 (x4) — Enc 1-3",
            [["E1", 4, 1], ["E2", 4, 1], ["E3", 4, 1]], 200, 1665,
            Enums.ReputationRank.ESTABLISHED],
        ["Raid 4 — Enc 4", [["E4", 4, 1]], 140, 1805,
            Enums.ReputationRank.RENOWNED],
        ["Raid 4 — Enc 5 + bonus",
            [["E5", 4, 1], ["BONUS", 4, 0]], 460, 2265,
            Enums.ReputationRank.RENOWNED],
        ["Adventure 5",
            [["A1", 5, 1], ["A2", 5, 1], ["A3", 5, 1]],
            125, 2390, Enums.ReputationRank.RENOWNED],
        ["Raid 5 (x5) — Enc 1-4",
            [["E1", 5, 1], ["E2", 5, 1], ["E3", 5, 1], ["E4", 5, 1]], 425, 2815,
            Enums.ReputationRank.RENOWNED],
        ["Raid 5 — Enc 5 + bonus",
            [["E5", 5, 1], ["BONUS", 5, 0]], 575, 3390,
            Enums.ReputationRank.LEGENDARY],
    ]

    var rp := 0
    var rank: int = Enums.ReputationRank.UNKNOWN
    for row in rows:
        var label: String = row[0]
        var earned := 0
        for award in row[1]:
            var slot: String = award[0]
            var tier: int = int(award[1])
            var hut: int = Reputation.max_raid_tier(rank)
            if slot == "BONUS":
                earned += Reputation.full_tier_bonus(tier, true, hut)
            else:
                earned += Reputation.award_for(
                    _enc(slot, tier), int(award[2]), hut)
        assert_eq(earned, int(row[2]), "%s — row RP" % label)
        rp += earned
        rank = Reputation.rank_after(rp, rank)
        assert_eq(rp, int(row[3]), "%s — cumulative RP" % label)
        assert_eq(rank, int(row[4]), "%s — rank after (got %s)"
            % [label, Enums.reputation_name_of(rank)])

func test_the_pacing_contract_holds_one_rank_per_tier_at_boss_three_or_four() -> void:
    # docs/03 §6.4's contract, in one line: "one rank per raid tier, arriving at
    # boss 3-4 of that tier — so the reward for a tier lands while the player is
    # still inside it". Rather than restate the table, this walks the clean run one
    # encounter at a time and records WHICH encounter each rank-up landed on, which
    # is the property the contract is actually about.
    var sequence := [["A0", 0, 0], ["TR", 0, 0]]
    for tier in range(1, 6):
        for rung in ["A1", "A2", "A3"]:
            sequence.append([rung, tier, 0])
        for enc in range(1, 6):
            sequence.append(["E%d" % enc, tier, enc])
        sequence.append(["BONUS", tier, 6])

    var rp := 0
    var rank: int = Enums.ReputationRank.UNKNOWN
    var arrivals := {}
    for step in sequence:
        var slot: String = step[0]
        var tier: int = int(step[1])
        var hut: int = Reputation.max_raid_tier(rank)
        if slot == "BONUS":
            rp += Reputation.full_tier_bonus(tier, true, hut)
        else:
            rp += Reputation.award_for(_enc(slot, maxi(1, tier)), 1, hut)
        var now: int = Reputation.rank_after(rp, rank)
        if now > rank:
            arrivals[now] = [tier, int(step[2])]
        rank = now

    assert_eq(rank, Enums.ReputationRank.LEGENDARY,
        "a clean no-farm run must finish the ladder exactly at the end of Raid 5")

    for reached in [Enums.ReputationRank.KNOWN, Enums.ReputationRank.RESPECTED,
            Enums.ReputationRank.ESTABLISHED, Enums.ReputationRank.RENOWNED]:
        assert_has(arrivals, reached,
            "%s must be reached on a clean run" % Enums.reputation_name_of(reached))
        var where: Array = arrivals[reached]
        # One rank per raid tier: Known on Tier 1, Respected on Tier 2, and so on.
        assert_eq(int(where[0]), int(reached),
            "%s must arrive during raid tier %d, not %d"
                % [Enums.reputation_name_of(reached), int(reached), int(where[0])])
        assert_in_range(float(where[1]), 3.0, 4.0,
            "%s must arrive on boss 3 or 4 of its tier, not encounter %d"
                % [Enums.reputation_name_of(reached), int(where[1])])

    # And Legendary lands on the FULL CLEAR of Raid 5 — the last thing in the game.
    # §6.4 draws the consequence itself: "Legendary rank cannot gate content".
    var legendary: Array = arrivals[Enums.ReputationRank.LEGENDARY]
    assert_eq(int(legendary[0]), 5)
    assert_eq(int(legendary[1]), 6, "on the full-tier bonus, not on Encounter 5")
    assert_eq(Reputation.max_raid_tier(Enums.ReputationRank.RENOWNED),
        Reputation.max_raid_tier(Enums.ReputationRank.LEGENDARY),
        "so Legendary must gate no raid tier Renowned did not already gate")


# ---------------------------------------------------------------- §6.5 loss rule

func test_rank_never_decreases() -> void:
    # docs/03 §6.5's monotonic-rank rule, and §8.2's reason: with rank loss "a
    # disband cascade could drop a player from Established to Respected and hand
    # them strictly worse raiders for content they had already unlocked".
    assert_eq(Reputation.rank_after(0, Enums.ReputationRank.ESTABLISHED),
        Enums.ReputationRank.ESTABLISHED,
        "even zero RP cannot demote a rank already held")
    assert_eq(Reputation.rank_after(3200, Enums.ReputationRank.UNKNOWN),
        Enums.ReputationRank.LEGENDARY, "but RP can still promote")

func test_a_disband_costs_a_tenth_of_the_rp_earned_inside_the_rank() -> void:
    # docs/03 §6.5: "-10% of RP earned inside the current rank, clamped to the rank
    # floor". At Respected (floor 400) holding 600, the 200 earned inside the rank
    # is what is taxed — 20 RP — not the whole 600.
    assert_eq(Reputation.rp_after_disband(600, Enums.ReputationRank.RESPECTED), 580)
    assert_eq(Reputation.rp_after_disband(400, Enums.ReputationRank.RESPECTED), 400,
        "at the floor of a rank there is nothing inside it to lose")
    assert_almost(Reputation.disband_rp_penalty(), 0.10, 0.0001)

func test_a_disband_can_never_demote() -> void:
    # The clamp, checked at every rank at four points INSIDE that rank's band. The
    # points have to be inside it: 199 RP while still holding Unknown is not a state
    # the game can be in, since 120 already promotes.
    for rank in range(Reputation.thresholds().size()):
        var floor_rp: int = Reputation.rp_floor(rank)
        var next_rp: int = Reputation.rp_for_next(rank)
        var span: int = 4000 if next_rp < 0 else next_rp - floor_rp
        for offset in [0, 1, span / 2, span - 1]:
            var held: int = floor_rp + int(offset)
            var after := Reputation.rp_after_disband(held, rank)
            assert_true(after >= floor_rp,
                "%s: %d RP must not fall below the rank floor %d"
                    % [Enums.reputation_name_of(rank), held, floor_rp])
            assert_true(after <= held,
                "a disband must never PAY reputation")
            assert_eq(Reputation.rank_for_rp(after), rank,
                "%s: a disband at %d RP must not change the rank"
                    % [Enums.reputation_name_of(rank), held])

func test_a_disband_cannot_demote_even_from_the_very_bottom_of_a_rank() -> void:
    # The sharpest case: one RP into Established, a disband must leave the player
    # Established. docs/03 §8.2 calls this "the spiral's steepest possible slope".
    var after := Reputation.rp_after_disband(901, Enums.ReputationRank.ESTABLISHED)
    assert_eq(after, 901, "10% of the 1 RP earned inside the rank floors to 0")
    assert_eq(Reputation.rank_for_rp(after), Enums.ReputationRank.ESTABLISHED)

# ---------------------------------------------------------------- §7 gates

func test_the_sell_rate_ladder_is_the_same_object_the_economy_uses() -> void:
    # docs/11 §6.1 adopts this ladder from docs/03 §7. Two copies of one number are
    # a drift risk, so the two are asserted equal rather than assumed equal.
    for rank in range(Reputation.thresholds().size()):
        assert_almost(Reputation.sell_rate(rank), float(Economy.SELL_RATE[rank]),
            0.0001, "sell rate at %s" % Enums.reputation_name_of(rank))
    assert_almost(Reputation.sell_rate(Enums.ReputationRank.UNKNOWN), 0.40, 0.0001)
    assert_almost(Reputation.sell_rate(Enums.ReputationRank.LEGENDARY), 0.65, 0.0001)

func test_consumables_get_cheaper_and_never_dearer() -> void:
    # docs/03 §7: 100 / 100 / 95 / 90 / 85 / 80 percent.
    var expected := [1.00, 1.00, 0.95, 0.90, 0.85, 0.80]
    for rank in range(expected.size()):
        assert_almost(Reputation.consumable_price_multiplier(rank),
            float(expected[rank]), 0.0001,
            "consumable price at %s" % Enums.reputation_name_of(rank))

func test_the_recruit_pool_matches_the_canon_column() -> void:
    # docs/03 §7's recruit column, marked ✅ CANON per §5.3 for four of six ranks.
    assert_eq(Reputation.recruit_tiers(Enums.ReputationRank.UNKNOWN),
        [Enums.Rarity.COMMON], "canon: Unknown finds Common only")
    assert_eq(Reputation.recruit_tiers(Enums.ReputationRank.KNOWN),
        [Enums.Rarity.COMMON, Enums.Rarity.UNCOMMON])
    assert_eq(Reputation.recruit_tiers(Enums.ReputationRank.RESPECTED),
        [Enums.Rarity.UNCOMMON, Enums.Rarity.RARE],
        "canon: Common stops appearing at Respected")
    assert_eq(Reputation.recruit_tiers(Enums.ReputationRank.RENOWNED),
        [Enums.Rarity.RARE, Enums.Rarity.EPIC, Enums.Rarity.LEGENDARY])
    assert_eq(Reputation.recruit_tiers(Enums.ReputationRank.LEGENDARY),
        [Enums.Rarity.EPIC, Enums.Rarity.LEGENDARY])

func test_no_rank_reintroduces_a_rarity_a_lower_rank_had_retired() -> void:
    # docs/03 §9's load assertion, which "guards C4 and C8 against a bad tuning
    # pass": each rarity's presence across the ladder must be one contiguous run.
    for rarity in Enums.all_rarities():
        var seen := false
        var gone := false
        for rank in range(Reputation.thresholds().size()):
            var present: bool = Reputation.recruit_tiers(rank).has(rarity)
            if present and gone:
                fail("%s reappears at %s after being retired"
                    % [Enums.rarity_name_of(rarity),
                        Enums.reputation_name_of(rank)])
            if present:
                seen = true
            elif seen:
                gone = true

func test_reputation_unlocks_tiers_which_is_the_canon_promise() -> void:
    # ✅ CANON: "New Tiers can be unlocked by gaining reputations with the town."
    assert_eq(Reputation.max_raid_tier(Enums.ReputationRank.UNKNOWN), 1)
    assert_eq(Reputation.max_raid_tier(Enums.ReputationRank.KNOWN), 2)
    assert_eq(Reputation.max_raid_tier(Enums.ReputationRank.RESPECTED), 3)
    assert_eq(Reputation.max_raid_tier(Enums.ReputationRank.ESTABLISHED), 4)
    assert_eq(Reputation.max_raid_tier(Enums.ReputationRank.RENOWNED), 5)
    for rank in range(1, Reputation.thresholds().size()):
        assert_true(Reputation.max_raid_tier(rank)
            >= Reputation.max_raid_tier(rank - 1),
            "content unlocks must never close again")

func test_content_gating_reads_the_rank() -> void:
    assert_true(Reputation.content_unlocked(_enc("E1", 1),
        Enums.ReputationRank.UNKNOWN), "Raid 1 is open from minute one")
    assert_false(Reputation.content_unlocked(_enc("E1", 2),
        Enums.ReputationRank.UNKNOWN), "Raid 2 is not")
    assert_true(Reputation.content_unlocked(_enc("E1", 2),
        Enums.ReputationRank.KNOWN))
    assert_true(Reputation.content_unlocked(_enc("A0", 1),
        Enums.ReputationRank.UNKNOWN),
        "tutorials are never reputation-gated — they are the first thing you do")
    assert_false(Reputation.content_unlocked(null, Enums.ReputationRank.LEGENDARY))

func test_every_rank_names_a_town_unlock_and_a_market_tier() -> void:
    # docs/03 §7 fills both columns for all six ranks; an empty cell would mean a
    # rank-up that visibly does nothing.
    for rank in range(Reputation.thresholds().size()):
        assert_true(Reputation.town_unlock(rank).length() > 0,
            "%s must unlock something in town" % Enums.reputation_name_of(rank))
        assert_true(Reputation.market_stock(rank).length() > 0,
            "%s must move the Market stock" % Enums.reputation_name_of(rank))

func test_the_town_unlock_column_is_items_with_building_ids() -> void:
    # M3-TUNE-05's split (W6-COPY): each rank's column is `[{building, text}]`
    # so the Town can filter a flagged-off building by id rather than by
    # string surgery, and the prose docs/03 §7 prints is the texts joined.
    for rank in range(Reputation.thresholds().size()):
        var items: Array = Reputation.town_unlock_items(rank)
        assert_true(items.size() >= 1, "%s names at least one thing" % Enums.reputation_name_of(rank))
        var joined: Array = []
        for item in items:
            assert_true(item is Dictionary and item.has("building") and item.has("text"), str(item))
            assert_true(String(item["text"]).length() > 0, "an item carries its sentence")
            joined.append(String(item["text"]))
        assert_eq(Reputation.town_unlock(rank), "; ".join(PackedStringArray(joined)))
    # docs/03 §7's own rows, verbatim.
    assert_eq(Reputation.town_unlock(Enums.ReputationRank.RESPECTED), "Blacksmith opens")
    assert_eq(Reputation.town_unlock(Enums.ReputationRank.LEGENDARY),
        "Perfect potions; Legendary raiders, one in twenty")
    # The filter: a building whose flag is off leaves the sentence; one with no
    # flag in the map, or with it on, stays.
    var off := {"blacksmith": false}
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.RESPECTED, off), "")
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.ESTABLISHED, off),
        "Guildhall facility upgrade II; Market expansion")
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.ESTABLISHED, {"blacksmith": true}),
        Reputation.town_unlock(Enums.ReputationRank.ESTABLISHED))
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.KNOWN, off),
        Reputation.town_unlock(Enums.ReputationRank.KNOWN), "Known names no flagged building")
    # An older file's prose string still reads as one untagged item.
    var legacy: Dictionary = Reputation.normalize({"ranks": [{"key": "unknown",
        "town_unlock": "Guildhall, Tavern"}]})
    assert_eq(legacy["ranks"][0]["town_unlock"], [{"building": "", "text": "Guildhall, Tavern"}])


# ---------------------------------------------------------------- §6.1 tier bonus

func test_the_full_tier_bonus_needs_all_five_encounters() -> void:
    assert_false(Reputation.tier_complete(["E1", "E2", "E3", "E4"]),
        "four of five is not a full clear")
    assert_true(Reputation.tier_complete(["E1", "E2", "E3", "E4", "E5"]))
    assert_true(Reputation.tier_complete(["E5", "E4", "E3", "E2", "E1", "A1"]),
        "order does not matter and extra slots do not hurt")


# ------------------------------------------------- live campaign (§6, §8.1 M3)

func _state():
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Reputation Test")
    return s

class Won extends RefCounted:
    func cleared() -> bool: return true
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0

class Lost extends RefCounted:
    func cleared() -> bool: return false
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0

func test_a_new_guild_starts_unknown_with_nothing() -> void:
    var s = _state()
    assert_eq(s.reputation_points, 0)
    assert_eq(s.reputation_rank, Enums.ReputationRank.UNKNOWN)
    assert_eq(s.rank_name(), "Unknown", "canon's own word for the starting rank")
    assert_false(s.stalled)

func test_clearing_the_first_adventure_rung_pays_its_documented_share() -> void:
    var s = _state()
    s.record_attempt("t1_adv_a1", Won.new(), s.roster.slice(0, 6))
    assert_eq(s.reputation_points, 5, "A1's share of Adventure 1's 25 RP")

func test_clearing_all_of_tier_one_pays_the_two_hundred_the_doc_promises() -> void:
    # docs/03 §6.1's "Raid tier total, first time: 200" — through the live campaign
    # object, bonus included, with no double payment.
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    for slot in ["e1", "e2", "e3", "e4", "e5"]:
        s.record_attempt("t1_raid_%s" % slot, Won.new(), party)
    assert_eq(s.reputation_points, 200,
        "50 + 10 + 15 + 25 + 35 + 65 is 150, plus the 50 full-tier bonus")
    assert_eq(s.tier_bonus_awarded, [1])

func test_the_full_tier_bonus_pays_once() -> void:
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    for slot in ["e1", "e2", "e3", "e4", "e5"]:
        s.record_attempt("t1_raid_%s" % slot, Won.new(), party)
    var after_first := int(s.reputation_points)
    s.record_attempt("t1_raid_e5", Won.new(), party)
    assert_eq(s.reputation_points, after_first + 13,
        "a re-clear pays the repeat base and no second bonus")
    assert_eq(s.tier_bonus_awarded, [1])

func test_a_wipe_costs_no_reputation() -> void:
    # docs/03 §6.5: "The game is named after wiping ... taxing the fantasy is a
    # design error."
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    s.record_attempt("t1_raid_e1", Won.new(), party)
    var earned := int(s.reputation_points)
    for i in 3:
        s.record_attempt("t1_raid_e2", Lost.new(), party)
    assert_eq(s.reputation_points, earned, "three wipes cost nothing")

func test_rank_advances_and_announces_itself() -> void:
    var s = _state()
    var announced: Array = []
    s.rank_advanced.connect(func(r): announced.append(r))
    s.reputation_points = 119
    s.record_attempt("t1_raid_e1", Won.new(), s.roster.slice(0, 12))
    assert_eq(s.reputation_points, 129)
    assert_eq(s.reputation_rank, Enums.ReputationRank.KNOWN)
    assert_eq(announced, [Enums.ReputationRank.KNOWN],
        "crossing a threshold must fire exactly once")

func test_the_stall_flag_arms_on_the_fifth_failure_and_clears_on_a_first_clear() -> void:
    # docs/03 §8.1 M3: "attempted the same raid encounter 5+ times without clearing
    # it ... Clear the flag on the player's next raid first-clear."
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    for i in 4:
        s.record_attempt("t1_raid_e3", Lost.new(), party)
    assert_false(s.stalled, "four failures is not yet stuck")
    s.record_attempt("t1_raid_e3", Lost.new(), party)
    assert_true(s.stalled, "the fifth failure at one encounter is the trigger")

    # While stuck, adventures pay double — the whole point of the mitigation.
    var before := int(s.reputation_points)
    s.record_attempt("t1_adv_a1", Won.new(), party.slice(0, 6))
    assert_eq(s.reputation_points, before + 10, "A1's 5 RP doubled to 10")

    s.record_attempt("t1_raid_e1", Won.new(), party)
    assert_false(s.stalled, "a raid first clear means the player is moving again")

func test_a_repeat_clear_does_not_clear_the_stall_flag() -> void:
    # The doc says FIRST clear. Re-beating content you have already beaten is not
    # evidence of being unstuck, and would let the flag be reset for free.
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    s.record_attempt("t1_raid_e1", Won.new(), party)
    for i in 5:
        s.record_attempt("t1_raid_e3", Lost.new(), party)
    assert_true(s.stalled)
    s.record_attempt("t1_raid_e1", Won.new(), party)
    assert_true(s.stalled, "a re-clear of Encounter 1 does not count")

func test_failures_spread_across_encounters_do_not_arm_the_flag() -> void:
    # M3 measures being stuck on ONE encounter, which is what "attempted the same
    # raid encounter 5+ times" says.
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    for slot in ["e1", "e2", "e3", "e4", "e5"]:
        s.record_attempt("t1_raid_%s" % slot, Lost.new(), party)
    assert_false(s.stalled, "five failures across five encounters is not a wall")

func test_the_reputation_bookkeeping_survives_a_save_round_trip() -> void:
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    for slot in ["e1", "e2", "e3", "e4", "e5"]:
        s.record_attempt("t1_raid_%s" % slot, Won.new(), party)
    for i in 5:
        s.record_attempt("t1_raid_e5", Lost.new(), party)
    var saved: Dictionary = s.to_dict()

    var t = GameStateScript.new()
    _made.append(t)
    t.set_content(_db)
    var problems: Array = t.from_dict(saved)
    assert_eq(problems.size(), 0, "clean round trip: %s" % str(problems))
    assert_eq(t.reputation_points, s.reputation_points)
    assert_eq(t.reputation_rank, s.reputation_rank)
    assert_eq(t.tier_bonus_awarded, [1],
        "a reloaded save must not be able to re-earn the full-tier bonus")
    assert_eq(t.stalled, s.stalled)
