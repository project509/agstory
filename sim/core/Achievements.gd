extends RefCounted
## The quest/achievement board: the record wall, its conditions, and its rewards.
##
## ✅ CANON places a "Quest/achievement board" in the Guildhall and says nothing
## else (canon: raw notes, *Guildhall*; docs/02 §4.1). docs/02 §4.4 proposes the
## shape — "~40 static achievements, each: name, condition, reward", with an
## explicit non-goal of daily/weekly timers — and docs/11 §11 adds the faucet
## spec: five entry types with ship counts 12/10/8/6/4, five reward kinds, and a
## coin total capped at ~15% of lifetime income.
##
## WHY THE BOARD IS NOT A CONTENT FILE IN `ContentDB`. This module owns its own
## JSON the way `sim/core/Reputation.gd` owns `data/reputation.json`: lazily
## loaded by `DEFAULT_PATH`, cached statically, and swappable in memory through
## `override_records()` so a test never writes a file. ContentDB indexes the
## *world* — classes, items, encounters, per tier — and the board is a flat
## table with one consumer. Same reasoning docs/14 §5.1 used to keep the tuning
## tables out of it.
##
## PURITY (docs/14 §3.1, house rule 6). Every function here is static and is a
## function of its arguments plus the shipped table. No Node, no clock, no RNG,
## and no reach into `game/`. The board never *applies* a reward: `claim_grant()`
## returns a description of what to grant and `game/core/GameState.gd` performs
## it — docs/14 OQ-10's division, "the sim reports; `game/` acts".
##
## THE STATE SNAPSHOT is a plain Dictionary built by `snapshot()`, which reads a
## GameState-shaped object by duck typing and never stores it. That keeps the
## evaluator testable against a hand-written Dictionary and keeps the one place
## that knows GameState's field names down to a single function.

const Enums = preload("res://sim/model/Enums.gd")

## docs/03 §9's precedent for a `sim/` table: JSON, not `.tres`, because docs/14
## §5.1's deciding row is "readable by `sim/` without breaking §3" and `.tres`
## needs `ResourceLoader`, which `sim/` is forbidden to call.
const DEFAULT_PATH := "res://data/achievements.json"

## docs/11 §11.1's five entry types and their ship counts. The counts are the
## doc's own column ("Count at ship"), and `validate()` enforces them, so the
## wall cannot quietly shrink to whatever Tier 1 can reach.
const TYPES := ["progress", "mastery", "roster", "comedy", "economy"]
const TYPE_SHIP_COUNTS := {
    "progress": 12, "mastery": 10, "roster": 8, "comedy": 6, "economy": 4,
}

## docs/11 §11.1's total, stated as a constant so a test can assert it rather
## than re-summing the table and agreeing with itself.
const SHIP_TOTAL := 40

## docs/11 §11.2's five reward kinds, in the doc's own row order.
const REWARD_KINDS := ["coin", "furnishing", "reputation", "town_flag", "consumables"]

## docs/11 §11.2's tier-1 coin scale, verbatim: "10 G (Progress) · 25 G (Mastery) ·
## 40 G (Roster) · 120 G (a tier capstone)".
##
## The doc prices FOUR things and Comedy and Economy are not among them. That is
## load-bearing, not an omission this module may fill: an Economy entry paying
## coin would be paying an invented rate. So `validate()` refuses a coin reward
## on a Comedy or Economy entry, and those two types pay in kind instead —
## Furnishings and consumable bundles, whose amounts docs/11 §11.2 does state.
const TYPE_COIN := {"progress": 10, "mastery": 25, "roster": 40}
const CAPSTONE_COIN := 120

## docs/11 §11.2: "Total coin from the board across the whole game is capped at
## ~15% of lifetime income". docs/16 W3.7 repeats it. docs/15 Q-69 (RULED
## 2026-09-15) takes the same share for reputation — the two constants stay
## separate because they are two docs' numbers that happen to agree.
const COIN_CAP_SHARE := 0.15
const RP_CAP_SHARE := 0.15

## docs/03 §7's master gate table (docs/03-guild-reputation.md:434): the
## "Quest/achievement board" appears in the Town-unlock column at **Known**, not
## at game start. Enums.ReputationRank.KNOWN, spelled as the enum rather than 1.
const UNLOCK_RANK := Enums.ReputationRank.KNOWN

## docs/10 §13 row 1: the completion beat fires on "the first clear of Raid 5,
## Encounter 5". Held as tier+slot rather than an encounter id because docs/10
## §2's naming note forbids depending on invented names and the tier-5 file does
## not exist yet — tier and slot are the two things the ladder guarantees.
const COMPLETION_TIER := 5
const COMPLETION_SLOT := "E5"

## docs/10 §13 row 2's "Legendary collection to 9 of 9" — ✅ CANON's "You can only
## ever find 1 Legendary per class". A function and not a `const 9`: the goal is
## the length of the class list, so it cannot drift away from it, and a constant
## expression cannot call `.size()`.
static func legendary_goal() -> int:
    return Enums.CLASS_KEYS.size()

## A record's standing for one guild.
enum State { LOCKED, EARNED, CLAIMED }

