# 04 — Recruitment & Roster Management

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs how raiders enter the guild at the Tavern, exactly what data a generated raider carries, and every operation the player can perform on the roster afterwards.

## 1. Scope

**This doc owns:**

- The Tavern loop: candidate board, refresh cadence, recruit cost, hold, dismissal.
- The raider data model — the field-level contract doc 14 implements.
- Generation recipes per rarity tier (what a recruit arrives *with*).
- Name generation.
- Backstory format and the trigger-tag vocabulary backstories emit.
- Legendary characters as hand-authored definition files.
- Roster operations: cap, benching, firing, departures, mid-tier replacement.
- The balance risk created by recruits arriving in current-tier gear.

**This doc does NOT own:**

| Topic | Owner |
|---|---|
| Which rarities a reputation rank can roll, and at what probability | [03 — Guild Reputation](03-guild-reputation.md) |
| Morale numbers, band effects, gain/loss magnitudes, starting morale, departure rolls | [05 — Morale](05-morale.md) |
| Mistake chance per rarity — base, floor, ceiling, and the morale multipliers | [08 — Stats & Formulas](08-stats-and-formulas.md) §8.8 |
| How many candidate slots the Tavern shows | [02 — Town & Buildings](02-town-and-buildings.md) §5.2 |
| Class kits and abilities, raid composition, the 12 raid slots, role requirements | [06 — Classes & Roles](06-classes-and-roles.md) |
| Mistake resolution in combat — the roll sites, severity and cascade | [07 — Combat Simulation](07-combat-simulation.md) |
| Item stat tables and drop tables | [09 — Items & Itemization](09-items-and-itemization.md) |
| Gold prices, selling, salvaging, crafting | [11 — Economy & Crafting](11-economy-and-crafting.md) |
| Save schema, resource format, RNG service | [14 — Technical Architecture](14-technical-architecture.md) |

This doc **emits** morale trigger tags; it does not define what they are worth. It **consumes** a rarity result; it does not decide the odds.

---

## 2. Canon anchors this document is built on

Everything below is quoted or reproduced exactly. Nothing in this section is negotiable.

| # | Canon statement | Source |
|---|---|---|
| A1 | "Recruits are found and managed here" (Tavern) | canon: raw notes, Town § Tavern |
| A2 | "This is all managed at the - Tavern" | canon: raw notes, Guild Reputation |
| A3 | Ranks: Unknown → Known → Respected → Established → Renowned → Legendary | canon: raw notes, Guild Reputation |
| A4 | "@Rank unknown you can only find the worst players to join your guild, they have 0 raid experience etc. (Common raiders)" | canon: raw notes, Guild Reputation |
| A5 | "@Known you have a chance to find raiders that have a small amount of experience, 1-2 pieces of basic adventure gear from your current raid tier etc.. (uncommon raiders)" | canon: raw notes, Guild Reputation |
| A6 | "@Respected you no longer find common and sometimes you find rare raiders players that are decent and only make mistakes sometimes (rare raiders) finding uncommon raiders is now common" | canon: raw notes, Guild Reputation |
| A7 | "@renowned you no longer find uncommon raiders and you have a chance to find raiders that very good have 1-2 pieces of current raid gear and rarely make a mistake (epic raiders)" | canon: raw notes, Guild Reputation |
| A8 | "you also gain a VERY SMALL chance to find raiders that are basically perfect, near 1% chance of mistake, have a few pieces of raid gear from your current tier (Legendary raiders)" | canon: raw notes, Guild Reputation |
| A9 | "You can only ever find 1 Legendary per class - They are also named characters - IE Natsuna(the shaman) or something." | canon: raw notes, Guild Reputation |
| A10 | "Gaining and losing Morale will be based on their back stories largely we can have bullet points for each raider that is recruited." | canon: raw notes, Morale |
| A11 | "Lower tier raiders will be hardest to keep happy, while legendary raiders will not be bothered by many things easily. (Meaning you wont have to worry about losing your higher tier raiders unless you are BIG dumb)" | canon: raw notes, Morale |
| A12 | "We could have raiders also know their bis and occasionally wishlist items for bonus morale. This is all just concepts and can easily be revisited" | canon: raw notes, Morale |
| A13 | Example roster: Natsuna — 87 (Shaman, Very Happy); Bob — 54 (Warrior, Content); Greg — 31 (Rogue, Annoyed); Steve — 14 (Mage, Upset) | canon: raw notes, Morale |
| A14 | "I've also decided I'd like the raid size to be 12, most fights normally requiring 2 tanks." | canon: raw notes, Classes |
| A15 | Nine classes: Warrior, Cleric, Druid, Shaman, Rogue, Monk, Mage, Wizard, Bard | canon: raw notes, Classes |
| A16 | Per-class "Starting armor for common recruits" with exact AC values and totals | canon: raw notes, Starting armor for common recruits |
| A17 | Seven-slot equipment model, and Monk/Mage/Wizard have no off-hand (2H weapons) | canon: ideaboard, § 1 Equipment Slot Matrix |
| A18 | "Train raiders < Maybe if we have level ups" | canon: raw notes, Guildhall |

---

## 3. The Tavern loop

**Why this exists:** recruiting has to be a repeated, cheap-to-enter decision the player returns to between runs, because it is the only faucet for bodies and — per A7/A8 — a secondary faucet for gear.

### 3.1 Candidate board

✅ CANON: recruits are found and managed at the Tavern (A1, A2). Everything else in this section is 🔷 PROPOSED.

🔷 PROPOSED — the Tavern shows a **candidate board** of face-up candidate cards.

**Board size is not owned here.** It is a Tavern building level, not a reputation rank: see [02 — Town & Buildings](02-town-and-buildings.md) §5.2 ("Slots shown"), which doc 02 §11 already charges gold for. This doc previously published a rank-gated 3/3/4/4/5/5 ladder; that table is deleted so only one number exists. Two consequences of doc 02's table that this doc depends on: at Unknown every slot is Common (A4), and Legendary cards can only appear from Renowned onward (A8) regardless of Tavern level.

Each slot is rolled independently. Rarity per slot comes from doc 03's rank→rarity table; this doc's generator takes that rarity as an input.

🔷 PROPOSED — **duplicate-class softening.** After rolling classes for the board, if a class appears twice, reroll the second occurrence once. Prevents a board of three Wizards when the player is short a tank.

### 3.2 Refresh cadence

🔷 PROPOSED — the board refreshes on **run resolution**, not on a real-time timer.

| Trigger | Effect |
|---|---|
| Any Adventure or Raid run resolves (win or wipe) | Full board reroll; unheld candidates are gone |
| Guild reputation rank increases | Immediate full board reroll (so the new rank is visible at once) |
| Player pays reroll cost | Full board reroll |
| Real time passing | No effect |

**Why no timer:** a wall-clock timer teaches the player to sit in town and wait, which fights the canon framing of the town as the thing raids improve, not the thing that gates raids. Tying refresh to runs means "go do a raid" is always the answer to a bad board.

