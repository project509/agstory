class_name TwgTierScaling
extends RefCounted
## The rung ladder: how one tier's numbers become the next tier's numbers.
##
## docs/09 §13 is the specification. This file owns the ARITHMETIC of that
## section — the growth multipliers, the slot-share split, the Power rule, the
## weapon ladder, and the override table that lets canon beat all of them. It
## owns nothing about files: `tools/gen_items.gd` reads the shipped Tier 1 JSON,
## feeds the canon totals in here, and writes what comes out.
##
## It also owns the derivation behind docs/08 §9.6 — the Tier 2-5 boss budget —
## because that budget is not a second set of numbers, it is §9.1/§9.2/§9.3's
## method run against the gear this file generates. `budget_row()` reproduces
## docs/08 §9.2/§9.3/§9.5's published Tier 1 figures exactly (2200/2500/3200/
## 4100/7150 and 61/63/65/68/73), and `tests/unit/test_tier_scaling.gd` pins
## that: a derivation that cannot re-derive Tier 1 is not the same method.
##
## PURE (house rule 6). No clock, no scene tree, no randomness, no file access.
##
## Two canon ambiguities are isolated here, each behind ONE named switch, in the
## shape `sim/core/Formulas.gd` already uses for `AC_READING`:
##
##   CURVE        — docs/09 §13.2 and docs/08 §10.2 publish DIFFERENT growth
##                  curves for the same ten rungs. Default is docs/09's,
##                  because docs/09 owns the item tables and docs/16 §8.1 E3.5
##                  restates its multipliers as the entry criterion.
##   ADV_OFFHANDS — docs/09 §13.1 budgets an Adventure rung at 27 rows
##                  including three off-hands; the shipped Tier 1 Adventure file
##                  has 28 rows and no off-hand at all. Default reproduces the
##                  shipped file.
##
## Neither has a `docs/15` row: the write-up was lost with the plan file that held
## it. ADV_OFFHANDS is the same canon gap the register already carries as the
## Adventure off-hand question; SHARE_CURVE is docs/09 §13.1 against docs/16 §8.1
## E3.5 and is doc 09's to settle. Both stay switched with both readings tested
## (`tests/unit/test_tier_scaling.gd`), and neither ships until the tiers are
## named (docs/15 BL-69), which is what makes holding them safe.

const Formulas = preload("res://sim/core/Formulas.gd")

# ================================================================ the ladder

## Ten rungs, r1..r10: r1 = T1 Adventure, r2 = T1 Raid, r3 = T2 Adventure, …
## r10 = T5 Raid (docs/09 §13.1). Starting gear is r0 and is not on the ladder.
const RUNGS := 10

## Rung index of one rung of one tier. `raid` false is the Adventure rung.
static func rung_of(tier: int, raid: bool) -> int:
    return 2 * tier - (0 if raid else 1)

static func tier_of_rung(rung: int) -> int:
    return (rung + 1) / 2

static func rung_is_raid(rung: int) -> bool:
    return rung % 2 == 0


# ================================================================ growth

## docs/09 §13.2's growth table, and the reason it is not docs/08 §10.2's.
##
## §13.2 alternates a big WITHIN-tier step (Adventure → Raid) with a small
## CROSS-tier one (Raid → next Adventure); its within-tier column is fitted to
## canon (docs/09 §13.3 lands eight of twelve family totals exactly). docs/08
## §10.2 instead publishes one uniform ×1.50 AC / ×1.55 HP per HALF-tier, which
## is ×2.25 per tier against §13.2's ×1.595 and reaches Warrior AC 541 at r10
## against §13.2's 132. They cannot both be the item table.
##
## Default DOC09_FITTED: docs/09 owns the item tables (docs/08 §1's own
## ownership table says so) and docs/16 §8.1 E3.5 names these exact numbers as
## the entry criterion for this work. DOC08_UNIFORM stays selectable because
## docs/08 §1 also claims "the per-tier scaling multipliers", and because it is
## the only one of the two under which a tier N+1 Adventure piece is a strict
## upgrade on every stat over a tier N Raid piece (see `test_tier_scaling.gd`).
enum ScalingCurve { DOC09_FITTED, DOC08_UNIFORM }

const CURVE := ScalingCurve.DOC09_FITTED

