# Handoff — agent `formulas` (DW-B1, DW-B2)

Changes I could not make because my ownership list for this wave is
`sim/core/Formulas.gd`, `tests/unit/test_formulas.gd` and
`tests/unit/test_stats.gd` only.

**§§4-6 are DW-B1's acceptance criterion, not a courtesy note.** The audit gives
DW-B1 `files_to_touch: ["docs/08-stats-and-formulas.md",
"docs/15-open-questions.md"]` and states its acceptance as *"docs/08 contains no
❓ OPEN on the AC reading, and test_formulas.gd's message cites a docs/15 heading
that actually says DECIDED."* The docs/15 half is drafted in
`build/plan/q-formulas.md`. The docs/08 half is §§4-6 below, and it is not
covered by any other agent's handoff — apply it, or DW-B1 is not done. Nothing in
it is a proposal about a number: every value named is one that has shipped in
`sim/core/Formulas.gd` since the first `sim/` commit.

§§1-3 are DW-B2's, and are not urgent while `AC_READING = AcReading.CURVE`; they
are what makes the switch genuinely flippable, which is the point of DW-B2.

Line numbers are as of 2026-09-10 with the `doclinks` agent's cross-reference
pass applied; each edit also quotes its anchor text, because further doc edits
will move the numbers.

---

## 1. `tests/unit/test_adventures.gd:158` — the caller the defect was hiding in

```gdscript
var mit := Formulas.mitigation(ac)
var needed := float(tank.max_hp(_db)) / (clock * (1.0 - mit))
```

This is the call site that made DW-B2 dangerous: under either flat reading
`mitigation()` used to return `0.0`, so `needed` became the unmitigated swing and
the assertion validated the encounter against the wrong clock rather than
failing. It no longer can silently — `mitigation()` now returns `NAN` under a
flat reading, so `needed` becomes `NAN`, `absf(authored - needed) <= 2.0` is
false, and the test fails loudly with a `push_error` explaining why.

That is safe, but it is not the right shape. The audit suggested repointing at
`mitigation_at(authored_raw, ac)`; that does not work here, because this equation
is *solving for* `raw` and `mitigation_at` needs a `raw` to measure at — it would
be circular. Two options that do work, pick one:

**(a) Guard the derivation to the readings it is valid under** (smallest change,
and honest — the closed-form solve only exists for a proportional reading):

```gdscript
if not Formulas.reading_is_proportional(Formulas.AC_READING):
    # docs/08 §9.3's `raw = hp / (clock * (1 - mitigation))` has no closed form
    # under a flat reading, where mitigation moves with the size of the hit.
    continue
var mit := Formulas.mitigation(ac)
```

**(b) Measure at the authored swing instead of solving for it** — compare the
clock the authored number actually produces against the intended one, which is
reading-agnostic:

```gdscript
var blk = e.enemies[0]
var authored := float(blk.raw_swing * blk.swings_per_round * blk.count)
var per_round := float(Formulas.damage_after_ac(authored, ac))
var got_clock := float(tank.max_hp(_db)) / per_round
assert_true(absf(got_clock - clock) <= 0.2, ...)
```

(b) is stronger and works under all four readings, but it changes the assertion's
tolerance from "within 2 raw damage" to "within 0.2 rounds" and I have not
measured whether the three rungs pass at that tolerance — do not take it on
faith.

## 2. `docs/08-stats-and-formulas.md:381` — the sentence is now wrong

> Reading 1 and Reading 2 variants (§3.3) are drop-in replacements for
> `mitigation`/`take_damage`. Implement mitigation behind this one function so
> the OPEN in §3 can be resolved by editing four lines.

They are not drop-in replacements for `mitigation`: the flat readings have no
constant fraction, which is why they returned `0.0`. Suggested replacement:

> The four readings of §3.3 all live behind **`damage_after_ac(raw, ac)`**, which
> is the single implementation; flipping `Formulas.AC_READING` is the whole edit.
> `mitigation(ac)` is a shorthand valid only under the proportional readings
> (R3, R2) and returns `NAN` under R1/R1b, where the effective fraction moves
> with the size of the hit; `mitigation_at(raw, ac)` is the reading-agnostic
> answer, measured off `damage_after_ac` rather than derived beside it. New
> callers should prefer `damage_after_ac`.

## 3. `docs/08-stats-and-formulas.md` §3.3 Reading 2 — two clarifications

Both are things the code now matches and the doc leaves implicit:

- Reading 2 is **uncapped**. `MITIGATION_CAP` belongs to Reading 3 only; §3.2's
  window-proof row (AC 15 vs 127.5 raw landing on 17.0) only reproduces without
  the cap. Worth one sentence, because the code previously applied it and that
  made the rejection unverifiable.
- Reading 2's con *"a 0 AC recruit divides by zero"* describes `raw / (AC/2)`,
  but the formula printed directly above it is `raw / max(1.0, AC / 2.0)`, which
  cannot. The `max` is the guard; the con should say so rather than read as an
  unfixed flaw in the printed formula.

