# 02 — The Town & Its Buildings

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs the town hub — which buildings exist, what each one sells or does, what unlocks and upgrades it, what its screen looks like, and how the town visibly changes as the guild's reputation grows.

## 1. Scope

**This doc owns**

- The town as a place: its navigation model, its scene composition, its visible states.
- Every building: purpose, service list, unlock condition, upgrade effects, screen spec.
- The unlock/cost table for buildings and building levels.
- The "maybe" decisions that determine whether Blacksmith, crafting, salvage, and raider training exist at all.
- The mapping from reputation rank → visible town change (the art requirement).

**This doc does NOT own**

| Topic | Owner |
|---|---|
| The reputation ladder itself — ranks, how reputation is earned, recruit rarity per rank | [03 — Guild Reputation](03-guild-reputation.md) |
| Morale math: bands, `baseline`, `facility_bonus`, drift, per-rarity mistake bands | [05 — Morale](05-morale.md) |
| Roster data, backstory tags, wishlists, recruit generation | [04 — Recruitment & The Raider Roster](04-recruitment-and-roster.md) |
| Encounter content, boss design, loot tables, raid size | [10 — Content Structure: Adventures, Raids & Encounters](10-content-and-encounters.md) |
| Item stats, slots, itemization sharing | [09 — Items & Itemization](09-items-and-itemization.md) |
| Prices, payouts, currency scale, sink/faucet balance | [11 — Economy & Crafting](11-economy-and-crafting.md) |
| How town art is authored, layered, lit, and animated | [12 — Art Direction (2D-HD)](12-art-direction.md) |
| Screen chrome, widget library, input, controller support | [13 — UI/UX](13-ui-ux.md) |
| Godot scene structure, save data, resource loading | [14 — Technical Architecture](14-technical-architecture.md) |

Sibling filenames above are the canonical set in [00 §1.1](00-vision-and-pillars.md).

## 2. The premise, stated sharply

✅ CANON — "Core concept: the town will be improved by the raids you do. Mostly by gaining reputation levels. Which will unlock additional things in the town." and "Instead of the guild simply being a menu between raids, make the town itself your progression engine." (canon: raw notes, *Town as progression engine*)

That sentence is a constraint on the build, not a mood. It produces three hard rules.

### 2.1 🔷 PROPOSED — Rule of Visible Change

**Why this exists:** if progress only ever appears as a new row in a menu, the town is a menu, and the core concept has failed silently.

> **No purchase, unlock, or reputation rank may resolve into UI only. Every one must produce at least one persistent, visible delta in the town scene.**

Acceptance criteria a programmer or artist can check:

| # | Criterion | Fail example |
|---|---|---|
| R1 | Every building level owns ≥1 exterior sprite/prop swap visible from the town view | Blacksmith L2 adds a menu row, exterior unchanged |
| R2 | Every reputation rank adds ≥3 scene deltas (see §9) | Renowned adds only a recruit-rarity change |
| R3 | Deltas persist across sessions — they are town state, not a one-shot VFX | Banner appears in the unlock cutscene, gone next load |
| R4 | On any unlock, the camera pushes to the changed thing for 1.5s before returning control | Player never learns what changed |
| R5 | The player can always tell rank from a single screenshot of the town, with no HUD | Unknown and Respected look identical |

### 2.2 🔷 PROPOSED — The town is the progression bar

There is no XP bar for the guild. Reputation has a numeric value (doc 03 owns it) but the town is its **primary readout**: repaired roofs, lit windows, crowd density, banners. The HUD shows the rank *name* only.

### 2.3 🔷 PROPOSED — One town, five buildings, no sprawl

Scope discipline: five canon buildings, no sixth without cutting one. Depth comes from building **levels** and from the town's visual state, not from new façades.

## 3. Town-level structure

### 3.1 Buildings at a glance

| Building | Canon status | Primary verb | Owns which loop step |
|---|---|---|---|
| Guildhall | ✅ CANON | Maintain | "You improve the guild/raid team." |
| Tavern | ✅ CANON | Recruit | "You recruit people at the tavern as needed." |
| Market | ✅ CANON | Buy / Sell | "You spend money at the blacksmith/Merchant." |
| Blacksmith | ❓ OPEN — canon heading reads "Blacksmith (Maybe)" | Improve gear | (conditional) |
| Adventure's Board | ✅ CANON | Depart | "You take missions from the adventure board." |

✅ CANON — the core loop is listed verbatim as: earn money → spend money at the blacksmith/Merchant → recruit at the tavern → take missions from the adventure board → improve the guild/raid team. (canon: raw notes, *Core things to do*)

❓ OPEN — canon names the shop **"Market"** as a heading but calls the vendor **"Merchant"** in the core-loop list, and spells the board **"Adventure's Board"** (not "Adventurer's Board"). This doc uses the heading spellings verbatim. Naming pass pending. See §12 Q7.

### 3.2 🔷 PROPOSED — Town state data model

Flat, savable, and enough to drive both the sim and the art. Doc 14 owns serialization format.

| Field | Type | Notes |
|---|---|---|
| `rank` | enum | Unknown, Known, Respected, Established, Renowned, Legendary (✅ CANON list) |
| `rep_points` | int | Doc 03 owns earn rates |
| `buildings[id].unlocked` | bool | Gated by `rank` and gold |
| `buildings[id].level` | int 1–4 | 0 = not built |
| `buildings[id].services[]` | enum set | Derived from level; drives menu rows |
| `scene_flags[]` | string set | Each visual delta from §9; art layer visibility keys |
| `npc_pool` | int | Ambient townsfolk count (§9) |
| `time_of_day` | enum | Dawn / Day / Dusk / Night — see §9.3 |

**Derivation rule (🔷 PROPOSED):** services are never stored directly on a save; they are recomputed from `level` at load. This keeps a design retune from invalidating saves.

## 4. Guildhall

