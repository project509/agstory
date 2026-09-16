extends Node
## Autoload: the options, and only the options docs/13 §15.1 lists.
##
## That section is deliberately a closed list — *"The rule: if an option is not in
## this table, it does not exist in the settings screen."* — because the options
## were previously defined across six documents with no single inventory. This
## file is that inventory in code, and adding a key here without adding a row
## there is the same mistake in the other direction.
##
## WHERE IT LIVES: `user://settings.cfg`, a Godot `ConfigFile`, deliberately
## SEPARATE from `user://saves/`. docs/13 §15.1: "Options are a property of the
## installation, not of a guild: deleting every save, or a save migration
## failing, must never reset the player's text scale, language or controller
## glyphs." It is therefore not versioned with `save_version`.
##
## CORRUPTION IS NOT AN ERROR PATH. "a missing or unparseable file falls back to
## the defaults above and is rewritten, so a corrupt options file can never block
## boot." Nothing in here can refuse to load.
##
## FEATURE_* flags are NOT here. docs/13 §15.1 marks them "Build flag — never a
## player setting", and docs/14 §5.2 keeps them in `data/tuning/flags.json`.

const Enums = preload("res://sim/model/Enums.gd")

## A static var, not a const, for one reason: tests/run_tests.gd moves it before
## any test runs (the way it moves SaveGame.SAVE_DIR), so the suite's last
## `set_value` is never what PREDELETE writes into the developer's own file
## (LESSONS: the runner redirected saves but not settings). Nothing else
## assigns it.
static var PATH := "user://settings.cfg"
const SECTION := "options"

## docs/13 §15.1's table, defaults included. The keys are the file format, so
## renaming one is a migration; the table is the contract.
const DEFAULTS := {
    "sim_speed": 0,                 # 0=1x 1=2x 2=4x 3=Instant (docs/01 §9, 07 §3.1)
    "comedy_brake": true,           # docs/13 §11.2
    "log_manual_advance": false,    # docs/13 §13
    "emoji_free": false,            # docs/13 §13
    "prose_font_swap": false,       # docs/13 §13
    "text_scale": 100,              # docs/13 §4.4 — 100 / 125 / 150
    "reduced_motion": false,        # docs/13 §13
    "auto_loot": false,             # docs/09 §14.3 item 5
    "reduced_effects": false,       # docs/14 §11, docs/12
    "window_mode": "borderless",    # docs/13 §15.1 "Native, borderless": borderless | windowed (SHIP-06)
    "display_aspect": "keep",       # art/ref/specs/11 §1: keep (letterbox) | expand
    "resolution": "native",         # docs/14
    "vsync": true,                  # docs/14 — DisplayServer.window_set_vsync_mode (SHIP-06)
    # docs/13 §8.3's L*-ordered morale ramp behind a switch, OFF: the reference
    # concepts' red/amber/green is the shipped default by standing user rule and
    # §13 makes CVD safety blocking — the two authorities disagree in writing
    # (Palette.gd, docs/15 Q16 / M6-A11Y-06). Ship default per the wave-10 rule
    # (ship plan §6 #40): an option, default off. Read by Palette.cvd_safe().
    "colourblind_safe": false,
    "audio_master": 100,            # docs/13 §15.1 — 100 / 80 / 80 / 100
    "audio_music": 80,
    "audio_ui": 80,
    "audio_voice": 100,
    "language": "",                 # "" = OS locale, falling back to en-US
    "glyph_set": "auto",            # auto-detect from the connected pad
}

## docs/13 §4.4's three steps, and nothing between them.
const TEXT_SCALES := [100, 125, 150]

## docs/13 §15.1's audio buses, in the doc's own order.
const AUDIO_BUSES := ["audio_master", "audio_music", "audio_ui", "audio_voice"]

