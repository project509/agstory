# Proposed `docs/15-open-questions.md` entries — agent `formulas` (DW-B1, DW-B2)

Two edits to docs/15, both record-keeping. Nothing here is implemented from this
file (docs/15 §1: "Nothing may be implemented from this file") — the code already
shipped Reading 3 and the tests already pin it; what was missing was the record.

**This file is only half of that record.** DW-B1's other half is the docs/08
side — the §3.3 retitle, the `❓ OPEN` paragraph at :141 and the §13 rows — which
this agent does not own either. It is drafted in
`build/plan/handoff-formulas.md` §§4-6 and, as of 2026-09-10, is **not yet
applied**: docs/08:141 still reads `❓ OPEN — decision required`. Applying one
half without the other leaves the owning doc contradicting the struck question.

**ID note:** the highest heading in the build-loop series at the time of writing
is `Q-59`, so the new entry below is numbered **Q-60**. If DW-A3's renumbering
lands first, renumber this one to the next free ID; nothing else in it depends on
the number.

---

## Edit 1 — strike the §4 Q-01 row (docs/15 §2.2 step 3)

Replace the heading at docs/15:82 and its `🔷 Recommended default` paragraph
(docs/15:95) with the struck form. The option table above it stays as the record
of the rejected alternatives.

Heading becomes:

```
### ~~Q-01 — Does "AC = 2 damage reduction" mean 2 damage per point of AC, or 1 damage per 2 AC — or neither?~~ *(RESOLVED — see 08 §3.3; build loop, 2026-09-10)*
```

The recommendation paragraph becomes:

```
**✅ RESOLVED — R3, `AC_K = 60`, cap `0.75`.** See [08 §3.3](./08-stats-and-formulas.md)
and Q-60 below. Implemented as `Formulas.AC_READING = AcReading.CURVE`
(`sim/core/Formulas.gd`); pinned by `tests/unit/test_formulas.gd`
`test_switches_are_single_named_constants` and
`test_reading_3_curve_mitigation_at_three_ac_values`.
```

**Rider, also resolved.** The same row's rider ("does AC apply to spell and
raid-wide damage") is implemented and should be struck with it:

```
**Rider — RESOLVED: raid-wide and spell damage ignore AC**, per
[10 OQ-3](./10-content-and-encounters.md), implemented as
`Formulas.raid_wide_damage()`, which rounds and floors at 1 and never consults
AC. Pinned by `test_formulas.gd :: test_raid_wide_damage_ignores_armour`. The
rider only mattered under R1, where a 28-AC tank takes 1 from every raid pulse;
under R3 it is a design choice rather than a rescue, and it is the one docs/10's
encounter tables were authored against.
```

---

## Edit 2 — new build-loop entry

### Q-60 - The AC reading was ruled in code and never recorded, and two of its four settings were silently armourless *(DECIDED - implemented)*

**Owner:** [08 §3.3](./08-stats-and-formulas.md) - **Signal:** Silent, twice over

Two separate gaps behind one switch.

**The record.** `sim/core/Formulas.gd` has shipped Reading 3 since the first
`sim/` commit — `AC_READING = AcReading.CURVE`, `AC_K = 60.0`,
`MITIGATION_CAP = 0.75` — and `test_formulas.gd` asserts the constant with the
message "docs/15 Q-01 ruled Reading 3". Q-01 was never struck, and
[08 §3.3](./08-stats-and-formulas.md) carried `❓ OPEN — decision required` over
the reading the whole project computes in — it still does at the moment this
entry is written, and the edit that clears it is
`build/plan/handoff-formulas.md` §§4-6, which must land with this entry rather
than after it. Every downstream number in docs 08 §9 and docs 10 was derived
under a reading the owning document described as unsettled.

**Decision: Reading 3, the diminishing-returns curve, is the shipped reading.**

```
mitigation   = (AC * 2) / ((AC * 2) + AC_K)      # AC_K = 60
mitigation   = min(mitigation, MITIGATION_CAP)   # 0.75
damage_taken = max(1, round(raw * (1.0 - mitigation)))
```

The reasoning is [08 §3.2](./08-stats-and-formulas.md)'s window proof, and it is
the whole argument. Solve for the boss auto-attack `raw` that kills the main tank
in exactly 8 unhealed hits, then ask how long the Mage lives at that same `raw`:

| Reading | T1 Adventure (15 vs 8 AC) | T1 Raid (28 vs 13 AC) |
|---|---|---|
| R1 flat 2/pt | Mage survives **2.4** hits | Mage survives **1.65** hits |
| R2 divisor AC/2 | 2.35 hits, and needs 127.5 raw | 1.98 hits, and needs 266 raw |
| R3 curve, K=60 | **3.7** hits | **3.2** hits |

R1 and R2 both get *worse as the tier progresses*: the gear that makes the tank
sturdier makes cloth more fragile, because a flat subtraction (or a linear
divisor) widens the absolute gap every time AC rises. R3 is the only reading
whose cloth clock is stable across tiers, which is the condition for cloth and
tanks coexisting at all. R2 additionally demands four-digit boss numbers at
Tier 1 that match nothing in canon.

