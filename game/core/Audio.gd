extends Node
## Autoload: the mixer, the eleven named hooks, the five ambience beds, and nothing else.
##
## docs/13 §12.4 hands doc 14 a list of ELEVEN hook names and says "Names for
## 14 to bind; mixing is audio's call." This file is that binding. The names
## are the contract: a screen says `play("ui.stamp")` and never learns what a
## bus, a stream or a pitch is.
##
## AN UNKNOWN NAME IS AN ERROR, not a silent no-op. Same discipline as
## `GameSettings.get_value` — the failure mode this project keeps hitting is a
## subsystem that quietly does nothing and reads as a content bug. A hook with
## an EMPTY stream list is a legal no-op, so a hook can be bound by name before
## its sample lands (every one of the eleven has its sample and its trigger
## site since W6-AUD-BIND; tools/audio/README.md maps them).
##
## FOUR BUSES, from docs/13 §15.1: master / music / UI / voice-of-the-scribe.
## `default_bus_layout.tres` is the topology; `user://settings.cfg` is the
## level; `apply_levels()` is the only thing that joins them. Before this file
## existed the Settings screen showed the volume rows DISABLED, carrying the
## reason "There is no audio yet." — which is all docs/13 asks of a disabled
## control (§12.3: "a reason string adjacent. A disabled control that does not
## say why is a dead end"; §7's WaxButton row: "reason text beneath — never a
## mystery"). This file is what lets those rows stop being disabled. The
## further judgement that an ENABLED row wired to nothing would be worse than a
## disabled one is game/screens/Settings.gd's own sentence, not a doc's — no
## section of docs/13 says it, and it must not be quoted as though one did.
##
## AMBIENCE, ONE DOOR. `play_bed(scene)` crossfades the Music bus onto the bed
## `BEDS` maps that scene to — five generated loops (tools/audio/gen_amb.py),
## keyed by the stage's own name, so the one call in `SceneStage.load()` is
## the whole binding and no screen learns about audio (Q-98 (ii), BL-138).
## MUSIC is not here: the generated lute docs/02 §9.1 asked for is W10-BUFFER's
## `BEDS_MUSIC` (Q-98 (i)); the leitmotif, bell and cheer are post-1.0.
##
## HEADLESS. `--headless` runs Godot's dummy audio driver. Everything here must
## therefore survive having no output device: nodes are created, `play()` is
## called, and nothing blocks or asserts on audible result. The test suite runs
## headless and a blocking audio call would take all 1100+ tests down with it.
##
## Reached with `Services.find(self, "Audio")`, never by the global identifier
## (BUILD_STATE invariant 7).

const Services = preload("res://game/core/Services.gd")
const GameSettings_ = preload("res://game/core/GameSettings.gd")

const SFX := "res://game/assets/audio/sfx/"

## docs/13 §15.1's buses in the doc's own order. Index 0 is Master because
## `default_bus_layout.tres` says so, and `_ensure_buses()` keeps that true.
const BUSES := ["Master", "Music", "UI", "Voice"]

## `GameSettings.AUDIO_BUSES` -> bus name. Written out rather than derived by
## stripping "audio_" and capitalising, because that derivation gets "UI"
## wrong and a mixer key that silently misses its bus is invisible.
const BUS_FOR_KEY := {
    "audio_master": "Master",
    "audio_music": "Music",
    "audio_ui": "UI",
    "audio_voice": "Voice",
}