🔷 PROPOSED — **manual reroll cost:** `50g × 2^(rerolls_since_last_run)`, capped at 400g. Counter resets to 0 on run resolution.

🔷 PROPOSED — **hold:** the player may hold exactly one candidate across one refresh for 25% of that candidate's recruit cost, non-refundable, and the hold is lost if not converted on the next visit. Purpose: lets a player who cannot afford a Legendary right now go earn the gold, without making board state permanent.

### 3.3 Recruit cost

🔷 PROPOSED — `cost = base(rarity) × (1 + 0.6 × (CT − 1))` where `CT` = current content tier (highest raid tier unlocked), rounded to the nearest 10g.

| Rarity | Base cost | At CT 1 | At CT 3 | At CT 5 |
|---|---|---|---|---|
| Common | 60g | 60g | 130g | 200g |
| Uncommon | 180g | 180g | 400g | 610g |
| Rare | 450g | 450g | 990g | 1,530g |
| Epic | 1,100g | 1,100g | 2,420g | 3,740g |
| Legendary | 3,000g | 3,000g | 6,600g | 10,200g |

Worked example: at CT 3 the multiplier is `1 + 0.6 × 2 = 2.2`; an Epic costs `1100 × 2.2 = 2,420g`. At CT 5 the multiplier is `1 + 0.6 × 4 = 3.4`; the same Epic costs `1100 × 3.4 = 3,740g`. Gold values are placeholders until doc 11 sets the earn rate; the *ratios* are the design intent — an Epic should cost roughly what a full tier's clear pays out, so buying power is a real alternative to farming.

### 3.4 Dismissal

🔷 PROPOSED — dismissing a candidate from the board is free and instant; the slot stays empty until the next refresh. Firing a *recruited* raider is a roster operation, not a Tavern one — see §12.3.

### 3.5 What a candidate card must show

🔷 PROPOSED — the card is the entire decision surface and must be readable without a submenu: portrait and name (§7), class and role (A15), rarity badge (doc 03 roll), mistake chance as a plain percentage (value from doc 08 §8.8), a gear preview of filled/empty tier-coloured slots (§6), **all** backstory bullets (§8), wishlist if any (§9), recruit cost (§3.3).

Backstory bullets are never hidden pre-recruit. The joke only lands if the player knowingly hires the guy whose bullet says he quits when benched.

---

## 4. Raider data model

**Why this exists:** this table is the contract doc 14 implements. Field names here are the field names in code and in the save file.

| Field | Type | Range / values | Source | Notes |
|---|---|---|---|---|
| `id` | string (UUID v4) | — | 🔷 PROPOSED | Stable across saves; never reused |
| `display_name` | string | 1–24 chars | 🔷 PROPOSED (§7) | Canon examples: Bob, Greg, Steve, Natsuna (A13) |
| `class_id` | enum | `warrior`, `cleric`, `druid`, `shaman`, `rogue`, `monk`, `mage`, `wizard`, `bard` | ✅ CANON (A15) | Immutable after generation |
| `role` | enum (derived) | Main Tank, Main Tank Healer, Raid Healer, Chain Healer, Melee DPS, Melee DPS/Offtank, AoE Caster, Single-Target Caster, Support | ✅ CANON (A15) | Derived from `class_id`, never stored authoritatively |
| `rarity` | enum | `common`, `uncommon`, `rare`, `epic`, `legendary` | ✅ CANON (A4–A8) | Immutable; see Q6 on the name collision with the reputation rank "Legendary" |
| `legendary_def_id` | string \| null | e.g. `legendary_shaman` | ✅ CANON (A9) | Non-null only for `rarity = legendary` |
| `portrait_id` | string | asset key | 🔷 PROPOSED | Legendaries use a hand-drawn key; others draw from a class-appropriate pool |
| `morale` | int | 0–100 | ✅ CANON (raw notes, Morale) | Band and effect owned by doc 05 |
| `morale_band` | enum (derived) | Very Upset … Loves Their Guild | ✅ CANON (raw notes, Morale) | Derived; see Q2 on overlapping band edges |
| `mistake_chance_base` | float | per rarity — see [08 — Stats & Formulas](08-stats-and-formulas.md) §8.8 | Legendary ≈ 0.01 is ✅ CANON (A8); the table is doc 08's | The value at morale band Content (50–60), which canon calls "Base mistake chance" |
| `mistake_chance_floor` | float | per rarity — doc 08 §8.8 | 🔷 PROPOSED, owned by doc 08 | Clamp at best morale — canon's "within tier limits for mistakes based on their tier" |
| `mistake_chance_ceiling` | float | per rarity — doc 08 §8.8 | 🔷 PROPOSED, owned by doc 08 | Clamp at worst morale, same canon line |
| `raid_experience` | int | 0–n | ✅ CANON for Common = 0 (A4); ranges above it 🔷 PROPOSED | Display-only stat; does not feed combat math (see Q4) |
| `equipment` | dict[slot → item_id \| null] | 7 slots: `main_hand`, `off_hand`, `head`, `chest`, `legs`, `feet`, `trinket` | ✅ CANON (A17) | `off_hand` is permanently null for Monk, Mage, Wizard (A17) |
| `backstory` | array[BackstoryBullet] | length 2–4 | ✅ CANON that bullets exist (A10); count 🔷 PROPOSED | See §8 for the bullet record |
| `wishlist` | array[item_id] | length 0–2 | ❓ OPEN (A12 says "could") | Ship behind a feature flag |
| `traits` | array[trait_id] | length 0–2 | 🔷 PROPOSED (§10) | Mechanical, unlike backstory tags which are social |
| `recruited_at_tier` | int | 1–n | 🔷 PROPOSED | Needed for the bound-gear rule in §13 |
| `recruited_at_rank` | enum | reputation rank | 🔷 PROPOSED | Telemetry and "you hired this guy when you were nobody" flavour |
| `status` | enum | `active`, `benched`, `departed`, `fired` | 🔷 PROPOSED | `departed`/`fired` rows are retained for the guild log, excluded from the cap |
| `runs_attended` | int | ≥0 | 🔷 PROPOSED | Counter feeding morale triggers in §8 |
| `consecutive_benched` | int | ≥0 | 🔷 PROPOSED | Counter feeding `hates_being_benched` |
| `wipes_witnessed` | int | ≥0 | 🔷 PROPOSED | Counter feeding `scared_of_wipes` |
| `loot_received` | int | ≥0 | 🔷 PROPOSED | Counter feeding `only_here_for_loot` |
| `level` / `xp` | int / int | — | ❓ OPEN | Canon: "Train raiders < Maybe if we have level ups" (A18). Reserve the fields, do not read them, until doc 03 rules on level ups |

🔷 PROPOSED — nothing in this record is written by combat except the four counters and `morale`. That keeps the raider record safe to serialise mid-raid.

---

## 5. Generation pipeline

