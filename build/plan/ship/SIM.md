# SIM — ship report (simulation: docs/05-09 vs sim/)

_Reporter run 2026-09-15; READ-ONLY on the tree; wave 5 (W5-SIM) landing concurrently._

## Executive summary

1. **Shippable today:** the sim is pure, deterministic, terminating, and every one of the twelve boss mechanics M01-M12 has a dispatched arm with behavioural tests (SIM-01/30); the AC curve, mana model, melee/spell/heal, threat coefficients, variance and morale bands equal docs/08 and the Q-01..Q-07/Q-59 rulings (SIM-26); items, drops, payouts and repeat decay equal docs/09-11 (SIM-25); the tutorial rate and round-3 scripted mistake landed this wave (SIM-28). Ten of the audit's fourteen `m5-*` rows are stale — the arms exist (SIM-01/02/03).
2. **Not shippable:** the cascade that makes a wipe a story is unwired — `caused_by` is always empty, the depth cap never binds, Results has nothing to indent (SIM-05); token modifiers hit the wrong raider (SIM-06); healer mistakes and five ambient types have a name and no consequence (SIM-07/15); "Stood in the Fire" fires on fights with no fire (SIM-14).
3. **Biggest gap 1 — docs/06's class kits are absent and un-queued:** no Lost Aggro semantics (Q-57), no Wizard Ramp, no Rogue Behind/Front, no Monk Guard/emergency tank, no Mage buff or true AoE, no Bard songs (Q-46 DECIDED), no healer threat (Q-58 DECIDED); no audit row tracks any of it (SIM-08/09/10/17).
4. **Biggest gap 2 — Focus (Q-02 Model A+) was decided and never built,** so M10's drain and the three "resource spent" heal mistakes have nothing to spend; docs/08 has no Focus section to build from (SIM-04).
5. **Biggest gap 3 — the campaign is not completable and the drift gate is not armed:** M6-BAL-04's four levers are restated plainly in SIM-19 (recommended: Common baseline -5 → 0, plus A3 without M03); `verify.sh` runs the sweep without `--drift`, so nothing enforces the 5pp rule (SIM-18); attrition fires at an undocumented `enrage_round + 5` (SIM-12).
6. **Content defects on E4:** M05 has no authored effect on ANY encounter in the game, E4's M08 tiles the fight so the boss never returns to the tank, and its M09 covers rounds 1-3 only (SIM-13/27).
7. **Docs owe the tree:** docs/08 §8.8 still prints the rejected mistake-equation fork as "OPEN" while the sim runs Q-04/05's answer (SIM-11); twelve mechanic/tutorial judgement calls sit in `build/plan/q-*.md` with no docs/15 row (SIM-27); overkill and the RNG channel list are undocumented (SIM-23/24).
8. **Wave order:** 6 = the rule fixes that churn goldens once (SIM-05/06/07/09/14/15/24/29) + arm the drift gate (SIM-18) + the DOCS pass (SIM-11/23/27) + E2/E4 goldens (SIM-16); 7 = Focus (SIM-04), the six class kits (SIM-10/17), quirk threading (SIM-20); 8 = the balance wave — add targeting (SIM-08), attrition (SIM-12), E4 content (SIM-13), the M6-BAL-04 lever once ruled (SIM-19), one re-baseline; 9 = tiers 2-5 mount (SIM-16/22), wishlists (SIM-21); 10 = polish and the pins turned back into assertions.
9. **Blocked on the designer (12 questions, below):** the M6-BAL-04 lever, M01-on-one-tank/TR swing, Focus numbers, M05's effect, E4's fixate window, Bard magnitudes, Monk Guard AC, attrition grace, the target clear-rate curve, nine quirk specs, the Rogue dagger, upkeep/payday. Every one has a recommended default written in its finding.
10. **Findings:** 30 — 21 CONFIRMED defects, 3 CONFIRMED-matching verifications (SIM-25/26/30, included so the reviewer sees what was checked), 4 REFUTED (audit rows stale: SIM-01/02/03/28), 2 BLOCKED-designer (SIM-19/20). Sizes: 17 S, 7 M, 4 L (SIM-04 Focus, SIM-10 kits, SIM-20 quirk spec, SIM-21 wishlists), 0 XL; the rest are verifications.

## Findings

### SIM-01 — The twelve mechanics all have arms; nine audit rows say "absent" and are stale
**Status:** REFUTED (the audit rows), CONFIRMED (the arms exist)
**Evidence:** `sim/core/RaidSim.gd:814-850` `_apply_scheduled_mechanics` carries a literal arm per `Enums.Mechanic` entry: RAID_WIDE (`_fire_raid_wide` :856), ENRAGE (:875), ADD_SPAWNS (:891), FIXATE (`_tick_fixate` :913), HEALING_DEBUFF (:938), MANA_BURN (:985), FRONTAL_CLEAVE (:1020), ESCALATING_SWING (:1051), POSITIONING (`_open_positioning_window` :1071); TANK_SWAP / INTERRUPT_CHECK / GROUND_EFFECT resolve through Phase 0b/0c (`_phase_mechanic_checks` :750, `_resolve_demanded_mechanics` :1104, `_resolve_tank_swap` :1127, `_resolve_interrupt` :1208, `_resolve_positioning` :1269) and Phase 5 (`_phase_effects` :1648). The default arm `_note_gap` (:1329) fires only for a thirteenth entry. Static guard: `tests/unit/test_mechanics_arms.gd` (wave 5); behavioural guard `test_raid_sim.gd:437` with `MECHANICS_WITH_NO_BEHAVIOUR := []`.
**Doc:** docs/10 §10 (vocabulary), docs/07 §5.3(b) (the mechanic roll site).
**Fix:** Close the audit rows `m5-m01-tank-swap`, `m5-m03-ground-effect`, `m5-m05-interrupt-check`, `m5-m07-positioning`, `m5-m08-fixate`, `m5-m09-healing-debuff`, `m5-m11-frontal-cleave`, `m5-m12-escalating-swing`, `m5-mechanic-dispatch-guard`, `m5-mech-roll-site` as done (their `actual_status` still reads not-started/partial). `M5-T25-12` ("seven of twelve have no behaviour") likewise closes. Only the M10 drain half stays open (SIM-04).
**Owns:** `build/plan/audit.json` (status fields only).
**Size:** S
**Wave:** 6 — bookkeeping that unblocks the plan's reading of what is left.
**Audit:** m5-m01-tank-swap, m5-m03-ground-effect, m5-m05-interrupt-check, m5-m07-positioning, m5-m08-fixate, m5-m09-healing-debuff, m5-m11-frontal-cleave, m5-m12-escalating-swing, m5-mechanic-dispatch-guard, m5-mech-roll-site, M5-T25-12.

### SIM-02 — M02 raid-wide bypasses AC (single mitigation) — audit row done and true
**Status:** REFUTED (the defect); the row's `actual_status: done` is correct
**Evidence:** `RaidSim.gd:856-871` `_fire_raid_wide` reads `ignores_ac := bool(spec.params.get("ignores_ac", true))` and passes it to `_apply_damage(..., ignores_ac)`; comment names the double-mitigation bug and its fix. Data carries `ignores_ac` (`data/encounters_t1.json`).
**Doc:** docs/10 §10 M02 "ignores AC (❓ §5.4)"; docs/15 Q-01r.
**Fix:** none in sim. Close `m5-m02-raid-wide-ac`.
**Owns:** —
**Size:** S
**Wave:** 6 (bookkeeping)
**Audit:** m5-m02-raid-wide-ac.

### SIM-03 — M04 double-spawn: the mechanic owns the round; the authored block is suppressed
**Status:** REFUTED (the defect)
**Evidence:** `RaidSim.gd:481-499` `_spawn_scheduled` skips an authored `spawn_round` block when `_add_spawns_fires_on(encounter, round_no)` (:512) is true; one predicate shared by both paths. Adds spawned after ENRAGE inherit `mstate["swing_mult_pct"]` via `_spawn_swing` (:502).
**Doc:** docs/10 §10 M04, §6 one-mechanic-per-star.
**Fix:** none in sim; close `m5-m04-double-spawn` (still `partial`). Whether a test pins "E1 round 5 spawns exactly one add" is checked in SIM-13.
**Owns:** —
**Size:** S
**Wave:** 6
**Audit:** m5-m04-double-spawn.

### SIM-04 — Focus (Q-02 "Model A+") does not exist; M10's drain half and the three "resource still spent" heal mistakes have nothing to spend
**Status:** CONFIRMED
**Evidence:** `sim/core/Formulas.gd:195-197` declares `enum ManaModel { MAGNITUDE_PLUS_FOCUS, ... }` and `MANA_MODEL := MAGNITUDE_PLUS_FOCUS` with a docstring only; `grep -rn "focus" sim/` finds no field, no class-fixed value, no spend. `RaidSim.gd:124` `MANA_BURN_DRAIN_ENABLED := false` with the comment "no pool exists: no field, no class-fixed values, no spend"; `:985-1003` `_fire_mana_burn` only silences. `Combatant.gd` has no resource field. `Mistakes.TYPES` MIS_HEAL_WRONG/CORPSE/CHAIN_FIZZLE emit `Token.MANA` (`Mistakes.gd:100-115`) and `Enums.TOKEN_DURATION[MANA] = -1`, but nothing reads a MANA token anywhere (`grep Token.MANA sim/` hits only the emit rows and the enum).
**Doc:** docs/15 Q-02 (DECIDED: Mana magnitude + class-fixed Focus that never appears on gear); docs/07 §5.2 rows 6-8 "resource still spent"; docs/07 §6 Mana token "Healer's next heal is weaker or skipped, per doc 08's resource rules"; docs/10 §10 M10 "casters lose X Mana per round". docs/08 has NO Focus section (its §5 still argues Model A vs B) — the coefficient owner has not published `FOCUS_MAX[class]`, regen, or cost per cast. No docs/15 row gives the numbers; recommended default (this report): Focus pool per healer/caster class in `data/classes.json` (`focus_max`, `focus_per_cast`), regen 0 within an encounter, a wasted heal costs a full cast, an empty pool makes the healer cast `HEAL_FLOOR`; M10 drain = `X` Focus per round while live.
**Fix:** (1) docs/08 gains §5.4 "Focus" with the table (DOCS unit, blocked on the designer for the numbers — the build loop may propose them behind `Formulas.FOCUS_ENABLED := false`). (2) `sim/model/ClassDef.gd` reads `focus_max`/`focus_per_cast`; `Combatant.gd` gains `focus: int`; `RaidSim._cast_heal` and the caster branch of `_take_action` spend it; `_apply_mistake` handles `Token.MANA` (next heal x0.5 or skipped); `_fire_mana_burn` drains when `MANA_BURN_DRAIN_ENABLED`. (3) NUMBERS-tier log line "resource after" (docs/07 §10.1 `numbers.resource_after`). (4) Goldens regenerate only if `FOCUS_ENABLED` flips true; ship with the default the designer picks.
**Owns:** `sim/core/Formulas.gd`, `sim/model/ClassDef.gd`, `sim/model/Combatant.gd`, `sim/core/RaidSim.gd` (heal/cast/M10 arms), `data/classes.json`, `tests/unit/test_formulas.gd`, `tests/unit/test_raid_sim.gd`, docs/08 §5 (handoff).
**Size:** L
**Wave:** 7 — needs the docs/08 numbers first (wave 6 DOCS pass) and it moves goldens; land before the wave-8 balance re-baseline.
**Audit:** DW-C1, DW-C2 (doc half), m5-m10-mana-burn (drain half), M5-T25-12.

