extends RefCounted
## Loot: what a clear drops, who should get it, and what it pays.
##
## ✅ CANON fixes the mapping from encounter to loot slot (raw notes, *Raid Layout
## and loot drops*), and docs/10 §4.1 verified cell by cell that the raw notes and
## the nine per-class ideaboard tables **agree item for item**. That agreement is
## what lets this be a table lookup instead of 45 hand-authored drop lists.
##
## docs/10 §4.2's implementable form:
##     drop_pool(tier, encounter) = items WHERE tier matches AND slot in slots_for(encounter)
##     rolls(encounter)           = E1:2  E2:2  E3:2  E4:3  E5:3  (+1 guaranteed trinket)
##
## The raid tier does not need the slot mapping at all: every raid item already
## carries `drop_encounter`, transcribed from canon's own per-class tables, so a
## raid pull reads straight off the data. Adventures have no such field, so they
## use the encounter's declared `loot_slots`.
##
## Pure and deterministic. No Node, no global RNG — an `Rng` comes in, the same
## seed always produces the same drops, and a reported loot bug is reproducible.

const Enums = preload("res://sim/model/Enums.gd")

## docs/10 §4.2. E5 rolls 3 and is then handed a trinket outright, because canon
## lists trinkets as a Boss 5 drop and a guaranteed capstone reward reads better
## than a fourth roll that might miss.
const RAID_ROLLS := {"E1": 2, "E2": 2, "E3": 2, "E4": 3, "E5": 3}
const E5_GUARANTEES_TRINKET := true

## docs/11 §F1 — per-encounter first-clear payout, summing to 70 G for a full
## Raid 1, which is the anchor docs/11 §3.1 prices the whole economy against.
const RAID_PAYOUT := {"E1": 6, "E2": 8, "E3": 14, "E4": 16, "E5": 26}

## docs/11 §F2 prices "Adventure 1" at 20 G for the whole adventure. Because
## docs/15 BL-24 makes one board rung one encounter, that 20 G is split across the
## three rungs in §F1's own rising shape. Sums to exactly 20.
const ADVENTURE_PAYOUT := {"A1": 4, "A2": 6, "A3": 10}

## docs/11 §F2, verbatim: "Adventure 0: 4 G · Tutorial Raid: 8 G". Priced here
## rather than folded into ADVENTURE_PAYOUT because the two tutorials are not
## adventure rungs — docs/10 §9 mounts them ahead of A1 as onboarding — and
## because THIS TABLE IS THE TUTORIAL TEST inside this file. `payout`,
## `rolls_for` and `drop_pool` all branch on it, so a tutorial is exactly the set
## of slots priced as one and there is no second list to fall out of step.
##
## The repeat decay below applies unchanged: docs/10 §9.3 keeps a resolved
## tutorial "replayable for gold" while its trinket is gone after the first clear.
const TUTORIAL_PAYOUT := {"A0": 4, "TR": 8}

## docs/11 §F5 — repeat-clear decay, mirroring docs/03's repeat-reputation
## halving: full, half, quarter, then a 10% floor forever.
const REPEAT_DECAY := [1.0, 0.5, 0.25]
const REPEAT_FLOOR := 0.10

## Pool keys as they appear in an encounter's `loot_slots`, mapped to the slot
## they actually name. Canon writes these as prose ("Feet + basic weapons"), so
## the keys are content-facing labels rather than engine slots.
const POOL_KEY_TO_SLOT := {
    "feet": Enums.Slot.FEET,
    "legs": Enums.Slot.LEGS,
    "head": Enums.Slot.HEAD,
    "chest": Enums.Slot.CHEST,
    "weapon": Enums.Slot.MAIN_HAND,
    "weapon_basic": Enums.Slot.MAIN_HAND,
    "weapon_strong": Enums.Slot.MAIN_HAND,
    "offhand_healer": Enums.Slot.OFF_HAND,
    "trinket": Enums.Slot.TRINKET,
}


# ---------------------------------------------------------------- the pool

## True when this encounter is a raid rung (E1-E5) rather than an Adventure.
static func is_raid_slot(slot: String) -> bool:
    return RAID_ROLLS.has(slot)


## An onboarding rung. Keyed off the payout table for the reason given there:
## one list, so the three branches below cannot disagree about what a tutorial is.
static func is_tutorial_slot(slot: String) -> bool:
    return TUTORIAL_PAYOUT.has(slot)


## How many items this encounter rolls. Adventures take one roll per declared
## loot slot — docs/10 gives roll counts only for the raid tier, and one-per-slot
## is the reading the data already carries (A1 2, A2 1, A3 2). Half-size content
## paying about half a raid's drops also keeps docs/10 §3's "Adventure = short"
## framing honest.
static func rolls_for(encounter) -> int:
    if encounter == null:
        return 0
    # A tutorial rolls NOTHING. Both carry one "trinket" loot slot, which is
    # canon's "1 crap trinket" stated as content, but the reward is a fixed
    # once-only grant made by `GameState.record_attempt` rather than a roll
    # (docs/09 §10.2 G12, docs/15 BL-77). Returning 1 here would promise a
    # phantom roll that `drop_pool` then has to answer with nothing.
    if is_tutorial_slot(encounter.slot):
        return 0
    if is_raid_slot(encounter.slot):
        return int(RAID_ROLLS.get(encounter.slot, 2))
    return maxi(1, encounter.loot_slots.size())