**Why this exists:** so two programmers generating a raider produce byte-identical output from the same seed.

🔷 PROPOSED — fixed order of operations. Each step consumes the RNG stream in this sequence:

1. **Rarity** — supplied by doc 03's rank→rarity roll. Not rolled here.
2. **Class** — uniform over the nine classes (A15), then the duplicate-class softening in §3.1. If `rarity = legendary`, restrict to classes whose Legendary has not yet been found (A9); if none remain, downgrade the roll to Epic.
3. **Legendary short-circuit** — if Legendary, load the definition file (§11) and skip steps 4, 7 and 8; the file supplies name, portrait, backstory, quirk, and optionally a starting-morale override. Step 6 still runs: Legendary mistake values come from doc 08 §8.8 like every other rarity, not from the definition file.
4. **Name** — §7.
5. **Gear** — §6 recipe for the rarity.
6. **Mistake chance** — base and floor/ceiling clamps per rarity from [08 — Stats & Formulas](08-stats-and-formulas.md) §8.8. Not rolled, and not tabulated here.
7. **Backstory** — draw 2–4 bullets per §8, respecting the exclusion rules.
8. **Morale** — consumes no RNG. Set to the computed baseline per [05 — Morale](05-morale.md) §4/§7.5, which is why backstory must be drawn first: the bullets supply doc 05's `backstory_offset`.
9. **Wishlist** — if the flag is on, roll per §9.
10. **Traits** — §10.
11. **Cost** — §3.3, computed last so it can read the generated gear (see Q7).

---

## 6. Generation recipes per rarity

**Why this exists:** rarity is the game's single promise about what a recruit is worth. It has to be a recipe, not an adjective.

### 6.1 Shared definitions

- `CT` = current content tier (highest raid tier unlocked).
- `starting_armor(class)` = the exact four-piece set in canon's "Starting armor for common recruits" (A16). Reproduced in §6.3.
- `adventure_set(class, T)` = the Tier-T Adventure gear for that class (canon Tier 1 in ideaboard §2, plus the Tier 1 Adventure weapons and trinkets in the raw notes).
- `raid_set(class, T)` = the Tier-T Raid gear for that class (canon Tier 1 in ideaboard §3).
- All slot fills respect A17: Monk, Mage and Wizard never receive an `off_hand`.

🔷 PROPOSED — **the Boss-5 lockout.** A recruit may never arrive wearing a Boss 5 drop: no Warrior Shield, Bard Instrument, Final Headband, Final Eyepatch, class Staff, class Healing Weapon, or Raid Trinket. Those are the terminal reward for clearing a tier and must not be purchasable at the Tavern. Chest (Boss 4) is Legendary-only.

🔷 PROPOSED — **slot draw weights** when granting raid gear, derived from the canon drop order (ideaboard §4) so recruits skew toward the early-boss slots the player has probably already farmed:

| Slot | Canon drop source | Epic weight | Legendary weight |
|---|---|---|---|
| Feet | Boss 1 | 30 | 22 |
| Main hand (basic) | Boss 1 | 25 | 20 |
| Legs | Boss 2 | 20 | 20 |
| Off hand | Boss 2 | 15 | 16 |
| Head | Boss 3 | 10 | 14 |
| Chest | Boss 4 | 0 | 8 |
| Boss 5 capstone / Trinket | Boss 5 | 0 | 0 |

Classes with no off-hand redistribute that weight proportionally across their remaining eligible slots.

### 6.2 Recipe table

| Rarity | Raid experience | Gear grant | Backstory bullets |
|---|---|---|---|
| Common | **0** ✅ CANON (A4) | `starting_armor(class)` exactly; **no weapon, no trinket** | 2, at least one negative 🔷 |
| Uncommon | 1–2 🔷 ("a small amount" ✅ A5) | `starting_armor`, then replace **1–2** slots from `adventure_set(class, CT)` ✅ CANON (A5) | 2–3 🔷 |
| Rare | 3–6 🔷 | `starting_armor`, then replace **3–4** slots from `adventure_set(class, CT)` 🔷 | 2–3 🔷 |
| Epic | 8–15 🔷 | **1–2** pieces from `raid_set(class, CT)` ✅ CANON (A7), then fill every remaining slot from `adventure_set(class, CT)` 🔷 | 2–3 🔷 |
| Legendary | 20+ 🔷 | **3–4** pieces from `raid_set(class, CT)` 🔷 (canon says "a few" ✅ A8), remaining slots from `adventure_set(class, CT)` 🔷 | 2–4, hand-authored ✅ (A9/A11) |

**Mistake base/floor/ceiling per rarity: see [08 — Stats & Formulas](08-stats-and-formulas.md) §8.8.** This doc used to publish its own per-rarity mistake numbers and its own clamp table; both are deleted. Doc 08 owns the values, the morale multipliers that move them, and the "within tier limits" clamp policy. The canon anchors those numbers must honour still bind: Legendary "near 1% chance of mistake" (A8), Epic "rarely make a mistake" (A7), Rare "only make mistakes sometimes" (A6), and the A11 consequence that a higher rarity is never made worse than a lower one by morale alone (doc 08 holds Legendary's ceiling below Epic's floor for exactly this reason).

**Starting morale is not rolled here either: `morale = baseline` per [05 — Morale](05-morale.md) §4/§7.5.** Doc 05 owns the morale value, and its baseline is `50 + rarity_offset + facility_bonus + backstory_offset` — so rarity is still legible on the recruit card (a Common walks in around 45, a Legendary around 62), it just is not a range this doc rolls inside.

Rare's *behaviour* is canon — "decent and only make mistakes sometimes" (A6). Its *loadout* is not stated anywhere, so the 3–4 adventure pieces are 🔷 PROPOSED. The intent is a clean ladder: Uncommon is partly kitted in adventure gear, Rare is fully kitted in adventure gear, Epic is the first rarity that arrives with raid gear (which is what A7 actually promises).

### 6.3 Common starting armor — canon values, reproduced exactly

✅ CANON (A16). These are the only gear values in this document that are already decided.

| Class | Head | Chest | Legs | Feet | Total AC |
|---|---|---|---|---|---|
| Warrior | Worn Iron Cap — 1 AC | Damaged Chainmail — 3 AC | Worn Leggings — 2 AC | Old Boots — 1 AC | 7 |
| Bard | Worn Iron Cap — 1 AC | Damaged Chainmail — 3 AC | Worn Leggings — 2 AC | Old Boots — 1 AC | 7 |
| Monk | Frayed Headband — 2 AC | Worn Gi — 2 AC | Worn Trousers — 1 AC | Old Sandals — 1 AC | 6 |
| Rogue | Worn Eyepatch — 1 AC | Old Leather Jerkin — 2 AC | Worn Leather Breeches — 1 AC | Worn Boots — 1 AC | 5 |
| Cleric | Worn Circlet — 1 AC | Tattered Vestments — 2 AC | Worn Leggings — 1 AC | Old Sandals — 1 AC | 5 |
| Druid | Worn Circlet — 1 AC | Tattered Hide Vest — 2 AC | Worn Leggings — 1 AC | Old Sandals — 1 AC | 5 |
| Shaman | Worn Headdress — 1 AC | Tattered Hide Vest — 2 AC | Worn Leggings — 1 AC | Old Sandals — 1 AC | 5 |
| Mage | Worn Apprentice Cap — 1 AC | Tattered Robe — 1 AC | Worn Trousers — 1 AC | Old Slippers — 1 AC | 4 |
| Wizard | Worn Apprentice Cap — 1 AC | Tattered Robe — 1 AC | Worn Trousers — 1 AC | Old Slippers — 1 AC | 4 |

