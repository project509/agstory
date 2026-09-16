extends RefCounted
## The reference fixture: a GameState seeded to what the reference concepts show.
##
## tools/art/refdiff.py scores a live screenshot against the 1536x1024 concepts.
## That score is only about DESIGN fidelity if the data on screen matches too —
## a card reading "Bob — 45" against a reference reading "Bork — Lv. 12" would
## register as layout error when it is test data. So every diff shot is taken
## with this fixture applied, and every value here is traceable to a concept.
##
## Where the concepts are not canon the fixture follows canon and says so; see
## art/ref/specs/00-canon-reconciliation.md for each ruling cited below.
##
##   var Fixture = load("res://tools/fixture_reference.gd")
##   Fixture.apply(state)            # loads content itself if the state has none
##   Fixture.apply(state, null, true) # ...and one recorded attempt at t1_raid_e5 (a wipe)
##   Fixture.apply_clear(state)      # ...and one recorded CLEAR of Adventure 0; returns the seed
##   Fixture.apply_new(state)        # a NEW GUILD: new_game() and nothing else (Day 1)
##   Fixture.apply_play(state)       # a LEGAL Known guild: the ladder walked to A1, the
##                                   # cupboard stocked; returns the seeds per rung
##
## Two fixtures for two questions (W6-SHEETS). `apply` reproduces the CONCEPTS so
## refdiff scores design, and it carries data no player ever sees — "Lv. 12",
## 320 RP at rank Unknown, Day 23 with an empty log (LOOP-01, UI-15). It stays
## byte-identical for tools/diff_all.sh's baselines. `apply_new` and `apply_play`
## are what a player REACHES: every later review's "one look" is on one of them.

