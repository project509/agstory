extends Control
## The illustrated scene, made to move.
##
## art/ref/specs/11 §5 and 09 §4–5: a plate at 1:1 with a few living layers on
## top — flames on the painted hearth, a warm light that breathes, embers, and
## the cream speech bubbles that drift between the figures. Everything is
## authored as DATA in game/assets/scenes/<name>.json, so a scene is placed by
## editing numbers, not code, and the same node builds every scene.
##
## The layers are Node2Ds under a Control so a Frame scene host can hold the
## stage like any other child. Nothing here needs a display to construct: the
## test runner instantiates screens headless and this must build there too, so
## no call below assumes a rendering device.
##
##   var stage := SceneStage.load("stage_camp")
##   host.add_child(stage)
##
## JSON shape (all positions scene-local, in plate pixels):
##   { "plate": "res://…png",
##     "figure_scale": 2,        # every actor without its own `scale` (STAGE-02)
##     "props":  [{"strip": "res://…fire_hearth.png", "frame_w": 64, "fps": 9,
##                 "pos": [x, y], "anchor": "bottom", "emissive": 1.35}],
##                # anchor "topleft" for an opaque crop of the plate (a banner);
##                # no `emissive` = drawn as it is, no warm over-drive
##     "actors": [{"who": "cleric", "pos": [x, y], "scale": 2, "flip": true,
##                 "phase": 1, "fps": 5, "tint": "#E8DCC8"}],
##     "paths":  [{"who": "variant_r02_black", "points": [[x, y], [x, y], …],
##                 "px_per_s": 22, "phase": 0.5, "loop": false}],  # walkers (TOWN-27)
##     "rotor":  [{"tex": "res://…sail_a.png", "pos": [x, y], "rad_per_s": 0.18,
##                 "phase": 0.0}],                                    # sails (STAGE-14)
##     "flyers": [{"strip": "res://…gull.png", "frame_w": 12, "fps": 5,
##                 "points": [[x, y], …], "px_per_s": 14, "phase": 0.3,
##                 "loop": true, "scale": 1}],                        # gulls (STAGE-14)
##     "lights": [{"pos": [x, y], "color": "#FFB060", "energy": 1.1, "radius": 220,
##                 "flicker": 0.25}],
##     "embers": [{"pos": [x, y], "amount": 24, "spread": 14, "height": 90,
##                 "preset": "embers" | "motes", "color": "#…", "lifetime": 2.2,
##                 "size": 1.0}],
##     "shimmer": [{"rect": [x, y, w, h], "color": "#7FC8FF", "strength": 0.024}],
##     "pulse":   [{"rect": [x, y, w, h], "color": "#78C8FF", "energy": 0.16,
##                 "feather": 0.35}],
##     "scroll":  [{"tex": "res://…clouds_far.png", "rect": [x, y, w, h],
##                 "px_per_s": 2.5, "opacity": 0.6}],   # UV drift (STAGE-14)
##     "bubbles": [[x, y], [x, y, "emote:mug"], [x, y, "emote:skull", "wipe"], …],
##     "bubble_visible": 2,
##     "speech": {"pos": [x, y], "size": [w, h], "speaker": 4, "lines": ["…", …]},
##     "marks": {"view": [0, -280],
##               "party": {"scale": 2, "face": "right",
##                         "ranks": [{"y": 692, "xs": [468, 532, 596, 660]}, …]},
##               "boss": {"pos": [x, y], "scale": 1, "flip": true,
##                        "floor": [x, y, w, h]}},
##     "glow_threshold": 1.3 }
##
## `marks` is the fight's blocking (STAGE-01): the arena screens read it through
## `SceneStage.marks(name)` instead of carrying plate coordinates of their own,
## so the numbers live beside the plate they were measured on.
##
## The overlay layer (STAGE-04, CRITIC-C07): `head_of`, `say_at`, `number_at`
## and `bar_for` put Controls over a figure's head. They are children of the
## stage's "Overlay" node, which is kept ABOVE every figure and BELOW the
## screen's chrome, so the switches in `apply_settings` reach them the same way
## they reach everything else on the stage. The Labels they carry stay Labels
## inside the screen subtree, which is how the tests read words.
##
## The verbs (STAGE-03, STAGE-09, PIPE-02, CRITIC-C04 — W2-STAGE2): `act(spr,
## verb)` for attack / cast / fumble / death, `hit(spr)`, and the VFX
## primitives `add_fx`, `burst`, `bolt`, `slash`. They are WORLD-LAYER motion
## (RULES §2: the world layer's one door is `apply_settings`), so they run on
## the stage's own clock the way the boss bob and the held speech already do:
## `_beat(ms, floor_ms)` is `GameSettings.motion_duration`'s arithmetic held
## by the stage's own switch — every beat collapses to its floor under reduced
## motion, a flourish's rotation is multiplied by `_motion_scale()`, and a verb
## never branches on the setting. No Tween is made here (`Widgets.tween` is the
## UI's door and refuses a node outside a tree, which is where every test
## stage lives — see tests/unit/test_scene_stage.gd's verb tests).
##
## The boss (STAGE-08 — W3-ENEMIES): `place_boss` takes the rank's still and,
## when enemies.json names a strip for it, builds an AnimatedSprite2D with the
## table's `idle` / `hit` / `death` tags and a `BossGlow` child (the emissive
## eye layer, over-driven so it blooms). `hit` and `act(…, "death")` play the
## tags on such a boss; a still with no strip keeps the bob.
##
## Motion on paths (TOWN-27, STAGE-14 — W4-LIFE): three layers that MOVE
## across the plate rather than in place. `paths` sends a figure walking
## between points on the strip gen_actors.py derived as its walk
## (`add_walker`, depth re-settled every tick so the back-to-front rule holds
## while it moves); `rotor` turns a cut of the plate about its centre (the
## windmill sails, `add_rotor`); `flyers` ride a spline (the gulls,
## `add_flyer`). All three tick behind the reduced-motion gate in `_process`
## and are held where they stand by `apply_settings`; none is an effect, so
## reduced effects leaves them. The banners and the lantern flames are plain
## `props` (an opaque plate crop anchored top-left; a 6x8 strip on each lamp).

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Services = preload("res://game/core/Services.gd")
const Icons = preload("res://game/ui/Icons.gd")
## `arena_for` reads the tier row's `scene` through the content layer's one
## accessor (game/ reads sim/, never the reverse — BUILD_STATE invariant 2).
const ContentDB = preload("res://sim/content/ContentDB.gd")

const SCENES := "res://game/assets/scenes/"
const LIGHT_TEX := "res://game/assets/vfx/light_soft.png"
const EMBER_TEX := "res://game/assets/vfx/ember.png"
## The combat strips (W1-VFX) and the manifest that carries their geometry —
## `add_fx` reads frame_w/fps from it when the caller passes neither.
const VFX := "res://game/assets/vfx/"
const VFX_MANIFEST := VFX + "vfx.json"
## The hub's life strips (W4-LIFE: the lantern flame, the camp banners, the
## gull, the windmill sails) and their own table, written by gen_fire.lua —
## `add_flyer` reads frame_w/fps from it when the scene passes neither.
const LIFE := VFX + "life/"
const LIFE_MANIFEST := LIFE + "life.json"
## The actor strips and their geometry, written by tools/art/gen_actors.py.
## spec 09 §4.1 row 4 and §4.2 row 8 both used to read "ambient patrons/raiders
## — baked v1"; the bare plates of 2026-09-11 called that debt in, so the
## figures are nodes now and they breathe.
const ACTORS := "res://game/assets/actors/"
const ACTOR_MANIFEST := ACTORS + "actors.json"
## Which sliced figure stands for each canon class — hand-authored, decided by
## canon's equipment families (docs/15 BL-68). See the file's own `note`.
const CLASS_ACTORS := ACTORS + "class_actors.json"
## The boss table (W0-MANIFEST / PIPE-17, written by tools/aseprite/
## gen_boss_anims.lua since W3-ENEMIES): per rank the still the screens load
## by name, and — STAGE-08 — the animation strip derived from it (`strip`,
## `frame_w`, `frame_h`, `tags {name: [first, last, fps]}`) plus the emissive
## eye layer (`glow`) the stage over-drives by `glow_modulate` so the 2D glow
## catches it. `place_boss` reads the rank off the still's resource path.
const ENEMIES := "res://game/assets/enemies/"
const ENEMIES_TABLE := ENEMIES + "enemies.json"
const BOSS_GLOW_MODULATE := 1.6

## The arena a screen falls back to when it has no encounter to ask about —
## a prep screen before a notice is chosen, a report with no record, the
## Options preview. Every fight with an encounter goes through `arena_for`.
##
## Until 2026-09-15 this constant WAS the arena: two bare plates existed and
## nothing said which fight happened where (`docs/15` Q-96, audit
## M4B-CONV-04). Q-96 is ruled: the arena belongs to the RAID, so the rule is
## one static function below and the three screens pass their encounter.
const DEFAULT_ARENA := "stage_arena_cave"
## Q-96's two plates, by the encounter's kind.
const ARENA_RAID := "stage_arena_dungeon"
const ARENA_ADVENTURE := "stage_arena_cave"


## Which arena an encounter is fought in (Q-96, CRITIC-C15, CONTENT-26's
## contract): the tier row's `scene` in data/tier_words.json when it names
## one for the encounter's kind (`ContentDB.tier_scene`), else the kind rule
## — raid encounters (E1-E5, the slot's "E") fight in the dungeon, adventures
## and the tutorials (A0, TR, A1-A3) in the cave. Fighting TR in the cave
## keeps the dungeon as the thing Raid 1 earns. A null encounter, or one whose
## named scene has no JSON on disk, answers `DEFAULT_ARENA` — a wrong plate
## is worse than the familiar one. No `backdrop` key on the record: a
## per-encounter key would be a second truth for a fact the kind carries.
static func arena_for(encounter) -> String:
	if encounter == null:
		return DEFAULT_ARENA
	var slot := String(encounter.get("slot")).to_upper()
	var kind := "raid" if slot.begins_with("E") else "adventure"
	var named := ContentDB.tier_scene(int(encounter.get("tier")), kind)
	if not named.is_empty() and FileAccess.file_exists(SCENES + named + ".json"):
		return named
	return ARENA_RAID if kind == "raid" else ARENA_ADVENTURE

## spec 02 §5.1: the floating status bar's footprint and its parts, in pixels.
const BAR_SIZE := Vector2(96, 23)
const BAR_BADGE := 24
const BAR_PIP := 12
const BAR_PIP_PITCH := 14
const BAR_HP := Vector2i(62, 7)
## spec 02 §5.1 / §5.3: air between an overlay's bottom edge and the head.
const BAR_AIR := 6.0
## A speech tail's apex sits `TAIL_AIR` above the head (the same 6px the ambient
## bubbles keep, and STAGE-10's "within 6px"); the plate's bottom edge is then
## the tail's depth (Widgets.TAIL_H, 8) above that — `SAY_AIR` is the sum.
const TAIL_AIR := 6.0
const SAY_AIR := 14.0
## UI-34: a second number over one figure stacks ABOVE the first by that
## label's own height plus this air — 14px under a 35px glyph half-overlapped.
const NUMBER_AIR := 4.0
## UI-20: the speech plate lifts to `CROWD_AIR` above the topmost head it
## would otherwise cover, and clear of every `keep_out` rect (the screen's
## chrome, the callouts); the tail stretches down to the speaker.
const CROWD_AIR := 8.0
## UI-07: on a 1x scene (the tavern, the market) the plate wraps narrower, so
## a 40px figure is not speaking from under a plate five times its height.
const SAY_WRAP_1X := 140
## UI-26: the stage's lights and the stage's OWN canvas items share this
## light layer and nothing else does — `PointLight2D.range_item_cull_mask` on
## every light, `light_mask` on every plate, prop, figure, shadow, boss and
## effect the stage builds. A Control outside the stage keeps Godot's default
## layer 1, so a lantern by the camp's stew pot no longer shines through the
## Quarters panel above it (it lit every panel drawn later in the canvas).
const LIGHT_LAYER := 2

## The particle looks a scene can ask for by name. `embers` is the campfire
## (the birth colour is emissive so it blooms); `motes` is spec 09 §5 row 6's
## cave dust — 1-2px, cool, slow, long-lived, no damping; `smoke` is a
## chimney's plume (STAGE-14): grey, not emissive, drifting +x, born formed
## (`preprocess`) so a held stage still shows one. An entry's own `color` /
## `end` / `lifetime` / `size` / `velocity` / `direction` / `cone` /
## `preprocess` override the preset.
const EMBER_PRESETS := {
	"embers": {"color": "#FFC060", "end": "#99261A", "emissive": 1.6, "lifetime": 2.2,
		"size": 1.0, "damping": [4.0, 9.0], "gravity": -12.0},
	"motes": {"color": "#AAD4FF", "end": "#4D80B3", "emissive": 1.8, "lifetime": 6.0,
		"size": 0.4, "velocity": [8.0, 14.0], "damping": [0.0, 0.0], "gravity": -2.0},
	"smoke": {"color": "#C4C4CE", "end": "#6E6E7A", "emissive": 1.0, "lifetime": 5.0,
		"size": 2.6, "velocity": [8.0, 14.0], "damping": [0.0, 0.0], "gravity": -3.0,
		"direction": [0.45, -1.0], "cone": 10.0, "spread": 2, "amount": 12, "preprocess": 5.0},
}

## docs/12 §5.2's hit flash (#FFF6DC) and §5.3's fumble mark (#F2C14E), as the
## floats those hex values are: this file names no hex literal (W1-CHROME's
## rule), and handoff-W2-STAGE2.md asks Palette for FLASH_HIT / MARK_FUMBLE
## tokens so a later wave can repoint these two lines.
const FLASH_COLOR := Color(1.0, 0.965, 0.863)
const MARK_COLOR := Color(0.949, 0.757, 0.306)
## The cast's emissive lift: over 1.0 so the glow catches it (11 §6's threshold).
const CAST_TINT := Color(1.12, 1.08, 1.45)

## The verbs' numbers — docs/12 §5.2-5.3 and STAGE-03/09, in milliseconds and
## pixels. A beat with a `floor` keeps that many ms under reduced motion (the
## fumble's freeze is where its "!" is read; the hit's flash is information).
const ACTS := {
	"attack": {"lunge_px": 6.0, "out_ms": 90, "back_ms": 90},
	"cast": {"rise_px": 2.0, "up_ms": 150, "down_ms": 150},
	"fumble": {"lunge_px": 6.0, "lunge_ms": 120, "freeze_ms": 200, "tilt_deg": 12.0,
		"tilt_ms": 120, "recover_ms": 240},
	"death": {"tilt_deg": 45.0, "ms": 400},
	"hit": {"recoil_px": 2.0, "out_ms": 45, "back_ms": 45},
}
## A strip or a burst under reduced motion is one held frame, this long.
const FX_HOLD := 0.3
## The travel of a bolt (STAGE-03: 180ms) and the ghosts behind it.
const BOLT_MS := 180
const BOLT_TRAIL := 3

## What a burst of each `kind` looks like: the particle ramp (spec 02 §9.1's
## five measured families plus heal / spark / poof from the A1 sheet) and the
## strip that plays over it when W1-VFX drew one. Colours are data (hex strings
## read the way a scene's own `color` keys are), never `Color("…")` literals.
const BURST_KINDS := {
	"impact": {"color": "#FF6A3D", "end": "#7A1F12", "strip": "fx_burst_impact"},
	"fire": {"color": "#FFC060", "end": "#99261A", "strip": ""},
	"arcane": {"color": "#B08CFF", "end": "#3C1A80", "strip": ""},
	"slash": {"color": "#8FE8FF", "end": "#1F5C80", "strip": ""},
	"void": {"color": "#8A4DFF", "end": "#1A0A40", "strip": ""},
	"heal": {"color": "#C8FFB0", "end": "#2E8B3A", "strip": "fx_heal_sparkle"},
	"spark": {"color": "#FFF0B0", "end": "#B06020", "strip": "fx_spark_hit"},
	"poof": {"color": "#9A9AA6", "end": "#3A3A44", "strip": "fx_poof_smoke", "additive": false},
}
## A bolt is the one arcane strip tinted per kind (PIPE-02 drew one bolt).
const BOLT_TINTS := {
	"arcane": "#FFFFFF", "fire": "#FFB070", "void": "#9060FF", "heal": "#B0FFC0", "slash": "#A0F0FF",
}

