extends RefCounted
## The composites that carry real roster data: the card, the bottom strip that
## pages them, and the event log.
##
## art/ref/specs/01 §3 measured the card (215x262, pitch 224, four across) and
## §4.2 the log. `10-screen-audit.md` §2 R1 owns the count problem: the
## reference shows exactly four cards, canon fields twelve and a roster can hold
## twenty, so the strip is a PAGER — the card size and pitch never change, the
## page does.
##
## The morale row is canon's, not the reference's (00 §2.1): two lines,
## `Name — 87 ❤` then `Class — Very Happy`, the number never smaller than the
## name, no bar. Everything the tests read stays in a Label or a Button.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Type = preload("res://game/ui/Type.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Fonts = preload("res://game/ui/Fonts.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Services = preload("res://game/core/Services.gd")

const PORTRAIT := "res://game/assets/portraits/"
const ICON := "res://game/assets/ui/icons/"
const ENEMIES := "res://game/assets/enemies/"
const PAGE := 4                       ## cards visible at once (01 §3)
const CARD_PAD := 14                  ## the card's PanelRound pad (01 §3)
## W5-KIT3: a card that carries an action band closes its column to this gap
## (4 without one) and, when the band holds a shut button's reason, its bottom
## pad to `CARD_PAD_REASONED`, so the band sits INSIDE the 262 (the arithmetic
## is in `card`'s comment; test_kit3 re-adds it from the theme's own heights).
const CARD_GAP := 4
const CARD_GAP_BANDED := 2
const CARD_PAD_REASONED := 7
## The band line's two-line ceiling ("Shaman — Slightly Annoyed" at 125% and
## up): never more, never an ellipsis inside the state word.
const BAND_LINES := 2
## The card's portrait row: the gap between the bust and the names column,
## and the gap between the class glyph and the class word (KIT-19), at 100%.
const CARD_TOP_GAP := 12
const CLASS_GLYPH_GAP := 4
## UI-31's third rung: the px the names column may take from those two gaps
## (8 from the row's, 2 from the glyph's) when the class word fits no other
## way at 150 — the bust keeps its integer 2x rather than shrinking.
const CLASS_ROW_GIVE := 10
const EVENT_HEAD_H := 36              ## the log's head row with the reasoned "View All" under the title
## The rows the event log can show under its head inside the 262 strip
## (W5-KIT3): (262 - 28 pad - 36 head - 1 rule) / 29 = 6. The Town's sidebar
## counts "N recent events on the log" against this, not a number of its own.
const ROWS: int = (Widgets.STRIP_H - 2 * CARD_PAD - EVENT_HEAD_H - 1) / Widgets.LOG_ROW_PITCH
## Where "View All" goes (KIT-21): the Guildhall's Records tab, pressed by its
## Button text — the test contract's own door, so a rename there is a red test
## and not a silent no-op here.
const GUILDHALL_SCENE := "res://game/screens/Guildhall.tscn"
const RECORDS_TAB_TEXT := "Records"
## The event log's link (LOOP-15): it opens the Records tab, so it says so —
## "View All" promised a full feed the panel does not have.
const RECORDS_LINK_TEXT := "Records"
## TOWN-23's day-one line, when the feed is empty on the guild's first day.
const DAY_ONE_EMPTY := "Day 1. Nothing yet — the board is up the road."
const EMPTY_TEXT := "Nothing has happened yet."
## The empty log's second line, the hub's — and every framed screen's (UI-12):
## `event_log` used to take it per screen and only the Town passed one, so
## the Market and the Tavern read a different empty state for the same panel.
## A screen overrides it only with a better line.
const HUB_HINT := "Raids and rests write here."
## The most morale sentences the feed prints for one day (UI-51). A twelve-
## raider clear is one sentence, not twelve tags; the raid's own line stays
## first and a second note (a wipe's culprit, a benching) keeps its row.
const MORALE_ROWS_PER_DAY := 2


## THE ONLY PLACE A MORALE GLYPH IS CHOSEN (docs/13 §13, emoji-free row).
##
## `GameSettings.morale_glyph` has always implemented the substitution — "Replaces
## morale glyphs with a 10-step monochrome pip figure. The integer and state word
## are unaffected" — but eight of the nine display sites reached past it straight
## to `Enums.MORALE_BAND_EMOJI`, so turning the option on changed one panel out of
## eight. Every site now funnels through here, which is what stops a tenth site
## forgetting: there is nothing left to forget.
##
## Static and node-taking because Cards is a RefCounted with no autoload access of
## its own; `who` may be null (a card is built before it is parented) because
## `Services.find` falls back to the SceneTree root. Null-tolerant on the setting
## itself for the same reason RaiderDetail was: the unit tests build widgets with
## no GameSettings registered, and a missing option must never mean a missing glyph.
static func morale_glyph(who: Node, morale: int) -> String:
	var settings: Node = Services.find(who, "GameSettings")
	if settings != null and settings.has_method("morale_glyph"):
		return String(settings.morale_glyph(morale))
	return Enums.MORALE_BAND_EMOJI[Enums.morale_band(morale)]


## Portrait for a raider, in three passes: the reference face named after them,
## then the authored class bust, then the reference bust whose class matches.
## Never a wrong-class face.
static func portrait_for(raider) -> Texture2D:
	var by_name := PORTRAIT + String(raider.display_name).to_lower() + ".png"
	if ResourceLoader.exists(by_name):
		return load(by_name)
	# A hand-authored class bust wins when one exists.
	var by_class := PORTRAIT + "class_" + Enums.class_key(raider.class_id) + ".png"
	if ResourceLoader.exists(by_class):
		return load(by_class)
	# The reference supplies four busts and names the class each depicts
	# (00 §2.2: its "Ranger" is canon's Rogue), so warrior/rogue/cleric/mage
	# borrow them. The other five — monk, druid, shaman, bard, wizard — have
	# their own class_*.png and are answered above, so no canon class reaches
	# the blank below. The blank stays for a class with neither: an honest empty
	# frame beats a wrong-class face or an upscaled smear (the first generated
	# set was rejected for exactly that; see art/export/portraits_rejected).
	var borrowed: String = REFERENCE_BUST_FOR_CLASS.get(Enums.class_key(raider.class_id), "")
	if not borrowed.is_empty() and ResourceLoader.exists(PORTRAIT + borrowed + ".png"):
		return load(PORTRAIT + borrowed + ".png")
	return null

const REFERENCE_BUST_FOR_CLASS := {
	"warrior": "bork", "rogue": "tiny", "cleric": "gruk", "mage": "spoof",
}


