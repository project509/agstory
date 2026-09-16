extends RefCounted
## The mistake-line corpus: what the log actually says when somebody fails.
##
## docs/07 §10.3 owns the writing standard, docs/14 §5.3.5 owns the field
## (`log_templates`) and docs/14 §5.4 assertion 7 owns the count. This file is
## the loader, the validators for everything in those rules a machine can check,
## and the deterministic picker that stops a bad raid printing the same joke
## nine times.
##
## docs/16 R-3 names "the comedy does not land" the project's top risk and says
## plainly that nothing in the doc set can prove otherwise. So the split of
## labour here is deliberate: the validators prove SHAPE — coverage, budget,
## uniqueness, resolvable tokens, one sentence, no mechanic-explaining — and a
## human proves FUNNY. `build/plan/q-comedy.md` records that gate as open.
##
## Pure and deterministic: every pick takes an `Rng`. Nothing here reads the
## clock, the scene tree, or `randi()` (house rule 6 / docs/14 §8).

const Enums = preload("res://sim/model/Enums.gd")
const Mistakes = preload("res://sim/core/Mistakes.gd")

const DEFAULT_PATH := "res://data/mistake_lines.json"

# ---------------------------------------------------------------- the budget

## docs/07 §10.3 rule 4 and docs/14 §5.4 assertion 7 both say six. Six is not
## enough, and the goldens say so (re-measured 2026-09-15 off the committed
## files): `e1_commons_starting` fires "Forgot to Taunt" TWELVE times inside one
## 22-round encounter (54 mistakes), `e3_commons_adventure` fires "Pulled Aggro
## Off the Tank" eleven times in 21 rounds, and `e5_miserable_commons` (11
## rounds, 44 mistakes) fires "Dropped a Mechanic" and "Pulled Aggro" seven
## times each. At six variants the player watches the same sentence twice in a
## fight they are watching tonight, which is docs/07 §5.5's own failure mode —
## it "reads as a bug, not a joke".
##
## So the floor stays, because two docs assert it, and a second constant carries
## the measured need. The ambiguity is a switch rather than a silent overrule;
## the ruling is docs/15 BL-80 (promoted from `build/plan/q-comedy.md`).
const MIN_VARIANTS := 6      ## the doc floor, enforced on every type's UNGATED lines
const HOT_VARIANTS := 14     ## measured worst (12) plus headroom, for the hot eight
const COLD_VARIANTS := 8     ## everything else, still comfortably above the floor

## The eight types that need `HOT_VARIANTS`. All eight are measured: every one
## fires five or more times inside a single shipped golden (docs/15 BL-80 has
## the counts). `MIS_FIRE` and `MIS_MECHANIC_DROP` were written in as a forecast
## — ungated by class and role, weight 8-9, rare only while Tier 1's mechanic
## checks were thin — and `e5_miserable_commons` now fires them 6 and 7 times.
const HOT_TYPES := [
    "MIS_AFK", "MIS_TAUNT_LAPSE", "MIS_WRONG_TARGET", "MIS_HEAL_WRONG",
    "MIS_AGGRO", "MIS_ARGUMENT", "MIS_FIRE", "MIS_MECHANIC_DROP",
]

## docs/07 §10.3 rule 4's second sentence: "Legendary raiders get their own
## variants". Four each — `e5_legendaries_raid` records four mistakes across
## twenty rounds, so four lines is already several fights' worth (docs/15 BL-80).
const LEGENDARY_VARIANTS := 4

# ------------------------------------------------------- the writing envelope

## `{actor}` is the ONLY token, because it is the only thing a
## `Mistakes.MistakeEvent` can resolve: the event carries `actor_id`, type,
## severity, round and cascade, and no target. docs/07 §10.3's own sample line
## ("Cindy heals Natsuna…") names a second person; that name has nowhere to come
## from at render time, so the shipped variant of that line is adapted. A
## `{target}` or `{tank}` slipping into the corpus would be a crash waiting for
## one specific fight, which is why this is a load-time error and not a runtime
## fallback.
const ACTOR_TOKEN := "{actor}"
const ALLOWED_TOKENS := ["actor"]

