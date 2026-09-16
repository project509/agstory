extends "res://tests/TestCase.gd"
## Comfort: the Guildhall facility track, Furnishings and Indulgences
## (docs/02 §4.2-§4.3, docs/05 §7.4-§7.6, docs/11 §8).
##
## ✅ CANON gives this system two lines and no numbers — "Manage morale with comfort
## items" and "Upgrade guild facilities < better morale values" — and THREE docs read
## the first one three different ways. docs/11 §8.1 resolves it into two product
## lines, and the tests below hold that resolution in place from both ends: a
## Furnishing must never behave like a spike, and an Indulgence must never behave
## like a floor.
##
## The single most valuable assertion here is
## `test_the_worked_steve_reaches_the_documented_sixty_two`. docs/02 §4.2 and
## docs/11 §8.2 both work the same example from canon's own Steve-at-14, and they
## disagree about the answer (62 vs 64) because docs/11 used a facility number
## docs/02 explicitly says it does not own. That test is the tie-break, and BL-39
## records it.

const Comfort = preload("res://sim/core/Comfort.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")

var _db = null
var _made: Array = []

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []

func after_each() -> void:
    # Screen teardown FIRST, and here rather than at the end of each test: a failed
    # assertion aborts the test body, and a borrowed autoload left holding content
    # breaks every later file in the run.
    _cleanup_screens()
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []


func _r(rarity: int, morale: float, id: String = "r", backstory: int = 0):
    var r = Raider.new()
    r.id = id
    r.display_name = id.capitalize()
    r.class_id = Enums.CharClass.MAGE
    r.rarity = rarity
    r.backstory_offset = backstory
    Morale.set_morale(r, morale)
    return r


func _state(gold: int = 5000):
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Comfort Test")
    s.gold = gold
    return s


# =============================================== the tie-break: doc 02 vs doc 11

func test_the_worked_steve_reaches_the_documented_sixty_two() -> void:
    # docs/02 §4.2, verbatim: "Guildhall L2 (`facility_bonus` +3, §4.3). Steve the
    # Mage sits at 14 ✅ CANON example value; doc 05 §11.2 reads him as a Common, so
    # his `rarity_offset` is −5 ... Baseline before comfort items = 50 − 5 + 3 = 48.
    # A Feather Bed (+6) and a backstory-matched Personal Effect (+8) raise it to 62."
    #
    # docs/11 §8.2 works the SAME example to 64, because it used "Guildhall L2
    # (floor 50)" — its own §8.4 floor column — where docs/02 §4.3 states in terms
    # that the morale column "is **not** a floor value invented here" and follows
    # docs/05 §7.5. docs/05's ladder gives L2 a +3 bonus on a base of 50, so the
    # answer is 48 + 14 = 62. BL-39 records the ruling.
    # docs/02's 48 is 50 - 5 + 3 with NO backstory term, even though the Personal
    # Effect it then adds is "backstory-matched" and docs/05 §7.5 would give such a
    # raider an offset. The doc's arithmetic is what is being asserted, so the
    # fixture matches it: a real Steve carrying a +8 past would settle at 70, which
    # the ceiling permits.
    var steve = _r(Enums.Rarity.COMMON, 14.0, "steve", 0)
    assert_eq(Morale.baseline_of(steve, 1), 48, "50 - 5 + 3, before any furnishing")

    steve.comfort_floor = Comfort.comfort_floor(["feather_bed", "personal_effect"])
    assert_eq(steve.comfort_floor, 14, "Feather Bed +6 and Personal Effect +8")
    assert_eq(Morale.baseline_of(steve, 1), 62,
        "docs/02 §4.2's own worked answer")

func test_the_worked_steve_costs_the_documented_four_hundred_gold() -> void:
    # docs/11 §8.2: "Cost: 140 + 260 = 400 G, or 77% of Tier 1's entire gross income,
    # to permanently rehabilitate one Common Mage." The prices are docs/11's own and
    # survive the floor correction untouched.
    assert_eq(Comfort.furnishing_price("feather_bed")
        + Comfort.furnishing_price("personal_effect"), 400)


# =============================================== docs/11 §8.2 prices, cell by cell

func test_the_furnishing_price_table_reproduces() -> void:
    # docs/02 §4.2's floors with docs/11 §8.2's prices. Both columns are quoted, so
    # neither can drift without this failing.
    var rows := [
        ["straw_cot", "Straw Cot", 3, 40],
        ["trophy_shelf", "Trophy Shelf", 4, 110],
        ["hot_meal", "Hot Meal Standing Order", 5, 90],
        ["feather_bed", "Feather Bed", 6, 140],
        ["personal_effect", "Personal Effect", 8, 260],
        ["hot_meal_all", "Hot Meal Standing Order (guild-wide)", 5, 360],
    ]
    for row in rows:
        var f := Comfort.furnishing(String(row[0]))
        assert_false(f.is_empty(), "%s must exist" % String(row[0]))
        assert_true(String(f["name"]).begins_with(String(row[1]).substr(0, 10)),
            "%s name" % String(row[0]))
        assert_eq(int(f["floor"]), int(row[2]), "%s floor" % String(row[0]))
        assert_eq(int(f["price"]), int(row[3]), "%s price" % String(row[0]))

