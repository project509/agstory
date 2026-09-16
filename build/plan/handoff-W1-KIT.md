# Handoff — W1-KIT

Exact edits this unit needs in files it does not own (shape: `## N. <path>:<line>`, then `old:` and
`new:` fenced blocks, one edit per heading, indentation matching the file — RaiderDetail.gd, Tavern.gd and
SceneStage.gd use TABS; Market.gd and RaidPrep.gd use FOUR SPACES). Nothing here is applied by the unit.
Line numbers are from the tree on 2026-09-14 14:00; W1-HALL (RaiderDetail.gd) and W1-STAGE (SceneStage.gd)
are editing two of these files in the same wave, so match by the `old:` text, not the number. API notes for
the consuming wave-2/3 units follow the edits.

Why each edit exists: §1-§2 finish RULES-12 (the two "private until the kit grows" classes are promoted
verbatim into Widgets.gd; the screens should call them so a kit repaint has one copy to restyle). §3-§5 finish
KIT-12 / CRITIC-C11 / TOWN-16 / COMBAT-19: `Cards.roster_strip` now draws its own gutter pager
(`PagerPrev`/`PagerNext`, spec 10 §2 R1's x 131 / 1035), so the three screens that drew their own arrows over
card 4 (RaidPrep, Tavern) or under the mini-grid (RaiderDetail) would show TWO pagers until these land; each
screen keeps its `_page` in step through `opts.on_page`. §6 retires SceneStage's private Ellipsis: the emote
frame is now W1-CHROME's 40x44 `PanelEmote` and `Widgets.speech_bubble` centres its own dots (or a glyph) on
that frame's body, while the private copy still draws at the old 33x32 bubble's pixels — on the new frame that
is the rim, not the body.

## 1. game/screens/RaiderDetail.gd:668

old:
```
	var chart := MoraleChart.new()
	for entry in log:
		chart.values.append(int(entry["morale"]))
	chart.custom_minimum_size = Vector2(
		mini(RIGHT_TEXT_W, log.size() * MoraleChart.PITCH), MoraleChart.HEIGHT)
	chart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(chart)
```
new:
```
	var values: Array = []
	for entry in log:
		values.append(int(entry["morale"]))
	var chart := Widgets.sparkline(values)
	chart.custom_minimum_size = Vector2(
		mini(RIGHT_TEXT_W, log.size() * Widgets.Sparkline.PITCH), Widgets.Sparkline.HEIGHT)
	chart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(chart)
```

## 2. game/screens/RaiderDetail.gd:682

The private class goes (its `_draw` is `Widgets.Sparkline._draw` line for line; the promoted copy takes the
band colour through `color_fn`, defaulting to the same `Palette.morale_color`). Delete the whole block, the
two blank lines above it included, so the file keeps two blank lines between functions.

old:
```
## One bar per recorded day, coloured by the morale band it landed in, on the
## kit's inset well. Private to this screen until the kit grows a sparkline.
class MoraleChart extends Control:
	const Pal = preload("res://game/ui/Palette.gd")
	const PITCH := 12
	const HEIGHT := 40
	var values: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Pal.SURFACE_INSET)
		draw_rect(Rect2(Vector2.ZERO, size), Pal.EDGE_SLATE, false, 1.0)
		var n := values.size()
		if n == 0:
			return
		var pitch := minf(float(PITCH), size.x / float(n))
		var w := maxf(2.0, floorf(pitch) - 2.0)
		var inner := size.y - 4.0
		for i in n:
			var v := clampi(int(values[i]), 0, 100)
			var h := maxf(2.0, floorf(inner * v / 100.0))
			draw_rect(Rect2(Vector2(2.0 + i * pitch, size.y - 2.0 - h), Vector2(w, h)),
				Pal.morale_color(v))


```
new:
```
```

## 3. game/screens/Market.gd:574

old:
```
    var box := _slot_with_reason(label, reason, TIER_CELL)
```
new:
```
    var box := Widgets.slot_with_reason(label, reason, TIER_CELL)
```

## 4. game/screens/Market.gd:583

Delete the private function (promoted verbatim as `Widgets.slot_with_reason(caption, reason, cell, icon)`;
the Button is still named "Button", so `Widgets.button_of(box)` on the line after §3 keeps working). Delete
the comment and the function and the two blank lines under it.

old:
```
## `Widgets.button_with_reason` for a slot cell: the slot chrome, the caption in
## the Button's text, and docs/13 §7's reason printed under it at the cell's own
## width. Private until the kit grows a slot variant of button_with_reason.
func _slot_with_reason(caption: String, reason: String, cell: Vector2,
        icon: Texture2D = null) -> VBoxContainer:
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    var b := Widgets.slot_button(caption, icon, int(cell.y))
    b.custom_minimum_size = cell
    b.name = "Button"
    b.disabled = not reason.is_empty()
    b.add_theme_color_override("font_color", Palette.TEXT_BODY)
    box.add_child(b)
    if not reason.is_empty():
        var why := Widgets.label_as(reason, "LabelSmall")
        why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        why.custom_minimum_size = Vector2(cell.x, 0)
        box.add_child(why)
    return box


```
new:
```
```

## 5. game/screens/RaidPrep.gd:469

The strip pages itself now; the screen's `_page` follows through `on_page`, and the screen-drawn arrows
(which sat at x 800-874 over card 4 — KIT-12's defect) go. The "Tonight's N" count is already printed by the
readout's "Slots n / m" line; the strip prints "n/m" under its right gutter.

old:
```
        var pages := Cards.roster_strip(_strip, _state, _page, {
            "cards": _chalked, "available": bench,
            "available_label": "Bench",
            "card_action": func(r) -> void: _toggle(String(r.id)),
            "card_action_text": "Bench",
            "grid_action": func(r) -> void: _toggle(String(r.id)),
        })
        _page = clampi(_page, 0, pages - 1)
        _pager(pages)
```
new:
```
        var pages := Cards.roster_strip(_strip, _state, _page, {
            "cards": _chalked, "available": bench,
            "available_label": "Bench",
            "card_action": func(r) -> void: _toggle(String(r.id)),
            "card_action_text": "Bench",
            "grid_action": func(r) -> void: _toggle(String(r.id)),
            "on_page": func(p: int) -> void: _page = p,
        })
        _page = clampi(_page, 0, pages - 1)
```

## 6. game/screens/RaidPrep.gd:486

Delete the function the edit above stopped calling (and its comment and the two blank lines under it).

old:
```
## Page arrows live in the strip's gutters (10 §2 R1); with one page there is
## nothing to say and nothing is drawn.
func _pager(pages: int) -> void:
    if pages <= 1:
        return
    var label := Widgets.label_as("Tonight's %d  ·  page %d/%d"
        % [_chalked.size(), _page + 1, pages], "LabelSmall")
    _strip.add_child(label)
    label.position = Vector2(Widgets.CARD_X0 - 13, Widgets.STRIP_H - 20)
    var prev := Widgets.pager_button(false)
    _strip.add_child(prev)
    prev.position = Vector2(Widgets.CARD_X0 + 660, Widgets.STRIP_H - 30)
    prev.size = Vector2(34, 26)
    prev.pressed.connect(func() -> void:
        _page = (_page - 1 + pages) % pages
        _refresh())
    var next := Widgets.pager_button(true)
    _strip.add_child(next)
    next.position = Vector2(Widgets.CARD_X0 + 700, Widgets.STRIP_H - 30)
    next.size = Vector2(34, 26)
    next.pressed.connect(func() -> void:
        _page = (_page + 1) % pages
        _refresh())


```
new:
```
```

## 7. game/screens/Tavern.gd:240

old:
```
	var pages := Cards.roster_strip(_strip, _state, _page, {
		"cards": board, "available": board,
		"available_label": "Seats", "seats": _state.board_slots(),
		"card_builder": func(who, index: int) -> Control: return _candidate_card(who, index),
		"grid_action": func(who) -> void:
			_selected = _index_of(who)
			_refresh(),
	})
	_page = clampi(_page, 0, pages - 1)
	if pages > 1:
		var lbl := Widgets.label_as("page %d/%d" % [_page + 1, pages], "LabelSmall")
		_strip.add_child(lbl)
		lbl.position = Vector2(Widgets.CARD_X0 - 13, Widgets.STRIP_H - 18)
		var prev := Widgets.pager_button(false)
		_strip.add_child(prev)
		prev.position = Vector2(Widgets.CARD_X0 + 660, Widgets.STRIP_H - 30)
		prev.size = Vector2(34, 26)
		prev.pressed.connect(func() -> void:
			_page = (_page - 1 + pages) % pages
			_refresh())
		var next := Widgets.pager_button(true)
		_strip.add_child(next)
		next.position = Vector2(Widgets.CARD_X0 + 700, Widgets.STRIP_H - 30)
		next.size = Vector2(34, 26)
		next.pressed.connect(func() -> void:
			_page = (_page + 1) % pages
			_refresh())
```
new:
```
	var pages := Cards.roster_strip(_strip, _state, _page, {
		"cards": board, "available": board,
		"available_label": "Seats", "seats": _state.board_slots(),
		"card_builder": func(who, index: int) -> Control: return _candidate_card(who, index),
		"grid_action": func(who) -> void:
			_selected = _index_of(who)
			_refresh(),
		"on_page": func(p: int) -> void: _page = p,
	})
	_page = clampi(_page, 0, pages - 1)
```

## 8. game/screens/RaiderDetail.gd:769

old:
```
	var pages := Cards.roster_strip(_strip, _state, _page, {
		"card_action": func(r) -> void: _open(String(r.id)),
		"card_action_text": "Open",
		"grid_action": func(r) -> void: _open(String(r.id)),
	})
	_page = clampi(_page, 0, pages - 1)
	_pager(pages)
	Cards.event_log(_strip, _state)
```
new:
```
	var pages := Cards.roster_strip(_strip, _state, _page, {
		"card_action": func(r) -> void: _open(String(r.id)),
		"card_action_text": "Open",
		"grid_action": func(r) -> void: _open(String(r.id)),
		"on_page": func(p: int) -> void:
			_page = p
			_paged = true,
	})
	_page = clampi(_page, 0, pages - 1)
	Cards.event_log(_strip, _state)
```

## 9. game/screens/RaiderDetail.gd:787

Delete the function §8 stopped calling (its comment and the two blank lines under it included).

old:
```
## Page arrows under the mini-grid (10 §2 R1). One page: nothing to say.
func _pager(pages: int) -> void:
	if pages <= 1:
		return
	var label := Widgets.label_as("page %d / %d" % [_page + 1, pages], "LabelSmall")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_strip.add_child(label)
	label.position = Vector2(0, Widgets.STRIP_H - 54)
	label.size = Vector2(110, 18)
	var prev := Widgets.pager_button(false)
	_strip.add_child(prev)
	prev.position = Vector2(10, Widgets.STRIP_H - 34)
	prev.size = Vector2(42, 26)
	prev.pressed.connect(func() -> void:
		_page = (_page - 1 + pages) % pages
		_paged = true
		_refresh())
	var next := Widgets.pager_button(true)
	_strip.add_child(next)
	next.position = Vector2(58, Widgets.STRIP_H - 34)
	next.size = Vector2(42, 26)
	next.pressed.connect(func() -> void:
		_page = (_page + 1) % pages
		_paged = true
		_refresh())


```
new:
```
```

## 10. game/ui/SceneStage.gd:945

**ALREADY APPLIED by W1-STAGE (seen in the tree at 16:35: SceneStage.gd:953 reads
`Widgets.speech_bubble("dots", glyph)` and the `Ellipsis` class is gone) — nothing left to apply for §10-§11;
kept for the record.**

`Widgets.speech_bubble(kind, glyph)` centres the dots or a glyph on `PanelEmote`'s body itself; the stage
stops adding its own. (W1-STAGE is editing this file in the same wave — match the text.)

old:
```
		var bub := Widgets.speech_bubble()
		bub.position = Vector2(float(b[0]), float(b[1]))
		bub.visible = false
		var icon_path := ICONS + String(b[2]) + ".png" if b.size() > 2 else ""
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			var ic := TextureRect.new()
			ic.texture = load(icon_path)
			ic.stretch_mode = TextureRect.STRETCH_KEEP
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic.position = Vector2(8, 4)
			bub.add_child(ic)
		else:
			var dots := Ellipsis.new()
			dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dots.position = Vector2.ZERO
			dots.size = Vector2(33, 24)
			bub.add_child(dots)
		add_child(bub)
```
new:
```
		var icon_path := ICONS + String(b[2]) + ".png" if b.size() > 2 else ""
		var glyph: Texture2D = null
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			glyph = load(icon_path)
		var bub := Widgets.speech_bubble("dots", glyph)
		bub.position = Vector2(float(b[0]), float(b[1]))
		bub.visible = false
		add_child(bub)
```

## 11. game/ui/SceneStage.gd:1196

**ALREADY APPLIED by W1-STAGE — see §10.** The private class is unreferenced after §10; delete it, its two
comment lines and the two blank lines under it. Before it landed the Town showed TWO rows of dots in each
emote bubble: the stage's Ellipsis at the old 33x32 bubble's (8,11) and the kit's centred on PanelEmote's
body (W1-KIT shot 1 at 16:21, `W1-KIT-Town_emote.png`).

old:
```
## The "..." inside a bubble: three dots in the bubble's ink, drawn rather than
## typeset so they sit on the pixel grid at any font.
class Ellipsis extends Control:
	func _draw() -> void:
		for i in 3:
			draw_rect(Rect2(8 + i * 6, 11, 3, 3), Palette.INK_BUBBLE_DOTS)


```
new:
```
```

---

## API notes for the consuming units (nothing to apply)

- `Widgets.stamp(text, tone: Color) -> Label` is UNCHANGED in signature (four screens hold a Label) and now
  leans 2-7° from the word at 0.85 alpha. The box form is `Widgets.stamp_box(word, tone: String) ->
  PanelContainer` (PanelStamp; the Label is `get_child(0)`; tones "danger" / "caution" / "positive" / "info").
  W2-RAIDVIEW: `_wipe_stamp_label = box.get_child(0)` and add the box DIRECTLY to the screen after the blot
  keeps test_wipe_sequence's sibling contract; `Widgets.stamp_press(box)` is the 120/60 ms press for a stamp
  that lands live. W2-RESULTS / W3-ROSTER: `stamp_box` where the old Label was a card stamp.
- `Widgets.reasoned(control, reason, glyph)` — the one disabled-with-reason treatment; the reason Label is
  named "Reason"; empty reason = enabled. `Widgets.confirm_pair(yes, no, on_yes, on_no)` — the "no" half is
  `Widgets.default_focus_of(plate)` and is grabbed (deferred) on tree entry; W3-OPTIONS / W3-DETAIL.
- `Widgets.damage_number(amount, kind)` + `Widgets.number_rise(label)` + `Widgets.number_stagger(i)`; the caller
  parents the Label (W2-RAIDVIEW through `SceneStage.number_at` once W1-STAGE lands it).
- `Cards.roster_strip(host, state, page, opts)` pages itself; `opts.on_page: Callable(int)`; the current page
  is `Cards.strip_page(host)`; everything it draws lives under `host/RosterStrip`. `Widgets.pager(page, pages,
  on_prev, on_next, caption)` is the captioned row for RaidView.
- `Widgets.tab_row(labels, active, reasons) -> VBoxContainer`, the Buttons via `Widgets.tabs_of(row)` — W1-HALL /
  W3-ROSTER (texts unchanged).
- `Cards.card(raider, db, action, actions)` — `actions` = [{text, on, reason}] becomes the in-card band named
  "Actions"; `Cards.event_log(host, state, rows, hint)`.
- `Widgets.building_callout(name, verb, reason, icon: Texture2D, anchor: Vector2)` — with `anchor` the plate
  places itself so the tail's apex sits on it (W2-TOWN passes the building's foot and `Icons.at("building_<id>")`).
- `Widgets.speech_plate(text, tail_at: Vector2)` grows a child named "Tail" only when `tail_at` is finite
  (W2-STAGE2 passes the speaker's head); `Widgets.speech_bubble(kind, glyph)`.
- `Widgets.empty_state(text, glyph: Texture2D, hint)` is still a Label; the glyph and hint are children named
  "Glyph" / "Hint".
- **W1-STAGE, bubble identity:** `Widgets.speech_bubble()` names its TextureRect "Emote", but sibling names must be
  unique, so a stage that adds five keeps "Emote" on the first and Godot renames the rest `@TextureRect@N` — a
  different N every run (this is why `test_every_ambient_bubble_hangs_over_a_head` found 3 and
  `test_reduced_motion_holds_lights_and_bubbles` saw two runs disagree at 16:40). Count or compare bubbles by
  `child.has_meta("emote")` (the value is the `kind`, "dots" by default), never by name.

## API notes added by the repair pass (review-W1-KIT.md; nothing to apply)

- **W2-TOWN, callout band (review F7):** `Widgets.building_callout(name, verb, reason, icon, anchor, bounds := Rect2())`
  keeps its plate inside the SCENE band expressed in the plate's PARENT's space — on the Town's full-bleed scene host
  (position (0,0)) that is screen (210,77)-(1139,717), so `anchor` in the same screen pixels Town.gd's `at` uses lands
  the plate right of the rail, left of the sidebar (no plate crosses x=1141) and the tail's apex on the anchor, with no
  workaround: parent the callouts to `f.scene` exactly as today and pass `anchor`. The band is derived by summing the
  parent's offset up to the screen root (the node carrying Frame's `frame_focus_order` meta), so a nested parent works
  too; `bounds` (parent's space) overrides it for a parent that is not on the scene at all.
- **W2-TOWN, 150% text:** with Town.gd's current `at` values (Blacksmith 292, Market 414 — 122px apart) and the
  two-sentence reason wrapping to three lines at `text_scale=150`, the locked plate (~185 tall) covers the Market's
  title exactly as the pre-wave build did (build/shots/all/text150/Town.png vs W1-KIT-fix-Town-t150-crop.png). The
  clamp keeps plates inside the band, never apart from each other; the anchors plus the one-line reason in W2-TOWN's
  acceptance are what separate them.
- **W2-RAIDVIEW / W2-RESULTS / W3-ROSTER, stamp lean (review M7):** `Widgets.stamp(text, tone) -> Label` now leans
  2-7° (from `word.hash()`, sign alternating) at 0.85 alpha wherever it is already used — Results' FALLEN, Tavern's,
  Roster's, RaidView's "WIPE." Label — a static docs/13 §7 lean, not motion (no reduced-motion door owed; RaidView's
  own box still rotates to 0 under reduced motion). Expect it; `stamp_box(word, tone_name)` is the PanelStamp form.
- **W3-OPTIONS / W3-DETAIL, confirm focus (review M8):** `confirm_pair` grabs the "no" half (deferred) on
  `tree_entered`; a pending confirm rebuilt inside `build()` therefore takes focus AFTER the router's
  `initial_focus_target` grab — the safe half of a pending destructive choice holds focus. Intended; plan for it.
- **W3-KIT2, the Available head (review M1):** on the Town the strip's ◄ plate (strip x 111-127, screen 124-140) sits
  12px over the Available panel because the panel's HEAD grows it: "Available   12" at LabelSectionSm (17px) is
  ~99px + 24px pad = 123 > the 110 Cards.gd assigns (the 2x4 mini-grid is 81 + 24 = 105 and fits; RaidPrep's "Bench
  0" and the Tavern's "Seats" fit too). spec 01 §4.1 draws the count as a separate dim numeral flush right at
  x≈101-110 with the panel 110 wide — that geometry fits ONE digit. A fix needs the head split into two Labels (word +
  right-aligned dim count) with the count at LabelSmall or the panel widened, and either changes the strip's
  `_texts()` — left to W3-KIT2, which owns that decision (`Cards._fill_strip`, the `"%s   %d"` head).
- **Page-turn focus (review M2):** `Cards._turn_page` now re-runs the screen's focus wiring (the `frame_focus_order`
  Callable on the nearest ancestor that carries it) after every rebuild, before handing focus to the new arrow; a
  screen that keeps its own `_page` and rebuilds other regions in `on_page` is re-wired after `on_page` returns.
