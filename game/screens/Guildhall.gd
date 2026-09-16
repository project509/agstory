extends Control
## S03 — Guildhall (docs/13 §5), the tabbed container.
##
## ✅ CANON: the Guildhall is where "the roster lives", morale is maintained,
## facilities are upgraded and records are shown (raw notes, *Guildhall*).
## docs/13 §5 makes those four things four tabs, and §6.1's depth rule requires
## the roster to be exactly two clicks from town — Town → Guildhall lands here
## with the Roster tab already open, which is that second click.
##
## The art pass puts this on archetype C (10 §1): Concept 1's chrome — header
## chips, nav rail with "Roster" lit, right sidebar, bottom strip — with the
## framed scene rectangle becoming the content panel. The four tabs are the
## kit's in-panel sub-tabs (`Widgets.tab_row`, HALL-11) across that panel's
## title bar, a shut tab's reason printed under its own tab (HALL-10); the
## active tab's view fills the panel beneath. The sidebar and the strip are
## the host's: each view is handed a sidebar column to fill (rest controls,
## sort and filter on Roster; the hall on Facilities), and the strip carries
## the roster's lowest-morale read and the event log.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Icons = preload("res://game/ui/Icons.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Services = preload("res://game/core/Services.gd")
const RosterView = preload("res://game/screens/Roster.gd")
const FacilitiesView = preload("res://game/screens/Facilities.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Achievements = preload("res://sim/core/Achievements.gd")

const TOWN := "res://game/screens/Town.tscn"
const COMPLETION := "res://game/screens/Completion.tscn"

## docs/13 §5 S03. A tab with no `reason` is live; the others say why not,
## because docs/13 §7 forbids a disabled control that is a mystery.
##
## THREE tabs, not four (LOOP-14, UI-50, ship plan §6 #42j): the "Raid Group"
## tab was permanently disabled — its reason was a redirect ("Chalk tonight's
## twelve from the Adventure's Board.") that nothing ever cleared, because the
## chalking moved to RaidPrep (docs/13 OQ-4's reversal) and RaidPrep's strip
## IS the raid group. A control that can never enable is not "disabled with a
## reason", it is a dead menu item. It comes back only if Q18j answers
## "read-only view" (W10-BUFFER builds it from `record_attempt`'s ids).
##
## Records' reason is a GATE, not a stub: docs/03 §7's master table
## (docs/03-guild-reputation.md:434) puts the "Quest/achievement board" in the
## Town-unlock column at **Known**, so the tab is genuinely shut on a new guild
## and opens on its own. `_tab_reason()` clears it at rank Known, and the
## sentence is `Achievements.unlock_reason()`'s — one owner for one wall
## (LOOP-15: three gates said three things, and one of them was false after
## the first raid), so the entry here carries no text of its own.
const TABS := [
	{"id": "roster", "label": "Roster", "reason": ""},
	{"id": "facilities", "label": "Facilities", "reason": ""},
	{"id": "records", "label": "Records", "reason": ""},
]

## docs/11 §11.1's five entry types, as the filter row S14 needs to make a
## forty-row wall readable. The empty id is "no filter" and is not a type.
const RECORD_FILTERS := [
	{"id": "", "label": "All"},
	{"id": "progress", "label": "Progress"},
	{"id": "mastery", "label": "Mastery"},
	{"id": "roster", "label": "Roster"},
	{"id": "comedy", "label": "Comedy"},
	{"id": "economy", "label": "Economy"},
]

## The content panel's inner width, less the reward column and the claim button.
const RECORD_TEXT_W := 520

## HALL-20: the record wall's rows carry an icon per state — the padlock for a
## locked record, the prize for one earned and waiting, the coin for one paid
## out — through `Icons.at` (W1-ICONS' grid). When W3-KIT2's
## `Cards.badge_icon` grows the record states this table is the one line to
## retire (handoff-W3-ROSTER). Keys are `Achievements.State` values.
const RECORD_ICON := {
	Achievements.State.LOCKED: ["lock", "16"],
	Achievements.State.EARNED: ["log", "loot"],
	Achievements.State.CLAIMED: ["log", "gold"],
}
const RECORD_ICON_PX := 22

## The rail's item list (00 §2.6), shared shape with Town.RAIL.
const RAIL := [
	{"id": "home", "label": "Camp", "scene": TOWN},
	{"id": "tavern", "label": "Tavern", "scene": "res://game/screens/Tavern.tscn"},
	{"id": "roster", "label": "Roster", "scene": "res://game/screens/Guildhall.tscn"},
	{"id": "market", "label": "Market", "scene": "res://game/screens/Market.tscn"},
	{"id": "board", "label": "Adventure's Board", "scene": "res://game/screens/AdventureBoard.tscn"},
	{"id": "options", "label": "Options", "scene": "res://game/screens/Settings.tscn"},
]

## The content panel inside the 928x640 scene rectangle. Its inner width is
## 916 - 28 (PanelWarm's own margins) = 888, which is exactly four roster cards
## at the reference pitch (3 × 224 + 215 = 887) — the Roster grid depends on it.
const PANEL_AT := Vector2(6, 8)
const PANEL_SIZE := Vector2(916, 624)
const STRIP_LEFT_W := 1020

## The tab row's geometry (HALL-10/11). A tab is `TAB_SIZE` at least (the
## kit's active plate otherwise hugs its word — handoff-W2-MARKET); a shut
## tab's reason is a caption under it at `Type.STACK` — the 12px caption
## HALL-10 asks for, rounded to the type scale's nearest step — on ONE line
## at 100% text, wrapped at its 100% width when the text scale grows. The
## caption sizes its own cell (`no reason text past its tab's column`), and
## the tab stays `TAB_SIZE` at the cell's left. One caption line is what
## leaves the panel 545px of roster under the row: two full rows of cards and
## the top of the third (HALL-03's acceptance) — a 13px caption wraps to two
## lines here and costs the second row its bottom.
const TAB_SIZE := Vector2(110, 28)
const TAB_CAPTION_SIZE: int = Type.STACK

## docs/15 BL-78 / spec 09 §4.1: the hall family stands on the BARE camp — the
## Town's own plate, `game/assets/scenes/stage_camp.json` — with the panels
## over it. Same plate, same framing: Town → Guildhall reads as a panel sliding
## over the camp the player was just looking at (docs/13 §2 M5, "the desk does
## not move"). Q03 (00-plan §6) is whether the hall keeps the hub's framing or
## takes a tighter one on the big guild tent so it reads as its own place; this
## switch holds the recommended default, and flipping it moves every hall
## screen at once — RaiderDetail and Settings read `framing()` rather than
## keeping numbers of their own.
##
## "same" is Town.CAMP_OFFSET; the dim is RaidPrep's, because the bare plate is
## darker than the Concept 1 crop was and carries its own lights, so the 0.5
## the crop needed takes too much away. "tight" is TOWN-14's suggestion.
const CAMP_SCENE := "stage_camp"
const HALL_FRAMING := "same"
const FRAMINGS := {
	"same": {"offset": Vector2(-46, -62), "dim": Color(0.62, 0.62, 0.68)},
	"tight": {"offset": Vector2(-120, -140), "dim": Color(0.55, 0.55, 0.62)},
}

## The strip's two-second read (HALL-04; docs/13 §8.1, §8.6): every raider in
## canon's two-line format, lowest morale first, in three columns of four —
## twelve, the raid size — at the card's own type (`LabelMorale` over
## `LabelClass`, 44px of text) on a 46px pitch inside the 234px the panel's
## pad leaves. Past twelve, one trailing Label says how many more and that
## every one of them sits above the last morale shown.
const STRIP_COLUMNS := 3
const STRIP_ROWS := 4
const STRIP_ENTRY_PITCH := 46
const STRIP_COLUMN_PITCH := 330
const STRIP_LIST_TOP := 28
const STRIP_LINE2_DY := 24

var _router = null
var _state = null
var _active := "roster"
var _content_host: Control = null
var _tab_host: Control = null
var _tab_row: Control = null
var _tab_buttons: Dictionary = {}
var _built := false
var _frame = null
var _side_col: VBoxContainer = null
var _fold_scroll: ScrollContainer = null
var _fold_spacer: Control = null
var _strip: Control = null
## S14's filter and its one-line answer to the last press ("Claimed 25 G", or
## why not). Kept on the host because `_show_tab()` rebuilds the view wholesale.
var _record_filter := ""
var _record_notice := ""


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
		if _router == null or not _router.screen_exists(scene):
			reason = "Not built in this version yet."
		nav.append({"id": item["id"], "label": item["label"], "reason": reason})

	_frame = Frame.build(self, {"nav": nav, "active": "roster", "framed": true})
	for item in RAIL:
		var id := String(item["id"])
		var scene := String(item["scene"])
		var b: Button = _frame.nav_buttons.get(id)
		if b == null or b.disabled or id == "roster":
			continue
		if id == "home":
			b.pressed.connect(_on_back)
		else:
			b.pressed.connect(func() -> void: _router.push(scene))

	_scene(_frame.scene)
	Frame.standard_chips(_frame, _state)
	_sidebar(Frame.sidebar(_frame))
	_strip = _frame.strip
	_show_tab("roster")


# ---------------------------------------------------------------- the stage

## The framing every hall screen stands on (see HALL_FRAMING).
static func framing() -> Dictionary:
	return FRAMINGS.get(HALL_FRAMING, FRAMINGS["same"])


## A bare stage with its words left out. A hall screen covers most of its
## window with opaque panels, and a speech plate or an ambient "..." bubble
## under a panel is a smudge at its edge — so the scene's `bubbles` and
## `speech` keys are dropped before the stage is built, through
## `SceneStage.from_data` (the seam the stage's own tests use). Everything
## else — plate, lights, the campfire, embers, actors, the stream — is kept.
##
## docs/13 §13's two switches are applied here as well as in the stage's own
## `_ready`: under a SceneTree script `_ready` never fires (LESSONS), and a test
## has to be able to see the camp held still under the panels.
static func bare_stage(who: Node, scene: String) -> Control:
	var data: Dictionary = {}
	var path := SceneStage.SCENES + scene + ".json"
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			data = parsed
	data.erase("bubbles")
	data.erase("speech")
	var stage := SceneStage.from_data(scene, data)
	if who != null:
		var settings = Services.find(who, "GameSettings")
		if settings != null:
			stage.apply_settings(bool(settings.get_value("reduced_motion")),
				bool(settings.get_value("reduced_effects")))
	return stage


# ---------------------------------------------------------------- the panel

## The reason a tab is shut, or "" when it is open. Records is the only one
## whose answer moves: docs/03 §7's master table puts the achievement board in
## the Town-unlock column at Known, so the tab opens on its own as the guild
## earns its way there rather than needing anything built. The sentence is
## the sim's (`Achievements.unlock_reason`), the same one the tab's body and
## the event log's "Records" link print. A static reason in TABS (none today)
## would be a property of the tab and is returned as written.
func _tab_reason(tab: Dictionary) -> String:
	var reason := String(tab.get("reason", ""))
	if String(tab.get("id", "")) != "records":
		return reason
	var snap := Achievements.blank_snapshot()
	if _state != null:
		snap = Achievements.snapshot(_state)
	return Achievements.unlock_reason(snap)


func _scene(host: Control) -> void:
	# docs/15 BL-78: the bare camp, framed as the Town frames it, dimmed so the
	# panel on top of it is the thing being read (09 §1.3). It shows in the
	# panel's margins here; the band it gets on LoadSave and Settings is
	# HALL-02's, and whether these two screens free one is Q03.
	var fr := framing()
	var offset: Vector2 = fr["offset"]
	var dim: Color = fr["dim"]
	var stage := bare_stage(self, CAMP_SCENE)
	stage.position = offset
	stage.size = host.size - offset
	stage.modulate = dim
	host.add_child(stage)

	var panel := Widgets.panel("PanelWarm", 0)
	panel.name = "ContentPanel"
	host.add_child(panel)
	panel.position = PANEL_AT
	panel.size = PANEL_SIZE
	panel.clip_contents = true
	var col := Widgets.column(6)
	Widgets.content_of(panel).add_child(col)

	# Title bar: the kit's tab row, rebuilt on every switch by `_build_tabs`.
	_tab_host = Widgets.column(0)
	_tab_host.name = "Tabs"
	_tab_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_tab_host)

	_content_host = Control.new()
	_content_host.name = "Content"
	_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_content_host)


