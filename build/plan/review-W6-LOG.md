# review-W6-LOG — brief look, 2026-09-15

Verdict: **pass** (with notes).

## What I saw

- `build/shots/review-W6-LOG.png` (`RaidView --fixture=raid --advance=10`): the headline shows — "Pulled Aggro Off the Tank — Tiny, Severe" leads with the type on one line beside the MISTAKE stamp, no ellipsis; both quotes wrap whole to two lines; rows sit on the pitch grid. Nothing overlaps, nothing runs off the frame.
- `build/shots/review-W6-LOG-results.png` (`Results --fixture=raid`): "What happened" prints "[R00] Started an Argument in Raid Chat — Alan, Moderate" wrapped to two lines, the joke whole on two, "[R01] Stood in the Fire — Tiny, Severe" as the last whole line above the fold. By raider has the "Raider · Mistakes · Morale · State" header and the red MISTAKE face where the claw was; the morale column shows because the fixture's ledger is -12/-18 (not flat).

## Tests (owned files only, through the lock)

`RUN_TESTS_ONLY=test_log_player,test_raid_beats,test_results_layout` → **TESTS PASSED 71 test(s) in 3 file(s)** [2995 ms]. No full suite / verify run (the orchestrator's gate).

## git status

Every changed file is on the owned list (RaidView, Results, Widgets, LogPlayer, spec 02, the three tests) plus the three plan files and the new `tests/unit/test_results_layout.gd` (+ its `.uid`). Nothing outside the list is this unit's.

## Audit closures

- **M5-COMEDY-10** — yes: `LogPlayer.gd:30` `COLLAPSE := true`, `:96` `static func collapse(entries)`; held by the three `test_log_player.gd` fold tests and `test_results_layout.gd :: test_the_report_folds_identical_minor_rows_like_the_live_log`, all green above.
- M6-AUD-04 (RaidView half only, row stays open per the report) — the hooks are in the tree (`RaidView.gd:1750` ui.silence, `:1803` ui.stamp, `:1932` ui.seal, `:2039-2040` stamp+blot with `live`) and the two tape tests pass; not closed, as the report says.

## Notes (minor, no repair requested)

1. Live log scroll snaps to PITCHES, not to whole mistake ROWS: in the RaidView shot the top of the panel falls between the two pitches of a wrapped header — the MISTAKE stamp is cut in half and only "Moderate" (the header's second line) shows above the quote (`review-W6-LOG.png`, region ~1050,745–1300,775). Every row is a whole number of pitches (the test's claim holds) but a two-pitch header can still be split at the clip edge. Judgement call 1 made this possible; a row-aware snap would close it.
2. Results By-raider "State" column ("Fallen", and the "State" header) is whole but sits flush against the scrollbar with no gutter (`review-W6-LOG-results.png`, x≈1105–1145). Pre-existing column geometry, worth a pixel or two of right padding in W7-REPORT.
3. A tooltip ("Tiny assumed the tank would take it back…") floats over the arena at ~270,160 in the RaidView shot — the mistake row's courtesy tooltip surfacing under the shot's default mouse position; cosmetic to the shot, not the screen.
4. The plan's literal "header on one line" was consciously not shipped (report judgement call 1, measured 372px vs ~324 available); the type is always whole on line one and the header never exceeds two pitches. Recorded, not contested.
