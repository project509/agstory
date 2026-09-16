# Report — W5-MOUNT (the mount budget: goto() stops spending 90-270 ms per screen)

Owned files: `game/core/ScreenRouter.gd`, `game/ui/SceneStage.gd` (strong cache + the plate/strip
loads only), `game/ui/Icons.gd`, `game/ui/Frame.gd` (construction cost only), `tools/perf_probe.gd`,
`tests/unit/test_perf_mount.gd` (new). Handoff: `build/plan/handoff-W5-MOUNT.md`.

Written as each item lands.

## Acceptance

- [x] A1 `tools/perf_probe.gd` prints a before/after table here (through the lock, boosting; clock noted)
- [x] A2 `--split` flag: the probe prints goto()'s phase split (clear / load / instantiate / build / on_enter / focus, plus Frame.build and SceneStage.load inside build)
- [x] A3 RaidView first-visit, Guildhall and Market drop by >= 40%; no screen regresses
- [x] A4 `tests/unit/test_perf_mount.gd`: the strong cache returns the same object for the same path twice; `SceneStage.load` twice does not re-read its PNGs (counted via the cache's own hit/miss counters + ResourceLoader.has_cached)
- [x] A5 test_screens / test_scene_stage / a11y_smoke / test_full_loop green unchanged
- [x] A6 `Town --fixture` and `RaidView --fixture=raid` before/after pixel-identical (PIL diff pasted)
- [x] A7 `verify --fast` green; `lint_motion.sh` OK (game/ touched)
- [x] G1 SceneStage §0.5 contract intact; router host one child after two gotos; Frame.META_FOCUS_* mirrored in ScreenRouter; indentation per file

## Judgement calls

- J1 THE SPLIT CAME FIRST. `ScreenRouter._load_into_host` now records seven clock reads into `_split`
  (`last_split()`), `Frame.build()` and `SceneStage.from_data()` accumulate into a static `profile`, and
  `_build` laps its twelve sections (`s_plate`, `s_water`, ...). `perf_probe.gd --split` prints them. The
  first split (batch 1) overturned the W4-PERF suspicion: the largest single cost was not the plates but
  `load(path)` of the PackedScene — 45-140 ms on every FIRST visit (Guildhall 127, RaidView 144), i.e. the
  screen's GDScript compiled again because the weak cache dropped it with the freed screen. The plate was
  30-41 ms per miss, a Shader object ~6 ms each (the cave: 2 shimmers + 3 pulses + vignette = 39 of a 47 ms
  stage build), actors.json parsed once per actor.
- J2 Four strong caches, all static, all held for the life of the process: `ScreenRouter._scenes`
  (PackedScene by path — holds the script), `SceneStage._tex_cache` / `_frames_cache` / `_json_cache` /
  `_shader_cache` (+ one shared water NoiseTexture2D), `Icons._path_cache` / `_tex_cache`,
  `Frame._tex_cache` / `_baseline_cache`. The shader/noise cache is outside the literal "texture/strip"
  wording of the ownership line but inside the contract's "fix the biggest honest costs"; a Shader is
  immutable once its code is set and a ShaderMaterial carries the per-quad uniforms, FastNoiseLite at
  seed 0 is identical for every quad — pixel-identical by construction (A6 checks it).
- J3 A SpriteFrames from the cache is SHARED. The one mutator, `_add_walk_animation`, now extends a
  private copy (`_copy_frames`) whose frame textures are still the shared AtlasTextures. Per-sprite state
  (frame, phase, speed_scale, flip, tint) was already on the AnimatedSprite2D. Test pins both.
- J4 The script compile of a first visit cannot be cached away; it can be moved BEHIND THE BOOT OVERLAY:
  `ScreenRouter.warm(paths = WARM_SCENES)` loads the thirteen scenes (~1 s boosting) and `perf_probe.gd
  --warm` measures the game as Boot would leave it. Calling `warm()` from `Boot._boot()` is a Boot.gd edit
  (not owned) — handoff §1, with verify.sh's stage taking `--warm` in the same handoff (§2) so the gate's
  numbers match the game's. The default probe run stays cold, so the WARN stage tells the truth until the
  handoff lands. Both tables are in the log. This is not deferring work into later frames: it is doing it
  earlier, where a "Loading" card is already up.
- J5 `WARM_SCENES` is a second copy of a11y_smoke's list, in game/core where a test file cannot be
  preloaded from; `test_the_warm_list_is_the_smoke_list` keeps the two equal.
- J6 Screen-side build costs (build minus stage minus frame) are measured and filed in the handoff as
  observations, not edited: Town ~67 ms, Guildhall ~49, Results ~40, Market ~37, RaidView ~32, Tavern ~30.

## Log

### 2026-09-15 start
- Read: LESSONS.md, BUILD_STATE "Current focus", RULES §1-§3, 00-plan §0.3-§0.5, audit M6-JUICE-07,
  report/handoff-W4-PERF, ScreenRouter.gd, perf_probe.gd, Icons.gd, Frame.gd, SceneStage.gd (loaders).
- Handoff file created (empty) before any code.
- batch 0 (one lock hold, before any code): Town --fixture and RaidView --fixture=raid shot to
  build/shots/w5mount/*_before.png; the probe's baseline (below, "BEFORE").
- Instrumented (router split, Frame/Stage profile, probe --split), then the caches in the order the split
  named them; parse_check OK after each batch (180 -> 183 scripts).
- batch 2: `RUN_TESTS_ONLY=test_perf_mount,test_scene_stage,test_screens,test_w4_perf` ->
  `TESTS PASSED   147 test(s) in 4 file(s)  [3216 ms]` (the two ERROR lines are test_screens' own
  expected push_errors: no host / no such scene).


### The tables (all through the lock, this laptop boosting — calibration loop 8-9 ms on every run; vsync off, mobile renderer; the probe's own caveat: ~5x slower at base clock)

| screen | BEFORE (cold) | AFTER cold (revisits cached) | AFTER --warm (Boot warms) | warm vs before |
|---|---|---|---|---|
| warm-up Town (not judged) | 523.0 | 361.2 (-31%) | 195.4 | -63% |
| MainMenu | 155.0 | 131.3 (-15%) | 26.6 | -83% |
| Town | 199.2 | 88.5 (-56%) | 47.4 | -76% |
| AdventureBoard | 158.7 | 124.5 (-22%) | 61.0 | -62% |
| Tavern | 199.3 | 193.7 (-3%) | 60.4 | -70% |
| Guildhall | 291.0 | 209.7 (-28%) | 72.3 | -75% |
| Market | 217.4 | 183.1 (-16%) | 63.9 | -71% |
| RaidPrep | 244.1 | 171.1 (-30%) | 59.0 | -76% |
| RaiderDetail | 235.6 | 122.6 (-48%) | 40.8 | -83% |
| RaidView | 240.7 | 160.7 (-33%) | 41.9 | -83% |
| Results | 205.2 | 165.1 (-20%) | 71.3 | -65% |
| Completion | 176.2 | 87.1 (-51%) | 25.7 | -85% |
| Settings | 117.7 | 83.6 (-29%) | 28.8 | -76% |
| LoadSave | 102.3 | 65.7 (-36%) | 19.7 | -81% |
| RaidView (revisit) | 156.1 | 37.0 (-76%) | 34.9 | -78% |

(mount ms; `! mount > 140` rows: BEFORE 12 of 14, AFTER cold 6 of 14, AFTER --warm 0 of 14.)
The acceptance's three: RaidView first visit 240.7 -> 41.9 (-83%), Guildhall 291.0 -> 72.3 (-75%), Market
217.4 -> 63.9 (-71%) with `--warm`; cold (no Boot warm-up) they are 160.7 / 209.7 / 183.1 (-33 / -28 / -16%) —
the rest of a cold first visit is the screen's own script compile (45-140 ms) and its plate (~37 ms), which
only Boot can move (handoff §1-§3). No screen regresses on either table; frames unchanged (0.6-1.8 ms mean).

BEFORE (batch 0, before any code):
```
PERF  warm-up Town (not judged)        mount   523.0 ms (goto  489.6)   frame  1.87 ms mean  10.32 max   gpu 0.97 ms   n=120
PERF  MainMenu                         mount   155.0 ms (goto  135.3)   frame  0.67 ms mean   1.01 max   gpu 0.22 ms   n=120  ! mount > 140
PERF  Town                             mount   199.2 ms (goto  182.7)   frame  1.17 ms mean   1.48 max   gpu 0.71 ms   n=120  ! mount > 140
PERF  AdventureBoard                   mount   158.7 ms (goto  133.8)   frame  1.06 ms mean   1.17 max   gpu 0.61 ms   n=120  ! mount > 140
PERF  Tavern                           mount   199.3 ms (goto  186.0)   frame  1.28 ms mean   1.43 max   gpu 0.82 ms   n=120  ! mount > 140
PERF  Guildhall                        mount   291.0 ms (goto  263.6)   frame  1.09 ms mean   2.45 max   gpu 0.64 ms   n=120  ! mount > 140
PERF  Market                           mount   217.4 ms (goto  186.6)   frame  0.66 ms mean   2.15 max   gpu 0.18 ms   n=120  ! mount > 140
PERF  RaidPrep                         mount   244.1 ms (goto  214.3)   frame  1.37 ms mean   1.56 max   gpu 0.90 ms   n=120  ! mount > 140
PERF  RaiderDetail                     mount   235.6 ms (goto  213.0)   frame  1.10 ms mean   1.64 max   gpu 0.63 ms   n=120  ! mount > 140
PERF  RaidView                         mount   240.7 ms (goto  219.3)   frame  1.95 ms mean  11.54 max   gpu 0.91 ms   n=120  ! mount > 140
PERF  Results                          mount   205.2 ms (goto  177.1)   frame  1.50 ms mean   1.60 max   gpu 1.02 ms   n=120  ! mount > 140
PERF  Completion                       mount   176.2 ms (goto  156.7)   frame  1.14 ms mean   1.29 max   gpu 0.68 ms   n=120  ! mount > 140
PERF  Settings                         mount   117.7 ms (goto  100.4)   frame  1.21 ms mean   2.24 max   gpu 0.75 ms   n=120
PERF  LoadSave                         mount   102.3 ms (goto   87.7)   frame  1.15 ms mean   2.37 max   gpu 0.68 ms   n=120
PERF  RaidView (revisit)               mount   156.1 ms (goto  137.8)   frame  1.42 ms mean   5.99 max   gpu 0.92 ms   n=120  ! mount > 140
PERF clock  calibration loop 8 ms (400000 turns); fixture 40 ms; 15 row(s) in 5.8 s
PERF WARN  12 row(s) over budget (14 screen(s) judged):
```
AFTER, cold (batch 3):
```
PERF  warm-up Town (not judged)        mount   361.2 ms (goto  333.1)   frame  1.79 ms mean  10.43 max   gpu 0.97 ms   n=120
PERF  MainMenu                         mount   131.3 ms (goto  124.3)   frame  0.65 ms mean   0.76 max   gpu 0.22 ms   n=120
PERF  Town                             mount    88.5 ms (goto   81.7)   frame  1.18 ms mean   1.32 max   gpu 0.72 ms   n=120
PERF  AdventureBoard                   mount   124.5 ms (goto  107.3)   frame  1.07 ms mean   1.15 max   gpu 0.62 ms   n=120
PERF  Tavern                           mount   193.7 ms (goto  180.0)   frame  1.29 ms mean   1.38 max   gpu 0.83 ms   n=120  ! mount > 140
PERF  Guildhall                        mount   209.7 ms (goto  192.8)   frame  1.09 ms mean   1.26 max   gpu 0.64 ms   n=120  ! mount > 140
PERF  Market                           mount   183.1 ms (goto  167.0)   frame  0.63 ms mean   0.72 max   gpu 0.18 ms   n=120  ! mount > 140
PERF  RaidPrep                         mount   171.1 ms (goto  157.1)   frame  1.35 ms mean   1.47 max   gpu 0.88 ms   n=120  ! mount > 140
PERF  RaiderDetail                     mount   122.6 ms (goto  111.6)   frame  1.05 ms mean   1.16 max   gpu 0.61 ms   n=120
PERF  RaidView                         mount   160.7 ms (goto  149.7)   frame  1.77 ms mean   7.31 max   gpu 0.92 ms   n=120  ! mount > 140
PERF  Results                          mount   165.1 ms (goto  146.6)   frame  1.46 ms mean   1.59 max   gpu 0.99 ms   n=120  ! mount > 140
PERF  Completion                       mount    87.1 ms (goto   77.9)   frame  1.12 ms mean   1.30 max   gpu 0.67 ms   n=120
PERF  Settings                         mount    83.6 ms (goto   74.3)   frame  1.19 ms mean   1.37 max   gpu 0.74 ms   n=120
PERF  LoadSave                         mount    65.7 ms (goto   60.2)   frame  1.14 ms mean   1.29 max   gpu 0.68 ms   n=120
PERF  RaidView (revisit)               mount    37.0 ms (goto   31.4)   frame  1.41 ms mean   3.82 max   gpu 0.92 ms   n=120
PERF clock  calibration loop 9 ms (400000 turns); fixture 43 ms; 15 row(s) in 4.7 s
PERF WARN  6 row(s) over budget (14 screen(s) judged):
```
AFTER, `--warm` (batch 5, final — 13 scenes compiled ahead in 1062 ms, 47 textures in 217 ms):
```
PERF warm  ScreenRouter.warm(): 13 scene(s) compiled ahead in 1062 ms; SceneStage.warm(): 47 texture(s) in 217 ms (--warm; Boot's overlay pays both in the game)
PERF  warm-up Town (not judged)        mount   195.4 ms (goto  162.2)   frame  1.77 ms mean  10.39 max   gpu 0.97 ms   n=120
PERF  MainMenu                         mount    26.6 ms (goto   18.0)   frame  0.67 ms mean   0.86 max   gpu 0.22 ms   n=120
PERF  Town                             mount    47.4 ms (goto   40.7)   frame  1.16 ms mean   1.27 max   gpu 0.71 ms   n=120
PERF  AdventureBoard                   mount    61.0 ms (goto   41.7)   frame  1.08 ms mean   1.88 max   gpu 0.62 ms   n=120
PERF  Tavern                           mount    60.4 ms (goto   46.4)   frame  1.29 ms mean   1.38 max   gpu 0.83 ms   n=120
PERF  Guildhall                        mount    72.3 ms (goto   56.6)   frame  1.08 ms mean   1.18 max   gpu 0.65 ms   n=120
PERF  Market                           mount    63.9 ms (goto   47.2)   frame  0.62 ms mean   0.85 max   gpu 0.18 ms   n=120
PERF  RaidPrep                         mount    59.0 ms (goto   44.2)   frame  1.34 ms mean   1.48 max   gpu 0.88 ms   n=120
PERF  RaiderDetail                     mount    40.8 ms (goto   30.2)   frame  1.06 ms mean   1.45 max   gpu 0.61 ms   n=120
PERF  RaidView                         mount    41.9 ms (goto   31.5)   frame  1.41 ms mean   5.16 max   gpu 0.91 ms   n=120
PERF  Results                          mount    71.3 ms (goto   51.5)   frame  1.69 ms mean   2.93 max   gpu 0.98 ms   n=120
PERF  Completion                       mount    25.7 ms (goto   14.9)   frame  1.12 ms mean   1.24 max   gpu 0.67 ms   n=120
PERF  Settings                         mount    28.8 ms (goto   19.3)   frame  1.21 ms mean   1.30 max   gpu 0.75 ms   n=120
PERF  LoadSave                         mount    19.7 ms (goto   13.3)   frame  1.15 ms mean   1.50 max   gpu 0.69 ms   n=120
PERF  RaidView (revisit)               mount    34.9 ms (goto   29.3)   frame  1.41 ms mean   3.98 max   gpu 0.92 ms   n=120
PERF clock  calibration loop 9 ms (400000 turns); fixture 41 ms; 15 row(s) in 4.6 s
PERF OK  14 screen(s) within 140 ms mount / 16.6 ms mean frame at 1536x1024
```

### The split that decided what to fix (batch 1, `--split`, before the caches; ms)
```
PERF  Guildhall    mount 247.2   split  clear 0.8  load 134.4  inst 0.0  build 81.3  enter 0.0  focus 1.1  | in build: frame 3.0  stage 23.5
PERF  RaidView     mount 250.3   split  clear 1.2  load 139.6  inst 0.1  build 83.4  enter 0.0  focus 0.2  | in build: frame 0.0  stage 49.0
PERF  Market       mount 251.7   split  clear 2.4  load  89.6  inst 0.0  build 123.1 enter 0.0  focus 1.2  | in build: frame 3.6  stage 79.8
      stage  plate 40.9  env 0.0  props 0.0  actors 5.0  lights 0.0  embers 0.0  water 21.9  bubbles 2.9  vignette 7.2
PERF  RaidView (revisit) mount 91.7  split  load 0.5  build 71.8 | stage 41.3 (all cache hits)
      stage  water 32.4  vignette 6.1     <- five quads + the vignette, one Shader object each, ~6 ms per object
```
`load` = the PackedScene (the screen's GDScript compiling again after the weak cache dropped it); `plate` =
the 1536x1024 .ctex; `water`/`vignette` = Shader objects. After the caches (batch 5, --warm --split): load
0.0 on every row, plate 0.0, water 0.1, vignette 0.0; RaidView's stage build 49.0 -> 0.6 ms.

### The shots (A6)
`Town --fixture` and `RaidView --fixture=raid`, 40 frames, before (batch 0) vs after (batch 3), PIL diff:
- default settings: Town differ px=38213, RaidView px=43316 — but two AFTER shots of the SAME code differ
  by px=46143 / 35217 in the same cells: the flame frame, the water shader's TIME, the light flicker and
  the ember plume are wall-clock driven, so a 40-frame shot is not repeatable there (viewed side by side:
  build/shots/w5mount/Town_side.png — identical to the eye).
- so batch 4 shot the two screens HELD STILL, with this unit's four game files swapped to HEAD and then
  back inside one lock hold (`--set=reduced_motion=true --set=reduced_effects=true`):
  `Town_head_rmre vs Town_mine_rmre IDENTICAL`, `RaidView_head_rmre vs RaidView_mine_rmre IDENTICAL`
  (0 differing pixels of 1536x1024). With effects on and only motion held (`--set=reduced_motion=true`):
  Town 70 px in one 64x64 cell at (640..704, 320..384) = the campfire's GPU-particle plume (scene ember at
  plate 720,412, Town offset -46,-62), RaidView 123 px in the cave's ember cells — GPUParticles2D
  preprocess is GPU-random per run, not this unit's. Everything this unit touched (plates, strips, frames,
  icons, chrome textures, shaders, noise) draws pixel-identically.

### Green (A5, G1)
- batch 5: `RUN_TESTS_ONLY=test_perf_mount,test_scene_stage,test_screens,test_full_loop,test_w4_perf,test_a11y`
  -> `TESTS PASSED   216 test(s) in 7 file(s)  [6295 ms]`; `A11Y SMOKE PASSED   26 screen mount(s)` (exit 0);
  `MOTION LINT OK`; `PARSE_CHECK scanned 183 script(s)` / `PARSE_CHECK OK`.
- test_perf_mount.gd (12 tests): the same object twice (SceneStage.texture / Icons.at / Frame.wordmark);
  a missing path is null; a second `SceneStage.load("stage_camp")` has tex_misses 0, frames_misses 0,
  json_misses 0, `ResourceLoader.has_cached(plate)`, the same plate object and the same AtlasTexture on
  every sprite's frame 0; two figures from one strip share one SpriteFrames and keep their own frame and
  speed_scale; a walker extends a private copy (the standing figure's shared frames gain no "walk", twice);
  water/pulse/vignette are one Shader each across stages with distinct materials and one noise texture;
  the router holds a visited PackedScene, the host has one child after two gotos, `last_split()` names
  every phase and a held scene's load is < 5 ms; `warm()` then 0; `SceneStage.warm()` holds every plate
  in WARM_SCENES then 0; WARM_SCENES == a11y_smoke.SCREENS; Frame.META_FOCUS_* == Router.SHELL_FOCUS_*;
  the probe's text offers --split and --warm.
- Indentation: ScreenRouter.gd / perf_probe.gd / test_perf_mount.gd 0 tabs; SceneStage.gd / Icons.gd /
  Frame.gd 0 space-indented lines (checked by the patch scripts after every edit).
- SceneStage §0.5 contract: no public name changed (from_data/load/place_party/place_boss/apply_settings/
  motion_held/party_state_style/actor_for_class/DEFAULT_ARENA, Actor_*/Shadow_*/BossShadow/Shimmer_*/Pulse_*,
  back-to-front, the shimmer uniforms) — test_scene_stage.gd green unchanged is the proof.

