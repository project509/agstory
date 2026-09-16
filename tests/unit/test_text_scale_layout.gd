extends "res://tests/TestCase.gd"
## W5-SCALE — M6-A11Y-05's layout half: every route fits at text_scale
## 100 / 125 / 150 with the reference fixture (docs/13 §13's blocking row, §14's
## "reflow, never truncate", §15's "survive 150%").
##
## WHAT IT ASSERTS, per Label on each of the 13 routes at each scale:
##   - a non-wrapping Label's string (the theme's own font at the theme's own
##     size, the way the screen draws it) fits the width the layout hands it;
##   - a wrapping Label's lines fit its rect — `max_lines_visible` shows every
##     line it needs, and a fixed-height rect is as tall as the wrap;
##   - a `clip_text` Label is not actually clipping;
##   - a container's content is no wider or taller than the rect it was given,
##     and nothing crosses the edge of the nearest ancestor that clips.
## A Label that TRIMS with an ellipsis (`text_overrun_behavior`, no
## `clip_text`) is the kit's designed overrun on band lines and log rows and
## is reported (TEXT_SCALE_LAYOUT_TABLE=1) but not asserted; the audit queue
## carries that debt by name.
##
## HOW IT MEASURES — THE HARNESS FACT THAT SHAPES THIS FILE. `tests/run_tests.gd`
## runs before the root Window enters the tree (a11y_smoke.gd's header), so
## containers never lay out here, `get_combined_minimum_size()` answers from a
## cache primed while the node was empty, and a Label shapes its text with the
## engine's fallback font (its theme cache is filled on ENTER_TREE) — measured:
## a LabelBody under a themed host answers 16px to `get_theme_font_size()` in
## `_initialize`. What DOES work off-tree is `NOTIFICATION_THEME_CHANGED` sent
## by hand: the Control refreshes its theme cache from the owner chain and the
## Label reshapes, after which `get_theme_font()`, `get_theme_font_size()` and
## `get_minimum_size()` all answer with the screen's own theme at the player's
## scale (the same probe: 23px, and a 36px line for the face-carrying
## LabelBody at 150, exactly the tree's number). Containers still never sort,
## and `get_combined_minimum_size()` stays a cache, so the "layout pass" is
## this file's own: a width-first estimator that hands each container the rect
## Godot would (BoxContainer, Margin, Panel, Scroll, Grid, Flow, Center, and
## coordinate-placed children under plain Controls with their anchors and grow
## directions), asks every leaf for its own minimum at that width, and records
## where it put things. It was validated against an in-tree dump of the same
## 13 routes at 100 and 150 (build/plan/report-W5-SCALE.md).
##
## ONE LIMIT, MEASURED. A screen that sets a Label's `size` by hand before the
## theme reaches it (a coordinate-placed caption) has that size clamped by the
## engine to the FALLBACK font's minimum, and the intended number is gone: the
## strip's "n/m" caption (48x18) reads 23 tall here at 100, 18 in the tree.
## The estimate errs high by the fallback-vs-real difference (5px at 100 for
## LabelSmall, 0 at 150 where the real font is the taller), never low.
##
## KNOWN is the allow-list: a row must still match a finding (a fixed screen
## fails the test until its row is deleted — test_sidebar_fit's mechanism), and
## every row names the owner and the measured number. For the screens this
## unit owns it holds one row, Results' page caption — the kit's placement
## inside a host this screen positions (see the row).

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const Fixture = preload("res://tools/fixture_reference.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const SettingsScreen = preload("res://game/screens/Settings.gd")
const GuildhallScreen = preload("res://game/screens/Guildhall.gd")

## a11y_smoke.SCREENS, in its order.
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
const SCALES := [100, 125, 150]
const HOST_SIZE := Vector2(1536, 1024)
## Sub-pixel rounding between the estimate and the engine.
const TOL := 1.0

## Finding kinds. TRIM is informational (see the header).
const WIDE := "too wide"
const CLIP := "clips"
const CUT := "cut lines"
const TRIM := "trims"
const OVER := "overflows"
const PAST := "past the clip"

## Overflows KNOWN in screens this unit does not own, each with its owner and
## the measured number (in-tree, 2026-09-15). `scale` 0 matches every scale.
## `match` is a prefix of the Label's text or a fragment of its node path.
const KNOWN := [
    {"screen": "AdventureBoard.tscn", "scale": 0, "kind": CUT, "match": "Trash  ·  1 enemy  ·",
     "why": "AdventureBoard.gd:592 caps the encounter's facts line at max_lines_visible 1 and the "
        + "fixture's line wants 2 lines at 100 (403px in 290), 3 at 150 — W2-BOARD's owner"},
    {"screen": "AdventureBoard.tscn", "scale": 100, "kind": CUT, "match": "One mob. Four volunteers.",
     "why": "AdventureBoard.gd:613 caps the notice's quip at max_lines_visible 2 and the fixture's "
        + "wants 3 at 100 in the 310 column — W2-BOARD's owner"},
    # (Rows for RaidPrep's cost line at 150, RaidView's objective title at 125/150 and
    # Cards.event_log's six rows at 150 were here; W5-KIT3 and the wave-5 handoffs
    # fixed them at the wave close and the test said so — 2026-09-15.)
    # The kit card (Cards.card) at 150: the morale line ("Rhona — 34" is 203px
    # at 30px tabular in the 191 inside the pad), the action pair ("Cheer up"
    # + "Manage", 197) and a reason line under it grow the card past its
    # authored 215x262 — the Roster grid's cells clip 4-16px of the rim, and
    # on the strip the card runs 4-60px under the frame's bottom edge.
    {"screen": "Guildhall.tscn", "scale": 0, "kind": PAST, "match": "Cell_",
     "why": "Cards.card at 125 (a reason line: 10px taller) and 150 (wider and taller) than the Roster "
        + "grid's 215x262 cell — the kit (W5-KIT3)"},
    {"screen": "Town.tscn", "scale": 150, "kind": PAST, "match": "RosterStrip",
     "why": "Cards.card at 150 runs under the strip (y 1024+) — the kit (W5-KIT3)"},
    {"screen": "AdventureBoard.tscn", "scale": 150, "kind": PAST, "match": "RosterStrip",
     "why": "Cards.card at 150 runs under the strip — the kit (W5-KIT3)"},
    {"screen": "Market.tscn", "scale": 150, "kind": PAST, "match": "RosterStrip",
     "why": "Cards.card at 150 runs under the strip — the kit (W5-KIT3)"},
    {"screen": "RaidPrep.tscn", "scale": 0, "kind": PAST, "match": "RosterStrip",
     "why": "Cards.card runs 12px under the strip at 125 and up to 60 at 150 — the kit (W5-KIT3)"},
    {"screen": "RaiderDetail.tscn", "scale": 0, "kind": PAST, "match": "RosterStrip",
     "why": "Cards.card runs 12px under the strip at 125 and up to 60 at 150 — the kit (W5-KIT3)"},
    # Results is this unit's, but the caption is the kit's: Cards.roster_strip
    # puts "n/m" at STRIP_H + 4 under the cards, and Results' card host sits
    # at y=741 (CARD_Y 6 under the concept's 735 strip), so the caption ends
    # at 1025/1029/1032 by scale — 1 (in tolerance), 5 and 8px under the
    # frame. The estimate reads the 100 row 5px taller than the tree (see the
    # header on hand-set sizes). handoff-W5-SCALE names the fix.
    {"screen": "Results.tscn", "scale": 0, "kind": PAST, "match": "RosterStrip",
     "why": "Cards.card at 150 runs under the strip; the pager's '1/3' caption ends 5/8px under the "
        + "frame at 125/150 — the kit (W5-KIT3)"},
    {"screen": "Market.tscn", "scale": 150, "kind": PAST, "match": "SidebarHost",
     "why": "the Market's sidebar panel wants 381 in 378 at 150 (\"Pay for a better stall — 130 G\" is "
        + "333px plus the pad) and ends 3px past the frame — Market.gd's owner, handoff-W5-SCALE"},
]

var _root: Node = null
var _made: Array = []
var _scale_was = null
var _findings: Array = []
var _rects: Dictionary = {}
var _min_w_cache: Dictionary = {}
var _wants_cache: Dictionary = {}
var _screen_file := ""
var _scale := 100


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []
    _scale_was = null
    _findings = []
    _rects = {}
    _ensure_autoloads()


func after_each() -> void:
    var gs = _root.get_node_or_null("GameSettings") if _root != null else null
    if gs != null and _scale_was != null:
        gs.set_value("text_scale", _scale_was)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []
    # The fixture's recorded raid autosaves into the runner's test dir; the
    # autoload is shared by every file in the run, so it goes back contentless.
    SaveGame.purge_all()
    var st = _state()
    if st != null:
        st.reset()
        st.content = null


# ---------------------------------------------------------------- mounting

func _ensure_autoloads() -> Node:
    if _root == null:
        return null
    if _root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        _root.add_child(s)
        _made.append(s)
    var gs = _root.get_node_or_null("GameSettings")
    if gs == null:
        gs = SettingsScript.new()
        gs.name = "GameSettings"
        _root.add_child(gs)
        _made.append(gs)
    if _scale_was == null:
        _scale_was = gs.get_value("text_scale")
    return gs


func _state():
    return _root.get_node_or_null("GameState")


## The reference guild, its recorded raid (RaidView/Results need one) and the
## campaign marked finished (Completion, the Board's post-clear goal).
func _fixture() -> void:
    var st = _state()
    st.reset()
    Fixture.apply(st, null, true)
    st.set("completed", true)
    st.set("completed_on_day", int(st.get("day")))
    st.set("completion_seen", false)


func _mount(path: String, scale: int) -> Control:
    var gs = _ensure_autoloads()
    gs.set_value("text_scale", scale)
    var host := Control.new()
    host.name = "ScaleHost"
    host.set_anchors_preset(Control.PRESET_TOP_LEFT)
    host.position = Vector2.ZERO
    host.size = HOST_SIZE
    _root.add_child(host)
    _made.append(host)
    var router = Router.new()
    router.name = "ScaleRouter"
    _root.add_child(router)
    _made.append(router)
    router.register_host(host)
    if not router.goto(path):
        return null
    return router.current_screen()


# ---------------------------------------------------------------- the fonts

func _font(c: Control) -> Font:
    var f: Font = c.get_theme_font("font")
    return f if f != null else ThemeDB.fallback_font


func _px(c: Control) -> int:
    return c.get_theme_font_size("font_size")


func _pad(c: Control, box: String = "normal") -> Vector2:
    var sb: StyleBox = c.get_theme_stylebox(box)
    return sb.get_minimum_size() if sb != null else Vector2.ZERO


## The widest line of `text` (a "\n" string is measured line by line).
func _text_w(font: Font, px: int, text: String) -> float:
    var w := 0.0
    for line in text.split("\n"):
        w = maxf(w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
    return w


## How many lines `text` takes when wrapped at `w`, the engine's own breaker.
func _lines_at(font: Font, px: int, text: String, w: float, mode: int) -> int:
    if mode == TextServer.AUTOWRAP_OFF:
        return text.split("\n").size()
    var tp := TextParagraph.new()
    tp.width = maxf(1.0, w)
    var flags: int = TextServer.BREAK_MANDATORY
    match mode:
        TextServer.AUTOWRAP_WORD_SMART:
            flags |= TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
        TextServer.AUTOWRAP_WORD:
            flags |= TextServer.BREAK_WORD_BOUND
        TextServer.AUTOWRAP_ARBITRARY:
            flags |= TextServer.BREAK_GRAPHEME_BOUND
    tp.break_flags = flags
    tp.add_string(text, font, px)
    return maxi(1, tp.get_line_count())


## `n` lines of `c`'s font: the font's height (a face-carrying variation is as
## tall as its sheet, as the engine draws it) plus the theme's line spacing.
func _lines_h(c: Control, n: int) -> float:
    var h: float = _font(c).get_height(_px(c))
    var spacing: float = float(c.get_theme_constant("line_spacing"))
    return float(n) * h + float(maxi(0, n - 1)) * spacing


func _trims(l: Label) -> bool:
    return l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING


## The one door off-tree (see the header): every Control under `n` refreshes
## its theme cache and reshapes, so the engine's own minimums are the theme's.
func _refresh_theme(n: Node) -> void:
    if n is Control:
        n.notification(Control.NOTIFICATION_THEME_CHANGED)
    for c in n.get_children():
        _refresh_theme(c)


## A wrapping Label or Button shaped at width `w`: re-setting the text marks
## the shape dirty so `get_minimum_size()` wraps at the width just set (a
## resize alone does not, outside the tree — test_sidebar_fit.gd).
func _reshape(c: Control, w: float) -> void:
    c.size = Vector2(maxf(1.0, w), 0.0)
    var t: String = c.text
    c.text = ""
    c.text = t


func _wraps(c: Control) -> bool:
    if c is Label:
        return (c as Label).autowrap_mode != TextServer.AUTOWRAP_OFF
    if c is Button:
        return (c as Button).autowrap_mode != TextServer.AUTOWRAP_OFF
    return false


# ---------------------------------------------------------------- minimum width

func _kids(c: Node) -> Array:
    var out: Array = []
    for ch in c.get_children():
        if ch is Control and (ch as Control).visible:
            out.append(ch)
    return out


func _sep(c: Control, key: String = "separation") -> float:
    return float(c.get_theme_constant(key))


## The width `c` claims, computed the way the container above it would — with
## the real fonts, no cache.
func _min_w(c: Control) -> float:
    if not c.visible:
        return 0.0
    var id: int = c.get_instance_id()
    if _min_w_cache.has(id):
        return _min_w_cache[id]
    var w := 0.0
    if c is BoxContainer:
        var kids := _kids(c)
        if (c as BoxContainer).vertical:
            for k in kids:
                w = maxf(w, _min_w(k))
        else:
            for k in kids:
                w += _min_w(k)
            if kids.size() > 1:
                w += _sep(c) * float(kids.size() - 1)
    elif c is MarginContainer:
        for k in _kids(c):
            w = maxf(w, _min_w(k))
        w += _sep(c, "margin_left") + _sep(c, "margin_right")
    elif c is PanelContainer:
        for k in _kids(c):
            w = maxf(w, _min_w(k))
        w += _pad(c, "panel").x
    elif c is ScrollContainer:
        if (c as ScrollContainer).horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
            for k in _kids(c):
                w = maxf(w, _min_w(k))
    elif c is GridContainer:
        var cols: Array = _grid_cols(c as GridContainer)
        for cw in cols:
            w += float(cw)
        if cols.size() > 1:
            w += _sep(c, "h_separation") * float(cols.size() - 1)
    elif c is Container:
        for k in _kids(c):
            w = maxf(w, _min_w(k))
    else:
        # A leaf (Label, Button, TextureRect, the drawn kit pieces): the
        # engine's own minimum with the theme it was just handed. A wrapping
        # or trimming Label claims 1px, as it does in the tree.
        w = c.get_minimum_size().x
    w = maxf(c.custom_minimum_size.x, w)
    _min_w_cache[id] = w
    return w


## A grid's column widths: the widest cell in each.
func _grid_cols(g: GridContainer) -> Array:
    var n: int = maxi(1, g.columns)
    var cols: Array = []
    for i in n:
        cols.append(0.0)
    var kids := _kids(g)
    for i in kids.size():
        var col: int = i % n
        cols[col] = maxf(float(cols[col]), _min_w(kids[i]))
    return cols


# ---------------------------------------------------------------- height at a width

func _fill_x(c: Control) -> bool:
    return (c.size_flags_horizontal & Control.SIZE_FILL) != 0


func _expand_x(c: Control) -> bool:
    return (c.size_flags_horizontal & Control.SIZE_EXPAND) != 0


func _expand_y(c: Control) -> bool:
    return (c.size_flags_vertical & Control.SIZE_EXPAND) != 0


## The widths an HBox hands its children at width `w`: minimums, the leftover
## shared by the expanders in proportion to their stretch ratios.
func _row_widths(c: Control, w: float) -> Array:
    var kids := _kids(c)
    var out: Array = []
    var fixed := 0.0
    var ratio := 0.0
    for k in kids:
        var mw: float = _min_w(k)
        out.append(mw)
        fixed += mw
        if _expand_x(k):
            ratio += maxf(0.0, (k as Control).size_flags_stretch_ratio)
    if kids.size() > 1:
        fixed += _sep(c) * float(kids.size() - 1)
    var spare: float = w - fixed
    if spare > 0.0 and ratio > 0.0:
        for i in kids.size():
            if _expand_x(kids[i]):
                out[i] = float(out[i]) + spare * (kids[i] as Control).size_flags_stretch_ratio / ratio
    return out


## The height `c` needs when handed width `w`.
func _wants_h(c: Control, w: float) -> float:
    if not c.visible:
        return 0.0
    var key := "%d@%d" % [c.get_instance_id(), int(round(w))]
    if _wants_cache.has(key):
        return _wants_cache[key]
    var h := 0.0
    if c is BoxContainer:
        var kids := _kids(c)
        if (c as BoxContainer).vertical:
            for k in kids:
                h += _wants_h(k, w if _fill_x(k) else _min_w(k))
            if kids.size() > 1:
                h += _sep(c) * float(kids.size() - 1)
        else:
            var widths := _row_widths(c, w)
            for i in kids.size():
                h = maxf(h, _wants_h(kids[i], float(widths[i])))
    elif c is MarginContainer:
        var inner: float = w - _sep(c, "margin_left") - _sep(c, "margin_right")
        for k in _kids(c):
            h = maxf(h, _wants_h(k, inner if _fill_x(k) else _min_w(k)))
        h += _sep(c, "margin_top") + _sep(c, "margin_bottom")
    elif c is PanelContainer:
        var pad := _pad(c, "panel")
        for k in _kids(c):
            h = maxf(h, _wants_h(k, w - pad.x if _fill_x(k) else _min_w(k)))
        h += pad.y
    elif c is ScrollContainer:
        var sc := c as ScrollContainer
        if sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
            for k in _kids(sc):
                h = maxf(h, _wants_h(k, w))
        # else: a scrolling column costs its parent nothing.
    elif c is GridContainer:
        for rh in _grid_rows(c as GridContainer, w):
            h += float(rh)
        var rows: int = _grid_rows(c as GridContainer, w).size()
        if rows > 1:
            h += _sep(c, "v_separation") * float(rows - 1)
    elif c is FlowContainer and not (c as FlowContainer).vertical:
        for rh in _flow_rows(c as FlowContainer, w):
            h += float(rh)
        var rows: int = _flow_rows(c as FlowContainer, w).size()
        if rows > 1:
            h += _sep(c, "v_separation") * float(rows - 1)
    elif c is Container:
        for k in _kids(c):
            h = maxf(h, _wants_h(k, w))
    else:
        if _wraps(c):
            _reshape(c, w)
        h = c.get_minimum_size().y
    h = maxf(c.custom_minimum_size.y, h)
    _wants_cache[key] = h
    return h


## A grid's row heights at width `w`: each cell at its column's width.
func _grid_rows(g: GridContainer, _w: float) -> Array:
    var n: int = maxi(1, g.columns)
    var cols := _grid_cols(g)
    var rows: Array = []
    var kids := _kids(g)
    for i in kids.size():
        var r: int = i / n
        while rows.size() <= r:
            rows.append(0.0)
        rows[r] = maxf(float(rows[r]), _wants_h(kids[i], float(cols[i % n])))
    return rows


## An HFlow's row heights at width `w`: children at their minimum widths,
## wrapped where the next one would cross the edge.
func _flow_rows(f: FlowContainer, w: float) -> Array:
    var rows: Array = []
    var x := 0.0
    var row_h := 0.0
    var in_row := 0
    var hs: float = _sep(f, "h_separation")
    for k in _kids(f):
        var kw: float = _min_w(k)
        if in_row > 0 and x + hs + kw > w + TOL:
            rows.append(row_h)
            x = 0.0
            row_h = 0.0
            in_row = 0
        if in_row > 0:
            x += hs
        row_h = maxf(row_h, _wants_h(k, kw))
        x += kw
        in_row += 1
    if in_row > 0:
        rows.append(row_h)
    return rows


# ---------------------------------------------------------------- the layout pass

## The node's path under the screen, walked by hand (`get_path()` is empty
## outside the tree).
func _path(c: Node) -> String:
    var parts: Array = []
    var n: Node = c
    while n != null and n != _root and n.get_parent() != _root:
        parts.push_front(String(n.name))
        n = n.get_parent()
    return "/".join(PackedStringArray(parts))


func _note(c: Control, kind: String, detail: String) -> void:
    var text := ""
    if c is Label:
        text = (c as Label).text
    elif c is Button:
        text = (c as Button).text
    _findings.append({"screen": _screen_file, "scale": _scale, "kind": kind,
        "path": _path(c), "text": text.left(48).replace("\n", " / "), "detail": detail,
        "variation": String(c.theme_type_variation)})


## Lay `c` out inside `rect` (screen space), check it, and place its children.
## `clip` is the rect of the nearest ancestor that clips (or the screen).
## `quiet` is set below an overflowing container so one defect is one finding.
func _place(c: Control, rect: Rect2, clip: Rect2, quiet: bool) -> void:
    if not c.visible:
        return
    # The world layer: stage coordinates, a plate larger than its host by
    # design, and no word of the UI (its bubble is the stage's own).
    if String(c.name).begins_with("SceneStage_"):
        return
    # A callout plate places ITSELF on its anchor inside its band from its
    # laid-out size (`Widgets._place_callout`, on `item_rect_changed`), so its
    # off-tree position means nothing; its band is test_town_layout.gd's.
    # Its rect is sized here and its words are still checked against it.
    if c.get_node_or_null("Tail") != null:
        clip = Rect2(-INF, -INF, INF, INF)
    _rects[c.get_instance_id()] = rect
    var q := quiet
    if c is Label:
        q = _check_label(c as Label, rect, clip, quiet) or q
    elif c is Button:
        q = _check_button(c as Button, rect, clip, quiet) or q
    elif c is Container and not quiet:
        var mw: float = _min_w(c)
        var mh: float = _wants_h(c, rect.size.x)
        if mw > rect.size.x + TOL:
            _note(c, OVER, "wants %.0f wide, has %.0f; the widest: %s" % [mw, rect.size.x, _widest_leaf(c)])
            q = true
        elif mh > rect.size.y + TOL:
            _note(c, OVER, "wants %.0f tall, has %.0f" % [mh, rect.size.y])
            q = true
        elif rect.end.x > clip.end.x + TOL or rect.end.y > clip.end.y + TOL:
            _note(c, PAST, "ends at %.0f,%.0f; the clip ends at %.0f,%.0f; the widest: %s"
                % [rect.end.x, rect.end.y, clip.end.x, clip.end.y, _widest_leaf(c)])
            q = true
    var my_clip := clip
    if c.clip_contents:
        my_clip = rect.intersection(clip)
    _place_children(c, rect, my_clip, q)


## The leaf that sets a container's width — the Label a finding should name.
func _widest_leaf(c: Control) -> String:
    var node: Control = c
    while node is Container:
        var widest: Control = null
        var w := -1.0
        for k in _kids(node):
            var kw: float = _min_w(k)
            if kw > w:
                w = kw
                widest = k
        if widest == null:
            break
        node = widest
    var text := ""
    if node is Label:
        text = (node as Label).text
    elif node is Button:
        text = (node as Button).text
    return "%s '%s' (%.0f)" % [node.get_class(), text.left(40), _min_w(node)]


## Where a Label overflows. Returns true when the finding is the container's
## problem as well (so the walk below goes quiet).
func _check_label(l: Label, rect: Rect2, clip: Rect2, quiet: bool) -> bool:
    var pad := _pad(l)
    var inner_w: float = rect.size.x - pad.x
    var found := false
    if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
        var tw: float = _text_w(_font(l), _px(l), l.text)
        if tw > inner_w + TOL:
            if l.clip_text:
                _note(l, CLIP, "needs %.0f, has %.0f" % [tw, inner_w])
            elif _trims(l):
                _note(l, TRIM, "needs %.0f, has %.0f" % [tw, inner_w])
            else:
                _note(l, WIDE, "needs %.0f, has %.0f" % [tw, inner_w])
                found = true
    else:
        # `Label.get_line_count()` answers 1 outside the tree, so the lines are
        # counted with the engine's breaker on the Label's own font.
        _reshape(l, rect.size.x)
        var n: int = _lines_at(_font(l), _px(l), l.text, inner_w, l.autowrap_mode)
        if l.max_lines_visible > 0 and n > l.max_lines_visible:
            _note(l, CUT, "%d lines, %d shown" % [n, l.max_lines_visible])
        else:
            var need: float = l.get_minimum_size().y
            if need > rect.size.y + TOL:
                _note(l, CUT, "%d lines need %.0f, has %.0f" % [n, need, rect.size.y])
                found = true
    if not quiet and (rect.end.x > clip.end.x + TOL or rect.end.y > clip.end.y + TOL):
        _note(l, PAST, "ends at %.0f,%.0f; the clip ends at %.0f,%.0f"
            % [rect.end.x, rect.end.y, clip.end.x, clip.end.y])
        found = true
    elif not quiet and _past_plate(l, rect):
        found = true
    return found


## A Label placed by coordinate inside a drawn plate (a Button, a panel) that
## ends outside it is visible whether or not anything clips — Widgets.cta's
## cost line under the Depart plate at 150, measured.
func _past_plate(l: Label, rect: Rect2) -> bool:
    var p := l.get_parent()
    if not (p is Button or p is PanelContainer or p is Panel):
        return false
    if not _rects.has(p.get_instance_id()):
        return false
    var pr: Rect2 = _rects[p.get_instance_id()]
    if rect.end.x > pr.end.x + TOL or rect.end.y > pr.end.y + TOL:
        _note(l, PAST, "ends at %.0f,%.0f; its %s plate ends at %.0f,%.0f"
            % [rect.end.x, rect.end.y, p.get_class(), pr.end.x, pr.end.y])
        return true
    return false


func _check_button(b: Button, rect: Rect2, clip: Rect2, quiet: bool) -> bool:
    var found := false
    var trims: bool = b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
    if b.autowrap_mode == TextServer.AUTOWRAP_OFF and not trims and not b.text.is_empty():
        var mw: float = _min_w(b)
        if mw > rect.size.x + TOL:
            _note(b, WIDE, "needs %.0f, has %.0f" % [mw, rect.size.x])
            found = true
    var need: float = _wants_h(b, rect.size.x)
    if need > rect.size.y + TOL:
        _note(b, CUT, "needs %.0f tall, has %.0f" % [need, rect.size.y])
        found = true
    if not quiet and (rect.end.x > clip.end.x + TOL or rect.end.y > clip.end.y + TOL):
        _note(b, PAST, "ends at %.0f,%.0f; the clip ends at %.0f,%.0f"
            % [rect.end.x, rect.end.y, clip.end.x, clip.end.y])
        found = true
    return found


func _place_children(c: Control, rect: Rect2, clip: Rect2, quiet: bool) -> void:
    var kids := _kids(c)
    if kids.is_empty():
        return
    if c is BoxContainer:
        _place_box(c as BoxContainer, kids, rect, clip, quiet)
    elif c is MarginContainer:
        var inner := Rect2(rect.position.x + _sep(c, "margin_left"), rect.position.y + _sep(c, "margin_top"),
            rect.size.x - _sep(c, "margin_left") - _sep(c, "margin_right"),
            rect.size.y - _sep(c, "margin_top") - _sep(c, "margin_bottom"))
        for k in kids:
            _place(k, _fit(k, inner), clip, quiet)
    elif c is PanelContainer:
        var sb: StyleBox = c.get_theme_stylebox("panel")
        var inner := rect
        if sb != null:
            inner = Rect2(rect.position.x + sb.get_margin(SIDE_LEFT), rect.position.y + sb.get_margin(SIDE_TOP),
                rect.size.x - sb.get_minimum_size().x, rect.size.y - sb.get_minimum_size().y)
        for k in kids:
            _place(k, _fit(k, inner), clip, quiet)
    elif c is ScrollContainer:
        var sc := c as ScrollContainer
        for k in kids:
            var kw: float = rect.size.x
            var open := clip
            if sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
                kw = maxf(kw, _min_w(k))
                open = Rect2(open.position, Vector2(INF, open.size.y))
            var kh: float = rect.size.y
            if sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
                kh = maxf(kh, _wants_h(k, kw))
                open = Rect2(open.position, Vector2(open.size.x, INF))
            # What scrolls is reachable, not overflowing: the clip opens along
            # the scrolling axis for everything inside.
            _place(k, Rect2(rect.position, Vector2(kw, kh)), open, quiet)
    elif c is GridContainer:
        _place_grid(c as GridContainer, kids, rect, clip, quiet)
    elif c is FlowContainer and not (c as FlowContainer).vertical:
        _place_flow(c as FlowContainer, kids, rect, clip, quiet)
    elif c is CenterContainer:
        for k in kids:
            var ms := Vector2(_min_w(k), _wants_h(k, _min_w(k)))
            _place(k, Rect2(rect.position + (rect.size - ms) / 2.0, ms), clip, quiet)
    elif c is Container:
        for k in kids:
            _place(k, _fit(k, rect), clip, quiet)
    else:
        for k in kids:
            _place(k, _anchored(k, rect), clip, quiet)


## A child inside a cell: the cell when it fills, its minimum otherwise
## (shrink flags place it at the start, the centre or the end).
func _fit(k: Control, cell: Rect2) -> Rect2:
    var w: float = cell.size.x if _fill_x(k) else minf(cell.size.x, _min_w(k))
    var h: float = cell.size.y if (k.size_flags_vertical & Control.SIZE_FILL) != 0 else minf(cell.size.y, _wants_h(k, w))
    var x: float = cell.position.x
    var y: float = cell.position.y
    if (k.size_flags_horizontal & Control.SIZE_SHRINK_CENTER) != 0:
        x += (cell.size.x - w) / 2.0
    elif (k.size_flags_horizontal & Control.SIZE_SHRINK_END) != 0:
        x += cell.size.x - w
    if (k.size_flags_vertical & Control.SIZE_SHRINK_CENTER) != 0:
        y += (cell.size.y - h) / 2.0
    elif (k.size_flags_vertical & Control.SIZE_SHRINK_END) != 0:
        y += cell.size.y - h
    return Rect2(x, y, w, h)


## A coordinate-placed child of a plain Control: its anchors and offsets
## against the parent's rect, grown to its minimum in its grow direction — a
## Control never draws smaller than its minimum, whatever `size` was set to.
func _anchored(k: Control, parent: Rect2) -> Rect2:
    var pw: float = parent.size.x
    var ph: float = parent.size.y
    var x0: float = k.anchor_left * pw + k.offset_left
    var x1: float = k.anchor_right * pw + k.offset_right
    var y0: float = k.anchor_top * ph + k.offset_top
    var y1: float = k.anchor_bottom * ph + k.offset_bottom
    var w: float = maxf(0.0, x1 - x0)
    var h: float = maxf(0.0, y1 - y0)
    var mw: float = _min_w(k)
    if mw > w:
        match k.grow_horizontal:
            Control.GROW_DIRECTION_BEGIN:
                x0 -= mw - w
            Control.GROW_DIRECTION_BOTH:
                x0 -= (mw - w) / 2.0
        w = mw
    var mh: float = _wants_h(k, w)
    if mh > h:
        match k.grow_vertical:
            Control.GROW_DIRECTION_BEGIN:
                y0 -= mh - h
            Control.GROW_DIRECTION_BOTH:
                y0 -= (mh - h) / 2.0
        h = mh
    return Rect2(parent.position.x + x0, parent.position.y + y0, w, h)


func _place_box(c: BoxContainer, kids: Array, rect: Rect2, clip: Rect2, quiet: bool) -> void:
    var sep: float = _sep(c)
    if c.vertical:
        var heights: Array = []
        var fixed := 0.0
        var ratio := 0.0
        for k in kids:
            var kw: float = rect.size.x if _fill_x(k) else _min_w(k)
            var kh: float = _wants_h(k, kw)
            heights.append(kh)
            fixed += kh
            if _expand_y(k):
                ratio += maxf(0.0, (k as Control).size_flags_stretch_ratio)
        if kids.size() > 1:
            fixed += sep * float(kids.size() - 1)
        var spare: float = rect.size.y - fixed
        var y: float = rect.position.y
        if spare > 0.0 and ratio > 0.0:
            for i in kids.size():
                if _expand_y(kids[i]):
                    heights[i] = float(heights[i]) + spare * (kids[i] as Control).size_flags_stretch_ratio / ratio
        elif spare > 0.0:
            if c.alignment == BoxContainer.ALIGNMENT_CENTER:
                y += spare / 2.0
            elif c.alignment == BoxContainer.ALIGNMENT_END:
                y += spare
        for i in kids.size():
            var k: Control = kids[i]
            var cell := Rect2(rect.position.x, y, rect.size.x, float(heights[i]))
            _place(k, _fit(k, cell), clip, quiet)
            y += float(heights[i]) + sep
    else:
        var widths := _row_widths(c, rect.size.x)
        var used := 0.0
        for wv in widths:
            used += float(wv)
        if kids.size() > 1:
            used += sep * float(kids.size() - 1)
        var x: float = rect.position.x
        var spare: float = rect.size.x - used
        if spare > 0.0:
            if c.alignment == BoxContainer.ALIGNMENT_CENTER:
                x += spare / 2.0
            elif c.alignment == BoxContainer.ALIGNMENT_END:
                x += spare
        for i in kids.size():
            var k: Control = kids[i]
            var cell := Rect2(x, rect.position.y, float(widths[i]), rect.size.y)
            _place(k, _fit(k, cell), clip, quiet)
            x += float(widths[i]) + sep


func _place_grid(g: GridContainer, kids: Array, rect: Rect2, clip: Rect2, quiet: bool) -> void:
    var n: int = maxi(1, g.columns)
    var cols := _grid_cols(g)
    var rows := _grid_rows(g, rect.size.x)
    var hs: float = _sep(g, "h_separation")
    var vs: float = _sep(g, "v_separation")
    var y: float = rect.position.y
    for r in rows.size():
        var x: float = rect.position.x
        for col in n:
            var i: int = r * n + col
            if i >= kids.size():
                break
            var cell := Rect2(x, y, float(cols[col]), float(rows[r]))
            _place(kids[i], _fit(kids[i], cell), clip, quiet)
            x += float(cols[col]) + hs
        y += float(rows[r]) + vs


func _place_flow(f: FlowContainer, kids: Array, rect: Rect2, clip: Rect2, quiet: bool) -> void:
    var hs: float = _sep(f, "h_separation")
    var vs: float = _sep(f, "v_separation")
    var rows := _flow_rows(f, rect.size.x)
    var x: float = rect.position.x
    var y: float = rect.position.y
    var in_row := 0
    var r := 0
    for k in kids:
        var kw: float = _min_w(k)
        if in_row > 0 and (x - rect.position.x) + hs + kw > rect.size.x + TOL:
            y += float(rows[r]) + vs
            r += 1
            x = rect.position.x
            in_row = 0
        if in_row > 0:
            x += hs
        var row_h: float = float(rows[mini(r, rows.size() - 1)])
        _place(k, _fit(k, Rect2(x, y, kw, row_h)), clip, quiet)
        x += kw
        in_row += 1


# ---------------------------------------------------------------- the sweep

func _sweep_screen(screen: Control, file: String, scale: int) -> void:
    _screen_file = file
    _scale = scale
    _min_w_cache = {}
    _wants_cache = {}
    _refresh_theme(screen)
    var frame := Rect2(Vector2.ZERO, HOST_SIZE)
    _place(screen, frame, frame, false)


func _asserted(f: Dictionary) -> bool:
    return String(f["kind"]) != TRIM


func _known_row(f: Dictionary) -> int:
    for i in KNOWN.size():
        var row: Dictionary = KNOWN[i]
        if String(row["screen"]) != String(f["screen"]):
            continue
        if int(row["scale"]) != 0 and int(row["scale"]) != int(f["scale"]):
            continue
        if String(row["kind"]) != String(f["kind"]):
            continue
        var m := String(row["match"])
        if String(f["text"]).begins_with(m) or String(f["path"]).contains(m) \
                or String(f["detail"]).contains(m):
            return i
    return -1


func _line(f: Dictionary) -> String:
    return "%-18s @%d  %-12s %-14s '%s' — %s  [%s]" % [String(f["screen"]), int(f["scale"]),
        String(f["kind"]), String(f["variation"]), String(f["text"]), String(f["detail"]), String(f["path"])]


## Every route at every scale under the reference fixture: no finding that is
## not KNOWN, and no KNOWN row that found nothing.
func test_every_route_fits_at_every_text_scale_with_the_reference_fixture() -> void:
    _fixture()
    var matched: Array = []
    for i in KNOWN.size():
        matched.append(false)
    var mounted := 0
    for scale in SCALES:
        for path in ROUTES:
            var screen := _mount(path, int(scale))
            assert_ne(screen, null, "%s mounts at %d" % [String(path).get_file(), int(scale)])
            if screen == null:
                continue
            mounted += 1
            _sweep_screen(screen, String(path).get_file(), int(scale))
    assert_eq(mounted, ROUTES.size() * SCALES.size(), "13 routes x 3 scales")
    var table := OS.get_environment("TEXT_SCALE_LAYOUT_TABLE") != ""
    var trims := 0
    for f in _findings:
        if table:
            print("  " + _line(f))
        if not _asserted(f):
            trims += 1
            continue
        var row: int = _known_row(f)
        if row >= 0:
            matched[row] = true
            continue
        fail("text does not fit: " + _line(f))
    for i in KNOWN.size():
        assert_true(matched[i],
            "KNOWN row %d (%s @%d %s '%s') matched nothing — the screen fits now; delete the row"
            % [i, String(KNOWN[i]["screen"]), int(KNOWN[i]["scale"]), String(KNOWN[i]["kind"]), String(KNOWN[i]["match"])])
    if table:
        print("  %d finding(s), %d of them ellipsis trims (not asserted)" % [_findings.size(), trims])
    # The walk is not blind: the fullest screens are inside it.
    assert_true(_rects.size() > 500, "the estimator placed %d controls" % _rects.size())


# ---------------------------------------------------------------- the estimator, proved

func _themed_host(w: float, h: float) -> Control:
    var host := Control.new()
    host.name = "ScaleHost"
    host.theme = Theme_.get_theme(100)
    host.size = Vector2(w, h)
    host.clip_contents = true
    _root.add_child(host)
    _made.append(host)
    return host


func _sweep_host(host: Control) -> Array:
    _findings = []
    _rects = {}
    _min_w_cache = {}
    _wants_cache = {}
    _screen_file = "probe"
    _scale = 100
    _refresh_theme(host)
    var frame := Rect2(Vector2.ZERO, host.size)
    _place(host, frame, frame, false)
    return _findings


func _kinds() -> Array:
    var out: Array = []
    for f in _findings:
        out.append(String(f["kind"]))
    return out


## The estimator must catch an overflowing Label, or the sweep above is the
## blind spot it exists to close: a one-line Label wider than its column, a
## clip_text Label narrower than its string, a wrap cut by max_lines_visible,
## and a column taller than the clipping box it sits in.
func test_the_estimator_catches_an_overflowing_label() -> void:
    var host := _themed_host(100.0, 40.0)
    var col := VBoxContainer.new()
    col.set_anchors_preset(Control.PRESET_FULL_RECT)
    host.add_child(col)
    var wide := Label.new()
    wide.text = "a line that is far too long for one hundred pixels"
    col.add_child(wide)
    _sweep_host(host)
    var kinds := _kinds()
    assert_true(WIDE in kinds or OVER in kinds or PAST in kinds,
        "a long one-line Label in a 100px column: %s" % str(_findings))
    var f: Dictionary = _findings[0]
    assert_true(String(f["detail"]).contains("a line that is far too long"),
        "the finding names the Label that set the width: " + str(f))
    assert_true(String(f["detail"]).contains("100"), "and what the column had: " + str(f))
    # The column that fits it is fine.
    var host2 := _themed_host(1000.0, 200.0)
    var col2 := VBoxContainer.new()
    col2.set_anchors_preset(Control.PRESET_FULL_RECT)
    host2.add_child(col2)
    var short := Label.new()
    short.text = "short"
    col2.add_child(short)
    var wrapped := Label.new()
    wrapped.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    wrapped.text = wide.text
    col2.add_child(wrapped)
    assert_eq(_sweep_host(host2).size(), 0, "a fitting column has no finding: %s" % str(_findings))


func test_the_estimator_catches_a_clipping_label_and_a_cut_wrap() -> void:
    var host := _themed_host(300.0, 300.0)
    var clip := Label.new()
    clip.text = "this string is wider than forty pixels"
    clip.clip_text = true
    clip.position = Vector2(0, 0)
    clip.size = Vector2(40, 20)
    host.add_child(clip)
    var cut := Label.new()
    cut.text = "a wrapped paragraph that needs several lines at one hundred pixels of width to be read"
    cut.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    cut.max_lines_visible = 1
    cut.position = Vector2(0, 40)
    cut.size = Vector2(100, 20)
    host.add_child(cut)
    _sweep_host(host)
    var kinds := _kinds()
    assert_true(CLIP in kinds, "a clip_text Label narrower than its string clips: %s" % str(kinds))
    assert_true(CUT in kinds, "max_lines_visible 1 under a three-line wrap is a cut: %s" % str(kinds))
    # A clip_text Label given its width is silent.
    var host2 := _themed_host(600.0, 100.0)
    var fine := Label.new()
    fine.text = clip.text
    fine.clip_text = true
    fine.size = Vector2(500, 20)
    host2.add_child(fine)
    assert_eq(_sweep_host(host2).size(), 0, str(_findings))


func test_the_estimator_catches_a_column_taller_than_its_clipping_box() -> void:
    var host := _themed_host(200.0, 400.0)
    var box := Control.new()
    box.clip_contents = true
    box.position = Vector2(10, 10)
    box.size = Vector2(150, 50)
    host.add_child(box)
    var col := VBoxContainer.new()
    col.set_anchors_preset(Control.PRESET_FULL_RECT)
    box.add_child(col)
    for i in 4:
        var l := Label.new()
        l.text = "row %d" % i
        col.add_child(l)
    _sweep_host(host)
    var kinds := _kinds()
    assert_true(OVER in kinds or PAST in kinds, "four rows in a 50px clipping box: %s" % str(kinds))
    var first: Dictionary = _findings[0]
    assert_true(String(first["detail"]).contains("has 50") or String(first["detail"]).contains("clip ends"),
        "the finding says what the box has: " + str(first))
    # One defect, one finding: the rows under the overflowing column stay quiet.
    var loud := 0
    for f in _findings:
        if String(f["kind"]) == PAST:
            loud += 1
    assert_true(loud <= 1, "the rows below the overflowing column do not each report the same edge: %d" % loud)


## The estimate agrees with the engine on the one quantity a test can read
## off-tree: a theme font's height is what a one-line Label of that variation
## measures in the tree (the in-tree dump: LabelBody 36 / LabelMuted 29 /
## LabelSmall 25 at 150; 24 / 19 / 17 at 100).
func test_the_estimate_uses_the_themes_own_fonts_at_the_scale() -> void:
    for scale in SCALES:
        var host := _themed_host(600.0, 100.0)
        host.theme = Theme_.get_theme(int(scale))
        var body := Widgets.label_as("Encounters cleared  0", "LabelBody")
        host.add_child(body)
        var muted := Widgets.label_as("Showing 12 of 12", "LabelMuted")
        host.add_child(muted)
        _refresh_theme(host)
        assert_eq(_px(body), Type.at(Type.BODY, int(scale)), "LabelBody's size at %d" % int(scale))
        var body_h: float = _wants_h(body, 600.0)
        var muted_h: float = _wants_h(muted, 600.0)
        assert_true(body_h > muted_h,
            "at %d the face-carrying LabelBody line (%.0f) is taller than LabelMuted's (%.0f), as the engine draws it"
            % [int(scale), body_h, muted_h])
        _min_w_cache = {}
        _wants_cache = {}
    var h150 := _themed_host(600.0, 100.0)
    h150.theme = Theme_.get_theme(150)
    var l := Widgets.label_as("Showing 12 of 12", "LabelMuted")
    h150.add_child(l)
    _refresh_theme(h150)
    assert_in_range(_wants_h(l, 600.0), 28.0, 30.0, "LabelMuted at 150 measured 29 in the tree")
    var body := Widgets.label_as("Encounters cleared  0", "LabelBody")
    h150.add_child(body)
    _refresh_theme(h150)
    assert_in_range(_wants_h(body, 600.0), 35.0, 37.0, "LabelBody at 150 measured 36 in the tree (the face sheet's height)")
    # And before the refresh a Label answers the engine's fallback — the fact
    # this file's door exists for.
    var raw := Widgets.label_as("Encounters cleared  0", "LabelBody")
    h150.add_child(raw)
    assert_ne(raw.get_theme_font_size("font_size"), Type.at(Type.BODY, 150),
        "off-tree, an unrefreshed Label does not see the theme (if it does now, drop _refresh_theme)")


# ---------------------------------------------------------------- the three 150 breaks, held

## (2) The Guildhall's sidebar fold never slices a block (report-W4-PIP.md's
## Note: the morale chart as a 10px sliver). The arithmetic is pure; the
## in-tree half is wired to the column's sort.
func test_the_guildhall_fold_lands_on_a_block_boundary() -> void:
    assert_eq(GuildhallScreen.fold_height([100.0, 100.0, 100.0], 10.0, 400.0), 400.0,
        "everything fits: the fold is the viewport")
    assert_eq(GuildhallScreen.fold_height([100.0, 100.0, 56.0, 100.0], 10.0, 250.0), 210.0,
        "the 56px block would be sliced at 250: the fold moves up to the block above it")
    assert_eq(GuildhallScreen.fold_height([300.0, 50.0], 10.0, 250.0), 250.0,
        "a first block taller than the viewport keeps the viewport and scrolls inside")
    assert_eq(GuildhallScreen.fold_height([], 10.0, 250.0), 250.0)
    _fixture()
    var screen := _mount("res://game/screens/Guildhall.tscn", 150)
    assert_ne(screen, null)
    var col: Control = screen.find_child("SideColumn", true, false) as Control
    assert_ne(col, null, "the roster view's column")
    assert_true((col as Container).sort_children.is_connected(screen._snap_fold),
        "the fold is recomputed on every sort of the column")
    var spacer: Control = screen.find_child("FoldSpacer", true, false) as Control
    assert_ne(spacer, null, "the spacer under the scroll")
    assert_false(spacer.visible, "hidden until a fold is needed (off-tree it never is)")
    var scroll: Control = screen.find_child("SidebarScroll", true, false) as Control
    assert_eq(spacer.get_parent(), scroll.get_parent(), "beside the scroll, above the rule")
    assert_true(spacer.get_index() == scroll.get_index() + 1)


## (3) The Tavern's seat card carries the authored face on its morale line and
## still holds its 262 at 150 with a wrapped class line — the fixed parts under
## the bullets' scroll are what must fit (Tavern.gd's header note).
func test_the_seat_card_holds_its_box_with_the_authored_face_at_150() -> void:
    _fixture()
    var screen := _mount("res://game/screens/Tavern.tscn", 150)
    assert_ne(screen, null)
    _sweep_screen(screen, "Tavern.tscn", 150)
    var strip: Control = screen.find_child("RosterStrip", true, false) as Control
    assert_ne(strip, null)
    var cards: Array = []
    _cards_in(strip, cards)
    assert_true(cards.size() >= 4, "the fixture's board shows four seat cards, found %d" % cards.size())
    var wrapped := 0
    for c in cards:
        var card := c as Control
        var morale: Control = card.find_child("Morale", true, false) as Control
        assert_ne(morale, null)
        var figure := morale.get_child(0) as Label
        assert_eq(String(figure.theme_type_variation), "LabelClass",
            "the morale line is on the face-carrying variation (HALL-05's authored face)")
        assert_true(_font(figure) != Theme_.get_theme(150).get_font("font", "LabelPip"),
            "and not LabelPip's bare bar font")
        var want: float = _wants_h(card, float(Widgets.CARD_SIZE.x))
        assert_true(want <= float(Widgets.CARD_SIZE.y) + TOL,
            "seat card '%s' wants %.0f of %d at 150" % [_card_name(card), want, Widgets.CARD_SIZE.y])
        var cls: Label = _class_line(card)
        if cls != null and _lines_at(_font(cls), _px(cls), cls.text, float(Widgets.CARD_SIZE.x) - 24.0, cls.autowrap_mode) > 1:
            wrapped += 1
    assert_true(wrapped >= 1, "the fixture's board has a class line that wraps at 150 (Warrior — Common), the case that broke")


func _cards_in(n: Node, out: Array) -> void:
    if n is PanelContainer and (n as Control).custom_minimum_size == Vector2(Widgets.CARD_SIZE):
        out.append(n)
        return
    for c in n.get_children():
        _cards_in(c, out)


func _card_name(card: Control) -> String:
    for l in _labels(card):
        if String((l as Label).theme_type_variation) == "LabelName":
            return (l as Label).text
    return "?"


func _class_line(card: Control) -> Label:
    for l in _labels(card):
        var lab := l as Label
        if lab.autowrap_mode != TextServer.AUTOWRAP_OFF and lab.text.contains(" — ") and String(lab.theme_type_variation) == "LabelMuted":
            return lab
    return null


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append(n)
    for c in n.get_children():
        _labels(c, out)
    return out


## (4) Completion's commit keeps its text verbatim, wraps to the lines it needs
## at 150 (three, in this column) and its plate ends inside the sidebar — the
## room is found above it (Completion.gd's SIDEBAR_GAP note).
func test_completions_commit_ends_inside_its_sidebar_at_150() -> void:
    _fixture()
    var screen := _mount("res://game/screens/Completion.tscn", 150)
    assert_ne(screen, null)
    _sweep_screen(screen, "Completion.tscn", 150)
    var back: Button = _button_with_text(screen, "Back to town — the guild carries on")
    assert_ne(back, null, "the commit's text is verbatim")
    var host: Control = screen.find_child("SidebarHost", true, false) as Control
    assert_ne(host, null)
    var r: Rect2 = _rects[back.get_instance_id()]
    var hr: Rect2 = _rects[host.get_instance_id()]
    assert_true(r.end.y <= hr.end.y + TOL,
        "the plate ends at %.0f, the sidebar at %.0f" % [r.end.y, hr.end.y])
    assert_true(_lines_at(_font(back), _px(back), back.text, r.size.x - _pad(back).x, back.autowrap_mode) >= 2,
        "the text wraps inside the plate rather than trimming")
    assert_eq(back.custom_minimum_size.y, float(Type.at(70, 150)), "the plate's floor scales with the text")


func _button_with_text(n: Node, text: String) -> Button:
    if n is Button and (n as Button).text == text:
        return n
    for c in n.get_children():
        var b := _button_with_text(c, text)
        if b != null:
            return b
    return null


## (5) Settings' control cell is COL_CTRL_W x CTRL_H at the text scale, and the
## chip/value buttons fit it at 150.
func test_settings_controls_fit_their_scaled_cell_at_150() -> void:
    _fixture()
    var screen := _mount("res://game/screens/Settings.tscn", 150)
    assert_ne(screen, null)
    _sweep_screen(screen, "Settings.tscn", 150)
    var ctrl_h: int = Type.at(SettingsScreen.CTRL_H, 150)
    assert_true(ctrl_h > SettingsScreen.CTRL_H, "CTRL_H scales (%d)" % ctrl_h)
    assert_true(ctrl_h <= Type.at(SettingsScreen.ROW_H, 150), "and stays inside the row's pitch")
    var rows := 0
    for row in SettingsScreen.ROWS:
        var line: Control = screen.find_child("Row_" + String(row["key"]), true, false) as Control
        assert_ne(line, null, "Row_" + String(row["key"]))
        if line == null:
            continue
        var cell: Control = _cell_of(line)
        assert_ne(cell, null, "the control cell of " + String(row["key"]))
        if cell == null:
            continue
        rows += 1
        assert_eq(cell.custom_minimum_size, Vector2(SettingsScreen.COL_CTRL_W, ctrl_h),
            "%s: COL_CTRL_W x CTRL_H at 150" % String(row["key"]))
        var need_w: float = _min_w(cell)
        var need_h: float = _wants_h(cell, float(SettingsScreen.COL_CTRL_W))
        assert_true(need_w <= float(SettingsScreen.COL_CTRL_W) + TOL,
            "%s: the control wants %.0f wide in %d" % [String(row["key"]), need_w, SettingsScreen.COL_CTRL_W])
        assert_true(need_h <= float(ctrl_h) + TOL,
            "%s: the control wants %.0f tall in %d" % [String(row["key"]), need_h, ctrl_h])
    assert_eq(rows, SettingsScreen.ROWS.size(), "every row's cell was measured")


## The control `_option_row` sized to the cell: the one descendant whose
## custom minimum is COL_CTRL_W wide.
func _cell_of(n: Node) -> Control:
    if n is Control and (n as Control).custom_minimum_size.x == float(SettingsScreen.COL_CTRL_W):
        return n
    for c in n.get_children():
        var found := _cell_of(c)
        if found != null:
            return found
    return null


## (6) The nav rail's label floor and its two-line fallback (UI-30, W7-STAGE).
const FrameScript = preload("res://game/ui/Frame.gd")


func test_every_rail_label_keeps_the_scaled_floor_and_fits_its_item() -> void:
    # UI-30: at 150 "Adventure's Board" drew at ~14px between 24px neighbours
    # because `RAIL_LABEL_FLOOR` was an UNSCALED constant — the step-down ran
    # the whole way. The floor is `Type.at(NAV - 2, pct)` now, and a string
    # still too wide at the floor wraps to two lines INSIDE the 55px item
    # instead of shrinking under it. Asserted on every route at every scale.
    _fixture()
    var seen := 0
    var wrapped_at_150 := 0
    for scale in SCALES:
        var floor_px: int = FrameScript.rail_label_floor(int(scale))
        assert_true(floor_px >= FrameScript.RAIL_LABEL_FLOOR,
            "the floor scales up, never down (%d at %d%%)" % [floor_px, int(scale)])
        for path in ROUTES:
            var screen := _mount(path, int(scale))
            if screen == null:
                continue
            for n in screen.find_children("RailLabel", "Label", true, false):
                var l := n as Label
                seen += 1
                var px: int = l.get_theme_font_size("font_size")
                assert_true(px >= floor_px,
                    "%s at %d%%: '%s' draws at %dpx, under the floor %d"
                    % [String(path).get_file(), int(scale), l.text, px, floor_px])
                if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
                    continue
                if int(scale) == 150:
                    wrapped_at_150 += 1
                assert_eq(l.max_lines_visible, 2, "a wrapped rail label is two lines, never three")
                var font: Font = l.get_theme_font("font")
                var block: float = 2.0 * font.get_height(px) \
                    + float(l.get_theme_constant("line_spacing"))
                assert_true(block <= float(Widgets.RAIL_ITEM_H) + TOL,
                    "%s at %d%%: '%s' wraps to %.0f in the %d item"
                    % [String(path).get_file(), int(scale), l.text, block, Widgets.RAIL_ITEM_H])
                assert_true(_lines_at(font, px, l.text, l.size.x, l.autowrap_mode) <= 2,
                    "'%s' needs no third line at %d%%" % [l.text, int(scale)])
    assert_true(seen >= 30, "walked the rails of the framed routes (%d labels)" % seen)
    assert_true(wrapped_at_150 >= 1,
        "the one canon name longer than the column ('Adventure's Board') takes the two-line rung at 150")
