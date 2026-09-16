class_name TwgMistakes
extends RefCounted
## The comedy engine: the mistake taxonomy, and how a failed roll becomes a
## specific, in-character disaster.
##
## docs/07 §5. Canon gives the *dial* — every raider has a mistake chance that
## moves with morale and rarity — and nothing else. No taxonomy, no cadence, no
## severity model. All of that is docs/07's proposal, implemented here.
##
## The equation lives in Formulas.gd (docs/08 owns coefficients). This file owns
## everything that turns "the roll failed" into "Greg saw a big number, chased a
## bigger one, and is now the big number".
##
## `caused_by` and `cascade_depth` are the load-bearing fields. They are what
## lets the post-mortem say "this wipe started when Greg pulled aggro in round 4"
## instead of listing twelve unrelated failures.

const Enums = preload("res://sim/model/Enums.gd")
const Formulas = preload("res://sim/core/Formulas.gd")
const Quirks = preload("res://sim/core/Quirks.gd")

static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/core/Mistakes.gd")
    return _self_script

# ---------------------------------------------------------------- guards

## docs/07 §5.5. Without these a low-morale raid produces an unreadable wall.
const PER_TYPE_COOLDOWN_ROUNDS := 1   # "Steve stood in the fire" x3 reads as a bug
const MAX_CRITICALS_PER_ROUND := 1    # a wipe is a chain, not a simultaneous explosion
const MAX_CASCADE_DEPTH := 3          # docs/07 §6: chains terminate, logs stay readable

## docs/15's tutorial-mistake-rate ruling (DECIDED, answering docs/07 OQ-9):
## "Reduced rate for both tutorials, full rates from Adventure 1 onward". OQ-9
## also names the two types to disable. The ruling gives the direction and not
## the number; 0.5 is the build loop's choice, recorded as docs/15 BL-90 (the
## number itself is the designer's — the ship plan's §6 row #57 asks it; BL-91
## records what the halving did to the Tutorial Raid's pin). Applied to the gate
## chance only — the taxonomy, the
## weights and the severity model are untouched, so a tutorial mistake reads
## exactly like a real one; it just happens half as often.
const TUTORIAL_MISTAKE_MULT := 0.5

## The two types docs/07 OQ-9 disables in a tutorial: both are Critical, both
## drag a second fight into the first one, and a player who has not yet read a
## mistake in the log should not meet the two that end the encounter.
const TUTORIAL_DISABLED_TYPES := ["MIS_FACEPULL", "MIS_NINJAPULL"]

# ---------------------------------------------------------------- taxonomy

