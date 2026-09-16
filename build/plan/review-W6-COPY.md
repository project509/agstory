# review-W6-COPY — brief look, 2026-09-15

## What I saw

- `build/shots/review-W6-COPY.png` (Town `--fixture=new`, 1536x1024): the Blacksmith plate reads "Closed. The smith took a better offer." — no Canon/build word; the mission card's facts read "Trash · 1 enemy · about 6 rounds"; the promise line "Next at Known: Guildhall facility upgrade I; Quest board."; the four visible cards carry backstory quotes under register names (Bob/Keith/Barry/Alan, 43-46 morale); the log reads "Day 1. Nothing yet — the board is up the road." over "Raids and rests write here.". Nothing overlaps, nothing runs off the frame, no blank panel. "View All / Opens at Known." is still the link's label (held to handoff #3-#7, as the report says).
- `build/shots/review-W6-COPY-board.png` (AdventureBoard `--fixture=new`): TR reads "Clear Adventure 0 first." (display name, no slot code in prose); "1 enemy" on every rung and the notice; exactly one reward cell with the charm icon; "A party of 4" under Go to prep; the standing "120 more to Known, which opens more of the same, better paid."; the skip line "This one is hard. Skipping it forfeits the Cracked Charm of Power — +1 Power and nothing else. It is not a good trinket." Layout intact.
- `tools/lint_copy.sh` by hand: `COPY LINT OK ... 20 allow-listed fall-throughs, all present`. verify.sh:95-98 runs it guarded by `-f`.

## Tests (owned files only, RUN_TESTS_ONLY through the lock)

`test_copy_lint,test_screens,test_town_layout,test_roster_layout,test_starting_roster,test_raider_detail,test_ladder,test_raid_plan,test_menu_lockup,test_board_rows,test_kit3,test_names_and_backstories,test_reputation` → **TESTS PASSED 298 test(s) in 14 file(s)**, 0 failing. (The `_fail` backtraces in the log are the two test_screens navigation-failure cases asserting push_error, expected.)

## Audit closures

- **M3-LOOP-03** (copy half): yes — Town.gd:119 `blurb` is the one source; Town.gd:546 prints `Reputation.town_unlock_for_build(rank, flags)`; held by test_screens.gd:361/468/488 and the copy lint. The `blacksmith_tier` GameState clause is correctly left open.
- **M3-LOOP-04** (display-names half): yes — RaidPlan.gd:419 `"Clear %s first." % display_name`; test_ladder.gd:78, test_board_rows.gd:432 hold it; shot confirms. The `building_level("board")` seam stays open, as the report says.
- **M3-TUNE-05** (`town_unlock` half): yes — data/reputation.json has 12 `{building, text}` rows; Reputation.gd:646-663 join/filter; test_reputation.gd:507 + test_reputation_schema.gd:248. The recruitment.json half stays open.

## Unowned files

None touched. `tests/unit/test_copy_lint.gd.uid` is Godot's sidecar for the owned new test (auto-generated, this unit's). Shots under build/shots/ are ignored by git.

## Notes (minor)

- verify --fast is red on 4 pins in test_paper_doll.gd (x3) and test_text_scale_layout.gd (x1) — both unowned this wave; handoff #12-#15 carries the exact retargets. Expected for a copy directive that removes pinned strings; orchestrator applies at close.
- "View All" → "Records" relabel (LOOP-15) and the one-raider morale sentence (UI-51, `Cards.SINGLE_ROW_SENTENCE = false`) are deferred to the handoff behind unowned pins — both visible in the Town shot as the old label. Not a defect of the tree.
- The rung Buttons still carry "A0 —", "TR —", "A1 —" slot codes (by design: the loop test presses by them; only prose lost the slot).

## Verdict

**PASS** — headline change shows in both shots, owned tests 298/298, tree parses (shots mounted, lint OK), audit closures hold as scoped.
