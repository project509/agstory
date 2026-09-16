extends Control
## S15 — Settings (docs/13 §5, inventory at §15.1).
##
## §15.1 is a CLOSED LIST, and this screen renders exactly it: "if an option is
## not in this table, it does not exist in the settings screen." And, by the
## designer's wave-6 ruling (LOOP-26, UI-28, CRITIC-C10), an option that does
## not WORK does not exist on the screen either: a row whose subsystem is not
## here is HIDDEN (moved from ROWS to HIDDEN_ROWS — the key stays in
## `GameSettings.DEFAULTS` so an old settings.cfg still loads, and the row
## comes back the day the thing works), never padlocked forever and never
## offered as a toggle that silently does nothing. `Widgets.reasoned`'s
## padlock is kept for a row that is disabled for a reason the PLAYER can act
## on; today no row is. Four rows are hidden and each says why beside it.
##
## Two kinds of option are deliberately absent, each for a documented reason:
##   FEATURE_* flags — "Build flag — never a player setting" (§15.1)
##   Reduced flashing, contrast, minimum text size — §13 makes them
##     unconditional: a build requirement with a QA gate, not something the
##     player can get wrong. (The CVD ramp is the one §13 row that IS an
##     option, default off — `colourblind_safe`, ship plan §6 #40.)
##
## THE LOOK (10 §3.12): archetype C in the dashboard's chrome — the rail with
## Options lit, the stage of the screen this one was opened over dimmed behind
## one warm panel that carries the inventory as a table (option | what it does
## | its control), and the Back / Restore defaults / Apply footer in the
## sidebar. docs/13 §2's "colophon at the back of the ledger" was the paper
## metaphor, superseded by the references (00 §1); the title is now simply
## "Options".
##
## THE FINISH (HALL-16, HALL-17, CRITIC-G06, CRITIC-G16): every row is ROW_H
## tall so the table has one pitch; a value control is the kit's chip and an
## engaged value (On, or anything that is not the inventory's default) wears the
## chip's pressed state; a volume row draws its ladder as pips beside the number,
## which stays the Button's text; a disabled row's control wears `Widgets.reasoned`
## (dimmed, padlocked) with the kit's reason Label standing in the row's
## description column so the row keeps its pitch; the panel ends at its last row
## and the stage shows in the band beneath; Apply is a lit secondary, not the
## crimson commit — crimson spends time, gold or a raider, and options spend none.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Icons = preload("res://game/ui/Icons.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Services = preload("res://game/core/Services.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")
const GuildhallScript = preload("res://game/screens/Guildhall.gd")
const Enums = preload("res://sim/model/Enums.gd")

const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const TOWN := "res://game/screens/Town.tscn"
const LOAD_SAVE := "res://game/screens/LoadSave.tscn"
const SETTINGS_SCENE := "res://game/screens/Settings.tscn"

## The rail's item list (00 §2.6), the same six as the camp's.
const RAIL := [
	{"id": "home", "label": "Camp", "scene": TOWN},
	{"id": "tavern", "label": "Tavern", "scene": "res://game/screens/Tavern.tscn"},
	{"id": "roster", "label": "Roster", "scene": "res://game/screens/Guildhall.tscn"},
	{"id": "market", "label": "Market", "scene": "res://game/screens/Market.tscn"},
	{"id": "board", "label": "Adventure's Board", "scene": "res://game/screens/AdventureBoard.tscn"},
	{"id": "options", "label": "Options", "scene": ""},
]

