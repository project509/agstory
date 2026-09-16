extends Control
## S05 — one raider, in full (docs/13 §5, docs/02 §4.5).
##
## docs/13 §5 gives this screen four contents and one action: "gear paper-doll,
## backstory bullets, wishlist, morale history", and "Equip / apply comfort item".
##
## Three of the four are here: the paper-doll, the backstory bullets (every
## raider draws theirs from `data/backstories.json` — starters on day one,
## recruits at the Tavern) and the morale history, the thirty-day log read as a
## trend. The wishlist is out of 1.0 (docs/16 C3; ship plan §6 #59) and this
## screen prints nothing about it — the field stays serialised for the day it
## is in. Beside the history stands docs/02 §4.5's baseline arithmetic, in the
## guild's own words with the sum as its tooltip (UI-27), which explains where
## this raider's morale is HEADING and what each purchase moved.
##
## docs/13 OQ-4 splits comfort items between here and the roster row: "Allow a
## quick-apply from the Roster row's context action, with the full slot view in Raider
## Detail." This is the full slot view; the roster row carries the quick-apply, and
## the sidebar here repeats it so the two-click repair is never further than one
## screen away.
##
## The art pass puts this on the dashboard frame as archetype C (10 §3.5): the
## Roster rail item lit, the bare camp dimmed behind two panels (docs/15 BL-78,
## the Guildhall's framing) — the kit on the left as Concept 2's slot grid
## (`game/ui/PaperDoll.gd`, HALL-07) over a legend and the gear totals, Quarters
## and what is written down on the right — and the headline card in the
## sidebar with the morale record under it (HALL-09). None of the concepts
## show anything below the card, so everything else is invented inside the
## kit's language and nothing else.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Type = preload("res://game/ui/Type.gd")
const Icons = preload("res://game/ui/Icons.gd")
const PaperDoll = preload("res://game/ui/PaperDoll.gd")
const Services = preload("res://game/core/Services.gd")
const GuildhallScript = preload("res://game/screens/Guildhall.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Comfort = preload("res://sim/core/Comfort.gd")
const Economy = preload("res://sim/core/Economy.gd")

const GUILDHALL := "res://game/screens/Guildhall.tscn"
const TOWN := "res://game/screens/Town.tscn"
const PORTRAIT := "res://game/assets/portraits/"

## docs/13 OQ-4's quick-apply is the +8 spike, not a piece of furniture — the same
## indulgence the roster row offers, so the two buttons never disagree.
const QUICK_INDULGENCE := "hot_bath"

## The rail (00 §2.6), as Town.gd lists it. Camp is the root of the stack.
const RAIL := [
	{"id": "home", "label": "Camp", "scene": TOWN},
	{"id": "tavern", "label": "Tavern", "scene": "res://game/screens/Tavern.tscn"},
	{"id": "roster", "label": "Roster", "scene": GUILDHALL},
	{"id": "market", "label": "Market", "scene": "res://game/screens/Market.tscn"},
	{"id": "board", "label": "Adventure's Board", "scene": "res://game/screens/AdventureBoard.tscn"},
	{"id": "options", "label": "Options", "scene": "res://game/screens/Settings.tscn"},
]

## Scene-local geometry. The framed scene is 929x640 (01 §1); two PanelWarm
## columns sit on it with the plate's margin kept clear on every side. Text
## widths subtract the panel pad and the 9-slice's own 14px content margin.
const PANEL_Y := 12
const PANEL_H := 616
const PANEL_PAD := 10
const LEFT_X := 14
const LEFT_W := 466
const RIGHT_X := 492
const RIGHT_W := 423
const LEFT_TEXT_W := LEFT_W - 2 * (PANEL_PAD + 14)
const RIGHT_TEXT_W := RIGHT_W - 2 * (PANEL_PAD + 14)
const SIDE_TEXT_W := 314
## The gear totals under the doll: one cell per stat, 27px tall (HALL-08).
const STAT_CELL_H := 27
## Text widths inside the two scrolled columns (`_scrolled`): the kit's 8px
## scrollbar plus its track margins must fit beside the text when it appears
## at 150%, or the column widens past the panel's pad.
const SCROLL_BAR_W := 10
const LEGEND_TEXT_W := LEFT_TEXT_W - SCROLL_BAR_W
const RECORD_TEXT_W := SIDE_TEXT_W - SCROLL_BAR_W

var _router = null
var _state = null
var _who = null
var _frame = null
var _left: VBoxContainer = null
var _right: VBoxContainer = null
var _side: VBoxContainer = null
var _strip: Control = null
var _notice := ""
var _confirming := false
var _page := 0
var _paged := false
var _built := false


func _ready() -> void:
	build()


## Idempotent and public, for the same reason Town.build() is: the router and
## the test runner mount screens on roots where `_ready` may never fire.
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
		if _router == null or not _router.screen_exists(scene):
			reason = "Not built in this version yet."
		nav.append({"id": item["id"], "label": item["label"], "reason": reason})

	_frame = Frame.build(self, {"nav": nav, "active": "roster", "framed": true})
	for item in RAIL:
		var scene := String(item["scene"])
		var b: Button = _frame.nav_buttons.get(String(item["id"]))
		if b == null or b.disabled:
			continue
		if scene == TOWN:
			b.pressed.connect(func() -> void: _router.goto(scene))
		else:
			b.pressed.connect(func() -> void: _router.push(scene))

	_scene(_frame.scene)
	Frame.standard_chips(_frame, _state)
	var side := Frame.sidebar(_frame)
	if side != null:
		# 12px of air between the sidebar's rows: the record under the card
		# reads as a list, not a paragraph.
		_side = Widgets.column(12)
		_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
		side.add_child(_side)
	_strip = _frame.strip
	_refresh()


# ---------------------------------------------------------------- the frame

## The camp you are standing in — the bare plate at the Guildhall's framing
## (docs/15 BL-78; this screen is pushed from the roster and returns to it, so
## the ground must not move) — dimmed so the two panels on it are what gets
## read (09 §1.3). Both panels are placed explicitly — Frame.gd's header
## explains why anchors are not used on the scene host.
func _scene(host: Control) -> void:
	var fr: Dictionary = GuildhallScript.framing()
	var offset: Vector2 = fr["offset"]
	var dim: Color = fr["dim"]
	var stage: Control = GuildhallScript.bare_stage(self, GuildhallScript.CAMP_SCENE)
	stage.position = offset
	stage.size = host.size - offset
	stage.modulate = dim
	host.add_child(stage)

	var left := Widgets.panel("PanelWarm", PANEL_PAD)
	host.add_child(left)
	left.position = Vector2(LEFT_X, PANEL_Y)
	left.size = Vector2(LEFT_W, PANEL_H)
	left.clip_contents = true
	_left = Widgets.column(10)
	Widgets.content_of(left).add_child(_left)

	var right := Widgets.panel("PanelWarm", PANEL_PAD)
	host.add_child(right)
	right.position = Vector2(RIGHT_X, PANEL_Y)
	right.size = Vector2(RIGHT_W, PANEL_H)
	right.clip_contents = true
	# Quarters plus the record can outgrow the panel once the Market stocks the
	# whole furnishing list, so this column scrolls rather than grows. It also
	# fills the panel when short, so the record's empty state can centre itself
	# in the space that is left (KIT-08).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Widgets.content_of(right).add_child(scroll)
	_right = Widgets.column(8)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_right)


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	for host in [_left, _right, _side]:
		if host == null:
			continue
		for c in host.get_children():
			host.remove_child(c)
			c.queue_free()
	if _strip != null:
		for c in _strip.get_children():
			_strip.remove_child(c)
			c.queue_free()

	_who = null
	if _state != null:
		_who = _state.raider(_state.selected_raider_id)
		if _who == null and not _state.roster.is_empty():
			_who = _state.roster[0]

	if _who == null:
		_nobody()
		_fill_strip()
		return

	if _left != null:
		_kit(_left)
	if _right != null:
		_quarters(_right)
		_right.add_child(Widgets.rule())
		_written(_right)
	if _side != null:
		_sidebar(_side)
	_fill_strip()


