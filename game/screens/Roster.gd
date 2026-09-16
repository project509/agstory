extends Control
## S04 — the roster readout (docs/13 §9.1).
##
## ✅ CANON gives this screen its exact shape, and it is worth quoting because
## every layout choice below serves it:
##
##     Natsuna — 87 ❤️        Bob — 54 🙂        Greg — 31 😒       Steve — 14 😡
##     Shaman — Very Happy    Warrior — Content  Rogue — Annoyed    Mage — Upset
##
## Two lines per raider: name and morale on the first, class and state on the
## second. Canon's stated payoff is the sentence the player says out loud —
## *"Oh shit, Steve is at 14"* — so the morale number and its face are the
## loudest things on the card, and docs/13 §9 sets the bar: a player who has
## never seen this roster must name every at-risk raider in under two seconds.
##
## The art pass makes each raider the reference's roster card (01 §3, canon's
## morale row per 00 §2.1) in a four-column grid inside the Guildhall's content
## panel (10 §2 R2), sorted lowest-morale first. The card carries its two
## actions INSIDE its rim (W3-ROSTER: HALL-03 / KIT-06 / CRITIC-C15 — the
## docs/13 OQ-4 record now says so), so a row is exactly one card tall and the
## panel shows two full rows and the top of a third at twelve raiders. The
## sort and filter chips, the filter-state line, the rest controls and the
## morale summary live in the sidebar (HALL-09, HALL-12): the panel's title
## bar is the tab row, and every pixel under it is roster.
##
## This is a Control, not a screen scene: the Guildhall mounts it as a tab and
## hands it `sidebar_host` before `build()`. Without it (the tests mount it
## bare) it stacks the sidebar in a column of its own, so every string is on
## the view either way.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Type = preload("res://game/ui/Type.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Services = preload("res://game/core/Services.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Morale = preload("res://sim/core/Morale.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")
const Comfort = preload("res://sim/core/Comfort.gd")

const RAIDER_DETAIL := "res://game/screens/RaiderDetail.tscn"

## docs/13 OQ-4's quick-apply reaches for the cheapest thing that moves morale NOW.
const QUICK_INDULGENCE := "hot_bath"

enum Sort { MORALE, NAME, CLASS, GEAR }

const SORT_LABELS := ["Morale", "Name", "Class", "Gear"]

## docs/13 §9.1's filter row, minus the ones that need systems that do not
## exist yet (Benched needs raid groups, Wants to go needs backstory triggers).
enum Filter { ALL, AT_RISK, TANKS, HEALERS, DPS }

const FILTER_LABELS := ["All", "At risk", "Tanks", "Healers", "DPS"]

## The grid: the reference card at the reference pitch (01 §3), four across.
## A cell IS the card (HALL-03): the actions are the card's own bottom band,
## so the row pitch is the card plus the reference's 8px gap — 270.
const COLUMNS := 4
const CELL_W: int = Widgets.CARD_SIZE.x
const CARD_H: int = Widgets.CARD_SIZE.y
const CELL_H := CARD_H
const COL_PITCH: int = Widgets.CARD_PITCH
const ROW_GAP := 8
const ROW_PITCH := CARD_H + ROW_GAP
## HALL-14: the grid scrolls with a visible bar. The bar is the theme's 8px
## VScrollBar (W1-CHROME), and it sits in the panel's own margin — the scroll
## host is widened by this much past its column — so four cards at the
## reference pitch (887) keep their right rims inside the 888 the bar would
## otherwise eat.
const SCROLLBAR_W := 8
const SIDEBAR_TEXT_W := 300
## The stamp (HALL-13; docs/13 §8.4): `Widgets.stamp_box` centred across the
## lower edge of the card's portrait — the portrait frame is at (14, 14) 90x94
## inside the card, so its lower edge is y 108; the box straddles it.
const STAMP_CENTRE := Vector2(59, 98)
## HALL-09: the morale-band histogram well under the sidebar summary. Ten
## bars (one per canon band) at a 31px pitch fit the 314px column.
const HISTOGRAM_SIZE := Vector2(310, 56)
const HISTOGRAM_BAR_W := 24
const HISTOGRAM_PITCH := 31
const HISTOGRAM_BAR_MAX_H := 34
## The empty grid's box: the sentence and its glyph centred in this much of
## the panel (the viewport is 545 at 100% text; the box reads as its upper middle).
const EMPTY_H := 360