### SIM-05 — Cascade attribution is never performed: `caused_by` is always empty and `cascade_depth` is always 0
**Status:** CONFIRMED
**Evidence:** `Mistakes.attribute(ev, parent)` exists (`sim/core/Mistakes.gd:452-458`) and is called from nowhere in `sim/` (`grep -rn "attribute(" sim/` = the definition only). `RaidSim._apply_mistake` (`RaidSim.gd:1803-1809`) stores the source event on the token (`actor.add_token(token, round_no, ev)`, `Combatant.token_sources`) and its own comment says "`caused_by` is still always empty; that gap is written up in build/plan/handoff-mech-arms.md". Consequence: `MAX_CASCADE_DEPTH` (`Mistakes.gd:33`) never binds because `ev.cascade_depth` is 0 at `roll()` (`:398`), and the post-mortem cannot render "this wipe started when Greg pulled aggro in round 4" (docs/07 §5.1, §6). `game/screens/Results.gd:1134-1249` already renders a cascaded mistake as an indented row by `cascade_depth` and resolves `caused_by` to a name — and has never had anything to indent, because the sim never sets either field. Sheet: `build/shots/all/raid-advanced/RaidView_all.png` shows 25 mistakes by round 11 of a miserable-Commons E5 and a flat list of them.
**Doc:** docs/07 §6 rules 1-2 ("a mistake caused by a live token records caused_by = that token's source event; depth cap 3"). docs/15: no row; the rule is unambiguous — no designer input needed. One ambiguity: which token is the parent when several are live — recommended default: the live token whose "Effect on later rolls" column names this roll (Aggro→a healer's roll, Fire/Adds→AVOIDABLE_DEATH, Distraction→an ambient roll), else the oldest live token on the actor.
**Fix:** In the four roll sites (`_phase_mechanic_checks`, `_take_action`, `_phase_healers`, `_phase_ambient`) after a non-null `ev`: find the enabling token's source (`Combatant.token_source(token)`, on the actor or raid-wide per SIM-06) and call `Mistakes.attribute(ev, parent)` BEFORE `_record`/`_log_mistake` so the log entry carries the edge. `EventLog.emit_mistake` already takes `caused_by, cascade_depth`. Add `test_raid_sim.gd::test_a_mistake_under_a_live_token_names_its_parent` and a golden expectation (e5_miserable_commons has MechanicDrop/Aggro chains — BL-80's measurement). Goldens WILL move (the `caused_by` field is in `to_dict`), so regenerate and state before/after in the commit.
**Owns:** `sim/core/RaidSim.gd`, `sim/core/Mistakes.gd`, `tests/unit/test_raid_sim.gd`, `tests/golden/*.json` (regenerate).
**Size:** M
**Wave:** 6 — it is a rule with no open question, it is what makes the wipe report a story, and the golden churn is best paid early, before the wave-7 Focus change and the wave-8 balance pass.
**Audit:** m5-token-effects-and-cascade.

### SIM-06 — Token modifiers land on the wrong raider: Aggro should raise the HEALERS' chance and Distraction should be RAID-WIDE; the sim raises only the offender's
**Status:** CONFIRMED
**Evidence:** `RaidSim._situational_bp(c)` (`RaidSim.gd:1935-1942`) adds +800bp if `c.has_token(AGGRO)` and +500bp if `c.has_token(DISTRACTION)` — tokens are stored on the ACTOR that emitted them (`_apply_mistake` :1803-1809 `actor.add_token`). So Greg's Aggro token makes Greg 8pp clumsier for two rounds and does nothing to Cindy; Steve's argument makes Steve 5pp clumsier and nobody else. docs/07 §5.2 row 16 also says MIS_ARGUMENT penalises "this raider and one random other for the rest of the encounter" — no second raider is chosen and the token expires after 2 rounds (`Enums.gd:328`).
**Doc:** docs/07 §6 table: Aggro "Healers' mistake chance +8pp"; Distraction "+5pp ambient mistake chance, raid-wide"; §5.2 row 16. docs/15: no row; unambiguous.
**Fix:** Give `_situational_bp` the raid: `_situational_bp(c, combatants, site)`: +800 if ANY living combatant holds AGGRO and `c` is a HEALER; +500 at the AMBIENT site if any living combatant holds DISTRACTION; keep the per-actor Fire/Adds gating for MIS_AVOIDABLE_DEATH as is. For MIS_ARGUMENT pick "one random other" on a derived channel `argument` and give both a per-encounter `argument_penalty_bp` meta (rest of encounter). Pin with three tests (a healer's chance rises when a DPS holds Aggro; a non-healer's does not; ambient chance rises raid-wide under Distraction). Goldens move; regenerate.
**Owns:** `sim/core/RaidSim.gd`, `tests/unit/test_raid_sim.gd`, `tests/golden/*.json`.
**Size:** S
**Wave:** 6 — same commit as SIM-05 (both touch the roll sites and both churn goldens once).
**Audit:** m5-token-effects-and-cascade.

### SIM-07 — Healer mistakes never reach `_apply_mistake`, and their effects are "skip the heal" rather than docs/07's three distinct outcomes
**Status:** CONFIRMED
**Evidence:** `RaidSim._phase_healers` (`RaidSim.gd:1554-1575`): on a rolled mistake it calls `_record` and `_log_mistake` then `continue      # the heal is lost; that IS the mistake` — no `_apply_mistake`, so MIS_HEAL_WRONG/CORPSE/CHAIN_FIZZLE emit no token at all (their `emits: [MANA]` never lands), and the three types are mechanically identical (heal skipped). docs/07 §5.2: HEAL_WRONG "lands on the highest-HP valid target" (docs/06 §4.2: "a random raider at full HP"); HEAL_CORPSE "targets a Dead raider"; CHAIN_FIZZLE "only the first hop does work" (docs/06 §4.4 Bad Bounce: "starts on a random raider; the one who needed it gets at best the small third hop"). Also `_context(...)` for healers is built with `enemies = []` (:1562) so `adds_present`/`boss_low` are always false for healer rolls.
**Doc:** docs/07 §5.2 rows 6-8; docs/06 §4.2/§4.4. docs/15: no row; the doc text is specific enough.
**Fix:** In `_phase_healers`, on `ev != null`: call `_apply_mistake` (tokens), then a per-type branch: HEAL_WRONG → cast onto the highest-HP valid target (log the heal with the wasted amount, NUMBERS tier); HEAL_CORPSE → emit a HEAL line to the corpse for 0 ("entirely wasted"); CHAIN_FIZZLE → bounce 1 lands on `_neediest`, bounces 2-3 on full-HP targets. Pass `enemies` to the healer context. Pin each with a test. Goldens move.
**Owns:** `sim/core/RaidSim.gd`, `tests/unit/test_raid_sim.gd`, `tests/golden/*.json`.
**Size:** M
**Wave:** 6 — with SIM-05/06 (one golden regeneration for the three).
**Audit:** m5-token-effects-and-cascade (relates); no dedicated row — add one.

### SIM-08 — Adds are never focused: raider targeting is first-alive-in-array-order, and the Mage's AoE lands on one target
**Status:** CONFIRMED (audit row `m5-add-target-priority` still true)
**Evidence:** `RaidSim._pick_enemy(enemies)` (`RaidSim.gd:1944-1948`) returns the first `active and is_alive()` enemy; M04 adds are `enemies.append`-ed (`:891-909`) and Loose Adds likewise (`:1830-1839`), so every DPS hits the boss until it dies while adds hunt the lowest-HP raider each round. The Mage's AoE (`_outgoing_damage` :1538-1546 `spell_damage_total(... targets = living_enemies)`) computes N-target damage but `_take_action` applies the whole total to ONE target (`:1502-1504`), so the canon "AoE Caster" is a single-target caster with a multiplier. docs/10 §7.2's card promises "adds that hunt the weakest raider" as healer pressure the raid must answer; docs/06 §4.7 rule 2 "the Mage deals spell damage to every living enemy"; docs/06 §4.8 rule 1 "the Wizard deals spell damage to the boss".
**Doc:** docs/06 §4.7/§4.8, docs/10 §7 split rule 2, docs/07 §5.2 row 11 (WRONG_TARGET needs a priority target to be wrong about). docs/15: no row. Recommended default: melee and Wizard focus the boss (the Wizard ramp is boss-locked); the Mage splits its per-target damage across every living enemy; adds die to the Mage's AoE, and to melee only when no boss is alive — this keeps docs/08 §9's boss-channel budget intact because only the Mage's overflow leaves the boss.
**Fix:** `_take_action`: for MAGE iterate living enemies applying `spell_damage(...)` per target (one ATTACK line per target at NUMBERS, one summary at PLAY_BY_PLAY); for everyone else `_pick_enemy` prefers a non-add. Sweep before/after in the commit (E2/E3 clears will move a few points; `--drift` must stay under 5pp or be re-baselined with the number stated).
**Owns:** `sim/core/RaidSim.gd`, `tests/unit/test_raid_sim.gd`, `tests/golden/*.json`, `tests/baselines/sweep_baseline.csv` (if re-baselined).
**Size:** M
**Wave:** 8 — a balance-moving change; land it inside the balance wave with the sweep in hand, after the wave-6 rule fixes have settled the goldens.
**Audit:** m5-add-target-priority.

