# Review — W1-VFX (adversarial, against the tree)

Reviewer: second-pass adversarial review, 2026-09-14. Verifies the TREE, not the report.
Contract: 00-plan.md "### W1-VFX", §0.5; RULES.md. Report: build/plan/report-W1-VFX.md; handoff: build/plan/handoff-W1-VFX.md.

## 1. Ownership / git state
- `git status --porcelain` on the owned set: M `tools/aseprite/gen_fire.lua`, M `art/src/vfx/fire_{camp,hearth,torch}.aseprite`,
  M `game/assets/vfx/fire_{camp,hearth,torch}.png`; new `tools/aseprite/gen_vfx.lua`, `tools/art/gen_clouds.py`,
  `tests/unit/test_vfx_assets.gd` (+ `.uid`), 7 `art/src/vfx/fx_*.aseprite`, 9 new PNGs + 9 `.import` under `game/assets/vfx/`,
  `game/assets/vfx/vfx.json`. `ember.png`/`light_soft.png` mtime 10:00 but byte-identical to HEAD (git clean) — regenerated, unchanged.
- Read in full: the `gen_fire.lua` diff (flame() replaced by tongue_mask/edt/paint_bands; `smoke` ramp entry and the `scale`
  arg dropped; RAMP hexes unchanged), `gen_vfx.lua` (467 lines), `gen_clouds.py` (158), `test_vfx_assets.gd` (289), `vfx.json`.
- Unowned files changed in the tree (cannot attribute; other units own them): `art/src/ui/**`, `game/assets/ui/**`,
  `game/assets/scenes/stage_*.json` (x5), `game/core/ScreenRouter.gd`, `game/screens/{Facilities,Guildhall,LoadSave,RaidView,
  RaiderDetail,Settings}.gd`, `game/ui/{Bar,Cards,Fonts,Frame,Palette,SceneStage,Theme,Type,Widgets}.gd`, `game/ui/Icons.gd`,
  `tests/unit/test_scene_stage.gd`, new `tests/unit/test_{frame_header,hall_plates,icons,theme_kit,widgets_kit}.gd`,
  `tools/art/{gen_wordmark,preview_scene}.py`, `tools/aseprite/gen_{icons,ui,wipe}.lua`, `tools/probe/Kit.gd`, `aguildstory.zip`.
  Grep of every unowned diff for `clouds_|fx_*_|vfx.json|gen_vfx|gen_clouds|add_fx|add_scroll`: NO hits — nothing of this
  unit's leaked into a file it does not own. The report's files_changed list names only owned files + report/handoff/shots.
- `stage_tavern.json` in the tree already reads `"frame_w": 64` (line 23) — W1-STAGE has landed the fix handoff §1 asks for;
  §1 is written as conditional ("apply only if ... still says 48") so it is moot, not wrong.
- Verdict for §1: no ownership breach found.
- Re-verified by the resumed reviewer (this pass; the tree has moved since — AdventureBoard.gd, Tavern.gd, Badge.gd,
  test_art_sources.gd are now also modified by other units): `git status --porcelain` on the owned set is exactly
  3 M fires (.png + .aseprite) + M gen_fire.lua + the new files above; `git diff` of every tracked unowned file grepped
  for `clouds_|fx_*_|vfx.json|gen_vfx|gen_clouds|add_fx|add_scroll` → no hit; a tree-wide grep of those names hits only
  the four owned files and report-W1-ICONS.md (which merely records "gen_vfx.lua has landed beside mine").
- `.import` sidecars: all 14 under game/assets/vfx carry a unique uid (each grep-counts to 1 across game/), the nine new
  ones' `[params]` block is byte-identical to fire_hearth.png.import's; `.godot/imported` holds 18 fx_/clouds_ entries
  (9 ctex + 9 md5) — Godot accepted them.
- lib.lua is git-clean: every `L.*` symbol gen_fire.lua / gen_vfx.lua call (`mask_new/mset/mget/mask_is_edge/
  mask_ellipse/glow_mask/chan/mix/rgba/strip/write_text/save_ase/save_png`) exists in the wave-0 library.