func test_the_guild_wide_meal_costs_four_times_the_personal_one() -> void:
    # docs/02 §4.2: "Guild-wide variant costs 4×."
    assert_eq(Comfort.furnishing_price("hot_meal_all"),
        Comfort.furnishing_price("hot_meal") * 4)

func test_the_cheap_floor_is_cheap_and_the_last_points_are_expensive() -> void:
    # docs/11 §8.2's stated intent: "Cost per point rises with the size of the
    # effect ... the cheap floor is cheap, the last few points are expensive."
    #
    # It is not monotonic across the whole table and docs/11 knows it: the Trophy
    # Shelf is priced at 27.5 G per point against the Hot Meal's 18.0, because the
    # doc prices in its conditional "+2 more if the raider was present" and quotes
    # "(18.3 if present)" in the same cell. So the claim asserted here is the one the
    # doc is actually making — the ends of the curve, not every neighbouring pair.
    var per_point := func(id: String) -> float:
        var f := Comfort.furnishing(id)
        return float(f["price"]) / float(f["floor"])
    var cheapest: float = per_point.call("straw_cot")
    var dearest: float = per_point.call("personal_effect")
    assert_almost(cheapest, 13.3, 0.1, "docs/11 §8.2's own 13.3")
    assert_almost(dearest, 32.5, 0.1, "docs/11 §8.2's own 32.5")
    for id in Comfort.FURNISHINGS:
        var v: float = per_point.call(String(id))
        assert_true(v >= cheapest - 0.01,
            "%s must not undercut the starter cot" % String(id))
        assert_true(v <= dearest + 0.01,
            "%s must not cost more per point than the dearest rung" % String(id))

func test_the_trophy_shelf_pays_more_when_they_were_there() -> void:
    # docs/02 §4.2: "+2 extra if the raider was present for the kill it commemorates."
    assert_eq(Comfort.comfort_floor(["trophy_shelf"], [], false), 4)
    assert_eq(Comfort.comfort_floor(["trophy_shelf"], [], true), 6)


# =============================================== docs/11 §8.4 facility track

func test_the_facility_track_is_the_documented_one() -> void:
    # docs/02 §4.3's names and slots, docs/11 §8.4's costs.
    var rows := [
        [1, "Leaking Guildhall", 1, 0],
        [2, "Repaired Guildhall", 2, 150],
        [3, "Proper Guildhall", 3, 500],
        [4, "Renowned Guildhall", 4, 1400],
    ]
    for i in rows.size():
        var level: Dictionary = Comfort.LEVELS[i]
        assert_eq(int(level["level"]), int(rows[i][0]))
        assert_eq(String(level["name"]), String(rows[i][1]))
        assert_eq(int(level["slots"]), int(rows[i][2]), "slots at L%d" % int(rows[i][0]))
        assert_eq(int(level["cost"]), int(rows[i][3]), "cost of L%d" % int(rows[i][0]))
    assert_eq(Comfort.LEVELS.size(), 4)

func test_the_track_costs_two_thousand_and_fifty_in_total() -> void:
    # docs/11 §8.4's cumulative column ends at 2,050 G.
    var total := 0
    for level in Comfort.LEVELS:
        total += int(level["cost"])
    assert_eq(total, 2050)

func test_guildhall_levels_map_to_facility_tiers_off_by_one() -> void:
    # docs/02 §4.3, verbatim: "Guildhall L1-L4 here map to facility tiers 0-3 in that
    # order, which is why the derelict starting hall contributes +0." This is the
    # single easiest thing in the system to get wrong.
    assert_eq(Morale.facility_bonus_for(0), 0, "L1, the leaking hall, is free and +0")
    assert_eq(Morale.facility_bonus_for(1), 3, "L2")
    assert_eq(Morale.facility_bonus_for(2), 6, "L3")
    assert_eq(Morale.facility_bonus_for(3), 10, "L4")
    assert_eq(Comfort.slots_for(0), 1)
    assert_eq(Comfort.slots_for(3), 4)
    assert_eq(Comfort.level_name(0), "Leaking Guildhall")
    assert_eq(Comfort.level_name(3), "Renowned Guildhall")

