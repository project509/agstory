extends "res://tests/TestCase.gd"
## W2-TAVERN — the Tavern's layout contracts (build/plan/artaudit/00-plan.md §3;
## findings TOWN-17, TOWN-18, TOWN-19, CRITIC-G05, KIT-10, TOWN-31, KIT-03).
##
## Nothing here runs a frame (the runner is a SceneTree script: no layout pass,
## no `_ready`), so every size assertion is on MINIMUM sizes — which is what a
## layout pass would clamp the real sizes up to. The one exception is the
## sidebar panel's `size.y`, which Frame.sidebar sets explicitly and which the
## plan's acceptance names.

const Enums = preload("res://sim/model/Enums.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const TavernView = preload("res://game/screens/Tavern.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Type = preload("res://game/ui/Type.gd")
const Recruitment = preload("res://sim/core/Recruitment.gd")

var _db = null
var _mounted: Array = []
var _borrowed = null
var _borrowed_content = null
var _scale_before := -1


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _mounted = []


func after_each() -> void:
    if _scale_before >= 0:
        var gs = _root().get_node_or_null("GameSettings")
        if gs != null:
            gs.set_value("text_scale", _scale_before)
        _scale_before = -1
    if _borrowed != null and is_instance_valid(_borrowed):
        _borrowed.reset()
        _borrowed.content = _borrowed_content
        _borrowed = null
        _borrowed_content = null
    for n in _mounted:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _mounted = []


func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


## The same borrow-the-autoload pattern test_tavern.gd uses (LESSONS: the
## autoloads outlive a test file, so what is changed is put back in after_each).
func _live_state(guild: String, gold: int = 5000):
    var root := _root()
    var st = root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        root.add_child(st)
        _mounted.append(st)
    else:
        _borrowed = st
        _borrowed_content = st.content
    if root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        root.add_child(rt)
        _mounted.append(rt)
    if root.get_node_or_null("GameSettings") == null:
        var gs = SettingsScript.new()
        gs.name = "GameSettings"
        root.add_child(gs)
        _mounted.append(gs)
    st.reset()
    st.set_content(_db)
    st.new_game(guild)
    st.gold = gold
    # The screen rolls the first board on entry; a test that reads a candidate
    # BEFORE mounting needs it rolled here (as test_a11y_legibility does).
    if st.tavern_board.is_empty():
        st.refresh_board()
    return st


func _tavern() -> Control:
    var view := TavernView.new()
    _root().add_child(view)
    _mounted.append(view)
    view.build()
    return view


func _find(n: Node, name: String):
    if n.name == name:
        return n
    for c in n.get_children():
        var found = _find(c, name)
        if found != null:
            return found
    return null


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _labels(c, out)
    return out


func _printed(n: Node) -> String:
    return "\n".join(PackedStringArray(_labels(n)))


func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out


func _button_named(n: Node, fragment: String):
    for b in _buttons(n):
        if (b as Button).text.contains(fragment):
            return b
    return null


## Give every wrapped Label in `n` the width it will have on screen, so its
## minimum HEIGHT is the wrapped height and not the one-word-per-line height a
## zero-width Label reports before its first layout pass.
func _settle_wraps(n: Node, fallback_w: float) -> void:
    if n is Label and (n as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
        var l := n as Label
        var w: float = maxf(l.custom_minimum_size.x, fallback_w)
        l.size = Vector2(w, 0)
    for c in n.get_children():
        _settle_wraps(c, fallback_w)


## The height the sidebar's content may take: the host minus the Pad's margins
## and the panel stylebox's own content margins (LESSONS: PanelWarm adds 14px
## under the Pad's 18).
func _sidebar_inner_h(view: Control) -> float:
    var host = _find(view, "SidebarHost")
    var panel = _find(view, "Sidebar")
    var pad = Widgets.content_of(panel)
    var margins: float = pad.get_theme_constant("margin_top") + pad.get_theme_constant("margin_bottom")
    var sb: StyleBox = panel.get_theme_stylebox("panel")
    var chrome: float = sb.get_minimum_size().y if sb != null else 0.0
    return host.size.y - margins - chrome


# ================================================================ TOWN-17

func test_the_sidebar_panel_never_outgrows_its_host() -> void:
    _live_state("Fit Guild")
    var view := _tavern()
    var host = _find(view, "SidebarHost")
    var panel = _find(view, "Sidebar")
    assert_ne(host, null, "Frame builds a SidebarHost")
    assert_ne(panel, null, "Frame.sidebar builds the Sidebar panel")
    assert_true(panel.size.y <= host.size.y,
        "the panel (%.0f) must end where its host ends (%.0f) — TOWN-17 had it at 765 over a 635 host"
            % [panel.size.y, host.size.y])
    assert_true(panel.get_combined_minimum_size().y <= host.size.y,
        "and its MINIMUM (%.0f) must not exceed the host (%.0f), or the next layout pass grows it"
            % [panel.get_combined_minimum_size().y, host.size.y])
    var scroll = _find(view, "SidebarScroll")
    assert_ne(scroll, null, "the screen (not Frame) wraps the column in a ScrollContainer")
    assert_true(scroll is ScrollContainer)
    assert_eq(scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
    assert_ne(scroll.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)


func test_the_panel_stays_bounded_on_the_manage_tab_and_an_empty_board() -> void:
    var st = _live_state("Fit Guild")
    var view := _tavern()
    var host = _find(view, "SidebarHost")
    _button_named(view, "Manage").pressed.emit()
    var panel = _find(view, "Sidebar")
    assert_true(panel.get_combined_minimum_size().y <= host.size.y, "Manage tab")
    _button_named(view, "Board").pressed.emit()
    st.tavern_board = []
    view._refresh()
    panel = _find(view, "Sidebar")
    assert_true(panel.get_combined_minimum_size().y <= host.size.y, "empty board")
    assert_true(_printed(view).contains("Nobody is drinking."))


func test_a_common_candidate_fits_the_sidebar_without_scrolling() -> void:
    # The plan's bar: "the sidebar column fits 635px after the move" — for the
    # common case, three bullets at text scale 100, the bar must not be needed.
    var st = _live_state("Fit Guild")
    # The runner leaves GameSettings at the last test's values (LESSONS), so the
    # scale this measures at is pinned, and put back in after_each.
    var gs = _root().get_node_or_null("GameSettings")
    _scale_before = int(gs.get_value("text_scale"))
    gs.set_value("text_scale", 100)
    var who = st.tavern_board[0]
    var src: Array = who.backstory.duplicate(true)
    var padded: Array = []
    for i in 3:
        padded.append((src[i % src.size()] as Dictionary).duplicate(true))
    who.backstory = padded
    var view := _tavern()
    var col = _find(view, "SidebarCol")
    assert_ne(col, null)
    _settle_wraps(col, 330.0)
    var need: float = col.get_combined_minimum_size().y
    var room: float = _sidebar_inner_h(view)
    assert_true(need <= room,
        "three bullets want %.0fpx of the sidebar's %.0f — the column must fit without a bar"
            % [need, room])
    who.backstory = src


func test_a_four_bullet_legendary_scrolls_inside_the_rim_instead_of_growing() -> void:
    var st = _live_state("Fit Guild")
    var who = st.tavern_board[0]
    var src: Array = who.backstory.duplicate(true)
    var rarity_before: int = who.rarity
    var padded: Array = []
    for i in 4:
        padded.append((src[i % src.size()] as Dictionary).duplicate(true))
    who.backstory = padded
    who.rarity = Enums.Rarity.LEGENDARY
    var view := _tavern()
    var host = _find(view, "SidebarHost")
    var panel = _find(view, "Sidebar")
    assert_true(panel.get_combined_minimum_size().y <= host.size.y,
        "four bullets and a stamp: the panel's minimum (%.0f) still inside the host (%.0f)"
            % [panel.get_combined_minimum_size().y, host.size.y])
    var printed := _printed(view)
    for b in padded:
        assert_true(printed.contains(String(b["text"])), "every bullet is still printed")
    who.backstory = src
    who.rarity = rarity_before


# ================================================================ TOWN-18 / KIT-10

func test_the_candidate_card_carries_three_gear_slots_and_a_rarity_rim() -> void:
    var st = _live_state("Gear Guild")
    var view := _tavern()
    var who = st.tavern_board[0]
    # Card 1 is selected on entry; card at index 1 is not.
    var plain: Control = view._candidate_card(who, 1)
    view.add_child(plain)
    _mounted.append(plain)
    var gear = _find(plain, "Gear")
    assert_ne(gear, null, "the card has a slot row named Gear")
    assert_eq(gear.get_child_count(), 3, "three arriving-gear slots, padded with empties")
    var worn: int = who.equipped_items(st.content).size()
    var filled := 0
    for cell in gear.get_children():
        if cell.get_child_count() > 0:
            filled += 1
    assert_eq(filled, mini(3, worn), "one filled cell per worn item")
    var sb: StyleBox = plain.get_theme_stylebox("panel")
    assert_true(sb is StyleBoxFlat, "the rim is a flat box the screen recoloured")
    assert_eq((sb as StyleBoxFlat).border_color, Palette.rarity_color(who.rarity),
        "the rim takes the rarity colour")
    assert_eq((sb as StyleBoxFlat).border_width_top, 2, "2px (06 §2's rarity-bordered variant)")
    var selected: Control = view._candidate_card(who, 0)
    view.add_child(selected)
    _mounted.append(selected)
    assert_eq(selected.theme_type_variation, "PanelRoundSelected",
        "the selected card wears the kit's selection rim (KIT-10), not a hand-rolled one")
    var morale = _find(selected, "Morale")
    assert_ne(morale, null)
    assert_eq(morale.get_child_count(), 2, "canon's two-line morale row")
    assert_true(String(morale.get_child(0).text).begins_with("starts at %d" % int(who.morale)))
    assert_eq(String(morale.get_child(1).text), Enums.morale_band_name(int(who.morale)),
        "the band word is the row's second line")
    assert_true(plain.get_combined_minimum_size().y <= float(Widgets.CARD_SIZE.y),
        "the gear row did not push the card past its 262 (%.0f)" % plain.get_combined_minimum_size().y)


func test_a_legendary_card_holds_its_box_at_text_scale_150() -> void:
    var st = _live_state("Big Guild")
    var gs = _root().get_node_or_null("GameSettings")
    _scale_before = int(gs.get_value("text_scale"))
    gs.set_value("text_scale", 150)
    var who = st.tavern_board[0]
    var src: Array = who.backstory.duplicate(true)
    var rarity_before: int = who.rarity
    var padded: Array = []
    for i in 4:
        padded.append((src[i % src.size()] as Dictionary).duplicate(true))
    who.backstory = padded
    who.rarity = Enums.Rarity.LEGENDARY
    var view := _tavern()
    for idx in [0, 1]:
        var card: Control = view._candidate_card(who, idx)
        view.add_child(card)
        _mounted.append(card)
        assert_true(card.get_combined_minimum_size().y <= float(Widgets.CARD_SIZE.y),
            "at 150%% a stamped Legendary card (index %d) wants %.0f of %d"
                % [idx, card.get_combined_minimum_size().y, Widgets.CARD_SIZE.y])
    who.backstory = src
    who.rarity = rarity_before


# ================================================================ TOWN-19

func test_the_caption_plate_carries_the_tabs_the_house_facts_and_the_reroll() -> void:
    var st = _live_state("Plate Guild")
    var view := _tavern()
    var plate = _find(_find(view, "SceneHost"), "Caption")
    assert_ne(plate, null, "one caption plate on the scene")
    assert_eq(plate.theme_type_variation, "PanelCallout", "in the callout chrome")
    for text in ["Board", "Manage", "Ask around again", "Take the room next door"]:
        var b = _button_named(plate, text)
        assert_ne(b, null, "'%s' is a Button on the plate" % text)
    var sidebar = _find(view, "Sidebar")
    assert_eq(_button_named(sidebar, "Ask around again"), null, "the reroll left the sidebar")
    assert_eq(_button_named(sidebar, "Take the room next door"), null, "so did the upgrade")
    var on_plate := _printed(plate)
    assert_true(on_plate.contains("house %d of" % st.tavern_tier), "the house line: %s" % on_plate)
    assert_true(on_plate.contains("At %s" % st.rank_name()), "the rank's rarity floor: %s" % on_plate)
    assert_true(on_plate.contains("Legendaries 0 of %d" % Enums.CLASS_KEYS.size()),
        "the collection meter lives with the house facts")
    assert_true(on_plate.contains("Free after any run"), "the reroll rule")
    # The notice is on the plate, and only shows when there is one.
    var notice = _find(plate, "Notice")
    assert_ne(notice, null)
    assert_false(notice.visible, "no notice yet")
    _button_named(view, "Not tonight").pressed.emit()
    notice = _find(_find(view, "SceneHost"), "Notice")
    assert_true(notice.visible and notice.text.contains("back to the bar"), notice.text)


func test_the_strip_carries_recent_events_and_the_hire_footer() -> void:
    var st = _live_state("Strip Guild", 12480)
    var view := _tavern()
    var strip = _find(view, "StripHost")
    assert_ne(strip, null)
    assert_true(_printed(strip).contains("Recent Events"), "Cards.event_log on the strip")
    var foot = _find(strip, "Footer")
    assert_ne(foot, null, "the hire footer under the cards")
    var who = st.tavern_board[0]
    var price := Recruitment.cost_of(who.rarity, st.highest_unlocked_tier())
    var want := "Roster %d of %d  ·  Hiring %s leaves %s" % [
        st.roster.size(), st.roster_cap(), who.display_name, Type.gold(st.gold - price)]
    assert_eq(foot.text, want, "docs/13 §9.4's footer, thousands separated")
    assert_true(foot.position.y >= Widgets.STRIP_H, "under the cards, in the strip's lower band")
    assert_true(foot.position.x + foot.size.x < 1015.0, "and clear of the pager's caption")
    # Manage keeps the board and the log on the strip.
    _button_named(view, "Manage").pressed.emit()
    strip = _find(view, "StripHost")
    assert_true(_printed(strip).contains("Recent Events"))
    assert_ne(_button_named(strip, "Look"), null, "the board stays on the strip on Manage")


# ================================================================ CRITIC-G05 / CRITIC-G04

func test_the_dismiss_confirm_is_the_kits_pair_with_the_texts_unchanged() -> void:
    var st = _live_state("Manage Guild")
    var view := _tavern()
    _button_named(view, "Manage").pressed.emit()
    var before: int = st.roster.size()
    _button_named(view, "Dismiss").pressed.emit()
    var confirm = _find(view, "Confirm")
    assert_ne(confirm, null, "Widgets.confirm_pair's plate")
    var yes = _find(confirm, "Yes")
    var no = _find(confirm, "No")
    assert_true(yes is Button and no is Button, "both halves are Buttons the walker reads")
    assert_eq(yes.text, "Yes — let them go (-2 morale to everyone else)")
    assert_eq(no.text, "Keep them")
    assert_eq(Widgets.default_focus_of(confirm), no, "the safe half is the default focus")
    assert_eq(st.roster.size(), before, "asking is not doing")
    no.pressed.emit()
    assert_eq(_find(view, "Confirm"), null, "Keep them closes the pair")
    assert_eq(st.roster.size(), before)


func test_look_from_the_manage_tab_returns_to_the_board() -> void:
    _live_state("Look Guild")
    var view := _tavern()
    _button_named(view, "Manage").pressed.emit()
    assert_eq(view.active_tab(), "manage")
    var look = _button_named(_find(view, "StripHost"), "Look")
    assert_ne(look, null)
    look.pressed.emit()
    assert_eq(view.active_tab(), "board", "Look shows the candidate, which is the Board tab")
    assert_true(_printed(view).contains("Hire — "))


# ================================================================ TOWN-31 / KIT-03

func test_back_to_town_is_a_quiet_button_and_the_chip_builder_is_gone() -> void:
    _live_state("Quiet Guild")
    var view := _tavern()
    var back = _button_named(view, "Back to town")
    assert_ne(back, null, "still a Button (CRITIC-C14), never a LinkButton")
    assert_eq(back.theme_type_variation, "ButtonQuiet")
    assert_false(view.has_method("_chips"), "KIT-03: the dead private chip builder is deleted")
    var src: String = FileAccess.get_file_as_string("res://game/screens/Tavern.gd")
    assert_true(src.contains("Frame.standard_chips("), "the chips come from Frame")
    assert_true(src.contains("Frame.refresh_chips("), "and are refreshed after a hire")
