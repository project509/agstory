extends RefCounted
## docs/02 §11's building unlock and cost table — the single home for what a building
## level costs and which rank opens it.
##
## Every building in the town had its own copy of this before: `Comfort.LEVELS` carried
## the Guildhall's costs, `Consumables.stall_level()` DERIVED the Market's level from
## reputation because §6.2 has no cost column, and the Tavern had nothing at all. §11
## has all four, priced and gated, and it says why the numbers look the way they do:
##
##   "Costs are 🔷 PROPOSED throughout and expressed in G, where 1 raid-tier clear
##    payout ≈ 100 G (a relative unit so doc 11 can rescale everything by one
##    multiplier without touching this doc)."
##
## docs/15 BL-54 records the correction: the Market IS purchasable, and BL-44's claim that
## no cost column existed was made from §6.2 alone.
##
## Pure and deterministic: a table and its lookups.

const Enums = preload("res://sim/model/Enums.gd")

## Each building's priced rungs, in order. Four of the five stand at level 1 from the
## first day for free — docs/02 §11's "Unknown (start)" rows, ✅ CANON for the Tavern
## ("recruiting happens here from the start") and for the Adventure's Board, 🔷 PROPOSED
## for the Guildhall and Market — so their ladders begin at level 2.
##
## The Blacksmith is the exception, and it is why this comment no longer says "level 1 is
## always present": §11 prices the Blacksmith's OWN level 1 at 300 G behind Respected, so
## its ladder carries a level-1 rung and a guild that has not bought it stands at level 0.
## `base_level()` is the one place that distinction is decided.
##
## `rank` is the reputation rank that opens the rung; `cost` is docs/02 §11's gold.
const LADDERS := {
    "guildhall": [
        {"level": 2, "rank": 1, "cost": 150},
        {"level": 3, "rank": 3, "cost": 500},
        {"level": 4, "rank": 4, "cost": 1400},
    ],
    "tavern": [
        {"level": 2, "rank": 1, "cost": 120},
        {"level": 3, "rank": 2, "cost": 420},
        {"level": 4, "rank": 4, "cost": 1200},
    ],
    "market": [
        {"level": 2, "rank": 1, "cost": 130},
        {"level": 3, "rank": 2, "cost": 450},
        {"level": 4, "rank": 3, "cost": 1100},
    ],
    "blacksmith": [
        # docs/02 §11's three Blacksmith rows, gate and price. Note the level-1 rung:
        # unlike the other four this building is not standing when the game begins, so
        # its first level is a purchase and `base_level("blacksmith")` is 0.
        #
        # Every one of these gates is ❓ OPEN in §11's own "canon status" column, because
        # canon's heading reads "Blacksmith (Maybe)" and docs/03 §11 Q8 has not been
        # answered ("if cut, Respected instead unlocks the Tavern expansion"). The table
        # is the doc's numbers; the DECISION stays behind the `blacksmith` feature flag
        # docs/14 §5.2 requires, which is why adding these rows is not shipping the
        # building — game/screens/Town.gd asks the flag before it asks the rank. Q8's
        # alternate reading (move the Tavern's L4 rung down to Respected) is deliberately
        # NOT implemented: it would move a 🔷 PROPOSED gate on a ✅ CANON building to
        # satisfy an ❓ OPEN one. See build/plan/q-town-loop.md.
        {"level": 1, "rank": 2, "cost": 300},
        {"level": 2, "rank": 3, "cost": 700},
        {"level": 3, "rank": 4, "cost": 1600},
    ],
    "board": [
        # ✅ CANON: "New Tiers can be unlocked by gaining reputations with the town", so
        # docs/02 §11 prices every Board rung at 0 — "Free: it upgrades by reputation,
        # not gold." The rung exists so the Board is in the same table as everything
        # else; nothing charges for it.
        {"level": 2, "rank": 1, "cost": 0},
        {"level": 3, "rank": 2, "cost": 0},
    ],
}

const MAX_LEVEL := 4


static func ladder(building: String) -> Array:
    return LADDERS.get(building, [])


static func top_level(building: String) -> int:
    var rungs := ladder(building)
    return int(rungs[-1]["level"]) if not rungs.is_empty() else 1


## The level a building stands at before the player has bought anything: 1 for the four
## docs/02 §11 marks "Unknown (start)", and 0 for a building whose own level 1 is a
## priced rung. Only the Blacksmith is the latter, and only because §11 prices its L1.
##
## An unknown building answers 1, matching what a screen assumes when it is handed an id
## the table has never heard of — a missing row must not read as a demolished building.
static func base_level(building: String) -> int:
    for rung in ladder(building):
        if int(rung["level"]) == 1:
            return 0
    return 1


