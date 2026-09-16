class_name TwgFormulas
extends RefCounted
## Every number the simulation produces. docs/08 §8 is the specification.
##
## docs/07 owns combat RULES — turn order, targeting, what a mechanic does.
## This file owns the ARITHMETIC. Nothing here knows about rounds or phases.
##
## Two canon ambiguities are isolated here on purpose, each behind ONE named
## switch, so resolving them is an edit in this file and nowhere else:
##
##   AC_READING   — canon's "AC = 2 damage reduction" has four defensible
##                  parses (docs/08 §3.3, Readings 1, 1b, 2 and 3).
##                  docs/15 Q-01 ruled Reading 3.
##   MANA_MODEL   — canon asks out loud whether healers need "2 variables".
##                  docs/15 Q-02 ruled Model A+: Mana is a magnitude stat, plus
##                  a class-fixed Focus resource that never appears on gear.
##
## Integer policy (docs/08 §12): 64-bit float internally, rounded ONCE at the
## final damage/heal value, half-up, floored at 1 for a landed hit.

const Enums = preload("res://sim/model/Enums.gd")

# ================================================================ AC

## docs/08 §3.3 Reading 3, ruled in docs/15 Q-01.
## The ×2 numerator keeps canon's "AC = 2 damage reduction" literally inside the
## formula while the denominator bends the curve, so tiers 2-5 can raise AC
## without trivialising tier 1. The flat reading was rejected because at Tier 1
## Raid a swing that takes 8 unhealed rounds to kill the tank kills a Mage in
## 1.65 — cloth and tanks cannot coexist under it (docs/08 §3.2).
## Members map to docs/08 §3.3's numbering: CURVE is Reading 3,
## FLAT_TWO_PER_POINT Reading 1, FLAT_HALF_AC Reading 1b, DIVISOR Reading 2.
enum AcReading { CURVE, FLAT_TWO_PER_POINT, FLAT_HALF_AC, DIVISOR }

const AC_READING := AcReading.CURVE
const AC_K := 60.0

## docs/08 §9's own OPEN note, implemented as a switch (docs/15 BL-72).
##
## §9 observes that a flat `AC_K` makes `MITIGATION_CAP` bind as the ladder
## climbs — armour stops buying survivability and the tank channel becomes a
## constant — and proposes `AC_K(tier) = 60 * 1.5^index`. With the step at 1.0
## the curve is exactly what Tier 1 shipped, so both readings stay selectable.
##
## TWO THINGS IN THAT NOTE ARE WRONG ABOUT THE LADDER THAT EXISTS, both measured
## against docs/08 §9.6 rather than argued:
##
## 1. WHERE THE CAP BINDS. The note says "roughly index 5" from a projected AC
##    of 107. The real ladder reaches AC 40 at Tier 3 Boss 1 (mitigation 57.1%),
##    64 at Tier 4 (68.1%), and only touches the cap at Tier 5 Boss 1 (AC 102,
##    exactly 75.0%). A Tier 5 problem, not a Tier 3 one.
## 2. THE STEP IS PER TIER, NOT PER RUNG. §9 writes `1.5^index` and the ladder
##    has ten rung indices across five tiers, so read per index the correction
##    over-shoots: tank mitigation falls to 14.9% at Tier 3 and 11.1% at Tier 4,
##    which is armour that has stopped mattering in the other direction. The
##    ladder's own tank AC grows about x1.55 per TIER (17 / 26 / 40 / 64 / 102
##    at the raid rungs), so a K that grows x1.5 per TIER holds mitigation
##    almost flat: 36.2% / 36.6% / 37.2% / 38.7% / 40.2%.
##
## So the parameter is the TIER. A step of 1.0 selects the flat reading.
const AC_K_TIER_STEP := 1.5

## `AC_K` at a tier of the ladder. Tier 1 is the shipped 60, so every caller that
## does not know its tier gets exactly what shipped and nothing moves.
static func ac_k_for(tier: int) -> float:
    return AC_K * pow(AC_K_TIER_STEP, float(maxi(0, tier - 1)))


const MITIGATION_CAP := 0.75
const MIN_HIT_FRACTION := 0.10   # both flat readings; docs/08 §3.3 writes it into each

