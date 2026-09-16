extends RefCounted
## The twelve people you start with.
##
## ❓ OPEN, decided here and logged as docs/15 BL-23: canon never says what a new
## guild owns on day one. It cannot be "nothing": the raid size is 12 (✅ CANON)
## and docs/11 §S1 prices a Common hire at 15 G against docs/01 §8.0's 60 G
## opening balance, so a player starting from an empty roster could hire four
## people and would never reach a first raid. A starting roster is therefore
## forced by canon's own numbers, and only its SHAPE is a choice.
##
## The shape chosen: **the benchmark twelve** — docs/06 §6.4 Template A, which
## docs/08 §9.1 and docs/10 §5.3 both adopt verbatim as the composition every
## balance number in the project is derived against. Starting the player on the
## exact roster the tuning assumes means the opening hours are the difficulty
## the sweep actually measures, rather than an accidental variant of it.
##
## All twelve are Common in canon starting armour, which is precisely canon's
## own description of rank Unknown: *"you can only find the worst players to
## join your guild, they have 0 raid experience etc. (Common raiders)"*.
##
## Deterministic: a guild seed in, the same twelve out. No global RNG.

const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Rng = preload("res://sim/core/Rng.gd")
const Morale = preload("res://sim/core/Morale.gd")
const NamePool = preload("res://sim/content/NamePool.gd")
const BackstoryPool = preload("res://sim/content/BackstoryPool.gd")

## docs/06 §6.4 Template A — two tanks (✅ CANON: "most fights normally requiring
## 2 tanks"), all three healing shapes, and a Bard so the Bard is never
## accidentally balanced out of the game.
const BENCHMARK_COMP := [
    "warrior", "warrior", "cleric", "druid", "shaman", "rogue",
    "rogue", "monk", "mage", "wizard", "wizard", "bard",
]

## Canon's own roster names come first: Bob (Warrior), Greg (Rogue) and Steve
## (Mage) are the three examples the design notes use to explain morale, and
## seeing them on the opening roster is the game quoting itself back.
##
## Natsuna is deliberately ABSENT: canon makes her a *named Legendary* shaman,
## and "you can only ever find 1 Legendary per class". She is not a starting
## Common and must be found.
const CANON_NAMES := {"warrior": "Bob", "rogue": "Greg", "mage": "Steve"}

## The other nine draw from the ONE name pool (`data/names.json`, docs/04 §7
## "Pool is data, not code"; CONTENT-20). This file used to carry twenty-four
## literals of its own — a second register nobody at the Tavern could ever be
## hired from, and twenty-two of them never went through docs/15 BL-53's
## review. `NamePool.pick(rng, taken)` keeps BL-23's promise (a seed in, the
## same twelve out) because it draws from the rng it is handed. Without the
## pool (a test that stubs the file away) the fallback is the honest
## placeholder, never a literal.
const FALLBACK_NAME := "Recruit %d"


## Build the opening roster. `db` is a loaded ContentDB; `seed_value` makes the
## result reproducible so a save can be regenerated and a bug re-run.
##
## `names` and `stories` are the pools; a caller that holds them (GameState
## caches both) may hand them over, and a caller that does not gets them
## loaded from their default paths — `new_game()` calls with two arguments
## and every starter still gets a name from the register and a backstory.
##
## THE BACKSTORY DRAW (LOOP-17, docs/04 §5 step 7): a starter draws bullets
## exactly as a recruit does, Common's guaranteed-negative first bullet
## included, and carries the offset those bullets add up to — so the Quarters
## line reads "their past" truthfully on day one and the detail page never
## has to say when a backstory "arrives". They open AT that baseline — 45
## plus the offset — exactly as a Tavern hire does (docs/05 §4).
static func build(db, seed_value: int, names = null, stories = null) -> Array:
    var out: Array = []
    if db == null:
        return out

    var rng = Rng.new(seed_value)
    if names == null:
        names = NamePool.load_from()
    if stories == null:
        stories = BackstoryPool.load_from()
    var used := {}
    # Canon's three are RESERVED before anyone draws: the register carries
    # Bob, Greg and Steve too, and a Cleric drawn "Greg" at i=2 would have
    # left canon's Rogue at i=5 with somebody else's name.
    var reserved: Array = CANON_NAMES.values()

    for i in BENCHMARK_COMP.size():
        var class_key: String = BENCHMARK_COMP[i]
        var r = Raider.new()
        r.id = "start_%02d" % i
        r.class_id = Enums.class_from_key(class_key)
        r.rarity = Enums.Rarity.COMMON
        r.recruited_at_rank = Enums.ReputationRank.UNKNOWN
        r.recruited_at_tier = 1

        # Canon's named examples take their own class; everyone else draws from
        # the register. One Warrior is Bob, the other is not.
        var name := ""
        if CANON_NAMES.has(class_key) and not used.has(CANON_NAMES[class_key]):
            name = String(CANON_NAMES[class_key])
        else:
            # The register's BARE form (`root_of`: "Wee Dave" -> "Dave",
            # "Kevin_7" -> "Kevin"): canon's own three are "aggressively
            # ordinary" and the opening twelve read like them. It is also
            # what the roster card can hold — `Cards.card`'s name row is
            # unwrapped, and "Kevin of the Ninefold Path" widens a 215px card
            # to 250 (W9-POLISH owns the card's fit; a hired epithet name
            # shows the same today). The joke names stay the Tavern's.
            name = names.root_of(String(names.pick(rng, used.keys() + reserved)))
            if name.is_empty() or used.has(name) or reserved.has(name):
                name = FALLBACK_NAME % (i + 1)
        used[name] = true
        r.display_name = name

        r.backstory = stories.draw(rng, Enums.Rarity.COMMON, int(r.class_id))
        r.backstory_offset = BackstoryPool.offset_for(r.backstory)

        # docs/05 §4 / §8: a raider arrives at THEIR baseline, not at 50 — the
        # rule `Recruitment.generate` applies to every hire (docs/04 §5 step
        # 8: "the bullets supply doc 05's backstory_offset", and morale is the
        # baseline including it). A Common with no past walks in at 45,
        # "Slightly Annoyed" before anything has gone wrong; one with a past
        # walks in a point or three either side of it, inside the same band.
        # Starting them AT the baseline rather than at 45 is what keeps "a new
        # guild starts at baseline" true (drift has nothing to do on day one;
        # tests/unit/test_rest.gd reads it).
        r.morale = Morale.baseline_of(r, 0)

        for it in db.starting_set(class_key):
            r.equip(db, it)

        out.append(r)
    return out


## The composition as a class-key -> count map, for tests and for the roster
## footer's role tally.
static func composition() -> Dictionary:
    var counts := {}
    for k in BENCHMARK_COMP:
        counts[k] = int(counts.get(k, 0)) + 1
    return counts