## docs/13 §15.1's rows, in the doc's own order, plus the two the doc folds into
## one line (window mode and V-sync) and the one §13 row that is an option
## (`colourblind_safe`). `reason` is what a disabled row says beside its
## control; every row here is live, so every reason is empty. ROWS is the
## table AS SHOWN — every test that counts rows, measures cells or walks
## `Row_<key>` nodes reads it and finds each one built. A row whose subsystem
## does not exist is in HIDDEN_ROWS below, not here (LOOP-26 C16/C19/C20,
## AUDIO-13's Voice row); `all_rows()` is the whole inventory for the tests
## that check keys against `GameSettings.DEFAULTS`.
##
## `reduced_motion` and `reduced_effects` went live with the art pass (10 §3.12
## re-evaluated both stale reasons). SceneStage is their consumer: reduced
## motion holds the flames, the light and the bubbles still; reduced effects
## drops the glow and the embers. `window_mode` and `vsync` went live with
## SHIP-06 (`GameSettings.apply_window_mode`, applied on press, on Apply and
## at boot).
##
## THE AUDIO ROWS went live with the audio pass. §15.1 gives them as one row
## — "Audio bus levels (master / music / UI / voice-of-the-scribe) | 100 /
## 80 / 80 / 100" — so the ORDER carries the meaning and this table repeats it
## in that order. Their consumer is the `Audio` autoload, which maps each key
## to its bus in `apply_levels()`. The Music row is labelled for what the bus
## carries from W7-AUD-AMB on (the ambience beds; no music — ship plan §6
## #46) and carries no note about the bus; the Voice row is hidden because
## nothing is voiced (AUDIO-13's default) — hidden, not padlocked, because a
## control that can never be enabled is not a control.
const ROWS := [
	{"key": "sim_speed", "label": "Sim speed", "reason": "",
	 "note": "1x / 2x / 4x always; Instant unlocks per encounter after a first clear."},
	{"key": "comedy_brake", "label": "Comedy brake", "reason": "",
	 "note": "A severe mistake, a death or a wipe keeps its beat at 2x and 4x."},
	{"key": "log_manual_advance", "label": "Log dwell", "reason": "",
	 "note": "The account pauses at each mistake until you dismiss it."},
	{"key": "emoji_free", "label": "Emoji-free mode", "reason": "",
	 "note": "Morale glyphs become a monochrome pip figure. The number and the "
		   + "state word are unaffected."},
	# UI-47 / docs/13 §8.3: the L*-ordered ramp behind a switch, default off (ship
	# plan §6 #40). The control shows the ten bands as plates (`_ramp_control`),
	# so the choice can be seen here before it is seen on a roster.
	{"key": "colourblind_safe", "label": "Colour-safe morale ramp", "reason": "",
	 "note": "Morale runs red to teal by lightness instead of red to green. "
		   + "The number and the state word are unaffected."},
	{"key": "display_aspect", "label": "Wide displays", "reason": "",
	 "note": "Keep: the 3:2 frame with bars at the sides. Expand: fill the width; "
		   + "the scene plates end where they end."},
	{"key": "window_mode", "label": "Window", "reason": "",
	 "note": "Fullscreen: borderless, at the desktop's size. Windowed: a 3:2 window "
		   + "that fits the desktop. F11 or Alt+Enter swaps them anywhere."},
	{"key": "vsync", "label": "V-sync", "reason": "",
	 "note": "Waits for the display's refresh, so nothing tears. Off lets a frame "
		   + "out the moment it is drawn."},
	{"key": "text_scale", "label": "Text scale", "reason": "",
	 "note": "100 / 125 / 150%."},
	{"key": "auto_loot", "label": "Auto loot", "reason": "",
	 "note": "Applies the suggested loot split without asking."},
	{"key": "reduced_motion", "label": "Reduced motion", "reason": "",
	 "note": "The scenes hold still: flames, lamplight and bubbles. Stamps still land, because they carry state."},
	{"key": "reduced_effects", "label": "Reduced effects", "reason": "",
	 "note": "No glow, no embers. Suggested automatically if a performance probe fails."},
	{"key": "audio_master", "label": "Audio — master", "reason": "",
	 "note": "Everything, and the level the wipe's silence ducks from."},
	{"key": "audio_music", "label": "Audio — music and ambience", "reason": "",
	 "note": ""},
	{"key": "audio_ui", "label": "Audio — interface", "reason": "",
	 "note": "Paper, chalk, brass, wax and coin: the stamp, the seal, the ledger."},
]

## The inventory's rows that are NOT shown: each one's subsystem does not
## exist, so by the wave-6 ruling the row does not either — hidden, never
## padlocked (a control that can never be enabled is not a control), its key
## kept in `GameSettings.DEFAULTS` so an old settings.cfg still loads and
## `save_to_disk` still writes it. Each says why; wave 10 (W10-DELETE) deletes
## what is still here, with its key. Never built: `_refresh` walks ROWS only.
const HIDDEN_ROWS := [
	# LOOP-26 C16: Fira Sans is already the body face, so what a second family
	# would be is Q16's to answer; retired in wave 10 under the §6 #40 default
	# unless the designer redefines it.
	{"key": "prose_font_swap", "label": "Prose font swap", "reason": "",
	 "note": "EB Garamond to Fira Sans."},
	# AUDIO-13, ship plan §6 #46: nothing is voiced. The bus and the key stay;
	# the row returns if `ui.quill` is bought (W8-AUD-OPT), else wave 10
	# deletes it.
	{"key": "audio_voice", "label": "Audio — voice", "reason": "", "note": ""},
	# LOOP-26 C19: one language ships. Back the day a second exists; deleted
	# with its key in wave 10 otherwise.
	{"key": "language", "label": "Language", "reason": "",
	 "note": "Falls back to en-US."},
	# LOOP-26 C20, ship plan §6 #65: a pad works, unverified and unsupported
	# for 1.0, so there is no glyph set to choose. Deleted in wave 10.
	{"key": "glyph_set", "label": "Controller glyphs", "reason": "",
	 "note": "Auto-detected from the connected pad."},
]