## Damage actually taken after armour, under an explicitly named reading.
## `damage_after_ac()` is this at the shipped AC_READING; the parameter exists so
## the three unshipped readings stay exercisable by a test. They were not, and
## two of them were wrong in a way nothing could see (see `mitigation_under`).
##
## Each branch is docs/08 §3.3's published formula, character for character.
static func damage_after_ac_under(reading: int, raw: float, ac: int,
        tier: int = 1) -> int:
    match reading:
        AcReading.CURVE:
            return maxi(1, int(round(raw
                * (1.0 - mitigation_under(AcReading.CURVE, ac, tier)))))
        AcReading.FLAT_TWO_PER_POINT:
            return maxi(int(ceil(raw * MIN_HIT_FRACTION)), int(round(raw - float(ac) * 2.0)))
        AcReading.FLAT_HALF_AC:
            return maxi(int(ceil(raw * MIN_HIT_FRACTION)), int(round(raw - floor(float(ac) / 2.0))))
        AcReading.DIVISOR:
            return maxi(1, int(round(raw / maxf(1.0, float(ac) / 2.0))))
    push_error("Formulas: unknown AcReading %d; falling back to unmitigated damage" % reading)
    return maxi(1, int(round(raw)))


## True when `reading` removes a CONSTANT FRACTION of every hit, so a single
## `mitigation(ac)` number describes it. The two flat readings subtract a fixed
## amount instead: their effective fraction moves with the size of the hit, and
## no `f(ac)` can report it. That distinction is the whole of DW-B2.
static func reading_is_proportional(reading: int) -> bool:
    return reading == AcReading.CURVE or reading == AcReading.DIVISOR


## Constant mitigation fraction under a named reading, or NAN where the reading
## has none. NAN and not 0.0: the flat branches used to answer "zero mitigation",
## which is indistinguishable from "no armour at all" and is what let two of the
## four settings silently produce an armourless game. NAN poisons the arithmetic
## it is fed to, so a wrong caller now shows up in the first number it prints.
static func mitigation_under(reading: int, ac: int, tier: int = 1) -> float:
    match reading:
        AcReading.CURVE:
            var a := float(ac) * 2.0
            return minf(MITIGATION_CAP, a / (a + ac_k_for(tier)))
        AcReading.DIVISOR:
            # docs/08 §3.3 Reading 2: `damage = raw / max(1.0, AC / 2.0)`.
            # Deliberately NOT clamped to MITIGATION_CAP — §3.2's window proof
            # only reproduces uncapped (AC 15 vs 127.5 raw must land on 17.0),
            # and "no invulnerability ceiling" is the reading's stated Pro. The
            # max(1.0, ...) is the doc's own guard against a 0 AC recruit
            # dividing by zero, and against AC under 2 amplifying the hit.
            return 1.0 - (1.0 / maxf(1.0, float(ac) / 2.0))
        AcReading.FLAT_TWO_PER_POINT, AcReading.FLAT_HALF_AC:
            return NAN
    # The flat readings above return NAN because that is the true answer. An
    # AcReading that is not a member at all is a different thing entirely, and
    # falling off the end of the match returned the same NAN with no error —
    # a typo'd reading was indistinguishable from a reading that refuses.
    # `damage_after_ac_under` guards its own fall-through the same way.
    push_error(("Formulas.mitigation_under(): unknown AcReading %d; there is no"
        + " mitigation fraction for a reading that does not exist.") % reading)
    return NAN


## Fraction of incoming damage removed by armour. Never rounded (docs/08 §12).
## Valid only while a proportional reading is live — see `mitigation_at()` for
## the reading-agnostic answer.
static func mitigation(ac: int, tier: int = 1) -> float:
    var m := mitigation_under(AC_READING, ac, tier)
    if is_nan(m):
        push_error("Formulas.mitigation(): AC_READING is a flat reading (docs/08 §3.3"
            + " Reading 1/1b), which has no constant mitigation fraction."
            + " Call mitigation_at(raw, ac) or damage_after_ac(raw, ac) instead.")
    return m