## One roster card, 215x262 (01 §3). `action` is an optional
## {"text": String, "on": Callable} that becomes a button along the card's
## bottom edge — Raid prep uses it for Bench/Chalk. `actions` (KIT-06, HALL-03,
## CRITIC-C15) is the roster's pair: each {"text", "on", "reason"} becomes a
## `button_with_reason` box in a band INSIDE the card's rim — the first
## expanding, the rest shrinking — so nothing hangs under the border and the
## reason stays the faint Label under its own button ("They are fine." is read
## there by test_raider_detail). The Button keeps the name "Button" so
## `Widgets.button_of` finds "Cheer up". The docs/13 OQ-4 beneath-the-card
## reading is reversed by W3-ROSTER in the same commit it adopts this.
##
## W5-KIT3 — THE 262 WITH A BAND. At 100% the card's rows are the portrait
## row 94, the morale line 25, the band line 24 and the slots 47 (190), its pad
## 28: with four 4px gaps a band has 28px, and a band is a 13px-label button
## (29 on `ButtonCardAction`'s plate; 33 on the secondary's) over, when shut,
## its reason. So a card WITH a band closes its gaps to `CARD_GAP_BANDED` (36
## for the band: a bare action fits) and a band that carries a reason takes
## the reason at `Type.STACK` under its button at separation 0 (14 more) and
## the bottom pad down to `CARD_PAD_REASONED` (7): 14+94+2+25+2+24+2+47+2+29+
## 14+7 = 262. `Roster._fit_band` does the same tightening and is a no-op on
## this card. Every card without a band is unchanged, byte for byte.
static func card(raider, db = null, action: Dictionary = {}, actions: Array = []) -> Control:
	var c := Widgets.panel("PanelRound", CARD_PAD)
	c.custom_minimum_size = Vector2(Widgets.CARD_SIZE.x, Widgets.CARD_SIZE.y)
	var banded: bool = not action.is_empty() or not actions.is_empty()
	var col := Widgets.column(CARD_GAP_BANDED if banded else CARD_GAP)

	var top := Widgets.row(CARD_TOP_GAP)
	var frame := Widgets.slot(portrait_for(raider), 90, "PortraitFrame")
	frame.custom_minimum_size = Vector2(90, 94)
	top.add_child(frame)
	var names := Widgets.column(2)
	# The column takes the width the portrait leaves (85px at 100%), so the
	# trimmed class row below knows how much it has; it never shrinks under a
	# long name's own minimum.
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(Widgets.label_as(String(raider.display_name), "LabelName"))
	# 00 §2.3: this game has no levels in canon's recruitment model, so the
	# line only appears when something has actually set one.
	if int(raider.level) > 0:
		names.add_child(Widgets.label_as("Lv. %d" % int(raider.level), "LabelLevel"))
	# KIT-19: the class word carries its 16px glyph (W1-ICONS' `class_<key>`
	# through Icons.at — Concept 1's "⚔ Warrior") in a row named "ClassRow";
	# the Label's text stays the bare class name the tests read.
	var class_row := Widgets.row(CLASS_GLYPH_GAP)
	class_row.name = "ClassRow"
	var glyph := class_glyph(raider)
	if glyph != null:
		var g := TextureRect.new()
		g.name = "ClassGlyph"
		g.texture = glyph
		g.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		class_row.add_child(g)
	var class_label := Widgets.label_as(Enums.class_name_of(raider.class_id), "LabelClass")
	class_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	class_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# At 150% "Shaman" beside its glyph ran under the card's rim ("Shamar" in
	# W3KIT2_Guildhall_t150_cards.png); it trims inside the names column instead.
	class_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	class_row.add_child(class_label)
	names.add_child(class_row)
	top.add_child(names)
	# UI-31 (W7-STAGE): the class word is never cut ("Shama" / "Warri" at
	# 125/150 — docs/13 §4.4). The same ladder as the band line, on the width
	# the names column has at the card's shipped 215 (the 262 cell has more):
	# the variation's size, then CLASS-2 on the plain face, then the third
	# rung — `CLASS_ROW_GIVE` more px from the two gutters beside the word.
	var glyph_w: float = 0.0 if glyph == null else float(glyph.get_width()) + CLASS_GLYPH_GAP
	var names_w: float = float(Widgets.CARD_SIZE.x - 2 * CARD_PAD) - frame.custom_minimum_size.x - CARD_TOP_GAP
	if fit_class_word(class_label, names_w - glyph_w, CLASS_ROW_GIVE) == 3:
		top.add_theme_constant_override("separation", CARD_TOP_GAP - CLASS_ROW_GIVE + CLASS_GLYPH_GAP / 2)
		class_row.add_theme_constant_override("separation", CLASS_GLYPH_GAP / 2)
	col.add_child(top)

	# Canon's morale contract (docs/05 §10.1, docs/13 §8.1).
	var m: int = int(raider.morale)
	var line1 := Widgets.label_as("%s — %d %s"
		% [String(raider.display_name), m, morale_glyph(null, m)], "LabelMorale")
	line1.add_theme_color_override("font_color", Palette.morale_color(m))
	col.add_child(line1)
	var band_line := Widgets.label_as("%s — %s"
		% [Enums.class_name_of(raider.class_id), Enums.morale_band_name(m)],
		"LabelClass")
	# At text_scale 150 "Warrior — Quite Happy" ran off the 215px card
	# (handoff-W2-RESULTS); the ellipsis is the last guard, and after
	# `fit_band_line` it is never reached: the line is FITTED to the width the
	# card ships at (W5-KIT3).
	band_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fit_band_line(band_line, float(Widgets.CARD_SIZE.x - 2 * CARD_PAD))
	col.add_child(band_line)

	# The quote line shows real text only (10 §2 R10): the most recent morale
	# note, else (TOWN-29) the raider's first backstory bullet — Concept 3's
	# cards carry a line under the morale row from day one. Two lines at most,
	# trimmed with an ellipsis, so a long bullet never grows the card past its
	# 262; and only on a card with no action band, where the 262 has no room
	# for both (Raid prep's Bench card keeps its old shape).
	var note := _last_note(raider)
	if note.is_empty() and action.is_empty() and actions.is_empty():
		note = _first_bullet(raider)
	if not note.is_empty():
		var q := Widgets.label_as(note, "LabelQuote")
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.max_lines_visible = 2
		q.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(q)

	var slots := Widgets.row(9)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	var shown := 0
	if db != null:
		for it in raider.equipped_items(db):
			if shown >= 3:
				break
			# The slot's own picture (gear_icon), not the n-th icon in a row.
			var cell := Widgets.slot(gear_icon(int(it.slot), true, it))
			# KIT-22: the two-line tooltip — the item over its slot — and
			# `tooltip_text` kept as "slot — item" for anything that reads it.
			Widgets.tooltip_for(cell, String(it.name), Enums.slot_name_of(int(it.slot)))
			cell.tooltip_text = "%s — %s" % [Enums.slot_name_of(int(it.slot)), String(it.name)]
			slots.add_child(cell)
			shown += 1
	while shown < 3:
		slots.add_child(Widgets.slot())
		shown += 1
	col.add_child(slots)

	if not action.is_empty():
		var b := Widgets.button(String(action.get("text", "")))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if action.has("on"):
			b.pressed.connect(action["on"])
		col.add_child(b)

	if not actions.is_empty():
		var band := Widgets.row(6)
		band.name = "Actions"
		band.alignment = BoxContainer.ALIGNMENT_BEGIN
		var first := true
		var reasoned := false
		for a in actions:
			if not (a is Dictionary):
				continue
			var box := Widgets.button_with_reason(String(a.get("text", "")), String(a.get("reason", "")))
			var ab := Widgets.button_of(box)
			# The card's own plate (W5-KIT3): the secondary chrome at the SMALL
			# size with 6px top/bottom margins, 29 tall at 100% — sized to its
			# label, which is what lets the band fit the 262.
			ab.theme_type_variation = "ButtonCardAction"
			if a.has("on") and (a["on"] as Callable).is_valid():
				ab.pressed.connect(a["on"])
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL if first else Control.SIZE_SHRINK_BEGIN
			box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			# A shut button's reason: the caption size (Type.STACK, the
			# Guildhall's tab captions) flush under its button, so the reason
			# costs the band 14 and not 19.
			for why in box.get_children():
				if why is Label:
					reasoned = true
					(why as Label).add_theme_font_size_override("font_size",
						Type.at(Type.STACK, Theme_.scale_of(why)))
					box.add_theme_constant_override("separation", 0)
			band.add_child(box)
			first = false
		col.add_child(band)
		if reasoned:
			Widgets.content_of(c).add_theme_constant_override("margin_bottom", CARD_PAD_REASONED)

	Widgets.content_of(c).add_child(col)
	return c


