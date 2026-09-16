class_name TwgRaider
extends RefCounted
## A raider on the guild roster.
##
## Field-for-field from docs/04 §4, which is the contract the save file also
## uses. Field names here are the field names on disk.
##
## IMPORTANT — this record holds NO combat state. No current HP, no threat, no
## alive flag, no buffs. docs/04 §4 is explicit that combat writes only `morale`
## and the four counters, which is what keeps a raider safe to serialise in the
## middle of an encounter. Per-encounter state belongs to the sim's own
## combatant struct, not here.
##
## Derived values (role, morale band, max HP, gear stats) are computed, never
## stored authoritatively, so they cannot drift from their source.

const Enums = preload("res://sim/model/Enums.gd")
const Stats = preload("res://sim/model/Stats.gd")

static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/model/Raider.gd")
    return _self_script

# ---------------------------------------------------------------- identity

var id: String = ""                    # stable across saves, never reused
var display_name: String = ""
var class_id: int = -1                 # Enums.CharClass, immutable after generation
var rarity: int = Enums.Rarity.COMMON  # immutable
var legendary_def_id: String = ""      # non-empty only when rarity == LEGENDARY
var portrait_id: String = ""

# ---------------------------------------------------------------- morale

## Canon: one number per raider, 0-100. What a band DOES is docs/05's business;
## this record just carries the value.
## The DISPLAYED morale, which every other system reads.
var morale: int = 50

## docs/05 §4: morale is "stored as float so sub-1 drift accumulates". This is
## that exact value; `morale` is it, rounded. -1.0 means "not yet initialised",
## in which case `Morale.morale_exact()` falls back to `morale` — so an older
## save, or a raider built by hand in a test, still behaves correctly.
var morale_exact: float = -1.0

## docs/05 §4: "Consecutive Day Ticks spent in band 0-2". Drives both the
## departure gate (§6.2) and the warning escalation the roster shows (§6.2's
## Warning UX table). Resets to 0 the moment a raider climbs out of band 2.
var at_risk_strikes: int = 0

## docs/05 §7.5's baseline shift from this raider's history, clamped to -8..+8.
## Backstory CONTENT (bullets, tag vocabulary) is docs/03's; this is the single
## numeric hook docs/05 exposes, and it deliberately exposes no more.
var backstory_offset: int = 0

## docs/02 §4.2's comfort floor from the Furnishings placed in this raider's
## quarters, guild-wide standing orders included. DERIVED, never authored: `game/`
## recomputes it from the guild's holdings whenever those change
## (`GameState._recompute_comfort()`), and `sim/` only reads it.
##
## It lives on the raider rather than being passed around because every function
## that computes a baseline needs it — drift, resting, recovery and the roster
## readout — and threading a per-raider number through all of them invites exactly
## one caller forgetting.
var comfort_floor: int = 0

## docs/04 §11.3's escape hatch, set by `game/` when any of its five named BIG-dumb
## conditions holds. While true, a Legendary's morale floor is suspended and their
## negative multiplier returns to 1.0 — canon's "unless you are BIG dumb".
##
## Derived, like `comfort_floor`: `game/` writes it, `sim/` only reads it.
var big_dumb_active: bool = false

## docs/13 §5's "morale history", which nothing recorded until now (docs/15 BL-50).
## One entry per Day Tick: `{day, morale, note}`, oldest first, capped at
## `MORALE_LOG_CAP`. `note` is the trigger id that moved this raider furthest that
## tick, or "" for a tick where only drift happened.
##
## Written by `game/` at the end of a Day Tick and only read elsewhere, exactly like
## `comfort_floor` — `sim/` records nothing about the passage of days.
var morale_log: Array = []

## Thirty Day Ticks. Long enough to hold the whole of a bad patch (docs/15 BL-34
## measured a wipe spiral at ten ticks and a full recovery at eight to ten more),
## short enough that a twenty-raider roster costs a few kilobytes of save.
const MORALE_LOG_CAP := 30