var scene_name := ""
var _lights: Array = []          # [{node, base, flicker, noise, phase}]
var _bubbles: Array = []         # TextureRects
var _bubble_visible := 2
var _bubble_clock := 0.0
var _bubble_next := 2.5
var _speech: PanelContainer = null   # the one bubble that carries words
var _speech_label: Label = null
var _speech_speaker: Node2D = null   # the figure the speaking bubble hangs over (TOWN-03)
var _speech_speakers: Array = []     # the figures a line may come from (STAGE-10: rotated by line hash)
var _speech_named := false           # the scene NAMED a speaker; none built = the plate hides
var _speech_size := Vector2(182, 76)
var _speech_pos := Vector2.ZERO        # the authored spot, for a scene with no speaker
var _lines: Array = []
var _line_clock := 0.0
var _line_next := 6.0
var _noise: FastNoiseLite = null
var _t := 0.0
var _env: WorldEnvironment = null
var _props: Array = []          # AnimatedSprite2D
var _embers: Array = []         # GPUParticles2D
var _actors: Array = []         # AnimatedSprite2D, back to front
var _motion_held := false       # docs/13 §13 reduced motion, already applied
var _bobbers: Array = []        # [{node, base_y, amp, speed, phase}] — a single-texture boss breathes
var _bosses: Array = []         # [{spr, glow, tags}] — strip bosses with idle/hit/death tags (STAGE-08)
var _shimmers: Array = []       # ColorRects carrying the water shader
var _pulses: Array = []         # [{node, base, period, swing, phase}] — crystal light
var _figure_scale := 1.0        # the scene's `figure_scale`; see add_actor
var _plate_size := Vector2(1536, 1024)
var _vignette: ColorRect = null # the 8% edge darken, an effect (STAGE-07 half)
var _overlay: Control = null    # bars, numbers and in-fight speech over the figures
var _says: Array = []           # [{node, spr, until}]
var _bars: Array = []           # [{node, spr}]
var _numbers: Array = []        # [{node, spr}]
var _scrolls: Array = []        # ColorRects carrying the UV-scroll shader (clouds)
var _walkers: Array = []        # [{spr, shadow, path, s, dir, v, loop}] — figures on a scene's `paths` (TOWN-27)
var _rotors: Array = []         # [{node, rad_per_s}] — the windmill sails (STAGE-14)
var _flyers: Array = []         # [{spr, path, s, dir, v, loop}] — the gulls on their spline (STAGE-14)
var _effects_off := false       # docs/13 §13 reduced effects, already applied: VFX are dropped
var _fx: Array = []             # [{node, until}] — strips and bursts, freed by the clock
var _fx_serial := 0
var _acts: Array = []           # [{spr, base, rot0, mod0, segs, t, off, persist, done, mark}]
var _flashes: Array = []        # [{spr, until, restore}] — the hit flash (docs/12 §5.2)
var _mood := ""                 # a bubble with a 4th entry shows only under this mood (a wipe's skull)
var _keep_out: Array = []       # Rect2s / Controls every speech plate stays clear of (UI-20, UI-04)
var _party_feet: Dictionary = {} # {sprite: feet y} for the cast place_party put on the floor (UI-21's ranks)
var _party_front_y := -INF      # the front rank's feet row: the largest feet y among them
var _bubble_moods: Array = []   # aligned with _bubbles: "" = ambient, else the mood it needs
## Every random choice the stage makes — which bubbles are up, when they
## shuffle, when the line changes, the flicker/pulse/bob phases — is drawn from
## this generator, seeded by the scene's name in `_build`. Two runs of one scene
## therefore match frame for frame, which is what a `--frames=A,B` diff and a
## reduced-motion shot both need (W1-ICONS saw the camp's "..." set differ
## between two held runs: the global RNG picked it).
var _rng := RandomNumberGenerator.new()

## THE STRONG CACHE (W5-MOUNT). Godot's resource cache is WEAK: a plate or a
## strip is dropped the moment its last owner is freed, and a screen owns its
## own textures, so every page turn reloaded the 1536x1024 plate, every actor
## strip and every VFX sheet from disk — tools/perf_probe.gd measured ~80 ms of
## RaidView's mount as exactly that. These three dictionaries hold a strong
## reference for the life of the process: a texture by its path, a SpriteFrames
## by strip path + cut (the AtlasTextures over a strip are the same for every
## figure drawn from it; the per-sprite state — frame, phase, speed_scale,
## flip, tint — lives on the AnimatedSprite2D, never here), and a manifest by
## its path (actors.json was parsed once PER ACTOR). The whole art set is a few
## tens of MB and never freed — a guild's screens are revisited all night, and
## a cache that forgets is the bug this closes. `profile` counts hits and
## misses so a test can prove the second load read nothing, and the probe's
## `--split` can print what a mount spent here.
##
## A SpriteFrames handed out of `_frames_cache` is SHARED: nothing may add an
## animation to it. `_add_walk_animation` copies before it extends.
static var _tex_cache: Dictionary = {}      # res:// path -> Texture2D
static var _frames_cache: Dictionary = {}   # cut key -> SpriteFrames
static var _json_cache: Dictionary = {}     # res:// path -> Dictionary (read-only by contract)
## One compiled Shader per source string, and one noise texture for every
## water quad: `Shader.new()` + `code` costs ~6 ms of parse and compile per
## OBJECT (measured by the --split laps — the cave's two shimmers, three
## pulses and vignette were 39 ms of a 47 ms stage build with every texture
## already cached). A Shader is immutable once its code is set and a
## ShaderMaterial carries the per-quad uniforms, so sharing it draws the same
## pixels; the noise is FastNoiseLite at seed 0, identical for every quad.
static var _shader_cache: Dictionary = {}   # source -> Shader
static var _noise_tex: NoiseTexture2D = null
static var profile: Dictionary = {"tex_hits": 0, "tex_misses": 0, "frames_hits": 0,
	"frames_misses": 0, "json_hits": 0, "json_misses": 0, "build_usec": 0, "builds": 0}


## A texture through the strong cache: loaded once per path, then the same
## object every time. null (no error) for a path that does not exist, so the
## callers' `ResourceLoader.exists()` guards keep their meaning.
static func texture(path: String) -> Texture2D:
	var hit = _tex_cache.get(path, null)
	if hit != null:
		profile["tex_hits"] = int(profile["tex_hits"]) + 1
		return hit
	profile["tex_misses"] = int(profile["tex_misses"]) + 1
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var tex := ResourceLoader.load(path) as Texture2D
	if tex != null:
		_tex_cache[path] = tex
	return tex


## The Shader for a source string, compiled once (see `_shader_cache`).
static func _shader(code: String) -> Shader:
	var hit = _shader_cache.get(code, null)
	if hit != null:
		return hit
	var shader := Shader.new()
	shader.code = code
	_shader_cache[code] = shader
	return shader


## Zero the counters (never the caches): the probe does this before each
## page turn and the test before each load it counts.
static func profile_reset() -> void:
	for k in profile.keys():
		profile[k] = 0


## `_build`'s stopwatch: adds the time since `t0` to profile[key] and returns
## now, so each section of a build is a line in the probe's --split output.
static func _lap(t0: int, key: String) -> int:
	var now := Time.get_ticks_usec()
	profile[key] = int(profile.get(key, 0)) + int(now - t0)
	return now


## The scenes a screen stands on today (BUILD_STATE's plate table; the dungeon
## is authored and loaded by no screen). `warm()`'s default list.
const WARM_SCENES := ["stage_camp", "stage_town", "stage_tavern", "stage_market", "stage_arena_cave"]


## Fill the texture cache for the named scenes now — each plate and every strip
## its props, actors, walkers, rotors, clouds and flyers name, plus the light
## and ember sprites — so a screen's first visit draws from the cache the way
## its second one does. A plate is ~37 ms of a first visit (measured, boosting);
## Boot pays it once behind its overlay (handoff-W5-MOUNT.md) and the probe's
## --warm does the same. Returns the number of textures loaded fresh.
static func warm(names: Array = WARM_SCENES) -> int:
	var before := _tex_cache.size()
	texture(LIGHT_TEX)
	texture(EMBER_TEX)
	for n in names:
		var d := _read(SCENES + String(n) + ".json")
		texture(String(d.get("plate", "")))
		for p in _as_list(d.get("props", [])):
			if p is Dictionary:
				texture(String(p.get("strip", "")))
		for a in _as_list(d.get("actors", [])):
			if a is Dictionary:
				texture(ACTORS + String(a.get("who", "")) + ".png")
		for w in _as_list(d.get("paths", [])):
			if w is Dictionary:
				texture(ACTORS + String(w.get("who", "")) + ".png")
				texture(ACTORS + String(w.get("who", "")) + "_walk.png")
		for r in _as_list(d.get("rotor", [])):
			if r is Dictionary:
				texture(String(r.get("tex", "")))
		for sc in _as_list(d.get("scroll", [])):
			if sc is Dictionary:
				texture(String(sc.get("tex", "")))
		for fl in _as_list(d.get("flyers", [])):
			if fl is Dictionary:
				texture(String(fl.get("strip", "")))
	return _tex_cache.size() - before


## What the cache holds, for a test or a probe: {textures, frames, manifests}.
static func cache_sizes() -> Dictionary:
	return {"textures": _tex_cache.size(), "frames": _frames_cache.size(), "manifests": _json_cache.size(),
		"shaders": _shader_cache.size()}


## Build a stage from game/assets/scenes/<name>.json. Missing or malformed data
## degrades to the bare plate rather than an error: a scene that fails to
## animate is a worse screen, not a broken one.
static func load(name: String) -> Control:
	var stage: Control = from_data(name, _read(SCENES + name + ".json"))
	# The ambience door (W7-AUD-AMB, Q-98 (ii), BL-138): the bed follows the
	# scene through this one call, and no screen learns about audio. Null-safe
	# for a tool that runs without the autoload; `play_bed` is headless-safe.
	var audio: Node = Services.find(stage, "Audio")
	if audio != null:
		audio.play_bed(name)
	return stage


## The same build, from data rather than from a file. This is the seam the unit
## tests use: a test scene with three actors in it has no business shipping in
## game/assets/scenes/, and a layer nobody can build in a test is a layer
## nobody checks.
static func from_data(name: String, data: Dictionary) -> Control:
	var t0 := Time.get_ticks_usec()
	var stage: Control = new()
	stage.scene_name = name
	stage.name = "SceneStage_" + name
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage._build(data)
	profile["build_usec"] = int(profile["build_usec"]) + int(Time.get_ticks_usec() - t0)
	profile["builds"] = int(profile["builds"]) + 1
	return stage


## The fight's blocking for a scene — the `marks` dictionary of its JSON, or {}
## for a scene that has none (every non-arena scene). Static so a screen can
## read it before the stage exists and a test can read it without a screen.
static func marks(name: String) -> Dictionary:
	var m = _read(SCENES + name + ".json").get("marks", null)
	return m if m is Dictionary else {}


