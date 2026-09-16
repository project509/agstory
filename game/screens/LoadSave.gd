extends Control
## The Load/Save screen — docs/14 §7.2's three guild slots, made visible.
##
## docs/13 §5's inventory gives this no S-number of its own: S01 is "Title / Guild
## select", and the in-game half has no home in canon at all. So the screen is reached
## twice — from the title screen's stack (where S01's "choose or create a guild" is what
## it is doing) and from the Options sidebar in game — and the placement is written up
## in docs/13 §5, which still has no row for this screen — audit `M3-SAVE-04` owns it and
## docs/15 BL-73 is the precedent for propagating one. Nothing here invents a rank, a rate
## or a name.
##
## THE LOOK (art/ref/specs/10 §1): archetype **C**, "full-page list/detail ... A chrome
## (header chips + nav rail) with the scene viewport replaced by a panel filling the same
## rectangle". Built as `Settings.gd` builds it — the same `Frame.build` options, the
## bare camp dimmed under one warm panel, the footer in the sidebar — because 10 §1 says
## a C screen "does not invent a new container type". The one liberty (HALL-02): the
## panel stops short of the window's right edge so the camp's fire ring shows beside
## the three rows instead of an 18px sliver around them; and (HALL-16) it ends at its
## content, so the camp shows under the rows as well as beside them.
##
## THE ROWS (HALL-15, HALL-25, CRITIC-G05/G06): three identical rows — the slot's
## sentence, a meta line ("Written 12 Sep, 18:37" when there is a readable save, blank
## otherwise, so the buttons sit at the same height in every row), Load / Save / Delete
## at ONE width, and the row's reasons under them. A disabled button wears the kit's one
## treatment (`Widgets.reasoned`: dimmed, padlocked, the reason in CAUTION), but a row
## prints each reason ONCE — Load and Delete share "Slot 2 is empty." and the sentence
## is adjacent to both. A destructive press turns the row's buttons into the kit's
## confirm pair (`Widgets.confirm_pair`); "Keep it" puts the three back.
##
## WHAT IT SHOWS. Every row comes from `SaveGame.slot_summaries()`, which already returns
## a ready-made one-line `label` per slot ("Slot 1 — empty" / "Slot 1 — <guild>, 3 minutes
## in" / "Slot 1 — <reason it cannot be read>"). The screen does not re-derive any of it.
##
## THE CHROME DEGRADES HONESTLY. From the title screen there is no campaign, so
## `Frame.standard_chips` prints its single "No guild loaded." chip and every rail item is
## disabled WITH THAT REASON — docs/13 §7: a disabled control is never a mystery.
##
## SAVE WRITES THE MANUAL SLOT, NOT `row["path"]`. `path` is the newest file in the slot,
## which is usually one of the three rotating autosaves; writing there would spend a
## rotation entry and break docs/14 §7.2's manual-vs-rotating split, which is the backstop
## against a bad migration. So Save calls `save_slot(row["slot"], ...)` and Load calls
## `load_into(row["path"], ...)`, and those are deliberately two different files.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Services = preload("res://game/core/Services.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")

const TOWN := "res://game/screens/Town.tscn"
const RESULTS := "res://game/screens/Results.tscn"
const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const GuildhallScript = preload("res://game/screens/Guildhall.gd")

## docs/15 BL-78: the bare camp under the slots. HALL-02's composition: the
## window is 928x930 (the frame is `tall`), the panel stops at PANEL_W, and the
## band that leaves open — window x 590..928, screen x 800..1138 — is where
## this offset puts the fire ring (plate x 620..820 → window 610..810), its
## four seated raiders, the embers and the breathing fire light: the liveliest
## 330px of the camp, framed the way the Market chose its band. The two tent
## lanterns fall outside the band and cost nothing. Dimmed a step less than the
## Guildhall because the band is the point of the layout.
const CAMP_SCENE := "stage_camp"
const CAMP_OFFSET := Vector2(-10, -62)
const CAMP_DIM := Color(0.70, 0.70, 0.76)
const PANEL_W := 590
## The panel's pad (Widgets.panel) and PanelWarm's own content margin, which
## together leave 526px inside a 590px panel.
const PANEL_PAD := 18
## HALL-15: nine Buttons at ONE width. 200 (the finding's example) does not fit
## three abreast in the 526px the fire-ring band leaves, so the width is the
## one that does: 3 x 168 + 2 x BTN_GAP = 524.
const BTN_W := 168
const BTN_H := 36
const BTN_GAP := 10
## The confirm pair's plate carries the kit's 8px content margin on each side
## of its buttons (Widgets.confirm_pair), so the row that is asking is taller
## by that much — the panel arithmetic in `_fit_panel` knows it.
const CONFIRM_PAD := 8
## Gaps inside a row: sentence / meta / buttons / reasons; and the room a row
## keeps above its sentence and under its reasons, so the rules between rows
## never touch the text (seen on the first shot).
const ROW_GAP := 4
const ROW_PAD := 8
## HALL-16: the panel ends at its content. A few pixels over the arithmetic so
## the last row's rule never sits on the rim; the acceptance allows 60.
const PANEL_SLACK := 6
## A refusal (`_notice`) wraps at the panel's width; two lines are reserved for
## it in the panel's height so the rows beneath keep their room.
const NOTICE_LINES := 2
const SIDEBAR_W := 330
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct",
	"Nov", "Dec"]