### SIM-09 — Healers generate no threat (Q-58 DECIDED "yes at a low multiplier") and the chain heal does not skip >95% HP targets
**Status:** CONFIRMED
**Evidence:** `Formulas.threat_from(char_class, pre_mitigation_damage, healing_done)` (`Formulas.gd:417-421`) supports `HEAL_THREAT_COEF 0.50`, but `RaidSim._cast_heal` (`:1577-1616`) never calls `add_threat`; only `_take_action` (:1503) does, and healers never reach it. `_neediest` (`:1627-1637`) picks lowest `hp_fraction` with an exclude set — never repeats (correct) but does not skip a 96%-HP target (a bounce lands for 4% of its value instead of moving on).
**Doc:** docs/15 Q-58 (DECIDED: healer threat yes at a low multiplier; chain never repeats and skips anyone above 95% HP); docs/08 §8.7 `HEAL_THREAT_COEF = 0.50`; docs/07 §8.1 "healing 0.5".
**Fix:** `_cast_heal` returns the healed total; caller `c.add_threat(round(Formulas.threat_from(cls, 0.0, healed)))`; `_neediest` takes `skip_above := 0.95` for the Shaman's hops 2-3 (hop 1 unfiltered). Tests: a Cleric's threat rises with healing; a fully-healed raid gives the Shaman two hops that go nowhere and are logged as such. Goldens move (threat numbers on HEAL entries; boss targeting in rare cases).
**Owns:** `sim/core/RaidSim.gd`, `tests/unit/test_raid_sim.gd`, `tests/golden/*.json`.
**Size:** S
**Wave:** 6 — with the other rule fixes; pure rule, decided, cheap.
**Audit:** none (the audit's `Q58-*` rows are about Legendary QUIRKS — a different numbering; see SIM-20). Add a row.

### SIM-10 — docs/06 §4's class kits are not in the sim: no Threat Lock/Lost Aggro semantics, no Rogue Behind/Front, no Monk Stance/emergency tank, no Mage Raid Spell Buff, no Wizard Ramp, no Bard songs (Q-46 DECIDED) — and no audit row tracks any of it
**Status:** CONFIRMED
**Evidence:** `grep -rn -i "positional_mult\|ramp\|song\|guard\|spell_buff\|emergency" sim/` finds only `Formulas.melee_swing(..., positional_mult := 1.0)` (`Formulas.gd:259-262`, never passed anything but the default from `RaidSim._outgoing_damage` :1538-1546) and comments. `_assign_tanks` (`RaidSim.gd:348-380`) seats a Monk as MAIN tank only when no Warrior was brought, at setup; nothing swaps a Monk to Guard when the Warrior goes Downed/Dead (docs/07 §8.3, docs/06 §4.6 rule 2). The Wizard has no stack counter; the Mage has no raid buff; the Bard acts in the DPS phase with `CLASS_MELEE_COEF[BARD] 0.55` and no song roll (`_action_order` :1459, `_outgoing_damage` :1538). Warrior *Lost Aggro* is not a type: MIS_TAUNT_LAPSE does `pass` (`_apply_mistake` :1815) — threat is not zeroed, so docs/10 §7.5's "designed killer" trace (swing retargets to the ramped Wizard) cannot happen; the only way a boss leaves the tank is a DPS's MIS_AGGRO or M08. `audit.json` has no item whose title/evidence mentions ramp, song, positional, stance, spell buff or Lost Aggro (checked by script).
**Doc:** docs/06 §4.1-4.9 (🔷 PROPOSED, each with numbered rules), §5.3-5.4 (Bard tables); docs/15 Q-46 DECIDED ("Ship doc 06 §5.3's B1 mechanic with the B3 stat model"), Q-45 ("non-stacking effects — the Mage raid spell buff — carry the balance"), Q-57 DECIDED (Lost Aggro retargets swing 1 only; swing 2 on the Warrior), Q-58. Coefficients: docs/08 §8.2 `positional_mult` (Behind 1.3 / Front 0.77), Wizard +10%/stack cap 5 (docs/06 §4.8 🔷), Bard `S = 1 + floor(Mana/10)` (docs/06 §5.4, "divisor is doc 08's to set"). BLOCKED-designer items inside it: (a) the Bard divisor and song magnitudes are 🔷 and docs/08 has no row; (b) Q-43 Bard Mana variants (tier 2+). Everything else has a written rule.
**Fix:** One unit per kit, in this order (each S-M, together L): (1) Warrior Lost Aggro = the tank's action-site mistake zeroes threat for one round and swing 1 retargets to the second-highest (Q-57); (2) Wizard Ramp: `ramp_stacks` on Combatant, +10%/round same target, cap 5, reset on a Wizard action mistake (Broke the Ramp); (3) Rogue Behind/Front: `positional_mult` 1.3 default, 0.77 for two rounds on a Rogue action mistake, threat as if tanking; (4) Monk Guard: on main-tank Downed/Dead the highest-threat living Monk gets `THREAT_COEF 3.0`, tank-grade AC (docs/08 owns the number — propose Warrior's family AC at the same rung), damage x0.5, exits when a Warrior is Alive and stable; Panicked Stance inverts it for two rounds; (5) Mage Raid Spell Buff: flat +S spell power to every caster while a Mage lives (no stacking) and Overpull = the AoE also hits untanked groups (needs SIM-08's per-target AoE); (6) Bard: d6 song table per round on a `song` channel, d4 Wrong Song on a Bard mistake, behind `Formulas.BARD_SONGS_ENABLED := true` with `BARD_S_DIVISOR := 10` proposed to docs/15. Each with its own test file and the goldens regenerated once at the end of the wave. The docs/07 §5.2 taxonomy stays; the class failure modes map onto it (Lost Aggro→MIS_TAUNT_LAPSE effect, Faced the Boss→MIS_FIRE/MIS_AGGRO on a Rogue, Broke the Ramp→MIS_WRONG_TARGET on a Wizard, Bad Bounce→MIS_CHAIN_FIZZLE, Wrong Song→any Bard mistake) — write that map into docs/07 §5.2 as a column (handoff to DOCS).
**Owns:** `sim/core/RaidSim.gd`, `sim/core/Formulas.gd`, `sim/model/Combatant.gd`, `sim/core/Mistakes.gd` (the map), `data/classes.json` (song/S params), `tests/unit/test_class_kits.gd` (new), `tests/golden/*.json`; docs/07 §5.2 + docs/08 §8 handoff.
**Size:** L (six S/M units)
**Wave:** 7 — after wave 6 has fixed the roll-site rules (SIM-05/06/07/09) so each kit lands on a stable cascade, and before the wave-8 balance pass, because every kit moves DPS and the sweep must be re-baselined once with all of them in.
**Audit:** none — add rows `m6-kit-warrior`, `-wizard`, `-rogue`, `-monk`, `-mage`, `-bard` (the queue's biggest blind spot in this area).

### SIM-11 — The mistake equation is implemented once (docs/05's shape, per Q-04/05) but docs/08 §8.8 still publishes the rejected fork as "❓ OPEN" and docs/05 §5.3/§5.7 still claim sole ownership
**Status:** CONFIRMED (docs only; the sim is right)
**Evidence:** `Formulas.gd:458-509` — `MISTAKE_BASE_BP` 2400/1500/800/350/120, `MISTAKE_SENSITIVITY` 1.20/1.05/0.90/0.70/0.50, floors 1200/800/500/250/90, ceilings 8500/5000/2500/900/250, `MORALE_BAND_DELTA` = docs/05 §5.2 exactly; `mistake_chance_bp` (`:565-582`) is `base*(1+delta*sens)*facility + situational - relief`, clamped. docs/08 §8.8 (`docs/08-stats-and-formulas.md:465-522`) still prints `p = BASE_MISTAKE[r] * MORALE_MULT[band]` with 22/15/9/4/1 and a 2.50…0.50 multiplier table headed "❓ OPEN — this is currently forked and the fork is live". docs/05 §5.3 (`docs/05-morale.md:196-216`) says "this table is the only base/floor/ceiling set" and §5.7 "Doc 08 … must not hold its own base, floor, ceiling"; BUILD_STATE's binding table says the opposite (Q-04/05: docs/08 §8.8 owns, importing docs/05's sensitivity). `docs/08` is not in this wave's modified set (git status), so W5-DOCS did not touch it.
**Doc:** docs/15 Q-04/Q-05 (DECIDED). No designer input needed.
**Fix:** Rewrite docs/08 §8.8 to the shipped equation and tables (one table, basis points, the `ROLL_SITE_WEIGHT` 0.55/0.55/0.15 per BL-21 and `SITUATIONAL_CAP_BP`), delete the MORALE_MULT table and the "forked" paragraph; docs/05 §5.1-5.4 become "imported by docs/08 §8.8" pointers with the matrix kept for readability, §5.6 levers deleted (duplicate of docs/08 §11), §5.7 reversed. Also docs/03 §4.2 and docs/02/04 worked examples (DW-D2) get the same pointer. Add `tests/unit/test_docs_links.gd`-style guard: the numbers in docs/08 §8.8's table equal `Formulas.MISTAKE_BASE_BP` (a canon_guard already exists for other tables — extend `test_canon_guard.gd`).
**Owns:** `docs/08-stats-and-formulas.md`, `docs/05-morale.md`, `docs/03-guild-reputation.md` §4.2, `docs/02`, `docs/04` (worked examples), `tests/unit/test_canon_guard.gd`.
**Size:** M
**Wave:** 6 — a DOCS unit; the single most important number in the game should have one published value before anyone tunes in wave 8.
**Audit:** DW-D1, DW-D2.

### SIM-12 — Wipe-by-attrition fires at `enrage_round + 5`, a rule no document states; docs/07 §7.3 says the 40-round cap and docs/10 §6 says "enrage expiry"
**Status:** CONFIRMED
**Evidence:** `RaidSim._check_end` (`RaidSim.gd:2025-2026`): `if round_no >= encounter.enrage_round + 5: return Outcome.ATTRITION`, plus `ROUND_CAP 40` at `:53/:240`. `grep -rn "enrage_round + 5\|five rounds" docs/` = nothing. docs/10 §6 `fail_conditions[]` "Default: all 12 dead, or enrage expiry"; docs/10 §7 cards "Fail: … or enrage at round N"; docs/07 §7.3 "Round cap reached (proposed 40 rounds) with boss alive → Wipe by attrition". No test pins the +5 (`grep -n attrition tests/unit/test_raid_sim.gd` = the label list only). For E5 the fight ends at 36 not 40; for A1 (enrage 12) at 17 — a six-raider Adventure that is *winning* slowly at round 17 is declared a wipe with no M06 to have doubled anything.
**Doc:** docs/07 §7.3, docs/10 §6. docs/15: no row. Recommended default: the ATTRITION outcome fires at `ROUND_CAP` only; M06 is what "enrage" means and it is already an authored mechanic (E5 has it, the Adventures do not). If the designer wants a grace after enrage, it is `enrage_round + N` authored on the encounter (`attrition_grace`), default none.
**Fix:** Replace the +5 with `round_no >= ROUND_CAP` (already handled in `run()`), or make it data (`encounter.attrition_round`, validator `>= enrage_round`). Pin: `test_attrition_only_at_the_round_cap`. Sweep before/after (A1-A3 late clears may flip to wins).
**Owns:** `sim/core/RaidSim.gd`, `sim/model/Encounter.gd` (if data), `tests/unit/test_raid_sim.gd`, `tests/baselines/sweep_baseline.csv`.
**Size:** S
**Wave:** 8 — balance-moving; part of the balance wave so its clear-rate effect is measured with the rest. (If the designer rules M6-BAL-04 before wave 8, fold it into that pass.)
**Audit:** none — add a row; relates to M6-BAL-04 (a hidden A-rung difficulty source).

### SIM-13 — E4 as shipped: M05 has no authored effect on ANY encounter (the star buys nothing but a roll) and M08's `rounds 5, every 5` tiles its windows so the boss never returns to the tank after round 5 — which also makes E4's M09 (healing debuff on the ACTIVE TANK) decorative
**Status:** CONFIRMED
**Evidence:** `data/encounters_t1.json` E4 `m05 {"round": 4, "every": 5, "requires_melee": 1}` — no `effect`; `RaidSim._apply_interrupt_effect` (`:1239-1244`) returns when `amount <= 0` ("an unauthored effect is a demand with no teeth", `:1231-1238`). Every M05 in `data/encounters_t[2-5].json` (t2_e4, t4_e3, t5_e4) is the same shape — so the mechanic never lands anywhere in the game. E4 `m08 {"rounds": 5, "every": 5}`: `_tick_fixate` (`:913-935`) opens 5-9, releases and re-acquires at 10, 15, 20 … `tests/unit/test_raid_sim.gd:1017-1021` says so in its own words ("E4's cadence … contiguous windows … nothing in Tier 1 can show the boss going back to the tank"). Tiers 2-5 author M08 as `every 6, rounds 3` (gaps) — E4 is the odd one. With the boss off the tank from round 5, E4's `m09 target active_tank` reduces healing on someone the boss is not hitting.
**Doc:** docs/10 §7.4 ("M05 Interrupt Check (round 4, then every 5)", "M08 Fixate (5 rounds)", "Threat rule: Standard, interrupted by M08 Fixate every 5 rounds"); docs/10 §10 M05 "effect `E` fires" — E is a parameter, never named. docs/15: no row (build/plan/q-mech-arms.md Q-M05 proposed it). Recommended defaults: M05 `effect: {"kind": "raid_damage", "amount": 0.35 × cloth_max_hp}` = the M02 pulse of that tier (E4: 27) — an uninterrupted cast is "the same shape of problem as M02's pulse" per the sim's own comment; M08 on E4 `{"rounds": 2, "every": 5}` (a 2-round chase every 5 — the docs/10 card's "every 5 rounds" reading, matching tiers 2-5's gapped shape).
**Fix:** Author the two params on E4 and the three tier 2-5 M05 specs (generator: `tools/gen_encounters` or the hand file — check which writes `encounters_t2-5.json`, verify stage 2 byte-compares); `Encounter.validate()` gains "an M05 spec must carry `effect.amount > 0`" and "an M08 window must be shorter than its period"; a golden for E4 (SIM-16). Tier 1 clear rates on E4 will fall — sweep before/after; this is the star the card already promised.
**Owns:** `data/encounters_t1.json`, `data/encounters_t2..t5.json` (or their generator), `sim/model/Encounter.gd` (validator), `tests/unit/test_encounters.gd`, `tests/baselines/sweep_baseline.csv`.
**Size:** S (content) + S (validator)
**Wave:** 8 — balance-moving on E4; land with the sweep. The validator rows can land in wave 6 as WARN and flip to FAIL in wave 8.
**Audit:** relates m5-m05-interrupt-check (the row's "no effect" clause is still true as CONTENT), m5-m08-fixate; add `m6-e4-m05-effect`, `m6-e4-m08-window`.

### SIM-14 — "Stood in the Fire" fires on encounters with no fire (the token is stripped, the sentence stays)
**Status:** CONFIRMED
**Evidence:** `Mistakes.TYPES["MIS_FIRE"]` (`Mistakes.gd:63-67`) has `site: MECHANIC` and no `requires`; `RaidSim._phase_mechanic_checks` (`:774-782`) erases `Token.FIRE` from `ev.tokens_emitted` when `not zone_exists` but keeps the type, so on E3 (M01 asks the tanks a check at the swap round) or an M05/M07 check the log reads "Bob (Warrior) MISTAKE · Stood in the Fire" in a fight with no ground effect, followed by nothing. The comment at `:754-767` documents the token half of the fix and leaves the name.
**Doc:** docs/07 §5.2 row 1 "Fires during: Mechanic check" (assumes a fire exists); §10.3 writing rule 3 (never explain the mechanic — but the sentence must be true). docs/15: no row; unambiguous.
**Fix:** `MIS_FIRE` gains `"requires": "zone_exists"` and `Context.zone_exists` (set in `_context` from `encounter.has_mechanic(GROUND_EFFECT)`); MIS_MECHANIC_DROP's Fire emit is gated the same way (already stripped; make it a rule in the taxonomy, not in the site). Remove the erase at `:781`. Test: no MIS_FIRE on an encounter without M03 (extend `test_an_encounter_with_no_ground_effect_cannot_set_anybody_on_fire` to the type, not only the token). Goldens: e3_commons_adventure may move (it is the case the comment cites).
**Owns:** `sim/core/Mistakes.gd`, `sim/core/RaidSim.gd`, `tests/unit/test_mistakes.gd`, `tests/unit/test_raid_sim.gd`, `tests/golden/*.json`.
**Size:** S
**Wave:** 6 — a legibility bug in the one surface the player reads; goes in with the wave-6 golden regeneration.
**Audit:** none — add a row.

### SIM-15 — Five ambient/action types have a name and no consequence: AFK (no 1-3 round absence), LOOT_CALL (no skipped action, no morale flag), ARGUMENT (no second raider, no rest-of-encounter penalty), NO_CONSUMABLE (the buff stays applied), NINJAPULL (unreachable: `break_phase` is never true)
**Status:** CONFIRMED
**Evidence:** `RaidSim._apply_mistake` (`:1803-1839`) matches only MIS_AGGRO, MIS_TAUNT_LAPSE (`pass`), MIS_INTERRUPT_WRONG, MIS_AVOIDABLE_DEATH, MIS_BROKE_CC/FACEPULL. `Combatant.can_act` (`Combatant.gd:136-139`) knows only ALIVE and `silenced_until` — no `afk_until`. `_roll_encounter_start_mistakes` (`:1988-2003`) logs MIS_NO_CONSUMABLE after `_build_combatants` folded the loadout into the profile (`:297-322`) and never removes it, so the "forgotten" Whetstone/Draught/relief still applies (and `Consumables` still charges it — check `game/` side). `Context.break_phase` is never set anywhere (`grep -rn break_phase sim/` = the field and its flag). MIS_LOOT_CALL's morale flag: `_queue_deltas` (`:2031-2039`) queues only runs/wipes/died. MIS_WRONG_TARGET's "damage into a non-priority target" is approximated as no damage.
**Doc:** docs/07 §5.2 rows 9, 11, 14, 15, 16, 17; docs/15 Q-50 (mid-fight penalties + queued morale delta applied by `game/`). docs/15: no row for NINJAPULL's break phase — the sim has no break phase between encounters because a raid is run one encounter at a time by `game/` (docs/01's loop). Recommended default: retire MIS_NINJAPULL from the eligible set until a break phase exists (mark `"requires": "break_phase"` as a documented dead flag) rather than fake a break.
**Fix:** `Combatant.afk_until` (severity → 1/2/3 rounds; tank/healer AFK bumps severity per row 9; tank AFK emits Aggro — already in the table); LOOT_CALL sets `skip_next_action` and appends `{"raider_id", "loot_call": 1}` to `deltas_queued` for `game/` to turn into a docs/05 §7.3 morale event; ARGUMENT picks a second raider on channel `argument` and sets `argument_penalty_bp` (+500 rest of encounter) on both; NO_CONSUMABLE strips that raider's `power_bonus/mana_bonus/relief_bp` from the profile and reports the item as unspent (`result.consumables_unspent`); WRONG_TARGET deals its damage to an add if one is alive (with SIM-08). Tests per type. Goldens move.
**Owns:** `sim/core/RaidSim.gd`, `sim/model/Combatant.gd`, `sim/core/Mistakes.gd`, `tests/unit/test_raid_sim.gd`, `tests/golden/*.json`; a `game/` handoff for the loot-call morale delta and the unspent consumable.
**Size:** M
**Wave:** 6 — the taxonomy is what the player reads; a named mistake with no consequence is a lie in the log. Same golden regeneration as SIM-05/06/07/14.
**Audit:** m5-token-effects-and-cascade (relates); add `m6-ambient-effects`.

### SIM-16 — Golden coverage: no golden runs E2 or E4, so M05, M08 and M09 are never pinned by a golden, and M07/M10/M11/M12 have no Tier 1 carrier at all
**Status:** CONFIRMED
**Evidence:** `tests/golden/Scenarios.gd` scenarios: E1 (commons/starting), E3 (commons/adventure), E5 x3. `data/encounters_t1.json`: M05/M08/M09 exist only on E4; M07/M10/M11/M12 first appear in `encounters_t2..t5.json`, which `ContentDB.load_all()` does not mount until named (BUILD_STATE HANDOFF gap 1). Unit tests cover every arm on synthetic encounters (`test_raid_sim.gd:589-1250`, `test_mechanics_arms.gd`), which is real coverage, but a golden is what catches an unintended change to a shipped fight.
**Doc:** docs/14 §9.2 (golden files); docs/07 §9.
**Fix:** Add two scenarios: `e4_rares_raid_entry` (E4, Rare, morale 55, raid_entry gear — the ordinary E4) and `e2_commons_adventure`; after wave 6's regeneration so they are written once. When tiers 2-5 mount, one golden per new mechanic's first carrier (t2_e3 for M11, t2_e4 for M07, t3_e3 for M10, t3_e4 for M12).
**Owns:** `tests/golden/Scenarios.gd`, `tests/golden/*.json`, `tests/unit/test_golden.gd`.
**Size:** S
**Wave:** 6 (E2/E4), 9 (tiers 2-5 carriers, once named).
**Audit:** M6-BAL-02 (relates).

### SIM-17 — Threat: `Formulas.should_retarget` (1.10/1.30 hysteresis) is never used, Tank Lead (1.30) is not computed, and there is no Taunt action — the boss switches on any strict `>`
**Status:** CONFIRMED
**Evidence:** `grep -rn should_retarget sim/ game/` = the definition (`Formulas.gd:426-429`) only. `_pick_enemy_target` (`RaidSim.gd:1418-1422`) takes the max-threat valid raider. MIS_AGGRO sets `actor.threat = top + 1` (`:1811-1814`) — under the doc's rule ("set above primary, 1.10x", docs/07 §10.3 tier-2 sample) that would NOT clear the 1.10 threshold if the threshold were wired. Warrior taunt (docs/07 §8.1 "sets the taunter's threat to 1.10 × current highest, short cooldown") does not exist; MIS_TAUNT_LAPSE is therefore "forgot to do a thing that does not exist" — the tank generates threat by attacking only.
**Doc:** docs/07 §8.1-8.2, docs/08 §8.7. docs/15: no row. Recommended default: wire `should_retarget` for organic switches; MIS_AGGRO sets `ceil(1.10 × top) + 1` (so it always retargets, matching the sample); Taunt = a Warrior's Phase 2 action when `tank_threat < 1.30 × highest_non_tank` ("Tank Lead" lost) sets threat to `1.10 × highest`, cooldown 2 rounds; MIS_TAUNT_LAPSE = that action skipped (with SIM-10's Lost Aggro zeroing).
**Fix:** As above, in `_phase_boss`/`_pick_enemy_target` and `_take_action`'s tank branch; tests for the three rules; goldens move (rarely — organic overtakes are rare by docs/08 §8.7's own sanity check).
**Owns:** `sim/core/RaidSim.gd`, `sim/core/Formulas.gd`, `tests/unit/test_raid_sim.gd`.
**Size:** S
**Wave:** 7 — with SIM-10's Warrior/Monk kits (same code path).
**Audit:** none — add a row.

