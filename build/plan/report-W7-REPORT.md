# report-W7-REPORT — the report says why, what the town heard, and offers Try again; the tutorials say their lesson where it happens; Esc means the report

Started 2026-09-15. Contract: build/plan/ship/00-plan.md "### W7-REPORT". Rulings: Q-53 (RULINGS §2 #6), BL-119, BL-139, BL-141.

## Acceptance (from the contract)

- [x] A. `Results._headline()` gains one sentence under the stamp from `result.wipe_cause` (header + quote; empty → "Nobody in particular. The boss simply won."); the culprit's By-raider row gets the stamp glyph; RaidView's wipe beat scrolls the log to the same entry. `test_results_report.gd`: for `e5_miserable_commons` the sentence names the actor and the mistake type.
- [x] B. "Reputation +N" cell in the tally from `Reputation.award_for(encounter, clear_number, highest_unlocked_tier)` fed the pre-record clear count. `test_results_report.gd`: for a clear golden the tally has "Reputation +N" equal to the call.
- [x] C. `Icons.at("log","reputation")` → the existing `rank_known` file at 22px (one glyph).
- [x] D. Clear branch: `Widgets.stamp("CLEARED", Palette.READY_GOLD)` pressed over the heading with the same press; the suggested split as crimson `ButtonCta` "Give as suggested — N drops" with "Sell all unusable" beside it; the wax seal in READY_GOLD; "Payout N G" at `Type.FIGURE` via `Type.gold()`; one `audio.play("ui.stamp")`. `test_wipe_sequence.gd` gains the clear twin (stamp text "CLEARED", CTA variation `ButtonCta`).
- [x] E. `Results.TRY_AGAIN := true`; "Try again" routes to RaidPrep with the plan still in GameState, default-focused; cost line "costs a day and the provisions you chalk".
- [x] F. `Results.default_focus()` → "Try again" on a wipe, the split CTA on a clear; `RaidView.default_focus()` → Pause. `a11y_smoke.gd` asserts the entry control text for the two routes.
- [x] G. `lesson` / `lesson_report` / `title` on the tutorial records, read by `Encounter.from_dict`; `RaidView.TUTORIAL_BAND := true` shows one `Widgets.callout` band above the log on a tutorial slot; Results prints `lesson_report` above the tally on TR's WIPE branch only. `test_tutorials.gd`: the band's `Label.text` equals `lesson` on A0/TR and is absent on A1; the Results line absent on a clear.
- [x] H. `Encounter.title` (TR "The Doorman"); RaidView's boss plate prints the title in the title slot with "Raid 1 — Encounter 5 · Main Boss" as the subtitle when present, else as today.
- [x] I. `Results.COMEDY_LINE := "epigraph"`: one `LabelMuted` "The notice said:" above the existing `LabelQuote`, on every outcome; `test_results_screen.gd` asserts the eyebrow.
- [x] J. Esc: `RaidView._unhandled_input` claims `ui_cancel` → `_on_skip()`; `ScreenRouter`'s `ui_cancel` handler defers to a screen with `handles_cancel() -> bool`. `test_raid_beats.gd`: `ui_cancel` mid-replay ends on the post-mortem and never on the menu.
- [x] K. The rally row's `icon` (UI-39's Results half; m4t-04's rally line).
- [x] L. UI-34's RaidView line: the kind switch names `LabelDamageDealt` (a string; W7-STAGE registers it this wave).
- [x] M. UI-24 only if W6-LOG shed it (check the tree first).
- [ ] Shots: `Results --fixture=raid` (the sentence under the stamp, "Try again") and `Results --fixture=raid:clear` (the stamp and the crimson commit) — viewed.
- [ ] Green: `verify.sh --fast`; `lint_motion.sh`; RULES §1 Results strings unchanged; router host one child after two gotos.

## Log (write-as-you-go)

- 16:05 Read the contract, LOOP-12/13/30, UI-24/33/34/36/37/39/55, SHIP-03, CRITIC-R4/C3, CONTENT-09, RULINGS #6/#25/#36/#39, BL-119/139/141, audit m4t-04. UI-24 (M) is already in the tree (W6-LOG landed the header row + flat delta) — nothing to do.
- 16:20 Code landed (all parse): `Encounter.gd` reads `lesson`/`lesson_report`/`title`; the tutorial JSON carries BL-141's three strings verbatim + `title: "The Doorman"` + a `_notes` row; `Icons.ALIASES` maps `log/reputation` → `rank_known` (LOG_KINDS untouched — test_icons pins 12); `ScreenRouter.screen_handles_cancel()` + the `ui_cancel` deferral; RaidView: `default_focus()`→Pause, `handles_cancel()`/`_unhandled_input`→`_on_skip`, `TUTORIAL_BAND` + `_lesson_band()` (callout, figure dropped, padded like the Board's), the titled boss plate (`BossTitle`/`BossSubtitle`, bar steps to `BOSS_BAR_TITLED`), `_cause_row` kept + DANGER ink + `ensure_control_visible` on the WIPE. beat, `LabelDamageDealt` named only when the theme has it (else the TEXT_BODY override stands); Results: `COMEDY_LINE="epigraph"` + `EPIGRAPH_EYEBROW`, `_cause_sentence()` from `wipe_cause` (NOBODY_LINE when empty), the culprit's `CulpritStamp`, `Reputation +N` cell via `reputation_earned()`, CLEARED stamp box re-inked EDGE_READY_GOLD + `stamp_press` + one `ui.stamp`, the gold seal (luminance-recolour shader), payout at FIGURE_XL via `Type.gold`, the crimson `Give as Suggested — N drops` CTA with Sell-all beside (an HFlow), `TRY_AGAIN` CTA with the cost subline routing Board→push Prep, `default_focus()`, `LessonReport` panel on TR's wipe, the rally flask's icon.
- 16:25 Tests written: test_results_report (+6), test_results_screen (+2 epigraph), test_wipe_sequence (+3 clear twin), test_raid_beats (+5), test_tutorials (+3 screen clause), test_results_layout (+2), a11y_smoke (ENTRY_CONTROL table + a third "clear" pass). Waiting on the shared tree: GameState.gd (W7-SAVE) does not parse right now, so no test can run until it does.

