extends "res://tests/TestCase.gd"
## W1-FRAME: one header, one rail, one lockup, a wide-safe frame (00-plan §2).
##
## The shell is read the way the game reads it — `Frame.build()` on a sized
## host, `Frame.standard_chips()`, a Town mounted through the real router host —
## and the contracts RULES §1 pins are re-asserted alongside the new ones: the
## chip strings "60 G" / "Day 1" / "Unknown" stay in Labels, `Nav_*` names and
## `Button.text` are untouched, no chip becomes a focus stop.

const Frame = preload("res://game/ui/Frame.gd")
const Type = preload("res://game/ui/Type.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")

const TOWN := "res://game/screens/Town.tscn"
const RAID_PLATE_W := 352      ## RaidView.HEADER_W / Results.HEADER_RECT (COMBAT-12)

var _root: Node = null
var _made: Array = []
var _scale_was = null


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []
    _scale_was = null


func after_each() -> void:
    var gs = _root.get_node_or_null("GameSettings") if _root != null else null
    if gs != null and _scale_was != null:
        gs.set_value("text_scale", _scale_was)
    # LESSONS: the autoload outlives the file — put it back, content included.
    var st = _root.get_node_or_null("GameState") if _root != null else null
    if st != null and st.has_method("reset"):
        st.reset()
        st.content = null
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


# ---------------------------------------------------------------- helpers

func _ensure_autoloads() -> Node:
    if _root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        _root.add_child(s)
        _made.append(s)
    if _root.get_node_or_null("ScreenRouter") == null:
        var r = Router.new()
        r.name = "ScreenRouter"
        _root.add_child(r)
        _made.append(r)
    var gs = _root.get_node_or_null("GameSettings")
    if gs == null:
        gs = SettingsScript.new()
        gs.name = "GameSettings"
        _root.add_child(gs)
        _made.append(gs)
    if _scale_was == null:
        _scale_was = gs.get_value("text_scale")
    return gs


func _router_with_host():
    var host := Control.new()
    host.name = "FrameHeaderHost"
    _root.add_child(host)
    _made.append(host)
    var r = _root.get_node_or_null("ScreenRouter")
    r.register_host(host)
    return r


## A bare shell host at `size`, off the tree like test_a11y's — Frame.build()
## must work there (the probes do exactly this).
func _host(size: Vector2 = Vector2(1536, 1024)) -> Control:
    var h := Control.new()
    h.name = "ShellHost"
    h.size = size
    _made.append(h)
    return h


## A guild that is `active`, so the four chips print (a fresh GameState node,
## never the autoload — nothing here leaks into the next file).
func _guild():
    var st = GameStateScript.new()
    st.new_game("Frame Guild")
    _made.append(st)
    return st


func _find_named(n: Node, name: String) -> Node:
    if n.name == name:
        return n
    for c in n.get_children():
        var found := _find_named(c, name)
        if found != null:
            return found
    return null


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append(n)
    for c in n.get_children():
        _labels(c, out)
    return out


func _focus_stops(n: Node, out: Array = []) -> Array:
    if n is Control and (n as Control).focus_mode == Control.FOCUS_ALL:
        out.append(n)
    for c in n.get_children():
        _focus_stops(c, out)
    return out


func _texts(n: Node) -> Array:
    var out: Array = []
    for l in _labels(n):
        out.append((l as Label).text)
    return out


# ---------------------------------------------------------------- KIT-15: numerals

func test_type_num_and_gold_carry_the_thousands_separator() -> void:
    # The plan's two lines, verbatim.
    assert_eq(Type.gold(12480), "12,480 G")
    assert_eq(Type.gold(60), "60 G")
    assert_eq(Type.num(0), "0")
    assert_eq(Type.num(999), "999")
    assert_eq(Type.num(1000), "1,000")
    assert_eq(Type.num(1234567), "1,234,567")
    assert_eq(Type.num(-1500), "-1,500", "the sign stays outside the groups")
    assert_eq(Type.THOUSANDS_SEPARATOR, ",", "en-US until a string table exists")


# ---------------------------------------------------------------- KIT-23 / TOWN-30: the standing tip