## The roster is where a raider is picked; with nobody in the guild this screen
## still has to be a screen, and it still has to have a way out.
func _nobody() -> void:
	if _left != null:
		_left.add_child(Widgets.label_as("Kit", "LabelSectionSm"))
		_left.add_child(Widgets.empty_state(
			"There is no kit to show. This guild has nobody in it.",
			Icons.at("empty", "shelf")))
	if _right != null:
		_right.add_child(Widgets.label_as("On record", "LabelSectionSm"))
		_right.add_child(Widgets.empty_state(
			"Nothing on record. Recruits are found at the Tavern.",
			Icons.at("empty", "quill")))
	if _side != null:
		_side.add_child(Widgets.label_as("Nobody selected", "LabelSection"))
		var why := Widgets.label_as(
			"The roster is where a raider is picked. This guild has nobody in it.",
			"LabelSmall")
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(SIDE_TEXT_W, 0)
		_side.add_child(why)
		_side.add_child(_spacer())
		_side.add_child(_back_button())


func _say(text: String) -> void:
	_notice = text


func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _back_button() -> Button:
	var back := Widgets.button("Back to the roster")
	back.pressed.connect(func() -> void:
		if _router != null:
			_router.goto(GUILDHALL))
	return back


## A left-aligned line of quiet prose inside a list — the record's "not written
## yet" admissions. Wraps to the column it sits in.
func _note(text: String, width: int) -> Label:
	var l := Widgets.label_as(text, "LabelSmall")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


