# handoff-W3-OPTIONS — edits this unit needs in files it does not own

Unit: W3-OPTIONS (LoadSave.gd, Settings.gd, tests/unit/test_options_layout.gd). Nothing below is applied by the unit.
Shape: `## N. <path>:<line>` then an `old:` fenced block and a `new:` fenced block, one edit per heading.

## 1. game/ui/Theme.gd:445

Two things Settings.gd names as strings and lets fall back until this lands (rule §0.2: a theme variation name falls back harmlessly). (a) `ButtonChip` gains `hover_pressed` so a lit (toggled) chip under the pointer keeps its gold plate instead of the engine default — Settings' engaged values are toggled chips (HALL-17); the screen sets a per-button override today, which this makes redundant. (b) `ButtonSecondaryLit` — CRITIC-G16's "secondary-lit" for Settings' Apply (`Settings.APPLY_VARIATION`): 06 §7.2's engaged tint on the secondary silhouette, through `_button()` so it carries the focus ring. Tabs.

old:
```
	t.set_color("font_pressed_color", "ButtonChip", Palette.ACCENT_GOLD)
```
new:
```
	t.set_color("font_pressed_color", "ButtonChip", Palette.ACCENT_GOLD)
	# A toggled chip under the pointer draws `hover_pressed` (W3-OPTIONS): the
	# lit plate stays lit, gold text and all, instead of the engine's default.
	t.set_stylebox("hover_pressed", "ButtonChip", chip_p)
	t.set_color("font_hover_pressed_color", "ButtonChip", Palette.ACCENT_GOLD)
	# The lit secondary (CRITIC-G16, W3-OPTIONS): Settings' Apply — a commit
	# that spends no time, gold or raider, so not crimson. 06 §7.2's engaged
	# tint on the secondary silhouette: the bronze plate a step up at rest,
	# brighter still on hover, the inverted plate pressed, dimmed disabled.
	var lit_n := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(1.22, 1.22, 1.22))
	var lit_h := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(1.4, 1.4, 1.4))
	var lit_p := pressed(tex("btn_secondary_pressed.png", 14, 14, 14, 14, 8, Color(1.22, 1.22, 1.22)))
	var lit_d := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(0.5, 0.5, 0.5))
	_button(t, "ButtonSecondaryLit", "Button", lit_n, lit_h, lit_p, lit_d,
		Fonts.ui_semibold(), Type.BODY, Palette.TEXT_TITLE, Palette.TEXT_TITLE,
		Palette.TEXT_DISABLED, scale)
```

## Notes for W3-KIT2 / the kit (nothing to apply)

- `Widgets.reasoned` puts its "Reason" Label UNDER the control. A table row (Settings) and a row of three buttons sharing one reason (LoadSave) both need the Label elsewhere in the row — Settings moves it into the description column so every row keeps ROW_H 40, LoadSave prints the row's distinct phrases once under the button row. Both do it by `box.remove_child(box.get_node("Reason"))`. A `placement` argument on `reasoned` ("under" | "beside" | "none" — return the Label for the caller) would let both screens drop that code.
- `Widgets.reasoned`'s Label does not wrap; Settings gives it `COL_NOTE_W` + autowrap the way the Tavern and Market do. A `width` argument is the one-door form (handoff-W2-TAVERN says the same).
- Volume pips are five `Widgets.bar(1|0, 1, "mana", "", Vector2i(12, 10))`; a `Widgets.pips(lit, total, kind)` would be the kit form if a third screen wants one.
