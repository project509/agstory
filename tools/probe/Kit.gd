extends Control
## Rebuilds Concept 1's chrome from the kit so it can be pixel-diffed.
##
## This is the art pass's own unit test. It is not a game screen: it assembles
## the frame, chips, rail, sidebar, cards and log at the reference's measured
## coordinates with the reference's own fixture text, so `tools/art/refdiff.py`
## scores the CHROME alone — before any screen's real data is wired in.
##
##   godot --path . --script res://tools/shot.gd -- res://tools/probe/Kit.tscn out.png 30 1536x1024
##   python tools/art/refdiff.py out.png 1

const Palette = preload("res://game/ui/Palette.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Fonts = preload("res://game/ui/Fonts.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")

## 00 §2.6 maps the reference's labels to canon's; the reference's own words are
## used here so the diff compares like with like.
const NAV := [
	{"id": "home", "label": "Home"},
	{"id": "recruit", "label": "Recruit"},
	{"id": "roster", "label": "Roster"},
	{"id": "gear", "label": "Gear"},
	{"id": "missions", "label": "Missions"},
	{"id": "reports", "label": "Reports"},
	{"id": "options", "label": "Options"},
]

const CARDS := [
	{"name": "Bork", "level": 12, "cls": "Warrior", "morale": 87, "quote": "\"I got this.\""},
	{"name": "Tiny", "level": 11, "cls": "Rogue", "morale": 14, "quote": "\"I hope there's no water...\""},
	{"name": "Gruk", "level": 9, "cls": "Cleric", "morale": 54, "quote": "\"I don't really believe in this.\""},
	{"name": "Spoof", "level": 10, "cls": "Mage", "morale": 31, "quote": "\"I'll just try my best... I guess.\""},
]

## Concept 1's seven rows with the reference's tone families, each typed by
## the feed kind it would carry in the game (Icons.LOG_KINDS), so the badge is
## the icon grid's `log_<kind>` sprite through the same door the shipping log
## uses (`Cards.badge_icon` + `Widgets.log_row`'s `kind`; m4t-09). The seven
## `badge_N.png` mockup crops this probe used to load are deleted (W5-TOOLS).
const EVENTS := [
	["Gruk returned from a failed mission. (0/3 survived)", "danger", "boss_attack"],
	["Spoof is feeling anxious about the next raid.", "info", "morale_down"],
	["You recruited a new member: Drel the Unlucky.", "gold", "recruit"],
	["Tiny broke a chair in the guild hall.", "danger", "mistake"],
	["Bork upgraded to level 12.", "gold", "morale_up"],
	["A raid team has returned with 2 new items.", "loot", "loot"],
	["You paid 2,400 gold for a new mission.", "gold", "gold"],
]

const ICON := "res://game/assets/ui/icons/"
const PORTRAIT := "res://game/assets/portraits/"

const BADGE := {
	"danger": Color("E44434"), "info": Color("6377A7"),
	"gold": Color("E1923F"), "loot": Color("819351"),
}

## Town.gd:134's placement of the camp stage inside the scene host, copied
## rather than preloaded so the probe does not depend on a screen.
const CAMP_OFFSET := Vector2(-46, -62)


## The second sheet (W1-CHROME): every theme variation the kit registers, laid
## out on the frame at 1536x1024, so a repaint can be looked at in one shot:
##
##   KIT_SHEET=variations tools/with_godot_lock.sh "$GODOT" --path . --script res://tools/shot.gd -- \
##     res://tools/probe/Kit.tscn build/shots/Kit_variations.png 30 1536x1024
##
## An environment variable rather than a shot.gd flag because shot.gd's `--set`
## grammar is the settings inventory (it refuses unknown keys) and the default
## sheet must stay pixel-identical for diff_all.sh's Kit-vs-Concept-1 baseline.
const SHEET_ENV := "KIT_SHEET"

## The ten morale glyphs, band order, for the faces row: the face font's own
## list (this is a probe under tools/, outside the lint's `game/` scope; the
## game reaches the glyphs only through Cards.morale_glyph). Not a third copy
## of the table — review W1-CHROME F5.
const FACES: Array = Fonts.FACE_GLYPHS


func build() -> void:
	for c in get_children():
		c.queue_free()
	theme = Theme_.get_theme()

	if OS.get_environment(SHEET_ENV) == "variations":
		_variations_sheet()
		return

	var f := Frame.build(self, {"nav": NAV, "active": "home", "framed": true})

	# The scene: the BARE camp plate with its living layers (the 2026-09-11
	# directive; RULES-16). The legacy mockup-crop scene this probe used to
	# mount was deleted in W2-STAGE2 (M4B-CONV-02); only bare stages exist. The stage
	# is placed exactly as Town.gd places it (CAMP_OFFSET), so the same part of
	# the camp sits under the Concept-1 chrome; the kit number was re-baselined
	# with this change (build/plan/report-W0-GATE.md).
	var stage := SceneStage.load("stage_camp")
	stage.position = CAMP_OFFSET
	stage.size = f.scene.size - CAMP_OFFSET
	f.scene.add_child(stage)

	_chips(Frame.chips(f))
	_sidebar(Frame.sidebar(f))
	_strip(f.strip)



func _chips(host: HBoxContainer) -> void:
	host.add_child(Widgets.chip("12,480", Color("E4C9AA"), load(ICON + "coin.png")))
	host.add_child(Widgets.chip("320", Color("A597F3"), load(ICON + "gem.png")))
	host.add_child(Widgets.chip("8/12", Color("A09EA0"), load(ICON + "book.png")))
	host.add_child(Widgets.chip("Day 23   16:40", Color("A5A4A7"), load(ICON + "sun.png")))


func _sidebar(host: Control) -> void:
	# 01 §2's measured column, placed explicitly. The sidebar panel is at
	# (1142, 79) with an 18px pad, so content-local = reference - (1160, 97).
	# Labels are set by CAP TOP; a Label's top sits ~4px above its cap. The
	# panel's pad is a MarginContainer, which lays its children out itself, so
	# the placed children live in a plain Control inside it.
	# PanelWarm's own content margin (14) sits under the Pad's 18: measured
	# against the concept, everything landed +14/+14. The Pad lays out its
	# direct child, so the pulled-back origin is a Control one level down.
	var free := Control.new()
	free.mouse_filter = Control.MOUSE_FILTER_PASS
	_free(host).add_child(free)
	free.position = Vector2(-14, -14)
	_at(free, Widgets.label_as("Current Raid", "LabelSection"), 16, 2)

	# Boss art card 1162,132 339x161: art well + title block.
	var card := Widgets.panel("PanelCard", 0)
	var card_free := _free(card)
	# RULES-10 (W3-KIT2): the mockup crop is deleted; the well is the kit's own
	# composition (the rank creature over a darkened arena slice), no encounter.
	var art := Cards.encounter_art(null, Vector2(337, 116))
	_at(card_free, art, 1, 1, Vector2(337, 116))
	_at(card_free, Widgets.label_as("The Sludge Maw", "LabelSubject"), 14, 108)   # cap top 245
	_at(card_free, Widgets.label_as("Aberration", "LabelMuted"), 14, 134)         # cap top 270
	_at(free, card, 2, 35, Vector2(339, 161))

	_at(free, Widgets.label_as("Potential Rewards", "LabelLabel"), 16, 212)   # cap top 313
	for i in 4:                                                              # y 335, pitch 56
		_at(free, Widgets.slot(load(ICON + "item_reward_%d.png" % i)), 15 + 56 * i, 238,
			Vector2(47, 47))

	_at(free, Widgets.callout("Estimated Success Chance", "17%", 17), 4, 295, Vector2(337, 82))

	_at(free, Widgets.label_as("Raid Team", "LabelLabelLg"), 16, 390)        # cap top 491
	for i in 4:                                                              # y 517, pitch 63
		_at(free, Widgets.slot(load(PORTRAIT + "team_%d.png" % i), Widgets.PORTRAIT_SLOT,
			"SlotBronze"), 14 + 63 * i, 420, Vector2(56, 58))
	var teambtn := Button.new()
	teambtn.text = "Team"
	teambtn.theme_type_variation = "ButtonPortrait"
	teambtn.icon = load(ICON + "cog.png")                                    # gear over the word
	teambtn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teambtn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	teambtn.expand_icon = false
	_at(free, teambtn, 266, 420, Vector2(64, 58))

	var gear := TextureRect.new()                                            # 01 §2: 1286,587 16x17
	gear.texture = load(ICON + "cog.png")
	gear.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gear.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gear.modulate = Palette.TEXT_MUTED
	_at(free, gear, 126, 490, Vector2(16, 17))
	var edit := Widgets.link("Edit Team")
	_at(free, edit, 148, 486, Vector2(100, 22))                              # centred x 1330

	_at(free, Widgets.cta("Send Them Anyway", "2,400 G"), 19, 520, Vector2(305, 70))


## A plain Control filling `container`, for children placed by position: the
## kit's containers (PanelContainer, MarginContainer) lay out whatever is put
## straight into them.
func _free(container: Control) -> Control:
	var c := Control.new()
	c.name = "Free"
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(c)
	return c


## Place `n` in `host` at a content-local position (and size, if given).
func _at(host: Control, n: Control, x: float, y: float, size: Vector2 = Vector2.ZERO) -> void:
	host.add_child(n)
	n.position = Vector2(x, y)
	if size != Vector2.ZERO:
		n.size = size
		n.custom_minimum_size = size


func _strip(host: Control) -> void:
	# "Available" mini-grid (01 §4.1).
	var avail := Widgets.panel("PanelRound", 12)
	avail.position = Vector2(0, 0)
	avail.size = Vector2(110, Widgets.STRIP_H)
	var acol := Widgets.column(8)
	acol.add_child(Widgets.label_as("Available   7", "LabelSectionSm"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	for i in 8:
		grid.add_child(Widgets.slot(load(PORTRAIT + "avail_%d.png" % i),
			Widgets.MINI_CELL, "SlotMini"))
	acol.add_child(grid)
	Widgets.content_of(avail).add_child(acol)
	host.add_child(avail)

	# Four roster cards (01 §3).
	for i in CARDS.size():
		var c: Dictionary = CARDS[i]
		var card := _roster_card(c)
		card.position = Vector2(Widgets.CARD_X0 - 13 + Widgets.CARD_PITCH * i, 0)
		card.size = Vector2(Widgets.CARD_SIZE.x, Widgets.CARD_SIZE.y)
		host.add_child(card)

	# Recent Events (01 §4.2).
	var log := Widgets.panel("PanelRound", 14)
	log.position = Vector2(1032, 0)
	log.size = Vector2(474, Widgets.STRIP_H)
	var lcol := Widgets.column(0)
	lcol.add_child(Widgets.label_as("Recent Events", "LabelSectionSm"))
	for i in EVENTS.size():
		var kind := String(EVENTS[i][2])
		lcol.add_child(Widgets.log_row(String(EVENTS[i][0]), Palette.TEXT_MUTED_WARM,
			BADGE[String(EVENTS[i][1])], Cards.badge_icon(kind), kind))
	Widgets.content_of(log).add_child(lcol)
	host.add_child(log)


# ---------------------------------------------------------------- the variations sheet

## A caption under a specimen, so the sheet reads without the source open.
func _spec(host: Control, n: Control, x: float, y: float, size: Vector2, caption: String) -> void:
	_at(host, n, x, y, size)
	var l := Widgets.label_as(caption, "LabelSmall")
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_at(host, l, x, y + size.y + 4)


func _btn(text: String, variation: String, disabled: bool = false, pressed: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.disabled = disabled
	if pressed:
		b.toggle_mode = true
		b.button_pressed = true
	b.focus_mode = Control.FOCUS_ALL
	return b


func _plate(variation: String, inner: Control = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	if inner != null:
		p.add_child(inner)
	return p


func _variations_sheet() -> void:
	var ground := ColorRect.new()
	ground.color = Palette.GROUND_FRAME
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_at(self, ground, 0, 0, Vector2(1536, 1024))
	var sheet := Control.new()
	sheet.name = "Sheet"
	sheet.mouse_filter = Control.MOUSE_FILTER_PASS
	_at(self, sheet, 0, 0, Vector2(1536, 1024))
	_at(sheet, Widgets.label_as("Kit — every variation (W1-CHROME)", "LabelSection"), 24, 12)

	# ---- row 1: the button family, normal / disabled / pressed -------------
	var y := 56.0
	var x := 24.0
	var buttons := [
		["Button", "Button", Vector2(130, 44)], ["ButtonCta", "Send Them", Vector2(190, 56)],
		["ButtonIcon", "", Vector2(46, 46)], ["ButtonPortrait", "Team", Vector2(64, 58)],
		["ButtonSlot", "Slot", Vector2(80, 47)], ["ButtonMini", "", Vector2(37, 37)],
		["ButtonQuiet", "Back to town", Vector2(130, 36)], ["ButtonNotice", "A1 — Notice", Vector2(190, 44)],
		["ButtonChip", "At risk", Vector2(90, 30)], ["NavItem", "Recruit", Vector2(130, 55)],
		["NavItemActive", "Home", Vector2(130, 55)],
	]
	for row in 3:
		x = 24.0
		for spec in buttons:
			var v: String = spec[0]
			var b := _btn(String(spec[1]), v, row == 1, row == 2)
			if v == "ButtonIcon" or v == "ButtonMini":
				b.icon = load(ICON + "cog.png")
				b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var size: Vector2 = spec[2]
			if row == 0:
				_spec(sheet, b, x, y, size, v)
			else:
				_at(sheet, b, x, y, size)
			# pitch by the caption where it is wider than the specimen (ButtonIcon is 46px, its name ~70)
			x += maxf(size.x, 7.0 * v.length()) + 14
		y += 76
	# the cost CTA and the link live bottom-left, where nothing else does
	var cost := Widgets.cta("Send Them Anyway", "2,400 G")
	_spec(sheet, cost, 24, 936, Vector2(224, 70), "ButtonCtaCost")
	var link := Widgets.link("Edit Team")
	_spec(sheet, link, 280, 958, Vector2(100, 24), "LinkButton")

	# ---- row 2: plates ----------------------------------------------------
	y = 300
	x = 24
	var plates := [
		["PanelWarm", Vector2(140, 90)], ["PanelSteel", Vector2(140, 90)], ["PanelRound", Vector2(110, 90)],
		["PanelRoundSelected", Vector2(110, 90)], ["PanelInset", Vector2(100, 90)], ["PanelCard", Vector2(100, 90)],
		["PanelChip", Vector2(100, 47)], ["PanelCallout", Vector2(140, 60)], ["PanelBubble", Vector2(140, 60)],
		["PanelEmote", Vector2(40, 44)], ["PanelCork", Vector2(130, 90)],
	]
	# A PanelContainer re-lays every Control put straight into it (LESSONS: the
	# +14/+14 drift), so anything placed INSIDE a plate goes into `_free(p)`
	# (content-local), and anything that must sit on the plate's EDGE (the
	# ornaments, the tail, the pin) goes on the sheet at the plate's coordinates.
	for spec in plates:
		var v: String = spec[0]
		var size: Vector2 = spec[1]
		var p := _plate(v)
		_spec(sheet, p, x, y, size, v)
		if v == "PanelWarm" or v == "PanelSteel":
			# the corner ornaments, overlaid as W3-KIT2's Widgets.panel will
			var orn: Texture2D = theme.get_icon("corner_ornament", v)
			var tint: Color = theme.get_color("ornament_tint", v)
			for corner in 4:
				var tr := TextureRect.new()
				tr.texture = orn
				tr.stretch_mode = TextureRect.STRETCH_KEEP
				tr.modulate = tint
				tr.flip_h = corner % 2 == 1
				tr.flip_v = corner >= 2
				tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_at(sheet, tr, x + (3.0 if corner % 2 == 0 else size.x - 19.0),
					y + (3.0 if corner < 2 else size.y - 19.0), Vector2(16, 16))
		if v == "PanelCallout":
			var tail := TextureRect.new()
			tail.texture = theme.get_icon("tail", v)
			tail.stretch_mode = TextureRect.STRETCH_KEEP
			tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_at(sheet, tail, x + size.x * 0.5 - 7, y + size.y - 2, Vector2(14, 8))
			var pf := _free(p)
			_at(pf, Widgets.label_as("Tavern", "LabelName"), 2, 0)
			_at(pf, Widgets.label_as("Recruit • Rest", "LabelSmall"), 2, 26)
		if v == "PanelBubble":
			_at(_free(p), Widgets.label_as("I think I'm ready…", "LabelSmall"), 4, 12)
		if v == "PanelEmote":
			var dots := Widgets.label_as("…", "LabelSmall")
			dots.add_theme_color_override("font_color", Palette.TEXT_ON_BUBBLE)
			_at(_free(p), dots, 2, -4)
		if v == "PanelCork":
			var paper := _plate("PanelPaper")
			_at(_free(p), paper, 5, 8, Vector2(96, 56))
			_at(_free(paper), Widgets.label_as("A1 — Notice", "LabelSmall"), 0, 22)
			var pin := TextureRect.new()
			pin.texture = theme.get_icon("pin", "PanelPaper")
			pin.stretch_mode = TextureRect.STRETCH_KEEP
			pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_at(sheet, pin, x + 12 + 5 + 42, y + 12 + 4, Vector2(12, 12))
		x += maxf(size.x, 7.0 * v.length()) + 16
	# the three success callouts with their flourish
	x = 24
	y = 430
	for spec in [["PanelCalloutDanger", "17%", 17], ["PanelCalloutCaution", "42%", 42], ["PanelCalloutPositive", "71%", 71]]:
		var c := Widgets.callout("Estimated Success Chance", String(spec[1]), int(spec[2]))
		_spec(sheet, c, x, y, Vector2(300, 82), String(spec[0]))
		var fl := TextureRect.new()
		fl.texture = theme.get_icon("flourish", String(spec[0]))
		fl.modulate = Palette.band_color(int(spec[2]))
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_at(sheet, fl, x + 300 - 22, y + 2, Vector2(18, 14))
		x += 316
	# stamps: the box is the Label's parent (CRITIC-C08); DANGER default, CAUTION re-tinted
	var stamp := _plate("PanelStamp", Widgets.label_as("FALLEN", "LabelSectionSm"))
	stamp.rotation_degrees = 4
	stamp.pivot_offset = Vector2(45, 16)
	stamp.modulate = Color(1, 1, 1, 0.85)
	_spec(sheet, stamp, 990, 436, Vector2(90, 32), "PanelStamp")
	var caution := _plate("PanelStamp", Widgets.label_as("MAY LEAVE", "LabelSectionSm"))
	var sb: StyleBoxTexture = theme.get_stylebox("panel", "PanelStamp").duplicate()
	sb.modulate_color = Palette.CAUTION
	caution.add_theme_stylebox_override("panel", sb)
	caution.rotation_degrees = -5
	caution.pivot_offset = Vector2(60, 16)
	_at(sheet, caution, 1110, 436, Vector2(120, 32))
	# damage numbers (CRITIC-C05)
	_spec(sheet, Widgets.label_as("-317", "LabelDamage"), 1260, 430, Vector2(70, 34), "LabelDamage")
	_spec(sheet, Widgets.label_as("-842", "LabelDamageCrit"), 1340, 426, Vector2(90, 40), "LabelDamageCrit")
	_spec(sheet, Widgets.label_as("+120", "LabelHeal"), 1440, 430, Vector2(70, 34), "LabelHeal")

	# ---- row 3: slots, the scrollbar, the faces ------------------------------
	y = 560
	x = 24
	for spec in [["Slot", Vector2(47, 47)], ["SlotBronze", Vector2(56, 58)], ["SlotAbility", Vector2(40, 40)],
			["SlotReady", Vector2(40, 40)], ["SlotWeapon", Vector2(62, 74)], ["PortraitFrame", Vector2(90, 94)],
			["SlotMini", Vector2(37, 37)]]:
		var v: String = spec[0]
		var size: Vector2 = spec[1]
		_spec(sheet, _plate(v), x, y, size, v)
		x += size.x + 40
	# a scrolling list with the bronze bar
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := Widgets.column(4)
	for i in 14:
		col.add_child(Widgets.label_as("Row %d of a long list" % (i + 1), "LabelBody"))
	sc.add_child(col)
	_spec(sheet, sc, 700, y, Vector2(200, 110), "VScrollBar (8px bronze)")
	# the wipe assets, regenerated (COMBAT-15)
	var blot := TextureRect.new()
	blot.texture = load("res://game/assets/ui/wipe_blot.png")
	blot.stretch_mode = TextureRect.STRETCH_KEEP
	blot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spec(sheet, blot, 920, y - 20, Vector2(320, 150), "wipe_blot")
	var seal := TextureRect.new()
	seal.texture = load("res://game/assets/ui/wax_seal.png")
	seal.stretch_mode = TextureRect.STRETCH_KEEP
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spec(sheet, seal, 1260, y, Vector2(72, 72), "wax_seal")
	var chip := Widgets.chip("12,480", Color("E4C9AA"), load(ICON + "coin.png"))
	_spec(sheet, chip, 1350, y, Vector2(150, 47), "PanelChip (Widgets.chip)")

	# the faces: the same glyphs in every variation that carries one (HALL-05)
	y = 730
	_at(sheet, Widgets.label_as("Morale glyphs — LabelMorale / LabelBody / LabelClass / LabelLog draw the face sheet; LabelSmall keeps the system emoji:", "LabelLabel"), 24, y)
	var glyphs := " ".join(FACES)
	var rows := [["LabelMorale", "Bork — 87 " + glyphs], ["LabelBody", "Body " + glyphs],
		["LabelClass", "Warrior — " + glyphs], ["LabelLog", "Log " + glyphs], ["LabelSmall", "Small " + glyphs]]
	var yy := y + 30
	for r in rows:
		var l := Widgets.label_as(String(r[1]), String(r[0]))
		_at(sheet, l, 24, yy)
		_at(sheet, Widgets.label_as(String(r[0]), "LabelSmall"), 700, yy + 4)
		yy += 34
	# the ten faces at 24px, each on its own, in LabelMorale
	var fx := 900.0
	for g in FACES:
		var l := Widgets.label_as(String(g), "LabelMorale")
		_at(sheet, l, fx, y + 30)
		fx += 40
	_at(sheet, Widgets.label_as("← faces.png through Fonts.faces(); Label.text still holds the code point", "LabelSmall"), 900, y + 66)
	# text scale: the same stamp/number at 150 for the record
	var t150 := Theme_.get_theme(150)
	var big := Widgets.label_as("-317 at 150", "LabelDamage")
	big.theme = t150
	_spec(sheet, big, 1150, 930, Vector2(200, 50), "LabelDamage @150")


## The roster card (01 §3) with canon's morale row (00 §2.1), not the
## reference's forbidden bar.
func _roster_card(c: Dictionary) -> Control:
	var card := Widgets.panel("PanelRound", 14)
	var col := Widgets.column(4)

	var top := Widgets.row(12)
	var frame := Widgets.slot(load(PORTRAIT + String(c["name"]).to_lower() + ".png"),
		90, "PortraitFrame")
	frame.custom_minimum_size = Vector2(90, 94)
	top.add_child(frame)
	var names := Widgets.column(2)
	names.add_child(Widgets.label_as(String(c["name"]), "LabelName"))
	names.add_child(Widgets.label_as("Lv. %d" % int(c["level"]), "LabelLevel"))
	names.add_child(Widgets.label_as(String(c["cls"]), "LabelClass"))
	top.add_child(names)
	col.add_child(top)

	# Canon's two-line morale row: "Name — 87 ❤" then "Class — Very Happy".
	var morale := int(c["morale"])
	var band_names := ["Very Upset", "Upset", "Unhappy", "Annoyed", "Slightly Annoyed",
		"Content", "Happy", "Quite Happy", "Very Happy", "Loves Their Guild"]
	var faces := ["🤬", "😡", "😞", "😒", "😐", "🙂", "😄", "😊", "❤", "💖"]
	var band: int = mini(9, morale / 10)
	var mrow := Widgets.label_as("%s — %d %s" % [String(c["name"]), morale, faces[band]], "LabelMorale")
	mrow.add_theme_color_override("font_color", Palette.morale_color(morale))
	col.add_child(mrow)
	var srow := Widgets.label_as("%s — %s" % [String(c["cls"]), band_names[band]], "LabelClass")
	col.add_child(srow)

	var q := Widgets.label_as(String(c["quote"]), "LabelQuote")
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(q)

	var slots := Widgets.row(9)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		slots.add_child(Widgets.slot(load(ICON + "item_gear_%d.png" % i)))
	col.add_child(slots)

	Widgets.content_of(card).add_child(col)
	return card
