# report-W7-SIM-EFFECTS — every named mistake has its consequence, healers generate threat, the tank can lose aggro, the seams are threaded; the wave's one regeneration

Contract: `build/plan/ship/00-plan.md` §2 "W7-SIM-EFFECTS". Findings: SIM-07, SIM-15, SIM-09, SIM-17 + Q-57, SIM-20 (Q58-4), SIM-22, CONTENT-12's BUILD branch (BL-116 — nothing lands here), m5-token-effects-and-cascade's effects half, m6-ambient-effects, M5-COMEDY-09's NINJAPULL half. SPACES everywhere in this unit.

Order inside the unit is the build notes': the effects and threat rules first, the quirk threading last (asserted golden-neutral in isolation before the regeneration), then ONE `write_goldens.gd` run and the drift numbers below.

## Acceptance

- [x] `handoff-W7-SIM-EFFECTS.md` written first: §1 `GameState` turns `deltas_queued[*].loot_call` into the morale event and surfaces `result.consumables_unspent`; §2 the NINJAPULL BL row note and the Q-57/Q-58 "implemented" markers (docs/15)
  - nine edits, `apply_handoff.py --dry-run` parses all nine: Morale.gd's `loot_call` trigger row (−3, ONCE_SESSION — docs/05 §7.3's passed-over figure, no doc prices a loot call), GameState's `_apply_raid_morale` loop over `loot_call` and `spend_loadout(potions_spent, unspent)` returning a forgotten Steady Hands, RaidPrep's one-line call, Results' "Provisions forgotten N" cell, Q-57/Q-58 status markers, BL-116's `opts` note, and one new BL row for every number this unit took.
- [x] `test_raid_sim.gd`: one test per healer outcome (HEAL_WRONG → highest-HP valid target with the wasted amount; HEAL_CORPSE → a 0 heal on the corpse; CHAIN_FIZZLE → hop 1 on `_neediest`, hops 2-3 on full-HP targets), the healer context sees `enemies`
  - four tests at `test_raid_sim.gd:1589/1613/1633/1658`; `_cast_mistaken_heal` is the one site, `_land_heal` the one landing. Verified at the resume: `RUN_TESTS_ONLY=test_raid_sim` green.
  - `_phase_healers` now passes `enemies` into `_context`, so `adds_present`/`boss_low` are real there for the first time; the healer mistake no longer `continue`s past `_apply_mistake`.
- [x] `test_raid_sim.gd`: one test per ambient consequence (AFK 1/2/3 rounds by severity, tank/healer bump, Aggro if tank; LOOT_CALL skips the next action and queues `loot_call`; ARGUMENT names a second raider on channel `argument` and both carry +500 bp for the encounter; NO_CONSUMABLE strips the provision and reports `result.consumables_unspent`)
  - five tests at `:1690/1721/1756/1793/1830`. `AFK_ROUNDS_BY_SEVERITY = [1,2,3,3]` indexed by `Enums.Severity` (MINOR..CRITICAL), `ARGUMENT_PENALTY_BP = 500` SET not stacked, `consumables_unspent` rides `mstate` out to `SimResult`.
  - audited the diff at the resume: `Combatant.can_act` reads `afk_until` beside `silenced_until`, and all five new fields are in `to_dict`/`from_dict`, so a resumed encounter cannot bring an AFK raider back early.
- [x] `::test_a_clerics_threat_rises_with_healing` (SIM-09: `_cast_heal` returns the healed total → `add_threat(threat_from(cls, 0.0, healed))`)
  - `:1907`. Threat is paid inside `_land_heal` per landed heal, so the chain and the raid heal pay per target and a wasted cast pays nothing.
- [x] `::test_the_shamans_hops_skip_full_targets` (Q-58: `_neediest(skip_above := 0.95)` for hops 2-3; a hop with nowhere to go is logged as such)
  - `:1936`. `CHAIN_SKIP_ABOVE = 0.95`; hop 1 unfiltered; a dead hop emits `chain_nowhere` at NUMBERS.