## Every condition kind the evaluator implements. docs/11 §11.1's examples that
## need a counter this build does not keep are NOT here and no record may name
## one — `validate()` rejects an unknown kind, which is what stops the wall
## filling with entries that can never fire.
##
## Values are the snapshot/event fields each kind reads, for the reader's sake.
const CONDITION_KINDS := {
    "cleared": "cleared_slots",              # a rung of the ladder, N times
    "cleared_slots": "cleared_slots",        # several rungs of one tier
    "clear_count": "cleared_slots",          # the same rung, repeatedly
    "attempts": "attempt_slots",
    "wipes": "attempt_slots - cleared_slots",
    "flawless_clear": "event.mistakes",
    "full_party_clear": "event.survivors / event.party_size",
    "survivors_at_most": "event.survivors",
    "class_coverage": "roster",
    "legendaries_found": "legendary_classes_found",
    "morale_at_least": "roster",
    "roster_size": "roster",
    "gold_at_least": "gold",
    "gold_earned": "gold_earned_lifetime",
    "items_sold": "items_sold_lifetime",
    "items_upgraded": "items_upgraded_lifetime",
    "facility_tier": "facility_tier",
    "furnishings_placed": "furnishings",
    "reputation_rank": "reputation_rank",
    "crisis_strikes": "crisis_strikes",
    "campaign_complete": "completed",
    "event": "event.name",
}

## The kinds that can only be decided while an attempt is being recorded. They
## read `event` and nothing else, so re-evaluating them against a bare snapshot
## must not silently answer "no" and must not answer "yes" either — it answers
## "not now", and the earned set (which persists) is what remembers.
const EVENT_ONLY_KINDS := [
    "flawless_clear", "full_party_clear", "survivors_at_most", "event",
]

## docs/10 §2's canon placeholder names for the ladder, and its binding note:
## "Every string ships as the canon placeholder — `Adventure 2`, `Raid 1`,
## `Boss 3`. Do not invent lore names." A0 and TR are docs/03 §6.1's own slot
## keys for the two tutorial entries (data/reputation.json `tutorial_awards`).
const TUTORIAL_SLOTS := {"A0": "Adventure 0", "TR": "Tutorial Raid"}


# ---------------------------------------------------------------- the table

## Lazily loaded and cached. Same shape as `Reputation._tables`: a plain
## container, loaded once, replaceable in memory for tests.
static var _records: Array = []
static var _by_id: Dictionary = {}
static var _errors: Array[String] = []
static var _loaded: bool = false


## Reads and validates a candidate file WITHOUT touching the cache, so a test can
## inspect one before installing it. Returns
## `{"records": Array, "errors": Array[String]}`.
##
## Never crashes and never calls `push_error` — ContentDB's stated policy, which
## every loader in `sim/` keeps: collect every problem and keep going, so one bad
## row does not hide the other thirty-nine, and `game/` decides what a broken
## table means.
static func read_records(path: String = DEFAULT_PATH) -> Dictionary:
    var errs: Array[String] = []
    if not FileAccess.file_exists(path):
        errs.append("achievements: %s is missing" % path)
        return {"records": [], "errors": errs}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        errs.append("achievements: %s is not a JSON object" % path)
        return {"records": [], "errors": errs}
    var raw = (parsed as Dictionary).get("achievements", [])
    if typeof(raw) != TYPE_ARRAY:
        errs.append("achievements: %s has no `achievements` array" % path)
        return {"records": [], "errors": errs}
    var list: Array = normalize(raw as Array)
    errs.append_array(validate(list))
    return {"records": list, "errors": errs}


## The shipped wall. Every accessor below goes through here.
static func records() -> Array:
    if not _loaded:
        var result: Dictionary = read_records(DEFAULT_PATH)
        _install(result["records"], result["errors"])
    return _records


static func load_errors() -> Array[String]:
    records()
    return _errors


static func is_valid() -> bool:
    return load_errors().is_empty()


## One record by id, or an empty Dictionary. Empty rather than null so callers
## can `.get()` a default off it without a null check on every line.
static func record(achievement_id: String) -> Dictionary:
    records()
    return _by_id.get(achievement_id, {})


static func has_record(achievement_id: String) -> bool:
    records()
    return _by_id.has(achievement_id)


static func ids() -> Array:
    records()
    var out: Array = _by_id.keys()
    out.sort()
    return out


## The in-memory seam. `Reputation.override_tables()`'s reason applies exactly:
## a test that had to write and delete a file to try an altered wall would be
## slow, order-dependent and capable of leaving the repo dirty.
static func override_records(list: Array) -> void:
    var norm: Array = normalize(list)
    _install(norm, validate(norm))


static func reset_records() -> void:
    _records = []
    _by_id = {}
    _errors = [] as Array[String]
    _loaded = false


static func _install(list: Array, errs: Array) -> void:
    _records = list
    _by_id = {}
    for rec in _records:
        _by_id[String((rec as Dictionary)["id"])] = rec
    var typed: Array[String] = []
    for e in errs:
        typed.append(String(e))
    _errors = typed
    _loaded = true


## JSON numbers arrive as whichever of int/float the parser felt like, and every
## optional key is filled in once here so no evaluator branch has to ask twice.
## Keys beginning with `_` are the file's provenance — JSON has no comments and
## these conditions are not defensible without their citations — and are dropped.
static func normalize(src: Array) -> Array:
    var out: Array = []
    for raw in src:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var r: Dictionary = raw as Dictionary
        var rec: Dictionary = {
            "id": String(r.get("id", "")),
            "type": String(r.get("type", "")),
            "name": String(r.get("name", "")),
            "blurb": String(r.get("blurb", "")),
            "hidden": bool(r.get("hidden", false)),
            "capstone": bool(r.get("capstone", false)),
            "condition": {},
            "reward": {},
        }
        var cond = r.get("condition", {})
        if typeof(cond) == TYPE_DICTIONARY:
            rec["condition"] = _clean(cond as Dictionary)
        var rew = r.get("reward", {})
        if typeof(rew) == TYPE_DICTIONARY:
            rec["reward"] = _clean(rew as Dictionary)
        out.append(rec)
    return out