## Parsed once per path and held (`_json_cache`); every caller reads and
## none writes — the scene dictionaries reach `_build` by reference, and a
## caller that needs to change one duplicates it first (add_walker does).
static func _read(path: String) -> Dictionary:
	var cached = _json_cache.get(path, null)
	if cached != null:
		profile["json_hits"] = int(profile["json_hits"]) + 1
		return cached
	profile["json_misses"] = int(profile["json_misses"]) + 1
	if not FileAccess.file_exists(path):
		push_warning("SceneStage: no scene data at %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	var data: Dictionary = parsed if parsed is Dictionary else {}
	_json_cache[path] = data
	return data


## A horizontal strip -> SpriteFrames, one animation (looping unless a one-shot
## effect asks otherwise). Shared by the props, the actors and the VFX, because
## a hearth's burn, a figure's idle and a slash are the same thing: frames left
## to right, cut every `frame_w` pixels.
##
## With `tags` ({name: [first, last[, fps]]}, enemies.json's shape) the strip
## is one sheet carrying several animations: each tag becomes one, over its
## frame range, at its own rate (or `fps`); only `idle` loops — a hit returns
## to idle by itself and a death holds its last frame (docs/12 §5.2).
static func _strip_frames(tex: Texture2D, frame_w: int, fps: float, anim: String,
		loop: bool = true, tags: Dictionary = {}) -> SpriteFrames:
	# The cut of a strip that came through the strong cache is itself cached
	# (keyed by the strip's path and every argument that shapes the cut); a
	# texture with no path — one built in a test — is cut fresh every time.
	var key := ""
	if not tex.resource_path.is_empty():
		key = "%s|%d|%s|%s|%s|%s" % [tex.resource_path, frame_w, fps, anim, loop, JSON.stringify(tags)]
		var hit = _frames_cache.get(key, null)
		if hit != null:
			profile["frames_hits"] = int(profile["frames_hits"]) + 1
			return hit
		profile["frames_misses"] = int(profile["frames_misses"]) + 1
	var frames := _cut_strip(tex, frame_w, fps, anim, loop, tags)
	if not key.is_empty():
		_frames_cache[key] = frames
	return frames


## The cut itself, uncached (see `_strip_frames`).
static func _cut_strip(tex: Texture2D, frame_w: int, fps: float, anim: String,
		loop: bool, tags: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var fw := maxi(1, frame_w)
	var n := maxi(1, int(tex.get_width() / fw))
	var cut: Array = []
	for i in n:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, tex.get_height())
		cut.append(at)
	if tags.is_empty():
		frames.add_animation(anim)
		frames.set_animation_loop(anim, loop)
		frames.set_animation_speed(anim, fps)
		for at in cut:
			frames.add_frame(anim, at)
		return frames
	for key in tags:
		var span = tags[key]
		if not (span is Array) or span.size() < 2:
			continue
		var tag := String(key)
		var first := clampi(int(span[0]), 0, n - 1)
		var last := clampi(int(span[1]), first, n - 1)
		frames.add_animation(tag)
		frames.set_animation_loop(tag, tag == "idle")
		frames.set_animation_speed(tag, float(span[2]) if span.size() > 2 else fps)
		for i in range(first, last + 1):
			frames.add_frame(tag, cut[i])
	return frames


## The actor strip that stands for a canon class key ("warrior", "monk", …), or
## "" when the class has no figure assigned.
##
## A screen showing a NAMED party — the twelve on an arena floor, a candidate in
## the tavern — has to turn a class into a sprite, and there is exactly one right
## place for that decision. Reading it from data rather than hard-coding a match
## statement is what lets `docs/15` BL-68 be revisited by editing a JSON file.
static func actor_for_class(class_key: String) -> String:
	var classes := _read(CLASS_ACTORS).get("classes", {}) as Dictionary
	var row = classes.get(class_key, null)
	if not (row is Dictionary):
		return ""
	return String(row.get("actor", ""))


## The actor list a scene or a screen hands over, back to front.
static func _sorted_actors(raw) -> Array:
	var placed: Array = []
	if raw is Array:
		for a in raw:
			if a is Dictionary:
				placed.append(a)
	placed.sort_custom(func(x, y): return _actor_y(x) < _actor_y(y))
	return placed


## The scene's figure scale — what an actor without its own `scale` is drawn at.
func figure_scale() -> float:
	return _figure_scale


## Put a canvas item on the stage's light layer (UI-26): the plate, the props,
## the figures and their shadows, the boss, the effects — everything the
## lanterns are meant to light. Overlays (bars, numbers, speech) and every
## Control outside the stage stay on layer 1, which no stage light reaches.
static func _lit(item: CanvasItem) -> void:
	if item != null:
		item.light_mask = LIGHT_LAYER


## Build ONE figure and add it to the stage. Public because a screen has actors
## a scene file cannot know about — RaidView's twelve are the party that
## actually departed — and they must be built the same way as the scene's own,
## or the party would be the one crowd in the game with no contact shadow, no
## phase spread and no reduced-motion switch.
##
## Returns the sprite, or null when the figure is not in the manifest.
func add_actor(a: Dictionary) -> AnimatedSprite2D:
	var manifest := _read(ACTOR_MANIFEST).get("actors", {}) as Dictionary
	var who := String(a.get("who", ""))
	var geom = manifest.get(who, null)
	if not (geom is Dictionary):
		push_warning("SceneStage: scene '%s' wants actor '%s', which is not in %s"
			% [scene_name, who, ACTOR_MANIFEST])
		return null
	var strip_path := ACTORS + who + ".png"
	if not ResourceLoader.exists(strip_path):
		push_warning("SceneStage: no strip at %s" % strip_path)
		return null
	var nth := _actors.size()
	var tex: Texture2D = texture(strip_path)
	var fw := int(geom.get("frame_w", tex.get_height()))
	var fps := float(a.get("fps", geom.get("fps", 5.0)))
	var frames := _strip_frames(tex, fw, fps, "idle")
	var n := frames.get_frame_count("idle")
	var spr := AnimatedSprite2D.new()
	spr.name = "Actor_%s_%d" % [who, nth]
	spr.sprite_frames = frames
	spr.animation = "idle"
	# A crowd that breathes in lockstep reads as one object with many heads.
	# The phase is the author's if given, and otherwise spread by position
	# in the scene — deterministic, so two runs of the same scene match.
	spr.frame = int(a.get("phase", nth)) % maxi(1, n)
	spr.speed_scale = 0.88 + 0.06 * float(nth % 5)
	var pos: Array = a.get("pos", [0, 0])
	spr.position = Vector2(float(pos[0]), float(pos[1]))
	# STAGE-02: the plates' own tents, crates and posts put a person at ~2x the
	# 31-48px strips on the camp and the arenas, so the SCENE says what a figure
	# is drawn at and an actor only overrides it (docs/12 §3.3: integer scale).
	var sc := float(a.get("scale", _figure_scale))
	spr.scale = Vector2(sc, sc)
	spr.flip_h = bool(a.get("flip", false))
	# A figure with no contact shadow floats: the plates are night scenes
	# with hard shadows painted under everything else, so a sprite with none
	# reads as a sticker. The same soft radial the lights use, squashed into
	# an ellipse under the feet and tinted down — it is added BEFORE the
	# figure so it sits under it, and it is the figure's own width so a wide
	# pose gets a wide shadow.
	if bool(a.get("shadow", true)) and ResourceLoader.exists(LIGHT_TEX):
		var shadow := Sprite2D.new()
		shadow.name = "Shadow_%s_%d" % [who, nth]
		shadow.texture = texture(LIGHT_TEX)
		var soft_w := float(shadow.texture.get_width())
		shadow.scale = Vector2(fw * sc * 1.15 / soft_w, fw * sc * 0.42 / soft_w)
		shadow.position = spr.position + Vector2(0, -2)
		shadow.modulate = Color(0.02, 0.02, 0.05, float(a.get("shadow_alpha", 0.42)))
		_lit(shadow)
		add_child(shadow)
	# `pos` is where the figure STANDS: the strip is bottom-aligned by the
	# generator, so lifting it half a frame puts its feet on that point.
	spr.offset = Vector2(0, -tex.get_height() / 2.0)
	if a.has("tint"):
		spr.modulate = Color(String(a.get("tint", "#FFFFFF")))
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lit(spr)
	add_child(spr)
	_actors.append(spr)
	_lift_layers()
	# A stage that has already been told to hold still must hold a figure added
	# later still too: `_ready` fires when the stage enters the tree, which is
	# BEFORE a screen gets the chance to place its own party.
	if _motion_held:
		spr.stop()
		spr.frame = 0
	else:
		spr.play("idle")
	return spr


## How a figure on the floor should look for a combat state word out of the log
## ("", "downed", "dead"). One place, because the rule is a DESIGN rule rather
## than a screen's detail: 10 §2 R4 greys a fallen combatant's panel and keeps it
## in its slot, so the figure greys and keeps its ground too — and stops
## breathing, because a body that is still breathing is the wrong kind of funny.
static func party_state_style(state: String) -> Dictionary:
	match state.to_lower():
		"dead":
			return {"tint": Color(0.45, 0.45, 0.5), "still": true, "rewind": true}
		"downed":
			return {"tint": Color(0.7, 0.7, 0.75), "still": true, "rewind": false}
		_:
			return {"tint": Color.WHITE, "still": false, "rewind": false}


## spec 09 §4.3 row 4: the enemy. The screen hands over the rank's STILL (the
## sliced boss sheet's slice, game/assets/enemies/boss_<rank>.png — what the
## boss plate's sigil and the board's card show too); when enemies.json names
## a strip for that rank (STAGE-08: gen_boss_anims.lua derives idle / hit /
## death from the slice) the creature is an AnimatedSprite2D cut from it with
## those tags, breathing on `idle`, with its emissive eye layer as a child over-
## driven past 1.0 so the glow catches it. A still with no strip (a texture
## from nowhere, a rank the table does not know) keeps the slow vertical bob —
## enough to stop a creature with a mouth that size reading as a statue.
##
## Same contact shadow as a figure, and the same bottom anchor: `pos` is where
## it STANDS — the strip's frames keep the still's bottom-centre at their own,
## so the feet do not move between a still and its strip. `opts.scale` is the
## mark's boss scale (1 until docs/15 Q02 rules on boss mass; no integer
## upscale here); the offset is in texture pixels, so the feet stay on `pos` at
## any scale. Returns the node (a Sprite2D or an AnimatedSprite2D, both Node2D)
## so the screen can grey it when the thing dies; a child named `BossGlow`
## carries the eyes, a sibling named `BossShadow` the shadow.
func place_boss(tex: Texture2D, pos: Vector2, opts: Dictionary = {}) -> Node2D:
	if tex == null:
		return null
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var sc := float(opts.get("scale", 1.0))
	if bool(opts.get("shadow", true)) and ResourceLoader.exists(LIGHT_TEX):
		var shadow := Sprite2D.new()
		shadow.name = "BossShadow"
		shadow.texture = texture(LIGHT_TEX)
		var soft_w := float(shadow.texture.get_width())
		shadow.scale = Vector2(w * sc * 0.95 / soft_w, w * sc * 0.34 / soft_w)
		shadow.position = pos + Vector2(0, -3)
		shadow.modulate = Color(0.02, 0.02, 0.05, float(opts.get("shadow_alpha", 0.5)))
		_lit(shadow)
		add_child(shadow)
	var row := _boss_row(tex)
	var tags = row.get("tags", {})
	var strip_path := ENEMIES + String(row.get("strip", ""))
	var animated := row.has("strip") and tags is Dictionary and not (tags as Dictionary).is_empty()
	if animated and ResourceLoader.exists(strip_path):
		return _place_boss_strip(row, texture(strip_path), pos, sc, opts)
	var spr := Sprite2D.new()
	spr.name = "Boss"
	spr.texture = tex
	spr.position = pos
	spr.offset = Vector2(0, -h / 2.0)
	spr.scale = Vector2(sc, sc)
	spr.flip_h = bool(opts.get("flip", false))
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lit(spr)
	add_child(spr)
	_lift_layers()
	# The bob is in PIXELS and deliberately small: 3px over ~4 seconds reads as
	# breathing, and anything larger reads as floating, which a thing standing
	# on stone must not do.
	_bobbers.append({"node": spr, "base_y": pos.y, "amp": float(opts.get("bob", 3.0)),
		"speed": float(opts.get("bob_speed", 1.6)), "phase": _rng.randf() * 6.28})
	if not _motion_held:
		set_process(true)
	return spr


## enemies.json's row for the rank a still stands for — the still's file name
## IS the rank (`boss_main.png` -> `boss_main`) — or {} for a texture that is
## not one of the ranks (an ImageTexture built in a test, a stranger's PNG).
static func _boss_row(tex: Texture2D) -> Dictionary:
	var path := tex.resource_path
	if path.is_empty() or not path.begins_with(ENEMIES):
		return {}
	var row = _read(ENEMIES_TABLE).get("ranks", {}).get(path.get_file().get_basename(), null)
	return row if row is Dictionary else {}


## The strip boss: one AnimatedSprite2D with the table's tags, its eye layer a
## child that mirrors its animation and frame (never plays on its own, so the
## two can never drift), drawn NEAREST like every figure.
func _place_boss_strip(row: Dictionary, strip: Texture2D, pos: Vector2, sc: float,
		opts: Dictionary) -> AnimatedSprite2D:
	var fw := int(row.get("frame_w", strip.get_height()))
	var fps := float(row.get("fps", 5.0))
	var tags: Dictionary = row["tags"]
	var frames := _strip_frames(strip, fw, fps, "idle", true, tags)
	var first := "idle" if frames.has_animation("idle") else String(frames.get_animation_names()[0])
	var spr := AnimatedSprite2D.new()
	spr.name = "Boss"
	spr.sprite_frames = frames
	spr.animation = first
	spr.position = pos
	spr.offset = Vector2(0, -strip.get_height() / 2.0)
	spr.scale = Vector2(sc, sc)
	spr.flip_h = bool(opts.get("flip", false))
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var glow: AnimatedSprite2D = null
	var glow_path := ENEMIES + String(row.get("glow", ""))
	if row.has("glow") and ResourceLoader.exists(glow_path):
		glow = AnimatedSprite2D.new()
		glow.name = "BossGlow"
		glow.sprite_frames = _strip_frames(texture(glow_path), fw, fps, "idle", true, tags)
		glow.animation = first
		glow.offset = spr.offset
		# flip_h does not reach a child sprite: the eyes flip with the face.
		glow.flip_h = spr.flip_h
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Over-driven past 1.0 so the 2D glow catches the eyes (11 §6's 1.3
		# threshold). With the glow off (reduced effects) the over-drive would
		# clip flat (CRITIC-G17), so the layer draws at 1.0 — the eyes stay, unlit.
		var g := float(_read(ENEMIES_TABLE).get("glow_modulate", BOSS_GLOW_MODULATE))
		glow.modulate = Color(1, 1, 1, 1) if _effects_off else Color(g, g, g, 1.0)
		_lit(glow)
		spr.add_child(glow)
	_lit(spr)
	add_child(spr)
	_lift_layers()
	_bosses.append({"spr": spr, "glow": glow, "tags": tags})
	spr.frame_changed.connect(_mirror_boss_glow.bind(spr))
	spr.animation_finished.connect(_on_boss_anim_finished.bind(spr))
	if _motion_held:
		spr.stop()
		spr.frame = 0
	else:
		spr.play(first)
	_mirror_boss_glow(spr)
	return spr


func _boss_entry(spr: Node2D) -> Dictionary:
	for b in _bosses:
		if b["spr"] == spr:
			return b
	return {}


## Whether a placed boss carries a strip tag of that name (`"idle"`, `"hit"`,
## `"death"`): the screen's way to know a verb will be performed by frames.
func boss_has_tag(spr: Node2D, tag: String) -> bool:
	var b := _boss_entry(spr)
	if b.is_empty() or not (b["tags"] as Dictionary).has(tag):
		return false
	return (spr as AnimatedSprite2D).sprite_frames.has_animation(tag)


## Play a strip boss's tag: `hit` runs once and returns to idle by itself
## (`_on_boss_anim_finished`), `death` runs once and holds its last frame.
## Under reduced motion a death ARRIVES (the last frame, at once — a fallen
## body is a destination) and anything else is refused, so the caller falls
## back to the flash-only path. Returns false for a boss without that tag.
func _boss_play(spr: Node2D, tag: String) -> bool:
	if not boss_has_tag(spr, tag):
		return false
	var a := spr as AnimatedSprite2D
	if _motion_held:
		if tag != "death":
			return false
		a.stop()
		a.animation = tag
		a.frame = a.sprite_frames.get_frame_count(tag) - 1
	else:
		a.play(tag)
	_mirror_boss_glow(spr)
	return true


func _on_boss_anim_finished(spr: Node2D) -> void:
	var a := spr as AnimatedSprite2D
	if not is_instance_valid(a) or String(a.animation) == "death" or _motion_held:
		return
	if a.sprite_frames != null and a.sprite_frames.has_animation("idle"):
		a.play("idle")
		_mirror_boss_glow(spr)


## The eye layer shows the body's animation and frame, always.
func _mirror_boss_glow(spr: Node2D) -> void:
	var b := _boss_entry(spr)
	if b.is_empty():
		return
	var glow = b["glow"]
	var a := spr as AnimatedSprite2D
	if glow is AnimatedSprite2D and is_instance_valid(glow) and is_instance_valid(a):
		if glow.sprite_frames.has_animation(a.animation):
			glow.animation = a.animation
			glow.frame = mini(a.frame, glow.sprite_frames.get_frame_count(a.animation) - 1)


## Take a figure `add_actor` built off the stage: the sprite, the contact
## shadow `add_actor` put directly before it, and its place in `_actors`, so
## a later `apply_settings` never meets a freed object. A screen that
## re-places a party (RaidPrep on every chalk) uses this rather than freeing
## the nodes itself. Safe on a sprite that is already gone.
func remove_actor(spr: Node) -> void:
	if spr == null or not is_instance_valid(spr):
		return
	_actors.erase(spr)
	var i: int = spr.get_index()
	if spr.get_parent() == self and i > 0:
		var shadow: Node = get_child(i - 1)
		if String(shadow.name).begins_with("Shadow_"):
			remove_child(shadow)
			shadow.queue_free()
	if spr.get_parent() == self:
		remove_child(spr)
	spr.queue_free()


## Whether docs/13 §13's reduced-motion switch has already been applied. A
## screen that resumes a figure's animation itself has to ask, or it would undo
## the setting for exactly the figures it added.
func motion_held() -> bool:
	return _motion_held


## Place a screen's own cast — [{who, pos, id, …}] — back to front, and return
## {id: sprite} for whatever the screen has to update later. An entry with no
## `scale` is drawn at the scene's `figure_scale`, like any of its own actors.
func place_party(actors: Array) -> Dictionary:
	var out := {}
	for a in _sorted_actors(actors):
		var spr := add_actor(a)
		if spr != null and a.has("id"):
			out[String(a["id"])] = spr
		if spr != null:
			# The cast's ranks (UI-21 / BL-137): the front rank is the row
			# whose feet stand lowest on the plate; `bar_for` hides the
			# overhead stack behind it unless the figure is acting or struck.
			_party_feet[spr] = _actor_y(a)
			_party_front_y = maxf(_party_front_y, _actor_y(a))
	return out


## Whether a figure `place_party` put on the floor stands behind the front
## rank (its feet a row above the lowest row). A figure the screen placed
## alone, or one on the front row, is never "behind".
func in_back_rank(spr: Node2D) -> bool:
	if spr == null or not _party_feet.has(spr):
		return false
	return float(_party_feet[spr]) < _party_front_y - 1.0


## An actor's floor line, which is what depth sorts on.
static func _actor_y(a: Dictionary) -> float:
	var pos = a.get("pos", [0, 0])
	if pos is Array and pos.size() > 1:
		return float(pos[1])
	return 0.0


# ---------------------------------------------------------------- paths (W4-LIFE)

## A `points` list ([[x, y], …]) as Vector2s; anything malformed is dropped.
static func _points_of(raw) -> Array:
	var out: Array = []
	if raw is Array:
		for p in raw:
			if p is Array and p.size() >= 2:
				out.append(Vector2(float(p[0]), float(p[1])))
	return out


## A polyline's arc-length table: {"pts", "cum" (the length up to each
## point), "total"}. A traveller is a distance `s` along it, nothing else.
static func _path_of(pts: Array) -> Dictionary:
	var cum: Array = [0.0]
	for i in range(1, pts.size()):
		cum.append(float(cum[i - 1]) + (pts[i] as Vector2).distance_to(pts[i - 1]))
	return {"pts": pts, "cum": cum, "total": float(cum.back()) if pts.size() > 1 else 0.0}


## The point `s` pixels along a path, and the unit direction of the segment
## it is on: {"pos", "dir"}.
static func _along(path: Dictionary, s: float) -> Dictionary:
	var pts: Array = path["pts"]
	var cum: Array = path["cum"]
	if pts.is_empty():
		return {"pos": Vector2.ZERO, "dir": Vector2.RIGHT}
	if pts.size() == 1:
		return {"pos": pts[0], "dir": Vector2.RIGHT}
	s = clampf(s, 0.0, float(path["total"]))
	var i := 0
	while i < pts.size() - 2 and s > float(cum[i + 1]):
		i += 1
	var a: Vector2 = pts[i]
	var b: Vector2 = pts[i + 1]
	var seg := float(cum[i + 1]) - float(cum[i])
	var t := (s - float(cum[i])) / seg if seg > 0.0 else 0.0
	var d := (b - a).normalized() if seg > 0.0 else Vector2.RIGHT
	return {"pos": a.lerp(b, clampf(t, 0.0, 1.0)), "dir": d}


## Advance a traveller `dt` seconds at its `v`: a `loop` path wraps, any
## other turns back at each end (ping-pong). Writes `s` and `dir` (±1).
static func _advance(e: Dictionary, dt: float) -> void:
	var total := float(e["path"]["total"])
	if total <= 0.0:
		return
	var s := float(e["s"]) + float(e["v"]) * dt * float(e["dir"])
	if bool(e["loop"]):
		s = fposmod(s, total)
	else:
		var guard := 0
		while (s > total or s < 0.0) and guard < 8:
			guard += 1
			if s > total:
				s = 2.0 * total - s
				e["dir"] = -1.0
			if s < 0.0:
				s = -s
				e["dir"] = 1.0
	e["s"] = s


## A Catmull-Rom spline through `pts` (closed when `loop`), sampled `per`
## points a segment into the polyline the walkers already use: a gull banks
## round a corner instead of turning on it. Fewer than three points is a line.
static func _spline(pts: Array, loop: bool, per: int = 12) -> Array:
	var n := pts.size()
	if n < 3:
		return pts.duplicate()
	var out: Array = []
	var segs := n if loop else n - 1
	for i in segs:
		var p0: Vector2 = pts[(i - 1 + n) % n] if loop else pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n] if loop else pts[mini(i + 2, n - 1)]
		for k in per:
			var t := float(k) / float(per)
			var q: Vector2 = 2.0 * p1
			q += (p2 - p0) * t
			q += (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * (t * t)
			q += (3.0 * p1 - p0 - 3.0 * p2 + p3) * (t * t * t)
			out.append(q * 0.5)
	out.append(pts[0] if loop else pts[n - 1])
	return out


## TOWN-27's `paths`: a figure that WALKS — between `points` at `px_per_s`,
## turning back at each end (or round again with `loop`), starting `phase`
## (0..1) of the way along, facing the way it goes. Built through `add_actor`
## (the same manifest, shadow and scale as a standing figure), then given the
## strip gen_actors.py derived as its walk (`<who>_walk`, a second manifest
## row) as a "walk" animation; a figure with no walk row walks on its idle.
## Its depth follows its feet every tick (`_settle_depth`): passing in front
## of a standing figure it is drawn in front, behind it behind — the
## back-to-front rule, kept while things move. Reduced motion holds it like
## the crowd (frame 0 of the walk is the pose; the feet stay where the switch
## found them); reduced effects leaves it walking. Returns the sprite, or
## null for a figure the manifest lacks or a path with fewer than two points.
func add_walker(entry: Dictionary) -> AnimatedSprite2D:
	var pts := _points_of(entry.get("points", []))
	if pts.size() < 2:
		push_warning("SceneStage: scene '%s' path for '%s' needs two points"
			% [scene_name, entry.get("who", "")])
		return null
	var path := _path_of(pts)
	var e := {"path": path, "s": clampf(float(entry.get("phase", 0.0)), 0.0, 1.0) * float(path["total"]),
		"dir": 1.0, "v": maxf(0.0, float(entry.get("px_per_s", 18.0))), "loop": bool(entry.get("loop", false))}
	var at := _along(path, float(e["s"]))
	var a := entry.duplicate()
	a["pos"] = [(at["pos"] as Vector2).x, (at["pos"] as Vector2).y]
	a.erase("flip")
	a.erase("phase")   # a path phase, not a frame
	var spr := add_actor(a)
	if spr == null:
		return null
	var nth := _walkers.size()
	var who := String(entry.get("who", ""))
	var shadow: Node = get_child(spr.get_index() - 1) if spr.get_index() > 0 else null
	if shadow != null and String(shadow.name).begins_with("Shadow_"):
		shadow.name = "Shadow_%s_walk%d" % [who, nth]
	else:
		shadow = null
	spr.name = "Walker_%s_%d" % [who, nth]
	_add_walk_animation(spr, who, entry)
	e["spr"] = spr
	e["shadow"] = shadow
	_walkers.append(e)
	_face_walker(e, at["dir"])
	if not _motion_held:
		var anim := "walk" if spr.sprite_frames.has_animation("walk") else "idle"
		spr.play(anim)
		# `play` rewinds; two walkers stepping in time read as one — spread them.
		spr.frame = nth % maxi(1, spr.sprite_frames.get_frame_count(anim))
	_settle_depth(spr, shadow)
	set_process(true)
	return spr


## The "walk" animation from the figure's `<who>_walk` strip, when the
## manifest has one (gen_actors.py writes them for its `WALKERS`).
func _add_walk_animation(spr: AnimatedSprite2D, who: String, entry: Dictionary) -> void:
	var manifest := _read(ACTOR_MANIFEST).get("actors", {}) as Dictionary
	var geom = manifest.get(who + "_walk", null)
	var strip_path := ACTORS + who + "_walk.png"
	if not (geom is Dictionary) or not ResourceLoader.exists(strip_path):
		return
	var tex: Texture2D = texture(strip_path)
	var fw := int(geom.get("frame_w", tex.get_height()))
	var fps := float(entry.get("fps", geom.get("fps", 6.0)))
	var walk := _strip_frames(tex, fw, fps, "walk")
	# The idle frames are the strong cache's, shared by every figure cut from
	# the strip: this walker gets its own copy to carry the walk (the textures
	# inside are still the shared ones).
	var frames: SpriteFrames = _copy_frames(spr.sprite_frames)
	spr.sprite_frames = frames
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", fps)
	for i in walk.get_frame_count("walk"):
		frames.add_frame("walk", walk.get_frame_texture("walk", i))


## A private SpriteFrames with the same animations, loops, rates and frame
## textures as `src` — what a sprite needs before it may extend a cached set.
static func _copy_frames(src: SpriteFrames) -> SpriteFrames:
	var out := SpriteFrames.new()
	out.remove_animation("default")
	for a in src.get_animation_names():
		var an := String(a)
		out.add_animation(an)
		out.set_animation_loop(an, src.get_animation_loop(an))
		out.set_animation_speed(an, src.get_animation_speed(an))
		for i in src.get_frame_count(an):
			out.add_frame(an, src.get_frame_texture(an, i), src.get_frame_duration(an, i))
	return out


## The strips face right; a walker heading left is flipped. `d` is the
## direction of travel (the segment's, times the ping-pong sign).
static func _face_walker(e: Dictionary, d: Vector2) -> void:
	var spr: AnimatedSprite2D = e["spr"]
	if absf(d.x) > 0.01:
		spr.flip_h = d.x < 0.0


## Move a child so it lands at slot `w` of the CURRENT list (before the node
## at `w`, or last when `w` is the count). `move_child`'s index is the slot
## in the list without the moved node, which is one less when the node is
## already before it.
func _move_to(node: Node, w: int) -> void:
	if node.get_index() < w:
		w -= 1
	w = clampi(w, 0, get_child_count() - 1)
	if node.get_index() != w:
		move_child(node, w)


## Keep a moving figure in the crowd's back-to-front order: among the
## standing figures in tree order it belongs before the first whose feet are
## lower than its own, after the last otherwise (after the props when there
## is nobody); its shadow rides just before it.
func _settle_depth(spr: Node2D, shadow: Node) -> void:
	var want := -1
	var after := -1
	for c in get_children():
		if c == spr or c == shadow or not (c in _actors):
			continue
		if (c as Node2D).position.y > spr.position.y:
			var i := c.get_index()
			var prev := get_child(i - 1) if i > 0 else null
			if prev != null and String(prev.name).begins_with("Shadow_"):
				i -= 1
			want = i
			break
		after = c.get_index() + 1
	if want < 0:
		if after >= 0:
			want = after
		elif not _props.is_empty():
			want = (_props.back() as Node).get_index() + 1
		else:
			want = _env.get_index() + 1 if _env != null else get_child_count()
	if shadow != null and is_instance_valid(shadow):
		_move_to(shadow, want)
		_move_to(spr, shadow.get_index() + 1)
	else:
		_move_to(spr, want)


func _tick_walkers(dt: float) -> void:
	for e in _walkers:
		var spr: AnimatedSprite2D = e["spr"]
		if not is_instance_valid(spr):
			continue
		_advance(e, dt)
		var at := _along(e["path"], float(e["s"]))
		spr.position = at["pos"]
		var shadow = e["shadow"]
		if shadow is Node2D and is_instance_valid(shadow):
			shadow.position = spr.position + Vector2(0, -2)
		_face_walker(e, (at["dir"] as Vector2) * float(e["dir"]))
		_settle_depth(spr, shadow if (shadow is Node and is_instance_valid(shadow)) else null)


## STAGE-14's `rotor`: a texture turning about its centre at `rad_per_s`
## (positive = clockwise on screen) — the windmill sails tools/art/
## patch_plate.py cut from the plate, whose axle is the canvas centre, so at
## `phase` 0 the sprite over the patched plate IS the painting. Pure motion:
## reduced motion holds the angle; reduced effects leaves it (a piece of the
## plate, not an effect — hiding it would bare the patch). Filtered like the
## plate rather than NEAREST: a painted sail turning through 360° needs the
## smooth sample or it crawls.
func add_rotor(tex: Texture2D, pos: Vector2, rad_per_s: float, opts: Dictionary = {}) -> Sprite2D:
	if tex == null:
		return null
	var spr := Sprite2D.new()
	spr.name = "Rotor_%d" % _rotors.size()
	spr.texture = tex
	spr.position = pos
	spr.rotation = float(opts.get("phase", 0.0))
	_lit(spr)
	add_child(spr)
	_rotors.append({"node": spr, "rad_per_s": rad_per_s})
	_lift_layers()
	set_process(true)
	return spr


func _tick_rotors(dt: float) -> void:
	for r in _rotors:
		var node: Sprite2D = r["node"]
		if is_instance_valid(node):
			node.rotation = fposmod(node.rotation + float(r["rad_per_s"]) * dt, TAU)


## life.json's row for a strip, or {} — the geometry lives with the PNG.
static func _life_geom(key: String) -> Dictionary:
	var row = _read(LIFE_MANIFEST).get("strips", {}).get(key, null)
	return row if row is Dictionary else {}


## STAGE-14's `flyers`: a strip (the gull) looping its frames while it rides
## a spline through `points` at `px_per_s` — closed by default (`opts.loop`
## false turns back at the ends). `opts.frame_w` / `opts.fps` fall back to
## life.json's row for the strip; `opts.phase` (0..1) is where it starts;
## `opts.scale` its size. Reduced motion holds it on frame 0 where it is;
## reduced effects leaves it flying (a bird is life, not an effect).
func add_flyer(strip: String, points: Array, px_per_s: float, opts: Dictionary = {}) -> AnimatedSprite2D:
	var pts := _points_of(points)
	if strip.is_empty() or not ResourceLoader.exists(strip) or pts.size() < 2:
		return null
	var geom := _life_geom(strip.get_file().get_basename())
	var tex: Texture2D = texture(strip)
	var fw := int(opts.get("frame_w", geom.get("frame_w", tex.get_height())))
	var fps := maxf(1.0, float(opts.get("fps", geom.get("fps", 5.0))))
	var loop := bool(opts.get("loop", true))
	var path := _path_of(_spline(pts, loop))
	var spr := AnimatedSprite2D.new()
	spr.name = "Flyer_%d" % _flyers.size()
	spr.sprite_frames = _strip_frames(tex, fw, fps, "fly")
	spr.animation = "fly"
	var n := spr.sprite_frames.get_frame_count("fly")
	spr.frame = int(opts.get("frame", _flyers.size())) % maxi(1, n)
	var sc := float(opts.get("scale", 1.0))
	spr.scale = Vector2(sc, sc)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var e := {"spr": spr, "path": path, "s": clampf(float(opts.get("phase", 0.0)), 0.0, 1.0) * float(path["total"]),
		"dir": 1.0, "v": maxf(0.0, px_per_s), "loop": loop}
	var at := _along(path, float(e["s"]))
	spr.position = at["pos"]
	if absf((at["dir"] as Vector2).x) > 0.01:
		spr.flip_h = (at["dir"] as Vector2).x < 0.0
	_lit(spr)
	add_child(spr)
	_flyers.append(e)
	_lift_layers()
	if _motion_held:
		spr.stop()
		spr.frame = 0
	else:
		spr.play("fly")
	set_process(true)
	return spr


func _tick_flyers(dt: float) -> void:
	for e in _flyers:
		var spr: AnimatedSprite2D = e["spr"]
		if not is_instance_valid(spr):
			continue
		_advance(e, dt)
		var at := _along(e["path"], float(e["s"]))
		spr.position = at["pos"]
		var d: Vector2 = (at["dir"] as Vector2) * float(e["dir"])
		if absf(d.x) > 0.01:
			spr.flip_h = d.x < 0.0


# ---------------------------------------------------------------- overlays

## The unscaled height of the frame a figure or a boss is drawn from.
static func _frame_h_of(spr: Node2D) -> float:
	if spr is AnimatedSprite2D:
		var frames: SpriteFrames = spr.sprite_frames
		var anim := String(spr.animation)
		if frames != null and frames.has_animation(anim) and frames.get_frame_count(anim) > 0:
			var tex := frames.get_frame_texture(anim, 0)
			if tex != null:
				return float(tex.get_height())
	elif spr is Sprite2D and spr.texture != null:
		return float(spr.texture.get_height())
	return 0.0


## Where a figure's head is, in stage space: its feet point lifted by one frame
## at the figure's own scale. Every overlay hangs off this one point, so the
## bars, the numbers and the in-fight bubble agree about where "above" is.
func head_of(spr: Node2D) -> Vector2:
	if spr == null or not is_instance_valid(spr):
		return Vector2.ZERO
	return spr.position - Vector2(0, _frame_h_of(spr) * spr.scale.y)


## The layer the overlays live in. Built last in `_build`, and lifted back over
## any figure a screen places afterwards (`_lift_layers`), so an overlay is
## always over the crowd and under the screen's chrome.
func _overlay_layer() -> Control:
	if _overlay == null or not is_instance_valid(_overlay):
		_overlay = Control.new()
		_overlay.name = "Overlay"
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_overlay)
	return _overlay


## Keep the vignette and the overlay the last two children: a figure or a boss
## added after `_build` would otherwise land on top of them.
func _lift_layers() -> void:
	if _vignette != null and is_instance_valid(_vignette):
		move_child(_vignette, get_child_count() - 1)
	if _overlay != null and is_instance_valid(_overlay):
		move_child(_overlay, get_child_count() - 1)


## Detach and free an overlay node without touching whoever still holds it.
## Untyped on purpose: a caller may already have freed the node, and a freed
## instance cannot be assigned to a typed parameter.
func _drop_overlay(node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var parent: Node = node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.queue_free()


## The live entries of an overlay list, minus any whose node or figure is gone
## and minus those over `except` (the figure a new overlay replaces).
static func _live(entries: Array, except: Node2D = null) -> Array:
	var keep: Array = []
	for e in entries:
		if not is_instance_valid(e["node"]) or not is_instance_valid(e["spr"]):
			continue
		if except != null and e["spr"] == except:
			continue
		keep.append(e)
	return keep


## A line of speech over a figure's head (spec 02 §5.3): the kit's plate with
## its tail's apex `TAIL_AIR` above the head (so its bottom edge is `SAY_AIR`
## above it), held for `hold_ms` (0 = until the next line replaces it). ONE
## bubble on the stage at a time: a new line retires the plate that is up,
## whoever said it — three jokes inside one hold used to stack three 196px
## plates over a 64px-pitch rank (handoff-W2-RAIDVIEW's observation), and a
## floor where everyone talks at once reads as noise, not comedy. The tail is
## the kit's own (`speech_plate`'s second argument, a point in the overlay's
## space = the stage's): it keeps pointing at the head the line was said over,
## so when a verb moves the figure a few pixels the tail flexes rather than
## drifts. Appearing and leaving are not motion, so the hold runs under
## reduced motion too — the words are information, not decoration.
##
## UI-20 / UI-35: the plate never covers a head or the screen's chrome. It is
## placed over the speaker first, then LIFTED — `CROWD_AIR` above the topmost
## head of any figure it would cover, and clear of every `keep_out` rect (stage
## space; the screen passes its header and boss plate, the camp its callouts)
## and of the rects `set_keep_out` holds — until it touches nothing; the tail
## stretches down to the speaker's head (its length is the kit's
## `speech_plate` `tail_len`). A boss speaker (a node `place_boss` made) hangs
## its plate under the boss plate's bottom-left when a keep-out rect sits
## over its head, else over its head like anyone. A 1x scene wraps the plate
## at `SAY_WRAP_1X` (UI-07).
func say_at(spr: Node2D, line: String, hold_ms: int = 2400, keep_out: Array = []) -> PanelContainer:
	if spr == null or not is_instance_valid(spr):
		return null
	for s in _says:
		_drop_overlay(s["node"])
	_says = []
	var opts := {}
	if _figure_scale <= 1.0:
		opts["wrap"] = SAY_WRAP_1X
	var plate := Widgets.speech_plate(line, head_of(spr) - Vector2(0, TAIL_AIR), opts)
	plate.name = "Say_%s" % spr.name
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Widgets.content_of(plate).mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_meta("speaker", spr.name)
	var avoid: Array = []
	for r in keep_out:
		if r is Rect2:
			avoid.append(r)
	plate.set_meta("keep_out", avoid)
	_overlay_layer().add_child(plate)
	var floor_w := 196.0 if _figure_scale > 1.0 else float(SAY_WRAP_1X + 16)
	plate.size = Vector2(floor_w, 56).max(plate.get_combined_minimum_size())
	_anchor_say(plate, spr)
	_says.append({"node": plate, "spr": spr,
		"until": (_t + float(hold_ms) / 1000.0) if hold_ms > 0 else INF})
	set_process(true)
	return plate


func _anchor_say(plate: Control, spr: Node2D) -> void:
	var avoid: Array = _keep_out_rects()
	var own = plate.get_meta("keep_out", null)
	if own is Array:
		avoid = avoid + own
	plate.position = _clear_plate(plate.size, spr, avoid)
	_stretch_tail(plate, head_of(spr).y - TAIL_AIR - (plate.position.y + plate.size.y))
	# The kit re-aims its tail on `item_rect_changed`, which a Control outside
	# a tree never emits for a position change (the kit's own tests emit it by
	# hand); in a tree this is one redundant re-aim.
	plate.item_rect_changed.emit()


## Rects (stage space) every speech plate keeps clear of, for the life of
## the stage: a screen passes the chrome that overlaps its band, the camp its
## building callouts. Entries may be `Rect2`s or `Control`s — a Control is
## read live, in the stage's parent's space (a callout settles its size one
## frame after it is built), and converted through the stage's `position`.
func set_keep_out(rects: Array) -> void:
	_keep_out = []
	for r in rects:
		if r is Rect2 or r is Control:
			_keep_out.append(r)
	_anchor_speech()
	for s in _live(_says):
		_anchor_say(s["node"], s["spr"])


func _keep_out_rects() -> Array:
	var out: Array = []
	for r in _keep_out:
		if r is Rect2:
			out.append(r)
		elif r is Control and is_instance_valid(r):
			var c := r as Control
			out.append(Rect2(c.position - position, c.size))
	return out


## A figure's head rect in stage space: the top third of its frame at its
## scale — the part a plate must not cover (a plate over a chest is a plate
## over a person; over the feet it is a plate over the floor).
func _head_rect(spr: Node2D) -> Rect2:
	var h := _frame_h_of(spr) * absf(spr.scale.y)
	var w := _frame_w_of(spr) * absf(spr.scale.x)
	var top := head_of(spr)
	return Rect2(top.x - w / 2.0, top.y, w, maxf(1.0, h / 3.0))


## The unscaled width of the frame a figure or a boss is drawn from.
static func _frame_w_of(spr: Node2D) -> float:
	if spr is AnimatedSprite2D:
		var frames: SpriteFrames = spr.sprite_frames
		var anim := String(spr.animation)
		if frames != null and frames.has_animation(anim) and frames.get_frame_count(anim) > 0:
			var tex := frames.get_frame_texture(anim, 0)
			if tex != null:
				return float(tex.get_width())
	elif spr is Sprite2D and spr.texture != null:
		return float(spr.texture.get_width())
	return 0.0


## Where a plate of `size` goes so that it covers no head but its speaker's
## own tail column and no keep-out rect (UI-20 / UI-35). Starts `SAY_AIR`
## over the speaker's head, centred; each obstacle it touches lifts its bottom
## to `CROWD_AIR` above that obstacle's top (a head) or its top edge (a keep-
## out rect), and the walk repeats until nothing is touched or the plate would
## leave the rows the screen shows — then it stops where it is, on screen. A
## keep-out rect that is only to one side is dodged sideways first (the
## camp's callouts stand beside the speaker, not over it). A boss speaker
## whose head is under a keep-out rect (the boss plate) hangs its plate at
## that rect's bottom-left instead.
func _clear_plate(size: Vector2, spr: Node2D, avoid: Array) -> Vector2:
	var head := head_of(spr)
	var want := head - Vector2(size.x / 2.0, size.y + SAY_AIR)
	var band_top := maxf(0.0, -position.y)
	if _is_boss(spr):
		for r in avoid:
			var rr: Rect2 = r
			if rr.end.y <= head.y + 1.0 and rr.position.x < head.x and rr.end.x > head.x:
				return Vector2(rr.position.x, rr.end.y + CROWD_AIR)
	var heads: Array = []
	for a in _actors:
		if a != spr and is_instance_valid(a):
			heads.append(_head_rect(a))
	for b in _bosses:
		var boss: Node2D = b["spr"]
		if boss != spr and is_instance_valid(boss):
			heads.append(_head_rect(boss))
	for _pass in 12:
		var rect := Rect2(want, size)
		var hit := false
		# The chrome first, sideways when it can: a callout beside the speaker
		# is cleared by sliding, not by climbing over it.
		for r in avoid:
			var rr: Rect2 = r
			if not rect.intersects(rr):
				continue
			hit = true
			# Three ways out of one rect — beside it either way, or above it —
			# and the shortest move that actually fits the plate on the plate
			# wins. A header pinned to the top of the band leaves only the two
			# sideways doors; a callout in the middle of the camp leaves all
			# three. When none fits, the plate drops UNDER the rect, which is
			# the header's case on a screen with no room above it.
			var left := rr.position.x - size.x - CROWD_AIR
			var right := rr.end.x + CROWD_AIR
			var up := rr.position.y - CROWD_AIR - size.y
			var best := INF
			var pick := Vector2.INF
			if left >= 0.0 and absf(want.x - left) < best:
				best = absf(want.x - left)
				pick = Vector2(left, want.y)
			if right + size.x <= _plate_size.x and absf(right - want.x) < best:
				best = absf(right - want.x)
				pick = Vector2(right, want.y)
			if up >= band_top and absf(want.y - up) < best:
				best = absf(want.y - up)
				pick = Vector2(want.x, up)
			want = pick if pick.is_finite() else Vector2(want.x, rr.end.y + CROWD_AIR)
			break
		if hit:
			continue
		var top := INF
		for hr in heads:
			var h: Rect2 = hr
			if rect.intersects(h):
				top = minf(top, h.position.y)
		if top == INF:
			break
		var lifted := top - CROWD_AIR - size.y
		if lifted < band_top:
			want.y = band_top
			break
		want.y = lifted
	want.x = clampf(want.x, 0.0, maxf(0.0, _plate_size.x - size.x))
	return want


func _is_boss(spr: Node2D) -> bool:
	if String(spr.name) == "Boss":
		return true
	return not _boss_entry(spr).is_empty()


## Tell the kit's tail how far it reaches (UI-20: a lifted plate's tail is a
## wedge down to the speaker, not a needle) — `Widgets.speech_plate`'s
## `tail_len`, written after the stage has decided the lift.
static func _stretch_tail(plate: Control, length: float) -> void:
	var tail = plate.get_node_or_null("Tail")
	if tail is Widgets.Tail:
		tail.length = maxf(0.0, length)
		tail.queue_redraw()


## A damage or heal number over a figure (spec 02 §5.4). The CALLER builds the
## Label (`Widgets.damage_number`, W1-KIT) so the stage never names a theme
## type it does not own; the stage places it centred over the head, stacked
## upward by each earlier label's own height plus `NUMBER_AIR` for every
## number already up over the same figure (UI-34: a fixed 14px stagger under
## a 35px glyph half-overlapped two "-30"s) so a raid-wide hit does not stack
## into one blob, and hands it back for the caller's rise-and-fade tween. It
## is not re-anchored afterwards — the tween owns its position from here.
func number_at(spr: Node2D, label: Label) -> Label:
	if spr == null or label == null or not is_instance_valid(spr):
		return label
	var lift := 0.0
	var keep: Array = []
	for n in _live(_numbers):
		if n["node"].get_parent() != _overlay:
			continue
		keep.append(n)
		if n["spr"] == spr:
			lift += (n["node"] as Control).size.y + NUMBER_AIR
	_numbers = keep
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_meta("speaker", spr.name)
	_overlay_layer().add_child(label)
	var sz := label.get_combined_minimum_size()
	label.size = sz
	label.position = head_of(spr) - Vector2(sz.x / 2.0, sz.y + BAR_AIR + lift)
	_numbers.append({"node": label, "spr": spr})
	return label


## spec 02 §5.1's floating status bar, 96x23 above the head: a 24x24 class badge
## (the given texture, or a bare plate — a numeral or "!" over it is the
## caller's Label, never a baked glyph, RULES-14), up to four 12x12 pips from
## `opts.pips` (Colors or Texture2Ds), and a 62x7 `Widgets.bar` when `maximum`
## is positive and `opts.bar` is not false. CRITIC-C06's default: badge + pips
## on every figure, the bar only on the acting or struck one — the screen
## decides per call. One bar per figure; a second call replaces the first.
##
## BL-137 (UI-21's extension of Q07): on a figure BEHIND the front rank the
## whole stack is built and hidden unless the call carries the bar (`opts.bar`
## true — the acting or struck figure): twelve overheads at four heights read
## as loose chips on the rock, and a back rank's badges sat between the front
## rank's heads. The box is still there, named, for whatever reads it.
func bar_for(spr: Node2D, hp: float, maximum: float, badge: Texture2D = null,
		opts: Dictionary = {}) -> Control:
	if spr == null or not is_instance_valid(spr):
		return null
	for b in _bars:
		if b["spr"] == spr:
			_drop_overlay(b["node"])
	_bars = _live(_bars, spr)
	var box := Control.new()
	box.name = "Bar_%s" % spr.name
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size = BAR_SIZE
	box.set_meta("speaker", spr.name)
	box.visible = not in_back_rank(spr) or bool(opts.get("bar", true))
	# Badge, bottom-left, overhanging the footprint by 1px the way the mockup does.
	if badge != null:
		var t := TextureRect.new()
		t.name = "Badge"
		t.texture = badge
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.position = Vector2.ZERO
		t.size = Vector2(BAR_BADGE, BAR_BADGE)
		box.add_child(t)
	else:
		var plate := ColorRect.new()
		plate.name = "Badge"
		plate.color = Palette.EDGE_STEEL_DIM
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.position = Vector2.ZERO
		plate.size = Vector2(BAR_BADGE, BAR_BADGE)
		var fill := ColorRect.new()
		fill.color = Palette.SURFACE_INSET
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.position = Vector2.ONE
		fill.size = Vector2(BAR_BADGE - 2, BAR_BADGE - 2)
		plate.add_child(fill)
		box.add_child(plate)
	# Pip row: 12x12 at pitch 14, starting badge right + 6, y 2..14.
	var pips: Array = opts.get("pips", [])
	var px := float(BAR_BADGE + 6)
	for i in mini(4, pips.size()):
		var pip = pips[i]
		var cell: Control = null
		if pip is Texture2D:
			var tr := TextureRect.new()
			tr.texture = pip
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cell = tr
		elif pip is Color:
			var rim := ColorRect.new()
			rim.color = Palette.SURFACE_INSET
			var dot := ColorRect.new()
			dot.color = pip
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.position = Vector2.ONE
			dot.size = Vector2(BAR_PIP - 2, BAR_PIP - 2)
			rim.add_child(dot)
			cell = rim
		if cell == null:
			continue
		cell.name = "Pip_%d" % i
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.position = Vector2(px + BAR_PIP_PITCH * i, 2)
		cell.size = Vector2(BAR_PIP, BAR_PIP)
		box.add_child(cell)
	# HP bar: 62x7 at (28, 15) — bottom edge 1px inside the footprint.
	if maximum > 0.0 and bool(opts.get("bar", true)):
		var bar := Widgets.bar(hp, maximum, String(opts.get("kind", "hp")), "", BAR_HP)
		bar.name = "HP"
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.position = Vector2(BAR_BADGE + 4, BAR_SIZE.y - BAR_HP.y - 1)
		bar.size = Vector2(BAR_HP)
		box.add_child(bar)
	_overlay_layer().add_child(box)
	_anchor_bar(box, spr)
	_bars.append({"node": box, "spr": spr})
	return box


func _anchor_bar(box: Control, spr: Node2D) -> void:
	box.position = head_of(spr) - Vector2(BAR_SIZE.x / 2.0, BAR_SIZE.y + BAR_AIR)


## Expire held speech and keep bars and bubbles on the figure they belong to
## (a boss bobs; W2's verbs move figures). Numbers are left to their tween.
func _tick_overlays() -> void:
	var keep: Array = []
	for s in _live(_says):
		if _t >= float(s["until"]):
			_drop_overlay(s["node"])
			continue
		_anchor_say(s["node"], s["spr"])
		keep.append(s)
	_says = keep
	_bars = _live(_bars)
	for b in _bars:
		_anchor_bar(b["node"], b["spr"])
	_anchor_speech()


# ---------------------------------------------------------------- the verbs

## The world layer's `motion_scale`: 0 once `apply_settings` has held the
## stage, else 1 — the same number GameSettings.motion_scale() answers for the
## UI, read from the one door the world layer has (RULES §2).
func _motion_scale() -> float:
	return 0.0 if _motion_held else 1.0


## A beat's length in seconds: `GameSettings.motion_duration(ms, floor_ms)`'s
## arithmetic — `max(floor_ms, ms * scale)` — so under reduced motion a beat
## collapses to its floor and a verb "arrives instantly, still arrives" with
## one code path (LESSONS: reduced motion means arrive, not skip).
func _beat(ms: int, floor_ms: int = 0) -> float:
	return maxf(float(floor_ms), float(ms) * _motion_scale()) / 1000.0


## Which way a figure faces on the floor: the sliced strips face right, so a
## flipped sprite faces left. A verb lunges this way and recoils against it;
## `opts.toward` / `opts.from` (stage points) override it per call.
static func _facing(spr: Node2D) -> float:
	if spr is AnimatedSprite2D and (spr as AnimatedSprite2D).flip_h:
		return -1.0
	if spr is Sprite2D and (spr as Sprite2D).flip_h:
		return -1.0
	return 1.0


## docs/12 §5.2's `hit`: a 2px recoil away from the attacker and a one-beat
## `FLASH_COLOR` on the figure. The recoil is two `_beat`s with no floor, so
## under reduced motion it is zero-length and the figure never leaves its mark
## (STAGE-03: "hit = flash only"); the flash is information and keeps its
## `Widgets.Motion.HIT` ms on the stage's clock whatever the setting. `opts.from`
## is the attacker's stage point (default: the figure's own front).
func hit(spr: Node2D, opts: Dictionary = {}) -> bool:
	if spr == null or not is_instance_valid(spr):
		return false
	# A strip boss performs its hit in frames (the flash and the 2px recoil
	# are baked, gen_boss_anims.lua); held still it falls through to the
	# flash-only path below, like any figure.
	if _boss_play(spr, "hit"):
		return true
	var n: Dictionary = ACTS["hit"]
	var dir := _facing(spr)
	if opts.has("from"):
		var from: Vector2 = opts["from"]
		dir = signf(spr.position.x - from.x) if absf(spr.position.x - from.x) > 0.5 else dir
	else:
		dir = -dir
	# A flourish's distance is scaled like its time (the stamp's tilt rule):
	# zero-length AND zero-distance under reduced motion, so a floor in the
	# middle of an act holds the figure on its mark, not mid-step.
	var px := float(n["recoil_px"]) * _motion_scale()
	_start_act(spr, [
		{"dur": _beat(int(n["out_ms"])), "off": Vector2(dir * px, 0)},
		{"dur": _beat(int(n["back_ms"])), "off": Vector2.ZERO},
	], false, "")
	_flash(spr, Widgets.Motion.HIT)
	return true


## The one-beat flash. Restores the colour the figure had before (or the colour
## its running act started from, so a flash inside a cast does not pin the
## cast's tint), through the same clock that expires the held speech.
func _flash(spr: Node2D, ms: int) -> void:
	for f in _flashes:
		if f["spr"] == spr:
			f["until"] = _t + float(ms) / 1000.0
			spr.modulate = FLASH_COLOR
			return
	var restore: Color = spr.modulate
	for a in _acts:
		if a["spr"] == spr:
			restore = a["mod0"]
	_flashes.append({"spr": spr, "until": _t + float(ms) / 1000.0, "restore": restore})
	spr.modulate = FLASH_COLOR
	set_process(true)


## STAGE-09's procedural acts, frame-free: `attack` = a 6px lunge and back
## (180ms); `cast` = a 2px rise with an emissive lift (0.3s); `fumble` = the
## docs/12 §5.3 beat — commit lunge, a 200ms freeze (a floor: the "!" over the
## head is where the joke is read, so the freeze survives reduced motion),
## ±12° × motion_scale, recovery; `death` = the party_state_style grey and a
## 45° topple that STAYS (a fallen body is a destination, not a flourish, so
## it arrives instantly rather than being scaled away). `opts.toward` is a
## stage point (the target) for the lunge's direction. Returns false for a
## verb the stage does not know.
func act(spr: Node2D, verb: String, opts: Dictionary = {}) -> bool:
	if spr == null or not is_instance_valid(spr) or not ACTS.has(verb):
		return false
	var n: Dictionary = ACTS[verb]
	var dir := _facing(spr)
	if opts.has("toward"):
		var toward: Vector2 = opts["toward"]
		if absf(toward.x - spr.position.x) > 0.5:
			dir = signf(toward.x - spr.position.x)
	# Flourishes (everything that comes back) scale their distance like their
	# time — see `hit`; the death topple is a destination and keeps its angle.
	var ms := _motion_scale()
	match verb:
		"attack":
			var lunge := Vector2(dir * float(n["lunge_px"]) * ms, 0)
			_start_act(spr, [
				{"dur": _beat(int(n["out_ms"])), "off": lunge},
				{"dur": _beat(int(n["back_ms"])), "off": Vector2.ZERO},
			], false, "")
		"cast":
			var rise := Vector2(0, -float(n["rise_px"]) * ms)
			_start_act(spr, [
				{"dur": _beat(int(n["up_ms"])), "off": rise, "mod": CAST_TINT},
				{"dur": _beat(int(n["down_ms"])), "off": Vector2.ZERO},
			], false, "")
		"fumble":
			var lunge := Vector2(dir * float(n["lunge_px"]) * ms, 0)
			var tilt := -dir * deg_to_rad(float(n["tilt_deg"])) * ms
			_start_act(spr, [
				{"dur": _beat(int(n["lunge_ms"])), "off": lunge},
				{"dur": _beat(int(n["freeze_ms"]), int(n["freeze_ms"])), "off": lunge},
				{"dur": _beat(int(n["tilt_ms"])), "off": lunge, "rot": tilt},
				{"dur": _beat(int(n["recover_ms"])), "off": Vector2.ZERO, "rot": 0.0},
			], false, "!")
		"death":
			var style := party_state_style("dead")
			# A strip boss dies in frames (desaturate, the 12° topple, the fade
			# — gen_boss_anims.lua) and holds the last one; under reduced
			# motion it arrives there at once. The grey is still written, so
			# the floor agrees with the panels the way it does for a raider.
			if _boss_play(spr, "death"):
				_end_act_on(spr)
				var flashes: Array = []
				for f in _flashes:
					if f["spr"] != spr:
						flashes.append(f)
				_flashes = flashes
				spr.modulate = style["tint"]
				return true
			_start_act(spr, [
				{"dur": _beat(int(n["ms"])), "off": Vector2.ZERO,
					"rot": dir * deg_to_rad(float(n["tilt_deg"])), "mod": style["tint"]},
			], true, "")
			if spr is AnimatedSprite2D:
				spr.stop()
				spr.frame = 0
		"hit":
			return hit(spr, opts)
	return true


## Start (or replace) the act on a figure. `segs` are sequential keyframes —
## each one is the state at ITS END (`off` from the figure's base position,
## `rot` absolute radians, `mod` a modulate), reached from the previous
## segment's end over `dur` seconds (0 = at once). `persist` keeps the final
## state; otherwise the figure returns to its base when the act ends. `mark`
## is a Label held over the head for the act's whole length ("!" for a fumble).
func _start_act(spr: Node2D, segs: Array, persist: bool, mark: String) -> void:
	_end_act_on(spr)
	var uses_mod := false
	for s in segs:
		if (s as Dictionary).has("mod"):
			uses_mod = true
	var a := {"spr": spr, "base": spr.position, "rot0": spr.rotation, "mod0": spr.modulate,
		"segs": segs, "t": 0.0, "off": Vector2.ZERO, "persist": persist, "done": Callable(),
		"mark": null, "uses_mod": uses_mod}
	if not mark.is_empty():
		var l := Widgets.label_as(mark, "LabelDamage")
		l.name = "Mark_%s" % spr.name
		l.add_theme_color_override("font_color", MARK_COLOR)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.set_meta("speaker", spr.name)
		_overlay_layer().add_child(l)
		l.size = l.get_combined_minimum_size()
		l.position = head_of(spr) - Vector2(l.size.x / 2.0, l.size.y + BAR_AIR)
		a["mark"] = l
	_acts.append(a)
	_apply_act(a, 0.0)
	set_process(true)


## Finish whatever act a figure is in (restoring its base unless the act
## persists) — a new verb on a busy figure, or the figure leaving.
func _end_act_on(spr: Node2D) -> void:
	var keep: Array = []
	for a in _acts:
		if a["spr"] == spr:
			_finish_act(a)
		else:
			keep.append(a)
	_acts = keep


func _finish_act(a: Dictionary) -> void:
	var spr: Node2D = a["spr"]
	if is_instance_valid(spr):
		if bool(a["persist"]) and not (a["segs"] as Array).is_empty():
			_apply_act_state(a, (a["segs"] as Array).back())
		else:
			spr.position = spr.position - a["off"]
			spr.rotation = a["rot0"]
			if bool(a.get("uses_mod", false)):
				spr.modulate = a["mod0"]
			a["off"] = Vector2.ZERO
	if a["mark"] != null:
		_drop_overlay(a["mark"])
		a["mark"] = null
	var done: Callable = a["done"]
	if done.is_valid():
		done.call()


## The state at time `t` into the act: walk the segments, lerp inside the one
## `t` falls in, and apply. Returns true when the act is over.
func _apply_act(a: Dictionary, t: float) -> bool:
	var spr: Node2D = a["spr"]
	if not is_instance_valid(spr):
		return true
	var prev := {"off": Vector2.ZERO, "rot": a["rot0"], "mod": a["mod0"]}
	var t0 := 0.0
	for s in a["segs"]:
		var seg: Dictionary = s
		var dur := float(seg.get("dur", 0.0))
		var target := {"off": seg.get("off", prev["off"]), "rot": seg.get("rot", prev["rot"]),
			"mod": seg.get("mod", prev["mod"])}
		if dur > 0.0 and t < t0 + dur:
			var f := clampf((t - t0) / dur, 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			_apply_act_state(a, {"off": (prev["off"] as Vector2).lerp(target["off"], f),
				"rot": lerpf(float(prev["rot"]), float(target["rot"]), f),
				"mod": (prev["mod"] as Color).lerp(target["mod"], f)})
			return false
		t0 += dur
		prev = target
	_apply_act_state(a, prev)
	return true


## Write one keyframe onto the figure. The position is written as a DELTA
## from the last one, so it composes with whatever else moves the node (the
## boss's bob writes `position.y` every frame; a hit on the boss must not
## freeze it or snap it).
func _apply_act_state(a: Dictionary, st: Dictionary) -> void:
	var spr: Node2D = a["spr"]
	var off: Vector2 = st.get("off", Vector2.ZERO)
	spr.position = spr.position - a["off"] + off
	a["off"] = off
	spr.rotation = float(st.get("rot", a["rot0"]))
	# Only an act with a tint channel writes modulate — a hit's recoil must
	# not paint over its own flash.
	if bool(a.get("uses_mod", false)):
		spr.modulate = st.get("mod", a["mod0"])


func _tick_acts(dt: float) -> void:
	var keep: Array = []
	for a in _acts:
		a["t"] = float(a["t"]) + dt
		if _apply_act(a, float(a["t"])):
			_finish_act(a)
		else:
			keep.append(a)
			var mark = a["mark"]
			if mark is Label and is_instance_valid(mark):
				mark.position = head_of(a["spr"]) - Vector2(mark.size.x / 2.0, mark.size.y + BAR_AIR)
	_acts = keep
	# The flash is re-asserted after the acts (a cast's tint lerp would paint
	# over it), and restored when its beat is over — to the act's running tint
	# if one is still going, else to what the figure wore before.
	var flashes: Array = []
	for f in _flashes:
		var spr: Node2D = f["spr"]
		if not is_instance_valid(spr):
			continue
		if _t >= float(f["until"]):
			var back: Color = f["restore"]
			for a in _acts:
				if a["spr"] == spr and bool(a.get("uses_mod", false)):
					back = spr.modulate
			spr.modulate = back
			continue
		spr.modulate = FLASH_COLOR
		flashes.append(f)
	_flashes = flashes


# ---------------------------------------------------------------- the VFX

## A strip's row in vfx.json, or {} — the geometry lives with the PNG.
static func _vfx_geom(key: String) -> Dictionary:
	var row = _read(VFX_MANIFEST).get("strips", {}).get(key, null)
	return row if row is Dictionary else {}


## The VFX primitive (PIPE-02, CRITIC-C04): a strip played once (or looped) at
## `pos`, an AnimatedSprite2D with NEAREST filtering and, for `opts.additive`,
## an additive blend so it glows. `strip` is a vfx.json key ("fx_slash_arc") or
## a res:// path; `frame_w` / `fps` <= 0 read the manifest's row. Freed when
## its animation finishes, and by the stage's clock as the fallback (a stage
## outside a tree never advances a frame). Under reduced effects nothing is
## made (VFX are effects); under reduced motion the LAST frame is held for
## `FX_HOLD` — the strike still lands, it just does not move (STAGE-03's
## "single held frame at the target"). `opts`: additive, once (default true),
## flip, scale, emissive, tint. Returns the sprite, or null.
func add_fx(strip: String, frame_w: int, fps: float, pos: Vector2, opts: Dictionary = {}) -> AnimatedSprite2D:
	if _effects_off:
		return null
	var key := strip.get_file().get_basename() if strip.begins_with("res://") else strip
	var path := strip if strip.begins_with("res://") else VFX + strip + ".png"
	if not ResourceLoader.exists(path):
		push_warning("SceneStage: no VFX strip at %s" % path)
		return null
	var geom := _vfx_geom(key)
	var tex: Texture2D = texture(path)
	var fw := frame_w if frame_w > 0 else int(geom.get("frame_w", tex.get_height()))
	var rate := fps if fps > 0.0 else float(geom.get("fps", 12.0))
	rate = maxf(1.0, rate)
	var once := bool(opts.get("once", true))
	var frames := _strip_frames(tex, fw, rate, "play", not once)
	var n := frames.get_frame_count("play")
	var spr := AnimatedSprite2D.new()
	_fx_serial += 1
	spr.name = "Fx_%s_%d" % [key, _fx_serial]
	spr.sprite_frames = frames
	spr.animation = "play"
	spr.position = pos
	spr.flip_h = bool(opts.get("flip", false))
	var sc := float(opts.get("scale", 1.0))
	spr.scale = Vector2(sc, sc)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var em := float(opts.get("emissive", 1.0))
	var tint: Color = opts.get("tint", Color(1, 1, 1, 1))
	spr.modulate = Color(tint.r * em, tint.g * em, tint.b * em, tint.a)
	if bool(opts.get("additive", false)):
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		spr.material = mat
	_lit(spr)
	add_child(spr)
	_lift_layers()
	var until := 0.0
	if _motion_held:
		# stop() rewinds to frame 0, so the held frame is set after it.
		spr.stop()
		spr.frame = n - 1
		until = _t + FX_HOLD
	else:
		spr.play("play")
		until = _t + (float(n) / rate + 0.05 if once else INF)
		if once:
			spr.animation_finished.connect(_free_fx.bind(spr))
	_fx.append({"node": spr, "until": until})
	set_process(true)
	return spr


## Detach and free a finished effect, and forget it.
func _free_fx(node: Node) -> void:
	var keep: Array = []
	for f in _fx:
		if f["node"] != node:
			keep.append(f)
	_fx = keep
	_drop_overlay(node)


func _tick_fx() -> void:
	var keep: Array = []
	for f in _fx:
		var node: Node = f["node"]
		if not is_instance_valid(node):
			continue
		if _t >= float(f["until"]):
			_drop_overlay(node)
			continue
		keep.append(f)
	_fx = keep


## STAGE-03's `burst(pos, kind)`: a one-shot GPUParticles2D (explosiveness
## 0.9, 14 particles, `Widgets.Motion.BURST` ms) in the kind's ramp, plus the
## kind's strip through `add_fx` when W1-VFX drew one. Particles are pure
## motion, so a held stage gets only the strip's held frame; reduced effects
## drops the whole thing. Returns the strip sprite when there is one, else the
## particles, else null. `opts.scale` scales the strip; `opts.size` the dots.
func burst(pos: Vector2, kind: String = "impact", opts: Dictionary = {}) -> Node2D:
	if _effects_off:
		return null
	var k: Dictionary = BURST_KINDS.get(kind, BURST_KINDS["impact"])
	var out: Node2D = null
	if not _motion_held and ResourceLoader.exists(EMBER_TEX):
		var part := GPUParticles2D.new()
		_fx_serial += 1
		part.name = "Burst_%s_%d" % [kind, _fx_serial]
		part.position = pos
		part.one_shot = true
		part.explosiveness = 0.9
		part.amount = 14
		part.lifetime = float(Widgets.Motion.BURST) / 1000.0
		part.texture = texture(EMBER_TEX)
		part.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var mat := ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		mat.direction = Vector3(1, 0, 0)
		mat.spread = 180.0
		mat.initial_velocity_min = 70.0
		mat.initial_velocity_max = 150.0
		mat.gravity = Vector3.ZERO
		mat.damping_min = 90.0
		mat.damping_max = 140.0
		var size := float(opts.get("size", 1.6))
		mat.scale_min = 0.6 * size
		mat.scale_max = 1.3 * size
		var birth := Color(String(k.get("color", "#FF6A3D")))
		var death := Color(String(k.get("end", "#7A1F12")))
		var em := 1.4 if bool(k.get("additive", true)) else 1.0
		var ramp := Gradient.new()
		ramp.set_color(0, Color(birth.r * em, birth.g * em, birth.b * em, 1.0))
		ramp.set_color(1, Color(death.r, death.g, death.b, 0.0))
		var ramp_tex := GradientTexture1D.new()
		ramp_tex.gradient = ramp
		mat.color_ramp = ramp_tex
		part.process_material = mat
		part.emitting = true
		_lit(part)
		add_child(part)
		_lift_layers()
		_fx.append({"node": part, "until": _t + part.lifetime + 0.1})
		set_process(true)
		out = part
	var strip := String(k.get("strip", ""))
	if not strip.is_empty():
		var spr := add_fx(strip, 0, 0.0, pos, {"additive": bool(k.get("additive", true)),
			"once": true, "scale": float(opts.get("scale", 1.0)), "flip": bool(opts.get("flip", false))})
		if spr != null:
			out = spr
	return out


## STAGE-03's `slash(pos)`: the arc strip, once, additive. `opts.flip` turns
## it for a strike from the right; `opts.scale` for a 2x figure.
func slash(pos: Vector2, opts: Dictionary = {}) -> AnimatedSprite2D:
	return add_fx("fx_slash_arc", 0, 0.0, pos, {"additive": true, "once": true,
		"flip": bool(opts.get("flip", false)), "scale": float(opts.get("scale", 1.0))})


## STAGE-03's `bolt(from, to, kind)`: the arcane bolt strip (tinted per kind),
## nose toward `to`, travelling `BOLT_MS` on the stage's clock with three
## fading ghosts behind it, then a `burst(to, kind)` where it lands. Under
## reduced motion the travel is zero-length — the bolt is never seen moving,
## the burst's held frame is what lands (STAGE-03). Returns the bolt sprite
## (already gone when the travel collapsed), or null under reduced effects.
func bolt(from: Vector2, to: Vector2, kind: String = "arcane", opts: Dictionary = {}) -> AnimatedSprite2D:
	if _effects_off:
		return null
	var tint := Color(String(BOLT_TINTS.get(kind, BOLT_TINTS["arcane"])))
	var spr := add_fx("fx_bolt_arcane", 0, 0.0, from, {"additive": true, "once": false,
		"scale": float(opts.get("scale", 1.0)), "tint": tint})
	if spr == null:
		return null
	var dir := to - from
	spr.rotation = dir.angle() + PI / 2.0
	var ghosts: Array = []
	for i in BOLT_TRAIL:
		var g := Sprite2D.new()
		g.name = "Trail_%d" % i
		g.texture = spr.sprite_frames.get_frame_texture("play", 0)
		g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		g.material = spr.material
		g.modulate = Color(tint.r, tint.g, tint.b, 0.45 - 0.12 * float(i))
		g.position = from
		g.rotation = spr.rotation
		g.scale = spr.scale
		_lit(g)
		add_child(g)
		ghosts.append(g)
	_lift_layers()
	var travel := _beat(BOLT_MS)
	var a := {"spr": spr, "base": spr.position, "rot0": spr.rotation, "mod0": spr.modulate,
		"segs": [{"dur": travel, "off": dir}], "t": 0.0, "off": Vector2.ZERO, "persist": true,
		"done": _land_bolt.bind(spr, ghosts, to, kind, opts), "mark": null}
	a["ghosts"] = ghosts
	_acts.append(a)
	_apply_act(a, 0.0)
	set_process(true)
	if travel <= 0.0:
		_end_act_on(spr)
	return spr


func _land_bolt(spr: Node, ghosts: Array, to: Vector2, kind: String, opts: Dictionary) -> void:
	for g in ghosts:
		_drop_overlay(g)
	_free_fx(spr)
	burst(to, kind, opts)


## The trail's ghosts lag the bolt along its own path.
func _tick_trails() -> void:
	for a in _acts:
		if not a.has("ghosts"):
			continue
		var spr: Node2D = a["spr"]
		if not is_instance_valid(spr):
			continue
		var base: Vector2 = a["base"]
		var off: Vector2 = a["off"]
		var i := 1
		for g in a["ghosts"]:
			if is_instance_valid(g):
				(g as Node2D).position = base + off * maxf(0.0, 1.0 - 0.18 * float(i))
			i += 1


# ---------------------------------------------------------------- water, light

## spec 09 §5 row 4's water, with that row's own numbers: two noise textures
## sampled at UV/64 and scrolled at 0.02 and -0.013 UV/s, added as about ±6 of
## 255 value (0.024). Only the crests catch light — a flat wash over a painted
## river reads as fog, not water — so the sum is pushed through a smoothstep
## before it is added.
##
## `motion` is a uniform rather than a `set_process` flag because the animation
## is TIME-driven inside the shader, where the reduced-motion switch cannot
## reach any other way.
const WATER_SHADER := """
shader_type canvas_item;
render_mode blend_add;

uniform vec4 tint : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform float strength = 0.024;
uniform vec2 speed_a = vec2(0.02, -0.013);
uniform vec2 speed_b = vec2(-0.011, 0.017);
uniform float tex_scale = 64.0;
uniform vec2 quad_size = vec2(256.0, 256.0);
uniform float motion = 1.0;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

void fragment() {
	vec2 p = UV * quad_size / tex_scale;
	float a = texture(noise_tex, p + speed_a * TIME * motion).r;
	float b = texture(noise_tex, p * 1.7 + speed_b * TIME * motion).r;
	float v = smoothstep(0.55, 0.95, (a + b) * 0.5);
	// The rect is a mask, so its own edges must not be one: fade the last 12%.
	vec2 e = min(UV, vec2(1.0) - UV) / 0.12;
	v *= clamp(min(e.x, e.y), 0.0, 1.0);
	COLOR = vec4(tint.rgb, v * strength * 20.0);
}
"""

## STAGE-05: the crystal pulse quad used to be a hard-edged additive rectangle,
## which read as a translucent box over the plate. The quad's `color` (and its
## pulsing alpha, which the tests read) still drives the light; the shader
## feathers the last `feather` of each edge and rolls the light off toward the
## corners so it reads as a glow around the shafts rather than a box.
const PULSE_SHADER := """
shader_type canvas_item;
render_mode blend_add;

uniform float feather = 0.35;

void fragment() {
	vec2 e = min(UV, vec2(1.0) - UV) / max(feather, 0.001);
	float edge = clamp(min(e.x, e.y), 0.0, 1.0);
	edge = edge * edge * (3.0 - 2.0 * edge);
	float r = length((UV - vec2(0.5)) * 2.0);
	float radial = 1.0 - smoothstep(0.45, 1.05, r);
	COLOR = vec4(COLOR.rgb, COLOR.a * edge * radial);
}
"""

## STAGE-14 / PIPE-10 / TOWN-12: a texture drifting across a rect — the cloud
## strips over the aerial's sky. The strip is periodic in x (gen_clouds.py), so
## sampling it with `repeat_enable` and a pixel offset that grows with TIME
## never shows a seam; `motion` is the reduced-motion uniform, as in the water.
const SCROLL_SHADER := """
shader_type canvas_item;

uniform sampler2D tex : repeat_enable, filter_nearest;
uniform float px_per_s = 3.0;
uniform vec2 quad_size = vec2(1536.0, 220.0);
uniform vec2 tex_size = vec2(1536.0, 220.0);
uniform float opacity = 0.6;
uniform float motion = 1.0;

void fragment() {
	vec2 px = UV * quad_size;
	px.x -= TIME * px_per_s * motion;
	vec4 c = texture(tex, px / tex_size);
	COLOR = vec4(c.rgb, c.a * opacity);
}
"""

## STAGE-07's cheap half (CRITIC-C17: the blur is docs/15 Q08; this is not):
## an 8% darkening of the outer `width` of the stage, in the page ground rather
## than pure black. An effect, so `reduced_effects` hides it.
const VIGNETTE_SHADER := """
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.012, 0.043, 0.075, 1.0);
uniform float strength = 0.08;
uniform float width = 0.08;

void fragment() {
	vec2 e = min(UV, vec2(1.0) - UV) / max(width, 0.001);
	float edge = 1.0 - clamp(min(e.x, e.y), 0.0, 1.0);
	COLOR = vec4(tint.rgb, tint.a * strength * edge * edge);
}
"""


static func _water_noise() -> NoiseTexture2D:
	if _noise_tex != null:
		return _noise_tex
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.04
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.width = 128
	tex.height = 128
	_noise_tex = tex
	return tex


## A masked quad of moving water. Returns the node so a screen could reach it.
func add_shimmer(cfg: Dictionary) -> ColorRect:
	var rect: Array = cfg.get("rect", [])
	if rect.size() < 4:
		return null
	var quad := ColorRect.new()
	quad.name = "Shimmer_%d" % _shimmers.size()
	quad.color = Color(1, 1, 1, 1)
	quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quad.position = Vector2(float(rect[0]), float(rect[1]))
	quad.size = Vector2(float(rect[2]), float(rect[3]))
	var mat := ShaderMaterial.new()
	mat.shader = _shader(WATER_SHADER)
	mat.set_shader_parameter("noise_tex", _water_noise())
	mat.set_shader_parameter("tint", Color(String(cfg.get("color", "#7FC8FF"))))
	mat.set_shader_parameter("strength", float(cfg.get("strength", 0.024)))
	mat.set_shader_parameter("tex_scale", float(cfg.get("tex_scale", 64.0)))
	# Set explicitly rather than left to the shader's own defaults: these two
	# numbers ARE spec 09 §5 row 4 ("0.02 and -0.013 UV/s"), so they belong where
	# the citation is, and a scene can override them per rect.
	var sa: Array = cfg.get("speed_a", [0.02, -0.013])
	var sb: Array = cfg.get("speed_b", [-0.011, 0.017])
	mat.set_shader_parameter("speed_a", Vector2(float(sa[0]), float(sa[1])))
	mat.set_shader_parameter("speed_b", Vector2(float(sb[0]), float(sb[1])))
	mat.set_shader_parameter("quad_size", quad.size)
	mat.set_shader_parameter("motion", 0.0 if _motion_held else 1.0)
	quad.material = mat
	_lit(quad)
	add_child(quad)
	_shimmers.append(quad)
	_lift_layers()
	return quad


## spec 09 §5 row 5: a cyan glow quad over the crystal shafts, pulsing ±10% on a
## 3-second period. The pulse is a `color.a` value pulse, which is what the row
## asks for and what a headless test can read back; the ShaderMaterial only
## feathers the quad's edges (STAGE-05).
func add_pulse(cfg: Dictionary) -> ColorRect:
	var rect: Array = cfg.get("rect", [])
	if rect.size() < 4:
		return null
	var quad := ColorRect.new()
	quad.name = "Pulse_%d" % _pulses.size()
	var base := float(cfg.get("energy", 0.16))
	quad.color = Color(String(cfg.get("color", "#78C8FF")))
	quad.color.a = base
	quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quad.position = Vector2(float(rect[0]), float(rect[1]))
	quad.size = Vector2(float(rect[2]), float(rect[3]))
	var mat := ShaderMaterial.new()
	mat.shader = _shader(PULSE_SHADER)
	mat.set_shader_parameter("feather", float(cfg.get("feather", 0.35)))
	quad.material = mat
	_lit(quad)
	add_child(quad)
	_pulses.append({"node": quad, "base": base, "period": float(cfg.get("period", 3.0)),
		"swing": float(cfg.get("swing", 0.10)), "phase": _rng.randf() * 6.28})
	_lift_layers()
	return quad


## A drifting texture over a rect (STAGE-14): `tex` slides `px_per_s` pixels a
## second along +x, tiled, at `opacity`. A layer of the world, so it takes
## both switches the water does: `motion` 0 under reduced motion, hidden under
## reduced effects. Returns the quad, or null for a bad rect / no texture.
func add_scroll(tex: Texture2D, rect: Rect2, px_per_s: float, opts: Dictionary = {}) -> ColorRect:
	if tex == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return null
	var quad := ColorRect.new()
	quad.name = "Scroll_%d" % _scrolls.size()
	quad.color = Color(1, 1, 1, 1)
	quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quad.position = rect.position
	quad.size = rect.size
	var mat := ShaderMaterial.new()
	mat.shader = _shader(SCROLL_SHADER)
	mat.set_shader_parameter("tex", tex)
	mat.set_shader_parameter("px_per_s", px_per_s)
	mat.set_shader_parameter("quad_size", quad.size)
	mat.set_shader_parameter("tex_size", tex.get_size())
	mat.set_shader_parameter("opacity", float(opts.get("opacity", 0.6)))
	mat.set_shader_parameter("motion", 0.0 if _motion_held else 1.0)
	quad.material = mat
	_lit(quad)
	add_child(quad)
	_scrolls.append(quad)
	_lift_layers()
	return quad


## One particle emitter from an ember entry: the preset's numbers under the
## entry's own (STAGE-19: the cave's motes were the campfire's ramp).
func _build_ember(em: Dictionary, ember_tex: Texture2D) -> GPUParticles2D:
	var preset: Dictionary = EMBER_PRESETS.get(String(em.get("preset", "embers")), EMBER_PRESETS["embers"])
	var cfg := preset.duplicate()
	cfg.merge(em, true)
	var part := GPUParticles2D.new()
	part.name = "Embers_%d" % _embers.size()
	var pos: Array = cfg.get("pos", [0, 0])
	part.position = Vector2(float(pos[0]), float(pos[1]))
	part.amount = int(cfg.get("amount", 24))
	part.lifetime = float(cfg.get("lifetime", 2.2))
	part.preprocess = float(cfg.get("preprocess", 0.0))
	part.texture = ember_tex
	part.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(float(cfg.get("spread", 14)), 3, 0)
	var dir: Array = cfg.get("direction", [0.0, -1.0])
	mat.direction = Vector3(float(dir[0]), float(dir[1]), 0)
	mat.spread = float(cfg.get("cone", 18.0))
	var height := float(cfg.get("height", 90))
	var vel: Array = cfg.get("velocity", [height * 0.35, height * 0.55])
	mat.initial_velocity_min = float(vel[0])
	mat.initial_velocity_max = float(vel[1])
	mat.gravity = Vector3(0, float(cfg.get("gravity", -12.0)), 0)
	var damp: Array = cfg.get("damping", [4.0, 9.0])
	mat.damping_min = float(damp[0])
	mat.damping_max = float(damp[1])
	var size := float(cfg.get("size", 1.0))
	mat.scale_min = 0.6 * size
	mat.scale_max = 1.2 * size
	var birth := Color(String(cfg.get("color", "#FFC060")))
	var em_mul := float(cfg.get("emissive", 1.6))
	var death := Color(String(cfg.get("end", "#99261A")))
	var ramp := Gradient.new()
	ramp.set_color(0, Color(birth.r * em_mul, birth.g * em_mul, birth.b * em_mul, 1.0))  # emissive at birth so it blooms
	ramp.set_color(1, Color(death.r, death.g, death.b, 0.0))
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex
	part.process_material = mat
	return part


func _build(d: Dictionary) -> void:
	var t := Time.get_ticks_usec()
	_noise = FastNoiseLite.new()
	_noise.frequency = 1.6
	_rng.seed = hash(scene_name)
	_figure_scale = float(d.get("figure_scale", 1.0))

	# ---- plate ---------------------------------------------------------------
	var plate_size := Vector2(1536, 1024)
	var plate_path := String(d.get("plate", ""))
	if not plate_path.is_empty() and ResourceLoader.exists(plate_path):
		var plate := TextureRect.new()
		plate.name = "Plate"
		plate.texture = texture(plate_path)
		plate.stretch_mode = TextureRect.STRETCH_KEEP
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lit(plate)
		add_child(plate)
		plate.position = Vector2.ZERO
		plate_size = plate.texture.get_size()
	t = _lap(t, "s_plate")

	# ---- glow ----------------------------------------------------------------
	# 11 §6: verified on the Mobile renderer. Threshold 1.3 so ordinary UI
	# (≤ 1.0) stays crisp and only the emissive flames bloom.
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CANVAS
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_strength = 1.0
	e.glow_bloom = 0.15
	e.glow_hdr_threshold = float(d.get("glow_threshold", 1.3))
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.environment = e
	add_child(env)
	_env = env
	t = _lap(t, "s_env")

	# ---- animated props --------------------------------------------------------
	for p in d.get("props", []):
		if not (p is Dictionary):
			continue
		var strip := String(p.get("strip", ""))
		if strip.is_empty() or not ResourceLoader.exists(strip):
			continue
		var tex: Texture2D = texture(strip)
		var fw := int(p.get("frame_w", tex.get_height()))
		var frames := _strip_frames(tex, fw, float(p.get("fps", 9)), "burn")
		var n := frames.get_frame_count("burn")
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = frames
		spr.animation = "burn"
		spr.frame = int(p.get("phase", 0)) % max(1, n)
		spr.play("burn")
		var pos: Array = p.get("pos", [0, 0])
		spr.position = Vector2(float(pos[0]), float(pos[1]))
		var anchor := String(p.get("anchor", "bottom"))
		if anchor == "bottom":
			spr.offset = Vector2(0, -tex.get_height() / 2.0)
		elif anchor == "topleft":
			# An opaque crop of the plate (a banner, W4-LIFE): `pos` is the
			# crop's origin, so at rest it lies on its own pixels.
			spr.centered = false
		# The fires are over-driven warm so the glow catches them (11 §6); a
		# prop with no `emissive` is drawn as it is — a banner cut from the
		# plate must not come back tinted.
		if p.has("emissive"):
			var em := float(p.get("emissive", 1.0))
			spr.modulate = Color(em, em * 0.94, em * 0.85, 1.0)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_lit(spr)
		add_child(spr)
		_props.append(spr)
	t = _lap(t, "s_props")

	# ---- rotors ----------------------------------------------------------------
	# STAGE-14: the windmill sails, over the plate and under the crowd. A
	# `rotor` entry names its texture by path (the scene file is the one place
	# a strip is named), its axle and its rate.
	for r in d.get("rotor", []):
		if not (r is Dictionary):
			continue
		var tex_path := String(r.get("tex", ""))
		var rpos: Array = r.get("pos", [])
		if tex_path.is_empty() or not ResourceLoader.exists(tex_path) or rpos.size() < 2:
			continue
		add_rotor(texture(tex_path), Vector2(float(rpos[0]), float(rpos[1])), float(r.get("rad_per_s", 0.15)), r)

	# ---- actors --------------------------------------------------------------
	# The people. spec 09 §4.1 row 4 / §4.2 row 8 had them baked into the plate
	# ("ambient patrons", "ambient raiders"), which is exactly what the bare
	# plates removed: a painted crowd cannot react, cannot be re-lit, and never
	# moves. Each actor is an AnimatedSprite2D over the plate, placed by its
	# FEET, breathing on its own frame.
	#
	# Depth is TREE ORDER, not z_index: the bubbles and the speaking plate are
	# Controls added after this block, and a z_index above zero here would lift
	# a figure over them. Sorting by y and adding back-to-front gives the same
	# overlap for free — the figure standing lower on the plate is in front.
	var raw_actors: Array = d.get("actors", []) if d.get("actors", []) is Array else []
	var placed_entries: Array = _sorted_actors(raw_actors)
	var placed_sprites: Array = []   # aligned with placed_entries, for `speech.speaker`
	for a in placed_entries:
		placed_sprites.append(add_actor(a))
	t = _lap(t, "s_actors")

	# ---- paths ---------------------------------------------------------------------
	# TOWN-27: the figures that walk. Added after the standing crowd, each
	# settling into its depth among them (`_settle_depth`), and re-settled
	# every tick as it moves.
	for p in d.get("paths", []):
		if p is Dictionary:
			add_walker(p)
	t = _lap(t, "s_paths")

	# ---- lights ------------------------------------------------------------------
	var light_tex: Texture2D = texture(LIGHT_TEX)
	for l in d.get("lights", []):
		if not (l is Dictionary) or light_tex == null:
			continue
		var light := PointLight2D.new()
		light.texture = light_tex
		var pos: Array = l.get("pos", [0, 0])
		light.position = Vector2(float(pos[0]), float(pos[1]))
		light.color = Color(String(l.get("color", "#FFB060")))
		var base := float(l.get("energy", 1.0))
		light.energy = base
		light.texture_scale = float(l.get("radius", 200)) / 32.0
		light.blend_mode = Light2D.BLEND_MODE_ADD
		# UI-26: the light reaches the stage's own layer and nothing else.
		light.range_item_cull_mask = LIGHT_LAYER
		add_child(light)
		_lights.append({"node": light, "base": base,
			"flicker": float(l.get("flicker", 0.2)), "phase": _rng.randf() * 100.0})
	t = _lap(t, "s_lights")

	# ---- embers --------------------------------------------------------------------
	var ember_tex: Texture2D = texture(EMBER_TEX)
	for em in d.get("embers", []):
		if not (em is Dictionary) or ember_tex == null:
			continue
		var part := _build_ember(em, ember_tex)
		_lit(part)
		add_child(part)
		_embers.append(part)
	t = _lap(t, "s_embers")

	# ---- water and crystal light -------------------------------------------
	# Added after the embers and BEFORE the bubbles, so a shimmer never lies over
	# a speech bubble: these are ambience, and the bubbles carry words.
	for sh in d.get("shimmer", []):
		if sh is Dictionary:
			add_shimmer(sh)
	for pl in d.get("pulse", []):
		if pl is Dictionary:
			add_pulse(pl)
	t = _lap(t, "s_water")

	# ---- drift ---------------------------------------------------------------------
	# STAGE-14: the aerial's clouds. A `scroll` entry names its texture by path
	# (a scene file is the one place a strip is named), its rect and its speed.
	for sc in d.get("scroll", []):
		if not (sc is Dictionary):
			continue
		var tex_path := String(sc.get("tex", ""))
		var rect: Array = sc.get("rect", [])
		if tex_path.is_empty() or not ResourceLoader.exists(tex_path) or rect.size() < 4:
			continue
		add_scroll(texture(tex_path), Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3])),
			float(sc.get("px_per_s", 3.0)), sc)

	# ---- flyers ----------------------------------------------------------------------
	# STAGE-14: the gulls, over the clouds (a bird under a 0.4 veil is a smudge)
	# and under the bubbles.
	for fl in d.get("flyers", []):
		if fl is Dictionary:
			add_flyer(String(fl.get("strip", "")), fl.get("points", []), float(fl.get("px_per_s", 12.0)), fl)
	t = _lap(t, "s_drift")

	# ---- bubbles -----------------------------------------------------------------
	# A bubble is [x, y], [x, y, "emote:mug"] or [x, y, "emote:skull", "wipe"]:
	# the third entry is an emote key from the icon grid (TOWN-26: mug, sweat,
	# skull, zzz, …; the "emote:" prefix is optional) shown inside the kit's
	# frame; without one the bubble carries the reference's "..." — a figure
	# mid-sentence, which is what most of them are. A fourth entry is a MOOD:
	# such a bubble is up only while `set_mood` has named that mood (the camp's
	# skull after a wipe), and then always, on top of the ambient picks.
	_bubble_visible = int(d.get("bubble_visible", 2))
	for b in d.get("bubbles", []):
		if not (b is Array) or b.size() < 2:
			continue
		var kind := "dots"
		var glyph: Texture2D = null
		if b.size() > 2:
			kind = String(b[2]).trim_prefix("emote:")
			glyph = Icons.at("emote", kind)
		var bub := Widgets.speech_bubble(kind, glyph)
		bub.position = Vector2(float(b[0]), float(b[1]))
		bub.visible = false
		add_child(bub)
		_bubbles.append(bub)
		_bubble_moods.append(String(b[3]) if b.size() > 3 else "")
	_shuffle_bubbles()
	t = _lap(t, "s_bubbles")

	# ---- the speaking bubble -----------------------------------------------------
	# Concept 3 paints one figure's line into the scene ("I think I'm ready for
	# a real raid this time!"). Ours belongs to someone and changes its mind:
	# the JSON's lines by default, a screen's own (set_lines) when it has them.
	#
	# TOWN-03 / STAGE-10's anchor: `speaker` names who says it — an index into
	# the JSON's `actors` (authoring order, not depth order), a `who`, or a
	# list of either. The plate hangs over that figure's head with the kit's
	# tail on it (`Widgets.speech_plate`'s second argument); with several
	# candidates the LINE picks the speaker (its hash, so a shot is stable and
	# a scene rotates its mouths); with a named speaker that did not build the
	# plate hides (a line with no mouth is a tooltip — KIT-02); with no
	# `speaker` at all `pos` still rules and there is no tail.
	var sp = d.get("speech", null)
	if sp is Dictionary:
		_lines = sp.get("lines", [])
		var size: Array = sp.get("size", [182, 76])
		_speech_size = Vector2(float(size[0]), float(size[1]))
		var pos: Array = sp.get("pos", [0, 0])
		_speech_pos = Vector2(float(pos[0]), float(pos[1]))
		_speech_named = sp.has("speaker")
		for want in _as_list(sp.get("speaker", null)):
			var idx := -1
			if want is float or want is int:
				idx = int(want)
			elif want is String:
				for i in raw_actors.size():
					if String((raw_actors[i] as Dictionary).get("who", "")) == want:
						idx = i
						break
			if idx < 0 or idx >= raw_actors.size():
				push_warning("SceneStage: scene '%s' names speaker %s, which is not an actor"
					% [scene_name, want])
				continue
			var entry = raw_actors[idx]
			for i in placed_entries.size():
				if placed_entries[i] == entry and placed_sprites[i] != null:
					_speech_speakers.append(placed_sprites[i])
					break
		if _speech_named and _speech_speakers.is_empty():
			push_warning("SceneStage: scene '%s' names a speaker and none built; the line hides"
				% scene_name)
		_place_speech(String(_lines[0]) if not _lines.is_empty() else "")
	t = _lap(t, "s_speech")

	# ---- vignette ------------------------------------------------------------------
	# Over the world, under the overlays: the figures and the plate darken at the
	# frame's edges, the bars and numbers over them do not. Fitted to the rows
	# the screen SHOWS (`_fit_vignette`): every screen offsets the stage by a
	# negative `position` and sizes it to the host, so the visible band starts
	# at `-position` — a vignette over the whole plate would darken rows that
	# are off the screen and leave the visible top edge bare.
	_plate_size = plate_size
	var vig := ColorRect.new()
	vig.name = "Vignette"
	vig.color = Color(1, 1, 1, 1)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.position = Vector2.ZERO
	vig.size = plate_size
	var vmat := ShaderMaterial.new()
	vmat.shader = _shader(VIGNETTE_SHADER)
	vmat.set_shader_parameter("tint", Palette.GROUND_PAGE)
	vmat.set_shader_parameter("strength", float(d.get("vignette", 0.08)))
	vmat.set_shader_parameter("width", 0.08)
	vig.material = vmat
	add_child(vig)
	_vignette = vig
	_fit_vignette()
	t = _lap(t, "s_vignette")

	# ---- overlay layer -------------------------------------------------------------
	_overlay_layer()

	set_process(not _lights.is_empty() or not _bubbles.is_empty() or _speech != null
		or not _pulses.is_empty() or not _bobbers.is_empty()
		or not _walkers.is_empty() or not _rotors.is_empty() or not _flyers.is_empty())


