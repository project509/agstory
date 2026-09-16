# Proposed `docs/15-open-questions.md` entries — the mechanic arms (M5)

> **CONSUMED (W6-LEDGER, 2026-09-15):** the eight entries are `docs/15` **BL-82** (Q-M07), **BL-83** (Q-M05), **BL-84** (Q-M01), **BL-85** (Q-M01b — ❓ OPEN, the designer's, ship plan §6 #9), **BL-86** (Q-M03, with the no-fire-without-a-zone half), **BL-87** (Q-M10; Focus deferred), **BL-88** (Q-M11), **BL-89** (Q-M12). The code comments that cite this file are re-pointed at those ids by `build/plan/handoff-W6-LEDGER.md` (applied at the wave-6 close; audit `m6-mech-arms-register`). Nothing below is edited; it is the record the entries were promoted from.

Written by the `mech-arms` agent. **These are proposals.** `docs/15` was not
edited (house rule 1). Each entry names the switch in `sim/core/RaidSim.gd` or
`sim/model/Enums.gd` that carries the documented default until a ruling lands.

---

## Q-M07 — Is there a position layer, or only abstract flags?

**Status today.** `docs/15`'s question table already carries the recommendation
("Abstract flags only. No grid, no coordinates") in the *recommendation* column,
and `grep DECIDED docs/15` does not list it. `docs/07` OQ-7 asks the same
question. So the recommendation has never been ratified, and M07 Positioning
Requirement (`docs/10` §10) cannot be implemented without answering it.

**Proposed answer: DECIDED — abstract flags only.**

> The simulation carries no coordinates, no grid and no distances. A raider is in
> exactly one of two named states, `Enums.Stance { SPREAD, STACKED }`, and
> nothing else about space is representable. A mechanic may demand a stance for
> a window of rounds; a raider is in the demanded stance if they answered that
> round's mechanic check and in the other one if they fumbled it. "Off-position"
> is therefore a synonym for "failed the check", which is exactly what makes M07
> a `MIS_MECHANIC_DROP` mechanic rather than a movement puzzle.

**Why.** Three reasons, in the order they mattered:

1. `docs/02`'s core claim is that the player is not in the raid. Coordinates
   would be state the player can neither see nor influence, and the sim would
   pay for them in every golden file forever.
2. `docs/10` §10 M07's own spec ("Fight demands Spread or Stack for `N` rounds;
   wrong state costs `X` per off-position raider") needs only a two-valued flag.
   Nothing else in the twelve-mechanic vocabulary asks for more.
3. A grid would make `docs/10` §12's 40-encounter budget an authoring problem
   (every encounter would need a map) which is exactly the cost §10 exists to
   avoid.

**What it costs.** The class-derived default stance (melee `STACKED`, everyone
else `SPREAD`, set in `RaidSim._build_combatants`) is only observable OUTSIDE a
live M07 window — inside one, the check result overwrites it. That is honest but
it means the default is nearly decorative, and a future ruling that "melee can
never satisfy a Spread demand" would give it teeth without changing the model.

**Switch.** `Enums.Stance` is the whole model; there is no wider one behind a
flag, because half a position layer would be worse than either answer.

**An m07 that does not name its stance.** docs/10 §10 M07 is "demands Spread or
Stack" and privileges neither, so RaidSim may not pick one for an encounter that
omits `required`. `POSITIONING_DEFAULT_REQUIRED := Enums.Stance.SPREAD` did
exactly that on the strength of the table's word order, with no entry here; it
has been deleted. An m07 with no `required` now opens no window, charges
nothing, and emits "The fight demands a position and nobody can say which" —
the same treatment Q-M05 gives an unauthored effect `E`, and for the same
reason. Asserted by
`tests/unit/test_raid_sim.gd::test_m07_without_a_named_stance_demands_nothing_and_says_so`.
No Tier 1 encounter authors m07, so this is a rule for Tier 2 authoring.

---

## Q-M05 — What is M05's effect `E`?

`docs/10` §10 M05 says "Boss casts on round `R`; unless ≥1 melee DPS is in
position, effect `E` fires" and never names E. No number for E exists anywhere
in canon or in the docs.

**Proposed answer.** E is a per-encounter authored payload, not a constant:

```json
"effect": {"kind": "raid_damage", "amount": 26}
```

`kind` is one of `raid_damage` (an AC-ignoring pulse, like M02) or
`boss_heal_pct` (the boss heals that percentage of its maximum). An encounter
that omits `effect` gets a cast that resolves and does **nothing** — a demand
with no teeth — rather than a number RaidSim invented.

**Switch.** `RaidSim.INTERRUPT_EFFECT_DEFAULT_KIND` (`"raid_damage"`) supplies
only the KIND when an author gives an amount without one. The amount defaults to
0 and is never synthesised.

**Follow-up.** `data/encounters_t1.json`'s E4 m05 spec needs an `effect` block or
its fourth star buys a roll and no consequence. Requested in
`build/plan/handoff-mech-arms.md`; that file is not mine to edit.

---

## Q-M01 — Does the tank-swap debuff decay while you are off duty?

`docs/10` §10 M01 gives the stack rules ("+50%/stack damage taken, 1 stack per
hit, swap required at 3") and says nothing about the stacks coming off. Without
decay the mechanic works exactly twice: both tanks reach 3, and there is nowhere
left to swap to.

**Proposed answer.** One stack per round while a tank is not the active tank —
the mirror of one stack per hit while they are. `RaidSim.TANK_DEBUFF_DECAY_PER_ROUND`
is the switch (default 1).

**No ceiling, and this is not a question.** docs/10 §10 M01 names exactly one
number, `swap_at`, and no maximum; docs/10 §10 M12 says "**no cap**" in as many
words for the escalating swing, so this vocabulary writes ceilings down when it
means them. A `TANK_DEBUFF_STACK_CAP_AT_SWAP` constant briefly capped the stack
at `swap_at` — a ×2.5 ceiling nothing in canon asks for, with no entry in this
file — and its only real effect was to soften the one case docs/06 says must
hurt. Deleted. Stacks are uncapped.

---

## Q-M01b — What does "swap required at 3" mean when there is nobody to swap to?

`data/encounters_adventure_t1.json` authors m01 onto A3, which is
`tanks_required` **1**. docs/10 §8's own A3 row lists M01 among its mechanics
and its party column gives it one tank. A solo tank cannot satisfy "swap
required at 3", so docs/10 §10 M01's rule set has no defined behaviour there.

**Proposed answer: the sim invents nothing, and content fixes A3.**

> M01 is live wherever it is authored. The tank accumulates stacks by the same
> rule as anywhere else, `_attempt_tank_swap` states in the transcript that
> there is nobody to swap with, and the stacks kill the tank. That is docs/06's
> composition punishment and the audit's own `m5-m01-tank-swap` remaining_work
> (5). An encounter that wants M01 has to ask for two tanks.

**Why it is a question and not just a ruling.** Because it makes A3 unclearable
as authored — measured 0/24 seeds with m01 as the only mechanic, tank dead at a
mean round of 4.8 against a 12-round target. The alternative readings are all
design rulings somebody has to make: M01 could decay on duty when no partner
exists, or cap, or not apply at all. **A previous pass took the last of those
silently** (`_tank_swap_is_live` gated M01 off below `tanks_required` 2) and
that is the reading this entry exists to stop being made in code. The three
content options are laid out in `build/plan/handoff-mech-arms.md` item 3.

---

## Q-M03 — Two documented exits from the fire, and they disagree

- `docs/07` §5.2 row 1: the raider "leaves at end of next round, or immediately
  on **BACK OFF!**".
- `docs/10` §10 M03: "a raider re-rolls out at `p` per round".
- `Enums.TOKEN_DURATION[Token.FIRE]` is `-1`, "until cleared", citing `docs/07`
  §6's duration column ("Until the raider leaves").

**Proposed answer.** `docs/10`'s re-roll is the implemented exit, because it is
the one content parameterises: `escape_chance_bp` is already authored on E4 and
E5 (`data/encounters_t1.json`) and was read nowhere. An encounter that omits the
param keeps a permanent zone, which is `docs/07` §6's "until the raider leaves"
with no way to leave. `docs/07` §5.2's "end of next round" then reads as the
*expected* outcome of a 50% per-round re-roll rather than a second rule.

If that is wrong, the fix is a token duration, not a mechanic parameter — and it
would move `Enums.TOKEN_DURATION`, which is why it is a question and not a
silent choice.

**The code now does this, and did not before.** `_phase_effects` used to run an
unconditional "out at the end of the round after entry" BEFORE the escape roll,
so every stay capped at two ticks, `escape_chance_bp` only ever chose between
one tick and two, and the permanent zone this entry describes did not exist in
the sim at all — ratifying the entry as written would have documented behaviour
the code did not have. The re-roll is now the only exit.
`tests/unit/test_raid_sim.gd::test_m03_puts_raiders_in_the_fire_and_takes_them_out_again`
asserts a stay can exceed two rounds at 5000bp, and
`::test_m03_without_an_escape_chance_is_a_zone_you_cannot_leave` asserts the
permanent case.

**A Fire token on a fight with no zone is not covered by any of this**, and it
is not a zone at all. Two MECHANIC-site mistake types emit `Token.FIRE` and
neither is gated on the encounter carrying m03, so a tank-swap check on E3 —
which has no ground effect — could stamp one that nothing would ever clear.
`_phase_mechanic_checks` refuses the stamp instead: the encounter card decides
which consequences are in play. See `build/plan/handoff-mech-arms.md` item 4 for
the eligibility half, which lives in `sim/core/Mistakes.gd`.

---

## Q-M10 — M10 is two mechanics in one row, and one of them has no resource

`docs/10` §10 M10: "For `N` rounds, casters lose `X` Mana per round **or** cannot
act".

**Proposed answer.** Ship the silence half now; the drain half is blocked.
`Formulas.MANA_MODEL` is `MAGNITUDE_PLUS_FOCUS` per `docs/15` Q-02, and its own
docstring says "Focus is a separate class-fixed resource that never appears on an
item" — but no Focus pool exists: no field on `Combatant`, no class-fixed values
in `data/classes*.json`, no spend anywhere. Mana in the sim is a flat magnitude
read off the gear profile and consumed by nothing.

Building one inside a mechanic arm would contradict `Formulas.MANA_MODEL`'s
documented shape, so `RaidSim.MANA_BURN_DRAIN_ENABLED` is `false` and the drain
half is written up as its own subsystem item in
`build/plan/handoff-mech-arms.md`.

---

## Q-M11 — Is the tank "melee-positioned"?

`docs/10` §10 M11: "`X` damage to all melee-positioned raiders each round",
class stressed "Rogue, Monk, Warrior".

**Proposed answer.** Yes. The Warrior is named in the stressed column, and the
Warrior is the tank in every canon composition, so a reading that spares the
tank contradicts the row's own second column.

**Switch.** `RaidSim.FRONTAL_CLEAVE_INCLUDES_TANK` (default `true`).

---

## Q-M12 — "No cap" versus the 40-round cap

`docs/10` §10 M12: "Boss raw swing +`X` per round, **no cap** — a soft enrage".
`docs/07` §7.3 makes the 40-round cap a safety property.

**Proposed answer.** No interaction to resolve: the swing has no cap, the fight
does. `tests/unit/test_raid_sim.gd::test_m12_still_terminates_inside_the_round_cap`
asserts termination rather than assuming it. The announcement cadence
(`RaidSim.ESCALATION_ANNOUNCE_EVERY`, 5) is a log-readability choice and not a
mechanic parameter — twenty rounds of "the swing is bigger" is a wall, not a
story beat.
