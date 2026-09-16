extends Node
## Autoload: owns which screen is on the desk.
##
## docs/13 §2 M5 — **"The desk does not move."** No screen slides in from
## off-camera; screens are *pages* and they change in place. That is why this
## router has no transition animation and never will: the only camera move in
## the whole game is the town push-in, which docs/02 owns.
##
## The router does not create its own CanvasLayer. Boot owns the window and
## registers a host Control; screens are added as children of that host. Keeping
## the host external means the boot overlay can sit above screens during load
## without fighting layer ordering.
##
## Screens are plain `Control` scenes. Two optional hooks, both called only when
## the scene actually implements them:
##   on_enter()  — after the screen is in the tree and visible
##   on_exit()   — before it is removed
##
## Autoloads are reached by node path (`/root/ScreenRouter`), never by the global
## identifier, per BUILD_STATE invariant 7: Godot's global registry is not
## reliably present in headless runs, and this project has been bitten by it.

signal screen_changed(path: String)
signal navigation_failed(path: String, reason: String)

## docs/13 §13.1's one global binding: "`Esc` — Back one level; from the town,
## opens Settings." Both halves are facts about the STACK, which only the router
## knows, so they live here rather than in eleven screens' own key handlers.
const TOWN_SCENE := "res://game/screens/Town.tscn"
const SETTINGS_SCENE := "res://game/screens/Settings.tscn"
## §13.1's other global row, "`F1` — Codex (S16)". S16 is not built, so this path
## is where it is expected to land and every use of it is guarded by
## `screen_exists()`: F1 is inert until the scene appears, and works the day it
## does. Whoever builds S16 should confirm the filename against this constant.
const CODEX_SCENE := "res://game/screens/Codex.tscn"

## Both under game/core (the router imports nothing from game/ui, see
## SHELL_FOCUS_ORDER): the autoload lookup, and the static window applier
## `toggle_fullscreen` shares with Boot and the Options screen.
const Services = preload("res://game/core/Services.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")

var _host: Control = null
var _stack: Array[String] = []
var _current: Control = null
## The last `_load_into_host()`'s cost by phase, in microseconds (W5-MOUNT):
## `clear` (the old screen's on_exit + remove_child + queue_free), `load` (the
## PackedScene), `instantiate`, `build`, `on_enter`, `focus` (the shell wiring
## and the initial grab) and `total`. Seven clock reads a page turn; read by
## tools/perf_probe.gd --split, which is how the mount budget was split into
## the costs that were actually there instead of the ones that were suspected.
var _split: Dictionary = {}
## The screens' PackedScenes, held strongly (W5-MOUNT). Godot's resource cache
## is weak: once a screen instance is freed nothing holds its PackedScene, so
## the scene — and the GDScript it references — is dropped, and the next visit
## re-parses and re-compiles the screen's script. tools/perf_probe.gd --split
## measured that `load()` at 45-140 ms per page turn (Guildhall 134, RaidView
## 140), the largest single cost in the mount budget. Thirteen small scene
## files and their scripts, kept for the life of the process.
var _scenes: Dictionary = {}

## Every screen the game turns to — the list `warm()` compiles behind the boot
## overlay. Explicit, never a directory walk (LESSONS); the same thirteen as
## tests/unit/a11y_smoke.gd's SCREENS, and tests/unit/test_perf_mount.gd
## asserts the two lists agree so neither can quietly grow without the other.
const WARM_SCENES := [
    "res://game/screens/MainMenu.tscn",
    "res://game/screens/Town.tscn",
    "res://game/screens/AdventureBoard.tscn",
    "res://game/screens/Tavern.tscn",
    "res://game/screens/Guildhall.tscn",
    "res://game/screens/Market.tscn",
    "res://game/screens/RaidPrep.tscn",
    "res://game/screens/RaiderDetail.tscn",
    "res://game/screens/RaidView.tscn",
    "res://game/screens/Results.tscn",
    "res://game/screens/Completion.tscn",
    "res://game/screens/Settings.tscn",
    "res://game/screens/LoadSave.tscn",
]


## Boot calls this once. Until it does, every navigation fails loudly rather
## than silently doing nothing — a router that quietly drops `goto()` produces a
## black window and no error, which is the worst possible failure to debug.
func register_host(host: Control) -> void:
    _host = host


func has_host() -> bool:
    return is_instance_valid(_host)


func current_path() -> String:
    return _stack[-1] if not _stack.is_empty() else ""


## The screen beneath the current one, or "" at the root. Settings reads it to
## stand on the stage of the screen it was opened over (docs/15 BL-78, spec 09
## §4.5: "it inherits the plate of the screen it was opened from") — a fact
## about the STACK, so it lives here with `current_path()`.
func previous_path() -> String:
    return _stack[-2] if _stack.size() >= 2 else ""