## docs/07 §5.2, all eighteen types.
##
## `affinity` scales a type's SELECTION WEIGHT, not the raider's mistake chance.
## A Rogue is not clumsier than a Mage; a Rogue's clumsiness is more likely to
## express itself as a facepull.
##
## `cascade_only` types can never open a chain — they need a live token.
##
## `requires: "zone_exists"` on MIS_FIRE (SIM-14): "Stood in the Fire" is a
## sentence about the encounter, and docs/07 §5.2 row 1 assumes a fire exists.
## Without the gate a tank-swap check on E3 — which carries no ground effect —
## drew the type, the roll site stripped the token, and the log read "Bob
## MISTAKE · Stood in the Fire" in a fight with no fire, followed by nothing. The
## name is gated here in the taxonomy and the Fire TOKEN is gated for every type
## by `emits_for`, so no site has to remember either rule.
const TYPES := {
    "MIS_FIRE": {
        "name": "Stood in the Fire", "site": Enums.RollSite.MECHANIC,
        "severity": Enums.Severity.MODERATE, "weight": 8,
        "affinity": {}, "melee_affinity": 1.5,
        "emits": [Enums.Token.FIRE], "cascade_only": false, "requires": "zone_exists",
    },
    "MIS_AGGRO": {
        "name": "Pulled Aggro Off the Tank", "site": Enums.RollSite.ACTION,
        "severity": Enums.Severity.SEVERE, "weight": 10,
        "affinity": {Enums.CharClass.WIZARD: 2.0, Enums.CharClass.ROGUE: 1.5},
        "roles": [Enums.RoleGroup.DPS],
        "emits": [Enums.Token.AGGRO], "cascade_only": false,
    },
    "MIS_TAUNT_LAPSE": {
        "name": "Forgot to Taunt", "site": Enums.RollSite.ACTION,
        "severity": Enums.Severity.MODERATE, "weight": 10,
        "affinity": {Enums.CharClass.WARRIOR: 1.0, Enums.CharClass.MONK: 1.0},
        "classes": [Enums.CharClass.WARRIOR, Enums.CharClass.MONK],
        "emits": [Enums.Token.AGGRO], "cascade_only": false,
    },
    "MIS_INTERRUPT_MISS": {
        "name": "Missed the Interrupt", "site": Enums.RollSite.MECHANIC,
        "severity": Enums.Severity.SEVERE, "weight": 10,
        "classes": [Enums.CharClass.ROGUE, Enums.CharClass.MONK, Enums.CharClass.WARRIOR],
        "emits": [], "cascade_only": false, "requires": "interrupt_check",
    },
    "MIS_INTERRUPT_WRONG": {
        "name": "Interrupted the Wrong Cast", "site": Enums.RollSite.MECHANIC,
        "severity": Enums.Severity.SEVERE, "weight": 6,
        "classes": [Enums.CharClass.ROGUE, Enums.CharClass.MONK, Enums.CharClass.WARRIOR],
        "emits": [], "cascade_only": false, "requires": "interrupt_check",
    },
    "MIS_HEAL_WRONG": {
        "name": "Healed the Wrong Target", "site": Enums.RollSite.ACTION,
        "severity": Enums.Severity.MODERATE, "weight": 10,
        "roles": [Enums.RoleGroup.HEALER],
        "emits": [Enums.Token.MANA], "cascade_only": false,
    },
    "MIS_HEAL_CORPSE": {
        "name": "Healed a Corpse", "site": Enums.RollSite.ACTION,
        "severity": Enums.Severity.MODERATE, "weight": 6,
        "classes": [Enums.CharClass.CLERIC, Enums.CharClass.SHAMAN],
        "emits": [Enums.Token.MANA], "cascade_only": false, "requires": "corpse_present",
    },
    "MIS_CHAIN_FIZZLE": {
        "name": "Bounced the Chain Heal Into Nobody", "site": Enums.RollSite.ACTION,
        "severity": Enums.Severity.MINOR, "weight": 8,
        "classes": [Enums.CharClass.SHAMAN],
        "emits": [Enums.Token.MANA], "cascade_only": false,
    },
    "MIS_AFK": {
        "name": "Went AFK", "site": Enums.RollSite.AMBIENT,
        "severity": Enums.Severity.MODERATE, "weight": 8,
        "affinity": {}, "low_morale_mult": 2.0, "low_morale_band": 1,
        "emits": [], "cascade_only": false,
        # docs/07 §5.2 row 9: "Moderate (Severe if tank or healer)" and "Aggro
        # if tank". The floor is applied in `roll()` after the band; the token
        # in `emits_for`, read off the context's `is_tank`.
        "severity_floor_if_tank_or_healer": Enums.Severity.SEVERE,
        "emits_if_tank": [Enums.Token.AGGRO],
    },
    "MIS_MECHANIC_DROP": {
        "name": "Dropped a Mechanic", "site": Enums.RollSite.MECHANIC,
        "severity": Enums.Severity.SEVERE, "weight": 9,
        "emits": [Enums.Token.FIRE, Enums.Token.DISTRACTION], "cascade_only": false,
    },
    "MIS_WRONG_TARGET": {
        "name": "Attacked the Wrong Target", "site": Enums.RollSite.ACTION,
        "severity": Enums.Severity.MODERATE, "weight": 10,
        "roles": [Enums.RoleGroup.DPS],
        "emits": [Enums.Token.ADDS], "cascade_only": false,
    },
    "MIS_BROKE_CC": {
        "name": "AoE'd the Sleeping Add", "site": Enums.RollSite.ACTION,
        "severity": Enums.Severity.SEVERE, "weight": 9,
        "classes": [Enums.CharClass.MAGE],
        "emits": [Enums.Token.ADDS], "cascade_only": false, "requires": "adds_present",
    },
    "MIS_FACEPULL": {
        "name": "Facepulled the Next Group", "site": Enums.RollSite.ACTION,
        "severity": Enums.Severity.CRITICAL, "weight": 7,
        "affinity": {Enums.CharClass.ROGUE: 2.0},
        "classes": [Enums.CharClass.ROGUE, Enums.CharClass.MONK],
        "emits": [Enums.Token.ADDS], "cascade_only": false, "requires": "trash_phase",
    },
    "MIS_NINJAPULL": {
        "name": "Ninja-Pulled During the Break", "site": Enums.RollSite.AMBIENT,
        "severity": Enums.Severity.CRITICAL, "weight": 5,
        "low_morale_mult": 2.0, "low_morale_band": 3,
        "emits": [Enums.Token.DISTRACTION], "cascade_only": false, "requires": "break_phase",
    },
    "MIS_NO_CONSUMABLE": {
        "name": "Forgot Their Consumable", "site": Enums.RollSite.AMBIENT,
        "severity": Enums.Severity.MINOR, "weight": 6,
        "emits": [], "cascade_only": false,
        # Both flags (W7-SIM-EFFECTS): the one-shot before round 1, AND a
        # provision on this raider to forget. "Forgot Their Consumable" on a
        # raider carrying nothing was the same lie SIM-14 took out of MIS_FIRE.
        "requires": ["encounter_start", "consumable_carried"],
    },
    "MIS_ARGUMENT": {
        "name": "Started an Argument in Raid Chat", "site": Enums.RollSite.AMBIENT,
        "severity": Enums.Severity.MODERATE, "weight": 7,
        "low_morale_mult": 2.0, "low_morale_band": 2,
        "emits": [Enums.Token.DISTRACTION], "cascade_only": false,
    },
    "MIS_LOOT_CALL": {
        "name": "Called Loot Before the Boss Died", "site": Enums.RollSite.AMBIENT,
        "severity": Enums.Severity.MINOR, "weight": 6,
        "emits": [Enums.Token.DISTRACTION], "cascade_only": false, "requires": "boss_low",
    },
    "MIS_AVOIDABLE_DEATH": {
        "name": "Died to Something Extremely Avoidable", "site": Enums.RollSite.MECHANIC,
        "severity": Enums.Severity.CRITICAL, "weight": 10,
        "emits": [Enums.Token.DISTRACTION], "cascade_only": true,
        "requires_token": [Enums.Token.FIRE, Enums.Token.ADDS],
    },
}