# ---------------------------------------------------------------- mistakes

## Owned by docs/08 §8.8, stored here so a raider is self-contained.
## `base` is the chance at band Content (50-60), which canon calls the base.
## floor/ceiling are the per-rarity clamps canon calls "within tier limits".
var mistake_chance_base: float = 0.0
var mistake_chance_floor: float = 0.0
var mistake_chance_ceiling: float = 0.0

var raid_experience: int = 0           # display-only; does not feed combat math

# ---------------------------------------------------------------- equipment

## slot (Enums.Slot) -> item_id. Ids, not Item objects, so the record
## serialises without dragging the content database with it.
## `off_hand` is permanently absent for Monk, Mage and Wizard.
var equipment: Dictionary = {}

# ---------------------------------------------------------------- social

var backstory: Array = []              # Array[Dictionary] — bullets, 2-4
var wishlist: Array = []               # Array[item_id], 0-2, behind a flag
var traits: Array = []                 # Array[trait_id], 0-2

# ---------------------------------------------------------------- bookkeeping

var recruited_at_tier: int = 1
var recruited_at_rank: int = Enums.ReputationRank.UNKNOWN
var status: int = Enums.RaiderStatus.ACTIVE

## The only fields combat may write, besides morale.
var runs_attended: int = 0
var consecutive_benched: int = 0
var wipes_witnessed: int = 0
var loot_received: int = 0

## Reserved. Canon: "Train raiders < Maybe if we have level ups". Do not read
## these until that is ruled on (docs/04 §4).
var level: int = 0
var xp: int = 0


# ---------------------------------------------------------------- derived

## Derived from class_id, never stored (docs/04 §4).
func role(db) -> int:
    var cd = db.class_of(class_id)
    return cd.role if cd != null else -1


func role_group(db) -> int:
    var cd = db.class_of(class_id)
    return cd.role_group if cd != null else -1


func class_key() -> String:
    return Enums.class_key(class_id)


func rarity_key() -> String:
    return Enums.rarity_key(rarity)


func morale_band() -> int:
    return Enums.morale_band(morale)


func morale_band_name() -> String:
    return Enums.morale_band_name(morale)


func is_legendary() -> bool:
    return rarity == Enums.Rarity.LEGENDARY


func is_available() -> bool:
    return status == Enums.RaiderStatus.ACTIVE or status == Enums.RaiderStatus.BENCHED


func has_left() -> bool:
    return status == Enums.RaiderStatus.DEPARTED or status == Enums.RaiderStatus.FIRED


# ---------------------------------------------------------------- equipment

## The item in a slot, or null. Resolved through the content database so the
## record itself stays a plain bag of ids.
func item_in(db, slot: int):
    var item_id = equipment.get(slot, "")
    if item_id == null or String(item_id).is_empty():
        return null
    return db.item(String(item_id))


func equipped_items(db) -> Array:
    var out := []
    for slot in Enums.all_slots():
        var it = item_in(db, slot)
        if it != null:
            out.append(it)
    return out


## Sum of everything worn. Recomputed on demand rather than cached, so it can
## never disagree with `equipment`.
func gear_stats(db):
    var blocks := []
    for it in equipped_items(db):
        blocks.append(it.stats)
    return Stats.sum(blocks)


## Base HP for the class, scaled by the rarity multiplier, plus gear HP.
## docs/08 §6: the multiplier ships at 1.00 for every rarity on purpose.
func max_hp(db) -> int:
    var cd = db.class_of(class_id)
    if cd == null:
        return 0
    var base := int(round(float(cd.base_hp) * db.hp_multiplier_for(rarity)))
    return base + gear_stats(db).hp


