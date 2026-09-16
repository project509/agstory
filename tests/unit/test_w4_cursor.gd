extends "res://tests/TestCase.gd"
## W4-CURSOR — the pointer and the outline (PIPE-15).
##
## The kit's cursor pair exists at the size the OS shows it, the project names
## the arrow with its hotspot on the tip, the alpha-dilate outline shader is a
## file that parses and declares its uniforms, and a building callout carries
## an "Outline" ring behind its plate that lights on the title's focus or on
## hover and never on a shut door. The theme's `focus` StyleBox on the title
## Button is untouched — the EDGE_STEEL ring and the outline both show.
##
## The signals are emitted by hand: nothing hovers or focuses between two
## synchronous test calls, and the wiring is what is under test.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Theme_ = preload("res://game/ui/Theme.gd")

const ARROW := "res://game/assets/ui/cursor_arrow.png"
const HAND := "res://game/assets/ui/cursor_hand.png"
const SHADER := "res://game/ui/shaders/outline.gdshader"

var _made: Array = []


func before_each() -> void:
    _made = []


func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


func _find(n: Node, name: String) -> Node:
    if String(n.name) == name:
        return n
    for c in n.get_children():
        var hit := _find(c, name)
        if hit != null:
            return hit
    return null


# ------------------------------------------------------------------ cursors

func _cursor_image(path: String) -> Image:
    # Read the PNG bytes directly (the .ctex import is a boot-time artefact;
    # the source is what the generator wrote and what --check gates).
    var img := Image.new()
    var err := img.load(ProjectSettings.globalize_path(path))
    assert_eq(err, OK, "%s loads as an image" % path)
    return img


func test_the_two_cursors_are_32px_with_no_pure_black_or_white() -> void:
    for path in [ARROW, HAND]:
        assert_true(FileAccess.file_exists(path), "%s exists" % path)
        assert_true(FileAccess.file_exists(path + ".import"), "%s has its .import" % path)
        var img := _cursor_image(path)
        assert_eq(img.get_width(), 32, "%s width" % path)
        assert_eq(img.get_height(), 32, "%s height" % path)
        var opaque := 0
        var cream := 0
        var ink := 0
        for y in img.get_height():
            for x in img.get_width():
                var c := img.get_pixel(x, y)
                if c.a <= 0.0:
                    continue
                opaque += 1
                if c.a >= 0.999:
                    assert_false(c.r >= 0.999 and c.g >= 0.999 and c.b >= 0.999,
                        "%s has a pure white pixel at %d,%d" % [path, x, y])
                    assert_false(c.r <= 0.001 and c.g <= 0.001 and c.b <= 0.001,
                        "%s has a pure black pixel at %d,%d" % [path, x, y])
                if c.is_equal_approx(Color("F4EEDD")):
                    cream += 1
                if c.is_equal_approx(Color("2A1E18")):
                    ink += 1
        assert_true(opaque > 100, "%s is drawn (%d px)" % [path, opaque])
        assert_true(cream > 40, "%s is cream (%d px)" % [path, cream])
        assert_true(ink > 40, "%s has the warm-dark outline (%d px)" % [path, ink])


func test_the_project_names_the_arrow_with_its_hotspot_on_the_tip() -> void:
    var image := String(ProjectSettings.get_setting("display/mouse_cursor/custom_image", ""))
    assert_eq(image, ARROW, "display/mouse_cursor/custom_image")
    var hot: Vector2 = ProjectSettings.get_setting("display/mouse_cursor/custom_image_hotspot", Vector2(-1, -1))
    assert_eq(hot, Vector2(1, 1), "the hotspot is the arrow's tip")
    # The tip: the hotspot pixel is the outline's ink and nothing is drawn
    # above or left of it (a hotspot off the drawn shape points at air).
    var img := _cursor_image(ARROW)
    assert_true(img.get_pixel(int(hot.x), int(hot.y)).a > 0.9, "the hotspot pixel is drawn")
    for y in img.get_height():
        assert_eq(img.get_pixel(0, y).a, 0.0, "column 0 is air (row %d)" % y)
    for x in img.get_width():
        assert_eq(img.get_pixel(x, 0).a, 0.0, "row 0 is air (col %d)" % x)


func test_the_hand_has_its_fingertip_on_row_one() -> void:
    # The hand is registered at runtime (Input.CURSOR_POINTING_HAND, every
    # BaseButton's default shape) with its hotspot on the fingertip, (12,1):
    # the topmost drawn row is row 1 and column 12 is in it.
    var img := _cursor_image(HAND)
    var top := -1
    var cols: Array = []
    for y in img.get_height():
        for x in img.get_width():
            if img.get_pixel(x, y).a > 0.9:
                if top < 0:
                    top = y
                if y == top:
                    cols.append(x)
        if top >= 0:
            break
    assert_eq(top, 1, "the fingertip is on row 1")
    assert_has(cols, 12, "the fingertip covers column 12 (%s)" % str(cols))


# ------------------------------------------------------------------ shader

