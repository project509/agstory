extends RefCounted
## Morale: the baseline model and rarity resilience (docs/05 §8).
##
## ✅ CANON keeps this deliberately small: *"the morale system itself stays
## extremely simple: one number, one state, one effect. The complexity comes
## from the stories and decisions surrounding it."* (raw notes, Morale section).
##
## Canon also states the resilience rule directly: *"Lower tier raiders will be
## hardest to keep happy, while legendary raiders will not be bothered by many
## things easily."* docs/05 §8 turns that into the multiplier table below.
##
## WHAT THIS FILE OWNS: the baseline every raider drifts toward, how rarity
## scales incoming change, drift, and docs/05 §7's TRIGGER TABLE — every event
## that moves morale, with the cap or cooldown docs/05 §7.6 requires so morale
## cannot be farmed. What it does NOT own yet: docs/05 §6's leave and guild
## disband checks, which are the consequence side and land next.
##
## Pure and deterministic: no Node, no RNG, no engine state.

const Enums = preload("res://sim/model/Enums.gd")
const Ledger = preload("res://sim/core/MoraleLedger.gd")

## The value drift pulls toward before rarity and facilities are applied.
## A Rare sits exactly here, which is what makes Rare the reference row.
const BASE_BASELINE := 50

## docs/05 §8, indexed by Enums.Rarity. `rarity_offset` shifts the baseline;
## the multipliers scale morale changes coming IN, so a Common takes a wipe
## nearly 3.4x harder than a Legendary does.
const RARITY_OFFSET := [-5, -2, 0, 4, 12]

## docs/05 §7.6's ceiling, stated there as an arithmetic result rather than a rule:
## "baseline caps at 50 + 12 + 10 + 8 = 80". That held while the sum had exactly
## three terms. docs/02 §4.2 adds a fourth — comfort items — and says so explicitly:
## the baseline is "clamped to **≤ 80** — doc 05 §7.6's baseline ceiling". So what
## was emergent becomes an actual clamp, with the same value.
const BASELINE_CEILING := 80
const NEG_MULT := [1.35, 1.15, 1.00, 0.70, 0.40]
const POS_MULT := [0.85, 0.95, 1.00, 1.05, 1.10]
const DRIFT_RATE := [0.75, 0.90, 1.00, 1.20, 1.50]

## Base drift per Day Tick before the per-rarity rate multiplies it (docs/05 §8:
## a Rare returns to baseline at 1.5/tick, hence 1.5 at DRIFT_RATE 1.00).
const BASE_DRIFT := 1.5


static func _valid(rarity: int) -> bool:
    return rarity >= 0 and rarity < RARITY_OFFSET.size()


## docs/05 §7.5's Guildhall facility ladder. Canon says "better morale values",
## a standing improvement, so a facility upgrade shifts the BASELINE rather than
## granting a one-off spike.
const FACILITY_BONUS := [0, 3, 6, 10]

## docs/05 §7.5 exposes exactly two backstory hooks and no more: an offset on
## baseline in this range, and tags that scale a §7 delta. Backstory CONTENT is
## docs/03's, not this file's.
const BACKSTORY_OFFSET_MIN := -8
const BACKSTORY_OFFSET_MAX := 8


## docs/05 §7.5:
##     baseline = 50 + rarity_offset + facility_bonus + backstory_offset
##
## docs/05 §8's table (Common 45 ... Legendary 62) is this at tier-0 facilities
## with no backstory.
static func baseline_for(rarity: int, facility_bonus: int = 0,
        backstory_offset: int = 0, comfort_floor: int = 0) -> int:
    if not _valid(rarity):
        return BASE_BASELINE
    return clampi(BASE_BASELINE + RARITY_OFFSET[rarity] + facility_bonus
        + maxi(0, comfort_floor)
        + clampi(backstory_offset, BACKSTORY_OFFSET_MIN, BACKSTORY_OFFSET_MAX),
        Enums.MORALE_MIN, mini(Enums.MORALE_MAX, BASELINE_CEILING))


## The bonus for a Guildhall facility tier. docs/06 owns the tier count and its
## costs; this file only consumes the number.
static func facility_bonus_for(tier: int) -> int:
    return FACILITY_BONUS[clampi(tier, 0, FACILITY_BONUS.size() - 1)]