static func _clean(d: Dictionary) -> Dictionary:
    var out: Dictionary = {}
    for k in d:
        if String(k).begins_with("_"):
            continue
        out[String(k)] = d[k]
    return out


## docs/02 §4.4's "no daily/weekly timers. This is a record wall, not a chore
## list" is a schema rule here, not a convention: a record carrying a timer or a
## repeat key is an error, so the non-goal cannot be reopened by a data edit.
const BANNED_KEYS := ["timer", "expires", "expires_on", "repeatable", "repeat", "daily", "weekly"]


static func validate(list: Array) -> Array[String]:
    var errs: Array[String] = []
    var seen: Dictionary = {}
    var histogram: Dictionary = {}
    for t in TYPES:
        histogram[t] = 0
    for raw in list:
        var rec: Dictionary = raw as Dictionary
        var rid: String = String(rec.get("id", ""))
        if rid.is_empty():
            errs.append("achievements: a record has no `id`")
            continue
        if seen.has(rid):
            errs.append("achievements: `%s` appears twice" % rid)
        seen[rid] = true
        var rtype: String = String(rec.get("type", ""))
        if not TYPES.has(rtype):
            errs.append("achievements: `%s` has type `%s`, which is not one of docs/11 §11.1's five"
                % [rid, rtype])
        else:
            histogram[rtype] = int(histogram[rtype]) + 1
        if String(rec.get("name", "")).is_empty():
            errs.append("achievements: `%s` has no name" % rid)
        for banned in BANNED_KEYS:
            if rec.has(banned):
                errs.append("achievements: `%s` carries `%s` — docs/02 §4.4's non-goal is "
                    % [rid, banned] + "\"no daily/weekly timers\"")
        errs.append_array(_validate_condition(rid, rec.get("condition", {})))
        errs.append_array(_validate_reward(rid, rtype, rec))
    for t in TYPES:
        var want: int = int(TYPE_SHIP_COUNTS[t])
        var got: int = int(histogram[t])
        if got != want:
            errs.append("achievements: %d `%s` entries, docs/11 §11.1 ships %d"
                % [got, t, want])
    return errs


static func _validate_condition(rid: String, cond_v) -> Array[String]:
    var errs: Array[String] = []
    if typeof(cond_v) != TYPE_DICTIONARY:
        errs.append("achievements: `%s` has no condition" % rid)
        return errs
    var cond: Dictionary = cond_v as Dictionary
    var kind: String = String(cond.get("kind", ""))
    if not CONDITION_KINDS.has(kind):
        errs.append("achievements: `%s` needs condition kind `%s`, which the evaluator does "
            % [rid, kind] + "not implement")
    for banned in BANNED_KEYS:
        if cond.has(banned):
            errs.append("achievements: `%s`'s condition carries `%s`" % [rid, banned])
    return errs


static func _validate_reward(rid: String, rtype: String, rec: Dictionary) -> Array[String]:
    var errs: Array[String] = []
    var rew_v = rec.get("reward", {})
    if typeof(rew_v) != TYPE_DICTIONARY:
        errs.append("achievements: `%s` has no reward" % rid)
        return errs
    var rew: Dictionary = rew_v as Dictionary
    var kind: String = String(rew.get("kind", ""))
    if not REWARD_KINDS.has(kind):
        errs.append("achievements: `%s` pays `%s`, which is not one of docs/11 §11.2's five"
            % [rid, kind])
        return errs
    if kind == "coin" or kind == "reputation":
        # Both resolve to a coin figure — `reputation` because docs/03 has never
        # signed off a rate and the fallback is the type's own coin scale
        # (M5-QAB-4). So both need a type docs/11 §11.2 actually prices.
        var expected: int = coin_for(rtype, bool(rec.get("capstone", false)))
        if expected <= 0:
            errs.append("achievements: `%s` is a `%s` entry paying coin, and docs/11 §11.2's "
                % [rid, rtype] + "coin row prices only Progress, Mastery, Roster and a capstone")
        var stated: int = int(rew.get("amount", expected))
        if stated != expected:
            errs.append("achievements: `%s` pays %d G; docs/11 §11.2's scale for a %s%s entry "
                % [rid, stated, "capstone " if bool(rec.get("capstone", false)) else "", rtype]
                + "is %d G" % expected)
    if kind == "furnishing" and String(rew.get("furnishing_id", "")).is_empty():
        errs.append("achievements: `%s` grants a Furnishing with no id" % rid)
    if kind == "consumables" and String(rew.get("consumable_id", "")).is_empty():
        errs.append("achievements: `%s` grants a consumable bundle with no id" % rid)
    if kind == "town_flag" and String(rew.get("flag_id", "")).is_empty():
        errs.append("achievements: `%s` grants a town scene flag with no id" % rid)
    return errs


## docs/11 §11.2's coin scale, as a lookup. Returns 0 for a type the doc does not
## price, which is how `_validate_reward()` catches an invented rate.
static func coin_for(rtype: String, capstone: bool) -> int:
    if capstone:
        return CAPSTONE_COIN
    return int(TYPE_COIN.get(rtype, 0))


# ---------------------------------------------------------------- the snapshot

