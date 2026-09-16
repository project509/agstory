extends "res://tests/TestCase.gd"
## W1-KIT (build/plan/artaudit/00-plan.md §2): the composites the wave-2 screens
## consume, asserted through the same door the screen tests use — a walk that
## collects `Label.text` and `Button.text` — plus the node names and flags the
## keyboard instrument reads (`PagerPrev`/`PagerNext`, FOCUS_ALL, "Button").
##
## Nothing here is inside a tree (tests/run_tests.gd runs from `_initialize`),
## so grab_focus() and tweens are asserted as WIRING: the meta a composite
## leaves, the signal it connects, the null `Widgets.tween` returns outside a
## tree — the same convention tests/unit/test_a11y.gd documents.

const Widgets = preload("res://game/ui/Widgets.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Type = preload("res://game/ui/Type.gd")
const RaiderScript = preload("res://sim/model/Raider.gd")

var _made: Array = []


class StateStub:
    var roster: Array = []


func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []


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


func _find(n: Node, name: String) -> Node:
    if String(n.name) == name:
        return n
    for c in n.get_children():
        var hit := _find(c, name)
        if hit != null:
            return hit
    return null


func _button(n: Node, text: String) -> Button:
    if n is Button and (n as Button).text == text:
        return n as Button
    for c in n.get_children():
        var hit := _button(c, text)
        if hit != null:
            return hit
    return null


func _link(n: Node, text: String) -> LinkButton:
    if n is LinkButton and (n as LinkButton).text == text:
        return n as LinkButton
    for c in n.get_children():
        var hit := _link(c, text)
        if hit != null:
            return hit
    return null


func _raider(i: int) -> RefCounted:
    var r = RaiderScript.new()
    r.id = "r%02d" % i
    r.display_name = "R%02d" % i
    r.class_id = 0
    r.morale = 50
    return r


func _state(count: int) -> StateStub:
    var st := StateStub.new()
    for i in count:
        st.roster.append(_raider(i + 1))
    return st


# ------------------------------------------------------------------ stamps

func test_the_stamp_box_holds_the_word_as_its_direct_child() -> void:
    var box := Widgets.stamp_box("FALLEN", "danger")
    _made.append(box)
    assert_true(box is PanelContainer, "the box is the PanelStamp container")
    assert_eq(box.theme_type_variation, StringName("PanelStamp"))
    assert_true(box.get_child_count() >= 1, "the word is in the box")
    var word := box.get_child(0)
    assert_true(word is Label, "the Label is the box's DIRECT child (test_wipe_sequence reads its parent)")
    assert_eq((word as Label).text, "FALLEN")
    # 0.01° of slack: Control stores rotation in radians, so an exact 2.0° reads
    # back as 1.9999999° ("WIPE." and "1 OF 1" hash to exactly 2°).
    assert_true(absf(box.rotation_degrees) >= 1.99 and absf(box.rotation_degrees) <= 7.01,
        "docs/13 §7: rotated 2-7° (%f)" % box.rotation_degrees)
    assert_almost(box.modulate.a, 0.85, 0.001, "about 85% opacity")
    assert_eq(box.mouse_filter, Control.MOUSE_FILTER_IGNORE)
    assert_eq(Widgets.stamp_angle("FALLEN"), Widgets.stamp_angle("FALLEN"), "deterministic from the word")
    assert_eq(Widgets.tone_color("caution"), Palette.CAUTION)
    assert_eq(Widgets.tone_color("nonsense"), Palette.DANGER)


func test_the_label_stamp_keeps_its_contract_and_leans() -> void:
    # Four screens hold this as a Label; the treatment rides on the Label itself.
    var l := Widgets.stamp("WIPE.")
    _made.append(l)
    assert_true(l is Label)
    assert_eq(l.text, "WIPE.")
    assert_true(absf(l.rotation_degrees) >= 1.99 and absf(l.rotation_degrees) <= 7.01,
        "leans 2-7° (%f)" % l.rotation_degrees)
    assert_almost(l.modulate.a, 0.85, 0.001)


func test_a_caution_stamp_retints_a_copy_of_the_frame_never_the_theme() -> void:
    var th: Theme = Theme_.get_theme()
    assert_true(th.has_stylebox("panel", "PanelStamp"), "W1-CHROME registered the stamp frame")
    var shared: StyleBox = th.get_stylebox("panel", "PanelStamp")
    var red := Widgets.stamp_box("WIPE.", "danger")
    var amber := Widgets.stamp_box("MAY LEAVE", "caution")
    _made.append(red)
    _made.append(amber)
    assert_false(red.has_theme_stylebox_override("panel"), "danger is the theme's own frame")
    assert_true(amber.has_theme_stylebox_override("panel"), "caution wears a re-tinted copy")
    var copy: StyleBox = amber.get_theme_stylebox("panel")
    assert_ne(copy, shared, "a copy, not the shared resource")
    if shared is StyleBoxTexture:
        assert_eq((copy as StyleBoxTexture).modulate_color, Palette.CAUTION)
        assert_eq((shared as StyleBoxTexture).modulate_color, Palette.DANGER, "the theme's frame is untouched")
    assert_eq((amber.get_child(0) as Label).get_theme_color("font_color"), Palette.CAUTION)


# ------------------------------------------------------------ confirm pair

func test_confirm_pair_is_two_buttons_on_one_plate_with_the_safe_default() -> void:
    var plate := Widgets.confirm_pair("Yes — overwrite Slot 1", "Keep it", Callable(), Callable())
    _made.append(plate)
    var yes := _button(plate, "Yes — overwrite Slot 1")
    var no := _button(plate, "Keep it")
    assert_ne(yes, null, "the yes half is a Button with the exact text")
    assert_ne(no, null, "the no half is a Button with the exact text")
    assert_false(yes.disabled)
    assert_eq(no.focus_mode, Control.FOCUS_ALL)
    assert_eq(Widgets.default_focus_of(plate), no, "the safe choice is the default focus")
    assert_true(plate.tree_entered.get_connections().size() >= 1,
        "the grab is wired to tree entry (this harness has no tree to grab in)")
    assert_eq(Widgets.default_focus_of(Widgets.button("loose")), null)


# ---------------------------------------------------------------- reasoned

func test_reasoned_disables_dims_and_prints_the_reason_in_a_label() -> void:
    var box := Widgets.reasoned(Widgets.button("Delete"), "Nothing to delete.")
    _made.append(box)
    var b := Widgets.button_of(box)
    assert_ne(b, null, "button_of finds the control (named \"Button\")")
    assert_true(b.disabled)
    assert_almost(b.modulate.a, 0.55, 0.001, "dimmed to 0.55")
    assert_true(_joined(box).contains("Nothing to delete."), "the reason is a Label, never a tooltip")
    var why := _find(box, "Reason")
    assert_true(why is Label)
    assert_eq((why as Label).get_theme_color("font_color"), Palette.CAUTION)
    # docs/13 §14: the reason grows the row, it never wraps — a wrapping Label
    # has a zero minimum width and collapsed to one letter per line inside the
    # event log's shrinking head (W1-KIT shot 1).
    assert_eq((why as Label).autowrap_mode, TextServer.AUTOWRAP_OFF, "the reason line sizes its box")
    var fine := Widgets.reasoned(Widgets.button("Go"), "")
    _made.append(fine)
    assert_false(Widgets.button_of(fine).disabled, "an empty reason leaves it enabled")
    assert_almost(Widgets.button_of(fine).modulate.a, 1.0, 0.001)
    # W3-KIT2 (CRITIC-G06; handoff-W2-RAIDVIEW): the padlock is the default
    # glyph and it is worn ONLY while there is a reason.
    assert_ne(b.icon, null, "a shut control wears the padlock by default")
    assert_eq(b.icon.resource_path, Icons.path("lock", "16"), "W1-ICONS' lock_16 through Icons")
    assert_eq(Widgets.button_of(fine).icon, null, "an open control wears nothing")
    var handed := Widgets.reasoned(Widgets.button("Skip"), "", PlaceholderTexture2D.new())
    _made.append(handed)
    assert_eq(Widgets.button_of(handed).icon, null, "a glyph handed with no reason is not put on")
    var own := PlaceholderTexture2D.new()
    var custom := Widgets.reasoned(Widgets.button("Skip"), "Locked.", own)
    _made.append(custom)
    assert_eq(Widgets.button_of(custom).icon, own, "a caller's glyph wins over the default")
    # handoff-W2-TAVERN: `width` is the one door to a wrapping reason.
    var wide := Widgets.reasoned(Widgets.button("Hire"), "Unknown guilds cannot commission this.", null, 220)
    _made.append(wide)
    var wrapped := _find(wide, "Reason") as Label
    assert_eq(wrapped.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
    assert_almost(wrapped.custom_minimum_size.x, 220.0, 0.001)


# ------------------------------------------------------------ damage number

func test_damage_number_sets_its_value_once_and_is_pooled() -> void:
    var l := Widgets.damage_number(-317, "hit")
    assert_eq(l.text, "-317")
    assert_eq(String(l.name), "DamageNumber")
    assert_eq(l.theme_type_variation, StringName("LabelDamage"))
    assert_eq(Widgets.damage_number(42, "heal").text, "+42")
    assert_eq(Widgets.damage_number(842, "crit").theme_type_variation, StringName("LabelDamageCrit"))
    assert_eq(Widgets.damage_number(9, "heal").theme_type_variation, StringName("LabelHeal"))
    # Outside a tree nothing can animate: the rise returns null, the value is
    # untouched, and the label is handed back to the pool (hidden).
    var t := Widgets.number_rise(l)
    assert_eq(t, null)
    assert_eq(l.text, "-317", "the value never changes after the rise starts")
    assert_false(l.visible, "finished = hidden = back in the pool")
    var again := Widgets.damage_number(-5, "hit")
    assert_eq(again, l, "a finished label is reused, not a seventeenth allocated")
    assert_true(again.visible)
    assert_eq(again.text, "-5")
    var seen := {}
    for i in 40:
        seen[Widgets.damage_number(i + 1, "hit").get_instance_id()] = true
    assert_true(seen.size() <= 16, "pooled to 16 (%d distinct)" % seen.size())
    assert_almost(Widgets.number_stagger(3), 42.0, 0.001, "+14px per simultaneous number")


# -------------------------------------------------------------- roster strip

func test_roster_strip_pages_twelve_names_across_three_pages() -> void:
    var host := Control.new()
    _made.append(host)
    var st := _state(12)
    var pages := Cards.roster_strip(host, st, 0)
    assert_eq(pages, 3)
    var wrap := host.get_node_or_null("RosterStrip")
    assert_ne(wrap, null, "everything the strip draws lives under one child")
    var page0 := _joined(host)
    assert_true(page0.contains("R01") and page0.contains("R04"), page0)
    assert_false(page0.contains("R05"), "page 0 shows four cards")
    var next := _find(host, "PagerNext")
    var prev := _find(host, "PagerPrev")
    assert_true(next is Button and prev is Button, "the arrows are Buttons in the gutters")
    assert_eq((next as Button).focus_mode, Control.FOCUS_ALL)
    assert_true((next as Control).position.x > 1000.0 and (prev as Control).position.x < 127.0,
        "spec 10 §2 R1: one arrow per gutter")
    assert_true(_joined(host).contains("1/3"), "the caption says where the reader is")
    (next as Button).pressed.emit()
    var page1 := _joined(host)
    assert_true(page1.contains("R05") and page1.contains("R08") and not page1.contains("R04"), page1)
    assert_eq(Cards.strip_page(host), 1)
    (_find(host, "PagerNext") as Button).pressed.emit()
    var page2 := _joined(host)
    assert_true(page2.contains("R09") and page2.contains("R12") and not page2.contains("R08"), page2)
    assert_true(page2.contains("3/3"))
    (_find(host, "PagerNext") as Button).pressed.emit()
    assert_true(_joined(host).contains("R01"), "and wraps")
    assert_eq(Cards.strip_page(host), 0)
    (_find(host, "PagerPrev") as Button).pressed.emit()
    assert_eq(Cards.strip_page(host), 2, "prev wraps the other way")


func test_a_one_page_strip_draws_no_pager() -> void:
    var host := Control.new()
    _made.append(host)
    assert_eq(Cards.roster_strip(host, _state(4), 0), 1)
    assert_eq(_find(host, "PagerNext"), null)
    assert_eq(_find(host, "PagerPrev"), null)


func test_the_strip_tells_a_screen_that_keeps_its_own_page() -> void:
    var host := Control.new()
    _made.append(host)
    var seen: Array = []
    Cards.roster_strip(host, _state(9), 0, {"on_page": func(p: int) -> void: seen.append(p)})
    (_find(host, "PagerNext") as Button).pressed.emit()
    assert_eq(seen, [1])


# ------------------------------------------------------------------ callout

func test_building_callout_keeps_button_of_and_grows_an_icon_column_and_a_tail() -> void:
    var c := Widgets.building_callout("Tavern", "Recruit")
    _made.append(c)
    assert_eq(String(c.name), "Callout")
    var b := Widgets.button_of(c)
    assert_ne(b, null)
    assert_eq(b.text, "Tavern", "the title stays the Button the tests press")
    assert_eq(String(b.name), "Button")
    assert_false(b.disabled)
    assert_ne(_find(c, "Tail"), null, "a tail hangs from the plate")
    assert_ne(_find(c, "Icon"), null, "the 32px icon column exists before any icon is passed")
    assert_true(_joined(c).contains("Recruit"))
    assert_true(c.custom_minimum_size.x >= 60.0 + 16.0, "width = 60 + text + 16")

    var locked := Widgets.building_callout("Blacksmith", "Repair", "Canon lists this one as a maybe.")
    _made.append(locked)
    assert_true(Widgets.button_of(locked).disabled)
    assert_true(_joined(locked).contains("maybe"), "the reason is a Label inside the plate")
    assert_almost(Widgets.button_of(locked).modulate.a, 0.55, 0.001, "the reasoned dim")

    var iconed := Widgets.building_callout("Market", "Buy", "", PlaceholderTexture2D.new(), Vector2(300, 400))
    _made.append(iconed)
    assert_true(_find(iconed, "Icon") is TextureRect, "a passed glyph fills the column")
    assert_ne(_find(iconed, "Tail"), null)


func test_a_placed_callout_is_kept_inside_the_scene() -> void:
    # Town places the Blacksmith at scene x=900 of 929; a locked plate is 276
    # wide and ran under the sidebar (W1-KIT shot 1). With no anchor the plate
    # keeps the caller's placement but is clamped to the scene rect whenever its
    # rect changes — emitted by hand here, since nothing lays out outside a tree.
    var locked := Widgets.building_callout("Blacksmith", "Improve gear", "Canon lists this one as a maybe.")
    _made.append(locked)
    locked.position = Vector2(900, 292)
    locked.size = Vector2(276, 110)
    locked.item_rect_changed.emit()
    # W3-KIT2: the locked plate is as wide as its one-line reason asks (60 +
    # text + 16), no longer a fixed 200px reason column, so the clamp reads the
    # plate's own minimum — a Control never sits below it, and outside a tree
    # that minimum is measured on the default theme's wider face.
    var w: float = maxf(276.0, locked.get_combined_minimum_size().x)
    assert_almost(locked.position.x, float(Widgets.SCENE.size.x) - w, 0.001,
        "clamped to the scene's right edge (%f)" % locked.position.x)
    assert_almost(locked.position.y, 292.0, 0.001, "y untouched when it fits")
    var anchored := Widgets.building_callout("Market", "Buy / Sell", "", null, Vector2(920, 630))
    _made.append(anchored)
    anchored.size = Vector2(140, 60)
    anchored.item_rect_changed.emit()
    assert_true(anchored.position.x + 140.0 <= float(Widgets.SCENE.size.x), "an anchored plate is clamped too")
    assert_true(anchored.position.y + 60.0 + float(Widgets.TAIL_H) <= float(Widgets.SCENE.size.y),
        "and its tail stays inside the scene")


func test_the_callout_band_is_the_scene_rect_in_the_parents_space() -> void:
    # review-W1-KIT F7: the Town is full-bleed — its scene host sits at (0,0)
    # 1536x726 under the screen and Town.gd places the callouts in SCREEN
    # pixels — so the band the plates are kept inside is SCENE itself
    # (210,77)-(1139,717), not (0,0)-(929,640). The screen root is the node
    # carrying Frame's focus meta; a host above it (a letterboxing shot host)
    # is not counted.
    var shot_host := Control.new()
    _made.append(shot_host)
    shot_host.position = Vector2(64, 40)
    var screen := Control.new()
    screen.set_meta("frame_focus_order", func() -> Array: return [])
    shot_host.add_child(screen)
    var scene := Control.new()
    screen.add_child(scene)
    scene.position = Vector2.ZERO
    scene.size = Vector2(1536, 726)
    var right := Widgets.SCENE.position.x + Widgets.SCENE.size.x
    var bottom := Widgets.SCENE.position.y + Widgets.SCENE.size.y

    # Town's locked Blacksmith: 276 wide at screen x=900 — the right rim ran
    # under the sidebar (1142); the band puts it at 1139-276 = 863, y untouched.
    var smith := Widgets.building_callout("Blacksmith", "Improve gear", "Canon lists this one as a maybe.")
    scene.add_child(smith)
    smith.size = Vector2(276, 110)
    smith.position = Vector2(900, 292)
    smith.item_rect_changed.emit()
    var smith_w: float = maxf(276.0, smith.get_combined_minimum_size().x)   # W3-KIT2: sized by its one-line reason
    assert_almost(smith.position.x, float(right) - smith_w, 0.001, "Blacksmith at %f" % smith.position.x)
    assert_almost(smith.position.y, 292.0, 0.001)
    # Town's Market (860,414) and Board (420,580; 80 tall) fit and do not move.
    var market := Widgets.building_callout("Market", "Buy / Sell")
    scene.add_child(market)
    market.size = Vector2(150, 60)
    market.position = Vector2(860, 414)
    market.item_rect_changed.emit()
    assert_eq(market.position, Vector2(860, 414), "a plate inside the band keeps its placement")
    var board := Widgets.building_callout("Adventure's Board", "Depart")
    scene.add_child(board)
    board.size = Vector2(230, 80)
    board.position = Vector2(420, 580)
    board.item_rect_changed.emit()
    assert_eq(board.position, Vector2(420, 580))
    # Under the rail or the header the plate is pushed onto the band.
    var low := Widgets.building_callout("Guildhall", "Maintain")
    scene.add_child(low)
    low.size = Vector2(200, 80)
    low.position = Vector2(100, 20)
    low.item_rect_changed.emit()
    assert_eq(low.position, Vector2(Widgets.SCENE.position), "kept off the rail and the header")
    # The anchored path: an anchor at the sidebar's edge lands the plate flush
    # with the band and the tail still aims at the anchor.
    var anchored := Widgets.building_callout("Market", "Buy / Sell", "", null, Vector2(1130, 700))
    scene.add_child(anchored)
    anchored.size = Vector2(150, 60)
    anchored.item_rect_changed.emit()
    assert_almost(anchored.position.x, float(right - 150), 0.001, "anchored plate at %f" % anchored.position.x)
    assert_almost(anchored.position.y, 700.0 - 60.0 - float(Widgets.TAIL_H), 0.001, "one tail above the anchor")
    assert_true(anchored.position.y + 60.0 + float(Widgets.TAIL_H) <= float(bottom), "inside the band's bottom")
    var tail := _find(anchored, "Tail")
    assert_true(tail is Node2D)
    var apex: Vector2 = tail.get("apex")
    assert_almost(apex.x, 1130.0 - anchored.position.x, 0.001, "the tail points at the anchor")

    # A framed scene host sits AT SCENE.position and is the band itself.
    var framed := Control.new()
    screen.add_child(framed)
    framed.position = Vector2(Widgets.SCENE.position)
    framed.size = Vector2(928, 640)
    var plate := Widgets.building_callout("Tavern", "Recruit")
    framed.add_child(plate)
    plate.size = Vector2(150, 60)
    plate.position = Vector2(900, 292)
    plate.item_rect_changed.emit()
    assert_almost(plate.position.x, 928.0 - 150.0, 0.001, "framed: clamped to the host's own right edge")

    # An explicit `bounds` (parent's space) wins over the derived band.
    var boxed := Widgets.building_callout("Tavern", "Recruit", "", null, Vector2.INF, Rect2(50, 50, 400, 300))
    scene.add_child(boxed)
    boxed.size = Vector2(150, 60)
    boxed.position = Vector2(900, 292)
    boxed.item_rect_changed.emit()
    assert_eq(boxed.position, Vector2(300, 282), "bounds: right 450-150, bottom 350-60-8")


# ------------------------------------------------------------------- speech

func test_speech_plate_grows_a_tail_only_when_anchored() -> void:
    var plain := Widgets.speech_plate("I think I'm ready.")
    _made.append(plain)
    assert_eq(_find(plain, "Tail"), null, "no anchor, no tail (W1-STAGE's one-arg call)")
    assert_true(Widgets.content_of(plain).get_child(0) is Label, "SceneStage reads the Pad's first child")
    assert_eq((Widgets.content_of(plain).get_child(0) as Label).text, "I think I'm ready.")
    assert_eq(plain.mouse_filter, Control.MOUSE_FILTER_IGNORE)
    var tailed := Widgets.speech_plate("Reloading… again…", Vector2(40, 120))
    _made.append(tailed)
    assert_ne(_find(tailed, "Tail"), null, "an anchor grows a node named Tail")


func test_speech_bubble_centres_a_glyph_or_draws_dots() -> void:
    var dots := Widgets.speech_bubble()
    _made.append(dots)
    assert_true(dots is TextureRect)
    assert_eq(String(dots.get_meta("emote")), "dots", "counted by meta: sibling names cannot all be Emote")
    assert_ne(_find(dots, "Dots"), null)
    assert_eq(_find(dots, "Glyph"), null)
    var mug := Widgets.speech_bubble("mug", PlaceholderTexture2D.new())
    _made.append(mug)
    assert_true(_find(mug, "Glyph") is TextureRect, "the emote glyph is a TextureRect")
    assert_eq(_find(mug, "Dots"), null)
    assert_eq(mug.mouse_filter, Control.MOUSE_FILTER_IGNORE)
    # The body is the theme's: PanelEmote's 12/10/12/18 margins on the 40x44
    # frame leave a 16x16 body at (12,10); the dots (15x3) sit centred in it,
    # on whole pixels, inside the frame's texture.
    var th: Theme = Theme_.get_theme()
    assert_true(th.has_stylebox("panel", "PanelEmote"), "W1-CHROME registered the emote frame")
    var sb: StyleBox = th.get_stylebox("panel", "PanelEmote")
    var frame: Vector2 = (dots as TextureRect).texture.get_size()
    var body := Rect2(sb.content_margin_left, sb.content_margin_top,
        frame.x - sb.content_margin_left - sb.content_margin_right,
        frame.y - sb.content_margin_top - sb.content_margin_bottom)
    var d := _find(dots, "Dots") as Node2D
    assert_eq(d.position, body.position + ((body.size - Vector2(15, 3)) * 0.5).floor())
    # W3-KIT2 (handoff-W2-STAGE2, option b): a glyph is the WHOLE marker — the
    # emote sprites are tailed bubbles of their own — drawn alone at 2x with
    # no frame texture behind it, inside the frame's unchanged 40x44 footprint
    # (test_scene_stage's head-gap rule reads that footprint), its tail apex on
    # the frame's apex: the 16px glyph's apex (3,14) lands on the frame's (5,43).
    assert_eq((mug as TextureRect).texture, null, "no frame under a framed glyph")
    assert_eq(mug.custom_minimum_size, frame, "the footprint is still the frame's")
    var g := _find(mug, "Glyph") as Control
    assert_eq(g.size, Vector2(32, 32), "2x")
    assert_eq(g.position, Widgets.emote_glyph_offset(frame))
    assert_eq(g.position, Vector2(0, 14), "apex (7,29) at 2x sits on (5..7, 43)")
    assert_eq((g as TextureRect).texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "pixel art")


# -------------------------------------------------------------------- pager

func test_pager_names_its_arrows_and_carries_a_caption() -> void:
    var p := Widgets.pager(0, 3, Callable(), Callable(), "Party of 12 · page 1/3")
    _made.append(p)
    assert_true(_find(p, "PagerPrev") is Button and _find(p, "PagerNext") is Button)
    assert_eq((_find(p, "PagerNext") as Button).focus_mode, Control.FOCUS_ALL)
    assert_true(_joined(p).contains("Party of 12 · page 1/3"))
    var bare := Widgets.pager(1, 2, Callable(), Callable())
    _made.append(bare)
    assert_true(_joined(bare).contains("2/2"), "n/m when no caption is given")
    var one := Widgets.pager(0, 1, Callable(), Callable())
    _made.append(one)
    assert_false((_find(one, "PagerNext") as Control).visible, "one page: nothing to press")


# ---------------------------------------------------------------------- tabs

func test_tab_row_keeps_every_text_and_prints_a_tab_reason_inside_the_row() -> void:
    var labels := ["Roster", "Raid Group", "Facilities", "Records"]
    var row := Widgets.tab_row(labels, 0, ["", "not in this version yet", "", ""])
    _made.append(row)
    var tabs := Widgets.tabs_of(row)
    assert_eq(tabs.size(), 4)
    for i in 4:
        assert_eq((tabs[i] as Button).text, labels[i], "texts unchanged")
        # W3-KIT2 (handoff-W2-MARKET): a tab's plate no longer hugs its word.
        assert_eq((tabs[i] as Button).custom_minimum_size, Widgets.TAB_MIN, "TAB_MIN on every tab")
    assert_eq((tabs[0] as Button).theme_type_variation, StringName("NavItemActive"))
    assert_eq((tabs[1] as Button).theme_type_variation, StringName("ButtonQuiet"))
    assert_true((tabs[1] as Button).disabled)
    assert_false((tabs[2] as Button).disabled)
    assert_true(_joined(row).contains("not in this version yet"), "the reason is a Label in the row")
    assert_eq(Widgets.tabs_of(Widgets.button("x")), [])


# ------------------------------------------------------- promoted (RULES-12)

func test_slot_with_reason_and_sparkline_are_promoted() -> void:
    var box := Widgets.slot_with_reason("Minor — 8 G", "Reach Known.", Vector2(90, 47))
    _made.append(box)
    var b := Widgets.button_of(box)
    assert_ne(b, null)
    assert_eq(b.text, "Minor — 8 G")
    assert_true(b.disabled)
    assert_true(_joined(box).contains("Reach Known."))
    var free := Widgets.slot_with_reason("Minor — 8 G", "", Vector2(90, 47))
    _made.append(free)
    assert_false(Widgets.button_of(free).disabled)
    var spark := Widgets.sparkline([10, 50, 90])
    _made.append(spark)
    assert_eq(String(spark.name), "Sparkline")
    assert_eq(spark.custom_minimum_size, Vector2(36, 40), "12px pitch, 40 tall — RaiderDetail's numbers")
    assert_eq((spark.get("values") as Array).size(), 3)
    assert_eq(spark.mouse_filter, Control.MOUSE_FILTER_IGNORE)


# ------------------------------------------------------------------- motion

func test_the_motion_table_is_g08s_numbers() -> void:
    assert_eq(Widgets.Motion.STAMP_PRESS, 120)
    assert_eq(Widgets.Motion.STAMP_PRESS_FLOOR, 60)
    assert_eq(Widgets.Motion.LOG_SETTLE, 90)
    assert_eq(Widgets.Motion.NUMBER, 600)
    assert_eq(Widgets.Motion.RISE_PX, 18)
    assert_eq(Widgets.Motion.BUBBLE, 2400)
    assert_eq(Widgets.Motion.HIT, 90)
    assert_eq(Widgets.Motion.BURST, 350)
    var box := Widgets.stamp_box("MISTAKE")
    _made.append(box)
    assert_eq(Widgets.stamp_press(box), null, "outside a tree the press arrives instantly")
    assert_eq(box.scale, Vector2.ONE)


# -------------------------------------------------------------------- cards

func test_card_actions_sit_inside_the_card_with_their_reason() -> void:
    var pressed: Array = []
    var card := Cards.card(_raider(1), null, {}, [
        {"text": "Cheer up", "reason": "They are fine."},
        {"text": "Manage", "on": func() -> void: pressed.append("manage")},
    ])
    _made.append(card)
    var band := _find(card, "Actions")
    assert_ne(band, null, "the band is inside the card")
    var cheer := _button(card, "Cheer up")
    var manage := _button(card, "Manage")
    assert_ne(cheer, null)
    assert_ne(manage, null)
    assert_true(cheer.disabled)
    assert_true(_joined(card).contains("They are fine."), "the reason stays a Label under its button")
    assert_eq(Widgets.button_of(band as Control), cheer, "button_of finds the first action's Button")
    manage.pressed.emit()
    assert_eq(pressed, ["manage"])


func test_the_card_quote_falls_back_to_the_first_backstory_bullet() -> void:
    var r = _raider(2)
    r.backstory = [{"text": "Once fell down a well and stayed."}]
    var card := Cards.card(r, null)
    _made.append(card)
    assert_true(_joined(card).contains("Once fell down a well and stayed."), "TOWN-29: real text from day one")
    r.morale_log = [{"day": 3, "morale": 40, "note": "wipe"}]
    var noted := Cards.card(r, null)
    _made.append(noted)
    assert_true(_joined(noted).contains("wipe") and not _joined(noted).contains("Once fell"),
        "the newest morale note still wins")
    var benched := Cards.card(_raider(3), null, {"text": "Bench"})
    _made.append(benched)
    var r3 = _raider(4)
    r3.backstory = [{"text": "A bullet."}]
    var with_action := Cards.card(r3, null, {"text": "Bench"})
    _made.append(with_action)
    assert_false(_joined(with_action).contains("A bullet."), "no room for both a bullet and an action in 262")
    assert_true(_joined(benched).contains("Bench"))


# ------------------------------------------------------------- empty state

func test_empty_state_is_still_a_label_and_carries_its_hint() -> void:
    var l := Widgets.empty_state("Nothing has happened yet.", null, "Raids and rests write here.")
    _made.append(l)
    assert_true(l is Label, "25 call sites hold a Label")
    assert_eq(l.text, "Nothing has happened yet.")
    assert_eq(l.size_flags_vertical, Control.SIZE_EXPAND_FILL, "KIT-08: fills and centres")
    assert_eq(l.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
    var hint := _find(l, "Hint")
    assert_true(hint is Label)
    assert_eq((hint as Label).text, "Raids and rests write here.")
    var glyphed := Widgets.empty_state("Nobody yet.", PlaceholderTexture2D.new())
    _made.append(glyphed)
    assert_true(_find(glyphed, "Glyph") is TextureRect)
    assert_eq(_find(glyphed, "Hint"), null)


# --------------------------------------------------------------- event log

func test_event_log_head_carries_the_reasoned_view_all_and_the_hint() -> void:
    var host := Control.new()
    _made.append(host)
    Cards.event_log(host, _state(0), 7, "Raids and rests write here.")
    var all := _joined(host)
    assert_true(all.contains("Recent Events"), all)
    assert_true(all.contains("Nothing has happened yet."), all)
    assert_true(all.contains("Raids and rests write here."), "the hint is a Label")
    # W3-KIT2 (KIT-21): the link routes to the Records tab at Known; a stub
    # state has no rank, so here it is shut with docs/03 §7's gate as reason.
    assert_true(all.contains("Opens at Known."), "the link's reason is a Label")
    var link := _link(host, "Records")
    assert_ne(link, null, "spec 03 §8's link exists")
    assert_true(link.disabled, "shut below Known")
    # review-W1-KIT F8: Theme.gd sets no LinkButton `font_disabled_color`, so
    # Godot's near-black default made the disabled word vanish under the 0.55
    # dim. A link's disabled ink is its own rest ink; the dim is the treatment.
    assert_true(link.has_theme_color_override("font_disabled_color"), "a disabled link keeps readable ink")
    var th: Theme = Theme_.get_theme()
    assert_true(th.has_color("font_color", "LinkButton"), "Theme.gd registers the link's rest ink")
    assert_eq(link.get_theme_color("font_disabled_color"), th.get_color("font_color", "LinkButton"),
        "the rest ink, dimmed by reasoned() — not a second grey")
    assert_almost(link.modulate.a, 0.55, 0.001)


func test_turning_a_page_rewires_the_screens_focus() -> void:
    # review-W1-KIT M2: the rebuilt arrows are new nodes, so the strip re-runs
    # the shell's focus wiring (the Callable Frame leaves on the screen root
    # under the key ScreenRouter mirrors) after every page turn.
    var screen := Control.new()
    _made.append(screen)
    var wired: Array = []
    screen.set_meta("frame_focus_order", func() -> Array:
        wired.append(true)
        return [])
    var strip := Control.new()
    screen.add_child(strip)
    Cards.roster_strip(strip, _state(12), 0)
    assert_eq(wired.size(), 0, "building the strip wires nothing — the router does that at entry")
    (_find(strip, "PagerNext") as Button).pressed.emit()
    assert_eq(wired.size(), 1, "one page turn, one re-wire")
    (_find(strip, "PagerPrev") as Button).pressed.emit()
    assert_eq(wired.size(), 2)
    var bare := Control.new()
    _made.append(bare)
    Cards.roster_strip(bare, _state(12), 0)
    (_find(bare, "PagerNext") as Button).pressed.emit()
    assert_eq(Cards.strip_page(bare), 1, "no shell: the turn still happens, nothing to re-wire")


# --------------------------------------------------------------------- cta

func test_cta_keeps_its_text_and_guards_a_long_label() -> void:
    var long := Widgets.cta("Back to town — the guild carries on")
    _made.append(long)
    assert_eq(long.text, "Back to town — the guild carries on", "test_screens presses this exact text")
    assert_eq(long.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
    assert_eq(long.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
    assert_almost(long.custom_minimum_size.x, float(Widgets.CTA_WRAP_W), 0.001,
        "a label wider than the cap wraps inside the plate instead of widening it")
    assert_almost(long.custom_minimum_size.y, float(Widgets.CTA_H), 0.001)
    var short := Widgets.cta("Depart", "2,400 G")
    _made.append(short)
    assert_eq(short.text, "Depart")
    assert_true(short.custom_minimum_size.x > 0.0 and short.custom_minimum_size.x < float(Widgets.CTA_WRAP_W),
        "a short CTA keeps exactly the width its text claimed (%f)" % short.custom_minimum_size.x)
    assert_ne(short.get_node_or_null("Cost"), null, "the subline is still the Cost Label")


# ------------------------------------------------------- W3-KIT2: second pass

func test_tooltip_for_lays_a_host_over_the_control_and_builds_two_lines() -> void:
    # KIT-22: the two-line tooltip; `tooltip_text` kept for a11y and the tests.
    var slot := Widgets.slot()
    _made.append(slot)
    var host = Widgets.tooltip_for(slot, "Cracked Charm of Power", "Trinket")
    assert_eq(slot.tooltip_text, "Cracked Charm of Power — Trinket", "the words stay in tooltip_text")
    assert_eq(host.get_parent(), slot, "the host is laid over the control")
    assert_eq(host.mouse_filter, Control.MOUSE_FILTER_PASS, "hover and click reach the control under it")
    assert_eq(host.focus_mode, Control.FOCUS_NONE, "never a Tab stop")
    var tip: Control = host.build_tooltip()
    _made.append(tip)
    var title := _find(tip, "Title") as Label
    var body := _find(tip, "Body") as Label
    assert_true(title != null and body != null, "a title over a body")
    assert_eq(title.text, "Cracked Charm of Power")
    assert_eq(body.text, "Trinket")
    assert_true(tip.custom_minimum_size.x <= float(Widgets.TOOLTIP_W), "06 §8: at most 260 wide")
    assert_eq(host._make_custom_tooltip("x").get_class(), "VBoxContainer", "Godot's hook answers the same box")
    var again = Widgets.tooltip_for(slot, "Other", "")
    assert_eq(again, host, "calling it again replaces the lines, never stacks hosts")
    assert_eq(slot.tooltip_text, "Other")
    assert_eq(_find(again.build_tooltip(), "Body"), null, "no body, no second line")


func test_a_major_panel_carries_its_corner_ornaments_after_the_pad() -> void:
    # KIT-09: the ornament is the theme's icon slot, drawn by a Node2D so a
    # PanelContainer cannot re-lay it; the Pad stays child 0.
    var warm := Widgets.panel("PanelWarm", 16)
    _made.append(warm)
    assert_eq(String(warm.get_child(0).name), "Pad", "content_of() still finds the Pad first")
    var orn = _find(warm, "Ornaments")
    assert_true(orn is Node2D, "the ornaments are a Node2D, never a laid-out Control")
    assert_ne(orn.sprite, null, "W1-CHROME's corner_ornament icon")
    var th: Theme = Theme_.get_theme()
    assert_eq(orn.tint, th.get_color("ornament_tint", "PanelWarm"), "tinted by the theme")
    var steel := Widgets.panel("PanelSteel", 0)
    _made.append(steel)
    assert_ne(_find(steel, "Ornaments"), null, "PanelSteel too")
    var round := Widgets.panel("PanelRound", 14)
    _made.append(round)
    assert_eq(_find(round, "Ornaments"), null, "a soft panel has none — the theme gave it no icon")


func test_the_callout_keeps_its_column_first_and_gains_the_sweep_and_flourish() -> void:
    var box := Widgets.callout("Estimated Success Chance", "17%", 17)
    _made.append(box)
    assert_true(box.get_child(0) is VBoxContainer, "AdventureBoard reads the column at index 0")
    assert_true(_joined(box).contains("17%"))
    var fl = _find(box, "Flourish")
    assert_true(fl is Node2D, "the flourish and the rim are a Node2D after the column")
    assert_eq(fl.tone, Palette.DANGER, "tinted by the band")
    assert_ne(fl.sprite, null, "W1-CHROME's flourish icon")
    assert_true(box.has_theme_stylebox_override("panel"), "the plate is the gradient sweep")
    var sweep := box.get_theme_stylebox("panel")
    assert_true(sweep is StyleBoxTexture and (sweep as StyleBoxTexture).texture is GradientTexture2D)
    var th: Theme = Theme_.get_theme()
    assert_eq(sweep.content_margin_left, th.get_stylebox("panel", "PanelCalloutDanger").content_margin_left,
        "the theme box's content margins are kept")
    var good := Widgets.callout("Chance", "80%", 80)
    _made.append(good)
    var fl2 = _find(good, "Flourish")
    assert_eq(fl2.tone, Palette.POSITIVE)


func test_the_card_puts_a_class_glyph_before_the_class_word_and_trims_the_band_line() -> void:
    # KIT-19: a 16px glyph in a row named ClassRow; the Label's text unchanged.
    var r = _raider(1)
    var c := Cards.card(r)
    _made.append(c)
    var row := _find(c, "ClassRow")
    assert_true(row is HBoxContainer)
    var g := _find(c, "ClassGlyph") as TextureRect
    assert_ne(g, null, "the glyph is a TextureRect before the word")
    assert_eq(g.texture.resource_path, Icons.path("class", "warrior"), "class 0 is the warrior")
    assert_eq(g.get_index(), 0)
    assert_true(_joined(c).contains("Warrior"), "the word is still a Label")
    assert_eq(Cards.class_glyph(null), null)
    # handoff-W2-RESULTS: the class/band line trims inside the 215px card at 150%.
    var trimmed := 0
    for l in _labels(c):
        if String(l.text).begins_with("Warrior — ") and l.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS:
            trimmed += 1
    assert_eq(trimmed, 1, "the class/band Label trims with an ellipsis")
    assert_eq(Cards.price_text(2400), "2,400 G", "KIT-15: prices through Type.gold")
    var priced := Widgets.cta_priced("Depart", 2400)
    _made.append(priced)
    assert_eq((priced.get_node("Cost") as Label).text, "2,400 G")


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append(n)
    for c in n.get_children():
        _labels(c, out)
    return out


func test_a_damage_number_sits_above_the_bubbles() -> void:
    # handoff-W2-RAIDVIEW: the kit sets the z-order once, for every caller.
    var l := Widgets.damage_number(-12, "hit")
    assert_eq(l.z_index, 1)


func test_a_locked_callout_is_two_rows_with_the_reason_on_the_second() -> void:
    # handoff-W2-TOWN: the verb gives its row to the reason (Subtitle hidden,
    # node kept for Town's own no-op), the reason one unwrapped line, pad 4/4.
    var locked := Widgets.building_callout("Blacksmith", "Repair", "Canon lists this one as a maybe.")
    _made.append(locked)
    var sub := _find(locked, "Subtitle") as Control
    assert_ne(sub, null, "the Subtitle node is kept")
    assert_false(sub.visible, "and hidden on a shut door")
    var why := _find(locked, "Reason") as Label
    assert_ne(why, null)
    assert_true(why.visible)
    assert_eq(why.autowrap_mode, TextServer.AUTOWRAP_OFF, "one line, the plate widens instead")
    var pad := _find(locked, "Pad") as MarginContainer
    assert_eq(pad.get_theme_constant("margin_top"), 4)
    assert_eq(pad.get_theme_constant("margin_bottom"), 4)
    var open := Widgets.building_callout("Tavern", "Recruit")
    _made.append(open)
    assert_true((_find(open, "Subtitle") as Control).visible, "an open door keeps its verb")


func test_the_tooltip_window_is_sized_off_a_laid_out_box() -> void:
    # UI-49 / CRITIC-R1 / handoff-W5-TOOLS §2: Godot sizes the tooltip Window
    # from get_contents_minimum_size() BEFORE any layout pass, and an autowrap
    # Label still 0 wide breaks every grapheme onto its own line — the first
    # two-line tooltip ever shot was a 180x571 plate. `build_tooltip()` now
    # pre-sizes its Labels; this reads the number the Window reads (probe:
    # 571 -> 56), through a PopupPanel given the box the way the engine does.
    var slot := Widgets.slot()
    _made.append(slot)
    var host = Widgets.tooltip_for(slot, "Cracked Charm of Power", "Trinket")
    var popup := PopupPanel.new()
    _made.append(popup)
    var tip: Control = host.build_tooltip()
    popup.add_child(tip)
    var contents: Vector2 = popup.get_contents_minimum_size()
    assert_true(contents.y < 80.0,
        "two lines must report a two-line minimum, got %s (571 was the bug)" % str(contents))
    assert_true(contents.x <= float(Widgets.TOOLTIP_W) + 32.0,
        "and at most the 06 §8 width plus the panel's margins, got %s" % str(contents))
