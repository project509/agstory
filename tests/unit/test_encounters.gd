extends "res://tests/TestCase.gd"
## data/encounters_t1.json + sim/model/Encounter.gd
##
## Encounter numbers are QUOTED from docs/08 §9.2/§9.3's damage budget, not
## authored in the content file. These tests are what keeps that true: if the
## data drifts from the budget, the encounter stops being balanced against the
## gear the player actually has, and no other test would notice.

const DB = preload("res://sim/content/ContentDB.gd")
const Encounter = preload("res://sim/model/Encounter.gd")
const E = preload("res://sim/model/Enums.gd")

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

# ---------------------------------------------------------------- structure

func test_five_tier_one_raid_encounters_in_slot_order() -> void:
    var raid: Array = _db.raid_encounters(1)
    assert_eq(raid.size(), 5, "canon: five encounters per raid tier")
    var slots := []
    for enc in raid:
        slots.append(enc.slot)
    assert_eq(slots, ["E1", "E2", "E3", "E4", "E5"])

func test_canon_star_ratings() -> void:
    # raw notes: encounters 1..5 carry 1..5 stars.
    for i in range(1, 6):
        var enc = _db.encounter_at_slot("E%d" % i)
        assert_eq(enc.stars, i, "E%d star rating" % i)

func test_canon_encounter_kinds() -> void:
    assert_eq(_db.encounter_at_slot("E1").kind, E.EncounterKind.TRASH)
    assert_eq(_db.encounter_at_slot("E2").kind, E.EncounterKind.HARD_TRASH)
    assert_eq(_db.encounter_at_slot("E3").kind, E.EncounterKind.MINI_BOSS)
    assert_eq(_db.encounter_at_slot("E4").kind, E.EncounterKind.MINI_BOSS)
    assert_eq(_db.encounter_at_slot("E5").kind, E.EncounterKind.MAIN_BOSS)

func test_canon_party_size_and_tank_requirement() -> void:
    # Canon: "raid size to be 12, most fights normally requiring 2 tanks".
    for enc in _db.raid_encounters(1):
        assert_eq(enc.party_size, E.RAID_SIZE, "%s party size" % enc.id)
        assert_eq(enc.tanks_required, E.TYPICAL_TANKS, "%s tanks" % enc.id)

# ---------------------------------------------------------------- the budget

func test_encounter_hp_matches_the_doc_08_budget() -> void:
    # docs/08 §9.2 derives each from stage DPS x target fight length.
    #
    # These moved on 2026-09-11 (docs/15 BL-71). The old five — 2100 / 2350 /
    # 3000 / 3800 / 6200 — were docs/10 §5.2's copy of an EARLIER §9.2, taken
    # before the +2 Power correction on the Boss-4 chests moved the DPS-at-
    # attempt column. docs/15 Q-17 already ruled that doc 08 §9 is authoritative
    # for all arithmetic; this is that ruling applied.
    var expected := {"E1": 2200, "E2": 2500, "E3": 3200, "E4": 4100, "E5": 7150}
    for slot in expected.keys():
        var enc = _db.encounter_at_slot(slot)
        assert_eq(enc.total_hp(), expected[slot], "%s total HP" % enc.id)

func test_raw_swing_budget_matches_doc_08() -> void:
    # docs/08 §9.3 sizes each from tank_max_hp / (TANK_DEATH_CLOCK x (1 - mit)).
    # The budget is a per-ROUND figure and each encounter splits it across its
    # own swings/round, so a small remainder is expected and allowed: E1 divides
    # 61 four ways and lands on 60, E3 divides 65 in two and lands on 66.
    var expected := {"E1": 61, "E2": 63, "E3": 65, "E4": 68, "E5": 73}
    for slot in expected.keys():
        var enc = _db.encounter_at_slot(slot)
        var got: int = enc.primary_raw_per_round()
        assert_true(absi(got - expected[slot]) <= 2,
            "%s raw/round is %d, budget says %d" % [enc.id, got, expected[slot]])

func test_target_rounds_match_doc_08_fight_lengths() -> void:
    var expected := {"E1": 12, "E2": 13, "E3": 15, "E4": 17, "E5": 22}
    for slot in expected.keys():
        assert_eq(_db.encounter_at_slot(slot).target_rounds, expected[slot], slot)

func test_enrage_is_always_the_formula() -> void:
    # docs/10 §5.2 / §10 M06: ceil(1.4 x target_rounds).
    for enc in _db.raid_encounters(1):
        assert_eq(enc.enrage_round, Encounter.enrage_for(enc.target_rounds),
            "%s enrage" % enc.id)
    assert_eq(_db.encounter_at_slot("E1").enrage_round, 17)
    assert_eq(_db.encounter_at_slot("E5").enrage_round, 31)

