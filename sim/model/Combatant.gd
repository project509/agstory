class_name TwgCombatant
extends RefCounted
## One raider's state inside a single encounter.
##
## This is the mutable half that `Raider` deliberately does not carry: current
## HP, threat, alive/downed/dead, and live consequence tokens. Keeping it here is
## what lets the roster record stay serialisable mid-raid (docs/04 §4).
##
## Implements docs/07 §7.1 (Downed → Dead) and §6 (consequence tokens).
##
## The Downed state is the important rule. docs/07 §4.2 resolves a round
## sequentially with boss damage in Phase 1 and healing in Phase 4, so without a
## grace state a healer structurally could not save anyone from a big hit. Downed
## hands them exactly one round, which is what makes a clutch heal a real event.

const Enums = preload("res://sim/model/Enums.gd")
const Stats = preload("res://sim/model/Stats.gd")

static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/model/Combatant.gd")
    return _self_script

## Damage at or beyond `current_hp + OVERKILL_MARGIN` kills outright, skipping
## Downed: a big enough hit should not be survivable by luck (docs/07 §7.1).
## docs/08 owns the final value; this is the named knob it will set.
const OVERKILL_MARGIN := 15

var raider = null                 # TwgRaider — the persistent record
var slot_index: int = 0           # roster position; deterministic tie-breaker
var max_hp: int = 1
var current_hp: int = 1
var state: int = Enums.CombatState.ALIVE
var threat: int = 0

## Token -> expires_after_round (-1 = until explicitly cleared).
var tokens: Dictionary = {}

## Token -> the MistakeEvent that emitted it. docs/07 §6 rule 1 — "a mistake
## caused by a live token records `caused_by = <that token's source event>`" —
## needs the event itself, not just the fact of the token, and the graph it
## builds is what the post-mortem reads instead of listing twelve unrelated
## failures.
##
## Two things depend on the SOURCE rather than the token: the cascade edge, and
## the Fire exit. §6's duration column says Fire lasts "until the raider leaves"
## and §5.2 row 1 says when that is — "end of next round" — which is a fact
## about the round it was emitted in, and `tokens` stores -1 for a token with no
## expiry, so it cannot answer.
##
## Deliberately NOT serialised by `to_dict`: a resumed encounter (docs/14 OQ-11)
## keeps its tokens and its finished graph — `caused_by` is written into the log
## entry as it happens — and loses only the ability to attribute a NEW mistake
## to a parent from before the save.
var token_sources: Dictionary = {}

## Set by the encounter when it assigns tank duty; the Monk can be pressed into
## offtanking, which is a sim behaviour rather than a comp-slot claim.
var is_main_tank: bool = false
var is_offtank: bool = false

## docs/10 §10 M01: "Debuff on current tank: +50%/stack damage taken, 1 stack per
## hit, swap required at 3."
##
## Per-combatant and never a global, because the mechanic IS two people taking
## turns: a single raid-wide counter cannot express "Bob steps out at three
## stacks while Kel starts again at zero", which is the entire teaching payload
## of the Tutorial Raid (docs/10 §9.1) and the comedy of docs/10 §7.3.
var tank_debuff_stacks: int = 0

## Whose turn it is at the boss. `is_main_tank` says who the raid brought;
## this says who is holding it right now, and M01's swap moves it.
var is_active_tank: bool = false

## docs/10 §10 M07, in docs/07 OQ-7's abstract-flags-only reading (proposed in
## build/plan/q-mech-arms.md): a raider is Spread or Stacked and the simulation
## knows nothing else about space. Set from the class in
## `RaidSim._build_combatants`, so an encounter with no M07 has a stance nothing
## reads and every golden stays byte-identical.
var stance: int = Enums.Stance.STACKED

## docs/10 §10 M09: "Healing on the current tank reduced `p%` for `N` rounds."
## A percentage plus the round it stops mattering, rather than a token, because
## the reduction is a magnitude and `tokens` stores only expiry.
var healing_reduction_pct: int = 0
var healing_reduction_until: int = 0

