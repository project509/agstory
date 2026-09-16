# report-W6-LOG — the log and the report never cut a mistake's name or a joke, the fold lands, and the fight's stamps make a sound

Wave 6, unit W6-LOG. Contract: `build/plan/ship/00-plan.md` §1 "### W6-LOG". Findings: UI-19, UI-23, UI-35 (log half), LOOP-11, CONTENT-15, CONTENT-13, UI-24, AUDIO-04(b), AUDIO-16, CRITIC-C2, handoff-W6-COPY §2.

Owned: `game/screens/RaidView.gd` (TABS), `game/screens/Results.gd` (SPACES), `game/ui/Widgets.gd` (`log_row` only), `game/core/LogPlayer.gd` (SPACES), `art/ref/specs/02-concept2-raid-layout.md` §2.1, `tests/unit/test_log_player.gd`, `tests/unit/test_results_layout.gd` (new), `tests/unit/test_raid_beats.gd`.

## Acceptance

- [x] A1. `Widgets.log_row` gains `wrap: int` (0 = clip as today, N = WORD_SMART with `max_lines_visible = N`, -1 = unbounded); the round-marker gutter kept.
- [x] A2. `LogPlayer.collapse(entries)` (pure, static) folds identical Minor same-type same-round rows into one synthetic entry with `count` and actor names; `LogPlayer.COLLAPSE := true`. `test_log_player.gd`: two Minor fold, a Severe does not, a different round does not.
- [x] A3. (header may take TWO pitches when its words need them — Judgement call 1) RaidView `_mistake_header` leads with the type ("Dropped a Mechanic — Greg, Severe"); a folded row reads "3 raiders — Went AFK"; `test_log_player.gd`: every `MistakeLines` type name's header fits `474 - 28 - blot - face - stamp` at BODY.
- [x] A4. RaidView `_append_line`: header wrap 1, quote wrap 2; live pitch `LOG_ROW_PITCH * lines` (mistake = 3, else 1); scroll snaps to whole rows. `test_raid_beats.gd`: no revealed mistake header or quote Label clips (line count <= max_lines_visible, full text in `Label.text`, no "…").
- [x] A5. Results post-mortem: header wrap 1, quote wrap -1 (fully wrapped); the fold snaps to a row; same collapse. `test_results_layout.gd` (new): no `LabelQuote` ends in "…", no row rect straddles the scroll's clip edge.
- [x] A6. Results By-raider: header row "Raider · Mistakes · Morale · State"; claw → `log_mistake` glyph; an all-equal delta column collapses into "The mood afterwards". `test_results_layout.gd` asserts the header row exists.
- [x] A7. Audio: `ui.stamp` + `ui.blot` before the row build in `_append_line`'s mistake block (with `{"live": _live}`); `ui.stamp` first line of `_wipe_stamp`, `ui.seal` at the seal beat, under `_wipe_beats`. Tape test: three mistakes at `Speed.ONE` → 3 stamp + 3 blot; a wipe → `ui.silence` → `ui.stamp` → `ui.seal` in order.
- [x] A8. Boss plate prints the encounter's `display_name` only (handoff-W6-COPY §2, applied here) — already true at `RaidView._boss_plate` (the name Label and the sigil tooltip); W6-COPY's §2 text had not been written by this unit's close, so nothing to apply.
- [x] A9. Spec 02 §2.1 amended to "the LIVE log's rows"; the BL row goes to W6-LEDGER via `handoff-W6-LOG.md`.
- [x] A10. Shots viewed: `Results --fixture=raid` (quotes whole) and `RaidView --fixture=raid --advance=10` (type leads).
- [x] A11. `verify.sh --fast`: every stage green except unit tests, where the 6 failures are W6-COPY's in-flight files (AdventureBoard/Completion/RaiderDetail/Guildhall — see Verify); nothing names an owned file; `lint_motion.sh` OK; `lint_copy.sh` OK.

