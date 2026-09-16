extends RefCounted
## Consumables, and what the Market's shelves carry (docs/11 §7, docs/02 §6.2).
##
## ✅ CANON gives one word: "Potions".
##
## docs/11 §7 explains the shape of everything below, and it is the most important
## constraint in the file: "the player does not control the raid — the sim does, and
## the raiders make mistakes. So an in-combat reactive consumable ('use when the tank
## drops') is unbuildable here: there is no 'when'. Every consumable is therefore
## either a **pre-raid buff** committed before the attempt, or a **safety net** the
## sim spends on the player's behalf under a rule the player can read."
##
## docs/11 §7 is also emphatic about the size of the list: "Same six SKUs at each
## tier, price x 2.4 per tier, effect x ~1.8 per tier. No new SKUs at higher tiers —
## six is the whole list, forever."
##
## Pure and deterministic: no Node, no RNG. Prices and tiers are arithmetic.

const Enums = preload("res://sim/model/Enums.gd")
const Comfort = preload("res://sim/core/Comfort.gd")
const Buildings = preload("res://sim/core/Buildings.gd")

# ============================================================ the six SKUs

## docs/11 §7's table. `kind` is the doc's own column, and it decides where the SKU
## is spent rather than being decoration:
##
##   SAFETY_NET  the sim spends it mid-encounter under a stated rule
##   PRE_RAID    committed at the raid-confirm screen, spent as the attempt begins
##   POST_WIPE   spent in town, on the attempt that just failed
enum Kind { SAFETY_NET, PRE_RAID, POST_WIPE }

## Tier 1 prices and effects, verbatim from docs/11 §7. `effect` is the magnitude the
## tier scaling multiplies; what it MEANS is per-SKU and named in `effect_unit`.
const SKUS := {
    "minor_healing_potion": {
        "name": "Minor Healing Potion", "kind": Kind.SAFETY_NET, "price": 8,
        "effect": 25.0, "effect_unit": "% of max HP restored",
        "rule": "Spent by the sim when a raider drops below 30% HP. One per raider per encounter.",
        "why": "The literal canon Potion. Gold becomes survived mistakes with nothing to micromanage.",
    },
    "potion_of_steady_hands": {
        "name": "Potion of Steady Hands", "kind": Kind.PRE_RAID, "price": 30,
        "effect": 3.0, "effect_unit": "percentage points off mistake chance",
        "target": "one",
        "rule": "One named raider, this attempt only.",
        "why": "Prices the canon Steve decision: bring him and pay, instead of benching him.",
    },
    "whetstone_kit": {
        "name": "Whetstone Kit", "kind": Kind.PRE_RAID, "price": 35,
        "effect": 1.0, "effect_unit": "Power to every melee participant",
        "target": "melee",
        "rule": "Warrior, Monk, Rogue and Bard, this attempt.",
        "why": "A gold-funded pass on a DPS check without touching the canon loot tables.",
    },
    "mana_draught": {
        "name": "Mana Draught", "kind": Kind.PRE_RAID, "price": 35,
        "effect": 10.0, "effect_unit": "Mana to every caster and healer",
        "target": "casters",
        "rule": "Every caster and healer participant, this attempt.",
        "why": "The same valve on the mana axis, and the lever that lets healing checks be tuned.",
    },
    "rally_flask": {
        "name": "Rally Flask", "kind": Kind.POST_WIPE, "price": 40,
        "effect": 0.5, "effect_unit": "x the wipe morale penalty",
        "rule": "Halves the wipe penalty for everyone on the attempt just failed. One per attempt.",
        "why": "Lets gold buy back time: a wipe becomes a bill instead of two Day Ticks of work.",
    },
    "guild_feast": {
        "name": "Guild Feast", "kind": Kind.PRE_RAID, "price": 60,
        "effect": 5.0, "effect_unit": "morale, for the simulation only",
        "target": "all",
        "rule": "The attempt runs at every participant's morale +5. Stored morale is unchanged.",
        "why": "One raid's competence at a premium, priced above Furnishings so comfort stays the efficient fix.",
    },
}

