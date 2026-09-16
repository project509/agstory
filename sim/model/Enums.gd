class_name TwgEnums
extends RefCounted
## Shared vocabulary for the whole game: classes, rarities, slots, stats, roles,
## item families, encounter kinds and reputation ranks.
##
## Sources:
##   docs/06-classes-and-roles.md §8   — class × role × family quick reference
##   docs/09-items-and-itemization.md §3–4 — slot list and sharing groups
##   docs/03-guild-reputation.md       — the six-rank ladder
##   docs/_source/                     — canon for every name below
##
## This file is vocabulary ONLY. It deliberately holds no per-class stats, no
## slot-availability rules and no probabilities — those are data (data/*.json)
## so they can be tuned without a code change.
##
## Every enum has three parallel forms:
##   the enum value      (fast, used in the sim)
##   a stable string key (used in JSON and save games — NEVER rename these)
##   a display name      (shown to the player)
##
## The string keys are a persistence contract. Renaming one silently breaks
## every save file and every content JSON. Add new members at the END.

# ---------------------------------------------------------------- canon constants

## Raid size (canon: raw notes — "I've also decided I'd like the raid size to be
## 12, most fights normally requiring 2 tanks").
const RAID_SIZE := 12
const TYPICAL_TANKS := 2

## Encounters per raid tier (canon: raw notes, *Raid Layout and loot drops*).
const ENCOUNTERS_PER_RAID := 5

## Morale runs 0-100 in ten bands of ten (canon: raw notes, *Morale: 0-100*).
const MORALE_MIN := 0
const MORALE_MAX := 100
const MORALE_BAND_COUNT := 10
const MORALE_BAND_WIDTH := 10

# ---------------------------------------------------------------- classes

## The nine canon classes (canon: raw notes, *Classes*).
enum CharClass { WARRIOR, MONK, ROGUE, CLERIC, DRUID, SHAMAN, BARD, MAGE, WIZARD }

const CLASS_KEYS := [
    "warrior", "monk", "rogue", "cleric", "druid", "shaman", "bard", "mage", "wizard",
]
const CLASS_NAMES := [
    "Warrior", "Monk", "Rogue", "Cleric", "Druid", "Shaman", "Bard", "Mage", "Wizard",
]

# ---------------------------------------------------------------- rarity

## Raider quality tiers. Distinct from the *chance of finding* one, which is
## reputation's business (docs/03). Common is the floor, Legendary is one per
## class ever and always a named character.
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const RARITY_KEYS := ["common", "uncommon", "rare", "epic", "legendary"]
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

# ---------------------------------------------------------------- slots

## Seven slots, no more (docs/09 §3.2). Canon drops exactly these seven
## slot-types across a tier's five encounters, so one tier fully gears a raider.
## Adding a slot means adding a drop source, which changes the raid shape.
enum Slot { MAIN_HAND, OFF_HAND, HEAD, CHEST, LEGS, FEET, TRINKET }

const SLOT_KEYS := [
    "main_hand", "off_hand", "head", "chest", "legs", "feet", "trinket",
]
const SLOT_NAMES := [
    "Main Hand", "Off Hand", "Head", "Chest", "Legs", "Feet", "Trinket",
]

## The three body-armor slots the matrix collapses into one column.
const BODY_SLOTS := [Slot.CHEST, Slot.LEGS, Slot.FEET]

## Slots that hold armor (as opposed to weapons/off-hands/trinkets).
const ARMOR_SLOTS := [Slot.HEAD, Slot.CHEST, Slot.LEGS, Slot.FEET]

# ---------------------------------------------------------------- stats

## The five stats that appear on items (canon: ideaboard §2 headers; raw notes).
## What they RESOLVE to numerically is docs/08's business, not this file's.
enum StatKind { AC, HP, POWER, MANA, DAMAGE }

const STAT_KEYS := ["ac", "hp", "power", "mana", "damage"]
const STAT_NAMES := ["AC", "HP", "Power", "Mana", "Damage"]

# ---------------------------------------------------------------- roles

