# Handoff — W4-LIFE (key `W4-LIFE`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Nothing here is applied by the unit.
Observations (no edit) are labelled as such.


## 1. tools/build_art.sh:114

The windmill sails (`game/assets/vfx/life/sail_a.png`, `sail_b.png`) and the patched aerial
plate (`game/assets/bg/stage_town.png`) are written by `tools/art/patch_plate.py` (PY — it
cannot go through lib.lua's out= prefix) and are byte-gated only when the art check runs its
`--check` (regenerate in memory from `art/src/bg/stage_town_raw.png`, compare the three
files, exit 1 on DIFFERS / MISSING) beside gen_actors.py's. Nobody owns build_art.sh this
wave; until this lands the three files are gated by the script's own `--check`, which is
green (W4-LIFE report).

old:
```
  if ! python tools/art/gen_actors.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/gen_actors.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
```
new:
```
  if ! python tools/art/gen_actors.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/gen_actors.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
# The windmill sails and the patched aerial plate (W4-LIFE): the same byte gate.
if [ -f tools/art/patch_plate.py ]; then
  printf '  gen  %s (py)\n' "patch_plate.py"
  if ! python tools/art/patch_plate.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/patch_plate.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
```

## 2. game/screens/MainMenu.gd:103

The `_build()` comment W3-MENU rewrote says the sail motion is still owed; the sails turn
now (`rotor` in stage_town.json) and the gulls cross (`flyers`). tests/unit/
test_menu_lockup.gd:209-214 pins "water shimmer is on" and the string "M4B-VFX-01", both of
which the new text keeps (the item still owes the airship). Tabs.

old:
```
	# (stage_town.json's three shimmer rects), the sky's cloud drift and the
	# chimney smoke landed with W2-STAGE2, and the windmill's sail motion is
	# still M4B-VFX-01's (RULES-05). It has no figures at any scale we own
```
new:
```
	# (stage_town.json's three shimmer rects), the sky's cloud drift and the
	# chimney smoke landed with W2-STAGE2, the windmill sails turn and the gulls
	# cross since W4-LIFE (`rotor` / `flyers`), and only the airship is still
	# M4B-VFX-01's (RULES-05). It has no figures at any scale we own
```

## Observation (no edit) — W4-HYGIENE / audit M4B-VFX-01, BUILD_STATE

STAGE-14's four motions are all on the aerial now: water shimmer (W1-STAGE), cloud drift and
chimney smoke (W2-STAGE2), the windmill sails and the gulls (this unit). What M4B-VFX-01
still owes is spec 09 §5 row 8's airship (160x140 of sky patched behind a cut — the
`patch_plate.py` recipe would do it as a second ROTORS-style table entry, or a `props` crop
like the camp banners). The LIES row keyed on stage_town.json can say so.

## Observation (no edit) — tools/aseprite/gen_vfx.lua / vfx.json

The five life strips live in `game/assets/vfx/life/` with their own `life.json` (written by
gen_fire.lua; the sails declared there, as vfx.json declares the clouds), because
tests/unit/test_vfx_assets.gd fails any PNG in game/assets/vfx that vfx.json does not name
and vfx.json is gen_vfx.lua's (W1-VFX). If the orchestrator would rather they sat at
`game/assets/vfx/<name>.png` as 00-plan names them: move the seven files (five PNGs + their
.import, minus life.json), add these rows to gen_vfx.lua's `vfx.json` block, repoint the
`LIFE_OUT` prefix in gen_fire.lua, the `OUT` in patch_plate.py, `SceneStage.LIFE`, the six
scene-JSON paths and the `LIFE` const in test_scene_stage.gd, and drop the life.json test:

```
row("flame_lantern", 3, 6, 8, 8, "burn", "tools/aseprite/gen_fire.lua")
row("banner_wave", 4, 40, 80, 6, "wave", "tools/aseprite/gen_fire.lua")
row("banner_wave_b", 4, 40, 88, 6, "wave", "tools/aseprite/gen_fire.lua")
row("gull", 3, 12, 6, 5, "fly", "tools/aseprite/gen_fire.lua")
row("sail_a", 1, 96, 96, 0, "", "tools/art/patch_plate.py")
row("sail_b", 1, 96, 96, 0, "", "tools/art/patch_plate.py")
```
