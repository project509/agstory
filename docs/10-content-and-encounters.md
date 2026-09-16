# 10 — Content Structure: Adventures, Raids & Encounters

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs the content ladder the Adventure's Board lists, the difference between an Adventure and a Raid, the anatomy of a single encounter, and the mapping from encounter to loot slot.

## 1. Scope

**This doc owns:**

- The canon content ladder and its gating shape (which missions exist, in what order, at what difficulty).
- The definition of "Adventure" versus "Raid" — canon uses both words but never defines either.
- Encounter anatomy: the reusable spec sheet every encounter is authored against.
- The encounter → loot-slot mapping, and the cross-check that the raw notes and the per-class ideaboard tables agree on it.
- The reusable boss mechanic vocabulary, and which class each mechanic stresses.
- Tutorial content (Adventure 0, Tutorial Raid) and the canon skip rule.
- Repeatability and farming policy at the content level.
- The Tier 1–5 content budget: how many encounters, bosses, items and sprites the ladder actually costs.

**This doc does NOT own:**

| Topic | Owner |
|---|---|
| Round order, threat, targeting, mistake resolution, combat log | [07 — Combat Simulation](07-combat-simulation.md) |
| Damage / healing / mitigation formulas; base HP; the AC interpretation; the derived boss HP and swing budget | [08 — Stats, Formulas & Numeric Model](08-stats-and-formulas.md) |
| Item stat blocks, item families, unique item keys, trinket design | [09 — Items & Itemization](09-items-and-itemization.md) |
| Class kits, failure modes, raid composition rules | [06 — Classes & Roles](06-classes-and-roles.md) |
| Which reputation rank unlocks which tier; reputation earn rates | [03 — Guild Reputation](03-guild-reputation.md) |
| Morale, mistake *chance*, raider backstories | [04 — Recruitment & Roster](04-recruitment-and-roster.md) |
| Board UI, mission cards, town buildings | [02 — Town & Buildings](02-town-and-buildings.md) |
| Whether the content volume counted in §12 is affordable, and the 1.0 cut order | [00 — Vision & Pillars §6.3](00-vision-and-pillars.md) |
| Schedule and staffing for the content counted in §12 | ❓ **OPEN — no production doc exists in the set (docs 00–14).** See §14 Q14 |

**Boundary rule used throughout:** this doc decides *what is in an encounter*. Doc 07 decides *how a round resolves*. Doc 08 decides *how big a number is*. This doc prints **no** base HP, no mitigation rule, no boss HP and no raw-swing value of its own: it **cites** [doc 08](08-stats-and-formulas.md) §3.3, §6, §9.2, §9.3 and §9.5 and consumes those figures — see §5.

🔷 PROPOSED — **sibling filenames.** The numbered set has drifted across docs (doc 01 calls encounters "10 — Encounter Design", doc 02 calls them "05 — Adventures, Raids & Encounters"). Every link in this doc now points at the **shipped filename** in `docs/`, so citations resolve; the *titles* other docs use for the same file still differ. A single naming pass across all docs is still needed; flagged, not silently corrected elsewhere.

---

## 2. The canon content ladder

✅ CANON — reproduced verbatim from the raw notes, *Adventure's Board*. The parenthetical text is the designer's, not a gloss.

| # | Entry | Canon content (verbatim) |
|---|---|---|
| 1 | Adventure 0 | "1 Trash mob (Just for learning - 1 crap trinket)" |
| 2 | Tutorial Raid | "1 Boss (Just for learning - 1 crap trinket)" |
| 3 | Adventure 1 | "a few trash encounters and a mini boss" |
| 4 | Raid 1 | "Explained below" — the 5-encounter layout, §4 |
| 5 | Adventure 2 | "TBD ---" |
| 6 | Raid 2 | *(no description in canon)* |
| 7 | Adventure 3 | *(no description in canon)* |
| 8 | Raid 3 | *(no description in canon)* |
| 9 | Adventure 4 | *(no description in canon)* |
| 10 | Raid 4 | *(no description in canon)* |
| 11 | Adventure 5 | *(no description in canon)* |
| 12 | Raid 5 | *(no description in canon)* |

❓ OPEN — the ordering above is explicitly provisional. Canon, verbatim: *"This continues or can go raid raid, adventure adventure, obviously they will need names later, but this is a placeholder"*. Two consequences that are binding on the build:

1. **Cadence is not decided.** Adventure/Raid alternation must not be hard-coded. The board reads an ordered list of mission records from data; inserting `Raid 2b` between two Adventures must cost a data edit and nothing else.
2. **Naming is pending.** Every string ships as the canon placeholder — `Adventure 2`, `Raid 1`, `Boss 3`. Do not invent lore names, in code, in UI, or in asset filenames. Asset naming convention: `t1_raid_e3_miniboss` — tier and slot, never a name.

✅ CANON — tier unlocks are reputation-gated: *"New Tiers can be unlocked by gaining reputations with the town."* Which rank opens which tier is [doc 03](03-guild-reputation.md)'s call; see §14 Open Questions #1 for the arithmetic problem it inherits.

---

## 3. Adventure versus Raid

Canon never defines the distinction. It is *implied* by three canon facts:

| Canon fact | Source | What it implies |
|---|---|---|
| Adventure 1 is "a few trash encounters and a mini boss" — no main boss | raw notes, Adventure's Board | Adventures are shorter and top out below a Raid |
| Raid 1 is a fixed 5-encounter ladder ending in "Main boss of tier" | raw notes, Raid Layout | Raids are the tier centrepiece |
| Two separate gear families exist: "Tier 1 **Adventure** gear" and "Tier 1 **Raid** gear" | ideaboard §2 vs §3 | Adventure gear is the prerequisite for the Raid of the same tier |
| Recruits at Known arrive with "1-2 pieces of basic adventure gear from your current raid tier" | raw notes, Guild Reputation | Adventure gear is the assumed floor, Raid gear the aspiration |

🔷 PROPOSED — **the definition.** *Why this exists:* the player needs to know, from the board, whether a mission is a 4-minute money run or the thing they have been preparing a week for. One word on the card should carry that.

> An **Adventure** is short, half-headcount content that teaches one thing and pays in gold plus Adventure-tier gear. It is the gate and the funding for the Raid of the same tier.
> A **Raid** is the tier centrepiece: 12 raiders, five encounters, one main boss, and the only source of Raid-tier gear and reputation at scale.