var _router = null
var _state = null
var _built := false

## The slot a destructive press is waiting on confirmation for, as "save:0" /
## "delete:2", or "". docs/02 §6.3's rule as the Market applies it: a press that
## destroys something asks once, in place, rather than refusing or acting.
var _confirming := ""

## The last thing that went wrong, printed in the failure colour where the player was
## looking. docs/14 §7.3's refusals are sentences, and this is where they land.
var _notice := ""

var _rows_host: VBoxContainer = null
var _notice_host: VBoxContainer = null
var _panel: PanelContainer = null
## The scene host's height, for the panel's ceiling.
var _host_h: float = 0.0
## The panel's height with no rows and no notice (pads, header, rule, gaps),
## measured once the header is built — nothing in it wraps.
var _panel_chrome: float = 0.0
## Line heights at the player's text scale, measured from a probe Label of each
## variation the rows use (see `_line_h`).
var _line_body: float = 0.0
var _line_small: float = 0.0


func _ready() -> void:
	build()


## Idempotent and public for the same reason every other screen's is: under a SceneTree
## script (the test runner, tools/) `_ready` never fires, and the router calls this after
## mounting so both paths behave identically.
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
	var f := Frame.build(self, {"nav": _nav(), "active": "options",
		"framed": true, "tall": true})
	if _has_guild():
		Frame.wire_nav(f, _router, "options")
	Frame.standard_chips(f, _state)
	_scene(f.scene)
	_sidebar(Frame.sidebar(f))


## The rail (00 §2.6), with the one extra gate this screen needs: from the title screen
## there is no campaign, and every building behind those items would open onto nothing.
## docs/13 §7 — the reason is printed, not implied by a missing button.
func _nav() -> Array:
	var items := Frame.nav_items(_router)
	if _has_guild():
		return items
	var out: Array = []
	for item in items:
		var row: Dictionary = (item as Dictionary).duplicate()
		if String(row["id"]) != "options":
			row["reason"] = "No guild loaded."
		out.append(row)
	return out


func _has_guild() -> bool:
	return _state != null and bool(_state.get("active"))


# ---------------------------------------------------------------- the panel

func _scene(host: Control) -> void:
	# docs/15 BL-78: the bare camp, offset so its fire ring lands in the band the
	# panel leaves open (CAMP_OFFSET), dimmed so the rows stay the thing being read.
	var stage: Control = GuildhallScript.bare_stage(self, CAMP_SCENE)
	stage.position = CAMP_OFFSET
	stage.size = host.size - CAMP_OFFSET
	stage.modulate = CAMP_DIM
	host.add_child(stage)
	_host_h = host.size.y

	_line_body = _line_h("LabelBody")
	_line_small = _line_h("LabelSmall")

	var panel := Widgets.panel("PanelWarm", PANEL_PAD)
	host.add_child(panel)
	_panel = panel
	# At the window's origin, not inset 18px: HALL-16 — the frame's seam is the
	# rim, and a second rim 18px inside it read as a double frame. PANEL_W wide,
	# so the camp has the rest; as tall as its three rows (`_fit_panel`), so the
	# camp shows under them too.
	panel.position = Vector2.ZERO
	panel.size = Vector2(PANEL_W, host.size.y)
	panel.clip_contents = true

	var col := Widgets.column(6)
	Widgets.content_of(panel).add_child(col)

	var head := Widgets.row(16)
	head.add_child(Widgets.label_as("Guild Slots", "LabelSection"))
	# Two lines beside the title, broken here rather than by autowrap: the
	# panel's height is arithmetic (`_fit_panel`) and a wrapping Label cannot
	# say how tall it is until it has been laid out.
	var count := Widgets.label_as(
		"%d slots, each keeping one save you write\nand three the game writes for you."
		% SaveGame.SLOTS, "LabelSmall")
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(count)
	col.add_child(head)
	col.add_child(Widgets.rule())

	_notice_host = Widgets.column(0)
	col.add_child(_notice_host)

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


