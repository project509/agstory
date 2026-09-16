extends RefCounted
## Comfort: the Guildhall facility track, Furnishings and Indulgences.
##
## ✅ CANON gives this system two lines and no numbers: "Manage morale with comfort
## items" and "Upgrade guild facilities < better morale values" (raw notes,
## Guildhall).
##
## THREE DOCS READ THAT FIRST LINE THREE WAYS, and docs/11 §8.1 is the one that
## resolves it, so this file follows docs/11:
##
##   docs/02 §4.2  a comfort item is a DURABLE PLACED object that raises the
##                 raider's comfort floor. Not consumed.
##   docs/05 §7.4  a comfort item is an EVENT worth +8, one per raider per 2 Day
##                 Ticks.
##   docs/11 §8.1  "Both are useful, and an economy needs the recurring one.
##                 Proposal: they are two product lines."
##
## So there are two: **Furnishings** are docs/02's durable placed floor, and
## **Indulgences** are docs/05's consumable +8 spike. Neither doc is contradicted,
## and the split is what makes the economy work — a large one-off sink and a small
## recurring emergency lever. docs/15 BL-38 records the ruling.
##
## Pure and deterministic: no Node, no RNG. Prices and floors are arithmetic.

const Enums = preload("res://sim/model/Enums.gd")
const Buildings = preload("res://sim/core/Buildings.gd")

# ============================================================ facility track

## docs/02 §4.3's levels and slot counts, with docs/11 §8.4's prices.
##
## ⚠️ THE INDEXING TRAP, in docs/02 §4.3's own words: "Guildhall L1-L4 here map to
## facility tiers 0-3 in that order, which is why the derelict starting hall
## contributes +0." So `facility_tier` in code is `level - 1`, and every function
## here takes the TIER, never the level.
##
## `bonus` is deliberately absent from this table. docs/02 §4.3 is explicit that the
## morale column "is **not** a floor value invented here — it is doc 05 §7.5's
## `facility_bonus` ... If doc 05 retunes the bonuses, this column follows it, not
## the reverse." So the number comes from `Morale.facility_bonus_for()` and lives in
## exactly one place. See docs/15 BL-39: docs/11 §8.4 printed its own floor column
## (45/50/55/60) that disagrees, and docs/05 wins.
const LEVELS := [
    {"level": 1, "name": "Leaking Guildhall", "slots": 1, "cost": 0,
     "look": "Boarded windows, sagging roof, one lantern"},
    {"level": 2, "name": "Repaired Guildhall", "slots": 2, "cost": 150,
     "look": "Roof patched, door replaced, 3 lit windows"},
    {"level": 3, "name": "Proper Guildhall", "slots": 3, "cost": 500,
     "look": "Second storey, guild banner, brazier at door"},
    {"level": 4, "name": "Renowned Guildhall", "slots": 4, "cost": 1400,
     "look": "Stone façade, stained glass, two standing guards"},
]

const MAX_TIER := 3


static func level_at(facility_tier: int) -> Dictionary:
    return LEVELS[clampi(facility_tier, 0, MAX_TIER)]


static func level_name(facility_tier: int) -> String:
    return String(level_at(facility_tier)["name"])


## docs/02 §4.3's comfort slots per raider, which is what gates how many
## Furnishings one raider can hold.
static func slots_for(facility_tier: int) -> int:
    return int(level_at(facility_tier)["slots"])


## Gold for the NEXT tier, or -1 when the Guildhall is finished. docs/02 §11 owns the
## price, via `Buildings`, so the one table that has all four buildings in it is the one
## that gets consulted — see docs/15 BL-54.
static func upgrade_cost(facility_tier: int) -> int:
    return Buildings.upgrade_cost("guildhall", facility_tier + 1)


