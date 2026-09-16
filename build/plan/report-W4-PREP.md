# report-W4-PREP — the prep strip and the dimmed arena

Unit: W4-PREP (00-plan §5). Owns `game/screens/RaidPrep.gd` (FOUR SPACES) and
`tests/unit/test_prep_layout.gd` (new). Handoff: `build/plan/handoff-W4-PREP.md`.
Shots: `build/shots/W4PREP_*.png`. Started 2026-09-15.

## Acceptance (00-plan §5 W4-PREP)

- [x] A1 KIT-12 — no pager rect intersects a card rect on the RaidPrep shot; the strip pages through
  `Cards.roster_strip` alone (no hand-placed pager left in RaidPrep.gd).
- [x] A2 KIT-03 — the dead `_chips()` (and the `ICON` const only it used) deleted.
- [x] A3 KIT-08 — the bench pads with `seats` so an empty bench shows empty seats; the bench glyph
  (`Icons.at("empty", "bench")`) on the strip's empty state when nothing is chalked.
- [x] A4 STAGE-01 — the prep arena reads `SceneStage.marks(SceneStage.DEFAULT_ARENA)`: the view is the
  mark's, the party band is framed, the rest dimmed.
- [x] A5 KIT-09 — the verdict callout is `Widgets.callout` and carries its sweep + "Flourish" (asserted).
- [x] A6 CRITIC-G06 — the Depart gate goes through `Widgets.reasoned` (reason Label adjacent, padlock);
  "Depart" stays the crimson wax Button; "Bench" in-card action kept.
- [x] A7 G15 — `RaidPrep --fixture --set=text_scale=150` shot: no clipped Label in the sidebar/readout.
- [x] A8 `test_prep_layout.gd` green; `test_raid_plan.gd:311-317` strings and `test_full_loop.gd` green.
- [x] A9 Shots viewed with the Read tool and described: `RaidPrep --fixture`,
  `RaidPrep --fixture --set=text_scale=150`, `RaidPrep` (empty bench).
- [x] A10 refdiff RaidPrep vs 2 masked (`210,77,928,640`) before/after recorded.
- [x] A11 `verify.sh --fast` green (summary lines pasted); `lint_motion.sh` prints `MOTION LINT OK`.

## Judgement calls