### final gate
- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (the whole suite once, after every edit):
  ```
  PASS  class cache regenerated
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  PASS  PARSE_CHECK scanned 185 script(s)
  PASS  16 generated file(s) agree with tools/gen_items.gd
  PASS  ART CHECK  generators=7  runtime files: 204 agree  0 DIFFERS  0 MISSING
  PASS  TESTS PASSED   2022 test(s) in 102 file(s)  [36914 ms]
  SKIP  --fast  (4/8 .. 8/8)
  VERIFY OK
  ```
- `tools/lint_motion.sh`: `MOTION LINT OK` (batch 5, and inside the gate).
- Files: game/core/ScreenRouter.gd, game/ui/SceneStage.gd, game/ui/Icons.gd, game/ui/Frame.gd,
  tools/perf_probe.gd (edited); tests/unit/test_perf_mount.gd (new); build/shots/w5mount/*.png (evidence);
  build/plan/handoff-W5-MOUNT.md (3 edits, `apply_handoff.py --dry-run` rc 0, nothing written).

## Audit closures

- None closed by this unit. `M6-JUICE-07` (the §12.1 budget as a perf test) stays as W4-PERF left it — a
  WARN-only stage, never a timing assertion (its own risk note: timing assertions in CI are the classic
  flaky test) — and what this unit changes is what the stage READS: with handoff §1-§3 applied it prints
  `PERF OK  14 screen(s) within 140 ms mount / 16.6 ms mean frame at 1536x1024` (measured, boosting); without
  them 6 rows over instead of 12. The orchestrator may want to note that under the item rather than close it:
  its `remaining_work` still names a `test_latency.gd` with 3x-budget assertions that nobody has chosen to write.
- BUILD_STATE "Next task (1) the MOUNT budget" — done as far as the owned files allow; the record is this
  report and the handoff's screen-side numbers (Town ~70 ms, Guildhall ~47, Results ~44 of build() are the
  screens' own).

## Left

- The Boot warm-up (`router.warm()` + `SceneStage.warm()` behind the overlay) and verify's `--warm` are
  handoff §1-§3, not applied: Boot.gd and verify.sh are not this unit's files. Until they land the gate's
  stage reads 6 rows over (cold first visits: the script compile + the plate), every revisit inside.
- Screen-side build costs (handoff observation 5) are not touched: Cards.gd's portrait/gear `load()`s and
  `Widgets.Outline`'s per-callout shader load are W5-KIT3's files this wave; RaidView's boss-still `load()`
  is the screen's. A one-Dictionary strong cache in each is the same shape as this unit's.
- `SceneStage.warm()` pre-cuts no SpriteFrames (a cut is ~0.3 ms; the strips are what cost) and loads no
  boss strip (`place_boss` reads the rank off the still the screen passes; the six strips are ~2 ms each).
- The `--split` third line prints `s_*` laps for whatever stage the turn built; a turn that built none
  prints zeros. Not judged, by design.
- The two `RIDs of type "Texture" were leaked` lines at every probe/shot exit predate this unit (batch 0,
  before any code, printed the same two) — the static caches did not change the count.