## Whether standing alone climbs this ladder — every rung free. docs/02 §11 prices all of
## the Adventure's Board's rungs at 0 and says why in the table's own note: "Free: it
## upgrades by reputation, not gold", under ✅ CANON "New Tiers can be unlocked by gaining
## reputations with the town."
##
## docs/14 §5.3.7 turns the same sentence into a load-time assertion — "the validator
## asserts `gold_cost == 0` for every Board level" — so this predicate is that validator's
## shape, asked of any building rather than hard-coded to one id.
static func is_reputation_only(building: String) -> bool:
    var rungs := ladder(building)
    if rungs.is_empty():
        return false
    for rung in rungs:
        if int(rung["cost"]) != 0:
            return false
    return true


## The level a free-rung building stands at, derived from the rank instead of stored.
## docs/02 §3.2's derivation rule asks for exactly this — recompute rather than save, so
## "a design retune" cannot invalidate a save — and for the Board there is no player
## decision left to store once the rank is known.
##
## A priced ladder cannot be derived from a rank: the gold half is the player's, so this
## returns that building's base level, which is all the rank alone proves.
static func reputation_level(building: String, rank: int) -> int:
    var level := base_level(building)
    if not is_reputation_only(building):
        return level
    for rung in ladder(building):
        if rank >= int(rung["rank"]):
            level = maxi(level, int(rung["level"]))
    return level


## The rung that takes a building from `level` to `level + 1`, or an empty Dictionary at
## the top of its ladder.
static func next_rung(building: String, level: int) -> Dictionary:
    for rung in ladder(building):
        if int(rung["level"]) == level + 1:
            return rung
    return {}


static func upgrade_cost(building: String, level: int) -> int:
    var rung := next_rung(building, level)
    return int(rung["cost"]) if not rung.is_empty() else -1


static func upgrade_rank(building: String, level: int) -> int:
    var rung := next_rung(building, level)
    return int(rung["rank"]) if not rung.is_empty() else -1


## Which of the two gates is blocking, or "" when the rung is buyable. docs/11 §8.4 asks
## for exactly this on the Guildhall's screen — "a level is buyable only when both its
## rank gate and its price are met, and the screen must show which of the two is
## blocking" — and every building screen wants the same sentence.
static func upgrade_blocker(building: String, level: int, gold: int,
        rank: int) -> String:
    var rung := next_rung(building, level)
    if rung.is_empty():
        return "There is nothing left to build here."
    var needed := int(rung["rank"])
    if rank < needed:
        return "%s guilds cannot commission this. Reach %s." % [
            Enums.reputation_name_of(rank), Enums.reputation_name_of(needed)]
    var cost := int(rung["cost"])
    if gold < cost:
        return "Costs %d G — you have %d." % [cost, gold]
    return ""


## Why a building is not standing at all, or "" once it is — the town square's question,
## where `upgrade_blocker` answers a building screen's.
##
## Four of the five need no answer: docs/02 §11 has them open at Unknown for free, because
## the ✅ CANON loop ("earn money → spend money at the blacksmith/Merchant → recruit at the
## tavern → take missions") needs all of them from minute one. The Blacksmith is the whole
## reason this function exists: §11 puts its level 1 behind Respected at 300 G, which makes
## "is there a smithy" the same rank-then-price pair every upgrade already answers.
##
## So it delegates rather than rephrasing. docs/11 §8.4 wants the screen to name which of
## the two gates is blocking, and the Guildhall's facility gate already prints those two
## sentences; a second wording of them would be a second thing to keep in step.
static func entry_blocker(building: String, gold: int, rank: int) -> String:
    if base_level(building) > 0:
        return ""
    return upgrade_blocker(building, 0, gold, rank)


## Why gold cannot buy this rung, or "" when gold is exactly what buys it. docs/02 §11
## prices every Adventure's Board rung at 0, so a screen that offered one for sale would
## be charging for something standing gives away — and `upgrade_blocker` would wave it
## through, since a cost of 0 is always affordable. This is the refusal that keeps a future
## Board screen honest, and it names the rank because that is the price it is really
## quoting.
static func purchase_refusal(building: String, level: int) -> String:
    if not is_reputation_only(building):
        return ""
    var rung := next_rung(building, level)
    if rung.is_empty():
        return "Reputation opens this, not gold — and there is nothing left to open."
    return "Reputation opens this, not gold. Reach %s." % Enums.reputation_name_of(
        int(rung["rank"]))
