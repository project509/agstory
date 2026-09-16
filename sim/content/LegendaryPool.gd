extends RefCounted
## The nine authored Legendaries (docs/04 §11, docs/03 §5.6).
##
## ✅ CANON (A9): "You can only ever find 1 Legendary per class - They are also named
## characters - IE Natsuna(the shaman) or something."
##
## That one line is why these are content rather than generator output, and docs/04 §11
## draws the consequence: "it makes reaching Renowned the moment the game hands the player
## a real character."
##
## ⚠️ Canon names exactly ONE of them, and hedges even that. docs/03 §5.6 and docs/04
## §11.1 both refuse to invent the other eight — "Do not invent names" — so this loader
## renders docs/03 §5.6's own placeholder for them and nothing here guesses.
##
## Pure and deterministic: file reads and lookups.

const Enums = preload("res://sim/model/Enums.gd")
const Quirks = preload("res://sim/core/Quirks.gd")

const DEFAULT_DIR := "res://data/legendaries"

## The keys docs/04 §11.2's `quirk` record must carry. `id` is the dispatch key,
## `name` is what a screen prints, `reads_as` is the sentence the designer wrote — a
## quirk with no `reads_as` is a mechanic nobody can name, and canon's whole reason for
## these characters is that they are named.
const QUIRK_REQUIRED_KEYS := ["id", "name", "reads_as"]

var by_class: Dictionary = {}       ## class_id -> definition
var errors: Array = []


static func load_from(dir_path: String = DEFAULT_DIR):
    var pool = load("res://sim/content/LegendaryPool.gd").new()
    pool._read(dir_path)
    return pool


func _read(dir_path: String) -> void:
    for key in Enums.CLASS_KEYS:
        var path := "%s/%s.json" % [dir_path, String(key)]
        if not FileAccess.file_exists(path):
            errors.append("legendaries: %s is missing" % path)
            continue
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if typeof(parsed) != TYPE_DICTIONARY:
            errors.append("legendaries: %s is not a JSON object" % path)
            continue
        var row: Dictionary = parsed
        var class_id := Enums.class_from_key(String(row.get("class_id", "")))
        if class_id < 0:
            errors.append("legendaries: %s has no valid class_id" % path)
            continue
        if by_class.has(class_id):
            # ✅ CANON A9 is "one per class", so two files claiming one class is a content
            # bug that must not load quietly.
            errors.append("legendaries: %s duplicates %s"
                % [path, Enums.class_name_of(class_id)])
            continue
        row["class_id"] = class_id
        _validate(path, row)
        by_class[class_id] = row


## docs/04 §11.3's `subscribed_tags` is "Only the tags in this Legendary's own backstory",
## so a subscription naming a tag they do not carry is a rule that can never fire — and
## silently, which is the worst kind.
func _validate(path: String, row: Dictionary) -> void:
    var own: Dictionary = {}
    for bullet in row.get("backstory", []):
        if typeof(bullet) == TYPE_DICTIONARY:
            own[String(bullet.get("tag", ""))] = true
    if own.is_empty():
        errors.append("legendaries: %s has no backstory bullets" % path)

    var rules: Dictionary = row.get("morale_rules", {})
    for tag in rules.get("subscribed_tags", []):
        if not own.has(String(tag)):
            errors.append("legendaries: %s subscribes to '%s', which is not in its own backstory"
                % [path, String(tag)])

    # docs/04 §8.1 caps a Legendary at one negative bullet, same as an Epic.
    var negatives := 0
    for bullet in row.get("backstory", []):
        if typeof(bullet) == TYPE_DICTIONARY \
                and String(bullet.get("polarity", "")) == "negative":
            negatives += 1
    if negatives > 1:
        errors.append("legendaries: %s carries %d negative bullets; the cap is one"
            % [path, negatives])

    _validate_quirk(path, row)