## docs/10 §10 M10's silence half: "For `N` rounds, casters ... cannot act."
## The drain half needs the Focus pool docs/15 Q-02 chose and nobody built —
## see `RaidSim.MANA_BURN_DRAIN_ENABLED` and build/plan/q-mech-arms.md.
var silenced_until: int = 0

## docs/07 §5.2 row 9, MIS_AFK: "No action for 1-3 rounds (severity picks
## duration)." The last round they are away; `can_act` reads it the way it
## reads the silence. Set by `RaidSim._apply_mistake` (W7-SIM-EFFECTS).
var afk_until: int = 0

## docs/07 §5.2 row 17, MIS_LOOT_CALL: "Skips next action." One flag, consumed
## by the first action phase that finds it (`consume_skipped_action`), so the
## skip is exactly one action and never a silent second one.
var skip_next_action: bool = false

## How many times this raider called loot early this encounter, for the
## queued delta (`loot_call`) `game/` turns into docs/07 §5.2 row 17's
## post-encounter morale event. Counted here, applied nowhere in sim/.
var loot_calls: int = 0

## docs/07 §5.2 row 16, MIS_ARGUMENT: "Both this raider and one random other
## take a mistake-chance penalty for the rest of the encounter." Basis points,
## read by `RaidSim._situational_bp`; SET rather than stacked (docs/15's row).
var argument_penalty_bp: int = 0

## docs/15 Q-57's Lost Aggro: the round in which the boss's FIRST swing does
## not read this tank's threat. Set by the active tank's MIS_TAUNT_LAPSE for
## the following round; swing 2 resolves on the tank as ruled. 0 = never.
var lost_aggro_round: int = 0


static func create(raider_record, db, slot: int = 0):
    var c = _cls().new()
    c.raider = raider_record
    c.slot_index = slot
    c.max_hp = maxi(1, raider_record.max_hp(db))
    c.current_hp = c.max_hp
    c.state = Enums.CombatState.ALIVE
    return c


# ---------------------------------------------------------------- state

func is_alive() -> bool:
    return state == Enums.CombatState.ALIVE


func is_downed() -> bool:
    return state == Enums.CombatState.DOWNED


func is_dead() -> bool:
    return state == Enums.CombatState.DEAD


## Downed raiders hold threat but are not valid boss targets (docs/07 §7.1).
func is_valid_boss_target() -> bool:
    return state == Enums.CombatState.ALIVE


## Downed raiders ARE valid heal targets — that is the whole point of the state.
## Healing a Dead one is a mistake (MIS_HEAL_CORPSE), not a legal action.
func is_valid_heal_target() -> bool:
    return state != Enums.CombatState.DEAD


## Can this raider take actions this round?
##
## `current_round` is optional so every existing caller keeps its exact meaning.
## docs/10 §10 M10's silence window is the only thing that needs it, and it needs
## the round because the window has an end and a Combatant owns no clock (house
## rule 6: nothing in sim/ may read the time).
func can_act(current_round: int = 0) -> bool:
    if state != Enums.CombatState.ALIVE:
        return false
    if current_round <= 0:
        return true
    return current_round > silenced_until and current_round > afk_until


## MIS_AFK's window, live THIS round. 0 once they are back.
func rounds_afk_remaining(current_round: int) -> int:
    return maxi(0, afk_until - current_round + 1)


## docs/07 §5.2 row 17's "skips next action": true exactly once after a loot
## call, and the flag is spent by the asking. The caller logs the skip.
func consume_skipped_action() -> bool:
    if not skip_next_action:
        return false
    skip_next_action = false
    return true


## docs/15 Q-57: does the boss's first swing this round ignore this tank?
func has_lost_aggro(current_round: int) -> bool:
    return lost_aggro_round == current_round


## docs/10 §10 M09's reduction, in percent, live on this raider THIS round.
## Returns 0 once the window has passed, so a stale stamp can never quietly
## halve a heal ten rounds after the debuff was supposed to fall off.
func effective_healing_reduction(current_round: int) -> int:
    if healing_reduction_pct <= 0 or current_round > healing_reduction_until:
        return 0
    return healing_reduction_pct


func hp_fraction() -> float:
    if max_hp <= 0:
        return 0.0
    return float(current_hp) / float(max_hp)


