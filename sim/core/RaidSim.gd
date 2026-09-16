class_name TwgRaidSim
extends RefCounted
## The fight. A pure function of (roster, gear, encounter, seed) -> event log.
##
## docs/07 §4 is the specification. Nothing here touches a Node, a timer or the
## clock; the raid view is a player for the log this produces, which is what
## makes speed controls, pause and skip trivial (docs/14 §3).
##
## Two structural rules from docs/07 shape everything below:
##
## **Sequential resolution with immediate application** (§4.2). Each actor reads
## live state at the instant it acts and its effects land before the next actor
## reads state. The alternative — collect intents against a start-of-round
## snapshot, then apply — produces a heal that lands after the death it was meant
## to prevent, the player reads the log and concludes the game is broken.
##
## **No mid-raid input** (docs/15 Q-09). The raid resolves on the roster, gear and
## morale it started with. The player's decisions were all made before the pull.

const Enums = preload("res://sim/model/Enums.gd")
const Formulas = preload("res://sim/core/Formulas.gd")
const Mistakes = preload("res://sim/core/Mistakes.gd")
const Combatant = preload("res://sim/model/Combatant.gd")
const Consumables = preload("res://sim/core/Consumables.gd")
const EventLog = preload("res://sim/core/EventLog.gd")
const MistakeLines = preload("res://sim/content/MistakeLines.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const Quirks = preload("res://sim/core/Quirks.gd")

static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/core/RaidSim.gd")
    return _self_script


## docs/07 §10.3's line corpus, read once and shared read-only.
##
## `MistakeLines.load_from` parses a 36KB JSON file. The balance sweep runs 1,440
## encounters, so re-reading it per fight would be by far the most expensive
## thing in the sim. Cached like `_self_script` above, and for the same reason:
## it is CONTENT — immutable, identical for every run — so two runs sharing it
## cannot make fight 2 depend on fight 1, which is the property house rule 6 and
## tests/unit/test_raid_sim.gd's purity tests actually defend. The per-encounter
## state is the shuffle BAG, and `run()` builds a fresh one every time.
static var _lines_pool = null
static func _lines():
    if _lines_pool == null:
        _lines_pool = MistakeLines.load_from()
    return _lines_pool

## docs/07 §7.3: the round cap is a safety property, not flavour. No combination
## of roster, gear and encounter may produce an unbounded loop.
const ROUND_CAP := 40

## docs/07 §7.3: with no healer left and the boss still healthy the sim calls it
## rather than simulating fifteen hopeless rounds.
const SOFT_WIPE_BOSS_HP_FRACTION := 0.40

# ------------------------------------------------- docs/10 §10 mechanic switches
#
# Every number in the twelve-mechanic vocabulary is authored per encounter. The
# constants below are the places where docs/10 §10's spec column is AMBIGUOUS
# rather than silent, so each one is a documented default behind a name, each
# recorded in docs/15 (BL-82..BL-89; the entries were promoted from
# build/plan/q-mech-arms.md at the wave-6 close — house rule 1).

## docs/10 §10 M05 says only that "effect `E` fires" and never names E, so the
## payload is authored per encounter (`{"kind": ..., "amount": ...}`). This
## supplies the KIND when an author gives an amount without one; the amount
## itself is never synthesised, so an unauthored effect is a demand with no
## teeth rather than a number this file invented. docs/15 BL-83; E4's missing
## effect is audit m6-e4-m05-effect.
const INTERRUPT_EFFECT_DEFAULT_KIND := "raid_damage"

## docs/07 §5.2 row 5: a wrong interrupt leaves "interrupt on cooldown 2 rounds".
const INTERRUPT_COOLDOWN_ROUNDS := 2

## docs/10 §10 M01 gives the stacks and the swap and never says the stacks come
## off. Without decay the mechanic works exactly twice — both tanks reach the
## swap threshold and there is nowhere left to swap to. One per round off duty
## mirrors one per hit on duty. docs/15 BL-84 (which also records: no cap).
const TANK_DEBUFF_DECAY_PER_ROUND := 1

## M01 on an encounter that cannot field a second tank: does it engage at all?
##
## CANON PUTS IT THERE TWICE, both times with one tank. docs/10 §8's A3 row
## gives the mini boss M01 at `tanks_required: 1` on a party of six, and §9.1's
## Tutorial Raid row gives it M01 at one tank on a party of four. So this is not
## an authoring slip on one encounter; it is how the vocabulary was written down.
##
## Taken literally the stacks never leave — there is nobody to hand them to — so
## the holder reaches the cap and dies. Measured: A3 clears 24/24 with the
## mechanics inert and 0/24 with m01 alone live. Applied to the Tutorial Raid
## that reading contradicts the same doc's stated intent for that exact
## encounter, in its own words: its swing is held under budget because "a
## tutorial demonstrates a fail state, it does not impose one" (docs/10 §9.1).
## An unwinnable tutorial imposes one.
##
## Two canon requirements, no winner, so the project's rule applies: behind a
## switch, with the reading that keeps canon's own ladder walkable, and the
## question held for a designer: docs/15 BL-85 records it (the ship plan's
## designer table, §6 rows #1 and #9, asks it); audit `M6-BAL-03` owns the
## ruling, and `tests/unit/test_tutorials.gd` pins the measurement either way.
## TRUE: M01 needs a partner, and SAYS SO in the transcript when it has none, so
## the star is inert but never silently inert — which is what docs/10 §6 forbids.
## FALSE: the stacks arrive regardless and the composition punishment is lethal,
## which is the literal §10 reading.
## A `static var` rather than a `const` so BOTH readings stay under test: the
## two tests that pin the literal §10 punishment flip it off, prove the stacks
## kill, and flip it back. A switch only one side of which is exercised is a
## switch that has quietly become a constant.
static var TANK_SWAP_NEEDS_A_PARTNER := true

## docs/10 §10 M11 is "all melee-positioned raiders" and stresses "Rogue, Monk,
## Warrior". The Warrior is the tank in every canon composition, so a reading
## that spares the tank contradicts the row's own second column. docs/15 BL-88;
## who counts as "in front" is BL-93 (the one melee predicate).
const FRONTAL_CLEAVE_INCLUDES_TANK := true

## docs/10 §10 M10 is two mechanics in one row: a silence window, and "casters
## lose `X` Mana per round". The drain half needs the Focus pool docs/15 Q-02
## chose — `Formulas.MANA_MODEL` is MAGNITUDE_PLUS_FOCUS and its docstring says
## Focus "never appears on an item" — and no pool exists: no field, no
## class-fixed values, no spend. Faking one inside a mechanic arm would
## contradict the documented model, so the drain stays off: docs/15 BL-87
## (M10 ships as a Silence; Focus and the drain half are post-1.0 in writing).
const MANA_BURN_DRAIN_ENABLED := false

## docs/10 §10 M12 has "no cap", so the escalation is ANNOUNCED on a cadence
## rather than every round. Twenty lines of "the swing is bigger" is a wall, not
## a story beat; the swing itself grows every round regardless. docs/15 BL-89.
const ESCALATION_ANNOUNCE_EVERY := 5

enum Outcome { VICTORY, WIPE, SOFT_WIPE, ATTRITION }

const OUTCOME_KEYS := ["victory", "wipe", "soft_wipe", "attrition"]

## docs/01 §6.1: "an extra −4 to the raider whose mistake triggered the wipe".
## The NUMBER is canon's and `Morale.TRIGGERS["wipe_caused"]` already carries it
## (tests/unit/test_raid_sim.gd pins the two equal); the RULE for "whose mistake
## triggered the wipe" is nowhere in canon and is this file's, behind
## `_wipe_cause` (ship plan §6 row #61; docs/15 BL-107): the last
## Severe-or-worse mistake before the first tank or healer death, else the
## deepest cascade, else nobody — the boss simply won. The sim only REPORTS
## (docs/14 OQ-10): `SimResult.wipe_cause` names the entry and `deltas_queued`
## marks the culprit `wipe_caused`; `game/` applies the delta.
const WIPE_CULPRIT_DELTA := -4

# ------------------------------------------------- docs/07 §5.2's consequences
#
# Eight types used to print their line and change nothing (SIM-07, SIM-15,
# SIM-17). Where the effect column gives a direction and no number, the number
# is here behind a name, recorded in docs/15 (W7-SIM-EFFECTS's row).

## docs/07 §5.2 row 9, MIS_AFK: "No action for 1-3 rounds (severity picks
## duration)." Indexed by Enums.Severity; the rounds AFTER the one the roll
## fell in, since Phase 6 comes after every action of its own round.
const AFK_ROUNDS_BY_SEVERITY := [1, 2, 3, 3]

## docs/07 §5.2 row 16, MIS_ARGUMENT: "Both this raider and one random other
## take a mistake-chance penalty for the rest of the encounter." Basis points
## on the situational term (docs/08's `SITUATIONAL_CAP_BP` still caps the sum);
## SET on both rather than stacked, so a second argument does not double it.
const ARGUMENT_PENALTY_BP := 500

## docs/07 §8.1: "Warrior taunt is on a short cooldown." Rounds, in the shape
## of `INTERRUPT_COOLDOWN_ROUNDS`: used at R, blocked through R + 2.
const TAUNT_COOLDOWN_ROUNDS := 2

## docs/15 Q-58: the Shaman's chain "skips anyone above 95% HP" on hops 2-3.
## Hop 1 is unfiltered — the neediest is the neediest at any fraction.
const CHAIN_SKIP_ABOVE := 0.95


## An enemy in the fight. Adds spawned by M04 are appended mid-encounter.
class Enemy extends RefCounted:
    var name: String = ""
    var hp: int = 0
    var max_hp: int = 0
    var raw_swing: int = 0
    var swings_per_round: int = 1
    var threat_rule: String = "standard"
    var spawn_round: int = 0
    var active: bool = true
    ## Adds are the fight's second priority, not part of the fight itself
    ## (docs/10 §7 split rule 2). Tagged rather than inferred, because the two
    ## things that make an enemy an add — an M04 spawn and a mistake's Loose Add
    ## — arrive by different paths and neither is visible from the array.
    var is_add: bool = false
    ## docs/07 §8.2's hysteresis needs a memory: the slot this enemy is
    ## currently hitting, so a candidate has to CLEAR `should_retarget`'s
    ## 1.10 / 1.30 bar rather than merely edge past the table's top. -1 until
    ## the first swing. Only the standard-threat rule reads it.
    var target_slot: int = -1

    func is_alive() -> bool:
        return hp > 0

    func hp_fraction() -> float:
        return float(hp) / float(maxi(1, max_hp))


## What the sim reports. docs/14 OQ-10: the sim REPORTS, `game/` acts — nothing
## here writes to a Raider record, so a run can be replayed or discarded freely.
class SimResult extends RefCounted:
    var outcome: int = Outcome.WIPE
    var rounds: int = 0
    var log = null                    # EventLog
    var seed_used: int = 0
    var encounter_id: String = ""
    var survivors: Array = []         # Combatants still alive
    var casualties: Array = []        # Combatants dead
    var mistake_count: int = 0
    var damage_dealt: int = 0
    var healing_done: int = 0
    ## docs/11 §7's healing potions the sim actually spent, so `game/` deducts what
    ## was drunk rather than what was carried.
    var potions_spent: int = 0

    ## Per-raider counter/morale changes for `game/` to apply. Never applied here.
    ## Every row carries `loot_call` (docs/07 §5.2 row 17's post-encounter
    ## morale event, counted per raider) beside `wipe_caused`.
    var deltas_queued: Array = []

    ## docs/07 §5.2 row 15: a forgotten consumable "is not consumed". One row
    ## per provision that never left the bag — `{raider_id, sku, reason}`,
    ## reason `no_consumable` here; W8-SIM-BALANCE adds `ninja_pulled`
    ## (docs/15 BL-116). `game/` decides what comes home.
    var consumables_unspent: Array = []

    ## Why it wiped, for the report (LOOP-12, CRITIC-C12): `{actor_id,
    ## mistake_type, round, entry_seq}` naming one log entry, by the rule at
    ## `WIPE_CULPRIT_DELTA`. Empty on a clear, and empty on a loss nobody's
    ## mistake can be pinned to — "nobody; the boss simply won" is an honest
    ## sentence and the report is expected to carry it.
    var wipe_cause: Dictionary = {}

    func cleared() -> bool:
        return outcome == Outcome.VICTORY

    func outcome_key() -> String:
        return TwgRaidSim.OUTCOME_KEYS[outcome]

    func summary() -> String:
        return "%s in %d rounds — %d mistakes, %d survivors" % [
            outcome_key(), rounds, mistake_count, survivors.size()]


# ================================================================ entry point

## Run one encounter to completion. Deterministic for a given seed.
## `loadout` is docs/11 §7's committed consumables, already resolved to plain numbers
## by `Consumables.new_loadout()`. An EMPTY loadout leaves this function
## byte-identical — every golden file depends on that, and a test asserts it.
##
## `opts` is the run's switches, as a dictionary so a caller that knows none
## of them passes nothing (every sweep and golden caller). Read here:
##   legendary_quirks   docs/14 §5.2's flag for the quirk seam (Q58-4); the
##                      campaign passes `GameState.flag_enabled(Quirks.FLAG_ID)`.
##                      Default `Quirks.DEFAULT_ENABLED`; identity while
##                      `Quirks.SPECS` is empty, at either setting.
## W8-SIM-BALANCE reads `difficulty_mult` and `ninja_pulled` from the same
## dictionary (docs/15 BL-113, BL-116); W7-SAVE's replay passes them back.
static func run(roster: Array, encounter, db, seed_value: int,
        loadout: Dictionary = {}, opts: Dictionary = {}):
    var result = SimResult.new()
    result.seed_used = seed_value
    result.encounter_id = encounter.id
    result.log = EventLog.new()

    var rng_master = load("res://sim/core/Rng.gd").new(seed_value)
    var quirks_enabled := bool(opts.get("legendary_quirks", Quirks.DEFAULT_ENABLED))
    var combatants := _build_combatants(roster, db, loadout, int(encounter.tier),
        quirks_enabled)
    var pouch := _new_pouch(loadout)
    var mstate := _new_mechanic_state()
    mstate["quirks_enabled"] = quirks_enabled
    # docs/07 OQ-9's ruling: the two onboarding rungs roll at a reduced rate. Read once
    # here for the two roll sites that build their Context by hand (ambient and
    # encounter start, which never see the encounter); `_context` asks the same
    # predicate for the other three.
    mstate["tutorial"] = _is_tutorial(encounter)
    # docs/10 §10 M03: is there a fire to stand in? The two hand-built contexts
    # (ambient, encounter start) read it from here; `_context` asks the card.
    mstate["zone_exists"] = encounter.has_mechanic(Enums.Mechanic.GROUND_EFFECT)
    # docs/07 §10.3's shuffle bag, one per encounter, so a bad raid does not
    # print the same joke nine times. `derive` is a pure function of the master
    # seed and consumes no draws from the parent stream (sim/core/Rng.gd
    # §derivation), so drawing a line cannot move a single simulation outcome —
    # only the strings the log carries. 228 authored lines and nothing called
    # this: no joke had ever reached the screen.
    mstate["jokes"] = MistakeLines.Bag.new(_lines(),
        rng_master.derive("mistake_line", 0, 0))
    var enemies := _build_enemies(encounter)
    _assign_tanks(combatants, db)

    var log = result.log
    log.emit_system(0, "%s begins." % encounter.display_name)

    # docs/07 §5.3: MIS_NO_CONSUMABLE is a one-shot ambient roll before round 1.
    # Its consequence — the provision stripped and reported — lands through
    # `_apply_mistake` into `mstate["consumables_unspent"]`, copied out below.
    mstate["consumables_unspent"] = []
    _roll_encounter_start_mistakes(rng_master, combatants, db, log, mstate)

    var round_no := 0
    while round_no < ROUND_CAP:
        round_no += 1
        _run_round(rng_master, round_no, combatants, enemies, encounter, db, log,
            result, pouch, mstate)

        var verdict := _check_end(combatants, enemies, encounter, round_no, log)
        if verdict >= 0:
            result.outcome = verdict
            break
        if round_no >= ROUND_CAP:
            result.outcome = Outcome.ATTRITION
            log.emit_system(round_no, "The raid runs out of time.")

    result.rounds = round_no
    for c in combatants:
        if c.is_dead():
            result.casualties.append(c)
        else:
            result.survivors.append(c)
    result.potions_spent = int(pouch["spent"])
    result.consumables_unspent = mstate["consumables_unspent"]
    result.mistake_count = log.mistakes().size()
    result.damage_dealt = log.sum_numbers(Enums.Verb.ATTACK, "amount")
    result.healing_done = log.sum_numbers(Enums.Verb.HEAL, "amount")
    if result.outcome != Outcome.VICTORY:
        result.wipe_cause = _wipe_cause(log, combatants)
        _log_wipe_cause(log, round_no, result.wipe_cause)
    _queue_deltas(result, combatants)
    return result


# ================================================================ setup

static func _build_combatants(roster: Array, db, loadout: Dictionary = {},
        tier: int = 1, quirks_enabled: bool = Quirks.DEFAULT_ENABLED) -> Array:
    var out := []
    var slot := 0
    var relief: Dictionary = loadout.get("mistake_relief_bp", {})
    for raider in roster:
        var c = Combatant.create(raider, db, slot)
        c.set_meta("profile", _gear_profile(raider, db, loadout, tier))
        # docs/04 §11.2's quirk seam (Q58-4). The id follows the convention
        # `LegendaryPool._validate_quirk` enforces on every authored file, so
        # the sim resolves it from `legendary_def_id` without carrying the
        # pool; "" for everybody else, and every hook is identity on "".
        c.set_meta("quirk_id", Quirks.expected_id_for(int(raider.class_id))
            if not String(raider.legendary_def_id).is_empty() else "")
        c.set_meta("quirks_enabled", quirks_enabled)
        # docs/11 §7's Guild Feast: "The attempt is simulated using each participant's
        # morale +5. Stored morale is unchanged." So the number lives on the combatant
        # and never touches the raider.
        c.set_meta("sim_morale", clampi(
            raider.morale + int(loadout.get("morale_bonus", 0)),
            Enums.MORALE_MIN, Enums.MORALE_MAX))
        c.set_meta("relief_bp", float(relief.get(raider.id, 0.0)))
        # docs/07 OQ-7's abstract position model (docs/15 BL-82):
        # melee are Stacked on the boss, everyone else is Spread. Derived from
        # the class rather than authored, so an encounter with no M07 has a
        # stance nothing reads and every existing golden stays byte-identical.
        c.stance = Enums.Stance.STACKED if Consumables.is_melee_class(raider.class_id) \
            else Enums.Stance.SPREAD
        out.append(c)
        slot += 1
    return out


## docs/11 §7's Minor Healing Potions, held for the whole encounter. A plain local in
## `run()`, threaded down: the alternative was file-level state, and `sim/` staying
## pure means two runs can never share a pouch.
static func _new_pouch(loadout: Dictionary) -> Dictionary:
    return {
        "count": int(loadout.get("potion_count", 0)),
        "heal_pct": float(loadout.get("potion_heal_pct", 0.0)),
        "spent": 0,
        "used": {},
    }


## Everything the formulas need about a raider's gear, resolved once.
##
## `tier` is the ENCOUNTER's (SIM-22): `Formulas.damage_after_ac` and
## `spell_damage_total` take it, and until it travelled here a Tier 3 fight
## mitigated exactly like Tier 1 (docs/15 BL-72's `AC_K` step and
## `MANA_TO_SPELL` decay were reached by tests and the budget tool only).
## `power_bonus` / `mana_bonus` are kept beside the folded totals so
## MIS_NO_CONSUMABLE can take them back out (docs/07 §5.2 row 15).
static func _gear_profile(raider, db, loadout: Dictionary = {}, tier: int = 1) -> Dictionary:
    var stats = raider.gear_stats(db)
    # docs/11 §7: the Whetstone Kit is "+1 Power to every melee participant (Warrior,
    # Monk, Rogue, Bard)" and the Mana Draught is "+10 Mana to every caster and healer
    # participant". Folded in here so every formula downstream sees them without
    # knowing consumables exist.
    var power_bonus := 0
    var mana_bonus := 0
    if Consumables.is_melee_class(raider.class_id):
        power_bonus = int(loadout.get("power_bonus", 0))
    else:
        mana_bonus = int(loadout.get("mana_bonus", 0))
    var main = raider.item_in(db, Enums.Slot.MAIN_HAND)
    var off = raider.item_in(db, Enums.Slot.OFF_HAND)
    var cd = db.class_of(raider.class_id)
    return {
        "ac": stats.ac, "power": stats.power + power_bonus,
        "mana": stats.mana + mana_bonus,
        "power_bonus": power_bonus, "mana_bonus": mana_bonus,
        "main_damage": main.stats.damage if main != null else 0,
        "off_damage": off.stats.damage if off != null else 0,
        "heal_base": main.heal_base if main != null else 0,
        "dual_wield": cd.dual_wield if cd != null else false,
        "class_id": raider.class_id,
        "role_group": cd.role_group if cd != null else Enums.RoleGroup.DPS,
        "tier": maxi(1, tier),
    }


static func _build_enemies(encounter) -> Array:
    var out := []
    for block in encounter.enemies:
        for i in block.count:
            var e := Enemy.new()
            e.name = block.name if block.count == 1 else "%s %d" % [block.name, i + 1]
            e.hp = block.hp
            e.max_hp = block.hp
            e.raw_swing = block.raw_swing
            e.swings_per_round = block.swings_per_round
            e.threat_rule = block.threat_rule
            e.spawn_round = block.spawn_round
            e.active = block.spawn_round == 0
            # `lowest_hp` is the data's own marker for an add: docs/10 §7 says
            # adds "exist as healer pressure" and hunt the weakest raider, and
            # `Encounter.primary_raw_per_round` already excludes exactly these
            # blocks from the tank-channel budget for that reason.
            e.is_add = block.threat_rule == "lowest_hp"
            out.append(e)
    return out


## Canon requires two tanks for most fights. The Warrior is the main tank; a Monk
## is the canon offtank ("High DPS + emergency tank").
static func _assign_tanks(combatants: Array, db) -> void:
    var main_done := false
    # docs/04 §11.2's quirk seam (Q58-4), `tank_priority`: among the Warriors
    # the highest bump takes the main-tank seat, ties to slot order — which,
    # with every bump at 0 (identity), is exactly the first Warrior brought.
    var main = null
    var main_priority := 0
    for c in combatants:
        var p: Dictionary = c.get_meta("profile")
        if int(p["class_id"]) != Enums.CharClass.WARRIOR:
            continue
        var bump: int = Quirks.tank_priority(_quirk_id(c), _quirks_on(c))
        if main == null or bump > main_priority:
            main = c
            main_priority = bump
    for c in combatants:
        var p: Dictionary = c.get_meta("profile")
        if int(p["class_id"]) == Enums.CharClass.WARRIOR:
            if c == main:
                c.is_main_tank = true
                main_done = true
            else:
                c.is_offtank = true
    if not main_done:
        # No Warrior brought. A Monk offtanks; otherwise whoever has most HP.
        for c in combatants:
            if int(c.get_meta("profile")["class_id"]) == Enums.CharClass.MONK:
                c.is_main_tank = true
                main_done = true
                break
    if not main_done and not combatants.is_empty():
        var best = combatants[0]
        for c in combatants:
            if c.max_hp > best.max_hp:
                best = c
        best.is_main_tank = true
    # docs/10 §10 M01 needs to know whose TURN it is, not only who the raid
    # brought. The main tank starts on the boss; the swap moves the flag from
    # there, and `_resolve_tank_swap` re-seats it if the holder dies.
    for c in combatants:
        if c.is_main_tank:
            c.is_active_tank = true


# ================================================================ the round

## Guard state that must OUTLIVE a single roll, or docs/07 §5.5's anti-spam
## rules are decorative. `criticals` is raid-wide for the round; per-type
## cooldowns live on each combatant and persist across rounds.
static func _new_round_state() -> Dictionary:
    # `forced_slot` is docs/10 §9.1's scripted mistake: the slot that makes it
    # this round, or -1. Per round by construction — `force_mistake_round` is
    # one round number — so the once-only guard is the round state's lifetime.
    return {"criticals": 0, "forced_slot": -1}


## Mechanic state that must outlive a round: who the boss is chasing, which
## stance the script is demanding, and how much the fight's swing has been
## multiplied. Threaded exactly like `pouch` — a plain local in `run()` passed
## down — and never file-level, because two runs sharing it would make fight 2
## depend on fight 1 and the goldens would stop meaning anything (house rule 6).
##
## Per-RAIDER mechanic state does NOT live here. M01's stacks, M09's healing
## reduction and M10's silence are fields on `Combatant`, because all three are
## facts about one person that a mid-raid save has to carry (docs/14 OQ-11).
static func _new_mechanic_state() -> Dictionary:
    return {
        # M08 Fixate: the slot the boss is chasing and the last round it cares.
        "fixate_slot": -1,
        "fixate_until": 0,
        # M06 Enrage's multiplier, kept AFTER the round it fired. The arm
        # multiplies the enemies present at that instant, so an M04 add
        # spawning on E5's round 20 swung its authored 9 in a fight where
        # everything else had doubled on round 31 — or would have, on a seed
        # that got there. Spawns read this instead.
        "swing_mult_pct": 100,
        # M07 Positioning: the demanded stance and the last round of the window.
        "stance_required": -1,
        "stance_until": 0,
    }


static func _run_round(rng, round_no: int, combatants: Array, enemies: Array,
        encounter, db, log, result, pouch: Dictionary = {},
        mstate: Dictionary = {}) -> void:
    var round_state := _new_round_state()
    # -- Phase 0: Round Open -------------------------------------------------
    log.emit_phase(round_no, Enums.Phase.ROUND_OPEN)
    _spawn_scheduled(round_no, enemies, encounter, log, mstate)
    _apply_scheduled_mechanics(rng, round_no, combatants, enemies, encounter, log, mstate)

    # -- Phase 0b: the mechanic checks this round demands ---------------------
    # docs/07 §5.3(b)'s roll site, after the announcements that create the
    # demand and before the boss acts on it. It is still Round Open: the check
    # is "did you respond to what the script just asked for", so a raider who
    # fails it is already standing in the wrong place when Phase 1 resolves.
    var failed := _phase_mechanic_checks(rng, round_no, combatants, enemies,
        encounter, log, round_state, mstate)

    # -- Phase 0c: and what the answers cost ----------------------------------
    # The four mechanics that DEMAND a response cannot resolve with the others
    # above: whether the swap happens, whether the cast is interrupted and
    # whether a raider is standing in the right place are all answers to checks
    # that have only just been rolled.
    _resolve_demanded_mechanics(round_no, combatants, enemies, encounter,
        log, mstate, failed)

    # -- Phase 1: Boss acts (reads LIVE threat) ------------------------------
    _phase_boss(rng, round_no, combatants, enemies, encounter, log, mstate)
    if _all_down(combatants):
        return

    # -- Phase 2-3: raiders act ----------------------------------------------
    # docs/10 §9.1's scripted mistake is decided here, after the boss has
    # swung, so the raider it lands on is one who is still standing to act.
    if encounter.force_mistake_round > 0 and encounter.force_mistake_round == round_no:
        round_state["forced_slot"] = _pick_forced_mistake_slot(rng, round_no, combatants)
    _phase_actors(rng, round_no, combatants, enemies, encounter, db, log,
        [Enums.Phase.TANKS, Enums.Phase.DPS], round_state, mstate)

    # -- Phase 4: Healers act (read LIVE HP) ---------------------------------
    _phase_healers(rng, round_no, combatants, enemies, encounter, db, log,
        round_state, mstate)

    # -- Phase 5: Effects tick ------------------------------------------------
    _phase_effects(rng, round_no, combatants, encounter, log)

    # -- Phase 5b: the potion pouch (docs/11 §7's safety net) ------------------
    _phase_potions(round_no, combatants, log, pouch)

    # -- Phase 6: Ambient mistake roll ---------------------------------------
    _phase_ambient(rng, round_no, combatants, enemies, db, log, round_state, mstate)

    # -- Phase 7: Round Close -------------------------------------------------
    _phase_close(round_no, combatants, log)


## An authored EnemyBlock with a `spawn_round` and an M04 spec that fires on the
## same round are two spawn paths for one event, and both used to run: E1 round 5
## produced two adds where the card promises one, E2 round 4 produced six.
##
## docs/10 §10 makes M04 the add-spawn mechanic — "`count` adds of `hp`/`swing`
## on round `R`, repeating every `N`" — and docs/10 §6 prices one mechanic per
## star, so the star is what the player is told they bought. The mechanic
## therefore owns the round, and the block scheduled onto it stays inactive for
## the whole fight. A block on a round M04 does NOT fire still arrives: that is a
## scripted reinforcement, not a duplicate.
static func _spawn_scheduled(round_no: int, enemies: Array, encounter, log,
        mstate: Dictionary = {}) -> void:
    var owned_by_m04 := _add_spawns_fires_on(encounter, round_no)
    for e in enemies:
        if not e.active and e.spawn_round == round_no:
            if owned_by_m04:
                continue
            e.active = true
            # A reinforcement arriving after M06 arrives into the enraged
            # fight, not into the fight as it was authored.
            e.raw_swing = _spawn_swing(e.raw_swing, mstate)
            log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN,
                Enums.Mechanic.ADD_SPAWNS, "%s joins the fight." % e.name)


