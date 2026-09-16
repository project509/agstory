extends "res://tests/TestCase.gd"
## W2-TOWN — the hub's callouts sit beside their buildings, not on the camp's
## figures (TOWN-07, TOWN-01, TOWN-02), and the sidebar is the working panel
## spec 10 §3.1 asks for (TOWN-06, TOWN-31).
##
## The plates are measured the way the game lays them out: each callout is
## sized to its own minimum under the GAME's theme (which is what a
## PanelContainer in a plain Control settles at) and its `item_rect_changed` is
## emitted by hand, since nothing lays out between two synchronous test calls
## (test_widgets_kit.gd does the same). See `_fresh_min` for why the minimum
## is walked rather than read. The figures' body boxes come from the scene file
## and the actor manifest — the same two files SceneStage reads — at the
## scene's figure scale, carried into screen pixels by `Town.CAMP_OFFSET`.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const TownScript = preload("res://game/screens/Town.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Frame = preload("res://game/ui/Frame.gd")
const DB = preload("res://sim/content/ContentDB.gd")

const TOWN := "res://game/screens/Town.tscn"
const SCENE_JSON := "res://game/assets/scenes/stage_camp.json"
const ACTOR_MANIFEST := "res://game/assets/actors/actors.json"

## The air a plate keeps from the nearest head (TOWN-07: "the reference keeps
## 12-20px of air between a plate and the nearest head"). The contract is no
## intersection; the air is the bar this pass was placed to.
const AIR := 8.0

var _root: Node = null
var _made: Array = []
var _content_was = null
var _scale_was = null


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []
    _content_was = null
    _scale_was = null


func after_each() -> void:
    # The autoloads outlive this file (LESSONS): put the content and the text
    # scale back and reset the guild.
    var st = _root.get_node_or_null("GameState") if _root != null else null
    if st != null:
        st.reset()
        st.content = _content_was
    var gs = _root.get_node_or_null("GameSettings") if _root != null else null
    if gs != null and _scale_was != null:
        gs.set_value("text_scale", _scale_was)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


# ---------------------------------------------------------------- helpers

func _ensure_autoloads() -> void:
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


func _state():
    return _root.get_node_or_null("GameState")


## The Town mounted through the real autoload router, the way Boot mounts it.
func _mount_town(guild: String, with_content: bool) -> Control:
    _ensure_autoloads()
    # The plates are measured at text_scale 100 (the geometry Town.BUILDINGS
    # was placed at); a settings autoload left at another step by an earlier
    # file would move them.
    var gs = _root.get_node_or_null("GameSettings")
    if gs != null:
        _scale_was = gs.get_value("text_scale")
        gs.set_value("text_scale", 100)
    var st = _state()
    _content_was = st.content
    # Contentless means contentless: an earlier file that left content on the
    # autoload (LESSONS) would otherwise build a roster here and pin a mission.
    st.set_content(DB.load_all() if with_content else null)
    st.new_game(guild)
    var host := Control.new()
    host.name = "TownLayoutHost"
    host.size = Vector2(Widgets.SCREEN)
    _root.add_child(host)
    _made.append(host)
    var r = _root.get_node_or_null("ScreenRouter")
    r.register_host(host)
    assert_true(r.goto(TOWN), "the Town must mount")
    return r.current_screen()


func _find_all(n: Node, prefix: String, out: Array = []) -> Array:
    if String(n.name).begins_with(prefix):
        out.append(n)
    for c in n.get_children():
        _find_all(c, prefix, out)
    return out


func _find(n: Node, name: String) -> Node:
    if String(n.name) == name:
        return n
    for c in n.get_children():
        var f := _find(c, name)
        if f != null:
            return f
    return null


func _find_button(n: Node, text: String) -> Button:
    if n is Button and (n as Button).text == text:
        return n
    for c in n.get_children():
        var f := _find_button(c, text)
        if f != null:
            return f
    return null


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