## Rule 1 is "one sentence", and docs/07 §10.3's own sample block breaks it:
## "Bob assumed someone else was handling it. Bob was the someone else." is two
## sentences and names Bob twice. The rule's stated intent is "not a paragraph",
## so the checkable envelope is taken from the doc's own authored text rather
## than from taste — at most two sentences, one or two `{actor}` tokens.
const MAX_SENTENCES := 2
const MIN_ACTOR_TOKENS := 1
const MAX_ACTOR_TOKENS := 2

## docs/13 §11.1 sets the log's measure at "≤ 74 characters". The joke line is
## indented 24px under its mistake header, so it may wrap; two measures is the
## point past which a one-sentence gag has become a paragraph on screen.
const LOG_MEASURE_CHARS := 74
const MAX_LINE_CHARS := LOG_MEASURE_CHARS * 2

## Rule 3, "never explain the mechanic in the joke line", as a substring test.
## Everything here is arithmetic the structured entry already carries and docs/07
## §10.2 tier 2 already prints; a line reaching for one of these words is doing
## the log's job instead of the comedy's.
const BANNED_SUBSTRINGS := ["threat", "hp", "dps", "cooldown", "mitigat", "%"]

## Terminal punctuation, for the sentence count. Kept as a constant because the
## count is a shipping gate and an inline literal would drift from the docstring.
const TERMINATORS := ".!?"


static func load_from(path: String = DEFAULT_PATH):
    var pool = load("res://sim/content/MistakeLines.gd").new()
    pool._read(path)
    return pool


var types: Array = []                ## type rows, in file order
var by_type: Dictionary = {}         ## type_id -> row
var legendaries: Array = []          ## legendary rows, in file order
var by_legendary: Dictionary = {}    ## legendary_def_id -> row
var by_id: Dictionary = {}           ## variant id -> variant, across both sets
var errors: Array = []


func is_valid() -> bool:
    return errors.is_empty()


## One multi-line report, in `ContentDB.error_report`'s register, so a boot
## screen can print content problems from both loaders the same way.
func error_report() -> String:
    if errors.is_empty():
        return "mistake lines OK: %d types, %d legendary sets, %d lines" % [
            types.size(), legendaries.size(), by_id.size()]
    return "mistake lines FAILED with %d problem(s):\n  - %s" % [
        errors.size(), "\n  - ".join(errors)]


func _err(msg: String) -> void:
    errors.append(msg)


# ---------------------------------------------------------------- loading

func _read(path: String) -> void:
    if not FileAccess.file_exists(path):
        _err("mistake_lines: %s is missing" % path)
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        _err("mistake_lines: %s is not a JSON object" % path)
        return
    var doc: Dictionary = parsed

    for row in doc.get("types", []):
        if typeof(row) == TYPE_DICTIONARY:
            _read_type(row)
    for row in doc.get("legendaries", []):
        if typeof(row) == TYPE_DICTIONARY:
            _read_legendary(row)

    _validate_coverage()


func _read_type(row: Dictionary) -> void:
    var type_id := String(row.get("type", ""))
    if type_id.is_empty():
        _err("mistake_lines: a type row has no `type`")
        return
    # docs/14 §5.4 assertion 7's other half, which had no implementation either:
    # a typo'd key writes fourteen lines into a void that nothing ever draws from.
    if not Mistakes.TYPES.has(type_id):
        _err("mistake_lines: `%s` is not a key of Mistakes.TYPES" % type_id)
        return
    if by_type.has(type_id):
        _err("mistake_lines: `%s` appears twice" % type_id)
        return

    var entry := {
        "type": type_id,
        "name": String(Mistakes.TYPES[type_id]["name"]),
        "variants": _read_variants(row.get("variants", []), type_id, false),
    }
    types.append(entry)
    by_type[type_id] = entry
    _check_budget(entry)


func _read_legendary(row: Dictionary) -> void:
    var def_id := String(row.get("legendary_def_id", ""))
    if def_id.is_empty():
        _err("mistake_lines: a legendary row has no `legendary_def_id`")
        return
    if by_legendary.has(def_id):
        _err("mistake_lines: legendary `%s` appears twice" % def_id)
        return

    var entry := {
        "legendary_def_id": def_id,
        "variants": _read_variants(row.get("variants", []), def_id, true),
    }
    legendaries.append(entry)
    by_legendary[def_id] = entry

    var variants: Array = entry["variants"]
    if variants.size() < LEGENDARY_VARIANTS:
        _err("mistake_lines: legendary `%s` has %d variants, needs %d (docs/07 §10.3 rule 4)"
            % [def_id, variants.size(), LEGENDARY_VARIANTS])