func test_full_clear_fits_the_pacing_budget() -> void:
    # docs/10 §7 wall-clock check: 48+52+60+68+88 = 316s, inside doc 01's
    # 3-8 minute micro loop once interstitials are counted.
    var total := 0
    for enc in _db.raid_encounters(1):
        total += enc.expected_clear_seconds()
    assert_eq(total, 316, "full Tier 1 clear in seconds of sim")
    assert_in_range(total, 180, 480, "must stay inside the 3-8 minute loop")

# ---------------------------------------------------------------- mechanics

func test_one_mechanic_per_star_exactly() -> void:
    # docs/10 §6 calls this the load-bearing constraint: difficulty is legible on
    # the board, authoring cost is capped, and QA gets a checklist. A one-star
    # fight with four mechanics is a bug, not a hard fight.
    for enc in _db.raid_encounters(1):
        assert_eq(enc.mechanics.size(), enc.stars,
            "%s has %d stars and %d mechanics" % [enc.id, enc.stars, enc.mechanics.size()])

func test_tier_one_uses_only_the_mechanics_doc_10_allows() -> void:
    # docs/10 §10 tier escalation: Tier 1 uses M01-M06, M08, M09 and nothing else.
    var allowed := ["m01", "m02", "m03", "m04", "m05", "m06", "m08", "m09"]
    for enc in _db.raid_encounters(1):
        for m in enc.mechanics:
            assert_true(m.key() in allowed,
                "%s uses %s, which Tier 1 should not introduce" % [enc.id, m.key()])

func test_coverage_rule_all_four_role_groups_stressed_before_e5() -> void:
    # docs/10 §10: otherwise a tier can be beaten by one lopsided roster and the
    # Tavern stops being interesting.
    var covered := {}
    for enc in _db.raid_encounters(1):
        if enc.slot == "E5":
            continue
        for g in enc.stressed_role_groups():
            covered[g] = true
    for group in [E.RoleGroup.TANK, E.RoleGroup.HEALER, E.RoleGroup.DPS]:
        assert_true(covered.has(group),
            "no Tier 1 encounter before E5 stresses %s" % E.role_group_name_of(group))

func test_mechanics_carry_their_parameters() -> void:
    var e5 = _db.encounter_at_slot("E5")
    assert_true(e5.has_mechanic(E.Mechanic.ENRAGE))
    var enrage = e5.mechanic_spec(E.Mechanic.ENRAGE)
    assert_eq(int(enrage.params["round"]), 31, "enrage params agree with enrage_round")
    var pulse = e5.mechanic_spec(E.Mechanic.RAID_WIDE)
    assert_eq(int(pulse.params["damage"]), 28, "docs/08 §9.5: 0.35 x cloth HP, fully geared")
    assert_true(bool(pulse.params["ignores_ac"]),
        "docs/10 §5.4 assumes raid-wide damage ignores AC so pressure lands on healers")

func test_raid_wide_damage_scales_with_the_cloth_pool() -> void:
    # docs/08 §9.5: AOE_BITE_FRACTION 0.35 x cloth max HP.
    # 75 HP at Adventure gear -> 26; 81 HP fully raid geared -> 28.
    assert_eq(int(_db.encounter_at_slot("E2").mechanic_spec(E.Mechanic.RAID_WIDE).params["damage"]), 26)
    assert_eq(int(_db.encounter_at_slot("E5").mechanic_spec(E.Mechanic.RAID_WIDE).params["damage"]), 28)

func test_swing_splitting_starts_at_e3() -> void:
    # docs/10 §5.4: E1 and E2 are one-swing bosses, which is the deadliest shape
    # for cloth; splitting from E3 is what keeps a retargeted swing survivable.
    for slot in ["E1", "E2"]:
        for e in _db.encounter_at_slot(slot).enemies:
            if e.threat_rule != "lowest_hp":
                assert_eq(e.swings_per_round, 1, "%s should be one-swing" % slot)
    for slot in ["E3", "E4", "E5"]:
        var primary = _db.encounter_at_slot(slot).enemies[0]
        assert_eq(primary.swings_per_round, 2, "%s should split its swing" % slot)

# ---------------------------------------------------------------- loot

