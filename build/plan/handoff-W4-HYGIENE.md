# handoff-W4-HYGIENE — edits this unit needs in files it does not own

Unit: W4-HYGIENE (tests/unit/test_project_hygiene.gd, tests/unit/test_sidebar_fit.gd, tools/lint_motion.sh,
build/plan/audit.json, BUILD_STATE.md, docs/12-art-direction.md, art/ref/specs/00, art/ref/specs/06,
docs/_log/progress.md). Nothing below is applied by the unit. Shape: `## N. <path>:<line>` then an `old:`
fenced block and a `new:` fenced block, one edit per heading; `python tools/apply_handoff.py
build/plan/handoff-W4-HYGIENE.md --dry-run` parses it (checked). Line numbers are from the tree at the
wave-4 start (2026-09-15); match by the `old:` text. Indentation matches each file (GameSettings.gd,
run_tests.gd, playtest.gd, a11y_smoke.gd: four spaces; shot.gd: see §6).

Edits 1-4 close the two wave-1 leftovers the orchestrator routed here (report-W0-SHOT §"FOUND WHILE
PROVING R1", review-W0-SHOT F13, LESSONS.md:23): the unit-test stage of every `verify.sh` run rewrites the
developer's real `user://settings.cfg` with the last test's values, and the fixture-applying instruments
write real autosaves. `GameSettings.PATH` is a `const`, so the runner cannot move it the way it moves
`SaveGame.SAVE_DIR`; §1 makes it a `static var` (the `SaveGame.SAVE_DIR` precedent, SaveGame.gd:28), §2 has
the runner move it, §3/§4 give the playtest and the keyboard smoke the save redirect `shot.gd:343` and
`perf_probe.gd:232` already have. test_settings.gd is untouched: its `GameSettings.PATH` reads keep working
(a static var reads the same way as a const on the script), its :144 `remove_absolute` then deletes the
TEST copy, and its :153-154 rule (`begins_with("user://")`, not containing "save") is why the redirect is
`user://test_settings.cfg` and not something under `test_saves/`.

## 1. game/core/GameSettings.gd:25

old:
```
const PATH := "user://settings.cfg"
```

new:
```
## A static var, not a const, for one reason: tests/run_tests.gd moves it before
## any test runs (the way it moves SaveGame.SAVE_DIR), so the suite's last
## `set_value` is never what PREDELETE writes into the developer's own file
## (LESSONS: the runner redirected saves but not settings). Nothing else
## assigns it.
static var PATH := "user://settings.cfg"
```

## 2. tests/run_tests.gd:13

old:
```
    var SaveGame = load("res://game/core/SaveGame.gd")
    SaveGame.SAVE_DIR = "user://test_saves"
    SaveGame.purge_all()
```

new:
```
    var SaveGame = load("res://game/core/SaveGame.gd")
    SaveGame.SAVE_DIR = "user://test_saves"
    SaveGame.purge_all()
    # Same for the options file: GameSettings saves on PREDELETE, and the
    # autoload's PREDELETE is the runner's quit — so without this every
    # verify.sh run left the developer's settings.cfg holding whatever the last
    # test set (measured: text_scale 100, reduced_motion true). Not under
    # test_saves/: test_settings.gd pins that options never live with saves.
    var GameSettings = load("res://game/core/GameSettings.gd")
    GameSettings.PATH = "user://test_settings.cfg"
    DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
```

## 3. tools/playtest.gd:102

old:
```
    var db = ContentDB.load_all()
    if not db.is_valid():
        push_error("playtest: content failed validation — " + db.error_report())
```

new:
```
    # record_attempt autosaves (docs/14 §7.4): without this every verify.sh
    # run left "Playtest NNNNN" autosaves in the developer's own save dir
    # (report-W0-SHOT). The same redirect shot.gd and perf_probe.gd carry.
    var SaveGame = load("res://game/core/SaveGame.gd")
    SaveGame.SAVE_DIR = "user://playtest_saves"
    SaveGame.purge_all()

    var db = ContentDB.load_all()
    if not db.is_valid():
        push_error("playtest: content failed validation — " + db.error_report())
```

## 4. tests/unit/a11y_smoke.gd:79

old:
```
func _initialize() -> void:
    _queue = SCREENS.duplicate()
```

new:
```
func _initialize() -> void:
    # The fixture pass records a raid (`Fixture.apply(state, null, true)`), and
    # record_attempt autosaves — into the real save dir unless it is moved.
    var SaveGame = load("res://game/core/SaveGame.gd")
    SaveGame.SAVE_DIR = "user://a11y_saves"
    SaveGame.purge_all()
    _queue = SCREENS.duplicate()
```

## 5. game/assets/scenes/stage_town.json:23

Owner this wave: W4-LIFE (game/assets/scenes/**). The `note` array is an accreting log, and its third
paragraph still says the sky "still need[s] art that does not exist — a tileable cloud strip" two
paragraphs before the one that records the strips landing (W2-STAGE2, gen_clouds.py, clouds_far/near.png).
m4t-13's shape: a reader who stops at paragraph three redraws the clouds. If W4-LIFE has already rewritten
these lines (its sails and gulls land in this note), apply_handoff reports SKIP and this edit is moot.
After it lands, `test_project_hygiene.gd` should gain the row
`["res://game/assets/scenes/stage_town.json", "still need art that does not exist", "res://game/assets/vfx/clouds_far.png"]`
in LIES (W4-HYGIENE did not add it now because the phrase is still in the file and the row would be red
until this edit is applied).

old:
```
  "THE FIGURES ARE STILL ABSENT (see above), but the aerial is no longer inert: spec 09 §5",
  "row 4's water shimmer runs on the sea, the harbour and the river mouth. Rows 7 and 8",
  "(cloud drift, the airship) still need art that does not exist — a tileable cloud strip",
  "and 160x140px of sky patched behind a cut airship — and stay in M4B-VFX-01.",
```

new:
```
  "THE FIGURES ARE STILL ABSENT (see above), but the aerial is no longer inert: spec 09 §5",
  "row 4's water shimmer runs on the sea, the harbour and the river mouth, and row 7's cloud",
  "drift landed with W2-STAGE2 (next paragraph). Row 8 (the airship: 160x140px of sky patched",
  "behind a cut airship) and the windmill sails stay in M4B-VFX-01 until W4-LIFE.",
```

## 6. tools/shot.gd:1

The other wave-1 leftover: `tools/shot.gd` is the one tab-indented file under tools/ (389 tab-led lines,
0 space-led; every other tools/*.gd is four spaces — balance_sweep 525, gen_items 1045, parse_check 95,
perf_probe 199, playtest 175, fixture_reference 70, write_goldens 42). W0-SHOT left the decision to this
unit (report-W0-SHOT:83). Ruling: convert, so rule 5's "tools/*.gd use four spaces" is true without an
exception — the hazard is not Godot (a consistent file parses either way) but the next agent who edits by
the directory rule and makes it mixed. Purely mechanical: every leading tab becomes four spaces, nothing
else changes (the file has no non-leading tab, LF endings, UTF-8); generated from the tree by
scratchpad/write_handoff_W4-HYGIENE.py, so the `old:` block is the file as it stands and the edit is a
no-op if anyone else has touched the file (apply_handoff: SKIP, old text not found). Verify after
applying: `grep -c $'^\t' tools/shot.gd` prints 0 and `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh
"$GODOT" --headless --path . --script res://tools/parse_check.gd` prints PARSE_CHECK OK.

old:
```
extends SceneTree
## Screenshot harness: render a screen into an exact-size offscreen viewport,
## save it, quit. This is the verification instrument for the whole art pass —
## a shot it produces must be directly pixel-diffable against the 1536x1024
## reference concepts, so the captured size must NEVER depend on the desktop.
##
## Godot's --headless display server uses the dummy rasteriser, where
## get_image() returns null, so a real window is still required to exist. But we
## do not capture the window: the screen is mounted inside a SubViewport of
## exactly the reference size, which the OS cannot clamp. The visible window is
## irrelevant and may be any size the desktop allows.
##
##   godot --path . --script res://tools/shot.gd -- <res://screen.tscn> <out.png> [frames] [WxH]
##        [--fixture | --fixture=raid | --fixture=raid:clear] [--completed] [--set=key=value]
##        [--focus] [--tab=N] [--press=<Button.text>]... [--advance=N|all]
##        [--frames=A,B] [--hold-boot]
##
## --fixture seeds GameState with tools/fixture_reference.gd first, so the shot
## shows the same roster, gold and day as the reference concepts and refdiff
## measures design, not test data. `=raid` also records one attempt at the
## fixture's raid (a wipe); `=raid:clear` records one CLEAR of Adventure 0 by
## the party the game suggests, trying seeds from the fixture's SEED upward
## until one clears, and prints the seed it used (CRITIC-G12: the Results
## screen's loot hand-out had never been seen).
##
## --completed marks the campaign finished (docs/10 §13 row 1's beat). Three
## surfaces only exist in that state — S17 itself, the Adventure's Board's
## post-clear goal, and Records' re-read link — and without this flag none of
## them can be looked at, because tier 5 does not ship until it is named
## (docs/15 BL-69). It sets the same three fields the engine would.
##
## --set=key=value writes one of docs/13 §15.1's options before the screen is
## built, which is how an accessibility state gets LOOKED at rather than only
## asserted: `--set=emoji_free=true`, `--set=reduced_motion=true`,
## `--set=text_scale=150`. One flag for the whole inventory; GameSettings
## coerces the value and refuses an unknown key with its own error.
##
## Every shot starts from §15.1's DEFAULTS (`GameSettings.reset_all()`), never
## from user://settings.cfg: the autoload loads that file in `_ready()`, and a
## machine whose player had left `reduced_motion` on produced two identical
## --frames captures and a 150% main menu with nothing on the command line to
## say why. --set is the only way an option differs, so a shot is reproducible
## from its command line alone. The file is put back before the tool quits:
## quit() frees the autoloads, and GameSettings writes its values to
## user://settings.cfg on NOTIFICATION_PREDELETE (GameSettings.gd:159-161), so
## every exit here goes through `_quit()`, which `load_from_disk()`s first and
## the write that follows carries the player's own options — not the defaults,
## not the --set. (Before this was understood, one shot batch had wiped a 150%
## text scale on the developer's machine; review-W0-SHOT F12.)
##
## Saves go to `user://shot_saves` (purged first), the way tests/run_tests.gd
## redirects `SaveGame.SAVE_DIR`: `record_attempt` autosaves (docs/14 §7.4), so
## `--fixture=raid[:clear]` had been overwriting the player's real
## `user://saves/slot_0_auto_0.json` on every shot (seen 2026-09-14 08:38). A
## LoadSave shot therefore lists only what the shot itself saved.
##
## --focus does what the router does after on_enter() and this tool never did
## (RULES-13): `ScreenRouter.wire_shell_focus()` then grab_focus() on
## `ScreenRouter.initial_focus_target()`, so the §12.3 focus ring is in the
## picture. The grab is verified against the SubViewport's focus owner; if the
## engine refused it the tool says why and exits 8 rather than faking a ring.
## --tab=N then calls find_next_valid_focus() N times (implies --focus).
##
## --press=<text> finds a Button by its exact `.text` — the way the screen
## tests drive screens — and emits `pressed`, after on_enter(). Repeatable;
## pressed in the order given, two settle frames after each, so a tab surface
## ("Records", "Facilities", "Manage", "Buy", "Comfort") can be shot.
##
## --advance=N|all is for RaidView and Results (COMBAT q7): `all` calls the
## screen's `_on_skip()` when it has one (the wipe sequence plays to its last
## beat), else runs the screen's own `_process()` until its LogPlayer is
## finished; `N` runs `_process()` until N entries are revealed, then freezes
## the screen's `_process` so the count holds through the capture frames.
##
## --frames=A,B captures twice, at frame A and frame B after the screen has
## settled, to `<out minus .png>.a.png` and `.b.png` — a motion diff in two
## files (STAGE-14; M4B-VFX-01's own measurement). Replaces [frames].
##
## --hold-boot is for res://game/ui/Boot.tscn (CRITIC-G02): Boot's `_ready()`
## defers `_boot()`, which loads content and routes to the main menu; inside
## the SubViewport that deferred call cannot be intercepted, so this tool lets
## it run, then un-mounts whatever the router placed and re-shows the overlay.
## What is captured is the boot card over the empty host — the composition of
## the game's real first frame.
##
## WxH other than the project size honours the `display_aspect` option
## (CRITIC-G03): under `keep` the screen is mounted at 1536x1024 (scaled by
## min(W/1536, H/1024)) and centred on bars of the project's
## `rendering/environment/defaults/default_clear_color`; under `expand` the
## screen is handed the whole canvas at the same scale, so
## `MainMenu 1820x1024 --set=display_aspect=expand` is 1820 wide.
##
## Exit codes:
##    0 the PNG(s) were written ("SHOT OK <path> WxH" per file)
##    2 usage: too few positionals, an unknown --flag, a bad --tab/--advance/--frames value
##    3 no such scene / not a PackedScene
##    4 the viewport image is null (headless — a real display server is required)
##    5 save_png failed
##    6 the captured image is not WxH
##    7 a flag needs an autoload that is missing, or --set named an unsettable option
##    8 --focus/--tab could not take focus (reason printed)
##    9 --press found no Button with that exact text
##   10 --fixture=raid:clear found no clearing seed (fixture_reference.CLEAR_MAX_SEEDS)
##   11 --advance on a screen with no `_on_skip()` and no `_player` LogPlayer
##   12 --press found the Button but it is disabled (its reason is printed; a
##      player cannot press it, so the tool does not fake the press — the shot
##      would silently show the tab that was already up)

const DEFAULT_FRAMES := 30
## Frames left to the screen between one queued action and the next, so a press
## that rebuilds a tab has laid out before the next press or the capture count.
const SETTLE_FRAMES := 2
## Seconds fed to the screen's `_process()` per synthetic step under --advance:
## one 50 fps frame, so no reveal step is skipped over and N means N.
const ADVANCE_STEP := 0.02
const ADVANCE_MAX_STEPS := 200000
const Fixture = preload("res://tools/fixture_reference.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
## Where a fixture's autosave lands — never the player's `user://saves`.
const SHOT_SAVE_DIR := "user://shot_saves"

var _target := ""
var _out := ""
var _frames := DEFAULT_FRAMES
var _size := Vector2i(0, 0)
var _fixture := false
var _fixture_mode := ""
var _completed := false
var _settings: Dictionary = {}
var _focus := false
var _tabs := 0
var _presses: Array[String] = []
var _advance := ""
var _frame_a := 0
var _frame_b := 0
var _hold_boot := false
var _n := 0
var _vp: SubViewport = null
var _host: Control = null
var _inst: Node = null
var _built := false
var _queue: Array = []
var _settle := 0
var _focus_owner: Control = null
## Set by _usage(): quit() only REQUESTS a quit, and a _process() that still ran
## would call quit(3) over the usage code — the code W0-GATE's SKIPPED row reads.
var _dead := false


func _init() -> void:
	var args: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a == "--fixture":
			_fixture = true
		elif a == "--fixture=raid":
			_fixture = true
			_fixture_mode = "raid"
		elif a == "--fixture=raid:clear":
			_fixture = true
			_fixture_mode = "raid:clear"
		elif a == "--completed":
			_completed = true
		elif a.begins_with("--set="):
			# One flag for every option in docs/13 §15.1's inventory, rather than
			# a new flag each time an accessibility state needs looking at. The
			# value is coerced by GameSettings itself, so a typo in the key is
			# refused there with the doc's own error rather than silently doing
			# nothing here.
			var kv := a.substr(6).split("=")
			if kv.size() == 2:
				_settings[String(kv[0])] = String(kv[1])
		elif a == "--focus":
			_focus = true
		elif a.begins_with("--tab="):
			var n := a.substr(6)
			if not n.is_valid_int() or int(n) < 0:
				_usage("--tab=N needs a non-negative integer, got '%s'" % n)
				return
			_tabs = int(n)
			_focus = true
		elif a.begins_with("--press="):
			var text := a.substr(8)
			if text.is_empty():
				_usage("--press= needs a Button's text")
				return
			_presses.append(text)
		elif a.begins_with("--advance="):
			var v := a.substr(10)
			if v != "all" and not (v.is_valid_int() and int(v) >= 0):
				_usage("--advance=N|all, got '%s'" % v)
				return
			_advance = v
		elif a.begins_with("--frames="):
			var ab := a.substr(9).split(",")
			if ab.size() != 2 or not ab[0].is_valid_int() or not ab[1].is_valid_int() \
					or int(ab[0]) < 1 or int(ab[1]) <= int(ab[0]):
				_usage("--frames=A,B needs integers with 0 < A < B, got '%s'" % a.substr(9))
				return
			_frame_a = int(ab[0])
			_frame_b = int(ab[1])
		elif a == "--hold-boot":
			_hold_boot = true
		elif a.begins_with("--"):
			# An unknown flag is a usage error, never a silently ignored
			# positional: tools/shot_all.sh reads exit 2 as "this shot.gd does
			# not know the flag" and prints SKIPPED for the row.
			_usage("unknown flag '%s'" % a)
			return
		else:
			args.append(a)
	if args.size() < 2:
		_usage("too few arguments")
		return
	_target = args[0]
	_out = args[1]
	if args.size() > 2 and args[2].is_valid_int():
		_frames = int(args[2])
	if args.size() > 3 and args[3].contains("x"):
		var p := args[3].split("x")
		_size = Vector2i(int(p[0]), int(p[1]))
	if _size == Vector2i.ZERO:
		_size = _project_size()


func _usage(why: String) -> void:
	push_error("shot: " + why)
	push_error("usage: --script res://tools/shot.gd -- <scene> <out.png> [frames] [WxH]"
		+ " [--fixture | --fixture=raid | --fixture=raid:clear] [--completed] [--set=key=value]"
		+ " [--focus] [--tab=N] [--press=<Button.text>]... [--advance=N|all]"
		+ " [--frames=A,B] [--hold-boot]")
	_dead = true
	_quit(2)


func _project_size() -> Vector2i:
	return Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 1536)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 1024)))


## Every exit goes through here. quit() frees the autoloads, and GameSettings
## saves `_values` to user://settings.cfg on NOTIFICATION_PREDELETE
## (GameSettings.gd:159-161) — after `reset_all()` and --set those are the
## shot's options, not the player's. Reloading the file first makes that write
## put back exactly what it held (its only `changed` listener is Audio's level
## apply). From _init, before the autoloads exist, there is nothing to reload
## and nothing was changed: the node lookup finds nothing and this is quit().
func _quit(code: int) -> void:
	var gs := root.get_node_or_null("GameSettings")
	if gs != null and gs.has_method("load_from_disk"):
		gs.call("load_from_disk")
		print("SETTINGS restored from user://settings.cfg")
	quit(code)


func _process(_dt: float) -> bool:
	# Everything below _init runs inside the tree, where autoloads resolve and
	# node paths are legal. _init is too early for either.
	if _dead:
		return true
	if not _built:
		_built = true
		return _build()

	# Queued actions, one per frame with settle frames between them, before the
	# capture count starts — so "40 frames" means forty frames of the finished
	# state, whichever flags produced it.
	if _settle > 0:
		_settle -= 1
		return false
	if not _queue.is_empty():
		var act: Dictionary = _queue.pop_front()
		if _run_action(act):
			return true
		_settle = SETTLE_FRAMES
		return false

	_n += 1
	if _frame_b > 0:
		if _n == _frame_a:
			return not _capture(_variant_path("a"))
		if _n < _frame_b:
			return false
		if not _capture(_variant_path("b")):
			return true
		_quit(0)
		return true
	if _n < _frames:
		return false
	if not _capture(_out):
		return true
	_quit(0)
	return true


## `<out>.png` -> `<out>.a.png`; an out without the extension gets it appended.
func _variant_path(tag: String) -> String:
	var base := _out
	if base.to_lower().ends_with(".png"):
		base = base.substr(0, base.length() - 4)
	return "%s.%s.png" % [base, tag]


## Saves the viewport to `path`. False (after quit(code)) when it could not.
func _capture(path: String) -> bool:
	var img := _vp.get_texture().get_image()
	if img == null:
		push_error("shot: viewport image is null — a real display server is required")
		_quit(4)
		return false
	if img.get_size() != _size:
		push_error("shot: captured %s but expected %s" % [img.get_size(), _size])
		_quit(6)
		return false
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var err := img.save_png(path)
	if err != OK:
		push_error("shot: save_png failed (%d) for %s" % [err, path])
		_quit(5)
		return false
	print("SHOT OK %s %dx%d" % [path, img.get_width(), img.get_height()])
	return true


func _build() -> bool:
	if not ResourceLoader.exists(_target):
		push_error("shot: no such scene %s" % _target)
		_quit(3)
		return true

	_vp = SubViewport.new()
	_vp.size = _size
	_vp.disable_3d = true
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)

	# Before anything can record an attempt (see the header): the fixture's
	# autosave must not be the player's.
	SaveGame.SAVE_DIR = SHOT_SAVE_DIR
	SaveGame.purge_all()

	if _fixture:
		var state := root.get_node_or_null("GameState")
		if state == null:
			push_error("shot: --fixture needs the GameState autoload")
			_quit(7)
			return true
		if _fixture_mode == "raid:clear":
			var seed_used: int = Fixture.apply_clear(state)
			if seed_used < 0:
				push_error("shot: --fixture=raid:clear found no clearing seed")
				_quit(10)
				return true
			print("FIXTURE raid:clear %s seed=%d" % [Fixture.CLEAR_SLOT, seed_used])
		else:
			Fixture.apply(state, null, _fixture_mode == "raid")

	# docs/13 §15.1's defaults, not whatever user://settings.cfg holds on this
	# machine (see the header): the autoload loaded that file in _ready().
	var gs := root.get_node_or_null("GameSettings")
	if gs != null and gs.has_method("reset_all"):
		gs.call("reset_all")
		print("SETTINGS defaults%s" % ("" if _settings.is_empty() else " + %s" % _settings))
	if not _settings.is_empty():
		if gs == null:
			push_error("shot: --set needs the GameSettings autoload")
			_quit(7)
			return true
		for key in _settings:
			var raw := String(_settings[key])
			var value = raw
			if raw in ["true", "false"]:
				value = raw == "true"
			elif raw.is_valid_int():
				value = int(raw)
			if not gs.set_value(String(key), value):
				push_error("shot: '%s' is not a settable option" % key)
				_quit(7)
				return true

	if _completed:
		var done := root.get_node_or_null("GameState")
		if done == null:
			push_error("shot: --completed needs the GameState autoload")
			_quit(7)
			return true
		# The same three fields `record_attempt()` sets on the first clear of the
		# last encounter. `completion_seen` stays false so S17 renders as it does
		# on arrival rather than as a re-read.
		done.set("completed", true)
		done.set("completed_on_day", int(done.get("day")))
		done.set("completion_seen", false)

	# The bars: whatever the host does not cover shows the project's clear
	# colour, exactly as a letterboxed window does (W0-SPLASH owns the colour).
	var bars := ColorRect.new()
	bars.name = "Bars"
	var clear = ProjectSettings.get_setting(
		"rendering/environment/defaults/default_clear_color", Color(0.3, 0.3, 0.3))
	if clear is Color:
		bars.color = clear
	bars.position = Vector2.ZERO
	bars.size = Vector2(_size)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp.add_child(bars)

	# TOP_LEFT + an explicit size, not FULL_RECT: a Control anchored full-rect
	# inside a SubViewport that hangs off the Window resolves its anchors
	# against the window's canvas, not the SubViewport, and comes out several
	# times too large. Every layout that measures from the right edge then
	# lands off-screen, which is invisible in a screenshot and very expensive
	# to debug. Pin the size instead.
	_host = Control.new()
	_host.name = "ShotHost"
	_host.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_place_host()
	_vp.add_child(_host)

	var router := root.get_node_or_null("ScreenRouter")
	if router != null and router.has_method("register_host"):
		router.call("register_host", _host)

	var packed = load(_target)
	if packed == null or not (packed is PackedScene):
		push_error("shot: %s is not a PackedScene" % _target)
		_quit(3)
		return true
	_inst = packed.instantiate()
	_host.add_child(_inst)
	if _hold_boot:
		# Queued AFTER Boot's own deferred `_boot()` (its `_ready` ran inside
		# add_child above), so it runs once the router has done its goto.
		call_deferred("_hold_boot_after")
	if _inst is Control:
		(_inst as Control).set_anchors_preset(Control.PRESET_TOP_LEFT)
		(_inst as Control).position = Vector2.ZERO
		(_inst as Control).size = _host.size
	if _inst.has_method("build"):
		_inst.call("build")
	if _inst.has_method("on_enter"):
		_inst.call("on_enter")

	for text in _presses:
		_queue.append({"kind": "press", "text": text})
	if not _advance.is_empty():
		_queue.append({"kind": "advance", "how": _advance})
	if _focus:
		_queue.append({"kind": "focus"})
	if _tabs > 0:
		_queue.append({"kind": "tab", "n": _tabs})
	return false


## Where the screen sits inside the viewport. At the project size this is the
## whole viewport, pixel-identical to every shot taken before the flag existed.
## At any other size it is what `Window.content_scale_aspect` does to the game
## (GameSettings.apply_display_aspect): keep = the 3:2 canvas at the largest
## integer-free scale that fits, centred; expand = the same scale, the canvas
## widened (or heightened) to cover the window.
func _place_host() -> void:
	var base := Vector2(_project_size())
	if Vector2(_size) == base:
		_host.position = Vector2.ZERO
		_host.size = base
		_host.scale = Vector2.ONE
		return
	var s := minf(float(_size.x) / base.x, float(_size.y) / base.y)
	_host.scale = Vector2(s, s)
	if _display_aspect() == "expand":
		_host.position = Vector2.ZERO
		_host.size = Vector2(floorf(float(_size.x) / s), floorf(float(_size.y) / s))
		return
	_host.size = base
	_host.position = Vector2(
		floorf((float(_size.x) - base.x * s) / 2.0),
		floorf((float(_size.y) - base.y * s) / 2.0))


## The option as the game would read it: the autoload (after --set has been
## applied), else the default.
func _display_aspect() -> String:
	var gs := root.get_node_or_null("GameSettings")
	if gs != null and gs.has_method("get_value"):
		return String(gs.call("get_value", "display_aspect"))
	return "keep"


## --hold-boot: runs after Boot's deferred `_boot()`. The router has mounted
## the main menu into Boot's own ScreenHost and hidden the overlay; put the
## frame back to the boot card over an empty host.
func _hold_boot_after() -> void:
	if _inst == null or not is_instance_valid(_inst):
		return
	var boot_host := _inst.get_node_or_null("ScreenHost")
	if boot_host != null:
		for c in boot_host.get_children():
			boot_host.remove_child(c)
			c.queue_free()
	var overlay := _inst.get_node_or_null("BootOverlay")
	if overlay != null:
		overlay.visible = true
	print("HOLD-BOOT overlay shown, host emptied")


## One queued action. True when it failed and quit() has been requested.
func _run_action(act: Dictionary) -> bool:
	match String(act["kind"]):
		"press":
			var b := _find_button(_inst, String(act["text"]))
			if b == null:
				push_error("shot: --press found no Button with text '%s'" % String(act["text"]))
				_quit(9)
				return true
			if b.disabled:
				# Never fake it: a disabled tab's handler is not even connected
				# (Guildhall.gd wires `pressed` only when the tab is open), so
				# emitting would capture the tab that was already up.
				var why := b.tooltip_text if not b.tooltip_text.is_empty() \
					else "no tooltip; the reason is in the adjacent Label"
				push_error("shot: --press '%s' is disabled — %s" % [b.text, why])
				_quit(12)
				return true
			b.pressed.emit()
			print("PRESS %s" % b.text)
		"advance":
			return _advance_log(String(act["how"]))
		"focus":
			return _take_focus()
		"tab":
			for i in int(act["n"]):
				if _focus_owner == null:
					push_error("shot: --tab has no focus owner to step from")
					_quit(8)
					return true
				var next := _focus_owner.find_next_valid_focus()
				if next == null:
					push_error("shot: find_next_valid_focus() from %s returned null" % _focus_owner.name)
					_quit(8)
					return true
				if _grab(next, "--tab %d" % (i + 1)):
					return true
				print("TAB %d -> %s" % [i + 1, _describe(next)])
	return false


## The way tests/unit/test_screens.gd's `_find_button` sees a screen: a Button
## by its exact `.text`, first match in tree order.
func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text:
		return n as Button
	for c in n.get_children():
		var found := _find_button(c, text)
		if found != null:
			return found
	return null


func _take_focus() -> bool:
	if not (_inst is Control):
		push_error("shot: --focus needs a Control screen")
		_quit(8)
		return true
	var screen := _inst as Control
	var regions: int = Router.wire_shell_focus(screen)
	var target: Control = Router.initial_focus_target(screen)
	if target == null:
		push_error("shot: --focus: initial_focus_target() found nothing focusable (%d shell regions)" % regions)
		_quit(8)
		return true
	if _grab(target, "--focus"):
		return true
	print("FOCUS %s (%d shell regions)" % [_describe(target), regions])
	return false


## grab_focus() verified against the SubViewport's own focus owner. True (after
## quit(8)) when the engine did not take it — never a faked ring.
func _grab(c: Control, what: String) -> bool:
	c.grab_focus()
	var holder := _vp.gui_get_focus_owner()
	if holder != c:
		push_error("shot: %s: grab_focus() on %s did not take — focus_mode=%d inside_tree=%s visible_in_tree=%s owner=%s"
			% [what, _describe(c), c.focus_mode, c.is_inside_tree(), c.is_visible_in_tree(),
				_describe(holder) if holder != null else "none"])
		_quit(8)
		return true
	_focus_owner = c
	return false


func _describe(c: Control) -> String:
	var r := c.get_global_rect()
	return "%s<%s> at %d,%d %dx%d" % [c.name, c.get_class(),
		int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]


## `all`: the screen's `_on_skip()` when it has one, else its `_process()` until
## the LogPlayer is finished. `N`: `_process()` until N entries are revealed,
## then freeze `_process` so the capture frames do not reveal an N+1th.
func _advance_log(how: String) -> bool:
	if how == "all" and _inst.has_method("_on_skip"):
		_inst.call("_on_skip")
		print("ADVANCE all via _on_skip()")
		return false
	var player = _inst.get("_player")
	if player == null or not _inst.has_method("_process"):
		push_error("shot: --advance needs a screen with _on_skip() or a `_player` LogPlayer")
		_quit(11)
		return true
	var want: int = int(how) if how != "all" else -1
	var steps := 0
	while steps < ADVANCE_MAX_STEPS:
		var revealed: int = player.revealed_count()
		var finished: bool = player.is_finished()
		if finished or (want >= 0 and revealed >= want):
			break
		_inst.call("_process", ADVANCE_STEP)
		steps += 1
	if want >= 0:
		_inst.set_process(false)
	var total: int = player.total()
	var got: int = player.revealed_count()
	print("ADVANCE %s revealed=%d/%d in %d steps" % [how, got, total, steps])
	return false
```

new:
```
extends SceneTree
## Screenshot harness: render a screen into an exact-size offscreen viewport,
## save it, quit. This is the verification instrument for the whole art pass —
## a shot it produces must be directly pixel-diffable against the 1536x1024
## reference concepts, so the captured size must NEVER depend on the desktop.
##
## Godot's --headless display server uses the dummy rasteriser, where
## get_image() returns null, so a real window is still required to exist. But we
## do not capture the window: the screen is mounted inside a SubViewport of
## exactly the reference size, which the OS cannot clamp. The visible window is
## irrelevant and may be any size the desktop allows.
##
##   godot --path . --script res://tools/shot.gd -- <res://screen.tscn> <out.png> [frames] [WxH]
##        [--fixture | --fixture=raid | --fixture=raid:clear] [--completed] [--set=key=value]
##        [--focus] [--tab=N] [--press=<Button.text>]... [--advance=N|all]
##        [--frames=A,B] [--hold-boot]
##
## --fixture seeds GameState with tools/fixture_reference.gd first, so the shot
## shows the same roster, gold and day as the reference concepts and refdiff
## measures design, not test data. `=raid` also records one attempt at the
## fixture's raid (a wipe); `=raid:clear` records one CLEAR of Adventure 0 by
## the party the game suggests, trying seeds from the fixture's SEED upward
## until one clears, and prints the seed it used (CRITIC-G12: the Results
## screen's loot hand-out had never been seen).
##
## --completed marks the campaign finished (docs/10 §13 row 1's beat). Three
## surfaces only exist in that state — S17 itself, the Adventure's Board's
## post-clear goal, and Records' re-read link — and without this flag none of
## them can be looked at, because tier 5 does not ship until it is named
## (docs/15 BL-69). It sets the same three fields the engine would.
##
## --set=key=value writes one of docs/13 §15.1's options before the screen is
## built, which is how an accessibility state gets LOOKED at rather than only
## asserted: `--set=emoji_free=true`, `--set=reduced_motion=true`,
## `--set=text_scale=150`. One flag for the whole inventory; GameSettings
## coerces the value and refuses an unknown key with its own error.
##
## Every shot starts from §15.1's DEFAULTS (`GameSettings.reset_all()`), never
## from user://settings.cfg: the autoload loads that file in `_ready()`, and a
## machine whose player had left `reduced_motion` on produced two identical
## --frames captures and a 150% main menu with nothing on the command line to
## say why. --set is the only way an option differs, so a shot is reproducible
## from its command line alone. The file is put back before the tool quits:
## quit() frees the autoloads, and GameSettings writes its values to
## user://settings.cfg on NOTIFICATION_PREDELETE (GameSettings.gd:159-161), so
## every exit here goes through `_quit()`, which `load_from_disk()`s first and
## the write that follows carries the player's own options — not the defaults,
## not the --set. (Before this was understood, one shot batch had wiped a 150%
## text scale on the developer's machine; review-W0-SHOT F12.)
##
## Saves go to `user://shot_saves` (purged first), the way tests/run_tests.gd
## redirects `SaveGame.SAVE_DIR`: `record_attempt` autosaves (docs/14 §7.4), so
## `--fixture=raid[:clear]` had been overwriting the player's real
## `user://saves/slot_0_auto_0.json` on every shot (seen 2026-09-14 08:38). A
## LoadSave shot therefore lists only what the shot itself saved.
##
## --focus does what the router does after on_enter() and this tool never did
## (RULES-13): `ScreenRouter.wire_shell_focus()` then grab_focus() on
## `ScreenRouter.initial_focus_target()`, so the §12.3 focus ring is in the
## picture. The grab is verified against the SubViewport's focus owner; if the
## engine refused it the tool says why and exits 8 rather than faking a ring.
## --tab=N then calls find_next_valid_focus() N times (implies --focus).
##
## --press=<text> finds a Button by its exact `.text` — the way the screen
## tests drive screens — and emits `pressed`, after on_enter(). Repeatable;
## pressed in the order given, two settle frames after each, so a tab surface
## ("Records", "Facilities", "Manage", "Buy", "Comfort") can be shot.
##
## --advance=N|all is for RaidView and Results (COMBAT q7): `all` calls the
## screen's `_on_skip()` when it has one (the wipe sequence plays to its last
## beat), else runs the screen's own `_process()` until its LogPlayer is
## finished; `N` runs `_process()` until N entries are revealed, then freezes
## the screen's `_process` so the count holds through the capture frames.
##
## --frames=A,B captures twice, at frame A and frame B after the screen has
## settled, to `<out minus .png>.a.png` and `.b.png` — a motion diff in two
## files (STAGE-14; M4B-VFX-01's own measurement). Replaces [frames].
##
## --hold-boot is for res://game/ui/Boot.tscn (CRITIC-G02): Boot's `_ready()`
## defers `_boot()`, which loads content and routes to the main menu; inside
## the SubViewport that deferred call cannot be intercepted, so this tool lets
## it run, then un-mounts whatever the router placed and re-shows the overlay.
## What is captured is the boot card over the empty host — the composition of
## the game's real first frame.
##
## WxH other than the project size honours the `display_aspect` option
## (CRITIC-G03): under `keep` the screen is mounted at 1536x1024 (scaled by
## min(W/1536, H/1024)) and centred on bars of the project's
## `rendering/environment/defaults/default_clear_color`; under `expand` the
## screen is handed the whole canvas at the same scale, so
## `MainMenu 1820x1024 --set=display_aspect=expand` is 1820 wide.
##
## Exit codes:
##    0 the PNG(s) were written ("SHOT OK <path> WxH" per file)
##    2 usage: too few positionals, an unknown --flag, a bad --tab/--advance/--frames value
##    3 no such scene / not a PackedScene
##    4 the viewport image is null (headless — a real display server is required)
##    5 save_png failed
##    6 the captured image is not WxH
##    7 a flag needs an autoload that is missing, or --set named an unsettable option
##    8 --focus/--tab could not take focus (reason printed)
##    9 --press found no Button with that exact text
##   10 --fixture=raid:clear found no clearing seed (fixture_reference.CLEAR_MAX_SEEDS)
##   11 --advance on a screen with no `_on_skip()` and no `_player` LogPlayer
##   12 --press found the Button but it is disabled (its reason is printed; a
##      player cannot press it, so the tool does not fake the press — the shot
##      would silently show the tab that was already up)

const DEFAULT_FRAMES := 30
## Frames left to the screen between one queued action and the next, so a press
## that rebuilds a tab has laid out before the next press or the capture count.
const SETTLE_FRAMES := 2
## Seconds fed to the screen's `_process()` per synthetic step under --advance:
## one 50 fps frame, so no reveal step is skipped over and N means N.
const ADVANCE_STEP := 0.02
const ADVANCE_MAX_STEPS := 200000
const Fixture = preload("res://tools/fixture_reference.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
## Where a fixture's autosave lands — never the player's `user://saves`.
const SHOT_SAVE_DIR := "user://shot_saves"

var _target := ""
var _out := ""
var _frames := DEFAULT_FRAMES
var _size := Vector2i(0, 0)
var _fixture := false
var _fixture_mode := ""
var _completed := false
var _settings: Dictionary = {}
var _focus := false
var _tabs := 0
var _presses: Array[String] = []
var _advance := ""
var _frame_a := 0
var _frame_b := 0
var _hold_boot := false
var _n := 0
var _vp: SubViewport = null
var _host: Control = null
var _inst: Node = null
var _built := false
var _queue: Array = []
var _settle := 0
var _focus_owner: Control = null
## Set by _usage(): quit() only REQUESTS a quit, and a _process() that still ran
## would call quit(3) over the usage code — the code W0-GATE's SKIPPED row reads.
var _dead := false


func _init() -> void:
    var args: Array[String] = []
    for a in OS.get_cmdline_user_args():
        if a == "--fixture":
            _fixture = true
        elif a == "--fixture=raid":
            _fixture = true
            _fixture_mode = "raid"
        elif a == "--fixture=raid:clear":
            _fixture = true
            _fixture_mode = "raid:clear"
        elif a == "--completed":
            _completed = true
        elif a.begins_with("--set="):
            # One flag for every option in docs/13 §15.1's inventory, rather than
            # a new flag each time an accessibility state needs looking at. The
            # value is coerced by GameSettings itself, so a typo in the key is
            # refused there with the doc's own error rather than silently doing
            # nothing here.
            var kv := a.substr(6).split("=")
            if kv.size() == 2:
                _settings[String(kv[0])] = String(kv[1])
        elif a == "--focus":
            _focus = true
        elif a.begins_with("--tab="):
            var n := a.substr(6)
            if not n.is_valid_int() or int(n) < 0:
                _usage("--tab=N needs a non-negative integer, got '%s'" % n)
                return
            _tabs = int(n)
            _focus = true
        elif a.begins_with("--press="):
            var text := a.substr(8)
            if text.is_empty():
                _usage("--press= needs a Button's text")
                return
            _presses.append(text)
        elif a.begins_with("--advance="):
            var v := a.substr(10)
            if v != "all" and not (v.is_valid_int() and int(v) >= 0):
                _usage("--advance=N|all, got '%s'" % v)
                return
            _advance = v
        elif a.begins_with("--frames="):
            var ab := a.substr(9).split(",")
            if ab.size() != 2 or not ab[0].is_valid_int() or not ab[1].is_valid_int() \
                    or int(ab[0]) < 1 or int(ab[1]) <= int(ab[0]):
                _usage("--frames=A,B needs integers with 0 < A < B, got '%s'" % a.substr(9))
                return
            _frame_a = int(ab[0])
            _frame_b = int(ab[1])
        elif a == "--hold-boot":
            _hold_boot = true
        elif a.begins_with("--"):
            # An unknown flag is a usage error, never a silently ignored
            # positional: tools/shot_all.sh reads exit 2 as "this shot.gd does
            # not know the flag" and prints SKIPPED for the row.
            _usage("unknown flag '%s'" % a)
            return
        else:
            args.append(a)
    if args.size() < 2:
        _usage("too few arguments")
        return
    _target = args[0]
    _out = args[1]
    if args.size() > 2 and args[2].is_valid_int():
        _frames = int(args[2])
    if args.size() > 3 and args[3].contains("x"):
        var p := args[3].split("x")
        _size = Vector2i(int(p[0]), int(p[1]))
    if _size == Vector2i.ZERO:
        _size = _project_size()


func _usage(why: String) -> void:
    push_error("shot: " + why)
    push_error("usage: --script res://tools/shot.gd -- <scene> <out.png> [frames] [WxH]"
        + " [--fixture | --fixture=raid | --fixture=raid:clear] [--completed] [--set=key=value]"
        + " [--focus] [--tab=N] [--press=<Button.text>]... [--advance=N|all]"
        + " [--frames=A,B] [--hold-boot]")
    _dead = true
    _quit(2)


func _project_size() -> Vector2i:
    return Vector2i(
        int(ProjectSettings.get_setting("display/window/size/viewport_width", 1536)),
        int(ProjectSettings.get_setting("display/window/size/viewport_height", 1024)))


## Every exit goes through here. quit() frees the autoloads, and GameSettings
## saves `_values` to user://settings.cfg on NOTIFICATION_PREDELETE
## (GameSettings.gd:159-161) — after `reset_all()` and --set those are the
## shot's options, not the player's. Reloading the file first makes that write
## put back exactly what it held (its only `changed` listener is Audio's level
## apply). From _init, before the autoloads exist, there is nothing to reload
## and nothing was changed: the node lookup finds nothing and this is quit().
func _quit(code: int) -> void:
    var gs := root.get_node_or_null("GameSettings")
    if gs != null and gs.has_method("load_from_disk"):
        gs.call("load_from_disk")
        print("SETTINGS restored from user://settings.cfg")
    quit(code)


func _process(_dt: float) -> bool:
    # Everything below _init runs inside the tree, where autoloads resolve and
    # node paths are legal. _init is too early for either.
    if _dead:
        return true
    if not _built:
        _built = true
        return _build()

    # Queued actions, one per frame with settle frames between them, before the
    # capture count starts — so "40 frames" means forty frames of the finished
    # state, whichever flags produced it.
    if _settle > 0:
        _settle -= 1
        return false
    if not _queue.is_empty():
        var act: Dictionary = _queue.pop_front()
        if _run_action(act):
            return true
        _settle = SETTLE_FRAMES
        return false

    _n += 1
    if _frame_b > 0:
        if _n == _frame_a:
            return not _capture(_variant_path("a"))
        if _n < _frame_b:
            return false
        if not _capture(_variant_path("b")):
            return true
        _quit(0)
        return true
    if _n < _frames:
        return false
    if not _capture(_out):
        return true
    _quit(0)
    return true


## `<out>.png` -> `<out>.a.png`; an out without the extension gets it appended.
func _variant_path(tag: String) -> String:
    var base := _out
    if base.to_lower().ends_with(".png"):
        base = base.substr(0, base.length() - 4)
    return "%s.%s.png" % [base, tag]


## Saves the viewport to `path`. False (after quit(code)) when it could not.
func _capture(path: String) -> bool:
    var img := _vp.get_texture().get_image()
    if img == null:
        push_error("shot: viewport image is null — a real display server is required")
        _quit(4)
        return false
    if img.get_size() != _size:
        push_error("shot: captured %s but expected %s" % [img.get_size(), _size])
        _quit(6)
        return false
    var dir := path.get_base_dir()
    if dir != "" and not DirAccess.dir_exists_absolute(dir):
        DirAccess.make_dir_recursive_absolute(dir)
    var err := img.save_png(path)
    if err != OK:
        push_error("shot: save_png failed (%d) for %s" % [err, path])
        _quit(5)
        return false
    print("SHOT OK %s %dx%d" % [path, img.get_width(), img.get_height()])
    return true


func _build() -> bool:
    if not ResourceLoader.exists(_target):
        push_error("shot: no such scene %s" % _target)
        _quit(3)
        return true

    _vp = SubViewport.new()
    _vp.size = _size
    _vp.disable_3d = true
    _vp.transparent_bg = false
    _vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(_vp)

    # Before anything can record an attempt (see the header): the fixture's
    # autosave must not be the player's.
    SaveGame.SAVE_DIR = SHOT_SAVE_DIR
    SaveGame.purge_all()

    if _fixture:
        var state := root.get_node_or_null("GameState")
        if state == null:
            push_error("shot: --fixture needs the GameState autoload")
            _quit(7)
            return true
        if _fixture_mode == "raid:clear":
            var seed_used: int = Fixture.apply_clear(state)
            if seed_used < 0:
                push_error("shot: --fixture=raid:clear found no clearing seed")
                _quit(10)
                return true
            print("FIXTURE raid:clear %s seed=%d" % [Fixture.CLEAR_SLOT, seed_used])
        else:
            Fixture.apply(state, null, _fixture_mode == "raid")

    # docs/13 §15.1's defaults, not whatever user://settings.cfg holds on this
    # machine (see the header): the autoload loaded that file in _ready().
    var gs := root.get_node_or_null("GameSettings")
    if gs != null and gs.has_method("reset_all"):
        gs.call("reset_all")
        print("SETTINGS defaults%s" % ("" if _settings.is_empty() else " + %s" % _settings))
    if not _settings.is_empty():
        if gs == null:
            push_error("shot: --set needs the GameSettings autoload")
            _quit(7)
            return true
        for key in _settings:
            var raw := String(_settings[key])
            var value = raw
            if raw in ["true", "false"]:
                value = raw == "true"
            elif raw.is_valid_int():
                value = int(raw)
            if not gs.set_value(String(key), value):
                push_error("shot: '%s' is not a settable option" % key)
                _quit(7)
                return true

    if _completed:
        var done := root.get_node_or_null("GameState")
        if done == null:
            push_error("shot: --completed needs the GameState autoload")
            _quit(7)
            return true
        # The same three fields `record_attempt()` sets on the first clear of the
        # last encounter. `completion_seen` stays false so S17 renders as it does
        # on arrival rather than as a re-read.
        done.set("completed", true)
        done.set("completed_on_day", int(done.get("day")))
        done.set("completion_seen", false)

    # The bars: whatever the host does not cover shows the project's clear
    # colour, exactly as a letterboxed window does (W0-SPLASH owns the colour).
    var bars := ColorRect.new()
    bars.name = "Bars"
    var clear = ProjectSettings.get_setting(
        "rendering/environment/defaults/default_clear_color", Color(0.3, 0.3, 0.3))
    if clear is Color:
        bars.color = clear
    bars.position = Vector2.ZERO
    bars.size = Vector2(_size)
    bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _vp.add_child(bars)

    # TOP_LEFT + an explicit size, not FULL_RECT: a Control anchored full-rect
    # inside a SubViewport that hangs off the Window resolves its anchors
    # against the window's canvas, not the SubViewport, and comes out several
    # times too large. Every layout that measures from the right edge then
    # lands off-screen, which is invisible in a screenshot and very expensive
    # to debug. Pin the size instead.
    _host = Control.new()
    _host.name = "ShotHost"
    _host.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _place_host()
    _vp.add_child(_host)

    var router := root.get_node_or_null("ScreenRouter")
    if router != null and router.has_method("register_host"):
        router.call("register_host", _host)

    var packed = load(_target)
    if packed == null or not (packed is PackedScene):
        push_error("shot: %s is not a PackedScene" % _target)
        _quit(3)
        return true
    _inst = packed.instantiate()
    _host.add_child(_inst)
    if _hold_boot:
        # Queued AFTER Boot's own deferred `_boot()` (its `_ready` ran inside
        # add_child above), so it runs once the router has done its goto.
        call_deferred("_hold_boot_after")
    if _inst is Control:
        (_inst as Control).set_anchors_preset(Control.PRESET_TOP_LEFT)
        (_inst as Control).position = Vector2.ZERO
        (_inst as Control).size = _host.size
    if _inst.has_method("build"):
        _inst.call("build")
    if _inst.has_method("on_enter"):
        _inst.call("on_enter")

    for text in _presses:
        _queue.append({"kind": "press", "text": text})
    if not _advance.is_empty():
        _queue.append({"kind": "advance", "how": _advance})
    if _focus:
        _queue.append({"kind": "focus"})
    if _tabs > 0:
        _queue.append({"kind": "tab", "n": _tabs})
    return false


## Where the screen sits inside the viewport. At the project size this is the
## whole viewport, pixel-identical to every shot taken before the flag existed.
## At any other size it is what `Window.content_scale_aspect` does to the game
## (GameSettings.apply_display_aspect): keep = the 3:2 canvas at the largest
## integer-free scale that fits, centred; expand = the same scale, the canvas
## widened (or heightened) to cover the window.
func _place_host() -> void:
    var base := Vector2(_project_size())
    if Vector2(_size) == base:
        _host.position = Vector2.ZERO
        _host.size = base
        _host.scale = Vector2.ONE
        return
    var s := minf(float(_size.x) / base.x, float(_size.y) / base.y)
    _host.scale = Vector2(s, s)
    if _display_aspect() == "expand":
        _host.position = Vector2.ZERO
        _host.size = Vector2(floorf(float(_size.x) / s), floorf(float(_size.y) / s))
        return
    _host.size = base
    _host.position = Vector2(
        floorf((float(_size.x) - base.x * s) / 2.0),
        floorf((float(_size.y) - base.y * s) / 2.0))


## The option as the game would read it: the autoload (after --set has been
## applied), else the default.
func _display_aspect() -> String:
    var gs := root.get_node_or_null("GameSettings")
    if gs != null and gs.has_method("get_value"):
        return String(gs.call("get_value", "display_aspect"))
    return "keep"


## --hold-boot: runs after Boot's deferred `_boot()`. The router has mounted
## the main menu into Boot's own ScreenHost and hidden the overlay; put the
## frame back to the boot card over an empty host.
func _hold_boot_after() -> void:
    if _inst == null or not is_instance_valid(_inst):
        return
    var boot_host := _inst.get_node_or_null("ScreenHost")
    if boot_host != null:
        for c in boot_host.get_children():
            boot_host.remove_child(c)
            c.queue_free()
    var overlay := _inst.get_node_or_null("BootOverlay")
    if overlay != null:
        overlay.visible = true
    print("HOLD-BOOT overlay shown, host emptied")


## One queued action. True when it failed and quit() has been requested.
func _run_action(act: Dictionary) -> bool:
    match String(act["kind"]):
        "press":
            var b := _find_button(_inst, String(act["text"]))
            if b == null:
                push_error("shot: --press found no Button with text '%s'" % String(act["text"]))
                _quit(9)
                return true
            if b.disabled:
                # Never fake it: a disabled tab's handler is not even connected
                # (Guildhall.gd wires `pressed` only when the tab is open), so
                # emitting would capture the tab that was already up.
                var why := b.tooltip_text if not b.tooltip_text.is_empty() \
                    else "no tooltip; the reason is in the adjacent Label"
                push_error("shot: --press '%s' is disabled — %s" % [b.text, why])
                _quit(12)
                return true
            b.pressed.emit()
            print("PRESS %s" % b.text)
        "advance":
            return _advance_log(String(act["how"]))
        "focus":
            return _take_focus()
        "tab":
            for i in int(act["n"]):
                if _focus_owner == null:
                    push_error("shot: --tab has no focus owner to step from")
                    _quit(8)
                    return true
                var next := _focus_owner.find_next_valid_focus()
                if next == null:
                    push_error("shot: find_next_valid_focus() from %s returned null" % _focus_owner.name)
                    _quit(8)
                    return true
                if _grab(next, "--tab %d" % (i + 1)):
                    return true
                print("TAB %d -> %s" % [i + 1, _describe(next)])
    return false


## The way tests/unit/test_screens.gd's `_find_button` sees a screen: a Button
## by its exact `.text`, first match in tree order.
func _find_button(n: Node, text: String) -> Button:
    if n is Button and (n as Button).text == text:
        return n as Button
    for c in n.get_children():
        var found := _find_button(c, text)
        if found != null:
            return found
    return null


func _take_focus() -> bool:
    if not (_inst is Control):
        push_error("shot: --focus needs a Control screen")
        _quit(8)
        return true
    var screen := _inst as Control
    var regions: int = Router.wire_shell_focus(screen)
    var target: Control = Router.initial_focus_target(screen)
    if target == null:
        push_error("shot: --focus: initial_focus_target() found nothing focusable (%d shell regions)" % regions)
        _quit(8)
        return true
    if _grab(target, "--focus"):
        return true
    print("FOCUS %s (%d shell regions)" % [_describe(target), regions])
    return false


## grab_focus() verified against the SubViewport's own focus owner. True (after
## quit(8)) when the engine did not take it — never a faked ring.
func _grab(c: Control, what: String) -> bool:
    c.grab_focus()
    var holder := _vp.gui_get_focus_owner()
    if holder != c:
        push_error("shot: %s: grab_focus() on %s did not take — focus_mode=%d inside_tree=%s visible_in_tree=%s owner=%s"
            % [what, _describe(c), c.focus_mode, c.is_inside_tree(), c.is_visible_in_tree(),
                _describe(holder) if holder != null else "none"])
        _quit(8)
        return true
    _focus_owner = c
    return false


func _describe(c: Control) -> String:
    var r := c.get_global_rect()
    return "%s<%s> at %d,%d %dx%d" % [c.name, c.get_class(),
        int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]


## `all`: the screen's `_on_skip()` when it has one, else its `_process()` until
## the LogPlayer is finished. `N`: `_process()` until N entries are revealed,
## then freeze `_process` so the capture frames do not reveal an N+1th.
func _advance_log(how: String) -> bool:
    if how == "all" and _inst.has_method("_on_skip"):
        _inst.call("_on_skip")
        print("ADVANCE all via _on_skip()")
        return false
    var player = _inst.get("_player")
    if player == null or not _inst.has_method("_process"):
        push_error("shot: --advance needs a screen with _on_skip() or a `_player` LogPlayer")
        _quit(11)
        return true
    var want: int = int(how) if how != "all" else -1
    var steps := 0
    while steps < ADVANCE_MAX_STEPS:
        var revealed: int = player.revealed_count()
        var finished: bool = player.is_finished()
        if finished or (want >= 0 and revealed >= want):
            break
        _inst.call("_process", ADVANCE_STEP)
        steps += 1
    if want >= 0:
        _inst.set_process(false)
    var total: int = player.total()
    var got: int = player.revealed_count()
    print("ADVANCE %s revealed=%d/%d in %d steps" % [how, got, total, steps])
    return false
```

## 7. LESSONS.md:23

Record-truth once §1-§4 land (LESSONS.md is not on this unit's list).

old:
```
- **The unit-test runner redirects saves but not settings.** `tests/run_tests.gd` points `SaveGame.SAVE_DIR` at a test dir; `GameSettings` still saves to the real `user://settings.cfg` on PREDELETE, so every `verify.sh` run overwrites the developer's options with the last test's values (text_scale 100, reduced_motion true). `tools/shot.gd` reloads from disk before every exit for that reason; the runner itself is still owed the same redirect (W4-HYGIENE).
```

new:
```
- **The unit-test runner redirects saves but not settings — and any instrument that applies the fixture writes a real autosave.** `tests/run_tests.gd` pointed `SaveGame.SAVE_DIR` at a test dir while `GameSettings` still saved to the real `user://settings.cfg` on PREDELETE, so every `verify.sh` run overwrote the developer's options with the last test's values (text_scale 100, reduced_motion true); `tools/playtest.gd` and `a11y_smoke.gd` wrote "Playtest NNNNN" and fixture autosaves into the real save dir for the same reason. `GameSettings.PATH` is a `static var` now and the runner points it at `user://test_settings.cfg` beside its `test_saves`; the two instruments redirect `SAVE_DIR` the way `shot.gd` and `perf_probe.gd` already did. The rule: before wiring a verb that touches the user's disk, ask what happens when the whole suite calls it, and put the answer behind a variable the runner can move (W4-HYGIENE).
```

## Observations for other units (no edit here)

- **W4-PREP — RaidPrep's sidebar overflowed the band at the wave start, and W4-PREP's in-flight edit
  already fixes it.** `tests/unit/test_sidebar_fit.gd` (TOWN-17's guard) measured the wave-start column at
  ~672px (empty guild) / ~703px (fixture) against a 635px host, and the wave-3 sheets confirmed it: the
  panel's bottom rim rendered at y=767 (empty) and y=822 (fixture) against SIDEBAR_BOTTOM 714
  (`build/shots/W4HYG_RaidPrep_{empty,fixture}_side.png`). The guard carried RaidPrep as an
  `OVERFLOW_PENDING` row (asserted to still overflow); an hour later W4-PREP's uncommitted RaidPrep.gd
  (a `SidebarScroll` ScrollContainer, the provisions moved to the strip — G15 / TOWN-17 in its own
  comments) flipped the row (the column now wants 178/153px outside the scroll), so the row is deleted and
  the guard covers RaidPrep like every other route. Nothing to apply; if W4-PREP's change does not land,
  the guard goes red on RaidPrep with the number, which is the correct state.
- **W4-LIFE — stage_town.json's note.** §5 above; if the sails/gulls edit rewrites that paragraph, drop the
  stale sentence in the same edit and add the LIES row named there.
- **Nobody's this wave — `tools/probe/Kit.gd:229` still loads the seven `badge_N.png` mockup crops** (the only
  loader left; the shipping log resolves badges by kind through the icon grid, W3-KIT2). Deleting
  `game/assets/ui/icons/badge_0..6.png` + `.import` needs Kit.gd repointed at `Cards.badge_icon(kind)` first;
  the audit row m4t-09 says so. Likewise `game/assets/bg/{arena_plate,arena_stage,menu_plate,tavern_plate}.png`
  are loaded by nothing (M4B-CONV-02's remaining step; three comments name them as history only).