## Canon: a newly recruited raider starts at their baseline, not at 50, so
## rarity is legible the moment they appear on the recruit screen.
static func starting_morale(rarity: int, facility_bonus: int = 0) -> int:
    return baseline_for(rarity, facility_bonus)


## Scale an incoming morale change by rarity. Negatives hit low rarities harder
## and positives land softer — the asymmetry IS the "hardest to keep happy" rule.
static func scale_delta(rarity: int, delta: float) -> float:
    if not _valid(rarity):
        return delta
    if delta < 0.0:
        return delta * NEG_MULT[rarity]
    return delta * POS_MULT[rarity]


## Apply a raw (unscaled) morale change and return the new value, clamped.
## Morale is carried as a float so sub-1 drift accumulates (docs/05 §4).
static func apply_delta(morale: float, rarity: int, raw_delta: float) -> float:
    return clampf(morale + scale_delta(rarity, raw_delta),
        float(Enums.MORALE_MIN), float(Enums.MORALE_MAX))


## One Day Tick of drift toward the baseline. Never overshoots: a raider 0.4
## below baseline lands exactly on it rather than bouncing past.
static func drift(morale: float, rarity: int, facility_bonus: int = 0) -> float:
    var target := float(baseline_for(rarity, facility_bonus))
    if is_equal_approx(morale, target):
        return target
    var rate: float = DRIFT_RATE[rarity] if _valid(rarity) else 1.0
    var step: float = BASE_DRIFT * rate
    if morale < target:
        return minf(target, morale + step)
    return maxf(target, morale - step)


## How many Day Ticks to return to baseline from here. Display and tuning use;
## docs/05 §8's worked table quotes these numbers.
static func ticks_to_baseline(morale: float, rarity: int,
        facility_bonus: int = 0) -> int:
    var target := float(baseline_for(rarity, facility_bonus))
    var gap := absf(target - morale)
    if gap <= 0.0:
        return 0
    var rate: float = DRIFT_RATE[rarity] if _valid(rarity) else 1.0
    var step: float = BASE_DRIFT * rate
    return int(ceil(gap / step))


# ---------------------------------------------------------------- display

## docs/05 §2: the band index is the stable key. Display names are provisional
## (band 7 was renamed to break canon's duplicate "Very Happy"), so nothing
## should ever key off the string.
static func band(morale: int) -> int:
    return Enums.morale_band(morale)


static func band_name(morale: int) -> String:
    return Enums.morale_band_name(morale)


static func face(morale: int) -> String:
    return Enums.MORALE_BAND_EMOJI[Enums.morale_band(morale)]


## Bands 0-2 are the end canon warns about: "may cause guild disband" (0-10)
## and "may leave guild" (10-20, 20-30). docs/13 §9 requires a player to name
## every at-risk raider in under two seconds, so this is the flag it reads.
static func is_at_risk(morale: int) -> bool:
    return Enums.morale_band(morale) <= 2


# ================================================================ triggers