## One rolled mistake. Field set is docs/07 §5.1.
class MistakeEvent extends RefCounted:
    var type_id: String = ""
    var type_name: String = ""
    var severity: int = Enums.Severity.MINOR
    var roll_site: int = Enums.RollSite.ACTION
    var round_no: int = 0
    var phase: int = 0
    var actor_id: String = ""
    var tokens_emitted: Array = []
    var caused_by: String = ""      # the MistakeEvent id that enabled this one
    var cascade_depth: int = 0
    var margin: float = 0.0
    var rng_draw_index: int = 0

    ## docs/07 §10.1's tier-3 provenance (SIM-29): why THIS roll failed. The
    ## gate chance and the draw against it, in basis points; the selection
    ## weights the type was drawn from; docs/07 §5.4's raw severity score S
    ## before banding; and the RNG channel the gate stream was derived on, as
    ## the exact `derive(name, round, stream)` triple so a bug report can replay
    ## the one draw. -1 means "not rolled" — `force()` skips the gate and the
    ## score. `EventLog.emit_mistake` carries them under `debug`.
    var p_bp: int = -1
    var r_bp: int = -1
    var weights: Dictionary = {}
    var severity_s: int = -1
    var channel: String = ""

    ## docs/07 §5.1's field: WHICH line variant was drawn for this failure. The
    ## choice belongs on the event so the goldens pin it; the corpus that fills
    ## it is data/mistake_lines.json, which is not written yet, so both of these
    ## stay empty and every render site treats "" as "no line".
    var log_template_id: String = ""
    ## The rendered line. docs/07 §10.1 says the entry references its template
    ## rather than inlining prose; this is the one exception, and it exists so
    ## that the four render sites (describe, RaidView, Results, the goldens) read
    ## one string instead of each carrying a copy of the renderer.
    var log_line: String = ""

    func id() -> String:
        return "%s:r%d:%s" % [actor_id, round_no, type_id]

    func severity_name() -> String:
        return Enums.severity_name_of(severity)

    func severity_key() -> String:
        return Enums.severity_key(severity)

    func to_dict() -> Dictionary:
        return {
            "type": type_id, "name": type_name,
            "severity": Enums.severity_key(severity),
            "roll_site": Enums.roll_site_key(roll_site),
            "round": round_no, "actor_id": actor_id,
            "caused_by": caused_by, "cascade_depth": cascade_depth,
            "log_template_id": log_template_id,
        }

    ## The `debug` block the log entry carries (docs/07 §10.1: "seed, channel,
    ## draw index, formula inputs — tier 3 only"). Always written — the sim
    ## emits everything and verbosity is a display filter (EventLog's rule 2).
    func debug_dict() -> Dictionary:
        return {
            "p_bp": p_bp, "r_bp": r_bp, "margin": margin,
            "channel": channel, "draw": rng_draw_index,
            "weights": weights.duplicate(), "severity_s": severity_s,
        }