## A column that takes whatever height its panel has left and scrolls past
## it — with the kit's visible 8px bar (W1-CHROME's VScrollBar) so a list
## that scrolls SAYS so. At 100% text the content fits and there is no bar; at
## 150% the legend and the record grow past their panels and the bar appears
## instead of a footer button vanishing under the rim. Returns the scroll; the
## column inside is `body_of(scroll)`.
func _scrolled(gap: int) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	var body := Widgets.column(gap)
	body.name = "Body"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	return scroll


func _body_of(scroll: ScrollContainer) -> VBoxContainer:
	return scroll.get_node("Body") as VBoxContainer


## spec 06 §8's tooltip: a title line over a body line. `tooltip_text` carries
## both until `Widgets.tooltip_for` (KIT-22, W3-KIT2) draws them as two
## styles — handoff-W3-DETAIL switches the call.
func _tip(title: String, body: String) -> String:
	return "%s\n%s" % [title, body] if not body.is_empty() else title


# ---------------------------------------------------------------- who this is

## ✅ CANON's roster line, in the shape the roster mock-up prints it:
##
##     Natsuna — 87 ❤️
##     Shaman — Very Happy
##
## The sidebar is the headline card (10 §3.5): name, the two canon lines, the
## rarity and the one number that says how good they are, then the actions,
## then the morale record (HALL-09: the reference's sidebar is its densest
## region, and this one used to stop at Dismiss).
func _sidebar(col: VBoxContainer) -> void:
	col.add_child(Widgets.label_as("Raider", "LabelSection"))

	var card := Widgets.panel("PanelCard", 14)
	var c := Widgets.column(4)
	c.add_child(Widgets.label_as(String(_who.display_name), "LabelName"))
	var morale := Widgets.label_as("%s — %d %s"
		% [_who.display_name, _who.morale,
			Cards.morale_glyph(self, int(_who.morale))], "LabelMorale")
	morale.add_theme_color_override("font_color", Palette.morale_color(_who.morale))
	c.add_child(morale)
	c.add_child(Widgets.label_as("%s — %s"
		% [Enums.class_name_of(_who.class_id), _who.morale_band_name()], "LabelClass"))
	var meta := _note("%s  ·  %s" % [Enums.rarity_name_of(_who.rarity),
		_competence_line()], SIDE_TEXT_W - 30)
	c.add_child(meta)
	Widgets.content_of(card).add_child(c)
	col.add_child(card)

	if not _notice.is_empty():
		var line := _note(_notice, SIDE_TEXT_W)
		line.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
		col.add_child(line)

	col.add_child(_quick_apply())
	col.add_child(_dismiss_block())
	col.add_child(Widgets.rule())
	var record := _scrolled(12)
	_history(_body_of(record))
	col.add_child(record)
	col.add_child(_back_button())


## docs/05 §5's mistake chance, which is the only number that says how good this raider
## actually is. Printed because it is the thing morale is FOR.
func _competence_line() -> String:
	var Formulas = load("res://sim/core/Formulas.gd")
	var chance: float = Formulas.mistake_chance(_who.rarity, _who.morale)
	return "misses about %.0f%% of the time" % (chance * 100.0)


## docs/13 OQ-4's quick-apply, the same button the roster row carries and for
## the same reasons (Roster.gd). docs/13 §7: a disabled control says why — the
## kit's one treatment (`Widgets.reasoned`, CRITIC-G06): dimmed, the padlock
## in the leading slot, the reason in CAUTION under it.
func _quick_apply() -> Control:
	# No morale gate (LOOP-16, the same predicate the Roster's row and the
	# Market use): the price and the day's cap; a bath that would not land is
	# refused by `GameState.use_indulgence`'s sentence on the press.
	var reason := ""
	var price: int = Comfort.indulgence_price(QUICK_INDULGENCE)
	if _state.gold < price:
		reason = "Costs %d G." % price
	elif _state.indulgences_today \
			>= Comfort.indulgence_cap(_state.roster.size()):
		reason = "Sold out today."
	var b := Widgets.button("Cheer up")
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var glyph: Texture2D = Icons.at("lock", "16") if not reason.is_empty() else null
	var box := Widgets.reasoned(b, reason, glyph)
	var rid: String = _who.id
	b.pressed.connect(func() -> void:
		var problem: String = _state.use_indulgence(QUICK_INDULGENCE, rid)
		_say(problem if not problem.is_empty()
			else "Sent up with the water still hot.")
		_refresh())
	return box


