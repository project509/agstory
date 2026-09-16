extends "res://tests/TestCase.gd"
## W2-MARKET (build/plan/artaudit/00-plan.md §3): the Market is a shop.
##
## tests/unit/test_market.gd owns the economy and the press-by-fragment contract
## ("Sell Worn Iron Cap — 1 G", "take it off", "Minor — 8 G", "1 held"). This file
## pins the SHAPE the art pass gave the screen: a slot grid whose selection fills
## the sidebar card (TOWN-21), the two sell groups and their Day-1 default
## (TOWN-28), the one crimson commit, the ledger beside the square (TOWN-22 /
## STAGE-15), the frame's chips (KIT-03) and the quiet escape (TOWN-31).

const DB = preload("res://sim/content/ContentDB.gd")
const Loot = preload("res://sim/core/Loot.gd")
const Enums = preload("res://sim/model/Enums.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const MarketView = preload("res://game/screens/Market.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Palette = preload("res://game/ui/Palette.gd")

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


# ---------------------------------------------------------------- harness

func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _live_state(guild: String, gold: int):
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
    st.reset()
    st.set_content(_db)
    st.new_game(guild)
    st.gold = gold
    return st


func _market() -> Control:
    var view := MarketView.new()
    _root().add_child(view)
    _mounted.append(view)
    view.build()
    return view


func _drop(slot: String = "A2"):
    return Loot.drop_pool(_db.encounter_at_slot(slot), _db)[0]


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


func _find(n: Node, node_name: String) -> Node:
    if String(n.name) == node_name:
        return n
    for c in n.get_children():
        var hit := _find(c, node_name)
        if hit != null:
            return hit
    return null


func _find_all(n: Node, node_name: String, out: Array = []) -> Array:
    if String(n.name) == node_name:
        out.append(n)
    for c in n.get_children():
        _find_all(c, node_name, out)
    return out


func _label_text(n: Node, node_name: String) -> String:
    var l := _find(n, node_name)
    return (l as Label).text if l is Label else ""


# ---------------------------------------------------------------- TOWN-28

func test_day_one_opens_with_an_empty_window_and_the_worn_group_open() -> void:
    # A new guild has found nothing; the roster wears its starting armour. The
    # window says so and the worn gear is simply shown — no toggle to find,
    # which is also what keeps test_market.gd:478's press unchanged.
    var st = _live_state("Day One", 60)
    assert_true(st.pending_loot.is_empty(), "a new game has an empty loot window")
    var view := _market()
    var printed := _printed(view)
    assert_true(printed.contains("In the window"), printed)
    assert_true(printed.contains("Nothing found yet"), printed)
    assert_true(printed.contains("Worn by the roster"), printed)
    assert_false(printed.contains("Show worn gear"),
        "with an empty window there is nothing to hide the worn group behind")
    var who = st.roster[0]
    var chest = who.item_in(_db, Enums.Slot.CHEST)
    assert_true(_button_named(view, "Sell " + String(chest.name)) != null,
        "the worn gear is on the grid as pressable slots")


func test_loot_in_the_window_puts_the_worn_group_behind_a_toggle() -> void:
    var st = _live_state("Loot Day", 60)
    st.pending_loot.append(_drop())
    var view := _market()
    var printed := _printed(view)
    assert_true(printed.contains("In the window"), printed)
    assert_false(printed.contains("Nothing found yet"), printed)
    assert_false(printed.contains("Worn by the roster"),
        "the roster's own gear is not the first thing a loot-carrying guild sees")
    var toggle = _button_named(view, "Show worn gear (")
    assert_true(toggle != null, "the worn group is behind a toggle: %s" % printed)
    assert_true(String(toggle.text).contains("(%d)" % (st.sell_rows().size() - 1)),
        "and the toggle counts the worn rows: %s" % toggle.text)
    toggle.pressed.emit()
    assert_true(_printed(view).contains("Worn by the roster"), _printed(view))


# ---------------------------------------------------------------- TOWN-21

func test_the_window_item_is_selected_by_default_and_the_card_describes_it() -> void:
    var st = _live_state("Card Test", 60)
    var it = _drop()
    st.pending_loot.append(it)
    var view := _market()
    assert_false(String(view.selected_row()).is_empty(), "the screen picks a slot on entry")
    assert_true(_find(view, "Card") != null, "the sidebar carries the selection's card")
    assert_eq(_label_text(view, "CardName"), String(it.name))
    assert_eq(_label_text(view, "CardWhere"), "in the loot window")
    assert_true(_label_text(view, "CardPrice").contains(" G"), _label_text(view, "CardPrice"))
    var sell = _find(view, "CardSell")
    assert_true(sell is Button and not (sell as Button).disabled,
        "a window item sells on the card's crimson button")
    (sell as Button).pressed.emit()
    assert_true(st.gold > 60, "and it sold")


func test_pressing_a_worn_slot_selects_it_and_asks() -> void:
    var st = _live_state("Select Test", 0)
    var view := _market()
    var who = st.roster[0]
    var chest = who.item_in(_db, Enums.Slot.CHEST)
    var before := String(view.selected_row())
    var slot_button = _button_named(view, "Sell " + String(chest.name))
    slot_button.pressed.emit()
    assert_true(String(view.selected_row()) != before
        or String(view.selected_row()).contains(String(chest.id)),
        "the press moved the selection to the chest piece")
    assert_true(String(view.selected_row()).contains(String(chest.id)))
    assert_eq(_label_text(view, "CardName"), String(chest.name))
    assert_true(_label_text(view, "CardWhere").begins_with("worn by "),
        _label_text(view, "CardWhere"))
    assert_true(_find(view, "Confirm") != null, "a worn item's press opens the confirm pair")
    assert_true(_button_named(view, "take it off") != null)
    assert_true(_button_named(view, "Keep it") != null)
    assert_eq(st.gold, 0, "nothing sold by selecting")
    _button_named(view, "Keep it").pressed.emit()
    assert_true(_find(view, "Confirm") == null, "Keep it closes the ask")
    assert_true(_find(view, "CardSell") != null, "and the card offers the sale again")


func test_every_grid_slot_is_a_focusable_button_carrying_the_rows_sentence() -> void:
    var st = _live_state("Slots Test", 60)
    st.pending_loot.append(_drop())
    var view := _market()
    _button_named(view, "Show worn gear (").pressed.emit()
    var grids: Array = [_find(view, "WindowGrid"), _find(view, "WornGrid")]
    assert_true(grids[0] != null and grids[1] != null, "one grid per group")
    var seen := 0
    for g in grids:
        assert_eq((g as GridContainer).columns,
            MarketView.columns_for(Theme_.scale_of(view)),
            "six across at 100, fewer as the cells widen with the text")
        for b in _buttons(g):
            seen += 1
            assert_eq((b as Button).focus_mode, Control.FOCUS_ALL, "%s must be keyboard-reachable" % b.text)
            assert_true(String(b.text).begins_with("Sell "), b.text)
            assert_true(String(b.text).contains(" G"), b.text)
            assert_true((b as Button).icon != null, "%s shows its gear icon" % b.text)
    assert_eq(seen, st.sell_rows().size(), "one slot per sell row")


func test_a_sell_slot_keeps_its_rim_clear_of_the_icon() -> void:
    # review-W2-MARKET.md issue 1: seven gear crops (the plate chest, the reward
    # trinkets) are opaque to their edge; expanded to the slot they painted over
    # the rim and the selection had no cue. The crop is drawn 1:1 inside the rim.
    var st = _live_state("Rim Test", 0)
    var view := _market()
    var who = st.roster[0]
    var chest = who.item_in(_db, Enums.Slot.CHEST)
    _button_named(view, "Sell " + String(chest.name)).pressed.emit()
    var lit := 0
    for b in _buttons(_find(view, "WornGrid")):
        var btn := b as Button
        assert_false(btn.expand_icon, "%s: the icon is not stretched over the rim" % btn.text)
        var rim := btn.get_theme_stylebox("normal") as StyleBoxFlat
        assert_true(rim != null and rim.border_width_top >= 2, "%s has a rim" % btn.text)
        assert_true(btn.icon.get_width() + 2 * rim.border_width_top < btn.custom_minimum_size.x,
            "%s: the icon fits inside the rim" % btn.text)
        if rim.border_color == Palette.ACCENT_GOLD:
            lit += 1
            assert_true(String(btn.text).contains(String(chest.name)),
                "the gold rim is on the pressed slot: %s" % btn.text)
    assert_eq(lit, 1, "exactly one slot carries the selection rim")


func test_the_sell_all_button_wraps_rather_than_trimming_its_arithmetic() -> void:
    # review-W2-MARKET.md issue 3: docs/02 §6.3's "(before → after)" preview is
    # the point of the button; at text scale 150 it goes to a second line.
    var st = _live_state("Wrap Test", 12480)
    var view := _market()
    var b = _button_named(view, "Sell all nobody can wear")
    assert_true(b != null, "the sell-all helper is on the Sell tab")
    assert_true(String(b.text).contains("(12480 → 12480)"), b.text)
    assert_eq((b as Button).autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
    assert_eq((b as Button).text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING,
        "nothing of the arithmetic is trimmed")
    assert_false((b as Button).clip_text)
    assert_true(st.roster.size() > 0)


func test_the_sell_tab_has_exactly_one_crimson_commit_and_the_buy_tab_none() -> void:
    var st = _live_state("Crimson Test", 500)
    st.pending_loot.append(_drop())
    var view := _market()
    assert_eq(_crimson(view).size(), 1, "the card's Sell is the one crimson control")
    _button_named(view, "Buy").pressed.emit()
    assert_eq(_crimson(view).size(), 0, "nothing is selected on the Buy tab")
    assert_true(_find(view, "Card") == null)


func _crimson(view: Node) -> Array:
    var out: Array = []
    for b in _buttons(view):
        if String((b as Button).theme_type_variation).begins_with("ButtonCta"):
            out.append(b)
    return out


func test_a_buy_cell_shows_the_provision_and_counts_what_is_held() -> void:
    var st = _live_state("Buy Cell", 500)
    var view := _market()
    _button_named(view, "Buy").pressed.emit()
    var potion = _button_named(view, "Minor — 8 G")
    assert_true(potion != null and (potion as Button).icon != null,
        "the slot carries the potion's icon")
    assert_true(_find(potion, "Held") == null, "nothing held, no numeral")
    potion.pressed.emit()
    potion = _button_named(view, "Minor — 8 G")
    var held := _find(potion, "Held")
    assert_true(held is Label, "one held: the corner numeral appears")
    assert_eq((held as Label).text, "1")
    assert_true(String(potion.text).contains("(1 held)"),
        "and the count stays in the Button's text for test_market.gd")


func test_a_furnishing_cell_carries_its_icon_and_the_reason_it_is_shut() -> void:
    var st = _live_state("Comfort Cell", 9999)
    var view := _market()
    _button_named(view, "Comfort").pressed.emit()
    var cot = _button_named(view, "Straw Cot")
    assert_true(cot != null and (cot as Button).icon != null, "the cot has its furnishing icon")
    var bed = _button_named(view, "Feather Bed")
    assert_true(bed != null and (bed as Button).disabled, "the L3 shelf is shut at level 1")
    var reason := _find(bed.get_parent().get_parent(), "Reason")
    assert_true(reason is Label and (reason as Label).text.contains("does not carry"),
        "the reason is a Label beside the slot, never a tooltip")
    assert_true(st.roster.size() > 0)


func test_the_grid_reflows_by_rows_as_the_text_scales() -> void:
    # docs/13 §4.4: reflow, never truncate. The cell widens with the text and
    # the column count is what the ledger's measure fits.
    assert_eq(MarketView.columns_for(100), MarketView.GRID_COLUMNS)
    assert_eq(MarketView.columns_for(100, MarketView.COMFORT_CELL_W), 3)
    for pct in Type.SCALES:
        var cols: int = MarketView.columns_for(int(pct))
        var w: int = Type.at(MarketView.CELL_W, int(pct))
        assert_true(cols >= 1 and cols <= MarketView.GRID_COLUMNS)
        assert_true(cols * w + (cols - 1) * MarketView.GRID_GAP <= MarketView.LEDGER_BODY_W,
            "at %d%% %d cells of %dpx must fit the ledger" % [int(pct), cols, w])
    assert_true(MarketView.columns_for(150) < MarketView.GRID_COLUMNS,
        "at 150 the grid is narrower than six")


# ---------------------------------------------------------------- TOWN-22 / STAGE-15

func test_the_ledger_sits_left_and_the_square_shows_beside_it() -> void:
    # The ledger is the Board's 610-tall inset, 560 wide; the band to its right
    # is plate through and through (no page ground past the plate's edge), and
    # the scene's speaking shopper stands inside it, so the market's line has a
    # visible speaker (STAGE-10 / STAGE-15 — W2-STAGE2 placed the crowd for
    # this offset; handoff-W2-STAGE2.md).
    var rect: Rect2 = MarketView.LEDGER_RECT
    assert_eq(rect.size.x, 560.0)
    var band := Rect2(rect.end.x, 0.0, Widgets.SCENE.size.x - rect.end.x, Widgets.SCENE.size.y)
    var on_plate := Rect2(band.position - MarketView.PLATE_OFFSET, band.size)
    assert_true(Rect2(Vector2.ZERO, Vector2(1536, 1024)).encloses(on_plate),
        "the band is inside the 1536x1024 plate: %s" % on_plate)
    var scene: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
        "res://game/assets/scenes/stage_market.json"))
    var speech: Dictionary = scene.get("speech", {})
    if speech.has("speaker"):
        var who: Dictionary = scene["actors"][int(speech["speaker"])]
        var feet := Vector2(who["pos"][0], who["pos"][1]) + MarketView.PLATE_OFFSET
        assert_true(band.has_point(feet), "the speaking shopper stands in the band: %s" % feet)

    var st = _live_state("Ledger Test", 60)
    var view := _market()
    var ledger := _find(view, "Ledger")
    assert_true(ledger is PanelContainer)
    assert_eq((ledger as Control).position, rect.position)
    assert_eq((ledger as Control).size, rect.size)
    assert_true(_printed(ledger).contains("Market"), "the title is in the ledger's own bar")
    assert_true(st.roster.size() > 0)


