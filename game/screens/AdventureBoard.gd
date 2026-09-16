extends Control
## S09 — the Adventure's Board (docs/13 §5).
##
## ✅ CANON spells it "Adventure's Board", not "Adventurer's", and lists the
## ladder itself: *"Adventure 0 - 1 Trash mob (Just for learning - 1 crap
## trinket) … Adventure 1 - a few trash encounters and a mini boss … This
## continues or can go raid raid, adventure adventure"*.
##
## ❓ OPEN, decided here and logged as docs/15 BL-24 — **what is one mission?**
## `RaidSim.run()` resolves exactly one encounter, and Tier 1 ships five of them
## (E1-E5). Canon's board lists missions of varying size without saying how a
## multi-encounter raid is chunked, and docs/13 S13 wants an interstitial with
## HP carry-over between encounters, which does not exist yet.
##
## **Decision: one board rung = one encounter**, in tier order, with clears
## remembered. That is the honest mapping of the content and the sim we have —
## it gives real progression today and leaves S13's carry-over as an addition
## rather than a rewrite. The rung labels use each encounter's own display name,
## so renaming content renames the board.
##
## The art pass puts this on the reference frame (10 §3.8, archetype A): the
## camp in the scene viewport with the notices pinned over it as a
## selectable list, the SELECTED notice in the sidebar as Concept 1's mission
## panel with the one crimson commit ("Go to prep"), the roster cards and the
## event log along the bottom. Pressing a rung still does what it always did —
## chooses it and walks into prep — so the loop test's "A1" press lands where
## it used to.
##
## W2-BOARD (TOWN-24, TOWN-11, RULES-07/TOWN-25, TOWN-10): the list is a cork
## panel; every notice is a paper `ButtonNotice` named `Notice_<id>` that a
## keyboard can reach — focusing or pressing it PINS the notice to the sidebar,
## the rung Button inside it still walks into prep — with a 20px rung ladder
## down the left (tick / pin / padlock joined by a line, one "Tier N" divider
## per tier), a bounded scroll whose bar sits inside the rim, and a fade at
## the bottom while there is more below.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Services = preload("res://game/core/Services.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")
const Achievements = preload("res://sim/core/Achievements.gd")

const TOWN := "res://game/screens/Town.tscn"
const RAID_PREP := "res://game/screens/RaidPrep.tscn"

## 00 §2.6's rail, with this screen lit.
const RAIL := [
	{"id": "home", "label": "Camp", "scene": TOWN},
	{"id": "tavern", "label": "Tavern", "scene": "res://game/screens/Tavern.tscn"},
	{"id": "roster", "label": "Roster", "scene": "res://game/screens/Guildhall.tscn"},
	{"id": "market", "label": "Market", "scene": "res://game/screens/Market.tscn"},
	{"id": "board", "label": "Adventure's Board", "scene": ""},
	{"id": "options", "label": "Options", "scene": "res://game/screens/Settings.tscn"},
]

## The scene viewport is 928x640 (Frame); the notices take the left of it and
## leave the camp visible on the right.
const LIST_RECT := Rect2(18, 14, 490, 610)
## The cork's own content margin is 12 (Theme.gd); this is the Pad on top of it.
const LIST_PAD := 8
## The rung ladder (TOWN-11): a 20px column left of every paper, a 2px line
## down its middle, a 16px state glyph on the line at the title's height.
const LADDER_W := 20
const LADDER_GAP := 6
const LADDER_LINE_X := 9
const GLYPH := 16
const GLYPH_Y := 20
## Papers are 6px apart, but the gap is carried INSIDE each row (3 above, 3
## below) so the ladder line runs unbroken from rung to rung.
const ROW_GAP := 6
const ROW_PAD := 3
## Room on the paper's right for the 2px focus ring the scroll would clip.
const RING_CLEAR := 4
const PAPER_PAD := 8
const FADE_H := 24
## Wrapped text minimums. The list: 490 - 2*(12+8) cork = 450, minus the 8px
## bar, the ladder (26) and the paper's pads (16 + 4) = 396. The sidebar:
## 378 - 2*(18+14) PanelWarm = 314 — the width the content actually has, not
## the 330 it used to claim and overflow with (TOWN-17).
const LIST_TEXT_W := 380
const SIDEBAR_TEXT_W := 314
const SIDEBAR_ART := Vector2(314, 88)

## Where the camp's 1536x1024 plate sits. See `_scene()` — it is chosen for the
## right half, the only half of the viewport the notices do not cover.
const CAMP_OFFSET := Vector2(-20, -80)

## Dimmed so the pinned notices are what gets read. Was 0.6 against the hall
## crop; eased a step because the firelight it is taking down is ours now.
const SCENE_DIM := Color(0.68, 0.68, 0.72)
## A locked notice's quip and facts, greyed on the greyed paper.
const LOCKED_DIM := Color(1, 1, 1, 0.7)