## 2. Tests and verify.sh --fast (observed)
- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (this reviewer, 2026-09-14, log in the
  scratchpad `verify_fast_1.log`): rc 1.
  `PASS class cache regenerated` · `PASS LINT OK` · `PASS MOTION LINT OK` · `PASS PARSE_CHECK scanned 160 script(s)` ·
  `PASS 16 generated file(s) agree with tools/gen_items.gd` ·
  `FAIL a generated PNG and its generator disagree` — the 20 listed DIFFERS are ALL `game/assets/ui/**` (btn_*, bubble_plate,
  callout_*, chip_chamfer, cork_tile, cta_*, emote_frame, faces*.png/.json, icons/arrow_left) = W1-CHROME / W1-ICONS mid-edit;
  no `game/assets/vfx` line ·
  `FAIL unit tests` — `TESTS FAILED 1/1710 failing`: `test_scene_stage.gd :: test_reduced_motion_holds_lights_and_bubbles`
  (lights/bubbles/speech under held motion; test_scene_stage.gd:961-1001 reads no fire strip, no vfx PNG — W1-STAGE's file,
  W1-STAGE's in-flight work). `test_vfx_assets.gd` is in the 1710 and is NOT in the failure list → its 9 tests pass.
- Shared art check re-run alone under the lock (`tools/with_godot_lock.sh ./tools/build_art.sh --check`, 20 s): rc 0,
  `gen_fire / gen_icons / gen_items / gen_ui / gen_vfx / gen_wipe` listed,
  `ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING` / `ART CHECK OK`. So the 2b red inside my
  verify run was other units' generators moving under it (or the shared-directory race the handoff §3 describes), not
  this unit.
- Race-free proof for the owned files: gen_vfx.lua + gen_fire.lua re-run with `--script-param out=<private scratch dir>`
  and `gen_clouds.py --out <same dir>` → `private check: 27 files, 0 differ` (13 runtime files + 2 clouds + 12 .aseprite
  sources, byte-identical to the tree); `python tools/art/gen_clouds.py --check` → `agree` x2, `GEN_CLOUDS CHECK OK`.
- PIL measurement of every PNG against vfx.json (scratchpad `measure.py`, run before it was overwritten by another
  agent's file of the same name — the numbers below are from my run): 14 PNGs = 14 rows, none unnamed, none missing;
  every row `width == frames*frame_w`, `height == frame_h`; fire_hearth 512x56, fire_camp 320x52, fire_torch 96x24;
  EVERY fire frame: 5 colours, 1 component (limits ≤6 / ≤4); the six fx strips: 3-5 colours each, 0 pure-white and
  0 pure-black opaque pixels in every authored strip (light_soft.png's 2828 white px are the pre-existing alpha mask,
  git-clean); clouds_far 1536x220 alpha max 144 rows 2..184, wrap-column diff 0.069 == adjacent-column diff 0.069;
  clouds_near alpha max 176 rows 1..209, wrap 0.000 == adjacent 0.000 → periodic in x. Frame-to-frame changed pixels
  are non-zero for every animated strip.
- `.aseprite` sources inspected headlessly (Aseprite Lua, scratchpad `vfxrev_inspect.lua`): fx_spark_hit 32x32 4 frames
  tag `play[1..4]` 62 ms; fx_slash_arc 64x48 x5 `play`; fx_bolt_arcane 24x48 x4 `play`; fx_bolt_trail 8x2 x1; fx_heal_sparkle
  32x32 x6 `play`; fx_burst_impact 64x64 x5 `play`; fx_poof_smoke 48x48 x5 `play`; fire_hearth 64x56 x8 `burn[1..8]` 111 ms;
  fire_camp 40x52 x8 `burn`; fire_torch 16x24 x6 `burn` 125 ms — real frames + tag + durations, as A1/A2 claim.

## 3. Shots re-taken (all viewed with Read)
- `tools/with_godot_lock.sh bash <scratch>/vfxrev_shots.sh` (one lock hold, §0.3 grammar):
  `"$GODOT" --path . --script res://tools/shot.gd -- res://game/screens/Tavern.tscn build/shots/review-W1-VFX-Tavern.png 40 1536x1024 --fixture --frames=1,20`
  → `SHOT OK` .a.png / .b.png; `... Town.tscn build/shots/review-W1-VFX-Town.png 40 1536x1024 --fixture` → `SHOT OK`.
- `review-W1-VFX-Tavern.a.png` whole: the tavern with the fireplace at screen ~(860..940, 100..190); the flame is a clean
  banded shape — dark rim, orange, yellow, cream core — blooming through the stage glow, no speckle. a vs b: 44,369 px
  differ (hearth crop 800,60,1000,210 alone: 8,688 px).
- `review-W1-VFX-fire_crops_x3.png` (my crops: Tavern hearth frame 1 | frame 20 | Town campfire 600,250,780,400, 3x):
  frame 1 is a three-lick silhouette seated on the andirons, frame 20 a taller shape with a tall right tongue — the same
  five bands, a different lick; the campfire in the stone ring is three licks with yellow interiors and cream cores at
  the seat, party around it. Banded, painted, no loose pixels. Note: stage_tavern.json in the tree now cuts at
  `frame_w: 64` (W1-STAGE landed it), so the hearth is no longer clipped as the first agent's A9 note described.
- `review-W1-VFX-Town.png` whole: the hub on the camp plate, campfire banded at ~(650..700, 300..380); everything else in
  the frame is other units' in-flight work.
- `review-W1-VFX-strips_x4.png` (my PIL sheet of the ten strips at 4x): spark = cream dot → gold 7-ray starburst → rays
  fly and break into tip sparks; slash = a steel-blue/cyan/white crescent revealed from the trailing end over frames 1-3,
  thick at the leading (lower-right) end, thinning to a dotted afterimage in 4-5 — the 200° sweep (A0 225 → A1 425 in the
  code); bolt = a periwinkle teardrop with an off-centre lighter core, orbiting sparks, wobbling tail, the 8x2 trail
  beneath; heal = white/blue four-point glint opening on the axes then the diagonals, three motes rising; burst = pink-white
  core with twelve ragged red spikes hollowing into a ring, spikes fading to dull magenta; poof = grey-blue two-tone cloud
  with a lit top that swells, rises and Bayer-dithers away. Fires: hearth 8, camp 8, torch 6 frames, each one outlined
  silhouette of 2-3 licks, yellow interior, cream cores low, no speckle. No glyph or text anywhere in any strip.
- `review-W1-VFX-clouds.png` + `review-W1-VFX-clouds_seam_x2.png` (my composite of clouds_far+near over stage_town rows
  0..260 at offset 0 and rolled by 768 so the wrap seam sits mid-frame, plus the raw layers on a mid-blue ground): thin
  cirrus streaks in the top band, soft puffs drifting over the peaks; no seam visible at x=768 in the rolled band; no text.
  The near layer's veil reaches down over the mountains/castle band (rows ~60..200 — its `fade_from` is row 100 while the
  plate's open sky ends near row 60); cosmetic, and the consumer's rect/modulate (W2-STAGE2 `add_scroll`) decides it.
- `build/shots/W1-VFX_hearth_refkit.png` (the implementer's A8, 728x360, viewed): left Concept 1 (330,380,90,90) at 4x,
  right the same crop with the painted flame dimmed and fire_hearth frame 0 seated on the logs at 4x. The concept's fire
  is taller and wispier with graduated glow; ours is a flatter five-band pixel flame with the same band order (dark
  red rim → red-orange → orange → yellow → cream) on the same seat line. A real side-by-side; the acceptance asks for
  the comparison, not a match.

## 4. Acceptance lines
| Line | Verdict | Evidence |
|---|---|---|
| A1 gen_vfx.lua: six strips via L.strip, seeded LCG, picked up by the glob; sizes 32x32x4 / 64x48x5 (200°, thick leading edge) / 24x48x4 + 8x2 / 32x32x6 / 64x64x5 / 48x48x5; ramps 02 §9.1 / 07 §4.2 | MET | gen_vfx.lua:153-156 `emit` → `L.strip(..., {tag="play"})`; rng(101..606) only; PIL: 128x32, 320x48, 96x48, 8x2, 192x32, 320x64, 240x48; .aseprite frames/tags listed in §2; `gen  gen_vfx.lua` in the ART CHECK run; ramps: ARCANE/IMPACT/SLASH hexes are 02 §9.1:294-297 verbatim, FIRE is the muzzle-flash ramp + one mid orange, HOLY = 07 §4.2:489 "white core, #9FD8FF mid, #3B6FE0 rim" with #F4FBFF for the core, SMOKE grey-blue 3-step |
| A2 gen_fire.lua re-authored: 2-3 filled banded tongues, jitter on the outline only, ≤6 colours, ≤4 components, PNG dims identical | MET | diff read in full: `tongue_mask` (outline extents ±1 every third row, never at the tip), union mask, `paint_bands` edge/tongue/body/hot/core; PIL: every frame 5 colours / 1 component; 512x56, 320x52, 96x24 |
| A3 gen_clouds.py: 1536x220 RGBA, periodic in x, seeded numpy fBm, palette from stage_town's sky | MET | gen_clouds.py:35 SKY_RECT (600,0,1536,200) sampled off the plate, :61-95 periodic value-noise fBm, seeds 7011/7023; PIL: wrap diff == adjacent diff (0.069/0.069, 0.000/0.000); light capped 244 |
| A4 vfx.json beside the strips, name → frames/frame_w/frame_h/fps/tag | MET | game/assets/vfx/vfx.json, 14 rows, written through `L.write_text` (gen_vfx.lua:464) so --check gates it |
| A5 test_vfx_assets.gd: exists / width == frames*frame_w / height / fire geometry / colours+components / clouds | MET | tests/unit/test_vfx_assets.gd (289 lines, 9 tests, four-space, extends tests/TestCase.gd); in the suite (1710) and absent from the failure list; the pins are constants (the file's own comment says so — the acceptance wording "pinned to the scene JSONs' declarations" is loose, the numbers match stage_*.json) |
| A6 .import for every new PNG; no `Failed to load` for game/assets/vfx | MET | 14/14 sidecars, unique uids, params byte-identical to fire_hearth's, dest hash == md5 of the res:// path; `.godot/imported` has the 18 ctex/md5; every `load()` in the test resolved; the Tavern/Town shots load the fires (the boot itself is skipped by --fast — the only vfx paths any scene names are the three fires) |
| A7 build_art.sh --check 0 DIFFERS 0 MISSING, generators=6 | MET | observed under the lock: `ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING` / `ART CHECK OK`; private out= regeneration: 27 files, 0 differ |
| A8 refkit side-by-side vs Concept 1 (330,380,90,90) | MET | build/shots/W1-VFX_hearth_refkit.png viewed, described in §3 |
| A9 Tavern --fixture --frames=1,20 and Town --fixture show banded flames | MET | my re-takes review-W1-VFX-Tavern.{a,b}.png, review-W1-VFX-Town.png, crops in §3 |
| A10 verify.sh --fast green; lint_motion OK | NOT MET — not by this unit | my run: lint/motion-lint/parse/gen_items PASS; 2b FAIL on game/assets/ui/** only (W1-CHROME/ICONS mid-edit; a solo re-run is green), 3/8 `1/1710 failing` = test_scene_stage.gd::test_reduced_motion_holds_lights_and_bubbles (W1-STAGE's file, no vfx in it). The unit left A10 unticked, honestly. It could not have met it. |
| Green line: no game code; fire geometry unchanged so scene JSONs and `test_every_prop_frame_w_divides_its_strip` hold | MET | no game/**/*.gd in the owned diff; that test (test_scene_stage.gd:881) is not in the failure list with the 512/320/96-wide fires |

## 5. Contract checks (§0.5 / RULES)
- No Label/Button text or node name touched: the unit ships no game code (grep of the owned diff: only .lua/.py/.gd-test/assets).
- Indentation: test_vfx_assets.gd 0 tab-led lines (four-space, tests/ rule); Lua/Python are not GDScript.
- `create_tween` / `reduced_motion` / `class_name` / `_ready`: none in any owned file (grep).
- `$GODOT` outside the lock: neither gen_vfx.lua, gen_fire.lua nor gen_clouds.py invokes Godot; the report's engine runs
  all cite `with_godot_lock.sh`.
- Baked text: none in any of the 9 new PNGs (strips sheet + cloud composite viewed at 4x/2x).
- `.import` sidecars: 9/9 new PNGs, LF, unique uids (§1).
- Router host: N/A (no scene code). Overlays: N/A.
- Pure black/white: 0 opaque pure-white / pure-black px in every authored strip and both clouds (PIL); light_soft.png is
  the untouched wave-0 alpha mask.
- Handoff edits: §1 old `"frame_w": 48,` → the tree already reads 64 at stage_tavern.json:23 (W1-STAGE applied it; §1 is
  self-declared conditional → moot). §2 `tools/build_art.sh:100` old line `run_generators "$CHECK"` is exactly line 100;
  the printf escapes survive as literal `\033`/`\n` (cat -A). §3 old line `CHECK="build/artcheck"` is exact but sits at
  line **97**, not 96 (heading off by one — minor; the only other mentions of the path are comments). build_art.sh is
  git-clean — nothing applied by the unit.
- No canon file touched (docs/_source clean in `git status`).
- Line endings of the new text files: LF.

## 6. Judgement calls vs §6
- Sizes, names and ramps: taken from the plan/PIPE-02 (CRITIC-C04 "PIPE's names win"), not chosen. No per-class VFX
  mapping (Q18 / PIPE-02 "mapping") was decided — no consumer wiring exists.
- Fire: sparks dropped from the strip (the ember emitters carry them) so ≤4 components holds; tongue boxes re-tuned; both
  inside STAGE-12's Fix (b), which needs no designer.
- Clouds: fade rows / alpha maxima / 3-tone shading are authoring choices the plan leaves to the unit; no §6 question
  covers cloud strips (Q08 is DoF/vignette, which this unit did not touch).
- The resume's calls (skip a third verify run; route build_art.sh changes through the handoff; rewrite the handoff via
  Write after a heredoc collapse) are process calls, not design rulings.
- Nothing reserved for the designer was decided.

## Verdict
**PASS** — every acceptance line the unit could meet is met against the tree; A10 is red only in other units' files
(test_scene_stage.gd, game/assets/ui/**), and the unit said so rather than ticking it. No ownership breach, no contract
breach, no designer-reserved call.

Minors (none blocking):
1. handoff §3's heading says `tools/build_art.sh:96`; the `CHECK="build/artcheck"` line is 97 (old string exact).
2. Until handoff §2 lands, `gen_clouds.py` is gated by nothing in verify.sh (only test_vfx_assets' geometry/periodicity
   checks); the plan's Goal wants the clouds under `build_art.sh --check`, a file the unit does not own — correct route,
   but the orchestrator must apply §2 for the Goal to be true.
3. clouds_near stays at full alpha to row 100 and fades to row 220, veiling the mountain/castle band; W2-STAGE2's rect
   and modulate should cap it — cosmetic.
4. The implementer's status summary to the orchestrator says the gate "is green now at 1710 tests"; observed here:
   `1/1710 failing` (W1-STAGE's test) and a 2b red on ui/** in the same run. The report body itself leaves A10 unticked
   and says why, so this is a summary overstatement, not a report falsehood.
5. A5's acceptance text says the fire geometry is "pinned to the scene JSONs' declarations"; the test pins constants
   (its comment says so). The numbers agree with stage_camp/tavern.json; wording only.
6. A scratchpad name collision: another agent overwrote `measure.py` in the shared scratchpad after my run — my numbers
   were captured first; process note for the orchestrator (session scratchpads are not isolated between agents).