## Set by the Guildhall before build(); null means "lay it out here".
var sidebar_host: Control = null
var on_changed: Callable = Callable()

var _state = null
var _sort: int = Sort.MORALE
var _filter: int = Filter.ALL
var _grid: Control = null
var _scroll: ScrollContainer = null
var _count: Label = null
var _sum_avg: Label = null
var _sum_risk: Label = null
var _sum_roles: Label = null
var _histogram: Control = null
var _rest_forecast: Label = null
var _rest_report: Label = null
var _last_action := ""
var _rest_one: Button = null
var _rest_all: Button = null
var _sort_buttons: Array = []
var _filter_buttons: Array = []
var _router = null
var _built := false
## The row's height at the current text scale: CARD_H at 100%, the tallest
## card's minimum above that (see `_refresh`).
var _row_h: int = CARD_H


## The height every cell in the grid was given on the last refresh.
func row_height() -> int:
	return _row_h


func _ready() -> void:
	build()


## See MainMenu.build() — `_ready` is not a reliable trigger under a SceneTree
## script, so the router and the Guildhall both call this explicitly.
func build() -> void:
	if _built:
		return
	_built = true
	_state = Services.state(self)
	_router = Services.router(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var side := sidebar_host
	var col: VBoxContainer = null
	if side == null:
		# Bare mount: no Guildhall around us, so the sidebar stacks here.
		col = Widgets.column(8)
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(col)
		side = Widgets.column(6)
		col.add_child(side)
		col.add_child(Widgets.rule())

	_sidebar(side)

	_scroll = ScrollContainer.new()
	_scroll.name = "RosterScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_grid = Control.new()
	_grid.name = "Grid"
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_grid)
	if col == null:
		_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		_scroll.offset_right = SCROLLBAR_W
		add_child(_scroll)
	else:
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(_scroll)
	_refresh()


## ✅ CANON puts morale maintenance in the Guildhall, and this view is the
## Guildhall's roster tab — so the control that moves morale sits beside the
## numbers it moves, where the player is already looking at "Steve — 14".
##
## docs/15 BL-34 measured why one button is not enough: recovery from a wipe is 8-10
## Day Ticks and docs/02 §4.3 works an example that takes ~30. Resting a day at a
## time is a click count rather than a decision, so the second button does the whole
## stretch and reports what happened during it. It is this screen's one commit
## control, so it takes the crimson CTA (06 §3).
##
## Under the rest block: the roster's summary with docs/13 §8.5's filter-state
## line ("Showing 12 of 12 · At risk" — always text, never a look), the
## morale-band histogram (HALL-09), and the sort / filter chips (HALL-12) —
## `ButtonChip` toggles whose pressed state is the lit plate and gold rim, so
## the active key reads by chrome and not by font colour alone.
func _sidebar(side: Control) -> void:
	side.add_child(Widgets.label_as("Rest", "LabelSection"))
	_rest_forecast = Widgets.label_as("", "LabelSmall")
	_rest_forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rest_forecast.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
	side.add_child(_rest_forecast)

	_rest_one = Widgets.button("Rest a day")
	_rest_one.pressed.connect(_on_rest_one)
	side.add_child(_rest_one)
	_rest_all = Widgets.cta("Rest until recovered") as Button
	_rest_all.pressed.connect(_on_rest_all)
	side.add_child(_rest_all)

	_rest_report = Widgets.label_as("", "LabelBody")
	_rest_report.add_theme_color_override("font_color", Palette.ACCENT_GOLD_LIGHT)
	_rest_report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rest_report.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
	_rest_report.hide()
	side.add_child(_rest_report)

	side.add_child(Widgets.rule())
	side.add_child(Widgets.label_as("Roster", "LabelSection"))
	var facts := Widgets.column(2)
	facts.name = "Facts"
	side.add_child(facts)
	_count = Widgets.label_as("", "LabelMuted")
	_count.name = "Showing"
	facts.add_child(_count)
	_sum_avg = Widgets.label_as("", "LabelBody")
	facts.add_child(_sum_avg)
	_sum_risk = Widgets.label_as("", "LabelBody")
	facts.add_child(_sum_risk)
	_sum_roles = Widgets.label_as("", "LabelMuted")
	facts.add_child(_sum_roles)
	_histogram = Widgets.panel("PanelInset", 0)
	_histogram.name = "MoraleHistogram"
	_histogram.custom_minimum_size = HISTOGRAM_SIZE
	_histogram.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_histogram.clip_contents = true
	side.add_child(_histogram)

	side.add_child(Widgets.rule())
	_sort_buttons = _controls(side, "Sort", SORT_LABELS, func(i: int) -> void:
		_sort = i
		_refresh())
	_filter_buttons = _controls(side, "Filter", FILTER_LABELS, func(i: int) -> void:
		_filter = i
		_refresh())


