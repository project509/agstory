extends Control
## S06 — the Market (docs/02 §6, docs/11 §7).
##
## ✅ CANON: "buy consumables (potions), sell loot, and maybe crafting supplies"
## (raw notes, *Market*). Selling is the load-bearing half — docs/02 §6.1 calls it
## the "primary gold faucet outside mission payouts" — and docs/02 §6.3 calls the
## sell-all helper "the single highest-value convenience in the game", because "the
## canon loot tables drop class-restricted gear at five encounters per raid, so junk
## volume is high".
##
## docs/02 §6.3's tabs are Buy · Sell · Comfort · Supplies. Three of the four are
## here:
##
##   Sell      live. Every unassigned drop plus everything worn, with docs/02's
##             "worn by" column and the confirm it exists to force.
##   Comfort   live. A second entry point to the same buy-and-place verb the
##             Guildhall uses (docs/15 BL-43), because docs/02 §4.2 says comfort
##             items are "bought at the Market (§6)".
##   Buy       docs/11 §7's six consumables are specified down to the price, but
##             every one of them changes how a raid resolves, so the tab opens when
##             the raid can spend them — see docs/15 BL-44. Disabled with that
##             reason rather than selling something inert.
##   Supplies  docs/02 §6.3: "hidden unless crafting ships", and docs/02 §8 cut
##             crafting. Not shown at all.
##
## W2-MARKET (build/plan/artaudit/00-plan.md §3; TOWN-21/22/28, STAGE-15,
## CRITIC-G05, RULES-12, KIT-03, TOWN-31): the screen is a SHOP. The ledger is a
## 560px panel on the left of the scene, the square with its fountain and two
## stalls stands beside it, and the three tabs are slot grids: Sell is a 6-column
## grid of 47px item slots (rarity-rimmed, the item name under each) whose
## selection fills a sidebar card with the one crimson commit; Buy is the same
## grid with the provision icons and a corner numeral for the count held;
## Comfort keeps its portrait picker and puts the furnishings in slots. Every
## slot is a Button whose `text` is the row's full sentence ("Sell Worn Iron
## Cap — 1 G", "Minor — 8 G\n(1 held)") so tests/unit/test_market.gd presses it
## by fragment; the caption the player reads is a Label under the slot. Nothing
## the sim is asked to do changed; every mutation below is the one the pre-art
## screen made.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Icons = preload("res://game/ui/Icons.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Type = preload("res://game/ui/Type.gd")
const Services = preload("res://game/core/Services.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Comfort = preload("res://sim/core/Comfort.gd")
const Consumables = preload("res://sim/core/Consumables.gd")
const Buildings = preload("res://sim/core/Buildings.gd")

const TOWN := "res://game/screens/Town.tscn"
const PORTRAIT := "res://game/assets/portraits/"

## docs/02 §6.3's tab row. A tab with no `reason` is live; docs/13 §7 forbids a
## disabled control that does not say why it is disabled.
const TABS := [
    {"id": "sell", "label": "Sell", "reason": ""},
    {"id": "comfort", "label": "Comfort", "reason": ""},
    {"id": "buy", "label": "Buy", "reason": ""},
]

## 00 §2.6's rail, identical on every archetype-A/C screen. "market" is this
## screen, so its scene is empty and the item is inert; "home" is the hub and
## goes back rather than pushing a second Town onto the stack.
const RAIL := [
    {"id": "home", "label": "Camp", "scene": TOWN},
    {"id": "tavern", "label": "Tavern", "scene": "res://game/screens/Tavern.tscn"},
    {"id": "roster", "label": "Roster", "scene": "res://game/screens/Guildhall.tscn"},
    {"id": "market", "label": "Market", "scene": ""},
    {"id": "board", "label": "Adventure's Board", "scene": "res://game/screens/AdventureBoard.tscn"},
    {"id": "options", "label": "Options", "scene": "res://game/screens/Settings.tscn"},
]

## TOWN-22 / STAGE-15: the Board's composition. The ledger is a 560px panel
## inset on the left of the 928x640 scene host; the 350px to its right is the
## market square, seen through the plate offset below — the plan's number,
## which W2-STAGE2 placed the crowd for in the same wave: the band is plate
## x 998..1348 by y 300..940, the three right-hand stalls (the green awning
## cut at the top, the white one whole, the red tent whole) with five shoppers
## standing whole on the cobbles in front of them and the speaking one among
## them (stage_market.json, STAGE-15). What this band does NOT hold is the
## fountain: its shimmer rect is plate x 700..880, and at this offset that is
## under the ledger. TOWN-22's "framed on the fountain and two stalls" cannot
## be had at TOWN-22's own offset — the plate's geometry, not a choice here.
## (-250, -300) would show the fountain's right rim and four of the five
## shoppers, with the white stall and the red tent cut by the host's edge;
## the crowd was placed for this one, so this one stands. A figure sliced by
## the ledger's edge or the host's would read as a bug: `columns_for`'s test
## file reads the JSON against this offset and counts the whole ones.
const PLATE_OFFSET := Vector2(-420, -300)
const LEDGER_RECT := Rect2(18, 14, 560, 610)
## PanelWarm's 9-slice keeps a 14px content margin under the 12px pad (LESSONS:
## the +14 drift), so the ledger's measure is 560 - 2 * (12 + 14).
const LEDGER_PAD := 12
const LEDGER_TEXT_W := 508
## The list scrolls inside the ledger; the bar takes a lane off the measure.
const SCROLL_LANE := 12
const LEDGER_BODY_W := LEDGER_TEXT_W - SCROLL_LANE

## The square is scenery beside the ledger now, not a band under a title, so
## it is taken down only a step: the plate is a daytime image and the ledger's
## rim has to read against it.
const SCENE_DIM := Color(0.7, 0.7, 0.74)

## The slot grids (TOWN-21; 06 §2's 47px slot). Six 76px cells and five 8px
## gaps are 496 — the ledger's measure less the scroll lane — at text scale
## 100. The cell widens with the text scale (docs/13 §4.4: reflow by rows,
## never truncate) and `columns_for` re-counts the columns from what fits, so
## at 150 the same grid is four across. Comfort's cells carry a furnishing's
## name and price, so they are wider and there are three to a row.
const GRID_COLUMNS := 6
const GRID_GAP := 8
const CELL_W := 76
const COMFORT_CELL_W := 160
const CARD_ICON := 94                   ## the sidebar card's slot: two 47s
const CARD_ICON_PX := 64                ## the 32px icon drawn at exactly 2x
## The sidebar panel's measure: 378 - 2 * (Frame's 18 pad + PanelWarm's 14).
const SIDEBAR_TEXT_W := 314
const CARD_TEXT_W := 186                ## SIDEBAR_TEXT_W - 12 pad * 2 - 94 - 10
const TILE := 56                        ## 06 §2's portrait slot
const TAB_W := 110
const TAB_H := 32
const WINDOW_EMPTY_H := 96              ## room for the empty state's glyph

var _router = null
var _state = null
var _active := "sell"
var _tab_host: VBoxContainer = null
var _body: VBoxContainer = null
var _notice := ""
## The sell row whose confirm is open ("<worn by>:<slot>:<item id>").
var _confirming := ""
## The sell row the sidebar card describes (same key). Empty = the screen picks:
## the first thing in the window, else the first thing worn.
var _selected := ""
## TOWN-28: the roster's own gear sits behind a toggle while the window has
## loot in it; with an empty window the group is simply open.
var _worn_open := false
var _comfort_target := ""
var _built := false
var _frame = null
var _notice_label: Label = null
var _card_host: VBoxContainer = null
var _stall_host: VBoxContainer = null


func _ready() -> void:
    build()


func build() -> void:
    if _built:
        return
    _built = true
    _router = Services.router(self)
    _state = Services.state(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)
    theme = Theme_.current(self)
    _build()


func _build() -> void:
    var nav: Array = []
    for item in RAIL:
        var scene := String(item["scene"])
        var reason := ""
        if not scene.is_empty() and (_router == null or not _router.screen_exists(scene)):
            reason = "Not built in this version yet."
        nav.append({"id": item["id"], "label": item["label"], "reason": reason})

    _frame = Frame.build(self, {"nav": nav, "active": "market", "framed": true})
    for item in RAIL:
        var scene := String(item["scene"])
        var b: Button = _frame.nav_buttons.get(String(item["id"]))
        if b == null or scene.is_empty() or b.disabled:
            continue
        if scene == TOWN:
            b.pressed.connect(func() -> void: _router.goto(TOWN))
        else:
            b.pressed.connect(func() -> void: _router.push(scene))

    _scene(_frame.scene)
    Frame.standard_chips(_frame, _state)
    _sidebar(Frame.sidebar(_frame))
    _strip(_frame.strip)
    _refresh()


# ---------------------------------------------------------------- scene

func _scene(host: Control) -> void:
    var stage := SceneStage.load("stage_market")
    stage.position = PLATE_OFFSET
    stage.size = host.size - PLATE_OFFSET
    stage.modulate = SCENE_DIM
    host.add_child(stage)

    # The ledger (06 §1): title and subtitle in its own title bar, never on
    # the plate (TOWN-22).
    var panel := Widgets.panel("PanelWarm", LEDGER_PAD)
    panel.name = "Ledger"
    panel.clip_contents = true
    host.add_child(panel)
    panel.position = LEDGER_RECT.position
    panel.size = LEDGER_RECT.size

    var col := Widgets.column(6)
    Widgets.content_of(panel).add_child(col)
    col.add_child(Widgets.label_as("Market", "LabelSection"))
    var tag := Widgets.label_as("Consumables in, salvage out.", "LabelSmall")
    tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tag.custom_minimum_size = Vector2(LEDGER_TEXT_W, 0)
    col.add_child(tag)

    _tab_host = Widgets.column(0)
    _tab_host.name = "Tabs"
    col.add_child(_tab_host)

    _body = Widgets.column(6)
    _body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_body)
    col.add_child(scroll)

    # The vendor's one line back, kept in view under the list rather than at
    # the end of a scroll the player may not be at.
    _notice_label = Widgets.label_as("", "LabelSmall")
    _notice_label.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
    _notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _notice_label.custom_minimum_size = Vector2(0, 18)
    col.add_child(_notice_label)