func test_the_town_day_chip_carries_the_standing_tooltip() -> void:
    _ensure_autoloads()
    var st = _root.get_node_or_null("GameState")
    st.new_game("Tip Guild")
    var r = _router_with_host()
    assert_true(r.goto(TOWN), "the town must open")
    var screen: Control = r.current_screen()
    var day := _find_named(screen, "DayChip")
    assert_true(day != null, "Frame.standard_chips names the day chip")
    assert_true(String((day as Control).tooltip_text).contains("reputation"),
        "the chip's tooltip is the standing tip, got '%s'" % (day as Control).tooltip_text)
    # RULES §1: the asserted strings are still Labels in the chip row.
    var texts := _texts(screen)
    assert_has(texts, "60 G")
    var day_texts: Array = _texts(day)
    assert_eq(day_texts.size(), 1, "one Label in the day chip")
    assert_true(String(day_texts[0]).begins_with("Day 1"), "'Day 1' stays in the chip Label")
    assert_true(String(day_texts[0]).contains("Unknown"), "'Unknown' stays in the chip Label")


func test_standing_tip_counts_down_to_the_next_rank() -> void:
    var st = _guild()
    var tip: String = Frame.standing_tip(st)
    assert_true(tip.contains("reputation"), tip)
    assert_true(tip.contains("more to Known"), "a fresh guild counts down to Known: " + tip)
    assert_eq(Frame.standing_tip(null), "", "no guild, no tip")


# ---------------------------------------------------------------- KIT-03 / TOWN-05: one builder, a refresh path

func test_refresh_chips_rebuilds_the_same_four_chips_in_place() -> void:
    var st = _guild()
    var host := _host()
    var p = Frame.build(host, {"nav": Frame.nav_items(null), "active": "home"})
    Frame.standard_chips(p, st)
    assert_eq(p.chips.get_child_count(), 4, "gold, reputation, roster, day")
    assert_has(_texts(p.chips), "60 G")
    st.gold = 12480
    Frame.refresh_chips(p, st)
    assert_eq(p.chips.get_child_count(), 4, "rebuilt in place, not appended")
    assert_has(_texts(p.chips), "12,480 G", "the gold chip re-reads the state with the separator")
    var day := _find_named(p.chips, "DayChip")
    assert_true(day != null and String((day as Control).tooltip_text).contains("reputation"),
        "the refreshed day chip keeps its tooltip")
    # No guild: the one "No guild loaded." chip, through the same door.
    Frame.refresh_chips(p, null)
    assert_eq(p.chips.get_child_count(), 1)
    assert_has(_texts(p.chips), "No guild loaded.")


func test_the_chips_are_labels_and_not_focus_stops() -> void:
    # Judgement call (report-W1-FRAME): a chip does nothing when activated, so
    # it is not a Tab stop — Frame._focusable's own argument. The header region
    # therefore stays empty and Tab leaves the rail for the scene (test_a11y).
    var st = _guild()
    var host := _host()
    var p = Frame.build(host, {"nav": Frame.nav_items(null), "active": "home"})
    Frame.standard_chips(p, st)
    assert_eq(_focus_stops(p.chip_host).size(), 0, "no chip is FOCUS_ALL")
    var regions: Array = Frame.focus_order(p)
    for region in regions:
        for c in region:
            assert_false(p.chip_host.is_ancestor_of(c), "no chip in any focus region")


# ---------------------------------------------------------------- KIT-04 / TOWN-04 / CRITIC-C13: the rail label