## The vignette covers the band the screen shows: from `-position` (the rows
## and columns the screen's offset scrolls off) to the stage's far edge (its
## `size` is the host's, once a screen has set it; the plate until then).
func _fit_vignette() -> void:
	if _vignette == null or not is_instance_valid(_vignette):
		return
	var full := _plate_size if size == Vector2.ZERO else size
	var origin := Vector2(maxf(0.0, -position.x), maxf(0.0, -position.y))
	_vignette.position = origin
	_vignette.size = (full - origin).max(Vector2.ZERO)


## The speaking bubble hangs over its speaker's head (its tail's apex
## `TAIL_AIR` above it, its bottom edge `SAY_AIR`) when the scene names one; a
## scene without a speaker keeps `pos`.
func _anchor_speech() -> void:
	if _speech == null or _speech_speaker == null or not is_instance_valid(_speech_speaker):
		return
	# The same lift as `say_at`'s (UI-20): clear of the heads around the
	# speaker and of the screen's keep-out rects (the camp's callouts, UI-04).
	var want := _clear_plate(_speech.size, _speech_speaker, _keep_out_rects())
	if want == _speech.position:
		return
	_speech.position = want
	_stretch_tail(_speech, head_of(_speech_speaker).y - TAIL_AIR - (want.y + _speech.size.y))
	_speech.item_rect_changed.emit()   # see _anchor_say