## The kit's tab row (Widgets.tab_row), rebuilt on every refresh so the active
## plate and its gold underline follow `_active`. The Button texts are the tab
## labels verbatim — the tests press "Buy" and "Comfort" by them.
func _rebuild_tabs() -> void:
    if _tab_host == null:
        return
    for c in _tab_host.get_children():
        _tab_host.remove_child(c)
        c.queue_free()
    var labels: Array = []
    var reasons: Array = []
    var active := 0
    for i in TABS.size():
        labels.append(String(TABS[i]["label"]))
        reasons.append(String(TABS[i]["reason"]))
        if String(TABS[i]["id"]) == _active:
            active = i
    var row := Widgets.tab_row(labels, active, reasons)
    var tabs: Array = Widgets.tabs_of(row)
    for i in tabs.size():
        var b: Button = tabs[i]
        if b == null:
            continue
        # The kit's active plate hugs its word; a tab is a plate, so give
        # each the width and height of one (its text scales inside).
        b.custom_minimum_size = Vector2(TAB_W, TAB_H)
        if b.disabled:
            continue
        var id := String(TABS[i]["id"])
        b.pressed.connect(func() -> void: _select_tab(id))
    _tab_host.add_child(row)


func _select_tab(id: String) -> void:
    _active = id
    _notice = ""
    _confirming = ""
    _refresh()