## docs/03 §7's town column gates the rungs by rank: "Guildhall facility upgrade I"
## at Known, "II" at Established, "III" at Renowned. docs/11 §8.4: "a level is
## buyable only when both its rank gate and its price are met."
##
## docs/03 §7 also lists a "facility upgrade IV" at Legendary, and docs/02 §4.3 has
## only three purchasable rungs above the starting hall — an off-by-one between the
## two docs, resolved in docs/15 BL-41 by mapping the rungs in the order they appear
## and letting Legendary add nothing, which docs/03 §6.4 already expects of it
## ("Legendary rank cannot gate content").
static func upgrade_rank(facility_tier: int) -> int:
    return Buildings.upgrade_rank("guildhall", facility_tier + 1)


## Which of the two gates is blocking, or "" when the upgrade is buyable. docs/11
## §8.4 requires the screen to say which, and docs/13 §7 forbids a disabled control
## that is a mystery — so the reason is computed here rather than in the UI.
static func upgrade_blocker(facility_tier: int, gold: int, rank: int) -> String:
    if facility_tier >= MAX_TIER:
        return "The Guildhall is as good as it gets."
    var needed_rank := upgrade_rank(facility_tier)
    if rank < needed_rank:
        return "%s guilds cannot commission this. Reach %s." % [
            Enums.reputation_name_of(rank), Enums.reputation_name_of(needed_rank)]
    var cost := upgrade_cost(facility_tier)
    if gold < cost:
        return "Costs %d G — you have %d." % [cost, gold]
    return ""


# ============================================================ Furnishings

## docs/02 §4.2's list with docs/11 §8.2's prices. Floors are docs/02's, prices are
## docs/11's, and neither is invented here.
##
## `slot` is the quarters slot a Furnishing occupies. docs/02 says the Feather Bed
## "replaces Straw Cot in same slot", which is the only slot grouping either doc
## states — so bedding is one slot and everything else stands alone. One Furnishing
## per slot, and the number of slots is the Guildhall's (§4.3).
const FURNISHINGS := {
    "straw_cot": {
        "name": "Straw Cot", "floor": 3, "price": 40, "slot": "bedding",
        "blurb": "Straw, mostly. It is better than the floor.",
    },
    "feather_bed": {
        "name": "Feather Bed", "floor": 6, "price": 140, "slot": "bedding",
        "blurb": "Replaces the cot. Nobody has asked what the feathers are from.",
    },
    "hot_meal": {
        "name": "Hot Meal Standing Order", "floor": 5, "price": 90, "slot": "board",
        "blurb": "One hot meal a day, arranged with the Market.",
    },
    "trophy_shelf": {
        "name": "Trophy Shelf", "floor": 4, "price": 110, "slot": "trophy",
        "present_bonus": 2,
        "blurb": "A shelf for the head of something. Worth more if they helped.",
    },
    "personal_effect": {
        "name": "Personal Effect", "floor": 8, "price": 260, "slot": "personal",
        "requires_backstory": true,
        "blurb": "Something from before the guild. Only means anything to them.",
    },
}

## docs/02 §4.2's "Hot Meal Standing Order — guild-wide variant costs 4×", priced by
## docs/11 §8.2 at 360 G. Bought once, it feeds the whole roster, and it takes the
## same `board` slot in every raider's quarters — so it is not stackable with the
## per-raider order, which is what "variant" means.
const GUILD_FURNISHINGS := {
    "hot_meal_all": {
        "name": "Hot Meal Standing Order (guild-wide)", "floor": 5, "price": 360,
        "slot": "board",
        "blurb": "The whole guild eats. The Market delivers at dawn.",
    },
}


static func furnishing(id: String) -> Dictionary:
    if FURNISHINGS.has(id):
        return FURNISHINGS[id]
    if GUILD_FURNISHINGS.has(id):
        return GUILD_FURNISHINGS[id]
    return {}


static func is_guild_wide(id: String) -> bool:
    return GUILD_FURNISHINGS.has(id)


static func furnishing_price(id: String) -> int:
    var f := furnishing(id)
    return int(f.get("price", 0)) if not f.is_empty() else 0


static func furnishing_slot(id: String) -> String:
    var f := furnishing(id)
    return String(f.get("slot", "")) if not f.is_empty() else ""


