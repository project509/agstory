# Handoff — W1-VFX

Edits this unit needs in files it does not own. Nothing here has been applied. Each heading is one exact edit.
(Appended as the unit progresses.)

## 1. game/assets/scenes/stage_tavern.json:17

The hearth strip has always been 8 frames of 64x56 (512x56 on disk; unchanged by W1-VFX and pinned by
tests/unit/test_vfx_assets.gd), but the tavern declares `frame_w: 48`, so SceneStage cuts ten 48px slices
through the 64px frames: the right tongue is clipped and the last two slices are the seam of two frames. The
plan gives W1-STAGE this exact edit ("stage_tavern.json frame_w: 64"); it is recorded here too so it cannot
be lost if that unit's file lands without it. Apply only if W1-STAGE's version of the file still says 48.

old:
```
   "frame_w": 48,
```
new:
```
   "frame_w": 64,
```

## 2. tools/build_art.sh:100

W1-VFX's Goal says the cloud layers are "gated by `build_art.sh --check`", but that script globs only
`tools/aseprite/gen_*.lua`; `tools/art/gen_clouds.py` (PY, numpy fBm) is byte-reproducible and carries its own
`--check` (`GEN_CLOUDS CHECK OK`, 0.9 s), which nothing in verify.sh runs today. This edit folds it into the same
gate without touching the `generators=N` count (the plan pins that at 6 Lua generators). build_art.sh is a wave-0
file (W0-LIB) that no wave-1 unit owns. Apply as-is; `python` is the interpreter tools/art/*.py already use.

old:
```
run_generators "$CHECK"
```
new:
```
run_generators "$CHECK"
# PY generators carry their own byte-check (they cannot go through lib.lua's out= prefix).
if [ -f tools/art/gen_clouds.py ]; then
  printf '  gen  %s (py)\n' "gen_clouds.py"
  if ! python tools/art/gen_clouds.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/gen_clouds.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
```

## 3. tools/build_art.sh:96

`--check` regenerates into a FIXED directory and `rm -rf`s it first, so two agents checking at once (build_art.sh
is not under the engine lock; verify.sh stage 2b calls it inside the lock but a direct `./tools/build_art.sh --check`
does not) wipe each other's output mid-run. Seen 2026-09-14 13:52: this unit's `verify.sh --fast` printed
`ART CHECK generators=6 runtime files: 4 agree 0 DIFFERS 0 MISSING` (PASS) while two direct runs minutes either
side printed `184 agree` — the find at the end simply found what the other run had not yet deleted. Had it found
none, `AGREE -gt 0` would have failed the gate for a reason no generator caused. A per-process directory removes
the race; the failure message already prints `$CHECK`, so a kept directory stays findable.

old:
```
CHECK="build/artcheck"
```
new:
```
CHECK="build/artcheck.$$"   # per-process: concurrent --check runs must not rm -rf each other (W1-VFX handoff §3)
```