## The four sub-tabs in the kit's idiom (`Widgets.tab_row`, HALL-11): the
## active one on the lit plate with the gold underline, a shut one dimmed
## with its reason under it (HALL-10) — the Button texts are TABS' labels
## verbatim, which the tests press. The row is a rebuild per switch, so
## `_show_tab` hands focus back to the active tab when the pressed one had it.
func _build_tabs() -> void:
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
		reasons.append(_tab_reason(TABS[i]))
		if String(TABS[i]["id"]) == _active:
			active = i
	_tab_row = Widgets.tab_row(labels, active, reasons)
	_tab_buttons = {}
	var tabs: Array = Widgets.tabs_of(_tab_row)
	for i in tabs.size():
		var id := String(TABS[i]["id"])
		var b: Button = tabs[i]
		b.custom_minimum_size = TAB_SIZE
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if not b.disabled:
			b.pressed.connect(func() -> void: _show_tab(id))
		_tab_buttons[id] = b
	_tab_host.add_child(_tab_row)
	# Shaped once the row is in the tree, so the caption measures itself with
	# the screen's own theme font (the one door, W0-TEXTSCALE).
	for i in tabs.size():
		_shape_caption(tabs[i], String(reasons[i]))


## The caption under a shut tab: the kit's "Reason" Label, re-sized to
## TAB_CAPTION_SIZE at the player's text scale and wrapped at the width the
## sentence has at 100% — one line at 100%, two at 150% — so the cell it
## sizes is exactly as wide as its own sentence and never wider than the row.
func _shape_caption(tab: Button, reason: String) -> void:
	if reason.is_empty():
		return
	var cell: Node = tab.get_parent()
	if cell == null:
		return
	var why: Label = cell.get_node_or_null("Reason") as Label
	if why == null:
		return
	why.add_theme_font_size_override("font_size",
		Type.at(TAB_CAPTION_SIZE, Theme_.scale_of(self)))
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.custom_minimum_size = Vector2(ceilf(_caption_width(why, reason)), 0)


