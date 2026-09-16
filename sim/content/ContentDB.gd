class_name TwgContentDB
extends RefCounted
## Loads every content JSON file, validates it, and indexes it for the sim.
##
## Validation policy: this class NEVER crashes and never calls push_error. It
## collects every problem it finds into `errors` and keeps going, so one bad
## item does not hide the other nine. `sim/` stays pure and testable; the caller
## in `game/` decides what a broken content set means (docs/14 OQ-10 — the sim
## reports, `game/` acts). Boot should refuse to start when `is_valid()` is
## false rather than shipping a half-loaded world.
##
## Everything here is derived once at load. Nothing in the sim should re-read
## JSON or re-derive eligibility at runtime.

const Enums = preload("res://sim/model/Enums.gd")
const Stats = preload("res://sim/model/Stats.gd")
const Item = preload("res://sim/model/Item.gd")
const ClassDef = preload("res://sim/model/ClassDef.gd")
const Encounter = preload("res://sim/model/Encounter.gd")

const DATA_DIR := "res://data/"

## The files that exist once for the whole game rather than once per tier.
## Starting gear is tier 0 and is authored once (docs/09 §5), so it does not
## belong to a rung. A future singleton content file belongs here; anything the
## ladder repeats per tier belongs in `tier_paths` instead.
const DEFAULT_PATHS := {
    "classes": "res://data/classes.json",
    "starting": "res://data/items_starting.json",
    # Onboarding is authored once for the whole game, not once per tier: docs/10
    # §9 gives the ladder exactly two tutorial rungs and Tier 2 does not repeat
    # them. So this belongs here beside the tier-0 starting gear rather than in
    # `tier_paths`, where a missing file would be reported as a half-authored
    # tier at every rung above the first.
    "tutorials": "res://data/encounters_tutorial_t1.json",
    # The onboarding REWARD, beside the onboarding rungs and for the same reason:
    # docs/09 §10.2 G12 is one pair of trinkets for the whole game. They are tier
    # 0 rather than tier 1 — docs/09 §12.1's tier column reads "0 = starting gear
    # and tutorial rewards" — which is also why the file carries no `_t1` suffix.
    "tutorial_items": "res://data/items_tutorial.json",
}

## The onboarding rungs, in canon's order (docs/10 §2, §9.1). Mounted at tier 1
## because that is the only tier that has them.
const TUTORIAL_SLOTS := ["A0", "TR"]
const TUTORIAL_TIER := 1

## docs/10 §12 budgets exactly five tiers and §13 leaves what happens after
## Raid 5 open, so five is the ceiling the tier probe scans to. A sixth tier is
## an open question, not a data edit.
const MAX_TIER := 5


## Self-reference without the global class registry. A script's own `class_name`
## does not reliably resolve inside a STATIC function in headless runs, which
## broke this file twice; loading by path always works and is cached after the
## first call.
static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/content/ContentDB.gd")
    return _self_script

var errors: Array[String] = []

## class key -> ClassDef, in canon order
var classes: Array = []
var _class_by_key: Dictionary = {}

## item id -> Item
var items: Dictionary = {}

## "<family>:<slot>" -> Array[Item]
var _by_family_slot: Dictionary = {}

## class key -> Array[Item] (the four starting pieces)
var starting_sets: Dictionary = {}

## tier -> { class key -> { encounter:int -> Array[Item] } }
## Keyed by tier first: canon repeats the class/boss grid every tier, so a
## table keyed by class alone can only ever hold the last tier loaded.
var raid_tables: Dictionary = {}

## encounter id -> Encounter, and "<tier>:<slot>" -> Encounter. The slot alone
## is NOT unique — every tier has an E1 — so the index carries the tier.
var encounters: Dictionary = {}
var _encounters_by_slot: Dictionary = {}

## The tiers the manifest mounted, ascending. This is how a caller asks what
## content exists without hard-coding a count (docs/16 §7 X2.8).
var tiers: Array[int] = []

## Tier 1's Boss 5 universal trinket pool, kept as a bare Array because every
## existing caller means Tier 1. `trinkets(tier)` is the tier-aware form.
var trinket_pool: Array = []
var _trinket_pool_by_tier: Dictionary = {}

var rarity_hp_multiplier: Dictionary = {}


# ---------------------------------------------------------------- loading