var _router = null
var _state = null
var _built := false
var _selected := ""
var _frame = null
var _list_host: VBoxContainer = null
var _list_scroll: ScrollContainer = null
var _fade: Control = null
var _side_col: VBoxContainer = null
var _goal_host: VBoxContainer = null
## id -> the row Control / the paper Button, for selection without a rebuild.
var _rows: Dictionary = {}
var _notices: Dictionary = {}
## id -> the empty column on a skippable paper that holds the skip block
## while that notice is the selected one.
var _skip_hosts: Dictionary = {}


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
	_selected = _default_selection()
	_build()


func _build() -> void:
	var nav: Array = []
	for item in RAIL:
		var scene := String(item["scene"])
		var reason := ""
		if not scene.is_empty() and (_router == null or not _router.screen_exists(scene)):
			reason = "Not built in this version yet."
		nav.append({"id": item["id"], "label": item["label"], "reason": reason})

	_frame = Frame.build(self, {"nav": nav, "active": "board", "framed": true})
	for item in RAIL:
		var scene := String(item["scene"])
		var b: Button = _frame.nav_buttons.get(String(item["id"]))
		if b != null and not scene.is_empty() and not b.disabled:
			b.pressed.connect(func() -> void: _router.push(scene))

	_scene(_frame.scene)
	# 00 §2.5's four chips are the frame's (KIT-03): one builder, the rank sigil.
	Frame.standard_chips(_frame, _state)
	_side_col = Widgets.column(3)
	var side: Control = Frame.sidebar(_frame)
	if side != null:
		side.add_child(_side_col)
	_strip(_frame.strip)
	_refresh()


# ---------------------------------------------------------------- the scene

## The board stands in the CAMP, not in the hall — and this screen had it wrong.
##
## It used to load the Concept 1 hall crop on a comment that read "the board lives
## in the hall". Spec 09 says otherwise twice: §1.3's table gives AdventureBoard
## "(a)-derived: C3 crop, dimmed", and §4.2's heading is "Town / Camp (C3-CAMP)
## — also Market / Facilities / AdventureBoard with the plate dimmed". The
## game's own Town agrees: `Town.BUILDINGS` puts the Adventure's Board outside,
## by the bridge, as one of canon's five buildings. So the backdrop is the camp,
## on the bare plate, dimmed so the notices pinned over it are what gets read.
##
## The offset is for the RIGHT half of the viewport, because the notices panel is
## opaque over x 18..508: (-20, -80) puts the campfire at window x 700 with the
## four figures round it, the mess tent above them, and the camp's own speaking
## bubble just clear of the panel's edge.
func _scene(host: Control) -> void:
	var stage := SceneStage.load("stage_camp")
	stage.position = CAMP_OFFSET
	stage.size = host.size - CAMP_OFFSET
	stage.modulate = SCENE_DIM
	host.add_child(stage)

	# TOWN-24: the cork. The panel is sized by hand and clips, so the list can
	# never grow the board; the scroll below is bounded by what is left.
	var panel := Widgets.panel("PanelCork", LIST_PAD)
	panel.name = "Board"
	host.add_child(panel)
	panel.position = LIST_RECT.position
	panel.size = LIST_RECT.size
	panel.clip_contents = true

	var col := Widgets.column(6)
	col.add_child(Widgets.label_as("Adventure's Board", "LabelSection"))
	var tag := Widgets.label_as(
		"Notices pinned to cork, in the order the guild is ready for them.",
		"LabelSmall")
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size = Vector2(LIST_TEXT_W, 0)
	col.add_child(tag)
	_goal_host = Widgets.column(2)
	col.add_child(_goal_host)

	# TOWN-10: a plain Control takes the column's remaining height and hands it
	# to the scroll by anchors, so the scroll IS bounded and its bar shows —
	# inside the cork's rim, because the scroll's rect is inside the Pad.
	var wrap := Control.new()
	wrap.name = "ListWrap"
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list_scroll = ScrollContainer.new()
	_list_scroll.name = "Notices"
	_list_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_host = Widgets.column(0)
	_list_host.name = "Rows"
	_list_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list_host)
	wrap.add_child(_list_scroll)
	_fade = _fade_strip()
	wrap.add_child(_fade)
	col.add_child(wrap)
	Widgets.content_of(panel).add_child(col)

	# The fade is a cue that there is MORE, so it goes when the list is at its
	# end (or never scrolls at all): re-read on every bar change.
	var bar := _list_scroll.get_v_scroll_bar()
	bar.changed.connect(_update_fade)
	bar.value_changed.connect(func(_v: float) -> void: _update_fade())
	_update_fade()