## docs/05 §7's trigger table, complete. Every delta here is PRE-RESILIENCE —
## docs/05 §8 scales it per rarity, which `apply()` does — and every row carries
## the cap or cooldown the doc gives it.
##
## docs/05 §7.6 states the stakes: without the caps "morale becomes farmable and
## every raider parks at 100". The audit at the end of that section is reproduced
## as tests rather than trusted.
##
## `subject` disambiguates a row that is capped per THING rather than per raider:
## the first-boss-kill bonus is "once per boss per raider", so its subject is the
## boss id. Rows with no subject use "".
const TRIGGERS := {
    # ---------------------------------------------------------- §7.1 raid outcomes
    "cleared": {
        "delta": 6.0, "cap": Ledger.Cap.ONCE_TICK,
        "doc": "Raid or Adventure cleared, raider participated",
    },
    "first_boss_kill": {
        "delta": 10.0, "cap": Ledger.Cap.ONCE_EVER,
        "doc": "Boss defeated for the first time ever, raider participated",
    },
    "wipe": {
        "delta": -8.0, "cap": Ledger.Cap.TOTAL_SESSION, "limit": 16.0,
        "doc": "Wipe, raider participated — max -16 per raid attempt session",
    },
    "loot_call": {
        "delta": -3.0, "cap": Ledger.Cap.ONCE_SESSION,
        "doc": "Called loot before the boss died (docs/07 §5.2 row 17) — docs/05 §7.3's passed-over figure, once per attempt",
    },
    "wipe_caused": {
        "delta": -4.0, "cap": Ledger.Cap.ONCE_SESSION,
        "doc": "Wipe directly caused by this raider's mistake, additional",
    },
    "knocked_out": {
        "delta": -3.0, "cap": Ledger.Cap.TOTAL_SESSION, "limit": 6.0,
        "doc": "Raider knocked out during a clear — max -6 per attempt",
    },
    "avenged": {
        "delta": 3.0, "cap": Ledger.Cap.ONCE_EVER,
        "doc": "Cleared an encounter that previously wiped the guild",
    },
    # ------------------------------------------------------- §7.2 roster decisions
    "brought": {
        "delta": 3.0, "cap": Ledger.Cap.ONCE_TICK,
        "doc": "Brought on a raid",
    },
    "benched": {
        "delta": -2.0, "cap": Ledger.Cap.TOTAL_WINDOW, "limit": 6.0, "window": 7,
        "doc": "Benched while healthy and the raid ran, from the 2nd consecutive tick",
    },
    "benched_wishlist": {
        "delta": -4.0, "cap": Ledger.Cap.TOTAL_WINDOW, "limit": 6.0, "window": 7,
        "doc": "Benched with a wishlist item on the loot table — replaces `benched`",
    },
    "peer_left": {
        "delta": -4.0, "cap": Ledger.Cap.ONCE_EVER,
        "doc": "Another roster raider leaves — once per departure",
    },
    "peer_left_same_class": {
        "delta": -6.0, "cap": Ledger.Cap.ONCE_EVER,
        "doc": "Another roster raider leaves, same class — replaces `peer_left`",
    },
    "peer_dismissed": {
        "delta": -2.0, "cap": Ledger.Cap.ONCE_EVER,
        "doc": "Player dismisses a raider voluntarily — cheaper than a departure",
    },
    "rank_up": {
        "delta": 5.0, "cap": Ledger.Cap.ONCE_EVER,
        "doc": "Guild Reputation rank up — once per rank",
    },
    # ------------------------------------------------------------------ §7.3 loot
    "loot_upgrade": {
        "delta": 5.0, "cap": Ledger.Cap.TOTAL_SESSION, "limit": 10.0,
        "doc": "Received an item that is a stat upgrade — max +10 per distribution",
    },
    "loot_wishlist": {
        "delta": 12.0, "cap": Ledger.Cap.COOLDOWN, "window": 3,
        "doc": "Received a wishlisted item — replaces the +5, one per 3 Day Ticks",
    },
    "loot_sidegrade": {
        "delta": 0.0, "cap": Ledger.Cap.NONE,
        "doc": "Received an item that is not an upgrade — no morale from clutter",
    },
    "passed_over": {
        "delta": -3.0, "cap": Ledger.Cap.TOTAL_SESSION, "limit": 6.0,
        "doc": "An item they could use went to another raider",
    },
    "passed_over_wishlist": {
        "delta": -5.0, "cap": Ledger.Cap.TOTAL_SESSION, "limit": 6.0,
        "doc": "A wishlisted item went to another raider — same -6 cap",
    },
    "wishlist_sold": {
        "delta": -7.0, "cap": Ledger.Cap.NONE,
        "doc": "A wishlisted item was sold — NOT capped, this is gold over a person",
    },
    # ------------------------------------------------------------------ §7.4 town
    "comfort_item": {
        "delta": 8.0, "cap": Ledger.Cap.COOLDOWN, "window": 2,
        "doc": "Comfort item used in the Guildhall — one per raider per 2 ticks",
    },
    "training": {
        "delta": 2.0, "cap": Ledger.Cap.ONCE_EVER,
        "doc": "Training completed — gated on canon's level-up Maybe",
    },
    "quest_completed": {
        "delta": 3.0, "cap": Ledger.Cap.ONCE_EVER,
        "doc": "Quest / achievement completed on the board — once per quest",
    },
}