## Everything a roll needs to know about the world right now.
class Context extends RefCounted:
    var roll_site: int = Enums.RollSite.ACTION
    var round_no: int = 1
    var phase: int = 0
    var trash_phase: bool = false
    var break_phase: bool = false
    var encounter_start: bool = false
    var adds_present: bool = false
    var corpse_present: bool = false
    var interrupt_check: bool = false
    var boss_low: bool = false        # last 25% of boss HP
    ## The encounter carries docs/10 §10 M03, so there is a fire to stand in.
    ## Gates MIS_FIRE's name and every type's Fire token (SIM-14). Set by
    ## RaidSim from the encounter card; false by default, so a context built
    ## without an encounter cannot put anybody in a fire.
    var zone_exists: bool = false
    ## docs/07 OQ-9's ruling: the fight is one of docs/10 §9's two onboarding rungs, so
    ## the gate runs at TUTORIAL_MISTAKE_MULT and TUTORIAL_DISABLED_TYPES are
    ## never eligible. Set by RaidSim from the encounter's slot; false for every
    ## real rung, which keeps every golden byte-identical.
    var tutorial: bool = false
    ## This raider carries a provision to forget — a kit, a draught or a Steady
    ## Hands potion folded into their profile (docs/07 §5.2 row 15). Gates
    ## MIS_NO_CONSUMABLE the way `zone_exists` gates MIS_FIRE (W7-SIM-EFFECTS).
    var consumable_carried: bool = false
    ## This raider is seated as a tank (main or off), whatever their class —
    ## docs/07 §5.2 row 9's "Severe if tank", "Aggro if tank" read this, not
    ## the role group, because a Monk main-tanks a Warrior-less party.
    var is_tank: bool = false
    ## docs/04 §11.2's Legendary quirk seam (Q58-4): the quirk id this raider
    ## carries ("" for everybody who is not an authored Legendary) and whether
    ## the campaign flag is on. `Quirks.immune_to` reads both; with `SPECS`
    ## empty it is identity and no golden moves.
    var quirk_id: String = ""
    var quirks_enabled: bool = false
    ## Live consequence tokens on this actor (Enums.Token values).
    var live_tokens: Array = []
    ## type_id -> last round it fired, for the per-type cooldown.
    var cooldowns: Dictionary = {}
    ## Criticals already logged raid-wide this round.
    var criticals_this_round: int = 0

    func flag(name: String) -> bool:
        match name:
            "trash_phase": return trash_phase
            "break_phase": return break_phase
            "encounter_start": return encounter_start
            "adds_present": return adds_present
            "corpse_present": return corpse_present
            "interrupt_check": return interrupt_check
            "boss_low": return boss_low
            "zone_exists": return zone_exists
            "consumable_carried": return consumable_carried
        return false

    ## Every flag in a type's `requires` — one name, or a list of names that
    ## must ALL hold (MIS_NO_CONSUMABLE needs the one-shot AND a provision).
    func requires_met(requires) -> bool:
        if typeof(requires) == TYPE_ARRAY:
            for name in requires:
                if not flag(String(name)):
                    return false
            return true
        return flag(String(requires))


# ---------------------------------------------------------------- eligibility