## The height of one line of `variation` at the player's scale, read off a probe
## Label parented under the themed screen (a Label outside the tree measures
## with the engine's default font). Nothing else in the file guesses a metric.
func _line_h(variation: String) -> float:
	var probe := Widgets.label_as("Slot", variation)
	add_child(probe)
	var h: float = probe.get_combined_minimum_size().y
	remove_child(probe)
	probe.free()
	return h


## Rebuild the rows from disk. Called after every write, because the label a row carries
## ("3 minutes in", "empty", a damage reason) is read from the file and nothing else.
func _refresh() -> void:
	if _rows_host == null:
		return
	for c in _rows_host.get_children():
		_rows_host.remove_child(c)
		c.queue_free()
	var rows: Array = SaveGame.slot_summaries()
	for i in rows.size():
		_rows_host.add_child(_slot_row(rows[i]))
		if i < rows.size() - 1:
			_rows_host.add_child(Widgets.rule())
	_paint_notice()
	_fit_panel()


func _paint_notice() -> void:
	if _notice_host == null:
		return
	for c in _notice_host.get_children():
		_notice_host.remove_child(c)
		c.queue_free()
	if _notice.is_empty():
		return
	var why := Widgets.label_as(_notice, "LabelBody")
	why.add_theme_color_override("font_color", Palette.DANGER)
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_host.add_child(why)


## HALL-16: the panel is as tall as what it holds — the chrome measured in
## `_scene`, every row's own height, the rules between them, the notice's two
## reserved lines — and never taller than the window. The rows' heights are set
## by `_slot_row` from measured lines, so this is a sum, not a layout pass.
func _fit_panel() -> void:
	if _panel == null or _rows_host == null:
		return
	var rows_h := 0.0
	for c in _rows_host.get_children():
		if c is Control:
			rows_h += (c as Control).custom_minimum_size.y
	var notice_h := 0.0
	if not _notice.is_empty():
		notice_h = NOTICE_LINES * _line_body + 6
	var want: float = _panel_chrome + notice_h + rows_h + PANEL_SLACK
	_panel.size = Vector2(PANEL_W, minf(want, _host_h))


## Test seam for HALL-16: the panel's height beside the content it was summed
## from, so a test can say the panel ends within the acceptance's 60px.
func panel_fit() -> Dictionary:
	if _panel == null:
		return {}
	var rows_h := 0.0
	for c in _rows_host.get_children():
		if c is Control:
			rows_h += (c as Control).custom_minimum_size.y
	return {"panel_h": _panel.size.y, "content_h": _panel_chrome + rows_h,
		"panel_w": _panel.size.x, "host_h": _host_h}


