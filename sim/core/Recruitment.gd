extends RefCounted
## Who walks into the Tavern (docs/03 §5, docs/04 §3, §5, §6).
##
## ✅ CANON fixes four of the six ranks and nothing else: Unknown finds "only the worst
## players", Known adds Uncommon, Respected drops Common and makes Uncommon the common
## result, Renowned drops Uncommon and adds Epic plus a "VERY SMALL" Legendary chance.
## Canon says NOTHING about Established or Legendary rank, and docs/03 §5.4 flags that
## as "THE LARGEST HOLE IN THIS DOC".
##
## ⚠️ THE TRAP docs/03 §5.1 marks in red, and it is worth repeating here because the
## number is sitting right next to it in canon: "The number '1%' in canon belongs to the
## Legendary raider's *mistake* chance, not to the chance of finding one. Canon gives NO
## number for the Legendary find chance — only 'VERY SMALL.' Do not implement 1% as a
## find chance because canon says 1% nearby."
##
## Pure and deterministic: every roll takes an `Rng` and consumes it in the fixed order
## docs/04 §5 lays down, "so two programmers generating a raider produce byte-identical
## output from the same seed".

const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const BackstoryPool = preload("res://sim/content/BackstoryPool.gd")
const LegendaryPool = preload("res://sim/content/LegendaryPool.gd")

# ============================================================ the matrix

## docs/03 §5.2's per-mille denominator. A schema invariant rather than a tuning value —
## "rows sum to 1000" is what `Reputation.validate()` checks the file against — so it is
## aliased from the one place that enforces it instead of being typed out twice.
const WEIGHT_TOTAL := Reputation.WEIGHT_TOTAL

## docs/03 §5.2's matrix, per-mille, rows summing to 1000, indexed by rank then by
## `Enums.Rarity`. The Established and Legendary rows are entirely 🔷 PROPOSED (docs/03
## §5.4's gap-fill); every other cell has a canon marker in §5.3.
##
## THE TABLE ITSELF LIVES IN `data/reputation.json` (docs/03 §9), and this reads it. It
## used to be a second literal copy beside the file's, which made docs/03 §9's promise —
## "a designer retunes the ladder by editing one file" — false for the single most
## canon-loaded table in the project: an edit to the file moved `Reputation.recruit_tiers()`
## (§7's recruit column) and left the roll that actually produces the raider untouched, so
## the Tavern could advertise a rarity the generator could no longer produce. Nothing
## asserted the two agreed; `tests/unit/test_reputation.gd`'s
## `test_no_tuning_number_exists_in_two_places_at_once` now does.
static func weights_for(rank: int) -> Array:
    var row: Dictionary = Reputation.rank_row(rank)
    var weights: Array = row.get("find_weights", [])
    return weights.duplicate()


# docs/03 §8.1 M2's two numbers — "when `pity >= 25` the next recruit is forced to Rare
# or better ... Active from **Respected** onward, since Rare does not exist before then"
# — are §9 keys (`pity_threshold`, `pity_min_rank`) and are read from the file the same
# way, at `pity_forced_tier()` below. docs/03 §8.1 decides them together with §5.2's
# matrix, so they live beside it rather than here.

## docs/04 §3.3: `cost = base(rarity) × (1 + 0.6 × (CT − 1))`, rounded to the nearest 10.
##
## WHICH BASE TABLE: docs/15 BL-94. Three docs print three recruit price tables for
## the same Tier 1 recruits, and the register's own recruit-price row says doc 11
## §4.2 S1 is the one authoritative table and docs 04 and 13 render it. Both are
## 🔷 PROPOSED, so the choice is a switch: `PRICE_SCALE` names the row of
## `COST_BASES` in force. "doc11" is the shipped default (a Common at 15 G — the
## scale docs/01 §8.0's 60 G purse was sized against, and the one docs/11 §12.1
## R3's anti-arbitrage floor is asserted on in tests/unit/test_recruitment.gd);
## "doc04" keeps the old 60/180/450/1100/3000 selectable. A `static var` so both
## tables stay under test. The content-tier multiplier is doc 04's and applies to
## either; the register's recruit-gear surcharge (the designer page's row #7,
## `GEAR_SURCHARGE_BP`, wave 8) is a later multiplier on the same result.
const COST_BASES := {
    "doc11": [15, 60, 160, 420, 1000],
    "doc04": [60, 180, 450, 1100, 3000],
}
static var PRICE_SCALE := "doc11"
const COST_PER_TIER := 0.6