func test_the_outline_shader_is_a_file_that_parses_and_declares_its_uniforms() -> void:
    assert_true(FileAccess.file_exists(SHADER), "the shader file exists")
    var sh: Shader = load(SHADER)
    assert_ne(sh, null, "loads as a Shader")
    assert_eq(sh.get_mode(), Shader.MODE_CANVAS_ITEM, "a canvas_item shader")
    var names: Array = []
    for u in sh.get_shader_uniform_list():
        names.append(String(u["name"]))
    for want in ["color", "width", "fill", "threshold"]:
        assert_has(names, want, "uniform %s" % want)
    # The code, not its comments (the header says what it leaves out).
    var code := ""
    for line in FileAccess.get_file_as_string(SHADER).split("\n"):
        if not String(line).strip_edges().begins_with("//"):
            code += String(line) + "\n"
    assert_false(code.contains("TIME"), "static: no TIME in the outline shader")
    assert_false(code.contains("motion"), "static: no motion uniform to hold")
    assert_true(code.contains("TEXTURE_PIXEL_SIZE"), "the dilation is in texels")


# ------------------------------------------------------------------ the hook

func test_a_callout_carries_an_outline_behind_its_plate_hidden_at_rest() -> void:
    var c := Widgets.building_callout("Tavern", "Recruit")
    _made.append(c)
    var o := _find(c, "Outline")
    assert_ne(o, null, "an Outline node exists")
    assert_true(o is Node2D, "a Node2D, so the PanelContainer leaves it alone and it takes no click")
    assert_eq(o.get_parent(), c, "a child of the plate")
    assert_true((o as Node2D).show_behind_parent, "drawn behind the plate")
    assert_false((o as Node2D).visible, "hidden at rest")
    var mat := (o as Node2D).material as ShaderMaterial
    assert_ne(mat, null, "the outline shader is its material")
    assert_eq(mat.shader.resource_path, SHADER)
    assert_eq(mat.get_shader_parameter("color"), Palette.ACCENT_GOLD_LIGHT, "the ring is the light gold")
    assert_almost(float(mat.get_shader_parameter("fill")), 1.0, 0.001, "silhouette mode")
    assert_almost(float(mat.get_shader_parameter("width")), 0.0, 0.001,
        "a nine-patch copy grows by drawing larger, not by dilating its texels")
    assert_eq(o.get("tail"), _find(c, "Tail"), "it knows the tail so the ring wraps it")
    # Nothing the tests read moved: the title is still the Button named
    # "Button" and every other node keeps its name.
    var b := Widgets.button_of(c)
    assert_eq(b.text, "Tavern")
    assert_ne(_find(c, "Tail"), null)
    assert_ne(_find(c, "Icon"), null)
    assert_ne(_find(c, "Subtitle"), null)


func test_the_outline_lights_on_focus_and_on_hover_and_goes_out_again() -> void:
    var c := Widgets.building_callout("Tavern", "Recruit")
    _made.append(c)
    var o := _find(c, "Outline") as Node2D
    var b := Widgets.button_of(c)
    assert_false(o.visible)
    b.focus_entered.emit()
    assert_true(o.visible, "focus lights the ring")
    b.focus_exited.emit()
    assert_false(o.visible, "and it goes out when focus leaves")
    b.mouse_entered.emit()
    assert_true(o.visible, "the pointer over the title lights it")
    b.mouse_exited.emit()
    assert_false(o.visible)
    c.mouse_entered.emit()
    assert_true(o.visible, "the pointer over the plate lights it")
    # Moving from the plate onto the title: the Button's enter arrives while
    # the plate is still counted, and the plate's exit (if it fires) must not
    # put the ring out while the title is hovered.
    b.mouse_entered.emit()
    c.mouse_exited.emit()
    assert_true(o.visible, "still lit while the title is hovered")
    b.mouse_exited.emit()
    assert_false(o.visible, "out once nothing is hovered")
    # Focus and hover are independent: hover leaving does not unfocus.
    b.focus_entered.emit()
    b.mouse_entered.emit()
    b.mouse_exited.emit()
    assert_true(o.visible, "focus keeps the ring after the pointer leaves")
    b.focus_exited.emit()
    assert_false(o.visible)


func test_a_shut_door_never_lights() -> void:
    var locked := Widgets.building_callout("Blacksmith", "Improve gear", "Canon lists this one as a maybe.")
    _made.append(locked)
    var o := _find(locked, "Outline") as Node2D
    assert_ne(o, null, "the node is there (one tree shape for every plate)")
    var b := Widgets.button_of(locked)
    assert_true(b.disabled)
    b.focus_entered.emit()
    b.mouse_entered.emit()
    locked.mouse_entered.emit()
    assert_false(o.visible, "a locked plate is not an affordance")


func test_the_focus_ring_is_still_the_themes_and_no_tween_is_involved() -> void:
    # §0.5: the outline never replaces the `focus` StyleBox — both show.
    var c := Widgets.building_callout("Tavern", "Recruit")
    _made.append(c)
    var b := Widgets.button_of(c)
    assert_false(b.has_theme_stylebox_override("focus"), "no focus override on the title")
    var t: Theme = Theme_.build()
    var ring: StyleBoxFlat = t.get_stylebox("focus", "Button")
    assert_eq(ring.border_color, Palette.EDGE_STEEL, "the theme's 2px EDGE_STEEL ring is what the Button draws")
    assert_eq(ring.border_width_left, 2)
    # The hook is a state, not a motion (RULES §2's "hover = stylebox swap
    # only, no tween"): the Outline class has no tween call in its source.
    var src := FileAccess.get_file_as_string("res://game/ui/Widgets.gd")
    var start := src.find("class Outline extends Node2D:")
    var end := src.find("\nclass ", start + 1)
    assert_true(start > 0 and end > start, "the Outline class is in Widgets.gd")
    var body := src.substr(start, end - start)
    assert_false(body.contains("tween"), "no tween in the outline")
    assert_false(body.contains("reduced_motion"), "no branching on a setting")