## Every item this encounter can drop.
static func drop_pool(encounter, db) -> Array:
    var out: Array = []
    if encounter == null or db == null:
        return out

    # Empty on purpose, and this is the guard rather than a happy accident. The
    # non-raid branch below maps the tutorials' declared "trinket" loot slot to
    # `Slot.TRINKET` and would return every tier-1 `source == "adventure"`
    # trinket — Adventure's Charm of Health (+7 HP) and Charm of Power (+2
    # Power). Those are the exact items docs/10 §9.2 says the crap trinkets must
    # be visibly worse than, so a tutorial rolling here would pay better than
    # Adventure 1 and turn the skip warning into a lie. `GameState` already
    # bypasses this for a tutorial; the bypass having a second author here means
    # a future caller cannot reintroduce the hazard by not knowing about it.
    if is_tutorial_slot(encounter.slot):
        return out

    if is_raid_slot(encounter.slot):
        # The raid tier is indexed by canon's own per-class tables: each raid
        # item records the boss that drops it, so no slot mapping is needed and
        # none can drift out of step with the transcription.
        var boss := int(encounter.slot.substr(1).to_int())
        for id in db.items.keys():
            var it = db.items[id]
            if it.source == "raid" and it.tier == encounter.tier \
                    and it.drop_encounter == boss:
                out.append(it)
        return out

    # Adventures declare their slots, because Adventure items carry no
    # drop_encounter — canon assigns Adventure loot to *the Adventure*, not to
    # an encounter within it (docs/10 §8).
    var wanted := {}
    for key in encounter.loot_slots:
        var slot: int = int(POOL_KEY_TO_SLOT.get(String(key), -1))
        if slot >= 0:
            wanted[slot] = true
    for id in db.items.keys():
        var it = db.items[id]
        if it.source == "adventure" and it.tier == encounter.tier \
                and wanted.has(it.slot):
            out.append(it)
    return out


# ---------------------------------------------------------------- rolling

## Roll this encounter's drops. Deterministic for a given rng.
##
## docs/10 §11 says raids are "repeatable with duplicate protection" but leaves
## the mechanism ❓ OPEN. Implemented as a BIAS rather than a ban (docs/15 BL-31):
## the roll prefers items that would actually upgrade somebody on the roster, and
## only falls back to the whole pool when nothing would. That stops the fifth
## pair of boots arriving while three raiders are still barefoot, without ever
## making a pull drop nothing — a farm run that yields an item you cannot use is
## disappointing; one that yields no item at all reads as a bug.
static func roll_drops(encounter, db, roster: Array, rng) -> Array:
    var pool := drop_pool(encounter, db)
    if pool.is_empty() or rng == null:
        return []

    var wanted: Array = []
    for it in pool:
        if is_upgrade_for_anyone(it, db, roster):
            wanted.append(it)

    var out: Array = []
    var n := rolls_for(encounter)
    for _i in n:
        var source: Array = wanted if not wanted.is_empty() else pool
        var picked = rng.pick(source)
        if picked != null:
            out.append(picked)

    if E5_GUARANTEES_TRINKET and encounter.slot == "E5":
        var trinket = _trinket_from_pool(db, encounter.tier, rng)
        if trinket != null:
            out.append(trinket)
    return out


## The Boss 5 trinket, DRAWN rather than picked.
##
## docs/09 §13.5 gives each tier a four-item trinket pool (Health / Armour /
## Mana / Power) and ContentDB loads and validates it per tier. Nothing read it:
## this used to scan every item and return the first trinket of the right tier
## by sorted id, which is always the ARMOR one — so three quarters of the pool
## was content the player could never see. Seeded from the same rng as the rest
## of the roll, so a given seed still produces a given drop.
##
## The old scan survives as the fallback for a tier whose pool is missing, which
## is a content error ContentDB already reports; a fight that hands out nothing
## would read as a bug on top of a bug.
static func _trinket_from_pool(db, tier: int, rng):
    var pool: Array = db.trinket_pool_for(tier) if db.has_method("trinket_pool_for") else []
    if not pool.is_empty() and rng != null:
        return rng.pick(pool)
    return _first_trinket(db, tier, "raid")


static func _first_trinket(db, tier: int, source: String):
    var ids: Array = db.items.keys()
    ids.sort()          # deterministic: never rely on Dictionary order
    for id in ids:
        var it = db.items[id]
        if it.slot == Enums.Slot.TRINKET and it.tier == tier and it.source == source:
            return it
    return null


# ---------------------------------------------------------------- assignment

## Raiders who can wear this at all. Canon's itemization is a family-sharing
## matrix, so this is usually several people and that contention is the point
## (docs/09 §107: "when item X drops, which of my raiders raise their hand?").
static func eligible(item, db, roster: Array) -> Array:
    var out: Array = []
    if item == null:
        return out
    for r in roster:
        if item.can_be_used_by(r.class_id):
            out.append(r)
    return out


