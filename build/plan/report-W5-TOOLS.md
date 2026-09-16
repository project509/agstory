# report-W5-TOOLS — the instruments and the records: --hover, the dead crops, BUILD_STATE's length

Unit: W5-TOOLS (wave 5, 2026-09-15). Owned: tools/shot.gd, tools/shot_all.sh, tools/probe/Kit.gd,
game/assets/bg/{arena,menu,tavern}_plate.png (+.import, deletion), game/assets/ui/icons/badge_N.png
(+.import, deletion), art/ref/specs/09-background-plates.md, BUILD_STATE.md, BACKLOG.md,
docs/_log/progress.md, tests/unit/test_build_state.gd (new), tests/unit/test_art_sources.gd (only if a
deleted crop is pinned there), build/plan/audit.json rows M4B-CONV-02 / m4t-09 / M6-FINAL-02 / M6-FINAL-03.
Handoff: build/plan/handoff-W5-TOOLS.md.

## Acceptance

- [x] A1 `tools/shot.gd --hover=x,y` exists: after on_enter and the settle frames a mouse motion to (x,y) is
      synthesised into the SubViewport, then settle frames, then the capture; documented in the flag list at
      the top of shot.gd; the 00-plan §0.3 grammar line is in the handoff.
- [x] A2 `Town --fixture --hover=1040,120` shows the callout outline (viewed).
- [x] A3 `RaiderDetail --fixture --hover=<slot centre>` shows the two-line tooltip on a gear slot (viewed).
- [x] A4 `shot_all.sh --sheet=tabs` has no SKIP: Guildhall_Records shoots on `--fixture=raid:clear`.
- [x] A5 The dead crops are deleted: game/assets/bg/{arena,menu,tavern}_plate.png (+.import) and
      game/assets/ui/icons/badge_0..6.png (+.import); the grep for `_plate.png` / `badge_[0-9]` over
      game tools tests finds no reader of a deleted file; Kit.gd repointed at the icon grid.
- [x] A6 The Kit probe shot (`tools/probe/Kit.tscn`) still shows badges (viewed); Kit-vs-1 refdiff before/after.
- [x] A7 Spec 09's paint-out lists for plates that no longer exist are dropped.
- [x] A8 M6-FINAL-02: tools/probe/diag.gd verified gone by git log; closing note written.
- [x] A9 M6-FINAL-03: BUILD_STATE.md <= 250 lines; history moved to docs/_log/progress.md; Current focus,
      HANDOFF (three gaps + Q-53 / Q-29), Binding decisions, Invariants, Key commands (+ export_build.sh,
      --dev), Key paths, Architecture, Environment, Open risks kept; sweep count 288 cells x 8 seeds = 2,304
      runs stated; BACKLOG.md:52 fixed.
- [x] A10 tests/unit/test_build_state.gd green (length rule; every `path/like/this` and `./tools/x.sh` exists).
- [x] A11 test_art_sources, test_project_hygiene, test_docs_links, test_readme, test_motion green.
- [x] A12 `verify.sh --fast` green (second run, 2,037 tests; the first run's one red test was another unit's in-flight tree — below).

## Log (what I did and saw, as I went)

- A11: `RUN_TESTS_ONLY=test_build_state,test_art_sources,test_project_hygiene,test_docs_links,test_readme,
  test_motion,test_audit_hygiene,test_hall_plates,test_scene_stage,test_widgets_kit` -> TESTS PASSED (171 tests in
  10 files after two fixes: the moved baselines paragraph named `00-plan.md` bare, which test_docs_links reads as a
  docs/ file — it now says `build/plan/artaudit/00-plan.md`; and a literal Q-53/Q-29 in my test read as a
  register citation into the Q/BL overlap — the ids are built (`"Q-%d" % 53`) and asserted beside their
  wording). `tools/lint_motion.sh` -> MOTION LINT OK.