## The fraction a hit of this size actually loses to armour, under whatever
## reading is live. Defined for all four, because it is measured from the one
## function that implements all four rather than derived alongside it.
##
## Domain: `raw >= 1`. Below 1, docs/08 §8.4's floor makes the hit land for MORE
## than it was worth — 0.5 raw still deals 1 — so the honest fraction is
## negative, and this returns it. Clamping to 0.0 was the alternative and it is
## the worse one: it would put this helper back to stating one armour figure
## while `damage_after_ac()` deals another, which is DW-B2 exactly. As written,
## `round(raw * (1 - mitigation_at(raw, ac))) == damage_after_ac(raw, ac)` holds
## for every `raw > 0`, and a test pins it below 1 as well as above.
## `raw == 0` is the one seam: there is no fraction of nothing, so it answers
## 0.0 while the floor still deals 1. No production caller passes either — every
## encounter `raw_swing` in docs/10 is an integer of at least 1.
static func mitigation_at(raw: float, ac: int) -> float:
    if raw <= 0.0:
        return 0.0
    return 1.0 - (float(damage_after_ac(raw, ac)) / raw)


## Damage actually taken after armour. Rounded once, floored at 1: a landed hit
## never does nothing (docs/08 §8.4).
static func damage_after_ac(raw: float, ac: int, tier: int = 1) -> int:
    return damage_after_ac_under(AC_READING, raw, ac, tier)


## Flipping AC_READING to a flat reading is legitimate — `damage_after_ac()`
## implements all four faithfully — but it silently invalidates every caller
## still holding `mitigation(ac)`, and those callers are in balance tests and
## encounter-authoring checks where a wrong number validates instead of failing.
## So the mismatch announces itself when the script loads, not three weeks later
## in a tuning table.
static func _static_init() -> void:
    if not reading_is_proportional(AC_READING):
        push_error("Formulas: AC_READING is a flat reading (docs/08 §3.3 Reading 1/1b)."
            + " mitigation(ac) cannot answer under it and now returns NAN;"
            + " audit every caller onto mitigation_at(raw, ac) before shipping this.")


## Raid-wide and spell damage bypass armour (docs/10 §5.4), so encounter
## pressure lands on healer throughput rather than on the tank's gear score.
static func raid_wide_damage(raw: float) -> int:
    return maxi(1, int(round(raw)))


# ================================================================ Mana

## docs/15 Q-02, "Model A+": Mana is a magnitude stat driving both spell damage
## and healing. Focus is a separate class-fixed resource that never appears on
## an item, so no item table changes and docs/07's healer mistakes have a real
## pool to spend.
enum ManaModel { MAGNITUDE_PLUS_FOCUS, MAGNITUDE_ONLY, POOL_AND_POWER }

const MANA_MODEL := ManaModel.MAGNITUDE_PLUS_FOCUS
const MANA_TO_SPELL := 0.35
const MANA_TO_HEAL := 0.80


# ================================================================ the tier-0 floor

## docs/15 BL-27, and the reason it existed at all.
##
## ✅ CANON gives common recruits "Starting armor": four armour pieces, no
## weapon, no HP and no Mana on any piece. Every output formula in this file
## reads off gear, so a fresh guild dealt EXACTLY ZERO damage and healed EXACTLY
## ZERO. Measured: Adventure 1 was unwinnable at any enemy HP, including 40% of
## the authored value, because the party died rather than failing to kill.
##
## docs/16 §E1.3 asks doc 08 to publish `base` and `k` for
## `heal = base_class + k x Mana`. These ship as **FLOORS rather than addends**,
## which serves the same intent - a class can always do *something* - with one
## decisive advantage: a floor changes nothing for anyone holding a weapon, so
## every validated geared number stays exactly where it was, including E5's
## 22-round first clear. Gear remains the whole progression story, which is what
## canon's itemization thesis requires.
##
## Both are deliberately a fraction of the FIRST real Tier 1 Adventure item, so
## the first weapon a raider ever picks up is a visible upgrade:
##   UNARMED_DAMAGE 2  vs the Adventure sword's +5 damage
##   HEAL_FLOOR     6  vs the Adventure healing weapon's heal_base 14

## Implied weapon damage for an empty main hand. Bare hands, a borrowed knife.
const UNARMED_DAMAGE := 2

## The least a healer can do with no weapon and no Mana: mumble something.
const HEAL_FLOOR := 6


## Main-hand damage after the unarmed floor. Applied to the MAIN HAND ONLY - an
## empty off-hand must stay empty, or every dual-wielder would gain a phantom
## second weapon they never picked up.
static func effective_main_damage(weapon_damage: int) -> int:
    return maxi(weapon_damage, UNARMED_DAMAGE)


