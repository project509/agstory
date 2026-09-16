extends "res://tests/TestCase.gd"
## docs/13 §13.1's keyboard map, the focus model it needs, and §12.3's focus ring.
##
## docs/13 §13 marks "Full keyboard navigation" **Blocking: Yes** — "a game that
## is 90% menus and cannot be driven from the keyboard cannot be driven on a Deck
## either". Before this file the project had zero InputMap actions, zero input
## handlers and nothing anywhere that set focus, so Tab order was accidental tree
## order and nothing was focused at all until the player clicked something.
##
## These tests mount real scenes and wire a real shell rather than testing the
## helpers in isolation, because the failures that matter are "nothing is
## focused when the screen opens" and "Tab falls out of the rail into nowhere",
## and neither is visible from a unit test of a pure function.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Palette = preload("res://game/ui/Palette.gd")

const TOWN := "res://game/screens/Town.tscn"
const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const BOARD := "res://game/screens/AdventureBoard.tscn"
const SETTINGS := "res://game/screens/Settings.tscn"

## docs/13 §13.1's five bindings Godot has no default for, and their keys.
const MAP := {
    "nav_toggle": KEY_SPACE,            # Space — chalk/unchalk, check/uncheck
    "nav_prev_subject": KEY_Q,          # Q — previous raider in a detail panel
    "nav_next_subject": KEY_E,          # E — next raider
    "nav_cycle_filter": KEY_F,          # F — cycle filters
    "nav_codex": KEY_F1,                # F1 — the codex (S16)
    "nav_sort_1": KEY_1,                # 1-4 — sort keys / S11 speed
    "nav_sort_2": KEY_2,
    "nav_sort_3": KEY_3,
    "nav_sort_4": KEY_4,
}

var _root: Node = null
var _made: Array = []


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []


func after_each() -> void:
    # The Tab-meaning switch is a static var, so a test that flips it has to put
    # it back or every later test in the run inherits the other reading of §13.1.
    Frame.tab_steps_within_region = false
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


func _ensure_autoloads() -> void:
    if _root == null:
        return
    if _root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        _root.add_child(s)
        _made.append(s)


func _host() -> Control:
    var h := Control.new()
    h.name = "A11yHost"
    _root.add_child(h)
    _made.append(h)
    return h


func _router() -> Node:
    var r = Router.new()
    r.name = "A11yRouter"
    _root.add_child(r)
    _made.append(r)
    r.register_host(_host())
    return r


# ------------------------------------------------------------ the InputMap

func _key_codes(action: String) -> Array:
    ## Every key an action is bound to, physical or not, as plain ints.
    var out: Array = []
    for ev in InputMap.action_get_events(action):
        if ev is InputEventKey:
            var k: InputEventKey = ev
            out.append(int(k.keycode) if int(k.keycode) != 0 else int(k.physical_keycode))
    return out


func _joy_buttons(action: String) -> Array:
    var out: Array = []
    for ev in InputMap.action_get_events(action):
        if ev is InputEventJoypadButton:
            out.append(int((ev as InputEventJoypadButton).button_index))
    return out


func test_every_action_docs13_names_exists() -> void:
    # The whole map was missing: `grep -n input project.godot` used to return
    # nothing at all, so none of these existed.
    for action in MAP:
        assert_true(InputMap.has_action(action), "no InputMap action '%s'" % action)


func test_every_action_is_bound_to_the_key_docs13_gives_it() -> void:
    for action in MAP:
        var want: int = MAP[action]
        assert_has(_key_codes(action), want,
            "%s must be bound to key %d (docs/13 §13.1)" % [action, want])


func test_the_letter_and_digit_keys_are_physical() -> void:
    # docs/13 §13.1 names QWERTY positions. A physical code keeps Q/E/F/1-4
    # under the same fingers on AZERTY; a logical code scatters them.
    for action in ["nav_prev_subject", "nav_next_subject", "nav_cycle_filter",
            "nav_sort_1", "nav_sort_2", "nav_sort_3", "nav_sort_4"]:
        for ev in InputMap.action_get_events(action):
            if ev is InputEventKey:
                assert_eq(int((ev as InputEventKey).keycode), 0,
                    "%s should bind a PHYSICAL code, not a logical one" % action)


