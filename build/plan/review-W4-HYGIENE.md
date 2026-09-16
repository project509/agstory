# Review — W4-HYGIENE — the records tell the truth and the guards close

Brief look, 2026-09-15. Plan's Shot line is "none (records)", so one shot of the screen the new
sidebar guard turned on.

## Shot
`RaidPrep --fixture` → build/shots/review-W4-HYGIENE.png (shot exit 0). The sidebar column
(Current Raid, boss card, rewards, the crimson "~58.5 mistakes" verdict callout, Raid Team, Depart
"12 of 12 chalked", Back to the board) ends around y=680, inside the 714px band that
`test_sidebar_fit.gd` measures — the overflow the unit found (672/703 in 635) is gone in the tree,
matching the report's account that W4-PREP's ScrollContainer flipped the row. Nothing overlaps,
no text leaves the frame, no blank panel; the strip shows four cards, bench 0 with empty seats,
provisions "The cupboard is bare", pager 1/3. The other headline items are records: the `Color("`
lint prints "MOTION LINT OK … and every colour under game/ is a Palette role" (exit 0); the four
LIES rows are in test_project_hygiene.gd (+18 lines); docs/12, BUILD_STATE, spec 00 §2.7, spec 06 §3
and audit.json diffs are present (310+/255-).

## Tests (pinned runner, scratchpad/run_review_W4-HYGIENE.gd)
test_project_hygiene.gd + test_sidebar_fit.gd → `TESTS PASSED 11 test(s) in 2 file(s) [2957 ms]`,
exit 0. 0 failures.

## Files
Owned list all touched. Outside the list but the report claims them as this unit's: docs/_log/progress.md
(+50, the BUILD_STATE overflow — the report's Owns line names it) and tests/unit/test_sidebar_fit.gd.uid
(generated with the test; should be committed with it). Nothing else outside the list is this unit's.
git's CRLF warning on BUILD_STATE.md / test_project_hygiene.gd is pre-existing (autocrlf=true; HEAD
copies are CRLF too) — not a change.

## Notes (minor, no repair asked)
- BUILD_STATE.md is 321 lines against the ~250 target; the report says what remains is orientation.
- The stage_town.json LIES row waits on handoff §5 (W4-LIFE's file); the orchestrator applies it.
- Seven handoff edits (GameSettings.PATH static var, run_tests settings redirect, playtest/a11y_smoke
  SAVE_DIR, stage_town.json prose, shot.gd tab→space, LESSONS.md) are for the orchestrator.

## Verdict
PASS. The guards close (lint green with the new door, sidebar guard green on all 13 routes) and the
records diffs are on disk; the unit's own tests pass 11/11; the shot shows the guarded screen fitting.