# ================================================================ melee

const MELEE_SWINGS := 2
const OFFHAND_COEF := 0.75

## docs/08 §8.2. Zero for classes that do not melee.
const CLASS_MELEE_COEF := {
    Enums.CharClass.WARRIOR: 1.00,
    Enums.CharClass.MONK: 1.10,
    Enums.CharClass.ROGUE: 0.95,
    Enums.CharClass.BARD: 0.55,
    Enums.CharClass.CLERIC: 0.00,
    Enums.CharClass.DRUID: 0.00,
    Enums.CharClass.SHAMAN: 0.00,
    Enums.CharClass.MAGE: 0.00,
    Enums.CharClass.WIZARD: 0.00,
}

## One swing, pre-mitigation. Power is added ONCE PER SWING, not once per round —
## that is what makes Raid-tier Power the upgrade it looks like (docs/08 §8.2).
static func melee_swing(char_class: int, weapon_damage: int, power: int,
        hand_coef: float = 1.0, positional_mult: float = 1.0) -> float:
    var base := (float(weapon_damage) * hand_coef) + float(power)
    return base * float(CLASS_MELEE_COEF.get(char_class, 0.0)) * positional_mult


## Total pre-mitigation melee output for one round.
static func melee_damage_per_round(char_class: int, main_hand_damage: int,
        off_hand_damage: int, power: int, dual_wields: bool,
        positional_mult: float = 1.0) -> float:
    var main: int = effective_main_damage(main_hand_damage)
    var total := 0.0
    for _i in MELEE_SWINGS:
        total += melee_swing(char_class, main, power, 1.0, positional_mult)
        if dual_wields:
            total += melee_swing(char_class, off_hand_damage, power, OFFHAND_COEF, positional_mult)
    return total


# ================================================================ spells

## docs/08 §8.3. Mage's coefficient is PER TARGET — canon calls it an AoE caster,
## so its total output scales with how many things it can hit.
const CLASS_SPELL_COEF := {
    Enums.CharClass.WIZARD: 1.60,
    Enums.CharClass.MAGE: 0.60,
    Enums.CharClass.CLERIC: 0.25,
    Enums.CharClass.DRUID: 0.25,
    Enums.CharClass.SHAMAN: 0.25,
    Enums.CharClass.WARRIOR: 0.00,
    Enums.CharClass.MONK: 0.00,
    Enums.CharClass.ROGUE: 0.00,
    Enums.CharClass.BARD: 0.00,   # songs are docs/06's, not spell damage
}

## docs/08 §9's paired OPEN note, the other half of BL-72: the Mana ladder steps
## x2.00 per half-tier, so either `MANA_TO_SPELL` decays 0.85 per tier or Mana's
## own step comes down to ~1.55 — "only one of the two may be written down". The
## decay is the half implemented, because it is the one that does not move
## canon's Tier 1 item tables. A decay of 1.0 selects the flat reading.
const MANA_TO_SPELL_TIER_DECAY := 0.85

static func mana_to_spell_for(tier: int) -> float:
    return MANA_TO_SPELL * pow(MANA_TO_SPELL_TIER_DECAY, float(maxi(0, tier - 1)))


static func spell_power(weapon_damage: int, mana: int, tier: int = 1) -> float:
    return float(effective_main_damage(weapon_damage)) + (float(mana) * mana_to_spell_for(tier))


## Damage of one cast against one target, pre-mitigation.
static func spell_damage(char_class: int, weapon_damage: int, mana: int,
        spell_coef: float = 1.0, tier: int = 1) -> float:
    return spell_power(weapon_damage, mana, tier) * spell_coef \
        * float(CLASS_SPELL_COEF.get(char_class, 0.0))


## What an AoE caster actually contributes against N targets.
static func spell_damage_total(char_class: int, weapon_damage: int, mana: int,
        targets: int, spell_coef: float = 1.0, tier: int = 1) -> float:
    return spell_damage(char_class, weapon_damage, mana, spell_coef, tier) \
        * float(maxi(1, targets))


# ================================================================ healing

const DRUID_RAID_COEF := 0.25