## Canon role strings, verbatim, one per class (canon: raw notes, *Classes*).
enum Role {
    MAIN_TANK,             # Warrior
    MELEE_DPS_OFFTANK,     # Monk
    MELEE_DPS,             # Rogue
    MAIN_TANK_HEALER,      # Cleric
    RAID_HEALER,           # Druid
    CHAIN_HEALER,          # Shaman
    SUPPORT,               # Bard
    AOE_CASTER,            # Mage
    SINGLE_TARGET_CASTER,  # Wizard
}

const ROLE_KEYS := [
    "main_tank", "melee_dps_offtank", "melee_dps", "main_tank_healer",
    "raid_healer", "chain_healer", "support", "aoe_caster", "single_target_caster",
]
const ROLE_NAMES := [
    "Main Tank", "Melee DPS / Offtank", "Melee DPS", "Main Tank Healer",
    "Raid Healer", "Chain Healer", "Support", "AoE Caster", "Single-Target Caster",
]

## Coarse grouping used by raid-composition validation (docs/06 §7).
## Canon requires 12 raiders with "most fights normally requiring 2 tanks", so
## comp checks need buckets, not the nine specific roles.
enum RoleGroup { TANK, HEALER, DPS, SUPPORT }

const ROLE_GROUP_KEYS := ["tank", "healer", "dps", "support"]
const ROLE_GROUP_NAMES := ["Tank", "Healer", "DPS", "Support"]

## Role -> RoleGroup. Monk is Melee DPS / Offtank: it counts as DPS here and can
## be pressed into tanking situationally, which is a sim behaviour (docs/07),
## not a comp-slot claim.
const ROLE_TO_GROUP := {
    Role.MAIN_TANK: RoleGroup.TANK,
    Role.MELEE_DPS_OFFTANK: RoleGroup.DPS,
    Role.MELEE_DPS: RoleGroup.DPS,
    Role.MAIN_TANK_HEALER: RoleGroup.HEALER,
    Role.RAID_HEALER: RoleGroup.HEALER,
    Role.CHAIN_HEALER: RoleGroup.HEALER,
    Role.SUPPORT: RoleGroup.SUPPORT,
    Role.AOE_CASTER: RoleGroup.DPS,
    Role.SINGLE_TARGET_CASTER: RoleGroup.DPS,
}

# ---------------------------------------------------------------- mistakes

## How badly the roll failed (docs/07 §5.4). Severity has to correlate with the
## margin of failure, or a game with this many rolls flattens into noise where
## every mistake feels the same size.
enum Severity { MINOR, MODERATE, SEVERE, CRITICAL }

const SEVERITY_KEYS := ["minor", "moderate", "severe", "critical"]
const SEVERITY_NAMES := ["Minor", "Moderate", "Severe", "Critical"]

## What each band means, for log lines and the post-mortem.
const SEVERITY_MEANING := [
    "Embarrassing, costs a little",
    "Costs a round or a chunk of HP",
    "Someone will probably die from this",
    "This is how wipes start",
]

## Where a mistake was rolled (docs/07 §5.3). Three sites, deliberately not one:
## encounter difficulty should come from how much the fight ASKS of people, which
## is docs/10's design surface. Under per-round rolling a boss that demands four
## responses is no more dangerous than one that demands nothing.
enum RollSite { ACTION, MECHANIC, AMBIENT }

const ROLL_SITE_KEYS := ["action", "mechanic", "ambient"]

static func severity_key(v: int) -> String: return _key_at(SEVERITY_KEYS, v)
static func severity_name_of(v: int) -> String: return _name_at(SEVERITY_NAMES, v)
static func severity_from_key(k: String) -> int: return _index_of(SEVERITY_KEYS, k)
static func roll_site_key(v: int) -> String: return _key_at(ROLL_SITE_KEYS, v)

# ---------------------------------------------------------------- combat log

## What kind of thing happened (docs/07 §10.1). The log IS the game's output —
## the player reads it more than any other screen and it carries the comedy.
enum Verb { ATTACK, HEAL, MECHANIC, MISTAKE, STATE_CHANGE, PHASE, SYSTEM }

const VERB_KEYS := [
    "attack", "heal", "mechanic", "mistake", "state_change", "phase", "system",
]

## Verbosity tiers (docs/07 §10.2). The sim ALWAYS emits everything; tier is a
## display filter over one complete log. Emitting differently per tier would
## make the log a source of divergence.
enum LogTier { STORY, PLAY_BY_PLAY, NUMBERS, DEBUG }