**Purpose:** the guild's own house — where the roster lives, where morale is maintained, and where the guild's record is displayed. ✅ CANON (canon: raw notes, *Guildhall*)

### 4.1 Services

| Service | Status | Notes |
|---|---|---|
| Train raiders | ❓ OPEN — canon: "Train raiders < Maybe if we have level ups" | Existence depends on level-ups existing at all. See §8 |
| Manage morale with comfort items | ✅ CANON | Comfort items are placed here, per raider |
| Upgrade guild facilities → better morale values | ✅ CANON | The building's upgrade track *is* a morale system |
| Quest/achievement board | ✅ CANON | Distinct from the Adventure's Board — records, not missions |
| Roster view (name / class / morale / state) | 🔷 PROPOSED | Canon shows a roster mock-up ("Natsuna — 87 ❤️ / Shaman — Very Happy") but does not say where it lives. Guildhall is the natural home |
| Raid group assembly (pick who goes) | 🔷 PROPOSED | Canon implies preparing a raid and choosing to bench Steve; assembly belongs next to the roster, not on the mission board |

### 4.2 🔷 PROPOSED — Comfort items

**Why this exists:** morale needs a *spend*, or money has nothing to buy once gear is capped, and the "keep them happy" fantasy has no verb.

- A comfort item is a **durable, placed** object assigned to one raider's quarters. Not consumed.
- Each raider has N comfort slots, N set by Guildhall level (§4.3).
- Items are bought at the Market (§6) and placed at the Guildhall.

| Item (🔷 PROPOSED names) | Effect | Notes |
|---|---|---|
| Straw Cot | +3 comfort floor | Starter, cheap |
| Feather Bed | +6 comfort floor | Replaces Straw Cot in same slot |
| Hot Meal Standing Order | +5 comfort floor | Guild-wide variant costs 4× |
| Trophy Shelf | +4 comfort floor | +2 extra if the raider was present for the kill it commemorates |
| Personal Effect (backstory-matched) | +8 comfort floor | Only valid for raiders whose backstory tags match — doc 04 owns tags |

**Comfort floor** = this doc's contribution to the `baseline` a raider's morale drifts toward. [05 — Morale](05-morale.md) §7.5 owns the baseline formula, the drift rule, and every other morale rule; this doc only owns where the Guildhall + comfort-item part of that sum comes from.

Doc 05 §7.5, restated for reference, not redefined here: `baseline = 50 + rarity_offset + facility_bonus + backstory_offset`, and each Day Tick morale moves toward baseline by `drift_step = 1.5 × drift_rate[rarity]` — **1.125 to 2.25 per Day Tick**, not a per-mission jump. Comfort items add into the same sum:

`baseline(raider) = 50 + rarity_offset + facility_bonus (§4.3) + Σ(comfort item floor bonuses) + backstory_offset`, clamped to **≤ 80** — doc 05 §7.6's baseline ceiling.

✅ **RULED** (was §12 Q13; see [15 BL-38](./15-open-questions.md)) — both readings stand, as **two product lines**, which is [11 §8.1](./11-economy-and-crafting.md)'s proposal. The items in §4.2 above are **Furnishings**: durable, placed, and a standing baseline shift exactly as this section assumes. Doc 05 §7.4's +8 on a 2-tick cooldown is a separate consumable line, **Indulgences**, priced in [11 §8.3](./11-economy-and-crafting.md). A Furnishing never moves morale on the spot and an Indulgence never moves the baseline; both halves are asserted by test. The ≤ 80 clamp this section asks for is now real rather than emergent (`Morale.BASELINE_CEILING`).

**Worked example.** Guildhall L2 (`facility_bonus` +3, §4.3). Steve the Mage sits at 14 ✅ CANON example value; doc 05 §11.2 reads him as a Common, so his `rarity_offset` is −5 and his `drift_step` is 1.125 per Day Tick. Baseline before comfort items = 50 − 5 + 3 = **48**. A Feather Bed (+6) and a backstory-matched Personal Effect (+8) raise it to **62**. Drift alone then lifts him 1.125 per Day Tick: ≈ 17.4 after 3 ticks, and ~30 ticks to reach 48. Reading: comfort items move *where a raider settles*, they do not rescue him — the fast path is doc 05 §7's event deltas, which walk this exact Steve from 14 to Content in five ticks (doc 05 §11.2). The player still has to decide whether to bench him meanwhile.

### 4.3 🔷 PROPOSED — Facility upgrade track

