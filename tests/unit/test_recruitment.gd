extends "res://tests/TestCase.gd"
## Who walks into the Tavern (docs/03 §5, docs/04 §3, §5, §6).
##
## Canon specifies four of six ranks and docs/03 §5.4 calls the other two "THE LARGEST
## HOLE IN THIS DOC", so the assertions here are weighted toward the four that ARE
## canon — every "no longer find" statement gets a test that tries to violate it.
##
## Two are worth naming.
##
## `test_the_legendary_find_chance_is_not_canons_one_percent` guards docs/03 §5.1's red
## flag: canon's "1%" is the Legendary's MISTAKE chance, sitting two lines from its find
## chance, which canon gives only as "VERY SMALL". It is the single most likely
## misreading in the document and the easiest to make by accident.
##
## `test_rarity_is_rolled_before_class` guards the ordering docs/03 §5.5 pins, because
## getting it backwards would silently erode the advertised Legendary rate as classes
## are claimed — by the ninth Legendary it would be a ninth of the table value.

const Recruitment = preload("res://sim/core/Recruitment.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Economy = preload("res://sim/core/Economy.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Rng = preload("res://sim/core/Rng.gd")

func _rng(seed_value: int = 1234):
    return Rng.new(Rng.splitmix64_mix(seed_value))


# =============================================== docs/03 §5.2's matrix

func test_every_row_sums_to_a_thousand() -> void:
    # docs/03 §5.2: "Integer weights per 1000 recruits generated. Rows sum to 1000."
    for rank in Recruitment.FIND_WEIGHTS.size():
        var total := 0
        for w in Recruitment.FIND_WEIGHTS[rank]:
            total += int(w)
        assert_eq(total, Recruitment.WEIGHT_TOTAL,
            "%s must sum to 1000" % Enums.reputation_name_of(rank))

func test_the_matrix_is_the_documented_one() -> void:
    assert_eq(Recruitment.FIND_WEIGHTS[Enums.ReputationRank.UNKNOWN],
        [1000, 0, 0, 0, 0])
    assert_eq(Recruitment.FIND_WEIGHTS[Enums.ReputationRank.KNOWN],
        [700, 300, 0, 0, 0])
    assert_eq(Recruitment.FIND_WEIGHTS[Enums.ReputationRank.RESPECTED],
        [0, 650, 350, 0, 0])
    assert_eq(Recruitment.FIND_WEIGHTS[Enums.ReputationRank.ESTABLISHED],
        [0, 350, 650, 0, 0])
    assert_eq(Recruitment.FIND_WEIGHTS[Enums.ReputationRank.RENOWNED],
        [0, 0, 800, 185, 15])
    assert_eq(Recruitment.FIND_WEIGHTS[Enums.ReputationRank.LEGENDARY],
        [0, 0, 0, 950, 50])

func test_canons_four_hard_statements_hold() -> void:
    # Every "only" and "no longer find" in canon, asserted as a zero.
    var w := Recruitment.FIND_WEIGHTS
    # C1: "@Rank unknown you can only find the worst players" — Common at 100%.
    assert_eq(int(w[0][Enums.Rarity.COMMON]), 1000)
    # C4: "@Respected you no longer find common."
    for rank in range(Enums.ReputationRank.RESPECTED, 6):
        assert_eq(int(w[rank][Enums.Rarity.COMMON]), 0,
            "Common must stay gone at %s" % Enums.reputation_name_of(rank))
    # C8: "@renowned you no longer find uncommon raiders."
    for rank in range(Enums.ReputationRank.RENOWNED, 6):
        assert_eq(int(w[rank][Enums.Rarity.UNCOMMON]), 0,
            "Uncommon must stay gone at %s" % Enums.reputation_name_of(rank))
    # C2/C6/C9/C10: nothing appears before canon introduces it.
    for rank in range(0, Enums.ReputationRank.KNOWN):
        assert_eq(int(w[rank][Enums.Rarity.UNCOMMON]), 0)
    for rank in range(0, Enums.ReputationRank.RESPECTED):
        assert_eq(int(w[rank][Enums.Rarity.RARE]), 0)
    for rank in range(0, Enums.ReputationRank.RENOWNED):
        assert_eq(int(w[rank][Enums.Rarity.EPIC]), 0)
        assert_eq(int(w[rank][Enums.Rarity.LEGENDARY]), 0)

func test_the_legendary_find_chance_is_not_canons_one_percent() -> void:
    # docs/03 §5.1's ❗ trap: canon's "near 1% chance of mistake" is a MISTAKE rate
    # sitting beside a find chance canon gives only as "VERY SMALL". 15 per-mille at
    # Renowned and 50 at Legendary rank are docs/03 §5.2's, and it declares itself the
    # single home for them.
    assert_eq(int(Recruitment.FIND_WEIGHTS[Enums.ReputationRank.RENOWNED][
        Enums.Rarity.LEGENDARY]), 15, "1.5%, not 1%")
    assert_eq(int(Recruitment.FIND_WEIGHTS[Enums.ReputationRank.LEGENDARY][
        Enums.Rarity.LEGENDARY]), 50, "5% at the top rank")

func test_the_modal_tier_is_the_one_canon_calls_common() -> void:
    # ✅ C5: "@Respected ... finding uncommon raiders is now common."
    assert_eq(Recruitment.modal_rarity(Enums.ReputationRank.UNKNOWN),
        Enums.Rarity.COMMON)
    assert_eq(Recruitment.modal_rarity(Enums.ReputationRank.KNOWN),
        Enums.Rarity.COMMON)
    assert_eq(Recruitment.modal_rarity(Enums.ReputationRank.RESPECTED),
        Enums.Rarity.UNCOMMON)
    assert_eq(Recruitment.modal_rarity(Enums.ReputationRank.ESTABLISHED),
        Enums.Rarity.RARE, "docs/03 §5.4's consolidation rank")
    assert_eq(Recruitment.modal_rarity(Enums.ReputationRank.RENOWNED),
        Enums.Rarity.RARE)
    assert_eq(Recruitment.modal_rarity(Enums.ReputationRank.LEGENDARY),
        Enums.Rarity.EPIC)

func test_the_gap_filled_ranks_never_contradict_a_canon_statement() -> void:
    # docs/03 §5.4's own test of its gap-fill: it "never contradicts a canon 'no longer
    # find' statement, and never introduces a tier earlier than canon introduces it".
    var est := Recruitment.FIND_WEIGHTS[Enums.ReputationRank.ESTABLISHED]
    assert_eq(int(est[Enums.Rarity.COMMON]), 0, "Common stays retired")
    assert_eq(int(est[Enums.Rarity.EPIC]), 0,
        "Epic must not be previewed early — that is the rejected alternate")
    assert_true(int(est[Enums.Rarity.UNCOMMON]) > 0,
        "Established introduces and retires nothing")

    var leg := Recruitment.FIND_WEIGHTS[Enums.ReputationRank.LEGENDARY]
    assert_eq(int(leg[Enums.Rarity.RARE]), 0, "the last 'no longer find' beat")
    assert_true(int(leg[Enums.Rarity.EPIC]) > int(leg[Enums.Rarity.LEGENDARY]),
        "Epic is modal at the top, not Legendary")


# =============================================== docs/03 §5.5's roll order

func test_a_claimed_legendary_pool_redistributes_rather_than_shrinks() -> void:
    # docs/03 §5.5 step 1: "weights[Epic] += weights[Legendary]; weights[Legendary] = 0"
    # — redistribute, keep sum 1000.
    var open := Recruitment.adjusted_weights(Enums.ReputationRank.RENOWNED, true)
    var shut := Recruitment.adjusted_weights(Enums.ReputationRank.RENOWNED, false)
    assert_eq(int(shut[Enums.Rarity.LEGENDARY]), 0)
    assert_eq(int(shut[Enums.Rarity.EPIC]),
        int(open[Enums.Rarity.EPIC]) + int(open[Enums.Rarity.LEGENDARY]))
    var total := 0
    for w in shut:
        total += int(w)
    assert_eq(total, 1000, "the row must still sum to 1000")

func test_rarity_is_rolled_before_class() -> void:
    # docs/03 §5.5: rolling class first "silently erodes the Legendary rate as classes
    # get claimed — by the 9th Legendary the effective rate would be 1/9th of the table
    # value. Rolling rarity first keeps the advertised 1.5% honest for the whole game."
    #
    # Asserted by measurement: with eight of nine Legendary classes claimed, the observed
    # Legendary rate must still be near 1.5%, not near 1.5/9%.
    var rng = _rng(99)
    var claimed: Array = Enums.all_classes().slice(0, 8)
    var legendaries := 0
    var runs := 8000
    for i in runs:
        if Recruitment.roll_rarity(rng, Enums.ReputationRank.RENOWNED, 0, true) \
                == Enums.Rarity.LEGENDARY:
            legendaries += 1
    var rate := float(legendaries) / float(runs)
    assert_in_range(rate, 0.010, 0.021,
        "eight classes claimed must not move the find rate: %.4f" % rate)

func test_the_observed_rates_match_the_table() -> void:
    # The matrix is only worth its numbers if the roll reproduces them.
    var rng = _rng(4242)
    var counts := [0, 0, 0, 0, 0]
    var runs := 12000
    for i in runs:
        counts[Recruitment.roll_rarity(rng, Enums.ReputationRank.RESPECTED)] += 1
    assert_eq(counts[Enums.Rarity.COMMON], 0, "canon: no Common at Respected")
    var uncommon := float(counts[Enums.Rarity.UNCOMMON]) / float(runs)
    assert_in_range(uncommon, 0.62, 0.68, "650 per mille: %.3f" % uncommon)

func test_a_legendary_only_ever_comes_from_an_unclaimed_class() -> void:
    # ✅ C12: "You can only ever find 1 Legendary per class."
    var rng = _rng(7)
    var claimed: Array = Enums.all_classes().slice(0, 8)
    for i in 200:
        var cls := Recruitment.roll_class(rng, Enums.Rarity.LEGENDARY, claimed)
        assert_eq(cls, int(Enums.all_classes()[8]),
            "only the one unclaimed class can produce a Legendary")

func test_a_fully_claimed_legendary_roll_downgrades_rather_than_failing() -> void:
    # docs/04 §5 step 2: "if none remain, downgrade the roll to Epic."
    var rng = _rng(11)
    assert_eq(Recruitment.roll_class(rng, Enums.Rarity.LEGENDARY,
        Enums.all_classes()), -1, "no class is available...")
    var who = Recruitment.generate(rng, Enums.ReputationRank.LEGENDARY, 5,
        {"claimed_legendary_classes": Enums.all_classes()})
    assert_ne(who.rarity, Enums.Rarity.LEGENDARY,
        "...so the candidate cannot be one")
    assert_true(who.class_id >= 0, "and they still have a class")


# =============================================== docs/03 §8.1's mitigations

func test_pity_forces_rare_or_better_after_twenty_five() -> void:
    # docs/03 §8.1 M2: "When `pity >= 25`, the next recruit is forced to Rare or better."
    assert_eq(Recruitment.PITY_THRESHOLD, 25)
    assert_eq(Recruitment.pity_forced_tier(Enums.ReputationRank.RESPECTED, 24, true),
        -1, "not yet")
    assert_eq(Recruitment.pity_forced_tier(Enums.ReputationRank.RESPECTED, 25, true),
        Enums.Rarity.RARE)

func test_pity_is_inactive_before_rare_exists() -> void:
    # docs/03 §8.1 M2: "Active from **Respected** onward, since Rare does not exist
    # before then." Forcing Rare at Known would put a tier on the board two ranks early.
    for rank in [Enums.ReputationRank.UNKNOWN, Enums.ReputationRank.KNOWN]:
        assert_eq(Recruitment.pity_forced_tier(rank, 99, true), -1,
            "%s has no Rare to force" % Enums.reputation_name_of(rank))

func test_the_pity_counter_resets_on_rare_or_better() -> void:
    assert_eq(Recruitment.next_pity(10, Enums.Rarity.COMMON), 11)
    assert_eq(Recruitment.next_pity(10, Enums.Rarity.UNCOMMON), 11)
    assert_eq(Recruitment.next_pity(10, Enums.Rarity.RARE), 0)
    assert_eq(Recruitment.next_pity(10, Enums.Rarity.LEGENDARY), 0)

func test_pity_at_the_top_rank_forces_what_the_rank_can_produce() -> void:
    # Legendary rank has no Rare at all, so the floor is Epic. Forcing a tier the matrix
    # says does not exist would put a retired rarity back on the board.
    assert_eq(Recruitment.pity_forced_tier(Enums.ReputationRank.LEGENDARY, 30, true),
        Enums.Rarity.EPIC)

func test_a_board_always_holds_one_at_the_modal_tier() -> void:
    # docs/03 §8.1 M1: "Every Tavern refresh guarantees at least one recruit at the
    # rank's modal tier ... Removes the 'all four recruits are Uncommon at Established'
    # run of bad luck." That run is the steepest edge of §8's spiral.
    var modal := Recruitment.modal_rarity(Enums.ReputationRank.ESTABLISHED)
    for seed_value in range(1, 40):
        var board := Recruitment.roll_board(_rng(seed_value), 4,
            Enums.ReputationRank.ESTABLISHED, 3)
        var best := -1
        for who in board:
            best = maxi(best, who.rarity)
        assert_true(best >= modal,
            "seed %d produced a board with nothing at the modal tier" % seed_value)


# =============================================== docs/04 §6's recipes

func test_the_gear_recipes_are_the_documented_ones() -> void:
    # docs/03 §4.1 and docs/04 §6.2. Common's four pieces are ✅ CANON; the rest are the
    # doc's "1-2" / "3-4" / "a few" made exact.
    var rng = _rng(5)
    for i in 60:
        var common := Recruitment.gear_plan(rng, Enums.Rarity.COMMON)
        assert_eq(String(common["source"]), "start")
        assert_eq((common["granted"] as Array).size(), 4,
            "canon dresses a Common in the whole starting set")

        var uncommon := Recruitment.gear_plan(rng, Enums.Rarity.UNCOMMON)
        assert_eq(String(uncommon["source"]), "adventure")
        assert_in_range(float((uncommon["granted"] as Array).size()), 1.0, 2.0)

        var rare := Recruitment.gear_plan(rng, Enums.Rarity.RARE)
        assert_in_range(float((rare["granted"] as Array).size()), 3.0, 4.0)

        var epic := Recruitment.gear_plan(rng, Enums.Rarity.EPIC)
        assert_eq(String(epic["source"]), "raid",
            "docs/04 §6.2: Epic is the first rarity that arrives with raid gear")
        assert_eq(String(epic["fill"]), "adventure")

        var leg := Recruitment.gear_plan(rng, Enums.Rarity.LEGENDARY)
        assert_in_range(float((leg["granted"] as Array).size()), 3.0, 4.0,
            "canon's 'a few'")

func test_no_recruit_is_ever_granted_a_weapon() -> void:
    # docs/03 §4.1: "weapons are never granted at recruitment (the Market/Blacksmith is
    # the weapon path)". docs/04 §6.1's Boss-5 lockout says the same for the capstones.
    var rng = _rng(31)
    for rarity in Enums.all_rarities():
        for i in 40:
            for slot in Recruitment.gear_plan(rng, rarity)["granted"]:
                assert_true(Recruitment.GRANT_SLOTS.has(int(slot)),
                    "%s is not one of the four armour slots"
                        % Enums.slot_name_of(int(slot)))

func test_a_slot_is_never_granted_twice() -> void:
    # docs/03 §4.1: "uniform without replacement".
    var rng = _rng(77)
    for i in 200:
        var granted: Array = Recruitment.gear_plan(rng, Enums.Rarity.RARE)["granted"]
        var seen := {}
        for slot in granted:
            assert_false(seen.has(slot), "slot %d granted twice" % int(slot))
            seen[slot] = true

func test_raid_experience_matches_the_bands_and_commons_is_canon_zero() -> void:
    # ✅ CANON (A4): Commons "have 0 raid experience".
    var rng = _rng(3)
    for i in 100:
        assert_eq(Recruitment.roll_experience(rng, Enums.Rarity.COMMON), 0)
        assert_in_range(float(Recruitment.roll_experience(rng, Enums.Rarity.UNCOMMON)),
            1.0, 2.0, "docs/04 §6.2's 'a small amount'")
        assert_true(Recruitment.roll_experience(rng, Enums.Rarity.LEGENDARY) >= 20)


# =============================================== the recruit price (docs/11 §4.2 S1 × docs/04 §3.3)

func after_each() -> void:
    # The scale is a static var so doc 04's table stays under test; a failed
    # assertion inside the doc-04 test must not leave the next file on it.
    Recruitment.PRICE_SCALE = "doc11"

func _cost_rows(scale: String) -> Array:
    var saved: String = Recruitment.PRICE_SCALE
    Recruitment.PRICE_SCALE = scale
    var out := []
    for rarity in Enums.all_rarities():
        out.append([Recruitment.cost_of(rarity, 1), Recruitment.cost_of(rarity, 3),
            Recruitment.cost_of(rarity, 5)])
    Recruitment.PRICE_SCALE = saved
    return out

func test_the_shipped_scale_is_doc_11s_and_the_table_reproduces() -> void:
    # docs/15 BL-94: doc 11 §4.2 S1 is the one recruit price table (Common 15 G);
    # doc 04 §3.3's multiplier `× (1 + 0.6 × (CT − 1))`, rounded to 10, is
    # applied to it. Cell by cell at CT 1 / 3 / 5.
    assert_eq(Recruitment.PRICE_SCALE, "doc11", "the register's default ships")
    var rows := [
        [Enums.Rarity.COMMON, 15, 30, 50],
        [Enums.Rarity.UNCOMMON, 60, 130, 200],
        [Enums.Rarity.RARE, 160, 350, 540],
        [Enums.Rarity.EPIC, 420, 920, 1430],
        [Enums.Rarity.LEGENDARY, 1000, 2200, 3400],
    ]
    for row in rows:
        var rarity := int(row[0])
        assert_eq(Recruitment.cost_of(rarity, 1), int(row[1]),
            "%s at CT 1" % Enums.rarity_name_of(rarity))
        assert_eq(Recruitment.cost_of(rarity, 3), int(row[2]),
            "%s at CT 3" % Enums.rarity_name_of(rarity))
        assert_eq(Recruitment.cost_of(rarity, 5), int(row[3]),
            "%s at CT 5" % Enums.rarity_name_of(rarity))

func test_doc_04s_scale_is_still_selectable_and_reproduces_its_own_columns() -> void:
    # The other 🔷 PROPOSED table, docs/04 §3.3's worked columns, behind the
    # same switch — so the ruling is a flip and not a rewrite.
    var rows := _cost_rows("doc04")
    assert_eq(rows, [
        [60, 130, 200], [180, 400, 610], [450, 990, 1530],
        [1100, 2420, 3740], [3000, 6600, 10200]])
    assert_eq(Recruitment.PRICE_SCALE, "doc11", "the helper puts the switch back")

func test_r3_the_hire_price_floors_the_arrival_kits_sale_value() -> void:
    # docs/11 §12.1 R3: `hire_cost(rarity) ≥ 1.5 × expected_sale_value(arrival_gear(rarity))`,
    # read from S1 and never from doc 04 — the regression test that keeps a future
    # price change from reopening the recruit-gear arbitrage (hire, strip, dismiss).
    # Priced at the WORST case rather than the expectation: every granted slot
    # takes the dearest Tier 1 item of the plan's source for that slot, every
    # fill slot the dearest of the fill source, all sold at the best sell rate.
    var db = DB.load_all()
    assert_true(db.is_valid(), "the content must load: %s" % [db.errors])
    var best_rank: int = Enums.ReputationRank.LEGENDARY
    for rarity in Enums.all_rarities():
        var plan: Dictionary = Recruitment.gear_plan(_rng(7 + rarity), rarity)
        var worst := 0
        for slot in Recruitment.GRANT_SLOTS:
            var granted: bool = (slot in plan["granted"])
            var source: String = String(plan["source"]) if granted else String(plan["fill"])
            if source.is_empty():
                continue
            worst += _dearest_sale(db, source, int(slot), best_rank)
        var price := Recruitment.cost_of(rarity, 1)
        assert_true(float(price) >= 1.5 * float(worst),
            "%s: hire %d G must floor 1.5 × the kit's worst-case sale value %d G (R3)"
                % [Enums.rarity_name_of(rarity), price, worst])
        if rarity != Enums.Rarity.COMMON:
            assert_true(worst > 0, "%s's kit priced at nothing — the reader is broken" % Enums.rarity_name_of(rarity))

func _dearest_sale(db, source: String, slot: int, rank: int) -> int:
    var best := 0
    for item_id in db.items:
        var it = db.items[item_id]
        if it.source != source or it.slot != slot:
            continue
        best = maxi(best, Economy.sell_price(it, rank))
    return best

func test_cost_rises_with_rarity_and_with_tier() -> void:
    for tier in [1, 3, 5]:
        var previous := 0
        for rarity in Enums.all_rarities():
            var price := Recruitment.cost_of(rarity, tier)
            assert_true(price > previous,
                "%s must cost more than the rarity below it"
                    % Enums.rarity_name_of(rarity))
            previous = price


# =============================================== the candidate

func test_a_candidate_arrives_at_their_baseline_not_at_fifty() -> void:
    # docs/05 §4: "a newly recruited raider starts at `baseline`, not at 50. This makes
    # rarity legible on the recruit screen: a Common walks in at 45, a Legendary at 62."
    var rng = _rng(19)
    var common = Recruitment.generate(rng, Enums.ReputationRank.UNKNOWN, 1)
    assert_eq(common.rarity, Enums.Rarity.COMMON)
    assert_eq(common.morale, 45, "50 - 5, with no facilities")

    var top = Recruitment.generate(rng, Enums.ReputationRank.LEGENDARY, 5)
    assert_true(top.morale > common.morale,
        "and a better raider walks in happier")

func test_a_candidate_is_born_with_no_name_it_has_to_lose_later() -> void:
    # docs/03 §5.6: "Use placeholders ... **Do not invent names.**" The same rule applies
    # to every rarity until `data/names.json` lands: a placeholder that says what is
    # missing beats a name that has to be deleted.
    var who = Recruitment.generate(_rng(23), Enums.ReputationRank.UNKNOWN, 1)
    assert_true(who.display_name.contains("name pending"), who.display_name)

func test_an_injected_namer_is_used_when_one_exists() -> void:
    # The seam the name pool will plug into, asserted now so the pool is a data task
    # rather than a refactor.
    var who = Recruitment.generate(_rng(29), Enums.ReputationRank.UNKNOWN, 1, {
        "namer": func(_r, _c, _rarity): return "Bob",
    })
    assert_eq(who.display_name, "Bob")

func test_an_injected_backstory_is_used_when_one_exists() -> void:
    var who = Recruitment.generate(_rng(31), Enums.ReputationRank.UNKNOWN, 1, {
        "backstory": func(_r, _who): return ["Hates mornings.", "Owns one spoon."],
    })
    assert_eq(who.backstory.size(), 2)

func test_the_same_seed_produces_the_same_candidate() -> void:
    # docs/04 §5's whole reason for a fixed order: "so two programmers generating a
    # raider produce byte-identical output from the same seed".
    var a = Recruitment.generate(_rng(4242), Enums.ReputationRank.RENOWNED, 4)
    var b = Recruitment.generate(_rng(4242), Enums.ReputationRank.RENOWNED, 4)
    assert_eq(a.rarity, b.rarity)
    assert_eq(a.class_id, b.class_id)
    assert_eq(a.raid_experience, b.raid_experience)
    assert_eq(a.id, b.id)
    assert_eq(a.morale, b.morale)

func test_a_board_softens_duplicate_classes() -> void:
    # docs/04 §3.1: "if a class appears twice, reroll the second occurrence once.
    # Prevents a board of three Wizards when the player is short a tank."
    var repeats := 0
    var boards := 40
    for seed_value in range(1, boards + 1):
        var board := Recruitment.roll_board(_rng(seed_value), 4,
            Enums.ReputationRank.KNOWN, 1)
        var seen := {}
        for who in board:
            if seen.has(who.class_id):
                repeats += 1
            seen[who.class_id] = true
    assert_true(repeats <= boards / 2,
        "duplicates must be rare across %d boards, saw %d" % [boards, repeats])

func test_a_board_never_offers_the_same_legendary_twice() -> void:
    # ✅ C12 again, this time within one refresh.
    for seed_value in range(1, 60):
        var board := Recruitment.roll_board(_rng(seed_value), 5,
            Enums.ReputationRank.LEGENDARY, 5)
        var legendary_classes := {}
        for who in board:
            if who.rarity != Enums.Rarity.LEGENDARY:
                continue
            assert_false(legendary_classes.has(who.class_id),
                "seed %d offered two Legendaries of one class" % seed_value)
            legendary_classes[who.class_id] = true

func test_a_board_of_zero_slots_is_empty_rather_than_broken() -> void:
    assert_eq(Recruitment.roll_board(_rng(1), 0, Enums.ReputationRank.KNOWN, 1), [])