## docs/09 §13.2, within tier (Adventure → Raid). Cloth takes ×1.60 on AC; the
## audit in §13.3 needs that to reproduce Mage/Wizard 8 → 13 exactly.
const WITHIN := {"ac": 1.45, "ac_cloth": 1.60, "hp": 1.55, "mana": 2.05}

## docs/09 §13.2, across tiers (Raid → next Adventure). The single knob that
## sets total campaign length, and §13.2 says so.
const CROSS := {"ac": 1.10, "hp": 1.10, "mana": 1.15, "weapon": 1.25}

## docs/08 §10.2's alternative: one step per half-tier, Mana ×2.00 once from
## index 1 → 2 and ×1.55 after (that is docs/08 §13 Q8's default made explicit).
const UNIFORM := {"ac": 1.50, "hp": 1.55, "mana": 1.55, "mana_first": 2.00, "weapon": 1.55}

## Families whose AC takes the cloth step. docs/09 §13.3's audit reproduces
## Mage/Wizard's canon 13 only with ×1.60; the healer line reproduces with the
## ordinary ×1.45 (9 × 1.45 = 13.05), so the healer is NOT cloth for this rule.
const CLOTH_FAMILIES := ["mage_wizard"]

## docs/09 §13.4: "Power appears only from the Raid rung of each tier ✅ CANON",
## and only on the physical families.
const PHYSICAL_FAMILIES := ["warrior_bard", "monk", "rogue"]

## The multiplier one stat takes on one step of the ladder.
static func step_multiplier(stat: String, to_raid: bool, cloth: bool,
        rung_from: int = 1) -> float:
    if CURVE == ScalingCurve.DOC08_UNIFORM:
        if stat == "mana":
            return float(UNIFORM["mana_first"]) if rung_from == 2 else float(UNIFORM["mana"])
        return float(UNIFORM.get(stat, 1.0))
    if to_raid:
        if stat == "ac" and cloth:
            return float(WITHIN["ac_cloth"])
        return float(WITHIN.get(stat, 1.0))
    return float(CROSS.get(stat, 1.0))


## docs/08 §12: round once, half-up. `round()` in GDScript is half-away-from-
## zero, which is half-up for the non-negative stats this ladder produces.
static func round_half_up(v: float) -> int:
    return int(round(v))


## One family's {ac, hp, mana} totals, one rung further up the ladder.
## `power` is not carried forward: docs/09 §13.4 derives it from AC at every
## Raid rung and zeroes it at every Adventure rung, so carrying it would
## double-count.
static func next_totals(prev: Dictionary, to_raid: bool, cloth: bool,
        rung_from: int = 1) -> Dictionary:
    var out := {}
    for stat in ["ac", "hp", "mana"]:
        var m := step_multiplier(stat, to_raid, cloth, rung_from)
        out[stat] = round_half_up(float(prev.get(stat, 0)) * m)
    return out


# ================================================================ slot split

## docs/09 §13.4's per-family share table, derived there from canon r1/r2.
const SHARES := {
    "warrior_bard": {"head": 0.22, "chest": 0.33, "legs": 0.25, "feet": 0.20},
    "monk":         {"head": 0.27, "chest": 0.29, "legs": 0.23, "feet": 0.21},
    "rogue":        {"head": 0.22, "chest": 0.31, "legs": 0.25, "feet": 0.22},
    "healer":       {"head": 0.23, "chest": 0.32, "legs": 0.23, "feet": 0.22},
    "mage_wizard":  {"head": 0.25, "chest": 0.28, "legs": 0.25, "feet": 0.22},
}

const ARMOUR_SLOTS := ["head", "chest", "legs", "feet"]

## Power's own split. docs/09 §13.4 gives Power a family TOTAL and no share
## table, and canon's Tier 1 Raid Warrior/Bard spends its 4 as head 1 / chest 2
## / legs 1 / feet 0 — chest double, feet nothing. That is the shape here.
const POWER_SHARES := {"head": 0.25, "chest": 0.50, "legs": 0.25, "feet": 0.0}

## docs/09 §13.4's rounding rule, verbatim: "floor every slot, then hand the
## remainder to Chest until the family total is exact." Chest is the heaviest
## slot in canon in four of five families, so it absorbs drift least visibly.
static func split_slots(total: int, shares: Dictionary) -> Dictionary:
    var out := {}
    var floored := 0
    for slot in ARMOUR_SLOTS:
        var v := int(floor(float(shares.get(slot, 0.0)) * float(total)))
        out[slot] = v
        floored += v
    out["chest"] = int(out["chest"]) + (total - floored)
    return out