## docs/13 §12.4's table, in the doc's own row order.
##
## `streams` holds resource PATHS, not loaded streams: a `const` cannot hold a
## loaded resource without preloading eleven samples into every tool script
## that touches this file, and the paths are what the acceptance test needs to
## check anyway. `_streams` caches the loaded form at `_ready`.
##
## `pitch_jitter_semitones` is 0.0 everywhere except `ui.stamp`. §12.4
## specifies "±2 semitone random pitch" for the stamp AND ONLY THE STAMP;
## giving the others a jitter would be inventing a number (house rule: every
## number traces to a doc section).
##
## `ui.page_turn` and `ui.ledger_close` bind to their EVENTS (Depart, the Day
## Tick), not to the motions docs/13 §12.2 drew for them — the router has no
## transition and "never will" (ScreenRouter.gd:4-7, docs/13 §2 M5), and §13's
## reduced-motion row already contemplates the two events happening without
## their motion. The sound is the transition when the desk does not move; if
## the motion is ever built it syncs to the sound, not the other way (W6, the
## AUDIO-08 default, recorded in docs/15's audio row).
const HOOKS := {
    "ui.tab": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_tab.wav"],
    },
    "ui.row_select": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_row_select_1.wav", SFX + "ui_row_select_2.wav"],
    },
    "ui.chalk": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_chalk_1.wav", SFX + "ui_chalk_2.wav",
            SFX + "ui_chalk_3.wav"],
    },
    "ui.chalk_bad": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_chalk_bad.wav"],
    },
    "ui.stamp": {
        "bus": "UI", "pitch_jitter_semitones": 2.0,
        "streams": [SFX + "ui_stamp_1.wav", SFX + "ui_stamp_2.wav",
            SFX + "ui_stamp_3.wav"],
    },
    "ui.seal": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_seal.wav"],
    },
    "ui.coin": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_coin_1.wav", SFX + "ui_coin_2.wav"],
    },
    "ui.page_turn": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_page_turn.wav"],
    },
    "ui.ledger_close": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_ledger_close.wav"],
    },
    "ui.blot": {
        "bus": "UI", "pitch_jitter_semitones": 0.0,
        "streams": [SFX + "ui_blot_1.wav", SFX + "ui_blot_2.wav"],
    },
    ## Not a sample. §12.4: "Ducks all buses to −60dB for 400ms." An empty
    ## stream list plus `duck` is the whole implementation, and `play()` on it
    ## performs the duck rather than playing nothing.
    "ui.silence": {
        "bus": "Master", "pitch_jitter_semitones": 0.0, "streams": [],
        "duck_db": -60.0, "duck_seconds": 0.4,
    },
}

## `ui.stamp` "fires dozens of times per raid" (§12.4), and during a wipe the
## stamp, the blot and the log's own hooks overlap. A ring of players per bus,
## allocated once, means a press never waits on an instantiation.
##
## NO DOC STATES A POOL SIZE, so 8 is a house number — but it is a derived one,
## and the arithmetic is asserted in
## `test_audio.gd :: test_a_full_lap_of_the_ring_touches_every_player_exactly_once`
## rather than left as a figure nobody can check. docs/13 §12.2 arrives a log
## line every 90 ms; a mistake line fires TWO hooks (§12.4's blot goes "with the
## stamp"); the longest one-shot is 138 ms. So at most two lines can still be
## sounding when the third arrives — four players — and 8 is that with the
## overlap doubled. The ring matters because `_take()` reassigns `stream` on
## whatever player it lands on, and doing that to a sounding player is a hard
## cut: the 6 ms fade the generator writes is at the END of the buffer, not at
## a stop.
const POOL_PER_BUS := 8

## The ambience beds (Q-98 (ii), BL-138), rendered by tools/audio/gen_amb.py.
const AMB := "res://game/assets/audio/amb/"

## Scene name (game/assets/scenes/<name>.json) -> bed id. Every scene has a
## row, so the door in `SceneStage.load()` passes the scene name and nothing
## else. `stage_town` plays the CAMP bed by design (BL-138): the main menu's
## aerial is the guild's own camp from above, and the guild's fire is the
## right first sound for "you are the guild leader" — a town-aerial bed is
## post-1.0. The dungeon has its own bed; `amb_cave` is its shed-fallback and
## the camp never is (a campfire under Raid 1's reveal would tell the ear the
## plate lied).
const BEDS := {
    "stage_camp": "amb_camp",
    "stage_town": "amb_camp",
    "stage_tavern": "amb_tavern",
    "stage_market": "amb_market",
    "stage_arena_cave": "amb_cave",
    "stage_arena_dungeon": "amb_dungeon",
}

## The five files the generator renders; `BEDS`' values are drawn from here
## and `play_bed` also accepts one of these directly.
const BED_IDS := ["amb_camp", "amb_tavern", "amb_market", "amb_cave", "amb_dungeon"]

## The equal-power crossfade between two beds, and `stop_bed()`'s fade-out.
## 600 ms is the fold gen_amb.py uses at the loop point: the same seam length
## on disk and in the mixer. Stepped in `_process` beside the §12.4 duck — no
## Tween, so `lint_motion.sh` has nothing to say (a fade is not motion, and
## reduced motion does not touch it: AUDIO-11's rule, sound is not motion).
const BED_FADE_SECONDS := 0.6

