# Review — W1-HALL — the hall family stands on the bare camp

Reviewer: adversarial review, 2026-09-14. Verified against the working tree, not the report.
Owned files: game/screens/Guildhall.gd, Roster.gd, Facilities.gd, RaiderDetail.gd, LoadSave.gd, Settings.gd, game/core/ScreenRouter.gd (previous_path() only), tests/unit/test_hall_plates.gd (new).

## Findings (written as they land)

### F1. Ownership — owned diffs only (checked)
`git diff --stat` over the seven owned code files: ScreenRouter +8 (previous_path() only, four spaces), Facilities +21/-9, Guildhall +112, LoadSave +56, RaiderDetail +50, Settings +122; Roster.gd unchanged; tests/unit/test_hall_plates.gd untracked (404 lines, spaces). Every other modified/untracked path in `git status` belongs to another wave-1 unit's ownership table (Frame/Type → W1-FRAME, Widgets/Cards/Bar → W1-KIT, Theme/Palette/Fonts + ui PNGs → W1-CHROME, SceneStage/stage_*.json/test_scene_stage/RaidView → W1-STAGE, icons → W1-ICONS, vfx → W1-VFX, tools/probe/Kit.gd → W0-GATE). Nothing in this unit's diffs or report touches them. `aguildstory.zip` untracked at the root — unattributable.

### F2. §0.2 same-wave references (checked, OK)
Every function the unit calls exists at HEAD: `Frame.standard_chips` (HEAD Frame.gd:421), `SceneStage.from_data` (:98), `SceneStage.SCENES` (:37), `DEFAULT_ARENA` (:61), `apply_settings` (:633), `motion_held` (:291). `Frame.refresh_chips` exists only in the tree (W1-FRAME's addition) and is NOT called — good. No preload cycle: Guildhall preloads Roster/Facilities; RaiderDetail/LoadSave/Settings preload Guildhall; Roster/Facilities preload no screen.

### F3. Indentation (checked, OK)
Six screen files: 0 space-indented lines, all tabs. ScreenRouter.gd and the test: 0 tab-indented lines.

### F4. Line endings — MINOR
`git ls-files --eol game/core/ScreenRouter.gd` → `i/lf w/crlf attr/text eol=lf`: the working copy was rewritten with CRLF by this unit's edit (only W1-HALL touches the file this wave; Settings/Guildhall/etc. are w/lf). git normalises to LF on commit (the `CRLF will be replaced by LF` warning) and the committed diff is the 8 lines, so no lasting effect — but it is a whole-file worktree reformat of lines the unit did not write. (Frame.gd shows the same w/crlf; that is W1-FRAME's.)

