extends "res://tests/TestCase.gd"
## The two onboarding rungs (docs/10 §9): Adventure 0 and the Tutorial Raid.
##
## These are the first fight a player ever sees and the only content in the game
## that is allowed to break the encounter rules, so almost every assertion here
## is a guard against a plausible, silent regression:
##
##   the HP column of docs/10 §9.1 is wrong by 5.3x and transcribing it (the
##   house rule everywhere else) ships two unwinnable tutorials
##   the slot keys "A0" and "TR" are what sim/core/Reputation.gd pays RP off —
##   any other key costs zero errors and silently pays nothing
##   `onboarding_complete` is the flag that arms a whole-roster wipe

const DB = preload("res://sim/content/ContentDB.gd")
const Encounter = preload("res://sim/model/Encounter.gd")
const Enums = preload("res://sim/model/Enums.gd")
const StartingRoster = preload("res://game/core/StartingRoster.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const Raider = preload("res://sim/model/Raider.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

func after_each() -> void:
    # `record_attempt` and `skip_tutorial` both autosave (docs/14 §7.4), so the
    # campaign tests below are save-writers.
    SaveGame.purge_all()
    # The screen clause borrows the autoload GameState; put it back, content
    # included (LESSONS: a state left with content changes what `new_game()`
    # does for the next file).
    var root: Node = (Engine.get_main_loop() as SceneTree).root
    var st = root.get_node_or_null("GameState")
    if st != null and not (st in _made):
        st.reset()
        st.set_content(null)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []

func _tut(slot: String):
    return _db.encounter_at_slot(slot)

# ---------------------------------------------------------------- shape

func test_the_tutorial_file_loads_with_no_errors() -> void:
    assert_true(_db.is_valid(), _db.error_report())

func test_both_rungs_exist_in_canon_order() -> void:
    var all: Array = _db.tutorial_encounters(1)
    assert_eq(all.size(), 2, "canon lists two tutorials: Adventure 0 and the Tutorial Raid")
    assert_eq(all[0].slot, "A0")
    assert_eq(all[1].slot, "TR")
    assert_eq(all[0].display_name, "Adventure 0")
    assert_eq(all[1].display_name, "Tutorial Raid")
    assert_eq(_db.tutorial_encounters(2).size(), 0,
        "docs/10 §9 gives the ladder exactly two tutorials, and not one per tier")

func test_the_tutorials_sit_at_their_own_slots_and_collide_with_nothing() -> void:
    # The rung index is keyed "<tier>:<slot>", so A0/TR cannot displace A1-A3 or
    # E1-E5 — but a mistyped slot would silently take one of theirs.
    assert_eq(_db.adventure_encounters(1).size(), 3, "the Adventure rungs are untouched")
    assert_eq(_db.raid_encounters(1).size(), 5, "the Raid rungs are untouched")
    assert_eq(_tut("A0").id, "t1_tut_a0")
    assert_eq(_tut("TR").id, "t1_tut_tr")
    assert_eq(_tut("A0").tier, 1)
    assert_eq(_tut("TR").tier, 1)

func test_the_kinds_are_one_trash_mob_and_one_boss() -> void:
    # Canon, verbatim: "Adventure 0 - 1 Trash mob" and "Tutorial Raid - 1 Boss".
    assert_eq(_tut("A0").kind, Enums.EncounterKind.TRASH)
    assert_eq(_tut("TR").kind, Enums.EncounterKind.MAIN_BOSS)
    assert_eq(_tut("A0").enemies.size(), 1)
    assert_eq(_tut("TR").enemies.size(), 1)

func test_party_sizes_and_tank_counts() -> void:
    # docs/10 §9.1 fields 4 and 6. Tanks are 1 and 1 — docs/15's per-fight tank
    # ruling (default 2, tutorials 1) overrides docs/10 §9.1's "no tanks
    # required" as the later DECIDED entry, and a literal 0 is unauthorable
    # because RaidPlan's guard reads `> 0` and would resolve it to 2.
    assert_eq(_tut("A0").party_size, 4)
    assert_eq(_tut("TR").party_size, 6)
    assert_eq(_tut("A0").tanks_required, 1)
    assert_eq(_tut("TR").tanks_required, 1)

# ---------------------------------------------------------------- the numbers

func test_hp_is_the_stage_zero_derivation_and_not_docs_10s_printed_column() -> void:
    # docs/08 §9.1a stage 0 = 16.5/round over the benchmark six = 2.75/raider.
    # A0 at party 4: 11.0 x 6 rounds = 66. TR at party 6: 16.5 x 12 = 198.
    # docs/10 §9.1 prints 350 and 1,055, both derived off STAGE A (full Tier 1
    # Adventure gear) — the same 5.3x error docs/15 BL-28 corrected for A1-A3.
    # The tutorials are played at stage 0 because nothing has dropped yet.
    var stage_zero_per_raider := 16.5 / 6.0
    for slot in ["A0", "TR"]:
        var e = _tut(slot)
        var derived := int(round(stage_zero_per_raider * float(e.party_size)
            * float(e.target_rounds)))
        assert_eq(e.total_hp(), derived,
            "%s: %d HP against the stage-0 derivation's %d" % [slot, e.total_hp(), derived])
    assert_eq(_tut("A0").total_hp(), 66)
    assert_eq(_tut("TR").total_hp(), 198)
    assert_ne(_tut("A0").total_hp(), 350, "docs/10 §9.1's stage-A figure must not return")
    assert_ne(_tut("TR").total_hp(), 1055, "docs/10 §9.1's stage-A figure must not return")

func test_the_swings_are_docs_10s_own_numbers_unmodified() -> void:
    # These are NOT re-derived. docs/10 §9.1 states the resulting unhealed tank
    # clocks (A0 ~7.4 rounds, TR 4.9 against docs/08 §9.3's 3.5) on purpose:
    # "a tutorial demonstrates a fail state, it does not impose one".
    var a0 = _tut("A0").enemies[0]
    assert_eq(a0.raw_swing, 20)
    assert_eq(a0.swings_per_round, 1)
    var tr = _tut("TR").enemies[0]
    assert_eq(tr.raw_swing, 15)
    assert_eq(tr.swings_per_round, 2)
    # docs/08 §9.3's full stage-0 tank budget is 120 HP / (3.5 x (1 - 0.189)) =
    # ~42 raw/round for a 3.5-round unhealed clock. The Tutorial Raid's 30 is
    # deliberately under it, which is docs/10 §9.1's stated 4.9-round clock.
    assert_eq(_tut("TR").primary_raw_per_round(), 30)
    assert_true(_tut("TR").primary_raw_per_round() < 42,
        "a tutorial demonstrates a fail state, it does not impose one")

func test_enrage_is_the_validated_formula_not_an_authored_number() -> void:
    for slot in ["A0", "TR"]:
        var e = _tut(slot)
        assert_eq(e.enrage_round, Encounter.enrage_for(e.target_rounds),
            "%s enrage must be ceil(1.4 x target_rounds)" % slot)
    assert_eq(_tut("A0").enrage_round, 9)
    assert_eq(_tut("TR").enrage_round, 17, "matches docs/10 §9.1's printed 17 independently")

# ---------------------------------------------------------------- mechanics

func test_adventure_zero_carries_no_mechanics_at_all() -> void:
    # docs/10 §9.1 in terms. Its five teaching beats are all UI — roster select,
    # confirm, watch, read a mistake, equip a drop — and a boss mechanic on top
    # teaches nothing the next rung would not.
    assert_eq(_tut("A0").mechanics.size(), 0)
    assert_eq(_tut("A0").stars, 1, "stars stay 1-5 so the board's star display keeps working")

func test_the_tutorial_raid_teaches_m01_with_its_parameters_authored() -> void:
    # docs/10 §10 M01: "+50%/stack damage taken, 1 stack per hit, swap at 3".
    # Authored explicitly rather than left to RaidSim's defaults, so a change to
    # the default cannot silently retune the one thing this fight exists to show.
    var e = _tut("TR")
    assert_eq(e.mechanics.size(), 1)
    var spec = e.mechanic_spec(Enums.Mechanic.TANK_SWAP)
    assert_ne(spec, null, "M01 Tank Swap is the Tutorial Raid's whole teaching payload")
    assert_eq(int(spec.params.get("stack_damage_pct", -1)), 50)
    assert_eq(int(spec.params.get("swap_at", -1)), 3)

func test_adventure_zero_scripts_a_mistake_on_round_three() -> void:
    # docs/10 §9.1: "a content-level override flag on the encounter record
    # (force_mistake_round: 3), and it exists on exactly one encounter."
    assert_eq(_tut("A0").force_mistake_round, 3)
    assert_eq(_tut("TR").force_mistake_round, 0)
    var scripted := 0
    for id in _db.encounters.keys():
        if int(_db.encounters[id].force_mistake_round) > 0:
            scripted += 1
    assert_eq(scripted, 1, "exactly one encounter in the game may script a mistake")

## THE SIM HALF OF force_mistake_round. The data half (the field, the loader's
## validator, the authored 3 on t1_tut_a0) landed with M5-TUT-01; until W5-SIM
## nothing in RaidSim read it, so the first tutorial taught four of its five
## beats and skipped the one the game is named after ("read a mistake in the
## log", docs/10 §9.1). Twenty seeds, the squad the game hands you: every run
## carries a MISTAKE entry on round 3 and `mistake_count >= 1`.
func test_adventure_zero_fires_its_scripted_mistake_on_every_seed() -> void:
    var enc = _tut("A0")
    var party := _premade(4)
    for i in 20:
        var res = RaidSim.run(party, enc, _db, 4000 + i * 7919)
        assert_true(res.rounds >= 3,
            "seed %d ended on round %d, before the script could fire" % [i, res.rounds])
        var on_three := 0
        for e in res.log.mistakes():
            if e.round_no == enc.force_mistake_round:
                on_three += 1
        assert_true(on_three >= 1, "seed %d: no mistake on round %d" % [i, enc.force_mistake_round])
        assert_true(res.mistake_count >= 1, "seed %d: mistake_count %d" % [i, res.mistake_count])

func test_the_scripted_mistake_is_one_raider_minor_and_seed_deterministic() -> void:
    # "one guaranteed mistake": the script adds exactly one event of its own on
    # that round, as a Minor whenever the type's band reaches Minor — the tutorial
    # demonstrates a fail state, it does not impose one — and the same seed
    # names the same raider, because the pick is drawn from the fight's Rng
    # (build/plan/q-W5-SIM.md).
    var enc = _tut("A0")
    var party := _premade(4)
    var a = RaidSim.run(party, enc, _db, 4242)
    var b = RaidSim.run(party, enc, _db, 4242)
    assert_eq(a.log.to_json(), b.log.to_json(), "the scripted mistake must not break replay")
    var scripted: Array = []
    for e in a.log.mistakes():
        if e.round_no == 3:
            scripted.append(e)
    assert_true(scripted.size() >= 1)
    var minor_seen := false
    for e in scripted:
        if String(e.mistake.get("severity", "")) == Enums.severity_key(Enums.Severity.MINOR):
            minor_seen = true
    assert_true(minor_seen, "the scripted mistake on round 3 should read as Minor: %s"
        % str(scripted.map(func(e): return e.mistake)))

func test_the_tutorial_raid_scripts_nothing_and_a_real_rung_never_could() -> void:
    # The flag is 0 everywhere but A0, so the forced path must be unreachable
    # from every other encounter: a seed that produces no round-3 mistake on the
    # Tutorial Raid is the proof that the sim reads the field and not the slot.
    var found_clean_seed := false
    for i in 20:
        var res = RaidSim.run(_premade(6), _tut("TR"), _db, 9000 + i * 31)
        var on_three := 0
        for e in res.log.mistakes():
            if e.round_no == 3:
                on_three += 1
        if on_three == 0 and res.rounds >= 3:
            found_clean_seed = true
            break
    assert_true(found_clean_seed,
        "twenty Tutorial Raid seeds all carried a round-3 mistake — the script is leaking")

func test_both_tutorials_roll_at_the_reduced_rate_and_a_real_rung_does_not() -> void:
    # docs/07 OQ-9's ruling through the sim, not only through Mistakes: the flag has to
    # reach the Context the fight actually builds. Read off the context builder
    # so the assertion is about the wire and not a hit rate.
    var party := _premade(4)
    var c = load("res://sim/model/Combatant.gd").create(party[0], _db, 0)
    c.set_meta("profile", {"class_id": party[0].class_id, "role_group": Enums.RoleGroup.DPS,
        "ac": 0, "power": 0, "mana": 0, "main_damage": 0, "off_damage": 0,
        "heal_base": 0, "dual_wield": false})
    for slot in ["A0", "TR"]:
        var ctx = RaidSim._context(Enums.RollSite.ACTION, 1, Enums.Phase.DPS, c, [], _tut(slot))
        assert_true(ctx.tutorial, "%s must roll at the tutorial rate" % slot)
    for slot in ["A1", "E1", "E5"]:
        var ctx = RaidSim._context(Enums.RollSite.ACTION, 1, Enums.Phase.DPS, c, [],
            _db.encounter_at_slot(slot))
        assert_false(ctx.tutorial, "%s is a real rung and rolls at the full rate" % slot)

# ------------------------------------------------------- reputation contract

func test_the_slot_keys_are_the_reputation_contract() -> void:
    # docs/03 §6.1: Adventure 0 pays 5 RP, the Tutorial Raid 10. sim/core/
    # Reputation.gd keys that off the literal strings "A0" and "TR", so this is
    # the assertion that catches a renamed slot — which would otherwise pay 0 RP
    # with no error anywhere in the build.
    assert_true(Reputation.is_tutorial_slot(_tut("A0").slot))
    assert_true(Reputation.is_tutorial_slot(_tut("TR").slot))
    assert_eq(Reputation.award_for(_tut("A0"), 1), 5)
    assert_eq(Reputation.award_for(_tut("TR"), 1), 10)

func test_the_tutorials_are_never_reputation_gated() -> void:
    # docs/03 §7's Unknown row — they are the first thing a new guild does.
    for slot in ["A0", "TR"]:
        assert_true(Reputation.content_unlocked(_tut(slot), Enums.ReputationRank.UNKNOWN),
            "%s must be open at the starting rank" % slot)

# ---------------------------------------------------------------- winnability

func _starting(class_key: String, index: int, morale: int = 55):
    var r = Raider.new()
    r.id = "tut_%s_%d" % [class_key, index]
    r.display_name = class_key.capitalize()
    r.class_id = Enums.class_from_key(class_key)
    r.rarity = Enums.Rarity.COMMON
    r.morale = morale
    for it in _db.starting_set(class_key):
        r.equip(_db, it)
    return r

## The squad the game actually hands you, which is the thing these tests are
## named after. It is NOT an invented six: `StartingRoster.BENCHMARK_COMP` is
## the twelve a new guild owns, and `RaidPlan.suggest_party()` is the rule that
## seeds a tutorial party out of them — role first (the encounter's own
## `tanks_required`, then docs/10 §3's healer recommendation), happiest first
## within a role.
##
## An earlier version of this helper listed one Warrior, Cleric, Shaman, Rogue,
## Mage, Wizard and attributed it to docs/01 §8.3, which does not say that. The
## difference is not cosmetic: canon's twelve contain TWO warriors, so the real
## squad can perform M01's swap and the invented one never could. Measuring a
## tutorial against a party the game will not give you measures nothing.
func _premade(n: int) -> Array:
    var roster := StartingRoster.build(_db, 700)
    var enc = _tut("A0") if n <= 4 else _tut("TR")
    var pool := roster.duplicate()
    pool.sort_custom(func(a, b): return a.morale > b.morale)
    var picked: Array = []
    var taken := {}
    var want := {
        Enums.RoleGroup.TANK: RaidPlan.tanks_required(enc),
        Enums.RoleGroup.HEALER: RaidPlan.healers_recommended(enc),
    }
    for g in [Enums.RoleGroup.TANK, Enums.RoleGroup.HEALER]:
        for r in pool:
            if picked.size() >= n or int(want[g]) <= 0:
                break
            var cd = _db.class_of(r.class_id)
            if taken.has(r.id) or (cd.role_group if cd != null else -1) != g:
                continue
            picked.append(r)
            taken[r.id] = true
            want[g] = int(want[g]) - 1
    for r in pool:
        if picked.size() >= n:
            break
        if not taken.has(r.id):
            picked.append(r)
            taken[r.id] = true
    return picked

func _clears(slot: String, party: Array, seeds: int = 20) -> int:
    var cleared := 0
    for i in seeds:
        if RaidSim.run(party, _tut(slot), _db, 4000 + i * 7919).cleared():
            cleared += 1
    return cleared

func test_adventure_zero_is_won_by_the_squad_the_game_hands_you() -> void:
    # A0 is the first fight in the game and it is not allowed to be a fail
    # state — docs/10 §9.1 gives the fail state to the Tutorial Raid instead.
    # A player who loses the tutorial has learned that the game is unfair, which
    # is the one thing docs/15's tutorial-mistake-rate ruling exists to prevent.
    var cleared := _clears("A0", _premade(4))
    assert_true(cleared >= 18, "Adventure 0 must be near-certain — got %d/20" % cleared)

## THE TUTORIAL RAID IS CURRENTLY UNWINNABLE, AND THIS PINS IT.
##
## docs/10 §9.1 wants "a real fail state: a boss with one mechanic, an enrage
## timer, and the Wipe Report" — winnable AND losable, because the Wipe Report
## is one of three things the fight exists to show. Measured with the squad the
## game hands you, it clears 0 of 20.
##
## The cause is arithmetic in the doc, not a defect in the sim, and it is the
## same one A3 has (see tests/unit/test_adventures.gd). §9.1 sizes the boss by
## its AUTOATTACK alone — "30 raw/round is a 4.9-round unhealed clock on a 120
## HP tank rather than doc 08's 3.5" — and then gives the same encounter M01
## Tank Swap, whose whole effect is +50% damage taken per stack. At the swap
## threshold the tank is taking 2.5x, so the 4.9-round clock is really about
## two rounds, at the one gear stage in the game where nobody has any healing
## throughput. The mechanic was priced at zero when the swing was chosen.
##
## Measured, one factor at a time, with the squad the game hands you:
##
##     as authored          0/20        no m01              13/20
##     swing 15 -> 10      10/20
##
## So M01 is the whole of it, and either lever alone is enough. That is the
## designer's choice to make and it is a short one: drop the mechanic from the
## tutorial (and TR stops teaching the swap, which §9.1 says is its payload),
## or re-price the swing WITH the multiplier included.
##
## Changing either number is a balance judgement, and docs/15 records exactly
## one number ever changed on judgement alone (BL-29) with the bar being that
## there stays one. So this asserts the defect, with its measurement, until a
## designer rules — the same shape as the A3 pin and as LIES_OWED in
## test_project_hygiene.gd. Flip it back to `>= 8` the day the numbers move.
##
## THE MEASUREMENT MOVED ONCE WITHOUT A NUMBER MOVING, and this records it. The
## 0/20 above was measured at the FULL mistake rate. docs/15's tutorial-rate ruling (DECIDED,
## "reduced rate for both tutorials") landed in the sim with W5-SIM at
## `Mistakes.TUTORIAL_MISTAKE_MULT` 0.5, and at half the mistakes one of the
## twenty seeds now clears: 1/20. Nothing about the swing or M01 changed, and
## 1/20 is not "winnable and losable" — the defect and the designer's choice are
## exactly as described above. The pinned value follows the measurement so the
## suite tells the truth (a gate red for a reason no loop may fix stops all
## work — LESSONS.md); the movement itself is the canon question recorded in
## build/plan/q-W5-SIM.md, because the 0.5 is the build loop's number and the
## designer may want the tutorial rate and the tutorial swing ruled together.
const TUTORIAL_RAID_CLEARS_AS_MEASURED := 1

func test_the_tutorial_raid_is_currently_unwinnable_and_that_is_recorded() -> void:
    var cleared := _clears("TR", _premade(6))
    assert_eq(cleared, TUTORIAL_RAID_CLEARS_AS_MEASURED,
        "the Tutorial Raid now clears %d/20. If that is the fix, restore this to "
        % cleared
        + "`assert_true(cleared >= 8)` and say so in docs/15; if it is not, its "
        + "swing or its mechanic needs a designer, not a loop.")
    assert_true(cleared < 8, "1/20 is still the defect; >= 8 is what winnable means here")

func test_one_tank_against_m01_degrades_out_loud_rather_than_crashing() -> void:
    # The composition trap in tanks_required 1: at 3 stacks there may be nobody
    # to swap to. RaidSim says so in the log and the tank keeps the stacks —
    # that IS the lesson, and it must never be an out-of-bounds.
    var res = RaidSim.run(_premade(6), _tut("TR"), _db, 4242)
    assert_ne(res, null, "the Tutorial Raid must resolve with a single tank")
    # The boss swings twice a round and each hit is a stack, so the swap is
    # demanded from round 2 — and with one tank every message on that path says
    # "stacks". The player has to be able to READ the mechanic; that is what the
    # Tutorial Raid is for.
    assert_true(res.log.transcript(Enums.LogTier.STORY).contains("stacks"),
        "M01 is the Tutorial Raid's whole payload and never reached the log")

# ---------------------------------------------------------------- the campaign

func _fresh_state():
    var s = GameStateScript.new()
    s.reset()
    s.set_content(_db)
    s.new_game("Tutorial Guild")
    return s

class _Result extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    var deltas_queued: Array = []
    var won: bool = false
    func cleared() -> bool: return won

func _win(party: Array):
    var res := _Result.new()
    res.won = true
    for r in party:
        res.deltas_queued.append({
            "raider_id": r.id, "runs_attended": 1, "wipes_witnessed": 0, "died": false,
        })
    return res

func test_a_tutorial_clear_never_drops_a_real_adventure_charm() -> void:
    # The hazard: `Loot.drop_pool` takes its non-raid branch for A0/TR, maps the
    # "trinket" loot slot to Slot.TRINKET and would return every tier-1
    # source=="adventure" trinket — Adventure's Charm of Health (+7 HP) and
    # Charm of Power (+2 Power). Those are the items docs/10 §9.2 says the crap
    # trinkets must be VISIBLY WORSE than, so rolling here would pay the
    # tutorials better loot than Adventure 1 and make the skip warning a lie.
    var s = _fresh_state()
    var party: Array = s.roster.slice(0, 4)
    s.record_attempt(_tut("A0").id, _win(party), party)
    for it in s.pending_loot:
        assert_false(String(it.id).begins_with("ITM_T1_ADV"),
            "a tutorial handed out %s, which is real Adventure loot" % it.id)
    s.free()

func test_the_tutorial_trinket_is_granted_once() -> void:
    # The grant is fixed, not rolled, and only on a FIRST clear (docs/10 §9.3:
    # replayable for gold, but the trinket is gone).
    #
    # THIS TEST USED TO BRANCH on whether the item rows existed, and they did
    # not: the grant, its guard and the drop-pool bypass had all shipped against
    # two ids that resolved to null, so a first clear handed over nothing and
    # every test still passed. The rows are `data/items_tutorial.json` now
    # (docs/09 §10.2 G12, docs/15 BL-77) and the branch is gone with them — a
    # test that passes either way is not a gate.
    var s = _fresh_state()
    var party: Array = s.roster.slice(0, 4)
    var expected_id := String(GameStateScript.TUTORIAL_TRINKET["A0"])
    assert_ne(_db.item(expected_id), null,
        "the id the grant names must be in the content set")

    s.record_attempt(_tut("A0").id, _win(party), party)
    assert_eq(s.pending_loot.size(), 1, "a first clear grants exactly one trinket")
    assert_eq(String(s.pending_loot[0].id), expected_id)

    s.record_attempt(_tut("A0").id, _win(party), party)
    assert_eq(s.pending_loot.size(), 1,
        "a repeat clear pays gold and drops nothing — docs/10 §9.3")
    s.free()


func test_each_tutorial_pays_its_own_documented_gold() -> void:
    # docs/11 §F2, verbatim: "Adventure 0: 4 G · Tutorial Raid: 8 G". Both paid
    # ZERO until this item — `Loot.payout` returns 0 for a slot in neither the
    # raid nor the adventure table, which is right for an unknown rung and was
    # silently wrong for the two the same doc line prices.
    var s = _fresh_state()
    var party: Array = s.roster.slice(0, 4)
    var before: int = s.gold
    s.record_attempt(_tut("A0").id, _win(party), party)
    assert_eq(s.gold - before, 4, "Adventure 0 pays 4 G on a first clear")
    assert_eq(s.last_payout, 4)

    before = s.gold
    s.record_attempt(_tut("TR").id, _win(party), party)
    assert_eq(s.gold - before, 8, "the Tutorial Raid pays 8 G on a first clear")

    # docs/11 §F5's decay applies to a tutorial like any other rung, because
    # docs/10 §9.3 keeps a resolved tutorial "replayable for gold".
    before = s.gold
    s.record_attempt(_tut("A0").id, _win(party), party)
    assert_true(s.gold - before < 4 and s.gold - before >= 1,
        "a repeat clear decays but never pays nothing")
    s.free()

func test_skipping_resolves_a_rung_and_only_ever_a_tutorial() -> void:
    var s = _fresh_state()
    var a0 := String(_tut("A0").id)
    assert_false(s.rung_resolved(a0))
    assert_true(s.skip_tutorial(a0), "canon makes the tutorials skippable")
    assert_true(s.rung_resolved(a0), "a skipped rung is resolved, so the ladder opens")
    assert_false(s.has_cleared(a0), "but it is NOT a clear")
    assert_true(s.skip_tutorial(a0), "skipping twice is idempotent, not an error")
    assert_eq(s.skipped_tutorials.size(), 1)

    # Per tutorial, not global (docs/10 §9.3's Granularity row).
    assert_false(s.rung_resolved(String(_tut("TR").id)),
        "skipping Adventure 0 must not skip the Tutorial Raid")
    # And nothing else in the game is skippable.
    assert_false(s.skip_tutorial("t1_adv_a1"), "a real rung cannot be skipped")
    assert_false(s.skip_tutorial("no_such_encounter"))
    assert_eq(s.skipped_tutorials.size(), 1)
    s.free()

func test_onboarding_completes_only_when_both_rungs_are_resolved() -> void:
    # This is the flag that arms a whole-roster wipe (docs/05 §6.3 via
    # Morale.may_disband), so every path into it is pinned.
    var a0 := String(_tut("A0").id)
    var tr := String(_tut("TR").id)

    var s = _fresh_state()
    assert_false(s.onboarding_complete, "a fresh guild is protected")
    var party: Array = s.roster.slice(0, 4)
    s.record_attempt(a0, _win(party), party)
    assert_false(s.onboarding_complete, "Adventure 0 alone is not onboarding")
    s.record_attempt(tr, _win(party), party)
    assert_true(s.onboarding_complete, "clearing both completes it")
    s.free()

    # A skip counts. docs/05 §6.3 says "completed" and a skip is not a
    # completion, but docs/01 §8.3 and docs/15 Q-90 make the skip permanent, so
    # a player who skipped both would otherwise be exempt from disband forever.
    var s2 = _fresh_state()
    s2.skip_tutorial(a0)
    assert_false(s2.onboarding_complete)
    s2.skip_tutorial(tr)
    assert_true(s2.onboarding_complete, "skipping both still completes onboarding")
    s2.free()

    # And the mixed path, which is the one a real player is likeliest to take.
    var s3 = _fresh_state()
    var party3: Array = s3.roster.slice(0, 4)
    s3.record_attempt(a0, _win(party3), party3)
    s3.skip_tutorial(tr)
    assert_true(s3.onboarding_complete, "clear one, skip the other")
    s3.free()

func test_a_wiped_tutorial_does_not_complete_onboarding() -> void:
    var s = _fresh_state()
    var party: Array = s.roster.slice(0, 4)
    var lost := _Result.new()
    for r in party:
        lost.deltas_queued.append({
            "raider_id": r.id, "runs_attended": 1, "wipes_witnessed": 1, "died": false,
        })
    s.record_attempt(String(_tut("A0").id), lost, party)
    s.record_attempt(String(_tut("TR").id), lost, party)
    assert_false(s.onboarding_complete, "attempting is not resolving")
    s.free()

func test_a_skip_survives_a_save_and_an_old_save_loads_with_none() -> void:
    var s = _fresh_state()
    s.skip_tutorial(String(_tut("A0").id))
    var body: Dictionary = s.to_dict()
    assert_true(body.has("skipped_tutorials"), "the skip list must be persisted")
    assert_true(int(body["save_version"]) >= 13,
        "the skip list is a save-shape change and owes a SAVE_VERSION bump")
    assert_eq(int(body["save_version"]), int(GameStateScript.SAVE_VERSION))
    s.free()

    var back = GameStateScript.new()
    back.reset()
    back.set_content(_db)
    assert_eq(back.from_dict(body).size(), 0, "the round trip must load clean")
    assert_true(back.rung_resolved(String(_tut("A0").id)),
        "a skip the player can undo by quitting to the menu is not a skip")
    back.free()

    # A v12 body carries no skip list at all, and the default IS the migration:
    # that guild never skipped anything, because the skip did not exist.
    var old: Dictionary = body.duplicate(true)
    old["save_version"] = 12
    old.erase("skipped_tutorials")
    var older = GameStateScript.new()
    older.reset()
    older.set_content(_db)
    assert_eq(older.from_dict(old).size(), 0)
    assert_eq(older.skipped_tutorials.size(), 0, "an old save skipped nothing")
    older.free()


# ---------------------------------------------------------------- the lesson, on screen (BL-141)

## Q15 as ruled: the two tutorials say their lesson where it happens. The
## words are DATA on the record (`lesson`, `lesson_report`, `title`) — no
## screen carries a literal — so this clause reads them off the record and
## asserts the screens print exactly those, on A0/TR, and nothing on A1.
## Mounted the way test_raid_beats.gd mounts a screen: the autoload GameState
## with a router host under the tree root; read through `Label.text`.

const Router = preload("res://game/core/ScreenRouter.gd")
const RaidView = preload("res://game/screens/RaidView.gd")
const RAID_VIEW := "res://game/screens/RaidView.tscn"
const RESULTS := "res://game/screens/Results.tscn"

var _made: Array = []


func _screen_state():
    var root: Node = (Engine.get_main_loop() as SceneTree).root
    var st = root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        root.add_child(st)
        _made.append(st)
    if root.get_node_or_null("ScreenRouter") == null:
        var r = Router.new()
        r.name = "ScreenRouter"
        root.add_child(r)
        _made.append(r)
    st.reset()
    st.set_content(_db)
    st.new_game("Lesson Guild", 31)
    return st


## A state whose last attempt is at `slot`, fought by the squad the game hands
## you, with the outcome forced when asked (the report's branches are the
## outcome's, and TR clears rarely — test above).
func _attempted(slot: String, force_outcome: int = -1):
    var st = _screen_state()
    var enc = _tut(slot) if slot in ["A0", "TR"] else _db.encounter_at_slot(slot)
    var party: Array = _premade(int(enc.party_size)) if slot in ["A0", "TR"] \
        else st.roster.slice(0, mini(int(enc.party_size), st.roster.size()))
    var result = RaidSim.run(party, enc, _db, 4000)
    if force_outcome >= 0:
        result.outcome = force_outcome
    st.last_result = result
    st.last_party = party.duplicate()
    st.selected_encounter_id = String(enc.id)
    return st


func _mount(path: String) -> Control:
    var root: Node = (Engine.get_main_loop() as SceneTree).root
    var host := Control.new()
    host.size = Vector2(1536, 1024)
    root.add_child(host)
    _made.append(host)
    var r = Router.new()
    _made.append(r)
    r.register_host(host)
    assert_true(r.goto(path), "%s must mount" % path)
    return r.current_screen()


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


func _named(n: Node, name: String, out: Array = []) -> Array:
    if String(n.name) == name:
        out.append(n)
    for c in n.get_children():
        _named(c, name, out)
    return out


func test_the_lesson_words_are_the_records_and_the_ruled_ones() -> void:
    # BL-141's words, verbatim, on the data — and nowhere in the screens.
    var a0 = _tut("A0")
    var tr = _tut("TR")
    assert_eq(String(a0.lesson),
        "Round three: somebody does something stupid. Watch for the stamp — the log says who, and why.")
    assert_eq(String(tr.lesson),
        "One trick, one timer, one tank between six of them. When it goes wrong, the report says who.")
    assert_eq(String(tr.lesson_report),
        "This is the Wipe Report. Who, what, and which round — it is all under 'By raider'.")
    assert_eq(String(a0.lesson_report), "", "A0's page has no report line")
    assert_eq(String(tr.title), "The Doorman", "BL-119: TR's rung carries its role title")
    assert_eq(String(a0.title), "", "a trash mob has no title")
    for enc in _db.adventure_encounters(1) + _db.raid_encounters(1):
        assert_eq(String(enc.lesson), "", "%s carries no lesson" % enc.slot)
    for src in ["res://game/screens/RaidView.gd", "res://game/screens/Results.gd"]:
        var code := FileAccess.get_file_as_string(src)
        assert_false(code.contains("somebody does something stupid"), src + " carries no lesson literal")
        assert_false(code.contains("This is the Wipe Report"), src + " carries no lesson literal")


func test_the_band_shows_the_lesson_on_a0_and_tr_and_not_on_a1() -> void:
    assert_true(RaidView.TUTORIAL_BAND, "the ruling: the band ships")
    for slot in ["A0", "TR"]:
        var st = _attempted(slot)
        var enc = _tut(slot)
        var view := _mount(RAID_VIEW)
        var bands := _named(view, "LessonBand")
        assert_eq(bands.size(), 1, "%s: one band above the log" % slot)
        var words := _named(bands[0], "Lesson")
        assert_eq(words.size(), 1)
        assert_eq((words[0] as Label).text, String(enc.lesson),
            "%s: the band's Label is the record's lesson" % slot)
        assert_true(_texts(view).has(String(enc.lesson)))
        assert_true(st.last_result != null)
    var st1 = _attempted("A1")
    assert_true(st1.last_result != null)
    var plain := _mount(RAID_VIEW)
    assert_eq(_named(plain, "LessonBand").size(), 0, "A1 is not a tutorial: no band")
    assert_false(_texts(plain).has(String(_tut("A0").lesson)))


func test_the_report_line_shows_on_trs_wipe_and_not_on_its_clear_or_on_a0() -> void:
    var st = _attempted("TR", RaidSim.Outcome.WIPE)
    assert_false(st.last_result.cleared())
    var page := _mount(RESULTS)
    var lines := _named(page, "LessonReport")
    assert_eq(lines.size(), 1, "TR's wipe page says what the page is")
    assert_true(_texts(page).has(String(_tut("TR").lesson_report)), "…in the record's words, as a Label")
    var cleared = _attempted("TR", RaidSim.Outcome.VICTORY)
    assert_true(cleared.last_result.cleared())
    var clear_page := _mount(RESULTS)
    assert_eq(_named(clear_page, "LessonReport").size(), 0, "over a clear the line would be false")
    assert_false(_texts(clear_page).has(String(_tut("TR").lesson_report)))
    var a0 = _attempted("A0", RaidSim.Outcome.WIPE)
    assert_false(a0.last_result.cleared())
    var a0_page := _mount(RESULTS)
    assert_eq(_named(a0_page, "LessonReport").size(), 0, "A0 has no report line to print")