func test_the_building_first_then_the_people_arc_survives_the_correction() -> void:
    # docs/11 §8.4's design contract, and the reason BL-39's correction matters:
    # "the facility track has to stay cheaper per point than Furnishings at the low
    # end ... So the correct opening move is to upgrade the building, and Furnishings
    # are for the specific problem raider. By L4 the ratio inverts, so late-game the
    # answer is per-raider again. That inversion is the intended arc."
    #
    # docs/11 computed it from a +5 first rung. Under docs/05's +3 the numbers move —
    # but the arc has to still hold, or the correction broke the design.
    var roster := 12.0
    var cheapest_furnishing := float(Comfort.furnishing_price("straw_cot")) \
        / float(Comfort.furnishing("straw_cot")["floor"])
    assert_almost(cheapest_furnishing, 13.3, 0.1, "docs/11 §8.2's own 13.3")

    var l2_points := float(Morale.facility_bonus_for(1) - Morale.facility_bonus_for(0))
    var l2_per_point := float(Comfort.upgrade_cost(0)) / (l2_points * roster)
    assert_true(l2_per_point < cheapest_furnishing,
        "the opening move must be the building: %.2f vs %.1f"
            % [l2_per_point, cheapest_furnishing])

    var l4_points := float(Morale.facility_bonus_for(3) - Morale.facility_bonus_for(2))
    var l4_per_point := float(Comfort.upgrade_cost(2)) / (l4_points * roster)
    assert_true(l4_per_point > cheapest_furnishing,
        "and by L4 it must invert to per-raider: %.2f vs %.1f"
            % [l4_per_point, cheapest_furnishing])

func test_the_upgrade_says_which_of_the_two_gates_is_blocking() -> void:
    # docs/11 §8.4: "a level is buyable only when both its rank gate and its price
    # are met, and the Guildhall screen must show which of the two is blocking."
    var rank_blocked := Comfort.upgrade_blocker(0, 99999,
        Enums.ReputationRank.UNKNOWN)
    assert_true(rank_blocked.contains("Known"),
        "rank first, and it must name the rank needed: %s" % rank_blocked)

    var gold_blocked := Comfort.upgrade_blocker(0, 10, Enums.ReputationRank.KNOWN)
    assert_true(gold_blocked.contains("150"),
        "then price, and it must name the price: %s" % gold_blocked)

    assert_eq(Comfort.upgrade_blocker(0, 150, Enums.ReputationRank.KNOWN), "",
        "both gates met is buyable")
    assert_true(Comfort.upgrade_blocker(3, 99999,
        Enums.ReputationRank.LEGENDARY).length() > 0, "and L4 is the end of the track")

func test_the_rank_gates_follow_doc_03s_town_column() -> void:
    # docs/03 §7: upgrade I at Known, II at Established, III at Renowned.
    assert_eq(Comfort.upgrade_rank(0), Enums.ReputationRank.KNOWN)
    assert_eq(Comfort.upgrade_rank(1), Enums.ReputationRank.ESTABLISHED)
    assert_eq(Comfort.upgrade_rank(2), Enums.ReputationRank.RENOWNED)
    assert_eq(Comfort.upgrade_rank(3), -1, "there is no fifth rung to gate")


# =============================================== slots and placement rules

func test_one_furnishing_per_slot_and_the_bed_replaces_the_cot() -> void:
    # docs/02 §4.2 states exactly one slot grouping: the Feather Bed "replaces Straw
    # Cot in same slot". So bedding is one slot and the two cannot both pay.
    assert_eq(Comfort.furnishing_slot("straw_cot"), "bedding")
    assert_eq(Comfort.furnishing_slot("feather_bed"), "bedding")
    assert_eq(Comfort.comfort_floor(["straw_cot", "feather_bed"]), 3,
        "the first in the slot is the one that counts — a purchase must replace")

func test_slots_are_gated_by_the_guildhall() -> void:
    var who = _r(Enums.Rarity.COMMON, 40.0, "bob", 4)
    # One slot at L1: the second furnishing has nowhere to go.
    assert_eq(Comfort.placement_blocker("straw_cot", [], 0, who), "")
    var full := Comfort.placement_blocker("hot_meal", ["straw_cot"], 0, who)
    assert_true(full.contains("no free slot"), full)
    # Two slots at L2 and it fits.
    assert_eq(Comfort.placement_blocker("hot_meal", ["straw_cot"], 1, who), "")

func test_a_personal_effect_needs_a_past_to_belong_to() -> void:
    # docs/02 §4.2: "Only valid for raiders whose backstory tags match — doc 04 owns
    # tags." Tags are not built yet, so this reads docs/05 §7.5's offset, the one
    # backstory hook that exists: non-zero means the raider has a backstory at all.
    var blank = _r(Enums.Rarity.COMMON, 40.0, "nobody", 0)
    var blocked := Comfort.placement_blocker("personal_effect", [], 3, blank)
    assert_true(blocked.contains("past"), blocked)

    var storied = _r(Enums.Rarity.COMMON, 40.0, "somebody", -6)
    assert_eq(Comfort.placement_blocker("personal_effect", [], 3, storied), "",
        "a BAD past is still a past — the rule is about matching, not the sign")