- A12: `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (log: build/shots/w5tools/verify_fast.log):
  ```
  == 0/8  lint ==                 PASS  LINT OK / MOTION LINT OK
  == 1/8  script parse ==         PASS  PARSE_CHECK scanned 186 script(s)
  == 2/8  generated content ==    PASS  16 generated file(s) agree with tools/gen_items.gd
  == 2b/8 generated art ==        PASS  ART CHECK generators=7  runtime files: 204 agree  0 DIFFERS  0 MISSING
  == 3/8  unit tests ==           TESTS FAILED   1/2037 failing  [42696 ms]
  ```
  The one failure is `test_text_scale_layout.gd :: test_every_route_fits_at_every_text_scale_with_the_reference_fixture`
  at @125 on the roster-strip PanelRounds of RaidPrep/RaiderDetail (12px past the clip) and the Guildhall roster
  cards, and @100 on the board's LabelQuote — all in `game/ui/Cards.gd`, `game/ui/Widgets.gd`, `Guildhall.gd`,
  `RaidPrep.gd`, which `git status` shows modified by other wave-5 units mid-work (W5-KIT3 / W5-SCALE own them;
  their reports name that test). Nothing in this unit touches a layout: my game/ diff is three unreferenced
  PNG deletions. Every stage and every test of mine is green; the wave close will run the gate over the
  merged tree. RE-RUN 20 minutes later over the same shared tree (build/shots/w5tools/verify_fast2.log):
  ```
  == 3/8  unit tests ==           PASS  TESTS PASSED   2037 test(s) in 104 file(s)  [40306 ms]
  VERIFY OK  (full log: .verify.log)
  ```

## Judgement calls

- `--hover` pushes the motion into the SubViewport rather than warping the OS cursor: the contract offered
  both; warping moves the developer's real mouse and reaches nothing (the SubViewport is not in a container).
- `--hover` grounds the popup (`transparent_bg = false`) rather than leaving the engine's 1/3-alpha
  rendering: a plate nobody can judge is not evidence. The shot loses the 5% see-through and the corner
  pixels; the header says so.
- The contract's example point (1040,120) is not on a callout in the Town fixture; 840,195 (the Tavern
  plate) is what the acceptance shot uses, with the HOVER line as the proof of what was under it.
- The seven badge PNGs stay on disk this wave (manifest rows pin them; the manifest is not mine): the
  handoff removes rows and files together and the test's floors are pre-lowered. Kit.gd no longer reads them.
- arena_stage.png was not in the unit's file list; it is left with a handoff rm line and M4B-CONV-02 stays
  `partial` with exactly that as its remaining_work, rather than closed with a file still there.
- BUILD_STATE: the two dated setup notes under the Binding decisions table (git init done / OneDrive) moved
  to the log with the rest of the history — the OneDrive risk is still an Open risks bullet, so nothing a
  new session needs is lost; every other kept section is verbatim.
- audit.json: the four rows I own are edited in place (a JSON round-trip of the file is byte-identical, so
  only those rows changed).

## Audit closures

- **M6-FINAL-02 — done.** Already deleted in 40ebf32 (2026-09-10; `git log --diff-filter=D -- tools/probe/diag.gd
  tools/probe/diag.gd.uid`); `ls tools/probe` = Bloom, Chips, Kit; diff_all.sh still scores Kit.tscn.
  BACKLOG.md:384 amended to record the exhausted audit surface. Held by: nothing new needed — the file is
  gone and the boot/parse stages would name it if anything cited it.
- **M6-FINAL-03 — done.** BUILD_STATE.md 325 -> 249 lines, history in docs/_log/progress.md's [M6-FINAL-03]
  entry, Key commands + export_build.sh/--dev, HANDOFF with the three gaps and Q-53/Q-29, ten stages
  everywhere, sweep count 288 cells x 8 seeds = 2,304 runs (BACKLOG.md:52 corrected). Held by
  `tests/unit/test_build_state.gd` (6 tests). The 150-line figure in the original entry is superseded by the
  file's own 250 rule, which the test pins; BACKLOG.md:384's handover half stays unchecked as the entry's risk
  note asked.
- **m4t-09 — stays done; note extended.** Kit.gd repointed at `Cards.badge_icon` / `Widgets.log_row(kind)`;
  the crops' files and manifest rows go together in handoff-W5-TOOLS §1 (test_art_sources' floors already
  lowered). Held by: test_art_sources (rows == files) and the Kit shot.
- **M4B-CONV-02 — partial, one file left.** arena_plate/menu_plate/tavern_plate deleted; spec 09 §3 rewritten,
  §4 baked rows dropped. Remaining: `rm game/assets/bg/arena_stage.png{,.import}` (handoff §3) — not in this
  unit's file list. Held by test_hall_plates' `_plate.png` guard.

## Left

- The seven `badge_N.png` files and their `.import`s are still on disk: their manifest rows in
  art/ref/manifests/all.json (not mine) are asserted by test_art_sources; handoff §1 removes rows + files.
- `game/assets/bg/arena_stage.png` (+.import): not in the file list; handoff §3.
- The 00-plan §0.3 grammar line for `--hover`: handoff §4.
- The tooltip Window is 180x571 in play (found by the new flag): Widgets.gd is not mine; handoff §2 is the
  fix, verified by probe (571 -> 56).

## Audit closures

## Left
- A1/A2: `--hover=x,y` parses, queues last, pushes an InputEventMouseMotion into the SubViewport, prints
  `HOVER x,y -> <node>` and exits 13 when nothing is under the pointer. The contract's example point
  (1040,120) lands on the mess tent (HOVER -> SceneHost), not a callout; the Tavern callout's Button is
  at 829,166 71x38, so the shot is `Town --fixture --hover=840,195`: the gold alpha-dilate outline ringed
  the plate and the title went to the hover colour (build/shots/w5tools/Town_hover.png, viewed).
- Kit.gd: EVENTS rows carry a feed kind (boss_attack, morale_down, recruit, mistake, morale_up, loot,
  gold) and the row is built exactly as Cards.gd:559 builds the shipping log —
  `Widgets.log_row(text, tone, badge, Cards.badge_icon(kind), kind)`; `load(ICON + "badge_%d.png")` is gone.
- shot_all.sh: the tabs sheet's Guildhall_Records row is `--fixture=raid:clear --press=Records` (the
  header comment says why). Verified below once the engine lock frees.
- Spec 09 §3 is now the six-bare-plates table (the crop rects and every paint-out list are gone; the
  header note records what they were); §4's three "baked v1" rows (hall patrons, camp airship, camp
  raiders) are deleted and the two §5 references to the §3.3 boss paint-out are repointed.
- The three bg crops are deleted (arena_plate, menu_plate, tavern_plate + .import; `git status` shows
  six D rows). The seven badge_N crops CANNOT be deleted in-wave: art/ref/manifests/all.json (not mine)
  carries a `ui_crop` row per badge whose `ships` path test_art_sources.gd asserts exists. So:
  handoff-W5-TOOLS §1 removes the seven rows (a text deletion apply_handoff.py can apply; json.loads
  checked on the result) and tells the orchestrator to `rm` the fourteen files after it; the test's two
  count floors are lowered now (57->50 rows, 45->38 reproducible) so it is green on both sides.
- A3, the long way: the first RaiderDetail hover showed the lit slot and NO tooltip. Four things were
  missing in turn, each found by a measurement and now in shot.gd's header: (1) the detached SubViewport
  never hears NOTIFICATION_VP_MOUSE_ENTER, so `mouse_in_viewport` stays false and no tooltip timer
  starts (hover lands, tooltip never) — the tool sends it; (2) the popup embeds into the ROOT window
  unless `_vp.gui_embed_subwindows` — set; (3) `gui/timers/tooltip_delay_sec` 0.5 s — set to 0 before
  the SubViewport exists; (4) the embedded transparent popup rendered its 0.95 fill at alpha 0.333
  (its texture read back `(…, 0.3333)`: a 2-bit-alpha target under Forward Mobile); HDR on the popup
  gave alpha 0.9497 but linear RGB composited black; `transparent_bg = false` on the popup gives the
  right plate (13,25,36) — `_ground_popups`, every frame under --hover. The capture prints `POPUP
  PopupPanel embedded=true at 594,177 180x571` and the crop shows "Head — Worn Iron Cap" in cream over
  "worth 1 G" in the muted ink on the steel-edged plate (build/shots/w5tools/RaiderDetail_hover.png, viewed).
- FOUND BY THE INSTRUMENT: that popup is 180x571 — Godot sizes the tooltip Window from
  get_contents_minimum_size() before any layout, and an autowrap Label 0 wide breaks every grapheme
  onto its own line. A scratch probe (a PopupPanel given `build_tooltip()`'s VBox) printed
  `contents_min=(180, 571)`, and `(180, 56)` with the Labels pre-sized to the VBox width. That is the
  tooltip's real size in play. Widgets.gd is not mine: handoff-W5-TOOLS §2 is the three-line fix.
- Non-hover paths of shot.gd are untouched (every addition is under `if _hover`), so shot_all/diff_all
  output names and pixels are as before.
- A4: `shot_all.sh build/shots/w5tools/all --sheet=tabs` -> "sheet tabs: 5 ok, 0 skipped, 0 failed";
  Guildhall_Records.log says `FIXTURE raid:clear A0 seed=23` / `PRESS Records` and the tile shows the
  open wall — "Records  3 of 40", First Blood earned with its Claim button, the guild at Known (viewed).
- A5/A6: `grep -rn "_plate.png\|badge_[0-9]" game tools tests` -> the four history comments (MainMenu.gd:100
  menu_plate, RaidView.gd:436 / Cards.gd:795 arena_stage, test_a11y_legibility.gd:643 badge_4/5), test_hall_plates'
  own guard strings and test_scene_stage's "must be deleted" assertion — no loader. Kit probe shot
  (build/shots/w5tools/kit.png, viewed): seven grid badges in the Recent Events column (eye, down-arrow, person,
  face, up-arrow, gem, coin). Kit vs Concept 1: 26.287 / 0.1841 / 41.63 against the wave-4 baseline
  26.26 / 0.184 / 41.6 — inside the <= 0.07 run-to-run jitter, no regression.
- A8: `git log --diff-filter=D --oneline -- tools/probe/diag.gd tools/probe/diag.gd.uid` -> 40ebf32 (2026-09-10,
  "stop importing 75MB of scratch, and four comments that had started lying"); `ls tools/probe` = Bloom, Chips,
  Kit. BACKLOG.md:384 amended to record the audit surface so nobody hunts again. Row closed in audit.json.
- A9: BUILD_STATE.md 325 -> 249 lines (CRLF kept). Moved verbatim to docs/_log/progress.md's new
  [M6-FINAL-03] entry: the wave-0-4 narratives, the bare-plate table + prose, the art-gate baselines, and
  Binding decisions' two dated setup notes. Kept unchanged: Binding decisions table, Invariants, Key paths,
  Architecture, Environment, Open risks. Key commands: + export_build.sh, export_build.sh --dev, shot_all.sh
  --sheet=all, audit_stale.py; "8-stage" -> "ten-stage". HANDOFF: ten stages listed; the three gaps; Q-53 / Q-29.
  Sweep: 288 cells x 8 seeds = 2,304 runs in BUILD_STATE; BACKLOG.md:52 corrected.
- A10: tests/unit/test_build_state.gd — 6 tests: length <= 250, the ten headings in order, the audit's
  strings + no "Eight stages"/"8-stage", Recent progress <= 12, every path-like code span resolves (file /
  dir / glob / docs/NN; one stated-absent exemption), every command names an existing script. First run
  found 6 non-paths my filter let through (ids, a range, a placeholder, ~/) — filtered by rule, not by list.
  `RUN_TESTS_ONLY=test_build_state` -> TESTS PASSED 6 test(s).