## docs/11 §7: "price x 2.4 per tier, effect x ~1.8 per tier".
const PRICE_PER_TIER := 2.4
const EFFECT_PER_TIER := 1.8

## docs/11 §7: "Stack cap 20 per SKU, per tier variant. Stops the player pre-buying a
## whole tier's insurance at Tier 1 prices."
const STACK_CAP := 20

## docs/03 §7's market column, which is the doc that gates stock by rank. Six rank
## rows, six potion tiers, and docs/11 §7 confirms these names are "placeholders" for
## the same six SKUs at successive tiers.
const TIER_NAMES := ["Minor", "Lesser", "Standard", "Greater", "Major", "Perfect"]

const MAX_TIER := 6


static func sku(id: String) -> Dictionary:
    return SKUS[id] if SKUS.has(id) else {}


## An inventory key. Stock is per SKU AND per tier, because docs/11 §7's stack cap is
## "20 per SKU, per tier variant" — a Minor and a Greater potion are different goods.
static func stock_key(sku_id: String, tier: int) -> String:
    return "%s@%d" % [sku_id, clampi(tier, 1, MAX_TIER)]


static func sku_of_key(key: String) -> String:
    return key.get_slice("@", 0)


static func tier_of_key(key: String) -> int:
    var parts := key.split("@")
    return int(parts[1]) if parts.size() > 1 else 1





## docs/11 §7's tier scaling. Tier 1 is the printed price; each tier above multiplies
## by 2.4 and rounds to something a shopkeeper would say.
static func price_at(id: String, tier: int) -> int:
    var s := sku(id)
    if s.is_empty():
        return 0
    var t := clampi(tier, 1, MAX_TIER)
    var raw := float(s["price"]) * pow(PRICE_PER_TIER, float(t - 1))
    return _round_price(raw)


## Prices land on a 5 for anything above a handful, which is what docs/11 §5's own
## `round_to_5` does for gear — the same shopkeeper rounds both.
static func _round_price(raw: float) -> int:
    if raw < 10.0:
        return maxi(1, int(round(raw)))
    return int(round(raw / 5.0)) * 5


static func effect_at(id: String, tier: int) -> float:
    var s := sku(id)
    if s.is_empty():
        return 0.0
    var t := clampi(tier, 1, MAX_TIER)
    return float(s["effect"]) * pow(EFFECT_PER_TIER, float(t - 1))


## The display name at a tier: docs/03 §7's placeholder adjective in front of the SKU
## line, so "Minor Healing Potion" becomes "Greater Healing Potion" at tier 4 without
## a second table.
static func display_name(id: String, tier: int) -> String:
    var s := sku(id)
    if s.is_empty():
        return ""
    var t := clampi(tier, 1, MAX_TIER)
    var base := String(s["name"])
    var first := TIER_NAMES[0]
    if base.begins_with(first + " "):
        return "%s %s" % [TIER_NAMES[t - 1], base.substr(first.length() + 1)]
    if t == 1:
        return base
    return "%s (%s)" % [base, TIER_NAMES[t - 1]]


static func kind_of(id: String) -> int:
    var s := sku(id)
    return int(s.get("kind", Kind.PRE_RAID)) if not s.is_empty() else Kind.PRE_RAID


# ============================================================ the loadout

## docs/11 §7's melee list, verbatim: the Whetstone Kit gives "+1 Power to every melee
## participant (Warrior, Monk, Rogue, Bard)". Named rather than derived from role
## group, because the Bard is a support class the doc still counts as melee.
const MELEE_CLASSES := [
    Enums.CharClass.WARRIOR, Enums.CharClass.MONK, Enums.CharClass.ROGUE,
    Enums.CharClass.BARD,
]

## docs/11 §7's Minor Healing Potion trigger: "Auto-spent by the sim when a
## participant drops below 30% HP".
const POTION_TRIGGER_FRACTION := 0.30