## Resume (2026-09-15, 21:15 — the first agent was killed by a usage limit at ~16:30)

Verified the killed agent's claims against the tree before touching anything: `git diff` over the
thirteen owned files carries every line its Log claims, and the four data/loader/icon/router diffs read
correctly (`Encounter.lesson`/`lesson_report`/`title` + the three JSON strings verbatim, `Icons.ALIASES`
`log/reputation` -> the `rank_known` file, `ScreenRouter.screen_handles_cancel()`). Every symbol the new
code calls exists at the wave's start (`Enums.encounter_kind_name_of`, `Reputation.is_tutorial_slot`,
`LogPlayer.is_finished`, `Widgets.callout/stamp_box/stamp_press/cta/reasoned`, `Type.gold/count`,
`GameState.clear_count/highest_unlocked_tier/stalled`, `Icons` has `item_rally_flask.png`). So the boxes
below are ticked against the tree, not against the claim.

- 21:20 `RUN_TESTS_ONLY=test_results_report,test_results_screen,test_results_layout,test_wipe_sequence`
  -> TESTS PASSED 55 tests in 4 files (17.4 s).
- 21:24 `RUN_TESTS_ONLY=test_raid_beats,test_tutorials` -> 61/62 pass. The one failure is NOT this
  unit's: `test_the_tutorial_raid_is_currently_unwinnable_and_that_is_recorded` pins the Tutorial Raid's
  measured clear rate (1/20) and W7-SIM-EFFECTS' in-flight RaidSim/Mistakes/Formulas edits move it to
  0/20. Both of that test's claims still hold in spirit (`cleared < 8`); the pinned MEASUREMENT is a sim
  number and is re-pinned below once the sim settles (see "## Left").
- 21:27 Shots taken and READ: `build/shots/W7REPORT_results_wipe.png` (`--fixture=raid`) and
  `W7REPORT_results_clear.png` (`--fixture=raid:clear`). The page says what the contract asked for —
  "Round 5: Sandra — Went AFK. \"Sandra is not here. Sandra's body is here.\"" under the stamp, the WIPE
  stamp on Sandra's By-raider row, "The notice said:" over the quote, "Try again" crimson and first in
  the exits; on the clear, the gold CLEARED stamp, "Reputation +5" in the tally, "Payout 4 G" as the
  figure, the crimson "Give as Suggested — 1 drop", the gold seal on the panel's corner.