func current_screen() -> Control:
    return _current


func depth() -> int:
    return _stack.size()


## A copy of the last page turn's phase costs (see `_split`); {} before the
## first one. Microseconds, integer.
func last_split() -> Dictionary:
    return _split.duplicate()


## Load (and so compile) the given scenes now and keep them (`_scenes`), so
## the player's first page turn to each does not pay for its script: 45-140
## ms a screen, measured — Guildhall 127, RaidView 144, about a second for
## the thirteen, which belongs behind Boot's overlay and not on the first
## click. Returns how many were loaded fresh (0 when every one was already
## held). A missing path is skipped; `goto()` reports it if ever asked for.
func warm(paths: Array = WARM_SCENES) -> int:
    var fresh := 0
    for p in paths:
        var path := String(p)
        if _scenes.has(path) or not ResourceLoader.exists(path):
            continue
        var packed = load(path)
        if packed is PackedScene:
            _scenes[path] = packed
            fresh += 1
    return fresh


## True when a screen scene exists on disk. Screens use this to disable a
## navigation control with an honest reason instead of offering a button that
## leads nowhere (docs/13 §7: a disabled control is never a mystery).
static func screen_exists(path: String) -> bool:
    return ResourceLoader.exists(path)


# ---------------------------------------------------------------- navigation

## Replace the whole stack. Use for top-level moves: Boot -> Menu, Menu -> Town.
func goto(path: String) -> bool:
    if not _load_into_host(path):
        return false
    _stack = [path]
    screen_changed.emit(path)
    return true


## Put a screen on top of the current one, keeping the stack so `pop()` returns.
func push(path: String) -> bool:
    if not _load_into_host(path):
        return false
    _stack.append(path)
    screen_changed.emit(path)
    return true


## Return to the screen underneath. Returns false at the root — the caller
## decides what "back" means there, because the router must not quit the game.
func pop() -> bool:
    if _stack.size() < 2:
        return false
    var leaving: String = _stack.pop_back()
    var target: String = _stack[-1]
    if not _load_into_host(target):
        # Restore the stack: failing to go back must not strand the player on a
        # screen the stack no longer believes in.
        _stack.append(leaving)
        return false
    screen_changed.emit(target)
    return true


## What `Esc` means, as one function, so the key and a screen's own Back button
## cannot drift apart. Returns true when it actually moved.
##
## At the root it must NEVER quit the game — that is the caller's decision, and
## a router that exits the process on a stray keypress is the kind of bug that
## only shows up in a playtest. On the town, §13.1 says it opens Settings; on
## any other root it is inert.
func back() -> bool:
    if _stack.size() >= 2:
        return pop()
    if current_path() == TOWN_SCENE and screen_exists(SETTINGS_SCENE):
        return push(SETTINGS_SCENE)
    return false


# ---------------------------------------------------------------- keyboard

## `_unhandled_input` and not `_input`: the focused control's own `_gui_input`
## runs first, so a screen that wants `Esc` for something narrower — dismissing
## its own modal, cancelling an edit — still gets first refusal and this only
## sees the keys nobody claimed. docs/13 §13.1 also promises "focus never traps
## in a modal without a visible way out", and this is that way out.
func _unhandled_input(event: InputEvent) -> void:
    var acted: bool = false
    if event.is_action_pressed("ui_cancel"):
        # SHIP-03's Esc rule (the attempts ruling, RULINGS §2 #6 / BL-139):
        # a screen that declares `handles_cancel() -> bool` and answers true
        # owns Esc for now — RaidView mid-replay, where Esc means "skip to the
        # post-mortem", never "pop the account and leave the report unread".
        # Duck-typed by `has_method`, so a screen that declares nothing keeps
        # docs/13 §13.1's global binding exactly as before.
        if screen_handles_cancel():
            return
        acted = back()
    elif event.is_action_pressed("nav_codex"):
        acted = codex()
    elif event.is_action_pressed("nav_settings"):
        acted = settings()
    elif event.is_action_pressed("nav_fullscreen"):
        acted = toggle_fullscreen()
    if acted and is_inside_tree():
        get_viewport().set_input_as_handled()


## Whether the screen on the desk has claimed Esc for itself right now. True
## only when it declares `handles_cancel()` AND answers true this instant — a
## RaidView whose account has finished answers false and Esc is the router's
## again. Public so a test can ask the same question the key handler does.
func screen_handles_cancel() -> bool:
    if _current == null or not is_instance_valid(_current):
        return false
    if not _current.has_method("handles_cancel"):
        return false
    return bool(_current.call("handles_cancel"))