## Whether `raider` may hold `id` given what they already hold, or a reason why not.
##
## docs/02 §4.2's Personal Effect is "Only valid for raiders whose backstory tags
## match", so a raider with no matching backstory cannot hold one at all — the
## floor is not merely reduced.
static func placement_blocker(id: String, held: Array, facility_tier: int,
        raider) -> String:
    var f := furnishing(id)
    if f.is_empty():
        return "No such furnishing."
    if is_guild_wide(id):
        return "That one is bought for the whole guild, not for a person."
    if bool(f.get("requires_backstory", false)):
        # docs/02 §4.2: "Only valid for raiders whose backstory tags match — doc 04
        # owns tags." Tags do not exist yet, so this reads the one backstory hook
        # that does: docs/05 §7.5's offset, which is non-zero exactly when a raider
        # has a backstory at all. A NEGATIVE offset still qualifies — a bad past is
        # still a past, and docs/02's rule is about matching, not about the sign.
        if raider == null or int(raider.backstory_offset) == 0:
            return "A Personal Effect only means something to a raider whose past it belongs to."
    if held.has(id):
        return "%s already has one." % _name_of(raider)

    var slot := String(f["slot"])
    for other in held:
        if furnishing_slot(String(other)) == slot:
            return "Their %s slot is taken by the %s." % [
                slot, String(furnishing(String(other))["name"])]
    if held.size() >= slots_for(facility_tier):
        return "%s has no free slot — the %s allows %d." % [
            _name_of(raider), level_name(facility_tier), slots_for(facility_tier)]
    return ""


static func _name_of(raider) -> String:
    if raider == null:
        return "That raider"
    return String(raider.display_name)


## The comfort floor a raider's placed Furnishings contribute, guild-wide ones
## included. docs/02 §4.2: this is "this doc's contribution to the `baseline` a
## raider's morale drifts toward".
##
## `trophy_kills` is docs/02's "+2 extra if the raider was present for the kill it
## commemorates" — pass true when the Trophy Shelf commemorates a boss this raider
## was actually there for.
static func comfort_floor(held: Array, guild_wide: Array = [],
        trophy_present: bool = false) -> int:
    var total := 0
    var slots_used: Dictionary = {}
    for id in held:
        var f := furnishing(String(id))
        if f.is_empty():
            continue
        var slot := String(f["slot"])
        if slots_used.has(slot):
            continue
        slots_used[slot] = true
        total += int(f["floor"])
        if trophy_present and f.has("present_bonus"):
            total += int(f["present_bonus"])
    # A guild-wide order only counts where the raider has not already been given
    # their own — the same slot, so it cannot pay twice.
    for id in guild_wide:
        var f := furnishing(String(id))
        if f.is_empty():
            continue
        var slot := String(f["slot"])
        if slots_used.has(slot):
            continue
        slots_used[slot] = true
        total += int(f["floor"])
    return total


# ============================================================ Indulgences

## docs/11 §8.3. An Indulgence is consumed and fires docs/05 §7.4's `comfort_item`
## trigger, which carries that doc's +8 and its 2-Day-Tick per-raider cooldown — so
## the number and the cooldown are docs/05's, not invented here.
##
## "Buy a round" (docs/11 §8.3, doc 02 §5.1) is cut for 1.0 — docs/15 BL-40: a
## 96 G spike that drift erases in two ticks was a trap purchase; the Hot Bath
## Token is the Indulgence line.
const INDULGENCES := {
    "hot_bath": {
        "name": "Hot Bath Token", "price": 20, "trigger": "comfort_item",
        "blurb": "An hour in hot water, no talking. Good for exactly one bad day.",
    },
}


static func indulgence(id: String) -> Dictionary:
    return INDULGENCES[id] if INDULGENCES.has(id) else {}


static func indulgence_price(id: String) -> int:
    var i := indulgence(id)
    return int(i.get("price", 0)) if not i.is_empty() else 0


## docs/11 §8.3's stockpiling cap: "purchases of Indulgences per Day Tick may not
## exceed roster size — the cooldown already limits use, and the cap stops
## stockpiling for a burst".
static func indulgence_cap(roster_size: int) -> int:
    return maxi(0, roster_size)
