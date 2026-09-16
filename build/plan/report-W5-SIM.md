# Report — W5-SIM (the tutorial mistake rate, the scripted round-3 mistake, and the two five-line mechanic arms)

Wave 5 follow-up, driven by five audit rows. Owned files: `sim/core/Mistakes.gd`, `sim/core/RaidSim.gd`,
`sim/model/Encounter.gd` (untouched — the field already exists), `tests/unit/test_mistakes.gd`,
`tests/unit/test_mechanics_arms.gd` (new), `tests/unit/test_tutorials.gd`, `build/plan/q-W5-SIM.md`.

## What the tree already had (read before the audit, per LESSONS)

Three of the five rows were STALE against the tree at the wave's start:

- `m5-m11-frontal-cleave` — `RaidSim._fire_frontal_cleave` (RaidSim.gd ~1004) exists, dispatched from
  `_apply_scheduled_mechanics`'s `FRONTAL_CLEAVE` arm (~823), behind `FRONTAL_CLEAVE_INCLUDES_TANK := true`
  (~114); pinned by `test_raid_sim.gd::test_m11_hits_the_melee_and_only_the_melee` (:1172).
- `m5-m12-escalating-swing` — `_tick_escalating_swing` (~1033), dispatched at ~826, announced every
  `ESCALATION_ANNOUNCE_EVERY := 5` rounds; pinned by `test_m12_adds_exactly_its_increment_every_round`
  (:1199) and `test_m12_still_terminates_inside_the_round_cap` (:1220). The ENRAGE sibling defect the row
  names (adds spawned after the enrage) is also fixed: `mstate["swing_mult_pct"]` + `_spawn_swing`,
  pinned by `test_an_add_spawned_after_the_enrage_swings_enraged` (:1228).
- `m5-mechanic-dispatch-guard` — `test_every_mechanic_in_the_vocabulary_is_dispatched_or_named_as_a_gap`
  (:437) with `MECHANICS_WITH_NO_BEHAVIOUR := []` (the allow-list, empty: all twelve have arms) plus a
  DEBUG-tier `_note_gap` default arm (~836) for a thirteenth.

So this unit adds the **static** guard the contract asks for in `test_mechanics_arms.gd` (source-level:
every `Enums.Mechanic` key has a literal dispatch arm, with an explicit allow-list that is empty today)
and effect-in-the-log tests for M11/M12 that read the log rather than the combatants, and spends its
real effort on the two rows that ARE open: `M5-TUT-11` and `M5-TUT-12`.

## Acceptance

- [x] M5-TUT-11: `Mistakes.Context.tutorial`, set from `Reputation.is_tutorial_slot(String(encounter.slot))`
      in `RaidSim._context()` (and the two sites that build a Context by hand: ambient, encounter start)
- [x] M5-TUT-11: `eligible_types()` drops `MIS_FACEPULL` and `MIS_NINJAPULL` when `ctx.tutorial`
- [x] M5-TUT-11: `const TUTORIAL_MISTAKE_MULT := 0.5` applied to `p_bp` in `roll()`; tests in
      `test_mistakes.gd` (never the two types for any class; tutorial p_bp exactly half)
- [x] M5-TUT-12: `force_mistake_round` read by the sim — on that round one raider, picked from the seeded
      Rng, makes a Minor mistake regardless of the roll; the halving cannot suppress it
- [x] M5-TUT-12: 20-seed A0 test in `test_tutorials.gd` (a mistake event at round 3, `mistake_count >= 1`);
      the existing pins (A0 >= 18/20, TR 0/20) unchanged
- [x] `test_mechanics_arms.gd` (new): static dispatch guard with allow-list; M11/M12 effects asserted in
      the event log; an encounter without the mechanic emits none of it
- [x] goldens unchanged (no golden encounter is a tutorial; the flag defaults false) — `test_golden.gd` green
- [x] `tools/balance_sweep.gd -- --drift` result pasted
- [x] `q-W5-SIM.md`: the 0.5, the raider pick, the Minor floor, the cleave front predicate as 🔷 PROPOSED
- [x] `verify.sh --fast` — 2010/2011, the one red is another unit's file (see Left); `lint_motion.sh` clean

