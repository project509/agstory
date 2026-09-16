# review-W3-OPTIONS — brief look

Reviewer: BRIEF (wave 3). Shots: `build/shots/review-W3-OPTIONS.png` (`LoadSave --fixture`), `build/shots/review-W3-OPTIONS-settings.png` (`Settings --fixture`), both viewed.

## What the shots show

- LoadSave: three slot rows, nine buttons at one width (Load / Save / Delete, 168x36 by eye — the row fills the 526 inner width), the dimmed Load/Delete each carry a padlock, "Slot N is empty." printed ONCE per row in CAUTION under the button row, no ISO-8601 string anywhere. The panel ends at y≈568 with a single rim line; the camp (seated figure by the lantern, bridge, stream) shows beneath it. Header sentence breaks cleanly on two lines. Nothing overlaps, nothing runs off the frame.
- Settings: 17 rows at one pitch (≈41px), "On" on Comedy brake lit gold (rim + text) while every Off/1x/Keep/100% sits on the resting chip; the four audio rows show five blue pips beside the number (80 → 4 lit, 100 → 5); the four disabled rows (Prose font swap, V-sync, Language, Controller glyphs) are dimmed with a padlock and their reason in CAUTION in the description column; the panel ends at y≈878, ≈33px under the last row, and the stream's water band is visible below (y≈880..1005). Apply is on the plain secondary plate (the "ButtonSecondaryLit" fallback until the Theme.gd handoff lands), no crimson CTA. Nothing broken.

## Tests

- `tests/unit/test_options_layout.gd` through `scratchpad/run_review_W3-OPTIONS.gd`: REVIEW TESTS PASSED 15 test(s) in 1 file(s) [1445 ms]. (Report says 14; the file has 15 `func test_` — one more landed after the report line was written. Not an issue.)
- Full suite / verify.sh not run here (orchestrator gate at wave close); implementer's run 4 log claims 1908/1908.

## git status

- Owned and changed: `game/screens/LoadSave.gd`, `game/screens/Settings.gd`, `tests/unit/test_options_layout.gd` (+ its `.uid`, engine-generated, expected), `build/plan/report-W3-OPTIONS.md`, `build/plan/handoff-W3-OPTIONS.md`. No unowned file touched by this unit.

## Notes (minor, none blocking)

- Apply renders as the plain secondary plate until the orchestrator applies `handoff-W3-OPTIONS.md` #1 (Theme.gd `ButtonSecondaryLit` + ButtonChip hover_pressed). Expected per the report.
- The plan's `Settings --fixture --focus --tab=6` shot lands the ring on the rail (Frame.tab_steps_within_region = false); the implementer recorded this and used `--tab=4` to show the chip ring. Plan-note, not a defect.
- `tests/unit/test_options_layout.gd.uid` is untracked and will be committed with the test file; fine.

## Verdict

PASS — headline changes visible in both shots (one button geometry, one reason per row, no ISO stamp; lit On chips, uniform pitch, volume pips, panel ending with the water band visible), unit test file green (15/15), tree parses (both shots and the runner compiled every dependency).
