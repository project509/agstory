# review-W6-SIM-CASCADE — brief look

Sim unit, no shot (the contract's `Results --fixture=raid` shot is the wave-close's). Read the report and the main diffs instead.

## What I saw

- `tools/verify.sh`: a guarded stage-1 copy-lint block (`-f tools/lint_copy.sh`, SKIP otherwise) and a `6b/8  balance drift vs the committed baseline` stage running `balance_sweep.gd -- --drift --seeds 200`, greps `SWEEP OK`, FAIL otherwise, SKIP under `--fast`. Both additive.
- `sim/core/RaidSim.gd` (+282/-): `_situational_bp(c, combatants, site)` now reads the raid (healer +800 under anybody's Aggro, +500 at AMBIENT under anybody's Distraction, cap kept); `_parent_for`/`_attribute` call `Mistakes.attribute` at the five roll sites; `_wipe_cause` + `SimResult.wipe_cause` + `WIPE_CULPRIT_DELTA := -4`; `encounter_start` replaces `compliance`; `zone_exists` flows into the Context. `Combatant.token_source`/`live_tokens` already existed, so `sim/model/Combatant.gd` is untouched. The diff does what the contract says.
- `tests/golden/e5_miserable_commons.json`: story shows 32 `(after gNN:rN:MIS_*, depth N)` edges and ends with `It traces back to Cindy — Healed a Corpse, round 4.`; outcome still `wipe`, 10 rounds.
- `tests/baselines/sweep_baseline.csv`: nine rows including `A3,after_a2` at 0/200; the report carries the three-way (500→200 sampling, then rule change) numbers for the commit message.

## Tests (unit's files only, through the lock)

`RUN_TESTS_ONLY=test_raid_sim,test_mistakes,test_event_log,test_sweep_baseline,test_golden` → **TESTS PASSED 149 test(s) in 5 file(s)** [9.8 s]. 0 failing.

## git status

Every file this unit changed is in its owned list (RaidSim, Mistakes, EventLog, balance_sweep, verify.sh, baseline CSV, five goldens, five test files) plus report/handoff/q files. No unowned file touched by this unit; `sim/model/Combatant.gd` unchanged (its `token_source` was already there).

## Audit closures

- **M6-BAL-02** (gate clause only): yes — verify.sh 6b runs the drift comparison, `test_sweep_baseline.gd` pins the invocation, the seed count and the `after_a2` row; the report records the 6pp red-proof. Piece 3 (sweep axes, roster fixtures) correctly left open.
- **m5-token-effects-and-cascade** (pieces 1-2): yes — `_attribute` at every roll site with `test_a_mistake_under_a_live_token_names_its_parent` and the golden test showing 32 edges; `_situational_bp` raid-wide with the three named tests. Piece 3 (Adds amplifier) correctly left to SIM-15.

## Notes (minor, no action asked)

- The golden JSON is a story+hash document, so `caused_by`/`wipe_cause` are not literal top-level fields; the story lines carry them (32 edges, the cause line) and `test_the_worst_case_golden_shows_a_cascade_and_names_the_cause` holds it. `tools/write_goldens.gd` is not owned — stated in the report.
- Two `--rebaseline` runs inside one unit (seed-count conversion, then the rule change) collapse to one git diff; the report's judgement call explains why and gives both tables. The commit message should carry them as the report asks.
- Stage numbered `6b/8` (plan text says `6b/9`); the acceptance asks only for a `6b/` line.

## Verdict

**pass** — the headline change (drift gate + attribution/wipe cause/raid-wide tokens/no fire without fire/channel rename/debug fields) is in the tree, the five goldens regenerated once, the unit's 149 tests are green.