func _read_variants(raw, owner_id: String, is_legendary: bool) -> Array:
    var out: Array = []
    if typeof(raw) != TYPE_ARRAY:
        _err("mistake_lines: `%s` has no variants array" % owner_id)
        return out

    var texts: Dictionary = {}
    for item in raw:
        if typeof(item) != TYPE_DICTIONARY:
            continue
        var v: Dictionary = item
        var vid := String(v.get("id", ""))
        var text := String(v.get("text", ""))
        if vid.is_empty() or text.is_empty():
            _err("mistake_lines: `%s` has a variant with no id or no text" % owner_id)
            continue
        if by_id.has(vid):
            _err("mistake_lines: variant id `%s` is used twice" % vid)
            continue
        # Two types wearing the same joke reads as a bug rather than a callback,
        # so uniqueness is global across the corpus, not per type.
        if texts.has(text):
            _err("mistake_lines: `%s` repeats a line verbatim (%s and %s)"
                % [owner_id, String(texts[text]), vid])
            continue

        var entry := {
            "id": vid,
            "text": text,
            "owner": owner_id,
            "severity": _read_severity(v.get("severity"), vid, owner_id, is_legendary),
            "classes": _read_classes(v.get("classes"), vid, owner_id, is_legendary),
            "types": _read_types_gate(v.get("types"), vid, is_legendary),
        }
        _check_writing_rules(entry)
        texts[text] = vid
        by_id[vid] = entry
        out.append(entry)
    return out


## An absent key, `null` and `""` all mean "any severity" — a gate is an extra on
## top of the floor, never part of it.
func _read_severity(raw, vid: String, owner_id: String, is_legendary: bool) -> int:
    if raw == null or typeof(raw) != TYPE_STRING or String(raw).is_empty():
        return -1
    var key := String(raw)
    var band: int = Enums.severity_from_key(key)
    if band < 0:
        _err("mistake_lines: `%s` gates on severity `%s`, which is not a severity key"
            % [vid, key])
        return -1
    # docs/07 §5.4 clamps a rolled severity to the type's base band ±1, so a gate
    # outside that window is a line that can never be drawn. Silently unreachable
    # content is worse than missing content: the budget still counts it.
    if not is_legendary and Mistakes.TYPES.has(owner_id):
        var base: int = int(Mistakes.TYPES[owner_id]["severity"])
        var lo: int = maxi(0, base - 1)
        var hi: int = mini(Enums.Severity.CRITICAL, base + 1)
        if band < lo or band > hi:
            _err("mistake_lines: `%s` gates on %s, which `%s` can never roll (band %d..%d)"
                % [vid, key, owner_id, lo, hi])
    return band


func _read_classes(raw, vid: String, owner_id: String, is_legendary: bool) -> Array:
    var out: Array = []
    if raw == null or typeof(raw) != TYPE_ARRAY:
        return out
    for key in raw:
        var class_key := String(key)
        var cls: int = Enums.class_from_key(class_key)
        if cls < 0:
            _err("mistake_lines: `%s` gates on class `%s`, which is not a class key"
                % [vid, class_key])
            continue
        # A class gate narrower than the type's own gate is fine; one OUTSIDE it
        # is a line no raider can ever earn (a Mage line on a Shaman-only fizzle).
        # The role-gated types cannot be checked here — the class→role table lives
        # in `data/classes.json`, which this loader deliberately does not read —
        # so `tests/unit/test_mistake_lines.gd` closes that half against ContentDB.
        if not is_legendary and Mistakes.TYPES.has(owner_id):
            var t: Dictionary = Mistakes.TYPES[owner_id]
            if t.has("classes") and not (cls in t["classes"]):
                _err("mistake_lines: `%s` gates on %s, which cannot commit `%s`"
                    % [vid, class_key, owner_id])
                continue
        out.append(cls)
    return out


