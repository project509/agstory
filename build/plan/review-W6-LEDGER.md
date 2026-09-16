# review-W6-LEDGER — brief review, 2026-09-15

**Verdict: PASS** (with notes).

## What I saw
- Shot `build/shots/review-W6-LEDGER.png` (`Tavern --fixture=new`, 1536x1024): the headline change shows — the sidebar CTA reads **"Hire — 15 G"** and the footer's arithmetic agrees ("Hiring Doug1 leaves 45 G" from the 60 G purse). Nothing broken: no overlap, no text off-frame, no blank panels; the four seat cards, Board/Manage tabs and the Recent Events panel all render.
- Observation (not this unit's): the header reads "Roster 12 of 15" while the plan's `--fixture=new` line says six Commons — W6-SHEETS's fixture, already flagged in the implementer's report.
- `sim/core/Recruitment.gd` diff: `COST_BASES {doc11, doc04}` + `static var PRICE_SCALE := "doc11"`; `cost_of()` returns the base at CT 1 and doc 04's multiplier above it — does what the contract says.
- `designer-page.md`: 67 `### #n` rows, 67 `**Default:**` lines, 67 `**Answer line:**` lines (one each); the 15 G figure is in row #1's arithmetic and row #47's PRICE_SCALE question.
- docs/15: 95 `### BL-` headings; BL-82..94, BL-107, BL-109, Q-97..99 present with status markers. BUILD_STATE is exactly 250 lines and carries 120/53/17, matching `audit.json` (120 done / 35 not-started / 18 partial / 17 blocked). `audit_stale.py --top 15` names no `done` row.
- `handoff-W6-LEDGER.md --dry-run`: all 16 edits match (dry-run writes nothing; RaidSim/Mistakes still cite q-*.md, 0 BL citations — as expected before the orchestrator applies it).

## Tests (unit's files only, RUN_TESTS_ONLY through the lock)
`test_recruitment, test_playtest_invariants, test_audit_hygiene, test_build_state, test_docs_links` → **62 passed, 0 failed** in 5 files [947 ms].

## git status
Every modified/new file in the implementer's list is on the owned list; `GameState.gd` and `test_build_state.gd` untouched (report says :894 needed no edit). Untracked `build/plan/ship/rulings/` (COMBAT.md, SCREENS.md, 14:37) is NOT this unit's — the report never mentions it; another process's.

## Audit closures (tree + test?)
- M3-SAVE-01/-02/-07/-08/-10: yes — `TOWN_SCREENS`/`_on_screen_changed`, played_seconds, the v10..v16 chain, `reconcile_content`, `rank_canary` all held by `test_savegame.gd`.
- M3-TUNE-01/-03/-04: yes — `data/reputation.json` the one source (`Recruitment.gd:38,392-411` derives its aliases), `test_reputation.gd` + `test_recruitment.gd`; -01 is a docs ruling (BL-81), record-only.
- M4B-CONV-01/-02: yes — bare plates only under `game/assets/bg/`, `test_hall_plates.gd`; -02's `arena_stage.png` is gone.
- m5-mech-roll-site, m5-m01-tank-swap, m5-m03-ground-effect, m5-m07-positioning, m5-m08-fixate, m5-m09-healing-debuff, M5-T25-12: yes — `test_mechanics_arms.gd` (an arm per Mechanic) + `test_raid_sim.gd` (`MECHANICS_WITH_NO_BEHAVIOUR := []`).
- m5-m04-double-spawn: yes — `RaidSim._add_spawns_fires_on` (:536) exists; the note names `test_raid_sim.gd`.
- M5-TUT-01/-02/-06/-08: yes — `test_tutorials.gd` exists; -06 is board wiring + BL-79 (record).
- M5-COMEDY-03/-04/-08: yes — `test_mistake_lines.gd` exists with the budget/repeat/coverage walks; M5-COMEDY-13: yes as a record (BL-80), no test needed.
- M5-QAB-3: yes — Records tab + `data/achievements.json`, `test_starting_roster.gd` cited in evidence.
- M6-AUD-01/-02: yes — commit 756081a, `test_audio.gd` / `test_settings.gd`.
- M6-A11Y-07: yes — `RaidView._log_kind` (:2028) + `Icons.at("log", kind)`; held by the icon tests, not a dedicated one.
- m4t-12, M4B-VFX-01: yes — done under another name / retired with the crop; record closes, no test needed.
- M6-JUICE-07: yes — `test_perf_mount.gd` exists, stage 8 is the perf test.
- DW-A1/-A2/-A3/-A4: yes — `test_docs_links.gd::test_file_links_resolve / test_link_fragments_resolve / test_every_register_citation_resolves_to_a_declared_entry / test_prose_doc_filenames_exist` all exist (:184/:208/:351).
- M3-LOOP-01, M6-JUICE-01, m4t-05, m4t-13, M5-TUT-15, DW-B1, DW-E1, M6-FINAL-01: yes — done-backlog-stale rows; the work was already in the tree, BACKLOG corrected in this pass (DW-B1 held by `test_formulas.gd`; TODO/FIXME grep under game/sim/tools/tests/data returns only two false positives in tool strings).
- M3-LOOP-02: yes in the tree (both tables derive from `data/reputation.json`), but the note cites `test_reputation.gd::test_no_tuning_number_exists_in_two_places_at_once`, which does NOT exist under that name in any test file — the citation is wrong; the structural derivation still holds the row.

## Notes (minor)
- `audit.json` M3-LOOP-02 `remaining_work_note`: nonexistent test name cited (see above); one-line fix when the orchestrator closes the wave.
- Orchestrator reminders from the report stand: do NOT apply `handoff-W6-SIM-CASCADE.md` §1 (BL-107 already landed); close/re-scope M6-AUD-06; spec 00 §2.7 switch rows are in the handoff's note.