## docs/08 §8.5 — the direct numeric encoding of canon's Shaman chain heal,
## "Medium → medium → small healing".
const SHAMAN_CHAIN_COEFS := [0.65, 0.65, 0.35]

## docs/08 §8.5. `heal_base` comes from the healer's weapon; canon leaves those
## stats TBD, so data/items_*.json carries a PROPOSED value per rung.
##
## This is why heal_base exists at all: canon starting armour carries NO Mana
## (raw notes, *Starting armor*), so a purely Mana-derived heal would be exactly
## zero at game start and healers would be decorative until their first drop.
## docs/10 §5.2 flags that as a live risk; heal_base is the floor that prevents it.
## The HEAL_FLOOR is what stops a 0-Mana, weaponless healer being decorative
## (docs/15 BL-27). It is a floor, not an addend, so a geared healer's output is
## byte-identical to what it was before the floor existed.
static func heal_power(weapon_heal_base: int, mana: int) -> float:
    return maxf(float(HEAL_FLOOR),
        float(weapon_heal_base) + (float(mana) * MANA_TO_HEAL))


## Cleric — canon "Efficient single-target healing". One target, full power.
static func cleric_heal(weapon_heal_base: int, mana: int) -> int:
    return maxi(1, int(round(heal_power(weapon_heal_base, mana))))


## Druid — canon "Small heal to the entire raid every round".
## Returns the per-target amount; total throughput is that times the raid size,
## which is the largest number in the table and an artifact of a 12-raid rather
## than of power. DRUID_RAID_COEF is the lever; docs/08 warns against raising it
## above 0.30 without re-checking the boss AoE budget.
static func druid_raid_heal(weapon_heal_base: int, mana: int) -> int:
    return maxi(1, int(round(heal_power(weapon_heal_base, mana) * DRUID_RAID_COEF)))


## Shaman — canon "Medium → medium → small". Returns the three bounces in order.
static func shaman_chain_heal(weapon_heal_base: int, mana: int) -> Array:
    var power := heal_power(weapon_heal_base, mana)
    var out: Array[int] = []
    for coef in SHAMAN_CHAIN_COEFS:
        out.append(maxi(1, int(round(power * float(coef)))))
    return out


# ================================================================ variance

## docs/08 §8.6, shipping the conservative option on the doc's own
## recommendation: this game's drama comes from mistake rolls and morale, not
## from damage dice. Deterministic damage keeps the combat log readable, makes
## "why did we wipe" answerable, and makes every budget figure exact rather than
## expected. Turn these on later if fights feel mechanical.
const DAMAGE_VARIANCE := 0.0
const CRIT_CHANCE_BP := 0
const CRIT_MULT := 1.50

## Applies variance and crit. With the shipped constants this is the identity,
## and it consumes no RNG draws — which matters, because a draw taken here would
## shift every downstream roll and invalidate golden files.
static func apply_variance(base: float, rng) -> float:
    if DAMAGE_VARIANCE <= 0.0 and CRIT_CHANCE_BP <= 0:
        return base
    var out := base
    if DAMAGE_VARIANCE > 0.0 and rng != null:
        var span := int(round(DAMAGE_VARIANCE * 10000.0))
        var roll: int = rng.randi_range(-span, span)
        out *= 1.0 + (float(roll) / 10000.0)
    if CRIT_CHANCE_BP > 0 and rng != null and rng.chance_bp(CRIT_CHANCE_BP):
        out *= CRIT_MULT
    return out


# ================================================================ threat

## docs/08 §8.7. The Warrior's 3.00 is canon's "high threat" made numeric.
const THREAT_COEF := {
    Enums.CharClass.WARRIOR: 3.00,
    Enums.CharClass.MONK: 1.50,
    Enums.CharClass.ROGUE: 0.80,   # canon wants rogues NOT tanking
    Enums.CharClass.WIZARD: 1.00,
    Enums.CharClass.MAGE: 1.00,
    Enums.CharClass.BARD: 0.50,
    Enums.CharClass.CLERIC: 0.00,
    Enums.CharClass.DRUID: 0.00,
    Enums.CharClass.SHAMAN: 0.00,
}

const HEAL_THREAT_COEF := 0.50
const TAUNT_THRESHOLD_MELEE := 1.10
const TAUNT_THRESHOLD_RANGED := 1.30

