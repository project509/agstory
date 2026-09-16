class_name TwgEncounter
extends RefCounted
## One encounter the raid fights, loaded from data/encounters_*.json.
##
## Field set is docs/10 §6's design template. That template exists because 40
## encounters get built across five tiers: if each is authored freehand the sim
## needs 40 special cases. Anything an encounter needs that is not a field here
## is either a mechanic from the §10 vocabulary or a change request against
## docs/07.
##
## Numbers are QUOTED, not authored. Every `hp` total and per-round raw swing
## comes from docs/08 §9.2/§9.3's damage budget; docs/10 only decides how those
## totals split across actors and swings. If docs/08 changes a value, the data
## file changes with it and nothing here is re-derived.

const Enums = preload("res://sim/model/Enums.gd")

static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/model/Encounter.gd")
    return _self_script

## docs/10 §5.2: one round is four seconds at 1x speed, back-solved from the
## 3-8 minute micro loop across five encounters.
const SECONDS_PER_ROUND := 4

## docs/10 §5.2 / §10 M06.
const ENRAGE_MULTIPLIER := 1.4

## docs/10 §6's `comedy_line` is "**Required.** One sentence: what makes this
## funny when it goes wrong. If it cannot be filled in, the encounter is a chore
## and should be cut."
##
## A non-empty check cannot tell a sentence from a space bar, so there is a
## floor — and the floor is a PLACEHOLDER DETECTOR, not a prose rule. It sits far
## below the shortest line the game ships (103 characters, `t1_tut_a0`) because
## its job is to catch "TBD", never to judge whether a joke lands. That judgement
## is docs/16 R-3's human gate and is the one thing in this project no test
## claims to make.
##
## 40 rather than a fresh number, because 40 was already in the tree: three gates
## checked this field and no two agreed — `tests/unit/test_encounters.gd` wanted
## more than 40 characters, `tests/unit/test_adventures.gd` wanted more than 20,
## and the validator wanted only non-empty. The corpus passed all three by
## accident. One constant now, and all three read it.
const COMEDY_LINE_MIN := 40

## The two onboarding rungs (docs/10 §9). They are named here as SLOTS because
## the slot string is the stable contract the rest of the tree keys off —
## sim/core/Reputation.gd's `tutorial_awards` table is keyed "A0"/"TR" and a
## different key costs zero errors and silently pays 0 RP.
const TUTORIAL_SLOTS := ["A0", "TR"]

var id: String = ""
var display_name: String = ""
var tier: int = 1
var slot: String = ""              # E1-E5 for raids, A1-A3 for adventures
var stars: int = 1
var kind: int = Enums.EncounterKind.TRASH
var party_size: int = 12
var tanks_required: int = 2

var enemies: Array = []            # Array[EnemyBlock]
var mechanics: Array = []          # Array[MechanicSpec]
var mistakes_invited: Array = []   # class failure modes this fight punishes
var loot_slots: Array = []         # slot keys, from docs/10 §4.2

var target_rounds: int = 1
var enrage_round: int = 1
var comedy_line: String = ""       # required — see docs/10 §6

## docs/10 §9.1: "Adventure 0 scripts one guaranteed mistake on round 3
## regardless of morale rolls ... this is a content-level override flag on the
## encounter record (`force_mistake_round: 3`), and it exists on exactly one
## encounter in the game." 0 means "no script", which is every other record.
## The premise of the game is that your raiders are bad and the player has to
## SEE that in the first fight, not infer it from a probability table — which is
## why this is content, not a mistake-system rate.
var force_mistake_round: int = 0

## BL-141 (docs/10 §9, docs/01 §8.1): the two tutorials say their lesson where
## it happens — `lesson` is the one line RaidView's band prints over the log
## on a tutorial slot, `lesson_report` the one line Results prints above the
## tally on the Tutorial Raid's WIPE branch. Both are DATA on the record so the
## writing pass owns the words and no screen carries a literal; empty on every
## other encounter, and an empty string is "no band".
var lesson: String = ""
var lesson_report: String = ""

## BL-119 (art/ref/specs/00 §2.3's optional `title`): a boss rung's role
## title — "The Doorman" — shown in the boss plate's title slot with the canon
## ladder words as the subtitle. Empty means the plate prints `display_name`
## as it always has; the enemies' log names are untouched either way.
var title: String = ""