## Everything the evaluator can read, as plain data.
##
## `state` is duck-typed on purpose: `sim/` may not name a `game/` script (house
## rule: no `class_name` cross-file references, and docs/14 §3.1 forbids the
## dependency in that direction anyway). Every field is read through `_prop()`,
## which returns the fallback for a property the build does not have yet — so
## this function works before and after the lifetime counters land, and the board
## simply reads zero for a counter that does not exist. Those counters are still
## missing and are audit `M5-QAB-5` — without them the ~15% reward caps have no
## denominator, which is the reason the seam exists rather than a hypothetical.
static func snapshot(state) -> Dictionary:
    if state == null:
        return blank_snapshot()
    var snap: Dictionary = blank_snapshot()
    snap["gold"] = int(_prop(state, "gold", 0))
    snap["day"] = int(_prop(state, "day", 1))
    snap["reputation_rank"] = int(_prop(state, "reputation_rank", 0))
    snap["reputation_points"] = int(_prop(state, "reputation_points", 0))
    snap["facility_tier"] = int(_prop(state, "facility_tier", 0))
    snap["crisis_strikes"] = int(_prop(state, "crisis_strikes", 0))
    snap["completed"] = bool(_prop(state, "completed", false))
    snap["gold_earned_lifetime"] = int(_prop(state, "gold_earned_lifetime", 0))
    snap["rp_earned_lifetime"] = int(_prop(state, "rp_earned_lifetime", 0))
    snap["items_sold_lifetime"] = int(_prop(state, "items_sold_lifetime", 0))
    snap["items_upgraded_lifetime"] = int(_prop(state, "items_upgraded_lifetime", 0))

    var legendaries = _prop(state, "legendary_classes_found", [])
    if typeof(legendaries) == TYPE_ARRAY:
        snap["legendaries_found"] = (legendaries as Array).size()

    var furnishings = _prop(state, "furnishings", {})
    if typeof(furnishings) == TYPE_DICTIONARY:
        var placed: int = 0
        for who in (furnishings as Dictionary):
            var owned = (furnishings as Dictionary)[who]
            if typeof(owned) == TYPE_ARRAY:
                placed += (owned as Array).size()
        snap["furnishings_placed"] = placed

    var roster = _prop(state, "roster", [])
    if typeof(roster) == TYPE_ARRAY:
        var classes: Dictionary = {}
        var people: Array = []
        for r in (roster as Array):
            if r == null:
                continue
            var class_id: int = int(_prop(r, "class_id", -1))
            classes[class_id] = true
            people.append({
                "class_id": class_id,
                "rarity": int(_prop(r, "rarity", 0)),
                "morale": float(_prop(r, "morale", 0.0)),
            })
        snap["roster"] = people
        snap["class_coverage"] = classes.size()

    var earned = _prop(state, "achievements_earned", {})
    if typeof(earned) == TYPE_DICTIONARY:
        snap["earned"] = (earned as Dictionary).duplicate()
    var claimed = _prop(state, "achievements_claimed", [])
    if typeof(claimed) == TYPE_ARRAY:
        snap["claimed"] = (claimed as Array).duplicate()

    _fill_ladder(snap, state)
    return snap


## The ladder half of the snapshot: how many times each (tier, slot) rung has
## been cleared and attempted.
##
## Keyed by tier and slot rather than by encounter id because docs/10 §2 note 2
## forbids depending on invented names and only two tiers of content exist —
## a Progress entry for Raid 4 has to survive whatever `t4_raid_e5` ends up
## being called. The key is `"<tier>:<slot>"`; `content` resolves the id.
static func _fill_ladder(snap: Dictionary, state) -> void:
    var content = _prop(state, "content", null)
    var cleared = _prop(state, "cleared", {})
    var attempts = _prop(state, "attempts", {})
    var by_clear: Dictionary = {}
    var by_attempt: Dictionary = {}
    if content == null:
        snap["cleared_slots"] = by_clear
        snap["attempt_slots"] = by_attempt
        return
    var ids_seen: Dictionary = {}
    for source in [cleared, attempts]:
        if typeof(source) == TYPE_DICTIONARY:
            for k in (source as Dictionary):
                ids_seen[String(k)] = true
    for encounter_id in ids_seen:
        var enc = content.encounter(String(encounter_id))
        if enc == null:
            continue
        var key: String = ladder_key(int(enc.tier), String(enc.slot))
        if typeof(cleared) == TYPE_DICTIONARY:
            by_clear[key] = int(by_clear.get(key, 0)) \
                + int((cleared as Dictionary).get(encounter_id, 0))
        if typeof(attempts) == TYPE_DICTIONARY:
            by_attempt[key] = int(by_attempt.get(key, 0)) \
                + int((attempts as Dictionary).get(encounter_id, 0))
    snap["cleared_slots"] = by_clear
    snap["attempt_slots"] = by_attempt


static func blank_snapshot() -> Dictionary:
    return {
        "gold": 0, "day": 1, "reputation_rank": 0, "reputation_points": 0,
        "facility_tier": 0, "crisis_strikes": 0, "completed": false,
        "gold_earned_lifetime": 0, "rp_earned_lifetime": 0,
        "items_sold_lifetime": 0, "items_upgraded_lifetime": 0,
        "legendaries_found": 0, "furnishings_placed": 0, "class_coverage": 0,
        "roster": [], "cleared_slots": {}, "attempt_slots": {},
        "earned": {}, "claimed": [],
    }


static func ladder_key(tier: int, slot: String) -> String:
    return "%d:%s" % [tier, slot]


## A property that may not exist on this build's GameState yet. `in` rather than
## `get()`: `Object.get()` on an undeclared property returns null, which is
## indistinguishable from a declared property that IS null, and the counters this
## reads are landing in a separate handoff.
static func _prop(obj, prop: String, fallback):
    if obj == null:
        return fallback
    if typeof(obj) == TYPE_DICTIONARY:
        return (obj as Dictionary).get(prop, fallback)
    if not (prop in obj):
        return fallback
    var v = obj.get(prop)
    return fallback if v == null else v


