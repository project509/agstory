# review-W4-PREP — the prep strip and the dimmed arena

Brief review, 2026-09-15 10:4x. Verdict: **pass**.

## Shots (both viewed with the Read tool)

`build/shots/review-W4-PREP.png` (`RaidPrep --fixture`): the headline change shows. The cave plate is
scrimmed and a 2px bronze rim at x≈284-671, y≈305-500 captioned "The party stands here" frames the lit
lantern floor; outside it the arena sits a shade darker. Readout panel complete (Comp check / Gear /
Predicted risk / Verdict: Reckless, no scroll bar); sidebar shows the mission card, two reward slots, the
crimson verdict callout with its sweep and the flourish in its top-right corner, four Raid Team portraits,
the wax Depart plate "12 of 12 chalked" and "Back to the board". Strip: "Bench 0" with the 2x4 empty
seats, four cards (Bork/Gruk/Rhona/Greg) each with its Bench button, the pager arrows in the gutters at
x≈132 and x≈1035 touching no card, "1/3", and Provisions in the log slot. No overlap, nothing off-frame.

`build/shots/review-W4-PREP-empty.png` (`RaidPrep`, no guild): the second new thing shows — eight empty
seats, the bench glyph over "No raiders to chalk." / "The Tavern has candidates." centred on the card
band; Depart dimmed with the padlock in its leading slot, "0 of 12 chalked", and the reason "No mission
chosen. Pick one on the board." directly under it in caution ink; the band + scrim as above.

## Tests

`scratchpad/run_review_W4-PREP.gd` pinned to `tests/unit/test_prep_layout.gd`: TESTS PASSED 16 test(s)
in 1 file(s) [1431 ms]. No SCRIPT ERROR in the shot logs.

## Notes (minor, no repair asked)

- The FIRST capture of each shot came out partial: arena band + scrim + the empty-state glyph drawn, but
  the readout, sidebar and strip panels absent (chrome/scene only; 932KB vs 1.04MB). The engine exited 0
  and my grep only kept the tail. Immediate retakes through the lock were complete, so this is most likely
  a transient from a shared kit file (Widgets.gd/Cards.gd) being mid-edit by another agent at that
  moment, not RaidPrep.gd. Worth one eye at the wave gate if the fixture shot ever shows blank panels again.
- Card text trims in the strip ("Slightly Annoy…") are Cards.gd's card at this width, as the report notes.

## Files outside the owned list

- `tests/unit/test_prep_layout.gd.uid` — Godot's generated sidecar for the unit's new test; this unit's.
- Handoff file is empty by design (nothing needed outside owned files).
