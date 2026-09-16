extends Control
## S01 — Title / Guild select (docs/13 §5).
##
## Primary action Continue, exit Quit. Continue reads docs/14 §7's save slots and opens
## the most recently written one; when there is nothing readable it is disabled with the
## reason on it — docs/13 §7 requires a disabled control to state why, and a missing
## button teaches the player the feature does not exist.
##
## docs/14 §7.1's header exists for exactly this screen: "read WITHOUT parsing the body,
## so the load menu can show an incompatible save instead of crashing on it."
##
## Every navigation target is checked with `screen_exists()` rather than assumed.
## A menu that offers a button to a scene nobody has written yet is the exact
## dead end the build quality bar forbids — and because the check is real, each
## button lights up on its own the iteration its screen lands.
##
## THE LOOK (10 §3.13): none of the three reference concepts is a title screen,
## so this is the frame's language without its chrome — the bare aerial town
## (09 §1, `stage_town.png`, 1536x1024 at 1:1) full-bleed, a dark scrim over its
## left third so type reads, the header's own lockup (the emblem, the authored
## 58 mark and Concept 3's tagline, 01 §5 / 03 §6 — TOWN-12) at the left, a
## version line in the corner, and the four actions as one column: the single
## crimson commit (New Guild) over three secondary buttons (06 §3/§7). Hover is
## the theme's lighter plate lifted one pixel — never a scale, never a tween
## (docs/13 §12.3, M6-JUICE-01).

