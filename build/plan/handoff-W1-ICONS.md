# Handoff — W1-ICONS (key `W1-ICONS`)

Everything below is outside my ownership (`tools/aseprite/gen_icons.lua`, `game/ui/Icons.gd`,
`game/assets/ui/icons/**`, `game/assets/ui/faces_30.png`/`faces_36.png` (+json/import),
`art/src/ui/icons/**`, `tests/unit/test_icons.gd`). Each edit is `## N. <path>:<line>` with an
`old:` and a `new:` block. Nothing here was applied by the unit.

(appended as the unit goes)

The one file outside my ownership that must learn about the grid is `tests/unit/test_art_sources.gd`
(W0-MANIFEST): it walks the TOP LEVEL of game/assets/ui/icons against a hand-transcribed emit list, so
the new grid lives in `icons/grid/` (report J1) and the hygiene for that directory is done by
`tests/unit/test_icons.gd` until these five edits land. They make the walk read the generator's own
manifest (`icons/grid/icons.json`, written by gen_icons.lua and byte-gated by verify 2b) instead of
growing the transcribed list by 130 names. Line numbers are as of 2026-09-14.

## 1. tests/unit/test_art_sources.gd:20

old:
```
const WALK := ["res://game/assets/ui/icons", "res://game/assets/enemies", "res://game/assets/portraits"]
```
new:
```
const WALK := ["res://game/assets/ui/icons", "res://game/assets/ui/icons/grid", "res://game/assets/enemies", "res://game/assets/portraits"]
```

## 2. tests/unit/test_art_sources.gd:24

old:
```
const GEN_ICONS_PATHS := ["res://tools/aseprite/gen_icons.lua", "res://tools/art/gen_icons.lua"]
```
new:
```
const GEN_ICONS_PATHS := ["res://tools/aseprite/gen_icons.lua", "res://tools/art/gen_icons.lua"]
## W1-ICONS: the generator writes its own emit list (name, role, key, file, cell) and verify.sh
## stage 2b byte-gates it, so the grid is read from there rather than transcribed by hand.
const GEN_ICONS_MANIFEST := "res://game/assets/ui/icons/grid/icons.json"
```

## 3. tests/unit/test_art_sources.gd:113

old:
```
    var ranks: Dictionary = _json(ENEMIES_JSON).get("ranks", {})
```
new:
```
    var ranks: Dictionary = _json(ENEMIES_JSON).get("ranks", {})
    var emitted := {}
    for row in _json(GEN_ICONS_MANIFEST).get("files", []):
        emitted[String(row.get("name", ""))] = true
    assert_true(emitted.has("class_warrior") and emitted.has("rank_unknown"), "gen_icons' manifest is empty")
```

## 4. tests/unit/test_art_sources.gd:124

old:
```
            if dir.ends_with("icons"):
                sourced = base in GEN_ICONS or base in GEN_ITEMS
```
new:
```
            if dir.ends_with("icons") or dir.ends_with("grid"):
                sourced = base in GEN_ICONS or base in GEN_ITEMS or emitted.has(base)
```

## 5. tests/unit/test_art_sources.gd:135

old:
```
    assert_true("res://game/assets/ui/icons/rank_unknown.png" in seen, "the icons walk saw nothing")
```
new:
```
    assert_true("res://game/assets/ui/icons/rank_unknown.png" in seen, "the icons walk saw nothing")
    assert_true("res://game/assets/ui/icons/grid/class_warrior.png" in seen, "the grid walk saw nothing")
```

## Notes for the orchestrator (no edit)

- `art/ref/manifests/all.json`'s twelve `mech_<key>` rows (`reproducible: false`, "W1-ICONS regenerates
  them") are now true in the other direction: the files are generator output. The rows can stay
  (test_art_sources' `test_mech_icons_are_recorded_as_not_reproducible` counts them) or W4-HYGIENE can
  drop them once edit 4 sources mech_* from the manifest.
- `Cards.BADGE_FOR_KIND` -> `log_<kind>` and every `Widgets.log_row` / `speech_bubble` /
  `building_callout` consumer is W3-KIT2 / wave 2 wiring, per the plan; nothing here asks for it early.