func _on_rest_one() -> void:
	if _state == null or _state.roster.is_empty():
		return
	var before := _at_risk_count()
	_state.rest_in_town()
	var line := "A day passes."
	var lost := before - _at_risk_count()
	if _state.roster.is_empty():
		line = "The guild fell apart."
	elif lost > 0:
		line = "A day passes. %d fewer at risk." % lost
	_say_rest(line)
	_refresh()


func _on_rest_all() -> void:
	if _state == null or _state.roster.is_empty():
		return
	var report: Dictionary = _state.rest_until_recovered()
	_say_rest(_rest_outcome(report))
	_refresh()


## The sentence the player reads after resting. It leads with the cost (days) and
## then the one thing that could have gone wrong, because a multi-day rest that
## quietly lost a raider would be the worst kind of convenience.
func _rest_outcome(report: Dictionary) -> String:
	var days := int(report.get("days", 0))
	var reason := String(report.get("reason", "rested"))
	var departed: Array = report.get("departed", [])
	var spent := "%d day%s pass%s." % [days, "" if days == 1 else "s",
		"es" if days == 1 else ""]
	if days == 0:
		spent = "No time passes."

	match reason:
		"disbanded":
			return "%s The guild fell apart." % spent
		"departure":
			return "%s %s left the guild — the rest stopped there." % [
				spent, _list(departed)]
		"empty":
			return "There is nobody left to rest."
		"stalled", "limit":
			return "%s Nobody is settling any further." % spent
		_:
			if days == 0:
				return "Everyone has already settled."
			return "%s The roster has settled." % spent


func _list(names: Array) -> String:
	if names.is_empty():
		return "Nobody"
	if names.size() == 1:
		return String(names[0])
	var head: Array = []
	for i in names.size() - 1:
		head.append(String(names[i]))
	return "%s and %s" % [", ".join(PackedStringArray(head)),
		String(names[names.size() - 1])]


func _say_rest(line: String) -> void:
	if _rest_report == null:
		return
	_rest_report.text = line
	_rest_report.visible = not line.is_empty()


## What resting is worth right now, and what it risks. docs/05 §6's leave checks
## fire on every rest tick, so a roster with someone in bands 0-2 gets told that
## resting is not shelter — the player can bench the risk instead by not resting.
func _refresh_rest() -> void:
	if _rest_forecast == null:
		return
	if _state == null or _state.roster.is_empty():
		_rest_forecast.text = "There is nobody to rest."
		_rest_one.disabled = true
		_rest_all.disabled = true
		return

	var days: int = Morale.rest_ticks_needed(_state.roster, _state.facility_tier)
	_rest_one.disabled = false
	_rest_all.disabled = days == 0

	if days == 0:
		_rest_forecast.text = \
			"Everyone is at their baseline. Rest will not lift anyone further."
	else:
		_rest_forecast.text = "%d day%s of rest will settle the roster." % [
			days, "" if days == 1 else "s"]

	var risk := _at_risk_count()
	if risk > 0:
		# docs/05 §6.2: at 2+ consecutive at-risk ticks a leave check can fire, and
		# a rest tick is one of those ticks. Saying so is the difference between a
		# convenience and a trap.
		_rest_forecast.text += "  Resting still rolls the leave checks — %d %s at risk." % [
			risk, "raider is" if risk == 1 else "raiders are"]


func _at_risk_count() -> int:
	var n := 0
	for r in _roster():
		if Morale.is_at_risk(r.morale):
			n += 1
	return n


