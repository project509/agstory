extends "res://tests/TestCase.gd"
## W3-MENU: the first and last screens (00-plan §4).
##
## MainMenu is read the way the game reads it — mounted through a router host —
## and asserted three ways: the lockup is the authored art (the emblem, the 58
## mark, the tagline texture) with the Label "A Guild Story" still beside it for
## test_screens.gd:180; a version line prints bottom-left; hover is a lifted
## copy of the theme's plate with no layout shift and no tween. Completion is
## mounted on a finished guild WITH content, so the credits roll has a roster to
## name; the band sits at the bottom of the scene host and the fireside figures
## stand in the open above it; the CTA keeps its text verbatim and its inset.
## Boot's overlay is built bare (no tree, no `_ready`): the card on PanelWarm,
## the failure card's widths through Type, and the source order that applies
## `display_aspect` before the overlay is shown (CRITIC-G02).

const Frame = preload("res://game/ui/Frame.gd")
const Type = preload("res://game/ui/Type.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const MainMenuScript = preload("res://game/screens/MainMenu.gd")
const CompletionScript = preload("res://game/screens/Completion.gd")
const BootScript = preload("res://game/ui/Boot.gd")
const Enums = preload("res://sim/model/Enums.gd")

const SaveGame = preload("res://game/core/SaveGame.gd")

const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const COMPLETION := "res://game/screens/Completion.tscn"
const TOWN := "res://game/screens/Town.tscn"
const RESULTS := "res://game/screens/Results.tscn"
const A1 := "t1_adv_a1"
const TAGLINE := "Questionable people. Worse decisions."
const CTA_TEXT := "Back to town — the guild carries on"
const VERSION_KEY := "application/config/version"

var _root: Node = null
var _made: Array = []


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []


func after_each() -> void:
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
    if _root.get_node_or_null("GameSettings") == null:
        var gs = SettingsScript.new()
        gs.name = "GameSettings"
        _root.add_child(gs)
        _made.append(gs)


func _host() -> Control:
    var h := Control.new()
    h.name = "MenuLockupHost"
    _root.add_child(h)
    _made.append(h)
    return h


## The screen mounted through a fresh router on a fresh host, as test_screens does.
func _mount(path: String) -> Control:
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    assert_true(r.goto(path), "%s must mount" % path)
    return r.current_screen()


## Label/Button text only — the walker every screen test uses.
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


func _find_named(n: Node, name: String) -> Node:
    if String(n.name) == name:
        return n
    for c in n.get_children():
        var found := _find_named(c, name)
        if found != null:
            return found
    return null


func _find_button(n: Node, text: String) -> Button:
    if n is Button and (n as Button).text == text:
        return n as Button
    for c in n.get_children():
        var found := _find_button(c, text)
        if found != null:
            return found
    return null


func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out


func _stages(n: Node, out: Array = []) -> Array:
    if String(n.name).begins_with("SceneStage_"):
        out.append(n)
    for c in n.get_children():
        _stages(c, out)
    return out


func _source(path: String) -> String:
    return FileAccess.get_file_as_string(path)


# ---------------------------------------------------------------- MainMenu: the lockup

func test_the_title_is_the_authored_lockup_and_the_label_stays() -> void:
    _ensure_autoloads()
    var screen := _mount(MAIN_MENU)
    var lockup := _find_named(screen, "Lockup")
    assert_ne(lockup, null, "the lockup host exists")
    var emblem := _find_named(lockup, "Emblem")
    assert_true(emblem is TextureRect and (emblem as TextureRect).texture != null, "the emblem is drawn")
    var mark := _find_named(lockup, "wordmark_58")
    assert_true(mark is TextureRect and (mark as TextureRect).texture != null,
        "the title is the pre-rendered 58 mark (TOWN-12)")
    # 01 §5: the mark starts at the emblem's right edge and sits on its baseline.
    assert_eq((mark as Control).position.x, (emblem as Control).size.x, "mark at the emblem's right")
    var baseline: float = (mark as Control).position.y + Frame.wordmark_baseline("wordmark_58")
    assert_eq(baseline, float(MainMenuScript.MARK_BASELINE_DY), "the mark sits by its baseline")
    # The strings test_screens.gd:180-183 reads are still Labels/Buttons.
    var printed := _joined(screen)
    assert_true(printed.contains("A Guild Story"), "the title Label stays: %s" % printed)
    assert_true(printed.contains("New Guild"))
    assert_true(printed.contains("Continue"))
    assert_true(printed.contains("Quit"))
    var title := _find_named(lockup, "Title")
    assert_true(title is Label and (title as Label).text == "A Guild Story",
        "the Label is beside the art as its accessible name")
    assert_false((title as Label).visible, "and is not drawn a second time over the mark")


func test_the_tagline_follows_the_header_lockup_switch() -> void:
    _ensure_autoloads()
    var screen := _mount(MAIN_MENU)
    var lockup := _find_named(screen, "Lockup")
    var spec: Dictionary = Frame.LOCKUPS[Frame.LOCKUP]
    var tag := _find_named(lockup, "wordmark_tagline")
    if bool(spec["tagline"]):
        assert_true(tag is TextureRect and (tag as TextureRect).texture != null,
            "Q05's default (44_tagline) hangs the tagline under the title too")
        # 03 §6: on the mark's left edge, its baseline under the mark's.
        var mark := _find_named(lockup, "wordmark_58") as Control
        assert_eq((tag as Control).position.x, mark.position.x, "tagline on the mark's left edge")
        var tag_baseline: float = (tag as Control).position.y + Frame.wordmark_baseline("wordmark_tagline")
        assert_eq(tag_baseline, float(MainMenuScript.MARK_BASELINE_DY + MainMenuScript.TAGLINE_BASELINE_DY))
        # The designer's words, verbatim, still in a Label (never paraphrased).
        assert_true(_joined(screen).contains(TAGLINE), "the tagline text is a Label")
        # The trailing rule is drawn only when it is a rule, not a stub.
        var rule := _find_named(lockup, "TaglineRule")
        var rule_w: float = mark.position.x + (mark as TextureRect).texture.get_width() \
            - ((tag as Control).position.x + (tag as TextureRect).texture.get_width() + 6.0)
        if rule_w >= MainMenuScript.RULE_MIN_W:
            assert_true(rule is ColorRect, "a rule of %d px is drawn" % int(rule_w))
            assert_eq((rule as Control).size.x, rule_w, "and ends at the mark's right edge")
        else:
            assert_eq(rule, null, "a %d px stub is not a rule" % int(rule_w))
    else:
        assert_eq(tag, null, "with LOCKUP flipped to 58 the title carries no tagline")


func test_the_stale_water_comment_is_gone() -> void:
    # RULES-05: the aerial's shimmer exists (stage_town.json's rects), the clouds
    # and smoke landed with W2-STAGE2; the comment says so and names what is left.
    var src := _source("res://game/screens/MainMenu.gd")
    assert_false(src.contains("none of which SceneStage can build"), "MainMenu.gd no longer denies the shimmer")
    assert_true(src.contains("water shimmer is on"), "and says the shimmer is on")
    assert_true(src.contains("M4B-VFX-01"), "and names the audit item that owes the rest")


# ---------------------------------------------------------------- MainMenu: the version line

func test_the_version_line_prints_bottom_left_in_the_muted_face() -> void:
    _ensure_autoloads()
    var screen := _mount(MAIN_MENU)
    var v := _find_named(screen, "Version")
    assert_true(v is Label, "the version line is a Label")
    var l := v as Label
    assert_eq(l.text, MainMenuScript.version_line(), "it prints what version_line() says")
    assert_eq(String(l.theme_type_variation), "LabelMuted", "in the muted face (TOWN-12)")
    assert_true(l.position.x < 100.0 and l.position.y > 900.0, "bottom-left: %s" % str(l.position))


func test_version_line_reads_the_project_setting_or_says_it_is_a_dev_build() -> void:
    var had: bool = ProjectSettings.has_setting(VERSION_KEY)
    var was = ProjectSettings.get_setting(VERSION_KEY, "") if had else null
    var current := MainMenuScript.version_line()
    if had and not String(was).is_empty():
        assert_eq(current, "Version %s" % String(was))
    else:
        assert_eq(current, "Development build", "an unset key is not a number nobody set")
    ProjectSettings.set_setting(VERSION_KEY, "9.9.9")
    assert_eq(MainMenuScript.version_line(), "Version 9.9.9")
    ProjectSettings.set_setting(VERSION_KEY, "")
    assert_eq(MainMenuScript.version_line(), "Development build")
    # Put the setting back the way it was found (in memory only; never saved).
    ProjectSettings.set_setting(VERSION_KEY, was if had else null)


# ---------------------------------------------------------------- MainMenu: hover

func test_hover_is_the_lighter_plate_lifted_one_pixel_with_no_layout_shift() -> void:
    _ensure_autoloads()
    var screen := _mount(MAIN_MENU)
    var theme: Theme = Theme_.current(screen)
    var buttons := _buttons(screen)
    assert_true(buttons.size() >= 4, "the stack has its buttons: %d" % buttons.size())
    for b in buttons:
        var btn := b as Button
        var type_name := String(btn.theme_type_variation)
        if type_name.is_empty():
            type_name = "Button"
        assert_true(btn.has_theme_stylebox_override("hover"), "%s carries the lifted hover" % btn.text)
        var base: StyleBox = theme.get_stylebox("hover", type_name)
        var lifted: StyleBox = btn.get_theme_stylebox("hover")
        assert_ne(lifted, base, "the override is a copy, not the theme's box")
        assert_eq(lifted.content_margin_top, base.content_margin_top - 1.0, "the label rises 1px")
        assert_eq(lifted.content_margin_bottom, base.content_margin_bottom + 1.0)
        assert_eq(lifted.expand_margin_top, base.expand_margin_top + 1.0, "the plate rises 1px")
        assert_eq(lifted.expand_margin_bottom, base.expand_margin_bottom - 1.0)
        # docs/13 §12.1: hover never shifts layout — the box's minimum size is the theme's.
        assert_eq(lifted.get_minimum_size(), base.get_minimum_size(), "no layout shift on hover")
        assert_false(btn.has_theme_stylebox_override("focus"), "the focus ring stays the theme's")
    var src := _source("res://game/screens/MainMenu.gd")
    assert_false(src.contains("create_tween"), "no tween on the title (lint_motion's door is Widgets.gd)")
    assert_false(src.contains(".scale ="), "docs/13 §12.3: no scale on hover")


# ------------------------------------------- Continue after a mid-replay quit

## The first enabled Button whose label starts with "Continue" — the label
## carries the guild's name, so the fragment is what can be looked for.
func _continue_button(screen: Node) -> Button:
    for b in _buttons(screen):
        if (b as Button).text.begins_with("Continue"):
            return b as Button
    return null


func test_continue_opens_the_report_a_mid_replay_quit_left_owed() -> void:
    # SHIP-03 / Q-53, through the button rather than through the state: the
    # attempt is committed at Depart, so quitting between the account and the
    # report used to lose the only page that says what happened. Continue now
    # replays the stored attempt and lands on the report.
    #
    # Mounted on the AUTOLOAD router because that is the one MainMenu resolves
    # through `Services`; a privately built router would leave `_load_and_go`
    # navigating a host nothing is mounted in (LESSONS).
    _ensure_autoloads()
    SaveGame.purge_all()
    var st = _root.get_node_or_null("GameState")
    var db = DB.load_all()
    st.set_content(db)
    st.new_game("Interrupted", 4242)
    var enc = db.encounter(A1)
    assert_ne(enc, null, "content has %s" % A1)
    var party: Array = st.roster.slice(0, mini(int(enc.party_size), st.roster.size()))
    var loadout: Dictionary = st.build_loadout(party)
    var lived = st.run_attempt(party, enc, st.next_raid_seed(), loadout)
    st.record_attempt(A1, lived, party, {"loadout": loadout})
    assert_true(st.active_run_pending(), "the report is owed")
    assert_eq(SaveGame.save_slot(0, st), "")
    st.reset()
    st.set_content(db)
    assert_false(st.active, "the quit left nothing in memory")

    var r = _root.get_node_or_null("ScreenRouter")
    r.register_host(_host())
    assert_true(r.goto(MAIN_MENU), "the title must mount")
    # `current_screen()` is untyped, so no `:=` here (LESSONS).
    var screen = r.current_screen()
    var cont := _continue_button(screen)
    assert_ne(cont, null, "the title offers Continue:\n%s" % _joined(screen))
    assert_false(cont.disabled, "with a readable save it is live")
    cont.pressed.emit()

    assert_eq(r.current_path(), RESULTS, "Continue lands on the report, not the town")
    assert_ne(st.last_result, null, "and the report has a fight to print")
    assert_eq(int(st.last_result.outcome), int(lived.outcome), "the same outcome")
    assert_eq(int(st.last_result.rounds), int(lived.rounds), "in the same rounds")
    assert_eq(int(st.last_result.mistake_count), int(lived.mistake_count),
        "with the same mistakes — the seed came back whole")
    SaveGame.purge_all()


func test_continue_opens_the_town_when_no_report_is_owed() -> void:
    # The other branch: a report already read is not a pending one, and the
    # ordinary Continue must not be re-routed by the new rule.
    _ensure_autoloads()
    SaveGame.purge_all()
    var st = _root.get_node_or_null("GameState")
    var db = DB.load_all()
    st.set_content(db)
    st.new_game("Settled", 4242)
    var enc = db.encounter(A1)
    var party: Array = st.roster.slice(0, mini(int(enc.party_size), st.roster.size()))
    var loadout: Dictionary = st.build_loadout(party)
    st.record_attempt(A1, st.run_attempt(party, enc, st.next_raid_seed(), loadout),
        party, {"loadout": loadout})
    st.dismiss_active_run()
    assert_false(st.active_run_pending())
    assert_eq(SaveGame.save_slot(0, st), "")
    st.reset()
    st.set_content(db)

    var r = _root.get_node_or_null("ScreenRouter")
    r.register_host(_host())
    assert_true(r.goto(MAIN_MENU))
    var cont := _continue_button(r.current_screen())
    assert_ne(cont, null)
    cont.pressed.emit()
    assert_eq(r.current_path(), TOWN, "a settled guild carries on into the town")
    SaveGame.purge_all()


# ---------------------------------------------------------------- Completion

func _finished_guild_with_content():
    var st = _root.get_node_or_null("GameState")
    st.set_content(DB.load_all())
    st.new_game("Ashfall Company")
    st.day = 91
    st.completed = true
    st.completed_on_day = 91
    st.completion_seen = false
    return st


func test_the_credits_roll_names_the_guild_above_the_files_lines() -> void:
    _ensure_autoloads()
    var st = _finished_guild_with_content()
    assert_true((st.roster as Array).size() >= 12, "the starting twelve are on the books")
    var screen := _mount(COMPLETION)
    var roll := _find_named(screen, "Roll")
    assert_true(roll is GridContainer, "the roster roll is a grid")
    assert_eq((roll as GridContainer).columns, CompletionScript.ROLL_COLUMNS, "two to a row")
    assert_eq(roll.get_child_count(), (st.roster as Array).size(), "one credit per raider")
    var printed := _joined(screen)
    for r in st.roster:
        assert_true(printed.contains(String(r.display_name)), "%s is credited" % String(r.display_name))
        assert_true(printed.contains(Enums.class_name_of(r.class_id)), "with the class word")
    # A 48px portrait beside each name.
    var first := roll.get_child(0)
    var slot: Control = null
    for c in first.get_children():
        if c is PanelContainer:
            slot = c
    assert_ne(slot, null, "a portrait tile leads the row")
    assert_eq(slot.custom_minimum_size, Vector2(CompletionScript.PORTRAIT, CompletionScript.PORTRAIT))
    # The file's lines come after the roll, verbatim — and while the roll is
    # unsigned the status paragraph is NOT printed (LOOP-27 / C8): the ending
    # shows the guild and says nothing about the state of its credits.
    var lines: Array = CompletionScript.credit_lines()
    var texts := _texts(screen)
    var roll_index: int = texts.find(String(st.roster[0].display_name))
    for line in lines:
        if String(line).is_empty():
            continue
        var at: int = texts.find(String(line))
        assert_true(at >= 0, "the file's line is printed verbatim: %s" % String(line))
        assert_true(at > roll_index, "and after the roster roll")
    assert_false(printed.to_lower().contains("not written yet"),
        "the status is for the person who signs the roll, never the player")
    # The one exit, its text verbatim, still routes home.
    var back := _find_button(screen, CTA_TEXT)
    assert_ne(back, null, "the commit keeps its text verbatim (test_screens.gd:547)")


func test_an_empty_roster_says_so_instead_of_an_empty_roll() -> void:
    _ensure_autoloads()
    var st = _root.get_node_or_null("GameState")
    st.new_game("Ashfall Company")      # contentless: no roster
    st.completed = true
    var screen := _mount(COMPLETION)
    assert_eq(_find_named(screen, "Roll"), null, "no grid for nobody")
    assert_true(_joined(screen).contains("Nobody on the books."), "the empty state is said")


func test_the_cta_is_inset_and_wraps_inside_its_plate() -> void:
    _ensure_autoloads()
    _finished_guild_with_content()
    var screen := _mount(COMPLETION)
    var back := _find_button(screen, CTA_TEXT)
    assert_ne(back, null)
    # KIT-05's guard is consumed, not overridden: the width the guard chose stays.
    assert_eq(back.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "the label wraps inside the plate")
    assert_eq(back.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
    assert_true(back.custom_minimum_size.x > 0.0, "the guard's width is not zeroed by the screen")
    assert_true(back.custom_minimum_size.x <= CompletionScript.SIDEBAR_W, "and fits the column")
    # The plate's side margins are the screen's inset on every state box.
    for slot in ["normal", "hover", "pressed", "disabled"]:
        assert_true(back.has_theme_stylebox_override(slot), "%s is the inset copy" % slot)
        var box: StyleBox = back.get_theme_stylebox(slot)
        assert_eq(box.content_margin_left, float(CompletionScript.CTA_SIDE_INSET))
        assert_eq(box.content_margin_right, float(CompletionScript.CTA_SIDE_INSET))
    assert_true(CompletionScript.CTA_SIDE_INSET >= 12, "TOWN-13: >= 12px inside each rim")
    assert_false(back.has_theme_stylebox_override("focus"), "the focus ring stays the theme's")
    # The column is the sidebar's true width: nothing overflows the pad.
    assert_eq(CompletionScript.SIDEBAR_W, Frame.SIDEBAR_W - 2 * 14 - 2 * 18)


func test_the_band_sits_at_the_bottom_and_the_guild_stands_in_the_open() -> void:
    _ensure_autoloads()
    _finished_guild_with_content()
    var screen := _mount(COMPLETION)
    var host := _find_named(screen, "SceneHost") as Control
    assert_ne(host, null)
    var stages := _stages(screen)
    assert_eq(stages.size(), 1, "one camp stage")
    var stage := stages[0] as Control
    assert_eq(String(stage.name), "SceneStage_stage_camp", "the camp, where the guild goes back to")
    # The report band: across the bottom of the scene host (TOWN-13's alternative).
    var band: Control = null
    for c in host.get_children():
        if c is PanelContainer and String(c.theme_type_variation) == "PanelWarm":
            band = c
    assert_ne(band, null, "the report band is a PanelWarm in the scene host")
    var band_top: float = host.size.y - CompletionScript.PANEL_INSET.y - CompletionScript.PANEL_H
    assert_eq(band.position.y, band_top, "the band's top")
    assert_eq(band.size.y, float(CompletionScript.PANEL_H))
    assert_true(band_top > host.size.y * 0.5, "the band is in the lower half: %d of %d" % [int(band_top), int(host.size.y)])
    # Four or more figures stand in the open above the band, inside the host.
    var in_open := 0
    for c in stage.get_children():
        if String(c.name).begins_with("Actor_") and c is Node2D:
            var p: Vector2 = (c as Node2D).position + stage.position
            if p.y < band_top and p.x >= 0.0 and p.x <= host.size.x:
                in_open += 1
    assert_true(in_open >= 4, "TOWN-13: four+ actors in the open camp, got %d" % in_open)


# ---------------------------------------------------------------- Boot

func test_the_boot_card_is_the_kits_panel_with_the_lockup_and_a_status_label() -> void:
    _ensure_autoloads()
    var boot = BootScript.new()
    _made.append(boot)
    boot.call("_build_overlay")
    var overlay := _find_named(boot, "BootOverlay")
    assert_ne(overlay, null, "the overlay exists")
    var panel: PanelContainer = null
    var walk: Array = [overlay]
    while not walk.is_empty():
        var n: Node = walk.pop_front()
        if n is PanelContainer and panel == null:
            panel = n
        for c in n.get_children():
            walk.append(c)
    assert_ne(panel, null, "the card is a panel")
    assert_eq(String(panel.theme_type_variation), "PanelWarm", "on the kit's warm panel (06 §1)")
    assert_true(Theme_.current(boot).has_icon("corner_ornament", "PanelWarm"),
        "KIT-09's ornament slot is registered for it (Widgets.panel overlays it — W3-KIT2)")
    assert_ne(_find_named(overlay, "wordmark_58"), null, "the same lockup the header uses")
    assert_ne(_find_named(overlay, "wordmark_tagline"), null)
    assert_true(_joined(overlay).contains("Reading the guild's paperwork"), "the status line is a Label")


func test_the_failure_card_widens_with_the_text_scale() -> void:
    _ensure_autoloads()
    var boot = BootScript.new()
    _made.append(boot)
    boot.call("_build_overlay")
    boot.call("_show_failure", "The guild's records do not add up", ["one", "two"])
    var overlay := _find_named(boot, "BootOverlay")
    var printed := _joined(overlay)
    assert_true(printed.contains("The guild's records do not add up"), "the headline is a Label")
    assert_true(printed.contains("2 problem(s):"))
    assert_true(printed.contains("one") and printed.contains("two"), "each problem its own Label")
    var pct: int = Theme_.scale_of(boot)
    var want: float = float(Type.at(BootScript.FAILURE_TEXT_W, pct))
    var wrapped := 0
    var walk: Array = [overlay]
    while not walk.is_empty():
        var n: Node = walk.pop_front()
        if n is Label and (n as Label).autowrap_mode == TextServer.AUTOWRAP_WORD_SMART:
            assert_eq((n as Label).custom_minimum_size.x, want, "a wrapped line's width goes through Type.at")
            wrapped += 1
        for c in n.get_children():
            walk.append(c)
    assert_true(wrapped >= 3, "the explanation and both problems wrap: %d" % wrapped)
    assert_ne(_find_button(overlay, "Quit"), null, "Quit stays a Button")


func test_display_aspect_is_applied_before_the_overlay_is_shown() -> void:
    # CRITIC-G02: read as source order — Boot's `_ready` cannot run under the
    # harness (nothing is inside the tree) and `_boot()` would route the autoload.
    var src := _source("res://game/ui/Boot.gd")
    var ready_at: int = src.find("func _ready() -> void:")
    assert_true(ready_at >= 0)
    var body := src.substr(ready_at, src.find("\nfunc ", ready_at + 1) - ready_at)
    var aspect_at: int = body.find("_apply_display_aspect()")
    var overlay_at: int = body.find("_build_overlay()")
    assert_true(aspect_at >= 0 and overlay_at >= 0, "both calls live in _ready")
    assert_true(aspect_at < overlay_at, "the aspect is applied before the overlay is built")
    var boot_at: int = src.find("func _boot() -> void:")
    var boot_body := src.substr(boot_at, src.find("\nfunc ", boot_at + 1) - boot_at)
    assert_false(boot_body.contains("apply_display_aspect("), "and no longer a frame later in _boot()")
    assert_true(src.contains("static func apply_display_aspect(window: Window, aspect: String)") \
        or _source("res://game/core/GameSettings.gd").contains("static func apply_display_aspect(window: Window, aspect: String)"),
        "the door is GameSettings.apply_display_aspect")