❓ OPEN — canon lists no **weapon** for Common recruits; the weapon list is headed "Weapons (Tier 1 Adventure)". §6.2 therefore ships Commons unarmed. See Q3.

### 6.4 Generator pseudocode

```
func generate_raider(rarity, CT, rng) -> Raider:
    r = Raider.new()
    r.rarity = rarity
    r.class_id = roll_class(rarity, rng)          # excludes claimed Legendary classes
    if rarity == LEGENDARY:
        return apply_legendary_def(r, legendary_def_for(r.class_id), CT)

    r.display_name = roll_name(rarity, rng)
    r.equipment = starting_armor(r.class_id)      # canon baseline for every rarity
    r.raid_experience = rng.int_range(EXP[rarity])

    match rarity:
        COMMON:    pass
        UNCOMMON:  grant(r, adventure_set(r.class_id, CT), n = rng.int(1, 2))
        RARE:      grant(r, adventure_set(r.class_id, CT), n = rng.int(3, 4))
        EPIC:
            grant_weighted(r, raid_set(r.class_id, CT), n = rng.int(1, 2), EPIC_WEIGHTS)
            fill_remaining(r, adventure_set(r.class_id, CT))

    r.mistake_chance_base    = MISTAKE[rarity].base    # table: doc 08 §8.8
    r.mistake_chance_floor   = MISTAKE[rarity].floor   # table: doc 08 §8.8
    r.mistake_chance_ceiling = MISTAKE[rarity].ceiling # table: doc 08 §8.8
    r.backstory  = roll_backstory(r, rng)         # §8, before morale: it sets backstory_offset
    r.morale     = morale_baseline(r)             # doc 05 §4/§7.5 — not rolled
    r.wishlist   = roll_wishlist(r, CT, rng) if WISHLIST_ENABLED else []
    r.traits     = roll_traits(r, rng)
    return r
```

`grant` and `grant_weighted` never write a Boss-5 slot, never write `off_hand` for Monk/Mage/Wizard, and never overwrite a slot already holding a higher-tier item.

---

## 7. Names

**Why this exists:** the joke is that this reads like a real guild roster, and canon's own examples — Bob, Greg, Steve — are aggressively ordinary. A fantasy name generator would kill the premise on sight.

🔷 PROPOSED — three name **shapes**, weighted. Legendaries bypass this entirely (§11).

| Shape | Weight | Construction | Reads like |
|---|---|---|---|
| A — Bare mundane | 62% | One entry from the mundane given-name pool | `Bob`, `Greg`, `Steve` (canon texture, A13) |
| B — Mundane, mangled | 26% | Mundane name + one mangle: doubled final consonant, dropped/added vowel, trailing digit, `_` + digit | `Dougg`, `Steev`, `Kevin7` |
| C — Mundane + fantasy mash | 12% | Mundane name + space + epithet from a small fantasy-noun list | `Gary Bloodfang`, `Phil the Bold` |

🔷 PROPOSED — constraints the generator must enforce:

- Never two live raiders with the same `display_name`; on collision, apply a shape-B mangle, then a numeric suffix.
- Never generate a shape-B or shape-C form of a name already live in the roster (no `Steve` **and** `Steev`).
- Shape C epithet list stays short (≈20 entries) so it reads as a running gag, not a generator.
- Pool is data, not code: `data/names/mundane.txt`, `data/names/epithets.txt`, hot-reloadable.
- A shape-B handle is the raider's name everywhere — the card, the log, the report, the record wall — and nothing restyles it: no "goes by", no quotation marks, no second line ([15 BL-120](15-open-questions.md#bl-120); Pillar 2's one-name rule). `Pauline_4` is Pauline_4.

### 7.1 Forty sample outputs

Proving the tone. Canon's own four are marked.

| # | Name | Shape | | # | Name | Shape |
|---|---|---|---|---|---|---|
| 1 | Bob ✅ | A | | 21 | Bobb | B |
| 2 | Greg ✅ | A | | 22 | Gregg | B |
| 3 | Steve ✅ | A | | 23 | Steev | B |
| 4 | Dave | A | | 24 | Dougg | B |
| 5 | Gary | A | | 25 | Kevinn | B |
| 6 | Terry | A | | 26 | Terrry | B |
| 7 | Barry | A | | 27 | Randee | B |
| 8 | Kevin | A | | 28 | Phill | B |
| 9 | Doug | A | | 29 | Marvv | B |
| 10 | Randy | A | | 30 | Kevin7 | B |
| 11 | Neil | A | | 31 | Dave_2 | B |
| 12 | Phil | A | | 32 | Barry99 | B |
| 13 | Dennis | A | | 33 | Sharonn | B |
| 14 | Marv | A | | 34 | Deb1 | B |
| 15 | Carl | A | | 35 | Gary Bloodfang | C |
| 16 | Wayne | A | | 36 | Phil the Bold | C |
| 17 | Deb | A | | 37 | Brenda Doomhowl | C |
| 18 | Brenda | A | | 38 | Carl Skullmender | C |
| 19 | Sharon | A | | 39 | Wayne of the Ninefold Path | C |
| 20 | Janice | A | | 40 | Big Ron | C |

🔷 PROPOSED — **content review gate.** Before ship, one named reviewer passes the mundane pool and asserts that no entry, and no shape-B/C combination of entries, reads as a real identifiable person being mocked. Rules for the pool: given names only, no surnames, no full-name pairs, no names of public figures, no names matching anyone on the dev team or in the community. Shape-C mashes are the risk case — an epithet plus a common given name can accidentally land on a real player handle, so the epithet list is reviewed against the same standard.

---

## 8. Backstories

**Why this exists:** ✅ CANON (A10) makes backstories the primary driver of morale gain and loss. That means the backstory is not flavour text — it is the raider's subscription list of morale events.

### 8.1 Format

🔷 PROPOSED — `backstory` is an array of 2–4 `BackstoryBullet` records:

| Field | Type | Notes |
|---|---|---|
| `text` | string | The line shown on the card. Written per-tag with 3–6 variants for variety |
| `tag` | enum | One of the trigger tags in §8.3. This is the only field doc 05 reads |
| `polarity` | enum | `positive`, `negative`, `mixed` — drives icon colour on the card |
| `weight` | float | 0.5 / 1.0 / 1.5 — how strongly this raider feels it; doc 05 multiplies its delta by this |

