extends Control
## S07 — the Tavern (docs/02 §5, docs/04 §3).
##
## ✅ CANON: "Recruits are found and managed here" and "This is all managed at the -
## Tavern" (raw notes, Tavern; Guild Reputation).
##
## docs/04 §3.5 fixes what a card must show and why, and it is the strongest instruction
## in that document: "the card is the entire decision surface and must be readable
## without a submenu ... Backstory bullets are never hidden pre-recruit. **The joke only
## lands if the player knowingly hires the guy whose bullet says he quits when
## benched.**"
##
## On the reference frame (Concept 1, archetype A — 10 §3.3) the board is the bottom
## strip: one card per candidate with EVERY bullet face up, the seats as the
## "Available" mini-grid, and the right sidebar holding the selected candidate's full
## detail with the one crimson commit control, "Hire — N G". Nothing about the money
## moved: a test asserts every bullet is printed before the Hire button exists.
##
## W2-TAVERN (build/plan/artaudit/00-plan.md): the card carries its arriving gear as
## three slots and a rarity rim (TOWN-18; docs/02 §5.3 "the card must therefore show
## arriving gear"); the scene text sits on ONE caption plate top-left in the callout
## chrome — the tab pair, the house line, the rank's rarity floor, the reroll and the
## room upgrade with their rules, the vendor notice (TOWN-19); the desk band carries
## Recent Events and a footer with the hire arithmetic; the sidebar ends where the
## strip begins (TOWN-17) — the column is trimmed to fit and, for the Legendary with
## four two-line bullets or the 150% text scale, scrolls inside the rim rather than
## painting over the strip.

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
const Morale = preload("res://sim/core/Morale.gd")
const Formulas = preload("res://sim/core/Formulas.gd")
const Recruitment = preload("res://sim/core/Recruitment.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const Buildings = preload("res://sim/core/Buildings.gd")
const Achievements = preload("res://sim/core/Achievements.gd")

const TOWN := "res://game/screens/Town.tscn"

const TABS := [
	{"id": "board", "label": "Board"},
	{"id": "manage", "label": "Manage"},
]

## The caption plate's two columns (TOWN-19): the tab pair, the house facts and
## the rarity floor on the left; the reroll and the room upgrade, with their
## rules, on the right. Both are MINIMUM widths — at text scale 150 the upgrade
## button is wider than 340 and the column (and the plate) grows with it, so the
## plate is min-driven in both axes (`size = ZERO`) and never clips a word.
const PLATE_LEFT_W := 250
const PLATE_RIGHT_W := 340
const PLATE_GAP := 20
const PLATE_AT := Vector2(14, 14)
## The Manage list hangs under the plate with this much air, and runs to the
## scene's bottom inset.
const MANAGE_GAP := 10
const MANAGE_INSET := 14
const MANAGE_W := 900
## Sidebar text width (the panel is 378 wide with an 18px pad and a 14px
## stylebox margin each side; 330 leaves room for the scrollbar when it shows).
const SIDE_TEXT_W := 330
## Slot cell for the card's three "arrives with" slots — the mini cell, so the
## three sit beside the 56px portrait and leave the bullets their room.
const GEAR_CELL := Widgets.MINI_CELL

var _router = null
var _state = null
var _active := "board"
var _tab_buttons: Dictionary = {}
var _notice := ""
var _confirming := ""
var _selected := 0                  ## index into tavern_board the sidebar shows
var _page := 0
var _built := false

var _frame = null
var _scene_host: Control = null
var _plate: PanelContainer = null
var _plate_tabs_host: VBoxContainer = null
var _plate_lines: VBoxContainer = null
var _plate_actions: VBoxContainer = null
var _tab_row: Control = null
var _notice_label: Label = null
var _manage_panel: Control = null
var _manage_host: VBoxContainer = null
var _side_host: Control = null
var _strip: Control = null


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
	_frame = Frame.build(self, {
		"nav": Frame.nav_items(_router), "active": "tavern", "framed": true,
	})
	Frame.wire_nav(_frame, _router, "tavern")

	_scene_host = _frame.scene
	_scene()
	Frame.standard_chips(_frame, _state)
	_side_host = Frame.sidebar(_frame)
	_strip = _frame.strip

	# docs/04 §3.2's board is refreshed by events, not by opening the door — but an empty
	# board on the first visit would be a dead screen, so a first look fills it. The
	# predicate is `board_needs_first_roll()`, not `is_empty()`: docs/04 §3.4 makes
	# dismissing free, so an emptied board plus an is_empty() guard was a whole new
	# board for nothing — the `50g × 2^n` ladder bypassed by walking out and back in.
	if _state != null and _state.board_needs_first_roll():
		_state.refresh_board()
	_refresh()


# ---------------------------------------------------------------- scene

## Where the tavern's 1536x1024 plate sits inside this screen's 928x640 scene
## viewport. The window shows plate x 320..1248, y 130..770: the bar and its
## stools, the hearth at (1000, 175), and every table. The performance stage and
## its guitar are at x 1200..1480 and fall outside — which is why the bard stands
## there in the SCENE data and not here. An offset belongs to the screen, not the
## scene: each screen frames the same plate differently.
const TAVERN_OFFSET := Vector2(-320, -130)

## Dimmed a step so the caption plate and the Manage list read over the room.
## Was 0.78 against the mockup crop; the bare plate is a darker image and
## carries our own lit candles and moving people, so it needs less taking away.
const SCENE_DIM := Color(0.86, 0.86, 0.9)


func _scene() -> void:
	# The 2026-09-11 directive: the BARE tavern plate, with the room's people
	# and its hearth fire rendered over it rather than painted into it. The old
	# crop had both baked in, and a tavern whose patrons never move is the exact
	# thing the directive names.
	var stage := SceneStage.load("stage_tavern")
	stage.position = TAVERN_OFFSET
	stage.size = _scene_host.size - TAVERN_OFFSET
	stage.modulate = SCENE_DIM
	_scene_host.add_child(stage)

	# ONE caption plate (TOWN-19), in the callout chrome the Town's building
	# plates wear, top-left over the bar's back shelves — set dressing, not the
	# patrons. Two columns so the plate is wide and short like docs/13 §9.4's
	# header band rather than a tall slab over the round table. Everything on it
	# that a hire or a purchase changes is rebuilt in `_refresh()` (the tab pair
	# included — the kit's `tab_row` is the idiom, and it is a rebuild); the
	# notice sits under both columns.
	_plate = Widgets.panel("PanelCallout", 8)
	_plate.name = "Caption"
	_scene_host.add_child(_plate)
	_plate.position = PLATE_AT
	_plate.size = Vector2.ZERO
	var col := Widgets.column(6)
	col.name = "PlateCol"
	var two := Widgets.row(PLATE_GAP)
	two.name = "PlateRow"
	var left := Widgets.column(6)
	left.name = "PlateLeft"
	left.custom_minimum_size = Vector2(PLATE_LEFT_W, 0)
	_plate_tabs_host = Widgets.column(0)
	_plate_tabs_host.name = "TabsHost"
	left.add_child(_plate_tabs_host)
	_plate_lines = Widgets.column(4)
	_plate_lines.name = "PlateLines"
	left.add_child(_plate_lines)
	two.add_child(left)
	_plate_actions = Widgets.column(4)
	_plate_actions.name = "PlateRight"
	_plate_actions.custom_minimum_size = Vector2(PLATE_RIGHT_W, 0)
	two.add_child(_plate_actions)
	col.add_child(two)

	_notice_label = Widgets.label_as("", "LabelBody")
	_notice_label.name = "Notice"
	_notice_label.add_theme_color_override("font_color", Palette.ACCENT_GOLD_LIGHT)
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_label.custom_minimum_size = Vector2(PLATE_LEFT_W + PLATE_GAP + PLATE_RIGHT_W, 0)
	_notice_label.visible = false
	col.add_child(_notice_label)
	Widgets.content_of(_plate).add_child(col)

	# The Manage list lives in the scene as a panel under the plate; hidden on
	# the Board tab. It follows the plate's rect (the plate grows with the text
	# scale and with a reason line), so the list never starts under the caption.
	_manage_panel = Widgets.panel("PanelWarm", 16)
	_manage_panel.name = "ManagePanel"
	_scene_host.add_child(_manage_panel)
	_manage_panel.clip_contents = true
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_manage_host = Widgets.column(6)
	_manage_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_manage_host)
	Widgets.content_of(_manage_panel).add_child(scroll)
	_place_manage()
	_plate.item_rect_changed.connect(_place_manage)