## Two dedicated players on the Music bus: the bed arriving and the one it is
## fading from. NOT the pool: `_take()` reassigns streams around a ring, and
## a bed is the one stream that must never be reassigned under a listener.
const BED_PLAYERS := 2

## Off in the game, on in tests. A headless run has no output device, so the
## only way to assert that a hook fired is to record that it did. `bed_tape`
## is the beds' own record ({scene, bed} per `play_bed`), kept apart from the
## hook tape so a screen mount never changes a hook count a test asserts.
var debug_tape := false
var tape: Array = []
var bed_tape: Array = []

var _built := false
var _levels_applied := false
var _settings: Node = null
var _router: Node = null
var _state: Node = null
var _pool: Dictionary = {}          # bus name -> Array[AudioStreamPlayer]
var _next: Dictionary = {}          # bus name -> int, the ring cursor
var _streams: Dictionary = {}       # hook -> Array[AudioStream]
var _rr: Dictionary = {}            # hook -> int, round-robin cursor
var _duck_db := 0.0
var _duck_left := 0.0

## The bed in play (or arriving), "" for none; the player it is on; how much
## of the crossfade is left; the loaded loops, one per bed id, on first use.
var _bed_id := ""
var _bed_players: Array = []        # Array[AudioStreamPlayer], BED_PLAYERS long
var _bed_active := 0
var _bed_fade_left := 0.0
var _bed_streams: Dictionary = {}   # bed id -> AudioStream

## The boot rule (AUDIO-15): the first screen of a session is silent; every
## change the player causes sounds. `Boot.gd` routes to the main menu on the
## first frame, before the player has touched anything, and a sound the player
## did not cause is worse than a missing one (the coin's own rule). True until
## the first `screen_changed` this autoload hears; a test puts it back to true
## to replay the boot.
var _first_change := true

## The `ui.coin` watermark. `GameState.gold_changed` announces a value WRITE,
## and three of its four emit sites are not a gold CHANGE — see
## `_on_gold_changed`, which is where these five are read and written.
var _coin_seen := false
var _coin_gold := 0
var _coin_seed := 0
var _coin_day := 0
var _coin_head := 0


func _ready() -> void:
    ensure_wired()


## Idempotent boot. Called from `_ready` in the game and from every public
## entry point below, because an autoload's `_ready` DOES NOT RUN under
## `--script`: the test runner is itself the SceneTree, it owns the root and it
## quits inside `_initialize()` without ever flushing a frame, so the autoload
## nodes exist with none of their callbacks fired. GameState hit exactly this
## and solved it the same way (`_ensure_router_connected`, GameState.gd:383) —
## this is that pattern, not a new one.
##
## The two halves are separated on purpose. The pool, the buses and the streams
## have no dependencies and are built once. The GameSettings and ScreenRouter
## connections DO depend on other autoloads, whose order "is not guaranteed
## under --script" (GameState's own comment), so they are retried on every call
## until those nodes exist.
func ensure_wired() -> void:
    if not _built:
        _built = true
        # The duck's restore runs in `_process`. Nothing in this project pauses
        # the tree today, but a future pause menu must not freeze a -60 dB duck
        # on Master — so the autoload runs always, as its players already do.
        process_mode = Node.PROCESS_MODE_ALWAYS
        _ensure_buses()
        _build_pool()
        _build_bed_players()
        _load_streams()
        set_process(false)
    _connect_settings()
    _connect_router()
    _connect_state()
    if _settings != null and not _levels_applied:
        # docs/13 §15.1's levels are read HERE and never in `_init`: Audio is
        # the fourth autoload and GameSettings the third, so in `_init` the
        # settings node does not exist yet. The audit's risk note for
        # M6-AUD-01 calls out this exact ordering trap.
        _levels_applied = true
        apply_levels()


func _connect_settings() -> void:
    if _settings == null:
        _settings = Services.find(self, "GameSettings")
    if _settings != null and not _settings.changed.is_connected(_on_setting_changed):
        _settings.changed.connect(_on_setting_changed)