# ---------------------------------------------------------------- evaluation

## Every record that is satisfied now and was not already earned, in table order.
##
## `event` is the attempt being recorded, or `{}` when this is a plain re-check
## from a screen. The event-only kinds answer false without one, which is why the
## earned set is persisted rather than recomputed: "cleared it with nobody dead"
## is not a fact the save can rediscover a week later.
static func evaluate(snap: Dictionary, event: Dictionary = {}) -> Array:
    var out: Array = []
    var earned = snap.get("earned", {})
    var already: Dictionary = (earned as Dictionary) if typeof(earned) == TYPE_DICTIONARY else {}
    for raw in records():
        var rec: Dictionary = raw as Dictionary
        var rid: String = String(rec["id"])
        if already.has(rid):
            continue
        if is_satisfied(rec, snap, event):
            out.append(rid)
    return out


static func is_satisfied(rec: Dictionary, snap: Dictionary, event: Dictionary = {}) -> bool:
    var cond_v = rec.get("condition", {})
    if typeof(cond_v) != TYPE_DICTIONARY:
        return false
    var cond: Dictionary = cond_v as Dictionary
    var kind: String = String(cond.get("kind", ""))
    if EVENT_ONLY_KINDS.has(kind) and event.is_empty():
        return false
    match kind:
        "cleared":
            return _ladder_total(snap, "cleared_slots", cond) >= int(cond.get("count", 1))
        "clear_count":
            return _ladder_best(snap, "cleared_slots", cond) >= int(cond.get("count", 1))
        "cleared_slots":
            return _slots_cleared(snap, cond) >= _slots_wanted(cond)
        "attempts":
            return _ladder_total(snap, "attempt_slots", cond) >= int(cond.get("count", 1))
        "wipes":
            var tried: int = _ladder_total(snap, "attempt_slots", cond)
            var won: int = _ladder_total(snap, "cleared_slots", cond)
            return (tried - won) >= int(cond.get("count", 1))
        "flawless_clear":
            return _event_matches(cond, event) and bool(event.get("won", false)) \
                and int(event.get("mistakes", -1)) == 0
        "full_party_clear":
            var size: int = int(event.get("party_size", 0))
            return _event_matches(cond, event) and bool(event.get("won", false)) \
                and size > 0 and int(event.get("survivors", -1)) == size
        "survivors_at_most":
            var alive: int = int(event.get("survivors", -1))
            return _event_matches(cond, event) and bool(event.get("won", false)) \
                and alive >= 0 and alive <= int(cond.get("count", 1))
        "event":
            return String(event.get("name", "")) == String(cond.get("name", "<none>"))
        "class_coverage":
            return int(snap.get("class_coverage", 0)) >= int(cond.get("count", 1))
        "legendaries_found":
            return int(snap.get("legendaries_found", 0)) >= int(cond.get("count", 1))
        "morale_at_least":
            return _morale_holds(snap, cond)
        "roster_size":
            var roster = snap.get("roster", [])
            var n: int = (roster as Array).size() if typeof(roster) == TYPE_ARRAY else 0
            return n >= int(cond.get("count", 1))
        "gold_at_least":
            return int(snap.get("gold", 0)) >= int(cond.get("amount", 1))
        "gold_earned":
            return int(snap.get("gold_earned_lifetime", 0)) >= int(cond.get("amount", 1))
        "items_sold":
            return int(snap.get("items_sold_lifetime", 0)) >= int(cond.get("count", 1))
        "items_upgraded":
            return int(snap.get("items_upgraded_lifetime", 0)) >= int(cond.get("count", 1))
        "facility_tier":
            return int(snap.get("facility_tier", 0)) >= int(cond.get("tier", 1))
        "furnishings_placed":
            return int(snap.get("furnishings_placed", 0)) >= int(cond.get("count", 1))
        "reputation_rank":
            return int(snap.get("reputation_rank", 0)) >= int(cond.get("rank", 1))
        "crisis_strikes":
            return int(snap.get("crisis_strikes", 0)) >= int(cond.get("count", 1))
        "campaign_complete":
            return bool(snap.get("completed", false))
    return false


## Sum over every rung the condition names. A condition with a `tier` and a
## `slot` names one rung; a condition with only a `slot` names that slot at any
## tier, which is how the two tutorial entries (unique slots A0 and TR, tier
## unknown until the file exists) are written without guessing a tier.
static func _ladder_total(snap: Dictionary, field: String, cond: Dictionary) -> int:
    var table = snap.get(field, {})
    if typeof(table) != TYPE_DICTIONARY:
        return 0
    var total: int = 0
    for key in (table as Dictionary):
        if _key_matches(String(key), cond):
            total += int((table as Dictionary)[key])
    return total


## The single busiest matching rung, for "the same encounter N times".
static func _ladder_best(snap: Dictionary, field: String, cond: Dictionary) -> int:
    var table = snap.get(field, {})
    if typeof(table) != TYPE_DICTIONARY:
        return 0
    var best: int = 0
    for key in (table as Dictionary):
        if _key_matches(String(key), cond):
            best = maxi(best, int((table as Dictionary)[key]))
    return best


static func _key_matches(key: String, cond: Dictionary) -> bool:
    var parts: PackedStringArray = key.split(":")
    if parts.size() != 2:
        return false
    if cond.has("tier") and int(parts[0]) != int(cond["tier"]):
        return false
    if cond.has("slot") and String(parts[1]) != String(cond["slot"]):
        return false
    return true


