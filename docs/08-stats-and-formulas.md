# 08 — Stats, Formulas & Numeric Model

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document defines every stat in A Guild Story and every formula that converts stats into damage, healing, threat, survival time and mistakes, plus the derived boss budget those formulas imply.

## 1. Scope

**This doc owns:** stat definitions and their interpretation; base HP; the master formula set (melee, spell, mitigation, healing, threat, mistake chance) **including the mistake-chance equation and every coefficient in it — the per-rarity base, floor and ceiling and the per-band morale multiplier (§8.8)**; the Mana-vs-resource resolution (§5.3); rounding and order of operations; the Tier 1 numeric sanity pass; the per-tier scaling multipliers; the tuning-lever map.

**This doc does NOT own:**

| Topic | Owner |
|---|---|
| Round structure, turn order, targeting, mechanics, positional rules | [07 — Combat Simulation](07-combat-simulation.md) |
| Item tables, drop rates, rarity naming, what appears on which slot | [09 — Items & Itemization](09-items-and-itemization.md) |
| Morale bands and their names, baseline and drift, every event that moves morale, rarity resilience, leave/disband rolls, wishlists, the roster display | [05 — Morale](05-morale.md) |
| Class abilities, songs, cooldowns, class fantasy | [06 — Classes & Roles](06-classes-and-roles.md) |
| Recruit rarity distribution by reputation rank | [03 — Guild Reputation](03-guild-reputation.md) |
| Engine choice, RNG implementation, determinism plumbing | [14 — Technical Architecture](14-technical-architecture.md) |

Doc 07 owns combat *rules*. This doc owns the *arithmetic*. Doc 09 owns the item *tables*. This doc owns what the numbers on them *do*.

❗ **Ownership collision to close (see §8.8).** [05 — Morale](05-morale.md) §1 also claims "Morale → mistake chance — the per-band multiplier and the per-rarity base it multiplies", and its §5.1-§5.4 publish a *different* equation with different coefficients. Split proposed here: **this doc owns the equation and all coefficients; doc 05 owns morale itself and points at §8.8 for the conversion.** Doc 05 §1's mistake-chance row, its §5.1-§5.4 numeric tables and its §5.6 tuning-lever table need to be replaced by a cross-reference to §8.8 / §11 for that split to hold.

## 2. Canon stat definitions

✅ CANON — quoted verbatim (canon: raw notes, "Stat definitions"):

```
AC = 2 damage reduction
Power = +1 melee dmg
Mana = spell damage (Subject to change)
```

That is the complete list. There are four stats that actually appear on gear in the ideaboard tables: **AC**, **HP**, **Power**, **Mana**. HP appears on every armor piece in both tiers but is **never defined anywhere in canon** — see §6.

| Stat | Canon definition | Appears on | Status of meaning |
|---|---|---|---|
| AC | "AC = 2 damage reduction" | All armor, shields, healer off-hand, Adventure's Charm of Armor | ❓ OPEN — the sentence has ≥2 valid readings (§3) |
| HP | *(undefined)* | All armor, Adventure's Charm of Health | ❓ OPEN — no base value exists (§6) |
| Power | "Power = +1 melee dmg" | Tier 1 **Raid** armor only, plus Adventures Charm of Power | ✅ CANON and unambiguous (§4) |
| Mana | "Mana = spell damage (Subject to change)" | Healer + Mage/Wizard armor, Bard Instrument, healer off-hand, Charm of Mana | ❓ OPEN — canon flags it and asks a direct question (§5) |

## 3. AC — the central ambiguity

### 3.1 The problem, stated with real canon numbers

✅ CANON: a Tier 1 Adventure Warrior/Bard armor set totals **15 AC** (canon: ideaboard §2.1). ✅ CANON: "AC = 2 damage reduction".

Read literally as *each point of AC removes 2 damage from every incoming hit*, that Warrior removes **30 damage per hit**. Add ✅ CANON "Adventure's Charm of Armor — +2 AC" and it is **34 per hit**. A Tier 1 Raid Warrior with the ✅ CANON Boss 5 shield (Warrior Shield — 7 AC / +8 HP / +1 Power) reaches 21 armor AC + 7 shield + 2 trinket = **30 AC → 60 damage removed per hit**.

That is not a large number in the abstract. It becomes a problem because it is **flat**, and because canon's own spread of AC across the roster is narrow in absolute terms but wide in ratio:

| Loadout | AC (canon) | Flat reduction at 2/pt |
|---|---|---|
| Common Mage starting armor | 4 | 8 |
| Common Warrior starting armor | 7 | 14 |
| T1 Adventure Mage/Wizard | 8 | 16 |
| T1 Adventure Healer | 9 | 18 |
| T1 Adventure Rogue | 13 | 26 |
| T1 Adventure Monk | 14 | 28 |
| T1 Adventure Warrior/Bard | 15 | 30 |
| T1 Raid Healer (incl. Tome) | 15 | 30 |
| T1 Raid Mage/Wizard | 13 | 26 |
| T1 Raid Warrior (armor only) | 21 | 42 |
| T1 Raid Warrior (+ Shield) | 28 | 56 |

The tank/cloth gap is **only 14 flat** at Tier 1 Adventure (30 vs 16) but the *ratio* of reductions is 1.9:1. Flat mitigation means any boss hit large enough to threaten the tank is catastrophic for cloth, and any hit small enough to be safe for cloth does literally nothing to the tank.

### 3.2 The window proof

Solve for the boss auto-attack size `raw` that kills the main tank in exactly 8 unhealed hits, then ask how many hits the Mage survives at that same `raw`. Uses 🔷 PROPOSED base HP from §6 (Warrior 120, Mage 65).

| Reading | Tier | `raw` to kill tank in 8 | Tank takes | Mage takes | Mage survives |
|---|---|---|---|---|---|
| R1 flat 2/pt | T1 Adventure (15 vs 8 AC) | 47.0 | 17.0 | 31.0 | **2.4 hits** |
| R1 flat 2/pt | T1 Raid (28 vs 13 AC) | 75.0 | 19.0 | 49.0 | **1.65 hits** |
| R2 divisor AC/2 | T1 Adventure | 127.5 | 17.0 | 31.9 | 2.35 hits |
| R2 divisor AC/2 | T1 Raid | 266.0 | 19.0 | 40.9 | 1.98 hits |
| R3 curve (K=60) | T1 Adventure | 25.5 | 17.0 | 20.1 | **3.7 hits** |
| R3 curve (K=60) | T1 Raid | 36.7 | 19.0 | 25.6 | **3.2 hits** |

Reading 1 gets **worse as the tier progresses** — at Tier 1 Raid the cloth caster dies to a single auto-attack that the tank barely feels. Reading 2 requires four-digit boss numbers at Tier 1 and still degrades. Reading 3 holds a stable ~3-round cloth clock at both tiers.

### 3.3 The three candidate readings in full

**Reading 1 — flat 2 per point** (the most literal parse)

```
damage_taken = max(raw - (AC * 2), ceil(raw * MIN_HIT_FRACTION))   # MIN_HIT_FRACTION = 0.10
```
- Pro: exactly what the sentence says; trivially readable in a combat log ("Bob's armor absorbed 30").
- Con: needs a minimum-damage floor or high-AC targets become invulnerable to small hits. At T1 Raid, a 40-damage hit does 4 to the tank (floor) and 14 to the Mage — a 3.5× spread from a 2.15× AC spread. Con: forces boss auto-attacks to be huge and boss AoE to be a completely separate, un-mitigated damage channel, or cloth cannot exist.

**Reading 1b — flat AC/2** (the mirror parse: "2 AC = 1 damage reduction")

```
damage_taken = max(raw - floor(AC / 2), ceil(raw * MIN_HIT_FRACTION))
```
- The same English sentence supports this. It yields Warrior 7, Mage 4 at T1 Adventure — small, gentle, and it makes the entire ideaboard AC spread nearly irrelevant (a 2-point difference between Warrior and Rogue armor (15 vs 13 AC) becomes 1 damage, and the 1-point Warrior/Monk gap disappears entirely — `floor(15/2)` and `floor(14/2)` are both 7). ❓ OPEN — worth 30 seconds of designer confirmation because it is a coin-flip on grammar with a 4× difference in outcome.

**Reading 2 — AC as a divisor**

```
damage_taken = raw / max(1.0, AC / 2.0)
```
- Pro: no invulnerability ceiling, no floor needed. **`MITIGATION_CAP` is Reading 3's and does not apply here** — §3.2's window-proof row for this reading (AC 15 against 127.5 raw landing on 17.0) only reproduces uncapped, so capping it would make the arithmetic that rejected this reading unverifiable.
- Con: unbounded scaling — mitigation approaches 100% asymptotically but the divisor grows linearly forever, so Tier 5 gear trivialises Tier 1 content in a way that cannot be tuned back. Con: below 2 AC the divisor would be <1 and *amplify* damage, and a 0 AC recruit would divide by zero — the `max(1.0, …)` in the formula above is the guard against both, so this is a flaw in the naive reading rather than in what is printed. Con: the Tier 1 numbers it demands (266 raw) do not match any other number in canon.

