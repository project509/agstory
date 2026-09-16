extends "res://tests/TestCase.gd"
## W1-HALL — the hall family stands on the bare camp (docs/15 BL-78, art/ref/specs/09
## §4.1 and §4.5). RULES-10 / HALL-01 were the last five screens on a Concept 1 crop
## with its patrons painted in; these tests mount the real scenes through the real
## router host, the way Boot does, and read the tree: one SceneStage under each,
## no TextureRect pointing at a `_plate.png`, Settings on the stage of the screen
## beneath it, and the camp held still under reduced motion.
##
## The two settings this file flips are persisted (GameSettings writes
## user://settings.cfg on exit), so the developer's own values are put back in
## `after_each`, which runs even when an assertion fails.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const GuildhallScript = preload("res://game/screens/Guildhall.gd")
const FacilitiesScript = preload("res://game/screens/Facilities.gd")
const LoadSaveScript = preload("res://game/screens/LoadSave.gd")
const SettingsScreen = preload("res://game/screens/Settings.gd")
const TownScript = preload("res://game/screens/Town.gd")

const TOWN := "res://game/screens/Town.tscn"
const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const GUILDHALL := "res://game/screens/Guildhall.tscn"
const RAIDER_DETAIL := "res://game/screens/RaiderDetail.tscn"
const LOAD_SAVE := "res://game/screens/LoadSave.tscn"
const SETTINGS := "res://game/screens/Settings.tscn"

## The four routed hall scenes; Roster and Facilities are tabs inside Guildhall.
const HALL_SCENES := [GUILDHALL, RAIDER_DETAIL, LOAD_SAVE, SETTINGS]

## The six owned files: none may name the crop again.
const HALL_FILES := [
    "res://game/screens/Guildhall.gd",
    "res://game/screens/Roster.gd",
    "res://game/screens/Facilities.gd",
    "res://game/screens/RaiderDetail.gd",
    "res://game/screens/LoadSave.gd",
    "res://game/screens/Settings.gd",
]

var _root: Node = null
var _made: Array = []
var _motion_was = null
var _effects_was = null


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []
    _motion_was = null
    _effects_was = null


func after_each() -> void:
    var gs = _root.get_node_or_null("GameSettings") if _root != null else null
    if gs != null and _motion_was != null:
        gs.set_value("reduced_motion", _motion_was)
    if gs != null and _effects_was != null:
        gs.set_value("reduced_effects", _effects_was)
    var st = _root.get_node_or_null("GameState") if _root != null else null
    if st != null:
        st.reset()
        st.content = null
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
    if _motion_was == null:
        _motion_was = gs.get_value("reduced_motion")
        _effects_was = gs.get_value("reduced_effects")
    return gs


## A host registered on the REAL autoload router, exactly as Boot does — a screen
## navigates through `Services.router()`, which is the autoload (LESSONS.md).
func _router_with_host():
    var host := Control.new()
    host.name = "HallPlatesHost"
    _root.add_child(host)
    _made.append(host)
    var r = _root.get_node_or_null("ScreenRouter")
    r.register_host(host)
    return r


func _new_guild(name: String) -> void:
    var st = _root.get_node_or_null("GameState")
    st.new_game(name)


## Every SceneStage under `n` — the stage names itself "SceneStage_<scene>".
func _stages(n: Node, out: Array = []) -> Array:
    if String(n.name).begins_with("SceneStage_"):
        out.append(n)
    for c in n.get_children():
        _stages(c, out)
    return out


## The resource path behind every TextureRect under `n` (an AtlasTexture reports
## the sheet it crops), so a crop of the old plate is caught as well as the
## plate itself.
func _texture_paths(n: Node, out: Array = []) -> Array:
    if n is TextureRect and (n as TextureRect).texture != null:
        var tex: Texture2D = (n as TextureRect).texture
        if tex is AtlasTexture and (tex as AtlasTexture).atlas != null:
            out.append(String((tex as AtlasTexture).atlas.resource_path))
        else:
            out.append(String(tex.resource_path))
    for c in n.get_children():
        _texture_paths(c, out)
    return out


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append(n)
    for c in n.get_children():
        _labels(c, out)
    return out