func test_a_guild_wide_order_cannot_be_placed_on_one_person() -> void:
    var who = _r(Enums.Rarity.COMMON, 40.0, "bob", 4)
    var blocked := Comfort.placement_blocker("hot_meal_all", [], 3, who)
    assert_true(blocked.contains("whole guild"), blocked)

func test_the_guild_wide_meal_does_not_stack_with_the_personal_one() -> void:
    # Same slot, and docs/02 calls it a "variant" — so paying twice buys nothing.
    assert_eq(Comfort.comfort_floor(["hot_meal"], ["hot_meal_all"]), 5)
    assert_eq(Comfort.comfort_floor([], ["hot_meal_all"]), 5,
        "and it reaches a raider with nothing of their own")


# =============================================== docs/05 §7.6's ceiling

func test_the_baseline_is_clamped_at_the_documented_eighty() -> void:
    # docs/05 §7.6 states 80 as an arithmetic result: "baseline caps at
    # 50 + 12 + 10 + 8 = 80". docs/02 §4.2 adds a fourth term and says the sum is
    # "clamped to ≤ 80 — doc 05 §7.6's baseline ceiling", so it becomes a real clamp.
    assert_eq(Morale.BASELINE_CEILING, 80)
    var best = _r(Enums.Rarity.LEGENDARY, 50.0, "natsuna", 8)
    assert_eq(Morale.baseline_of(best, 3), 80, "50 + 12 + 10 + 8, with no furnishing")
    best.comfort_floor = 23
    assert_eq(Morale.baseline_of(best, 3), 80, "and furnishings cannot push past it")

func test_rarity_still_orders_the_baseline_at_realistic_investment() -> void:
    # ✅ CANON: "lower tier raiders will be hardest to keep happy." The comfort term
    # must not erase that. At the ceiling everyone ties by definition, so the test
    # that matters is at the investment a real guild actually reaches: Guildhall L2,
    # a Feather Bed and a Personal Effect.
    var common = _r(Enums.Rarity.COMMON, 20.0, "steve", 0)
    var legend = _r(Enums.Rarity.LEGENDARY, 20.0, "natsuna", 0)
    var kit := Comfort.comfort_floor(["feather_bed", "personal_effect"])
    common.comfort_floor = kit
    legend.comfort_floor = kit
    assert_eq(Morale.baseline_of(common, 1), 62)
    assert_eq(Morale.baseline_of(legend, 1), 79)
    assert_true(Morale.baseline_of(common, 1) < Morale.baseline_of(legend, 1),
        "the Common must still be the harder one to keep happy")


# =============================================== the live guild

func test_buying_a_furnishing_charges_gold_and_raises_the_baseline() -> void:
    var s = _state(500)
    var who = s.roster[0]
    var before := Morale.baseline_of(who, s.facility_tier)
    assert_eq(s.buy_furnishing("straw_cot", who.id), "")
    assert_eq(s.gold, 460, "40 G for a Straw Cot")
    assert_eq(Morale.baseline_of(who, s.facility_tier), before + 3)
    assert_eq(s.placed_for(who.id), ["straw_cot"])

func test_a_furnishing_is_a_floor_and_never_a_spike() -> void:
    # This is the whole point of docs/11 §8.1's split. A Furnishing must not move
    # morale at all — it moves where morale is heading.
    var s = _state(500)
    var who = s.roster[0]
    Morale.set_morale(who, 25.0)
    assert_eq(s.buy_furnishing("feather_bed", who.id), "")
    assert_almost(Morale.morale_exact(who), 25.0, 0.0001,
        "buying furniture does not cheer anyone up on the spot")
    assert_eq(Morale.baseline_of(who, s.facility_tier), 51, "50 - 5 + 6")

func test_a_better_bed_replaces_the_cot_and_a_worse_one_is_refused() -> void:
    # docs/02 §4.2's own verb is "replaces".
    var s = _state(500)
    var who = s.roster[0]
    assert_eq(s.buy_furnishing("straw_cot", who.id), "")
    assert_eq(s.buy_furnishing("feather_bed", who.id), "",
        "the bed replaces the cot rather than being refused")
    assert_eq(s.placed_for(who.id), ["feather_bed"], "and the cot is gone")
    assert_eq(who.comfort_floor, 6, "not 9 — one slot, one floor")

    var refused := s.buy_furnishing("straw_cot", who.id)
    assert_true(refused.contains("no worse"), refused)
    assert_eq(s.placed_for(who.id), ["feather_bed"])

