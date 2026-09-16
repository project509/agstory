# Report — W2-RESULTS (the report reconciles the party, and the clear branch is seen for the first time)

Wave 2 of the art/UI overhaul (build/plan/artaudit/00-plan.md §3 "W2-RESULTS"). Owns
`game/screens/Results.gd` (SPACES) and `tests/unit/test_results_report.gd` (new). Written as I go.

## Acceptance (from the plan)

- [x] `test_results_report.gd` asserts a "By raider" Label and one name Label per party member
- [x] `test_results_report.gd` asserts "Suggested — give everything" disabled with its reason on the wipe fixture and enabled on the clear fixture
- [x] `test_screens.gd:606-632` (Return to town / See how it ended) green
- [x] `test_full_loop.gd` (Cracked Charm, the Suggested press by fragment) green
- [x] wipe shot: right column filled to ≥ y 650
- [x] wipe shot: the pager reads as a pair
- [x] wipe shot: stamps rotated
- [x] clear shot shows the hand-out rows
- [x] refdiff Results vs 2 masked (210,77,928,640) recorded, before/after
- [x] shots: `Results --fixture=raid`, `--fixture=raid:clear`, `--fixture=raid --completed`, `--fixture=raid --set=text_scale=150` — each viewed and described below
- [x] Green: "Return to town", "Back to the board", "See how it ended", "No attempt to report", "Rounds", "Mistakes", "What happened" stay; both exits enabled; spaces indentation
- [x] `verify.sh --fast` green (summary pasted); `lint_motion.sh` prints MOTION LINT OK

## Findings checklist

- [x] COMBAT-11 `_by_raider(result)` under Loot: 24px portrait · name · blot count · signed tabular morale delta · Fallen/Stood; sorted mistakes desc; cause chain as indented rows in "What happened"
- [x] COMBAT-22 `Widgets.reasoned(accept, "Nothing dropped")`
- [x] COMBAT-19 pager via `Cards.roster_strip`; the stacked chevrons go
- [x] COMBAT-18 `Icons.at("rank", key)` beside the "Unknown" Label (Label stays)
- [x] COMBAT-12 `Frame.draw_lockup(host, "33_compact")`
- [x] COMBAT-08 headline + FALLEN as stamps (texts unchanged)
- [x] COMBAT-06 `Icons.at("log", kind)` at the `log_row` call site
- [x] COMBAT-10 verify the face font shows on the cards (nothing to build)
- [x] COMBAT-20 `const COMEDY_LINE := "as_built"` (Q12b)
- [x] CRITIC-G12 clear branch audited (hand-out rows, Suggested does something, See how it ended, Cracked Charm line)
- [x] KIT-03 no `_chips()` builder here — verify
- [x] G15 text150 shot, no clipped Label I own
- [x] M4B-CONV-05 the fallen grid at 12-of-12 fits its panel (resume note)

## Log

