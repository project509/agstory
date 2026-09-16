# handoff — `mech-arms` (M5 mechanic arms)

Changes I could not make because the file is not mine. Each is exact.

---

## 1. `data/encounters_t1.json` — E4's m05 needs an `effect` block

**Why.** docs/10 §10 M05 is "Boss casts on round `R`; unless ≥1 melee DPS is in
position, **effect `E` fires**". The arm is in (`RaidSim._resolve_interrupt`) and
reads the payload from the spec, because docs/10 never names E and RaidSim must
not invent a number (house rule 1). Without this block E4's fourth star buys a
roll and no consequence: the cast resolves, the log says so, and nothing lands.

**Old** (`data/encounters_t1.json`, the m05 spec on `t1_raid_e4`):

```json
{"id": "m05", "params": {"round": 4, "every": 5, "requires_melee": 1}}
```

**New:**

```json
{"id": "m05", "params": {"round": 4, "every": 5, "requires_melee": 1,
  "effect": {"kind": "raid_damage", "amount": 28}}}
```

`kind` is `raid_damage` (AC-ignoring, like M02's pulse) or `boss_heal_pct`. The
amount is content's to set and needs a docs/08 source; **28 above is E5's m02
magnitude, offered as a shape, not as a derived number** — if it cannot be
sourced, leave the block out and the gap stays visible. Proposal in
`build/plan/q-mech-arms.md` Q-M05.

---

## 2. `data/encounters_t1.json` — E4's m09 has a duration and no cadence

**Why.** E4's m09 is `{"reduction_pct": 40, "rounds": 3, "target": "active_tank"}`.
`rounds` is a duration; there is no `round` and no `every`. RaidSim reads a
windowed mechanic with no cadence as "on from the pull for `rounds` rounds"
(`_unscheduled_reading` → `FROM_THE_PULL`), because the alternative reading makes
m09 dead on the only encounter that configures it. That means E4's healing debuff
covers rounds 1-3 of a **17-round** fight and never returns, which is almost
certainly not what docs/10 §7.4's card ("M09 Healing Debuff on the active tank")
intends.

**Suggested:** add a cadence, e.g.

```json
{"id": "m09", "params": {"round": 3, "every": 6, "reduction_pct": 40,
  "rounds": 3, "target": "active_tank"}}
```

which gives three windows across a 17-round fight. The cadence numbers are
content's call; the *shape* is the request.

---

## 3. `data/encounters_adventure_t1.json` — A3 asks for a tank swap with one tank

**Why.** A3 is `party_size` 6, `tanks_required` **1**, and carries m01. M01 is a
swap mechanic and a solo tank cannot swap, so docs/10 §10 M01's rule set has no
defined behaviour there: "swap required at 3" presupposes somebody to swap to.

**This entry has changed since the last wave.** RaidSim used to gate M01 off
whenever `tanks_required < 2` (`_tank_swap_is_live`), which made A3's m01 do
nothing at all — docs/10 §6's "a star that buys nothing is a lie on the
encounter card", and against the audit's own `m5-m01-tank-swap` remaining_work
(5). **That gate is gone.** M01 is now live on A3: the tank accumulates stacks,
`_attempt_tank_swap` says out loud that there is nobody to swap with, and the
stacks kill the tank — which is what the audit asked for and what docs/06 calls
composition punishment. It also makes A3 unclearable on its own (see item 7).

The sim will not invent a rule for the one-tank case. Content has to resolve it,
one of:

- **(a)** raise A3 to `tanks_required: 2` — but docs/10 §3 and
  `tests/unit/test_adventures.gd::test_adventures_are_half_headcount_with_one_tank`
  both assert one tank per Adventure, so this is a doc change too; or
- **(b)** replace A3's m01 with a mechanic a six-person one-tank party can
  actually answer (M03 and M02 are already there; M08 Fixate or M09 Healing
  Debuff would both work), and amend docs/10 §8's table; or
- **(c)** rule that M01 on a one-tank fight means something else, and say what
  in `docs/15` — proposal drafted as Q-M01b in `build/plan/q-mech-arms.md`.

This is a content/doc decision. Whichever way it goes, docs/10 §8's mechanics
column and the data have to agree.

---

## 4. `sim/core/Mistakes.gd` — MIS_FIRE can fire on a fight with no fire

**Why.** `MIS_FIRE` is `site: RollSite.MECHANIC` with no `requires` gate, so it
is eligible at EVERY mechanic check — including M01's tank-swap check on an
encounter that has no ground effect. "Bob stood in the fire" in a fight with no
fire is wrong on its own terms, and docs/07 §5.2 row 1 defines the type's
consequence as "takes mechanic tick damage in Phase 5", which a fight with no
tick cannot deliver.

**The dangerous half is already fixed on my side.** `_phase_mechanic_checks`
now refuses to stamp `Token.FIRE` when the encounter carries no GROUND_EFFECT
spec, because the token was permanent there (`TOKEN_DURATION[FIRE]` is -1 and
only `_phase_effects` clears it) and armed `MIS_AVOIDABLE_DEATH` — the
taxonomy's only Critical cascade-only type — for the whole fight. The shipped
`e3_commons_adventure` golden lost a raider to exactly that. So this handoff is
now about the FLAVOUR, not about a kill.

Note the RaidSim invariant does **not** make this redundant:
`MIS_MECHANIC_DROP` also emits `Token.FIRE` and has no `requires` either, so
gating `MIS_FIRE` alone still leaves a second path to a fireless fire token.
Both layers are wanted — one stops the eligibility, one stops the consequence.

**Suggested** — a context flag, the way `interrupt_check` already works:

```gdscript
# in Mistakes.TYPES
"MIS_FIRE": { ... "cascade_only": false, "requires": "ground_effect", },

# in Mistakes.Context
var ground_effect: bool = false
# and in Context.flag():
"ground_effect": return ground_effect
```

I will then set `ctx.ground_effect = encounter.has_mechanic(Enums.Mechanic.GROUND_EFFECT)`
in `RaidSim._context` — that half is mine and is one line, but it is inert until
the type carries the gate. **Note this moves the goldens again**, so it wants to
land with a golden regeneration.

---

## 5. New item — the Focus pool (docs/15 Q-02), which M10's drain half needs

**Why.** docs/10 §10 M10 is "casters lose `X` Mana per round **or** cannot act".
The silence half shipped. The drain half has nothing to drain:
`Formulas.MANA_MODEL` is `ManaModel.MAGNITUDE_PLUS_FOCUS` and its docstring says
Focus "is a separate class-fixed resource that never appears on an item", but
grep for Focus across `sim/` returns only those comment lines. Mana in the sim is
a flat magnitude off the gear profile, consumed by nothing.

**Scope of the item** (a subsystem, not a mechanic arm):

1. `focus` / `focus_max` on `Combatant`, serialised.
2. Class-fixed values in `data/classes.json`, read by `sim/model/ClassDef.gd`.
3. A spend in `_take_action` and `_cast_heal`, and a documented rule for what a
   caster does at zero.
4. Then, and only then, M10's drain: flip `RaidSim.MANA_BURN_DRAIN_ENABLED` and
   read `X` from the spec.

The Token.MANA that the three wasted-heal mistakes emit (`Mistakes.gd:80,86,92`)
is the other half of the same hole: `_situational_bp` reads only AGGRO and
DISTRACTION, so a Mana token currently has no effect either. Both want the same
resource.

---

## 6. `tests/unit/test_enums.gd` — `Stance` has no key/name test

`sim/model/Enums.gd` gained `Stance` / `STANCE_KEYS` / `STANCE_NAMES` and the
three accessors. Every other enum in that file has a keys-and-names test in
`test_enums.gd`; this one does not, because the file is not mine. Two lines:

```gdscript
func test_stance_is_two_abstract_flags_and_nothing_else() -> void:
    # docs/07 OQ-7: no grid, no coordinates (build/plan/q-mech-arms.md Q-M07).
    assert_eq(E.STANCE_KEYS.size(), 2)
    assert_eq(E.STANCE_NAMES.size(), 2)
    assert_eq(E.stance_key(E.Stance.SPREAD), "spread")
    assert_eq(E.stance_from_key("stacked"), E.Stance.STACKED)
```

---

## 7. `tests/unit/test_adventures.gd` — one red test, and it is a true signal

`test_the_mini_boss_is_still_winnable` asserts A3's clear rate is above zero. It
is **0%**, it was already 0% before this repair pass, and the `_tank_swap_is_live`
gate that was added to save it did not save it. Measured at A3's own gear stage
(`_stage_equipped`, morale 55) over the same 24 seeds the test uses, against an
A3-shaped encounter with mechanics added one at a time:

| A3 mechanics live | clear rate |
|---|---|
| none | **24/24** |
| m01 only | **0/24** |
| m02 only | 3/24 |
| m03 only | 9/24 |
| all three (= shipped A3) | **0/24** |

Read that top row first: **A3's boss autoattacks alone are a 100% clear.**
docs/10 §8's clock math for A3 prices the boss's swings and nothing else, and
A3 then carries three mechanics on a six-person party. Each of the three is
individually near-fatal at that headcount; m01 is fatal on its own, for the
reason in item 3 (nobody to swap with, stacks climb until the tank dies at a
mean round of 4.8 across 24 seeds against a 12-round target).

Per the task's instruction I did **not** retune to compensate, and I removed the
gate that had quietly done so. The fix is item 3 plus a balance pass on §8's
sizing — not a softer m01, m02 or m03.