## The whole inventory as this screen knows it: the table, then the hidden
## rows. For the tests that hold the screen against `GameSettings.DEFAULTS`.
static func all_rows() -> Array:
	return ROWS + HIDDEN_ROWS

## The table's columns, in scene pixels: the option's name, what it does, its
## control. Together with the panel's padding they fill the 928px panel. The
## name column is sized to its widest name at 100% ("Audio — music and
## ambience"): a name that wraps at 100% makes its row taller than ROW_H and
## breaks the table's one pitch (HALL-17); at 150% the pitch scales and a
## two-line name fits it.
const COL_NAME_W := 204
const COL_NOTE_W := 444
const COL_CTRL_W := 150
## The control cell's height at 100%; `_ctrl_h()` scales it with the text the
## way ROW_H is scaled (W5-SCALE / M6-A11Y-05: it was the one hard pixel left).
const CTRL_H := 36
## HALL-17: one pitch for every row — tall enough for a two-line note beside a
## 36px control, scaled with the text (`Type.at`) so 150% keeps two lines too.
const ROW_H := 40
## The volume ladder as pips (HALL-17): one `Widgets.bar` per audible step of
## VOLUME_STEPS, lit up to the level, in the control cell beside the number.
const PIP_W := 12
const PIP_H := 10
const PIP_GAP := 3
## CRITIC-G16: Apply is a secondary control lit as the engaged one (06 §7.2's
## warm tint), not the screen's crimson commit. The variation is Theme.gd's to
## register (handoff-W3-OPTIONS); a name the theme lacks falls back to Button.
const APPLY_VARIATION := "ButtonSecondaryLit"
const APPLY_H := 48
## HALL-16: the panel ends at its content — a few pixels over the row sum so
## the last rule never sits on the rim; the acceptance allows 60.
const PANEL_SLACK := 6

## docs/15 BL-78 / spec 09 §4.5: this screen has no ground of its own — it
## stands on the stage of the screen it was opened over, dimmed, so the desk
## "does not move" (docs/13 §2 M5). `ScreenRouter.previous_path()` says which
## screen that is; this table says what that screen stands on and how it frames
## it (each screen's own offset constant, copied here because a screen's
## framing is the screen's, not the scene's). The hall pair reads the
## Guildhall's `framing()` so Q03's switch moves them together. Anything not
## listed — and a Settings with nothing beneath it, as tools/shot.gd mounts it
## — gets the camp at the Town's framing, the default the ruling names.
const STAGE_FOR := {
	"res://game/screens/Town.tscn": ["stage_camp", Vector2(-46, -62)],
	"res://game/screens/AdventureBoard.tscn": ["stage_camp", Vector2(-20, -80)],
	"res://game/screens/Completion.tscn": ["stage_camp", Vector2(-46, -62)],
	"res://game/screens/LoadSave.tscn": ["stage_camp", Vector2(-10, -62)],
	"res://game/screens/Tavern.tscn": ["stage_tavern", Vector2(-320, -130)],
	"res://game/screens/Market.tscn": ["stage_market", Vector2(-330, -240)],
	"res://game/screens/RaidPrep.tscn": [SceneStage.DEFAULT_ARENA, Vector2(-30, -120)],
	"res://game/screens/RaidView.tscn": [SceneStage.DEFAULT_ARENA, Vector2(-30, -120)],
	"res://game/screens/Results.tscn": [SceneStage.DEFAULT_ARENA, Vector2(-30, -120)],
	"res://game/screens/MainMenu.tscn": ["stage_town", Vector2.ZERO],
}
const STAGE_DEFAULT := ["stage_camp", Vector2(-46, -62)]
const HALL_SCREENS := [
	"res://game/screens/Guildhall.tscn",
	"res://game/screens/RaiderDetail.tscn",
]
## Spec 09 §4.5's value, kept.
const STAGE_DIM := Color(0.55, 0.55, 0.62)
## HALL-02: the panel ends short of the window's bottom so a band of the stage
## shows under the table — on the camp at the Town's framing that band is the
## stream's water shimmer, which is animated and worth the 100px. HALL-16 sizes
## the panel to its rows (`_fit_panel`); this is the band's floor, what a table
## too tall for the window (150%) still leaves, scrolling inside the panel.
const BAND_H := 100

var _router = null
var _state = null
var _settings = null
var _built := false
var _rows_host: VBoxContainer = null
var _panel: PanelContainer = null
## The scene host's height, for the panel's ceiling (`_fit_panel`).
var _host_h: float = 0.0
## The panel's height with no rows (pads, header, rule, gaps), measured once
## the header is built — nothing in it wraps, so the number is a fact.
var _panel_chrome: float = 0.0
## The text scale this instance was themed at, so Apply knows whether the page
## it is standing on is stale (see `_remount_if_rescaled`).
var _mounted_scale: int = 100
## How many times the window applier ran on this instance (`_apply_display`).
var _applied: int = 0


