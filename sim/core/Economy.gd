extends RefCounted
## What an item is worth, and what the Market pays for it (docs/11 §5-§6).
##
## *Why a formula and not a price list* — docs/11 §6.1 states the reason plainly:
## "with nine classes x five encounters of class-restricted drops, hand-pricing
## every item is both a content cost and a bug farm. One formula prices all
## current and future loot, including items canon has not statted yet."
##
## Canon gives no currency name, no price, no sell rate and no payout, so every
## number here is 🔷 PROPOSED by docs/11 — but the weights are *derived* from
## canon's own stat definitions ("AC = 2 damage reduction", "Power = +1 melee
## dmg", "Mana = spell damage"), not invented.
##
## Pure and deterministic: no Node, no RNG. Prices never vary by roll, which is
## what lets docs/11 §6.2's worked table be a test rather than a guideline.

const Enums = preload("res://sim/model/Enums.gd")

## docs/11 §6.1's raw weights. Mana's 0.8 is flagged by the doc as the one
## coefficient guaranteed to move, because canon marks Mana "Subject to change".
const W_AC := 2.0
const W_HP := 1.0
const W_POWER := 3.0
const W_MANA := 0.8
const W_DAMAGE := 2.5

## docs/11 §5. Gear steps run in canon's own progression order, so Tier 1
## Adventure is step 1 and each subsequent step is 1.9x the last.
const STEP_RATIO := 1.9

## Starting armour is step 0 and deliberately near-worthless. docs/11 §6.2: "That
## the whole beginner kit is worth one coin at the Market is the joke, and it is
## also why S1's Common hire at 15 G is not an arbitrage target."
const STARTING_COEFF := 0.35

## docs/11 §6.1, adopted verbatim from docs/03 §7. Indexed by ReputationRank.
const SELL_RATE := [0.40, 0.45, 0.50, 0.55, 0.60, 0.65]

## docs/11 §6.2: "Minimum price is 1 G, never 0 — a rounded-to-zero item still
## sells, or the sell-all helper silently deletes inventory." Applied on the VALUE
## line as well as the sell line.
const MINIMUM_PRICE := 1


## docs/11 §3.1: "Every price and payout is rounded to the nearest 5 G."
static func round_to_5(x: float) -> int:
    return int(round(x / 5.0) * 5)


## Which gear step an item sits on. Canon's ladder alternates Adventure then Raid
## within each tier, so Tier 1 Adventure is 1, Tier 1 Raid is 2, Tier 2 Adventure
## is 3, and so on — which is exactly the order docs/11 §5's table lists.
static func step_of(item) -> int:
    if item == null:
        return 0
    match item.source:
        "start":
            return 0
        "adventure":
            return maxi(1, 2 * item.tier - 1)
        "raid":
            return maxi(2, 2 * item.tier)
    # vendor / quest gear is priced as its tier's Adventure rung: it is bought or
    # awarded alongside that content, and inventing a step for it would put an
    # unpriced item in a shop.
    return maxi(1, 2 * maxi(1, item.tier) - 1)


static func value_coeff(step: int) -> float:
    if step <= 0:
        return STARTING_COEFF
    return pow(STEP_RATIO, float(step - 1))


## docs/11 §6.1's `raw`, before the step coefficient.
static func raw_worth(item) -> float:
    if item == null:
        return 0.0
    var st = item.stats
    return W_AC * float(st.ac) \
        + W_HP * float(st.hp) \
        + W_POWER * float(st.power) \
        + W_MANA * float(st.mana) \
        + W_DAMAGE * float(st.damage)


## What the item is worth. Note this deliberately ignores `heal_base`: docs/11
## §6.1's weights cover the five gear stats canon defines, and a healer weapon's
## heal_base is docs/08 §8.5's own PROPOSED stand-in for stats canon leaves TBD.
## Pricing it would put a number on a number that is itself a placeholder.
static func value_of(item) -> int:
    if item == null:
        return 0
    return maxi(MINIMUM_PRICE,
        round_to_5(raw_worth(item) * value_coeff(step_of(item))))


static func sell_rate(rank: int) -> float:
    if rank < 0 or rank >= SELL_RATE.size():
        return SELL_RATE[0]
    return SELL_RATE[rank]


## What the Market pays, at this guild's reputation. Reputation is the only thing
## that moves it, which is docs/03 §7's whole point: the town pays better as it
## thinks better of you.
static func sell_price(item, rank: int) -> int:
    if item == null:
        return 0
    return maxi(MINIMUM_PRICE, round_to_5(float(value_of(item)) * sell_rate(rank)))


# ---------------------------------------------------------------- the helper

## docs/02 §6.3 calls this "the single highest-value convenience in the game",
## and gives the reason: "the canon loot tables drop class-restricted gear at five
## encounters per raid, so junk volume is high."
##
## "Unusable" means NOBODY on the roster can equip it — not "nobody wants it".
## An item that is a sidegrade for someone is still theirs to keep or sell
## deliberately; only gear no class present can wear is junk by definition.
static func unusable_by(items: Array, roster: Array) -> Array:
    var out: Array = []
    for it in items:
        var usable := false
        for r in roster:
            if it.can_be_used_by(r.class_id):
                usable = true
                break
        if not usable:
            out.append(it)
    return out


## Total the Market would pay for a pile. Used for the footer's "gold before ->
## after" preview (docs/02 §6.3) so the number the player is shown is the number
## they get.
static func total_sell_price(items: Array, rank: int) -> int:
    var total := 0
    for it in items:
        total += sell_price(it, rank)
    return total