## Whether this raider may wear an item: right family, right slot, and the class
## must actually have that slot.
func can_equip(db, item) -> bool:
    if item == null:
        return false
    var cd = db.class_of(class_id)
    if cd == null:
        return false
    if cd.family_for_slot(item.slot) < 0:
        return false
    return item.can_be_used_by(class_id)


## Equip into the item's own slot. Returns "" on success or a reason string.
## Enforces the canon two-hand rule: a 2H main hand locks the off hand.
func equip(db, item) -> String:
    if item == null:
        return "no item"
    if not can_equip(db, item):
        return "%s cannot equip %s" % [class_key(), item.id]
    if item.two_handed and item.slot == Enums.Slot.MAIN_HAND:
        equipment.erase(Enums.Slot.OFF_HAND)
    if item.slot == Enums.Slot.OFF_HAND:
        var mh = item_in(db, Enums.Slot.MAIN_HAND)
        if mh != null and mh.two_handed:
            return "main hand is two-handed; off hand is locked"
    equipment[item.slot] = item.id
    return ""


## Append one Day Tick to the history, dropping the oldest when full. A repeat of the
## same day OVERWRITES rather than appending, so a tick that resolves in two passes
## (docs/05 §7.2's deferred peer deltas) still leaves one row per day.
func record_morale_day(day: int, value: int, note: String = "") -> void:
    if not morale_log.is_empty() and int(morale_log[-1]["day"]) == day:
        morale_log[-1]["morale"] = value
        if not note.is_empty():
            morale_log[-1]["note"] = note
        return
    morale_log.append({"day": day, "morale": value, "note": note})
    while morale_log.size() > MORALE_LOG_CAP:
        morale_log.pop_front()


## The trend across the recorded window: the morale now minus the oldest recorded.
## Zero when there is nothing to compare against.
func morale_trend() -> int:
    if morale_log.size() < 2:
        return 0
    return int(morale_log[-1]["morale"]) - int(morale_log[0]["morale"])


func unequip(db, slot: int) -> void:
    equipment.erase(slot)


## Slots this raider can fill but currently has not.
func empty_slots(db) -> Array:
    var cd = db.class_of(class_id)
    if cd == null:
        return []
    var out := []
    for slot in cd.available_slots():
        if item_in(db, slot) == null:
            out.append(slot)
    return out


# ---------------------------------------------------------------- display

## Canon roster line: "Natsuna — 87 ❤️ / Shaman — Very Happy".
func roster_line(db) -> String:
    var cd = db.class_of(class_id)
    var cls_name: String = cd.name if cd != null else "?"
    return "%s — %d %s\n%s — %s" % [
        display_name, morale, Enums.morale_band_emoji(morale),
        cls_name, morale_band_name(),
    ]


func _to_string() -> String:
    return "Raider(%s %s %s morale=%d)" % [display_name, rarity_key(), class_key(), morale]


# ---------------------------------------------------------------- persistence

func to_dict() -> Dictionary:
    var equip_out := {}
    for slot in equipment.keys():
        equip_out[Enums.slot_key(int(slot))] = equipment[slot]
    return {
        "id": id, "display_name": display_name,
        "class_id": Enums.class_key(class_id), "rarity": Enums.rarity_key(rarity),
        "legendary_def_id": legendary_def_id, "portrait_id": portrait_id,
        "morale": morale,
        "mistake_chance_base": mistake_chance_base,
        "mistake_chance_floor": mistake_chance_floor,
        "mistake_chance_ceiling": mistake_chance_ceiling,
        "raid_experience": raid_experience,
        "equipment": equip_out,
        "morale_exact": morale_exact,
        "at_risk_strikes": at_risk_strikes,
        "backstory_offset": backstory_offset,
    "comfort_floor": comfort_floor,
    "big_dumb_active": big_dumb_active,
    "morale_log": morale_log.duplicate(true),
        "backstory": backstory.duplicate(true),
        "wishlist": wishlist.duplicate(),
        "traits": traits.duplicate(),
        "recruited_at_tier": recruited_at_tier,
        "recruited_at_rank": Enums.reputation_key(recruited_at_rank),
        "status": Enums.raider_status_key(status),
        "runs_attended": runs_attended,
        "consecutive_benched": consecutive_benched,
        "wipes_witnessed": wipes_witnessed,
        "loot_received": loot_received,
        "level": level, "xp": xp,
    }