# ---------------------------------------------------------------- damage

## Apply damage. Returns the resulting state so the caller can log the
## transition. Already-dead combatants absorb nothing.
func take_damage(amount: int, overkill_margin: int = OVERKILL_MARGIN) -> int:
    if state == Enums.CombatState.DEAD or amount <= 0:
        return state
    # Overkill skips Downed entirely.
    if amount >= current_hp + overkill_margin:
        current_hp = 0
        state = Enums.CombatState.DEAD
        threat = 0
        return state
    if state == Enums.CombatState.DOWNED:
        # Downed raiders take no further damage (docs/07 §7.1).
        return state
    current_hp -= amount
    if current_hp <= 0:
        current_hp = 0
        state = Enums.CombatState.DOWNED
    return state


## Heal. A Downed raider comes back Alive at the healed amount — the clutch heal.
## Returns the HP actually restored (0 if the target could not be healed).
func heal(amount: int) -> int:
    if amount <= 0 or state == Enums.CombatState.DEAD:
        return 0
    var before := current_hp
    if state == Enums.CombatState.DOWNED:
        state = Enums.CombatState.ALIVE
        current_hp = mini(amount, max_hp)
        return current_hp - before
    current_hp = mini(current_hp + amount, max_hp)
    return current_hp - before


## Kill outright, bypassing Downed. Used by MIS_AVOIDABLE_DEATH and overkill.
func kill() -> void:
    current_hp = 0
    state = Enums.CombatState.DEAD
    threat = 0


## Phase 7 Round Close: anyone still Downed is confirmed Dead (docs/07 §4.1).
## Returns true if this call killed them, so the caller can log it.
func confirm_death_at_round_close() -> bool:
    if state != Enums.CombatState.DOWNED:
        return false
    state = Enums.CombatState.DEAD
    current_hp = 0
    threat = 0
    return true


# ---------------------------------------------------------------- threat

func add_threat(amount: int) -> void:
    if state == Enums.CombatState.DEAD:
        return
    threat = maxi(0, threat + amount)


func clear_threat() -> void:
    threat = 0


# ---------------------------------------------------------------- tokens

## Attach a consequence token. `current_round` is needed because most durations
## are relative; tokens with duration -1 persist until explicitly cleared.
##
## `source` is the MistakeEvent that emitted it, when one did. It is recorded
## even for a refresh, because docs/07 §6's chain follows the mistake that most
## recently put the token there — the worked cascade refreshes Aggro on Bob's
## `MIS_TAUNT_LAPSE` and then blames Cindy's heal on that, not on Greg's
## original pull two entries earlier.
func add_token(token: int, current_round: int, source = null) -> void:
    if source != null:
        token_sources[token] = source
    var duration: int = Enums.TOKEN_DURATION.get(token, 1)
    if duration < 0:
        tokens[token] = -1
        return
    var expires := current_round + duration - 1
    # Refreshing a token extends it; it never shortens an existing one.
    if tokens.has(token) and int(tokens[token]) == -1:
        return
    tokens[token] = maxi(int(tokens.get(token, -999)), expires)


## The MistakeEvent that emitted a live token, or null. Only meaningful while
## the token is live: `clear_token` and `expire_tokens` drop the source with it,
## so a chain can never be attributed to a token that is already gone.
func token_source(token: int):
    return token_sources.get(token, null)


func has_token(token: int) -> bool:
    return tokens.has(token)


func clear_token(token: int) -> void:
    tokens.erase(token)
    token_sources.erase(token)


## Drop tokens whose duration has elapsed. Called at Round Close.
func expire_tokens(current_round: int) -> Array:
    var expired := []
    for token in tokens.keys():
        var until: int = int(tokens[token])
        if until >= 0 and current_round > until:
            expired.append(token)
    for token in expired:
        tokens.erase(token)
        token_sources.erase(token)
    return expired


func live_tokens() -> Array:
    var out := tokens.keys()
    out.sort()   # deterministic ordering for logs and golden files
    return out


# ---------------------------------------------------------------- display

func display_name() -> String:
    return raider.display_name if raider != null else "?"