## docs/05 §7.5's backstory tag hooks: a tag may scale a §7 delta by 1.5x or
## 0.5x. The doc allows exactly these two and no more, so they are named rather
## than left as an arbitrary float.
## docs/04 §11.3's other two mechanisms for ✅ CANON A11. A Legendary is "slow to anger,
## normal to please", and cannot drift into canon's leave bands by neglect alone:
##
##   `delta_multiplier`  0.35 on negative deltas, 1.0 on positive
##   `morale_floor`      40 (Slightly Annoyed) while no BIG-dumb condition is active
##
## The floor is suspended, and the multiplier returns to 1.0, under any of docs/04 §11.3's
## five named BIG-dumb conditions — canon's own bar for losing one ("unless you are BIG
## dumb"). `Morale` is handed the verdict; `game/` owns gathering the facts.
const LEGENDARY_NEG_MULT := 0.35
const LEGENDARY_FLOOR := 40

const TAG_AMPLIFY := 1.5
const TAG_DAMPEN := 0.5


static func trigger_exists(trigger_id: String) -> bool:
    return TRIGGERS.has(trigger_id)


## The pre-resilience delta a trigger carries, before caps.
static func trigger_delta(trigger_id: String) -> float:
    if not TRIGGERS.has(trigger_id):
        return 0.0
    return float(TRIGGERS[trigger_id].get("delta", 0.0))


## Apply one trigger to one raider. Returns the delta ACTUALLY applied, after
## rarity resilience, backstory scaling and the row's cap — 0.0 when the cap is
## already spent, which makes a blocked trigger a no-op rather than an error.
##
## Order matters and follows docs/05: the raw delta is scaled by the backstory
## tag, then by rarity resilience (§8), and the CAP is measured against the
## scaled magnitude, because the caps in §7 are written in the same units as the
## deltas beside them.
static func apply(raider, trigger_id: String, ledger, subject: String = "",
        tag_scale: float = 1.0) -> float:
    if raider == null or ledger == null or not TRIGGERS.has(trigger_id):
        return 0.0
    var row: Dictionary = TRIGGERS[trigger_id]
    var raw := float(row.get("delta", 0.0)) * tag_scale
    if is_zero_approx(raw):
        return 0.0

    # docs/04 §11.3, applied before the ledger so a swallowed event does not burn a
    # cooldown a Legendary never felt.
    var legendary := is_unbotherable(raider)
    if legendary and not Ledger_hears(raider, trigger_id):
        return 0.0

    var scaled := scale_delta(raider.rarity, raw)
    if legendary and scaled < 0.0 and not bool(raider.big_dumb_active):
        scaled *= LEGENDARY_NEG_MULT
    var magnitude := absf(scaled)
    var key := Ledger.key_for(raider.id, trigger_id, subject)
    var allowed: float = ledger.allowance(key, int(row.get("cap", Ledger.Cap.NONE)),
        float(row.get("limit", 0.0)), int(row.get("window", 0)), magnitude)
    if allowed <= 0.0:
        return 0.0

    ledger.record(key, int(row.get("cap", Ledger.Cap.NONE)),
        int(row.get("window", 0)), allowed)
    var applied: float = allowed if scaled > 0.0 else -allowed
    var before := morale_exact(raider)
    var after := before + applied
    if legendary and not bool(raider.big_dumb_active) and after < float(LEGENDARY_FLOOR):
        # The floor is a guarantee, not a suggestion: docs/04 §11.3 says a Legendary
        # "can never drift into the leave/disband bands by neglect", and canon's leave
        # band starts at 30. Clamping here rather than at the tick means no single event
        # can breach it either.
        after = maxf(float(LEGENDARY_FLOOR), minf(before, float(LEGENDARY_FLOOR)))
    set_morale(raider, after)
    return morale_exact(raider) - before


# ================================================================ the tick

## docs/05 §4: morale is "stored as float so sub-1 drift accumulates".
##
## `Raider.morale` is the DISPLAYED integer that every other system reads, so the
## exact value lives alongside it. Without this a Common's drift of 1.125/tick
## would truncate to 1 every tick and quietly lose an eighth of its recovery.
static func morale_exact(raider) -> float:
    if raider == null:
        return 0.0
    if raider.morale_exact < 0.0:
        return float(raider.morale)
    return raider.morale_exact


static func set_morale(raider, value: float) -> void:
    if raider == null:
        return
    var clamped := clampf(value, float(Enums.MORALE_MIN), float(Enums.MORALE_MAX))
    raider.morale_exact = clamped
    raider.morale = int(round(clamped))