func _ready() -> void:
	build()


func build() -> void:
	if _built:
		return
	_built = true
	_router = Services.router(self)
	_state = Services.state(self)
	_settings = Services.find(self, "GameSettings")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Theme_.current(self)
	_mounted_scale = Theme_.scale_of(self)
	_build()


func _build() -> void:
	var nav: Array = []
	for item in RAIL:
		var scene := String(item["scene"])
		var reason := ""
		if not scene.is_empty() and (_router == null or not _router.screen_exists(scene)):
			reason = "Not built in this version yet."
		nav.append({"id": item["id"], "label": item["label"], "reason": reason})

	var f := Frame.build(self, {"nav": nav, "active": "options", "framed": true, "tall": true})
	for item in RAIL:
		var scene := String(item["scene"])
		var b: Button = f.nav_buttons.get(String(item["id"]))
		if b != null and not scene.is_empty() and not b.disabled:
			b.pressed.connect(func() -> void: _leave_to(scene))

	_scene(f.scene)
	Frame.standard_chips(f, _state)
	_sidebar(Frame.sidebar(f))


# ---------------------------------------------------------------- the panel

## What this screen stands on, given the screen beneath it: [scene, offset].
static func stage_for(previous: String) -> Array:
	if previous in HALL_SCREENS:
		var fr: Dictionary = GuildhallScript.framing()
		return [GuildhallScript.CAMP_SCENE, fr["offset"]]
	return STAGE_FOR.get(previous, STAGE_DEFAULT)


## The screen this page is opened over. The router appends to its stack AFTER
## the new screen has built (`push` → `_load_into_host` → `build()` → append),
## so while this page is building the opener is still `current_path()`;
## `previous_path()` is the answer only once this page is on the stack — a
## re-mount by `goto` at the root, or any reader that asks later.
func _opener() -> String:
	if _router == null:
		return ""
	var here := String(_router.current_path())
	if here.is_empty() or here == SETTINGS_SCENE:
		return String(_router.previous_path())
	return here


func _scene(host: Control) -> void:
	# 09 §4.5: the stage of the screen this one was opened over, dimmed — a
	# modal screen keeps the desk it was opened over (docs/13 §2.3 M5, kept by
	# 00 §1). See STAGE_FOR.
	var pick: Array = stage_for(_opener())
	var offset: Vector2 = pick[1]
	var stage: Control = GuildhallScript.bare_stage(self, String(pick[0]))
	stage.position = offset
	stage.size = host.size - offset
	stage.modulate = STAGE_DIM
	host.add_child(stage)

	var panel := Widgets.panel("PanelWarm", 18)
	host.add_child(panel)
	_panel = panel
	_host_h = host.size.y
	# At the window's origin (HALL-16: the frame's seam is the rim; a second one
	# 18px inside it read as a double frame). The frame is `tall` here (no
	# strip); the panel is as tall as its rows (`_fit_panel`) and never taller
	# than the window less the band that shows the stage (BAND_H) — past that
	# the table scrolls inside it.
	panel.position = Vector2.ZERO
	panel.size = Vector2(host.size.x, host.size.y - BAND_H)
	panel.clip_contents = true

	var col := Widgets.column(6)
	Widgets.content_of(panel).add_child(col)
	# The title alone (LOOP-26 C15): the "N of M live" count that stood beside
	# it was the loop's status board printed for the player.
	var head := Widgets.row(16)
	head.add_child(Widgets.label_as("Options", "LabelSection"))
	col.add_child(head)
	col.add_child(Widgets.rule())

	if _settings == null:
		col.add_child(Widgets.empty_state(
			"Settings are unavailable — the GameSettings autoload is missing."))
		return

	# 10 §2 R15: text scale applies to panels, so the table scrolls rather
	# than growing past the panel at 150%.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_rows_host = Widgets.column(0)
	_rows_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows_host)
	# Everything above the rows is built and nothing in it wraps, so this is
	# the panel's chrome — pads, header, rule, the column's gaps.
	_panel_chrome = panel.get_combined_minimum_size().y
	_refresh()


func _refresh() -> void:
	if _rows_host == null:
		return
	for c in _rows_host.get_children():
		_rows_host.remove_child(c)
		c.queue_free()
	for i in ROWS.size():
		_rows_host.add_child(_option_row(ROWS[i]))
		if i < ROWS.size() - 1:
			_rows_host.add_child(Widgets.rule())
	_fit_panel()