## Threat is generated from PRE-mitigation damage so a tank's own high AC does
## not starve their threat generation (docs/08 §8.1).
static func threat_from(char_class: int, pre_mitigation_damage: float,
        healing_done: float = 0.0) -> float:
    var t := pre_mitigation_damage * float(THREAT_COEF.get(char_class, 0.0))
    t += healing_done * HEAL_THREAT_COEF
    return t


## Whether the boss should switch targets. The RULE is docs/07's; this is only
## the comparison.
static func should_retarget(candidate_threat: float, current_threat: float,
        candidate_is_melee: bool) -> bool:
    return candidate_threat > current_threat * retarget_threshold(candidate_is_melee)


## The hysteresis a candidate has to clear, by where they stand. Its own
## function so MIS_AGGRO can set a threat that clears it by construction
## (docs/07 §8.2: the mistake "sets the offender above the primary target
## regardless") — SIM-17's flat 1.10 would have left a Wizard's pull under the
## ranged bar and the boss on the tank, which is the opposite of the joke.
static func retarget_threshold(candidate_is_melee: bool) -> float:
    return TAUNT_THRESHOLD_MELEE if candidate_is_melee else TAUNT_THRESHOLD_RANGED


## docs/07 §8.2: "a tank is stable while `tank_threat >= 1.30 × highest_non_tank`."
const TANK_LEAD_RATIO := 1.30

## docs/07 §8.1: "Taunt sets the taunter's threat to `1.10 × current highest`."
const TAUNT_RATIO := 1.10


## Tank Lead (docs/07 §8.2). True while the tank is stable; a tank whose lead
## is lost spends its next action on a Taunt (RaidSim's Phase 2).
static func tank_lead_held(tank_threat: float, highest_non_tank: float) -> bool:
    return tank_threat >= highest_non_tank * TANK_LEAD_RATIO


## The threat a Taunt sets (docs/07 §8.1): 1.10 × the table's top, as the
## smallest integer STRICTLY above it — the melee retarget bar is the same
## 1.10, and a taunt that landed exactly on `should_retarget`'s `>` would
## leave the boss where it was, which is the one outcome a taunt exists to
## rule out.
static func taunt_threat(current_highest: float) -> int:
    return _first_int_above(current_highest * TAUNT_RATIO)


## The threat MIS_AGGRO sets: past the offender's own retarget threshold, so
## the boss turns on them at the next Phase 1 whatever the table says
## (docs/07 §8.2's short-circuit, expressed in the hysteresis's own terms).
static func aggro_pull_threat(current_top: float, offender_is_melee: bool) -> int:
    return _first_int_above(current_top * retarget_threshold(offender_is_melee))


## The smallest integer strictly greater than `x`, checked against the same
## float `should_retarget` compares with: `1.1 * 100` is 110.00000000000001
## in a double, so `ceil` alone over-shoots by one and `floor + 1` can land
## exactly on a bar the `>` then refuses.
static func _first_int_above(x: float) -> int:
    var t := int(floor(x)) + 1
    if float(t) <= x:
        t += 1
    return t


# ================================================================ mistakes

## The single most important number in the game, and it had two values.
##
## docs/08 §8.8 published `base * MORALE_MULT[band]` with bases 22/15/9/4/1.
## docs/05 §5.1 published `base * (1 + band_delta[band] * sensitivity[rarity])`
## with bases 24/15/8/3.5/1.2. The two disagreed by roughly 2x — a Very Upset
## Common was 81.6% under one and 40% under the other.
##
## docs/15 Q-04/05 resolved it: docs/08 owns the equation and coefficients,
## importing docs/05's per-rarity `sensitivity`. Both documents independently
## proposed that same resolution, and docs/08 says plainly that sensitivity "is
## a genuinely better encoding of CANON 'legendary raiders will not be bothered
## by many things easily' than one flat multiplier per band" — because a flat
## per-band multiplier cannot express resilience that varies by rarity.
##
## So: docs/05's shape and coefficients, living here, in one place, forever.
##
##     chance = base[rarity] * (1 + band_delta[band] * sensitivity[rarity])
##     chance = chance * facility_mult + situational
##     chance = clamp(chance, floor[rarity], ceiling[rarity])
##
## Everything is in basis points (1% = 100bp) so outcome gates stay integer
## arithmetic, per docs/14 §8.