## The caption's width at the 100% scale — the caption's own theme font at
## the unscaled TAB_CAPTION_SIZE — so a larger text scale wraps instead of
## widening the row. Read off the Label (in the tree by now), never a bare
## theme call.
func _caption_width(who: Label, text: String) -> float:
	var f: Font = who.get_theme_font("font", "LabelSmall")
	if f == null:
		return 0.0
	return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TAB_CAPTION_SIZE).x + 2.0


func _show_tab(id: String) -> void:
	var region := _focus_note()
	_active = id
	for host in [_content_host, _side_col]:
		if host == null:
			continue
		for c in host.get_children():
			host.remove_child(c)
			c.queue_free()
	_build_tabs()

	match id:
		"roster":
			var view := RosterView.new()
			view.name = "RosterView"
			view.set_anchors_preset(Control.PRESET_FULL_RECT)
			view.sidebar_host = _side_col
			view.on_changed = _on_changed
			_content_host.add_child(view)
			view.build()
		"facilities":
			var facilities := FacilitiesView.new()
			facilities.name = "FacilitiesView"
			facilities.set_anchors_preset(Control.PRESET_FULL_RECT)
			facilities.sidebar_host = _side_col
			facilities.on_changed = _on_changed
			_content_host.add_child(facilities)
			facilities.build()
		"records":
			_records(_content_host)
			_records_sidebar(_side_col)
	_rewire_focus()
	_regrab(region)