## A control's rect in SCREEN pixels: its position summed up to the screen root
## (the node the router mounted), which is how Widgets._callout_bounds reads it.
func _screen_rect(c: Control, screen: Control) -> Rect2:
    var pos := Vector2.ZERO
    var n: Node = c
    while n is Control and n != screen:
        pos += (n as Control).position
        n = n.get_parent()
    return Rect2(pos, c.size)


## A control's minimum size as the game's theme lays it out.
##
## WHY NOT `get_combined_minimum_size()`: tests/run_tests.gd runs every test
## inside `_initialize`, before the root has a tree, so nothing here is
## `is_inside_tree()` and Godot never invalidates a Control's minimum-size
## cache off the tree. The kit fills that cache while it builds a plate — with
## no parent yet, under the DEFAULT theme — so the cached answer is the default
## theme's forever (the W2-TOWN probe: 150x58 cached for a plate the game
## settles at 166x84). The leaves' uncached `get_minimum_size()` is fresh once
## NOTIFICATION_THEME_CHANGED has refreshed their theme caches, so this walks
## the stock containers a plate is made of with their own arithmetic and reads
## the leaves. A container this does not model fails loudly.
func _fresh_min(c: Control) -> Vector2:
    var inner := Vector2.ZERO
    if c is BoxContainer:
        var vertical: bool = (c as BoxContainer).vertical
        var sep := float(c.get_theme_constant("separation"))
        var n := 0
        for ch in c.get_children():
            if ch is Control and (ch as Control).visible:
                var m := _fresh_min(ch)
                if vertical:
                    inner.x = maxf(inner.x, m.x)
                    inner.y += m.y
                else:
                    inner.y = maxf(inner.y, m.y)
                    inner.x += m.x
                n += 1
        if n > 1:
            if vertical:
                inner.y += sep * float(n - 1)
            else:
                inner.x += sep * float(n - 1)
    elif c is MarginContainer:
        for ch in c.get_children():
            if ch is Control and (ch as Control).visible:
                inner = inner.max(_fresh_min(ch))
        inner += Vector2(
            float(c.get_theme_constant("margin_left") + c.get_theme_constant("margin_right")),
            float(c.get_theme_constant("margin_top") + c.get_theme_constant("margin_bottom")))
    elif c is PanelContainer:
        for ch in c.get_children():
            if ch is Control and (ch as Control).visible:
                inner = inner.max(_fresh_min(ch))
        var sb := c.get_theme_stylebox("panel")
        if sb != null:
            inner += sb.get_minimum_size()
    elif c is Container:
        fail("_fresh_min does not model a %s (%s)" % [c.get_class(), c.name])
    else:
        inner = c.get_minimum_size()
    return inner.max(c.custom_minimum_size)


## Size each plate to its content and let the kit place it, as the first
## `item_rect_changed` after the theme lands would. The theme notification
## is what makes the leaves measure with the game's fonts and styleboxes
## (see `_fresh_min`); the subtitle's fresh line is checked against the
## theme's own LabelSmall metrics so a walk under the default theme (23px
## lines, not 17) cannot pass quietly.
func _settle_callouts(screen: Control) -> Array:
    screen.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)
    var th: Theme = screen.theme
    var small_line: float = th.get_font("font", "LabelSmall").get_height(
        th.get_font_size("font_size", "LabelSmall"))
    var plates := _find_all(screen, "Callout")
    for p in plates:
        var c := p as Control
        var sub := _find(c, "Subtitle") as Label
        if sub != null:
            assert_almost(sub.get_minimum_size().y, small_line, 0.5,
                "%s: the subtitle measures %f, the theme's LabelSmall line is %f"
                % [c.name, sub.get_minimum_size().y, small_line])
        var want := _fresh_min(c)
        assert_true(want.x >= c.custom_minimum_size.x and want.y >= 2.0 * small_line,
            "%s: the walk gives %s" % [c.name, want])
        c.size = want
        c.item_rect_changed.emit()
    return plates