## docs/11 §7: "One per raider per encounter maximum."
const POTIONS_PER_RAIDER := 1


static func is_melee_class(class_id: int) -> bool:
    return MELEE_CLASSES.has(class_id)


## What the sim receives: flat, pre-resolved numbers rather than a shopping list, so
## `RaidSim` never re-derives a price or a rule mid-encounter.
##
## An EMPTY loadout must leave the simulation byte-identical — every golden file in the
## project depends on that, and a test asserts it directly.
static func new_loadout() -> Dictionary:
    return {
        "power_bonus": 0,          ## Whetstone Kit, melee participants only
        "mana_bonus": 0,           ## Mana Draught, casters and healers only
        "morale_bonus": 0,         ## Guild Feast, the simulation only
        "mistake_relief_bp": {},   ## Steady Hands, raider id -> basis points
        "potion_count": 0,         ## healing potions the sim may spend
        "potion_heal_pct": 0.0,    ## each restores this % of max HP
    }


static func loadout_is_empty(loadout: Dictionary) -> bool:
    var relief: Dictionary = loadout.get("mistake_relief_bp", {})
    return int(loadout.get("power_bonus", 0)) == 0 \
        and int(loadout.get("mana_bonus", 0)) == 0 \
        and int(loadout.get("morale_bonus", 0)) == 0 \
        and relief.is_empty() \
        and int(loadout.get("potion_count", 0)) == 0


## Fold one bought consumable into the loadout. Returns "" when it was taken, or the
## reason it was not — so the raid-confirm screen can say why a second one does
## nothing rather than quietly swallowing it.
##
## docs/11 §7 phrases every group SKU as a flat effect on "this attempt" ("+1 Power to
## every melee participant this attempt"), never as a stack, and the Rally Flask says
## "One per attempt" outright. So a group buff is ONCE PER ATTEMPT and the second is
## refused rather than doubled — docs/15 BL-46.
static func fold_into_loadout(loadout: Dictionary, sku_id: String, tier: int,
        target_id: String = "", party_size: int = 0) -> String:
    var s := sku(sku_id)
    if s.is_empty():
        return "No such consumable."
    var magnitude := effect_at(sku_id, tier)

    match sku_id:
        "whetstone_kit":
            if int(loadout["power_bonus"]) > 0:
                return "The party is already sharpened. A second kit adds nothing."
            loadout["power_bonus"] = int(round(magnitude))
        "mana_draught":
            if int(loadout["mana_bonus"]) > 0:
                return "Everyone has already drunk one."
            loadout["mana_bonus"] = int(round(magnitude))
        "guild_feast":
            if int(loadout["morale_bonus"]) > 0:
                return "One feast is a feast. Two is a problem."
            loadout["morale_bonus"] = int(round(magnitude))
        "potion_of_steady_hands":
            if target_id.is_empty():
                return "That one is for a named raider."
            var relief: Dictionary = loadout["mistake_relief_bp"]
            if relief.has(target_id):
                return "They have already had one."
            # docs/11 §7 quotes the effect in PERCENTAGE POINTS; the formulas work in
            # basis points, so one point is 100.
            relief[target_id] = magnitude * 100.0
        "minor_healing_potion":
            var cap := party_size * POTIONS_PER_RAIDER
            if party_size > 0 and int(loadout["potion_count"]) >= cap:
                return "One per raider is all the party can carry."
            loadout["potion_count"] = int(loadout["potion_count"]) + 1
            loadout["potion_heal_pct"] = magnitude
        "rally_flask":
            # docs/11 §7 files this one as "Post-wipe, town", not pre-raid: it acts on
            # "the attempt just failed", which has not happened yet. `GameState` spends
            # it from the Results screen.
            return "A Rally Flask is drunk after a wipe, not before one."
        _:
            return "That one is not spent on a raid."
    return ""