## docs/13 §15.1's window modes. `borderless` is fullscreen at the desktop's
## own size (Godot's WINDOW_MODE_FULLSCREEN is the borderless kind; the
## exclusive one changes the display mode and is not offered); `windowed` is a
## 3:2 window sized to fit the desktop it is on (`windowed_size`).
const WINDOW_MODES := ["borderless", "windowed"]

signal changed(key: String)

var _values: Dictionary = {}


func _ready() -> void:
    load_from_disk()


# ---------------------------------------------------------------- access

func get_value(key: String):
    if not DEFAULTS.has(key):
        push_error("GameSettings: '%s' is not in docs/13 §15.1's inventory" % key)
        return null
    return _values.get(key, DEFAULTS[key])


func set_value(key: String, value) -> bool:
    if not DEFAULTS.has(key):
        push_error("GameSettings: '%s' is not in docs/13 §15.1's inventory" % key)
        return false
    var coerced = _coerce(key, value)
    if coerced == null:
        return false
    if _values.get(key, DEFAULTS[key]) == coerced:
        return true
    _values[key] = coerced
    changed.emit(key)
    return true


func is_default(key: String) -> bool:
    return DEFAULTS.has(key) and get_value(key) == DEFAULTS[key]


func reset_all() -> void:
    _values = DEFAULTS.duplicate(true)
    changed.emit("")


## Keep a stored value inside its documented range rather than trusting the file.
## An out-of-range text scale would otherwise make every screen unreadable, and
## the file is user-editable by construction.
func _coerce(key: String, value):
    var want = DEFAULTS[key]
    match key:
        "sim_speed":
            return clampi(int(value), 0, 3)
        "text_scale":
            var n := int(value)
            return n if n in TEXT_SCALES else int(DEFAULTS[key])
        "audio_master", "audio_music", "audio_ui", "audio_voice":
            return clampi(int(value), 0, 100)
        "display_aspect":
            return String(value) if String(value) in ["keep", "expand"] else String(DEFAULTS[key])
        "window_mode":
            return String(value) if String(value) in WINDOW_MODES else String(DEFAULTS[key])
    match typeof(want):
        TYPE_BOOL:
            return bool(value)
        TYPE_INT:
            return int(value)
        TYPE_STRING:
            return String(value)
    return value


# ---------------------------------------------------------------- persistence

## Never raises, never blocks boot. A missing or unparseable file yields the
## defaults and is rewritten (docs/13 §15.1).
func load_from_disk() -> bool:
    _values = DEFAULTS.duplicate(true)
    var cfg := ConfigFile.new()
    var err := cfg.load(PATH)
    if err != OK:
        # Not an error worth reporting: a first run has no file.
        save_to_disk()
        return false
    var recovered := 0
    for key in DEFAULTS:
        if cfg.has_section_key(SECTION, key):
            var coerced = _coerce(key, cfg.get_value(SECTION, key))
            if coerced != null:
                _values[key] = coerced
                recovered += 1
    if recovered == 0:
        # Parsed, but carried nothing we recognise — treat as corrupt and rewrite.
        save_to_disk()
        return false
    changed.emit("")
    return true


## docs/13 §15.1: "Written on Apply and on quit, never on every keystroke."
func save_to_disk() -> bool:
    var cfg := ConfigFile.new()
    for key in DEFAULTS:
        cfg.set_value(SECTION, key, get_value(key))
    return cfg.save(PATH) == OK


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
        save_to_disk()


# ---------------------------------------------------------------- derived rules

## docs/01 §9, which is that doc's OQ#1 ruling and therefore governs:
##
##   "1x/2x/4x + pause always available; Instant / skip-to-result unlocked per
##    encounter after first clear of that encounter"
##
## Rationale, quoted: "gating skip behind a first clear means the player always
## watches the content that is new (where the comedy and the learning are) and
## can fast-forward content that is now farming."
##
## `state` is the GameState autoload, or null outside a game.
static func skip_unlocked(state, encounter_id: String) -> bool:
    if state == null or encounter_id.is_empty():
        return false
    return state.has_cleared(encounter_id)


