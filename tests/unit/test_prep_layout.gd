extends "res://tests/TestCase.gd"
## W4-PREP — raid prep's layout contracts (build/plan/artaudit/00-plan.md §5;
## findings KIT-12, KIT-03, KIT-08, STAGE-01, KIT-09, CRITIC-G06).
##
## The runner is a SceneTree script (no layout pass, no `_ready`), so every
## geometry read here is a position/size the screen or the kit SET explicitly:
## the strip's cards and arrows, the arena's stage and band, the readout panel.
## Text is read the way every screen test reads it — Label.text / Button.text.

const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const PrepScript = preload("res://game/screens/RaidPrep.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Icons = preload("res://game/ui/Icons.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Fixture = preload("res://tools/fixture_reference.gd")

const PREP := "res://game/screens/RaidPrep.tscn"
const PREP_SOURCE := "res://game/screens/RaidPrep.gd"

var _db = null
var _made: Array = []
var _scale_before := -1
var _host: Control = null


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []
    _host = null


func after_each() -> void:
    if _scale_before >= 0:
        var gs = _root().get_node_or_null("GameSettings")
        if gs != null:
            gs.set_value("text_scale", _scale_before)
        _scale_before = -1
    # The autoloads outlive this file (LESSONS): put the state back, content
    # included, or another file's empty-roster assertion depends on order.
    var st = _root().get_node_or_null("GameState") if _root() != null else null
    if st != null:
        st.reset()
        st.set_content(null)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _autoloads() -> void:
    var root := _root()
    if root.get_node_or_null("GameState") == null:
        var st = GameStateScript.new()
        st.name = "GameState"
        root.add_child(st)
        _made.append(st)
    if root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        root.add_child(rt)
        _made.append(rt)
    if root.get_node_or_null("GameSettings") == null:
        var gs = SettingsScript.new()
        gs.name = "GameSettings"
        root.add_child(gs)
        _made.append(gs)


## The reference guild the shots use (tools/fixture_reference.gd): fifteen
## slots, a roster the prep chalks twelve of, a selected raid.
func _fixture_state():
    _autoloads()
    var st = _root().get_node_or_null("GameState")
    st.reset()
    Fixture.apply(st, _db, false)
    return st


## A state with no guild at all — what the a11y smoke's "empty" pass and the
## plain `RaidPrep` shot mount: no content, no roster, no encounter.
func _empty_state():
    _autoloads()
    var st = _root().get_node_or_null("GameState")
    st.reset()
    st.set_content(null)
    return st


## Mount through the REAL autoload router, as Boot does (LESSONS: screens
## resolve their router through Services, which returns the autoload).
## One host per test: a second `_mount()` in the same test re-routes into the
## host already registered (the router clears the old screen from ITS host).
func _mount():
    var root := _root()
    var r = root.get_node_or_null("ScreenRouter")
    if _host == null:
        _host = Control.new()
        _host.size = Vector2(1536, 1024)
        root.add_child(_host)
        _made.append(_host)
        r.register_host(_host)
    assert_true(r.goto(PREP), "could not open %s" % PREP)
    return r.current_screen()


func _find(n: Node, name: String):
    if n.name == name:
        return n
    for c in n.get_children():
        var found = _find(c, name)
        if found != null:
            return found
    return null


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


func _joined(n: Node) -> String:
    return "\n".join(PackedStringArray(_texts(n)))


func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out


func _button_named(n: Node, text: String):
    for b in _buttons(n):
        if (b as Button).text == text:
            return b
    return null


func _source() -> String:
    return FileAccess.get_file_as_string(PREP_SOURCE)


## The strip's cards: the RosterStrip children the kit sized to CARD_SIZE.
func _card_rects(strip: Control) -> Array:
    var out: Array = []
    for c in strip.get_children():
        if c is Control and (c as Control).size == Vector2(Widgets.CARD_SIZE):
            out.append(Rect2((c as Control).position, (c as Control).size))
    return out


# ================================================================ KIT-12

func test_no_pager_rect_intersects_a_card_rect() -> void:
    _fixture_state()
    var view = _mount()
    var strip = _find(view, "RosterStrip")
    assert_ne(strip, null, "the strip is Cards.roster_strip's one wrap")
    var cards := _card_rects(strip)
    assert_eq(cards.size(), Cards.PAGE, "twelve chalked: a full page of four cards")
    var pager_parts: Array = []
    for name in ["PagerPrev", "PagerNext", "PageCaption"]:
        var p = _find(strip, name)
        assert_ne(p, null, "%s is the strip's own (three pages of twelve)" % name)
        if p != null:
            pager_parts.append(p)
    for p in pager_parts:
        var pr := Rect2((p as Control).position, (p as Control).size)
        for cr in cards:
            assert_false(pr.intersects(cr),
                "%s %s must not share pixels with a card %s (KIT-12)" % [p.name, pr, cr])
    assert_true(_source().find("_pager(") < 0, "the hand-placed pager is gone from RaidPrep.gd")
    assert_true(_source().find("pager_button(") < 0, "RaidPrep.gd draws no arrow of its own")


# ================================================================ KIT-03

func test_the_dead_chip_builder_is_gone() -> void:
    var src := _source()
    assert_true(src.find("func _chips(") < 0, "RaidPrep.gd:181's dead _chips() is deleted")
    assert_true(src.find("sun.png") < 0, "and nothing here names sun.png")
    assert_true(src.find("Frame.standard_chips(") >= 0, "the header row is the shell's")


# ================================================================ KIT-08

func test_an_empty_bench_shows_its_seats() -> void:
    _fixture_state()
    var view = _mount()
    assert_true(_joined(view).contains("Bench   0"), "everyone is chalked, so the bench is empty")
    var strip = _find(view, "RosterStrip")
    var grid = null
    for n in _descendants(strip):
        if n is GridContainer:
            grid = n
            break
    assert_ne(grid, null, "the bench is the strip's mini-grid")
    assert_eq(grid.get_child_count(), PrepScript.BENCH_SEATS,
        "an empty bench pads to its eight seats instead of a blank panel")
    for cell in grid.get_children():
        assert_eq(cell.theme_type_variation, "SlotMini", "each seat is the kit's empty mini slot")


func test_nothing_chalked_says_so_under_the_bench_glyph() -> void:
    _empty_state()
    var view = _mount()
    var empty = _find(view, "StripEmpty")
    assert_ne(empty, null, "a guild with no raiders gets the strip's empty state")
    assert_true(empty is Label, "the sentence is a Label the tests can read")
    assert_eq(empty.text, "No raiders to chalk.")
    var glyph = _find(empty, "Glyph")
    assert_ne(glyph, null, "under the kit's glyph")
    assert_eq(glyph.texture, Icons.at("empty", "bench"), "the bench glyph (KIT-08)")
    var hint = _find(empty, "Hint")
    assert_ne(hint, null)
    assert_eq(hint.text, "The Tavern has candidates.")
    assert_eq(empty.mouse_filter, Control.MOUSE_FILTER_IGNORE, "overlays ignore the mouse")
    # It covers the card band and nothing else: right of the Bench panel, left
    # of the log's gutter, never over the strip's pager column.
    var x0 := float(Widgets.CARD_X0 - 13)
    assert_eq(empty.position, Vector2(x0, 0))
    assert_eq(empty.size, Vector2(float(Cards.PAGER_NEXT_X) - x0, float(Widgets.STRIP_H)))


func test_benching_everyone_leaves_the_chalk_hint_not_the_tavern_one() -> void:
    _fixture_state()
    var view = _mount()
    for id in view.chalked_ids().duplicate():
        view._toggle(String(id))
    assert_eq(view.chalked_ids().size(), 0)
    var empty = _find(view, "StripEmpty")
    assert_ne(empty, null)
    assert_eq(empty.text, "No one is chalked.")
    assert_eq(_find(empty, "Hint").text, "Press a face on the bench to chalk them.")
    assert_true(_joined(view).contains("Bench   12"), "the twelve are on the bench")


# ================================================================ STAGE-01

func test_the_band_is_the_marks_grown_by_a_figure() -> void:
    var m := SceneStage.marks(SceneStage.DEFAULT_ARENA)
    assert_true(m.has("party"), "the cave ships party marks")
    var band: Rect2 = PrepScript.fight_band(m)
    assert_true(band.size.x > 0.0 and band.size.y > 0.0)
    var sc: float = float(m["party"].get("scale", 1.0))
    for rank in m["party"]["ranks"]:
        for x in rank["xs"]:
            var feet := Vector2(float(x), float(rank["y"]))
            assert_true(band.has_point(feet), "feet %s inside the band %s" % [feet, band])
            # Room for a figure above the feet at the mark's scale: the
            # shortest class strip is 37 rows (actors.json), so 37*scale is
            # the least any figure needs.
            assert_true(band.position.y <= feet.y - 37.0 * sc,
                "the band rises at least a figure above %s" % feet)
    assert_eq(PrepScript.fight_band({}), Rect2(), "a scene with no marks has no band")
    assert_eq(PrepScript.fight_band({"party": {"ranks": []}}), Rect2())


func test_the_arena_view_is_the_marks_view_centred_on_the_band() -> void:
    var m := SceneStage.marks(SceneStage.DEFAULT_ARENA)
    var host := Vector2(Widgets.SCENE.size)
    var view: Vector2 = PrepScript.arena_view(m, host)
    assert_eq(view.y, float(m["view"][1]), "the rows are the mark's — RaidView's rows")
    var band: Rect2 = PrepScript.fight_band(m)
    var on_host := Rect2(band.position + view, band.size)
    var column := Rect2(0.0, 0.0, float(PrepScript.READOUT_X), host.y)
    assert_true(column.encloses(on_host),
        "the band %s sits in the column left of the readout (%s)" % [on_host, column])
    assert_almost(on_host.get_center().x, float(PrepScript.READOUT_X) * 0.5, 1.0,
        "centred in it")
    # The plate never shows an edge.
    assert_true(view.x <= 0.0 and view.x >= host.x - PrepScript.PLATE.x)
    assert_true(view.y <= 0.0 and view.y >= host.y - PrepScript.PLATE.y)
    # A scene without marks: RaidView's own fallback rows.
    assert_eq(PrepScript.arena_view({}, host), PrepScript.ARENA_OFFSET)
    assert_eq(PrepScript.ARENA_OFFSET, Vector2(0, -280),
        "the fallback is RaidView.ARENA_OFFSET so a mark-less scene still shares the band")


func test_the_mounted_arena_is_dimmed_framed_and_ignores_the_mouse() -> void:
    _fixture_state()
    var view = _mount()
    var host = _find(view, "SceneHost")
    assert_ne(host, null)
    var m := SceneStage.marks(SceneStage.DEFAULT_ARENA)
    var want: Vector2 = PrepScript.arena_view(m, host.size)
    var stage = null
    for c in host.get_children():
        if String(c.name).begins_with("SceneStage_"):
            stage = c
    assert_ne(stage, null, "the arena stage is on the scene host")
    assert_eq(stage.name, "SceneStage_" + SceneStage.DEFAULT_ARENA)
    assert_eq(stage.position, want, "the stage sits where the marks put it")
    assert_eq(stage.modulate, PrepScript.SCENE_DIM, "dimmed under the readout")
    var rim = _find(host, "FightBand")
    assert_ne(rim, null, "the band is framed")
    var band: Rect2 = PrepScript.fight_band(m)
    assert_eq(rim.position, band.position + want)
    assert_eq(rim.size, band.size)
    assert_eq(rim.mouse_filter, Control.MOUSE_FILTER_IGNORE)
    var sb: StyleBox = rim.get_theme_stylebox("panel")
    assert_true(sb is StyleBoxFlat and not (sb as StyleBoxFlat).draw_center, "a rim, not a plate")
    assert_eq((sb as StyleBoxFlat).border_width_top, PrepScript.BAND_RIM_W)
    var scrim = _find(host, "BandScrim")
    assert_ne(scrim, null, "the arena outside the band is dimmed a second time")
    assert_eq(scrim.get_child_count(), 4, "four rects around the band")
    var covered := 0.0
    for c in scrim.get_children():
        assert_true(c is ColorRect)
        assert_eq(c.mouse_filter, Control.MOUSE_FILTER_IGNORE)
        assert_false(Rect2(c.position, c.size).intersects(Rect2(rim.position, rim.size)),
            "no scrim over the band")
        covered += c.size.x * c.size.y
    assert_almost(covered + rim.size.x * rim.size.y, host.size.x * host.size.y, 1.0,
        "scrim + band tile the whole host")
    # W6-AUD-BIND, LOOP C29: no caption over an empty band — "The party stands
    # here" was a screen admitting an unbuilt thing. W7-PREP: the party stands
    # on it now, and the rim is a focus outline — hidden until the strip has
    # the keyboard (test_the_rim_is_a_focus_outline_for_the_strip).
    assert_eq(_find(host, "FightBandCaption"), null, "C29: the band carries no caption")
    assert_false(rim.visible, "UI-16: the rim shows only while the strip has focus")
    # Tree order: stage, scrim, rim all BEFORE the readout panel, so the four
    # readouts draw over every one of them.
    var readout = null
    for c in host.get_children():
        if c is PanelContainer and c.position == PrepScript.READOUT_POS:
            readout = c
    assert_ne(readout, null, "the readout panel is at its place")
    assert_true(readout.get_index() > rim.get_index(), "the readout draws over the band chrome")


# ================================================================ KIT-09

func test_the_verdict_callout_carries_its_sweep_and_flourish() -> void:
    _fixture_state()
    var view = _mount()
    var printed := _joined(view)
    assert_true(printed.contains("Verdict:"))
    var host = view._verdict_host
    assert_ne(host, null)
    assert_eq(host.get_child_count(), 1, "one callout")
    var callout = host.get_child(0)
    assert_true(callout is PanelContainer, "Widgets.callout's plate")
    assert_ne(_find(callout, "Flourish"), null, "with its flourish (KIT-09)")
    var sb: StyleBox = callout.get_theme_stylebox("panel")
    assert_true(sb is StyleBoxTexture, "the plate is the gradient sweep, not the flat theme box")
    assert_true((sb as StyleBoxTexture).texture is GradientTexture2D, "a GradientTexture2D sweep")
    assert_true(_joined(callout).contains("mistakes"), "the figure is the sim's expected mistakes")


# ================================================================ CRITIC-G06

func test_depart_is_the_crimson_button_and_enabled_with_a_party() -> void:
    _fixture_state()
    var view = _mount()
    var depart = _button_named(view, "Depart")
    assert_ne(depart, null, "Depart stays a Button found by its text")
    assert_false(depart.disabled)
    assert_true(String(depart.theme_type_variation).begins_with("ButtonCta"),
        "the crimson commit (ButtonCtaCost inherits ButtonCta)")
    var cost = _find(depart, "Cost")
    assert_ne(cost, null, "10 §2 R7: the sub-line inside the plate reports the party")
    assert_eq(cost.text, "12 of 12 chalked")
    assert_eq(depart.focus_mode, Control.FOCUS_ALL)
    assert_eq(depart.icon, null, "no padlock while it can leave")
    var host = _find(view, "DepartHost")
    assert_ne(host, null)
    assert_eq(_find(host, "Reason"), null, "and no reason Label")
    assert_true(host.is_ancestor_of(depart), "the button lives in the reasoned box")
    assert_ne(_button_named(view, "Bench"), null, "the in-card Bench action is kept")


func test_depart_with_nobody_chalked_is_reasoned() -> void:
    _fixture_state()
    var view = _mount()
    for id in view.chalked_ids().duplicate():
        view._toggle(String(id))
    var depart = _button_named(view, "Depart")
    assert_ne(depart, null)
    assert_true(depart.disabled, "nobody to send")
    var host = _find(view, "DepartHost")
    var why = _find(host, "Reason")
    assert_ne(why, null, "the reason is a Label beside the button (CRITIC-G06)")
    assert_eq(why.text, "Chalk at least one raider.")
    assert_eq(why.get_parent(), depart.get_parent(), "directly under it, in the same box")
    assert_ne(depart.icon, null, "the padlock in the leading slot")
    assert_almost(depart.modulate.a, Widgets.REASONED_DIM, 0.001, "dimmed the kit's way")
    assert_true(_joined(view).contains("0 of 12 chalked"))
    # Chalk one back: the gate lifts and the reason goes.
    var bench_button = null
    for b in _buttons(_find(view, "RosterStrip")):
        if b.theme_type_variation == "ButtonMini":
            bench_button = b
            break
    assert_ne(bench_button, null, "a bench tile is a Button")
    bench_button.pressed.emit()
    depart = _button_named(view, "Depart")
    assert_false(depart.disabled)
    assert_eq(_find(_find(view, "DepartHost"), "Reason"), null)


func test_depart_with_no_mission_says_so() -> void:
    _empty_state()
    var view = _mount()
    var depart = _button_named(view, "Depart")
    assert_ne(depart, null)
    assert_true(depart.disabled)
    var why = _find(_find(view, "DepartHost"), "Reason")
    assert_ne(why, null)
    assert_eq(why.text, "No mission chosen. Pick one on the board.")
    assert_ne(_button_named(view, "Back to the board"), null, "the way out is still there")


# ================================================================ G15

## Give every wrapped Label in `n` the width it will have on screen, so its
## minimum HEIGHT is the wrapped height and not the one-word-per-line height a
## zero-width Label reports before its first layout pass (test_tavern_layout).
func _settle_wraps(n: Node, fallback_w: float) -> void:
    if n is Label and (n as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
        var l := n as Label
        l.size = Vector2(maxf(l.custom_minimum_size.x, fallback_w), 0)
    for c in n.get_children():
        _settle_wraps(c, fallback_w)


## The box a panel's content actually has: the host less the Pad's margins and
## the variation's own content margins (LESSONS: PanelWarm adds 14 under the
## 18). The stylebox is read off the theme by the variation's name — asked
## through the node in the runner it answered an empty box (W4-PREP probe).
func _inner(panel: Control, outer: Vector2) -> Vector2:
    var pad = Widgets.content_of(panel)
    var th: Theme = Theme_.get_theme()
    assert_true(th.has_stylebox("panel", panel.theme_type_variation),
        "sanity: %s is a registered variation" % panel.theme_type_variation)
    var chrome: Vector2 = th.get_stylebox("panel", panel.theme_type_variation).get_minimum_size()
    return outer - Vector2(
        pad.get_theme_constant("margin_left") + pad.get_theme_constant("margin_right"),
        pad.get_theme_constant("margin_top") + pad.get_theme_constant("margin_bottom")) - chrome


## The minimum a subtree really needs, computed by hand: in the runner a
## PanelContainer or MarginContainer reports (0,0) until its first layout pass
## (seen in the W4-PREP probe), so a VBox holding a card or a callout under-
## counts by the whole card. Box/Margin/Panel/Scroll are walked; a leaf (Label,
## Button, slot, rule) answers for itself. Wrapped Labels must be settled first.
func _min_of(c: Control) -> Vector2:
    if not c.visible:
        return Vector2.ZERO
    var m := Vector2.ZERO
    if c is VBoxContainer or c is HBoxContainer:
        var vertical := c is VBoxContainer
        var sep: float = c.get_theme_constant("separation")
        var n := 0
        for ch in c.get_children():
            if not (ch is Control) or not (ch as Control).visible:
                continue
            var cm := _min_of(ch)
            if vertical:
                m.y += cm.y
                m.x = maxf(m.x, cm.x)
            else:
                m.x += cm.x
                m.y = maxf(m.y, cm.y)
            n += 1
        if n > 1 and vertical:
            m.y += sep * float(n - 1)
        elif n > 1:
            m.x += sep * float(n - 1)
    elif c is ScrollContainer:
        for ch in c.get_children():
            if ch is Control and (ch as Control).visible:
                var cm := _min_of(ch)
                if c.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
                    m.x = maxf(m.x, cm.x)
                if c.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
                    m.y = maxf(m.y, cm.y)
    elif c is MarginContainer:
        for ch in c.get_children():
            if ch is Control and (ch as Control).visible:
                m = m.max(_min_of(ch))
        m += Vector2(
            c.get_theme_constant("margin_left") + c.get_theme_constant("margin_right"),
            c.get_theme_constant("margin_top") + c.get_theme_constant("margin_bottom"))
    elif c is PanelContainer:
        for ch in c.get_children():
            if ch is Control and (ch as Control).visible:
                m = m.max(_min_of(ch))
        var sb: StyleBox = c.get_theme_stylebox("panel")
        if sb != null:
            m += sb.get_minimum_size()
    elif c is HFlowContainer:
        for ch in c.get_children():
            if ch is Control and (ch as Control).visible:
                m.y = maxf(m.y, _min_of(ch).y)
    else:
        m = c.get_combined_minimum_size()
    return m.max(c.custom_minimum_size)


func _set_scale(pct: int) -> void:
    var gs = _root().get_node_or_null("GameSettings")
    if _scale_before < 0:
        _scale_before = int(gs.get_value("text_scale"))
    gs.set_value("text_scale", pct)


func test_the_sidebar_fits_without_a_bar_at_100_and_never_widens() -> void:
    _fixture_state()
    _set_scale(100)
    var view = _mount()
    var host = _find(view, "SidebarHost")
    var panel = _find(view, "Sidebar")
    var inner: Vector2 = _inner(panel, host.size)
    assert_eq(inner, Vector2(314, 571), "378x635 less 18+14 each side (LESSONS)")
    var col = _find(view, "SidebarCol")
    var info = _find(view, "SidebarInfo")
    var scroll = _find(view, "SidebarScroll")
    assert_ne(scroll, null, "the mission block scrolls when it must (TOWN-17's shape)")
    assert_eq(scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
    assert_true(scroll.follow_focus, "a keyboard reaching a control scrolls it into view")
    _settle_wraps(col, PrepScript.SIDEBAR_TEXT_W)
    # Height: the whole column — the scrolling block AND the footer — fits the
    # host at 100% so no bar shows on the common case (the card and the
    # callout are PanelContainers, which the runner counts as 0: _min_of).
    var gap: float = col.get_theme_constant("separation")
    var need: float = _min_of(info).y
    for c in col.get_children():
        if c != scroll:
            need += gap + _min_of(c).y
    assert_true(need <= inner.y,
        "the sidebar wants %.0fpx of its %.0f at 100%% — no bar, nothing past the rim" % [need, inner.y])
    assert_true(need > 300.0, "sanity: the arithmetic saw the card and the callout (%.0f)" % need)
    # Width: nothing in the column claims more than the column has, at either
    # scale — the art well is the one thing at the full 314, and text stops
    # 12px short of it for the bar.
    for scale in [100, 150]:
        _set_scale(scale)
        view = _mount()
        col = _find(view, "SidebarCol")
        _settle_wraps(col, PrepScript.SIDEBAR_TEXT_W)
        var inner_w: float = _inner(_find(view, "Sidebar"), _find(view, "SidebarHost").size).x
        assert_true(_min_of(col).x <= inner_w,
            "at %d%% the column claims %.0f of %.0f — one uncapped Label widens the rim (LESSONS)"
                % [scale, _min_of(col).x, inner_w])
        # The scrolling block leaves the bar its 8px: a ScrollContainer adds a
        # visible bar to its child's minimum, and 314 + 8 made the panel 386
        # wide at 150% (probe). Nothing inside the scroll claims more than 306.
        assert_true(_min_of(_find(view, "SidebarInfo")).x <= inner_w - 8.0,
            "at %d%% the mission block claims %.0f; the bar needs 8 of the %.0f"
                % [scale, _min_of(_find(view, "SidebarInfo")).x, inner_w])
        var depart = _button_named(view, "Depart")
        assert_true(_min_of(depart).x <= inner_w, "the CTA fits the column")
        var why = _find(_find(view, "DepartHost"), "Reason")
        assert_eq(why, null, "the fixture can leave: no reason under Depart")


func test_the_readout_fits_at_100_and_wraps_at_150() -> void:
    _fixture_state()
    _set_scale(100)
    var view = _mount()
    var panel = _find(view, "Readout")
    assert_ne(panel, null)
    var inner: Vector2 = _inner(panel, PrepScript.READOUT_SIZE)
    var col = _find(view, "ReadoutCol")
    _settle_wraps(col, PrepScript.READOUT_TEXT_W)
    assert_true(_min_of(col).y <= inner.y,
        "docs/13 §10.2: all four readouts in view at 100%% — %.0f of %.0f"
            % [_min_of(col).y, inner.y])
    assert_ne(_find(view, "ReadoutScroll"), null, "and a scroll for the scale that cannot")
    for scale in [100, 150]:
        _set_scale(scale)
        view = _mount()
        col = _find(view, "ReadoutCol")
        _settle_wraps(col, PrepScript.READOUT_TEXT_W)
        var w: float = _inner(_find(view, "Readout"), PrepScript.READOUT_SIZE).x
        assert_true(_min_of(col).x <= w,
            "at %d%% a readout line claims %.0f of %.0f" % [scale, _min_of(col).x, w])
        var lines := 0
        for c in col.get_children():
            if c is Label:
                lines += 1
                assert_eq((c as Label).autowrap_mode, TextServer.AUTOWRAP_WORD_SMART,
                    "'%s' wraps rather than clips" % (c as Label).text.left(30))
                assert_eq((c as Label).text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING,
                    "and is never trimmed (a number may not be cut)")
        assert_true(lines >= 12, "the readout is still its lines (%d)" % lines)


func test_the_callout_figure_wraps_instead_of_running_past_the_rim() -> void:
    _fixture_state()
    _set_scale(150)
    var view = _mount()
    var callout = view._verdict_host.get_child(0)
    var figure = PrepScript._figure_of(callout)
    assert_ne(figure, null, "the kit's LabelFigure is where it was")
    assert_eq(figure.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
    assert_true(figure.text.contains("mistakes"))


# ================================================================ provisions

func test_the_provisions_sit_in_the_strips_log_slot_and_wrap_there() -> void:
    _fixture_state()
    var view = _mount()
    var strip = _find(view, "RosterStrip")
    var prov = _find(view, "Provisions")
    assert_ne(prov, null, "docs/11 §7's provisions panel is on the strip")
    assert_eq(prov.get_parent(), strip.get_parent(), "beside the roster strip, under the strip host")
    assert_eq(prov.position, PrepScript.PROVISIONS_POS, "in Cards.event_log's slot (x 1032)")
    assert_eq(prov.size, PrepScript.PROVISIONS_SIZE)
    var pr := Rect2(prov.position, prov.size)
    for cr in _card_rects(strip):
        assert_false(pr.intersects(cr), "never over a card")
    for name in ["PagerPrev", "PagerNext", "PageCaption"]:
        var p = _find(strip, name)
        assert_false(pr.intersects(Rect2(p.position, p.size)), "never over the pager")
    var printed := _joined(prov)
    assert_true(printed.contains("Provisions"))
    assert_true(printed.contains("The cupboard is bare. The Market sells provisions."),
        "the fixture's cupboard is bare, and the sentence is a Label")
    assert_eq(_find(view, "SidebarInfo").get_node_or_null("ProvisionsCol"), null,
        "and it left the sidebar")
    for scale in [100, 150]:
        _set_scale(scale)
        view = _mount()
        prov = _find(view, "Provisions")
        var col = _find(prov, "ProvisionsCol")
        _settle_wraps(col, PrepScript.PROVISIONS_TEXT_W)
        var inner: Vector2 = _inner(prov, prov.size)
        assert_true(_min_of(col).x <= inner.x, "at %d%% the lines wrap inside the panel" % scale)
        assert_true(_min_of(col).y <= inner.y, "and fit its height")


func _descendants(n: Node, out: Array = []) -> Array:
    for c in n.get_children():
        out.append(c)
        _descendants(c, out)
    return out


# ================================================================ W7-PREP

const RaidPlan = preload("res://game/core/RaidPlan.gd")
const Consumables = preload("res://sim/core/Consumables.gd")
const DETAIL := "res://game/screens/RaiderDetail.tscn"


## The prep stage on the scene host.
func _stage_of(view: Control) -> Control:
    var host = _find(view, "SceneHost")
    for c in host.get_children():
        if String(c.name).begins_with("SceneStage_"):
            return c
    return null


## The stage's children by name prefix, in tree order.
func _named(stage: Node, prefix: String) -> Array:
    var out: Array = []
    for c in stage.get_children():
        if String(c.name).begins_with(prefix):
            out.append(c)
    return out


# ---------------------------------------------------------------- UI-16 / LOOP-09

func test_the_chalked_party_stands_on_the_band_and_benching_takes_a_figure_off() -> void:
    _fixture_state()
    var view = _mount()
    var stage := _stage_of(view)
    assert_ne(stage, null)
    var ids: Array = view.chalked_ids()
    assert_eq(ids.size(), 12, "the fixture chalks twelve")
    var actors := _named(stage, "Actor_")
    assert_eq(actors.size(), 12, "twelve figures on the band, one per chalked raider")
    for id in ids:
        var spr = stage.get_node_or_null("Actor_%s" % String(id))
        assert_ne(spr, null, "%s stands on the band, named by id" % String(id))
        assert_true(spr is AnimatedSprite2D, "a figure the stage built (add_actor)")
        # `add_actor` puts the contact shadow directly before its figure.
        var shadow: Node = stage.get_child(spr.get_index() - 1)
        assert_true(String(shadow.name).begins_with("Shadow_"), "with its own shadow under it")
    assert_eq(_named(stage, "Seat_").size(), 0, "a full chalkboard has no empty seat")
    # The formation is the marks' own: every figure's feet on one of the ranks'
    # points, at the mark's scale, facing the mark's way (RaidView's rule).
    var m := SceneStage.marks(SceneStage.DEFAULT_ARENA)
    var feet := {}
    for rank in m["party"]["ranks"]:
        for x in rank["xs"]:
            feet[Vector2(float(x), float(rank["y"]))] = true
    var sc := float(m["party"].get("scale", 1.0))
    for spr in actors:
        assert_true(feet.has((spr as Node2D).position), "%s stands on a mark: %s" % [spr.name, spr.position])
        assert_eq((spr as Node2D).scale, Vector2(sc, sc))
    # Bench one: eleven figures, the benched one gone, one greyed seat.
    var gone := String(ids[0])
    view._toggle(gone)
    assert_eq(_named(stage, "Actor_").size(), 11, "benching takes the figure off the band")
    assert_eq(stage.get_node_or_null("Actor_%s" % gone), null, "and it is that raider's figure")
    assert_eq(_named(stage, "Seat_").size(), 1, "the empty mark is a greyed seat")
    var seat = _named(stage, "Seat_")[0]
    assert_true(seat is Sprite2D)
    var grey: Color = SceneStage.party_state_style("downed")["tint"]
    assert_almost((seat as Sprite2D).modulate.r, grey.r, 0.001, "party_state_style's grey")
    assert_almost((seat as Sprite2D).modulate.a, PrepScript.SEAT_ALPHA, 0.001)
    assert_true(seat.get_index() < _named(stage, "Actor_")[0].get_index(), "under the figures")
    # Chalk them back: twelve again, no seat, and the id is a figure again.
    view._toggle(gone)
    assert_eq(_named(stage, "Actor_").size(), 12)
    assert_eq(_named(stage, "Seat_").size(), 0)
    assert_ne(stage.get_node_or_null("Actor_%s" % gone), null)
    # Bench everyone: no figures, twelve seats, and the strip's empty state.
    for id in view.chalked_ids().duplicate():
        view._toggle(String(id))
    assert_eq(_named(stage, "Actor_").size(), 0, "an empty chalkboard stands nobody")
    assert_eq(_named(stage, "Shadow_").size(), 0, "and leaves no shadow behind")
    assert_eq(_named(stage, "Seat_").size(), 12, "twelve greyed seats")
    assert_ne(_find(view, "StripEmpty"), null, "the strip's empty state does the talking")


func test_the_stage_forgets_a_benched_figure() -> void:
    # `add_actor` keeps its own list and `apply_settings` walks it; a freed
    # sprite left there would trip the next reduced-motion pass. The screen
    # scrubs what it takes off (LESSONS: built vs armed — assert the wire).
    _fixture_state()
    var view = _mount()
    var stage := _stage_of(view)
    for id in view.chalked_ids().slice(0, 6):
        view._toggle(String(id))
    var list = stage.get("_actors")
    assert_true(list is Array, "SceneStage still keeps `_actors`")
    for s in list:
        assert_true(is_instance_valid(s), "no freed figure left in the stage's list")
    assert_eq((list as Array).size(), _named(stage, "Actor_").size(),
        "the cave ships no actors of its own, so the list is exactly the party")
    # Reduced motion applied AFTER a bench must not throw and must hold the six.
    stage.apply_settings(true, false)
    for spr in _named(stage, "Actor_"):
        assert_false((spr as AnimatedSprite2D).is_playing(), "held still")


func test_the_rim_is_a_focus_outline_for_the_strip() -> void:
    _fixture_state()
    var view = _mount()
    var rim = _find(_find(view, "SceneHost"), "FightBand")
    assert_ne(rim, null)
    assert_false(rim.visible, "hidden until the strip has the focus")
    var bench = _button_named(view, "Bench")
    assert_ne(bench, null)
    view._on_focus_changed(bench)
    assert_true(rim.visible, "a card's Bench is in the strip: the rim shows")
    view._on_focus_changed(_button_named(view, "Depart"))
    assert_false(rim.visible, "Depart is the sidebar's: the rim hides")
    view._on_focus_changed(null)
    assert_false(rim.visible)


# ---------------------------------------------------------------- UI-39 / LOOP-29

## The fixture with two of every raid-day provision in the cupboard.
func _stocked_state():
    var st = _fixture_state()
    st.add_gold(1000)
    for sku_id in Consumables.SKUS:
        assert_eq(st.buy_consumable(String(sku_id), 1, 2), "", "stocking %s" % sku_id)
    return st


func test_every_provision_button_carries_its_icon_and_keeps_its_text() -> void:
    var st = _stocked_state()
    var purse: int = st.gold
    var view = _mount()
    var prov = _find(view, "Provisions")
    assert_ne(prov, null)
    var buttons := _buttons(prov)
    var raid_day := 0
    for sku_id in Consumables.SKUS:
        if Consumables.kind_of(String(sku_id)) != Consumables.Kind.POST_WIPE:
            raid_day += 1
    assert_eq(buttons.size(), raid_day, "one button per raid-day provision held (the flask is post-wipe)")
    var seen := {}
    for b in buttons:
        var btn := b as Button
        assert_ne(btn.icon, null, "'%s' carries an icon (UI-39)" % btn.text)
        assert_eq(btn.icon_alignment, HORIZONTAL_ALIGNMENT_LEFT, "in the leading slot")
        assert_false(btn.expand_icon, "at its own 32px")
        assert_eq(btn.focus_mode, Control.FOCUS_ALL)
        # The text is verbatim: "<name>  chosen/held".
        var matched := ""
        for sku_id in Consumables.SKUS:
            var name := Consumables.display_name(String(sku_id), 1)
            if btn.text == "%s  0/2" % name:
                matched = String(sku_id)
        assert_ne(matched, "", "'%s' is still '<name>  0/2'" % btn.text)
        assert_eq(btn.icon, Icons.at("item", matched), "the Market shelf's icon for %s" % matched)
        seen[matched] = true
    assert_eq(seen.size(), raid_day, "every provision once")
    # Pressing one still chalks it and the text still moves.
    (buttons[0] as Button).pressed.emit()
    var again := _buttons(_find(view, "Provisions"))
    var chosen := 0
    for b in again:
        if (b as Button).text.ends_with("1/2"):
            chosen += 1
        assert_ne((b as Button).icon, null, "the icon survives the refresh")
    assert_eq(chosen, 1, "one chalked")
    assert_eq(st.gold, purse, "chalking spends nothing (docs/11 §7)")


func test_the_quarters_furnishing_buttons_carry_the_market_icon() -> void:
    var st = _fixture_state()
    st.selected_raider_id = st.roster[0].id
    var root := _root()
    var r = root.get_node_or_null("ScreenRouter")
    if _host == null:
        _host = Control.new()
        _host.size = Vector2(1536, 1024)
        root.add_child(_host)
        _made.append(_host)
        r.register_host(_host)
    assert_true(r.goto(DETAIL), "could not open %s" % DETAIL)
    var view = r.current_screen()
    var found := 0
    for b in _buttons(view):
        var btn := b as Button
        if not btn.text.begins_with("Straw Cot"):
            continue
        found += 1
        assert_eq(btn.icon, Icons.at("furnishing", "straw_cot"), "the Market's straw cot icon (LOOP-29)")
        assert_eq(btn.icon_alignment, HORIZONTAL_ALIGNMENT_LEFT)
        assert_false(btn.expand_icon)
        assert_true(btn.text.contains("40 G"), "the text is verbatim: %s" % btn.text)
    assert_eq(found, 1, "the fixture's raider is offered a Straw Cot in Quarters")


# ---------------------------------------------------------------- UI-14

func test_the_rewards_row_shows_exactly_the_drops_there_are() -> void:
    var st = _fixture_state()
    var notices: Array = []
    notices.append_array(_db.tutorial_encounters(1))
    notices.append_array(_db.adventure_encounters(1))
    notices.append_array(_db.raid_encounters(1))
    assert_true(notices.size() >= 10, "every Tier-1 notice (%d)" % notices.size())
    var seen_one := false
    for e in notices:
        st.selected_encounter_id = String(e.id)
        var view = _mount()
        var n: int = e.loot_slots.size()
        var row = _find(_find(view, "SidebarInfo"), "Rewards")
        var none = _find(_find(view, "SidebarInfo"), "NoRewards")
        if n == 0:
            assert_eq(row, null, "%s: no row for no drops" % e.slot)
            assert_ne(none, null)
            assert_eq(none.text, "Nothing worth carrying.")
        else:
            assert_ne(row, null, "%s: a rewards row" % e.slot)
            assert_eq(none, null)
            assert_eq(row.get_child_count(), n, "%s: exactly %d cell(s), no hole" % [e.slot, n])
            for cell in row.get_children():
                assert_eq(cell.get_child_count(), 1, "%s: every cell carries an icon" % e.slot)
        if n == 1:
            seen_one = true
    assert_true(seen_one, "sanity: some Tier-1 notice drops exactly one thing")


# ---------------------------------------------------------------- LOOP-08 / UI-17

func test_the_verdict_callout_is_one_word_and_one_signed_number() -> void:
    var st = _fixture_state()
    var view = _mount()
    var callout = view._verdict_host.get_child(0)
    var col = callout.get_child(0)
    var headline = col.get_child(0)
    assert_true(headline is Label)
    assert_true(String(headline.text) in ["Ready", "Risky", "Reckless", "Suicidal"],
        "the headline is the verdict word alone: '%s'" % headline.text)
    var figure = PrepScript._figure_of(callout)
    assert_ne(figure, null)
    var first := String(figure.text).left(1)
    assert_true(first == "+" or first == "−", "signed: '%s'" % figure.text)
    assert_true(String(figure.text).ends_with(" mistakes"))
    var against = _find(callout, "Against")
    assert_ne(against, null)
    assert_true(String(against.text) in ["over a content guild", "under a content guild"])
    # The number is expected − baseline for exactly this party, as the
    # readout's own two lines print them.
    var chalked: Array = []
    for id in view.chalked_ids():
        chalked.append(st.raider(String(id)))
    var a: Dictionary = RaidPlan.analyse(chalked, _db, st.content.encounter(st.selected_encounter_id))
    assert_eq(String(figure.text), "%s mistakes" % RaidPlan.signed(
        float(a["expected_mistakes"]) - float(a["baseline_mistakes"])))
    assert_eq(String(headline.text), String(a["verdict"]))
    # The readout keeps its own "Verdict:" line, and the per-encounter figure.
    var printed := _joined(_find(view, "ReadoutCol"))
    assert_true(printed.contains("Verdict: %s" % a["verdict"]))
    assert_true(printed.contains("Expected mistakes  ~%.1f / encounter" % a["expected_mistakes"]))
    assert_true(printed.contains("Baseline at this comp"))
    # Bench everyone: a content guild's delta is +0.0, never "-0.0".
    for id in view.chalked_ids().duplicate():
        view._toggle(String(id))
    figure = PrepScript._figure_of(view._verdict_host.get_child(0))
    assert_eq(String(figure.text), "+0.0 mistakes")


func test_the_risk_meter_is_drawn_and_captioned_not_typed() -> void:
    var st = _fixture_state()
    var view = _mount()
    var col = _find(view, "ReadoutCol")
    var row = _find(col, "RiskRow")
    assert_ne(row, null, "the hatch row is in the readout")
    assert_eq(row.get_parent(), col)
    var hatch = _find(row, "RiskHatch")
    assert_ne(hatch, null, "a drawn Control (UI-17)")
    assert_true(hatch is Control and not (hatch is Label), "drawn, not typed")
    assert_eq(hatch.custom_minimum_size, PrepScript.HATCH_SIZE)
    assert_eq(hatch.mouse_filter, Control.MOUSE_FILTER_IGNORE)
    var word = _find(row, "RiskWord")
    assert_true(word is Label, "the band word stays a Label beside it")
    assert_true(String(word.text) in ["LOW", "ELEVATED", "SEVERE"])
    var chalked: Array = []
    for id in view.chalked_ids():
        chalked.append(st.raider(String(id)))
    var a: Dictionary = RaidPlan.analyse(chalked, _db, st.content.encounter(st.selected_encounter_id))
    assert_almost(float(hatch.fill), float(a["risk_fill"]), 0.0001, "the fill is RaidPlan's")
    assert_eq(String(word.text), String(a["risk_word"]))
    # The block's order: hatch row first, the per-encounter figure second.
    var idx: int = row.get_index()
    var second = col.get_child(idx + 1)
    assert_true(second is Label and String(second.text).begins_with("Expected mistakes"),
        "the per-encounter figure is the block's second line")
    # No typed hatch anywhere the player reads.
    for t in _texts(view):
        assert_false(String(t).contains("////"), "the typed hatch is gone from the screen: %s" % t)
        assert_false(String(t).contains("...."), "no dotted track either: %s" % t)
    # Still in RaidPlan for the log and the tests, and it agrees with the fill.
    assert_true(RaidPlan.risk_hatch(10.0, 5.0).contains("/"))
    assert_eq(RaidPlan.risk_hatch(float(a["expected_mistakes"]), float(a["baseline_mistakes"])),
        String(a["risk_hatch"]))


# ---------------------------------------------------------------- UI-18

func test_the_raid_team_row_says_how_many_more_and_turns_the_strip() -> void:
    _fixture_state()
    var view = _mount()
    var row = _find(view, "TeamRow")
    assert_ne(row, null)
    assert_eq(row.get_child_count(), PrepScript.TEAM_FACES + 1, "four faces and the +N tile")
    var tile = _find(row, "MoreTile")
    assert_ne(tile, null)
    assert_true(tile is Button, "a Button the walker reads")
    assert_eq(tile.text, "+8", "twelve chalked, four shown")
    assert_eq(tile.theme_type_variation, "ButtonMini")
    assert_eq(tile.focus_mode, Control.FOCUS_ALL)
    assert_eq(tile.custom_minimum_size, Vector2(Widgets.PORTRAIT_SLOT, Widgets.PORTRAIT_SLOT))
    var strip = _find(view, "RosterStrip")
    assert_eq(int(strip.get_meta("roster_page")), 0, "the strip opens on page 1")
    tile.pressed.emit()
    strip = _find(view, "RosterStrip")
    assert_eq(int(strip.get_meta("roster_page")), 1, "the tile turns the strip to the first unseen card")
    assert_eq(view._page, 1)
    # The fifth chalked raider is now a card on the strip.
    var fifth = view.chalked_ids()[PrepScript.TEAM_FACES]
    assert_true(_joined(strip).contains(String(_root().get_node("GameState").raider(String(fifth)).display_name)))
    # Bench down to four: no tile.
    for id in view.chalked_ids().slice(PrepScript.TEAM_FACES).duplicate():
        view._toggle(String(id))
    row = _find(view, "TeamRow")
    assert_eq(row.get_child_count(), PrepScript.TEAM_FACES)
    assert_eq(_find(row, "MoreTile"), null, "four chalked: nothing is unseen")