const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const ContentDB = preload("res://sim/content/ContentDB.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const Consumables = preload("res://sim/core/Consumables.gd")

## Concept 1 / Concept 3's four front cards. The morale values are canon's own
## headline roster (87 / 54 / 31 / 14 — raw notes, Morale) standing in for the
## reference's non-canon "Low / Okay" words (00 §2.1). "Ranger" maps to Rogue
## (00 §2.2). Levels are display-only in this game (Raider.level).
const CARDS := [
    {"name": "Bork",  "class": "warrior", "level": 12, "morale": 87},
    {"name": "Tiny",  "class": "rogue",   "level": 11, "morale": 14},
    {"name": "Gruk",  "class": "cleric",  "level": 9,  "morale": 54},
    {"name": "Spoof", "class": "mage",    "level": 10, "morale": 31},
]

const GUILD_NAME := "A Guild Story"
const GOLD := 12480            # Concept 1 header chip
const DAY := 23                # Concept 1 header chip
const REPUTATION_POINTS := 320 # Concept 1's gem chip, read as Reputation (00 §2.5)
const SEED := 23               # any fixed value; makes the other eight reproducible

## The mission panel needs a raid to point at. Canon's Tier 1 main boss.
const SELECTED_ENCOUNTER := "t1_raid_e5"

## The clearing fixture's fight. `SELECTED_ENCOUNTER` wipes for the fixture's
## twelve (docs/15 M6-BAL-04: 0 of 8 playtests clear Tier 1), so the Results
## screen's clear branch — the loot hand-out — could never be looked at
## (CRITIC-G12). Adventure 0 is the one fight the game promises is won by the
## squad it hands you (tests/unit/test_tutorials.gd, "adventure zero is won by
## the squad the game hands you": 18+ of 20 seeds).
const CLEAR_SLOT := "A0"
## How many seeds `apply_clear` tries, starting at SEED and stepping by one,
## before giving up. A0 clears ~90% of seeds, so this is never reached unless
## the tutorial's balance changes — in which case failing loudly is the point.
const CLEAR_MAX_SEEDS := 200


## Seeds `state` in place. Returns the content DB so callers that need it
## (portrait lookups, item icons) do not load it twice.
## `with_raid` also runs one attempt at SELECTED_ENCOUNTER with the twelve
## highest-morale raiders and records it, so the raid view and the report have
## a real log, real HP numbers and real loot to show. Deterministic (SEED).
static func apply(state, db = null, with_raid: bool = false):
    if db == null:
        db = state.content if state.get("content") != null else ContentDB.load_all()
    if not db.is_valid():
        push_error("fixture: content failed validation — " + db.error_report())
        return db
    state.set_content(db)
    state.new_game(GUILD_NAME, SEED)

    # The first four seats become the reference cards; canon's benchmark twelve
    # (StartingRoster) fill the rest, so the roster is still a fieldable raid.
    var rest: Array = state.roster.slice(CARDS.size())
    var front: Array = []
    for i in CARDS.size():
        front.append(_make_card(db, CARDS[i], i))
    state.roster = front + rest

    state.gold = GOLD
    state.day = DAY
    state.reputation_points = REPUTATION_POINTS
    state.selected_encounter_id = SELECTED_ENCOUNTER

    state.gold_changed.emit(state.gold)
    state.roster_changed.emit()

    if with_raid:
        var enc = db.encounter(SELECTED_ENCOUNTER)
        if enc != null:
            var party: Array = state.roster.duplicate()
            party.sort_custom(func(x, y) -> bool: return x.morale > y.morale)
            party = party.slice(0, mini(int(enc.party_size), party.size()))
            var loadout: Dictionary = state.build_loadout(party)
            var result = RaidSim.run(party, enc, db, SEED, loadout)
            state.spend_loadout(result.potions_spent)
            state.record_attempt(enc.id, result, party)
    return db


## The base fixture plus one recorded CLEAR of Adventure 0, fought by the party
## `RaidPlan.suggest_party()` picks out of the fixture's roster — the same rule
## RaidPrep seeds a tutorial party with (role first, happiest first), so this is
## the squad the game hands THIS guild. Seeds are tried deterministically from
## SEED upward until the outcome is a clear; the first clearing seed is returned
## so the shot is reproducible and the log can say which seed it was.
##
## Returns -1 (and records nothing) when no seed inside CLEAR_MAX_SEEDS clears,
## or when the slot is missing from content. The caller decides how loud that is.
static func apply_clear(state, db = null) -> int:
    db = apply(state, db, false)
    if db == null or not db.is_valid():
        return -1
    return _record_clear(state, db, CLEAR_SLOT, SEED)


## One recorded CLEAR of the encounter at `slot`, fought by the party
## `RaidPlan.suggest_party()` picks, at the first seed from `first_seed` upward
## (CLEAR_MAX_SEEDS tried) whose outcome is a clear. Returns that seed, or -1
## (and records nothing) when no seed clears or the slot is missing.
static func _record_clear(state, db, slot: String, first_seed: int) -> int:
    var enc = db.encounter_at_slot(slot)
    if enc == null:
        push_error("fixture: no encounter at slot %s" % slot)
        return -1
    var party: Array = RaidPlan.suggest_party(state, enc, db)
    if party.is_empty():
        push_error("fixture: suggest_party picked nobody for %s" % slot)
        return -1
    var loadout: Dictionary = state.build_loadout(party)
    for i in CLEAR_MAX_SEEDS:
        var seed_value: int = first_seed + i
        var result = RaidSim.run(party, enc, db, seed_value, loadout)
        if result == null or not result.cleared():
            continue
        state.selected_encounter_id = String(enc.id)
        state.spend_loadout(result.potions_spent)
        state.record_attempt(enc.id, result, party)
        return seed_value
    push_error("fixture: %s did not clear in %d seeds from %d" % [slot, CLEAR_MAX_SEEDS, first_seed])
    return -1


# ---------------------------------------------------------------- the states a player reaches

## The ladder `apply_play` walks, in the order RaidPlan.ladder() opens it: the
## two tutorials, then Adventure 1. A1 cannot be legally cleared with a
## tutorial unresolved (`RaidPlan.locked_reason` walks every earlier rung), and
## the Tutorial Raid is the ONE RAID the guild has behind it. TR clears rarely
## today (tests/unit/test_tutorials.gd pins it at 1 in 20 until W8-SIM-BALANCE),
## so its seed search runs long; CLEAR_MAX_SEEDS at that rate fails once in
## ~30,000 — and failing loudly is the point.
const PLAY_LADDER := ["A0", "TR", "A1"]
## Two of each consumable in the cupboard (UI-39's fixture half), at tier 1 —
## the only grade the Market stocks below Known.
const PLAY_STOCK := 2
## Coin the guild is handed before it shops, through `add_gold()` so the
## lifetime-income counter agrees with the purse (LESSONS: a cap is a share of
## something). Two of each tier-1 SKU is 416 G; docs/01 §8.0's 60 G could not
## buy it, and the three clears pay 16 G between them.
const PLAY_PURSE := 500


## Reputation the guild holds BEFORE it walks the ladder, derived so that the
## three first clears (data/reputation.json's tutorial and adventure awards,
## through `Reputation.award_for`) land the A1 clear on Known's threshold
## exactly — the clear on the log is the promotion, and the Board's "N more to
## Respected" is a true number. The one figure `apply_play` SETS rather than
## earns, and it is computed from the tables rather than typed (LESSONS: a
## hardcoded tuning number forbids its own correction).
static func play_rp_before(db) -> int:
    var paid := 0
    for slot in PLAY_LADDER:
        var enc = db.encounter_at_slot(String(slot))
        if enc != null:
            paid += Reputation.award_for(enc, 1, 1, false)
    return maxi(0, Reputation.rp_floor(Enums.ReputationRank.KNOWN) - paid)


## A new guild and nothing else: `GameState.new_game()` exactly as the main
## menu calls it (the name decides the seed), so the shot is Day 1 as the
## player sees it — the starting roster, docs/01 §8.0's 60 G, rank Unknown,
## Adventure 0 open, nothing on the log. Returns the content DB.
static func apply_new(state, db = null):
    if db == null:
        db = state.content if state.get("content") != null else ContentDB.load_all()
    if not db.is_valid():
        push_error("fixture: content failed validation — " + db.error_report())
        return db
    state.set_content(db)
    state.new_game(GUILD_NAME)
    return db


## A legal save a few days in: the starting roster (no `level` anywhere), two of
## each consumable bought at the Market, then the ladder cleared to Adventure 1
## through the game's own verbs — `record_attempt` pays the gold, awards the
## RP, ticks the day, writes the feed row and the morale notes, autosaves — so
## rank Known sits at its threshold, the log has rows, and the Board's next
## rung is A2. Returns `{slot: seed}` for the rungs cleared, or an empty
## Dictionary (and a push_error) when a rung would not clear.
static func apply_play(state, db = null) -> Dictionary:
    db = apply_new(state, db)
    if db == null or not db.is_valid():
        return {}
    state.add_gold(PLAY_PURSE)
    for sku_id in Consumables.SKUS:
        var refused: String = state.buy_consumable(String(sku_id), 1, PLAY_STOCK)
        if not refused.is_empty():
            push_error("fixture: could not stock %s — %s" % [sku_id, refused])
            return {}
    var rp_before: int = play_rp_before(db)
    state.reputation_points = rp_before
    state.rp_earned_lifetime = rp_before
    var seeds: Dictionary = {}
    for slot in PLAY_LADDER:
        var seed_used: int = _record_clear(state, db, String(slot), SEED)
        # Checked against the STATE, not the returned seed: a runtime error
        # inside the sim (a half-edited RaidSim while another unit works)
        # aborts `_record_clear` with a 0, and a `play` shot taken over a
        # guild that never fought would be a sheet that lies.
        var enc = db.encounter_at_slot(String(slot))
        if seed_used < 0 or enc == null or not state.has_cleared(String(enc.id)):
            push_error("fixture: play could not clear %s — the ladder stops here" % slot)
            return {}
        seeds[String(slot)] = seed_used
    return seeds


static func _make_card(db, card: Dictionary, index: int):
    var r = Raider.new()
    r.id = "ref_%02d" % index
    r.display_name = String(card["name"])
    r.class_id = Enums.class_from_key(String(card["class"]))
    r.rarity = Enums.Rarity.COMMON
    r.recruited_at_rank = Enums.ReputationRank.UNKNOWN
    r.recruited_at_tier = 1
    r.level = int(card["level"])
    r.morale = int(card["morale"])
    for it in db.starting_set(String(card["class"])):
        r.equip(db, it)
    return r