## The four files one tier is authored as. The names are the convention the
## shipped Tier 1 set already uses, and here that convention becomes the
## contract: docs/16 §7 X2.8 requires a full tier to be authored with no
## engineering change, and docs/10 §2 rules that inserting a rung must cost a
## data edit and nothing else. So the loader finds a tier by its filenames.
## A caller that wants a different layout passes its own manifest to
## `load_all` — the convention is the default, not the only option.
## docs/10's tier escalation rule, in one place: "A tier introduces at most TWO
## mechanics the player has not seen ... new tiers get harder by number and
## overlap of mechanics, not by novelty."
const MAX_NEW_MECHANICS_PER_TIER := 2


static func tier_paths(tier: int) -> Dictionary:
    return {
        "tier": tier,
        "adventure": "%sitems_t%d_adventure.json" % [DATA_DIR, tier],
        "raid": "%sitems_t%d_raid.json" % [DATA_DIR, tier],
        "encounters": "%sencounters_t%d.json" % [DATA_DIR, tier],
        "adventures": "%sencounters_adventure_t%d.json" % [DATA_DIR, tier],
    }


## Which tiers are NAMED. docs/09 §11.4's material and title words are pending a
## designer for tiers 2-5, and `data/tier_words.json` says so per tier.
##
## docs/15 BL-69: a tier whose words are pending is GENERATED but not SHIPPED.
## `tools/gen_items.gd` writes it, `tests/unit/test_tier_scaling.gd` checks it,
## and anything that wants it can ask for `tier_paths(n)` by name — but it does
## not enter the default content set, because docs/10 §2 forbids inventing lore
## names and a generator token ("TIER2's Boots") is not a canon placeholder the
## way "Raid 1" and "Boss 3" are. Filling in four material words and four titles
## is what ships them.
static func tier_is_named(tier: int) -> bool:
    var text := FileAccess.get_file_as_string(DATA_DIR + "tier_words.json")
    if text.is_empty():
        return true    # no words file at all: the old behaviour, mount what is there
    var doc = JSON.parse_string(text)
    if not (doc is Dictionary):
        return true
    var tiers: Dictionary = doc.get("tiers", {})
    var row = tiers.get(str(tier), null)
    if not (row is Dictionary):
        return true
    return not bool(row.get("pending", false))


## The arena a tier names for a kind of fight ("raid" / "adventure"), or "" —
## the tier row's `scene` key in `data/tier_words.json` (CONTENT-26's contract,
## Q-96's ruling): a scene NAME (`stage_arena_dungeon`), never a path, so the
## content layer knows nothing of where the plates live; `SceneStage.arena_for`
## is the one reader and falls back to the kind rule when this answers "".
## The key is per kind because Q-96 keys the arena on the RAID, not the
## encounter: `{"adventure": "stage_arena_cave", "raid": "stage_arena_dungeon"}`.
## A tier row with no `scene`, or a `scene` that is a bare string, answers that
## string for every kind (one plate for the whole tier).
static func tier_scene(tier: int, kind: String) -> String:
    var text := FileAccess.get_file_as_string(DATA_DIR + "tier_words.json")
    if text.is_empty():
        return ""
    var doc = JSON.parse_string(text)
    if not (doc is Dictionary):
        return ""
    var row = (doc.get("tiers", {}) as Dictionary).get(str(tier), null)
    if not (row is Dictionary):
        return ""
    var scene = row.get("scene", null)
    if scene is String:
        return scene
    if scene is Dictionary:
        return String(scene.get(kind, ""))
    return ""


## The shipped content set: the shared files, plus every tier that is on disk
## AND named.
static func default_paths() -> Dictionary:
    var out: Dictionary = DEFAULT_PATHS.duplicate(true)
    var found: Array = []
    for tier in range(1, MAX_TIER + 1):
        var tp: Dictionary = tier_paths(tier)
        # The raid encounter file is the tier's marker. A tier whose other three
        # files are missing still mounts and reports them: a half-authored tier
        # is a content error the boot screen should name, not a silence.
        if FileAccess.file_exists(String(tp["encounters"])) and tier_is_named(tier):
            found.append(tp)
    out["tiers"] = found
    return out


static func load_all(paths: Dictionary = {}):
    var db = _cls().new()
    db._load(default_paths() if paths.is_empty() else paths)
    return db


func is_valid() -> bool:
    return errors.is_empty()


## A single multi-line report, suitable for a boot-time failure screen.
func error_report() -> String:
    if errors.is_empty():
        return "content OK: %d classes, %d items, %d tier(s)" \
            % [classes.size(), items.size(), tiers.size()]
    return "content FAILED with %d problem(s):\n  - %s" % [errors.size(), "\n  - ".join(errors)]


func _err(msg: String) -> void:
    errors.append(msg)