## An enemy's swing at the moment it joins a fight already in progress.
##
## docs/10 §10 M06 multiplies "boss damage x2 PERMANENTLY", and the arm applies
## that to the enemies present when it fires — so anything arriving later used
## to swing its authored value in a fight where everything else had doubled.
## Two spawn paths reach this: M04's adds and an authored `spawn_round` block.
static func _spawn_swing(raw: int, mstate: Dictionary) -> int:
    var pct := int(mstate.get("swing_mult_pct", 100))
    if pct == 100:
        return raw
    return int(round(float(raw) * float(pct) / 100.0))


## True when an M04 spec on this encounter spawns adds on `round_no`. One
## predicate, read by both the mechanic branch and the block suppression above,
## so the two can never disagree about which round is whose.
static func _add_spawns_fires_on(encounter, round_no: int) -> bool:
    for spec in encounter.mechanics:
        # The same `false` the ADD_SPAWNS arm passes. If these two ever
        # disagreed about an unscheduled spec, a block would be suppressed on a
        # round no add arrives on — the exact double-spawn confusion the one
        # predicate exists to prevent, running the other way.
        if spec.mechanic == Enums.Mechanic.ADD_SPAWNS \
                and _mechanic_fires(spec, round_no):
            return true
    return false


## What a spec that authors NO cadence means. docs/10 §10's spec column answers
## it one row at a time, and the three readings are not interchangeable.
enum Unscheduled { NEVER, ALWAYS, FROM_THE_PULL }


## Does this spec fire on this round? One question, one answer, for all twelve.
##
## `_mechanic_fires_this_round` below owns the CADENCE — `rounds`, `round`,
## `every`. What this adds is the reading of a spec with none of the three:
##
##   NEVER          M02 M04 M05 M06 M08 — "every `N` rounds", "on round `R`".
##                  No R, no fire: a spec that forgot its round must stay silent
##                  rather than firing forty times.
##   ALWAYS         M01 M03 M11 M12 — "swap required at 3", "`X`/round", "each
##                  round", "+`X` per round". Simply on.
##   FROM_THE_PULL  M07 M09 M10 — "for `N` rounds". A window with a length and
##                  no start.
##
## Both non-NEVER readings are load-bearing, and each was a live bug:
##
##   * The mechanic-check roll site passed a flat `false`, and neither M01 nor
##     M03 authors a schedule anywhere in Tier 1 (`data/encounters_t1.json` gives
##     m01 `{stack_damage_pct, swap_at}` and m03 `{damage_per_round,
##     escape_chance_bp}`) — so the two mechanics that most need a check
##     demanded nothing all fight, and m03's Fire token had no way in even after
##     its roll site existed.
##   * E4's m09 is `{"reduction_pct": 40, "rounds": 3, "target": "active_tank"}`,
##     where `rounds` is a DURATION. Under NEVER it never fires at all — armed
##     in the sim and dead on the only encounter that configures it, while
##     docs/10 §7.4's card says the debuff is on.
static func _mechanic_fires(spec, round_no: int) -> bool:
    match _unscheduled_reading(spec.mechanic):
        Unscheduled.ALWAYS:
            return _mechanic_fires_this_round(spec, round_no, true)
        Unscheduled.FROM_THE_PULL:
            if _has_cadence(spec):
                return _mechanic_fires_this_round(spec, round_no, false)
            return round_no == 1
    return _mechanic_fires_this_round(spec, round_no, false)