func test_an_unaffordable_furnishing_is_refused_without_charging() -> void:
    var s = _state(30)
    var who = s.roster[0]
    var refused := s.buy_furnishing("straw_cot", who.id)
    assert_true(refused.contains("40 G"), refused)
    assert_eq(s.gold, 30, "and nothing was taken")
    assert_eq(s.placed_for(who.id), [])

func test_a_guild_wide_order_reaches_everyone_including_later_recruits() -> void:
    var s = _state(500)
    assert_eq(s.buy_guild_furnishing("hot_meal_all"), "")
    assert_eq(s.gold, 140)
    for r in s.roster:
        assert_eq(r.comfort_floor, 5, "%s eats too" % r.display_name)
    assert_true(s.buy_guild_furnishing("hot_meal_all").contains("already"))

    var newcomer = _r(Enums.Rarity.RARE, 50.0, "latecomer", 0)
    assert_true(s.add_raider(newcomer))
    assert_eq(newcomer.comfort_floor, 5,
        "a recruit walks into the standing order the guild already has")

func test_upgrading_the_guildhall_lifts_the_whole_roster_but_gives_no_spike() -> void:
    # docs/05 §7.5: an upgrade "Raises `baseline`, not a one-off spike".
    var s = _state(500)
    s.reputation_rank = Enums.ReputationRank.KNOWN
    for r in s.roster:
        Morale.set_morale(r, 30.0)
    var before := Morale.baseline_of(s.roster[0], s.facility_tier)

    assert_eq(s.upgrade_guildhall(), "")
    assert_eq(s.facility_tier, 1)
    assert_eq(s.gold, 350, "150 G for the Repaired Guildhall")
    assert_eq(Morale.baseline_of(s.roster[0], s.facility_tier), before + 3)
    for r in s.roster:
        assert_almost(Morale.morale_exact(r), 30.0, 0.0001,
            "a better roof is not a morale event")

func test_an_upgrade_the_rank_forbids_is_refused_without_charging() -> void:
    var s = _state(5000)
    var refused := s.upgrade_guildhall()
    assert_true(refused.contains("Known"), refused)
    assert_eq(s.gold, 5000)
    assert_eq(s.facility_tier, 0)

func test_the_whole_track_can_be_walked() -> void:
    # No dead end: a Renowned guild with the gold must be able to finish the building.
    var s = _state(2500)
    s.reputation_rank = Enums.ReputationRank.RENOWNED
    for i in 3:
        assert_eq(s.upgrade_guildhall(), "", "rung %d" % (i + 1))
    assert_eq(s.facility_tier, Comfort.MAX_TIER)
    assert_eq(s.gold, 2500 - 2050, "docs/11 §8.4's cumulative 2,050 G")
    assert_true(s.upgrade_guildhall().contains("as good as it gets"))
    assert_eq(Comfort.slots_for(s.facility_tier), 4)


# =============================================== Indulgences

func test_an_indulgence_is_a_spike_and_never_a_floor() -> void:
    # The other half of docs/11 §8.1's split, and the mirror of the Furnishing test.
    var s = _state(200)
    var who = s.roster[0]
    Morale.set_morale(who, 20.0)
    var baseline_before := Morale.baseline_of(who, s.facility_tier)

    assert_eq(s.use_indulgence("hot_bath", who.id), "")
    # docs/05 §7.4's +8, scaled by docs/05 §8's POS_MULT for a Common (0.85).
    assert_almost(Morale.morale_exact(who), 20.0 + 8.0 * 0.85, 0.0001)
    assert_eq(Morale.baseline_of(who, s.facility_tier), baseline_before,
        "a bath does not move where they settle")
    assert_eq(s.gold, 180, "20 G for a Hot Bath Token")

func test_the_indulgence_cooldown_is_doc_05s_and_a_blocked_bath_is_not_charged() -> void:
    # docs/05 §7.4: "One comfort item per raider per 2 Day Ticks." Charging for a use
    # the cooldown swallowed would be robbery, so the cooldown is spent before the
    # gold is.
    var s = _state(200)
    var who = s.roster[0]
    assert_eq(s.use_indulgence("hot_bath", who.id), "")
    var gold_after_first: int = s.gold

    var blocked := s.use_indulgence("hot_bath", who.id)
    assert_true(blocked.contains("recently"), blocked)
    assert_eq(s.gold, gold_after_first, "a refused bath costs nothing")

    # Two Day Ticks later it lands again.
    s.rest_in_town()
    s.rest_in_town()
    assert_eq(s.use_indulgence("hot_bath", who.id), "")
    assert_eq(s.gold, gold_after_first - 20)