- KIT-09: the verdict callout was already `Widgets.callout` when the wave started (W2-RAIDVIEW's era) and
  W3-KIT2 gave the kit the sweep + Flourish, so nothing in RaidPrep.gd changed for it; the test pins the
  GradientTexture2D plate and the "Flourish" child so a regression in either file is caught here.
- STAGE-01: `SceneStage.marks()` gives a `view` and party feet marks but no figure height; the band is grown
  by the tallest/widest class strip read from the same two manifests SceneStage reads (never a typed number),
  and the view is shifted sideways so the band centres in the column LEFT of the opaque readout — the plan
  says "dim and frame the same band RaidView fights on" and RaidView's rows are the mark's `view.y`, kept.
- CRITIC-G06: Depart's disabled reasons are only "no mission" and "nobody chalked" — docs/06 §6.6 forbids the
  comp gating it, so a one-tank raid stays enabled and the readout's warnings do the teaching.
- G15 (scope): the 150% shot found the sidebar 741px in a 635 host at 100% already (hidden by empty space
  under the rim) — fixed here because a clipped Label at 150 IS the acceptance line; the provisions block
  moved to the strip's log slot (the one block whose height depended on the cupboard). Every asserted string
  (test_raid_plan :311-317, "Depart", "Bench", "Back to the board") kept.
- The Cards.gd card trims seen in the 150% shot ("Warri", "Shama", the Bench buttons under y=1024) are
  Cards.gd's card at text150, not this screen's — out of scope, noted for W3-ROSTER's owner; no handoff
  because the fix is a card-kit layout choice, not an exact edit.

## Shots

Retaken 10:4x after the resume (batch_W4-PREP_5.sh), all three viewed with the Read tool:
- `build/shots/W4PREP_RaidPrep.png` (`RaidPrep --fixture`): the cave plate dimmed under the readout; the
  fight band is a bronze 2px rim x≈284-671, y≈305-500 captioned "The party stands here", the lantern floor
  inside it lit and the arena outside it a shade darker (the scrim); the readout panel's four blocks all in
  view (Comp check / Gear / Predicted risk / Verdict: Reckless) with no bar; sidebar: art well, "Raid 1 —
  Encounter 5 / Main Boss", two reward slots, the verdict callout with its crimson sweep and the flourish
  in its top-right corner, four Raid Team portraits, the crimson Depart plate reading "12 of 12 chalked"
  with "Back to the board" under it, rim at y≈714. Strip: "Bench  0" with the 2x4 empty seats, four cards
  (Bork/Gruk/Rhona/Greg) each with its "Bench" button, the pager arrows in the gutters at x≈132 and x≈1035
  (touching no card), caption "1/3", and the Provisions panel in the log slot ("The cupboard is bare. The
  Market sells provisions.").
- `build/shots/W4PREP_RaidPrep_text150.png` (`--fixture --set=text_scale=150`): both scroll bars appear
  INSIDE their rims (sidebar x≈1483, readout x≈1088); the readout wraps "Expected mistakes ~58.5 /
  encounter" onto two lines and scrolls past "Tiny Rogue Upset +6.2"; the callout figure wraps ("~58.5" /
  "mistakes", the second line at the scroll's edge — scrolling shows it); the card title trims to "Raid 1 —
  Encou…" (the ellipsis, docs/13 §14); Depart + Back stay a footer, never scrolled away; the sidebar rim is
  still at x≈1518, y≈714. No Label is cut by a panel edge — what is cut is at a scroll window's edge, with
  the bar showing. Seen, not mine: Cards.gd's cards trim "Warri"/"Shama" and their Bench buttons run under
  y=1024 at 150 (the card kit's height at text150).
- `build/shots/W4PREP_RaidPrep_empty.png` (`RaidPrep`, no guild): "No guild loaded." chip; the arena and
  band as above; readout "Slots 0 / 12 … Verdict: Suicidal"; the sidebar's "No mission chosen" card over a
  blank art well, two empty reward slots, the callout "~0.0 mistakes", Depart dimmed with the padlock in its
  leading slot and "0 of 12 chalked", the reason "No mission chosen. Pick one on the board." directly under
  it in caution ink; strip: "Bench  0" with its eight seats and the empty state — the bench glyph over
  "No raiders to chalk." / "The Tavern has candidates." — centred on the card band, the log slot's
  Provisions panel unchanged.
- Refdiff RaidPrep vs 2, mask 210,77,928,640 (`build/diff/w4prep/`): after = mae 31.325 / structure 0.1545
  / layout_iou 0.0793 / within-8 35.5% — identical to the 02:16 numbers; before (the wave-3 gate,
  build/diff/raidprep_diff.json) mae 31.629 / 0.158 / 0.0758 / 34.6%. Does not regress.

## Log

### start — read the plan
- Read 00-plan §0, §5 ownership table, W4-PREP; RULES §1-§2; KIT-12/03/08/09, STAGE-01, CRITIC-G06/G15;
  LESSONS; report/handoff-W1-KIT §5-§6 (already applied: RaidPrep.gd:469-477 passes `on_page` and has no
  `_pager`); RaidPrep.gd in full; Cards.roster_strip (`seats` opt exists, pads with SlotMini cells);
  Widgets.callout (sweep + Flourish landed in W3-KIT2); Widgets.reasoned; Widgets.empty_state;
  SceneStage.marks + stage_arena_cave.json marks; RaidView `_stage()` / `_party_layout()` (the consumer
  to mirror).

### edits landed in RaidPrep.gd (parse-check OK, 174 scripts)
- KIT-03: `_chips()` and its `ICON` const deleted; `Frame.standard_chips` is the only chip builder left.
- KIT-08: `"seats": BENCH_SEATS` (8, the mini-grid's 2x4) passed to `Cards.roster_strip`; `_strip_empty()` puts
  `Widgets.empty_state(text, Icons.at("empty", "bench"), hint)` over the card band when nothing is chalked
  ("No one is chalked." / "No raiders to chalk." + a one-line hint — the kit's hint hangs under ONE line).
- STAGE-01: `arena_view(m, host_size)` (static) = the mark's `view` shifted so `fight_band(m)` (static; feet
  marks grown by the tallest/widest class figure read from class_actors.json + actors.json at the mark's scale,
  + 12px air) is centred in the column left of the readout, clamped inside the plate; `_frame_band()` adds
  "BandScrim" (4 ColorRects, GROUND_PAGE @0.32) outside the band, "FightBand" (2px bronze rim, draw_center
  off) and "FightBandCaption" ("The party stands here"); all MOUSE_FILTER_IGNORE. `ARENA_OFFSET` is now
  RaidView's own fallback (0,-280) so a mark-less scene still puts both screens on the same rows.
- CRITIC-G06: Depart is rebuilt each refresh by `_rebuild_depart()` inside `Widgets.reasoned(wax_button,
  _depart_reason())` under "DepartHost"; reasons "No mission chosen. Pick one on the board." /
  "Chalk at least one raider."; `_refresh()` re-runs the shell's focus hook (idempotent) since the box is new.
- Comment at the old :576 had five spaces (a comment, so Godot let it through) — squared to four.
- Not touched: the verdict callout already goes through `Widgets.callout` (W3-KIT2 gave it the sweep +
  Flourish); the test pins it.

### G15 pass — the 150% shot found real clipping, fixed in RaidPrep.gd
- First text150 shot (W4PREP_RaidPrep_text150, 01:5x): the readout cut "Expected mistakes ~58.5 / encount",
  "Rhona Shaman Slightly Annoyed +0" and the warnings at the panel's bottom; the sidebar column ran past
  the rim ("Raid 1 — Encounter 5", "~58.5 mistakes", the Depart plate cut at x=1536, "The cupboard is bare.
  The Market sells p"). At 100% the sidebar panel had ALREADY grown to 741px over a 635 host (rim at y=820
  in every earlier shot; the space under it is empty on this screen so nobody saw it) and the cupboard
  line was a 386px uncapped Label in a 314px column (LESSONS' "find the widest unwrapped sibling").
- Probe (scratchpad/probe_W4-PREP_layout.gd, a SceneTree script that lets the layout pass run and prints
  REAL sizes): at 100% the mission block was 451px in a 450px scroll (a bar), and a visible bar is ADDED to
  the ScrollContainer's minimum (314 + 8 = 322 -> panel 386 wide). In the test runner PanelContainer and
  MarginContainer report a (0,0) minimum until their first layout pass, so a min-size test that sums a
  VBox is blind to every card and callout — `test_prep_layout._min_of()` walks Box/Margin/Panel/Scroll by
  hand and the probe's numbers agree with it.
- Fixes (all RaidPrep.gd): sidebar = "SidebarCol" [ScrollContainer "SidebarScroll" (h disabled,
  follow_focus) > "SidebarInfo" (card, rewards, callout, Raid Team)] + a footer OUT of the scroll (Depart
  box, Back) so the commit never has to be found; SIDEBAR_GAP 6; the card's art 306x84 centred
  (`Cards.encounter_art(_encounter, SIDEBAR_ART)`, the board's treatment) with the title/kind trimmed with
  an ellipsis at SIDEBAR_TEXT_W-24; the callout's LabelFigure wraps (`_figure_of`); Depart is
  `Widgets.cta("Depart", "N of M chalked")` — the kit's sub-line INSIDE the plate (10 §2 R7) instead of a
  separate Label under it; the Depart reason wraps at SIDEBAR_TEXT_W. Readout = "Readout" panel >
  "ReadoutScroll" > "ReadoutCol", every line through `_line()` (wrap at READOUT_TEXT_W 304, never trimmed).
  PROVISIONS moved to the strip's log slot (`_provisions_panel()` at Cards.event_log's rect 1032,0 474x262,
  name "Provisions"; the cupboard row is an HFlowContainer, lines wrap at 434) — it was the block whose
  height depended on the cupboard and the one that pushed Depart under the rim.
- Probe after: 100% — sidebar 378 wide, no bar, mission block 435 of 454, readout 530 of 556 (no bar);
  150% — bars visible inside both rims, panel still 378 (scroll min 306+8), readout 897 scrolls in 556.
- Refdiff RaidPrep vs 2 masked 210,77,928,640: BEFORE (build/diff/raidprep.png, the 01:14 gate shot =
  the wave-3 baseline) mae 31.629 / structure 0.158 / layout_iou 0.0758 / within-8 34.6% -> AFTER
  (W4PREP_RaidPrep.png) mae 31.325 / 0.1545 / 0.0793 / 35.5%. Does not regress (all four moved the right way).
- `tools/lint_motion.sh`: MOTION LINT OK.
- Seen, not mine: between my first and second shot batches every body-size glyph rendered garbled ("Glots
  12 / 12", "WarrioP") — W4-PIP's Fonts.gd was mid-edit (02:06, the face-font sheets); the third batch,
  after it settled, renders cleanly. Nothing in RaidPrep.gd touches fonts.

### resumed 10:32 (the first agent was killed after its 02:28 verify)
- Verified against the tree: parse-check OK (178 scripts); `git diff` of RaidPrep.gd (+430/-94) and the
  untracked test_prep_layout.gd (656 lines) match every claim in the log above; scratchpad/verify_W4-PREP.log
  (02:28) reads VERIFY OK, 1956 tests in 96 files — 96 = every `test_*.gd`, so the new file ran green.
  The shots at 02:16 postdate the last code edit (02:15) but the Shots section was never written, and other
  units have edited Widgets/SceneStage/Fonts/Theme since — so: re-run the one-file runner, retake the three
  shots, view them, redo the refdiff, then the final verify --fast + lint.

### final gate 10:5x
- `tools/lint_motion.sh`: MOTION LINT OK (tweens/glyphs one door; every colour under game/ a Palette role).
- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (scratchpad/verify_W4-PREP_2.log):
  ```
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  PASS  PARSE_CHECK scanned 178 script(s)
  PASS  16 generated file(s) agree with tools/gen_items.gd
  PASS  ART CHECK  generators=7  runtime files: 204 agree  0 DIFFERS  0 MISSING
  PASS  TESTS PASSED   1956 test(s) in 96 file(s)  [63653 ms]
  VERIFY OK
  ```
- `tests/unit/a11y_smoke.gd` (both sweeps): `A11Y SMOKE PASSED   26 screen mount(s)`, no warn lines;
  RaidPrep empty: focusable=7 reachable=8 disabled=1 (Depart, reasoned); fixture: focusable=14 reachable=14.
- One-file runner (scratchpad/run_W4-PREP.gd): 16/16 in test_prep_layout.gd.
- Handoff: empty (`no edits found` on dry-run) — nothing this unit needs lives outside its two files.
- Left undone: nothing in the unit's contract. Noted for a card-kit owner (not a handoff, a layout choice):
  Cards.gd's roster cards trim their class word and push their Bench button under y=1024 at text_scale 150.