## Fit a card's "Class — State" line to `width`, the inner width the card
## ships at (W5-KIT3; docs/13 §8.1 never abbreviates a state word, §4.4 never
## truncates a class name or a state word at any scale). Three rungs, the
## first that fits wins: the variation's own size; `Type.CLASS - 2` at the
## player's scale (13 at 100%, where "Shaman — Slightly Annoyed" and "Shaman —
## Loves Their Guild" are the only two of the ninety lines wider than 187),
## bottom-aligned in the variation's own line height so the card's rows and
## the baseline do not move; else the line wraps to `BAND_LINES` at that size
## and reserves their height (a wrapping Label's own minimum is measured at
## the width it has, which is none before layout). The ellipsis the Label
## carries is never reached: every rung is measured with the font the Label
## draws with. Returns the lines reserved.
##
## THE SMALLER RUNGS SHAPE FROM THE PLAIN FIRA FACE (`Fonts.ui()`), NOT THE
## VARIATION'S. Measured on the Guildhall at 125% (build/plan/report-W5-KIT3.md,
## the two experiment shots): a Label drawing `LabelClass`'s `with_pips` font
## (the pip bar in front, the 30px face sheet behind) at a size the variation
## was not built for — 16 where the theme built it at 19 — corrupted the 16px
## glyph rasters of Fira Sans Regular for EVERY Label on the screen (the
## sidebar's LabelSmall included: glyphs drawn ~1.25x their advance, letters
## overlapping), while the advances measured correct headless. Shaping the
## smaller rungs from the plain face (identical letters; no sheet, so a 20px
## line where the sheet makes 30) rendered clean. Rule: a `with_pips`
## variation is drawn at the size it was built for and no other.
static func fit_band_line(l: Label, width: float) -> int:
	var fs: Array = Widgets.font_of(String(l.theme_type_variation), l)
	var font: Font = fs[0]
	var size: int = int(fs[1])
	if font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
		return 1
	var own_h: float = font.get_height(size)
	var small: int = Type.at(Type.CLASS - 2, Theme_.scale_of(l))
	font = Fonts.ui()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", small)
	if font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x <= width:
		# The variation's line, the smaller text on its baseline: the plain
		# face's descent is the sheet's less a pixel, so bottom-aligned the
		# baseline lands where the neighbouring cards' lines put theirs.
		l.custom_minimum_size = Vector2(0, ceilf(own_h))
		l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		return 1
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.max_lines_visible = BAND_LINES
	var tp := TextParagraph.new()
	tp.width = width
	tp.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	tp.add_string(l.text, font, small)
	var lines: int = clampi(tp.get_line_count(), 1, BAND_LINES)
	var spacing: float = float(l.get_theme_constant("line_spacing"))
	l.custom_minimum_size = Vector2(0, ceilf(font.get_height(small) * float(lines) + spacing * float(lines - 1)))
	return lines


## Fit the card's class WORD to `width` (UI-31, docs/13 §4.4: a class name
## is never cut at any scale) — `fit_band_line`'s ladder without its wrap: the
## variation's own size (1); `Type.CLASS - 2` at the player's scale on the
## plain face, bottom-aligned in the variation's own line (2); and, when even
## that is wider, the same small size with the caller's `extra` px added to
## the column (3) — the caller gives the px. Returns the rung taken; the
## ellipsis the Label carries is the last guard and is not reached on any
## canon class name at 100/125/150 (test_kit3).
static func fit_class_word(l: Label, width: float, extra: float) -> int:
	var fs: Array = Widgets.font_of(String(l.theme_type_variation), l)
	var font: Font = fs[0]
	var size: int = int(fs[1])
	if font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
		return 1
	var own_h: float = font.get_height(size)
	var small: int = Type.at(Type.CLASS - 2, Theme_.scale_of(l))
	font = Fonts.ui()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", small)
	l.custom_minimum_size = Vector2(0, ceilf(own_h))
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	if font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x <= width:
		return 2
	return 3


static func _last_note(raider) -> String:
	var log: Array = raider.morale_log
	for i in range(log.size() - 1, -1, -1):
		var e = log[i]
		if e is Dictionary and not String(e.get("note", "")).is_empty():
			return String(e["note"])
	return ""


## The raider's first backstory bullet's text, or "" (a stub without the field,
## a raider without a story). Bullets are {text} dictionaries (docs/03) and,
## in older fixtures, bare strings — both are read.
static func _first_bullet(raider) -> String:
	var bullets = raider.get("backstory")
	if not (bullets is Array) or (bullets as Array).is_empty():
		return ""
	var b = bullets[0]
	if b is Dictionary:
		return String((b as Dictionary).get("text", ""))
	return String(b)


## The 16px class glyph for a raider (KIT-19; W1-ICONS' `class` role, the
## warrior's answered by `Icons.WARRIOR_GLYPH` — Q18), or null for a class the
## grid has not drawn: the word beside it is still the class.
static func class_glyph(raider) -> Texture2D:
	if raider == null:
		return null
	var key := String(Enums.class_key(int(raider.class_id)))
	if key.is_empty() or not Icons.exists("class", key):
		return null
	return Icons.at("class", key)


## KIT-15's door for a price on a card or a row: "1,240 G", through `Type.gold`.
static func price_text(gold: int) -> String:
	return Type.gold(gold)


## The bottom strip: an "Available" mini-grid then one page of cards
## (10 §2 R1). Returns the number of pages so a caller can add arrows.
##
## PAGING LIVES HERE (KIT-12, CRITIC-C11, TOWN-16, COMBAT-19): with more than
## one page the strip draws its own ◄ ► — focusable Buttons named `PagerPrev` /
## `PagerNext` in spec 10 §2 R1's gutters (screen x 131 and 1035, the 8px
## between the Available panel and card 1, and between card 4 and the log) and
## a "n/m" LabelSmall under the right gutter — so no pager ever shares pixels
## with a card and a hub screen pages with no code of its own. A press rebuilds
## the strip in place at the new page; `page` is the caller's opening page and
## still wins on every call (a screen that keeps its own `_page` passes
## `"on_page": Callable(int)` in `opts` to stay in step). The strip's current
## page is also `host`'s child "RosterStrip" meta `roster_page`. Everything the
## strip draws lives under that one plain Control, so a rebuild keeps tree
## order — and `Frame.focus_order`'s strip region — stable.
static func roster_strip(host: Control, state, page: int = 0,
		opts: Dictionary = {}) -> int:
	# `opts`: cards (Array of raiders, default the whole roster), available
	# (Array shown in the mini-grid, default the same), card_action and
	# grid_action (Callable(raider)), available_label, seats, card_builder,
	# card_action_text, on_page.
	var roster: Array = opts.get("cards", state.roster)
	var pages: int = maxi(1, int(ceil(float(roster.size()) / float(PAGE))))
	page = clampi(page, 0, pages - 1)
	var wrap := Control.new()
	wrap.name = "RosterStrip"
	wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	host.add_child(wrap)
	wrap.position = Vector2.ZERO
	wrap.size = Vector2(PAGER_NEXT_X + PAGER_W, Widgets.STRIP_H)
	_fill_strip(wrap, state, page, opts)
	return pages


