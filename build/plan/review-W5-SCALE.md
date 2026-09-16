# Review W5-SCALE — the 150% pass (M6-A11Y-05 layout half)

Brief review, 2026-09-15. Verdict: **pass** (with notes).

## What I saw

- `build/shots/review-W5-SCALE.png` (Tavern --fixture --set=text_scale=150): four seat cards each show the authored pixel face on "starts at 46 😐", Pauline_4's "Wizard — / Common" wraps and her Look plate sits level with the other three, inside the card rim; the Looking/Look plates are the card-action idiom. Nothing overlaps; bullet lines trim behind a scroll bar as the report says. The sidebar's own scroll folds through "Not tonight" (report's Left item, not this unit's).
- `build/shots/review-W5-SCALE-2.png` (Completion --fixture --completed --set=text_scale=150): "Back to town — / the guild carries / on" wraps to three verbatim lines and ends inside the sidebar (~968 of ~1000); the twelve-row roll and the credits paragraph fit. The report band covers the camp speech bubble ("I think I'm ready for a real raid thi…") — seen, the stage's, disclosed in the report.
- RaidView.gd diff is exactly one line (:1725, `Type.at(Type.FIGURE_XL, Theme_.scale_of(self))`).

## Tests

`RUN_TESTS_ONLY=test_text_scale_layout` → TESTS PASSED 9 test(s) in 1 file(s) [3070 ms]. 0 failures.
Note: the run prints ~6 engine WARNINGs ("Nodes with non-equal opposite anchors will have their size overridden after _ready()") from `_reshape` (test_text_scale_layout.gd:318) with full GDScript backtraces — noise, not failures.

## Audit closures

- M6-A11Y-05 (layout half): **yes** — test_text_scale_layout.gd sweeps 13 routes x 3 scales with the fixture and asserts overflow/clip/container fit with self-tests; Settings' CTRL_H through Type.at is asserted at 150; the three unscaled font sites route through Type.at. The remaining 150 debts are the kit's and are in KNOWN + handoff-W5-SCALE.md with numbers.

## Notes (minor)

- The contract asked for an empty allow-list on owned screens; KNOWN (test_text_scale_layout.gd:95-150) still carries rows on Guildhall/Town/Tavern/Results (`Cell_`, `RosterStrip`, `Wiped on Raid 1`) — kit-component overflows (Cards.card / Cards.event_log) hosted by owned screens, disclosed in the report and handed off to KIT3. Reasonable under rule 7; the orchestrator should track that these rows empty when the kit lands.
- Tavern at 150: bullet lines in the seat cards show one line and trim ("• Has never once", "• Checks the") — the report's designed scroll; reads a little cramped but nothing is cut off the frame.

## Ownership

No file outside the owned list is this unit's; other tree changes belong to other units. build/shots/ is untracked output.