## HALL-16: the panel is as tall as what it holds — the chrome measured in
## `_scene`, ROW_H per row, the rules between them — and never taller than the
## window less the stage's band. The rows' heights are set, not laid out, so
## this is a sum; the same sum `panel_fit()` hands the test.
func _fit_panel() -> void:
	if _panel == null or _rows_host == null:
		return
	var want: float = _panel_chrome + _rows_height() + PANEL_SLACK
	_panel.size = Vector2(_panel.size.x, minf(want, _host_h - BAND_H))


func _rows_height() -> float:
	var rows_h := 0.0
	if _rows_host == null:
		return rows_h
	for c in _rows_host.get_children():
		if c is Control:
			rows_h += (c as Control).custom_minimum_size.y
	return rows_h


## Test seam for HALL-16 / HALL-17: the panel's height beside the content it
## was summed from, and the pitch every row was given.
func panel_fit() -> Dictionary:
	if _panel == null:
		return {}
	return {"panel_h": _panel.size.y, "content_h": _panel_chrome + _rows_height(),
		"host_h": _host_h, "row_h": _row_h()}


func _row_h() -> int:
	return Type.at(ROW_H, Theme_.scale_of(self))


func _ctrl_h() -> int:
	return Type.at(CTRL_H, Theme_.scale_of(self))