const LOG_TIER_KEYS := ["story", "play_by_play", "numbers", "debug"]
const LOG_TIER_NAMES := ["Story", "Play-by-play", "Numbers", "Debug"]

## Round phases (docs/07 §4.1). Ordering matters: it is the sim's turn order and
## the log's secondary sort key.
enum Phase {
    ROUND_OPEN,      # 0  script events, mechanic announcements, threat snapshot
    BOSS,            # 1  boss acts, reads LIVE threat, damage applied at once
    TANKS,           # 2  main tank then offtank
    DPS,             # 3  melee, then casters, then Bard
    HEALERS,         # 4  single-target, then chain, then raid-wide
    EFFECTS,         # 5  DoTs, HoTs, ground effects, durations tick
    AMBIENT_MISTAKE, # 6  one roll per living raider for non-action failures
    ROUND_CLOSE,     # 7  confirm deaths, check wipe, check encounter end
}

const PHASE_KEYS := [
    "round_open", "boss", "tanks", "dps", "healers",
    "effects", "ambient_mistake", "round_close",
]
const PHASE_NAMES := [
    "Round Open", "Boss", "Tanks", "DPS", "Healers",
    "Effects", "Ambient", "Round Close",
]

static func verb_key(v: int) -> String: return _key_at(VERB_KEYS, v)
static func verb_from_key(k: String) -> int: return _index_of(VERB_KEYS, k)
static func phase_key(v: int) -> String: return _key_at(PHASE_KEYS, v)
static func phase_name_of(v: int) -> String: return _name_at(PHASE_NAMES, v)
static func phase_from_key(k: String) -> int: return _index_of(PHASE_KEYS, k)
static func log_tier_key(v: int) -> String: return _key_at(LOG_TIER_KEYS, v)

# ---------------------------------------------------------------- mechanics

## The mechanic vocabulary (docs/10 §10). Five tiers of eight encounters is 40
## fights; a small team builds that by recombining twelve parameterised
## mechanics, not by inventing eighty. Content configures; docs/07 implements
## each behaviour exactly once.
enum Mechanic {
    TANK_SWAP,        # M01
    RAID_WIDE,        # M02
    GROUND_EFFECT,    # M03
    ADD_SPAWNS,       # M04
    INTERRUPT_CHECK,  # M05
    ENRAGE,           # M06
    POSITIONING,      # M07
    FIXATE,           # M08
    HEALING_DEBUFF,   # M09
    MANA_BURN,        # M10
    FRONTAL_CLEAVE,   # M11
    ESCALATING_SWING, # M12
}

## Keys keep the doc's M-numbers so a stat block reads against docs/10 §10.
const MECHANIC_KEYS := [
    "m01", "m02", "m03", "m04", "m05", "m06",
    "m07", "m08", "m09", "m10", "m11", "m12",
]
const MECHANIC_NAMES := [
    "Tank Swap", "Raid-Wide Damage", "Avoidable Ground Effect", "Add Spawns",
    "Interrupt Check", "Enrage Timer", "Positioning Requirement", "Fixate",
    "Healing Debuff", "Mana Burn", "Frontal Cleave", "Escalating Swing",
]

## Which role group each mechanic is built to stress. docs/10 §10's coverage
## rule requires every tier to stress all four groups before its E5, or a tier
## can be beaten by one lopsided roster and the Tavern stops mattering.
const MECHANIC_STRESSES := {
    Mechanic.TANK_SWAP: RoleGroup.TANK,
    Mechanic.RAID_WIDE: RoleGroup.HEALER,
    Mechanic.GROUND_EFFECT: RoleGroup.DPS,
    Mechanic.ADD_SPAWNS: RoleGroup.DPS,
    Mechanic.INTERRUPT_CHECK: RoleGroup.DPS,
    Mechanic.ENRAGE: RoleGroup.DPS,
    Mechanic.POSITIONING: RoleGroup.DPS,
    Mechanic.FIXATE: RoleGroup.HEALER,
    Mechanic.HEALING_DEBUFF: RoleGroup.HEALER,
    Mechanic.MANA_BURN: RoleGroup.SUPPORT,
    Mechanic.FRONTAL_CLEAVE: RoleGroup.TANK,
    Mechanic.ESCALATING_SWING: RoleGroup.TANK,
}