## docs/04 §6.2's raid-experience bands. Common's 0 is ✅ CANON ("they have 0 raid
## experience"); the rest are 🔷 PROPOSED, and docs/15 Q-30 already ruled the field
## "flavour and display only", so nothing downstream reads these as competence.
const EXPERIENCE_BANDS := [[0, 0], [1, 2], [3, 6], [8, 15], [20, 30]]

## docs/03 §4.1 and docs/04 §6.2's gear recipes: how many pieces, and from which table.
## The remaining slots are filled by the fallback, so every recruit arrives dressed.
const GEAR_RECIPES := [
    {"source": "start", "min": 4, "max": 4, "fill": ""},
    {"source": "adventure", "min": 1, "max": 2, "fill": "start"},
    {"source": "adventure", "min": 3, "max": 4, "fill": "start"},
    {"source": "raid", "min": 1, "max": 2, "fill": "adventure"},
    {"source": "raid", "min": 3, "max": 4, "fill": "adventure"},
]

## docs/03 §4.1: "weapons are never granted at recruitment (the Market/Blacksmith is the
## weapon path)", and docs/04 §6.1's Boss-5 lockout keeps the terminal drops out of the
## Tavern entirely. Armour only, and only the four canon starting slots.
const GRANT_SLOTS := [
    Enums.Slot.HEAD, Enums.Slot.CHEST, Enums.Slot.LEGS, Enums.Slot.FEET,
]


## The modal tier at a rank — docs/03 §8.1's M1 guarantees one of these per board.
static func modal_rarity(rank: int) -> int:
    var w := weights_for(rank)
    var best := 0
    for i in w.size():
        if int(w[i]) > int(w[best]):
            best = i
    return best


# ============================================================ the roll

## docs/03 §5.5's step 1: "If every class's Legendary is claimed, Legendary cannot roll.
## weights[Epic] += weights[Legendary]; weights[Legendary] = 0" — redistributed rather
## than dropped, so the row still sums to 1000 and Epic absorbs the difference.
static func adjusted_weights(rank: int, legendary_available: bool) -> Array:
    var w := weights_for(rank)
    if not legendary_available:
        w[Enums.Rarity.EPIC] = int(w[Enums.Rarity.EPIC]) \
            + int(w[Enums.Rarity.LEGENDARY])
        w[Enums.Rarity.LEGENDARY] = 0
    return w


## docs/03 §8.1 M2. Returns the forced tier, or -1 when pity is not due.
##
## The forced tier is the lowest Rare-or-better the rank can actually produce, so pity
## can never hand out a rarity the matrix says does not exist at that rank.
static func pity_forced_tier(rank: int, pity: int, legendary_available: bool) -> int:
    if rank < Reputation.pity_min_rank() or pity < Reputation.pity_threshold():
        return -1
    var w := adjusted_weights(rank, legendary_available)
    for tier in range(Enums.Rarity.RARE, w.size()):
        if int(w[tier]) > 0:
            return tier
    return -1


## docs/03 §5.5, and the order matters: **rarity is rolled before class**. The
## alternative — class first, then downgrade a Legendary whose class is taken —
## "silently erodes the Legendary rate as classes get claimed: by the 9th Legendary the
## effective rate would be 1/9th of the table value".
static func roll_rarity(rng, rank: int, pity: int = 0,
        legendary_available: bool = true) -> int:
    var forced := pity_forced_tier(rank, pity, legendary_available)
    if forced >= 0:
        return forced
    var w := adjusted_weights(rank, legendary_available)
    var pick: int = rng.pick_weighted(w)
    return pick if pick >= 0 else Enums.Rarity.COMMON


## docs/03 §8.1 M2's counter: "Increment on every generated recruit below Rare; reset to
## 0 on any Rare-or-better."
static func next_pity(pity: int, rolled: int) -> int:
    return 0 if rolled >= Enums.Rarity.RARE else pity + 1


