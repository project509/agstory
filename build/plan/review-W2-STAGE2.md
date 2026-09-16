# Review — W2-STAGE2 (adversarial, against the tree) — second pass, after the repair

Reviewer: subagent, 2026-09-14 (re-review after the implementer's repair pass for the first review's
[major] A9b). Verdict at the bottom; findings written as they land. The first review's text is superseded
by this one; where a finding stands unchanged it is restated with fresh evidence.

## 1. Ownership and diff scope

`git status --porcelain` + `git diff --stat` on every owned path (2026-09-14, second pass):
- game/ui/SceneStage.gd +919 lines (1955 total; 1260 tab-led lines, 0 space-led) — the verb section
  (`_motion_scale/_beat/_facing/hit/_flash/act/_start_act/_end_act_on/_finish_act/_apply_act/_apply_act_state/_tick_acts`),
  the VFX section (`_vfx_geom/add_fx/_free_fx/_tick_fx/burst/slash/bolt/_land_bolt/_tick_trails`), `SCROLL_SHADER` +
  `add_scroll`, `_build_ember` direction/cone/preprocess, the `smoke` preset, emote bubbles + moods (`set_mood/_apply_mood`),
  speaker list/rotation (`_as_list/_place_speech`), the `backing` branch and `_speech_backing` removed, `apply_settings`
  handling for scrolls/emitters/in-flight fx. The one repair-pass line is `_place_speech`'s
  `Widgets.content_of(_speech).mouse_filter = Control.MOUSE_FILTER_IGNORE` (SceneStage.gd:1759).