static func mechanic_key(v: int) -> String:
    return _key_at(MECHANIC_KEYS, v)

static func mechanic_name_of(v: int) -> String:
    return _name_at(MECHANIC_NAMES, v)

static func mechanic_from_key(k: String) -> int:
    return _index_of(MECHANIC_KEYS, k)

# ---------------------------------------------------------------- positioning

## The whole position model, and deliberately the smallest one that answers
## docs/10 §10 M07 ("Fight demands Spread or Stack for `N` rounds").
##
## docs/07 OQ-7 asks whether the sim needs a position layer at all, and docs/15's
## question table carries the recommendation this implements — "abstract flags
## only. No grid, no coordinates" — in the recommendation column, never marked
## DECIDED. So the ruling is proposed in build/plan/q-mech-arms.md and the model
## is built to it: two named states, no coordinates, no distances, nothing else
## about space representable. docs/02's core claim is that the player is not in
## the raid, and coordinates would be state they can neither see nor influence.
enum Stance { SPREAD, STACKED }

const STANCE_KEYS := ["spread", "stacked"]
const STANCE_NAMES := ["Spread", "Stacked"]

static func stance_key(v: int) -> String:
    return _key_at(STANCE_KEYS, v)

static func stance_name_of(v: int) -> String:
    return _name_at(STANCE_NAMES, v)

static func stance_from_key(k: String) -> int:
    return _index_of(STANCE_KEYS, k)

# ---------------------------------------------------------------- combat state

## docs/07 §7.1. Downed exists because the round resolves sequentially with boss
## damage before healing: without a grace state healers structurally could not
## save anyone from a big hit, and the clutch heal would never happen.
enum CombatState { ALIVE, DOWNED, DEAD }

const COMBAT_STATE_KEYS := ["alive", "downed", "dead"]
const COMBAT_STATE_NAMES := ["Alive", "Downed", "Dead"]

## Consequence tokens (docs/07 §6). A mistake emits tokens; later roll sites in
## the same encounter see them. This is what turns four small failures into one
## wipe with a story, rather than one person's fault.
enum Token { AGGRO, FIRE, MANA, ADDS, DISTRACTION }

const TOKEN_KEYS := ["aggro", "fire", "mana", "adds", "distraction"]
const TOKEN_NAMES := ["Aggro", "Fire", "Mana", "Adds", "Distraction"]

## Rounds a token stays live. -1 means it persists until something clears it
## explicitly (the raider leaves the fire; the add dies) rather than expiring.
## docs/07 §6: Aggro = this round + next; Distraction = 2 rounds;
## Mana = rest of encounter; Fire and Adds = until cleared.
const TOKEN_DURATION := {
    Token.AGGRO: 2,
    Token.FIRE: -1,
    Token.MANA: -1,
    Token.ADDS: -1,
    Token.DISTRACTION: 2,
}

static func combat_state_key(v: int) -> String:
    return _key_at(COMBAT_STATE_KEYS, v)

static func token_key(v: int) -> String:
    return _key_at(TOKEN_KEYS, v)

static func token_from_key(k: String) -> int:
    return _index_of(TOKEN_KEYS, k)

# ---------------------------------------------------------------- raider status

## Roster membership. `departed` and `fired` rows are retained for the guild log
## and excluded from the roster cap (docs/04 §4).
enum RaiderStatus { ACTIVE, BENCHED, DEPARTED, FIRED }

const RAIDER_STATUS_KEYS := ["active", "benched", "departed", "fired"]
const RAIDER_STATUS_NAMES := ["Active", "Benched", "Departed", "Fired"]

# ---------------------------------------------------------------- morale bands

