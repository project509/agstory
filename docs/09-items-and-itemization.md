# 09 — Items & Itemization

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document defines every equippable item in A Guild Story — the slot model, the item families that decide who competes for a drop, the exact Tier 1 stat tables, and the rules that generate Tiers 2–5.

## 1. Scope

**This doc owns:**

- The equipment slot model and per-class slot availability.
- Item families and the drop-competition (sharing) model.
- Every Tier 1 item table: starting gear, Adventure gear, Raid gear, weapons, trinkets.
- Item naming convention and item identity (ID + data schema).
- The tier-scaling rule that generates Tiers 2–5 from Tier 1.
- Loot routing at the point of drop (who receives an item).

**This doc does NOT own:**

- What AC / HP / Power / Mana *resolve to* numerically → [08 — Stats, Formulas & Numeric Model](08-stats-and-formulas.md)
- What those stats *do* during a fight → [07 — Raid Simulation & The Mistake System](07-combat-simulation.md)
- Morale consequences of loot awards and wishlists → [05 — Morale](05-morale.md)
- Which encounter exists in which raid, encounter difficulty, and **drops per encounter** → [10 — Content Structure: Adventures, Raids & Encounters](10-content-and-encounters.md)
- Class abilities, roles, and why a class wants a stat → [06 — Classes, Roles & Raid Composition](06-classes-and-roles.md)
- Vendors, sell prices, crafting, salvage → [11 — Economy, Shops & Crafting](11-economy-and-crafting.md)
- Recruit rarity, what gear a recruit arrives holding, and **gear binding / what a departing raider keeps** → [04 — Recruitment & Roster Management](04-recruitment-and-roster.md)
- Resource format, loading, and validation in engine → [14 — Technical Architecture (Godot)](14-technical-architecture.md)

> Sibling filenames follow the doc-number index; if a doc is renamed, update the links here.

---

## 2. Stat model

✅ CANON — verbatim stat definitions (canon: raw notes, *Stat definitions*):

```
AC = 2 damage reduction
Power = +1 melee dmg
Mana = spell damage (Subject to change)
```

✅ CANON — the four stats that appear on items are **AC**, **HP**, **Power**, **Mana**, plus **Damage** on weapons (canon: ideaboard §2 column headers; raw notes, *Weapons*).

❓ OPEN — `AC = 2 damage reduction` is ambiguous: it can read as "each point of AC removes 2 damage" or "the whole AC stat converts at a 2:1 rate". At Tier 1 the difference on a raid-geared Warrior (21 AC of armor, §8.11) is 42 damage reduced versus 10. With the Boss 5 Warrior Shield equipped (28 AC) it is 56 versus 14. Resolution belongs to [08 — Stats, Formulas & Numeric Model](08-stats-and-formulas.md) §3 / Q1; itemization only needs the number to stay stable.

❓ OPEN — `Mana = spell damage (Subject to change)` makes Mana simultaneously a caster damage stat and (by name) a resource pool. Canon also puts **+20 Mana** on the Bard Instrument, a support class with no stated spell damage. Flagged, not resolved.

---

## 3. Slot model

### 3.1 The equipment slot matrix

✅ CANON — reproduced exactly (canon: ideaboard §1, `Screenshot_2026-08-27_033817.png`):

| Class | Main Hand | Off Hand | Head | Chest / Legs / Feet | Trinket |
|---|---|---|---|---|---|
| Warrior | Warrior/Rogue/Bard 1H | Warrior Shield | Warrior | Warrior/Bard | Universal |
| Monk | 2H Monk Weapon | — | Monk Headband | Monk/Rogue | Universal |
| Rogue | Warrior/Rogue/Bard 1H | Warrior/Rogue/Bard 1H | Rogue Eyepatch | Monk/Rogue | Universal |
| Cleric | Cleric Weapon | Healer Off-Hand | Healer | Healer | Universal |
| Druid | Druid Weapon | Healer Off-Hand | Healer | Healer | Universal |
| Shaman | Shaman Weapon | Healer Off-Hand | Healer | Healer | Universal |
| Bard | Warrior/Rogue/Bard 1H | Instrument | Warrior/Bard | Warrior/Bard | Universal |
| Mage | 2H Mage Staff | — | Mage/Wizard | Mage/Wizard | Universal |
| Wizard | 2H Wizard Staff | — | Mage/Wizard | Mage/Wizard | Universal |

### 3.2 Formal slot list

🔷 PROPOSED — *why this exists: the matrix collapses Chest/Legs/Feet into one column, but the loot tables drop them on three different encounters, so the build needs them as three distinct slots.*

| # | Slot key | Display | Notes |
|---|---|---|---|
| 1 | `main_hand` | Main Hand | Always occupied. A 2H item fills `main_hand` and locks `off_hand`. |
| 2 | `off_hand` | Off Hand | Absent for Monk / Mage / Wizard. |
| 3 | `head` | Head | ✅ CANON slot. |
| 4 | `chest` | Chest | ✅ CANON slot (ideaboard §2 rows). |
| 5 | `legs` | Legs | ✅ CANON slot. |
| 6 | `feet` | Feet | ✅ CANON slot. |
| 7 | `trinket` | Trinket | One per raider. See §9.2 for contention. |

🔷 PROPOSED — **seven slots, no more.** No rings, no cloak, no belt. Rationale: canon drops exactly seven slot-types across the five encounters of a tier, so a raider is fully geared by clearing one tier. Adding slots means adding drop sources, which means changing the five-encounter raid shape owned by doc 10.

### 3.3 Per-class exceptions the matrix encodes

✅ CANON, all five (canon: ideaboard §1 and its *Observations* block):

| Exception | Classes | Consequence for the build |
|---|---|---|
| No off-hand at all (2H main hand) | Monk, Mage, Wizard | `off_hand` is hidden, not empty, in the character sheet. |
| Dual-wields the shared 1H family | Rogue | Rogue equips two items from `Warrior/Rogue/Bard 1H`; needs two copies. |
| Off-hand is a Shield | Warrior | Shield is a defensive item (canon Boss 5 Shield gives 7 AC / +8 HP / +1 Power). |
| Off-hand is an Instrument | Bard | Instrument is a Mana item (canon Boss 5 Instrument = +20 Mana). |
| Shared Healer Off-Hand | Cleric, Druid, Shaman | One off-hand family, three classes competing. |