func _read_json(path: String, label: String):
    if not FileAccess.file_exists(path):
        _err("%s: file not found (%s)" % [label, path])
        return null
    var text := FileAccess.get_file_as_string(path)
    if text.is_empty():
        _err("%s: file is empty (%s)" % [label, path])
        return null
    var parsed = JSON.parse_string(text)
    if parsed == null:
        _err("%s: not valid JSON (%s)" % [label, path])
        return null
    if not (parsed is Dictionary):
        _err("%s: expected a JSON object at the top level" % label)
        return null
    return parsed


func _load(paths: Dictionary) -> void:
    var classes_doc = _read_json(String(paths.get("classes", "")), "classes")
    if classes_doc != null:
        _load_classes(classes_doc)

    var manifest: Array = paths.get("tiers", [])
    for entry in manifest:
        tiers.append(int(entry.get("tier", 1)))

    # Item files, in ladder order so ids collide predictably if anything
    # repeats: starting gear, then each tier's Adventure rung and its Raid.
    var starting_doc = _read_json(String(paths.get("starting", "")), "starting")
    if starting_doc != null:
        _load_items(starting_doc, "starting")
    # Tier 0's other half. Loaded here rather than with the tutorial ENCOUNTERS
    # below, because this loop is the one that owns item ids and a duplicate id
    # has to collide against the rest of tier 0 before any tier mounts.
    var tutorial_items_doc = _read_json(String(paths.get("tutorial_items", "")), "tutorial items")
    if tutorial_items_doc != null:
        _load_items(tutorial_items_doc, "tutorial")
    for entry in manifest:
        var tier: int = int(entry.get("tier", 1))
        for label in ["adventure", "raid"]:
            var doc = _read_json(String(entry.get(label, "")), "%s t%d" % [label, tier])
            if doc != null:
                _check_tier_header(doc, tier, "%s t%d" % [label, tier])
                _load_items(doc, label, tier)

    # Cross-file wiring, only once EVERY tier's items exist: a table is free to
    # point at gear from any tier that loaded, and Tier 2's tables landing
    # before Tier 1's items would otherwise read as a pile of unknown ids.
    if starting_doc != null:
        _load_starting_sets(starting_doc)
    for entry in manifest:
        var tier: int = int(entry.get("tier", 1))
        var raid_doc = _read_json(String(entry.get("raid", "")), "raid t%d" % tier)
        if raid_doc != null:
            _load_raid_tables(raid_doc, tier)
        # Adventures load through the same path as raid encounters: they are the
        # same record shape at a different party size, which is what lets the
        # board treat both as rungs (docs/10 §3).
        for label in ["encounters", "adventures"]:
            var enc_doc = _read_json(String(entry.get(label, "")), "%s t%d" % [label, tier])
            if enc_doc != null:
                _check_tier_header(enc_doc, tier, "%s t%d" % [label, tier])
                _load_encounters(enc_doc, tier)

    # Tutorials load through the same path as everything else — they are the
    # same record shape at a smaller party size, which is exactly the argument
    # the adventures comment above makes, and it is what lets the board treat
    # A0 and TR as rungs with no special case in the UI. Loaded LAST so that a
    # tutorial can never win a slot clash against authored ladder content.
    var tut_doc = _read_json(String(paths.get("tutorials", "")), "tutorials")
    if tut_doc != null:
        _check_tier_header(tut_doc, TUTORIAL_TIER, "tutorials")
        _load_encounters(tut_doc, TUTORIAL_TIER)

    _validate_cross_references()


## A per-tier file must agree with the rung it was mounted at. If it does not,
## its items and encounters carry a tier the manifest disagrees with, and every
## tier filter downstream reads the wrong rung — sim/core/Loot.gd's drop pools
## and doc 03 §6.2's obsolescence factor both key on it.
func _check_tier_header(doc: Dictionary, tier: int, where: String) -> void:
    var declared: int = int(doc.get("tier", tier))
    if declared != tier:
        _err("%s: file header says tier %d but it is loaded as tier %d"
            % [where, declared, tier])


# ---------------------------------------------------------------- classes

