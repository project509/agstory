# Review — W2-TOWN (the hub's callouts, sidebar and hotspots)

Reviewer: adversarial pass, 2026-09-14. Verified against the TREE (git diff, engine runs, shots), not the report.
Owned files: `game/screens/Town.gd`, `tests/unit/test_town_layout.gd` (new), plus report/handoff.

## 1. Files touched (git status --porcelain)

- `M game/screens/Town.gd` — owned. Diff read in full (343+/95-).
- `?? tests/unit/test_town_layout.gd` (+ `.uid`) — owned, new. Read in full (408 lines, four-space).
- `?? build/plan/report-W2-TOWN.md`, `?? build/plan/handoff-W2-TOWN.md` — the unit's plan files.
- Every other changed file in the status belongs to another wave-2 unit (Board/Market/RaidView/Results/Tavern/STAGE2 files, their tests, reports, handoffs); nothing in the Town diff or the report shows this unit touching any of them. `aguildstory.zip` is untracked and predates this unit (not attributable).

## 2. Findings (as found)

(appended as the review goes)

### F1. Engine runs (observed, not reported)
- Four shots through the lock (`scratchpad/shots.sh`): `Town --fixture` → `build/shots/review-W2-TOWN-fixture.png` (SHOT OK); `--fixture --focus` → `review-W2-TOWN-focus.png` (log: `FOCUS Nav_home<Button> at 0,105 211x55`); `--fixture --set=text_scale=150` → `review-W2-TOWN-t150.png`; no fixture → `review-W2-TOWN-day1.png`. All exit 0.
- `verify.sh --fast` through the lock: LINT OK · MOTION LINT OK · PARSE_CHECK 166 scripts · ART CHECK 184 agree 0 DIFFERS · `TESTS PASSED 1806 test(s) in 86 file(s) [38287 ms]` · VERIFY OK. Matches the report's numbers.
- Unit suite run directly (`run_tests.gd`): `TESTS PASSED 1806 test(s) in 86 file(s) [37119 ms]`, exit 0. 87 .gd files in tests/unit = 86 TestCase files + a11y_smoke; `grep -c "^func test_"` over the dir = 1806, of which test_town_layout.gd = 5 — the five new tests are in the run and green.

### F2. The fixture shot, with my eyes (review-W2-TOWN-fixture.png, plates2x / anchors2x / guildhall2x / smith2x crops)
- Five plates, each with its grid icon (banner, tankard, scales, padlock, notice board), the chamfered two-line rim, a shadow, a 14x8 tail. Interior fill measured from the PNG: all five are 80px tall (84 with the rim) — the Blacksmith is the same height as the others. Fill x-ranges measured: Guildhall 360..521, Tavern 771..913, Market 979..1124, Blacksmith 626..897, Board 563..800 → rim right edges 523/915/1126/899/802; max 1127 < 1141. Matches the report's rects within 2px.
- Tail apexes (anchors2x crop, magenta = `BUILDINGS[].anchor`): Guildhall on the big tent's right foot (the plate hangs off the tent's right side); Tavern on the crate stack at the mess tent's foot; Market on the garden beds' top fence corner; Blacksmith a slanted tail onto the forge/bench's top-right corner; Board on the bridge's right railing post. Every apex is on or at the foot of the thing it names — met.
- Blacksmith: title and padlock dimmed, "Canon lists this one as a maybe." in CAUTION on the second row, one line, the verb row hidden. Visibly locked.
- Figure boxes recomputed from stage_camp.json + actors.json at figure_scale, CAMP_OFFSET (-46,-62) — twelve boxes — against the measured plate rects grown by 8px: no intersection (`review-W2-TOWN-boxes.png` overlay). TOWN-07 met on the real render, not only in the test's synthetic settle.
- Sidebar: guild name, the NextMission card (art well with a "Next mission" caption plate, "Adventure 0", "Trash · 1 enemies · about 6 rounds"), ONE crimson "Open the board", the gold "Next at Known: Guildhall facility upgrade I; Quest board.", "Today: 12 raiders · morale 46 · slightly annoyed", "Nothing on the log yet.", "Board: Level 1 of 3 — reputation raises this, not gold.", rule, quiet "Back to menu". Panel's right rim at x≈1515 (inside 1519).
- Strip: roster strip with ◄ ► and "1/3"; the log shows "Nothing has happened yet." + "Raids and rests write here." with no glyph (the Cards.gd handoff).

