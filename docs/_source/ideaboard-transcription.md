# Ideaboard Transcription — Equipment & Loot Tables

> **Status:** Faithful transcription of the nine screenshots in `/ideaboard/`, provided by the
> lead designer. This file is **canon source material** alongside `lead-designer-notes-raw.md`.
> Numbers here override any number invented elsewhere in the design docs.
> Where a cell is blank in the source it is written as `—` (no drop / not applicable).

| Screenshot | Contents |
|---|---|
| `Screenshot_2026-08-27_033817.png` | Equipment slot matrix (which class can use which item family) |
| `Screenshot_2026-08-27_040809.png` | Tier 1 Adventure gear — Warrior/Bard armor, Monk/Rogue armor |
| `Screenshot_2026-08-27_040835.png` | Tier 1 Adventure gear — Healer armor, Mage/Wizard armor |
| `Screenshot_2026-08-27_044354.png` | Tier 1 Raid gear — Warrior, Bard |
| `Screenshot_2026-08-27_044548.png` | Tier 1 Raid gear — Monk |
| `Screenshot_2026-08-27_044612.png` | Tier 1 Raid gear — Rogue |
| `Screenshot_2026-08-27_044623.png` | Tier 1 Raid gear — Cleric, Druid |
| `Screenshot_2026-08-27_044633.png` | Tier 1 Raid gear — Shaman, Mage |
| `Screenshot_2026-08-27_044640.png` | Tier 1 Raid gear — Wizard |

---

## 1. Equipment Slot Matrix

*Source: `Screenshot_2026-08-27_033817.png`*

Defines which item **family** fills each slot per class. This is the itemization sharing model —
it determines which classes compete for the same drop.

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

**Observations implied by the matrix (not stated in the source):**
- Head is more fragmented than body armor: Warrior has its own head family, Monk and Rogue each
  have a distinct head item, but Bard shares Head with Warrior.
- Note the asymmetry between Head and Chest/Legs/Feet for Warrior: Head is "Warrior" alone while
  Chest/Legs/Feet is "Warrior/Bard".
- Rogue dual-wields the shared Warrior/Rogue/Bard 1H family in both hands.
- Monk, Mage, and Wizard have no off-hand at all (2H weapons).

---

## 2. Tier 1 Adventure Gear — Armor

*Source: `Screenshot_2026-08-27_040809.png`, `Screenshot_2026-08-27_040835.png`*

### 2.1 Warrior / Bard Armor

| Slot | Item | AC | HP | Power | Mana |
|---|---|---|---|---|---|
| Head | Iron Adventurer's Helm | 3 | +3 | — | — |
| Chest | Iron Adventurer's Cuirass | 5 | +6 | — | — |
| Legs | Iron Adventurer's Greaves | 4 | +4 | — | — |
| Feet | Iron Adventurer's Boots | 3 | +3 | — | — |
| **Total** | | **15** | **+16** | — | — |

### 2.2 Monk / Rogue Armor

| Slot | Item | AC | HP | Power | Mana |
|---|---|---|---|---|---|
| Monk Head | Ironbound Headband | 4 | +2 | — | — |
| Rogue Head | Reinforced Rogue Eyepatch | 3 | +2 | — | — |
| Chest | Reinforced Leather Vest | 4 | +5 | — | — |
| Legs | Reinforced Leather Leggings | 3 | +4 | — | — |
| Feet | Reinforced Leather Boots | 3 | +3 | — | — |
| **Monk Total** | | **14** | **+14** | — | — |
| **Rogue Total** | | **13** | **+14** | — | — |

### 2.3 Healer Armor (Cleric / Druid / Shaman)

| Slot | Item | AC | HP | Power | Mana |
|---|---|---|---|---|---|
| Head | Blessed Adventurer's Circlet | 2 | +2 | — | +3 |
| Chest | Blessed Adventurer's Robe | 3 | +5 | — | +5 |
| Legs | Blessed Adventurer's Leggings | 2 | +3 | — | +3 |
| Feet | Blessed Adventurer's Shoes | 2 | +2 | — | +2 |
| **Total** | | **9** | **+12** | — | **+13 Mana** |

### 2.4 Mage / Wizard Armor