func _load_classes(doc: Dictionary) -> void:
    rarity_hp_multiplier = doc.get("rarity_hp_multiplier", {})
    var raw: Array = doc.get("classes", [])
    if raw.size() != Enums.CLASS_KEYS.size():
        _err("classes: expected %d classes, found %d"
            % [Enums.CLASS_KEYS.size(), raw.size()])

    for entry in raw:
        var cd = ClassDef.new()
        cd.key = String(entry.get("key", ""))
        cd.index = Enums.class_from_key(cd.key)
        if cd.index < 0:
            _err("classes: unknown class key '%s'" % cd.key)
            continue
        cd.name = String(entry.get("name", ""))
        cd.description = String(entry.get("description", ""))
        cd.base_hp = int(entry.get("base_hp", 0))
        cd.two_handed = bool(entry.get("two_handed", false))
        cd.dual_wield = bool(entry.get("dual_wield", false))

        cd.role = Enums.role_from_key(String(entry.get("role", "")))
        if cd.role < 0:
            _err("classes/%s: unknown role '%s'" % [cd.key, entry.get("role", "")])
        cd.role_group = Enums.role_group_from_key(String(entry.get("role_group", "")))
        if cd.role_group < 0:
            _err("classes/%s: unknown role_group '%s'" % [cd.key, entry.get("role_group", "")])
        elif cd.role >= 0 and Enums.role_group_of(cd.role) != cd.role_group:
            _err("classes/%s: role '%s' does not belong to group '%s'"
                % [cd.key, entry.get("role"), entry.get("role_group")])

        cd.primary_stat = Enums.stat_from_key(String(entry.get("primary_stat", "")))
        if cd.primary_stat < 0:
            _err("classes/%s: unknown primary_stat '%s'" % [cd.key, entry.get("primary_stat", "")])
        for s in entry.get("secondary_stats", []):
            var kind := Enums.stat_from_key(String(s))
            if kind < 0:
                _err("classes/%s: unknown secondary stat '%s'" % [cd.key, s])
            else:
                cd.secondary_stats.append(kind)

        if cd.base_hp <= 0:
            _err("classes/%s: base_hp must be positive, got %d" % [cd.key, cd.base_hp])

        var fams: Dictionary = entry.get("families", {})
        cd.head_family = _family_of(fams.get("head"), cd.key, "head")
        cd.body_family = _family_of(fams.get("body"), cd.key, "body")
        cd.main_hand_family = _family_of(fams.get("main_hand"), cd.key, "main_hand")
        cd.off_hand_family = _family_of(fams.get("off_hand"), cd.key, "off_hand")

        # Structural rule from the canon matrix: a two-handed class has no off-hand.
        if cd.two_handed and cd.off_hand_family >= 0:
            _err("classes/%s: two-handed classes must have a null off_hand" % cd.key)
        if not cd.two_handed and cd.off_hand_family < 0:
            _err("classes/%s: only two-handed classes may omit an off_hand" % cd.key)
        if cd.dual_wield and cd.off_hand_family != cd.main_hand_family:
            _err("classes/%s: a dual-wielding class must use one family in both hands" % cd.key)

        # Every family the class names must claim it back.
        for slot in Enums.all_slots():
            var fam: int = cd.family_for_slot(slot)
            if fam >= 0 and not Enums.class_can_use_family(cd.index, fam):
                _err("classes/%s: family '%s' on slot '%s' does not claim this class"
                    % [cd.key, Enums.family_key(fam), Enums.slot_key(slot)])

        classes.append(cd)
        _class_by_key[cd.key] = cd

    # Canon order matters: enum values index this array directly.
    for i in classes.size():
        if classes[i].index != i:
            _err("classes: entry %d is '%s' but Enums expects '%s' — order must match"
                % [i, classes[i].key, Enums.class_key(i)])
            break

    for key in Enums.RARITY_KEYS:
        if not rarity_hp_multiplier.has(key):
            _err("classes: rarity_hp_multiplier is missing '%s'" % key)


func _family_of(value, class_key: String, slot_label: String) -> int:
    if value == null:
        return -1
    var fam := Enums.family_from_key(String(value))
    if fam < 0:
        _err("classes/%s: unknown family '%s' on %s" % [class_key, value, slot_label])
    return fam


# ---------------------------------------------------------------- items