**Reading 3 — diminishing-returns curve** ✅ **RULED** — the shipped reading ([doc 15 Q-01](15-open-questions.md#q-01), build loop, 2026-09-10)

```
mitigation  = (AC * 2) / ((AC * 2) + AC_K)          # AC_K = 60
damage_taken = max(1, round(raw * (1.0 - mitigation)))
mitigation is additionally clamped to MITIGATION_CAP = 0.75
```

Why this one: the numerator is literally `AC * 2`, so canon's phrase "AC = 2 damage reduction" survives *inside the formula* — each AC point still contributes 2 units of mitigation weight. `AC_K` is a single knob that sets where returns start bending, and it caps naturally, so tiers 2-5 can raise AC without breaking tier 1.

Resulting mitigation with the real canon numbers at `AC_K = 60`:

| Loadout | AC | Mitigation | Damage from a 40 raw hit |
|---|---|---|---|
| Common Mage starting armor | 4 | 11.8% | 35.3 |
| Common Warrior starting armor | 7 | 18.9% | 32.4 |
| T1 Adventure Mage/Wizard | 8 | 21.1% | 31.6 |
| T1 Adventure Healer | 9 | 23.1% | 30.8 |
| T1 Adventure Rogue | 13 | 30.2% | 27.9 |
| T1 Adventure Monk | 14 | 31.8% | 27.3 |
| T1 Adventure Warrior/Bard | 15 | 33.3% | 26.7 |
| T1 Raid Mage/Wizard | 13 | 30.2% | 27.9 |
| T1 Raid Healer (incl. Tome) | 15 | 33.3% | 26.7 |
| T1 Raid Warrior (armor only) | 21 | 41.2% | 23.5 |
| T1 Raid Warrior (+ Shield) | 28 | 48.3% | 20.7 |

Reads as a clean progression: a fully raid-geared main tank halves incoming damage, cloth sits around 30%, and the *shield is the single biggest defensive item in the game* — which matches its ✅ CANON stat line being the largest AC value in Tier 1.

✅ **RULED — Reading 3, and it was already the code.** Three readings of one canon sentence produce a 4× to 14× difference in tank survivability, and §3.2 above is the argument that settles it: under Readings 1 and 2 cloth gets *more* fragile as the tier progresses, because a flat subtraction — or a linear divisor — widens the absolute gap every time AC rises. Reading 3 is the only reading whose cloth clock is stable across tiers, which is the condition for cloth and tanks coexisting at all. Shipped in `sim/core/Formulas.gd` as `AC_READING = AcReading.CURVE`, `AC_K = 60.0`, `MITIGATION_CAP = 0.75`; pinned by `tests/unit/test_formulas.gd :: test_switches_are_single_named_constants` and `test_reading_3_curve_mitigation_at_three_ac_values`. Everything downstream (§9 boss budget) is computed under Reading 3 and stays re-derivable under the others: Readings 1, 1b and 2 above are the **rejected alternatives**, each still implemented behind `Formulas.damage_after_ac_under()` under the enum member named in §3.3 — Reading 1 is `FLAT_TWO_PER_POINT`, Reading 1b `FLAT_HALF_AC`, Reading 2 `DIVISOR` — and each is asserted at §3.1's canon AC values against §3.2's own window-proof rows, so the arithmetic that rejected them can be re-run rather than taken on trust. See [doc 15 Q-01](15-open-questions.md#q-01) (struck) and [doc 15 BL-60](15-open-questions.md#bl-60), which records the ruling and the reason it went unrecorded for four milestones.

## 4. Power

✅ CANON: "Power = +1 melee dmg" (canon: raw notes, "Stat definitions"). Unambiguous: 1 Power = 1 point added to melee damage before class coefficients.

✅ CANON, and load-bearing: **Power appears on no Tier 1 Adventure armor piece.** The transcription states it explicitly (canon: ideaboard §5, "Power column is empty (`—`) on every Tier 1 Adventure armor piece; Power only begins appearing on Tier 1 **Raid** armor"). The only Adventure-tier Power source is ✅ CANON "Adventures Charm of Power — +2 Power" (name reproduced verbatim, including the missing apostrophe).

🔷 PROPOSED interpretation — *why this exists: it turns an itemization observation into an explicit design rule the whole item set can be generated from.*

> **Adventure gear buys survival. Raid gear buys power.** Adventure tiers grant AC/HP/Mana only; Power is the stat that marks a raider as raid-graduated. A melee raider's entire pre-raid offensive progression is weapon + trinket.

Total Power available at Tier 1 Raid, summed from the ✅ CANON tables:

| Class | Head | Chest | Legs | Feet | Capstone | Total Power |
|---|---|---|---|---|---|---|
| Warrior | +1 | +2 | +1 | — | +1 (Shield) | **+5** |
| Bard | +1 | +2 | +1 | — | — (Instrument is +20 Mana) | **+4** |
| Monk | — (Raider's Headband) | +2 | +1 | — | ❓ (Final Headband, no stats) | **+3** |
| Rogue | +2 (Raider's Eyepatch) | +2 | +1 | — | ❓ (Final Eyepatch, no stats) | **+5** |
| Cleric / Druid / Shaman | — | — | — | — | — | **0** |
| Mage / Wizard | — | — | — | — | — | **0** |

Two things fall out of the canon tables that are worth the designer's eye (both flagged in §13, not corrected here): Monk's Raider's Headband is the only Boss 3 head piece with no Power, and Rogue's Raider's Eyepatch is the only one with +2 rather than +1.

🔷 PROPOSED: Power is melee-only, per canon's literal wording. It does nothing for Mana-based output. The Warrior Shield carrying +1 Power is therefore a genuine offensive item for a tank, not a rounding artifact.

## 5. Mana — the live design question

✅ CANON, verbatim, twice: "Mana = spell damage (Subject to change)" and, on healer weapons, "Class-specific healer weapons (Will have mana or power unsure how much) **we need to discuss if we want to have 2 variables or not.** Stats TBD until we establish the healing/Mana formulas." (canon: raw notes, "Weapons (Tier 1 Adventure)").

❓ OPEN by explicit designer request. Two models:

### 5.1 Model A — one variable: Mana is a power stat

Mana multiplies spell damage and healing output. There is no pool, no cost, no regeneration.

| Consequence | Detail |
|---|---|
| Healer gameplay | **Healers have no resource management at all.** Every heal is free, every round, forever. A healer's only decision is target selection, and their only failure mode is a mistake roll. |
| Cleric's canon niche breaks | ✅ CANON describes Cleric as "Efficient single-target healing". Efficiency is meaningless without a cost. Under Model A, Cleric and Shaman differ only in shape, not efficiency. |
| Itemization | Zero work. Every ideaboard table stays valid exactly as transcribed. |
| Bard | ✅ CANON note survives cleanly: *"Bard uses the same Warrior/Bard armor, so **Mana can appear on these pieces and compete with Power**"* — a real either/or choice between song strength and melee damage. |
| UI | One bar (HP). Simplest possible readout, consistent with canon's stated preference for morale: "one number, one state, one effect". |

### 5.2 Model B — two variables: Mana is a pool, plus a new power stat

Mana becomes a spendable resource; a second stat (unnamed in canon — "Spell Power"?) drives magnitude.

| Consequence | Detail |
|---|---|
| Healer gameplay | Real triage: overhealing is punished, big heals are rationed, "the Cleric is out of mana at 20%" becomes a story beat. Cleric's "Efficient" niche becomes mechanically true. |
| Itemization | **Every armor piece in both ideaboard tables needs a new column.** 8 armor families × 4 slots × 2 tiers, plus off-hands, instruments and trinkets. Doc 09 grows by a full stat. |
| Contradicts canon phrasing | "Mana = spell damage" directly states Mana *is* magnitude. Model B repurposes the word. |
| Bard | The Bard Instrument's ✅ CANON +20 Mana becomes a *pool* bonus, which for a support class with no obvious spend is a dead stat unless songs cost mana. |
| UI | Two bars per healer, plus a regeneration rule, plus per-spell costs — a system doc of its own. |

### 5.3 Recommendation — the owning decision for canon's "2 variables" question

**This section is where canon's *"we need to discuss if we want to have 2 variables or not"* is resolved for the whole doc set.** Four docs currently answer it four different ways and they are not compatible:

| Doc | Current answer |
|---|---|
| [06 — Classes & Roles](06-classes-and-roles.md) Q1 | "Mana drives both spell damage and healing magnitude; **no fourth stat**." |
| [09 — Items & Itemization](09-items-and-itemization.md) OQ-4 | "**One variable: Mana.**" |
| [07 — Combat Simulation](07-combat-simulation.md) OQ-1 | "Mana is **both**: a pool that depletes and a magnitude stat. A wasted heal costs the pool." — and `MIS_HEAL_WRONG`, `MIS_HEAL_CORPSE`, `MIS_CHAIN_FIZZLE` plus the Mana cascade token are all built on "resource still spent". |
| §5.3 below | Model A+ — Mana stays magnitude, add class-fixed **Focus**. |

Docs 06 and 09 are consistent with each other; doc 07 assumes a pool that no doc supplies; Focus is a second resource by any reading. One answer has to propagate.

**DECIDED for 1.1 — [15 BL-87](15-open-questions.md#bl-87), 2026-09-15.** Model A+ is the ruling and its numbers are the table below; it ships in the first post-1.0 sim unit, not in 1.0. In 1.0 no pool exists in the sim (`Formulas.MANA_MODEL` names Model A+ and nothing spends it; `RaidSim.MANA_BURN_DRAIN_ENABLED := false`): healing is unlimited, an empty pool is never reached, M10 Mana Burn ships as its silence half only ([10 §10](10-content-and-encounters.md)), and the wasted-heal mistakes spend the round and their token, not a pool. The 1.1 unit must reproduce the 1.0 goldens byte-for-byte with Focus off (`MAGNITUDE_ONLY`).

**Model A+ (one gear stat, one class-fixed resource).** *Why this exists: it satisfies both canon statements — Mana stays "spell damage", and Cleric's "efficient" becomes real — without adding a column to a single existing item table.*

- **Mana** stays exactly as canon defines it: a power stat on gear, driving spell damage and heal magnitude.
- Add **Focus**, a per-encounter resource that is **class-fixed and never appears on gear**. Each caster/healer starts an encounter with `FOCUS_MAX[class]` and regenerates `FOCUS_REGEN[class]` per round. Each spell has a Focus cost.
- Cleric's ✅ CANON "Efficient single-target healing" is implemented as the lowest Focus-per-point-healed in the game. Druid's raid-wide heal is the most expensive per point but hits 12. Shaman sits between.

DECIDED-for-1.1 values (BL-87; single-encounter budget, tuned so a healer can heal at full rate for ~14 rounds and then must ration — at E5's 22 rounds the Cleric never runs dry (100 + 7 × 22 = 254 ≥ 198), the Druid rations from round 15, the Shaman from 21, so the "dry at 20 %" beat lands only on the tier's last boss):

| Class | FOCUS_MAX | FOCUS_REGEN /round | Primary spell cost | Focus per point healed/dealt |
|---|---|---|---|---|
| Cleric | 100 | 7 | 9 (single-target heal) | 0.28 |
| Druid | 100 | 7 | 14 (raid heal, 12 targets) | 0.14 (spread) |
| Shaman | 100 | 7 | 12 (chain heal, 3 targets) | 0.22 |
| Mage | 100 | 8 | 11 (AoE nuke) | — |
| Wizard | 100 | 8 | 10 (single-target nuke) | — |
| Bard | 60 | 5 | song-dependent (doc 06) | — |

The three riders, answered (BL-87): (1) a healer with no resource pressure is the 1.0 feel and Focus is the 1.1 pressure — nothing else in this doc changes either way; (2) Focus stays class-fixed and never appears on gear (Q-02); (3) the Bard's +20 Mana Instrument feeds song magnitude ([15 Q-46](15-open-questions.md#q-46)), not a pool. An empty pool heals at `HEAL_FLOOR` or hits for the staff alone with Mana counted as 0; a wasted heal spends its full cast and the Focus token (doc 07 §6's Mana token, renamed) doubles the next heal's cost; M10's drain is `drain` Focus per round on the record, default 10.

**Propagation contract — whichever branch is chosen, these edits land in other docs and nothing here changes:**

| Focus **ships** in 1.1 (Model A+, DECIDED) | Focus **off** — the 1.0 state, and the `MAGNITUDE_ONLY` branch the 1.1 unit must keep byte-identical |
|---|---|
| Doc 06 Q1: amend the default to "no fourth *gear* stat; one class-fixed resource (Focus, doc 08 §5.3)" — Focus is a fourth resource even though it never appears on an item. | Doc 07 OQ-1: change the default from "Mana is both" to "Mana is a magnitude stat only; a wasted heal costs the round, not a pool". |
| Doc 07: rewrite `MIS_HEAL_WRONG`, `MIS_HEAL_CORPSE` and `MIS_CHAIN_FIZZLE` so "resource still spent" spends **Focus**, and re-point the Mana cascade token at Focus. | Doc 07: re-rate those same three mistake types — doc 07 itself notes they "get much weaker" with no pool — and delete the Mana cascade token. |
| Doc 09 OQ-4: keep "one variable: Mana" for *gear*, and note Focus as a non-gear resource owned by §5.3. | Docs 06 / 09: no change; they are already correct. |

Doc 07's mistake effects must not be implemented against a Mana pool under either branch — no doc defines one.

## 6. HP — canon has none

✅ CANON gives `+HP` on nearly every armor piece and on "Adventure's Charm of Health — +7 Hp". ✅ CANON never states a base HP for any raider, class or rarity. Without a base, `+16 HP` is unscaled and unbuildable.

🔷 PROPOSED base HP by class. *Why this exists: it is the denominator for every survivability number in the game; nothing downstream can be tuned without it.* Chosen so that (a) the Warrior/Mage ratio is ~1.85:1, matching the AC ratio canon already implies, and (b) Tier 1 gear HP is a meaningful but not dominant share of the total (~11-13%), leaving room for tiers 2-5.

| Class | Role (canon) | Base HP 🔷 | + T1 Adventure armor ✅ | Total | + T1 Raid armor ✅ | Total |
|---|---|---|---|---|---|---|
| Warrior | Main Tank | 120 | +16 | **136** | +24 (+32 with Shield) | **144 / 152** |
| Monk | Melee DPS / Offtank | 100 | +14 | **114** | +22 | **122** |
| Bard | Support | 90 | +16 | **106** | +24 | **114** |
| Rogue | Melee DPS | 85 | +14 | **99** | +21 | **106** |
| Cleric | Main Tank Healer | 75 | +12 | **87** | +19 | **94** |
| Druid | Raid Healer | 75 | +12 | **87** | +19 | **94** |
| Shaman | Chain Healer | 75 | +12 | **87** | +19 | **94** |
| Mage | AoE Caster | 65 | +10 | **75** | +16 | **81** |
| Wizard | Single-Target Caster | 65 | +10 | **75** | +16 | **81** |

Mage and Wizard use the identical ✅ CANON Mage/Wizard armor family, so their defensive totals are the same; they differ only on weapon damage (+15 vs +16 at Raid tier).

Add ✅ CANON "Adventure's Charm of Health — +7 Hp" to any of the above if the trinket slot is spent on it.

### 6.1 Rarity and HP

❓ OPEN. ✅ CANON frames recruit rarity entirely as *mistake rate plus starting gear* — "raiders that have a small amount of experience, 1-2 pieces of basic adventure gear from your current raid tier" (Uncommon), "only make mistakes sometimes" (Rare), "rarely make a mistake" (Epic), "near 1% chance of mistake" (Legendary). Canon never says a Legendary raider has more HP.

🔷 PROPOSED — ship with rarity contributing **no** innate stats, and keep the hook:

```
max_hp = round(BASE_HP[class] * RARITY_HP_MULT[rarity])
RARITY_HP_MULT = { Common: 1.00, Uncommon: 1.00, Rare: 1.05, Epic: 1.10, Legendary: 1.15 }
```

Recommendation: set every entry to 1.00 for the first playable. A Legendary raider should be better because they *do not make mistakes*, not because they have a bigger health bar — that is the whole thesis of the game. If the designer wants Legendaries to feel physically superior, the values above are the suggested curve.

## 7. Derived stat sheet — real canon totals

Everything in this table is summed directly from the ✅ CANON ideaboard tables. No invented numbers. `Power` and `Mana` totals include the capstone where it has stats.

### 7.1 Tier 1 Adventure (full set, no trinket)

| Class | AC | HP (gear) | Power | Mana | Weapon |
|---|---|---|---|---|---|
| Warrior | 15 | +16 | 0 | 0 | Iron Adventurer's Sword +5 Damage |
| Bard | 15 | +16 | 0 | 0 | Iron Adventurer's Sword +5 Damage |
| Monk | 14 | +14 | 0 | 0 | Iron Adventurer's Staff +9 Damage |
| Rogue | 13 | +14 | 0 | 0 | Iron Adventurer's Sword +5 Damage (×2? see §13 Q9) |
| Cleric / Druid / Shaman | 9 | +12 | 0 | +13 | ❓ TBD (canon: stats TBD) |
| Mage | 8 | +10 | 0 | +17 | Apprentice's Firestaff +10 Damage |
| Wizard | 8 | +10 | 0 | +17 | Apprentice's Arcstaff +10 Damage |

### 7.2 Tier 1 Raid (full clear, armor + off-hand/capstone where statted)

| Class | AC | HP (gear) | Power | Mana | Strong weapon |
|---|---|---|---|---|---|
| Warrior | 21 (+7 Shield = **28**) | +24 (+8 = **32**) | +5 | 0 | Strong Raid Sword +8 Damage |
| Bard | 21 | +24 | +4 | +20 (Instrument) | Strong Raid Sword +8 Damage |
| Monk | 20 | +22 | +3 | 0 | Strong Raid Staff +14 Damage |
| Rogue | 19 | +21 | +5 | 0 | Strong Raid Dagger +6 ×2 = +12 |
| Cleric / Druid / Shaman | 13 (+2 Tome = **15**) | +19 | 0 | +27 (+5 Tome = **+32**) | ❓ TBD |
| Mage | 13 | +16 | 0 | +34 | Strong Raid Staff +15 Damage |
| Wizard | 13 | +16 | 0 | +34 | Strong Raid Staff +16 Damage |

## 8. Master formula set 🔷 PROPOSED

*Why this exists: this is the section a programmer implements. Everything here is expressed with named constants defined in §11 so a balance pass never edits code.*

### 8.1 Order of operations (normative)

```
1. Compute the attacker's raw output              (§8.2 / §8.3 / §8.5)
2. Apply variance and crit                        (§8.6)
3. Apply the target's mitigation                  (§3.3)
4. Apply flat shields/absorbs, then floor at 1
5. Subtract from HP; clamp at 0
6. Generate threat from step 2's value (pre-mitigation)   (§8.7)
```

Threat is generated from **pre-mitigation** damage so that a tank's own high AC does not starve their threat.

### 8.2 Outgoing melee damage

```
func melee_attacks(a) -> Array:
    # doc 07 owns how many attack windows a round grants; default MELEE_SWINGS = 2
    out = []
    for _ in range(MELEE_SWINGS):
        out.append(swing(a, a.main_hand, 1.00))
        if a.dual_wields:
            out.append(swing(a, a.off_hand, OFFHAND_COEF))   # 0.75
    return out

func swing(a, weapon, hand_coef) -> float:
    base = (weapon.damage * hand_coef) + a.power
    return base * CLASS_MELEE_COEF[a.class] * positional_mult(a)   # positional_mult: doc 07, default 1.0
```

`CLASS_MELEE_COEF` 🔷 PROPOSED: Warrior 1.00 · Monk 1.10 · Rogue 0.95 · Bard 0.55 · everyone else 0.00.

Note Power is added **once per swing**, not once per round. That is what makes Raid-tier Power the meaningful upgrade it looks like in §4.

**Worked example** — T1 Raid Rogue, Strong Raid Daggers (+6 / +6), Power +5:
```
main swing = (6 * 1.00 + 5) * 0.95 = 10.45
off swing  = (6 * 0.75 + 5) * 0.95 =  9.03
per round  = 2 * (10.45 + 9.03)    = 38.96  →  39 damage/round pre-mitigation
```

### 8.3 Outgoing spell damage

```
func spell_damage(a, spell) -> float:
    power = a.weapon.damage + (a.mana * MANA_TO_SPELL)      # MANA_TO_SPELL = 0.35
    return power * spell.coef * CLASS_SPELL_COEF[a.class]
```

`CLASS_SPELL_COEF` 🔷 PROPOSED: Wizard 1.60 (canon: "Very high single-target DPS") · Mage 0.60 **per target** (canon: "AoE Caster") · healers 0.25 (filler nuke) · Bard 0.00 (songs are doc 06).

**Worked example** — T1 Raid Wizard, Strong Raid Staff +16, Mana +34, Charm of Mana +10 → 44 Mana:
```
power = 16 + (44 * 0.35) = 31.4
cast  = 31.4 * 1.00 * 1.60 = 50.2 damage/round
```
Mage with the same Mana and a +15 staff: `30.4 * 0.60 = 18.2` per target — 18.2 on one target, **91** across five.

### 8.4 Incoming damage after AC

```
func mitigation(ac) -> float:
    return min(MITIGATION_CAP, (ac * 2.0) / ((ac * 2.0) + AC_K))    # AC_K = 60, cap 0.75

func take_damage(target, raw) -> int:
    dealt = max(1, round(raw * (1.0 - mitigation(target.ac))))
    dealt = apply_absorbs(target, dealt)
    target.hp = max(0, target.hp - dealt)
    return dealt
```

All four readings of §3.3 live behind **`damage_after_ac(raw, ac)`**, which is the single implementation; flipping `Formulas.AC_READING` is the whole edit. They are **not** drop-in replacements for `mitigation(ac)`, and saying they were is how two of the four settings shipped with no armour at all: a flat reading has no constant fraction, so `mitigation()` had nothing honest to return and returned `0.0`. It now returns `NAN` and `push_error`s under R1/R1b — valid only under the proportional readings (R3, R2). `mitigation_at(raw, ac)` is the reading-agnostic answer, measured *off* `damage_after_ac` rather than derived beside it, and new callers should prefer `damage_after_ac` outright. See [doc 15 BL-60](15-open-questions.md#bl-60).

### 8.5 Healing output, per canon healer archetype

```
func heal_power(h) -> float:
    return h.weapon.heal_base + (h.mana * MANA_TO_HEAL)      # MANA_TO_HEAL = 0.80
```

| Archetype | Canon description | Formula | Targets |
|---|---|---|---|
| Cleric — single target | "Efficient single-target healing" | `heal_power(h) * 1.00` | 1 (highest threat / lowest HP%) |
| Druid — raid-wide | "Small heal to the entire raid every round" | `heal_power(h) * DRUID_RAID_COEF` (0.25) | all 12 |
| Shaman — chain | "Medium → medium → small healing" | `heal_power(h) * [0.65, 0.65, 0.35]` | 3, in that order |

Shaman's `[0.65, 0.65, 0.35]` is the direct numeric encoding of ✅ CANON "Medium → medium → small". ❓ OPEN: canon does not say whether the chain can bounce back to an already-healed target, or whether it skips full-HP targets.

### 8.5a The tier-0 output floors — `HEAL_FLOOR` and `UNARMED_DAMAGE`

🔷 PROPOSED, and **implemented** — resolves [doc 15 BL-27](15-open-questions.md) and the blocker [doc 16 §E1.3](16-production-roadmap.md) predicted in writing.

✅ CANON gives common recruits *“Starting armor”*: four armour pieces, **no weapon**, and no HP or Mana on any piece. Every formula in §8 reads off gear, so a fresh guild dealt **exactly zero** damage and healed **exactly zero**. Measured consequence: Adventure 1 was unwinnable at any enemy HP, including 40% of its authored value — the party died rather than failing to kill.

| Constant | Value | Compared to the first real item |
|---|---|---|
| `UNARMED_DAMAGE` | **2** | the Tier 1 Adventure sword is `+5` damage |
| `HEAL_FLOOR` | **6** | the Tier 1 Adventure healing weapon is `heal_base` 14 |

```
effective_main_damage(w) = max(w, UNARMED_DAMAGE)      # main hand ONLY
heal_power(h)            = max(HEAL_FLOOR, h.weapon.heal_base + h.mana * MANA_TO_HEAL)
```

**They are floors, not addends, and that is the whole point.** Doc 16 §E1.3 asks for `heal = base_class + k × Mana`; a floor serves the same intent — a class can always do *something* — while changing **nothing** for anyone holding a weapon. Every validated geared number therefore stayed exactly where it was: E5’s first clear still lands on **22 rounds** against §9.2’s target of 22, and three of the five golden files regenerated byte-identical. Gear remains the entire progression story, which is what canon’s itemization thesis requires.

**Main hand only.** Applying the unarmed floor to an off-hand would hand every dual-wielder a phantom second weapon they never picked up.

---

**Worked example** — T1 Adventure healer, Mana +13, Charm of Mana +10 = 23 Mana, 🔷 PROPOSED weapon `heal_base` 14 (canon leaves this TBD):
```
heal_power = 14 + (23 * 0.8) = 32.4
Cleric:  32.4 to one target
Druid:   32.4 * 0.25 = 8.1 to each of 12  (97.2 total throughput, only useful if all 12 are damaged)
Shaman:  21.1 / 21.1 / 11.3               (53.5 total across 3)
```
T1 Raid healer, Mana +32 (armor + Tome) + 10 charm = 42, 🔷 PROPOSED `heal_base` 22:
```
heal_power = 22 + 33.6 = 55.6
Cleric:  55.6 · Druid: 13.9 ×12 = 166.8 · Shaman: 36.1 / 36.1 / 19.5
```

❗ Note for the balance pass: Druid's *total* throughput is the largest number in the table by far. That is an artifact of a 12-raid, not power — it only realises when the whole raid is damaged. `DRUID_RAID_COEF` is the lever (§11); do not raise it above 0.30 without re-checking the boss AoE budget.

❓ OPEN: healer weapon `heal_base` is invented here. ✅ CANON: "Class-specific healer weapons (Will have mana or power unsure how much) ... Stats TBD until we establish the healing/Mana formulas." The formulas now exist; the designer can set real values.

### 8.6 Variance and crit

❓ OPEN — canon is silent on both.

🔷 PROPOSED, with a recommendation to ship the conservative option:
```
DAMAGE_VARIANCE = 0.10          # ±10%, uniform
CRIT_CHANCE     = 0.05
CRIT_MULT       = 1.50
final = base * rand_range(1 - DAMAGE_VARIANCE, 1 + DAMAGE_VARIANCE) * (CRIT_MULT if roll_crit() else 1.0)
```
Recommendation: **ship with `DAMAGE_VARIANCE = 0.0` and `CRIT_CHANCE = 0.0` for the first playable.** This game's drama comes from mistake rolls and morale, not from damage dice. Deterministic damage makes the combat log readable, makes "why did we wipe" answerable, and makes every number in §9 exact rather than expected. Turn variance on later if fights feel mechanical.

### 8.7 Threat

```
func threat_from(a, pre_mitigation_damage, healing_done) -> float:
    t  = pre_mitigation_damage * THREAT_COEF[a.class]
    t += healing_done * HEAL_THREAT_COEF          # 0.50
    return t
```

`THREAT_COEF` 🔷 PROPOSED: Warrior **3.00** (canon: "High survivability, **high threat**") · Monk 1.50 (canon: offtank) · Wizard 1.00 · Mage 1.00 · Bard 0.50 · Rogue **0.80** (canon: "Position-dependent burst DPS" — rogues need to not be tanking) · healers 0.00 damage-side.

Target switch rule (arithmetic only; the rule itself is doc 07): the boss re-targets when `threat[candidate] > threat[current] * TAUNT_THRESHOLD`, with `TAUNT_THRESHOLD = 1.10` for melee-range candidates and `1.30` for ranged.

**Sanity check** — full T1 Raid clear, per round, trinket included (§9.1's After Boss 5 row): Warrior 30.0 dmg × 3.00 = **90 threat**. Wizard 50.2 × 1.00 = 50.2. Rogue 46.6 × 0.80 = 37.3. Cleric 55.6 heal × 0.50 = 27.8. The Warrior out-threatens the highest-DPS class by 1.79× per round and the gap compounds — a tank never loses aggro through arithmetic alone, only through a mistake or a mechanic. That is the correct feel for this game.

### 8.8 Mistake chance

✅ RULED — [15 Q-04 / Q-05](15-open-questions.md#q-04) (doc 08 owns the equation and every coefficient, importing doc 05's per-rarity `sensitivity`; the roll is per raider per roll site), [BL-20](15-open-questions.md#bl-20) (the coefficients), [BL-21](15-open-questions.md#bl-21) (the site weights). Published to the shipped equation 2026-09-15 (W7-DOCS; audit DW-D1/DW-D2). **Single owner, stated in writing.** This section owns the mistake-chance **equation** and **every coefficient in it**; `sim/core/Formulas.gd` holds them under the names below, and `tests/unit/test_canon_guard.gd` asserts that the tables here equal the code, so the doc and the sim cannot drift again. [05 — Morale](05-morale.md) owns the morale side — the ten bands, `band_delta` (its §5.2, imported here unchanged), the baseline and drift, every morale source, rarity resilience and the leave/disband rolls — and publishes no competing equation or coefficient; its §5.1-§5.4 point here.

The shape is doc 05's: a per-rarity `sensitivity` is a better encoding of ✅ CANON "legendary raiders will not be bothered by many things easily" than one flat multiplier per band, because a flat multiplier cannot express resilience that varies by rarity. Everything is in **basis points** (1% = 100 bp) so the outcome gates stay integer arithmetic (§12).

```
func mistake_chance_bp(rarity, morale, situational_bp = 0, facility_mult = 1.0, relief_bp = 0) -> int:
    band = morale_band(morale)                                     # doc 05 §2, half-open bands (Q-06)
    p  = MISTAKE_BASE_BP[rarity] * (1 + MORALE_BAND_DELTA[band] * MISTAKE_SENSITIVITY[rarity])
    p *= facility_mult                                             # Guildhall morale facilities (doc 03); default 1.0
    p += clamp(situational_bp, 0, SITUATIONAL_CAP_BP)              # live consequence tokens (doc 07 §6)
    p -= max(0, relief_bp)                                         # Potion of Steady Hands (doc 11 §7) — BEFORE the floor
    return clamp(round(p), MISTAKE_FLOOR_BP[rarity], MISTAKE_CEIL_BP[rarity])

func mistake_chance_at_site_bp(rarity, morale, roll_site, ...) -> int:
    return round(mistake_chance_bp(rarity, morale, ...) * ROLL_SITE_WEIGHT[roll_site])   # doc 07 §5.3's three sites
```

Order matters twice. The situational term is clamped to `[0, SITUATIONAL_CAP_BP]` **before** it is added, so a negative token can never lower the chance — which is why relief is its own term rather than a negative modifier. Relief is subtracted **before** the per-rarity floor, which is what ✅ CANON "All values above are have within tier limits for mistakes based on their tier" (canon: raw notes, Morale; quoted verbatim including the grammatical error) fixes: a potion steadies a panicking raider and cannot make a Common better than a Common. Gold buys back situational risk, never competence.

**The coefficients** — `Formulas.MISTAKE_BASE_BP`, `MISTAKE_SENSITIVITY`, `MISTAKE_FLOOR_BP`, `MISTAKE_CEIL_BP`. `base` is the chance at band 5 (Content, 50-60), which canon calls "Base mistake chance":

| Rarity | `base` (bp) | `sensitivity` | `floor` (bp) | `ceiling` (bp) | Canon anchor |
|---|---|---|---|---|---|
| Common | 2400 | 1.20 | 1200 | 8500 | "the worst players … 0 raid experience" |
| Uncommon | 1500 | 1.05 | 800 | 5000 | "a small amount of experience" |
| Rare | 800 | 0.90 | 500 | 2500 | "decent and only make mistakes sometimes" |
| Epic | 350 | 0.70 | 250 | 900 | "very good … rarely make a mistake" |
| Legendary | 120 | 0.50 | 90 | 250 | ✅ "basically perfect, near 1% chance of mistake" |

`MORALE_BAND_DELTA` is [05 §5.2](05-morale.md)'s `band_delta` column, imported unchanged: **+2.00 · +1.40 · +0.90 · +0.50 · +0.20 · 0.00 · −0.12 · −0.22 · −0.30 · −0.35** for bands 0-9 (the punishment side has ~6× the range of the reward side — the drama lives on the failure side). `SITUATIONAL_CAP_BP` = **2000** (doc 07 §6's +20 percentage points per raider). `ROLL_SITE_WEIGHT` = **0.55 action · 0.55 mechanic · 0.15 ambient** (BL-21, tuned against the balance sweep: with two rolls in a typical round each site needs about `1 − sqrt(1 − p)` for the per-round aggregate across sites to equal the published chance; ambient — going AFK, arguing in raid chat — is colour, not a second combat roll). The floors and ceilings are safety rails for tokens and facility effects, not tuning: no band reaches them.

**The effective matrix** (rarity × band, base and band only; no cell is clamped):

| Band | State | Common | Uncommon | Rare | Epic | Legendary |
|---|---|---|---|---|---|---|
| 0 | Very Upset | 81.6% | 46.5% | 22.4% | 8.4% | 2.40% |
| 1 | Upset | 64.3% | 37.1% | 18.1% | 6.9% | 2.04% |
| 2 | Unhappy | 49.9% | 29.2% | 14.5% | 5.7% | 1.74% |
| 3 | Annoyed | 38.4% | 22.9% | 11.6% | 4.7% | 1.50% |
| 4 | Slightly Annoyed | 29.8% | 18.2% | 9.4% | 4.0% | 1.32% |
| 5 | Content | 24.0% | 15.0% | 8.0% | 3.5% | 1.20% |
| 6 | Happy | 20.5% | 13.1% | 7.1% | 3.2% | 1.13% |
| 7 | Quite Happy | 17.7% | 11.5% | 6.4% | 3.0% | 1.07% |
| 8 | Very Happy | 15.4% | 10.3% | 5.8% | 2.8% | 1.02% |
| 9 | Loves Their Guild | 13.9% | 9.5% | 5.5% | 2.6% | 0.99% |

**What the clamps buy.** Legendary is strictly better than every other rarity in every morale state — worst Legendary 2.40% < best Epic 2.6% — which is ✅ CANON "you wont have to worry about losing your higher tier raiders unless you are BIG dumb", and a Loves-Their-Guild Legendary sits on canon's "near 1%" to the decimal. Below Legendary the adjacent tiers **overlap on purpose**: a Very Upset Epic (8.4%) is worse than a Loves-Their-Guild Rare (5.5%), and a miserable Rare (22.4%) is worse than a delighted Common (13.9%). Morale can invert more than one rarity step at the bottom of the ladder; that is what makes morale a decision rather than a cosmetic, and it is the direct reading of ✅ CANON "Lower tier raiders will be hardest to keep happy, while legendary raiders will not be bothered by many things easily". This doc's earlier "one step, never two" guarantee was given up for that reading ([BL-20](15-open-questions.md#bl-20); the numbers are in [15 Q-08](15-open-questions.md#q-08)).

**Effective DPS tax.** A mistake costs the raider their output for that round (plus whatever mechanic doc 07 attaches):
```
effective_raid_dps = sum over raiders of (nominal_dps * (1 - mistake_chance))
```
A raid of Content Commons runs at **76%** of nominal; a raid of Very Happy Epics at ~97%. **That spread is the game's core progression currency and it costs nothing in stats.** The on-ramp is sized under it — §9.3a's `TAX = 1 − mistake_chance(Common, 45)` = 0.702 ([BL-110](15-open-questions.md#bl-110)) — and the sim's site-weighted roll taxes a little less than the published chance, which [15 Q-100](15-open-questions.md#q-100) records as the expected first-pass reading.

## 9. Numeric sanity pass — the Tier 1 boss budget

*Why this exists: with base HP (§6), the mitigation curve (§3.3) and the formula set (§8) fixed, the boss numbers are no longer a design decision — they are a calculation. This section hands the designer the Tier 1 boss budget for free.*

🔷 PROPOSED reference raid composition (12, per ✅ CANON "I'd like the raid size to be 12, most fights normally requiring 2 tanks") — **[06 — Classes & Roles](06-classes-and-roles.md) §6.4 Template A, adopted verbatim so the doc set has one benchmark comp**: 2 Warrior · 1 Monk · 2 Rogue · 1 Bard · 1 Mage · 2 Wizard · 1 Cleric · 1 Druid · 1 Shaman. This is also [10 — Content & Encounters](10-content-and-encounters.md) §5.3's benchmark comp. Doc 06 owns comp *rules*; this is the yardstick every number below is measured against, and swapping one Monk for one Wizard moves the raid total by ~13, which moves every boss HP value in §9.2.

### 9.1 Nominal raid DPS at each gear stage

Melee assume `MELEE_SWINGS = 2`, casters 1 cast/round, healers contribute 0 damage. All gear values are ✅ CANON; the coefficients are 🔷 PROPOSED from §8. Trinket assumed Charm of Power (melee) / Charm of Mana (casters).

Two things the columns are built from, both ✅ CANON and both easy to lose: the Boss 4 **chest** pieces carry **+2 Power** (Raider's Cuirass / Raider's Vest / Raider's Leather Vest), so melee Power at Boss 4 is head+chest+legs+charm; and the caster **Mana** total advances every stage as the ideaboard replaces each Mage/Wizard slot — 27 → **30** (feet: Spellweave Slippers +3 → Raider's Slippers +6) → **34** (legs +4 → +8) → **38** (head +4 → +8) → **44** (chest +6 → +12), charm included. Wizard uses the Wizard staff line (+12 basic / +16 strong), Mage the Mage line (+11 / +15).

| Stage | Warrior ea. | Monk ea. | Rogue ea. | Bard | Wizard ea. | Mage (ST) | Caster Mana | **Raid total** |
|---|---|---|---|---|---|---|---|---|
| A — full T1 Adventure | 14.0 | 24.2 | 24.2 | 7.7 | 31.1 | 11.7 | 27 | **182.3** |
| After Boss 1 (feet + basic wpns) | 16.0 | 26.4 | 20.9 | 8.8 | 36.0 | 12.9 | 30 | **193.9** |
| After Boss 2 (legs + Tome) | 18.0 | 28.6 | 24.7 | 9.9 | 38.2 | 13.7 | 34 | **214.1** |
| After Boss 3 (head) | 20.0 | 28.6 | 32.3 | 11.0 | 40.5 | 14.6 | 38 | **239.7** |
| After Boss 4 (chest + strong wpns) | 28.0 | 41.8 | 46.6 | 15.4 | 50.2 | 18.2 | 44 | **325.0** |
| After Boss 5 (capstones; Shield only statted) | 30.0 | 41.8 | 46.6 | 15.4 | 50.2 | 18.2 | 44 | **329.0** |

**Adventure → full Raid clear = ×1.81 raid DPS**, and note where it comes from: melee gains **+100%** across the tier (Warrior 14.0 → 30.0) while casters gain **+61%** (Wizard 31.1 → 50.2). That asymmetry is the ✅ CANON design statement of §4 — Adventure gear buys survival, Raid gear buys Power — and the chest piece at Boss 4 is the single largest melee jump in the tier.

Note the Rogue row *drops* from 24.2 to 20.9 after Boss 1 — that is a real consequence of the canon numbers, flagged in §13 Q10.

### 9.1a Stage 0 and the Adventure stages — the rows doc 10 asked for

🔷 PROPOSED — *Why this exists:* [doc 10 §8](10-content-and-encounters.md) sized the whole Adventure tier against “half of stage A” (~88/round) while stating in writing that it was **an upper bound**, because stage A is *full* Tier 1 Adventure gear and Adventures are played below it. It then instructed: “Do not replace it with a locally invented figure; ask doc 08 for the stage.” These are those stages, measured rather than invented.

**Method:** identical to §9.1 above — **nominal** per-round output, pre-mistake-tax, summed over a fixed composition. The composition is the benchmark six that doc 10 §8 itself assumes: **1 Warrior, 1 Cleric, 2 Rogue, 1 Wizard, 1 Mage** (one tank, one healer, all three damage shapes). Mage is counted single-target, as §9.1 does.

| Stage | Gear | Warrior | Cleric | Rogue ea. | Wizard | Mage (ST) | **Party total (6)** |
|---|---|---|---|---|---|---|---|
| **0** | ✅ CANON starting armour — 4 pieces, no weapon, 0 Mana | 4.0 | 0.5 | 3.8 | 3.2 | 1.2 | **16.5** |
| **after A1** | + Adventure `feet` + first weapon | 10.0 | 1.5 | 9.5 | 17.7 | 6.6 | **54.9** |
| **after A2** | + Adventure `legs` | 10.0 | 1.8 | 9.5 | 19.9 | 7.5 | **58.2** |

**The headline number is stage 0 = 16.5, not 88.** Doc 10's figure was **5.3× too high** for A1, which is why Adventure 1 was unwinnable at every enemy HP down to 40% of the authored value.

**The first weapon is the largest single upgrade in the game**: 16.5 → 54.9 is a **3.3×** jump from one item per raider. That is the correct beat for a guild that owns no weapon at all, and it is what makes canon’s “1-2 pieces of basic adventure gear” at Known rank feel like a windfall rather than an increment.

**Stage 0 exists at all only because of §8.5a’s floors.** Before them every cell in the stage-0 row was literally **0.0**: canon starting armour is AC-only, and every formula in §8 reads off gear.

**Tank mitigation by the same stages**, since §9.3’s death clock assumed 7 AC / 120 HP throughout:

| Stage | Tank AC | HP | Mitigation | 42 raw becomes |
|---|---|---|---|---|
| 0 | 7 | 120 | 18.9% | 34.1 |
| after A1 | 9 | 123 | 23.1% | 32.3 |
| after A2 | 11 | 127 | 26.8% | **30.7** |

This matters for doc 10 §8’s A3 warning, which quoted **34.1** as A3’s single-target healing requirement. A3 is fought at the *after A2* stage, so the real figure is **30.7** — the warning overstated it by 11% by applying stage-0 mitigation to a fight nobody reaches in stage-0 gear.


### 9.2 Boss HP budget

Set against **nominal** DPS at the stage the boss is first attempted. The mistake tax (§8.8) is the difficulty dial on top: a Common-heavy roster clears ~32% slower than these round counts (Content Commons run at 76% of nominal).

"Raid DPS at attempt" is §9.1's raid total for the *previous* stage — the boss is fought in the gear the boss before it dropped. `Boss HP = DPS at attempt × target fight length`, rounded to the nearest 50.

| Boss | Raid DPS at attempt | Target fight length 🔷 | **Boss HP 🔷** | Rounds with a Content-Common roster (÷0.76) |
|---|---|---|---|---|
| Boss 1 (Trash) | 182 | 12 rounds | **2,200** | 15.9 |
| Boss 2 (Harder trash) | 194 | 13 rounds | **2,500** | 17.0 |
| Boss 3 (Mini boss) | 214 | 15 rounds | **3,200** | 19.7 |
| Boss 4 (Mini boss) | 240 | 17 rounds | **4,100** | 22.5 |
| Boss 5 (Main boss of tier) | 325 | 22 rounds | **7,150** | 28.9 |

Encounter names and star ratings are ✅ CANON (canon: raw notes, "Raid Layout and loot drops"); the HP values are 🔷 PROPOSED. Real names are pending — canon: "obviously they will need names later, but this is a placeholder".

### 9.3 Boss damage budget — tank channel

Main tank = Warrior, base HP 120, trinket Charm of Armor (+2 AC), gear advancing one slot per boss. Under Reading 3, `AC_K = 60`.

Every value in the **Boss auto raw** column is the output of the invariant below, rounded to the nearest integer — not hand-set. That is why the death clock is flat.

| Boss | Tank AC ✅+🔷 | Tank HP | Mitigation | **Boss auto raw/round 🔷** | Tank takes | Unhealed rounds to death |
|---|---|---|---|---|---|---|
| Boss 1 | 17 | 136 | 36.2% | **61** | 38.9 | 3.5 |
| Boss 2 | 18 | 137 | 37.5% | **63** | 39.4 | 3.5 |
| Boss 3 | 19 | 139 | 38.8% | **65** | 39.8 | 3.5 |
| Boss 4 | 21 | 141 | 41.2% | **68** | 40.0 | 3.5 |
| Boss 5 | 23 | 144 | 43.4% | **73** | 41.3 | 3.5 |

🔷 PROPOSED design invariant, the **3-round death clock**: a main tank with tier-appropriate gear and zero healing dies in 3.5 rounds at every boss in the tier. Tight enough that a healer mistake is felt immediately; loose enough that one mistake is survivable. Every boss's auto-attack is set from this invariant, not by hand:
```
boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK * (1 - mitigation(tank_ac)))
TANK_DEATH_CLOCK = 3.5
```
The clock is deliberately **flat**, not tightening: at Tier 1 the escalation from Boss 1 to Boss 5 comes from HP totals (§9.2), mechanic density (doc 07) and the AoE channel (§9.5), not from shortening the tank's survival window. A per-boss clock that tightens 3.9 → 3.4 is the alternative — it needs `TANK_DEATH_CLOCK` to become a per-encounter field rather than the single constant in §11, and doc 07 would own its cadence. ❓ OPEN if the designer wants the tank to feel progressively more fragile within one tier.

### 9.4 Healing supply vs demand

| Boss | Heal needed on tank | Cleric supply | + Shaman first bounce | Surplus | Verdict |
|---|---|---|---|---|---|
| Boss 1 | 38.9/round | 32.4 | +21.1 = 53.5 | +14.6 | Cleric alone is 17% short — Shaman must contribute. Intentional: solo-healing the tank must not work. |
| Boss 5 | 41.3/round | ~44 (partial raid gear) | +28 = 72 | +30.7 | Comfortable, leaving Druid free for AoE damage. |

This is the correct shape: the Cleric is *nearly* sufficient, which makes the third healer's mistakes matter.

### 9.5 Boss AoE budget — cloth channel

Under Reading 3, a boss auto aimed at cloth would kill a Mage in **1.6 rounds** at Boss 1 (48.2 taken vs 75 HP). Cloth must never be auto-attacked; that is what the threat system in §8.7 is for. Raid-wide pressure comes from AoE pulses sized off the *cloth* HP pool, not the tank's:

```
aoe_pulse_raw = (AOE_BITE_FRACTION * cloth_max_hp) / (1 - mitigation(cloth_ac))
AOE_BITE_FRACTION = 0.35
```
| Boss | Cloth AC / HP | **AoE pulse raw 🔷** | Cloth takes | Druid can out-heal it in |
|---|---|---|---|---|
| Boss 1 | 8 / 75 | **33** | 26.0 | 3.2 rounds of raid heal (8.1/round) |
| Boss 5 | 13 / 81 | **41** | 28.4 | 2.0 rounds (13.9/round) |

A 3.2-round recovery window at Boss 1 means AoE pulses cannot come more often than every ~4 rounds at Tier 1 without a second raid healer. Cadence is doc 07's call; the arithmetic above is the constraint.

### 9.6 Tiers 2-5 boss budget

**Generated, not authored.** Every number below is printed by
`godot --headless --path . --script res://tools/gen_items.gd -- budget`, which applies §9.1's
nominal-DPS method, §9.2's HP budget, §9.3's tank-channel invariant and §9.5's cloth channel
to the gear ladder in `docs/09` §13. Regenerate rather than edit: `tests/unit/test_tier_budget.gd`
reads this section back and fails if it stops agreeing with the rules that produced it.

**Tier 1 is in the table on purpose.** It is derived by exactly the same method as the other four
and lands on the numbers §9.2 and §9.3 already published by hand — 2200 / 2500 / 3200 / 4100 / 7150
boss HP, and 61 / 63 / 65 / 68 / 73 raw swing. That is the whole argument that Tier 2 is not a
different curve: the method reproduces the tier canon actually specifies, so the tiers above it are
the same shape continued rather than a new one invented. If a future change to the ladder breaks
that agreement, the Tier 1 rows here stop matching §9.2 and the test says so.

Three things worth reading out of the tables rather than leaving implied:

1. **The tank death clock holds at ~3.5 rounds across all twenty-five raid bosses.** That is §9.3's
   invariant, and it is what makes the raw-swing column a derivation rather than a taste: the swing
   is solved for, so that an unhealed tank always dies in the same number of rounds however much
   armour the tier has handed out.
2. **`MITIGATION_CAP` binds from Tier 5 Boss 1.** The Mit column reads exactly 75.0% for the whole
   of Tier 5, which means tank AC stops buying survivability there and the swing column is being
   solved against a constant. The cap is doc 15 Q-01's clamp; a Tier 5 pass should decide whether
   that is the intended shape of the last tier or whether the cap moves. This is the first place in
   the game where the clamp is not a safety rail but the actual binding constraint.
3. **The Adventure rungs are sized at their own stage, not the raid's.** docs/10 §8's corrected rule
   — Adventure tier N is played in tier N-1's gear — is what the Adventure tables apply, which is
   why their DPS column is far below the raid column of the same tier and why their clock column
   runs 5.5 / 4.3 / 3.5 rather than a flat 3.5: an Adventure party has one tank and one healer, and
   the rungs are deliberately gentler at the start of a tier.

**Names are not in this section and must not arrive in it.** The budget is arithmetic; the words
that would turn these rows into items are pending a designer (docs/09 §11.4, `data/tier_words.json`).

#### Tier 1 raid

| Boss | Raid DPS at attempt | Rounds | Boss HP | Tank AC | Tank HP | Mit | Raw/rd | Clock | Cloth AC/HP | AoE pulse | AoE grossed |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Boss 1 | 182.3 | 12 | **2200** | 17 | 136 | 36.2% | **61** | 3.49 | 8 / 75 | **26** | 33 |
| Boss 2 | 193.9 | 13 | **2500** | 18 | 137 | 37.5% | **63** | 3.48 | 9 / 76 | **27** | 35 |
| Boss 3 | 214.1 | 15 | **3200** | 19 | 139 | 38.8% | **65** | 3.49 | 10 / 78 | **27** | 36 |
| Boss 4 | 239.7 | 17 | **4100** | 21 | 141 | 41.2% | **68** | 3.52 | 11 / 79 | **28** | 38 |
| Boss 5 | 325.0 | 22 | **7150** | 23 | 144 | 43.4% | **73** | 3.48 | 13 / 81 | **28** | 41 |

#### Tier 2 raid

| Boss | Raid DPS at attempt | Rounds | Boss HP | Tank AC | Tank HP | Mit | Raw/rd | Clock | Cloth AC/HP | AoE pulse | AoE grossed |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Boss 1 | 359.7 | 12 | **4300** | 26 | 146 | 46.4% | **78** | 3.49 | 14 / 83 | **29** | 43 |
| Boss 2 | 379.3 | 13 | **4950** | 28 | 149 | 48.3% | **82** | 3.51 | 15 / 86 | **30** | 45 |
| Boss 3 | 408.8 | 15 | **6150** | 31 | 153 | 50.8% | **89** | 3.50 | 17 / 89 | **31** | 49 |
| Boss 4 | 438.3 | 17 | **7450** | 33 | 156 | 52.4% | **94** | 3.49 | 19 / 92 | **32** | 53 |
| Boss 5 | 563.8 | 22 | **12400** | 36 | 160 | 54.5% | **101** | 3.49 | 22 / 93 | **33** | 56 |

#### Tier 3 raid

| Boss | Raid DPS at attempt | Rounds | Boss HP | Tank AC | Tank HP | Mit | Raw/rd | Clock | Cloth AC/HP | AoE pulse | AoE grossed |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Boss 1 | 629.2 | 12 | **7550** | 40 | 164 | 57.1% | **109** | 3.51 | 24 / 96 | **34** | 60 |
| Boss 2 | 664.8 | 13 | **8650** | 43 | 169 | 58.9% | **117** | 3.51 | 27 / 100 | **35** | 66 |
| Boss 3 | 726.5 | 15 | **10900** | 47 | 175 | 61.0% | **128** | 3.51 | 30 / 105 | **37** | 74 |
| Boss 4 | 788.2 | 17 | **13400** | 51 | 180 | 63.0% | **139** | 3.50 | 33 / 110 | **39** | 81 |
| Boss 5 | 962.3 | 22 | **21150** | 56 | 188 | 65.1% | **154** | 3.50 | 38 / 113 | **40** | 90 |

#### Tier 4 raid

| Boss | Raid DPS at attempt | Rounds | Boss HP | Tank AC | Tank HP | Mit | Raw/rd | Clock | Cloth AC/HP | AoE pulse | AoE grossed |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Boss 1 | 1123.0 | 12 | **13500** | 64 | 195 | 68.1% | **175** | 3.49 | 42 / 118 | **41** | 99 |
| Boss 2 | 1197.1 | 13 | **15550** | 69 | 203 | 69.7% | **191** | 3.51 | 47 / 125 | **44** | 112 |
| Boss 3 | 1332.5 | 15 | **20000** | 75 | 214 | 71.4% | **214** | 3.50 | 53 / 132 | **46** | 128 |
| Boss 4 | 1460.3 | 17 | **24850** | 81 | 223 | 73.0% | **236** | 3.50 | 59 / 139 | **49** | 144 |
| Boss 5 | 1717.2 | 22 | **37800** | 90 | 236 | 75.0% | **270** | 3.50 | 67 / 147 | **51** | 166 |

#### Tier 5 raid

| Boss | Raid DPS at attempt | Rounds | Boss HP | Tank AC | Tank HP | Mit | Raw/rd | Clock | Cloth AC/HP | AoE pulse | AoE grossed |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Boss 1 | 2034.1 | 12 | **24400** | 102 | 248 | 75.0% | **283** | 3.51 | 74 / 155 | **54** | 188 |
| Boss 2 | 2200.0 | 13 | **28600** | 110 | 262 | 75.0% | **299** | 3.51 | 83 / 166 | **58** | 219 |
| Boss 3 | 2467.6 | 15 | **37000** | 121 | 279 | 75.0% | **319** | 3.50 | 94 / 179 | **63** | 251 |
| Boss 4 | 2727.7 | 17 | **46350** | 130 | 294 | 75.0% | **336** | 3.50 | 105 / 192 | **67** | 269 |
| Boss 5 | 3184.6 | 22 | **70050** | 143 | 318 | 75.0% | **363** | 3.50 | 118 / 205 | **72** | 287 |

#### Tier 2 Adventure

| Rung | Party DPS at its own stage | Rounds | Pull HP | Tank AC | Tank HP | Raw/rd | Clock | M02 pulse |
|---|---|---|---|---|---|---|---|---|
| A1 | 206.9 | 8 | **1650** | 24 | 144 | **47** | 5.5 | 19 |
| A2 | 247.8 | 10 | **2500** | 24 | 145 | **61** | 4.3 | 19 |
| A3 | 239.0 | 12 | **2850** | 24 | 145 | **75** | 3.5 | 19 |

#### Tier 3 Adventure

| Rung | Party DPS at its own stage | Rounds | Pull HP | Tank AC | Tank HP | Raw/rd | Clock | M02 pulse |
|---|---|---|---|---|---|---|---|---|
| A1 | 350.9 | 8 | **2800** | 37 | 160 | **65** | 5.5 | 22 |
| A2 | 407.3 | 10 | **4050** | 38 | 160 | **84** | 4.3 | 22 |
| A3 | 400.0 | 12 | **4800** | 39 | 161 | **106** | 3.5 | 22 |

#### Tier 4 Adventure

| Rung | Party DPS at its own stage | Rounds | Pull HP | Tank AC | Tank HP | Raw/rd | Clock | M02 pulse |
|---|---|---|---|---|---|---|---|---|
| A1 | 619.0 | 8 | **4950** | 58 | 188 | **100** | 5.5 | 26 |
| A2 | 701.6 | 10 | **7000** | 59 | 190 | **131** | 4.3 | 27 |
| A3 | 687.8 | 12 | **8250** | 60 | 191 | **164** | 3.5 | 27 |

#### Tier 5 Adventure

| Rung | Party DPS at its own stage | Rounds | Pull HP | Tank AC | Tank HP | Raw/rd | Clock | M02 pulse |
|---|---|---|---|---|---|---|---|---|
| A1 | 1126.0 | 8 | **9000** | 93 | 236 | **172** | 5.5 | 34 |
| A2 | 1241.0 | 10 | **12400** | 95 | 238 | **221** | 4.3 | 35 |
| A3 | 1215.7 | 12 | **14600** | 97 | 241 | **275** | 3.5 | 35 |

#### Family totals per rung (docs/09 §13.2 ladder)

| Family | r1 | r2 | r3 | r4 | r5 | r6 | r7 | r8 | r9 | r10 |
|---|---|---|---|---|---|---|---|---|---|---|
| warrior_bard AC/HP/Mana | 15/16/0 | 21/24/0 | 23/26/0 | 33/40/0 | 36/44/0 | 52/68/0 | 57/75/0 | 83/116/0 | 91/128/0 | 132/198/0 |
| monk AC/HP/Mana | 14/14/0 | 20/22/0 | 22/24/0 | 32/37/0 | 35/41/0 | 51/64/0 | 56/70/0 | 81/109/0 | 89/120/0 | 129/186/0 |
| rogue AC/HP/Mana | 13/14/0 | 19/21/0 | 21/23/0 | 30/36/0 | 33/40/0 | 48/62/0 | 53/68/0 | 77/105/0 | 85/116/0 | 123/180/0 |
| healer AC/HP/Mana | 9/12/13 | 13/19/27 | 14/21/31 | 20/33/64 | 22/36/74 | 32/56/152 | 35/62/175 | 51/96/359 | 56/106/413 | 81/164/847 |
| mage_wizard AC/HP/Mana | 8/10/17 | 13/16/34 | 14/18/39 | 22/28/80 | 24/31/92 | 38/48/189 | 42/53/217 | 67/82/445 | 74/90/512 | 118/140/1050 |

## 10. Progression curve 🔷 PROPOSED

*Why this exists: so tiers 2-5 can be generated from tier 1 rather than hand-authored, and so any generated item can be checked against a curve instead of a vibe.*

### 10.1 The measured Tier 1 Adventure → Tier 1 Raid jump (all ✅ CANON values)

| Quantity | Adventure | Raid | Multiplier |
|---|---|---|---|
| AC — Warrior/Bard armor | 15 | 21 | ×1.400 |
| AC — Warrior incl. Shield | 15 | 28 | ×1.867 |
| AC — Monk | 14 | 20 | ×1.429 |
| AC — Rogue | 13 | 19 | ×1.462 |
| AC — Healer armor | 9 | 13 | ×1.444 |
| AC — Healer incl. Tome | 9 | 15 | ×1.667 |
| AC — Mage/Wizard | 8 | 13 | ×1.625 |
| HP — Warrior/Bard | +16 | +24 | ×1.500 |
| HP — Monk | +14 | +22 | ×1.571 |
| HP — Rogue | +14 | +21 | ×1.500 |
| HP — Healer | +12 | +19 | ×1.583 |
| HP — Mage/Wizard | +10 | +16 | ×1.600 |
| Mana — Healer armor | +13 | +27 | ×2.077 |
| Mana — Mage/Wizard | +17 | +34 | ×2.000 |
| Weapon — Warrior | +5 | +8 | ×1.600 |
| Weapon — Monk | +9 | +14 | ×1.556 |
| Weapon — Mage | +10 | +15 | ×1.500 |
| Weapon — Wizard | +10 | +16 | ×1.600 |

**The canon numbers are remarkably consistent.** Three clean clusters emerge:

| Stat | Observed | 🔷 Canonical step |
|---|---|---|
| AC | 1.40 - 1.63 | **×1.50** |
| HP | 1.50 - 1.60 | **×1.55** |
| Weapon damage | 1.50 - 1.60 | **×1.55** |
| Mana | 2.00 - 2.08 | **×2.00** |
| Power | 0 → 3-5 | additive: `+1` per slot, `+2` on chest |

Mana scaling at double the rate of AC/HP is the standout. Under Model A (§5) that means caster output outruns tank survivability tier over tier. Either `MANA_TO_SPELL` must decay per tier or Mana's step must come down to ~1.55. ❓ OPEN — the ×2.0 Mana step is measurable in canon but it is not clear it was intentional.

### 10.2 Generated tier table

🔷 PROPOSED — one step of ×1.50 AC / ×1.55 HP / ×1.55 weapon per *half*-tier (Adventure N → Raid N → Adventure N+1 → …). **Mana steps ×2.00 once more from index 1 → 2, then ×1.55 like HP and weapon** — that is §13 Q8's proposed default ("keep canon's ×2.0 for T1→T2") made explicit, paired with `MANA_TO_SPELL` decaying 0.85 per tier so the doubling does not run away. Tier 1 Adventure is index 0.

| Index | Stage | Warrior AC | Warrior HP (gear) | Warrior weapon | Mage Mana |
|---|---|---|---|---|---|
| 0 | T1 Adventure | 15 ✅ | +16 ✅ | +5 ✅ | +17 ✅ |
| 1 | T1 Raid | 21 ✅ | +24 ✅ | +8 ✅ | +34 ✅ |
| 2 | T2 Adventure | 32 | +37 | +12 | +68 |
| 3 | T2 Raid | 47 | +58 | +19 | +105 |
| 4 | T3 Adventure | 71 | +90 | +30 | +163 |
| 5 | T3 Raid | 107 | +139 | +46 | +253 |
| 6 | T4 Adventure | 160 | +215 | +72 | +392 |
| 7 | T4 Raid | 240 | +334 | +111 | +608 |
| 8 | T5 Adventure | 361 | +517 | +172 | +943 |
| 9 | T5 Raid | 541 | +802 | +267 | +1462 |

If the designer instead rules that ×2.00 was an unintentional artifact of the Tier 1 tables, change §10.1's canonical Mana step to ×1.55, revise Q8's default to match, and the Mana column becomes 17 / 34 / 53 / 82 / 127 / 197 / 305 / 473 / 733 / 1136. Only one of the two may be written down.

At index 9, `mitigation(541)` = 94.7%, clamped to `MITIGATION_CAP` 0.75. **The cap binds from roughly index 5 onward** (`mitigation(107)` = 78.1%). Two options, ❓ OPEN:
- Raise `AC_K` per tier: `AC_K(tier) = 60 * 1.5^(index)`. This keeps mitigation percentages stable across the whole game and makes AC a *relative* stat — the standard MMO solution.
- Let the cap bind and let HP carry late-game survivability.

Recommendation: scale `AC_K` with the tier. It is one line and it means the §9 boss-budget derivation works unchanged at every tier.

## 11. Tuning levers

Every knob, its default, its safe range, and what breaks outside that range.

| Lever | Default | Safe range | Governs | Breaks if exceeded |
|---|---|---|---|---|
| `AC_K` | 60 | 40 - 120 (per tier) | Mitigation curve shape | <40: tanks near-immune at T1. >120: AC nearly worthless |
| `MITIGATION_CAP` | 0.75 | 0.60 - 0.85 | Late-tier ceiling | >0.85: 4× effective HP, healers idle |
| `MIN_HIT_FRACTION` | 0.10 | 0.05 - 0.15 | Floor under Reading 1 only | n/a under Reading 3 |
| `MELEE_SWINGS` | 2 | 1 - 3 | Melee vs caster DPS parity | 1: casters dominate. 3: Power scales too hard |
| `OFFHAND_COEF` | 0.75 | 0.50 - 1.00 | Rogue dual-wield value | 1.00: Rogue is 30% ahead of Monk |
| `CLASS_MELEE_COEF[Warrior]` | 1.00 | fixed (the reference) | Baseline everything else is measured against | — |
| `CLASS_MELEE_COEF[Monk]` | 1.10 | 1.00 - 1.25 | Monk DPS | >1.25: offtank out-damages pure DPS |
| `CLASS_MELEE_COEF[Rogue]` | 0.95 | 0.85 - 1.05 | Rogue baseline before positional | with positional 1.3× this is the real DPS check |
| `CLASS_MELEE_COEF[Bard]` | 0.55 | 0.40 - 0.70 | Bard damage floor | Bard's value is songs; keep low |
| `CLASS_SPELL_COEF[Wizard]` | 1.60 | 1.40 - 1.80 | Top single-target DPS | <1.40: canon "very high single-target" untrue |
| `CLASS_SPELL_COEF[Mage]` | 0.60/target | 0.45 - 0.75 | AoE throughput | >0.75: Mage beats Wizard on 3 targets |
| `MANA_TO_SPELL` | 0.35 | 0.20 - 0.50 | Caster gear scaling | >0.50: Mana ×2/tier makes casters run away |
| `MANA_TO_HEAL` | 0.80 | 0.60 - 1.00 | Healer gear scaling | >1.00: healers outgrow boss damage in one tier |
| `DRUID_RAID_COEF` | 0.25 | 0.18 - 0.30 | Raid-wide heal | >0.30: AoE pulses become free |
| Shaman chain | 0.65 / 0.65 / 0.35 | ±0.10 each | ✅ CANON "medium → medium → small" | first bounce must stay ≥ third |
| `THREAT_COEF[Warrior]` | 3.00 | 2.50 - 4.00 | Aggro stability | <2.50: Wizard steals aggro by round 6 |
| `HEAL_THREAT_COEF` | 0.50 | 0.25 - 0.75 | Healer danger | >0.75: healers pull off the tank |
| `TAUNT_THRESHOLD` | 1.10 melee / 1.30 ranged | 1.05 - 1.50 | Target-switch churn | <1.05: boss flickers between targets |
| `MISTAKE_BASE_BP[Common]` | 2400 | 1500 - 3000 | Early-game chaos level | >3000: unwinnable. <1500: no comedy |
| `MISTAKE_BASE_BP[Legendary]` | 120 | ✅ CANON-anchored | Endgame ceiling | canon: "near 1% chance of mistake" (0.99% at band 9) |
| `MISTAKE_SENSITIVITY` | 1.20 → 0.50 by rarity | 1.00 - 1.30 (Common) | How hard morale hits each rarity | Common above 1.30: 0-20 morale is a wall, not a joke |
| `MORALE_BAND_DELTA` | +2.00 … −0.35 (doc 05 §5.2) | ×0.8 on bands 0-2 at most | How much morale matters | wider: morale eclipses gear entirely; never edit one mid band (monotonicity) |
| `SITUATIONAL_CAP_BP` | 2000 | 1500 - 3000 | Ceiling on live-token panic (doc 07 §6) | >3000: one cascade is a wipe |
| `ROLL_SITE_WEIGHT` | 0.55 / 0.55 / 0.15 | measured, not tuned (BL-21) | Per-site share of the published chance | 1.00 everywhere: ~300 mistakes an encounter |
| `OVERKILL_MARGIN` | 15 | 10 - 25 | Damage at or beyond `current_hp + margin` kills outright, skipping Downed (doc 07 §7.1) | <10: cloth is never Downed, only Dead. >25: a Tier 1 raw swing (≈15 on cloth) never overkills |
| `TANK_DEATH_CLOCK` | 3.5 rounds | 2.5 - 5.0 | Boss auto-attack sizing | <2.5: one healer mistake = wipe |
| `AOE_BITE_FRACTION` | 0.35 | 0.20 - 0.45 | Boss AoE sizing | >0.45: cloth dies to two pulses |
| `DAMAGE_VARIANCE` | 0.0 (ship), 0.10 (later) | 0.0 - 0.20 | Log readability vs texture | >0.20: outcomes feel arbitrary |
| `CRIT_CHANCE` / `CRIT_MULT` | 0.0 / 1.50 | 0.0 - 0.15 / 1.3 - 2.0 | Burst spikes | high crit + flat AC = one-shot cloth |
| `RARITY_HP_MULT` | all 1.00 | 1.00 - 1.20 | Whether rarity gives stats | see §6.1 ❓ |
| `BASE_HP[Warrior]` | 120 | 90 - 150 | Everything survivability | changing this invalidates §9 wholesale |

## 12. Rounding, determinism and integer policy

🔷 PROPOSED — *why this exists: a sim-heavy game with a scrolling combat log must produce the same numbers twice or players cannot learn it.*

| Rule | Value |
|---|---|
| Internal arithmetic | 64-bit float throughout |
| Rounding point | Once, at the final damage/heal value, `round()` half-up |
| Damage floor | 1 (never 0 from a landed hit) |
| HP | Integer, clamped to `[0, max_hp]` |
| Mitigation | Float, never rounded, capped at `MITIGATION_CAP` |
| Mistake chance | Float, compared against a single RNG draw per raider per round |
| RNG | One seeded stream per encounter; log the seed with the encounter result so a wipe is reproducible |
| Stat summation | Integer sum of integer item stats; no fractional gear stats anywhere |

Order of RNG draws per round must be fixed (doc 07 owns the order) or the seed is worthless.

## 13. Open questions

Four things are left undecided by canon itself and are therefore **not** proposed here at all: healer weapon values (✅ CANON "Stats TBD until we establish the healing/Mana formulas"); the stat blocks for Raid Trinket, Final Headband, Final Eyepatch and the Boss 5 class weapons (✅ CANON lists them with no numbers); whether level-ups exist at all (✅ CANON "Train raiders < Maybe if we have level ups" — every formula in this doc is deliberately level-free so either answer works); and crafting-derived stats (✅ CANON "Crafting Supplies < Maybe"). Boss and encounter names stay as placeholders per ✅ CANON "obviously they will need names later".

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| 1 | Does "AC = 2 damage reduction" mean 2 damage **per point of AC**, or **1 damage per 2 AC**? | 4× swing in tank survivability; every boss number in §9 depends on it | ✅ **ANSWERED** ([doc 15 Q-01](15-open-questions.md#q-01), struck) — neither literal reading: the ×2-numerator curve, Reading 3, `AC_K = 60`, cap `0.75`, per §3.3. Shipped as `Formulas.AC_READING = AcReading.CURVE` |
| 2 | If flat reduction (Reading 1) is intended, how do cloth classes survive? At T1 Raid a hit that takes 8 rounds to kill the tank kills a Mage in 1.65 | Under flat mitigation there is **no** boss auto-attack value where the tank is threatened and cloth survives | ✅ **ANSWERED** ([doc 15 Q-01](15-open-questions.md#q-01), struck) — Reading 3, for exactly this reason. The contingency stands as the record of what a Reading 1 mandate would cost: cloth would need a separate damage channel and a hard rule that bosses never melee non-tanks |
| 3 | Is Mana a power stat or a resource pool? ✅ CANON: "we need to discuss if we want to have 2 variables or not" | Model B adds a stat column to every item table in doc 09 | Model A+: Mana stays power (canon), add class-fixed Focus as the resource. §5.3 is the owning section and carries the propagation contract for docs 06 / 07 / 09, which currently give three other answers |
| 4 | Is a healer with **zero** resource management the intended feel? | Cleric's canon niche "Efficient single-target healing" is unimplementable without a cost | No — ship Focus (§5.3), keep it off gear |
| 5 | What is base HP for each class? Canon defines none | `+16 HP` is meaningless without it; nothing can be balanced | Warrior 120, Monk 100, Bard 90, Rogue 85, healers 75, Mage/Wizard 65 |
| 6 | Does recruit rarity grant innate stats, or only mistake rate + starting gear? | Canon only ever describes rarity in terms of mistakes and gear | Rarity grants **no** stats; `RARITY_HP_MULT` all 1.00 |
| 7 | "All values above are have within tier limits for mistakes based on their tier" — do tiers strictly not overlap, or may morale invert one step? | Strict non-overlap makes the 10-band morale table inert for mid rarities | Loose clamps (§8.8): morale may invert exactly one rarity step, never two; Legendary always beats Epic |
| 8 | Should the ×2.0 Mana-per-tier step (measured from canon) be reduced to ~×1.55 to match AC/HP? | At ×2.0 with `MANA_TO_SPELL` fixed, casters outscale tanks every tier | Keep canon's ×2.0 for the index 1→2 step only, then ×1.55 (stated in §10.2), and decay `MANA_TO_SPELL` by 0.85 per tier |
| 9 | Does the Rogue equip **two** Iron Adventurer's Swords at Adventure tier? The slot matrix says Warrior/Rogue/Bard 1H in main **and** off hand; the weapon list gives one entry | Determines whether Basic Raid Daggers (+4/+4 = 8) are an **upgrade or a downgrade** from 2× +5 swords (10) | Yes, two swords — which makes Boss 1's Basic Raid Dagger a downgrade (see #10) |
| 10 | Basic Raid Dagger is +4; two of them total +8, below a dual-wielded Adventure loadout's +10. Intentional (daggers trade damage for speed/positional) or an oversight? | The first raid drop in the game being a downgrade is a bad first impression | Raise Basic Raid Dagger to +5 and Strong Raid Dagger to +7, **or** give Rogue extra swings — needs designer's call, not ours |
| 11 | Monk's Raider's Headband (Boss 3) is the only head piece with no Power; Rogue's Raider's Eyepatch is the only one with +2 rather than +1 | ±1-2 Power × 2 swings × whole tier is a real DPS gap between two classes sharing a gear family | Leave exactly as canon states; confirm both are intentional |
| 12 | Monk "Raider's Vest" and Rogue "Raider's Leather Vest" have identical stats (6 AC / +7 HP / +2 Power) but different names, while the slot matrix says Chest is a shared "Monk/Rogue" family | One item or two? Affects loot-table size and whether Monk and Rogue compete for the drop | One shared item with two display names is wrong; treat as **one** item, name TBD |
| 13 | "Worn Leggings" is **2 AC** on the Warrior/Bard starting set and **1 AC** on the Cleric/Druid/Shaman sets | Same item name, two values — a data-integrity problem the moment items become rows in a table | Two distinct items; the healer version needs its own name |
| 14 | Canon's morale bands overlap at every boundary (`0-10`, `10-20`, …) and 70-80 / 80-90 are **both** "Very Happy" with identical effect text | Ambiguous band lookup; two identical states is a UI problem | Lower-inclusive/upper-exclusive (`[0,10)`, `[10,20)` … `[90,100]`); rename one of the Very Happy bands |
| 15 | Encounter table says Boss 3 drops "Head + **stronger shared gear**" and Boss 5 drops "Class-specific + **trinkets**" (plural), but the per-class tables show head only at Boss 3 and one Raid Trinket at Boss 5 | Affects total items per tier and therefore the DPS-per-stage table in §9.1 | Per-class tables are authoritative; the summary table is shorthand |
| 16 | Does damage variance / crit exist at all? | Determines whether §9's numbers are exact or expected values | Ship at zero variance, zero crit; revisit after the first playtest |
| 17 | Can the Shaman chain heal bounce to an already-healed target, and does it skip full-HP targets? | Changes Shaman throughput by up to 35% | Never repeat a target; skip targets above 95% HP and pass to the next |
| 18 | Is `MELEE_SWINGS = 2` per round right, or does doc 07 want per-class attack counts? | The single biggest lever on melee-vs-caster parity | 2 for all melee; per-class counts are a later refinement |
| 19 | Does the 12-raid ✅ CANON size assume duplicate classes (only 9 exist)? §9's DPS totals assume 2 Warriors / 2 Rogues / 2 Wizards | The reference comp determines every boss HP value in §9.2 — one Monk↔Wizard swap moves the raid total by ~13 | Doc 06 §6.4 Template A, adopted verbatim in §9.1 and matching doc 10 §5.3: 2 Warrior (canon: "most fights normally requiring 2 tanks"), 1 Monk, 2 Rogue, 2 Wizard, 1 each of the rest. One benchmark comp across docs 06 / 08 / 10 |
| 20 | Should `AC_K` scale per tier so mitigation percentages stay flat, or should `MITIGATION_CAP` bind from tier 3 onward? | Decides whether tiers 2-5 can be auto-generated or must be hand-tuned | Scale `AC_K` by ×1.5 per half-tier index |
| 21 | Who owns the morale → mistake-chance conversion, and which of the two published equations is real? | Doc 05 §5.1 and §8.8 here give the same raider a 2× different answer (Very Upset Common: 81.6% vs 40.0%). It is the game's most important number and it currently has two values | §8.8 owns the equation and all coefficients; doc 05 keeps bands / drift / sources / leave rolls and points here. If doc 05's per-rarity `sensitivity` shape is preferred, import it *into* §8.8 rather than leaving the equation in two docs |
| 22 | Is the tank death clock flat at 3.5 rounds for a whole tier, or does it tighten within the tier? | Decides whether `TANK_DEATH_CLOCK` stays a single §11 constant or becomes a per-encounter field | Flat 3.5 (§9.3); escalation comes from boss HP, mechanics and the AoE channel instead |

## Related documents

- [05 — Morale](05-morale.md) — owns the canon morale bands, drift, morale sources and the leave/disband rolls; it supplies the *band*, this doc's §8.8 owns the equation and coefficients that convert that band into a mistake chance. See the ownership note in §8.8 — doc 05 §5.1-§5.6 currently forks both.
- [06 — Classes & Roles](06-classes-and-roles.md) — owns ability lists, the Bard's TBD songs, and the comp rules whose §6.4 Template A is §9.1's reference composition; read it for what each class *does* with the coefficients here.
- [10 — Content & Encounters](10-content-and-encounters.md) — §5.3's benchmark comp is the same 12 as §9.1; the boss HP and damage budgets here are the inputs to its encounter tables.
- [07 — Combat Simulation](07-combat-simulation.md) — owns round structure, targeting, positional rules and mechanic cadence; read it for the rules that call these formulas, and for the AoE cadence constrained by §9.5.
- [09 — Items & Itemization](09-items-and-itemization.md) — owns the item tables themselves; read it for what drops where, and to see the flagged canon inconsistencies in §13 resolved as data.
- [03 — Guild Reputation](03-guild-reputation.md) — owns which rarities appear at which reputation rank; read it to know which `MISTAKE_BASE_BP` row a given roster draws from.
- [02 — Town & Buildings](02-town-and-buildings.md) — owns guild upgrades that feed `facility_mult` in the mistake formula.
- [14 — Technical Architecture](14-technical-architecture.md) — owns the engine and RNG plumbing that §12's determinism policy depends on.
