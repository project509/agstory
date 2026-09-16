extends SceneTree
## The live keyboard-navigation check: docs/13 §13's blocking row, asserted by
## ASKING GODOT rather than by reading back the wiring we wrote.
##
##   godot --headless --path . --script res://tests/unit/a11y_smoke.gd
##
## WHY THIS IS NOT A test_*.gd FILE. tests/run_tests.gd does its whole run from
## `MainLoop::_initialize`, which is before the root window enters the tree —
## measured: `root.is_inside_tree()` is false there, `grab_focus()` fails the
## engine's `!is_inside_tree()` check outright, and `find_next_valid_focus()`
## errors with "Parameter data.tree is null". So the three facts that actually
## matter — something IS focused, Tab LEAVES the rail, the ring RETURNS —
## cannot be expressed in the suite at all. They can be expressed from
## `_process`, which is where tools/shot.gd does its work for the same reason,
## so they live here as a second instrument with its own exit code. The name
## does not begin with `test_`, so run_tests.gd's discovery skips it.
##
## tests/unit/test_a11y.gd asserts the WIRING (`focus_next`, `focus_neighbor_*`,
## `focus_mode`) inside the suite; this asserts the BEHAVIOUR. Both are needed:
## the wiring test cannot see an engine that refuses a stop, and this cannot run
## where the suite runs.
##
## What it checks, per screen, against docs/13 §13.1:
##   1. "every screen operable with no mouse" needs a starting point — after
##      `router.goto(path)` the viewport has exactly one focus owner, and it is
##      inside the screen.
##   2. "focus order always follows reading order: rail, then header, then
##      content, then commit" — the owner is the rail's first item on every
##      screen that has a rail.
##   3. "Focus never traps" — stepping `find_next_valid_focus()` leaves the rail
##      and comes back to where it started, visiting each stop once.
##   4. "Arrows — move within the focused group" — the rail's arrow ring steps
##      every rail item and wraps.

const Router = preload("res://game/core/ScreenRouter.gd")
## The same seeded guild the art pass shoots against. Every screen is swept
## TWICE: once with no guild — where every list is empty, which is the state the
## rail trap actually lives in, measured — and once with this applied, where the
## lists are full and there is real content to reach. A one-pass check would
## miss whichever half it skipped.
const Fixture = preload("res://tools/fixture_reference.gd")