func test_indulgences_cannot_be_stockpiled_past_the_roster_size() -> void:
    # docs/11 §8.3: "purchases of Indulgences per Day Tick may not exceed roster
    # size — the cooldown already limits use, and the cap stops stockpiling for a
    # burst."
    var s = _state(5000)
    assert_eq(Comfort.indulgence_cap(s.roster.size()), s.roster.size())
    for r in s.roster:
        assert_eq(s.use_indulgence("hot_bath", r.id), "",
            "%s gets one" % r.display_name)
    assert_eq(s.indulgences_today, s.roster.size())

    var extra = _r(Enums.Rarity.RARE, 40.0, "thirteenth", 0)
    assert_true(s.add_raider(extra))
    # The cap grew with the roster, so the newcomer still gets theirs...
    assert_eq(s.use_indulgence("hot_bath", extra.id), "")
    # ...and the day's budget is now spent.
    var over := s.use_indulgence("hot_bath", s.roster[0].id)
    assert_true(over.contains("sold out") or over.contains("recently"), over)

func test_a_new_day_refills_the_indulgence_budget() -> void:
    var s = _state(5000)
    for r in s.roster:
        assert_eq(s.use_indulgence("hot_bath", r.id), "")
    assert_eq(s.indulgences_today, s.roster.size())
    s.advance_day()
    assert_eq(s.indulgences_today, 0)


# =============================================== resting, and BL-34's other half

func test_furnishings_make_a_rest_end_somewhere_better() -> void:
    # This is why BL-34 wanted comfort items: resting settles a raider at their
    # baseline, and a Furnishing moves the baseline. The rest gets LONGER and ends
    # HIGHER — a gold sink that buys a destination, not a shortcut.
    var s = _state(500)
    var who = s.roster[0]
    Morale.set_morale(who, 20.0)
    var days_before := Morale.rest_ticks_for(who, s.facility_tier)

    assert_eq(s.buy_furnishing("feather_bed", who.id), "")
    var days_after := Morale.rest_ticks_for(who, s.facility_tier)
    assert_true(days_after > days_before,
        "six more points to climb: %d days became %d" % [days_before, days_after])

    for i in days_after:
        Morale.drift_raider(who, s.facility_tier, who.backstory_offset)
    assert_true(Morale.is_recovered(who, s.facility_tier))
    assert_almost(Morale.morale_exact(who), 51.0, 0.0001,
        "and they settle at 50 - 5 + 6 rather than 45")


# =============================================== persistence

func test_the_comfort_holdings_survive_a_save_round_trip() -> void:
    var s = _state(3000)
    s.reputation_rank = Enums.ReputationRank.KNOWN
    assert_eq(s.upgrade_guildhall(), "")
    assert_eq(s.buy_guild_furnishing("hot_meal_all"), "")
    var who = s.roster[0]
    assert_eq(s.buy_furnishing("feather_bed", who.id), "")
    var expected_floor: int = who.comfort_floor
    assert_eq(expected_floor, 11, "Feather Bed 6 + guild-wide meal 5")

    var saved: Dictionary = s.to_dict()
    var t = GameStateScript.new()
    _made.append(t)
    t.set_content(_db)
    var problems: Array = t.from_dict(saved)
    assert_eq(problems.size(), 0, "clean round trip: %s" % str(problems))

    assert_eq(t.facility_tier, 1)
    assert_eq(t.guild_furnishings, ["hot_meal_all"])
    assert_eq(t.placed_for(who.id), ["feather_bed"])
    assert_eq(t.roster[0].comfort_floor, expected_floor,
        "and the derived floor is rebuilt from the holdings, not trusted")

func test_the_derived_floor_is_rebuilt_rather_than_believed() -> void:
    # The saved per-raider number is a cache. A save that disagrees with the holdings
    # must lose to the holdings, or a hand-edited or half-migrated save could hand a
    # raider a floor nobody paid for.
    var s = _state(500)
    var who = s.roster[0]
    assert_eq(s.buy_furnishing("straw_cot", who.id), "")
    var saved: Dictionary = s.to_dict()
    var raiders: Array = saved["roster"]
    for entry in raiders:
        if String(entry["id"]) == who.id:
            entry["comfort_floor"] = 999

    var t = GameStateScript.new()
    _made.append(t)
    t.set_content(_db)
    t.from_dict(saved)
    assert_eq(t.roster[0].comfort_floor, 3,
        "the Straw Cot they actually own is worth 3, whatever the file claims")


# =============================================== the Facilities tab (S03)

const Router = preload("res://game/core/ScreenRouter.gd")
const FacilitiesView = preload("res://game/screens/Facilities.gd")
const GuildhallScript = preload("res://game/screens/Guildhall.gd")

## The screen tests need a live `/root/GameState`, which under `--script` is shared
## with every other test file. Borrowing it means putting it back exactly as found,
## `content` included — a GameState with content builds a starting roster on
## `new_game()` and one without cannot.
var _borrowed = null
var _borrowed_content = null
var _mounted: Array = []