static func _slots_wanted(cond: Dictionary) -> int:
    var listed = cond.get("slots", [])
    var n: int = (listed as Array).size() if typeof(listed) == TYPE_ARRAY else 0
    return int(cond.get("count", n if n > 0 else 1))


static func _slots_cleared(snap: Dictionary, cond: Dictionary) -> int:
    var listed = cond.get("slots", [])
    if typeof(listed) != TYPE_ARRAY:
        return 0
    var table = snap.get("cleared_slots", {})
    if typeof(table) != TYPE_DICTIONARY:
        return 0
    var hit: int = 0
    for slot in (listed as Array):
        var probe: Dictionary = {"slot": String(slot)}
        if cond.has("tier"):
            probe["tier"] = int(cond["tier"])
        if _ladder_total(snap, "cleared_slots", probe) > 0:
            hit += 1
    return hit


## docs/11 §11.1's "Keep a Common at 90+ morale": ONE raider of the named rarity
## at or above the figure, not the roster average. A rarity of -1 (or an absent
## `rarity`) means anybody.
static func _morale_holds(snap: Dictionary, cond: Dictionary) -> bool:
    var roster = snap.get("roster", [])
    if typeof(roster) != TYPE_ARRAY:
        return false
    var want_rarity: int = -1
    if cond.has("rarity"):
        want_rarity = Enums.rarity_from_key(String(cond["rarity"]))
    var floor_v: float = float(cond.get("morale", 100))
    for who in (roster as Array):
        var person: Dictionary = who as Dictionary
        if want_rarity >= 0 and int(person.get("rarity", -1)) != want_rarity:
            continue
        if float(person.get("morale", 0.0)) >= floor_v:
            return true
    return false


## An event condition may narrow to one rung of the ladder. No tier and no slot
## means "any encounter", which is docs/11 §11.1's "Clear an encounter with no
## mistakes".
static func _event_matches(cond: Dictionary, event: Dictionary) -> bool:
    if event.is_empty():
        return false
    if cond.has("tier") and int(event.get("tier", -1)) != int(cond["tier"]):
        return false
    if cond.has("slot") and String(event.get("slot", "")) != String(cond["slot"]):
        return false
    return true


# ---------------------------------------------------------------- state

static func state_of(achievement_id: String, snap: Dictionary) -> int:
    var claimed = snap.get("claimed", [])
    if typeof(claimed) == TYPE_ARRAY and (claimed as Array).has(achievement_id):
        return State.CLAIMED
    var earned = snap.get("earned", {})
    if typeof(earned) == TYPE_DICTIONARY and (earned as Dictionary).has(achievement_id):
        return State.EARNED
    return State.LOCKED


static func state_name(s: int) -> String:
    match s:
        State.CLAIMED:
            return "Claimed"
        State.EARNED:
            return "Earned"
    return "Locked"


## docs/03 §7: the board is a Known-rank town unlock. An unreached gate must
## still say what it is waiting for (docs/13 §7), so this returns the reason
## rather than a bool.
##
## ONE sentence for one wall (LOOP-15): the Records tab's caption, the tab's
## body and the event log's "Records" link all print this and nothing of their
## own. The old three disagreed — one said "there is nothing to record until
## you have raided", which was false after the first raid at Unknown (raids
## ARE recorded; the feed shows the wipe) — and "the record wall" is what the
## player is looking at, where "the board" could be read as the Adventure's.
static func unlock_reason(snap: Dictionary) -> String:
    if int(snap.get("reputation_rank", 0)) >= UNLOCK_RANK:
        return ""
    return "The record wall opens at %s." % Enums.reputation_name_of(UNLOCK_RANK)


static func earned_count(snap: Dictionary) -> int:
    var earned = snap.get("earned", {})
    return (earned as Dictionary).size() if typeof(earned) == TYPE_DICTIONARY else 0


static func claimable(snap: Dictionary) -> Array:
    var out: Array = []
    for raw in records():
        var rid: String = String((raw as Dictionary)["id"])
        if state_of(rid, snap) == State.EARNED:
            out.append(rid)
    return out


# ---------------------------------------------------------------- rewards

## What claiming `achievement_id` should actually pay, given docs/15 Q-69's
## switch (`GameState.FLAG_DEFAULTS.achievement_rp`, true).
##
## M5-QAB-4 / Q-69, RULED 2026-09-15 (build/plan/ship/RULINGS.md §2 row 13):
## the record wall pays reputation. The two reputation-kind records carry
## `rp: 15` — docs/03 §6.1's smallest award, the two tutorials' worth — and
## docs/03 §6.1 gains the row "Record wall, reputation-kind records | — | 15 | 0"
## (W7-DOCS). So:
##   * `rp_live` true (the shipped value) — the record's own `rp` amount is paid,
##     capped by `rp_cap()` in `claim_grant()`.
##   * `rp_live` false — the recorded alternative: a `reputation` reward pays its
##     type's coin figure from docs/11 §11.2 instead. Nothing invented: the
##     validator already refuses a `reputation` reward on a type the coin row
##     does not price.
static func effective_reward(rec: Dictionary, rp_live: bool) -> Dictionary:
    var rew_v = rec.get("reward", {})
    if typeof(rew_v) != TYPE_DICTIONARY:
        return {"kind": "none", "amount": 0}
    var rew: Dictionary = (rew_v as Dictionary).duplicate()
    var kind: String = String(rew.get("kind", ""))
    if kind != "reputation":
        if kind == "coin":
            rew["amount"] = coin_for(String(rec.get("type", "")),
                bool(rec.get("capstone", false)))
        return rew
    var rp_amount: int = int(rew.get("rp", 0))
    if rp_live and rp_amount > 0:
        return {"kind": "reputation", "amount": rp_amount}
    var coin: int = coin_for(String(rec.get("type", "")), bool(rec.get("capstone", false)))
    return {"kind": "coin", "amount": coin, "instead_of": "reputation"}