- tests/unit/test_scene_stage.gd +607 lines, 63 `func test_` (was 44; the repair added
  `test_the_camp_raises_two_glyph_bubbles_whatever_the_pick`), 1370 space-led / 0 tab-led lines, 0 CR bytes (the first
  review's CRLF minor is fixed in the tree).
- game/assets/scenes/stage_camp.json: bubbles gain emote keys (sweat/zzz/note/question + one bare dots + the skull with
  mood "wipe"), `bubble_visible` 2 → 3 (the repair), `backing` gone, `speaker` [4, 11].
- stage_tavern.json: mug/mug/note/zzz, `bubble_visible` 3, `speaker` [12, 11, 6]. stage_market.json: 12 → 8 actors
  (five in the right band), six bubbles, `speaker` 4. stage_town.json: `scroll` x2 over `[0,0,1536,200]` (the repair;
  was 220), three `smoke` emitters.
- camp.json, guildhall.json, bg/camp_plate.png(.import), bg/guildhall_plate.png(.import): six ` D` in git status; not on
  disk (`ls game/assets/scenes` = the six stage_*.json; `ls game/assets/bg | grep -i "camp\|guild"` = stage_camp only).
- tools/art/patch_bubbles.py: docstring only (the example now names `stage_town 1180,40,160,140`).
All within the owned list. The two plan files (report/handoff) exist.

Changed files NOT in the owned list: game/screens/AdventureBoard.gd, Market.gd, RaidView.gd, Results.gd, Tavern.gd,
Town.gd (the other six W2 units' files) and their new test files. Grep of their diffs' added lines for this unit's new
API (`set_mood`, `.act(`, `.hit(`, `.burst(`, `.bolt(`, `add_fx`, `add_scroll`, `SAY_AIR`, `TAIL_AIR`) finds only a
W2-MARKET comment in Market.gd that mentions W2-STAGE2 by name; Town.gd has no `set_mood`/`last_result` (handoff §4 NOT
applied by this unit). No evidence this unit touched an unowned file. `aguildstory.zip` at the root is untracked and not
attributable.

Kit calls all pre-exist in the tree: `Widgets.speech_plate(text, tail_at := Vector2.INF)` (Widgets.gd:1138, builds a
child "Tail" and re-aims it on `item_rect_changed`), `speech_bubble(kind, glyph)` (:1082, sets meta `emote`, a "Glyph"
child when a texture is given — so the market's `"emote:dots"` IS a glyph bubble), `content_of` (:799), `label_as`
(:258), `TAIL_H := 8` (:73); `Icons.path/exists/at` (Icons.gd:110/123/130); all ten `grid/emote_*.png` present; the six
`fx_*` strips + `clouds_far/near.png` in game/assets/vfx with vfx.json rows.

## 2. Tests and verify --fast (observed)

`GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` run by me at 19:19 (summary in
build/shots/review2-W2-STAGE2-verify.log, the full .verify.log copied to build/shots/review2-W2-STAGE2-verify-full.log):

```
PASS  LINT OK  no cross-file class_name references in sim/ or game/
PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
PASS  PARSE_CHECK scanned 166 script(s)
PASS  16 generated file(s) agree with tools/gen_items.gd
PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING
PASS  TESTS PASSED   1806 test(s) in 86 file(s)  [40914 ms]
VERIFY OK   (exit 0)
```

Green, matching the report's repair-pass summary line for line. The runner names only failing tests, so the 63
`test_scene_stage.gd` tests are proven to have run by their expected push_warnings in the full log (unknown figure,
`no_such_strip`, orphan speaker 7, "names a speaker and none built", the two deleted scene names from
`test_the_mockup_crop_scenes_are_gone`) and by the total (1806 = the first review's 1801 + this unit's one new test +
the other units' additions). No `Failed to load`, no SCRIPT ERROR. `tools/lint_motion.sh` run standalone: `MOTION LINT OK`.

## 3. Shots re-taken and viewed

All six through the lock with §0.3's grammar (`40 1536x1024`), written to build/shots/review2-W2-STAGE2-*.png, every
one opened with Read (crops beside them, made with PIL at 3-5x):

- `Town --fixture` (review2-W2-STAGE2-Town.png; crops Town_bubbles.png at 3x, Town_platetail.png at 5x): THREE ambient
  bubbles are up — a "..." over the ranger top-left (screen ~328,150, tail on the hood), a GLYPH bubble with the blue
  sweat drop over the red-haired warrior at the fire (~616,240, tail on the head), a GLYPH bubble with the note over the
  dark-haired figure at the beds (~1118,465, tail on the head). The speaking plate "I think I'm ready for a real raid this
  time!" at (310..505, 397..471) has a dark wedge tail (rows 472..~480, tip x ~408) whose apex sits ~6-7px above the
  hooded cleric's frame top (~487) on its centre line. Two glyph bubbles + every tail on a head: A9 is met in the tree
  now (the first review's [major] is repaired). The sweat and the note glyphs still read as a small tailed bubble drawn
  inside the kit's 40x44 frame (W1-ICONS' drawing; handoff observation stands).
- `Town --fixture --set=reduced_motion=true` (review2-W2-STAGE2-Town_rm.png; crop Town_rm_bubbles.png): the same three
  bubbles at the same spots (the seeded pick is the same); 21,153 px differ from the moving shot, all in the fire /
  ember / pulse band — the world held, not a bubble change.
- `MainMenu --frames=1,60` (review2-W2-STAGE2-MainMenu.a/.b.png; crops MainMenu_skydiff.png (amplified rows 0-260) and
  MainMenu_chimneys.png (the hall stack and the east house, frame a over frame b at 3x)): rows 0-200 differ in 26,516 px
  (mean |Δ| 0.103/channel), cloud-shaped bands across the whole width; rows 200-250 differ in 0 px (the first review's
  73 px in rows 200-223 are gone — the rect is 200 rows now); rows 250+ differ in 41,067 px of which ALL BUT 13 lie
  inside the three pre-existing water shimmer rects ([0,250,190,450], [0,690,600,334], [1270,900,210,124]) or within
  140 px of the three smoke emitters — the 13 are at the harbour rect's right rim (block 896,1472), glow bleed. The
  chimney crops show a blocky grey-brown wisp rising up-right from both stacks, moved between a and b. The sky in
  frame a reads as a soft haze over the blue and the peaks, not a grey veil.
- `MainMenu --frames=1,60 --set=reduced_motion=true` (review2-W2-STAGE2-MainMenu_rm.a/.b.png): 0 differing pixels;
  `cmp` says the two files are byte-identical. The preprocessed plumes stand still in both.
- `Tavern --fixture` (review2-W2-STAGE2-Tavern.png; crop Tavern_crops.png): two mug glyph bubbles up (over the
  dark-haired figure at the left round table ~343,305 and the red-haired figure at the right table ~913,335), tails on
  the seated heads; the plate "I have killed a rat. Professionally." at (585..780, 542..615) with its tail on the figure
  seated at the foot of the long table. TOWN-26's mugs are there.
- `Market --fixture` (review2-W2-STAGE2-Market.png; crop Market_band.png at 2x): right of the ledger — the speaker
  (knight) whole under the plate "That is a lot of gold for a hat." with the tail on its head (~917,320), a figure on
  the path (~810,405), a figure by the tan stall under a "..." bubble (~1040,380, tail on it), a figure standing on the
  red tent's rug (~897,635): four whole figures in the band, the plate whole (not under the ledger).

## 4. Acceptance lines

| # | Line (00-plan §W2-STAGE2) | Verdict | Evidence |
|---|---|---|---|
| A1 | `test_hit_recoils_and_returns` | met | test_scene_stage.gd:1181; green in my verify run. SceneStage.gd:760 `hit`: ≤2px recoil (two `_beat(45)`s) + FLASH_COLOR held Motion.HIT; the test asserts ≤2px at 0.02s, on its mark and own colour at 0.5s, and the attacker-side direction. |
| A2 | `test_burst_is_one_shot_and_frees_itself` | met | :1217; green. `burst` (:1090) = GPUParticles2D `Burst_*` one_shot, explosiveness 0.9, 14 dots, lifetime Motion.BURST + `Fx_fx_burst_impact_*` additive/non-looping/NEAREST under the Overlay; both gone at 0.7s. |
| A3 | `test_reduced_motion_makes_hit_a_flash_only` | met | :1202; green. `px * _motion_scale()` and zero-length beats (:731-743, :775-781): six ticks never move the figure, flash on then off. |
| A4 | `test_a_fumble_holds_still_under_reduced_motion` (rotation 0, "!" shown) | met | :1333; green. `Overlay/Mark_<actor>` Label "!" MOUSE_FILTER_IGNORE ≥6px above the head, rotation 0.0 and position fixed through five ticks, gone after the 200ms floor. |
| A5 | `test_the_speaking_bubble_follows_its_speaker` (node "Tail", apex within 6px of the head) | met | :1423; green. Tail present, `plate.position + tail.apex` within 6px of `head_of`, on the centre line, the plate rides an `attack`; plus the repair's Pad-IGNORE assertion. Town shot: apex ~6-7px above the cleric's frame top (§3). |
| A6 | `test_a_bubble_with_an_emote_key_shows_that_icon` | met | :1492; green. Glyph texture `resource_path == Icons.path("emote","mug")`; every shipped key exists in the grid; mug in the tavern, sweat + skull in the camp; ≥2 glyph kinds per scene. |
| A7 | `test_scroll_layer_stops_under_reduced_motion` | met | :1589; green. `Scroll_N` ColorRect + SCROLL_SHADER with TIME, `motion` 1.0 → 0.0 after `apply_settings(true,false)` (:1824) and still visible; hidden under reduced effects (:1856); stage_town's two rects end at row 200. New layer = JSON key `scroll` + `add_scroll` (:1394) + apply_settings + this test. |
| A8 | the dead-file grep returns nothing | NOT met in the tree — not meetable by this unit (unchanged from the first review) | My grep: tools/probe/Kit.gd:92 (a comment) and tests/unit/test_hall_plates.gd:388 (the guard's own pattern). Neither is owned (rule 1); neither loads anything; handoff §2/§3 carry exact old→new blocks whose old text matches the tree byte for byte (Kit.gd:91-93 tabs, test_hall_plates.gd:388-389 spaces); `apply_handoff.py --dry-run` reports #1-#4 applicable and writes nothing (git status on those files unchanged). The unit's own side is complete: six ` D`, no `backing` in SceneStage or the JSON, `test_the_mockup_crop_scenes_are_gone` (:1670) pins it, no `Failed to load` in the verify log. |
| A9a | Town shot: every bubble's tail within 6px of a figure's head | met | §3 Town: the plate's tail apex ~6-7px over the cleric's hood; the "...", sweat and note tails each on a head. `test_every_ambient_bubble_hangs_over_a_head` (:1120, 4..10px) green for all 17 bubbles against the real frame geometry. |
| A9b | Town shot: at least two glyph bubbles | **met — REPAIRED** | review2-W2-STAGE2-Town.png shows the sweat and the note glyph bubbles plus one "..." (crop Town_bubbles.png). stage_camp.json: `bubble_visible` 3 over five ambient bubbles of which one is bare dots, so any 3-of-5 pick raises ≥2 glyphs; `test_the_camp_raises_two_glyph_bubbles_whatever_the_pick` (:1530) pins both the data (up ≥ 3, up − dots ≥ 2) and eight shuffles of the built camp. The rm shot shows the same three. |
| A10 | MainMenu `--frames=1,60` differs in rows 0-200 and matches elsewhere, identical under `reduced_motion` | met (same caveat as before) | §3: sky differs (26,516 px), rows 200-250 identical, below that only the three pre-existing water shimmer rects (W0-SHOT's own acceptance already has them moving — "matches elsewhere" cannot mean them) and the three chimney plumes the plan asks this unit to add, plus 13 px of harbour glow bleed. rm pair: byte-identical files. |
| A11 | Market shot ≥ 3 whole figures in the band | met | §3 Market: four whole figures right of the ledger (the speaker under its plate, the path, the tan stall under "...", the red tent's rug). `test_market_shoppers_stand_in_the_band_the_screen_shows` (:1692) pins five feet points inside plate x 980..1349 / y 300..940. |
| A12 | `test_motion.gd:139-156` green | met | Green in my run (1806/1806); the arena JSON is untouched (git status: no stage_arena_* change; cave props at fps 8; dungeon motes/pulse/light already at [905,830,120,110]/(965,870)/(965,890) from W1-STAGE — nothing was owed here). |
| S1-S6 | The six shots | met (S5 not re-taken) | Town, Town rm, MainMenu pair, MainMenu rm pair, Tavern, Market re-taken and viewed (§3). `RaidView --fixture=raid --advance=10` not re-taken by me: the plan itself says the verbs are wired by W3-RAIDVIEW2 and "here use a probe call in the test" — eleven verb tests through `from_data` are that probe; the unit's own W2STAGE2_RaidView.png exists in build/shots. |

## 5. Green line and §0.5 contracts

- Label/Button texts and node names: no asserted string changed. Test edits outside the 19 new tests are all in the
  unit's own file (28 → `SAY_AIR`, speaker-as-list, the `emote` meta lookup, one raw-newline literal escaped, the
  repair's Pad assertion) — allowed and explained (report J2). No other test file reads `say_at`/`set_lines`/`SAY_AIR`
  (grep: only test_theme_kit/test_widgets_kit, which read the kit; both green).
- §0.5 SceneStage line: `load` :232, `from_data` :240, `actor_for_class` :294, `party_state_style` :400, `place_boss`
  :419, `motion_held` :457, `place_party` :464, `DEFAULT_ARENA := "stage_arena_cave"` :100, the literal
  `func apply_settings(reduced_motion: bool, reduced_effects: bool)` at :1813; `Actor_*/Shadow_*/BossShadow/Shimmer_*/
  Pulse_*` untouched; the 44 W1 tests (back-to-front, uniforms, ≥10 rects, fps>3, actors.json geometry) green in my run.
- Indentation: SceneStage.gd 1260 tab-led / 0 space-led lines; test_scene_stage.gd 1370 space-led / 0 tab-led, LF only
  (the first review's CRLF minor is closed). Scene JSON is data.
- `create_tween`: none in SceneStage.gd (grep; `test_the_mockup_crop_scenes_are_gone` also pins it; MOTION LINT OK). No
  `focus_mode`/`FOCUS_ALL`/`grab_focus` — nothing focusable added. a11y smoke run by me after the repair
  (build/shots/review2-W2-STAGE2-a11y.log): `A11Y SMOKE PASSED 26 screen mount(s)`, no `warn`, no WARNING lines.
- Reduced-motion branching: no verb reads a GameSettings value; `_motion_scale()`/`_beat()` (:731/:739) are
  `GameSettings.motion_scale()`/`motion_duration()`'s arithmetic on the stage's own held flag — RULES §2's world-layer
  door. `add_fx`/`burst`/`bolt` test `_motion_held` for the held-frame / no-particles / zero-travel behaviour STAGE-03
  prescribes ("a single held frame at the target"); the same gate W1 already used in `_process`/`place_party`. Accepted,
  as in the first review.
- `$GODOT` outside the lock: the unit added no script that calls the engine (patch_bubbles.py is numpy/PIL, docstring-only
  diff). New PNGs: none (four deleted; no .import owed). No baked text. Nothing parented to the router host — the stage adds
  children to itself / its Overlay only. Pure black/white: no Palette token added; the `#FFFFFF`/`Color(1,1,1,1)` in the
  file are identity modulate tints and shader-base colours (one pre-existing at :379), not painted colours.
- MOUSE_FILTER_IGNORE: 20 sites — the stage, the Overlay, the "!" mark, the scroll quads, the vignette, the say plates
  and their Pads, and now the scene plate AND its Pad (:1758-1759, the repair) — so the rebuilt scene plate matches
  `say_at`. The kit's Tail is a Node2D (Widgets.gd:120); bolt ghosts/particles are Node2Ds.
- Handoff format: four `## N. <path>:<line>` headings each with one old/new fenced pair, in the target file's indentation
  (Palette.gd:136 one line; Kit.gd:91-93 tabs; test_hall_plates.gd:388-389 four spaces; Town.gd:201 two tabs, and the
  new block's two lines keep two tabs / three tabs). Every old block matches the tree verbatim (checked with `sed`/`cat -A`);
  `apply_handoff.py --dry-run` reports #1-#4 applicable and wrote nothing. The withdrawn §5 is a heading the tool's
  `## N.` grammar skips. `last_result.cleared()` exists (sim/core/RaidSim.gd:178) and is what RaidView.gd:1483
  `_is_wipe()` already uses. The W2-MARKET observation now says speaker 4 (matches the JSON).
- Minor, new: under reduced motion a verb calls `set_process(true)` and `_process` never turns itself off again once the
  act/fx/flash lists drain (the held branch of `apply_settings` only decides at apply time; :1877-1925). Pre-existing
  shape (`say_at` did the same in W1); a per-frame no-op, no contract touched.
- Minor, unchanged: `BURST_KINDS`/`slash`/`bolt` name W1-VFX's `fx_*` keys inside SceneStage while §0.2 says scene JSON
  is the only place that names strips. The report's R5 reasoning (the only owned data dir is guarded as "only bare stages
  ship"; vfx.json is W1-VFX's) is sound; all six strips exist and `add_fx` guards with `ResourceLoader.exists`. Suggested
  home: a `kinds` block in vfx.json, W3-RAIDVIEW2/orchestrator.

## 6. Judgement calls vs §6

- J1 (verbs on the stage clock, no Tween): verified — `Widgets.tween` returns null outside a tree, every acceptance test
  is a `from_data` stage outside a tree, RULES §2 names `apply_settings` as the world layer's door. Not a designer
  question.
- J2 (tail apex 6px above the frame top, SAY_AIR 28 → 14): the plan's Findings say `head_of − (0,28)`, its Acceptance
  says "within 6px of the head"; the unit took the acceptance's number. Q04 reserves the bubble FILL and the
  emote→event mapping and explicitly lands "geometry, tails and the ten glyphs". Not reserved.
- J3 (the market crowd in W2-MARKET's right band): the plan's own W2-MARKET text says W2-STAGE2 moves five shoppers
  "into that band"; handoff-W2-MARKET confirmed it; the shot shows it. Fine.
- J4/R7 (skull via `set_mood`, the Town.gd edit in the handoff, the rule = `not last_result.cleared()`): correct — Town.gd
  is W2-TOWN's this wave; TOWN-26's "after a wipe" is read as the screen family's own existing wipe rule (RaidView's WIPE
  stamp), so WIPE/SOFT_WIPE/ATTRITION all skull. That is a consistency choice inside the plan's text, not a §6 question.
- J5 (every emitter `speed_scale 0` under reduced motion): consistent with docs/13 §13; suites green. Not reserved.
- J6/J7/R3 (bolt/burst kinds; the 1s-vs-2s diff measure; the 200-row crop): tooling-level; fine.
- R1 (`bubble_visible` 3 on the camp, the cleric's "..." → zzz): a data change inside TOWN-26's own vocabulary
  (mug, sweat, skull, zzz …) with no morale-band/event mapping added — decorative placement, reversible; the only
  state-driven emote (wipe → skull) is TOWN-26's own text. Q04's reserved half (fill, mapping) is untouched.
- R5 (strip keys stay in code): recorded, minor (§5).
- No canon file touched; no canon number; no canon-guard test weakened (test_motion, test_hall_plates untouched by this unit).

## Verdict

**PASS** — the first review's one [major] (A9b) is repaired in the tree and the repair is what the report says it is:

- stage_camp.json `bubble_visible` 3 and the cleric's bubble `emote:zzz`; `test_the_camp_raises_two_glyph_bubbles_whatever_the_pick`
  pins it; my own `Town --fixture` shot (review2-W2-STAGE2-Town.png) shows two glyph bubbles (sweat, note) plus one "...",
  every tail on a head, the plate's tail 6-7px over the cleric.
- `verify.sh --fast` run by me: VERIFY OK, 1806/1806, PARSE_CHECK 166, ART CHECK 0 DIFFERS, MOTION LINT OK; a11y smoke
  26 mounts / no warn; MainMenu pair moves only in the sky, the pre-existing shimmer rects and the plumes, rows 200-250
  identical, the rm pair byte-identical; tavern mugs and market figures as claimed; the dead files gone with the two
  remaining grep hits (unowned) handed off as exact, applicable edits.
- No false claims found in the repair-pass report: every number I could re-measure agrees or differs only by the frame
  (the report's 49 residual harbour-rim px are 13 in my pair — same place, same cause).

Not met and not meetable by the unit (unchanged): A8's grep still hits tools/probe/Kit.gd:92 and
tests/unit/test_hall_plates.gd:388 — both unowned, both handed off (§2/§3), applied by the orchestrator between waves.

Minors (no verdict weight): strip keys named in SceneStage's BURST_KINDS/slash/bolt (guarded, all exist; suggested
vfx.json `kinds` block); `_process` stays on after a held verb finishes; emote glyphs read as a bubble inside the kit's
bubble (W1-ICONS' drawing, correctly handed off to W3-KIT2/Icons); the RaidView `--advance=10` shot was not re-taken by
this review (no verb is wired until W3-RAIDVIEW2).

Handoffs for the orchestrator after the wave: §1 Palette FLASH_HIT/MARK_FUMBLE; §2 Kit.gd:92 comment; §3
test_hall_plates.gd:388 guard; §4 Town.gd:201 `set_mood("wipe")` on `not last_result.cleared()`.