## Chance at band Content (50-60), which canon calls "Base mistake chance".
const MISTAKE_BASE_BP := {
    Enums.Rarity.COMMON: 2400,      # canon: "the worst players ... 0 raid experience"
    Enums.Rarity.UNCOMMON: 1500,    # canon: "a small amount of experience"
    Enums.Rarity.RARE: 800,         # canon: "only make mistakes sometimes"
    Enums.Rarity.EPIC: 350,         # canon: "rarely make a mistake"
    Enums.Rarity.LEGENDARY: 120,    # canon: "near 1% chance of mistake"
}

## How hard morale hits this rarity. Falls as rarity rises — this IS canon's
## "legendary raiders will not be bothered by many things easily", expressed in
## the mistake curve rather than only in how fast morale moves.
const MISTAKE_SENSITIVITY := {
    Enums.Rarity.COMMON: 1.20,
    Enums.Rarity.UNCOMMON: 1.05,
    Enums.Rarity.RARE: 0.90,
    Enums.Rarity.EPIC: 0.70,
    Enums.Rarity.LEGENDARY: 0.50,
}

## Hard clamps, so canon's "within tier limits for mistakes based on their tier"
## is literally enforceable rather than emergent. In practice no band reaches
## them — they are safety rails for tokens and facility effects, not tuning.
const MISTAKE_FLOOR_BP := {
    Enums.Rarity.COMMON: 1200, Enums.Rarity.UNCOMMON: 800, Enums.Rarity.RARE: 500,
    Enums.Rarity.EPIC: 250, Enums.Rarity.LEGENDARY: 90,
}
const MISTAKE_CEIL_BP := {
    Enums.Rarity.COMMON: 8500, Enums.Rarity.UNCOMMON: 5000, Enums.Rarity.RARE: 2500,
    Enums.Rarity.EPIC: 900, Enums.Rarity.LEGENDARY: 250,
}

## The morale side of the curve, one entry per canon band (docs/05 §5.2).
## Deliberately asymmetric: the punishment side has roughly 6x the range of the
## reward side. Falling apart is dramatic; being adored is a modest, reliable
## edge. That is the correct shape for a game whose premise is that these people
## are bad at this: the drama has to live on the failure side.
const MORALE_BAND_DELTA := [
    2.00,   # 0  Very Upset        canon: "Very high mistake chance"
    1.40,   # 1  Upset             canon: "Increased"
    0.90,   # 2  Unhappy           canon: "Increased"
    0.50,   # 3  Annoyed           canon: "noticeably higher"
    0.20,   # 4  Slightly Annoyed   canon: "Slightly increased"
    0.00,   # 5  Content           canon: "Base mistake chance"
    -0.12,  # 6  Happy             canon: "Reduced"
    -0.22,  # 7  Quite Happy       canon: "Further reduced"
    -0.30,  # 8  Very Happy        canon: "Further reduced"
    -0.35,  # 9  Loves Their Guild canon: "Lowest mistake chance"
]

## docs/07 §6 caps the total situational modifier from live consequence tokens
## at +20 percentage points per raider.
const SITUATIONAL_CAP_BP := 2000

## Per-roll-site weighting of the published mistake chance.
##
## docs/07 §5.3 rules three roll sites (action, mechanic check, ambient) and
## explicitly says docs/08's base rates "must then be rescaled for the resulting
## checks-per-encounter count". That rescale is a coefficient, so it lives here.
##
## ACTION carries the published chance unscaled, because docs/08 §8.8's DPS tax
## — `effective = nominal * (1 - mistake_chance)` — models exactly one action
## roll per raider per round. Changing it would silently invalidate the whole
## progression-currency argument.
##
## MECHANIC also carries it unscaled: docs/10's difficulty dial IS how many
## responses a fight demands, so a check must be as hard as acting.
##
## AMBIENT is scaled down. Going AFK, arguing in raid chat and calling loot early
## should be occasional colour, not a second full mistake roll every round.
##
## These are provisional until the balance sweep measures real mistakes per
## encounter — see docs/15 BL-21.
## Tuned against the balance sweep, 2026-09-09 (docs/15 BL-21). The first cut
## used 1.00/1.00/0.35, which measured at up to 312 mistakes per encounter — an
## unreadable wall. These values make the PER-ROUND AGGREGATE across sites equal
## docs/08's published per-round chance, which is exactly what its DPS-tax
## argument assumes: with two rolls in a typical round, each site needs about
## `1 - sqrt(1 - p)`, i.e. roughly 0.55x. Ambient is pushed lower still because
## going AFK and arguing in raid chat are colour, not a second combat roll.
const ROLL_SITE_WEIGHT := {
    0: 0.55,   # Enums.RollSite.ACTION
    1: 0.55,   # Enums.RollSite.MECHANIC
    2: 0.15,   # Enums.RollSite.AMBIENT
}

