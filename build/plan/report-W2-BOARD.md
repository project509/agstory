# Report — W2-BOARD (the Adventure's Board becomes a board and a keyboard can pin a notice)

Unit: 00-plan §3 W2-BOARD. Owns `game/screens/AdventureBoard.gd`, `tests/unit/test_board_rows.gd` (new).
Findings: RULES-07, TOWN-25, TOWN-11, TOWN-24, TOWN-10, TOWN-17, TOWN-31, KIT-03, KIT-08, TOWN-09 (REFUTED — untouched).

## Acceptance

- [x] A1 Each notice row is a full-rect `ButtonNotice` named `Notice_<id>`, FOCUS_ALL, `pressed → _select(id)`;
      the rung Button keeps "<slot> — <name>", the quip/facts/reason Labels stay (test_raid_plan reads them).
- [x] A2 a11y_smoke prints no `warn` for AdventureBoard on either sweep; the Tab ring includes `Notice_A0`.
- [x] A3 Rung ladder: 20px column per row with a state glyph (cleared = gold tick, open = pin, locked = padlock
      from the icon grid) joined by a vertical line; tier dividers as LabelLabel.
- [x] A4 Cork behind (`PanelCork`), paper rows (`ButtonNotice` chrome) with the theme's `pin` icon top-centre,
      "LOCKED" / "CLEARED" via `Widgets.stamp` ("CLEARED" stays printed in the facts Label too).
- [x] A5 `_list_scroll` bound to the panel height; the bar visible inside the rim; a 24px gradient fade at the
      list bottom.
- [x] A6 The sidebar fits inside 714: standing paragraph in LabelMuted; no ScrollContainer in the sidebar;
      "Back to town" is a `ButtonQuiet` Button, whole inside the panel.
- [x] A7 `_chips()` deleted; `Frame.standard_chips(f, _state)` used; `sun.png` no longer named here.
- [x] A8 Empty states pass `Icons.at("empty", "quill")` (KIT-08).
- [x] A9 `tests/unit/test_board_rows.gd`: stepping focus through rows updates `_selected`; every row Button
      FOCUS_ALL and named; a locked notice is still pinnable; the loop's "A1 (disabled)" contract holds.
- [x] A10 test_raid_plan.gd, test_screens.gd:256-288 / :689-723, test_full_loop.gd green (verify --fast).
- [x] A11 Shots viewed with Read and described: `AdventureBoard --fixture`, `--fixture --focus --tab=N`,
      `--fixture --completed`, `--fixture --set=text_scale=150`.
- [x] A12 refdiff AdventureBoard vs 1 recorded before/after.
- [x] A13 `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` green; `tools/lint_motion.sh`
      prints MOTION LINT OK; summary lines pasted below.

## Judgement calls

- J1 (the pin, twice): TOWN-11 wants open = pin in the ladder column and TOWN-24 wants a pin on every
  paper. Both are built as written — the ladder's pin is the same theme icon as the paper's — so an open
  rung shows a pin on its rung AND a pin head on its paper. It reads as "pinned, and this is the one you
  can take"; if the doubling reads as an error to the reviewer, the ladder's open glyph is one line.
- J2 (the tick): the grid has no tick and no pin (`Icons.at("state", …)` has only the sim's states);
  the cleared glyph is two 2px ACCENT_GOLD strokes rotated about a foot, drawn in code, and the handoff
  asks W1-ICONS/W3-KIT2 for a grid tick. The padlock is `Icons.at("lock", "16")`; the pin is read off
  the theme (`has_icon/get_icon("pin", "PanelPaper")`) — no PNG path named in this file.
- J3 (selected = overrides, not toggle_mode): a toggle Button's second click un-selects it and Enter
  toggles; the selected paper instead carries the theme's ButtonNotice `pressed` box as its `normal`
  and `hover` (the steel rim), and a locked paper carries the theme's `disabled` box as `normal` (greyed
  paper) while staying ENABLED and FOCUS_ALL so a keyboard can read it. The old 3px ColorRect mark is
  gone — the steel rim is the mark.
