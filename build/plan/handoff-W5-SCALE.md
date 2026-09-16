# handoff-W5-SCALE — edits to files this unit does not own

Every row here is a finding of `tests/unit/test_text_scale_layout.gd` (its `KNOWN` allow-list carries the
same rows with the measured numbers; a row there fails the test the day the screen fits, and asks to be
deleted). Numbers are in-tree at the reference fixture, 2026-09-15. Tabs in RaidView.gd, Widgets.gd, Cards.gd.

## 1. game/screens/RaidView.gd:576

The objective title is a `clip_text` Label in the concept's 352px plate (02 §4.2) and trims with an ellipsis
above 100%: "E5 — Raid 1 — Encounter 5" is 293px at 125 and 351 at 150 in its 283. docs/13 §14 forbids an
ellipsis through an encounter's name; the plate cannot grow. The rail's answer (Frame._rail_label_size) —
step the size down until the string fits, never below the 100% size — carried over. `Frame._theme_font` is
static and RaidView already preloads Frame, Theme_ and Type.

old:
```
	var t := Widgets.label_as(title, "LabelObjective")
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(t)
	t.position = Vector2(57, 98)
	t.size = Vector2(OBJECTIVE.size.x - 57 - 12, 28)
```
new:
```
	var t := Widgets.label_as(title, "LabelObjective")
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(t)
	t.position = Vector2(57, 98)
	t.size = Vector2(OBJECTIVE.size.x - 57 - 12, 28)
	# W5-SCALE: the plate is the concept's 352 at every text scale, so above
	# 100 the title steps its size down a pixel at a time until it fits its
	# 283 — never below the 100% size, never an ellipsis through an
	# encounter's name (docs/13 §14). Measured: 293px at 125, 351 at 150
	# (tests/unit/test_text_scale_layout.gd).
	var pct: int = Theme_.scale_of(self)
	if pct != Type.SCALE_DEFAULT:
		var tf: Font = Frame._theme_font(self, "LabelObjective")
		var px: int = Type.at(Type.OBJECTIVE, pct)
		while px > Type.OBJECTIVE \
				and tf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > t.size.x:
			px -= 1
		t.add_theme_font_size_override("font_size", px)
```

## 2. game/ui/Widgets.gd:653

`cta()`'s cost line sits in a 22px slot under the label (offsets -30/-8). The LabelCtaCost line is 34px
tall at 150, so the Label grows 4px under the Depart plate (RaidPrep's "12 of 12 chalked" ends at y=635
in a plate that ends at 631). The slot scales with the text; identity at 100 by construction.

old:
```
		cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		cost.offset_top = -30
		cost.offset_bottom = -8
```
new:
```
		cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		# W5-SCALE: the 22px slot scales with the text — the line is 34 tall
		# at 150 and grew 4px under the plate (test_text_scale_layout.gd).
		var pct: int = Theme_.scale_of(b)
		var slot: int = 22 if pct == Type.SCALE_DEFAULT else Type.at(24, pct)
		cost.offset_top = -(8 + slot)
		cost.offset_bottom = -8
```

## 3. game/ui/Cards.gd:632

`event_log()` fits its rows by `ROWS`, a compile-time count at the unscaled `LOG_ROW_PITCH` (29): six rows
at 150 are 36 tall each, the column wants 216 in the 197 under the head, and the PanelRound grows 12px
under the frame's bottom edge on every hub screen (the panel clips its own content, not its plate). The
pitch at the scale is the fit's divisor (W5-KIT3 owns the file this wave; the `old:` is its text at 12:10).
NOTE: `game/screens/Town.gd:_today_lines` (W5-SCALE) mirrors the 100% arithmetic to say how many events the
log shows (it could not adopt `Cards.ROWS`, this wave's, under rule 7) — if the count becomes scale-aware,
Town's line should read the same number.

old:
```
	var events := recent_events(state, mini(rows, ROWS))
```
new:
```
	# W5-SCALE: the rows that fit at the player's text scale, not ROWS (the
	# 100% count) — six 36px rows overran the 262 by 12 at 150, measured.
	var fit: int = int((Widgets.STRIP_H - 2 * CARD_PAD - EVENT_HEAD_H - 1)
		/ Type.at(Widgets.LOG_ROW_PITCH, Theme_.scale_of(host)))
	var events := recent_events(state, mini(rows, fit))
```

## Notes (no exact edit — the owner's call)

- **Cards.card at 125/150 (W5-KIT3, editing the file this wave).** The kit card wants more than its authored
  215x262 above 100: the morale line ("Rhona — 34 😒" is 203px at 30px tabular in the 191 inside the pad),
  the action pair ("Cheer up" + "Manage", 197 at 150) and the reason line under it ("They are fine.", +10px
  at 125). The Roster grid's cells clip 4-16px of the rim; on the strip the card runs 12px (125) to 60px
  (150) under the frame's bottom edge on Town, AdventureBoard, Market, RaidPrep, RaiderDetail and Results.
  docs/13 §4.4's answer is fewer, wider cards per page at the larger scales (the strip pages in fours at
  CARD_PITCH 224); the Tavern's own seat card reached 236 of 238 at 150 by dropping the face sheet's line
  height from the class line (Tavern.gd's header note) — the same lever exists on the kit card's class row.
- **Cards.roster_strip's page caption.** "n/m" sits at STRIP_H + 4 under the cards; Results' card host sits
  at y=741 (its CARD_Y 6 under the concept's 735 strip), so the caption ends at 1025/1029/1032 by scale —
  the frame is 1024 and the Strip host clips. Reading the caption's own height and keeping it inside the
  host's bottom edge (or Results giving up CARD_Y) fixes it; the test allow-lists it under Results.
- **Market.gd's sidebar at 150** wants 381 in 378 ("Pay for a better stall — 130 G" is 333px plus the
  pad's 2x(14+18)) and the PanelWarm ends 3px past the frame. A wrapping Button (`Widgets._guard_cta`'s
  idiom) or a `custom_minimum_size.x` cap on that button is the fix.
- **AdventureBoard.gd:592 / :613** cap the encounter's facts line at 1 line and the notice's quip at 2
  (`max_lines_visible`); the fixture's lines want 2/3 at 100 and 3 at 150. Those are designed caps, and
  docs/13 §14 says reflow-not-truncate — the owner's call whether the caps stand.
- **Roster.gd's sidebar facts** ("Roster average morale 46", "At risk 1") are LabelBody lines that print no
  face and pay the face sheet's line height (36 instead of 29 at 150, 24 instead of 19 at 100); the same
  LabelMuted-at-LabelClass-colour move the Tavern and Completion made would give the Guildhall's roster
  block ~14px back at 150 and put the morale chart above the fold on its own.
- **Tavern.gd's sidebar** (owned, left): the whole column scrolls (TOWN-17) and at 150 the fold lands
  through "Not tonight" (build/shots/w5scale/Tavern_text150.png). The Guildhall's `_snap_fold` is the
  mechanism; it was not applied here because the column has no fixed footer and TOWN-17 chose the scroll.