## The ten canon morale bands (canon: raw notes, *Morale: 0-100*).
##
## Canon names bands 70-80 and 80-90 BOTH "Very Happy". docs/15 Q-07 resolved
## the duplicate by renaming 70-80 to "Quite Happy" so ten bands carry ten
## names; 80-90 keeps "Very Happy" so canon's own roster example (Natsuna at 87,
## "Very Happy") still reads correctly.
##
## Bands are half-open and lower-inclusive (docs/15 Q-06):
##     band_index = min(9, floor(morale / 10))
## Canon writes them as 0-10, 10-20, ... which overlaps at every tens value;
## this is the unambiguous reading.
const MORALE_BAND_NAMES := [
    "Very Upset",       # 0-10
    "Upset",            # 10-20
    "Unhappy",          # 20-30
    "Annoyed",          # 30-40
    "Slightly Annoyed", # 40-50
    "Content",          # 50-60   <- canon's "Base mistake chance"
    "Happy",            # 60-70
    "Quite Happy",      # 70-80   <- renamed from a duplicate "Very Happy"
    "Very Happy",       # 80-90
    "Loves Their Guild",# 90-100
]

## Emoji shown beside the number on the roster (canon shows one per raider).
##
## FOUR OF THESE ARE CANON and are pinned by test_morale.gd, because canon's
## example roster prints the exact face for an exact value:
##     Natsuna 87 ❤  (band 8)   Bob 54 🙂 (band 5)
##     Greg    31 😒 (band 3)   Steve 14 😡 (band 1)
##
## Band 8 is ❤, NOT band 9. An earlier table had the heart one band too high,
## which made canon's own headline row render wrong; the remaining six faces are
## 🔷 PROPOSED and chosen to keep the ramp monotone around the fixed four.
const MORALE_BAND_EMOJI := ["🤬", "😡", "😞", "😒",
    "😐", "🙂", "😄", "😊", "❤", "💖"]

## The canon morale band for a value, as a band index 0-9.
static func morale_band(morale: int) -> int:
    var m: int = clampi(morale, MORALE_MIN, MORALE_MAX)
    return mini(MORALE_BAND_COUNT - 1, m / MORALE_BAND_WIDTH)

static func morale_band_name(morale: int) -> String:
    return MORALE_BAND_NAMES[morale_band(morale)]

static func morale_band_emoji(morale: int) -> String:
    return MORALE_BAND_EMOJI[morale_band(morale)]

static func raider_status_key(v: int) -> String:
    return _key_at(RAIDER_STATUS_KEYS, v)

static func raider_status_from_key(k: String) -> int:
    return _index_of(RAIDER_STATUS_KEYS, k)

# ---------------------------------------------------------------- item families

## An item family is a CONTENTION group: when an item drops, the family decides
## which raiders raise their hand (docs/09 §4). This is what makes loot a
## decision and therefore what makes the wishlist/morale lever work.
enum ItemFamily {
    # Armor sharing groups (canon: ideaboard §1 observations)
    WARRIOR_BARD_ARMOR,    # chest/legs/feet — Warrior, Bard
    MONK_ROGUE_ARMOR,      # chest/legs/feet — Monk, Rogue
    HEALER_ARMOR,          # head + body     — Cleric, Druid, Shaman
    MAGE_WIZARD_ARMOR,     # head + body     — Mage, Wizard
    # Head families the matrix splits out separately.
    # docs/09 §4.4 flagged a canon contradiction here: the slot matrix gives
    # Warrior a head family of its own, but every item table ships a SHARED
    # helm (Adventure "Iron Adventurer's Helm" under a "Warrior / Bard Armor"
    # heading; Raid "Raider's Helm" identical on both class tables). Resolved
    # in favour of the item tables — a Warrior-only head family has no item
    # behind it at any rung and would leave Warriors a slot they cannot fill.
    # See docs/15-open-questions.md BL-19.
    WARRIOR_BARD_HEAD,     # Warrior + Bard
    MONK_HEAD,             # Monk Headband
    ROGUE_HEAD,            # Rogue Eyepatch
    # Weapons
    WRB_ONE_HAND,          # Warrior/Rogue/Bard 1H — highest contention weapon
    MONK_TWO_HAND,
    MAGE_TWO_HAND,
    WIZARD_TWO_HAND,
    CLERIC_WEAPON,
    DRUID_WEAPON,
    SHAMAN_WEAPON,
    # Off-hands
    WARRIOR_SHIELD,
    HEALER_OFF_HAND,
    INSTRUMENT,
    # Trinkets
    UNIVERSAL_TRINKET,     # all nine classes — the 9-way contention family
}

