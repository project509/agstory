extends SceneTree
## The latency budget, measured (RULES-15, audit M6-JUICE-07): docs/13 §12.1
## says "screen / tab switch fully settled ≤ 140 ms" and calls itself a perf
## test, and until this file nothing in the gate timed anything — every light,
## particle system and shader of the art pass landed without a number.
##
## Every screen in tests/unit/a11y_smoke.gd's SCREENS list is mounted through
## the real ScreenRouter autoload (`goto()`, the way the game turns a page),
## inside a SubViewport of exactly the project size (1536x1024 — the number the
## budget is quoted at), on the reference fixture with one recorded raid
## (tools/fixture_reference.gd — the same seam tools/shot.gd's --fixture=raid
## uses, so RaidView/Results/RaidPrep have a real log to draw). Two numbers per
## screen:
##
##   mount   wall time from the `goto()` call to the start of the next frame:
##           the previous screen's on_exit/free, instantiate, build(),
##           on_enter(), the focus wiring and the FIRST DRAW (shader compile,
##           texture upload). Judged against MOUNT_BUDGET_MS (§12.1 row 2).
##   frame   mean wall period between frames over up to FRAMES frames, after
##           WARMUP frames, with vsync off and no fps cap — the steady state the
##           screen's tweens, shimmer and lights cost. Judged against
##           FRAME_BUDGET_MS (60 fps at 1536x1024; the plan's 16.6).
##           `max` and the viewport's own measured GPU time are printed beside
##           it for diagnosis and never judged.
##
## Order: a warm-up mount of Town (printed, not judged — it carries the cold
## load of the shared theme, fonts and kit textures every screen would
## otherwise pay first), then the thirteen in list order, each on its FIRST
## visit (its own plates and strips cold, as a player's first visit is), then
## RaidView once more. Measured 2026-09-15: the revisit after twelve other
## screens costs ~150 ms of goto against ~250 cold, and a RaidView-to-RaidView
## switch (`--only=RaidView`) ~70 — the resource cache is weak, so a freed
## screen's own textures are gone by the next visit and a player's second
## visit reloads them; the gap between the three is what loading costs, the
## remainder is build().
##
##   godot --path . --script res://tools/perf_probe.gd [-- --frames=N] [--only=Name] [--split]...
##       --frames=N   frames measured per screen (default FRAMES)
##       --only=Name  a scene's basename (repeatable); judged rows are limited to those
##       --warm       ScreenRouter.warm() and SceneStage.warm() before the rows — the
##                    scenes compiled and the plates loaded ahead, as Boot does behind
##                    its overlay (handoff-W5-MOUNT.md); without it every first visit
##                    pays its script's compile (45-140 ms, the `load` figure under
##                    --split) and its plate (~37 ms), and the rows say what a build
##                    with no warm-up would cost
##       --split      a second line per row: goto()'s phases (ScreenRouter.last_split —
##                    clear / load / instantiate / build / on_enter / focus), what
##                    Frame.build() and SceneStage.from_data() cost inside build, and
##                    the strong cache's hits/misses for the turn (W5-MOUNT). Not
##                    judged; it is how a mount number is read, not a second budget.
##
## A real display server is required: the headless rasteriser draws nothing,
## so a frame time under --headless is a number about nothing (exit 4).
##
## THE CLOCK CAVEAT. This laptop ran the same suite in 33 s boosting and 177 s
## at base clock (BUILD_STATE.md, machine note), so absolute times here vary
## ~5x between runs of the same code. Every run therefore prints a calibration
## figure (CALIB_ITERS turns of a fixed GDScript loop, in ms) so two runs can
## be compared, rows are judged only as WARN lines, and tools/verify.sh's stage
## reads `PERF OK` / `PERF WARN` and never fails the build on either — the
## playtest precedent (verify.sh's stage 7/8). The gate is a human reading the
## numbers; the instrument's job is that the numbers exist on every full run.
##
## Every exit goes through `_quit()`, which reloads user://settings.cfg first:
## quit() frees the autoloads and GameSettings writes its values on PREDELETE,
## and after `reset_all()` those would be the probe's defaults, not the
## player's options (tools/shot.gd's header, review-W0-SHOT F12). Saves are
## redirected to SAVE_DIR before the fixture records its attempt, so the
## autosave never lands in the player's `user://saves` (shot.gd J6).
##
## Exit codes:
##    0 PERF OK — every judged row inside both budgets
##    1 PERF WARN — at least one judged row over a budget (the table says which)
##    2 usage: an unknown --flag or a bad --frames value
##    4 no real display server (--headless), so nothing renders
##    7 an autoload the probe needs is missing (GameState, GameSettings, ScreenRouter)