## The Manage list hangs MANAGE_GAP under the caption plate, whatever the plate's
## height is this frame, and runs to the scene's bottom inset.
func _place_manage() -> void:
	if _manage_panel == null or _plate == null or _scene_host == null:
		return
	var top: float = _plate.position.y + _plate.size.y + MANAGE_GAP
	_manage_panel.position = Vector2(PLATE_AT.x, top)
	_manage_panel.size = Vector2(MANAGE_W, maxf(0.0, _scene_host.size.y - MANAGE_INSET - top))


# ---------------------------------------------------------------- refresh

## Rebuild everything a press can change. Every region is a rebuild (the kit's
## own strip and tab row are), and a rebuild frees the control the keyboard was
## on — so the region that held focus is noted FIRST, before the clear (a
## control loses focus the moment it leaves the tree), the shell's focus paths
## are re-wired over the new nodes, and focus lands on the first control of the
## same region again. Without this a keyboard player who pressed Hire, Dismiss
## or Manage would be left with no focus owner at all.
func _refresh() -> void:
	var region := _focus_region()
	if _notice_label != null:
		_notice_label.text = _notice
		_notice_label.visible = not _notice.is_empty()
	if _frame != null:
		Frame.refresh_chips(_frame, _state)

	for host in [_plate_tabs_host, _plate_lines, _plate_actions, _side_host, _strip, _manage_host]:
		if host != null:
			for c in host.get_children():
				host.remove_child(c)
				c.queue_free()

	_build_tabs()

	if _state != null:
		_build_plate()
		_manage_panel.visible = _active == "manage"
		if _active == "manage":
			_build_manage()
		_build_board()
		_build_sidebar()
	elif _side_host != null:
		_side_host.add_child(Widgets.empty_state("No guild loaded."))

	_rewire_focus()
	_regrab(region)