## Mistake chance for one roll at a given site, in basis points.
static func mistake_chance_at_site_bp(rarity: int, morale: int, roll_site: int,
        situational_bp: int = 0, facility_mult: float = 1.0,
        relief_bp: float = 0.0) -> int:
    var full := mistake_chance_bp(rarity, morale, situational_bp, facility_mult,
        relief_bp)
    var w: float = float(ROLL_SITE_WEIGHT.get(roll_site, 1.0))
    return clampi(int(round(float(full) * w)), 0, 10000)


## Effective mistake chance in basis points.
##   `situational_bp` is the summed live-token modifier (docs/07 §6), capped.
##   `facility_mult` is the Guildhall's morale facilities (docs/03), default 1.0.
## `relief_bp` is docs/11 §7's Potion of Steady Hands, "-3 percentage points mistake
## chance for one named raider", in basis points.
##
## It is its own term rather than a negative `situational_bp` for two reasons. The
## situational modifier is clamped to zero and upward just below, so a negative one
## would silently do nothing. And relief is applied BEFORE the per-rarity floor, which
## ✅ CANON fixes ("mistake values stay within tier limits ... based on their tier") —
## so a potion steadies a panicking raider and cannot make a Common better than a
## Common. That is deliberate: gold buys back situational risk, never competence.
static func mistake_chance_bp(rarity: int, morale: int,
        situational_bp: int = 0, facility_mult: float = 1.0,
        relief_bp: float = 0.0) -> int:
    var base: int = int(MISTAKE_BASE_BP.get(rarity, MISTAKE_BASE_BP[Enums.Rarity.COMMON]))
    var sens: float = float(MISTAKE_SENSITIVITY.get(rarity, 1.0))
    var band := Enums.morale_band(morale)
    var delta: float = float(MORALE_BAND_DELTA[band])

    var p := float(base) * (1.0 + delta * sens)
    p *= maxf(0.0, facility_mult)
    p += float(clampi(situational_bp, 0, SITUATIONAL_CAP_BP))
    p -= maxf(0.0, relief_bp)

    var lo: int = int(MISTAKE_FLOOR_BP.get(rarity, 0))
    var hi: int = int(MISTAKE_CEIL_BP.get(rarity, 10000))
    return clampi(int(round(p)), lo, hi)


## Same value as a fraction, for display and for the DPS-tax calculation.
static func mistake_chance(rarity: int, morale: int,
        situational_bp: int = 0, facility_mult: float = 1.0) -> float:
    return float(mistake_chance_bp(rarity, morale, situational_bp, facility_mult)) / 10000.0


## The per-rarity profile stamped onto a Raider at generation (docs/04 §4).
static func rarity_mistake_profile(rarity: int) -> Dictionary:
    return {
        "base": float(MISTAKE_BASE_BP.get(rarity, 0)) / 10000.0,
        "floor": float(MISTAKE_FLOOR_BP.get(rarity, 0)) / 10000.0,
        "ceiling": float(MISTAKE_CEIL_BP.get(rarity, 0)) / 10000.0,
        "sensitivity": float(MISTAKE_SENSITIVITY.get(rarity, 1.0)),
    }


# ================================================================ helpers

## docs/08 §8.8's DPS tax: a mistake costs the raider their output for the round.
## The equation for mistake_chance itself is the next task; this is the consumer.
static func effective_output(nominal: float, mistake_chance: float) -> float:
    return nominal * (1.0 - clampf(mistake_chance, 0.0, 1.0))


## Rounds a final value once, half-up, per docs/08 §12.
static func final_value(x: float) -> int:
    return int(round(x))