## docs/01 §9: the stored speed is global and persisted, but "reset to 1x for any
## mission never cleared". The stored value is untouched — this is the speed the
## raid view should OPEN at, which is why it is a query and not a mutation.
func effective_sim_speed(state, encounter_id: String) -> int:
    var stored := int(get_value("sim_speed"))
    if skip_unlocked(state, encounter_id):
        return stored
    return mini(stored, 2)      # 1x / 2x / 4x are always available; Instant is not


## docs/13 §13: emoji-free mode "Replaces morale glyphs with a 10-step monochrome
## pip figure. The integer and state word are unaffected."
func morale_glyph(morale: int) -> String:
    if not bool(get_value("emoji_free")):
        return Enums.MORALE_BAND_EMOJI[Enums.morale_band(morale)]
    var band := Enums.morale_band(morale)
    return "|".repeat(band + 1) + ".".repeat(Enums.MORALE_BAND_COUNT - band - 1)


## docs/13 §4.4's text scale, as a multiplier for a base font size.
func scaled(size: int) -> int:
    return int(round(float(size) * float(get_value("text_scale")) / 100.0))


# ------------------------------------------------- docs/13 §13: reduced motion

## docs/13 §13's reduced-motion row disables "doc 12's post-processing motion
## (bloom pulse, depth-of-field shifts, ambient drift, parallax), the page turn,
## the ledger close, and the wipe sequence's bleed" — and then carves out the one
## exception that shapes this whole API: "Stamps still land (they carry state)
## but at 60ms with no rotation."
##
## So reduced motion is not "skip the animation". It is "arrive instantly, and
## still arrive". A tween of duration 0.0 in Godot completes on the very next
## frame and applies its final value, which means a call site needs NO branch:
## ask for a duration, get 0.0, tween anyway, and the end state is reached. That
## is the difference between an accessibility setting and a code path nobody
## tests.
const MOTION_OFF := 0.0
const MOTION_ON := 1.0


## 0.0 when the player has asked for reduced motion, 1.0 otherwise.
func motion_scale() -> float:
    return MOTION_OFF if bool(get_value("reduced_motion")) else MOTION_ON


## docs/13 §12.2's motion table is written in MILLISECONDS; Godot's tweens take
## seconds. This converts and applies the setting in one place, so no call site
## does either arithmetic and none of them can forget the second half.
##
## `floor_ms` is §13's stamp exception: a duration that must survive reduced
## motion rather than collapsing, because the thing it animates carries state.
## `motion_duration(120, 60)` is the StampBadge row of §12.2 read together with
## §13's "at 60ms with no rotation" — 120ms normally, 60ms reduced, never zero.
## Everything else passes no floor and collapses to nothing, which is the point.
func motion_duration(ms: int, floor_ms: int = 0) -> float:
    var scaled_ms := float(maxi(0, ms)) * motion_scale()
    return maxf(scaled_ms, float(maxi(0, floor_ms))) / 1000.0


## docs/13 §13's reduced-flashing row, quoted whole: "No element exceeds 3
## changes per second. Nothing flashes at all." It is unconditional — docs/13
## §15.1 keeps it off the options list on purpose ("a build requirement with a QA
## gate, not a toggle the player can get wrong") — so it is a number in code and
## a test, never a setting.
const MAX_CHANGES_PER_SECOND := 3.0