# ---------------------------------------------------------------- focus

## [region, Button.text] of the keyboard focus owner ([] when nothing owns
## it): the tab row, the panel's content, or the sidebar column.
func _focus_note() -> Array:
	var vp := get_viewport()
	if vp == null:
		return []
	var owner := vp.gui_get_focus_owner()
	if owner == null:
		return []
	var text := (owner as Button).text if owner is Button else ""
	for pair in [["tabs", _tab_host], ["content", _content_host], ["sidebar", _side_col]]:
		var host: Control = pair[1]
		if host != null and host.is_ancestor_of(owner):
			return [String(pair[0]), text]
	return []


## Hand focus back to the region that had it: the active tab for the tab
## row; elsewhere the rebuilt Button with the same text (a filter chip, a
## Claim) or the region's first focusable control.
func _regrab(note: Array) -> void:
	if note.is_empty() or not is_inside_tree():
		return
	var region := String(note[0])
	var text := String(note[1])
	var target: Control = null
	match region:
		"tabs":
			target = _tab_buttons.get(_active, null)
		"content":
			target = _button_in(_content_host, text)
			if target == null:
				target = _first_focusable(_content_host)
		"sidebar":
			target = _button_in(_side_col, text)
			if target == null:
				target = _first_focusable(_side_col)
	if target != null and target.is_inside_tree() and target.is_visible_in_tree():
		target.grab_focus()


func _button_in(node: Node, text: String) -> Control:
	if node == null or text.is_empty():
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


## Re-run the shell's focus wiring (the Callable Frame leaves on this screen —
## the key is mirrored as a literal the way Cards.gd mirrors it).
func _rewire_focus() -> void:
	if has_meta(Cards.SCREEN_FOCUS_META):
		var cb = get_meta(Cards.SCREEN_FOCUS_META)
		if cb is Callable and (cb as Callable).is_valid():
			(cb as Callable).call()


# ---------------------------------------------------------------- records