## `default_tier` is the rung the manifest mounted this file at. It is only a
## fallback: the file header wins when it states a tier, and `_check_tier_header`
## has already complained if the two disagree.
func _load_items(doc: Dictionary, label: String, default_tier: int = 0) -> void:
    var tier := int(doc.get("tier", default_tier))
    var source := String(doc.get("source", label))
    for entry in doc.get("items", []):
        var it = Item.new()
        it.id = String(entry.get("id", ""))
        if it.id.is_empty():
            _err("%s: an item has no id" % label)
            continue
        if items.has(it.id):
            _err("%s: duplicate item id '%s'" % [label, it.id])
            continue
        it.name = String(entry.get("name", ""))
        if it.name.is_empty():
            _err("%s/%s: item has no name" % [label, it.id])
        it.tier = tier
        it.source = source
        it.canon = bool(entry.get("canon", true))
        it.two_handed = bool(entry.get("two_handed", false))
        it.heal_base = int(entry.get("heal_base", 0))
        it.note = String(entry.get("note", ""))
        it.drop_encounter = int(entry.get("boss", -1))

        it.slot = Enums.slot_from_key(String(entry.get("slot", "")))
        if it.slot < 0:
            _err("%s/%s: unknown slot '%s'" % [label, it.id, entry.get("slot", "")])
        it.family = Enums.family_from_key(String(entry.get("family", "")))
        if it.family < 0:
            _err("%s/%s: unknown family '%s'" % [label, it.id, entry.get("family", "")])

        var stat_errors: Array = []
        it.stats = Stats.from_dict(entry.get("stats", {}), stat_errors, "%s/%s" % [label, it.id])
        for e in stat_errors:
            _err(String(e))
        if it.stats.is_empty():
            _err("%s/%s: item carries no stats" % [label, it.id])

        if not it.canon and it.note.is_empty():
            _err("%s/%s: non-canon items must cite their derivation in `note`" % [label, it.id])

        items[it.id] = it
        var index_key := "%d:%d" % [it.family, it.slot]
        if not _by_family_slot.has(index_key):
            _by_family_slot[index_key] = []
        _by_family_slot[index_key].append(it)


func _load_starting_sets(doc: Dictionary) -> void:
    var sets: Dictionary = doc.get("starting_sets", {})
    for class_key in sets.keys():
        if Enums.class_from_key(String(class_key)) < 0:
            _err("starting_sets: unknown class '%s'" % class_key)
            continue
        var resolved := []
        var seen_slots := {}
        for id in sets[class_key]:
            if not items.has(id):
                _err("starting_sets/%s: unknown item '%s'" % [class_key, id])
                continue
            var it = items[id]
            if seen_slots.has(it.slot):
                _err("starting_sets/%s: two items for slot '%s'"
                    % [class_key, Enums.slot_key(it.slot)])
            seen_slots[it.slot] = true
            resolved.append(it)
        if resolved.size() != 4:
            _err("starting_sets/%s: expected 4 pieces, got %d" % [class_key, resolved.size()])
        starting_sets[class_key] = resolved

    for key in Enums.CLASS_KEYS:
        if not starting_sets.has(key):
            _err("starting_sets: no set for class '%s'" % key)


## One tier's per-class loot grid. Every tier repeats the whole class × boss
## grid (docs/10 §4.1), so the tier is the outer key — indexing by class alone
## let Tier 2 silently take Tier 1's table.
func _load_raid_tables(doc: Dictionary, tier: int) -> void:
    var where := "class_tables t%d" % tier
    var per_class := {}
    var tables: Dictionary = doc.get("class_tables", {})
    for class_key in tables.keys():
        if Enums.class_from_key(String(class_key)) < 0:
            _err("%s: unknown class '%s'" % [where, class_key])
            continue
        var per_boss := {}
        for boss_key in tables[class_key].keys():
            var boss := int(boss_key)
            if boss < 1 or boss > 5:
                _err("%s/%s: encounter '%s' out of range 1-5" % [where, class_key, boss_key])
                continue
            var resolved := []
            for id in tables[class_key][boss_key]:
                if not items.has(id):
                    _err("%s/%s: unknown item '%s'" % [where, class_key, id])
                    continue
                resolved.append(items[id])
            per_boss[boss] = resolved
        for b in range(1, 6):
            if not per_boss.has(b) or per_boss[b].is_empty():
                _err("%s/%s: nothing drops at encounter %d" % [where, class_key, b])
        per_class[class_key] = per_boss

    for key in Enums.CLASS_KEYS:
        if not per_class.has(key):
            _err("%s: no table for class '%s'" % [where, key])
    raid_tables[tier] = per_class

    var pool: Array = []
    for id in doc.get("boss5_trinket_pool", []):
        if not items.has(id):
            _err("boss5_trinket_pool t%d: unknown item '%s'" % [tier, id])
            continue
        var it = items[id]
        if it.family != Enums.ItemFamily.UNIVERSAL_TRINKET:
            _err("boss5_trinket_pool t%d: '%s' is not a universal trinket" % [tier, id])
        pool.append(it)
    if pool.is_empty():
        _err("boss5_trinket_pool t%d: pool is empty" % tier)
    _trinket_pool_by_tier[tier] = pool
    if tier == 1:
        trinket_pool = pool