Also, §3.3's heading is "The three candidate readings in full" and it lists four
(1, 1b, 2, 3) — the enum has four members for that reason.

## 4. `docs/08-stats-and-formulas.md:113` — retitle Reading 3 (DW-B1)

The line currently reads:

```
**Reading 3 — diminishing-returns curve** 🔷 PROPOSED — **recommended**
```

Replace with:

```
**Reading 3 — diminishing-returns curve** ✅ **RULED** — the shipped reading ([doc 15 Q-01](15-open-questions.md), build loop, 2026-09-10)
```

`✅ **RULED**` rather than a new marker word: [02 §4.2](02-town-and-buildings.md)
already uses exactly that form for a build-loop ruling
(`✅ **RULED** (was §12 Q13; see [15 Q-38]...)`), and neither doc's legend row
needs changing for it.

## 5. `docs/08-stats-and-formulas.md:141` — the ❓ OPEN paragraph (DW-B1)

This is the one the acceptance criterion names. It currently reads:

> ❓ **OPEN — decision required.** Three readings of one canon sentence produce a
> 4× to 14× difference in tank survivability. This doc recommends Reading 3 but
> does **not** treat it as settled. Everything downstream (§9 boss budget) is
> computed under Reading 3 and is re-derivable under the others; the derivation
> is parameterised, not hand-tuned.

Replace the whole paragraph with:

> ✅ **RULED — Reading 3, and it was already the code.** Three readings of one
> canon sentence produce a 4× to 14× difference in tank survivability, and §3.2
> above is the argument that settles it: under Readings 1 and 2 cloth gets
> *more* fragile as the tier progresses, because a flat subtraction (or a linear
> divisor) widens the absolute gap every time AC rises. Reading 3 is the only
> reading whose cloth clock is stable across tiers, which is the condition for
> cloth and tanks coexisting at all. Shipped in `sim/core/Formulas.gd` as
> `AC_READING = AcReading.CURVE`, `AC_K = 60.0`, `MITIGATION_CAP = 0.75`; pinned
> by `tests/unit/test_formulas.gd` ::
> `test_switches_are_single_named_constants` and
> `test_reading_3_curve_mitigation_at_three_ac_values`. Everything downstream
> (§9 boss budget) is computed under Reading 3 and stays re-derivable under the
> others: Readings 1, 1b and 2 above are the **rejected alternatives**, each
> still implemented behind `Formulas.damage_after_ac_under()` under the enum
> member named in §3.3 — Reading 1 is `FLAT_TWO_PER_POINT`, Reading 1b
> `FLAT_HALF_AC`, Reading 2 `DIVISOR` — and each is asserted at §3.1's canon AC
> values against §3.2's own window-proof rows, so the arithmetic that rejected
> them can be re-run rather than taken on trust. See [doc 15
> Q-01](15-open-questions.md) (struck) and the build-loop entry recording it.

Two notes for whoever applies it:

- Do not name the build-loop entry's ID inline unless
  `build/plan/q-formulas.md`'s **Q-60** survives DW-A3's renumbering; the
  sentence above is written so the ID is not load-bearing.
- Nothing here is a new number. `AC_K = 60.0` and `MITIGATION_CAP = 0.75` are
  §3.3's own published constants, and "4× to 14×" is this paragraph's own phrase,
  kept.

## 6. `docs/08-stats-and-formulas.md:760-761` — §13 rows 1 and 2 (DW-B1)

The §13 table's fourth column is headed `Proposed default`, and rows 1 and 2 are
both the AC reading. Marking them answered in place, keeping the header and the
rest of the table untouched. Row 1 becomes:

```
| 1 | Does "AC = 2 damage reduction" mean 2 damage **per point of AC**, or **1 damage per 2 AC**? | 4× swing in tank survivability; every boss number in §9 depends on it | ✅ **ANSWERED** ([doc 15 Q-01](15-open-questions.md), struck) — neither literal reading: the ×2-numerator curve, Reading 3, `AC_K = 60`, cap `0.75`, per §3.3. Shipped as `Formulas.AC_READING = AcReading.CURVE` |
```

Row 2 becomes:

```
| 2 | If flat reduction (Reading 1) is intended, how do cloth classes survive? At T1 Raid a hit that takes 8 rounds to kill the tank kills a Mage in 1.65 | Under flat mitigation there is **no** boss auto-attack value where the tank is threatened and cloth survives | ✅ **ANSWERED** ([doc 15 Q-01](15-open-questions.md), struck) — Reading 3, for exactly this reason. The contingency stands as the record of what a Reading 1 mandate would cost: cloth would need a separate damage channel and a hard rule that bosses never melee non-tanks |
```

Both cells keep their original text as the substance of the answer; the only
change is that a *proposal* becomes a *ruling* with a pointer. If §13's intro
sentence ("Four things are left undecided by canon itself...") is ever recounted,
note that it refers to the four items *above* the table, not to these rows.