## S14, the Records tab (docs/02 §4.4, docs/11 §11.1). A record wall, not a
## chore list: docs/02 is explicit that there are no timers and nothing
## repeatable here, so the view is a reading surface — what the guild has done,
## what it has not, and the two meters docs/10 §13 makes the post-clear
## activity. Every string is a Label or a Button, because the screen tests read
## the tree and a keyboard player reads the same words.
func _records(host: Control) -> void:
	var col := Widgets.column(10)
	col.name = "Records"
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(col)

	var snap := Achievements.blank_snapshot()
	if _state != null:
		snap = Achievements.snapshot(_state)

	# The gate first, if it is shut. docs/13 §7: never a mystery.
	var locked := Achievements.unlock_reason(snap)
	if not locked.is_empty():
		col.add_child(Widgets.label_as(locked, "LabelBody"))
		col.add_child(Widgets.rule())

	var earned := Achievements.earned_count(snap)
	var total := Achievements.records().size()
	col.add_child(Widgets.label_as("Records  %d of %d" % [earned, total], "LabelSection"))
	# docs/10 §13 row 2's collection meter, phrased by the sim so the screen and
	# the rule cannot drift apart.
	col.add_child(Widgets.label_as(Achievements.legendary_meter(snap), "LabelBody"))
	_completion_link(col)
	# The answer to the last press, where the press was (docs/13 §7). A refusal —
	# the coin cap, most often — is a sentence the player reads, never a button
	# that quietly does nothing.
	if not _record_notice.is_empty():
		var notice := Widgets.label_as(_record_notice, "LabelBody")
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notice.add_theme_color_override("font_color", Palette.ACCENT_GOLD_LIGHT)
		col.add_child(notice)

	var rows := Widgets.column(4)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var listed := 0
	for raw in Achievements.records():
		var rec: Dictionary = raw
		# S14's type filter (RECORD_FILTERS, chosen in the sidebar): "" lists
		# the whole wall; the heading above counts the whole wall either way.
		if not _record_filter.is_empty() and String(rec.get("type", "")) != _record_filter:
			continue
		listed += 1
		var rid := String(rec.get("id", ""))
		var state := Achievements.state_of(rid, snap)
		var row := Widgets.row(10)
		row.name = "Record_%s" % rid.validate_node_name()
		# HALL-20: the state's icon leads the row — and the state WORD stays a
		# Label beside it: docs/13 §13 wants more than one channel.
		row.add_child(_record_icon(state))
		row.add_child(Widgets.label_as(Achievements.state_name(state), "LabelSmall"))
		row.add_child(Widgets.label_as(String(rec.get("name", rid)), "LabelName"))
		# A locked record still shows its blurb — the wall is the point, and a
		# hidden one cannot be aimed at (docs/02 §4.4).
		var blurb := Widgets.label_as(String(rec.get("blurb", "")), "LabelSmall")
		blurb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		blurb.clip_text = true
		blurb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(blurb)
		_claim_control(row, rec, rid, state, snap)
		rows.add_child(row)
	if listed == 0:
		rows.add_child(Widgets.empty_state("No records of that kind yet.", Icons.at("empty", "shelf")))
	var scroll := ScrollContainer.new()
	scroll.name = "RecordsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	col.add_child(scroll)


## The Records tab's sidebar (HALL-09's rule that no sidebar is left half
## empty applies here too): the wall's two tallies, the coin the board has
## paid against docs/11 §11.2's share of lifetime income (the refusal the
## player will meet, said before it is met), and S14's type filter as chips —
## `RECORD_FILTERS`, pressed state = the filter on (HALL-12's idiom).
func _records_sidebar(side: Control) -> void:
	if side == null:
		return
	var snap := Achievements.blank_snapshot()
	if _state != null:
		snap = Achievements.snapshot(_state)
	side.add_child(Widgets.label_as("Records", "LabelSection"))
	var facts := Widgets.column(2)
	facts.name = "RecordFacts"
	side.add_child(facts)
	var claimed: Array = snap.get("claimed", [])
	facts.add_child(Widgets.label_as("%d of %d earned  ·  %d claimed" % [
		Achievements.earned_count(snap), Achievements.records().size(), claimed.size()], "LabelBody"))
	var paid: int = Achievements.coin_paid(claimed)
	var cap: int = Achievements.coin_cap(int(snap.get("gold_earned_lifetime", 0)))
	facts.add_child(Widgets.label_as("Paid out %s of the %s the board may pay" % [
		Type.gold(paid), Type.gold(cap)], "LabelMuted"))
	var share := Widgets.label_as("The board pays a share of what the guild has earned; raid, and the share grows.",
		"LabelSmall")
	share.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	share.custom_minimum_size = Vector2(300, 0)
	facts.add_child(share)

	side.add_child(Widgets.rule())
	var flow := HFlowContainer.new()
	flow.name = "RecordFilter"
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	var head := Widgets.label_as("Show", "LabelLabel")
	head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flow.add_child(head)
	for i in RECORD_FILTERS.size():
		var f: Dictionary = RECORD_FILTERS[i]
		var id := String(f["id"])
		var b := Widgets.button(String(f["label"]))
		b.name = "RecordFilter_%d" % i
		b.theme_type_variation = "ButtonChip"
		b.toggle_mode = true
		b.set_pressed_no_signal(id == _record_filter)
		b.pressed.connect(func() -> void:
			_record_filter = id
			_show_tab("records"))
		flow.add_child(b)
	side.add_child(flow)