## docs/13 §12.4: `ui.tab` is "Tab / screen change". Subscribing to the router
## means no screen has to learn about audio to get its own transition sound —
## every screen already goes through the router to get on the desk.
func _connect_router() -> void:
    if _router == null:
        _router = Services.router(self)
    if _router != null and not _router.screen_changed.is_connected(_on_screen_changed):
        _router.screen_changed.connect(_on_screen_changed)


## docs/13 §12.4: `ui.coin` fires when "Gold changes", "On the value write".
##
## The audit (M6-AUD-04 item f) said to "emit a `gold_changed` signal from
## GameState and let Audio subscribe". Half of that was already done —
## GameState.gd:68 has declared `signal gold_changed(amount: int)` all along.
## But subscribing is NOT the whole binding: the signal fires from FOUR places
## and only two of them are a gold change (see `_on_gold_changed`).
##
## `roster_changed` is subscribed for the same reason and nothing else: it keeps
## the coin's watermark current so a hire or a departure does not cost the next
## real gold change its chime.
##
## `day_advanced` is docs/13 §12.4's "Day advance" — `ui.ledger_close`, "start
## of the close". `GameState.advance_day()` is the one Day Tick (an attempt or
## a rest), so subscribing here binds every caller at once and no screen learns
## about audio.
func _connect_state() -> void:
    if _state == null:
        _state = Services.state(self)
    if _state == null:
        return
    if not _state.gold_changed.is_connected(_on_gold_changed):
        _state.gold_changed.connect(_on_gold_changed)
    if not _state.roster_changed.is_connected(_on_roster_changed):
        _state.roster_changed.connect(_on_roster_changed)
    if not _state.day_advanced.is_connected(_on_day_advanced):
        _state.day_advanced.connect(_on_day_advanced)


# ---------------------------------------------------------------- the mixer

## The layout in `default_bus_layout.tres` is the source of truth, but a
## stripped export or a driver that declined to load it would leave every
## `play()` pointing at bus -1 and silently route to Master. Recreating what is
## missing is cheaper than debugging that.
func _ensure_buses() -> void:
    for i in BUSES.size():
        var want: String = BUSES[i]
        if AudioServer.get_bus_index(want) >= 0:
            continue
        AudioServer.add_bus()
        var at := AudioServer.bus_count - 1
        AudioServer.set_bus_name(at, want)
        if i > 0:
            AudioServer.set_bus_send(at, BUSES[0])


## docs/13 §15.1's four levels, as bus volumes. 0 mutes rather than setting
## `linear_to_db(0.0)`, which is -inf and which Godot clamps to -80 dB — audible
## on a loud system, and "0" in the options menu has to mean silent.
func apply_levels() -> void:
    ensure_wired()
    for key in BUS_FOR_KEY:
        _apply_key(String(key))


func _apply_key(key: String) -> void:
    var name_of: String = String(BUS_FOR_KEY[key])
    var idx := AudioServer.get_bus_index(name_of)
    if idx < 0:
        push_error("Audio: bus '%s' is missing; check default_bus_layout.tres" % name_of)
        return
    var pct: int = 100
    if _settings != null:
        pct = int(_settings.get_value(key))
    AudioServer.set_bus_mute(idx, pct <= 0)
    if pct <= 0:
        return
    var db := linear_to_db(float(pct) / 100.0)
    if name_of == BUSES[0]:
        db += _duck_db          # §12.4's ui.silence rides on top of the setting
    AudioServer.set_bus_volume_db(idx, db)


## The level a bus is currently asked to sit at, in dB. Exposed because the
## acceptance test needs to compare against the mixer without reaching into it.
##
## A refusal returns NAN, not 0.0. 0.0 dB is UNITY — a real, common, correct
## answer for a bus at 100% — so returning it for a key that has no bus made
## the refusal indistinguishable from success, and a test written against it
## could not tell the two apart (it passed with the guard deleted). NAN is the
## only float here that cannot be mistaken for a level.
func level_db(key: String) -> float:
    ensure_wired()
    if not BUS_FOR_KEY.has(key):
        push_error("Audio: '%s' is not one of docs/13 §15.1's four bus keys" % key)
        return NAN
    var idx := AudioServer.get_bus_index(String(BUS_FOR_KEY[key]))
    if idx < 0:
        push_error("Audio: bus '%s' is missing; check default_bus_layout.tres"
            % String(BUS_FOR_KEY[key]))
        return NAN
    return AudioServer.get_bus_volume_db(idx)