func test_the_builtin_half_of_the_map_is_still_intact() -> void:
    # Six of §13.1's eleven bindings are Godot defaults. `ui_accept` and
    # `ui_cancel` ARE now restated in project.godot, to add §13.2's `A` and `B`
    # joypad buttons which the engine does not ship (measured) — and redefining
    # an action REPLACES its event list, which is how a project silently loses
    # Enter on every Button. This is the tripwire for that edit.
    assert_has(_key_codes("ui_accept"), KEY_ENTER, "Enter — primary action")
    assert_has(_key_codes("ui_accept"), KEY_KP_ENTER, "the numpad's Enter too")
    assert_has(_key_codes("ui_cancel"), KEY_ESCAPE, "Esc — back one level")
    assert_has(_key_codes("ui_focus_next"), KEY_TAB, "Tab — next focus group")
    assert_has(_key_codes("ui_left"), KEY_LEFT, "arrows — move within the group")
    assert_has(_key_codes("ui_right"), KEY_RIGHT)
    assert_has(_key_codes("ui_up"), KEY_UP)
    assert_has(_key_codes("ui_down"), KEY_DOWN)
    var back_tab: bool = false
    for ev in InputMap.action_get_events("ui_focus_prev"):
        if ev is InputEventKey:
            var k: InputEventKey = ev
            if k.shift_pressed or int(k.keycode) == KEY_BACKTAB \
                    or int(k.physical_keycode) == KEY_BACKTAB:
                back_tab = true
    assert_true(back_tab, "Shift+Tab — previous focus group")


func test_space_and_enter_stay_two_different_bindings() -> void:
    # §13.1 lists Enter as "primary action on the focused item" and Space as
    # "Toggle", i.e. two rows, not one. Enter must therefore NOT be a toggle.
    assert_false(_key_codes("nav_toggle").has(KEY_ENTER),
        "Enter is the primary action, not the toggle")
    assert_has(_key_codes("nav_toggle"), KEY_SPACE)
    # Pinned deliberately: Godot's built-in `ui_accept` ALSO carries Space, so a
    # focused Button consumes Space in `_gui_input` before any screen's
    # `_unhandled_input` sees `nav_toggle`. That overlap is a real ordering trap
    # and the proposed docs/15 entry in build/plan/q-a11y-keys.md asks for a
    # ruling; if the ruling removes Space from ui_accept this assertion fails,
    # which is exactly when someone should re-read that entry.
    assert_has(_key_codes("ui_accept"), KEY_SPACE,
        "Godot still gives ui_accept Space — see build/plan/q-a11y-keys.md")


func test_the_gamepad_equivalents_docs132_names_are_bound() -> void:
    # docs/13 §13.2's table, for every row it maps onto a plain button:
    # X = toggle, Y = cycle filters, View/Back = codex, Start = Settings.
    assert_has(_joy_buttons("nav_toggle"), JOY_BUTTON_X)
    assert_has(_joy_buttons("nav_cycle_filter"), JOY_BUTTON_Y)
    assert_has(_joy_buttons("nav_codex"), JOY_BUTTON_BACK)
    assert_has(_joy_buttons("nav_settings"), JOY_BUTTON_START,
        "§13.2's `Start` row — Settings (S15)")


func test_the_gamepads_a_and_b_are_bound_because_the_engine_does_not_bind_them() -> void:
    # An earlier version of this file asserted the opposite in a COMMENT —
    # "A/B/D-pad are already Godot defaults" — and never checked it. Measured on
    # 4.7.1: `ui_up` ships `joy btn=11` and an axis event, but `ui_accept` and
    # `ui_cancel` shipped NO joypad event at all, so §13.2's two most important
    # rows (`A` primary, `B` back) were dead and a controller could neither
    # confirm nor cancel. project.godot now restates both actions with the
    # engine's own keyboard events plus the button.
    assert_has(_joy_buttons("ui_accept"), JOY_BUTTON_A, "§13.2 `A` — primary action")
    assert_has(_joy_buttons("ui_cancel"), JOY_BUTTON_B, "§13.2 `B` — back one level")
    # The D-pad half really is an engine default; this is the contrast that
    # makes the two assertions above worth having.
    assert_has(_joy_buttons("ui_down"), JOY_BUTTON_DPAD_DOWN)


func test_a_real_key_event_fires_the_action() -> void:
    # The bindings above are read out of the map; this proves the map matches an
    # event, which is what a screen's `_unhandled_input` actually does.
    var ev := InputEventKey.new()
    ev.physical_keycode = KEY_F
    ev.keycode = KEY_F
    ev.pressed = true
    assert_true(ev.is_action_pressed("nav_cycle_filter"))
    assert_false(ev.is_action_pressed("nav_toggle"))


# ------------------------------------------------------------ the focus ring

func _button_family(t: Theme) -> Array:
    ## Every theme type that is a Button, a Button variation, or a LinkButton —
    ## docs/13 §12.3 says "identical shape on every widget", so the test has to
    ## enumerate the widgets rather than trust a hand-written list.
    var out: Array = []
    for type_name in t.get_type_list():
        var walk: String = type_name
        var guard: int = 0
        while walk != "" and guard < 8:
            if walk == "Button" or walk == "LinkButton":
                out.append(type_name)
                break
            walk = t.get_type_variation_base(walk)
            guard += 1
    return out