static func _unscheduled_reading(mechanic: int) -> int:
    match mechanic:
        Enums.Mechanic.TANK_SWAP, Enums.Mechanic.GROUND_EFFECT, \
                Enums.Mechanic.FRONTAL_CLEAVE, Enums.Mechanic.ESCALATING_SWING:
            return Unscheduled.ALWAYS
        Enums.Mechanic.POSITIONING, Enums.Mechanic.HEALING_DEBUFF, \
                Enums.Mechanic.MANA_BURN:
            return Unscheduled.FROM_THE_PULL
    return Unscheduled.NEVER


## Did the author say WHEN, in any of the three forms the cadence accepts? A
## bare `rounds: 3` is a duration and says nothing about when.
static func _has_cadence(spec) -> bool:
    var params: Dictionary = spec.params
    if int(params.get("round", 0)) > 0 or int(params.get("every", 0)) > 0:
        return true
    return typeof(params.get("rounds", null)) == TYPE_ARRAY


## How long a windowed mechanic lasts. `rounds` carries both meanings in the
## shipped data — a LIST of exact rounds (E5's m04 is `[10, 20]`) and a DURATION
## (E4's m08 is `5`) — and `int()` of an Array is a crash, not a zero. A window
## handed a list has no duration of its own and gets one round.
static func _duration_of(spec, default_rounds: int = 1) -> int:
    var raw = spec.params.get("rounds", null)
    if raw == null or typeof(raw) == TYPE_ARRAY:
        return default_rounds
    return maxi(1, int(raw))


## Whether a mechanic is ASKING something of the raid this round, which is not
## the same question as whether it FIRES this round. M07 announces once and then
## demands an answer for every round of the window it opened, so the check phase
## cannot simply reuse the fire test.
static func _mechanic_demands_now(spec, round_no: int, mstate: Dictionary,
        encounter, combatants: Array) -> bool:
    match spec.mechanic:
        Enums.Mechanic.POSITIONING:
            return int(mstate.get("stance_required", -1)) >= 0 \
                and round_no <= int(mstate.get("stance_until", 0))
    return _mechanic_fires(spec, round_no)


## Whether this mechanic is asking RAIDERS a question this round — one mechanic
## check each, rolled in `_phase_mechanic_checks`. Narrower than
## `_mechanic_demands_now`, which answers whether the mechanic is LIVE.
##
## M01 is the reason the two are not the same question. It is live every round
## of an E3 (the stacks climb on every boss swing and decay every round off
## duty) but docs/10 §7.3's own encounter card says "Standard threat, with M01
## overriding on stack 3" — the swap is an EVENT at the threshold, not a
## standing demand. Asking every round put two extra MECHANIC-site rolls per
## round into every m01 fight, and MECHANIC is the site MIS_FIRE rolls at: E3,
## which carries no ground effect at all, grew fire deaths out of a tank-swap
## mechanic. See `_phase_mechanic_checks` for the second half of that fix.
static func _check_demanded_now(spec, round_no: int, mstate: Dictionary,
        encounter, combatants: Array) -> bool:
    if not _mechanic_demands_now(spec, round_no, mstate, encounter, combatants):
        return false
    if spec.mechanic == Enums.Mechanic.TANK_SWAP:
        return _tank_swap_demanded(spec, combatants)
    return true


## docs/10 §10 M01: "swap required at 3". The tanks are asked to perform the
## swap on the round the holder reaches the authored threshold, and not before.
## A fight with one tank still asks — the demand is what makes the failure
## legible, and `_attempt_tank_swap` says out loud that there is nobody to swap
## with (docs/06's composition punishment).
## True when M01 can run on this roster at all: either the switch is off, or a
## second living tank exists to receive the swap.
static func _tank_swap_engages(combatants: Array) -> bool:
    if not TANK_SWAP_NEEDS_A_PARTNER:
        return true
    var tanks := 0
    for c in combatants:
        if c.is_alive() and int(c.get_meta("profile")["role_group"]) == Enums.RoleGroup.TANK:
            tanks += 1
    return tanks >= 2


static func _tank_swap_demanded(spec, combatants: Array) -> bool:
    if not _tank_swap_engages(combatants):
        return false
    var swap_at := int(spec.params.get("swap_at", 3))
    for c in combatants:
        if c.is_active_tank and c.is_alive() and c.tank_debuff_stacks >= swap_at:
            return true
    return false


## ONE cadence rule for all twelve mechanics (docs/10 §10). Three arms each
## invented their own — M02 read `every` alone, M06 read `round` alone, M04 read
## a `rounds` list — so `every: 4` meant "rounds 4, 8, 12" to one and "never" to
## another, and an author could not tell which by reading the vocabulary table.
##
##   `rounds`  a list of exact rounds        (M04 on E5: [10, 20])
##   `round`   the first round it fires      (M06: 31)
##   `every`   the repeat, from `round` if there is one, else from round 0
##
## `unscheduled_is_always` is the reading for a spec with none of the three.
## docs/10 M03 ("`X`/round") and M11 ("each round") describe mechanics that are
## simply on, so it defaults true — but a one-shot like M06 must pass false, or
## an encounter that forgot to author `round` would enrage every single round.
##
## The `rounds` guard is not defensive programming: E4 authors M08 as
## `{"rounds": 5, "every": 5}` where `rounds` is a DURATION, not a list
## (data/encounters_t1.json). A bare `var rounds: Array = params.get(...)`
## crashes the sim on that spec, and it only stayed hidden because this test
## used to be reachable from the M04 branch alone.
static func _mechanic_fires_this_round(spec, round_no: int,
        unscheduled_is_always: bool = true) -> bool:
    var params: Dictionary = spec.params
    var listed: Array = []
    var raw = params.get("rounds", null)
    if typeof(raw) == TYPE_ARRAY:
        listed = raw
    var start := int(params.get("round", 0))
    var every := int(params.get("every", 0))
    if round_no in listed:
        return true
    if start > 0:
        if round_no == start:
            return true
        return every > 0 and round_no > start and (round_no - start) % every == 0
    if every > 0:
        return round_no % every == 0
    return listed.is_empty() and unscheduled_is_always


## docs/07 §5.3(b)'s roll site: "when the encounter script demands a response from
## a raider (move out, interrupt, hold a debuff, spread), that raider rolls once
## against that check. A raider facing three checks in one round rolls three times."
##
## This is the site that makes docs/10 §10's design surface real. Under a
## per-round roll a boss demanding four responses is no more dangerous than one
## demanding nothing, and §5.3 rejects that reading explicitly — "this boss is
## hard" and "this boss asks a lot" are supposed to be the same sentence.
##
## WHICH mechanics demand a response is read off docs/10 §10's spec column, not
## invented: only the four whose text names a thing the raider must DO are here.
## M02/M06/M09/M10/M11/M12 simply happen to you, and M04/M08 change who the enemy
## hits — none of them asks the raider a question, so none of them rolls. A
## mechanic arm landing later extends this table and nothing else.
static func _mechanic_demands(spec, combatants: Array) -> Array:
    var out := []
    match spec.mechanic:
        Enums.Mechanic.TANK_SWAP:
            # "swap required at 3" — the demand is on whoever is holding it.
            for c in combatants:
                if c.is_alive() and int(c.get_meta("profile")["role_group"]) == Enums.RoleGroup.TANK:
                    out.append(c)
        Enums.Mechanic.GROUND_EFFECT:
            # "X/round to raiders flagged in-zone" — stressing "Rogue, melee".
            for c in combatants:
                if c.is_alive() and Consumables.is_melee_class(int(c.get_meta("profile")["class_id"])):
                    out.append(c)
        Enums.Mechanic.INTERRUPT_CHECK:
            # "unless >= 1 melee DPS is in position" — the melee DPS are asked.
            for c in combatants:
                if not c.is_alive():
                    continue
                var p: Dictionary = c.get_meta("profile")
                if int(p["role_group"]) == Enums.RoleGroup.DPS \
                        and Consumables.is_melee_class(int(p["class_id"])):
                    out.append(c)
        Enums.Mechanic.POSITIONING:
            # "wrong state costs X per off-position raider" — everyone is asked.
            for c in combatants:
                if c.is_alive():
                    out.append(c)
    return out


## Phase 0b. Every check the script demands this round, in slot order, one roll
## each. The RNG stream is derived per (round, slot, ordinal) so a raider facing
## two checks draws twice from two fixed streams — docs/14 §8 makes draw order
## part of the save-scum guarantee, so it may not depend on iteration order of a
## Dictionary or on how many mechanics happen to be authored.
##
## Returns the checks that FAILED, keyed by (slot, mechanic). Four mechanics
## resolve off that answer rather than off the roll — a swap that does not
## happen, a cast that goes off, a raider in the wrong place — so the answer has
## to leave this function rather than being re-derived from the log.
static func _phase_mechanic_checks(rng, round_no: int, combatants: Array,
        enemies: Array, encounter, log, round_state: Dictionary,
        mstate: Dictionary = {}) -> Dictionary:
    var failed := {}
    var ordinal := {}
    # docs/07 §6's Fire token is the consequence of ONE mechanic, M03, and it is
    # the only token in the taxonomy that names a thing the encounter has to
    # carry. This site used to strip it from the event when the encounter had
    # no zone and keep the NAME, so E3 — no ground effect — logged "Stood in the
    # Fire" followed by nothing (SIM-14). Both halves are the taxonomy's now:
    # `Context.zone_exists` (set in `_context` from the card) gates MIS_FIRE's
    # eligibility and `Mistakes.emits_for` gates the token for every type.
    for spec in encounter.mechanics:
        if not _check_demanded_now(spec, round_no, mstate, encounter, combatants):
            continue
        for c in _mechanic_demands(spec, combatants):
            var slot: int = c.slot_index
            var nth: int = int(ordinal.get(slot, 0))
            ordinal[slot] = nth + 1
            var p: Dictionary = c.get_meta("profile")
            var ctx = _context(Enums.RollSite.MECHANIC, round_no, Enums.Phase.ROUND_OPEN,
                c, enemies, encounter, round_state)
            var stream: int = 300 + slot * 4 + nth
            var gate = rng.derive("mechanic_gate", round_no, stream)
            var ev = Mistakes.roll(gate, int(p["class_id"]), int(p["role_group"]),
                c.raider.rarity, _sim_morale(c), ctx,
                _situational_bp(c, combatants, Enums.RollSite.MECHANIC), 1.0,
                _relief_bp(c))
            if ev == null:
                continue
            failed[_check_key(c, spec.mechanic)] = true
            ev.actor_id = c.raider.id
            ev.channel = _channel("mechanic_gate", round_no, stream)
            _attribute(ev, c, combatants)
            _record(ctx, c, round_state, ev)
            _log_mistake(log, round_no, Enums.Phase.ROUND_OPEN, c, ev, mstate)
            _apply_mistake(rng, round_no, Enums.Phase.ROUND_OPEN, c, combatants, enemies,
                ev, log, mstate)
    return failed


## The key one raider's answer to one mechanic is filed under. A raider can be
## asked by two mechanics in the same round (E4 asks a Rogue about the fire and
## the interrupt) and the two answers are independent.
static func _check_key(c, mechanic: int) -> String:
    return "%d|%d" % [c.slot_index, mechanic]


static func _check_failed(failed: Dictionary, c, mechanic: int) -> bool:
    return bool(failed.get(_check_key(c, mechanic), false))


## Round Open: the mechanics that HAPPEN to the raid.
##
## The four that DEMAND a response (docs/07 §5.3(b) — M01, M03, M05, M07) are
## dispatched here too, so the default arm keeps meaning "nobody wrote this
## one", but they resolve in `_resolve_demanded_mechanics` after Phase 0b has
## asked the question. One arm per mechanic, one helper per arm: docs/10 §10 is
## twelve parameterised behaviours and a reader looking for one of them should
## find it whole in one place.
static func _apply_scheduled_mechanics(rng, round_no: int, combatants: Array,
        enemies: Array, encounter, log, mstate: Dictionary = {}) -> void:
    for spec in encounter.mechanics:
        var fires := _mechanic_fires(spec, round_no)
        match spec.mechanic:
            Enums.Mechanic.RAID_WIDE:
                if fires:
                    _fire_raid_wide(round_no, combatants, spec, log)
            Enums.Mechanic.ENRAGE:
                if fires:
                    _fire_enrage(round_no, enemies, spec, log, mstate)
            Enums.Mechanic.ADD_SPAWNS:
                if fires:
                    _fire_add_spawns(round_no, enemies, spec, log, mstate)
            Enums.Mechanic.FIXATE:
                _tick_fixate(rng, round_no, combatants, spec, log, mstate, fires)
            Enums.Mechanic.HEALING_DEBUFF:
                if fires:
                    _fire_healing_debuff(rng, round_no, combatants, spec, log)
            Enums.Mechanic.MANA_BURN:
                if fires:
                    _fire_mana_burn(round_no, combatants, spec, log)
            Enums.Mechanic.FRONTAL_CLEAVE:
                if fires:
                    _fire_frontal_cleave(round_no, combatants, spec, log)
            Enums.Mechanic.ESCALATING_SWING:
                if fires:
                    _tick_escalating_swing(round_no, enemies, spec, log)
            Enums.Mechanic.POSITIONING:
                if fires:
                    _open_positioning_window(round_no, spec, log, mstate)
            Enums.Mechanic.TANK_SWAP, Enums.Mechanic.INTERRUPT_CHECK:
                pass    # resolved after Phase 0b's checks; see below
            Enums.Mechanic.GROUND_EFFECT:
                pass    # entry is the check, tick is Phase 5 (`_phase_effects`)
            _:
                if round_no == 1:
                    _note_gap(log, round_no, spec.mechanic, "mechanic_unimplemented",
                        "is configured but has no behaviour in the sim yet")


## docs/10 §10 M02: "`X` damage to all living raiders every `N` rounds."
static func _fire_raid_wide(round_no: int, combatants: Array, spec, log) -> void:
    var dmg := Formulas.raid_wide_damage(float(spec.params.get("damage", 20)))
    # docs/10 §5.4: the pulse bypasses armour, so its raw value is what lands.
    # It used to be mitigated twice — once nominally by `raid_wide_damage`, which
    # returns the raw number unchanged, and then for real by `_apply_damage`'s AC
    # path, which handed the tank's gear a say in a healer-facing mechanic. The
    # `ignores_ac` flag the data has always carried (data/encounters_t1.json) is
    # the switch for §5.4's open question; its default here is the doc's
    # assumption, and it is the ONLY mechanic that bypasses armour.
    var ignores_ac := bool(spec.params.get("ignores_ac", true))
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "A raid-wide pulse hits everyone for %d." % dmg)
    for c in combatants:
        if c.is_alive():
            _apply_damage(round_no, Enums.Phase.ROUND_OPEN, c, dmg, log,
                "the pulse", ignores_ac)


## docs/10 §10 M06: at one computed round, "boss damage x2 permanently".
static func _fire_enrage(round_no: int, enemies: Array, spec, log,
        mstate: Dictionary) -> void:
    var pct := int(spec.params.get("damage_multiplier_pct", 200))
    for e in enemies:
        e.raw_swing = int(round(float(e.raw_swing) * float(pct) / 100.0))
    # "Permanently" has to outlive the round, because the enemy list does not
    # stop growing: M04's adds and a mistake's Loose Add both arrive later, and
    # both used to swing their authored value in an enraged fight.
    mstate["swing_mult_pct"] = int(round(
        float(int(mstate.get("swing_mult_pct", 100))) * float(pct) / 100.0))
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "ENRAGE. Everything hits twice as hard now.")


## docs/10 §10 M04: "`count` adds of `hp`/`swing` on round `R`, repeating every
## `N`; adds target lowest-HP raider."
static func _fire_add_spawns(round_no: int, enemies: Array, spec, log,
        mstate: Dictionary) -> void:
    for i in int(spec.params.get("count", 1)):
        var add := Enemy.new()
        add.name = "Add"
        add.hp = int(spec.params.get("hp", 60))
        add.max_hp = add.hp
        add.raw_swing = _spawn_swing(int(spec.params.get("swing", 8)), mstate)
        add.threat_rule = "lowest_hp"
        add.is_add = true
        enemies.append(add)
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "Adds join the fight.")