func _read_json(path: String) -> Dictionary:
    var f := FileAccess.open(path, FileAccess.READ)
    assert_ne(f, null, "%s must open" % path)
    if f == null:
        return {}
    var parsed = JSON.parse_string(f.get_as_text())
    assert_true(parsed is Dictionary, "%s must be a JSON object" % path)
    return parsed if parsed is Dictionary else {}


## Every figure's body box on screen: the strip frame at the scene's figure
## scale (or the actor's own), centred on its feet and standing on them, then
## moved by the Town's framing of the plate. Keyed by actor name.
func _figure_boxes() -> Dictionary:
    var scene := _read_json(SCENE_JSON)
    var manifest: Dictionary = _read_json(ACTOR_MANIFEST).get("actors", {})
    var figure_scale := float(scene.get("figure_scale", 1.0))
    var out := {}
    var i := 0
    for a in scene.get("actors", []):
        var who := String(a.get("who", ""))
        var geom: Dictionary = manifest.get(who, {})
        assert_true(not geom.is_empty(), "actor %s must be in the manifest" % who)
        var sc := float(a.get("scale", figure_scale))
        var pos: Array = a.get("pos", [0, 0])
        var w := float(geom.get("frame_w", 0)) * sc
        var h := float(geom.get("frame_h", 0)) * sc
        var feet := Vector2(float(pos[0]), float(pos[1])) + TownScript.CAMP_OFFSET
        out["%s_%d" % [who, i]] = Rect2(feet.x - w * 0.5, feet.y - h, w, h)
        i += 1
    return out


# ---------------------------------------------------------------- callouts

func test_no_callout_sits_on_a_camp_figure() -> void:
    # TOWN-07 / handoff-W1-STAGE: at figure_scale 2 the wave-1 plates sat on
    # four bodies. The anchors in Town.BUILDINGS were measured against these
    # boxes; this is what keeps a later move of a figure or a plate honest.
    var screen := _mount_town("Layout Guild", false)
    var plates := _settle_callouts(screen)
    assert_eq(plates.size(), TownScript.BUILDINGS.size(), "one plate per building")
    var boxes := _figure_boxes()
    assert_true(boxes.size() >= 10, "the camp is a crowd: %d figures" % boxes.size())
    for p in plates:
        var rect := _screen_rect(p, screen)
        assert_true(rect.size.x > 60.0 and rect.size.y > 20.0,
            "%s must have laid out (%s)" % [p.name, rect])
        for who in boxes:
            var body: Rect2 = boxes[who]
            assert_false(rect.intersects(body),
                "%s %s sits on %s %s" % [p.name, rect, who, body])
            assert_false(rect.grow(AIR).intersects(body),
                "%s %s is within %dpx of %s %s" % [p.name, rect, int(AIR), who, body])


func test_every_callout_points_at_its_building_and_stays_in_the_scene_band() -> void:
    # TOWN-01: the tail's apex is the anchor, the plate hangs inside the scene
    # (no plate crosses x=1141 — the sidebar's edge) and carries its glyph.
    var screen := _mount_town("Anchor Guild", false)
    var plates := _settle_callouts(screen)
    var band := Rect2(Vector2(Widgets.SCENE.position), Vector2(Widgets.SCENE.size))
    for b in TownScript.BUILDINGS:
        var id := String(b["id"])
        var plate := _find(screen, "Callout_%s" % id) as Control
        assert_ne(plate, null, "a plate for %s" % id)
        if plate == null:
            continue
        assert_true(plates.has(plate))
        var rect := _screen_rect(plate, screen)
        assert_true(band.encloses(rect), "%s %s must stay inside the scene band %s" % [id, rect, band])
        assert_true(rect.end.x <= 1141.0, "%s must not cross the sidebar (%s)" % [id, rect])
        var tail := _find(plate, "Tail")
        assert_ne(tail, null, "%s hangs a tail" % id)
        if tail != null:
            var apex: Vector2 = tail.get("apex")
            var anchor: Vector2 = b["anchor"]
            assert_eq(rect.position + apex, anchor, "%s's tail lands on its anchor" % id)
            assert_true(band.has_point(anchor), "%s's anchor is on the visible camp" % id)
        var icon := _find(plate, "Icon")
        assert_true(icon is TextureRect and (icon as TextureRect).texture != null,
            "%s carries a glyph from the icon grid" % id)
        var btn := Widgets.button_of(plate)
        assert_ne(btn, null)
        assert_eq(btn.text, String(b["name"]), "the title Button keeps the canon name")
        assert_eq(btn.focus_mode, Control.FOCUS_ALL)