## Log (what I did and saw, as it lands)

- Measured first (scratch `measure.gd` under the lock): LabelLog is 15px; the MISTAKE stamp box is 68x23; the live row's label gets ~324px with the bar up. Type-leading headers with "Greg": 4 of 18 type names exceed one line ("Died to Something Extremely Avoidable — Greg, Severe" = 372px); with the pool's long shape ("Maureen Skullmender", "X of the Ninefold Path") 8 do. A one-line header cannot hold every type with the stamp on the row; see Judgement calls.
- Widgets.log_row: `wrap` parameter landed (0 clip / N lines / -1 unbounded; NO_TRIMMING, clip_text off). Row minimum stays one pitch; callers set taller pitches.
- LogPlayer: `COLLAPSE := true`, `collapse(entries)` (pure), `count_of`, `mistake_header` (the one rule), `actors_of`; the fold is applied in `_init` so the reveal, `revealed()` and `total()` see it. Synthetic entry = the last member copied + `params.count/actors/sequences`, landing at the last member's position with its sequence so RaidView's HP fold never runs ahead of the page. Not folded: Severe, knock-ons (`caused_by`), a repeated actor, different rounds/types.
- RaidView: `_append_line` — audio stamp+blot before the row build with `{"live": ...}` (false on skip and at Instant); header `wrap = HEADER_LINES (2)` with the row's pitch measured by `text_lines` (TextParagraph, the Label's own break flags) at the width `_row_text_width` computes (bar reserved); quote wraps at `max(QUOTE_LINES, need)` (cap 3) in a fixed two-pitch band; every column child a whole number of pitches (round marker 22 -> 29, phase 18 -> 29, the WIPE. line 2 pitches); the scroll is 7 x 29 = 203px so its end is a row boundary; `snap_scroll` guards `_scroll_to_end`. `_wipe_silence` plays `ui.silence` (same duck, now on the tape); `_wipe_stamp` opens with `ui.stamp` at pitch 1.0; `_drop_seal` plays `ui.seal`.
- Results: `_story_row` prints `[Rnn] ` + `LogPlayer.mistake_header(e)` and wraps everything (header -1, quote -1, cause line too); `_log_panel` indexes mistakes BEFORE the fold and prints `LogPlayer.collapse(lines)`; a `FoldSpacer` beside `ReportScroll` and `_snap_report_fold` on `ReportRows.sort_children` (Guildhall.fold_height reused); By-raider: `TallyHeader` row (Raider · Mistakes · Morale · State in LabelSmall), the blot silhouette -> `Icons.at("log","mistake")` in a "Mark" cell, `flat_delta_of(rows)` collapses an all-equal morale column (Labels built, hidden — test_results_report reads them) and the mood line prints "That cost N morale each — M between them."
- Spec 02 §2.1 amended (one sentence): the LIVE log's ordinary rows ellipsize; the mistake header/quote wrap to pitches; the report wraps in full.
- Tests written: test_log_player (retargeted two pins; the fold x3; the header/type-name test), test_raid_beats (no-ellipsis + whole-pitch + the two tape tests), test_results_layout (new, 6 tests). First run: my three fixes (duplicate sibling names print as @Class@id, the fixture's ledger is not flat, the pool's longest shape is 19 chars) applied; second run blocked by RaidSim.gd mid-edit (W6-SIM-CASCADE) — retrying.

## Judgement calls