## docs/04 §11.2's `quirk` row is a required field, and until this ran a typo in `quirk.id`
## loaded silently — the record was parsed into `by_class` and read by nothing at all.
##
## `status` is checked as hard as the rest ON PURPOSE. docs/15 BL-58 is OPEN and every one
## of the nine files says so in its own `quirk.status`; the day somebody deletes that line
## is the day the quirk claims to be specced, so this fails until docs/07 (or docs/06 §4 —
## see build/plan/q-quirks.md) actually has a section to point at. Same shape as the
## name-invention guard in tests/unit/test_legendaries.gd, and for the same reason: an
## instruction that is not asserted does not survive a content pass.
func _validate_quirk(path: String, row: Dictionary) -> void:
    var quirk = row.get("quirk", null)
    if typeof(quirk) != TYPE_DICTIONARY:
        errors.append("legendaries: %s has no `quirk` record (docs/04 §11.2)" % path)
        return
    var record: Dictionary = quirk
    for key in QUIRK_REQUIRED_KEYS:
        if String(record.get(key, "")).strip_edges().is_empty():
            errors.append("legendaries: %s quirk is missing `%s`" % [path, String(key)])

    var quirk_id := String(record.get("id", ""))
    var expected := Quirks.expected_id_for(int(row["class_id"]))
    if not quirk_id.is_empty() and quirk_id != expected:
        # The dispatch key is derivable from the class, and ✅ CANON A9's one-per-class
        # rule is what makes that safe. A quirk id that does not match its class would
        # dispatch to somebody else's gift the moment `SPECS` has rows in it.
        errors.append("legendaries: %s quirk id is '%s'; the convention is '%s'"
            % [path, quirk_id, expected])
    for other_class in by_class:
        var other: Dictionary = by_class[other_class]
        var other_quirk = other.get("quirk", null)
        if typeof(other_quirk) != TYPE_DICTIONARY:
            continue
        if String((other_quirk as Dictionary).get("id", "")) == quirk_id:
            errors.append("legendaries: %s quirk id '%s' is already %s's"
                % [path, quirk_id, Enums.class_name_of(int(other_class))])

    if String(record.get("status", "")).strip_edges().is_empty():
        errors.append(("legendaries: %s quirk has no `status`; while docs/15 BL-58 is OPEN"
            + " every quirk must say so (see sim/core/Quirks.gd)") % path)


func is_valid() -> bool:
    return errors.is_empty()


func definition(class_id: int) -> Dictionary:
    return by_class.get(class_id, {})


func has_definition(class_id: int) -> bool:
    return by_class.has(class_id)


## docs/03 §5.6's placeholder, verbatim: "Use placeholders `Legendary (Warrior) — name
## pending`". Only the Shaman returns a real name, because only the Shaman has one.
func display_name(class_id: int) -> String:
    var row := definition(class_id)
    if row.is_empty():
        return "Legendary (%s) — name pending" % Enums.class_name_of(class_id)
    var name = row.get("display_name", null)
    if name == null or String(name).is_empty():
        return "Legendary (%s) — name pending" % Enums.class_name_of(class_id)
    return String(name)


func is_named(class_id: int) -> bool:
    var row := definition(class_id)
    if row.is_empty():
        return false
    var name = row.get("display_name", null)
    return name != null and not String(name).is_empty()


## Every class whose Legendary is still unnamed, for a content report. This is the list
## docs/03 §5.6 hands to the lead designer.
func unnamed_classes() -> Array:
    var out: Array = []
    for cls in Enums.all_classes():
        if not is_named(int(cls)):
            out.append(cls)
    return out


func backstory_of(class_id: int) -> Array:
    var out: Array = []
    for bullet in definition(class_id).get("backstory", []):
        if typeof(bullet) == TYPE_DICTIONARY:
            out.append((bullet as Dictionary).duplicate())
    return out


func barks_of(class_id: int) -> Array:
    var out: Array = []
    for line in definition(class_id).get("dialogue_barks", []):
        out.append(String(line))
    return out


func morale_rules(class_id: int) -> Dictionary:
    return definition(class_id).get("morale_rules", {})


## docs/04 §11.2's optional override: "Default is null, meaning the computed baseline per
## docs/05 §4/§7.5 — not a fixed 75." Returns -1 for "use the baseline".
func starting_morale(class_id: int) -> int:
    var value = definition(class_id).get("starting_morale", null)
    return int(value) if value != null else -1


## docs/04 §11.2's gear grant: "Count of raid pieces (3-4) and any forced slot."
func gear_grant(class_id: int) -> Dictionary:
    return definition(class_id).get("gear_grant", {})


## docs/04 §11.2's `quirk` record — "One class-flavoured mechanical gift; specced in doc
## 07, named here". Parsed since the files were authored and read by nothing until now;
## this is the accessor `sim/core/Quirks.gd` dispatches through, so the eventual spec pass
## is a table in that file plus this lookup, not a hunt through the loader.
##
## Copied on the way out, like `backstory_of()`: `by_class` is loaded once and must never
## be mutated by a caller that only meant to look.
func quirk_of(class_id: int) -> Dictionary:
    var record = definition(class_id).get("quirk", null)
    if typeof(record) != TYPE_DICTIONARY:
        return {}
    return (record as Dictionary).duplicate(true)


## The dispatch key alone, or "" for a class with no definition. This is what a caller
## hands `Quirks.threat_multiplier()` and friends.
func quirk_id_of(class_id: int) -> String:
    return String(quirk_of(class_id).get("id", ""))


## Whether this quirk is still waiting on its spec. True for all nine today, because every
## file carries `quirk.status` and docs/15 BL-58 is OPEN. A screen that wants to print the
## gift's name can do so — the NAME is authored — but nothing may promise an effect while
## this is true.
func quirk_spec_pending(class_id: int) -> bool:
    return not String(quirk_of(class_id).get("status", "")).strip_edges().is_empty()