- J4 (select without rebuild): `_select` re-dresses the two papers in place, rebuilds only the sidebar,
  and calls `Frame.focus_order(_frame)` again (ScreenRouter.wire_shell_focus wires what exists at entry;
  the sidebar's controls are new after every pin). Rebuilding the list would free the paper the keyboard
  is on. `focus_entered` on a paper OR its rung Button pins it, so the arrows walk the ladder and the
  sidebar follows (TOWN-25's second reading, built on top of the first).
- J5 (the skip block moved onto the paper): with the sidebar capped at its honest 314x571 the column was
  34px too tall at 100 and 180px too tall at 150, and TOWN-17 forbids a sidebar scroll. The forfeit
  warning + "Skip the tutorial" now sit on the SELECTED tutorial's paper (`_skip_hosts`, moved on every
  pin; the paper is "the thing being forfeited", which is the file's own rationale for the board over
  RaidPrep; the list scrolls). test_full_loop presses "Skip the tutorial" by fragment and still finds
  exactly one. At 125/150 the sidebar also drops its two-line quip teaser (the joke is on the paper in
  full) — CRITIC-G15's reflow — and the whole column, "Back to town" included, fits at 150.
- J6 (sidebar trims): art 337x104 → 314x88, sub-facts one line with an ellipsis (printed in full on the
  paper), column gap 4 → 3, skip gap 4 → 2, band margin 6 → 4. TOWN-09 (REFUTED) untouched: the loot
  row keeps `maxi(2, n)`.
- J7 (fade colour): no cork token exists in Palette (not mine to add) — the fade is
  `SURFACE_PAPER` α0 → α0.92, "the cork in shadow under the last paper"; it hides itself when the bar
  is at its end or absent (`bar.changed`/`value_changed`), and stops 8px short of the bar's column.
- J8 (`--tab=3`): Tab is a region step (`Frame.tab_steps_within_region = false`), so 3 Tabs from the rail
  land on the strip's pager; the ring-on-a-notice shot is `--tab=1` (taken as well). Both viewed.
- J9 (the rung title wraps): at 150 "A1 — Adventure 1 — Encounter 1" + LOCKED exceeded the paper and
  an unwrapped Button widened the whole board under the camp; `autowrap_mode` on the rung Button and on
  the facts Label makes them grow the row instead (identity at 100).

## Log (write-as-you-go)

- Read 00-plan §0 + §3 ownership + W2-BOARD, RULES.md §1-§5 + RULES-07/12/14, TOWN-09/10/11/17/24/25/31,
  KIT-03/08, CRITIC-C14/G15, LESSONS.md, report-W1-CHROME.md (judgement calls), handoff-W1-FRAME.md,
  handoff-W1-HALL.md, AdventureBoard.gd in full, Theme.gd (panels/buttons), Widgets.gd (stamps/buttons/
  containers), Frame.gd (chips/sidebar/focus), Icons.gd, a11y_smoke.gd (rules 6/7), test_a11y.gd (_tab),
  test_full_loop.gd (_press by fragment), test_raid_plan.gd:256-292, test_screens.gd:256-288/:685-725.
- Facts that shape the build: the harness cannot hold focus (test_a11y.gd:731-759), so the new test asserts
  the wiring (`focus_neighbor_*` / `focus_next`) and drives `focus_entered` by hand; Tab is a REGION step
  (`Frame.tab_steps_within_region = false`), so "through the rows" is the arrow step inside the scene
  region and the Tab ring's scene entry is the first FOCUS_ALL control under `p.scene` — the first row's
  `Notice_<id>` if it is the row's first child. The icon grid has `lock_16` and no tick/pin; the pin is
  the theme's `pin` icon on `PanelPaper` (`Theme_.get_theme().get_icon("pin", "PanelPaper")`).
- Baseline shot viewed: build/shots/W1F_AdventureBoard.png — PanelSteel list with PanelInset rows, the A2
  quip hard-cut at the panel bottom, no bar, the sidebar's "Back to town" link at y≈714 on a panel that
  has grown past the sidebar host.
- 18:05 AdventureBoard.gd rewritten (cork panel, ladder cells, `Notice_<id>` papers, bounded scroll +
  fade, standard_chips, ButtonQuiet back, LabelMuted standing, 314px sidebar caps, quill empty states);
  `PARSE_CHECK OK` for my two files. tests/unit/test_board_rows.gd written (10 cases). The unit suite
  cannot run yet: `game/ui/SceneStage.gd` (W2-STAGE2, mid-edit) fails to compile (`_speech_backing`
  undeclared) and every screen that loads a stage — this one included — mounts as null. Waiting on
  that file; nothing of mine to fix.
- 18:10 SceneStage.gd compiles again; unit suite run: my 10 cases pass (only failures listed are other
  units' files: test_market_grid, test_raid_overlays (parse), test_scene_stage x2, test_town_layout,
  and test_text_scale flagged MY `Theme_.get_theme()` fallback — fixed to `Theme_.current(self)`).
- 18:12 first five shots taken under one lock (all `SHOT OK`), viewed:
  - W2B_AdventureBoard.png: cork panel (speckled brown) at 228..718; "Tier 1" divider; four papers with a
    red pin head top-centre; the ladder line down x≈258 with the pin glyph on A0 (open) and padlocks on
    TR/A1/A2; A0 selected with the steel rim; "LOCKED" stamps in CAUTION, tilted, right of the rung
    titles; the bronze scrollbar grabber at x≈695, y 175..360, inside the rim; the A2 row fading into
    shadow at the list foot (the 24px fade). Sidebar: card 314 wide, text no longer overflows the pad —
    BUT the panel's bronze side rims ran to y=732 (host bottom 714): the column was ~34px too tall.
  - W2B_AdventureBoard_focus_tab1.png: after one Tab from the rail the 2px steel ring sits on
    Notice_A0 (the paper), outside its rim. tab3: rail → Notice_A0 → "Go to prep" → the strip's "<"
    pager button (Tab is a region step; the plan's `--tab=3` lands in the strip, so tab1 is the shot
    that shows the ring on a notice).
  - W2B_AdventureBoard_completed.png: "The campaign is finished. The guild is not." + "Legendaries 0 of
    9 · Records 0 of 40" under the subtitle; the list shrinks and still scrolls.
  - W2B_AdventureBoard_text150.png: the papers ran under the camp (x > 718) — an unwrapped Label
    widened the board; the sidebar's skip warning wraps to 5 lines and the column overflows under
    the strip.
- Fixes: sidebar column gap 4→3, art 96→88, sub facts 1 line (ellipsis), skip block gap 4→2, band
  margin 6→4 (−~40px); rung Button `autowrap_mode` and the facts Label wrapped at LIST_TEXT_W.
- 18:20 re-shot: sidebar rims now end at y=707 (bottom rim + chamfer visible above the strip rule at
  734), "Back to town" whole at y≈658, ~40px spare. a11y_smoke: `ok empty AdventureBoard … tab ring=2`,
  `ok fixture AdventureBoard … tab ring=4 focusable=22 reachable=22`, NO `warn` line, `A11Y SMOKE
  PASSED 26 screen mount(s)`.
- 18:32 J5 built (skip block on the paper, quip dropped at >100), test added
  (`test_the_skip_block_sits_on_the_selected_tutorials_paper_and_follows_the_pin`), the arrow-walk test
  made bounded (the ring is re-wired on every pin). Final shots (all five `SHOT OK`), viewed:
  - W2B_AdventureBoard.png: as before plus the CAUTION warning and "Skip the tutorial" inside A0's
    paper; sidebar column ends at y≈575, panel bottom rim at 707..712 (host bottom 714) — "Back to
    town" whole at y≈561. Measured: bronze side rims x=1143/1518 run y 85..707.
  - W2B_AdventureBoard_text150.png: papers inside the cork (right edge 685, bar at 695), facts wrapped
    to two lines, the skip block on A0's paper; sidebar without the quip teaser fits — rims 85..712,
    "Back to town" at y≈668. No clipped Label owned by this screen at 150.
  - W2B_AdventureBoard_focus_tab1.png: ring on Notice_A0. _focus_tab3: ring on the strip's "<" pager.
  - W2B_AdventureBoard_completed.png: the two goal lines under the subtitle; list shrinks and scrolls.
- refdiff AdventureBoard vs 1 (no mask): BEFORE (W1F_AdventureBoard.png) mae 28.868 / rmse 51.485 /
  structure 0.2751 / layout_iou 0.1417 / palette 0.2908 / within-8 39.11%, DIFFERENT. AFTER
  (W2B_AdventureBoard.png) mae 27.431 / rmse 49.14 / structure 0.2876 / layout_iou 0.14 / palette 0.2833
  / within-8 41.52%, DIFFERENT. No regression.
- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (18:40) summary lines:
  `PASS  LINT OK  no cross-file class_name references in sim/ or game/`
  `PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`
  `PASS  PARSE_CHECK scanned 166 script(s)`
  `PASS  16 generated file(s) agree with tools/gen_items.gd`
  `PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING`
  `FAIL  unit tests` — `TESTS FAILED   1/1801 failing`: the ONE failure is
  `test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason`
  (W2-TOWN's new file, being built in this same wave; nothing in it reads the board). Every
  test_board_rows.gd case (11), test_raid_plan, test_screens, test_full_loop pass. `VERIFY FAILED` is
  that one line; the gate is otherwise green for this unit.
- a11y_smoke (18:41): `ok empty AdventureBoard.tscn owner='Camp' tab ring=2 rail=6 focusable=7
  reachable=8 disabled=1` / `ok fixture AdventureBoard.tscn owner='Camp' tab ring=4 rail=6 focusable=22
  reachable=22 disabled=10` / `A11Y SMOKE PASSED 26 screen mount(s)`; no `warn` line anywhere.
- `tools/lint_motion.sh` → `MOTION LINT OK  tweens and morale glyphs each go through one door`.
- Greps: `sun.png`, `func _chips`, `Widgets.link`, `gui_input` — none in AdventureBoard.gd.

## Left undone / notes for the orchestrator

- Nothing in the unit's own text is left. The wave-level red is `test_town_layout.gd` (W2-TOWN).
- Handoff: one observation (a grid tick for the ladder); no edits to files I do not own.
- build/diff/W1F_AdventureBoard_* and W2B_AdventureBoard_* are the before/after refdiff artefacts.