func _on_setting_changed(key: String) -> void:
    # An empty key means "all of them" (GameSettings.reset_all, load_from_disk).
    if key.is_empty():
        apply_levels()
    elif BUS_FOR_KEY.has(key):
        _apply_key(key)


# ---------------------------------------------------------------- §12.4 duck

## docs/13 §12.4's `ui.silence`: "Ducks all buses to −60dB for 400ms." Ducking
## MASTER ducks all of them, which is what the four-bus topology is for.
##
## The restore runs on `_process` rather than a `SceneTree` timer so that
## nothing here allocates a node per wipe and nothing survives the autoload;
## `set_process` is left off when neither a duck nor a bed fade is in flight.
func duck(db: float, seconds: float) -> void:
    ensure_wired()
    if seconds <= 0.0:
        _unduck()
        return
    _duck_db = minf(db, 0.0)
    _duck_left = seconds
    _apply_key("audio_master")
    set_process(true)


## One clock for the two things this file steps by time: the §12.4 duck's
## restore and the beds' crossfade. Each runs down on its own; the process
## callback stays on until both are idle.
func _process(delta: float) -> void:
    if _duck_left > 0.0:
        _duck_left -= delta
        if _duck_left <= 0.0:
            _unduck()
    if _bed_fade_left > 0.0:
        _bed_fade_left -= delta
        _apply_bed_fade()
    if _duck_left <= 0.0 and _bed_fade_left <= 0.0:
        set_process(false)


func _unduck() -> void:
    _duck_db = 0.0
    _duck_left = 0.0
    _apply_key("audio_master")


## Test seam: advance the duck's clock without running frames. `run_tests.gd` is
## a `SceneTree` script that never draws a frame, so `_process` never fires
## there and the restore would otherwise be unobservable.
func advance_duck(seconds: float) -> void:
    if _duck_left <= 0.0:
        return
    _duck_left -= seconds
    if _duck_left <= 0.0:
        _unduck()


func is_ducked() -> bool:
    return _duck_left > 0.0


# ---------------------------------------------------------------- the hooks

## Play one of docs/13 §12.4's eleven hooks.
##
## `opts` accepts `volume_db` (a per-call trim), `pitch_scale` (overriding the
## jitter, for a caller that needs a deterministic pitch) and `live` — the
## Instant/skip gate. docs/13 §11.2 gives Instant "no reveal", and a skip lands
## every remaining line in one frame; a per-line hook fired then is a wall of
## stamps, so a call site that reveals lines passes `{"live": _live}` and this
## gate drops the press when it is false. The gate lives HERE, not at the
## sites, so each site stays one line and the rule has one door. The wipe's
## own beats (silence, stamp, seal) pass no `live` and fire once at the end.
##
## What does NOT gate a hook, by the same ruling (AUDIO-11's defaults): the
## reduced-motion setting — sound is not motion, and docs/13 §13's own row
## keeps the stamps landing under it; reduced effects; the comedy brake, which
## changes pacing, and pacing is what the hooks follow. Nothing here reads a
## setting but the four levels.
func play(hook: String, opts: Dictionary = {}) -> void:
    ensure_wired()
    if not HOOKS.has(hook):
        # Never a silent no-op: docs/13 §12.4 is a closed list of eleven names,
        # and a typo'd hook must fail where it is written, not at mix time.
        push_error("Audio: '%s' is not one of docs/13 §12.4's eleven hooks" % hook)
        return
    if opts.has("live") and not bool(opts["live"]):
        return
    var spec: Dictionary = HOOKS[hook]
    if debug_tape:
        tape.append({"hook": hook, "msec": Time.get_ticks_msec()})
    if spec.has("duck_db"):
        duck(float(spec["duck_db"]), float(spec["duck_seconds"]))
        return
    var streams: Array = _streams.get(hook, [])
    if streams.is_empty():
        # Legal: the hook is bound by name and its sample (or its animation)
        # has not landed. Bound-but-silent beats unbound-and-crashing.
        return
    var player: AudioStreamPlayer = _take(String(spec["bus"]))
    if player == null:
        return
    var at: int = int(_rr.get(hook, 0))
    _rr[hook] = (at + 1) % streams.size()
    player.stream = streams[at]
    player.volume_db = float(opts.get("volume_db", 0.0))
    player.pitch_scale = float(opts.get("pitch_scale",
        _jitter(float(spec["pitch_jitter_semitones"]))))
    # `AudioStreamPlayer.play()` refuses outside the tree ("Playback can only
    # happen when a node is inside the scene tree"). Under `--script` the
    # runner owns the root, so this autoload's children are NOT inside a tree
    # (the same trap Services.gd documents) and every call would log an engine
    # error. The stream and the pitch are still set, so a test can see what
    # would have played; only the driver call is skipped.
    if not player.is_inside_tree():
        return
    player.play()