## One table row: name | note and reason | control. The name and the reason
## are Labels (the tests read the reason); the control is a Button. Every row
## is ROW_H tall (HALL-17). A disabled row's control wears `Widgets.reasoned`
## (CRITIC-G06: dimmed, padlocked, the reason in CAUTION); the kit's reason
## Label is moved from under the control into the description column so the
## row keeps the table's pitch — the reason stays a Label adjacent to its
## control, which is docs/13 §7's whole requirement.
func _option_row(row: Dictionary) -> Control:
	var key := String(row["key"])
	var reason := String(row["reason"])
	var line := Widgets.row(16)
	line.name = "Row_" + key
	line.custom_minimum_size = Vector2(0, _row_h())

	var name_label := Widgets.label_as(String(row["label"]), "LabelBody")
	name_label.custom_minimum_size = Vector2(COL_NAME_W, 0)
	# Wraps at its column: at 150% "Audio — voice of the scribe" is wider than
	# COL_NAME_W and an unwrapped name pushed the control cell off the panel's
	# right edge (LESSONS: one uncapped Label moves every column after it).
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if not reason.is_empty():
		name_label.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	line.add_child(name_label)

	var about := Widgets.column(0)
	about.custom_minimum_size = Vector2(COL_NOTE_W, 0)
	about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	about.alignment = BoxContainer.ALIGNMENT_CENTER
	var note := String(row["note"])
	if not note.is_empty():
		var n := Widgets.label_as(note, "LabelSmall")
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n.custom_minimum_size = Vector2(COL_NOTE_W, 0)
		about.add_child(n)
	line.add_child(about)

	var ctrl := _control_for(key, reason)
	ctrl.custom_minimum_size = Vector2(COL_CTRL_W, _ctrl_h())
	var lock: Texture2D = null if reason.is_empty() else Icons.at("lock", "16")
	var box := Widgets.reasoned(ctrl, reason, lock)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var why: Node = box.get_node_or_null("Reason")
	if why != null:
		# docs/13 §7: never a mystery — in the row, beside the control.
		box.remove_child(why)
		(why as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(why as Label).custom_minimum_size = Vector2(COL_NOTE_W, 0)
		about.add_child(why)
	line.add_child(box)
	return line


## One control per option kind. Everything is a button rather than a slider or a
## dropdown — the reference has no switch or segmented control (06 §7), so a
## value cycles when you press it. The control is the kit's chip, lit when the
## value is engaged (`_chip`); `Widgets.reasoned` in `_option_row` disables it
## when the row has a reason, so nothing here sets `disabled` itself. A volume
## row's control is a cell holding the pips and the number (`_volume_control`).
func _control_for(key: String, reason: String) -> Control:
	var disabled := not reason.is_empty()

	match key:
		"sim_speed":
			return _cycle_button(key, disabled, ["1x", "2x", "4x", "Instant"])
		"text_scale":
			var labels: Array = []
			for n in GameSettings.TEXT_SCALES:
				labels.append("%d%%" % n)
			return _scale_button(key, disabled, labels)
		"display_aspect":
			return _choice_button(key, disabled, ["keep", "expand"], ["Keep", "Expand"])
		"window_mode":
			return _choice_button(key, disabled, GameSettings.WINDOW_MODES,
				["Fullscreen", "Windowed"])
		"colourblind_safe":
			return _ramp_control(key, disabled)
		"language":
			return _chip("en-US", false)
		"glyph_set":
			return _chip(String(_settings.get_value(key)), false)
		"audio_master", "audio_music", "audio_ui", "audio_voice":
			return _volume_control(key, disabled)
	return _toggle_button(key, disabled)


## SHIP-06: the two window keys reach the window the moment they change, the
## way `display_aspect` always has — a choice you cannot see until a restart
## is a choice you cannot make. Every handler calls this before it rebuilds;
## Apply calls it again with the stored values (`_apply_display`), which is
## what the test pins. Keys that are not display keys are a no-op here.
func _after_change(key: String) -> void:
	if key == "display_aspect":
		GameSettings.apply_display_aspect(get_window(), String(_settings.get_value(key)))
	elif key == "window_mode" or key == "vsync":
		_apply_display()


## The window applier, with the stored values. `_applied` counts the calls for
## the test that pins "Apply runs the applier" — a headless DisplayServer
## accepts the calls and shows nothing, so the count is the only witness.
func _apply_display() -> void:
	if _settings == null:
		return
	_applied += 1
	GameSettings.apply_window_mode(get_window(),
		String(_settings.get_value("window_mode")), bool(_settings.get_value("vsync")))


## Test seam: how many times the window applier has run on this instance.
func display_applied() -> int:
	return _applied


## HALL-17: the value control is the kit's chip (HALL-12's `ButtonChip`), and an
## engaged value — On, or any value that is not the inventory's default — wears
## the chip's pressed state: gold rim, lit plate, gold text. State by chrome, not
## by font colour alone (docs/13 §8.5). The chip is a toggle so Godot draws that
## state; a press still cycles the value through the row's own handler, which
## rebuilds the row, so the toggle never drifts from the setting. Named "Button"
## so `Widgets.button_of` (and `reasoned`) find it inside a cell.
func _chip(text: String, engaged: bool) -> Button:
	var b := Widgets.button(text)
	b.name = "Button"
	b.theme_type_variation = "ButtonChip"
	b.toggle_mode = true
	b.button_pressed = engaged
	var th: Theme = theme
	if th != null and th.has_stylebox("pressed", "ButtonChip"):
		# A toggled chip under the pointer draws `hover_pressed`, which the kit
		# does not register (handoff-W3-OPTIONS asks for it); until it does, the
		# lit plate stays lit under the pointer.
		b.add_theme_stylebox_override("hover_pressed", th.get_stylebox("pressed", "ButtonChip"))
		if th.has_color("font_pressed_color", "ButtonChip"):
			b.add_theme_color_override("font_hover_pressed_color",
				th.get_color("font_pressed_color", "ButtonChip"))
	return b


## Whether a stored value is the inventory's default for its key.
func _is_default(key: String) -> bool:
	if not GameSettings.DEFAULTS.has(key):
		return true
	return _settings.get_value(key) == GameSettings.DEFAULTS[key]


func _toggle_button(key: String, disabled: bool) -> Button:
	var on: bool = bool(_settings.get_value(key))
	var b := _chip("On" if on else "Off", on)
	if not disabled:
		b.pressed.connect(func() -> void:
			_settings.set_value(key, not bool(_settings.get_value(key)))
			_after_change(key)
			_refresh())
	return b


func _cycle_button(key: String, disabled: bool, labels: Array) -> Button:
	var idx: int = clampi(int(_settings.get_value(key)), 0, labels.size() - 1)
	var b := _chip(String(labels[idx]), not _is_default(key))
	if not disabled:
		b.pressed.connect(func() -> void:
			var next: int = (int(_settings.get_value(key)) + 1) % labels.size()
			_settings.set_value(key, next)
			_refresh())
	return b


## A setting stored as one of a few words cycles through them; a display key
## is applied at once (`_after_change`) so the choice can be seen without a
## restart.
func _choice_button(key: String, disabled: bool, values: Array, labels: Array) -> Button:
	var idx: int = maxi(0, values.find(String(_settings.get_value(key))))
	var b := _chip(String(labels[idx]), not _is_default(key))
	if not disabled:
		b.pressed.connect(func() -> void:
			var at: int = maxi(0, values.find(String(_settings.get_value(key))))
			_settings.set_value(key, values[(at + 1) % values.size()])
			_after_change(key)
			_refresh())
	return b


## UI-47: the colour-safe ramp's control is the toggle chip with the ten
## morale bands drawn as plates beside it, in the volume row's own shape (pips
## beside the number) so the column keeps its edges. The plates are what the
## roster's morale bar and the kit's sparkline draw — `Palette.band_color_active`
## reads the option — so the row shows the choice before any roster does: the
## reference ramp is three colours across ten bands, docs/13 §8.3's is ten,
## red to teal by lightness. Plates, not text: §8.3's fills reach L* 16, which is
## why the text-tint sites keep the reference ramp (Palette.gd).
const SWATCH_W := 6
const SWATCH_GAP := 1


func _ramp_control(key: String, disabled: bool) -> Control:
	var cell := Widgets.row(6)
	cell.name = "Ramp_" + key
	var swatches := Widgets.row(SWATCH_GAP)
	swatches.name = "Swatches"
	swatches.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatches.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for band in Enums.MORALE_BAND_COUNT:
		var plate := ColorRect.new()
		plate.name = "Band%d" % int(band)
		plate.custom_minimum_size = Vector2(SWATCH_W, PIP_H)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.color = Palette.band_color_active(self, int(band) * 10 + 5)
		swatches.add_child(plate)
	cell.add_child(swatches)
	var b := _toggle_button(key, disabled)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_child(b)
	return cell


## docs/13 §15.1's four bus levels. A percentage, stepped rather than dragged:
## the reference has no slider and no switch (06 §7), so the level cycles on
## press like every other control on this screen.
##
## THE STEPS ARE 20% APART so that BOTH documented defaults — 100 for master
## and voice, 80 for music and interface — are values the player can press
## their way back to. A 25% ladder (0/25/50/75/100) would make §15.1's own 80
## unreachable from the screen that is supposed to own it.
##
## The button's TEXT is the value, deliberately: the screen test contract reads
## only `Label.text` and `Button.text`, so a slider would be an option no test
## could see. Pressing walks up to the next step and wraps at the top, which is
## also how 0 (mute) is reached.
const VOLUME_STEPS := [0, 20, 40, 60, 80, 100]


## HALL-17: the level as the ladder it walks — one pip per audible step of
## VOLUME_STEPS, lit up to the stored level (0 is an empty strip) — beside the
## number, which stays the Button's text. Each pip is the kit's bar
## (`Widgets.bar`, the secondary tint), so no new pixels; the pips never take
## the pointer, the Button does. The cell is COL_CTRL_W wide like every other
## control, so the column's edges stay straight.
func _volume_control(key: String, disabled: bool) -> Control:
	var level: int = int(_settings.get_value(key))
	var cell := Widgets.row(6)
	cell.name = "Volume_" + key
	var pips := Widgets.row(PIP_GAP)
	pips.name = "Pips"
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for step in VOLUME_STEPS:
		if int(step) <= 0:
			continue
		var lit: bool = level >= int(step)
		var pip := Widgets.bar(1.0 if lit else 0.0, 1.0, "mana", "", Vector2i(PIP_W, PIP_H))
		pip.name = "Pip%d" % int(step)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)
	cell.add_child(pips)
	var b := _chip("%d" % level, not _is_default(key))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not disabled:
		b.pressed.connect(func() -> void:
			_settings.set_value(key, _next_volume(int(_settings.get_value(key))))
			_refresh())
	cell.add_child(b)
	return cell


