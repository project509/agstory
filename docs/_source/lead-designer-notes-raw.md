# Lead Designer Notes — Raw Capture

> **Status:** Verbatim capture of the lead designer's loose notes, as provided 2026-09-08.
> This file is **canon source material**. Do not edit it to "fix" or refine ideas —
> refinements belong in the numbered design docs, which must cite back to this file.
> Anything not in this file (or in `ideaboard-transcription.md`) is a proposal, not a decision.

---

## Premise

Clone of *It's A Wipe!* by Parody Games LLC, rebuilt with a 2D-HD aesthetic similar to *Octopath Traveler*.

## Town as progression engine

Core concept: the town will be improved by the raids you do. Mostly by gaining reputation levels. Which will unlock additional things in the town.

Instead of the guild simply being a menu between raids, make the town itself your progression engine.

### Guildhall

* Train raiders < Maybe if we have level ups
* Manage morale with comfort items
* Upgrade guild facilities < better morale values
* Quest/achievement board

### Tavern

* Recruits are found and managed here

### Market

* Buy consumables (Potions)
* Sell loot
* Crafting Supplies < Maybe

### Blacksmith (Maybe)

* Equipment upgrades < Maybe
* Salvaging < If we do crafting
* Weapons and armor crafting < If we do crafting

### Adventure's Board

* Adventure 0 - 1 Trash mob (Just for learning - 1 crap trinket)
* Tutorial Raid - 1 Boss (Just for learning - 1 crap trinket)
* Adventure 1 - a few trash encounters and a mini boss
* Raid 1 - Explained below
* Adventure 2 TBD ---
* Raid 2
* Adventure 3
* Raid 3
* Adventure 4
* Raid 4
* Adventure 5
* Raid 5

-- This continues or can go raid raid, adventure adventure, obviously they will need names later, but this is a placeholder --

Tutorials can be skip, but will offer a special loot piece that is easy, players will be warned that they will miss out on reward if they skip tutorial (not a big deal - not a great piece) Like a +1 dps trinket or something

New Tiers can be unlocked by gaining reputations with the town. Explained below....

## Guild Reputation

Your guild has a single primary stat: **Guild Reputation**

You start at:

Unknown

Then:

Known
Respected
Established
Renowned
Legendary

Reputation determines what starts appearing around town.

For example:

@Rank unknown you can only find the worst players to join your guild, they have 0 raid experience etc. (Common raiders)

@Known you have a chance to find raiders that have a small amount of experience, 1-2 pieces of basic adventure gear from your current raid tier etc.. (uncommon raiders)

@Respected you no longer find common and sometimes you find rare raiders players that are decent and only make mistakes sometimes (rare raiders) finding uncommon raiders is now common