## Which rebuilt region holds keyboard focus right now ("" when none does).
func _focus_region() -> String:
	var vp := get_viewport()
	if vp == null:
		return ""
	var owner := vp.gui_get_focus_owner()
	if owner == null:
		return ""
	for pair in [["tabs", _plate_tabs_host], ["plate", _plate_actions], ["manage", _manage_host],
			["strip", _strip], ["sidebar", _side_host]]:
		var host: Control = pair[1]
		if host != null and host.is_ancestor_of(owner):
			return String(pair[0])
	return ""


## Hand focus back to the region that had it: the active tab for the tab row,
## the first focusable control otherwise.
func _regrab(region: String) -> void:
	if region.is_empty() or not is_inside_tree():
		return
	var target: Control = null
	match region:
		"tabs":
			target = _tab_buttons.get(_active, null)
		"plate":
			target = _first_focusable(_plate_actions)
		"manage":
			target = _first_focusable(_manage_host)
		"strip":
			target = _first_focusable(_strip)
		"sidebar":
			target = _first_focusable(_side_host)
	if target != null and target.is_inside_tree() and target.is_visible_in_tree():
		target.grab_focus()


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


func _say(text: String) -> void:
	_notice = text


# ---------------------------------------------------------------- the caption plate

## The tab pair in the kit's sub-tab idiom (`Widgets.tab_row`; the texts "Board"
## and "Manage" are what the tests press). The row is a rebuild — `_refresh`
## hands focus back to the active tab when the pressed one had it.
func _build_tabs() -> void:
	if _plate_tabs_host == null:
		return
	var labels: Array = []
	var active := 0
	for i in TABS.size():
		labels.append(String(TABS[i]["label"]))
		if String(TABS[i]["id"]) == _active:
			active = i
	_tab_row = Widgets.tab_row(labels, active)
	_tab_buttons = {}
	var tabs: Array = Widgets.tabs_of(_tab_row)
	for i in tabs.size():
		var id := String(TABS[i]["id"])
		var b: Button = tabs[i]
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			_active = id
			_notice = ""
			_confirming = ""
			_refresh())
		_tab_buttons[id] = b
	_plate_tabs_host.add_child(_tab_row)


## Re-run the shell's focus wiring (the Callable Frame leaves on this screen —
## the key is mirrored as a literal the way Cards.gd mirrors it).
func _rewire_focus() -> void:
	if has_meta(Cards.SCREEN_FOCUS_META):
		var cb = get_meta(Cards.SCREEN_FOCUS_META)
		if cb is Callable and (cb as Callable).is_valid():
			(cb as Callable).call()


## The facts on the plate: the house line (docs/02 §5.3), the rank's rarity
## floor (docs/13 §9.4's header line — "At Respected you no longer meet Common
## adventurers"), the collection meter, and on the right the reroll and the
## room upgrade with the sentences that explain their prices.
func _build_plate() -> void:
	_plate_lines.add_child(Widgets.label_as("house %d of %d  ·  %d seats" % [
		_state.tavern_tier, Buildings.MAX_LEVEL, _state.board_slots()], "LabelSmall"))
	var floor_line := Widgets.label_as(_floor_line(), "LabelSmall")
	floor_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	floor_line.custom_minimum_size = Vector2(PLATE_LEFT_W, 0)
	floor_line.add_theme_color_override("font_color", Palette.TEXT_MUTED_WARM)
	_plate_lines.add_child(floor_line)
	_collection_meter(_plate_lines)

	_plate_actions.add_child(_reroll_row())
	_plate_actions.add_child(_upgrade_row())


## docs/03 §5.2's matrix, read through `Reputation.recruit_tiers(rank)`: the
## lowest rarity the rank can meet is the floor. Never a typed rarity name —
## the sentence follows the table.
func _floor_line() -> String:
	var rank: int = _state.reputation_rank
	var rank_name := String(_state.rank_name())
	var tiers: Array = Reputation.recruit_tiers(rank)
	if tiers.is_empty():
		return "At %s nobody worth hiring walks in." % rank_name
	var floor_r: int = int(tiers[0])
	if floor_r <= 0:
		return "At %s the room is mostly %s adventurers." % [
			rank_name, Enums.rarity_name_of(Recruitment.modal_rarity(rank))]
	if floor_r == 1:
		return "At %s you no longer meet Common adventurers." % rank_name
	return "At %s nobody below %s walks in." % [rank_name, Enums.rarity_name_of(floor_r)]


# ---------------------------------------------------------------- the board