## The next step strictly above `current`, wrapping to silence. Written as a
## search rather than an index so a stored value off the ladder — §15.1's 80
## before this ladder existed, or a hand-edited settings.cfg — still steps
## somewhere sensible instead of snapping to 0.
static func _next_volume(current: int) -> int:
	for step in VOLUME_STEPS:
		if step > current:
			return step
	return int(VOLUME_STEPS[0])


## Text scale stores the percentage itself, not an index, so it cycles by value.
func _scale_button(key: String, disabled: bool, labels: Array) -> Button:
	var current: int = int(_settings.get_value(key))
	var idx: int = maxi(0, GameSettings.TEXT_SCALES.find(current))
	var b := _chip(String(labels[idx]), not _is_default(key))
	if not disabled:
		b.pressed.connect(func() -> void:
			var at: int = maxi(0, GameSettings.TEXT_SCALES.find(
				int(_settings.get_value(key))))
			var nxt: int = (at + 1) % GameSettings.TEXT_SCALES.size()
			_settings.set_value(key, GameSettings.TEXT_SCALES[nxt])
			_refresh())
	return b


# ---------------------------------------------------------------- sidebar

## The footer, stood up on the right: what the screen does with its writes,
## then Back / Restore defaults / Apply. docs/13 §15.1: "Written on Apply and
## on quit" — Apply is the commit control, but not a crimson one (CRITIC-G16):
## crimson spends time, gold or a raider, and options spend none, so Apply is
## the lit secondary (APPLY_VARIATION).
func _sidebar(host: Control) -> void:
	if host == null:
		return
	var col := Widgets.column(10)
	host.add_child(col)
	col.add_child(Widgets.label_as("Written to disk", "LabelSection"))
	var blurb := Widgets.label_as(
		"On Apply and when you leave — never on every press. Options belong to "
		+ "the installation, not to a guild: deleting a save leaves them alone.",
		"LabelSmall")
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(330, 0)
	col.add_child(blurb)
	col.add_child(Widgets.rule())
	# LOOP-26 C21: the sentence that stood here named a repo path. What the
	# player can use from anywhere is the window key (SHIP-06).
	var where := Widgets.label_as("F11 or Alt+Enter swaps fullscreen and windowed "
		+ "from any screen; Esc comes back here from the camp.", "LabelSmall")
	where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	where.custom_minimum_size = Vector2(330, 0)
	col.add_child(where)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)

	# docs/13 §5 gives the guild slots no S-number — S01 is "Title / Guild select", and
	# the in-game half of saving has no home in the inventory at all. The rail is a
	# closed list (00 §2.6) and options are not saves, so it hangs off Options here
	# rather than becoming a seventh rail item. docs/13 §5 still carries no row for the
	# save screen; audit `M3-SAVE-04` owns it.
	var slots_reason := ""
	if _router == null or not _router.screen_exists(LOAD_SAVE):
		slots_reason = "The guild slots are not in this version yet."
	var slots_btn := Widgets.button("Save / Load")
	slots_btn.custom_minimum_size = Vector2(0, _ctrl_h())
	if slots_reason.is_empty():
		slots_btn.pressed.connect(func() -> void:
			_save()
			_router.push(LOAD_SAVE))
	col.add_child(_reasoned(slots_btn, slots_reason))

	var back := Widgets.button("Back")
	back.custom_minimum_size = Vector2(0, _ctrl_h())
	back.pressed.connect(_on_back)
	col.add_child(back)

	# CRITIC-G06: the two writers are disabled only when there is nothing to
	# write to, and say so.
	var no_store := "" if _settings != null else "Settings are unavailable in this build."
	var defaults := Widgets.button("Restore defaults")
	defaults.custom_minimum_size = Vector2(0, _ctrl_h())
	if no_store.is_empty():
		defaults.pressed.connect(func() -> void:
			_settings.reset_all()
			_settings.save_to_disk()
			_refresh()
			_remount_if_rescaled())
	col.add_child(_reasoned(defaults, no_store))

	var apply := Widgets.button("Apply")
	apply.theme_type_variation = APPLY_VARIATION
	apply.custom_minimum_size = Vector2(0, APPLY_H)
	if no_store.is_empty():
		# SHIP-06: Apply is the commit, so the window keys are applied here
		# with the stored values as well as on their own presses.
		apply.pressed.connect(func() -> void:
			_apply_display()
			_settings.save_to_disk()
			_remount_if_rescaled())
	col.add_child(_reasoned(apply, no_store))