const SCREENS := [
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

## UI-33 / CRITIC-R4 / docs/13 §11.4: the two fight screens name the control
## focus must open on — Pause on the account (the one control a watching
## player needs), "Try again" on the wipe page, the loot's suggested split on
## a clear. Keyed by pass so the wipe fixture and the clear pass each assert
## their own answer; a screen absent from a pass's table keeps the general
## rules only.
const ENTRY_CONTROL := {
    "fixture": {
        "res://game/screens/RaidView.tscn": "Pause",
        "res://game/screens/Results.tscn": "Try again",
    },
    "clear": {
        "res://game/screens/Results.tscn": "Give as Suggested — ",
    },
}
## The third pass (the clear): only the screens whose entry control differs
## on a clear are mounted again, on `Fixture.apply_clear`.
const CLEAR_SCREENS := ["res://game/screens/Results.tscn"]

## Frames to let the containers lay out before measuring. An un-laid-out
## container reports every child at its own origin, which silently fakes both
## geometry and clipping answers.
const SETTLE_FRAMES := 12

var _queue: Array = []
var _n := 0
var _mounted_at := -1
var _path := ""
var _host: Control = null
var _router = null
var _failures: Array[String] = []
var _checked := 0
var _skipped: Array[String] = []
## Which sweep is running: "empty" (no guild — every list is empty, which is
## where the rail trap lives) then "fixture" (the reference guild).
var _pass := "empty"


func _initialize() -> void:
    # The fixture pass records a raid (`Fixture.apply(state, null, true)`), and
    # record_attempt autosaves — into the real save dir unless it is moved.
    var SaveGame = load("res://game/core/SaveGame.gd")
    SaveGame.SAVE_DIR = "user://a11y_saves"
    SaveGame.purge_all()
    _queue = SCREENS.duplicate()


func _process(_dt: float) -> bool:
    _n += 1
    if _path == "":
        if _queue.is_empty():
            if _pass == "empty":
                var state := root.get_node_or_null("GameState")
                if state == null:
                    print("  FATAL  the GameState autoload is missing")
                    quit(2)
                    return true
                Fixture.apply(state, null, true)
                _pass = "fixture"
                _queue = SCREENS.duplicate()
                print("")
                return false
            if _pass == "fixture":
                # The clear: the report's other branch, where the entry
                # control is the loot's crimson split rather than Try again.
                var state2 := root.get_node_or_null("GameState")
                if state2 != null and Fixture.apply_clear(state2) >= 0:
                    _pass = "clear"
                    _queue = CLEAR_SCREENS.duplicate()
                    print("")
                    return false
                _failures.append("[clear] the clear fixture found no clearing seed")
            return _finish()
        _path = _queue.pop_front()
        if not Router.screen_exists(_path):
            _skipped.append("%s (no such scene)" % _path)
            _path = ""
            return false
        _mount(_path)
        _mounted_at = _n
        return false
    if _n - _mounted_at < SETTLE_FRAMES:
        return false
    _check(_path)
    _teardown()
    _path = ""
    return false


func _finish() -> bool:
    print("")
    print("──────────────────────────────────────────────")
    for s in _skipped:
        print("  SKIP  " + s)
    if _failures.is_empty():
        print("A11Y SMOKE PASSED   %d screen mount(s)" % _checked)
        print("──────────────────────────────────────────────")
        quit(0)
        return true
    for f in _failures:
        print("  FAIL  " + f)
    print("A11Y SMOKE FAILED   %d failure(s) over %d screen mount(s)" % [_failures.size(), _checked])
    print("──────────────────────────────────────────────")
    quit(1)
    return true


func _mount(path: String) -> void:
    # A full-rect host at the reference size, because focus is refused to a
    # control that is not visible in the tree and a zero-size host hides
    # everything inside it.
    _host = Control.new()
    _host.name = "SmokeHost"
    _host.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _host.position = Vector2.ZERO
    _host.size = Vector2(
        float(ProjectSettings.get_setting("display/window/size/viewport_width", 1536)),
        float(ProjectSettings.get_setting("display/window/size/viewport_height", 1024)))
    root.add_child(_host)
    _router = Router.new()
    _router.name = "SmokeRouter"
    root.add_child(_router)
    _router.register_host(_host)
    if not _router.call("goto", path):
        _skipped.append("%s (goto refused)" % path)


func _teardown() -> void:
    if _router != null:
        _router.queue_free()
    if _host != null:
        _host.queue_free()
    _router = null
    _host = null


func _fail(path: String, msg: String) -> void:
    _failures.append("[%s] %s :: %s" % [_pass, path.get_file(), msg])


func _check(path: String) -> void:
    var screen: Control = _router.call("current_screen")
    if screen == null:
        return
    _checked += 1

    # ---- 1. something is focused, and it is inside this screen -------------
    var owner: Control = root.gui_get_focus_owner()
    if owner == null:
        _fail(path, "nothing is focused after goto() — the screen is mouse-only")
        return
    if not (owner == screen or screen.is_ancestor_of(owner)):
        _fail(path, "the focus owner is outside the screen: %s" % owner.name)
    if owner.focus_mode != Control.FOCUS_ALL:
        _fail(path, "the focus owner's mode is %d, not FOCUS_ALL" % owner.focus_mode)

    # ---- 1b. the screens that name their entry control open on it ---------
    var wanted: String = String(ENTRY_CONTROL.get(_pass, {}).get(path, ""))
    if not wanted.is_empty() and not _text(owner).begins_with(wanted):
        _fail(path, "focus opens on '%s', not on '%s' (default_focus, UI-33 / docs/13 §11.4)"
            % [_text(owner), wanted])

    var stops: Array = []
    _walk(screen, stops)

    # ---- 2. reading order: the rail comes first (§13.1) --------------------
    var rail: Array = []
    for c in stops:
        if String((c as Control).name).begins_with("Nav_"):
            rail.append(c)
    if not rail.is_empty() and owner != rail[0]:
        _fail(path, "focus opens on '%s', not the rail's first item '%s' (§13.1 reading order)"
            % [_text(owner), _text(rail[0])])

    # ---- 3. the Tab ring returns, and it is not the rail on its own --------
    var chain: Array = [owner]
    var cur: Control = owner
    for _i in stops.size() + 2:
        var nxt: Control = cur.find_next_valid_focus()
        if nxt == null:
            _fail(path, "Tab from '%s' goes nowhere" % _text(cur))
            break
        if nxt == chain[0]:
            break
        if chain.has(nxt):
            _fail(path, "the Tab ring re-enters '%s' before closing: %s"
                % [_text(nxt), _names(chain)])
            break
        chain.append(nxt)
        cur = nxt
    if cur != null and cur.find_next_valid_focus() != chain[0] and not chain.is_empty():
        _fail(path, "the Tab ring does not close: %s" % _names(chain))
    var left_rail := false
    for c in chain:
        if not String((c as Control).name).begins_with("Nav_"):
            left_rail = true
    # The population that must be reachable is every ENABLED BUTTON, not every
    # current Tab stop: a button the engine refuses (`FOCUS_CLICK`,
    # `FOCUS_ACCESSIBILITY`) is absent from `stops`, so comparing against
    # `stops` would let the exact defect this checks for hide the evidence of
    # itself. Measured before the fix: the Adventure's Board had six rail stops
    # and six focusables, so a stops-based guard passed while the board's only
    # other button — the "Back to town" link — sat outside the Tab chain.
    if not rail.is_empty() and _buttons_outside_rail(screen) > 0 and not left_rail:
        _fail(path, "Tab never leaves the rail (§13.1 forbids the trap): %d rail stop(s), %d button(s) outside it, ring=%s"
            % [rail.size(), _buttons_outside_rail(screen), _names(chain)])

    # ---- 6. every button is a keyboard stop (§13.2, the absolute rule) -----
    var refused: Array = []
    _pointer_only_buttons(screen, refused)
    if not refused.is_empty():
        _fail(path, "%d enabled button(s) the keyboard cannot reach at all — focus_mode is not FOCUS_ALL: %s"
            % [refused.size(), _names(refused)])

    # Reported, not failed: a plain Control wired to `gui_input` is also a
    # §13.2 breach, but the fix is per-screen (make the row a real button or
    # give it a focusable proxy) and lives in game/screens/ and game/ui/Cards.gd,
    # not in the shell. build/plan/handoff-a11y-keys.md carries them.
    var gestures: Array = []
    _pointer_only_gestures(screen, gestures)
    if not gestures.is_empty():
        print("  warn %-8s %-22s %d pointer-only gesture target(s): %s"
            % [_pass, path.get_file(), gestures.size(), _names(gestures)])

    # ---- 4. the arrows step within the rail and wrap (§13.1) --------------
    if rail.size() > 1:
        var seen: Array = [rail[0]]
        var a: Control = rail[0]
        for _i in rail.size() + 1:
            var nb: Control = a.find_valid_focus_neighbor(SIDE_BOTTOM)
            if nb == null:
                _fail(path, "the down-arrow dead-ends at '%s'" % _text(a))
                break
            if nb == rail[0]:
                break
            seen.append(nb)
            a = nb
        if seen.size() != rail.size():
            _fail(path, "the rail's arrow ring visits %d of %d items: %s"
                % [seen.size(), rail.size(), _names(seen)])

    # ---- 5. every stop is reachable from the entry (§13.2's absolute rule) -
    # "no interaction may exist only as a pointer gesture". Tab visits one
    # control per region and the arrows move inside it, so reachability is the
    # closure of BOTH — asked of the engine, five moves at a time.
    var reach: Dictionary = {owner: true}
    var frontier: Array = [owner]
    while not frontier.is_empty():
        var c: Control = frontier.pop_back()
        var moves: Array = [c.find_next_valid_focus(), c.find_prev_valid_focus(),
            c.find_valid_focus_neighbor(SIDE_TOP), c.find_valid_focus_neighbor(SIDE_BOTTOM),
            c.find_valid_focus_neighbor(SIDE_LEFT), c.find_valid_focus_neighbor(SIDE_RIGHT)]
        for m in moves:
            if m != null and not reach.has(m):
                reach[m] = true
                frontier.append(m)
    var orphans: Array = []
    for c in stops:
        if not reach.has(c):
            orphans.append(c)
    if not orphans.is_empty():
        _fail(path, "%d focusable control(s) no keyboard move reaches: %s"
            % [orphans.size(), _names(orphans)])

    # `reachable` can exceed `focusable`: Godot's own walk also stops on a
    # DISABLED button (its focus_mode is untouched by `disabled`), which the
    # list above deliberately excludes — docs/13 §7 puts the reason in an
    # adjacent Label, so the dead control itself need not be a stop. Printed so
    # the difference is explained rather than mysterious.
    print("  ok  %-8s %-22s owner='%s'  tab ring=%d  rail=%d  focusable=%d  reachable=%d  disabled=%d"
        % [_pass, path.get_file(), _text(owner), chain.size(), rail.size(), stops.size(),
        reach.size(), _disabled_stops(screen)])


func _buttons_outside_rail(n: Node) -> int:
    var count := 0
    if n is Control and not (n as Control).is_visible_in_tree():
        return 0
    if n is BaseButton and not (n as BaseButton).disabled \
            and not String(n.name).begins_with("Nav_"):
        count += 1
    for c in n.get_children():
        count += _buttons_outside_rail(c)
    return count


func _pointer_only_buttons(n: Node, out: Array) -> void:
    if n is Control and not (n as Control).is_visible_in_tree():
        return
    if n is BaseButton and not (n as BaseButton).disabled \
            and (n as Control).focus_mode != Control.FOCUS_ALL:
        out.append(n)
    for c in n.get_children():
        _pointer_only_buttons(c, out)


func _pointer_only_gestures(n: Node, out: Array) -> void:
    if n is Control and not (n as Control).is_visible_in_tree():
        return
    if n is Control and not (n is BaseButton):
        var ctl: Control = n
        if ctl.gui_input.get_connections().size() > 0 \
                and ctl.focus_mode != Control.FOCUS_ALL:
            out.append(ctl)
    for c in n.get_children():
        _pointer_only_gestures(c, out)


func _disabled_stops(n: Node) -> int:
    var count := 0
    if n is Control and not (n as Control).is_visible_in_tree():
        return 0
    if n is BaseButton and (n as BaseButton).disabled \
            and (n as Control).focus_mode == Control.FOCUS_ALL:
        count += 1
    for c in n.get_children():
        count += _disabled_stops(c)
    return count


func _names(a: Array) -> String:
    var out: Array = []
    for c in a:
        out.append(_text(c))
    return " -> ".join(out)


func _text(c: Control) -> String:
    if c == null:
        return "<null>"
    if c is Button and not (c as Button).text.is_empty():
        return (c as Button).text
    if c is LinkButton and not (c as LinkButton).text.is_empty():
        return (c as LinkButton).text
    # An icon-only button prints as its class and name, because "focus opens on
    # ''" is not a diagnosable line.
    return "<%s %s>" % [c.get_class(), c.name]


## Every control the ENGINE would stop on: FOCUS_ALL, visible in the tree, and
## not a disabled button.
func _walk(n: Node, out: Array) -> void:
    if n is Control and not (n as Control).is_visible_in_tree():
        return
    if n is Control and (n as Control).focus_mode == Control.FOCUS_ALL:
        if not (n is BaseButton and (n as BaseButton).disabled):
            out.append(n)
    for c in n.get_children():
        _walk(c, out)
