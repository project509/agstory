extends "res://tests/TestCase.gd"
## W4-HYGIENE / TOWN-17: the sidebar panel fits its host on every route.
##
## THE DEFECT THIS GUARDS. `Frame.sidebar()` sets the panel's `size` to the
## host's, but a PanelContainer cannot be smaller than its content's minimum,
## so a column that wants more than the 635px between SIDEBAR_TOP and
## SIDEBAR_BOTTOM grows the panel straight through the strip band (the Tavern's
## rim sat at y≈765 against a 714 bottom; the Board's at 732). No screen test
## noticed, because a clipped Label still reports its text (LESSONS: "a sidebar
## that fits today is not a sidebar with room in it").
##
## HOW IT MEASURES. The runner cannot settle a frame (everything happens in
## `_initialize`, nothing is inside the tree), so container layout never runs
## and `get_combined_minimum_size()` on the panel answers from a cache primed
## when the panel was still EMPTY — outside the tree that cache is never
## invalidated. The guard therefore walks the panel itself and sums what the
## content WANTS, the way BoxContainer would: Labels re-wrapped at the width
## the column gives them (the engine's own `_shape`, forced by re-setting the
## text after the width), containers by their separation and margins, a
## vertical ScrollContainer as zero (scrolling is what TOWN-17's fix chose for
## the Tavern), and everything else by its own uncached `get_minimum_size()`.
## An HBox hands each child its minimum width and splits the rest between the
## expanders. It is an estimate of the laid-out minimum, not the layout — but it
## is the quantity that decides whether the panel grows, and it is exact for
## the case that failed (one wrapped Label too many in a VBox).
##
## Two sweeps, the same two a11y_smoke.gd runs: an empty guild (every list
## empty, the "empty state" copy in place) and the reference fixture (four
## cards, a recorded raid, the fullest sidebars the game builds).

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Fixture = preload("res://tools/fixture_reference.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const Frame = preload("res://game/ui/Frame.gd")

## a11y_smoke.SCREENS, in its order. Not every route builds a sidebar (MainMenu
## is frameless; RaidView and Results run the arena to the gutter) — those are
## recorded as "no sidebar", and the test anchors on the routes that must have
## one so it cannot pass by finding none.
const ROUTES := [
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

## Routes that call `Frame.sidebar()` today; the sweep must find a panel on
## each of these or the walk is blind (LESSONS: anchor on something real).
const MUST_HAVE_SIDEBAR := [
    "res://game/screens/Town.tscn",
    "res://game/screens/AdventureBoard.tscn",
    "res://game/screens/Tavern.tscn",
    "res://game/screens/Settings.tscn",
]

## Routes whose sidebar is KNOWN to overflow, keyed to the unit that owns the
## file — a row here is asserted to STILL overflow (the LIES_OWED mechanism of
## test_project_hygiene.gd), so the day the column is made to fit this test
## fails and asks for the row to be deleted rather than leaving the screen
## unguarded. Empty today. It held RaidPrep for an hour on 2026-09-15: the
## guard landed (W4-HYGIENE) measuring its column at ~672/703px in a 635px
## band while W4-PREP was rebuilding the file, and the wave-3 sheets showed
## the rim at y=767/822 against SIDEBAR_BOTTOM 714; W4-PREP's ScrollContainer
## and the provisions' move to the strip flipped this row the same afternoon,
## which is the mechanism working. Do not add a row without the measured number.
const OVERFLOW_PENDING := {}

const HOST_SIZE := Vector2(1536, 1024)

var _root: Node = null
var _made: Array = []


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []
    _ensure_autoloads()


func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []
    # The fixture's recorded raid autosaves (docs/14 §7.4); the runner points
    # SAVE_DIR at a test dir, so this purges only that. And the autoload is
    # shared by every file in the run: put it back contentless.
    SaveGame.purge_all()
    var st = _state()
    if st != null:
        st.reset()
        st.content = null


func _ensure_autoloads() -> void:
    if _root == null:
        return
    if _root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        _root.add_child(s)
        _made.append(s)


func _state():
    return _root.get_node_or_null("GameState")


## Mount one route into a fresh host at the reference size and return the
## screen, or null when the router refuses it.
func _mount(path: String) -> Control:
    var host := Control.new()
    host.name = "FitHost"
    host.set_anchors_preset(Control.PRESET_TOP_LEFT)
    host.position = Vector2.ZERO
    host.size = HOST_SIZE
    _root.add_child(host)
    _made.append(host)
    var router = Router.new()
    router.name = "FitRouter"
    _root.add_child(router)
    _made.append(router)
    router.register_host(host)
    if not router.goto(path):
        return null
    return router.current_screen()


# ---------------------------------------------------------------- the estimate

## What `l` wants vertically when the column gives it `w` px: the engine's own
## wrap, not a guess about line spacing. Re-setting the text marks the shape
## dirty so `get_minimum_size()` re-wraps at the width just set (a resize alone
## does not, outside the tree — NOTIFICATION_RESIZED needs a tree).
func _label_wants(l: Label, w: float) -> float:
    if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
        return l.get_minimum_size().y
    var width: float = maxf(w, l.custom_minimum_size.x)
    l.size = Vector2(width, 0.0)
    var t: String = l.text
    l.text = ""
    l.text = t
    return l.get_minimum_size().y


## The minimum width a child claims in a row: its own minimum, or the custom
## one — a wrapped Label reports 1px and relies on its custom_minimum_size.
func _min_w(c: Control) -> float:
    return maxf(c.custom_minimum_size.x, c.get_minimum_size().x)


func _visible_controls(c: Node) -> Array:
    var out: Array = []
    for ch in c.get_children():
        if ch is Control and (ch as Control).visible:
            out.append(ch)
    return out


## The height `c` needs at width `w`, BoxContainer-style, bypassing every
## minimum-size cache (see the file comment).
func _wants(c: Control, w: float) -> float:
    if not c.visible:
        return 0.0
    var h := 0.0
    if c is Label:
        h = _label_wants(c as Label, w)
    elif c is ScrollContainer:
        var sc := c as ScrollContainer
        if sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
            for ch in _visible_controls(sc):
                h = maxf(h, _wants(ch, w))
        # else: a scrolling column costs the panel nothing — that is the fix.
    elif c is VBoxContainer:
        var sep: float = float(c.get_theme_constant("separation"))
        var kids := _visible_controls(c)
        for ch in kids:
            h += _wants(ch, w)
        if kids.size() > 1:
            h += sep * float(kids.size() - 1)
    elif c is HBoxContainer:
        var sep: float = float(c.get_theme_constant("separation"))
        var kids := _visible_controls(c)
        var fixed := 0.0
        var expanders := 0
        for ch in kids:
            if (ch as Control).size_flags_horizontal & Control.SIZE_EXPAND:
                expanders += 1
            else:
                fixed += _min_w(ch)
        if kids.size() > 1:
            fixed += sep * float(kids.size() - 1)
        var share: float = (w - fixed) / float(expanders) if expanders > 0 else 0.0
        for ch in kids:
            var cw: float = _min_w(ch)
            if (ch as Control).size_flags_horizontal & Control.SIZE_EXPAND:
                cw = maxf(cw, share)
            h = maxf(h, _wants(ch, cw))
    elif c is MarginContainer:
        var l: float = float(c.get_theme_constant("margin_left"))
        var r: float = float(c.get_theme_constant("margin_right"))
        var t: float = float(c.get_theme_constant("margin_top"))
        var b: float = float(c.get_theme_constant("margin_bottom"))
        var inner := 0.0
        for ch in _visible_controls(c):
            inner = maxf(inner, _wants(ch, w - l - r))
        h = inner + t + b
    elif c is PanelContainer:
        var sb: StyleBox = c.get_theme_stylebox("panel")
        var ms: Vector2 = sb.get_minimum_size() if sb != null else Vector2.ZERO
        var inner := 0.0
        for ch in _visible_controls(c):
            inner = maxf(inner, _wants(ch, w - ms.x))
        h = inner + ms.y
    else:
        # Buttons, TextureRects, rules, the drawn kit pieces, plain Controls
        # (whose positioned children do not push them), and any container the
        # walk does not model — its own minimum, uncached.
        h = c.get_minimum_size().y
    return maxf(c.custom_minimum_size.y, h)


## One route under the current GameState: [route, sidebar_found, wants, host_h].
func _measure(path: String) -> Array:
    var screen := _mount(path)
    assert_ne(screen, null, "%s mounts" % path.get_file())
    if screen == null:
        return [path, false, 0.0, 0.0]
    var sidebar_host: Control = screen.find_child("SidebarHost", true, false) as Control
    var side: Control = screen.find_child("Sidebar", true, false) as Control
    if sidebar_host == null or side == null:
        return [path, false, 0.0, 0.0]
    assert_eq(side.get_parent(), sidebar_host,
        "%s: the panel named Sidebar sits in SidebarHost" % path.get_file())
    return [path, true, _wants(side, sidebar_host.size.x), sidebar_host.size.y]


func _sweep(label: String) -> void:
    var found: Array = []
    var rows: Array = []
    for path in ROUTES:
        var m := _measure(path)
        if not bool(m[1]):
            rows.append("  %-16s %s  no sidebar" % [String(m[0]).get_file(), label])
            continue
        found.append(m[0])
        rows.append("  %-16s %s  wants %4.0f  host %4.0f" % [String(m[0]).get_file(), label, m[2], m[3]])
        if OVERFLOW_PENDING.has(m[0]):
            assert_true(float(m[2]) > float(m[3]),
                "%s (%s) fits its sidebar now (wants %.0f in %.0f) — delete its OVERFLOW_PENDING row so the "
                % [String(m[0]).get_file(), label, m[2], m[3]]
                + "guard covers it; the row said: " + String(OVERFLOW_PENDING[m[0]]))
            continue
        assert_true(float(m[2]) <= float(m[3]) + 0.5,
            "%s (%s): the sidebar's content wants %.0fpx and its host is %.0fpx — the panel "
            % [String(m[0]).get_file(), label, m[2], m[3]]
            + "would grow through the strip band (TOWN-17); move a row out of the column "
            + "or put the overflowing block in a ScrollContainer with a visible bar")
    for must in MUST_HAVE_SIDEBAR:
        assert_true(must in found,
            "%s builds a sidebar today; the walk found none, so it is blind" % must.get_file())
    if OS.get_environment("SIDEBAR_FIT_TABLE") != "":
        print("\n".join(PackedStringArray(rows)))


## The host is where the number to fit inside comes from; pin the arithmetic
## Frame promises so the sweeps below are testing against the real band: the
## framed screens run SIDEBAR_TOP..SIDEBAR_BOTTOM (635), the full-bleed camp
## meets the header rule and stops 8px short of the strip (TOWN-08: 650).
func test_the_sidebar_host_is_the_band_between_header_and_strip() -> void:
    var st = _state()
    st.reset()
    st.content = null
    var board := _mount("res://game/screens/AdventureBoard.tscn")
    assert_ne(board, null)
    var host: Control = board.find_child("SidebarHost", true, false) as Control
    assert_ne(host, null, "the Board frames a sidebar")
    assert_eq(host.size.y, float(Frame.SIDEBAR_BOTTOM - Frame.SIDEBAR_TOP),
        "a framed host runs from SIDEBAR_TOP to SIDEBAR_BOTTOM (Frame.gd)")
    assert_eq(host.size.x, float(Frame.SIDEBAR_W))
    var side: Control = board.find_child("Sidebar", true, false) as Control
    assert_ne(side, null)
    assert_true(side.size.y <= host.size.y,
        "Frame.sidebar sizes the panel to its host, never past it")
    var town := _mount("res://game/screens/Town.tscn")
    assert_ne(town, null)
    var camp_host: Control = town.find_child("SidebarHost", true, false) as Control
    assert_ne(camp_host, null, "the full-bleed Town has a sidebar too")
    assert_eq(camp_host.size.y, float((Frame.STRIP_Y - 8) - (Frame.DIVIDER_Y + 2)),
        "the full-bleed host meets the header rule and stops 8px above the strip")


## The estimator must see a wrapped Label as more than one line, or the whole
## guard is the blind spot it exists to close.
func test_the_estimate_counts_wrapped_lines() -> void:
    var host := Control.new()
    _root.add_child(host)
    _made.append(host)
    var col := VBoxContainer.new()
    host.add_child(col)
    var one := Label.new()
    one.text = "short"
    col.add_child(one)
    var many := Label.new()
    many.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    many.text = "a line that is far too long to fit inside one hundred pixels of column and so must wrap several times over"
    col.add_child(many)
    var single: float = _wants(one, 100.0)
    var wrapped: float = _wants(many, 100.0)
    assert_true(wrapped > single * 2.5,
        "a long wrapped Label at 100px wants %.0f, a one-liner %.0f — the wrap is counted" % [wrapped, single])
    assert_true(_wants(col, 100.0) >= single + wrapped,
        "a VBox wants at least the sum of its children")
    var scroll := ScrollContainer.new()
    host.add_child(scroll)
    var inner := Label.new()
    inner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inner.text = many.text
    scroll.add_child(inner)
    assert_eq(_wants(scroll, 100.0), 0.0, "a vertical ScrollContainer costs its parent nothing")


func test_every_route_fits_its_sidebar_with_an_empty_guild() -> void:
    var st = _state()
    st.reset()
    st.content = null
    _sweep("empty")


func test_every_route_fits_its_sidebar_with_the_reference_fixture() -> void:
    var st = _state()
    st.reset()
    Fixture.apply(st, null, true)
    _sweep("fixture")
