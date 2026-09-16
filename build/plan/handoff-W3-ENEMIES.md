# Handoff — W3-ENEMIES (key `W3-ENEMIES`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading (build_art.sh is bash, two-space; the test is
four-space). Nothing here is applied by the unit. Observations (no edit) are labelled as such.

## 1. tools/build_art.sh:102

The regenerated townsfolk strips (STAGE-16) are gated only if the art check runs
`tools/art/gen_actors.py --check` — a byte gate since this wave (regenerate in memory, compare the
56 strips + actors.json, exit 1 on DIFFERS / MISSING) — beside gen_clouds.py's. The note that
built this unit named this as the one edit build_art.sh needs; nobody owns the file this wave.

old:
```
# PY generators carry their own byte-check (they cannot go through lib.lua's out= prefix).
if [ -f tools/art/gen_clouds.py ]; then
  printf '  gen  %s (py)\n' "gen_clouds.py"
  if ! python tools/art/gen_clouds.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/gen_clouds.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
```
new:
```
# PY generators carry their own byte-check (they cannot go through lib.lua's out= prefix).
if [ -f tools/art/gen_clouds.py ]; then
  printf '  gen  %s (py)\n' "gen_clouds.py"
  if ! python tools/art/gen_clouds.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/gen_clouds.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
# The actor strips (W3-ENEMIES): the same byte gate over game/assets/actors/**.
if [ -f tools/art/gen_actors.py ]; then
  printf '  gen  %s (py)\n' "gen_actors.py"
  if ! python tools/art/gen_actors.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/gen_actors.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
```

## 2. tests/unit/test_art_sources.gd:20

The boss animation strips live in `game/assets/enemies/anim/` (twelve PNGs: `<rank>.png` and
`<rank>_glow.png`, written by tools/aseprite/gen_boss_anims.lua, which also writes enemies.json;
`build_art.sh --check` byte-gates all of it). The hygiene walk is non-recursive, so today it does not
see them; this widens it so each strip is sourced BY NAME through the table's `strip` / `glow`
paths — the same "a PNG no table names fails here" rule, one directory further down.

old:
```
const WALK := ["res://game/assets/ui/icons", "res://game/assets/ui/icons/grid", "res://game/assets/enemies", "res://game/assets/portraits"]
```
new:
```
const WALK := ["res://game/assets/ui/icons", "res://game/assets/ui/icons/grid", "res://game/assets/enemies", "res://game/assets/enemies/anim", "res://game/assets/portraits"]
```

## 3. tests/unit/test_art_sources.gd:135

old:
```
            elif dir.ends_with("enemies"):
                sourced = ranks.has(base)
```
new:
```
            elif dir.ends_with("enemies/anim"):
                # W3-ENEMIES: a strip is sourced when a rank's row names it (gen_boss_anims.lua).
                for rank_key in ranks:
                    var rr: Dictionary = ranks[rank_key]
                    if path.ends_with("/" + String(rr.get("strip", "-"))) or path.ends_with("/" + String(rr.get("glow", "-"))):
                        sourced = true
            elif dir.ends_with("enemies"):
                sourced = ranks.has(base)
```

## Observation (no edit) — W3-RAIDVIEW2 / RaidView.gd: the boss's verbs are the stage's

`stage.hit(boss)` and `stage.act(boss, "death")` now play the strip's `hit` / `death` tags on a rank
that has them (every rank does), with the 2px recoil, the flash, the desaturate and the 12° topple
baked into the frames; the modulate flash and the procedural 45° rotation are NOT applied on top of
them. RaidView's own `modulate = party_state_style("dead").tint` write still composes (the stage
writes the same tint when the death tag starts). `stage.boss_has_tag(boss, "hit")` answers whether a
verb will be frames — RaidView need not read enemies.json for that. Under reduced motion the boss
holds idle frame 0, a hit is the flash only, a death arrives on its last frame.

## Observation (no edit) — say_at keeps ONE plate on the stage now

handoff-W2-RAIDVIEW's observation is taken as a stage rule: a new `say_at` line retires the plate
that is up, whoever said it (`test_a_new_speaker_retires_the_previous_plate`). RaidView's per-joke
calls need no change; three jokes inside one hold show the newest.