## docs/09 §13.4: Power = `round(AC_total × 0.20)` for the physical families,
## 0 for Healer / Mage / Wizard, and only from the Raid rung of each tier.
## THE LADDER MUST NOT INVERT AT THE SLOT LEVEL, and a total that rises does not
## guarantee that (docs/15 BL-70). §13.2 steps the family TOTAL and §13.4 re-splits
## it across four slots by share, so a share plus a rounding rule can hand Chest a
## remainder and leave Legs flat — or lower — while the total rises. Measured on
## the first generated rung: warrior_bard legs went 5 AC / 6 HP at the Tier 1 raid
## rung to 5 / 6 at the Tier 2 Adventure rung (flat), and monk_rogue legs went
## 5 / 6 to 5 / 5 (a DOWNGRADE the player would feel as a broken loot loop).
##
## So the split is floored against the rung below, per slot and per stat, and if
## nothing rose at all the slot is given one point of the stat its share is
## largest in. Deterministic, tiny, and it only ever adds: a floor cannot make a
## piece worse, and the totals it nudges stay inside their own rung's step.
static func floor_against_previous(prev_slot: Dictionary, here_slot: Dictionary,
        shares: Dictionary, slot: String) -> Dictionary:
    var out := here_slot.duplicate()
    var rose := false
    for stat in prev_slot.keys():
        var before := int(prev_slot.get(stat, 0))
        var now := int(out.get(stat, 0))
        if now < before:
            out[stat] = before
            now = before
        if now > before:
            rose = true
    if not rose and not prev_slot.is_empty():
        # Nothing moved: add a point where this slot carries the most weight, so
        # the nudge lands on the stat the slot is supposed to be about.
        var best_stat := ""
        var best := -1.0
        for stat in prev_slot.keys():
            if int(prev_slot.get(stat, 0)) <= 0:
                continue
            var weight := float(shares.get(slot, 0.0))
            if weight > best or best_stat.is_empty():
                best = weight
                best_stat = String(stat)
        if not best_stat.is_empty():
            out[best_stat] = int(out.get(best_stat, 0)) + 1
    return out


const POWER_FROM_AC := 0.20

static func power_total(family: String, ac_total: int, raid_rung: bool) -> int:
    if not raid_rung or not (family in PHYSICAL_FAMILIES):
        return 0
    return round_half_up(float(ac_total) * POWER_FROM_AC)


# ================================================================ overrides

## docs/09 §13.3: "The generator needs an override column: `overrides.csv` keyed
## by `(family, rung, stat)` carrying a signed delta. Canon values are entered
## as overrides at r1/r2 and win over the formula, always. The generator never
## edits canon."
##
## The r1/r2 half of that is not a table here: `tools/gen_items.gd` READS
## `data/items_t1_adventure.json` and `data/items_t1_raid.json` and seeds the
## ladder from them, so canon wins by construction and cannot be transcribed
## wrong. What is left is the deltas above r2, and the eight §13.3 measured at
## r2 stay listed as the record of what the formula misses — they document the
## fit, and they are applied nowhere because r2 is read from canon.
##
## Key is `"<family>|<rung>|<stat>"`. Value is a signed integer delta applied
## AFTER the multiplier and BEFORE the slot split.
const OVERRIDES := {
    # docs/09 §13.3's measured misses at r2 (Tier 1 Raid). Recorded, not
    # applied: r2 is seeded from the canon file, which already holds the truth.
    # "warrior_bard|2|ac": -1, "warrior_bard|2|hp": -1, "rogue|2|hp": -1,
    # "healer|2|mana": 0, "mage_wizard|2|mana": -1,
}

static func override_delta(family: String, rung: int, stat: String) -> int:
    return int(OVERRIDES.get("%s|%d|%s" % [family, rung, stat], 0))


## Totals for one rung of one family: multiply, then let canon win.
static func totals_for(family: String, prev: Dictionary, rung: int) -> Dictionary:
    var to_raid := rung_is_raid(rung)
    var cloth: bool = family in CLOTH_FAMILIES
    var out := next_totals(prev, to_raid, cloth, rung - 1)
    for stat in ["ac", "hp", "mana"]:
        out[stat] = maxi(0, int(out[stat]) + override_delta(family, rung, stat))
    out["power"] = power_total(family, int(out["ac"]), to_raid)
    return out


