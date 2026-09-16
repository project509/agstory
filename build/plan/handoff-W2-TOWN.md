# Handoff — W2-TOWN (key `W2-TOWN`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Observations (no edit) are labelled as such.
Nothing here is applied by the unit.

(appended as the unit goes; empty means nothing was needed so far)

## 1. game/ui/Cards.gd:438

Why: KIT-08 — the hub passes `Icons.at("empty", "quill")` for the empty log; `event_log` has no glyph parameter and Cards.gd has no owner in wave 2 (W3-KIT2 / orchestrator). `Widgets.empty_state` already takes the glyph. TABS.

old:
```
static func event_log(host: Control, state, rows: int = 7, hint: String = "") -> void:
```
new:
```
static func event_log(host: Control, state, rows: int = 7, hint: String = "",
		glyph: Texture2D = null) -> void:
```

## 2. game/ui/Cards.gd:465

old:
```
		col.add_child(Widgets.empty_state("Nothing has happened yet.", null, hint))
```
new:
```
		col.add_child(Widgets.empty_state("Nothing has happened yet.", glyph, hint))
```

## 3. game/screens/Town.gd:532 (apply AFTER §1 — a fifth argument is a parse error until then; TABS)

old:
```
	Cards.event_log(host, _state, 7, "Raids and rests write here.")
```
new:
```
	Cards.event_log(host, _state, 7, "Raids and rests write here.", Icons.at("empty", "quill"))
```

## Observation (no edit) — W3-KIT2: a locked `building_callout` is three rows
Town.gd hides the kit's "Subtitle" Label on a locked plate (`find_child("Subtitle")`, no-op if the kit renames it) so the Blacksmith is the same two-row height as its neighbours (TOWN-02 acceptance) with the reason on the second row. The kit could own that: with `reason` non-empty, print the reason in the subtitle row (CAUTION) and drop the verb, or take a `locked_replaces_verb` flag — then the Town's `verb.visible = false` line goes.

## Observation (no edit) — W3-KIT2: the callout plate is 84px tall against the reference's 52-57
`build/shots/W2-TOWN-plate-vs-ref.png`: Concept 3's Tavern plate fill is 53 tall (title cap 13 at fill.y+9, subtitle cap 10 at +31 — spec 03 §3); `Widgets.building_callout` settles at 84 because the title is a full `Button` carrying the theme's Button stylebox margins (the row measures 38) over a 17px subtitle inside a 6/6 pad and an 8/8 rim. A zero-margin flat variation for the title (through `_button()` so the ring stays) would bring the plate to ~66; the pad to 4/4 to ~62. Town.gd passes nothing that depends on the height.

## Observation (no edit) — orchestrator: the `_settle_callouts` deferred pass in Town.gd
Godot fills a Control's theme-item and minimum-size caches at construction (no parent → the default theme) and refreshes them on a deferred THEME_CHANGED after the node enters the tree; a Control never shrinks below the size a layout pass gave it. The locked plate's reason row measured taller under the default theme, so it settled at 101 with a minimum of 84 (probe). Town.gd sets each plate back to its minimum on one deferred call after build. Any screen that places a kit composite whose first-pass size can EXCEED its themed size will see the same growth — worth a kit-level fix (e.g. `building_callout` deferring its own settle) when Widgets.gd is next owned.
