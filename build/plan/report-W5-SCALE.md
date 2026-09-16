# W5-SCALE — the 150% pass, and text_scale's layout half (M6-A11Y-05)

Wave 5, 2026-09-15. Owned: Guildhall.gd, Tavern.gd, Completion.gd, Town.gd, Settings.gd, LoadSave.gd (TABS), RaidPrep.gd, Results.gd (SPACES), RaidView.gd (line 1725 only), tests/unit/test_text_scale_layout.gd (new).

## Acceptance

- [x] A1 tests/unit/test_text_scale_layout.gd: 13 routes x 100/125/150 with the reference fixture; no Label overflows its rect, no clip_text Label clips; estimator self-test; allow-list empty for owned screens
  - tests/unit/test_text_scale_layout.gd, 9 tests green (3.7 s); KNOWN holds only rows for screens this unit does not own plus Results' page caption (the kit's placement); the sweep is 13 x 3 = 39 mounts, 2,600+ controls placed.
- [x] A2 Guildhall sidebar roster block at 150 no longer clips the morale chart
  - `_snap_fold` + `FoldSpacer` in Guildhall._sidebar; `fold_height()` pure and tested; Guildhall_text150.png shows the fold under the facts, no sliver.
- [x] A3 Tavern seat card fits its authored face at 150
  - the morale line on LabelClass (the sheet's face), the class line on LabelMuted+TEXT_SLATE with line_spacing 0, Look on ButtonCardAction, gaps 2/1 — 236 of 238 worst case; Tavern_text150.png / crop_Tavern_seats_100_and_emoji150.png.
- [x] A4 Completion CTA fits its plate at 150 (Button text verbatim)
  - `_gap()` 10/8/6 by scale, the roll's class word face-free, BTN_H through Type.at; Completion_text150.png: three verbatim lines inside the sidebar.
- [x] A5 Settings CTRL_H through Type.at; chip/value buttons fit COL_CTRL_W x CTRL_H at 150 (asserted)
  - `_ctrl_h()` at the cell and the three sidebar buttons; test_settings_controls_fit_their_scaled_cell_at_150 (every row: cell == 150x54, control minimum fits); Settings_text150.png.
- [x] A6 RaidPrep.gd:574, Results.gd:715, RaidView.gd:1725 through Type.at(<const>, Theme_.scale_of(self)); `_raider_row` deleted
  - RaidPrep.gd:575 Type.at(Widgets.SIZE_META, scale) (+ `const Type`), Results.gd:715 Type.at(Type.SMALL, scale), RaidView.gd:1725 Type.at(Type.FIGURE_XL, scale) — RaidView's diff is that one line; `_raider_row` deleted (RaidPrep.gd 928 -> 897 lines).
- [x] A7 Town sidebar says the number of events the log shows
  - Town._today_lines counts `min(events, fit)` with the log's own arithmetic (6), Cards.EVENT_HEAD_H (a wave-start const) rather than KIT3's new `Cards.ROWS`.
- [x] A8 Shots viewed: Guildhall/Tavern/Completion/Settings at --fixture --set=text_scale=150
  - Guildhall/Tavern/Completion/Settings at --fixture --set=text_scale=150 (+ Completion --completed) in build/shots/w5scale/, each viewed and described above.
- [x] A9 test_screens, test_roster_layout, test_options_layout, test_prep_layout, test_raid_beats, test_wipe_sequence, test_sidebar_fit, test_text_scale green unchanged
  - RUN_TESTS_ONLY batch of the 11 named files + test_tavern: 214 tests green before the test file existed; all inside the 104 files of the final gate.
- [x] A10 verify --fast green; lint_motion OK
  - verify --fast: VERIFY OK, TESTS PASSED 2037 test(s) in 104 file(s) [39837 ms]; lint_motion: MOTION LINT OK.

## Log

- Read: LESSONS.md, BUILD_STATE Current focus, RULES §1-§3, 00-plan §0.3-§0.6, audit M6-A11Y-05 (remaining_work), report/handoff-W4-PIP (the sidebar Note, the seat-card face), the owned files. Probe FIRST (scratchpad/layout_dump.gd, headless, in the tree, 12 settle frames, fixture + completed, one lock hold for 150 and 100): every visible Label/Button with its real rect, its string width at its real font, its line counts — `dump_150.txt`/`dump_100.txt`. The harness fact that shapes the unit: `tests/run_tests.gd` runs before the root enters the tree, so containers never lay out and `get_combined_minimum_size()` is a stale cache — the test's "layout pass" is therefore its own width-first estimator with the theme's real fonts (`get_theme_font`/`get_theme_font_size` resolve off-tree; the Label's internal shaping does not), validated against the in-tree dump.
- Measured at 150 with the fixture (the three known breaks, exact): Tavern seat cards with a wrapped class line ("Warrior — Common" 199px in 191) — the card's column wants 255 in 238, the Look button 17px through the rim; Completion — the sidebar column wants 918 in the pad's 861, the CTA's plate (3 lines, 133 tall) bottom at y=1029 in a 1024 frame; Guildhall — the roster block's chart (56px well) sits at the scroll's fold with ~10px showing. Also found: Settings' chips are 150x37/38 in a 60px row (fit); LoadSave's head row fits (its "\n" Label is 363 wide = its longest line); Town has no cut line at 150.
- Screen edits landed (all parse; the 12 neighbouring test files green, 214 tests):
  - Guildhall.gd: `_snap_fold()` on `SideColumn.sort_children` + a hidden `FoldSpacer` — the scroll's fold moves up to the last block boundary that fits so no block is sliced (the chart is whole or below the fold, with the theme's visible bar); `fold_height(heights, sep, avail)` is the pure arithmetic. JUDGEMENT CALL: "scroll it" rather than "its scaled height" — the column already scrolled; what was wrong was the fold slicing a block. Roster.gd (not owned) still charges the face sheet's height on four fact lines that print no face (36 vs 29 at 150): handoff note.
  - Tavern.gd `_candidate_card`: class line on LabelMuted + TEXT_SLATE + line_spacing 0 (no face tax on a line that prints no face), morale line on the face-carrying LabelClass (the authored face, 36/24), Look on ButtonCardAction (the kit card's action plate) — worst case at 150: 72+58+61+37+8 = 236 of 238.
  - Completion.gd: `_gap()` (10/8/6 by scale, floor), the roll's class word on LabelMuted+TEXT_SLATE (63 not 70 a row at 150), `BTN_H` through Type.at. At 150 the column is ~850 of 861.
  - Settings.gd: `_ctrl_h()` = Type.at(CTRL_H, scale) at the control cell and the three sidebar buttons.
  - Town.gd: "N recent events" counts `min(events, fit)` with the log's own arithmetic (6).
  - RaidPrep.gd:574 → Type.at(Widgets.SIZE_META, scale) (+ `const Type`); `_raider_row` (RaidPrep.gd:639-668) deleted. Results.gd:715 → Type.at(Type.SMALL, scale). RaidView.gd: one line (1725) → Type.at(Type.FIGURE_XL, scale).
- THE HARNESS FACT (scratchpad/theme_probe.gd, one lock hold): in `_initialize` a LabelBody under a themed host answers 16px to `get_theme_font_size()` — the theme lookup does NOT resolve off-tree, contrary to what the plan assumed; `Frame._theme_font` exists because of it. What does work is `notification(NOTIFICATION_THEME_CHANGED)` sent by hand: after it the Label answers 23px at 150 and `get_minimum_size()` = (199, 36) — the real Fira + the face sheet's line height, exactly the in-tree dump's numbers. `Label.get_line_count()` still answers 1 off-tree, so wrapped lines are counted with `TextParagraph` on the Label's own font. Containers never sort and `get_combined_minimum_size()` stays a cache, so the layout pass is the test's own width-first estimator (BoxContainer with expand/stretch/alignment, Margin, Panel, Scroll (the clip opens along the scrolling axis), Grid, HFlow, Center, coordinate-placed children by anchors/offsets grown to their minimum in their grow direction, self-placing callouts by their `Tail`), with every leaf's minimum asked of the engine after the refresh.
- tests/unit/test_text_scale_layout.gd (spaces, 9 tests, 3.7 s): the sweep (13 routes x 100/125/150, fixture + recorded raid + completed), KNOWN allow-list (LIES mechanism: a row that matches nothing fails), four estimator self-tests (a wide one-liner names the Label and the column's width; a clip_text Label narrower than its string; max_lines_visible under a three-line wrap; a column taller than its clipping box with one finding, not one per row), the fonts check (LabelBody 36 / LabelMuted 29 at 150 as the tree measured; an unrefreshed Label answers the fallback — the fact the door exists for), and the three 150 breaks held: `Guildhall.fold_height` arithmetic + the wiring (`SideColumn.sort_children` → `_snap_fold`, `FoldSpacer` beside the scroll); the seat cards at 150 (`_wants_h(card, 215) <= 262` for all four, the morale line on LabelClass with the sheet, at least one wrapped class line — the case that broke); Completion's commit ends inside the sidebar at 150 and wraps rather than trims, `BTN_H` scaled; Settings' cell == COL_CTRL_W x Type.at(CTRL_H,150) on every row and every control's minimum fits it (54 ≤ ROW_H 60).
- Estimator vs the in-tree dump: the trims it lists at 100 are the dump's (Results' 33 log rows with the ellipsis, Tavern's "Brenda Ironbelly" 136 in 125); at 150 the kit card's class word beside the portrait ("Warrior" 77 in 65) on every hub strip, the dump's rows. ONE LIMIT, measured and written in the header: a Label whose `size` a screen sets by hand before the theme reaches it is clamped by the engine to the FALLBACK font's minimum (the strip's "n/m" caption, 48x18, reads 23 tall at 100 here, 18 in the tree) — the estimate errs high by the fallback-vs-real difference, never low.
- KNOWN (all with the measured number and the owner): AdventureBoard's two max_lines_visible caps (:592 1 line under 2/3 lines; :613 2 under 3); RaidPrep's CTA cost line 4px under the Depart plate at 150 (Widgets.cta); RaidView's objective title 293/351 in 283 at 125/150; Cards.card wider/taller than 215x262 at 125/150 (Guildhall grid cells clip 4-16px; the strip cards run 12-60px under the frame on Town/AdventureBoard/Market/RaidPrep/RaiderDetail/Results); Cards.event_log's six 36px rows overrunning the 262 by 12 at 150 on five hub screens; Market's sidebar 381 in 378 at 150; Results' page caption 5/8px under the frame at 125/150 — the one row for an owned screen, because the caption is the kit's placement inside a host Results positions (CARD_Y 6 under the concept's 735). 203 findings at the sweep, 142 of them ellipsis trims (informational — the kit's band lines and the log rows; the kit debt the queue already names).
- handoff-W5-SCALE.md: three exact edits (RaidView's title steps its size down to fit, Frame._rail_label_size's idiom; Widgets.cta's cost slot scaled; Cards.event_log's fit at the scale — against KIT3's 12:10 text) + notes (Cards.card at 125/150 → fewer, wider cards per docs/13 §4.4; the page caption; Market's sidebar; the Board's caps; Roster's face-tax fact lines; the Tavern's own scrolling sidebar fold). `apply_handoff.py --dry-run`: 3/3 parse.
- Shots (build/shots/w5scale/, all viewed with the Read tool):
  - `Guildhall_text150.png`: the sidebar's fold now lands under "Tanks 1 · Healers 2 · DPS 8" — no sliver of the morale chart; a clean gap, then the rule and "Back to town" where they were; the theme's scrollbar (x≈1497) says there is more (the chart and Sort/Filter, whole, below the fold). The strip's two rows of three + "+6 more, all above 45" as before. (The kit card's band line wraps to two lines now — KIT3's change under this run.)
  - `Tavern_text150.png`: four seat cards with the AUTHORED pixel face on "starts at 46 😐" (the sheet, not a system emoji); Pauline_4's "Wizard — / Common" wraps and her Look plate sits at the same y as the others, inside the card; the other cards show one bullet line with a bar. `crop_Tavern_seats_100_and_emoji150.png` (100 above, 150 emoji-free below): at 100 the face is authored too, the class line slate, both bullets in full (four lines now) and the Look plate the card-action idiom; at 150 the pip figure "IIIII....." is even on LabelClass.
  - `Completion_text150.png`: "Back to town — / the guild carries / on" (three lines, verbatim) ends inside the sidebar (bottom ≈968 of the panel's ≈1000); the roll's twelve rows tighter (63); the credits paragraph in full. SEEN, not fixed: the report band's upward growth at 150 covers the camp's speech bubble ("I think I'm ready for a real raid thi…") — the stage's bubble is the world layer's, placed by the scene JSON; a 150 cosmetic for the stage owner.
  - `Settings_text150.png`: every control cell 150x54 (chips "1x"/"On"/"Off"/"Keep"/"150%", the volume cell's pips + "100") inside 60px rows; the three sidebar buttons 54 tall; the table scrolls.
  - `Tavern_text150.png` also shows the LEFT item: the Tavern's own sidebar scroll folds through "Not tonight" (TOWN-17's scroll; noted in the handoff, not changed).

## Gate

`GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (scratchpad/verify_W5-SCALE.log):
`PASS  class cache regenerated` · `PASS  LINT OK  no cross-file class_name references in sim/ or game/` ·
`PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)` ·
`PASS  PARSE_CHECK scanned 186 script(s)` · `PASS  16 generated file(s) agree with tools/gen_items.gd` ·
`PASS  ART CHECK  generators=7  runtime files: 204 agree  0 DIFFERS  0 MISSING` ·
`PASS  TESTS PASSED   2037 test(s) in 104 file(s)  [39837 ms]` · stages 4-8 SKIP (--fast) · `VERIFY OK`.
`tools/lint_motion.sh` -> `MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)` /
`and every colour under game/ is a Palette role (docs/13 §3)`.
(The tree carried other units' in-progress edits — Cards.gd, Widgets.gd, Theme.gd, Frame.gd and more — throughout; the gate is the tree's at 12:20.)

## Judgement calls

- Guildhall (2): "scroll it" was already true; the defect was the fold slicing a block. The fix is a fold that lands on a block boundary (a block is whole or below the fold), not a taller block — the roster block's height is Roster.gd's (not owned; its face-tax fact lines are the handoff note). At 150 the chart sits whole below the fold with the theme's bar showing; at 100 nothing moves (the column fits, the spacer stays hidden).
- Tavern (3): the card is 215x262 at every scale and its fixed parts were 255 in 238 at 150 with a wrapped class line BEFORE any face — a pre-existing 17px overflow the probe found. The three levers (no face tax on a line that prints no face; the authored face on the line that does; the kit card's own action plate for Look) are all theme-variation strings, no font override, no new kit call. At 100 the bullets gain 16px. The full answer at 150 (fewer, wider cards per page — docs/13 §4.4) is the kit's and is in the handoff notes.
- Completion (4): at 150 the commit's second line "the guild carries on" is 297px at 32px in a 314 column, so three lines are inevitable at any inset <= 8 and the plate takes the height three lines need; the room (57px) came from the roll's face-free class word (42) and a scale-aware column gap (10/8/6; 21 at 150), not from the plate.
- The estimator is the test's own, not Godot's sort (which cannot run in the harness): its leaf minimums are the engine's after a by-hand THEME_CHANGED, its containers are modelled. Trims (ellipsis) are reported, not asserted — the contract names Labels that overflow and clip_text Labels that clip; an ellipsis is the kit's designed overrun and the audit queue's named debt.
- No q-W5-SCALE.md: nothing here is reserved for the designer; the two open calls (the kit card at 150, the Board's line caps) are owners' calls and are in the handoff.

## Audit closures

- **M6-A11Y-05** — the layout half of (4) is closed: (a) `tests/unit/test_text_scale_layout.gd` mounts each of the 13 routes at 100/125/150 with the reference fixture, runs a layout pass (the estimator, with the engine's own minimums after THEME_CHANGED), and asserts no Label overflows its rect (string width vs the width the layout hands it for non-wrapping Labels; lines vs `max_lines_visible` and the rect for wrapping ones), no `clip_text` Label clips, no container outgrows its rect or its clipping ancestor; a self-test proves the estimator catches each kind; the allow-list carries the measured overflows in screens outside this unit (handoff-W5-SCALE). (b) Settings' CTRL_H goes through `Type.at` (`_ctrl_h()`, Settings.gd:124/:401 and the three sidebar buttons) and `test_settings_controls_fit_their_scaled_cell_at_150` proves every chip/value control fits COL_CTRL_W x CTRL_H at 150. (c) RaidPrep.gd:575, Results.gd:715 and RaidView.gd:1725 route through `Type.at(<const>, Theme_.scale_of(self))`; `_raider_row` is deleted. The Theme half was already closed (24cd140). The remaining 150 debts the sweep found are the kit's (Cards.card / Cards.event_log / Widgets.cta / the page caption), RaidView's title, Market's sidebar and the Board's caps — each with a number in KNOWN and a row in the handoff; they are not this item's (4) but the kit's own 150 pass.

## Left

- The kit card at 125/150 (Cards.card: wider/taller than 215x262) and Cards.event_log's row fit at 150 — not owned; W5-KIT3 is editing Cards.gd this wave; exact edit + notes in the handoff, rows in KNOWN.
- RaidView's objective title (293/351 in 283), Widgets.cta's cost slot (4px), Market's sidebar (3px), AdventureBoard's two max_lines caps — not owned; handoff §1-§2 and notes.
- Results' page caption 5/8px under the frame at 125/150 — the kit's placement in Results' host; the one KNOWN row for an owned screen (CARD_Y is the concept's measured 741). Handoff note.
- The Tavern's own sidebar scroll folds through "Not tonight" at 150 (TOWN-17's scroll) — owned, seen, left: the same `_snap_fold` would fit, but the column has no fixed footer and the design chose the scroll; noted in the handoff for the wave close.
- Completion at 150: the report band's upward growth covers the camp's speech bubble (the stage's, from the scene JSON) — seen in the shot; the world layer's owner.
- Roster.gd's face-tax fact lines (36 vs 29 at 150) — with them the Guildhall's chart would sit above the fold on its own; handoff note.

## Files

- game/screens/Guildhall.gd — `_fold_scroll`/`_fold_spacer`, `FoldSpacer` in `_sidebar`, `_snap_fold()`, `static fold_height()`.
- game/screens/Tavern.gd — `CARD_GAP`/`NAME_GAP`, the seat card's class line (LabelMuted+TEXT_SLATE, line_spacing 0), morale line (LabelClass), Look (ButtonCardAction), the header note.
- game/screens/Completion.gd — `SIDEBAR_GAP`/`_gap()`, the roll's class word (LabelMuted+TEXT_SLATE), `BTN_H` through Type.at; `const Palette`, `const Type`.
- game/screens/Settings.gd — `_ctrl_h()` at four sites.
- game/screens/Town.gd — `_today_lines` counts what the log shows.
- game/screens/RaidPrep.gd — `const Type`, :575 scaled, `_raider_row` deleted.
- game/screens/Results.gd — :715 scaled. game/screens/RaidView.gd — :1725 scaled (one line).
- tests/unit/test_text_scale_layout.gd (+ .uid) — new, 9 tests.
- build/plan/handoff-W5-SCALE.md — 3 exact edits + notes. build/shots/w5scale/ — the shots and crops named above.