## Types that could fire right now for this raider, in deterministic order.
static func eligible_types(char_class: int, role_group: int, ctx: Context) -> Array:
    var out: Array[String] = []
    for type_id in TYPES.keys():
        var t: Dictionary = TYPES[type_id]
        if int(t["site"]) != ctx.roll_site:
            continue
        # docs/07 OQ-9 (ruled in docs/15): the two pulls are off in a tutorial.
        if ctx.tutorial and type_id in TUTORIAL_DISABLED_TYPES:
            continue
        # Class / role gating
        if t.has("classes") and not (char_class in t["classes"]):
            continue
        if t.has("roles") and not (role_group in t["roles"]):
            continue
        # Context requirement — one flag, or every flag in a list.
        if t.has("requires") and not ctx.requires_met(t["requires"]):
            continue
        # docs/07 §5.3(c): the encounter-start roll IS MIS_NO_CONSUMABLE's
        # "special one-shot"; nothing else is rolled before round 1. Going AFK
        # or starting an argument at round 0 used to be reachable there, and
        # with consequences attached (W7-SIM-EFFECTS) an absence that begins
        # before the pull would be a mistake the round structure never named.
        #
        # This gates the ENCOUNTER-START roll only. BL-116's break roll is a
        # different one-shot — `break_phase`, rolled by `game/` at Depart — and
        # it must NOT set `encounter_start`, or MIS_NINJAPULL would be filtered
        # out here by the flag it does not carry.
        if ctx.encounter_start and not _requires_flag(t, "encounter_start"):
            continue
        # docs/04 §11.2's quirk seam (Q58-4): an authored Legendary's gift can
        # take one type off their table. Identity while `Quirks.SPECS` is empty.
        if not ctx.quirk_id.is_empty() \
                and Quirks.immune_to(ctx.quirk_id, type_id, ctx.quirks_enabled):
            continue
        # Cascade-only types need a live token of a listed kind
        if bool(t["cascade_only"]):
            var ok := false
            for tok in t.get("requires_token", []):
                if tok in ctx.live_tokens:
                    ok = true
            if not ok:
                continue
        # Per-type cooldown
        if ctx.cooldowns.has(type_id):
            if ctx.round_no - int(ctx.cooldowns[type_id]) <= PER_TYPE_COOLDOWN_ROUNDS - 1:
                continue
        out.append(type_id)
    out.sort()   # deterministic: golden files compare this
    return out


## Does a type's `requires` (one name or a list) name this flag?
static func _requires_flag(t: Dictionary, name: String) -> bool:
    var req = t.get("requires", null)
    if req == null:
        return false
    if typeof(req) == TYPE_ARRAY:
        return req.has(name)
    return String(req) == name


## Selection weight of one type for one raider.
static func weight_for(type_id: String, char_class: int, morale_band: int) -> int:
    var t: Dictionary = TYPES[type_id]
    var w := float(t["weight"])
    var affinity: Dictionary = t.get("affinity", {})
    if affinity.has(char_class):
        w *= float(affinity[char_class])
    # Melee affinity applies to the canon melee classes.
    if t.has("melee_affinity"):
        if char_class in [Enums.CharClass.WARRIOR, Enums.CharClass.MONK,
                          Enums.CharClass.ROGUE, Enums.CharClass.BARD]:
            w *= float(t["melee_affinity"])
    # Some types are far likelier when a raider is miserable.
    if t.has("low_morale_mult") and morale_band <= int(t["low_morale_band"]):
        w *= float(t["low_morale_mult"])
    return maxi(1, int(round(w)))


# ---------------------------------------------------------------- severity

## docs/07 §5.4. `S = clamp(round(margin*100) + d20 - 10, 1, 100)`, banded, then
## clamped to the type's base band +/- 1 so a forgotten consumable can never be
## Critical and a facepull can never be Minor.
##
## Split in two so the raw score can travel to the log's tier-3 line (SIM-29)
## without a second d20: `severity_score` draws once, `severity_band_for` is
## pure. This wrapper is the original signature and draw order, unchanged.
static func severity_for(type_id: String, margin: float, rng) -> int:
    return severity_band_for(type_id, severity_score(margin, rng))


## docs/07 §5.4's S, 1..100. One d20 from `rng`; 10 when there is no rng.
static func severity_score(margin: float, rng) -> int:
    var d20: int = rng.randi_range(1, 20) if rng != null else 10
    return clampi(int(round(margin * 100.0)) + d20 - 10, 1, 100)


## S banded, then clamped to the type's base band +/- 1.
static func severity_band_for(type_id: String, s: int) -> int:
    var band := Enums.Severity.MINOR
    if s >= 94:
        band = Enums.Severity.CRITICAL
    elif s >= 76:
        band = Enums.Severity.SEVERE
    elif s >= 46:
        band = Enums.Severity.MODERATE
    var base: int = int(TYPES[type_id]["severity"])
    return clampi(band, maxi(0, base - 1), mini(Enums.Severity.CRITICAL, base + 1))