## One Day Tick of drift for one raider, per docs/05 §7.5:
##     morale += clamp(baseline - morale, -drift_step, +drift_step)
##     drift_step = 1.5 * drift_rate[rarity]
##
## "Drift is the anti-farm mechanism and the recovery mechanism at once: morale
## gained above baseline decays, and morale lost below baseline recovers, both at
## the rarity's own pace."
static func drift_raider(raider, facility_tier: int = 0,
        backstory_offset: int = 0) -> float:
    if raider == null:
        return 0.0
    var before := morale_exact(raider)
    var target := float(baseline_for(raider.rarity,
        facility_bonus_for(facility_tier), backstory_offset,
        _comfort_of(raider)))
    var rate: float = DRIFT_RATE[raider.rarity] if _valid(raider.rarity) else 1.0
    var step: float = BASE_DRIFT * rate
    var after := before + clampf(target - before, -step, step)
    set_morale(raider, after)
    return after - before


## Where drift is pulling this raider, backstory and facilities included. The
## single answer to "what is this raider's baseline", so no caller has to remember
## that three terms go into it.
static func baseline_of(raider, facility_tier: int = 0) -> int:
    if raider == null:
        return BASE_BASELINE
    return baseline_for(raider.rarity, facility_bonus_for(facility_tier),
        _backstory_of(raider), _comfort_of(raider))


## Whether rest has anything left to give this raider. docs/05 §8's drift pulls
## toward the baseline and stops dead there, so at-or-above the baseline is the
## definition of recovered — a raider ABOVE it is drifting down, which is not
## something resting fixes.
static func is_recovered(raider, facility_tier: int = 0) -> bool:
    if raider == null:
        return true
    return morale_exact(raider) \
        >= float(baseline_of(raider, facility_tier)) - 0.0001


## Day Ticks of rest before this raider reaches their baseline.
##
## Unlike `ticks_to_baseline()` this is one-directional: it answers "how long must
## I rest", so a raider already at or above baseline needs zero regardless of how
## far above they are.
static func rest_ticks_for(raider, facility_tier: int = 0) -> int:
    if raider == null or is_recovered(raider, facility_tier):
        return 0
    var gap := float(baseline_of(raider, facility_tier)) - morale_exact(raider)
    var rate: float = DRIFT_RATE[raider.rarity] if _valid(raider.rarity) else 1.0
    return int(ceil(gap / (BASE_DRIFT * rate)))


## The days of rest the whole roster needs — the number on the button. It is the
## slowest raider, not the average: resting stops when everyone has settled.
static func rest_ticks_needed(roster: Array, facility_tier: int = 0) -> int:
    var most := 0
    for r in roster:
        most = maxi(most, rest_ticks_for(r, facility_tier))
    return most


static func roster_is_rested(roster: Array, facility_tier: int = 0) -> bool:
    for r in roster:
        if not is_recovered(r, facility_tier):
            return false
    return true


## docs/05 §7.6's ceiling: 50 + 12 (Legendary) + 10 (tier 3) + 8 (backstory) = 80,
## "the bottom of band 8, Very Happy". Band 9 is reachable only by active play,
## for anyone — "the top band should feel earned".
static func max_sustainable(rarity: int) -> int:
    return baseline_for(rarity, FACILITY_BONUS[FACILITY_BONUS.size() - 1],
        BACKSTORY_OFFSET_MAX)


# ================================================================ §6 leaving

