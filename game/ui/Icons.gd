extends RefCounted
## Icons — the one lookup for every glyph the kit and the screens draw
## (00-plan §W1-ICONS, CRITIC-G07/C03). `Icons.at(role, key)` is the only door:
## no screen or widget names an icon path or a pixel size any more; this file
## holds the size table and the directory layout, tools/aseprite/gen_icons.lua
## emits the files (deterministic; verify.sh stage 2b byte-checks them), and
## tests/unit/test_icons.gd walks the two against each other.
##
## The grid (docs: PIPE §1.8, CRITIC-G07 — "an icon at role R is N px"):
##   class / emote / arrow / lock 16 · blot 12 · log 22 · state / mech / bar /
##   face / control 24 · rank 28 · building / empty / item / furnishing / slot 32 ·
##   sigil 48.
##
## Layout: names a screen already loads by path (rank_<key> in Frame.gd,
## mech_<key> in RaidView.gd, face_N, slot_*, the four potions, the page
## arrows, cog_24, fast_forward_24) stay at the top of game/assets/ui/icons/;
## everything the overhaul adds lives in icons/grid/. `path()` looks in grid/
## first, then the top level, and a name that is in neither is a
## `push_error`, never a silent null (LESSONS: "built vs armed").
##
## Consumers preload this script (it registers no global class — invariant 7/8)
## and call the static functions; textures cross unit lines as Texture2D
## parameters.

const Enums = preload("res://sim/model/Enums.gd")

const DIR := "res://game/assets/ui/icons/"
const GRID := DIR + "grid/"
const MANIFEST := GRID + "icons.json"

## Q18 (00-plan §0.6): the warrior's identifying glyph. "swords" = the
## reference's crossed swords (spec 01/02); "shield" = docs/12 §5.1's shield
## silhouette, which gen_icons.lua emits beside it as class_warrior_shield.
const WARRIOR_GLYPH := "swords"

## role -> cell size in px (the grid). Icons.size(role) reads this; the
## manifest gen_icons.lua writes carries the same table and the test compares.
const SIZES := {
	"class": 16, "emote": 16, "arrow": 16, "lock": 16,
	"blot": 12,
	"log": 22,
	"state": 24, "mech": 24, "bar": 24, "face": 24, "control": 24,
	"rank": 28,
	"building": 32, "empty": 32, "item": 32, "furnishing": 32, "slot": 32,
	"sigil": 48,
}

## role -> file-name prefix; the key follows (`blot` files are blot_12_<a|b|c>,
## `lock` is lock_16, `control` names are the whole file name).
const PREFIX := {
	"class": "class_", "emote": "emote_", "arrow": "arrow_", "lock": "lock_",
	"blot": "blot_12_", "log": "log_", "state": "state_", "mech": "mech_",
	"bar": "bar_", "face": "face_", "control": "", "rank": "rank_",
	"building": "building_", "empty": "empty_", "item": "item_",
	"furnishing": "furnishing_", "slot": "slot_", "sigil": "sigil_",
}

## The sim's named per-raider states that carry a plate (PIPE-07; anything
## else is Q18). swap_stack's plate is bare — its numeral is a Label.
const STATE_KEYS := ["downed", "dead", "at_risk", "tanking", "swap_stack", "fixated", "mana_burn", "healing_debuff"]
## Log-event kinds (KIT-07 Table A); `badge_<kind>` naming is retired.
const LOG_KINDS := ["mistake", "heal", "raider_attack", "boss_attack", "mechanic", "phase", "system",
	"morale_up", "morale_down", "loot", "gold", "recruit"]
## The five hub buildings (00 §2.6) and the three empty-state glyphs (KIT-08).
const BUILDING_KEYS := ["guildhall", "tavern", "market", "blacksmith", "board"]
const EMPTY_KEYS := ["quill", "bench", "shelf"]
## The A1-S8 emote set (TOWN-26, spec 06 §8).
const EMOTE_KEYS := ["dots", "exclaim", "question", "heart", "zzz", "sweat", "skull", "mug", "note", "anger"]