func test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason() -> void:
    # TOWN-02: one visual language for locked — the padlock, the dim, the reason
    # on the plate's second row (the verb gives up its line), so the shut plate
    # is exactly as tall as its neighbours.
    var screen := _mount_town("Locked Guild", false)
    _settle_callouts(screen)
    var smith := _find(screen, "Callout_blacksmith") as Control
    var hall := _find(screen, "Callout_guildhall") as Control
    assert_ne(smith, null)
    assert_ne(hall, null)
    if smith == null or hall == null:
        return
    assert_almost(smith.size.y, hall.size.y, 1.0,
        "locked plate %f tall vs %f" % [smith.size.y, hall.size.y])
    var btn := Widgets.button_of(smith)
    assert_true(btn.disabled, "the shut door is a disabled Button")
    assert_almost(btn.modulate.a, Widgets.REASONED_DIM, 0.001, "dimmed")
    var reason := _find(smith, "Reason") as Label
    assert_ne(reason, null, "the reason is a Label on the plate")
    if reason != null:
        # Q-13's copy (ship plan §6 #10) is the building's `blurb`, the one
        # source; only that and the one-line shape are asserted here.
        var blurb := ""
        for b in TownScript.BUILDINGS:
            if String(b["id"]) == "blacksmith":
                blurb = String(b["blurb"])
        assert_eq(reason.text, blurb, "the plate prints the blurb verbatim")
        assert_eq(reason.autowrap_mode, TextServer.AUTOWRAP_OFF, "one line (TOWN-02)")
        assert_true(reason.visible)
    var verb := _find(smith, "Subtitle") as Control
    if verb != null:
        assert_false(verb.visible, "the verb gives its row to the reason")


# ---------------------------------------------------------------- sidebar

func test_the_sidebar_is_the_next_mission_panel_with_one_crimson_control() -> void:
    # TOWN-06 / spec 10 §3.1: the pinned or first-open rung with its art, one
    # crimson CTA, the promise line and the Board's level line (both asserted
    # by test_screens) — and it fits the 378px panel (handoff-W1-FRAME).
    var screen := _mount_town("Panel Guild", true)
    var card := _find(screen, "NextMission") as Control
    assert_ne(card, null, "the next-mission card")
    if card != null:
        assert_ne(_find(card, "Art"), null, "with the encounter's art well")
        # docs/13 §4.4: the facts reflow to a second row, never trim to one
        # (review-W2-TOWN F4a: at 150 the line was ellipsised).
        var facts := _find(card, "Facts") as Label
        assert_ne(facts, null, "the facts line")
        if facts != null:
            assert_eq(facts.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
            assert_true(facts.max_lines_visible >= 2 or facts.max_lines_visible == -1,
                "the facts may take a second row (max_lines_visible %d)" % facts.max_lines_visible)
        # The caption tag is the small type, so it stays in the well's corner
        # off the centred thumbnail (review-W2-TOWN F4b).
        var tag := _find(card, "Caption") as Control
        assert_ne(tag, null, "the 'Next mission' tag")
        if tag != null and tag.get_child_count() > 0 and tag.get_child(0) is Label:
            assert_eq(String((tag.get_child(0) as Label).theme_type_variation), "LabelSmall")
    var ctas: Array = []
    for b in _find_all(screen, ""):
        if b is Button and String((b as Button).theme_type_variation).begins_with("ButtonCta"):
            ctas.append(b)
    assert_eq(ctas.size(), 1, "exactly one crimson control on the hub")
    if ctas.size() == 1:
        var cta := ctas[0] as Button
        var want := "Open the board" if TownScript.HUB_CTA == "board" else "Go to prep"
        assert_eq(cta.text, want)
        assert_false(cta.disabled, "with content loaded the door is open: %s" % cta.text)
        assert_eq(cta.focus_mode, Control.FOCUS_ALL)
    var printed := "\n".join(PackedStringArray(_texts(screen)))
    assert_true(printed.contains("Next at Known"), printed)
    assert_true(printed.contains("Level 1 of 3 — reputation raises this, not gold."), printed)
    assert_true(printed.contains("Today"))
    # UI-02 / LOOP-04: A0 is one enemy, and the facts line says so in English
    # ("1 enemy", never "1 enemies") through the one plural door, Type.count.
    assert_true(printed.contains("1 enemy  ·"), "A0's facts pluralise: %s" % printed)
    assert_false(printed.contains("1 enemies"), printed)
    var back := _find_button(screen, "Back to menu")
    assert_ne(back, null, "Back to menu stays a Button")
    if back != null:
        assert_eq(String(back.theme_type_variation), "ButtonQuiet", "demoted, not a link")
    var panel := _find(screen, "Sidebar") as Control
    assert_ne(panel, null)
    if panel != null:
        screen.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)
        var want := _fresh_min(panel)
        assert_true(want.x <= float(Frame.SIDEBAR_W),
            "the sidebar's content must not widen the panel past %d (wants %f)"
            % [Frame.SIDEBAR_W, want.x])
        assert_true(want.y <= panel.size.y,
            "the sidebar's rows must fit its %f (want %f) — Back to menu stays on the panel"
            % [panel.size.y, want.y])


