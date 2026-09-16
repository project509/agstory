extends Control
## S17 — Completion. The screen the ending fires into (docs/13 §5, spec in §9.5).
##
## docs/10 §13 row 1 asserts that a completion beat fires on the first clear of
## Raid 5's last encounter and hands the SCREEN to doc 13; doc 13 never carried
## the row until docs/15 BL-73 propagated it. docs/15 Q-88 is the ruling that
## decides what this screen is allowed to be: **the save continues** past the
## beat. So this is a report and a door back to town — it ends nothing, resets
## nothing and locks nothing, and it carries no prestige button, no difficulty
## toggle and no New Game+, because doc 10 §13 refuses to invent an endgame mode
## and docs/16 R-4 lists Tier 6 and a heroic mode as cut.
##
## Every figure on it is already kept by the campaign: the guild's name, the day,
## `played_seconds`, the `cleared` tally, `rank_name()`, the roster and the gold.
## A completion screen that needed its own bookkeeping would be a second source
## of truth for what the run was.
##
## THE ONE RULE THAT IS EASY TO GET WRONG: the beat is spent on ARRIVAL.
## `GameState.completion_seen` is set in `build()`, not when the button is
## pressed — a player who closes the game while reading their ending has seen it,
## and re-showing it on the next load would be the game deciding they had not.
## Re-reading it later is deliberate and reachable: the Guildhall's Records tab
## routes back here once `completed` is true, because a report you can never open
## again is a cutscene.
##
## THE CREDITS BLOCK IS DATA. It is read from `data/credits.json` and printed
## verbatim — its `lines`, and nothing else. Who the game credits is a person's
## signature, not a build's guess; until it is given the roll is the guild's
## own roster and the screen says nothing about the state of the credits
## (LOOP-27: the file's `status` sentence is the record for the person who
## signs, never a paragraph for the player).

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Type = preload("res://game/ui/Type.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Services = preload("res://game/core/Services.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const Achievements = preload("res://sim/core/Achievements.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Enums = preload("res://sim/model/Enums.gd")

const TOWN := "res://game/screens/Town.tscn"
const CREDITS_PATH := "res://data/credits.json"

## The camp, because that is where the guild goes back to — Town's own plate,
## framed, so walking out of the ending lands somewhere recognisable. Town's x
## offset; the y is 32px higher than Town's (-62), which is exactly what keeps
## the crate-side figure (plate y 625) clear of the band and puts the plate's
## last row on the host's last row (1024 - 930 = 94).
## Dimmed, as 09 §4.1 dims a plate a panel sits on top of.
const SCENE := "stage_camp"
const SCENE_OFFSET := Vector2(-46, -94)
## Lightly dimmed, not pushed to the back: on every other screen the plate is a
## backdrop to something being read, but here the camp with the guild still in it
## IS the message. The report sits in a band across the bottom and the rest of
## the viewport is the place the player is about to walk back into.
const SCENE_DIM := Color(0.82, 0.82, 0.86)

## The report band. Measured against its own content — a headline, the four-line
## tally, the two meters and the closing line at a 6px pitch — rather than
## filled to the viewport, because a panel with 500px of nothing in it reads as
## a broken screen. (The old 348 was short of the content and the panel grew
## past it, harmlessly while it stood at the top; at the bottom it must be the
## real number, and `grow_vertical` BEGIN makes a larger text scale grow it
## upward rather than off the host.)
const PANEL_H := 368
const PANEL_GAP := 6
## TOWN-13: the band sits across the BOTTOM of the viewport, so the fire ring
## and the guild around it (plate y 340-432, host y 246-338 at this offset) are
## in the open above it — the ending shows the camp with the guild in it. The
## finding's (-46,-300) offset would put the ring under a top band (host y 119),
## so the band moved instead, which is the finding's own alternative.
const PANEL_INSET := Vector2(18, 14)

## The sidebar column's true width: 378 less the PanelWarm rim (14 a side) and
## the pad (18 a side). The old 330 overflowed the pad by 16px and pushed the
## CTA's right rim past the column (TOWN-13's "jammed against the panel edge").
const SIDEBAR_W := 314
## W5-SCALE: the column's gap at 100%; larger text scales give part of it
## back (`_gap`, the way Frame.chip_gap does), because at 150 the roll, the
## file's lines and a three-line commit want 918px of the pad's 861 — the
## commit's plate sat 32px through the frame's bottom edge, measured.
const SIDEBAR_GAP := 10
## The commit's plate at 100%; `Type.at` scales it with the text. Its text
## wraps to three lines at 150 in this column whatever the inset (the second
## line "the guild carries on" is 297px at 32px in 314), and the plate takes
## the height three lines need — so the room is found above it, not here.
const BTN_H := 70
## KIT-05 / TOWN-13: the commit's plate keeps its side margins this wide, so
## the label's wrap breaks after "guild" instead of stranding "on" alone —
## with the plate's own 14px the first line "Back to town — the guild carries"
## just fits (305px in 300) — and both lines sit well inside the rims.
const CTA_SIDE_INSET := 29
## The roll: 48px portraits (TOWN-13), two to a row, so fifteen raiders fit
## above the file's lines without a scroll (LESSONS: a scroll hides a defect).
const PORTRAIT := 48
const ROLL_COLUMNS := 2
const ROLL_GAP := 6

## A `lines` entry that is a MARKER for a person, not a line for the player:
## "[designer credit pending]" (W6-LEDGER's draft roll carries one). Wrapped in
## square brackets, and never printed (LOOP-27 / C8): the roll shows what is
## signed and says nothing about what is not.
const MARKER_OPEN := "["
const MARKER_CLOSE := "]"

var _router = null
var _state = null
var _built := false


func _ready() -> void:
	build()


## Idempotent and public for the same reason every other screen's is: under a
## SceneTree script (the test runner, tools/) `_ready` never fires, and the
## router calls this after mounting so both paths behave identically.
func build() -> void:
	if _built:
		return
	_built = true
	_router = Services.router(self)
	_state = Services.state(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Theme_.current(self)
	_mark_seen()
	_build()


## docs/15 BL-73: the beat is spent here, on arrival.
func _mark_seen() -> void:
	if _state != null and "completion_seen" in _state:
		_state.completion_seen = true


func _build() -> void:
	# Archetype C (art/ref/specs/10-screen-audit.md §1): the chrome, with the
	# scene viewport replaced by one panel filling the same rectangle. `tall`
	# because there is no desk strip to keep — the report IS the screen.
	var f := Frame.build(self, {"nav": Frame.nav_items(_router), "active": "",
		"framed": true, "tall": true})
	# No lit rail item and every item live: this screen is not a building, and a
	# rail that went nowhere would trap a player inside their own ending.
	Frame.wire_nav(f, _router, "")
	Frame.standard_chips(f, _state)
	_scene(f.scene)
	_sidebar(Frame.sidebar(f))


# ---------------------------------------------------------------- the report

func _scene(host: Control) -> void:
	var stage := SceneStage.load(SCENE)
	stage.position = SCENE_OFFSET
	stage.size = host.size - SCENE_OFFSET
	stage.modulate = SCENE_DIM
	host.add_child(stage)
	_camp_speaks(stage)

	var panel := Widgets.panel("PanelWarm", 18)
	host.add_child(panel)
	panel.position = Vector2(PANEL_INSET.x, host.size.y - PANEL_INSET.y - PANEL_H)
	panel.size = Vector2(host.size.x - 2.0 * PANEL_INSET.x, PANEL_H)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.clip_contents = true

	var col := Widgets.column(PANEL_GAP)
	Widgets.content_of(panel).add_child(col)

	col.add_child(Widgets.label_as("The guild is finished.", "LabelSection"))
	col.add_child(_wrapped(_headline(), "LabelBody"))
	col.add_child(Widgets.rule())

	col.add_child(Widgets.label_as("The run", "LabelLabel"))
	for line in _report_lines():
		col.add_child(Widgets.label_as(String(line), "LabelBody"))

	col.add_child(Widgets.rule())
	col.add_child(Widgets.label_as("What is left", "LabelLabel"))
	# docs/10 §13 row 2's two meters, phrased by the sim so this screen and the
	# Records tab cannot drift apart. This IS the endgame's UI, by design.
	col.add_child(Widgets.label_as(Achievements.remaining_line(_snapshot()), "LabelBody"))

	col.add_child(Widgets.rule())
	col.add_child(_wrapped("The save continues. Nothing is taken away — the roster, the gold and"
		+ " the board are where you left them, and the fights can be fought again.", "LabelSmall"))


## The camp's one speaking bubble, exactly as Town fills it: the roster's own
## backstory bullets (docs/03), so the line is the guild's rather than a line
## written for an ending nobody has authored. The scene JSON's generic lines are
## the fallback, and on this screen they would be the wrong ones — a raider who
## has just finished the campaign is not still hoping for "a real raid".
func _camp_speaks(stage) -> void:
	if _state == null:
		return
	var lines: Array = []
	for r in _state.roster:
		for bullet in r.backstory:
			var text := str(bullet)
			if typeof(bullet) == TYPE_DICTIONARY:
				text = String((bullet as Dictionary).get("text", ""))
			if not text.is_empty():
				lines.append(text)
	stage.set_lines(lines)


## docs/10 §13's own framing: the ending is a sentence about this guild, not a
## score. `completed_on_day` rather than `day`, because the report is about the
## day it happened and the campaign keeps running after it.
func _headline() -> String:
	if _state == null:
		return "No guild loaded."
	var when: int = int(_state.completed_on_day)
	if when <= 0:
		when = int(_state.day)
	var played: int = int(_state.played_seconds)
	# `played_words` rather than a second phrasing of the same number: the save
	# screen already says "6 hours in" and two ways of saying it would drift.
	return "%s cleared the last fight on day %d, at %s — %s." % [
		String(_state.guild_name), when, String(_state.rank_name()),
		SaveGame.played_words(played)]


func _report_lines() -> Array:
	if _state == null:
		return []
	var clears: int = 0
	for enc_id in _state.cleared:
		clears += maxi(0, int(_state.cleared[enc_id]))
	var roster_size: int = (_state.roster as Array).size()
	return [
		"Encounters cleared  %d" % clears,
		"Days spent  %d" % int(_state.day),
		"Raiders on the books  %d" % roster_size,
		"Gold in the strongbox  %d G" % int(_state.gold),
	]


func _snapshot() -> Dictionary:
	if _state == null:
		return Achievements.blank_snapshot()
	return Achievements.snapshot(_state)


# ---------------------------------------------------------------- the credits

## A centred roll (TOWN-13): the guild's own roster first — the people the run
## was about, as names, classes and portraits — then the file's lines, then the
## one commit. Every word is a Label, so the walker reads the names and
## test_screens.gd:567-577 still finds each credit line verbatim.
func _sidebar(host: Control) -> void:
	if host == null:
		return
	var col := Widgets.column(_gap())
	host.add_child(col)
	col.add_child(_centred("Credits", "LabelSection"))
	_roll(col)
	# The file's lines, if a person has written any (LOOP-27 / C8): with
	# `lines` empty — or holding only markers — the roll is the guild alone,
	# and nothing about the state of the credits reaches the player. The
	# file's `status` sentence is the record of why they are empty; it is for
	# the person who signs the roll, and is never printed.
	var lines: Array = credit_lines()
	if not lines.is_empty():
		col.add_child(Widgets.rule())
	for line in lines:
		var text := String(line)
		if text.is_empty():
			# A blank entry is a spacer in the roll, and an empty Label is the
			# honest way to draw one — it keeps the line count the file wrote.
			col.add_child(Widgets.label_as("", "LabelSmall"))
		else:
			var l := _wrapped(text, "LabelSmall")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(l)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)

	col.add_child(Widgets.rule())
	# The one crimson control on the screen (art/ref/specs/06-ui-component-kit.md
	# §3): there is exactly one commit here, and its text says what it does —
	# "Continue" alone would read as a menu, and the save carrying on IS the
	# ruling this screen exists to deliver. The text is verbatim (a test finds
	# the Button by it); it wraps inside the plate through cta()'s guard
	# (KIT-05) — only the height is set here, never the width the guard chose.
	var back := Widgets.cta("Back to town — the guild carries on")
	back.custom_minimum_size.y = Type.at(BTN_H, Theme_.scale_of(self))
	back.pressed.connect(_on_back)
	col.add_child(back)
	_inset_cta(back)


## The roster as credits: two to a row, a 48px portrait beside the name over
## the class word, the grid centred in the column. An empty roster (a guild
## that finished with nobody on the books, or a contentless state) says so.
func _roll(col: VBoxContainer) -> void:
	col.add_child(_centred("The guild", "LabelLabel"))
	var roster: Array = []
	if _state != null:
		roster = _state.roster
	if roster.is_empty():
		col.add_child(_centred("Nobody on the books.", "LabelMuted"))
		return
	var grid := GridContainer.new()
	grid.name = "Roll"
	grid.columns = ROLL_COLUMNS
	grid.add_theme_constant_override("h_separation", ROLL_GAP)
	grid.add_theme_constant_override("v_separation", ROLL_GAP)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(grid)
	var cell_w: float = float(SIDEBAR_W - ROLL_GAP * (ROLL_COLUMNS - 1)) / float(ROLL_COLUMNS)
	for r in roster:
		grid.add_child(_credit(r, cell_w))


func _credit(r, cell_w: float) -> Control:
	var row := Widgets.row(ROLL_GAP)
	row.name = "Credit_" + String(r.display_name)
	row.custom_minimum_size = Vector2(cell_w, PORTRAIT)
	row.add_child(Widgets.slot(Cards.portrait_for(r), PORTRAIT, "SlotMini"))
	var text := Widgets.column(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var who := Widgets.label_as(String(r.display_name), "LabelName")
	who.clip_text = true
	who.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(who)
	# The class word in LabelClass's size and colour without the face sheet's
	# line height (36 at 150 for a face this line never prints; W5-SCALE): the
	# row is the portrait's 48 at 100 either way, and 63 instead of 70 at 150.
	var cls := Widgets.label_as(Enums.class_name_of(r.class_id), "LabelMuted")
	cls.add_theme_color_override("font_color", Palette.TEXT_SLATE)
	text.add_child(cls)
	row.add_child(text)
	return row


## The commit's plate with its side margins widened to CTA_SIDE_INSET: the
## theme's own boxes, copied, so the crimson, the glow and the pressed drop
## are untouched and the focus ring stays the theme's.
func _inset_cta(b: Button) -> void:
	for slot in ["normal", "hover", "pressed", "disabled"]:
		var box: StyleBox = b.get_theme_stylebox(slot)
		if box == null:
			continue
		var inset: StyleBox = box.duplicate()
		inset.content_margin_left = CTA_SIDE_INSET
		inset.content_margin_right = CTA_SIDE_INSET
		b.add_theme_stylebox_override(slot, inset)


func _on_back() -> void:
	if _router != null:
		_router.goto(TOWN)


## The sidebar column's gap at the player's text scale: SIDEBAR_GAP at 100,
## 8 at 125, 6 at 150 — identity at 100 by construction.
func _gap() -> int:
	return int(float(SIDEBAR_GAP) * 100.0 / float(Type.step(Theme_.scale_of(self))))


## The roll, read from `data/credits.json` and printed verbatim — every
## `lines` entry that is not a marker (`is_marker`). Empty until a person
## writes the roll; the file's `status` is never part of it (LOOP-27). Public
## and static so a test can read exactly what the screen will print without
## walking its nodes.
static func credit_lines() -> Array:
	var doc: Dictionary = _read(CREDITS_PATH)
	var out: Array = []
	var lines = doc.get("lines", [])
	if typeof(lines) == TYPE_ARRAY:
		for line in (lines as Array):
			if not is_marker(String(line)):
				out.append(String(line))
	return out


## "[…]" — a note to the person who signs the roll, kept in the file's lines
## so the draft and the signed roll are one array, and never printed.
static func is_marker(line: String) -> bool:
	var s := line.strip_edges()
	return s.length() >= 2 and s.begins_with(MARKER_OPEN) and s.ends_with(MARKER_CLOSE)


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Completion: no credits at %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _wrapped(text: String, variation: String) -> Label:
	var l := Widgets.label_as(text, variation)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(SIDEBAR_W, 0)
	return l


static func _centred(text: String, variation: String) -> Label:
	var l := Widgets.label_as(text, variation)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
