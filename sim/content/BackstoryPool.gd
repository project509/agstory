extends RefCounted
## Backstory bullets, and the number docs/05 reads off them (docs/04 §8, docs/05 §7.5).
##
## ✅ CANON, raw notes (Morale): "Gaining and losing Morale will be based on their back
## stories largely we can have bullet points for each raider that is recruited."
##
## docs/04 §8.3's rule for the tag vocabulary is the one that keeps this file honest:
## "Every tag must be listenable, or it does not ship. Adding a tag that needs a new
## event is a design change, not content work."
##
## Pure and deterministic: every draw takes an `Rng`.

const Enums = preload("res://sim/model/Enums.gd")

const DEFAULT_PATH := "res://data/backstories.json"

var tags: Array = []                ## rows, in file order
var by_tag: Dictionary = {}
var exclusions: Array = []          ## [[tag_a, tag_b], ...]
var errors: Array = []

## docs/04 §8.1's polarity enum, as stored.
const POSITIVE := "positive"
const NEGATIVE := "negative"
const MIXED := "mixed"

## docs/04 §6.2's bullet counts per rarity: 2 for a Common, 2-3 for the middle, 2-4 for
## a Legendary (whose bullets are hand-authored, so the count is what a definition file
## would supply).
const BULLET_COUNTS := [[2, 2], [2, 3], [2, 3], [2, 3], [2, 4]]

## docs/04 §8.1's heaviest weight, and the most bullets anyone draws. Together they set
## the extreme a backstory can reach, which is what maps onto docs/05 §7.5's range.
const MAX_WEIGHT := 1.5
const MAX_BULLETS := 4

## docs/05 §7.5 exposes "a `backstory_offset` in the range -8..+8 on baseline".
const OFFSET_LIMIT := 8


static func load_from(path: String = DEFAULT_PATH):
    var pool = load("res://sim/content/BackstoryPool.gd").new()
    pool._read(path)
    return pool


func _read(path: String) -> void:
    if not FileAccess.file_exists(path):
        errors.append("backstories: %s is missing" % path)
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        errors.append("backstories: %s is not a JSON object" % path)
        return

    for row in parsed.get("tags", []):
        if typeof(row) != TYPE_DICTIONARY:
            continue
        var variants: Array = []
        for line in row.get("variants", []):
            variants.append(String(line))
        var entry := {
            "tag": String(row.get("tag", "")),
            "polarity": String(row.get("polarity", MIXED)),
            "weight": float(row.get("weight", 1.0)),
            "listens": String(row.get("listens", "")),
            "parameterised": String(row.get("parameterised", "")),
            "variants": variants,
        }
        if String(entry["tag"]).is_empty():
            errors.append("backstories: a tag row has no tag")
            continue
        if variants.size() < 3:
            # docs/04 §8.1: "Written per-tag with 3-6 variants for variety." Fewer than
            # three and the tag becomes the one that always reads the same.
            errors.append("backstories: %s has only %d variants"
                % [String(entry["tag"]), variants.size()])
        tags.append(entry)
        by_tag[String(entry["tag"])] = entry

    for pair in parsed.get("exclusions", []):
        if typeof(pair) == TYPE_ARRAY and (pair as Array).size() == 2:
            exclusions.append([String(pair[0]), String(pair[1])])

    if tags.is_empty():
        errors.append("backstories: no tags loaded")


func is_valid() -> bool:
    return errors.is_empty()


func excluded_with(tag: String) -> Array:
    var out: Array = []
    for pair in exclusions:
        if String(pair[0]) == tag:
            out.append(String(pair[1]))
        elif String(pair[1]) == tag:
            out.append(String(pair[0]))
    return out


# ---------------------------------------------------------------- the draw