## docs/10 §10 M08: "Boss ignores threat for `N` rounds and chases a random
## raider." The chase itself is in `_pick_enemy_target`; this picks the victim,
## and lets them go again.
##
## The tanks are not candidates. Fixating on the tank is the DEFAULT behaviour —
## M08 exists to take the boss off the person built to survive it, which is why
## docs/10 §10 lists its stressed class as the Cleric and not the Warrior.
static func _tick_fixate(rng, round_no: int, combatants: Array, spec, log,
        mstate: Dictionary, fires: bool) -> void:
    if int(mstate.get("fixate_slot", -1)) >= 0 \
            and round_no > int(mstate.get("fixate_until", 0)):
        var was = _combatant_in_slot(combatants, int(mstate["fixate_slot"]))
        mstate["fixate_slot"] = -1
        log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
            "The boss loses interest in %s and goes back to the tank."
            % ("its last victim" if was == null else was.display_name()))
    if not fires or round_no <= int(mstate.get("fixate_until", 0)):
        return
    var candidates := []
    for c in combatants:
        if c.is_alive() and not (c.is_main_tank or c.is_offtank):
            candidates.append(c)
    if candidates.is_empty():
        return
    var chosen = candidates[rng.derive("fixate", round_no, 0).next_below(candidates.size())]
    mstate["fixate_slot"] = chosen.slot_index
    mstate["fixate_until"] = round_no + _duration_of(spec) - 1
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "The boss fixates on %s and stops caring about threat." % chosen.display_name())


## docs/10 §10 M09: "Healing on the current tank reduced `p%` for `N` rounds."
static func _fire_healing_debuff(rng, round_no: int, combatants: Array, spec, log) -> void:
    var pct := int(spec.params.get("reduction_pct", 0))
    if pct <= 0:
        return
    var t = _healing_debuff_target(rng, round_no, combatants, spec)
    if t == null:
        return
    var rounds := _duration_of(spec)
    t.healing_reduction_pct = pct
    t.healing_reduction_until = round_no + rounds - 1
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "Healing on %s is cut by %d%% for %d rounds." % [t.display_name(), pct, rounds])


## docs/10 §10 M09 is "healing on the current TANK", and the data says so as
## `"target": "active_tank"` — a concept that did not exist until M01 introduced
## it. `random` and `lowest_hp` are the two other shapes an author could
## reasonably want; anything unrecognised falls through to the tank rather than
## silently debuffing nobody.
static func _healing_debuff_target(rng, round_no: int, combatants: Array, spec):
    var living := []
    for c in combatants:
        if c.is_alive():
            living.append(c)
    if living.is_empty():
        return null
    match String(spec.params.get("target", "active_tank")):
        "random":
            return living[rng.derive("healing_debuff", round_no, 0).next_below(living.size())]
        "lowest_hp":
            var weakest = living[0]
            for c in living:
                if c.hp_fraction() < weakest.hp_fraction():
                    weakest = c
            return weakest
    for c in living:
        if c.is_active_tank:
            return c
    for c in living:
        if c.is_main_tank:
            return c
    return null


## docs/10 §10 M10, the half that can ship: "For `N` rounds, casters ... cannot
## act." `Combatant.can_act(round_no)` is where it binds, so Phases 2-4 honour
## it without knowing the mechanic exists.
static func _fire_mana_burn(round_no: int, combatants: Array, spec, log) -> void:
    var rounds := _duration_of(spec)
    var until := round_no + rounds - 1
    var silenced := 0
    for c in combatants:
        if not c.is_alive() or not _is_caster_or_support(c):
            continue
        c.silenced_until = maxi(c.silenced_until, until)
        silenced += 1
    if silenced == 0:
        return
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "Silence. %d of the raid have nothing to say for %d rounds." % [silenced, rounds])
    if MANA_BURN_DRAIN_ENABLED:
        # The other half of docs/10 §10 M10's row, "casters lose `X` Mana per
        # round". There is nothing to subtract from: see MANA_BURN_DRAIN_ENABLED.
        _note_gap(log, round_no, spec.mechanic, "mechanic_partial",
            "would drain Mana here, and docs/15 Q-02's Focus pool does not exist")


## Who M10 silences. docs/10 §10 M10's stressed column is "Mage, Wizard,
## healers, Bard": the two casters by class, and the healers and the Bard by
## role group — Bard is docs/06's SUPPORT, and a Bard's song is a cast.
static func _is_caster_or_support(c) -> bool:
    var p: Dictionary = c.get_meta("profile")
    if int(p["class_id"]) in [Enums.CharClass.MAGE, Enums.CharClass.WIZARD]:
        return true
    return int(p["role_group"]) in [Enums.RoleGroup.HEALER, Enums.RoleGroup.SUPPORT]


## docs/10 §10 M11: "`X` damage to all melee-positioned raiders each round."
##
## Announced once and then applied per raider: one mechanic line per victim
## would bury a twelve-round fight under sixty of them, and STORY is the tier
## the player actually reads (docs/07 §10.2).
static func _fire_frontal_cleave(round_no: int, combatants: Array, spec, log) -> void:
    var damage := int(spec.params.get("damage", 0))
    if damage <= 0:
        return
    var hit := []
    for c in combatants:
        if not c.is_alive():
            continue
        if not Consumables.is_melee_class(int(c.get_meta("profile")["class_id"])):
            continue
        if (c.is_main_tank or c.is_offtank) and not FRONTAL_CLEAVE_INCLUDES_TANK:
            continue
        hit.append(c)
    if hit.is_empty():
        return
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "A frontal cleave catches %d melee raiders." % hit.size())
    for c in hit:
        # Armour applies. docs/10 §5.4's AC bypass belongs to the raid-wide
        # pulse shapes — M02, and M05's `raid_damage` payload, which is the same
        # "everyone eats this" event — and a cleave the plate tank shrugs off is
        # exactly what plate is for.
        _apply_damage(round_no, Enums.Phase.ROUND_OPEN, c, damage, log, "the cleave")


## docs/10 §10 M12: "Boss raw swing +`X` per round, no cap — a soft enrage."
##
## No cap is honoured literally; termination is docs/07 §7.3's round cap and the
## attrition rule, not a ceiling here. `from_round` is the knob for a soft
## enrage that starts late; the shared cadence still decides which rounds tick,
## so an author can also make it every other round.
static func _tick_escalating_swing(round_no: int, enemies: Array, spec, log) -> void:
    var increment := int(spec.params.get("increment", 0))
    var from_round := int(spec.params.get("from_round", 1))
    if increment <= 0 or round_no < from_round:
        return
    for e in enemies:
        # docs/10 §7 split rule 2: adds are healer pressure and sit outside the
        # tank-channel budget, so a growing ADD swing is a different mechanic
        # from a growing boss swing, and M12 is not it.
        if not e.is_add:
            e.raw_swing += increment
    var elapsed := round_no - from_round + 1
    if elapsed == 1 or elapsed % ESCALATION_ANNOUNCE_EVERY == 0:
        log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
            "The boss is swinging harder every round — %d more than it opened with."
            % (elapsed * increment))


## docs/10 §10 M07: "Fight demands Spread or Stack for `N` rounds." The demand is
## announced here, answered at Phase 0b, and priced in `_resolve_positioning`.
static func _open_positioning_window(round_no: int, spec, log,
        mstate: Dictionary) -> void:
    # docs/10 §10 M07 is "Fight demands Spread or Stack" and privileges neither,
    # so an encounter that does not say which one gets a demand with no content
    # rather than a stance this file picked — the same treatment M05's unnamed
    # effect `E` gets, and for the same reason (house rule 1). The line says so,
    # because a silent no-op is docs/10 §6's "star that buys nothing".
    var required := Enums.stance_from_key(String(spec.params.get("required", "")))
    if required < 0:
        log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
            "The fight demands a position and nobody can say which.")
        return
    var rounds := _duration_of(spec)
    mstate["stance_required"] = required
    mstate["stance_until"] = round_no + rounds - 1
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "The fight demands %s for %d rounds."
        % [Enums.stance_name_of(required), rounds])


# ------------------------------------------------- phase 0c: the answers cost

## The three mechanics whose outcome is an ANSWER, resolved once Phase 0b has
## rolled the checks. M03 is the fourth demand mechanic and needs nothing here:
## its check places the Fire token through `_apply_mistake`, and the tick is
## Phase 5.
##
## Guarded on `_mechanic_demands_now` (is the mechanic LIVE) and not on
## `_check_demanded_now` (was a raider ASKED). M01 only asks the tanks anything
## on the round the stacks reach `swap_at`, but it has to resolve every round of
## the fight regardless: the off-duty decay and the hand-over when the holder
## dies both live in `_resolve_tank_swap`, and a debuff that stopped decaying on
## the rounds nobody was asked would be a different mechanic.
static func _resolve_demanded_mechanics(round_no: int, combatants: Array,
        enemies: Array, encounter, log, mstate: Dictionary,
        failed: Dictionary) -> void:
    for spec in encounter.mechanics:
        if not _mechanic_demands_now(spec, round_no, mstate, encounter, combatants):
            continue
        match spec.mechanic:
            Enums.Mechanic.TANK_SWAP:
                _resolve_tank_swap(round_no, combatants, spec, log, failed)
            Enums.Mechanic.INTERRUPT_CHECK:
                _resolve_interrupt(round_no, combatants, enemies, spec, log, failed)
            Enums.Mechanic.POSITIONING:
                _resolve_positioning(round_no, combatants, spec, log, failed, mstate)


## docs/10 §10 M01: "swap required at 3."
##
## The swap moves THREAT, not the boss. docs/07 §8 owns targeting, and a hard
## override — "while M01 is live the boss hits the active tank" — would have
## neutered MIS_AGGRO on E3 and E5, where docs/10 §7.5 names Warrior *Lost
## Aggro* the tier's designed killer. A taunt is also what the fiction is: the
## incoming tank takes the boss by getting its attention, and a DPS who pulls
## aggro can still steal it back.
static func _resolve_tank_swap(round_no: int, combatants: Array, spec, log,
        failed: Dictionary) -> void:
    if not _tank_swap_engages(combatants):
        if round_no == 1:
            _note_gap(log, round_no, Enums.Mechanic.TANK_SWAP, "mechanic_needs_a_partner",
                "is configured on a party that cannot field a second tank, so there "
                + "is no swap to demand and no stacks are applied")
        return
    var tanks := []
    for c in combatants:
        if c.is_main_tank or c.is_offtank:
            tanks.append(c)
    var active = null
    for c in tanks:
        if c.is_active_tank and c.is_alive():
            active = c
    if active == null:
        # The holder is down. The flag has to follow the fight, or the debuff
        # stops being anybody's problem for the rest of the encounter.
        for c in tanks:
            c.is_active_tank = false
        for c in tanks:
            if c.is_alive():
                c.is_active_tank = true
                active = c
                break
    if active == null:
        return
    var swap_at := int(spec.params.get("swap_at", 3))
    if active.tank_debuff_stacks >= swap_at:
        _attempt_tank_swap(round_no, combatants, tanks, active, swap_at, log, failed)
    # The debuff decays off duty (docs/15 BL-84): docs/10 says
    # how stacks arrive and never how they leave, and without decay the mechanic
    # works exactly twice before both tanks are capped and there is nowhere to
    # swap to.
    for c in tanks:
        if not c.is_active_tank and c.tank_debuff_stacks > 0:
            c.tank_debuff_stacks = maxi(0,
                c.tank_debuff_stacks - TANK_DEBUFF_DECAY_PER_ROUND)


static func _attempt_tank_swap(round_no: int, combatants: Array, tanks: Array,
        active, swap_at: int, log, failed: Dictionary) -> void:
    if _check_failed(failed, active, Enums.Mechanic.TANK_SWAP):
        # docs/10 §10 M01's invited mistakes are Monk *Panicked Stance* and
        # Warrior *Lost Aggro*: the swap is a thing a person has to DO, and
        # somebody who has just fumbled the check keeps the boss and the stacks.
        log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, Enums.Mechanic.TANK_SWAP,
            "%s is meant to step out at %d stacks, and does not."
            % [active.display_name(), swap_at])
        return
    var incoming = null
    for c in tanks:
        if c != active and c.is_alive():
            incoming = c
            break
    if incoming == null:
        # docs/06's composition punishment, out loud: one tank cannot take turns
        # with itself, and the stacks are what it costs.
        log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, Enums.Mechanic.TANK_SWAP,
            "%s has nobody to swap with and holds it at %d stacks."
            % [active.display_name(), active.tank_debuff_stacks])
        return
    var top := 0
    for c in combatants:
        top = maxi(top, c.threat)
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, Enums.Mechanic.TANK_SWAP,
        "%s steps out at %d stacks; %s takes over."
        % [active.display_name(), active.tank_debuff_stacks, incoming.display_name()])
    active.is_active_tank = false
    incoming.is_active_tank = true
    incoming.tank_debuff_stacks = 0
    incoming.threat = top + 1


## docs/10 §10 M05: "Boss casts on round `R`; unless >=1 melee DPS is in
## position, effect `E` fires."
##
## Three ways it goes off, and the line says which: nobody brought a melee DPS,
## the ones who did fumbled this round's check (docs/07 §5.2 rows 4-5), or they
## spent the interrupt two rounds ago on the wrong cast.
static func _resolve_interrupt(round_no: int, combatants: Array, enemies: Array,
        spec, log, failed: Dictionary) -> void:
    # The same set Phase 0b asked, from the same predicate, so "who could have
    # interrupted" and "who rolled for it" can never disagree.
    var melee := _mechanic_demands(spec, combatants)
    var why := ""
    if melee.size() < int(spec.params.get("requires_melee", 1)):
        why = "Nobody was in melee. The cast goes off."
    else:
        var ready := 0
        for c in melee:
            if _interrupt_on_cooldown(c, round_no):
                continue
            if _check_failed(failed, c, spec.mechanic):
                continue
            ready += 1
        if ready == 0:
            why = "Everyone who could have interrupted it was getting it wrong."
    if why.is_empty():
        log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
            "The cast is interrupted, which is what the melee were for.")
        return
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic, why)
    _apply_interrupt_effect(round_no, combatants, enemies, spec, log)


## Effect `E`. docs/10 §10 M05 never names it, so it is authored per encounter
## and NOT defaulted to a number this file made up: an encounter with no
## `effect` block has a cast that resolves and does nothing, which is a visible
## authoring gap rather than an invisible invented one. See docs/15 BL-83
## and audit m6-e4-m05-effect (E4's missing effect block).
static func _apply_interrupt_effect(round_no: int, combatants: Array,
        enemies: Array, spec, log) -> void:
    var effect: Dictionary = spec.params.get("effect", {})
    var amount := int(effect.get("amount", 0))
    if amount <= 0:
        return
    match String(effect.get("kind", INTERRUPT_EFFECT_DEFAULT_KIND)):
        "boss_heal_pct":
            for e in enemies:
                if e.active and e.is_alive() and not e.is_add:
                    e.hp = mini(e.max_hp,
                        e.hp + int(round(float(e.max_hp) * float(amount) / 100.0)))
                    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
                        "%s heals itself for %d%% of the way back." % [e.name, amount])
                    return
        _:
            # `raid_damage`, and the default kind: an uninterrupted cast is the
            # same shape of problem as M02's pulse, so it lands like one.
            for c in combatants:
                if c.is_alive():
                    _apply_damage(round_no, Enums.Phase.ROUND_OPEN, c, amount, log,
                        "the cast", true)


## docs/10 §10 M07: "wrong state costs `X` per off-position raider."
##
## "Off-position" is a synonym for "failed the check" — that is the whole
## abstract position model (docs/07 OQ-7, docs/15 BL-82), and
## it is what makes M07 a *Broke the Ramp* mechanic rather than a movement
## puzzle the player cannot touch.
static func _resolve_positioning(round_no: int, combatants: Array, spec, log,
        failed: Dictionary, mstate: Dictionary) -> void:
    var required := int(mstate.get("stance_required", -1))
    if required < 0:
        return
    var wrong := []
    for c in combatants:
        if not c.is_alive():
            continue
        c.stance = _other_stance(required) if _check_failed(failed, c, spec.mechanic) \
            else required
        if c.stance != required:
            wrong.append(c)
    if wrong.is_empty():
        return
    var damage := int(spec.params.get("damage", 0))
    log.emit_mechanic(round_no, Enums.Phase.ROUND_OPEN, spec.mechanic,
        "%d raiders are standing in the wrong place." % wrong.size())
    if damage <= 0:
        return
    for c in wrong:
        _apply_damage(round_no, Enums.Phase.ROUND_OPEN, c, damage, log,
            "bad positioning")


