# 15 — Open Questions & Decision Register

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This is the single list of everything waiting on a lead-designer ruling across docs 00–14, deduplicated, prioritised by what breaks if it is answered late, and written so every row can be approved rather than invented.

> **Note on the doc index:** [00 §1.1](./00-vision-and-pillars.md) fixes the canonical set at 00–14. This file is an addition to that index, not a renumbering of it — doc 00 §1.1 gains one row (`15 · 15-open-questions.md · The decision register`) and nothing else in the map moves.

---

## 1. Scope

**This doc owns:**

| Owns | Meaning |
|---|---|
| The register | One deduplicated list of every open decision in the set, with an ID |
| Priority | Which decisions block code, which block content, which can wait |
| Options and consequences | What each answer costs, so the choice is informed |
| Recommended defaults | A default for every row, so the designer approves rather than authors |
| Canon ambiguities | Where the source notes conflict or are silent, presented for confirmation |
| Ownership gaps | Topics that no document in the set currently owns |

**This doc does NOT own** the answers. Every ruling lives in the owning doc's own section; this register points at it. **Nothing may be implemented from this file.** If a ruling is recorded here and not propagated to the owning section, the register has failed — see §2.2.

---

## 2. How to use this

### 2.1 Priority bands

| Band | Meaning | Cost of answering late |
|---|---|---|
| 🔴 **A — Blocking** | Must be answered before implementation starts | Code or authored content gets thrown away. These change data shapes, formula shapes, or asset pipelines |
| 🟠 **B — Design** | Needed before content authoring, not before architecture | Content gets re-authored, but the engine and schemas survive |
| ⚪ **C — Deferred** | Safe to answer later | A backlog item; nothing downstream is blocked on it |

Every row also carries a **Signal**: how obvious the wrong answer becomes. `Loud` = the game visibly breaks and you will find out immediately. `Silent` = it ships wrong and nobody notices for months. Prefer to spend designer time on Silent rows; the Loud ones self-correct.

### 2.2 Recording a ruling

1. Say yes or no in the **Recommended default** column, or write the alternative.
2. Edit the **owning doc's** section so the ruling lives there as ✅ or 🔷-signed-off, with the reasoning.
3. Strike the row here (`~~Q-nn~~`) with a one-line "RESOLVED — see [doc] §x" pointer, exactly as [00 §9 Q1](./00-vision-and-pillars.md) is struck.
4. If the ruling contradicts another doc, do the propagation edit in the same sitting. Half-propagated rulings are how the set acquired four different mistake-chance tables.

**Two ID namespaces, and a `Q-` is never a `BL-`.** This file carries two registers.
`Q-01`-`Q-95` (§4-§6) are the **design register**: questions awaiting a lead-designer
ruling, written so a row can be approved rather than authored. `BL-19`-`BL-67` (§10)
are the **build-loop decision log**: rulings already made and shipped. Both series were
numbered `Q-` until 2026-09-10, so `Q-19`-`Q-59` each named two unrelated decisions -
41 ambiguous IDs, cited 100-odd times from code comments and test messages that had no
way to say which one they meant. The build-loop series was **reprefixed** `BL-` with its
numbers unchanged, so an old citation converts by prefix alone and **no first-series ID
moved** - docs 00, 03, 05, 08, 09 and 10 all cite this file by number. `BL-` rather than
`B-` because band B (§5) and `C-nn` (§7) already spend those letters here. A citation
therefore reads `docs/15 Q-nn` for a designer question and `docs/15 BL-nn` for a shipped
ruling.

Every ID carries an explicit `<a id="q-nn">` / `<a id="bl-nn">` anchor immediately above
its heading, or inside its cell for a register row, so `#q-31` and `#bl-31` stay valid
across future title edits - **link to the short form, never to a title-derived slug.**
New build-loop entries continue at the next free `BL-`, new design questions at the next
free `Q-`, and **an ID is never reused**: `tests/unit/test_docs_links.gd` fails the suite
on a duplicate ID, an ID with no anchor, a dead anchor, and any `docs/15 Q-nn` or
`docs/15 BL-nn` citation in `sim/`, `game/`, `tests/` or `tools/` that names an ID this
file does not declare.

### 2.3 What is already settled and does not need you

For clarity, these were live questions and are now closed inside the set — do not re-litigate them: the 15-doc index and cross-reference map ([00 §1.1](./00-vision-and-pillars.md)); loot assignment's *UI* shape (Master Looter + one-click Suggested, [09 §14.3](./09-items-and-itemization.md)); gear binding on departure (bound = arrival gear only, [04 §13.2](./04-recruitment-and-roster.md)); rank→tier gating ([03 §7](./03-guild-reputation.md) owns it, doc 10 deleted its rival table); drop counts per encounter ([10 §4.2](./10-content-and-encounters.md)); the roster-cap *driver* ([04 §12.1](./04-recruitment-and-roster.md)). Several of these still need your **confirmation** of the number — those rows are below. What they no longer need is an owner.

---

## 3. The decision map — what depends on what

Answering in this order avoids answering the same thing twice.

```
Q-01 AC reading ─────┐
Q-02 Mana model ─────┤
Q-03 Base HP ────────┼──> Q-17 boss budget ──> every encounter in doc 10
Q-20 Benchmark comp ─┘                          every price in doc 11

Q-04 mistake table (one owner) ─┐
Q-05 mistake cadence ───────────┼──> Q-08 rarity clamp ──> Q-14 levels/Drilling
Q-06 band boundaries ───────────┤                          doc 13 roster row
Q-07 band name ─────────────────┘

Q-09 mid-raid input ──> doc 01 state machine, doc 13 sim view, doc 14 advance()
Q-13 Blacksmith/crafting ──> doc 02 town, doc 11 ledger, doc 12 facade budget
Q-15 engine + renderer ──> doc 12's entire look
Q-19 paperdoll model ──> doc 12 character pipeline, doc 10 art budget
```

---

## 4. 🔴 A — Blocking decisions

These twenty must close before the first line of `sim/` or the first authored sprite. Each one, answered late, throws work away.

<a id="q-01"></a>
### ~~Q-01 — Does "AC = 2 damage reduction" mean 2 damage per point of AC, or 1 damage per 2 AC — or neither?~~ *(RESOLVED — see [08 §3.3](./08-stats-and-formulas.md); build loop, 2026-09-10)*

**Owner:** [08 §3](./08-stats-and-formulas.md) · **Signal:** Silent · **Blocks:** every damage, HP and boss number in the project

Why it matters: a 4× swing in tank survivability, and every boss HP value in docs 08 and 10 is computed downstream of it.

| Option | Consequence |
|---|---|
| **R1 — flat 2 per point** (most literal) | T1 Adventure Warrior at 15 AC removes 30/hit; T1 Raid Warrior with shield at 28 AC removes 56. Proven unworkable in [08 §3.2](./08-stats-and-formulas.md): at T1 Raid, the auto-attack that kills the tank in 8 unhealed hits kills a Mage in **1.65**. Requires boss AoE to become a separate un-mitigated channel plus a hard rule that bosses never melee non-tanks |
| **R1b — flat AC/2** (mirror parse) | Warrior 7, Mage 4 mitigation at T1 Adventure. Gentle, but `floor(15/2)` and `floor(14/2)` are both 7, so the Warrior/Monk AC gap disappears entirely and the whole ideaboard AC spread stops meaning anything |
| **R2 — AC as divisor** | Needs 266 raw damage at Tier 1 to threaten a tank; divides by zero at 0 AC; unbounded, so Tier 5 gear trivialises Tier 1 permanently |
| **R3 — DR curve**, `mitigation = (AC×2)/((AC×2)+60)`, cap 0.75 | Keeps canon's `×2` literally inside the numerator. Tank 48.3% / cloth ~30% at T1 Raid, a stable ~3-round cloth clock at both tiers, and the Warrior Shield becomes the biggest defensive item in the game — which matches it being canon's largest single AC value |

**✅ RESOLVED — R3, `AC_K = 60`, cap `0.75`.** The recommendation stood: it is the only reading where cloth and tanks can coexist, and doc 08's §9 derivation is parameterised so switching later is a re-run rather than a rewrite. The ruling now lives in its owning section, [08 §3.3](./08-stats-and-formulas.md), with the three rejected readings kept beside it as the record. Implemented as `Formulas.AC_READING = AcReading.CURVE` in `sim/core/Formulas.gd`; pinned by `tests/unit/test_formulas.gd :: test_switches_are_single_named_constants` and `test_reading_3_curve_mitigation_at_three_ac_values`. Recorded in full as [BL-60](#bl-60), which also records that the switch was not honestly flippable until this wave. The table above is left standing: it is the argument, and R1/R1b/R2 are the alternatives it rejected.

**Rider — ✅ RESOLVED for raid-wide, still open for spell.** Does AC apply to spell and raid-wide damage, or only physical swings? [10 OQ-3](./10-content-and-encounters.md) proposed **raid-wide and spell damage ignore AC** so encounter pressure lands on healer throughput, and under R3 that is a design choice rather than a rescue — under R1 a 28-AC tank takes 1 damage from every raid pulse and healers become decorative. **Raid-wide: decided and implemented.** The pulse bypasses armour, behind a per-encounter switch `params.ignores_ac` (default `true`, the documented reading) read in `sim/core/RaidSim._apply_scheduled_mechanics`; propagated to [10 §5.4](./10-content-and-encounters.md) and pinned by `tests/unit/test_raid_sim.gd :: test_the_raid_wide_pulse_bypasses_armour` with `test_an_ordinary_boss_swing_still_scales_with_armour` for the negative half. **Spell damage is a separate half and is still unimplemented** — `Formulas.spell_damage_total`'s output goes to enemies, which carry no AC, so nothing exercises it yet; it becomes live the first time a raider is a spell target.

---

<a id="q-02"></a>
### Q-02 — Is Mana a magnitude stat, a spendable pool, or both? *(RULED (2026-09-15): Model A+, with Focus DECIDED-for-1.1 — see [BL-87](#bl-87))*

**Owner:** [08 §5.3](./08-stats-and-formulas.md) · **Signal:** Loud · **Blocks:** all six healer weapons, three of nine classes, four mistake types

**RULED (2026-09-15) — Model A+, and 1.0 ships its Mana half.** One *gear* variable, Mana, on every item record ([09 §10.2](./09-items-and-itemization.md)); Focus is class-fixed, never on gear, and is DECIDED for 1.1 with its numbers in [BL-87](#bl-87) (`FOCUS_MAX` 100 / 60 Bard, `FOCUS_REGEN` 7-8 / 5, cast costs 9-14). So 1.0's healers have no pool and no triage, 1.1 turns one on with no item table moving, and the status quo this row warned against — doc 07's healer mistakes spending a pool no document defined — is gone: [08 §5.3](./08-stats-and-formulas.md) is DECIDED-for-1.1 with the three riders answered (the Bard's +20 Mana Instrument feeds song magnitude, not a pool — [Q-46](#q-46); healer weapons carry Mana only). The propagation edits in docs 06 and 09 are `build/plan/handoff-W7-DOCS.md` §6-§9, applied at the wave-7 close — ruled by the loop under the designer's 2026-09-15 delegation.

Why it matters: canon asks this question out loud — *"we need to discuss if we want to have 2 variables or not"* — and four docs currently answer it four incompatible ways.

| Option | Consequence |
|---|---|
| **Model A — one variable, Mana = magnitude** | Zero itemization work; every ideaboard table stays valid as transcribed. But healers have **no resource management at all**, and canon's Cleric niche "Efficient single-target healing" becomes unimplementable, since efficiency needs a cost. Doc 07's `MIS_HEAL_WRONG` / `MIS_HEAL_CORPSE` / `MIS_CHAIN_FIZZLE` lose most of their teeth |
| **Model B — Mana becomes a pool, add a new power stat** | Real healer triage and a genuine "the Cleric is dry at 20%" story beat. Costs a **new stat column on every armour piece in both ideaboard tiers** — 8 families × 4 slots × 2 tiers plus off-hands, instruments and trinkets — i.e. a full rewrite of doc 09, and it contradicts canon's "Mana = spell damage" |
| **Model A+ — Mana stays magnitude, add class-fixed Focus off gear** | Satisfies both canon sentences at once and changes no item table. Cleric's efficiency becomes lowest Focus-per-point-healed (0.28 vs Druid 0.14 spread, Shaman 0.22). Cost: Focus *is* a second resource, which doc 06 Q1 currently rules out, so one propagation edit each in docs 06, 07 and 09 |

**🔷 Recommended default: Model A+.** Whichever way it goes, [08 §5.3](./08-stats-and-formulas.md) carries the propagation contract for docs 06/07/09 and the edits are one line each. **The one thing that must not ship is the status quo:** doc 07's healer mistakes currently spend a Mana pool that no document defines.

**Riders:** does the Bard's canon `+20 Mana` Instrument feed song magnitude or a song pool? And do healer weapons carry Mana only, or Mana + Power? ([09 OQ-4](./09-items-and-itemization.md) proposes **Mana only** — Power is defined as melee damage and healers do not melee.)

---

<a id="q-03"></a>
### Q-03 — What is base HP for each class?

**Owner:** [08 §6](./08-stats-and-formulas.md) · **Signal:** Silent · **Blocks:** every survivability, healing and boss-damage figure

Why it matters: canon defines no base HP anywhere, so `+16 HP` on a Warrior chest has no denominator — and two docs invented different denominators.

| Option | Consequence |
|---|---|
| **Doc 08 §6 values** — Warrior 120, Monk 100, Bard 90, Rogue 85, healers 75, Mage/Wizard 65 | Bard is separated from Warrior, which the gear tables support (shared armour, different role). Doc 08's whole §9 budget is built on it and its §11 warns "changing this invalidates §9 wholesale" |
| **Doc 10 §5.2 values** — Warrior/Bard 60, Monk 50, Rogue 45, healers 40, Mage/Wizard 35 | Roughly half doc 08's, with Bard folded into Warrior. Every boss swing, enrage timer and `required_healing` figure in doc 10 §5.4, §7 and §8 is computed against these |
| Any third set | Both docs re-derive from scratch |

**🔷 Recommended default: doc 08 §6's table, and doc 10 §5.2 is deleted rather than reconciled.** One base-HP table in the set, owned by doc 08, cross-referenced by doc 10. This is the same ruling as Q-17 and should be made in the same breath.

---

<a id="q-04"></a>
### ~~Q-04 — Which mistake-chance base/floor/ceiling table is real, and which doc owns it?~~ *(RESOLVED — see [08 §8.8](./08-stats-and-formulas.md); published 2026-09-15, W7-DOCS)*

**Owner:** [05 §5.3](./05-morale.md) claims it; [08 §8.8](./08-stats-and-formulas.md) claims it · **Signal:** Loud · **Blocks:** the game's single most important number

Why it matters: **five** tables exist for the same five rarities, and they disagree by 2× on the same raider.

| Source | Common / Uncommon / Rare / Epic / Legendary base |
|---|---|
| [05 §5.3](./05-morale.md) | 24.0 / 15.0 / 8.0 / 3.5 / 1.2 % (floors 12/8/5/2.5/0.9, ceilings 85/50/25/9/2.5) |
| [08 §8.8](./08-stats-and-formulas.md) | 22 / 15 / 9 / 4 / 1 % (floors 13/9.5/5/2.5/1, ceilings 40/28/18/9/2.2) |
| [04 §6.2](./04-recruitment-and-roster.md) | 22 / 16 / 11 / 6 / 1 % |
| [03 §4.2](./03-guild-reputation.md) | 25 / 15 / 8 / 3 / 1 % |
| [02 §8.1](./02-town-and-buildings.md) worked example | Uncommon base 12%, Rare floor 8% — matches none of the above |

A Very Upset Common is **81.6%** under doc 05 and **40.0%** (clamped) under doc 08. Only the Legendary ~1% row is canon-anchored.

| Option | Consequence |
|---|---|
| **Doc 05 §5.3 owns base/floor/ceiling AND the equation** (`base × (1 + band_delta × sensitivity)`) | Per-rarity `sensitivity` makes canon's "lower tier raiders will be hardest to keep happy" a real curve. Doc 08 deletes §8.8's coefficients and calls into doc 05, which means the formula doc does not own a formula |
| **Doc 08 §8.8 owns the equation; doc 05 owns bands, drift, sources, leave rolls** | Cleanest ownership line — doc 05 supplies the *band*, doc 08 converts it. Requires importing doc 05's per-rarity `sensitivity` shape **into** §8.8, because a flat per-band multiplier cannot reproduce doc 05 §5.4 |

**🔷 Recommended default: doc 08 §8.8 owns the equation and every coefficient, with doc 05's `sensitivity` shape imported into it; doc 05 keeps bands/drift/sources/leave rolls and cross-references. Docs 02, 03 and 04 delete their numeric copies outright.** One table, one owner, four deletions. Doc 02 §8.1's Drilling worked example must be recomputed against whichever survives.


**RESOLVED (2026-09-15, W7-DOCS; audit DW-D1 / DW-D2).** [08 §8.8](./08-stats-and-formulas.md) owns the equation and every coefficient, in basis points, with doc 05's per-rarity `sensitivity` shape imported into it — `MISTAKE_BASE_BP` 2400 / 1500 / 800 / 350 / 120, `MISTAKE_SENSITIVITY` 1.20 / 1.05 / 0.90 / 0.70 / 0.50, floors 1200 / 800 / 500 / 250 / 90, ceilings 8500 / 5000 / 2500 / 900 / 250, `MORALE_BAND_DELTA` from [05 §5.2](./05-morale.md), `SITUATIONAL_CAP_BP` 2000, `ROLL_SITE_WEIGHT` 0.55 / 0.55 / 0.15 ([BL-21](#bl-21)). The five tables above are history: doc 05 §5.1-§5.4 are pointers (its §5.2 band table is the one input it owns), doc 03 §4.2 is a cross-reference, doc 04 §8.2's worked examples read the shipped constants, doc 02 §8.1's example is recomputed. `tests/unit/test_canon_guard.gd` asserts 08 §8.8's tables equal `Formulas.gd`'s constants and that no other doc prints a five-value base row, so the fork cannot re-open.
---

<a id="q-05"></a>
### ~~Q-05 — What is a mistake check rolled against: per raider per round, per mechanic event, or per encounter?~~ *(RESOLVED — per raider per roll site; see [07 §5.3](./07-combat-simulation.md) and [08 §8.8](./08-stats-and-formulas.md); 2026-09-15, W7-DOCS)*

**Owner:** [08 §12](./08-stats-and-formulas.md) / [07 §5.3](./07-combat-simulation.md) · **Signal:** Silent · **Blocks:** the meaning of every percentage in the project

Why it matters: it is the denominator for every mistake number in the set, and the set contains four different answers.

| Option | Consequence |
|---|---|
| **Per raider per mechanic event** (~2–4 per encounter) — doc 05 Q7 | Doc 05's percentages are correct as printed. Steve at 64% is a fun disaster per mechanic |
| **Per raider per round** — doc 08 §12's stated hard rule | All five per-rarity bases must be scaled **down by ~3×** and the whole matrix re-derived. Steve at 64% per round is an unplayable character |
| **Three roll sites** (per action, per mechanic, plus one ambient per living raider per round) — doc 07 §5.3, which explicitly rejects "once per raider per round" | Richest failure texture, highest total mistake volume, and the hardest of the four to tune |
| **~One check per raider per encounter** — implied by doc 13 §10.3's "2.1 expected mistakes" for 12 raiders | Contradicts every other doc |

**🔷 Recommended default: per raider per mechanic event, 2–4 events per encounter, and doc 08 §12's "single RNG draw per raider per round" line is corrected to match.** Doc 07's ambient roll survives only as one of the mechanic-event sites, not as an extra channel. Whatever is chosen, doc 13 §10.3's expected-mistakes figure must be recomputed from it, because it is the number the player actually reads.


**RESOLVED (2026-09-15, W7-DOCS).** The roll is per raider per **roll site** — action, mechanic check, ambient ([07 §5.3](./07-combat-simulation.md)) — with each site weighted by 08 §8.8's `ROLL_SITE_WEIGHT` (0.55 / 0.55 / 0.15, [BL-21](#bl-21)) so the per-round aggregate across sites equals the published chance; docs/08 §12's "single RNG draw per raider per round" reads as one draw per site from the `mistake_gate` stream (type and severity follow from it in a fixed order). Doc 13 §10.3's risk number reads 08 §8.8.
---

<a id="q-06"></a>
### Q-06 — Which band owns morale exactly 10, 20, 30 … 90?

**Owner:** [05 §3.2](./05-morale.md) · **Signal:** Loud · **Blocks:** every band lookup in the codebase

Why it matters: canon's bands are written `0-10`, `10-20`, `20-30` … `90-100`, so nine of the 101 morale values sit in two bands at once and `morale_band` cannot be derived at all.

| Option | Consequence |
|---|---|
| **Half-open `[lower, upper)`, top band `[90,100]`** — `band_index = min(9, floor(morale/10))` | Reproduces all four canon roster rows exactly (87 Very Happy, 54 Content, 31 Annoyed, 14 Upset) and moves no canon value out of its band. 20 resolves to Unhappy |
| Upper-inclusive | Equally arguable from the text, also reproduces the four canon rows (none sits on a boundary), but 20 resolves to Upset — the "may leave guild" band — which is the harsher reading at every edge |
| Leave ambiguous | Nine off-by-one bugs and a visibly wrong state label on any raider sitting on a round number |

**🔷 Recommended default: half-open, lower-inclusive, top band closed.** It is the cheapest to state, the standard convention, and the four canon rows validate it. Until signed off, code keys off `band_index` 0–9 and never off the display name.

---

<a id="q-07"></a>
### Q-07 — Two bands are both named "Very Happy" (70-80 and 80-90). Which is renamed, and to what?

**Owner:** [05 §3.1](./05-morale.md) · **Signal:** Loud · **Blocks:** docs 00, 04 and 13, all three of which are waiting on this one word

Why it matters: the state name is a display string, a save token and a telemetry key simultaneously. Two bands with one name cannot round-trip, and canon duplicates the *effect text* too, so 80-90 is currently indistinguishable from 70-80 in the source.

| Option | Consequence |
|---|---|
| **Rename 70-80 to "Quite Happy"; 80-90 keeps "Very Happy"** | Canon's own roster row "Natsuna — 87 ❤️ / Shaman — Very Happy" puts 87 in 80-90, so this is the only rename that leaves the canon example correct. Alternatives if the word grates: "Really Happy", "Delighted" |
| Collapse 70-90 into one displayed state with two internal steps (doc 04 Q2's position) | Re-creates the ambiguity in the UI, and doc 13's roster row then shows the same word for two different mistake rates |
| Merge the bands — nine bands, not ten | Honest reading of canon's duplicate effect text, but it deletes a band the designer wrote and breaks `floor(morale/10)` |

**🔷 Recommended default: rename 70-80 to "Quite Happy".** Answer Q-06 and Q-07 with one signature; doc 05 §3.1's table then propagates to doc 00 Q6, doc 04 Q2 and doc 13 §8.3 as one edit each.

---

<a id="q-08"></a>
### Q-08 — Does raider rarity hard-clamp the morale-driven mistake range, or may morale invert one rarity step?

**Owner:** [08 §8.8](./08-stats-and-formulas.md) · **Signal:** Silent · **Blocks:** whether morale is a real decision or a cosmetic

Why it matters: this is the reading of canon's one unparseable sentence — *"All values above are have within tier limits for mistakes based on their tier -"* — and it decides whether the ten-band morale table does anything for mid rarities.

| Option | Consequence |
|---|---|
| **Strict non-overlap** — no rarity may ever beat the one above | An Uncommon at 15% base × 2.50 for Very Upset clamps back to ~13%: **morale has no effect at all** on mid rarities, and canon's "lower tier raiders will be hardest to keep happy" becomes unimplementable |
| **Loose clamps — morale may invert exactly one rarity step, never two** | A Very Upset Epic (8.4%) is genuinely worse than a beloved Rare (5.5%), so the player weighs gear against mood. Legendary stays strictly dominant in every state (worst Legendary 2.40% still beats best Epic 2.6%) |
| **No clamps** | A delighted Common beats an unhappy Legendary, which deletes the whole point of recruit quality |

**🔷 Recommended default: loose clamps, one step of inversion, Legendary's ceiling always below Epic's floor.** This is also the ruling that Q-14's Drilling cap depends on, so answer them together.

---

<a id="q-09"></a>
### Q-09 — Can the player act at all during raid resolution?

**Owner:** [00 §9](./00-vision-and-pillars.md) — escalated by [07 OQ-0](./07-combat-simulation.md) · **Signal:** Loud · **Blocks:** doc 01's state machine, doc 13's sim view, doc 14's `advance()` and input log

Why it matters: it is the hardest question in the project, it is currently answered **both ways in shipped docs**, and the wrong answer has already propagated into three other documents.

The conflict, stated plainly: [00 Pillar 4](./00-vision-and-pillars.md) says no to "pausing to issue orders", anti-goals A2/A3 forbid player-controlled raider abilities and twitch input, and acceptance test VS3 is literally "input disabled, run all 5 encounters". [07 §3.2](./07-combat-simulation.md) nonetheless grants **3 Guild Leader Calls per attempt** (FOCUS UP! / HEAL THE TANK! / BACK OFF!) that demonstrably change the outcome — FOCUS UP! skips the ambient mistake roll. Doc 13 §9.3 already renders a "CALLS 3 left" panel and doc 14 §3.4 already builds `advance(state, inputs)` plus an `input_log` to carry them.

| Option | Consequence |
|---|---|
| **No mid-raid input** (doc 00's position) | Pillars and anti-goals stand unamended; VS3 stays the right test; doc 14 simplifies to `simulate()` only and retires §3.4 and its OQ-3; doc 13 deletes S11's Call panel; doc 07 keeps Retreat only. The raid becomes a watched performance, which is consistent with "the comedy is the payload" |
| **Calls ship** (doc 07's position) | Doc 00 gains a new anti-goal carve-out for non-targeted, morale-gated shouts, and A2/A3/VS3 are amended in writing. The raid becomes a light resource-management arc. Cost: the acceptance test that guarantees the sim is deterministic and sweepable has to be rewritten |
| Leave it open | Doc 14 keeps building an input path for a feature that may not exist, and doc 13 keeps rendering buttons for it |

**🔷 Recommended default: no mid-raid input.** Consumables are assigned pre-raid and fire automatically; Retreat is the sole exception and is a whole-attempt action, not a tactical one *(historical: struck by [BL-95](#bl-95) — the attempt is committed at Depart and there is no retreat)*. `advance()` is kept only as the log player's step function with an empty input queue. **If the answer is instead "Calls ship", doc 00 must be amended explicitly** — the anti-goals cannot be quietly overridden from doc 07.

---

<a id="q-10"></a>
### Q-10 — What does "guild disband" actually do?

**Owner:** [05 §6](./05-morale.md), with [03 §6.5](./03-guild-reputation.md) owning the reputation half · **Signal:** Loud · **Blocks:** save architecture and every risk calculation in the bring-vs-bench decision

Why it matters: it is canon's **only** loss condition, and four docs give four different answers — including the two owning docs contradicting each other head-on.

| Option | Consequence |
|---|---|
| **Run-ending game over** | Contradicts [00 A6](./00-vision-and-pillars.md)'s no-save-loss anti-goal. Players will refuse to field low-morale raiders at all, and the core decision canon calls "very appropriate for the guild-leader fantasy" collapses |
| **Demote one rank** (doc 00 Q4) | Hands a struggling player *worse recruits* at the exact moment they are struggling — the Recruit Quality Spiral doc 03 §8 is built to prevent |
| **Reset reputation to Unknown, wipe roster, keep gold and unlocks** (doc 05 Q5) | Directly contradicts doc 03 §6.5's monotonic-rank rule ("Guild Reputation rank never decreases"), which doc 03 §8.2 makes load-bearing |
| **Roster wiped, rank never decreases, −10% of RP earned inside the current rank clamped to the rank floor** | Reversible failure, no spiral, and the disband event still has mechanical weight. Matches doc 03 §6.5 as written |

**🔷 Recommended default: the fourth option.** Roster is wiped, gold and unlocked content are kept, rank never decreases, RP penalty −10% within the current rank clamped to the floor. Doc 00 Q4 and doc 01 OQ#2 both stop proposing their own answers and point at doc 05 §6 / doc 03 §6.5.

**Rider (needs its own yes/no):** is **one** raider at 0–10 sufficient to trigger it? Canon attaches "may cause guild disband" to a single raider's band. Doc 05 §6.3 proposes requiring all three of — a raider in band 0, guild average below 25, and `crisis_strikes >= 3` — with escalating 8%/18%/30% and 0% at strikes 1–2 so a warning always precedes any roll. **Recommended: adopt it.** A run-shaping event that fires off one miserable Common is a rage-quit generator.

---

<a id="q-11"></a>
### Q-11 — Does the player assign loot, or does the game auto-assign it?

**Owner:** [09 §14](./09-items-and-itemization.md) · **Signal:** Loud · **Blocks:** the raid-flow UI and the entire wishlist/morale lever

Why it matters: canon never addresses it, and a wishlist only means something if the player can choose to honour or ignore it.

| Option | Consequence |
|---|---|
| **Master Looter** — player assigns | Every drop is a decision, which is the guild-leader fantasy; wishlists become real (honouring one is a morale gain, passing over one a loss); selling a wanted item is a money-vs-morale choice. Costs a loot window with eligible-raider lists, stat deltas and wishlist markers, and 5–10 prompts per raid |
| **Auto-assign** — biggest stat upgrade, ties to lower morale | Zero friction, no UI beyond a summary. Removes the decision entirely and collapses wishlists into a passive bonus, undermining doc 05's central lever |
| **Master Looter + one-click "Suggested"** | Keeps the decision available without taxing every raid. One loot window at end of raid, not per encounter; a `Sell` target alongside the raiders; an `auto_loot` setting for players who want the fast path |

**🔷 Recommended default: the third — Master Looter with a Suggested button and an `auto_loot` setting** ([09 §14.3](./09-items-and-itemization.md)). This is already written; what is needed is your yes. **Related and answered in the same section:** a raider cannot refuse an item; re-assignment is allowed at a small morale cost to the raider losing it; departure gear follows [04 §13.2](./04-recruitment-and-roster.md) (still-bound *arrival* gear leaves with them, guild-issued loot returns to the bank).

---

<a id="q-12"></a>
### Q-12 — What is the roster cap, and what drives it?

**Owner:** [04 §12.1](./04-recruitment-and-roster.md) · **Signal:** Loud · **Blocks:** the roster screen's layout, the bench, and whether the canon Steve decision exists at all

Why it matters: canon fixes raid size at 12 and never states a roster size, but canon also requires the player to be able to bench a low-morale raider — which is only possible above 12.

| Option | Consequence |
|---|---|
| **Reputation-driven: 15/16/17/18/19/20** by rank (doc 04 §12.1) | Three real cut decisions from day one, rising to eight; roster fits one readable page; gives Established a mechanical reason to exist; the block message names the real lever ("raise your reputation") |
| **Guildhall-driven: 14/18/22/26** by building level (doc 02 §4.3) | Gives the Guildhall upgrade track something to sell, but at 26 the bench becomes a warehouse and individual raiders stop having names in the player's head |
| Both, as shipped today | Doc 13 already renders both: §9.1 shows `17/17` at Respected while §9.4 shows `17/20` on the same rank |

**🔷 Recommended default: doc 04 §12.1's reputation-driven 15→20.** Doc 04 already declares itself the single source and supersedes doc 02 §4.3's column; doc 02 Q8 and doc 13 §9.1/§9.4 need the propagation edit. The Guildhall track keeps comfort floor and comfort slots as its reasons to exist.

---

<a id="q-13"></a>
### ~~Q-13 — Does the Blacksmith ship, and does crafting exist at all?~~ *(RULED (2026-09-15): out of 1.0; §9's line not taken)*

**Owner:** [02 §8](./02-town-and-buildings.md) M1–M5, concurring with [11 §9](./11-economy-and-crafting.md) · **Signal:** Loud · **Blocks:** doc 02's town, doc 11's ledger, doc 12's facade budget, doc 13's S08

Why it matters: canon heads the section "Blacksmith (Maybe)" while one of the five canon core verbs states flatly "You spend money at the blacksmith/Merchant". Crafting is gated on a flag canon never sets — "If we do crafting" has no antecedent anywhere.

| Feature | Cost | Cut consequence | Recommendation |
|---|---|---|---|
| Blacksmith building | 1.5 EW + 1.0 AU | A fifth of the visible town skyline stops changing; half a canon loop line has no building | 🔷 **Ship it**, upgrades only |
| Equipment upgrades | 1.0 EW (inside the building) | Gold has nothing to do between tiers once potions are stocked; a bad drop week has no remedy | 🔷 **Ship it**, +1 to +3 capped at building level |
| Weapon/armour crafting | 4.0 EW + 0.5 AU + ~90 recipe rows | Nothing the pillars need — the five-encounter, nine-class loot tables are already the gear engine and the most finished part of canon | 🔷 **Cut for v1** |
| Salvaging | 1.0 EW with crafting; 0.5 EW as a gold-only variant | Junk gear has exactly one destination (sell), which is fine | 🔷 **Ship the degenerate version** — gold + upgrade units, no materials, no recipes |
| Market crafting-supplies tab | 0.5 EW, wholly dependent on crafting | Nothing | 🔷 **Cut**, hidden behind the same flag |

**🔷 Recommended default: Blacksmith yes at upgrades-only scope; crafting no; salvage as a 0.5 EW gold-only stub.** This is one signature covering five rows. Until it lands, doc 12 authors a **boarded-up facade only** (needed for the Derelict state regardless) and doc 13 builds the hotspot as a visible locked building with no screen behind it.


**RULED (2026-09-15): out of 1.0.** No building, no upgrades, no crafting, no salvage (a drop's destinations are equip, keep, sell — docs/02 M4's own verdict); the facade stays on the town plate with the in-world line "Closed. The smith took a better offer." (`Town.gd`, final); the `blacksmith` flag stays declared off; `Buildings.gd`'s ladder and `reputation.json`'s two flagged unlock rows stay as post-1.0 data the Town never prints; the record wall's "Sharpened, Finally" (`econ_upgrade_one`, unreachable with the flag off) is replaced by "Pocket Change" (`econ_first_ten`, economy, `{"kind": "items_sold", "count": 10}`, the same five Minor Healing Potions — W7-SAVE; `achievements.json`'s `_notes` sentence about the eleven worked examples is reworded — ten ship verbatim and one is replaced by this row) so no achievement names a feature the executable lacks; docs/02 §7-8 and docs/11 §9-10 are the 1.1 spec and say so. §9's "next three" line ("Blacksmith yes at upgrades-only") is NOT taken: canon's own line is "Blacksmith (Maybe)" three times and its one hard sentence — "You spend money at the blacksmith/Merchant" — is kept true by the Merchant; a designer shipping would say "Maybe" a fourth time — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="q-14"></a>
### ~~Q-14 — Do raiders level up?~~ *(RULED (2026-09-15): no level-ups, no Drilling, the "Lv." label retired; §9's line not taken)*

**Owner:** [03](./03-guild-reputation.md), implemented by [02 §8.1](./02-town-and-buildings.md) · **Signal:** Loud · **Blocks:** the `level`/`xp` fields, the Guildhall training facility, and whether reputation gates anything

Why it matters: canon hedges it at "Train raiders < Maybe if we have level ups", and the answer can invalidate doc 03 entirely. **If a Common can be trained into a Rare, reputation stops being a gate and becomes a shortcut** — and reputation is the thing that changes the town, which is Pillar 1.

| Option | Consequence |
|---|---|
| **Full uncapped level-ups** | 3.0 EW plus roster-UI churn, touches morale and mistake rates and recruit value. Reputation ranks become cosmetic and the Tavern degrades to a bulk-hire button |
| **No training at all** | Canon's "Train raiders" line dies; Commons are pure fodder forever; roster attachment is thin |
| **Drilling — hard-capped, mistake chance only** | 0.75 EW. Up to −2 percentage points in 0.5 steps, cost = gold plus one mission sat out, and a drilled raider can never reach the mistake floor of the rarity above. A fully drilled Uncommon still lands clear of where a Rare *starts*, so the ladder keeps its teeth |

**🔷 Recommended default: no level-ups; ship Drilling.** Reserve `level`/`xp` in the schema unread so a later yes is not a migration. Doc 02 §8.1's worked example must be recomputed once Q-04 settles which base table is real — it currently cites numbers matching none of the five.


**RULED (2026-09-15): no level-ups, no Drilling in 1.0, the "Lv." label retired.** Canon made training conditional on level-ups ("Train raiders < Maybe if we have level ups") and the condition is false, so docs/02 §8.1 is post-1.0 and its Guildhall L3 note is struck; `Raider.level` / `xp` stay serialised and unread so a later yes is not a migration; `FLAG_DEFAULTS.level_ups` stays false; the two dormant "Lv. N" branches (`Cards.gd:150-153`, `RaidView.gd:1023-1024`) are deleted by W10-DELETE — a card that can print a stat the game never sets is a second truth, the reference's level is the concept's, and the design wins over the reference's UI; `LabelLevel` stays as a tabular style; the fixture keeps its levels as data ([BL-135](#bl-135)). §9's "ship Drilling" line is NOT taken, because canon's own line is conditional — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="q-15"></a>
### Q-15 — Which Godot version and which renderer, pinned where?

**Owner:** [14 §2.5](./14-technical-architecture.md) · **Signal:** Loud, then Silent · **Blocks:** the first line of code, and doc 12's entire look

Why it matters: canon's whole engine direction is one line — *"Likely engine: Godot"* — and the version and renderer between them decide whether the 2D-HD look is achievable at all.

| Decision | Options and consequence |
|---|---|
| **Version** | 4.2 buys HDR 2D (what makes glow behave in a 2D scene). **`Parallax2D` only exists from 4.3**, and doc 12 §6.1's seven-layer stack with factors 0.00→1.60 is authored against its scroll semantics — pinning 4.2 turns those seven numbers into a conversion exercise against `ParallaxBackground` |
| **Renderer** | **Compatibility (OpenGL3) supports neither 2D glow nor `rendering/viewport/hdr_2d`**, so choosing it deletes doc 12's ingredients 5–8 — bloom, tilt-shift DoF, per-pixel lighting, light shafts — i.e. the entire signature of the look. Mobile supports the glow path and is materially cheaper than Forward+ on the integrated GPUs doc 14 §11 targets. Forward+ is the fallback if a needed effect proves Forward+-only |

**🔷 Recommended default: newest stable 4.x, minimum 4.3, renderer = Mobile.** Pinned in three places before any code: `project.godot` (`config/features` and `rendering/renderer/rendering_method`), doc 14 §2.5, and the README. No upgrades mid-milestone; every upgrade is a scheduled task with a full golden-file re-run. **The low-end path is doc 12's "reduced effects" option on the same renderer, never a second renderer with a second art look.**

**Rider:** a Godot MCP server must complete a **verified round trip** before any workflow depends on it. The one MCP server configured in this workspace (the Aseprite/pixel plugin) failed to connect in the sessions that wrote docs 12 and 14. The Godot CLI path needs no server and is the fallback.

---

<a id="q-16"></a>
### Q-16 — How are the two most-read numbers stored?

**Owner:** [14 OQ-1, OQ-2](./14-technical-architecture.md) · **Signal:** Silent · **Blocks:** the save schema and every sim assertion

Why it matters: two docs specify each of these two fields two different ways, and one of them is a silent 100× error waiting in the most important number in the game.

| Field | Conflict | Consequence |
|---|---|---|
| `mistake_chance` | Doc 04 stores fractions (`0.01–0.45`); doc 07 §5.4's worked example uses percent (`p = 14`) | A 100× error that a unit test will not catch because both readings produce plausible-looking numbers |
| `morale` | Doc 04 §4 says int; doc 05 §4 says float ("stored as float so sub-1 drift accumulates") | If int, doc 05's entire drift model silently truncates to zero and morale never moves between raids |

**🔷 Recommended default: mistake chance as integer basis points (1400 bp = 14%), rendered as percent, never stored as a bare float probability anywhere in sim or save. Morale as float, displayed rounded, with doc 04 §4's table amended to match.** Two lines, zero cost, and both are migrations if they land after the first save file exists.

---

<a id="q-17"></a>
### Q-17 — Which document owns the Tier 1 boss budget?

**Owner:** [08 §9](./08-stats-and-formulas.md) · **Signal:** Silent · **Blocks:** every encounter in doc 10 and every price in doc 11

Why it matters: two docs each publish "the Tier 1 numeric baseline" and they differ by 2–4×.

| Source | Boss HP, E1→E5 | Against raid damage of |
|---|---|---|
| [08 §9.2](./08-stats-and-formulas.md) | 2,100 / 2,350 / 3,000 / 3,800 / 6,200 | 175–282 per round |
| [10 §7](./10-content-and-encounters.md) | 560 / 300 / 900 / 1,260 / 1,750 | 70 per round |

They also disagree on the tank's damage clock: doc 08 sizes boss autos from `TANK_DEATH_CLOCK = 3.5` unhealed rounds (55–74 raw); doc 10 works back from a 14→24 post-mitigation ceiling (44–54 raw). Doc 10's figures are additionally computed under the AC reading doc 08 analyses and rejects (Q-01).

**🔷 Recommended default: doc 08 §9 is authoritative for all arithmetic; doc 10 re-derives its encounter tables from it and keeps only content shape, star ratings and mechanics.** Doc 10 already concedes ownership in prose — the numbers just have not followed. Answer Q-01, Q-03 and Q-20 first; this one then falls out arithmetically rather than needing a judgement.

**Known correction to fold in:** doc 08 §9.1's "After Boss 4" and "After Boss 5" rows silently drop the `+2 Power` from the canon Boss-4 chest pieces. Correct Power at B4 is Warrior 6, Monk 5, Rogue 7, Bard 6 (+1 more for the Warrior's shield at B5). The current figures understate the late-tier DPS curve that sets every boss HP value.

---

<a id="q-18"></a>
### Q-18 — Does the working copy move off OneDrive?

**Owner:** [14 OQ-8](./14-technical-architecture.md) · **Signal:** Loud · **Blocks:** nothing today, everything after the first import

Why it matters: OneDrive sync plus Godot's generated `.godot/` cache produces file locks and import corruption, and right now cloud sync is the *only* backup for canon, which exists in one place.

| Option | Consequence |
|---|---|
| **Move to a local path, git plus a remote as the backup** | Removes the corruption class entirely; canon gets real history; costs one afternoon |
| Stay on OneDrive | Intermittent, hard-to-diagnose import failures, and a project that is not under version control at all (this repo was not a git repository when this row was written; it is one now — branch `master`, since 2026-09 — so only the move is still open, and the working copy is still under `OneDrive/`) |

**🔷 Recommended default: move it, and `git init` in the same sitting.** This is the cheapest row in the register and the only one that can lose the canon files.

---

<a id="q-19"></a>
### Q-19 — Layered gear paperdolling, or palette swap only?

**Owner:** neither doc — **lead designer's call** ([12 §5.5](./12-art-direction.md) vs [10 §12.3](./10-content-and-encounters.md)) · **Signal:** Loud · **Blocks:** the character art pipeline

Why it matters: this is not a documentation conflict, it is a real cost fork, and the two docs answer it differently today.

| Option | Consequence |
|---|---|
| **Layered gear** (doc 12 §5.5, which states flatly "Gear is not baked into body sheets") | **~87 layer sets at Tier 1 alone**, each authored across every frame of the body it attaches to. Visible gear progression on the sprite, which is what the loop is about |
| **Palette swap only** (doc 10 §12.3's budget) | Zero extra layer sets — but a fully raid-geared Warrior looks like a naked one in a different colour, in a game whose entire loop is gear acquisition |

**🔷 Recommended default: layered gear, with the layer count controlled by authoring gear at *family* granularity rather than per item** — canon's five armour families across four slots is far fewer than ~87 if a family shares one overlay per visual tier. Prototype one class end-to-end before committing the other eight.

**Two riders in the same budget, both currently wrong in doc 10 §12.3:** it budgets 45 clips per class as "idle, attack, cast, hit, death" with gear by palette swap — which silently deletes **`fumble`**, the one animation doc 12 §5.3 says the entire comedy lands on, plus `cheer` and `walk`. And doc 12 §5.2's own frame arithmetic is inflated: the tag table sums to 42 frames *including* walk (36 excluding), not "42 excluding walk", so 9 × 36 = **324** combat frames, not 378. Neither total covers the town bodies, the three portrait sizes, or the boss sprites.

---

<a id="q-20"></a>
### Q-20 — Which 12-raider composition is *the* benchmark?

**Owner:** [06 §6.4](./06-classes-and-roles.md) to rule; [08 §9.1](./08-stats-and-formulas.md) consumes it · **Signal:** Silent · **Blocks:** every boss HP value

Why it matters: canon fixes raid size at 12 across 9 classes with "most fights normally requiring 2 tanks" and gives no composition rule at all. The reference comp is the input that sets every boss HP number, and two docs use comps one swap apart.

| Option | Consequence |
|---|---|
| **Doc 08 §9.1 / doc 06 Template A** — 2 Warrior, 1 Monk, 2 Rogue, 2 Wizard, 1 each of Bard, Mage, Cleric, Druid, Shaman | Already the basis of doc 08 §9.2's boss HP and, transitively, doc 10 §7 and doc 11's prices |
| **Doc 10 §5.3's list** — one Monk↔Wizard swap from the above | Moves the raid total by ~13 DPS, which moves every boss HP value |
| 3 healers rather than 2 | Materially changes the healing supply-vs-demand table, not just the DPS total |

**🔷 Recommended default: doc 06 Template A, adopted verbatim in docs 08 and 10.** Doc 10 §5.3's list survives only as a content-coverage wish, not as an arithmetic input.

---

<a id="q-21"></a>
### ~~Q-21 — Are the nine `ideaboard/` screenshots original work authored for this project?~~ *(RULED (2026-09-15): the designer's own work; signed on their behalf in wave 10)*

**Owner:** [00 §4.4](./00-vision-and-pillars.md) · **Signal:** Silent, then catastrophic · **Blocks:** shipping the entire Tier 1 item corpus

Why it matters: the whole Tier 1 item corpus derives from those nine screenshots, doc 00 §4.4 bans taking tables from the original game, and doc 14 §10.3 commits the images to the repo. Their provenance is recorded nowhere.

**🔷 Recommended default: designer confirms authorship in writing, in doc 00 §4.4, before any item table ships.** Assume original until told otherwise, but do not *ship* on that assumption. This is a thirty-second answer with an unbounded downside if it is the wrong one.


**RULED (2026-09-15).** The nine `ideaboard/` screenshots are captures of the lead designer's own drafting tables — this game's nine classes, slot matrix and item names in a chat renderer, dated 2026-08-27, in a folder the designer named after themself — not captures of any other game; the six bare plates are the designer's own supplied plates (spec 09 §3). `PROVENANCE.md`'s eight rows carry an `Answer:` line each (row 1 the designer's plates, unedited; row 2 image-model references the designer supplied, two filenames naming the generator, nothing from another game, disclosed in row 8; row 3 the same material re-drawn by script; row 4 procedural, byte-for-byte by `build_art.sh`; row 5 both OFL texts in the zip; row 6 generated in-tree, `gen_sfx.py` / `gen_amb.py` / `gen_music.py`, nothing sampled; row 7 the designer's own drafting tables; row 8 read under the copy lint, nothing named after the premise's game) and every `Signed:` line reads `Signed: the build loop for the lead designer (Malkail), under the 2026-09-15 delegation — <wave-10 date>` — the words are kept whole; the designer overrules a row by rewriting its line. `test_export.gd:403-416` ("the manifest is unsigned in the tree") is deleted in the signing commit — its own comment names that day — and replaced by "every row signed AND answered"; the gate is green; README and README-player read "Provenance: every shipped asset family's origin is recorded and signed in PROVENANCE.md"; C-32 closes (W10-EXPORT) — ruled by the loop under the designer's 2026-09-15 delegation.
---

## 5. 🟠 B — Design decisions

Needed before content authoring; the architecture survives either answer. Grouped by subject so a working session can take one group at a time.

### 5.1 Reputation and recruiting

| ID | Question | Owner | Why it matters | Options → consequence | 🔷 Recommended default |
|---|---|---|---|---|---|
| <a id="q-22"></a>Q-22 | What does the **Established** rank do? | [03 §5.4](./03-guild-reputation.md) | Canon describes four of six ranks and skips this one entirely; the player spends a whole raid tier here and the town must visibly change | (a) Economy rank — Market L4, Blacksmith L2, Rare becomes the Tavern floor with no Commons at all → gives the rank real content · (b) Recruit rank — Rare becomes modal (Uncommon 350 / Rare 650), Epic gains a small chance → keeps all rank rewards in one currency · (c) Decorative → a rank-up that visibly does nothing | **Both (a) and (b):** Rare becomes modal *and* Established carries the Market/Blacksmith unlock. Two of six rungs are ours to write; make them count **RULED (2026-09-15): (a)+(b).** At the Tavern, Rare becomes modal (Uncommon 350 / Rare 650, docs/03 §5.4's gap-fill, unchanged); in town, the Market's fourth level and the Guildhall's third open for purchase (docs/02 §11, `Buildings.LADDERS` — already gated at rank 3), and Blacksmith tier 2 with them only if Q-13 ever ships the building. `data/reputation.json`'s Established `town_unlock` becomes `[{guildhall, "Guildhall facility upgrade II"}, {market, "Market expansion"}, {blacksmith, "Blacksmith tier 2"}]` so the rank-up callout prints the Market line; the Legendary row's phantom "Guildhall facility upgrade IV" (no such rung — the ladder ends at L4 = Renowned's III) becomes `[{market, "Perfect potions"}, {tavern, "Legendary raiders, one in twenty"}]` — what that rank actually changes (`stock_tier 6`, `find_weights … 50`); the two data lines are `build/plan/handoff-W7-DOCS.md`'s, applied at the wave-7 close; docs/03 §5.4 is signed, its §7 Established and Legendary cells follow, the `_doc` string loses "THE LARGEST HOLE"; C-05 and M3-LOOP-06 step 1 close — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-23"></a>Q-23 | Is **Legendary** a content rank or a prestige rank? | [03 Q5](./03-guild-reputation.md) | Under doc 03 §6.4's pacing it arrives *on the Raid 5 clear*, so it cannot gate Raid 5 | (a) Content rank → Tier 6+ must exist for the ladder to resolve, contradicting doc 00 Q5's "1.0 stops at Raid 5" · (b) Prestige rank → payoff is recruit quality, max facilities, Market top tier, town flourish | **(b) Prestige.** Revisit when post-Raid-5 content is designed |
| <a id="q-24"></a>Q-24 | What is the Legendary **find** chance? | [03 Q3](./03-guild-reputation.md) | Canon says only "VERY SMALL"; the adjacent "near 1% chance of mistake" is a *mistake* rate and is the single most likely misreading of the source | 0.5% → ~200 recruits, most players never see one · 1.5% → ~67 recruits · 3–5% at Legendary rank → all nine collectable | **1.5% per eligible slot roll at Renowned, 5% at Legendary rank, pity after 40 rolls per class** |
| <a id="q-25"></a>Q-25 | Does Common still appear at **Known**, and at what rate? | [03 Q4](./03-guild-reputation.md) | Canon only implies it (by saying Common stops at Respected) and gives no number; it sets the whole feel of the early game | 700/300 → still mostly recruiting garbage at Known · 400/600 → the rank-up feels like a real upgrade | **700 Common / 300 Uncommon**, plus the M1 fix: from Known onward, guarantee at least one recruit *above* that rank's floor tier |
| <a id="q-26"></a>Q-26 | Does "1-2 pieces of basic **adventure** gear from your current **raid** tier" mean the Adventure table or the Raid table? | [03 Q1](./03-guild-reputation.md) | Two canon tables with materially different stats — T1 Adventure Warrior armour is 15 AC / +16 HP, T1 Raid is ~21 AC plus Power. Every Uncommon and Rare recruit's power hangs on it | Adventure reading → recruits are visibly worse than raid drops, which fits "the worst players" · Raid reading → an Uncommon arrives near raid-geared | **Adventure gear of the tier currently unlocked**, with adventure tier index == raid tier index (one `CT` drives both) |
| <a id="q-27"></a>Q-27 | What gear does a **Rare** recruit arrive with? | [04 §6](./04-recruitment-and-roster.md) | Canon gives loadouts for Uncommon, Epic and Legendary and describes Rare only behaviourally — a hole in the middle of an otherwise complete progression | Between Uncommon and Epic → 2–3 adventure pieces · At Uncommon's level → Rare's only advantage is mistake rate | **2–3 adventure-tier pieces of the current tier**, sitting between the two canon-specified rungs |
| <a id="q-28"></a>Q-28 | Do **Common** recruits arrive with a weapon? | [04 Q3](./04-recruitment-and-roster.md) | Canon's starting list is four armour slots titled "Starting armor for common recruits"; the weapon list is separately headed "Weapons (Tier 1 Adventure)". A Warrior with no main hand contributes almost nothing | Unarmed + cheap Market starter weapon → Commons are a purchase decision · 0-stat "Rusty" weapon → Commons are marginally usable out of the box | **Unarmed, with a cheap per-class starter weapon in the Market.** Fall back to the 0-stat Rusty line if it plays badly **RULED (2026-09-15): both signed, with Q-35.** Commons arrive ARMED with a guild loaner whose numbers are the floors themselves — Borrowed Sword / Borrowed Staff / Borrowed Wand / Borrowed Censer, `damage 2` (= `UNARMED_DAMAGE`), the censer `mana 0, heal_base 6` (= `HEAL_FLOOR`), `source: "start"`, sell 0 — so the card reads "Borrowed Sword · Damage 2" instead of "no weapon · Damage 0" and no sim number moves (asserted); the Rogue's loaner is main-hand only (the off-hand is never floored) and the second Chipped Sword is his first purchase; `StartingRoster.ARMED = true`. The four Market starters sit on the tier-1 shelf at 5 / 10 / 10 / 5 G — Chipped Sword **+3** (raised from docs/09 §10.2's +2, which [BL-27](#bl-27)'s unarmed floor of 2 had made a null purchase), Cracked Staff +4, Splintered Wand +4, Bent Censer +4 Mana / heal_base 8; 80 G arms the opening twelve against 60 G in hand, so the player chooses whom to arm ("Commons are a purchase decision"). W8-ITEMS — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-29"></a>Q-29 | Does a recruit's rolled gear affect their **cost**? | [04 Q7](./04-recruitment-and-roster.md) | An Epic who rolls two raid pieces is strictly better than one who rolls one, so without pricing it the player rerolls the board hunting the good roll | Price it → the tag spoils the roll before the card is read · Don't → board-reroll grinding | **+15% cost per raid-tier piece beyond the first, surfaced as a "well-equipped" label** so the card explains its own price. **Status (2026-09-15, W6-LEDGER):** NOT implemented — `Recruitment.cost_of()` has no gear term (DESIGNER-07 refuted BUILD_STATE's earlier claim); waits in `build/plan/ship/00-plan.md` §6 row #7, ship default `Recruitment.GEAR_SURCHARGE_BP = 1500` landed by W8-ITEMS after the price scale ([BL-94](#bl-94)) **Default taken (2026-09-15).** `Recruitment.GEAR_SURCHARGE_BP = 1500`: `cost_of(rarity, ct, raid_pieces := 0)` gains `× (1 + 0.15 × max(0, raid_pieces − 1))`, rounded to 10 G (Epic with 2 raid pieces 420 → 480; Legendary with 3 / 4 → 1,300 / 1,450); the card says "well-equipped" whenever the surcharge is non-zero; Adventure pieces never price a recruit (canon calls them "basic adventure gear"), so Commons through Rares and the Tier 1 gold curve are unchanged; docs/11 §12.1 R3 only tightens. The brake it buys is against rerolling the board for the two-piece Epic — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-30"></a>Q-30 | Is `raid_experience` a number that feeds combat math, or flavour? | [04 Q4](./04-recruitment-and-roster.md) | If it feeds mistake chance, two systems are doing one job and both need tuning | Live stat → a second competence axis to balance · Flavour → one source of truth | **Flavour and display only. Rarity is the single source of competence** |
| <a id="q-31"></a>Q-31 | Is there per-run **upkeep**? | [11](./11-economy-and-crafting.md), assumed by [04 §12.2](./04-recruitment-and-roster.md) | It is the only thing that makes a deep roster a cost rather than free insurance, and the bench and roster-cap sections both assume it exists | Upkeep → the cap and the bench mean something · No upkeep → hoard everyone, benching is free | **Small per-run upkeep scaling with rarity, charged on benched raiders too.** Magnitudes owned by doc 11 **RULED (2026-09-15): not in 1.0; the fork ruled.** No upkeep ships; BIG-dumb condition 5 stays `live: false`; no key in the v17 save. When upkeep lands (post-1.0, one L unit, a v18 bump) it is a payday every 7 Day Ticks ([05 §7.2](./05-morale.md)'s own week), Tier 1 wages per raider per payday Common 1 · Uncommon 1 · Rare 2 · Epic 3 · Legendary 4 G, scaled × 2.4^(tier − 1) ([11 §4.3](./11-economy-and-crafting.md)'s one knob), the bench pays; an unpayable payday is paid down to 0 G and counts as a miss; two consecutive misses is BIG-dumb condition 5. "Small": an all-Common fifteen pays ~15 G a payday ≈ 60 G a tier ≈ 11 % of doc 11 §4.3's 520 G gross; a Renowned mix at Tier 4 ≈ 400 G a payday ≈ 22 % — rising with the roster's quality, which is what makes the cap and the bench bite. Out of 1.0 because the save freezes at v17 in wave 7 and a sink is measured on the opened on-ramp, not guessed on the closed one. (The register row asked W7-DOCS to repair a duplicate `#q-31` anchor: there is none — this file carries one `<a id="q-31">` and no duplicate anchor or heading slug anywhere, checked at the wave-7 close.) — ruled by the loop under the designer's 2026-09-15 delegation |

### 5.2 Items and itemization

| ID | Question | Owner | Why it matters | Options → consequence | 🔷 Recommended default |
|---|---|---|---|---|---|
| <a id="q-32"></a>Q-32 | Is the **Warrior head** its own family, or shared with Bard? | [09 OQ-1](./09-items-and-itemization.md) | The slot matrix says Warrior-only; every authored table gives Warrior and Bard the byte-identical `Raider's Helm — 5 AC / +5 HP / +1 Power`. No Warrior-only head item exists anywhere in canon | Shared → one head family, halved authoring, real drop contention · Separate → two assets and two records per tier for identical items | **Shared. One `WARBARD` head family; delete the matrix's Warrior-only head cell.** Doc 14 keeps `head_family` as a field regardless, so either reading stays expressible without a migration |
| <a id="q-33"></a>Q-33 | Item names collide: three different `Raider's Leggings`, three different `Basic Raid Staff`, `Worn Leggings` at 2 AC and 1 AC, `Raider's Boots` identical across two separate families | [09 §9](./09-items-and-itemization.md) | Names cannot be item identity as canon stands, and the loot system is specced as a keyed join | Internal keys + canon display names → data integrity with canon preserved · Rename items → canon rule 1 forbids silent correction | **Internal keys `t{N}_{family}_{slot}` with canon display names untouched.** Two decisions still needed from you: is `Raider's Boots` one item contested four ways or two identical items (recommend **two, family-qualified IDs**), and does the healer `Worn Leggings` at 1 AC get its own name (recommend **yes**) **RULED (2026-09-15): nothing renamed.** Every canon display name stays byte-identical, including the healer's 1-AC "Worn Leggings"; identity is the ID; wherever two live items share a display name (Worn Leggings ×2, Worn Trousers ×2, Old Sandals ×2, Raider's Boots ×2, Raider's Leggings ×3, Basic/Strong Raid Staff ×3) the UI prints the family beside it through the existing "who can wear this" line — "Worn Leggings · Healer" (W8-ITEMS); `test_canon_guard.gd` stays closed — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-34"></a>Q-34 | Does Boss 3 drop "Head + **stronger shared gear**", or Head alone? | [09 OQ-5](./09-items-and-itemization.md) | The raw notes say the former, the ideaboard says `Boss 3 | Head | —`, and no per-class table shows a second E3 item. It is also the only slot that could carry the missing Adventure-phase off-hands | Head only → tier gearing pace ~6.5 clears; read "stronger shared gear" as describing the Head pieces, which genuinely are shared families · Head + off-hands → ~5 clears and fills the empty off-hand gap, at 5+ more item records per tier | **Head + the tier's off-hands (Shield / Instrument / Tome)** — it resolves two canon gaps with one ruling |
| <a id="q-35"></a>Q-35 | Is there Adventure-tier **off-hand** and **starting-weapon** content? | [09 OQ-7](./09-items-and-itemization.md) | As canon stands, Warrior, Bard and all three healers show an empty off-hand for the entire Adventure phase, and every Common arrives with empty hands | Add both → the seven-slot model is fillable from turn one · Leave empty → canon slots that cannot be filled until the Tier 1 raid | **Add both** — recorded as the build's default in [09 §10.2](./09-items-and-itemization.md) (the three off-hand blocks, the four starting weapons) and [09 §13.1](./09-items-and-itemization.md) (the 27-per-rung template), 🔷 PROPOSED and unsigned. The content half — the three T1 Adventure off-hand rows, the generator template for T2-T5, the row-count tests — is audit `M5-T25-14` and a later unit; today's data files carry 28 Adventure rows with no off-hand, which is why §13.1 says 27 and the tests say 28 **RULED (2026-09-15): both signed, with Q-28.** Three Adventure off-hands per rung at docs/09 §10.2's stats (Iron Adventurer's Shield 4 AC / +5 HP; Adventurer's Lute +12 Mana; Blessed Adventurer's Tome 1 AC / +3 Mana), generated for tiers 2-5 — the Shield on `material`, the Tome on `healer`, the Lute on the `leather` craft-quality column ("Studded Adventurer's Lute"); docs/09 §10.2, §13.1 (27 → 31 per rung), §5 amended. The SHELF is not neutral (+50 % on a melee Common, +200 % on a caster at A0/A1): W8-SIM-BALANCE sweeps with the shelf ON and the harness buying the cheapest starters first, and states which roster the curve assumes — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-36"></a>Q-36 | Is the Rogue's `Basic Raid Dagger — +4` intentional, given the shared Adventure sword is +5 and the Rogue may dual-wield? | [09 OQ-15](./09-items-and-itemization.md), same question as [08 Q10](./08-stats-and-formulas.md) and [11 Q6](./11-economy-and-crafting.md) | **The first raid drop in the game is a downgrade for one class** (2×+5 = 10 → 2×+4 = 8), and doc 08's DPS-per-stage table shows the Rogue row falling 24.2 → 20.9 after Boss 1 while every other class rises | Leave canon → a visible "bug" at the player's first loot moment, and doc 11's upgrade headroom clamps at 0 · Raise to +5/+7 → the curve behaves · Give the Rogue extra swings → keeps canon numbers and pays the difference in doc 07 | **Designer's call, not ours.** Recommend **extra swings for the Rogue** so canon's numbers survive untouched and the class gets a real identity out of it. Whichever way, docs 08, 09 and 11 all point here **DECIDED (2026-09-15): the daggers rise one point.** Basic Raid Dagger +4 → +5 and Strong Raid Dagger +6 → +7 (ideaboard §3.4's numbers, changed on the record — `build/plan/ship/RULINGS.md` §4; docs/_source untouched); `TierScaling.DAGGER_OFFSET` −2 → −1 so the dagger sits one under the sword at every tier and the Boss 1 dip never recurs; `MELEE_SWINGS` stays 2 for all melee and no per-class swing count is spent. docs/08 §9.1's Rogue column becomes 24.2 / 24.2 / 28.0 / 35.6 / 49.9 — monotone, the Wizard (36.0 / 38.2 / 40.5 / 50.2) the single-target ceiling at every rung as canon's "Very high single-target DPS" requires, by 0.3 at Boss 5, which is the margin that forbids any Behind bonus. The swing alternatives were costed against that table and every one either doubled the Rogue or dethroned the Wizard. After the fix the dagger is a sidegrade, not an upgrade — the Rogue's real Boss 1 upgrade is the shared Basic Raid Sword in the main hand — and the two item notes (W8-ITEMS) say so in the register ("Lighter than the sword. The Rogue will tell you that is the point."), so [BL-32](#bl-32)'s "Suggested" never equipping the dagger is correct behaviour. Pinned by `test_items.gd` and `test_tier_scaling.gd`; docs/09 OQ-15, docs/08 Q10 and docs/11 Q6 close — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-37"></a>Q-37 | Does an Adventure-tier Rogue equip **two** Iron Adventurer's Swords? | [09 OQ-11](./09-items-and-itemization.md) | The matrix puts the shared 1H family in both Rogue hands; the weapon list gives one entry. It doubles Rogue weapon demand from a shared family | Two → +10 vs a Warrior's +5, and Q-36 becomes live · One → the Rogue is a weak melee at Adventure tier | **Two copies** — the Boss 1 Rogue row lists the same dagger in both hands, so the raid tier confirms the pattern |
| <a id="q-38"></a>Q-38 | Is `Raid Trinket` one universal item, or nine class variants? | [10 OQ-8](./10-content-and-encounters.md), stats by [09](./09-items-and-itemization.md) | The matrix says Trinket = Universal for all nine classes, yet every per-class table lists `Raid Trinket` in its own Boss 5 cell. It decides whether the tier capstone can ever be a duplicate | 1 item → dead weight after clear two · 9 items → nine records, none of them statted · 4 universal charms mirroring canon's Adventure charms (Health/Armor/Mana/Power) → a real choice every clear | **Four universal Raid charms** mirroring the canon Adventure set |
| <a id="q-39"></a>Q-39 | Are Monk's `Raider's Headband` (no Power) and Rogue's `Raider's Eyepatch` (+2 Power) deliberate? | [08 Q11](./08-stats-and-formulas.md) | Every other Boss 3 head grants +1 Power; Power applies per swing at 2 swings/round, so a 1–2 point gap is a whole-tier DPS difference between two classes sharing chest/legs/feet | Deliberate → the Monk is the tankier of the pair by design · Transcription artifact → normalise both to +1 | **Confirm as deliberate and reproduce exactly**, but say so in writing — right now it reads as an omission **RULED (2026-09-15): deliberate.** Power on zero Tier 1 Adventure armour, the Monk headband's none and the Rogue eyepatch's +2 are reproduced exactly (ideaboard §5) — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-40"></a>Q-40 | Are Monk's `Raider's Vest` and Rogue's `Raider's Leather Vest` one item or two? | [09](./09-items-and-itemization.md), [06](./06-classes-and-roles.md) | Byte-identical stats (6 AC / +7 HP / +2 Power), two names, from the same encounter, in a family the matrix declares shared. It decides Boss 4 loot contention | One item → Monk and Rogue compete, which is the pressure that makes comp choices costly · Two → no contention, and one item with two display names is a data bug | **One shared item, one name** (pick either canon string; a single item with two display names cannot ship) |
| <a id="q-41"></a>Q-41 | Tier 2–5 **material and title words** (T1 uses Iron / Raider) | [09 OQ-13](./09-items-and-itemization.md) | Every generated item name in four fifths of the game depends on them, and doc 09's candidates are explicitly placeholders that must not ship | Designer names them → the naming template generates cleanly · Ship placeholders → 300+ items named by accident | **Designer names them.** Discussion candidates only: Steel / Mithril / Adamant / Runegold, and Vanquisher / Conqueror / Ascendant / Immortal **RULED (2026-09-15).** The twenty words are: T2 Steel · Runeweave · Hallowed · Vanquisher · Vanquisher; T3 Silvered · Starweave · Sanctified · Conqueror · Conqueror; T4 Adamant · Stormweave · Anointed · Ascendant · Ascendant; T5 Runegold · Voidweave · Exalted · Immortal · Immortal (material · cloth · healer · raid_title · raid_adj, with `raid_adj` = `raid_title` per docs/09 §11.4's sanctioned collapse). The leather line keeps its own column — Reinforced (T1, canon) · Studded · Hardened · Masterwork · Flawless — so a Monk/Rogue Adventure piece never shares a display name with a Warrior/Bard one (`gen_items.gd` `WORD_COLUMN.monk` / `.rogue` → `"leather"`; docs/09 §11.4 widens to six columns). Tier 1's five words are canon's and untouched. The words stay STRAIGHT MMO words (the designer's own Tier 1 is "Basic Raid Sword", "Final Headband"): the joke is Bob and Steve wearing them, and the pompous title line — "Steve — 14 😡 — Immortal's Slippers" — is the roster-row joke played across five tiers. The register's own candidates are kept where good (Steel, Adamant, Runegold; the four titles) and Mithril was dropped for Silvered on docs/00 §4.4's originality gate. Grepped: no display-name collision (Flawless only as the `flawless_clear` condition id; Steel only as a palette name). `data/tier_words.json` is the one source; the regeneration clears `name_pending` on 304 rows and the export gate's eight item-file holds; [BL-69](#bl-69)'s mount rule now mounts all five tiers (W8-ITEMS the words, W9-TIERS the mount) — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-42"></a>Q-42 | Normalise the trinket prefix? Canon has `Adventure's` ×3 and `Adventures` ×1, while all armour uses `Adventurer's` | [09 OQ-9](./09-items-and-itemization.md) | Three spellings of one prefix across four items; it blocks the naming template from generating trinket names for later tiers | Normalise to `Adventurer's Charm of X` → one pattern, generatable · Preserve → four keys that should share a pattern and don't | **Normalise all four**, and record it as a deliberate correction rather than a silent one |
| <a id="q-43"></a>Q-43 | Does Mana appear on Warrior/Bard pieces, as the Bard source note says? | [09 OQ-10](./09-items-and-itemization.md) | Canon's note says "Mana can appear on these pieces and compete with Power" but **no Tier 1 piece has any** — a stated design intent absent from the data. It decides whether Warrior/Bard is genuinely contested or two classes sharing identical BiS | Tier 2+ intent → author one Mana variant per Warrior/Bard slot from T2 · Never → the Bard's only Mana source in the whole tier is its Boss 5 capstone, so it has no primary stat until the last boss | **Treat as Tier 2+ intent**, and give the Bard an interim Mana source at Tier 1 if Q-46 lands on Mana-scaling songs |
| <a id="q-44"></a>Q-44 | Monk and Rogue get a head at Boss 3 **and** Boss 5; everyone else gets one per tier. Intended? | [09 OQ-3](./09-items-and-itemization.md) | Their Boss 3 head becomes dead loot the moment Boss 5 falls, which changes how the player should value that drop | Intended → author the Boss 3 head as an explicit stepping stone the Final piece beats on every stat · Not intended → the Boss 3 head moves to another slot | **Intended — it is their capstone**, authored so the progression reads |

### 5.3 Classes, combat and encounters

| ID | Question | Owner | Why it matters | Options → consequence | 🔷 Recommended default |
|---|---|---|---|---|---|
| <a id="q-45"></a>Q-45 | Are **duplicate classes** allowed in one 12-person raid? | [06 Q4](./06-classes-and-roles.md) | Canon never says. With one dedicated tank class and a canon two-tank requirement, forbidding duplicates makes the canon requirement unmeetable without a Monk in every fight | Allowed → stacking three Mages is a legal-but-bad comp, balanced by non-stacking effects · Forbidden → 9 classes into 12 slots is impossible anyway | **Allowed and unpenalised.** Non-stacking effects (the Mage raid spell buff) carry the balance; no comp rule needed |
| <a id="q-46"></a>Q-46 | What do **Bard songs** do? | [06 §5](./06-classes-and-roles.md) | Canon says only "Random song effects TBD". One of nine classes and one of twelve slots currently has neither a mechanic nor a primary stat, and doc 07 flags the Bard as not-shippable until it closes | d6 positive-or-neutral song table per round with magnitude `S = 1 + floor(Mana/10)` plus a reduced Power-funded auto-attack, and a d4 Wrong Song table on a mistake → the Bard becomes simulable and its Mana/Power tension becomes the point · Anything else → the class, its itemization and its Legendary all stay blocked | **Ship doc 06 §5.3's B1 mechanic with the B3 stat model.** This also unblocks Q-43 and the ninth Legendary |
| <a id="q-47"></a>Q-47 | How many tanks does a fight require, and what is a Monk offtank worth? | [06 Q6, Q7](./06-classes-and-roles.md) jointly with [07 OQ-3](./07-combat-simulation.md) | Canon hedges twice — "most fights normally requiring 2 tanks" — and one Warrior plus one Monk is the normal early roster, so this single number decides how punishing the whole early game is | Per-fight `tanks_required`, default 2, tutorials 1 → encounter data carries it, the comp checker reads it · Monk weight 1.0 → a free substitute for a second Warrior · 0.5 → visibly worse · 0 (emergency-only) → a one-Warrior raid genuinely runs a tank short | **Per-fight `tanks_required` (default 2, tutorials 1); Monk weight 0, emergency-only.** Doc 06 §6.2 and doc 07 §8.3 must move together — one answer, both docs |
| <a id="q-48"></a>Q-48 | Is there a **position layer**, or only abstract flags? | [07 OQ-7](./07-combat-simulation.md) | Canon calls the Rogue "Position-dependent burst DPS" but defines no space model anywhere. It decides whether doc 10 authors mechanics spatially | Real positions → all 12 raiders and every boss mechanic need a space model; a large systems commitment · Abstract Melee/Ranged band plus per-mechanic booleans → two-state flags cost nothing, and the Rogue's bonus becomes a conditional buff | **Abstract flags only.** No grid, no coordinates. If the Rogue's canon description then reads as untrue, reword the description rather than build the system |
| <a id="q-49"></a>Q-49 | Does **battle-res** exist? | [07 OQ-4](./07-combat-simulation.md) | No canon class has a resurrect ability, and without one every death is permanent for the encounter | No battle-res → late encounters get sharply harder and a chain-failure wipe keeps its drama · Battle-res → wipes become recoverable and the drama flattens; the Cleric needs a second heal-type action slot | **No battle-res at launch.** Add later as a Reputation/Guildhall unlock (1 per encounter, 25% HP, 0 threat) only if playtest shows wipes are too abrupt |
| <a id="q-50"></a>Q-50 | Do **morale changes land during** an encounter, or only in the post-raid ledger? | [07 OQ-8](./07-combat-simulation.md) | Mid-fight morale means mistake chance drifts inside an encounter and one bad round can spiral unboundedly | Post-only → the encounter is a clean function of its inputs; far easier to tune and to explain · Mid-fight → argument and loot-drama mistakes feel immediate but the sim stops being sweepable | **Post-raid only.** Mid-fight, those mistakes apply a mistake-chance penalty and *queue* a morale delta that lands at encounter end — and `game/`, not the sim, applies it |
| <a id="q-51"></a>Q-51 | Does the mistake system run at **full rate in the tutorials**? | [07 OQ-9](./07-combat-simulation.md) | Canon frames Adventure 0 and the Tutorial Raid as "Just for learning". A tutorial that rolls mistakes at full rate teaches the player the game is unfair before it teaches them what the game is | Reduced rate, Facepull and Ninja-Pull disabled → the tutorial explains the system before demonstrating it · Full rate → the first ten minutes are a coin flip | **Reduced rate for both tutorials, full rates from Adventure 1 onward** |
| <a id="q-52"></a>Q-52 | Does a wipe **checkpoint** at the last cleared encounter? | [01 OQ-5](./01-core-loop.md) | Turns Raid 1 into a five-rung ladder or an all-or-nothing gate, and swings retry length between roughly 1 and 8 minutes. It also decides whether a failed attempt still pays out, which keeps canon's "You earn money" alive on a loss | Checkpoint within the town cycle, keep loot from cleared encounters → retries stay short and failure still pays · No checkpoint → an 8-minute retry after every wipe | **Checkpoint within the same town cycle, loot kept from encounters already cleared; leaving town resets to Encounter 1** |
| <a id="q-53"></a>Q-53 | Are raid **attempts limited**, and can the player quit mid-sim? | [07 OQ-5, OQ-6](./07-combat-simulation.md) / [01 OQ-6](./01-core-loop.md) | Two docs disagree: doc 01 says an attempt is atomic and quitting discards it; doc 07 says resume from the stored seed and round index. It is the save-scum surface | Unlimited attempts with a real economic cost → the economy is the brake, which loads doc 01's cost ledger · Attempt counter → failure is punishing in a game whose subject is failure · Resume from seed → player-friendly, and since the seed is committed before round 1 it cannot reroll anything · Forfeit → the only thing stopping alt-F4 being an undo | **Unlimited attempts with a per-attempt economic cost; resume from the stored seed and round index.** Doc 01 OQ-6 amends to match doc 07 and doc 14 OQ-11, which already require `SimState` to be serialisable. **Status (2026-09-15, W6-LEDGER): default taken, as built** — the attempt is resolved and recorded BEFORE RaidView plays a line (`RaidView.gd:386`, the stronger reading; nothing mid-account can discard or reroll), attempts are unlimited, `RaidView.EXITS_GATED = false`. `build/plan/ship/00-plan.md` §6 row #6 asks for the signature and carries the three recommendations (`Results.TRY_AGAIN`, Esc → the report, Continue → Results from the stored seed: W7-REPORT / W7-SAVE); the doc propagation (01 OQ-6, 07 OQ-5/6) is W7-DOCS's **RULED (2026-09-15).** Attempts are unlimited and the attempt is committed at Depart: the sim resolves and `record_attempt()` autosaves before RaidView plays a line, so speed, pause, skip, Esc, quitting and reloading are presentation and cannot discard or reroll anything. "Try again" is the wipe page's default-focused button (`Results.TRY_AGAIN = true`; the Board→Prep route with the plan still pinned; "Costs a day and the provisions you chalk."), Esc mid-replay is the post-mortem (`handles_cancel()`), and Continue after a mid-replay quit replays the stored seed (`active_run` = {encounter_id, master_seed, party_ids, resolved, difficulty_mult, ninja_pulled} — save v17, no later key) to Results. docs/01 §6.1's 25 G retry fee is not built; the day, the chalked provisions and the morale ledger are the per-attempt cost; docs/01 OQ-6 and docs/07 OQ-5/6 close (W7-DOCS applied them) — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-54"></a>Q-54 | Do Adventures and Raids strictly alternate, and do Adventures 2–5 keep the 3-encounter shape? | [10 OQ-4](./10-content-and-encounters.md) / [01 OQ-10](./01-core-loop.md) | Canon lists a strict alternating ladder and then withdraws it in the next line ("or can go raid raid, adventure adventure"). It sets the macro cadence and how gear tiers interleave with ranks | Alternate for tiers 1–2 then free → teaches the rhythm, then allows variety · Strict → predictable but rigid · Free from the start → no rhythm to learn | **Alternate as listed for tiers 1–2, designer free from tier 3; keep A1/A2/A3 at each tier's numbers.** The board must be data-driven either way — canon supplies no names |
| <a id="q-55"></a>Q-55 | Party size for **Adventure 0** and the **Tutorial Raid**, and how many trinkets do they pay? | [10 OQ-5, OQ-6](./10-content-and-encounters.md) | Canon fixes raid size at 12 and specifies Adventure 0 as "1 Trash mob", so read literally the first tutorial sends twelve raiders and two tanks at one mob — before the Tavern is in use. Canon also gives each tutorial "1 crap trinket" while the skip paragraph says "a special loot piece" singular | 4 pre-made for Adventure 0, 6 with 1 tank for the Tutorial Raid → both tutorials are shippable and set enemy HP via `hp_total = dps × rounds` · 12 → absurd · Two trinkets → the mission list says it twice · One → the skip warning is simpler | **4 and 6, both pre-made; two distinct trinkets, one per tutorial, both deliberately weak.** Skipping one forfeits only that one. The tutorial trinket stat is **+1 Power** (canon puts Damage only on weapons), which doc 01 §8.2 and doc 10 §9.2 must both be corrected to |
| <a id="q-56"></a>Q-56 | What heals the party in **Adventure 1**, if healing scales off Mana and starting armour has 0 Mana? | [10 OQ-11](./10-content-and-encounters.md), formula owned by [08](./08-stats-and-formulas.md) | A purely Mana-derived heal outputs **zero** at game start, which makes Adventure 1 mathematically unwinnable and invalidates the whole Adventure budget | `heal = base_class + k × Mana` with non-zero class base → Adventure 1 is winnable and gear scales it · Pure Mana → unwinnable | **`heal = base_class + k × Mana`, base non-zero.** Doc 08 owns `base` and `k`, and doc 08 §9.1 also needs a **stage-0 row** (starting armour, no weapon) because both tutorials and Adventure 1 are played below its current earliest stage |
| <a id="q-57"></a>Q-57 | Does **Lost Aggro** retarget one boss swing or the whole round? | [10 OQ-12](./10-content-and-encounters.md) | On the 2-swing bosses at E3–E5, the whole-round reading makes every Warrior mistake an automatic caster death (2 × 28 on a 51 HP Wizard), which removes the compounding-failure texture the sim exists to produce | Swing 1 only → the mistake hurts and the fight continues · Whole round → the mistake is an instant kill | **Swing 1 only retargets; swing 2 resolves on the Warrior** **Status (2026-09-15, W7-SIM-EFFECTS):** implemented — the active tank's `MIS_TAUNT_LAPSE` is Lost Aggro: `Combatant.lost_aggro_round` zeroes the tank's threat for the next Phase 1, swing 1 goes to the second-highest threat, swing 2 resolves on the tank (`RaidSim._phase_boss`); `Formulas.should_retarget`'s 1.10 / 1.30 hysteresis decides every organic switch in `_pick_enemy_target`; the active tank Taunts to 1.10 × highest when its 1.30 Tank Lead is lost (`RaidSim.TAUNT_COOLDOWN_ROUNDS = 2`); pinned by `test_raid_sim.gd::test_a_tanks_action_mistake_drops_aggro_for_one_round`, `::test_taunt_restores_the_lead`, `::test_the_boss_switches_only_past_the_hysteresis` |
| <a id="q-58"></a>Q-58 | Do **healers generate threat**, and does the Shaman chain heal repeat or skip targets? | [06 Q9](./06-classes-and-roles.md) / [08 Q17](./08-stats-and-formulas.md) | Threat decides whether a Cleric can pull the boss off its own tank and whether Lost Aggro can land on a healer. The chain heal rule changes Shaman throughput by up to 35% | Healer threat yes, low multiplier → healers are exposed but not fragile bait · No → healing is consequence-free · Chain never repeats, skips above 95% HP → a raid-wide smoothing tool · Repeats → a reliable tank cooldown | **Healer threat yes at a low multiplier (doc 07 owns the number); chain heal never repeats a target and skips anyone above 95% HP** **Status (2026-09-15, W7-SIM-EFFECTS):** implemented — `RaidSim._cast_heal` returns the healed total and the healer takes `Formulas.threat_from(cls, 0.0, healed)` (`HEAL_THREAT_COEF` 0.50, docs/08 §8.7); the Shaman's hops 2-3 go through `_neediest(..., skip_above = RaidSim.CHAIN_SKIP_ABOVE)` at 0.95 and a hop with nowhere to go is logged; pinned by `test_raid_sim.gd::test_a_clerics_threat_rises_with_healing` and `::test_the_shamans_hops_skip_full_targets` |
| <a id="q-59"></a>Q-59 | Do **damage variance and crit** exist, and is `MELEE_SWINGS = 2`? | [08 Q16, Q18](./08-stats-and-formulas.md) | Variance decides whether doc 08's budget numbers are exact or expected values, and whether a wipe is diagnosable from the combat log. Swings is the single largest lever on melee-vs-caster parity | Zero variance, zero crit → every boss number is exact and every wipe is explainable; high crit plus flat AC would one-shot cloth · Variance on → tuning becomes statistical · 1 swing → casters dominate; 3 → the Rogue runs away with the tier | **Ship at zero variance, zero crit, `MELEE_SWINGS = 2` for all melee.** Revisit variance after the first playtest; per-class swing counts are a later refinement, and Q-36 may spend one |

### 5.4 Town, economy and morale

| ID | Question | Owner | Why it matters | Options → consequence | 🔷 Recommended default |
|---|---|---|---|---|---|
| <a id="q-60"></a>Q-60 | Which **recruit price scale** ships? | [11 §4.2](./11-economy-and-crafting.md) owns prices | Three docs publish three scales for the same recruits at Tier 1: doc 11 (15 / 60 / 160 / 420 / 1,000 G), doc 04 §3.3 (60 / 180 / 450 / 1,100 / 3,000 g — roughly 3×), doc 13 §9.4 (a third set, while claiming to render doc 04's). Doc 11's anti-arbitrage test R3 is asserted against its own lower figure | Doc 11's scale → the ledger and income curve stay coherent · Doc 04's → recruiting is a major sink and the early game is much tighter | **Doc 11 §4.2's scale is authoritative; docs 04 and 13 render it.** Then re-run doc 11 §12.1 R3 and doc 01's 60 G starting-gold figure against whatever survives. **Status (2026-09-15, W6-LEDGER): default taken** — `Recruitment.PRICE_SCALE = "doc11"` selects S1's table, doc 04's stays selectable; the R3 test and the 60 G re-run are [BL-94](#bl-94) **Confirmed (2026-09-15).** Doc 11 §4.2's table is the shipped recruit price (Common 15 · Uncommon 60 · Rare 160 · Epic 420 · Legendary 1,000 G); `PRICE_SCALE = "doc11"`; doc 04 §3.3's column is a pointer and the "doc04" row exists only so both tables stay under test; `STARTING_GOLD` 60 stays. A 60 G purse that buys one Common and nothing else is a Tavern the player cannot use on day one — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-61"></a>Q-61 | What is the **currency** called? | [11 §3](./11-economy-and-crafting.md) | It appears in every UI string and every price tooltip, and the placeholder is already propagating through docs 01, 02 and 03 | Name it now → strings and localisation can start · Keep the placeholder → do not localise currency strings yet | **Keep "Guild Coin (G)" as an explicit placeholder until named, and do not localise currency strings before it is decided** **RULED (2026-09-15): the currency is gold, "G".** Written "G" on chips and prices and "gold" in prose, final (docs/11 §3's "Guild Coin (G)" → "gold (G)" — `build/plan/handoff-W7-DOCS.md`; the copy lint may carry "no coin / Guild Coin / GC in player-facing strings"); the "do not localise" clause is moot under [BL-133](#bl-133) — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-62"></a>Q-62 | Are **comfort items** durable furnishings, consumed indulgences, or both — and per-raider or guild-wide? | [11 Q4](./11-economy-and-crafting.md) / [02 Q10, Q13](./02-town-and-buildings.md) / [05 §7](./05-morale.md) | Three docs model the same purchase three ways. It decides whether the morale economy is a one-off purchase (~500 G of T1–3 sinks) or a recurring bill (~1,500 G), and whether the Guildhall needs a per-raider quarters UI | Durable baseline shift → the Guildhall upgrade track is a morale system; a permanent floor · Consumed +8 event on cooldown → gold stays relevant mid-tier but morale repair is a chore · Both, as two SKU lines → covers both jobs · Per-raider slots (1/2/3/4 by Guildhall level) → bigger UI, upgrade track has something to scale · Guild-wide → one shared list, smaller | **Both, as two SKU lines: durable Furnishings that shift `baseline`, plus consumable Indulgences on a cooldown. Per-raider, slot count set by Guildhall level.** Doc 05 owns whether Furnishings count against its baseline ceiling of 80 |
| <a id="q-63"></a>Q-63 | Does the town have a **day clock**, or does time only pass when you raid? | [05 Q8](./05-morale.md) | Every per-Day-Tick number in doc 05 — drift, leave rolls, disband strikes, comfort cooldowns, bench penalties — is anchored to it. Without a rest action, a player stuck on a raid they cannot clear has **no way to recover morale**, which is exactly when they need one | Time advances on attempt resolution **or** an explicit rest → recovery is always available · Attempts only → raise every drift value ~1.5× so recovery still tracks a reasonable number of attempts · A real calendar → a whole system nobody asked for | **Time advances when an attempt resolves or the player rests in town.** The rest action is the cheap insurance against a stuck save |
| <a id="q-64"></a>Q-64 | Is a raider's **morale visible before recruiting**? | [05 Q10](./05-morale.md) | It turns recruitment from a gamble into a shopping trip. Since starting morale equals baseline, showing it also leaks rarity | Show → an informed "can I afford to keep this person happy" call, and morale reads as a rarity tell · Hide → a surprise, and the player cannot plan | **Show it** |
| <a id="q-65"></a>Q-65 | Does a **benched** raider get the raid-clear morale bonus? | [05 Q11](./05-morale.md) | With raid size 12 and a larger roster, the bench is where most leave checks actually fire — it decides whether the roster splits into a permanent 12 and a slowly rotting remainder | No bonus plus a small penalty from the 2nd consecutive benched tick (−2, capped −6 per 7 ticks) → rotation is rewarded · No penalty → the bench is a free warehouse · Full bonus → benching is strictly better than fielding | **No clear bonus while benched, −2 from the second consecutive tick, capped.** Enough to encourage rotation without making a deep roster unmanageable |
| <a id="q-66"></a>Q-66 | Is there a morale cost to **firing** a raider yourself? | [05 Q12](./05-morale.md) | Without one, "fire the unhappy one" is strictly optimal and the whole morale system is bypassable | Voluntary dismissal −2 to all remaining vs −4 for a departure → cheaper than neglect, not free · Zero → morale management is optional | **−2 on voluntary dismissal, −4 on a departure** |
| <a id="q-67"></a>Q-67 | **Navigation model:** clickable illustrated scene, walkable hub, or stylized map? | [02 §10](./02-town-and-buildings.md) | It sets the art and engineering budget in docs 12, 13 and 14, and decides whether the per-rank visual progression is affordable at all. **Doc 12 is currently pricing art for the option doc 02 rejected** — a player avatar, a follow camera with dead zone, and a required 6-frame `walk` tag | Clickable scene with 3 parallax depths, ambient NPCs, camera push-in → the progression is affordable; no nav mesh, no player entity · Walkable hub → +3–4 EW of locomotion, collision, camera, door transitions and save position, buying no progression | **Clickable illustrated scene.** Doc 12 then deletes the town avatar, the follow-camera row and the `walk` requirement from its budget |
| <a id="q-68"></a>Q-68 | Canonical strings: **Market or Merchant? Adventure's or Adventurer's Board?** | [02 Q7](./02-town-and-buildings.md) | Baked into painted signage, save keys and every UI string; changing later means re-authoring art | Building = "Market", vendor NPC = "the Merchant", board = "Adventure's Board" (canon's own heading spelling) → canon preserved, one key each · A naming pass now → cleaner, but delays art | **Market / the Merchant / Adventure's Board**, each as one string-table key so a later rename is a data change **RULED (2026-09-15): as built.** The building is "Market", the vendor "the Merchant", the board "Adventure's Board" (canon's spelling, painted on the sign), one string-table key each — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-69"></a>Q-69 | Does the **achievement board** grant reputation, and does **time of day** advance? | [02 Q11, Q9](./02-town-and-buildings.md) | The board adds a non-mission reputation faucet that doc 03 may not want, and reputation drives every town change. Time of day costs one extra lighting pass per building | Board grants RP, capped ~15% of total earned → achievements matter without becoming the main path · No RP → the board is cosmetic · Time of day cosmetic (Dawn/Day/Dusk/Night, one step per mission) → forge glow, lit windows, festival lanterns · No → the town reads as a diorama | **Board yes, capped at ~15%; time of day yes, cosmetic only — rejected if doc 12 prices it above 0.5 AU per building** **RULED (2026-09-15): the record wall pays reputation (the board half); the time-of-day half is unchanged.** Records of kind `reputation` (two ship: One of Each, Comfortable) pay 15 RP each — docs/03 §6.1's smallest award, the two tutorials' worth — claimed once, and the board's lifetime RP is capped live at 15 % of RP earned exactly as its coin is (`Achievements.rp_cap`; a claim past the share is blocked with "The town has heard its share for now — %d of the %d reputation it may pay against %d earned." rather than paid short). `FLAG_DEFAULTS.achievement_rp = true`; `claim_grant()` gains the reputation branch; `describe_reward()`'s "(reputation is not signed off — …)" clause is deleted; docs/03 §6.1 gains the row "Record wall, reputation-kind records | — | 15 | 0". The ladder's proof is unmoved: +30 RP lifetime, never before Known (the cap at Known is ⌊0.15 × 120⌋ = 18 ≥ 15), and Legendary still lands on Raid 5's full-clear bonus (2815 + 30 + 325 = 3170 < 3200). "One of Each" is earned on day one (the starting twelve cover all nine classes) — that is the record's condition, accepted. LOOP-13's feed line reads "The town heard: +15 reputation" on a claim through `_award_reputation`'s signal; the rank-up callout listens to the same path (W8-CRISIS). All in W7-SAVE; M5-QAB-4 closes — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-70"></a>Q-70 | Do **wishlists** ship? | [05 §9](./05-morale.md) / [04 Q11](./04-recruitment-and-roster.md) | Canon is explicitly tentative ("This is all just concepts"). It is the strongest hook for making loot distribution a social decision, and it adds an entire second morale surface to tune and author text for. **Note:** doc 01 §5.2 currently marks this line ✅ CANON while docs 00, 04 and 05 all mark it ❓ OPEN — doc 01 is wrong and should be corrected regardless of the ruling | In, as a cut-able module → six rows of doc 05 §7.3 and all of §9 live; the rows collapse cleanly to plain +5 upgrade / −3 passed-over if dropped · Out → the loot screen's morale preview is reworked later · Feature-flagged, off for playtest 1 and on for playtest 2 → decide with data | **Build it as a cut-able module behind a flag, after the core loop ships. The game must be fully playable with the flag off** |
| <a id="q-71"></a>Q-71 | Should the game **flag a town cycle that improved nothing**? | [01 OQ-7](./01-core-loop.md) | Without it a new player can re-run a mission they cannot clear indefinitely with no signal about whether gear, morale, roster or unlocks is the blocker — the most likely early-game churn point | Diagnostic hint on the board naming the weakest of the four → a way out of the loop · Nothing → silent churn | **Yes.** If a cycle changed none of the four, the Adventure's Board shows a hint naming the weakest one |
| <a id="q-72"></a>Q-72 | Do **difficulty presets or assist options** ship? | [00 Q13](./00-vision-and-pillars.md) | Doc 03 §8's recruit-quality spiral and doc 05 §8's morale spiral have no player-facing relief, and doc 08 §11 has no global difficulty lever. Retrofitting difficulty after the sim is swept against one tuning set means re-sweeping every table in doc 10 | One default difficulty plus one assist toggle, as a single `DIFFICULTY_MULT` in doc 08 §11 → cheap now, expensive later · Nothing → a stuck player has no way out at all | **One default plus one assist toggle, implemented as a single lever now** even if it stays hidden until playtest |

---

## 6. ⚪ C — Deferred

Safe to answer later. Nothing downstream is blocked; each is a backlog item with a default already in place.

| ID | Question | Owner | 🔷 Default until asked again |
|---|---|---|---|
| <a id="q-73"></a>Q-73 | Is the "!" fumble glyph a sprite layer or a UI element? | [12 Q10](./12-art-direction.md) | Sprite layer on `60_fx`, no text, so it works at 12-person lineup scale and never needs localising |
| <a id="q-74"></a>Q-74 | How many `fumble` variants per class at v1? | [12 Q8](./12-art-direction.md) | One per class; add a second for the three most-played classes after playtest identifies them |
| <a id="q-75"></a>Q-75 | Do we hand-author sprite normal maps? | [12 Q6](./12-art-direction.md) | Prototype a 3-tone hand-painted proxy on one class; if the gain is not obvious at 1440p, drop to a single global baked light direction |
| <a id="q-76"></a>Q-76 | Layered 2D with painted perspective, or textured quads in a 3D scene? And `SubViewport` or native canvas? | [12 Q7, Q11](./12-art-direction.md) | Layered 2D, painted perspective, native-resolution canvas with no `SubViewport` for the character/plate layer. Doc 14 §2.2 amends its `SubViewport` cell. Blocked on the engine prototype demonstrating sub-pixel motion at 3× — **settle before environment production starts** |
| <a id="q-77"></a>Q-77 | Are painted environment plates authored in RGB, outside the master palette? | [12 Q3](./12-art-direction.md) | Far and mid plates painted in RGB but value-range-checked against the palette; play plane, near props and foreground occluders strictly palette-bound |
| <a id="q-78"></a>Q-78 | Does the Rogue read as swords or daggers, and do Warrior and Bard share one head asset? | [12 Q5, Q9](./12-art-direction.md) | Twin daggers for the Rogue (the raid table is the more specific statement); one shared helm asset with a Bard-only plume overlay. Both follow Q-32 and Q-36 rather than leading them |
| <a id="q-79"></a>Q-79 | Which morale colour ramp, and which ground colour? | [13 OQ-11](./13-ui-ux.md) | Doc 12's three hues become anchors at bands 1, 4 and 7 with the other seven interpolated along the L* ladder, high end shifted green→teal for CVD safety. **The ground colour — warm parchment or cool ledger stock — needs a call**, but it is a token swap, not a rebuild |
| <a id="q-80"></a>Q-80 | Does raid prep show a single predicted **win percentage**? | [13 OQ-2](./13-ui-ux.md) | No. Ship expected-mistakes-per-encounter plus the three biggest named contributors. Doc 01 §5.2's illustrative percentages (55/30/40/65) are prose, not a spec. Revisit after playtest measures comprehension |
| <a id="q-81"></a>Q-81 | Ship a button that auto-fills all twelve raid slots? | [13 OQ-3](./13-ui-ux.md) | Yes, but it optimises for comp validity only and deliberately ignores morale, so the player still makes the Steve call. Label it "Suggest a group", never "Optimal" |
| <a id="q-82"></a>Q-82 | Are comfort items applied from the Roster row or only from Raider Detail? | [13 OQ-4](./13-ui-ux.md) | Quick-apply from the Roster row's context action, full slot view in Raider Detail. Depends on Q-62 landing per-raider |
| <a id="q-83"></a>Q-83 | Is the em dash in the canon roster line a hard character or a localizable separator? | [13 OQ-5](./13-ui-ux.md) | Localizable separator in the string template, defaulting to U+2014 with spaces. The canon format stays exact in every shipped English build |
| <a id="q-84"></a>Q-84 | How are unnamed missions and bosses labelled? | [13 OQ-8](./13-ui-ux.md) | Render canon's placeholders verbatim (`Raid 1`, `Boss 3`) with a `[name pending]` marker in dev builds only. The marker must not ship **CLOSED (2026-09-15)** by [BL-119](#bl-119): the 21 boss rungs carry a role title through spec 00 §2.3's `title` field; trash, the ladder words and every enemy log name keep canon's placeholders; "Encounter N" in the UI, "Boss N" only as the loot key; no dev-build marker — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-85"></a>Q-85 | Is RTL in scope after 1.0, and is gamepad support a 1.0 requirement? | [13 OQ-6, OQ-12](./13-ui-ux.md) | RTL not in 1.0, but use start/end anchors throughout regardless. Focus model is 1.0 (already required by the keyboard row, so it is free); default bindings ship in 1.0; rebinding UI and Deck layout verification defer to the Deck milestone |
| <a id="q-86"></a>Q-86 | Is **farming** a strategy or a safety net? | [10 §11](./10-content-and-encounters.md) | Safety net. Flat rewards, duplicate protection at 2 copies, 5-clear pity counter, no heroic mode in v1 — otherwise all 42 encounters need a second tuning pass |
| <a id="q-87"></a>Q-87 | Is `target_rounds` measured against entry gear or full-clear gear? | [10 OQ-10](./10-content-and-encounters.md) | Entry gear; enrage stays at 1.4× the entry-gear figure, so farming genuinely feels easier and first clears stay possible |
| <a id="q-88"></a>Q-88 | Does clearing **Raid 5** end the run, or open a completion phase? | [10 §13](./10-content-and-encounters.md) | A completion beat (doc 13 gains S17), then the save continues: Legendary collection to 9-of-9, achievements, flat repeat clears. No Tier 6 in 1.0 |
| <a id="q-89"></a>Q-89 | If a **Legendary** leaves or is dismissed, are they re-findable? | [03 Q6](./03-guild-reputation.md) / [04 Q10](./04-recruitment-and-roster.md) | Gone for good — with a hard confirmation the first time a Legendary drops below 40 morale and a standing roster warning while any severe condition is active. Canon's "will not be bothered by many things easily" means this should require deliberate negligence |
| <a id="q-90"></a>Q-90 | Is skipping a tutorial permanent, and how many attempts should a first Raid 1 clear take? | [01 OQ-8, OQ-9](./01-core-loop.md) | Skip is permanent — the mission leaves the board and the reward is gone. Target 3–5 attempts across 2–3 town cycles for a first Raid 1 clear |
| <a id="q-91"></a>Q-91 | Does the `Legendary` name collision get resolved by renaming one? | [04 Q6](./04-recruitment-and-roster.md) | Keep both in code as `rank_legendary` and `rarity_legendary`; display the rank as "Legendary Guild" in UI. Cheap, and it removes the ambiguity where it is actually read |
| <a id="q-92"></a>Q-92 | Does the disband RP penalty survive playtest? | [03 Q11](./03-guild-reputation.md) | Keep −10% of RP earned within the current rank, clamped so it can never demote. Cut it if telemetry correlates it with churn |
| <a id="q-93"></a>Q-93 | Does any build ship **network telemetry**, and does a debug console ship in release? | [14 OQ-14, OQ-12](./14-technical-architecture.md) | Playtest-only local JSONL logs under `user://analytics/`, no egress, off in release. Debug console behind a launch flag, disabled by default. Shipping aggregate telemetry is an amendment to doc 00 A11 and a business decision, not an engineering one |
| <a id="q-94"></a>Q-94 | Is `sim/` GDScript or C#/GDExtension, and JSON or `.tres`? | [14 OQ-4, OQ-5](./14-technical-architecture.md) | GDScript — iteration speed matters more now, and doc 14 §3's purity rule keeps the port available if measurement demands it. JSON for content, `.tres` for tuning singletons only, flattened to Dictionaries before entering `SimInput` |
| <a id="q-95"></a>Q-95 | PowerShell 7 (`pwsh`) or Windows PowerShell 5.1 for the pipeline? | [12 Q12](./12-art-direction.md) | Author for 5.1 — `pwsh` is not installed on this machine — so no `&&`/`\|\|`, no ternary, `-Encoding utf8` on every write, invoked as `powershell -File`. Revisit only if a script genuinely needs a 7-only feature |
| <a id="q-96"></a>Q-96 | **Which arena is each encounter fought in?** Two bare arena plates shipped on 2026-09-11 (`stage_arena_cave`, `stage_arena_dungeon`) and nothing says which fight happens where: `Encounter.kind` is trash / hard trash / mini boss / main boss, which is a difficulty, not a place, and the A1-A3 rungs carry no location either. | [09 §2 sheet rows S1-CAVE / S3-CAVE](../art/ref/specs/09-background-plates.md), [10 §8](./10-content-and-encounters.md) | **Proposed:** a `backdrop` key on each encounter record, authored per fight, defaulting to the cave. Until it is authored, RaidPrep, RaidView and Results all name ONE arena in a single constant (`ARENA_SCENE`) rather than guessing a mapping for eight encounters — a wrong mapping is worse than an honest repetition, because it looks deliberate. Needs the designer to say whether the backdrop belongs to the ENCOUNTER (this boss lives in a dungeon) or to the RAID (a raid is one location, five fights) **RESOLVED (2026-09-15): the arena belongs to the RAID.** `SceneStage.arena_for(encounter)` is the one rule (W7-STAGE): the tier row's `scene` (per kind, `{"adventure": …, "raid": …}`) if `data/tier_words.json` names it, else raid encounters (E1-E5) in `stage_arena_dungeon` and adventures and tutorials (A0, TR, A1-A3) in `stage_arena_cave`; the three `DEFAULT_ARENA` sites become handoff lines; no `backdrop` key on encounter records (this row's own proposal is superseded — a per-encounter key is a second truth for a fact the kind carries); the bed follows the same function ([BL-138](#bl-138)). Fighting TR in the cave keeps the dungeon as the thing Raid 1 earns. Tiers 2-5 inherit the kind rule until a tier row names a plate; M4B-CONV-04 closes — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-97"></a>Q-97 | **What is the audio direction, and what does "audio's call" mean when nobody owns audio?** [13 §12.4](./13-ui-ux.md) hands doc 14 eleven hook names and defers mixing to "audio's call"; §8 below records that this defers it to nobody. Promoted from `build/plan/q-audio.md` (audit M6-AUD-06) at the next free number — its draft said Q-96, which the arena question above had taken. | [13 §12.4, §15.1](./13-ui-ux.md), [14 §4](./14-technical-architecture.md), §8 gap row | **Recorded as built (2026-09-15):** four buses and no fifth (`default_bus_layout.tres`, Master / Music / UI / Voice in §15.1's order — no SFX bus, because §15.1 names the voice of the scribe, not SFX); the four settings keys move those four buses by name at boot and on every change, 0 mutes; the eleven §12.4 hooks are bound by name in `game/core/Audio.gd` and an unknown name is a hard error; every sample is generated from a physical model (`tools/audio/gen_sfx.py`, byte-checked — nothing downloaded, so docs/00 §4.4's "all audio original" holds and the credits owe no audio attribution); `ui.silence` is a mixer move (`Audio.duck(-60.0, 0.4)`), not a sample; pitch jitter is ±2 semitones on `ui.stamp` and 0 on every other hook. Two house choices disclosed: the 140 ms ceiling applies to every non-indulgent one-shot (the two indulgent hooks are bounded by the motion they sync to: 380 ≤ 700, 430 ≤ 900); a save restore is not a "gold change" and rings no coin. Still a person's: whether `ui.stamp` fatigues at a real raid's rate (a taste judgement no loop can self-verify). doc 14 §4's `game/autoload/audio.gd` is `game/core/Audio.gd` (W7-DOCS corrects the tree listing) |
| <a id="q-98"></a>Q-98 | **The soundscape beyond the eleven hooks: music beds, ambience, the Voice bus, the world layer — composed, licensed, generated, or cut for 1.0?** [02 §9.1](./02-town-and-buildings.md) commits an Audio column per rank (wind and a sparse lute at Unknown → a bell toll at Renowned → a cheer stinger and leitmotif at Legendary); none of it exists and canon has no audio word. Promoted from `build/plan/q-audio.md`'s second entry with the ambience, voice and world-sound halves folded in (AUDIO-06/-11/-13/-19) so the designer answers the whole soundscape once — `build/plan/ship/00-plan.md` §6 row #46 | [02 §9.1](./02-town-and-buildings.md), [13 §11, §12.4, §13, §15.1](./13-ui-ux.md), §8 gap row | **Ship default (unanswered by wave 7):** (i) NO MUSIC in 1.0 — the melodic beds and the leitmotif are authored things a generator cannot make recognisable, and `Audio.play_bed()` stays a deliberate no-op until a person delivers stems (`tests/unit/test_audio.gd :: test_play_bed_is_a_no_op_because_no_one_owns_the_music_yet` is the tripwire); (ii) AMBIENCE rides the **Music** bus — no fifth bus, no fifth §15.1 row — and the Settings row reads "Music and ambience" (W6-SETTINGS); generated beds per stage through one door (`tools/audio/gen_amb.py`, W7-AUD-AMB: camp, tavern, market, cave; the dungeon and the aerial play the camp bed until authored); the arena bed follows `SceneStage.arena_for()` (Q-96's answer), never a second mapping; (iii) the **Voice** bus ("the voice of the scribe", defined nowhere) has no consumer: the row is HIDDEN in wave 6 and deleted in wave 10 unless the page buys `ui.quill` (audit `m6-quill-hook`); (iv) the WORLD layer is silent — the log is a document (13 §11.1) and the stage's attacks, heals and numbers make no sound; (v) the WIPE stamp uses `ui.stamp` unjittered (13 §12.4 binds it to every StampBadge land). **Three defaults for the option interplay (AUDIO-11), asserted in `tests/unit/test_audio_binds.gd`:** `reduced_motion` never silences a hook — sound is not motion, and 13 §13's own carve-out ("stamps still land") is the precedent; at Instant speed and during a skip no per-line hook fires (`Audio.play` drops `{"live": false}`), only `ui.silence` and the wipe/clear stamp fire once at the end; `reduced_effects` and `comedy_brake` do not touch audio. **The clear's sound is the coin** (AUDIO-19): a clear presses no stamp (13 §11 "no victory framing"), so `ui.coin` on the gold write is the clear's own sound — a decision, not an omission; if Results ever presses the CLEARED StampBadge 13 §7 lists, it inherits `ui.stamp` for free **AMENDED (2026-09-15).** (i) MUSIC in 1.0 is the generated sparse lute docs/02 §9.1 asked for at Unknown and Known: `tools/audio/gen_music.py` in `gen_sfx.py`'s shape (numpy + `wave`, seeded per `sha256("music:<rank_bed>")`, `--check` / `--list` / `--out`) — a Karplus-Strong string (delay `fs/f0`, averaging loop filter, decay 0.996, pluck-position comb at 0.13, two strings ±3 cents, a body band-pass at 210 Hz Q 4 at −12 dB), A minor pentatonic A2-A4, a phrase walker (gaps mean 2.4 s clamped 0.6-6 s; step ±1 55 % / ±2 25 % / repeat 10 % / tonic 10 %; 20 % dyads on the nearest fifth; velocity 0.55-0.9; an 8 s rest after every 6-10 notes 15 % of the time), Unknown rubato, Known adds a frame drum (200 Hz low-passed noise thump, 90 ms, beats 1 and 3 of 4/4 at 66 BPM, beat 3 −6 dB) and quantises onsets to the eighth grid; `music_lute_unknown.wav` 90 s and `music_lute_known.wav` 87.27 s (24 bars at 66 BPM), 44.1 kHz mono 16-bit, tail folded over 600 ms, peak −24 / RMS ≈ −34 dBFS; `Audio.BEDS_MUSIC` (rank 0 Unknown, ranks 1-5 Known), `MUSIC_BY_SCENE = {"stage_camp", "stage_town"}` (the camp family and the main menu only), a second player pair on the Music bus with the beds' crossfade, behind `Audio.MUSIC_BED = true`; `test_audio_music.gd` replaces the `play_bed`-is-a-no-op tripwire. The ensemble, the bell toll, the cheer stinger and the leitmotif are post-1.0. It lands as **W10-BUFFER's first item** and is cut for 1.0 in writing if the buffer is consumed (the credits line follows — [BL-132](#bl-132)). (ii) Ambience rides the Music bus ("Audio — music and ambience") through five generated beds and the one door ([BL-138](#bl-138)); the arena bed follows `arena_for()`. (iii) The Voice bus is "the scribe": `ui.quill` — `stick_slip`, 85 ms, 1.8-6 kHz, grain 90 Hz, three round-robin variants, peak −27 dBFS, jitter 0 — under every log line at live speed (none at Instant or during a skip), the twelfth docs/13 §12.4 hook, bound beside the stamp's in `RaidView._append_line`; the Settings row returns as `{"key": "audio_voice", "label": "Audio — the scribe", "note": "The quill under each line of the account."}`; W8-AUD-OPT (S), the two lines by handoff to W8-KEYS; W10-DELETE does not delete the Voice row. (iv) The world layer is silent — failure is the content and hits and heals would bury the mistakes under the noise of competence. (v) The WIPE stamp is `ui.stamp` unjittered. The three interplay defaults and the coin as the clear's sound stand; the owner is the loop; nothing is downloaded (docs/00 §4.4 (5)); docs/02 §9.1's Audio column is amended to what ships — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-99"></a>Q-99 | **Does "the desk does not move" (13 §2 M5) forbid a 110 ms opacity cross-dissolve on a screen change, or only spatial slides?** [13 §12.2](./13-ui-ux.md)'s motion table asks for "cross-dissolve + active tab shifts 6px right, 110 ms"; `game/core/ScreenRouter.gd`'s header says the router "has no transition animation and never will"; docs/13 §11.4's t=1,800 post-mortem slide waits on the same word (audit M6-JUICE-02; art plan Q09; UI-46) — `build/plan/ship/00-plan.md` §6 row #33 | [13 §2 M5, §11.4, §12.2](./13-ui-ux.md) | **Ship default (unanswered by wave 8): `ScreenRouter.TRANSITION_MS = 0` and no slide** — screens cut, the wipe's page appears in place of the log (how `_run_wipe_sequence` already does it), and the references show no transition (spec 00 §1 row 4). The constant does not exist in the tree yet: it is recorded here as the default so a "yes" is one constant (110, opacity only, through `Widgets.tween` so `motion_duration` governs it) and W10-DELETE softens the docstring's "never will" to "not by default". The 6px tab shift is a slide and stays out under either answer **RULED (2026-09-15): a page fades in.** `ScreenRouter.TRANSITION_MS = 110` — `_load_into_host` adds the new screen at t=0 (every `Label.text` read holds), sets `modulate.a = 0` and tweens to 1 over 110 ms `EASE_OUT`; the outgoing screen is freed at once (a fade-in, not a cross-fade — one screen in the tree); `TRANSITION_MS` reads 0 under `GameSettings.reduced_motion` and when `shot.gd` is driving (the sheets stay byte-stable); `ui.tab` fires on the fade's first frame. A dissolve is a page changing IN PLACE, which is docs/13 M5's own sentence; the 6 px tab shift is a slide and is struck; §11.4's t=1,800 post-mortem slide is struck — the report appears in place under the stamp. 110 < §12.1's 140 ms settle. Lands in W8-KEYS (owns `ScreenRouter.gd` and `test_a11y.gd` in wave 8; the pins go in `test_a11y.gd`); the docstring's "never will" becomes "110 ms, opacity only" there, and W10-DELETE's line is struck; docs/13 §12.2 row 1 → "Fade-in, opacity only | 110 ms | ease-out", §11.4 amended (W7-DOCS applied both) — ruled by the loop under the designer's 2026-09-15 delegation. |
| <a id="q-100"></a>Q-100 | **What is the target clear-rate curve, and what does a rung outside its band do?** [08 §9.2-§9.3](./08-stats-and-formulas.md) priced the raid and [10 §8-§9](./10-content-and-encounters.md) the on-ramp without a written target; the sweep measured and no row said what the number should be (audit M6-BAL-03; `build/plan/ship/00-plan.md` §6 row #9). | [08 §9.2, §9.3, §9.3a](./08-stats-and-formulas.md), [10 §8, §9.1](./10-content-and-encounters.md), [Q-90](#q-90), [BL-85](#bl-85), [BL-110](#bl-110) | **DECIDED (2026-09-15):** first-attempt clear for the benchmark six / twelve, all-Common, 200 seeds, each rung at the gear it is sized for. The on-ramp at morale **45** (the fresh guild): A0 ≥ 90 · TR 55 (40-70) · A1 75 (65-85) · A2 65 (55-75) · A3 50 (40-60) — the wave-8 completability gate (FAIL). The raid at morale **55** (`balance_sweep.gd`'s `REFERENCE_MORALE`, 08 §9.2's own Content costing, the state the farm delivers to the raid door): E1 ≥ 90 · E2 ≥ 80 · E3 75 (60-90) · E4 60 (45-75) · E5 40 (30-55) — WARN from wave 8, asserted from wave 9 with the tier pass; the morale-45 raid cells print beside the bands as the "after a wipe" reading, never as the gate. P(a fresh guild reaches the raid door without a wipe) ≈ 13 %; P(E5 in ≤ 3 attempts) = 78 % (Q-90's arithmetic). A rung outside its band moves by its formula lever only, each step one 200-seed sweep recorded in the row: too hard → the raw swing −1 per swing per re-measure (three steps at most), then its M02/M03 magnitude to 08 §9.5's ½-pulse rule (13 at stage 0); too easy → `target_rounds` +2 with HP re-derived — two steps at most on the on-ramp, ONE on E1-E5 (the mechanic lever having gone first — BL-115). BL-85 closes: no Tier 1 encounter authors M01 on one tank (TR carries M03 — the fire — and A3 M04; E3 is the tier's first swap; `TANK_SWAP_NEEDS_A_PARTNER` stays true and dormant) and `Encounter.validate()` refuses the combination. Because TR and A3 share one budget (183 HP, 8 ×2) with A3 carrying three mechanics to TR's one, A3 is EXPECTED to land under TR on the first pass; its band and the too-hard rule are the answer, not a wall. The first 200-seed pass is also expected to land A1 and A2 ABOVE band (the sim's site-weighted roll taxes DPS less than 08 §8.8's published tax the rows were derived under); the +2 arm then fires once — the rule working, not a mistake — ruled by the loop under the designer's 2026-09-15 delegation |

---

## 7. Canon ambiguities to confirm

These are places the designer's own notes conflict with themselves or are silent. **They are normal for notes at this stage** and none of them is an error to be embarrassed about — the notes were written to think with, not to build from. What each one needs is a sentence of confirmation, because in every case two readings are defensible and they produce different games. No document in the set has silently corrected any of them.

| # | The ambiguity | Where | What it blocks | Needs |
|---|---|---|---|---|
| C-01 | Two morale bands carry the **identical state name and identical effect text**: `70-80 \| Very Happy \| Further reduced mistake chance` and `80-90 \| Very Happy \| Further reduced mistake chance` | raw notes, Morale table | One of ten bands is invisible to the player; the name cannot be a save token or telemetry key | A rename, or a ruling that there are nine bands (Q-07) |
| C-02 | **Band boundaries overlap at every step** — `0-10`, `10-20`, `20-30` … `90-100` — so nine morale values sit in two bands | raw notes, Morale table | Every band lookup in the codebase | An inclusive/exclusive rule (Q-06) |
| C-03 | The sentence governing rarity vs morale is **grammatically incomplete**: *"All values above are have within tier limits for mistakes based on their tier -"* | raw notes, below the Morale table | The whole mistake-chance model; at least three readings are possible and they produce different math | Confirmation of which reading was meant (Q-08) |
| C-04 | Severity adjectives are **not strictly ordered**: `10-20` and `20-30` are both "Increased mistake chance", and `30-40` is "noticeably higher" while the *lower* `20-30` is only "Increased" | raw notes, Morale table | Read literally, raising a raider's morale could make them worse | Confirmation that the table is monotonic in morale value and the adjectives are loose prose |
| C-05 | Six reputation ranks are listed but **only four have described effects** — `Established` and `Legendary` appear once and are never mentioned again. Rank names are also inconsistently capitalised (`@renowned`, `@Rank unknown`) | raw notes, Guild Reputation | A third of the progression ladder, and doc 04 cannot build the Tavern | Effects for both ranks (Q-22, Q-23) |
| C-06 | **Rare's stopping rank and starting gear are both unstated.** Canon says Common stops at Respected and Uncommon at Renowned but never says when Rare stops; and Rare is the only rarity described behaviourally with no gear clause | raw notes, Guild Reputation | The middle of the recruit progression | One line each (Q-25, Q-27) |
| C-07 | **Healer weapon stats are explicitly TBD by the designer:** *"Will have mana or power unsure how much) we need to discuss if we want to have 2 variables or not. Stats TBD until we establish the healing/Mana formulas."* | raw notes, Weapons | Six named items and all healer tuning | The Mana ruling (Q-02), then the stat blocks |
| C-08 | **No base HP exists anywhere** for any class or rarity, while HP appears on almost every item | both sources | Every survivability, healing and boss-damage number | A base HP table (Q-03) |
| C-09 | **`AC = 2 damage reduction` is ambiguous English** — "2 per point of AC" and "1 damage per 2 AC" both parse, a 4× difference — and its scope is never stated (physical only, or spells and raid-wide too) | raw notes, Stat definitions | Every combat number | The AC ruling (Q-01) |
| C-10 | Canon has **exactly one numeric mistake value** — Legendary's "near 1% chance of mistake" — with no unit. Per round? Per action? Per encounter? | raw notes, Guild Reputation | The denominator of every percentage in the project | The cadence ruling (Q-05) |
| C-11 | **`Guild disband` is named as a consequence and never defined.** It hangs off one raider's band with no statement of what it does or how one raider triggers a guild-wide event | raw notes, Morale table | The only loss condition in the game, and the save architecture | The disband ruling (Q-10) |
| C-12 | **The two sources disagree on Encounter 3.** Raw notes: "Head + stronger shared gear". Ideaboard §4: `Boss 3 \| Head \| —`, and no per-class table shows a second drop | both sources | One encounter's drop pool and the tier's gearing pace | A ruling (Q-34) |
| C-13 | **The slot matrix and the drop tables disagree on families** in two places: Warrior Head is matrix-exclusive but both classes get the identical helm; and Rogue shares the `Warrior/Rogue/Bard 1H` family in the matrix while the raid tables give it a separate dagger line | ideaboard §1 vs §3 | Whether there are four armour families or five, and whether the 1H family is contested | Two rulings (Q-32, Q-36) |
| C-14 | **Item names are not unique keys.** `Raider's Leggings` carries three different stat blocks; `Basic Raid Staff` three; `Worn Leggings` is 2 AC for Warrior/Bard and 1 AC for healers; `Raider's Boots — 4 AC / +4 HP` is identical in name and stats across two families the matrix separates | both sources | Any name-keyed data model | Internal keys plus two naming calls (Q-33) |
| C-15 | **Ten named Tier 1 items exist with no stat block:** `Raid Trinket` (all nine classes), `Final Headband`, `Final Eyepatch`, `Basic`/`Strong Healing Weapon`, `Cleric`/`Druid`/`Shaman Weapon`, `Mage Staff`, `Wizard Staff`. The transcription confirms these are open items, not gaps in transcription | ideaboard §5 | The tier's capstone — the payoff the whole macro loop points at — is unquantified, and doc 11 cannot price it | Stat blocks, or acceptance of doc 11's interim 1.4× rule |
| C-16 | **Power appears on zero Tier 1 Adventure armour pieces** and on most Tier 1 Raid pieces, with two unexplained exceptions inside the raid tier (Monk's headband has none, Rogue's eyepatch has +2) | ideaboard §2, §3, §5 | Whether the three melee classes have access to their primary stat for the whole Adventure phase | Confirmation that it is intended pacing (Q-39) |
| C-17 | **The Bard source note contradicts the Bard table it annotates:** *"Mana can appear on these pieces and compete with Power"* — but every Warrior/Bard raid piece carries Power and no Mana | ideaboard §3.2 | Whether Warrior/Bard is a contested family, and whether the Bard has a primary stat before its Boss 5 capstone | A ruling (Q-43) |
| C-18 | **The ladder's own ordering and endpoint are withdrawn by canon** in the line after the list: *"This continues or can go raid raid, adventure adventure, obviously they will need names later, but this is a placeholder"*, plus `Adventure 2 TBD ---` | raw notes, Adventure's Board | The macro cadence and the content budget; the board must be data-driven either way | A cadence ruling (Q-54) and, eventually, names |
| C-19 | **Encounter naming differs between sources.** The raw notes label the five slots `Encounter 1 (Trash)` … `Encounter 5 (Main boss)`; the ideaboard labels the same five columns `Boss 1` … `Boss 5` — so the trash pull is "Boss 1" in every loot table | both sources | Every UI string and data key referring to encounter identity — and doc 12 cannot tell whether slot 1 needs a boss sprite or a reused trash pack | One canonical vocabulary |
| C-20 | **Raid size 12 with no composition rule.** Canon fixes 12 across 9 classes with "most fights normally requiring 2 tanks" and gives no per-class minimum or maximum, no healer count, and no statement on duplicates | raw notes, Classes | Every boss HP value, via the benchmark comp | Two rulings (Q-45, Q-20) |
| C-21 | **Raid size 12 vs "1 Trash mob".** Canon never scales the party down, so read literally the first tutorial fields twelve raiders and two tanks against one mob, before the Tavern is in use | raw notes | Both tutorials | A party-size ruling (Q-55) |
| C-22 | **The tutorial reward count is inconsistent** — each tutorial gets "1 crap trinket" but the skip paragraph says "a special loot piece" singular — and its stat, "+1 dps", **maps to no defined stat** (canon's stats are AC, Power, Mana; Damage appears only on weapons) | raw notes, Adventure's Board | Two reward records and the skip warning copy | A ruling (Q-55) |
| C-23 | **Trinket naming is inconsistent within four consecutive lines:** `Adventure's Charm of Health/Armor/Mana`, then `Adventures Charm of Power` with the apostrophe dropped — while all armour uses `Adventurer's`. `+7 Hp` also lowercases the P | raw notes, Trinkets | Icon filenames and any name-keyed asset lookup | Permission to normalise (Q-42) |
| C-24 | **Building and board names differ between sections:** `Market` in the town layout vs `blacksmith/Merchant` in the core verbs; `Adventure's Board` as a heading vs "the adventure board" in the verbs | raw notes | Painted signage, save keys and every UI string | A naming ruling (Q-68) |
| C-25 | **Five systems are marked "Maybe" and their absence cascades:** `Blacksmith (Maybe)`, `Equipment upgrades < Maybe`, `Crafting Supplies < Maybe`, `Salvaging < If we do crafting`, `Train raiders < Maybe if we have level ups`. "If we do crafting" has **no antecedent anywhere** — canon never states whether crafting exists | raw notes, Town | A whole building, a Market tab, and whether gear is the only power axis | Two rulings (Q-13, Q-14) |
| C-26 | **`Legendary` names two different things** — the top reputation rank and the top raider rarity — and both appear on the same recruit screen. Rarities are also inconsistently capitalised across the notes | raw notes, Guild Reputation | Every UI string, save key and log line mentioning Legendary | A display convention (Q-91) |
| C-27 | **Morale's own foundation is declared provisional by canon:** *"Gaining and losing Morale will be based on their back stories largely"* — no backstory exists in either source — and *"We could have raiders also know their bis … This is all just concepts and can easily be revisited"* | raw notes, Morale | The triggers and magnitudes that the entire meso loop spends its time on | Confirmation that doc 05 §7's invented trigger table is the right shape, plus the wishlist ruling (Q-70) |
| C-28 | **Failure cost is absent from canon entirely.** Nothing states what a wipe costs — no time, coin, gear or morale consequence — in a game modelled on one called *It's A Wipe!* The only loss language anywhere is inside the morale table | both sources | The whole of doc 01 §6 | Confirmation of the proposed cost model (Q-52, Q-53) |
| C-29 | **The canon emoji set is not one ramp.** 87 is a heart (❤️) while 54, 31 and 14 are faces (🙂 😒 😡), with no rule for where the ramp switches and six of ten bands unspecified | raw notes, example roster | The single most-read visual element in the game | A ten-step glyph set, or permission for doc 13 to author one |
| C-30 | **Almost everything doc 14 owns is unstated.** The entire technical direction is *"Likely engine: Godot"* — no version, no renderer, no platform, no resolution, no input model, no save model, no session length, no business model, no price | raw notes, Direction | The first line of code | The engine pin (Q-15) and confirmation of doc 00 §6's proposals |
| C-31 | **There is essentially no art brief.** The complete visual direction is three lines: a 2D-HD look "similar to *Octopath Traveler*", "Aseprite is in the project root", and "'Really awesome frontend design' is a priority" — no resolution, palette, camera, projection, character or building description, biome, or second style reference | raw notes, Direction | Doc 12 §3–§6 is proposal rather than refinement, at a far higher proposal-to-canon ratio than the gameplay docs face | A review pass on doc 12 rather than a single ruling |
| C-32 | **The nine `ideaboard/` screenshots have no recorded provenance**, and the entire Tier 1 item corpus derives from them | ideaboard | Shipping any item table | Written confirmation of authorship (Q-21) |

---

## 8. Ownership gaps — nobody owns these at all

Not questions with two answers; topics with no home. Each needs an owner assigned before it needs a decision.

| Gap | Evidence | What is already committed to it | Recommendation |
|---|---|---|---|
| **Audio and music** | The word "music" appears nowhere in the doc set | Doc 13 §12.4 defines eleven named UI sound hooks (`ui.stamp` is called "the game's signature sound"; `ui.silence` ducks all buses to −60 dB for 400 ms) and defers mixing to "audio's call" — to nobody. Doc 02 §9.1 assigns a per-rank Audio column (wind and sparse lute at Unknown → anvil ring at Respected → bell toll at Renowned → cheer stinger and leitmotif at Legendary). Doc 14 §4 lists a bare `game/autoload/audio.gd`; doc 13 S15 lists an audio settings page | **Assign an owner.** The combat-sim soundscape is the urgent part — the mistake stamp fires dozens of times per raid, and a signature sound that grates is worse than no sound. **→ [Q-97](#q-97) (the direction, as built) and [Q-98](#q-98) (beds, ambience, voice, the world layer — the owner question, on the designer's page as row #46), 2026-09-15** |
| **Playtest** | Eight docs defer decisions to playtest and no doc plans one | Doc 00 §8's VS1/VS5/VS8 and R2 are all worded as playtest protocols ("8 of 10 testers name the morale number"); doc 13 §8.6 specifies a 2-second screenshot recall test with a ≥90% gate; doc 04 Q11, doc 07 OQ-2/OQ-4, doc 08 §8.6/Q16, doc 12 Q8 and doc 03 §8.1 M3 all say "revisit after playtest" | **Assign an owner and answer four questions:** who tests, when, on what build, and how each deferred question actually gets answered. Until then "revisit after playtest" means "never" |
| **Production schedule and staffing** | Doc 10 §1, §12 and its Related list all point at a `16-production-roadmap.md` that had not been written when this row was filed — [16 — Production Roadmap](./16-production-roadmap.md) exists now (dated 2026-09-08) with the milestone plan, so the gap that remains is the *staffing* half | Doc 10 §12 counts 42 encounters, 21 boss actors, 26 trash actors, ~360 item records and 90 icon renders, and doc 02 §8 prices features in engineering weeks and art units, but nothing converts any of it into a schedule | **Either write doc 16 or delete the references.** Interim: doc 00 §6.3 owns the volume envelope and its cut order; doc 10 §12.3 holds the per-tier art constraint. **Schedule and staffing genuinely have no owner** |
| **Version control** | ~~This project is not a git repository~~ — it is one now (branch `master`; [BL-74](#bl-74)'s export path and [14 §10.3](./14-technical-architecture.md) tag from it), so this gap is closed | Doc 14 §10 assumes git for release tagging and §6 assumes it for the content pipeline | ~~**`git init` alongside Q-18's move off OneDrive.** Same afternoon, both problems~~ — done; only Q-18's move is still open |

---

## 9. Answer these six first

Ten minutes, six signatures, and the project can start. Each of these is currently answered **two or more ways in shipped documents**, so the cost of not answering is not delay — it is two teams building different games.

| Order | Ruling | Q | Say | Because |
|---|---|---|---|---|
| **1** | **AC is a diminishing-returns curve**, `mitigation = (AC×2)/((AC×2)+60)`, capped at 0.75 | Q-01 | "R3, `AC_K = 60`" | It is the only reading where the tank is threatened and cloth survives more than two hits. Every boss number in the project is downstream, and doc 10's encounter tables are currently computed under the reading doc 08 rejects |
| **2** | **Mana stays a magnitude stat; add class-fixed Focus, off gear** | Q-02 | "Model A+" | Canon asked this question directly and four docs answered it differently. It changes no item table, and it stops doc 07's healer mistakes spending a pool that no document defines |
| **3** | **One mistake table, one owner, one cadence** — doc 08 §8.8 owns the equation and coefficients with doc 05's per-rarity `sensitivity` imported; the roll is **per raider per mechanic event** | Q-04, Q-05 | "08 §8.8 owns it; per mechanic event" | Five tables exist for the game's most important number and they disagree by 2× on the same raider. Four docs then delete their copies |
| **4** | **No mid-raid input** | Q-09 | "No Calls" | Doc 00's pillars, anti-goals and acceptance test say one thing and doc 07 §3.2 does another — and docs 13 and 14 have already built for doc 07. This is the only row where deciding *either* way beats deciding late |
| **5** | **Morale bands: half-open lower-inclusive; rename 70-80 to "Quite Happy"** | Q-06, Q-07 | "Half-open; Quite Happy" | Two signatures unblock four documents. `band_index = min(9, floor(morale/10))` reproduces all four of canon's own roster rows, and Natsuna at 87 keeps "Very Happy" |
| **6** | **Godot ≥ 4.3, renderer Mobile, repo off OneDrive and under git** | Q-15, Q-18 | "4.3+, Mobile, move it" | Thirty seconds. `Parallax2D` only exists from 4.3 and doc 12's seven-layer stack is authored against it; Compatibility deletes four of the eight ingredients that make up the look; and OneDrive plus Godot's `.godot/` cache corrupts imports while being the only backup canon has |

**The next three, if there is time** *(historical — 2026-09-15: every row here is ruled; Q-13's "Blacksmith yes" and Q-14's "ship Drilling" were NOT taken, because canon's own lines are "Maybe" and a false conditional — see their rows)*: Q-13 (Blacksmith yes at upgrades-only, crafting no) unblocks docs 02, 11, 12 and 13 with one signature. Q-11 (Master Looter with a Suggested button) unblocks the raid-flow UI and doc 05's central lever. Q-12 (roster cap 15→20 by rank) unblocks the roster screen and settles a number doc 13 currently renders two ways on the same rank.

---

## 10. BL - the build-loop decision log

Rulings the build loop **made and shipped**, appended as the work landed. These are
not rows awaiting a signature: each one names the code that holds the decision and
the test that pins it, so the designer's job here is to overrule what they disagree
with rather than to choose. IDs are `BL-` per §2.2 and run from 19 because this
series was originally numbered `Q-` and was reprefixed rather than renumbered.

Entries are in the order the build loop wrote them, which is not ID order - the
numbering was assigned per iteration, and reordering the file now would move every
line number the handoffs and BUILD_STATE cite. Read by ID, not by position.


---

<a id="bl-19"></a>
### BL-19 — Warrior's head slot: does the matrix or the item table win? *(RESOLVED — build loop, 2026-09-09)*

**Owner:** [09 §4.4](./09-items-and-itemization.md) · **Signal:** Silent · **Blocked:** loot routing for two classes

The canon slot matrix gives Warrior a head family of its own (`Warrior`) while giving Bard
`Warrior/Bard`. Every canon **item table** contradicts it: the Tier 1 Adventure table is headed
"Warrior / Bard Armor" and ships a single shared `Iron Adventurer's Helm — 3 AC / +3 HP`, and the
Tier 1 Raid tables list an identical `Raider's Helm — 5 AC / +5 HP / +1 Power` on both class tables.

| Option | Consequence |
|---|---|
| Matrix wins — keep a Warrior-only head family | No item exists in it at any rung, so Warriors have a head slot they can never fill |
| **Item tables win — Warrior and Bard share one head family** | Matches every shipped item; costs the matrix's asymmetry, which no content backs up |

**✅ Resolved: the item tables win.** `ItemFamily.WARRIOR_HEAD` has been removed and
`WARRIOR_BARD_HEAD` is claimed by both Warrior and Bard. Done before any save data existed, so the
enum's append-only rule was not yet binding. Reversing this means re-adding the family *and*
authoring Warrior-only head items at every rung — cheap now, expensive after Tier 2.

---

<a id="bl-20"></a>
### BL-20 - Adopting docs/05's mistake coefficients costs docs/08's "one step, never two" guarantee *(RESOLVED with a caveat - build loop, 2026-09-09)*

**Owner:** [08 SS8.8](./08-stats-and-formulas.md) - **Signal:** Silent - **Affects:** how much morale matters

Q-04/05 ruled that docs/08 owns the mistake equation while importing docs/05's
per-rarity `sensitivity`. Implementing that merge revealed a consequence neither
document states: **docs/08's claimed property does not survive it.**

docs/08 SS8.8 asserted its own coefficients guaranteed *"Morale can invert exactly
one rarity step, never two"*. Under docs/05's coefficients, which the ruling
adopted, that is false:

| Comparison | Value | Result |
|---|---|---|
| Very Upset Rare | 22.4% | worse than... |
| Loves Their Guild Common | 13.9% | ...a beloved Common - a **two-step** inversion |
| Very Upset Uncommon | 46.5% | worse than a beloved Common too |

The one property that **does** hold is the canon-anchored one: worst Legendary
(2.40%) still beats best Epic (2.64%), so canon's *"you wont have to worry about
losing your higher tier raiders unless you are BIG dumb"* is intact.

**Shipped as-is, deliberately.** Canon's stated thesis is that *"the complexity
comes from the stories and decisions surrounding it"* and that morale management
is the core skill. A model where a beloved Common outperforms a miserable Rare
makes morale the dominant lever, which is the game canon describes. docs/08's
one-step guarantee was its own design property, not a canon requirement.

**For the designer:** if you want the one-step guarantee back, raise the per-rarity
`floor` values (or lower the `ceiling` values) in `sim/core/Formulas.gd` until the
bands stop overlapping - docs/08 SS8.8 calls that the "strict policy". The cost is
that morale becomes almost inert for mid rarities, which is the trade docs/08
itself flags. Test `test_morale_can_invert_more_than_one_rarity_step` pins the
current behaviour and will fail loudly if the policy changes.

---

<a id="bl-21"></a>
### BL-21 - How many mistakes per encounter is the right number? *(RESOLVED at Tier 1 by the sweep - re-measure when Tier 2 ships)*

**Owner:** [08 SS8.8](./08-stats-and-formulas.md) coefficients, [07 SS5.3](./07-combat-simulation.md) cadence - **Signal:** Loud

docs/07 SS5.3 rules three roll sites - one per action, one per mechanic check, one
ambient per living raider per round - and rejects per-round rolling explicitly,
because *"a boss that demands four responses per round is no more dangerous than
one that demands nothing"* and docs/10 would lose its main difficulty dial.

It then states that docs/08's base rates *"must be rescaled for the resulting
checks-per-encounter count"*. **That rescale has not happened**, and it interacts
with something docs/08 relies on: its DPS-tax argument
(`effective = nominal * (1 - mistake_chance)`, a raid of Content Commons running
at 78% of nominal) models exactly **one action roll per raider per round**.

**Shipped compromise:** `Formulas.ROLL_SITE_WEIGHT` weights each site.

| Site | Weight | Reasoning |
|---|---|---|
| Action | 1.00 | Carries the published chance unscaled, so docs/08's DPS tax stays true |
| Mechanic | 1.00 | docs/10's difficulty dial IS how much a fight asks, so a check must be as hard as acting |
| Ambient | 0.35 | AFK, arguments and loot calls are colour, not a second full roll every round |

**Why it is still open.** Nobody has measured the resulting mistakes per
encounter. A back-of-envelope estimate for 12 Content Commons over a 12-round
fight is somewhere near 60-80 mistakes, which would be an unreadable wall even
with docs/07 SS5.5's anti-spam guards. The number could equally be fine once the
guards, class gating and context requirements thin the eligible set.

**First measurement (build loop, 2026-09-09).** A benchmark twelve of Content-ish
Commons in starting gear against E1 produced **46 mistakes across 12 rounds** —
roughly 3.8 per round raid-wide, or 0.32 per raider per round. The story-tier log
is dense but each line is individually legible and funny; whether it reads as a
wall depends heavily on doc 13's log-collapse widget (identical Minor events in
one round collapse to a single counted line). The anti-spam guards are confirmed
binding: at most one Critical per round raid-wide, and no raider repeats a type
in consecutive rounds.

**ANSWERED by the sweep (build loop, 2026-09-09).** 1080 runs across 135 cells:

| Cell | Mean mistakes / encounter |
|---|---|
| Legendary, raid gear, morale 95 (best) | **1-3** |
| Common, adventure gear, morale 55 (typical early) | **89-129** |
| Common, raid gear, morale 15 (worst) | **312** |

**The volume is far too high in the lower half of the range.** A readable
scrolling log tops out somewhere near 200 events of *all* kinds; 312 mistakes
alone is a wall. The good news is the top end is exactly right — a Legendary
raid fumbles once or twice a fight, which is precisely the feel canon describes.

So the fix is a rescale, not a redesign, and `Formulas.ROLL_SITE_WEIGHT` is the
knob. **Principled target:** make the per-round aggregate across all sites equal
docs/08's published per-round chance, which is what its DPS-tax argument assumes.
With ~2 rolls per raider-round that means roughly `1 - sqrt(1 - p)`, i.e. about
0.53x the published rate per site. Re-run the sweep after changing it.

**RESOLVED (build loop, 2026-09-09).** `ROLL_SITE_WEIGHT` rescaled from
`1.00 / 1.00 / 0.35` to **`0.55 / 0.55 / 0.15`**, so the per-round aggregate across
sites approximates docs/08's published per-round chance — which is what its
DPS-tax argument assumes. Ambient sits deliberately below an equal split because
going AFK is colour, not a second combat roll.

Re-measured across 1080 runs: every cell is now under the readable limit.

| Cell | Before | After |
|---|---|---|
| Legendary, raid, m95 (best) | 1-3 | **0-1** |
| Common, adventure, m55 (typical early) | 89-129 | **34-72** |
| Common, raid, m15 (worst) | 312 | **144** |

Reopen only if playtesting says the log still reads as a wall.

**Resolved with data, not argument.** `tools/balance_sweep.gd` reports mistakes per
encounter by rarity and morale band on every run, and the figures above are its. The
per-TYPE counts inside one encounter — which is what the line corpus had to be sized
against — are recorded in BL-80. Tiers 2-5 re-run the sweep when they are named
([BL-69](#bl-69)); until then this is a Tier 1 answer, which is all the content there is.

---

<a id="bl-23"></a>
### BL-23 - What does a new guild own on day one? *(DECIDED - implemented)*

**Owner:** [04](./04-recruitment-and-roster.md) / [01](./01-core-loop.md) - **Signal:** Loud, and blocking

Canon never says. It cannot be answered with "nothing", and the reason is
arithmetic rather than taste:

| Fact | Source |
|---|---|
| Raid size is 12 | ✅ CANON, raw notes |
| A Common hire costs 15 G | [11 §S1](./11-economy-and-crafting.md), the project's only recruit price table |
| A new guild holds 60 G | [01 §8.0](./01-core-loop.md) Q-13 |

Sixty gold buys four Commons. A player starting from an empty roster cannot
reach a first raid, and no amount of Tavern refreshes fixes it. **A starting
roster is forced by canon's own numbers; only its shape was ever a choice.**

**Decision - the benchmark twelve, all Common, in canon starting armour.**
[06 §6.4](./06-classes-and-roles.md) Template A: 2 Warrior, 2 Rogue, 2 Wizard,
and one each of Monk, Bard, Mage, Cleric, Druid, Shaman.

**Why that shape:** it is the composition [08 §9.1](./08-stats-and-formulas.md)
and [10 §5.3](./10-content-and-encounters.md) both adopt verbatim, and every
balance number in the project is derived against it. Starting the player on the
roster the tuning assumes means the opening hours are the difficulty the sweep
actually measures rather than an accidental variant of it. Twelve also leaves
three slots under the Unknown cap of 15 ([04 §12.1](./04-recruitment-and-roster.md)),
so hiring still matters on day one and [01 §8.0](./01-core-loop.md)'s "one Common
hire plus potions" reading of the opening purse survives intact.

All twelve are Common, which is canon's own description of rank Unknown: *"you
can only find the worst players to join your guild, they have 0 raid experience
etc. (Common raiders)"*. They arrive at morale **45**, the Common baseline from
[05 §8](./05-morale.md) - "Slightly Annoyed" before anything has gone wrong,
which is the correct opening note for this game.

Canon's own named examples take their canon classes: **Bob** the Warrior,
**Greg** the Rogue and **Steve** the Mage are all on the opening roster, so the
first thing the player reads is the design notes quoting themselves. **Natsuna
is deliberately absent** - canon makes her a *named Legendary* shaman and "you
can only ever find 1 Legendary per class", so she is a thing to be found.

Implemented in `game/core/StartingRoster.gd`, seeded from the guild name so a
new game is reproducible from a screenshot. Reopen if the designer wants the
first raid to be a hiring problem instead of a management one.

---

<a id="bl-24"></a>
### BL-24 - What is one rung of the Adventure's Board? *(DECIDED - implemented)*

**Owner:** [10](./10-content-and-encounters.md) / [13](./13-ui-ux.md) - **Signal:** Quiet, structural

`RaidSim.run()` resolves exactly one encounter. Tier 1 ships five (E1-E5). Canon
lists a board of missions of varying size without saying how a multi-encounter
raid is chunked, and [13](./13-ui-ux.md) S13 wants an interstitial with HP and
mana carry-over between encounters that does not exist yet.

**Decision: one board rung = one encounter**, in tier order, with clears
remembered in `GameState.cleared`. It is the honest mapping of the sim and the
content that exist, it gives real progression today, and S13's carry-over
becomes an addition rather than a rewrite. Revisit when the interstitial lands.

---

<a id="bl-25"></a>
### BL-25 - Where do LOW / ELEVATED / SEVERE sit? *(DECIDED - implemented)*

**Owner:** [13](./13-ui-ux.md) §10.3 - **Signal:** Quiet

[13 §10.3](./13-ui-ux.md) requires the risk readout to carry a word and a hatch
density, "never colour alone", but sets no thresholds.

**Decision: the word describes a RATIO against the same comp at Content**, not
an absolute mistake count - ELEVATED at 1.25x, SEVERE at 2.0x. That way the word
answers "what is morale costing me tonight", which is the decision the screen
exists for, instead of "how big is this fight", which the encounter name already
says. Both constants live in `RaidPlan` and are one edit to retune.

---

<a id="bl-26"></a>
### BL-26 - Raid 1 has no on-ramp, so the board is a dead ladder *(RESOLVED - the ladder has a bottom step)*

**Owner:** [10](./10-content-and-encounters.md) - **Signal:** Loud, and blocking a playable game

**Measured, not suspected.** The starting roster cannot clear E1 at *any* morale:
20 seeds at morale 95 in canon starting armour return 10 soft wipes and 10
attritions, zero clears. The golden `e1_commons_starting` has recorded a soft
wipe for this roster since it was written.

**This is not a tuning fault.** [08 §9.2](./08-stats-and-formulas.md) derives
Boss 1's HP from "Raid DPS at attempt" = 182, which is the row for a raid that
already owns **Tier 1 Adventure gear**. Raid 1 was never sized for starting
armour, and it should not be re-tuned to be.

**The missing piece is canon's own on-ramp**, which is content nobody has
authored: *"Adventure 0 - 1 Trash mob (Just for learning - 1 crap trinket)"* and
*"Adventure 1 - a few trash encounters and a mini boss"* (raw notes, *Adventure's
Board*). Adventures are where a starting guild actually plays and where Tier 1
Adventure gear comes from. `sim/model/Encounter.gd` already reserves the slot
keys `A1`-`A3` for them.

**Consequence today:** the Adventure's Board offers Raid 1, the guild cannot
clear its first rung, and E2-E5 are unreachable. The loop is wired and works;
the ladder has no bottom step. **This is the next content task and it gates a
completable game.** Pinned by `test_raid_one_cannot_be_entered_in_starting_armour`
so it cannot be quietly "fixed" by buffing starting gear.

---

<a id="bl-27"></a>
### BL-27 - Nobody has any output in canon starting gear *(RESOLVED - implemented)*

**Owner:** [08](./08-stats-and-formulas.md) §8.5 / §5.3 - **Signal:** Loud, and it blocks a completable game

**This is the root cause under BL-26, found by authoring the Adventure tier and
measuring it.** It is not a content problem and it cannot be fixed with content.

✅ CANON gives common recruits *"Starting armor"* - **four armour pieces and no
weapon**, carrying **no HP and no Mana** on any piece. Our `data/items_starting.json`
models that faithfully: `starting_set()` returns exactly four armour items.

Both output formulas read entirely off gear:

| Formula | Source | Value in starting gear |
|---|---|---|
| `heal_power = weapon.heal_base + Mana x 0.80` | [08 §8.5](./08-stats-and-formulas.md) | `0 + 0 x 0.8 =` **0** |
| melee and spell damage | [08 §8.1-8.4](./08-stats-and-formulas.md) | weapon-derived, so ~**0** |

So a fresh guild's healers heal nothing and its damage dealers barely scratch.

**Measured consequences:**

| Measurement | Result |
|---|---|
| A1 (705 HP, party 6, starting armour, morale 70) | **0 clears in 24**, all soft wipes |
| A1 with enemy HP scaled to **40%** | **still 0 clears** - they are dying, not failing to kill |
| E1 (Raid 1 rung 1) with the benchmark twelve at morale 95 | **0 clears in 20** (BL-26) |

Scaling HP down does not help, which is the diagnostic that matters: the party
dies either way, because one healer with `heal_power = 0` cannot answer a 21-27
raw/round pull no matter how little HP the enemy has.

**Two documents predicted this in writing and neither was acted on:**

- [16 §E1.3](./16-production-roadmap.md): *"canon healer weapon stats are TBD and
  canon starting armour has 0 Mana, so a Mana-only heal formula heals nothing and
  Adventure 1 is literally unwinnable. Doc 08 must publish `base` and `k` for
  `heal = base_class + k x Mana`"* - note **`base_class`**, not `weapon.heal_base`.
- [10 §8](./10-content-and-encounters.md) repeats it for A3 and instructs, in
  terms, **not** to soften A3's swing to hide it.

**The fix must be a class-fixed output floor**, which is the same shape as the
already-ruled Q-02 *Model A+* ("class-fixed and never appears on gear"). Q-02
shipped its `ManaModel.MAGNITUDE_PLUS_FOCUS` enum and its comments, but **no
Focus term and no class base were ever implemented** - `Formulas.heal_power()`
is still purely `weapon + Mana`.

**Deliberately NOT done here**, because it is a formula change that moves every
golden, the whole balance sweep and E5's validated 22-round first clear, and
bundling it with content authoring would put two risky changes in one commit:

1. Publish `HEAL_BASE_CLASS` and a melee/spell counterpart in [08](./08-stats-and-formulas.md).
2. Implement them, re-run the sweep, regenerate goldens **deliberately**, and
   re-confirm E5 still lands on 22 rounds.
3. Then delete `test_a_starting_party_cannot_yet_clear_the_first_adventure` and
   `test_raid_one_cannot_be_entered_in_starting_armour`, which exist to fail
   loudly the moment this lands.

**Do not fix this by giving starting recruits a weapon** - that contradicts canon
and [10 §8](./10-content-and-encounters.md) - **or by re-tuning A1-A3 or E1**,
which are both authored to their documents' own arithmetic.

---

### BL-27 resolution - `HEAL_FLOOR` and `UNARMED_DAMAGE`, as floors

Published in **[08 §8.5a](./08-stats-and-formulas.md)** and implemented in
`sim/core/Formulas.gd`:

```
UNARMED_DAMAGE = 2                                    # vs the Adventure sword's +5
HEAL_FLOOR     = 6                                    # vs the Adventure weapon's heal_base 14

effective_main_damage(w) = max(w, UNARMED_DAMAGE)     # MAIN HAND ONLY
heal_power(h)            = max(HEAL_FLOOR, h.weapon.heal_base + h.mana * MANA_TO_HEAL)
```

**Floors, not addends — and that choice is the whole reason this was safe to
ship.** [16 §E1.3](./16-production-roadmap.md) asked for
`heal = base_class + k x Mana`. An additive base would have raised **every**
healer in the game and re-tuned content that is already validated. A floor
serves the identical intent - a class can always do *something* - while changing
nothing whatsoever for anyone holding a weapon.

**Evidence that it held:**

| Check | Result |
|---|---|
| E5 first clear (raid_entry gear) | **22 rounds** vs [08 §9.2](./08-stats-and-formulas.md)'s target of 22 - unmoved |
| Golden files | 3 of 5 regenerated **byte-identical**; only the two *starting-gear* scenarios moved |
| Balance sweep | SWEEP OK, worst case still 0% at the tier boss |
| Adventure 1, canon starting armour, morale 55 | **50% clear** - was 0% at any enemy HP |

`e1_commons_starting` moved from *soft wipe* to *attrition* (18 -> 22 rounds,
healing 183 -> 580, survivors 6 -> 9), which is the right story: a fresh guild now
survives Raid 1's opening pull but still cannot win a raid it has no business
attempting.

**One test was found asserting the bug.** `test_heal_base_prevents_zero_healing_at_game_start`
asserted `cleric_heal(0, 0) == 1` while its own comment explained why that was
wrong and cited this very question. A test can pin a defect as expected
behaviour and read as coverage while doing it.

---

<a id="bl-28"></a>
### BL-28 - Doc 08 never published a starting-gear DPS stage *(RESOLVED - measured)*

**Owner:** [08 §9.1a](./08-stats-and-formulas.md) - **Signal:** Silent, and it invalidated a whole tier's sizing

[10 §8](./10-content-and-encounters.md) sized every Adventure rung against
**~88/round** (half of stage A) while stating in writing that it was an upper
bound, and instructing: *"Do not replace it with a locally invented figure; ask
doc 08 for the stage."*

The stages are now published in [08 §9.1a](./08-stats-and-formulas.md), measured
by §9.1's own nominal method on the benchmark six: **stage 0 = 16.5/round**,
after A1 = 54.9, after A2 = 58.2. The old figure was **5.3x too high for A1**.

Two things worth keeping:

- **Each rung is sized for the gear the rung before it dropped**, the same rule
  [08 §9.2](./08-stats-and-formulas.md) already applies to the raid tier. Sizing
  every rung against one figure is what made the original table wrong.
- **The first weapon is the largest single upgrade in the game** (16.5 -> 54.9, a
  3.3x jump from one item per raider), because the party starts with none.

---

<a id="bl-29"></a>
### BL-29 - Raid-wide magnitude was derived for a 12-raid *(DECIDED - implemented)*

**Owner:** [08 §9.5](./08-stats-and-formulas.md) / [10 §8](./10-content-and-encounters.md) - **Signal:** Quiet, and it made two encounters unwinnable

M02's magnitude **23** comes from `0.35 x 65` cloth HP, which sizes
*survivability per target* correctly. But its healing-coverage assumption is a
**12-raid with three healers**: a proc costs 23 x 12 = 276, carried by 3 healers
= 92 each. At party 6 with **one** healer - [10 §8](./10-content-and-encounters.md)'s
own stated assumption - the same magnitude costs 23 x 6 = 138 carried by one, a
**1.5x heavier burden per healer**.

**Decision: hold raid-wide damage PER HEALER constant.** 92 / 6 = **15** for a
six-party. Measured, 23 killed the party outright in A2 and A3 rather than
out-timing it; at 15 they clear 65% and 90%.

This is a judgment call on an unvalidated number, not a canon value. If a future
Adventure comp assumes two healers, the same derivation gives a different figure -
which is the point of writing the derivation down rather than the result.

---

<a id="bl-30"></a>
### BL-30 - The Adventure difficulty curve is inverted *(RESOLVED - implemented; SUPERSEDED by BL-110 (2026-09-15))*

**Owner:** [10 §8](./10-content-and-encounters.md) - **Signal:** Quiet

Measured at morale 55, each rung in its own gear stage: **A1 50% clear, A2 65%,
A3 90%** - against ratings of ★, ★★, ★★★. The hardest fight is the easiest to
clear.

**Cause, and it is structural rather than a bad number.** A3's party is **3.5x
stronger** than A1's (58.2 vs 16.5 nominal DPS, because A1 and A2 hand out a
weapon and legs) while A3's incoming damage is only **1.6x** heavier. Gear scales
faster across this tier than pressure does.

**Why A1 at 50% is not itself the bug.** docs/01 §7.2 gives hour one the beat
*"these people are idiots"* with failure meaning *"Comedy"*, and Adventures are
freely repeatable with a cheap wipe cost ([10 §3](./10-content-and-encounters.md)).
A coin-flip first mission in a game called *It's A Wipe!* is the right joke. The
problem is the top of the curve, not the bottom.

**Do not fix this by softening A1.** The honest levers, in order of preference:

1. **Recompute A3's swing at the stage it is actually fought.**
   [08 §9.3](./08-stats-and-formulas.md)'s death clock was applied at 7 AC /
   120 HP, but A3 is fought at **11 AC / 127 HP** - so the intended 3.5-round
   clock is really 4.1 rounds. Restoring a true 3.5-round clock at that stage
   *raises* the swing, and does so by the doc's own rule rather than against it.
2. Give A2 and A3 a second mechanic that scales with gear rather than with HP.
3. Leave it. ★★★ is the Adventure tier's ceiling and its purpose is to fund and
   gate Raid 1, not to be the wall.


**Superseded (2026-09-15)** by [BL-110](#bl-110): the staged on-ramp swings this row derived at each rung's own gear stage are replaced by docs/08 §9.3a's healed clock at stage 0 / all-Common / morale 45 for A0-A3 and TR; the clock was right and the stage was still wrong for a six with one healer. [BL-28](#bl-28)'s stage-0 finding stands — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-31"></a>
### BL-31 - Duplicate protection, with no mechanism given *(DECIDED - implemented)*

**Owner:** [10 §11](./10-content-and-encounters.md) - **Signal:** Quiet

[10 §11](./10-content-and-encounters.md) says raids are *"repeatable, with duplicate
protection"* and leaves the mechanism ❓ OPEN.

**Decision: a BIAS, never a ban.** `Loot.roll_drops()` prefers items that would
upgrade somebody on the roster and falls back to the whole pool when nothing
would. So the fifth pair of boots does not arrive while three raiders are
barefoot, but a pull **always** drops something: a farm run that yields an item
you cannot use is disappointing, whereas one that yields *no item at all* reads
as a bug. `test_a_clear_always_drops_something` pins that.

---

<a id="bl-32"></a>
### BL-32 - Should "Suggested" gear the roster, or the raid that just ran? *(RESOLVED - party first)*

**Owner:** [09 §14.3](./09-items-and-itemization.md) - **Signal:** Quiet, and it changes how the on-ramp feels

[09 §14.3](./09-items-and-itemization.md)'s one-click **Suggested** is Option B,
"need-based" - and `assign_suggested_loot()` implements that across the **whole
roster**, which is the literal reading.

**Measured consequence:** a player farming Adventure 1 with a fixed six sees gear
handed to benched raiders. Twelve A1 clears armed only **4 of the 6 who actually
went**, and Adventure 2 stayed unreachable. Routing the same drops to the party
that ran armed **6 of 6** and opened A2.

Both behaviours are defensible - a guild does want its best gear on whoever
benefits most - but they are not the same game. Options:

1. **Suggest within the raid group first**, falling back to the roster. Matches
   what a player farming an on-ramp is trying to do.
2. Keep it roster-wide and let the player override per row, which they can
   already do. Costs a click per drop during exactly the grind where clicks hurt.
3. Two buttons: *Suggested (this raid)* and *Suggested (whole guild)*.

**Not decided here** because it is a feel question rather than a correctness one,
and the override already exists. Option 1 is the recommendation.

---

<a id="bl-33"></a>
### BL-33 - Loot distribution starves shared-family classes? *(RESOLVED - explained, and it was BL-32)*

**Owner:** [09](./09-items-and-itemization.md) - **Signal:** Quiet

**Measured, not yet explained.** Farming A1 fifteen times and routing every drop
to the six who ran left the Warrior, Cleric, Wizard and Mage each holding an
Adventure main hand, but **both Rogues still holding none** - while 20 items sat
unassignable.

The content is not the gap: every class has an Adventure main hand available, and
Rogues share `ITM_T1_ADV_W1H_MH` with Warrior and Bard, so the pool covers them.
The suspicion is the interaction between the roll bias (BL-31, evaluated against
the full twelve) and the need-first rule - a shared item may keep being consumed
by whoever is checked first while its other claimants stay empty-handed.

Worth a targeted look before the loot system is considered finished. It does not
block: A2 is reachable at 25% with four of six armed.

---

### BL-30 resolution - the clock was right, the stage was wrong

Fixed by **option 1**, which was the recommendation: recompute each rung's swing
from [08 §9.3](./08-stats-and-formulas.md)'s own formula at the stage the rung is
actually fought.

[10 §8](./10-content-and-encounters.md) applied
`boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK x (1 - mitigation))` at
**7 AC / 120 HP for all three rungs**, while its own loot column says each rung is
fought in the gear the one before it dropped.

| Rung | Fought at | Tank | Mitigation | Intended clock | Needed | Was | Now |
|---|---|---|---|---|---|---|---|
| A1 | stage 0 | 7 AC / 120 HP | 18.9% | 5.5 rd | 26.9 | 27 | **27 - already correct** |
| A2 | after A1 | 9 AC / 123 HP | 23.1% | 4.3 rd | 37.2 | 34 | **38** |
| A3 | after A2 | 11 AC / 127 HP | 26.8% | 3.5 rd | 49.6 | 42 | **50** |

**A1 needed no correction at all**, and that is the tell: A1 is the one rung
genuinely fought at stage 0, so the doc got it exactly right (27 authored against
26.9 needed) and got only A2 and A3 wrong. The *method* was sound; it was applied
at one stage instead of three.

This **raises** pressure by the doc's own rule, which is the opposite of the
softening [10 §8](./10-content-and-encounters.md) forbids.

**Measured after, each rung at its own stage's gear:**

| Morale | A1 ★ | A2 ★★ | A3 ★★★ |
|---|---|---|---|
| 45 | 38% | 50% | **13%** |
| 55 (Content) | 54% | 58% | **29%** |
| 70 | 67% | 79% | **50%** |

The ★★★ mini boss is now decisively the hardest fight in the tier - it was
**90%** before, the easiest. A3 at 29% at Content is a gate rather than a wall:
Adventures are "repeatable, freely" with a cheap wipe cost
([10 §3](./10-content-and-encounters.md)), and morale is the player's lever on it.

**Same error class as BL-28 and the iteration-22 raid finding.** All three were a
correct formula read at the wrong gear stage: docs/10's 88/round benchmark, the
raid's DPS-at-attempt row, and now the tank death clock. Worth watching for
whenever a sizing number is quoted without the stage it was computed at.

**One honest caveat.** A1 and A2 now sit within a few points of each other (54%
vs 58% at Content, which is one clear in 24) rather than descending cleanly. The
cause is structural and already documented: the first weapon is a **3.3x** jump in
party output ([08 §9.1a](./08-stats-and-formulas.md)), a bigger step than anything
the fight sizing grows by. Not pursued - A2 is ★★ trash and the meaningful step in
the tier is the mini boss. Two tests pin the shape: every rung hits its intended
clock at its own stage, and A3 clears less often than A1.

---

### BL-32 / BL-33 resolution - they were the same question

**BL-33 turned out not to be a loot bug at all, and not a separate issue from
BL-32.** Measured, the cause is content plus the wrong audience for the roll.

**The content half.** A1's drop pool is eleven entries rolled uniformly, and
canon's family-sharing matrix makes them wildly unequal in how many raiders want
them:

| Entry | Wanted by (12-roster) |
|---|---|
| `ITM_T1_ADV_W1H_MH` | **5** - 2 Warriors, 2 Rogues, 1 Bard |
| `ITM_T1_ADV_W2H_WIZ_MH` | 2 |
| Mage / Monk / Cleric / Druid / Shaman weapons | **1 each** |

So one entry supplies five melee claimants at the same rate a dedicated staff
supplies one caster. A Rogue waits behind two Warriors and a Bard for a 1-in-11
roll. That is canon's contention working as designed ([09 §107](./09-items-and-itemization.md)),
not a defect - but it means melee arm up far more slowly than casters.

**The bug half, and it is BL-32.** [BL-31](#bl-31)'s duplicate-protection bias prefers
items that still upgrade somebody, and that bias is what should have fixed the
asymmetry: as the party arms up, the "still needed" set narrows and the remaining
gaps become far more likely. It never narrowed, because the roll was computed
against **the whole twelve-raider roster**. Benched raiders' unmet needs kept
every entry in the pool forever.

**Both fixed by routing loot to the party that actually went:**

- `record_attempt()` now takes the departing party, stored as `last_party`.
- `roll_drops()` biases against that party.
- `assign_suggested_loot()` offers **party first, then the rest of the roster** -
  still need-based per [09 §14.3](./09-items-and-itemization.md) Option B; it
  just reads "need" as the need of the raiders in the field.

**Measured, same content, same seeds:**

| | Clears to arm the six | Rogues armed | Items stranded |
|---|---|---|---|
| Roster-wide (before) | 15+, never completed | **0 of 2** | 20 |
| Party-first (after) | **8** | **2 of 2** | 0 |

Pinned by `test_farming_arms_every_one_of_the_six_including_both_rogues`, which
names the Rogues specifically because they are the pair the old behaviour
starved.

**What this does not change:** loot is still never auto-applied without the
player (docs/09 §14.3's window still opens), the bias is still a bias and never a
ban (BL-31), and an item nobody in the party needs still falls through to the
roster rather than being forced onto someone.

---

### BL-34 resolution - the click count was the whole complaint

Recommendation (1) shipped: **"Rest until recovered"**, on the Guildhall's roster
tab, directly above the morale numbers it moves. ✅ CANON puts morale maintenance in
the Guildhall, so that is where the control that maintains it belongs.

| Before | After |
|---|---|
| `rest_in_town()` existed but had no UI at all | Two controls: "Rest a day" and "Rest until recovered" |
| Recovery from one wipe was 8-10 unprompted clicks | One click, and it prints the price first: "9 days of rest will settle the roster" |
| The player could not see how far off baseline anyone was | `Morale.rest_ticks_needed()` is the forecast, and it is the same number the rest then costs - a test asserts the two are equal |

**Three things it deliberately is not.**

1. **Not a drift change.** No morale number moved. Raising drift was option (2) and it
   is still rejected for the reason recorded above: it would be tuning around the
   missing comfort-item lever ([05 §7.4](./05-morale.md)) and would have to be undone
   once that lever exists, and drift also carries [05 §7.6](./05-morale.md)'s
   anti-farm role.
2. **Not shelter.** [05 §6](./05-morale.md)'s leave and disband checks fire on every
   tick of the loop. The rest **stops on a departure** and names who left, rather
   than resting through it, and the forecast line warns in advance: *"Resting still
   rolls the leave checks - 3 raiders are at risk."* A convenience that silently
   loses a raider is worse than the clicking.
3. **Not free forever.** Resting costs Day Ticks and nothing else today because
   there is no upkeep yet ([Q-31](#q-31)). When per-run upkeep lands, a multi-day
   rest starts costing gold on its own, with no change to this control.

**What stays open** is the half of the recommendation that needs a building: [05
§7.4](./05-morale.md)'s **comfort items**, which are canon's own named lever
("Manage morale with comfort items") and turn recovery into a gold sink rather than a
wait. That work belongs to the Guildhall's Facilities tab and is tracked in the
backlog, not here. *(Landed since: [BL-38](#bl-38)'s two product lines and
[BL-43](#bl-43)'s buy-and-place on the Facilities tab — `sim/core/Comfort.gd`,
`GameState.buy_furnishing()`, `tests/unit/test_comfort.gd`.)*

**One documentation bug found on the way.** [05](./05-morale.md) pointed at
`06-town-and-guild-progression.md` in four places - the doc that owns the day clock,
comfort items and facility tiers. Doc 06 is *Classes & Roles*; that material lives in
[02 - Town & Buildings](./02-town-and-buildings.md). All four references repointed.

---

<a id="bl-35"></a>
### BL-35 - The full-tier bonus is priced "per lockout", and lockouts do not exist *(DECIDED - implemented)*

**Owner:** [03 §6.1](./03-guild-reputation.md) - **Signal:** Quiet, but it decides whether 50 RP is repeatable

[03 §6.1](./03-guild-reputation.md) prices the full-tier clear bonus as **"all 5
in one lockout"** and gives it both a first-time value (50) and a repeat value (10).
Canon never mentions lockouts, resets or a weekly clock, and nothing in the build
has one - `GameState.cleared` counts total clears and has no notion of a period.

So the repeat column has no event that could ever fire it. Three readings:

| Reading | Consequence |
|---|---|
| Bonus pays once, ever, per tier | The 200 RP tier total in §6.1 is exact and the pacing table holds. Repeat value is dead until lockouts ship |
| Bonus pays on every re-clear of the fifth encounter | 10 RP per boss re-clear on top of the boss's own 13, which is a 77% raise to farming - directly against §6.3's "progression beats farming" |
| Invent a lockout period now | A whole clock, a save field and a UI affordance, for one bonus |

**Decision: it pays once per tier**, the first time all five of that tier's
encounters have been cleared, recorded in `GameState.tier_bonus_awarded` so a
reload cannot re-earn it. This is the reading that makes §6.1's printed "Raid tier
total, first time: 200" literally true and leaves §6.4's pacing table intact - a
test asserts both. `FULL_TIER_BONUS[1]` (10) stays in the table, unused and
documented, so the day a lockout clock lands the value is already sitting there.

---

<a id="bl-36"></a>
### BL-36 - M3's config flag has no telemetry to decide it *(DECIDED - shipped ON)*

**Owner:** [03 §8.1](./03-guild-reputation.md) - **Signal:** Quiet, and it only ever matters to a stuck player

[03 §8.1](./03-guild-reputation.md) says: "Ship **M1 + M2**; keep **M3** behind a
config flag and enable it if telemetry shows stalls." M3 is the adventure catch-up
valve - double reputation from adventures once the player has failed the same raid
encounter five times.

That instruction assumes a telemetry pipeline. This is an offline single-player
game with no analytics, so "enable it if telemetry shows stalls" resolves to
**never**, and §8's Recruit Quality Spiral - which §8 itself calls "a positive
feedback loop on failure" - keeps its steepest edge.

**Decision: `Reputation.CATCHUP_ENABLED = true`.** The flag exists exactly as §8.1
asks, and it defaults on, because:

1. M3 can only ever **add** progress. There is no state in which it makes the game
   harder, so the risk of being wrong is one-sided.
2. Its trigger cannot be farmed: it needs **five recorded failures at one raid
   encounter**, which is a worse way to earn RP than simply clearing anything.
3. The player is told. The board prints "the town has noticed you are stuck", so
   the doubled payout is a visible act of mercy rather than a silent fudge.

What is deliberately NOT done: no change to any RP value to compensate. §6.2's
`catchup = 2.0` is the doc's own number.

---

<a id="bl-37"></a>
### BL-37 - An Adventure is priced whole, but the board serves it in three *(DECIDED - implemented)*

**Owner:** [03 §6.1](./03-guild-reputation.md) / [BL-24](#bl-24) - **Signal:** Quiet, structural

[03 §6.1](./03-guild-reputation.md) prices whole Adventures (Adventure 1 = 25 RP,
Adventure 5 = 125). BL-24 decided one board rung is one encounter, and
[10 §8](./10-content-and-encounters.md) gives each Adventure three rungs. So one
documented award has to become three.

**Decision: split it 20 / 30 / 50**, the same proportions the gold payout already
uses ([11 §F2](./11-economy-and-crafting.md)'s 4 / 6 / 10 of 20), so reputation and
gold agree about which rung is the payoff. Implemented as *cumulative* shares and
differenced, which makes the three rungs sum to the doc's total **exactly** at every
tier rather than dropping a point to rounding: 25 → 5/7/13, 50 → 10/15/25,
75 → 15/22/38, 100 → 20/30/50, 125 → 25/37/63.

**The trap next to this one, worth writing down because it nearly went the wrong
way.** §6.2's formula multiplies `base_award × encounter_tier`, and it is tempting
to apply that to adventures too. It must not be: §6.1 labels the raid table "Tier 1
base awards" and gives the adventure table no such label, and §6.4's pacing table
settles it in writing by pricing **Adventure 2 at 50** - the §6.1 number unchanged -
in the same table where every raid row *is* multiplied (Raid 2 Enc 1-3 = 50 × 2 =
100). The adventure curve is baked into its own table; multiplying would
double-count it and inflate Adventure 5 from 125 to 625. A named test asserts the
50, because the mistake is invisible at Tier 1 where all the content currently is.

---

<a id="bl-57"></a>
### BL-57 - Canon shows Natsuna at 87 morale. Is that her starting value? *(DECIDED - no)*

**Owner:** [04 §11.2](./04-recruitment-and-roster.md) - **Signal:** Quiet, and easy to get wrong in the tempting direction

✅ CANON's example roster reads *"Natsuna — 87 ❤️"*, and [05 §11.2](./05-morale.md) quotes
it again. It is the only morale number canon ever attaches to a named character, so it is
the obvious candidate for `starting_morale`.

**Decision: `starting_morale` stays null on all nine files, Natsuna included.**

[04 §11.2](./04-recruitment-and-roster.md) is explicit about what the field is for:
"**Optional override only.** Default is null, meaning the computed baseline per doc 05
§4/§7.5 — not a fixed 75. Set it only where a specific character's fiction demands walking
in above or below their rarity's baseline."

Canon's 87 is a snapshot of a roster **mid-campaign** — the same mock-up shows Steve at 14,
and nobody thinks Steve *arrives* at 14. Reading a played-game value as an arrival value
would hand the player a Legendary two morale bands above where the system says she settles,
and it would do it by misreading an example as a specification.

A Legendary's baseline is 62 (`50 + 12`), and 87 is exactly the sort of number a
well-managed Legendary reaches through play — which is the better story anyway.

---

<a id="bl-58"></a>
### BL-58 - The Legendary quirks are named here and specced nowhere *(DECIDED — specced, in `Quirks.SPECS`; `legendary_quirks` ships on (W9-QUIRKS))*

**Owner:** [07](./07-combat-simulation.md) - **Signal:** Quiet

> **Status (2026-09-15, W6-LEDGER):** waits in the ship plan's designer table, `build/plan/ship/00-plan.md` §6 row #14 — ship default: the quirks ship INERT and DISPLAYED (`legendary_quirks` off, the "reads as" line on the card; no invented combat effect). The seam is threaded by W7-SIM-EFFECTS; W9-QUIRKS builds the nine only if the page specs them. Answer line on `build/plan/ship/designer-page.md`.

[04 §11.2](./04-recruitment-and-roster.md) defines the `quirk` field as "One
class-flavoured mechanical gift; **specced in doc 07**, named here." Doc 07 does not
mention quirks at all.

**Decision: name them, and ship them inert.** All nine files carry a quirk id, a name and
a one-line "reads as" — *Holds the Line*, *Reads the Room*, *The Totem Holds* — and none of
them does anything yet. Each carries its own status line saying so.

**Why not invent the mechanics.** A quirk is a permanent per-character combat effect on the
rarity that is already strictly the best; inventing nine of them would mean balancing nine
untested exceptions against a sim whose tuning is currently validated by 1,440 sweep runs
and five golden files. That is a design pass, not content work — the same line [04
§8.3](./04-recruitment-and-roster.md) draws for backstory tags.

**What is owed:** doc 07 specs the nine effects, then `quirk.status` comes off each file
and the sim reads them.


**DECIDED (2026-09-15) — specced, in `Quirks.SPECS`, in the four-hook shape the seam documents; `legendary_quirks` ships on (W9-QUIRKS, M).** quirk_warrior "Holds the Line" `{"tank_priority": 1, "immune": ["MIS_TAUNT_LAPSE"]}` — "Never yields the main-tank slot, and never forgets to taunt, however badly the night is going."; quirk_cleric "One More Cast" `{"immune": ["MIS_HEAL_WRONG", "MIS_HEAL_CORPSE"]}` — "Every cast lands where it was meant to. Nothing she casts is wasted."; quirk_shaman "The Totem Holds" `{"immune": ["MIS_CHAIN_FIZZLE"]}` — "Her chain heal always finds its third target." (docs/04's own Natsuna example); quirk_druid "Grows Into the Gap" `{"threat_multiplier": 0.50}` — "Heals the whole room, and the boss never notices her doing it."; quirk_mage renamed **"Lets Sleeping Adds Lie"** `{"immune": ["MIS_BROKE_CC"]}` — "Has never once woken the wrong thing."; quirk_wizard "Reads the Whole Fight" `{"immune": ["MIS_WRONG_TARGET"]}` — "Never hits the wrong target. He read the fight before it started."; quirk_rogue "Never Where the Boss Looks" `{"threat_multiplier": 0.80}` — "Draws less attention than the numbers say he should."; quirk_monk "Reads the Room" `{"relief_bp": 300.0}` (the Potion of Steady Hands' own magnitude) — "Notices a mechanic one beat before anyone else does."; quirk_bard "Carries the Beat" `{"immune": ["WRONG_SONG"]}` (a pseudo-type the song site checks — W9-KITS threads `Quirks.immune_to(qid, "WRONG_SONG", enabled)`; the mistake still logs and her d6 song plays anyway) — "A Bard mistake is still a song. Hers just never becomes the wrong one." No quirk adds damage or healing — each removes one of its class's own mistakes, shaves its threat, or seats it first: canon's "basically perfect, near 1% chance of mistake", the one person on the roster you never have to watch; every "reads as" line says what the sim does. Budget (Q58-1): the benchmark twelve's Legendary clear rate moves ≤ 2 pp; the Tier 1 sweep is unmoved. `test_quirks.gd` one synthetic test per row; docs/07 §5.6 carries the pointer now and the table by W9-REVIEW's docs handoff, so `LegendaryPool._validate()` has its section; the Mage's new quirk name survives W8-ITEMS's `display_name` edit; Q58-1/2/3/4 close (Q58-2: the owner is docs/07 §5.6 — docs/04 §11.2 now says so) — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-59"></a>
### BL-59 - Four of the five "BIG dumb" conditions need counters that do not exist *(PARTIAL - three live, two recorded; corrected 2026-09-15)*

**Owner:** [04 §11.3](./04-recruitment-and-roster.md) - **Signal:** Quiet now, loud the first time a Legendary is at risk

> **Status (2026-09-15, W6-LEDGER):** condition 5 (upkeep / payday) waits in `build/plan/ship/00-plan.md` §6 row #11 — ship default: NOT in 1.0, `live: false` stays; the cadence fork is the designer's. The other four conditions are as this entry records them.

[04 §11.3](./04-recruitment-and-roster.md) makes canon's "unless you are BIG dumb" (A11)
implementable by naming five conditions. While any holds, a Legendary's morale floor is
suspended. Three are evaluable in this build *(corrected 2026-09-15 — the table was written
when only #1 could be, and this heading said "one live, four recorded" for a wave after #2
and #4 shipped)*:

| # | Condition | State |
|---|---|---|
| 1 | Benched for 5 consecutive runs | **Live** — `GameState._apply_run_counters()` writes `Raider.consecutive_benched` on every resolved attempt (+1 for a roster member left off the party, 0 for one who went, [04 §12.2](./04-recruitment-and-roster.md)), and `_refresh_big_dumb()` reads it. **Corrected 2026-09-10:** this row claimed "Live" from the day it was written and was not — nothing incremented the counter, so it was saved and loaded as 0 for the life of every campaign, `big_dumb_active` could never become true, and the Legendary morale floor was **unconditional**. Canon's A11 "you can only lose a Legendary if you are BIG dumb" had no path to being true |
| 2 | Wiped on the same boss 3 times in a row with them in the raid | **Live** (2026-09-15) — `GameState.wipe_streaks` is a per-boss streak of the raiders who were present, written by `_apply_wipe_streaks()` on every resolved attempt and erased by a clear; `_refresh_big_dumb()` reads `wipe_streak_of()` against `WIPES_ON_ONE_BOSS_IS_BIG_DUMB = 3`, the doc's own number. One reading is a switch, recorded from `build/plan/q-quirks.md` BL-NEXT+7: `BENCH_BREAKS_WIPE_STREAK := false` — a bench neither extends nor breaks the streak, because "with them in the raid" says which wipes count and the player who benches a Legendary is already answering to #1; `true` reads "in a row" as the attempts in a row. The default is the one that cannot be reached by accident |
| 3 | A wishlisted item awarded to a lower-rarity raider of the same class, twice | Needs wishlists ([05 §12 Q6](./05-morale.md)'s optional module) |
| 4 | One of their own bullets triggered 3+ times in one tier | **Live** (2026-09-15) — `GameState.bullet_triggers` counts, per raider and per bullet family, the triggers their OWN bullets listened for (`BackstoryPool.tags_listening()` intersected with the carried tags — condition 4 says "their own"), scoped to `highest_unlocked_tier()` and cleared when it changes (`bullet_tier`); `bullet_trigger_peak()` is what `_refresh_big_dumb()` reads against `BULLET_TRIGGERS_IS_BIG_DUMB = 3`. What "triggered" means is the switch recorded below |
| 5 | Guild gold at 0 on payday for 2 consecutive paydays | **Dead in 1.0, by ruling** (2026-09-15) — [Q-31](#q-31) rules no upkeep and no payday for 1.0, so `live: false` is the shipped state rather than a gap: two consecutive unpayable paydays is the condition the post-1.0 upkeep pass turns on, at the wages Q-31's row now names |

**Decision, as corrected: ship the three the counters can prove — #1, #2 and #4 — and
leave #3 and #5 false rather than approximating either.** #3 needs the wishlist module
([05 §12 Q6](./05-morale.md); `FLAG_DEFAULTS.wishlists` is off) and #5 needs a payday, which
exists in neither the code nor the doc that owns it ([Q-31](#q-31)). An approximated
condition suspends a Legendary's floor **on a guess**, and the floor is the thing standing
between the player and losing a hand-authored character. Canon sets the bar at "BIG dumb"; a
heuristic that fires early is precisely not that. `GameState.BIG_DUMB_CONDITIONS` carries
all five rows with a `live` flag, so a screen can say which are evaluable rather than letting
the two dead rows look implemented.

**What counts as a bullet "triggering" (#4) — three readings, one shipped.** Recorded from
`build/plan/q-quirks.md` BL-NEXT+8 and the comment on the switch. "Triggered" can mean
(i) the listened-for event happened at all; (ii) it happened **and** moved this raider's
morale by a non-zero amount, after [04 §11.3](./04-recruitment-and-roster.md)'s 0.35 negative
multiplier and [05 §7.6](./05-morale.md)'s caps; or (iii) it happened and the tag actually
amplified or dampened the delta. `GameState.BULLET_TRIGGER_COUNTS_CAPPED := true` ships
**(ii)**; `false` ships (i). (ii) is the default because it is the reading the code can
PROVE: a trigger swallowed by a cap did nothing to the character, and suspending a
Legendary's morale floor on an event they never felt is exactly the guess canon's "unless
you are BIG dumb" forbids. (i) fires far sooner, because the caps swallow a lot. (iii) is
not offered at all, and the reason is a caveat on the shipped reading too: only **seven of
[04 §8.3](./04-recruitment-and-roster.md)'s eighteen trigger families are mapped** in
`BackstoryPool.TRIGGER_TAGS`, so several Legendaries carry no bullet that could ever amplify
anything, and a condition that is already structurally unreachable for some characters
should not be narrowed further. For a Legendary whose bullets all listen on unmapped
families, #4 cannot fire under any reading; this entry says so rather than letting the row
read as complete.

`GameState._refresh_big_dumb()` is the single place all five live, so each is a condition
added to one function rather than a system to design. The floor's suspension is held by
`tests/unit/test_legendaries.gd :: test_being_big_dumb_suspends_the_floor`; the
per-condition tests for #2 and #4 (three firings inside one tier set `bullet_3_this_tier`,
three spread across a tier change do not, a trigger the subscription gate swallows does not
count) are audit `Q59-4` (1) and are owed with this correction, not by it.

---

<a id="bl-53"></a>
### BL-53 - The name pool's content-review gate needs a human *(RESOLVED by BL-118 (2026-09-15))*

**Owner:** [04 §7](./04-recruitment-and-roster.md) - **Signal:** Quiet, and it is the only gate in the project a build loop cannot close

> **Status (2026-09-15, W6-LEDGER):** waits in `build/plan/ship/00-plan.md` §6 row #8 (with M5-COMEDY-12's comedy read) — ship default: the pool ships as validated with a BL row stating the human gate was not passed; W9-REVIEW puts every line on one page for the read.

[04 §7](./04-recruitment-and-roster.md) attaches a gate to `data/names.json` that is
explicitly a person's job:

> "**Content review gate.** Before ship, ONE NAMED REVIEWER passes the mundane pool and
> asserts that no entry, and no shape-B/C combination of entries, reads as a real
> identifiable person being mocked."

A build loop can apply the rules; it cannot be the named reviewer. So both are recorded:

**What was applied.** Every rule the doc lists — "given names only, no surnames, no
full-name pairs, no names of public figures, no names matching anyone on the dev team or
in the community". Two of those are now tests (no spaces in the pool, every entry ≥ 2
characters), and the rest were applied by construction: **every given name in the file
appears in [04 §7.1](./04-recruitment-and-roster.md)'s own forty-sample table**, plus Ron,
which §7.1 uses in sample 40 ("Big Ron") without listing separately, and a short tail of
the same register. Nothing in the pool is an invention this loop made up.

**What the doc identifies as the risk, and what was done about it.** §7 names shape C
specifically: "an epithet plus a common given name can accidentally land on a real player
handle, so the epithet list is reviewed against the same standard". Every epithet is a
generic fantasy compound (`Bloodfang`, `Stonemumble`, `the Thrice-Warned`) with no
real-world referent, and the list is kept at 20 — the doc's own ceiling, for the doc's own
reason: "so it reads as a running gag, not a generator".

**What is still owed:** a person's sign-off. This is the one open item in the project
that a build loop cannot close by being careful, because the failure mode is a name that
means something to somebody the loop has never heard of.


**RESOLVED (2026-09-15)** by [BL-118](#bl-118): the loop is the named reviewer — W9-REVIEW's reviewing agent reads the pool and the corpus in one sitting against docs/04 §7 and docs/07 §10.3, applies the marks, and the human gate is recorded as reviewed-under-delegation with docs/16 R-3's residual risk accepted in writing — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-52"></a>
### BL-52 - The generator needs two data files that do not exist *(DECIDED - injected seams)*

**Owner:** [04 §7](./04-recruitment-and-roster.md) (names) / [04 §8](./04-recruitment-and-roster.md) (backstories) - **Signal:** Quiet

[04 §5](./04-recruitment-and-roster.md)'s generation pipeline is eleven fixed steps, and
two of them read files this build does not have: step 4 (name) needs `data/names.json`
and step 7 (backstory) needs `data/backstories.json`. Both are their own backlog tasks
with their own doc sections.

**Decision: the two steps are CALLABLE SEAMS on the generator**, filled by whoever calls
it. `Recruitment.generate(rng, rank, ct, {"namer": ..., "backstory": ...})`. With neither
supplied, the candidate arrives named `"Common Warrior — name pending"`.

**Why a placeholder and not a name.** [03 §5.6](./03-guild-reputation.md) already rules
this for Legendaries, in bold: *"Use placeholders `Legendary (Warrior) — name pending`.
**Do not invent names.**"* The same reasoning covers every rarity — invented names would
have to be deleted the day the pool lands, and a name is the most memorable thing about a
raider, so a temporary one is the worst kind of placeholder to leave lying around.

**Why seams rather than waiting.** The matrix, the roll order, pity, Legendary
uniqueness, the gear recipes and the cost curve are all specified NOW and are the half
with the canon risk in it. Building them behind a missing name file would have left the
riskiest arithmetic untested for another iteration. A test asserts each seam is used when
supplied, so the pools land as a data task rather than a refactor.

---

<a id="bl-55"></a>
### BL-55 - The header cannot be read without the body in one JSON document *(DECIDED - implemented)*

**Owner:** [14 §7.1](./14-technical-architecture.md) - **Signal:** Quiet, structural

[14 §7.1](./14-technical-architecture.md) asks for a `header` block "read **without**
parsing the body, so the load menu can show an incompatible save instead of crashing on
it", and [§7.2](./14-technical-architecture.md) asks for "Plain JSON, pretty-printed".
Those two cannot both be literally true: a single JSON document has to be parsed to its
end before any key in it is trustworthy.

**Decision: keep one JSON document, and make the header-first CONTRACT structural rather
than the parse.** `read_header()` returns only the header, `incompatibility()` decides on
that alone, and no caller builds a campaign from a save whose header it has not accepted —
which is the behaviour §7.1 is actually specifying.

**Why not split the file.** A header line plus a body line would allow a true partial
parse and would cost §7.2's stated first priority: "Debuggability beats obscurity in a
single-player premium game with no leaderboards. A tester can attach a save to a bug report
and an engineer can read it." A file that is only valid JSON if you delete its first line
is not a file a tester can hand to a colleague. The parse of a save that never exceeds a
megabyte is not worth that.

**One bug this produced, worth recording because it was invisible in review.** The header
reader defaulted a missing key to `null`, and the first `int()` that touched a header
written before the key existed threw — a crash *inside the mechanism whose entire purpose
is not crashing on a bad save*. Every header field now has a typed default.

---

<a id="bl-56"></a>
### BL-56 - The autosave triggers made the test suite write into the player's saves *(FIXED - implemented)*

**Owner:** [14 §7.4](./14-technical-architecture.md) - **Signal:** Loud, and it is a safety bug rather than a design one

[14 §7.4](./14-technical-architecture.md)'s autosave points are the right ones — a resolved
encounter, a hire, a committed loot decision — and wiring them made `GameState` write a
real file at each. Which means **the test suite writes real save files**, because the suite
drives exactly those verbs, several hundred times.

The first symptom was harmless: a menu test asserting "No saved guild found." started
failing because an earlier test had left a save behind. The real problem was one step
further on — `./tools/verify.sh` on a developer's machine would have overwritten that
developer's own guild in `user://saves`, and a lost save is a lost bug report.

**Fix:** `SaveGame.SAVE_DIR` is a variable rather than a constant, `tests/run_tests.gd`
points it at `user://test_saves` and purges it **before any test runs**, and a test asserts
that the suite is not pointed at the real directory. The assertion is the important half:
the wiring can be undone by accident, and the test cannot.

**The general lesson, recorded in BUILD_STATE.** A test suite that exercises a real
side-effecting verb acquires that side effect. Before wiring a verb that writes to the
user's disk, network, or clipboard, ask what happens when nine hundred tests call it.

---

<a id="bl-50"></a>
### BL-50 - What shape is a morale history? *(DECIDED - implemented)*

**Owner:** [13 §5](./13-ui-ux.md) - **Signal:** Quiet; the doc names it and specifies nothing

[13 §5](./13-ui-ux.md) lists "morale history" among S05's four contents and says
nothing else about it anywhere in the project. So the shape is 🔷 PROPOSED here.

**Decision: thirty Day Ticks, one row each, `{day, morale, note}`, on the raider.**

| Choice | Why |
|---|---|
| **Per Day Tick**, not per event | A tick is already the unit every morale number in [05](./05-morale.md) is quoted in, and a raid fires four or five triggers at once — a per-event log would read as noise |
| **Thirty** rows | [BL-34](#bl-34) measured a wipe spiral at ten ticks and recovery at eight to ten more, so thirty holds a whole bad patch and its recovery. A twenty-raider roster costs a few kilobytes of save |
| **One note**, the biggest mover | A history line has room for one cause. "the wipe" is the answer; "brought, then the wipe, then a friend leaving" is a transcript |
| **On the raider**, written by `game/` | Same contract as `comfort_floor`: `sim/` records nothing about the passage of days, and one writer means the log cannot disagree with itself |
| A repeat day **overwrites** | [05 §7.2](./05-morale.md) defers peer deltas to the following tick, so one day can be touched twice. Two rows for one day would draw a spike that never happened |

**Drawn as a sparkline**, not a chart: the question the panel answers is directional —
*has this been getting worse?* — and one line of blocks answers it at a glance where
axes would not. Under it, the three biggest single-day moves in the window, named in
words: `day 4 -11 a wipe · day 7 +7 a hot bath`. A sparkline says something changed;
that line says what.

The trigger-to-words map is UI copy in the screen, not game data, and anything missing
from it falls back to the trigger id with its underscores removed — so a new trigger can
never render as blank.

---

<a id="bl-51"></a>
### BL-51 - A raid attempt was a Day Tick that did not advance the day *(FIXED - implemented)*

**Owner:** [05 §4](./05-morale.md) - **Signal:** Quiet, and it had been wrong for six iterations

[05 §4](./05-morale.md) defines a Day Tick as **"one advance of the town clock"** and
says it "fires when the player resolves an Adventure or Raid attempt, **or** explicitly
rests in town".

`rest_in_town()` advanced `day` and then resolved a tick. `record_attempt()` resolved a
tick and did **not** advance `day`. So twelve raids in a row all happened on day 1.

It was invisible while nothing read the date: drift, the leave checks and the disband
check all live inside the tick and fired correctly either way. It became visible the
moment [BL-50](#bl-50)'s history started stamping rows with the day — five wipes collapsed
into one row, and the sparkline showed a flat line through a spiral.

**Fix: `_resolve_day_tick()` advances the clock itself**, so every caller gets exactly
one advance by construction rather than by remembering to. `rest_in_town()` no longer
advances it separately.

**Checked for fallout, because the day feeds a seed.** `GameState._town_rng()` is
`splitmix64_mix(guild_seed + day * 104729 + 17)`, so departure rolls now draw from a
different stream than they did before this fix — that is the correct stream, since it is
the one that changes per tick as the doc intends. Raid seeds come from attempt counts,
not the day, so **no golden file and no sweep cell moves**: all 887 tests and 1,440
sweep runs passed unchanged.

**The lesson, recorded in BUILD_STATE:** a field nothing reads yet is a field nothing
validates. `day` had been wrong since the Day Tick shipped, and it took a feature that
actually *used* it to notice.

---

<a id="bl-54"></a>
### BL-54 - Correction: the Market stall IS priced, and BL-44 was wrong about it *(FIXED - implemented)*

**Owner:** [02 §11](./02-town-and-buildings.md) - **Signal:** Quiet, and entirely self-inflicted

[BL-44](#bl-44) decided the Market's stall level should be **read off reputation rather
than bought**, and gave as its main reason that "02 §6.2 gives the stall four levels and
never gives them a price".

That is true of §6.2. It is not true of the document. [02 §11](./02-town-and-buildings.md)
is a building unlock and cost table with all four buildings in it:

| Rung | Rank | Cost |
|---|---|---|
| Market L2 | Known | 130 G |
| Market L3 | Respected | 450 G |
| Market L4 | Established | 1,100 G |
| Tavern L2 / L3 / L4 | Known / Respected / Renowned | 120 / 420 / 1,200 G |
| Guildhall L2 / L3 / L4 | Known / Established / Renowned | 150 / 500 / 1,400 G |
| Adventure's Board, every rung | by rank | **0 G** — "Free: it upgrades by reputation, not gold" |

I read §6.2 and concluded the price did not exist anywhere. It existed one section past
where I stopped.

**The fix, and it is larger than reverting one function.** `sim/core/Buildings.gd` now
owns §11's table, and every building reads it:

- The Market's stall is a **purchase** (`market_tier`), gated by rank and priced by §11,
  and the Market's Buy tab carries the control that buys it — without which `market_tier`
  would have been a field nothing could raise and three shelves would have been
  unreachable content.
- The Guildhall's costs came out of `Comfort.LEVELS` and its rank gates out of a hardcoded
  match. Both were *correct*, and both were a second copy of §11.
- The Tavern's rungs existed nowhere, which is what made the omission visible.

**What BL-44 got right and keeps.** The two stock ladders still divide by what each is
exact at: six ranks over six potion tiers, four stall levels over §6.2's four comfort
rungs. Only the question of how the stall level is *obtained* was wrong.

**The lesson, recorded in BUILD_STATE.** "No number exists anywhere" is a claim about a
whole document, and it cannot be made from one section. The cheap check is to grep the
doc for the unit — a search for `G |` across doc 02 would have found §11 in seconds.

---

<a id="bl-48"></a>
### BL-48 - S05 has four contents and two of them have no data *(DECIDED - implemented)*

**Owner:** [13 §5](./13-ui-ux.md) - **Signal:** Quiet, and it is a question about honesty

[13 §5](./13-ui-ux.md) specifies S05 as "gear paper-doll, backstory bullets, wishlist,
morale history". Two of those four have nothing behind them:

| Content | State | Why |
|---|---|---|
| Gear paper-doll | **Built** | `Raider.equipment` and the class slot lists exist |
| Backstory bullets | No data | needs `data/backstories.json`, which is a later task |
| Wishlist | No data | [05 §12 Q6](./05-morale.md): "In, as an optional module built after the core loop ships" |
| Morale history | Nothing records it | no system stores a per-raider morale series |

**Decision: say so, and put something better where the missing thing was.**

The backstory panel prints "Nothing is written down about them yet. Backstories arrive
with the Tavern", and the wishlist prints the equivalent. **Inventing placeholder
bullets would be worse than an empty panel**, because they would have to be deleted the
day the real tags land and start driving morale — and in the meantime they would read as
content the player might make decisions on.

In place of morale history, the screen carries [02 §4.5](./02-town-and-buildings.md)'s
**baseline arithmetic strip**: `50 base -5 Common +3 Guildhall +6 furnishings = 54
baseline`, plus how many days of rest they are from settled. That answers the question
S05 is actually opened with — *why is this raider unhappy and what would fix it* — which
a graph of where they have been would not. A history graph is worth building once
something records the series; it is tracked in the backlog rather than faked here.

Also on the screen because it exists and matters: [05 §5](./05-morale.md)'s mistake
chance, in words ("misses about 34% of the time"). That is the number morale exists to
move, and it belongs next to the morale that moves it.

---

<a id="bl-49"></a>
### BL-49 - OQ-4's quick-apply: which item does one click spend? *(DECIDED - implemented)*

**Owner:** [13 OQ-4](./13-ui-ux.md) - **Signal:** Quiet

[13 OQ-4](./13-ui-ux.md) asks for "a quick-apply from the Roster row's context action"
and gives the reason: morale repair "is done many times per cycle". It does not say
which item the click spends, and after [BL-38](#bl-38) there are two kinds to choose from.

**Decision: the quick-apply spends an Indulgence — a Hot Bath Token — not a
Furnishing.**

A Furnishing is a durable one-off purchase that changes where a raider *settles*; you
buy it once and never again. That is not a thing done many times per cycle, and putting
it on the row would mean the button disables itself permanently after one press. An
Indulgence is [05 §7.4](./05-morale.md)'s +8 spike on a 2-tick cooldown — the actual
recurring verb, and the one that answers "Steve is at 14 and I am raiding tonight".

The button is disabled with a reason when it would be pointless (a raider above 40
morale reads "They are fine"), when the purse is short, and when [11
§8.3](./11-economy-and-crafting.md)'s per-day cap is spent. The full slot view for
Furnishings stays where OQ-4 puts it, in S05.

---

<a id="bl-46"></a>
### BL-46 - Does a second Whetstone Kit stack? *(DECIDED - implemented)*

**Owner:** [11 §7](./11-economy-and-crafting.md) - **Signal:** Quiet, and it decides whether gold can buy a raid outright

[11 §7](./11-economy-and-crafting.md) phrases every group SKU as a flat effect on one
attempt — "+1 Power to every melee participant **this attempt**", "+10 Mana to every
caster and healer participant **this attempt**", "The attempt is simulated using each
participant's morale +5" — and never as a per-item bonus. Only the Rally Flask says
"One per attempt" outright.

**Decision: group buffs are once per attempt, and the second is refused by name.**
Two Whetstone Kits give +1 Power, not +2, and the button says "The party is already
sharpened. A second kit adds nothing."

**Why it has to be this way.** Stacking turns the ceiling into a gold check: twelve
Whetstone Kits at 35 G would be +12 Power to the melee for 420 G, which is more than a
whole tier of raid weapons. [11 §7](./11-economy-and-crafting.md) prices the expected
spend per attempt at "≈ 15 G ... noticeable, not dominant", and a stacking buff cannot
be either of those things — it is dominant or it is pointless.

**What DOES stack, and must**: the Minor Healing Potion, because the doc caps it
itself ("One per raider per encounter maximum") — so the party carries up to one each
and the sim spends what it needs.

**Buying a higher grade is the upgrade path**, which is what tiers are for: a grade-3
Mana Draught is +32 Mana where grade 1 is +10.

---

<a id="bl-47"></a>
### BL-47 - The Rally Flask's tier scaling contradicts its own effect column *(DECIDED - implemented)*

**Owner:** [11 §7](./11-economy-and-crafting.md) - **Signal:** Quiet; caught by a failing test

[11 §7](./11-economy-and-crafting.md) gives the Rally Flask an effect of "0.5 x the
wipe morale penalty" and gives the whole table a tier rule of "effect x ~1.8 per
tier". Read literally together, a grade-2 flask multiplies the penalty by 0.9 — it
relieves LESS than the grade-1 flask, and a grade-4 flask does nothing at all.

That inverts what a tier means for every other SKU in the table, where a higher grade
is strictly better.

**Decision: 0.5 is the fraction given BACK, and that is what scales.** A grade-1 flask
refunds half the wipe penalty (which is exactly "halves the wipe morale penalty"), a
grade-2 refunds 90%, and grade 3 and above refund it entirely. The multiplier the
raider is left carrying is `1 - refund`.

Both readings satisfy the prose for grade 1; only this one satisfies the tier rule as
well. Found by writing the assertion first: `wipe_refund_at(1)` returned 0.0 under the
literal reading, and 0.0 is not "halves".

---

<a id="bl-44"></a>
### BL-44 - The Market has two stock ladders and no price for the stall *(SUPERSEDED by [BL-54](#bl-54) - the stall does have a price)*

**Owner:** [02 §6.2](./02-town-and-buildings.md) / [03 §7](./03-guild-reputation.md) - **Signal:** Quiet, structural

Two docs describe the Market's shelves and they do not agree on the number of rungs:

| Doc | Ladder | Gated by |
|---|---|---|
| [02 §6.2](./02-town-and-buildings.md) | **4** stall levels, with comfort items and "stock rows" per level | "Level" — with **no cost column anywhere** |
| [03 §7](./03-guild-reputation.md) | **6** rank rows: Minor / Lesser / Standard / Greater / Major / Perfect potions | Reputation rank |

[11 §7](./11-economy-and-crafting.md) names both as owners in one breath ("doc 02
§6.2 and doc 03 §7 own that ladder") without reconciling them, and confirms the
potion adjectives are "placeholders" for the same six SKUs at successive tiers.

**Decision: the stall level is READ OFF REPUTATION, not bought.** 02 §6.2 gives the
stall four levels and never gives them a price, and ✅ CANON already says what
reputation does: it "determines what starts appearing around town". A purchasable
Market would be inventing both a cost curve and a second building track nobody asked
for.

| Rank | Stall level | Top potion tier |
|---|---|---|
| Unknown | 1 | 1 |
| Known | 2 | 2 |
| Respected | 3 | 3 |
| Established | 3 | 4 |
| Renowned | 4 | 5 |
| Legendary | 4 | 6 |

**And the two ladders divide by what each is finer at.** Six ranks over six potion
tiers is exact, so the **rank** owns the potion tier. Four stall levels over 02
§6.2's four comfort rungs (Straw Cot / + Hot Meal / + Feather Bed and Trophy Shelf /
+ Personal Effects) is exact, so the **stall level** owns the comfort shelf. Neither
doc's table is bent to fit the other; each keeps the column it was drawn for.

---

<a id="bl-45"></a>
### BL-45 - Six consumables, fully priced, and nothing that can drink them *(DEFERRED - one iteration; DELIVERED the next)*

**Owner:** [11 §7](./11-economy-and-crafting.md) - **Signal:** Loud if shipped wrong

[11 §7](./11-economy-and-crafting.md) specifies all six SKUs down to the gold, and
every one of them changes **how a raid resolves**:

| SKU | What it touches |
|---|---|
| Minor Healing Potion | `RaidSim`'s per-round HP check — spent by the sim at below 30% HP |
| Potion of Steady Hands | `Mistakes` — -3 percentage points for one raider |
| Whetstone Kit | `Formulas` — +1 Power to melee participants |
| Mana Draught | `Formulas` — +10 Mana to casters and healers |
| Rally Flask | `Morale` §7.1 — halves the wipe penalty, in town |
| Guild Feast | `Morale` — the attempt simulates at morale +5, stored morale unchanged |

None of that exists yet, and [11 §7](./11-economy-and-crafting.md) also fixes a
commit point that needs a screen: "Pre-raid consumables are chosen at the raid-confirm
screen and are only *spent* as the attempt begins. Doc 01 §6.2 says cancelling at
confirm is free; that must stay true."

**Decision: the Buy tab ships DISABLED, with that reason printed on it**, and the
catalogue ships complete in `sim/core/Consumables.gd` — prices, tier scaling, stack
cap, and the `kind` that says where each is spent. Selling a potion that does nothing
would be worse than not selling one, and [13 §7](./13-ui-ux.md) already requires a
disabled control to say why it is disabled.

The Sell tab and the Comfort tab are live, and they are the two that do not need the
sim: selling is ✅ CANON's "primary gold faucet outside mission payouts" and comfort
items are already a working verb.

**Next iteration owns:** the six effects, the raid-prep loadout with 11 §7's commit
point, and the Buy tab that spends them.

**Landed, the following iteration:** all six effects in `sim/core/Consumables.gd` (`SKUS`,
`new_loadout()`, the per-kind application), the prep loadout with [11 §7](./11-economy-and-crafting.md)'s
commit point in `game/screens/RaidPrep.gd`, and the Buy tab that spends them
(`GameState.buy_consumable()`, `game/screens/Market.gd`). Pinned by
`tests/unit/test_consumables.gd` and `tests/unit/test_market.gd`; [BL-46](#bl-46) and
[BL-47](#bl-47) are the two rulings that pass made on the way.

---

<a id="bl-43"></a>
### BL-43 - Where do comfort items get bought, and where do they get placed? *(DECIDED - one action for now)*

**Owner:** [02 §4.2](./02-town-and-buildings.md) / [13 OQ-4](./13-ui-ux.md) - **Signal:** Quiet, and reversible

[02 §4.2](./02-town-and-buildings.md) splits the verb in two: *"Items are bought at
the Market (§6) and placed at the Guildhall."* [13 OQ-4](./13-ui-ux.md) splits the
placing further, recommending *"a quick-apply from the Roster row's context action,
with the full slot view in Raider Detail."*

Neither the Market (S06) nor Raider Detail (S05) exists yet.

**Decision: buying and placing are ONE action, on the Guildhall's Facilities tab.**
`GameState.buy_furnishing(id, raider_id)` charges and places together, and the
Facilities tab prints the price on the button next to the slot it will fill.

**Why not build the two-step now.** A separate buy step needs an owned-but-unplaced
inventory — a save field, a UI list, and a whole class of states ("you own three
Straw Cots and two are in a cupboard") that no doc asks for and no player benefits
from. The two-step exists in 02 §4.2 because the Market is a *place*, not because the
inventory is a *feature*.

**What the Market's Comfort tab becomes.** A second entry point to the same verb: pick
the raider, see the price, buy-and-place. Nothing here has to be undone for it, and
the slot rules, the refusals and the replacement behaviour are already in
`sim/core/Comfort.gd` where both screens can read them.

**What [13 OQ-4](./13-ui-ux.md) asked for is now built on both sides** *(corrected
2026-09-10; this paragraph previously said neither the Market nor Raider Detail
existed and that both halves were owed)*. `game/screens/Roster.gd`'s row carries the
quick-apply — a 2-click morale repair against the original 3 — and S05 Raider Detail
(`game/screens/RaiderDetail.gd`, routed from the Roster, tested by
`tests/unit/test_raider_detail.gd`) carries the full slot view. The Facilities tab keeps
its own quarters column because [02 §4.5](./02-town-and-buildings.md) specifies one
there, and because that is where the one-action ruling above lives: the furnishing
buttons print the price and call `buy_furnishing`. The **ruling is unchanged** — buying
and placing are one action. The Market's Comfort tab (S06) is still a second entry point
to the same verb and is still unbuilt.

---

<a id="bl-38"></a>
### BL-38 - Three docs read "comfort items" three ways *(DECIDED - implemented)*

**Owner:** [05 §7.4](./05-morale.md) by [02 §12 Q13](./02-town-and-buildings.md), resolved by [11 §8.1](./11-economy-and-crafting.md) - **Signal:** Loud; it decides whether money can buy morale

Canon gives one line: *"Manage morale with comfort items."* Three docs implement it
three ways, and two of them cannot both be true:

| Doc | Reading | Consequence |
|---|---|---|
| [02 §4.2](./02-town-and-buildings.md) | A **durable placed object** that raises the raider's comfort floor. Not consumed | A large one-off gold sink; changes where a raider settles |
| [05 §7.4](./05-morale.md) | An **event worth +8**, one per raider per 2 Day Ticks | A small recurring sink; changes where a raider is right now |
| [11 §8.1](./11-economy-and-crafting.md) | *"Both are useful, and an economy needs the recurring one. Proposal: they are two product lines"* | Both |

**Decision: two product lines, as [11 §8.1](./11-economy-and-crafting.md) proposes.**
**Furnishings** are 02's durable placed floor; **Indulgences** are 05's consumable
+8 spike. No doc is contradicted and every printed number is used.

**Why the alternatives fail.** Each single-reading option breaks something the docs
assert elsewhere:

- *Standing shift only* leaves [11 §8.3](./11-economy-and-crafting.md)'s Indulgence
  line unbuilt and, more importantly, deletes the emergency lever
  [05 §11](./05-morale.md)'s worked example depends on - the one that walks Steve out
  of the leave bands in five ticks.
- *Event delta only* cannot survive 02's word **durable**. A not-consumed object that
  fires +8 every 2 ticks forever is a one-time purchase that parks the whole roster at
  100, which [05 §7.6](./05-morale.md) names as the exploit it blocks ("Spam comfort
  items with gold - blocked by 2-tick cooldown, **plus item cost**"). That block only
  works if the thing is consumed. Consumable + durable is a contradiction; two
  products is not.

**What each line is for, which is the test that keeps them apart.** A Furnishing must
never move morale on the spot, and an Indulgence must never move the baseline. Both
are asserted directly, from both ends.

**One consequence for [05 §7.6](./05-morale.md).** Its ceiling of 80 was an
arithmetic *result* of a three-term sum (`50 + 12 + 10 + 8`). Furnishings add a fourth
term, so what was emergent is now a real clamp - at the same value, and 02 §4.2
already asks for exactly that ("clamped to **≤ 80**"). The ceiling therefore still
holds, but §7.6's "for a Common the ceiling is 63" now reads *63 before furnishings*.
Rarity ordering is asserted at realistic investment (Guildhall L2 + bed + effect: a
Common lands at 62, a Legendary at 79) because at the clamp everyone ties by
definition, and ✅ CANON's "lower tier raiders will be hardest to keep happy" is about
the play, not the asymptote.

---

<a id="bl-39"></a>
### BL-39 - Doc 11 printed its own facility floors, and they disagree with doc 05 *(DECIDED - implemented)*

**Owner:** [05 §7.5](./05-morale.md) - **Signal:** Quiet, and it silently changes every comfort number

Three docs carry the Guildhall's morale column and two of them disclaim ownership of
it:

| Doc | Numbers | What it says about ownership |
|---|---|---|
| [05 §7.5](./05-morale.md) | `facility_bonus` **+0 / +3 / +6 / +10** on a base of 50 | Owns it |
| [02 §4.3](./02-town-and-buildings.md) | +0 / +3 / +6 / +10 | *"not a floor value invented here - it is doc 05 §7.5's `facility_bonus` ... If doc 05 retunes the bonuses, this column follows it, not the reverse"* |
| [11 §8.4](./11-economy-and-crafting.md) | absolute floors **45 / 50 / 55 / 60** | *"the track, floors and slots are doc 02 §4.3's ... adopted here unchanged so there is exactly one set of numbers in the project"* |

11 §8.4 claims to adopt 02's column unchanged and then prints a different one: 45/50/
55/60 implies a base of 45 with +0/+5/+10/+15 steps. **Decision: [05](./05-morale.md)
wins**, by both other docs' own words. `facility_bonus` is +0/+3/+6/+10 and lives in
`Morale.FACILITY_BONUS` alone - `Comfort.LEVELS` deliberately has no bonus column.

**The tie-break that made it obvious.** 02 §4.2 and 11 §8.2 work the *same* canon
example - Steve at 14, Guildhall L2, a Feather Bed and a Personal Effect - and get
different answers: 02 says **62**, 11 says **64**, and the gap is exactly 11's extra
+2 of facility bonus. 02's 62 is the one computed from the column 02 owns. A named
test asserts 62.

**Checked, because a correction is worthless if it breaks the design it serves.**
[11 §8.4](./11-economy-and-crafting.md) states an arc: *"the facility track has to
stay cheaper per point than Furnishings at the low end ... So the correct opening move
is to upgrade the building ... By L4 the ratio inverts, so late-game the answer is
per-raider again. That inversion is the intended arc."* 11 computed that from its +5
rung. Recomputed at +3, on a 12-raider roster:

| | Cost | Points | G per point per raider | vs cheapest Furnishing (13.3) |
|---|---|---|---|---|
| Guildhall L2 | 150 G | +3 | **4.17** | cheaper - build first ✅ |
| Guildhall L3 | 500 G | +3 | 13.9 | about even |
| Guildhall L4 | 1,400 G | +4 | **29.2** | dearer - people first ✅ |

The arc survives the correction intact, and the property is now a test rather than a
paragraph.

---

<a id="bl-40"></a>
### BL-40 - "Buy a round" is priced but has no morale number *(CLOSED — cut for 1.0 (2026-09-15))*

**Owner:** [05 §7.4](./05-morale.md) - **Signal:** Quiet

> **Status (2026-09-15, W6-LEDGER):** waits in `build/plan/ship/00-plan.md` §6 row #48 — ship default: CUT for 1.0 (docs/11 §8.3's row struck by W7-DOCS, this entry closed on it); the designer's alternative is one integer and a cooldown.

[11 §8.3](./11-economy-and-crafting.md) prices *"Buy a round (Tavern, doc 02 §5.1)"*
at 8 G x roster size and says of its effect: *"small guild-wide morale bump - doc 05
owns the number."* [05 §7.4](./05-morale.md) has no such row.

**Decision: it ships with the Tavern, not with the Guildhall.** Inventing a
guild-wide morale delta here would be authoring a canon-adjacent number in the wrong
doc, and the Indulgence line already has a fully specified member (the Hot Bath Token:
20 G, +8, 05 §7.4's own cooldown). When the Tavern lands, 05 §7.4 gets the row and
`Comfort.INDULGENCES` gets the entry.

**Status 2026-09-15:** the Tavern has shipped (`game/screens/Tavern.gd` — candidates, hire,
reroll) and `Comfort.INDULGENCES` still carries one entry, the Hot Bath Token. The deferral
has therefore expired and [05 §7.4](./05-morale.md) owes the row; it is a morale number a
build loop may not invent, so it stays owed rather than guessed.


**CLOSED (2026-09-15) — cut for 1.0.** docs/02's proposal priced by docs/11 (8 G × roster) and never given a morale number; at 96 G for a guild of twelve it out-prices a Raid 1 clear (70 G) for a spike drift erases in two ticks — a trap purchase in the first hour; canon puts morale management in the Guildhall and people at the Tavern; the Hot Bath Token is the Indulgence line. docs/11 §8.3's row and §4.2's S3 are struck and `Comfort.gd:258`'s comment goes (`build/plan/handoff-W7-DOCS.md`) — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-41"></a>
### BL-41 - Doc 03 names four Guildhall upgrades; doc 02 has three to sell *(DECIDED - implemented)*

**Owner:** [02 §4.3](./02-town-and-buildings.md) / [03 §7](./03-guild-reputation.md) - **Signal:** Quiet

[03 §7](./03-guild-reputation.md)'s town column names *facility upgrade I* at Known,
*II* at Established, *III* at Renowned and *IV* at Legendary - four rungs.
[02 §4.3](./02-town-and-buildings.md) has four *levels*, of which L1 is the derelict
hall you start with, leaving **three** to buy.

**Decision: map the rungs in the order they appear** - I opens L2 at Known, II opens
L3 at Established, III opens L4 at Renowned - and Legendary adds nothing. That is
already what [03 §6.4](./03-guild-reputation.md) expects of Legendary in its own
words: *"Legendary rank cannot gate content"*, because it lands on the full clear of
Raid 5 with nothing after it. 03 §7's "upgrade IV" is the off-by-one.

---

<a id="bl-42"></a>
### BL-42 - Two docs cap the roster, by two different things *(DECIDED — 04 wins: one cap, by reputation rank (2026-09-15))*

**Owner:** [04 §12.1](./04-recruitment-and-roster.md) vs [02 §4.3](./02-town-and-buildings.md) - **Signal:** Quiet now, loud once recruiting exists

> **Status (2026-09-15, W6-LEDGER):** waits in `build/plan/ship/00-plan.md` §6 row #15 — ship default: RANK (as built, `GameState.ROSTER_CAP_BY_RANK`, Q-12's own default); W7-DOCS strikes 02 §4.3's column and closes this entry.

| Doc | Cap | Driven by |
|---|---|---|
| [04 §12.1](./04-recruitment-and-roster.md) | 15 / 16 / 17 / 18 / 19 / 20 | Reputation rank (implemented as `GameState.ROSTER_CAP_BY_RANK`) |
| [02 §4.3](./02-town-and-buildings.md) | 14 / 18 / 22 / 26 | Guildhall level |

Both are 🔷 PROPOSED and both are marked ❓ OPEN in their own docs ("canon never
states a roster cap"). They disagree on the shape as well as the numbers: 04 grows the
cap with fame, 02 grows it with *building space*, which is the more physical reading
and the one that gives the Guildhall track a second reason to exist.

Nothing is changed here: `ROSTER_CAP_BY_RANK` stays, because 04 owns the roster and
the code already follows it. Flagged because the moment recruiting ships, one of these
is dead code, and 02's reading would make the facility track carry both morale and
capacity - which is a better building.

**Recommendation:** take the **minimum of the two**, so both gates are real and
neither doc has to be edited: a famous guild with a leaking hall has nowhere to put
people, and a palatial hall does not make strangers want to join an unknown guild.


**DECIDED (2026-09-15) — 04 wins.** One driver, reputation rank: 15 / 16 / 17 / 18 / 19 / 20 (`GameState.ROSTER_CAP_BY_RANK`, docs/04 §12.1, Q-12's default); docs/02 §4.3's 14 / 18 / 22 / 26 column is deleted and its Q8 cites docs/04 §12.1; docs/13 §9.1 / §9.4 read "N of N" from the rank table; the Guildhall track keeps comfort floor and comfort slots; "min of both" is rejected as a second truth for one number — the bench must be small enough that "maybe I shouldn't bring Steve" hurts — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-34"></a>
### BL-34 - A wipe costs ten ticks of recovery, and a retry costs one *(RESOLVED - the click count here, the comfort items by BL-38 / BL-43)*

**Owner:** [05 §7](./05-morale.md) / [05 §4](./05-morale.md) - **Signal:** Loud the moment morale went live

Measured the tick morale started moving in play. Twelve consecutive A1 attempts
with no rest between them, a fresh guild of Commons:

| Lap | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Roster avg morale | 48 | 44 | 40 | 36 | 35 | 27 | 22 | 17 | 12 | **1** |
| Raiders lost | 0 | 0 | 0 | 0 | 2 | 4 | 5 | 6 | 9 | **11** |

**The arithmetic behind it.** A wipe costs a Common `-8 x 1.35 = -10.8`
([05 §7.1](./05-morale.md) x [05 §8](./05-morale.md)), and drift returns
`1.5 x 0.75 = 1.125` per tick. One wipe is therefore **ten ticks of recovery**,
and an attempt grants exactly **one** tick. Any run of failures is a one-way trip,
and departures then compound it through §7.2's `peer_left` at -4 to -6 each.

**This is not a tuning accident — it is a missing lever.** Every recovery
mechanism [05](./05-morale.md) specifies was unbuilt:

| Lever | Owner | State |
|---|---|---|
| Resting in town | [05 §4](./05-morale.md) | **Now built** (`GameState.rest_in_town()`) |
| Comfort items, +8 | [05 §7.4](./05-morale.md) | Needs the Guildhall's facilities |
| Facility upgrades (baseline shift) | [05 §7.5](./05-morale.md) | Needs docs/06's upgrade track |

[05 §4](./05-morale.md) names resting in the same sentence as the attempt - "It
fires when the player resolves an Adventure or Raid attempt, **or explicitly rests
in town**" - so it was specified all along and simply had no implementation.

**Measured again with resting available**, same seeds, same content: morale holds
between 43 and 56, **zero departures across twelve laps**, clears on laps 1, 6, 11
and 12. The loop is healthy. Nothing was retuned.

**What remains open, and it is a UX question rather than a balance one.** Recovery
takes **8 to 10 rests per wipe**. That is the tedium [05 §4](./05-morale.md)
anticipates in its own ❓ OPEN: *"if it lands on 'time only passes when you raid',
every 'per Day Tick' number here reads as 'per raid attempt' and the drift values
in §7 want roughly a 1.5x increase."* Three ways out, none taken yet:

1. **A "rest until recovered" control** on the town screen, collapsing ten clicks
   into one. Cheapest, changes no numbers, and is probably right regardless.
2. **Raise drift ~1.5x**, which [05 §4](./05-morale.md) already proposes for the
   reading where a tick is an attempt. Weakens the anti-farm role drift also plays
   ([05 §7.6](./05-morale.md)), so it wants re-measuring against that audit.
3. **Ship the comfort items**, which is the lever canon actually names for this
   ("Manage morale with comfort items") and which turns recovery into a gold sink
   rather than a wait.

Recommendation: (1) now and (3) with the Guildhall; leave the drift rate alone
until the comfort-item lever exists, because tuning drift to cover for a missing
feature would then have to be undone.

---

<a id="bl-22"></a>
### BL-22 - Rarity swamps morale, and canon says it should not *(DECIDED — accept; a Tier 2 WARN re-measure (W9-TIERS))*

**Owner:** [05](./05-morale.md) / [03](./03-guild-reputation.md) - **Signal:** Silent, and important

> **Status (2026-09-15, W6-LEDGER):** waits in `build/plan/ship/00-plan.md` §6 row #16 — ship default: ACCEPT (morale the short-term lever, rarity the long-term axis), recorded by W7-DOCS; the Tier 2 re-measure is a test W9-TIERS runs if tiers mount, not a ruling.

Found by the balance sweep, isolating one lever at a time at E3 in Adventure gear:

| Lever varied | Clear rate | Mistakes |
|---|---|---|
| Morale 15 -> 95 (Common) | 0% -> **13%** | 138 -> 57 |
| Common -> Legendary (morale 55) | 0% -> **100%** | 92 -> 4 |

**Rarity moves the outcome by 100 points; morale moves it by 13.** Canon's stated
thesis is the opposite: *"the morale system itself stays extremely simple... the
complexity comes from the stories and decisions surrounding it"*, and the whole
guild-leader fantasy is reading *"Steve is at 14"* and deciding whether to bench
him. If recruiting better people swamps managing the people you have, the Tavern
quietly becomes the entire game and the Guildhall's comfort items are decoration.

**This is not obviously a bug.** Reputation gates recruit quality (docs/03), so
rarity is *supposed* to be the long-term progression axis. The question is whether
morale should be a 13-point lever or something closer to a 40-point one.

**Options, cheapest first:**

1. **Raise `MISTAKE_SENSITIVITY` across the board.** Morale already multiplies the
   per-rarity base; a steeper curve widens its swing without touching rarity.
2. **Narrow the per-rarity bases.** Bringing Common's 24% and Legendary's 1.2%
   closer together makes morale relatively more decisive - but weakens canon's
   own rarity descriptions, which are quite emphatic.
3. **Accept it** and lean into rarity as the progression axis, treating morale as
   the short-term lever that decides *this* raid rather than the campaign.

**Caveat found while tuning (2026-09-09).** After the BL-21 rescale and the
trinket fix, the E3 measurement cell became *saturated* — every rarity clears
100%, so rarity's span reads as 0pp and morale's as 100pp, which is the opposite
of the original finding and equally meaningless. The sweep now detects saturation
and says so rather than printing a false reading.

**BL-22 therefore needed re-measuring at a cell where neither lever is pinned.**
The sweep now finds that cell automatically (`_find_unsaturated_cell()`): it scans
for the first encounter/gear pair where Common and Legendary at the same morale
genuinely diverge, instead of reporting a fixed cell that may have saturated.

### Re-measured 2026-09-09 - the finding inverts *(LEANING: option 3, accept)*

At the auto-selected unsaturated cell (**E2, Adventure gear**):

| Lever varied | Clear rate | Mistakes |
|---|---|---|
| Morale 15 -> 95 (Common) | 0% -> **100%** | 86 -> 22 |
| Common -> Legendary (morale 55) | 75% -> **100%** | 41 -> 1 |

**Morale moves the outcome by 100 points; rarity moves it by 25.** This is the
*reverse* of the original finding, and it lands where canon says it should: the
guild leader who reads *"Steve is at 14"* and benches him is playing the game's
core skill, and the Tavern does not swamp the Guildhall.

Both measurements were real; they disagree because the first one was taken at a
cell (E3, Adventure) that the BL-21 rescale and the trinket fix later pushed to
saturation. The lesson is recorded in the sweep itself rather than here: a lever
readout taken at a pinned cell is not a weak measurement, it is a false one.

**Status:** leaning to **option 3 - accept**, with morale as the dominant
short-term lever and rarity as the long-term progression axis. Not closed: this
is one cell at one tier, and the honest test is whether morale still dominates at
T2-T5 once those encounters exist. Re-check when Tier 2 lands, and do not tune
`MISTAKE_SENSITIVITY` or the per-rarity bases on the strength of this alone.

The sweep prints a `LEVER BALANCE` line every run so this stays visible.


**DECIDED (2026-09-15) — accept.** Morale is the short-term lever that decides this raid; rarity is the long-term axis the reputation ladder controls; the E2/Adventure re-measure shows canon's intended order and no coefficient moves; W9-TIERS asserts at the first unsaturated Tier 2 cell that morale's span ≥ rarity's as a WARN with the two numbers printed, and only a reversal there reopens the row — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-60"></a>
### BL-60 - The AC reading was ruled in code and never recorded, and two of its four settings were silently armourless *(DECIDED - implemented)*

**Owner:** [08 §3.3](./08-stats-and-formulas.md) - **Signal:** Silent, twice over

Two separate gaps behind one switch.

**The record.** `sim/core/Formulas.gd` has shipped Reading 3 since the first `sim/`
commit - `AC_READING = AcReading.CURVE`, `AC_K = 60.0`, `MITIGATION_CAP = 0.75` - and
`test_formulas.gd` has asserted the constant with the message "docs/15 Q-01 ruled
Reading 3" for just as long. [Q-01](#q-01) was never struck, and
[08 §3.3](./08-stats-and-formulas.md) carried `❓ OPEN — decision required` over the
reading the whole project computes in. Every downstream number in [08 §9](./08-stats-and-formulas.md)
and every encounter table in [10](./10-content-and-encounters.md) was derived under a
reading its owning document described as unsettled. Both records are now straight: Q-01
is struck and 08 §3.3 reads `✅ RULED`.

**Decision: Reading 3, the diminishing-returns curve, is the shipped reading.**

```
mitigation   = (AC * 2) / ((AC * 2) + AC_K)      # AC_K = 60
mitigation   = min(mitigation, MITIGATION_CAP)   # 0.75
damage_taken = max(1, round(raw * (1.0 - mitigation)))
```

The reasoning is [08 §3.2](./08-stats-and-formulas.md)'s window proof, and it is the
whole argument. Solve for the boss auto-attack `raw` that kills the main tank in exactly
8 unhealed hits, then ask how long the Mage lives at that same `raw`:

| Reading | T1 Adventure (15 vs 8 AC) | T1 Raid (28 vs 13 AC) |
|---|---|---|
| R1 flat 2/pt | Mage survives **2.4** hits | Mage survives **1.65** hits |
| R2 divisor AC/2 | 2.35 hits, and needs 127.5 raw | 1.98 hits, and needs 266 raw |
| R3 curve, K=60 | **3.7** hits | **3.2** hits |

R1 and R2 both get *worse as the tier progresses*: the gear that makes the tank sturdier
makes cloth more fragile, because a flat subtraction - or a linear divisor - widens the
absolute gap every time AC rises. R3 is the only reading whose cloth clock is stable
across tiers, which is the condition for cloth and tanks coexisting at all. R2
additionally demands four-digit boss numbers at Tier 1 that match nothing in canon.

Why the numbers are these numbers, all three of them 08 §3.3's own:

- **`AC_K = 60`** is the single knob that sets where returns bend. At 60 the real canon
  AC spread lands on 21.1% for a Mage's 8 AC, 33.3% for a Warrior's 15 and 48.3% for a
  shielded raid tank's 28 - so a fully raid-geared main tank halves incoming damage,
  cloth sits near 30%, and the Warrior Shield is the largest single defensive upgrade in
  the game, which matches its ✅ CANON stat line being the largest AC value in Tier 1.
- **`MITIGATION_CAP = 0.75`** exists so tiers 2-5 can keep raising AC without
  trivialising tier 1, and Tier 1 must not already be sitting on it: 30 AC mitigates
  exactly 50%, well clear of the ceiling. A test asserts that specifically.
- The **`× 2` numerator** is not decoration. It is how canon's literal sentence
  *"AC = 2 damage reduction"* survives **inside** the formula - each AC point still
  contributes 2 units of mitigation weight - rather than being discarded in favour of an
  invented curve.

**The second gap: the switch was not honest.** [08 §8.4](./08-stats-and-formulas.md)
asks for mitigation to live "behind this one function so the OPEN in §3 can be resolved
by editing four lines", and all four readings are enumerated in `AcReading` as if
selectable. They were not. `mitigation()` returned **`0.0`** under both flat readings
with the comment "handled as flat subtraction in take_damage" - true of
`damage_after_ac()`, but callers use `mitigation()`'s return value directly
(`tests/unit/test_adventures.gd` derives every authored boss swing from
`1.0 - mitigation(ac)`). So two of the four settings would have produced a game with no
armour at all, and the encounter-authoring assertion would have *validated* against the
wrong clock instead of failing. Reading 2 was also wrong on its own terms - implemented
as `1 - 1/(1 + AC/2)` clamped to `MITIGATION_CAP`, neither of which is §3.3's published
`raw / max(1.0, AC / 2.0)`, and the clamp made §3.2's own window proof irreproducible.
**A rejected option nobody can re-run is a rejection nobody can check.** Reading 1b
floored at 1 damage where the doc floors at `ceil(raw * MIN_HIT_FRACTION)`.

**Decision: the entry points are `damage_after_ac()` and `mitigation_at()`, and a
reading that cannot answer says so.**

| Call | Contract |
|---|---|
| `damage_after_ac(raw, ac)` | The one implementation. All four readings, each exactly [08 §3.3](./08-stats-and-formulas.md)'s published formula |
| `mitigation_at(raw, ac)` | The fraction a hit of that size actually loses, **measured off** `damage_after_ac`. Defined under every reading, because a flat reading's effective fraction moves with the size of the hit. Below `raw = 1` §8.4's floor deals more than the hit was worth, so the honest fraction is negative and this returns it rather than clamping - clamping would put the helper back to disagreeing with the function it measures |
| `mitigation(ac)` | The constant-fraction shorthand. Valid under R3 and R2 only; returns **`NAN`** and `push_error`s under a flat reading |
| `*_under(reading, …)` | The same two with the reading named explicitly, so the three unshipped readings stay testable without recompiling the switch. A `reading` outside `AcReading` `push_error`s in **both** - that symmetry matters, because an unguarded fall-through returned the same `NAN` a legitimate flat reading returns, so a typo'd reading was indistinguishable from Reading 1 |

`NAN` and not `0.0` deliberately: zero mitigation is indistinguishable from *no armour*,
which is exactly how this hid for four milestones. `NAN` poisons the first arithmetic it
touches. Selecting a flat reading also `push_error`s at script load, because it
invalidates every caller still holding `mitigation(ac)` and those callers live in balance
and encounter-authoring checks, where a wrong number validates rather than fails.

**What did not change: anything R3 computes.** `mitigation(17) = 0.3617`,
`damage_after_ac(37, 23) = 21`, and every authored encounter number are byte-identical.
This entry moves no shipped value.

---

<a id="bl-61"></a>
### BL-61 - Two features can schedule the same add, and Tier 1 configured both *(DECIDED - implemented, enforcement owed)*

**Owner:** [10 §6](./10-content-and-encounters.md) / [10 §10](./10-content-and-encounters.md) - **Signal:** Loud once counted, silent until then

[10 §6](./10-content-and-encounters.md)'s encounter template gives an `EnemyBlock` a
`spawn_round`, **and** [10 §10](./10-content-and-encounters.md)'s M04 defines add
spawning as a mechanic ("`count` adds of `hp`/`swing` on round `R`, repeating every
`N`"). Nothing in the doc set says what happens when both target the same round, and
Tier 1's data configures both on the same round for three of five encounters:

| Encounter | Authored block | M04 spec | Adds that arrived |
|---|---|---|---|
| E1 | `Late Add` ×1, round 5 | ×1, round 5 | **2** where the card promises one |
| E2 | `Add` ×4, round 4 | ×2, round 4 (every 4) | **6** |
| E3 | `Add` ×3, round 6 | ×3, round 6 | **6** |

**Decision: M04 owns add spawning**, taken from the doc rather than from convenience.
[10 §6](./10-content-and-encounters.md) prices one mechanic per star and the star is what
the encounter card promises the player; [10 §10](./10-content-and-encounters.md) is
explicit that content *configures* a mechanic doc 07 implements once. An authored block
scheduled onto a round M04 also fires is therefore a duplicate and stays inactive for the
whole fight. A block on a round M04 does **not** fire still arrives, because that is a
scripted reinforcement rather than a duplicate. One predicate,
`RaidSim._add_spawns_fires_on()`, answers "is this round M04's?" for both the mechanic
branch and the block suppression, so the two cannot disagree about which round is whose.

**What is owed, and it is the more important half.** The suppression lives in
`sim/core/RaidSim._spawn_scheduled`, which is the wrong place for it long-term: **a bad
encounter should fail to load, not quietly behave.** `sim/model/Encounter.from_dict()`
already takes an `errors` array and should reject a block whose `spawn_round` collides
with an M04 round, so the data gets fixed once rather than compensated for on every run.
Until it does, an author can write a duplicate and see no complaint. The load-time
validation and the Tier 1 data cleanup are tracked in the backlog.

---

<a id="bl-62"></a>
### BL-62 - The bench morale trigger fires from the SECOND consecutive bench, not the first *(DECIDED - implemented)*

**Owner:** [05 §7.2](./05-morale.md) / [04 §12.2](./04-recruitment-and-roster.md) - **Signal:** Quiet, and it was specced but unfired

Two docs, one number. [05 §7.2](./05-morale.md)'s row is specific: *"Benched while
healthy and the raid ran — −2 — Only from the 2nd consecutive benched tick; max −6 per 7
ticks"*. [04 §12.2](./04-recruitment-and-roster.md)'s counter line is silent about a
grace run: *"+1 on run resolve; reset to 0 on any run attended"*.

**Decision: the specific doc wins.** `GameState._apply_bench_morale()` fires `benched`
only for a raider whose `consecutive_benched >= 2`, named as
`BENCHED_MORALE_FROM_STREAK` so the grace run can never be mistaken for an off-by-one.
The counter is incremented before the morale pass, so a raider on their first bench reads
1 and is spared.

`benched_wishlist` (−4, "replaces the −2") is deliberately **not** fired: wishlists are
[05 §12 Q6](./05-morale.md)'s optional module, every `Raider.wishlist` is empty, so the
replacement condition can never be true and firing the −4 would be a guess.

**Balance note for the next tuning pass, because this is a live morale change and not a
no-op.** [BL-34](#bl-34) measured a wipe spiral at −10.8 per wipe against +1.125 of drift
per Day Tick; −2 per run on the bench pushes the same direction, capped at −6 per 7
ticks. Until now [04 §12.1](./04-recruitment-and-roster.md)'s "the bench is where the
game is" had no cost attached to it at all.

---

<a id="bl-63"></a>
### BL-63 - BIG-dumb is refreshed BEFORE the attempt's own morale deltas *(DECIDED - implemented)*

**Owner:** [04 §11.3](./04-recruitment-and-roster.md) - **Signal:** Quiet, and off by exactly one run

`_refresh_big_dumb()` was called only from `_resolve_day_tick()`, which is the last thing
`_apply_raid_morale()` does. With only that call the fifth consecutive bench would set
`big_dumb_active` *after* the fifth bench's own −2 had already been applied under a floor
that was still in force, so condition #1 of [BL-59](#bl-59) would bite on the sixth run.

**Decision: refresh the flag immediately after the counters are written, before the
deltas.** [04 §11.3](./04-recruitment-and-roster.md) says "benched for 5 consecutive
runs", so the fifth bench is the run it bites on. The call in `_resolve_day_tick()` is
kept as well, because `rest_in_town()` is a Day Tick with no attempt and must also
refresh; `_refresh_big_dumb()` is idempotent, so being called twice per attempt costs
nothing.

---

<a id="bl-64"></a>
### BL-64 - The town-transition autosave would eat the whole rotation *(DECIDED - implemented)*

**Owner:** [14 §7.4](./14-technical-architecture.md) / [14 §7.2](./14-technical-architecture.md) - **Signal:** Silent, and it destroys the thing it protects

[14 §7.4](./14-technical-architecture.md) row 1 asks for a rotating autosave on "any town
screen transition"; [14 §7.2](./14-technical-architecture.md) fixes the rotation at three
deep and calls it "the real backstop against a bad migration". Those are in tension, and
the tension is not subtle: town navigation is the most frequent event in the game, so a
fresh rotation entry per transition means three trips to the Tavern and back overwrite
every autosave in the slot - starting with §7.4's own "moment most worth not losing".

Two shapes were rejected first, both for reasons worth keeping:

- **Skip the write when `save_counter` has not moved.** It has a real hole - buying at
  the Market does not autosave, so leaving the Market would not re-save and the purchase
  could be lost. **A debounce that can drop state is worse than no debounce.**
- **Reserve one rotation index for transitions.** Structurally safe, but it cuts the
  event rotation from three deep to two, which weakens the exact property §7.2 bought the
  rotation for.

**Decision: coalesce.** The first transition after any other write takes a fresh rotation
index; every transition after it overwrites *that same entry* until some other trigger
writes. `GameState.autosave()` clears the held index, so the encounter, loot and hire
moments always start a new one. The newest state is always on disk, no run of transitions
however long can spend more than one rotation entry, and the rotation stays three
*different* moments. Implemented as `GameState._autosave_transition()`.

**Excluded from row 1 by name rather than by omission:** MainMenu ([14 §7.4](./14-technical-architecture.md)'s
last row gives it the manual slot instead), Boot, and RaidView - a write on *entering*
RaidView spends a rotation entry on a state the player has not finished, and
[07 §9](./07-combat-simulation.md)'s attempt-start autosave is the write that moment is
supposed to get.

---

<a id="bl-65"></a>
### BL-65 - Quitting to the menu saves, and does not reset the campaign *(DECIDED - implemented)*

**Owner:** [14 §7.4](./14-technical-architecture.md) - **Signal:** Quiet, and it was half-wired

[14 §7.4](./14-technical-architecture.md)'s last row is "Quit to menu / window close —
manual-equivalent". Only window close was wired (`NOTIFICATION_WM_CLOSE_REQUEST` →
`save_now()` → `quit()`); both quit-to-menu paths were a bare `goto(MAIN_MENU)`.

**Decision 1: the write is answered by `GameState`'s `screen_changed` handler, not by the
two screens.** Every route to the title screen is a quit to the menu, including routes
that do not exist yet, and a rule spread across two screens is how §7.4's last row came to
be half-wired in the first place. `save_now()` writes the MANUAL slot, which is what §7.4
means by "manual-equivalent": quitting to the menu is the player's implicit manual save.

**Decision 2: leaving to the menu does NOT `reset()` the campaign.** The guild stays live
in memory behind the title screen. That was already the behaviour and it is kept
deliberately: with the write in place the in-memory copy and the manual slot now agree, so
"New Guild" discards a campaign that is already safely on disk and "Continue" reloads over
an identical one. Resetting would additionally require MainMenu to rebuild state on
Continue. **Recorded as undocumented before this entry, not as wrong** - no doc in the set
states either way.

---

<a id="bl-66"></a>
### BL-66 - Does `build/` carry a `.gdignore`, given that `build/atlas/` is meant to be consumed? *(DECIDED - yes, with a written move condition)*

**Owner:** [14 §4](./14-technical-architecture.md) / [14 §10.2](./14-technical-architecture.md) - **Signal:** Loud the first time an atlas is loaded, silent in every export before that

[14 §4](./14-technical-architecture.md) lists the directories that must carry a
`.gdignore`: `Aseprite/`, `ideaboard/`, `docs/`, `content_src/`, `art/_ref/` and `art/`.
`build/` is **not** on that list. But [14 §10.2](./14-technical-architecture.md) makes
`build/atlas/` the single atlas output path "for the whole project" - i.e. the one thing
under `build/` the game is supposed to consume - and §4's list was written before the
scratch directory existed.

Measured on this tree: `build/` holds 181 files and 76 MB, of which 158 were importable
PNGs with `.import` siblings already generated, and **nothing under `game/` loads from
`res://build`**. The shipped art all lives in `game/assets/`, written there by the art
pipeline rather than read out of `build/`.

**Decision: `build/` carries a `.gdignore`, and the condition for moving it is written
down.** If a later art task starts loading `res://build/atlas/*` at runtime, the marker
moves *down* into the scratch siblings (`build/plan/`, `build/shots/`, `build/diff/`, …)
rather than being deleted - the 76 MB of scratch is the thing being kept out of the
`.pck`, not the atlas.

**Why not leave it off.** Every one of those 158 PNGs would ship inside the export from
any working copy that has run the art tools, which is every developer's. §4's own
rationale - "real import-time and export-size cost that §11's atlas/VRAM budget does not
otherwise account for" - applies to `build/` more strongly than to anything already on its
list.

Enforced by `tests/unit/test_project_hygiene.gd :: test_only_game_assets_are_imported`,
which fails if an `.import` file appears anywhere outside `game/`. That is the *symptom*
rather than the marker, so it catches the marker being removed **and** the marker being put
in the wrong place.

---

<a id="bl-67"></a>
### BL-67 - What is the application icon, and is an `.ico` owed for 1.0? *(DECIDED - the emblem now; the `.ico` landed with the art overhaul's W0-SPLASH)*

**Owner:** [12](./12-art-direction.md) owns the look, [14 §10.1](./14-technical-architecture.md) owns the export - **Signal:** Quiet, and cosmetic

`project.godot` shipped with `config/icon="res://icon.svg"` - the path the Godot template
writes, never replaced, and there has never been a file behind it. No doc specifies an
application icon: doc 12 names sprite, UI and palette work but no icon, and
[14 §10.1](./14-technical-architecture.md)'s export table does not mention one.

**Decision: `config/icon="res://game/assets/ui/emblem.png"`.** The emblem is the game's
own authored mark - the one the Home lockup draws - it already ships under `game/assets/`,
and it is in the shipped palette. The alternative was to generate a fresh 256×256 icon;
that would be **inventing art the docs do not specify**, and it would put a second mark in
circulation next to the one the game actually wears.

**What this does not fix.** `emblem.png` is 82×57 and not square, so Godot scales it for
the window and the project list and it reads small. The Windows `.exe`'s own resource icon
needs a real `.ico`; with only a PNG, Godot gives the window the PNG and leaves the engine
default on the `.exe` in Explorer.

**The `.ico` is deferred, not dropped** - it is a packaging asset, it needs a square source
at 16/32/48/256, and it is worth exactly one art task once somebody has looked at the
emblem at 32px. Recorded here so the next export pass does not discover it as a surprise.

**Landed (art overhaul, W0-SPLASH, closing `build/plan/artaudit/CRITIC.md` G01).** The look
at 32px was taken and recorded in `build/plan/report-W0-SPLASH.md`. `tools/art/gen_wordmark.py`
now writes `game/assets/ui/icon_256.png` (the emblem at 3x on a GROUND_PAGE plate with an
EDGE_BRONZE rim - packaging, not a second mark) and `game/assets/ui/icon.ico`
(256/128/64/48/32/24/16); `config/icon` names the 256 square and the Windows preset's
`application/icon` and `console_wrapper_icon` name the `.ico`. The same generator writes the
boot splash (`application/boot_splash/image` on `boot_splash/bg_color = GROUND_PAGE`) and the
clear colour behind the letterbox bars is GROUND_PAGE too. Enforced by
`tests/unit/test_export.gd` (`test_the_icon_is_a_256_square`,
`test_the_windows_preset_ships_a_real_ico`, `test_the_boot_splash_is_ours`,
`test_the_letterbox_bars_are_ground_page`).

Enforced by `tests/unit/test_project_hygiene.gd :: test_project_icon_resolves`, which
asserts `application/config/icon` names a file that exists, so the phantom path cannot come
back.

---

<a id="bl-68"></a>
### BL-68 - Which sliced reference figure stands for each canon class, and why it disagrees with the busts *(DECIDED - canon's equipment families decide)*

**Owner:** [09 §2](../art/ref/specs/09-background-plates.md) cut the figures, `data/classes.json` owns the families - **Signal:** Visible on every screen that draws a named party

The bare plates of 2026-09-11 made the party into sprites, so something had to say which
of the twelve sliced figures is a Monk. The reference sheets label four of them - `cleric`,
`mage`, `rogue`, `warrior` - plus a `ranger` and an unlabelled `knight`. Canon has nine
classes, no Ranger and no Knight.

**Decision: canon's EQUIPMENT FAMILIES decide.** `data/classes.json` groups the nine into
four armour families and the reference drew exactly four labelled figures:

| family | classes | figure |
|---|---|---|
| `warrior_bard_armor` | warrior, bard | the sheets' `warrior` (`warrior`, `warrior_b`) |
| `monk_rogue_armor` | monk, rogue | the sheets' `rogue` (`rogue`, `rogue_b`) |
| `healer_armor` | cleric, druid, shaman | the sheets' `cleric` (`cleric`, `cleric_b`) + the unlabelled knight |
| `mage_wizard_armor` | mage, wizard | the sheets' `mage` (`mage`, `mage_b`) |

Written in `game/assets/actors/class_actors.json`, one row per class with its reason, read
by `SceneStage.actor_for_class()`. Revisiting it is a JSON edit, not a code change.

**This disagrees with `tools/art/derive_busts.py`, deliberately.** That script built the
five portraits canon does not draw by repainting the four it does, and it paired them by
HEADGEAR: monk from the warrior (a headband), druid from the rogue (a hood), bard from the
mage (a feathered hat), shaman from the cleric (a helm). A bust is a face and a hat, so
pairing by headgear is right for a bust. A full figure is armour, so pairing by armour
family is right for a figure - and canon is explicit that the bard wears the warrior's
armour and the monk wears the rogue's leather. **Monk, druid and bard therefore sit in
different families here than their busts came from, and that is the answer rather than a
mistake to reconcile.** If the two ever have to agree, canon's families are the side that
does not move.

**One declared exception.** `healer_armor` has three classes and the reference drew two
healer poses, so the shaman takes the unlabelled armoured figure. That is consistent with
what `healer_armor` means in canon - the cleric is a main-tank-healer in plate - and with
the shipped shaman bust, which is an armoured helm repainted bone. Deriving a third healer
strip by repaint was tried and rejected: the bust's shaman recipe masks steel at `s < 0.25`
and `v > 0.45`, and these ~30px figures carry about 10% desaturated pixels at `v = 0.26`,
so the repaint would have been invisible. The exception is declared to the test with its
reason rather than worked around.

**Three figures stay unclaimed** and are recorded as such: `ranger_as_rogue` and its second
pose (canon has no Ranger; its green leather is closest to `monk_rogue_armor`, whose two
slots are taken by the figures the sheets labelled `rogue`), and `knight_unlabelled_b`.
They remain available as scene crowd.

Enforced by `tests/unit/test_scene_stage.gd`: every canon class has a figure that exists,
no two classes share one, classes in one armour family share one reference figure unless
the file declares the exception WITH a reason, every unclaimed sliced figure is listed with
a reason, and `actor_for_class()` answers "" for a class canon does not have rather than
handing back a default.

---

<a id="bl-69"></a>
### BL-69 - A tier whose words are pending is GENERATED but not SHIPPED *(DECIDED - implemented; AMENDED 2026-09-15 - the valve stays and all five tiers now pass it)*

**Owner:** [09 §11.4](./09-items-and-itemization.md) owns the words, `sim/content/ContentDB.gd` owns the mount - **Signal:** Silent; it decides what a player can loot

**AMENDED (2026-09-15), with [Q-41](#q-41).** The twenty words are ruled - T2 Steel · Runeweave · Hallowed · Vanquisher; T3 Silvered · Starweave · Sanctified · Conqueror; T4 Adamant · Stormweave · Anointed · Ascendant; T5 Runegold · Voidweave · Exalted · Immortal (`raid_adj` = `raid_title` per [09 §11.4](./09-items-and-itemization.md)'s sanctioned collapse), with leather keeping its own column (Reinforced · Studded · Hardened · Masterwork · Flawless). The mechanism below is unchanged and stays as the valve; what changes is that no tier is pending any more, so `tier_is_named()` returns true for all five and `default_paths()` skips none. The Tier-1-only fallback (S17 on the Raid 1 clear, `data/_pending/`) is **not built** - it was the branch that existed only while the words were missing. W8-ITEMS regenerates against `data/tier_words.json` and clears `name_pending` on the 304 rows - ruled by the loop under the designer's 2026-09-15 delegation.

`ContentDB.default_paths()` discovers tiers by filename: drop `encounters_t2.json` in and Tier 2
mounts, which is exactly what [16 §7 X2.8](./16-production-roadmap.md) asks for - a full tier
authored with no engineering change. Running `tools/gen_items.gd` for the first time therefore
put 336 items and 32 encounters into the shipped content set in one command, and three tests
that had been written against a one-tier world started failing - correctly.

The problem is not the tiers. It is that their NAMES are pending (BL-69's sibling question,
[09 §11.4](./09-items-and-itemization.md), tracked as audit M5-T25-08), so every one of those
336 items is called `TIER2's Boots`. [10 §2](./10-content-and-encounters.md) forbids inventing
lore names, and a generator token is not a canon placeholder the way "Raid 1" and "Boss 3" are:
those are canon's own words, and `TIER2` is a variable that leaked.

**Decision: a tier mounts only when `data/tier_words.json` says its words are answered.**
`ContentDB.tier_is_named(tier)` reads that file; `default_paths()` skips a pending tier. The
files are still written, still tested by `tests/unit/test_tier_scaling.gd`, and still loadable
by name through `tier_paths(n)` - so the content is reviewable, and filling in four material
words and four titles is what ships it. With no words file at all the old behaviour returns
(mount whatever is on disk), so this cannot strand an installation that never had one.

---

<a id="bl-70"></a>
### BL-70 - The generated ladder is floored per SLOT, because a rising total does not stop a slot inverting *(DECIDED - implemented)*

**Owner:** [09 §13.2/§13.4](./09-items-and-itemization.md) - **Signal:** The loot loop; a player feels it as a downgrade

BACKLOG asked the tier generator to "validate no tier inverts power" and the first generated
rung failed it, in exactly the way [09 §13.4](./09-items-and-itemization.md)'s split invites:
§13.2 steps the family TOTAL by x1.10 across a tier boundary, §13.4 re-splits that total across
four slots by share, and a share plus a rounding rule can leave one slot flat or lower while the
total rises.

Measured, on the first rung the generator writes: `warrior_bard` legs went 5 AC / 6 HP at the
Tier 1 raid rung to 5 / 6 at the Tier 2 Adventure rung - flat - and `monk_rogue` legs went
5 / 6 to **5 / 5**, a downgrade. A player who cleared Tier 1's raid and opened Tier 2's
Adventure rung would have been handed worse legs.

**Decision: `TierScaling.floor_against_previous()` floors every generated slot against the same
slot one rung below, per stat, and adds one point to the stat that slot carries most of when
nothing rose at all.** It only ever adds, so it cannot make a piece worse; it is deterministic,
so the files regenerate byte-identically; and it leaves canon alone, because rungs 1 and 2 are
read from the Tier 1 files and never passed through it.

`tests/unit/test_tier_scaling.gd` asserts the property rather than the fix: per-slot
monotonicity, per-family totals, no cross-rung inversion (a tier's Adventure rung must beat the
tier below's raid rung), and no inversion in the numbers that reach the sim (effective HP through
the mitigation curve, and cloth Mana).

---

<a id="bl-71"></a>
### BL-71 - Tier 1's shipped encounter numbers were two years of drift behind §9.2, and doc 08 wins *(DECIDED - implemented)*

**Owner:** [08 §9.2/§9.3](./08-stats-and-formulas.md) - **Signal:** Loud; it changes every Tier 1 fight

[Q-17](#q-17) already ruled that **doc 08 §9 is authoritative for all arithmetic**. This is that
ruling applied to the one place it had never reached: the shipped encounters.

`docs/08` §9.2 says Boss HP 2,200 / 2,500 / 3,200 / 4,100 / 7,150 and §9.3 says raw swing
61 / 63 / 65 / 68 / 73 per round. `docs/10` §5.2 quoted an EARLIER §9.2 — 2,100 / 2,350 / 3,000 /
3,800 / 6,200 and 55 / 58 / 62 / 68 / 74 — and `data/encounters_t1.json` shipped that older set,
repeating it in its own `_notes` as though quoting the current doc. The correction that moved
§9's column is the one Q-17 names: **+2 Power on the Boss-4 chests**, which raised the
DPS-at-attempt row that §9.2 multiplies by the target round count. Doc 10 and the data never
followed.

**Decision: the data and doc 10 move to doc 08's numbers.** The HP split keeps each encounter's
shape (the adds stay where canon put them and the primary block carries the reconciliation) and
the per-round swing is re-split across each block's own swings/round, so E1 divides 61 four ways
and lands on 60, E3 divides 65 in two and lands on 66. `target_rounds` does not change, so the
enrage formula and the pacing test are untouched.

**What it cost, measured rather than assumed.** The goldens were regenerated deliberately and
they moved: `e5_first_clear` went from 21 rounds to **25**, against its own 22-round target, and
`e3_commons_adventure` from 19 to 21. That is the honest consequence of the correction - §9.1's
DPS column is NOMINAL and the fights are fought with the mistake tax on top - and it is recorded
here rather than tuned away, because docs/15 has exactly one number ever changed on judgement
alone (BL-29) and the bar is that there stays one. **If the Tier 1 raid is now too long, the fix
is a doc 08 §9 pass, not an edit to the encounter file.**

---

<a id="bl-72"></a>
### BL-72 - `AC_K` and `MANA_TO_SPELL` stop being flat, and doc 08 was wrong about where the cap binds *(DECIDED - implemented as switches, not yet threaded)*

**Owner:** [08 §9](./08-stats-and-formulas.md) - **Signal:** Silent at Tier 1; decisive at Tier 5

Doc 08 §9 raises two OPEN notes against itself and this entry answers both.

**The tank channel.** `AC_K` is a flat 60, so as the ladder climbs, `mitigation(ac)` walks into
`MITIGATION_CAP` and armour stops buying anything: the tank channel becomes a constant and the
boss swing that §9.3 solves against it becomes meaningless. §9's own proposal is
`AC_K(tier) = 60 * 1.5^index`, and that is now `Formulas.ac_k_for(tier)` with
`AC_K_TIER_STEP = 1.5`. A step of 1.0 IS the flat reading, and both are tested.

**Two things in §9's note are wrong about the ladder that exists, and both were measured rather
than argued.**

1. **Where the cap binds.** §9 says "the cap binds from roughly index 5 onward
   (mitigation(107) = 78.1%)", from a projected AC of 107. The gear ladder that actually exists -
   measured in §9.6, generated from docs/09 §13 - reaches AC 40 at Tier 3 Boss 1 (mitigation
   57.1%), 64 at Tier 4 (68.1%), and only touches the cap at **Tier 5 Boss 1** (AC 102, exactly
   75.0%). A Tier 5 problem, not a Tier 3 one: still real, because the last tier is the one where
   the tank channel goes flat, but a recommendation to implement rather than a fire.
2. **The step is per TIER, not per rung.** §9 writes `1.5^index`, and the ladder has ten rung
   indices across five tiers. Read per index, the correction over-shoots badly in the other
   direction: tank mitigation falls to 14.9% at Tier 3 and **11.1% at Tier 4**, which is armour
   that has stopped mattering just as completely. The ladder's own tank AC grows about x1.55 per
   TIER (17 / 26 / 40 / 64 / 102 at the raid rungs), so a K that grows x1.5 per TIER holds
   mitigation almost flat across the whole ladder: 36.2% / 36.6% / 37.2% / 38.7% / 40.2%. That is
   the reading implemented, and `test_the_per_rung_reading_of_the_doc_over_shoots` holds the
   rejected one so the choice stays visible.

**The caster channel.** The Mana ladder steps x2.00 per half-tier, and §9 says plainly that
either `MANA_TO_SPELL` decays 0.85 per tier or Mana's own step comes down to ~1.55, and that
**only one of the two may be written down**. The decay is the half implemented, as
`Formulas.mana_to_spell_for(tier)` with `MANA_TO_SPELL_TIER_DECAY = 0.85`, because it is the one
that does not move canon's Tier 1 item tables - the other would rewrite the ladder docs/09 §13.2
already fixed.

**Both defaults are inert.** Every caller that does not know its rung passes 0 (Tier 1's
Adventure rung), which is `AC_K = 60` and `MANA_TO_SPELL = 0.35`, so the shipped game and the five
golden hashes are byte-identical. `tests/unit/test_tier_constants.gd` holds the Tier 1 no-op, the
monotonic rise, the flat reading's clamp at Tier 5, the proposed curve never clamping anywhere on
the ladder, and the caster's share of a party staying inside ten points across all five tiers.

**What is deliberately NOT done yet:** threading the rung index into the budget derivation
(`TierScaling`, `tools/gen_items.gd`) and into `RaidSim._apply_damage` / the spell path. Those two
have to move in ONE commit - a budget sized with the curve and fights fought with the flat
constant would disagree about how hard every tier above one is - and neither matters until tiers
2-5 are named and ship (BL-69). Tracked as audit M5-T25-15.

---

<a id="bl-73"></a>
### BL-73 - Doc 10's S17 row is now IN doc 13, and the screen is built to it *(DECIDED - implemented)*

**Owner:** [13 §5](./13-ui-ux.md) - **Signal:** Silent until the last tier ships - **Propagates:** [10 §13](./10-content-and-encounters.md) row 1

[10 §13](./10-content-and-encounters.md) row 1 does not claim the screen. It asserts two things -
that a completion beat fires on the first clear of Raid 5's last encounter, and that **doc 13's
screen inventory must gain it as S17 - Completion / credits** - and then hands the screen to doc
13 in its own Owner column. Doc 13 never gained the row: its inventory ran S01-S16, and the words
"completion", "credits" and "victory" appeared nowhere in it. So the doc that OWNS the screen
carried no spec for it, and [Q-88](#q-88)'s ruling was half-propagated in exactly the way §2.2
step 4 exists to prevent.

**The edit the loop made, and why it is a propagation rather than invented canon.** Doc 13 §5 now
carries S17, and §9.5 carries its panel spec. Every line of both is either quoted from doc 10 §13
or derived from state the campaign already keeps - the loop chose the layout (archetype C, which
`art/ref/specs/10-screen-audit.md` §1 already defines and which Settings and the save screen
already use) and nothing else. It invented no rank, rate or name. This is the same move [BL-71](#bl-71)
made when doc 08 §9.2 and the shipped encounters disagreed: the doc that owns the decision wins,
and the propagation is written down here so the amendment is visible rather than discovered later
as unattributed canon.

**What the screen is, in one sentence:** a report and a door back to town. [Q-88](#q-88) rules that
the save continues past the beat, so S17 ends nothing, resets nothing and locks nothing; the only
exit is S02. It carries no prestige button, no difficulty toggle and no New Game+, because doc 10
§13's closing paragraph refuses to invent an endgame mode and [docs/16](./16-production-roadmap.md)
R-4 lists Tier 6 and heroic mode as cut.

**Three details that are rulings rather than layout.**

1. **The beat is spent on ARRIVAL.** `GameState.completion_seen` is set when the screen builds, not
   when its button is pressed. A player who closes the game while reading their ending has seen it;
   re-showing it on the next load would be the game deciding they had not.
2. **Re-reading it is deliberate and reachable.** The Guildhall's Records tab gains a button to it
   once `completed` is true. A report that can never be opened again is a cutscene, and doc 02 §4.4
   makes Records a reading surface precisely so the guild's history stays readable.
3. **The credits block is DATA.** The screen reads `data/credits.json` and prints its lines
   verbatim. Audit M5-END-4 is the open half - who the game credits, the third-party attribution
   the fonts and any CC0 assets owe, and [Q-21](#q-21)'s provenance question - and none of it is a
   build loop's to answer. So the file ships containing one `status` line saying it is awaiting
   sign-off, and the screen prints that line. This is the shape [BL-58](#bl-58) already used for the
   Legendary quirks: ship it inert, carrying its own status, rather than ship a plausible
   invention.

**Where it fires from.** S12 Results. When the beat is pending its exit row collapses to a single
crimson commit - the one screen in the game where there IS a single commit - and pressing it opens
S17; when it is not, the two ordinary exits are unchanged. That keeps `art/ref/specs/06-ui-component-kit.md` §3's one-crimson-control
rule true in both states and means the ending cannot be walked past by accident.

**Pinned by** `tests/unit/test_screens.gd` (the screen prints the guild, the day, the rank, both
meters and the continue button; the credits status line is printed verbatim; the town is reachable
from it; a second clear after `completion_seen` does not re-route) and `tests/unit/test_completion.gd`
(the state half, landed as audit M5-END-1). Unreachable in a real playthrough until tiers
2-5 are named and ship ([BL-69](#bl-69)) - which is the reason to have built and tested it now
rather than the reason not to.

---

<a id="bl-74"></a>
### BL-74 - Doc 14 §10.1's pre-export gate list names five tools this build never grew *(DECIDED - mapped and implemented; the last gate landed as audit M6-EXP-06)*

**Owner:** [14 §10.1](./14-technical-architecture.md) - **Signal:** Silent until somebody ships a build

[14 §10.1](./14-technical-architecture.md) lists six pre-export gates and its own rule for them:
**"a gate that cannot run is not a gate"**. Five of the six name a tool that does not exist in this
repository. That is not doc 14 being wrong so much as the project having taken a different and
equivalent route - it grew `tools/verify.sh` rather than five separate scripts - but the gap had the
worst possible shape: a release checklist that reads as satisfied because nobody can run it to find
out. The tempting move was to drop the rows that name missing tools. This entry is the other move.

**The mapping, gate by gate. Every row is a command that runs today.**

| §10.1 gate | Names | Actually runs as | Verified |
|---|---|---|---|
| (1) sim purity | `check_sim_purity.sh` | `tools/export_build.sh` step 2/8 - one `grep` over `sim/**.gd` for `Engine.`, `get_tree()`, `OS.`, `Time.`, unseeded `randi/randf/randomize`, and `res://game/`; plus `tools/lint_no_global_classes.sh` as gate stage 0 | green, 0 hits |
| (2) generator is idempotent | `gen_items.gd` produces no tree change | `tools/verify.sh` stage 2/8 - `gen_items.gd -- check` rebuilds all sixteen Tier 2-5 files in memory and compares them to what is committed, writing nothing. The mode had existed since the generator was written and had no caller; audit `M6-EXP-06` wired it. Deliberately NOT in `export_build.sh`: a release build must not mutate the tree it is packing | green, 0 files differ |
| (3) unit + golden tests | unit + golden green | `tools/verify.sh` stages 1-2 (parse check + the whole suite, `tests/unit/test_golden.gd` among it) | green |
| (4) §5.4 assertions 1-10 | incl. no `stats_pending`, no `shippable: false` | the content assertions live inside `ContentDB.is_valid()` / `error_report()` and run at boot from `game/ui/Boot.gd`, which gate stage 3 exercises; assertion 10 specifically is `tools/export_build.sh` step 1/8, a LIST of pending flags rather than two greps | green (boot); step 1 correctly HOLDS today, below |
| (5) atlas check | `art/tools/export_all.ps1 -Check`/`-Verify` | `tools/build_art.sh`. There is no PowerShell driver and no `art/tools/`; the pipeline is bash + Aseprite's Lua API, which [Q-95](#q-95) already rules is how this machine is scripted | runs |
| (6) pck hygiene | no stray imported paths in the `.pck` | `tools/export_build.sh` step 6/8 - `grep -a` for `res://ideaboard/`, `res://Aseprite/`, `res://build/`, `res://art/` and `res://docs/` inside the pack, which works only because `binary_format/embed_pck=false` | green, 0 hits each |

**All six gates run now.** Gate (2) was the one owed when this entry was written and was wired by
audit `M6-EXP-06`; the row above is updated rather than the entry being re-filed, because the mapping is
the decision and only its status moved.

**Two rows of §10.1 were wrong about this machine and are corrected in place.** Its *Gate prerequisites*
row required ripgrep on `PATH` "or the PowerShell equivalent" - `rg` is still not installed and nothing
here needs it, because every check is plain `grep` under Git Bash. The same row required PowerShell for
gate (5); the art pipeline is bash and Lua. `content_src/` and `art/_ref/`, named in §10.3's `.gdignore`
list and in the build order, do not exist in this project either and are not owed.

**The export path is now verified rather than asserted**, which is the other half of this entry:
`tools/export_build.sh` was written in the rename commit and had never been run under the loop. Both
presets export (`AGuildStory.exe` + a 28 MB separate `.pck`, and `AGuildStory.x86_64`), all five pck
hygiene greps return zero, and **the exported build boots clean for 180 frames from the pack** - which
is the only check that distinguishes a build from an artifact, because `--export-release` returns 0 over
a project that cannot start. The Linux binary is exported and explicitly NOT launch-checked; there is no
Linux runner on this machine and the script says so rather than implying it passed.

**A release is currently BLOCKED on content, correctly.** Step 1/8 holds on 16 files carrying
`stats_pending: true` or `name_pending: true`: the eight generated tier item tables ([BL-69](#bl-69) -
unnamed tiers generate but do not ship) and the eight Legendaries whose names [03 §5.6](./03-guild-reputation.md)
forbids inventing. `--dev` exports past it and stamps the result **NOT SHIPPABLE** in the sentinel line.
That is the designed behaviour and not a defect to route around: the gate clears when a designer supplies
names, not when somebody edits the gate.

**Pinned by** `tests/unit/test_export.gd`, which asserts the export CONFIGURATION the way the suite
asserts everything else - the preset exists and is unique, `embed_pck` is false and
`export_console_wrapper` is 2 (1 is debug-only and this script only ever runs `--export-release`, so 1
produced no wrapper and the launch check had nothing to run), the icon `project.godot` names is a file
that exists and the preset names the same one, the six `.gdignore` markers [14 §10.3](./14-technical-architecture.md)
requires are all present, and no secret is in the committed cfg. The export itself is not a suite stage:
it takes minutes and needs the templates installed, so it stays a command a person runs.

---

<a id="bl-75"></a>
### BL-75 - Does doc 13 §13's three-changes-a-second rule govern the WORLD layer, or only the UI? *(DECIDED - UI only, both readings switched and tested)*

**Owner:** [13 §13](./13-ui-ux.md) - **Signal:** Silent unless read literally, in which case the shipped
art violates the doc

[13 §13](./13-ui-ux.md)'s reduced-flashing row is one sentence: **"No element exceeds 3 changes per
second. Nothing flashes at all."** It is unconditional and deliberately not a player setting - §15.1 says
so in terms, "a build requirement with a QA gate, not a toggle the player can get wrong". So it wants a
number in code and a test, and building that is what made the ambiguity visible.

**The shipped art does not obey it, read literally.** `SceneStage`'s hearth and brazier flames run at 9
fps, both arena fires at 8, and the townsfolk idle cycles at 5 (`game/assets/scenes/stage_*.json`). Every
one of those is more than three changes a second.

**Two readings, and they are not close.**

1. **UI only** - the row is a PHOTOSENSITIVE rule and its own section is the UI document's. [13
   §12.2](./13-ui-ux.md) closes by saying *"Nothing in the UI loops, pulses, or breathes; ambient motion
   belongs to the world layer and is doc 12's"*, which puts the flames outside §12's scope before §13
   ever speaks. A fire cycling through near-identical frames is not a "change" in the sense a flashing
   rule means - the hazard is luminance flashes, not frame counts.
2. **Everything** - "no element" means no element. Cheap to honour, and it would run every fire, candle
   and breathing idle in the game at three frames a second, which is a slideshow rather than a camp.

**Reading 1 is shipped**, as `GameSettings.FLASH_RULE_COUNTS_WORLD_MOTION = false` with
`flash_rule_applies_to(layer)` as the one place it is asked. Both readings are live in
`tests/unit/test_motion.gd`: the UI layer is held to three changes a second under either, and the test
that holds the literal reading flips the switch and asserts what it would cost - which is the shipped
art failing, stated as a measurement rather than as an argument.

**What is NOT at stake.** A player who needs the motion stopped is already served, and by the other,
separate row: reduced motion halts the world layer outright in `SceneStage.apply_settings()` - the
flames stop, the lights stop breathing, the idles freeze. This entry decides only whether a guild that
has NOT asked for that is allowed to see a fire flicker. Nothing here weakens the accessibility
guarantee; it decides which layer a QA gate measures.

**If the designer prefers reading 2** the switch flips and the scene JSONs' `fps` values come down with
it; nothing else moves, because every animation rate in the game is authored data rather than code.

---

<a id="bl-76"></a>
### BL-76 - `comedy_line` is one or two sentences, because half the shipped ones are two and they are better *(DECIDED - doc amended)*

**Owner:** [10 §6](./10-content-and-encounters.md) - **Signal:** Silent; nothing ever enforced it

[10 §6](./10-content-and-encounters.md)'s field table says `comedy_line` is **"Required. One sentence:
what makes this funny when it goes wrong."** Five of the ten hand-authored Tier 1 lines are one sentence
and five are two or three. Nothing checked, so the rule and the content have disagreed since the content
was written.

**The doc is the half that moves.** Read the two shapes side by side:

> *"Twenty-two rounds of your guild being nearly competent, and then Steve - morale 14, whom you brought
> anyway - stands in the fire on round 21."* (one sentence, `t1_raid_e5`)

> *"Three mobs and a party of six who have never met. Someone pulls before the tank; someone else is
> still reading their own spellbook."* (two, `t1_adv_a1`)

The second is not a rule violation looking for a fix; it is the setup-then-punchline the first one
achieves with a dash. Rewriting the five two-sentence lines to obey a count would make them worse to
satisfy a constraint the doc never explained and never enforced - and §6's actual PURPOSE, stated in the
same cell, is the cut rule: *"If it cannot be filled in, the encounter is a chore and should be cut."*
That is about whether a fight has a joke in it at all, not about punctuation.

**Amended to "one or two sentences"**, and the line that says so points here. The generated Tier 2-5
lines in `tools/gen_items.gd`'s `COMEDY` table were authored to the same shape and need no change.

**What is enforced instead**, because a rule nothing checks is how this drifted in the first place:
`Encounter.COMEDY_LINE_MIN` (40 characters) is now a validator rule and the single bar all three gates
read. Before it, three gates checked this field and no two agreed - `test_encounters.gd` wanted more
than 40 characters, `test_adventures.gd` wanted more than 20, and the validator wanted only non-empty -
and the corpus passed all three by accident. The floor is a PLACEHOLDER DETECTOR, not a prose rule: it
sits far below the shortest shipped line (103 characters) and its only job is to refuse "TBD".

**Sentence count is deliberately NOT tested.** A test that counted full stops would be policing prose,
and [16 R-3](./16-production-roadmap.md) already says the thing no test in this project may claim:
whether the writing is funny is a human's read. Two tests that were missing now exist instead - every
encounter in `data/` carries a line (walking the FILES, because BL-69 keeps unnamed tiers out of the
default mount and a DB-based check would have seen ten of forty-two), and no two encounters share one,
which is the copy-paste failure the field exists to prevent.

---

<a id="bl-77"></a>
### BL-77 - The tutorial rewards had no SOURCE token, so the two trinkets could not be given a legal id *(DECIDED - doc amended, one token added)*

**Owner:** [09 §12.1](./09-items-and-itemization.md) - **Signal:** Silent; it blocks two item rows and nothing else, so nothing fails loudly

[09 §12.1](./09-items-and-itemization.md) fixes the item id grammar as
`ITM_T{tier}_{SOURCE}_{FAMILY}_{SLOT}[_{VARIANT}]` and enumerates `SOURCE` as
`START`, `ADV`, `RAID`, `VEND`, `QUEST`. The same table's `tier` row reads **"`0` = starting gear and
tutorial rewards"** - so the doc contemplates a tutorial reward in one cell and gives it no source token
in the next. [09 §10.2](./09-items-and-itemization.md) G12 then authors exactly two such items, the
Cracked Charm of Power and the Cracked Charm of Health, and they cannot be named.

**`TUT` is added to the `SOURCE` enumeration.** This is the smallest completion of a sentence the doc
already wrote, not a new concept: the tier column had already decided that tutorial rewards are tier 0
and distinct from starting gear, and every other content axis in the project - the encounters file, the
reputation award table, `is_tutorial_slot` - already separates a tutorial from the rung it sits beside.

**`START` was the alternative and is wrong for a load-bearing reason.** `source` is not a label in this
codebase: `sim/core/Loot.gd`'s non-raid drop pool selects on `it.source == "adventure"`, and
`data/items_starting.json`'s `starting_sets` is the contract the recruiter fills a new Common from.
Filing these two under `START` would put them one edit away from being handed to every recruit at
character creation, which is the opposite of a reward for clearing Adventure 0. Under `TUT` they are
unreachable by any pool and any set by construction.

**Shipped as:** `ITM_T0_TUT_UNIV_TRINKET_POWER` and `ITM_T0_TUT_UNIV_TRINKET_HEALTH` in
`data/items_tutorial.json`, mounted from `ContentDB.DEFAULT_PATHS` beside the tutorial encounters because
[10 §9](./10-content-and-encounters.md) gives the whole game exactly two tutorial rungs and Tier 2 does
not repeat them. `game/core/GameState.gd`'s `TUTORIAL_TRINKET` names the same two ids, and
`tests/unit/test_items_tutorial.gd` holds the grammar, the stat blocks and the inequality against the
live Adventure charms that makes the skip warning true.

**What this fixes, which is the real point:** the grant was already written.
`GameState._grant_tutorial_trinket` and its once-only guard, the drop-pool bypass, the skip warning's
fallback copy and a test that branched on whether the rows existed had all shipped - against two ids that
named nothing, so a first clear of either tutorial handed over nothing at all. The sixth instrument this
project has found complete and unarmed.

<a id="bl-78"></a>
### BL-78 - The hall family stands on the bare camp plate *(RULED by the designer, 2026-09-13 - recorded, not decided here)*

**Owner:** [art/ref/specs/09 §4.1](../art/ref/specs/09-background-plates.md) - **Signal:** Loud; five
screens (Guildhall with Roster / Facilities / Records, RaiderDetail, LoadSave, Settings) still mount
`guildhall_plate.png`, a crop of Concept 1 with its patrons and speech bubbles painted in

Audit `M4B-CONV-03` held the hall family's conversion as `blocked-needs-human` because the six bare
plates the designer supplied on 2026-09-11 contain no hall interior. On 2026-09-13 the designer wrote:
*"Right now it seems like we are using a lot of background graphics with baked in UI which need to be
replaced with our naked backgrounds and we need to build out the actual working graphics of the game."*
That is the ruling: no mockup crop under any screen, the supplied bare plates under all of them. The
hall family goes on **`stage_camp`** - the plate `BUILD_STATE.md`'s directive table had already assigned
it - with the panels over it; Settings inherits the stage of the screen that opened it, default
`stage_camp`. Whether the hall reuses the Town's framing or takes a tighter one on the big tent is the
only part still open and lands behind `HALL_FRAMING` (default `same`; plan Q03). The build-loop's own
part is the conversion itself (art plan unit `W1-HALL`); nothing here changes a canon number.

---

<a id="bl-79"></a>
### BL-79 - Does a skipped tutorial leave the board, and does a skip count as onboarding? *(DECIDED - switch + one reading; the docs/13 addendum landed with it)*

**Owner:** [10 §9.3](./10-content-and-encounters.md) / [01 §8.3](./01-core-loop.md) / [Q-90](#q-90) for the skip, [13 §5](./13-ui-ux.md) for where the prompt lives - **Signal:** Two docs, opposite answers

Two live forks, resolved together because they are the same question asked twice, plus a
third thing decided by omission, plus the screen question the state chart left open. Promoted
from `build/plan/q-tutorials.md` (audits `M5-TUT-06` / `M5-TUT-08`), with the switch's home
corrected to where it actually lives.

**Fork 1 — what happens to the mission.** [10 §9.3](./10-content-and-encounters.md)'s Re-run row
(marked 🔷 PROPOSED): "a skipped tutorial stays on the board and is replayable for gold, but its
trinket is gone for the run". [01 §8.3](./01-core-loop.md)'s Irreversibility row and [Q-90](#q-90):
"Skip is permanent — the mission leaves the board and the reward is gone." **Defaulted to the
register**, which is this project's tie-break and which [10 §9.3](./10-content-and-encounters.md)
itself marks proposed. Implemented as `RaidPlan.SKIPPED_TUTORIAL_STAYS_ON_BOARD := false`
(`game/core/RaidPlan.gd`), a named switch with both citations on it, so flipping it is one line
rather than an archaeology exercise. It lives on `RaidPlan` rather than on the Adventure's Board
because the ladder does: the screen that draws the board and `tools/playtest.gd`, which walks it,
read one switch, or a run could be proved completable under a rule the game does not use. Pinned
by `tests/unit/test_ladder.gd :: test_a_skipped_tutorial_leaves_the_board_and_unblocks_what_is_behind_it`.

**Fork 2 — does a skip complete onboarding?** [05 §6.3](./05-morale.md) gates disband on having
"completed Adventure 0 and the Tutorial Raid", and a skip is not a completion. But the skip is
permanent, so a player who skips both would be exempt from disband **forever**. **Decision: a
RESOLVED tutorial counts, cleared or skipped.** The gate exists to protect a player who has not
yet seen the game, not to reward clearing. `GameState.rung_resolved()` is the predicate
(`has_cleared` or `skipped_tutorials`), it is what the board's ladder gate asks instead of
`has_cleared()` — without that, "skip" would have meant "soft-lock the campaign" — and
`GameState._maybe_complete_onboarding()` sets the flag from the same predicate. Pinned by
`tests/unit/test_tutorials.gd :: test_onboarding_completes_only_when_both_rungs_are_resolved`
(fresh false; A0 alone false; both cleared, both skipped, one of each all true) and
`test_a_wiped_tutorial_does_not_complete_onboarding`.

**A third thing decided by omission and worth writing down:** a content set with **no** tutorials
leaves `onboarding_complete` **false**. This is the flag that arms a whole-roster wipe, and "the
onboarding file failed to load" is not consent to that.

**Where the skip prompt lives — a [13 §5](./13-ui-ux.md) addendum, not a screen.**
[01 §4](./01-core-loop.md)'s state chart names `TutorialSkipPrompt`, reached from `ConfirmRaid`.
[13 §5](./13-ui-ux.md)'s inventory had no screen for it, and this codebase has no dialog primitive
at all. **Decision: fold it into S09, the Adventure's Board**, as a warning Label plus a
`Skip the tutorial` Button in the Selected Notice sidebar, beneath the existing `Go to prep` CTA
(`AdventureBoard._skip_block()`). [01 §8.3](./01-core-loop.md)'s "Where the skip lives" row is
🔷 PROPOSED, not canon; canon requires only that the player be warned. The board is where the rung
is chosen and where the notice already prints its Potential Rewards, so the forfeit is legible
**next to the thing being forfeited** instead of one screen later — and a player who skips never
has to enter prep at all. The warning copy meets [10 §9.3](./10-content-and-encounters.md)'s two
requirements verbatim: it names the item and its stat (read off the granted item itself —
[BL-77](#bl-77)'s pair — with [09 §10.2](./09-items-and-itemization.md)'s authored pair as the
fallback) and says plainly "It is not a good trinket". Every string is a Label or a Button, because
the screen tests collect only `Label.text` and `Button.text` — a warning in a tooltip would be the
one canon-mandated sentence in the game that nothing tests. Pinned by `tests/unit/test_full_loop.gd`
(a fresh board names the trinket, its stat and "not a good trinket"; two skips open A1 and no Label
still begins with "A0") and `tests/unit/test_board_rows.gd` (exactly one "Skip the tutorial", on the
selected tutorial's paper). **No S17 for it** — S17 is [BL-73](#bl-73)'s completion screen. Doc 13
§5's S09 contents cell now lists the skip panel, which is the propagation §2.2 step 4 asks for.

---

<a id="bl-80"></a>
### BL-80 - The mistake-line budget sits above the doc floor, and the corpus is one file, not eighteen *(DECIDED - implemented)*

**Owner:** [07 §10.3](./07-combat-simulation.md) / [14 §5.3.5](./14-technical-architecture.md) / [14 §5.4](./14-technical-architecture.md) - **Signal:** Silent; a thin corpus reads as a bug, not a joke

Two rulings the mistake-line pass made, recorded together because both live in
`sim/content/MistakeLines.gd` and `data/mistake_lines.json`. Promoted from
`build/plan/q-comedy.md` (audit `M5-COMEDY-13`), with the measurement corrected against the
goldens as committed.

**1. The budget: 6 is the floor, 14 / 8 is the need.** [07 §10.3](./07-combat-simulation.md) rule 4
says "Each mistake type needs **at least 6 template variants** so a long raid does not repeat", and
[14 §5.4](./14-technical-architecture.md) assertion 7 says the same. Two docs, one number — and the
shipped goldens show six is not enough. Measured off the committed goldens on 2026-09-15 (counting
each type's `MISTAKE` header lines): `e1_commons_starting` is **22 rounds / 54 mistakes** and fires
*Forgot to Taunt* (`MIS_TAUNT_LAPSE`) **12** times; `e3_commons_adventure` (21 rounds / 30) fires
*Pulled Aggro Off the Tank* (`MIS_AGGRO`) **11** times; `e5_miserable_commons` is **11 rounds / 44
mistakes**, with *Dropped a Mechanic* and *Pulled Aggro* at **7** each and *Went AFK*, *Stood in the
Fire* and *Healed the Wrong Target* at 6. (The earlier draft's "eleven each in fourteen rounds" was a
figure from a golden that has since been regenerated under [BL-71](#bl-71); these are the current
ones.) At six variants the player watches the same sentence twice in a fight they are watching
tonight — [07 §5.5](./07-combat-simulation.md)'s own named failure mode: it "reads as a bug, not a
joke".

**Ruling: the floor stays and a measured budget sits above it.** `MIN_VARIANTS := 6` — the doc
floor, enforced on every type's UNGATED lines: a class- or severity-gated line is an extra on top
of the floor, so a type whose spare lines are all gated cannot drop a Cleric back to four, which is
the exact repetition rule 4 forbids hidden behind a passing row count. `HOT_VARIANTS := 14` — the
measured worst case (12) plus headroom — for the eight `HOT_TYPES`: `MIS_AFK`, `MIS_TAUNT_LAPSE`,
`MIS_WRONG_TARGET`, `MIS_HEAL_WRONG`, `MIS_AGGRO`, `MIS_ARGUMENT`, `MIS_FIRE`, `MIS_MECHANIC_DROP`
(every one of the eight now fires five or more times inside a single shipped golden; the pair the
draft called a forecast, `MIS_FIRE` and `MIS_MECHANIC_DROP`, are measured at 6 and 7 in
`e5_miserable_commons`). `COLD_VARIANTS := 8` for everything else, still comfortably above the floor.
`LEGENDARY_VARIANTS := 4` for the per-Legendary sets rule 4's second sentence asks for and gives no
number — `e5_legendaries_raid` records four mistakes in twenty rounds, so four lines is several
fights' worth for a rarity the player owns one of. 14 and 8 both satisfy "at least 6", so the docs
are tightened, not overruled; it is recorded because a reader who finds 14 lines where the doc asks
for 6 deserves to know it was measured.

**2. One file, not eighteen.** [14 §5.3.5](./14-technical-architecture.md) specifies
`data/mistakes/*.json`, eighteen files; the shipped corpus is one `data/mistake_lines.json` carrying
all eighteen types plus the nine Legendary sets — the same shape `data/backstories.json` took against
§5.3.6's `data/backstory_tags/*.json`. The corpus's load-bearing invariant is **global uniqueness of
the line text**: two types wearing the same joke reads as a bug rather than a callback. That check
is one pass over one document; across eighteen files it becomes a cross-file validator nobody would
write, and the writing pass loses the ability to read the whole corpus at once, which is the only
way a human can tell whether it is funny. The Legendary variants live in the same file rather than
in `data/legendaries/*.json`, and this half is genuinely arguable (`dialogue_barks` already lives in
each Legendary's own file). Three reasons it is here: the uniqueness check spans the whole corpus,
and a Legendary line duplicating a type line would otherwise fall between two loaders; a Legendary
file is a *character* record and a mistake line is a property of a *failure the character
committed*, keyed by a mistake type id, which is this corpus's vocabulary; and
`MistakeLines._validate_coverage()` derives the nine expected `legendary_<class>` sets from
`Enums.all_classes()`, so a tenth class fails loudly here where a missing file would fail quietly.
**Revisit if** the Legendary files ever gain line-shaped content beyond barks. **Migration path:**
§5.3.5's `MistakeType` record is data-driven tokens the code does not yet read — `sim/core/Mistakes.gd`
holds the type table in GDScript — and when it moves to data, `mistake_lines.json` stays the line
corpus and the type record references it by id, so the one-file ruling survives the move.

Pinned by `tests/unit/test_mistake_lines.gd` (coverage, the budget on both the row total and the
ungated subset, global uniqueness, resolvable tokens, the sentence envelope, no proper nouns). What
no test may claim — that the lines are *funny* — is the open human read recorded in
`build/plan/q-comedy.md` and audit `M5-COMEDY-12`. BL-21's per-encounter totals are the volume this
budget was sized under.

---

<a id="bl-81"></a>
### BL-81 - `data/reputation.json` is JSON, not doc 03 §9's `.tres`, and the fence is corrected in six places *(DECIDED - implemented; doc 03 §9 amended)*

**Owner:** [03 §9](./03-guild-reputation.md) / [14 §5.1](./14-technical-architecture.md) - **Signal:** Silent; a tuning file whose documented schema is not its real one is a file a designer edits wrong

Promoted from `build/plan/q-tuning.md` (audit `M3-TUNE-02` (1)-(2)); the corrected fence is
`build/plan/handoff-tuning.md` §1 and now stands in [03 §9](./03-guild-reputation.md).

**The format.** [03 §9](./03-guild-reputation.md) proposed `res://data/reputation.tres`;
[14 §5.1](./14-technical-architecture.md) flagged the pair as OPEN and [Q-94](#q-94) kept ".tres for
tuning singletons". **Ruling: JSON**, and §5.1's own deciding row settles it without a preference —
"Readable by `sim/` without breaking §3: `.tres` **No**, requires `ResourceLoader`, which `sim/` is
forbidden to call." The two consumers are `sim/core/Reputation.gd` and `sim/core/Recruitment.gd`,
both pure sim; a `.tres` reaches them only through a `game/`-side loader handing the tables in, which
is a second module and a second format to keep in step for no gain. §5.1's second reason applies too:
"the sweep harness in §9.3 exists precisely to load *altered* tables thousands of times", and a plain
Dictionary is what an altered table already is — `Reputation.override_tables()` is that seam and
needs no file. What survives of Q-94's answer is narrow: a `.tres` is still right for the
`game/`-side singletons §5.1 lists beside this one (the UI Theme is the live example); a table the
pure sim reads is JSON. Doc 14 §5.1's OPEN note and doc 16 W2.6's `reputation.tres` now say so.

**The fence.** §9's block was written before [BL-35](#bl-35) and [BL-37](#bl-37) changed the award
tables, and six of its keys no longer described the code. **The file wins in all six, and §9's fence
is replaced with the shipped shape.**

| # | §9 said | The file has | Why the file wins |
|---|---|---|---|
| 1 | `unlocks_content` / `unlocks_building: Array[StringName]` | `max_raid_tier: int`, `max_adventure: int` | §2.3 closed rank→tier gating in [03 §7](./03-guild-reputation.md)'s favour and had doc 10 delete its rival table; an id list would re-open it. Building ids are doc 02's and §7 never names one — the prose row below |
| 2 | `market: {stock_tier, sell_pct, buy_pct}` | `stock_tier`, `sell_rate`, `consumable_price`, flat in the rank row | The numbers are §7's. A `_pct` suffix on a fraction is exactly the misreading [14 OQ-2](./14-technical-architecture.md) exists to prevent, so `sell_rate` keeps the unambiguous name, and `consumable_price` is the buy-side multiplier §7's ladder prints (100/100/95/90/85/80). Flat because every other rank column is |
| 3 | one `awards: Dictionary` (encounter id → first/repeat) | `raid_awards` (by slot), `adventure_awards` (by adventure tier), `tutorial_awards` (by slot), `rung_cumulative` (by rung) | The split is load-bearing: §6.2 multiplies the raid table by tier and does NOT multiply the adventure table (§6.4 prices Adventure 2 at 50 beside Raid 2 Enc 1-3 at 50 × 2), and one dictionary keyed by encounter id cannot say which table is tier-scaled. `rung_cumulative` exists because [BL-24](#bl-24) made one rung one encounter and [BL-37](#bl-37) split an Adventure across three |
| 4 | `full_clear_bonus_base: int = 50` | `full_tier_bonus: [50, 10]` | [BL-35](#bl-35) pays the bonus once per tier and deliberately kept the repeat value in the table for the day a lockout clock lands; a scalar throws the 10 away |
| 5 | neither `stall_attempts` nor `catchup_enabled` | both | Both are stated in §8.1's own prose (M3's "5+ times without clearing it"; "keep M3 behind a config flag"), both are read live, and [BL-36](#bl-36) ships the flag ON |
| 6 | `pity_threshold: int = 25`, and stops | plus `pity_min_rank: 2` | §8.1 M2 is a two-number rule ("when `pity >= 25` … Active from **Respected** onward"); half a rule in a tuning file is worse than none — a designer who moves the threshold could not move the rank it starts at |

**`town_unlock` and `market_stock` stay free text — deferred, not refused.** §7's Town-unlock and
Market-stock columns are prose ("Blacksmith opens", "Greater potions") and §9 asked for
`unlocks_building: Array[StringName]`. Doc 02 owns the building ids and §7 never names one, so a
structured list would have to invent six sets of ids, which house rule 1 forbids.
`Reputation.town_unlock()` and `market_stock()` return the strings §7 prints, and
`Reputation.market_stock_tier()` carries the one part of the column that IS structured — the potion
rung [BL-44](#bl-44) / [BL-54](#bl-54) give the rank. Those two strings are display copy living in a
pure-sim module with no non-test caller (audit `M3-LOOP-03`); if the town screen turns out to want
ids, this is where the decision was made and where it is re-opened. Revisit when doc 02 publishes a
building-id table.

**What the file does NOT carry**, so nobody looks for it: doc 04's tables — `COST_BASE` /
`COST_PER_TIER`, `EXPERIENCE_BANDS`, `GEAR_RECIPES` / `GRANT_SLOTS` — stay as named constants in
`sim/core/Recruitment.gd` until the economy sweep ships a sibling `data/recruitment.json`; a `gear`
key inside `reputation.json` would put a doc-04 table in a doc-03 file and undo the boundary. The
file is the only source for what it does carry: the five old constant names (`Recruitment.FIND_WEIGHTS`,
`PITY_THRESHOLD`, `PITY_MIN_RANK`, `Reputation.STALL_ATTEMPTS`, `CATCHUP_ENABLED`) survive as
derived aliases computed from it, so no number exists in two places
(`tests/unit/test_reputation.gd :: test_no_tuning_number_exists_in_two_places_at_once`).
`Reputation.validate()` runs §9's three load assertions plus a fourth — exactly one row per canon
rank, in the enum's order — each a collected error naming the rank, never a crash. The key-parity
test the file's `_notes` name — the shipped top-level and per-rank key sets against the fence,
failing in both directions, `_`-prefixed provenance exempt — is `M3-TUNE-02` (3): it reads the
fence out of doc 03 §9, which is why the fence had to be corrected first.

---

<a id="bl-82"></a>
### BL-82 - There is no position layer, only abstract flags *(DECIDED - implemented)*

**Owner:** [07 OQ-7](./07-combat-simulation.md) / [10 §10 M07](./10-content-and-encounters.md) - **Signal:** Silent - the question table carried the recommendation and nothing had ratified it

Promoted from `build/plan/q-mech-arms.md` (the mech-arms unit's judgement call, M5; audit `m6-mech-arms-register`, SIM-27). The switch is in `sim/core/RaidSim.gd`; the code comment cites this entry from the wave-6 close.

**Ruling: abstract flags only.** The simulation carries no coordinates, no grid and no distances. A
raider is in exactly one of two named states, `Enums.Stance { SPREAD, STACKED }`, and nothing else
about space is representable. A mechanic may demand a stance for a window of rounds; a raider is in
the demanded stance if they answered that round's mechanic check and in the other one if they fumbled
it, so "off-position" is a synonym for "failed the check" — which is what makes M07 a
`MIS_MECHANIC_DROP` mechanic rather than a movement puzzle the player cannot touch. Three reasons in
the order they mattered: doc 02's claim that the player is not in the raid (coordinates would be state
the player can neither see nor influence, paid for in every golden forever); M07's own spec needs only
a two-valued flag; a grid would make doc 10 §12's forty-encounter budget an authoring problem.

**What it costs.** The class-derived default stance (melee `STACKED`, everyone else `SPREAD`, set in
`RaidSim._build_combatants`) is observable only OUTSIDE a live M07 window — inside one the check
result overwrites it — so the default is nearly decorative. `Enums.Stance` is the whole model; there
is no wider one behind a flag, because half a position layer would be worse than either answer.

**An m07 that names no stance demands nothing.** Doc 10 §10 M07 "demands Spread or Stack" and
privileges neither, so RaidSim may not pick one for an encounter that omits `required`: it opens no
window, charges nothing, and emits "The fight demands a position and nobody can say which" (the same
treatment [BL-83](#bl-83) gives an unauthored effect). Asserted by
`tests/unit/test_raid_sim.gd::test_m07_without_a_named_stance_demands_nothing_and_says_so`. No Tier 1
encounter authors m07; this is a rule for Tier 2 authoring.

---

<a id="bl-83"></a>
### BL-83 - M05's effect `E` is authored per encounter, and an unauthored one is a demand with no teeth *(DECIDED - implemented; E4's content owed)*

**Owner:** [10 §10 M05](./10-content-and-encounters.md) - **Signal:** Silent - the doc names E and never says what it is

Promoted from `build/plan/q-mech-arms.md` (the mech-arms unit's judgement call, M5; audit `m6-mech-arms-register`, SIM-27). The switch is in `sim/core/RaidSim.gd`; the code comment cites this entry from the wave-6 close.

Doc 10 §10 M05 says "Boss casts on round `R`; unless ≥1 melee DPS is in position, effect `E` fires"
and never names E; no number for E exists anywhere in canon or the docs. **Ruling: E is a
per-encounter authored payload, not a constant** — `"effect": {"kind": "raid_damage" | "boss_heal_pct",
"amount": N}` on the mechanic spec. `RaidSim.INTERRUPT_EFFECT_DEFAULT_KIND` (`"raid_damage"`)
supplies only the KIND when an author gives an amount without one; the amount defaults to 0 and is
never synthesised, so an encounter that omits `effect` has a cast that resolves and does **nothing**
— a visible authoring gap rather than an invisible invented number.

**The content this leaves owed:** `data/encounters_t1.json`'s E4 m05 carries no `effect`, so its
fourth star buys a roll and no consequence (SIM-13, CRITIC-R5; audit `m6-e4-m05-effect`). The ship
plan's designer table (`build/plan/ship/00-plan.md` §6 row #55) carries the recommendation — `raid_damage` at the
tier's M02 pulse, E4: 27 — and W8-SIM-BALANCE authors it at that default if the page is silent.

---

<a id="bl-84"></a>
### BL-84 - The tank-swap debuff decays one stack per round off duty, and has no ceiling *(DECIDED - implemented)*

**Owner:** [10 §10 M01](./10-content-and-encounters.md) - **Signal:** Silent - the doc gives the stacks and the swap and never says the stacks come off

Promoted from `build/plan/q-mech-arms.md` (the mech-arms unit's judgement call, M5; audit `m6-mech-arms-register`, SIM-27). The switch is in `sim/core/RaidSim.gd`; the code comment cites this entry from the wave-6 close.

Doc 10 §10 M01 gives the stack rules ("+50%/stack damage taken, 1 stack per hit, swap required at
3") and nothing about the stacks leaving. Without decay the mechanic works exactly twice: both tanks
reach 3 and there is nowhere left to swap to. **Ruling: one stack per round while a tank is not the
active tank** — the mirror of one per hit while they are. `RaidSim.TANK_DEBUFF_DECAY_PER_ROUND` is
the switch (default 1).

**No ceiling, and that is not a question.** M01 names exactly one number, `swap_at`, and no maximum;
M12 says "**no cap**" in as many words for the escalating swing, so this vocabulary writes ceilings
down when it means them. A `TANK_DEBUFF_STACK_CAP_AT_SWAP` constant briefly capped the stack at
`swap_at` — a ×2.5 ceiling nothing in canon asks for — and its only real effect was to soften the
one case doc 06 says must hurt. Deleted; stacks are uncapped. Held by `tests/unit/test_raid_sim.gd`'s
M01 cases and `test_mechanics_arms.gd`.

---

<a id="bl-85"></a>
### BL-85 - M01 on a one-tank encounter: the sim invents nothing, says so, and holds the content question *(CLOSED on Q-100 (2026-09-15))*

**Owner:** [10 §8 (A3), §9.1 (TR), §10 M01](./10-content-and-encounters.md) - **Signal:** Loud - it makes A3 unclearable as authored and the Tutorial Raid nearly so

Promoted from `build/plan/q-mech-arms.md` (the mech-arms unit's judgement call, M5; audit `m6-mech-arms-register`, SIM-27). The switch is in `sim/core/RaidSim.gd`; the code comment cites this entry from the wave-6 close.

`data/encounters_adventure_t1.json` authors m01 onto A3 at `tanks_required` **1**, and doc 10 §8's
own A3 row and §9.1's Tutorial Raid row both give M01 to a one-tank party — so this is how the
vocabulary was written down, not an authoring slip. A solo tank cannot satisfy "swap required at 3",
and M01's rule set has no defined behaviour there. Taken literally the stacks never leave and the
holder dies: measured 0/24 on A3 with m01 as the only mechanic (tank dead at a mean round of 4.8
against a 12-round target), and the Tutorial Raid's pin ([BL-91](#bl-91)). A previous pass took the
opposite reading silently (`_tank_swap_is_live` gated M01 off below two tanks); this entry exists to
stop that being made in code.

**Behind a switch, both readings under test.** `RaidSim.TANK_SWAP_NEEDS_A_PARTNER` (a `static var`,
default **true**): M01 needs a partner and SAYS SO in the transcript when it has none, so the star is
inert but never silently inert (doc 10 §6 forbids that); `false` is the literal §10 reading — the
stacks arrive regardless and the composition punishment is lethal. `tests/unit/test_tutorials.gd`
and `test_adventures.gd` pin the measurement either way.

**The question is the designer's,** and it is the same ruling as the clear-rate curve and the swing
pricing: `build/plan/ship/00-plan.md` §6 rows #1 and #9 (keep the switch true and size A3 by doc 08 §9.3's formula
with the mechanic term, or replace A3's M01 with M04). Recorded, never resolved here.


**Closes (2026-09-15)** on [Q-100](#q-100): no Tier 1 encounter authors M01 on one tank (TR carries M03 — the fire — and A3 M04; E3 is the tier's first swap), `TANK_SWAP_NEEDS_A_PARTNER` stays true and dormant, and `Encounter.validate()` refuses `m01` where `tanks_required < 2` (W8-SIM-BALANCE) — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-86"></a>
### BL-86 - The fire's only exit is the authored re-roll, and there is no fire on a fight with no zone *(DECIDED - implemented; the eligibility half lands with SIM-14)*

**Owner:** [10 §10 M03](./10-content-and-encounters.md) / [07 §5.2 row 1, §6](./07-combat-simulation.md) - **Signal:** Silent - two documented exits that disagree, and a third case neither covers

Promoted from `build/plan/q-mech-arms.md` (the mech-arms unit's judgement call, M5; audit `m6-mech-arms-register`, SIM-27). The switch is in `sim/core/RaidSim.gd`; the code comment cites this entry from the wave-6 close.

Doc 07 §5.2 row 1 says the raider "leaves at end of next round, or immediately on BACK OFF!"; doc 10
§10 M03 says "a raider re-rolls out at `p` per round"; `Enums.TOKEN_DURATION[Token.FIRE]` is -1,
"until cleared". **Ruling: doc 10's re-roll is the implemented exit**, because it is the one content
parameterises — `escape_chance_bp` is authored on E4 and E5 and was read nowhere. An encounter that
omits the param keeps a permanent zone (doc 07 §6's "until the raider leaves" with no way to leave);
doc 07 §5.2's "end of next round" reads as the EXPECTED outcome of a 50% per-round re-roll, not a
second rule. If that is wrong the fix is a token duration, which moves `Enums.TOKEN_DURATION` — the
reason this is an entry and not a silent choice. The code did NOT do this before: `_phase_effects`
ran an unconditional "out at the end of the round after entry" before the roll, so every stay capped
at two ticks. The re-roll is now the only exit —
`tests/unit/test_raid_sim.gd::test_m03_puts_raiders_in_the_fire_and_takes_them_out_again` asserts a
stay can exceed two rounds at 5000bp, and `::test_m03_without_an_escape_chance_is_a_zone_you_cannot_leave`
the permanent case.

**No fire without a zone.** Two MECHANIC-site mistake types emit `Token.FIRE` and neither is gated
on the encounter carrying m03, so a tank-swap check on E3 — which has no ground effect — could stamp
a token nothing would ever clear. `_phase_mechanic_checks` refuses the stamp: the encounter card
decides which consequences are in play. The other half — `MIS_FIRE` never being ELIGIBLE on an
encounter without a zone, so the sentence "stood in the fire" cannot fire either — is SIM-14, landed
by W6-SIM-CASCADE (`test_mistakes.gd::test_no_fire_mistake_on_an_encounter_without_a_ground_effect`).

---

<a id="bl-87"></a>
### BL-87 - M10 ships as a Silence only; the Mana drain and Focus itself are post-1.0 *(DECIDED — Focus stays post-1.0 and its numbers are decided (DECIDED-for-1.1); M10 ships as Silence)*

**Owner:** [10 §10 M10](./10-content-and-encounters.md) / [Q-02](#q-02) / [08 §5.3](./08-stats-and-formulas.md) - **Signal:** Silent - one row, two mechanics, and one of them has no resource to spend

Promoted from `build/plan/q-mech-arms.md` (the mech-arms unit's judgement call, M5; audit `m6-mech-arms-register`, SIM-27). The switch is in `sim/core/RaidSim.gd`; the code comment cites this entry from the wave-6 close.

Doc 10 §10 M10: "For `N` rounds, casters lose `X` Mana per round **or** cannot act." **Ruling: the
silence half ships; the drain half is blocked and stays off.** `Formulas.MANA_MODEL` is
`MAGNITUDE_PLUS_FOCUS` per [Q-02](#q-02), whose own docstring says Focus "is a separate class-fixed
resource that never appears on an item" — and no Focus pool exists: no field on `Combatant`, no
class-fixed values in `data/classes*.json`, no spend anywhere. Mana in the sim is a flat magnitude
read off the gear profile and consumed by nothing. Building a pool inside a mechanic arm would
contradict the documented model, so `RaidSim.MANA_BURN_DRAIN_ENABLED := false` and
`Formulas.FOCUS_ENABLED` stays false.

**Focus is out of 1.0, in writing** (`build/plan/ship/00-plan.md` §6 row #54, §7.1; SIM-04, CONTENT-27, audit
DW-C1/C2): it is an L unit that needs the designer's `focus_max` / `focus_per_cast` per class and a
rule for an empty pool, its first carrier is a Tier 3 encounter, and the three "resource still spent"
heal mistakes have distinct outcomes without a pool (W7-SIM-EFFECTS). W7-DOCS amends doc 10 §10's M10
row to say Silence, and doc 08 §5.3 / doc 07's heal mistakes to say the pool is post-1.0. If the
designer supplies the numbers, this entry is where the drain half is re-opened.


**Amended (2026-09-15): Focus stays post-1.0 and its numbers are decided.** `FOCUS_MAX` 100 for Cleric, Druid, Shaman, Mage and Wizard and 60 for the Bard; `FOCUS_REGEN` 7 / 7 / 7 / 8 / 8 / 5 per round; primary cast costs 9 / 14 / 12 / 11 / 10 and the song's; class-fixed, never on gear (Q-02). An empty pool heals at `HEAL_FLOOR` or hits for the staff alone with Mana counted as 0; a wasted heal spends its full cast and the Focus token (docs/07 §6's Mana token, renamed) doubles the next heal's cost; M10's drain is `drain` Focus per round on the record, default 10, while the silence half ships now. The Bard's +20 Mana Instrument feeds song magnitude (Q-46), not a pool. docs/08 §5.3's table goes 🔷 → DECIDED-for-1.1 with its three riders answered; docs/10 §10's M10 row reads "Silence Window; the drain half is 1.1"; docs/07 §5.2's three healer mistakes and its §6 token read Focus (1.1); DW-C1 closes with the numbers, DW-C2's docs/07 edits land here and its docs/06 / docs/09 lines by `build/plan/handoff-W7-DOCS.md`. At those numbers over E5's 22 rounds the Cleric never runs dry (100 + 7 × 22 = 254 ≥ 198), the Druid rations from round 15, the Shaman from 21 — the "dry at 20 %" beat lands only on the tier's last boss. `MAGNITUDE_ONLY` must reproduce the 1.0 goldens byte-for-byte when the 1.1 unit lands — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-88"></a>
### BL-88 - The tank is melee-positioned, so Frontal Cleave hits it *(DECIDED - implemented)*

**Owner:** [10 §10 M11](./10-content-and-encounters.md) - **Signal:** Silent

Promoted from `build/plan/q-mech-arms.md` (the mech-arms unit's judgement call, M5; audit `m6-mech-arms-register`, SIM-27). The switch is in `sim/core/RaidSim.gd`; the code comment cites this entry from the wave-6 close.

Doc 10 §10 M11 is "`X` damage to all melee-positioned raiders each round", class stressed "Rogue,
Monk, Warrior". **Ruling: yes, the tank is in front.** The Warrior is named in the stressed column and
the Warrior is the tank in every canon composition, so a reading that spares the tank contradicts the
row's own second column. `RaidSim.FRONTAL_CLEAVE_INCLUDES_TANK` (default `true`) is the switch; the
predicate that decides who is "in front" is [BL-93](#bl-93).

---

<a id="bl-89"></a>
### BL-89 - "No cap" on the escalating swing versus the 40-round cap on the fight: no interaction, and the announcement has a cadence *(DECIDED - implemented)*

**Owner:** [10 §10 M12](./10-content-and-encounters.md) / [07 §7.3](./07-combat-simulation.md) - **Signal:** Silent

Promoted from `build/plan/q-mech-arms.md` (the mech-arms unit's judgement call, M5; audit `m6-mech-arms-register`, SIM-27). The switch is in `sim/core/RaidSim.gd`; the code comment cites this entry from the wave-6 close.

Doc 10 §10 M12: "Boss raw swing +`X` per round, **no cap** — a soft enrage." Doc 07 §7.3 makes the
40-round cap a safety property. **Ruling: nothing to resolve — the swing has no cap, the fight does.**
`tests/unit/test_raid_sim.gd::test_m12_still_terminates_inside_the_round_cap` asserts termination
rather than assuming it. The announcement cadence (`RaidSim.ESCALATION_ANNOUNCE_EVERY`, 5) is a
log-readability choice and not a mechanic parameter — the swing grows every round regardless; twenty
lines of "the swing is bigger" would be a wall, not a story beat.

---

<a id="bl-90"></a>
### BL-90 - The tutorial mistake rate is HALF, and the two pulls are off *(DECIDED — a two-entry table: A0 0.0, TR 0.5 (W8-SIM-BALANCE); BL-91 closes with it)*

**Owner:** [Q-51](#q-51) / [07 OQ-9](./07-combat-simulation.md) / [10 §9.1](./10-content-and-encounters.md) - **Signal:** Silent - the ruling gave a direction and no number, and the sim ran both tutorials at the full rate

Promoted from `build/plan/q-W5-SIM.md` (W5-SIM, wave 5; audit `m6-mech-arms-register`, SIM-27).

[Q-51](#q-51) is DECIDED — "Reduced rate for both tutorials, full rates from Adventure 1 onward",
mirroring 07 OQ-9, which names `MIS_FACEPULL` and `MIS_NINJAPULL` as the two types to disable.
Neither text says how much "reduced" is. **Decision: `Mistakes.TUTORIAL_MISTAKE_MULT := 0.5`,
applied to the gate chance only, at every roll site, for every encounter whose slot
`Reputation.is_tutorial_slot()` knows ("A0", "TR").** `Mistakes.Context.tutorial` carries the flag;
`RaidSim._context()` sets it from the encounter and the two roll sites that build a Context by hand
read it off the mechanic state. `Mistakes.TUTORIAL_DISABLED_TYPES := ["MIS_FACEPULL",
"MIS_NINJAPULL"]` are dropped from `eligible_types()` under the flag. The taxonomy, weights and
severity model are untouched, so a tutorial mistake reads exactly like a real one; it happens half as
often.

| Option | Cost |
|---|---|
| 0.5 | One halving, no second number to explain; the tutorial still shows roughly one action in eight failing for a Common at Content, which is the beat §9.1 needs the player to see |
| 0.25 or lower | Adventure 0 would rely on its scripted mistake alone; the Tutorial Raid's six-raider fight would show almost none |
| Per-tutorial values | Two numbers for one sentence of ruling; nothing in canon distinguishes the two rungs' rates |

Pinned by `tests/unit/test_mistakes.gd` (the two types are never offered to any class at any site
with the flags armed; `Mistakes.chance_bp()` is exactly `round(full × 0.5)` over 60
rarity/morale/site cells; the observed hit rate through `roll()` sits at 0.38-0.62 of the real one
over 6000 rolls) and `tests/unit/test_tutorials.gd::test_both_tutorials_roll_at_the_reduced_rate_and_a_real_rung_does_not`.
Every golden and every balance-sweep cell is byte-identical (`--drift`: +0.0pp on all eight reference
cells). The number is the designer's to confirm or split (A0 "only the scripted one", TR 0.5):
`build/plan/ship/00-plan.md` §6 row #57; the ship default is 0.5 / 0.5 as a two-entry table (W8-SIM-BALANCE).


**Amended (2026-09-15): a two-entry table.** A0 rolls no organic mistakes and fires only its scripted round-3 one; the Tutorial Raid rolls at half rate — `Mistakes.TUTORIAL_MISTAKE_MULT = {"A0": 0.0, "TR": 0.5}` read by `Context.tutorial_slot`; the two pull types stay disabled on both. Q-51's "reduced" is read per tutorial: Adventure 0 teaches the player to read a mistake and shows exactly one, as docs/10 §9.1 and its own comedy line ("On the third round somebody will do something stupid, and that is the lesson.") promise — at 0.5 somebody does something stupid on round 2 and the line lies; the Tutorial Raid is the fight designed to be lost and keeps half rate so its Wipe Report has organic causes. `test_mistakes.gd`'s 60-cell check runs per slot; A0's pin stays `>= 18/20` (expected 20/20); the `raid-clear` sheet's A0 tile reads "Mistakes 1". [BL-91](#bl-91) closes with it: TR's sizing ([BL-110](#bl-110)) was done at 0.5, so the coupling is answered in the same commit and the pin becomes `>= 8/20` — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-91"></a>
### BL-91 - The reduced tutorial rate moved the Tutorial Raid's pinned measurement from 0/20 to 1/20 *(❓ OPEN - canon question, recorded, not retuned)*

**Owner:** [10 §9.1](./10-content-and-encounters.md) / [Q-51](#q-51) - **Signal:** Loud - a pin moved with no number changed

Promoted from `build/plan/q-W5-SIM.md` (W5-SIM, wave 5; audit `m6-mech-arms-register`, SIM-27).

`tests/unit/test_tutorials.gd::test_the_tutorial_raid_is_currently_unwinnable_and_that_is_recorded`
pins the Tutorial Raid's clear rate with the squad the game hands you as the record of a defect only
a designer may fix (the swing was priced without M01's multiplier; the pin's own comment has the
measurement, one factor at a time). That 0/20 was measured at the FULL mistake rate. With
[BL-90](#bl-90)'s 0.5 in the sim, one of the twenty seeds clears: **1/20**. Only the halving can have
moved it — `MIS_FACEPULL` needs a trash phase and TR is a boss; `MIS_NINJAPULL` needs a break phase
and nothing in RaidSim opens one. Nothing about TR's swing, HP or M01 changed, and 1/20 is not
"winnable and losable" (the pin's text calls `>= 8` the fix).

**What the build loop did:** the pin's value follows the measurement (`TUTORIAL_RAID_CLEARS_AS_MEASURED
:= 1`, with the history in its comment and `cleared < 8` asserted beside it), because a gate that is
red for a reason no loop may fix stops all work (LESSONS.md), and 0.5 was NOT moved to restore 0/20 —
that would have been tuning a canon-driven number to a pin. Adventure 0's pin (>= 18/20) is unchanged.

**The question for the designer:** the Tutorial Raid's swing/mechanic ruling (audit `M6-BAL-03`) and
the tutorial mistake rate are now coupled — a designer re-pricing TR's swing "with the multiplier
included" should do it at the reduced rate the fight will actually be played at, and may want to name
the rate at the same time (`build/plan/ship/00-plan.md` §6 rows #1, #9 and #57). No recommendation on the swing;
the 0.5 stands until ruled.

---

<a id="bl-92"></a>
### BL-92 - Adventure 0's scripted mistake: who, how, and how bad *(🔷 PROPOSED - implemented)*

**Owner:** [10 §9.1](./10-content-and-encounters.md) - **Signal:** Silent - the field existed on the record and the validator for a wave, and nothing in the sim read it

Promoted from `build/plan/q-W5-SIM.md` (W5-SIM, wave 5; audit `m6-mech-arms-register`, SIM-27).

10 §9.1: "Adventure 0 scripts one guaranteed mistake on round 3 regardless of morale rolls ... a
content-level override flag on the encounter record (`force_mistake_round: 3`), and it exists on
exactly one encounter in the game." The doc fixes the round and the guarantee and leaves three things
open. **Decision, three parts.** (1) **The gate is skipped, not weighted.** `Mistakes.force()` builds
the event from the ordinary path AFTER the gate — the same eligible set (the tutorial bans included),
the same class-weighted draw, the same event shape — and never rolls the chance; that is what
"regardless" means, and it is why [BL-90](#bl-90)'s halved rate has nothing to suppress. (2) **The
raider is drawn from the seeded Rng** (`rng.derive("forced_mistake", round_no, 0)`, its own channel)
out of the living non-tank raiders who act in the tank/DPS phases, chosen after the boss has swung so
the pick is somebody still standing; the tank is the fallback when nobody else can act, because a
scripted mistake that quietly does not happen is the one outcome the flag exists to rule out. The
audit's alternative — the highest-morale non-tank, "even your best is bad" — was not taken: it makes
the same raider fail on every seed, which reads as a targeted script rather than as the roster being
bad. (3) **Minor, at the type's floor.** "A tutorial demonstrates a fail state, it does not impose
one" (10 §9.1): the draw prefers types whose band reaches Minor and lands at Minor; when none is
eligible it falls back to the whole set at each type's own floor. The type's tokens are emitted as
they would be organically.

Held by `tests/unit/test_mistakes.gd` (fires 40/40 at a 95-morale Legendary inside a tutorial context;
Minor at the floor for every class/role; deterministic; a cooldown narrows the pool and never empties
it) and `tests/unit/test_tutorials.gd` (20 seeds on A0 with the squad the game hands you: a MISTAKE
entry on round 3 and `mistake_count >= 1` on every seed; replay-identical; the Tutorial Raid and the
real rungs never script one). `sim/model/Encounter.gd`'s validator (negative, or past `target_rounds`)
was already in the tree. `RaidSim._pick_forced_mistake_slot` and `Mistakes.force()` cite this entry.

---

<a id="bl-93"></a>
### BL-93 - Frontal Cleave's "in front of the boss" is the one melee predicate, Bard included *(🔷 PROPOSED - already implemented; written down on request)*

**Owner:** [10 §10 M11](./10-content-and-encounters.md) / [07 §5.2 row 1](./07-combat-simulation.md) - **Signal:** Silent - the predicate was chosen in code and recorded only in a plan file

Promoted from `build/plan/q-W5-SIM.md` (W5-SIM, wave 5; audit `m6-mech-arms-register`, SIM-27).

M11 is "`X` damage to all melee-positioned raiders each round", stressing "Rogue, Monk, Warrior". The
sim has no positions ([BL-82](#bl-82)). **"Melee-positioned" is `Consumables.MELEE_CLASSES` —
Warrior, Monk, Rogue, Bard — the one melee predicate the tree already uses for the Whetstone Kit,
M03's zone demand and M05's interrupters**, so four mechanics and a consumable can never disagree
about who stands in front. The tank is included ([BL-88](#bl-88)). The Bard is included by the shared
predicate rather than by the row's own list; if a designer wants the Bard out of the front, that is a
change to `MELEE_CLASSES` and moves the kit and two other mechanics with it, which is the point of one
predicate. Armour applies (a cleave the plate tank shrugs off is what plate is for); the AC bypass
stays M02's alone.

Held by `tests/unit/test_raid_sim.gd::test_m11_hits_the_melee_and_only_the_melee` and
`tests/unit/test_mechanics_arms.gd` (every living melee raider is cleaved on round 1, one line per
round, nobody outside the predicate ever is, and an encounter without m11 carries no trace of it).

---

<a id="bl-94"></a>
### BL-94 - The recruit price is doc 11's table, behind `Recruitment.PRICE_SCALE` *(DECIDED - Q-60's own default, landed; doc 04's scale kept selectable)*

**Owner:** [11 §4.2 S1, §12.1 R3](./11-economy-and-crafting.md) / [Q-60](#q-60) - **Signal:** Loud - a new guild's 60 G bought exactly one Common and nothing else

Landed by W6-LEDGER (wave 6; LOOP-19, CRITIC-C7; `build/plan/ship/00-plan.md` §6 row #63). Not a canon number:
both scales are 🔷 PROPOSED and [Q-60](#q-60)'s recorded default already says "Doc 11 §4.2's scale is
authoritative; docs 04 and 13 render it". The tree had shipped doc 04 §3.3's `[60, 180, 450, 1100,
3000]` with no switch, so a fresh guild's 60 G (doc 01 §8.0, sized against a 15 G Common) bought one
recruit; the designer's page was about to be asked to cost levers in that arithmetic (CRITIC-C7).

**`Recruitment.PRICE_SCALE := "doc11"`** selects `[15, 60, 160, 420, 1000]`; `"doc04"` keeps the
old table selectable, and both are in `Recruitment.COST_BASES`. Doc 04's content-tier multiplier
(`× (1 + 0.6 × (CT − 1))`, rounded to 10) is unchanged and applies to either. Recorded, not moved:
the 60 G starting purse (doc 01 §8.0) now buys four Commons, which is what the ship plan's solvency
and BAL-04 arithmetic quote; the Q-29 gear surcharge ([ship plan §6 row #7](#q-29)) is a later
multiplier on the same `cost_of()` and lands in W8-ITEMS.

Held by `tests/unit/test_recruitment.gd`: the doc-11 table cell by cell at CT 1/3/5, doc 04's table
still reproduced under its own key, and **doc 11 §12.1 R3** as a test — for every rarity,
`cost_of(rarity, 1) >= 1.5 × the sale value of the arrival kit` with the kit priced at its WORST case
(every granted slot the dearest item of the plan's source at Tier 1, every fill slot the dearest of
the fill source, sold at the best sell rate) — so a future price change cannot reopen the
recruit-gear arbitrage. `tools/playtest.gd`'s solvency floor reads `cost_of()`, so it moved with the
table by construction (`tests/unit/test_playtest_invariants.gd`).

---

<a id="bl-95"></a>
### BL-95 - Retreat is struck: the attempt is committed at Depart, and leaving early is Skip *(CONFIRMED — struck; docs amended 2026-09-15 (W7-DOCS))*

**Owner:** [07 §3, §7.3](./07-combat-simulation.md) / [01 §6](./01-core-loop.md) / [Q-09](#q-09) - **Signal:** Silent - a doc verb with no button, no outcome and no way to exist

Recorded by W6-LEDGER (CRITIC-M2; `build/plan/ship/00-plan.md` §6 row #51). Doc 07 §3 says "Retreat is
separate and always available: the player may abandon the attempt at any phase boundary"; §7.3 lists
"Player Retreat → Abandoned attempt, not a wipe"; [Q-09](#q-09) calls Retreat "the sole exception".
The tree has no button and no outcome (`grep -rn -i retreat sim/core game/screens game/core` = two
comments), and it cannot have one: the attempt is resolved in full and recorded before RaidView plays
a line ([Q-53](#q-53)'s default, as built), so "abandon at a phase boundary" would need an
incremental sim, which BUILD_STATE invariant 2 and Q-53's stronger reading rule out.

**Ruling: Retreat is struck.** The attempt is committed at Depart; leaving the account early is
"Skip to the end", never Retreat, and costs what the attempt costs. W7-DOCS amends doc 07 §3 and the
§7.3 outcome row, and doc 01 §6's cost table if it prices a retreat; Q-09's "sole exception" sentence
reads as history. No code. If the designer wants a retreat, it is a whole-attempt action taken at
Depart's prep board (a "don't go") and not a mid-fight verb.


**CONFIRMED (2026-09-15).** Retreat stays struck: the attempt is committed at Depart (Q-53), so there is no phase boundary at which to abandon it and no mid-fight verb (Q-09); leaving the account early is Skip or an exit; the whole-attempt "don't go" is the prep board's Back. Applied: docs/07 §3's sentence now reads "There is no retreat: the attempt is committed at Depart; the prep board's Back is the only 'don't go'", the §7.3 outcome row "Player Retreat → Abandoned attempt" is struck, docs/13 §5 S11 lost "retreat" (and the Calls), docs/01 §6's table prices no retreat (its retry fee is struck under Q-53), and Q-09's "sole exception" carries "(historical: struck by BL-95)" — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-96"></a>
### BL-96 - Traits are post-1.0; the field stays serialised and empty *(CONFIRMED — traits are post-1.0; docs/04 §10 and docs/14 §5 marked (2026-09-15))*

**Owner:** [04 §10](./04-recruitment-and-roster.md) - **Signal:** Silent - a field with a name and nothing that fills or reads it

Recorded by W6-LEDGER (CRITIC-M3; `build/plan/ship/00-plan.md` §6 row #50, §7.1). Doc 04 §10 tables six
mechanical traits (`slow_learner`, `clutch`, `expensive`, `cheap_date`, `fragile_ego`,
`iron_stomach`, 0-2 per raider), 🔷 PROPOSED and on no cut list; `sim/model/Raider.gd` carries
`var traits: Array = []` serialised in `to_dict()`, and nothing generates, applies or prints one.

**Ruling: cut for 1.0.** A sixth axis on recruits while the recruit price scale ([BL-94](#bl-94)),
the Q-29 surcharge and the BIG-dumb counters ([BL-59](#bl-59)) are still settling would be tuned
against numbers that are about to move. The field stays serialised and empty so no save migration is
owed when it lands. If the designer says "yes" (one word on the page): M — `Recruitment.generate()`
rolls 0-2 by rarity, `Mistakes._situational_bp` reads `slow_learner` / `clutch`, `cost_of` reads
`expensive`, `Comfort` reads `cheap_date`, the backstory weights read the ego pair, one line on the
Tavern card and RaiderDetail — wave 9 at the earliest.


**Confirmed (2026-09-15).** The designer's texture axis for a raider is the backstory bullet (Pillar 3); the fight's inputs are rarity and morale; four of the six traits are bullets wearing a mechanic and the two that touch the fight are a sixth axis on a card already reading five things; `Raider.traits` stays serialised and empty; docs/04 §10 and docs/14 §5's row are marked post-1.0; no code behind a flag — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-97"></a>
### BL-97 - S13 and S16 are struck from doc 13 §5, the Codex key goes with them, and the list-screen sort row is struck *(CONFIRMED — S13 struck, S16 out of 1.0, `F1` / `nav_codex` deleted in W8-KEYS; docs amended 2026-09-15)*

**Owner:** [13 §5, §13.1](./13-ui-ux.md) / [16 C4](./16-production-roadmap.md) / [BL-24](#bl-24) - **Signal:** Silent - two screens in the inventory with no state to show and a key bound to nothing

Recorded by W6-LEDGER (CRITIC-M4, CRITIC-C13, SHIP-07/-20; `build/plan/ship/00-plan.md` §6 row #64, §7.1).
Doc 13 §5 lists S13 (the encounter interstitial: "HP/mana carry-over, swap-ins, continue or bank") and
S16 (the Codex), both 🔷 PROPOSED; §13.1 binds `F1` to the Codex and `1`-`4` to a sort on the list
screens; `project.godot` binds `nav_codex` and `ScreenRouter.CODEX_SCENE` does not exist.

**Ruling: both screens struck, with their reasons.** S13: [BL-24](#bl-24) runs the raid one
encounter per rung, so there is no between-encounter state to carry, bank or swap. S16: doc 16 C4
sanctions the Codex cut, and the two questions a codex answers already have homes — "who can wear
this" is the Market's compare tooltip and the Records tab, "what does this mechanic do" is the prep
board's risk readout. `F1` / `nav_codex` are deleted (W8-KEYS). **The `1`-`4` sort row on list
screens is struck too** (SHIP-07): no sort mode exists on Roster, Tavern or Market to bind, and
building one for a key is the wrong order; `1`-`4` stay the raid speeds on RaidView, Space is pause,
Q/E step the subject on RaiderDetail, F cycles the Records filter — the surviving rows are audit
`M6-A11Y-01`'s re-scoped list. W7-DOCS strikes the two §5 rows and the two §13.1 rows.


**CONFIRMED (2026-09-15).** S13 struck outright (one rung is one encounter — [BL-24](#bl-24)); S16 out of 1.0 and revisited only if Tiers 2-5 ship item families the Market's compare tooltip and the paper-doll cannot explain; `F1` / `nav_codex` deleted from `project.godot` and `ScreenRouter.codex()` / `CODEX_SCENE` removed in W8-KEYS, not left inert; the `1`-`4` sort row on list screens and the list-screen filter row struck; the map that ships is Space pause and `1`-`4` speeds on RaidView (respecting `_skip_unlocked`), Q/E on RaiderDetail, F on the Records filter, Esc back — every other control is Tab-reachable. docs/13 §5's S13 / S16 rows carry "struck (BL-97)", §13.1's F1 and sort rows are struck, §13.2's Codex binding is gone — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-98"></a>
### BL-98 - Wishlists are out of 1.0; the flag stays declared off and no screen mentions them *(CONFIRMED — wishlists out of 1.0; Q59-3 closes as cut (2026-09-15))*

**Owner:** [05 §11 (Q-70)](./05-morale.md) / [09](./09-items-and-itemization.md) / [16 C3](./16-production-roadmap.md) / audit Q59-3 - **Signal:** Silent - a leaf module named on a player-facing screen and built nowhere

Recorded by W6-LEDGER (CRITIC-C16, CONTENT-19, LOOP-17, SIM-21; `build/plan/ship/00-plan.md` §6 row #59,
§7.1). `GameState.FLAG_DEFAULTS.wishlists = false`; the BIG-dumb condition that reads it (Q59-3)
is declared and inert; RaiderDetail printed "wishlists with the loot module" to the player (hidden by
W6-COPY). Doc 16 C3 sanctions the cut.

**Ruling: out of 1.0.** The wishlist generator (SIM-21's L) is post-ship; the flag stays declared
off so a save that ever carries the field loads; no screen names the module; audit `Q59-3` closes on
this entry as cut, and BIG-dumb ships on the conditions [BL-59](#bl-59) lists as live. If the
designer wants them in (one word on the page), it is W9's conditional slot at the earliest and needs
doc 05 §11's rules signed first.


**Confirmed (2026-09-15).** Canon calls them "just concepts"; the 1.0 loot decision is Q-11's Master Looter, whose per-raider stat delta is the game knowing each raider's best-in-slot for the player; the flag stays declared off, `Raider.wishlist` serialised, the four authored morale rows unreachable data, BIG-dumb condition #3 declared and inert while 1, 2 and 4 ship live; docs/09 §14.3 and docs/11 §6.3 tagged post-1.0 (`build/plan/handoff-W7-DOCS.md`); Q59-3 closes as cut — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-99"></a>
### BL-99 - Doc 06's four PROPOSED class kits are post-1.0 unless the designer names them; no code ships behind `false` *(DECIDED — three of doc 06's four kits ship in canon-line shape (W9-KITS); the Wizard Ramp stays post-1.0)*

**Owner:** [06 §4.6-4.8](./06-classes-and-roles.md) / [Q-46](#q-46) / [Q-57](#q-57) / [Q-58](#q-58) - **Signal:** Silent - nine classes that function and differ, and four rule sets nobody signed

Recorded by W6-LEDGER (SIM-10, CRITIC-C17; `build/plan/ship/00-plan.md` §6 row #52, §7.1; audit
`m6-kit-proposed`, `m6-kit-bard`). Doc 06's Wizard ramp, Rogue Behind/Front, Monk Guard and Mage
raid buff are 🔷 with no DECIDED row; each is an afternoon and each moves the sweep; every class
functions and differs today through its stats, role and mistake weights.

**Ruling: the four are post-1.0 unless the page names them.** Nothing ships behind a `false` switch
for a kit that was never signed — a half-built kit is exactly what BUILD_STATE invariant 5 forbids.
The three DECIDED rules are different and DO land: Lost Aggro + Taunt / `should_retarget` ([Q-57](#q-57))
and healer threat ([Q-58](#q-58)) in W7-SIM-EFFECTS, the Bard's songs as [Q-46](#q-46) tables them
(`S = 1 + floor(Mana / 10)`, behind `Formulas.BARD_S_DIVISOR = 10`) and the Rogue's extra swings
(`Formulas.DAGGER_SWINGS = 2`, [Q-36](#q-36)'s recommended default) in W9-KITS, each with the wave's
one golden regeneration. A named PROPOSED kit is built fully in W9-KITS (M each) with its own entry.


**Amended (2026-09-15): three of doc 06's four kits are DECIDED in the shape canon's own class line requires and no wider (W9-KITS, L−).** Monk Guard (canon "emergency tank"): `Combatant.in_guard`, evaluated at Round Open — on when the Monk holds a tank flag at setup or when no Warrior is Alive and stable (Tank Lead 1.30, W7's `should_retarget`), off when one is; on entry a Taunt (1.10 × current highest); `GUARD_THREAT_COEF 3.0`, `GUARD_AC_BONUS +7` (the canon Warrior Shield's 7, the piece a Monk cannot carry; Monk Adventure 14 + 7 = 21 = docs/10 §5.4's E4 tank AC), `GUARD_DAMAGE_MULT 0.5`, one Story line each way ("{actor} drops into Guard. Somebody had to."); a Guard Monk counts as tanking for M09/M11/M01's holder rule and is never M01's partner (docs/06 §4.6). Rogue Front (canon "position-dependent"): `ROGUE_FRONT_MULT 0.77` in `_outgoing_damage` while the Rogue is the raider the boss targeted this round (organic threat, MIS_AGGRO, M08 Fixate), otherwise 1.0 — docs/08 §8.2's default, so no clean-run number moves; a Behind bonus of even 1.05 would put the Rogue over the Wizard at Boss 5. Mage Raid Spell Buff (canon phrase): `MAGE_RAID_BUFF +2` spell damage per cast to every Mage and Wizard while any Mage `is_alive()`, once regardless of Mage count; the Bard's Hymn of Focus stacks on top (≈ +2-3 % raid DPS). The Wizard Ramp stays post-1.0: canon's "Very high single-target DPS" is the 1.60 coefficient already and a five-stack ramp is a borrowing the notes never asked for. The Bard sings as Q-46 tables it — `BARD_S_DIVISOR = 10`, `data/classes.json` song params, the d6 on seeded channel `song`, the d4 Wrong Song on a Bard action mistake, Drinking Song as `relief_bp 300`, Discord through the retarget path, the Loud Solo through `add_threat` — with the canon Charm of Mana (+10) as its Tier 1 Mana (S = 2; 3 with the Instrument; 4 with both). Panicked Stance, Overpull and Faced-the-Boss are not built. `test_class_kits.gd` one test per rule; the wave's one regeneration; if W9-KITS must trim, the Mage buff moves to W10-BUFFER and Guard and Front do not move; docs/06 §4.5-4.7 amended to the built shapes, §4.8 stays 🔷 post-1.0 — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-100"></a>
### BL-100 - Tiers 2-5 share the two arenas and the boss set; per-tier visual identity is post-1.0 *(CONFIRMED — stands, now visible for four tiers (2026-09-15))*

**Owner:** [10 §8, §12.3](./10-content-and-encounters.md) / [16 W3.3, W3.6](./16-production-roadmap.md) / [Q-96](#q-96) - **Signal:** Silent - five tiers, one arena per kind, one boss set, one palette

Recorded by W6-LEDGER (CONTENT-26's art half, CRITIC-C15; `build/plan/ship/00-plan.md` §7.1). Two bare arena
plates exist (cave, dungeon) and one boss/trash sprite set; encounter records carry no visual
identity; doc 16 W3.3/W3.6's per-tier arenas, boss recolours and icon palettes are the one XL art line
no report sizes.

**Ruling: one arena per KIND ships** — `SceneStage.arena_for(encounter)` = the tier's `scene` if
`data/tier_words.json`'s tier row names one, else the kind rule ([Q-96](#q-96)'s default: Adventures
and the tutorials in the cave, the raid in the dungeon), landed by W7-STAGE. Tiers 2-5 reuse the
Tier 1 boss set; per-tier recolours and a third arena are post-1.0, and the `scene` key on the tier
row is where the answer goes when it is authored. If Tier 1 ships alone (§6 row #2's default) the
question is moot for 1.0.


**Stands (2026-09-15)**, now visible for four tiers: tiers 2-5 share the two arenas by kind ([Q-96](#q-96)), the Tier 1 boss set and one icon palette; per-tier plates, recolours and palettes are post-1.0 and land through `tier_words.json`'s `scene` key when painted; a `modulate` re-hue of a boss was tried and rejected (PIPE-16) and a tinted boss is the palette-swap the game parodies — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-101"></a>
### BL-101 - Placeholder names ship: the display name only, never the kind as a name *(CONFIRMED — stands for trash, the ladder and the log; the boss plate carries BL-119's title (2026-09-15))*

**Owner:** [10 §2, §8](./10-content-and-encounters.md) / [Q-84](#q-84) / [C-19](#7-canon-ambiguities-to-confirm) - **Signal:** Silent - "Main Boss" was the boss's only name on the prep board and in the fight

Recorded by W6-LEDGER (LOOP C24, CONTENT-28, DESIGNER-25; `build/plan/ship/00-plan.md` §6 row #25, §7.1).
Doc 10 §2 forbids inventing lore names; `data/encounters_t1.json` names its records "Raid 1 —
Encounter N"; the prep card and the boss plate printed the KIND ("Main Boss") as if it were a name.

**Ruling: the placeholders are canon's own words and ship as they are**, and the kind is a kind. The
prep card's sub-line and the boss plate print the encounter's `display_name` only (W6-AUD-BIND and
W6-LOG apply the two lines in wave 6); the vocabulary is "Encounter N" in the UI and "Boss N" only
inside the loot tables' `boss` key (as built). If the designer lists creature or encounter names on
the page, they are `title` data on the records (W8-ITEMS) and nothing else moves. The tutorial
trinkets keep doc 09's template names ("Cracked Charm of Power / Health") over doc 01's joke names
unless the page says otherwise.


**Amended (2026-09-15):** stands for trash rungs, the ladder words and every enemy log name; the boss rungs' plate carries [BL-119](#bl-119)'s role title above the placeholder — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-102"></a>
### BL-102 - The town has one plate and rank dressings; three or six plates are the designer's, post-1.0 *(DECIDED — the six dressings are a table (W8-FACILITY ranks 0-3, W9-ART ranks 4-5); docs/02 §9.1 rewritten 2026-09-15)*

**Owner:** [02 §2.1 R5, §9.1](./02-town-and-buildings.md) / [03 §5.4](./03-guild-reputation.md) - **Signal:** Silent - six documented town states, one plate

Recorded by W6-LEDGER (M3-LOOP-06, DESIGNER-22/-24, UI-40; `build/plan/ship/00-plan.md` §6 rows #22 and
#24, §7.1). Doc 02 §9.1 specifies six rank states ("Guildhall boarded, 3 idle townsfolk" →
"statue of the guild, 26 townsfolk, stained glass and a tower") and §2.1 R5 makes them acceptance
criteria; the reference concepts set the bar (memory: reference-concepts-are-a-standard), so five
more plates at that bar are the designer's to supply, not the loop's to approximate.

**Ruling: ONE plate plus additive rank dressings derived from the plate's own pixels** — the
mechanism W4-LIFE built (`stage_camp.json` prop layers gated on rank: fewer walkers and a boarded
tent at Unknown, the shipped scene at Known/Respected, more walkers, banners and a statue prop at
Renowned/Legendary if a sheet has one) plus the four Guildhall tent states (W8-FACILITY). Doc 02 §9.1
is amended 🔷 to "one plate, six dressings" and R5 restated as "the town visibly changes at every
rank" (props count). The aerial `stage_town` stays an establishing shot with motion and no figures
(a person on that street is 10-14 px; every strip we own is 21-48 px). Three or six painted plates
and an aerial figure sheet are the designer's, post-1.0, and the page asks.


**Amended (2026-09-15): the six dressings are a table.** Every layer gated `rank >= N` in `stage_camp.json`, props cut from the plate's or the sheets' own pixels, never painted: **0 Unknown** 0 walkers, 6 lantern flames, the two shipped banner props hidden · **1 Known** 1 walker, 8 flames, the banners return and one cloth pennant on a pole beside the Board callout (never on the tent — the tent's cloth banner is facility L2's) · **2 Respected** 2 walkers (the shipped scene), 10 flames, a notice post beside the Board callout, the pennant takes the crest colour · **3 Established** 3 walkers, 10, a cobble band on the main path (`patch_plate.py`) and a pennant line of 5 between the two big tents · **4 Renowned** 4 walkers, 10 + 2 brazier flames (`fire_camp` at 1x), a stone statue (one idle warrior frame, desaturated, on a 24×10 plinth) in the square · **5 Legendary** 5 walkers, 10 + 4 braziers, a second guild tent (a patch copy), two `knight_unlabelled` guards flanking it, crest pennants on all four tents. Ranks 0-3 in W8-FACILITY; ranks 4-5 in W9-ART (it owns `stage_camp.json` in wave 9). Every rank adds ≥ 3 deltas (docs/02 §2.1 R2) and a rank is readable from a screenshot (R5); docs/02 §9.1 is rewritten to this table under "one plate, six dressings" with the six painted states kept below as the post-1.0 plate brief; `test_scene_stage.gd` asserts rank 0..5 shows exactly the table — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-103"></a>
### BL-103 - 1.0 ships the party at 2x integer scale and the boss at 1x in front of the fence; the 2x-canvas re-author is post-1.0 unless commissioned *(DECIDED — the party AND every enemy at 2x integer scale on both arenas (`marks.boss.scale` 2, W7-STAGE); the re-author is post-1.0)*

**Owner:** [12 §3.3, §4.1](./12-art-direction.md) / art plan Q01, Q02 - **Signal:** Silent - the boss reads as a different medium from the party

Recorded by W6-LEDGER (UI-21/-22, DESIGNER-26/-27; `build/plan/ship/00-plan.md` §6 rows #26 and #27, §7.1).
`figure_scale` is 2 on the camp and both arenas and 1 on the tavern and market (the plates' own props
set the numbers); `marks.boss.scale` is 1, and doc 12 §4.1 warns 2x "reads as chunky"; the reference's
boss is ~580 px on the 1536 frame.

**Ruling for 1.0:** the boss stays 1x on its own floor and is moved IN FRONT of the fence with the
party spread at the built scale (W7-STAGE); `marks.boss.scale` goes to 2 on the main and mini boss
ONLY if the designer writes "upscale ok" on the page, never silently. A re-author of the seven Tier 1
boss/trash sprites at ~300 px, or of the party families on a 2x canvas, is an XL art unit and is
post-1.0 unless commissioned; the tavern's 1.5x exception is one integer per scene JSON if asked.


**Amended (2026-09-15): 1.0 ships the party AND every enemy at 2x integer scale on both arenas.** `marks.boss.scale = 2` in `stage_arena_cave.json` and `stage_arena_dungeon.json` for every enemy rank (main, mini, elite, trash and the `_2` variants): the Main Boss stands 262 px (155×131 at 2x), the Mini Boss 210, the stone brute 330, the elite 182, trash 164, beside 62-96 px raiders — Octopath's proportion (≈ 3.2× a raider), not the mockup's 6×; one pixel pitch on the floor, which is what closes the seam UI-22 measured ("the party is crunchier than its enemy"); spec 07 A1's "chunky" warning had 1:1 raiders as its premise and the raiders are 2x. The delegation is the "upscale ok" the row was waiting for. `place_boss()` already scales the contact shadow and `boss_feet_y()` the plate clearance; the boss mark's x moves so a 2x footprint (up to 400 px wide) clears the front rank by ≥ 24 px and the lantern entirely; `test_scene_stage.gd:602` reads `Vector2(2, 2)` from the mark; damage numbers and `head_of(boss)` follow the frame rect. `figure_scale` stays 2 on the camp and both arenas and 1 on the tavern and market — the tavern takes no 1.5x exception (a non-integer shimmers under nearest and blurs under linear); the tavern speaker's plate is sized to the 1x figure (UI-07). The 2x-canvas re-author of the four party families and six enemies at painted density is post-1.0 and a person's; spec 00 §2.7's `marks.boss.scale` row: default 2, the other branch 1 — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-104"></a>
### BL-104 - Two gates stay records rather than bars: region-masked art scoring is not required to ship, and the latency stage stays WARN with its budget stated *(CONFIRMED — recorded; the README's budget line says "measured on the second machine" (2026-09-15))*

**Owner:** [13 §12.1](./13-ui-ux.md) / [14 §11](./14-technical-architecture.md) / audit m4t-06, M6-JUICE-07 - **Signal:** Silent

Recorded by W6-LEDGER (UI bar #10, UI-45, SHIP-09; `build/plan/ship/00-plan.md` §7.1). **The art gate is a
no-regression record, not a resemblance bar.** `tools/diff_all.sh`'s whole-screen numbers are the
record a unit compares before/after; the region-masked per-component scoring audit `m4t-06` proposed
would measure resemblance to mockups the design has already been ruled to outrank
(memory: reference-concepts-are-a-standard; the plates are bare by the designer's 2026-09-11
directive). Closed as not required to ship. **Stage 8 (the latency probe) stays WARN**, on the
playtest's precedent: the reference laptop's clock varies ~5x between boosting and base, so a FAIL
would be a coin toss. The budget is STATED instead, where a reviewer reads it — BUILD_STATE's build
status and README's stage table: mount ≤ 140 ms warm, frame ≤ 16.6 ms, on the reference laptop
boosting (calibration loop ≤ 10 ms); PERF OK on all 14 screens at the wave-5 close — and the
second-machine run at the native window is audit `M6-FINAL-05` (W10-WALK).


**Confirmed (2026-09-15)**, with one sentence: README's budget line reads "mount ≤ 140 ms warm, frame ≤ 16.6 ms, calibration loop ≤ 10 ms, on the reference laptop boosting — measured on the second machine at the native window (W10-WALK)", so WARN is never read as "not measured"; `test_perf_mount.gd`'s cache invariants are the FAIL that exists; docs/14 §11 carries the budget — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-105"></a>
### BL-105 - Instrumentation (doc 14 §12) is post-ship *(CONFIRMED — post-ship; docs/14 §12 carries its status line (2026-09-15))*

**Owner:** [14 §12](./14-technical-architecture.md) / [Q-93](#q-93) - **Signal:** Silent

Recorded by W6-LEDGER (CRITIC-M7; `build/plan/ship/00-plan.md` §7.1). Doc 14 §12's `--instrument` launch
flag and JSONL run logs under `user://analytics/` are off in release by design ([Q-93](#q-93)) and
no producer exists (`grep -rn "analytics\|instrument" game/ tools/*.gd` = nothing). SHIP-16's
file logging is the player-side crash log and is separate. Nothing for 1.0; post-ship, doc 14 §12.


**Confirmed (2026-09-15)**; docs/14 §12 gains the status line "🔷 PROPOSED, post-1.0; nothing under `game/` produces these events; the balance harness (§9.3) is the shipped instrument"; the only file the shipped game writes about itself is Godot's crash log (`debug/file_logging`, five files) — docs/00 §6.1's "no telemetry-driven tuning" — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-106"></a>
### BL-106 - A role-based VFX default, a global light, eight state glyphs and one figure per class ship; per-class families, normals, further glyphs and per-rarity figures are post-1.0 *(DECIDED — as built, with b, c, e, j, k added (2026-09-15): `Icons.WARRIOR_GLYPH = "shield"` (W9-ART), the tent's four states (W8-FACILITY), `FUMBLE_BY_SEVERITY`, the Raid Group tab retired (W10-DELETE))*

**Owner:** [12 §5](./12-art-direction.md) / [Q-74](#q-74), [Q-75](#q-75) / art plan Q18 d, f, h, i - **Signal:** Silent

Recorded by W6-LEDGER (DESIGNER-42, PIPE-02/07/16, STAGE-17; `build/plan/ship/00-plan.md` §6 row #42,
§7.1). The role-based attack/support VFX families landed in W3-RAIDVIEW2; a re-hue of the class
busts and figures was tried and rejected (HALL-06 / PIPE-16); the eight log/state glyphs exist;
[Q-75](#q-75)'s own fallback is a global baked light direction.

**Ruling: as built for 1.0.** One figure per class (drawn variants only where a sheet has them; no
re-hue), a global light (normals only if a single class prototype shows an obvious gain at 1440p),
no further state glyphs (the log line carries the rest), the role-based VFX default. The fumble
flavours W9-ART draws first are trip / drop weapon / wrong target — the three the log's Minor /
Moderate / Severe lines describe most. Per-class VFX, normals, more glyphs and per-rarity figures are
1.1 art units; the page's row #42 is where the designer edits the list.


**Amended (2026-09-15): b, c, e, j, k added.** **b** `Icons.WARRIOR_GLYPH = "shield"` — the Warrior's whole identity in canon is the shield (the matrix's only one), the badge exists so the player finds the two tanks at a glance, and a tank badge that says "swords" says DPS; Octopath's job icons name the role; the asset exists beside the swords; `test_icons.gd:122` asserts "shield" (W9-ART). **c** the guild tent is the guildhall with four states (L1 the patched tent · L2 + a cloth banner · L3 + a second tent and a lantern ring · L4 + a painted sign) and the camp dresses per rank as [BL-102](#bl-102)'s table (W8-FACILITY). **e** `FUMBLE_BY_SEVERITY = {MINOR: "trip", MODERATE: "drop", SEVERE: "wrong_target", CRITICAL: "wrong_target"}` on three `fumble_*` frames (W9-ART). **j** the Raid Group tab is retired, not rebuilt as a read-only view or a "Chalked" filter — RaidPrep's strip is the raid group and the only truth about who is going tonight; the escape hatch is closed; W10-DELETE removes the `raid_group` remnants and retargets `test_roster_layout.gd:296,:319`, `test_starting_roster.gd:224`. **k** the party bodies stay at the sliced reference density (the bosses upscale — [BL-103](#bl-103)). a, d, f, h, i as built; the nine Legendary busts are a named pass through `derive_busts.py`, not a rarity re-hue, and are not barred by d — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-107"></a>
### BL-107 - The wipe's culprit is the last Severe-or-worse mistake before the first tank or healer death, else the deepest cascade, else nobody; the −4 is queued by the sim and applied by the game *(DECIDED - the rule as built stands; `WIPE_CULPRIT_DELTA = -4` (2026-09-15))*

**Owner:** [01 §6.1, §6.4](./01-core-loop.md) / [07 §6](./07-combat-simulation.md) / [05 §7.1](./05-morale.md) - **Signal:** Silent - doc 01 names the number and never defines "the raider whose mistake triggered the wipe"

Doc 01 §6.1 gives "an extra −4 to the raider whose mistake triggered the wipe" and §6.4 wants a
post-mortem "naming the raider at fault, the specific mistake". `Morale.TRIGGERS["wipe_caused"]`
has carried the −4 since the morale ledger landed and nothing ever named a raider, because no
document says which mistake "triggered" a wipe. LOOP-12 proposed the rule; CRITIC-C12 put it in the
sim's cascade unit so the report reads a field that exists.

**Taken (W6-SIM-CASCADE, `sim/core/RaidSim.gd` `_wipe_cause`, `WIPE_CULPRIT_DELTA := -4`):** on any
loss (wipe, soft wipe, attrition) the sim names ONE log entry —

1. the LAST mistake of severity Severe or Critical logged before the first tank or healer is
   confirmed Dead ("Severe" reads as Severe-or-worse: a Critical is a worse Severe);
2. else the mistake with the deepest `cascade_depth` (ties to the later one);
3. else nobody — `wipe_cause` is empty, the verdict line stands alone, and the report is expected to
   say the boss simply won.

`SimResult.wipe_cause = {actor_id, mistake_type, round, entry_seq}`; the log's last Story line on a
loss is `wipe_cause` ("It traces back to Cindy — Healed a Corpse, round 4."); the culprit's entry in
`deltas_queued` carries `wipe_caused: 1`. The sim REPORTS (doc 14 OQ-10): `game/` fires the ledger's
`wipe_caused` trigger from that flag (W7-REPORT), and `tests/unit/test_raid_sim.gd` pins
`WIPE_CULPRIT_DELTA` equal to the trigger's delta so the number lives in one place.

**Also taken here, doc 07 §6 rule 1's parent when several tokens are live (SIM-05's default):** the
live token whose "Effect on later rolls" column names THIS roll — the actor's Fire/Adds for
`MIS_AVOIDABLE_DEATH`, the raid's Aggro for a healer's roll, the raid's Distraction for an ambient
roll — else the OLDEST live token on the actor, else the mistake is a root. Only the actor's own
tokens count in the fallback: a raid-wide fallback would put every miserable raid at depth 3 and,
through the depth cap, stop most tokens from being emitted. A Downed holder's token still counts
(§6's worked cascade gives Cindy her +8pp in the round Greg drops); a Dead holder's does not.

**Alternatives** (for the designer, ship plan §6): (a) the FIRST Severe of the fight rather than the
last before the death — blames the opening of the slide instead of its last step; (b) the mistake
with the most descendants — needs a graph walk and reads the same as (2) in practice; (c) the
raider who died first — a consequence, not a mistake, and often the tank taking a boss swing.


**🔷 → DECIDED (2026-09-15).** The rule as W6-SIM-CASCADE built it stands: the last Severe-or-worse mistake logged before the first tank or healer is confirmed Dead; else the mistake with the deepest cascade depth (ties to the later one); else nobody — "Nobody in particular. The boss simply won." — the honest line and the DPS-check signal; `WIPE_CULPRIT_DELTA = -4` = `Morale.TRIGGERS["wipe_caused"]` once per attempt session (a test pins them equal), on top of the wipe's −8, so the culprit takes −12; the blame is the comedy, and [BL-116](#bl-116)'s round-1 Critical is its best case — ruled by the loop under the designer's 2026-09-15 delegation.
---

<a id="bl-108"></a>
### BL-108 - spec 02 §2.1's "a row never wraps" is the LIVE log's ordinary rows only *(DECIDED - implemented; spec 02 §2.1 amended)*

Promoted from `build/plan/q-W6-LOG.md` (W6-LOG, wave 6; numbered by W6-LEDGER).

**Owner:** art/ref/specs/02 §2.1 / docs/13 §11.3-§11.4 - **Signal:** Loud; the mistake's name and the joke were the two things the log and the report cut

Spec 02 §2.1 measured "longer rows ellipsize, never wrap" on Concept 2's eight short factual rows ("Tiny fired a shot for 317 damage."). The build applied it to every row on both surfaces, and the two rows the game exists for are the long ones: the MISTAKE header lost its type name to an ellipsis at 100% on the first mistake of the fixture (UI-19) and the wipe report cut three of three jokes (UI-23; CONTENT-15 measured the corpus at mean 75 characters, max 109, against ~62 visible). docs/13 §4.4 (never abbreviated), §7 (a tooltip is never the only place a fact lives) and §11.3 (the mistake is "the loudest single event in the game's UI") outrank a measurement taken on rows with no comedy in them, and the user's rule (reference concepts are a standard; where their UI does not fit the design, the design wins) settles it.

**Ruling.** ONE rule for the two reading surfaces (CRITIC-C2), `LogPlayer.mistake_header` the one door:
- The header leads with the TYPE — "Dropped a Mechanic — Greg, Severe" — because the type is the fact the row exists to say and the part the ellipsis ate; the class is on the card and in the joke's voice.
- LIVE log (RaidView): an ordinary row still ellipsizes (spec 02 §2.1 stands for it); the mistake header wraps to a second pitch only when its words need one (`RaidView.HEADER_LINES = 2`; measured, four of eighteen type names with a four-letter name and eight with the pool's long shape do not fit one line beside the MISTAKE stamp), the quote wraps to two lines and a third only when the corpus line needs it (`QUOTE_LINES = 2`, `QUOTE_LINES_MAX = 3`), every row is a whole number of `Type.LOG_ROW_PITCH`es and the scroll shows `LOG_VISIBLE_ROWS = 7` of them, so the scroll snaps by rows and the fold never slices a line (UI-35).
- REPORT (Results): nothing ellipsizes — header, cause line and quote wrap in full (`Widgets.log_row(..., wrap = -1)`), the header is filed under its round ("[R04] Pulled Aggro Off the Tank — Greg, Severe"), and the scroll's fold snaps to the last LINE that fits whole (`Results._snap_report_fold`, `Guildhall.fold_height` reused).
- Spec 02 §2.1's sentence now says so. `EventLog.describe()` (the sim's plain rendering, the goldens' `story` arrays) is untouched.

Tests: `tests/unit/test_log_player.gd` (every `Mistakes.TYPES` name whole on the first line; the whole header with the pool's longest shape never past two), `test_raid_beats.gd :: test_no_revealed_mistake_header_or_quote_clips_and_every_row_is_whole_pitches`, `test_results_layout.gd` (no `LabelQuote` trims, the fold's wiring and arithmetic).

---

<a id="bl-109"></a>
### BL-109 - docs/07 §5.5's fourth guard, the log collapse, is a DISPLAY-time fold behind `LogPlayer.COLLAPSE` *(DECIDED - implemented as a switch, default on)*

Promoted from `build/plan/q-W6-LOG.md` (W6-LOG, wave 6; numbered by W6-LEDGER).

**Owner:** docs/07 §5.5 / docs/13 §11 - **Signal:** Quiet; a wall of "Went AFK" rows in a miserable raid (64 mistakes in 16 rounds on `e5_miserable_commons`)

docs/07 §5.5 row 4: "Identical Minor events by different raiders in the same round collapse to one line with a count | Readability; doc 13 owns the widget". docs/07 §10 rule 2 says the sim emits everything, so the fold is display-side (`game/core/LogPlayer.collapse`, pure, applied once when a `LogPlayer` is built and by `Results._log_panel`): Minor + same round + same `mistake.type` + DIFFERENT raiders fold into one synthetic entry carrying `params.count` and `params.actors`, landing where the last member stood with its `sequence` (so RaidView's HP fold never runs ahead of the page) and printing that member's joke — one line for the folded row (CONTENT-13's "the bag draws once" is met at the reading end: N were drawn, one is shown). A Severe never folds (docs/13 §11.2's beat), a knock-on (`caused_by`) never folds (its chain is the point), one raider twice is two lines. The header reads "Went AFK — 3 raiders, Minor"; the names are the row's tooltip. The rail counter counts the ACCOUNT (`count_of`), never the rows. No `GameSettings` key was added (docs/13 §15.1's inventory is closed — M5-COMEDY-10's risk clause); the switch is `const LogPlayer.COLLAPSE := true`, the designer's to flip if the wall of AFKs was the joke.

Tests: `tests/unit/test_log_player.gd :: test_identical_minor_mistakes_in_one_round_collapse`, `:: test_collapse_never_merges_across_rounds_or_severities`, `:: test_a_folded_row_reads_as_a_count_on_the_screen`; `test_results_layout.gd :: test_the_report_folds_identical_minor_rows_like_the_live_log`.

---

<a id="bl-nnn"></a>
### BL-nnn - The wipe's culprit is the last Severe-or-worse mistake before the first tank or healer death, else the deepest cascade, else nobody; the −4 is queued by the sim and applied by the game *(🔷 PROPOSED - implemented behind a named constant)*

**Owner:** [01 §6.1, §6.4](./01-core-loop.md) / [07 §6](./07-combat-simulation.md) / [05 §7.1](./05-morale.md) - **Signal:** Silent - doc 01 names the number and never defines "the raider whose mistake triggered the wipe"

Doc 01 §6.1 gives "an extra −4 to the raider whose mistake triggered the wipe" and §6.4 wants a
post-mortem "naming the raider at fault, the specific mistake". `Morale.TRIGGERS["wipe_caused"]`
has carried the −4 since the morale ledger landed and nothing ever named a raider, because no
document says which mistake "triggered" a wipe. LOOP-12 proposed the rule; CRITIC-C12 put it in the
sim's cascade unit so the report reads a field that exists.

**Taken (W6-SIM-CASCADE, `sim/core/RaidSim.gd` `_wipe_cause`, `WIPE_CULPRIT_DELTA := -4`):** on any
loss (wipe, soft wipe, attrition) the sim names ONE log entry —

1. the LAST mistake of severity Severe or Critical logged before the first tank or healer is
   confirmed Dead ("Severe" reads as Severe-or-worse: a Critical is a worse Severe);
2. else the mistake with the deepest `cascade_depth` (ties to the later one);
3. else nobody — `wipe_cause` is empty, the verdict line stands alone, and the report is expected to
   say the boss simply won.

`SimResult.wipe_cause = {actor_id, mistake_type, round, entry_seq}`; the log's last Story line on a
loss is `wipe_cause` ("It traces back to Cindy — Healed a Corpse, round 4."); the culprit's entry in
`deltas_queued` carries `wipe_caused: 1`. The sim REPORTS (doc 14 OQ-10): `game/` fires the ledger's
`wipe_caused` trigger from that flag (W7-REPORT), and `tests/unit/test_raid_sim.gd` pins
`WIPE_CULPRIT_DELTA` equal to the trigger's delta so the number lives in one place.

**Also taken here, doc 07 §6 rule 1's parent when several tokens are live (SIM-05's default):** the
live token whose "Effect on later rolls" column names THIS roll — the actor's Fire/Adds for
`MIS_AVOIDABLE_DEATH`, the raid's Aggro for a healer's roll, the raid's Distraction for an ambient
roll — else the OLDEST live token on the actor, else the mistake is a root. Only the actor's own
tokens count in the fallback: a raid-wide fallback would put every miserable raid at depth 3 and,
through the depth cap, stop most tokens from being emitted. A Downed holder's token still counts
(§6's worked cascade gives Cindy her +8pp in the round Greg drops); a Dead holder's does not.

**Alternatives** (for the designer, ship plan §6): (a) the FIRST Severe of the fight rather than the
last before the death — blames the opening of the slide instead of its last step; (b) the mistake
with the most descendants — needs a graph walk and reads the same as (2) in practice; (c) the
raider who died first — a consequence, not a mistake, and often the tank taking a boss swing.


<a id="bl-110"></a>
### BL-110 - The on-ramp is sized by one rule for the roster a new guild brings: stage 0, all-Common, morale 45 *(DECIDED - lever (c) of M6-BAL-04, taken under the designer's delegation; W8-SIM-BALANCE lands the rows)*

**Owner:** [08 §9.3a](./08-stats-and-formulas.md) (new) / [10 §8, §9.1](./10-content-and-encounters.md) / [05 §8](./05-morale.md) - **Signal:** The playtest's "closed circuit" (M6-BAL-04): eight guilds walked A2 with a stage-0 party against a rung sized for a shod six

`RaidPlan.gear_label()` returns "T1A" the moment one chalked raider wears one Adventure piece, and `tools/playtest.gd` never farmed a cleared rung — so M6-BAL-04's "in full Tier 1 Adventure gear" was the label, not the gear: 550 HP at 16.5 × 0.70 is 48 rounds against an enrage of 14, and no morale number opens that. The wall was a gear stage the player was assumed to have and never handed; the 45 is real and second. Lever (c): A0, TR, A1, A2 and A3 are re-derived from a new 08 §9.3a for every encounter whose party carries ONE healer — `fight_len = target_rounds / TAX` (TAX = 1 − mistake_chance(Common, 45) = 0.702), `hp_total = nominal_dps(stage 0) × target_rounds × (TAX / TAX_CONTENT) = × 0.924`, `boss_auto_raw = (tank_max_hp / fight_len + HEAL_FLOOR) / (1 − mitigation(7 AC) = 18.9 %)` — the HEALED clock, because 08 §9.4's 3.5-round invariant was written to be unhealable solo for a twelve with three healers and a six has one. Tutorials take the lesser of the rule and their authored under-budget swing (10 §9.1: a tutorial demonstrates a fail state, it does not impose one). The rows (W8-SIM-BALANCE, hand-written in `data/encounters_tutorial_t1.json` and `data/encounters_adventure_t1.json`): A0 4-party, 1 × 61 HP, 20 raw ×1, no mechanic, target 6 / enrage 9 · TR 6-party, 183 HP, 8 ×2, M03 {13/rd, escape 50 %}, 12 / 17 · A1 3 × 41, 7 ×3, M04 {1 add, 11 HP, swing 5, round 5}, 8 / 12 · A2 2 × 76, 9 ×2, M04 {1, 12, 6, r6} + M02 15 every 4, 10 / 14 · A3 183, 8 ×2, M02 15/4 + M03 18/50 % + M04 {1, 15, 6, r6}, 12 / 17. Before/after: A0 66 · 20 → 61 · 20; TR 198 · 30 → 183 · 16; A1 135 · 27 → 123 · 21; A2 550 · 38 → 152 · 18; A3 700 · 50 → 183 · 16. The Common baseline (−5), the wipe deltas, the 60 G purse and the 150 G Guildhall are unchanged — the facility keeps its purpose because a Common still rests at 45; lever (a) would have spent the first facility's reason to exist on a wall gear built. Derived under an attrition grace of 5 rounds past enrage ([BL-114](#bl-114)) — without it A2's mean kill clock (13.1) runs into its enrage (14) and the tails fail. The 12-raid keeps §9.3 unchanged (its three healers are §9.4's own model). `Formulas.SWING_PRICES_MECHANICS` is NOT built — after Q-100 no one-tank rung carries M01, so there is nothing to price; `Encounter.validate()` refuses `m01` where `tanks_required < 2`. The harness now farms like a player: `tools/playtest.gd` (W8-SIM-BALANCE's file this wave) re-runs the Adventure rungs (A3 → A2 → A1, each a Day Tick) before a raid rung until no raider wears `start`-source armour or an unarmed main hand — 08 §9.2's E1 stage — and re-runs cleared raid rungs to `raid_entry` before E2-E5; farm runs are attempt rows, the 5-attempt cap applies only to the rung being sized; the stage predicate is a local function in `playtest.gd` (start / adventure / raid by `source` on worn items and an armed main hand). Pins: `test_adventures.gd:213` → `rate >= 0.40`; `test_tutorials.gd:364` → `cleared >= 8`; A0 stays `>= 18`; "A1 still bites" `<= 19/20` at 55. The drift baseline gains the five on-ramp rows at (stage 0, Common, 45) and `--rebaseline` runs once, AFTER W8-ITEMS's regeneration (the daggers, off-hands and loaners move `raid_entry`). BL-28's stage-0 finding stands; BL-30's staged swings are superseded and its row says so; docs/08 §9.3a and docs/10 §8/§9.1's tables move in the same unit, the docs commit before the data commit (`test_canon_guard.gd` reads docs/08's tables). Under this rule the on-ramp is winnable at stage 0 / 45 and the raid door (E1: 2,200 HP against full Adventure gear) is the first real wall, which is the designer's ladder: the Adventure is beatable on arrival and its loot is what you re-run it for — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-111"></a>
### BL-111 - An Adventure rung rolls two items per loot slot *(DECIDED - implemented; W8-SIM-BALANCE)*

**Owner:** [10 §4.2](./10-content-and-encounters.md) / [11 §4.3](./11-economy-and-crafting.md) - **Signal:** Silent; the raid's `raid_entry` stage was a 36-clear farm

docs/10 §4.2 counts the raid's rolls (E1:2 … E5:3) and says nothing of the Adventure's; the tree fell back to `loot_slots.size()`, one item per slot per clear, which made dressing the twelve for Raid 1 (12 feet + 12 weapons over two rolls, 12 legs over one, 24 head/chest over two) a 36-clear farm against docs/11 §4.3's ~9-attempt tier budget. `Loot.ADVENTURE_ROLLS_PER_SLOT = 2` (`sim/core/Loot.gd`) halves it to 18 — A1 4 rolls, A2 4 (two slots once the off-hand slot lands — Q-35), A3 4; the raid's `RAID_ROLLS` are untouched. BL-31's upgrade bias keeps the extra rolls from becoming a gold faucet until every raider is dressed; the Tier 1 boundary balance is re-read by the playtest's `peak_gold` column against docs/11 §4.4's 0-20 % band. The designer's Adventure hands out the tier's SET (the ideaboard's Tier 1 Adventure gear is a four-piece set per family plus weapons and charms, assigned to the Adventure, not to an encounter) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-112"></a>
### BL-112 - A wiped tutorial costs morale like any wipe *(DECIDED - the ship default kept; no code)*

**Owner:** [05 §7.1](./05-morale.md) / [10 §9.3](./10-content-and-encounters.md) - **Signal:** LOOP-24's first-hour path (wipe TR, skip it, six Commons at 34 cannot clear A2)

docs/05 §7.1 has no tutorial exemption and gains none: a wiped Tutorial Raid pays the wipe row (−8, ×1.35 for a Common) and the culprit's −4 ([BL-107](#bl-107)). The Tutorial Raid is the fight designed to be lost and its Wipe Report is read on the roster page too — "Oh shit, Steve is at 14" is the designer's own description of the game, and a wipe that costs nothing teaches that wipes cost nothing. With TR winnable at ~55 % (Q-100) the expected cost is one wipe, recovered by drift in ten ticks or two A0 re-runs (+6 cleared, +3 brought per tick; docs/10 §9.3 keeps a resolved tutorial replayable for gold). LOOP-24's path is closed by BL-110 (A2 sized for stage 0) and Q-100, not by a fifth canon number; `GameState._apply_raid_morale` keeps no tutorial branch — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-113"></a>
### BL-113 - The Forgiving Guild toggle ships: one multiplier, 0.75, on mistake chance and enemy HP *(DECIDED - built; W8-SIM-BALANCE · W8-KEYS · W8-CRISIS · W7-SAVE)*

**Owner:** [00 §6.4](./00-vision-and-pillars.md) / [08 §11](./08-stats-and-formulas.md) / [13 §15.1](./13-ui-ux.md) / [16 §11 C13](./16-production-roadmap.md) - **Signal:** CRITIC-M1: the docs' one relief valve was in the cut order's LAST slot and not in any wave

docs/00 §6.4 as written: off by default, switchable at any time, no achievement or content gating, touches only mistakes and boss HP. `Formulas.DIFFICULTY_MULT` (default 1.0; 0.75 under `forgiving_guild`) multiplies `mistake_chance_bp` BEFORE the clamp so the per-rarity floors hold (a Common at 45 reads 29.8 % × 0.75 = 22.4 %, above the 12 % floor) and enemy `max_hp` at build (rounded to 5); it arrives as `RaidSim.run(..., opts.difficulty_mult)` because the sim may not read GameSettings, is written into `active_run.difficulty_mult` and the attempt record by `record_attempt` so Results' stored-seed replay (Q-53) is the fight that happened, and is swept as a second axis (`balance_sweep.gd --forgiving`). `GameSettings.forgiving_guild: false`; one Options row on the kit's cycle chip — "Forgiving Guild — fewer mistakes, softer bosses. Changes nothing else."; docs/13 §15.1 gains the row; docs/16 C13 is not cut (C5 and C8 ship, and nothing lower is cut while something above it is in). It is a relief valve for the two named spirals and was NOT used to make the playtest green — the on-ramp is sized at 1.0 (BL-110). Achievements unlock under it; the Records tab prints nothing about it. Audit `m6-forgiving-guild` closes — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-114"></a>
### BL-114 - Wipe by attrition fires at the enrage round plus a named grace of 5; the 40-round cap stays the safety *(DECIDED - implemented; W8-SIM-BALANCE)*

**Owner:** [10 §5.2, §6](./10-content-and-encounters.md) / [07 §7.3](./07-combat-simulation.md) - **Signal:** SIM-12: an unstated `+ 5` every baseline clear rate was measured under; the plan's default deleted the DPS check from seven of Tier 1's eight fights

`RaidSim.ATTRITION_GRACE_ROUNDS := 5` — the value the tree has run since the mech-arms unit — now named and overridable per record as `attrition_grace` (validator `>= 0`); `_check_end` reads it; the 40-round cap (docs/07 §7.3) remains the safety property, not the rule. At `enrage_round` every fight without an authored M06 logs a Story line — "Round 17. The boss has stopped being careful. Five rounds before this stops being a fight." — so a loss on the clock reads as a countdown, not a crash. With Focus out of 1.0 healing is unlimited, so the enrage clock is the ONLY thing that stops a stable-but-weak raid grinding any fight to a win over 35 rounds; the baseline (A1 starting/Common/55: 57 of 200 outcomes on the clock; E5 raid_entry: 39 of 200) shows it is a live lever. It is load-bearing for BL-110: A2's mean kill clock at 45 is 13.1 rounds against an enrage of 14 — without the grace the tails fail and the on-ramp bands cannot hold. Pinned by `test_raid_sim.gd::test_attrition_fires_at_the_enrage_round_plus_the_grace` (replacing the plan's `test_attrition_only_at_the_round_cap`); docs/07 §7.3's table gains the row and docs/10 §6's "enrage expiry" gets the number — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-115"></a>
### BL-115 - E4's mechanics are authored, not implied: M05's effect, M08's window, M09's cadence *(DECIDED - implemented; W8-SIM-BALANCE for Tier 1, W9-TIERS through the generator for tiers 2-5)*

**Owner:** [10 §7.4, §10](./10-content-and-encounters.md) / [08 §9.5](./08-stats-and-formulas.md) - **Signal:** SIM-13: M05's "effect E" was never named; M08 authored as a permanent fixate by accident; handoff-mech-arms #2 never applied

M05 Interrupt Check carries `effect {"kind": "raid_damage", "amount": 27}` on `round 4, every 5` — the tier's M02 pulse, 08 §9.5's `AOE_BITE_FRACTION × cloth_max_hp` as the generator already computes it for E3 — so a missed interrupt is a second pulse the healers did not budget for; M08 Fixate is a window, `{"rounds": 2, "every": 6}` (the recommendation's 5 moved to 6 so the fixate never overlaps the debuff it would otherwise make decorative); M09 Healing Debuff recurs, `{"reduction_pct": 40, "rounds": 3, "round": 3, "every": 6, "target": "active_tank"}` — live while the boss is on the tank, never while it is chasing someone else. Over 17 rounds: M09 live 3-5 / 9-11 / 15-17, M08 6-7 / 12-13, M05 checks at 4 / 9 / 14 — the three mechanics visibly take turns, which is the fight a player can read coming (docs/07 §8.2). `Encounter.validate()` refuses an M05 spec without `effect.amount > 0` and an M08 `rounds` not strictly less than its `every`. E4 falls from its measured 200/200 at Common/raid_entry/55 — the ★★★★ buys teeth; its band is Q-100's 60 (45-75). Pinned by the `e4_rares_raid_entry` golden and `test_encounters.gd`; tiers 2-5 inherit the three rules through `gen_items.gd` (W9-TIERS) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-116"></a>
### BL-116 - The break phase exists, in `game/`: MIS_NINJAPULL is built, not cut *(DECIDED - implemented; W8-CRISIS the roll, W8-SIM-BALANCE the sim, W7-SAVE the key)*

**Owner:** [07 §4.1, §5.2 row 14](./07-combat-simulation.md) / [14 §3.1](./14-technical-architecture.md) / [BL-24](#bl-24) - **Signal:** CONTENT-12: eight of the corpus's best lines behind a type no path reached

When the player presses Depart on a raid encounter and the mission already has an attempt this town cycle (a clear or a wipe — either is a break), `GameState.start_attempt` rolls one ambient check per living party member on a new seeded channel `break` (derived from the attempt seed like the others) with `ctx.break_phase = true`; only a MIS_NINJAPULL draw counts, the first in slot order pulls, at most one per break. The sim receives `mstate.ninja_pulled` (a raider id) and starts the fight with the provisions unapplied and unconsumed (every item listed in `result.consumables_unspent` with reason `ninja_pulled` — the potions are still in the bag), the mistake emitted through `_log_mistake` at round 1 ROUND_OPEN at its base Critical band with `Token.DISTRACTION` live (+5pp raid-wide, 2 rounds) and a line from the type's own variants — the perfect culprit for BL-107: "It traces back to Greg — Ninja-Pulled During the Break, round 1." Adventures, the tutorials and a raid's first pull have no break (NINJAPULL is in `TUTORIAL_DISABLED_TYPES`). The roll's result is written into `active_run.ninja_pulled` (default "") and the attempt record, and passed back into `RaidSim.run(..., opts)` by Continue's re-run and Results' replay, so the replay is a pure function of what was stored (Q-53's commit rule). Expected rate per break with the type's ambient share: a full Common party at Content ≈ 48 %, Rare ≈ 21 %, Epic ≈ 9 %, Legendary ≈ 3 % — the worst guild pulls early every other break and it stops as the roster improves; `balance_sweep.gd` never sees it (it calls the sim), so Q-100's curve is measured without it, stated. `Mistakes.NINJAPULL_REACHABLE` is not built; the type is never flagged unreachable; the eight lines stay. W7-SIM-EFFECTS landed nothing on the type itself; it opened the seam — `RaidSim.run(..., loadout, opts)`'s sixth parameter and `SimResult.consumables_unspent` (`{raider_id, sku, reason}`) — that W8-SIM-BALANCE's `ninja_pulled` branch writes into. Pinned by `test_raid_sim.gd::test_a_ninja_pull_starts_the_fight_unbuffed_and_names_the_puller` and `test_game_state.gd::test_the_break_rolls_only_after_a_first_pull` — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-117"></a>
### BL-117 - The nine Legendaries are named: Gunnar, Ottilie, Alder, Natsuna, Solenne, Casimir, Tallis, Isaura, Lorcan *(DECIDED - W8-ITEMS sets `display_name`; the `name_pending` fallback is not built)*

**Owner:** [03 §5.6](./03-guild-reputation.md) / [04 §7, §11.1](./04-recruitment-and-roster.md) - **Signal:** SHIP-04's eight legendary holds on the export gate

Canon: "You can only ever find 1 Legendary per class — They are also named characters — IE Natsuna(the shaman) or something." Natsuna (Shaman) is final; the eight are Gunnar the Warrior ("Front is where I stand. Move."), Ottilie the Cleric (has your old raid logs printed out), Alder the Druid (would raid naked; home is "somewhere with trees"), Solenne the Mage (notices when someone is wearing last tier), Casimir the Wizard (counts ninety seconds; was the only one laughing), Tallis the Rogue (keeps his own numbers; was behind it the whole time), Isaura the Monk (turns around three times before every boss), Lorcan the Bard (arrives as the pull starts; knows the tavern staff by name) — given names only, two or three syllables, from no single culture, none a surname, a public figure or a name in docs/04 §7's mundane pool, each fitted to the character its file already draws and sitting outside the Bob/Greg/Steve register as Natsuna does; the four pronouns the files carry are honoured; initials all distinct so the Records meter's nine rows scan. Grepped against `data/`, `game/`, `sim/`, docs: no collision. `data/legendaries/*.json` `display_name` set, `name_pending: false`, `name_status` "ruled by the loop, 2026-09-15 delegation"; docs/03 §5.6's two ❓ OPEN rows close; the Records meter reads 9-of-9; the `Recruitment` `name_pending` guard, the `_pending/` move and the N-of-named meter are dead branches and are not built. The nine busts are drawn by `derive_busts.py`'s named pass (W9-ART) — a named person, not a rarity re-hue — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-118"></a>
### BL-118 - The comedy gate and the name pool are reviewed by the loop, in one sitting, in W9-REVIEW *(DECIDED - the read is the loop's; BL-53 resolves with it)*

**Owner:** [04 §7](./04-recruitment-and-roster.md) / [07 §10.3](./07-combat-simulation.md) / [16 R-3](./16-production-roadmap.md) - **Signal:** M5-COMEDY-12 / CONTENT-16: two human reads with no reader

The name pool (36 given names, 20 epithets, six mangles) and the corpus (192 type lines, 36 Legendary lines, 42 encounter lines, 68 item notes, 72 backstory bullets, 40 achievement blurbs, plus the 21 boss titles, 20 tier words and 8 Legendary names ruled today) are rendered on one page by `tools/corpus_review.py` and read in one sitting by W9-REVIEW's reviewing agent — not the writer — against docs/04 §7's standard and docs/07 §10.3's five rules (never punches down, never blames the player, never lands on a real person); the keep / rewrite / cut marks are `build/plan/ship/corpus-review.md` and are applied in-wave by `--apply`, every rewrite re-validated by `MistakeLines._check_writing_rules` and the budget test. BL-53 → RESOLVED; `data/mistake_lines.json`, `names.json` and `achievements.json`'s `_notes` say who read them and when; the NINJAPULL lines are kept (BL-116). The residual risk docs/16 R-3 names — that a validated, reviewed line still does not land — is accepted in writing and answered after ship by player reports, not by a further gate; the page ships in the tree so the designer can file marks as a 1.0.x data patch. W9-REVIEW runs after W8-ITEMS's and W9-TIERS's regenerations — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-119"></a>
### BL-119 - The 21 boss rungs carry a role title through spec 00 §2.3's `title` field; everything else keeps canon's placeholders *(DECIDED - W7-REPORT the field and TR; W8-SIM-BALANCE A3/E3-E5; W8-SCALE-1 the prep card; W9-TIERS tiers 2-5)*

**Owner:** [10 §2](./10-content-and-encounters.md) / [art/ref/specs/00 §2.3](../art/ref/specs/00-canon-reconciliation.md) / [09 §10.2](./09-items-and-itemization.md) / [Q-84](#q-84), [C-19](../build/plan/ship/LOOP.md) - **Signal:** "Main Boss" as the boss's only name on the plate; canon: "obviously they will need names later"

The vocabulary is "Encounter N" in every UI string and "Boss N" only as the loot tables' `boss` key; the ladder words ("Raid 1", "Adventure 2") and the enemies' log names ("Trash", "Elite", "Add", "Mini Boss", "Main Boss") are canon's placeholders shipped as final ([BL-101](#bl-101) stands for them). The boss rungs get a name in the optional `title` field spec 00 §2.3 defined (shown in the title slot, the ladder words dropping to the subtitle "Raid 1 — Encounter 5 · Main Boss"): Tutorial Raid **The Doorman**; A1 **The Gatekeeper** · A2 **The Tollkeeper** · A3 **The Cartographer** · A4 **The Groundskeeper** · A5 **The Lamplighter**; Raid 1 **The Understudy** (E3) · **The Orator** (E4) · **The Landlord** (E5); Raid 2 **The Sweeper** · **The Auditor** · **The Encore**; Raid 3 **The Librarian** · **The Choirmaster** · **The Creditor**; Raid 4 **The Censor** · **The Surveyor** · **The Chronicler**; Raid 5 **The Usher** · **The Proctor** · **The Last Word**. Roles rather than creatures because one boss set serves five tiers (BL-100) and a creature name would be a lie the art tells four times over; each is a job the guild is failing an interview for, in the record wall's register, and fits its mechanics (the Doorman teaches the door; the Librarian is Raid 3's silence; the Encore kept going nineteen rounds; the Last Word is the last boss and the log will still say Steve stood in something). Enemy `name`s are untouched so no golden moves. `sim/model/Encounter.gd` `title: String = ""`; the RaidView boss plate and the RaidPrep card sub-line (title over kind when present); `test_encounters.gd` asserts a non-empty `title` on every mini_boss/main_boss rung and none on trash; tiers 2-5 through `gen_items.gd`'s encounter table. The tutorial trinkets are docs/09 §10.2's "Cracked Charm of Power" / "Cracked Charm of Health" (docs/01 §8.2's and docs/10 §9.2's "Trinket of Mild Competence / Faint Encouragement" struck — "Cracked" is the register's word for crap and the template generates). Q-84 and C-19 close — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-120"></a>
### BL-120 - A shape-B handle is the raider's name everywhere; nothing restyles it *(DECIDED - no code; docs/04 §7 gains one sentence)*

**Owner:** [04 §7](./04-recruitment-and-roster.md) / [00 Pillar 2](./00-vision-and-pillars.md) - **Signal:** TOWN-20 / UI q2: "Pauline_4 reads as a collision suffix"

It is a collision suffix, in-fiction: Pauline was taken, so she is Pauline_4, and she has answered to it for nine years. The handle is the display name on the card, the roster, the log and the wipe report, and is never restyled ("goes by Pauline_4") or explained — a second name line breaks Pillar 2's `Name — NN <face>` row and puts two names on one person. Shape B produces it at ~4 % of hires, a running gag, not a generator; it is funnier in the log ("Pauline_4 stood in the fire") than on a card. `NamePool.gd:189-190` unchanged — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-121"></a>
### BL-121 - 1.0 is the twelve-entry canon ladder, Adventure 0 through Raid 5; `tier_is_named` is a top-down valve, never a return to Tier 1 *(DECIDED - W9-TIERS's long branch; the no-words branch is not built)*

**Owner:** [00 §6.3, §8.2 R1](./00-vision-and-pillars.md) / [BL-69](#bl-69) / [BL-73](#bl-73) - **Signal:** CRITIC q5 / SHIP q3: the release shape hung on words that have now come

With the tier words (Q-41) and the Legendary names (BL-117) ruled, W9-TIERS runs its "words came" branch: the 16 files regenerate, `--tier=N` sweeps at each tier's own gear stages, one golden per new mechanic's first carrier, the walls as rows, S17 on the first clear of Raid 5. The Tier-1-only ending survives only as the mechanism it already is (`ContentDB.tier_is_named`, `GameState.COMPLETED_AT = "last_named_tier"`): if the per-tier pass measures a tier uncompletable at its own gear stage over eight seeds, that tier's `pending` flips back to true (a one-key data edit), the ending retimes to the tier below and the row records the numbers — docs/00 §6.3's cut order ("Raid 5 and Adventure 5, shipping a 4-tier ladder"), top down, never Raid 2-4 and never back to Tier 1. `data/_pending/` is never created; W10-EXPORT's pending-file list is empty; the README's "smaller game" line is not written; Completion's copy is the five-tier line. The Legendaries become reachable (Renowned at 1,800 RP is arithmetic only tiers 4-5 pay) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-122"></a>
### BL-122 - The Legendary find rate is the endgame's clock, not a content gate *(DECIDED - accepted; nothing retimed)*

**Owner:** [03 §5.2, §5.4, §6.4](./03-guild-reputation.md) / [10 §13](./10-content-and-encounters.md) / [Q-23](#q-23), [Q-88](#q-88) - **Signal:** M5-END-5: 5 % at a rank with nothing left to serve

The 5 % at Legendary rank (`find_weights [0,0,0,950,50]`) and the 3200 RP threshold stand; the continuing activity after Raid 5 is the 9-of-9 collection (Q-88), whose expected length at 5 % per candidate is ≈ 180 generated candidates, ≈ 30 Tavern boards at six a board — the endgame's length, by design, and the designer's own trophy case ("one Legendary per class, named"; Octopath's eight travellers: the game is done when the party is). Retiming the rate earlier would spend the prize on a rank that still has raids to gate. docs/03 §5.4 gains one sentence saying so; docs/10 §13 row 3 closes "accepted"; the pacing tests are untouched; with five tiers mounted (BL-121) Renowned pays and the rule has a 1.0 player — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-123"></a>
### BL-123 - The aerial town is an establishing shot: motion, no figures *(DECIDED - as built; deferred in writing)*

**Owner:** [12 §3.2](./12-art-direction.md) / [art/ref/specs/09 §3](../art/ref/specs/09-background-plates.md) - **Signal:** M4B-ACT-04: the 21-48 px strips scaled to 0.3 destroyed the pixel art

The MainMenu's aerial plate carries sails, gulls, clouds, the fountain and the waterfall and no figures, because no sprite the project owns reads at 10-14 px and downsampled pixel art is blur ("nothing blurry"); Octopath's title pan has no ants either. Aerial-scale townsfolk are post-1.0 (`gen_townsfolk.lua`, PIPE-09). `stage_town.json`'s "no actors" note is the record — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-124"></a>
### BL-124 - Hall framing is "same" and the roster is margins-only *(DECIDED - as built)*

**Owner:** [13 §2 M5](./13-ui-ux.md) / [BL-78](#bl-78) - **Signal:** Q03

`Guildhall.HALL_FRAMING = "same"`: the hall family (Guildhall, Roster, RaiderDetail, Settings, LoadSave) is a panel over the hub's own camp framing — Town → Guildhall reads as a panel opening over the place you were already looking at, which is the desk not moving; the guild lives in the camp (BL-78). A 3-column roster spends 250 px of a 12-card roster on a fire ring. `FRAMINGS["tight"]` stays built as the recorded alternative — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-125"></a>
### BL-125 - Header chip 2 wears the rank sigil, not a gem, and never the word "Rep" *(DECIDED - `Frame.REP_ICON = "sigil"`; W9-POLISH; spec 00 §2.5 amended)*

**Owner:** [art/ref/specs/00 §2.5](../art/ref/specs/00-canon-reconciliation.md) / [13 §8.1](./13-ui-ux.md) - **Signal:** UI-53 / LOOP-05 / CRITIC-C5: a gem beside a number reads as a currency the player cannot spend

Canon has one guild stat ("Your guild has a single primary stat: Guild Reputation") and one currency, gold; a gem beside a number is a second currency. Chip 2 shows the reputation points beside the current rank's sigil (the existing `rank_<name>.png` — no new asset), carries no word, and its tooltip reads "320 reputation · 80 more to Known" (the word in full, docs/13 §8.1's discipline). `gem.png` stays for the Board's trinket row, which is a trinket, which is right. `test_frame_header.gd` asserts the tooltip contains "reputation" and the texture is `rank_<name>` — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-126"></a>
### BL-126 - No depth of field ships and none is owed *(DECIDED - off; docs/12 §2.2 row 6 and docs/00 VS7 amended)*

**Owner:** [12 §2.2, §3.1, §6.1](./12-art-direction.md) / [00 VS7](./00-vision-and-pillars.md) - **Signal:** Q08

The plates are the designer's own 1:1 pixel art at display density (docs/12 §3.1's supersession: no pixel pitch above 1); Octopath's tilt-shift blurs 3D planes, and a blur here would smear the designer's pixels — the one thing "nothing blurry" forbids. The vignette stays behind `reduced_effects`; the scene `dof` key stays absent as the post-1.0 hook. docs/12 §2.2 row 6 ("non-negotiable") → "optional, OFF — the plates are authored sharp at 1:1"; docs/00 VS7 → "lighting, parallax and ambient motion present; no depth-of-field on 1:1 plates" — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-127"></a>
### BL-127 - Accessibility: the three-state ramp is corrected and CVD-verified; the text floors stay; `prose_font_swap` is retired; the logotype is a mark *(DECIDED - W8-KEYS the palette; W7-DOCS the doc rows; W10-DELETE the key)*

**Owner:** [13 §8.3, §13, §14, §15.1](./13-ui-ux.md) / [art/ref/specs/04 §5](../art/ref/specs/04-palette.md) - **Signal:** M6-A11Y-06 / UI-47 / RULES-08/09: the reference's sampled trio was not lightness-ordered (amber L* 78.5 above green 69.3; 2.2 L* apart for a protanope)

(1) The ONLY morale/success ramp is the reference's red / amber / green family corrected so it is lightness-ordered: `DANGER #F73526` (unchanged), `CAUTION #E8A302`, `POSITIVE #AFEBA2` — L* 54.5 / 71.8 / 87.6, every adjacent step ≥ 5 L* and monotone under none, protanope (42.5 / 68.5 / 89.6), deuteranope (59.5 / 73.5 / 86.4), tritanope (72.4 / 78.6 / 84.9) and greyscale (`tools/art/cvd.py`, Brettel/Viénot); contrast on `SURFACE_INSET` 4.81 / 8.47 / 13.34. docs/13 §8.3's ten-plate table is struck (band 0's fill is 1.35:1 on `SURFACE_PANEL` and cannot be text on navy); the other seven bands ride the integer, the word and the glyph, which is §13's first row. `colourblind_safe` (default Off) stays and means a hue swap of the third state only — `POSITIVE_CVD #C6DDF1` (L* 85.8) for eyes that do not separate red from green; the Settings note: "Morale's third colour is sky instead of green, for eyes that do not tell red from green. The number and the state word are unaffected." The criterion, confirmed: ΔL* ≥ 5 between adjacent ramp steps under all five observers, monotone (the 3:1-per-step half is struck as arithmetically unreachable). `Palette.CAUTION`/`POSITIVE` take the hexes; `BAND_FILL_CVD`/`BAND_INK_CVD`/`band_ink_cvd` are deleted; `band_color_cvd` returns `[DANGER, CAUTION, POSITIVE_CVD]`; `morale_color` goes through `band_color_active`; `test_palette_cvd.gd` asserts the numbers; the art-gate baselines re-record at the wave-8 close inside the 0.07 jitter. (2) `Type.SMALL 13` / `STACK 11` stay: docs/13 §13's 14 px floor is read in §4.2's 1920-wide authoring frame (13 in the 1536 frame renders at 14 whole pixels at 1080p); the 125/150 text scale is the remedy. (3) `prose_font_swap` is retired — Fira Sans is the only body face and there is nothing to swap from; the row is hidden now and deleted with its key in W10-DELETE; §13's font-choice row and §15.1's row are struck. (4) The pre-rendered logotype (`gen_wordmark.py`, an OFL face) is a mark, not text, and exempt from §14's "no text in art"; the words are also a Label beside it. §15.1 gains "Colour-safe morale ramp | Off | §13 | Player | Global"; `test_a11y_legibility.gd`'s `BELOW_FLOOR_AT_1920` becomes the record of the ruling, not a defect list — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-128"></a>
### BL-128 - The morale faces are ten authored sprites, never system emoji *(DECIDED - as built; `Fonts.MORALE_FACE_FONT = true`)*

**Owner:** [12 §5.2](./12-art-direction.md) / [art/ref/specs/00 §2.1](../art/ref/specs/00-canon-reconciliation.md) - **Signal:** Q17

Canon's "Natsuna — 87 ❤️ … Steve — 14 😡" is the designer's shorthand for a face beside the number; in a 2D-HD frame the only reading is a pixel face at integer scale (Octopath's UI contains no system glyph; It's A Wipe! draws its mood faces). docs/12 §5.2's reading is confirmed; `emoji_free` keeps its pip figure — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-129"></a>
### BL-129 - "Screen shake on wipes" is struck *(DECIDED - BACKLOG carries the strike; M6-JUICE-04 closes)*

**Owner:** [13 §11.4, §12.2, §13](./13-ui-ux.md) - **Signal:** M6-JUICE-04

docs/13 §11.4 ("No 'You Failed', no red flash"), §12.2 ("Nothing in the UI loops, pulses, or breathes") and §13 (reduced flashing is unconditional) forbid it; a wipe is the joke, not the punishment, and the comedy lands on the report. The wipe's beat is the WIPE stamp press, the 12 % dim and the seal; the camp's fallen lie down (W9-ART) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-130"></a>
### BL-130 - The game opens borderless fullscreen and letterboxes the 1536×1024 frame *(DECIDED - as built by W6-SETTINGS; spec 00 §4's first item closed)*

**Owner:** [13 §15.1](./13-ui-ux.md) / [14 §10.4](./14-technical-architecture.md) / [art/ref/specs/00 §4, 11 §1](../art/ref/specs/00-canon-reconciliation.md) - **Signal:** SHIP-06: a first launch taller than a 1366×768 laptop hid the commit row

`window_mode = "borderless"` (F11 / Alt+Enter to a 3:2 window that fits the desktop) and `display_aspect = "keep"` — every player sees exactly the designer's 1536×1024 composition; `expand` is the opt-in for players who accept the plates' edges (spec 11 §1's revised decision, made on a 1920×1080 Town shot where expand exposed the plate's edge). SHIP's README line and export check state the same defaults — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-131"></a>
### BL-131 - Spec 00 §2's reference-concept conflicts are confirmed in canon's favour *(DECIDED - confirmed; §2.5's gem ruled by BL-125)*

**Owner:** [art/ref/specs/00 §2.2-§2.6](../art/ref/specs/00-canon-reconciliation.md) - **Signal:** DESIGNER-45

Tiny/Ranger → Rogue (nine classes, raw notes); no creature names or raider levels from the references — the loop's 21 role titles land through §2.3's own `title` field (BL-119) and `Raider.level` is never set (Q-14); twelve cards, paged; "Day N · Rank" in place of the clock; the rail's canon labels; §2.5's gem is the sigil (BL-125). The references set the art bar; where their content contradicts canon, canon wins — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-132"></a>
### BL-132 - The credits name the lead designer by the handle in the tree, the build loop and the tooling honestly, and close in the game's voice; `© 2026 Malkail`; version 1.0.0 *(DECIDED - W10-CREDITS · W10-EXPORT · W10-README; M5-END-4 closes)*

**Owner:** [00 §4.4.1, §4.4.2](./00-vision-and-pillars.md) / [13 §9.5](./13-ui-ux.md) - **Signal:** M5-END-4: no doc names a contributor; the only public name the designer wrote into the tree is the folder `screenshots from malkail the lead game designer`

`data/credits.json` `lines`, in order (the marker line deleted; `status` cleared): "Malkail — lead designer" · "Built from the designer's notes by an autonomous build loop (Claude)" · "Art drawn by script in Aseprite and Python from references the designer supplied" · "Sound and music generated in-house from physical models" (W10-CREDITS reads `Audio.MUSIC_BED` before it writes the line: "Sound generated in-house from physical models" if the lute was cut) · "Made with Godot Engine (MIT)" · "Fira Sans and Grenze Gotisch — SIL Open Font License 1.1" · "The raiders would like it known that they did their best." Seven Labels, none containing "pending"; the closer collides with nothing in `data/`. `project.godot` `config/version="1.0.0"`; `export_presets.cfg` `file_version`/`product_version` "1.0.0.0", `application/copyright="© 2026 Malkail"`, `company_name` "A Guild Story". README.md and `README-player.txt`: "© 2026 Malkail. All rights reserved. Made with Godot Engine (MIT). Fira Sans and Grenze Gotisch are used under the SIL Open Font License 1.1; the licence texts are beside the .exe." plus the disclosure the stores require, also docs/00 §4.4.2's last bullet: "The game's code, pixel art, copy and sound were generated by an AI build loop from the lead designer's own design and under their direction; the reference art was image-model output the designer supplied." — it names no other game and describes this one on its own terms. `test_export.gd` asserts version ≠ "0.1.0" and a non-empty copyright; `test_completion.gd` asserts seven lines. A real name replaces the handle by editing exactly three strings (`credits.json` line 1, `export_presets.cfg`'s copyright, the README line) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-133"></a>
### BL-133 - 1.0 ships keyboard + mouse and one language: a pad works unverified and unsupported, no glyphs or rebinding, no second language, no pseudolocale pass *(DECIDED - W10-DELETE the rows and keys; W10-EXPORT the README sentences; W7-DOCS docs/13 §15.1)*

**Owner:** [00 §6.1](./00-vision-and-pillars.md) / [13 §15.1, OQ-12](./13-ui-ux.md) / [16 W4.8, C6](./16-production-roadmap.md) - **Signal:** SHIP-20 / LOOP-26 C19-C20: two hidden Settings rows with nothing behind them

The joypad events in `project.godot` stay (A/B/X/Y/Start bound; the D-pad steps focus through Godot's defaults — deleting them would be a regression for nothing); no glyph set, no rebinding, no Deck verification (docs/16 C6 prices all three as the Deck milestone, after 1.0 per docs/00 §6.1). `README-player.txt`'s Controls block ends: "A gamepad will steer the menus — D-pad to move, A to confirm, B to go back, Start for options — but is not a supported input in this release: no button glyphs, no rebinding, and nothing has been tested on a Steam Deck." One language, en-US — the only string table that exists; `TranslationServer` is called nowhere under `game/`; a translation of a comedy is a content project with its own reviewer (docs/16 W4.8). No `xx-LONG` pass: the 150 % text-scale sweep (`test_a11y_legibility.gd`) is the layout proof that stands in for it until a translation exists. `Settings.ROWS` loses `glyph_set` and `language`, `GameSettings.DEFAULTS` the two keys (an old `settings.cfg`'s unknown keys are ignored — asserted); docs/13 §15.1 loses both rows and gains "One language (en-US) and keyboard + mouse in 1.0; localization and pad support are docs/16 W4.8 / C6"; OQ-12 closes; "Known limits" lists "English only" — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-134"></a>
### BL-134 - 1.0 ships unsigned; the README-player tells the player the two clicks; the zip's SHA-256 is in the release record *(DECIDED - W10-EXPORT · W10-README · W10-WALK)*

**Owner:** [14 §10.1](./14-technical-architecture.md) / [00 §4.4.2, §6.1](./00-vision-and-pillars.md) - **Signal:** SHIP-16: no row on signing; a certificate is money and a legal identity the tree does not have

`README-player.txt`, under "Known limits": "The .exe is not code-signed. The first time you run it Windows may show 'Windows protected your PC' — click **More info**, then **Run anyway**. Nothing is installed; the game keeps its saves and settings under %APPDATA%\Godot\app_userdata\A Guild Story\." Step 9 of `export_build.sh` prints `sha256sum` of the zip as its last line; W10-README copies the hash into the release commit's message and BUILD_STATE's wave-10 entry (it cannot live inside the zip it describes); W10-WALK records the SmartScreen prompt as seen on the second machine. SmartScreen's reputation is earned by downloads, as every itch.io release earns it. A certificate is post-ship — one `signtool` line between steps 8 and 9, filed in BACKLOG — if the designer buys one under a legal name — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-135"></a>
### BL-135 - The `new` and `play` fixtures carry no level; the reference fixture keeps its four levels as data and they stop rendering *(DECIDED - W6-SHEETS; the branches go in W10-DELETE per Q-14; `diff_all.sh` re-recorded at the wave-10 close)*

**Owner:** [art/ref/specs/00 §2.3](../art/ref/specs/00-canon-reconciliation.md) / `tools/fixture_reference.gd` - **Signal:** UI-15 / LOOP-01: "Bork Lv. 12" on every review sheet

`--fixture=new` and `--fixture=play` (`apply_new`/`apply_play`) carry `level` 0 everywhere and a legal Known state earned through `record_attempt`; every wave's review sheet from wave 6 on is `new` or `play` (the reviewer's one look is `build/shots/all/new/_sheet_1.png` with no "Lv."). The plain `--fixture` reproduces the concepts and keeps its `CARDS` levels 12/11/9/10 as DATA (`test_w0_shot.gd:144` pins "the concept's Lv. stays on the reference"); when W10-DELETE deletes the two `Lv. N` branches (Q-14) the four glyph runs stop rendering, and `diff_all.sh` is re-recorded once at the wave-10 close with before/after numbers in W10-README's entry (four "Lv. 12" runs on a 1536-wide sheet sit inside the 0.07 jitter). Spec 00 §2.3's "the card shows `Lv. N` only when `level > 0`" becomes "no level is shown" — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-136"></a>
### BL-136 - One bubble chrome; `SceneStage.EMOTE_MAP` is the one emote table, in two halves *(DECIDED - W9-ART; the Town mood pick by handoff to W9-POLISH; the RaidView line by handoff to W9-SCALE-2)*

**Owner:** [12 §5.3](./12-art-direction.md) / [art/ref/specs/07](../art/ref/specs/07-assets-sheet-a.md) / [05 §5](./05-morale.md) - **Signal:** Q04: two loose proposals (DESIGNER-29's seven rows, UI-41's ten)

One chrome everywhere — Concept 3's dark callout plate. `EMOTE_MAP.FIGHT` (over the figure the log line names, for the line's dwell): MINOR → `question`, MODERATE → `sweat`, SEVERE → `anger`, CRITICAL → `exclaim`, downed → `skull` (stays while down), the Bard's song → `note` (over the Bard) — canon's ❤️ 🙂 😒 😡 ladder read for one mistake instead of one raider; docs/12 §5.3's "!" is reserved for the loudest line. `EMOTE_MAP.MOODS` (`Town.set_mood()`, one at a time, priority top-down): `wipe` → the camp's skull, `cleared` → a new heart bubble, `at_risk` (any roster raider below 40 — docs/05's "noticeably higher mistake chance" band) → the camp's sweat bubble, which stops being ambient; `question`, `anger`, `exclaim`, `note`, `mug`, `zzz`, `dots` are the scene author's ambient decor. `stage_camp.json` gains the `at_risk` tag on the sweat bubble and one `[x, y, "emote:heart", "cleared"]` entry; `RaidView._line_effects` calls `stage.emote(id, EMOTE_MAP.FIGHT[sev])` on a MISTAKE line under `_effects_allowed`; UI-41's 24 px glyphs and `figure_scale` bubble sizing land with it; the cards keep the morale faces (BL-128). `test_scene_stage.gd`: every `Severity` has a fight glyph and every mood a bubble on the camp — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-137"></a>
### BL-137 - The header lockup is the 44 px mark plus the tagline; overhead bars are badge + pips on every figure and the HP bar on the acting or struck figure only *(DECIDED - as built)*

**Owner:** [art/ref/specs/00 §2.7](../art/ref/specs/00-canon-reconciliation.md) / [13 §8](./13-ui-ux.md) - **Signal:** Q05 / Q07

`Frame.LOCKUP = "44_tagline"` — "Questionable people. Worse decisions." is the premise in five words and the designer's own sentence; it belongs on every framed page. The overhead rule (UI-21's extension of Q07): class badge + pips on every figure, the full HP bar only on the acting or struck figure, the stack hidden on back ranks except that figure — how twelve overheads stay off the floor — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-138"></a>
### BL-138 - Five generated ambience beds ship — camp, tavern, market, cave, dungeon — keyed by scene through one door; the aerial plays the camp bed by design *(DECIDED - W7-AUD-AMB; `amb_cave` is the dungeon's shed-fallback, never the camp)*

**Owner:** [Q-98 (ii)](#q-98) / [13 §12.4](./13-ui-ux.md) - **Signal:** AUDIO-07's table left the dungeon on a campfire

`amb_dungeon`: the cave's 40-120 Hz hollow rumble, a chain-creak (`stick_slip` at 2-4 Hz, 1.2 s, every 9-17 s) and a distant stone fall every 20-40 s; no drip; 25 s, the same loop fold; all beds 44.1 kHz mono 16-bit, RMS −30 dBFS / peak ≤ −20, 600 ms equal-power crossfade. `Audio.BEDS` = {camp, tavern, market → their own; `stage_arena_cave` → `amb_cave`; `stage_arena_dungeon` → `amb_dungeon`; `stage_town` → `amb_camp`}; the door is the one line in `SceneStage.load()`. Raid 1 is the dungeon's reveal (Q-96) and a campfire under it would tell the ear the plate lied; the main menu hearing the guild's own fire before the player sees it is the right first sound for "you are the guild leader" — the aerial is the camp from above, not a placeholder; a town-aerial bed is post-1.0. `gen_amb.py --check` prints 5 AGREE; the dungeon bed is not the camp's bytes — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-139"></a>
### BL-139 - The encounter's comedy line stays on every Results page as the notice's epigraph under "The notice said:"; RaidView's exits stay live from round 1 *(DECIDED - `Results.COMEDY_LINE = "epigraph"`, W7-REPORT; `EXITS_GATED = false` as built)*

**Owner:** [01 §9](./01-core-loop.md) / [13 §11.2](./13-ui-ux.md) / [10 §7](./10-content-and-encounters.md) / [Q-53](#q-53) - **Signal:** COMBAT-20 / LOOP-10: a line about round 21 over a tally that reads "Rounds 6"

Q12b: the comedy line is authored encounter content (the UI must not rewrite it — option (c) refused) and hiding it on early wipes hides the writing where it is needed most (option (a) refused); labelled as the notice's it is the mission-brief-versus-outcome gag — the board said what was supposed to happen, the report says what did, and the distance is the joke. `Results.gd`'s builder adds one `LabelMuted` "The notice said:" above the existing `LabelQuote`, on the clear page too; `test_results_screen.gd` asserts the eyebrow. Q12c: the record exists before the first line plays (Q-53), so a lock on the exits protects nothing; the first-clear gate keeps governing Instant and "Skip to the end", which shape the default path rather than bar the door; the skip lock's decorative reading (LOOP-10) is accepted in writing and LOOP-10's routing change is not taken — the attempt is in Records and `active_run` replays it on Continue — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-140"></a>
### BL-140 - The Options screen's controls are the kit's lit cycle chips, the audio ladders as pips; no toggle, segmented control or slider ships *(DECIDED - as built; the Forgiving Guild row is an Off / On cycle on the same chip)*

**Owner:** [13 §7, §15.1](./13-ui-ux.md) / [art/ref/specs/06 §7](../art/ref/specs/06-ui-component-kit.md) - **Signal:** KIT-20 / Q14

The reference carries no slider and no switch, and the kit has one control for the job; a settings page in a paper-and-brass world that grows a modern slider would be the one screen that looks like a different game. `Settings._cycle_button()` and the `ROWS` table stay; W8-KEYS's `forgiving_guild` row uses `_cycle_button(key, false, ["Off", "On"])` with BL-113's sentence as its note; `test_options_layout.gd:370`'s count moves once per wave with the rows that wave adds (Forgiving, the scribe — one commit). Volume at six presses is accepted for 1.0 — the pips make the ladder legible; a slider is a 1.1 kit unit if players ask — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-141"></a>
### BL-141 - The two tutorials say their lesson where it happens: one band on RaidView, one line on the Tutorial Raid's wipe page *(DECIDED - `RaidView.TUTORIAL_BAND = true`, W7-REPORT; the words are data)*

**Owner:** [01 §8.1](./01-core-loop.md) / [10 §9](./10-content-and-encounters.md) / [BL-92](#bl-92) - **Signal:** Q15 / LOOP-30 / UI-55

Tutorials only: `RaidView._build()` adds one static `Widgets.callout` band above the log when `Reputation.is_tutorial_slot(encounter.slot)` and the record's `lesson` is non-empty (no round timing, nothing persisted); `Results` prints `lesson_report` above the tally on the Tutorial Raid's WIPE branch only (over a clear it would be false). The words, on `data/encounters_tutorial_t1.json`, never a literal in RaidView or Results: A0 `lesson` "Round three: somebody does something stupid. Watch for the stamp — the log says who, and why." (true by construction — BL-92's scripted round 3; if the scripted round ever moves, the word moves with it); TR `lesson` "One trick, one timer, one tank between six of them. When it goes wrong, the report says who."; TR `lesson_report` "This is the Wipe Report. Who, what, and which round — it is all under 'By raider'." — its last sentence dropped because TR's notice (Q-100) already ends "Read the Wipe Report; you will be seeing a lot of it." and the notice prints on the same page as the epigraph (BL-139): one punchline, once. `test_tutorials.gd` asserts the band's `Label.text` equals `lesson` on A0/TR and is absent on A1, and the Results line is absent on a clear — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-142"></a>
### BL-142 - Town focus entry is rail-first; the rail is the building ring *(DECIDED - as built; docs/13 §13.2 amended; RULES-06 closes)*

**Owner:** [13 §13, §13.2](./13-ui-ux.md) / [02 §10.2](./02-town-and-buildings.md) - **Signal:** Q10

Focus enters every screen on the rail's first item (`Frame.focus_entry` walks `FOCUS_REGIONS` rail-first; `a11y_smoke.gd` pins `rail[0]` on every route); the rail is the only element on all thirteen screens, so one habit serves the whole game, and it cycles the buildings docs/02 §10.2 asks the D-pad to cycle. The illustrated hotspots stay the mouse's door and are reachable by Tab into the scene region; they are not a second focus model; "last building visited" is not restored. docs/13 §13.2's hotspot-ring paragraph is rewritten in three sentences to say so — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-143"></a>
### BL-143 - Disband is recoverable, and an insolvent guild always finds a walk-in: one Common at 0 G per board refresh; no loan *(DECIDED - W8-CRISIS; `GameState.is_insolvent()` is the one predicate)*

**Owner:** [05 §6.3, §12 Q5](./05-morale.md) / [03 §6.5, §8.1 M1](./03-guild-reputation.md) / [00 A6](./00-vision-and-pillars.md) / [Q-10](#q-10) - **Signal:** SHIP-13 / LOOP-25: "recoverable" with New Guild as the only door is a run reset by another name

Disband as built: the roster is wiped; gold, buildings, unlocks and rank are kept; RP loses 10 % of what was earned inside the rank (`Reputation.rp_after_disband`); the Town says "The guild disbanded on day N. The tent is still yours, and so is the purse. The Tavern is up the road." with the Tavern as the one action; docs/05 §6.3's five guarantees land beside it. `GameState.is_insolvent()` = roster.size() < `RaidPlan.party_size(next_open_mission)` AND gold < the cheapest seat on the Tavern board (`Recruitment.cost_of` under `PRICE_SCALE` — 15 G for a Common at doc 11's; at Respected+ the cheapest seat is an Uncommon/Rare, which is exactly where the lock bites) AND `Economy.total_sell_price(pending_loot + worn gear, rank)` < that seat; `tools/playtest.gd:_can_still_make_progress` calls it (one owner). While it holds, `GameState.refresh_board()` appends one candidate beyond `board_slots()` itself — `Recruitment.generate(rng, Enums.Rank.UNKNOWN, tier)` (at Unknown the weights roll only Commons — canon's own rule, no forced-rarity parameter needed) — and records its id in `flags.walk_in_id` (the `flags` Dictionary W7-SAVE left open; no top-level save key, no field on `Raider`; `FROZEN_SHAPE` holds), so neither `sim/core/Recruitment.gd` (W8-ITEMS's file this wave) nor `sim/model/Raider.gd` (unowned) is edited; `GameState.hire()` skips the charge when the candidate's id is `flags.walk_in_id` and clears the flag; the Tavern card and the Board read the same flag; the card reads price "Free", quote "A walk-in. Will raid for a bed."; the Board prints "You cannot field a party and cannot afford a recruit. Someone at the Tavern will raid for a bed." Canon's "@Respected you no longer find common" describes who the guild FINDS; the walk-in finds the guild, and the card says so. A loan is refused — no debt ledger, no repayment mechanic, no field in a frozen save, and a guild in hock is not funny the way a walk-in is. A full roster with an empty purse never sees it (the roster clause), so it cannot become the on-ramp's crutch; the walk-in's morale is a rolled Common's, so a guild rebuilt from walk-ins is the slow, miserable, funny recovery the disband earned. Pinned by `test_game_state.gd` (roster 0 / gold 5 / empty inventory → one 0 G Common; hiring it costs nothing; a solvent board carries none) and `test_full_loop.gd` after a disband — ruled by the loop under the designer's 2026-09-15 delegation.

---

<a id="bl-144"></a>
### BL-144 - docs/10 §9.1's HP column and §9.2's trinkets, and docs/01 §8.2's reward, now say what the tree ships *(DECIDED - docs amended 2026-09-15, W7-DOCS; the data was already right)*

**Owner:** [10 §9.1, §9.2](./10-content-and-encounters.md) / [01 §8.2](./01-core-loop.md) / [09 §10.2](./09-items-and-itemization.md) (the stat blocks) - **Signal:** CONTENT-10: docs/10 printed 350 / 1,055 HP and "no tanks required" against data shipping 66 / 198 and `tanks_required: 1`; docs/10 §9.2 and docs/01 §8.2 named "Trinket of Mild Competence +1 Damage" / "Trinket of Faint Encouragement +1 AC" against docs/09 §10.2's Cracked Charm of Power +1 Power / Cracked Charm of Health +2 HP

Doc drift, not data drift: `data/encounters_tutorial_t1.json`'s `_notes` derive both departures and were right — the HP was stage-A arithmetic for two fights played at stage 0 ([BL-28](#bl-28)'s error, the same way), a literal 0 tanks is unauthorable (`RaidPlan.gd` reads `> 0`), and `+1 Damage` is not expressible on a trinket (docs/09 §12.2 restricts `damage` to weapons). The amendment: docs/10 §9.1 prints 66 / 198 with the stage-0 derivation and `tanks_required` 1, and says that [BL-110](#bl-110) re-sizes both rows once more (A0 61 · 20; TR 183 · 8 ×2 · M03) in W8-SIM-BALANCE — docs before data; docs/10 §9.2 and docs/01 §8.2 cite docs/09 §10.2's two rows by name, the names ruled final by [BL-119](#bl-119); the placeholders are struck in both. No number the tree ships moved; audit M5-TUT-01 / M5-TUT-04 / M5-TUT-13 (the data side) were already done - ruled by the loop under the designer's 2026-09-15 delegation.

---

<a id="bl-nnn"></a>
### BL-nnn - Every named mistake has its consequence: the numbers docs/07 §5.2 left to the sim *(🔷 PROPOSED - implemented behind named constants; W7-SIM-EFFECTS)*

**Owner:** [07 §5.2 rows 6-9, 15-17](./07-combat-simulation.md) / [07 §8.1-8.2](./07-combat-simulation.md) / [Q-57](#q-57) / [Q-58](#q-58) - **Signal:** SIM-07, SIM-15, SIM-17: eight types printed a line and changed nothing

docs/07 §5.2's effect column gives each type a direction; where it gives no number the sim
took one, each behind a name in `sim/core/RaidSim.gd` or `sim/core/Mistakes.gd`:

- **MIS_AFK** (row 9, "1-3 rounds, severity picks duration"): `RaidSim.AFK_ROUNDS_BY_SEVERITY`
  = Minor 1 / Moderate 2 / Severe 3 / Critical 3, the rounds AFTER the one the roll fell in
  (`Combatant.afk_until`); "Severe if tank or healer" is the taxonomy row's
  `severity_floor_if_tank_or_healer` applied in `Mistakes.roll`; "Aggro if tank" is
  `emits_if_tank`.
- **MIS_LOOT_CALL** (row 17): the raider's next action is skipped (`Combatant.skip_next_action`)
  and the sim counts it on the queued delta (`loot_call`); the post-encounter morale event
  is `Morale.TRIGGERS["loot_call"]` at −3, once per attempt — docs/05 §7.3's passed-over
  figure, the smallest negative loot row, because no doc prices a loot call.
- **MIS_ARGUMENT** (row 16, "both this raider and one random other"): the other is drawn on
  the seeded channel `argument` from the living raiders; both carry
  `Combatant.argument_penalty_bp` = `RaidSim.ARGUMENT_PENALTY_BP` 500 for the rest of the
  encounter, SET rather than stacked (a second argument does not double it — the cap on
  the situational term is docs/08's `SITUATIONAL_CAP_BP` and a stacking penalty would sit on
  it by round eight of a miserable raid).
- **MIS_NO_CONSUMABLE** (row 15): eligible only for a raider who CARRIES something
  (`Context.consumable_carried`), the same shape as MIS_FIRE's `zone_exists`; the kit /
  draught / Steady Hands bonus is stripped from that raider's profile and reported as
  `consumables_unspent` with reason `no_consumable`; the Guild Feast is eaten in town and is
  not a thing a raider carries.
- **MIS_HEAL_WRONG / MIS_HEAL_CORPSE / MIS_CHAIN_FIZZLE** (rows 6-8): the wrong-target heal
  lands on the highest-HP valid target (docs/07's wording over docs/06 §4.2's "random"), the
  corpse heal lands for 0 on the first corpse in slot order, the fizzled chain lands hop 1 on
  the neediest and hops 2-3 on the two fullest; every wasted heal is a NUMBERS-tier HEAL entry
  carrying `wasted`, and the healer takes threat only for what landed.
- **MIS_WRONG_TARGET** (row 11, "damage goes into a non-priority or immune target; priority
  target unharmed this round"): the swing lands on the first living ADD; with no add in the
  room the priority target is still unharmed and the swing is gone, as before. No number was
  taken — the raider's own `_outgoing_damage` is what lands. SIM-08's full priority table is
  wave 8's.
- **MIS_AGGRO** (row 2, "set above the current primary target"): the offender's threat becomes
  `ceil(top × threshold) + 1` at the offender's OWN `should_retarget` threshold (1.10 melee,
  1.30 ranged), so the pull always clears the hysteresis — SIM-17's `1.10 × top` would have
  left a Wizard's pull below the ranged bar.
- **Taunt** (docs/07 §8.1): the ACTIVE tank — the Warrior, or the Monk seated main tank when no
  Warrior came (docs/07 §8.3's auto-taunt) — spends its Phase 2 action on a Taunt when
  `tank_threat < 1.30 × highest_non_tank` (Tank Lead lost), setting threat to
  `ceil(1.10 × highest)`, cooldown `RaidSim.TAUNT_COOLDOWN_ROUNDS` 2; MIS_TAUNT_LAPSE on that
  tank is Lost Aggro ([Q-57](#q-57)).

Ruled by the loop under the designer's 2026-09-15 delegation; pinned in
`tests/unit/test_raid_sim.gd` (one test per row).

---

## Related documents

Filenames are the canonical ones from [00 §1.1](./00-vision-and-pillars.md).

- [00 — Vision & Pillars](./00-vision-and-pillars.md) — owns the pillars and anti-goals that Q-09 turns on, the scope envelope behind Q-13, and the corpus-provenance question in Q-21.
- [01 — Core Loop & Session Flow](./01-core-loop.md) — owns pacing, failure handling and the state machine that Q-09, Q-52 and Q-53 reshape.
- [02 — The Town & Its Buildings](./02-town-and-buildings.md) — owns the "maybe" decision table behind Q-13 and Q-14, and the navigation model in Q-67.
- [03 — Guild Reputation](./03-guild-reputation.md) — owns the six-rank ladder, so Q-22 through Q-26 and the monotonic-rank half of Q-10 land here.
- [04 — Recruitment & Roster Management](./04-recruitment-and-roster.md) — owns the roster cap (Q-12), recruit generation (Q-26 to Q-30) and gear binding.
- [05 — Morale](./05-morale.md) — owns the bands (Q-06, Q-07), the disband rules (Q-10), the day clock (Q-63) and the wishlist module (Q-70).
- [06 — Classes, Roles & Raid Composition](./06-classes-and-roles.md) — owns the class set, the Bard problem (Q-46), duplicates (Q-45), tank requirements (Q-47) and the benchmark comp (Q-20).
- [07 — Raid Simulation & The Mistake System](./07-combat-simulation.md) — owns round structure and the mistake system; source of Q-05's cadence conflict and Q-09's Calls conflict.
- [08 — Stats, Formulas & Numeric Model](./08-stats-and-formulas.md) — owns AC (Q-01), Mana (Q-02), base HP (Q-03), the mistake equation (Q-04) and the boss budget (Q-17). More blocking rows point here than anywhere else.
- [09 — Items & Itemization](./09-items-and-itemization.md) — owns every item record, so Q-32 to Q-44 and the loot model in Q-11 land here.
- [10 — Content Structure](./10-content-and-encounters.md) — owns the ladder and encounter design; consumer of Q-01, Q-03, Q-17 and Q-20, and source of the paperdoll fork in Q-19.
- [11 — Economy, Shops & Crafting](./11-economy-and-crafting.md) — owns prices and the crafting decision (Q-13, Q-60, Q-61, Q-62).
- [12 — Art Direction & Aseprite Pipeline](./12-art-direction.md) — owns the look that Q-15 enables and Q-19 prices; also Q-67's budget correction.
- [13 — UI/UX & Frontend Design](./13-ui-ux.md) — owns the screens that Q-06, Q-07, Q-11 and Q-12 all render; most of §6 is its backlog.
- [14 — Technical Architecture (Godot)](./14-technical-architecture.md) — owns the engine pin (Q-15), the storage policy (Q-16) and the sim-purity rule that Q-50 leans on.