## AND IT IS AMBIGUOUS ABOUT WHAT AN "ELEMENT" IS, which matters because the
## shipped hearth flames run at 9 fps and the townsfolk idles at 5. Two readings,
## and they disagree about whether the art already violates the doc:
##
##   false (shipped) — the row is a PHOTOSENSITIVE rule about the UI layer. Its
##     own section is the UI doc's, and §12.2 closes by saying "Nothing in the UI
##     loops, pulses, or breathes; ambient motion belongs to the world layer and
##     is doc 12's" — which puts the flames outside §12's scope entirely. A fire
##     cycling through near-identical frames is not something "changing" in the
##     sense a flashing rule means, and reading it otherwise bans every fire,
##     candle and breathing idle in the game.
##
##   true (the literal reading) — "no element" means no element, the world layer
##     included, and every strip must run at 3 fps or slower. Cheap to honour and
##     it would make the camp look like a slideshow.
##
## The shipped reading is the first. Both are under test in
## `tests/unit/test_motion.gd`, and the question is docs/15 BL-75. Reduced motion
## is the separate, player-facing setting and stops the world layer outright —
## `SceneStage.apply_settings()` — so a player who needs the flames still can
## turn them off whatever this rules.
const FLASH_RULE_COUNTS_WORLD_MOTION := false


## Whether docs/13 §13's three-per-second rule governs `layer`, which is "ui" or
## "world". A pure function of the switch above so the rule is asked, never
## re-derived at each call site.
static func flash_rule_applies_to(layer: String) -> bool:
    if layer == "world":
        return FLASH_RULE_COUNTS_WORLD_MOTION
    return true


## art/ref/specs/11 §1: the base viewport IS the reference frame (1536x1024).
## `keep` letterboxes it on wider displays — the concepts' composition exactly.
## `expand` widens the canvas instead; the scene plates keep their own width.
## Static so a screen can apply a fresh choice without a restart.
static func apply_display_aspect(window: Window, aspect: String) -> void:
    if window == null:
        return
    window.content_scale_aspect = (Window.CONTENT_SCALE_ASPECT_EXPAND
        if aspect == "expand" else Window.CONTENT_SCALE_ASPECT_KEEP)


# ------------------------------------------ SHIP-06: the window mode and V-sync

## The reference frame (project.godot's base viewport): what a windowed 3:2
## window wants to be when the desktop has room for it.
const BASE_WINDOW := Vector2i(1536, 1024)
## What the OS draws around a window — the title bar and borders — which the
## desktop's usable rect does not subtract. A fixed allowance rather than a
## measurement, because the measurement is taken on a fullscreen window (no
## decorations) at the moment the choice is applied.
const WINDOW_CHROME := Vector2i(16, 48)


## docs/13 §15.1's "Native, borderless" row, applied. Before this landed the
## game opened a 1536x1024 window whatever the desktop was, so on a 1366x768
## laptop the bottom 256px — every commit row — was off the screen (SHIP-06).
## `borderless` is fullscreen at the desktop's own size; `windowed` is a 3:2
## window that FITS the desktop (`windowed_size`), centred, with `canvas_items`
## stretch scaling the frame into it. V-sync is applied in the same breath so
## the two display keys have one door. Static, like `apply_display_aspect`, so
## Boot can apply the file's choice before a frame paints and the Options
## screen can apply a fresh one without a restart.
static func apply_window_mode(window: Window, mode: String, vsync: bool) -> void:
    if window == null:
        return
    var id: int = window.get_window_id()
    DisplayServer.window_set_vsync_mode(
        DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED, id)
    if mode == "windowed":
        var usable: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
        window.mode = Window.MODE_WINDOWED
        window.size = windowed_size(usable.size)
        window.move_to_center()
    else:
        window.mode = Window.MODE_FULLSCREEN


## The largest 3:2 window, no wider than the reference frame, that fits inside
## a desktop's usable area once the OS's chrome is allowed for. A pure
## function so the arithmetic is testable without a display: on a 1366x768
## desktop with a taskbar (usable 1366x728) it is 1020x680, not 1536x1024.
static func windowed_size(usable: Vector2i) -> Vector2i:
    var room := usable - WINDOW_CHROME
    if room.x <= 0 or room.y <= 0:
        return BASE_WINDOW
    var w: int = mini(BASE_WINDOW.x, room.x)
    var h: int = w * BASE_WINDOW.y / BASE_WINDOW.x
    if h > room.y:
        h = room.y
        w = h * BASE_WINDOW.x / BASE_WINDOW.y
    return Vector2i(w, h)
