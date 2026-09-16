extends "res://tests/TestCase.gd"
## docs/13 §4.4's text scale, on a MOUNTED screen (RULES-02, CRITIC-G15).
##
## `test_a11y_legibility.gd` proves the arithmetic of `Type.at`; nothing proved
## that a screen ever asked for it — every `build()` called `Theme_.get_theme()`
## bare and the option on the settings page did nothing. These tests mount the
## real scenes through the real router host, the way Boot does, and measure a
## Label; and they read the screens' source so a fifteenth screen cannot go back
## to the bare call without this file saying so.
##
## The setting is persisted (GameSettings writes user://settings.cfg), so the
## developer's own scale is put back in `after_each`, which runs even when an
## assertion fails.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")

const TOWN := "res://game/screens/Town.tscn"
const SETTINGS := "res://game/screens/Settings.tscn"

## Every file whose `build()` must go through the door, plus Boot's overlay.
const DOOR_FILES := [
    "res://game/screens/AdventureBoard.gd",
    "res://game/screens/Completion.gd",
    "res://game/screens/Guildhall.gd",
    "res://game/screens/LoadSave.gd",
    "res://game/screens/MainMenu.gd",
    "res://game/screens/Market.gd",
    "res://game/screens/RaidPrep.gd",
    "res://game/screens/RaidView.gd",
    "res://game/screens/RaiderDetail.gd",
    "res://game/screens/Results.gd",
    "res://game/screens/Settings.gd",
    "res://game/screens/Tavern.gd",
    "res://game/screens/Town.gd",
    "res://game/ui/Boot.gd",
]

## Variations whose size is `Type.BODY`, plus the bare Label (the theme's
## `default_font_size` is BODY too).
const BODY_VARIATIONS := ["", "LabelBody", "LabelMuted", "LabelLog"]

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
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


# ---------------------------------------------------------------- helpers

## The autoloads a screen looks up. Under `--script` the project's autoloads may
## not be instantiated, so provide them rather than skipping (test_screens.gd).
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


## A host registered on the REAL autoload router, exactly as Boot does — a screen
## navigates through `Services.router()`, which is the autoload (LESSONS.md).
func _router_with_host():
    var host := Control.new()
    host.name = "TextScaleHost"
    _root.add_child(host)
    _made.append(host)
    var r = _root.get_node_or_null("ScreenRouter")
    r.register_host(host)
    return r


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append(n)
    for c in n.get_children():
        _labels(c, out)
    return out


## THE HARNESS NEVER ENTERS THE TREE (run_tests.gd runs from `_initialize`), and
## that matters here in one specific way: when a subtree is parented under a
## themed Control, the engine assigns every descendant its theme owner but sends
## NOTIFICATION_THEME_CHANGED only when the node is inside the tree. A Label that
## shaped its text before it was parented has already cached the default theme's
## 16px, and off-tree nothing ever clears that cache — so it reports 16 at every
## scale, which is what an unfixed reading of this test showed (16 at 100, 16 at
## 150). In the game the tree delivers the notification on entry; this delivers
## the same one, once, and nothing else.
func _settle_theme(screen: Node) -> void:
    screen.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)


## The Labels whose theme size is BODY and that nothing overrides by hand.
func _body_labels(screen: Node) -> Array:
    _settle_theme(screen)
    var out: Array = []
    for l in _labels(screen):
        var lab: Label = l
        if lab.theme_type_variation in BODY_VARIATIONS \
                and not lab.has_theme_font_size_override("font_size"):
            out.append(lab)
    return out


func _find_button(n: Node, text: String):
    if n is Button and (n as Button).text == text:
        return n
    for c in n.get_children():
        var found = _find_button(c, text)
        if found != null:
            return found
    return null


# ---------------------------------------------------------------- the door

