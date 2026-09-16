# Proposed docs/15 entries — W5-SIM (the tutorial mistake rate and the scripted round-3 mistake)

> **CONSUMED (W6-LEDGER, 2026-09-15):** the four entries are `docs/15` **BL-90** (the 0.5 rate; the number is the designer's, ship plan §6 #57), **BL-91** (the TR pin 0/20 → 1/20 — ❓ OPEN, §6 #1/#9), **BL-92** (A0's scripted mistake), **BL-93** (the melee predicate). The `Mistakes.gd` / `RaidSim.gd` comments that cite this file are re-pointed by `build/plan/handoff-W6-LEDGER.md` (applied at the wave-6 close).

Three judgement calls this unit made inside DECIDED rulings, one canon question those calls surfaced,
and one predicate the tree already carried that the contract asked to be written down. **Numbers are
not claimed** — BL-81 was the highest declared entry when this was written and W5-DOCS owns docs/15;
assign the next free ids in order. Nothing in `sim/` or `tests/` cites these by number
(`tests/unit/test_docs_links.gd` fails the suite on a `BL-nn` docs/15 does not declare); every code
comment points at `build/plan/q-W5-SIM.md` and those pointers should be rewritten once these land.

Copy the entries below in the file's existing heading style, each preceded by its
`<a id="bl-nn"></a>` anchor.

---

### BL-?? - The tutorial mistake rate is HALF, and the two pulls are off *(🔷 PROPOSED - implemented behind a named constant)*

