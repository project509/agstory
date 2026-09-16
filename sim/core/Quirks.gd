extends RefCounted
## The Legendary quirk seam: every hook, every one of them a no-op (docs/04 §11.2).
##
## docs/04 §11.2 promises each Legendary "one class-flavoured mechanical gift; specced in
## doc 07, named here". The nine names are authored (`data/legendaries/*.json`), and the
## spec does not exist — `grep -ci quirk docs/07-combat-simulation.md` is 0, and docs/15
## BL-58 refused to invent it ("That is a design pass, not content work"). So the nine
## records carry a `quirk.status` of ❓ OPEN and `SPECS` below is EMPTY.
##
## WHY THIS FILE EXISTS WITH NOTHING IN IT. Without it, the spec pass lands as a refactor:
## somebody has to find the roll sites, decide how a quirk reaches them, and thread a pool
## through `RaidSim.run()`'s argument list, which every sweep and golden caller uses. With
## it, the spec pass is a table — one row per quirk in `SPECS`, and the flag flipped on.
## docs/14 §5.2's rule is the reason it is a flag and not a constant: "The game must boot
## and be completable with every flag off."
##
## THE HOOKS ARE IDENTITY-VALUED AND STAY THAT WAY WHILE `SPECS` IS EMPTY — deliberately,
## even when the flag is ON. A seam that could move a number before anybody wrote the spec
## would move it by accident, and the one golden containing Legendaries
## (tests/golden/e5_legendaries_raid.json) is the ceiling case the balance sweep reads.
## `tests/unit/test_legendaries.gd` asserts both halves: the hooks are identity for all
## nine ids at either flag setting, and that golden's SHA-256 has not moved.
##
## THE HOOKS ARE CALLED (W7-SIM-EFFECTS, Q58-4): each at the site named in `HOOKS`, so the
## spec pass is a `SPECS` table and a flag flip and nothing else. The sim resolves a
## raider's quirk id from `Raider.legendary_def_id` by `expected_id_for` — the convention
## `LegendaryPool._validate_quirk` enforces on every authored file — so no pool travels
## through `RaidSim.run()`; the flag reaches it as `opts["legendary_quirks"]`.
##
## PURE, per docs/14 §3.1. Every function here is static, takes what it needs, and reads
## no clock, tree or RNG. `enabled` is passed IN rather than read from `GameState.flags`
## for the same reason — `sim/` may not know a campaign exists.

const Enums = preload("res://sim/model/Enums.gd")

## docs/14 §5.2's flag id for this seam, and the same string
## `GameState.FLAG_DEFAULTS` declares. Named here so the sim and the campaign cannot
## disagree about which switch they are talking about.
const FLAG_ID := "legendary_quirks"

## The flag's shipped default. docs/15 BL-58 is OPEN, so the honest default is off; the
## spec pass flips it in `GameState.FLAG_DEFAULTS` (and, once docs/14 §5.2's
## `data/tuning/flags.json` exists, there).
const DEFAULT_ENABLED := false

## The four hook names, so a caller can be checked against the seam rather than against a
## memory of it. Each is CALLED at the site named (W7-SIM-EFFECTS):
##   threat_multiplier  RaidSim `_threat_mult()` — every `Formulas.threat_from` result:
##                      the swing's in `_take_action`, the heal's in `_land_heal`, and the
##                      mistaken swing's in `_swing_into_the_wrong_target`
##   relief_bp_bonus    RaidSim `_relief_bp()`, which docs/11 §7's Steady Hands feeds
##   tank_priority      RaidSim `_assign_tanks()`, the Warriors' main-tank order
##   immune_to          Mistakes `eligible_types()`, through `Context.quirk_id`
const HOOKS := ["threat_multiplier", "relief_bp_bonus", "tank_priority", "immune_to"]


## quirk id -> spec. EMPTY, and a test asserts it: docs/15 BL-58 must be DECIDED before a
## row appears here, because a quirk is a permanent buff on the rarity that is already the
## best in the game. docs/07 §5.3's warning is the specific trap — "treat every mistake
## percentage in the project as unanchored and do not tune against it" — so a row
## expressed as a mistake-chance delta needs doc 08 §12 amended first.
##
## Shape the spec pass should fill in (one key per hook it uses, absent means identity):
##   {"threat_multiplier": 0.85, "relief_bp": 120.0, "tank_priority": 1,
##    "immune": ["MIS_CHAIN_FIZZLE"]}
const SPECS := {}


## True only when the flag is on AND somebody has written a spec for this quirk. Both
## halves matter: the flag alone must not make an unspecced quirk do something, and a spec
## alone must not fire while docs/15 BL-58 is open.
static func is_live(quirk_id: String, enabled: bool) -> bool:
    return enabled and SPECS.has(quirk_id)


## The spec for one quirk, or {} — which every hook below reads as "identity".
static func spec_of(quirk_id: String, enabled: bool) -> Dictionary:
    if not is_live(quirk_id, enabled):
        return {}
    var row: Dictionary = SPECS[quirk_id]
    return row.duplicate(true)


## The canonical quirk id for a class, and the shape `LegendaryPool._validate()` enforces.
## Derived rather than read so a caller can check the data against the convention instead
## of trusting it.
static func expected_id_for(class_id: int) -> String:
    return "quirk_%s" % Enums.class_key(class_id)


# ---------------------------------------------------------------- the four hooks

## Multiplies the threat a Legendary generates. 1.0 is identity.
## The site is real: `Formulas.threat_from()` feeds `c.add_threat()` and
## `_pick_enemy_target()` picks the top of the table, so quirk_rogue's "draws less
## attention than the numbers say" is expressible here and nowhere else.
static func threat_multiplier(quirk_id: String, enabled: bool) -> float:
    var spec := spec_of(quirk_id, enabled)
    return float(spec.get("threat_multiplier", 1.0))


## Extra mistake relief in basis points, added to `RaidSim._relief_bp()`. 0.0 is identity.
## docs/11 §7's Steady Hands already feeds that parameter, which is why quirk_monk's
## "notices a mechanic one beat before anyone else" needs no new plumbing — but see
## docs/07 §5.3 before choosing a magnitude.
static func relief_bp_bonus(quirk_id: String, enabled: bool) -> float:
    var spec := spec_of(quirk_id, enabled)
    return float(spec.get("relief_bp", 0.0))


## A bump in the main-tank order used by `_assign_tanks()`. 0 is identity — the existing
## Warrior-first, Monk-offtank, most-HP-backstop order stands untouched.
## quirk_warrior's "never yields the main-tank slot" and one reading of quirk_druid's
## "covers whichever role the party is short of" both land here.
static func tank_priority(quirk_id: String, enabled: bool) -> int:
    var spec := spec_of(quirk_id, enabled)
    return int(spec.get("tank_priority", 0))


## Whether a quirk removes one docs/07 §5.2 mistake type from `Mistakes.eligible_types()`.
## false is identity. This is the hook shape docs/04:397's own worked example already
## assumes — Natsuna's `chain_heal_never_misses_third_target`, which is MIS_CHAIN_FIZZLE
## by another name.
static func immune_to(quirk_id: String, type_id: String, enabled: bool) -> bool:
    var spec := spec_of(quirk_id, enabled)
    var immune: Array = spec.get("immune", [])
    return immune.has(type_id)