| Slot | Item | AC | HP | Power | Mana |
|---|---|---|---|---|---|
| Head | Apprentice's Reinforced Cap | 2 | +2 | — | +4 |
| Chest | Reinforced Spellweave Robe | 2 | +4 | — | +6 |
| Legs | Spellweave Leggings | 2 | +2 | — | +4 |
| Feet | Spellweave Slippers | 2 | +2 | — | +3 |
| **Total** | | **8** | **+10** | — | **+17 Mana** |

### 2.5 Adventure armor totals at a glance

| Armor family | AC | HP | Mana |
|---|---|---|---|
| Warrior / Bard | 15 | +16 | — |
| Monk | 14 | +14 | — |
| Rogue | 13 | +14 | — |
| Healer (Cleric/Druid/Shaman) | 9 | +12 | +13 |
| Mage / Wizard | 8 | +10 | +17 |

---

## 3. Tier 1 Raid Gear

*Sources: `Screenshot_2026-08-27_044354.png` through `Screenshot_2026-08-27_044640.png`*

Columns are the five encounters of the Tier 1 raid (Boss 1 → Boss 5). Each cell is the drop that
class receives from that encounter.

### 3.1 Warrior

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Helm — 5 AC / +5 HP / +1 Power | — | — |
| Chest | — | — | — | Raider's Cuirass — 7 AC / +9 HP / +2 Power | — |
| Legs | — | Raider's Greaves — 5 AC / +6 HP / +1 Power | — | — | — |
| Feet | Raider's Boots — 4 AC / +4 HP | — | — | — | — |
| Main Hand | Basic Raid Sword — +6 Damage | — | — | Strong Raid Sword — +8 Damage | — |
| Shield | — | — | — | — | Warrior Shield — 7 AC / +8 HP / +1 Power |
| Trinket | — | — | — | — | Raid Trinket |

### 3.2 Bard

> Source note, verbatim: *"Bard uses the same Warrior/Bard armor, so **Mana can appear on these
> pieces and compete with Power**."*

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Helm — 5 AC / +5 HP / +1 Power | — | — |
| Chest | — | — | — | Raider's Cuirass — 7 AC / +9 HP / +2 Power | — |
| Legs | — | Raider's Greaves — 5 AC / +6 HP / +1 Power | — | — | — |
| Feet | Raider's Boots — 4 AC / +4 HP | — | — | — | — |
| Main Hand | Basic Raid Sword — +6 Damage | — | — | Strong Raid Sword — +8 Damage | — |
| Instrument | — | — | — | — | Bard Instrument — +20 Mana |
| Trinket | — | — | — | — | Raid Trinket |

### 3.3 Monk

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Headband | — | — | Raider's Headband — 5 AC / +5 HP | — | Final Headband |
| Chest | — | — | — | Raider's Vest — 6 AC / +7 HP / +2 Power | — |
| Legs | — | Raider's Leggings — 5 AC / +6 HP / +1 Power | — | — | — |
| Feet | Raider's Boots — 4 AC / +4 HP | — | — | — | — |
| 2H Weapon | Basic Raid Staff — +10 Damage | — | — | Strong Raid Staff — +14 Damage | — |
| Trinket | — | — | — | — | Raid Trinket |

### 3.4 Rogue

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Eyepatch | — | — | Raider's Eyepatch — 4 AC / +4 HP / +2 Power | — | Final Eyepatch |
| Chest | — | — | — | Raider's Leather Vest — 6 AC / +7 HP / +2 Power | — |
| Legs | — | Raider's Leggings — 5 AC / +6 HP / +1 Power | — | — | — |
| Feet | Raider's Boots — 4 AC / +4 HP | — | — | — | — |
| Main Hand | Basic Raid Dagger — +4 Damage | — | — | Strong Raid Dagger — +6 Damage | — |
| Off Hand | Basic Raid Dagger — +4 Damage | — | — | Strong Raid Dagger — +6 Damage | — |
| Trinket | — | — | — | — | Raid Trinket |

### 3.5 Cleric

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Circlet — 3 AC / +4 HP / +7 Mana | — | — |
| Chest | — | — | — | Raider's Vestments — 4 AC / +7 HP / +10 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +6 Mana | — | — | — |
| Feet | Raider's Shoes — 3 AC / +4 HP / +4 Mana | — | — | — | — |
| Weapon | Basic Healing Weapon | — | — | Strong Healing Weapon | Cleric Weapon |
| Off Hand | — | Blessed Raider's Tome — 2 AC / +5 Mana | — | — | — |
| Trinket | — | — | — | — | Raid Trinket |