func test_loot_slots_follow_the_canon_drop_pattern() -> void:
    # raw notes: E1 feet + basic weapons, E2 legs + healer off-hand, E3 head,
    # E4 chest + strong weapons, E5 class capstone + trinket.
    assert_eq(_db.encounter_at_slot("E1").loot_slots, ["feet", "weapon_basic"])
    assert_eq(_db.encounter_at_slot("E2").loot_slots, ["legs", "offhand_healer"])
    assert_eq(_db.encounter_at_slot("E3").loot_slots, ["head"])
    assert_eq(_db.encounter_at_slot("E4").loot_slots, ["chest", "weapon_strong"])
    assert_eq(_db.encounter_at_slot("E5").loot_slots, ["capstone", "trinket"])

func test_difficulty_increases_monotonically() -> void:
    var prev_hp := 0
    var prev_raw := 0
    for enc in _db.raid_encounters(1):
        assert_true(enc.total_hp() > prev_hp,
            "%s must have more HP than the encounter before it" % enc.id)
        assert_true(enc.primary_raw_per_round() >= prev_raw,
            "%s must not hit softer than the encounter before it" % enc.id)
        prev_hp = enc.total_hp()
        prev_raw = enc.primary_raw_per_round()

# ---------------------------------------------------------------- authoring

func test_every_encounter_has_a_comedy_line() -> void:
    # docs/10 §6: "Required. If it cannot be filled in, the encounter is a chore
    # and should be cut." This is a content-quality gate, not decoration.
    for enc in _db.raid_encounters(1):
        assert_false(enc.comedy_line.strip_edges().is_empty(), "%s" % enc.id)
        assert_true(enc.comedy_line.length() >= Encounter.COMEDY_LINE_MIN,
            "%s comedy line is too thin" % enc.id)

func test_every_encounter_names_the_mistakes_it_punishes() -> void:
    for enc in _db.raid_encounters(1):
        assert_true(enc.mistakes_invited.size() >= 1,
            "%s does not say which failure mode it is built to punish" % enc.id)
    assert_eq(_db.encounter_at_slot("E5").mistakes_invited.size(), 9,
        "docs/10 §7.5: all nine failure modes are reachable on the tier boss")

func test_ids_follow_the_documented_pattern() -> void:
    var re := RegEx.new()
    re.compile("^t[1-5]_(adv|raid)_e[1-5]$")
    for enc in _db.raid_encounters(1):
        assert_true(re.search(enc.id) != null, "malformed encounter id %s" % enc.id)

# ---------------------------------------------------------------- validation

func test_validator_rejects_a_star_mechanic_mismatch() -> void:
    var errors := []
    Encounter.from_dict({
        "id": "t1_raid_e9", "tier": 1, "slot": "E9", "stars": 1, "kind": "trash",
        "enemies": [{"name": "x", "count": 1, "hp": 10, "raw_swing": 1}],
        "mechanics": [{"id": "m01"}, {"id": "m02"}],
        "loot_slots": ["feet"], "target_rounds": 10, "enrage_round": 14,
        "comedy_line": "long enough to pass the content quality gate here",
    }, errors)
    var found := false
    for e in errors:
        if e.contains("one per star"):
            found = true
    assert_true(found, "a 1-star fight with 2 mechanics must be rejected: %s" % str(errors))

func test_validator_rejects_a_wrong_enrage_round() -> void:
    var errors := []
    Encounter.from_dict({
        "id": "t1_raid_e8", "tier": 1, "slot": "E8", "stars": 1, "kind": "trash",
        "enemies": [{"name": "x", "count": 1, "hp": 10, "raw_swing": 1}],
        "mechanics": [{"id": "m01"}],
        "loot_slots": ["feet"], "target_rounds": 10, "enrage_round": 99,
        "comedy_line": "long enough to pass the content quality gate here",
    }, errors)
    var found := false
    for e in errors:
        if e.contains("enrage_round"):
            found = true
    assert_true(found, str(errors))

## A minimal valid record, so a validator test can change ONE thing and be sure
## that thing is what it caught.
func _record(over: Dictionary) -> Dictionary:
    var d := {
        "id": "t1_raid_e9", "tier": 1, "slot": "E9", "stars": 1, "kind": "trash",
        "enemies": [{"name": "x", "count": 1, "hp": 10, "raw_swing": 1}],
        "mechanics": [{"id": "m01"}],
        "loot_slots": ["feet"], "target_rounds": 10, "enrage_round": 14,
        "comedy_line": "long enough to pass the content quality gate here",
    }
    for k in over.keys():
        d[k] = over[k]
    return d

func _errors_for(over: Dictionary) -> Array:
    var errors := []
    Encounter.from_dict(_record(over), errors)
    return errors

func _complains_about(over: Dictionary, needle: String) -> bool:
    for e in _errors_for(over):
        if String(e).contains(needle):
            return true
    return false

