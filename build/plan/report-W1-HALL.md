# Report — W1-HALL — the hall family stands on the bare camp

Unit: wave 1, 00-plan.md §2 "W1-HALL". Findings closed: RULES-10 (P0), HALL-01 (P0), HALL-02 (LoadSave/Settings half), HALL-16 (geometry half), HALL-18 (interim crop), STAGE-13 (screens half), TOWN-14 (operational half), CRITIC-C01, HALL-19/KIT-03 (the three hall `_chips()` copies), RULES q7 / HALL q2 (Settings inherits).
Ruling: docs/15 BL-78, art/ref/specs/09 §4.1 — hall family on bare `stage_camp`; Settings inherits the opener's stage, default `stage_camp`; `HALL_FRAMING = "same"` (Q03).
Owned: game/screens/Guildhall.gd, Roster.gd, Facilities.gd, RaiderDetail.gd, LoadSave.gd, Settings.gd, game/core/ScreenRouter.gd (`previous_path()` only), tests/unit/test_hall_plates.gd (new).
Handoff: build/plan/handoff-W1-HALL.md.

## Acceptance

- [x] `grep -rn guildhall_plate game/screens game/ui` is empty of every owned file and of game/ui; the one survivor is `AdventureBoard.gd:126`, a comment in W2-BOARD's file — the exact edit is handoff §1 and the grep is empty once the orchestrator applies it (this unit may not touch that file).
- [x] `test_hall_plates.gd`: each hall screen (Guildhall, Guildhall+Facilities, RaiderDetail, LoadSave, Settings) mounts a `SceneStage` child and no `TextureRect` points at a `_plate.png` — 8 tests, all green in the 13:58 suite run (the runner lists failures only; the file is discovered from tests/unit and is absent from the FAIL list).
- [x] Settings pushed from Town uses `stage_camp`; from MainMenu uses `stage_town`; `ScreenRouter.previous_path()` = `_stack[-2]`, "" at the root; default `stage_camp (-46,-62)` — `test_settings_inherits_the_stage_of_the_screen_beneath_it` and `test_previous_path_is_the_screen_beneath_the_current_one` green; `Settings._opener()` covers the router's build-before-append order (log, run 2).
- [x] Fixture shots of Guildhall / RaiderDetail / LoadSave / Settings show no painted human (retaken 13:53 as `build/shots/hall_*.png`, each viewed with the Read tool; described under "Shots (resume)").
- [x] LoadSave shows the fire ring and four seated actors in x 810..1138 (`hall_LoadSave.png`: ring at ≈(920,430), seated figures at ≈(850,400)/(895,330)/(960,320)/(1000,400), a fifth actor standing by the tent at ≈(930,200) — all pixel actors from stage_camp.json).
- [x] Settings shows water shimmer in y 907..1007 (`hall_Settings.png`: the stream with its rocks at x≈600..800 in the band; the live frame pair moves 203 px there, the reduced pair 0 — see the log).
- [x] `Guildhall --fixture --press=Facilities` shows the tent crop in the sidebar card (no painted bartender) — `hall_Guildhall_facilities.png`.
- [x] `Settings --fixture --set=reduced_motion=true` — camp held still: `hall_Settings_reduced.png` viewed; `--frames=20,40` pair differs in 0 pixels (the live pair differs in 272, 203 of them in the band) — the stage's `motion_held()` is the test's assertion.
- [x] refdiff vs 3 masked (`0,77,1536,649`) recorded before/after for the four screens (table under "After (resume)").
- [x] a11y_smoke 26 mounts green — `A11Y SMOKE PASSED   26 screen mount(s)` at 13:59 under the lock (Settings fixture: focusable=23 reachable=23 disabled=4; LoadSave: focusable=12 reachable=16 disabled=4; RaiderDetail: focusable=26 reachable=26; Guildhall in the sweep).
- [x] `verify.sh --fast`: every stage green except `3/8 unit tests` at `TESTS FAILED   1/1708 failing` — the one red is `test_widgets_kit.gd :: test_the_label_stamp_keeps_its_contract_and_leans` (W1-KIT's untracked test against its own Widgets.gd, mid-edit; no owned file is involved). `MOTION LINT OK`. Summary lines pasted in the log.
- [x] No Label/Button text touched (the diffs change no `.text`; the chip row's strings now come from `Frame.standard_chips`, the same literals); `Nav_*` untouched (no rail edit in any diff); SceneStage adds no focusables (`grep -c 'Button|focus_mode' SceneStage.gd` = 0; a11y counts above unchanged by the stage).

## Baseline (before) — refdiff vs concept 3, scene band masked, from build/diff (wave-0 run)

| screen | mae | rmse | structure | layout_iou | palette_div | within_8 |
|---|---|---|---|---|---|---|
| guildhall | 33.73 | 68.314 | 0.1421 | 0.0777 | 0.433 | 61.5 |
| raiderdetail | 37.857 | 70.892 | 0.1713 | 0.1031 | 0.324 | 51.53 |
| loadsave | 32.378 | 65.683 | 0.1374 | 0.0593 | 0.2933 | 58.5 |
| settings | 35.059 | 67.83 | 0.1558 | 0.0746 | 0.2763 | 51.27 |

## Judgement calls

1. **Words are dropped from the data, not hidden after the fact.** The build note says
   `stage.set_lines([])` and no bubbles. `SceneStage.set_lines([])` is a no-op (it returns on
   an empty array) and the ambient bubbles are re-shown every few seconds by the stage's own
   `_shuffle_bubbles`, so hiding nodes once would not hold. `Guildhall.bare_stage()` reads the
   scene JSON, erases `bubbles` and `speech`, and builds through `SceneStage.from_data` — a
   public seam pinned by test_scene_stage — so nothing in SceneStage.gd (W1-STAGE's file this
   wave) is touched or called privately. Every moving layer is kept.
2. **`apply_settings` is called at build time as well as by the stage's `_ready`.** Under
   the test runner and tools/ `_ready` never fires (LESSONS), so a test could not otherwise
   see the camp held still. Calling it twice is idempotent (`_motion_held` ORs).
3. **One switch, one place.** `HALL_FRAMING` and `FRAMINGS` live in Guildhall.gd (the family
   head); RaiderDetail and Settings' hall rows read `Guildhall.framing()` so Q03 flips one
   constant. "tight" is authored with TOWN-14's suggested numbers ((-120,-140), dim 0.55) but
   not measured — it is the designer's option, not a claim.
4. **Panels sit at the window's origin (HALL-16), not at (18,14).** The plan's LoadSave
   numbers are "(18,14) 572x902"; HALL-16's fix says "collapse the double rim by placing the
   panel at (0,0) full-window (the seam is the rim)". Both units are mine, so the panel is at
   (0,0) with PANEL_W = 590 — the same right edge (18+572) and therefore the same camp band
   (window x 590..928). Settings likewise: (0,0), height `930 - BAND_H(100)`, so the band is
   screen y 907..1007, the plan's acceptance numbers exactly.
5. **LoadSave's reason width 240 → 150.** With the panel at 590 the inner width is 526px;
   Slot 2/3 rows (two 240px reasoned buttons + Save) were 607px and would have clipped. 150
   keeps three buttons and their reasons inside at 100/125/150% (427/454/488px). HALL-15's
   real fix (one width for all nine buttons, one reason per row) stays W3-OPTIONS's.
6. **Settings' arena rows use one offset.** HALL's table groups RaidPrep/RaidView/Results at
   (-30,-120); RaidView/Results actually frame the arena at (0,-280) with a plate inset. The
   table is the cited spec and Settings only ever shows a dimmed backdrop, so the group's
   number is used. LoadSave (-10,-62) and Completion (-46,-62) were added so Start from those
   screens keeps their ground too.
7. **`Frame.standard_chips` replaces the three hand-rolled chip rows.** Guildhall rebuilt its
   row on `_on_changed` by clearing children; `standard_chips` creates a fresh HBox each call,
   so `_rebuild_chips()` frees `_frame.chips` and calls it again. Semantics: the frame prints
   "No guild loaded." when the state is null OR inactive; Guildhall's copy only checked null.
   No test reads the hall chips (test_screens reads Town's), and a Guildhall with an inactive
   state is not a state the game reaches.
8. **Facilities' card is the tent crop at the plan's rect, unmeasured beyond the shot.** The
   rect is HALL-18's interim; the shot (`--press=Facilities`) is the check.

## Log

(appended as each item lands)

- Code landed in the seven owned files + the new test (see "What changed" below). `PARSE_CHECK OK` (154 scripts) under the lock at the first attempt.
- First unit-suite run: blocked by another unit — `game/ui/Frame.gd:234/235/251/273/371` call `_scrim()`, `draw_lockup()`, `_scale()` that do not exist yet (W1-FRAME mid-edit; not mine). Every screen test fails to compile behind it. Retrying once Frame.gd parses again.
- `grep -rn guildhall_plate game/screens game/ui` → only `AdventureBoard.gd:126`, a historical comment in a file I do not own → handoff §1.

## What changed

- `game/core/ScreenRouter.gd`: `previous_path()` = `_stack[-2]`, "" at the root (spaces).
- `game/screens/Guildhall.gd`: `CAMP_SCENE`, `HALL_FRAMING := "same"`, `FRAMINGS` {same: (-46,-62) dim 0.62/0.62/0.68; tight: (-120,-140) dim 0.55/0.55/0.62}, `static framing()`, `static bare_stage(who, scene)` (reads the scene JSON, drops `bubbles` and `speech`, `SceneStage.from_data`, applies reduced_motion/effects from GameSettings so tests and tools see the held camp); `_scene` mounts the stage at the framing; `_chips()` deleted → `Frame.standard_chips`; `_rebuild_chips()` replaces the row on `_on_changed`; `ICON` const gone.
- `game/screens/RaiderDetail.gd`: stage at `GuildhallScript.framing()`; `_chips()` deleted → `Frame.standard_chips`; `ICON` gone.
- `game/screens/LoadSave.gd`: `CAMP_OFFSET (-10,-62)`, `CAMP_DIM 0.70/0.70/0.76`, `PANEL_W 590` (panel at the window origin, HALL-16; right edge where the plan's 18+572 put it, so window x 590..928 / screen x 800..1138 is camp), `REASON_W 150` (was 240 — three reasoned buttons must fit the 526px inner width), the helper sentence wraps beside "Guild Slots"; `PLATE` const gone.
- `game/screens/Settings.gd`: `STAGE_FOR` table (HALL's plate plan), `STAGE_DEFAULT`, `HALL_SCREENS` → `GuildhallScript.framing()`, `STAGE_DIM 0.55/0.55/0.62`, `BAND_H 100`; `static stage_for(previous)`; `_scene` reads `_router.previous_path()`; panel at the origin, `host.size.y - BAND_H` tall; `_chips()` deleted → `Frame.standard_chips`; `ICON` gone.
- `game/screens/Facilities.gd`: `HALL_CARD_PLATE = stage_camp.png`, `HALL_CARD_CROP = Rect2(230,110,337,104)`; header comment no longer claims the hall plate.
- `game/screens/Roster.gd`: untouched (no ground of its own; verified by reading it in full).
- `tests/unit/test_hall_plates.gd` (new, spaces): 8 tests — one camp stage + no `_plate.png` on the four scenes; Facilities' card crops stage_camp at the tent rect; no words under the hall stage; framing == Town.CAMP_OFFSET and LoadSave's own offset; Settings from Town → stage_camp at the camp's offset, from MainMenu → stage_town, `stage_for` defaults; `previous_path` across goto/push/pop; reduced motion holds the camp (motion_held, not processing, every AnimatedSprite2D stopped on frame 0) and releases with the option off; source text (no crop named, HALL_FRAMING const, previous_path signature, no sun.png / standard_chips in the three files).
- Viewed `stage_camp.png` at `Rect2(230,110,337,104)` (scratchpad/tent_crop.png, 2x): the big canvas tent with its lit doorway, dark pines behind, the guild's crimson banner at the right edge — no figure in the rect. HALL-18's interim crop is the right one.
- Suite run 2 (Frame.gd back, Fonts.gd/Widgets.gd still mid-edit by W1-CHROME/W1-KIT): `TESTS FAILED 8/1677`; 7 of my 8 tests green, one red: Settings pushed from MainMenu stood on the camp. Cause found in the router: `push()` builds the screen BEFORE appending to `_stack`, so at build time `previous_path()` is "" and `current_path()` is the opener. Fix: `Settings._opener()` = `current_path()` while building (falls back to `previous_path()` when this page is already on the stack); `previous_path()` keeps the plan's contract. The other 7 reds (test_a11y focus ring / LinkButton, test_frame_header lockup 374 vs 375, test_screens callout, test_text_scale x2) trace to `Widgets.ui_semibold` missing and Fonts.gd's `set_glyph_advance` error — other units' files.
- Suite run 3 (after `_opener()`): `TESTS FAILED 8/1677` — test_hall_plates.gd is no longer in the FAIL list (all 8 of its tests green). The 8 reds are other units' mid-wave state: `test_icons.gd` fails to compile (W1-ICONS), `test_a11y` focus-ring/LinkButton and `test_text_scale` x2 and `test_screens` callout (`Widgets.ui_semibold` missing — W1-KIT/W1-CHROME), `test_frame_header` lockup 374 vs 375 (W1-FRAME). None touch an owned file.

## Shots (build/shots/, 1536x1024, 40 frames, viewed with the Read tool)

- **Guildhall_camp.png** (`--fixture`): the roster grid over the bare camp. The campfire ring with its four seated figures sits at screen ≈(880,420) between the Rhona/Greg column and the sidebar, the mess tent's canvas at the top of the window, embers and the fire light visible; no painted human, no speech plate, no "..." bubble anywhere. Header chips are the frame's now — Day 23 · Unknown carries the rank sigil, not the sun (HALL-19). The PanelWarm panel renders translucent in this run, so the camp reads through the grid instead of only in the 6-8px margins — that is the panel chrome, which is W1-CHROME's this wave (Theme.gd / panel_warm.png mid-repaint), not this unit's; the margins-only framing will look as planned once the panel is opaque again. The Recent Events well in the strip shows a vertical "View All / Records" wrap — Cards.event_log (W1-KIT's file), not touched here.

## Resume (second agent, 2026-09-14)

The first agent returned no result and ticked no box; every box above is re-verified against the working tree from here on. State found: the six owned diffs (+244/-125) and the untracked test are in the tree; `grep -rn guildhall_plate game/screens game/ui` → only `AdventureBoard.gd:126` (handoff §1, not mine); `build/diff/hall/*_diff.json` (10:06) holds an after-run nobody recorded. Shots are retaken under fresh names (`build/shots/hall_*.png`) because the kit files under them (Frame/Theme/Widgets) moved after the old shots were taken.

## After (resume) — refdiff vs concept 3, scene band masked (`0,77,1536,649`), build/diff/hall2, shots of 13:53

| screen | mae | rmse | structure | layout_iou | palette_div | within_8 | vs baseline |
|---|---|---|---|---|---|---|---|
| guildhall | 33.149 | 67.009 | 0.1673 | 0.0863 | 0.3948 | 57.52 | mae −0.58, structure +0.025, iou +0.009, palette −0.038, within_8 −4.0 |
| raiderdetail | 37.684 | 69.79 | 0.1893 | 0.1005 | 0.2854 | 47.81 | mae −0.17, structure +0.018, iou −0.003, palette −0.039, within_8 −3.7 |
| loadsave | 33.604 | 65.085 | 0.1955 | 0.0779 | 0.2648 | 51.22 | mae +1.23, structure +0.058, iou +0.019, palette −0.029, within_8 −7.3 |
| settings | 36.076 | 66.958 | 0.1944 | 0.0857 | 0.2901 | 43.23 | mae +1.02, structure +0.039, iou +0.011, palette +0.014, within_8 −8.0 |

Reading: structure and layout_iou improve on all four; mae moves within ±1.3. The within_8 drops on LoadSave/Settings are the bands this unit frees on purpose — window y 726..1007 (LoadSave) and y 907..1007 (Settings) are OUTSIDE the mask and were opaque panel before, camp now — plus the stage's screen-space glow (LESSONS:118-121). Not a regression of the chrome the mask keeps.

## Shots (resume) — build/shots/hall_*.png, 1536x1024, 40 frames, all viewed with the Read tool

- **hall_Guildhall.png** (`--fixture`): the roster grid on an opaque PanelWarm (the translucent panel the first agent saw is gone — W1-CHROME's chrome landed); the camp shows only in the 6–8px margins (dark pines at x 210..232, the treeline strip at y 77..85), exactly the margins-only framing `HALL_FRAMING = "same"` promises. Chip 4 carries the rank shield. No painted human, no plate, no bubble. (The Recent Events well's vertical "View All / Records" wrap is `Cards.event_log`, W1-KIT's file.)
- **hall_RaiderDetail.png** (`--fixture`): two panels; the 12px seam between them (x≈688..706) and the window's edges show camp ground and trees instead of the hall's painted floor. No figure anywhere in the slivers.
- **hall_LoadSave.png** (`--fixture`): the slots panel stops at x≈800 and the camp band x 800..1138 holds the fire ring with its flame, the four seated raiders around it, a fifth standing by the tent, the tent's lantern, the pines and the bridge lamp below. One rim line at the panel's edge (HALL-16). The three rows' 150px reasons fit.
- **hall_Settings.png** (`--fixture`): the table's panel ends at y≈905; the 100px band under it is the stream — rocks, water, the far bank — at x≈600..800. One rim line. `Reduced motion — Off`.
- **hall_Guildhall_facilities.png** (`--fixture --press=Facilities`): the sidebar card is the big canvas tent with its lit doorway, the pines behind and the crimson banner at the right edge — HALL-18's interim crop; no bartender, no barmaid.
- **hall_Settings_reduced.png** (`--fixture --set=reduced_motion=true`): same composition, `Reduced motion — On`; the frame pair `hall_Settings_reduced_frames.{a,b}.png` (frames 20/40) differ in 0 pixels; the live pair `hall_Settings_live_frames.{a,b}.png` differ in 272 (203 in the stream band). The camp is held still by the option and moves without it.

## Log (resume)

- 13:53 six contract shots under one lock (`scratchpad/shots.sh`): all `SHOT OK`, exit 0 each; viewed and described above.
- 13:55 refdiff x4 → build/diff/hall2 (table above). `tools/lint_motion.sh` → `MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`.
- 13:56 contract greps: no space-indented line in the six tab files, no tab in ScreenRouter.gd / the test; no `create_tween` and no `reduced_motion` branch in an owned file (Guildhall.gd:192 passes the option to `SceneStage.apply_settings`, the world-layer door); `Frame.refresh_chips` exists in the tree but not at HEAD, so `_rebuild_chips()` keeps calling `standard_chips` (§0.2: no same-wave function).
- 13:57 `--frames=20,40` pairs: reduced 0 px changed, live 272 px (203 in the stream band y 907..1007).
- 13:58 `verify.sh --fast` under the lock, summary:
  `PASS  class cache regenerated` · `PASS  LINT OK  no cross-file class_name references` · `PASS  MOTION LINT OK` · `PASS  PARSE_CHECK scanned 160 script(s)` · `PASS  16 generated file(s) agree with tools/gen_items.gd` · `PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING` · `FAIL  unit tests` → `FAIL  test_widgets_kit.gd :: test_the_label_stamp_keeps_its_contract_and_leans` (expected true) · `TESTS FAILED   1/1708 failing  [37415 ms]` · 4-7/8 SKIP (--fast) · `VERIFY FAILED`.
  The one red is W1-KIT's (untracked `tests/unit/test_widgets_kit.gd` against its own modified `game/ui/Widgets.gd`); it was 4/1708 at the resume and is now 1/1708 as the other units settle. `test_hall_plates.gd` (8 tests) is green.
- 13:59 `a11y_smoke.gd` under the same lock: `A11Y SMOKE PASSED   26 screen mount(s)`; both sweeps, every hall screen `ok`.
- Nothing left undone inside the ownership. Outside it: handoff §1 (the AdventureBoard.gd:126 comment) is what makes the acceptance grep literally empty.