## docs/04 §8.1's draw rules, all four:
##
##   "One bullet = one tag; a raider never carries the same tag twice."
##   "Tags are drawn from an exclusion graph."
##   "Commons must include at least one `negative` bullet — canon: 'Lower tier raiders
##    will be hardest to keep happy'."
##   "Epics and above draw at most one `negative` bullet."
##
## Returns an Array of `{text, tag, polarity, weight}`.
func draw(rng, rarity: int, class_id: int = -1) -> Array:
    if tags.is_empty():
        return []
    var band: Array = BULLET_COUNTS[clampi(rarity, 0, BULLET_COUNTS.size() - 1)]
    var lo := int(band[0])
    var hi := int(band[1])
    var want: int = lo if hi <= lo else lo + rng.next_below(hi - lo + 1)

    var out: Array = []
    var used: Dictionary = {}
    var blocked: Dictionary = {}
    var negatives := 0

    # ✅ CANON via docs/04 §8.1: a Common's first bullet is guaranteed negative, so the
    # rarity canon calls "hardest to keep happy" always has something to be unhappy
    # about. Drawn first rather than checked afterwards, because a retry loop can fail.
    if rarity == Enums.Rarity.COMMON:
        var first := _pick_from(rng, _candidates(used, blocked, NEGATIVE), class_id)
        if not first.is_empty():
            out.append(first)
            _claim(first, used, blocked)
            negatives += 1

    while out.size() < want:
        var allow_negative: bool = _negatives_allowed(rarity, negatives)
        var pool := _candidates(used, blocked, "", allow_negative)
        if pool.is_empty():
            break
        var bullet := _pick_from(rng, pool, class_id)
        if bullet.is_empty():
            break
        out.append(bullet)
        _claim(bullet, used, blocked)
        if String(bullet["polarity"]) == NEGATIVE:
            negatives += 1
    return out


## docs/04 §8.1: "Epics and above draw at most one `negative` bullet."
func _negatives_allowed(rarity: int, so_far: int) -> bool:
    if rarity >= Enums.Rarity.EPIC:
        return so_far < 1
    return true


func _candidates(used: Dictionary, blocked: Dictionary, polarity: String = "",
        allow_negative: bool = true) -> Array:
    var out: Array = []
    for row in tags:
        var tag := String(row["tag"])
        if used.has(tag) or blocked.has(tag):
            continue
        var pol := String(row["polarity"])
        if not polarity.is_empty() and pol != polarity:
            continue
        if not allow_negative and pol == NEGATIVE:
            continue
        out.append(row)
    return out


func _pick_from(rng, pool: Array, class_id: int) -> Dictionary:
    if pool.is_empty():
        return {}
    var row: Dictionary = pool[rng.next_below(pool.size())]
    var variants: Array = row["variants"]
    if variants.is_empty():
        return {}
    var text := String(variants[rng.next_below(variants.size())])
    var tag := String(row["tag"])

    # docs/04 §8.3 tag 6 is `class_rival:<class>`, the one parameterised tag. The class
    # is bound at draw time and never the raider's own — a Rogue who refuses to speak to
    # Rogues is a different joke, and not this one.
    if String(row["parameterised"]) == "class":
        var others: Array = []
        for cls in Enums.all_classes():
            if int(cls) != class_id:
                others.append(cls)
        if others.is_empty():
            return {}
        var rival: int = int(others[rng.next_below(others.size())])
        text = text.replace("{class}", Enums.class_name_of(rival))
        tag = "%s:%s" % [tag, Enums.class_key(rival)]

    return {
        "text": text, "tag": tag,
        "polarity": String(row["polarity"]), "weight": float(row["weight"]),
    }


func _claim(bullet: Dictionary, used: Dictionary, blocked: Dictionary) -> void:
    var base := String(bullet["tag"]).get_slice(":", 0)
    used[base] = true
    for other in excluded_with(base):
        blocked[other] = true


# ---------------------------------------------------------------- the number