func test_the_door_reads_the_autoload_and_falls_back_to_100() -> void:
    var gs = _ensure_autoloads()
    gs.set_value("text_scale", 150)
    assert_eq(Theme_.scale_of(null), 150,
        "outside the tree the door finds the autoload on the main loop's root")
    assert_true(Theme_.current(null) == Theme_.get_theme(150),
        "current() is get_theme(pct) — the same cached Theme object")
    gs.set_value("text_scale", 100)
    assert_eq(Theme_.scale_of(null), 100)
    assert_true(Theme_.current(null) == Theme_.get_theme(),
        "at 100 the door hands out the unscaled theme, byte-identical")
    assert_true(Theme_.get_theme(100) == Theme_.get_theme(),
        "get_theme() and get_theme(100) are one cache entry")


## The plan's acceptance line, verbatim: set 150 on the autoload, mount Town
## through the real router host, and a Label measures Type.at(Type.BODY, 150).
func test_a_mounted_town_at_150_measures_150() -> void:
    var gs = _ensure_autoloads()
    var st = _root.get_node_or_null("GameState")
    st.new_game("Scaled Guild")
    gs.set_value("text_scale", 150)
    var r = _router_with_host()
    assert_true(r.goto(TOWN), "the town must open")
    var screen: Control = r.current_screen()
    assert_true(screen.theme == Theme_.get_theme(150),
        "the screen's theme is the 150 entry, not the bare one")
    var want: int = Type.at(Type.BODY, 150)
    assert_true(want > Type.BODY, "150 must actually be larger")
    # Harness-independent half: the Theme the screen holds carries the size.
    assert_eq(screen.theme.get_font_size("font_size", "LabelBody"), want,
        "the 150 theme's LabelBody is BODY at 150")
    assert_eq(screen.theme.default_font_size, want,
        "and so is the default font size a bare Label inherits")
    var body: Array = _body_labels(screen)
    assert_true(body.size() > 0, "the town prints at least one BODY Label")
    for l in body:
        var lab: Label = l
        assert_eq(lab.get_theme_font_size("font_size"), want,
            "'%s' (%s) must measure Type.at(BODY, 150)"
            % [lab.text.left(30), lab.theme_type_variation])
    st.reset()
    st.content = null


## Identity at 100, on the same mounted screen: nothing moves for a player who
## never touched the option, which is what keeps the art gate's baselines.
func test_a_mounted_town_at_100_is_the_unscaled_theme() -> void:
    var gs = _ensure_autoloads()
    var st = _root.get_node_or_null("GameState")
    st.new_game("Plain Guild")
    gs.set_value("text_scale", 100)
    var r = _router_with_host()
    assert_true(r.goto(TOWN), "the town must open")
    var screen: Control = r.current_screen()
    assert_true(screen.theme == Theme_.get_theme(),
        "at 100 the screen holds the very theme every screen held before the door")
    var body: Array = _body_labels(screen)
    assert_true(body.size() > 0, "the town prints at least one BODY Label")
    for l in body:
        var lab: Label = l
        assert_eq(lab.get_theme_font_size("font_size"), Type.BODY,
            "'%s' must measure the unscaled BODY at 100" % lab.text.left(30))
    st.reset()
    st.content = null


## Every screen names the door and none keeps the bare call. Read as text, the
## way test_motion.gd reads the lint: a screen that goes back to
## `Theme_.get_theme()` would still pass every other test, because a bare theme
## is a working theme at 100.
func test_every_screen_builds_its_theme_through_the_door() -> void:
    for path in DOOR_FILES:
        var f := FileAccess.open(path, FileAccess.READ)
        assert_ne(f, null, "%s must exist" % path)
        if f == null:
            continue
        var src := f.get_as_text()
        assert_true(src.contains("theme = Theme_.current(self)"),
            "%s must set its theme through Theme_.current(self)" % path)
        assert_false(src.contains("Theme_.get_theme("),
            ("%s must not call Theme_.get_theme() itself — that is the pre-RULES-02 "
            + "bare call that ignored the setting") % path)
    var theme_src := FileAccess.get_file_as_string("res://game/ui/Theme.gd")
    assert_true(theme_src.contains("static func current(who: Node) -> Theme:"),
        "Theme.gd owns the door")
    assert_true(theme_src.contains("static func scale_of(who: Node) -> int:"),
        "and the pct half of it, for direct font sizes")


