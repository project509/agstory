# q-W6-LOG — proposed docs/15 rows from W6-LOG (W6-LEDGER owns docs/15 this wave)

Two rows, at the next free BL numbers. Text is ready to paste; the unit's report is `build/plan/report-W6-LOG.md`.

## Row A — spec 02 §2.1's "a row never wraps" is the LIVE log's ordinary rows only *(DECIDED - implemented; spec 02 §2.1 amended)*

**Owner:** art/ref/specs/02 §2.1 / docs/13 §11.3-§11.4 - **Signal:** Loud; the mistake's name and the joke were the two things the log and the report cut

Spec 02 §2.1 measured "longer rows ellipsize, never wrap" on Concept 2's eight short factual rows ("Tiny fired a shot for 317 damage."). The build applied it to every row on both surfaces, and the two rows the game exists for are the long ones: the MISTAKE header lost its type name to an ellipsis at 100% on the first mistake of the fixture (UI-19) and the wipe report cut three of three jokes (UI-23; CONTENT-15 measured the corpus at mean 75 characters, max 109, against ~62 visible). docs/13 §4.4 (never abbreviated), §7 (a tooltip is never the only place a fact lives) and §11.3 (the mistake is "the loudest single event in the game's UI") outrank a measurement taken on rows with no comedy in them, and the user's rule (reference concepts are a standard; where their UI does not fit the design, the design wins) settles it.

**Ruling.** ONE rule for the two reading surfaces (CRITIC-C2), `LogPlayer.mistake_header` the one door:
- The header leads with the TYPE — "Dropped a Mechanic — Greg, Severe" — because the type is the fact the row exists to say and the part the ellipsis ate; the class is on the card and in the joke's voice.
- LIVE log (RaidView): an ordinary row still ellipsizes (spec 02 §2.1 stands for it); the mistake header wraps to a second pitch only when its words need one (`RaidView.HEADER_LINES = 2`; measured, four of eighteen type names with a four-letter name and eight with the pool's long shape do not fit one line beside the MISTAKE stamp), the quote wraps to two lines and a third only when the corpus line needs it (`QUOTE_LINES = 2`, `QUOTE_LINES_MAX = 3`), every row is a whole number of `Type.LOG_ROW_PITCH`es and the scroll shows `LOG_VISIBLE_ROWS = 7` of them, so the scroll snaps by rows and the fold never slices a line (UI-35).
- REPORT (Results): nothing ellipsizes — header, cause line and quote wrap in full (`Widgets.log_row(..., wrap = -1)`), the header is filed under its round ("[R04] Pulled Aggro Off the Tank — Greg, Severe"), and the scroll's fold snaps to the last LINE that fits whole (`Results._snap_report_fold`, `Guildhall.fold_height` reused).
- Spec 02 §2.1's sentence now says so. `EventLog.describe()` (the sim's plain rendering, the goldens' `story` arrays) is untouched.

Tests: `tests/unit/test_log_player.gd` (every `Mistakes.TYPES` name whole on the first line; the whole header with the pool's longest shape never past two), `test_raid_beats.gd :: test_no_revealed_mistake_header_or_quote_clips_and_every_row_is_whole_pitches`, `test_results_layout.gd` (no `LabelQuote` trims, the fold's wiring and arithmetic).

## Row B — docs/07 §5.5's fourth guard, the log collapse, is a DISPLAY-time fold behind `LogPlayer.COLLAPSE` *(DECIDED - implemented as a switch, default on)*

**Owner:** docs/07 §5.5 / docs/13 §11 - **Signal:** Quiet; a wall of "Went AFK" rows in a miserable raid (64 mistakes in 16 rounds on `e5_miserable_commons`)

docs/07 §5.5 row 4: "Identical Minor events by different raiders in the same round collapse to one line with a count | Readability; doc 13 owns the widget". docs/07 §10 rule 2 says the sim emits everything, so the fold is display-side (`game/core/LogPlayer.collapse`, pure, applied once when a `LogPlayer` is built and by `Results._log_panel`): Minor + same round + same `mistake.type` + DIFFERENT raiders fold into one synthetic entry carrying `params.count` and `params.actors`, landing where the last member stood with its `sequence` (so RaidView's HP fold never runs ahead of the page) and printing that member's joke — one line for the folded row (CONTENT-13's "the bag draws once" is met at the reading end: N were drawn, one is shown). A Severe never folds (docs/13 §11.2's beat), a knock-on (`caused_by`) never folds (its chain is the point), one raider twice is two lines. The header reads "Went AFK — 3 raiders, Minor"; the names are the row's tooltip. The rail counter counts the ACCOUNT (`count_of`), never the rows. No `GameSettings` key was added (docs/13 §15.1's inventory is closed — M5-COMEDY-10's risk clause); the switch is `const LogPlayer.COLLAPSE := true`, the designer's to flip if the wall of AFKs was the joke.

Tests: `tests/unit/test_log_player.gd :: test_identical_minor_mistakes_in_one_round_collapse`, `:: test_collapse_never_merges_across_rounds_or_severities`, `:: test_a_folded_row_reads_as_a_count_on_the_screen`; `test_results_layout.gd :: test_the_report_folds_identical_minor_rows_like_the_live_log`.