const Fixture = preload("res://tools/fixture_reference.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
## For their `profile` counters under --split only; nothing is built through them.
const Frame = preload("res://game/ui/Frame.gd")
const Stage = preload("res://game/ui/SceneStage.gd")
## The one explicit screen list (LESSONS: no directory walk). Preloaded for its
## SCREENS constant only; the smoke itself is never instantiated here.
const Smoke = preload("res://tests/unit/a11y_smoke.gd")

## docs/13 §12.1 row 2, and the plan's frame number at 1536x1024.
const MOUNT_BUDGET_MS := 140.0
const FRAME_BUDGET_MS := 16.6
## RULES-15's "mean frame time over 120 frames".
const FRAMES := 120
## Frames after the first draw that are not counted: the second and third
## frames still pay one-off costs (deferred layout, the first tween tick).
const WARMUP := 3
## Cap on one screen's measuring window, so a slow clock (80 ms frames) keeps
## the whole probe near a minute: n is printed, so a short window is visible.
const SCREEN_CAP_MS := 2500.0
## Turns of the calibration loop. Sized to ~40 ms on this laptop boosting.
const CALIB_ITERS := 400000
## Where the fixture's autosave lands — never the player's `user://saves`.
const SAVE_DIR := "user://perf_saves"
const WARMUP_SCENE := "res://game/screens/Town.tscn"
const REVISIT_SCENE := "res://game/screens/RaidView.tscn"

var _frames := FRAMES
var _only: Array[String] = []
var _split := false
var _warm := false
var _dead := false
var _built := false
var _phase := ""
var _vp: SubViewport = null
var _host: Control = null
var _router: Node = null
var _rid: RID
var _size := Vector2i(1536, 1024)
var _queue: Array = []
var _row: Dictionary = {}
var _rows: Array = []
var _warns: Array[String] = []
var _t_run := 0
var _t_mount := 0
var _t_last := 0
var _t_window := 0
var _n := 0
var _sum := 0.0
var _max := 0.0
var _gpu_sum := 0.0
var _calib_ms := 0
var _fixture_ms := 0


func _init() -> void:
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--frames="):
            var n := a.substr(9)
            if not n.is_valid_int() or int(n) < 1:
                _usage("--frames=N needs a positive integer, got '%s'" % n)
                return
            _frames = int(n)
        elif a.begins_with("--only="):
            var base := a.substr(7)
            if base.is_empty():
                _usage("--only= needs a scene basename, e.g. --only=RaidView")
                return
            _only.append(base)
        elif a == "--split":
            _split = true
        elif a == "--warm":
            _warm = true
        elif a.begins_with("--"):
            _usage("unknown flag '%s'" % a)
            return


func _usage(why: String) -> void:
    push_error("perf_probe: " + why)
    push_error("usage: --script res://tools/perf_probe.gd [-- --frames=N] [--only=Name] [--split] [--warm]...")
    _dead = true
    _quit(2)


## Every exit goes through here (see the header): the settings file is put
## back before quit() lets GameSettings write the probe's defaults over it.
func _quit(code: int) -> void:
    var gs := root.get_node_or_null("GameSettings")
    if gs != null and gs.has_method("load_from_disk"):
        gs.call("load_from_disk")
        print("SETTINGS restored from user://settings.cfg")
    quit(code)


func _project_size() -> Vector2i:
    return Vector2i(
        int(ProjectSettings.get_setting("display/window/size/viewport_width", 1536)),
        int(ProjectSettings.get_setting("display/window/size/viewport_height", 1024)))


func _process(_dt: float) -> bool:
    # Everything below _init runs inside the tree, where the autoloads resolve.
    if _dead:
        return true
    var now := Time.get_ticks_usec()
    if not _built:
        _built = true
        return _setup()
    match _phase:
        "mount":
            if _queue.is_empty():
                return _finish()
            _row = _queue.pop_front()
            if _split:
                Frame.profile_reset()
                Stage.profile_reset()
            _t_mount = Time.get_ticks_usec()
            if not _router.call("goto", String(_row["path"])):
                print("  SKIP  %s (goto refused)" % String(_row["label"]))
                return false
            _row["goto_ms"] = float(Time.get_ticks_usec() - _t_mount) / 1000.0
            if _split:
                _row["split"] = _router.call("last_split")
                _row["frame_profile"] = Frame.profile.duplicate()
                _row["stage_profile"] = Stage.profile.duplicate()
            _pin_screen()
            _phase = "first"
        "first":
            # The previous frame drew the screen for the first time; this is
            # the first moment after that draw, so the switch has settled.
            _row["mount_ms"] = float(now - _t_mount) / 1000.0
            _n = 0
            _sum = 0.0
            _max = 0.0
            _gpu_sum = 0.0
            _t_last = now
            _phase = "warm"
        "warm":
            _n += 1
            _t_last = now
            if _n >= WARMUP:
                _n = 0
                _t_window = now
                _phase = "measure"
        "measure":
            var ms := float(now - _t_last) / 1000.0
            _t_last = now
            _n += 1
            _sum += ms
            _max = maxf(_max, ms)
            _gpu_sum += RenderingServer.viewport_get_measured_render_time_gpu(_rid)
            if _n >= _frames or float(now - _t_window) / 1000.0 >= SCREEN_CAP_MS:
                _record()
                _phase = "mount"
    return false


func _setup() -> bool:
    _t_run = Time.get_ticks_usec()
    if DisplayServer.get_name() == "headless":
        push_error("perf_probe: a real display server is required — the headless rasteriser renders nothing")
        print("PERF SKIP  headless: run without --headless (nothing renders, so nothing can be timed)")
        _quit(4)
        return true
    var state := root.get_node_or_null("GameState")
    var gs := root.get_node_or_null("GameSettings")
    _router = root.get_node_or_null("ScreenRouter")
    if state == null or gs == null or _router == null:
        push_error("perf_probe: needs the GameState, GameSettings and ScreenRouter autoloads")
        _quit(7)
        return true

    # The frame period must be the frame's own cost, not the monitor's.
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    Engine.max_fps = 0
    OS.low_processor_usage_mode = false
    _calib_ms = _calibrate()

    # Before anything can record an attempt: the fixture's autosave must not be
    # the player's (tools/shot.gd J6).
    SaveGame.SAVE_DIR = SAVE_DIR
    SaveGame.purge_all()
    var t := Time.get_ticks_usec()
    Fixture.apply(state, null, true)
    _fixture_ms = int((Time.get_ticks_usec() - t) / 1000)
    # docs/13 §15.1's defaults, never this machine's user://settings.cfg: a
    # player's reduced_motion=true would hold every tween and shimmer at 0 and
    # flatter the frame numbers (shot.gd's header).
    gs.call("reset_all")

    _size = _project_size()
    _vp = SubViewport.new()
    _vp.size = _size
    _vp.disable_3d = true
    _vp.transparent_bg = false
    _vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(_vp)
    _rid = _vp.get_viewport_rid()
    RenderingServer.viewport_set_measure_render_time(_rid, true)

    # TOP_LEFT + an explicit size, never FULL_RECT: inside a SubViewport that
    # hangs off the Window a full-rect anchor resolves against the window's
    # canvas and the screen comes out several times too large (LESSONS).
    _host = Control.new()
    _host.name = "PerfHost"
    _host.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _host.position = Vector2.ZERO
    _host.size = Vector2(_size)
    _vp.add_child(_host)
    _router.call("register_host", _host)

    _queue.append({"path": WARMUP_SCENE, "label": "warm-up Town (not judged)", "judged": false})
    var has_raidview := false
    for p in Smoke.SCREENS:
        var base := String(p).get_file().get_basename()
        if not _only.is_empty() and not (base in _only):
            continue
        _queue.append({"path": String(p), "label": base, "judged": true})
        if String(p) == REVISIT_SCENE:
            has_raidview = true
    if has_raidview:
        _queue.append({"path": REVISIT_SCENE, "label": "RaidView (revisit)", "judged": true})

    print("PERF probe  %dx%d SubViewport (UPDATE_ALWAYS), vsync off, no fps cap, %s renderer"
        % [_size.x, _size.y, String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))])
    print("PERF budget mount <= %.0f ms (docs/13 §12.1 screen switch), frame <= %.1f ms mean (60 fps); up to %d frames per screen after %d warm-up frames, window capped at %.0f ms"
        % [MOUNT_BUDGET_MS, FRAME_BUDGET_MS, _frames, WARMUP, SCREEN_CAP_MS])
    print("PERF fixture  reference guild + one recorded raid in %d ms; calibration loop %d ms" % [_fixture_ms, _calib_ms])
    if _warm:
        var tw := Time.get_ticks_usec()
        var fresh: int = _router.call("warm")
        var scenes_ms := int((Time.get_ticks_usec() - tw) / 1000)
        tw = Time.get_ticks_usec()
        var plates: int = Stage.warm()
        print("PERF warm  ScreenRouter.warm(): %d scene(s) compiled ahead in %d ms; SceneStage.warm(): %d texture(s) in %d ms (--warm; Boot's overlay pays both in the game)"
            % [fresh, scenes_ms, plates, int((Time.get_ticks_usec() - tw) / 1000)])
    print("")
    _phase = "mount"
    return false