const FAMILY_KEYS := [
    "warrior_bard_armor", "monk_rogue_armor", "healer_armor", "mage_wizard_armor",
    "warrior_bard_head", "monk_head", "rogue_head",
    "wrb_one_hand", "monk_two_hand", "mage_two_hand", "wizard_two_hand",
    "cleric_weapon", "druid_weapon", "shaman_weapon",
    "warrior_shield", "healer_off_hand", "instrument",
    "universal_trinket",
]
const FAMILY_NAMES := [
    "Warrior/Bard Armor", "Monk/Rogue Armor", "Healer Armor", "Mage/Wizard Armor",
    "Warrior/Bard Head", "Monk Headband", "Rogue Eyepatch",
    "Warrior/Rogue/Bard 1H", "2H Monk Weapon", "2H Mage Staff", "2H Wizard Staff",
    "Cleric Weapon", "Druid Weapon", "Shaman Weapon",
    "Warrior Shield", "Healer Off-Hand", "Instrument",
    "Universal Trinket",
]

## Which classes compete for each family (canon: ideaboard §1, inverse table in
## docs/09 §4.2). Loot routing reads this; nothing else should hardcode it.
const FAMILY_CLAIMANTS := {
    ItemFamily.WARRIOR_BARD_ARMOR: [CharClass.WARRIOR, CharClass.BARD],
    ItemFamily.MONK_ROGUE_ARMOR: [CharClass.MONK, CharClass.ROGUE],
    ItemFamily.HEALER_ARMOR: [CharClass.CLERIC, CharClass.DRUID, CharClass.SHAMAN],
    ItemFamily.MAGE_WIZARD_ARMOR: [CharClass.MAGE, CharClass.WIZARD],
    ItemFamily.WARRIOR_BARD_HEAD: [CharClass.WARRIOR, CharClass.BARD],
    ItemFamily.MONK_HEAD: [CharClass.MONK],
    ItemFamily.ROGUE_HEAD: [CharClass.ROGUE],
    ItemFamily.WRB_ONE_HAND: [CharClass.WARRIOR, CharClass.ROGUE, CharClass.BARD],
    ItemFamily.MONK_TWO_HAND: [CharClass.MONK],
    ItemFamily.MAGE_TWO_HAND: [CharClass.MAGE],
    ItemFamily.WIZARD_TWO_HAND: [CharClass.WIZARD],
    ItemFamily.CLERIC_WEAPON: [CharClass.CLERIC],
    ItemFamily.DRUID_WEAPON: [CharClass.DRUID],
    ItemFamily.SHAMAN_WEAPON: [CharClass.SHAMAN],
    ItemFamily.WARRIOR_SHIELD: [CharClass.WARRIOR],
    ItemFamily.HEALER_OFF_HAND: [CharClass.CLERIC, CharClass.DRUID, CharClass.SHAMAN],
    ItemFamily.INSTRUMENT: [CharClass.BARD],
    ItemFamily.UNIVERSAL_TRINKET: [
        CharClass.WARRIOR, CharClass.MONK, CharClass.ROGUE, CharClass.CLERIC,
        CharClass.DRUID, CharClass.SHAMAN, CharClass.BARD, CharClass.MAGE,
        CharClass.WIZARD,
    ],
}

# ---------------------------------------------------------------- encounters

## The five-encounter raid shape (canon: raw notes, *Raid Layout and loot drops*).
enum EncounterKind { TRASH, HARD_TRASH, MINI_BOSS, MAIN_BOSS }

const ENCOUNTER_KIND_KEYS := ["trash", "hard_trash", "mini_boss", "main_boss"]
const ENCOUNTER_KIND_NAMES := ["Trash", "Harder Trash", "Mini Boss", "Main Boss"]

## Canon difficulty stars per encounter slot, 1-indexed by encounter number.
const ENCOUNTER_STARS := [0, 1, 2, 3, 4, 5]

# ---------------------------------------------------------------- reputation

## The single primary guild stat (canon: raw notes, *Guild Reputation*).
## The player starts at UNKNOWN.
enum ReputationRank { UNKNOWN, KNOWN, RESPECTED, ESTABLISHED, RENOWNED, LEGENDARY }