Why the numbers are these numbers:

- **`AC_K = 60`** is the single knob that sets where returns bend. At 60 the real
  canon AC spread lands on 21.1% for a Mage's 8 AC, 33.3% for a Warrior's 15, and
  48.3% for a shielded raid tank's 28 - so a fully raid-geared main tank halves
  incoming damage, cloth sits near 30%, and the Warrior Shield is the largest
  single defensive upgrade in the game, which matches its ✅ CANON stat line being
  the largest AC value in Tier 1.
- **`MITIGATION_CAP = 0.75`** exists so tiers 2-5 can keep raising AC without
  trivialising tier 1. Tier 1 must not already be sitting on it: 30 AC mitigates
  exactly 50%, well clear of the ceiling. A test asserts that specifically.
- The `× 2` numerator is not decoration. It is how canon's literal sentence
  *"AC = 2 damage reduction"* survives **inside** the formula - each AC point
  still contributes 2 units of mitigation weight - rather than being discarded in
  favour of an invented curve.

**The second gap: the switch was not honest.** docs/08 §8.4 asks for mitigation
to live "behind this one function so the OPEN in §3 can be resolved by editing
four lines", and all four readings are enumerated in `AcReading` as if
selectable. They were not. `mitigation()` returned **`0.0`** under both flat
readings, with the comment "handled as flat subtraction in take_damage" - true of
`damage_after_ac()`, but callers use `mitigation()`'s return value directly
(`tests/unit/test_adventures.gd` derives every authored boss swing from
`1.0 - mitigation(ac)`). So two of the four settings would have produced a game
with no armour at all, and the encounter-authoring assertion would have validated
against the wrong clock instead of failing. Reading 2 was also wrong on its own
terms: it was implemented as `1 - 1/(1 + AC/2)` clamped to `MITIGATION_CAP`,
neither of which is [08 §3.3](./08-stats-and-formulas.md)'s published
`raw / max(1.0, AC / 2.0)`, and the clamp made §3.2's own window proof
irreproducible - a rejected option nobody can re-run is a rejection nobody can
check. Reading 1b floored at 1 damage where the doc floors at
`ceil(raw * MIN_HIT_FRACTION)`, the same floor it publishes for Reading 1.

**Decision: the two entry points are `damage_after_ac()` and `mitigation_at()`,
and a reading that cannot answer says so.**

| Call | Contract |
|---|---|
| `damage_after_ac(raw, ac)` | The one implementation. All four readings, each exactly [08 §3.3](./08-stats-and-formulas.md)'s published formula |
| `mitigation_at(raw, ac)` | The fraction a hit of that size actually loses, **measured off** `damage_after_ac`. Defined under every reading, because the flat readings' effective fraction moves with the size of the hit. Domain `raw >= 1`: below 1, §8.4's floor deals more than the hit was worth, so the honest fraction is negative and this returns it rather than clamping — clamping would put the helper back to disagreeing with the function it measures. `raw = 0` answers 0.0. No production caller passes either; every authored `raw_swing` is an integer of at least 6 |
| `mitigation(ac)` | The constant-fraction shorthand. Valid under R3 and R2 only; returns **`NAN`** and `push_error`s under a flat reading |
| `*_under(reading, …)` | The same two functions with the reading named explicitly, so the three unshipped readings stay testable without recompiling the switch. A `reading` that is not an `AcReading` member `push_error`s in **both** — `damage_after_ac_under` falls back to unmitigated damage, `mitigation_under` to `NAN`. That symmetry matters: an unguarded fall-through returned the same `NAN` a legitimate flat reading returns, so a typo'd reading was indistinguishable from Reading 1 |

`NAN` and not `0.0` deliberately: zero mitigation is indistinguishable from *no
armour*, which is exactly how this hid. `NAN` poisons the first arithmetic it
touches. Selecting a flat reading also `push_error`s at script load
(`_static_init`), because it silently invalidates every caller still holding
`mitigation(ac)` and those callers live in balance and encounter-authoring
checks, where a wrong number validates rather than fails.

Pinned by ten new tests in `tests/unit/test_formulas.gd`, one per reading at
three canon AC values each (a Mage's 8, a Warrior's 15, a shielded tank's 28),
plus `test_no_reading_can_silently_report_no_armour`,
`test_mitigation_helpers_cannot_diverge_from_damage_after_ac` and
`test_no_reading_can_diverge_from_its_own_mitigation_fraction` — the last of
those being the convergence check run under **all four** readings rather than
only the live one, which is where a divergence could hide. The flat readings'
cases are asserted against [08 §3.2](./08-stats-and-formulas.md)'s window-proof
rows (47 raw at T1 Adventure, 75 at T1 Raid), so the arithmetic that rejected
them stays reproducible.

**What did not change: anything R3 computes.** `mitigation(17) = 0.3617`,
`damage_after_ac(37, 23) = 21`, and every authored encounter number are
byte-identical. This entry moves no shipped value.