static func from_dict(d: Dictionary, errors: Array = []):
    var r = _cls().new()
    r.id = String(d.get("id", ""))
    r.display_name = String(d.get("display_name", ""))
    r.class_id = Enums.class_from_key(String(d.get("class_id", "")))
    if r.class_id < 0:
        errors.append("raider %s: unknown class '%s'" % [r.id, d.get("class_id", "")])
    r.rarity = Enums.rarity_from_key(String(d.get("rarity", "common")))
    if r.rarity < 0:
        errors.append("raider %s: unknown rarity '%s'" % [r.id, d.get("rarity", "")])
        r.rarity = Enums.Rarity.COMMON
    r.legendary_def_id = String(d.get("legendary_def_id", ""))
    r.portrait_id = String(d.get("portrait_id", ""))
    r.morale = clampi(int(d.get("morale", 50)), Enums.MORALE_MIN, Enums.MORALE_MAX)
    # docs/05 §4's exact value. Absent in a save written before it existed, in
    # which case it is derived from the displayed integer rather than lost.
    r.morale_exact = float(d.get("morale_exact", float(r.morale)))
    r.at_risk_strikes = int(d.get("at_risk_strikes", 0))
    r.backstory_offset = int(d.get("backstory_offset", 0))
    r.comfort_floor = maxi(0, int(d.get("comfort_floor", 0)))
    r.big_dumb_active = bool(d.get("big_dumb_active", false))
    var raw_log = d.get("morale_log", [])
    if typeof(raw_log) == TYPE_ARRAY:
        for entry in raw_log:
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            r.morale_log.append({
                "day": int(entry.get("day", 0)),
                "morale": int(entry.get("morale", 50)),
                "note": String(entry.get("note", "")),
            })
    r.mistake_chance_base = float(d.get("mistake_chance_base", 0.0))
    r.mistake_chance_floor = float(d.get("mistake_chance_floor", 0.0))
    r.mistake_chance_ceiling = float(d.get("mistake_chance_ceiling", 0.0))
    r.raid_experience = int(d.get("raid_experience", 0))

    for slot_key in d.get("equipment", {}).keys():
        var slot := Enums.slot_from_key(String(slot_key))
        if slot < 0:
            errors.append("raider %s: unknown slot '%s'" % [r.id, slot_key])
            continue
        r.equipment[slot] = String(d["equipment"][slot_key])

    r.backstory = d.get("backstory", []).duplicate(true)
    r.wishlist = d.get("wishlist", []).duplicate()
    r.traits = d.get("traits", []).duplicate()
    r.recruited_at_tier = int(d.get("recruited_at_tier", 1))
    r.recruited_at_rank = maxi(0, Enums.reputation_from_key(String(d.get("recruited_at_rank", "unknown"))))
    r.status = maxi(0, Enums.raider_status_from_key(String(d.get("status", "active"))))
    r.runs_attended = int(d.get("runs_attended", 0))
    r.consecutive_benched = int(d.get("consecutive_benched", 0))
    r.wipes_witnessed = int(d.get("wipes_witnessed", 0))
    r.loot_received = int(d.get("loot_received", 0))
    r.level = int(d.get("level", 0))
    r.xp = int(d.get("xp", 0))

    if r.is_legendary() and r.legendary_def_id.is_empty():
        errors.append("raider %s: legendary rarity requires a legendary_def_id" % r.id)
    if not r.is_legendary() and not r.legendary_def_id.is_empty():
        errors.append("raider %s: only legendaries may carry a legendary_def_id" % r.id)
    return r