## The tokens a type emits IN THIS CONTEXT. docs/07 §6's Fire token is the
## consequence of one mechanic, M03, and the only token in the table that names
## a thing the encounter has to carry; on a fight with no zone it used to be
## stripped at one roll site and could still arrive from another. A rule in
## the taxonomy instead of in the site (SIM-14): no zone, no Fire, whichever
## type and whichever site.
static func emits_for(type_id: String, ctx: Context) -> Array:
    var out: Array = []
    var t: Dictionary = TYPES[type_id]
    for tok in t.get("emits", []):
        if int(tok) == Enums.Token.FIRE and not ctx.zone_exists:
            continue
        out.append(tok)
    # docs/07 §5.2 row 9's "Aggro if tank": the seated tank going AFK is the
    # boss looking for somebody else, whatever class is holding the seat.
    if ctx.is_tank:
        for tok in t.get("emits_if_tank", []):
            if not out.has(tok):
                out.append(tok)
    return out


## docs/07 §5.2 row 9's "Moderate (Severe if tank or healer)": the band the
## roll produced, floored for the two roles whose absence costs the raid more
## than their own output. Read off the taxonomy row, so a second type can
## carry the same rule without a second branch.
static func severity_floored_for_role(type_id: String, severity: int,
        role_group: int, ctx: Context) -> int:
    var t: Dictionary = TYPES[type_id]
    if not t.has("severity_floor_if_tank_or_healer"):
        return severity
    if ctx.is_tank or role_group == Enums.RoleGroup.HEALER:
        return maxi(severity, int(t["severity_floor_if_tank_or_healer"]))
    return severity


# ---------------------------------------------------------------- the roll

## The gate chance one roll is made against, in basis points. `Formulas` owns
## the equation (docs/08); this is the one place the CONTEXT bends it, and the
## tutorial multiplier is the only bend. Its own function so the halving can be
## asserted exactly rather than inferred from a hit rate.
static func chance_bp(rarity: int, morale: int, ctx: Context,
        situational_bp: int = 0, facility_mult: float = 1.0,
        relief_bp: float = 0.0) -> int:
    var p_bp := Formulas.mistake_chance_at_site_bp(
        rarity, morale, ctx.roll_site, situational_bp, facility_mult, relief_bp)
    if ctx.tutorial:
        p_bp = int(round(float(p_bp) * TUTORIAL_MISTAKE_MULT))
    return p_bp


## Roll one mistake check. Returns a MistakeEvent, or null if nothing went wrong.
##
## Draw order is fixed — gate, then type, then severity — because docs/14 §8
## requires a deterministic draw order or the seed is worthless.
## `relief_bp` is docs/11 §7's Potion of Steady Hands; see
## `Formulas.mistake_chance_bp` for why it is its own term and why the rarity floor
## still wins.
static func roll(rng, char_class: int, role_group: int, rarity: int, morale: int,
        ctx: Context, situational_bp: int = 0, facility_mult: float = 1.0,
        relief_bp: float = 0.0):
    var p_bp := chance_bp(rarity, morale, ctx, situational_bp, facility_mult, relief_bp)
    if p_bp <= 0:
        return null

    var draw_index: int = rng.draws
    var r_bp: int = rng.next_below(10000)
    if r_bp >= p_bp:
        return null                      # no mistake

    var eligible := eligible_types(char_class, role_group, ctx)
    if eligible.is_empty():
        return null                      # failed the gate, but nothing can express it

    var band := Enums.morale_band(morale)
    var weights: Array = []
    for type_id in eligible:
        weights.append(weight_for(type_id, char_class, band))
    var pick: int = rng.pick_weighted(weights)
    if pick < 0:
        return null
    var chosen: String = eligible[pick]

    var ev := MistakeEvent.new()
    ev.type_id = chosen
    ev.type_name = String(TYPES[chosen]["name"])
    ev.roll_site = ctx.roll_site
    ev.round_no = ctx.round_no
    ev.phase = ctx.phase
    ev.margin = float(p_bp - r_bp) / float(p_bp)
    ev.rng_draw_index = draw_index
    ev.p_bp = p_bp
    ev.r_bp = r_bp
    # The selection weights, keyed on the type, in the eligible set's own
    # (sorted) order so the log serialises deterministically.
    for i in eligible.size():
        ev.weights[eligible[i]] = int(weights[i])
    ev.severity_s = severity_score(ev.margin, rng)
    ev.severity = severity_band_for(chosen, ev.severity_s)
    # docs/07 §5.2 row 9: a tank or healer going AFK is Severe at least.
    ev.severity = severity_floored_for_role(chosen, ev.severity, role_group, ctx)

    # Raid-wide Critical cap: a wipe reads as a chain of small failures, not a
    # simultaneous explosion. Demote rather than discard — the mistake happened.
    if ev.severity == Enums.Severity.CRITICAL and ctx.criticals_this_round >= MAX_CRITICALS_PER_ROUND:
        ev.severity = Enums.Severity.SEVERE

    # Depth cap: a mistake at max depth emits nothing, so chains terminate.
    if ev.cascade_depth < MAX_CASCADE_DEPTH:
        ev.tokens_emitted = emits_for(chosen, ctx)
    return ev