# ---------------------------------------------------------------- Settings' Apply

## Apply re-mounts the options page at the new scale AND keeps the stack it was
## pushed on: Back after Apply must still return to the camp, not the main menu.
func test_apply_rebuilds_settings_at_the_new_scale_and_keeps_the_stack() -> void:
    var gs = _ensure_autoloads()
    var st = _root.get_node_or_null("GameState")
    st.new_game("Options Guild")
    gs.set_value("text_scale", 100)
    var r = _router_with_host()
    assert_true(r.goto(TOWN))
    assert_true(r.push(SETTINGS), "Esc from the camp pushes Settings")
    assert_eq(r.depth(), 2)
    var before: Control = r.current_screen()
    assert_true(before.theme == Theme_.get_theme(100))

    # The scale cycles by value on its own button: 100% -> 125%.
    var scale_btn = _find_button(before, "100%")
    assert_ne(scale_btn, null, "the text-scale row shows its value as a Button")
    if scale_btn == null:
        return
    scale_btn.pressed.emit()
    assert_eq(int(gs.get_value("text_scale")), 125, "one press steps to 125")
    assert_true(r.current_screen() == before,
        "stepping the value alone does not re-mount — Apply is the commit")

    var apply = _find_button(r.current_screen(), "Apply")
    assert_ne(apply, null, "Apply is a Button")
    if apply == null:
        return
    apply.pressed.emit()
    var after: Control = r.current_screen()
    assert_true(after != before, "Apply re-mounts the page")
    assert_true(after.theme == Theme_.get_theme(125),
        "and the fresh page is themed at 125")
    assert_eq(r.current_path(), SETTINGS, "still on the options page")
    assert_eq(r.depth(), 2, "the stack survived: Back still leads to the camp")
    for l in _body_labels(after):
        var lab: Label = l
        assert_eq(lab.get_theme_font_size("font_size"), Type.at(Type.BODY, 125),
            "'%s' measures BODY at 125 on the re-mounted page" % lab.text.left(30))

    # Applying without changing the scale again leaves the page alone.
    var apply2 = _find_button(after, "Apply")
    assert_ne(apply2, null)
    if apply2 != null:
        apply2.pressed.emit()
        assert_true(r.current_screen() == after,
            "a second Apply at the same scale must not restart the screen")

    assert_true(r.pop(), "Back pops to the camp")
    assert_eq(r.current_path(), TOWN)
    assert_true(r.current_screen().theme == Theme_.get_theme(125),
        "the camp beneath is rebuilt at the applied scale on its next mount")
    st.reset()
    st.content = null


## Restore defaults saves the file as Apply does, so it re-mounts the same way:
## a page still drawn at 150 over a saved 100 would be RULES-02 in miniature.
func test_restore_defaults_rebuilds_settings_at_100_and_keeps_the_stack() -> void:
    var gs = _ensure_autoloads()
    var st = _root.get_node_or_null("GameState")
    st.new_game("Default Guild")
    gs.set_value("text_scale", 150)
    var r = _router_with_host()
    assert_true(r.goto(TOWN))
    assert_true(r.push(SETTINGS))
    var before: Control = r.current_screen()
    assert_true(before.theme == Theme_.get_theme(150), "pushed at 150")
    var defaults = _find_button(before, "Restore defaults")
    assert_ne(defaults, null, "Restore defaults is a Button")
    if defaults == null:
        return
    defaults.pressed.emit()
    assert_eq(int(gs.get_value("text_scale")), 100, "defaults put the scale back to 100")
    var after: Control = r.current_screen()
    assert_true(after != before, "the page re-mounts at the restored scale")
    assert_true(after.theme == Theme_.get_theme(), "and holds the unscaled theme")
    assert_eq(r.current_path(), SETTINGS)
    assert_eq(r.depth(), 2, "Back still leads to the camp")
    st.reset()
    st.content = null