# ---------------------------------------------------------------- sidebar

## The selection's card first (TOWN-21: the item, where it is, what it fetches,
## and the one crimson commit), then the stall itself: docs/02 §6.2's stock
## model, which exists because "a shop with static infinite stock is a menu; a
## shop whose shelves change is a place". Its level is bought (docs/02 §11,
## docs/15 BL-54), so the rung is sold here too — without it the shelves above
## level 1 are unreachable content.
func _sidebar(host: Control) -> void:
    if host == null:
        return
    var col := Widgets.column(10)
    host.add_child(col)
    _card_host = Widgets.column(0)
    _card_host.name = "ItemCard"
    col.add_child(_card_host)
    _stall_host = Widgets.column(8)
    col.add_child(_stall_host)

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    col.add_child(spacer)

    col.add_child(Widgets.rule())
    # TOWN-31 / CRITIC-C14: the hub's one quiet escape — a Button, so a test
    # that reads it sees Button.text.
    var back := Widgets.button("Back to town")
    back.theme_type_variation = "ButtonQuiet"
    back.pressed.connect(func() -> void:
        if _router != null:
            _router.goto(TOWN))
    col.add_child(back)


func _refresh_stall() -> void:
    if _stall_host == null:
        return
    for c in _stall_host.get_children():
        _stall_host.remove_child(c)
        c.queue_free()
    if _state == null:
        _stall_host.add_child(_wrapped("No guild loaded.", "LabelSmall"))
        return

    var level := Consumables.stall_level(_state.market_tier)
    var top := Buildings.top_level("market")
    # The level shares the title's line: the sidebar has 635px for the card,
    # the stall and the escape, and at text scale 150 every line counts.
    var head := Widgets.row(8)
    var title := Widgets.label_as("The Stall", "LabelSection")
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    head.add_child(title)
    var lvl := Widgets.label_as("Level %d of %d" % [level, top], "LabelMuted")
    lvl.size_flags_vertical = Control.SIZE_SHRINK_END
    head.add_child(lvl)
    _stall_host.add_child(head)
    _stall_host.add_child(_wrapped(Consumables.stall_look(level), "LabelBody"))
    _stall_host.add_child(Widgets.rule())

    if level >= top:
        _stall_host.add_child(_wrapped(
            "The row is covered, the banners are up. Nothing left to build.", "LabelSmall"))
        return
    var cost := Buildings.upgrade_cost("market", level)
    var blocker := Buildings.upgrade_blocker("market", level, _state.gold,
        _state.reputation_rank)
    var rung := Widgets.button("Pay for a better stall — %d G" % cost)
    rung.pressed.connect(func() -> void:
        var problem: String = _state.upgrade_building("market")
        _say(problem if not problem.is_empty()
            else "The stall goes up overnight. New stock with it.")
        _refresh())
    _stall_host.add_child(_reasoned(rung, blocker, SIDEBAR_TEXT_W))
    # LOOP-20: the next level's EFFECT — stock rows, and what reaches the
    # comfort shelf — not a look nothing draws. The look sentence returns only
    # when the market plate carries a layer for that level (W8-FACILITY).
    var next_level := level + 1
    var effect := "Next: level %d — %d stock rows" % [next_level, Consumables.stock_rows(next_level)]
    var shelf: Array = []
    for id in Consumables.comfort_catalogue(next_level):
        if Consumables.comfort_stock_level(String(id)) == next_level:
            shelf.append(String(Comfort.furnishing(String(id)).get("name", id)))
    if not shelf.is_empty():
        effect += ", and the %s on the shelf" % " and the ".join(PackedStringArray(shelf))
    if Cards.scene_has_level_layer("stage_market", "market", next_level):
        effect += ". %s" % Consumables.stall_look(next_level)
    _stall_host.add_child(_wrapped(effect + ".", "LabelSmall"))


## A sidebar line that wraps at the panel's measure instead of running under it.
func _wrapped(text: String, variation: String) -> Label:
    var l := Widgets.label_as(text, variation)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
    return l