❓ OPEN — **No Adventure-tier off-hand exists in canon for any class.** The Warrior Shield, the Bard Instrument, and the Healer Off-Hand (Blessed Raider's Tome) all first appear inside the Tier 1 *Raid*. Until then Warrior, Bard, and the three healers have a visible empty off-hand for the whole Adventure phase. Proposed default: add an Adventure-tier off-hand per family (§10.2).

---

## 4. Item families and drop competition

### 4.1 Why this section exists

The matrix is not a UI spec — it is a **contention table**. Its real output is: *when item X drops, which of my raiders raise their hand?* That is what makes loot a decision and therefore what makes the wishlist/morale lever in doc 05 work at all.

### 4.2 Inverse table: family → who wants it

🔷 PROPOSED presentation of ✅ CANON data (canon: ideaboard §1). "Demand" = number of classes; "Copies wanted" counts Rogue's two hands.

| Family | Slots it fills | Classes competing | Demand | Copies wanted |
|---|---|---|---|---|
| Universal (Trinket) | trinket | Warrior, Monk, Rogue, Cleric, Druid, Shaman, Bard, Mage, Wizard | **9** | 9 |
| Warrior/Rogue/Bard 1H | main_hand, off_hand (Rogue) | Warrior, Rogue, Bard | 3 | **4** |
| Healer (armor) | head, chest, legs, feet | Cleric, Druid, Shaman | 3 | 3 |
| Healer Off-Hand | off_hand | Cleric, Druid, Shaman | 3 | 3 |
| Warrior/Bard (body armor) | chest, legs, feet | Warrior, Bard | 2 | 2 |
| Monk/Rogue (body armor) | chest, legs, feet | Monk, Rogue | 2 | 2 |
| Mage/Wizard (armor) | head, chest, legs, feet | Mage, Wizard | 2 | 2 |
| Warrior/Bard (head) | head | Bard — and Warrior? see §4.4 | 1–2 | 1–2 |
| Warrior (head) | head | Warrior (per matrix) | 1 | 1 |
| Monk Headband | head | Monk | 1 | 1 |
| Rogue Eyepatch | head | Rogue | 1 | 1 |
| Warrior Shield | off_hand | Warrior | 1 | 1 |
| Instrument | off_hand | Bard | 1 | 1 |
| 2H Monk Weapon | main_hand | Monk | 1 | 1 |
| 2H Mage Staff | main_hand | Mage | 1 | 1 |
| 2H Wizard Staff | main_hand | Wizard | 1 | 1 |
| Cleric Weapon | main_hand | Cleric | 1 | 1 |
| Druid Weapon | main_hand | Druid | 1 | 1 |
| Shaman Weapon | main_hand | Shaman | 1 | 1 |

### 4.3 The sharing groups, named

✅ CANON groups (canon: ideaboard §1):

1. **Warrior/Bard armor** — chest, legs, feet shared between the two plate users.
2. **Monk/Rogue armor** — chest, legs, feet shared between the two leather users.
3. **Healer armor** — head *and* body shared across Cleric, Druid, Shaman. The only family where the head is shared by three classes.
4. **Mage/Wizard armor** — head *and* body shared between the two cloth casters.
5. **Universal trinkets** — one family, all nine classes.

🔷 PROPOSED design read: contention is deliberately front-loaded on **trinkets** (9-way) and **1H weapons** (4 copies wanted from 1 family). Those two are where loot arguments live; everything else is at most a 3-way. Keep it that way when authoring Tiers 2–5.

### 4.4 The Head-slot asymmetry

✅ CANON — the matrix gives Warrior a Head family of `Warrior` (its own) while giving Bard a Head family of `Warrior/Bard` (canon: ideaboard §1, rows *Warrior* and *Bard*). The transcription itself calls this out: *"Note the asymmetry between Head and Chest/Legs/Feet for Warrior: Head is 'Warrior' alone while Chest/Legs/Feet is 'Warrior/Bard'."*

❓ OPEN — **is that asymmetry intentional?** The item tables contradict it in two places:

- The Adventure armor table is titled **"Warrior / Bard Armor"** and its Head row is a single item, `Iron Adventurer's Helm — 3 AC / +3 HP`, with no Warrior-only or Bard-only variant (canon: ideaboard §2.1).
- The Tier 1 Raid tables give Warrior *and* Bard the same Boss 3 head, `Raider's Helm — 5 AC / +5 HP / +1 Power`, name and stats identical (canon: ideaboard §3.1, §3.2).

So the matrix says the Warrior head is its own family, and every authored item says it is shared. Two readings:

| Reading | Implication | Cost |
|---|---|---|
| **A — shared head (tables are right)** | Delete the `Warrior` head family; Warrior and Bard compete for one helm. Head sharing then matches body sharing for all families. | Contradicts the matrix cell. |
| **B — split head (matrix is right)** | Author a Warrior-only helm and a Bard-only helm at every rung. Adds 2 items per tier for a 2-class group. | Doubles head authoring for no observed benefit; nothing in canon uses it. |

🔷 PROPOSED default: **Reading A.** One `warrior_bard` head family, Warrior and Bard compete. Reason: it is what the authored data does at both Tier 1 rungs, and every other family shares head and body identically. If the designer wants the split, it is a deliberate Warrior-tanks-get-their-own-helm statement and needs a Bard head authored to go with it.

---

## 5. Tier 1 — starting gear for Common recruits

✅ CANON — reproduced verbatim, including AC totals (canon: raw notes, *Starting armor for common recruits*). This is what an `Unknown`-reputation Common recruit arrives wearing.

| Class | Head | Chest | Legs | Feet | Total AC |
|---|---|---|---|---|---|
| Warrior | Worn Iron Cap — 1 AC | Damaged Chainmail — 3 AC | Worn Leggings — 2 AC | Old Boots — 1 AC | **7 AC** |
| Bard | Worn Iron Cap — 1 AC | Damaged Chainmail — 3 AC | Worn Leggings — 2 AC | Old Boots — 1 AC | **7 AC** |
| Monk | Frayed Headband — 2 AC | Worn Gi — 2 AC | Worn Trousers — 1 AC | Old Sandals — 1 AC | **6 AC** |
| Rogue | Worn Eyepatch — 1 AC | Old Leather Jerkin — 2 AC | Worn Leather Breeches — 1 AC | Worn Boots — 1 AC | **5 AC** |
| Cleric | Worn Circlet — 1 AC | Tattered Vestments — 2 AC | Worn Leggings — 1 AC | Old Sandals — 1 AC | **5 AC** |
| Druid | Worn Circlet — 1 AC | Tattered Hide Vest — 2 AC | Worn Leggings — 1 AC | Old Sandals — 1 AC | **5 AC** |
| Shaman | Worn Headdress — 1 AC | Tattered Hide Vest — 2 AC | Worn Leggings — 1 AC | Old Sandals — 1 AC | **5 AC** |
| Mage | Worn Apprentice Cap — 1 AC | Tattered Robe — 1 AC | Worn Trousers — 1 AC | Old Slippers — 1 AC | **4 AC** |
| Wizard | Worn Apprentice Cap — 1 AC | Tattered Robe — 1 AC | Worn Trousers — 1 AC | Old Slippers — 1 AC | **4 AC** |

✅ CANON — starting gear has **AC only**. No HP, Power, or Mana on any starting piece.

❓ OPEN — starting gear names split families the matrix shares: `Worn Leggings` is worn by Warrior, Bard, Cleric, Druid and Shaman but at **2 AC** for Warrior/Bard and **1 AC** for the healers. Same name, two stat blocks. Also `Tattered Vestments` (Cleric) vs `Tattered Hide Vest` (Druid, Shaman) split the shared Healer family into two chest items at the starting rung. Proposed default: keep the canon names, treat them as separate items disambiguated by family in the ID (§11), and do not let the healer/plate `Worn Leggings` collision reach the data layer.

❓ OPEN — canon lists no starting **weapon**, **off-hand**, or **trinket**. A Common recruit arrives with four armor pieces and empty hands. Proposed default in §10.2.

---

## 6. Tier 1 Adventure — armor

✅ CANON — all four tables reproduced exactly, including the `—` cells and the totals rows (canon: ideaboard §2, `Screenshot_2026-08-27_040809.png` and `Screenshot_2026-08-27_040835.png`).

### 6.1 Warrior / Bard armor

| Slot | Item | AC | HP | Power | Mana |
|---|---|---|---|---|---|
| Head | Iron Adventurer's Helm | 3 | +3 | — | — |
| Chest | Iron Adventurer's Cuirass | 5 | +6 | — | — |
| Legs | Iron Adventurer's Greaves | 4 | +4 | — | — |
| Feet | Iron Adventurer's Boots | 3 | +3 | — | — |
| **Total** | | **15** | **+16** | — | — |

### 6.2 Monk / Rogue armor

| Slot | Item | AC | HP | Power | Mana |
|---|---|---|---|---|---|
| Monk Head | Ironbound Headband | 4 | +2 | — | — |
| Rogue Head | Reinforced Rogue Eyepatch | 3 | +2 | — | — |
| Chest | Reinforced Leather Vest | 4 | +5 | — | — |
| Legs | Reinforced Leather Leggings | 3 | +4 | — | — |
| Feet | Reinforced Leather Boots | 3 | +3 | — | — |
| **Monk Total** | | **14** | **+14** | — | — |
| **Rogue Total** | | **13** | **+14** | — | — |

### 6.3 Healer armor (Cleric / Druid / Shaman)

| Slot | Item | AC | HP | Power | Mana |
|---|---|---|---|---|---|
| Head | Blessed Adventurer's Circlet | 2 | +2 | — | +3 |
| Chest | Blessed Adventurer's Robe | 3 | +5 | — | +5 |
| Legs | Blessed Adventurer's Leggings | 2 | +3 | — | +3 |
| Feet | Blessed Adventurer's Shoes | 2 | +2 | — | +2 |
| **Total** | | **9** | **+12** | — | **+13 Mana** |

### 6.4 Mage / Wizard armor

| Slot | Item | AC | HP | Power | Mana |
|---|---|---|---|---|---|
| Head | Apprentice's Reinforced Cap | 2 | +2 | — | +4 |
| Chest | Reinforced Spellweave Robe | 2 | +4 | — | +6 |
| Legs | Spellweave Leggings | 2 | +2 | — | +4 |
| Feet | Spellweave Slippers | 2 | +2 | — | +3 |
| **Total** | | **8** | **+10** | — | **+17 Mana** |

### 6.5 Adventure armor totals at a glance

✅ CANON (canon: ideaboard §2.5):

| Armor family | AC | HP | Mana |
|---|---|---|---|
| Warrior / Bard | 15 | +16 | — |
| Monk | 14 | +14 | — |
| Rogue | 13 | +14 | — |
| Healer (Cleric/Druid/Shaman) | 9 | +12 | +13 |
| Mage / Wizard | 8 | +10 | +17 |

✅ CANON — **Power is `—` on every Tier 1 Adventure armor piece.** Power first appears on Tier 1 Raid armor (canon: ideaboard §5). The only Adventure-tier Power source is the trinket in §7.2.

---

## 7. Tier 1 Adventure — weapons and trinkets

### 7.1 Weapons

✅ CANON — verbatim (canon: raw notes, *Weapons (Tier 1 Adventure)*):

| Class(es) | Item | Stat |
|---|---|---|
| Warrior / Rogue / Bard | Iron Adventurer's Sword | +5 Damage |
| Monk | Iron Adventurer's Staff | +9 Damage |
| Mage | Apprentice's Firestaff | +10 Damage |
| Wizard | Apprentice's Arcstaff | +10 Damage |
| Healers (Cleric / Druid / Shaman) | Class-specific healer weapons | **TBD** |

✅ CANON — the healer line verbatim: *"Class-specific healer weapons (Will have mana or power unsure how much) we need to discuss if we want to have 2 variables or not. Stats TBD until we establish the healing/Mana formulas."*

RULED — that "2 variables or not" question is answered in [08 §5.3](08-stats-and-formulas.md) ([15 Q-02](15-open-questions.md#q-02) / [BL-87](15-open-questions.md#bl-87)): one gear variable, Mana, on every item record here; Focus is a class-fixed resource that never appears on gear and is DECIDED for 1.1. OQ-4's "one variable: Mana" stands for gear, which is all §10's numbers depend on.

❓ OPEN — Rogue dual-wields the `Warrior/Rogue/Bard 1H` family, so does an Adventure-tier Rogue equip **two** Iron Adventurer's Swords (+10 total) against a Warrior's one (+5)? Canon does not say. Proposed default: yes, two copies, because the Boss 1 Rogue row explicitly lists the same dagger in both hands.

### 7.2 Trinkets

✅ CANON — verbatim, spelling and all (canon: raw notes, *Trinkets (Tier 1 Adventure)*):

| Item | Stat |
|---|---|
| Adventure's Charm of Health | +7 Hp |
| Adventure's Charm of Armor | +2 AC |
| Adventure's Charm of Mana | +10 Mana |
| Adventures Charm of Power | +2 Power |

❓ OPEN — three trinkets read `Adventure's` and the fourth reads `Adventures` (no apostrophe); the armor sets read `Adventurer's`. Almost certainly a typo, but canon rule 1 forbids silently correcting it. Proposed default: normalise all four to **`Adventurer's Charm of X`** on designer sign-off, matching the armor prefix.

### 7.3 Tutorial trinkets

✅ CANON — *"Adventure 0 - 1 Trash mob (Just for learning - 1 crap trinket)"* and *"Tutorial Raid - 1 Boss (Just for learning - 1 crap trinket)"*, described as *"Like a +1 dps trinket or something"* (canon: raw notes, *Adventure's Board*). Two unnamed, unstatted trinkets. Names and stat blocks are settled in §10.2 (G12) — this doc owns them, and docs 01 and 10 cite them rather than proposing their own.

---

## 8. Tier 1 Raid — the nine class tables

✅ CANON — all nine reproduced exactly, cell for cell, including `—` (canon: ideaboard §3, `Screenshot_2026-08-27_044354.png` through `Screenshot_2026-08-27_044640.png`). Encounter naming is placeholder: **Boss 1 … Boss 5**.

### 8.1 Warrior

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Helm — 5 AC / +5 HP / +1 Power | — | — |
| Chest | — | — | — | Raider's Cuirass — 7 AC / +9 HP / +2 Power | — |
| Legs | — | Raider's Greaves — 5 AC / +6 HP / +1 Power | — | — | — |
| Feet | Raider's Boots — 4 AC / +4 HP | — | — | — | — |
| Main Hand | Basic Raid Sword — +6 Damage | — | — | Strong Raid Sword — +8 Damage | — |
| Shield | — | — | — | — | Warrior Shield — 7 AC / +8 HP / +1 Power |
| Trinket | — | — | — | — | Raid Trinket |

### 8.2 Bard

✅ CANON source note, verbatim: *"Bard uses the same Warrior/Bard armor, so **Mana can appear on these pieces and compete with Power**."*

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Helm — 5 AC / +5 HP / +1 Power | — | — |
| Chest | — | — | — | Raider's Cuirass — 7 AC / +9 HP / +2 Power | — |
| Legs | — | Raider's Greaves — 5 AC / +6 HP / +1 Power | — | — | — |
| Feet | Raider's Boots — 4 AC / +4 HP | — | — | — | — |
| Main Hand | Basic Raid Sword — +6 Damage | — | — | Strong Raid Sword — +8 Damage | — |
| Instrument | — | — | — | — | Bard Instrument — +20 Mana |
| Trinket | — | — | — | — | Raid Trinket |

❓ OPEN — the Bard note says Mana *can* appear on Warrior/Bard pieces, but **no authored Warrior/Bard piece carries Mana.** Either the note is forward-looking intent for Tiers 2–5, or a Bard-flavoured Mana variant is missing from Tier 1. Proposed default: treat it as intent, and from Tier 2 author one Mana-bearing variant per Warrior/Bard slot so the family genuinely contests (see §12.4).

### 8.3 Monk

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Headband | — | — | Raider's Headband — 5 AC / +5 HP | — | Final Headband |
| Chest | — | — | — | Raider's Vest — 6 AC / +7 HP / +2 Power | — |
| Legs | — | Raider's Leggings — 5 AC / +6 HP / +1 Power | — | — | — |
| Feet | Raider's Boots — 4 AC / +4 HP | — | — | — | — |
| 2H Weapon | Basic Raid Staff — +10 Damage | — | — | Strong Raid Staff — +14 Damage | — |
| Trinket | — | — | — | — | Raid Trinket |

### 8.4 Rogue

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Eyepatch | — | — | Raider's Eyepatch — 4 AC / +4 HP / +2 Power | — | Final Eyepatch |
| Chest | — | — | — | Raider's Leather Vest — 6 AC / +7 HP / +2 Power | — |
| Legs | — | Raider's Leggings — 5 AC / +6 HP / +1 Power | — | — | — |
| Feet | Raider's Boots — 4 AC / +4 HP | — | — | — | — |
| Main Hand | Basic Raid Dagger — +4 Damage | — | — | Strong Raid Dagger — +6 Damage | — |
| Off Hand | Basic Raid Dagger — +4 Damage | — | — | Strong Raid Dagger — +6 Damage | — |
| Trinket | — | — | — | — | Raid Trinket |

### 8.5 Cleric

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Circlet — 3 AC / +4 HP / +7 Mana | — | — |
| Chest | — | — | — | Raider's Vestments — 4 AC / +7 HP / +10 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +6 Mana | — | — | — |
| Feet | Raider's Shoes — 3 AC / +4 HP / +4 Mana | — | — | — | — |
| Weapon | Basic Healing Weapon | — | — | Strong Healing Weapon | Cleric Weapon |
| Off Hand | — | Blessed Raider's Tome — 2 AC / +5 Mana | — | — | — |
| Trinket | — | — | — | — | Raid Trinket |

### 8.6 Druid

✅ CANON note: *"Identical to Cleric except the Boss 5 weapon."*

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Circlet — 3 AC / +4 HP / +7 Mana | — | — |
| Chest | — | — | — | Raider's Vestments — 4 AC / +7 HP / +10 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +6 Mana | — | — | — |
| Feet | Raider's Shoes — 3 AC / +4 HP / +4 Mana | — | — | — | — |
| Weapon | Basic Healing Weapon | — | — | Strong Healing Weapon | Druid Weapon |
| Off Hand | — | Blessed Raider's Tome — 2 AC / +5 Mana | — | — | — |
| Trinket | — | — | — | — | Raid Trinket |

### 8.7 Shaman

✅ CANON note: *"Identical to Cleric/Druid except the Boss 5 weapon."*

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Circlet — 3 AC / +4 HP / +7 Mana | — | — |
| Chest | — | — | — | Raider's Vestments — 4 AC / +7 HP / +10 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +6 Mana | — | — | — |
| Feet | Raider's Shoes — 3 AC / +4 HP / +4 Mana | — | — | — | — |
| Weapon | Basic Healing Weapon | — | — | Strong Healing Weapon | Shaman Weapon |
| Off Hand | — | Blessed Raider's Tome — 2 AC / +5 Mana | — | — | — |
| Trinket | — | — | — | — | Raid Trinket |

### 8.8 Mage

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Cap — 3 AC / +3 HP / +8 Mana | — | — |
| Chest | — | — | — | Raider's Robe — 4 AC / +6 HP / +12 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +8 Mana | — | — | — |
| Feet | Raider's Slippers — 3 AC / +3 HP / +6 Mana | — | — | — | — |
| 2H Staff | Basic Raid Staff — +11 Damage | — | — | Strong Raid Staff — +15 Damage | Mage Staff |
| Trinket | — | — | — | — | Raid Trinket |

### 8.9 Wizard

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Cap — 3 AC / +3 HP / +8 Mana | — | — |
| Chest | — | — | — | Raider's Robe — 4 AC / +6 HP / +12 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +8 Mana | — | — | — |
| Feet | Raider's Slippers — 3 AC / +3 HP / +6 Mana | — | — | — | — |
| 2H Staff | Basic Raid Staff — +12 Damage | — | — | Strong Raid Staff — +16 Damage | Wizard Staff |
| Trinket | — | — | — | — | Raid Trinket |

### 8.10 Derived drop-slot pattern

✅ CANON — the pattern the nine tables agree on (canon: ideaboard §4; corroborated by raw notes, *Raid Layout and loot drops*):

| Encounter | Difficulty | Slot dropped | Also drops |
|---|---|---|---|
| Boss 1 (Trash) | ★ | Feet | Basic weapons (Sword / Dagger ×2 / Staff / Healing Weapon) |
| Boss 2 (Harder trash) | ★★ | Legs | Healer Off-Hand (Blessed Raider's Tome) |
| Boss 3 (Mini boss) | ★★★ | Head | — |
| Boss 4 (Mini boss) | ★★★★ | Chest | Strong weapons |
| Boss 5 (Main boss of tier) | ★★★★★ | Class capstone (Shield / Instrument / Final Headband / Final Eyepatch / class Staff / class Healing Weapon) | Raid Trinket |

❓ OPEN — the two canon statements of the Boss 3 drop disagree. Raw notes: *"Encounter 3 (Mini boss) | Head + stronger shared gear"*. Ideaboard §4: *"Boss 3 | Head | —"*, and no per-class table lists any second Boss 3 item. So either the raw-notes "stronger shared gear" is unauthored content missing from the tables, or the tables are correct and Boss 3 is a single-drop encounter. Proposed default: **Boss 3 also drops the tier's off-hand upgrades** (Warrior Shield / Instrument / a second Tome), which is the only "shared gear" gap left and fixes the empty-off-hand problem in §3.3.

### 8.11 Tier 1 Raid armor totals (derived)

🔷 PROPOSED — summed from the canon tables above; useful as the balance target doc 08 tunes boss damage against. Armor slots only (head + chest + legs + feet).

| Armor family | AC | HP | Power | Mana | Δ AC vs Adventure | Δ HP | Δ Mana |
|---|---|---|---|---|---|---|---|
| Warrior / Bard | 21 | +24 | +4 | — | ×1.40 | ×1.50 | — |
| Monk | 20 | +22 | +3 | — | ×1.43 | ×1.57 | — |
| Rogue | 19 | +21 | +5 | — | ×1.46 | ×1.50 | — |
| Healer | 13 | +19 | — | +27 | ×1.44 | ×1.58 | ×2.08 |
| Mage / Wizard | 13 | +16 | — | +34 | ×1.63 | ×1.60 | ×2.00 |

Read: AC grows ~×1.45 (cloth ×1.63, catching up), HP ~×1.55, Mana ~×2.0 within a tier. That is the basis of §12.

---

## 9. Canon collisions the data layer must survive

### 9.1 Name collisions

🔷 PROPOSED — *why this exists: item **names are not unique** in canon, so the build cannot key on name. These are the concrete collisions.*

| Name | Distinct stat blocks in canon | Where |
|---|---|---|
| `Raider's Leggings` | 3 — `5 AC/+6 HP/+1 Power` (Monk, Rogue), `3 AC/+4 HP/+6 Mana` (healers), `3 AC/+4 HP/+8 Mana` (Mage, Wizard) | §8.3–8.9 |
| `Raider's Boots` | 1 block, but **two families** — Warrior/Bard *and* Monk/Rogue both get `4 AC / +4 HP` | §8.1–8.4 |
| `Worn Leggings` | 2 — `2 AC` (Warrior, Bard), `1 AC` (Cleric, Druid, Shaman) | §5 |
| `Basic Raid Staff` | 3 — `+10` (Monk), `+11` (Mage), `+12` (Wizard) | §8.3, §8.8, §8.9 |
| `Strong Raid Staff` | 3 — `+14` (Monk), `+15` (Mage), `+16` (Wizard) | §8.3, §8.8, §8.9 |

❓ OPEN — **is the Boss 1 `Raider's Boots` one item or two?** Identical name, identical `4 AC / +4 HP`, but the matrix puts Warrior/Bard and Monk/Rogue in different families. If one item, the Boss 1 feet drop is contested 4 ways and the two body families are not actually separate at the Feet slot. Proposed default: **two items, one per family**, same stats — preserving family integrity — with the name disambiguated in the ID, not the display string.

❓ OPEN — **Monk/Rogue chest splits at the Raid rung.** Adventure has one shared `Reinforced Leather Vest — 4 AC / +5 HP` (§6.2), but Raid has `Raider's Vest — 6 AC / +7 HP / +2 Power` (Monk) and `Raider's Leather Vest — 6 AC / +7 HP / +2 Power` (Rogue): identical stats, two names, for a family the matrix says is shared. Proposed default: one item, display name `Raider's Leather Vest`; treat `Raider's Vest` as the same row.

❓ OPEN — **healer chest base noun changes rung to rung**: `Blessed Adventurer's Robe` (Adventure) → `Raider's Vestments` (Raid). Every other family keeps its base noun. Proposed default: fix the healer chest noun to **Vestments** at all rungs so §11's naming template holds.

### 9.2 Trinket scarcity

✅ CANON — raid size is **12** (canon: raw notes, *Classes*: *"I've also decided I'd like the raid size to be 12, most fights normally requiring 2 tanks."*). ✅ CANON — Boss 5 drops `Raid Trinket`, singular, and the Universal family is wanted by all 9 classes.

❓ OPEN — canon never states **how many copies** any encounter drops. With 12 raiders and one trinket per Boss 5 kill, fully trinketing a roster takes 12 clears.

**Drops-per-encounter is not owned here.** It belongs to [10 — Content Structure: Adventures, Raids & Encounters](10-content-and-encounters.md) §4.2, which specifies `rolls(encounter) = E1:2 E2:2 E3:2 E4:3 E5:3 (+1 guaranteed Raid Trinket)` and derives the gearing-pace figure from it. This doc supplies the item pool each roll draws from; it does not set the roll counts. If the trinket pace is too slow, the fix is a roll-count change in doc 10 §4.2, not a second number here.

---

## 10. The gaps: canon items with no stats

### 10.1 The full list

✅ CANON — canon names these items and gives them no stat block (canon: ideaboard §5, corroborated by raw notes):

| # | Item | Class(es) | Source | Canon says |
|---|---|---|---|---|
| G1 | Raid Trinket | all 9 | Boss 5 | name only |
| G2 | Final Headband | Monk | Boss 5 | name only |
| G3 | Final Eyepatch | Rogue | Boss 5 | name only |
| G4 | Basic Healing Weapon | Cleric, Druid, Shaman | Boss 1 | name only |
| G5 | Strong Healing Weapon | Cleric, Druid, Shaman | Boss 4 | name only |
| G6 | Cleric Weapon | Cleric | Boss 5 | name only |
| G7 | Druid Weapon | Druid | Boss 5 | name only |
| G8 | Shaman Weapon | Shaman | Boss 5 | name only |
| G9 | Mage Staff | Mage | Boss 5 | name only |
| G10 | Wizard Staff | Wizard | Boss 5 | name only |
| G11 | Adventure-tier healer weapons | Cleric, Druid, Shaman | Adventure 1 | *"Stats TBD until we establish the healing/Mana formulas"* |
| G12 | Tutorial "crap trinket" ×2 | any | Adventure 0, Tutorial Raid | *"Like a +1 dps trinket or something"* |

### 10.2 Proposed stat blocks

🔷 PROPOSED — *why this exists: ten named-but-empty items block the Tier 1 loot table from being data-complete. These numbers slot into the observed scaling so the tier can be built and playtested; every one is a sign-off candidate, not a decision.*

Scaling anchors used, all canon: Boss 1 weapon = Adventure weapon **+1 to +2**, *except the Rogue's Basic Raid Dagger at +4 against a +5 Iron Adventurer's Sword (**−1**)* — see OQ-11 and OQ-15, plus [08 §13 Q10](08-stats-and-formulas.md) and [11 §14 Q6](11-economy-and-crafting.md), which flag the same step; Boss 4 weapon = Boss 1 **+2** (1H) or **+4** (2H); Boss 5 Bard Instrument = **+20 Mana**, i.e. capstone off-hands/weapons sit around **+20**; Boss 5 Warrior Shield = `7 AC / +8 HP / +1 Power`, i.e. a capstone matches or exceeds the Boss 4 chest.

**Weapons**

| Gap | Item | Proposed | Derivation |
|---|---|---|---|
| G11 | Adventurer's Healing Focus (name pending) | **+10 Mana** | Parity with Apprentice's Firestaff/Arcstaff `+10` and Adventure's Charm of Mana `+10`. |
| G4 | Basic Healing Weapon | **+11 Mana** | Adventure +1, matching Mage `10 → 11`. |
| G5 | Strong Healing Weapon | **+15 Mana** | Basic +4, matching Mage `11 → 15`. |
| G6 | Cleric Weapon | **+19 Mana / +2 AC** | Strong +4; secondary from the budget below. |
| G7 | Druid Weapon | **+19 Mana / +4 HP** | Strong +4; secondary from the budget below. |
| G8 | Shaman Weapon | **+19 Mana / +1 AC / +2 HP** | Strong +4; secondary from the budget below. |
| G9 | Mage Staff | **+19 Damage** | Strong `15` +4. |
| G10 | Wizard Staff | **+20 Damage** | Strong `16` +4; preserves the canon Wizard-is-always-+1 gap (`11/12`, `15/16`). |

🔷 PROPOSED **secondary budget**, used to differentiate the three healer capstones without inventing a new stat: each capstone spends **4 points** where `1 AC = 2 pts`, `1 HP = 1 pt`, `1 Power = 2 pts`, `1 Mana = 1 pt`. Cleric buys AC (tank healer, stands close), Druid buys HP (raid healer, eats AoE), Shaman splits (chain healer, mid-line). Mechanical differentiation beyond stats belongs to doc 06.

**Heads (capstone)**

| Gap | Item | Proposed | Derivation |
|---|---|---|---|
| G2 | Final Headband (Monk) | **6 AC / +6 HP / +2 Power** | Must beat Boss 3 `Raider's Headband — 5 AC / +5 HP`; lands level with Boss 4 `Raider's Vest — 6 AC / +7 HP / +2 Power`. |
| G3 | Final Eyepatch (Rogue) | **5 AC / +5 HP / +3 Power** | Must beat Boss 3 `Raider's Eyepatch — 4 AC / +4 HP / +2 Power`; Rogue family runs 1 AC lighter than Monk and 2 Power heavier at the head slot (Raider's Eyepatch +2 Power vs Raider's Headband's none). |

Note the structural consequence: Monk and Rogue receive **two** head items in one tier (Boss 3 and Boss 5) while every other class receives one. Their Boss 3 head is superseded inside the same tier — see OQ-3.

**Trinkets (G1)**

🔷 PROPOSED — the `Raid Trinket` is one **family of four**, mirroring the four Adventure charms, scaled by the observed within-tier multipliers (AC ×1.45, HP ×1.55, Mana ×2.0, Power ×1.45), rounded to whole numbers:

| Item | Proposed | From |
|---|---|---|
| Raider's Charm of Health | **+11 HP** | Adventure `+7 Hp` × 1.55 |
| Raider's Charm of Armor | **+3 AC** | Adventure `+2 AC` × 1.45 |
| Raider's Charm of Mana | **+20 Mana** | Adventure `+10 Mana` × 2.0 |
| Raider's Charm of Power | **+3 Power** | Adventure `+2 Power` × 1.45 |

Per [10 §4.2](10-content-and-encounters.md) Boss 5 drops **exactly 1 guaranteed Raid Trinket** per clear alongside its 3 capstone rolls. So the four charms above are a pool of four that Boss 5 draws **one** from per clear: the tension is *which* charm the roster gets, not which raider gets it, and fully trinketing 12 raiders takes ~12 clears. Roll counts are doc 10's to change, not this doc's.

**Tutorial trinkets (G12)**

🔷 PROPOSED — **this doc owns item stat blocks, so this is the single pair.** One primary (`+1 Power`, canon's *"+1 dps"*) and one weak secondary. Names follow the §11.3 trinket template `{RungFiction}'s Charm of {Stat}`.

| Item | Proposed | Slot / source | Note |
|---|---|---|---|
| Cracked Charm of Power | **+1 Power** | trinket, Adventure 0 | Canon *"Like a +1 dps trinket or something"*. `+1 Power`, **not** `+1 Damage`: §12.2 restricts `damage` to weapons, so a `+1 Damage` trinket cannot be expressed as an item row at all. Agrees with [11 §14 Q5](11-economy-and-crafting.md), which rules canon's "+1 dps" to be `+1 Power`. |
| Cracked Charm of Health | **+2 HP** | trinket, Tutorial Raid | Deliberately worse than any Adventure charm (`+7 Hp` is the weakest health charm), per canon *"not a great piece"*. |

Cross-doc note, one line each and owed *to* this doc: [01 §8.2](01-core-loop.md)'s `Trinket of Mild Competence — +1 Damage` and [10 §9.2](10-content-and-encounters.md)'s `Trinket of Mild Competence / +1 Damage` and `Trinket of Faint Encouragement / +1 AC` should cite the two rows above by name and stat rather than propose their own. If the designer prefers doc 01's joke names to the template names, the names change **here** and propagate outward — the stat blocks do not fork.

**Adventure-tier off-hands** (fills the §3.3 gap)

🔷 PROPOSED — 60% of the Boss-5 capstone value, so the Raid capstone is still the moment. **This block and the starting weapons below are [15 Q-35](15-open-questions.md#q-35)'s recommended default ("Add both"), adopted as the build's default on 2026-09-15 and still unsigned:** the three rows are the §13.1 template's `+3` per Adventure rung. They are not in the data yet — `data/items_t1_adventure.json` carries 28 rows and no off-hand, and `tools/gen_items.gd` holds every generated Adventure rung at that shape — so the content half (the three T1 rows with `canon: false` citing this section, an off-hand template in the generator for T2-T5, the row-count tests moved from 28 to 31) is a later unit, audit `M5-T25-14`. Until it lands, Warrior, Bard and the three healers show the empty off-hand §3.3 describes for the whole Adventure phase.

| Item | Slot | Proposed |
|---|---|---|
| Iron Adventurer's Shield (Warrior) | off_hand | **4 AC / +5 HP** |
| Adventurer's Lute (Bard) | off_hand | **+12 Mana** |
| Blessed Adventurer's Tome (healers) | off_hand | **1 AC / +3 Mana** |

**Starting weapons** (fills the §5 gap)

🔷 PROPOSED — 40% of the Adventure weapon, one per family: Chipped Sword `+2 Damage` (Warrior/Rogue/Bard), Cracked Staff `+4 Damage` (Monk), Splintered Wand `+4 Damage` (Mage/Wizard), Bent Censer `+4 Mana` (healers). Common recruits arrive armed but embarrassing.

---

## 11. Naming convention

🔷 PROPOSED — *why this exists: canon already names items to a consistent pattern. Formalising it means Tiers 2–5 name themselves from a word table instead of ~400 hand-written strings (count derived in §13.1).*

### 11.1 The template

```
{QualityWord}? {TierWord} {FamilyWord}? {BaseNoun}
```

- **QualityWord** — only at the starting rung: `Worn`, `Damaged`, `Old`, `Frayed`, `Tattered`. Signals "this raider is a nobody."
- **TierWord** — the tier + rung marker. This is the slot the word table fills.
- **FamilyWord** — a possessive that marks the rung's fiction: canon uses `Adventurer's` for Adventure gear and `Raider's` for Raid gear.
- **BaseNoun** — fixed per family + slot for the life of the game. Never varies by tier.

### 11.2 Base nouns (fixed, from canon)

✅ CANON nouns, ❓ OPEN where canon varies:

| Family | Head | Chest | Legs | Feet | Main Hand | Off Hand |
|---|---|---|---|---|---|---|
| Warrior / Bard | Helm | Cuirass | Greaves | Boots | Sword | Shield (W) / Instrument (B) |
| Monk | Headband | Vest | Leggings | Boots | Staff | — |
| Rogue | Eyepatch | Leather Vest | Leggings | Boots | Dagger | Dagger |
| Healer | Circlet | Vestments ❓ (Adventure says `Robe`) | Leggings | Shoes | Healing Weapon | Tome |
| Mage / Wizard | Cap | Robe | Leggings | Slippers | Firestaff (M) / Arcstaff (W) | — |

### 11.3 Rung words at Tier 1 (canon) and the pattern they imply

✅ CANON Tier 1 words:

| Rung | Warrior/Bard | Monk/Rogue | Healer | Mage/Wizard | Weapons |
|---|---|---|---|---|---|
| Starting | `Worn` / `Damaged` / `Old` | `Frayed` / `Worn` / `Old` | `Worn` / `Tattered` / `Old` | `Worn` / `Tattered` / `Old` | — |
| T1 Adventure | `Iron Adventurer's` | `Ironbound` (Monk head) / `Reinforced` | `Blessed Adventurer's` | `Apprentice's Reinforced` / `Reinforced Spellweave` / `Spellweave` | `Iron Adventurer's` / `Apprentice's` |
| T1 Raid | `Raider's` | `Raider's` | `Raider's` / `Blessed Raider's` (off-hand) | `Raider's` | `Basic Raid` / `Strong Raid` / `Final` / `{Class}` |

Extracted rule, 🔷 PROPOSED:

| Rung | Formula | Tier 1 example |
|---|---|---|
| Starting | `{QualityWord} {BaseNoun}` | Damaged Chainmail |
| Adventure | `{TierMaterial} {FamilyFiction}'s {BaseNoun}` | Iron Adventurer's Cuirass |
| Raid — armor | `{RaidTitle}'s {BaseNoun}` | Raider's Cuirass |
| Raid — Boss 1 weapon | `Basic {RaidTitle-adj} {WeaponNoun}` | Basic Raid Sword |
| Raid — Boss 4 weapon | `Strong {RaidTitle-adj} {WeaponNoun}` | Strong Raid Sword |
| Raid — Boss 5 capstone | `Final {BaseNoun}` or `{Class} {BaseNoun}` | Final Headband, Cleric Weapon |
| Trinket | `{RungFiction}'s Charm of {Stat}` | Adventure's Charm of Health |

### 11.4 Tier word table for Tiers 2–5

🔷 PROPOSED **placeholders only — naming is pending designer sign-off.** The point is that the *shape* is fixed: **five words per tier** — the metal line, the cloth line, the healer line, the raid title and the raid adjective — plus one structural choice for the leather line, and every item name in the tier is generated. (Amended 2026-09-15 to five columns: the two this table carried before were the two the generator's `material` and `raid_title` keys read, and `tools/gen_items.gd` had read five since it was written — CONTENT-04.)

| Tier | `material` (Adventure metal: Warrior/Bard, Monk, Rogue; the Adventure sword and staff) | `cloth` (Mage/Wizard Adventure; Firestaff, Arcstaff) | `healer` (healer Adventure; the raid Tome's prefix) | `raid_title` (every raid armour piece, possessive; the raid charms) | `raid_adj` (§11.3's {RaidTitle-adj}: "Basic ___ Sword", "Strong ___ Staff"; the Boss 5 capstone prefix) |
|---|---|---|---|---|---|
| 1 | Iron ✅ | Spellweave ✅ | Blessed ✅ | Raider ✅ | Raid ✅ |
| 2 | *(pending)* — candidate: Steel | *(pending)* | *(pending)* | *(pending)* — candidate: Vanquisher | *(pending)* |
| 3 | *(pending)* — candidate: Mithril | *(pending)* | *(pending)* | *(pending)* — candidate: Conqueror | *(pending)* |
| 4 | *(pending)* — candidate: Adamant | *(pending)* | *(pending)* | *(pending)* — candidate: Ascendant | *(pending)* |
| 5 | *(pending)* — candidate: Runegold | *(pending)* | *(pending)* | *(pending)* — candidate: Immortal | *(pending)* |

Grammar (§11.1): one capitalised word per cell; no possessive in the word (the template adds `'s`); `raid_title` must read as a person ("Raider" → "Vanquisher") because it is used possessively; `raid_adj` reads as a rank adjective of the title ("Raider" → "Raid"), and the designer may set `raid_adj` = `raid_title` per tier. The words above are placeholders in the same spirit as "Raid 1" and "Boss 3" — the designer names them. **The leather line is the sixth decision:** at Tier 1 the Monk/Rogue line reads *Reinforced* Leather Vest, not *Iron* Leather Vest (canon), so either leather shares `material` from Tier 2 on (the recommended default — canon's own T1 line already mixes `Ironbound` and `Reinforced`) or the table gains a `leather` column; `data/tier_words.json`'s `leather_column` records the choice and its T1 row carries `Reinforced`.

**Where the answer goes, when there is one:** `data/tier_words.json`. The file exists, carries Tier 1's
words read off canon's own item names (`Iron`, `Spellweave`, `Blessed`, `Raider`, `Raid`, and `Reinforced`
for leather), and marks tiers 2-5 `pending: true` with the candidates above recorded as candidates rather
than as values (every pending tier lists all five columns, null where no candidate was ever written down).
`tools/gen_items.gd` reads it, stamps `name_pending` on every row of a pending tier, and refuses to call
that tier finished — so filling in four material words and four titles is what turns ~360 generated item
records from placeholders into content. **One wrinkle to decide with them:** at Tier 1 the leather line
reads *Reinforced* Leather Vest, not *Iron* Leather Vest, so canon's T1 leather uses a word that
this table's five columns do not carry. Either the leather line shares the metal word from Tier 2 on, or
this table gains a sixth column (`leather`) — the `leather_column` slot in the data file holds the answer.

---

## 12. Item identity and data schema

🔷 PROPOSED — *why this exists: §9 proves item names are not unique, so the build needs a stable key. Doc 14 turns this schema into a Godot `Resource`.*

### 12.1 ID format

```
ITM_T{tier}_{SOURCE}_{FAMILY}_{SLOT}[_{VARIANT}]
```

| Field | Values | Notes |
|---|---|---|
| `tier` | `0`–`5` | `0` = starting gear and tutorial rewards. |
| `SOURCE` | `START`, `TUT`, `ADV`, `RAID`, `VEND`, `QUEST` | Where it enters the economy. `TUT` is the onboarding reward the `tier` row above already contemplates — added by [15 BL-77](./15-open-questions.md#bl-77), which also says why these two are not `START`. |
| `FAMILY` | `WARBARD`, `MONKROGUE`, `HEALER`, `MAGEWIZ`, `W1H`, `W2H_MONK`, `W2H_MAGE`, `W2H_WIZ`, `WPN_CLR`, `WPN_DRU`, `WPN_SHM`, `SHIELD`, `INSTR`, `HEALOFF`, `MONKHEAD`, `ROGUEHEAD`, `UNIV` | Matches §4.2 exactly. |
| `SLOT` | `MH`, `OH`, `HEAD`, `CHEST`, `LEGS`, `FEET`, `TRINKET` | |
| `VARIANT` | `B1`–`B5`, `BASIC`, `STRONG`, `FINAL`, `HEALTH`, `ARMOR`, `MANA`, `POWER` | Only when one family+slot has several items in a rung. |

Worked keys:

| Item | ID |
|---|---|
| Raider's Cuirass | `ITM_T1_RAID_WARBARD_CHEST` |
| Raider's Boots (Warrior/Bard) | `ITM_T1_RAID_WARBARD_FEET` |
| Raider's Boots (Monk/Rogue) | `ITM_T1_RAID_MONKROGUE_FEET` |
| Basic Raid Dagger | `ITM_T1_RAID_W1H_MH_BASIC` |
| Raider's Charm of Mana | `ITM_T1_RAID_UNIV_TRINKET_MANA` |
| Damaged Chainmail | `ITM_T0_START_WARBARD_CHEST` |
| Cracked Charm of Power (§10.2 G12) | `ITM_T0_TUT_UNIV_TRINKET_POWER` |

IDs are permanent. Renaming an item changes `name`, never `id`.

### 12.2 Data-row schema

| Field | Type | Required | Meaning |
|---|---|---|---|
| `id` | string | yes | §12.1. Primary key. |
| `name` | string | yes | Display string. Not unique. |
| `slot` | enum | yes | One of the seven slots in §3.2. |
| `family` | enum | yes | Drives eligibility. See §4.2. |
| `tier` | int 0–5 | yes | |
| `source` | enum | yes | `START` / `ADV` / `RAID` / `VEND` / `QUEST` |
| `drop_encounter` | int 1–5 or null | no | Which Boss dropped it. Null for non-raid sources. |
| `ac` | int | yes | Default 0. |
| `hp` | int | yes | Default 0. |
| `power` | int | yes | Default 0. |
| `mana` | int | yes | Default 0. |
| `damage` | int | yes | Default 0. Weapons only. |
| `two_handed` | bool | yes | True locks `off_hand`. |
| `sell_value` | int | no | Owned by doc 11; null until priced. |
| `sprite` | string | no | Aseprite source key; owned by the art doc. |
| `flavour` | string | no | One line of comedy. Empty is legal. |
| `canon_ref` | string | yes | Where the numbers come from, or `PROPOSED`. Makes canon drift auditable. |

### 12.3 Worked example

```json
{
  "id": "ITM_T1_RAID_WARBARD_CHEST",
  "name": "Raider's Cuirass",
  "slot": "chest",
  "family": "WARBARD",
  "tier": 1,
  "source": "RAID",
  "drop_encounter": 4,
  "ac": 7,
  "hp": 9,
  "power": 2,
  "mana": 0,
  "damage": 0,
  "two_handed": false,
  "sell_value": null,
  "sprite": "items/t1_raid/warbard_chest",
  "flavour": "Dented in the shape of a boss you have not beaten yet.",
  "canon_ref": "ideaboard-transcription.md §3.1 Warrior / Boss 4"
}
```

### 12.4 Eligibility is derived, never stored

🔷 PROPOSED — do **not** store a class list on the item. Store `family`; derive eligible classes from the §3.1 matrix at load. One table edit then re-points every item in the family, and the §4.4 head question becomes a one-cell change instead of a data migration.

---

## 13. Tier scaling: generating Tiers 2–5

🔷 PROPOSED — *why this exists: the ten rungs of §13.1 crossed with the §4.2 families produce **roughly 400 items** for 1.0 (arithmetic in §13.1). Hand-authoring them guarantees drift. Generate them, then hand-author only the exceptions.*

### 13.1 The rungs

Ten rungs, `r1`–`r10`: `r1` = T1 Adventure, `r2` = T1 Raid, `r3` = T2 Adventure, … `r10` = T5 Raid. Starting gear is `r0`.

**Item-count envelope (derived, not estimated).** Counted as *family × slot* per rung — not class × slot, because families are shared. Under §4.4's Reading A and §9.1's one-Vest merge:

| Line | Per rung | Breakdown |
|---|---|---|
| Armor | **17** | Warrior/Bard 4 (head/chest/legs/feet) + Monk/Rogue 5 (3 body + Monk Headband + Rogue Eyepatch) + Healer 4 + Mage/Wizard 4 |
| Weapons — Adventure rung | **7** | 1H Sword, Monk Staff, Mage Staff, Wizard Staff, Cleric/Druid/Shaman healer weapons |
| Weapons — Raid rung | **12** | 6 lines (Sword, Dagger, Monk Staff, Mage Staff, Wizard Staff, Healing Weapon) × Basic (Boss 1) + Strong (Boss 4) |
| Off-hands — Adventure rung | **3** | Iron Adventurer's Shield, Adventurer's Lute, Blessed Adventurer's Tome (§10.2 proposals) |
| Off-hands — Raid rung | **1** | Blessed Raider's Tome (Boss 2); Shield and Instrument are Boss 5 capstones, counted below |

So: an Adventure rung generates `17 + 7 + 3 = 27`, a Raid rung generates `17 + 12 + 1 = 30`.

**RULED — the `+ 3` ships ([15 Q-28 / Q-35](15-open-questions.md#q-35), 2026-09-15: "both signed").** The row count is the contract W8-ITEMS regenerates against: every Adventure file holds **28** rows at HEAD (17 armour + 7 weapons + 4 charms, no off-hands — 24 generated rows against the 27 this table counts, as `tools/gen_items.gd` says in each generated file's notes), and after W8-ITEMS lands the three off-hands per rung (Shield on `material`, Tome on `healer`, Lute on the `leather` column — "Studded Adventurer's Lute") it holds **31** (27 generated + 4 charms); the row-count tests in `tests/unit/test_tier_scaling.gd` move from 28 to 31 in that unit and this note goes with them (audit `M5-T25-14`; CONTENT-05). The four Market starters and the seven "Borrowed" loaners of the same ruling are §10.2's and are not counted in this envelope (they are `source: "start"` / the tier-1 shelf, not rung rows).

| Bucket | Arithmetic | Items |
|---|---|---|
| Generated, 5 Adventure rungs (r1, r3, r5, r7, r9) | 5 × 27 | **135** |
| Generated, 5 Raid rungs (r2, r4, r6, r8, r10) | 5 × 30 | **150** |
| `r0` starting gear | 22 family-qualified armor rows (19 distinct canon names, §5) + 4 starting weapons + 2 tutorial trinkets (§10.2) | **28** |
| Hand-authored capstones (§13.5) | 9 per tier × 5 | **45** |
| Hand-authored Raid charms (§10.2) | 4 per tier × 5 | **20** |
| Hand-authored Adventure charms (§7.2) | 4 per tier × 5 | **20** |
| **Total distinct item records for 1.0** | 135 + 150 + 28 + 45 + 20 + 20 | **≈ 398** |

Hand-authoring therefore totals **85** items (45 + 20 + 20), and the per-tier figure is 74 (31 Adventure + 43 Raid).

**This agrees with the rest of the set.** [10 §12.2](10-content-and-encounters.md) derives ~72 items per tier → ~360, and [00 §6.3](00-vision-and-pillars.md) states ~350–450 for 1.0; ~398 sits inside that band. The ~38-item gap against doc 10 is fully accounted for: doc 10 counts canon Tier 1 only and so excludes `r0` starting gear and the three proposed Adventure off-hands per rung. [14 §11](14-technical-architecture.md) sizes the atlas/VRAM risk off the same ~350–450 envelope and needs no change. The earlier "roughly 200 items" figure in this section was the outlier and is retired.

### 13.2 Growth rule

| Step | AC | HP | Mana | Power | Weapon damage |
|---|---|---|---|---|---|
| Within tier (Adventure → Raid) | ×1.45 (cloth ×1.60) | ×1.55 | ×2.05 | new at Raid: see §13.4 | Basic = Adv +1 (+2 for Wizard); Strong = Basic +2 (1H) / +4 (2H); Capstone = Strong +4 |
| Across tiers (Raid → next Adventure) | ×1.10 | ×1.10 | ×1.15 | ×1.10 | ×1.25 |

Within-tier multipliers are **fitted to canon**, not invented: see §8.11. Cross-tier multipliers are the proposal that needs sign-off, and are the single knob that sets total campaign length.

### 13.3 Fit quality against canon (audit)

Applying ×1.45 / ×1.55 / ×2.05 to the §6.5 Adventure totals, rounded half-up:

| Family | AC pred / canon | HP pred / canon | Mana pred / canon |
|---|---|---|---|
| Warrior / Bard | 22 / **21** ⚠ −1 | 25 / **24** ⚠ −1 | — |
| Monk | 20 / **20** ✓ | 22 / **22** ✓ | — |
| Rogue | 19 / **19** ✓ | 22 / **21** ⚠ −1 | — |
| Healer | 13 / **13** ✓ | 19 / **19** ✓ | 27 / **27** ✓ |
| Mage / Wizard | 13 / **13** ✓ (using ×1.60) | 16 / **16** ✓ | 35 / **34** ⚠ −1 |

Eight of twelve totals land exactly; four are off by 1. So the generator needs an **override column**: `overrides.csv` keyed by `(family, rung, stat)` carrying a signed delta. Canon values are entered as overrides at r1/r2 and win over the formula, always. The generator never edits canon.

### 13.4 Slot distribution

Family totals are split across slots by a per-family share table (derived from canon r1/r2, so it reproduces canon by construction):

| Family | Head | Chest | Legs | Feet |
|---|---|---|---|---|
| Warrior / Bard | 0.22 | 0.33 | 0.25 | 0.20 |
| Monk | 0.27 | 0.29 | 0.23 | 0.21 |
| Rogue | 0.22 | 0.31 | 0.25 | 0.22 |
| Healer | 0.23 | 0.32 | 0.23 | 0.22 |
| Mage / Wizard | 0.25 | 0.28 | 0.25 | 0.22 |

Rounding rule: floor every slot, then hand the remainder to **Chest** until the family total is exact. Chest is the heaviest slot in canon in four of five families, so it absorbs drift least visibly.

Power appears only from the Raid rung of each tier ✅ CANON, at 🔷 PROPOSED `round(AC_total × 0.20)` for physical families and `0` for Healer / Mage / Wizard — which reproduces Warrior/Bard `4`, Monk `3` (rounds to 4, override −1) and Rogue `5` (rounds to 4, override +1).

### 13.5 What is NOT generated

Hand-author, always: capstones (Boss 5), trinkets, and any item with a joke in it. Nine capstones, four Raid charms and four Adventure charms per tier is 85 hand-written items across the game (§13.1) — a manageable number, and they are the memorable ones.

---

## 14. Loot rules: who gets the drop?

❓ OPEN — **canon never says whether the player assigns loot or the game auto-assigns it.** Nothing in either source addresses it. This is the largest undecided question in this document, because loot routing is the main input to the wishlist/morale lever: canon says *"We could have raiders also know their bis and occasionally wishlist items for bonus morale"* (canon: raw notes, *Morale*), and a wishlist only means something if the player can choose to honour or ignore it.

### 14.1 Option A — Master Looter (player assigns)

The drop goes to the loot window. The player picks a recipient from the eligible classes (§4.2) or sends it to the Market.

| Pro | Con |
|---|---|
| Every drop is a decision, which is the guild-leader fantasy. | Slower; a 5-encounter raid means 5–10 loot prompts. |
| Wishlists become real: honouring one is a morale gain, passing over one is a morale loss. | Decision fatigue if drop counts rise in later tiers. |
| Player can deliberately gear the raider they need, or bribe the raider at 14 morale. | Optimal play can become obvious and therefore rote. |
| Selling a wanted item is a *choice with a cost* — money vs morale. | Needs UI: eligible list, current-vs-new stat delta, wishlist flag. |

### 14.2 Option B — Auto-assign (need-based)

The engine hands the item to the eligible raider with the biggest stat upgrade; ties break toward lower morale.

| Pro | Con |
|---|---|
| Zero friction; raids stay fast. | Removes the decision, so wishlists collapse into a passive bonus. |
| No UI beyond a results summary. | The player watches loot happen instead of leading. |
| Impossible to grief yourself into an unwinnable roster. | Undermines doc 05's central lever. |

### 14.3 Recommendation (the wishlist half is post-1.0 — [15 BL-98](15-open-questions.md#bl-98); the Master Looter with a Suggested button is Q-11's shipped answer)

🔷 PROPOSED — **Option A, with Option B available as a one-click default.**

Concretely:

1. The loot window opens once at the end of the raid, not per encounter — one list, all drops.
2. Each row shows: item, the eligible raiders, each one's stat delta if equipped, and a wishlist marker on any raider who wanted it.
3. A **Suggested** button pre-fills the whole list using Option B's rule. The player can accept it in one click or override any row.
4. A **Sell** target sits alongside the raiders; selling a wishlisted item is allowed and carries a morale cost.
5. A setting, `auto_loot`, applies the suggestion silently for players who want the fast path.

This keeps the decision available without taxing every raid, and it gives doc 05 the hook it needs: the game knows both what the player *could* have done and what they did. Exact morale deltas for honouring or ignoring a wishlist belong to [05 — Morale](05-morale.md).

❓ OPEN — related and unanswered: can a raider **refuse** an item, can the player **take gear off** a raider to give it to someone else, and does a leaving raider (canon: morale 10–30 *"may leave guild"*) take their gear with them? The first two are loot-routing questions with morale consequences and are answered here: refusal no, re-assignment yes with a small morale cost to the raider losing the item.

The third is **not this doc's to answer.** Gear binding and departure are owned by [04 — Recruitment & Roster Management](04-recruitment-and-roster.md) §13, which holds the strip-and-fire exploit analysis. Its rule, which this doc adopts verbatim rather than restating a rival version:

- **Bound = the gear a recruit arrives wearing (generation gear) only.** Guild-issued loot is never bound.
- **Unbind trigger:** automatic when `CT > recruited_at_tier`.
- **On departure or firing:** still-bound arrival pieces leave with the raider; everything else — all guild-issued loot, plus unbound arrival gear — returns to the bank.

So morale neglect still costs the player material, but it costs the *recruit's own* starting kit, not the tier's raid drops. Anything in this doc that reads as "a leaving raider keeps whatever they are wearing" is superseded by the above.

---

## 15. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| OQ-1 | Is the Warrior head its own family (matrix) or shared with Bard (every authored table)? | Decides whether Warrior and Bard compete for the helm, and whether head authoring doubles for that group. | Shared. One `WARBARD` head family; delete the matrix's `Warrior` head cell. |
| OQ-2 | Is `Raider's Boots — 4 AC / +4 HP` one item contested 4 ways, or two identical items in two families? | Changes Boss 1 contention from 2-way to 4-way and sets the precedent for every Feet drop. | Two items, same stats, family-qualified IDs. |
| OQ-3 | Monk and Rogue get a head at Boss 3 *and* Boss 5; everyone else gets one head per tier. Intended? | Two heads per tier means their Boss 3 head is dead loot as soon as Boss 5 falls. | Intended: it is their capstone. Make the Boss 3 head a clear stepping stone (see §10.2). |
| OQ-4 | Do healer weapons carry one variable (Mana) or two (Mana + Power)? Canon: *"we need to discuss if we want to have 2 variables or not."* | Blocks all six healer weapon stat blocks and the healing formula in doc 08. | One variable: Mana. Power is defined as melee damage; healers do not melee. |
| OQ-5 | Boss 3: does it drop "Head + stronger shared gear" (raw notes) or Head alone (ideaboard §4)? | An entire encounter's second drop is either missing from the tables or does not exist. | Head + the tier's off-hands (Shield / Instrument / Tome), which also fixes the empty Adventure off-hand. |
| OQ-6 | How many copies of each item drop per encounter? | With raid size 12 and one trinket per Boss 5, trinketing the roster takes 12 clears. | **Not owned here.** Use [10 §4.2](10-content-and-encounters.md): `E1:2 E2:2 E3:2 E4:3 E5:3 (+1 guaranteed Raid Trinket)`. This doc supplies the pool, doc 10 sets the counts. |
| OQ-7 | Is there Adventure-tier off-hand and starting-weapon content, or are those slots empty until the Tier 1 raid? | Warrior, Bard and all three healers currently show an empty off-hand for the whole Adventure phase. | Add both; blocks in §10.2. |
| OQ-8 | Does the player assign loot, or does it auto-assign? | Sole input to the wishlist/morale lever; also the biggest UI decision in the raid flow. | Master Looter with a one-click Suggested default (§14.3). |
| OQ-9 | Is the trinket name `Adventure's` / `Adventures` deliberate, given armor uses `Adventurer's`? | Three spellings of one prefix in four items; blocks the naming template. | Normalise all four to `Adventurer's Charm of X`. |
| OQ-10 | Does Mana actually appear on Warrior/Bard pieces, as the Bard note says? No Tier 1 piece has it. | Decides whether Warrior/Bard is a genuinely contested family or two classes sharing identical BiS. | Treat as Tier 2+ intent; author one Mana variant per Warrior/Bard slot from Tier 2. |
| OQ-11 | Does an Adventure-tier Rogue equip two Iron Adventurer's Swords (+10) against a Warrior's one (+5)? | Doubles Rogue weapon demand and changes early DPS balance. | Yes, two copies — the Boss 1 Rogue row lists the same dagger in both hands. |
| OQ-12 | Are the cross-tier multipliers (×1.10 AC/HP, ×1.15 Mana) right? | Single knob that sets total campaign power growth and therefore campaign length. | Ship with these, tune once doc 08's damage model exists. |
| OQ-13 | Tier 2–5 material and title words. | Every generated item name depends on them; the §11.4 candidates are placeholders. | Designer names them. Do not ship the placeholders. |
| OQ-14 | Does a raider who leaves keep their gear? | Turns morale neglect into a real material loss and changes how the player values loot. | **Not owned here** — rule lives in [04 §13.2](04-recruitment-and-roster.md), which holds the strip-and-fire exploit analysis. They keep still-bound arrival gear only; guild-issued gear returns to the bank. Bound = generation gear, unbinding at `CT > recruited_at_tier`. |
| OQ-15 | The Rogue's Boss 1 `Basic Raid Dagger — +4 Damage` is a **−1** step from the shared `Iron Adventurer's Sword — +5 Damage`, against a +1/+2 step for every other class. Intended (daggers trade damage for swings/positioning) or a canon slip? | The first raid drop in the game is a downgrade for one class; also breaks the §10.2 / §13.2 weapon-scaling anchor and, with OQ-11's two swords, makes the whole Boss 1 loadout worse (+8 vs +10). | Treat the canon numbers as canon and **do not silently fix them.** Either give the Rogue extra swings in doc 07 / doc 08, or the designer raises the dagger to `+5` / `+7`. Same question as [08 §13 Q10](08-stats-and-formulas.md) and [11 §14 Q6](11-economy-and-crafting.md); it is this doc's call to make because this doc owns the item tables. |

---

## Related documents

- [04 — Recruitment & Roster Management](04-recruitment-and-roster.md) — what gear an uncommon/rare/epic/legendary recruit arrives already wearing (drawing directly on the tables in §5–§8), and the **owner** of gear binding and the departing-raider rule behind OQ-14.
- [05 — Morale](05-morale.md) — the morale deltas for honouring, ignoring, or selling a wishlisted item; consumes the loot routing decided in §14.
- [06 — Classes, Roles & Raid Composition](06-classes-and-roles.md) — why each class wants AC, Power or Mana, and what differentiates the three healer capstones beyond their stat lines.
- [07 — Raid Simulation & The Mistake System](07-combat-simulation.md) — what a stat point does during a fight, and where OQ-15's "extra Rogue swings" option would live.
- [08 — Stats, Formulas & Numeric Model](08-stats-and-formulas.md) — resolves what `AC = 2 damage reduction` and `Mana = spell damage` actually compute to, which validates the §13 scaling; also flags the Rogue dagger step (§13 Q10 / OQ-15).
- [10 — Content Structure: Adventures, Raids & Encounters](10-content-and-encounters.md) — the five-encounter structure these drop tables hang on, and the **owner** of drops-per-encounter (§4.2), which answers OQ-6.
- [11 — Economy, Shops & Crafting](11-economy-and-crafting.md) — `sell_value`, whether upgrading or salvaging items changes the family model, and the bound-gear sell rule that must follow doc 04 §13.2's unbind trigger.
- [14 — Technical Architecture (Godot)](14-technical-architecture.md) — turns §12's schema into a Godot resource and owns the generator plus `overrides.csv` from §13.