# ================================================================ weapons

## docs/09 §13.2's weapon column, verbatim: "Basic = Adv +1 (+2 for Wizard);
## Strong = Basic +2 (1H) / +4 (2H); Capstone = Strong +4", and ×1.25 across
## tiers. Every one of those reproduces canon at Tier 1 — sword 5 → 6 → 8,
## Monk staff 9 → 10 → 14, Mage 10 → 11 → 15 → 19, Wizard 10 → 12 → 16 → 20.
const WEAPON_BASIC_STEP := 1
const WEAPON_BASIC_STEP_WIZARD := 2
const WEAPON_STRONG_STEP_1H := 2
const WEAPON_STRONG_STEP_2H := 4
const WEAPON_CAPSTONE_STEP := 4

## The Rogue's dagger against the shared sword. ✅ CANON ships Basic Raid Dagger
## at +4 against a +5 Adventure sword and Strong at +6 against +8 — a step DOWN
## that docs/09 OQ-15 flags and rules on in terms: "Treat the canon numbers as
## canon and do not silently fix them." So the gap is carried forward as a
## constant rather than smoothed away at Tier 2.
const DAGGER_OFFSET := -2

static func weapon_basic(adventure_damage: int, wizard: bool = false) -> int:
    return adventure_damage + (WEAPON_BASIC_STEP_WIZARD if wizard else WEAPON_BASIC_STEP)

static func weapon_strong(basic_damage: int, two_handed: bool) -> int:
    return basic_damage + (WEAPON_STRONG_STEP_2H if two_handed else WEAPON_STRONG_STEP_1H)

static func weapon_capstone(strong_damage: int) -> int:
    return strong_damage + WEAPON_CAPSTONE_STEP

## docs/09 §13.2's cross-tier weapon step, applied to the rung's terminal
## (Strong) weapon, because that is the weapon the player carries into the next
## tier's Adventure rung.
static func weapon_next_tier(strong_damage: int) -> int:
    return round_half_up(float(strong_damage) * float(CROSS["weapon"]))


# ================================================================ the budget

## docs/08 §9.2's own sentence: "Boss HP = DPS at attempt × target fight length,
## rounded to the nearest 50", where DPS at attempt is §9.1's raid total for the
## PREVIOUS stage — the boss is fought in the gear the boss before it dropped.
const HP_ROUNDING := 50

## docs/08 §9.2's target fight lengths, held flat across tiers. Changing them is
## a designer call, not a generator one: they set the wall-clock pacing docs/10
## §7 checks (12+13+15+17+22 rounds x 4 s = 316 s per clear).
const TARGET_ROUNDS := [12, 13, 15, 17, 22]

## docs/08 §9.3's 3-round death clock, and §9.5's AoE bite. Both are §11 tuning
## levers with published safe ranges (2.5-5.0 and 0.20-0.45).
const TANK_DEATH_CLOCK := 3.5
const AOE_BITE_FRACTION := 0.35

static func boss_hp(dps_at_attempt: float, target_rounds: int) -> int:
    var raw := dps_at_attempt * float(target_rounds)
    return int(round(raw / float(HP_ROUNDING))) * HP_ROUNDING

## docs/08 §9.3's invariant, not a hand-set number:
##   boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK * (1 - mitigation(tank_ac)))
static func boss_auto_raw(tank_max_hp: int, tank_ac: int) -> int:
    var mit := Formulas.mitigation(tank_ac)
    return round_half_up(float(tank_max_hp) / (TANK_DEATH_CLOCK * (1.0 - mit)))

## The unhealed clock a given swing actually buys, which is what a test asserts
## against TANK_DEATH_CLOCK. Inverse of `boss_auto_raw`, measured not assumed.
static func unhealed_clock(tank_max_hp: int, tank_ac: int, raw_per_round: int) -> float:
    var taken := float(raw_per_round) * (1.0 - Formulas.mitigation(tank_ac))
    if taken <= 0.0:
        return INF
    return float(tank_max_hp) / taken

## docs/08 §9.5. Two readings, and docs/10 §5.4 picked one: raid-wide damage
## ignores AC so the pressure lands on healer throughput rather than on the
## tank's gear score, which makes `AOE_BITE_FRACTION x cloth_max_hp` the raw
## value directly. That is the number every M02 in the shipped Tier 1 data uses
## (26 at Raid 1 entry, 28 fully geared), so it is what encounters get.
static func aoe_pulse(cloth_max_hp: int) -> int:
    return round_half_up(AOE_BITE_FRACTION * float(cloth_max_hp))