## A fixed amount of GDScript work, timed, so two runs of this probe can be
## compared: a row that doubled on a run whose calibration also doubled is the
## clock, not the screen.
func _calibrate() -> int:
    var t := Time.get_ticks_usec()
    var acc := 0
    for i in CALIB_ITERS:
        acc = (acc * 31 + i) % 1000003
    if acc < 0:
        print(acc)  # never; keeps the loop's result observable
    return int((Time.get_ticks_usec() - t) / 1000)


## The router mounts the screen FULL_RECT (as the game does under Boot's
## host); pin it the way shot.gd does, and say so if the size still disagrees.
func _pin_screen() -> void:
    var screen: Control = _router.call("current_screen")
    if screen == null:
        return
    screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
    screen.position = Vector2.ZERO
    screen.size = _host.size
    if screen.size != _host.size:
        print("  note  %s root is %s, host is %s" % [String(_row["label"]), screen.size, _host.size])


func _record() -> void:
    var n := maxi(_n, 1)
    var mean := _sum / float(n)
    var gpu := _gpu_sum / float(n)
    _row["frame_ms"] = mean
    _row["max_ms"] = _max
    _row["gpu_ms"] = gpu
    _row["n"] = _n
    _rows.append(_row)
    var label := String(_row["label"])
    # The row carries its own verdict (`!`), so the rows alone — which
    # verify.sh prints on every full run — say which screen is over.
    var mark := ""
    if bool(_row["judged"]):
        if float(_row["mount_ms"]) > MOUNT_BUDGET_MS:
            mark += "  ! mount > %.0f" % MOUNT_BUDGET_MS
            _warns.append("  WARN  %-32s mount %.1f ms > %.0f ms (docs/13 §12.1: screen switch settled)"
                % [label, float(_row["mount_ms"]), MOUNT_BUDGET_MS])
        if mean > FRAME_BUDGET_MS:
            mark += "  ! frame > %.1f" % FRAME_BUDGET_MS
            _warns.append("  WARN  %-32s frame %.2f ms mean > %.1f ms (60 fps at %dx%d)"
                % [label, mean, FRAME_BUDGET_MS, _size.x, _size.y])
    print("PERF  %-32s mount %7.1f ms (goto %6.1f)   frame %5.2f ms mean %6.2f max   gpu %4.2f ms   n=%d%s"
        % [label, float(_row["mount_ms"]), float(_row["goto_ms"]), mean, _max, gpu, _n, mark])
    if _split and _row.has("split"):
        print(_split_line(_row))
        print(_stage_line(_row))


