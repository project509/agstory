# Review — W5-SIM (brief)

## What I saw
- Sim unit, no shot. Read `git diff -- sim/core/Mistakes.gd sim/core/RaidSim.gd`.
- Mistakes.gd: `TUTORIAL_MISTAKE_MULT := 0.5`, `TUTORIAL_DISABLED_TYPES`, `Context.tutorial`, the ban in
  `eligible_types()`, a `chance_bp()` accessor that `roll()` reads, and `force()` (no gate, gentle-first
  weighted draw, Minor at the type's floor). RaidSim.gd: `Reputation` preload, `_is_tutorial()`, the flag on
  all five Context sites, `round_state["forced_slot"]`, `_pick_forced_mistake_slot` on its own Rng channel,
  and the `Mistakes.force` branch in `_take_action`. Does what the contract says; sim/ stays pure (seeded
  Rng only, no Node/await, no game/ import); four spaces throughout.
- The three mechanic rows were already in the tree (report documents where); the new
  `test_mechanics_arms.gd` adds a static source-level dispatch guard with an empty explicit allow-list
  (`MECHANICS_WITHOUT_AN_ARM := []`) plus log-side M11/M12 holds.

## Tests (through the lock)
- `RUN_TESTS_ONLY=test_mistakes,test_mechanics_arms,test_tutorials` -> `TESTS PASSED 72 test(s) in 3 file(s) [1307 ms]`.
- Full suite / verify.sh not run here (orchestrator's gate).

## git status vs owned list
- All of this unit's changes are on the owned list: `sim/core/Mistakes.gd`, `sim/core/RaidSim.gd`,
  `tests/unit/test_mistakes.gd`, `tests/unit/test_tutorials.gd`, `tests/unit/test_mechanics_arms.gd` (+ its
  `.uid`, now present), `build/plan/{report,handoff,q}-W5-SIM.md`. Nothing outside the list.

## Audit closures
- M5-TUT-11: yes — flag, halving and two-type ban in the tree; held by 4 tests in test_mistakes.gd and
  `test_both_tutorials_roll_at_the_reduced_rate_and_a_real_rung_does_not`.
- M5-TUT-12: yes — `force_mistake_round` now read by RaidSim; held by 20-seed A0 tests in test_tutorials.gd
  and 4 `force` tests in test_mistakes.gd. docs/10 §6 row is handoff #1.
- m5-m11-frontal-cleave: yes — pre-existing `_fire_frontal_cleave` + second hold in test_mechanics_arms.gd.
- m5-m12-escalating-swing: yes — pre-existing `_tick_escalating_swing` + log-side hold in test_mechanics_arms.gd.
- m5-mechanic-dispatch-guard: yes — static guard with explicit allow-list (empty) in test_mechanics_arms.gd.

## Notes (nothing broken)
- Canon question, correctly not retuned: the 0.5 moved the Tutorial Raid pin 0/20 -> 1/20; pin now asserts
  `TUTORIAL_RAID_CLEARS_AS_MEASURED := 1` with `cleared < 8` (test_tutorials.gd:364-373) and q-W5-SIM.md
  carries it OPEN for the designer.
- Report's one verify --fast red (`test_game_state.gd:236`, Q-59 citation) is another unit's file.
- Drift gate +0.0pp on all 8 cells per the report; baseline untouched.

## Verdict
PASS.