static func _other_stance(stance: int) -> int:
    return Enums.Stance.SPREAD if stance == Enums.Stance.STACKED else Enums.Stance.STACKED


## docs/07 §5.2 row 5's two-round interrupt cooldown, read back. It lives on the
## combatant's meta and not in a file-level static, because two encounters may
## never share it (house rule 6).
static func _interrupt_on_cooldown(c, round_no: int) -> bool:
    if not c.has_meta("interrupt_cd_until"):
        return false
    return round_no <= int(c.get_meta("interrupt_cd_until"))


static func _combatant_in_slot(combatants: Array, slot: int):
    for c in combatants:
        if c.slot_index == slot:
            return c
    return null


## A star was spent on a mechanic that does nothing. docs/10 §6: "a star that
## buys nothing is a lie on the encounter card", and the match above had no
## default arm, so E4's four configured mechanics were a silent no-op while every
## data-shape test stayed green. All twelve are armed now, so this fires only for
## a THIRTEENTH — which is exactly when it is needed. Named once per fight rather
## than once per round: a transcript should show the hole, not drown in it.
##
## DEBUG and not NUMBERS. docs/07 §10.2 sells tier 2 to "players who want to tune
## gear" — RaidView offers it as a verbosity button — and reserves tier 3 for
## "dev builds and bug reports only". This is a note about the sim, not about the
## fight, so it belongs where the doc puts notes about the sim.
##
## Emitted through `emit` rather than `emit_system` because that helper stamps
## ROUND_CLOSE, and a round-open line wearing the closing phase breaks the log's
## phase ordering.
static func _note_gap(log, round_no: int, mechanic: int, template_id: String,
        what: String) -> void:
    log.emit(Enums.Verb.SYSTEM, Enums.LogTier.DEBUG, round_no,
        Enums.Phase.ROUND_OPEN, template_id,
        {"mechanic": Enums.mechanic_key(mechanic),
         "text": "%s (%s) %s." % [Enums.mechanic_name_of(mechanic),
            Enums.mechanic_key(mechanic), what]})


# ---------------------------------------------------------------- phase 1

static func _phase_boss(rng, round_no: int, combatants: Array, enemies: Array,
        encounter, log, mstate: Dictionary = {}) -> void:
    # docs/10 §10 M01's debuff is read here rather than stamped as a token: it
    # is a multiplier on one raider's incoming damage, and `tokens` stores
    # expiry, not magnitude.
    var swap = encounter.mechanic_spec(Enums.Mechanic.TANK_SWAP)
    var stack_pct := 0
    if swap != null:
        stack_pct = int(swap.params.get("stack_damage_pct", 50))
    var ordinal := 0
    for e in enemies:
        if not e.active or not e.is_alive():
            continue
        for swing in e.swings_per_round:
            var target = _pick_enemy_target(rng, e, combatants, round_no, ordinal,
                mstate, int(swing), log)
            if target == null:
                continue
            var raw: int = e.raw_swing
            # "+50%/stack damage taken", applied BEFORE armour, so the tank's
            # gear cannot mitigate a stack away: the answer to three stacks is
            # the swap, not the AC. That is what makes E3 the first fight where
            # the second tank has to function rather than merely exist
            # (docs/10 §7.3).
            if swap != null and target.is_active_tank and target.tank_debuff_stacks > 0:
                raw = int(round(float(raw) * (1.0
                    + float(target.tank_debuff_stacks) * float(stack_pct) / 100.0)))
            _apply_damage(round_no, Enums.Phase.BOSS, target, raw, log, e.name)
            # "1 stack per hit" — from the enemy whose threat table the swap
            # exists to manage. An add hunting the weakest raider is not the
            # tank's turn at the boss (docs/10 §7 split rule 2).
            #
            # Uncapped. docs/10 §10 M01 names exactly one threshold, `swap_at`,
            # and no ceiling; a cap at the threshold would only ever soften the
            # one case the row cannot soften — a fight with nobody to swap to,
            # where docs/06's composition punishment is the stacks themselves.
            if swap != null and target.is_active_tank and not e.is_add \
                    and _tank_swap_engages(combatants):
                target.tank_debuff_stacks += 1
            ordinal += 1


## Standard threat picks the highest-threat living raider — through docs/07
## §8.2's hysteresis (SIM-17): the enemy keeps its current target until a
## candidate CLEARS `Formulas.should_retarget` (1.10 × in melee, 1.30 × at
## range), and the switch is said out loud. `lowest_hp` adds hunt the weakest,
## which is what makes them healer pressure rather than boss damage.
##
## `swing` is which of this enemy's swings this round is being aimed: docs/15
## Q-57's Lost Aggro — the tank's MIS_TAUNT_LAPSE — sends swing 1 (index 0)
## to the second-highest threat and swing 2 back to the tank, and the enemy's
## remembered target does not move for it.
static func _pick_enemy_target(rng, enemy, combatants: Array, round_no: int,
        ordinal: int, mstate: Dictionary = {}, swing: int = 0, log = null):
    var valid := []
    for c in combatants:
        if c.is_valid_boss_target():
            valid.append(c)
    if valid.is_empty():
        return null
    # docs/10 §10 M08: "Boss ignores threat for `N` rounds and chases a random
    # raider." Only the standard-threat primary chases — an add already hunts
    # the weakest and has no threat table to ignore. A fixate on somebody who
    # has since gone Downed or Dead falls through to threat, because they are
    # not in `valid` — silently, and on purpose: the window is `N` rounds
    # (docs/10 §10 M08) and a Downed raider can be back up inside it, so the
    # boss resumes chasing them. The release line is emitted once, when the
    # window ENDS, by `_tick_fixate`.
    if not enemy.is_add and round_no <= int(mstate.get("fixate_until", 0)):
        var slot: int = int(mstate.get("fixate_slot", -1))
        for c in valid:
            if c.slot_index == slot:
                return c
    if enemy.threat_rule == "lowest_hp":
        var weakest = valid[0]
        for c in valid:
            if c.current_hp < weakest.current_hp:
                weakest = c
        return weakest
    if enemy.threat_rule == "independent":
        # Each mob in a pack keeps its own table; approximate by spreading across
        # the raid deterministically rather than stacking on one raider.
        var pick = rng.derive("targeting", round_no, ordinal)
        return valid[pick.next_below(valid.size())]
    # The remembered target, if still standing. `valid` is in slot order, so
    # the strict `>` below keeps the earlier slot on a tie — the same
    # tie-break every other phase in this file uses.
    var current = null
    for c in valid:
        if c.slot_index == enemy.target_slot:
            current = c
    # docs/15 Q-57: Lost Aggro. Swing 1 only; the memory stays on the tank so
    # swing 2 and the next round resolve on them as ruled.
    if swing == 0 and current != null and current.has_lost_aggro(round_no):
        var second = _top_threat(valid, current)
        if second != null:
            if log != null:
                _say(log, Enums.LogTier.STORY, round_no, Enums.Phase.BOSS, "lost_aggro", current,
                    "%s has lost %s's attention; it swings at %s first."
                        % [current.display_name(), enemy.name, second.display_name()],
                    {"target_id": second.raider.id})
            return second
    var top = _top_threat(valid, null)
    if current == null:
        enemy.target_slot = top.slot_index
        return top
    if top != current and Formulas.should_retarget(float(top.threat), float(current.threat),
            _is_melee(top)):
        enemy.target_slot = top.slot_index
        if log != null:
            _say(log, Enums.LogTier.STORY, round_no, Enums.Phase.BOSS, "retarget", top,
                "%s turns on %s." % [enemy.name, top.display_name()])
        return top
    return current


## The highest-threat raider in `valid`, skipping `except`; ties to the
## earlier slot. Null when nobody else is standing.
static func _top_threat(valid: Array, except):
    var top = null
    for c in valid:
        if c == except:
            continue
        if top == null or c.threat > top.threat:
            top = c
    return top


## docs/08 §8.7's melee / ranged split for the retarget threshold, by class
## (Consumables' canon list: Warrior, Monk, Rogue, Bard).
static func _is_melee(c) -> bool:
    return Consumables.is_melee_class(int(c.get_meta("profile")["class_id"]))


# ---------------------------------------------------------------- phases 2-3

## docs/07 §4.1 sub-order: tanks (main then off), then melee, then casters, then
## Bard. Ties resolve by roster slot index, which is what keeps runs identical.
static func _phase_actors(rng, round_no: int, combatants: Array, enemies: Array,
        encounter, db, log, phases: Array, round_state: Dictionary,
        mstate: Dictionary = {}) -> void:
    var order := _action_order(combatants)
    for entry in order:
        var c = entry[1]
        var phase: int = entry[2]
        # `can_act(round_no)` rather than `can_act()`: docs/10 §10 M10's silence
        # window is the only thing that reads the round, and a silenced caster
        # takes no action and therefore rolls no action mistake.
        if not phases.has(phase) or not c.can_act(round_no):
            continue
        if _spends_action_on_loot(round_no, phase, c, log):
            continue
        _take_action(rng, round_no, phase, c, combatants, enemies, encounter, db,
            log, round_state, mstate)


## docs/07 §5.2 row 17's "skips next action", spent here at the first action
## phase that reaches the raider after the call. Said out loud: a raider who
## silently does nothing for a round reads as a bug, not a joke.
static func _spends_action_on_loot(round_no: int, phase: int, c, log) -> bool:
    if not c.consume_skipped_action():
        return false
    _say(log, Enums.LogTier.STORY, round_no, phase, "loot_call_skip", c,
        "%s is still typing about loot." % c.display_name())
    return true


static func _action_order(combatants: Array) -> Array:
    var out := []
    for c in combatants:
        var p: Dictionary = c.get_meta("profile")
        var cls := int(p["class_id"])
        var rank := 50
        var phase := Enums.Phase.DPS
        if c.is_main_tank:
            rank = 0
            phase = Enums.Phase.TANKS
        elif c.is_offtank:
            rank = 1
            phase = Enums.Phase.TANKS
        elif cls in [Enums.CharClass.ROGUE, Enums.CharClass.MONK]:
            rank = 10
        elif cls in [Enums.CharClass.MAGE, Enums.CharClass.WIZARD]:
            rank = 20
        elif cls == Enums.CharClass.BARD:
            rank = 30
        else:
            rank = 40    # healers act in their own phase
            phase = Enums.Phase.HEALERS
        out.append([rank * 1000 + c.slot_index, c, phase])
    out.sort_custom(func(a, b): return a[0] < b[0])
    return out


static func _take_action(rng, round_no: int, phase: int, c, combatants: Array,
        enemies: Array, encounter, db, log, round_state: Dictionary,
        mstate: Dictionary = {}) -> void:
    var p: Dictionary = c.get_meta("profile")
    var ctx = _context(Enums.RollSite.ACTION, round_no, phase, c, enemies, encounter, round_state)
    var gate = rng.derive("mistake_gate", round_no, c.slot_index)
    var ev = null
    if int(round_state.get("forced_slot", -1)) == c.slot_index:
        # docs/10 §9.1: "one guaranteed mistake on round 3 regardless of morale
        # rolls". The gate is not rolled at all, so the tutorial's halved rate
        # (docs/07 OQ-9's ruling) has nothing to suppress; the same derived stream picks
        # the type, so the fight stays a pure function of its seed.
        ev = Mistakes.force(gate, int(p["class_id"]), int(p["role_group"]),
            _sim_morale(c), ctx)
    else:
        ev = Mistakes.roll(gate, int(p["class_id"]), int(p["role_group"]),
            c.raider.rarity, _sim_morale(c), ctx,
            _situational_bp(c, combatants, Enums.RollSite.ACTION), 1.0,
            _relief_bp(c))
    if ev != null:
        ev.actor_id = c.raider.id
        ev.channel = _channel("mistake_gate", round_no, c.slot_index)
        _attribute(ev, c, combatants)
        _record(ctx, c, round_state, ev)
        _log_mistake(log, round_no, phase, c, ev, mstate)
        _apply_mistake(rng, round_no, phase, c, combatants, enemies, ev, log, mstate)
        return

    # docs/07 §8.1-8.2 (SIM-17): the tank on duty spends its action on a Taunt
    # when its Tank Lead is gone, instead of on a swing.
    if phase == Enums.Phase.TANKS and _taunt_if_lead_lost(round_no, c, combatants, log):
        return

    var target = _pick_enemy(enemies)
    if target == null:
        return
    var raw := _outgoing_damage(p, enemies)
    if raw <= 0.0:
        return
    var dealt := Formulas.final_value(raw)
    target.hp = maxi(0, target.hp - dealt)
    c.add_threat(int(round(Formulas.threat_from(int(p["class_id"]), raw) * _threat_mult(c))))
    log.emit_attack(round_no, phase, c, target.name, dealt, target.hp, c.threat)
    if target.hp <= 0:
        log.emit_system(round_no, "%s dies." % target.name, Enums.LogTier.PLAY_BY_PLAY)


## docs/07 §8.2's Tank Lead and §8.1's Taunt. The tank ON DUTY — the active
## tank while it stands, else the first living tank — checks
## `Formulas.tank_lead_held` against the highest non-tank threat; when the lead
## is lost and the taunt is off cooldown it sets its threat to
## `Formulas.taunt_threat` (1.10 × the table's top) and that is its action.
## A Monk seated main tank taunts too: docs/07 §8.3's emergency tank
## "auto-taunts", and a seat with no taunt in it is a seat the boss ignores.
## Returns true when the action was spent here.
static func _taunt_if_lead_lost(round_no: int, c, combatants: Array, log) -> bool:
    if c != _tank_on_duty(combatants):
        return false
    if c.has_meta("taunt_cd_until") and round_no <= int(c.get_meta("taunt_cd_until")):
        return false
    var highest_other := 0
    var highest_non_tank := 0
    for other in combatants:
        if other == c or not other.is_alive():
            continue
        highest_other = maxi(highest_other, other.threat)
        if not (other.is_main_tank or other.is_offtank):
            highest_non_tank = maxi(highest_non_tank, other.threat)
    if highest_non_tank <= 0 or Formulas.tank_lead_held(float(c.threat), float(highest_non_tank)):
        return false
    c.threat = Formulas.taunt_threat(float(highest_other))
    c.set_meta("taunt_cd_until", round_no + TAUNT_COOLDOWN_ROUNDS)
    _say(log, Enums.LogTier.STORY, round_no, Enums.Phase.TANKS, "taunt", c,
        "%s taunts the boss back." % c.display_name(), {"threat_after": c.threat})
    return true


## The tank holding the boss right now: the active tank (M01 moves the flag)
## while it is standing, else the first living tank in slot order, else null.
static func _tank_on_duty(combatants: Array):
    for c in combatants:
        if c.is_active_tank and c.is_alive():
            return c
    for c in combatants:
        if (c.is_main_tank or c.is_offtank) and c.is_alive():
            return c
    return null


## docs/04 §11.2's quirk seam, `threat_multiplier` (Q58-4): 1.0 for everybody
## while `Quirks.SPECS` is empty, and for everybody who is not an authored
## Legendary regardless.
static func _threat_mult(c) -> float:
    return Quirks.threat_multiplier(_quirk_id(c), _quirks_on(c))


static func _quirk_id(c) -> String:
    return String(c.get_meta("quirk_id")) if c.has_meta("quirk_id") else ""


static func _quirks_on(c) -> bool:
    return bool(c.get_meta("quirks_enabled")) if c.has_meta("quirks_enabled") else false