### 3.6 Druid

Identical to Cleric except the Boss 5 weapon.

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Circlet — 3 AC / +4 HP / +7 Mana | — | — |
| Chest | — | — | — | Raider's Vestments — 4 AC / +7 HP / +10 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +6 Mana | — | — | — |
| Feet | Raider's Shoes — 3 AC / +4 HP / +4 Mana | — | — | — | — |
| Weapon | Basic Healing Weapon | — | — | Strong Healing Weapon | Druid Weapon |
| Off Hand | — | Blessed Raider's Tome — 2 AC / +5 Mana | — | — | — |
| Trinket | — | — | — | — | Raid Trinket |

### 3.7 Shaman

Identical to Cleric/Druid except the Boss 5 weapon.

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Circlet — 3 AC / +4 HP / +7 Mana | — | — |
| Chest | — | — | — | Raider's Vestments — 4 AC / +7 HP / +10 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +6 Mana | — | — | — |
| Feet | Raider's Shoes — 3 AC / +4 HP / +4 Mana | — | — | — | — |
| Weapon | Basic Healing Weapon | — | — | Strong Healing Weapon | Shaman Weapon |
| Off Hand | — | Blessed Raider's Tome — 2 AC / +5 Mana | — | — | — |
| Trinket | — | — | — | — | Raid Trinket |

### 3.8 Mage

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Cap — 3 AC / +3 HP / +8 Mana | — | — |
| Chest | — | — | — | Raider's Robe — 4 AC / +6 HP / +12 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +8 Mana | — | — | — |
| Feet | Raider's Slippers — 3 AC / +3 HP / +6 Mana | — | — | — | — |
| 2H Staff | Basic Raid Staff — +11 Damage | — | — | Strong Raid Staff — +15 Damage | Mage Staff |
| Trinket | — | — | — | — | Raid Trinket |

### 3.9 Wizard

| Slot | Boss 1 | Boss 2 | Boss 3 | Boss 4 | Boss 5 |
|---|---|---|---|---|---|
| Head | — | — | Raider's Cap — 3 AC / +3 HP / +8 Mana | — | — |
| Chest | — | — | — | Raider's Robe — 4 AC / +6 HP / +12 Mana | — |
| Legs | — | Raider's Leggings — 3 AC / +4 HP / +8 Mana | — | — | — |
| Feet | Raider's Slippers — 3 AC / +3 HP / +6 Mana | — | — | — | — |
| 2H Staff | Basic Raid Staff — +12 Damage | — | — | Strong Raid Staff — +16 Damage | Wizard Staff |
| Trinket | — | — | — | — | Raid Trinket |

---

## 4. Drop-slot pattern confirmed by the tables

The per-class tables agree with the raid layout in the raw notes:

| Encounter | Slot dropped | Also drops |
|---|---|---|
| Boss 1 | Feet | Basic weapons (Sword / Dagger ×2 / Staff / Healing Weapon) |
| Boss 2 | Legs | Healer Off-Hand (Blessed Raider's Tome) |
| Boss 3 | Head | — |
| Boss 4 | Chest | Strong weapons |
| Boss 5 | Class-specific capstone (Shield / Instrument / Final Headband / Final Eyepatch / class Staff / class Healing Weapon) | Raid Trinket |

---

## 5. Values the source leaves undefined

These cells appear in the screenshots with a name but **no stat block**. They are open items, not
omissions in this transcription:

- **Warrior/Bard/Monk/Rogue/Cleric/Druid/Shaman/Mage/Wizard "Raid Trinket"** (Boss 5) — no stats.
- **Monk "Final Headband"** (Boss 5) — no stats.
- **Rogue "Final Eyepatch"** (Boss 5) — no stats.
- **Cleric / Druid / Shaman "Basic Healing Weapon", "Strong Healing Weapon"**, and the Boss 5
  class weapons (**Cleric Weapon**, **Druid Weapon**, **Shaman Weapon**) — no stats. The raw notes
  confirm healer weapon stats are TBD pending the healing/mana formula.
- **Mage Staff / Wizard Staff** (Boss 5) — no stats.
- **Power** column is empty (`—`) on every Tier 1 Adventure armor piece; Power only begins appearing
  on Tier 1 **Raid** armor.