## The 24px gradient at the list's foot (TOWN-10): the cork falling into
## shadow under the last visible paper. It stops short of the bar's column
## so the grabber is never covered.
func _fade_strip() -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([
		Color(Palette.SURFACE_PAPER, 0.0), Color(Palette.SURFACE_PAPER, 0.92)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 8
	tex.height = FADE_H
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var t := TextureRect.new()
	t.name = "Fade"
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	t.offset_left = 0
	t.offset_right = -8
	t.offset_top = -FADE_H
	t.offset_bottom = 0
	return t


func _update_fade() -> void:
	if _fade == null or _list_scroll == null:
		return
	var bar := _list_scroll.get_v_scroll_bar()
	_fade.visible = bar.visible and bar.value + bar.page < bar.max_value - 0.5


## One notice: a ladder cell, then the paper.
##
## The paper is a full-rect `ButtonNotice` named `Notice_<id>` (RULES-07,
## TOWN-25) — text "", FOCUS_ALL — whose `pressed` AND `focus_entered` pin the
## notice to the sidebar, so an arrow key reads a locked notice the way a click
## does. The words sit in a MOUSE_FILTER_IGNORE pad over it, so a click on the
## quip falls through to the paper. The rung Button keeps "<slot> — <name>" as
## its text (the loop test presses "A1" by fragment) and still walks into prep;
## the quip, facts and reason are Labels (test_raid_plan reads them).
func _rung(e) -> Control:
	var reason := _locked_reason(e)
	var cleared: bool = _state != null and _state.has_cleared(e.id)
	var enc_id: String = e.id
	var is_selected: bool = enc_id == _selected
	var locked: bool = not reason.is_empty()

	var row := Widgets.row(LADDER_GAP)
	row.name = "Row_" + enc_id
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rung_state := "open"
	if cleared:
		rung_state = "cleared"
	elif locked:
		rung_state = "locked"
	row.add_child(_ladder_cell(rung_state))

	var wrap := MarginContainer.new()
	wrap.name = "Paper"
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override("margin_left", 0)
	wrap.add_theme_constant_override("margin_right", RING_CLEAR)
	wrap.add_theme_constant_override("margin_top", ROW_PAD)
	wrap.add_theme_constant_override("margin_bottom", ROW_PAD)
	row.add_child(wrap)

	var notice := Button.new()
	notice.name = "Notice_" + enc_id
	notice.theme_type_variation = "ButtonNotice"
	notice.text = ""
	notice.focus_mode = Control.FOCUS_ALL
	notice.set_meta("locked", locked)
	notice.pressed.connect(func() -> void: _select(enc_id))
	notice.focus_entered.connect(func() -> void: _select(enc_id))
	wrap.add_child(notice)
	_dress_notice(notice, is_selected)
	_notices[enc_id] = notice
	# The pin (TOWN-24): the theme's icon, top-centre, its head over the rim.
	var pin_tex := _theme_icon("pin", "PanelPaper")
	if pin_tex != null:
		var pin := TextureRect.new()
		pin.name = "Pin"
		pin.texture = pin_tex
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin.set_anchors_preset(Control.PRESET_CENTER_TOP)
		pin.offset_left = -6
		pin.offset_right = 6
		pin.offset_top = -3
		pin.offset_bottom = 9
		notice.add_child(pin)

	var pad := MarginContainer.new()
	pad.name = "Words"
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, PAPER_PAD)
	wrap.add_child(pad)
	var col := Widgets.column(2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(col)

	var head := Widgets.row(6)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var btn := Widgets.button("%s — %s" % [e.slot, e.display_name])
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# CRITIC-G15: at text scale 150 "A1 — Adventure 1 — Encounter 1" plus the
	# stamp is wider than the paper, and an unwrapped Button widens the whole
	# board (seen: the papers ran under the camp). Wrapping zeroes the Button's
	# claimed width, so it takes what the row gives and grows the row instead.
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.disabled = locked
	if not locked:
		btn.pressed.connect(func() -> void: _on_pick(enc_id))
	btn.focus_entered.connect(func() -> void: _select(enc_id))
	head.add_child(btn)
	# TOWN-24: the state as a stamp. "CLEARED" is also printed in the facts
	# line below, which is the text test_raid_plan reads.
	if cleared:
		head.add_child(Widgets.stamp("CLEARED", Palette.POSITIVE))
	elif locked:
		head.add_child(Widgets.stamp("LOCKED", Palette.CAUTION))
	col.add_child(head)

	# docs/10 §6 requires every encounter to carry a comedy line. Printing it on
	# the board is what makes the ladder read as a place rather than a list.
	var quip := Widgets.label_as(e.comedy_line, "LabelQuote")
	quip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quip.custom_minimum_size = Vector2(LIST_TEXT_W, 0)
	col.add_child(quip)

	var facts := Widgets.label_as(_facts_of(e, cleared), "LabelSmall")
	# One line at 100; at 150 it wraps and grows the row rather than widening
	# the board (the one unwrapped Label sets the whole column's width — LESSONS).
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts.custom_minimum_size = Vector2(LIST_TEXT_W, 0)
	if cleared:
		facts.add_theme_color_override("font_color", Palette.POSITIVE)
	col.add_child(facts)
	if locked:
		quip.modulate = LOCKED_DIM
		facts.modulate = LOCKED_DIM

	if locked:
		var why := Widgets.label_as(reason, "LabelSmall")
		why.add_theme_color_override("font_color", Palette.CAUTION)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(LIST_TEXT_W, 0)
		col.add_child(why)

	# docs/10 §9.3's forfeit warning and the skip live ON the tutorial's own
	# paper, filled only while it is the selected notice (see `_skip_block`).
	if _is_skippable(e):
		var skip_host := Widgets.column(2)
		skip_host.name = "Skip"
		skip_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(skip_host)
		_skip_hosts[enc_id] = skip_host
		if is_selected:
			skip_host.add_child(_skip_block(e))
	return row


## The paper's chrome for its state. Selected = the theme's pressed box (the
## steel rim) held as `normal` and `hover`, so the row reads as chosen without
## `toggle_mode` (whose second click would un-choose it). Locked = the theme's
## dimmed box as `normal` — greyed paper that still lights on hover and still
## takes focus, because a locked notice must remain readable (TOWN-25).
func _dress_notice(b: Button, selected: bool) -> void:
	b.remove_theme_stylebox_override("normal")
	b.remove_theme_stylebox_override("hover")
	var th: Theme = theme if theme != null else Theme_.current(self)
	if selected and th.has_stylebox("pressed", "ButtonNotice"):
		var box: StyleBox = th.get_stylebox("pressed", "ButtonNotice")
		b.add_theme_stylebox_override("normal", box)
		b.add_theme_stylebox_override("hover", box)
	elif bool(b.get_meta("locked", false)) and th.has_stylebox("disabled", "ButtonNotice"):
		b.add_theme_stylebox_override("normal", th.get_stylebox("disabled", "ButtonNotice"))


## An icon slot off the theme (the pin lives on PanelPaper), null when the
## theme has none — the row then simply has no pin, never a stand-in path.
func _theme_icon(icon_name: String, type_name: String) -> Texture2D:
	var th: Theme = theme if theme != null else Theme_.current(self)
	if th != null and th.has_icon(icon_name, type_name):
		return th.get_icon(icon_name, type_name)
	return null


## The ladder cell (TOWN-11): a 20px column with the 2px line, broken around
## the state glyph — a gold tick (cleared), the pin (open), the padlock
## (locked) — or unbroken when `state` is "" (a tier divider).
func _ladder_cell(state: String) -> Control:
	var cell := Control.new()
	cell.name = "Ladder"
	cell.custom_minimum_size = Vector2(LADDER_W, 0)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if state.is_empty():
		cell.add_child(_ladder_line(0.0, 1.0, 0.0))
		return cell
	cell.add_child(_ladder_line(0.0, 0.0, GLYPH_Y - 2.0))
	cell.add_child(_ladder_line(GLYPH_Y + GLYPH + 2.0, 1.0, 0.0))
	var glyph := _rung_glyph(state)
	if glyph != null:
		glyph.position = Vector2(2, GLYPH_Y)
		glyph.size = Vector2(GLYPH, GLYPH)
		cell.add_child(glyph)
	return cell


## A segment of the ladder line from `top` down to (`bottom_anchor` of the
## cell's height + `bottom_offset`).
func _ladder_line(top: float, bottom_anchor: float, bottom_offset: float) -> ColorRect:
	var line := ColorRect.new()
	line.name = "Rung"
	line.color = Palette.EDGE_PAPER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.anchor_left = 0.0
	line.anchor_right = 0.0
	line.offset_left = LADDER_LINE_X
	line.offset_right = LADDER_LINE_X + 2
	line.anchor_top = 0.0
	line.offset_top = top
	line.anchor_bottom = bottom_anchor
	line.offset_bottom = bottom_offset
	return line


## The 16px state glyph. The padlock is the grid's `lock_16`; the pin is the
## theme's; the tick is drawn (two gold strokes) because the grid has none yet
## — build/plan/handoff-W2-BOARD.md asks for one.
func _rung_glyph(state: String) -> Control:
	if state == "cleared":
		return _tick(Palette.ACCENT_GOLD)
	var glyph := TextureRect.new()
	glyph.name = "Glyph"
	if state == "locked":
		glyph.texture = Icons.at("lock", "16")
	else:
		glyph.texture = _theme_icon("pin", "PanelPaper")
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return glyph


## A tick in a 16x16 box: a short stroke down to the foot, a long one up out
## of it, both 2px, rotated about the foot.
func _tick(colour: Color) -> Control:
	var box := Control.new()
	box.name = "Glyph"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var foot := Vector2(6, 13)
	box.add_child(_stroke(foot, 6.0, -45.0, colour))
	box.add_child(_stroke(foot, 12.0, 45.0, colour))
	return box


func _stroke(foot: Vector2, length: float, deg: float, colour: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = colour
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size = Vector2(2, length)
	r.pivot_offset = Vector2(1, length)
	r.position = foot - Vector2(1, length)
	r.rotation_degrees = deg
	return r


## "Tier N" between tiers (TOWN-11), with the ladder line running through.
func _tier_divider(tier: int) -> Control:
	var row := Widgets.row(LADDER_GAP)
	row.name = "Tier_%d" % tier
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_ladder_cell(""))
	var l := Widgets.label_as("Tier %d" % tier, "LabelLabel")
	l.custom_minimum_size = Vector2(0, 22)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	return row


func _facts_of(e, cleared: bool) -> String:
	# "Trash · 1 enemy · about 6 rounds" — the plural through the one door
	# (Type.count, LOOP-04 / UI-02); the Town's card prints the same line.
	var facts := "%s  ·  %s  ·  about %d rounds" % [
		Enums.encounter_kind_name_of(e.kind),
		Type.count(e.enemies.size(), "enemy", "enemies"), e.target_rounds]
	# docs/10 §9.3: the skip has to be DISCOVERABLE, or a replaying player pays
	# the tutorial tax without ever learning they did not have to.
	if _is_skippable(e):
		facts += "  ·  tutorial  ·  skippable"
	if cleared:
		facts += "  ·  CLEARED"
	elif _state != null and _state.skipped_tutorials.has(String(e.id)):
		facts += "  ·  SKIPPED"
	return facts


## A tutorial the guild has neither cleared nor already skipped.
func _is_skippable(e) -> bool:
	if e == null or _state == null:
		return false
	return Reputation.is_tutorial_slot(String(e.slot)) \
		and not _state.rung_resolved(String(e.id))


# ---------------------------------------------------------------- sidebar

## Concept 1's mission panel (00 §2.3, 10 §2 R3) pointed at the selected
## notice: art card, display name over kind, the encounter's own loot slots
## floored at two, and the one crimson commit.
##
## TOWN-17: everything here is capped at the 314px the panel's content
## actually has, and there is no ScrollContainer — a bar under the panel's
## edge is no fix (LESSONS). The standing paragraph is LabelMuted so the whole
## column, "Back to town" included, ends above the strip.
func _sidebar() -> void:
	var col := _side_col
	if col == null:
		return
	var e = _encounter(_selected)

	col.add_child(Widgets.label_as("Selected Notice", "LabelSection"))

	var card := Widgets.panel("PanelCard", 0)
	card.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
	card.clip_contents = true
	var cardcol := Widgets.column(0)
	cardcol.add_child(Cards.encounter_art(e, SIDEBAR_ART))
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 12)
	tm.add_theme_constant_override("margin_right", 12)
	tm.add_theme_constant_override("margin_top", 2)
	tm.add_theme_constant_override("margin_bottom", 4)
	var tbox := Widgets.column(0)
	var title := Widgets.label_as(
		e.display_name if e != null else "Nothing pinned yet", "LabelSubject")
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.custom_minimum_size = Vector2(SIDEBAR_TEXT_W - 24, 0)
	tbox.add_child(title)
	var sub := ""
	if e != null:
		sub = _facts_of(e, _state != null and _state.has_cleared(e.id))
	# This line was the one uncapped Label in the sidebar, and one uncapped
	# Label is enough: the facts of A0 are "Trash · 1 enemy · about 6 rounds ·
	# tutorial · skippable", which set the card's minimum width, which widened
	# the whole sidebar column, which made every WRAPPED label below it wrap at
	# the column's new width instead — so the skip warning and the standing
	# lines ran off the right edge of the 1536px frame entirely. Capped to one
	# line with an ellipsis (TOWN-17: the column has 571px and every line here
	# is paid for). The same facts are printed in full on the notice itself,
	# so nothing is lost by trimming here.
	var sub_label := Widgets.label_as(sub, "LabelMuted")
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_label.max_lines_visible = 1
	sub_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub_label.custom_minimum_size = Vector2(SIDEBAR_TEXT_W - 24, 0)
	tbox.add_child(sub_label)
	tm.add_child(tbox)
	cardcol.add_child(tm)
	card.add_child(cardcol)
	col.add_child(card)

	if e == null:
		col.add_child(Widgets.empty_state(
			"No notices — the guild has no content loaded to pin.",
			Icons.at("empty", "quill")))
	else:
		# The full line is on the notice itself; here it is a two-line teaser
		# — at text scale 100 only. At 125/150 the column's 571px are spent on
		# the card, the commit and the standing (CRITIC-G15: reflow, never
		# clip), and the joke is 500px to the left in full.
		if Theme_.scale_of(self) <= Type.SCALE_DEFAULT:
			var quip := Widgets.label_as(e.comedy_line, "LabelQuote")
			quip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			quip.max_lines_visible = 2
			quip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			quip.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
			col.add_child(quip)

		# 10 §2 R3: the row is data-driven from the encounter's own loot slots,
		# never a fixed four — and exactly as many cells as there are slots
		# (UI-14). It used to floor at two, so A0's one trinket sat beside an
		# empty 9-slice that read as a missing icon; the design's row is "what
		# may drop", never "how many holes". With nothing to drop the caption
		# says so instead of drawing an empty well.
		col.add_child(Widgets.label_as("Potential Rewards", "LabelLabel"))
		var n: int = e.loot_slots.size()
		if n == 0:
			var none := Widgets.label_as("Nothing worth carrying.", "LabelMuted")
			none.name = "NoRewards"
			col.add_child(none)
		else:
			var rewards := Widgets.row(9)
			rewards.name = "Rewards"
			for i in n:
				# The slot's own picture: a helm for a head drop, boots for feet.
				rewards.add_child(Widgets.slot(
					Cards.loot_slot_icon(String(e.loot_slots[i]))))
			col.add_child(rewards)

		var reason := _locked_reason(e)
		var go := Widgets.cta("Go to prep") as Button
		go.disabled = not reason.is_empty()
		var enc_id: String = e.id
		go.pressed.connect(func() -> void: _on_pick(enc_id))
		col.add_child(go)
		# 10 §2 R7: departing costs no gold, so the sub-line is the notice's
		# own facts — who it takes, or why it cannot be taken yet. No slot
		# code here (LOOP-03): "A0 · a party of 4" led with a data key.
		var note := Widgets.label_as(
			reason if not reason.is_empty()
			else "A party of %d" % e.party_size, "LabelCtaCost")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
		if not reason.is_empty():
			note.add_theme_color_override("font_color", Palette.CAUTION)
		col.add_child(note)

	col.add_child(Widgets.rule())
	for c in _standing():
		col.add_child(c)

	# TOWN-31 / CRITIC-C14: the quiet Button, not a LinkButton — the tests read
	# Button.text, and the four hub sidebars share one idiom.
	var back := Widgets.button("Back to town")
	back.name = "BackToTown"
	back.theme_type_variation = "ButtonQuiet"
	back.pressed.connect(func() -> void:
		if _router != null:
			_router.goto(TOWN))
	col.add_child(back)


## Canon, verbatim: "Tutorials can be skip, but will offer a special loot piece
## that is easy, players will be warned that they will miss out on reward if they
## skip tutorial (not a big deal - not a great piece)". docs/10 §9.3 turns that
## into two requirements — the copy must NAME the forfeited item and its stat,
## and must say plainly that it is not good, because "honesty is the joke".
##
## Every string here is a Label or a Button on purpose: the screen tests collect
## only `Label.text` and `Button.text` and press by fragment, so a warning
## rendered as a tooltip or a RichTextLabel would be the one canon-mandated
## sentence in the game that nothing tests.
##
## It lives on the board rather than in RaidPrep. docs/01 §8.3 puts a
## `TutorialSkipPrompt` after ConfirmRaid, but that row is 🔷 PROPOSED and docs/13
## §5's S01-S16 screen inventory has no state for it; the board is where the rung
## is chosen and where the notice already prints its rewards, so the forfeit is
## legible next to the thing being forfeited instead of one screen later. Logged
## in build/plan/q-tutorials.md as a docs/13 addendum rather than a new screen.
##
## W2-BOARD moved it from the sidebar onto the selected tutorial's own PAPER
## (`_skip_hosts`): the paper is the thing being forfeited, the list scrolls
## where the sidebar cannot (TOWN-17 — no ScrollContainer there), and at text
## scale 150 the sidebar could not hold the warning at all. The loop test
## presses "Skip the tutorial" by fragment wherever it is.
func _skip_block(e) -> Control:
	var box := Widgets.column(2)
	var reward: String = _state.tutorial_reward_line(String(e.id))
	if reward.is_empty():
		reward = "the tutorial trinket"
	# LOOP-24's honest reading, until the designer rules on the Tutorial Raid's
	# numbers (M6-BAL-03): the forced skip must not read as failure, so the
	# copy says what skipping costs and that it costs nothing else. Canon's
	# two requirements stay in the same breath — the forfeited item and its
	# stat by name, and that it is not good ("honesty is the joke",
	# test_full_loop presses on both).
	var warn := Widgets.label_as(
		"This one is hard. Skipping it forfeits the %s and nothing else." % reward
		+ " It is not a good trinket.", "LabelSmall")
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn.custom_minimum_size = Vector2(LIST_TEXT_W, 0)
	warn.add_theme_color_override("font_color", Palette.CAUTION)
	box.add_child(warn)
	var skip := Widgets.secondary("Skip the tutorial")
	var enc_id: String = e.id
	skip.pressed.connect(func() -> void:
		if _state != null and _state.skip_tutorial(enc_id):
			_selected = ""
			_selected = _default_selection()
			_refresh()
			_rewire_focus()
			_focus_selected())
	box.add_child(skip)
	return box


## What the guild's reputation is currently worth, on the screen where it is spent.
## ✅ CANON: "New Tiers can be unlocked by gaining reputations with the town", so the
## board is where that promise has to be legible — a player looking at a wall of
## notices should be able to see what the next rank adds to it.
func _standing() -> Array:
	if _state == null:
		return [Widgets.label_as("No guild loaded.", "LabelMuted")]
	var rank: int = _state.reputation_rank
	var rp: int = _state.reputation_points
	var next_rp: int = Reputation.rp_for_next(rank)
	var line := ""
	if next_rp < 0:
		line = "%s  ·  %d reputation  ·  the highest standing there is." % [
			_state.rank_name(), rp]
	else:
		var next_rank: int = rank + 1
		# The promise names a tier only when THIS BUILD mounts it (LOOP-06):
		# docs/03 §7 opens Raid 2 at Known, but `ContentDB` mounts only the
		# tiers whose words are named (docs/15 BL-69), so until then the
		# sentence the player earned Known with would have been false. When
		# tiers 2-5 mount the guard costs nothing and the original line returns.
		var opens := "more of the same, better paid"
		var next_tier: int = Reputation.max_raid_tier(next_rank)
		if next_tier > Reputation.max_raid_tier(rank) and _tier_mounted(next_tier):
			opens = "Adventure %d and Raid %d" % [
				Reputation.max_adventure(next_rank), next_tier]
		# Rank-ups are the sim's to grant; if the points have run ahead of the
		# rank the countdown reads zero rather than a negative distance.
		line = "%s  ·  %d reputation  ·  %d more to %s, which opens %s." % [
			_state.rank_name(), rp, maxi(0, next_rp - rp),
			Enums.reputation_name_of(next_rank), opens]
	var label := Widgets.label_as(line, "LabelMuted")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
	var out: Array = [label]
	if _state.stalled:
		# docs/03 §8.1 M3. A doubled payout the player cannot see is a mechanic that
		# does not exist as far as they are concerned.
		out.append(_notice_callout("The town has noticed you are stuck.",
			"Adventures pay double reputation until you clear a new raid encounter.",
			45))
	return out


## docs/10 §13 row 2, and the whole of the endgame's UI by design.
##
## Once the campaign is finished the LADDER has nothing left to open, so the board
## that lists it says what does remain: the collection and the record wall. That is
## the entire post-clear offer and it is deliberate — doc 10 §13's closing
## paragraph refuses to invent a Tier 6 or a heroic difficulty to fill the gap,
## docs/00 §6.3 stops 1.0 at Raid 5, and docs/16 R-4 lists both as CUT. A stated
## goal is the honest thing to put here; a prestige mode would be an invention.
##
## It sits under the list's own subtitle rather than in the sidebar because it is
## a fact about the BOARD, not about whichever notice is pinned — and because the
## sidebar is already the most crowded column in the game.
##
## Phrased by `Achievements.remaining_line()` and nowhere else: S17 prints the same
## sentence, and two phrasings of one pair of numbers is how they start disagreeing.
##
## The second state (LOOP-07): every rung resolved and the campaign NOT
## finished — the road past the last mounted raid is not open, because the
## next tier's words are pending (docs/15 BL-69). Until tiers 2-5 mount this
## is the first dead end a good player hits, and the board is where the goal
## is stated, so it says what it is waiting on in one sentence. When the
## content lands the state is only reachable after Raid 5 and the sentence
## becomes S17's job.
func _completion_goal() -> void:
	if _goal_host == null:
		return
	for c in _goal_host.get_children():
		_goal_host.remove_child(c)
		c.queue_free()
	if _state == null:
		return
	if not bool(_state.completed):
		var ladder: Array = RaidPlan.ladder(_state)
		if ladder.is_empty() or RaidPlan.next_open_mission(_state) != null:
			return
		var last_tier: int = int(ladder[ladder.size() - 1].tier)
		var wall := Widgets.label_as(
			"Raid %d is cleared. The road past it is not open yet." % last_tier,
			"LabelLabel")
		wall.name = "WalkedOut"
		wall.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wall.custom_minimum_size = Vector2(LIST_TEXT_W, 0)
		_goal_host.add_child(wall)
		return
	_goal_host.add_child(Widgets.label_as(
		"The campaign is finished. The guild is not.", "LabelLabel"))
	var line := Widgets.label_as(
		Achievements.remaining_line(Achievements.snapshot(_state)), "LabelSmall")
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(LIST_TEXT_W, 0)
	_goal_host.add_child(line)


## Whether this build mounts raid content for `tier` — `ContentDB` mounts a
## tier only when its words are named, so a promise that names it must ask.
## A contentless state (the screen tests' stubs) mounts nothing.
func _tier_mounted(tier: int) -> bool:
	if _state == null or _state.content == null:
		return false
	return not _state.content.raid_encounters(tier).is_empty()


## A caution callout carrying a sentence rather than a figure. The kit's
## `callout()` sets its second line in figure type, which a sentence cannot
## wear, so the figure Label is re-dressed as body text and allowed to wrap.
func _notice_callout(headline: String, body: String, band: int) -> Control:
	var box := Widgets.callout(headline, body, band)
	var inner := box.get_child(0)
	if inner != null and inner.get_child_count() > 1:
		for c in inner.get_children():
			if c is Label:
				# A modest minimum and a fill flag: the box takes the column's
				# width and wraps inside it, instead of dictating the width.
				c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				c.custom_minimum_size = Vector2(240, 0)
				c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if inner.get_child(1) is Label:
			inner.get_child(1).theme_type_variation = "LabelBody"
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 8)
	# Re-parent the callout's column into a padded margin so the rim clears the text.
	box.remove_child(inner)
	pad.add_child(inner)
	box.add_child(pad)
	return box