## The strip on both tabs: the seats, one page of candidate cards, Recent
## Events in the strip's right corner (TOWN-19) and the hire arithmetic under
## the cards. The Manage tab keeps the board in view — the list is in the
## scene's panel and the board is what the room has on offer either way.
func _build_board() -> void:
	var board: Array = _state.tavern_board
	if board.is_empty():
		var e := Widgets.panel("PanelRound", 14)
		_strip.add_child(e)
		e.position = Vector2(Widgets.CARD_X0 - 13, 0)
		e.size = Vector2(Widgets.CARD_PITCH * 4 - 9, Widgets.STRIP_H)
		Widgets.content_of(e).add_child(Widgets.empty_state(
			"Nobody is drinking. Finish a run and the room fills up.", Icons.at("empty", "bench")))
	else:
		_selected = clampi(_selected, 0, board.size() - 1)
		var pages := Cards.roster_strip(_strip, _state, _page, {
			"cards": board, "available": board,
			"available_label": "Seats", "seats": _state.board_slots(),
			"card_builder": func(who, index: int) -> Control: return _candidate_card(who, index),
			"grid_action": func(who) -> void:
				if _selected != _index_of(who):
					var audio: Node = Services.find(self, "Audio")
					if audio != null:
						audio.play("ui.row_select")
				_selected = _index_of(who)
				_active = "board"
				_refresh(),
			"on_page": func(p: int) -> void: _page = p,
		})
		_page = clampi(_page, 0, pages - 1)
	Cards.event_log(_strip, _state, 7, "Raids and rests write here.")

	# docs/13 §9.4's footer: "Roster 17 of 20 · Hiring Marguerite leaves 1,080g",
	# in the 28px band under the cards the strip leaves (the pager's caption
	# sits under the right gutter, so this stops short of it).
	var foot := Widgets.label_as(_footer_line(), "LabelSmall")
	foot.name = "Footer"
	foot.add_theme_color_override("font_color", Palette.TEXT_MUTED_WARM)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_strip.add_child(foot)
	foot.position = Vector2(Widgets.CARD_X0 - 13, Widgets.STRIP_H + 4)
	foot.size = Vector2(Cards.PAGER_NEXT_X - 40 - (Widgets.CARD_X0 - 13), 20)


func _footer_line() -> String:
	var line := "Roster %d of %d" % [_state.roster.size(), _state.roster_cap()]
	var board: Array = _state.tavern_board
	if board.is_empty() or _selected < 0 or _selected >= board.size():
		return line
	var who = board[_selected]
	var price := Recruitment.cost_of(who.rarity, _state.highest_unlocked_tier())
	if _state.gold >= price:
		return "%s  ·  Hiring %s leaves %s" % [line, who.display_name, Type.gold(_state.gold - price)]
	return "%s  ·  Hiring %s needs %s more" % [line, who.display_name, Type.gold(price - _state.gold)]


## The candidate card. docs/04 §3.5 forbids a submenu, so the bullets ride on the
## card itself, every one of them, and a test walks the whole board to prove it.
## The compact 56px portrait (Concept 1's Raid Team slot) buys the room.
##
## TOWN-18: the three "arrives with" slots (`Cards.card`'s slot row, the mini
## cell) sit beside the portrait under the name and class, so the gear costs the
## bullets 21px rather than a whole 47px row; the rim is the rarity's colour,
## 2px, on the theme's own PanelRound box (the Legendary adds a soft outer glow),
## and the portrait wears the same rim through `Widgets.slot_rarity`. The
## SELECTED card takes the kit's `PanelRoundSelected` rim instead (KIT-10 — one
## selection idiom for the Roster to share), keeping its rarity on the name,
## the class line and the portrait's rim. The band word is the second line of
## the morale row, canon's two-line form.
##
## W5-SCALE — THE CARD'S FIXED PARTS AT 150% TEXT. The card is 215x262 at
## every text scale (the strip is 262 tall) and the bullets' scroll takes what
## the fixed parts leave, so those must fit the 238 inside the pad at 150 with
## a wrapped class line ("Warrior — Common" is 199px at 23px in 191). Measured
## in the tree at 150 they were 255 and the Look button sat 17px through the
## card's bottom rim. What gives, and why (each at 150 / 100):
##   - the class line prints no face, so it does not pay the face sheet's line
##     height (LabelClass is 36/24 tall for a face it never draws): LabelMuted
##     at LabelClass's own size and colour, 29/19 a line, no line spacing;
##   - the morale line DOES print the face — the authored pixel face through
##     the face-carrying LabelClass (24/30/36 by scale, HALL-05) instead of
##     LabelPip's system emoji; it costs 36/24 and that is the point;
##   - Look wears the kit card's own action plate (ButtonCardAction, the
##     "Cheer up"/"Manage" idiom, 37/29) instead of the 45/35 secondary;
##   - the column's gaps are 2 and the name block's 1.
## Worst case at 150: 72 + 58 + 61 + 37 + 4 gaps = 236 of 238. At 100 the
## bullets gain 16px. tests/unit/test_text_scale_layout.gd holds the sum.
const CARD_GAP := 2
const NAME_GAP := 1

