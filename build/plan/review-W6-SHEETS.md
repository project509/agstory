# review-W6-SHEETS — brief look

## What I saw

- `build/shots/review-W6-SHEETS.png` — Town `--fixture=new`, 1536x1024, fresh shot through the lock. Headline visible: header "60 G · 0 RP · Roster 12 of 15 · Day 1 · Unknown", next mission "Adventure 0 — Trash · 1 enemy", the four raider cards carry name + morale only (no "Lv."), the log panel reads "Day 1. Nothing yet — the board is up the road." Nothing overlaps, nothing runs off the frame, no blank panel.
- `build/shots/review-W6-SHEETS-play.png` — Town `--fixture=play` (stdout: `FIXTURE play: day 4, 160 G, Known, seeds A0=23 TR=24 A1=23`). Header "160 G · 120 · Roster 12 of 16 · Day 4 · Known", next mission "Adventure 1 — Encounter 2", "6 recent events on the log", six rows headed "Cleared Adventure 1 — Encounter 1 — 4 G." All twelve starters still show (the plan's "six Commons" is W6-LEDGER's roster change; the report says so).
- A `--headless` run of shot.gd fails with "viewport image is null — a real display server is required"; windowed run works. Pre-existing behaviour (shot_all.sh never passes --headless), not this unit's.

## Tests

`RUN_TESTS_ONLY=test_w0_shot,test_export,test_widgets_kit` → `TESTS PASSED 61 test(s) in 3 file(s) [1198 ms]`. 0 failing.

## Ownership

`git status --porcelain`: tools/shot.gd, tools/shot_all.sh, tools/fixture_reference.gd, tools/export_build.sh, tests/unit/test_export.gd, test_w0_shot.gd, test_widgets_kit.gd (modified); PROVENANCE.md, report-, handoff-W6-SHEETS.md (new). All owned. export_presets.cfg untouched. No game/ or sim/ file is this unit's.

## Audit closures

audit_closed is empty; the report's "## Audit closures" lists only notes on rows already done/blocked (M6-EXP-02 extended, Q-21 gate now red-and-visible). Nothing to confirm or deny.

## Notes (minor, no repair asked)

- Acceptance's "two-line plate at every site" is delivered as handoff §1-§5 (Market x2, RaidView, Tavern are other units' files this wave); only RaiderDetail's site shows the kit plate on the `hover` sheet. Tavern gear cell cannot light until `Recruitment.gear_plan()` gets a caller (handoff §6) — orchestrator queue row.
- Acceptance's `--user-data-dir <tmp>` does not exist in Godot 4.7.1 (probed, silently ignored); step 7 redirects APPDATA/XDG to a temp root and asserts app_userdata appears there. Reasonable substitution, recorded in the script header and test_export.gd.
- Step 7b greps no "migration line" (none is printed at boot); it asserts a clean boot with v10_sample.json as slot 0, the file byte-identical, no .bak.
- `export_build.sh --dev` was run with `--skip-gates` (the gate is the full verify, red mid-wave on others' files); stamp names both holds.
- Sidebar "Adventure's Board" label sits flush against the sidebar's right edge in both shots (a faint mark after "Board") — pre-existing Town sidebar, not this unit's.

## Verdict

PASS — the new fixtures show what the contract names on a fresh shot, the unit's 61 tests are green, the tree parses, every changed file is owned.