func test_the_mechanic_budget_is_relaxed_for_tutorials_and_only_downward() -> void:
    # docs/10 §9.1 specifies Adventure 0 with "no mechanics" while `stars` may
    # not be 0, so no (stars, mechanics) pair satisfied both and A0 could not be
    # authored at all. The exemption is ONE-WAY: a tutorial may carry fewer
    # mechanics than its stars, never more — docs/10 §6 calls one-per-star the
    # load-bearing constraint for all 42 encounters, and relaxing it to `<=`
    # everywhere would delete it silently.
    assert_true(_complains_about({"mechanics": []}, "one per star"),
        "a NON-tutorial 1-star fight with no mechanics is still a bug")
    assert_false(_complains_about({"slot": "A0", "mechanics": []}, "one per star"),
        "Adventure 0 must be authorable exactly as docs/10 §9.1 specifies it")
    assert_false(_complains_about({"slot": "TR", "mechanics": []}, "one per star"))
    assert_true(_complains_about(
        {"slot": "A0", "mechanics": [{"id": "m01"}, {"id": "m02"}]}, "one per star"),
        "the exemption is downward only — a 1-star tutorial with 2 mechanics is a bug")

func test_a_tutorial_is_identified_by_its_slot_and_nothing_else() -> void:
    var errors := []
    var tut = Encounter.from_dict(_record({"slot": "A0", "mechanics": []}), errors)
    assert_true(tut.is_tutorial())
    var raid = Encounter.from_dict(_record({}), errors)
    assert_false(raid.is_tutorial(), "E9 is not a tutorial")

func test_validator_refuses_a_zero_tank_requirement() -> void:
    # game/core/RaidPlan.gd's guard reads `> 0`, so an authored 0 is
    # indistinguishable from an absent field and silently resolves to 2 — a
    # difficulty change with no error anywhere. docs/15's per-fight tank ruling
    # is default 2 and tutorials 1, never 0, so 0 is refused here rather than
    # the guard being loosened tier-wide.
    assert_true(_complains_about({"tanks_required": 0}, "tanks_required"))
    assert_true(_complains_about({"tanks_required": -1}, "tanks_required"))
    assert_false(_complains_about({"tanks_required": 1}, "tanks_required"))
    assert_false(_complains_about({}, "tanks_required"),
        "an absent field still defaults to docs/15's 2 and is not an error")

func test_the_scripted_mistake_round_must_be_a_round_the_fight_reaches() -> void:
    # docs/10 §9.1 authorises `force_mistake_round` on exactly one encounter.
    # A round past `target_rounds` is a content bug, not a teaching beat: the
    # player would never see it.
    assert_false(_complains_about({"force_mistake_round": 3}, "force_mistake_round"))
    assert_false(_complains_about({}, "force_mistake_round"),
        "0 means no script, which is every other encounter in the game")
    assert_true(_complains_about({"force_mistake_round": 11}, "force_mistake_round"))
    assert_true(_complains_about({"force_mistake_round": -1}, "force_mistake_round"))
    var errors := []
    var e = Encounter.from_dict(_record({"force_mistake_round": 3}), errors)
    assert_eq(e.force_mistake_round, 3, "the field must survive from_dict")

func test_validator_requires_a_comedy_line() -> void:
    var errors := []
    Encounter.from_dict({
        "id": "t1_raid_e7", "tier": 1, "slot": "E7", "stars": 1, "kind": "trash",
        "enemies": [{"name": "x", "count": 1, "hp": 10, "raw_swing": 1}],
        "mechanics": [{"id": "m01"}],
        "loot_slots": ["feet"], "target_rounds": 10, "enrage_round": 14,
        "comedy_line": "   ",
    }, errors)
    var found := false
    for e in errors:
        if e.contains("comedy_line"):
            found = true
    assert_true(found, str(errors))

# ---------------------------------------------------------------- the ladder

func test_every_loaded_tier_has_a_full_rung_set() -> void:
    # Written against `_db.tiers` rather than the number 1, so the day a tier
    # lands it is held to canon's shape (docs/10 §4: five raid encounters;
    # §8: three Adventure encounters) with no edit here.
    assert_true(_db.tiers.size() >= 1, "no tier mounted at all")
    for tier in _db.tiers:
        assert_eq(_db.raid_encounters(tier).size(), 5, "tier %d raid rungs" % tier)
        assert_eq(_db.adventure_encounters(tier).size(), 3, "tier %d Adventure rungs" % tier)
        for enc in _db.raid_encounters(tier):
            assert_eq(enc.tier, tier, "%s files itself under the wrong tier" % enc.id)
        for enc in _db.adventure_encounters(tier):
            assert_eq(enc.tier, tier, "%s files itself under the wrong tier" % enc.id)