## SHIP-06: `F11` / `Alt+Enter` swap the window between the two modes of
## docs/13 §15.1's "window mode" row from anywhere, the way every desktop game
## does. Here and not in a screen because it is about the WINDOW, which no
## screen owns; the value goes through GameSettings so the Options row shows
## the mode the window is actually in, and the file picks it up on quit
## (§15.1: written on Apply and on quit). Returns true when it moved.
func toggle_fullscreen() -> bool:
    var settings = Services.find(self, "GameSettings")
    if settings == null:
        return false
    var current := String(settings.get_value("window_mode"))
    var next: String = "windowed" if current == "borderless" else "borderless"
    settings.set_value("window_mode", next)
    # No window (a harness outside the tree): the applier is a no-op and the
    # setting still flips, which is what the Options row then shows.
    GameSettings.apply_window_mode(get_window(), next, bool(settings.get_value("vsync")))
    return true


## docs/13 §13.2's `Start` row — "Settings (S15)", whose stated keyboard
## equivalent is "`Esc` from the town", i.e. `back()` above. The gamepad gets a
## direct route because it has no Esc, and it opens Settings from ANYWHERE, not
## only the town, which is what the row says. Inert once Settings is on the desk
## so holding Start cannot stack it — `back()`/`B` is the way out, per §13.1.
func settings() -> bool:
    if current_path() == SETTINGS_SCENE or not screen_exists(SETTINGS_SCENE):
        return false
    return push(SETTINGS_SCENE)


## §13.1's `F1`. Inert while S16 does not exist rather than pushing a scene that
## is not there — `push()` on a missing path is a loud failure, and a keyboard
## row that shouts is worse than one that waits.
func codex() -> bool:
    if not screen_exists(CODEX_SCENE) or current_path() == CODEX_SCENE:
        return false
    return push(CODEX_SCENE)


# ---------------------------------------------------------------- initial focus

## docs/13 §13 makes "every screen operable with no mouse" blocking, and a
## keyboard has nowhere to start until something holds focus. A screen declares
## its own answer with `default_focus() -> Control`; docs/13 gives two of them
## explicitly (§11.4: after a wipe "`Try again` is left and **default-focused**";
## §13.2: on the town "one hotspot is always focused, even with no input").
##
## The fallback — first focusable control in tree order — is what keeps a screen
## that declares nothing operable rather than dead, and it is why this landed
## without editing eleven screens.
static func initial_focus_target(screen: Control) -> Control:
    if not is_instance_valid(screen):
        return null
    var declared: Control = null
    if screen.has_method("default_focus"):
        var d = screen.call("default_focus")
        if d is Control:
            declared = d
    if _can_focus(declared):
        return declared
    # The shell's own reading order beats tree order: docs/13 §13.1 ends "focus
    # order always follows reading order: rail, then header, then content, then
    # commit", and Frame.build() adds the scene host BEFORE the rail so the
    # panels draw over it — so tree order opens a screen in the middle of its
    # content rather than at the rail.
    var entry: Control = _shell_focus_entry(screen)
    if _can_focus(entry):
        return entry
    return _first_focusable(screen)


## The two hooks game/ui/Frame.gd leaves on a screen that uses the dashboard
## shell. They are read by name and never imported: nothing under game/core
## preloads game/ui, and inverting that for the focus model would make the
## router depend on the widget kit. A screen with no shell has no meta and both
## calls below are no-ops.
const SHELL_FOCUS_ORDER := "frame_focus_order"
const SHELL_FOCUS_ENTRY := "frame_focus_entry"


static func _shell_hook(screen: Control, key: String) -> Callable:
    if not is_instance_valid(screen) or not screen.has_meta(key):
        return Callable()
    var cb = screen.get_meta(key)
    return cb if cb is Callable and (cb as Callable).is_valid() else Callable()


static func _shell_focus_entry(screen: Control) -> Control:
    var cb: Callable = _shell_hook(screen, SHELL_FOCUS_ENTRY)
    if cb.is_null():
        return null
    var c = cb.call()
    return c if c is Control else null


## docs/13 §13.1's Tab/arrow model, applied to the live screen. Before this the
## mechanism existed and had no caller, so the shipped Tab order was still
## accidental tree order — measured on the Adventure's Board, Tab cycled the six
## rail buttons and never left them, which is the trap §13.1 forbids.
##
## Called after `on_enter()`, because that is the first moment the screen's
## content is in the tree. A screen that rebuilds a list afterwards must call
## `Frame.focus_order()` again itself; this wires what exists at entry.
static func wire_shell_focus(screen: Control) -> int:
    var cb: Callable = _shell_hook(screen, SHELL_FOCUS_ORDER)
    if cb.is_null():
        return 0
    var regions = cb.call()
    return (regions as Array).size() if regions is Array else 0