func _candidate_card(who, index: int) -> Control:
	var card := Widgets.panel("PanelRound", 12)
	card.custom_minimum_size = Vector2(Widgets.CARD_SIZE.x, Widgets.CARD_SIZE.y)
	card.clip_contents = true
	var selected := index == _selected
	if selected:
		card.theme_type_variation = "PanelRoundSelected"
	else:
		card.add_theme_stylebox_override("panel", _rarity_rim(int(who.rarity)))
	var col := Widgets.column(CARD_GAP)

	var top := Widgets.row(10)
	top.add_child(Widgets.slot_rarity(int(who.rarity), Cards.portrait_for(who), Widgets.PORTRAIT_SLOT))
	var names := Widgets.column(NAME_GAP)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Widgets.label_as(String(who.display_name), "LabelName")
	name_label.add_theme_color_override("font_color", Palette.rarity_color(who.rarity))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(name_label)
	names.add_child(_gear_slots(who))
	top.add_child(names)
	col.add_child(top)
	# The class line takes the card's full width under the portrait row: beside
	# the portrait it had 125px and "Wizard — Common" trimmed (shot 1), and a
	# class name is never truncated (docs/13 §4.4) — at 150% it WRAPS ("Wizard —"
	# / "Common"). It is shaped at the card's inner width before its first
	# layout pass, so the minimum height the tests read is the wrapped height
	# and not the one-word-per-line height a zero-width Label reports. The
	# Legendary's "1 of 1" stamp (docs/02 §5.3) sits at the row's end, where a
	# wrapped class line costs the stamped card no extra height.
	var class_row := Widgets.row(6)
	var class_label := Widgets.label_as("%s — %s" % [
		Enums.class_name_of(who.class_id), Enums.rarity_name_of(who.rarity)], "LabelMuted")
	class_label.add_theme_color_override("font_color", Palette.TEXT_SLATE)
	class_label.add_theme_constant_override("line_spacing", 0)
	class_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	class_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_label.size = Vector2(Widgets.CARD_SIZE.x - 24, 0)
	class_row.add_child(class_label)
	if who.rarity == Enums.Rarity.LEGENDARY:
		var stamp := Widgets.stamp("1 OF 1")
		stamp.size_flags_horizontal = Control.SIZE_SHRINK_END
		stamp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		class_row.add_child(stamp)
	col.add_child(class_row)

	# Canon's morale line — a recruit arrives at their rarity's baseline.
	#
	# docs/13 §13 (blocking) counts FOUR channels on every morale reading: "the
	# integer, the state word, the glyph, and the chip's lightness". The state
	# word is the only one of the four a screen test can read, since no test
	# can see a colour, and it takes the second line of the row: §9.4's S06
	# wireframe is `Starts 52 (o)` then `Content`, and at 13px "Loves Their
	# Guild" plus the figure overruns the 191px content width, which §14
	# forbids resolving by truncation.
	var m: int = int(who.morale)
	var morale := Widgets.column(0)
	morale.name = "Morale"
	var mrow := Widgets.label_as("starts at %d %s"
		% [m, Cards.morale_glyph(self, m)], "LabelClass")
	mrow.add_theme_color_override("font_color", Palette.morale_color(m))
	morale.add_child(mrow)
	var mword := Widgets.label_as(Enums.morale_band_name(m), "LabelSmall")
	mword.add_theme_color_override("font_color", Palette.morale_color(m))
	morale.add_child(mword)
	col.add_child(morale)

	# THE BULLETS SCROLL RATHER THAN GROWING THE CARD, AND THAT IS A REFLOW, NOT A
	# TRUNCATION. `custom_minimum_size` is a MINIMUM: `Cards.roster_strip` assigns
	# every card `Widgets.CARD_SIZE`, but a Control cannot be sized below its own
	# combined minimum, so before this the card GREW past spec 01 §3's authored
	# 215x262. Measured on a mounted Tavern at 1536x1024 (strip top y=734, spec 01
	# §4.2 "unify at y=995"): four bullets made the card 318 tall, bottom y=1052,
	# and put 16px of the 35px primary control below the 1024 frame — docs/13 §14.
	# With the longest bullet in data/backstories.json it reached 398 and y=1132.
	#
	# docs/04 §6.2 allows 2-3 bullets at the middle rarities and
	# `BackstoryPool.MAX_BULLETS` = 4 for a Legendary, and docs/04 §3.5 forbids
	# hiding any of them behind a submenu, so the card cannot answer this by showing
	# fewer. docs/13 §4.4 names the mechanism that is allowed: layouts "reflow by
	# reducing row count (scrolling), never by truncating". Every bullet is still
	# built, still a Label, still read by the screen tests; the card holds its
	# authored box, and the sidebar still shows the whole backstory at 330px. The
	# conflict itself — a fixed 215x262 card that must carry four wrapped bullets —
	# is filed in build/plan/q-a11y-legible.md.
	#
	# No width is set on the lines: inside a ScrollContainer with horizontal
	# scrolling disabled the child is forced to the container's width, so the
	# bullets wrap to whatever is left beside the scrollbar instead of claiming
	# 187px and pushing the card wider than its 224px pitch.
	var bullets := Widgets.column(3)
	bullets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for bullet in who.backstory:
		var line := Widgets.label_as("• " + _bullet_text(bullet), "LabelSmall")
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_theme_color_override("font_color", _bullet_tone(bullet))
		bullets.add_child(line)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# The one child that takes the card's slack, which is what pins the button to
	# the card's bottom edge whether there are two bullets or four.
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(bullets)
	col.add_child(scroll)

	# "Look" puts the candidate in the sidebar. On the selected card it reads
	# "Looking" and stays enabled in the active-tab plate (the same idiom as the
	# kit's tab row, whose active tab is a live Button): a disabled "Looking"
	# would owe a reason line the 262px card has no room for, and pressing it
	# is the harmless re-selection a tab press is. The plain one is the kit
	# card's action plate (W5-SCALE, see the header note).
	var look := Widgets.button("Looking" if selected else "Look")
	look.theme_type_variation = "NavItemActive" if selected else "ButtonCardAction"
	look.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	look.pressed.connect(func() -> void:
		if _selected != _index_of(who):
			# docs/13 §12.4 `ui.row_select`: the pick, on change only (W6-AUD-BIND).
			var audio: Node = Services.find(self, "Audio")
			if audio != null:
				audio.play("ui.row_select")
		_selected = _index_of(who)
		_active = "board"
		_refresh())
	col.add_child(look)

	Widgets.content_of(card).add_child(col)
	return card