func test_every_button_variation_has_a_focus_ring_outside_its_bounds() -> void:
    # This is the bug: the ring was `flat(transparent, EDGE_STEEL, 1, 3)` with no
    # expand margin, so it drew 1px INSIDE the control. docs/13 §12.3 wants "2px
    # ... drawn *outside* the bounds so it never shifts layout".
    var t: Theme = Theme_.build()
    var family: Array = _button_family(t)
    assert_true(family.size() >= 9,
        "expected the kit's button variations, found %d" % family.size())
    for type_name in family:
        assert_true(t.has_stylebox("focus", type_name),
            "%s has no focus ring at all" % type_name)
        var sb = t.get_stylebox("focus", type_name)
        assert_true(sb is StyleBoxFlat, "%s focus ring is not a StyleBoxFlat" % type_name)
        var f: StyleBoxFlat = sb
        assert_eq(f.border_width_left, 2, "%s ring width" % type_name)
        assert_eq(f.border_width_top, 2, "%s ring width" % type_name)
        assert_eq(f.border_width_right, 2, "%s ring width" % type_name)
        assert_eq(f.border_width_bottom, 2, "%s ring width" % type_name)
        assert_true(f.expand_margin_left >= 2.0,
            "%s ring is not outside the bounds" % type_name)
        assert_true(f.expand_margin_top >= 2.0,
            "%s ring is not outside the bounds" % type_name)
        assert_true(f.expand_margin_right >= 2.0,
            "%s ring is not outside the bounds" % type_name)
        assert_true(f.expand_margin_bottom >= 2.0,
            "%s ring is not outside the bounds" % type_name)
        assert_eq(f.border_color, Palette.EDGE_STEEL, "%s ring colour" % type_name)
        assert_almost(f.bg_color.a, 0.0, 0.001,
            "%s ring must not fill the control" % type_name)


func test_the_link_button_is_in_that_family() -> void:
    # It was the one focusable widget the theme skipped entirely: LinkButton
    # never passes through `_button()`, so a focused link showed nothing.
    var t: Theme = Theme_.build()
    assert_has(_button_family(t), "LinkButton")
    assert_true(t.has_color("font_focus_color", "LinkButton"))


func test_the_focus_ring_is_the_same_shape_on_every_widget() -> void:
    # §12.3: "Identical shape on every widget."
    var t: Theme = Theme_.build()
    var reference: StyleBoxFlat = t.get_stylebox("focus", "Button")
    for type_name in _button_family(t):
        var f: StyleBoxFlat = t.get_stylebox("focus", type_name)
        assert_eq(f.border_color, reference.border_color, type_name)
        assert_eq(f.corner_radius_top_left, reference.corner_radius_top_left, type_name)
        assert_eq(f.expand_margin_left, reference.expand_margin_left, type_name)


func test_a_focused_link_underlines_itself() -> void:
    # The underline is UNDERLINE_MODE_ON_HOVER and a keyboard never hovers, so
    # focus has to drive the same signal (docs/13 §13.2: no interaction — or
    # affordance — may exist only as a pointer gesture).
    #
    # The signals are emitted rather than provoked with grab_focus(): nothing in
    # this harness can hold focus at all (see the last test in this file), so
    # what is asserted is the handler, and Godot's own contract is that a
    # focused Control emits `focus_entered`.
    var l := Widgets.link("Read the ledger")
    _made.append(l)
    assert_eq(l.underline, LinkButton.UNDERLINE_MODE_ON_HOVER)
    # The precondition this test used to skip: a handler on a control the
    # keyboard can never focus is dead code, and emitting the signal by hand
    # hides that. See test_a_link_is_a_stop_the_engine_accepts.
    assert_eq(l.focus_mode, Control.FOCUS_ALL,
        "a link that cannot take focus can never run the handler below")
    assert_true(l.focus_entered.get_connections().size() >= 1,
        "a link with no focus handler shows nothing to a keyboard")
    l.focus_entered.emit()
    assert_eq(l.underline, LinkButton.UNDERLINE_MODE_ALWAYS,
        "a focused link must show something")
    l.focus_exited.emit()
    assert_eq(l.underline, LinkButton.UNDERLINE_MODE_ON_HOVER,
        "and stop showing it when focus leaves")


func test_a_link_is_a_stop_the_engine_accepts() -> void:
    # The defect this pins: `LinkButton.new().focus_mode` is
    # `FOCUS_ACCESSIBILITY` (3) in Godot 4.7.1, NOT `FOCUS_ALL` (2) as on
    # Button. Godot's Tab walk stops only on FOCUS_ALL, so before
    # `Widgets.link()` set this explicitly every link in the game was
    # pointer-only, the focus ring and underline handler above were unreachable,
    # and the Adventure's Board's "Back to town" was measurably absent from the
    # Tab chain — a live breach of §13.2's "no interaction may exist only as a
    # pointer gesture".
    var raw := LinkButton.new()
    _made.append(raw)
    assert_eq(raw.focus_mode, Control.FOCUS_ACCESSIBILITY,
        "if the engine default changes, the comment above needs rewriting")
    for l in [Widgets.link("Back to town"), Widgets.link("Always", true)]:
        _made.append(l)
        assert_eq((l as Control).focus_mode, Control.FOCUS_ALL,
            "every link, underlined or not, must be a keyboard stop")