## §9.5's own printed column, which grosses the bite up through cloth armour.
## Kept because it is the figure docs/10 §5.4 says to use if the designer ever
## rules that AC DOES apply to raid-wide damage.
static func aoe_pulse_gross(cloth_max_hp: int, cloth_ac: int) -> int:
    return round_half_up(AOE_BITE_FRACTION * float(cloth_max_hp)
        / (1.0 - Formulas.mitigation(cloth_ac)))


# ================================================================ adventures

## docs/10 §8, as corrected in its own notes: each Adventure rung is sized for
## the gear the rung BEFORE it dropped, and Adventure tier N is played in tier
## N-1's gear. Three rungs, target rounds 8 / 10 / 12, and the unhealed tank
## clock loosens as the star rating drops.
const ADVENTURE_TARGET_ROUNDS := [8, 10, 12]

## docs/10 §8's "intended clocks" table: A1 5.5 rounds, A2 4.3, A3 3.5. Only A3
## sits on §9.3's raid clock; the two trash rungs are deliberately slacker.
const ADVENTURE_CLOCKS := [5.5, 4.3, 3.5]

const ADVENTURE_PARTY_SIZE := 6
const ADVENTURE_HEALERS := 1

## docs/15 BL-29's correction, as a rule rather than a hand-tune: raid-wide
## damage is held constant PER HEALER, not per raider. docs/08 §9.5 sizes M02
## for a 12-raid with three healers; a party of six with one healer carries the
## same pulse 1.5x harder. Reproduces Tier 1's 15 by construction from §9.5's 23.
static func adventure_aoe_pulse(cloth_max_hp: int, party_size: int = ADVENTURE_PARTY_SIZE,
        healers: int = ADVENTURE_HEALERS) -> int:
    var full := AOE_BITE_FRACTION * float(cloth_max_hp)
    return round_half_up(full * (float(healers) / 3.0) * (12.0 / float(party_size)))

## docs/10 §8 knock-on 1: "M04 add HP scales with the pull." At A1 the add was
## 8-9% of the fight and at A2 8%; left at a fixed HP against a re-derived pull
## it changed the encounter's shape rather than its size.
const ADVENTURE_ADD_HP_FRACTION := [0.09, 0.08]

static func adventure_add_hp(pull_total_hp: int, rung_index: int) -> int:
    if rung_index < 0 or rung_index >= ADVENTURE_ADD_HP_FRACTION.size():
        return 0
    return maxi(1, round_half_up(float(pull_total_hp)
        * float(ADVENTURE_ADD_HP_FRACTION[rung_index])))

## The Adventure rung's swing, from docs/08 §9.3's formula at the rung's OWN
## clock and the rung's OWN gear stage. Sizing all three rungs at one stage is
## the mistake docs/10 §8 made twice and warns about in writing.
static func adventure_raw_per_round(tank_max_hp: int, tank_ac: int, rung_index: int) -> int:
    var clock: float = ADVENTURE_CLOCKS[clampi(rung_index, 0, ADVENTURE_CLOCKS.size() - 1)]
    var mit := Formulas.mitigation(tank_ac)
    return round_half_up(float(tank_max_hp) / (clock * (1.0 - mit)))


# ================================================================ authoring

## docs/10 §5.2 / §10 M06.
static func enrage_for(target_rounds: int) -> int:
    return int(ceil(1.4 * float(target_rounds)))

## docs/10 §5.4: "E1 and E2 are one-swing bosses … splitting the swing from E3
## onward is the lever that keeps a retarget survivable." Held for every tier
## until a tier deliberately breaks it.
static func swings_per_round(slot_index: int) -> int:
    return 1 if slot_index < 2 else 2

## docs/10 §10's tier escalation rule: "A tier introduces at most TWO mechanics
## the player has not seen. Tier 1 uses M01-M06, M08, M09. Tiers 2-5 add M07,
## M10, M11, M12 and then recombine."
const MAX_NEW_MECHANICS_PER_TIER := 2

const TIER1_MECHANICS := ["m01", "m02", "m03", "m04", "m05", "m06", "m08", "m09"]