## §12.4's "±2 semitone random pitch". `randf_range` is fine here and nowhere
## near `sim/`: BUILD_STATE invariant 6 makes the SIM deterministic, and audio
## is presentation. A seeded Rng here would make every stamp in a replay
## identical, which is the fatigue the doc is warning about.
func _jitter(semitones: float) -> float:
    if semitones <= 0.0:
        return 1.0
    return pow(2.0, randf_range(-semitones, semitones) / 12.0)


func _take(bus: String) -> AudioStreamPlayer:
    var ring: Array = _pool.get(bus, [])
    if ring.is_empty():
        return null
    var at: int = int(_next.get(bus, 0))
    _next[bus] = (at + 1) % ring.size()
    return ring[at]


func _build_pool() -> void:
    for bus in BUSES:
        var ring: Array = []
        for _i in POOL_PER_BUS:
            var p := AudioStreamPlayer.new()
            p.bus = String(bus)
            # A UI one-shot must never be held up by the world layer.
            p.process_mode = Node.PROCESS_MODE_ALWAYS
            add_child(p)
            ring.append(p)
        _pool[String(bus)] = ring
        _next[String(bus)] = 0


## Loaded once at boot, not per press. A missing file is reported and then
## dropped: audio is not allowed to be the reason the game will not start.
func _load_streams() -> void:
    for hook in HOOKS:
        var paths: Array = HOOKS[hook]["streams"]
        var loaded: Array = []
        for path in paths:
            var p := String(path)
            if not ResourceLoader.exists(p):
                push_error("Audio: '%s' names a missing sample: %s" % [hook, p])
                continue
            var stream = load(p)
            if stream is AudioStream:
                loaded.append(stream)
        _streams[String(hook)] = loaded
        _rr[String(hook)] = 0


## The loaded streams for a hook, for tests and for a tool that wants to
## inspect the mix without playing it.
func streams_for(hook: String) -> Array:
    ensure_wired()
    return _streams.get(hook, [])


# ---------------------------------------------------------------- §12.4 binds

func _on_screen_changed(_path: String) -> void:
    # The boot transition is the one screen change the player did not cause
    # (`Boot.gd` -> main menu on the first frame). Continue / Load / every
    # later goto is a press, and sounds.
    if _first_change:
        _first_change = false
        return
    play("ui.tab")


## docs/13 §12.4: `ui.ledger_close` — "Day advance", "start of the close".
func _on_day_advanced(_day: int) -> void:
    play("ui.ledger_close")


## docs/13 §12.4: `ui.coin` — trigger "Gold changes", sync "On the value write".
##
## A GOLD SIGNAL IS NOT A GOLD CHANGE. GameState emits `gold_changed(amount)`
## from four places and only two of them are a change: `add_gold`
## (GameState.gd:609) and `spend_gold` (:618). The other two announce that a
## whole campaign has appeared — `new_game` (:532) and `from_dict` (:2376),
## the save-restore path, both of which emit so the gold labels redraw. A
## restore is not a transaction, and ringing a coin over the load screen is a
## sound the player did not cause. `add_gold(0)` is a write with no change and
## must be silent too.
##
## The payload is only the new total, so the emitting site cannot be read off
## the signal — which is why this used to be a heuristic. It is not any more:
## `GameState.announcing` (AUDIO-10, W7-SAVE) is true for the whole of
## `new_game()` and `from_dict()` and false everywhere else, so the state SAYS
## which of the four emits this is and the coin believes it.
##
## The watermark is still recorded on every write, and the heuristic behind it
## still stands as the second line: the coin rings only when the total moved AND
## the campaign under it is the one Audio last heard from — same guild seed, same
## object at the head of the roster, the day not run backwards. Both arrival
## sites call `reset()` (:499) first and rebuild the roster from scratch, so both
## fail that test too; neither `add_gold` nor `spend_gold` touches the seed, the
## day or the roster, so neither ever does. A reward one frame after a campaign
## arrives still rings, because the flag is false by then.
func _on_gold_changed(amount: int) -> void:
    var seed_now: int = 0
    var day_now: int = 0
    var arriving: bool = false
    if _state != null:
        seed_now = int(_state.guild_seed)
        day_now = int(_state.day)
        arriving = bool(_state.announcing)
    var moved: bool = _coin_note(amount, seed_now, day_now, _roster_head())
    if moved and not arriving:
        play("ui.coin")