func _sprites(n: Node, out: Array = []) -> Array:
    if n is AnimatedSprite2D:
        out.append(n)
    for c in n.get_children():
        _sprites(c, out)
    return out


func _find_button(n: Node, text: String):
    if n is Button and (n as Button).text == text:
        return n
    for c in n.get_children():
        var found = _find_button(c, text)
        if found != null:
            return found
    return null


func _assert_no_plate_crop(screen: Node, where: String) -> void:
    for p in _texture_paths(screen):
        assert_false(String(p).contains("_plate.png"),
            "%s: no TextureRect may show a mockup crop, found %s" % [where, p])


# ---------------------------------------------------------------- the ground

## RULES-10's acceptance: each hall screen mounts one SceneStage — the camp —
## and nothing under it is a `_plate.png` or a crop of one.
func test_every_hall_screen_stands_on_one_camp_stage_and_no_plate_crop() -> void:
    _ensure_autoloads()
    _new_guild("Hall Guild")
    var r = _router_with_host()
    for path in HALL_SCENES:
        assert_true(r.goto(path), "%s must open" % path)
        var screen: Control = r.current_screen()
        var stages: Array = _stages(screen)
        assert_eq(stages.size(), 1, "%s mounts exactly one SceneStage" % path)
        if stages.size() == 1:
            assert_eq(String(stages[0].name), "SceneStage_stage_camp",
                "%s stands on the bare camp" % path)
            var plate: Node = (stages[0] as Node).get_node_or_null("Plate")
            assert_ne(plate, null, "%s: the stage carries its plate" % path)
        _assert_no_plate_crop(screen, path)


## Facilities is a tab inside the Guildhall's panel and was the fifth offender:
## its sidebar card cropped the bar with the painted bartender. HALL-18's
## interim: the same card crops the bare camp's big tent.
func test_the_facilities_hall_card_crops_the_bare_camps_tent() -> void:
    _ensure_autoloads()
    _new_guild("Tent Guild")
    var r = _router_with_host()
    assert_true(r.goto(GUILDHALL))
    var screen: Control = r.current_screen()
    var tab = _find_button(screen, "Facilities")
    assert_ne(tab, null, "the Facilities tab is a Button")
    if tab == null:
        return
    tab.pressed.emit()
    _assert_no_plate_crop(screen, "Guildhall > Facilities")
    assert_eq(FacilitiesScript.HALL_CARD_CROP, Rect2(230, 110, 337, 104),
        "the interim crop is the big tent, the rect HALL's plate plan names")
    var found := false
    for n in _texture_rects(screen):
        var tex: Texture2D = (n as TextureRect).texture
        if tex is AtlasTexture and (tex as AtlasTexture).atlas != null \
                and String((tex as AtlasTexture).atlas.resource_path).ends_with("stage_camp.png"):
            found = true
            assert_eq((tex as AtlasTexture).region, FacilitiesScript.HALL_CARD_CROP,
                "the card crops the tent rect")
    assert_true(found, "the Facilities sidebar card shows a crop of stage_camp.png")
    assert_eq(_stages(screen).size(), 1, "the tab adds no second stage")


func _texture_rects(n: Node, out: Array = []) -> Array:
    if n is TextureRect:
        out.append(n)
    for c in n.get_children():
        _texture_rects(c, out)
    return out


## The panels cover most of the window, so the camp's words — the speaking plate
## and the "..." bubbles — are left out of the hall's stage: a bubble under a
## panel is a smudge at its edge. Everything that moves is kept.
func test_the_hall_stage_carries_no_words() -> void:
    _ensure_autoloads()
    _new_guild("Quiet Guild")
    var r = _router_with_host()
    for path in [GUILDHALL, LOAD_SAVE]:
        assert_true(r.goto(path))
        var stages: Array = _stages(r.current_screen())
        if stages.size() != 1:
            fail("%s: expected one stage" % path)
            continue
        var stage: Node = stages[0]
        for l in _labels(stage):
            assert_eq(String((l as Label).text), "", "%s: no speech under the panels" % path)
        for p in _texture_paths(stage):
            assert_false(String(p).contains("speech_bubble"),
                "%s: no ambient bubble under the panels" % path)
        assert_true(_sprites(stage).size() > 0,
            "%s: the camp's figures and fire are still there" % path)