# ---------------------------------------------------------------- encounters

## `tier` is the rung the manifest mounted this file at, and it is what the
## index keys on. A record may restate it (the shipped files do) but must not
## contradict it — `_check_tier_header` has already reported a file-level
## disagreement, and `Encounter.from_dict` defaults an unstated tier to 1, which
## would be wrong for every tier but the first.
func _load_encounters(doc: Dictionary, tier: int) -> void:
    for raw in doc.get("encounters", []):
        var errs: Array = []
        var enc = Encounter.from_dict(raw, errs)
        for e in errs:
            _err(String(e))
        if enc.id.is_empty():
            continue
        if encounters.has(enc.id):
            _err("encounters: duplicate id '%s'" % enc.id)
            continue
        if int(raw.get("tier", tier)) != tier:
            _err("encounters/%s: record says tier %d but the file is tier %d"
                % [enc.id, int(raw.get("tier", tier)), tier])
        enc.tier = tier
        encounters[enc.id] = enc
        var slot_key := _slot_key(enc.tier, enc.slot)
        # Two fights claiming one rung is unreachable content: the board and
        # every accessor here read a rung through exactly one record, so the
        # second would be invisible. First authored wins, and the clash is named.
        if _encounters_by_slot.has(slot_key):
            _err("encounters: '%s' and '%s' both claim tier %d slot '%s'"
                % [_encounters_by_slot[slot_key].id, enc.id, enc.tier, enc.slot])
            continue
        _encounters_by_slot[slot_key] = enc


static func _slot_key(tier: int, slot: String) -> String:
    return "%d:%s" % [tier, slot]


func encounter(id: String):
    return encounters.get(id)


## The fight at one rung of one tier — `encounter_at(1, "E5")` is Raid 1's main
## boss. Slot names repeat every tier, so the tier is not optional.
func encounter_at(tier: int, slot: String):
    return _encounters_by_slot.get(_slot_key(tier, slot))


## Tier-1 shim, kept rather than migrated: `encounter_at_slot` has call sites
## across a dozen test files plus tools/, and every one of them means Tier 1.
func encounter_at_slot(slot: String):
    return encounter_at(1, slot)


## The five raid encounters of a tier, in slot order.
## The Adventure ladder in order. docs/10 §8: three encounters, two trash and a
## mini boss, played at HALF headcount in the previous tier's gear. This is the
## content that carries a guild from canon starting armour to Raid 1 entry, so
## it is the board's real first rung.
func adventure_encounters(tier: int = 1) -> Array:
    var out := []
    for slot in ["A1", "A2", "A3"]:
        var enc = encounter_at(tier, slot)
        if enc != null:
            out.append(enc)
    return out


## The two onboarding rungs, in canon's order (docs/10 §9.1: Adventure 0 then
## the Tutorial Raid). Only Tier 1 has them, so every other tier answers empty
## and the board's per-tier loop needs no special case.
func tutorial_encounters(tier: int = 1) -> Array:
    var out := []
    for slot in TUTORIAL_SLOTS:
        var enc = encounter_at(tier, slot)
        if enc != null:
            out.append(enc)
    return out


## docs/10 §4.2's Boss 5 trinket pool for a tier. The pool is loaded and
## validated per tier (`_load_raid_tables`) and was then read by nobody:
## `Loot` picked the first trinket it found by sorted id, so three of the four
## could never drop at all. An accessor is what that map was for.
func trinket_pool_for(tier: int) -> Array:
    return _trinket_pool_by_tier.get(tier, [])


func raid_encounters(tier: int = 1) -> Array:
    var out := []
    for slot in ["E1", "E2", "E3", "E4", "E5"]:
        var enc = encounter_at(tier, slot)
        if enc != null:
            out.append(enc)
    return out


# ---------------------------------------------------------------- cross-checks