func test_a_control_the_engine_would_refuse_is_not_treated_as_a_tab_stop() -> void:
    # Both predicates used to reject only FOCUS_NONE, so a FOCUS_CLICK or
    # FOCUS_ACCESSIBILITY control counted as focusable: `focus_order()` wired a
    # region ring through it (Godot then ignores that NodePath and falls back to
    # tree order, silently breaking the ring) and `initial_focus_target()`
    # handed it to `grab_focus()`, which the engine refuses — so the screen
    # opened with nothing focused and no test failed.
    for mode in [Control.FOCUS_CLICK, Control.FOCUS_ACCESSIBILITY]:
        var c := Button.new()
        c.text = "Pointer only"
        c.focus_mode = mode
        _made.append(c)
        assert_false(Frame._focusable(c),
            "Frame must not wire a focus_mode %d control into a ring" % mode)
        assert_eq(Router._can_focus(c), false,
            "the router must not hand a focus_mode %d control to grab_focus()" % mode)
    var ok := Button.new()
    ok.text = "Real"
    _made.append(ok)
    assert_true(Frame._focusable(ok))
    assert_true(Router._can_focus(ok))


func test_an_always_underlined_link_is_left_alone() -> void:
    var l := Widgets.link("Always", true)
    _made.append(l)
    assert_eq(l.focus_entered.get_connections().size(), 0,
        "nothing to toggle: it is already underlined")
    assert_eq(l.underline, LinkButton.UNDERLINE_MODE_ALWAYS)


# ------------------------------------------------------------ the focus order

## A shell with a nav rail, two chips, three scene controls and a commit button
## — the five regions docs/13 §13.1 orders.
func _shell() -> Dictionary:
    var host := _host()
    var r = _router()
    var p = Frame.build(host, {"nav": Frame.nav_items(r), "active": "home"})
    var chips := Frame.chips(p)
    var chip_a := Widgets.button("Chip A")
    var chip_b := Widgets.button("Chip B")
    chips.add_child(chip_a)
    chips.add_child(chip_b)
    var scene_controls: Array = []
    for i in 3:
        var b := Widgets.button("Row %d" % i)
        p.scene.add_child(b)
        scene_controls.append(b)
    var commit := Widgets.cta("Depart")
    p.strip.add_child(commit)
    return {"host": host, "parts": p, "chips": [chip_a, chip_b],
        "scene": scene_controls, "commit": commit}


func test_the_focus_order_is_reading_order_not_tree_order() -> void:
    # §13.1: "focus order always follows reading order: rail, then header, then
    # content, then commit." Frame.build() adds the scene host FIRST so panels
    # draw over it, so tree order says the opposite — this asserts both.
    var s: Dictionary = _shell()
    var p = s["parts"]
    var regions: Array = Frame.focus_order(p)
    assert_true(regions.size() >= 4, "expected the rail, header, scene and strip")
    var first: Control = regions[0][0]
    assert_eq(first, p.nav_buttons["home"], "the rail comes first (reading order)")
    assert_eq(regions[1][0], s["chips"][0], "then the header chips")
    assert_eq(regions[2][0], s["scene"][0], "then the content")
    assert_eq(regions[regions.size() - 1][0], s["commit"], "and the commit last")
    # The premise: tree order really does put the scene ahead of the rail, so
    # this ordering is doing work rather than agreeing with the default.
    var tree_first: Control = Router._first_focusable(s["host"])
    assert_ne(tree_first, first,
        "tree order and reading order must actually differ, or this test proves nothing")


## Where Tab goes from `c`. `Control::find_next_valid_focus()` returns exactly
## this node when `focus_next` is set AND THE TARGET CAN HOLD FOCUS — so the
## second half is asserted here rather than assumed. Reading the NodePath alone
## is what let a wired-but-refused control (a `FOCUS_ACCESSIBILITY` LinkButton)
## read as a valid stop while the engine stepped straight past it. The engine's
## own `find_next_valid_focus()` cannot be called here at all; see
## `test_the_harness_cannot_hold_focus_and_this_is_why` and the live instrument
## it points at.
func _tab(c: Control) -> Control:
    return _engine_would_stop_on(c.get_node_or_null(c.focus_next) as Control)


func _shift_tab(c: Control) -> Control:
    return _engine_would_stop_on(c.get_node_or_null(c.focus_previous) as Control)