- BEFORE (Results.gd untouched, wave-1 kit in the tree): `build/shots/W2R_before_Results.png` (`--fixture=raid`).
  refdiff vs 2, mask 210,77,928,640: mae 32.015 · layout_iou 0.0745 · palette_divergence 0.6322 · within_8 24.76%.
  Seen on the older review-W1-KIT-fix-Results.png (same layout): wordmark "ry" runs past the 352 plate; right column empty
  from y ~470 to 712; "Suggested — give everything" lit over "No payout"; pager stacked > over < over 1/3; the fallen grid
  already fits at 12-of-12 (six to a row, two rows — M4B-CONV-05's earlier fix holds at 100% text scale).
- Round 1 landed in Results.gd (parse-check OK): `Frame.draw_lockup(self, "33_compact")`; the rank sigil row before
  the "Day N · Rank" Label; `Widgets.stamp_box` for the wipe headline (SHRINK_BEGIN, SECTION size through
  `Type.at(…, Theme_.scale_of(self))`); `_by_raider_section` / `_by_raider` / `_tally_row` (24px portrait, name,
  blot glyph + count, tabular delta, Fallen/Stood; sorted mistakes desc, name asc); `Widgets.reasoned` on Suggested
  and Sell-all, both rebuilt with the rows in `_refresh_loot`; `Cards.roster_strip` with a `card_builder` (kit card,
  FALLEN_TINT + `stamp_box("FALLEN")`), the stacked `_pager` deleted; `Icons.at("log"|"state", …)` on every story
  row; a cascaded mistake indents by `cascade_depth` and prints "→ set up by X's Y" from `caused_by` through
  `_mistake_index`; `const COMEDY_LINE := "as_built"` read by `_shows_comedy_line`.
- Shot 1 `build/shots/W2R_Results_wipe.png` (`--fixture=raid`), viewed: lockup inside the 352 plate; grey shield
  sigil before "Day 24 · Unknown"; "It's a wipe!" boxed and leaning; By raider = 12 rows (4/3/3/2×6/1×3 = 25 =
  "Mistakes 25"), every delta -11, every state Fallen; ◄ ► in the strip's gutters with "1/3" under the right one;
  log rows carry the mistake face / system glyph. DEFECTS SEEN: the right column overflowed (bronze bar at x 1140,
  the exits below the fold, "Fallen" clipped by the bar); the FALLEN stamp sat over each card's NAME (the kit card's
  name column starts where the old 232-wide card's did not). The other three shots failed to build — another
  agent's file was mid-edit (`_speech_backing`, `ICONS` — SceneStage/Cards, not mine); retaken below.
- Round 2: exits pinned under the scroll area (`RightColumn` VBox: ScrollContainer + rule + exits); PANEL_PAD 14;
  the wipe's "No payout — nothing was cleared." folded into the reasoned control's reason ("Nothing dropped —
  nothing was cleared."); the mood's cost sentence one line; FALLEN stamp at card-local (14, 58) across the
  portrait's lower half like a stamp on a file photo.
- Round 3 (text150 + the clear's audit): the report block's three lines stack in a column at (20,96) so the
  scale spaces them; `_fallen` scales the cell width through `Type.at(metrics.x, Theme_.scale_of(self))`
  (identity at 100%, so test_results_screen's six-to-a-row arithmetic holds; 90px/four a row at 150%);
  `_exit_row` is an HFlowContainer (at 150% the pair stacks instead of widening the panel); the two loot
  buttons autowrap and their `Reason` Labels wrap inside the column (`_wrapped_reason`);
  `_morale_delta_of` reads a `last_attempt_morale` ledger first when GameState has one — handoff §1-§4.
- `tests/unit/test_results_report.gd`: 12 tests, all green on their own (scratch one-file runner) and inside the
  suite. They mount the real scene on `Fixture.apply(state, null, true)` (wipe) and `Fixture.apply_clear`
  (clear, seed 25) and assert: "By raider" + one `Name` Label per `last_party` member; rows sorted mistakes-desc
  and summing to `result.mistake_count`; Fallen/Stood counts = casualties/survivors; every wipe delta signed
  negative; Suggested disabled with a "Nothing dropped" `Reason` Label on the wipe (and no sell-all at all);
  Suggested enabled on the clear, "Give" present, a press empties `pending_loot` and the rebuilt control says
  "Nothing left to hand out"; both exits enabled + FOCUS_ALL and the asserted strings hold; the headline is a
  PanelContainer named Headline whose Label reads "It's a wipe!" at 2-7°; four FALLEN `Stamp` boxes on the strip's
  first page; exactly one `PagerPrev` and one `PagerNext` on one y (the pair); `RankSigil` with a texture and the
  "Day N  ·  Rank" Label untouched; a cascaded mistake row is a MarginContainer at 18px with a "→ set up by
  Greg's Pulled Aggro Off the Tank" line while a first-order one is not indented and prints one text; a story row's
  badge is a TextureRect with a texture (two texts for a mistake with a joke — test_log_player's contract);
  `COMEDY_LINE` in ["as_built", "promise"].

## Shots (all viewed with the Read tool)

- `build/shots/W2R_Results_wipe.png` — `Results --fixture=raid`. Lockup inside the 352 plate (rightmost bright
  wordmark pixel x 326 ≤ 344, measured); the Unknown shield sigil before "Day 24 · Unknown"; "It's a wipe!" in a
  rimmed, leaning stamp box; right column: Loot (Suggested dimmed, "Nothing dropped — nothing was cleared."), By
  raider — twelve rows, portrait · name · blot · count · -11 · Fallen, sorted 4/3/3/2×6/1×3 (sum 25 = "Mistakes 25"),
  The mood afterwards (one line + the flask hint), the exits at y 662-690 with NO scrollbar; mean luminance of
  x 806-1150 × y 470-700 is 27 (was 10 in COMBAT-11's evidence). Strip: "Party 12" roll-call, four kit cards greyed
  with FALLEN stamped across each portrait, ◄ at x 131 and ► at x 1035 with "1/3" under the right gutter. The
  cards' morale faces are the authored pixel faces (crop at 3x: `build/shots/W2R_wipe_crops.png`) — COMBAT-10
  verified, nothing to build. Log rows carry the system / mistake glyphs.
- `build/shots/W2R_Results_clear.png` — `Results --fixture=raid:clear` (FIXTURE raid:clear A0 seed=25). "Cleared.",
  A0 — Adventure 0, blurb; Payout 4 G + the sell note; Suggested LIT; Sell all unusable (+0 G) dimmed with
  "Everything here fits somebody."; the hand-out row: Cracked Charm of Power · Trinket · Sell 1 G · "Bork · Warrior
  (+1)" · Give; By raider — Rhona 3, Gruk 2, Bork 0, Greg 0, all Stood, morale "—" (see the judgement call on the
  ledger); "Morale has already settled from this one."; both exits. CRITIC-G12 audit: the hand-out row renders,
  Suggested does something (the test presses it: `pending_loot` empties and the control re-states its reason),
  the Cracked Charm line is the row's name Label, "See how it ended" is the completed shot. Nothing left to file
  against Results.gd on the clear branch beyond the ledger handoff.
- `build/shots/W2R_Results_completed.png` — `Results --fixture=raid --completed`. The crimson "See how it ended"
  CTA is the only exit, pinned under the column; because the CTA is 70px tall the scroll area above it loses 42px
  and the mood section's flask line sits at the fold with the bronze bar visible (the bar is the cue; every line
  is reachable). Left as is: the ending beat is the one-time case and the CTA's height is the kit's.
- `build/shots/W2R_Results_t150.png` — `Results --fixture=raid --set=text_scale=150`. The panel keeps its 820
  width; the report block's three lines stack; the fallen grid is four 90px cells a row with whole class names and
  the left column's bar visible; the right column scrolls with its bar (twelve 24px rows cannot fit at 150%), the
  loot button and its reason wrap, the exits stack; log rows ellipsize. No Label I own is clipped. The kit card's
  band line ("Warrior — Quite Hap") overruns the card — Cards.gd's, noted in the handoff for W3-KIT2.
- `build/shots/W2R_final_crops.png` — the report block, both right columns and the completed CTA side by side.

## refdiff Results vs 2, mask 210,77,928,640

- before: mae 32.015 · layout_iou 0.0745 · palette_divergence 0.6322 · within_8 24.76%
- after:  mae 32.294 · layout_iou 0.0750 · palette_divergence 0.6211 · within_8 24.73%
- flat within noise (the panel moved up 12px and grew 18px; the arena is masked): does not regress.

## Gate

`GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (2026-09-14):
```
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  PASS  PARSE_CHECK scanned 166 script(s)
  PASS  16 generated file(s) agree with tools/gen_items.gd
  PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING
  FAIL  test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason
TESTS FAILED   1/1801 failing  [40525 ms]
```
The one red test is W2-TOWN's own new file (the Blacksmith plate's height on Town), in flight in the same working
tree; nothing in it touches Results. Every other test — test_results_report (12), test_results_screen,
test_screens' Results block, test_full_loop, test_log_player's post-mortem row, test_raid_plan's Results — is green.
`tools/lint_motion.sh` → `MOTION LINT OK`. `tests/unit/a11y_smoke.gd` → `A11Y SMOKE PASSED 26 screen mount(s)`;
Results: empty sweep owner 'Back to the board' ring 2; fixture sweep owner `PagerPrev` ring 5, focusable 4,
reachable 5, disabled 1 (the reasoned Suggested), no warn.

## Judgement calls

- COMBAT-19 is closed with `Cards.roster_strip` (the plan's text and the resume note both name it) rather than
  `Widgets.pager`'s captioned row: Results' strip now has the hub's geometry (host at x 14, Available panel, cards at
  141/365/589/813, arrows in the gutters) instead of Concept 2's 232-wide panels at 23/277/531/785. The Available
  panel is the party roll-call ("Party  N", faces of who went; the kit caps it at eight). The cards are built by a
  `card_builder` so the fallen keep their grey and their stamp; the screen's own `_pager` and the
  CARD_X0/CARD_PITCH/CARD_W/PAGE/PAGER_X constants are gone.
- The FALLEN stamp lands ACROSS the portrait's lower half (card-local 14,58), not top-right: on the kit's 215px card
  the top-right is the name column, and a stamp on the file photo reads better than one on the name.
- The morale column's source: `last_attempt_morale` (handoff) → `last_wipe_penalty` (the plan's source) → the
  raider's own morale_log day delta → "—". On the wipe fixture the column is the wipe hit (-11 × 12 = 130, the same
  number the mood sentence and the flask refund use). On the clear it reads "—" until the handoff lands (the
  fixture roster has one history row); in play, from the second Day Tick on, it reads the day's movement.
- COMBAT-22's reason on a wipe is "Nothing dropped — nothing was cleared." and the separate "No payout — nothing
  was cleared." line is gone on that branch (COMBAT-22's own complaint was three lines saying the same thing); a
  clear with no payout prints "No payout this time."; after a hand-out the reason is "Nothing left to hand out.".
  With nothing pending the Sell-all control is not drawn at all (a second disabled control with the same reason
  would be noise). No test reads any of those strings; test_full_loop's "Suggested" press by fragment holds.
- The rank sigil is drawn at its native 28px (the grid's rank cell), not the plan's 16px: a 16px downscale of a
  28px pixel sigil blurs, and the 28px row still clears the attempt line.
- PANEL_RECT moved from (358,100,820,616) to (358,88,820,634) with PANEL_PAD 14: the height a twelve-body wipe
  needs for the tally AND its exits without a scroll. test_results_screen's `room` arithmetic loosens by 18px and
  stays green.
- Cause chain: `caused_by` is always empty today (RaidSim.gd:1756's own comment — `Mistakes.attribute` has no
  caller), so no shot shows a chain; the render path is proven by the unit test with a synthetic cascade.
- The MISTAKE stamp is NOT added to Results' story rows: test_log_player.gd:406-422 pins a mistake row to exactly
  two texts (header + quote), and the plan gives that stamp to RaidView.
- COMBAT-20: `COMEDY_LINE = "as_built"` with "promise" (option a) implemented behind it; (b)/(c) are content
  decisions and are not switched.
- M4B-CONV-05 (resume note): at 100% the twelve-body grid already fit (six compact cells a row, two rows — the
  earlier fix); what overflowed was the 150% case (60px cells wrapping "Warrior" mid-word into a clipped third
  line), closed by scaling the cell width with the text.

## Left / not done

- Nothing in the unit's own text is left. Outside it: the per-attempt morale ledger is a GameState edit (handoff
  §1-§4, orchestrator); the kit card's band-line overrun at 150% is Cards.gd's (handoff observation, W3-KIT2).