func test_a_contentless_guild_still_gets_a_working_panel() -> void:
    # The screen tests mount the hub with no content (RULES §1): the card says
    # so in words, the CTA still opens the board, nothing crashes.
    var screen := _mount_town("Empty Guild", false)
    var printed := "\n".join(PackedStringArray(_texts(screen)))
    assert_true(printed.contains("Nothing pinned yet"), printed)
    var back := _find_button(screen, "Back to menu")
    assert_ne(back, null)
    var open := _find_button(screen, "Open the board" if TownScript.HUB_CTA == "board" else "Go to prep")
    assert_ne(open, null, "the hub's one commit is still a Button")


# ------------------------------------------------- the joke plate keeps out (UI-04)

## The camp's stage: `SceneStage.load` names its root `SceneStage_<scene>`.
func _camp_stage(screen: Control) -> Control:
    for n in screen.find_children("SceneStage_stage_camp", "", true, false):
        return n as Control
    return null


func test_the_camps_speech_plate_never_sits_on_a_callout() -> void:
    # UI-04: on every Town sheet the camp's joke plate sat under the
    # Guildhall's callout — two cream plates overlapping, the lower one
    # unreadable. `Town._scene` hands the five callouts to the stage as
    # keep-out rects and the stage lifts or slides its speech off them on
    # every tick; the plates are read LIVE, so the deferred settle that gives
    # each one its real size is picked up without the screen saying so again.
    var screen := _mount_town("Keep Out Guild", true)
    var plates := _settle_callouts(screen)
    assert_eq(plates.size(), TownScript.BUILDINGS.size(), "one plate per building")
    var stage := _camp_stage(screen)
    assert_ne(stage, null, "the camp stands on its stage")
    if stage == null:
        return
    # The per-frame path, by hand: `_tick_overlays` is what `_process` runs.
    stage._tick_overlays()
    var speech: PanelContainer = null
    for c in stage.get_children():
        if c is PanelContainer:
            speech = c
            break
    assert_ne(speech, null, "the camp has its one speaking plate")
    if speech == null:
        return
    assert_true(speech.visible, "and it is up: the roster's own backstory lines")
    var said := _screen_rect(speech, screen)
    assert_true(said.size.x > 60.0 and said.size.y > 20.0, "the plate laid out (%s)" % said)
    for p in plates:
        var callout := _screen_rect(p as Control, screen)
        assert_false(said.intersects(callout),
            "the joke plate %s sits on %s %s" % [said, p.name, callout])