## Q03's switch: the recommended default is the Town's own framing, so Town →
## Guildhall reads as a panel over the same camp. RaiderDetail follows the
## Guildhall; flipping HALL_FRAMING moves both.
func test_the_hall_frames_the_camp_as_the_town_does_until_q03_rules() -> void:
    assert_eq(GuildhallScript.HALL_FRAMING, "same", "the default the plan records")
    var fr: Dictionary = GuildhallScript.framing()
    assert_eq(fr["offset"], TownScript.CAMP_OFFSET, "same framing as the hub")
    var dim: Color = fr["dim"]
    assert_true(dim.r > 0.0 and dim.r < 1.0 and dim.b > 0.0 and dim.b < 1.0,
        "a dim, not a blackout and not a no-op")
    assert_true(GuildhallScript.FRAMINGS.has("tight"), "the other answer is authored")
    _ensure_autoloads()
    _new_guild("Framed Guild")
    var r = _router_with_host()
    for path in [GUILDHALL, RAIDER_DETAIL]:
        assert_true(r.goto(path))
        var stages: Array = _stages(r.current_screen())
        if stages.size() == 1:
            var stage: Control = stages[0]
            assert_eq(stage.position, fr["offset"], "%s at the hall's offset" % path)
            assert_eq(stage.modulate, dim, "%s at the hall's dim" % path)
    # HALL-02: LoadSave frees a band for the fire ring, so its own offset differs.
    assert_true(r.goto(LOAD_SAVE))
    var ls: Array = _stages(r.current_screen())
    if ls.size() == 1:
        assert_eq((ls[0] as Control).position, LoadSaveScript.CAMP_OFFSET)
    assert_true(LoadSaveScript.PANEL_W < 928,
        "the slots panel stops short of the window so the camp shows beside it")


# ---------------------------------------------------------------- Settings

## Spec 09 §4.5: Settings has no ground of its own. From the camp it stands on
## the camp; from the title screen, on the aerial the menu stands on.
func test_settings_inherits_the_stage_of_the_screen_beneath_it() -> void:
    _ensure_autoloads()
    _new_guild("Options Guild")
    var r = _router_with_host()

    assert_true(r.goto(TOWN))
    assert_true(r.push(SETTINGS), "Esc from the camp pushes Settings")
    assert_eq(r.previous_path(), TOWN)
    var from_town: Array = _stages(r.current_screen())
    assert_eq(from_town.size(), 1)
    if from_town.size() == 1:
        assert_eq(String(from_town[0].name), "SceneStage_stage_camp",
            "opened over the camp, it stands on the camp")
        assert_eq((from_town[0] as Control).position, TownScript.CAMP_OFFSET,
            "at the camp's own framing, so the desk does not move")

    assert_true(r.goto(MAIN_MENU))
    assert_true(r.push(SETTINGS), "Start from the title pushes Settings")
    assert_eq(r.previous_path(), MAIN_MENU)
    var from_menu: Array = _stages(r.current_screen())
    assert_eq(from_menu.size(), 1)
    if from_menu.size() == 1:
        assert_eq(String(from_menu[0].name), "SceneStage_stage_town",
            "opened over the title screen, it stands on the aerial")
    _assert_no_plate_crop(r.current_screen(), "Settings from MainMenu")

    # The table, read directly: the hall pair follows the Guildhall's framing,
    # and anything unknown — including nothing at all — is the camp.
    assert_eq(SettingsScreen.stage_for(""), SettingsScreen.STAGE_DEFAULT)
    assert_eq(String(SettingsScreen.STAGE_DEFAULT[0]), "stage_camp")
    assert_eq(SettingsScreen.STAGE_DEFAULT[1], TownScript.CAMP_OFFSET)
    assert_eq(SettingsScreen.stage_for("res://game/screens/Nowhere.tscn"),
        SettingsScreen.STAGE_DEFAULT)
    var hall: Array = SettingsScreen.stage_for(GUILDHALL)
    assert_eq(String(hall[0]), GuildhallScript.CAMP_SCENE)
    assert_eq(hall[1], GuildhallScript.framing()["offset"])
    assert_eq(String(SettingsScreen.stage_for(MAIN_MENU)[0]), "stage_town")