## Returns the control, having asserted that Godot's focus walk would actually
## stop on it. `FOCUS_NONE` (0) is not a stop, `FOCUS_CLICK` (1) takes focus
## only from a click, and `FOCUS_ACCESSIBILITY` (3) — LinkButton's default in
## 4.7.1 — only while a screen reader is running. Only `FOCUS_ALL` (2) is a
## keyboard stop.
func _engine_would_stop_on(c: Control) -> Control:
    if c != null:
        assert_eq(c.focus_mode, Control.FOCUS_ALL,
            "'%s' is wired as a Tab stop but the engine would refuse it (mode %d)"
            % [_label_of(c), c.focus_mode])
    return c


func _label_of(c: Control) -> String:
    if c is Button:
        return (c as Button).text
    if c is LinkButton:
        return (c as LinkButton).text
    return String(c.name)


func _arrow(c: Control, forward: bool) -> Control:
    var p: NodePath = c.focus_neighbor_bottom if forward else c.focus_neighbor_top
    var q: NodePath = c.focus_neighbor_right if forward else c.focus_neighbor_left
    # §13.1 names no axis, so the shell binds all four arrows to the same step;
    # this asserts they really do agree before answering.
    assert_eq(str(p), str(q), "the vertical and horizontal arrow must agree")
    return c.get_node_or_null(p) as Control


func test_tab_from_the_last_control_in_a_region_reaches_the_next_region() -> void:
    var s: Dictionary = _shell()
    var regions: Array = Frame.focus_order(s["parts"])
    for i in regions.size():
        var members: Array = regions[i]
        var last: Control = members[members.size() - 1]
        var want: Control = regions[(i + 1) % regions.size()][0]
        assert_eq(_tab(last), want,
            "Tab out of region %d must land on the next region, not nowhere" % i)
    # §13.2: "it wraps, so there is no dead end" — the last region returns to
    # the rail rather than falling off the end of the screen.
    var tail: Array = regions[regions.size() - 1]
    assert_eq(_tab(tail[0]), regions[0][0], "the region ring wraps")
    assert_eq(_shift_tab(regions[0][0]), tail[0], "and wraps backwards too")


func test_tab_is_a_region_step_and_the_arrows_move_inside_the_region() -> void:
    var s: Dictionary = _shell()
    var regions: Array = Frame.focus_order(s["parts"])
    var rail: Array = regions[0]
    assert_true(rail.size() >= 3, "the rail needs several items to test this")
    # Tab leaves the rail from its FIRST item too — that is what makes Tab a
    # group step (§13.1) rather than a control step.
    assert_eq(_tab(rail[0]), regions[1][0])
    # Arrows step inside it, and wrap at both ends.
    assert_eq(_arrow(rail[0], true), rail[1])
    assert_eq(_arrow(rail[1], false), rail[0])
    assert_eq(_arrow(rail[rail.size() - 1], true), rail[0],
        "the last rail item wraps to the first — no dead end (§13.2)")
    assert_eq(_arrow(rail[0], false), rail[rail.size() - 1])


func test_the_other_reading_of_tab_is_available_behind_the_switch() -> void:
    # docs/13 §13.1 says Tab is a group step; every other toolkit says Tab walks
    # every control. The doc's answer is the default and the convention is a
    # switch — build/plan/q-a11y-keys.md carries the proposed docs/15 entry.
    var s: Dictionary = _shell()
    Frame.tab_steps_within_region = true
    var regions: Array = Frame.focus_order(s["parts"])
    var rail: Array = regions[0]
    assert_eq(_tab(rail[0]), rail[1],
        "with the switch on, Tab walks within the region")
    assert_eq(_tab(rail[rail.size() - 1]), regions[1][0],
        "and only the last member steps to the next region")
    assert_eq(_shift_tab(rail[0]), regions[regions.size() - 1][0],
        "and Shift+Tab off the first member still leaves the region")


func test_the_nav_rail_is_reachable_and_escapable() -> void:
    # Both halves matter: a rail nothing can Tab into is a mouse-only rail, and
    # a rail Tab cannot leave is the focus trap §13.1 forbids.
    var s: Dictionary = _shell()
    var regions: Array = Frame.focus_order(s["parts"])
    var rail: Array = regions[0]
    var walk: Control = s["scene"][0]
    var reached: bool = false
    for _i in regions.size() + 1:
        walk = _tab(walk)
        if walk == null:
            break
        if rail.has(walk):
            reached = true
            break
    assert_true(reached, "Tab from the content must reach the rail within one cycle")
    for item in rail:
        assert_false(rail.has(_tab(item as Control)),
            "Tab must always leave the rail — no trap")


func test_a_disabled_nav_item_is_not_a_tab_stop() -> void:
    # docs/13 §7 puts the reason in an adjacent string, so the dead control
    # itself would only be a stop that does nothing.
    var host := _host()
    var p = Frame.build(host, {"nav": [
        {"id": "home", "label": "Camp"},
        {"id": "tavern", "label": "Tavern", "reason": "Not built in this version yet."},
        {"id": "roster", "label": "Roster"},
    ], "active": "home"})
    var regions: Array = Frame.focus_order(p)
    var rail: Array = regions[0]
    assert_eq(rail.size(), 2, "the disabled item must be skipped")
    assert_false(rail.has(p.nav_buttons["tavern"]))
    assert_eq(_arrow(rail[0], true), p.nav_buttons["roster"],
        "the arrows step over it rather than stopping on it")