## The rules that are about a TIER rather than about one encounter.
##
## The per-encounter rules (one mechanic per star, the enrage formula, a comedy
## line) are checked as each record loads. These four are checked once per tier,
## after everything is mounted, because none of them can be seen from inside a
## single record — and two of them are about the relationship BETWEEN tiers,
## which is exactly where generated content goes wrong: every record can be
## individually legal while the ladder has a step down in the middle of it.
##
## Written as a PURE function of {tier: [encounters]} so a test can feed it a
## synthetic tier that breaks each rule and read the error back. A validator
## nobody can make fail is a validator nobody has tested.
static func tier_rule_problems(by_tier: Dictionary) -> Array:
    var problems: Array = []
    var seen_mechanics := {}          # mechanic id -> the first tier that used it
    var previous_by_slot := {}        # slot -> the tier below's encounter in it
    var ordered: Array = by_tier.keys()
    ordered.sort()
    for tier in ordered:
        var raid: Array = by_tier[tier]
        if raid.is_empty():
            continue

        # 1. COVERAGE (docs/10 §10), in the two halves it actually has.
        #
        # The obvious reading — "all four role groups before E5" — is impossible
        # at Tier 1, and the shipped test already knows it: the only mechanic
        # that stresses SUPPORT is M10 Mana Burn, and docs/10 §473 says Tier 1
        # uses M01-M06, M08 and M09, with M07 and M10-M12 arriving above it.
        # Demanding SUPPORT everywhere would fail canon's own tier.
        #
        # So: the three groups Tier 1's vocabulary CAN stress must be stressed
        # before the boss, AND the boss must not be the first fight to test any
        # group. The second half carries the design intent — "a tier can be
        # beaten by one lopsided roster" is what happens when E5 is where your
        # healers first find out.
        var covered := {}
        var at_boss := {}
        for enc in raid:
            if String(enc.slot) == "E5":
                for group in enc.stressed_role_groups():
                    at_boss[group] = true
                continue
            for group in enc.stressed_role_groups():
                covered[group] = true
        for group in [Enums.RoleGroup.TANK, Enums.RoleGroup.HEALER, Enums.RoleGroup.DPS]:
            if not covered.has(group):
                problems.append("tier %d: nothing before E5 stresses %s (docs/10 §10 coverage rule)"
                    % [tier, Enums.role_group_key(group)])
        for group in at_boss.keys():
            if not covered.has(group):
                problems.append("tier %d: E5 is the first fight that stresses %s (docs/10 §10)"
                    % [tier, Enums.role_group_key(group)])

        # 2. ESCALATION (docs/10 §473): "A tier introduces at most TWO mechanics
        # the player has not seen ... new tiers get harder by number and overlap
        # of mechanics, not by novelty". A tier that teaches five new things at
        # once is a tutorial, not a difficulty step.
        var fresh: Array[String] = []
        for enc in raid:
            for m in enc.mechanics:
                if not seen_mechanics.has(m.mechanic):
                    seen_mechanics[m.mechanic] = tier
                    if int(tier) > 1:
                        fresh.append(Enums.mechanic_key(m.mechanic))
        if fresh.size() > MAX_NEW_MECHANICS_PER_TIER:
            problems.append("tier %d introduces %d mechanics the player has not seen (%s);"
                % [tier, fresh.size(), ", ".join(fresh)]
                + " docs/10's escalation rule allows %d" % MAX_NEW_MECHANICS_PER_TIER)

        # 3. THE LADDER DOES NOT STEP DOWN — compared SLOT BY SLOT, which is the
        # only comparison that means anything. "Tier N+1's E1 must beat tier N's
        # E5" sounds right and is wrong: E1 is a twelve-round opening pull and E5
        # is a twenty-two-round boss, so E1 legitimately holds less total HP.
        # What must never fall is the same slot one tier up.
        if not previous_by_slot.is_empty():
            for enc in raid:
                var key := String(enc.slot)
                if not previous_by_slot.has(key):
                    continue
                var below = previous_by_slot[key]
                if enc.total_hp() <= below.total_hp():
                    problems.append("tier %d %s has %d HP, which does not beat the tier below's %d"
                        % [tier, key, enc.total_hp(), below.total_hp()])
                if enc.primary_raw_per_round() <= below.primary_raw_per_round():
                    problems.append("tier %d %s swings %d per round, which does not beat the tier below's %d"
                        % [tier, key, enc.primary_raw_per_round(), below.primary_raw_per_round()])
        previous_by_slot = {}
        for enc in raid:
            previous_by_slot[String(enc.slot)] = enc

        # 4. NO ORPHAN MECHANIC. An encounter naming a mechanic the vocabulary
        # does not have is content that cannot resolve, and it would surface as
        # a fight that silently does nothing rather than as a loading error.
        for enc in raid:
            for m in enc.mechanics:
                if m.mechanic < 0 or m.mechanic >= Enums.Mechanic.size():
                    problems.append("tier %d %s: mechanic id %d is not in the vocabulary"
                        % [tier, enc.slot, m.mechanic])
    return problems