# ---------------------------------------------------------------- bottom strip

func _strip(host: Control) -> void:
	if _state == null:
		return
	Cards.roster_strip(host, _state, 0)
	Cards.event_log(host, _state)


# ---------------------------------------------------------------- data

## The board in canon's own order: Adventures before the Raid of the same tier.
## docs/10 §3 — an Adventure "is the gate and the funding for the Raid of the
## same tier", and docs/08 §9.2 sizes Boss 1 for a raid that already owns
## Adventure gear, so listing Raid 1 first made the first rung unclimbable.
## The ladder itself lives in `RaidPlan` so this screen and `tools/playtest.gd`
## walk the same one — a harness that proved a DIFFERENT ladder completable would
## prove nothing about the game (audit M6-PLAY-01). The order, the tutorials and
## the rank gate are all documented there.
func _missions() -> Array:
	return RaidPlan.ladder(_state)


func _encounter(id: String):
	if id.is_empty():
		return null
	for e in _missions():
		if String(e.id) == id:
			return e
	return null


## The notice the sidebar opens on: what the guild last chose, if it is on the
## board and can actually be taken; otherwise the next rung it can climb.
func _default_selection() -> String:
	var order := _missions()
	if order.is_empty():
		return ""
	if _state != null:
		var chosen: String = _state.selected_encounter_id
		var e = _encounter(chosen)
		if e != null and _locked_reason(e).is_empty():
			return chosen
	for e in order:
		if _locked_reason(e).is_empty():
			return String(e.id)
	return String(order[0].id)