## Letting somebody go, as the Tavern's Manage tab does it: the kit's confirm
## pair (`Widgets.confirm_pair`, CRITIC-G05) that names the consequence
## (docs/02 §5.3) with the number the sim really applies; "Keep them" is the
## default focus.
func _dismiss_block() -> Control:
	if not _confirming:
		var b := Widgets.button("Dismiss")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			_confirming = true
			_notice = ""
			_refresh())
		return b

	var box := Widgets.column(6)
	box.add_child(_note(
		"Letting somebody go costs the people who stay. It always does.", SIDE_TEXT_W))
	var cost := ""
	if Morale.trigger_exists("peer_dismissed"):
		cost = " (%+d morale to everyone else)" % int(Morale.trigger_delta("peer_dismissed"))
	var rid: String = _who.id
	var who_name: String = _who.display_name
	var pair := Widgets.confirm_pair("Yes — let them go%s" % cost, "Keep them",
		func() -> void:
			var problem: String = _state.dismiss_raider(rid)
			_confirming = false
			if problem.is_empty() and _router != null:
				_router.goto(GUILDHALL)
				return
			_say(problem if not problem.is_empty()
				else "%s clears out. The others notice." % who_name)
			_refresh(),
		func() -> void:
			_confirming = false
			_refresh())
	var yes: Node = pair.find_child("Yes", true, false)
	if yes is Button:
		# The consequence clause is long: at the kit's meta size (through the
		# text-scale door, CRITIC-G15) it wraps to a second line INSIDE its
		# plate rather than widening the sidebar's column — one uncapped
		# control widens the column and clips every wrapped Label under it
		# (LESSONS; seen on the first Dismiss shot). Two lines of height.
		var yb := yes as Button
		var fs: int = Type.at(Widgets.SIZE_META, Theme_.scale_of(self))
		yb.add_theme_font_size_override("font_size", fs)
		yb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		yb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		yb.custom_minimum_size = Vector2(0, int(fs * 2.6) + 12)
	box.add_child(pair)
	return box


# ---------------------------------------------------------------- gear

## Who this is, as a picture. The reference supplies four faces by name; the
## class portrait set is produced in parallel, so it is looked up but never
## assumed (07/08-assets-sheet-*.md).
func _portrait() -> Texture2D:
	var tex := Cards.portrait_for(_who)
	if tex != null:
		return tex
	var by_class := PORTRAIT + "class_%s.png" % _who.class_key()
	if ResourceLoader.exists(by_class):
		return load(by_class)
	return null


## docs/13 §5's "gear paper-doll", on Concept 2's slot grid (06 §2, HALL-07):
## the doll (`PaperDoll.build`) — every slot this class can fill with what is
## in it — over the gear totals (HALL-08) and a legend that names each slot,
## what is worn and what it is worth, and — the part that makes it a screen
## rather than a list — what in the loot window would be better, with the
## delta docs/09 §14 wants on the control.
func _kit(col: VBoxContainer) -> void:
	col.add_child(Widgets.label_as("Kit", "LabelSectionSm"))
	var db = _state.content
	if db == null:
		col.add_child(Widgets.empty_state("Content is not loaded.", Icons.at("empty", "shelf")))
		return
	var cd = db.class_of(_who.class_id)
	if cd == null:
		var head := Widgets.row(12)
		head.add_child(PaperDoll.build(_portrait(), {}, self))
		col.add_child(head)
		col.add_child(Widgets.empty_state("This class has no equipment profile.",
			Icons.at("empty", "shelf")))
		return

	var cells: Dictionary = {}
	for slot in cd.available_slots():
		cells[int(slot)] = _cell(db, int(slot))
	col.add_child(PaperDoll.build(_portrait(), cells, self))
	col.add_child(_totals(db))
	col.add_child(Widgets.rule())
	var legend := _scrolled(10)
	var body := _body_of(legend)
	for slot in cd.available_slots():
		body.add_child(_legend_row(db, int(slot)))
	body.add_child(Widgets.rule())
	body.add_child(_kit_summary(db, cd))
	col.add_child(legend)