🔷 PROPOSED — draw rules:

- Bullet count by rarity per §6.2. One bullet = one tag; a raider never carries the same tag twice.
- Tags are drawn from an exclusion graph: `worships_guild_leader` cannot co-occur with `resents_authority`; `only_here_for_loot` cannot co-occur with `gear_indifferent`.
- Commons must include at least one `negative` bullet — canon: "Lower tier raiders will be hardest to keep happy" (A11).
- Epics and above draw at most one `negative` bullet. Legendaries use hand-authored bullets only (§11).

### 8.2 Worked examples

**Common Warrior — "Bob"** (canon's Bob is a Warrior at morale 54, A13):

```
display_name: "Bob"
class_id: warrior      rarity: common      raid_experience: 0
equipment:
  head: Worn Iron Cap (1 AC)          chest: Damaged Chainmail (3 AC)
  legs: Worn Leggings (2 AC)          feet:  Old Boots (1 AC)
  main_hand: null   off_hand: null    trinket: null          # total 7 AC (canon)
mistake_chance_base: 0.24   floor: 0.12   ceiling: 0.85   # doc 08 §8.8, Common row (2400 / 1200 / 8500 bp)
morale: 45                                                # baseline for a Common, doc 05 §4
backstory:
  - text: "Has never actually been in a raid. Says he's read about it."
    tag: scared_of_wipes           polarity: negative   weight: 1.0
  - text: "Will not stop asking when he gets to hold the big sword."
    tag: only_here_for_loot        polarity: negative   weight: 0.5
traits: [slow_learner]
wishlist: [basic_raid_sword]
```

**Legendary Shaman — "Natsuna"** ✅ CANON name and class (A9), bullets 🔷 PROPOSED:

```
display_name: "Natsuna"
class_id: shaman      rarity: legendary      legendary_def_id: legendary_shaman
raid_experience: 24
equipment (CT = 1, 3 raid pieces rolled: feet, legs, main hand):
  head:  Blessed Adventurer's Circlet (2 AC / +2 HP / +3 Mana)      # adventure fill
  chest: Blessed Adventurer's Robe (3 AC / +5 HP / +5 Mana)         # adventure fill
  legs:  Raider's Leggings (3 AC / +4 HP / +6 Mana)                 # raid, Boss 2
  feet:  Raider's Shoes (3 AC / +4 HP / +4 Mana)                    # raid, Boss 1
  main_hand: Basic Healing Weapon (stats TBD — canon)               # raid, Boss 1
  off_hand: null                                                    # no adventure-tier healer off-hand exists in canon — see Q9
  trinket: null                                                     # Boss-5 lockout
mistake_chance_base: 0.012  floor: 0.009  ceiling: 0.025  # doc 08 §8.8, Legendary row (120 / 90 / 250 bp)
morale: 87                 # canon example value, A13 — a roster value after play, not a
                           # starting value; a fresh Legendary starts at baseline (doc 05 §4)
backstory (hand-authored, fixed):
  - text: "Has cleared every tier of content already. Came back because it was boring out there."
    tag: gear_indifferent          polarity: positive   weight: 1.0
  - text: "Calls every wipe 'data'. Does not appear to be joking."
    tag: unbothered_by_wipes       polarity: positive   weight: 1.5
  - text: "Will walk if she is benched for a boss she has not seen die."
    tag: hates_being_benched       polarity: negative   weight: 1.5   # her BIG dumb lever
quirk: chain_heal_never_misses_third_target
```

Note how A11 is expressed mechanically: Natsuna subscribes to almost nothing, and the one thing she does care about is a lever the player has to actively pull wrong.

### 8.3 Reusable backstory tags

🔷 PROPOSED — the shared vocabulary. Doc 05 owns the deltas; this table owns the names and the events they listen for. Every tag must be listenable, or it does not ship.

| # | Tag | Bullet reads like | Listens for | Polarity |
|---|---|---|---|---|
| 1 | `hates_being_benched` | "Left his last guild over a bench decision." | Run resolves with this raider not in the 12 | negative |
| 2 | `only_here_for_loot` | "Openly here for the gear. Says so in the interview." | Loot awarded — to self (up) or to another raider of the same class (down) | mixed |
| 3 | `worships_guild_leader` | "Has your old raid logs printed out." | Reputation rank increase; any raid win | positive |
| 4 | `scared_of_wipes` | "Cries during wipes. Every wipe." | Raid wipe with this raider present | negative |
| 5 | `unbothered_by_wipes` | "Calls every wipe 'data'." | Raid wipe with this raider present | positive |
| 6 | `class_rival:<class>` | "Refuses to speak to Wizards." | Named class present in the same raid roster | negative |
| 7 | `needs_a_friend` | "Only joined because his mate did." | A rostered raider departs or is fired / is in the same raid | mixed |
| 8 | `glory_hound` | "Wants his name said out loud after fights." | This raider was top of their role's contribution in a run | mixed |
| 9 | `chronically_late` | "Was late to the interview." | Every run start (self-inflicted, always fires small) | negative |
| 10 | `gear_snob` | "Notices when someone is wearing last tier." | Own equipment contains an item below CT at run start | negative |
| 11 | `gear_indifferent` | "Would raid naked. Has offered to." | Own equipment below CT at run start (no penalty; small positive when passing loot) | positive |
| 12 | `wants_to_tank` | "Insists he is a tank. He is a Rogue." | Role assignment for the run does not include a tank slot for them | negative |
| 13 | `superstitious` | "Will not pull without saying the thing." | First attempt of a boss; attempt number is a multiple of 13 | mixed |
| 14 | `homesick` | "Talks about going home a lot." | `runs_attended` crosses each multiple of 5 without a rest week | negative |
| 15 | `in_debt` | "Being followed by someone he owes." | Guild gold below a threshold at payday | negative |
| 16 | `loves_the_tavern` | "Has a tab. It is large." | Comfort item purchased; guild facility upgraded | positive |
| 17 | `mentor` | "Keeps trying to teach the new people." | A Common or Uncommon raider is recruited | positive |
| 18 | `blames_the_healers` | "Has a theory about why he died." | This raider dies during an encounter | negative |

🔷 PROPOSED — every event above is emitted by systems that already exist in the loop (run resolve, loot award, purchase, rank up, recruit, death). Adding a tag that needs a new event is a design change, not content work.

---

## 9. Wishlists

❓ OPEN — canon is explicitly tentative: "We could have raiders also know their bis and occasionally wishlist items for bonus morale. This is all just concepts and can easily be revisited" (A12). That uncertainty is preserved: wishlists ship behind a flag and the game must be playable with the flag off.

🔷 PROPOSED, if enabled:

| Rule | Value |
|---|---|
| Chance a generated raider has a wishlist | 40% for Common–Rare, 70% for Epic, always for Legendary |
| Length | 1 item (Common–Rare), 1–2 (Epic+) |
| Eligible items | Any `raid_set(class, CT)` piece the raider does not have, weighted toward the slot they are worst in |
| Refresh | Rerolls when the wished item is obtained, or when CT increases |
| Effect | Morale bonus on receiving it; morale penalty if it is awarded to someone else. Magnitudes: doc 05 |

---

## 10. Traits — post-1.0

**Cut for 1.0 ([15 BL-96](15-open-questions.md#bl-96), confirmed 2026-09-15):** the designer's texture axis for a raider is the backstory bullet (Pillar 3) and the fight's inputs are rarity and morale; four of the six traits are bullets wearing a mechanic and the two that touch the fight would be a sixth axis on a card already reading five things. `Raider.traits` stays serialised and empty ([14 §5](14-technical-architecture.md)); no code ships behind a flag. The table below is the post-1.0 spec.

🔷 PROPOSED — traits are the *mechanical* counterpart to backstory tags: they touch combat or economy, not morale. Kept deliberately tiny so they do not compete with class design (doc 07).

| Trait | Effect | Eligible rarities |
|---|---|---|
| `slow_learner` | +2pp mistake chance on the first attempt of any boss | Common, Uncommon |
| `clutch` | −5pp mistake chance while the raid is below 3 living members | any |
| `expensive` | +40% recruit cost, −0 elsewhere (pure comedy tax; visible on the card) | any |
| `cheap_date` | Comfort items cost 25% less for this raider | Common–Rare |
| `fragile_ego` | Doubles the weight of this raider's negative backstory bullets | Common–Rare |
| `iron_stomach` | Halves the weight of this raider's negative backstory bullets | Rare+ |

Trait count is 0–2, and `fragile_ego` / `iron_stomach` are mutually exclusive.

---

## 11. Legendaries as characters

**Why this exists:** ✅ CANON (A9) makes Legendaries unique, named, one-per-class-ever. That makes them content, not generator output, and it makes reaching Renowned the moment the game hands the player a real character.

### 11.1 Canon constraints

| Constraint | Source |
|---|---|
| One Legendary per class, ever, for the whole run | ✅ CANON (A9) |
| They are named characters, e.g. "Natsuna(the shaman)" | ✅ CANON (A9) |
| First findable at Renowned, at a "VERY SMALL chance" | ✅ CANON (A8) |
| Near 1% mistake chance; a few pieces of current-tier raid gear | ✅ CANON (A8) |
| "legendary raiders will not be bothered by many things easily … unless you are BIG dumb" | ✅ CANON (A11) |

❓ OPEN — canon names exactly one Legendary, and hedges even that ("IE Natsuna(the shaman) or something"). The other eight are unnamed. This doc does **not** invent them: they are referred to as `legendary_warrior`, `legendary_cleric`, and so on, and naming is pending the lead designer.

### 11.2 Definition file

🔷 PROPOSED — one file per class at `data/legendaries/<class>.json`. Nine files, hand-authored, no procedural fields. Format per [14 — Technical Architecture](14-technical-architecture.md) §5.1 (authored content is JSON under `data/`); the loader is `content_db.gd`, which also validates these files at boot. Not `.tres`: doc 14's deciding argument is that `.tres` needs `ResourceLoader`, which `sim/` may not call, and the generator in §6.4 runs inside `sim/`.

| Field | Type | Notes |
|---|---|---|
| `legendary_def_id` | string | e.g. `legendary_shaman` |
| `display_name` | string | Natsuna is the only canon value; the other eight are DECIDED — Gunnar, Ottilie, Alder, Solenne, Casimir, Tallis, Isaura, Lorcan ([15 BL-117](15-open-questions.md#bl-117); W8-ITEMS sets them) |
| `class_id` | enum | Must be unique across all nine files |
| `portrait_set` | asset keys | Full portrait plus roster thumbnail; hand-drawn, not pooled |
| `backstory` | array[BackstoryBullet] | 2–4, fixed, never rolled |
| `starting_morale` | int \| null | **Optional override only.** Default is null, meaning the computed baseline per [05 — Morale](05-morale.md) §4/§7.5 — not a fixed 75. Set it only where a specific character's fiction demands walking in above or below their rarity's baseline |
| `morale_rules` | record | See §11.3 |
| `quirk` | record | One class-flavoured mechanical gift; specced in [07 §5.6](07-combat-simulation.md) — the nine ruled rows are [15 BL-58](15-open-questions.md#bl-58)'s — and named here ([Q-58](15-open-questions.md#q-58): the owner moved from a filename that did not exist to doc 07's mistake catalogue, because a quirk is an immunity to, or a threat shave against, one of doc 07's own mistake types) |
| `recruit_cost_override` | int \| null | Optional flat price instead of §3.3 |
| `gear_grant` | record | Count of raid pieces (3–4) and any forced slot |
| `dialogue_barks` | array[string] | Tavern and raid one-liners; the character's voice |

### 11.3 "Not easily bothered", expressed as rules

🔷 PROPOSED — three mechanisms, all in `morale_rules`:

| Mechanism | Value | Purpose |
|---|---|---|
| `subscribed_tags` | Only the tags in this Legendary's own backstory. All other events are ignored outright | Direct expression of A11 |
| `delta_multiplier` | 0.35 on negative deltas, 1.0 on positive | Slow to anger, normal to please |
| `morale_floor` | 40 (band: Slightly Annoyed) while no BIG-dumb condition is active | Guarantees they never drift into the leave/disband bands by neglect |

🔷 PROPOSED — **"BIG dumb" conditions.** Canon says losing a Legendary should require the player being "BIG dumb" (A11). That has to be a finite list, or it is not implementable. While any of these is true, `morale_floor` is suspended and `delta_multiplier` rises to 1.0:

| # | Condition | Reads as |
|---|---|---|
| 1 | Benched for 5 consecutive runs | "You stopped using them" |
| 2 | Wiped on the same boss 3 times in a row with them in the raid | "You are not learning" |
| 3 | An item on their wishlist awarded to a lower-rarity raider of the same class, twice | "You insulted them, twice" |
| 4 | Any of their own backstory bullets triggered 3+ times in one tier | "You did the one thing they told you not to" |
| 5 | Guild gold at 0 on payday for 2 consecutive paydays | "You cannot pay them" |

If none of these is true, a Legendary cannot fall below 40 morale, and therefore cannot enter the canon "may leave guild" bands (10–30) at all.

### 11.4 Loss and permanence

❓ OPEN — if a Legendary departs, is that class's Legendary spent forever? A9 says "You can only ever find 1 Legendary per class", which reads as spent. 🔷 PROPOSED default: yes, permanent — with a hard, unmissable confirmation the *first* time a Legendary crosses below 40, and a persistent roster warning while any BIG-dumb condition is active. Losing a hand-authored character should be a story the player tells, but it must never be a surprise. See Q10.

---

## 12. Roster operations

### 12.1 Roster cap

✅ CANON: raid size is 12, "most fights normally requiring 2 tanks" (A14). ❓ OPEN: canon never states a roster cap.

🔷 PROPOSED — the cap must **exceed** 12. A cap of exactly 12 means every recruited raider is always in the raid, which deletes benching, deletes the "should I bring Steve at 14?" decision that canon calls out as "very appropriate for the guild-leader fantasy", and turns morale into a stat you can only watch. The bench is where the game is.

| Reputation rank | Roster cap | Forced bench per run | Rationale |
|---|---|---|---|
| Unknown | 15 | 3 | Three real cut decisions from day one |
| Known | 16 | 4 | |
| Respected | 17 | 5 | |
| Established | 18 | 6 | Gives Established a mechanical reason to exist |
| Renowned | 19 | 7 | Room to hold a Legendary plus a rotation |
| Legendary | 20 | 8 | Enough for a B-team on adventures |

**One cap, one driver — DECIDED ([15 BL-42](15-open-questions.md#bl-42), 2026-09-15; `GameState.ROSTER_CAP_BY_RANK`).** This table is the single source of the roster cap, and the driver is **reputation rank**, not Guildhall level. [02 — Town & Buildings](02-town-and-buildings.md) §4.3's facility-upgrade track must not restate a roster cap (its 14/18/22/26 column is superseded by this table and its Q8 default should cite this section); the Guildhall track keeps comfort floor and comfort slots as its reasons to exist. UI showing the cap — [13 — UI/UX](13-ui-ux.md) §9.1 and §9.4 — reads it from here, so a Respected guild reads "17 of 17" in every screen, not "17/20".

**Why 15, not 24:** every rostered raider is a morale subscription the player has to service. At 15 the player must cut 3 people per run — enough that benching hurts — while keeping the roster screen readable on one page. At 24 the bench becomes a warehouse and individual raiders stop having names in the player's head.

🔷 PROPOSED — at cap, the Tavern still shows candidates but recruiting is blocked with an explicit "roster full — fire someone or raise your reputation" message, not a hidden button. The wording has to name the real lever, which is rank.

Raid composition, tank requirements, and whether a run may be attempted with fewer than 12 are doc 06's call — see [06 — Classes & Roles](06-classes-and-roles.md).

### 12.2 Benching

🔷 PROPOSED — benching is not a separate action. Any raider not placed in the 12 for a run is benched for that run, and `consecutive_benched` increments on run resolution. Consequences:

| Effect | Value |
|---|---|
| Morale event emitted | `benched` (magnitude: doc 05), amplified for `hates_being_benched` |
| `consecutive_benched` | +1 on run resolve; reset to 0 on any run attended |
| Gear | Stays equipped. Benched raiders are not stripped automatically |
| Payday | 🔷 PROPOSED benched raiders still cost upkeep if doc 11 adopts upkeep — that is the pressure that makes the cap matter |

### 12.3 Firing

🔷 PROPOSED:

| Rule | Value |
|---|---|
| Cost | Severance = 20% of that raider's current-tier recruit cost, minimum 25g |
| Gear | Returns to the guild bank, subject to the binding rule in §13 |
| Confirmation | Single confirm for Common–Rare; typed/held confirm for Epic and Legendary |
| Morale | Emits a `guild_member_fired` event to the whole roster; `needs_a_friend` raiders take it hardest (doc 05) |
| Cooldown | 🔷 PROPOSED none. Do not punish cleanup; the severance cost is the brake |
| Record | Row retained with `status = fired` for the guild log, excluded from the cap |

### 12.4 Raiders leaving on their own

✅ CANON: at morale 10–20 and 20–30 a raider "may leave guild"; at 0–10 a raider "may cause guild disband" (canon: raw notes, Morale). The roll itself belongs to [05 — Morale](05-morale.md). This doc owns the roster consequence:

| Consequence | Rule |
|---|---|
| Slot | Freed immediately; the departure is announced at run resolution, never mid-encounter 🔷 |
| Gear | Non-bound gear returns to the bank; bound recruit gear leaves with them (§13) 🔷 |
| Notice | 🔷 PROPOSED one-run warning: a raider who rolls departure is flagged "threatening to leave" and actually leaves at the *next* run resolution, so the player gets one chance to intervene with comfort items |
| Legendary | Cannot depart unless a BIG-dumb condition is active (§11.3) 🔷 |
| Record | `status = departed`, retained in the log |

### 12.5 Replacing a lost raider mid-tier

🔷 PROPOSED — no catch-up mechanic is needed, because canon already solves it: rarity availability rises with reputation (A6, A7) and recruit gear scales to CT (A5, A7, A8). A player who loses a healer at CT 3 while Renowned can hire an Epic who arrives in Tier 3 raid gear. A player who loses a healer at CT 3 while still Known hires an Uncommon in Tier 3 adventure gear and has a bad week — which is the correct outcome.

Two safety valves:

| Valve | Rule |
|---|---|
| Role floor | If a departure leaves the roster unable to field 2 tanks or 2 healers, the next Tavern refresh guarantees at least one candidate of the missing role bucket 🔷 |
| Bank fallback | The departed raider's returned gear is immediately equippable by the replacement if class-compatible per the canon slot matrix (canon: ideaboard §1) |

---

## 13. The gear-on-recruit interaction

**Why this exists:** ✅ CANON says Epic recruits arrive with "1-2 pieces of current raid gear" (A7) and Legendaries with "a few pieces of raid gear from your current tier" (A8). Gold therefore buys raid loot without killing the boss. That is a second faucet into the loot economy, and if it is not constrained it competes with raiding itself.

### 13.1 The risk, concretely

At Renowned with CT = 1, an Epic Warrior can arrive with `Raider's Boots` (4 AC / +4 HP) and `Basic Raid Sword` (+6 Damage) — both canon Boss 1 drops. If that gear is transferable, the player can:

1. Hire the Epic, strip both pieces onto an existing Warrior, fire the Epic for 20% back. Net: two Boss 1 drops for roughly 80% of one Epic's price, no raid attempt.
2. Repeat every board refresh, converting gold directly into gear and skipping Encounter 1 forever.
3. If the gear is sellable, run the loop in reverse for gold laundering, depending on doc 11's buy/sell spread.

The Boss-5 lockout in §6.1 already protects the tier capstones. The exposure is Boss 1–4 slots.

### 13.2 Options

| Option | Mechanic | Pro | Con |
|---|---|---|---|
| **A — Bound to raider** | Recruit gear cannot be unequipped or traded while `recruited_at_tier >= CT`; unbinds once CT exceeds it | Kills the strip-and-fire loop outright; the gear stays a property of the *person*, which fits the fiction | Player sees gear they cannot touch; needs clear UI |
| B — Bound, salvage only | As A, but salvageable at the Blacksmith for materials | Feeds crafting | Canon puts Blacksmith and salvaging behind "Maybe" / "If we do crafting" — cannot depend on it |
| C — Free and sellable | No restriction | Simplest; maximal player freedom | Recruiting becomes the optimal way to gear a tier; the loot loop stops mattering |
| D — Bound and worthless on exit | As A, and the gear is destroyed when the raider leaves | Fully closes the exploit | Feels punitive; deletes items the player watched arrive |

🔷 PROPOSED — **Option A**, with these specifics:

| Rule | Value |
|---|---|
| Binding | Gear granted at generation is flagged `bound_to = raider.id` |
| Unbind | Automatic when `CT > recruited_at_tier` — last tier's gear becomes freely tradable |
| On fire / depart | Still-bound pieces leave with the raider; unbound pieces return to the bank |
| Selling | Bound gear cannot be sold |
| Salvage | Deferred to [11 — Economy & Crafting](11-economy-and-crafting.md); canon leaves salvaging conditional ("Salvaging < If we do crafting") |
| UI | A lock icon on the slot, with the tooltip "Belongs to <name> until Tier <n+1>" |

Consequence worth stating out loud: under Option A, buying an Epic buys you a *geared person*, never *gear*. That keeps the Tavern a roster faucet and leaves the raid the only gear faucet, which is what makes the loot tables in the ideaboard the spine of the game.

---

## 14. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| Q1 | What changes at reputation rank **Established**? Canon walks through Unknown, Known, Respected and Renowned but skips Established entirely, and gives Legendary rank no recruitment behaviour either. | Two of six ranks have no defined Tavern effect. Doc 03 cannot finish its table and the player hits a rank-up that does nothing. | Established: Rare becomes common and Epic gains a small chance. Legendary rank: Legendary find chance roughly doubles. Board sizes are not rank-driven at all — see doc 02 §5.2. |
| Q2 | Morale bands share their edge values (0-10, 10-20, 20-30 …) and 70-80 and 80-90 are both labelled "Very Happy". Which band owns morale exactly 20? | `morale_band` is a derived field read by every mistake-chance calculation. Ambiguity here is a real bug, not a cosmetic one. | Lower bound inclusive, upper exclusive (20 → Unhappy), and treat 70-90 as one displayed state with two internal steps. Canon labels preserved verbatim. |
| Q3 | Do Common recruits arrive with a **weapon**? Canon's per-class starting armor list has four armor slots and no weapon, and the weapon list is titled "Weapons (Tier 1 Adventure)". | A Warrior with no main hand contributes almost no damage. This decides whether Commons are usable at all or are pure comedy. | Commons arrive unarmed; the Market sells a cheap starter weapon per class. If that plays badly, grant a 0-stat "Rusty" weapon instead. |
| Q4 | Is `raid_experience` a **number that does anything**, or flavour? Canon uses it descriptively ("0 raid experience", "a small amount of experience"). | If it feeds mistake chance we have two systems doing one job; if it is flavour we should say so and stop tuning it. | Flavour and display only. Rarity is the single source of competence. |
| Q5 | Does "1-2 pieces of basic adventure gear from your current raid tier" mean **Adventure tier N** gear while the current raid is **Raid tier N**? The Adventure's Board interleaves Adventure 1, Raid 1, Adventure 2, Raid 2 … | The generator needs a concrete tier index for `adventure_set(class, T)`. Off-by-one here makes every Uncommon either overgeared or undergeared. | Adventure tier index == raid tier index; `CT` drives both. |
| Q6 | "Legendary" names both a reputation rank and a raider rarity. Rename one? | Every UI string, save key and log line is ambiguous, and "you reached Legendary and found a Legendary" is genuinely confusing. | Keep both in code (`rank_legendary`, `rarity_legendary`) but show the rank as "Legendary Guild" in UI. Needs a call. |
| Q7 | Should a recruit's **generated gear affect their recruit cost**? An Epic who rolls two raid pieces is strictly better than one who rolls one. | Without it, the player rerolls the board hunting the two-piece Epic. With it, the price tag spoils the roll. | Yes: +15% cost per raid-tier piece beyond the first. Visible on the card as "well-equipped". |
| Q8 | Is there **upkeep** (per-run or per-payday wages)? | It is the only thing that makes an 18-person roster a cost rather than free insurance, and §12.2 assumes it. | Yes, small per-run upkeep scaling with rarity. Owned by doc 11. |
| Q9 | Healer **off-hand** at recruit time: the canon adventure healer set lists four armor pieces and no off-hand, while the raid table gives "Blessed Raider's Tome" from Boss 2. What fills a healer's off-hand on an Epic/Legendary recruit whose raid roll did not include it? | Leaves a canon slot in the seven-slot model with no adventure-tier item to fill it. | Leave `off_hand` empty at adventure tier; healer off-hands exist only as raid drops. |
| Q10 | Is losing a Legendary **permanent** for that class? | It is the harshest consequence in the game and it lands on hand-authored content. | Yes, permanent, with hard confirmation and a standing warning (§11.4). |
| Q11 | Ship **wishlists** (canon: "We could…", "This is all just concepts")? | Wishlists are the best hook for making loot distribution a social decision, but they add a whole morale surface. | Build behind a flag, off for the first playtest, on for the second, then decide with data. |
| Q12 | Do raiders have **levels**? Canon: "Train raiders < Maybe if we have level ups". | Blocks the `level`/`xp` fields, the Guildhall training facility, and whether Commons can be salvaged into usefulness. | No levels for v1. Reserve the fields; rarity plus gear carries progression. Owned by doc 03. |

---

## Related documents

- [03 — Guild Reputation](03-guild-reputation.md) — owns the rank→rarity probability table this doc's generator takes as input, and the Q1/Q12 rulings.
- [05 — Morale](05-morale.md) — consumes every backstory trigger tag in §8.3 and owns the departure and disband rolls behind §12.4.
- [06 — Classes & Roles](06-classes-and-roles.md) — owns the class kits behind the nine canon classes, the Legendary `quirk` field, and the 12 raid slots and role requirements that make the roster cap in §12.1 bite.
- [11 — Economy & Crafting](11-economy-and-crafting.md) — owns gold values, the buy/sell spread, and the salvage ruling that §13 depends on.
- [02 — Town & Buildings](02-town-and-buildings.md) — owns Tavern level and therefore the candidate-slot count §3.1 consumes; its §4.3 Guildhall track owns comfort floor and slots, not the roster cap (§12.1).
- [08 — Stats & Formulas](08-stats-and-formulas.md) — owns mistake chance per rarity (§8.8): base, floor, ceiling and the morale multipliers this doc's recruits are generated against.
- [14 — Technical Architecture](14-technical-architecture.md) — implements the §4 data model, the §5 generation pipeline order, and the JSON Legendary definition files in §11.2 (§5.1 sets the format).
- [_source/lead-designer-notes-raw.md](_source/lead-designer-notes-raw.md) — canon for ranks, rarities, morale bands, classes, and Common starting armor.
- [_source/ideaboard-transcription.md](_source/ideaboard-transcription.md) — canon for the seven-slot equipment matrix and the Tier 1 adventure/raid gear the generator draws from.