## The 22px icon a record row leads with (HALL-20), dimmed for a locked one
## the way a shut control is (`Widgets.REASONED_DIM`), so locked and earned
## read apart at a glance without the word.
func _record_icon(state: int) -> Control:
	var t := TextureRect.new()
	t.name = "StateIcon"
	t.custom_minimum_size = Vector2(RECORD_ICON_PX, RECORD_ICON_PX)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture = Cards.badge_icon(Achievements.state_name(state).to_lower())
	if t.texture == null:
		var key: Array = RECORD_ICON.get(state, [])
		if key.size() == 2:
			t.texture = Icons.at(String(key[0]), String(key[1]))
	if state == Achievements.State.LOCKED:
		t.modulate = Color(1, 1, 1, Widgets.REASONED_DIM)
	return t


## The right-hand end of a record row: what it pays, and — once it is earned and
## not yet taken — the button that takes it.
##
## docs/14 OQ-10 splits this in two and the split is the point: the board decides
## what is owed (`Achievements.claim_grant`) and GameState is the hand that pays
## (`claim_achievement`). This function does neither. It prints the reward in the
## board's own words and presses the hand.
##
## A LOCKED record still shows its reward. docs/02 §4.4 makes the wall a thing you
## aim at, and a prize you cannot see is not a prize.
func _claim_control(row: HBoxContainer, rec: Dictionary, rid: String,
		state: int, snap: Dictionary) -> void:
	var reward := Widgets.label_as(Achievements.describe_reward(rec), "LabelSmall")
	# Clipped and shrink-fitted so it can never dictate the row's width. LESSONS:
	# one uncapped Label in a row sets the container's minimum, and this row lives
	# in a ScrollContainer with horizontal scrolling DISABLED — so a long reward
	# string would not widen the panel, it would silently clip the blurb beside it.
	reward.clip_text = true
	reward.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	reward.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(reward)
	if state != Achievements.State.EARNED or _state == null:
		return
	var b := Widgets.button("Claim")
	b.pressed.connect(func() -> void: _on_claim(rid))
	row.add_child(b)


## One press. The refusal, when there is one, is the board's own sentence — the
## coin cap's "the board has paid its share for now" names the figure and the
## income it is a share of, which is the only form of "no" docs/13 §7 allows.
func _on_claim(rid: String) -> void:
	if _state == null:
		return
	var refusal := String(_state.claim_achievement(rid))
	if refusal.is_empty():
		var rec: Dictionary = Achievements.record(rid)
		_record_notice = "Claimed — %s." % Achievements.describe_reward(rec)
	else:
		_record_notice = refusal
	_show_tab("records")


## S17 is re-readable from here, and only from here (docs/15 BL-73). A report the
## player can never open again is a cutscene, and docs/02 §4.4 makes this tab a
## reading surface precisely so the guild's history stays readable. It appears
## only once there is an ending to re-read.
func _completion_link(col: Control) -> void:
	if _state == null or not bool(_state.completed):
		return
	if _router == null or not _router.screen_exists(COMPLETION):
		return
	var b := Widgets.button("Read the ending again")
	b.pressed.connect(func() -> void: _router.push(COMPLETION))
	col.add_child(b)


func active_tab() -> String:
	return _active


## A view changed the world (rested, bought, upgraded): the chips and the strip
## read the same state, so they are rebuilt.
func _on_changed() -> void:
	_rebuild_chips()
	if _strip != null:
		_fill_strip(_strip)


# ---------------------------------------------------------------- header

## 00 §2.5's four chips are the frame's (`Frame.standard_chips`), the same row
## on every screen — HALL-19/KIT-03: this file used to hand-roll them with the
## sun where the frame prints the rank sigil, so the icon flipped between
## screens. A change to the world replaces the row rather than editing it.
func _rebuild_chips() -> void:
	if _frame == null:
		return
	Frame.refresh_chips(_frame, _state)


# ---------------------------------------------------------------- sidebar