## The third line: SceneStage._build's sections, in ms, for every stage the
## turn built (the `s_*` laps), so a stage's cost is read by layer.
func _stage_line(row: Dictionary) -> String:
    var st: Dictionary = row["stage_profile"]
    var parts: Array[String] = []
    for k in st.keys():
        var key := String(k)
        if key.begins_with("s_"):
            parts.append("%s %.1f" % [key.substr(2), float(int(st[k])) / 1000.0])
    return "      stage  " + "  ".join(parts)


## The --split line under a row: goto()'s phases in ms, then what the shell
## and the stage cost inside build() (count in brackets), then the strong
## cache's hits/misses for this turn. `ms(k)` reads a microsecond field.
func _split_line(row: Dictionary) -> String:
    var sp: Dictionary = row["split"]
    var fp: Dictionary = row["frame_profile"]
    var st: Dictionary = row["stage_profile"]
    var ms := func(d: Dictionary, k: String) -> float: return float(int(d.get(k, 0))) / 1000.0
    return ("      split  clear %5.1f  load %4.1f  inst %5.1f  build %6.1f  enter %5.1f  focus %4.1f  | in build: frame %5.1f [%d]  stage %5.1f [%d]  | cache tex %d/%d frames %d/%d json %d/%d (hit/miss)"
        % [ms.call(sp, "clear"), ms.call(sp, "load"), ms.call(sp, "instantiate"), ms.call(sp, "build"),
            ms.call(sp, "on_enter"), ms.call(sp, "focus"),
            ms.call(fp, "build_usec"), int(fp.get("builds", 0)), ms.call(st, "build_usec"), int(st.get("builds", 0)),
            int(st.get("tex_hits", 0)), int(st.get("tex_misses", 0)), int(st.get("frames_hits", 0)),
            int(st.get("frames_misses", 0)), int(st.get("json_hits", 0)), int(st.get("json_misses", 0))])


func _finish() -> bool:
    var total_s := float(Time.get_ticks_usec() - _t_run) / 1000000.0
    var judged := 0
    for r in _rows:
        if bool(r["judged"]):
            judged += 1
    print("")
    print("PERF clock  calibration loop %d ms (%d turns); fixture %d ms; %d row(s) in %.1f s"
        % [_calib_ms, CALIB_ITERS, _fixture_ms, _rows.size(), total_s])
    print("PERF clock  caveat: this laptop ran the suite in 33 s boosting and 177 s at base clock — absolute times vary ~5x between runs; compare rows within one run, and runs by their calibration figure")
    if _warns.is_empty():
        print("PERF OK  %d screen(s) within %.0f ms mount / %.1f ms mean frame at %dx%d"
            % [judged, MOUNT_BUDGET_MS, FRAME_BUDGET_MS, _size.x, _size.y])
        _quit(0)
        return true
    print("PERF WARN  %d row(s) over budget (%d screen(s) judged):" % [_warns.size(), judged])
    for w in _warns:
        print(w)
    _quit(1)
    return true
