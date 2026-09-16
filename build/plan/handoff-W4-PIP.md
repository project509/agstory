# handoff-W4-PIP — edits this unit needs in files it does not own

Unit: W4-PIP (Theme.gd, Fonts.gd, game/assets/fonts/**, tests/unit/test_pip_figure.gd). Nothing below is applied by the unit.
Shape: `## N. <path>:<line>` then an `old:` fenced block and a `new:` fenced block, one edit per heading.

Why there are edits at all: the emoji-free figure is made even at the FONT layer (Fonts.with_pips: a one-glyph bar
font in front of Fira Sans in the morale variations — LabelMorale, LabelBody, LabelLog, LabelClass, and the new
LabelPip), so seven of the nine sites that print it are even with no screen edit. The Tavern's two sites print the
figure through variations that cannot carry the bar: LabelSmall is pinned to carry no fallback
(tests/unit/test_theme_kit.gd:447-449) and LabelName is the plain name face. Each is a one-token change to the
variation the morale line already has elsewhere. Tabs in Tavern.gd.

## 1. game/screens/Tavern.gd:527

The seat card's morale line ("starts at 46 |||||.....", the line `Tavern --fixture --set=emoji_free=true` shows) goes
onto `LabelPip`: LabelSmall's size, colour and LINE HEIGHT with the bar font in front and nothing else (CRITIC-G09;
the plan's Tavern acceptance line is this edit). Nothing on the card moves at any scale: the line is exactly as
tall as LabelSmall's, and with the option off it draws the same system colour emoji it draws today. (The first
cut carried the face sheet too; at 150 the 36px sheet made the 20px line 36 tall and pushed Pauline_4's Look
button ~12px off the card's plate, so the sheet came off — build/shots/w4pip/crop_Tavern_seats150_before_after.png.
The authored face on this line is a Tavern-owner call: it costs the card ~11px at 150.) Seen applied through a
scratchpad preview scene: build/shots/w4pip/Tavern_emoji_handoff.png, Tavern_emoji_handoff_text150.png,
Tavern_faces_handoff.png.

old:
```
	var mrow := Widgets.label_as("starts at %d %s"
		% [m, Cards.morale_glyph(self, m)], "LabelSmall")
```
new:
```
	var mrow := Widgets.label_as("starts at %d %s"
		% [m, Cards.morale_glyph(self, m)], "LabelPip")
```

## 2. game/screens/Tavern.gd:897

The Manage row's morale line ("Bork — 87 |||||||||.") is the same line the roster, the strip and RaiderDetail print
through `LabelMorale`; on LabelName it has neither the bar nor the faces (with the option off it draws a system
colour emoji today). LabelMorale is 20px tabular Medium against LabelName's 18px Medium — the same colour, and the
row's colour override (`Palette.morale_color`) is kept. The row is a scrolling list (no fixed plate), so the
face-carrying line height costs nothing here. Seen applied: build/shots/w4pip/crop_Tavern_manage_handoff.png
(LabelName left, LabelMorale right).

old:
```
	var l1 := Widgets.label_as("%s — %d %s"
		% [r.display_name, m, Cards.morale_glyph(self, m)], "LabelName")
```
new:
```
	var l1 := Widgets.label_as("%s — %d %s"
		% [r.display_name, m, Cards.morale_glyph(self, m)], "LabelMorale")
```

## Notes (nothing to apply)

- Guildhall at 150 (`build/shots/w4pip/Guildhall_fixture_text150.png` against `before_Guildhall_text150.png`): the
  face font for a scale is one fallback shared by LabelBody/LabelLog/LabelClass/LabelMorale/LabelPip, and a Font's
  line height is its tallest font, so at 125 a 19px body line is 30 tall (was 24) and at 150 a 23px line is 36 (was
  29) — the same 1.2x the 24px face already costs a 15px line at 100, now scaled with the face. The Guildhall
  sidebar's Roster block (four LabelBody lines above the morale chart) already overran its column at 150 at HEAD
  (the chart's lower half was clipped); with the taller lines the chart is clipped entirely. A screen-owner call:
  a shorter chart at 150, or the block scrolling. Not a wave-4 file of this unit's; W4-HYGIENE's
  `test_sidebar_fit.gd` measures at 100, where nothing moved.
- `Guildhall._line_h` (Guildhall.gd:837-846) reads a variation's BASE font for the strip's pitch. The base is now
  the bar font, which carries Fira's ascent/descent at every registered size for exactly this reason
  (tests/unit/test_pip_figure.gd pins it), so no edit — but a future helper should measure a line with
  `font.get_height(size)` on the variation's `fallbacks[0]` (the text font) rather than assume the base is the text.
- RaidPrep.gd:424 (`Widgets.body`, LabelBody) and the six LabelMorale sites need nothing.
