# review-W3-ROSTER — brief review of "the roster reads in two seconds"

Reviewer: wave-3 brief pass, 2026-09-15 00:55. Replaces the 00:41 static pass at this path (its one note is carried below).

## Shots (both viewed)

- `build/shots/review-W3-ROSTER.png` (`Guildhall --fixture`): the headline change shows. Two full rows of
  four cards (y 148..410, 418..680) with Cheer up / Manage inside each card's band and "They are fine." under
  a shut Cheer up inside the rim; the third row's top rims at ~y 688; the bronze scrollbar at x ~1118..1125.
  Tab row: Roster on the plate with a gold underline, Raid Group / Records dimmed, each caption under its own
  tab. "AT RISK" stamp box across Tiny's portrait. Sidebar: "Showing 12 of 12", the ten-band histogram
  (1·1·8·1·1), Sort with Morale lit, Filter with All lit. Strip: all twelve in 3x4 two-line entries.
  Nothing overlaps, nothing runs off the frame, no blank panel.
- `build/shots/review-W3-ROSTER-records.png` (`--fixture=raid:clear --press=Records`): Records lit with the
  underline; every row leads with a state icon (dimmed padlock on Locked, the gem on Earned "First Blood" with
  its Claim button); the sidebar carries "3 of 40 earned · 0 claimed", the coin-cap line, the Show chips
  (All lit). Nothing broken.

## Tests

- `scratchpad/run_review_W3-ROSTER.gd` (FILES = tests/unit/test_roster_layout.gd), through the lock:
  `REVIEW TESTS PASSED   15 test(s) in 1 file(s)  [1401 ms]`. 15/15.

## Notes (minors, no repair requested)

- Rhona's band reads "Shaman — Slightly Annoy…" at 100% (primary shot, x 692..880 y 296): the kit card's
  ellipsis trims a state word docs/13 §8.1 never abbreviates. Known, KIT2's, in the handoff as an observation.
- The Records sidebar has ~320px of empty run under the Show chips (records shot, y 320..640); the Roster and
  Facilities sidebars are filled. HALL-09 named only the roster half.
- `Facilities._picker`'s 2px EDGE_READY_GOLD rim is a screen-local StyleBox, not the theme's ButtonMini
  pressed box — the look matches HALL-22; a Theme.gd handoff would be the tidy home.

## Ownership
`git status --porcelain`: this unit's changes are Guildhall.gd, Roster.gd, Facilities.gd, docs/13-ui-ux.md
(one line, the OQ-4 row), test_roster_layout.gd (+ its .uid sidecar), report/handoff. Every other modified
file is another wave-3 unit's by name (KIT2's kit files, ENEMIES' SceneStage/enemies, the OPTIONS/DETAIL/RAID screens).

## Verdict
PASS. The headline change shows, the Records wall shows its icons and a built sidebar, 15/15 tests pass,
the tree parses with the owned files in it.