## The sidebar column the active view fills, above a rule and the way out.
## The column scrolls (the theme's bar, inside the panel's pad) so a larger
## text scale pushes nothing off the panel and "Back to town" stays put.
##
## W5-SCALE: a scroll's fold cuts whatever block it lands on — at 150% the
## Roster view's morale chart (a 56px well under four face-height fact lines)
## showed as a 10px sliver with the rest below the fold (report-W4-PIP.md's
## Note). `_snap_fold` moves the fold UP to the last block boundary that fits,
## so a block is whole or below the fold and never sliced; `FoldSpacer` takes
## the leftover so the rule and "Back to town" do not move.
func _sidebar(host: Control) -> void:
	if host == null:
		return
	var col := Widgets.column(10)
	host.add_child(col)
	var scroll := ScrollContainer.new()
	scroll.name = "SidebarScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side_col = Widgets.column(10)
	_side_col.name = "SideColumn"
	_side_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_side_col)
	col.add_child(scroll)
	_fold_scroll = scroll
	_fold_spacer = Control.new()
	_fold_spacer.name = "FoldSpacer"
	_fold_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fold_spacer.visible = false
	col.add_child(_fold_spacer)
	col.add_child(Widgets.rule())
	var back := Widgets.button("Back to town")
	back.theme_type_variation = "ButtonQuiet"
	back.pressed.connect(_on_back)
	col.add_child(back)
	_side_col.sort_children.connect(_snap_fold)


## In-tree only (the fold is a laid-out quantity; under a SceneTree script the
## column never sorts and the spacer stays hidden). Runs after every sort of
## the column: what the column holds is measured, the fold is `fold_height()`,
## and the spacer is shown at the leftover — the same value on the next sort,
## so the layout settles in one pass.
func _snap_fold() -> void:
	if _side_col == null or _fold_scroll == null or _fold_spacer == null:
		return
	if not is_inside_tree():
		return
	var col := _fold_scroll.get_parent() as VBoxContainer
	if col == null:
		return
	var sep: float = float(col.get_theme_constant("separation"))
	var fixed := 0.0
	var gaps := 0
	for c in col.get_children():
		if c == _fold_scroll or c == _fold_spacer or not (c is Control):
			continue
		if not (c as Control).visible:
			continue
		fixed += (c as Control).get_combined_minimum_size().y
		gaps += 1
	var avail: float = col.size.y - fixed - sep * float(gaps)
	var heights: Array = []
	for c in _side_col.get_children():
		if c is Control and (c as Control).visible:
			heights.append((c as Control).size.y)
	var fold: float = fold_height(heights, float(_side_col.get_theme_constant("separation")), avail)
	var want: float = avail - fold - sep
	if fold < avail and want > 0.5:
		_fold_spacer.custom_minimum_size = Vector2(0, want)
		_fold_spacer.visible = true
	else:
		_fold_spacer.visible = false


## Where the scroll's fold goes for blocks of `heights` (top to bottom, `sep`
## between them) in `avail` px: `avail` itself when everything fits, else the
## bottom of the last block that fits whole — a block is never sliced. A first
## block taller than the viewport keeps the whole viewport (it scrolls inside).
static func fold_height(heights: Array, sep: float, avail: float) -> float:
	var total := 0.0
	for i in heights.size():
		total += float(heights[i]) + (sep if i > 0 else 0.0)
	if total <= avail + 0.5:
		return avail
	var y := 0.0
	var fold := 0.0
	for h in heights:
		var bottom: float = y + float(h)
		if bottom > avail + 0.5:
			break
		fold = bottom
		y = bottom + sep
	return fold if fold > 0.0 else avail


# ---------------------------------------------------------------- bottom strip