const Widgets = preload("res://game/ui/Widgets.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Services = preload("res://game/core/Services.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")

const TOWN := "res://game/screens/Town.tscn"
const RESULTS := "res://game/screens/Results.tscn"
const SETTINGS := "res://game/screens/Settings.tscn"
const LOAD_SAVE := "res://game/screens/LoadSave.tscn"
## The scene this screen stands on: the designer's bare aerial town.
const TOWN_SCENE := "stage_town"

## The lockup and the stack sit on the reference frame's left third, clear of
## the plate's guildhall (which the scrim leaves lit at the right). LOCKUP_AT is
## the emblem's top-left; the mark, the tagline and the rule hang off it at the
## header's own relative metrics, so the title IS the header's lockup at the
## title's size.
const LOCKUP_AT := Vector2(120, 296)
const STACK_AT := Vector2(122, 452)
const BUTTON_W := 336
const CTA_H := 62
## The title's mark: the full-size 58 (01 §5), the one Boot's card carries too.
const TITLE_MARK := "wordmark_58"
## 01 §5: the 58 mark's baseline sits 45px under the emblem's top (60 - 15) and
## its left edge at the emblem's right (22 + 82 = 104).
const MARK_BASELINE_DY := 45
## 03 §6 hangs the tagline's baseline 23px under the 44 mark's; at the 58's size
## that is 30 (23 x 58/44). The rule rides 6px above the tagline's baseline
## (y 67 against 73) and 2px tall.
const TAGLINE_BASELINE_DY := 30
const TAGLINE_RULE_DY := 6
## 03 §6: the rule fills what the tagline leaves of the mark's width so the
## block right-aligns; narrower than this it is a stub, not a rule, and is not
## drawn (the header makes the same call in `Frame.draw_lockup`).
const RULE_MIN_W := 24
## The version line's corner (TOWN-12): inside the page gutter, bottom-left.
const VERSION_AT := Vector2(24, 44)

var _router = null
var _state = null
var _notice := ""
var _built := false


func _ready() -> void:
	build()


## Populate the page. Idempotent, and public because `_ready()` is not a
## reliable trigger everywhere this screen is used: a SceneTree script (the test
## runner, tools/) adds nodes to a root that is not itself "inside the tree", so
## `_ready` never fires and the screen would mount completely blank. The router
## calls this after mounting, which makes the two paths behave identically.
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
	add_child(Widgets.ground())

	# 09 §1: the plate is authored at the frame's own size, so it is drawn 1:1
	# from the top-left and never scaled. Slightly dimmed so the chrome reads.
	#
	# The 2026-09-11 directive: the designer's own bare aerial (`stage_town`)
	# rather than `menu_plate.png`, the reference sheet's top-down town. It is a
	# SceneStage, not a TextureRect: the harbour's water shimmer is on
	# (stage_town.json's three shimmer rects), the sky's cloud drift and the
	# chimney smoke landed with W2-STAGE2, the windmill sails turn and the gulls
	# cross since W4-LIFE (`rotor` / `flyers`), and only the airship is still
	# M4B-VFX-01's (RULES-05). It has no figures at any scale we own
	# (M4B-ACT-04). `--frames=1,60` shows the sky and the water moving and the
	# ground still; under reduced_motion the two frames are identical.
	var stage := SceneStage.load(TOWN_SCENE)
	stage.position = Vector2.ZERO
	stage.size = Widgets.SCREEN
	stage.modulate = Color(0.82, 0.82, 0.86)
	add_child(stage)
	add_child(_scrim())

	add_child(_lockup())
	add_child(_version())

	var menu := Widgets.column(12)
	add_child(menu)
	menu.position = STACK_AT
	menu.size = Vector2(BUTTON_W, 0)

	# New Game is the commit control: it discards whatever guild is loaded.
	# docs/13 §3 — exactly one crimson plate per screen, and this is it.
	var new_reason := "" if _can_go(TOWN) else "The town is not built in this version yet."
	var new_game := Widgets.wax_button("New Guild")
	new_game.disabled = not new_reason.is_empty()
	new_game.custom_minimum_size = Vector2(BUTTON_W, CTA_H)
	new_game.pressed.connect(_on_new_game)
	menu.add_child(new_game)
	if not new_reason.is_empty():
		menu.add_child(_reason_label(new_reason))

	# docs/14 §7's slots. A damaged or too-new save shows its reason here rather than
	# crashing the menu, which is what §7.1's header-first read is for.
	var newest: Dictionary = SaveGame.newest_loadable()
	var cont_reason := ""
	var cont_label := "Continue"
	if newest.is_empty():
		cont_reason = "No saved guild found."
		for row in SaveGame.slot_summaries():
			if bool(row["exists"]) and not String(row["blocked"]).is_empty():
				cont_reason = String(row["blocked"])
	else:
		cont_label = "Continue — %s" % String(newest.get("guild_name", "your guild"))
	if not _can_go(TOWN):
		cont_reason = "The town is not built in this version yet."
	var cont := Widgets.button_with_reason(cont_label, cont_reason)
	_fit_reason(cont)
	var cont_btn := Widgets.button_of(cont)
	if cont_btn != null:
		cont_btn.custom_minimum_size = Vector2(BUTTON_W, 0)
		if cont_reason.is_empty():
			var path: String = String(newest.get("path", ""))
			cont_btn.pressed.connect(func() -> void: _load_and_go(path))
	menu.add_child(cont)

	# Continue opens the newest readable save anywhere; this is the way to the other two
	# slots, to an older autosave, and to the only place a slot can be deleted. Gated by
	# `screen_exists` like every other target, so it lights up when its screen lands.
	var slots_reason := "" if _can_go(LOAD_SAVE) else "The guild slots are not in this version yet."
	var slots := Widgets.button_with_reason("Load Guild", slots_reason)
	_fit_reason(slots)
	var slots_btn := Widgets.button_of(slots)
	if slots_btn != null:
		slots_btn.custom_minimum_size = Vector2(BUTTON_W, 0)
		if slots_reason.is_empty():
			slots_btn.pressed.connect(func() -> void: _router.push(LOAD_SAVE))
	menu.add_child(slots)

	var settings_reason := "" if _can_go(SETTINGS) else "Settings are not in this version yet."
	var settings := Widgets.button_with_reason("Settings", settings_reason)
	_fit_reason(settings)
	var settings_btn := Widgets.button_of(settings)
	if settings_btn != null:
		settings_btn.custom_minimum_size = Vector2(BUTTON_W, 0)
		if settings_reason.is_empty():
			settings_btn.pressed.connect(func() -> void: _router.push(SETTINGS))
	menu.add_child(settings)

	var quit := Widgets.button("Quit")
	quit.custom_minimum_size = Vector2(BUTTON_W, 0)
	quit.pressed.connect(_on_quit)
	menu.add_child(quit)

	# docs/14 §7.3: a load that refused says so, in the failure colour, where
	# the player was looking.
	if not _notice.is_empty():
		var why := Widgets.label_as(_notice, "LabelBody")
		why.add_theme_color_override("font_color", Palette.DANGER)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(BUTTON_W + 80, 0)
		menu.add_child(why)

	_lift_on_hover(menu)


## TOWN-12: the title is the authored lockup — the emblem, the pre-rendered 58
## mark and the tagline texture (tools/art/gen_wordmark.py) — placed by their
## own baseline metrics the way `Frame.draw_lockup` places the header's, so
## the two are one drawing at two sizes. Whether the tagline hangs under the
## mark follows `Frame.LOCKUP` (Q05): the title says what every framed screen
## says. The Label "A Guild Story" — and the tagline's — stay beside the art
## as the strings a reader (and test_screens.gd:180) gets; they are not drawn
## a second time. RULES-14/Q16 (the logotype as art) is the designer's.
func _lockup() -> Control:
	var host := Control.new()
	host.name = "Lockup"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.position = LOCKUP_AT

	# 01 §5: the emblem, then the mark at its right edge.
	var emblem := TextureRect.new()
	emblem.name = "Emblem"
	emblem.texture = load("res://game/assets/ui/emblem.png")
	emblem.stretch_mode = TextureRect.STRETCH_KEEP
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(emblem)
	emblem.size = emblem.texture.get_size()
	var mark_x: float = emblem.size.x

	var mark := Frame.wordmark(TITLE_MARK)
	host.add_child(mark)
	mark.position = Vector2(mark_x, MARK_BASELINE_DY - Frame.wordmark_baseline(TITLE_MARK))
	mark.set("accessibility_name", "A Guild Story")
	var title := Widgets.label_as("A Guild Story", "LabelWordmark")
	title.name = "Title"
	title.visible = false
	host.add_child(title)

	var spec: Dictionary = Frame.LOCKUPS[Frame.LOCKUP]
	if bool(spec["tagline"]):
		# 03 §6: the tagline on the mark's left edge, its baseline under the
		# mark's; the rule from text.right + 6 to the mark's right edge.
		var tag := Frame.wordmark("wordmark_tagline")
		host.add_child(tag)
		var tag_baseline: float = MARK_BASELINE_DY + TAGLINE_BASELINE_DY
		tag.position = Vector2(mark_x, tag_baseline - Frame.wordmark_baseline("wordmark_tagline"))
		tag.set("accessibility_name", "Questionable people. Worse decisions.")
		var tag_text := Widgets.label_as("Questionable people. Worse decisions.", "LabelTagline")
		tag_text.name = "Tagline"
		tag_text.visible = false
		host.add_child(tag_text)
		var rule_x: float = mark_x + tag.texture.get_width() + 6.0
		var rule_w: float = mark_x + mark.texture.get_width() - rule_x
		if rule_w >= RULE_MIN_W:
			var rule := ColorRect.new()
			rule.name = "TaglineRule"
			rule.color = Palette.HEADER_RULE_LIT
			rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
			host.add_child(rule)
			rule.position = Vector2(rule_x, tag_baseline - TAGLINE_RULE_DY)
			rule.size = Vector2(rule_w, 2)
	return host


## TOWN-12: the build says which build it is, bottom-left, in the muted face.
func _version() -> Label:
	var v := Widgets.label_as(version_line(), "LabelMuted")
	v.name = "Version"
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(VERSION_AT.x, float(Widgets.SCREEN.y) - VERSION_AT.y)
	return v


## `application/config/version` is the one place the number lives (the export
## preset's product_version is kept in step with it — handoff-W3-MENU asks the
## orchestrator for the key). An unset key prints an honest "Development build"
## rather than a number nobody set. Static so a test reads the same string.
static func version_line() -> String:
	var v := String(ProjectSettings.get_setting("application/config/version", ""))
	return "Version %s" % v if not v.is_empty() else "Development build"


## TOWN-12 / docs/13 §12.3 / M6-JUICE-01: hover is the theme's lighter plate
## plus a one-pixel lift — no scale, no tween. The lift is the theme's own
## hover StyleBox for the button's variation, copied with its content one
## pixel higher and the plate drawn one pixel up (expand top +1, bottom -1),
## so the control's rect and the stack's layout never move (§12.1: no layout
## shift on hover). The box is read from the theme by name rather than through
## `get_theme_stylebox`, which off the tree (the test harness) answers with the
## engine default. Disabled buttons draw `disabled`, so the reasoned Continue
## is untouched.
func _lift_on_hover(root: Node) -> void:
	var th: Theme = Theme_.current(self)
	for c in root.get_children():
		if c is Button:
			var b := c as Button
			var hover: StyleBox = _theme_hover(th, String(b.theme_type_variation))
			if hover != null:
				var lifted: StyleBox = hover.duplicate()
				lifted.content_margin_top = hover.content_margin_top - 1
				lifted.content_margin_bottom = hover.content_margin_bottom + 1
				lifted.expand_margin_top = hover.expand_margin_top + 1
				lifted.expand_margin_bottom = hover.expand_margin_bottom - 1
				b.add_theme_stylebox_override("hover", lifted)
		_lift_on_hover(c)


## The theme's `hover` box for a Button variation, walking the variation's
## base chain the way the engine does ("" is the plain Button).
static func _theme_hover(th: Theme, variation: String) -> StyleBox:
	var type_name := variation if not variation.is_empty() else "Button"
	while not type_name.is_empty():
		if th.has_stylebox("hover", type_name):
			return th.get_stylebox("hover", type_name)
		type_name = String(th.get_type_variation_base(type_name))
	return null


## The dark gradient over the plate's left third, so the lockup and the stack
## read against a busy town. Built from the ground token at falling alpha —
## no hex of its own. (A private helper; a `Widgets.scrim()` would let the
## camp and raid screens share it.)
func _scrim() -> Control:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.34, 0.62, 1.0])
	g.colors = PackedColorArray([
		Color(Palette.GROUND_PAGE, 0.94), Color(Palette.GROUND_PAGE, 0.86),
		Color(Palette.GROUND_PAGE, 0.42), Color(Palette.GROUND_PAGE, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 8
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var t := TextureRect.new()
	t.texture = tex
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _reason_label(text: String) -> Label:
	var l := Widgets.faint(text)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(BUTTON_W, 0)
	return l


## Keep a long slot-blocked reason inside the stack's column rather than
## running out under the plate.
func _fit_reason(box: Control) -> void:
	for c in box.get_children():
		if c is Label:
			(c as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			(c as Label).custom_minimum_size = Vector2(BUTTON_W, 0)


func _can_go(path: String) -> bool:
	return _router != null and _router.screen_exists(path)


func _on_new_game() -> void:
	if _state == null or _router == null:
		push_error("MainMenu: autoloads missing; cannot start a guild")
		return
	_state.new_game("A Guild Story")
	_router.goto(TOWN)


func _on_quit() -> void:
	get_tree().quit()


## docs/14 §7.3's load path from the menu's side: refuse loudly, load cleanly, and never
## leave a half-built campaign on the screen.
##
## `load_into` returns both hard refusals and soft content problems, so the campaign being
## `active` afterwards is what separates "loaded, with notes" from "did not load".
func _load_and_go(path: String) -> void:
	if path.is_empty() or _state == null:
		return
	var problems: Array = SaveGame.load_into(path, _state)
	if not problems.is_empty():
		_notice = String(problems[0])
	if not _state.active:
		_rebuild()
		return
	if _router == null:
		return
	# Q-53 / SHIP-03: a quit mid-replay owes the player the report. The save
	# carries the attempt as it departed (`active_run`); replaying it is the
	# fight that happened, and the report is where Continue lands.
	if _state.active_run_pending() and _router.screen_exists(RESULTS):
		if _state.replay_active_run() != null:
			_router.goto(RESULTS)
			return
	if _router.screen_exists(TOWN):
		_router.goto(TOWN)


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()