## Who makes docs/10 §9.1's scripted mistake. One raider, drawn from the seeded
## Rng on its own channel so the pick cannot move any other draw, out of the
## living non-tank raiders who act in the tank/DPS phases (the healers resolve
## in Phase 4 through a path that never reaches `_take_action`). The tank is
## left out because a one-tank pull's only tank mistake is a taunt lapse, whose
## consequence is invisible on a single mob — and §9.1's beat is "READ a
## mistake in the log". With nobody else standing the tank is the fallback,
## because a scripted mistake that quietly does not happen is the one outcome
## the flag exists to rule out. -1 when nobody can act at all.
## docs/15 BL-92 records the choice.
static func _pick_forced_mistake_slot(rng, round_no: int, combatants: Array) -> int:
    var candidates := []
    var fallback := []
    for entry in _action_order(combatants):
        var c = entry[1]
        var phase: int = entry[2]
        if phase == Enums.Phase.HEALERS or not c.can_act(round_no):
            continue
        if c.is_main_tank or c.is_offtank:
            fallback.append(c)
        else:
            candidates.append(c)
    if candidates.is_empty():
        candidates = fallback
    if candidates.is_empty():
        return -1
    var pick = rng.derive("forced_mistake", round_no, 0)
    return candidates[pick.next_below(candidates.size())].slot_index


static func _outgoing_damage(p: Dictionary, enemies: Array) -> float:
    var cls := int(p["class_id"])
    if cls in [Enums.CharClass.MAGE, Enums.CharClass.WIZARD]:
        var targets := 1
        if cls == Enums.CharClass.MAGE:
            targets = maxi(1, _living_enemies(enemies))
        # The encounter's tier (SIM-22): docs/15 BL-72's `MANA_TO_SPELL` decay
        # is per tier and reaches the fight through this argument.
        return Formulas.spell_damage_total(cls, int(p["main_damage"]), int(p["mana"]),
            targets, 1.0, int(p.get("tier", 1)))
    return Formulas.melee_damage_per_round(cls, int(p["main_damage"]),
        int(p["off_damage"]), int(p["power"]), bool(p["dual_wield"]))


# ---------------------------------------------------------------- phase 4

## docs/07 §4.1: single-target (Cleric) -> chain (Shaman) -> raid-wide (Druid).
## Cleric triages first, or the Druid's small raid heal gets wasted lifting a
## tank one point above death.
static func _phase_healers(rng, round_no: int, combatants: Array, enemies: Array,
        encounter, db, log, round_state: Dictionary, mstate: Dictionary = {}) -> void:
    var order := [Enums.CharClass.CLERIC, Enums.CharClass.SHAMAN, Enums.CharClass.DRUID]
    for cls in order:
        for c in combatants:
            var p: Dictionary = c.get_meta("profile")
            if int(p["class_id"]) != cls or not c.can_act(round_no):
                continue
            if _spends_action_on_loot(round_no, Enums.Phase.HEALERS, c, log):
                continue
            # The healer's context sees the enemies (SIM-07): `adds_present`
            # and `boss_low` were always false here because it was built
            # against an empty list.
            var ctx = _context(Enums.RollSite.ACTION, round_no, Enums.Phase.HEALERS,
                c, enemies, encounter, round_state, mstate)
            ctx.corpse_present = _has_corpse(combatants)
            var stream: int = 100 + c.slot_index
            var gate = rng.derive("mistake_gate", round_no, stream)
            var ev = Mistakes.roll(gate, cls, Enums.RoleGroup.HEALER,
                c.raider.rarity, _sim_morale(c), ctx,
                _situational_bp(c, combatants, Enums.RollSite.ACTION), 1.0,
                _relief_bp(c))
            if ev != null:
                ev.actor_id = c.raider.id
                ev.channel = _channel("mistake_gate", round_no, stream)
                _attribute(ev, c, combatants)
                _record(ctx, c, round_state, ev)
                _log_mistake(log, round_no, Enums.Phase.HEALERS, c, ev, mstate)
                _apply_mistake(rng, round_no, Enums.Phase.HEALERS, c, combatants, enemies,
                    ev, log, mstate)
                # docs/07 §5.2 rows 6-8: the three healer mistakes are three
                # different casts, not one lost heal (SIM-07).
                _cast_mistaken_heal(round_no, cls, c, p, combatants, ev.type_id, log)
                continue
            _cast_heal(round_no, cls, c, p, combatants, log)


## The healer's cast. Returns the HP it actually restored, summed over every
## target — docs/15 Q-58's healer threat is paid on that (SIM-09), per landed
## heal, inside `_land_heal`.
static func _cast_heal(round_no: int, cls: int, healer, p: Dictionary,
        combatants: Array, log) -> int:
    var heal_base := int(p["heal_base"])
    var mana := int(p["mana"])
    var healed := 0
    match cls:
        Enums.CharClass.CLERIC:
            var t = _neediest(combatants)
            if t != null:
                var amount := Formulas.cleric_heal(heal_base, mana)
                healed += _land_heal(round_no, cls, healer, t, int(amount), log)
        Enums.CharClass.SHAMAN:
            var chain: Array = Formulas.shaman_chain_heal(heal_base, mana)
            var hit := {}
            var nowhere := 0
            for hop in chain.size():
                # docs/15 Q-58: the chain never repeats a target and hops 2-3
                # skip anyone above 95% HP. Hop 1 is the neediest, whoever
                # that is; a later hop with nobody under the line goes nowhere.
                var skip_above: float = CHAIN_SKIP_ABOVE if hop > 0 else 0.0
                var t = _neediest(combatants, hit, skip_above)
                if t == null:
                    nowhere += 1
                    continue
                hit[t] = true
                healed += _land_heal(round_no, cls, healer, t, int(chain[hop]), log)
            if nowhere > 0:
                _say(log, Enums.LogTier.NUMBERS, round_no, Enums.Phase.HEALERS, "chain_nowhere",
                    healer, "%s's chain has nowhere left to bounce (%d %s skipped)."
                        % [healer.display_name(), nowhere, "hop" if nowhere == 1 else "hops"],
                    {"hops_skipped": nowhere})
        Enums.CharClass.DRUID:
            var per := Formulas.druid_raid_heal(heal_base, mana)
            for t in combatants:
                if t.is_valid_heal_target():
                    healed += _land_heal(round_no, cls, healer, t, int(per), log)
    return healed


## docs/07 §5.2 rows 6-8, the three healer mistakes as three casts (SIM-07):
##   HEAL_WRONG    "lands on the highest-HP valid target instead of the
##                 intended one" — the fullest raider gets the cast, and what
##                 does not fit is logged as wasted.
##   HEAL_CORPSE   "targets a Dead raider; entirely wasted" — a 0 heal on the
##                 first corpse in slot order.
##   CHAIN_FIZZLE  "only the first hop does work" — hop 1 on the neediest,
##                 hops 2-3 on the two fullest.
## Every wasted heal is a HEAL entry at NUMBERS carrying `wasted`, so the
## report can add up what the mistake cost; the healer's threat is paid on
## what landed, which is usually nothing. Returns the HP restored.
static func _cast_mistaken_heal(round_no: int, cls: int, healer, p: Dictionary,
        combatants: Array, type_id: String, log) -> int:
    var heal_base := int(p["heal_base"])
    var mana := int(p["mana"])
    var single: int = 0
    match cls:
        Enums.CharClass.CLERIC:
            single = Formulas.cleric_heal(heal_base, mana)
        Enums.CharClass.SHAMAN:
            single = int(Formulas.shaman_chain_heal(heal_base, mana)[0])
        Enums.CharClass.DRUID:
            single = Formulas.druid_raid_heal(heal_base, mana)
    match type_id:
        "MIS_HEAL_WRONG":
            var t = _fullest(combatants)
            if t == null:
                return 0
            return _land_heal(round_no, cls, healer, t, single, log, true)
        "MIS_HEAL_CORPSE":
            for t in combatants:
                if t.is_dead():
                    return _land_heal(round_no, cls, healer, t, single, log, true)
            return 0
        "MIS_CHAIN_FIZZLE":
            var chain: Array = Formulas.shaman_chain_heal(heal_base, mana)
            var hit := {}
            var healed := 0
            for hop in chain.size():
                var t = _neediest(combatants, hit) if hop == 0 else _fullest(combatants, hit)
                if t == null:
                    continue
                hit[t] = true
                healed += _land_heal(round_no, cls, healer, t, int(chain[hop]), log, hop > 0)
            return healed
    return 0


## One heal landing on one target: M09's reduction, the target's own rule
## (`Combatant.heal` — a corpse takes nothing), the healer's threat for what
## landed (docs/15 Q-58, `Formulas.HEAL_THREAT_COEF`; the quirk seam's
## multiplier), and the log entry. A heal that restored nothing is logged
## only when `wasted_cast` says the miss is the point — an ordinary Druid
## top-up on a full raider stays silent, as it always did.
static func _land_heal(round_no: int, cls: int, healer, target, amount: int, log,
        wasted_cast: bool = false) -> int:
    var done: int = target.heal(_healed_amount(amount, target, round_no))
    if done > 0:
        healer.add_threat(int(round(Formulas.threat_from(cls, 0.0, float(done))
            * _threat_mult(healer))))
    if done <= 0 and not wasted_cast:
        return 0
    var e = log.emit_heal(round_no, Enums.Phase.HEALERS, healer, target, done,
        target.current_hp)
    e.numbers["threat_after"] = healer.threat
    if wasted_cast:
        e.tier = Enums.LogTier.NUMBERS
        e.numbers["wasted"] = maxi(0, amount - done)
    return done


## docs/10 §10 M09's reduction, applied at exactly ONE place: the healer's cast.
## Every hop of the Shaman's chain and every recipient of the Druid's raid heal
## pays it, because all three are healing.
##
## Deliberately NOT inside `Combatant.heal`. docs/11 §7's Minor Healing Potion
## comes through the same method, and that is gold the player spent — a boss
## debuff has no business eating it unless docs/11 says so, and docs/11 does
## not. Putting the reduction in the model would have quietly nerfed the
## consumable economy from a content file.
static func _healed_amount(amount: int, target, round_no: int) -> int:
    var pct: int = target.effective_healing_reduction(round_no)
    if pct <= 0:
        return amount
    return int(round(float(amount) * float(100 - pct) / 100.0))


## The most-in-need valid heal target. Downed raiders come first — that is the
## whole point of the grace round. `skip_above` > 0 leaves out anyone whose HP
## fraction is above it (docs/15 Q-58's 95% line for the chain's later hops);
## 0.0 filters nobody.
static func _neediest(combatants: Array, exclude: Dictionary = {},
        skip_above: float = 0.0):
    var best = null
    for c in combatants:
        if not c.is_valid_heal_target() or exclude.has(c):
            continue
        if c.is_downed():
            return c
        if skip_above > 0.0 and c.hp_fraction() > skip_above:
            continue
        if best == null or c.hp_fraction() < best.hp_fraction():
            best = c
    return best


## The LEAST-in-need valid heal target — docs/07 §5.2 row 6's "highest-HP
## valid target", where a wrong heal goes. Ties to the earlier slot; a Downed
## raider is never the fullest.
static func _fullest(combatants: Array, exclude: Dictionary = {}):
    var best = null
    for c in combatants:
        if not c.is_valid_heal_target() or exclude.has(c) or c.is_downed():
            continue
        if best == null or c.hp_fraction() > best.hp_fraction():
            best = c
    return best


# ---------------------------------------------------------------- phases 5-7

## docs/10 §10 M03: "`X`/round to raiders flagged in-zone; a raider re-rolls out
## at `p` per round." Phase 5 is where docs/07 §5.2 row 1 puts the tick.
##
## The ENTRY is not here and never was: a raider is in the zone because they
## failed a mechanic check and drew MIS_FIRE or MIS_MECHANIC_DROP, both of which
## emit the Fire token through `_apply_mistake`. That is why m03 needed a roll
## site and a cadence reading before it could fire at all, rather than more code.
static func _phase_effects(rng, round_no: int, combatants: Array, encounter, log) -> void:
    for spec in encounter.mechanics:
        if spec.mechanic != Enums.Mechanic.GROUND_EFFECT:
            continue
        var dmg := int(spec.params.get("damage_per_round", 20))
        # The exit. `escape_chance_bp` has been authored on E4 and E5 since the
        # content landed and was read nowhere, so the zone was permanent —
        # Enums.TOKEN_DURATION[Token.FIRE] is -1, "until cleared", and nothing
        # cleared it. An encounter that omits the param keeps that permanence,
        # deliberately: a zone you cannot leave is a legitimate mechanic and it
        # should not be the accidental default.
        var escape_bp := int(spec.params.get("escape_chance_bp", 0))
        for c in combatants:
            if not (c.is_alive() and c.has_token(Enums.Token.FIRE)):
                continue
            _apply_damage(round_no, Enums.Phase.EFFECTS, c, dmg, log, "the fire")
            if not c.is_alive():
                continue
            # ONE exit, and it is docs/10 §10 M03's: "a raider re-rolls out at
            # `p` per round". docs/07 §5.2 row 1's "leaves at end of next round"
            # is the EXPECTED OUTCOME of a 50% per-round re-roll, not a second
            # rule — docs/15 BL-86 records it, and this
            # is the only reading content can parameterise.
            #
            # It used to be both: an unconditional "out at end of the round
            # after entry" ran BEFORE the re-roll, so `escape_chance_bp` only
            # ever chose between one tick and two, no encounter could hold a
            # raider longer, and the permanent zone Q-M03 describes did not
            # exist in the code at all. Docs and sim now agree.
            var out: bool = escape_bp > 0 \
                and int(rng.derive("fire_escape", round_no, c.slot_index)
                    .next_below(10000)) < escape_bp
            if out:
                c.clear_token(Enums.Token.FIRE)
                log.emit_system(round_no,
                    "%s finally steps out of the fire." % c.display_name())
    for c in combatants:
        c.expire_tokens(round_no)


static func _phase_ambient(rng, round_no: int, combatants: Array, enemies: Array,
        db, log, round_state: Dictionary, mstate: Dictionary = {}) -> void:
    for c in combatants:
        if not c.is_alive():
            continue
        var p: Dictionary = c.get_meta("profile")
        var ctx = Mistakes.Context.new()
        ctx.roll_site = Enums.RollSite.AMBIENT
        ctx.round_no = round_no
        ctx.phase = Enums.Phase.AMBIENT_MISTAKE
        ctx.live_tokens = c.live_tokens()
        ctx.boss_low = _boss_low(enemies)
        ctx.cooldowns = _cooldowns_of(c)
        ctx.criticals_this_round = int(round_state["criticals"])
        ctx.tutorial = bool(mstate.get("tutorial", false))
        ctx.zone_exists = bool(mstate.get("zone_exists", false))
        _stamp_actor(ctx, c, mstate)
        var stream: int = 200 + c.slot_index
        var gate = rng.derive("mistake_gate", round_no, stream)
        var ev = Mistakes.roll(gate, int(p["class_id"]), int(p["role_group"]),
            c.raider.rarity, _sim_morale(c), ctx,
            _situational_bp(c, combatants, Enums.RollSite.AMBIENT), 1.0,
            _relief_bp(c))
        if ev != null:
            ev.actor_id = c.raider.id
            ev.channel = _channel("mistake_gate", round_no, stream)
            _attribute(ev, c, combatants)
            _record(ctx, c, round_state, ev)
            _log_mistake(log, round_no, Enums.Phase.AMBIENT_MISTAKE, c, ev, mstate)
            _apply_mistake(rng, round_no, Enums.Phase.AMBIENT_MISTAKE, c, combatants,
                enemies, ev, log, mstate)


static func _phase_close(round_no: int, combatants: Array, log) -> void:
    for c in combatants:
        if c.confirm_death_at_round_close():
            log.emit_state_change(round_no, Enums.Phase.ROUND_CLOSE, c, "DEAD")
    _expire_mechanic_debuffs(round_no, combatants, log)


## Round Close: the timed mechanic debuffs that have run out.
##
## Announced, because a player who watched the healing get cut needs to see it
## come back — docs/10 §6's "a star that buys nothing is a lie" cuts both ways,
## and an invisible recovery reads as the debuff never ending. Silence is
## reported as one line for the whole raid rather than one per caster: M10 hits
## five or six people at once and six identical lines is docs/07 §5.5's wall.
static func _expire_mechanic_debuffs(round_no: int, combatants: Array, log) -> void:
    var freed := 0
    for c in combatants:
        if c.healing_reduction_pct > 0 and round_no > c.healing_reduction_until:
            c.healing_reduction_pct = 0
            c.healing_reduction_until = 0
            log.emit_mechanic(round_no, Enums.Phase.ROUND_CLOSE,
                Enums.Mechanic.HEALING_DEBUFF,
                "%s can be healed properly again." % c.display_name())
        if c.silenced_until > 0 and round_no > c.silenced_until:
            c.silenced_until = 0
            freed += 1
    if freed > 0:
        log.emit_mechanic(round_no, Enums.Phase.ROUND_CLOSE, Enums.Mechanic.MANA_BURN,
            "The silence lifts; %d of the raid can cast again." % freed)