static func reward_of(achievement_id: String, rp_live: bool = true) -> Dictionary:
    return effective_reward(record(achievement_id), rp_live)


## docs/11 §11.2: "Total coin from the board across the whole game is capped at
## ~15% of lifetime income." The denominator is `gold_earned_lifetime` — money
## that came IN, never the balance, so spending cannot lower the cap.
static func coin_cap(gold_earned_lifetime: int) -> int:
    return int(floor(maxi(0, gold_earned_lifetime) * COIN_CAP_SHARE))


## docs/15 Q-69's other half, "capped at ~15% of total earned" — live since the
## ruling. The denominator is `rp_earned_lifetime`, which the board's own
## payouts do NOT raise (GameState pays them with `counts_as_earned` false), so
## the faucet cannot widen its own ceiling: at Known, ⌊0.15 × 120⌋ = 18 ≥ 15,
## which is why the first record can be paid the moment the board opens.
static func rp_cap(rp_earned_lifetime: int) -> int:
    return int(floor(maxi(0, rp_earned_lifetime) * RP_CAP_SHARE))


## Coin already taken off the board, for the cap check and for the screen's
## running total.
static func coin_paid(claimed: Array, rp_live: bool = true) -> int:
    var total: int = 0
    for rid in claimed:
        var rew: Dictionary = reward_of(String(rid), rp_live)
        if String(rew.get("kind", "")) == "coin":
            total += int(rew.get("amount", 0))
    return total


## Reputation already taken off the board, the coin's twin for the RP cap.
static func rp_paid(claimed: Array, rp_live: bool = true) -> int:
    var total: int = 0
    for rid in claimed:
        var rew: Dictionary = reward_of(String(rid), rp_live)
        if String(rew.get("kind", "")) == "reputation":
            total += int(rew.get("amount", 0))
    return total


## Every coin the wall could ever pay, at the switch setting (`rp_live` defaults
## to the SHIPPED value, true, everywhere in this file, so a screen that passes
## nothing prints what the claim will pay). The cap
## test's numerator: a board whose maximum payout already exceeds 15% of a
## realistic lifetime income is mis-scaled at authoring time, not at play time.
static func coin_ceiling(rp_live: bool = true) -> int:
    var total: int = 0
    for raw in records():
        var rew: Dictionary = effective_reward(raw as Dictionary, rp_live)
        if String(rew.get("kind", "")) == "coin":
            total += int(rew.get("amount", 0))
    return total


## What `game/` should do to honour a claim. The board never applies anything
## itself (docs/14 OQ-10): this is the instruction, and GameState.claim_achievement()
## is the hand.
##
## `blocked` is non-empty when the claim must not proceed — already claimed, not
## earned, or the coin cap reached. The caller prints it; docs/13 §7 again.
static func claim_grant(achievement_id: String, snap: Dictionary, rp_live: bool = true) -> Dictionary:
    var rec: Dictionary = record(achievement_id)
    if rec.is_empty():
        return {"blocked": "No such record.", "kind": "none", "amount": 0}
    var standing: int = state_of(achievement_id, snap)
    if standing == State.CLAIMED:
        return {"blocked": "Already claimed.", "kind": "none", "amount": 0}
    if standing != State.EARNED:
        return {"blocked": "Not earned yet.", "kind": "none", "amount": 0}
    var grant: Dictionary = effective_reward(rec, rp_live).duplicate()
    grant["id"] = achievement_id
    grant["blocked"] = ""
    if String(grant.get("kind", "")) == "coin":
        var claimed = snap.get("claimed", [])
        var already: int = coin_paid(
            (claimed as Array) if typeof(claimed) == TYPE_ARRAY else [], rp_live)
        var cap: int = coin_cap(int(snap.get("gold_earned_lifetime", 0)))
        if already + int(grant.get("amount", 0)) > cap:
            # docs/11 §11.2's cap is "never enough to substitute for playing
            # content", so the honest failure is to make the player go and earn
            # some income rather than to silently pay a smaller purse.
            grant["blocked"] = ("The board has paid its share for now — %d of the %d G "
                + "it may pay against %d G earned.") % [
                    already, cap, int(snap.get("gold_earned_lifetime", 0))]
    elif String(grant.get("kind", "")) == "reputation":
        # Q-69's twin of the coin rule: blocked past the share, never paid short.
        var claimed_rp = snap.get("claimed", [])
        var heard: int = rp_paid(
            (claimed_rp as Array) if typeof(claimed_rp) == TYPE_ARRAY else [], rp_live)
        var rp_ceiling: int = rp_cap(int(snap.get("rp_earned_lifetime", 0)))
        if heard + int(grant.get("amount", 0)) > rp_ceiling:
            grant["blocked"] = ("The town has heard its share for now — %d of the %d "
                + "reputation it may pay against %d earned.") % [
                    heard, rp_ceiling, int(snap.get("rp_earned_lifetime", 0))]
    return grant


# ---------------------------------------------------------------- display