## docs/05 §6.1's canon gates, quoted: band 0-10 "may cause guild disband";
## 10-20 and 20-30 "may leave guild"; 30-40 "Won't leave".
##
## The doc is emphatic that the floor is not a low probability but an absolute:
## "Departure impossible — a hard floor, not a low probability". So bands 3-9 are
## a literal zero, never a small number that rounds to never.
const LEAVE_RATE := [0.22, 0.14, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

## docs/05 §6.2. Canon constrains this directly: "you wont have to worry about
## losing your higher tier raiders unless you are BIG dumb".
const LEAVE_RESILIENCE := [1.30, 1.10, 0.85, 0.55, 0.25]

## docs/05 §6.2's hard rules 1 and 2, resolved into one gate.
##
##   1. "A raider cannot leave on the same Day Tick they first entered band 0-2"
##   2. "A raider cannot leave while at_risk_strikes == 0"
##
## Strikes increment during the tick a raider enters band 0-2, so on that tick
## they sit at 1 — rule 1 forbids leaving. They reach 2 on the following tick,
## which is the first tick they may leave. The two rules therefore reduce to a
## single threshold, and expressing it as one constant means neither can be
## satisfied while the other is quietly broken.
const MIN_STRIKES_TO_LEAVE := 2


## docs/05 §6.2: `p_leave = leave_rate[band] * leave_resilience[rarity]`.
static func p_leave(raider) -> float:
    if raider == null:
        return 0.0
    var band := Enums.morale_band(raider.morale)
    var rate: float = LEAVE_RATE[clampi(band, 0, LEAVE_RATE.size() - 1)]
    if rate <= 0.0:
        return 0.0
    var resilience: float = LEAVE_RESILIENCE[raider.rarity] \
        if _valid(raider.rarity) else 1.0
    return rate * resilience


## Update the consecutive-tick counter. Called once per Day Tick, before the
## leave check, and returns the new value.
static func update_at_risk_strikes(raider) -> int:
    if raider == null:
        return 0
    if is_at_risk(raider.morale):
        raider.at_risk_strikes += 1
    else:
        raider.at_risk_strikes = 0
    return raider.at_risk_strikes


## docs/05 §6.2's Warning UX ladder: 1 amber, 2 red + "AT RISK", 3+ red +
## "MAY LEAVE" and pinned to the top of the roster. Returned as the strike count
## clamped to 3 so a screen can switch on it without knowing the table.
static func warning_level(raider) -> int:
    if raider == null:
        return 0
    return mini(3, raider.at_risk_strikes)


## Whether this raider is even eligible to be rolled for. Separated from the roll
## so the gate can be asserted without an RNG in hand.
static func may_leave(raider, in_raid: bool = false) -> bool:
    if raider == null:
        return false
    # docs/05 §6.2 hard rule 3: "A raider mid-raid never leaves. Departure
    # resolves in town only."
    if in_raid:
        return false
    if raider.at_risk_strikes < MIN_STRIKES_TO_LEAVE:
        return false
    return p_leave(raider) > 0.0


## Roll the departure. docs/05 §6.2 hard rule 4 is a deliberate absence: "The
## last raider of a class flagged required by an unlocked raid still leaves. No
## plot armor; the player must recruit at the Tavern." Nothing here consults the
## roster's composition, and that is the rule being honoured.
static func rolls_to_leave(raider, rng, in_raid: bool = false) -> bool:
    if not may_leave(raider, in_raid) or rng == null:
        return false
    return rng.chance_bp(int(round(p_leave(raider) * 10000.0)))


# ================================================================ §6 disband

## docs/05 §6.3 condition B.
const CRISIS_AVG_MORALE_MAX := 25

## docs/05 §6.3's escalation, indexed by crisis_strikes. Strikes 1 and 2 are
## flatly 0%, which is the mechanism behind the doc's absolute rule: "disband can
## never fire without prior warning ... At least two full Day Ticks of escalating
## warning before any roll."
const DISBAND_P := [0.0, 0.0, 0.0, 0.08, 0.18, 0.30]

## docs/05 §6.3 condition C.
const MIN_CRISIS_STRIKES_TO_DISBAND := 3

## The strike count at which the unmissable modal is raised (docs/05 §6.3).
const CRISIS_MODAL_STRIKE := 2


## docs/05 §6.3 conditions A and B, which together decide whether the strike
## counter advances. C is the counter itself, so it is not evaluated here.
##
##   A  at least one raider is in band 0 (morale < 10)
##   B  guild average morale across the FULL roster is below 25
static func crisis_conditions_hold(roster: Array) -> bool:
    if roster.is_empty():
        return false
    var any_band_zero := false
    var total := 0.0
    for r in roster:
        if Enums.morale_band(r.morale) == 0:
            any_band_zero = true
        total += float(r.morale)
    if not any_band_zero:
        return false
    return (total / float(roster.size())) < float(CRISIS_AVG_MORALE_MAX)


## docs/05 §6.3: increments while A and B hold, "resets to 0 on any tick where
## either fails".
static func next_crisis_strikes(roster: Array, current: int) -> int:
    if crisis_conditions_hold(roster):
        return current + 1
    return 0


static func p_disband(crisis_strikes: int) -> float:
    if crisis_strikes < MIN_CRISIS_STRIKES_TO_DISBAND:
        return 0.0
    return DISBAND_P[mini(crisis_strikes, DISBAND_P.size() - 1)]


## docs/05 §6.3: "No disband during onboarding — disabled until the player has
## completed Adventure 0 and the Tutorial Raid."
static func may_disband(crisis_strikes: int, onboarding_complete: bool) -> bool:
    if not onboarding_complete:
        return false
    return p_disband(crisis_strikes) > 0.0


static func rolls_to_disband(crisis_strikes: int, onboarding_complete: bool,
        rng) -> bool:
    if not may_disband(crisis_strikes, onboarding_complete) or rng == null:
        return false
    return rng.chance_bp(int(round(p_disband(crisis_strikes) * 10000.0)))


# ================================================================ the Day Tick

## docs/05 §4 fixes the order and warns about it: "All drift, leave checks and
## disband checks are evaluated once per Day Tick, AFTER all event-driven morale
## deltas for that tick have applied. Order matters: never roll a leave check
## against a mid-update value."
##
## Callers apply their §7 triggers first, then call this once. Returns a report
## rather than mutating the roster array, so the caller owns removal — but it does
## write `morale` and `at_risk_strikes`, which is this module's own state.
##
## `departed` is in roster order, and a raider who leaves is excluded from the
## crisis average that follows, per §6.2: "A raider who leaves is removed before
## the next raider is checked." Their -4/-6 `peer_left` hit lands on the FOLLOWING
## tick, never this one — the doc rules out a same-tick cascade explicitly.
static func resolve_day_tick(roster: Array, rng, opts: Dictionary = {}) -> Dictionary:
    var facility_tier := int(opts.get("facility_tier", 0))
    var onboarding_complete := bool(opts.get("onboarding_complete", false))
    var crisis_strikes := int(opts.get("crisis_strikes", 0))
    var in_raid := bool(opts.get("in_raid", false))

    var departed: Array = []
    var survivors: Array = []

    for r in roster:
        drift_raider(r, facility_tier, _backstory_of(r))
        var strikes := update_at_risk_strikes(r)
        # A raider who first entered band 0-2 this tick sits at 1 strike and is
        # therefore spared by MIN_STRIKES_TO_LEAVE — the player's one tick to react.
        if strikes >= MIN_STRIKES_TO_LEAVE and rolls_to_leave(r, rng, in_raid):
            departed.append(r)
        else:
            survivors.append(r)

    var next_strikes := next_crisis_strikes(survivors, crisis_strikes)
    var disbanded := rolls_to_disband(next_strikes, onboarding_complete, rng)

    return {
        "departed": departed,
        "survivors": survivors,
        "crisis_strikes": next_strikes,
        "crisis": crisis_conditions_hold(survivors),
        "p_disband_next": p_disband(next_strikes + 1),
        "show_crisis_modal": next_strikes == CRISIS_MODAL_STRIKE,
        "disbanded": disbanded,
    }


## docs/05 §7.5's backstory offset. Backstory CONTENT is docs/03's, so this reads
## whatever the raider carries and clamps it rather than inventing a value.
## Whether docs/04 §11.3's rules apply to this raider: a Legendary with an authored
## definition behind them. A procedurally generated Legendary cannot exist (canon makes
## them authored characters), so the definition id is the honest test.
static func is_unbotherable(raider) -> bool:
    return raider != null and raider.rarity == Enums.Rarity.LEGENDARY \
        and not String(raider.legendary_def_id).is_empty()


## Indirection so `Morale` does not import `sim/content`, which would point a rules file
## at a data loader. The subscription question is about the raider's own bullets, and
## `BackstoryPool` owns the tag-to-trigger map.
static func Ledger_hears(raider, trigger_id: String) -> bool:
    var pool = load("res://sim/content/BackstoryPool.gd")
    return pool.legendary_hears(raider, trigger_id)


static func _backstory_of(raider) -> int:
    if raider == null:
        return 0
    return clampi(raider.backstory_offset,
        BACKSTORY_OFFSET_MIN, BACKSTORY_OFFSET_MAX)


## docs/02 §4.2's comfort floor, carried on the raider so every function that
## computes a baseline picks it up without a new parameter — drift, resting and
## recovery included. `game/` owns writing it (`GameState._recompute_comfort()`);
## `sim/` only ever reads it, which is why a stale value cannot be produced here.
static func _comfort_of(raider) -> int:
    if raider == null:
        return 0
    return maxi(0, int(raider.comfort_floor))