## A name the grid does not draw yet, served by a file it does: `role/key` ->
## [role, key] of the file that stands in. W7-REPORT: the reputation feed row
## (LOOP-13, the kind W7-SAVE writes) wants a 22px `log_reputation` glyph and
## `gen_icons.lua` is W9-ART's this wave, so until it draws one the rank
## sigil the header chip already carries (`rank_known`) is the glyph — a stand-
## in by NAME, resolved here, so the call site reads `Icons.at("log",
## "reputation")` today and nothing moves when the real file lands (the grid
## is searched first; an alias is only consulted when the name has no file).
## Not in `LOG_KINDS`: that list is the set the generator emits.
const ALIASES := {
	"log/reputation": ["rank", "known"],
}

## The strong cache (W5-MOUNT): a resolved path per role+key (two exists()
## checks a call, on every icon of every card of every page turn) and the
## loaded texture per path, held for the life of the process so the weak
## resource cache cannot drop a glyph between two visits to a screen. The
## same object every time; `at()` still push_errors a missing name.
static var _path_cache: Dictionary = {}   # "role/key" -> res:// path ("" = none)
static var _tex_cache: Dictionary = {}    # res:// path -> Texture2D


## Cell size of a role in px, 0 for a role the grid does not have.
static func size(role: String) -> int:
	return int(SIZES.get(role, 0))


## Every role the grid has, in size order.
static func roles() -> Array:
	return SIZES.keys()


## Enums.MECHANIC_KEYS are m01..m12; the files are named by the Enums.Mechanic
## enum key lower-cased (mech_tank_swap), which is what RaidView already does.
## Accepts either spelling and returns the file spelling ("" when unknown).
static func mech_key(key: String) -> String:
	var idx: int = Enums.MECHANIC_KEYS.find(key)
	if idx < 0:
		idx = Enums.Mechanic.keys().map(func(k): return String(k).to_lower()).find(key)
	if idx < 0 or idx >= Enums.Mechanic.size():
		return ""
	return String(Enums.Mechanic.keys()[idx]).to_lower()


## The file name (no directory, no extension) for a role + key.
static func file_name(role: String, key: String) -> String:
	if not PREFIX.has(role):
		return ""
	var k := key
	if role == "mech":
		k = mech_key(key)
		if k == "":
			return ""
	elif role == "class" and key == "warrior" and WARRIOR_GLYPH == "shield":
		k = "warrior_shield"
	return String(PREFIX[role]) + k


## The res:// path of the PNG for a role + key, or "" when no such file exists.
## grid/ first (the overhaul's files), then the top level (the names screens
## load by path). A name must not exist in both — test_icons.gd pins that.
static func path(role: String, key: String) -> String:
	var id := role + "/" + key
	if _path_cache.has(id):
		return String(_path_cache[id])
	var found := _resolve(role, key)
	_path_cache[id] = found
	return found


static func _resolve(role: String, key: String) -> String:
	var name := file_name(role, key)
	if name == "":
		return ""
	var in_grid := GRID + name + ".png"
	if ResourceLoader.exists(in_grid):
		return in_grid
	var legacy := DIR + name + ".png"
	if ResourceLoader.exists(legacy):
		return legacy
	var alias = ALIASES.get(role + "/" + key, null)
	if alias is Array and alias.size() == 2:
		return _resolve(String(alias[0]), String(alias[1]))
	return ""


static func exists(role: String, key: String) -> bool:
	return path(role, key) != ""


## The texture for a role + key. A missing file is an error at the call site
## (push_error) and returns null so the caller's slot stays empty visibly,
## never a stand-in that hides the gap.
static func at(role: String, key: String) -> Texture2D:
	var p := path(role, key)
	if p == "":
		push_error("Icons.at(\"%s\", \"%s\"): no icon file — gen_icons.lua emits none by that name (role size %d)" % [role, key, size(role)])
		return null
	var cached = _tex_cache.get(p, null)
	if cached != null:
		return cached
	var tex := load(p) as Texture2D
	if tex == null:
		push_error("Icons.at(\"%s\", \"%s\"): %s did not load as a texture" % [role, key, p])
	else:
		_tex_cache[p] = tex
	return tex