## True when a gold write is a gold CHANGE within the campaign already being
## listened to; records the watermark either way. Split out from the handler so
## a headless test can walk a campaign's arrival, a reward, a no-op write and a
## restore without needing a content database to make a real roster from.
func _coin_note(amount: int, seed_value: int, day_value: int, head: int) -> bool:
    var same_campaign: bool = (_coin_seen and seed_value == _coin_seed
        and head == _coin_head and day_value >= _coin_day)
    var moved: bool = amount != _coin_gold
    _coin_seen = true
    _coin_gold = amount
    _coin_seed = seed_value
    _coin_day = day_value
    _coin_head = head
    return same_campaign and moved


## The identity of the roster's first entry, or 0 for an empty roster. An
## OBJECT id and not a name: `reset()` empties the roster and both campaign
## arrivals rebuild it, so a restored roster is never the same objects even when
## it holds the same twelve people.
func _roster_head() -> int:
    if _state == null:
        return 0
    var roster: Array = _state.roster
    if roster.is_empty():
        return 0
    var first: Object = roster[0] as Object
    return int(first.get_instance_id()) if first != null else 0


func _on_roster_changed() -> void:
    # A hire or a departure can replace the head of the roster without touching
    # gold. Refreshing here is what stops the NEXT real gold change from
    # looking like a campaign arrival. Both arrival sites emit `gold_changed`
    # before `roster_changed`, so this never masks one of them.
    _coin_head = _roster_head()


# ---------------------------------------------------------------- the beds

## The ambience door (Q-98 (ii), BL-138 — M6-AUD-05's generable half).
##
## `name` is a SCENE name (`BEDS`' keys — what `SceneStage.load()` has in its
## hand) or one of the five bed ids directly. The same bed asked for twice is
## left where it is: Town, the Board, the Guildhall and the Completion all
## stand on `stage_camp`, and the fire must not restart at every door. A
## different bed crossfades in over `BED_FADE_SECONDS`, equal-power, on the
## other of the two dedicated Music-bus players; a third request mid-fade
## settles the fade first (the loser stops, the winner lands at 0 dB) and
## starts the next one — fast navigation never leaves two loops up.
##
## The melodic beds docs/02 §9.1 proposed are NOT reachable through here:
## `BEDS` names ambience only, and `test_audio_beds.gd` pins that. An unknown
## name is an error, the way an unknown hook is — a scene added without a row
## must fail where it is written.
func play_bed(name: String) -> void:
    ensure_wired()
    if name.is_empty():
        return
    var bed := name
    if BEDS.has(name):
        bed = String(BEDS[name])
    if not (bed in BED_IDS):
        push_error("Audio: '%s' is not a scene in Audio.BEDS nor one of its beds" % name)
        return
    if debug_tape:
        bed_tape.append({"scene": name, "bed": bed})
    if bed == _bed_id:
        return
    _settle_bed_fade()
    var stream: AudioStream = _bed_stream(bed)
    if stream == null:
        return
    _bed_id = bed
    _bed_active = (_bed_active + 1) % BED_PLAYERS
    var incoming: AudioStreamPlayer = _bed_players[_bed_active]
    incoming.stream = stream
    incoming.volume_db = _gain_db(0.0)
    _bed_fade_left = BED_FADE_SECONDS
    _apply_bed_fade()
    # The same off-tree rule as `play()`: under `--script` the players are not
    # in a tree and `play()` would log an engine error. The stream is set, so
    # a test can see what would be playing; only the driver call is skipped.
    if incoming.is_inside_tree():
        incoming.play()
    set_process(true)