# ================================================================ helpers

## `ignores_ac` is docs/10 §5.4's raid-wide reading: the pulse's raw value IS the
## number that lands, so the encounter's pressure sits on the healers rather than
## on the tank's gear score. Default false so every ordinary swing keeps its AC
## path byte-identical; only the M02 branch passes true. The Downed/Dead
## bookkeeping stays here — a second damage path would drift from this one.
static func _apply_damage(round_no: int, phase: int, target, raw: int, log,
        source: String, ignores_ac: bool = false) -> void:
    if not target.is_valid_boss_target():
        return
    var p: Dictionary = target.get_meta("profile")
    # The encounter's tier rides on the profile (SIM-22): docs/15 BL-72's
    # `AC_K` step is per tier and this is the one place armour is read.
    var dealt: int = raw if ignores_ac \
        else Formulas.damage_after_ac(float(raw), int(p["ac"]), int(p.get("tier", 1)))
    var before: int = target.state
    target.take_damage(dealt)
    log.emit_attack(round_no, phase, source, target, dealt, target.current_hp)
    if before != target.state:
        if target.is_downed():
            log.emit_state_change(round_no, phase, target, "DOWNED")
        elif target.is_dead():
            log.emit_state_change(round_no, phase, target, "DEAD")


## The taxonomy KEY and the severity KEY go on the entry, not their display
## names: `LogPlayer.severity_of` and any line corpus look both up as keys, and
## sending names made the comedy brake dead and the header print "?" while every
## test kept passing (docs/13 §11.2, §11.3).
static func _log_mistake(log, round_no: int, phase: int, c, ev,
        mstate: Dictionary = {}) -> void:
    _draw_joke(mstate.get("jokes", null), c, ev)
    log.emit_mistake(round_no, phase, c, ev.type_id, ev.type_name,
        ev.severity_key(), ev.caused_by, ev.cascade_depth,
        ev.log_template_id, ev.log_line, ev.debug_dict())


## docs/07 §5.1's `log_template_id`, and §10.3's rendered line.
##
## Drawn HERE because every one of the four roll sites already funnels through
## `_log_mistake`, so there is exactly one place a mistake can acquire a joke
## and no site can forget to. The gates are the ones the corpus itself offers:
## severity and class make a line apter, and a Legendary's own variants win when
## they have one for this failure (docs/07 §10.3 rule 4). A pool with nothing to
## say leaves both fields empty, which is what every render site is written
## against.
static func _draw_joke(bag, c, ev) -> void:
    if bag == null or ev == null or c == null or c.raider == null:
        return
    var chosen: Dictionary = bag.draw(ev.type_id, ev.severity,
        Enums.class_key(int(c.get_meta("profile")["class_id"])),
        c.raider.legendary_def_id)
    if chosen.is_empty():
        return
    ev.log_template_id = String(chosen["id"])
    ev.log_line = MistakeLines.fill(String(chosen["text"]), c.raider.display_name)


## The mechanical consequence of a mistake. docs/07 §5.2's effect column,
## every row of it (W7-SIM-EFFECTS): a type that prints its line and changes
## nothing is a lie in the log. `rng` is for the one row that has to draw —
## MIS_ARGUMENT's "one random other" — on its own channel, so the pick cannot
## move any other roll.
static func _apply_mistake(rng, round_no: int, phase: int, actor, combatants: Array,
        enemies: Array, ev, log, mstate: Dictionary = {}) -> void:
    for token in ev.tokens_emitted:
        # WITH the source event: `Combatant.token_sources` is docs/07 §6 rule
        # 1's cascade edge — which mistake put this token here — and `tokens`
        # stores only an expiry round. `_parent_for` reads it back at the next
        # roll and `Mistakes.attribute` writes the edge (SIM-05). `tokens_emitted`
        # is read here AFTER attribution, so an event at the depth cap has
        # already been emptied and the chain terminates.
        actor.add_token(token, round_no, ev)
    match ev.type_id:
        "MIS_AGGRO":
            # docs/07 §8.2: "sets the offender above the primary target
            # regardless of accumulated threat" — past the offender's OWN
            # retarget bar, so the boss turns at the next Phase 1 whatever
            # the hysteresis says (SIM-17).
            var top := 0
            for c in combatants:
                top = maxi(top, c.threat)
            actor.threat = Formulas.aggro_pull_threat(float(top), _is_melee(actor))
        "MIS_TAUNT_LAPSE":
            # docs/15 Q-57's Lost Aggro: the tank's action-site mistake zeroes
            # its threat for the boss's FIRST swing next round — swing 2
            # resolves on the tank. Only bites the tank the boss is on;
            # `_pick_enemy_target` checks the enemy's remembered target.
            actor.lost_aggro_round = round_no + 1
        "MIS_AFK":
            # docs/07 §5.2 row 9: "No action for 1-3 rounds (severity picks
            # duration)". The row prices MISSED ACTIONS, so the window is
            # counted from the first action the raider does not take. The
            # ambient roll is Phase 6, past every action of its own round, so
            # its window opens next round; an action-site roll already ate this
            # round's action (`_take_action` returns on a mistake), and that is
            # the first of the `away` — counting from the next round as well
            # would make a Minor AFK cost two actions and a Severe four.
            var away: int = AFK_ROUNDS_BY_SEVERITY[clampi(ev.severity, 0,
                AFK_ROUNDS_BY_SEVERITY.size() - 1)]
            var last_away: int = round_no + away
            if int(ev.roll_site) != Enums.RollSite.AMBIENT:
                last_away -= 1
            actor.afk_until = maxi(actor.afk_until, last_away)
            _say(log, Enums.LogTier.STORY, round_no, phase, "afk", actor,
                "%s has wandered off for %s." % [actor.display_name(), _rounds_word(away)],
                {"rounds": away})
        "MIS_LOOT_CALL":
            # docs/07 §5.2 row 17: "Skips next action. Flags a post-encounter
            # morale event" — the skip is spent by the next action phase, the
            # flag is counted here and queued for `game/` in `_queue_deltas`.
            actor.skip_next_action = true
            actor.loot_calls += 1
        "MIS_ARGUMENT":
            # docs/07 §5.2 row 16: "Both this raider and one random other take
            # a mistake-chance penalty for the rest of the encounter." The
            # other is drawn on the seeded `argument` channel; both carry the
            # same SET penalty, read by `_situational_bp`.
            actor.argument_penalty_bp = maxi(actor.argument_penalty_bp, ARGUMENT_PENALTY_BP)
            var other = _pick_argument_partner(rng, round_no, actor, combatants)
            if other != null:
                other.argument_penalty_bp = maxi(other.argument_penalty_bp, ARGUMENT_PENALTY_BP)
                _say(log, Enums.LogTier.STORY, round_no, phase, "argument", actor,
                    "%s drags %s into it." % [actor.display_name(), other.display_name()],
                    {"with_id": other.raider.id})
        "MIS_NO_CONSUMABLE":
            # docs/07 §5.2 row 15: "Assigned consumable's buff is not applied
            # for the whole encounter. Item is not consumed." The provision
            # comes back out of the profile it was folded into, and the row
            # goes to `result.consumables_unspent` for `game/` to honour.
            _strip_provisions(round_no, actor, log, mstate)
        "MIS_INTERRUPT_WRONG":
            # docs/07 §5.2 row 5: "interrupt on cooldown 2 rounds". On the
            # combatant's meta rather than a file-level static — two encounters
            # may never share it, and the cooldown outlives the round.
            actor.set_meta("interrupt_cd_until", round_no + INTERRUPT_COOLDOWN_ROUNDS)
        "MIS_WRONG_TARGET":
            # docs/07 §5.2 row 11: "Damage goes into a non-priority or immune
            # target; priority target unharmed this round." The swing is not
            # lost — it lands on a live add (SIM-15). SIM-08's full priority
            # table is wave 8's; until then the only non-priority thing in the
            # room IS an add, and with no add there the round's damage is gone,
            # which is what the mistake did before it had a consequence.
            _swing_into_the_wrong_target(round_no, phase, actor, enemies, log)
        "MIS_AVOIDABLE_DEATH":
            actor.kill()
            log.emit_state_change(round_no, phase, actor, "DEAD")
        "MIS_BROKE_CC", "MIS_FACEPULL":
            var add := Enemy.new()
            add.name = "Loose Add"
            add.hp = 90
            add.max_hp = 90
            # An add that wanders in after M06 wanders into the enraged fight.
            add.raw_swing = _spawn_swing(9, mstate)
            add.threat_rule = "lowest_hp"
            add.is_add = true
            enemies.append(add)


## docs/07 §5.2 row 11's "non-priority target": the first living ADD, which is
## the only other thing in the room until SIM-08 lands wave 8's priority table.
## The damage and the threat are real — that is what makes the mistake cost the
## boss's health bar rather than the raider's, and what makes an Adds cascade
## worth the raid's attention. Nothing happens when there is no add, exactly as
## before: the priority target is unharmed and the round's swing is gone.
static func _swing_into_the_wrong_target(round_no: int, phase: int, actor,
        enemies: Array, log) -> void:
    var wrong = null
    for e in enemies:
        if e.is_add and e.active and e.is_alive():
            wrong = e
            break
    if wrong == null:
        return
    var p: Dictionary = actor.get_meta("profile")
    var raw := _outgoing_damage(p, enemies)
    if raw <= 0.0:
        return
    var dealt := Formulas.final_value(raw)
    wrong.hp = maxi(0, wrong.hp - dealt)
    actor.add_threat(int(round(Formulas.threat_from(int(p["class_id"]), raw)
        * _threat_mult(actor))))
    log.emit_attack(round_no, phase, actor, wrong.name, dealt, wrong.hp, actor.threat)
    if wrong.hp <= 0:
        log.emit_system(round_no, "%s dies." % wrong.name, Enums.LogTier.PLAY_BY_PLAY)


## A SYSTEM line about ONE raider, with the entry's actor fields filled the
## way `emit_attack` fills them — so a screen or a test can find the line by
## `actor_id` rather than by parsing the sentence. `emit_system` cannot: it
## stamps ROUND_CLOSE and knows no actor, and a round-open line wearing the
## closing phase breaks the log's phase ordering (see `_note_gap`).
static func _say(log, tier: int, round_no: int, phase: int, template_id: String, actor,
        text: String, extra: Dictionary = {}) -> void:
    var params: Dictionary = extra.duplicate()
    params["text"] = text
    var e = log.emit(Enums.Verb.SYSTEM, tier, round_no, phase, template_id, params)
    if actor != null and actor.raider != null:
        e.actor_id = actor.raider.id
        e.actor_name = actor.display_name()
        e.actor_class = int(actor.raider.class_id)


## "for a round" / "for two rounds" / "for three rounds": the AFK line is read
## on RaidView, and a digit in a sentence reads like a stat.
static func _rounds_word(n: int) -> String:
    match n:
        1: return "a round"
        2: return "two rounds"
        3: return "three rounds"
    return "%d rounds" % n


## docs/07 §5.2 row 16's "one random other": a living raider who is not the
## one arguing, drawn on the seeded `argument` channel keyed by round and
## slot — derived from the master seed like every other draw, so the pick is
## replayable and consumes nothing from any other stream. Null when nobody
## else is standing.
static func _pick_argument_partner(rng, round_no: int, actor, combatants: Array):
    var others := []
    for c in combatants:
        if c != actor and c.is_alive():
            others.append(c)
    if others.is_empty() or rng == null:
        return null
    var pick = rng.derive("argument", round_no, actor.slot_index)
    return others[pick.next_below(others.size())]


## docs/07 §5.2 row 15: take the forgotten provisions back out of the profile
## `_gear_profile` folded them into, and report each as unspent. Everything
## this raider CARRIES goes — the kit or draught (the group buff they were
## handed a share of) and their own Steady Hands. The Guild Feast is eaten in
## town and is not a thing a raider carries, so `sim_morale` stays.
static func _strip_provisions(round_no: int, actor, log, mstate: Dictionary) -> void:
    var p: Dictionary = actor.get_meta("profile")
    var unspent: Array = mstate.get("consumables_unspent", [])
    var forgotten: Array[String] = []
    if int(p.get("power_bonus", 0)) > 0:
        p["power"] = int(p["power"]) - int(p["power_bonus"])
        p["power_bonus"] = 0
        forgotten.append("whetstone_kit")
    if int(p.get("mana_bonus", 0)) > 0:
        p["mana"] = int(p["mana"]) - int(p["mana_bonus"])
        p["mana_bonus"] = 0
        forgotten.append("mana_draught")
    if _bought_relief_bp(actor) > 0.0:
        actor.set_meta("relief_bp", 0.0)
        forgotten.append("potion_of_steady_hands")
    for sku in forgotten:
        unspent.append({"raider_id": actor.raider.id, "sku": sku, "reason": "no_consumable"})
    mstate["consumables_unspent"] = unspent
    if forgotten.is_empty():
        return
    _say(log, Enums.LogTier.STORY, round_no, Enums.Phase.ROUND_OPEN, "no_consumable", actor,
        "%s left the %s in the bag." % [actor.display_name(),
            " and the ".join(_provision_names(forgotten))],
        {"skus": forgotten.duplicate()})


static func _provision_names(skus: Array) -> Array[String]:
    var out: Array[String] = []
    for sku in skus:
        match String(sku):
            "whetstone_kit": out.append("whetstone")
            "mana_draught": out.append("draught")
            "potion_of_steady_hands": out.append("steadying potion")
            _: out.append(String(sku).replace("_", " "))
    return out


## Does this raider carry a provision to forget? docs/07 §5.2 row 15 gates on
## it (`Context.consumable_carried`): the kit or draught share folded into
## their profile, or a Steady Hands bought for them by name.
static func _carries_provision(c) -> bool:
    var p: Dictionary = c.get_meta("profile")
    return int(p.get("power_bonus", 0)) > 0 or int(p.get("mana_bonus", 0)) > 0 \
        or _bought_relief_bp(c) > 0.0


## The Steady Hands bought for this raider, and nothing else — not the quirk
## seam's bonus, which is not a thing anybody can leave in a bag.
static func _bought_relief_bp(c) -> float:
    if c == null or not c.has_meta("relief_bp"):
        return 0.0
    return float(c.get_meta("relief_bp"))


## The facts about the ACTOR every roll site's context carries (W7-SIM-EFFECTS):
## the tank seat (docs/07 §5.2 row 9), the provision (row 15) and the quirk
## seam (Q58-4). One helper so the two hand-built contexts and `_context`
## cannot disagree.
static func _stamp_actor(ctx, c, mstate: Dictionary = {}) -> void:
    ctx.is_tank = c.is_main_tank or c.is_offtank
    ctx.consumable_carried = _carries_provision(c)
    ctx.quirk_id = _quirk_id(c)
    ctx.quirks_enabled = bool(mstate.get("quirks_enabled", _quirks_on(c)))


## Per-combatant type cooldowns, persisted on the combatant across rounds.
static func _cooldowns_of(c) -> Dictionary:
    if not c.has_meta("cooldowns"):
        c.set_meta("cooldowns", {})
    return c.get_meta("cooldowns")


## Arm the guards after a mistake fires. Without this the per-type cooldown and
## the raid-wide Critical cap are decorative — they were, until this was wired up.
static func _record(ctx, c, round_state: Dictionary, ev) -> void:
    Mistakes.note_fired(ctx, ev)
    c.set_meta("cooldowns", ctx.cooldowns)
    round_state["criticals"] = ctx.criticals_this_round