## A labelled run of chip toggles in `host` (docs/13 §8.5: "four PaperButton
## chips, not a dropdown"); returns the buttons so the active one can be lit on
## every refresh. An HFlowContainer, so at 150% text the row wraps instead of
## running off the sidebar.
func _controls(host: Control, label: String, labels: Array, on_pick: Callable) -> Array:
	var out: Array = []
	var flow := HFlowContainer.new()
	flow.name = label
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	var head := Widgets.label_as(label, "LabelLabel")
	head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flow.add_child(head)
	for i in labels.size():
		var b := Widgets.button(String(labels[i]))
		b.theme_type_variation = "ButtonChip"
		b.toggle_mode = true
		b.pressed.connect(func() -> void: on_pick.call(i))
		b.name = "%s_%d" % [label, i]
		flow.add_child(b)
		out.append(b)
	host.add_child(flow)
	return out


## The pressed state IS the lit state (ButtonChip: gold rim, lit plate, gold
## text) — no font-colour override, so the chip reads the same way a keyboard
## user's focus ring does: by chrome.
func _light(buttons: Array, active: int) -> void:
	for i in buttons.size():
		var b: Button = buttons[i]
		b.set_pressed_no_signal(i == active)


# ---------------------------------------------------------------- data

func _roster() -> Array:
	if _state == null:
		return []
	return _state.roster


func _visible_rows() -> Array:
	var db = _state.content if _state != null else null
	var out: Array = []
	for r in _roster():
		if _passes(r, db):
			out.append(r)
	_sort_rows(out, db)
	return out


func _passes(r, db) -> bool:
	match _filter:
		Filter.AT_RISK:
			return Morale.is_at_risk(r.morale)
		Filter.TANKS:
			return db != null and r.role_group(db) == Enums.RoleGroup.TANK
		Filter.HEALERS:
			return db != null and r.role_group(db) == Enums.RoleGroup.HEALER
		Filter.DPS:
			return db != null and r.role_group(db) == Enums.RoleGroup.DPS
	return true


