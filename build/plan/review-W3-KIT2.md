# review-W3-KIT2 — brief review of "the kit's second pass and the hub's event feed"

Verdict: PASS (with notes). Brief look per the standing rule; no acceptance-line audit.

## Shots (taken through the lock, viewed with Read; 0 SCRIPT ERRORs in both .logs)

- `build/shots/review-W3-KIT2.png` — `Town --fixture=raid`, 1536x1024. The headline shows: Recent Events
  carries the feed's raid row "Wiped on Raid 1 — Encounter 5 — 12 fell." with the red frown badge, then
  five "<name>: wipe" rows each with the crisp red down-arrow badge; "View All" reasoned "Opens at Known."
  under the link. The four cards wear a class glyph before Warrior / Rogue / Cleric / Mage. The locked
  Blacksmith plate is two rows (title + one-line CAUTION reason) at its neighbours' height; the sidebar's
  PanelWarm has its corner ornament. Nothing overlaps, nothing runs off the frame, no blank panel.
  Crop `review-W3-KIT2_log2x.png`: six rows, one empty row's worth of space under them.
- `build/shots/review-W3-KIT2-hire.png` — `Tavern --fixture --press="Hire — 60 G"` (the plan's recipe for
  the recruit row). Recent Events reads "Hired Linda the Mage for 60 G." beside the person badge; the
  board says "Linda signs on…", Roster 13 of 15, gold 12,420. "Take the room next door" wears the padlock
  with its reason under it. Nothing broken.

## Tests (unit's files only, `scratchpad/run_review_W3-KIT2.gd` through the lock)

REVIEW TESTS PASSED   40 test(s) in 2 file(s)  [849 ms] — test_event_feed.gd 10, test_widgets_kit.gd 30.
Suite/verify not run here (the orchestrator's wave-close gate).

## Ownership

Owned files changed: GameState.gd, Widgets.gd, Cards.gd, Badge.gd, test_widgets_kit.gd, test_event_feed.gd
(+ .uid, new), boss_sludge_maw.png + .import (staged `D`). Bar.gd unchanged. Nothing outside the owned list
is attributed to this unit by its report; Town.gd's one-line diff is a Blacksmith blurb string, not this
unit's. `tools/probe/Kit.gd:134` still loads the deleted PNG until handoff §1/§2 apply (art-gate Kit target).

## Notes (minor, no repair requested)

- Count vs fit: the Town sidebar says "7 recent events on the log." (Town.gd:496 `recent_events(_state, 7)`)
  while `Cards.event_log` fits (262-28-36-1)/29 = 6 rows (Cards.gd:531), so the seventh row is never drawn;
  the shot shows 6 rows with a blank row's space below. Pre-existing shape; Town.gd is not this unit's.
- A4 (gear-slot tooltip) has no shot — shot.gd has no hover flag; unit-tested only, as the report says.
