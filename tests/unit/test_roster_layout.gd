extends "res://tests/TestCase.gd"
## W3-ROSTER — the Guildhall's layout contracts (build/plan/artaudit/00-plan.md §4;
## findings HALL-03/KIT-06/CRITIC-C15, HALL-04, HALL-09, HALL-10, HALL-11, HALL-12,
## HALL-13, HALL-14, HALL-20, HALL-22, KIT-08).
##
## Nothing here runs a frame (the runner is a SceneTree script: no layout pass,
## no `_ready`), so every geometry assertion is on what the screens SET
## explicitly (cell positions and sizes, the strip's entries) or on MINIMUM
## sizes, which a layout pass clamps the real sizes up to. The tests read the
## screens the way every other screen test does: Label.text and Button.text,
## Buttons by exact text, nodes by name.

const Enums = preload("res://sim/model/Enums.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const GuildhallScript = preload("res://game/screens/Guildhall.gd")
const RosterView = preload("res://game/screens/Roster.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Morale = preload("res://sim/core/Morale.gd")
const RaiderScript = preload("res://sim/model/Raider.gd")

const GUILDHALL := "res://game/screens/Guildhall.tscn"
## The content panel's inner width (PanelWarm's 14px margins off 916).
const PANEL_INNER_W := 888
## What the second row's bottom edge and the third row's top need of the grid.
const TWO_ROWS_AND_A_TOP := 2 * 270 + 1

var _db = null
var _mounted: Array = []
var _borrowed = null
var _borrowed_content = null


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _mounted = []


func after_each() -> void:
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


## The borrow-the-autoload pattern (LESSONS: the autoloads outlive a test file,
## so what is changed is put back in after_each).
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
    return st


## The roster view on its own, the way test_raider_detail mounts it.
func _roster() -> Control:
    var view := RosterView.new()
    _root().add_child(view)
    _mounted.append(view)
    view.build()
    return view


## The whole Guildhall through a private router's host, the way
## test_starting_roster mounts it (the screen itself still finds the autoload
## router through Services for `screen_exists`).
func _guildhall() -> Control:
    var host := Control.new()
    host.name = "RosterLayoutHost"
    _root().add_child(host)
    _mounted.append(host)
    var r = Router.new()
    _mounted.append(r)
    r.register_host(host)
    assert_true(r.goto(GUILDHALL), "the Guildhall must open")
    return r.current_screen()


func _find(n: Node, name: String):
    if n.name == name:
        return n
    for c in n.get_children():
        var found = _find(c, name)
        if found != null:
            return found
    return null


func _find_all(n: Node, prefix: String, out: Array = []) -> Array:
    if String(n.name).begins_with(prefix):
        out.append(n)
    for c in n.get_children():
        _find_all(c, prefix, out)
    return out


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _labels(c, out)
    return out


func _joined(n: Node) -> String:
    return "\n".join(PackedStringArray(_labels(n)))


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


func _cells(view: Control) -> Array:
    var grid = _find(view, "Grid")
    assert_true(grid != null, "the roster grid is named Grid")
    var out: Array = []
    for c in grid.get_children():
        if String(c.name).begins_with("Cell_"):
            out.append(c)
    return out


# ------------------------------------------------ HALL-03 / KIT-06 / CRITIC-C15

func test_both_actions_live_inside_the_card_and_a_row_is_one_card_tall() -> void:
    var st = _live_state("Inside Test")
    var view := _roster()
    var cells := _cells(view)
    assert_eq(cells.size(), st.roster.size(), "one cell per raider")
    for cell in cells:
        var card = _find(cell, "Card")
        assert_true(card != null, "every cell holds a Card")
        assert_eq(cell.size, Vector2(RosterView.CELL_W, view.row_height()),
            "the cell IS the card — nothing hangs under it")
        assert_eq(card.size, cell.size, "and the card fills its cell")
        assert_eq(card.position, Vector2.ZERO)
        var cheer = _button_named(cell, "Cheer up")
        var manage = _button_named(cell, "Manage")
        assert_true(cheer != null and manage != null, "both actions on every card")
        assert_true(card.is_ancestor_of(cheer) and card.is_ancestor_of(manage),
            "the actions are the card's own band, inside its rim")
        # The only things a cell holds are the card and, at risk, its stamp.
        for c in cell.get_children():
            assert_true(String(c.name) in ["Card", "Stamp"], "stray child in a cell: %s" % c.name)
    assert_eq(RosterView.ROW_PITCH, 270, "262 + the reference's 8px gap")
    assert_eq(RosterView.CELL_H, Widgets.CARD_SIZE.y)
    assert_true(view.row_height() >= Widgets.CARD_SIZE.y, "a row is never shorter than the card")


func test_cells_sit_at_the_grid_pitch_and_the_grid_declares_its_height() -> void:
    var st = _live_state("Pitch Test")
    var view := _roster()
    var cells := _cells(view)
    var pitch: int = view.row_height() + RosterView.ROW_GAP
    for i in cells.size():
        @warning_ignore("integer_division")
        var want := Vector2((i % RosterView.COLUMNS) * RosterView.COL_PITCH,
            (i / RosterView.COLUMNS) * pitch)
        assert_eq(cells[i].position, want, "cell %d" % i)
    @warning_ignore("integer_division")
    var lines: int = (st.roster.size() + RosterView.COLUMNS - 1) / RosterView.COLUMNS
    var grid = _find(view, "Grid")
    assert_eq(grid.custom_minimum_size.y, float(lines * pitch - RosterView.ROW_GAP),
        "the grid's minimum is its rows, so the scroll container knows there is more")
    assert_true(grid.custom_minimum_size.x <= PANEL_INNER_W,
        "four cards at the reference pitch fit the panel's inner width")


func test_the_panel_leaves_room_for_two_full_rows_and_the_top_of_a_third() -> void:
    # HALL-03's acceptance, as arithmetic: the panel's inner height less the
    # tab row's minimum (with both shut tabs' captions) and the column gap
    # must be at least two row pitches plus one pixel of the third row.
    _live_state("Rows Test")
    var hall := _guildhall()
    var row = _find(hall, "TabRow")
    assert_true(row != null, "the panel's title bar is the kit's tab row")
    # No layout pass runs here, and an autowrapped Label's pre-layout minimum
    # is its text wrapped at width 0 (one word per line) — so the row's height
    # is summed from what the screen SETS: the tab, the underline, ONE caption
    # line (each caption is asserted to fit its cell on one line at 100%), the
    # rule. The shot is the measurement of the same number (48 with the gap).
    var tabs: Array = Widgets.tabs_of(row)
    var caption_h := 0.0
    for b in tabs:
        var tab: Button = b
        assert_eq(tab.custom_minimum_size, GuildhallScript.TAB_SIZE, "%s is TAB_SIZE" % tab.text)
        var why: Label = (tab.get_parent() as Control).get_node_or_null("Reason") as Label
        if why == null:
            continue
        # The screen's own lookup (the variation's font, the unscaled size).
        var f: Font = why.get_theme_font("font", "LabelSmall")
        var px: int = GuildhallScript.TAB_CAPTION_SIZE
        assert_eq(why.get_theme_font_size("font_size"), px, "the caption is the 11px step at 100%")
        var one_line: float = f.get_string_size(why.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
        assert_true(why.custom_minimum_size.x >= one_line,
            "%s's caption fits its cell on one line (%.0f in %.0f)" % [tab.text, one_line, why.custom_minimum_size.x])
        caption_h = maxf(caption_h, f.get_height(px) + float(why.get_theme_constant("line_spacing")))
    assert_true(caption_h > 0.0, "the two shut tabs carry captions")
    # The underline (active cell) and the caption (a shut cell) are in
    # different cells: the row is as tall as its tallest cell, plus the rule.
    var tab_h: float = GuildhallScript.TAB_SIZE.y + maxf(2.0, caption_h) + 1.0
    var inner_h: float = GuildhallScript.PANEL_SIZE.y - 28.0
    var grid_h: float = inner_h - tab_h - 6.0
    assert_true(grid_h >= float(TWO_ROWS_AND_A_TOP),
        "grid %.0f < %d: the tab row (%.0f) eats the second row" % [grid_h, TWO_ROWS_AND_A_TOP, tab_h])
    # And a card with its band — a disabled Cheer up and its reason included —
    # asks for no more than the 262 it is given, so nothing hangs under the rim.
    var view = _find(hall, "RosterView")
    assert_true(view != null)
    assert_eq(view.row_height(), Widgets.CARD_SIZE.y, "at 100% text a row is exactly one card")
    var cells := _cells(view)
    assert_true(cells.size() >= 12, "the starting roster fills three rows")
    for cell in cells:
        var card: Control = _find(cell, "Card")
        var want: Vector2 = card.get_combined_minimum_size()
        assert_true(want.y <= float(Widgets.CARD_SIZE.y),
            "%s asks for %.0f of the card's %d" % [cell.name, want.y, Widgets.CARD_SIZE.y])
        assert_true(want.x <= float(Widgets.CARD_SIZE.x))


# ------------------------------------------------ LOOP-16

func test_a_45_morale_raider_can_be_cheered_up_with_gold_in_hand() -> void:
    # "They are fine." at 45 — the exact morale a Common settles at, and the
    # morale at which the campaign cannot be cleared — while the Market sold
    # the same Hot Bath Token to the same raider with no such gate. The quick-
    # apply gates on what the Market gates on: the price and the day's cap.
    var st = _live_state("Cheer Test", 500)
    for r in st.roster:
        Morale.set_morale(r, 45.0)
    var view := _roster()
    var cheer = _button_named(view, "Cheer up")
    assert_true(cheer != null, "the quick-apply is on the row")
    assert_false(cheer.disabled, "and live at 45 with 500 G")
    assert_false(_joined(view).contains("They are fine"), _joined(view))
    var who = st.roster[0]
    var cell = _find(view, "Cell_%s" % String(who.id).validate_node_name())
    assert_true(cell != null, "the first raider's cell")
    var mine = _button_named(cell, "Cheer up")
    var before: float = Morale.morale_exact(who)
    mine.pressed.emit()
    assert_true(Morale.morale_exact(who) > before, "one click, and it lands")
    assert_eq(st.gold, 480, "20 G for a Hot Bath Token")
    # A bath that would not land (docs/05 §7.4's cooldown) is refused by the
    # game's own sentence on the press, never by a morale band: the button on
    # a rebuilt view stays live, and the refusal is a Label.
    var again := _roster()
    var cell2 = _find(again, "Cell_%s" % String(who.id).validate_node_name())
    var second = _button_named(cell2, "Cheer up")
    assert_false(second.disabled, "the button stays live; the refusal is the sentence")
    second.pressed.emit()
    assert_eq(st.gold, 480, "nothing was charged for a bath that did not land")
    assert_true(_joined(again).contains("had one recently"), _joined(again))


# ------------------------------------------------ HALL-14

func test_the_grid_scrolls_in_a_container_whose_bar_sits_in_the_margin() -> void:
    _live_state("Scroll Test")
    var hall := _guildhall()
    var scroll = _find(hall, "RosterScroll")
    assert_true(scroll is ScrollContainer, "the grid scrolls")
    assert_eq(scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
    assert_true(scroll.follow_focus, "keyboard focus scrolls the grid")
    assert_eq(scroll.offset_right, float(RosterView.SCROLLBAR_W),
        "the host is widened by the bar so the fourth card keeps its rim")
    assert_true(scroll.get_v_scroll_bar() != null)


# ------------------------------------------------ HALL-10 / HALL-11

func test_the_tabs_are_the_kits_row_with_each_reason_under_its_own_tab() -> void:
    _live_state("Tabs Test")
    var hall := _guildhall()
    var row = _find(hall, "TabRow")
    assert_true(row != null, "the title bar is Widgets.tab_row")
    var tabs: Array = Widgets.tabs_of(row)
    # Three tabs (LOOP-14 / UI-50): the "Raid Group" tab could never enable —
    # its reason was a redirect to the board — and a dead control is not
    # "disabled with a reason". RaidPrep's strip is the raid group.
    assert_eq(tabs.size(), 3)
    var texts: Array = []
    for b in tabs:
        texts.append((b as Button).text)
    assert_eq(texts, ["Roster", "Facilities", "Records"])
    var roster_tab: Button = tabs[0]
    assert_eq(roster_tab.theme_type_variation, "NavItemActive", "the open tab is lit")
    assert_false(roster_tab.disabled)
    var cells_w := 0.0
    for b in tabs:
        var tab: Button = b
        assert_true(tab.custom_minimum_size.x >= GuildhallScript.TAB_SIZE.x, "a tab never hugs its word")
        var cell: Control = tab.get_parent()
        var why: Label = cell.get_node_or_null("Reason") as Label
        if tab.disabled:
            assert_true(why != null, "a shut tab prints its reason under itself: %s" % tab.text)
            assert_true(why.text.length() > 0)
            assert_true(why.custom_minimum_size.x > 0.0, "the caption sizes its own cell")
            assert_true(why.autowrap_mode != TextServer.AUTOWRAP_OFF,
                "a larger text scale wraps the caption instead of widening the row")
        else:
            assert_true(why == null, "an open tab has no reason")
        cells_w += cell.get_combined_minimum_size().x
    cells_w += 4.0 * (tabs.size() - 1)
    assert_true(cells_w <= float(PANEL_INNER_W),
        "the three cells and their captions fit the panel (%.0f)" % cells_w)
    var printed := _joined(hall)
    assert_true(printed.contains("Records"))
    assert_false(printed.contains("Raid Group"), "the dead tab is gone")
    # LOOP-15: one sentence for the one wall, the sim's, and never the old
    # "nothing to record until you have raided" (false after the first raid).
    var Achievements = load("res://sim/core/Achievements.gd")
    var gate := String(Achievements.unlock_reason(Achievements.blank_snapshot()))
    assert_true(printed.contains(gate), "the gate's reason is still a Label: %s" % printed)
    assert_true(gate.contains("record wall") and gate.contains("Known"), gate)
    assert_false(printed.contains("nothing to record"), printed)
    for b in _buttons(hall):
        var btn: Button = b
        if btn.is_visible_in_tree() and not btn.disabled:
            assert_eq(btn.focus_mode, Control.FOCUS_ALL, "%s is not FOCUS_ALL" % btn.text)


func test_pressing_a_tab_rebuilds_the_row_with_that_tab_lit() -> void:
    _live_state("Switch Test")
    var hall := _guildhall()
    var fac = _button_named(hall, "Facilities")
    assert_true(fac != null and not fac.disabled)
    fac.pressed.emit()
    assert_eq(hall.active_tab(), "facilities")
    var tabs: Array = Widgets.tabs_of(_find(hall, "TabRow"))
    assert_eq((tabs[1] as Button).theme_type_variation, "NavItemActive", "Facilities is the second of three")
    assert_eq((tabs[0] as Button).theme_type_variation, "ButtonQuiet")
    assert_true(_find(hall, "FacilitiesView") != null)
    assert_true(_find(hall, "RosterView") == null, "one view at a time")


# ------------------------------------------------ HALL-12

func test_the_filter_word_is_printed_only_while_a_filter_is_on() -> void:
    var st = _live_state("Filter Test")
    var view := _roster()
    var showing: Label = _find(view, "Showing")
    assert_true(showing != null)
    assert_eq(showing.text, "Showing %d of %d" % [st.roster.size(), st.roster.size()],
        "the exact prefix test_starting_roster reads, with no suffix on All")
    var at_risk = _find(view, "Filter_1")
    assert_true(at_risk is Button and (at_risk as Button).text == "At risk")
    at_risk.pressed.emit()
    assert_true(showing.text.ends_with(" · At risk"), showing.text)
    assert_true(showing.text.begins_with("Showing 0 of"), "nobody starts at risk: %s" % showing.text)
    assert_true(_joined(view).contains("Nobody matches this filter"))
    _find(view, "Filter_0").pressed.emit()
    assert_eq(showing.text, "Showing %d of %d" % [st.roster.size(), st.roster.size()])


func test_sort_and_filter_chips_are_lit_by_their_pressed_state() -> void:
    _live_state("Chip Test")
    var view := _roster()
    for name in ["Sort_0", "Sort_1", "Filter_0", "Filter_4"]:
        var b: Button = _find(view, name)
        assert_true(b != null, name)
        assert_eq(b.theme_type_variation, "ButtonChip", "%s is a chip" % name)
        assert_true(b.toggle_mode, "%s is a toggle" % name)
        assert_eq(b.focus_mode, Control.FOCUS_ALL)
    assert_true((_find(view, "Sort_0") as Button).button_pressed, "Morale is the default sort")
    assert_true((_find(view, "Filter_0") as Button).button_pressed, "All is the default filter")
    _find(view, "Sort_1").pressed.emit()
    assert_true((_find(view, "Sort_1") as Button).button_pressed)
    assert_false((_find(view, "Sort_0") as Button).button_pressed, "one key at a time")
    # The chip's font colour is the variation's, not an override (state by chrome).
    assert_false((_find(view, "Sort_1") as Button).has_theme_color_override("font_color"))


# ------------------------------------------------ HALL-13

func test_an_at_risk_raider_wears_a_stamp_box_across_the_portrait() -> void:
    var st = _live_state("Stamp Test")
    Morale.set_morale(st.roster[0], 12.0)
    var view := _roster()
    var stamped: Array = []
    for cell in _cells(view):
        var stamp = _find(cell, "Stamp")
        if stamp != null:
            stamped.append(cell)
            assert_true(stamp is PanelContainer, "the stamp is the kit's box, not a caption")
            assert_eq(stamp.theme_type_variation, "PanelStamp")
            var word: Label = stamp.get_node_or_null("Word")
            assert_true(word != null and word.text in ["AT RISK", "MAY LEAVE"], "the word is a Label")
            assert_true(stamp.rotation_degrees != 0.0, "a stamp lands at an angle")
            assert_true(stamp.position.x >= 0.0 and stamp.position.y >= 0.0)
            assert_true(stamp.position.y + stamp.size.y <= float(Widgets.CARD_SIZE.y),
                "inside the card")
            assert_true(stamp.position.y < 120.0, "across the portrait's lower edge, not the slots")
    assert_eq(stamped.size(), 1, "exactly the one raider at risk is stamped")


# ------------------------------------------------ HALL-09

func test_the_histogram_counts_every_raider_once_per_band() -> void:
    var st = _live_state("Histogram Test")
    var counts: Array = RosterView.band_counts(st.roster)
    assert_eq(counts.size(), Enums.MORALE_BAND_COUNT)
    var total := 0
    for n in counts:
        total += int(n)
    assert_eq(total, st.roster.size())
    var view := _roster()
    var well = _find(view, "MoraleHistogram")
    assert_true(well != null, "the well is under the summary")
    for band in Enums.MORALE_BAND_COUNT:
        assert_true(_find(well, "Band%d" % band) is ColorRect, "one bar per band")
    var printed := _joined(view)
    assert_true(printed.contains("Roster average morale"))
    assert_true(printed.contains("At risk 0"))


# ------------------------------------------------ HALL-04

func test_the_strip_lists_twelve_in_two_lines_each() -> void:
    var st = _live_state("Strip Test")
    var hall := _guildhall()
    var low = _find(hall, "LowestMorale")
    assert_true(low != null, "the strip's left panel")
    var shown: int = mini(GuildhallScript.STRIP_COLUMNS * GuildhallScript.STRIP_ROWS, st.roster.size())
    assert_eq(shown, 12, "the fixture is a full raid")
    var sorted: Array = st.roster.duplicate()
    sorted.sort_custom(func(a, b) -> bool: return a.morale < b.morale)
    var inner_h: float = Widgets.STRIP_H - 28.0
    for i in shown:
        var line1: Label = _find(low, "Morale_%d" % i)
        var line2: Label = _find(low, "Class_%d" % i)
        assert_true(line1 != null and line2 != null, "entry %d has two lines" % i)
        var r = sorted[i]
        assert_true(line1.text.begins_with("%s — %d " % [String(r.display_name), int(r.morale)]),
            "line 1 is Name — value glyph: %s" % line1.text)
        assert_eq(line2.text, "%s — %s" % [Enums.class_name_of(r.class_id), Enums.morale_band_name(int(r.morale))],
            "line 2 is Class — State")
        assert_eq(line1.theme_type_variation, "LabelMorale")
        assert_eq(line2.theme_type_variation, "LabelClass")
        assert_true(line2.position.y + line2.size.y <= inner_h, "entry %d is inside the panel" % i)
        assert_true(line1.position.x + line1.size.x <= GuildhallScript.STRIP_LEFT_W - 28.0)
    assert_true(_find(low, "More") == null, "twelve of twelve: nothing more to say")
    assert_true(_find(low, "Morale_12") == null)


func test_past_twelve_the_strip_says_how_many_more_and_where_they_stand() -> void:
    var st = _live_state("More Test")
    # A thirteenth raider, happier than everyone shown, so the tail is honest.
    var d: Dictionary = st.roster[0].to_dict()
    d["id"] = String(d.get("id", "r")) + "_thirteenth"
    d["display_name"] = "Thirteenth"
    var extra = RaiderScript.from_dict(d)
    assert_true(extra != null, "a raider round-trips through its dict")
    st.roster.append(extra)
    Morale.set_morale(extra, 90.0)
    var hall := _guildhall()
    var low = _find(hall, "LowestMorale")
    var more: Label = _find(low, "More")
    assert_true(more != null, "a trailing Label past twelve")
    var sorted: Array = st.roster.duplicate()
    sorted.sort_custom(func(a, b) -> bool: return a.morale < b.morale)
    assert_eq(more.text, "+1 more, all above %d" % int(sorted[11].morale))
    assert_true(more.position.y + more.size.y <= Widgets.STRIP_H - 28.0, "inside the panel")


# ------------------------------------------------ HALL-20

func test_every_record_row_leads_with_a_state_icon() -> void:
    var st = _live_state("Records Test")
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var hall := _guildhall()
    var tab = _button_named(hall, "Records")
    assert_true(tab != null and not tab.disabled, "Records opens at Known")
    tab.pressed.emit()
    var rows := _find_all(hall, "Record_")
    assert_true(rows.size() > 0, "the wall has rows")
    for row in rows:
        var icon = row.get_child(0)
        assert_true(icon is TextureRect and icon.name == "StateIcon", "the row leads with its icon")
        assert_true((icon as TextureRect).texture != null, "and the icon is a real texture")
    var printed := _joined(hall)
    assert_true(printed.contains("Records  0 of"), "the wall's own count, two spaces")
    assert_true(printed.contains("Legendaries 0 of %d" % Enums.CLASS_KEYS.size()))


# ------------------------------------------------ HALL-22

func test_the_facilities_picker_lights_exactly_the_chosen_tile() -> void:
    var st = _live_state("Picker Test")
    var hall := _guildhall()
    _button_named(hall, "Facilities").pressed.emit()
    var picker = _find(hall, "Picker")
    assert_true(picker != null, "the portrait mini-grid")
    var lit: Array = []
    for b in _buttons(picker):
        var tile: Button = b
        assert_true(tile.toggle_mode, "a tile is a toggle so the pressed plate is its lit state")
        assert_eq(tile.theme_type_variation, "ButtonMini")
        assert_eq(tile.modulate, Color.WHITE, "no tile is dimmed to hint at the chosen one")
        if tile.button_pressed:
            lit.append(tile)
    assert_eq(lit.size(), 1, "exactly one tile is lit")
    assert_eq((lit[0] as Button).text, String(st.roster[0].display_name), "Button.text is the name")


# ------------------------------------------------ KIT-08

func test_empty_states_carry_the_kits_glyph_and_their_sentence() -> void:
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
    st.reset()
    st.set_content(_db)
    var view := _roster()
    var empty: Label = _find(view, "Empty")
    assert_true(empty != null, "the empty grid is the kit's empty state")
    assert_true(empty.text.begins_with("No raiders yet"), empty.text)
    var glyph = empty.get_node_or_null("Glyph")
    assert_true(glyph is TextureRect and (glyph as TextureRect).texture != null, "with its glyph")