func test_focus_order_is_idempotent() -> void:
    # Screens call it again after rebuilding a list; a second call must not
    # produce a different order or a self-referential neighbour.
    var s: Dictionary = _shell()
    var first: Array = Frame.focus_order(s["parts"])
    var second: Array = Frame.focus_order(s["parts"])
    assert_eq(str(first), str(second))
    for members in second:
        for c in members:
            assert_ne((c as Control).get_node_or_null((c as Control).focus_next), c,
                "no control may Tab to itself")


func test_frame_offers_an_entry_control_for_default_focus() -> void:
    var s: Dictionary = _shell()
    assert_eq(Frame.focus_entry(s["parts"]), s["parts"].nav_buttons["home"])


# ------------------------------------------------------------ initial focus

class StubScreen extends Control:
    var target: Control = null
    func default_focus() -> Control:
        return target


func test_a_screen_can_declare_its_initial_focus() -> void:
    # The hook docs/13 §11.4 ("`Try again` is left and default-focused") and
    # §13.2 (the town's last-visited hotspot) both need.
    var screen := StubScreen.new()
    _root.add_child(screen)
    _made.append(screen)
    var first := Widgets.button("First in tree order")
    var wanted := Widgets.button("Try again")
    screen.add_child(first)
    screen.add_child(wanted)
    screen.target = wanted
    assert_eq(Router.initial_focus_target(screen), wanted,
        "the screen's declaration must beat tree order")


func test_a_screen_that_declares_nothing_still_gets_focus() -> void:
    # The fallback is what made this landable without editing eleven screens.
    var screen := Control.new()
    _root.add_child(screen)
    _made.append(screen)
    var first := Widgets.button("First")
    screen.add_child(first)
    screen.add_child(Widgets.button("Second"))
    assert_eq(Router.initial_focus_target(screen), first)


func test_a_declaration_that_cannot_hold_focus_falls_back() -> void:
    var screen := StubScreen.new()
    _root.add_child(screen)
    _made.append(screen)
    var dead := Widgets.button("Not built in this version yet.")
    dead.disabled = true
    var live := Widgets.button("Live")
    screen.add_child(dead)
    screen.add_child(live)
    screen.target = dead
    assert_eq(Router.initial_focus_target(screen), live,
        "a disabled control cannot be the initial focus")


func test_every_mounted_screen_designates_an_initial_focus_the_engine_accepts() -> void:
    # The blocking requirement, as far as this harness reaches. Renamed: the old
    # name promised "exactly one", which `initial_focus_target()` satisfies by
    # returning one Control by construction — it asserted nothing. What is
    # actually worth asserting is that the control it picks is one Godot will
    # TAKE, and the old `assert_ne(focus_mode, FOCUS_NONE)` was the exact check
    # that let a FOCUS_ACCESSIBILITY link through. The live half — that
    # something IS focused after goto() — is in tests/unit/a11y_smoke.gd,
    # because grab_focus() needs a tree this suite does not have.
    _ensure_autoloads()
    _reading_order_mattered = 0
    for path in [MAIN_MENU, TOWN, BOARD, SETTINGS]:
        if not Router.screen_exists(path):
            continue
        var r = _router()
        assert_true(r.goto(path), path)
        var screen: Control = r.current_screen()
        var target: Control = Router.initial_focus_target(screen)
        assert_ne(target, null, "%s: nothing to focus — the screen is mouse-only" % path)
        if target == null:
            continue
        assert_true(target == screen or screen.is_ancestor_of(target),
            "%s: the initial focus must be inside the screen" % path)
        assert_eq(target.focus_mode, Control.FOCUS_ALL,
            "%s: FOCUS_CLICK and FOCUS_ACCESSIBILITY both refuse grab_focus()" % path)
        assert_eq(Router.initial_focus_target(screen), target,
            "%s: the choice must be stable, not whichever control answers first" % path)
        var focusables: Array = []
        _collect_focusable(screen, focusables)
        assert_true(focusables.size() >= 1, path)
        assert_true(focusables.has(target), "%s: the target must be a real Tab stop" % path)
        if screen.has_method("default_focus"):
            continue
        if screen.has_meta(Frame.META_FOCUS_ENTRY):
            # A shell screen answers with READING order, which is the point:
            # §13.1 ends "rail, then header, then content, then commit", and
            # Frame.build() adds the scene host BEFORE the rail so the panels
            # draw over it — so tree order would open the screen mid-content.
            # This assertion used to demand tree order and is why the two are
            # worth distinguishing.
            assert_eq(screen.get_meta(Frame.META_FOCUS_ENTRY).call(), target,
                "%s: a shell screen opens at the rail, not at tree order" % path)
            if focusables[0] != target:
                _reading_order_mattered += 1
        else:
            assert_eq(focusables[0], target,
                "%s: with no shell and nothing declared, tree order is the fallback" % path)
    # The premise, asserted once rather than per screen: on at least one real
    # screen reading order and tree order genuinely disagree, so preferring the
    # shell's answer is doing work. (They coincide on the Adventure's Board with
    # no guild loaded, because its list is then empty.)
    assert_true(_reading_order_mattered >= 1,
        "reading order and tree order must differ somewhere, or this proves nothing")