### SIM-18 — The drift gate is NOT armed: `verify.sh` stage 6 runs the sweep at 8 seeds without `--drift`; the committed baseline is only compared when a unit runs it by hand
**Status:** CONFIRMED
**Evidence:** `tools/verify.sh:196-211`: `"$GODOT" --headless --path . --script res://tools/balance_sweep.gd` (no `--drift`), passes on the sanity string `SWEEP OK` (`balance_sweep.gd:238-246` — bounds "deliberately loose … a smoke test"). `_run_drift` (`:199-235`) and `_check_drift` (`:632`) compare against `tests/baselines/sweep_baseline.csv` (9 lines: 8 reference cells at 500 seeds — A1 34.2%, A2 99.8%, A3 98.2%, E1-E4 100%, E5 75.4%) only under `--drift`, which refuses below 100 seeds (`:200-204`). W5-SIM ran it by hand and pasted the result (report-W5-SIM.md); nothing enforces that a unit does. BUILD_STATE says "`--drift` runs 500 seeds against the baseline" as if it were part of the gate; it is not.
**Doc:** docs/14 §9.3 (">5pp drift fails"); BUILD_STATE "Build status".
**Fix:** Add a verify stage `6b/9 drift` that runs `balance_sweep.gd -- --drift --seeds 200` (≈25 s at 8 cells; 200 seeds keeps the Wilson half-width ≈ 3.5pp under the 5pp rule) in the full (non-`--fast`) gate, FAIL on `DRIFT` past 5pp; `--rebaseline` stays a deliberate manual act recorded in the commit message. Also fix the 5pp rule's evidence: the baseline's A3 98.2% is at FULL adventure gear, while `test_adventures.gd:213` pins A3 at 0% at its OWN stage — both are true; the baseline should carry both rows (`A3,after_a2,common,55` and `A3,adventure,common,55`) so the wall is in the drift file, not only in a unit test.
**Owns:** `tools/verify.sh`, `tools/balance_sweep.gd`, `tests/baselines/sweep_baseline.csv`, `tests/unit/test_sweep_baseline.gd`, BUILD_STATE (one line).
**Size:** S
**Wave:** 6 — it must be armed BEFORE the wave-6 golden regeneration and the wave-7/8 balance-moving units, or none of their "does not regress" claims are checked by the gate.
**Audit:** M6-BAL-02 (its "no committed baseline" clause is REFUTED — the file exists; its "gate" clause is CONFIRMED still open).