## `null` -> [], a scalar -> [it], an Array -> itself.
static func _as_list(v) -> Array:
	if v == null:
		return []
	if v is Array:
		return v
	return [v]


## Put `text` in the speaking bubble, over the figure the line picks. The
## plate is (re)built when its speaker changes, because the kit's tail points
## at the head it was given: a plate that moved to another figure would keep
## pointing at the first one. The plate keeps its sibling slot so the depth
## order the bubbles were built in holds.
func _place_speech(text: String) -> void:
	var speaker: Node2D = null
	if not _speech_speakers.is_empty():
		var live: Array = []
		for s in _speech_speakers:
			if is_instance_valid(s):
				live.append(s)
		_speech_speakers = live
		if not live.is_empty():
			speaker = live[absi(hash(text)) % live.size()]
	if _speech != null and is_instance_valid(_speech) and speaker == _speech_speaker:
		if _speech_label != null:
			_speech_label.text = text
	else:
		var at := get_child_count()
		if _speech != null and is_instance_valid(_speech):
			at = _speech.get_index()
			remove_child(_speech)
			_speech.queue_free()
		_speech_speaker = speaker
		if speaker != null:
			_speech = Widgets.speech_plate(text, head_of(speaker) - Vector2(0, TAIL_AIR))
		else:
			_speech = Widgets.speech_plate(text)
		_speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Widgets.content_of(_speech).mouse_filter = Control.MOUSE_FILTER_IGNORE   # the Pad too, as say_at
		add_child(_speech)
		move_child(_speech, mini(at, get_child_count() - 1))
		_speech.position = _speech_pos
		_speech.size = _speech_size
		_speech.custom_minimum_size = _speech_size
		_speech_label = Widgets.content_of(_speech).get_child(0) as Label
		if _speech_label != null:
			_speech_label.custom_minimum_size = Vector2(_speech_size.x - 16, 0)
	_speech.visible = not text.is_empty() and not (_speech_named and speaker == null)
	_anchor_speech()
	_speech.item_rect_changed.emit()   # aim the tail once the plate is placed (see _anchor_say)