## docs/04 §5 step 2: "Class — uniform over the nine classes (A15) ... If
## `rarity = legendary`, restrict to classes whose Legendary has not yet been found."
##
## `avoid` is docs/04 §3.1's duplicate-class softening, applied by `roll_board`.
static func roll_class(rng, rarity: int, claimed: Array = [],
        avoid: Array = []) -> int:
    var pool: Array = []
    for cls in Enums.all_classes():
        if rarity == Enums.Rarity.LEGENDARY and claimed.has(cls):
            continue
        pool.append(cls)
    if pool.is_empty():
        return -1
    var open: Array = []
    for cls in pool:
        if not avoid.has(cls):
            open.append(cls)
    var from: Array = open if not open.is_empty() else pool
    return int(from[rng.next_below(from.size())])


# ============================================================ what they arrive with

## docs/04 §6.2's raid-experience band. docs/15 Q-30: display only.
static func roll_experience(rng, rarity: int) -> int:
    var band: Array = EXPERIENCE_BANDS[clampi(rarity, 0, EXPERIENCE_BANDS.size() - 1)]
    var lo := int(band[0])
    var hi := int(band[1])
    if hi <= lo:
        return lo
    return lo + rng.next_below(hi - lo + 1)


## Which slots get the good gear and which get the fallback. docs/03 §4.1: "slot
## selection is uniform without replacement across [Head, Chest, Legs, Feet]".
##
## Returns `{"source": String, "granted": Array[slot], "fill": String}` — a plan rather
## than items, because which item fills a slot is `ContentDB`'s answer and this module
## does not read content.
static func gear_plan(rng, rarity: int) -> Dictionary:
    var recipe: Dictionary = GEAR_RECIPES[clampi(rarity, 0, GEAR_RECIPES.size() - 1)]
    var lo := int(recipe["min"])
    var hi := int(recipe["max"])
    var count: int = lo if hi <= lo else lo + rng.next_below(hi - lo + 1)

    var slots: Array = GRANT_SLOTS.duplicate()
    var granted: Array = []
    for i in mini(count, slots.size()):
        var idx: int = rng.next_below(slots.size())
        granted.append(slots[idx])
        slots.remove_at(idx)
    granted.sort()
    return {
        "source": String(recipe["source"]),
        "granted": granted,
        "fill": String(recipe["fill"]),
    }


## docs/04 §3.3. "Gold values are placeholders until doc 11 sets the earn rate; the
## *ratios* are the design intent — an Epic should cost roughly what a full tier's clear
## pays out, so buying power is a real alternative to farming."
static func cost_of(rarity: int, content_tier: int) -> int:
    var table: Array = COST_BASES[PRICE_SCALE]
    var base: int = table[clampi(rarity, 0, table.size() - 1)]
    var ct := maxi(1, content_tier)
    if ct == 1:
        # The base table IS the Tier 1 price (doc 11 S1's 15 G is not a multiple
        # of 10); the rounding below belongs to doc 04's multiplier, not the base.
        return base
    var mult := 1.0 + COST_PER_TIER * float(ct - 1)
    return int(round(float(base) * mult / 10.0)) * 10


# ============================================================ the candidate