## The kit in one line under the legend: how much of the class's slot set is
## filled and what the Market would pay for all of it (`Economy.sell_price`,
## the same number the legend prints per item).
func _kit_summary(db, cd) -> Control:
	var slots: Array = cd.available_slots()
	var filled := 0
	var worth := 0
	for slot in slots:
		var worn = _who.item_in(db, int(slot))
		if worn != null:
			filled += 1
			worth += Economy.sell_price(worn, _state.reputation_rank)
	var line := _note("%d of %d slots filled  ·  the whole kit would fetch %d G at the Market"
		% [filled, slots.size(), worth], LEGEND_TEXT_W)
	line.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	return line


## One doll cell: the icon (the worn item's, or the slot's own glyph for an
## empty one — `Cards.gear_icon` resolves per slot and per the item's family,
## tools/aseprite/gen_items.lua), and the two-line tooltip.
func _cell(db, slot: int) -> Dictionary:
	var worn = _who.item_in(db, slot)
	var title := "%s — %s" % [Enums.slot_name_of(slot), worn.name if worn != null else "empty"]
	var body := ""
	if worn != null:
		body = "worth %d G" % Economy.sell_price(worn, _state.reputation_rank)
	elif slot == Enums.Slot.MAIN_HAND:
		body = "no weapon"
	else:
		body = "nothing worn here"
	return {
		"icon": Cards.gear_icon(slot, worn != null, worn),
		"worn": worn != null,
		"tooltip": _tip(title, body),
	}


## The gear totals as a strip of cells under the doll (HALL-08): HP is the
## raider's real maximum (base by class and rarity, plus gear —
## `Raider.max_hp`), the rest are what the gear ADDS and carry their sign, so
## "+0 Power" reads as "nothing worn adds power" and never as a broken stat;
## an empty main hand says "no weapon" where the damage bonus would be. A
## flow, not a row: at 150% text the five cells take two lines (docs/13 §14
## reflows by rows and never truncates a value).
func _totals(db) -> Control:
	var stats = _who.gear_stats(db)
	var row := HFlowContainer.new()
	row.name = "Totals"
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	var damage := "no weapon"
	if _who.item_in(db, Enums.Slot.MAIN_HAND) != null:
		damage = "%+d Damage" % stats.damage
	for text in ["%d HP" % _who.max_hp(db), "%+d AC" % stats.ac, "%+d Power" % stats.power,
			"%+d Mana" % stats.mana, damage]:
		row.add_child(_stat_cell(String(text)))
	return row


func _stat_cell(text: String) -> Control:
	var cell := Widgets.panel("PanelInset", 4)
	cell.custom_minimum_size = Vector2(0, STAT_CELL_H)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := Widgets.label_as(text, "LabelLevel")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Widgets.content_of(cell).add_child(l)
	return cell


## One legend row under the doll (HALL-07): the slot's name, what is in it and
## what that is worth, in LabelSmall — so "worth", "empty" and the slot names
## stay readable words — and the upgrade button when the loot window holds a
## better fit.
func _legend_row(db, slot: int) -> Control:
	var row := Widgets.row(8)
	row.name = "Legend_%s" % Enums.slot_key(slot)
	var worn = _who.item_in(db, slot)

	var name := Widgets.label_as("%s —" % Enums.slot_name_of(slot), "LabelSmall")
	name.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name)
	if worn != null:
		var item := Widgets.label_as(worn.name, "LabelSmall")
		item.add_theme_color_override("font_color", Palette.TEXT_BODY)
		item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(item)
		var worth := Widgets.label_as("· worth %d G"
			% Economy.sell_price(worn, _state.reputation_rank), "LabelSmall")
		worth.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		worth.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(worth)
	else:
		var empty := Widgets.label_as("empty", "LabelSmall")
		empty.add_theme_color_override("font_color", Palette.CAUTION)
		empty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(empty)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)

	var candidate = _best_candidate(db, slot, worn)
	if candidate != null:
		var delta := _delta_line(db, worn, candidate)
		var b := Widgets.button("Equip %s%s" % [candidate.name, delta])
		b.add_theme_font_size_override("font_size",
			Type.at(Widgets.SIZE_META, Theme_.scale_of(self)))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var item_id: String = candidate.id
		b.pressed.connect(func() -> void:
			if _state.assign_loot(item_id, _who.id):
				_say("%s puts it on." % _who.display_name)
			else:
				_say("It does not fit them.")
			_refresh())
		row.add_child(b)
	return row


## The best thing in the loot window this raider could put in that slot. "Best" is the
## same `item_worth` the Suggested split uses (docs/15 BL-33), so the screen and the
## one-click helper never disagree about which item is the upgrade.
func _best_candidate(db, slot: int, worn):
	var Loot = load("res://sim/core/Loot.gd")
	var best = null
	var best_worth := -1
	for it in _state.pending_loot:
		if it.slot != slot or not it.can_be_used_by(_who.class_id):
			continue
		var worth: int = Loot.item_worth(it)
		if worn != null and worth <= Loot.item_worth(worn):
			continue
		if worth > best_worth:
			best = it
			best_worth = worth
	return best