## The three "arrives with" slots (docs/02 §5.3, spec 10 §3.3): the slot's own
## picture through `Cards.gear_icon`, padded with empty cells to three, the item
## named in the cell's tooltip — the words are in the sidebar's "arrives with"
## Label, so nothing here is tooltip-only.
func _gear_slots(who) -> Control:
	var slots := Widgets.row(4)
	slots.name = "Gear"
	var shown := 0
	var db = _state.content if _state != null else null
	if db != null:
		for it in who.equipped_items(db):
			if shown >= 3:
				break
			var cell := Widgets.slot(Cards.gear_icon(int(it.slot), true, it), GEAR_CELL, "SlotMini")
			# KIT-22 / UI-49's sweep (handoff-W6-SHEETS): the two-line plate;
			# `tooltip_text` kept as the "slot — item" words the tests read.
			Widgets.tooltip_for(cell, String(it.name), Enums.slot_name_of(int(it.slot)))
			cell.tooltip_text = "%s — %s" % [Enums.slot_name_of(int(it.slot)), String(it.name)]
			slots.add_child(cell)
			shown += 1
	while shown < 3:
		slots.add_child(Widgets.slot(null, GEAR_CELL, "SlotMini"))
		shown += 1
	return slots


## The rarity-bordered card (06 §2's variant): the theme's own PanelRound box
## with its rim recoloured and widened to 2px, so a repaint of the corner radius
## or the fill flows through; the Legendary adds the 1px outer glow docs/13 §9.4
## frames it with. Falls back to a flat box if the theme's is not a flat one.
func _rarity_rim(rarity: int) -> StyleBox:
	var colour := Palette.rarity_color(rarity)
	var th: Theme = Theme_.current(self)
	var box: StyleBox = th.get_stylebox("panel", "PanelRound") if th.has_stylebox("panel", "PanelRound") else null
	var s: StyleBoxFlat
	if box is StyleBoxFlat:
		s = (box as StyleBoxFlat).duplicate()
	else:
		s = Theme_.flat(Palette.SURFACE_CARD, colour, 2, 6, 0)
	s.border_color = colour
	s.set_border_width_all(2)
	if rarity == Enums.Rarity.LEGENDARY:
		s.shadow_color = Color(colour, 0.45)
		s.shadow_size = 3
		s.shadow_offset = Vector2.ZERO
	return s


func _bullet_text(bullet) -> String:
	if typeof(bullet) == TYPE_DICTIONARY:
		return String(bullet.get("text", ""))
	return str(bullet)


func _bullet_tone(bullet) -> Color:
	if typeof(bullet) == TYPE_DICTIONARY:
		match String(bullet.get("polarity", "")):
			"negative":
				return Palette.DANGER
			"positive":
				return Palette.POSITIVE
	return Palette.CAUTION


# ---------------------------------------------------------------- sidebar