## The router fact Settings reads: the screen beneath, or "" at the root.
func test_previous_path_is_the_screen_beneath_the_current_one() -> void:
    _ensure_autoloads()
    _new_guild("Stack Guild")
    var r = _router_with_host()
    assert_true(r.goto(TOWN))
    assert_eq(r.previous_path(), "", "nothing beneath the root")
    assert_true(r.push(SETTINGS))
    assert_eq(r.previous_path(), TOWN)
    assert_true(r.push(LOAD_SAVE))
    assert_eq(r.previous_path(), SETTINGS, "the stack, not the first screen")
    assert_true(r.pop())
    assert_eq(r.previous_path(), TOWN)
    assert_true(r.pop())
    assert_eq(r.previous_path(), "")
    assert_eq(r.current_path(), TOWN)


# ---------------------------------------------------------------- settings doors

## docs/13 §13: reduced motion holds the world layer still. The stage applies it
## in `_ready`, which never fires under this harness — so the hall applies it
## when it builds the stage, and this is the assertion that it does.
func test_reduced_motion_holds_the_camp_still_under_the_panels() -> void:
    var gs = _ensure_autoloads()
    _new_guild("Still Guild")
    gs.set_value("reduced_motion", true)
    var r = _router_with_host()
    for path in [GUILDHALL, SETTINGS]:
        assert_true(r.goto(path))
        var stages: Array = _stages(r.current_screen())
        if stages.size() != 1:
            fail("%s: expected one stage" % path)
            continue
        var stage = stages[0]
        assert_true(stage.motion_held(), "%s: the stage knows it is held" % path)
        assert_false(stage.is_processing(), "%s: nothing ticks" % path)
        for s in _sprites(stage):
            assert_false((s as AnimatedSprite2D).is_playing(),
                "%s: every figure and flame is on its first frame" % path)
            assert_eq((s as AnimatedSprite2D).frame, 0)
    gs.set_value("reduced_motion", false)
    assert_true(r.goto(GUILDHALL))
    var live: Array = _stages(r.current_screen())
    if live.size() == 1:
        assert_false(live[0].motion_held(), "with the option off the camp moves")


# ---------------------------------------------------------------- the source

## Read as text, the way test_motion.gd reads the lint: a screen that went back
## to the crop would still pass every string test, because the tests read
## words and the crop carries none.
func test_nothing_in_the_hall_family_names_the_crop() -> void:
    for path in HALL_FILES:
        var f := FileAccess.open(path, FileAccess.READ)
        assert_ne(f, null, "%s must exist" % path)
        if f == null:
            continue
        var src := f.get_as_text()
        assert_false(src.contains("guildhall" + "_plate"),
            "%s must not name the Concept 1 crop" % path)
        assert_false(src.contains("_plate.png"),
            "%s must not load any mockup plate" % path)
    var hall := FileAccess.get_file_as_string("res://game/screens/Guildhall.gd")
    assert_true(hall.contains("const HALL_FRAMING := \"same\""),
        "Q03's switch is a constant the designer's answer flips")
    var router := FileAccess.get_file_as_string("res://game/core/ScreenRouter.gd")
    assert_true(router.contains("func previous_path() -> String:"),
        "the router owns the stack fact Settings reads")
    for path in ["res://game/screens/Guildhall.gd", "res://game/screens/RaiderDetail.gd",
            "res://game/screens/Settings.gd"]:
        var src := FileAccess.get_file_as_string(path)
        assert_false(src.contains("sun.png"),
            "%s: the chips are the frame's (HALL-19/KIT-03)" % path)
        assert_true(src.contains("Frame.standard_chips("),
            "%s calls Frame.standard_chips" % path)
