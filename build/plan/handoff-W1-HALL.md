# Handoff — W1-HALL

Every code edit this unit needs is in an owned file (Guildhall.gd, Roster.gd,
Facilities.gd, RaiderDetail.gd, LoadSave.gd, Settings.gd, ScreenRouter.gd
`previous_path()`, tests/unit/test_hall_plates.gd). One comment edit below is in a file
another unit owns; nothing here is applied by this unit.

## 1. game/screens/AdventureBoard.gd:126

The acceptance grep `grep -rn guildhall_plate game/screens game/ui` has exactly one
survivor: a historical comment in a file this unit does not own (W2-BOARD's, untouched in
wave 1). LESSONS: "keep the record, drop the path" — the fact worth keeping is that the
board once stood on the hall crop, not the filename, which is what the grep (and any
future `_plate.png` lint) trips on.

old:
```
## It used to load `guildhall_plate.png` on a comment that read "the board lives
```
new:
```
## It used to load the Concept 1 hall crop on a comment that read "the board lives
```