1. **The live header may take TWO pitches, not one.** The contract says "header on one line" AND "every type name's header fits `474 - 28 - blot - face - stamp`". Measured, both cannot be true with the stamp on the row (372px for the longest type with a four-letter name; the label gets ~324). The unit's title — never cut a mistake's name — wins, and UI-19's own Fix already allowed "exactly the MISTAKE row to wrap to two lines when the stamp is present". So: `HEADER_LINES = 2`, the row's pitch measured (1 or 2), the TYPE always whole on the first line (asserted for all 18 names), the whole header never past two (asserted with the pool's longest shape). The snap still holds: every row is a whole number of pitches.
2. **The quote may take a third line** when a corpus line needs one at the column's width (`QUOTE_LINES_MAX = 3`), inside `max(2, need)` pitches — "up to two lines" was the norm, "never cut a joke" is the rule.
3. **The fold's header reads "Went AFK — 3 raiders, Minor"**, not CONTENT's illustrative "3 raiders — Went AFK": UI-19's type-leading rule is the one rule for both surfaces (CRITIC-C2), and the severity is one of docs/13 §11.3's four signals. The names are `params.actors` and the row's tooltip (a courtesy, never the only place — the count is the docs/07 content).
4. **The report's mistake header keeps its `[Rnn]` prefix** ("[R04] Pulled Aggro Off the Tank — Greg, Severe") because every other report row is filed under its round; the two RULES §1 strings in test_log_player (`Greg (Rogue) — Severe — …`, `MISTAKE · Severe · …`) are retargeted in the file I own, as W6-COPY's contract does for hidden strings. `EventLog.describe()` (sim, the goldens) is untouched.
5. **`_wipe_silence` now calls `play("ui.silence")`** instead of `duck(-60, 0.4)` — identical duck (Audio.HOOKS), and the beat lands on the tape so the acceptance's `silence -> stamp -> seal` order is readable. Outside the listed functions but inside the owned file; three lines.
6. **The collapsed morale column stays in the tree, hidden.** `test_results_report.gd` (not owned) reads a "Morale" Label per raider with a signed figure; the column is a fact of the account, so the Labels are built and `visible = false`, the header drops the word, and the mood line carries the figure once. No unowned test changes needed.
7. **The report's fold reuses `Guildhall.fold_height`** (a static that existed at the wave's start) through a preload rather than a second copy of the arithmetic.
8. **The scroll shows 7 whole rows, not "eight"** (the docstring's number): 224 inner px is 7.7 pitches, which is exactly the slice UI-35 measured.

## Verify

`tools/with_godot_lock.sh ./tools/verify.sh --fast` (2026-09-15, mid-wave, other units editing):
```
  PASS  class cache regenerated
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  PASS  PARSE_CHECK scanned 189 script(s)
  PASS  COPY LINT OK  no player-facing string under game/ admits an unfinished feature (ship plan §0.2; 20 allow-listed fall-throughs, all present)
  PASS  16 generated file(s) agree with tools/gen_items.gd
  PASS  ART CHECK  generators=7  runtime files: 204 agree  0 DIFFERS  0 MISSING
  FAIL  unit tests   TESTS FAILED   5/2126 failing  [42909 ms]   (second run at the unit's close; the first had 6 with test_rest.gd, since settled)
        test_paper_doll.gd x3 (RaiderDetail — W6-COPY),
        test_text_scale_layout.gd x2 (AdventureBoard 'Trash · 1 enemy' rows + Completion @150 — W6-COPY's copy edits moved the allow-list rows)
  SKIP  --fast (x6)
```
No failure names RaidView, Results, LogPlayer, Widgets or any test this unit owns. The owned files' own run:
```
RUN_TESTS_ONLY=test_log_player,test_raid_beats,test_results_layout,test_results_report,test_raid_overlays,test_wipe_sequence,test_event_feed -> 7 file(s)
TESTS PASSED   131 test(s) in 7 file(s)  [4805 ms]
```
(+ the `_leaf_heights` pin after the fold fix: `RUN_TESTS_ONLY=test_results_layout,test_results_report` — TESTS PASSED 18 test(s).)
`tools/lint_motion.sh` — MOTION LINT OK. `tools/lint_copy.sh` — COPY LINT OK.

## Shots (viewed with the Read tool)

- `build/shots/w6log/RaidView_advance10.png` + `RaidView_advance10_log_crop.png` — the live log at line 10: "Pulled Aggro Off the Tank — Clive Skullmender, Moderate" leads with the type, wraps to a second pitch beside the MISTAKE stamp with no ellipsis; both quotes whole on two lines; the top of the panel is a row boundary (a whole quote), 21px air under the last row.
- `build/shots/w6log/Results_raid.png` + `Results_raid_log_crop.png` + `Results_raid_right_crop.png` — "What happened": "[R00] Started an Argument in Raid Chat — Greg, Moderate" on two lines, the joke whole on two, "[R01] Dropped a Mechanic — Greg, Severe" as the last whole line above the fold (its quote below it; first take folded per BLOCK and left two rows + 90px of air — fixed to fold per LINE, `_leaf_heights`). By raider: the header row "Raider · Mistakes · Morale · State", the log's red MISTAKE face where the blot silhouette was, Morale shown because the fixture's ledger is -18/-12 (not flat); the flat case is the test's.

## Audit closures

- **M5-COMEDY-10** (docs/07 §5.5's log collapse) — DONE. `LogPlayer.collapse()` at display time (never the sim; goldens untouched), `LogPlayer.COLLAPSE := true` as the switch (no `GameSettings` key: the §15.1 inventory is closed, per the entry's own risk clause), RaidView renders "Went AFK — 3 raiders, Minor" with one quote, Results uses the same fold. Held by `test_log_player.gd :: test_identical_minor_mistakes_in_one_round_collapse`, `:: test_collapse_never_merges_across_rounds_or_severities`, `:: test_a_folded_row_reads_as_a_count_on_the_screen`; `test_results_layout.gd :: test_the_report_folds_identical_minor_rows_like_the_live_log`. docs/15 row text in `q-W6-LOG.md` Row B.
- **M6-AUD-04** — the RaidView half (b) DONE: `ui.stamp` + `ui.blot` before the row build in `_append_line` (`{"live": ...}`), `ui.stamp` opening `_wipe_stamp`, `ui.seal` in `_drop_seal`, `ui.silence` through `play` in `_wipe_silence`. Held by `test_raid_beats.gd :: test_three_mistakes_at_one_x_tape_three_stamps_and_three_blots` and `:: test_a_wipe_tapes_silence_then_the_stamp_then_the_seal_in_order`. The other halves (RaidPrep, Widgets lambdas, row_select) are W6-AUD-BIND's — the row stays open until they land.
- **M6-A11Y-07**'s text half — every MISTAKE row names itself in `Label.text` (the type leads); the glyph half was W1-ICONS'. Not this unit's row to close; noted.
- Findings closed on this unit (for the orchestrator's §8.2 index): UI-19, UI-23, UI-35 (log half; the plate keep-out is wave 7's), LOOP-11, CONTENT-15, CONTENT-13, UI-24, AUDIO-04(b), AUDIO-16, CRITIC-C2.

## Left

- The plan's literal "header on one line" for the live log: not done as written, because it cannot hold every type name beside the stamp (measured; Judgement call 1). What ships is the stronger true rule (type whole on line one, header never past two pitches, nothing cut) with the snap intact.
- `handoff-W6-COPY.md` §2 (the boss-plate line) had not been written when this unit closed; the plate already prints `display_name` only. If W6-COPY's §2 lands with a different edit, RaidView.gd is this unit's file and the orchestrator may apply it at the close.
- The Instant/skip silence for the per-line hooks is W6-AUD-BIND's gate in `Audio.play` (`opts.live == false` -> drop); this unit passes `live` (false on skip AND at Instant) and asserts the tape at 1x only — the "tapes nothing at Instant" half is that unit's test by the plan's split.
- Sibling node names repeat in the log column ("Settle", "Quote", "TallyRow" print as `@Class@id` after the first) — the tests walk `_log_rows` / the "Tally" host instead; no contract names those repeats.
- `verify --fast`'s six unit failures are W6-COPY's files mid-edit (listed under Verify); re-run at the close.