## docs/10 §9.1's scripted mistake: "Adventure 0 scripts one guaranteed mistake
## on round 3 regardless of morale rolls." The gate is skipped — that is what
## "regardless" means, and it is also why TUTORIAL_MISTAKE_MULT cannot suppress
## it — and everything after the gate is the ordinary path: the same eligible
## set, the same class-weighted draw, the same event shape, so the line the
## player reads is byte-identical in form to the ones the rest of the game will
## hand them. Returns null only when nothing at all is eligible.
##
## Severity is the Minor end of the type's band. A tutorial demonstrates a fail
## state, it does not impose one (docs/10 §9.1), so the lesson is embarrassing
## and never lethal: the draw prefers types whose band reaches Minor, and falls
## back to the whole eligible set at each type's own floor when none does.
## The choices are docs/15 BL-92.
static func force(rng, char_class: int, role_group: int, morale: int, ctx: Context):
    var eligible := eligible_types(char_class, role_group, ctx)
    if eligible.is_empty():
        return null
    var gentle: Array = []
    for type_id in eligible:
        if int(TYPES[type_id]["severity"]) <= Enums.Severity.MODERATE:
            gentle.append(type_id)
    var pool: Array = gentle if not gentle.is_empty() else eligible
    var band := Enums.morale_band(morale)
    var weights: Array = []
    for type_id in pool:
        weights.append(weight_for(type_id, char_class, band))
    var draw_index: int = rng.draws
    var pick: int = rng.pick_weighted(weights)
    if pick < 0:
        return null
    var chosen: String = pool[pick]

    var ev := MistakeEvent.new()
    ev.type_id = chosen
    ev.type_name = String(TYPES[chosen]["name"])
    ev.roll_site = ctx.roll_site
    ev.round_no = ctx.round_no
    ev.phase = ctx.phase
    ev.margin = 0.0                  # a fumble, not a catastrophe
    ev.rng_draw_index = draw_index
    # No gate and no score were rolled: `p_bp`, `r_bp` and `severity_s` stay at
    # -1 ("not rolled") so the tier-3 line says so rather than inventing them.
    for i in pool.size():
        ev.weights[pool[i]] = int(weights[i])
    var base: int = int(TYPES[chosen]["severity"])
    ev.severity = clampi(Enums.Severity.MINOR, maxi(0, base - 1),
        mini(Enums.Severity.CRITICAL, base + 1))
    ev.tokens_emitted = emits_for(chosen, ctx)
    return ev


## Mark a fired type so the per-type cooldown blocks it next round.
static func note_fired(ctx: Context, ev) -> void:
    if ev == null:
        return
    ctx.cooldowns[ev.type_id] = ev.round_no
    if ev.severity == Enums.Severity.CRITICAL:
        ctx.criticals_this_round += 1


## Attribute a mistake to the token that enabled it (docs/07 §6 rule 1).
##
## THE ONLY WRITER of `caused_by` and `cascade_depth`. RaidSim calls it at every
## roll site after a non-null event and before the event is recorded, logged or
## applied, with the parent `RaidSim._parent_for` chose (SIM-05); the depth cap
## binds here — an event at MAX_CASCADE_DEPTH emits nothing — and `_apply_mistake`
## reads `tokens_emitted` AFTER this, which is why the order matters.
static func attribute(ev, parent) -> void:
    if ev == null or parent == null:
        return
    ev.caused_by = parent.id()
    ev.cascade_depth = mini(MAX_CASCADE_DEPTH, parent.cascade_depth + 1)
    if ev.cascade_depth >= MAX_CASCADE_DEPTH:
        ev.tokens_emitted = []


static func type_count() -> int:
    return TYPES.size()