## The strip's left panel is canon's two-second read (docs/13 §9): whoever is
## lowest, in the two-line format, without scrolling the grid — all twelve of
## a raid's worth (HALL-04), in three columns of four. The right panel is the
## shared event log.
func _fill_strip(host: Control) -> void:
	for c in host.get_children():
		host.remove_child(c)
		c.queue_free()
	if _state == null:
		return

	var low := Widgets.panel("PanelRound", 14)
	low.name = "LowestMorale"
	host.add_child(low)
	low.position = Vector2.ZERO
	low.size = Vector2(STRIP_LEFT_W, Widgets.STRIP_H)
	low.clip_contents = true
	var well := Control.new()
	well.name = "List"
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Widgets.content_of(low).add_child(well)
	var inner_w: float = STRIP_LEFT_W - 28.0
	var inner_h: float = Widgets.STRIP_H - 28.0

	var title := Widgets.label_as("Lowest morale first", "LabelSectionSm")
	well.add_child(title)
	title.position = Vector2.ZERO
	title.size = Vector2(inner_w, 22)
	var rule := Widgets.rule()
	well.add_child(rule)
	rule.position = Vector2(0, 24)
	rule.size = Vector2(inner_w, 1)

	var roster: Array = _state.roster.duplicate()
	if roster.is_empty():
		# In a MarginContainer given the rect (see Roster._empty for why an
		# autowrapped Label is never placed by hand).
		var box := MarginContainer.new()
		box.name = "EmptyBox"
		well.add_child(box)
		box.position = Vector2(0, STRIP_LIST_TOP)
		box.size = Vector2(inner_w, inner_h - STRIP_LIST_TOP)
		var empty := Widgets.empty_state(
			"Nobody on the books. The Tavern is where a guild finds people.",
			Icons.at("empty", "bench"))
		empty.name = "Empty"
		box.add_child(empty)
		Cards.event_log(host, _state, 7, "Raids and rests write here.", Icons.at("empty", "quill"))
		return
	roster.sort_custom(func(a, b) -> bool: return a.morale < b.morale)
	# The pitch is the two lines' own heights at the player's text scale
	# (docs/13 §4.4: at 150% fewer entries, never a squeezed or cut one);
	# at 100% that is STRIP_ENTRY_PITCH and STRIP_ROWS rows.
	var h1 := _line_h("LabelMorale", float(STRIP_LINE2_DY))
	var h2 := _line_h("LabelClass", float(STRIP_ENTRY_PITCH - STRIP_LINE2_DY))
	var pitch: int = maxi(STRIP_ENTRY_PITCH, int(ceilf(h1 + h2 + 2.0)))
	var rows: int = clampi(int((inner_h - STRIP_LIST_TOP) / float(pitch)), 1, STRIP_ROWS)
	# Past what fits, the trailing "+N more" line takes the floor and the rows
	# above it give it room (at 150% that is a third row less, not an overlap).
	var more_h: float = maxf(16.0, _line_h("LabelSmall", 16.0) + 2.0)
	if roster.size() > STRIP_COLUMNS * rows:
		rows = clampi(int((inner_h - STRIP_LIST_TOP - more_h) / float(pitch)), 1, STRIP_ROWS)
	var shown: int = mini(STRIP_COLUMNS * rows, roster.size())
	for i in shown:
		var r = roster[i]
		var m: int = int(r.morale)
		@warning_ignore("integer_division")
		var at := Vector2((i / rows) * STRIP_COLUMN_PITCH,
			STRIP_LIST_TOP + (i % rows) * pitch)
		var line1 := Widgets.label_as("%s — %d %s" % [
			String(r.display_name), m, Cards.morale_glyph(self, m)], "LabelMorale")
		line1.name = "Morale_%d" % i
		line1.add_theme_color_override("font_color", Palette.morale_color(m))
		well.add_child(line1)
		line1.position = at
		line1.size = Vector2(STRIP_COLUMN_PITCH - 10, ceilf(h1))
		var line2 := Widgets.label_as("%s — %s" % [
			Enums.class_name_of(r.class_id), Enums.morale_band_name(m)], "LabelClass")
		line2.name = "Class_%d" % i
		well.add_child(line2)
		line2.position = at + Vector2(0, ceilf(h1))
		line2.size = Vector2(STRIP_COLUMN_PITCH - 10, ceilf(h2))
	if roster.size() > shown:
		var last: int = int(roster[shown - 1].morale)
		var more := Widgets.label_as("+%d more, all above %d" % [roster.size() - shown, last],
			"LabelSmall")
		more.name = "More"
		more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		well.add_child(more)
		# Sat on the panel's inner floor at its own height (a Label never goes
		# under its minimum, so the height is asked for, not assumed).
		more_h = maxf(more_h, more.get_combined_minimum_size().y)
		more.position = Vector2(0, inner_h - more_h)
		more.size = Vector2(inner_w, more_h)

	Cards.event_log(host, _state, 7, "Raids and rests write here.", Icons.at("empty", "quill"))


## A Label variation's line height at this screen's theme (the player's text
## scale), or `fallback` when the theme has no such font — the bare mounts.
## The face sheet rides the morale fonts as a fallback (Fonts.with_faces) and
## a Font's height is the tallest of its fallbacks, so the TEXT font's own
## height is what is asked for — the 24px face draws over the line it is on,
## as it does on every card.
func _line_h(variation: String, fallback: float) -> float:
	var th: Theme = theme if theme != null else Theme_.current(self)
	if th == null or not th.has_font("font", variation) or not th.has_font_size("font_size", variation):
		return fallback
	var f: Font = th.get_font("font", variation)
	if f is FontVariation:
		var fv := f as FontVariation
		if fv.base_font != null and not fv.fallbacks.is_empty():
			f = fv.base_font
	return f.get_height(th.get_font_size("font_size", variation))


func _on_back() -> void:
	if _router != null:
		_router.goto(TOWN)