func _validate_tier_rules() -> void:
    var by_tier := {}
    for tier in tiers:
        var raid: Array = raid_encounters(tier)
        if not raid.is_empty():
            by_tier[tier] = raid
    for problem in tier_rule_problems(by_tier):
        _err(problem)


func _validate_cross_references() -> void:
    _validate_tier_rules()

    # Every item must be wearable by someone, or it is unreachable content.
    for id in items.keys():
        var it = items[id]
        if it.family >= 0 and it.eligible_classes().is_empty():
            _err("%s: belongs to family '%s' which no class can use"
                % [id, Enums.family_key(it.family)])

    # Every raider must actually be able to equip everything handed to them.
    for class_key in starting_sets.keys():
        var cd = _class_by_key.get(class_key)
        if cd == null:
            continue
        for it in starting_sets[class_key]:
            if not it.can_be_used_by(cd.index):
                _err("starting_sets/%s: cannot equip '%s'" % [class_key, it.id])
    for tier in raid_tables.keys():
        var per_class: Dictionary = raid_tables[tier]
        for class_key in per_class.keys():
            var cd2 = _class_by_key.get(class_key)
            if cd2 == null:
                continue
            for boss in per_class[class_key].keys():
                for it in per_class[class_key][boss]:
                    if not it.can_be_used_by(cd2.index):
                        _err("class_tables t%d/%s: cannot equip '%s' from encounter %d"
                            % [tier, class_key, it.id, boss])
                    # A class with no off-hand must never be handed one.
                    if it.slot == Enums.Slot.OFF_HAND and not cd2.has_off_hand():
                        _err("class_tables t%d/%s: two-handed class receives off-hand '%s'"
                            % [tier, class_key, it.id])

    # Canon drop pattern: B1 feet, B2 legs, B3 head, B4 chest, B5 capstone. It
    # is checked per tier by walking the index, so every tier that loads is
    # held to it and none has to be named here.
    var canon_slot_for := {"E1": "feet", "E2": "legs", "E3": "head", "E4": "chest"}
    for slot_key in _encounters_by_slot.keys():
        var enc = _encounters_by_slot[slot_key]
        if not canon_slot_for.has(enc.slot):
            continue
        if not (canon_slot_for[enc.slot] in enc.loot_slots):
            _err("%s: canon drops '%s' at %s but its loot_slots are %s"
                % [enc.id, canon_slot_for[enc.slot], enc.slot, str(enc.loot_slots)])


# ---------------------------------------------------------------- queries

func class_by_key(key: String):
    return _class_by_key.get(key)


func class_of(char_class: int):
    if char_class < 0 or char_class >= classes.size():
        return null
    return classes[char_class]


func item(id: String):
    return items.get(id)


func items_for(family: int, slot: int) -> Array:
    return _by_family_slot.get("%d:%d" % [family, slot], [])


## Everything a class can equip in a given slot, across every tier loaded.
func items_for_class_slot(char_class: int, slot: int) -> Array:
    var cd = class_of(char_class)
    if cd == null:
        return []
    var fam: int = cd.family_for_slot(slot)
    if fam < 0:
        return []
    return items_for(fam, slot)


func starting_set(class_key: String) -> Array:
    return starting_sets.get(class_key, [])


## What one class can win from one raid encounter. `tier` defaults to 1 so the
## Tier-1 callers already in the tree keep reading the rung they mean.
func raid_drops(class_key: String, encounter: int, tier: int = 1) -> Array:
    var per_class: Dictionary = raid_tables.get(tier, {})
    var per_boss: Dictionary = per_class.get(class_key, {})
    return per_boss.get(encounter, [])


## The tier's Boss 5 universal trinket pool (docs/10 §4.2).
func trinkets(tier: int = 1) -> Array:
    return _trinket_pool_by_tier.get(tier, [])


func hp_multiplier_for(rarity: int) -> float:
    return float(rarity_hp_multiplier.get(Enums.rarity_key(rarity), 1.0))


## Total stats a class ends a tier wearing, taking the last item per slot.
## Tier-scoped: reading every tier's tables at once would report gear the guild
## cannot have reached yet, which is exactly what a tier-blind sum did.
func best_in_slot_stats(class_key: String, tier: int = 1) -> Variant:
    var best := {}
    var per_class: Dictionary = raid_tables.get(tier, {})
    var table: Dictionary = per_class.get(class_key, {})
    for boss in range(1, 6):
        for it in table.get(boss, []):
            best[it.slot] = it
    var blocks := []
    for slot in best.keys():
        blocks.append(best[slot].stats)
    return Stats.sum(blocks)