## Log

- 12:xx — `Mistakes.gd`: `TUTORIAL_MISTAKE_MULT := 0.5`, `TUTORIAL_DISABLED_TYPES`, `Context.tutorial`, the
  ban in `eligible_types`, a `chance_bp()` accessor that `roll()` now reads (so the halving is assertable
  exactly), and `force()` — the scripted mistake's taxonomy half (no gate; gentle-first weighted draw;
  Minor at the type's floor). `RaidSim.gd`: `const Reputation` preload, `_is_tutorial(encounter)`,
  `mstate["tutorial"]` for the two hand-built Contexts (ambient, encounter start), `ctx.tutorial` in
  `_context`, `round_state["forced_slot"]`, `_pick_forced_mistake_slot` (own Rng channel
  `forced_mistake`, non-tank tank/DPS-phase actors, tank as fallback) and the `Mistakes.force` branch in
  `_take_action`. Parse check OK (180 scripts).
- Tests: `test_mistakes.gd` +8 (bans for every class/role/site with the flags armed; the inverse; exact
  halving at 60 rarity/morale/site cells; observed rate ratio 0.38-0.62 over 6000 rolls; forced fires at
  a 95-morale Legendary in a tutorial context 40/40; Minor-at-floor; deterministic and shaped like `roll`;
  cooldown narrows but never empties). `test_tutorials.gd` +4 (20 seeds A0: round-3 MISTAKE and
  `mistake_count >= 1` every seed; one raider, Minor, replay-identical; TR and real rungs never script;
  the flag reaches the Context for A0/TR and not A1/E1/E5). `test_mechanics_arms.gd` new, 8 tests.
  First run: 71/72 — **the Tutorial Raid pin moved from 0/20 to 1/20**, see "The pin that moved" below.
  Second run: `TESTS PASSED 72 test(s) in 3 file(s) [1302 ms]`.

## The pin that moved (canon question — recorded, not retuned)