## Name the scene's mood — bubbles authored with that mood (a fourth entry,
## e.g. "wipe" for the camp's skull) come up and stay up; "" clears it. The
## screen knows the state (TOWN-26: `last_result`); the stage only shows it.
func set_mood(mood: String) -> void:
	_mood = mood
	_apply_mood()


func _apply_mood() -> void:
	for i in _bubbles.size():
		var mood := String(_bubble_moods[i])
		if not mood.is_empty() and is_instance_valid(_bubbles[i]):
			_bubbles[i].visible = (mood == _mood)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_vignette()


## docs/13 §13's two switches finally have a consumer. Reduced motion holds
## every layer still (flames on their first frame, no flicker, the bubbles
## that are up stay up); reduced effects drops the glow and the embers. Read
## when the stage joins a tree, because that is when the autoload is reachable.
func _ready() -> void:
	# The screens set `position` and `size` BEFORE add_child, when no RESIZED
	# notification is sent (the node is not in a tree yet), so the fit runs
	# here as well.
	_fit_vignette()
	var settings = Services.find(self, "GameSettings")
	if settings == null:
		return
	apply_settings(bool(settings.get_value("reduced_motion")),
		bool(settings.get_value("reduced_effects")))


## Split out of `_ready` so both switches are testable: a unit test owns the
## SceneTree root itself, so a node parented under it is never "inside the
## tree" and `_ready` does not fire (see LESSONS.md). The screens reach this
## through `_ready`; the tests reach it directly.
func apply_settings(reduced_motion: bool, reduced_effects: bool) -> void:
	_motion_held = _motion_held or reduced_motion
	_effects_off = _effects_off or reduced_effects
	if reduced_motion:
		for spr in _props + _actors:
			spr.stop()
			spr.frame = 0
		for b in _bobbers:
			var node: Node2D = b["node"]
			if is_instance_valid(node):
				node.position.y = b["base_y"]
		# A strip boss holds its first frame — unless it is dead, when it holds
		# its last (a fallen body is a destination); the eyes follow.
		for b in _bosses:
			var boss: AnimatedSprite2D = b["spr"]
			if not is_instance_valid(boss):
				continue
			boss.stop()
			var dead := String(boss.animation) == "death"
			boss.frame = boss.sprite_frames.get_frame_count(boss.animation) - 1 if dead else 0
			_mirror_boss_glow(boss)
		for q in _shimmers + _scrolls:
			if is_instance_valid(q) and q.material is ShaderMaterial:
				q.material.set_shader_parameter("motion", 0.0)
		for p in _pulses:
			var pnode: ColorRect = p["node"]
			if is_instance_valid(pnode):
				pnode.color.a = p["base"]
		# Particles are motion too (a chimney's plume, the campfire's sparks):
		# held in place, still drawn — a preprocessed plume stays a plume.
		for part in _embers:
			if is_instance_valid(part):
				part.speed_scale = 0.0
		# An effect mid-flight holds its last frame; an act arrives at once
		# (its beats are now zero-length) on the next tick.
		for f in _fx:
			var node: Node = f["node"]
			if node is AnimatedSprite2D and is_instance_valid(node):
				node.stop()
				node.frame = node.sprite_frames.get_frame_count(node.animation) - 1
		# The travellers (W4-LIFE): a walker is one of `_actors` and is held
		# above, on the pose, where it stands; a gull holds its frame where it
		# flies; a sail keeps its angle. Their ticks sit behind the gate in
		# `_process`, so none of them moves again.
		for fl in _flyers:
			var bird: AnimatedSprite2D = fl["spr"]
			if is_instance_valid(bird):
				bird.stop()
				bird.frame = 0
		# Nothing ambient ticks any more; only a verb or an effect still in
		# flight keeps the clock, so it can finish and go.
		set_process(not (_acts.is_empty() and _fx.is_empty() and _flashes.is_empty()))
	if reduced_effects:
		if _env != null and _env.environment != null:
			_env.environment.glow_enabled = false
		for part in _embers:
			part.emitting = false
		for f in _fx:
			var node: Node = f["node"]
			if is_instance_valid(node):
				_drop_overlay(node)
		_fx = []
		for q in _scrolls:
			if is_instance_valid(q):
				q.visible = false
		# CRITIC-G17: the flames are over-driven (modulate 1.2-1.35) so that the
		# glow catches them; with the glow off that over-drive clips to a flat
		# white-orange, so they return to 1.0 — the strip's own colours. The
		# bosses' eye layers (1.6) likewise.
		for spr in _props:
			if is_instance_valid(spr):
				spr.modulate = Color(1, 1, 1, 1)
		for b in _bosses:
			var glow = b["glow"]
			if glow is AnimatedSprite2D and is_instance_valid(glow):
				glow.modulate = Color(1, 1, 1, 1)
		# The water, the crystal light and the vignette are effects, not
		# motion: §13's second switch is the one that turns them off entirely.
		for q in _shimmers:
			if is_instance_valid(q):
				q.visible = false
		for p in _pulses:
			var pnode: ColorRect = p["node"]
			if is_instance_valid(pnode):
				pnode.visible = false
		if _vignette != null and is_instance_valid(_vignette):
			_vignette.visible = false