## The selected candidate, in full (docs/04 §3.5's list: portrait and name, class and
## role, rarity, mistake chance as a plain percentage, arriving gear, every bullet,
## wishlist, cost) — and the one commit control.
##
## TOWN-17: the column lives in a ScrollContainer the SCREEN builds inside the
## kit's sidebar panel (never inside Frame), so the panel's minimum never
## carries the column and the rim stays at y=714 whatever is in it. The common
## case — two or three bullets at text scale 100 — fits without a bar (a test
## does the arithmetic); the Legendary with four two-line bullets and the 150%
## scale scroll, with the bar inside the rim where it can be seen (LESSONS: a
## bar the panel edge hides is no fix).
func _build_sidebar() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "SidebarScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side_host.add_child(scroll)
	var col := Widgets.column(6)
	col.name = "SidebarCol"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	if _active == "manage":
		col.add_child(Widgets.label_as("Manage", "LabelSection"))
		var warn := _wrapped("Letting somebody go costs the people who stay. It always does.", "LabelSmall")
		col.add_child(warn)
		_sidebar_footer(col)
		return

	var board: Array = _state.tavern_board
	if board.is_empty():
		col.add_child(Widgets.label_as("The Board", "LabelSection"))
		col.add_child(Widgets.empty_state("Nobody is drinking."))
		_sidebar_footer(col)
		return

	var who = board[_selected]
	col.add_child(Widgets.label_as("At the bar", "LabelSection"))

	var head := Widgets.row(12)
	head.add_child(Widgets.slot(Cards.portrait_for(who), 90, "PortraitFrame"))
	var names := Widgets.column(2)
	var name_label := Widgets.label_as(String(who.display_name), "LabelSubject")
	name_label.add_theme_color_override("font_color", Palette.rarity_color(who.rarity))
	names.add_child(name_label)
	names.add_child(Widgets.label_as("%s — %s" % [
		Enums.class_name_of(who.class_id), Enums.rarity_name_of(who.rarity)], "LabelClass"))
	if who.rarity == Enums.Rarity.LEGENDARY:
		names.add_child(Widgets.stamp("1 OF 1"))
	head.add_child(names)
	col.add_child(head)

	# docs/04 §3.5: "mistake chance as a plain percentage". The whole point of rarity.
	var chance: float = Formulas.mistake_chance(who.rarity, who.morale)
	col.add_child(_wrapped(
		"starts at %d morale  ·  misses about %.0f%% of the time  ·  %d raids behind them"
			% [who.morale, chance * 100.0, who.raid_experience], "LabelSmall"))

	var gear := _wrapped("arrives with %s" % _gear_line(who), "LabelSmall")
	gear.add_theme_color_override("font_color", Palette.TEXT_MUTED_WARM)
	col.add_child(gear)

	col.add_child(Widgets.rule())
	for bullet in who.backstory:
		var line := _wrapped("• " + _bullet_text(bullet), "LabelBody")
		line.add_theme_color_override("font_color", _bullet_tone(bullet))
		col.add_child(line)
	if not who.wishlist.is_empty():
		col.add_child(_wrapped("wants: %s" % ", ".join(PackedStringArray(who.wishlist)), "LabelSmall"))
	col.add_child(Widgets.rule())

	# The one crimson control on the screen (docs/13 §3): hiring is the commit.
	var price := Recruitment.cost_of(who.rarity, _state.highest_unlocked_tier())
	var reason := ""
	if _state.roster_is_full():
		reason = "The roster is full at %d." % _state.roster_cap()
	elif _state.gold < price:
		reason = "Costs %d G — you have %d." % [price, _state.gold]
	var btn := Widgets.cta("Hire — %d G" % price)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func() -> void:
		var problem: String = _state.hire(_index_of(who))
		_say(problem if not problem.is_empty()
			else "%s signs on. They seem pleased, which is a bad sign."
				% who.display_name)
		_refresh())
	col.add_child(_reasoned(btn, reason, SIDE_TEXT_W))

	# docs/04 §3.4: "dismissing a candidate from the board is free and instant".
	var shoo := Widgets.button("Not tonight")
	shoo.pressed.connect(func() -> void:
		_state.dismiss_candidate(_index_of(who))
		_say("They go back to the bar.")
		_refresh())
	col.add_child(shoo)

	_sidebar_footer(col)


## The way out — the same on every tab (TOWN-31: the quiet Button, never a link,
## so a test that presses "Back to town" finds a Button).
func _sidebar_footer(col: VBoxContainer) -> void:
	col.add_child(Widgets.rule())
	var back := Widgets.button("Back to town")
	back.theme_type_variation = "ButtonQuiet"
	back.pressed.connect(func() -> void:
		if _router != null:
			_router.goto(TOWN))
	col.add_child(back)


## A wrapped sidebar/plate line at the column's text width (LESSONS: one
## uncapped Label widens the whole column and every wrapped sibling with it).
func _wrapped(text: String, variation: String, width: int = SIDE_TEXT_W) -> Label:
	var l := Widgets.label_as(text, variation)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