✅ CANON says upgrading guild facilities yields "better morale values". Proposed concrete track. The morale column is **not** a floor value invented here — it is doc 05 §7.5's `facility_bonus`, and this doc owns only the level names and the slot counts (the roster cap is [04 §12.1](04-recruitment-and-roster.md)'s, by rank — [15 BL-42](15-open-questions.md#bl-42)):

| Level | Name | `facility_bonus` (doc 05 §7.5) | Comfort slots / raider | Visible change (§9 obligation) |
|---|---|---|---|---|
| 1 | Leaking Guildhall | +0 | 1 | Boarded windows, sagging roof, one lantern |
| 2 | Repaired Guildhall | +3 | 2 | Roof patched, door replaced, 3 lit windows |
| 3 | Proper Guildhall | +6 | 3 | Second storey, guild banner, brazier at door |
| 4 | Renowned Guildhall | +10 | 4 | Stone façade, stained glass, two standing guards |

Doc 05 §7.5 numbers its facility tiers 0–3; **Guildhall L1–L4 here map to facility tiers 0–3 in that order**, which is why the derelict starting hall contributes +0. If doc 05 retunes the bonuses, this column follows it, not the reverse.

**Roster cap — DECIDED ([15 BL-42](15-open-questions.md#bl-42), 2026-09-15): one driver, reputation rank.** `GameState.ROSTER_CAP_BY_RANK` is 15 / 16 / 17 / 18 / 19 / 20 from Unknown to Legendary ([04 §12.1](04-recruitment-and-roster.md)); the 14 / 18 / 22 / 26 column this table used to carry is struck, and "min of both" was rejected as a second truth for one number. The cap sits above the ✅ CANON raid size of 12 at every rank so the player can always bench someone — which the canon Steve-at-14 scenario requires — and stays small enough that "maybe I shouldn't bring Steve" hurts. The Guildhall track keeps the comfort floor and the comfort slots.

### 4.4 🔷 PROPOSED — Quest/achievement board (inside the Guildhall)

✅ CANON lists it; nothing more. Proposed shape:

| Element | Spec |
|---|---|
| Achievements | Static list, ~40 at ship. Each: name, condition, reward |
| Reward types | Reputation points (doc 03 sets rates), a comfort item, or a town scene flag (banner/statue) |
| Examples (🔷 PROPOSED) | "First Blood" clear Adventure 0 · "No One Died" clear Raid 1 with 12/12 alive · "Big Dumb" lose a Legendary raider to morale |
| Explicit non-goal | No daily/weekly timers. This is a record wall, not a chore list |

Achievements are the *only* non-mission reputation faucet proposed here; doc 03 decides whether to accept that.

### 4.5 Screen — Guildhall

| Panel | Contents | Notes |
|---|---|---|
| Left rail | Roster list: portrait, name, class, morale number + emoji, state label | ✅ CANON display format from the roster mock-up |
| Centre | Selected raider: gear paper-doll (read-only here), backstory bullets, wishlist | Doc 06 owns equip UI; Guildhall shows, doesn't equip |
| Right | Quarters view: comfort slots as drop targets, baseline computed live | Shows `50 + rarity_offset + facility_bonus + items = baseline` as an arithmetic strip, per doc 05 §7.5 |
| Tabs | Roster · Raid Group · Facilities · Records | "Training" tab appears only if §8 resolves yes |
| Facilities tab | Current level card, next level card, cost, delta table, exterior before/after thumbnails | Before/after thumbnails satisfy R1 by making the visual change part of the purchase pitch |
| Exit | Returns to town scene with camera on the Guildhall | |

## 5. Tavern

**Purpose:** ✅ CANON — "Recruits are found and managed here" and "This is all managed at the - Tavern" (the reputation → recruit-rarity system). (canon: raw notes, *Tavern*; *Guild Reputation*)

### 5.1 Services

| Service | Status | Notes |
|---|---|---|
| Find recruits (rarity by reputation rank) | ✅ CANON | Doc 03 owns the rank → rarity table |
| Manage recruits | ✅ CANON — the word "managed" is canon; its meaning is not | ❓ OPEN. Proposed: dismiss, rename, review backstory, review wishlist |
| Legendary recruits — 1 per class, named characters | ✅ CANON | "You can only ever find 1 Legendary per class - They are also named characters - IE Natsuna(the shaman)" |
| Refresh the recruit list | 🔷 PROPOSED | See §5.2 |
| Buy a round (small guild-wide morale bump) | 🔷 PROPOSED | Gives the Tavern a gold sink and a reason to visit when not hiring |

### 5.2 🔷 PROPOSED — Recruit board refresh

**Why this exists:** without a refresh rule, the player either sees an infinite list (no scarcity) or a frozen one (softlock when no healer appears).

| Rule | Value |
|---|---|
| Slots shown | 4 at Tavern L1, 5 at L2, 6 at L3, 7 at L4 |
| Free refresh | On completing any adventure or raid |
| Paid refresh | Costs 1 refresh fee (doc 11 sets it); price doubles each paid refresh within the same mission cycle, resets on mission completion |
| Anti-softlock | If the roster has no living member of a role the current tier requires, one slot is forced to that role |
| Legendary appearance | Rolled per §canon "near 1% chance" wording — doc 03 owns the exact roll; the Tavern presents it as a distinct rare-card treatment |

❓ OPEN — canon's "near 1% chance of mistake" describes the *raider's* mistake rate, and "you also gain a VERY SMALL chance to find raiders that are basically perfect" describes the *find* chance without a number. Do not conflate them. See §12 Q1.

### 5.3 Screen — Tavern

| Panel | Contents |
|---|---|
| Scene backdrop | Interior, animated crowd; crowd count and lighting scale with reputation rank (§9) |
| Recruit cards | One per slot: portrait, name, class, rarity frame, morale start value, gear they arrive with, 2–3 backstory bullets |
| Rarity frames | Common / Uncommon / Rare / Epic / Legendary — colour + frame ornament, doc 13 owns the exact treatment |
| Legendary card | Full-height card, unique portrait, name spoken in a barked line, "1 of 1" stamp |
| Cost strip | Hire cost, upkeep if any (doc 11), roster space remaining |
| Manage tab | Current roster with dismiss action + confirmation that names the morale consequence |

✅ CANON — recruits arrive already geared at higher ranks ("1-2 pieces of basic adventure gear from your current raid tier"). The card must therefore show arriving gear, because it is part of the hire's value.

## 6. Market

**Purpose:** ✅ CANON — buy consumables (potions), sell loot, and *maybe* crafting supplies. (canon: raw notes, *Market*)

### 6.1 Services

| Service | Status | Notes |
|---|---|---|
| Buy consumables (Potions) | ✅ CANON | Doc 11 owns prices; doc 10 owns in-raid effects |
| Sell loot | ✅ CANON | Primary gold faucet outside mission payouts |
| Crafting supplies | ❓ OPEN — canon: "Crafting Supplies < Maybe" | Exists only if crafting exists (§8) |
| Comfort items | 🔷 PROPOSED | §4.2 items need a vendor; Market is the only canon shop that is not itself a "maybe" |
| Buy-back of the last N sold items | 🔷 PROPOSED | N = 6. Cheap insurance against a mis-sale; costs 1.25× sale price |

### 6.2 🔷 PROPOSED — Stock model

**Why this exists:** a shop with static infinite stock is a menu; a shop whose shelves change is a place.

| Level | Consumable tiers stocked | Comfort items stocked | Stock rows | Visible change |
|---|---|---|---|---|
| 1 | Tier 1 potions | Straw Cot | 5 | One trestle table, one vendor, canvas awning |
| 2 | Tier 1–2 | + Hot Meal Standing Order | 7 | Second stall, crates, 2 shoppers |
| 3 | Tier 1–3 | + Feather Bed, Trophy Shelf | 9 | Permanent stone stall, hanging goods, 4 shoppers |
| 4 | All tiers | + Personal Effects (backstory-matched) | 12 | Covered market row, banners, 6 shoppers, night lanterns |

Sell prices are a flat fraction of item value — doc 11 sets the fraction and every price in this table.

### 6.3 Screen — Market

| Panel | Contents |
|---|---|
| Tabs | Buy · Sell · Comfort · Supplies (Supplies tab hidden unless crafting ships) |
| Buy list | Item, effect line, price, owned count, stock remaining |
| Sell list | Guild inventory with a "worn by" column so the player cannot sell equipped gear without a confirm |
| Sell-all helper | "Sell all unusable by current roster" — computes from the class/slot matrix in doc 06 |
| Footer | Gold before → after preview on hover |

The sell-all helper is the single highest-value convenience in the game: the canon loot tables drop class-restricted gear at five encounters per raid, so junk volume is high.

## 7. Blacksmith — post-1.0 (RULED, [15 Q-13](15-open-questions.md#q-13))

**Status (2026-09-15):** out of 1.0. No building, no upgrades, no crafting, no salvage; the facade stays on the town plate behind the in-world line "Closed. The smith took a better offer." (`Town.gd`, final), the `blacksmith` flag stays declared off, and `Buildings.gd`'s ladder and `reputation.json`'s two flagged unlock rows stay as post-1.0 data the Town never prints. §7-§8 below are the 1.1 spec and say so; nothing here changes for 1.0.

**Purpose:** ❓ OPEN — the canon heading is literally "Blacksmith (Maybe)", and each of its three services carries its own conditional. (canon: raw notes, *Blacksmith (Maybe)*)

Canon, verbatim, preserved:

| Service | Canon conditional |
|---|---|
| Equipment upgrades | "< Maybe" |
| Salvaging | "< If we do crafting" |
| Weapons and armor crafting | "< If we do crafting" |

Note the tension the decision table in §8 must resolve: the ✅ CANON core loop already says "You spend money at the blacksmith/Merchant" — the loop assumes a blacksmith the building spec calls a maybe.

### 7.1 🔷 PROPOSED — If the Blacksmith ships, this is the smallest version

**Why this exists:** the cheapest Blacksmith that still earns its façade is a **sharpening bench**, not a crafting tree.

| Feature | Spec |
|---|---|
| Upgrade | Any equipped item can be upgraded +1 to +3. Each rank: +1 AC on armor, +1 Damage on weapons |
| Cost curve | +1 = 1 unit, +2 = 3 units, +3 = 6 units (doc 11 sets the unit) |
| Cap rule | Upgrade cap = Blacksmith level. L1 allows +1 only |
| Anti-obsolescence rule | Upgrades do **not** transfer between items, so upgrading Adventure gear is a deliberate stopgap, not a trap |
| Explicit non-goal | No random enchants, no reforging, no sockets |

Worked example: a Warrior in full Tier 1 Adventure armor (✅ CANON total **15 AC**) with a fully +3 Blacksmith at L3 reaches 15 + 4 pieces × 3 = **27 AC**, versus **21 AC** from the four Tier 1 Raid armor pieces (5+7+5+4 ✅ CANON). That is the balance risk the decision table must weigh: an upgrade bench can out-value the raid it is supposed to bridge. Proposed mitigation — upgrade cap 2 on Adventure-tier items, 3 on Raid-tier.

### 7.2 Screen — Blacksmith (if it ships)

| Panel | Contents |
|---|---|
| Left | Roster picker → selected raider's equipped items |
| Centre | Item card, current stats, next-rank stats in green, cost, materials if crafting ships |
| Right | Salvage bin (only if crafting ships): drag junk in, see material yield |
| Footer | "Sharpen all +1" bulk action with total cost |

## 8. The "maybe" decision table

**Ruled 2026-09-15 ([15 Q-13](15-open-questions.md#q-13), [Q-14](15-open-questions.md#q-14)):** M1-M5 are out of 1.0 with the Blacksmith (§7); M6 is no level-ups and no Drilling — canon's "Maybe if we have level ups" is a conditional whose condition is false, so §8.1 is post-1.0. The table is kept as the 1.1 costing.

This is the section the team should read first. Costs are in **engineering weeks (EW)** and **art units (AU = one building's worth of sprite work at 2D-HD fidelity)**, sized for a small team. Recommendations are opinionated by request.

| # | Feature | Canon wording | Cost to build | What the game loses without it | What it adds | Recommendation |
|---|---|---|---|---|---|---|
| M1 | **Blacksmith building** | "Blacksmith (Maybe)" | 1.5 EW + 1.0 AU (exterior + interior + 4 upgrade states) | One of five façades, so the town skyline stops changing between Known and Renowned; the ✅ CANON loop line "spend money at the blacksmith/Merchant" loses half its meaning | A second gold sink that is not consumables; a visible smithy fire as a night-time landmark | 🔷 **BUILD IT.** The town-as-progression pillar needs building count, and the canon loop already names it. Ship it at §7.1 scope only |
| M2 | **Equipment upgrades** | "Equipment upgrades < Maybe" | 1.0 EW (inside M1) | Gold has nothing to do between raid tiers once potions are stocked; bad luck on drops has no remedy | Player agency over a bad drop week; a use for the pile of duplicate gear | 🔷 **BUILD IT**, with the Adventure-tier cap of +2 from §7.1. Cheapest system in this table per unit of player agency |
| M3 | **Crafting (weapons/armor)** | "< If we do crafting" | 4.0 EW + 0.5 AU + ~90 recipe/data rows | Nothing the pillar needs. The canon loot tables are already the gear engine — 5 encounters × 9 classes | A parallel gear path that competes with raiding, plus a materials economy, plus a UI | 🔷 **CUT for v1.** It duplicates the loot tables, and the tables are the most finished part of canon. Revisit post-launch |
| M4 | **Salvaging** | "< If we do crafting" | 1.0 EW *if* M3 ships; 0.5 EW as a standalone gold-only variant | Junk gear has exactly one destination (sell), which is fine | Materials sink for junk; feels good next to class-restricted drops | 🔷 **CUT the crafting version; SHIP the degenerate version** — "Salvage" that yields gold + upgrade units, no materials, no recipes. Keeps the fantasy at 0.5 EW |
| M5 | **Crafting supplies at Market** | "Crafting Supplies < Maybe" | 0.5 EW, entirely dependent on M3 | Nothing | A Market tab | 🔷 **CUT with M3.** Hide the tab behind the same flag |
| M6 | **Raider training / level-ups** | "Train raiders < Maybe if we have level ups" | 3.0 EW + roster UI churn; touches morale, mistake rates, and recruit value | A recruit is only as good as the day you hired them; Common raiders stay dead weight forever and are pure fodder | Attachment to specific raiders; a use for a bad roster; a second progression axis | 🔷 **CUT level-ups; SHIP a narrow substitute** — see §8.1. Full level-ups collide with the reputation ladder (§8.2) |

### 8.1 🔷 PROPOSED, post-1.0 — The narrow substitute for training

Not in 1.0 ([15 Q-14](15-open-questions.md#q-14)): the "ship Drilling" line was not taken because canon's own training line is conditional on level-ups, which do not exist. `Raider.level` / `xp` stay serialised and unread so a later yes is not a migration; the "Lv." label is retired.

**Why this exists:** the *appeal* of training is "my guys get better", but the *cost* of training is a second progression system that fights the first. Buy the appeal, skip the system.

| Mechanic | Spec |
|---|---|
| Name (placeholder) | Drilling |
| Where | Guildhall, Training tab (post-1.0; would unlock at Guildhall L3 — the L3 note in §11 is struck) |
| What it changes | **Mistake chance only.** One raider may be drilled to reduce mistake chance by up to 2 percentage points, in 0.5-point steps |
| Hard cap | A drilled raider can never reach the mistake floor of the rarity above them. [08 §8.8](08-stats-and-formulas.md) owns the per-rarity floors ("All values above are have within tier limits for mistakes based on their tier" ✅ CANON) |
| Cost | Gold + one mission slot per step: the raider sits out one mission to drill |
| No level, no XP, no stat growth | Gear remains the only stat source, preserving the canon loot tables as the power curve |

Worked example, against [08 §8.8](08-stats-and-formulas.md)'s table (the one published set — [15 Q-04](15-open-questions.md#q-04)): Bob the Warrior, Uncommon, base **15.0%** at Content morale. Drilled the full 4 steps → **13.0%**. Rare's floor is **5%** and its Content base is **8%**, so even a fully drilled Uncommon lands 5 points clear of where a Rare *starts*. Drilling can never make Bob a Rare. The player who wants 8% still has to reach Respected and hire one.

### 8.2 ❗ The tension worth naming: training vs the reputation ladder

✅ CANON makes reputation the recruit-quality gate — at Unknown "you can only find the worst players", at Respected "you no longer find common", at Renowned "you no longer find uncommon". (canon: raw notes, *Guild Reputation*)

**If a Common raider can be trained up to Rare, reputation stops being a gate and becomes a shortcut.** The entire canon ladder — and therefore the town's progression pillar, since reputation is what changes the town — loses its teeth. The three coherent positions:

| Position | Consequence | Verdict |
|---|---|---|
| A. Full level-ups, uncapped | Reputation ranks become cosmetic; the Tavern degrades to a bulk-hire button; the pillar breaks | 🔷 Reject |
| B. No training at all | Canon "Train raiders" line dies; Commons are pure fodder; roster attachment is thin | 🔷 Acceptable fallback |
| C. Drilling, hard-capped below the next rarity band (§8.1) | Raiders improve; the ladder still gates the ceiling; cost is 0.75 EW not 3.0 | 🔷 **Recommended** |

Doc 03 must sign off on C, because C spends part of its subject matter.

## 9. 🔷 PROPOSED — Town visual progression

**Why this exists:** §2.2 claims the town is the progression bar. That claim is only true if an artist is given a per-rank checklist. This is that checklist. Doc 12 owns *how* these are drawn (layer counts, palettes, lighting rig, sprite budgets).

### 9.1 Rank → scene deltas — one plate, six dressings

Ranks are ✅ CANON (Unknown, Known, Respected, Established, Renowned, Legendary — canon: raw notes, *Guild Reputation*). **DECIDED ([15 BL-102](15-open-questions.md#bl-102), 2026-09-15): the town is ONE painted plate and six rank dressings**, every layer gated `rank >= N` in `stage_camp.json`, its props cut from the plate's or the sheets' own pixels, never painted new. Every rank adds at least three deltas (§2.1 R2) and a rank is readable from a screenshot (R5). Ranks 0-3 land in W8-FACILITY, ranks 4-5 in W9-ART.

| Rank | Walkers | Lantern flames | Props and dressing | Audio (what ships — [15 Q-98](15-open-questions.md#q-98)) |
|---|---|---|---|---|
| 0 Unknown | 0 | 6 | The two shipped banner props hidden | The camp bed (`amb_camp`); the sparse lute, rubato ([`Audio.MUSIC_BED`](15-open-questions.md#q-98), W10-BUFFER's first item) |
| 1 Known | 1 | 8 | The banners return; one cloth pennant on a pole beside the Board callout (never on the tent — the tent's cloth banner is facility L2's) | The lute gains a frame drum at 66 BPM and quantises to the eighth grid |
| 2 Respected | 2 (the shipped scene) | 10 | A notice post beside the Board callout; the pennant takes the crest colour | As Known |
| 3 Established | 3 | 10 | A cobble band on the main path (`patch_plate.py`); a pennant line of 5 between the two big tents | As Known |
| 4 Renowned | 4 | 10 + 2 brazier flames (`fire_camp` at 1x) | A stone statue (one idle warrior frame, desaturated, on a 24×10 plinth) in the square | As Known |
| 5 Legendary | 5 | 10 + 4 braziers | A second guild tent (a patch copy), two `knight_unlabelled` guards flanking it, crest pennants on all four tents | As Known |

The world layer is silent by ruling (Q-98 (iv): failure is the content, and hits and heals would bury the mistakes under the noise of competence); the anvil ring, market chatter, ensemble, bell toll, cheer stinger and leitmotif the painted brief below asked for are post-1.0.

**The six painted states — the post-1.0 plate brief.** Kept as the checklist for the day a person paints six plates (3 or 6 plates are the designer's, [BL-102](15-open-questions.md#bl-102)); nothing below is built.

| Rank | Buildings | NPCs / crowd | Banners & signage | Lighting / weather / time | Audio (brief) |
|---|---|---|---|---|---|
| Unknown | Guildhall boarded, Tavern only lit building, Market = 1 trestle table, no Blacksmith, Board is a cracked post | 3 idle townsfolk, all turned away from the player | No guild banner. Guildhall sign hangs crooked | Overcast, dusk, puddles, no street lamps lit | Wind, one dog, sparse lute |
| Known | Guildhall roof patched, Market gains a 2nd stall | 6 townsfolk; 1 waves at the player | Small cloth guild banner over Guildhall door | Overcast breaking, dusk, 2 lamps lit | Lute gains a drum |
| Respected | Blacksmith appears (if M1 ships), Tavern gains a second storey | 10 townsfolk, 2 children, 1 stray cat on the Market awning | Guild banner on Guildhall + Board; Board gains a notice frame | Clear, late afternoon, all street lamps lit | Anvil ring loop, market chatter |
| Established | Guildhall L3 façade available; cobbles replace mud on the main path | 14 townsfolk, a busker outside the Tavern, 1 recruit hopeful loitering | Painted signboards on all buildings; pennant line across the street | Clear, midday, warm bounce light | Full ensemble; crowd murmur bed |
| Renowned | Stone façades; Market becomes a covered row; fountain restored in the square | 20 townsfolk, 2 town guards, a merchant caravan parked | Guild crest carved above the Guildhall door; 4 hanging banners | Golden hour, god rays through the gate, doves | Bell toll on entry |
| Legendary | Statue of the guild in the square; Guildhall gains stained glass and a tower | 26 townsfolk, crowd gathers when the player crosses the square, NPCs face and salute | Crest on every building; street renamed on a plaque | Night option unlocked: braziers, lit windows, festival lanterns | Cheer stinger on entry; leitmotif |

Established is what [15 Q-22](15-open-questions.md#q-22) says it is — the Rare modal at the Tavern and the Market L4 / Guildhall L3 purchases (§11) — and Legendary is a town rank as well as a raider rarity (§12 Q2 is answered by BL-102's table).

### 9.2 Building level → exterior delta (obligation table)

Every building level must claim at least one exterior asset. This table is the art contract; §4.3 and §6.2 restate their own rows.

| Building | L1 → L2 | L2 → L3 | L3 → L4 |
|---|---|---|---|
| Guildhall | Roof patched, door replaced | Second storey + banner + brazier | Stone façade, stained glass, 2 guards |
| Tavern | Windows unboarded, sign repainted | Second storey, balcony, patrons outside | Lantern arch, live band audible from square |
| Market | 2nd stall + crates | Permanent stone stall, hanging goods | Covered row, banners, night lanterns |
| Blacksmith | Forge fire visible, smoke | Water wheel / bellows animation | Second forge, apprentice NPC, sparks at night |
| Adventure's Board | Post repaired, 2 notices | Roofed board, map pinned, 4 notices | Stone kiosk, bounty bell, quartermaster NPC |

### 9.3 Time of day

🔷 PROPOSED — time of day advances one step per completed mission (Dawn → Day → Dusk → Night → Dawn), and is **cosmetic only**: no service changes, no shop hours. It buys a large amount of "this is a place" for one lighting pass per scene, and it makes the Blacksmith's forge and the Legendary lanterns pay off. Reject if doc 12 prices the second lighting pass above 0.5 AU per building.

## 10. 🔷 PROPOSED — Navigation model

**Why this exists:** this single choice sets the cost of everything in §9, and therefore whether the progression pillar is affordable.

| Option | What it is | Sells 2D-HD? | Cost | Shows change? | Risk |
|---|---|---|---|---|---|
| A. Clickable illustrated scene | One painted, layered town scene. Buildings are hotspots; hover lifts a label; click pushes in and opens the screen. Ambient NPC sprites walk on fixed spline paths | Strongly — it is the *money shot* framing, like an Octopath town establishing view | ~1.0 AU per building + 1 scene composite; no character controller, no collision, no pathfinding | Yes — every §9 delta is a layer toggle | Can feel static if NPC/parallax/lighting budget is cut |
| B. Walkable hub | Player character walks the town, enters buildings | Hardest — 2D-HD is at its best with a controllable character in a diorama | +3–4 EW (controller, collision, camera, door transitions, save position) + NPC pathing + interior maps + player sprite set with 8-dir walk | Yes, and more intimately | Highest cost; a walk from Tavern to Board becomes a tax paid dozens of times per session |
| C. Stylized map | Icons on a parchment map | Weakest — undercuts the whole aesthetic pitch | ~0.3 AU total | Only via icon swaps, which is exactly the "menu row" failure of §2.1 | Kills the pillar |

### 10.1 Recommendation: **A, clickable illustrated scene**

The argument, in order:

1. The pillar requires that the town *look* different at every rank. Option A spends its entire budget on exactly that; option B spends most of its budget on locomotion, which is not progression.
2. This is a management game. The player will cross the town dozens of times per session; a walk cycle between two menus becomes friction the moment the novelty fades.
3. A is the only option that scales down gracefully: if a rank's art slips, it ships with fewer layers, not with a broken map.
4. A leaves the door open — B can be added later over the same scene composition (the layer stack becomes the backdrop), whereas going B → A wastes the controller work.

🔷 PROPOSED mitigations for A's staticness, all cheap:

| Mitigation | Cost |
|---|---|
| 3 parallax depths + slow cloud/light drift | Included in doc 12's layer spec |
| 6–26 ambient NPC sprites on spline walks (count from §9.1) | 1 sprite set, recoloured |
| Camera push-in on building select, push-out on exit | 0.2 EW |
| Camera pan-to-change on unlock (rule R4) | 0.2 EW |
| Idle vignettes: drunk ejected from Tavern, smith quenches a blade | 0.3 AU total, high perceived value |

### 10.2 Cost implication for other docs

| Doc | Implication |
|---|---|
| [12 — Art Direction](12-art-direction.md) | Owns: layer stack per building (base + level variants + lighting), one ambient NPC sprite set, per-rank layer manifest. Budget ≈ 5 buildings × 4 levels × 1 AU + 6 rank lighting passes |
| [13 — UI/UX](13-ui-ux.md) | Needs a hotspot + focus model that works on gamepad (D-pad cycles buildings) as well as mouse. No free cursor dependency |
| [14 — Technical Architecture](14-technical-architecture.md) | Town = one Godot scene; buildings = nodes with a `level` and a visibility manifest driven by `scene_flags[]`. No navigation mesh, no player entity, no interiors as separate maps — building screens are UI scenes over a blurred town backdrop |

## 11. Building unlock & cost table

Costs are 🔷 PROPOSED throughout and expressed in **G**, where **1 raid-tier clear payout ≈ 100 G** (a relative unit so doc 11 can rescale everything by one multiplier without touching this doc).

| Building / level | Unlocked at rank | Canon status of the gate | Gold cost | Notes |
|---|---|---|---|---|
| Guildhall L1 | Unknown (start) | 🔷 PROPOSED (canon lists the building, not the gate) | 0 | Present at game start; derelict |
| Guildhall L2 | Known | 🔷 PROPOSED | 150 G | `facility_bonus` +0 → +3 (§4.3) |
| Guildhall L3 | Established | 🔷 PROPOSED | 500 G | Opens at Established with the Market's L4 ([15 Q-22](15-open-questions.md#q-22)); Drilling is post-1.0 ([Q-14](15-open-questions.md#q-14)) |
| Guildhall L4 | Renowned | 🔷 PROPOSED | 1,400 G | |
| Tavern L1 | Unknown (start) | ✅ CANON that recruiting happens here from the start — rank Unknown already describes finding Common raiders | 0 | |
| Tavern L2 | Known | 🔷 PROPOSED | 120 G | 5 recruit slots |
| Tavern L3 | Respected | 🔷 PROPOSED | 420 G | 6 recruit slots |
| Tavern L4 | Renowned | 🔷 PROPOSED | 1,200 G | 7 recruit slots |
| Market L1 | Unknown (start) | 🔷 PROPOSED | 0 | Potions must be buyable before Adventure 0 |
| Market L2 | Known | 🔷 PROPOSED | 130 G | |
| Market L3 | Respected | 🔷 PROPOSED | 450 G | |
| Market L4 | Established | 🔷 PROPOSED | 1,100 G | Opens at Established — named in `reputation.json`'s Established `town_unlock` so the rank-up callout prints it ([15 Q-22](15-open-questions.md#q-22)) |
| Blacksmith L1 | Respected | post-1.0 ([15 Q-13](15-open-questions.md#q-13)) | 300 G | Upgrade cap +1 |
| Blacksmith L2 | Established | post-1.0 (Q-13) | 700 G | Upgrade cap +2 |
| Blacksmith L3 | Renowned | post-1.0 (Q-13) | 1,600 G | Upgrade cap +3 |
| Adventure's Board L1 | Unknown (start) | ✅ CANON — Adventure 0 and the Tutorial Raid are the first content | 0 | |
| Adventure's Board L2 | Known | 🔷 PROPOSED | 0 | Free: it upgrades by reputation, not gold |
| Adventure's Board L3 | Respected | 🔷 PROPOSED | 0 | |

✅ CANON — "New Tiers can be unlocked by gaining reputations with the town." (canon: raw notes, *Adventure's Board*) The Board's own content gating is therefore reputation-only, never gold. Which tier maps to which rank is doc 03 + doc 10's call.

### 11.1 Adventure's Board — the building

**Purpose:** ✅ CANON — mission select. Canon mission list, verbatim and in order: Adventure 0 (1 Trash mob, learning, 1 crap trinket) · Tutorial Raid (1 Boss, learning, 1 crap trinket) · Adventure 1 (a few trash encounters and a mini boss) · Raid 1 · Adventure 2 TBD · Raid 2 · Adventure 3 · Raid 3 · Adventure 4 · Raid 4 · Adventure 5 · Raid 5.

❓ OPEN — canon: "This continues or can go raid raid, adventure adventure, obviously they will need names later, but this is a placeholder". Cadence and all names are undecided; the Board UI must not hard-code the pattern. Use canon placeholders (Raid 1, Adventure 2, Boss 3) in all strings and keep them data-driven.

✅ CANON — tutorials are skippable, warn the player they forfeit an easy reward, and that reward is deliberately weak: "Like a +1 dps trinket or something".

Board screen (🔷 PROPOSED):

| Panel | Contents |
|---|---|
| Mission list | Placeholder name, type (Adventure / Raid), difficulty stars, locked-by-rank badge |
| Detail | Encounter count, drop slots per encounter (docs 09/10 own the data), recommended roster |
| Skip-tutorial dialog | Explicit text naming the forfeited reward — canon requires the warning |
| Depart | Opens raid-group confirmation; the group itself was assembled at the Guildhall (§4.1) |

Encounter content, difficulty stars, and loot are doc 10's; the Board only lists and launches.

## 12. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| 1 | What is the actual *find* chance for a Legendary recruit? Canon gives "VERY SMALL chance" and "near 1% chance of mistake" — the 1% describes mistakes, not finds | Tavern refresh economy and the whole late-game fantasy hinge on it | 1.5% per Legendary-eligible slot roll at Renowned, 3% at Legendary rank; guaranteed by pity after 40 rolls per class |
| 2 | What does **Established** do? Canon lists the rank but describes only Unknown / Known / Respected / Renowned | It is a whole rank with no defined content; the town has to change there anyway | Established = the *economy* rank: Market L4, Blacksmith L2, and "no more Common in the Tavern at all" (Respected only stops them "no longer find common" — Established makes Rare the floor) |
| 3 | Does the Blacksmith exist? (M1/M2 in §8) | Sets the town skyline, the second gold sink, and 2.5 EW + 1.0 AU | Yes, at §7.1 scope: upgrades only, no crafting |
| 4 | Does crafting exist? (M3/M4/M5) | 4+ EW and an entire parallel gear economy against already-complete loot tables | No for v1. Ship gold-only "Salvage" instead |
| 5 | Do raiders level up, and if so does training bypass the reputation gate? (§8.2) | This is the biggest single design risk in the doc — it can invalidate doc 03 | No level-ups. Ship hard-capped Drilling (§8.1) |
| 6 | Navigation model: clickable scene, walkable hub, or map? (§10) | Sets art and engineering budget for docs 12/13/14 and whether §9 is affordable | Clickable illustrated scene with parallax, ambient NPCs, and camera pushes |
| 7 | Canonical names: "Market" or "Merchant"? "Adventure's Board" or "Adventurer's Board"? | Strings, save keys, and art signage all bake these in | Building = "Market", vendor NPC = "the Merchant"; board = "Adventure's Board" (canon heading spelling) verbatim until a naming pass |
| 8 | ~~Is there a roster cap, and is it a Guildhall upgrade?~~ DECIDED ([15 BL-42](15-open-questions.md#bl-42)): a cap by reputation rank, 15 → 20, owned by [04 §12.1](04-recruitment-and-roster.md); not a Guildhall upgrade | Determines whether benching a low-morale raider (the canon Steve scenario) is even possible | Yes: 15 → 20 by rank (04 §12.1) |
| 9 | Does time of day advance? (§9.3) | One extra lighting pass per building against a large "living place" payoff | Yes, cosmetic only, one step per mission |
| 10 | Are comfort items canon-shaped as per-raider placed objects, or guild-wide purchases? Canon says only "Manage morale with comfort items" | Determines whether the Guildhall screen needs per-raider quarters UI (bigger) or a single shared list (smaller) | Per-raider, slot-limited by Guildhall level — it makes the Guildhall upgrade track matter |
| 11 | Does the achievement board grant reputation? (§4.4) | Adds a non-mission reputation faucet that doc 03 may not want | Yes, small amounts, capped at ~15% of total reputation earned |
| 12 | What does "recruits are **managed** here" include — dismissal, renaming, gear assignment? | Splits responsibility between Tavern and Guildhall screens; affects both screen specs | Tavern = acquire + dismiss; Guildhall = everything ongoing (morale, comfort, gear, group) |
| 13 | Is a comfort item a standing `baseline` shift (§4.2) or a one-off event delta with a cooldown (doc 05 §7.5–7.6)? | Decides whether the Guildhall quarters UI shows a permanent arithmetic strip or a cooldown timer, and whether comfort items count against doc 05's baseline ceiling of 80 | Standing baseline shift, as §4.2 assumes — it is what makes the Guildhall upgrade track a morale system. Doc 05 owns the ruling |

## Related documents

- [03 — Guild Reputation](03-guild-reputation.md) — owns the rank ladder and the rank → recruit-rarity table this doc gates buildings against; must sign off on §8.2.
- [05 — Morale](05-morale.md) — owns the 0-100 bands, the `baseline` formula and `facility_bonus` values (§7.5), the baseline ceiling of 80 (§7.6), and the per-rarity mistake bands (§5.3) that §4.2, §4.3 and §8.1 consume.
- [04 — Recruitment & Roster Management](04-recruitment-and-roster.md) — owns roster data, backstory tags and wishlists that §4.2's Personal Effect matches against.
- [10 — Content Structure: Adventures, Raids & Encounters](10-content-and-encounters.md) — owns the mission content the Adventure's Board lists.
- [09 — Items & Itemization](09-items-and-itemization.md) — owns the item stats the Market sells and the Blacksmith would upgrade.
- [11 — Economy & Crafting](11-economy-and-crafting.md) — owns every gold number in §11; rescale there, not here.
- [12 — Art Direction (2D-HD)](12-art-direction.md) — owns how the §9 visual progression is actually drawn and layered.
- [13 — UI/UX](13-ui-ux.md) — owns the widget library every building screen in this doc is assembled from.
- [14 — Technical Architecture](14-technical-architecture.md) — owns the Godot scene structure implied by the §10 navigation recommendation.