## The kit's one disabled treatment for the sidebar's buttons (CRITIC-G06),
## with the padlock only when there is a reason — the kit puts the glyph on
## before it reads the reason, so an enabled button handed the lock would wear
## it (RaidView review F2).
func _reasoned(b: Button, reason: String) -> Control:
	var lock: Texture2D = null if reason.is_empty() else Icons.at("lock", "16")
	var box := Widgets.reasoned(b, reason, lock)
	var why: Node = box.get_node_or_null("Reason")
	if why != null:
		(why as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(why as Label).custom_minimum_size = Vector2(330, 0)
	return box


## RULES-02: a screen learns the text scale when it builds its theme
## (`Theme_.current`), so a scale changed on this page is visible only after a
## rebuild. Every other screen is rebuilt on its next mount by construction;
## this page is the one standing when Apply — the commit, docs/13 §15.1 — is
## pressed, so it re-mounts itself. Restore defaults writes the file too, so it
## takes the same exit: a page still at 150 over a saved 100 is the bug again.
##
## The router has no "reload". A bare `goto(current_path())` would flatten the
## stack to this one page and turn Back into a trip to the main menu, and
## Settings is nearly always PUSHED (Esc from the camp, Start from anywhere).
## So a pushed page pops and pushes itself — the two moves the player could
## make by hand, with the same consequences and no others — and only a page
## standing at the root uses `goto`. Nothing moves when the scale is the one
## this instance was built at: applying a volume change must not restart the
## screen underneath.
func _remount_if_rescaled() -> void:
	if _router == null or Theme_.scale_of(self) == _mounted_scale:
		return
	var here: String = _router.current_path()
	if here.is_empty():
		return
	if _router.depth() >= 2:
		if _router.pop():
			_router.push(here)
	else:
		_router.goto(here)


# ---------------------------------------------------------------- leaving

func _save() -> void:
	if _settings != null:
		_settings.save_to_disk()


func _on_back() -> void:
	# docs/13 §15.1: written on Apply and on quit — leaving the screen is a quit
	# of the screen, and losing a toggle because you pressed Back is worse than a
	# spare disk write.
	_save()
	if _router == null:
		return
	if not _router.pop():
		_router.goto(MAIN_MENU)


## A rail item is also a way out, so it saves the same way Back does. The
## camp is the hub the stack stands on, so it is a `goto`; the rest push.
func _leave_to(scene: String) -> void:
	_save()
	if _router == null:
		return
	if scene == TOWN:
		_router.goto(scene)
	else:
		_router.push(scene)


## Test seam.
func option_rows() -> Array:
	return ROWS
