# Review — W1-FRAME (adversarial, second resume)

Reviewer edits nothing but this file. Verified against the TREE, not the report.
Started 2026-09-14. Findings appended as they land.

## 1. Ownership / git status

- Owned: game/ui/Frame.gd, game/ui/Type.gd, tools/art/gen_wordmark.py, game/assets/ui/wordmark_33.png (+.json +.import), tests/unit/test_frame_header.gd (new), report/handoff-W1-FRAME.md.
- `git status --porcelain` (16:34): the owned files are M Frame.gd, M Type.gd, M gen_wordmark.py; untracked wordmark_33.{png,json,png.import}, test_frame_header.gd (+ its auto .uid). The other ~70 modified / ~120 untracked paths belong to W1-CHROME/KIT/STAGE/HALL/ICONS/VFX (Theme/Palette/Fonts/Widgets/Cards/Badge/Bar/SceneStage, screens, scene JSON, art/src, vfx, icons, their tests/reports/handoffs) — nothing in the report or in any of those diffs attributes them to this unit. `aguildstory.zip` untracked at the root is unattributable (not this unit's).
- The generator's pre-existing outputs (wordmark_58/44/tagline .png+.json, splash.png, icon_256.png, icon.ico, emblem.png) are byte-identical to HEAD (`git status` prints nothing for them) although their mtimes are 09:46 — the unit ran the generator and changed nothing it does not own.
- Only cross-unit edit: the unit applied handoff-W1-CHROME edits 1-7 to its OWN file (seven `Color("…")` → `Palette.*` lines). Every token exists in Palette.gd with the same hex as HEAD's literal (Palette.gd:28-29,129-133,141-145 checked against `git show HEAD:game/ui/Frame.gd`). Process note (minor): §0.2 says the orchestrator applies handoffs between waves; this pulled a same-wave dependency on W1-CHROME's Palette tokens into Frame.gd early. The tree parses and the handoff file flags it for the orchestrator, so it is a process deviation, not a defect.

## 2. Diffs read

- **Type.gd** (+31, tabs, no size constant touched): `THOUSANDS_SEPARATOR`, `num(n)`, `gold(n)`. `num` groups from the right, sign outside. Fine.
- **gen_wordmark.py** (+11): one call `wordmark(48, 232, "wordmark_33")` + docstring. Regenerated into scratch with OUT redirected: all eight outputs (33/44/58/tagline png+json, splash, icon_256, icon.ico) md5-identical to the tree → deterministic and the tree's wordmark_33 IS the generator's. (build_art.sh only gates the Lua generators, so this is not covered by ART CHECK — pre-existing gap, not this unit's.)
- **wordmark_33.png** 235x47 RGBA, .json `{baseline_y 33, cap_top_y 2, glyph_left 3}`, .import copied from wordmark_44's with its own uid/md5 path; `.godot/imported/wordmark_33.png-….ctex` exists. Viewed at 3x: the "A Guild Story" logotype — the plan's named exception (Q16, "PY; the pre-rendered logotype's one exception"). 96 + 235 = 331 ≤ 344.
- **Frame.gd** (+396/-76): read in full. Adds Theme_/Enums/Reputation preloads (precedent: Cards/Badge/Town already preload sim), RAIL_* / *_SCRIM_* / TAGLINE_RULE_END / LOCKUP / LOCKUPS consts, Parts fields widened to Control (+ sidebar_rule, expand_ground, lockup_right), `_scrim()` GradientTexture2D overlays for the full-bleed header/divider/rail, `draw_lockup()`, `_fill_chips`/`refresh_chips`/`standing_tip`, `_rail_label_size`/`_theme_font`, `chip_gap`, expand_ground in relayout. `focus_order`/`_focusable`/META keys/`wire_shell_focus`/`nav_items` untouched (grep of the diff for those names: nothing). `Nav_` names, `b.text = label` untouched. All overlays `MOUSE_FILTER_IGNORE`. No `create_tween`, no `reduced_motion`, no `class_name`, no `Color("` left.
- Whitespace: Frame.gd 0 space-led lines / 521 tab-led; Type.gd 0 space-led; test 0 tab-led. **Minor:** Frame.gd's working copy is CRLF (868/868 lines) while HEAD and `.gitattributes` (`*.gd eol=lf`) are LF — git will normalise on commit (`git diff` already shows content-only changes), Godot parses it; hygiene only.
- **test_frame_header.gd** (411 lines, spaces): 12 cases; builds bare shell hosts + one Town through a registered router host; restores text_scale and resets the GameState autoload in after_each. Asserts the plan's lines verbatim (gold 12480/60, "reputation" in DayChip tooltip) and the RULES §1 strings stay Labels.

## 3. Gate runs observed (one lock hold, 16:35:47–16:38:05, scratchpad/review_batch.sh; log copies in the reviewer's scratchpad)

- `parse_check.gd`: `PARSE_CHECK scanned 160 script(s) / PARSE_CHECK OK`.
- `./tools/verify.sh --fast`: **VERIFY OK** — `LINT OK`, `MOTION LINT OK`, `PARSE_CHECK scanned 160 script(s)`, `16 generated file(s) agree`, `ART CHECK generators=6 runtime files: 184 agree 0 DIFFERS 0 MISSING`, `TESTS PASSED 1713 test(s) in 80 file(s) [34771 ms]`. (The report's 16:29 run was 1709/1710 with W1-STAGE's `test_reduced_motion_holds_lights_and_bubbles` red; SceneStage.gd/test_scene_stage.gd were rewritten at 16:31/16:33 and the suite is green now — the red was never this unit's.)
- `a11y_smoke.gd`: `A11Y SMOKE PASSED 26 screen mount(s)` — 13 `ok empty`, 13 `ok fixture`, the one pre-existing `warn fixture AdventureBoard.tscn 10 pointer-only gesture target(s)` (RULES-07).
- The unit's file alone (reviewer's scratchpad `run_one.gd`, through the lock, 16:39): **`REVIEW_ONE test_frame_header.gd: 12/12 passed`**, every case printed `ok` (num/gold, DayChip tooltip, standing tip, refresh_chips, chips-not-focus-stops, rail label, same lockup, compact lockup, full-bleed fades, framed slabs, expand, text scale).

## 4. Shots retaken and viewed (§0.3 grammar, `--fixture`, 40 frames, through the lock → build/shots/review-W1-FRAME-*.png)

- **Town** (1536x1024): the lockup (skull + 44 mark + "Bad People. Worse Decisions." + trailing rule) on a dark plate that melts into the camp sky by x≈440 (2x crop viewed); the four chips "12,480 G · 320 · Roster 12 of 15 · Day 23 · Unknown" floating over the scene; the rail scrim fading into the grass with no border line (3x crop viewed); "Adventure's Board" whole in the rail; the sidebar meeting the bronze rule. Seen and NOT this unit's: the Town sidebar panel overhangs the gutter (border at x≈1529-1533, the rule ends at 1519), the Blacksmith callout clipped by the sidebar — both already in the unit's handoff for W2-TOWN.
- **Guildhall**: the identical lockup and chips; opaque rail with its core at x=208; rail crop at 3x viewed — glyph column at 16, labels at 62, "Adventure's Board" whole at the 16px floor (visibly a step smaller than its 18px neighbours), the active "Roster" plate.
- **Town --focus**: `FOCUS Nav_home<Button> at 0,105 211x55 (4 shell regions)`; 3x crop viewed — the 2px steel ring (EDGE_STEEL 4982A2) around "Camp"; the rest of the diff vs the plain Town shot is scene animation (fire, figures).
- **Town 1820x1024 expand**: chips end at the new gutter (rightmost light px 1801, plate 1803); sidebar right edge at 1804 (= 1820 − 16); header band spans the canvas; the camp plate covers the added width. Seen, not this unit's: the strip's event log still ends at x 1518 (Cards.roster_strip's fixed wrap — in the handoff for W1-KIT), the Town panel overhang again.
- **Guildhall 1820x1024 expand**: sidebar border bronze at x 1802, page ground from 1804 ✓; the widened framed scene shows W1-HALL's dimmed camp, so the GROUND_RAIL `ExpandGround` is covered (it is the guard for a narrower plate; the test pins its 284px).
- **Town text_scale=150**: all four chips whole (light px span x 458..1499; at 100: 541..1500), the lockup untouched, the rail's short labels at 27px and "Adventure's Board" at 16px (3x crop viewed — see minor M2).
- **Ten glow-off shots** (`--set=reduced_effects=true`: Town, AdventureBoard, RaidPrep, Guildhall, RaiderDetail, Tavern, Market, LoadSave, Settings, Completion) for A3 — measured below.
- The unit's own W1F_Guildhall.png (16:23) header region is byte-identical to the review retake (diff bbox None) — the unit's evidence matches the tree.

## 5. Acceptance lines (00-plan §W1-FRAME)

| Line | Verdict | Evidence |
|---|---|---|
| A1 Town day chip `tooltip_text` contains "reputation" | **met** | `test_the_town_day_chip_carries_the_standing_tooltip` ok (run_one 16:39); Frame.gd:585-586 `day.name = "DayChip"; day.tooltip_text = standing_tip(state)`; `standing_tip` → "%s reputation · %s more to %s" |
| A2 `Type.gold(12480) == "12,480 G"`, `Type.gold(60) == "60 G"` | **met** | `test_type_num_and_gold_carry_the_thousands_separator` ok; Type.gd:119-135; Town/Guildhall shots print "12,480 G" |
| A3 header region (0,0,400,74) pixel-identical across the archetype-A shots | **met** (with the known glow caveat) | PIL over the ten glow-off review shots vs Town: **0 differing pixels in every pairing**. Glow on, Town vs Guildhall: 3096 px differ with max channel delta 4 — SceneStage's screen-space glow (§0.3 / LESSONS:116-121), no layout pixel moves. The plan's "eleven" is not reachable with distinct fixture shots (Roster/Facilities/Records are Guildhall tabs); ten distinct screens measured |
| A4 no rail-label pixel right of x=206 | **met** | rightmost low-saturation label pixel in the "Adventure's Board" row (x<208) is **x=200** on all nine framed glow-off shots and Guildhall_expand; RAIL_LABEL_X 62 + 145 = 207 clip (Frame.gd:36,56,441-460); test asserts position/size/clip_text/TRIM_ELLIPSIS |
| A5 Town shot: rail edge fades, no plate pixels between header and sidebar or sidebar and strip | **met** | Town row 400: (6,18,22) at x≤150 → plate greens by x 200, no hard edge; row 30: GROUND_FRAME (13,22,28) to x 413 → plate by 440. Column x=1300 (and 1150): rows 74-75 bronze rule (123,98,84), row 76 (33,28,25) panel edge, row 77 (139,101,74) panel border — no plate row. Rows 726-733 under the sidebar = page ground (0,13,18), row 734 the strip's top — no plate. 3x crops viewed |
| A6 RaidView/Results wordmark rightmost ≤ plate right − 8 "once wave 2 consumes wordmark_33 (this unit ships the asset and the table)" | **met for this unit's half** | wordmark_33.png 235x47 + .json + .import on disk; `LOCKUPS["33_compact"]` (mark_x 96, baseline 48, emblem (22,12) crop 65x57); `test_the_compact_lockup_ends_inside_the_raid_plate` ok asserts `draw_lockup(host,"33_compact") ≤ 344`; 96+235 = 331. The RaidView/Results shots still show wordmark_44 (their screens are wave 2's) |
| A7 `test_a11y.gd` green | **met** | in the 1713-green suite; a11y_smoke 26 mounts both sweeps; Frame's focus code untouched by the diff |
| Shot list: Town, Guildhall, Town --focus, Town 1820 expand | **met** | the unit's W1F_*.png at 16:23 exist; all retaken and viewed here (§4) |
| Green: chip Labels keep "60 G", "Day 1", "Roster 0 of 15"; a11y_smoke rail rules; no tween | **met** | test_screens in the green suite; the new test asserts "60 G"/"Day 1"/"Unknown" as Labels; `grep create_tween Frame.gd` = 0 |

## 6. §0.5 / Green line checks

- Label/Button texts and node names: `b.name = "Nav_" + id`, `b.text = label` untouched; new names only (`DayChip`, `Glyph`, `RailLabel`, `Emblem`, `TaglineRule`, `SidebarRule`, `ExpandGround`, `Header`, `Divider`, `Rail`). Chip strings unchanged except the separator, which only appears at ≥4 digits (test_screens' "60 G" holds; "12,480 G" in fixture shots).
- Indentation: Frame.gd/Type.gd tabs (0 space-led), test spaces (0 tab-led); gen_wordmark.py spaces.
- No `create_tween` outside Widgets (MOTION LINT OK); no `reduced_motion` branch; no `class_name` (LINT OK); no `_ready` in Frame.gd.
- No shell script added to the tree (no `scratchpad/` in the repo); every engine call in the report went through `with_godot_lock.sh`.
- New PNG: wordmark_33.png is the logotype — text by design, the plan's explicit exception (Assets: "PY; the pre-rendered logotype's one exception, Q16"). `.import` present with its own uid; the `.godot/imported` ctex exists.
- Nothing parented to the router host: Frame.build adds to the screen; test_screens :159-169 (one child after two gotos) is in the green suite.
- Overlays: header/divider/rail scrims, sidebar_rule, expand_ground, emblem, marks, tagline rule all `MOUSE_FILTER_IGNORE` (asserted by `test_the_full_bleed_camp_fades_its_rail_and_header`).
- Palette: no new hex in Frame.gd; the seven literals became the same-hex tokens; no pure black/white (`Color(ground, 0.0)` is the token at alpha 0).
- Every font size through the door: rail label `Type.at(Type.NAV, Theme_.scale_of(host))` then the step-down; chip host `Type.at(CHIPS_W, pct)`; `chip_gap(pct)` identity at 100.
- Handoff: observations only, no `## N.` edits — the unit needs nothing applied elsewhere; the observations name the owning wave-2/W1-KIT units and the orchestrator note about CHROME edits 1-7.
- Same-wave references: Frame.gd names W1-CHROME's Palette tokens (via the applied handoff) — see §1 process note; it names no PNG it does not emit and calls no function another unit is adding.

## 7. Judgement calls vs §6

- J3 `LOCKUP = "44_tagline"` — exactly §0.6's landed switch for Q05; the `tagline` opt made inert, recorded for W2-TOWN. Not a designer decision.
- J2 rail label step-down to `Type.NAV - 2` — TOWN-04's first option combined with its second; CRITIC-C13 rules the label "decidable without the designer". Type sizes untouched (Q16 respected). See M2 for the 150% consequence.
- J4/J5 wordmark_33 parameters and the 65x57 emblem crop — COMBAT-12 / spec 02 §4.1 mechanics; the PNG is 57 tall so 65x58 is unreachable; not reserved.
- J1 chips are not focus stops — keeps the tested focus model (rail → scene); W0-SHOT's open observation, not a §6 question.
- J6/J7/J8/J9/J10 — mechanics inside TOWN-08 / CRITIC-G03 / W0-TEXTSCALE / KIT-15 text.
- Q06 (reputation chip gem) untouched — still gem.png. Nothing reserved for the designer was decided.

## Minors (none blocks)

- **M1** Frame.gd's working copy is CRLF while HEAD and `.gitattributes` (`*.gd eol=lf`) are LF; git normalises on commit, Godot parses it. Hygiene.
- **M2** `RAIL_LABEL_FLOOR = Type.NAV - 2` is an absolute 16px, so at text_scale 150 "Adventure's Board" is drawn at 16px beside 27px neighbours (Town_text150 rail crop viewed) — the one label the scale setting does not reach. Inside the plan's text (CRITIC-C13 "keep the label whole"; the alternative is the ellipsis) and recorded as J2/A8 in the report; worth a Q16 note (a scaled floor `Type.at(NAV-2, pct)` + ellipsis is the other reading).
- **M3** Process: the unit applied handoff-W1-CHROME edits 1-7 to Frame.gd itself instead of leaving them for the orchestrator (§0.2). Same hexes, tree parses, flagged in the handoff — no defect.
- **M4** The report's `verify_fast=fail` is stale: the 1713-test suite is green at 16:36 (the red was W1-STAGE's, since fixed).

## Verdict

**PASS.** Every acceptance line verified against the tree (tests run, shots retaken and viewed, pixels measured); no unowned file touched by this unit; no false claim found in the report (its measurements reproduce within threshold: label edge 199 vs 200, chip span 463 vs 458 — method differences); minors M1-M4 only.