## The ladder is ordered: you cannot skip ahead to the boss. Clearing the rung
## before it is the key, which is what makes the board a progression bar.
## The campaign's own gate is `RaidPlan.locked_reason()`; the one thing this
## screen adds is a reason that belongs to the BUILD rather than to the guild.
func _locked_reason(e) -> String:
	if _router == null or not _router.screen_exists(RAID_PREP):
		return "Raid prep is not in this version yet."
	return RaidPlan.locked_reason(_state, e)


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	_rows.clear()
	_notices.clear()
	_skip_hosts.clear()
	if _list_host != null:
		for c in _list_host.get_children():
			_list_host.remove_child(c)
			c.queue_free()
		var order := _missions()
		if order.is_empty():
			_list_host.add_child(Widgets.empty_state(
				"Nothing is pinned. The guild has no content loaded to draw notices from.",
				Icons.at("empty", "quill")))
		var tier := -1
		for e in order:
			if int(e.tier) != tier:
				tier = int(e.tier)
				_list_host.add_child(_tier_divider(tier))
			var row := _rung(e)
			_list_host.add_child(row)
			_rows[String(e.id)] = row
		if _rows.has(_selected) and _list_scroll != null:
			_list_scroll.ensure_control_visible.call_deferred(_rows[_selected])
	_completion_goal()
	_rebuild_sidebar()


