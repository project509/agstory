extends RefCounted
## The name generator (docs/04 §7).
##
## docs/04 §7 states the constraint that shapes everything here: "the joke is that this
## reads like a real guild roster, and canon's own examples — Bob, Greg, Steve — are
## aggressively ordinary. A fantasy name generator would kill the premise on sight."
##
## Three shapes, weighted: a bare mundane name, a mundane name mangled the way a real
## player mangles a taken handle, and a mundane name with a fantasy epithet welded on.
## The third one is the joke; it only works because it is rare.
##
## Pure and deterministic: every pick takes an `Rng`.

const DEFAULT_PATH := "res://data/names.json"

var given: Array = []
var epithets: Array = []
var mangles: Array = []
var shape_weights: Array = [620, 260, 120]   ## bare, mangled, epithet — per mille
var errors: Array = []

enum Shape { BARE, MANGLED, EPITHET }

## docs/04 §7: "Never two live raiders with the same `display_name`; on collision, apply
## a shape-B mangle, then a numeric suffix." This bounds the retry loop so a tiny pool
## and a huge roster cannot hang the generator.
const COLLISION_TRIES := 12


static func load_from(path: String = DEFAULT_PATH):
    var pool = load("res://sim/content/NamePool.gd").new()
    pool._read(path)
    return pool


func _read(path: String) -> void:
    if not FileAccess.file_exists(path):
        errors.append("names: %s is missing" % path)
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        errors.append("names: %s is not a JSON object" % path)
        return

    for name in parsed.get("given", []):
        given.append(String(name))
    for row in parsed.get("epithets", []):
        if typeof(row) != TYPE_DICTIONARY:
            continue
        epithets.append({
            "form": String(row.get("form", "suffix")),
            "text": String(row.get("text", "")),
        })
    for row in parsed.get("mangles", []):
        if typeof(row) == TYPE_DICTIONARY:
            mangles.append(String(row.get("kind", "")))

    var w = parsed.get("shape_weights", {})
    if typeof(w) == TYPE_DICTIONARY:
        shape_weights = [
            int(w.get("bare", 620)), int(w.get("mangled", 260)),
            int(w.get("epithet", 120)),
        ]

    if given.is_empty():
        errors.append("names: the mundane pool is empty")
    if epithets.is_empty():
        errors.append("names: the epithet list is empty")
    if mangles.is_empty():
        errors.append("names: no mangle rules")


func is_valid() -> bool:
    return errors.is_empty()


# ---------------------------------------------------------------- the pick

## A name nobody in `taken` is already using, or a near-miss of.
##
## docs/04 §7's two collision rules, and the second one is the interesting half:
## "Never generate a shape-B or shape-C form of a name already live in the roster (no
## `Steve` **and** `Steev`)." So the check is on the mundane ROOT, not the string.
func pick(rng, taken: Array = []) -> String:
    if given.is_empty():
        return ""
    var roots := {}
    for name in taken:
        roots[root_of(String(name))] = true

    for attempt in COLLISION_TRIES:
        var base := String(given[rng.next_below(given.size())])
        if roots.has(base):
            continue
        match _roll_shape(rng):
            Shape.MANGLED:
                return _mangle(rng, base)
            Shape.EPITHET:
                return _with_epithet(rng, base)
            _:
                return base

    # Every root is taken, which a nine-class roster of twenty can actually reach.
    # Fall back to a numeric suffix, which docs/04 §7 names as the last resort.
    var fallback := String(given[rng.next_below(given.size())])
    var n := 2
    while taken.has("%s%d" % [fallback, n]) and n < 100:
        n += 1
    return "%s%d" % [fallback, n]


func _roll_shape(rng) -> int:
    var pick_index: int = rng.pick_weighted(shape_weights)
    return pick_index if pick_index >= 0 else Shape.BARE


## The mundane name a generated one was built from, or the string itself when it does
## not look like one of ours. This is what makes "no Steve AND Steev" enforceable.
func root_of(name: String) -> String:
    if name.is_empty():
        return name
    # Strip a shape-C epithet: a prefix word, or everything after the first space.
    var words := name.split(" ")
    if words.size() > 1:
        for candidate in [String(words[0]), String(words[words.size() - 1])]:
            if given.has(candidate):
                return candidate
    var bare := String(words[0]) if words.size() > 1 else name
    # Strip a shape-B numeric tail, with or without the underscore.
    var trimmed := bare
    while trimmed.length() > 1 and (trimmed[-1].is_valid_int() or trimmed[-1] == "_"):
        trimmed = trimmed.substr(0, trimmed.length() - 1)
    if given.has(trimmed):
        return trimmed
    # Strip a doubled final consonant, and try the vowel swaps in reverse.
    if trimmed.length() > 2 and trimmed[-1] == trimmed[-2]:
        var undoubled := trimmed.substr(0, trimmed.length() - 1)
        if given.has(undoubled):
            return undoubled
    for candidate in given:
        if _is_vowel_variant(trimmed, String(candidate)):
            return String(candidate)
    return trimmed


func _is_vowel_variant(candidate: String, base: String) -> bool:
    if candidate == base:
        return true
    # "Steve" -> "Steev" and "Randy" -> "Randee" both keep the consonant skeleton.
    return _skeleton(candidate) == _skeleton(base) and not candidate.is_empty()


func _skeleton(word: String) -> String:
    var out := ""
    for i in word.length():
        var ch := word[i].to_lower()
        if not ["a", "e", "i", "o", "u", "y"].has(ch):
            out += ch
    return out


# ---------------------------------------------------------------- the shapes

## docs/04 §7's shape B: "Mundane name + one mangle: doubled final consonant,
## dropped/added vowel, trailing digit, `_` + digit." The samples in §7.1 are the
## acceptance criteria — Dougg, Steev, Kevin7, Dave_2, Barry99, Randee.
func _mangle(rng, base: String) -> String:
    if base.is_empty():
        return base
    var kind := String(mangles[rng.next_below(mangles.size())])
    match kind:
        "double_final_consonant":
            var last := base[-1]
            if _skeleton(last) != "":
                return base + last
            return base + base[-1]
        "drop_final_vowel":
            if base.length() > 3 and _skeleton(base[-1]) == "":
                return base.substr(0, base.length() - 1)
            return base + base[-1]
        "swap_final_vowel":
            if base.length() > 2 and _skeleton(base[-1]) == "":
                return base.substr(0, base.length() - 1) + "ee"
            if base.length() > 2 and _skeleton(base[-2]) == "":
                return base.substr(0, base.length() - 2) + "ee" + base[-1]
            return base + "ee"
        "trailing_digit":
            return "%s%d" % [base, 1 + rng.next_below(9)]
        "underscore_digit":
            return "%s_%d" % [base, 1 + rng.next_below(9)]
        "trailing_double_digit":
            return "%s%d" % [base, 10 + rng.next_below(90)]
        _:
            return base


## docs/04 §7's shape C. Three forms, because §7.1's own samples use all three:
## "Gary Bloodfang" (suffix), "Phil the Bold" (phrase) and "Big Ron" (prefix).
func _with_epithet(rng, base: String) -> String:
    if epithets.is_empty():
        return base
    var row: Dictionary = epithets[rng.next_below(epithets.size())]
    var text := String(row["text"])
    if String(row["form"]) == "prefix":
        return "%s %s" % [text, base]
    return "%s %s" % [base, text]