## One slot: its sentence, a meta line, then Load / Save / Delete at one width, then
## the row's reasons — each once. The slot NUMBER is the last word of every button so a
## test pressing by text fragment can name one row unambiguously.
func _slot_row(row: Dictionary) -> Control:
	var slot := int(row["slot"])
	var human := slot + 1
	var exists := bool(row["exists"])
	var blocked := String(row["blocked"])
	var readable := exists and blocked.is_empty()

	var col := Widgets.column(ROW_GAP)
	col.name = "SlotRow%d" % human

	var line := Widgets.label_as(String(row["label"]), "LabelBody")
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.name = "SlotLine"
	col.add_child(line)

	# HALL-25: the header's UTC stamp as a local day and time; the format
	# version, a number only a bug report reads, goes to the row's tooltip on a
	# readable row and onto the meta line only where it IS the reason.
	var meta_text := ""
	var version := int(row["save_version"])
	if readable:
		meta_text = written_words(String(row["created_at"]))
		if version > 0:
			line.tooltip_text = "Save format v%d" % version
	elif exists and version > 0:
		meta_text = "Save format v%d" % version
	var meta := Widgets.label_as(meta_text, "LabelSmall")
	meta.name = "SlotMeta"
	meta.add_theme_color_override("font_color", Palette.TEXT_MUTED)
	col.add_child(meta)

	var buttons_h: float = BTN_H
	var reasons: Array = []
	if _confirming == "save:%d" % slot:
		col.add_child(_confirm("Yes — overwrite Slot %d" % human,
			func() -> void: _on_save(slot)))
		buttons_h = BTN_H + 2 * CONFIRM_PAD
	elif _confirming == "delete:%d" % slot:
		col.add_child(_confirm("Yes — delete Slot %d" % human,
			func() -> void: _on_delete(slot)))
		buttons_h = BTN_H + 2 * CONFIRM_PAD
	else:
		var buttons := Widgets.row(BTN_GAP)
		buttons.name = "SlotButtons"
		for made in [_load_button(row, human), _save_button(slot, human, exists),
				_delete_button(slot, human, exists)]:
			buttons.add_child(made[0])
			if made[1] != null:
				reasons.append(made[1])
		col.add_child(buttons)

	# HALL-15: the row's reasons, each phrase once, under the buttons they
	# belong to (Load and Delete share "Slot N is empty."). The Labels are the
	# ones `Widgets.reasoned` made — the kit's colour, size and name.
	var why_row := Widgets.row(16)
	why_row.name = "SlotReasons"
	var seen: Array = []
	for why in reasons:
		var text: String = (why as Label).text
		if text in seen:
			(why as Label).free()
			continue
		seen.append(text)
		# Siblings need distinct names or the engine renames the second to
		# "@Label@N"; the kit's "Reason" stays on the first.
		if seen.size() > 1:
			why.name = "Reason%d" % seen.size()
		why_row.add_child(why)
	col.add_child(why_row)

	# Centred in a row taller than its lines by ROW_PAD each side (the rows'
	# column stacks rows at their own heights, so the pad is real room).
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size = Vector2(0, 2 * ROW_PAD
		+ _line_body + ROW_GAP + _line_small + ROW_GAP + buttons_h + ROW_GAP + _line_small)
	return col


## One button of a row at the row's one width. `Widgets.reasoned` is the one
## "disabled with reason" treatment (CRITIC-G06): the dim, the padlock, the reason
## in CAUTION. The reason Label comes back beside the box so `_slot_row` can print
## the row's phrases once each. Returns [box, reason_label_or_null, button].
func _row_button(text: String, reason: String) -> Array:
	var b := Widgets.button(text)
	b.custom_minimum_size = Vector2(BTN_W, BTN_H)
	var lock: Texture2D = null if reason.is_empty() else Icons.at("lock", "16")
	var box := Widgets.reasoned(b, reason, lock)
	var why: Node = box.get_node_or_null("Reason")
	if why != null:
		box.remove_child(why)
	return [box, why, b]


func _load_button(row: Dictionary, human: int) -> Array:
	var reason := ""
	if not bool(row["exists"]):
		reason = "Slot %d is empty." % human
	elif not String(row["blocked"]).is_empty():
		reason = String(row["blocked"])
	var made := _row_button("Load — Slot %d" % human, reason)
	if reason.is_empty():
		var path: String = String(row["path"])
		(made[2] as Button).pressed.connect(func() -> void: _on_load(path))
	return made


func _save_button(slot: int, human: int, exists: bool) -> Array:
	var reason := "" if _has_guild() else "No guild loaded."
	var made := _row_button("Save to Slot %d" % human, reason)
	if reason.is_empty():
		if exists:
			(made[2] as Button).pressed.connect(func() -> void: _ask("save:%d" % slot))
		else:
			(made[2] as Button).pressed.connect(func() -> void: _on_save(slot))
	return made


func _delete_button(slot: int, human: int, exists: bool) -> Array:
	var reason := "" if exists else "Slot %d is empty." % human
	var made := _row_button("Delete Slot %d" % human, reason)
	if reason.is_empty():
		(made[2] as Button).pressed.connect(func() -> void: _ask("delete:%d" % slot))
	return made


## The kit's confirm (CRITIC-G05): the destructive press becomes a sentence with the
## consequence in it and a way out beside it, on one DANGER-rimmed plate, the way out
## focused. It stands where the row's three buttons stood; both halves are Buttons, so
## the screen test can see the confirm as well as the action.
func _confirm(yes_text: String, act: Callable) -> Control:
	var plate: PanelContainer = Widgets.confirm_pair(yes_text, "Keep it",
		func() -> void: act.call(),
		func() -> void:
			_confirming = ""
			_refresh())
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for n in _buttons_in(plate):
		(n as Button).custom_minimum_size = Vector2(0, BTN_H)
	return plate