func _rebuild_sidebar() -> void:
	if _side_col == null:
		return
	for c in _side_col.get_children():
		_side_col.remove_child(c)
		c.queue_free()
	_sidebar()


## Pin a notice. The rows are re-dressed in place — never rebuilt — so the
## paper that has focus keeps it while the arrows walk the ladder; only the
## sidebar is rebuilt, and the shell's focus wiring is redone for its new
## controls (ScreenRouter.wire_shell_focus wires what exists at entry only).
func _select(encounter_id: String) -> void:
	if encounter_id == _selected:
		return
	var was := _selected
	_selected = encounter_id
	# docs/13 §12.4 `ui.row_select`: the pick, on change only (W6-AUD-BIND).
	var audio: Node = Services.find(self, "Audio")
	if audio != null:
		audio.play("ui.row_select")
	if _notices.has(was) and is_instance_valid(_notices[was]):
		_dress_notice(_notices[was], false)
	if _notices.has(encounter_id) and is_instance_valid(_notices[encounter_id]):
		_dress_notice(_notices[encounter_id], true)
	_place_skip(was)
	_place_skip(encounter_id)
	if _rows.has(encounter_id) and _list_scroll != null:
		_list_scroll.ensure_control_visible.call_deferred(_rows[encounter_id])
	_rebuild_sidebar()
	_rewire_focus()


## The skip block sits on the selected paper only: empty the host of a notice
## that lost the selection, fill the host of the one that has it.
func _place_skip(encounter_id: String) -> void:
	if not _skip_hosts.has(encounter_id):
		return
	var host = _skip_hosts[encounter_id]
	if not is_instance_valid(host):
		return
	for c in host.get_children():
		host.remove_child(c)
		c.queue_free()
	if encounter_id == _selected:
		var e = _encounter(encounter_id)
		if e != null and _is_skippable(e):
			host.add_child(_skip_block(e))


func _rewire_focus() -> void:
	if _frame != null:
		Frame.focus_order(_frame)


## After a rebuild that freed the focused control (the skip), put the keyboard
## on the notice now pinned. Live trees only: outside one, grab_focus is refused.
func _focus_selected() -> void:
	if not is_inside_tree():
		return
	var b = _notices.get(_selected)
	if b is Control and (b as Control).is_visible_in_tree():
		(b as Control).grab_focus()


func _on_pick(encounter_id: String) -> void:
	if _state == null or _router == null:
		return
	_selected = encounter_id
	_state.selected_encounter_id = encounter_id
	_router.push(RAID_PREP)