`test_the_tutorial_raid_is_currently_unwinnable_and_that_is_recorded` pinned 0/20 with the squad the game
hands you. That was measured at the FULL mistake rate. With docs/15 Q-51's reduced rate in the sim at 0.5,
one of the twenty seeds clears (1/20). Only the halving can have moved it — the two banned types are
unreachable on TR anyway (`MIS_FACEPULL` needs `trash_phase`, TR is `main_boss`; `MIS_NINJAPULL` needs
`break_phase`, which nothing in RaidSim sets). Nothing about TR's swing, HP or M01 changed; 1/20 is not
"winnable and losable" (>= 8 is what the pin's own text calls the fix), so the defect the pin records is
unchanged. I did NOT touch 0.5 to restore 0/20 (that would be tuning a canon-driven number to a pin) and
did NOT leave the suite red (LESSONS: a gate red for a reason no loop may fix stops all work). The pin now
carries `TUTORIAL_RAID_CLEARS_AS_MEASURED := 1` with the full history in its comment plus `cleared < 8`,
and the movement is written up as a 🔷 PROPOSED canon question in `q-W5-SIM.md` (the designer may want the
tutorial rate and the Tutorial Raid's swing ruled together). A0's pin (>= 18/20) is unchanged and green.

- Goldens + neighbours: `RUN_TESTS_ONLY=test_golden,test_event_log,test_raid_sim,test_encounters,test_adventures,test_tier_rules`
  -> `TESTS PASSED 155 test(s) in 6 file(s) [8785 ms]`. No golden moved (none is a tutorial; `Context.tutorial`
  defaults false; the forced path is gated on `force_mistake_round == round_no`, which is 0 everywhere but A0),
  so no regeneration.
- Drift gate (`tools/balance_sweep.gd -- --drift`, through the lock, 4000 runs / 8 reference cells / 61.3 s):
  ```
  DRIFT VS COMMITTED BASELINE  (docs/14 §9.3: fail past 5pp)
    A1/starting/common/m55               34.2% ->   34.2%    +0.0pp
    A2/adventure/common/m55              99.8% ->   99.8%    +0.0pp
    A3/adventure/common/m55              98.2% ->   98.2%    +0.0pp
    E1/adventure/common/m55             100.0% ->  100.0%    +0.0pp
    E2/raid_entry/common/m55            100.0% ->  100.0%    +0.0pp
    E3/raid_entry/common/m55            100.0% ->  100.0%    +0.0pp
    E4/raid_entry/common/m55            100.0% ->  100.0%    +0.0pp
    E5/raid_entry/common/m55             75.4% ->   75.4%    +0.0pp
  SWEEP OK
  ```
  No `--rebaseline`; `tests/baselines/sweep_baseline.csv` untouched.
- `q-W5-SIM.md` written: the 0.5 (implemented), the TR pin's move (canon question, OPEN), the scripted
  mistake's three calls (gate skipped / Rng pick, non-tank, tank fallback / Minor at the floor), and M11's
  front predicate (MELEE_CLASSES, tank included, Bard by the shared predicate).
- `tools/lint_motion.sh`: MOTION LINT OK.
- First `verify.sh --fast`: 2001/2011 — ten `test_docs_links.gd` register-citation hits, nine of them mine:
  a `Q-51` citation is ambiguous with `BL-51` under that lint, and the fix it offers is an allow-list row in
  `test_docs_links.gd`, which I do not own. Followed the precedent already in `test_tutorials.gd`
  ("docs/15's tutorial-mistake-rate ruling") and cite the ruling by name and by `docs/07 OQ-9` instead, so no
  handoff is needed and the lint has no hole. Re-run of `test_docs_links,test_mistakes,test_mechanics_arms,
  test_tutorials`: my files clean.
- Final `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast`:
  ```
  PASS  class cache regenerated
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  PASS  PARSE_CHECK scanned 183 script(s)
  PASS  16 generated file(s) agree with tools/gen_items.gd
  PASS  ART CHECK  generators=7  runtime files: 204 agree  0 DIFFERS  0 MISSING
  FAIL  unit tests — TESTS FAILED 1/2011 failing [36916 ms]
        test_docs_links.gd :: test_every_register_citation_resolves_to_a_declared_entry
        res://tests/unit/test_game_state.gd:236 cites Q-59, and BL-59 also exists
  ```
  The single red is `tests/unit/test_game_state.gd:236`, a file another unit is editing this wave (110 lines
  of uncommitted changes, none mine; my files contribute zero hits). Every test in my six files and in the
  sim's neighbours is green; 2010/2011 overall.

## Audit closures

- **M5-TUT-11** — DONE. `Mistakes.Context.tutorial` (Mistakes.gd, Context), set in `RaidSim._context()` from
  `Reputation.is_tutorial_slot(String(encounter.slot))` via `_is_tutorial()` and, for the two hand-built
  Contexts (ambient, encounter start), from `mstate["tutorial"]` set once in `run()`; `eligible_types()` drops
  `TUTORIAL_DISABLED_TYPES` (`MIS_FACEPULL`, `MIS_NINJAPULL`) under the flag; `TUTORIAL_MISTAKE_MULT := 0.5`
  applied in `Mistakes.chance_bp()`, which `roll()` reads. The 0.5 is a proposed docs/15 entry in
  `build/plan/q-W5-SIM.md` (W5-DOCS owns docs/15). Held by `test_mistakes.gd` (4 tests: bans for every
  class/role/site, the inverse, exact half over 60 cells, observed ratio) and
  `test_tutorials.gd::test_both_tutorials_roll_at_the_reduced_rate_and_a_real_rung_does_not`. Risk clause met:
  the scripted mistake skips the gate, so the halving cannot suppress it
  (`test_a_forced_mistake_fires_with_no_gate_roll_at_all` runs it inside a tutorial context at a 95-morale
  Legendary, 40/40).
- **M5-TUT-12** — DONE (the sim half; the model half was already in). `RaidSim._run_round` sets
  `round_state["forced_slot"]` on `encounter.force_mistake_round` after the boss phase via
  `_pick_forced_mistake_slot` (own Rng channel; non-tank tank/DPS-phase actor; tank fallback); `_take_action`
  routes that slot through `Mistakes.force()` (no gate; gentle-first weighted type; Minor at the floor) and then
  the ordinary `_record`/`_log_mistake`/`_apply_mistake`. Held by `test_tutorials.gd` (20 seeds on A0: a MISTAKE
  entry on round 3 and `mistake_count >= 1` every seed; one raider, Minor, replay-identical; TR and the real
  rungs never script) and `test_mistakes.gd` (4 `force` tests). The docs/10 §6 field-table row is
  `handoff-W5-SIM.md` #1 (parses under `apply_handoff.py --dry-run`). Judgement calls in `q-W5-SIM.md`.
- **m5-m11-frontal-cleave** — ALREADY LANDED before this wave (mech-arms slice): `_fire_frontal_cleave`,
  `FRONTAL_CLEAVE_INCLUDES_TANK`, `test_raid_sim.gd::test_m11_hits_the_melee_and_only_the_melee`. This unit adds
  the second hold in `test_mechanics_arms.gd` (every living melee raider cleaved on round 1, one line per round,
  nobody outside `Consumables.MELEE_CLASSES`, no trace without it) and writes the front predicate down in
  `q-W5-SIM.md`. Close the row.
- **m5-m12-escalating-swing** — ALREADY LANDED before this wave: `_tick_escalating_swing`,
  `ESCALATION_ANNOUNCE_EVERY`, the ENRAGE sibling fix (`swing_mult_pct` + `_spawn_swing`), three tests in
  `test_raid_sim.gd`. This unit adds `test_mechanics_arms.gd`'s log-side hold (round 10 = round 1 + 9 x
  increment before AC, asserted from the boss's logged swings; cadence; termination inside ROUND_CAP; no trace
  without it). Close the row.
- **m5-mechanic-dispatch-guard** — ALREADY LANDED before this wave (`test_raid_sim.gd:437`, behavioural, with
  the empty `MECHANICS_WITH_NO_BEHAVIOUR` allow-list, and the DEBUG-tier `_note_gap` default arm). This unit adds
  the independent STATIC guard in `test_mechanics_arms.gd` (`_apply_scheduled_mechanics`' source must carry a
  literal `Enums.Mechanic.<NAME>` arm for every enum entry; `MECHANICS_WITHOUT_AN_ARM := []` is the explicit
  allow-list; the default arm and its template id must exist). The two guards fail in different ways, which is
  the point. Close the row.

## Left

- `tests/unit/test_game_state.gd:236` (`Q-59`) is the one red in `verify --fast` — not my file, not my
  citation; whichever unit owns `test_game_state.gd` this wave needs to cite by name or add the allow-list row.
- The docs/10 §6 `force_mistake_round` table row is a handoff (#1), not applied — docs/10 is not mine.
- The audit's suggested "trailing default arm at NUMBERS tier" for the dispatch guard was NOT added: the tree
  already carries one at DEBUG tier (`_note_gap`), and `test_a_development_note_never_reaches_a_player_tier`
  pins DEBUG on purpose (docs/07 §10.2).
- `test_mechanics_arms.gd` has no `.uid` sidecar yet (same as the wave's other new test files); the engine
  writes it on the orchestrator's full run.
- The TR pin: NOT retuned. `TUTORIAL_MISTAKE_MULT` stays 0.5, the pin follows the measurement (1/20, with its
  history and `cleared < 8`), and the coupling of the tutorial rate with TR's swing ruling is an OPEN canon
  question in `q-W5-SIM.md` for the designer — see "The pin that moved" above.