## An enemy stat block. A pack divides the encounter's tank-channel budget
## rather than each mob carrying it, which is why four small swings that can all
## land on one 8 AC caster are the real danger in trash (docs/10 §7.1).
class EnemyBlock extends RefCounted:
    var name: String = ""
    var count: int = 1
    var hp: int = 0
    var raw_swing: int = 0
    var swings_per_round: int = 1
    var threat_rule: String = "standard"
    var spawn_round: int = 0        # 0 = present from the start

    func total_hp() -> int:
        return hp * count

    func total_raw_per_round() -> int:
        return raw_swing * swings_per_round * count


## A configured mechanic: which behaviour, with what parameters.
class MechanicSpec extends RefCounted:
    var mechanic: int = -1
    var params: Dictionary = {}

    func key() -> String:
        return TwgEncounter.Enums.mechanic_key(mechanic)

    func name_of() -> String:
        return TwgEncounter.Enums.mechanic_name_of(mechanic)


# ---------------------------------------------------------------- derived

## Total HP the raid must chew through. Must equal docs/08 §9.2's figure.
func total_hp() -> int:
    var sum := 0
    for e in enemies:
        sum += e.total_hp()
    return sum


## The encounter's tank-channel budget per round, before mitigation. Adds that
## exist as healer pressure sit on top of this and are excluded (docs/10 §7).
func primary_raw_per_round() -> int:
    var sum := 0
    for e in enemies:
        if e.spawn_round == 0 and e.threat_rule != "lowest_hp":
            sum += e.total_raw_per_round()
    return sum


func expected_clear_seconds() -> int:
    return target_rounds * SECONDS_PER_ROUND


## docs/10 §5.2: enrage lands at ceil(1.4 x target_rounds).
static func enrage_for(rounds: int) -> int:
    return int(ceil(ENRAGE_MULTIPLIER * float(rounds)))


## True for the two onboarding rungs of docs/10 §9. Tutorials are the one place
## the content rules bend, so every bend in this file asks this rather than
## testing a slot string of its own.
func is_tutorial() -> bool:
    return slot in TUTORIAL_SLOTS


func has_mechanic(mechanic: int) -> bool:
    for m in mechanics:
        if m.mechanic == mechanic:
            return true
    return false


func mechanic_spec(mechanic: int):
    for m in mechanics:
        if m.mechanic == mechanic:
            return m
    return null


## Role groups this encounter puts under pressure — used by the coverage rule.
func stressed_role_groups() -> Array:
    var out := {}
    for m in mechanics:
        if Enums.MECHANIC_STRESSES.has(m.mechanic):
            out[Enums.MECHANIC_STRESSES[m.mechanic]] = true
    var keys := out.keys()
    keys.sort()
    return keys


func _to_string() -> String:
    return "Encounter(%s %d* hp=%d rounds=%d)" % [id, stars, total_hp(), target_rounds]


# ---------------------------------------------------------------- loading

