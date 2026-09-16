# Handoff — W3-MENU

Exact edits for files this unit does not own. One edit per heading; `old:`/`new:` fenced blocks;
`python tools/apply_handoff.py build/plan/handoff-W3-MENU.md --dry-run` must parse it.

## Observations (no edit)

- `Widgets.cta()` already carries KIT-05's two-line guard (`_guard_cta`: autowrap, ellipsis,
  `CTA_WRAP_W` 300, 70 -> 88 when wrapped). Completion consumes it as of this unit; no Widgets edit.
- Boot's card is `Widgets.panel("PanelWarm", 28)`; when W3-KIT2's `panel()` overlays the four
  `corner_ornament` icons, the boot card gets them with no change here.

## 1. project.godot:4

Why: TOWN-12 — MainMenu prints a LabelMuted version line from `application/config/version`, which
project.godot never set (export_presets.cfg carries `application/product_version="0.1.0.0"`). Until the
key exists the screen prints "Development build"; with it, "Version 0.1.0". project.godot has no owner
in wave 3 (orchestrator). Keep the two in step when the export preset's version moves.

old:
```
config/name="A Guild Story"
config/description="Manage a guild of incompetent raiders."
```
new:
```
config/name="A Guild Story"
config/description="Manage a guild of incompetent raiders."
; The version MainMenu prints bottom-left (TOWN-12). Matches export_presets.cfg's
; application/product_version; move both together.
config/version="0.1.0"
```

## Observation for W4-HYGIENE (no edit here — test_project_hygiene.gd is not this unit's)

- RULES-05: MainMenu.gd no longer says "none of which SceneStage can build". The LIES row to add:
  `["res://game/screens/MainMenu.gd", "none of which SceneStage can build", "res://game/assets/scenes/stage_town.json"]`
  (tests/unit/test_menu_lockup.gd already asserts the phrase is gone and "water shimmer is on" is there).