## docs/10 §2's canon placeholder names, and nothing else. Note 2 of that
## section is binding: "Every string ships as the canon placeholder — Adventure
## 2, Raid 1, Boss 3. Do not invent lore names, in code, in UI, or in asset
## filenames."
static func ladder_name(tier: int, slot: String) -> String:
    if TUTORIAL_SLOTS.has(slot):
        return String(TUTORIAL_SLOTS[slot])
    if slot.begins_with("A"):
        return "Adventure %d" % tier
    if slot.begins_with("E"):
        return "Raid %d, Encounter %s" % [tier, slot.substr(1)]
    return "%s %d" % [slot, tier]


static func _cond_where(cond: Dictionary) -> String:
    var tier: int = int(cond.get("tier", 0))
    var slot: String = String(cond.get("slot", ""))
    if slot.is_empty():
        return "any encounter"
    if tier <= 0:
        return String(TUTORIAL_SLOTS.get(slot, slot))
    return ladder_name(tier, slot)


## One line the Records tab can put in a Label. Generated rather than authored so
## a condition and its description cannot drift apart in a 40-row data file.
static func describe_condition(rec: Dictionary) -> String:
    var cond_v = rec.get("condition", {})
    if typeof(cond_v) != TYPE_DICTIONARY:
        return ""
    var cond: Dictionary = cond_v as Dictionary
    var n: int = int(cond.get("count", 1))
    match String(cond.get("kind", "")):
        "cleared":
            return "Clear %s." % _cond_where(cond)
        "clear_count":
            return "Clear %s %d times." % [_cond_where(cond), n]
        "cleared_slots":
            return "Clear %d encounters of Raid %d." % [_slots_wanted(cond),
                int(cond.get("tier", 0))]
        "attempts":
            return "Attempt %s %d times." % [_cond_where(cond), n]
        "wipes":
            return "Wipe on %s %d times." % [_cond_where(cond), n]
        "flawless_clear":
            return "Clear %s with no mistakes." % _cond_where(cond)
        "full_party_clear":
            return "Clear %s with everyone still standing." % _cond_where(cond)
        "survivors_at_most":
            return "Clear %s with %d raider left standing." % [_cond_where(cond), n]
        "event":
            return String(cond.get("text", "A thing that happens once."))
        "class_coverage":
            return "Have one of every class on the books at once."
        "legendaries_found":
            return "Find %d of the %d Legendaries." % [n, legendary_goal()]
        "morale_at_least":
            var who: String = "raider"
            if cond.has("rarity"):
                who = Enums.rarity_name_of(Enums.rarity_from_key(String(cond["rarity"])))
            return "Keep a %s at %d morale or better." % [who, int(cond.get("morale", 100))]
        "roster_size":
            return "Carry %d raiders on the books." % n
        "gold_at_least":
            return "Hold %d G at once." % int(cond.get("amount", 0))
        "gold_earned":
            return "Take %d G in over the life of the guild." % int(cond.get("amount", 0))
        "items_sold":
            return "Sell %d items." % n
        "items_upgraded":
            return "Fully upgrade %d item." % n
        "facility_tier":
            return "Get the Guildhall to upgrade %d." % int(cond.get("tier", 1))
        "furnishings_placed":
            return "Place %d Furnishings in the quarters." % n
        "reputation_rank":
            return "Reach %s." % Enums.reputation_name_of(int(cond.get("rank", 1)))
        "crisis_strikes":
            return "Let the whole guild get that unhappy, once."
        "campaign_complete":
            return "Clear Raid 5."
    return ""


static func describe_reward(rec: Dictionary, rp_live: bool = true) -> String:
    var rew: Dictionary = effective_reward(rec, rp_live)
    match String(rew.get("kind", "")):
        "coin":
            return "%d G" % int(rew.get("amount", 0))
        "reputation":
            return "%d reputation" % int(rew.get("amount", 0))
        "furnishing":
            return String(rew.get("furnishing_name", rew.get("furnishing_id", "")))
        "consumables":
            return "%d x %s" % [int(rew.get("amount", 1)),
                String(rew.get("consumable_name", rew.get("consumable_id", "")))]
        "town_flag":
            return String(rew.get("flag_name", rew.get("flag_id", "")))
    return "Nothing, yet."


# ---------------------------------------------------------------- completion

## docs/10 §13 row 1: the completion beat fires on "the first clear of Raid 5,
## Encounter 5". Asked of the encounter record rather than of an id, because
## docs/10 §2 note 2 forbids depending on a name and the tier-5 file does not
## ship until it is named (docs/15 BL-69). The caller landed with docs/15 BL-73:
## `GameState.record_attempt()` asks this on the FIRST clear of an encounter and
## sets the completion beat from the answer.
static func is_completion_encounter(enc) -> bool:
    if enc == null:
        return false
    return int(_prop(enc, "tier", -1)) == COMPLETION_TIER \
        and String(_prop(enc, "slot", "")) == COMPLETION_SLOT


## docs/10 §13 row 2's three continuing activities, as one readable line. This is
## the whole of the endgame's UI by design: docs/16 R-4 names doc 10 §13 "a
## standing invitation to invent an endgame" and lists Tier 6 and a heroic mode
## as cut, so what remains after the beat is a stated goal, not a new mode.
static func remaining_line(snap: Dictionary) -> String:
    return "Legendaries %d of %d  ·  Records %d of %d" % [
        int(snap.get("legendaries_found", 0)), legendary_goal(),
        earned_count(snap), records().size()]


## The collection meter docs/10 §13 row 2 makes one third of the post-clear
## activity. Nine is derived from the class list, never typed as a literal:
## ✅ CANON is "You can only ever find 1 Legendary per class".
static func legendary_meter(snap: Dictionary) -> String:
    return "Legendaries %d of %d" % [int(snap.get("legendaries_found", 0)), legendary_goal()]
