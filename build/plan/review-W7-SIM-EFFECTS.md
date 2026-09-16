# review-W7-SIM-EFFECTS — BRIEF

Reviewer pass, 2026-09-15. One look, no audit.

## What I saw (no shot — sim unit; `.git` is gone from the tree, so I read the code, not a diff)

- `git status --porcelain` / `git diff` are unavailable: `.git` does not exist in the working
  tree ("fatal: not a repository"). The implementer flagged this too. I read the owned source
  directly instead. Step 4 (changed files outside the owned list) is therefore unverifiable
  here — flagged for the orchestrator, who must restore/inspect the repo before committing.
- `sim/core/RaidSim.gd:2237` dispatches `MIS_WRONG_TARGET` to `_swing_into_the_wrong_target`
  (`:2265`): first living active add takes `_outgoing_damage`, real threat is added, an ATTACK
  entry is emitted, and `wrong == null` returns silently — the pre-existing "swing is gone"
  behaviour with no add. The priority target is never touched. That is docs/07 §5.2 row 11 and
  the contract's SIM-15 row, and the paired test at `tests/unit/test_raid_sim.gd:1905` asserts
  all three arms (add damaged, boss hp unmoved, threat up, one ATTACK entry named "Loose Add").
- The four Legendary quirk hooks are genuinely called from production, not stubbed:
  `_threat_mult` at `RaidSim.gd:1684/1934/2282`, `relief_bp_bonus` at `:2488`, `tank_priority`
  at `:458`, `immune_to` in `Mistakes.gd:360` via `Context.quirk_id`. Nothing broken-looking.

## Tests (unit's files only, through the lock)

`RUN_TESTS_ONLY=test_raid_sim,test_golden,test_legendaries,test_mistakes,test_formulas,test_sweep_baseline`
→ **TESTS PASSED 226 tests in 6 files [22.5 s]**, 0 failing. The two `ERROR:` lines in the output
are `test_formulas.gd:257/259` deliberately exercising the unknown-AcReading guard (push_error by
design), not failures. `test_golden.gd`'s SHA replays are inside that green, so the regenerated
goldens are byte-identical to the committed ones.

## Audit closures

- **m6-ambient-effects — yes.** All four ambient consequences are in the tree and each has a
  named test: `test_raid_sim.gd:1690` (AFK 1/2/3), `:1761` (loot call skips + queues),
  `:1798` (argument names a second raider and taxes both), `:1835` (forgotten consumable
  stripped and reported). All green in the run above.
- **Q58-4 — yes.** All four hooks have real call sites (listed above) and the identity /
  golden-SHA assertions are at `test_legendaries.gd:311` and `:328`, both green. The route to
  the quirk id (`Quirks.expected_id_for` rather than a `ContentDB` LegendaryPool) is a
  deliberate, recorded substitution that keeps `sim/` pure; it satisfies the entry's intent.

## Broken / notes

- No breakage attributable to an owned file; the tree parses (the 6-file run loaded fine).
- The unit's one self-caused fast-gate failure (`test_kit3.gd:573`, missing `loot_call`
  MORALE_SENTENCES pair) is correctly carried as handoff §10 against W7-STAGE's `game/ui/Cards.gd`
  — orchestrator must apply it or the wave gate stays red.
- Two judgement calls worth the orchestrator's eye, both recorded and neither hidden: the ONE
  re-baseline (`sweep_baseline.csv`, A1 -15.5pp / E5 -30.0pp) and the Boss-5 fight-length ceiling
  moving 25 → 28 in `test_golden.gd` (floor untouched at 19, re-read from docs/08 §9.2's
  Content-Common column). Both are stated in the report with numbers.
- A1/starting at 25.5% is below Q-100's 65-85 band and is handed to W8-SIM-BALANCE (BL-110).

## Verdict: PASS (with notes)

The headline change shows and does what the contract says; every test this unit owns is green.