| Axis | Adventure 🔷 | Raid ✅/🔷 |
|---|---|---|
| Encounters | 3 (2 trash + 1 mini boss) 🔷 | 5, fixed ✅ CANON (raw notes, Raid Layout) |
| Party size | 6 🔷 | 12 ✅ CANON ("I'd like the raid size to be 12") |
| Tanks required | 1 🔷 | 2 ✅ CANON ("most fights normally requiring 2 tanks") |
| Wall-clock, first clear | 3–4 min 🔷 | 6–8 min 🔷 (fits doc 01's 3–8 min micro loop) |
| Difficulty | ★ to ★★★ 🔷 | ★ to ★★★★★ ✅ CANON per encounter |
| Loot | Tier N **Adventure** gear ✅ CANON (ideaboard §2) | Tier N **Raid** gear ✅ CANON (ideaboard §3) |
| Gold | Primary gold source 🔷 | Secondary; loot is the point 🔷 |
| Reputation granted | Low, diminishing fast on repeat 🔷 | High; the main reputation engine 🔷 — rates in [doc 03](03-guild-reputation.md) |
| Repeatable | Yes, freely 🔷 | Yes, with duplicate protection 🔷 — §11 |
| Wipe cost | Cheap: morale hit only 🔷 | Expensive: morale + a full town cycle 🔷 (doc 01) |
| Purpose in the loop | Fund and prep | Progress the tier |

**Why 6 and not 12 for Adventures.** Two reasons. It halves the sim's actor count for content the player will re-run most often, which is the cheapest performance win available. And it makes Adventures a *roster* puzzle rather than a *gear* puzzle: with 6 slots you cannot bring one of everything, so you find out which six of your idiots actually function together. Canon fixes 12 for raids and says nothing about Adventures, so this is free design space.

---

## 4. Raid anatomy

✅ CANON — the 5-encounter structure, difficulty stars, and loot slots (raw notes, *Raid Layout and loot drops*), reproduced exactly:

| Encounter | Drops | Difficulty |
|---|---|---|
| Encounter 1 (Trash) | Feet + basic weapons | ★ |
| Encounter 2 (Harder trash) | Legs + healer off-hand | ★★ |
| Encounter 3 (Mini boss) | Head + stronger shared gear | ★★★ |
| Encounter 4 (Mini boss) | Chest + strong weapons | ★★★★ |
| Encounter 5 (Main boss of tier) | Class-specific + trinkets | ★★★★★ |

### 4.1 Cross-check against the per-class tables — they agree

This matters enough to state explicitly: **the loot slot mapping in the raw notes and the nine per-class Tier 1 Raid tables in the ideaboard transcription agree, item for item.** That agreement is what makes the loot system implementable as a single table lookup rather than 9 hand-authored drop lists. Verified cell by cell:

| Encounter | Raw notes says | Per-class tables actually contain (ideaboard §3.1–3.9) | Agrees |
|---|---|---|---|
| E1 ★ | Feet + basic weapons | Raider's Boots (W/B), Raider's Boots (M/R), Raider's Shoes (Healer), Raider's Slippers (M/Wiz); Basic Raid Sword, Basic Raid Dagger ×2, Basic Raid Staff ×3, Basic Healing Weapon | ✅ Yes |
| E2 ★★ | Legs + healer off-hand | Raider's Greaves (W/B), Raider's Leggings (M/R, Healer, M/Wiz); Blessed Raider's Tome | ✅ Yes |
| E3 ★★★ | Head + stronger shared gear | Raider's Helm, Raider's Headband, Raider's Eyepatch, Raider's Circlet, Raider's Cap | ✅ Head, yes — ❓ see below |
| E4 ★★★★ | Chest + strong weapons | Raider's Cuirass, Raider's Vest, Raider's Leather Vest, Raider's Vestments, Raider's Robe; Strong Raid Sword, Strong Raid Dagger ×2, Strong Raid Staff ×3, Strong Healing Weapon | ✅ Yes |
| E5 ★★★★★ | Class-specific + trinkets | Warrior Shield, Bard Instrument, Final Headband, Final Eyepatch, Cleric/Druid/Shaman Weapon, Mage Staff, Wizard Staff; Raid Trinket | ✅ Yes |

❓ OPEN — one dangling phrase. Raw notes give E3 "Head + **stronger shared gear**", but the transcription's own summary (§4) lists Boss 3 as `Head | —`, and no per-class table shows any second E3 drop. Either "stronger shared gear" is a loose synonym for the Head pieces themselves (which *are* shared: Healer Circlet across three classes, Cap across two), or an intended second E3 item family was never itemized. Not resolved here — see §14 Open Questions #2. Until it is, **E3 drops Head only**, and the drop-count budget in §7 assumes that.

### 4.2 The implementable form

🔷 PROPOSED — *Why this exists:* the whole loot system should be one join, not 45 authored lists.

```
drop_pool(tier, encounter) = all items WHERE item.tier == tier
                             AND item.slot IN slots_for(encounter)
rolls(encounter)           = E1:2  E2:2  E3:2  E4:3  E5:3 (+1 guaranteed Raid Trinket)
```

| Encounter | `slots_for` | Rolls | Notes |
|---|---|---|---|
| E1 | `feet`, `weapon_basic` | 2 | |
| E2 | `legs`, `offhand_healer` | 2 | |
| E3 | `head` | 2 | Head only, pending Open Question #2 |
| E4 | `chest`, `weapon_strong` | 3 | The fattest pool; 3 rolls keeps it from being a bottleneck |
| E5 | `capstone` | 3 + 1 | Trinket is guaranteed, not rolled |

❓ OPEN — **the join above needs unique item keys, and canon names collide.** `Raider's Leggings` is three different items (Monk/Rogue 5 AC/+6 HP/+1 Power; Healer 3/+4/+6 Mana; Mage/Wizard 3/+4/+8 Mana). `Basic Raid Staff` is three different items (+10 Monk, +11 Mage, +12 Wizard); `Strong Raid Staff` likewise (+14 / +15 / +16). And `Raider's Boots — 4 AC / +4 HP` appears with an identical name *and* identical stats under both Warrior/Bard and Monk/Rogue, whose armor families the matrix (ideaboard §1) otherwise keeps separate. So: one drop both families use, or two items that happen to share a name? The loot pool count for E1 changes either way. This doc keys items as `t{N}_{family}_{slot}` internally and shows canon names in UI unchanged. Item identity is [doc 09](09-items-and-itemization.md)'s to settle — §14 Open Questions #12.

**Gearing pace check.** A full clear yields 13 items. Fully kitting 12 raiders in Raid gear costs roughly 7 items each (4 armor, 1–2 weapons, 1 capstone, 1 trinket) ≈ 84 items → **~6.5 full clears per tier**, before duplicate protection (§11) shortens the tail. That is the number to argue about; it is a knob, and it lives here.

---

## 5. The Tier 1 numeric baseline

🔷 PROPOSED — every number in §5–§9 is a budget target **consumed from** [doc 08](08-stats-and-formulas.md), not published here. Doc 08 §1 claims "the derived boss budget those formulas imply"; this doc took that claim at its word and deleted its own competing base-HP table, mitigation rule, boss-HP figures and raw-swing figures. What remains below is (a) citations of doc 08's values and (b) the content-side arithmetic — swings per round, star escalation, enrage timers, mechanic magnitudes — that turns those values into an encounter. If doc 08 changes a value, this section changes with it and nothing here is re-authored.

### 5.1 Canon inputs

✅ CANON — the three stat definitions (raw notes, *Stat definitions*), verbatim: `AC = 2 damage reduction`, `Power = +1 melee dmg`, `Mana = spell damage (Subject to change)`. The parenthetical on Mana is canon and is not resolved here.

✅ CANON — the gear the player is expected to be wearing at Raid 1 entry is the Tier 1 Adventure set (ideaboard §2.5): Warrior/Bard **15 AC / +16 HP**, Monk **14 / +14**, Rogue **13 / +14**, Healer **9 / +12 / +13 Mana**, Mage/Wizard **8 / +10 / +17 Mana**.

### 5.2 Derived budget constants

| Constant | Value | Owner / derivation |
|---|---|---|
| Round length at 1× | 4 s | This doc. Back-solved from doc 01's 3–8 min micro loop across 5 encounters |
| Mitigation | `mitigation = (AC × 2) / ((AC × 2) + AC_K)`, `AC_K = 60`, capped at `MITIGATION_CAP = 0.75`; `taken = max(1, round(raw × (1 − mitigation)))` | [doc 08 §3.3](08-stats-and-formulas.md) **Reading 3**. This doc previously hard-coded the flat `taken = max(1, raw − 2 × AC)` reading, which doc 08 §3.2 analyses and rejects (under flat mitigation "at T1 Raid a hit that takes 8 rounds to kill the tank kills a Mage in 1.65") and whose §13 Q1 default is explicitly "Neither literal reading — use the ×2-numerator curve, Reading 3, `AC_K = 60`" |
| Base HP per class | [doc 08 §6](08-stats-and-formulas.md) — Warrior **120**, Monk **100**, Bard **90**, Rogue **85**, Cleric/Druid/Shaman **75**, Mage/Wizard **65** | Doc 08. `BASE_HP[Warrior]` is a doc 08 §11 tuning lever carrying the warning "changing this invalidates §9 wholesale". This doc publishes no base-HP table |
| Benchmark raid damage, Raid 1 entry | **175 per round** ([doc 08 §9.1](08-stats-and-formulas.md) stage A: 12 raiders in full Tier 1 Adventure gear, 175.3) | Doc 08. Assumes `MELEE_SWINGS = 2` and that the **Rogue dual-wields two Iron Adventurer's Swords** (doc 08 §13 Q9's default: "Yes, two swords") |
| Benchmark raid damage, Raid 1 full-clear geared | **~286 per round** (doc 08 §9.1, after Boss 5) | Doc 08 — ×1.63 over entry |
| Boss / encounter HP, Tier 1 Raid | [doc 08 §9.2](08-stats-and-formulas.md): E1 **2,200** · E2 **2,500** · E3 **3,200** · E4 **4,100** · E5 **7,150** | Doc 08 derives each from the stage DPS × its target fight length (12 / 13 / 15 / 17 / 22 rounds) |
| Enemy HP, non-boss content | `hp_total = benchmark_dps(party) × target_rounds` | Definitional; `benchmark_dps` comes from doc 08 §9.1 |
| Boss raw swing, **per round** | [doc 08 §9.3](08-stats-and-formulas.md): **61 / 63 / 65 / 68 / 73** | Doc 08 sizes each from `boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK × (1 − mitigation))`, `TANK_DEATH_CLOCK = 3.5` unhealed rounds. This doc splits that per-round figure across swings (§5.4) but never re-sizes it |
| Raid-wide pulse magnitude | `AOE_BITE_FRACTION × cloth_max_hp`, `AOE_BITE_FRACTION = 0.35` ([doc 08 §9.5](08-stats-and-formulas.md)) | Doc 08. Under this doc's AC-ignoring assumption (below) that product **is** the raw value; if AC applies, use doc 08 §9.5's grossed-up raw instead |
| Enrage timer | `ceil(1.4 × target_rounds)`; wipe by attrition fires at `enrage_round + 5` (`RaidSim.ATTRITION_GRACE_ROUNDS`, per-record `attrition_grace` — [15 BL-114](15-open-questions.md#bl-114)) | This doc, §10 M06; the grace is doc 07 §7.3's |

**Base HP is doc 08's, not this doc's.** Canon specifies HP only as gear bonuses, never a base. [Doc 08 §6](08-stats-and-formulas.md) publishes the one table; this doc's earlier, roughly halved table (Warrior/Bard 60, Monk 50, Rogue 45, healers 40, Mage/Wizard 35 — which also collapsed Bard into Warrior where doc 08 separates them at 90 vs 120) is **deleted**, and every survivability figure in §5.4, §7 and §8 is now computed against doc 08 §6. The totals used below, all from doc 08 §6 plus ✅ CANON gear: main tank **136** at Raid 1 entry rising to **144** (152 with the E5 Shield); Mage/Wizard **75** in Tier 1 Adventure gear, **81** in Tier 1 Raid gear; healers 87 → 94. If doc 10's smaller scale is ever preferred, it must be raised in [doc 08 §13 Q5](08-stats-and-formulas.md) and changed there once — not restated here.

**Healing throughput is stated as a requirement, not computed here.** The damage budget below fixes how much post-mitigation damage lands on the tank per round ([doc 08 §9.4](08-stats-and-formulas.md) checks the supply side against it). Doc 08 must then produce a healing formula whose 3-healer single-target throughput matches that figure at the Mana levels canon's gear actually provides. That constraint has teeth: ✅ CANON starting armor for common recruits carries **no Mana at all** (raw notes, *Starting armor*), and canon healer weapon stats are explicitly *"TBD until we establish the healing/Mana formulas"*. A purely Mana-derived heal is therefore **zero at game start**. Flagged in §14 Open Questions #11 — it is doc 08's problem, but this doc's Adventure numbers (§8) are what break if it is answered wrong.

### 5.3 Benchmark composition

🔷 PROPOSED — the fixed 12 used for every *content-side* statement in this doc. [Doc 06](06-classes-and-roles.md) owns composition *rules*; this is just the yardstick: **Warrior, Warrior, Cleric, Druid, Shaman, Rogue, Rogue, Monk, Mage, Wizard, Wizard, Bard.** Satisfies canon's 2-tank requirement, covers all three healing shapes, and includes a Bard so the Bard's contribution is never accidentally balanced out of the game.

❓ OPEN — **this comp is not doc 08's comp, and the DPS figure in §5.2 is doc 08's.** [Doc 08 §9](08-stats-and-formulas.md) derives its 175.3/round from **2 Warrior · 2 Monk · 2 Rogue · 1 Bard · 1 Mage · 1 Wizard · 1 Cleric · 1 Druid · 1 Shaman** — one Monk↔Wizard swap away from the list above. Two comps cannot both be the yardstick. Since doc 08 owns the arithmetic, **doc 08 §9's comp is authoritative for every number**, and the list above stands only as this doc's content-coverage wish (a Bard present, all three healing shapes present). Either doc 06 rules one comp canonical or doc 08 re-derives §9.1 against the list above; flagged in §14 Q16, not silently reconciled.

### 5.4 Boss damage budget — the escalation table

*Why this exists:* the tank's AC climbs inside a single tier as drops land (doc 08 §9.3: 17 → 18 → 19 → 21 → 23, including the ✅ CANON Charm of Armor, and 30 with the E5 Shield). Under doc 08 §3.3's curve an unchanging swing gets steadily cheaper across five encounters, so the swing must escalate with the star rating — and the escalation is what the star rating *means*.

**Every AC, mitigation, raw and tank-take figure in this table is quoted from [doc 08 §9.3](08-stats-and-formulas.md).** The only columns this doc contributes are `Swings/rd` (a content choice — more, smaller swings from E3 onward) and the per-swing figures that follow from dividing doc 08's per-round raw by it. `required_healing` is the single-target throughput doc 08 must deliver for the fight to be sustainable with no mistakes; doc 08 §9.4 already checks it.

| Enc | ★ | Tank AC (doc 08 §9.3) | Mit | Raw/rd (doc 08 §9.3) | Swings/rd 🔷 | Raw/swing | Post-mit/round = `required_healing` | Post-mit/swing on a Mage (8 AC, 75 HP) |
|---|---|---|---|---|---|---|---|---|
| E1 | ★ | 17 | 36.2% | 55 | 1 | 55 | 35.1 | 43.4 |
| E2 | ★★ | 18 | 37.5% | 58 | 1 | 58 | 36.2 | 45.8 |
| E3 | ★★★ | 19 | 38.8% | 62 | 2 | 31 | 38.0 | 24.5 |
| E4 | ★★★★ | 21 | 41.2% | 68 | 2 | 34 | 40.0 | 26.8 |
| E5 | ★★★★★ | 23 | 43.4% | 74 | 2 | 37 | 41.9 | 29.2 |

Three things fall out of that table, and all three are the game working as intended:

- **Post-mitigation damage on the tank rises 35 → 42 per round across the tier and never exceeds it.** That is doc 08 §9.3's 3.4–3.9-round unhealed death clock held nearly flat while gear improves. With healing tuned to §5.2's requirement, a geared tank never dies to autoattacks. A tank dies to *mechanics* and to *mistakes*.
- **E1 and E2 are one-swing bosses, and that is the deadliest shape for cloth.** A single 55–58 raw swing is 43–46 on a 75 HP Mage — more than half a caster's health in one hit. This is precisely doc 08 §9.5's finding ("an un-mitigated boss auto would kill a Mage in 1.7 rounds at Boss 1"), and it is why the threat system, not a damage cap, is what keeps cloth alive.
- **Splitting the swing from E3 onward is the lever that keeps a retarget survivable.** E5's 37 raw per swing is 21 to the tank and 29 to a Mage in Adventure gear (75 HP) or 26 to one in Raid gear (81 HP). So a single retargeted swing does not kill — but a retargeted swing *plus* that round's raid-wide pulse *plus* the next round's ground effect does. That is the payoff for the Warrior's failure mode, Lost Aggro (doc 06 §4.1), and it is why mistakes in this game read as compounding rather than instant.

🔷 PROPOSED — **Lost Aggro retargets one swing, not the round.** Doc 06 says "the boss's attack this round retargets". On a 2-swing boss that must mean swing 1 only, or every Warrior mistake at E3–E5 is an automatic caster death and the mechanic stops being interesting. Doc 07 owns the resolution order; this is the content-side assumption every number above depends on.

❓ OPEN — **does AC apply to spell and raid-wide damage?** Canon defines AC as damage reduction and never scopes it. Under doc 08 §3.3's curve a 30 AC Warrior mitigates 50% of every raid-wide pulse, which is less catastrophic than the flat reading's "takes 1" but still hands the tank's gear score a say in a healer-facing mechanic. This doc assumes **raid-wide damage ignores AC** so that the encounter's pressure lands on the healers, and therefore reads doc 08 §9.5's `AOE_BITE_FRACTION × cloth_max_hp` product as the pulse's raw value directly (26 at Raid 1 entry, 28 fully geared). If doc 08 rules that AC *does* apply, use doc 08 §9.5's grossed-up raw (33 → 41) instead and every M02 magnitude in §7 changes with it. Doc 08's call. Flagged in §14 Open Questions #3.

---

## 6. Encounter design template 🔷 PROPOSED

*Why this exists:* 42 encounters get built (§12). If each one is authored freehand, the sim needs 42 special cases and the loot table needs 42 exceptions. This is the spec sheet; anything an encounter needs that is not a field here is either a mechanic from the §10 vocabulary or a change request against doc 07.

| Field | Type | Rule |
|---|---|---|
| `id` | string | `t{N}_{adv\|raid}_e{n}` — tier and slot only, never a name |
| `display_name` | string | Canon placeholder (`Raid 1 — Encounter 3`). Naming pending, §2 |
| `tier` | 1–5 | |
| `slot` | E1–E5 (raid) / A1–A3 (adventure) | Determines the loot pool via §4.2 |
| `stars` | 1–5 | ✅ CANON for raid encounters; sets the swing budget from §5.4 |
| `party_size` | int | 12 raid / 6 adventure / tutorial override |
| `tanks_required` | int | Feeds doc 06's composition check |
| `enemies[]` | stat blocks | `name, count, hp, raw_swing, swings_per_round, threat_rule`. `hp` and the per-round raw total are **quoted from [doc 08 §9.2/§9.3](08-stats-and-formulas.md)**, never authored here; this doc only decides how they split across actors and swings |
| `mechanics[]` | mechanic IDs | From §10. Budget: **one mechanic per star**, no exceptions |
| `mistakes_invited[]` | class failure modes | Which doc 06 failure mode this encounter is *built to punish* |
| `loot_slots[]` | slot keys | From §4.2 — never authored per encounter |
| `target_rounds` | int | Raid bosses: doc 08 §9.2's target fight length (12 / 13 / 15 / 17 / 22 at Tier 1). Other content: `hp_total = benchmark_dps(party) × target_rounds` |
| `enrage_round` | int | `ceil(1.4 × target_rounds)` |
| `expected_clear` | seconds | `target_rounds × 4 s` |
| `fail_conditions[]` | list | Default: all 12 dead, or enrage expiry — `enrage_round` plus the grace of **5** rounds ([15 BL-114](15-open-questions.md#bl-114); the 40-round cap of doc 07 §7.3 stays the safety) |
| `comedy_line` | string | **Required.** One or two sentences: what makes this funny when it goes wrong. If it cannot be filled in, the encounter is a chore and should be cut. Amended from "one sentence" by [15 BL-76](15-open-questions.md#bl-76) — half the shipped lines are two, they are the better writing, and the rule was never enforced by anything |
| `force_mistake_round` | int, default 0 | §9.1's content-level override: on this round one raider makes a scripted Minor mistake regardless of the roll (implemented in `sim/core/RaidSim.gd`, picked from the seeded Rng — see [15](15-open-questions.md) W5-SIM entries). **Exactly one encounter may carry it** (Adventure 0, `3`); the loader refuses a negative value or one past `target_rounds` |

**The one-mechanic-per-star rule** is the load-bearing constraint. It makes difficulty legible on the board (three stars = three things to get wrong), it caps authoring cost, and it gives QA a checklist. A ★ encounter with four mechanics is a bug.

---

## 7. Worked examples — all five Tier 1 Raid encounters 🔷 PROPOSED

Names are canon placeholders. Enemy descriptors are functional, not lore.

**Reading these stat blocks.** Every `hp` total and every per-round raw total below is [doc 08 §9.2/§9.3](08-stats-and-formulas.md)'s figure, and `target_rounds` is doc 08 §9.2's target fight length. Two split rules are this doc's, and they matter:

1. **Doc 08's per-round raw is the encounter's tank-channel budget, not one actor's swing.** A four-mob pack therefore divides it four ways. The danger in a pack is not a big swing, it is four small swings that can all land on the same 8 AC caster.
2. **Add damage sits on top of that budget** and is sized off the cloth pool (doc 08 §9.5), because adds exist to pressure healers, not to out-damage the boss.

Enrage rounds below are all `ceil(1.4 × target_rounds)` per §5.2 / §10 M06, recomputed against doc 08's round counts — E1 `ceil(16.8)` = 17, E2 `ceil(18.2)` = 19, E3 `ceil(21)` = 21, E4 `ceil(23.8)` = 24, E5 `ceil(30.8)` = 31.

### 7.1 `t1_raid_e1` — Raid 1, Encounter 1 (Trash) ★

| Field | Value |
|---|---|
| Stars / slot | ★ / E1 ✅ CANON |
| Party | 12, 2 tanks |
| Enemies | Trash ×4 — 505 HP each (2,020), raw swing **15** each, 1 swing/round each · plus the round-5 add at 180 HP → **2,200 HP total** (doc 08 §9.2, Boss 1) |
| Raw budget | 4 × 14 = 56 raw/round ≈ doc 08 §9.3's **55** for Boss 1, divided across the pack |
| Threat rule | Standard threat; each mob attacks its own highest-threat target |
| Mechanics | **M04 Add Spawns** (1 extra mob joins on round 5) |
| Mistakes invited | Mage *Overpull*; Warrior *Lost Aggro* |
| Loot | `feet`, `weapon_basic` — 2 rolls ✅ CANON slots |
| Target rounds / clear | 12 / 48 s · enrage round 17 |
| Fail | All 12 dead, or enrage at round 17 |
| Comedy | Four mobs, two tanks, and a Mage who AoEs the pack he was told not to touch — the first wipe of the tier is a pull the player did not make. |

**Design note.** E1 is where the player learns that the *pack*, not the boss, is what kills a bad roster. Four separate threat tables means four separate chances for someone to be attacked who has 8 AC — and the arithmetic is the point: one 14 raw swing is 11 on a 75 HP Mage and harmless, but all four stacking on that Mage is 44 post-mitigation per round and a corpse in two.

### 7.2 `t1_raid_e2` — Raid 1, Encounter 2 (Harder trash) ★★

| Field | Value |
|---|---|
| Stars / slot | ★★ / E2 ✅ CANON |
| Party | 12, 2 tanks |
| Enemies | Elite ×2 — 1,100 HP each (2,200), raw swing **31** each, 1/round · Add ×4 — 75 HP, raw swing 8, 1/round → **2,500 HP total** (doc 08 §9.2, Boss 2) |
| Raw budget | 2 × 29 = 58 raw/round = doc 08 §9.3's **58** for Boss 2. Add damage (4 × 8) is mechanic pressure on top, sized off the cloth pool |
| Threat rule | Elites hold threat normally; adds spawn untargeted and attack the lowest-HP raider |
| Mechanics | **M04 Add Spawns** (2 adds every 4 rounds) · **M02 Raid-Wide Damage** (**26**, every 4th round, AC-ignoring — `0.35 × 75` cloth HP per doc 08 §9.5) |
| Mistakes invited | Druid *skipped heal*; Mage *Overpull* |
| Loot | `legs`, `offhand_healer` — 2 rolls ✅ CANON slots |
| Target rounds / clear | 13 / 52 s · enrage round 19 |
| Fail | All 12 dead, or enrage at round 19 |
| Comedy | Adds that hunt the weakest raider, in a fight where the Druid whose job is topping everyone up occasionally just… doesn't. |

**Design note.** This is the encounter that justifies the canon healer off-hand dropping here: it is the first fight where raid-wide damage exists, so the first fight where a healer's throughput is the binding constraint.

### 7.3 `t1_raid_e3` — Raid 1, Encounter 3 (Mini boss) ★★★

| Field | Value |
|---|---|
| Stars / slot | ★★★ / E3 ✅ CANON |
| Party | 12, 2 tanks |
| Enemies | Mini boss ×1 — 3,050 HP, raw swing **33**, 2 swings/round · Add ×3 — 50 HP, spawn on round 6 → **3,200 HP total** (doc 08 §9.2, Boss 3) |
| Raw budget | 2 × 31 = 62 raw/round = doc 08 §9.3's **62** for Boss 3 |
| Threat rule | Standard, with M01 overriding on stack 3 |
| Mechanics | **M01 Tank Swap** (debuff, +50% damage taken per stack, swap at 3) · **M02 Raid-Wide** (**27** / 4 rounds) · **M04 Add Spawns** |
| Mistakes invited | Monk *Panicked Stance*; Warrior *Lost Aggro*; Cleric *Wrong Target* |
| Loot | `head` — 2 rolls ✅ CANON slot (see §4.1 on "stronger shared gear") |
| Target rounds / clear | 15 / 60 s · enrage round 21 |
| Fail | All 12 dead, or enrage at round 21 |
| Comedy | The whole fight is "two tanks take turns", and the Monk's failure mode is picking the wrong stance at exactly the moment it is his turn. |

**Design note.** First fight requiring the canon 2-tank setup to actually *function* rather than merely exist. A raid that brought a Monk as its second tank (tank weight 0.5, doc 06 §7) survives E1 and E2 on tank AC alone and finds out here.

### 7.4 `t1_raid_e4` — Raid 1, Encounter 4 (Mini boss) ★★★★

| Field | Value |
|---|---|
| Stars / slot | ★★★★ / E4 ✅ CANON |
| Party | 12, 2 tanks |
| Enemies | Mini boss ×1 — **4,100 HP** (doc 08 §9.2, Boss 4), raw swing **34**, 2 swings/round |
| Raw budget | 2 × 34 = 68 raw/round = doc 08 §9.3's **68** for Boss 4 |
| Threat rule | Standard, interrupted by M08 Fixate every 5 rounds |
| Mechanics | **M03 Ground Effect** (**22**/round standing in it) · **M05 Interrupt Check** (round 4, then every 5) · **M08 Fixate** (5 rounds) · **M09 Healing Debuff** on the active tank |
| Mistakes invited | Rogue *Faced the Boss*; Wizard *Broke the Ramp*; Shaman *Bad Bounce*; Bard *Wrong Song* |
| Loot | `chest`, `weapon_strong` — 3 rolls ✅ CANON slots |
| Target rounds / clear | 17 / 68 s · enrage round 24 |
| Fail | All 12 dead, or enrage at round 24 |
| Comedy | An interrupt check in a game where you do not press the button — you just watch to see whether the Rogue you brought was facing the right way. |

**Design note.** Four mechanics is the star budget exactly. This is the fight that teaches the player that a raid is a *portfolio*: no single class covers all four, so the answer is roster breadth, which is the answer the Tavern sells.

### 7.5 `t1_raid_e5` — Raid 1, Encounter 5 (Main boss of tier) ★★★★★

| Field | Value |
|---|---|
| Stars / slot | ★★★★★ / E5 ✅ CANON |
| Party | 12, 2 tanks |
| Enemies | Main boss ×1 — **7,150 HP** (doc 08 §9.2, Boss 5), raw swing **37**, 2 swings/round |
| Raw budget | 2 × 37 = 74 raw/round = doc 08 §9.3's **74** for Boss 5 |
| Threat rule | Standard; M01 overrides at stack 3; M08 overrides for its duration |
| Mechanics | **M01 Tank Swap** · **M02 Raid-Wide** (**28** / 4 rounds) · **M03 Ground Effect** (**26**/round) · **M04 Add Spawns** (round 10, 20) · **M06 Enrage** (round 31, +100% damage) |
| Mistakes invited | All nine failure modes are reachable; Warrior *Lost Aggro* is the designed killer (§5.4) |
| Loot | `capstone` — 3 rolls + 1 guaranteed Raid Trinket ✅ CANON slots |
| Target rounds / clear | 22 / 88 s · enrage round 31 |
| Fail | All 12 dead, or enrage at round 31 |
| Comedy | Twenty-two rounds of your guild being *nearly* competent, and then Steve — morale 14, whom you brought anyway — stands in the fire on round 21. |

**Worked failure trace** (the one to show a programmer — every input is doc 08's, every step is arithmetic):

> Round 20, and it is also a raid-wide pulse round (M02 fires on 4, 8, 12, 16, 20). Baseline: the boss swings 37 raw twice; the Warrior at 23 AC mitigates 43.4% and takes 21 + 21 = **41.9**, healed for 41.9 → net 0 on a 144 HP tank. Sustainable forever, and doc 08 §9.4 confirms the supply exists (Cleric ~44 plus the Shaman's first bounce 28). Now the Warrior rolls a mistake: *Lost Aggro*, threat zeroed, swing 1 retargets to the second-highest threat, a fully ramped Wizard at 13 AC (30.2% mitigation) and 81 HP. Swing 1: `37 × 0.698` = **26**, Wizard at 55. Swing 2 lands on the Warrior for 21. Then M02 fires: **28** raid-wide, AC-ignoring → Wizard at 27. The Shaman's chain would have saved it, but the Shaman is healing the tank the Cleric already topped up (*Bad Bounce*, doc 06 §4.4). Round 21's ground effect — 26/round — finishes the Wizard. Raid damage drops 286 → ~236/round, rounds-to-kill on the remaining boss HP stretches by about a fifth, and the round-31 enrage is suddenly live. **No single event killed anybody. Two mistakes and a scheduled mechanic did** — which is exactly the shape of failure this game is about, and the log has to make all three lines legible (doc 07 owns log formatting).

**Wall clock check.** 48 + 52 + 60 + 68 + 88 = **316 s ≈ 5.3 min of sim** for a full Tier 1 clear, which lands inside §3's 6–8 min once interstitials (S13) and the results screen (S12) are counted. The previous, self-derived budget totalled 312 s — so adopting doc 08's round counts costs the pacing nothing and buys a single owner.

---

## 8. Adventure anatomy 🔷 PROPOSED

*Why this exists:* canon describes exactly one Adventure ("a few trash encounters and a mini boss") and marks Adventure 2 as TBD. A single reusable shape lets Adventures 2–5 be data, not design work.

**The gear assumption that sets the numbers.** Adventure tier N is played in tier N−1's gear. So Adventure 1 is played in ✅ CANON *starting armor for common recruits* — Warrior **7 AC**, Mage **4 AC** — not in Adventure gear, which is what Adventure 1 exists to hand out. Under [doc 08 §3.3](08-stats-and-formulas.md) Reading 3 that is **18.9%** mitigation for the tank and **11.8%** for the Mage. And note what canon's starting armor does *not* carry: **no HP and no Mana on any piece**, so an Adventure-1 Warrior is doc 08 §6's base 120 HP flat and an Adventure-1 Mage 65 HP flat.

**The benchmark — RESOLVED, and the gap is closed.** This section previously sized every rung against **~88 per round** (half of [doc 08 §9.1](08-stats-and-formulas.md)'s stage A) while flagging that figure as an upper bound, because stage A is *full* Tier 1 Adventure gear and Adventures are played below it. Doc 08 has now published the missing stages in **[§9.1a](08-stats-and-formulas.md)**, measured by §9.1's own nominal method on this section's own benchmark six:

| Rung | Fought in | Nominal party DPS | `hp_total` |
|---|---|---|---|
| A1 | ✅ CANON starting armour | **16.5** | 16.5 × 8 = 132 |
| A2 | + A1's `feet` + first weapon | **54.9** | 54.9 × 10 = 549 |
| A3 | + A2's `legs` | **58.2** | 58.2 × 12 = 698 |

**Each rung is sized for the gear the rung before it dropped** — which is precisely the rule [doc 08 §9.2](08-stats-and-formulas.md) already applies to the raid tier (*“the boss is fought in the gear the boss before it dropped”*). The old single figure was **5.3× too high for A1**, which made Adventure 1 unwinnable at any HP. §14 Q17 is closed.

Swings are sized from doc 08 §9.3's own rule, `boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK × (1 − mitigation))`, applied to a 120 HP / 7 AC tank: at `TANK_DEATH_CLOCK = 3.5` that is 42 raw/round, which is A3's budget exactly. A1 and A2 sit on deliberately longer clocks.

| Slot | Type | Stars | Enemies (Tier 1) | Raw/rd | Post-mit/rd on a 7 AC tank | Unhealed clock | Target rounds | Mechanics | Loot |
|---|---|---|---|---|---|---|---|---|---|
| A1 | Trash | ★ | 3 × 45 HP (**135**), raw swing 9 each, 1/rd | 27 | 21.9 | 5.5 rd | 8 | M04 (**12** HP add) | Adventure `feet` + `weapon` |
| A2 | Harder trash | ★★ | 2 × 275 HP (**550**), raw swing **19** each, 1/rd | **38** | 29.2 at 9 AC | 4.3 rd | 10 | M04 (**44** HP add), M02 (**15** / 4 rds) | Adventure `legs` |
| A3 | Mini boss | ★★★ | 1 × **700** HP, raw swing **25**, 2/rd | **50** | 36.6 at 11 AC | **3.5 rd** | 12 | M01, M02 (**15**), M03 | Adventure `head` + `chest` |

Each row is sized at **its own** gear stage: 16.5 × 8 = 132 → 3 × 45 = 135; 54.9 × 10 = 549 → 2 × 275 = 550; 58.2 × 12 = 698 → 700. The round budget is unchanged at 8 + 10 + 12 = 30, so a full clear is still ≈ **2 min of sim**, 3–4 min with the report screens.

**Two knock-on corrections the re-sizing forced, both measured:**

1. **M04 add HP scales with the pull.** At 705 HP the A1 add was 8% of the fight; left at 60 against the re-derived 135 it would have been **44%**, changing the encounter's *shape* as well as its size. Adds are held at their original fraction: A1 60 → 12, A2 70 → 44.
2. **M02's magnitude is 15 here, not §9.5's 23** — see [doc 15 BL-29](15-open-questions.md). The 23 sizes *survivability per target* correctly (`0.35 × 65` cloth HP) but its healing-coverage assumption is a **12-raid with three healers**: a proc costs 23 × 12 = 276 carried by 3 healers, i.e. 92 each. At party 6 with **one** healer — this section's own assumption — the same magnitude costs 23 × 6 = 138 carried by one, a **1.5× heavier burden per healer**. Holding raid-wide damage *per healer* constant gives 92 / 6 ≈ **15**. Measured, 23 killed the party outright in A2 and A3 rather than out-timing it.

**A3's auto-swing was RAISED to 50 raw/round — by §9.3's own formula rather than against it.** See [doc 15 BL-30](15-open-questions.md). This section applied `boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK × (1 − mitigation))` at **7 AC / 120 HP for all three rungs**, while its own loot column says each rung is fought in the gear the one before it dropped. Restoring the intended clocks at the real stages:

| Rung | Fought at | Tank | Mitigation | Intended clock | Raw/rd needed | Was | Now |
|---|---|---|---|---|---|---|---|
| A1 | stage 0 | 7 AC / 120 HP | 18.9% | 5.5 rd | 26.9 | 27 | **27 — already correct** |
| A2 | after A1 | 9 AC / 123 HP | 23.1% | 4.3 rd | 37.2 | 34 | **38** |
| A3 | after A2 | 11 AC / 127 HP | 26.8% | 3.5 rd | 49.6 | 42 | **50** |

**A1 needed no correction**, because it is the one rung genuinely fought at stage 0 — which is exactly why this section got A1 right and only A2 and A3 wrong. The *method* was sound; it was applied at one stage instead of three.

✅ **RESOLVED — and this warning was right about the cause, slightly wrong about the size.** It read: *“A3 demands 34.1 post-mitigation per round of single-target healing against a party carrying one healer — and that healer is in ✅ CANON starting armor, which carries 0 Mana … It is unmeetable under a Mana-only heal. Do not soften A3's swing to hide it — it is doc 08's healing formula that has to move.”*

Doc 08's formula moved, exactly as instructed: **[§8.5a](08-stats-and-formulas.md)** adds a `HEAL_FLOOR` so a weaponless, 0-Mana healer is no longer decorative, and **A3's swing is untouched at 42 raw/round**.

Two corrections to the warning's own arithmetic, both measured:

- **34.1 was the stage-0 figure.** A3 is fought at the *after A2* stage, where the tank wears Adventure feet and legs — **11 AC, 26.8% mitigation, so 42 raw is 30.7 post-mitigation**, not 34.1. The warning applied starting-armour mitigation to a fight nobody reaches in starting armour, overstating the requirement by 11%.
- **The healer is not in starting armour either.** A1 drops the first *weapon*, so by A3 the healer holds an Adventure healing weapon (`heal_base` 14). The staged reading is what makes A3 answerable.

Measured after the fix, at morale 55 with each rung in its own stage's gear: **A1 50% clear, A2 65%, A3 90%**. ❓ OPEN — that curve is *inverted* against the ★/★★/★★★ rating, because A3's party is 3.5× stronger than A1's while A3's incoming damage is only 1.6× heavier. Tracked as [doc 15 BL-30](15-open-questions.md); it is a shaping problem, not a blocker.

✅ CANON anchor — the Tier 1 Adventure loot that these three encounters must distribute is fully specified (ideaboard §2.1–2.4 armor; raw notes for weapons and the four Adventure charms). The A1/A2/A3 slot split above is 🔷 PROPOSED; canon assigns Adventure loot to *the Adventure*, not to encounters within it.

❓ OPEN — canon says only "Adventure 2 TBD ---" and gives Adventures 3–5 no content at all. This doc proposes they reuse the A1/A2/A3 shape at their tier's numbers. Whether Adventures should diverge in *structure* at higher tiers (a 5-encounter Adventure? a no-boss gold run?) is undecided — §14 Open Questions #4.

---

## 9. Tutorial content

✅ CANON — two entries, verbatim: *"Adventure 0 - 1 Trash mob (Just for learning - 1 crap trinket)"* and *"Tutorial Raid - 1 Boss (Just for learning - 1 crap trinket)"*.

✅ CANON — the skip rule, verbatim: *"Tutorials can be skip, but will offer a special loot piece that is easy, players will be warned that they will miss out on reward if they skip tutorial (not a big deal - not a great piece) Like a +1 dps trinket or something"*.

### 9.1 What each teaches

🔷 PROPOSED — canon fixes the content, not the teaching order.

| Mission | Canon content | Party 🔷 | Teaches | Encounter spec |
|---|---|---|---|---|
| Adventure 0 | "1 Trash mob" | 4, pre-made, `tanks_required` 1 (a literal 0 is unauthorable — the register's per-fight tank ruling: default 2, tutorials 1) | Roster select → confirm → watch the sim → read a mistake in the log → equip a drop | 1 × **66** HP, raw swing 20, 1/round, no mechanics, target rounds 6, enrage 9 |
| Tutorial Raid | "1 Boss" | 6, pre-made, 1 tank | A real fail state: a boss with one mechanic, an enrage timer, and the Wipe Report | 1 × **198** HP, raw swing 15, 2/round, **M01 Tank Swap**, target rounds 12, enrage 17 |

**The HP column is re-derived at stage 0 ([15 BL-28](15-open-questions.md#bl-28); amended 2026-09-15, [BL-144](15-open-questions.md#bl-144)).** This table used to print 350 and 1,055, derived from "~58/round for 4 (⅓ of doc 08 §9.1 stage A) × 6" and "~88/round for 6 × 12" — stage A figures, full Tier 1 Adventure gear, for two fights played at stage 0 because nothing has dropped yet; BL-28 found the same error for A1-A3. The rule is §8's, `hp_total = benchmark_dps(party) × target_rounds`, at [doc 08 §9.1a](08-stats-and-formulas.md)'s stage-0 row (2.75 per raider): 2.75 × 4 × 6 = 66 and 16.5 × 12 = 198, which is what `data/encounters_tutorial_t1.json` ships and its `_notes` derive. The raw swings are not re-derived: 20 ×1 and 15 ×2 are doc 08 §9.3's stage-0 tank clock and are well under §8's starting-armor budget on purpose — a tutorial demonstrates a fail state, it does not impose one, and the Tutorial Raid's 30 raw/round is a 4.9-round unhealed clock on a 120 HP tank rather than doc 08's 3.5. **[BL-110](15-open-questions.md#bl-110) re-sizes both rows once more** (A0 61 · 20; TR 183 · 8 ×2 · M03 in place of M01 — [Q-100](15-open-questions.md#q-100)) by doc 08's new §9.3a healed clock at morale 45; that edit and §8's table are W8-SIM-BALANCE's, docs before data, and this table follows them then.

🔷 PROPOSED — **Adventure 0 scripts one guaranteed mistake** on round 3 regardless of morale rolls. The premise of the game is that your raiders are bad; the player must see that in the first 30 seconds, not infer it from a probability table. Doc 04 owns mistake chance; this is a content-level override flag on the encounter record (`force_mistake_round: 3`), and it exists on exactly one encounter in the game.

❓ OPEN — canon fixes raid size at 12 but Adventure 0 is one trash mob. Party sizes above are proposed; doc 01 flagged the same gap. See §14 Open Questions #5.

### 9.2 The two crap trinkets

Canon gives "1 crap trinket" to each tutorial and names one example: "+1 dps trinket or something". These must be *visibly* worse than the canon Tier 1 Adventure charms (✅ CANON: Charm of Health +7 HP, Charm of Armor +2 AC, Charm of Mana +10 Mana, Charm of Power +2 Power) or the skip warning is a lie.

Each is exactly half, or less, of the weakest canon Adventure charm. **The two items are [doc 09 §10.2](09-items-and-itemization.md)'s** — doc 09 owns item stat blocks, and `+1 Damage` is not expressible on a trinket at all (doc 09 §12.2 restricts `damage` to weapons): the names below are §11.3's template names, ruled final by [15 BL-119](15-open-questions.md#bl-119) ("the trinkets are Cracked Charm of Power / Health"). This section's earlier placeholders ("Trinket of Mild Competence +1 Damage", "Trinket of Faint Encouragement +1 AC") are struck ([BL-144](15-open-questions.md#bl-144)); doc 01 §8.2 cites the same rows.

| Mission | Reward (doc 09 §10.2) | Stat | Rationale |
|---|---|---|---|
| Adventure 0 | Cracked Charm of Power | +1 Power | Half the canon Charm of Power (+2); canon's "+1 dps trinket" in effect |
| Tutorial Raid | Cracked Charm of Health | +2 HP | Well under the canon Charm of Health (+7 HP), so the comparison tooltip does the arguing |

### 9.3 Skip implementation

| Rule | Spec |
|---|---|
| Warning copy | Must name the forfeited item and its stat, and state plainly that it is not good. Honesty is the joke |
| Granularity | Per tutorial, not global — skipping Adventure 0 does not skip the Tutorial Raid ✅ (canon says "Tutorials", plural, are skippable) |
| Forfeit | Permanent for the mission skipped 🔷 |
| Re-run | 🔷 PROPOSED: a skipped tutorial stays on the board and is replayable for gold, but its trinket is gone for the run |

❓ OPEN — canon gives "1 crap trinket" to *both* tutorials, but the skip paragraph says "a special loot piece", singular. Two trinkets or one? This doc assumes two (one per mission) because that is what the mission list says twice. Quoted in §14 Open Questions #6.

---

## 10. Mechanic vocabulary 🔷 PROPOSED

*Why this exists:* five tiers × 8 encounters is 40 encounters. A small team builds that by combining twelve mechanics, not by inventing eighty. Every mechanic below is a parameterised behaviour doc 07 implements once and content authors only configure.

| ID | Mechanic | Spec (parameters) | Class stressed | Mistake it invites |
|---|---|---|---|---|
| M01 | **Tank Swap** | Debuff on current tank: +50%/stack damage taken, 1 stack per hit, swap required at 3 | Warrior, Monk | Monk *Panicked Stance*; Warrior *Lost Aggro* |
| M02 | **Raid-Wide Damage** | `X` damage to all living raiders every `N` rounds, ignores AC (❓ §5.4). `X = AOE_BITE_FRACTION × cloth_max_hp`, 0.35 per [doc 08 §9.5](08-stats-and-formulas.md) — never authored per encounter | Druid, Shaman | Druid *skipped heal*; Shaman *Bad Bounce* |
| M03 | **Avoidable Ground Effect** | `X`/round to raiders flagged in-zone; a raider re-rolls out at `p` per round | Rogue, melee | Rogue *Faced the Boss* |
| M04 | **Add Spawns** | `count` adds of `hp`/`swing` on round `R`, repeating every `N`; adds target lowest-HP raider | Mage | Mage *Overpull*; Wizard *Broke the Ramp* |
| M05 | **Interrupt Check** | Boss casts on round `R`; unless ≥1 melee DPS is in position, effect `E` fires | Rogue, Monk | Rogue *Faced the Boss*; Monk *Panicked Stance* |
| M06 | **Enrage Timer** | At round `ceil(1.4 × target_rounds)`, boss damage ×2 permanently | Whole raid's DPS | None directly — it prices every earlier mistake |
| M07 | **Positioning Requirement** | Fight demands Spread or Stack for `N` rounds; wrong state costs `X` per off-position raider | Mage, Wizard | Wizard *Broke the Ramp* |
| M08 | **Fixate** | Boss ignores threat for `N` rounds and chases a random raider | Cleric | Cleric *Wrong Target* |
| M09 | **Healing Debuff** | Healing on the current tank reduced `p%` for `N` rounds | Cleric, Shaman | Cleric *Wrong Target*; Shaman *Bad Bounce* |
| M10 | **Silence Window** (Mana Burn's drain half is 1.1) | For `N` rounds, casters and healers cannot act — the silence half ships (`RaidSim`'s M10 arm); "lose `X` Focus per round" is the drain half, `drain` on the record (default 10), live from 1.1 with the Focus pool ([15 BL-87](15-open-questions.md#bl-87); `MANA_BURN_DRAIN_ENABLED := false`; audit M5-T25-12 / DW-C1) | Mage, Wizard, healers, Bard | Bard *Wrong Song* |
| M11 | **Frontal Cleave** | `X` damage to all melee-positioned raiders each round | Rogue, Monk, Warrior | Rogue *Faced the Boss* |
| M12 | **Escalating Swing** | Boss raw swing +`X` per round, no cap — a soft enrage | Warrior + healers | Any; it compresses the margin for all of them |

**Coverage rule 🔷.** Every tier's Raid must use at least one mechanic that stresses each of the four role groups (tank / healer / melee DPS / caster) before E5. Otherwise a tier can be beaten by one lopsided roster, and the Tavern stops being interesting. Tier 1 as specified in §7 satisfies this: M01 (tank), M02+M09 (healer), M03+M05 (melee), M04 (caster).

**Tier escalation rule 🔷.** A tier introduces at most **two** mechanics the player has not seen. Tier 1 uses M01–M06, M08, M09. Tiers 2–5 add M07, M10, M11, M12 and then recombine. New tiers get harder by *number and overlap* of mechanics, not by novelty — which is also the only way 5 tiers fit the budget in §12.

---

## 11. Repeatability & farming ❓ OPEN

Canon says nothing at all about re-running content, duplicate drops, or pity. Everything in this section is a proposal against a silent canon.

🔷 PROPOSED — *Why this exists:* the loop in doc 01 needs a gold faucet that does not require new content, and a bad drop week needs a remedy other than quitting.

| Rule | Proposal |
|---|---|
| Re-run Adventures | Freely, unlimited |
| Re-run Raids | Freely once cleared; per-encounter entry allowed after that encounter's first clear (matches doc 01's skip-unlock rule) |
| Gold on repeat | 100% every time — this is the intended faucet |
| Loot on repeat | 100% roll rate, subject to duplicate protection below |
| Reputation on repeat | Diminishing. Curve owned by [doc 03](03-guild-reputation.md); this doc only asserts it must diminish, or reputation gating stops gating |
| Duplicate protection | An item the guild already owns **2** copies of is removed from the roll pool for that encounter |
| Pity counter | Per encounter, per class-slot: after **5** clears with no item that class can use, the next clear force-drops one |
| Tutorials | Replayable for gold; the trinket is one-time (§9.3) |

**Why "2 copies" and not "1".** Twelve raiders, and canon's item families are shared: three healers compete for one Circlet, two casters for one Cap, Monk and Rogue for the same Leggings. Locking a family out after one copy would starve the second and third user of that family. Two is the smallest number that respects the canon sharing model in ideaboard §1.

❓ OPEN — is farming *supposed* to be a strategy, or a safety net? If the former, repeat clears want a difficulty/reward escalation (a "heroic" toggle). If the latter, keep it flat and boring on purpose. §14 Open Questions #7.

---

## 12. Content budget, Tier 1–5 🔷 PROPOSED

*Why this exists:* nobody can schedule "five tiers". These are the counts, derived from §3, §4 and §8, with the reuse strategy that makes them survivable.

❓ OPEN — **these counts have no schedule owner.** They were previously handed to a "16 — Production Roadmap" that does not exist: the shipped set is docs 00–14, and no other doc references a doc 15 or 16. Interim assignment, pending a real owner: [doc 00 §6.3](00-vision-and-pillars.md) already carries the content-volume envelope and the 1.0 cut order, so it owns **whether this volume is affordable**; the counts themselves stay here because they fall out of §3, §4 and §8. **Nobody owns schedule or staffing.** See §14 Q14.

### 12.1 Encounters and actors

| Item | Per tier | × 5 tiers | Tutorials | Total |
|---|---|---|---|---|
| Adventure encounters (A1–A3) | 3 | 15 | 1 (Adventure 0) | **16** |
| Raid encounters (E1–E5) | 5 | 25 | 1 (Tutorial Raid) | **26** |
| **Encounters total** | **8** | **40** | **2** | **42** |
| Unique boss actors (1 Adv mini + 2 Raid mini + 1 Main) | 4 | 20 | 1 | **21** |
| Unique trash actors | 5 | 25 | 1 | **26** |
| Encounter records to author | 8 | 40 | 2 | **42** |

### 12.2 Items

Counted from canon for Tier 1, then held constant per tier. ✅ CANON counts:

| Family | Tier 1 Adventure | Tier 1 Raid |
|---|---|---|
| Armor pieces | **17** — W/B 4, Monk/Rogue 5, Healer 4, Mage/Wizard 4 | **18** — W/B 4, Monk/Rogue 6, Healer 4, Mage/Wizard 4 |
| Weapons | **7** — 4 named + 3 healer weapons (stats ❓ TBD in canon) | **12** — basic ×6, strong ×6 |
| Off-hands / capstones | — | **10** — Shield, Instrument, Final Headband, Final Eyepatch, 3 class healer weapons, Mage Staff, Wizard Staff, Blessed Raider's Tome |
| Trinkets | **4** — the canon Adventure charms | **1** canon entry ("Raid Trinket", no stats) — 🔷 proposed to resolve to 4 universal Raid charms |
| **Per tier** | **28** | **41 canon entries / ~44 as proposed** |

| Line | Per tier | × 5 tiers |
|---|---|---|
| Distinct item records | ~72 | **~360** |
| Distinct item **icons** if every item gets one | ~72 | **~360** |
| Distinct item icons **with per-slot-family reuse + per-tier recolor** | ~18 base shapes | **~18 shapes × 5 palettes = 90 renders** |

**The reuse strategy is not optional.** 360 hand-drawn icons is not a small-team number; 18 shapes recoloured per tier is. The canon item naming already implies exactly this — `Iron Adventurer's Boots` → `Raider's Boots` is the same silhouette in a different palette. Lock the 18 base shapes at Tier 1 and treat tier identity as palette, not geometry.

### 12.3 Sprites and animation

**Counts here are [doc 12](12-art-direction.md)'s, multiplied out.** The previous version of this table under-counted doc 12 on two rows and silently contradicted it on a third; both are corrected below so §12 and doc 12 §5–§6 can be diffed at a glance.

| Asset class | Count | Reuse strategy |
|---|---|---|
| Raider battle sprites | 9 classes × **8 tags** (`idle`, `walk`, `attack`, `cast`, `hit`, `death`, **`fumble`**, `cheer`) = **72 clips** — doc 12 §5.2, whose per-class frame total is 42 on a combat body / 48 with `walk`, i.e. **378 combat frames** for the base cast | Tag names are load-bearing (they drive doc 12 §7.3's export). `fumble` is **not optional**: doc 12 §5.3 makes it the single animation the comedy lands on, and this doc's whole premise (§6's mandatory `comedy_line`) fails without it |
| Gear layer sets | **~87 at Tier 1** (doc 12 §5.5: 36 body-armour + 18 head + ~33 weapon/off-hand sets), each authored across all 42 frames of the body it attaches to | Doc 12 §5.5: "Gear is not baked into body sheets." The ✅ CANON sharing model (ideaboard §1) is what keeps this to 87 rather than 9 × every slot. ❓ **The paperdoll-versus-palette-swap decision is unresolved — §14 Q15** |
| Legendary raiders | 9 bespoke named characters | Doc 12 §5.4: reuse the class body sheet, replace gear/weapon/FX layers + 1 bespoke portrait each ≈ 9 layer sets + 9 portraits, **not** 378 new frames |
| Trash actors | 26 × (idle, attack, hit, death) = 104 clips | 6 base silhouettes, recoloured and rescaled per tier |
| Boss actors | 21 × (idle, attack, special, hit, death) = 105 clips | 5 base silhouettes + per-tier palette; bosses get one bespoke `special` clip each — this is where the art budget should go |
| Raid environments | 5 raids × (~3 painted plates + 5 L3/L5 dressing sets + 5 lighting grades + 1 bespoke E5 arena) = **~15 plates, 25 dressing sets, 25 grades, 5 bespoke arenas** | Doc 12 §6.3's per-raid unit cost ("~3 painted plates, 5 dressing sets, 5 grades, plus boss sprites"), ×5. Encounter 4 reuses Encounter 3's arena damaged; Encounter 5 does **not** reuse anything |
| Adventure environments | 5 × (reuse of the tier's raid plates + 3 dressings) = **~15 dressing sets, 0 new plates** 🔷 | Proposed here, not in doc 12: Adventures are the same tier as their raid, so they should read as the same place earlier in the day |
| Tutorial backdrops | **2** (Adventure 0, Tutorial Raid) | Doc 12 §6.3 flags these as "easy to forget", plus a visibly worthless trinket icon each (§9.2) |
| **Environment total** | **~15 painted plates · ~40 dressing sets · 25 lighting grades · 5 bespoke arenas · 2 tutorial backdrops** | The previous line here read "10 backdrops = 5 environments × 2 lighting states" — under doc 12 §6.3 that is low by more than a factor of two on plates and by five on grades |
| Item icons | 90 renders (§12.2) | 18 shapes × 5 palettes |

🔷 PROPOSED per-tier art constraint, held here until a production owner exists: **one palette, one boss silhouette, one environment identity per tier.** If a tier needs more than that, it needs a schedule conversation — with whoever ends up owning §14 Q14.

---

## 13. After Raid 5 — the completion gap ❓ OPEN

*Why this exists:* nothing in the doc set says what the game **is** once Raid 5 is cleared, and no doc owns the question. There is no completion state anywhere: [doc 13](13-ui-ux.md)'s screen inventory runs S01–S16 with no victory, completion or credits screen, and [doc 03 §7](03-guild-reputation.md)'s Legendary row for content unlocked reads "❓ OPEN — canon's content list ends at Raid 5 with 'This continues'".

The gap has a sharp edge in doc 03. Its §6.4 pacing puts Legendary rank **exactly on** "the full clear of Raid 5", and its §5.2/§5.4 raise the Legendary find chance from 1.5% to **5%** at that rank specifically because collecting nine Legendaries at Renowned's rate "takes ~600 recruits — too slow". So as the set currently reads, the reward for finishing the game is a recruit-quality upgrade with no content left to spend it on. Doc 03 Q5 flags the *rank* half of this; nobody owns the endgame itself, and §11's farming rules are explicitly a "safety net", not an endgame.

Four assertions, all 🔷 PROPOSED. Only the content-ladder half is this doc's to decide; the rest are one-line cross-references to the owning doc.

| # | Item | Proposal | Owner |
|---|---|---|---|
| 1 | **The completion beat** | A victory/report screen and credits fire on the **first clear of Raid 5, Encounter 5**. Doc 13's screen inventory must gain it as **S17 — Completion / credits**; this doc asserts only that the beat exists and where it fires | [doc 13](13-ui-ux.md) owns the screen |
| 2 | **Does the save continue?** | Yes. The save continues past the completion beat, and the continuing activity is threefold: Legendary collection to **9 of 9** (✅ CANON "You can only ever find 1 Legendary per class"), achievement completion against [doc 02 §4.4](02-town-and-buildings.md)'s ~40-achievement record wall, and repeat clears under §11's flat rewards, duplicate protection and pity counter | this doc (content) + doc 02 (achievements) |
| 3 | **Legendary rank's 5% find rate** | **Accepted ([15 BL-122](15-open-questions.md#bl-122), 2026-09-15):** the collection metagame IS the endgame — the 5% and the 3200 RP threshold stand, nothing is retimed; with five tiers mounted ([BL-121](15-open-questions.md#bl-121)) Renowned pays and the rule has a 1.0 player. Cross-reference [doc 03 §5.4](03-guild-reputation.md), which now says so | [doc 03](03-guild-reputation.md) |
| 4 | **Tier 6** | **No Tier 6 ships in 1.0.** [Doc 00 Q5](00-vision-and-pillars.md): "1.0 ships the 12 listed entries and stops at Raid 5; further tiers are post-launch." ✅ CANON's "This continues" is therefore post-launch scope, not a 1.0 obligation, and §12's counts are sized for exactly five tiers | [doc 00 §6.3](00-vision-and-pillars.md) |

**What this doc will not do:** invent Tier 6 content, or a prestige/heroic difficulty, to fill the gap. §14 Q7 already defaults farming to "safety net, no heroic mode in v1", and adding an endgame mode is a scope decision for the lead designer, not a consequence of an audit. See §14 Q13.

---

## 14. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| 1 | 6 reputation ranks (Unknown → Legendary) but tutorials + 5 tiers of content. Which rank gates which tier? | Decides whether Tier 5 is reachable at Renowned or requires Legendary, i.e. whether the last rank has any content behind it | **Owned by [doc 03 §7](03-guild-reputation.md)**, not here: T1 at Unknown (Adventure 0, Tutorial Raid, Adventure 1, Raid 1) through T5 at Renowned (Adventure 5, Raid 5); **Legendary is a prestige rank** (doc 03 Q5). This doc's earlier default — Renowned → T4, Legendary → T5 — put the whole fifth tier behind a rank doc 03 §6.4's pacing awards only *on the clear of Raid 5*, which is unreachable. Deleted. If the shifted ladder is preferred, doc 03 §7 and its §6.4 pacing table must change **together** so Legendary arrives before Raid 5 |
| 2 | E3's canon "stronger shared gear" has no referent in any per-class table | Changes E3's drop pool and the §4.2 gearing pace from 6.5 clears to ~5 | Read it as describing the Head pieces themselves (which are shared families). E3 drops Head only |
| 3 | Does AC reduce spell and raid-wide damage, or only physical swings? | If AC applies universally, a 28 AC tank takes 1 from every raid-wide pulse and healers become decorative | Raid-wide and spell damage ignore AC. Doc 08 owns it |
| 4 | Do Adventures 2–5 keep the 3-encounter shape, or diverge in structure? | 4 encounter records versus a bespoke design pass per tier | Keep A1/A2/A3 at each tier's numbers; revisit only if a tier needs a distinct hook |
| 5 | Party size for Adventure 0 and the Tutorial Raid | Canon fixes 12 for raids; fielding 12 against "1 Trash mob" is absurd and the tutorial has no Tavern yet | 4 for Adventure 0, 6 for the Tutorial Raid, both pre-made |
| 6 | One tutorial trinket or two? | One reward record versus two, and the exact wording of the skip warning | Two — one per tutorial, per the mission list |
| 7 | Is farming a strategy or a safety net? | Decides whether repeat clears need a difficulty/reward escalation at all | Safety net. Flat rewards, duplicate protection, pity counter. No heroic mode in v1 |
| 8 | Does the "Raid Trinket" resolve to 1 universal item or 9 class items? | 1 item record versus 9, and whether E5's trinket is ever a duplicate | 4 universal Raid charms mirroring the canon Adventure charms; doc 09 sets stats |
| 9 | Do E1/E2 trash packs have a wipe *cost* distinct from a boss wipe? | If not, the player will always pull trash carelessly and the ★ rating means nothing | Same cost; the deterrent is time and morale, not a special penalty |
| 10 | Is `target_rounds` measured against entry gear or full-clear gear? | A 25-round E5 becomes an 18-round E5 once geared; enrage timers must not become free | Entry gear, as in §5. Enrage stays at `1.4 ×` the entry-gear figure, so farming genuinely feels easier |
| 11 | Healing scales off Mana, but canon starting armor has **0 Mana** and healer weapon stats are canon-TBD. What heals the party in Adventure 1? | Every damage figure in §5.4 and §8 assumes healing can meet `required_healing`. At 0 Mana a Mana-only formula heals nothing and Adventure 1 is unwinnable | A flat class base plus a Mana term: `heal = base_class + k × Mana`, base non-zero. Doc 08 owns `base` and `k` |
| 12 | Canon item names collide across families (§4.2): three distinct `Raider's Leggings`, three distinct `Basic Raid Staff`, and a `Raider's Boots` identical in name and stats across two separate armor families | Decides the E1 drop pool size and whether the loot join can be a single table lookup at all | Internal keys `t{N}_{family}_{slot}`; canon display names untouched. Treat the duplicate Boots as **one** shared item until doc 09 rules |
| 13 | **Does clearing Raid 5 end the run, or open a completion phase, and what does the player do in it?** | No doc in the set has a completion state: doc 13's screens stop at S16, doc 03 §7's Legendary content cell is OPEN, and doc 03 raises the Legendary find rate to 5% at the exact moment there is nothing left to recruit for | §13's proposal: a completion beat (doc 13 gains S17), then the save continues; the post-clear activity is Legendary collection to 9-of-9, achievements (doc 02 §4.4) and flat repeat clears under §11. **No Tier 6 in 1.0** (doc 00 Q5) |
| 14 | **Who owns the per-tier art and schedule budget?** (one palette + one boss silhouette + one environment identity per tier) | §12's 42 encounters, 21 boss actors, 26 trash actors, ~360 item records and 90 icon renders have no owner who converts them into a schedule. **No production doc exists** — the set is docs 00–14, and the "doc 16" this section used to name was never written | ❓ OPEN. Interim: [doc 00 §6.3](00-vision-and-pillars.md) owns the *volume* envelope and its cut order; §12.3 holds the per-tier art constraint. **Schedule and staffing have no owner** and this needs a decision, not a default |
| 15 | **Paperdolling: layered gear per doc 12 §5.5, or palette-swap only?** | This is not a documentation conflict, it is a real cost fork, and the two docs currently answer it differently | ❓ OPEN — **lead designer's call, resolved in neither doc.** (a) Layered gear per [doc 12 §5.5](12-art-direction.md): **~87 layer sets at Tier 1**, each authored across all 42 frames of the body it attaches to, and doc 12 states flatly "Gear is not baked into body sheets". (b) Palette-swap only: **0 extra layer sets**, but **no visible gear progression on the sprite** — a fully raid-geared Warrior looks like a naked one in a different colour, in a game whose loop is gear acquisition. §12.3 previously budgeted (b) while doc 12 mandates (a); neither doc gets to decide |
| 16 | Which 12 is *the* benchmark comp — this doc's §5.3 list or [doc 08 §9](08-stats-and-formulas.md)'s (one Monk↔Wizard swap apart)? | Doc 08's 175.3/round raid DPS, and therefore every boss HP value in doc 08 §9.2 that §7 now consumes, is computed against doc 08's comp | Doc 08 §9's comp is authoritative for all arithmetic; §5.3's list stands only as a content-coverage wish. Doc 06 should rule one of them canonical, or doc 08 re-derives §9.1 |
| 17 | What is raid DPS in ✅ CANON **starting** armor, with no weapon? | [Doc 08 §9.1](08-stats-and-formulas.md)'s earliest stage is *full Tier 1 Adventure gear*, but Adventure 1 and both tutorials are played below it — §8's ~88/round for a party of 6 is an upper bound, so A1–A3 may be over-HP'd | Doc 08 adds a stage-0 row (starting armor, no weapon) to §9.1 and §8 cites it. Do not invent the figure here |

---

## Related documents

- [00 — Vision & Pillars](00-vision-and-pillars.md) — §6.3's content-volume envelope and cut order, which §12's counts must fit inside; Q5 fixes 1.0 at Raid 5, which is what §13 leans on.
- [01 — Core Loop & Session Flow](01-core-loop.md) — the 3–8 minute micro loop this doc's encounter timings are back-solved from, and the tutorial threading.
- [02 — Town & Buildings](02-town-and-buildings.md) — the Adventure's Board UI that lists the §2 ladder; it must stay data-driven because the cadence is undecided. §4.4's achievement wall is half of §13's post-clear activity.
- [03 — Guild Reputation](03-guild-reputation.md) — **owns** which rank unlocks which tier (§7), the pacing that makes Legendary a prestige rank (§6.4, Q5), and the diminishing-returns curve §11 depends on.
- [04 — Recruitment & Roster](04-recruitment-and-roster.md) — mistake *chance*; §9.1's single scripted-mistake override is the only content-side exception.
- [06 — Classes & Roles](06-classes-and-roles.md) — the nine failure modes named in every `mistakes_invited` row, and the composition rules the §5.3 benchmark comp must satisfy.
- [07 — Combat Simulation](07-combat-simulation.md) — implements the §10 mechanic vocabulary once, and owns the combat log that has to make the §7.5 failure trace readable.
- [08 — Stats, Formulas & Numeric Model](08-stats-and-formulas.md) — **owns** base HP (§6), the AC interpretation (§3.3 Reading 3), raid DPS (§9.1), boss HP (§9.2), boss swings (§9.3) and AoE sizing (§9.5). §5, §7 and §8 of this doc quote those and publish none of their own.
- [09 — Items & Itemization](09-items-and-itemization.md) — the item stat blocks §4 maps encounters onto, plus the unresolved Raid Trinket and healer weapon stats. ⚠️ Its §2 currently names **doc 07** as the owner of the AC interpretation; the owner is [doc 08 §3](08-stats-and-formulas.md), and doc 07 §1 itself defers every formula to doc 08. That line in doc 09 needs correcting — flagged here, not editable from this doc.
- [12 — Art Direction](12-art-direction.md) — **owns** the animation tag set (§5.2), the `fumble` contract (§5.3), the gear-layer model (§5.5) and the per-raid environment cost (§6.3) that §12.3 multiplies out.
- [13 — UI/UX](13-ui-ux.md) — the S01–S16 screen inventory that §13 asks to extend with S17 (completion / credits).
- [14 — Technical Architecture](14-technical-architecture.md) — the Godot data shape the §6 encounter template serializes into.