func _to_string() -> String:
    return "Combatant(%s %d/%d %s threat=%d)" % [
        display_name(), current_hp, max_hp,
        Enums.combat_state_key(state), threat,
    ]


# ---------------------------------------------------------------- persistence

## docs/14 OQ-11: an encounter must be resumable, so combat state serialises.
func to_dict() -> Dictionary:
    var tok := {}
    for t in tokens.keys():
        tok[Enums.token_key(int(t))] = tokens[t]
    return {
        "raider_id": raider.id if raider != null else "",
        "slot_index": slot_index,
        "max_hp": max_hp, "current_hp": current_hp,
        "state": Enums.combat_state_key(state),
        "threat": threat, "tokens": tok,
        "is_main_tank": is_main_tank, "is_offtank": is_offtank,
        # docs/10 §10's mechanic state. A resumed encounter that forgot these
        # would hand the boss a fresh tank at zero stacks, drop a live silence
        # and un-debuff a healing target — a save that makes the fight easier is
        # the save-scum hole docs/14 §8 exists to close.
        "is_active_tank": is_active_tank,
        "tank_debuff_stacks": tank_debuff_stacks,
        "stance": Enums.stance_key(stance),
        "healing_reduction_pct": healing_reduction_pct,
        "healing_reduction_until": healing_reduction_until,
        "silenced_until": silenced_until,
        # docs/07 §5.2's mistake consequences (W7-SIM-EFFECTS). A resumed
        # encounter that forgot these would bring an AFK raider back early,
        # hand a loot-caller their action, and drop an argument's penalty.
        "afk_until": afk_until,
        "skip_next_action": skip_next_action,
        "loot_calls": loot_calls,
        "argument_penalty_bp": argument_penalty_bp,
        "lost_aggro_round": lost_aggro_round,
    }


static func from_dict(d: Dictionary, raider_record):
    var c = _cls().new()
    c.raider = raider_record
    c.slot_index = int(d.get("slot_index", 0))
    c.max_hp = maxi(1, int(d.get("max_hp", 1)))
    c.current_hp = clampi(int(d.get("current_hp", 1)), 0, c.max_hp)
    c.state = maxi(0, Enums.COMBAT_STATE_KEYS.find(String(d.get("state", "alive"))))
    c.threat = int(d.get("threat", 0))
    c.is_main_tank = bool(d.get("is_main_tank", false))
    c.is_offtank = bool(d.get("is_offtank", false))
    c.is_active_tank = bool(d.get("is_active_tank", false))
    c.tank_debuff_stacks = maxi(0, int(d.get("tank_debuff_stacks", 0)))
    # A row written before these fields existed reads back as the default
    # rather than as -1: `stance_from_key` returns -1 for an absent key, and a
    # stance of -1 would match no demand and take M07 damage forever.
    #
    # An UNRECOGNISED key needs the same answer, and `maxi(0, ...)` did not give
    # it: -1 clamped to 0, which is `Stance.SPREAD` — the opposite of the
    # default this very line declares. A save hand-edited to "foo" came back
    # Spread while a save missing the key came back Stacked.
    var stance_read := Enums.stance_from_key(String(d.get("stance", "stacked")))
    c.stance = stance_read if stance_read >= 0 else Enums.Stance.STACKED
    c.healing_reduction_pct = maxi(0, int(d.get("healing_reduction_pct", 0)))
    c.healing_reduction_until = maxi(0, int(d.get("healing_reduction_until", 0)))
    c.silenced_until = maxi(0, int(d.get("silenced_until", 0)))
    c.afk_until = maxi(0, int(d.get("afk_until", 0)))
    c.skip_next_action = bool(d.get("skip_next_action", false))
    c.loot_calls = maxi(0, int(d.get("loot_calls", 0)))
    c.argument_penalty_bp = maxi(0, int(d.get("argument_penalty_bp", 0)))
    c.lost_aggro_round = maxi(0, int(d.get("lost_aggro_round", 0)))
    for key in d.get("tokens", {}).keys():
        var t := Enums.token_from_key(String(key))
        if t >= 0:
            c.tokens[t] = int(d["tokens"][key])
    return c