- [x] `::test_the_boss_switches_only_past_the_hysteresis` (SIM-17: `Formulas.should_retarget` in `_pick_enemy_target`, 1.10 melee / 1.30 ranged; MIS_AGGRO sets threat past the offender's own threshold)
  - `:1986`. `Enemy.target_slot` is the memory the hysteresis needed; `Formulas.aggro_pull_threat` puts the pull past the offender's OWN bar (a Wizard at a flat 1.10 would not have pulled).
- [x] `::test_a_tanks_action_mistake_drops_aggro_for_one_round` (Q-57: the active tank's MIS_TAUNT_LAPSE zeroes its threat for the next Phase 1; swing 1 retargets to the second-highest, swing 2 resolves on the tank)
  - `:2036`. `Combatant.lost_aggro_round`; only bites when the enemy's remembered target IS the lapsed tank, and the memory does not move for it.
- [x] `::test_taunt_restores_the_lead` (SIM-17: Tank Lead = 1.30 × highest non-tank; the active tank's Phase 2 action is a Taunt to 1.10 × highest when the lead is lost, cooldown 2)
  - `:2080`, plus `test_formulas.gd::test_tank_lead_taunt_and_the_pull_are_the_docs_numbers`. `taunt_threat` is the first integer STRICTLY above 1.10 × top, because `should_retarget`'s comparison is `>`.
- [x] `::test_a_tier_three_fight_mitigates_less_at_the_same_ac` (SIM-22: `encounter.tier` through `_apply_damage`/`_outgoing_damage`)
  - `:2126`. The tier rides on the gear profile (`_gear_profile(..., tier)`), which is the one dictionary both damage sites already read.
- [x] `test_legendaries.gd`: the four `Quirks` hooks are called at their sites behind the flag with identity semantics; the golden SHA of `e5_legendaries_raid` is unchanged by the threading at either flag setting (asserted in isolation BEFORE the regeneration)
  - `:311` (identity at either flag for all nine ids + "" + an unknown id) and `:328` (the scenario replays to the committed SHA at either setting, and the nine authored characters produce the same log at either setting).
  - ISOLATION, verified before the regeneration: every call site is algebraically neutral — `threat * 1.0`, `relief_bp + 0.0`, `tank_priority` 0 for all so `_assign_tanks` still takes the first Warrior in slot order, `immune_to` false so `eligible_types` filters nothing. The `:328` SHA half is red until the regeneration lands (the EFFECTS moved that golden, not the threading); it is asserted green after it, below.
- [x] `test_mistake_lines.gd` green with NINJAPULL's budget row intact (no edit to that file; no `NINJAPULL_REACHABLE`; the type never flagged unreachable)
  - not touched, green in the run; `grep -n NINJAPULL sim/ tests/` shows no flag and no skip — BL-116 leaves the break roll to W8-CRISIS.
- [ ] MIS_WRONG_TARGET's row (docs/07 §5.2 row 11, named in the contract's SIM-15 finding): the swing lands on a living add if there is one
  - written at the resume: `_swing_into_the_wrong_target` + `::test_a_wrong_target_swing_lands_on_the_add`. The one row of SIM-15's Fix the previous agent had not reached; ticked when the run below is green.
- [ ] ONE `tools/write_goldens.gd` run; goldens byte-identical afterwards (`test_golden.gd` green); the story diff read
- [ ] drift before/after at 200 seeds printed here; re-baselined only if a cell moved past 5pp, with the numbers
- [ ] `verify.sh --fast` green; `lint_motion.sh` clean; `parse_check.gd` clean

## Judgement calls

Every number docs/07 §5.2 left to the sim is in the handoff's BL row, which is where the
designer reads them. The calls behind them:

1. **MIS_AGGRO goes past the offender's OWN retarget bar, not a flat 1.10.** SIM-17's fix
   text said `1.10 × top`; `should_retarget` uses 1.30 for a ranged candidate, so a Wizard's
   pull at 1.10 would have printed "Wizard10 pulls aggro" and left the boss on the tank —
   the opposite of the joke. `Formulas.aggro_pull_threat(top, is_melee)` is the hysteresis's
   own threshold, so the pull always lands. docs/07 §8.2's wording ("regardless of
   accumulated threat") is what decided it.
2. **`taunt_threat` is the first integer STRICTLY above 1.10 × highest, not `ceil`.**
   `1.1 * 100.0` is `110.00000000000001` in a double, and `should_retarget` compares with
   `>`; a taunt that landed exactly on the bar would leave the boss where it was, which is
   the one outcome a taunt exists to rule out.
3. **MIS_TAUNT_LAPSE is a flag on the round, not a threat reset.** Q-57 rules "swing 1 only
   retargets; swing 2 resolves on the Warrior". Zeroing the threat would have sent both
   swings elsewhere and left the tank behind for every following round too;
   `Combatant.lost_aggro_round` expires by itself and only bites the enemy whose remembered
   target IS the lapsed tank.
4. **MIS_NO_CONSUMABLE gained a `consumable_carried` requirement.** "Forgot Their
   Consumable" on a raider who was handed nothing is the same lie SIM-14 took out of
   MIS_FIRE. That made `requires` a list as well as a string (`Context.requires_met`), which
   is the smallest change that lets a row carry two gates.
5. **The encounter-start roll is now MIS_NO_CONSUMABLE's alone.** docs/07 §5.3(c) calls it a
   "special one-shot"; every other AMBIENT type with no `requires` used to be reachable
   there, and with consequences attached an AFK or an argument that begins BEFORE the pull
   is an absence the round structure never names (round 0 has no next action to skip). The
   gate is `ctx.encounter_start` → only types that name `encounter_start`.
6. **The argument penalty is SET, not stacked.** docs/08's `SITUATIONAL_CAP_BP` caps the
   sum, so a stacking penalty would simply sit on the cap by round eight of a miserable
   raid and stop meaning anything. 500 bp is the same order as the existing Distraction
   (500) and Aggro-on-a-DPS (800) terms.
7. **A wasted heal is a NUMBERS-tier HEAL entry carrying `wasted`, not a silent nothing.**
   The report has to be able to add up what the three healer mistakes cost; an ordinary
   Druid top-up on a full raider still logs nothing, as it always did.
8. **MIS_WRONG_TARGET took no number.** docs/07 §5.2 row 11 wants the damage to go
   somewhere non-priority; the raider's own `_outgoing_damage` is what lands, on the first
   living add. With no add in the room the swing is gone — exactly the old behaviour — and
   SIM-08's full priority table stays wave 8's.
9. **Q-58's 95% line applies to hops 2-3 only.** "Hop 1 is the neediest, whoever that is" —
   a chain whose first hop skipped a 96%-HP raid would do nothing at all in a healthy raid,
   and the ruling is about the chain not WASTING hops, not about refusing to cast.
10. **The tier travels on the gear profile.** `_gear_profile` is the one dictionary both
    `_apply_damage` and `_outgoing_damage` already read, so SIM-22 needed no new parameter
    on either. Tier 1 is byte-identical (asserted in `::test_a_tier_three_fight_...`).

## Audit closures

- **`m6-ambient-effects`** — CLOSED. All four types now have the consequence the entry asks
  for, each through the existing `_apply_mistake` seam: AFK is `Combatant.afk_until` (1/2/3
  rounds by severity, read by `can_act`), LOOT_CALL is `skip_next_action` + the `loot_call`
  count on `deltas_queued`, ARGUMENT names a second living raider on the seeded `argument`
  channel and sets `argument_penalty_bp` 500 on both for the rest of the encounter,
  NO_CONSUMABLE strips the raider's `power_bonus`/`mana_bonus`/`relief_bp` back out of the
  profile and reports each as `result.consumables_unspent`. One docs/15 BL row is drafted in
  `build/plan/handoff-W7-SIM-EFFECTS.md` §2 (edit 9). Held by
  `tests/unit/test_raid_sim.gd::test_afk_takes_the_raider_out_for_one_to_three_rounds`,
  `::test_a_tank_or_healer_going_afk_is_severe_and_the_tank_drops_aggro`,
  `::test_a_loot_call_skips_the_next_action_and_is_queued`,
  `::test_an_argument_names_a_second_raider_and_taxes_both`,
  `::test_a_forgotten_consumable_is_stripped_and_reported` — each asserts the consequence,
  not only the line. Goldens regenerated once for the wave.
- **`Q58-4`** — CLOSED. (a) all four hooks are now CALLED from production: `threat_multiplier`
  through `RaidSim._threat_mult()` on every `Formulas.threat_from` result (the swing's in
  `_take_action`, the heal's in `_land_heal`), `relief_bp_bonus` folded into `_relief_bp()`,
  `tank_priority` in `_assign_tanks()`, `immune_to` in `Mistakes.eligible_types()` through
  `Context.quirk_id`. (b) is met by a DIFFERENT route than the entry proposed and the
  difference is deliberate: the quirk id is resolved from `Raider.legendary_def_id` by
  `Quirks.expected_id_for(class_id)` — the convention `LegendaryPool._validate_quirk` already
  enforces on every authored file — so no `LegendaryPool` travels through `ContentDB` and
  `sim/` stays a pure function of its arguments without a ContentDB change this unit does not
  own; the flag reaches `run()` as `opts["legendary_quirks"]`, which is the same dictionary
  W7-SAVE's replay and W8-SIM-BALANCE's `difficulty_mult`/`ninja_pulled` use. (c) the
  acceptance test is `tests/unit/test_legendaries.gd` rather than a new `test_quirks.gd`
  (that file is not in this unit's ownership list, and `test_legendaries.gd` is):
  `::test_the_nine_quirk_ids_are_distinct_and_conventional`,
  `::test_every_hook_is_identity_for_every_quirk_at_either_flag_setting`,
  `::test_the_threaded_seam_leaves_the_legendary_golden_where_it_was` (the golden SHA at both
  flag settings, plus the nine-authored-characters run identical at both). The two
  docstrings the entry calls false (`Quirks.gd:21-22`) are rewritten to say the hooks ARE
  called and where.
- **`M5-T25-15`** — the SIM HALF only; the entry stays open for W9-TIERS. Done here:
  `encounter.tier` rides on the gear profile and reaches `Formulas.damage_after_ac` in
  `_apply_damage` and `Formulas.spell_damage_total` in `_outgoing_damage`, so BL-72's `AC_K`
  step and `MANA_TO_SPELL` decay apply in a fight for the first time
  (`::test_a_tier_three_fight_mitigates_less_at_the_same_ac`; Tier 1 asserted byte-identical
  in the same test). NOT done here, by the plan's own split: `TierScaling.boss_auto_raw /
  unhealed_clock / aoe_pulse_gross`, `gen_items.gd`'s budget rows, docs/08 §9.6 and
  `test_tier_budget.gd` — W9-TIERS owns those files.
- **`m5-token-effects-and-cascade`** — the EFFECTS half; (1) closed by W6-SIM-CASCADE, (2)
  closed (`_situational_bp` already took the roller and the raid; this unit added the
  argument term inside the same `SITUATIONAL_CAP_BP` clamp), (3) the Adds amplifier —
  scaling mechanic checks per round with living adds — is NOT built and is not in this
  unit's contract. The entry should stay open on (3) alone.
- **`M5-COMEDY-09`** — NOT closed here, and nothing was done to it, which is the contract:
  BL-116 rules MIS_NINJAPULL BUILT, so this unit writes no `NINJAPULL_REACHABLE`, flags no
  type unreachable and does not edit `test_mistake_lines.gd`. The break roll is W8-CRISIS's
  and `run()`'s `ninja_pulled` branch is W8-SIM-BALANCE's; the eight lines stay (W9-REVIEW).

## Left