### F3. Focus shot: the 2px steel ring is on `Nav_home` ("Camp") at rail (0,105) 211x55 (`review-W2-TOWN-focus-crop.png`). RULES-06 stays as built — met.

### F4. text_scale 150 shot (review-W2-TOWN-t150.png)
- Sidebar fits: "Back to menu" at y≈646 inside the panel; the guild name whole; plates grow to ~100 tall and stay inside the band; the Blacksmith reason still one line.
- MINOR: the card's facts line trims with an ellipsis at 150 ("Trash · 1 enemies · abou…"; `facts.max_lines_visible = 1 if pct >= 150`). docs/13 §4.4 says reflow by rows, never truncate — this is a Label the unit owns showing a trimmed value at 150. It is neither a morale value, state word nor class name (the §4.4 hard list), the same facts print in full on the Board, and the report declares it "by design", so minor rather than an unmet CRITIC-G15. A second row (ART_H 48→36) would fix it.
- MINOR: at 150 the "Next mission" caption plate (top-left of the 48px art well) covers most of the encounter thumbnail — only a sliver of the art shows. At 100 the thumbnail reads fine.
- Not this unit's: "Warrior — Very Happ" clipped in the roster strip card (Cards.gd), the rail's "Adventure's Board" at a smaller size (Frame).

### F5. Day-1 / no-fixture shot (review-W2-TOWN-day1-sidebar.png): "A Guild Story" heading, card says "Nothing pinned yet / The guild has no content loaded to pin.", "Open the board" enabled, "Today: no raiders yet — the Tavern is up the road.", "Nothing on the log yet.", the Board level line, quiet "Back to menu". Nothing crashes, nothing clipped.

### F6. a11y_smoke (run myself, not in --fast): `A11Y SMOKE PASSED 26 screen mount(s)`; Town `ok` on both sweeps (empty: focusable 12 reachable 12 disabled 2; fixture: 14/14, disabled 2), no `warn`. Exit 0.