func _buttons_in(n: Node, out: Array = []) -> Array:
	if n is Button:
		out.append(n)
	for c in n.get_children():
		_buttons_in(c, out)
	return out


## HALL-25: the save header's UTC stamp (`Time.get_datetime_string_from_system(true)`,
## "2026-09-12T18:37:59") as the player's own day and time — "Written 12 Sep, 18:37".
## An empty or unreadable stamp prints nothing rather than a wrong time.
static func written_words(created_at: String) -> String:
	# The shape the header writes, checked first: the engine's parser prints an
	# error for anything else, and a hand-edited file must not fill the log.
	if created_at.length() != 19 or created_at[4] != "-" or created_at[7] != "-":
		return ""
	if created_at[10] != "T" or created_at[13] != ":" or created_at[16] != ":":
		return ""
	var unix: int = Time.get_unix_time_from_datetime_string(created_at)
	if unix <= 0:
		return ""
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(unix + bias * 60)
	var month: int = clampi(int(d.get("month", 1)), 1, 12)
	return "Written %d %s, %02d:%02d" % [int(d.get("day", 1)), MONTHS[month - 1],
		int(d.get("hour", 0)), int(d.get("minute", 0))]


# ---------------------------------------------------------------- the presses

func _ask(what: String) -> void:
	_confirming = what
	_notice = ""
	_refresh()


## docs/14 §7.3's load path, the same one MainMenu takes: refuse loudly, and never leave
## a half-built campaign on the screen. `load_into` returns hard refusals and soft content
## problems through one array, so whether the campaign came up `active` is what separates
## "loaded, with notes" from "did not load".
func _on_load(path: String) -> void:
	if path.is_empty() or _state == null:
		return
	_confirming = ""
	var problems: Array = SaveGame.load_into(path, _state)
	_notice = String(problems[0]) if not problems.is_empty() else ""
	if not _state.active:
		_refresh()
		return
	# Q-53 / SHIP-03: a report still owed lands on Results, replayed from the
	# stored attempt — the same route MainMenu's Continue takes.
	var owed: bool = _router != null and _state.active_run_pending() \
			and _router.screen_exists(RESULTS)
	if owed and _state.replay_active_run() != null:
		_router.goto(RESULTS)
	elif _router != null and _router.screen_exists(TOWN):
		_router.goto(TOWN)
	else:
		_refresh()


func _on_save(slot: int) -> void:
	_confirming = ""
	if not _has_guild():
		_notice = "No guild loaded."
		_refresh()
		return
	# The MANUAL slot. `row["path"]` is the newest file, which may be an autosave.
	var problem := SaveGame.save_slot(slot, _state)
	_notice = problem
	_refresh()


func _on_delete(slot: int) -> void:
	_confirming = ""
	# `erase_slot` takes the manual save, all three rotation entries and their backups —
	# a Delete that left an autosave behind would leave the row still full.
	SaveGame.erase_slot(slot)
	_notice = ""
	_refresh()


# ---------------------------------------------------------------- sidebar

func _sidebar(host: Control) -> void:
	if host == null:
		return
	var col := Widgets.column(10)
	host.add_child(col)
	col.add_child(Widgets.label_as("How saving works", "LabelSection"))
	col.add_child(_blurb("Each slot keeps one save you write here and three the game "
		+ "rotates through on its own. A row names the newest of the four, which is "
		+ "what Load opens; Save always writes your own copy and never spends one of "
		+ "the three."))
	col.add_child(Widgets.rule())
	col.add_child(_blurb("A slot the game cannot read says why instead of disappearing. "
		+ "Nothing here is repaired behind your back: a save from a newer build is "
		+ "refused, and an older one is brought forward with a backup written first."))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)

	var back := Widgets.button("Back")
	back.custom_minimum_size = Vector2(0, BTN_H)
	back.pressed.connect(_on_back)
	col.add_child(back)


func _blurb(text: String) -> Label:
	var l := Widgets.label_as(text, "LabelSmall")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(SIDEBAR_W, 0)
	return l


func _on_back() -> void:
	if _router == null:
		return
	if not _router.pop():
		_router.goto(MAIN_MENU)


## Test seam: what the screen believes is on disk, without walking its nodes.
func slot_rows() -> Array:
	return SaveGame.slot_summaries()