func _delta_line(db, worn, candidate) -> String:
	var Loot = load("res://sim/core/Loot.gd")
	if worn == null:
		return "  (+%d)" % Loot.item_worth(candidate)
	return "  (+%d)" % (Loot.item_worth(candidate) - Loot.item_worth(worn))


# ---------------------------------------------------------------- quarters

## docs/13 OQ-4's "full slot view", and docs/02 §4.5's arithmetic strip — the one thing
## on this screen that explains a number rather than showing it.
func _quarters(col: VBoxContainer) -> void:
	col.add_child(Widgets.label_as("Quarters", "LabelSectionSm"))

	var tier: int = _state.facility_tier
	var baseline: int = Morale.baseline_of(_who, tier)
	# One Label at the kit's meta size (HALL-26), in the guild's own voice
	# (UI-27): "Settles at 45 — Common, no furnishings." The arithmetic —
	# docs/02 §4.5's `50 + rarity + facility + items = baseline` strip — is the
	# tooltip, where a player who wants the sum can read it; the Facilities
	# tab prints the strip in full because there it is the purchase pitch.
	var terms := "%d base %+d %s %+d Guildhall %+d furnishings" % [
		Morale.BASE_BASELINE, Morale.RARITY_OFFSET[_who.rarity],
		Enums.rarity_name_of(_who.rarity), Morale.facility_bonus_for(tier),
		int(_who.comfort_floor)]
	if int(_who.backstory_offset) != 0:
		terms += " %+d their past" % int(_who.backstory_offset)
	var sum := Widgets.label_as(_settles_line(baseline, tier), "LabelSmall")
	sum.name = "Settles"
	sum.add_theme_color_override("font_color", Palette.TEXT_BODY)
	sum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sum.custom_minimum_size = Vector2(RIGHT_TEXT_W, 0)
	sum.mouse_filter = Control.MOUSE_FILTER_STOP
	Widgets.tooltip_for(sum, "How it adds up", "%s = %d baseline" % [terms, baseline])
	col.add_child(sum)

	var days: int = Morale.rest_ticks_for(_who, tier)
	if days > 0:
		col.add_child(Widgets.label_as("%d day%s of rest from settled."
			% [days, "" if days == 1 else "s"], "LabelSmall"))
	else:
		col.add_child(Widgets.label_as("Settled, or better.", "LabelSmall"))

	var held: Array = _state.placed_for(_who.id)
	var slots: int = Comfort.slots_for(tier)
	var lines: Array = []
	for id in held:
		var f := Comfort.furnishing(String(id))
		lines.append("%s (+%d)" % [String(f["name"]), int(f["floor"])])
	for i in range(held.size(), slots):
		lines.append("empty")
	col.add_child(_note("Slots: %s" % ", ".join(PackedStringArray(lines)), RIGHT_TEXT_W))

	for id in Comfort.FURNISHINGS:
		var box := _furnishing_row(String(id))
		if box != null:
			col.add_child(box)
	for id in Comfort.INDULGENCES:
		col.add_child(_indulgence_row(String(id)))


## Only what is actually placeable is offered here. This is a detail screen, not a
## shop: the Market is where the whole catalogue lives, and repeating it would bury the
## one item that would help.
func _furnishing_row(id: String) -> Control:
	var Consumables = load("res://sim/core/Consumables.gd")
	var level: int = Consumables.stall_level(_state.market_tier)
	if not Consumables.stock_blocker(id, level).is_empty():
		return null
	var f := Comfort.furnishing(id)
	var blocker := Comfort.placement_blocker(
		id, _state.placed_for(_who.id), _state.facility_tier, _who)
	if blocker.is_empty() and _state.gold < int(f["price"]):
		blocker = "Costs %d G — you have %d." % [int(f["price"]), _state.gold]
	if not blocker.is_empty() and not blocker.contains("Costs"):
		return null
	var box := Widgets.button_with_reason("%s  +%d  ·  %d G"
		% [String(f["name"]), int(f["floor"]), int(f["price"])], blocker)
	var b := Widgets.button_of(box)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# LOOP-29 / W7-PREP: the same icon the Market's shelf shows for this
	# furnishing, in the Button's leading slot; the text stays verbatim.
	b.icon = Icons.at("furnishing", id)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.expand_icon = false
	b.pressed.connect(func() -> void:
		var problem: String = _state.buy_furnishing(id, _who.id)
		_say(problem if not problem.is_empty()
			else "%s is delivered to their room." % String(f["name"]))
		_refresh())
	return box