## docs/11 §7's Rally Flask: "Halves the wipe morale penalty for all participants of
## the attempt just failed (rounds toward zero)."
##
## The effect column reads "0.5 x the wipe morale penalty", and §7's tier rule is
## "effect x ~1.8 per tier". Those two only agree if the scaled quantity is the
## RELIEF, not the surviving multiplier — scaling the multiplier would make a
## higher-grade flask relieve LESS (0.5 -> 0.9 of the penalty kept), which is the
## opposite of what a tier means for every other SKU in the table. So 0.5 is the
## fraction given BACK, and a grade-3 flask refunds the wipe entirely.
static func wipe_refund_at(tier: int) -> float:
    return clampf(effect_at("rally_flask", tier), 0.0, 1.0)


## The fraction of the wipe penalty the raider is left carrying.
static func wipe_relief_at(tier: int) -> float:
    return clampf(1.0 - wipe_refund_at(tier), 0.0, 1.0)


# ============================================================ the shelves

## The stall level the guild has BOUGHT. docs/02 §11 prices the Market's rungs at
## 130 / 450 / 1,100 G behind rank gates, which BL-44 missed by reading §6.2 alone —
## that section has no cost column, but §11 does. docs/15 BL-54 records the correction.
##
## Kept as a function taking the level so every caller reads the same clamp.
static func stall_level(market_tier: int) -> int:
    return clampi(market_tier, 1, 4)


## The highest stall level this rank is ALLOWED to have bought, which is what a screen
## uses to explain why a rung is shut.
static func stall_level_cap(rank: int) -> int:
    var cap := 1
    for rung in Buildings.ladder("market"):
        if rank >= int(rung["rank"]):
            cap = int(rung["level"])
    return cap


## docs/02 §6.2's "Visible change" column, which is the art contract for the stall.
## Text until the art exists, exactly as the Guildhall's rungs are.
static func stall_look(level: int) -> String:
    match clampi(level, 1, 4):
        1:
            return "One trestle table, one vendor, canvas awning"
        2:
            return "Second stall, crates, two shoppers"
        3:
            return "Permanent stone stall, hanging goods, four shoppers"
        _:
            return "Covered market row, banners, six shoppers, night lanterns"


## docs/02 §6.2's "Stock rows" column — how many lines the stall shows at once.
static func stock_rows(level: int) -> int:
    return [5, 7, 9, 12][clampi(level, 1, 4) - 1]


## The highest potion tier this stall carries. docs/02 §6.2 gates by stall level,
## docs/03 §7 by rank, and six tiers over six ranks is the finer of the two — so the
## tier is the rank's own rung and the stall level only gates comfort items.
static func top_potion_tier(rank: int) -> int:
    return clampi(rank + 1, 1, MAX_TIER)


## docs/02 §6.2's comfort-item column: L1 Straw Cot, L2 adds the Hot Meal Standing
## Order, L3 adds the Feather Bed and Trophy Shelf, L4 adds Personal Effects.
static func comfort_stock_level(furnishing_id: String) -> int:
    match furnishing_id:
        "straw_cot":
            return 1
        "hot_meal", "hot_meal_all":
            return 2
        "feather_bed", "trophy_shelf":
            return 3
        "personal_effect":
            return 4
        _:
            return 1


## Why the stall does not carry something yet, or "" when it does. The reason names
## the rank rather than the stall level, because the rank is the thing the player can
## act on.
static func stock_blocker(furnishing_id: String, level: int) -> String:
    var needed := comfort_stock_level(furnishing_id)
    if level >= needed:
        return ""
    var f := Comfort.furnishing(furnishing_id)
    var what := String(f["name"]) if not f.is_empty() else furnishing_id
    return "A %s stall does not carry the %s yet." % [
        stall_look(level).get_slice(",", 0).to_lower(), what]


## Everything the stall carries at this level, in the order docs/02 §6.2 introduces it.
static func comfort_catalogue(market_tier: int) -> Array:
    var level := stall_level(market_tier)
    var out: Array = []
    for id in ["straw_cot", "hot_meal", "hot_meal_all", "feather_bed",
            "trophy_shelf", "personal_effect"]:
        if comfort_stock_level(String(id)) <= level:
            out.append(id)
    return out