**Owner:** [15 Q-51](./15-open-questions.md#q-51) / [07 OQ-9](./07-combat-simulation.md) / [10 §9.1](./10-content-and-encounters.md) - **Signal:** Silent - the ruling gave a direction and no number, and the sim ran both tutorials at the full rate

Q-51 is DECIDED: "Reduced rate for both tutorials, full rates from Adventure 1 onward", mirroring
07 OQ-9, which names `MIS_FACEPULL` and `MIS_NINJAPULL` as the two types to disable. Neither text says
how much "reduced" is.

**Decision: `Mistakes.TUTORIAL_MISTAKE_MULT := 0.5`, applied to the gate chance only, at every roll
site, for every encounter whose slot `Reputation.is_tutorial_slot()` knows ("A0", "TR").**
`Mistakes.Context.tutorial` carries the flag; `RaidSim._context()` sets it from the encounter and the
two roll sites that build a Context by hand (ambient, encounter start) read it off the mechanic state.
`Mistakes.TUTORIAL_DISABLED_TYPES := ["MIS_FACEPULL", "MIS_NINJAPULL"]` are dropped from
`eligible_types()` under the flag. The taxonomy, weights and severity model are untouched, so a tutorial
mistake reads exactly like a real one; it happens half as often.

| Option | Cost |
|---|---|
| 0.5 | One halving, no second number to explain; the tutorial still shows roughly one action in eight failing for a Common at Content, which is the beat §9.1 needs the player to see |
| 0.25 or lower | Adventure 0 would rely on its scripted mistake alone; the Tutorial Raid's six-raider fight would show almost none |
| Per-tutorial values | Two numbers for one sentence of ruling; nothing in canon distinguishes the two rungs' rates |

Pinned by `tests/unit/test_mistakes.gd` (the two types are never offered to any class at any site
with the flags armed; `Mistakes.chance_bp()` is exactly `round(full x 0.5)` over 60 rarity/morale/site
cells; the observed hit rate through `roll()` sits at 0.38-0.62 of the real one over 6000 rolls) and
`tests/unit/test_tutorials.gd::test_both_tutorials_roll_at_the_reduced_rate_and_a_real_rung_does_not`
(the flag reaches the Context the fight builds for A0/TR and not for A1/E1/E5). Every golden and every
balance-sweep cell is byte-identical: no golden fixture is a tutorial and the sweep does not run them
(`--drift`: +0.0pp on all eight reference cells).

---

### BL-?? - The reduced tutorial rate moved the Tutorial Raid's pinned measurement from 0/20 to 1/20 *(❓ OPEN - canon question, recorded, not retuned)*

**Owner:** [10 §9.1](./10-content-and-encounters.md) / [15 Q-51](./15-open-questions.md#q-51) - **Signal:** Loud - a pin moved with no number changed

`tests/unit/test_tutorials.gd::test_the_tutorial_raid_is_currently_unwinnable_and_that_is_recorded`
pins the Tutorial Raid's clear rate with the squad the game hands you, measured 0/20, as the record of
a defect only a designer may fix (the swing was priced without M01's multiplier; the pin's own comment
has the measurement, one factor at a time). That 0/20 was measured at the FULL mistake rate. With Q-51's
reduced rate at 0.5 in the sim, one of the twenty seeds clears: **1/20**. Only the halving can have
moved it — `MIS_FACEPULL` needs a trash phase and TR is a boss; `MIS_NINJAPULL` needs a break phase and
nothing in RaidSim opens one. Nothing about TR's swing, HP or M01 changed, and 1/20 is not "winnable and
losable" (the pin's text calls `>= 8` the fix).

**What the build loop did:** the pin's value follows the measurement (`TUTORIAL_RAID_CLEARS_AS_MEASURED
:= 1`, with the history in its comment and `cleared < 8` asserted beside it), because a gate that is red
for a reason no loop may fix stops all work (LESSONS.md), and 0.5 was NOT moved to restore 0/20 — that
would have been tuning a canon-driven number to a pin. Adventure 0's pin (>= 18/20) is unchanged.

**The question for the designer:** the Tutorial Raid's swing/mechanic ruling (audit `M6-BAL-03`, the
pin's comment) and the tutorial mistake rate are now coupled — a designer re-pricing TR's swing "with
the multiplier included" should do it at the reduced rate the fight will actually be played at, and may
want to name the rate at the same time. No recommendation on the swing; the 0.5 stands until ruled.

---

### BL-?? - Adventure 0's scripted mistake: who, how, and how bad *(🔷 PROPOSED - implemented)*

**Owner:** [10 §9.1](./10-content-and-encounters.md) - **Signal:** Silent - the field existed on the record and the validator for a wave, and nothing in the sim read it

10 §9.1: "Adventure 0 scripts one guaranteed mistake on round 3 regardless of morale rolls ... a
content-level override flag on the encounter record (`force_mistake_round: 3`), and it exists on
exactly one encounter in the game." The doc fixes the round and the guarantee, and leaves three things
open: which raider, how severe, and how "regardless of morale rolls" interacts with the gate.

**Decision, three parts.**

1. **The gate is skipped, not weighted.** `Mistakes.force()` builds the event from the ordinary path
   AFTER the gate — the same eligible set (the tutorial bans included), the same class-weighted draw,
   the same event shape — and never rolls the chance. That is what "regardless" means, and it is also
   why the halved tutorial rate (above) has nothing to suppress: the two rulings cannot interact.
2. **The raider is drawn from the seeded Rng** (`rng.derive("forced_mistake", round_no, 0)`, its own
   channel, so the pick cannot move any other draw and the fight stays a pure function of its seed),
   out of the living non-tank raiders who act in the tank/DPS phases, chosen after the boss has swung so
   the pick is somebody still standing. The healers resolve in Phase 4 through a path that never
   reaches the action site. The tank is excluded because a one-tank pull's only tank mistake is a taunt
   lapse whose consequence is invisible on a single mob, and §9.1's beat is "READ a mistake in the log";
   the tank is the fallback when nobody else can act, because a scripted mistake that quietly does not
   happen is the one outcome the flag exists to rule out. The audit's alternative — "the highest-morale
   non-tank actor, so the player reads 'even your best is bad'" — was not taken: it makes the same
   raider fail on every seed, which reads as a targeted script rather than as the roster being bad.
3. **Minor, at the type's floor.** "A tutorial demonstrates a fail state, it does not impose one"
   (10 §9.1). The draw prefers types whose band reaches Minor (base Minor or Moderate) and lands at
   Minor; when none is eligible it falls back to the whole set at each type's own floor (a Severe type
   can only ever be Moderate here). The type's tokens are emitted as they would be organically.

| Option | Cost |
|---|---|
| Rng pick, Minor (taken) | Deterministic per seed, varies across seeds; embarrassing, never lethal |
| Highest-morale non-tank | Same raider every run; reads as a targeted script |
| Severity from `severity_for` (random) | A Severe on round 3 of a four-raider trash pull can down somebody in the fight that is not allowed to be a fail state |

Held by `tests/unit/test_mistakes.gd` (fires 40/40 at a 95-morale Legendary inside a tutorial context;
Minor at the floor for every class/role; deterministic; a cooldown narrows the pool and never empties
it) and `tests/unit/test_tutorials.gd` (20 seeds on A0 with the squad the game hands you: a MISTAKE
entry on round 3 and `mistake_count >= 1` on every seed; replay-identical; the Tutorial Raid and the
real rungs never script one). `sim/model/Encounter.gd`'s validator (negative, or past `target_rounds`)
was already in the tree; the docs/10 §6 field-table row is `build/plan/handoff-W5-SIM.md` #1.

---

### BL-?? - Frontal Cleave's "in front of the boss" is the melee predicate, tank included *(🔷 PROPOSED - already implemented; written down on request)*

**Owner:** [10 §10 M11](./10-content-and-encounters.md) / [07 §5.2 row 1](./07-combat-simulation.md) - **Signal:** Silent - the predicate was chosen in code and recorded only in `build/plan/q-mech-arms.md` Q-M11

M11 is "`X` damage to all melee-positioned raiders each round", stressing "Rogue, Monk, Warrior". The
sim has no positions; docs/07 OQ-7's abstract model gives every raider a stance derived from class.
**"Melee-positioned" is `Consumables.MELEE_CLASSES` — Warrior, Monk, Rogue, Bard — the one melee
predicate the tree already uses for the Whetstone Kit, M03's zone demand and M05's interrupters**, so
four mechanics and a consumable can never disagree about who stands in front. The tank is included
(`RaidSim.FRONTAL_CLEAVE_INCLUDES_TANK := true`; Q-M11's argument: the Warrior is named in the row and
is the tank in every canon composition). The Bard is included by the shared predicate rather than by
the row's own list; if a designer wants the Bard out of the front, that is a change to `MELEE_CLASSES`
and moves the kit and two other mechanics with it, which is the point of one predicate. Armour applies
(a cleave the plate tank shrugs off is what plate is for); the AC bypass stays M02's alone.

Held by `tests/unit/test_raid_sim.gd::test_m11_hits_the_melee_and_only_the_melee` and
`tests/unit/test_mechanics_arms.gd` (every living melee raider is cleaved on round 1, one line per
round, nobody outside the predicate ever is, and an encounter without m11 carries no trace of it).