func _process(dt: float) -> void:
	_t += dt
	# Gated on the switch itself, not only on `set_process(false)`: another layer
	# (a held bubble, the boss) can turn processing back on, and reduced motion
	# has to survive that — for the pulses and the boss, and equally for the
	# light flicker, the line rotation and the bubble shuffle (STAGE-20).
	if not _motion_held:
		for p in _pulses:
			var pnode: ColorRect = p["node"]
			if not is_instance_valid(pnode):
				continue
			var swing: float = sin(_t * TAU / maxf(0.1, p["period"]) + p["phase"]) * p["swing"]
			pnode.color.a = p["base"] * (1.0 + swing)
		for b in _bobbers:
			var node: Node2D = b["node"]
			if not is_instance_valid(node):
				continue
			node.position.y = b["base_y"] + sin(_t * b["speed"] + b["phase"]) * b["amp"]
		for l in _lights:
			var node: PointLight2D = l["node"]
			if not is_instance_valid(node):
				continue
			# 11 §6: energy = base + noise. Two octaves so it breathes AND crackles.
			var n := _noise.get_noise_1d(_t * 2.0 + l["phase"]) * 0.7 \
				+ _noise.get_noise_1d(_t * 9.0 + l["phase"] * 3.0) * 0.3
			node.energy = l["base"] * (1.0 + n * l["flicker"])
		if _speech != null and _lines.size() > 1:
			_line_clock += dt
			if _line_clock >= _line_next:
				_line_clock = 0.0
				_line_next = _rng.randf_range(5.0, 9.0)
				_say(_lines[_rng.randi() % _lines.size()])
		if not _bubbles.is_empty():
			_bubble_clock += dt
			if _bubble_clock >= _bubble_next:
				_bubble_clock = 0.0
				_bubble_next = _rng.randf_range(2.5, 5.5)
				_shuffle_bubbles()
		# The travellers (W4-LIFE) — inside the gate: held means held.
		_tick_rotors(dt)
		_tick_walkers(dt)
		_tick_flyers(dt)
	# The verbs and the effects tick OUTSIDE the gate: their beats already
	# collapsed to their floors, and a held stage must still let a fumble's "!"
	# expire, a flash end and a held strike frame go.
	_tick_acts(dt)
	_tick_trails()
	_tick_fx()
	_tick_overlays()


## A few figures are talking at any moment, never all of them: pick a fresh
## subset of the AMBIENT bubbles each time so the room reads as alive rather
## than as decoration; a mood bubble is up exactly while its mood is on.
func _shuffle_bubbles() -> void:
	var idx: Array = []
	for i in _bubbles.size():
		_bubbles[i].visible = false
		if String(_bubble_moods[i]).is_empty():
			idx.append(i)
	for i in range(idx.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = idx[i]
		idx[i] = idx[j]
		idx[j] = tmp
	for i in mini(_bubble_visible, idx.size()):
		_bubbles[idx[i]].visible = true
	_apply_mood()


## Give the speaking bubble a screen's own lines (the party's, say); the
## JSON's lines are the fallback for a scene with nobody in it yet.
func set_lines(lines: Array) -> void:
	if lines.is_empty() or _speech == null:
		return
	_lines = lines.duplicate()
	_say(_lines[_rng.randi() % _lines.size()])


func _say(text: String) -> void:
	if _speech != null:
		_place_speech(text)