static func from_dict(d: Dictionary, errors: Array = []):
    var e = _cls().new()
    e.id = String(d.get("id", ""))
    if e.id.is_empty():
        errors.append("encounter with no id")
        return e
    e.display_name = String(d.get("display_name", ""))
    e.tier = int(d.get("tier", 1))
    e.slot = String(d.get("slot", ""))
    e.stars = int(d.get("stars", 1))
    e.party_size = int(d.get("party_size", 12))
    e.tanks_required = int(d.get("tanks_required", 2))
    e.target_rounds = int(d.get("target_rounds", 1))
    e.enrage_round = int(d.get("enrage_round", 0))
    e.comedy_line = String(d.get("comedy_line", ""))
    e.force_mistake_round = int(d.get("force_mistake_round", 0))
    e.lesson = String(d.get("lesson", "")).strip_edges()
    e.lesson_report = String(d.get("lesson_report", "")).strip_edges()
    e.title = String(d.get("title", "")).strip_edges()
    e.mistakes_invited = d.get("mistakes_invited", []).duplicate()
    e.loot_slots = d.get("loot_slots", []).duplicate()

    var kind_key := String(d.get("kind", ""))
    e.kind = Enums.encounter_kind_from_key(kind_key)
    if e.kind < 0:
        errors.append("%s: unknown encounter kind '%s'" % [e.id, kind_key])
        e.kind = Enums.EncounterKind.TRASH

    for raw in d.get("enemies", []):
        var b := EnemyBlock.new()
        b.name = String(raw.get("name", ""))
        b.count = int(raw.get("count", 1))
        b.hp = int(raw.get("hp", 0))
        b.raw_swing = int(raw.get("raw_swing", 0))
        b.swings_per_round = int(raw.get("swings_per_round", 1))
        b.threat_rule = String(raw.get("threat_rule", "standard"))
        b.spawn_round = int(raw.get("spawn_round", 0))
        if b.count <= 0 or b.hp <= 0:
            errors.append("%s: enemy '%s' needs a positive count and hp" % [e.id, b.name])
        e.enemies.append(b)
    if e.enemies.is_empty():
        errors.append("%s: encounter has no enemies" % e.id)

    for raw in d.get("mechanics", []):
        var spec := MechanicSpec.new()
        var mkey := String(raw.get("id", ""))
        spec.mechanic = Enums.mechanic_from_key(mkey)
        if spec.mechanic < 0:
            errors.append("%s: unknown mechanic '%s'" % [e.id, mkey])
            continue
        spec.params = raw.get("params", {}).duplicate(true)
        e.mechanics.append(spec)

    # --- structural rules from docs/10 -----------------------------------
    if e.stars < 1 or e.stars > 5:
        errors.append("%s: stars must be 1-5, got %d" % [e.id, e.stars])
    # "One mechanic per star, no exceptions." A one-star fight with four
    # mechanics is a bug, not a hard encounter (docs/10 §6).
    #
    # The tutorials are the documented exception, and the exemption is one-way.
    # docs/10 §9.1 specifies Adventure 0 with "no mechanics" while `stars` may
    # not be 0, so no (stars, mechanics) pair satisfies both and A0 could not
    # exist at all. Relaxed DOWNWARD only — a tutorial may carry FEWER mechanics
    # than its stars, never more — because docs/10 §6 calls one-per-star the
    # load-bearing constraint for all 42 encounters and the wrong relaxation
    # (`<=` for everything) would delete it silently. Proposed docs/15
    # build-loop entry in build/plan/q-tutorials.md.
    var budget_broken: bool = e.mechanics.size() != e.stars
    if e.is_tutorial():
        budget_broken = e.mechanics.size() > e.stars
    if budget_broken:
        errors.append("%s: %d stars but %d mechanics — docs/10 §6 budgets one per star"
            % [e.id, e.stars, e.mechanics.size()])
    # docs/10 §9.1 permits the scripted mistake on exactly one encounter, and a
    # round the fight is not expected to reach is a content bug rather than a
    # teaching beat: the player would never see it.
    if e.force_mistake_round < 0:
        errors.append("%s: force_mistake_round %d cannot be negative"
            % [e.id, e.force_mistake_round])
    elif e.force_mistake_round > e.target_rounds:
        errors.append("%s: force_mistake_round %d is past target_rounds %d — the scripted"
            % [e.id, e.force_mistake_round, e.target_rounds]
            + " mistake would never fire (docs/10 §9.1)")
    # An authored 0 and an absent field are the same value to
    # game/core/RaidPlan.gd's `tanks_required()` guard, which reads `> 0` and so
    # turns a deliberate 0 into the default 2 — a silent difficulty change with
    # no error anywhere. docs/15's per-fight tank ruling (register Q, the
    # `tanks_required` question, sourced from docs/06 Q6/Q7 and docs/07 OQ-3)
    # sets the default at 2 and tutorials at 1 and never at 0, so 0 is refused
    # here rather than the guard being loosened tier-wide.
    if e.tanks_required <= 0:
        errors.append("%s: tanks_required %d — the ruling is default 2, tutorials 1;"
            % [e.id, e.tanks_required]
            + " 0 reads as 'absent' downstream and silently becomes 2")
    var expected_enrage := enrage_for(e.target_rounds)
    if e.enrage_round != expected_enrage:
        errors.append("%s: enrage_round %d should be ceil(1.4 x %d) = %d"
            % [e.id, e.enrage_round, e.target_rounds, expected_enrage])
    var joke: String = String(e.comedy_line).strip_edges()
    if joke.is_empty():
        errors.append("%s: comedy_line is required — docs/10 §6 says an encounter that cannot"
            % e.id + " be filled in here is a chore and should be cut")
    elif joke.length() < COMEDY_LINE_MIN:
        errors.append(("%s: comedy_line is %d characters; under %d it is a placeholder rather"
            + " than the sentence docs/10 §6 asks for")
            % [e.id, joke.length(), COMEDY_LINE_MIN])
    if e.loot_slots.is_empty():
        errors.append("%s: no loot slots" % e.id)
    return e