## docs/05 §7.5's `backstory_offset`, "in the range -8..+8 on baseline" — the only
## numeric hook that doc exposes for backstory, and it "deliberately exposes no more".
##
## The scale is derived rather than picked: the strongest possible backstory is
## `MAX_BULLETS` bullets at `MAX_WEIGHT` all pulling one way, so mapping that extreme
## onto ±8 is what makes the documented range actually reachable. A `mixed` bullet
## contributes nothing here — it moves morale through its trigger, not its baseline.
static func offset_for(bullets: Array) -> int:
    var sum := 0.0
    for b in bullets:
        # A caller may hand over plain strings — `Recruitment`'s injected seam takes
        # whatever it is given. A bullet with no polarity has no opinion about the
        # baseline, which is the same answer as `mixed`.
        if typeof(b) != TYPE_DICTIONARY:
            continue
        var weight := float(b.get("weight", 1.0))
        match String(b.get("polarity", MIXED)):
            POSITIVE:
                sum += weight
            NEGATIVE:
                sum -= weight
    var extreme := float(MAX_BULLETS) * MAX_WEIGHT
    var scaled := sum * (float(OFFSET_LIMIT) / extreme)
    return clampi(int(round(scaled)), -OFFSET_LIMIT, OFFSET_LIMIT)


## docs/05 §7.5's other backstory hook: "named trigger tags that multiply a §7 delta by
## 1.5x or 0.5x". Which tag amplifies which trigger is docs/04 §8.3's "Listens for"
## column, and only the rows whose listened-for event is a morale trigger this build
## fires are mapped — the rest wait for their events rather than being guessed at.
const TRIGGER_TAGS := {
    "wipe": {"scared_of_wipes": 1.5, "unbothered_by_wipes": 0.5},
    "benched": {"hates_being_benched": 1.5, "needs_a_friend": 1.5},
    "cleared": {"worships_guild_leader": 1.5, "glory_hound": 1.5},
    "peer_left": {"needs_a_friend": 1.5},
    "peer_left_same_class": {"needs_a_friend": 1.5},
    "comfort_item": {"loves_the_tavern": 1.5},
    "knocked_out": {"blames_the_healers": 1.5},
}


## Which of docs/04 §8.3's tags listen for a given morale trigger. docs/04 §11.3's
## `subscribed_tags` needs this in reverse: a Legendary hears an event only if one of
## their own bullets is listening for it.
static func tags_listening(trigger_id: String) -> Array:
    if not TRIGGER_TAGS.has(trigger_id):
        return []
    return (TRIGGER_TAGS[trigger_id] as Dictionary).keys()


## docs/04 §11.3's first mechanism, and the direct expression of ✅ CANON A11 —
## "legendary raiders will not be bothered by many things easily": an event reaches a
## Legendary only when one of their OWN backstory bullets listens for it. Everything else
## "is ignored outright".
static func legendary_hears(raider, trigger_id: String) -> bool:
    if raider == null:
        return true
    var listeners := tags_listening(trigger_id)
    if listeners.is_empty():
        # No tag family listens for this trigger at all, so subscription cannot gate it.
        # A raid clear reaching a Legendary is not "being bothered".
        return true
    for bullet in raider.backstory:
        if typeof(bullet) != TYPE_DICTIONARY:
            continue
        if listeners.has(String(bullet.get("tag", "")).get_slice(":", 0)):
            return true
    return false


## The multiplier this raider's backstory puts on one trigger. 1.0 when nothing in their
## past has an opinion about it.
##
## When two tags disagree the AMPLIFIER wins, because docs/05 §8 already makes negatives
## land harder than positives and a raider who both fears and shrugs off wipes cannot
## exist — the exclusion graph forbids that exact pair.
static func tag_scale(raider, trigger_id: String) -> float:
    if raider == null or not TRIGGER_TAGS.has(trigger_id):
        return 1.0
    var listeners: Dictionary = TRIGGER_TAGS[trigger_id]
    var scale := 1.0
    for bullet in raider.backstory:
        if typeof(bullet) != TYPE_DICTIONARY:
            continue
        var base := String(bullet.get("tag", "")).get_slice(":", 0)
        if not listeners.has(base):
            continue
        var found := float(listeners[base])
        if found > scale:
            scale = found
        elif scale == 1.0:
            scale = found
    return scale