## What an item is worth as an ORDERING KEY — total stat points plus heal_base.
##
## This is emphatically NOT a power score, and docs/13 §10.2 is right that one
## would be dishonest: a Mage's Mana and a Warrior's AC are not commensurable.
## The reason it is sound here is that it is only ever used to rank candidates
## for ONE SLOT, and `eligible()` has already filtered to raiders who can use the
## item — so it compares like with like.
##
## `heal_base` is included because a healer's weapon carries its entire power
## there rather than as a stat. Leaving it out rated every healing weapon at zero.
static func item_worth(item) -> int:
    if item == null:
        return 0
    var st = item.stats
    return st.ac + st.hp + st.power + st.mana + st.damage + item.heal_base


## How much this item improves that raider, in `item_worth` points.
##
## An earlier version measured the CLASS'S primary stat, which was wrong in a way
## that looked reasonable: a Warrior's primary stat is not `damage`, so a +5
## damage sword scored zero and the game never handed out a single weapon. The
## party farmed A1 fifteen times and came back wearing nothing but boots.
static func upgrade_delta(item, db, raider) -> int:
    if item == null or db == null or raider == null:
        return 0
    if not item.can_be_used_by(raider.class_id):
        return 0
    return item_worth(item) - item_worth(raider.item_in(db, item.slot))


static func is_upgrade_for_anyone(item, db, roster: Array) -> bool:
    for r in roster:
        if upgrade_delta(item, db, r) > 0:
            return true
    return false


## Priority bonus for a raider who has NOTHING in that slot.
##
## docs/09 §14.3 calls Option B "need-based", and this is need taken literally: a
## raider holding no weapon at all needs one more than a raider trading up. It is
## also what makes farming an on-ramp work — the party gets kitted out before
## anyone double-dips — and canon starting armour leaves the main hand and trinket
## empty for everybody, so on day one this is the rule that does all the work.
const EMPTY_SLOT_PRIORITY := 1000


static func need_score(item, db, raider) -> int:
    var delta := upgrade_delta(item, db, raider)
    if delta <= 0:
        return delta
    if raider.item_in(db, item.slot) == null:
        return delta + EMPTY_SLOT_PRIORITY
    return delta


## docs/09 §14.3's "Suggested" rule, which is Option B (need-based) offered as a
## one-click default the player may override. Returns the raider who gains most,
## or null when the item helps nobody — in which case the loot window's Sell
## target is the honest answer rather than forcing it onto someone.
##
## Ties break on roster order, which is stable across saves, so the suggestion
## never flickers between two equally good candidates.
static func suggest(item, db, roster: Array):
    var best = null
    var best_score := 0
    for r in eligible(item, db, roster):
        var score := need_score(item, db, r)
        if score > best_score:
            best_score = score
            best = r
    return best


## The whole loot window in one call: a row per drop, each with its eligible
## raiders, the suggested target and that target's gain.
static func plan(drops: Array, db, roster: Array) -> Array:
    var rows: Array = []
    for it in drops:
        var target = suggest(it, db, roster)
        rows.append({
            "item": it,
            "eligible": eligible(it, db, roster),
            "suggested": target,
            "delta": upgrade_delta(it, db, target) if target != null else 0,
        })
    return rows


# ---------------------------------------------------------------- gold

## docs/11 §F1/§F2 with §F5's repeat decay. `times_cleared` is how many times
## this encounter has been cleared BEFORE this one, so a first clear pays full.
static func payout(encounter, times_cleared: int = 0) -> int:
    if encounter == null:
        return 0
    var base := 0
    # Tutorials first: docs/11 §F2 prices them in the same breath as Adventure 1
    # and they are in neither table below, so without this row both paid 0 G —
    # `payout()` returns 0 for any slot it does not recognise, which is the right
    # behaviour for an unknown rung and was silently wrong for these two.
    if is_tutorial_slot(encounter.slot):
        base = int(TUTORIAL_PAYOUT.get(encounter.slot, 0))
    elif is_raid_slot(encounter.slot):
        base = int(RAID_PAYOUT.get(encounter.slot, 0))
    else:
        base = int(ADVENTURE_PAYOUT.get(encounter.slot, 0))
    if base == 0:
        return 0
    var mult := REPEAT_FLOOR
    if times_cleared >= 0 and times_cleared < REPEAT_DECAY.size():
        mult = float(REPEAT_DECAY[times_cleared])
    # docs/11 says "rounded to the nearest 5 G AFTER ALL MULTIPLIERS", and its own
    # §F1 table is 6 / 8 / 14 / 16 / 26 — none of them multiples of 5. Both are
    # true if the published tables ARE the first-clear figures and the rounding
    # applies to what the decay produces. Rounding a first clear as well would
    # silently contradict the table this file is meant to implement (it turned
    # E5's 26 G into 25 G, which is how this was caught).
    if is_equal_approx(mult, 1.0):
        return base
    # Never below 1 G: a farmed encounter should become poor, not worthless.
    return maxi(1, int(round(float(base) * mult / 5.0) * 5))