func _read_types_gate(raw, vid: String, is_legendary: bool) -> Array:
    var out: Array = []
    if raw == null or typeof(raw) != TYPE_ARRAY:
        return out
    if not is_legendary:
        _err("mistake_lines: `%s` carries a `types` gate, which only legendary lines have"
            % vid)
        return out
    for key in raw:
        var type_id := String(key)
        if not Mistakes.TYPES.has(type_id):
            _err("mistake_lines: `%s` reserves itself for `%s`, which is not a mistake type"
                % [vid, type_id])
            continue
        out.append(type_id)
    return out


# ---------------------------------------------------------------- validators

func _check_budget(entry: Dictionary) -> void:
    var type_id := String(entry["type"])
    var variants: Array = entry["variants"]
    var want: int = budget_for(type_id)
    if variants.size() < want:
        _err("mistake_lines: `%s` has %d lines, needs %d" % [type_id, variants.size(), want])

    # docs/07 §10.3 rule 4's floor has to hold for EVERY raider, not for the row
    # total: a type whose extra lines are all class-gated would drop a Cleric back
    # to four. So the floor is measured on the lines anyone can draw.
    var ungated := 0
    for v in variants:
        var row: Dictionary = v
        var classes: Array = row["classes"]
        if classes.is_empty() and int(row["severity"]) < 0:
            ungated += 1
    if ungated < MIN_VARIANTS:
        _err("mistake_lines: `%s` has only %d ungated lines, below the documented floor of %d"
            % [type_id, ungated, MIN_VARIANTS])


func _check_writing_rules(entry: Dictionary) -> void:
    var vid := String(entry["id"])
    var text := String(entry["text"])

    _check_tokens(vid, text)

    if text.length() > MAX_LINE_CHARS:
        _err("mistake_lines: `%s` is %d characters, over %d (docs/13 §11.1's measure, doubled)"
            % [vid, text.length(), MAX_LINE_CHARS])

    var sentences: int = _sentence_count(text)
    if sentences == 0:
        _err("mistake_lines: `%s` does not end in a full stop" % vid)
    elif sentences > MAX_SENTENCES:
        _err("mistake_lines: `%s` is %d sentences; docs/07 §10.3 rule 1 wants one, and the doc's own sample runs to %d"
            % [vid, sentences, MAX_SENTENCES])

    var lowered := text.to_lower()
    for banned in BANNED_SUBSTRINGS:
        if lowered.contains(banned):
            _err("mistake_lines: `%s` says \"%s\" — docs/07 §10.3 rule 3, the joke does not explain the mechanic"
                % [vid, banned])

    var capital := _stray_capital(text)
    if not capital.is_empty():
        # docs/03 §5.6, "DO NOT INVENT NAMES": eight of the nine Legendaries have
        # none yet, and a baked proper noun is how one gets invented by accident.
        # It also catches a second raider's name in a type line, which `{actor}`
        # cannot substitute for.
        _err("mistake_lines: `%s` contains the proper noun \"%s\"; every person in a line is `{actor}`"
            % [vid, capital])


func _check_tokens(vid: String, text: String) -> void:
    var actor_count := 0
    var from := 0
    while true:
        var open_at: int = text.find("{", from)
        if open_at < 0:
            break
        var close_at: int = text.find("}", open_at)
        if close_at < 0:
            _err("mistake_lines: `%s` has an unclosed placeholder" % vid)
            return
        var token := text.substr(open_at + 1, close_at - open_at - 1)
        if token == "actor":
            actor_count += 1
        elif not (token in ALLOWED_TOKENS):
            _err("mistake_lines: `%s` uses {%s}, and a MistakeEvent carries no such field"
                % [vid, token])
        from = close_at + 1

    if actor_count < MIN_ACTOR_TOKENS:
        _err("mistake_lines: `%s` never names the raider (docs/07 §10.3 rule 2)" % vid)
    elif actor_count > MAX_ACTOR_TOKENS:
        _err("mistake_lines: `%s` names the raider %d times; the doc's own sample stops at %d"
            % [vid, actor_count, MAX_ACTOR_TOKENS])


## Terminal punctuation runs, counted. Returns 0 when the text does not end on
## one at all, which is its own failure.
func _sentence_count(text: String) -> int:
    var trimmed := text.strip_edges()
    if trimmed.is_empty() or not TERMINATORS.contains(trimmed.right(1)):
        return 0
    var count := 0
    var in_run := false
    for i in trimmed.length():
        var ch := trimmed[i]
        if TERMINATORS.contains(ch):
            if not in_run:
                count += 1
                in_run = true
        else:
            in_run = false
    return count