- 21:35 TWO LAYOUT DEFECTS the tests could not see, both found by cropping the shot (LESSONS: a clipped
  Label still reports its text):
  1. `Widgets.cta` anchors the cost Label across the PLATE and sizes the plate to the WORD, so
     "costs a day and the provisions you chalk" painted straight across "Back to the board" and out of
     the panel. Fixed in `Results._fit_cost_line()`: the plate takes `TRY_AGAIN_W` (208), the line wraps
     inside it, and the plate grows one line-slot per wrapped row, measured off the theme's own
     `LabelCtaCost` face so 125/150% get their own answer.
  2. The loot acts' flow left a 400px hole: `Widgets.reasoned`'s Label was autowrapped with NO width, so
     it reported a minimum height as if it wrapped at nothing, and the disabled "Sell all unusable"
     beside it was squeezed one word wide and 390 tall. Fixed with `LOOT_ACT_W` / `LOOT_REASON_W` and a
     `width` parameter on `Results._wrapped_reason` — a flow packs by minimum width, so every cell in
     one now declares the width it needs to read.

## What each ticked box is ticked against (verified on the tree at the resume)

- **A.** `Results._cause_sentence()` builds "Round 5: Sandra — Went AFK. \"…\"" from the entry
  `result.wipe_cause.entry_seq` names (never re-derived), `NOBODY_LINE` on an empty cause; the culprit's
  tally row wears `CulpritStamp`; `RaidView._append_line` keeps `_cause_row` (keyed on the sim's
  `wipe_cause` template id, never on words) and `_wipe_line()` calls `ensure_control_visible` on it.
  `test_results_report.gd::test_the_wipe_headline_names_the_culprit_and_the_mistake` + `…nobody_caused…`
  and `test_raid_beats.gd::test_the_wipe_beat_points_at_the_cause_row` — green.
- **B.** `Results.reputation_earned(state, enc)` = `Reputation.award_for(enc, clear_count, tier, stalled)`
  — the same pure call `GameState._award_reputation` makes, no new field; the cell prints only on a
  clear. Shot: "Reputation +5" beside "Survivors 4 of 4".
- **C.** `Icons.ALIASES` resolves `log/reputation` to the `rank_known` file (grid first, alias last), so
  the call site names the glyph the feed kind wants. `LOG_KINDS` untouched (test_icons pins 12).
- **D.** Gold `CLEARED` stamp box re-inked `EDGE_READY_GOLD` with `Widgets.stamp_press` and one
  `audio.play("ui.stamp")`; the crimson `Give as Suggested — 1 drop` with Sell-all in the same flow; the
  wax seal re-inked gold by luminance and dropped on the panel's corner; "Payout 4 G" through
  `Type.gold()` at `Type.FIGURE_XL`. JUDGEMENT CALL: the contract says `Type.FIGURE`, and there is no
  such constant in `Type.gd` — the figure sizes are `FIGURE_XL` (34) and `DAMAGE*`; `FIGURE_XL` is the
  one the name meant. Recorded rather than invented.
- **E/F.** `TRY_AGAIN = true`; the button pins `selected_encounter_id` and goes Board -> push prep (the
  Board's own stack shape); `default_focus()` answers Try again on a wipe and the split on a clear, and
  `RaidView.default_focus()` answers Pause. `a11y_smoke.gd` grew `ENTRY_CONTROL` and a third "clear"
  pass over Results.
- **G/H.** The three strings and `title: "The Doorman"` are in `data/encounters_tutorial_t1.json`
  verbatim, read by `Encounter.from_dict`; `RaidView._lesson_band()` prints `lesson` on a tutorial slot
  only; `Results._lesson_line()` prints `lesson_report` above the tally on TR's wipe branch only; the
  boss plate prints the title with "Tutorial Raid · Main Boss" underneath and steps the HP bar down.
- **I.** `COMEDY_LINE = "epigraph"` and the `LabelMuted` eyebrow directly above the `LabelQuote`, on
  both outcomes (`test_results_screen.gd`, two tests; the shots show it on the wipe and the clear).
- **J.** `RaidView.handles_cancel()` is true only while `_player` is unfinished; `_unhandled_input`
  presses skip and marks the input handled; `ScreenRouter.screen_handles_cancel()` defers by
  `has_method`, so every other screen keeps docs/13 §13.1's binding.
- **K.** The rally flask's control carries `Icons.at("item", "rally_flask")`, LEFT, unexpanded, text
  verbatim.
- **L.** The kind switch names `LabelDamageDealt` only once the theme carries the variation (W7-STAGE
  registers it this wave); until then the body-cream override stands, so the size never silently drops.
- **M.** Nothing to do: W6-LOG landed UI-24 (the By-raider header row and the flat delta are in the tree).