## The kit's disabled-with-reason treatment, with the reason allowed to WRAP at
## `width` — `Widgets.reasoned` leaves its reason on one line by design and asks
## a caller that wants a wrap to give the box a width; "Unknown guilds cannot
## commission this. Reach Known." is wider than the plate's column at 150%.
func _reasoned(control: Control, reason: String, width: int) -> Control:
	var box := Widgets.reasoned(control, reason)
	var why := box.get_node_or_null("Reason")
	if why is Label:
		(why as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(why as Label).custom_minimum_size = Vector2(width, 0)
	return box


## docs/10 §13 row 2's collection meter, on the screen where Legendaries are
## actually found. ✅ CANON: "You can only ever find 1 Legendary per class", so the
## goal is nine — but nine is never typed here or anywhere: `legendary_goal()` is
## the length of the class list, and a class added or cut moves the meter with it.
##
## It is a fact about the SAVE, not about whoever is at the bar tonight, so it
## sits on the caption plate with the house's other facts — which `_refresh()`
## rebuilds after a hire exactly as it rebuilds the sidebar (LESSONS: put a fact
## where the thing that rebuilds it lives), on every tab and on an empty board.
##
## ONE line: canon's "one per class" is already stated on the Legendary card's
## 1 OF 1 stamp. Phrased by `Achievements.legendary_meter()` and nowhere else:
## the Guildhall's Records tab and the completion screen print the same
## sentence, and three screens with three phrasings of one number is how a meter
## starts disagreeing with itself.
func _collection_meter(col: VBoxContainer) -> void:
	if _state == null:
		return
	var snap := Achievements.snapshot(_state)
	col.add_child(Widgets.label_as(Achievements.legendary_meter(snap), "LabelLabel"))


## docs/04 §3.2's paid refresh, and the sentence that explains why it is priced this way:
## "Tying refresh to runs means 'go do a raid' is always the answer to a bad board."
func _reroll_row() -> Control:
	var col := Widgets.column(1)
	var price: int = _state.reroll_cost()
	var reason := ""
	if _state.gold < price:
		reason = "Costs %d G — you have %d." % [price, _state.gold]
	var b := Widgets.button("Ask around again — %d G" % price)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func() -> void:
		var problem: String = _state.pay_to_reroll()
		_say(problem if not problem.is_empty() else "A different four walk in.")
		_selected = 0
		_refresh())
	col.add_child(_reasoned(b, reason, PLATE_RIGHT_W))
	var note := _wrapped(
		"Free after any run. The price doubles each time you pay, and resets when you raid.",
		"LabelSmall", PLATE_RIGHT_W)
	note.add_theme_color_override("font_color", Palette.TEXT_MUTED_WARM)
	col.add_child(note)
	return col


func _upgrade_row() -> Control:
	var level: int = _state.tavern_tier
	if level >= Buildings.top_level("tavern"):
		return _wrapped("The house is as big as it gets: %d seats."
			% _state.board_slots(), "LabelSmall", PLATE_RIGHT_W)
	var cost := Buildings.upgrade_cost("tavern", level)
	var blocker := Buildings.upgrade_blocker("tavern", level, _state.gold,
		_state.reputation_rank)
	var b := Widgets.button("Take the room next door — %d G, one more seat" % cost)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func() -> void:
		var problem: String = _state.upgrade_building("tavern")
		_say(problem if not problem.is_empty()
			else "They knock through. Room for %d now." % _state.board_slots())
		_refresh())
	return _reasoned(b, blocker, PLATE_RIGHT_W)


func _gear_line(who) -> String:
	if _state.content == null:
		return "whatever they stood up in"
	var worn: Array = []
	for slot in Enums.all_slots():
		var it = who.item_in(_state.content, int(slot))
		if it != null:
			worn.append(it.name)
	if worn.is_empty():
		return "nothing anyone would call armour"
	return ", ".join(PackedStringArray(worn))


## The board shifts when a card is taken, so a captured index goes stale. Looking the
## candidate up by identity at press time is what keeps the wrong person from being hired.
func _index_of(who) -> int:
	for i in _state.tavern_board.size():
		if _state.tavern_board[i] == who:
			return i
	return -1


# ---------------------------------------------------------------- manage

## docs/02 §5.3's Manage tab: "Current roster with dismiss action + confirmation that
## names the morale consequence."
func _build_manage() -> void:
	if _state.roster.is_empty():
		_manage_host.add_child(Widgets.empty_state("Nobody to manage."))
		return
	for r in _state.roster:
		_manage_host.add_child(_manage_row(r))
		_manage_host.add_child(Widgets.rule())


func _manage_row(r) -> Control:
	var row := Widgets.row(10)
	row.add_child(Widgets.slot(Cards.portrait_for(r), Widgets.MINI_CELL, "SlotMini"))
	var lines := Widgets.column(0)
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m: int = int(r.morale)
	var l1 := Widgets.label_as("%s — %d %s"
		% [r.display_name, m, Cards.morale_glyph(self, m)], "LabelMorale")
	l1.add_theme_color_override("font_color", Palette.morale_color(m))
	lines.add_child(l1)
	lines.add_child(Widgets.label_as("%s — %s  ·  %s" % [
		Enums.class_name_of(r.class_id), Enums.morale_band_name(m),
		Enums.rarity_name_of(r.rarity)], "LabelClass"))
	row.add_child(lines)

	var rid: String = r.id
	if _confirming == rid:
		# docs/02 §5.3 asks the confirmation to NAME the consequence, and docs/05 §12
		# Q12 supplies the number: "-2 to all remaining, versus -4 for a departure.
		# Cheaper, but not free." CRITIC-G05: the kit's one confirm shape — a
		# DANGER-rimmed plate, both halves Buttons with these exact texts, "Keep
		# them" focused by default.
		var pair := Widgets.confirm_pair(
			"Yes — let them go (-2 morale to everyone else)", "Keep them",
			func() -> void:
				var problem: String = _state.dismiss_raider(rid)
				_confirming = ""
				_say(problem if not problem.is_empty()
					else "%s clears out. The others notice." % r.display_name)
				_refresh(),
			func() -> void:
				_confirming = ""
				_refresh())
		pair.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pair)
	else:
		var b := Widgets.button("Dismiss")
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(func() -> void:
			_confirming = rid
			_notice = ""
			_refresh())
		row.add_child(b)
	return row


func active_tab() -> String:
	return _active