func test_five_shoppers_stand_whole_in_the_visible_band() -> void:
    # STAGE-15's acceptance (>= 3 whole figures; the plan asks 4) measured
    # against the JSON rather than a shot: a figure is whole when its frame,
    # planted by the feet at `pos`, lies inside the band right of the ledger.
    var scene: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
        "res://game/assets/scenes/stage_market.json"))
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
        "res://game/assets/actors/actors.json"))
    var band := Rect2(MarketView.LEDGER_RECT.end.x, 0.0,
        Widgets.SCENE.size.x - MarketView.LEDGER_RECT.end.x, Widgets.SCENE.size.y)
    var whole := 0
    for a in scene["actors"]:
        var spec: Dictionary = manifest["actors"].get(String(a["who"]), {})
        if spec.is_empty():
            continue
        var w := float(spec["frame_w"])
        var h := float(spec["frame_h"])
        var feet := Vector2(a["pos"][0], a["pos"][1]) + MarketView.PLATE_OFFSET
        var body := Rect2(feet.x - w * 0.5, feet.y - h, w, h)
        if band.encloses(body):
            whole += 1
    assert_true(whole >= 4, "%d whole figures in the band; the plan asks for four" % whole)


# ---------------------------------------------------------------- KIT-03 / TOWN-31

func test_the_frame_owns_the_chips_and_the_escape_is_quiet() -> void:
    var st = _live_state("Chips Test", 12480)
    var view := _market()
    assert_false(view.has_method("_chips"), "the private chip builder is gone (KIT-03)")
    var day := _find(view, "DayChip")
    assert_true(day != null, "Frame.standard_chips built the day chip")
    assert_true(_printed(view).contains("12,480 G"),
        "the frame's chip carries the thousands separator: %s" % _printed(view))
    st.gold = 12500
    _button_named(view, "Buy").pressed.emit()
    assert_true(_printed(view).contains("12,500 G"), "and the refresh path rebuilds it")
    var back = _button_named(view, "Back to town")
    assert_true(back != null and back is Button)
    assert_eq(String(back.theme_type_variation), "ButtonQuiet")