func test_the_slot_index_carries_the_tier() -> void:
    # Every rung is reachable by (tier, slot), and the bare-slot accessor the
    # rest of the tree calls is the tier-1 case of it, not a second index.
    for tier in _db.tiers:
        for enc in _db.raid_encounters(tier):
            assert_eq(_db.encounter_at(tier, enc.slot).id, enc.id)
    for enc in _db.raid_encounters(1):
        assert_eq(_db.encounter_at_slot(enc.slot), _db.encounter_at(1, enc.slot))
    assert_eq(_db.encounter_at(1, "E9"), null, "an unauthored slot resolves to nothing")

# ------------------------------------ docs/10 §6's comedy_line, across the whole
# ------------------------------------ corpus rather than a file at a time

## §6 makes the field required and says why: "If it cannot be filled in, the
## encounter is a chore and should be cut." It is a CUT RULE wearing a content
## field, which is why it earns three tests rather than one.
##
## Three gates used to check it and no two agreed — this file wanted more than 40
## characters, tests/unit/test_adventures.gd wanted more than 20, and the
## validator wanted only non-empty. The corpus passed all three by accident.
## `Encounter.COMEDY_LINE_MIN` is the one bar now and all three read it.
##
## These walk the DATA FILES rather than a loaded ContentDB on purpose: docs/15
## BL-69 keeps an unnamed tier out of the default mount, so a DB-based check
## would see Tier 1's ten encounters and silently ignore the thirty-two in tiers
## 2-5 — which is exactly the set most likely to ship with a hole in it.

const ENCOUNTER_DATA_DIR := "res://data"


func _all_encounter_rows() -> Array:
    var out: Array = []
    var d := DirAccess.open(ENCOUNTER_DATA_DIR)
    if d == null:
        return out
    var names: Array = []
    for f in d.get_files():
        if String(f).begins_with("encounters") and String(f).ends_with(".json"):
            names.append(String(f))
    names.sort()
    for name in names:
        var doc = JSON.parse_string(
            FileAccess.get_file_as_string(ENCOUNTER_DATA_DIR + "/" + String(name)))
        if not (doc is Dictionary):
            continue
        for row in ((doc as Dictionary).get("encounters", []) as Array):
            out.append(row)
    return out


func test_every_encounter_in_the_data_carries_a_usable_line() -> void:
    var rows := _all_encounter_rows()
    # docs/16 W1.10 and R-10 both put the corpus at 42. If this number falls the
    # walk broke; if it rises, the new content is covered by the loop below.
    assert_true(rows.size() >= 42,
        "the walk found %d encounters — docs/16 puts the corpus at 42" % rows.size())
    for row in rows:
        var rec: Dictionary = row
        var line := String(rec.get("comedy_line", "")).strip_edges()
        assert_true(line.length() >= Encounter.COMEDY_LINE_MIN,
            "%s has no usable comedy line (%d characters)"
                % [String(rec.get("id", "?")), line.length()])


func test_no_two_encounters_share_a_comedy_line() -> void:
    # The exact failure this field exists to prevent. A line copied to the rung
    # next door passes every other check in the project — non-empty, long enough,
    # one per encounter — and tells the player the two fights are the same joke.
    var by_line := {}
    for row in _all_encounter_rows():
        var rec: Dictionary = row
        var line := String(rec.get("comedy_line", "")).strip_edges()
        if line.is_empty():
            continue
        assert_false(by_line.has(line), "%s and %s share a comedy line: %s"
            % [String(by_line.get(line, "?")), String(rec.get("id", "?")), line])
        by_line[line] = String(rec.get("id", "?"))


func test_the_validator_refuses_a_placeholder_and_not_only_a_blank() -> void:
    # "TBD" is non-empty. The floor is what stops it shipping, and it is a
    # placeholder detector rather than a prose rule — it sits far below the
    # shortest line the game actually ships (103 characters).
    var doc := {
        "id": "test_thin", "slot": "E1", "tier": 1, "kind": "trash",
        "stars": 1, "party_size": 12, "target_rounds": 10, "enrage_round": 14,
        "enemies": [{"name": "Thing", "count": 1, "hp": 100, "raw_per_round": 10}],
        "loot_slots": ["head"], "comedy_line": "TBD",
    }
    var errors: Array[String] = []
    Encounter.from_dict(doc, errors)
    var complained := false
    for e in errors:
        if e.contains("comedy_line") and e.contains("placeholder"):
            complained = true
    assert_true(complained, "a three-character line must be refused: %s" % str(errors))