func _indulgence_row(id: String) -> Control:
	var item := Comfort.indulgence(id)
	var reason := ""
	if _state.gold < int(item["price"]):
		reason = "Costs %d G — you have %d." % [int(item["price"]), _state.gold]
	elif _state.indulgences_today >= Comfort.indulgence_cap(_state.roster.size()):
		reason = "Sold out for today."
	var box := Widgets.button_with_reason("%s  ·  %d G"
		% [String(item["name"]), int(item["price"])], reason)
	var b := Widgets.button_of(box)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func() -> void:
		var problem: String = _state.use_indulgence(id, _who.id)
		_say(problem if not problem.is_empty()
			else "They come back looking almost cheerful.")
		_refresh())
	return box


# ---------------------------------------------------------------- the record

## The baseline in the guild's own voice (UI-27): where this raider settles,
## and the two things a player can see that decide it — rarity and what is
## in their quarters. "Common, no furnishings" / "Common, one furnishing" /
## "Uncommon, two furnishings"; the Guildhall's own bonus is the hall's and
## the backstory's is theirs, both in the tooltip's arithmetic.
func _settles_line(baseline: int, tier: int) -> String:
	var held: int = _state.placed_for(_who.id).size()
	var room := "no furnishings"
	if held == 1:
		room = "one furnishing"
	elif held > 1:
		room = "%d furnishings" % held
	var hall := ""
	if Morale.facility_bonus_for(tier) > 0:
		hall = ", a %s" % Comfort.level_name(tier).to_lower()
	return "Settles at %d — %s, %s%s." % [
		baseline, Enums.rarity_name_of(_who.rarity), room, hall]


## docs/13 §5's backstory bullets, under Quarters. A starter draws theirs on
## day one (`StartingRoster.build`, LOOP-17) and a recruit at the Tavern
## (docs/04 §5 step 7), so a raider with none is the rare case — a stub, an
## old save — and the empty state says only that: nothing is written down.
## No sentence about when a backstory "arrives" and none about wishlists at
## all (UI-27, C12-C14): wishlists are out of 1.0 (docs/16 C3, ship plan §6
## #59) and the field stays serialised for the day they are in; a panel that
## promised them would be the one line on this screen that lied.
func _written(col: VBoxContainer) -> void:
	col.add_child(Widgets.label_as("Backstory", "LabelSectionSm"))
	if _who.backstory.is_empty():
		col.add_child(Widgets.empty_state(
			"Nothing is written down about them yet.", Icons.at("empty", "quill")))
		return
	for bullet in _who.backstory:
		col.add_child(_note("• %s" % _bullet_text(bullet), RIGHT_TEXT_W))


## Bullets are {text} dictionaries (docs/03) and, in older fixtures, bare
## strings — both are read, the way `Cards._first_bullet` reads them.
func _bullet_text(bullet) -> String:
	if bullet is Dictionary:
		return String((bullet as Dictionary).get("text", ""))
	return String(bullet)


## docs/13 §5's "morale history", under the raider card in the sidebar
## (HALL-09): the counters the sim keeps, then the trend.
func _history(col: VBoxContainer) -> void:
	col.add_child(Widgets.label_as("On record", "LabelSectionSm"))
	col.add_child(_note("Ran %d raid%s  ·  saw %d wipe%s  ·  took %d drop%s"
		% [_who.runs_attended, "" if _who.runs_attended == 1 else "s",
			_who.wipes_witnessed, "" if _who.wipes_witnessed == 1 else "s",
			_who.loot_received, "" if _who.loot_received == 1 else "s"], RECORD_TEXT_W))
	var joined := "Joined while the guild was %s." % Enums.reputation_name_of(
		int(_who.recruited_at_rank))
	# docs/04 §12.2: benching is a roster fact the sim never sees, counted here.
	if int(_who.consecutive_benched) > 0:
		joined += "  Benched for the last %d run%s." % [int(_who.consecutive_benched),
			"" if int(_who.consecutive_benched) == 1 else "s"]
	elif int(_who.runs_attended) > 0:
		joined += "  Went on the last run."
	col.add_child(_note(joined, RECORD_TEXT_W))
	_morale_history(col)


