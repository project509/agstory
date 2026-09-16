# Handoff — W1-CHROME

Exact edits in files this unit does not own. One edit per heading; `old:` then `new:`; indentation matches the
file (Frame.gd, Widgets.gd, SceneStage.gd, Tavern.gd use TABS; Bar.gd and Badge.gd use FOUR SPACES). Every token
named here exists in game/ui/Palette.gd after this unit's commit (same hexes as the literals they replace, so no
pixel moves — tests/unit/test_theme_kit.gd `test_handoff_tokens_carry_the_hexes_they_replace` pins each one).
Line numbers are from the tree on 2026-09-14 13:50; W1-KIT/W1-FRAME/W1-STAGE are editing some of these files in
the same wave, so match by the `old:` text, not the number. Every file below already preloads Palette as
`Palette` (verified by grep), so no import line is needed.

After applying: `grep -n 'Color("' game/ui/Frame.gd game/ui/Bar.gd game/ui/Widgets.gd game/ui/Badge.gd game/ui/SceneStage.gd game/screens/Tavern.gd`
should print nothing (that is W4-HYGIENE's lint line, KIT-10).

## 1. game/ui/Frame.gd:192

old:
```
		p.seam.color = Color("020406")
```
new:
```
		p.seam.color = Palette.GROUND_SEAM
```

## 2. game/ui/Frame.gd:215

old:
```
		p.shared_rule.color = Color("3B3532")
```
new:
```
		p.shared_rule.color = Palette.HEADER_RULE
```

## 3. game/ui/Frame.gd:225

old:
```
	var bronze := Color("7A6152")                   # 01 §1: 2px bronze
```
new:
```
	var bronze := Palette.HEADER_DIVIDER            # 01 §1: 2px bronze
```

## 4. game/ui/Frame.gd:269

old:
```
		edge.color = Color("463E3E")                # 01 §1: border core x=208
```
new:
```
		edge.color = Palette.EDGE_RAIL_CORE         # 01 §1: border core x=208
```

## 5. game/ui/Frame.gd:438

old:
```
			g.modulate = (Color("F9F3E0") if is_active else Color("8A8A8A"))
```
new:
```
			g.modulate = (Palette.INK_NAV_GLYPH_ACTIVE if is_active else Palette.INK_NAV_GLYPH)
```

## 6. game/ui/Frame.gd:453

old:
```
			Color("F0E3D2") if is_active else Color("9B9A9D"))
```
new:
```
			Palette.INK_NAV_ACTIVE if is_active else Palette.INK_NAV)
```

## 7. game/ui/Frame.gd:641

old:
```
		rule.color = Color("988880")
```
new:
```
		rule.color = Palette.HEADER_RULE_LIT
```

## 8. game/ui/Bar.gd:40

old:
```
const RIM := Color("2C3F5C")
```
new:
```
const RIM := Palette.BAR_RIM
```

## 9. game/ui/Bar.gd:41

old:
```
const TRACK := Color("010D1B")
```
new:
```
const TRACK := Palette.BAR_TRACK
```

## 10. game/ui/Bar.gd:49

old:
```
            return [Color("F24A50"), Color("B01A28")]
```
new:
```
            return [Palette.BAR_BOSS_LIGHT, Palette.BAR_BOSS]
```

## 11. game/ui/Bar.gd:51

old:
```
            return [Color("F54841"), Color("811725")]
```
new:
```
            return [Palette.BAR_HP_FILL_LIGHT, Palette.BAR_HP_FILL]
```

## 12. game/ui/Bar.gd:91

old:
```
        draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color("0B1118"))
```
new:
```
        draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Palette.INK_BAR_OUTLINE)
```

## 13. game/ui/Bar.gd:92

old:
```
        draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("F5F1E8"))
```
new:
```
        draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.INK_BAR)
```

## 14. game/ui/Widgets.gd:828

old:
```
	var s := Theme_.flat(Color("11181E"), Palette.rarity_color(rarity), 2, 4)
```
new:
```
	var s := Theme_.flat(Palette.SURFACE_SLOT, Palette.rarity_color(rarity), 2, 4)
```

## 15. game/ui/Widgets.gd:118

The tail's colours (building_callout / speech_plate). JUDGEMENT CALL, recorded in report-W1-CHROME.md: the plan
names SURFACE_CALLOUT for the fill, but SURFACE_CALLOUT (#08080C) is a PRE-EXISTING token — the base under the
tinted success callouts (PanelCalloutDanger/Caution/Positive) — and "add only, never rename" forbids repointing
it. The 9-slice the tail hangs from (callout_plate.png / bubble_plate.png) is filled #040E18, which is
Palette.SURFACE_BUBBLE; a tail in SURFACE_CALLOUT would be a visibly different navy under the plate it opens into.
So: fill → SURFACE_BUBBLE, rim → EDGE_CALLOUT (== EDGE_BUBBLE, #605A54, the plate's outer line). The comment
lines change with the code so the file stops promising a retoken that has landed.

old:
```
## the tail. Colours are the kit's tokens until W1-CHROME's handoff retokens
## them (SURFACE_CALLOUT / EDGE_CALLOUT).
class Tail extends Node2D:
	var apex := Vector2.ZERO
	var base_x := 0.0
	var base_y := 0.0
	var fill: Color = Palette.SURFACE_PANEL
	var rim: Color = Palette.EDGE_SLATE
```
new:
```
## the tail. Colours are the dark plate's own (W1-CHROME: callout_plate.png's
## fill and outer line), so the tail and the 9-slice read as one object.
class Tail extends Node2D:
	var apex := Vector2.ZERO
	var base_x := 0.0
	var base_y := 0.0
	var fill: Color = Palette.SURFACE_BUBBLE
	var rim: Color = Palette.EDGE_CALLOUT
```

## 16. game/ui/Badge.gd:48

`@export` defaults must be constant expressions; `Palette` is a `const ... = preload(...)` in Badge.gd, so
`Palette.BADGE_DANGER` qualifies (the same form Bar.gd's consts above use). If the parser refuses it on this
engine build, keep the literal and add `## = Palette.BADGE_DANGER` beside it — the token exists either way.

old:
```
@export var color: Color = Color("E44434"):
```
new:
```
@export var color: Color = Palette.BADGE_DANGER:
```

## 17. game/ui/SceneStage.gd:1138

old:
```
			draw_rect(Rect2(8 + i * 6, 11, 3, 3), Color("#3B2F27"))
```
new:
```
			draw_rect(Rect2(8 + i * 6, 11, 3, 3), Palette.INK_BUBBLE_DOTS)
```

## 18. game/screens/Tavern.gd:278

Tavern's hand-rolled selected-card rim is now the theme's `PanelRoundSelected` (KIT-10). The minimal edit keeps
the override and swaps the literal; the better edit (W2-TAVERN's call) is
`card.theme_type_variation = "PanelRoundSelected"` in place of the two override lines.

old:
```
			Theme_.flat(Color("020C14"), Palette.EDGE_STEEL, 1, 6, 0))
```
new:
```
			Theme_.flat(Palette.SURFACE_CARD, Palette.EDGE_STEEL, 1, 6, 0))
```

## Note (repair pass, no edit): the morale face takes the line's ink

Not an edit — a fact for W1-KIT / the designer. A bitmap FontFile glyph is drawn modulated by the Label's
font colour, so the pixel face on a morale line that Cards.gd:113 colours with `Palette.morale_color(m)` is
saturated by DANGER / CAUTION / POSITIVE (measured on the Guildhall shot; report-W1-CHROME.md "Known property").
If the authored shading should survive, keep the LINE in TEXT_TITLE and colour the number alone (Cards.gd, W1-KIT),
or rule the band ink intended (Q17). Nothing in Fonts.gd/Theme.gd can switch it off.