func _sort_rows(rows: Array, db) -> void:
	match _sort:
		Sort.MORALE:
			# Lowest first: the roster's job is to surface the problem, and
			# canon's example opens on Steve at 14, not on the happy Shaman.
			rows.sort_custom(func(a, b) -> bool: return a.morale < b.morale)
		Sort.NAME:
			rows.sort_custom(func(a, b) -> bool:
				return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
		Sort.CLASS:
			rows.sort_custom(func(a, b) -> bool:
				if a.class_id == b.class_id:
					return a.morale < b.morale
				return a.class_id < b.class_id)
		Sort.GEAR:
			rows.sort_custom(func(a, b) -> bool:
				return _gear_filled(a, db) < _gear_filled(b, db))


## Slots this raider actually wears something in.
func _gear_filled(r, _db) -> int:
	return r.equipment.size()


## docs/13 §9.1: coverage is "slots filled out of that raider's VISIBLE slot
## count" — seven, or six for Monk / Mage / Wizard, whose off-hand is hidden
## rather than empty. Reading it as a score instead of coverage would mark
## every caster permanently incomplete.
func _gear_total(r, db) -> int:
	if db == null:
		return Enums.all_slots().size()
	var cd = db.class_by_key(r.class_key())
	if cd == null:
		return Enums.all_slots().size()
	return cd.available_slots().size()


## docs/13 §8.5's filter-state line. "Showing 12 of 12" is the exact prefix
## test_starting_roster and test_rest read; the " · <filter>" suffix appears
## only when a filter other than All is on (HALL-12), so a filtered list can
## never look unfiltered.
func showing_text(shown: int, total: int) -> String:
	var line := "Showing %d of %d" % [shown, total]
	if _filter != Filter.ALL:
		line += " · %s" % String(FILTER_LABELS[_filter])
	return line


# ---------------------------------------------------------------- rendering

## A rebuild of the grid frees every card, and a freed Button drops keyboard
## focus (handoff-W2-TAVERN). So the focused card and button are noted FIRST,
## the grid is rebuilt, the shell's focus wiring is re-run, and focus lands on
## the same button of the same raider again — or the grid's first control.
func _refresh() -> void:
	_refresh_rest()
	if not _last_action.is_empty():
		_say_rest(_last_action)
		_last_action = ""
	if _grid == null:
		return
	var focus := _focus_note()
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_light(_sort_buttons, _sort)
	_light(_filter_buttons, _filter)

	var db = _state.content if _state != null else null
	var rows := _visible_rows()
	var total := _roster().size()

	if _count != null:
		_count.text = showing_text(rows.size(), total)

	var grid_w := COL_PITCH * (COLUMNS - 1) + CELL_W
	if total == 0:
		_empty("No raiders yet. The Tavern is where a guild finds people.", grid_w, "bench")
	elif rows.is_empty():
		_empty("Nobody matches this filter — which is usually good news.", grid_w, "shelf")
	else:
		# Two passes: every card is built and parented first, so the row's
		# height can be read off the tallest card AT THIS TEXT SCALE (docs/13
		# §4.4: at 150% a layout reflows by scrolling more, never by cutting a
		# word — here the band); at 100% that is the card's own 262.
		var cells: Array = []
		_row_h = CARD_H
		for i in rows.size():
			var cell := _cell(rows[i], db)
			_grid.add_child(cell)
			cells.append(cell)
			var card: Control = cell.get_node("Card")
			_row_h = maxi(_row_h, int(ceilf(card.get_combined_minimum_size().y)))
		var pitch := _row_h + ROW_GAP
		for i in cells.size():
			var cell: Control = cells[i]
			@warning_ignore("integer_division")
			cell.position = Vector2((i % COLUMNS) * COL_PITCH, (i / COLUMNS) * pitch)
			cell.size = Vector2(CELL_W, _row_h)
			(cell.get_node("Card") as Control).size = Vector2(CELL_W, _row_h)
			_stamp(cell, rows[i])
		@warning_ignore("integer_division")
		var lines: int = (rows.size() + COLUMNS - 1) / COLUMNS
		_grid.custom_minimum_size = Vector2(grid_w, lines * pitch - ROW_GAP)

	_summary(db)
	_rewire_focus()
	_regrab(focus)
	if on_changed.is_valid():
		on_changed.call()


## KIT-08: the empty grid says why, with the kit's glyph above the sentence
## (the Label text is what the tests read; the glyph is a child TextureRect).
## The Label sits in a MarginContainer given the rect, not placed by hand: an
## autowrapped Label whose width is unknown when its minimum is first read
## wraps one glyph per line and keeps that height (measured: 465px for four
## words), and a Container hands it width and height together.
func _empty(text: String, width: int, glyph: String) -> void:
	var box := MarginContainer.new()
	box.name = "EmptyBox"
	_grid.add_child(box)
	box.position = Vector2.ZERO
	box.size = Vector2(width, EMPTY_H)
	var l := Widgets.empty_state(text, Icons.at("empty", glyph))
	l.name = "Empty"
	box.add_child(l)
	_grid.custom_minimum_size = Vector2(width, EMPTY_H)


## One raider: the reference card (01 §3) carrying canon's two-line morale row,
## with docs/13 OQ-4's two actions — the fast fix and the way in — in the
## card's own bottom band (`Cards.card(actions)`; the reason a disabled Cheer
## up gives is the faint Label under it, inside the rim). The at-risk stamp is
## added by `_stamp` once the cell is in the tree, so it can measure itself.
func _cell(r, db) -> Control:
	var cell := Control.new()
	cell.name = "Cell_%s" % String(r.id).validate_node_name()
	cell.clip_contents = true
	var card := Cards.card(r, db, {}, [_quick_apply_action(r), _manage_action(r)])
	card.name = "Card"
	_fit_band(card)
	cell.add_child(card)
	card.position = Vector2.ZERO
	card.size = Vector2(CELL_W, CARD_H)
	return cell


## A card whose Cheer up is shut carries the reason under the button, and
## that line is what pushes the kit's card past its 262 (measured on the
## first W3-ROSTER shot: "They are fine." cut by the rim). Until the kit's
## band fits its own card (handoff-W3-ROSTER), the card's column is tightened
## here: separation 4 → 2, the reason box's 2 → 0, the reason at Type.STACK.
## Nothing here changes a text, a name or a node type — the walk that reads
## "They are fine." and presses "Cheer up" sees the same tree.
func _fit_band(card: Control) -> void:
	var pad := Widgets.content_of(card as PanelContainer)
	if pad.get_child_count() == 0:
		return
	var col := pad.get_child(0) as VBoxContainer
	if col == null:
		return
	var band := col.get_node_or_null("Actions")
	if band == null:
		return
	var has_reason := false
	for box in band.get_children():
		if not (box is VBoxContainer):
			continue
		for c in box.get_children():
			if c is Label:
				has_reason = true
				(c as Label).add_theme_font_size_override("font_size",
					Type.at(Type.STACK, Theme_.scale_of(self)))
		if has_reason:
			(box as VBoxContainer).add_theme_constant_override("separation", 0)
	if has_reason:
		col.add_theme_constant_override("separation", 2)


## docs/05 §6.2's Warning UX ladder, which escalates with consecutive ticks
## spent at risk rather than showing one flat tag: 1 amber, 2 "AT RISK",
## 3+ "MAY LEAVE". A player who has been warned twice should see that.
##
## HALL-13 / docs/13 §8.4: a StampBadge — `Widgets.stamp_box` (PanelStamp
## chrome, the word its direct child, rotated 2-7° from the word) laid across
## the lower edge of the portrait. A stamp carrying a word survives greyscale,
## small sizes and colour blindness at once; the tone is a name, so no hex.
func _stamp(cell: Control, r) -> void:
	var level := Morale.warning_level(r)
	if level <= 0 and not Morale.is_at_risk(r.morale):
		return
	var text := "AT RISK"
	var tone := "caution"
	if level >= 3:
		text = "MAY LEAVE"
		tone = "danger"
	elif level == 2:
		tone = "danger"
	var box := Widgets.stamp_box(text, tone)
	box.name = "Stamp"
	cell.add_child(box)
	var want: Vector2 = box.get_combined_minimum_size()
	box.size = want
	box.pivot_offset = want * 0.5
	box.position = STAMP_CENTRE - want * 0.5


## docs/13 OQ-4's quick-apply, and the reason it is an INDULGENCE rather than a
## furnishing: OQ-4 says morale repair "is done many times per cycle", and the thing
## done many times is the +8 spike (docs/05 §7.4), not a one-off purchase of furniture.
## Two clicks from the roster — this button, and nothing else.
##
## No morale gate (LOOP-16): the Market sells the same Hot Bath Token to the
## same raider at any morale, and "They are fine." at 45 — the exact morale a
## Common settles at — contradicted the game. The button gates on what the
## Market gates on: the price and the day's cap; a bath that would not land
## (docs/05 §7.4's cooldown) is refused by `GameState.use_indulgence`'s own
## sentence when it is pressed.
func _quick_apply_action(r) -> Dictionary:
	var reason := ""
	if _state == null:
		reason = "No guild loaded."
	else:
		var price: int = Comfort.indulgence_price(QUICK_INDULGENCE)
		if _state.gold < price:
			reason = "Costs %d G." % price
		elif _state.indulgences_today \
				>= Comfort.indulgence_cap(_state.roster.size()):
			reason = "Sold out today."
	var rid: String = r.id
	return {"text": "Cheer up", "reason": reason, "on": func() -> void:
		_last_action = _state.use_indulgence(QUICK_INDULGENCE, rid)
		if _last_action.is_empty():
			_last_action = "Sent up with the water still hot."
		_refresh()}


## docs/13 §5: S05 is entered from "S04 row". This is that row.
func _manage_action(r) -> Dictionary:
	if _router == null or not _router.screen_exists(RAIDER_DETAIL):
		return {"text": "Manage", "reason": "Not built in this version yet."}
	var rid: String = r.id
	return {"text": "Manage", "reason": "", "on": func() -> void:
		_state.selected_raider_id = rid
		_router.push(RAIDER_DETAIL)}


## Which gear tier this raider is standing in, in docs/13 §9.1's notation.
func _gear_label(r, db) -> String:
	if db == null:
		return "Gear"
	var best := "Start"
	for it in r.equipped_items(db):
		if it.source == "raid":
			return "T1R"
		if it.source == "adventure":
			best = "T1A"
	return best


## The sidebar summary: average, risk, roles — one Label each — and the
## histogram well under them (HALL-09): one bar per canon band, coloured by
## the morale ramp, its count printed above it (a Label, so the number is
## read and not only seen — docs/13 §13's two channels).
func _summary(db) -> void:
	if _sum_avg == null:
		return
	var all := _roster()
	if all.is_empty():
		_sum_avg.text = "Nobody on the books."
		_sum_risk.text = ""
		_sum_roles.text = ""
		_fill_histogram([])
		return
	var total := 0
	var at_risk := 0
	var tanks := 0
	var healers := 0
	var dps := 0
	for r in all:
		total += r.morale
		if Morale.is_at_risk(r.morale):
			at_risk += 1
		if db != null:
			match r.role_group(db):
				Enums.RoleGroup.TANK: tanks += 1
				Enums.RoleGroup.HEALER: healers += 1
				Enums.RoleGroup.DPS: dps += 1
	_sum_avg.text = "Roster average morale %d" % int(round(float(total) / float(all.size())))
	_sum_risk.text = "At risk %d" % at_risk
	_sum_roles.text = "Tanks %d  ·  Healers %d  ·  DPS %d" % [tanks, healers, dps]
	_fill_histogram(all)


## Raiders per canon band (0-9), as `band_counts(roster)` reads them.
static func band_counts(roster: Array) -> Array:
	var counts: Array = []
	for _i in Enums.MORALE_BAND_COUNT:
		counts.append(0)
	for r in roster:
		var band: int = Enums.morale_band(int(r.morale))
		if band >= 0 and band < counts.size():
			counts[band] += 1
	return counts


func _fill_histogram(roster: Array) -> void:
	if _histogram == null:
		return
	var well: Control = Widgets.content_of(_histogram)
	for c in well.get_children():
		well.remove_child(c)
		c.queue_free()
	var counts := band_counts(roster)
	var peak := 1
	for n in counts:
		peak = maxi(peak, int(n))
	var inner := Control.new()
	inner.name = "Bars"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	well.add_child(inner)
	var floor_y := HISTOGRAM_SIZE.y - 4.0
	for band in counts.size():
		var n := int(counts[band])
		var x := 3 + band * HISTOGRAM_PITCH
		var h := 2.0
		if n > 0:
			h = maxf(4.0, float(HISTOGRAM_BAR_MAX_H) * float(n) / float(peak))
		var bar := ColorRect.new()
		bar.name = "Band%d" % band
		bar.color = Palette.band_color_active(self, band * 10 + 5)
		if n == 0:
			bar.color = Color(bar.color, 0.35)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(bar)
		bar.position = Vector2(x, floor_y - h)
		bar.size = Vector2(HISTOGRAM_BAR_W, h)
		if n > 0:
			var count := Widgets.label_as(str(n), "LabelSmall")
			count.name = "Count%d" % band
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			count.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(count)
			count.position = Vector2(x, floor_y - h - 16)
			count.size = Vector2(HISTOGRAM_BAR_W, 14)


# ---------------------------------------------------------------- focus

## The screen-root Callable the shell leaves (`Frame.META_FOCUS_ORDER`,
## mirrored as a literal the way Cards.gd mirrors it): walk up to whichever
## ancestor carries it and re-run it over the rebuilt grid.
func _rewire_focus() -> void:
	var n: Node = self
	while n != null:
		if n.has_meta(Cards.SCREEN_FOCUS_META):
			var cb = n.get_meta(Cards.SCREEN_FOCUS_META)
			if cb is Callable and (cb as Callable).is_valid():
				(cb as Callable).call()
			return
		n = n.get_parent()


## [cell index, Button.text] of the focused grid control, or [] when the grid
## does not hold focus.
func _focus_note() -> Array:
	var vp := get_viewport()
	if vp == null or _grid == null:
		return []
	var owner := vp.gui_get_focus_owner()
	if owner == null or not _grid.is_ancestor_of(owner):
		return []
	var text := ""
	if owner is Button:
		text = (owner as Button).text
	for i in _grid.get_child_count():
		if _grid.get_child(i).is_ancestor_of(owner):
			return [i, text]
	return [0, text]


func _regrab(note: Array) -> void:
	if note.is_empty() or _grid == null or not is_inside_tree():
		return
	var index: int = clampi(int(note[0]), 0, maxi(0, _grid.get_child_count() - 1))
	var target: Control = null
	if _grid.get_child_count() > 0:
		var cell := _grid.get_child(index)
		target = _button_in(cell, String(note[1]))
		if target == null:
			target = _first_focusable(cell)
	if target == null:
		target = _first_focusable(_grid)
	if target != null and target.is_inside_tree() and target.is_visible_in_tree():
		target.grab_focus()


func _button_in(node: Node, text: String) -> Control:
	if text.is_empty():
		return null
	if node is Button and (node as Button).text == text and _first_focusable(node) == node:
		return node
	for child in node.get_children():
		var found := _button_in(child, text)
		if found != null:
			return found
	return null


func _first_focusable(node: Node) -> Control:
	if node == null:
		return null
	if node is Control:
		var c := node as Control
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree():
			if not (c is BaseButton) or not (c as BaseButton).disabled:
				return c
	for child in node.get_children():
		var found := _first_focusable(child)
		if found != null:
			return found
	return null