func _root_node() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _live_state(guild: String, gold: int):
    var root := _root_node()
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
    st.reset()
    st.set_content(_db)
    st.new_game(guild)
    st.gold = gold
    return st


func _facilities() -> Control:
    var view := FacilitiesView.new()
    _root_node().add_child(view)
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


## Every button in a subtree, so a test can assert what is clickable.
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


func _cleanup_screens() -> void:
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


func test_the_guildhall_facilities_tab_is_no_longer_a_promise() -> void:
    # It shipped disabled with "Facility upgrades are not in this version yet."
    for t in GuildhallScript.TABS:
        if String(t["id"]) == "facilities":
            assert_eq(String(t["reason"]), "",
                "the Facilities tab must be live now")

func test_the_facilities_tab_prints_both_level_cards_and_the_delta() -> void:
    # docs/02 §4.5: "Current level card, next level card, cost, delta table,
    # exterior before/after thumbnails." The art is not built, so docs/02 §9's own
    # "Visible change" wording stands in — the pitch the artist will draw.
    var st = _live_state("Facilities Test", 1000)
    var view := _facilities()
    var printed := _printed(view)

    assert_true(printed.contains("Leaking Guildhall"), "the current level")
    assert_true(printed.contains("Boarded windows"),
        "and what it looks like: %s" % printed)
    assert_true(printed.contains("Repaired Guildhall"), "the next level")
    assert_true(printed.contains("150 G"), "its cost")
    assert_true(printed.contains("+3 morale baseline"),
        "and the delta, which is what the money buys")
    _cleanup_screens()

func test_the_upgrade_button_says_which_gate_is_blocking() -> void:
    # docs/11 §8.4: "the Guildhall screen must show which of the two is blocking."
    # A new guild is Unknown and rich, so it must be the RANK that is named.
    var st = _live_state("Gate Test", 9999)
    var view := _facilities()
    var printed := _printed(view)
    assert_true(printed.contains("Reach Known"),
        "rank is the blocker here, and it must be named: %s" % printed)
    var btn = _button_named(view, "Commission")
    assert_true(btn != null, "the button must exist even when it cannot be pressed")
    assert_true(btn.disabled, "and be disabled rather than hidden")
    _cleanup_screens()

func test_a_poor_but_famous_guild_is_told_the_price_instead() -> void:
    var st = _live_state("Purse Test", 20)
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var view := _facilities()
    var printed := _printed(view)
    assert_true(printed.contains("Costs 150 G"),
        "with the rank gate met, price is the blocker: %s" % printed)
    _cleanup_screens()

func test_commissioning_the_work_upgrades_the_hall_on_screen() -> void:
    var st = _live_state("Build Test", 1000)
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var view := _facilities()
    var btn = _button_named(view, "Commission")
    assert_false(btn.disabled, "both gates met")
    btn.pressed.emit()

    assert_eq(st.facility_tier, 1)
    assert_eq(st.gold, 850)
    var printed := _printed(view)
    assert_true(printed.contains("Repaired Guildhall"),
        "the card now shows the hall they bought")
    assert_true(printed.contains("Proper Guildhall"), "and the next rung")
    _cleanup_screens()

func test_the_arithmetic_strip_shows_every_term_of_the_baseline() -> void:
    # docs/02 §4.5, verbatim: "Shows `50 + rarity_offset + facility_bonus + items =
    # baseline` as an arithmetic strip, per doc 05 §7.5."
    var st = _live_state("Strip Test", 1000)
    var view := _facilities()
    var printed := _printed(view)
    assert_true(printed.contains("50 base"), "the base")
    assert_true(printed.contains("-5 Common"), "the rarity term: %s" % printed)
    assert_true(printed.contains("+0 Guildhall"), "the facility term")
    assert_true(printed.contains("+0 furnishings"), "the comfort term")
    assert_true(printed.contains("45 baseline"), "and the sum: %s" % printed)
    _cleanup_screens()

func test_buying_a_furnishing_from_the_screen_moves_the_strip() -> void:
    var st = _live_state("Buy Test", 1000)
    var view := _facilities()
    var btn = _button_named(view, "Straw Cot")
    assert_true(btn != null, "the catalogue must be on the screen")
    assert_false(btn.disabled)
    btn.pressed.emit()

    assert_eq(st.gold, 960)
    var printed := _printed(view)
    assert_true(printed.contains("+3 furnishings"),
        "the strip must show what was bought: %s" % printed)
    assert_true(printed.contains("Straw Cot"), "and the slot must show it")
    _cleanup_screens()

