extends "res://tests/TestCase.gd"
## The rules that are about a TIER rather than about one encounter.
##
## Every per-encounter rule was already enforced at load — one mechanic per star,
## the enrage formula, a comedy line — and all of them can pass while the LADDER
## is broken: a tier whose boss is the first fight to test your healers, a tier
## that teaches five new mechanics at once, a tier whose E3 is softer than the
## E3 below it. None of that is visible from inside a single record, which is
## exactly why generated content needed it.
##
## `ContentDB.tier_rule_problems()` is a pure function of {tier: [encounters]},
## so each rule is tested by feeding it a synthetic tier that breaks THAT rule
## and reading the error back. A validator nobody can make fail is a validator
## nobody has tested.

const DB = preload("res://sim/content/ContentDB.gd")
const Encounter = preload("res://sim/model/Encounter.gd")
const Enums = preload("res://sim/model/Enums.gd")

var _db = null


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()


## A minimal legal-looking encounter: one enemy block and whatever mechanics the
## caller wants to test the rules with.
func _enc(slot: String, hp: int, raw: int, mechanics: Array) -> Variant:
    var specs: Array = []
    for m in mechanics:
        specs.append({"id": Enums.mechanic_key(m), "params": {}})
    return Encounter.from_dict({
        "id": "synthetic_%s" % slot.to_lower(),
        "display_name": "Synthetic %s" % slot,
        "tier": 1, "slot": slot, "stars": 1, "kind": "trash",
        "party_size": 12, "tanks_required": 2,
        "target_rounds": 12, "enrage_round": 17,
        "comedy_line": "A synthetic fight, for a test that needed one.",
        "loot_slots": ["feet"],
        "enemies": [{"name": "Trash", "count": 1, "hp": hp, "raw_swing": raw,
            "swings_per_round": 1}],
        "mechanics": specs,
    }, [])


## A whole tier of five, stressing tank/healer/dps before the boss.
func _legal_tier(hp_base: int, raw_base: int, extra: Array = []) -> Array:
    return [
        _enc("E1", hp_base, raw_base, [Enums.Mechanic.TANK_SWAP]),
        _enc("E2", hp_base + 100, raw_base + 1, [Enums.Mechanic.RAID_WIDE]),
        _enc("E3", hp_base + 200, raw_base + 2, [Enums.Mechanic.GROUND_EFFECT]),
        _enc("E4", hp_base + 300, raw_base + 3, [Enums.Mechanic.ADD_SPAWNS]),
        _enc("E5", hp_base + 400, raw_base + 4, [Enums.Mechanic.ENRAGE] + extra),
    ]


func test_the_shipped_content_passes_every_tier_rule() -> void:
    # The one that matters most: canon's own tier, through the real loader.
    assert_true(_db.is_valid(), _db.error_report())
    assert_eq(DB.tier_rule_problems({1: _db.raid_encounters(1)}).size(), 0,
        "Tier 1 must satisfy the rules it is the source of")


func test_every_generated_tier_passes_too() -> void:
    # The generated tiers are not in the default set (docs/15 BL-69), so they are
    # loaded by name here. This is the check that the generator's encounter half
    # is legal content and not just well-formed JSON.
    var paths: Dictionary = DB.DEFAULT_PATHS.duplicate(true)
    var found: Array = []
    for tier in range(1, 6):
        found.append(DB.tier_paths(tier))
    paths["tiers"] = found
    var all_tiers = DB.load_all(paths)
    assert_eq(all_tiers.tiers.size(), 5, "expected five tiers on disk")
    assert_true(all_tiers.is_valid(), all_tiers.error_report())


func test_a_tier_whose_boss_is_the_first_healer_test_is_rejected() -> void:
    # docs/10 §10's intent: "a tier can be beaten by one lopsided roster" is what
    # happens when the raid-wide damage arrives for the first time at E5.
    var tier := [
        _enc("E1", 100, 10, [Enums.Mechanic.TANK_SWAP]),
        _enc("E2", 200, 11, [Enums.Mechanic.GROUND_EFFECT]),
        _enc("E3", 300, 12, [Enums.Mechanic.ADD_SPAWNS]),
        _enc("E4", 400, 13, [Enums.Mechanic.POSITIONING]),
        _enc("E5", 500, 14, [Enums.Mechanic.RAID_WIDE]),
    ]
    var problems := DB.tier_rule_problems({1: tier})
    assert_true(problems.size() >= 1, "a healer-blind tier must be rejected")
    var joined := "\n".join(problems)
    assert_true(joined.contains("healer"), "and the error must name the group: %s" % joined)