## A capitalised word that is not opening a sentence. `{actor}` opens plenty of
## them, so a word counts as sentence-initial when it is first or follows a
## terminator.
func _stray_capital(text: String) -> String:
    var words := text.split(" ", false)
    var at_start := true
    for raw in words:
        var word := String(raw)
        var core := _strip_punctuation(word)
        if not at_start and _is_capitalised(core):
            return core
        at_start = word.length() > 0 and TERMINATORS.contains(word.right(1))
    return ""


func _strip_punctuation(word: String) -> String:
    var out := ""
    for i in word.length():
        var ch := word[i]
        if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z"):
            out += ch
        elif not out.is_empty():
            break
    return out


func _is_capitalised(word: String) -> bool:
    if word.length() < 2:
        return false
    var first := word[0]
    if first < "A" or first > "Z":
        return false
    for i in range(1, word.length()):
        var ch := word[i]
        if ch < "a" or ch > "z":
            return false
    return true


## docs/14 §5.4 assertion 7: every type in the taxonomy has lines. Run after the
## file is read, so a type missing entirely is caught as loudly as a short one.
func _validate_coverage() -> void:
    var missing: Array = []
    for type_id in Mistakes.TYPES.keys():
        if not by_type.has(type_id):
            missing.append(String(type_id))
    if not missing.is_empty():
        missing.sort()
        _err("mistake_lines: no lines for %s" % ", ".join(missing))

    # docs/04 §11.2: one Legendary per class, nine of them. Derived from the class
    # list rather than listed, so adding a tenth class fails here instead of
    # shipping a Legendary with nothing to say.
    var absent: Array = []
    for cls in Enums.all_classes():
        var def_id := "legendary_%s" % Enums.class_key(int(cls))
        if not by_legendary.has(def_id):
            absent.append(def_id)
    if not absent.is_empty():
        _err("mistake_lines: no legendary lines for %s" % ", ".join(absent))


# ---------------------------------------------------------------- the budget

## What this type owes. HOT is the measured need, COLD the general case; both sit
## above docs/07 §10.3's floor of six, which `_check_budget` enforces separately
## on the ungated subset.
static func budget_for(type_id: String) -> int:
    return HOT_VARIANTS if type_id in HOT_TYPES else COLD_VARIANTS


# ---------------------------------------------------------------- selection

## Every line this raider could draw for this failure. `severity` is an
## `Enums.Severity` or -1 for "do not filter"; `class_key` is "" for the same.
##
## A filter that empties the pool falls back to the unfiltered one rather than
## returning nothing: a gate exists to make a line MORE apt, never to leave a
## mistake with no line at all.
func variants_for(type_id: String, severity: int = -1, class_key: String = "") -> Array:
    if not by_type.has(type_id):
        return []
    var row: Dictionary = by_type[type_id]
    var all: Array = row["variants"]
    if severity < 0 and class_key.is_empty():
        return all

    var cls: int = Enums.class_from_key(class_key) if not class_key.is_empty() else -1
    var out: Array = []
    for item in all:
        var v: Dictionary = item
        var gate: int = int(v["severity"])
        if gate >= 0 and severity >= 0 and gate != severity:
            continue
        var classes: Array = v["classes"]
        if not classes.is_empty() and cls >= 0 and not (cls in classes):
            continue
        out.append(v)
    return all if out.is_empty() else out


## docs/07 §10.3 rule 4's legendary half. `type_id` of "" returns the whole set,
## which is what the shuffle bag refills from.
func legendary_variants_for(def_id: String, type_id: String = "") -> Array:
    if not by_legendary.has(def_id):
        return []
    var row: Dictionary = by_legendary[def_id]
    var all: Array = row["variants"]
    if type_id.is_empty():
        return all
    var out: Array = []
    for item in all:
        var v: Dictionary = item
        var gate: Array = v["types"]
        # An empty gate is a line for any failure; a populated one is reserved
        # for this character's signature way of getting it wrong.
        if gate.is_empty() or type_id in gate:
            out.append(v)
    return out


func variant(variant_id: String) -> Dictionary:
    if not by_id.has(variant_id):
        return {}
    return by_id[variant_id]