## The question the history answers is directional — "has this been getting
## worse?" — so the sentence comes first, in a word and a number, and a bar
## per recorded day is drawn under it for the eye (`Widgets.sparkline`,
## RULES-12). The words stay in a Label; the chart is only ever a second
## reading of them.
func _morale_history(col: VBoxContainer) -> void:
	var log: Array = _who.morale_log
	if log.size() < 2:
		col.add_child(_note(
			"No history yet. It starts filling on the first day that passes.", RECORD_TEXT_W))
		return

	var trend: int = _who.morale_trend()
	var word := "steady"
	var colour := Palette.TEXT_MUTED
	if trend > 2:
		word = "climbing"
		colour = Palette.POSITIVE
	elif trend < -2:
		word = "falling"
		colour = Palette.DANGER

	var line := Widgets.label_as("%+d over %d day%s — %s" % [
		trend, log.size(), "" if log.size() == 1 else "s", word], "LabelBody")
	line.add_theme_color_override("font_color", colour)
	col.add_child(line)

	var values: Array = []
	for entry in log:
		values.append(int(entry["morale"]))
	var chart := Widgets.sparkline(values,
		func(v: int) -> Color: return Palette.band_color_active(self, v))
	chart.custom_minimum_size = Vector2(
		mini(RECORD_TEXT_W, log.size() * Widgets.Sparkline.PITCH), Widgets.Sparkline.HEIGHT)
	chart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(chart)

	# The turning points, named. A chart says something changed; this says what.
	var moments: Array = _turning_points(log)
	if not moments.is_empty():
		col.add_child(_note("  ·  ".join(PackedStringArray(moments)), RECORD_TEXT_W))


## The three biggest single-day moves in the window, oldest first, each named by the
## trigger that caused it. Three because that is what fits on a line and because a
## fourth is rarely the reason anybody opened this screen.
func _turning_points(log: Array) -> Array:
	var moves: Array = []
	for i in range(1, log.size()):
		var note := String(log[i].get("note", ""))
		if note.is_empty():
			continue
		var delta: int = int(log[i]["morale"]) - int(log[i - 1]["morale"])
		if delta == 0:
			continue
		moves.append({"day": int(log[i]["day"]), "delta": delta, "note": note})
	moves.sort_custom(func(a, b): return absi(int(a["delta"])) > absi(int(b["delta"])))
	var top: Array = moves.slice(0, mini(3, moves.size()))
	top.sort_custom(func(a, b): return int(a["day"]) < int(b["day"]))

	var out: Array = []
	for m in top:
		out.append("day %d %+d %s" % [
			int(m["day"]), int(m["delta"]), _trigger_words(String(m["note"]))])
	return out


## Player-facing words for a trigger id. UI copy, not game data — every id that has no
## line here still reads sensibly, because the fallback is the id with its underscores
## taken out.
const TRIGGER_WORDS := {
	"wipe": "a wipe",
	"cleared": "a clear",
	"brought": "went along",
	"knocked_out": "went down",
	"peer_left": "someone left",
	"peer_left_same_class": "a friend left",
	"comfort_item": "a hot bath",
	"rally_flask": "the flask",
	"quest_completed": "a quest",
	"training": "training",
}


func _trigger_words(note: String) -> String:
	if TRIGGER_WORDS.has(note):
		return String(TRIGGER_WORDS[note])
	return note.replace("_", " ")


# ---------------------------------------------------------------- bottom strip

## The rest of the roster, as the strip's cards (10 §1: a C screen's strip, when
## present, is the same card strip). Opening a card re-points this screen, so
## walking the guild never means leaving it. The strip pages itself (KIT-12:
## `Cards.roster_strip`'s gutter pager); `_page` follows through `on_page`.
func _fill_strip() -> void:
	if _strip == null or _state == null:
		return
	if not _paged and _who != null:
		for i in _state.roster.size():
			if _state.roster[i].id == _who.id:
				_page = floori(i / float(Cards.PAGE))
				break
	var pages := Cards.roster_strip(_strip, _state, _page, {
		"card_action": func(r) -> void: _open(String(r.id)),
		"card_action_text": "Open",
		"grid_action": func(r) -> void: _open(String(r.id)),
		"on_page": func(p: int) -> void:
			_page = p
			_paged = true,
	})
	_page = clampi(_page, 0, pages - 1)
	Cards.event_log(_strip, _state)


func _open(raider_id: String) -> void:
	_state.selected_raider_id = raider_id
	_confirming = false
	_notice = ""
	_paged = false
	_refresh()


## Test seams: who this screen is currently showing, and the doll's slot
## Buttons ({Enums.Slot: Button}) for tests/unit/test_paper_doll.gd.
func shown_raider_id() -> String:
	return String(_who.id) if _who != null else ""


func slot_buttons() -> Dictionary:
	if _left == null:
		return {}
	var doll := _left.get_node_or_null("PaperDoll")
	return PaperDoll.slots_of(doll as Control) if doll != null else {}