static func _context(site: int, round_no: int, phase: int, c, enemies: Array, encounter,
        round_state: Dictionary = {}, mstate: Dictionary = {}):
    var ctx = Mistakes.Context.new()
    ctx.cooldowns = _cooldowns_of(c)
    ctx.criticals_this_round = int(round_state.get("criticals", 0))
    ctx.roll_site = site
    ctx.round_no = round_no
    ctx.phase = phase
    ctx.live_tokens = c.live_tokens()
    ctx.adds_present = _living_enemies(enemies) > 1
    ctx.boss_low = _boss_low(enemies)
    ctx.trash_phase = encounter.kind == Enums.EncounterKind.TRASH \
        or encounter.kind == Enums.EncounterKind.HARD_TRASH
    ctx.interrupt_check = encounter.has_mechanic(Enums.Mechanic.INTERRUPT_CHECK)
    ctx.zone_exists = encounter.has_mechanic(Enums.Mechanic.GROUND_EFFECT)
    ctx.tutorial = _is_tutorial(encounter)
    _stamp_actor(ctx, c, mstate)
    return ctx


## docs/07 OQ-9's ruling (docs/15): is this one of docs/10 §9's two onboarding
## rungs? Asked of the reputation ledger's slot table rather than of a slot
## string here, because "A0"/"TR" is the contract that pays the tutorial RP
## (sim/core/Reputation.gd) and the one place the tree already keys them.
static func _is_tutorial(encounter) -> bool:
    if encounter == null:
        return false
    return Reputation.is_tutorial_slot(String(encounter.slot))


## docs/11 §7's safety net: "Auto-spent by the sim when a participant drops below 30%
## HP; restores 25% of max HP. One per raider per encounter maximum."
##
## It runs AFTER the healers and the effect tick, because a potion is what happens when
## healing was not enough — spending it first would burn gold the healer would have
## saved. Deterministic: the party is walked in slot order, which is how every other
## phase in this file resolves ties.
static func _phase_potions(round_no: int, combatants: Array, log,
        pouch: Dictionary) -> void:
    if int(pouch.get("count", 0)) <= 0:
        return
    var used: Dictionary = pouch["used"]
    for c in combatants:
        if int(pouch["count"]) <= 0:
            return
        if not c.is_alive() or used.has(c.raider.id):
            continue
        if c.hp_fraction() >= Consumables.POTION_TRIGGER_FRACTION:
            continue
        var amount := int(round(float(c.max_hp)
            * float(pouch["heal_pct"]) / 100.0))
        if amount <= 0:
            continue
        var healed: int = c.heal(amount)
        used[c.raider.id] = true
        pouch["count"] = int(pouch["count"]) - 1
        pouch["spent"] = int(pouch["spent"]) + 1
        # A system line rather than a HEAL verb: `result.healing_done` is the healers'
        # number, and gold should not flatter them.
        log.emit_system(round_no,
            "%s drains a potion. (+%d HP)" % [c.raider.display_name, healed])


## docs/11 §7's Potion of Steady Hands, in basis points, for the raider it was bought
## for. Zero for everyone else.
static func _relief_bp(c) -> float:
    if c == null:
        return 0.0
    var bp := 0.0
    if c.has_meta("relief_bp"):
        bp = float(c.get_meta("relief_bp"))
    # docs/04 §11.2's quirk seam, `relief_bp_bonus` (Q58-4): 0.0 while
    # `Quirks.SPECS` is empty, and for every non-Legendary regardless.
    return bp + Quirks.relief_bp_bonus(_quirk_id(c), _quirks_on(c))


## The morale the SIMULATION runs at. docs/11 §7's Guild Feast raises this and leaves
## the stored value alone, so every mistake roll reads it rather than `raider.morale`.
static func _sim_morale(c) -> int:
    if c == null or c.raider == null:
        return 50
    if c.has_meta("sim_morale"):
        return int(c.get_meta("sim_morale"))
    return int(c.raider.morale)


## docs/07 §6's token table, the "Effect on later rolls" column, read for the
## RAIDER WHO IS ROLLING against the RAID's live tokens (SIM-06):
##
##   Aggro        "Healers' mistake chance +8pp (they are panic-targeting)" — the
##                healers' rolls, at any site, while anybody holds it.
##   Distraction  "+5pp ambient mistake chance, raid-wide" — the ambient roll,
##                for everybody, while anybody holds it.
##
## It used to read the tokens on the ROLLER: Greg's Aggro made Greg 8pp clumsier
## and did nothing to Cindy, and Steve's argument distracted only Steve. Fire
## and Adds are not roll modifiers (Fire gates MIS_AVOIDABLE_DEATH through
## `requires_token`; Adds is the check-volume amplifier, SIM-15's). Rule 4's cap
## is docs/08's `SITUATIONAL_CAP_BP` and `Formulas.mistake_chance_bp` clamps to
## it as well; the sum here cannot reach it, and the clamp stays so a future
## row cannot quietly exceed the doc.
static func _situational_bp(c, combatants: Array, site: int) -> int:
    var bp := 0
    if _is_healer(c) and _raid_holds(combatants, Enums.Token.AGGRO):
        bp += 800
    if site == Enums.RollSite.AMBIENT and _raid_holds(combatants, Enums.Token.DISTRACTION):
        bp += 500
    # docs/07 §5.2 row 16: an argument's penalty follows BOTH parties for the
    # rest of the encounter, at every site (`ARGUMENT_PENALTY_BP`).
    bp += maxi(0, int(c.argument_penalty_bp))
    return mini(bp, Formulas.SITUATIONAL_CAP_BP)


static func _is_healer(c) -> bool:
    return int(c.get_meta("profile")["role_group"]) == Enums.RoleGroup.HEALER


## Somebody in the raid who is not Dead holds this token. Downed counts: a
## raider at 0 HP holding Aggro is exactly the one the healers are panicking
## over (docs/07 §6's worked cascade gives Cindy her +8pp in the round Greg
## went Downed). The dead are excluded — their tokens are never cleared, and
## nobody panics over a corpse.
static func _raid_holds(combatants: Array, token: int) -> bool:
    for c in combatants:
        if not c.is_dead() and c.has_token(token):
            return true
    return false


## The event that put this token on somebody in the raid — the most recent
## one, because docs/07 §6's chain "follows the mistake that most recently put
## the token there" (`Combatant.add_token`); ties, if two mistakes in one round
## both emitted it, resolve by slot order so the pick is a pure function of the
## seed. Null when nobody who is not Dead holds it.
static func _raid_token_source(combatants: Array, token: int):
    var best = null
    for c in combatants:
        if c.is_dead() or not c.has_token(token):
            continue
        var src = c.token_source(token)
        if src == null:
            continue
        if best == null or src.round_no > best.round_no:
            best = src
    return best


## docs/07 §6 rule 1's parent for a freshly rolled mistake, or null when it is
## a root (SIM-05). When several tokens are live the tie-break is the plan's
## recommended default: the live token whose "Effect on later rolls" column
## names THIS roll, else the oldest live token on the actor.
##
##   1. A cascade-only type was enabled by a token on the actor (rule 3):
##      MIS_AVOIDABLE_DEATH -> the actor's Fire, else the actor's Adds.
##   2. A healer's roll under Aggro -> the raid's Aggro source; an ambient roll
##      under Distraction -> the raid's Distraction source — the same two
##      readings `_situational_bp` just applied to the chance.
##   3. Else the oldest live token on the actor, by the round its source fired.
##   4. Else none: a new root.
##
## Only the actor's own tokens count in 3, not the raid's — every miserable
## raid holds Aggro somewhere most of the time, and "everything rolled while
## anybody held anything" would put the whole fight at depth 3 and, through the
## depth cap, stop most tokens from ever being emitted.
static func _parent_for(ev, c, combatants: Array):
    if ev == null or c == null:
        return null
    var t: Dictionary = Mistakes.TYPES.get(ev.type_id, {})
    if bool(t.get("cascade_only", false)):
        for tok in t.get("requires_token", []):
            var src = c.token_source(int(tok))
            if src != null:
                return src
    if _is_healer(c):
        var aggro = _raid_token_source(combatants, Enums.Token.AGGRO)
        if aggro != null:
            return aggro
    if ev.roll_site == Enums.RollSite.AMBIENT:
        var distraction = _raid_token_source(combatants, Enums.Token.DISTRACTION)
        if distraction != null:
            return distraction
    var oldest = null
    for tok in c.live_tokens():
        var src = c.token_source(int(tok))
        if src == null:
            continue
        if oldest == null or src.round_no < oldest.round_no:
            oldest = src
    return oldest


## The one call that writes `caused_by` / `cascade_depth`, at every roll site,
## after the event exists and before it is recorded, logged or applied. Draws
## nothing from the RNG.
static func _attribute(ev, c, combatants: Array) -> void:
    Mistakes.attribute(ev, _parent_for(ev, c, combatants))


## docs/07 §10.1's channel field: the exact `Rng.derive(name, round, stream)`
## triple the gate was drawn on, so a tier-3 line names the one draw a bug
## report needs to replay.
static func _channel(name: String, round_no: int, stream: int) -> String:
    return "%s:r%d:%d" % [name, round_no, stream]


static func _pick_enemy(enemies: Array):
    for e in enemies:
        if e.active and e.is_alive():
            return e
    return null


static func _living_enemies(enemies: Array) -> int:
    var n := 0
    for e in enemies:
        if e.active and e.is_alive():
            n += 1
    return n


static func _boss_low(enemies: Array) -> bool:
    for e in enemies:
        if e.active and e.is_alive():
            return e.hp_fraction() <= 0.25
    return false


static func _has_corpse(combatants: Array) -> bool:
    for c in combatants:
        if c.is_dead():
            return true
    return false


static func _all_down(combatants: Array) -> bool:
    for c in combatants:
        if c.is_alive() or c.is_downed():
            return false
    return true


static func _living_healers(combatants: Array) -> int:
    var n := 0
    for c in combatants:
        if c.is_alive() and int(c.get_meta("profile")["role_group"]) == Enums.RoleGroup.HEALER:
            n += 1
    return n


## docs/07 §5.3's one-shot before round 1. The channel is `encounter_start`
## (SIM-24): it was `compliance`, a leftover from the Calls that docs/15 Q-09
## cut, and a channel name is what a bug report and docs/07 §9 read.
static func _roll_encounter_start_mistakes(rng, combatants: Array, db, log,
        mstate: Dictionary = {}) -> void:
    for c in combatants:
        var p: Dictionary = c.get_meta("profile")
        var ctx = Mistakes.Context.new()
        ctx.roll_site = Enums.RollSite.AMBIENT
        ctx.round_no = 0
        ctx.encounter_start = true
        ctx.tutorial = bool(mstate.get("tutorial", false))
        ctx.zone_exists = bool(mstate.get("zone_exists", false))
        _stamp_actor(ctx, c, mstate)
        var gate = rng.derive("encounter_start", 0, c.slot_index)
        var ev = Mistakes.roll(gate, int(p["class_id"]), int(p["role_group"]),
            c.raider.rarity, _sim_morale(c), ctx, 0, 1.0, _relief_bp(c))
        if ev != null:
            ev.actor_id = c.raider.id
            ev.channel = _channel("encounter_start", 0, c.slot_index)
            _attribute(ev, c, combatants)    # nothing is live yet: always a root
            _log_mistake(log, 0, Enums.Phase.ROUND_OPEN, c, ev, mstate)
            # The consequence (SIM-15): until this call existed the forgotten
            # provision stayed applied and charged.
            _apply_mistake(rng, 0, Enums.Phase.ROUND_OPEN, c, combatants, [], ev, log, mstate)


## docs/07 §7.3. Returns an Outcome, or -1 to keep fighting.
static func _check_end(combatants: Array, enemies: Array, encounter,
        round_no: int, log) -> int:
    if _living_enemies(enemies) == 0:
        log.emit_system(round_no, "%s is defeated." % encounter.display_name)
        return Outcome.VICTORY
    var standing := 0
    for c in combatants:
        if c.is_alive() or c.is_downed():
            standing += 1
    if standing == 0:
        log.emit_system(round_no, "WIPE.")
        return Outcome.WIPE
    if _living_healers(combatants) == 0:
        var boss = _pick_enemy(enemies)
        if boss != null and boss.hp_fraction() > SOFT_WIPE_BOSS_HP_FRACTION:
            # Logged explicitly as an auto-call so it never reads as a crash.
            log.emit_system(round_no,
                "No healers left and the boss is barely scratched. The raid calls it.")
            return Outcome.SOFT_WIPE
    if round_no >= encounter.enrage_round + 5:
        return Outcome.ATTRITION
    return -1


## Whose mistake triggered the wipe (docs/01 §6.1, §6.4; the rule is at
## `WIPE_CULPRIT_DELTA`). Reads the finished log, so it is pure and replayable:
##
##   1. The LAST Severe-or-worse mistake logged before the first tank or healer
##      is confirmed Dead — the failure the fight never recovered from.
##   2. Else the mistake with the deepest `cascade_depth` (the longest chain the
##      raid was still running; ties go to the later one).
##   3. Else empty: nobody — the boss simply won.
##
## "Severe" reads as Severe OR Critical: a Critical is a worse Severe, and
## a rule that blamed a Severe over the Critical beside it would be absurd.
## Clause 1 needs a tank/healer death to anchor "before"; a loss with none
## (attrition with everybody standing) goes straight to the chains.
static func _wipe_cause(log, combatants: Array) -> Dictionary:
    var mistakes: Array = log.mistakes()
    if mistakes.is_empty():
        return {}
    var roles := {}
    for c in combatants:
        roles[c.raider.id] = int(c.get_meta("profile")["role_group"])
    var first_death := -1
    for e in log.entries:
        if e.verb != Enums.Verb.STATE_CHANGE or String(e.params.get("state", "")) != "DEAD":
            continue
        var role: int = int(roles.get(e.actor_id, -1))
        if role == Enums.RoleGroup.TANK or role == Enums.RoleGroup.HEALER:
            first_death = e.sequence
            break
    var pick = null
    if first_death >= 0:
        for e in mistakes:
            if e.sequence < first_death and e.severity_index() >= Enums.Severity.SEVERE:
                pick = e
    if pick == null:
        var deepest := 0
        for e in mistakes:
            var d: int = int(e.mistake.get("cascade_depth", 0))
            if d > 0 and d >= deepest:
                deepest = d
                pick = e
    if pick == null:
        return {}
    return {
        "actor_id": String(pick.actor_id),
        "mistake_type": String(pick.mistake.get("type", "")),
        "round": int(pick.round_no),
        "entry_seq": int(pick.sequence),
    }


## The cause, on the record. docs/01 §6.4: the post-mortem names "the raider at
## fault, the specific mistake" — so the log's last Story line on a loss says
## which entry it was. Structured under template `wipe_cause` with the same
## four fields as `SimResult.wipe_cause`, so the report can render its own
## sentence from the entry (W7-REPORT) and the goldens' story carries the fact.
## Never says "wipe": `LogPlayer.is_wipe_line` keys the wipe beat on that word.
## Silent when nobody is to blame — the verdict line above already said the
## boss won, and a sentence blaming nobody is a sentence about nothing.
static func _log_wipe_cause(log, round_no: int, cause: Dictionary) -> void:
    if cause.is_empty():
        return
    var e = log.entries[int(cause["entry_seq"])]
    var params: Dictionary = cause.duplicate()
    params["text"] = "It traces back to %s — %s, round %d." % [
        e.actor_name, e.mistake_name(), int(e.round_no)]
    log.emit(Enums.Verb.SYSTEM, Enums.LogTier.STORY, round_no,
        Enums.Phase.ROUND_CLOSE, "wipe_cause", params)


## docs/14 OQ-10: the sim only reports; `game/` applies these to the roster.
## `wipe_caused` marks the one raider `wipe_cause` names (0 for everybody
## else, and for everybody on a clear); `game/` turns it into docs/05 §7.1's
## `wipe_caused` morale trigger, whose delta is `WIPE_CULPRIT_DELTA`.
static func _queue_deltas(result, combatants: Array) -> void:
    var wiped: bool = result.outcome != Outcome.VICTORY
    var culprit := String(result.wipe_cause.get("actor_id", ""))
    for c in combatants:
        result.deltas_queued.append({
            "raider_id": c.raider.id,
            "runs_attended": 1,
            "wipes_witnessed": 1 if wiped else 0,
            "wipe_caused": 1 if (wiped and not culprit.is_empty() and c.raider.id == culprit) else 0,
            # docs/07 §5.2 row 17's "post-encounter morale event", counted
            # here and turned into the ledger's trigger by `game/`.
            "loot_call": int(c.loot_calls),
            "died": c.is_dead(),
        })