## The one disabled-with-reason treatment (CRITIC-G06), with the reason wrapped
## at `width` — `Widgets.reasoned` leaves the wrap to the caller because a
## wrapping Label inside a shrinking box collapses to one letter per line.
func _reasoned(control: Control, reason: String, width: int) -> VBoxContainer:
    var box := Widgets.reasoned(control, reason)
    var why := box.get_node_or_null("Reason")
    if why != null:
        (why as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        (why as Label).custom_minimum_size = Vector2(width, 0)
    return box


# ---------------------------------------------------------------- the card

## The sidebar's item card for the selected sell row: the icon at 2x on a
## rarity-rimmed slot, the name, its slot, "worn by X" / "in the loot window",
## the price, and beneath them the commit. A row in the window sells on the
## crimson button; a worn row's crimson button ASKS (docs/02 §6.3: "so the
## player cannot sell equipped gear without a confirm") and the ask is the
## kit's confirm pair, "Yes — take it off X and sell it" / "Keep it".
func _refresh_card(rows: Array) -> void:
    if _card_host == null:
        return
    for c in _card_host.get_children():
        _card_host.remove_child(c)
        c.queue_free()
    var row := _row_for(rows, _selected)
    if row.is_empty():
        return
    var it = row["item"]
    var worn_by := String(row["worn_by"])
    var price := int(row["price"])
    var key := _row_key(row)

    var card := Widgets.panel("PanelRound", 12)
    card.name = "Card"
    var col := Widgets.column(10)
    Widgets.content_of(card).add_child(col)

    var head := Widgets.row(10)
    head.add_child(_card_icon(it))
    var facts := Widgets.column(2)
    facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var name_l := Widgets.label_as(String(it.name), "LabelBody")
    name_l.name = "CardName"
    name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    name_l.custom_minimum_size = Vector2(CARD_TEXT_W, 0)
    facts.add_child(name_l)
    facts.add_child(_note(Enums.slot_name_of(int(it.slot)), Palette.TEXT_MUTED, "CardSlot"))
    if worn_by.is_empty():
        facts.add_child(_note("in the loot window", Palette.TEXT_MUTED, "CardWhere"))
    else:
        facts.add_child(_note("worn by %s" % worn_by, Palette.CAUTION, "CardWhere"))
    facts.add_child(_note("Sells for %s" % Type.gold(price), Palette.ACCENT_GOLD, "CardPrice"))
    head.add_child(facts)
    col.add_child(head)

    if not worn_by.is_empty() and _confirming == key:
        var rid: String = row["raider_id"]
        var slot: int = int(row["slot"])
        var on_yes := func() -> void:
            var paid: int = _state.sell_equipped(rid, slot)
            _confirming = ""
            _selected = ""
            _say("Sold %s's %s for %d G. They will notice." % [worn_by, it.name, paid])
            _refresh()
        var on_no := func() -> void:
            _confirming = ""
            _refresh()
        var pair := Widgets.confirm_pair(
            "Yes — take it off %s and sell it" % worn_by, "Keep it", on_yes, on_no)
        # The long half wraps inside the card instead of widening the sidebar
        # (LESSONS: one uncapped control in a sidebar breaks the column).
        var yes := pair.find_child("Yes", true, false)
        if yes is Button:
            (yes as Button).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            (yes as Button).custom_minimum_size = Vector2(0, 52)
        col.add_child(pair)
    else:
        var go := Widgets.cta("Sell — %s" % Type.gold(price))
        go.name = "CardSell"
        if worn_by.is_empty():
            var iid: String = it.id
            go.pressed.connect(func() -> void:
                var paid: int = _state.sell_loot(iid)
                _selected = ""
                _say("Sold for %d G." % paid)
                _refresh())
        else:
            go.pressed.connect(func() -> void:
                _confirming = key
                _notice = ""
                _refresh())
        col.add_child(go)
    _card_host.add_child(card)


## The card's slot: the item's icon drawn at exactly 2x (an integer scale keeps
## the pixels square) on the rarity rim.
func _card_icon(it) -> Control:
    var s := Widgets.slot(null, CARD_ICON)
    s.name = "CardIcon"
    s.add_theme_stylebox_override("panel",
        Theme_.flat(Palette.SURFACE_SLOT, _rim_color(it), 2, 4, 0))
    s.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    var centre := CenterContainer.new()
    centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var t := TextureRect.new()
    t.texture = Cards.gear_icon(int(it.slot), true, it)
    t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    t.custom_minimum_size = Vector2(CARD_ICON_PX, CARD_ICON_PX)
    t.mouse_filter = Control.MOUSE_FILTER_IGNORE
    centre.add_child(t)
    s.add_child(centre)
    return s


func _note(text: String, tone: Color, node_name: String = "") -> Label:
    var l := Widgets.label_as(text, "LabelSmall")
    l.add_theme_color_override("font_color", tone)
    if not node_name.is_empty():
        l.name = node_name
    return l


## Canon gives items no rarity of their own — docs/09 grades gear by TIER, and
## the tier is what the rim colour reads: starting gear (tier 0) on the common
## rim, and each raid tier one rung up the same ramp the raiders use.
func _rim_color(it) -> Color:
    return Palette.rarity_color(clampi(int(it.tier), 0, Palette.RARITY.size() - 1))


func _row_key(row: Dictionary) -> String:
    var it = row["item"]
    return "%s:%d:%s" % [String(row["worn_by"]), int(row["slot"]), String(it.id)]


func _row_for(rows: Array, key: String) -> Dictionary:
    if key.is_empty():
        return {}
    for row in rows:
        if _row_key(row) == key:
            return row
    return {}


# ---------------------------------------------------------------- bottom strip

func _strip(host: Control) -> void:
    if _state == null:
        return
    Cards.roster_strip(host, _state, 0)
    Cards.event_log(host, _state)


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
    if _body == null:
        return
    for c in _body.get_children():
        _body.remove_child(c)
        c.queue_free()
    _rebuild_tabs()
    if _frame != null:
        Frame.refresh_chips(_frame, _state)
    if _notice_label != null:
        _notice_label.text = _notice

    if _state == null:
        _body.add_child(Widgets.empty_state("No guild loaded."))
        _refresh_card([])
        _refresh_stall()
        return

    match _active:
        "sell":
            _build_sell()
        "comfort":
            _refresh_card([])
            _build_comfort()
        "buy":
            _refresh_card([])
            _build_buy()
    _refresh_stall()


func _say(text: String) -> void:
    _notice = text


# ---------------------------------------------------------------- Sell

## Two groups (TOWN-28): what the raids brought back, then what the roster is
## wearing — the second behind a toggle while the first has anything in it, so
## the Market's first sentence to a new guild is not "strip your raiders for a
## gold each". With an empty window the worn group is simply open.
func _build_sell() -> void:
    var rows: Array = _state.sell_rows()
    if rows.is_empty():
        _selected = ""
        _refresh_card(rows)
        _body.add_child(Widgets.empty_state(
            "Nothing to sell. Everything the guild owns is being worn or was never found."))
        if not _state.sold_recently.is_empty():
            _body.add_child(Widgets.rule())
            _body.add_child(_buy_back_block())
        return

    var window: Array = []
    var worn: Array = []
    for row in rows:
        if String(row["worn_by"]).is_empty():
            window.append(row)
        else:
            worn.append(row)
    # The window sorts by what it fetches; the roster's gear keeps the
    # roster's order so a raider's kit reads as a set.
    window.sort_custom(func(a, b) -> bool: return int(a["price"]) > int(b["price"]))

    if _row_for(rows, _selected).is_empty():
        _selected = _row_key(window[0]) if not window.is_empty() else _row_key(worn[0])
        _confirming = ""

    _body.add_child(_sell_all_row())
    _body.add_child(Widgets.rule())

    _body.add_child(_group_head("In the window", window.size()))
    if window.is_empty():
        var none := Widgets.empty_state("Nothing found yet — raid first.",
            Icons.at("empty", "shelf"))
        none.size_flags_vertical = Control.SIZE_FILL
        none.custom_minimum_size = Vector2(0, WINDOW_EMPTY_H)
        _body.add_child(none)
    else:
        _body.add_child(_sell_grid(window, "WindowGrid"))

    if not worn.is_empty():
        var open := _worn_open or window.is_empty()
        if open:
            _body.add_child(_group_head("Worn by the roster", worn.size()))
            _body.add_child(_sell_grid(worn, "WornGrid"))
        else:
            var show := Widgets.button("Show worn gear (%d)" % worn.size())
            show.theme_type_variation = "ButtonQuiet"
            show.pressed.connect(func() -> void:
                _worn_open = true
                _refresh())
            _body.add_child(show)

    if not _state.sold_recently.is_empty():
        _body.add_child(Widgets.rule())
        _body.add_child(_buy_back_block())
    _refresh_card(rows)


func _group_head(text: String, count: int) -> Label:
    return Widgets.label_as("%s  ·  %d" % [text, count], "LabelLabel")


## docs/02 §6.3's sell-all helper, with the footer preview §6.3 asks for ("Gold
## before → after") on the button itself, because that is where the decision is made.
func _sell_all_row() -> Control:
    var worth: int = _state.unusable_loot_value()
    var reason := ""
    if worth <= 0:
        reason = "Nothing in the window is useless to everyone."
    var b := Widgets.button("Sell all nobody can wear — %d G  (%d → %d)"
        % [worth, _state.gold, _state.gold + worth])
    # The one wide sentence in the ledger: it never widens the column (LESSONS:
    # one uncapped control breaks every wrapped Label below it). Wrapping zeroes
    # the Button's claimed width and grows the row instead, so at text scale 150
    # the "(before → after)" arithmetic is on a second line, never trimmed.
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.pressed.connect(func() -> void:
        var paid: int = _state.sell_unusable_loot()
        _selected = ""
        _say("Sold the unwearable for %d G." % paid)
        _refresh())
    return _reasoned(b, reason, LEDGER_TEXT_W)


## The grid of one group's rows: six across at text scale 100, fewer as the
## cells widen with the text (`columns_for`).
func _sell_grid(rows: Array, grid_name: String) -> Control:
    var grid := _grid(CELL_W)
    grid.name = grid_name
    for row in rows:
        grid.add_child(_sell_cell(row))
    return grid


## A slot grid whose column count is what the ledger's measure fits at the
## player's text scale.
func _grid(cell_w: int) -> GridContainer:
    var grid := GridContainer.new()
    grid.columns = columns_for(Theme_.scale_of(self), cell_w)
    grid.add_theme_constant_override("h_separation", GRID_GAP)
    grid.add_theme_constant_override("v_separation", GRID_GAP)
    return grid


## How many `cell_w`-wide cells (at text scale `pct`) fit the ledger's body
## with a GRID_GAP between them: 6 of the 76px cells at 100, 4 at 150.
static func columns_for(pct: int, cell_w: int = CELL_W) -> int:
    var w: int = Type.at(cell_w, pct)
    return maxi(1, int((LEDGER_BODY_W + GRID_GAP) / (w + GRID_GAP)))


## A cell's width at the player's text scale.
func _cell_w(cell_w: int) -> int:
    return Type.at(cell_w, Theme_.scale_of(self))


## One item as a slot (06 §2): the icon on a rarity rim, the name under it,
## the row's whole sentence as the Button's text. Pressing a window row selects
## it; pressing a worn row selects it AND asks, because the press IS "Sell X".
func _sell_cell(row: Dictionary) -> Control:
    var it = row["item"]
    var worn_by := String(row["worn_by"])
    var price := int(row["price"])
    var key := _row_key(row)
    var b := Widgets.slot_button("Sell %s — %d G" % [it.name, price],
        Cards.gear_icon(int(it.slot), true, it))
    b.name = "Button"
    # The gear icons are 39px crops and seven of them (the plate chest, the
    # reward trinkets) are opaque to their edge: expanded to the 47px slot they
    # paint over the rim, and the selection cue vanishes on exactly the row the
    # confirm is for. Drawn 1:1 the crop sits inside the rim on every state.
    b.expand_icon = false
    _mute_text(b)
    # KIT-22 / UI-49's sweep (handoff-W6-SHEETS): the kit's two-line plate —
    # the item over its slot and wearer — with `tooltip_text` kept as the
    # same words for the tests and the a11y walk.
    Widgets.tooltip_for(b, String(it.name), "%s%s" % [Enums.slot_name_of(int(it.slot)),
        "" if worn_by.is_empty() else " — worn by %s" % worn_by])
    b.tooltip_text = "%s — %s%s" % [it.name, Enums.slot_name_of(int(it.slot)),
        "" if worn_by.is_empty() else " — worn by %s" % worn_by]
    var selected := key == _selected
    b.add_theme_stylebox_override("normal", Theme_.flat(
        Palette.SURFACE_SLOT_LIT if selected else Palette.SURFACE_SLOT,
        Palette.ACCENT_GOLD if selected else _rim_color(it), 2, 4, 0))
    b.pressed.connect(func() -> void:
        if _selected != key:
            # docs/13 §12.4 `ui.row_select`: the pick, on change only (W6-AUD-BIND).
            var audio: Node = Services.find(self, "Audio")
            if audio != null:
                audio.play("ui.row_select")
        _selected = key
        _confirming = "" if worn_by.is_empty() else key
        _notice = ""
        _refresh())
    return _cell(b, String(it.name), "", _cell_w(CELL_W), "")


## A slot cell: the Button centred over its caption, the caption wrapped at the
## cell's width, the reason (if any) under both in the kit's one treatment.
func _cell(b: Button, caption: String, sub: String, width: int, reason: String) -> Control:
    var col := Widgets.column(2)
    col.custom_minimum_size = Vector2(width, 0)
    b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    col.add_child(b)
    if not caption.is_empty():
        col.add_child(_caption(caption, Palette.TEXT_BODY, width))
    if not sub.is_empty():
        col.add_child(_caption(sub, Palette.TEXT_MUTED, width))
    return _reasoned(col, reason, width)


func _caption(text: String, tone: Color, width: int) -> Label:
    var l := Widgets.label_as(text, "LabelSmall")
    l.add_theme_color_override("font_color", tone)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size = Vector2(width, 0)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l


## The Button keeps its sentence in `text` (the tests read and press it) and
## shows its icon: the caption the player reads is the Label under the slot.
func _mute_text(b: Button) -> void:
    b.clip_text = true
    b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    for key: String in ["font_color", "font_hover_color", "font_pressed_color",
            "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
        b.add_theme_color_override(key, Color(0, 0, 0, 0))


## docs/02 §6.1's buy-back shelf: "the last N sold items ... N = 6. Cheap insurance
## against a mis-sale; costs 1.25x sale price."
func _buy_back_block() -> Control:
    var col := Widgets.column(4)
    col.add_child(Widgets.label_as("Still on the shelf — bought back at %d%% of the sale"
        % _state.buy_back_markup_percent(), "LabelLabel"))
    for item_id in _state.sold_recently:
        var it = _state.content.item(String(item_id)) if _state.content != null else null
        if it == null:
            continue
        var price: int = _state.buy_back_price(String(item_id))
        var reason := ""
        if _state.gold < price:
            reason = "Costs %d G — you have %d." % [price, _state.gold]
        var line := Widgets.row(12)
        line.add_child(_item_slot(it))
        var b := _wide_button("Buy back %s — %d G" % [it.name, price])
        var iid: String = item_id
        b.pressed.connect(func() -> void:
            var problem: String = _state.buy_back(iid)
            _say(problem if not problem.is_empty()
                else "The vendor hands it back without comment.")
            _refresh())
        line.add_child(_reasoned(b, reason, 340))
        col.add_child(line)
    return col


## The 47px slot (06 §2) for a piece of gear on the shelf: the item's art, or
## its slot glyph where canon's seven slots have none.
func _item_slot(it) -> Control:
    var s := Widgets.slot(Cards.gear_icon(int(it.slot), true, it))
    s.add_theme_stylebox_override("panel",
        Theme_.flat(Palette.SURFACE_SLOT, _rim_color(it), 2, 4, 0))
    s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    # KIT-22 / UI-49's sweep (handoff-W6-SHEETS): the two-line plate.
    Widgets.tooltip_for(s, String(it.name), Enums.slot_name_of(int(it.slot)))
    s.tooltip_text = "%s — %s" % [it.name, Enums.slot_name_of(int(it.slot))]
    return s


func _wide_button(text: String) -> Button:
    var b := Widgets.button(text)
    b.custom_minimum_size = Vector2(340, 0)
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    return b


# ---------------------------------------------------------------- Buy

## docs/11 §7's six SKUs as a slot grid (10 §3.6): one row per good, one cell per
## grade the rank stocks. Every tier the rank reaches is offered, because the tier
## IS the upgrade — docs/11 is emphatic that "six is the whole list, forever" —
## and a tier it does not reach is absent, not greyed.
func _build_buy() -> void:
    var top: int = Consumables.top_potion_tier(_state.reputation_rank)
    var rank_name := Enums.reputation_name_of(_state.reputation_rank)
    var intro := Widgets.label_as(
        "Six goods, six grades. %s %s guild's custom reaches grade %s."
            % [_article(rank_name), rank_name, Consumables.TIER_NAMES[top - 1]], "LabelMuted")
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.custom_minimum_size = Vector2(LEDGER_TEXT_W, 0)
    _body.add_child(intro)
    for sku_id in Consumables.SKUS:
        _body.add_child(_sku_block(String(sku_id), top))


func _sku_block(sku_id: String, top_tier: int) -> Control:
    var s := Consumables.sku(sku_id)
    var col := Widgets.column(4)

    var head := Widgets.row(12)
    head.add_child(Widgets.label_as(String(s["name"]), "LabelBody"))
    var rule := Widgets.label_as(String(s["rule"]), "LabelSmall")
    rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rule.size_flags_vertical = Control.SIZE_SHRINK_END
    head.add_child(rule)
    col.add_child(head)

    var grid := _grid(CELL_W)
    grid.name = "BuyGrid"
    var icon := Icons.at("item", sku_id)
    for tier in range(1, top_tier + 1):
        grid.add_child(_buy_cell(sku_id, tier, icon))
    col.add_child(grid)
    return col


## One grade of one good, as a slot: the provision's icon, the count held as a
## corner numeral (06 §2's stack numeral), the grade and price captioned under
## it. The Button's own text is "Minor — 8 G", then "(N held)" on a second
## line, so the tests press it by that fragment and read the count; the reason
## it is shut, when it is, prints beneath at the cell's width.
func _buy_cell(sku_id: String, tier: int, icon: Texture2D) -> Control:
    var price: int = Consumables.price_at(sku_id, tier)
    var held: int = _state.consumable_count(sku_id, tier)
    var reason := ""
    if held >= Consumables.STACK_CAP:
        reason = "The cupboard holds %d." % Consumables.STACK_CAP
    elif _state.gold < price:
        reason = "Costs %d G — you have %d." % [price, _state.gold]

    var caption := "%s — %d G" % [Consumables.TIER_NAMES[tier - 1], price]
    var label := caption
    if held > 0:
        label += "\n(%d held)" % held
    var b := Widgets.slot_button(label, icon)
    b.name = "Button"
    _mute_text(b)
    b.tooltip_text = "%s%s" % [Consumables.display_name(sku_id, tier),
        "" if held == 0 else " — %d in the pack" % held]
    if held > 0:
        b.add_child(_numeral(held))
    b.pressed.connect(func() -> void:
        var problem: String = _state.buy_consumable(sku_id, tier, 1)
        _say(problem if not problem.is_empty()
            else "Wrapped and put in the pack.")
        _refresh())
    # The grade over the price, each on its own line: "Standard — 110 G" does
    # not fit a slot's width at any text scale, and a word cut in half does not
    # read (docs/13 §14).
    return _cell(b, Consumables.TIER_NAMES[tier - 1], "%d G" % price, _cell_w(CELL_W), reason)


## 06 §2's stack numeral: a 12px digit with a 1px outline, bottom-right of the
## slot, on the Button so it never intercepts the click.
func _numeral(n: int) -> Label:
    var l := Widgets.label_as(str(n), "LabelSmall")
    l.name = "Held"
    l.add_theme_font_size_override("font_size", Type.at(Type.STACK, Theme_.scale_of(self)))
    l.add_theme_color_override("font_color", Palette.TEXT_TITLE)
    l.add_theme_color_override("font_outline_color", Palette.SURFACE_SLOT)
    l.add_theme_constant_override("outline_size", 2)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    l.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    l.offset_left = -Widgets.SLOT
    l.offset_top = -Widgets.SLOT
    l.offset_right = -4
    l.offset_bottom = -2
    return l


# ---------------------------------------------------------------- Comfort

## docs/02 §4.2: "Items are bought at the Market (§6) and placed at the Guildhall."
## docs/15 BL-43 makes that one action, so this tab is the Market's entry point to the
## same verb the Guildhall's Facilities tab uses — the rules live in
## `sim/core/Comfort.gd` where both screens read them.
##
## docs/02 §6.2 gates WHICH comfort items the stall carries by market level, which is
## the one thing this tab does that the Guildhall's does not.
func _build_comfort() -> void:
    if _state.roster.is_empty():
        _body.add_child(Widgets.empty_state("Nobody to buy for."))
        return
    if _comfort_target.is_empty():
        _comfort_target = String(_state.roster[0].id)

    var level := Consumables.stall_level(_state.market_tier)
    var rank_name := Enums.reputation_name_of(_state.reputation_rank)
    var intro := Widgets.label_as(
        "The stall carries what %s %s guild's custom is worth."
            % [_article(rank_name).to_lower(), rank_name], "LabelMuted")
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.custom_minimum_size = Vector2(LEDGER_TEXT_W, 0)
    _body.add_child(intro)
    _body.add_child(_target_picker())

    var who = _state.raider(_comfort_target)
    if who == null:
        _body.add_child(Widgets.empty_state("Pick a raider."))
        return

    _body.add_child(Widgets.label_as("Furnishings for %s" % who.display_name, "LabelLabel"))
    var grid := _comfort_grid()
    for id in Comfort.FURNISHINGS:
        grid.add_child(_furnishing_cell(String(id), who, level))
    _body.add_child(grid)
    _body.add_child(Widgets.label_as("For the whole guild", "LabelLabel"))
    var guild := _comfort_grid()
    for id in Comfort.GUILD_FURNISHINGS:
        guild.add_child(_guild_cell(String(id), level))
    _body.add_child(guild)
    _body.add_child(Widgets.label_as("Indulgences", "LabelLabel"))
    for id in Comfort.INDULGENCES:
        _body.add_child(_indulgence_row(String(id), who))


func _comfort_grid() -> GridContainer:
    return _grid(COMFORT_CELL_W)


## Who the purchase is for: 10 §2 R6's portrait mini-grid in place of a row of
## twenty buttons. Two rows of tiles, the chosen one lit, and beneath it canon's
## morale row for that raider (00 §2.1) — number, glyph and band word, never a
## bar — because the morale is the reason anything on this tab gets bought.
func _target_picker() -> Control:
    var col := Widgets.column(6)
    col.add_child(Widgets.label_as("For", "LabelLabel"))

    var n: int = _state.roster.size()
    var grid := GridContainer.new()
    grid.columns = maxi(1, int(ceil(n / 2.0)))
    grid.add_theme_constant_override("h_separation", 7)
    grid.add_theme_constant_override("v_separation", 7)
    for r in _state.roster:
        grid.add_child(_portrait_tile(r))
    col.add_child(grid)

    var who = _state.raider(_comfort_target)
    if who != null:
        var m: int = int(who.morale)
        var line := Widgets.label_as("%s — %d %s"
            % [who.display_name, m, Cards.morale_glyph(self, m)],
            "LabelMorale")
        line.add_theme_color_override("font_color", Palette.morale_color(m))
        col.add_child(line)
        col.add_child(Widgets.label_as("%s — %s"
            % [Enums.class_name_of(who.class_id), who.morale_band_name()], "LabelClass"))
    return col


## One tile of the picker. The Button's text is "<name> <morale>" as it always
## was, so the walker reads the same thing; with a portrait the text is hidden
## behind the face and repeated in the tooltip, without one it shows small.
func _portrait_tile(r) -> Button:
    var selected := String(r.id) == _comfort_target
    var face := _portrait_for(r)
    var b := Widgets.slot_button("%s %d" % [r.display_name, r.morale], face, TILE)
    b.theme_type_variation = "ButtonPortrait" if selected else "ButtonMini"
    b.clip_text = true
    b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if face != null:
        b.add_theme_color_override("font_color", Color(0, 0, 0, 0))
    else:
        b.add_theme_font_size_override("font_size", Type.at(Type.STACK, Theme_.scale_of(self)))
    b.modulate = Color.WHITE if selected else Color(1, 1, 1, 0.7)
    b.tooltip_text = "%s — %d %s" % [r.display_name, r.morale, r.morale_band_name()]
    var rid: String = r.id
    b.pressed.connect(func() -> void:
        _comfort_target = rid
        _notice = ""
        _refresh())
    return b


## Cards' by-name fallback first, then the class portrait set that is being
## produced alongside this pass (guarded: it may not be there yet).
func _portrait_for(r) -> Texture2D:
    var face := Cards.portrait_for(r)
    if face != null:
        return face
    var by_class := PORTRAIT + "class_%s.png" % Enums.class_key(int(r.class_id))
    if ResourceLoader.exists(by_class):
        return load(by_class)
    return null


## A furnishing in a slot: its icon (W1-ICONS' furnishing grid), the name and
## "+floor · price" under it, the reason it cannot be bought beneath that. The
## Button's text is the row's old sentence so "Straw Cot" is still pressable.
func _furnishing_cell(id: String, who, level: int) -> Control:
    var f := Comfort.furnishing(id)
    var reason := Consumables.stock_blocker(id, level)
    if reason.is_empty():
        reason = _placement_reason(id, who)
    var b := Widgets.slot_button("%s  +%d  ·  %d G"
        % [String(f["name"]), int(f["floor"]), int(f["price"])], Icons.at("furnishing", id))
    b.name = "Button"
    _mute_text(b)
    b.tooltip_text = String(f.get("blurb", f["name"]))
    var rid: String = who.id
    b.pressed.connect(func() -> void:
        var problem: String = _state.buy_furnishing(id, rid)
        _say(problem if not problem.is_empty()
            else "Sent up to the Guildhall and put in place.")
        _refresh())
    return _cell(b, String(f["name"]), "+%d  ·  %d G" % [int(f["floor"]), int(f["price"])],
        _cell_w(COMFORT_CELL_W), reason)


## The same refusal the state will produce, computed here so the button and the
## outcome cannot disagree.
func _placement_reason(id: String, who) -> String:
    var held: Array = _state.placed_for(who.id)
    var slot := Comfort.furnishing_slot(id)
    for other in held:
        if Comfort.furnishing_slot(String(other)) == slot:
            if String(other) == id:
                return "%s already has one." % who.display_name
            var mine := int(Comfort.furnishing(id).get("floor", 0))
            var theirs := int(Comfort.furnishing(String(other)).get("floor", 0))
            if mine <= theirs:
                return "The %s they already have is no worse." % \
                    String(Comfort.furnishing(String(other))["name"])
            return ""
    var blocker := Comfort.placement_blocker(id, held, _state.facility_tier, who)
    if not blocker.is_empty():
        return blocker
    var price := Comfort.furnishing_price(id)
    if _state.gold < price:
        return "Costs %d G — you have %d." % [price, _state.gold]
    return ""


func _guild_cell(id: String, level: int) -> Control:
    var f := Comfort.furnishing(id)
    var reason := Consumables.stock_blocker(id, level)
    if reason.is_empty():
        if _state.guild_furnishings.has(id):
            reason = "The guild already has that standing order."
        elif _state.gold < int(f["price"]):
            reason = "Costs %d G — you have %d." % [int(f["price"]), _state.gold]
    var b := Widgets.slot_button("%s  +%d each  ·  %d G"
        % [String(f["name"]), int(f["floor"]), int(f["price"])], Icons.at("furnishing", id))
    b.name = "Button"
    _mute_text(b)
    b.tooltip_text = String(f.get("blurb", f["name"]))
    b.pressed.connect(func() -> void:
        var problem: String = _state.buy_guild_furnishing(id)
        _say(problem if not problem.is_empty()
            else "The standing order is placed. The whole guild eats.")
        _refresh())
    return _cell(b, String(f["name"]), "+%d each  ·  %d G" % [int(f["floor"]), int(f["price"])],
        _cell_w(COMFORT_CELL_W), reason)


## The indulgence has no slot art (it is a token, not a thing in the quarters),
## so it stays a wide button with its reason under it.
func _indulgence_row(id: String, who) -> Control:
    var item := Comfort.indulgence(id)
    var reason := ""
    if _state.gold < int(item["price"]):
        reason = "Costs %d G — you have %d." % [int(item["price"]), _state.gold]
    elif _state.indulgences_today >= Comfort.indulgence_cap(_state.roster.size()):
        reason = "Sold out for today."
    var b := _wide_button("%s for %s  ·  %d G"
        % [String(item["name"]), who.display_name, int(item["price"])])
    var rid: String = who.id
    b.pressed.connect(func() -> void:
        var problem: String = _state.use_indulgence(id, rid)
        _say(problem if not problem.is_empty()
            else "Sent round to the Guildhall with the water still hot.")
        _refresh())
    return _reasoned(b, reason, 340)


## "An Unknown guild", "A Known guild": the rank names are canon and two of
## the six start with a vowel.
func _article(word: String) -> String:
    return "An" if word.length() > 0 and word[0].to_lower() in ["a", "e", "i", "o", "u"] else "A"


func active_tab() -> String:
    return _active


## The key of the sell row the sidebar card describes (tests/unit/test_market_grid.gd).
func selected_row() -> String:
    return _selected