## Strip-local x of the two gutter arrows (spec 10 §2 R1: screen 131 / 1035 on
## a strip host at x=13-14; the Available panel ends at 110, card 1 starts at
## 127, card 4 ends at 1014, the log starts at 1032).
const PAGER_PREV_X := 111
const PAGER_NEXT_X := 1015
const PAGER_W := 16
const PAGER_H := 44


static func _fill_strip(wrap: Control, state, page: int, opts: Dictionary) -> void:
	var roster: Array = opts.get("cards", state.roster)
	var available: Array = opts.get("available", roster)
	var pages: int = maxi(1, int(ceil(float(roster.size()) / float(PAGE))))
	page = clampi(page, 0, pages - 1)
	wrap.set_meta("roster_page", page)
	var host := wrap

	# "Available" mini-grid (01 §4.1) — who is not on tonight's list.
	var avail := Widgets.panel("PanelRound", 12)
	host.add_child(avail)
	avail.position = Vector2.ZERO
	avail.size = Vector2(110, Widgets.STRIP_H)
	var acol := Widgets.column(8)
	acol.add_child(Widgets.label_as("%s   %d"
		% [String(opts.get("available_label", "Available")), available.size()],
		"LabelSectionSm"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	var grid_action = opts.get("grid_action", null)
	# `seats` pads the grid with empty cells up to a fixed count — the Tavern's
	# board has N seats whether or not anyone is sitting in them (docs/04 §3.1).
	var seats: int = int(opts.get("seats", 0))
	for i in mini(8, maxi(seats, available.size())):
		if i >= available.size():
			grid.add_child(Widgets.slot(null, Widgets.MINI_CELL, "SlotMini"))
			continue
		var who = available[i]
		if grid_action == null:
			grid.add_child(Widgets.slot(portrait_for(who),
				Widgets.MINI_CELL, "SlotMini"))
		else:
			# A tile the player can press must stay a Button, and its text is
			# the raider's name so the test walker can still read the bench.
			# The face is a child TextureRect, not Button.icon: the (invisible)
			# name still claims its width beside an icon, which shrank the
			# face to a few pixels.
			var t := Widgets.slot_button(String(who.display_name), null, Widgets.MINI_CELL)
			t.theme_type_variation = "ButtonMini"
			t.clip_text = true
			t.add_theme_color_override("font_color", Color(0, 0, 0, 0))
			var face := TextureRect.new()
			face.texture = portrait_for(who)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			face.mouse_filter = Control.MOUSE_FILTER_IGNORE
			face.set_anchors_preset(Control.PRESET_FULL_RECT)
			face.offset_left = 2
			face.offset_top = 2
			face.offset_right = -2
			face.offset_bottom = -2
			t.add_child(face)
			t.tooltip_text = "%s — %d %s" % [who.display_name, who.morale,
				Enums.morale_band_name(who.morale)]
			t.pressed.connect(grid_action.bind(who))
			grid.add_child(t)
	acol.add_child(grid)
	Widgets.content_of(avail).add_child(acol)

	var db = state.content if state.get("content") != null else null
	var card_action = opts.get("card_action", null)
	for i in PAGE:
		var idx: int = page * PAGE + i
		if idx >= roster.size():
			break
		var act: Dictionary = {}
		if card_action != null:
			act = {"text": String(opts.get("card_action_text", "Bench")),
				"on": card_action.bind(roster[idx])}
		# `card_builder` lets a screen supply its own card composite while the
		# strip still owns the paging and placement (the Tavern's candidate card).
		var c: Control
		if opts.has("card_builder"):
			c = (opts["card_builder"] as Callable).call(roster[idx], idx)
		else:
			c = card(roster[idx], db, act)
		host.add_child(c)
		c.position = Vector2(Widgets.CARD_X0 - 13 + Widgets.CARD_PITCH * i, 0)
		c.size = Vector2(Widgets.CARD_SIZE.x, Widgets.CARD_SIZE.y)

	if pages > 1:
		_strip_pager(wrap, state, page, pages, opts)


## The gutter arrows and the page caption. Both arrows are FOCUS_ALL Buttons
## inside the strip host, so `Frame.focus_order` collects them into the strip
## region and a11y_smoke's Tab ring closes through them.
static func _strip_pager(wrap: Control, state, page: int, pages: int, opts: Dictionary) -> void:
	var y := float(Widgets.STRIP_H - PAGER_H) * 0.5
	var prev := Widgets.pager_button(false)
	prev.name = "PagerPrev"
	prev.expand_icon = true
	prev.custom_minimum_size = Vector2(PAGER_W, PAGER_H)
	wrap.add_child(prev)
	prev.position = Vector2(PAGER_PREV_X, y)
	prev.size = Vector2(PAGER_W, PAGER_H)
	prev.pressed.connect(func() -> void:
		_turn_page(wrap, state, opts, (page - 1 + pages) % pages, false))
	var next := Widgets.pager_button(true)
	next.name = "PagerNext"
	next.expand_icon = true
	next.custom_minimum_size = Vector2(PAGER_W, PAGER_H)
	wrap.add_child(next)
	next.position = Vector2(PAGER_NEXT_X, y)
	next.size = Vector2(PAGER_W, PAGER_H)
	next.pressed.connect(func() -> void:
		_turn_page(wrap, state, opts, (page + 1) % pages, true))
	# "n/m" under the right gutter, in the 28px band the strip leaves below the
	# cards (STRIP_Y + STRIP_H = 996 of 1024): never over a card, never over the log.
	var cap := Widgets.label_as("%d/%d" % [page + 1, pages], "LabelSmall")
	cap.name = "PageCaption"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(cap)
	cap.position = Vector2(PAGER_NEXT_X + PAGER_W * 0.5 - 24, Widgets.STRIP_H + 4)
	cap.size = Vector2(48, 18)


## The meta key Frame.gd leaves on a screen built on the shell (its
## `META_FOCUS_ORDER`: a Callable that re-runs `Frame.focus_order`, idempotent),
## mirrored as a literal the way ScreenRouter mirrors it — Cards must not
## preload Frame.
const SCREEN_FOCUS_META := "frame_focus_order"


## Rebuild the strip at `new_page`. The pressed arrow is among what goes, so it
## is detached first and freed later (LESSONS: never free a node inside its own
## signal handler); keyboard focus, if it was on the arrow, moves to the same
## arrow of the new page so the ring is not dropped on the floor.
##
## The rebuilt arrows are NEW nodes with no Tab/arrow paths (review-W1-KIT M2:
## the router wires the ring once, at entry), so the screen's own focus wiring
## is re-run here — the shell's Callable, found on the nearest ancestor that
## carries it — before focus is handed to the new arrow. A strip on a screen
## without the shell has no Callable and keeps Godot's geometric search.
static func _turn_page(wrap: Control, state, opts: Dictionary, new_page: int, next: bool) -> void:
	var had_focus := false
	var vp := wrap.get_viewport()
	if vp != null:
		var owner := vp.gui_get_focus_owner()
		had_focus = owner != null and wrap.is_ancestor_of(owner)
	for c in wrap.get_children():
		wrap.remove_child(c)
		c.queue_free()
	_fill_strip(wrap, state, new_page, opts)
	if opts.has("on_page") and (opts["on_page"] as Callable).is_valid():
		(opts["on_page"] as Callable).call(new_page)
	_rewire_focus(wrap)
	if had_focus:
		var again := wrap.get_node_or_null("PagerNext" if next else "PagerPrev")
		if again != null and (again as Control).is_inside_tree():
			(again as Control).grab_focus()


## Re-run the focus wiring of the screen `node` sits on, if it has one. Returns
## true when a Callable was found and called.
static func _rewire_focus(node: Node) -> bool:
	var n: Node = node
	while n != null:
		if n.has_meta(SCREEN_FOCUS_META):
			var cb = n.get_meta(SCREEN_FOCUS_META)
			if cb is Callable and (cb as Callable).is_valid():
				(cb as Callable).call()
				return true
			return false
		n = n.get_parent()
	return false


## The page the strip under `host` is showing (its "RosterStrip" child's
## memory), or 0 when there is none.
static func strip_page(host: Control) -> int:
	var wrap := host.get_node_or_null("RosterStrip") if host != null else null
	if wrap == null or not wrap.has_meta("roster_page"):
		return 0
	return int(wrap.get_meta("roster_page"))


## "Recent Events" (01 §4.2). The rows are `GameState.event_feed` (TOWN-23:
## hires, sales, purchases, upgrades, raid results, rests — the guild's own
## verbs, in the game's own words) and, older or beside them, the most recent
## morale-log notes across the roster. Never invented text.
##
## KIT-21 / TOWN-23: the head row carries spec 03 §8's "View All" link at the
## panel's right. It opens the Guildhall's Records tab — on the Guildhall
## itself by pressing the "Records" tab Button, elsewhere by pushing the
## Guildhall and then pressing it — and is disabled with its reason (the
## `reasoned` treatment, "Opens at Known.") while docs/03 §7's gate holds or
## nothing can route. `hint` is the empty state's second line — the hub's
## `HUB_HINT` unless a screen passes a better one (UI-12); `glyph` its
## picture, W1-ICONS' quill unless a screen passes its own (KIT-08). On the
## guild's first day with an empty feed the empty state is TOWN-23's "Day 1.
## Nothing yet — the board is up the road."; after that, "Nothing has
## happened yet."
## The head grew a line, so the rows are capped to what still fits the 262
## (`ROWS`, six) and the panel clips — a seventh row never pokes below the
## strip, whatever `rows` asks for.
static func event_log(host: Control, state, rows: int = ROWS, hint: String = HUB_HINT,
		glyph: Texture2D = null) -> void:
	var log := Widgets.panel("PanelRound", 14)
	host.add_child(log)
	log.position = Vector2(1032, 0)
	log.size = Vector2(474, Widgets.STRIP_H)
	log.clip_contents = true

	var col := Widgets.column(0)
	var head := Widgets.row(8)
	var title := Widgets.label_as("Recent Events", "LabelSectionSm")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var link := Widgets.link(RECORDS_LINK_TEXT, true)
	var why := view_all_reason(state)
	if why.is_empty():
		link.pressed.connect(func() -> void: open_records(log))
	var view_all := Widgets.reasoned(link, why)
	view_all.name = "ViewAll"
	view_all.size_flags_horizontal = Control.SIZE_SHRINK_END
	for c in view_all.get_children():
		if c is Control:
			(c as Control).size_flags_horizontal = Control.SIZE_SHRINK_END
		if c is Label:
			(c as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(view_all)
	col.add_child(head)
	col.add_child(Widgets.rule())

	# W5-SCALE: the rows that fit at the player's text scale, not ROWS (the
	# 100% count) — six 36px rows overran the 262 by 12 at 150, measured.
	var fit: int = int((Widgets.STRIP_H - 2 * CARD_PAD - EVENT_HEAD_H - 1)
		/ Type.at(Widgets.LOG_ROW_PITCH, Theme_.scale_of(host)))
	var events := recent_events(state, mini(rows, fit))
	if events.is_empty():
		var picture: Texture2D = glyph
		if picture == null and Icons.exists("empty", "quill"):
			picture = Icons.at("empty", "quill")
		col.add_child(Widgets.empty_state(empty_text(state), picture, hint))
	for e in events:
		# The badge sprite, not a bare disc: docs/13 §13's first row is Blocking
		# and the row's tone was the only thing saying whether a day went well.
		# The feed's kinds resolve through the icon grid (`log_row`'s `kind`);
		# `badge_icon` answers the morale pair and the record states.
		var kind := String(e["kind"])
		col.add_child(Widgets.log_row(String(e["text"]), Palette.TEXT_MUTED_WARM,
			Color(e["tone"]), badge_icon(kind), kind))
	Widgets.content_of(log).add_child(col)


## The empty log's sentence: TOWN-23's day-one line on a fresh guild, else
## the plain one. A state without a day (a test stub) reads as not day one.
static func empty_text(state) -> String:
	if state != null and state.get("day") != null and int(state.get("day")) <= 1:
		return DAY_ONE_EMPTY
	return EMPTY_TEXT


## Why "View All" is shut, or "" when it can open the Records tab: docs/03 §7
## puts the board in the Town-unlock column at Known (the Guildhall's own gate,
## `Guildhall._tab_reason`), and a state without a rank (a test stub) or a
## project without the Guildhall scene cannot route.
static func view_all_reason(state) -> String:
	if state == null or state.get("reputation_rank") == null:
		return "Opens at Known."
	if not ResourceLoader.exists(GUILDHALL_SCENE):
		return "Not built in this version yet."
	if int(state.get("reputation_rank")) < Enums.ReputationRank.KNOWN:
		return "Opens at Known."
	return ""


## "View All" → the Records tab (KIT-21). On the Guildhall the "Records" tab
## Button is pressed where it stands; from any other screen the Guildhall is
## pushed first and the tab pressed on the screen that arrives. A screen with
## no such Button (a rename, a stub) is left as it is — the link routed, the
## tab did not open, and the test contract on "Records" is what catches it.
static func open_records(from: Node) -> bool:
	var router: Node = Services.router(from)
	if router == null:
		return false
	var here: Control = router.current_screen() if router.has_method("current_screen") else null
	if here != null and _press_tab(here, RECORDS_TAB_TEXT):
		return true
	if not router.has_method("push") or not bool(router.push(GUILDHALL_SCENE)):
		return false
	var there: Control = router.current_screen() if router.has_method("current_screen") else null
	return there != null and _press_tab(there, RECORDS_TAB_TEXT)


## Press the first ENABLED Button with exactly `text` under `n`, the way the
## screen tests do. False when there is none.
static func _press_tab(n: Node, text: String) -> bool:
	if n is Button and (n as Button).text == text:
		if (n as Button).disabled:
			return false
		(n as Button).pressed.emit()
		return true
	for c in n.get_children():
		if _press_tab(c, text):
			return true
	return false


## The event badge for a row kind, or null for the plain disc.
##
## KIT-07 / HALL-20 (W3-KIT2): the badges are the icon grid's (W1-ICONS,
## gen_icons.lua — crisp 22px sprites; the badge_N mockup crops that used to
## answer here are blurry at 18px and were keyed by a spec list that was wrong
## about what they showed). Keyed by MEANING, resolved through `Icons.at` by
## role and key, so no path is named here and a missing sprite degrades to the
## disc (`Icons.exists` first — never a push_error for a kind the grid has no
## business drawing).
##
## What is here, and what is not: the morale pair (docs/13 §13's blocking row
## — a gain and a loss must differ by shape, and the grid's up/down arrows do)
## and the three record states the Records wall wants (HALL-20: locked /
## earned / claimed → the padlock, the coin that waits, the scroll it is
## written on). The feed's other kinds (recruit, gold, loot, mistake …) are NOT
## here on purpose: `Widgets.log_row` resolves them through `Icons.at("log",
## kind)` itself, and test_a11y_legibility.gd pins `badge_icon("loot") == null`
## as "an unclassified row keeps the disc".
const BADGE_FOR_KIND := {
	"morale_down": ["log", "morale_down"],
	"morale_up": ["log", "morale_up"],
	"locked": ["lock", "16"],
	"earned": ["log", "gold"],
	"claimed": ["log", "system"],
}

static func badge_icon(kind: String) -> Texture2D:
	var ref = BADGE_FOR_KIND.get(kind, null)
	if not (ref is Array) or (ref as Array).size() != 2:
		return null
	var role := String((ref as Array)[0])
	var key := String((ref as Array)[1])
	if not Icons.exists(role, key):
		return null
	return Icons.at(role, key)


## Notes that reach `morale_log` WITHOUT being docs/05 §7 trigger ids, and the
## sign each one carries. Values are a sign, never a delta — the size of the
## change belongs to the doc that owns the mechanic, and none of these are in §7.
##
## `rally_flask` is the live case and it is a GAIN: docs/11 §7 defines the Rally
## Flask as "halves the wipe morale penalty for all participants of the attempt
## just failed", and `GameState.use_rally_flask` only writes the row when the
## refund it hands back is positive. Left unmapped it fell to delta 0.0 and
## rendered as a grey disc with no badge — a morale gain wearing neither of
## docs/13 §13's two channels, which is worse than the always-green bug the fix
## below was for. A note that is in neither table is answered from the log's own
## history instead (see `_note_sign`).
const NOTE_SIGN := {
	"rally_flask": 1.0,
}


## The sign to paint a log row with: docs/05 §7's table first, then NOTE_SIGN,
## then the history itself.
##
## The third branch is what keeps this honest as the game grows: `morale_log` is
## written from four call sites and nothing forces a note to be a §7 trigger, so
## a new one WILL appear here before it appears in either table. `before` is the
## morale the previous row recorded and `after` this row's, so their difference
## is the change the player actually saw — no invented number, and the row keeps
## both of §13's channels. `before < 0` means there is no previous row (the
## raider's first recorded day), and only then is a row left neutral.
static func _note_sign(note: String, before: int, after: int) -> float:
	var trigger: Dictionary = Morale.TRIGGERS.get(note, {})
	if not trigger.is_empty():
		return signf(float(trigger.get("delta", 0.0)))
	if NOTE_SIGN.has(note):
		return float(NOTE_SIGN[note])
	return 0.0 if before < 0 else signf(float(after - before))


## The newest events, newest first: `GameState.event_feed` (TOWN-23 — the
## guild's own verbs, each `{day, seq, kind, text}`) FIRST, then the morale
## notes across the whole roster; within one day the feed's rows come before
## the notes, in the order they were written (`seq`). A state without a feed
## (a test stub, an older save shape) reads as notes only.
##
## `kind` is the second channel §13 requires; `tone` is the hue that used to be
## the only one. WHY THE SIGN DOES NOT COME FROM THE ROW: a `morale_log` entry is
## `{day, morale, note}` (sim/model/Raider.gd:245-251) and has never carried a
## `delta`, so the old `e.get("delta", 0.0) < 0.0` was always false and EVERY row
## in the event log rendered POSITIVE green regardless of what happened.
##
## UI-51: the morale notes are FOLDED, per day and per note, into one sentence
## each through `MORALE_SENTENCES` — a twelve-raider clear used to print
## "Bork: cleared / Gruk: cleared / …" twelve times and push the raid's own
## line off the six-row panel. A day keeps at most `MORALE_ROWS_PER_DAY` of
## them, the widest groups first (the crowd's mood before one raider's), and
## the feed's rows still come first within the day.
static func recent_events(state, limit: int) -> Array:
	var out: Array = []
	var feed = state.get("event_feed") if state != null else null
	if feed is Array:
		for f in feed:
			if not (f is Dictionary):
				continue
			out.append({
				"day": int(f.get("day", 0)),
				"seq": int(f.get("seq", 0)),
				"text": String(f.get("text", "")),
				"kind": String(f.get("kind", "")),
				"tone": feed_tone(String(f.get("kind", ""))),
			})
	# day -> note -> {names: [...], sgn: float} — who shares a note on a day.
	var groups: Dictionary = {}
	for r in state.roster:
		# Walked by index, not `for e in`, because an unmapped note takes its
		# sign from the morale the PREVIOUS row recorded. Rows with no note move
		# the morale too, so `before` advances on every row, not every event.
		var before := -1
		for i in r.morale_log.size():
			var e = r.morale_log[i]
			if not (e is Dictionary):
				continue
			var after: int = int(e.get("morale", 0))
			var note := String(e.get("note", ""))
			if note.is_empty():
				before = after
				continue
			var sgn: float = _note_sign(note, before, after)
			before = after
			var day: int = int(e.get("day", 0))
			if not groups.has(day):
				groups[day] = {}
			var by_note: Dictionary = groups[day]
			if not by_note.has(note):
				by_note[note] = {"names": [], "sgn": sgn}
			(by_note[note]["names"] as Array).append(String(r.display_name))
	for day in groups:
		var by_note: Dictionary = groups[day]
		var notes: Array = by_note.keys()
		# The widest group first; ties in the order the notes were met.
		notes.sort_custom(func(a, b) -> bool:
			return (by_note[a]["names"] as Array).size() > (by_note[b]["names"] as Array).size())
		for k in mini(notes.size(), MORALE_ROWS_PER_DAY):
			var note := String(notes[k])
			var sgn: float = float(by_note[note]["sgn"])
			var kind := ""
			var tone: Color = Palette.TEXT_MUTED
			if sgn < 0.0:
				kind = "morale_down"
				tone = Palette.DANGER
			elif sgn > 0.0:
				kind = "morale_up"
				tone = Palette.POSITIVE
			out.append({
				"day": int(day),
				"seq": -k,
				"text": morale_sentence(note, by_note[note]["names"]),
				"kind": kind,
				"tone": tone,
				"note": note,
				"names": by_note[note]["names"],
			})
	out.sort_custom(func(a, b) -> bool:
		if int(a["day"]) != int(b["day"]):
			return int(a["day"]) > int(b["day"])
		return int(a["seq"]) > int(b["seq"]))
	return out.slice(0, limit)


## The feed's sentence for a morale-log note (UI-51): `one` with the raider's
## name, `many` with the count, so the tag the sim writes ("cleared") never
## reaches a Label as "<name>: cleared". The notes are a closed set —
## `Morale.TRIGGERS`' ids, `NOTE_SIGN`'s and the comfort triggers — and a note
## neither table knows falls back to the raw pair, which is the honest read
## of a tag nobody has written the sentence for yet.
const MORALE_SENTENCES := {
	"cleared": ["%s came home happier.", "%d raiders came home happier."],
	"first_boss_kill": ["%s will not stop talking about the boss.",
		"%d raiders will not stop talking about the boss."],
	"wipe": ["%s is still upset about the wipe.", "%d raiders are still upset about the wipe."],
	"wipe_caused": ["%s knows the wipe was their fault.", "%d raiders blame themselves for the wipe."],
	"knocked_out": ["%s is nursing bruises.", "%d raiders are nursing bruises."],
	"avenged": ["%s got even.", "%d raiders got even."],
	"brought": ["%s was glad to be brought along.", "%d raiders were glad to be brought along."],
	"benched": ["%s minds being benched.", "%d raiders mind being benched."],
	"benched_wishlist": ["%s minds being benched.", "%d raiders mind being benched."],
	"peer_left": ["%s misses the one who left.", "%d raiders miss the one who left."],
	"peer_left_same_class": ["%s misses the one who left.", "%d raiders miss the one who left."],
	"peer_dismissed": ["%s noticed the dismissal.", "%d raiders noticed the dismissal."],
	"rank_up": ["%s is proud of the guild's standing.", "%d raiders are proud of the guild's standing."],
	"loot_upgrade": ["%s likes the new gear.", "%d raiders like their new gear."],
	"loot_wishlist": ["%s got the thing they wanted.", "%d raiders got the thing they wanted."],
	"loot_sidegrade": ["%s shrugged at the drop.", "%d raiders shrugged at the drop."],
	"passed_over": ["%s watched a drop go to someone else.",
		"%d raiders watched a drop go to someone else."],
	"passed_over_wishlist": ["%s watched a drop go to someone else.",
		"%d raiders watched a drop go to someone else."],
	"wishlist_sold": ["%s saw the thing they wanted sold.", "%d raiders saw what they wanted sold."],
	"comfort_item": ["%s enjoyed a comfort.", "%d raiders enjoyed a comfort."],
	"training": ["%s finished training.", "%d raiders finished training."],
	"quest_completed": ["%s is pleased with the record.", "%d raiders are pleased with the record."],
	"rally_flask": ["%s took heart from the flask.", "%d raiders took heart from the flask."],
}

## Whether a ONE-raider row is the table's sentence ("Bob is still upset about
## the wipe.") or the raw pair ("Bob: wipe"). False this wave only because
## tests/unit/test_a11y_legibility.gd:657-700 (another unit's file in wave 6)
## finds the single rows by `text.ends_with(note)`; handoff-W6-COPY §4 flips
## this to true with those two tests' edits, and the constant goes with it.
const SINGLE_ROW_SENTENCE := true

static func morale_sentence(note: String, names: Array,
		single_as_sentence: bool = SINGLE_ROW_SENTENCE) -> String:
	var forms = MORALE_SENTENCES.get(note, null)
	if names.is_empty():
		return note
	var known: bool = forms is Array and (forms as Array).size() == 2
	if names.size() == 1:
		if known and single_as_sentence:
			return String(forms[0]) % String(names[0])
		return "%s: %s" % [String(names[0]), note]
	if not known:
		return "%d raiders: %s" % [names.size(), note]
	return String(forms[1]) % names.size()


## The text hue of a feed row by its kind: the loss kinds in DANGER, the gain
## kinds in POSITIVE, everything else the log's muted ink — the hue is the
## second channel, the badge (the picture) the first.
static func feed_tone(kind: String) -> Color:
	match kind:
		"mistake", "morale_down", "boss_attack":
			return Palette.DANGER
		"morale_up", "heal", "raider_attack", "recruit":
			return Palette.POSITIVE
		"gold", "loot":
			return Palette.ACCENT_GOLD
		_:
			return Palette.TEXT_MUTED


# ---------------------------------------------------------------- encounter art

## The sprite that stands for an encounter. Canon names its enemy blocks by
## rank (Trash / Elite / Mini Boss / Main Boss) and the sliced boss sheet has
## a creature per rank (game/assets/enemies/boss_<rank>[_2].png); the id picks
## the variant so two mini-bosses in a tier do not share a face.
static func encounter_sprite(enc) -> Texture2D:
	if enc == null:
		return null
	var rank := "trash"
	for block in enc.enemies:
		var nm := String(block.name).to_lower()
		if nm.contains("main boss"):
			rank = "main"
			break
		if nm.contains("mini boss"):
			rank = "mini"
		elif nm.contains("elite") and rank == "trash":
			rank = "elite"
	var variant := "_2" if (rank in ["main", "mini"]) and (String(enc.id).hash() % 2 == 1) else ""
	var path := ENEMIES + "boss_%s%s.png" % [rank, variant]
	if not ResourceLoader.exists(path):
		path = ENEMIES + "boss_%s.png" % rank
	return load(path) if ResourceLoader.exists(path) else null


## 01 §2's art well (337x104 in the sidebar card): every encounter — the main
## boss included — gets its rank's creature over a darkened slice of the arena,
## so the well is never the wrong boss. RULES-10 (W3-KIT2): the main boss used
## to keep a crop of the Concept 2 mockup (the reference's own pixels pasted
## back in — LESSONS: a diff against the reference is a tautology there); that
## crop is deleted from game/assets/bg and this composition is the well.
static func encounter_art(enc, size: Vector2 = Vector2(337, 104)) -> Control:
	var well := Control.new()
	well.name = "Art"
	well.custom_minimum_size = size
	well.clip_contents = true
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := TextureRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The 2026-09-11 directive reaches this thumbnail too: the well used to hold a
	# crop of `arena_stage.png`, which is the mockup's arena with its own figures
	# and pills a few hundred pixels away. The bare cave plate is the same room
	# the prep screen now shows behind this card, so the card and the screen stop
	# disagreeing about where the fight is. Region 620,380 is the central
	# plateau: floor, crystals, no lantern posts cut in half.
	if ResourceLoader.exists("res://game/assets/bg/stage_arena_cave.png"):
		var at := AtlasTexture.new()
		at.atlas = load("res://game/assets/bg/stage_arena_cave.png")
		at.region = Rect2(620, 380, size.x, size.y)
		bg.texture = at
		bg.stretch_mode = TextureRect.STRETCH_KEEP
		bg.modulate = Color(0.55, 0.55, 0.62)
		well.add_child(bg)
		bg.position = Vector2.ZERO
	var spr := TextureRect.new()
	spr.texture = encounter_sprite(enc)
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	well.add_child(spr)
	spr.position = Vector2(0, 6)
	spr.size = Vector2(size.x, size.y - 12)
	return well


# ---------------------------------------------------------------- gear icons

## The picture for a gear slot, the same on every screen. Weapons, chests and
## trinkets use the sliced reference icons; head, legs, feet and the off-hand
## use the generated set (tools/aseprite/gen_items.lua) in the MATERIAL the
## item's family implies — plate for Warrior/Bard, leather for Monk/Rogue,
## cloth for the healers and casters; a shield, a tome or a lute in the off
## hand. With no item (`item` null and `has_item` false) the slot's own glyph
## comes back for the empty well (callers dim it).
static func gear_icon(slot: int, has_item: bool, item = null) -> Texture2D:
	var file := ""
	if has_item:
		var mat := _material_of(item)
		match slot:
			Enums.Slot.MAIN_HAND:
				file = _weapon_file(item)
			Enums.Slot.CHEST:
				# The reference's cuirass for plate; a robe or a jerkin otherwise.
				file = "item_gear_1" if mat == "iron" else "item_chest_" + mat
			Enums.Slot.TRINKET:
				file = _trinket_file(item)
			Enums.Slot.OFF_HAND:
				file = "item_off_hand_" + _off_hand_kind(item, mat)
			Enums.Slot.HEAD:
				# Canon gives the Rogue an eyepatch and the Monk a headband as
				# their own head families; a hood would be the wrong picture.
				var fam := _family_key(item)
				var kind := "eyepatch" if fam == "rogue_head" else ("headband" if fam == "monk_head" else mat)
				file = "item_head_" + kind
			Enums.Slot.LEGS, Enums.Slot.FEET:
				file = "item_%s_%s" % [String(Enums.Slot.keys()[slot]).to_lower(), mat]
	if file.is_empty() and slot >= 0 and slot < Enums.Slot.size():
		file = "slot_%s" % String(Enums.Slot.keys()[slot]).to_lower()
	var path := ICON + file + ".png"
	return load(path) if not file.is_empty() and ResourceLoader.exists(path) else null


## Item family -> icon material. Unknown or no item reads as iron, the
## reference's own default look.
static func _family_key(item) -> String:
	if item == null or not ("family" in item):
		return ""
	return String(Enums.family_key(int(item.family)))


static func _material_of(item) -> String:
	var key := _family_key(item)
	if key.is_empty():
		return "iron"
	if key.begins_with("monk") or key.begins_with("rogue") or key == "instrument":
		return "leather"
	if key.begins_with("healer") or key.begins_with("mage_wizard") 			or key in ["mage_two_hand", "wizard_two_hand", "druid_weapon", "shaman_weapon", "cleric_weapon"]:
		return "cloth"
	return "iron"


## Canon's weapon families each have a shape: the reference sword for the
## Warrior/Rogue/Bard one-hander (a dagger when the item says so), staves for
## the Monk and the casters — plain, ember, arc, living — a mace for the
## Cleric, a totem for the Shaman.
static func _weapon_file(item) -> String:
	var key := _family_key(item)
	var nm := String(item.name).to_lower() if item != null and "name" in item else ""
	match key:
		"wrb_one_hand":
			return "item_weapon_dagger" if nm.contains("dagger") else "item_gear_0"
		"monk_two_hand":
			return "item_weapon_staff_wood"
		"mage_two_hand":
			return "item_weapon_staff_fire"
		"wizard_two_hand":
			return "item_weapon_staff_arc"
		"druid_weapon":
			return "item_weapon_staff_druid"
		"cleric_weapon":
			return "item_weapon_mace"
		"shaman_weapon":
			return "item_weapon_totem"
	return "item_gear_0"


## The four charms (docs/09: Armor / Health / Mana / Power) by the word in the
## item's name; the reference gem for anything else.
## Every trinket in the game is a Charm of Armor / Health / Mana / Power, so
## the named branch is the whole catalogue; a trinket with no item behind it
## (a loot-slot cell on a notice, UI-14) is the charm family's picture too —
## the reference's purple gem is the reputation chip's and nobody else's
## (spec 00 §2.5 records that canon has no gems).
static func _trinket_file(item) -> String:
	var nm := String(item.name).to_lower() if item != null and "name" in item else ""
	for word in ["armor", "health", "mana", "power"]:
		if nm.contains(word):
			return "item_trinket_" + word
	return "item_trinket_power"


static func _off_hand_kind(item, mat: String) -> String:
	if item != null and "family" in item:
		var key := String(Enums.family_key(int(item.family)))
		if key == "instrument":
			return "instr"
		if key == "healer_off_hand":
			return "cloth"
		if key == "warrior_shield":
			return "iron"
	return mat


## The picture for one of an encounter's loot slots (docs/10 §4.2 keys). Most
## are plain slot names; the rest are canon's own words — "weapon_basic",
## "weapon_strong", "offhand_healer", "capstone" — and get the nearest gear
## picture, the capstone the reference's gold medallion.
static func loot_slot_icon(key: String) -> Texture2D:
	if key.begins_with("weapon"):
		return gear_icon(Enums.Slot.MAIN_HAND, true)
	if key == "offhand_healer":
		var tome := ICON + "item_off_hand_cloth.png"
		return load(tome) if ResourceLoader.exists(tome) else gear_icon(Enums.Slot.OFF_HAND, true)
	if key.begins_with("offhand"):
		return gear_icon(Enums.Slot.OFF_HAND, true)
	if key == "capstone":
		return load(ICON + "item_reward_3.png")
	var slot := Enums.slot_from_key(key)
	if slot >= 0:
		return gear_icon(slot, true)
	var unknown := ICON + "item_unknown.png"
	return load(unknown) if ResourceLoader.exists(unknown) else null


# ---------------------------------------------------------------- building levels

## Whether a scene's JSON carries an art layer for `building` at `level` —
## the `has_layer` check LOOP-20 asks the "Next: …" copy to make before it
## promises what a level LOOKS like. docs/02 §2.1's Rule of Visible Change
## obliges every building level to a visible exterior delta, and
## `Consumables.stall_look()` / `Comfort.LEVELS[].look` carry that delta as
## PROSE ("Second stall, crates, two shoppers") — which nothing draws today.
## So the Market and Facilities print a level's NAME and its EFFECT, and add
## the look sentence only where the plate can back it.
##
## The shape it looks for: `"levels": {"<building>": {"<level>": <layer>}}`
## in `game/assets/scenes/<scene>.json`. No scene carries the key yet; W8-
## FACILITY's tent states and stall layers are the first that will, and this
## is where the copy will notice. Lives here beside `encounter_art` rather
## than in SceneStage because that file is another unit's this wave; the
## reader is three lines and reads the file, never the stage.
static func scene_has_level_layer(scene: String, building: String, level: int) -> bool:
	var path := "res://game/assets/scenes/%s.json" % scene
	if not FileAccess.file_exists(path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return false
	var levels = (parsed as Dictionary).get("levels", {})
	if not (levels is Dictionary):
		return false
	var mine = (levels as Dictionary).get(building, {})
	return mine is Dictionary and (mine as Dictionary).has(str(level))