var _reading_order_mattered: int = 0


func _collect_focusable(n: Node, out: Array) -> void:
    if n is Control and not (n as Control).visible:
        return
    # FOCUS_ALL, not "anything but FOCUS_NONE": this list is meant to be the
    # controls Godot's own walk stops on.
    if n is Control and (n as Control).focus_mode == Control.FOCUS_ALL \
            and not (n is BaseButton and (n as BaseButton).disabled):
        out.append(n)
    for c in n.get_children():
        _collect_focusable(c, out)


func test_the_router_wires_the_shells_focus_order_on_every_real_screen() -> void:
    # A11Y-02's headline defect was that `Frame.focus_order()` had ZERO callers
    # outside this file, so the shipped Tab order was still accidental tree
    # order. `Frame.build()` now leaves the call on the host as metadata and
    # `ScreenRouter._load_into_host` invokes it after `on_enter()`.
    #
    # The rail assertion is the trap check §13.1 forbids, made on the REAL
    # screens instead of the synthetic shell below: measured before the fix, the
    # Adventure's Board's live Tab chain was the six rail buttons, forever.
    _ensure_autoloads()
    var checked: int = 0
    for path in [TOWN, BOARD, SETTINGS]:
        if not Router.screen_exists(path):
            continue
        var r = _router()
        assert_true(r.goto(path), path)
        var screen: Control = r.current_screen()
        assert_true(screen.has_meta(Frame.META_FOCUS_ORDER),
            "%s: the shell must publish its focus hooks" % path)
        # Re-invoking is idempotent, so the test can read what the router wired.
        var regions: Array = screen.get_meta(Frame.META_FOCUS_ORDER).call()
        assert_true(regions.size() >= 2,
            "%s: one region means Tab can only cycle inside it — the trap" % path)
        var rail: Array = regions[0]
        assert_true(rail.size() >= 2, "%s: the rail" % path)
        for item in rail:
            assert_false(rail.has(_tab(item as Control)),
                "%s: Tab must leave the rail from every item" % path)
        assert_eq(Router.initial_focus_target(screen), rail[0],
            "%s: focus opens on the rail's first item (§13.1 reading order)" % path)
        checked += 1
    assert_true(checked >= 2, "expected at least two mountable shell screens")


func test_a_region_that_shrinks_to_one_member_drops_its_stale_neighbours() -> void:
    # `focus_order()` is documented as re-callable "after rebuilding a list".
    # `_wire_regions` only wrote `focus_neighbor_*` when the region had more than
    # one member and never cleared them, so a region that shrank kept relative
    # paths to controls that no longer exist — Godot resolves those to null and
    # the arrow does nothing, which reads as a dead control.
    var s: Dictionary = _shell()
    var p = s["parts"]
    Frame.focus_order(p)
    var first: Control = s["scene"][0]
    assert_ne(str(first.focus_neighbor_bottom), "",
        "three scene rows: the arrows step between them")
    for i in [2, 1]:
        var gone: Control = s["scene"][i]
        gone.get_parent().remove_child(gone)
        gone.free()
    Frame.focus_order(p)
    assert_eq(str(first.focus_neighbor_bottom), "",
        "one member left: the neighbour must be cleared, not left pointing at a freed node")
    assert_eq(str(first.focus_neighbor_top), "")
    assert_eq(str(first.focus_neighbor_left), "")
    assert_eq(str(first.focus_neighbor_right), "")
    # Tab still leaves the region — the region ring is unaffected by its size.
    assert_ne(_tab(first), null)
    assert_ne(_tab(first), first)


# ------------------------------------------------------------ Esc / Back