### SIM-19 — M6-BAL-04 (Tier 1 not completable): the four costed levers, restated; plus the two pinned single-encounter defects it sits on top of
**Status:** BLOCKED-designer
**Evidence:** `sim/core/Morale.gd:30` `RARITY_OFFSET := [-5, -2, 0, 4, 12]`, `:68-75` `baseline_for(COMMON, facility 0) = 50 - 5 = 45`; `:109-117` `drift()` stops exactly at the target; `:402-406` `is_recovered` = at-or-above baseline. So a fresh all-Common guild rests to 45 and never above (band 4 "Slightly Annoyed", `MORALE_BAND_DELTA[4] = 0.20` → a Common rolls 24% × (1 + 0.20 × 1.20) = **29.8%** per action instead of 24% at Content). `tools/playtest.gd` (verify stage 7, WARN-only) measured 0/8 guilds clearing Tier 1 (audit entry, quoted). Two pinned sub-defects: A3 0/24 at its own stage (`tests/unit/test_adventures.gd:213`, one-tank party + M01/M02/M03; with `TANK_SWAP_NEEDS_A_PARTNER := true` M01 is inert there, so the wall is M02+M03 on a six-party with one healer), and the Tutorial Raid 1/20 (`test_tutorials.gd`, moved from 0/20 by the wave-5 halving — `report-W5-SIM.md` "The pin that moved").
**Doc:** docs/05 §7.5/§8 (baseline, drift), docs/11 §8.2 (facility price) + docs/01 §8.0 (60 G purse), docs/10 §3/§8 (Adventure sizing), docs/05 §7.1 (wipe delta), docs/10 §9.1 (TR swing "held under budget"); audit M6-BAL-03 (the target clear-rate curve is documented nowhere). Every lever moves a shipped canon-derived number; the loop may not pick.
**The four levers, plainly:**
(a) **Raise the Common baseline** — change `RARITY_OFFSET[COMMON]` from -5 to 0 (or +5): a new guild rests to 50 (Content, 24%) instead of 45. Cost: every band reading in docs/05 §8 and the morale chart's scale shift; the "Commons are hardest to keep happy" canon line is weakened at the start only. One number, one file (`Morale.gd`, docs/05 §7.5).
(b) **Make the first facility reachable at start** — price Guildhall tier 1 (`FACILITY_BONUS[1] = +3` → baseline 48) at or under the 60 G opening purse, or grant tier 1 at New Guild. Cost: docs/11 §8.2's price ladder and docs/01 §8.0's purse; 48 is still band 4, so this lever alone does NOT cross the 50 line — it needs (a) or (c) as well.
(c) **Size A1-A3 for 45** — re-derive the Adventure budgets in docs/10 §8 against a 29.8% Common at each rung's own gear stage (docs/08 §9.1a rows), i.e. lower A2/A3 enemy HP or raw swing, or drop M03 from A3. Cost: three rows in `data/encounters_adventure_t1.json` and docs/10 §8; admits the on-ramp was costed against a morale the player cannot reach. This is the lever that also fixes A3's 0/24.
(d) **Pay morale for a wipe differently** — reduce docs/05 §7.1's wipe delta (or cap the per-attempt loss) so five attempts do not drag a roster to the floor. Cost: docs/05 §7.1's numbers and the "failure has a cost" pillar; does not lift the 45 ceiling, only slows the fall.
Recommended default (this report, for the designer to accept or replace): **(a) at 0** — the smallest edit, fixes the ceiling rather than the slope, keeps every encounter number canon — **plus (c) for A3 only** (drop M03 from A3 or halve its `damage_per_round`), because A3 at 0/24 is a separate wall that (a) does not open. Then re-run `tools/playtest.gd` and flip verify stage 7 from WARN to FAIL.
**Fix (after the ruling):** the file list is the audit entry's: `docs/15` BL row, `sim/core/Morale.gd` or `data/encounters_adventure_t1.json`, `docs/05`/`docs/10`; re-pin `test_adventures.gd:213` and `test_tutorials.gd`; `--rebaseline` with the numbers in the commit; verify stage 7 → FAIL.
**Owns:** as above.
**Size:** M (after the ruling); the ruling itself is the blocker.
**Wave:** 8 — the balance wave; every balance-moving unit (SIM-08, SIM-12, SIM-13, SIM-10's kits) lands in or before it so the playtest is run once against the final sim.
**Audit:** M6-BAL-04, M6-BAL-03, and the TR/A3 pins.

### SIM-20 — Legendary quirks (audit Q58-*): the seam exists and is empty, the spec is a designer pass, and RaidSim does not call the seam
**Status:** BLOCKED-designer (Q58-1/3), CONFIRMED partial (Q58-4)
**Evidence:** `sim/core/Quirks.gd:1-60`: `SPECS` empty, `DEFAULT_ENABLED := false`, four identity hooks named (`threat_multiplier`, `relief_bp_bonus`, `tank_priority`, `immune_to`) with their intended RaidSim sites in comments; `grep -n quirk sim/core/RaidSim.gd sim/core/Mistakes.gd` = 0 — the hooks are not threaded into `_run_round`/`_relief_bp`/`_assign_tanks`/`eligible_types` yet, so the "spec pass is a data change" promise of Q58-4 is not yet true. `grep -ci quirk docs/07-combat-simulation.md` = 0 (Q58-1). Note the audit's "Q-58" is an older numbering: docs/15's Q-58 today is healer threat (SIM-09); the quirk ruling is BL-58 (OPEN).
**Doc:** docs/04 §11.2 (nine gifts "specced in doc 07"), docs/15 BL-58. Blocked: the nine specs.
**Fix:** Build-loop half (Q58-4): thread the four hooks into their sites behind the flag with identity semantics (goldens byte-identical, `test_legendaries.gd` already asserts the SHA), so the spec pass is a `SPECS` table + flag flip. Designer half: nine rows. Q58-2 (which doc owns the spec — docs/04 points at a missing filename): DOCS unit, S.
**Owns:** `sim/core/Quirks.gd`, `sim/core/RaidSim.gd`, `sim/core/Mistakes.gd`, `tests/unit/test_legendaries.gd`; docs/04 §11.2 / docs/07 (new §5.6 "Legendary quirks") for the spec when ruled.
**Size:** S (threading) + L (spec pass, designer)
**Wave:** 7 (threading, with the class kits since three hooks sit in the same code paths); 9 (spec, if ruled by then).
**Audit:** Q58-1, Q58-2, Q58-3, Q58-4.

### SIM-21 — BIG-dumb (audit Q59-*): conditions 1-2 live, 3 (wishlists) unbuilt behind a flag, 4 partial, 5 blocked on Q-31 vs §11.3, 6 (the warning surface) is UI
**Status:** CONFIRMED (statuses as the audit says, verified)
**Evidence:** `game/core/GameState.gd:1142-1144` increments `consecutive_benched` (Q59-0 done); `:1175-1231` `wipe_streaks` (Q59-2 done); `:221` `"wishlists": false` flag and `:1362` "benched_wishlist … is not fired" (Q59-3 not-started); `Raider.big_dumb_active` (`sim/model/Raider.gd:74`) read by `Morale.gd:319/333` as the Legendary floor gate — the sim half is done. Q59-5 (upkeep/payday) has no code and two docs disagree (Q-31 "per-run" vs docs/04 §11.3 "payday") — blocked. Q59-6 is a screen (UI reporter's area).
**Doc:** docs/04 §11.3-11.4, docs/05 §9 (wishlists ❓ OPEN optional module), docs/15 Q-31.
**Fix:** Q59-3: the generator (`sim/core/Wishlists.gd`, new: one BiS item per raider from `Loot.upgrade_delta` at hire, re-rolled when granted) + the insult counter in `GameState.assign_loot`; the four morale triggers already exist. Q59-4: a `bullet_tier` scope on `MoraleLedger` caps. Q59-5: designer picks per-run vs payday (recommended default per the audit: payday = the Day Tick after a raid, `upkeep = 1 G × rarity_index` per raider, from docs/11's ledger). Q59-6: UI.
**Owns:** `sim/core/Wishlists.gd` (new), `sim/core/MoraleLedger.gd`, `game/core/GameState.gd`, `tests/unit/test_morale_triggers.gd`.
**Size:** L (Q59-3), S (Q59-4), M (Q59-5 after ruling)
**Wave:** 9 — the wishlist module is optional (docs/05 §9 ❓) and the campaign ships without it; it is the polish that makes loot routing mean something (docs/09 §14.3), so it belongs in the content-polish wave, not before the sim rules.
**Audit:** Q59-0, Q59-2, Q59-3, Q59-4, Q59-5, Q59-6.

### SIM-22 — Tier is never threaded into the fight: `damage_after_ac` and `spell_damage_total` are called without `tier`, so BL-72's `AC_K` step and `MANA_TO_SPELL` decay never apply in a raid
**Status:** CONFIRMED (audit M5-T25-15 still true; harmless at Tier 1, wrong from Tier 2)
**Evidence:** `RaidSim._apply_damage` (`:1758`) `Formulas.damage_after_ac(float(raw), int(p["ac"]))` — `tier` defaults to 1 (`Formulas.gd:166`); `_outgoing_damage` (`:1544`) `spell_damage_total(cls, dmg, mana, targets)` — no tier (`:317`). `ac_k_for(tier)` and `mana_to_spell_for(tier)` (`Formulas.gd:65, :301`) are exercised only by tests and the tier budget tool. `encounter.tier` is on the record (`Encounter.gd`).
**Doc:** docs/08 §9.6 + docs/15 BL-72 (per-tier K and decay, DECIDED as switches).
**Fix:** Pass `encounter.tier` through `_apply_damage` and `_outgoing_damage` (two call sites; the profile can carry `"tier": encounter.tier`); test: a Tier-3 fight mitigates less at the same AC than Tier 1. Goldens unchanged (all Tier 1).
**Owns:** `sim/core/RaidSim.gd`, `tests/unit/test_raid_sim.gd`.
**Size:** S
**Wave:** 9 — with the tiers 2-5 mount (it changes nothing until then), but it can land in 6 for free.
**Audit:** M5-T25-15.

### SIM-23 — Overkill threshold: `Combatant.OVERKILL_MARGIN := 15` says "docs/08 owns the final value" and docs/08 has no such row
**Status:** CONFIRMED (doc gap)
**Evidence:** `sim/model/Combatant.gd:25-28`; `grep -n -i overkill docs/08-stats-and-formulas.md` = 0; docs/07 §7.1 "Threshold value is doc 08's".
**Doc:** docs/07 §7.1. docs/15: no row. Recommended default: keep 15 (≈ one Tier 1 raw swing on cloth after AC) and publish it in docs/08 §11's lever table as `OVERKILL_MARGIN`.
**Fix:** One row in docs/08 §11 and a `test_canon_guard` line. DOCS unit.
**Owns:** `docs/08-stats-and-formulas.md`, `tests/unit/test_canon_guard.gd`.
**Size:** S
**Wave:** 6 (DOCS pass, with SIM-11).
**Audit:** none.

### SIM-24 — RNG channels: docs/07 §9's list (`damage, mistake_gate, mistake_type, severity, targeting, compliance, loot`) does not match the tree's (`mistake_gate, mechanic_gate, targeting, fixate, healing_debuff, fire_escape, forced_mistake, compliance, mistake_line`); `compliance` is used for the encounter-start consumable roll, not for Calls
**Status:** CONFIRMED (doc drift; determinism itself is fine)
**Evidence:** `grep -o 'derive("[a-z_]*"' sim/core/RaidSim.gd | sort | uniq -c` = the nine above; type and severity draw from the gate stream in fixed order (`Mistakes.roll` `:376-399`, documented). `Rng.gd:3` xoshiro256** + SplitMix64 per docs/14 §8. `_roll_encounter_start_mistakes` (`:1998`) `rng.derive("compliance", 0, slot)` — Calls were cut (Q-09), so the channel name is a leftover. Determinism tests: `test_raid_sim.gd:92-115`, `test_rng.gd`, goldens byte-identical.
**Doc:** docs/07 §9 item 3 (docs/14 §8 is the implementation spec and wins). docs/15: no row.
**Fix:** docs/07 §9's channel list becomes "see docs/14 §8; the tree's channels are …" (DOCS); rename `compliance` → `encounter_start` (goldens move: the substream changes — do it inside the wave-6 regeneration or not at all).
**Owns:** `docs/07-combat-simulation.md` §9, `sim/core/RaidSim.gd` (one string), `tests/golden/*.json`.
**Size:** S
**Wave:** 6 (with the regeneration).
**Audit:** none.

### SIM-25 — Items (docs/09) vs `sim/`: the stat model, slot matrix, drop counts, payouts and repeat decay match; item "rarity" is not a concept in this design (rarity is the raider's); two doc-side OQs remain
**Status:** CONFIRMED (no sim defect)
**Evidence:** `sim/model/Stats.gd` = AC/HP/Power/Mana/Damage (docs/09 §2); `Loot.RAID_ROLLS` `{E1:2,E2:2,E3:2,E4:3,E5:3}` + `E5_GUARANTEES_TRINKET` (docs/10 §4.2 / docs/09 OQ-6); `RAID_PAYOUT` 6/8/14/16/26 = 70 G and `ADVENTURE_PAYOUT` 4/6/10 = 20 G (docs/11 §F1/F2); `REPEAT_DECAY` 1/0.5/0.25 floor 0.10 (docs/11 §F5); duplicate-protection as bias (BL-31, `roll_drops` :160-194); the Boss-5 trinket drawn from the four-item pool (`_trinket_from_pool` :197); tutorials roll nothing (BL-77). Held by `test_items_starting/t1_adventure/t1_raid/tutorial.gd`, `test_loot.gd`, `test_tier_scaling.gd`, `test_gen_items_merge.gd`, `test_canon_guard.gd`. Open on the docs side only: OQ-15 (the Rogue's +4 Basic Raid Dagger is a downgrade from the +5 Adventurer's Sword — canon, deliberately not fixed) and Q-35/M5-T25-14 (Adventure off-hands, content half). The generator for tiers 2-5 exists (`tools/gen_items.gd`, `sim/content/TierScaling.gd`, verify stage 2) and waits on names (M5-T25-08, designer).
**Doc:** docs/09 §2, §8.10, §13, §14; docs/10 §4.2; docs/11 §F.
**Fix:** none in sim. OQ-15 is a designer question (kept in "Questions" below).
**Owns:** —
**Size:** —
**Wave:** —
**Audit:** M5-T25-14 (content half, S, wave 9), M5-T25-08 (designer).

### SIM-26 — AC curve, mana model, melee/spell/heal formulas, variance, threat coefficients, morale bands: verified equal to docs/08 §3.3/§8.2-8.7 and docs/15 Q-01/Q-01r/Q-06/07/Q-59
**Status:** CONFIRMED (matches)
**Evidence:** `Formulas.gd:35-36` `AC_READING = CURVE`, `AC_K = 60`, `:69` `MITIGATION_CAP 0.75`, `mitigation_under` `:107-113` = `(AC*2)/((AC*2)+K)` (Q-01); `raid_wide_damage` bypass (Q-01r); `MELEE_SWINGS 2`, `OFFHAND_COEF 0.75`, `CLASS_MELEE_COEF` 1.00/1.10/0.95/0.55 (docs/08 §8.2); `MANA_TO_SPELL 0.35`, `CLASS_SPELL_COEF` 1.60/0.60/0.25 (§8.3); `MANA_TO_HEAL 0.80`, `DRUID_RAID_COEF 0.25`, `SHAMAN_CHAIN_COEFS [0.65,0.65,0.35]`, `HEAL_FLOOR 6`, `UNARMED_DAMAGE 2` (§8.5/8.5a); `DAMAGE_VARIANCE 0`, `CRIT 0` (§8.6, Q-59); `THREAT_COEF` 3.00/1.50/0.80/1.00/1.00/0.50/0 (§8.7); `Enums.morale_band = min(9, floor(m/10))` with "Quite Happy" (Q-06/07 — `Enums.gd`, checked by `test_morale.gd`). Held by `test_formulas.gd`, `test_canon_guard.gd`, `test_encounters.gd:50-88` (HP/swing/rounds = docs/08 §9.2/9.3).
**Doc:** as cited.
**Fix:** none.
**Owns:** —
**Size:** —
**Wave:** —
**Audit:** DW-B* (closed), Q-01 (closed).

### SIM-27 — The mech-arms unit's eight judgement calls (Q-M01, M01b, M03, M05, M07, M10, M11, M12) and its seven handoffs never reached docs/15 or the data; the sim carries them as switches with comments pointing at a plan file
**Status:** CONFIRMED
**Evidence:** `build/plan/q-mech-arms.md` (banner: "These are proposals. docs/15 was not edited") holds the eight; `grep -rn "q-mech-arms" docs/` = 0 and no BL-70..81 heading names a mechanic switch. `RaidSim.gd:63-129` comments cite `build/plan/q-mech-arms.md` for `TANK_DEBUFF_DECAY_PER_ROUND`, `TANK_SWAP_NEEDS_A_PARTNER`, `FRONTAL_CLEAVE_INCLUDES_TANK`, `MANA_BURN_DRAIN_ENABLED`, `ESCALATION_ANNOUNCE_EVERY`, `INTERRUPT_EFFECT_DEFAULT_KIND`; `_phase_effects` `:1662-1670` cites Q-M03 (the 50% re-roll exit replaces docs/07 §5.2 row 1's "leaves at end of next round"). `build/plan/handoff-mech-arms.md` #1 (E4 m05 effect), #2 (E4 m09 has a 3-round duration and no cadence → the debuff covers rounds 1-3 of a 17-round fight and never returns — `data/encounters_t1.json` still reads `{"reduction_pct": 40, "rounds": 3, "target": "active_tank"}`), #3 (A3 one-tank M01), #4 (MIS_FIRE on no-fire fights = SIM-14), #5 (Focus = SIM-04) are all still open in the tree. The same is true of `build/plan/q-W5-SIM.md` (four entries, written this wave, numbers unclaimed).
**Doc:** house rule 1 / BUILD_STATE: "where canon is ambiguous, behind a switch, with a docs/15 row". The rows do not exist; the switches do.
**Fix:** DOCS unit: append BL rows for the eight mech-arms calls and the four W5-SIM calls (12 entries, the text is written), then rewrite the code comments to cite the BL ids (`test_docs_links.gd` will hold them). CONTENT unit: apply handoff #2 (E4 m09 `round 3, every 6`) together with SIM-13's E4 fixes; #3 is the M6-BAL-03 designer question (below).
**Owns:** `docs/15-open-questions.md`, `sim/core/RaidSim.gd` (comments), `sim/core/Mistakes.gd` (comments), `data/encounters_t1.json`.
**Size:** M (docs) + S (content)
**Wave:** 6 (docs) / 8 (E4 content, with SIM-13's sweep).
**Audit:** none — the handoffs were never turned into audit rows; add `m6-mech-arms-register`, `m6-e4-m09-cadence`.

### SIM-28 — Tutorial rate and the scripted round-3 mistake: landed by W5-SIM this wave; the audit rows M5-TUT-11/12 are now stale, and the Tutorial Raid pin moved 0/20 → 1/20
**Status:** REFUTED (the rows' "not-started/partial"); CONFIRMED (the pin movement is a designer coupling)
**Evidence:** `Mistakes.gd:40-48` `TUTORIAL_MISTAKE_MULT := 0.5`, `TUTORIAL_DISABLED_TYPES`; `Context.tutorial` (`:235`); `chance_bp` (`:332-340`); `force()` (`:409-445`); `RaidSim._is_tutorial` (`:1877-1880`), `_pick_forced_mistake_slot` (`:1518-1535`), the forced branch in `_take_action` (`:1474-1481`); `report-W5-SIM.md` acceptance all ticked, drift +0.0pp on all eight cells. The TR pin now reads `TUTORIAL_RAID_CLEARS_AS_MEASURED := 1` with `cleared < 8` (`test_tutorials.gd`).
**Doc:** docs/15 Q-51 (DECIDED, no number), docs/10 §9.1. The 0.5 and the round-3 choices are 🔷 PROPOSED in `q-W5-SIM.md` (SIM-27 folds them into docs/15).
**Fix:** Close M5-TUT-11/12. The designer question is whether TR's swing re-pricing (M6-BAL-03) is done at the halved rate — restated below.
**Owns:** `build/plan/audit.json`.
**Size:** S
**Wave:** 6.
**Audit:** M5-TUT-11, M5-TUT-12.

### SIM-29 — Log verbosity: the sim emits the DEBUG-tier provenance docs/07 §10.1 asks for only for gap notes; mistake entries carry no `p`, `r`, `margin`, channel or draw index, so a tier-3 view cannot show "why this roll failed"
**Status:** CONFIRMED
**Evidence:** `RaidSim._log_mistake` (`:1773-1779`) → `EventLog.emit_mistake(round, phase, c, type_id, type_name, severity_key, caused_by, cascade_depth, template_id, line)` — `ev.margin` and `ev.rng_draw_index` (`Mistakes.MistakeEvent`, `:170-171`) are computed and not logged; `Mistakes.roll` does not return `p_bp`/`r_bp`; `_note_gap` (`:1329`) is the only DEBUG-tier emitter (`grep -n "LogTier.DEBUG" sim/core/RaidSim.gd`). docs/07 §10.1's `debug` field ("seed, channel, draw index, formula inputs — tier 3 only") and §10.3's tier-3 sample (`p=14.0 r=3.1 margin=0.779 | ch=mistake_gate:r4:greg draw#17 … type roll {…} -> AGGRO | severity S=82`) have no producer. NUMBERS tier is fine for attacks/heals (`emit_attack/emit_heal` carry amounts, HP after, threat after).
**Doc:** docs/07 §10.1-10.3; docs/14 §9 (bug reports attach the replay artifact — the debug line is what makes a report readable without re-running).
**Fix:** `MistakeEvent` gains `p_bp`, `r_bp`, `weights: Dictionary`, `severity_s`; `EventLog.emit_mistake` writes them under `debug` at tier DEBUG as a second entry (or as fields on the same entry filtered by tier — the entry schema already has a `tier`). Goldens: add the fields to `to_dict` → regenerate once (wave 6). RaidView's verbosity button (UI area) then has something to show at tier 3.
**Owns:** `sim/core/Mistakes.gd`, `sim/core/EventLog.gd`, `sim/core/RaidSim.gd`, `tests/unit/test_event_log.gd`, `tests/golden/*.json`.
**Size:** S
**Wave:** 6 (inside the one regeneration).
**Audit:** none — add a row.

### SIM-30 — Determinism, purity, termination and the Downed/Dead rule: verified against docs/07 §4, §7, §9 and the invariants
**Status:** CONFIRMED (matches)
**Evidence:** `sim/` imports nothing from `game/` (`grep -rn "res://game" sim/` = 0); no `randi`/`Time` in `sim/` (`tools/lint_no_global_classes.sh` + `test_raid_sim.gd:116-136` purity tests); `ROUND_CAP 40` (`:53`) and `test_always_terminates`; sequential resolution with live reads (`_run_round` `:417-465` in docs/07 §4.1's order: open → 0b checks → 0c answers → boss → tanks/DPS → healers → effects → potions → ambient → close); Downed at 0 HP with `OVERKILL_MARGIN`, `_neediest` heals the Downed first, `confirm_death_at_round_close` (`Combatant.gd:161-212`); soft wipe (no healer AND boss > 40%) logged explicitly (`_check_end` `:2018-2024`); the sim REPORTS and `game/` applies (`_queue_deltas`, docs/14 OQ-10); `EventLog.emit_phase` per round so the player can replay phases. Byte-identical goldens x5 (`test_golden.gd:70`). One deviation is SIM-12 (attrition at enrage+5).
**Doc:** docs/07 §4, §7.1, §7.3, §9; BUILD_STATE invariants 2, 9.
**Fix:** none.
**Owns:** —
**Size:** —
**Wave:** —
**Audit:** —

## Shippable bar

A reviewer ticks every line before the sim ships. Each names the finding that closes it.

**Mechanics (docs/10 §10)**
- [ ] Every one of M01-M12 has an arm and a behavioural test on a synthetic encounter — TRUE today (SIM-01); the static and behavioural dispatch guards stay green.
- [ ] M05 lands an authored effect on every encounter that carries it (SIM-13); `Encounter.validate()` refuses an M05 with no `effect.amount`.
- [ ] M08 windows are shorter than their period on every carrier (SIM-13); M09 on E4 has a cadence (SIM-27 #2).
- [ ] M10 drains Focus when `MANA_BURN_DRAIN_ENABLED` — or the designer has ruled the drain half out and the row says so (SIM-04).
- [ ] The eight mech-arms switches each have a docs/15 BL row and the code cites it (SIM-27).

**Mistakes and cascade (docs/07 §5-§6)**
- [ ] Every one of the 18 types has the mechanical effect its row states, or a documented substitute (SIM-07, SIM-15); no type is unreachable without a row saying why (NINJAPULL).
- [ ] `caused_by`/`cascade_depth` are set from live tokens; the depth cap binds; the Results report shows an indented chain on the miserable-Commons golden (SIM-05).
- [ ] Aggro raises the healers' chance, Distraction is raid-wide, the cap of +20pp holds (SIM-06).
- [ ] "Stood in the Fire" never appears on a fight with no fire (SIM-14).
- [ ] The tutorial rate (0.5), the two disabled types and the round-3 scripted mistake are pinned and in docs/15 (SIM-28).
- [ ] A tier-3 (DEBUG) view can show p/r/margin/channel/draw for a mistake (SIM-29).

**Classes (docs/06 §4, docs/15 Q-45/46/57/58)**
- [ ] Warrior Lost Aggro zeroes threat for a round and swing 1 retargets (Q-57); Taunt exists; `should_retarget` is wired (SIM-10, SIM-17).
- [ ] Wizard ramps; Rogue has Behind/Front; Monk enters Guard when the tank drops and Panicked Stance inverts it; Mage buffs casters and its AoE hits every enemy; Bard sings d6 / Wrong Song d4 (SIM-10, SIM-08).
- [ ] Healers generate threat at 0.5; the chain never repeats and skips >95% (SIM-09).

**Formulas (docs/08)**
- [ ] docs/08 §8.8 publishes the ONE mistake equation the sim runs, with `ROLL_SITE_WEIGHT` and the cap; docs/05 defers to it (SIM-11).
- [ ] Focus has a docs/08 section with class values (SIM-04); `OVERKILL_MARGIN` is in §11 (SIM-23).
- [ ] AC curve, melee/spell/heal, threat, variance, bands — verified equal (SIM-26); tier is threaded into AC and spell power (SIM-22).

**Goldens and the gate**
- [ ] Five goldens byte-identical after the wave-6 regeneration, plus E2 and E4 goldens (SIM-16); every regeneration's commit states before/after.
- [ ] `verify.sh` runs `--drift` against `tests/baselines/sweep_baseline.csv` and FAILS past 5pp (SIM-18); the baseline carries A3 at its own stage.
- [ ] Attrition fires only at the round cap or an authored grace (SIM-12).

**Completable**
- [ ] The designer's lever for M6-BAL-04 is recorded in docs/15 and applied; `tools/playtest.gd` clears Tier 1 on 8/8 seeds; verify stage 7 is FAIL, not WARN (SIM-19).
- [ ] A3 and the Tutorial Raid pins are turned back into the assertions they want to be (`rate > 0`, `cleared >= 8`) with docs/15 rows (SIM-19, SIM-28).
- [ ] Tiers 2-5 mount once named; one golden per new mechanic's first carrier (SIM-16, SIM-22).

## Questions for the designer

Only the ones the tree cannot answer by reading the docs. Each names the recommended default already written down.

1. **M6-BAL-04 — which lever?** (a) Common baseline -5 → 0, (b) first facility at start, (c) re-size A1-A3 for morale 45, (d) smaller wipe delta. Recommended: (a) at 0, plus (c) for A3 only (drop M03 or halve its tick). Every option moves a shipped number; the loop will not choose. (SIM-19)
2. **M6-BAL-03 — the Tutorial Raid's swing and M01 with one tank.** TR (and A3) carry M01 on a one-tank party; the sim currently makes M01 *say* it has no partner and stay inert (`TANK_SWAP_NEEDS_A_PARTNER := true`). Is that the reading, or should M01 be replaced on those two rungs (handoff-mech-arms #3 options a/b/c)? And should TR's swing be re-priced at the halved tutorial rate the fight now runs at? Recommended: keep the switch TRUE, replace A3's M01 with M04 (a six-party can answer adds), leave TR's swing and re-measure after the rate ruling. (SIM-19, SIM-28)
3. **Focus numbers (Q-02 Model A+).** `focus_max` and `focus_per_cast` per healer/caster class, and what an empty pool does. Recommended default is in SIM-04 (pool per class in `classes.json`, no regen in-fight, empty pool = `HEAL_FLOOR`). Without a ruling the build lands it behind `FOCUS_ENABLED := false`.
4. **M05's effect E.** Recommended: `raid_damage` at the tier's M02 pulse value (E4: 27). If you would rather it be a boss self-heal or a tank one-shot, say which per encounter. (SIM-13)
5. **E4's M08 window.** "Fixate (5 rounds), every 5 rounds" tiles the fight; recommended `rounds 2, every 5`. (SIM-13)
6. **Bard song magnitudes.** docs/06 §5.4's `S = 1 + floor(Mana/10)`: is 10 the divisor, and are the six song / four Wrong Song effects as tabled? Recommended: ship the table as written behind `BARD_S_DIVISOR := 10`. (SIM-10)
7. **Monk Guard's AC.** docs/06 §4.6 "AC treated as tank-grade" — recommended: the Warrior family AC of the same rung. (SIM-10)
8. **Attrition grace.** Should a fight that outlives its enrage round get a grace before "wipe by attrition", and how long? Recommended: none — M06 is the enrage, the 40-round cap is the safety. (SIM-12)
9. **The target clear-rate curve.** M6-BAL-03 is right that no doc states what E1…E5 should clear at for the benchmark comp at each gear stage; the baseline is 100/100/100/100/75 at Common/raid_entry/55. Is that the intended shape (a tier that is free until its boss), or should E3/E4 bite? The wave-8 balance pass cannot tune against nothing.
10. **Legendary quirks (BL-58).** Nine one-line specs, in the four-hook shape `Quirks.gd` documents. (SIM-20)
11. **docs/09 OQ-15.** The Rogue's Basic Raid Dagger +4 is a downgrade from the Adventurer's Sword +5 — canon, deliberately unfixed. Raise it, or give the Rogue its swings? (SIM-25)
12. **Upkeep / payday (Q59-5).** Per-run (Q-31) or payday (docs/04 §11.3)? (SIM-21)

## Coverage

**Read in full:** `sim/core/RaidSim.gd` (2039 lines), `sim/core/Mistakes.gd`, `sim/core/Formulas.gd`, `sim/model/Combatant.gd` (first 300 lines + API), `sim/core/Loot.gd` (drop model), `sim/core/Morale.gd` (baseline/drift/recovered), `sim/core/Quirks.gd` (header), `sim/model/Enums.gd` (bands, tokens); docs/07 in full; docs/08 §8 (master formulas), §3 headers; docs/05 §5; docs/06 §4-§5; docs/09 §2, §14-§15; docs/10 §6-§7, §10; docs/15 Q-01..Q-09 table rows, Q-45..Q-59, BL-70..81 headings; BUILD_STATE (all); `report-W5-SIM.md`, `q-W5-SIM.md`, `q-mech-arms.md` (headings), `handoff-mech-arms.md` (#2 in full); `data/encounters_*.json` (all mechanics/params, all tiers); `tests/golden/Scenarios.gd`, `tests/baselines/sweep_baseline.csv`; test function lists for `test_raid_sim.gd` (59), `test_mechanics_arms.gd`, `test_golden.gd`, `test_encounters.gd`, `test_adventures.gd` (A3 pin in full); `tools/verify.sh` stage 6; `tools/balance_sweep.gd` drift section; the 36 audit rows named in the brief (ids, status, M6-BAL-04 in full); sheet `raid-advanced/RaidView_all.png`.

**Not read (and why):** `sim/core/Reputation.gd`, `Recruitment.gd`, `Economy.gd`, `Buildings.gd`, `Comfort.gd`, `Consumables.gd`, `Achievements.gd`, `MoraleLedger.gd` — outside docs/05-09's sim surface except as callers (another reporter's area: campaign/economy); `sim/content/*` beyond `Quirks`; `game/` beyond two greps; docs/08 §9-§13 and docs/09 §3-§13 in full (their numbers are held by `test_encounters.gd`/`test_items_*.gd`/`test_canon_guard.gd`, which I trusted rather than re-derived); the eleven other contact sheets (UI area); no Godot run (the mutex) — every "measured" number here is quoted from a test comment, a baseline file or a W5 report, never re-measured. The tiers 2-5 encounter data were read for mechanics only, not budgets. Q59-3..6 were verified by grep, not by reading `GameState.gd`.