## docs/04 §5's pipeline, in its fixed order. Steps 4 (name) and 7 (backstory) are the
## two that need data files this build does not have yet, so they are INJECTED: pass
## `namer` and `backstory` callables and this fills them, or leave them out and the
## candidate arrives with a placeholder that says what is missing.
##
## Morale is deliberately not rolled — docs/04 §5 step 8: "consumes no RNG. Set to the
## computed baseline per docs/05 §4/§7.5, which is why backstory must be drawn first:
## the bullets supply doc 05's `backstory_offset`."
static func generate(rng, rank: int, content_tier: int, ctx: Dictionary = {}):
    var claimed: Array = ctx.get("claimed_legendary_classes", [])
    var avoid: Array = ctx.get("avoid_classes", [])
    var pity := int(ctx.get("pity", 0))
    var legendary_available: bool = claimed.size() < Enums.all_classes().size()

    var rarity := roll_rarity(rng, rank, pity, legendary_available)
    var cls := roll_class(rng, rarity, claimed, avoid)
    if cls < 0:
        # Every Legendary class is claimed and the redistribution missed it. docs/04 §5
        # step 2's own fallback: "if none remain, downgrade the roll to Epic."
        rarity = Enums.Rarity.EPIC
        cls = roll_class(rng, rarity, claimed, avoid)

    var r = Raider.new()
    r.id = "rec_%d" % rng.next_below(0x7FFFFFFF)
    r.class_id = cls
    r.rarity = rarity
    r.recruited_at_tier = maxi(1, content_tier)
    r.recruited_at_rank = rank
    r.raid_experience = roll_experience(rng, rarity)

    # docs/04 §5 step 4. A pool if one was handed over, then the callable seam, then
    # the placeholder — docs/03 §5.6 is emphatic that a missing name is a placeholder
    # and never an invention.
    var names = ctx.get("name_pool", null)
    var namer: Callable = ctx.get("namer", Callable())
    if names != null:
        r.display_name = names.pick(rng, ctx.get("taken_names", []))
    elif namer.is_valid():
        r.display_name = String(namer.call(rng, cls, rarity))
    if r.display_name.is_empty():
        r.display_name = _placeholder_name(rarity, cls)

    # docs/04 §5 step 7, and it must run BEFORE morale: step 8 says so in terms —
    # "backstory must be drawn first: the bullets supply doc 05's `backstory_offset`".
    var stories = ctx.get("backstory_pool", null)
    var backstory: Callable = ctx.get("backstory", Callable())
    if stories != null:
        r.backstory = stories.draw(rng, rarity, cls)
    elif backstory.is_valid():
        var written = backstory.call(rng, r)
        if typeof(written) == TYPE_ARRAY:
            r.backstory = written
    r.backstory_offset = BackstoryPool.offset_for(r.backstory)

    # docs/04 §5 step 3's short-circuit. It runs AFTER the generic path rather than
    # instead of it, so an authored character overwrites the rolled name and bullets
    # rather than the code having two ways to build a raider.
    var legends = ctx.get("legendary_pool", null)
    if rarity == Enums.Rarity.LEGENDARY and legends != null \
            and legends.has_definition(cls):
        r.legendary_def_id = String(legends.definition(cls).get("legendary_def_id", ""))
        # docs/03 §5.6: only the Shaman has a canon name; the rest render the doc's own
        # placeholder. Nothing here invents one.
        r.display_name = legends.display_name(cls)
        r.backstory = legends.backstory_of(cls)
        r.backstory_offset = BackstoryPool.offset_for(r.backstory)
        var override: int = legends.starting_morale(cls)
        if override >= 0:
            Morale.set_morale(r, float(override))
            return r

    # docs/05 §4: "a newly recruited raider starts at `baseline`, not at 50. This makes
    # rarity legible on the recruit screen: a Common walks in at 45, a Legendary at 62."
    Morale.set_morale(r, float(Morale.baseline_of(r,
        int(ctx.get("facility_tier", 0)))))
    return r


## docs/03 §5.6: "The other 8 Legendary names — ❓ OPEN, naming pending. Use placeholders
## `Legendary (Warrior) — name pending`. **Do not invent names.**" The same rule is
## applied to every rarity here: a placeholder that says what is missing beats a name
## that has to be deleted when `data/names.json` lands.
static func _placeholder_name(rarity: int, cls: int) -> String:
    if rarity == Enums.Rarity.LEGENDARY:
        return "Legendary (%s) — name pending" % Enums.class_name_of(cls)
    return "%s %s — name pending" % [
        Enums.rarity_name_of(rarity), Enums.class_name_of(cls)]