### F7. Refdiff, re-run on my shots
- Town vs 3, mask 0,77,1536,649: BEFORE (`review-W1-KIT-fix-Town.png`) mae 35.857 · structure 0.2055 · IoU 0.1106 · within-8 50.72; AFTER (`review-W2-TOWN-fixture.png`) mae 35.934 · structure 0.2067 · IoU 0.1110 · within-8 50.60. Identical to the report's numbers; +0.08 mae and -0.12pt within-8 against +structure/+IoU — flat within the noise the plan allows. Does not regress.
- Callout region (386,115,224,57) vs Concept 3, the unit's paste-at-origin method reproduced with MY Tavern plate: BEFORE (unit's `plate_before.png`, the W1-KIT plate with the empty well) mae 43.73 · structure 0.2168 · IoU 0.1514 · within-8 23.94; AFTER mae 43.03 · structure 0.2471 · IoU 0.1793 · within-8 17.64. Three of four improve; the method is contrived (our Tavern plate sits at 769,150, not where the reference's does) but it is the only way to score the region and the report says so. `W2-TOWN-plate-vs-ref.png` viewed: the reference plate is ~55 tall with a tight two-line layout, ours 84 with the icon — the kit's height, filed as a handoff observation.

### F8. Code-level contract checks (Town.gd, test_town_layout.gd)
- Indentation: Town.gd all tabs (no space-led line), test file all four-space (no tab-led line). Godot parsed both (PARSE_CHECK 166).
- No `create_tween`, no `reduced_motion`, no `class_name`, no `$GODOT`/`OS.execute` in either file. `_ready()` only calls the idempotent `build()` (unchanged pattern). Nothing parented to the router host. No new PNG, so no baked text / .import question.
- Every API the unit calls exists at the wave start: `Widgets.building_callout(name, sub, reason, icon, anchor, bounds)` (Widgets.gd:1203), `Widgets.reasoned/cta/panel/button_of`, `Theme_.scale_of/flat/current`, `Cards.encounter_art/recent_events/event_log/roster_strip`, `RaidPlan.ladder/locked_reason/next_open_mission`, `GameState.rung_resolved/has_cleared/skipped_tutorials/selected_encounter_id`, `Enums.morale_band_name/encounter_kind_name_of`, `ScreenRouter.screen_exists`. `Icons.at("lock", "16")` resolves to grid/lock_16.png (Icons.gd has a "lock" role, not the plan's "ui" spelling — the right adaptation).
- Asserted strings/nodes: "Guildhall"/"Tavern"/"Market"/"Adventure's Board"/"Blacksmith" stay Button texts inside the plates; "maybe", "Reach Respected", "Costs 300 G", "Not built in this version yet." print through the kit's Reason Label; "Next at Known"/"Quest board" via `_town_unlock_line()` verbatim; "Level 1 of 3 — reputation raises this, not gold." kept (now prefixed "Board: "); Blacksmith a disabled Button. test_screens.gd:221-430 green in the run. The removed `"tagline"` opt is inert since Frame.LOCKUP landed (Frame.gd:179 "ignored since Q05").
- FOCUS_ALL: callout title Buttons (kit default, asserted by the new test), `Widgets.cta`, `Widgets.button` — a11y ring 14/14 on the fixture. Disabled controls: the Blacksmith carries its Reason Label; the CTA goes through `Widgets.reasoned` (reason only when the Board scene is missing).
- No pure black/white: `Color(0,0,0,0)` is a transparent border, not a paint; fills are Palette tokens.
- Plates renamed `Callout_<id>` (the kit names them "Callout"); nothing outside test_widgets_kit (which tests the kit's own return) looks up the bare name — fine.
- `_settle_callouts.call_deferred(plates)` — a one-shot deferred pass inside build(), not `_ready` logic; a screen-side workaround for a kit first-pass growth, honestly recorded in the handoff as an observation for W3-KIT2.

### F9. Handoff (handoff-W2-TOWN.md)
- §1 Cards.gd:438 and §2 Cards.gd:465: `old:` blocks match the tree byte-for-byte (tabs), `new:` blocks tab-indented, one edit per heading — exact.
- §3 says `game/screens/Town.gd:462`; the line is actually **525** (the `old:` text is exact and unique, so the edit still applies). MINOR: wrong line number.
- Three observations (locked plate three rows; plate 84 vs reference 52-57; the first-pass growth) are labelled as observations, no edits. Fine.

### F10. BLOCKER — the unit decided Q13's copy (§6, reserved for the designer)
- `_unlock_reason()` (Town.gd:553) now returns `"Canon lists this one as a maybe."`; the tree at the wave start returned `"Canon lists this one as a maybe. Disabled in this build."` (diff; spec 10 §audit:132 records the two-sentence string as what the Town prints).
- The plan reserves this: §6 Q13 — "what does a player read on the locked Blacksmith callout … | TOWN-02 (copy half), TOWN-20 — **the strings stay verbatim**"; the W2-TOWN finding line — "the copy is Q13". The unit's own comment (Town.gd:545-548) acknowledges "Q13 owns the player-facing copy" and then removes a sentence of it (J3 in the report).
- The acceptance ("one-line reason") did not force it: the unit already sets the Reason Label `AUTOWRAP_OFF`, so the full two-sentence string would still be one line — the plate widens to ~406px, which fits the Blacksmith band (right edge 900) and stays >= 8px off every figure box at 100 (checked against the twelve boxes: the widened rect x 494..900 y 395..479 touches none).
- Aggravating: the new test pins the decision — `test_town_layout.gd:346` asserts `reason.text == "Canon lists this one as a maybe."` and `:353` asserts "Disabled in this build" is absent — so the designer's eventual Q13 answer now has to edit a wave-2 test as well as Town.gd.
- Fix (two edits, both in owned files): restore the string in `_unlock_reason` (keep `AUTOWRAP_OFF` so it stays one line), and drop the exact-text assertion at test_town_layout.gd:346 (assert `contains("maybe")` instead) and the "build note is gone" assertion at :353. test_screens.gd:353's "Disabled in this build" check is for the flag-ON path only and is unaffected.

### F11. Judgement calls J1-J5 against the plan
- J1 (plates beside the building, `band` slides them off a doorway figure, tail slants): within TOWN-01/07's text; `band` is `building_callout`'s existing `bounds` parameter. OK.
- J2 (hide the kit's Subtitle on a locked plate so it is two rows): "Improve gear" is asserted by nothing; TOWN-02's acceptance is the height. OK, recorded for W3-KIT2.
- J3: see F10 — NOT the unit's to make.
- J4 (sidebar text width 310): a layout number. OK.
- J5 (KIT-08's quill cannot be passed; handoff): correct — `Cards.event_log` has no glyph parameter and Cards.gd has no owner this wave. Left honestly.
- `HUB_CTA := "board"` — the plan's landed default (§0.6). OK.
- `Icons.at("lock", "16")` for the plan's `Icons.at("ui", "lock_16")` — the plan's spelling does not exist in Icons.gd; the unit used the role that does. OK.

## 3. Acceptance lines (the plan's ### W2-TOWN Acceptance)

| Line | Met | Evidence |
|---|---|---|
| Five plates with an icon, chamfered two-line rim, shadow, tail whose apex sits on the building | yes | F2: review-W2-TOWN-fixture.png, plates2x/anchors2x crops; apexes on the tent foot / crate stack / bed fence / forge corner / bridge post |
| Blacksmith plate same height, dimmed, one-line reason | yes (height/dim/one line) — but the one-line reason was reached by rewriting Q13's copy, see F10 | fill 80px on all five plates; smith2x crop; Town.gd:553 |
| No plate crosses x=1141 | yes | measured rim right edges 523/915/1126/899/802; max 1127 |
| Sidebar shows an encounter thumbnail and one crimson button | yes | F2; the day-1 shot shows the well with the fallback art; one `ButtonCta` asserted by the new test |
| test_screens.gd:221-430 Town assertions green | yes | TESTS PASSED 1806 (verify + direct run) |
| test_town_layout.gd green | yes | 5 tests in the 1806; no FAIL lines |
| refdiff Town vs 3 masked does not regress; callout region vs Concept 3 improves | yes | F7: 35.857->35.934 mae (noise), structure/IoU up; region mae/structure/IoU improve, within-8 drops |
| `--focus` shot shows the ring on Nav_home | yes | F3 |
| Shots: `--fixture`, `--fixture --focus`, `--fixture --set=text_scale=150`, no fixture | yes | all four taken and viewed (F2-F5) |
| Green: title Buttons named "Button" inside the plates keep their texts; every callout Button FOCUS_ALL; no `_ready` logic; tweens only through Widgets | yes | F8 |
| Wave-2 common: delete `_chips()`, `Frame.standard_chips`, `ButtonQuiet` back button, text150 shot with no clipped Label the unit owns | mostly — the facts line trims with an ellipsis at 150 (F4, minor) | Town.gd:153, :350; t150 shot |
| KIT-08 quill glyph on the empty log | not met, correctly left | Cards.event_log has no glyph parameter; handoff §1-§3 |

## 4. False claims in the report
None found. Every number I re-measured (plate rects, heights, max x, refdiff before/after, region scores, test count, a11y result) matches the report. The probe figures "456/586 at 100, 557 at 150" come from a scratchpad probe not in the tree — unverifiable, but the 150 shot shows the panel fitting.

## 5. Verdict: FAIL (one blocker, minors listed)
- BLOCKER F10: the locked-Blacksmith copy is Q13's and the unit rewrote it (and pinned the rewrite in its test). Two-edit fix in owned files.
- MINOR F4a: card facts line ellipsis-trimmed at text_scale 150 (docs/13 §4.4 prefers a second row).
- MINOR F4b: at 150 the caption plate hides most of the 48px encounter art.
- MINOR F9: handoff §3 cites Town.gd:462; the line is 525.
Everything else — five iconed tailed plates off the figures, the locked treatment, the next-mission sidebar with one crimson control, ButtonQuiet, the dead builders gone, the hint on the log, 1806 tests, a11y both sweeps, MOTION LINT OK, refdiff flat — is met and verified on the tree.

---

# Repair-pass review — W2-TOWN (2026-09-14, second adversarial pass)

Verifies the repair of F10 (blocker), F4a/F4b/F9 (minors) against the TREE. Written as it goes.

## R-1. Files touched
- `git status --porcelain`: the same set as the first pass — `M game/screens/Town.gd` (owned), `?? tests/unit/test_town_layout.gd` + `.uid` (owned), the unit's report/handoff. Every other entry belongs to another wave-2 unit or predates the unit (`aguildstory.zip`). Nothing in the Town diff or the report shows this unit touching a file it does not own.
- `git diff -- game/screens/Town.gd` read in full (350+/94-). Test file read in full (422 lines).

## R-2. Findings (as found)

### R-F1. Engine runs (observed by this pass, through the lock)
- `Town --fixture` → `build/shots/review-W2-TOWN-r2-fixture.png` SHOT OK exit 0; `--fixture --set=text_scale=150` → `review-W2-TOWN-r2-t150.png` SHOT OK exit 0 (scratchpad/rev2.sh, rev2.log).
- `verify.sh --fast` exit 0: LINT OK · MOTION LINT OK · PARSE_CHECK 166 · ART CHECK 184 agree 0 DIFFERS 0 MISSING · `TESTS PASSED 1806 test(s) in 86 file(s) [64882 ms]` · VERIFY OK. 87 files in tests/unit = 86 TestCase + a11y_smoke; `grep -c "^func test_"` = 1806 with test_town_layout.gd = 5, so the five town tests are in the run and green.
- `a11y_smoke.gd` run by this pass: `A11Y SMOKE PASSED 26 screen mount(s)`; Town `ok` on both sweeps (empty 12/12 disabled 2; fixture 14/14 disabled 2), no `warn`, exit 0. (The repair report did not re-run it; it is green on the tree.)
- refdiff Town vs 3, mask 0,77,1536,649 on MY r2 shot: mae 35.934 · structure 0.2067 · layout_iou 0.111 · within-8 50.6 — identical to the report's post-repair numbers and to the pre-repair AFTER; no regression.

### R-F2. F10 (blocker) — FIXED on the tree
- `game/screens/Town.gd:561` returns `"Canon lists this one as a maybe. Disabled in this build."` — byte-identical to HEAD's :305 (`git show HEAD:game/screens/Town.gd | grep maybe`). The docstring at :551-555 now names Q13 and "the strings stay verbatim".
- `Town.gd:257-259` keeps the kit's Reason Label `AUTOWRAP_OFF`, so the two-sentence string is one line.
- `tests/unit/test_town_layout.gd:348-349` asserts `reason.text.contains("maybe")` and `autowrap_mode == AUTOWRAP_OFF`; the exact-text assertion and the "build note is gone" assertion are gone (grep "Disabled in this build" in the test file: no hits). The designer's Q13 answer no longer has to edit a wave-2 test.
- Shot, with my eyes (`review-W2-TOWN-r2-smith2x.png`): padlock + "Blacksmith" dimmed, the full two-sentence reason in CAUTION on ONE line, chamfered rim, shadow, the slanted tail onto the forge's foot.
- Measured from the PNG (rim pixels): Blacksmith rim x 503..899, y 395..478 → 397x84; Guildhall rim y 166..249 → 84. Same height — met. Max right edge 899 < 1141.
- Figure boxes recomputed (stage_camp.json + actors.json, figure_scale, CAMP_OFFSET (-46,-62), twelve boxes) against 503..899 x 395..478 grown by 8: no hit, none within 8 (nearest: warrior_0 bottom 370 vs plate top 395 = 25px; cleric_b_4 right 442 vs plate left 503 = 61px). The report's claim holds.

### R-F3. F4a (minor) — FIXED
- `Town.gd:385` `facts.max_lines_visible = 2` at every scale; `facts.name = "Facts"`; test :369-374 pins autowrap WORD_SMART and `max_lines_visible >= 2`.
- 150 shot (`review-W2-TOWN-r2-t150-sidebar2x.png`): "Trash · 1 enemies · about / 6 rounds" on two rows, no ellipsis; "Back to menu" whole inside the panel (~y 667 vs panel bottom ~722). At 100 the facts stay one line.
- Residual (not new, minor at most): `text_overrun_behavior` is still TRIM_ELLIPSIS, so a long facts string (e.g. a "Mini-boss · N enemies · about NN rounds · CLEARED" rung) could still trim at 150 if it needs a third row. The fixture's rung fits; not exercised by any shot.

### R-F4. F4b (minor) — FIXED
- `Town.gd:370` caption tag is `LabelSmall`; test :377-380 pins the variation. 150 shot: the tag sits in the well's top-left and ends ~well-x 131; the tentacle thumbnail stands whole to its right (~well-x 146..163). The tag is still ~34 of the well's 48px tall on the left — a strip with a tag on it, as the report says (J6) — but the art reads whole, which is what F4b asked.

### R-F5. F9 (minor) — FIXED
- handoff §3 says `Town.gd:532`; `grep -nF` finds the exact `old:` text at line 532, tab-indented (`^I` under cat -A). §1/§2 `old:` blocks match Cards.gd:438 and :465 byte-for-byte (tabs). One edit per heading; exact.

### R-F6. Contract checks after the repair (Town.gd, test_town_layout.gd)
- Indentation: no space-led line in Town.gd; no tab-led line in the test. PARSE_CHECK 166 green.
- No `create_tween`, `reduced_motion`, `class_name`, `OS.execute`, `$GODOT` in either file. `_ready()` only calls the idempotent `build()` (unchanged from HEAD). No new PNG. Nothing parented to the router host (the test mounts through `register_host` + `goto`).
- `Color(0, 0, 0, 0)` at :366 is a transparent border, not a paint; the other literal is a Palette token with alpha.
- Asserted strings intact: five building names as Button texts, "maybe" (now the full Q13 string), "Reach Respected"/"Costs 300 G"/"Not built in this version yet.", "Next at Known", "Level 1 of 3 — reputation raises this, not gold.", Blacksmith a disabled Button; test_screens.gd:290-371 green in the run.

### R-F7. Judgement calls J6-J8 against the plan
- J6 (caption stays on the art at every scale, LabelSmall): a layout choice inside the unit's own sidebar; the plan reserves nothing here. OK.
- J7 (150 gap 6→5, card bottom margin 8→6 at 150; 100 untouched): layout numbers. OK.
- J8 (`facts.name = "Facts"`): a node name no test outside the unit reads. OK.
- J3 withdrawn; the Q13 string is verbatim. No decision reserved for the designer (§6) is taken by the unit any more.

### R-F8. MINOR (cross-unit, recorded not fixed) — the verbatim Blacksmith plate and W2-STAGE2's speech plate collide
- At 100 the 397px plate's left rim (x 503) sits directly against the speech plate's right edge (row 440: bubble fill at x ≤ 502, plate rim at 503) — zero air, the two dark boxes read as one bar (`review-W2-TOWN-r2-scene.png`). At 150 the 570px plate covers the speech plate almost entirely (`review-W2-TOWN-r2-t150-scene.png`) and its top is 5px from warrior_0's box (inside the test's 8px, which is pinned at 100 only).
- Attribution: the speech plate's position comes from `stage_camp.json`'s `speech.speaker` list — a W2-STAGE2 change in this same wave (the bubble now moves among speakers per line), so the Town's anchors could not have been placed against it at the wave start; and the plate's width is Q13's copy. The unit records it in the report's "Observation" for the designer. It is not in the handoff file — the orchestrator should carry it to the wave-end composition pass (either the speech plate moves off the lantern-tent figure's right side, or the locked plate's `band` shifts once Q13 is answered).
- Not a failing acceptance line: TOWN-07's contract is figure body boxes, met at 100; the 150 line is "no clipped Label the unit owns", met.

## R-3. Acceptance lines after the repair

| Line | Met | Evidence |
|---|---|---|
| Five plates: icon, chamfered two-line rim, shadow, tail apex on the building | yes | R-F2 shot; unchanged from pass 1 (F2) |
| Blacksmith plate same height, dimmed, one-line reason | yes — and the reason is Q13's verbatim string | rim 84px on both Guildhall and Blacksmith (PNG); smith2x crop; Town.gd:561 == HEAD |
| No plate crosses x=1141 | yes | max rim right edge 899 |
| Sidebar: encounter thumbnail + one crimson button | yes | sidebar2x crops at 100 and 150; test pins one ButtonCta |
| test_screens.gd:221-430 Town assertions green | yes | TESTS PASSED 1806 (my run) |
| test_town_layout.gd green | yes | 5 tests in the 1806, no FAIL |
| refdiff Town vs 3 masked does not regress; callout region improves | yes | R-F1 (identical to pass 1's AFTER); region numbers unchanged from pass 1 (F7) — no chrome in the region moved |
| `--focus` shows the ring on Nav_home | yes (pass 1 F3; the repair touched nothing on that path — a11y ring 14/14 re-run here) | review-W2-TOWN-focus-crop.png |
| Shots: fixture / focus / text150 / no-fixture | yes | fixture + t150 retaken and viewed this pass; focus + day1 from pass 1 |
| Green: titles keep texts, callout Buttons FOCUS_ALL, no `_ready` logic, tweens via Widgets | yes | R-F6; test :322-323 |
| Wave-2 common: `_chips()` gone, `Frame.standard_chips`, `ButtonQuiet`, text150 with no clipped owned Label | yes | Town.gd:147-152, :318; t150 shot — facts now two rows, no ellipsis |
| Designer-reserved decisions (§6) untouched | yes | Q13 string verbatim; HUB_CTA = "board" is the plan's landed default |
| KIT-08 quill on the empty log | not met, correctly left | Cards.event_log has no glyph parameter; handoff §1-§3 exact |

## R-4. False claims in the repair report
None found. Every number re-measured this pass (plate 503..900 x 395..479 → rim 503..899 x 395..478; 84px on both plates; no figure hit/within-8 at 100; refdiff 35.934/0.2067/0.1110/50.60; 1806 tests; handoff line 532; the tag/thumbnail x-ranges at 150) agrees with the report within 1px. The probe figures (456/586 at 100, 578/586 at 150) come from a scratchpad probe not in the tree — unverifiable, but the 150 shot shows the panel fitting.

## R-5. Verdict: PASS (minors only)
- F10 blocker fixed exactly as prescribed (string verbatim, AUTOWRAP_OFF, test relaxed).
- F4a/F4b/F9 fixed and verified on the tree.
- MINOR R-F8: the widened locked plate abuts (100) / covers (150) W2-STAGE2's speech plate — cross-unit, Q13-dependent, recorded in the report; the orchestrator should carry it to the wave-end composition pass.
- MINOR R-F3 residual: the facts Label keeps TRIM_ELLIPSIS with max 2 rows — a long rung string could still trim at 150; not exercised by any shot.