@renowned you no longer find uncommon raiders and you have a chance to find raiders that very good have 1-2 pieces of current raid gear and rarely make a mistake (epic raiders) you also gain a VERY SMALL chance to find raiders that are basically perfect, near 1% chance of mistake, have a few pieces of raid gear from your current tier (Legendary raiders) - (You can only ever find 1 Legendary per class - They are also named characters - IE Natsuna(the shaman) or something.

This is all managed at the - Tavern

## Core things to do

You earn money.

You spend money at the blacksmith/Merchant.

You recruit people at the tavern as needed.

You take missions from the adventure board.

You improve the guild/raid team.

## Morale: 0-100

Every raider has a single morale value.

| Morale | State | Gameplay Effect |
|---|---|---|
| 0-10 | Very Upset | Very high mistake chance; may cause guild disband |
| 10-20 | Upset | Increased mistake chance; may leave guild |
| 20-30 | Unhappy | Increased mistake chance; may leave guild |
| 30-40 | Annoyed | Won't leave; noticeably higher mistake chance |
| 40-50 | Slightly Annoyed | Slightly increased mistake chance |
| 50-60 | Content | Base mistake chance |
| 60-70 | Happy | Reduced mistake chance |
| 70-80 | Very Happy | Further reduced mistake chance |
| 80-90 | Very Happy | Further reduced mistake chance |
| 90-100 | Loves Their Guild | Lowest mistake chance |

All values above are have within tier limits for mistakes based on their tier -

Gaining and losing Morale will be based on their back stories largely we can have bullet points for each raider that is recruited. Lower tier raiders will be hardest to keep happy, while legendary raiders will not be bothered by many things easily. (Meaning you wont have to worry about losing your higher tier raiders unless you are BIG dumb)

We could have raiders also know their bis and occasionally wishlist items for bonus morale. This is all just concepts and can easily be revisited, but that's the baseline for morale. Below is an example roster we may see.

Your roster might show:

Natsuna — 87 ❤️
Shaman — Very Happy

Bob — 54 🙂
Warrior — Content

Greg — 31 😒
Rogue — Annoyed

Steve — 14 😡
Mage — Upset

So when you're preparing a raid, you immediately know:

Oh shit, Steve is at 14. Maybe I shouldn't bring him, unless he really wants to go and I know I can beat the raid with him messing up.

That feels very appropriate for the guild-leader fantasy.

And importantly, the morale system itself stays extremely simple: one number, one state, one effect. The complexity comes from the stories and decisions surrounding it.

## Classes

| Class | Role | Description |
|---|---|---|
| Warrior | Main Tank | High survivability, high threat |
| Cleric | Main Tank Healer | Efficient single-target healing |
| Druid | Raid Healer | Small heal to the entire raid every round |
| Shaman | Chain Healer (bouncing heal) | Medium → medium → small healing |
| Rogue | Melee DPS | Position-dependent burst DPS |
| Monk | Melee DPS / Offtank | High DPS + emergency tank |
| Mage | AoE Caster | Raid spell buff + AoE damage |
| Wizard | Single-Target Caster | Very high single-target DPS |
| Bard | Support | Random song effects TBD |

I can go into LARGE amounts of detail when we get rdy to dive into classes.

I have thoughts and plans, its a lot.

I've also decided I'd like the raid size to be 12, most fights normally requiring 2 tanks.

## Stat definitions

AC = 2 damage reduction
Power = +1 melee dmg
Mana = spell damage (Subject to change)

## Starting armor for common recruits

**Warrior**
Head: Worn Iron Cap — 1 AC
Chest: Damaged Chainmail — 3 AC
Legs: Worn Leggings — 2 AC
Feet: Old Boots — 1 AC
Total: 7 AC

**Bard**
Head: Worn Iron Cap — 1 AC
Chest: Damaged Chainmail — 3 AC
Legs: Worn Leggings — 2 AC
Feet: Old Boots — 1 AC
Total: 7 AC

**Monk**
Head: Frayed Headband — 2 AC
Chest: Worn Gi — 2 AC
Legs: Worn Trousers — 1 AC
Feet: Old Sandals — 1 AC
Total: 6 AC

**Rogue**
Head: Worn Eyepatch — 1 AC
Chest: Old Leather Jerkin — 2 AC
Legs: Worn Leather Breeches — 1 AC
Feet: Worn Boots — 1 AC
Total: 5 AC

**Cleric**
Head: Worn Circlet — 1 AC
Chest: Tattered Vestments — 2 AC
Legs: Worn Leggings — 1 AC
Feet: Old Sandals — 1 AC
Total: 5 AC

**Druid**
Head: Worn Circlet — 1 AC
Chest: Tattered Hide Vest — 2 AC
Legs: Worn Leggings — 1 AC
Feet: Old Sandals — 1 AC
Total: 5 AC

**Shaman**
Head: Worn Headdress — 1 AC
Chest: Tattered Hide Vest — 2 AC
Legs: Worn Leggings — 1 AC
Feet: Old Sandals — 1 AC
Total: 5 AC

**Mage**
Head: Worn Apprentice Cap — 1 AC
Chest: Tattered Robe — 1 AC
Legs: Worn Trousers — 1 AC
Feet: Old Slippers — 1 AC
Total: 4 AC

**Wizard**
Head: Worn Apprentice Cap — 1 AC
Chest: Tattered Robe — 1 AC
Legs: Worn Trousers — 1 AC
Feet: Old Slippers — 1 AC
Total: 4 AC

Tier 1 Adventure gear in screenshots.

## Weapons (Tier 1 Adventure)

Warrior / Rogue / Bard
Iron Adventurer's Sword
+5 Damage

Monk
Iron Adventurer's Staff
+9 Damage

Mage
Apprentice's Firestaff
+10 Damage

Wizard
Apprentice's Arcstaff
+10 Damage

Healers
Class-specific healer weapons (Will have mana or power unsure how much) we need to discuss if we want to have 2 variables or not.
Stats TBD until we establish the healing/Mana formulas.

## Trinkets (Tier 1 Adventure)

Adventure's Charm of Health — +7 Hp
Adventure's Charm of Armor — +2 AC
Adventure's Charm of Mana — +10 Mana
Adventures Charm of Power — +2 Power

## Raid Layout and loot drops

| Encounter | Drops | Difficulty |
|---|---|---|
| Encounter 1 (Trash) | Feet + basic weapons | ★ |
| Encounter 2 (Harder trash) | Legs + healer off-hand | ★★ |
| Encounter 3 (Mini boss) | Head + stronger shared gear | ★★★ |
| Encounter 4 (Mini boss) | Chest + strong weapons | ★★★★ |
| Encounter 5 (Main boss of tier) | Class-specific + trinkets | ★★★★★ |

## Direction given alongside the notes

* 2D-HD aesthetic similar to *Octopath Traveler*.
* Aseprite is in the project root; use it heavily for sprite work.
* Likely engine: Godot.
* "Really awesome frontend design" is a priority.