const REPUTATION_KEYS := [
    "unknown", "known", "respected", "established", "renowned", "legendary",
]
const REPUTATION_NAMES := [
    "Unknown", "Known", "Respected", "Established", "Renowned", "Legendary",
]

# ---------------------------------------------------------------- lookup

## Generic key -> index lookup. Returns -1 when the key is unknown so callers
## can report a bad content file rather than silently defaulting to member 0.
static func _index_of(keys: Array, key: String) -> int:
    return keys.find(key)

static func _name_at(names: Array, idx: int) -> String:
    if idx < 0 or idx >= names.size():
        return "<invalid>"
    return names[idx]

static func _key_at(keys: Array, idx: int) -> String:
    if idx < 0 or idx >= keys.size():
        return ""
    return keys[idx]

static func class_key(v: int) -> String: return _key_at(CLASS_KEYS, v)
static func class_name_of(v: int) -> String: return _name_at(CLASS_NAMES, v)
static func class_from_key(k: String) -> int: return _index_of(CLASS_KEYS, k)

static func rarity_key(v: int) -> String: return _key_at(RARITY_KEYS, v)
static func rarity_name_of(v: int) -> String: return _name_at(RARITY_NAMES, v)
static func rarity_from_key(k: String) -> int: return _index_of(RARITY_KEYS, k)

static func slot_key(v: int) -> String: return _key_at(SLOT_KEYS, v)
static func slot_name_of(v: int) -> String: return _name_at(SLOT_NAMES, v)
static func slot_from_key(k: String) -> int: return _index_of(SLOT_KEYS, k)

static func stat_key(v: int) -> String: return _key_at(STAT_KEYS, v)
static func stat_name_of(v: int) -> String: return _name_at(STAT_NAMES, v)
static func stat_from_key(k: String) -> int: return _index_of(STAT_KEYS, k)

static func role_key(v: int) -> String: return _key_at(ROLE_KEYS, v)
static func role_name_of(v: int) -> String: return _name_at(ROLE_NAMES, v)
static func role_from_key(k: String) -> int: return _index_of(ROLE_KEYS, k)

static func role_group_key(v: int) -> String: return _key_at(ROLE_GROUP_KEYS, v)
static func role_group_name_of(v: int) -> String: return _name_at(ROLE_GROUP_NAMES, v)
static func role_group_from_key(k: String) -> int: return _index_of(ROLE_GROUP_KEYS, k)

static func family_key(v: int) -> String: return _key_at(FAMILY_KEYS, v)
static func family_name_of(v: int) -> String: return _name_at(FAMILY_NAMES, v)
static func family_from_key(k: String) -> int: return _index_of(FAMILY_KEYS, k)

static func encounter_kind_key(v: int) -> String: return _key_at(ENCOUNTER_KIND_KEYS, v)
static func encounter_kind_name_of(v: int) -> String: return _name_at(ENCOUNTER_KIND_NAMES, v)
static func encounter_kind_from_key(k: String) -> int: return _index_of(ENCOUNTER_KIND_KEYS, k)

static func reputation_key(v: int) -> String: return _key_at(REPUTATION_KEYS, v)
static func reputation_name_of(v: int) -> String: return _name_at(REPUTATION_NAMES, v)
static func reputation_from_key(k: String) -> int: return _index_of(REPUTATION_KEYS, k)

# ---------------------------------------------------------------- derived

static func role_group_of(role: int) -> int:
    return ROLE_TO_GROUP.get(role, RoleGroup.DPS)

## Classes that can equip an item of this family.
static func claimants_of(family: int) -> Array:
    return FAMILY_CLAIMANTS.get(family, [])

static func class_can_use_family(char_class: int, family: int) -> bool:
    return char_class in FAMILY_CLAIMANTS.get(family, [])

## Number of classes competing for a family — the "demand" column in docs/09 §4.2.
static func family_demand(family: int) -> int:
    return FAMILY_CLAIMANTS.get(family, []).size()

static func all_classes() -> Array:
    return range(CLASS_KEYS.size())

static func all_rarities() -> Array:
    return range(RARITY_KEYS.size())

static func all_slots() -> Array:
    return range(SLOT_KEYS.size())

static func all_reputation_ranks() -> Array:
    return range(REPUTATION_KEYS.size())