func test_the_rail_label_sits_at_62_whole_and_clipped_at_the_rail_edge() -> void:
    var host := _host()
    var p = Frame.build(host, {"nav": Frame.nav_items(null), "active": "home"})
    var avail: int = Frame.RAIL_W - Frame.RAIL_LABEL_X
    assert_eq(Frame.RAIL_GLYPH_X, 16)
    assert_eq(Frame.RAIL_LABEL_X, 62)
    for item in Frame.NAV:
        var id := String(item["id"])
        var b: Button = p.nav_buttons[id]
        assert_eq(b.name, "Nav_" + id, "the rail's names are the a11y contract")
        assert_eq(b.text, String(item["label"]), "Button.text is what the tests press")
        var g := _find_named(b, "Glyph")
        if g != null:
            assert_eq((g as Control).position.x, float(Frame.RAIL_GLYPH_X), id + ": glyph column")
        var lbl := _find_named(b, "RailLabel") as Label
        assert_true(lbl != null, id + ": the drawn label")
        assert_eq(lbl.text, b.text, id + ": the drawn label prints the same string")
        assert_eq(lbl.position.x, float(Frame.RAIL_LABEL_X), id + ": label column")
        assert_eq(int(lbl.size.x), avail, id + ": the label ends at the rail edge")
        assert_true(lbl.clip_text, id + ": clip_text is the last guard")
        assert_eq(lbl.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
        var px: int = lbl.get_theme_font_size("font_size")
        assert_in_range(px, Frame.RAIL_LABEL_FLOOR, Type.NAV,
            id + ": between the floor and Type.NAV at scale 100")
        # Measured with the theme's own LabelBody face — the door Frame uses —
        # because an off-tree Label reports the engine's fallback font.
        var font: Font = Frame._theme_font(host, "LabelBody")
        var w: float = font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
        if px > Frame.RAIL_LABEL_FLOOR:
            assert_true(w <= float(avail), "%s: '%s' at %dpx is %.0f wide, fits %d"
                % [id, lbl.text, px, w, avail])
    # The short labels keep the reference size; only the long one steps down.
    var camp := _find_named(p.nav_buttons["home"], "RailLabel") as Label
    assert_eq(camp.get_theme_font_size("font_size"), Type.NAV, "'Camp' is drawn at Type.NAV")
    var board := _find_named(p.nav_buttons["board"], "RailLabel") as Label
    assert_true(board.get_theme_font_size("font_size") < Type.NAV,
        "'Adventure's Board' does not fit 145px at 18 and steps down (TOWN-04)")
    assert_eq(Frame.RAIL_LABEL_FLOOR, Type.NAV - 2)


# ---------------------------------------------------------------- KIT-13 / TOWN-05 / Q05: one lockup

func test_every_framed_screen_draws_the_same_lockup() -> void:
    assert_eq(Frame.LOCKUP, "44_tagline", "Q05's recommended default")
    assert_true(Frame.LOCKUPS.has("58") and Frame.LOCKUPS.has("44_tagline")
        and Frame.LOCKUPS.has("33_compact"), "the three lockups the shell knows")
    var a := _host()
    var pa = Frame.build(a, {"nav": Frame.nav_items(null), "active": "home", "framed": false,
        "tagline": "Questionable people. Worse decisions."})
    var b := _host()
    var pb = Frame.build(b, {"nav": Frame.nav_items(null), "active": "roster", "framed": true})
    for host in [a, b]:
        assert_true(_find_named(host, "wordmark_44") != null, "the 44 mark on every screen")
        assert_true(_find_named(host, "wordmark_58") == null, "never the 58 beside it")
        assert_true(_find_named(host, "wordmark_tagline") != null, "the tagline on every screen")
        assert_true(_find_named(host, "TaglineRule") != null, "and its trailing rule")
        assert_true(_find_named(host, "Emblem") != null)
    var ma := _find_named(a, "wordmark_44") as Control
    var mb := _find_named(b, "wordmark_44") as Control
    assert_eq(ma.position, mb.position, "same place whether the screen passed a tagline or not")
    assert_eq((_find_named(a, "Emblem") as Control).position, Vector2(22, 15))
    # The mark's PNG is 271 wide (104 + 271 = 375: a 1px outline/shadow past
    # the glyph run); the block's edge is the rule's end, where 03 §6 aligns it,
    # unless the tagline is the wider element (the designer's copy is), in
    # which case the rule has nothing to fill, hides, and the block ends at
    # the tagline's right edge.
    assert_eq(Frame.TAGLINE_RULE_END, 374.0)
    var tag := _find_named(a, "wordmark_tagline") as TextureRect
    var tag_right: float = tag.position.x + tag.texture.get_width()
    var block_edge: float = maxf(Frame.TAGLINE_RULE_END, tag_right)
    assert_eq(pa.lockup_right, block_edge, "03 §6: the block right-aligns at the rule's end or the tagline's")
    assert_eq(pb.lockup_right, block_edge)
    var rule := _find_named(a, "TaglineRule") as Control
    if tag_right + 6.0 >= Frame.TAGLINE_RULE_END:
        assert_false(rule.visible, "a tagline past the rule's end leaves it nothing to draw")
    else:
        assert_eq(rule.position.x + rule.size.x, 374.0, "the rule ends at the block's edge")


func test_the_compact_lockup_ends_inside_the_raid_plate() -> void:
    # COMBAT-12: the asset and the table ship here; W2-RAIDVIEW/W2-RESULTS
    # consume them. 96 + width must clear the 352px plate by 8.
    assert_true(ResourceLoader.exists("res://game/assets/ui/wordmark_33.png"))
    assert_true(FileAccess.file_exists("res://game/assets/ui/wordmark_33.json"))
    assert_true(Frame.wordmark_baseline("wordmark_33") > 0, "the .json carries the baseline")
    var spec: Dictionary = Frame.LOCKUPS["33_compact"]
    assert_eq(spec["mark"], "wordmark_33")
    assert_eq(spec["mark_x"], 96)
    assert_eq(spec["baseline_y"], 48)
    var host := _host()
    var right: float = Frame.draw_lockup(host, "33_compact")
    assert_true(right <= float(RAID_PLATE_W - 8),
        "the compact mark ends at %.0f, inside %d" % [right, RAID_PLATE_W - 8])
    var mark := _find_named(host, "wordmark_33") as TextureRect
    assert_true(mark != null)
    assert_eq(mark.position.x, 96.0)
    assert_eq(mark.position.y, 48.0 - Frame.wordmark_baseline("wordmark_33"))
    var emblem := _find_named(host, "Emblem") as TextureRect
    assert_eq(emblem.position, Vector2(22, 12), "02 §4.1: the skull at (22, 12)")
    assert_true(emblem.texture is AtlasTexture, "the 65px crop, not the whole 82")
    assert_eq((emblem.texture as AtlasTexture).region.size, Vector2(65, 57))
    assert_true(_find_named(host, "wordmark_tagline") == null, "no tagline on the compact header")
    # The full lockups keep the whole emblem.
    var full := _host()
    Frame.draw_lockup(full, "44_tagline")
    assert_false((_find_named(full, "Emblem") as TextureRect).texture is AtlasTexture)


# ---------------------------------------------------------------- TOWN-08: the full-bleed camp's chrome fades

func test_the_full_bleed_camp_fades_its_rail_and_header() -> void:
    var host := _host()
    var p = Frame.build(host, {"nav": Frame.nav_items(null), "active": "home", "framed": false})
    assert_true(p.rail is TextureRect and p.rail.texture is GradientTexture2D,
        "the rail is a gradient scrim")
    var rg: Gradient = (p.rail.texture as GradientTexture2D).gradient
    assert_eq(rg.colors[0], Palette.GROUND_RAIL, "opaque GROUND_RAIL at the left edge")
    assert_almost(rg.colors[rg.colors.size() - 1].a, 0.0, 0.0001, "gone at the right edge")
    assert_eq(int(p.rail.size.x), Frame.RAIL_SCRIM_END, "the fade ends at x=200")
    assert_eq(Frame.RAIL_SCRIM_OPAQUE, 150)
    assert_true(p.rail_edge == null, "no hard border core on the camp")
    assert_true(p.header is TextureRect and p.header.texture is GradientTexture2D,
        "the header is a gradient plate behind the lockup")
    var hg: Gradient = (p.header.texture as GradientTexture2D).gradient
    assert_eq(hg.colors[0], Palette.GROUND_FRAME)
    assert_eq(p.header.size, Vector2(Frame.HEADER_SCRIM_END, Frame.HEADER_H))
    assert_eq(Frame.HEADER_SCRIM_OPAQUE, 414, "03 §9: opaque to 414, gone by 440")
    assert_true(p.divider is TextureRect, "the bronze rule fades with the plate")
    assert_true(p.sidebar_rule != null, "and reappears over the sidebar column")
    assert_eq(p.sidebar_rule.position, Vector2(1536 - Frame.SIDEBAR_W - Frame.GUTTER, Frame.DIVIDER_Y))
    assert_eq(int(p.sidebar_rule.size.x), Frame.SIDEBAR_W)
    # The sidebar meets the rule and the strip: no plate between them.
    assert_eq(p.sidebar_host.position.y, float(Frame.DIVIDER_Y + 2),
        "the panel starts on the row under the 2px rule — no plate line between them")
    assert_eq(p.sidebar_host.position.y + p.sidebar_host.size.y, float(Frame.STRIP_Y - 8))
    for n in [p.rail, p.header, p.divider, p.sidebar_rule]:
        assert_eq((n as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "overlays ignore the mouse")
    # The reading order is untouched: the scene host still precedes the rail.
    assert_true(p.scene.get_index() < p.rail.get_index(), "scene host before the chrome")


func test_the_framed_screens_keep_their_slabs() -> void:
    var host := _host()
    var p = Frame.build(host, {"nav": Frame.nav_items(null), "active": "roster", "framed": true})
    assert_true(p.rail is ColorRect and p.rail.color == Palette.GROUND_RAIL)
    assert_true(p.rail_edge != null and p.rail_edge is ColorRect)
    assert_true(p.header is ColorRect and p.header.color == Palette.GROUND_FRAME)
    assert_eq(p.header.size, Vector2(1536, Frame.HEADER_H))
    assert_true(p.sidebar_rule == null)
    assert_eq(p.sidebar_host.position.y, float(Frame.SIDEBAR_TOP))


# ---------------------------------------------------------------- CRITIC-G03: expand

func test_under_expand_the_sidebar_and_strip_follow_the_viewport_edge() -> void:
    var wide := _host(Vector2(1820, 1024))
    var p = Frame.build(wide, {"nav": Frame.nav_items(null), "active": "roster", "framed": true})
    assert_eq(p.sidebar_host.position.x + p.sidebar_host.size.x, 1820.0 - Frame.GUTTER,
        "the sidebar's right edge is the viewport's gutter")
    assert_eq(p.strip.position.x + p.strip.size.x, 1820.0 - 17.0, "and so is the strip's")
    assert_eq(p.chip_host.position.x + p.chip_host.size.x, 1820.0 - Frame.GUTTER - 1.0,
        "the chips stay right-aligned")
    assert_eq(p.header.size.x, 1820.0, "the header band spans the canvas")
    var g: ColorRect = p.expand_ground
    assert_true(g != null and g.get_parent() == p.scene and g.get_index() == 0,
        "the extra width sits under the screen's plate")
    assert_eq(g.color, Palette.GROUND_RAIL, "and it is GROUND_RAIL")
    assert_eq(g.size.x, 1820.0 - 1536.0, "exactly the width the canvas added")
    assert_eq(g.position.x + p.scene.position.x, 1536.0 - (Frame.SIDEBAR_W + Frame.GUTTER + 4),
        "starting where the reference's scene ended")
    assert_eq(g.size.y, p.scene.size.y)
    # At the reference size nothing moves: the ground is zero-width.
    var base := _host()
    var pb = Frame.build(base, {"nav": Frame.nav_items(null), "active": "roster", "framed": true})
    assert_eq(pb.expand_ground.size.x, 0.0, "zero-width at 1536")
    assert_eq(pb.sidebar_host.position.x, 1536.0 - Frame.SIDEBAR_W - Frame.GUTTER)


# ---------------------------------------------------------------- W0-TEXTSCALE: the chips and rail size through the door

func test_the_chips_and_rail_size_through_the_text_scale() -> void:
    var gs = _ensure_autoloads()
    gs.set_value("text_scale", 150)
    var st = _guild()
    var host := _host()
    var p = Frame.build(host, {"nav": Frame.nav_items(null), "active": "home"})
    Frame.standard_chips(p, st)
    assert_eq(int(p.chip_host.size.x), Type.at(Frame.CHIPS_W, 150), "the row's host grows with the scale")
    assert_eq(p.chip_host.position.x + p.chip_host.size.x, 1536.0 - Frame.GUTTER - 1.0,
        "and stays anchored at the gutter")
    assert_eq(p.chips.get_theme_constant("separation"), Frame.chip_gap(150))
    assert_eq(Frame.chip_gap(100), Frame.CHIP_GAP, "identity at 100")
    assert_true(Frame.chip_gap(150) < Frame.CHIP_GAP, "the gap gives back what the text takes")
    var camp := _find_named(p.nav_buttons["home"], "RailLabel") as Label
    assert_eq(camp.get_theme_font_size("font_size"), Type.at(Type.NAV, 150),
        "'Camp' is drawn at Type.NAV through the door")
    var board := _find_named(p.nav_buttons["board"], "RailLabel") as Label
    assert_in_range(board.get_theme_font_size("font_size"), Frame.RAIL_LABEL_FLOOR,
        Type.at(Type.NAV, 150), "the long label steps down but never below the floor")
    gs.set_value("text_scale", 100)
    var plain := _host()
    var pp = Frame.build(plain, {"nav": Frame.nav_items(null), "active": "home"})
    assert_eq(int(pp.chip_host.size.x), Frame.CHIPS_W, "identity at 100")