# ---------------------------------------------------------------- rendering

## The one substitution. Returns "" for an unknown id rather than inventing a
## line, because `Mistakes.MistakeEvent.log_line` already treats "" as "no line"
## and every render site is written against that.
func render(variant_id: String, actor_name: String) -> String:
    if not by_id.has(variant_id):
        return ""
    var v: Dictionary = by_id[variant_id]
    return fill(String(v["text"]), actor_name)


static func fill(text: String, actor_name: String) -> String:
    return text.replace(ACTOR_TOKEN, actor_name)


# ---------------------------------------------------------------- the bag

## One shuffle bag per encounter. docs/07 §5.5 already stops a TYPE repeating in
## consecutive rounds; this stops the same SENTENCE repeating within a type, which
## is the half the player actually notices — the taxonomy line is a header, the
## joke is the thing being read.
##
## Seed it once, from `rng.derive("mistake_line", 0, 0)`. `derive` is a pure
## function of the master seed and consumes no draws from the parent stream
## (`sim/core/Rng.gd` §derivation), so adding the bag cannot move a single
## simulation outcome — only the log's rendered strings.
class Bag extends RefCounted:
    var _pool = null
    var _rng = null

    ## deck key -> remaining variant ids, in shuffled order
    var _decks: Dictionary = {}
    ## deck key -> the id drawn last, so a wrap cannot put it back-to-back
    var _last: Dictionary = {}

    func _init(pool, rng) -> void:
        _pool = pool
        _rng = rng

    ## The line for one failure. `legendary_def_id` is "" for everybody else.
    ## Returns {} when the corpus has nothing, which the caller renders as "".
    func draw(type_id: String, severity: int = -1, class_key: String = "",
            legendary_def_id: String = "") -> Dictionary:
        if _pool == null or _rng == null:
            return {}

        # docs/07 §10.3 rule 4: the legendary's own line wins when they have one
        # for this failure, and the shared pool catches everything else.
        if not legendary_def_id.is_empty():
            var chosen: Dictionary = _take("leg:%s" % legendary_def_id,
                _pool.legendary_variants_for(legendary_def_id, type_id),
                _pool.legendary_variants_for(legendary_def_id))
            if not chosen.is_empty():
                return chosen

        return _take(type_id,
            _pool.variants_for(type_id, severity, class_key),
            _pool.variants_for(type_id))

    ## Convenience for the common case: the rendered string, or "".
    func line(type_id: String, actor_name: String, severity: int = -1,
            class_key: String = "", legendary_def_id: String = "") -> String:
        var chosen: Dictionary = draw(type_id, severity, class_key, legendary_def_id)
        if chosen.is_empty():
            return ""
        return _pool.fill(String(chosen["text"]), actor_name)

    func _take(key: String, eligible: Array, full: Array) -> Dictionary:
        if eligible.is_empty():
            return {}

        var allowed: Dictionary = {}
        for item in eligible:
            var v: Dictionary = item
            allowed[String(v["id"])] = v

        var last := String(_last.get(key, ""))
        if not _decks.has(key):
            _decks[key] = _shuffled(full, last)

        # Two passes at most: the deck as it stands, then one refill. A third pass
        # cannot find anything the second did not, and an unbounded loop here would
        # hang a raid rather than print a wrong joke.
        for _attempt in 2:
            var deck: Array = _decks[key]
            for i in deck.size():
                var vid := String(deck[i])
                if not allowed.has(vid):
                    continue
                # Never the same sentence twice running, even across a wrap —
                # unless it is the only line this raider is allowed to have.
                if vid == last and allowed.size() > 1:
                    continue
                deck.remove_at(i)
                _last[key] = vid
                return allowed[vid]
            _decks[key] = _shuffled(full, last)

        return {}

    ## A fresh deck, with `avoid` displaced from the front so the wrap cannot
    ## repeat the line that emptied the previous one.
    func _shuffled(full: Array, avoid: String) -> Array:
        var ids: Array = []
        for item in full:
            var v: Dictionary = item
            ids.append(String(v["id"]))
        _rng.shuffle(ids)
        if ids.size() > 1 and String(ids[0]) == avoid:
            var head = ids[0]
            ids[0] = ids[1]
            ids[1] = head
        return ids