## Deliberately does NOT require `is_inside_tree()`, so that the answer is a
## pure function of the screen and the test suite can ask it: run_tests.gd does
## its whole run from `_initialize`, before the root window enters the tree,
## which is the same reason its docstring notes `_ready` never fires there. The
## engine's own precondition is enforced at the one place that actually grabs.
##
## `== FOCUS_ALL` and not `!= FOCUS_NONE`: `FOCUS_CLICK` (1) and
## `FOCUS_ACCESSIBILITY` (3, LinkButton's default in 4.7.1) both refuse
## `grab_focus()`. Accepting them let this function hand the grab below a
## control the engine would not take, so the screen opened with NOTHING
## focused — the blocking requirement quietly unmet, with only a warning on
## stderr to show it.
static func _can_focus(c) -> bool:
    if not (c is Control) or not is_instance_valid(c):
        return false
    var ctl: Control = c
    if ctl.focus_mode != Control.FOCUS_ALL or not ctl.visible:
        return false
    if ctl.is_inside_tree() and not ctl.is_visible_in_tree():
        return false
    if ctl is BaseButton and (ctl as BaseButton).disabled:
        return false
    return true


static func _first_focusable(n: Node) -> Control:
    if _can_focus(n):
        return n
    if n is Control and not (n as Control).visible:
        return null
    for c in n.get_children():
        var found: Control = _first_focusable(c)
        if found != null:
            return found
    return null


# ---------------------------------------------------------------- internals

func _load_into_host(path: String) -> bool:
    if not has_host():
        _fail(path, "no host registered — Boot must call register_host() first")
        return false
    if not ResourceLoader.exists(path):
        _fail(path, "no such scene")
        return false

    var t0 := Time.get_ticks_usec()
    var packed = _scenes.get(path, null)
    if packed == null:
        packed = load(path)
        if packed == null or not (packed is PackedScene):
            _fail(path, "not a PackedScene")
            return false
        _scenes[path] = packed
    var t1 := Time.get_ticks_usec()

    var next = packed.instantiate()
    if not (next is Control):
        _fail(path, "screen root must be a Control, got %s" % next.get_class())
        next.queue_free()
        return false
    var t2 := Time.get_ticks_usec()

    _clear_current()
    var t3 := Time.get_ticks_usec()

    _current = next
    _current.set_anchors_preset(Control.PRESET_FULL_RECT)
    _host.add_child(_current)
    # Screens expose an idempotent build() because `_ready` does not fire when a
    # SceneTree script owns the root (the test runner and tools/ both do). Calling
    # it here makes "mounted" and "populated" the same event in every context.
    if _current.has_method("build"):
        _current.call("build")
    var t4 := Time.get_ticks_usec()
    if _current.has_method("on_enter"):
        _current.call("on_enter")
    var t5 := Time.get_ticks_usec()
    # After on_enter, not before: a screen that builds its content there would
    # otherwise have nothing focusable to offer yet. The in-tree/visible guard
    # is the engine's own precondition for grab_focus() — under `--script`
    # harnesses (the test runner, tools/) the root window never enters the tree,
    # and calling it there is a hard error, not a no-op.
    wire_shell_focus(_current)
    var focus_here: Control = initial_focus_target(_current)
    if focus_here != null and focus_here.is_inside_tree() and focus_here.is_visible_in_tree():
        focus_here.grab_focus()
    var t6 := Time.get_ticks_usec()
    _split = {"load": t1 - t0, "instantiate": t2 - t1, "clear": t3 - t2, "build": t4 - t3,
        "on_enter": t5 - t4, "focus": t6 - t5, "total": t6 - t0}
    return true


func _clear_current() -> void:
    if not is_instance_valid(_current):
        _current = null
        return
    if _current.has_method("on_exit"):
        _current.call("on_exit")
    # Detach NOW so the replacement never overlaps it, but delete on the next
    # idle frame. A screen is usually replaced from inside one of its own button
    # handlers (Depart does exactly this), and freeing an object while its own
    # signal is still on the stack is refused by the engine — which left the
    # navigation half-done and the player on the wrong screen.
    _host.remove_child(_current)
    _current.queue_free()
    _current = null


func _fail(path: String, reason: String) -> void:
    push_error("ScreenRouter: cannot show '%s' — %s" % [path, reason])
    navigation_failed.emit(path, reason)