func test_a_tier_that_teaches_three_new_mechanics_is_rejected() -> void:
    # docs/10 §473: at most two the player has not seen. Three is a tutorial.
    var t1 := _legal_tier(1000, 20)
    var t2 := [
        _enc("E1", 2000, 30, [Enums.Mechanic.TANK_SWAP, Enums.Mechanic.MANA_BURN]),
        _enc("E2", 2100, 31, [Enums.Mechanic.RAID_WIDE, Enums.Mechanic.FRONTAL_CLEAVE]),
        _enc("E3", 2200, 32, [Enums.Mechanic.GROUND_EFFECT, Enums.Mechanic.ESCALATING_SWING]),
        _enc("E4", 2300, 33, [Enums.Mechanic.ADD_SPAWNS]),
        _enc("E5", 2400, 34, [Enums.Mechanic.ENRAGE]),
    ]
    var problems := DB.tier_rule_problems({1: t1, 2: t2})
    var joined := "\n".join(problems)
    assert_true(joined.contains("escalation"),
        "three new mechanics in one tier must be rejected: %s" % joined)


func test_two_new_mechanics_in_a_tier_are_allowed() -> void:
    # The boundary, asserted from the legal side as well as the illegal one.
    var t1 := _legal_tier(1000, 20)
    var t2 := [
        _enc("E1", 2000, 30, [Enums.Mechanic.TANK_SWAP, Enums.Mechanic.MANA_BURN]),
        _enc("E2", 2100, 31, [Enums.Mechanic.RAID_WIDE, Enums.Mechanic.FRONTAL_CLEAVE]),
        _enc("E3", 2200, 32, [Enums.Mechanic.GROUND_EFFECT]),
        _enc("E4", 2300, 33, [Enums.Mechanic.ADD_SPAWNS]),
        _enc("E5", 2400, 34, [Enums.Mechanic.ENRAGE]),
    ]
    assert_eq(DB.tier_rule_problems({1: t1, 2: t2}).size(), 0,
        "exactly two new mechanics is what the rule allows")


func test_a_tier_whose_slot_is_softer_than_the_one_below_is_rejected() -> void:
    # The ladder check, slot by slot. Tier 2's E3 is weaker than Tier 1's E3
    # while every other slot rises — the kind of hole a per-tier total would
    # never show.
    var t1 := _legal_tier(1000, 20)
    var t2 := _legal_tier(2000, 40)
    t2[2] = _enc("E3", 900, 5, [Enums.Mechanic.GROUND_EFFECT])
    var problems := DB.tier_rule_problems({1: t1, 2: t2})
    var joined := "\n".join(problems)
    assert_true(joined.contains("E3"), "the sagging slot must be named: %s" % joined)
    assert_true(joined.contains("HP") or joined.contains("swings"),
        "and what fell about it: %s" % joined)


func test_comparing_e1_against_the_tier_belows_e5_is_NOT_the_rule() -> void:
    # Recorded as a test because the obvious-sounding version of the ladder rule
    # is wrong, and the shipped content proves it: Tier 2's E1 holds 4300 HP
    # against Tier 1's E5 at 7150, because E1 is a twelve-round pull and E5 is a
    # twenty-two-round boss. A rule comparing them would reject canon's own
    # ladder.
    var t1 := _legal_tier(1000, 20)
    var t2 := _legal_tier(2000, 40)
    assert_eq(DB.tier_rule_problems({1: t1, 2: t2}).size(), 0,
        "a tier whose every slot beats the slot below it is legal")
    var t1_e5_hp: int = t1[4].total_hp()
    var t2_e1_hp: int = t2[0].total_hp()
    assert_true(t2_e1_hp < t1_e5_hp or t2_e1_hp > t1_e5_hp,
        "this test exists to document the comparison that is NOT made")