### F5. Contract greps (checked, OK)
No `create_tween`, no `reduced_motion` branch (Guildhall.gd:192 passes the value to `SceneStage.apply_settings`, the world-layer door), no `class_name` refs, `_ready()` bodies pre-existing (screens draw in build()). `grep -rn _plate.png` over the six owned files is empty. `grep -rn guildhall_plate game/screens game/ui` → only `AdventureBoard.gd:126` (a comment, W2-BOARD's file; handoff §1 old-block matches the line byte-for-byte).

### F6. Stage mount mirrors Town (checked, OK)
Town.gd:143-145 `SceneStage.load("stage_camp")` / `position = CAMP_OFFSET` / `size = host.size - CAMP_OFFSET`; the hall copies use `Guildhall.bare_stage()` which reads the same JSON as `SceneStage._read` (HEAD:112) then `from_data` — from_data sets `mouse_filter = MOUSE_FILTER_IGNORE` (HEAD:102), so the stage never eats clicks. Judgement call 1 (drop `bubbles`/`speech` from the data rather than call `set_lines([])`) is sound: `set_lines([])` is a no-op and `_shuffle_bubbles` re-shows ambient bubbles.

### F7. Settings STAGE_FOR vs HALL's plate plan (checked, OK)
HALL.md:45's table: Town (-46,-62), Guildhall/RaiderDetail same, Board (-20,-80), Tavern (-320,-130), Market (-330,-240), arena trio DEFAULT_ARENA (-30,-120), MainMenu stage_town at MainMenu's offset — MainMenu.gd:85 is `Vector2.ZERO`, matching. Completion and LoadSave rows are additive. Default `stage_camp (-46,-62)` as the plan names. `HALL_FRAMING = "same"` is §0.6's landed default; "tight" is authored but not selected — nothing reserved for Q03/Q18 was decided.


---

## Second pass (resume reviewer, 2026-09-14 ~16:30) — everything above re-verified from the tree; findings continue

### R1. Ownership re-check (checked)
`git diff --stat` over owned code: ScreenRouter +8, Facilities +21/-9, Guildhall +112, LoadSave +56, RaiderDetail +50, Settings +122; Roster.gd untouched; tests/unit/test_hall_plates.gd untracked (0 tab-indented lines). Owned-file mtimes 09:39–09:54; report 13:57.
**`game/screens/AdventureBoard.gd` IS modified in the tree** with exactly handoff §1's edit (line 126 `guildhall_plate.png` → `the Concept 1 hall crop`). Attribution: its mtime is 16:16:06.27, identical to the second with `game/screens/Tavern.gd` (whose one-line diff is handoff-W1-CHROME §18) and `tests/unit/test_art_sources.gd` — a batch handoff application ~6.5 h after this unit's last write and 2.5 h after its report. That is the orchestrator's action, not the unit's; the report and handoff both say "nothing here is applied by this unit" and the timeline agrees. Not a finding against W1-HALL. Consequence: `grep -rn guildhall_plate game/screens game/ui` is now literally empty (verified below).

### R2. §0.2 same-wave references (re-checked, OK)
HEAD Frame.gd:421 `static func standard_chips(p: Parts, state)`, :112 `var chips: HBoxContainer`; HEAD SceneStage.gd:37 `SCENES`, :61 `DEFAULT_ARENA`, :98 `from_data` (:101 names the node `SceneStage_<name>`, :102 `MOUSE_FILTER_IGNORE`), :291 `motion_held`, :633 `apply_settings(reduced_motion: bool, reduced_effects: bool)`; Services.gd:22 `static func find(who, name)`. `Frame.refresh_chips` (tree-only, W1-FRAME) is not called. Town.gd:134 `CAMP_OFFSET = (-46,-62)` matches FRAMINGS["same"].

### R3. Engine runs (observed 16:20–16:26 under one lock, scratchpad/review_batch.sh)
- `parse_check.gd`: `PARSE_CHECK scanned 160 script(s)` / `PARSE_CHECK OK`.
- `run_tests.gd`: `TESTS FAILED 1/1710 failing [34556 ms]`. 1710 == `grep -c '^func test_'` over tests/unit (8 of them in test_hall_plates.gd); test_hall_plates.gd is absent from the FAIL list → its 8 tests are green (the runner prints failures only). The one red: `test_scene_stage.gd :: test_reduced_motion_holds_lights_and_bubbles` — "expected [[&"@TextureRect@59448", …]] got [[&"@TextureRect@59434", …]]; two runs of one scene must pick the same bubbles at the same ticks": W1-STAGE's untracked-diff test (+490) comparing auto-generated `@TextureRect@N` names between two `_stage()` builds. It references no owned file (grep for Guildhall/Settings/LoadSave/RaiderDetail/ScreenRouter in it is empty) and `_stage()` builds from a literal dict, not from any hall screen. **Not caused by W1-HALL.** (The report's 13:58 run had a different single red, W1-KIT's; the tree has moved since.)
- `a11y_smoke.gd`: `A11Y SMOKE PASSED 26 screen mount(s)`; hall rows: empty Guildhall focusable=18/reachable=21, RaiderDetail 7/8, Settings 23/23, LoadSave 4/16; fixture Guildhall 42/42, RaiderDetail 26/26, Settings 23/23, LoadSave 12/16. The single `warn` is AdventureBoard's 10 pointer-only cards (RULES §5, pre-existing).
- `lint_motion.sh`: `MOTION LINT OK`.
- Seven shots `SHOT OK` exit 0 → build/shots/review-W1-HALL-*.png (viewed below).
- `verify.sh --fast` (16:33, under the lock, scratchpad/out/verify_fast.log): `PASS class cache regenerated` · `PASS LINT OK` · `PASS MOTION LINT OK` · `PASS PARSE_CHECK scanned 160 script(s)` · `PASS 16 generated file(s) agree` · `PASS ART CHECK generators=6 184 agree 0 DIFFERS 0 MISSING` · `FAIL unit tests` = the same single `test_scene_stage.gd :: test_reduced_motion_holds_lights_and_bubbles` (`1/1710`) · 4–7/8 SKIP · `VERIFY FAILED`. **Observed: fail; cause: W1-STAGE's file, not this unit's.**

### R4. Shots re-taken and viewed (build/shots/review-W1-HALL-*.png, §0.3 grammar, 40 frames, 1536x1024)
- **LoadSave** (`--fixture`): slots panel from the window's origin to x≈800; camp band x 800..1138 with the fire ring at ≈(925,430), four pixel figures around it (≈850,400 / 895,330 / 960,320 / 1000,400) and a fifth by the tent (≈930,200); waterfall, banner, pines, bridge lamp. Band mean RGB (44.9,38.1,23.6) vs panel (11,17,26) — the band is camp, not panel. No painted human. Three rows' 150px reasons fit ("Slot N is empty." under each button). Rim zoom (scratchpad/rims.png): the double line at the panel edge is PanelWarm's own double-ruled 9-slice (the sidebar panel shows the identical pair) — the frame rim + panel rim did collapse to one (HALL-16).
- **Settings** (`--fixture`): table panel ends at y≈905; band y≈907..1007 shows the stream, rocks and far bank at x≈500..900. "Reduced motion — Off". No painted human.
- **Settings frame pairs** (`--frames=20,40`): live pair 23,380 px differ whole-frame, 4,405 inside x210..1138 × y907..1007 (the shimmer moves); reduced pair (`--set=reduced_motion=true`) **0 px** whole-frame; its .a shows "Reduced motion — On" with the same composition.
- **Guildhall** (`--fixture`): opaque PanelWarm over the roster grid; the camp shows only in the ~8px margins (dark pines x≈210..220, treeline strip y≈77..85) — margins-only, `HALL_FRAMING = "same"`. Chip 4 carries the rank shield. No figure, no plate, no bubble. (Vertical "View All / Records…" wrap in Recent Events = Cards.event_log, W1-KIT.)
- **RaiderDetail** (`--fixture`): two panels; the seam x≈688..706 and the window edges show camp ground and trees; no figure.
- **Guildhall `--press=Facilities`**: the sidebar card is the canvas tent, lit doorway, pines behind, crimson banner at the right edge — the `Rect2(230,110,337,104)` crop; no bartender/barmaid. A faint lit disc at ≈(870,400) on the panel is the campfire PointLight2D reaching UI (stage light-mask; present on Town, W1-STAGE's) — noted, not this unit's.

### R5. refdiff vs 3 masked (0,77,1536,649)
build/diff/hall2/hall_*_diff.json hold exactly the report's after-table (guildhall mae 33.149 / structure 0.1673 / iou 0.0863 / within_8 57.52; raiderdetail 37.684 / 0.1893 / 0.1005 / 47.81; loadsave 33.604 / 0.1955 / 0.0779 / 51.22; settings 36.076 / 0.1944 / 0.0857 / 43.23); baseline build/diff/*_diff.json holds the report's before-table. My re-run on the review shots reproduces them (33.15 / 37.687 / 33.585 / 36.046 mae; structure 0.1673 / 0.1893 / 0.1953 / 0.1943). Structure and layout_iou rise on all four, mae within ±1.3; within_8 drops 4–8 points on the two screens that free a band (panel → camp outside the mask; screen-space glow, LESSONS:116-121). Recorded before/after: met; not a regression of the chrome.

### R6. §0.5 / Green line checks (all OK)
- Indentation: 0 space-indented lines in the six tab files; 0 tab-indented lines in ScreenRouter.gd and the test.
- No `create_tween`, no `class_name` (only `Enums.class_name_of` calls, pre-existing), no `_ready()` change (the pre-existing `_ready` stubs are untouched; all drawing in `_build`), no branch on `reduced_motion` — Guildhall.gd:192 passes the value into `SceneStage.apply_settings(...)`, §0.5's named world-layer door; `lint_motion.sh` OK.
- Label/Button text: `git diff -U0` shows no added/changed `.text`, `label(`, `chip(` or node name; the only string lines are the deleted hand-rolled chip literals, which `Frame.standard_chips` (HEAD:421) emits verbatim. `Nav_*` untouched. Stage is `MOUSE_FILTER_IGNORE` (from_data:102); `grep -cE 'Button|focus_mode' SceneStage.gd` = 0 at HEAD and in the tree — no new focusables (a11y counts match the report).
- Nothing parented to the router host: the stage is a child of `_frame.scene`; test_screens' one-child-after-two-gotos is green in the suite.
- No new PNG, no new .import, no script that calls `$GODOT` (the unit added only a test). Roster.gd: `git diff` empty.
- Handoff §1: the old block equals HEAD:AdventureBoard.gd:126 byte-for-byte; one edit, `## ` comment indentation, already applied by the orchestrator (R1).

### R7. Judgement calls vs §6 (nothing reserved for the designer was decided)
1 (drop `bubbles`/`speech` from the data): sound — `set_lines([])` returns early on an empty array and `_shuffle_bubbles` re-shows bubbles; the plan's intent ("no words under the panel") is met through the public `from_data` seam. 2 (`apply_settings` at build): required under the harness; idempotent. 3 (`HALL_FRAMING = "same"`, `FRAMINGS.tight` authored, not selected): §0.6's landed default; Q03 untouched. 4 (panels at the origin, PANEL_W 590): HALL-16 is in the unit's finding list; the right edge (18+572 = 590) and the band the plan names are preserved. 5 (REASON_W 240→150): a layout consequence inside owned files; the 100% shot shows the reasons fit; the report's 125/150% widths (454/488px) are **unverified here** (no acceptance line asks for them). 6 (arena rows at (-30,-120)): RaidPrep.gd:45 is (-30,-120) but RaidView.gd:51 / Results.gd:65 are (0,-280), so a Settings opened over RaidView/Results would shift the arena by (30,160) — recorded by the unit; MINOR, W3-OPTIONS can true it up. 7 (`_rebuild_chips` via `standard_chips`, not the tree-only `refresh_chips`): correct under §0.2. 8 (tent crop): the plan's rect exactly.

### R8. Minor findings
- M1 (= F4): `game/core/ScreenRouter.gd` working copy is CRLF (`i/lf w/crlf`); git normalises on commit and the committed diff is the 8 lines, but the unit's editor rewrote every line ending of a file it owns only for `previous_path()`. Cosmetic; the orchestrator's commit fixes it.
- M2: `Settings.STAGE_FOR` RaidView/Results offset (-30,-120) ≠ those screens' `ARENA_OFFSET (0,-280)` (judgement 6 above).
- M3: `Settings._opener()` under a `goto` (not `push`) reads `current_path()` = the OUTGOING screen while building (the router replaces `_stack` after `_load_into_host`), so a `goto(Settings)` stands on the previous screen's stage while `previous_path()` then reports "". In the game Settings is only ever pushed (router:127/158, every rail entry `push`es), and under a11y_smoke/test_a11y it merely picks the preceding screen's stage — harmless, but the comment in `_opener()` should say so. No action required.

## Acceptance (plan §2 W1-HALL), judged from the tree

| # | Line | Verdict | Evidence |
|---|---|---|---|
| 1 | `grep -rn guildhall_plate game/screens game/ui` is empty | **met** | grep at 16:20 → no hit under game/screens or game/ui (the only repo hits are the test's own negative assertion, tools/art/patch_bubbles.py's usage line and tools/probe/Kit.gd:90 — outside the grep's paths). The last survivor (AdventureBoard.gd:126, not owned) went through handoff §1 and was applied by the orchestrator at 16:16 (R1). |
| 2 | test_hall_plates.gd: five screens mount a SceneStage child, no TextureRect at a `_plate.png` | **met** | 8 tests discovered (1710 = 1710), none in the FAIL list; `test_every_hall_screen_stands_on_one_camp_stage_and_no_plate_crop` walks Guildhall/RaiderDetail/LoadSave/Settings, `test_the_facilities_hall_card_crops_the_bare_camps_tent` presses Facilities. |
| 3 | Settings pushed from Town → stage_camp; from MainMenu → stage_town | **met** | `test_settings_inherits_the_stage_of_the_screen_beneath_it` green (push after goto(TOWN) → `SceneStage_stage_camp` at Town.CAMP_OFFSET; after goto(MAIN_MENU) → `SceneStage_stage_town`); Settings.gd `_opener()`/`stage_for()`; ScreenRouter.gd:59 `previous_path()`. |
| 4 | Fixture shots of Guildhall/RaiderDetail/LoadSave/Settings show no painted human | **met** | review-W1-HALL-{Guildhall,RaiderDetail,LoadSave,Settings}.png viewed (R4): pixel actors only. |
| 5 | LoadSave shows the fire ring and four seated actors in x 810..1138 | **met** | review-W1-HALL-LoadSave.png: ring ≈(925,430), figures ≈850..1000 x, band mean RGB is camp not panel (R4). |
| 6 | Settings shows water shimmer in y 907..1007 | **met** | review-W1-HALL-Settings.png band y 907..1007 = stream; live `--frames=20,40` pair differs in 4,405 px inside the band, reduced pair 0 (R4). |
| 7 | refdiff vs 3 masked recorded before/after | **met** | build/diff/*_diff.json (before) and build/diff/hall2/hall_*_diff.json (after) match the report's tables; reproduced on the review shots (R5). |
| 8 | a11y_smoke 26 mounts green | **met** | `A11Y SMOKE PASSED 26 screen mount(s)` at 16:22 (R3). |
| — | Shot list (6 shots) | met | all six re-taken here, exit 0, viewed. |
| — | Green: no Label/Button text touched; `Nav_*` untouched; SceneStage adds no focusables; the stage gates its own motion | met | R6; reduced pair 0 px; `motion_held()` asserted by the test. |
| — | `verify.sh --fast` green (§0.4) | **not met by the tree, not this unit's** | 1/1710 red is `test_scene_stage.gd` (W1-STAGE) — R3. |

## Verdict

**PASS** (minors only: M1 CRLF working copy of ScreenRouter.gd; M2 arena rows' offset in `STAGE_FOR`; M3 `_opener()` comment under `goto`). No blocker; no unmet acceptance line the unit could have met; no §6 decision taken; no unowned file touched by the unit (AdventureBoard.gd's tree change is the orchestrator's application of handoff §1). `verify.sh --fast` observed FAILED on another unit's test.