func test_the_harness_cannot_hold_focus_and_this_is_why() -> void:
    # Measured, not assumed, because it decides how every test above is written.
    # run_tests.gd does its whole run from `_initialize`, which is BEFORE the
    # root window enters the tree — the same reason its docstring notes that
    # `_ready` never fires here, and the reason tools/shot.gd does its work in
    # `_process` instead ("Everything below _init runs inside the tree").
    # `Control::grab_focus()` hard-requires `is_inside_tree()`, so nothing in
    # this suite can hold focus and `find_next_valid_focus()` always returns
    # null. The tests above therefore assert the WIRING Godot's Tab walk reads
    # (`focus_next`, `focus_neighbor_*`) plus the precondition that the engine
    # would accept each stop, which is the same fact one step earlier.
    #
    # THE LIVE HALF IS NOT MISSING, IT IS ELSEWHERE:
    #   godot --headless --path . --script res://tests/unit/a11y_smoke.gd
    # asks the engine directly — `gui_get_focus_owner()` after `goto()`,
    # `find_next_valid_focus()` for the Tab ring, `find_valid_focus_neighbor()`
    # for the arrows — on all eleven screens with the reference fixture applied.
    # It is not named `test_*`, so run_tests.gd's discovery skips it; it has its
    # own exit code. Measured this pass: `grab_focus()` works from `_process`
    # and fails from `_initialize`, which is the whole reason for the split.
    # No grab_focus() call here: outside the tree it is an ERR_FAIL that would
    # print an engine error into an otherwise clean gate.
    var c := Widgets.button("Probe")
    _root.add_child(c)
    _made.append(c)
    assert_false(c.is_inside_tree(),
        "if this ever fails, the harness gained a real tree — re-enable the live focus asserts")
    assert_false(c.has_focus())
    assert_eq(c.find_next_valid_focus(), null)


func test_escape_goes_back_one_level() -> void:
    _ensure_autoloads()
    var r = _router()
    assert_true(r.goto(TOWN))
    assert_true(r.push(BOARD))
    assert_eq(r.depth(), 2)
    assert_true(r.back())
    assert_eq(r.depth(), 1)
    assert_eq(r.current_path(), TOWN)


func test_escape_from_the_town_opens_settings() -> void:
    # §13.1: "Esc — Back one level; from the town, opens Settings."
    _ensure_autoloads()
    assert_true(Router.screen_exists(SETTINGS), "the premise: S15 exists")
    var r = _router()
    assert_true(r.goto(TOWN))
    assert_true(r.back())
    assert_eq(r.current_path(), SETTINGS)
    assert_eq(r.depth(), 2, "Settings goes ON the town, so Esc comes back")
    assert_true(r.back())
    assert_eq(r.current_path(), TOWN)


func test_the_gamepads_start_button_opens_settings() -> void:
    # docs/13 §13.2's `Start` row — "Settings (S15)", keyboard equivalent "`Esc`
    # from the town". The gamepad gets a direct route because it has no Esc, and
    # the row is unconditional, so it works away from the town too.
    _ensure_autoloads()
    var r = _router()
    assert_true(r.goto(BOARD))
    var ev := InputEventJoypadButton.new()
    ev.button_index = JOY_BUTTON_START
    ev.pressed = true
    assert_true(ev.is_action_pressed("nav_settings"), "Start must fire nav_settings")
    r._unhandled_input(ev)
    assert_eq(r.current_path(), SETTINGS, "Start opens Settings from any screen")
    # Inert once it is open: holding Start must not stack the screen.
    assert_false(r.settings())
    assert_eq(r.depth(), 2)
    assert_true(r.back(), "and B / Esc is the way out")
    assert_eq(r.current_path(), BOARD)


func test_escape_at_any_other_root_does_nothing() -> void:
    # The router must never quit the game on a keypress.
    _ensure_autoloads()
    var r = _router()
    assert_true(r.goto(MAIN_MENU))
    assert_false(r.back())
    assert_eq(r.depth(), 1)
    assert_eq(r.current_path(), MAIN_MENU)


func test_f1_is_wired_to_the_codex_and_inert_until_s16_exists() -> void:
    # §13.1's other global row. S16 is not built; the router must wait rather
    # than push a scene that is not there, because a failed push is a loud
    # push_error and a keyboard row that shouts is worse than one that waits.
    _ensure_autoloads()
    var r = _router()
    assert_true(r.goto(TOWN))
    var ev := InputEventKey.new()
    ev.physical_keycode = KEY_F1
    ev.pressed = true
    assert_true(ev.is_action_pressed("nav_codex"), "F1 must fire nav_codex")
    r._unhandled_input(ev)
    if Router.screen_exists(Router.CODEX_SCENE):
        assert_eq(r.current_path(), Router.CODEX_SCENE, "S16 exists now — F1 must open it")
    else:
        assert_eq(r.current_path(), TOWN, "S16 does not exist: F1 must do nothing at all")
        assert_eq(r.depth(), 1)


func test_the_escape_key_itself_is_wired() -> void:
    # `back()` is the behaviour; this is the wire from the key to it.
    _ensure_autoloads()
    var r = _router()
    assert_true(r.goto(TOWN))
    assert_true(r.push(BOARD))
    var ev := InputEventKey.new()
    ev.keycode = KEY_ESCAPE
    ev.physical_keycode = KEY_ESCAPE
    ev.pressed = true
    r._unhandled_input(ev)
    assert_eq(r.depth(), 1, "Esc must reach the router")
    assert_eq(r.current_path(), TOWN)