func test_every_furnishing_is_offered_with_its_price() -> void:
    # No hidden catalogue: a player must be able to see what money can do.
    var st = _live_state("Catalogue Test", 9999)
    st.reputation_rank = Enums.ReputationRank.RENOWNED
    var view := _facilities()
    var printed := _printed(view)
    for id in Comfort.FURNISHINGS:
        var f := Comfort.furnishing(String(id))
        assert_true(printed.contains(String(f["name"])),
            "%s must be on the screen" % String(f["name"]))
        assert_true(printed.contains("%d G" % int(f["price"])),
            "%s must show its price" % String(f["name"]))
    for id in Comfort.INDULGENCES:
        assert_true(printed.contains(String(Comfort.indulgence(String(id))["name"])))
    _cleanup_screens()

func test_the_screen_warns_when_more_spending_would_do_nothing() -> void:
    # docs/05 §7.6's ceiling. A purchase that silently achieves nothing is the worst
    # possible outcome for a 260 G item.
    var st = _live_state("Ceiling Test", 9999)
    st.facility_tier = 3
    for r in st.roster:
        r.rarity = Enums.Rarity.LEGENDARY
        r.backstory_offset = 8
        r.comfort_floor = 23
    var view := _facilities()
    var printed := _printed(view)
    assert_true(printed.contains("Capped at 80"),
        "the strip must admit the cap: %s" % printed)
    assert_true(printed.contains("does nothing"),
        "and say how much of the spending is wasted")
    _cleanup_screens()

func test_a_finished_guildhall_is_not_a_dead_end() -> void:
    var st = _live_state("Finished Test", 100)
    st.facility_tier = Comfort.MAX_TIER
    var view := _facilities()
    var printed := _printed(view)
    assert_true(printed.contains("Renowned Guildhall"))
    assert_true(printed.contains("nothing left to build"),
        "it must say so rather than showing an empty card: %s" % printed)
    assert_true(_button_named(view, "Commission") == null,
        "and offer no button to press")
    _cleanup_screens()

func test_the_quarters_panel_survives_an_empty_roster() -> void:
    var st = _live_state("Empty Test", 100)
    st.roster = []
    var view := _facilities()
    var printed := _printed(view)
    assert_true(printed.contains("Nobody lives here yet"), printed)
    _cleanup_screens()


# ---------------------------------------------------------------- reset is total

## The bug this was written for: `facility_tier`, `_trophy_witnesses` and
## `_pending_departures` were added to the state and to the save shape but not to
## `reset()`, so a second "New Guild" in one session inherited the first guild's
## Guildhall. It surfaced as an unrelated screen test reading a +3 morale baseline
## out of a brand-new guild.
##
## Asserted against the SAVE SHAPE rather than field by field, so a field added
## later is covered without anyone remembering to come back here: whatever
## `to_dict()` thinks is worth persisting, `reset()` has to clear.
func test_reset_returns_every_persisted_field_to_its_starting_value() -> void:
    var fresh = GameStateScript.new()
    _made.append(fresh)
    fresh.reset()
    var pristine: Dictionary = fresh.to_dict()

    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Dirty Guild")
    # Dirty everything a campaign can dirty.
    s.gold = 4242
    s.day = 17
    s.reputation_points = 900
    s.reputation_rank = Enums.ReputationRank.ESTABLISHED
    s.facility_tier = 3
    s.crisis_strikes = 2
    s.stalled = true
    s.onboarding_complete = true
    s.tier_bonus_awarded = [1, 2]
    s.guild_furnishings = ["hot_meal_all"]
    s.furnishings = {"someone": ["straw_cot"]}
    s.cleared = {"t1_raid_e1": 3}
    s.attempts = {"t1_raid_e1": 9}
    s.flags = {"blacksmith": true}
    s.indulgences_today = 5

    s.reset()
    var after: Dictionary = s.to_dict()
    for key in pristine:
        assert_eq(after[key], pristine[key],
            "reset() left '%s' dirty" % String(key))
    assert_eq(s.facility_tier, 0,
        "a new guild starts in the leaking hall, whatever the last one built")
    assert_eq(s.indulgences_today, 0)
    assert_false(s.active, "and it is not a live campaign until new_game()")

func test_a_second_new_guild_does_not_inherit_the_first_ones_building() -> void:
    # The player-facing shape of the same bug, end to end.
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("First Guild")
    s.gold = 1000
    s.reputation_rank = Enums.ReputationRank.KNOWN
    assert_eq(s.upgrade_guildhall(), "")
    assert_eq(s.facility_tier, 1)

    s.reset()
    s.new_game("Second Guild")
    assert_eq(s.facility_tier, 0)
    assert_eq(s.reputation_rank, Enums.ReputationRank.UNKNOWN)
    for r in s.roster:
        assert_eq(r.comfort_floor, 0,
            "%s did not inherit the last guild's furniture" % r.display_name)