## docs/04 §3.1's board: "Each slot is rolled independently", with the duplicate-class
## softening, plus docs/03 §8.1's M1 modal-tier floor:
##
##   "Every Tavern refresh guarantees at least one recruit at the rank's modal tier ...
##   generate the pool, then if no recruit is at-or-above the modal tier, force-reroll
##   the lowest one at the modal tier."
##
## M1 exists to remove "the 'all four recruits are Uncommon at Established' run of bad
## luck" — the steepest edge of docs/03 §8's Recruit Quality Spiral.
static func roll_board(rng, slots: int, rank: int, content_tier: int,
        ctx: Dictionary = {}) -> Array:
    var out: Array = []
    var claimed: Array = (ctx.get("claimed_legendary_classes", []) as Array).duplicate()
    var pity := int(ctx.get("pity", 0))
    var drawn: Array = []

    for i in maxi(0, slots):
        var slot_ctx := ctx.duplicate()
        slot_ctx["claimed_legendary_classes"] = claimed
        slot_ctx["avoid_classes"] = drawn
        slot_ctx["pity"] = pity
        var who = generate(rng, rank, content_tier, slot_ctx)
        pity = next_pity(pity, who.rarity)
        if who.rarity == Enums.Rarity.LEGENDARY:
            # A Legendary on the board claims its class for the rest of the board, so a
            # refresh can never offer two of the same one.
            claimed.append(who.class_id)
        drawn.append(who.class_id)
        out.append(who)

    _apply_modal_floor(rng, out, rank, content_tier, ctx)
    return out


static func _apply_modal_floor(rng, board: Array, rank: int, content_tier: int,
        ctx: Dictionary) -> void:
    if board.is_empty():
        return
    var modal := modal_rarity(rank)
    var lowest := 0
    for i in board.size():
        if board[i].rarity >= modal:
            return
        if board[i].rarity < board[lowest].rarity:
            lowest = i

    # Re-roll the weakest card AT the modal tier rather than rolling again and hoping.
    var forced_ctx := ctx.duplicate()
    forced_ctx["avoid_classes"] = []
    var replacement = generate(rng, rank, content_tier, forced_ctx)
    replacement.rarity = modal
    replacement.raid_experience = roll_experience(rng, modal)
    replacement.display_name = _placeholder_name(modal, replacement.class_id)
    Morale.set_morale(replacement, float(Morale.baseline_of(replacement,
        int(ctx.get("facility_tier", 0)))))
    board[lowest] = replacement


## The pity counter after a whole board, for the caller to persist.
static func board_pity(pity: int, board: Array) -> int:
    var out := pity
    for who in board:
        out = next_pity(out, who.rarity)
    return out


# ================================================ deprecated compatibility aliases
#
# THESE ARE NOT A SECOND COPY. Each one is DERIVED from `data/reputation.json` through
# the accessors above, so a designer's edit to the file moves them and they cannot drift
# — which is the whole point of the extraction and the thing the old `const` literals
# broke. They exist only because `tests/unit/test_recruitment.gd` reads all three by name
# (`:32`, `:34`, `:40-50`, `:55`, `:80-82`, `:103`, `:110`, `:186`) and this wave does not
# own that file. Audit `M3-TUNE-04` owns the edits that re-point it at `weights_for()` /
# `Reputation.pity_threshold()`; delete this whole block — and the `static var`s below —
# the day it lands. (This used to cite a `build/plan/` handoff that was never written;
# the citation outlived the plan and pointed at nothing for four milestones.)
#
# `static var` and not `const` on purpose: a `const` cannot be computed, and computing
# them is the only thing that makes them safe. They are declared LAST in the file because
# static initialisers run in declaration order and these call `Reputation.tables()`, which
# needs `Reputation`'s own statics up first.

## docs/03 §5.2's matrix as one array-of-rows, for callers written before the extraction.
## Typed `Array[Array]` and not bare `Array`: `test_recruitment.gd:103,110` writes
## `var est := Recruitment.FIND_WEIGHTS[rank]`, and an untyped element makes that an
## "cannot infer the type" parse error — which is a broken tree, not a failing test.
static var FIND_WEIGHTS: Array[Array] = _all_weights()

## docs/03 §8.1 M2's two numbers, likewise.
static var PITY_THRESHOLD: int = Reputation.pity_threshold()
static var PITY_MIN_RANK: int = Reputation.pity_min_rank()


static func _all_weights() -> Array[Array]:
    var out: Array[Array] = []
    for row in Reputation.tables().get("ranks", []):
        var weights: Array = (row as Dictionary).get("find_weights", [])
        out.append(weights)
    return out