## Fade the bed out over `BED_FADE_SECONDS` and release its player. Nothing
## calls this on a screen change — the next scene's bed replaces the last —
## but a caller with no scene (an ending, a return to a silent menu) has it.
func stop_bed() -> void:
    ensure_wired()
    if _bed_id.is_empty():
        return
    _settle_bed_fade()
    _bed_id = ""
    _bed_active = (_bed_active + 1) % BED_PLAYERS
    _bed_fade_left = BED_FADE_SECONDS
    _apply_bed_fade()
    set_process(true)


## The bed in play (or arriving); "" when the Music bus carries no bed.
func bed_playing() -> String:
    return _bed_id


## The bed id a scene maps to, or "" — for a test or a tool reading the table
## the way the door does.
func bed_for(scene: String) -> String:
    return String(BEDS.get(scene, ""))


static func bed_path(bed: String) -> String:
    return AMB + bed + ".wav"


## What the two bed players hold, for a headless test: the bed id, whether a
## fade is in flight, and the resource path on the arriving and the departing
## player ("" when empty).
func bed_state() -> Dictionary:
    ensure_wired()
    var incoming: AudioStreamPlayer = _bed_players[_bed_active]
    var outgoing: AudioStreamPlayer = _bed_players[(_bed_active + 1) % BED_PLAYERS]
    return {
        "bed": _bed_id,
        "fading": _bed_fade_left > 0.0,
        "active": incoming.stream.resource_path if incoming.stream != null else "",
        "outgoing": outgoing.stream.resource_path if outgoing.stream != null else "",
        "active_db": incoming.volume_db,
        "outgoing_db": outgoing.volume_db,
    }


## Test seam, the twin of `advance_duck`: run the crossfade's clock forward
## without frames. `run_tests.gd` never draws one.
func advance_bed(seconds: float) -> void:
    if _bed_fade_left <= 0.0:
        return
    _bed_fade_left -= seconds
    _apply_bed_fade()


func _build_bed_players() -> void:
    for i in BED_PLAYERS:
        var p := AudioStreamPlayer.new()
        p.name = "Bed_%d" % i
        p.bus = BUSES[1]                      # Music — Q-98 (ii)
        p.process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(p)
        _bed_players.append(p)


## Loaded on first use and held: five loops, ~450 kB each imported, and a
## scene change is the only caller. A missing file is reported and the bed
## request dropped — audio is not allowed to be the reason a screen will not
## mount.
func _bed_stream(bed: String) -> AudioStream:
    if _bed_streams.has(bed):
        return _bed_streams[bed]
    var path := bed_path(bed)
    if not ResourceLoader.exists(path):
        push_error("Audio: bed '%s' names a missing loop: %s" % [bed, path])
        return null
    var stream = load(path)
    if not (stream is AudioStream):
        push_error("Audio: bed '%s' did not load as an AudioStream: %s" % [bed, path])
        return null
    _bed_streams[bed] = stream
    return stream


## The equal-power law: the arriving player at sin, the departing at cos of
## the fade's progress, so the sum of powers stays flat across the seam — the
## same law gen_amb.py folds each loop's tail with. At the end the departing
## player is stopped and emptied; with no bed at all (after `stop_bed`) the
## arriving one is too.
func _apply_bed_fade() -> void:
    var t := 1.0 - clampf(_bed_fade_left / BED_FADE_SECONDS, 0.0, 1.0)
    var incoming: AudioStreamPlayer = _bed_players[_bed_active]
    var outgoing: AudioStreamPlayer = _bed_players[(_bed_active + 1) % BED_PLAYERS]
    incoming.volume_db = _gain_db(sin(t * PI * 0.5))
    outgoing.volume_db = _gain_db(cos(t * PI * 0.5))
    if _bed_fade_left <= 0.0:
        _bed_fade_left = 0.0
        outgoing.stop()
        outgoing.stream = null
        if _bed_id.is_empty():
            incoming.stop()
            incoming.stream = null


## Finish a fade in flight before starting another, so at most one loop is
## ever coming and one going.
func _settle_bed_fade() -> void:
    if _bed_fade_left <= 0.0:
        return
    _bed_fade_left = 0.0
    _apply_bed_fade()


## A linear gain as dB, floored at -80: `linear_to_db(0.0)` is -inf, and the
## floor is what the mixer already treats as silence.
static func _gain_db(gain: float) -> float:
    return linear_to_db(maxf(gain, 0.0001))
