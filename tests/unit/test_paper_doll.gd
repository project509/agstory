extends "res://tests/TestCase.gd"
## W3-DETAIL — RaiderDetail's paper doll (game/ui/PaperDoll.gd, HALL-07) and the
## screen around it: the doll is Concept 2's slot grid, every slot is a Button a
## keyboard can reach whose text is the slot's name, the legend keeps the words
## the older list printed, the gear totals never read as broken stats (HALL-08),
## the formula is one Label (HALL-26), the dismissal is the kit's confirm pair
## (CRITIC-G05), the disabled Cheer up says why through `Widgets.reasoned`
## (CRITIC-G06) and the empty record is one empty state (HALL-23).
##
## The screen is read the way every screen test reads it — `Label.text` and
## `Button.text` — plus the two seams RaiderDetail exposes for this file
## (`slot_buttons()`, `shown_raider_id()`).

const Enums = preload("res://sim/model/Enums.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const DetailView = preload("res://game/screens/RaiderDetail.gd")
const PaperDoll = preload("res://game/ui/PaperDoll.gd")
const Widgets = preload("res://game/ui/Widgets.gd")

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


func _live_state(guild: String, gold: int = 500):
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


func _detail() -> Control:
    var view := DetailView.new()
    _root().add_child(view)
    _mounted.append(view)
    view.build()
    return view


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


func _find(n: Node, name: String) -> Node:
    if n.name == name:
        return n
    for c in n.get_children():
        var hit := _find(c, name)
        if hit != null:
            return hit
    return null


func _label_containing(n: Node, fragment: String) -> Label:
    if n is Label and (n as Label).text.contains(fragment):
        return n
    for c in n.get_children():
        var hit := _label_containing(c, fragment)
        if hit != null:
            return hit
    return null


## The first roster raider whose class has (or lacks) an off hand, or null.
func _raider_with_off_hand(st, wants: bool):
    for r in st.roster:
        var cd = _db.class_of(r.class_id)
        if cd != null and cd.has_off_hand() == wants:
            return r
    return null


# =============================================== the doll on the screen

func test_every_slot_the_class_can_fill_is_a_button_named_for_it() -> void:
    # HALL-07's acceptance: seven slot Buttons (or six + a blank) with their slot
    # names — the walker reads the names, a keyboard reaches every slot.
    var st = _live_state("Doll Buttons")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var view := _detail()
    var slots: Dictionary = view.slot_buttons()
    var cd = _db.class_of(who.class_id)
    var available: Array = cd.available_slots()
    assert_eq(slots.size(), available.size(),
        "one Button per available slot: %s" % str(slots.keys()))
    for slot in available:
        assert_true(slots.has(int(slot)), "%s must have a Button" % Enums.slot_name_of(int(slot)))
        var b: Button = slots[int(slot)]
        assert_eq(b.text, Enums.slot_name_of(int(slot)))
        assert_eq(b.name, "Slot_%s" % Enums.slot_key(int(slot)))
        assert_eq(b.focus_mode, Control.FOCUS_ALL, "every slot is reachable by keyboard")
        assert_false(b.disabled)
        assert_true(b.icon != null, "every slot carries a picture — the item's or the slot's own glyph")

func test_the_grid_is_always_three_by_two_and_the_weapon_stands_alone() -> void:
    var st = _live_state("Doll Grid")
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var doll := _find(view, "PaperDoll")
    assert_true(doll != null, "the doll is built under the Kit heading")
    var grid := _find(doll, "Grid")
    assert_true(grid is GridContainer)
    assert_eq((grid as GridContainer).columns, PaperDoll.GRID_COLS)
    assert_eq(grid.get_child_count(), PaperDoll.GRID_SLOTS.size(), "six cells: off hand, head, chest, legs, feet, trinket")
    var weapon := _find(doll, "Slot_main_hand")
    assert_true(weapon is Button, "the main hand is the tall weapon slot")
    assert_true(weapon.get_parent() == doll, "and stands beside the grid, not inside it")
    assert_eq((weapon as Control).custom_minimum_size, Vector2(PaperDoll.WEAPON))
    var portrait := _find(doll, "Portrait")
    assert_true(portrait != null)
    assert_eq((portrait as Control).custom_minimum_size, Vector2(PaperDoll.WELL), "a 2x well for the 90x94 bust")
    assert_true(PaperDoll.WIDTH <= DetailView.LEFT_TEXT_W, "the doll fits the kit panel's text width")

func test_a_class_without_an_off_hand_shows_a_blank_not_an_empty_slot() -> void:
    # docs/13 §9.1: "hidden, not empty". The grid keeps its 3x2 shape with a
    # blank well where the off hand would be, and no Button a keyboard could
    # land on.
    var st = _live_state("Doll Blank")
    var who = _raider_with_off_hand(st, false)
    if who == null:
        return
    st.selected_raider_id = who.id
    var view := _detail()
    var slots: Dictionary = view.slot_buttons()
    assert_false(slots.has(Enums.Slot.OFF_HAND), "no off-hand Button")
    assert_eq(slots.size(), 6, "six Buttons")
    var blank := _find(view, "Blank_off_hand")
    assert_true(blank != null and not (blank is BaseButton), "and a blank well in its place")
    assert_false(_printed(view).contains("Off Hand"), "the legend does not list a slot they do not have")

func test_a_class_with_an_off_hand_shows_seven_slots() -> void:
    var st = _live_state("Doll Seven")
    var who = _raider_with_off_hand(st, true)
    if who == null:
        return
    st.selected_raider_id = who.id
    var view := _detail()
    assert_eq(view.slot_buttons().size(), 7)
    assert_true(_find(view, "Blank_off_hand") == null)

func test_the_slot_tooltip_is_a_title_over_a_body() -> void:
    # KIT-22 / spec 06 §8: title line, body line. An empty slot says so; a worn
    # one names the item and what it is worth.
    var st = _live_state("Doll Tips")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var view := _detail()
    var slots: Dictionary = view.slot_buttons()
    for slot in slots:
        var b: Button = slots[slot]
        var lines: PackedStringArray = b.tooltip_text.split("\n")
        assert_eq(lines.size(), 2, "two lines: %s" % b.tooltip_text)
        assert_true(lines[0].begins_with(Enums.slot_name_of(int(slot))), "the title names the slot: %s" % lines[0])
        var worn = who.item_in(_db, int(slot))
        if worn != null:
            assert_true(lines[0].contains(worn.name))
            assert_true(lines[1].contains("worth"))
        else:
            assert_true(lines[0].contains("empty"))

func test_the_legend_keeps_the_words_the_list_printed() -> void:
    # The slot names, "empty" and "worth" stay readable Labels under the doll
    # (test_raider_detail.gd reads them), one row per available slot.
    var st = _live_state("Doll Legend")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var view := _detail()
    var cd = _db.class_of(who.class_id)
    var worn_any := false
    var empty_any := false
    for slot in cd.available_slots():
        var row := _find(view, "Legend_%s" % Enums.slot_key(int(slot)))
        assert_true(row != null, "a legend row for %s" % Enums.slot_name_of(int(slot)))
        var text := _printed(row)
        assert_true(text.contains(Enums.slot_name_of(int(slot))))
        if who.item_in(_db, int(slot)) != null:
            worn_any = true
            assert_true(text.contains("worth"), text)
        else:
            empty_any = true
            assert_true(text.contains("empty"), text)
    assert_true(worn_any and empty_any, "a starting raider wears armour and holds no weapon")


# =============================================== the totals, the formula

func test_no_stat_cell_reads_as_a_bare_zero() -> void:
    # HALL-08: "0 HP" on a living raider reads as a bug. HP is the real maximum;
    # the rest carry their sign as gear bonuses; no weapon says "no weapon".
    var st = _live_state("Doll Totals")
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var view := _detail()
    var totals := _find(view, "Totals")
    assert_true(totals != null)
    var cells: Array = _labels(totals)
    assert_eq(cells.size(), 5)
    for text in cells:
        var s := String(text)
        assert_false(s.begins_with("0 "), "a bare zero: %s" % s)
    assert_eq(String(cells[0]), "%d HP" % who.max_hp(_db), "HP is base + gear, never the gear alone")
    assert_true(String(cells[1]).ends_with(" AC") and (String(cells[1]).begins_with("+") or String(cells[1]).begins_with("-")))
    if who.item_in(_db, Enums.Slot.MAIN_HAND) == null:
        assert_eq(String(cells[4]), "no weapon")
    assert_true(_printed(view).contains("%d AC" % who.gear_stats(_db).ac), "test_raider_detail's AC read still holds")

func test_the_baseline_formula_is_one_label() -> void:
    # HALL-26 / UI-27: ONE Label, single-spaced, at the kit's small size —
    # "Settles at 45 — Common, no furnishings." in the guild's own voice — and
    # docs/02 §4.5's "50 base ... = 45 baseline" arithmetic as its tooltip.
    var st = _live_state("Doll Formula")
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var l := _label_containing(view, "Settles at")
    assert_true(l != null)
    assert_true(l.tooltip_text.contains("50 base") and l.tooltip_text.contains("baseline"),
        "the terms and the result are the Label's tooltip: %s" % l.tooltip_text)
    assert_false(l.text.contains("  "), "no double spaces: %s" % l.text)
    assert_eq(l.theme_type_variation, "LabelSmall")


# =============================================== the sidebar

func test_dismissal_is_the_kits_confirm_pair() -> void:
    # CRITIC-G05: press Dismiss, get ONE plate named "Confirm" holding both
    # halves as Buttons with the texts the older block printed.
    var st = _live_state("Doll Dismiss")
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    assert_true(_find(view, "Confirm") == null, "nothing to confirm before Dismiss is pressed")
    var dismiss = _button_named(view, "Dismiss")
    assert_true(dismiss != null)
    dismiss.pressed.emit()
    var plate := _find(view, "Confirm")
    assert_true(plate != null, "the confirm pair is on the sidebar")
    var yes = _button_named(plate, "Yes — let them go")
    var no = _button_named(plate, "Keep them")
    assert_true(yes != null and no != null, _printed(plate))
    assert_true(Widgets.default_focus_of(plate) == no, "the safe half is the default focus")
    no.pressed.emit()
    assert_true(_find(view, "Confirm") == null, "Keep them puts the block away")

func test_the_disabled_cheer_up_says_why_beside_itself() -> void:
    # CRITIC-G06: `Widgets.reasoned` — the reason is the Label named "Reason"
    # right under the button, never a tooltip.
    var st = _live_state("Doll Reasoned", 0)
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var view := _detail()
    var cheer = _button_named(view, "Cheer up")
    assert_true(cheer != null)
    assert_true(cheer.disabled, "no gold, no bath — the one gate the Market also has (LOOP-16)")
    var reason: Node = (cheer as Button).get_parent().get_node_or_null("Reason")
    assert_true(reason is Label, "the reason sits in the same box as the button")
    assert_true((reason as Label).text.contains("Costs 20 G"), (reason as Label).text)
    assert_true(cheer.icon != null, "the padlock sits in the button's leading slot")

func test_the_record_sits_under_the_card_in_the_sidebar() -> void:
    # HALL-09: "On record" and the counters live in the sidebar, under the raider
    # card and above "Back to the roster".
    var st = _live_state("Doll Record")
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var side := _find(view, "Sidebar")
    assert_true(side != null)
    var text := _printed(side)
    assert_true(text.contains("On record"), text)
    assert_true(text.contains("Ran 0 raids"), text)
    assert_true(text.find("On record") < text.find("Back to the roster"))
    assert_true(text.find("Dismiss") < text.find("On record"), "the actions come first")

func test_the_empty_record_is_one_empty_state_with_both_sentences() -> void:
    # HALL-23: not a paragraph — one centred empty-state block: the backstory's
    # sentence is the line, the wishlist's the hint under it, both the Labels
    # test_raider_detail.gd asserts.
    var st = _live_state("Doll Empty")
    st.roster[0].backstory = []
    st.roster[0].backstory_offset = 0
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var l := _label_containing(view, "Nothing is written down about them yet")
    assert_true(l != null)
    assert_eq(l.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
    assert_eq(l.size_flags_vertical, Control.SIZE_EXPAND_FILL, "it fills the space the panel has left")
    assert_true(l.get_node_or_null("Hint") == null,
        "one sentence, no hint: nothing about when a backstory arrives or a wishlist (C12-C14)")
    assert_true(l.get_node_or_null("Glyph") != null, "with the quill over it")


# =============================================== the composite alone

func test_the_composite_builds_without_a_screen() -> void:
    var host := Control.new()
    _mounted.append(host)
    var cells := {}
    for slot in Enums.all_slots():
        cells[int(slot)] = {"icon": null, "worn": false, "tooltip": "%s — empty\nnothing worn here" % Enums.slot_name_of(int(slot))}
    var doll := PaperDoll.build(null, cells, host)
    host.add_child(doll)
    var slots := PaperDoll.slots_of(doll)
    assert_eq(slots.size(), Enums.all_slots().size())
    for slot in slots:
        var b: Button = slots[slot]
        assert_eq(b.text, Enums.slot_name_of(int(slot)))
        assert_eq(b.focus_mode, Control.FOCUS_ALL)
    var bare := PaperDoll.build(null, {}, host)
    host.add_child(bare)
    assert_eq(PaperDoll.slots_of(bare).size(), 0, "no cells, no Buttons")
    assert_eq(_buttons(bare).size(), 0)
    assert_eq(_find(bare, "Grid").get_child_count(), 6, "the grid still reads as 3x2")
    assert_eq(PaperDoll.slots_of(host).size(), 0, "a stranger has no slots")
