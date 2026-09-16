# 11 — Economy, Shops & Crafting

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document owns every number with a price on it — the currency, what pays it in, what drains it out, the shelves of the Market, Guildhall and Blacksmith, and whether crafting exists at all.

## 1. Scope

**This doc owns:**

- The currency: what it is called, its scale, its display and its save field.
- The complete faucet/sink ledger and the per-tier income-versus-cost curve.
- Vendor buy and sell prices, and the formula that derives them from item stats.
- Consumables: the SKU list, effects, prices and stocking rules.
- Comfort items and facility upgrades — the **price tags**, not the morale deltas.
- The crafting / salvage / equipment-upgrade decision, and the spec if it ships.
- The Guildhall quest/achievement board as a **reward faucet**.
- Anti-exploit rules for anything that touches money.

**This doc does NOT own:**

| Topic | Owner |
|---|---|
| Which building unlocks at which rank, and what each building *does* | [02 — The Town & Its Buildings](02-town-and-buildings.md) |
| Reputation rank thresholds and the rank → stock/sell-rate ladder's *shape* | [03 — Guild Reputation](03-guild-reputation.md) |
| Recruit rarity, mistake bands, backstory tags, dismissal rules | [04 — Raiders & Recruitment](04-recruitment-and-roster.md) |
| Morale math: bands, deltas, drift, caps, wishlist rules | [05 — Morale](05-morale.md) |
| Item stat blocks, loot tables, drop slots, trinket stats | [09 — Items & Loot](09-items-and-itemization.md) |
| Wipe rules, partial credit, retry/checkpoint behaviour | [01 — Core Loop & Session Flow](01-core-loop.md) |

Rule of engagement with doc 05 and doc 09: **they own the effect, we own the price.** If a row here quotes a morale number or a stat number, it is quoted from them, and if they retune it, this doc's price stays and the effect column changes.

## 2. Canon anchors

Everything canon says about money, shops and crafting, verbatim, with its hedges intact.

| # | Canon text (verbatim) | Source | Status |
|---|---|---|---|
| A1 | "You earn money." | raw notes, *Core things to do* | ✅ CANON |
| A2 | "You spend money at the blacksmith/Merchant." | raw notes, *Core things to do* | ✅ CANON |
| A3 | "Buy consumables (Potions)" | raw notes, *Market* | ✅ CANON |
| A4 | "Sell loot" | raw notes, *Market* | ✅ CANON |
| A5 | "Crafting Supplies < Maybe" | raw notes, *Market* | ❓ OPEN — the "Maybe" is canon |
| A6 | "Blacksmith (Maybe)" | raw notes, section heading | ❓ OPEN — the "Maybe" is canon |
| A7 | "Equipment upgrades < Maybe" | raw notes, *Blacksmith (Maybe)* | ❓ OPEN |
| A8 | "Salvaging < If we do crafting" | raw notes, *Blacksmith (Maybe)* | ❓ OPEN — conditional on A10 |
| A9 | "Weapons and armor crafting < If we do crafting" | raw notes, *Blacksmith (Maybe)* | ❓ OPEN — conditional on A10 |
| A10 | *Whether crafting exists at all* | **Not stated anywhere in either source** | ❓ OPEN |
| A11 | "Manage morale with comfort items" | raw notes, *Guildhall* | ✅ CANON |
| A12 | "Upgrade guild facilities < better morale values" | raw notes, *Guildhall* | ✅ CANON |
| A13 | "Quest/achievement board" | raw notes, *Guildhall* | ✅ CANON |
| A14 | Tutorials skippable, forfeiting "a special loot piece that is easy… Like a +1 dps trinket or something" | raw notes, *Adventure's Board* | ✅ CANON |
| A15 | Recruits at Known+ arrive with "1-2 pieces of basic adventure gear from your current raid tier" | raw notes, *Guild Reputation* | ✅ CANON — see §12.1 |

**What canon does not give us:** no currency name, no price, no payout, no sell rate, no hire cost, no consumable other than the word "Potions". Every number in §3 onward is 🔷 PROPOSED. Note also that A2 makes the Blacksmith a canon money sink while A6 marks the Blacksmith itself a "Maybe" — see §14 Q1.

## 3. Currency ❓ OPEN

**Why this exists:** every price in this document needs a unit, and the engine needs one integer field.

### 3.1 🔷 PROPOSED — One soft currency

| Property | Value |
|---|---|
| Name | **gold**, abbreviated **G** — RULED ([15 Q-61](15-open-questions.md#q-61), 2026-09-15): "G" on chips and prices, "gold" in prose, final; the "Guild Coin" placeholder is retired (the copy lint may carry "no coin / Guild Coin / GC in player-facing strings") |
| Type | `int64`, never negative, never fractional |
| Save field | `guild.coin` |
| Anchor scale | **A full first-time clear of Raid 1 yields ≈ 100 G in total value** (direct payout + sale of the junk half of its drops). Adopted from [02 §11](02-town-and-buildings.md), which prices buildings against this same unit |
| Display | Digit-grouped, always with the G suffix: `1,400 G`. Never abbreviate to `1.4k` — the player compares prices constantly |
| Rounding | Every price and payout is rounded to the nearest 5 G after all multipliers. Prices are pre-rounded and cached at load, never rounded at the point of sale |
| Carry | Coin persists across missions, tiers and wipes ✅ (doc 01 lists "unspent coin" among things a wipe does not take) |

### 3.2 🔷 PROPOSED — Argument against a second currency

A second currency (crafting materials, "reputation tokens", a premium tier) is the default instinct and it is wrong at this size:

| Reason | Detail |
|---|---|
| Nothing needs partitioning | A second currency exists to stop fungibility — to force "you cannot buy your way past this gate". This game already has two non-fungible gates: **Guild Reputation** ✅ (which no amount of money buys) and **loot drops** ✅ (which come only from encounters). Coin is already fenced out of both |
| It doubles the shop UI | Every price line, every affordability check, every tooltip and every "can't afford" state forks |
| It halves the legibility of the single decision this economy is for | "Potions, comfort item, or save for the facility upgrade?" is a clean three-way. Add a currency and the player must first learn which pile a price draws from |
| Pillar check | Doc 00 A5 rules out premium currency outright; a materials currency is the only remaining candidate, and it exists only if crafting ships (§9) |

**The one allowed exception:** if the salvage-plus-upgrade path in §9.4 ships, it produces **Fittings** — a non-tradeable, non-sellable *upgrade unit*, not a currency. Fittings have no exchange rate to G in either direction, cannot be bought, and are the reason §9.4 does not reintroduce a second economy. If Fittings ever become purchasable, they are a currency and this section is void.

## 4. The ledger — every faucet and every sink 🔷 PROPOSED

**Why this exists:** an economy that has not been written down as one table does not close. This is that table. All values are Tier 1; §5 scales them.

### 4.1 Faucets (income)

| # | Source | Canon | Tier 1 scale | Frequency | Notes |
|---|---|---|---|---|---|
| F1 | Encounter clear payout | ✅ A1 (that money is earned; the amount is ours) | E1 6 G · E2 8 G · E3 14 G · E4 16 G · E5 26 G = **70 G** per full Raid 1 | Per encounter, first clear | Uses canon's five-encounter raid layout |
| F2 | Adventure clear payout | ✅ A1 | Adventure 0: 4 G · Tutorial Raid: 8 G · Adventure 1: 20 G | Per clear | Canon placeholders; naming pending |
| F3 | Selling loot at the Market | ✅ A4 | ≈ 30 G per Raid 1 clear at the Unknown sell rate | Per loot distribution | §6 owns the formula. **The main income lever** |
| F4 | Quest/achievement board rewards | ✅ A13 (that it exists) | 10–120 G per entry, ~40 entries at ship | One-off, per entry | §11 |
| F5 | Repeat-clear payout | 🔷 | F1 × decay: 100% → 50% → 25% → floor 10% | Per repeat | Mirrors doc 03's repeat-reputation halving. §12.4 |
| F6 | Tutorial skip-forfeit | ✅ A14 | **Not a faucet.** Skipping *loses* the trinket; it pays nothing | — | Canon is explicit that the reward is deliberately weak |
| F7 | Salvage yield | ❓ A8 | 25% of item value in G + Fittings | Per salvage | Only if §9.4 ships |

Deliberately **not** faucets: idle/passive income, selling consumables (§12.3), selling comfort items (§12.3), a daily stipend. This game's income comes from playing content, because content is what the town's progression is meant to reward.

### 4.2 Sinks (spending)

| # | Sink | Canon | Tier 1 price | Frequency | Elasticity |
|---|---|---|---|---|---|
| S1 | Recruiting | ✅ "You recruit people at the tavern as needed" | Common 15 G · Uncommon 60 G · Rare 160 G · Epic 420 G · Legendary 1,000 G — **the project's single recruit price table**, see the note under this table | Bursty, early-tier heavy | Essential |
| S2 | Tavern paid refresh | 🔷 (doc 02 §5.2 asks for the number) | 20 G, doubling per paid refresh in the same mission cycle | Impulse | Discretionary |
| ~~S3~~ | ~~Buy a round~~ struck — cut for 1.0 ([15 BL-40](15-open-questions.md#bl-40)): 96 G for a +2 that drifts away in two ticks is a trap purchase; the Hot Bath Token is the Indulgence line | — | — | — | — |
| S4 | Consumables | ✅ A3 | 8–60 G per SKU, ≈ 15 G per attempt in practice | Per attempt | Essential-ish |
| S5 | Comfort items — Furnishings (durable) | ✅ A11 | 40–260 G | One-off per raider per slot | Discretionary |
| S6 | Comfort items — Indulgences (consumed) | ✅ A11 | 20 G | Per raider per 2 Day Ticks | Discretionary |
| S7 | Guild facility upgrades | ✅ A12 | 150 / 500 / 1,400 G (adopted from doc 02 §11) | Once per level | Discretionary, large |
| S8 | Other building upgrades | 🔷 (doc 02 §11 owns the ladder) | Tavern 120/420/1,200 · Market 130/450/1,100 | Once per level | Discretionary, large |
| S9 | Equipment upgrades | ❓ A7 | 0.5 × item value × rank, + Fittings | Per rank per item | Discretionary |
| S10 | Blacksmith building | ❓ A6 | 300 / 700 / 1,600 G (doc 02 §11) | Once per level | Discretionary, large |
| S11 | Crafting | ❓ A9 | Not priced — see §9, recommended cut | — | — |
| S12 | Crafting supplies | ❓ A5 | Not priced — cut with S11 | — | — |
| S13 | Wipe / retry fee | 🔷 (doc 01 §6.1 proposes 25 G at Tier 1) | 25 G, **charged only from the 3rd attempt** on the same encounter-set per town cycle | Per retry | Punitive |
| S14 | Market buy-back | 🔷 (doc 02 §6.1) | 1.25 × the price it sold for | Rare | Insurance |

**S1 is the only recruit price table in the project.** Two sibling docs currently print their own and both are stale: [04 §3.3](04-recruitment-and-roster.md) lists base costs of Common 60g / Uncommon 180g / Rare 450g / Epic 1,100g / Legendary 3,000g (2.8–4× S1, with its own note that "Gold values are placeholders until doc 11 sets the earn rate"), and [13 §9.4](13-ui-ux.md) renders a third set in the Tavern wireframe (180g / 400g / 1,600g) while stating the costs are doc 04's. §1 gives this doc every number with a price on it, and both §4.3's income-versus-cost curve and §12.1 R3's price floor are computed from the S1 row, so S1 wins. One-line edits owed elsewhere: **doc 04 §3.3** replaces its base-cost column with a pointer to S1 and keeps only its multiplier `cost = base(rarity) × (1 + 0.6 × (CT − 1))`; **doc 13 §9.4** uses `<cost>` placeholders, since that doc owns placement only. Where doc 04's CT multiplier disagrees with §4.3's `tier_scalar = 2.4`, this doc's scaling governs — see §14 Q10.

### 4.3 The curve: expected income vs expected cost, per tier

Assumptions per tier: ~9 mission attempts, ~2.5 full-clear equivalents of the tier raid plus decayed repeats, ~30 drops of which roughly two thirds are unusable by the current roster and get sold. "Essential" = S1 + S4 + S13. "Catalogue" = the full price of everything discretionary that is *available* that tier (all Furnishings for a 12-person roster, that tier's facility level, that tier's building levels, an upgrade pass over the raid group).

| Tier | Gross income | Essential spend | Essential coverage | Discretionary catalogue | Affordable share of catalogue |
|---|---|---|---|---|---|
| 1 | 520 G | 275 G | 1.9× | 900 G | 0.27 |
| 2 | 1,250 G | 660 G | 1.9× | 2,150 G | 0.27 |
| 3 | 3,000 G | 1,580 G | 1.9× | 5,200 G | 0.27 |
| 4 | 7,200 G | 3,800 G | 1.9× | 12,500 G | 0.27 |
| 5 | 17,300 G | 9,100 G | 1.9× | 30,000 G | 0.27 |

Read this as: **the player can always afford to keep playing, and can never afford everything they want.** Essential coverage of 1.9× means the run is never softlocked by poverty; an affordable catalogue share of 0.27 (which becomes ~0.45 with a tier's leftovers carried forward and repeat farming) means each tier forces two or three real refusals.

**Tier scaling is one knob.** Every price and payout in this doc is stored as `base × 2.4^(tier − 1)`, `tier_scalar = 2.4`. Prices in the catalogue must scale with income or the player is gold-rich by Tier 4 by arithmetic alone: a fixed-price shop against exponential income is a shop that closes itself.

### 4.4 The target: gold-constrained. 🔷 PROPOSED — recommended

| Target | What it does to the game |
|---|---|
| **Gold-constrained (recommended)** | The Market is a place with an opportunity cost. Selling a drop is a decision (§6.3). Comfort items compete with facility upgrades, so "keep them happy" has a budget. Every canon building has a reason to be visited more than once |
| Gold-rich | Gold becomes a formality: you buy everything, so the Market, Blacksmith and half the Guildhall degrade into confirmation dialogs. The whole building — canon's "You earn money / You spend money" loop, ✅ A1 and A2 — becomes a click-through, and the game's only remaining constraints are drops and reputation |

**Measurable definition of "constrained" for QA:** at every tier boundary the player's coin balance should sit at **0–20% of that tier's gross income**. Above 35% carried into a new tier means the economy has gone slack and the catalogue needs widening (more Furnishings, more upgrade ranks) or payouts trimming. A player who has never once declined a purchase they wanted is a bug report.

**One guard rail against constraint becoming cruelty:** consumables and Common hires are the only spend the player can be *forced* into, and both are cheap by design (S1: 15 G, S4: ≈ 15 G per attempt against a 70 G raid clear). A player who is broke can always still raid. Poverty must cost the player *options*, never *access*.

## 5. Price scaling and tier coefficients 🔷 PROPOSED

Gear steps, in canon's own progression order, are what price gear:

| Step | Gear step | `value_coeff` |
|---|---|---|
| 1 | Tier 1 Adventure gear | 1.0 |
| 2 | Tier 1 Raid gear | 1.9 |
| 3 | Tier 2 Adventure gear | 3.6 |
| 4 | Tier 2 Raid gear | 6.9 |
| n | — | `1.9^(n−1)` |

Starting armor for common recruits (✅ canon: Worn Iron Cap, Damaged Chainmail, etc.) is **step 0, `value_coeff = 0.35`** — it is deliberately near-worthless, which is the joke.

## 6. Selling loot — the main income lever

✅ CANON: the Market sells loot (A4). Everything below is 🔷 PROPOSED.

### 6.1 Item value formula

**Why this exists:** with nine classes × five encounters of class-restricted drops, hand-pricing every item is both a content cost and a bug farm. One formula prices all current and future loot, including items canon has not statted yet.

```
raw   = 2.0*AC + 1.0*HP + 3.0*Power + 0.8*Mana + 2.5*Damage
value = round_to_5( raw * value_coeff(step) )
sell  = round_to_5( value * sell_rate(rank) )
```

Weights are derived from canon's own stat definitions: "AC = 2 damage reduction", "Power = +1 melee dmg", "Mana = spell damage (Subject to change)". ❓ OPEN — the Mana weight of 0.8 is a placeholder because canon flags Mana as "Subject to change" and leaves the healing/mana formula TBD. It is the one coefficient guaranteed to move.

`sell_rate(rank)` is adopted verbatim from [03 §7](03-guild-reputation.md): Unknown 40% · Known 45% · Respected 50% · Established 55% · Renowned 60% · Legendary 65%.

### 6.2 Worked prices from canon items

Every stat below is quoted exactly from canon; only value and sell are ours.

| Item | Canon stats | Step | raw | value | Sell at Unknown (40%) | Sell at Renowned (60%) |
|---|---|---|---|---|---|---|
| Damaged Chainmail | 3 AC | 0 | 6.0 | 1 G* | 1 G* | 1 G* |
| Iron Adventurer's Cuirass | 5 AC / +6 HP | 1 | 16.0 | 15 G | 5 G | 10 G |
| Iron Adventurer's Sword | +5 Damage | 1 | 12.5 | 15 G | 5 G | 10 G |
| Apprentice's Firestaff | +10 Damage | 1 | 25.0 | 25 G | 10 G | 15 G |
| Blessed Adventurer's Robe | 3 AC / +5 HP / +5 Mana | 1 | 15.0 | 15 G | 5 G | 10 G |
| Adventure's Charm of Health | +7 HP | 1 | 7.0 | 5 G | 1 G* | 5 G |
| Raider's Cuirass | 7 AC / +9 HP / +2 Power | 2 | 29.0 | 55 G | 20 G | 35 G |
| Raider's Helm | 5 AC / +5 HP / +1 Power | 2 | 18.0 | 35 G | 15 G | 20 G |
| Warrior Shield | 7 AC / +8 HP / +1 Power | 2 | 25.0 | 50 G | 20 G | 30 G |
| Strong Raid Staff (Wizard) | +16 Damage | 2 | 40.0 | 75 G | 30 G | 45 G |
| Bard Instrument | +20 Mana | 2 | 16.0 | 30 G | 10 G | 20 G |
| Raider's Robe (Mage/Wizard) | 4 AC / +6 HP / +12 Mana | 2 | 23.6 | 45 G | 20 G | 25 G |

\* **Minimum price is 1 G, never 0** — a rounded-to-zero item still sells, or the sell-all helper silently deletes inventory. Implement as `max(1, round_to_5(...))`, on the value line as well as the sell line.

**Step 0 carries `value_coeff = 0.35`** (§5), and the Damaged Chainmail row is the only place in this table where that matters: `round_to_5(6.0 × 0.35) = round_to_5(2.1) = 0`, floored to 1 G, and no sell rate can lift 1 G back above the floor — so it is 1 G at every reputation rank. Every other ✅ canon starting-armor piece (Worn Iron Cap, Worn Leggings, Old Boots, Tattered Robe, Worn Gi, …) is 1–3 AC at step 0 and prices out identically: **1 G, always.** Do not read the ×1.0 rows above as licence to omit the coefficient on the rest of the starting set. That the whole beginner kit is worth one coin at the Market is the joke, and it is also why S1's Common hire at 15 G is not an arbitrage target (§12.1 R3).

Sanity check against the §3.1 anchor: a full Raid 1 clear for a 12-raider group drops roughly 14 items; a typical roster can use ~5, leaving ~9 sold at an average value of 35 G × 40% ≈ 125 G at first clear — higher than the ≈ 30 G in F3 because F3 assumes a mature roster that keeps more. Both bracket the 100 G anchor once the direct 70 G payout is included; the tuning target is 100–200 G of total value from a first clear and 40–70 G from a farmed repeat.

### 6.3 The wishlist collision — post-1.0 with the module ([15 BL-98](15-open-questions.md#bl-98))

[05 §7.3](05-morale.md) prices this already: **"Passed over: a wishlisted item was sold at the Market — −7 morale, Not capped — this is the player choosing gold over a person."** Canon's own words are that raiders "occasionally wishlist items for bonus morale" (and canon calls this a concept, ❓ OPEN, so this whole interaction may be cut with the module).

The collision is the point, and it is the most interesting decision this doc creates. Concretely, at Unknown, selling a Raider's Cuirass wishlisted by Bob is **+20 G and −7 morale**. Implied exchange rate: ~3 G per morale point. Compare S6, an Indulgence at 20 G for +8 morale (doc 05 §7.4), i.e. 2.5 G per point.

**Therefore the sale is a bad trade whenever the wishlisting raider matters — by design.** The Market pays less per morale point than the Guildhall charges to repair it. Selling a wishlisted item should be something the player does knowingly, to a raider they are already writing off.

Build requirements this places on the Market screen (doc 13 owns the visuals):

| Rule | Spec |
|---|---|
| No blind sales | Every sell row shows: sale price, a wishlist star, the wishlisting raider's name, their morale before → after, and their resulting band |
| Bulk sell is guarded | Doc 02's "Sell all unusable by current roster" helper must exclude wishlisted items by default, and show the total morale cost in the confirm if the player includes them |
| Equipped items | Cannot be sold from the sell list at all; unequip first (doc 02 §6.3 already asks for the "worn by" column) |
| Buy-back covers mistakes | S14 at 1.25×, last 6 items (doc 02 §6.1). Buy-back **does not refund the morale hit** — the raider saw you sell it |

❓ OPEN — if the wishlist module is cut, the −7 row disappears and selling becomes a pure stat-versus-gold decision. This doc's prices do not change either way.

## 7. Consumables 🔷 PROPOSED

✅ CANON gives us exactly one word: "Potions" (A3).

**Why this set exists, and why it looks like this:** the player does not control the raid — the sim does, and the raiders make mistakes. So an in-combat reactive consumable ("use when the tank drops") is unbuildable here: there is no "when". Every consumable is therefore either a **pre-raid buff** committed before the attempt, or a **safety net** the sim spends on the player's behalf under a rule the player can read. That constraint is what makes stocking a real decision at the Market instead of a reflex.

| SKU (placeholder name) | Kind | Effect | Tier 1 price | Why it exists |
|---|---|---|---|---|
| Minor Healing Potion | Safety net | Auto-spent by the sim when a participant drops below 30% HP; restores 25% of max HP. One per raider per encounter maximum | 8 G | The literal canon "Potions". Converts gold into survived mistakes without the player micromanaging |
| Potion of Steady Hands | Pre-raid, single target | −3 percentage points mistake chance for one named raider, this attempt only | 30 G | Prices the canon Steve decision: "Maybe I shouldn't bring him, unless he really wants to go". Now there is a third option — bring him and pay |
| Whetstone Kit | Pre-raid, group | +1 Power to every melee participant (Warrior, Monk, Rogue, Bard) this attempt | 35 G | A gold-funded pass on a DPS check, without touching the canon loot tables. Canon: "Power = +1 melee dmg" |
| Mana Draught | Pre-raid, group | +10 Mana to every caster and healer participant this attempt | 35 G | The same valve on the mana axis — and the tuning lever that lets healing encounters be balanced while healer weapon stats are still TBD in canon |
| Rally Flask | Post-wipe, town | Halves the wipe morale penalty for all participants of the attempt just failed (rounds toward zero). One per attempt | 40 G | Lets gold buy back *time*: a wipe becomes a bill instead of two Day Ticks of Guildhall work |
| Guild Feast | Pre-raid, group | The attempt is simulated using each participant's morale +5. Stored morale is unchanged | 60 G | One raid's worth of competence at a premium, deliberately priced above the Furnishings path so comfort items stay the efficient way to fix morale |

Rules:

| Rule | Spec |
|---|---|
| Commit point | Pre-raid consumables are chosen at the raid-confirm screen and are only *spent* as the attempt begins. Doc 01 §6.2 says cancelling at confirm is free; that must stay true |
| Consumed on wipe | ✅ Adopted from doc 01 §6.1: "Potions consumed up to the wipe are gone" |
| Stack cap | 20 per SKU, per tier variant. Stops the player pre-buying a whole tier's insurance at Tier 1 prices |
| Stock ladder | Market level and rank gate which tiers are stocked — doc 02 §6.2 and doc 03 §7 own that ladder; the potion tier names there ("Minor / Lesser / Standard / Greater / Major / Perfect") are placeholders and map onto the Minor Healing Potion line above |
| Tier variants | Same six SKUs at each tier, price × 2.4 per tier, effect × ~1.8 per tier. No new SKUs at higher tiers — six is the whole list, forever |
| Not sellable | See §12.3 |
| Effects are not ours | The mistake-chance and morale numbers above are quoted from doc 05's model and must be signed off there. If doc 05 changes them, the prices here hold and the effects change |

**Expected consumable spend per attempt** (the S4 line in §4.2): a cautious player brings 12 Minor Healing Potions (96 G) on a tier-opening attempt and nothing else; a routine farm run brings 4 (32 G). Averaged over a tier: ≈ 15 G per attempt, i.e. ~135 G per tier — about 26% of Tier 1 gross income. That is the intended weight: noticeable, not dominant.

## 8. Comfort items & facility upgrades — the morale economy

✅ CANON: "Manage morale with comfort items" (A11) and "Upgrade guild facilities < better morale values" (A12). This section is the price list; [05 — Morale](05-morale.md) owns every delta, and [02 §4.2–4.3](02-town-and-buildings.md) owns the item concept and the facility track.

### 8.1 Two SKU classes 🔷 PROPOSED

Doc 02 models comfort items as **durable placed objects that raise a raider's comfort floor**; doc 05 models a comfort item as an **event worth +8 morale on a 2-Day-Tick cooldown**. Both are useful, and an economy needs the recurring one. Proposal: they are two product lines.

| Class | Behaviour | Economic role |
|---|---|---|
| **Furnishings** | Durable, placed in a raider's quarters slot, raises the comfort floor. Not consumed | Large one-off sink; permanent improvement; competes with facility upgrades |
| **Indulgences** | Consumed on use, gives doc 05's +8 spike, subject to doc 05's 2-tick per-raider cooldown | Small recurring sink; the emergency lever for a raider about to leave |

❓ OPEN — whether the designer wants both, or only one. See §14 Q4.

### 8.2 Furnishings — prices

Names and floor effects are doc 02's 🔷 PROPOSED list, reproduced so the price column has something to price. Prices are ours.

| Furnishing | Floor effect (doc 02) | Price | G per floor point |
|---|---|---|---|
| Straw Cot | +3 | 40 G | 13.3 |
| Trophy Shelf | +4 (+2 more if the raider was present for the kill) | 110 G | 27.5 (18.3 if present) |
| Hot Meal Standing Order | +5 | 90 G | 18.0 |
| Feather Bed | +6 (replaces Straw Cot in the same slot) | 140 G | 23.3 |
| Personal Effect (backstory-matched) | +8 (only valid for matching backstory tags — doc 04 owns tags) | 260 G | 32.5 |
| Hot Meal Standing Order, guild-wide | +5 to all (doc 02: "guild-wide variant costs 4×") | 360 G | 4× per doc 02 |

**Cost per point rises with the size of the effect.** That is deliberate: the cheap floor is cheap, the last few points are expensive, and a 12-raider roster fully kitted at the top end (12 × 260 G = 3,120 G) is a Tier-3 project, not a Tier-1 purchase.

**Worked example.** Doc 02's example: Steve the Mage, ✅ canon 14 morale, Guildhall L2 (floor 50), Feather Bed (+6) + Personal Effect (+8) → effective floor 64. Cost: 140 + 260 = **400 G**, or 77% of Tier 1's entire gross income, to permanently rehabilitate one Common Mage. Reading: fixing Steve properly is a real strategic commitment, and the cheaper answer (bench him, or 3 Indulgences at 60 G to walk him out of the leave bands per doc 05 §11's worked example) is genuinely competitive. Both routes are correct play. That is a healthy sink.

### 8.3 Indulgences — prices

| Indulgence | Effect | Price |
|---|---|---|
| Hot Bath Token | doc 05's comfort-item event: +8 to one raider, 2-tick cooldown | 20 G |
| ~~Buy a round (Tavern, doc 02 §5.1)~~ | struck — cut for 1.0 ([15 BL-40](15-open-questions.md#bl-40)); the Hot Bath Token is the Indulgence line | ~~8 G × roster size (12 raiders → 96 G)~~ |

Cap: purchases of Indulgences per Day Tick may not exceed roster size — the cooldown already limits use, and the cap stops stockpiling for a burst (§12.2).

### 8.4 Facility upgrades — prices

✅ A12 makes this canon in *purpose*; the track, floors and slots are doc 02 §4.3's, and the costs are doc 02 §11's, adopted here unchanged so there is exactly one set of numbers in the project:

| Level | Name (doc 02) | Comfort floor | Slots / raider | Cost | Cumulative | G per floor point (guild-wide) |
|---|---|---|---|---|---|---|
| 1 | Leaking Guildhall | 45 | 1 | 0 G | 0 G | — |
| 2 | Repaired Guildhall | 50 | 2 | 150 G | 150 G | 2.5 G per point per raider (12 roster) |
| 3 | Proper Guildhall | 55 | 3 | 500 G | 650 G | 8.3 |
| 4 | Renowned Guildhall | 60 | 4 | 1,400 G | 2,050 G | 23.3 |

**The comparison the player is meant to make**, and the reason the facility track has to stay cheaper per point than Furnishings at the low end: Guildhall L2 at 150 G buys +5 floor for *everyone* (2.5 G per point per raider) where a Straw Cot buys +3 for one (13.3). So the correct opening move is to upgrade the building, and Furnishings are for the specific problem raider. By L4 the ratio inverts (23.3 vs 13.3), so late-game the answer is per-raider again. That inversion is the intended arc: fix the guild, then fix the people.

Rank gating on these levels is doc 02/doc 03's; a level is buyable only when both its rank gate and its price are met, and the Guildhall screen must show which of the two is blocking.

## 9. The crafting decision ❓ OPEN

Canon gates four features behind hedges — A5 "Crafting Supplies < Maybe", A7 "Equipment upgrades < Maybe", A8 "Salvaging < If we do crafting", A9 "Weapons and armor crafting < If we do crafting" — and **never states whether crafting itself exists** (A10). Two of the four are conditional on an undecided flag. This section does not resolve the "maybe" by fiat; it lays out the trade so the lead designer can.

### 9.1 What crafting adds

| Value | Detail |
|---|---|
| A use for duplicate loot | Canon's raid drops are class-restricted across five encounters × nine classes, so duplicate and unusable gear volume is high by construction. Crafting turns that pile into a resource instead of a receipt |
| Agency over drops | The loot tables are fixed sequences; a bad week has no remedy. Crafting is the answer to "the Chest never dropped" |
| A gold sink that is not consumables | Without it, once potions are stocked and the facility is bought, gold has nowhere to go mid-tier (doc 02 §8 makes the same point) |
| Fantasy fit | A blacksmith who cannot make anything is a strange blacksmith |

### 9.2 What crafting costs

| Cost | Detail |
|---|---|
| A whole subsystem | Recipes, materials, material sources, material drop tables, a crafting queue or instant-craft rule, and a balance pass against the loot tables |
| UI | A recipe browser, a materials inventory, a salvage bin, a Market supplies tab (A5), and per-recipe affordability states |
| Content | ~90 recipe rows to cover nine classes × slots × tiers — and every one of them is a second, parallel version of an item the loot tables already define |
| Balance surface | Every craftable competes with a raid drop. If craftables are weaker they are dead content; if equal they replace raiding; if stronger they invalidate the most finished part of canon |
| Doc 02's estimate | 4.0 EW + 0.5 AU for crafting, +0.5 EW for the supplies tab, +1.0 EW for the crafting version of salvage |

### 9.3 What happens if it is cut

| Consequence | Severity |
|---|---|
| Duplicates become pure gold (§6) | Low — selling is already ✅ canon (A4) and already the main faucet |
| No remedy for bad drop luck | **Medium** — this is the real loss, and §9.4 recovers most of it |
| The Blacksmith has one service instead of three | Medium — survivable if that one service is good (§10) |
| Canon lines A5, A8, A9 go unbuilt | Low — all three are hedged in canon itself |
| The Market's Supplies tab never ships | None — hide it behind the same flag (doc 02 §6.3 already does) |

### 9.4 🔷 PROPOSED — Recommendation: cut full crafting, ship salvage + upgrade

**The cheapest version that captures most of the value is salvage-plus-upgrade without recipes.** It buys the two things §9.1 actually wants — a use for duplicates and agency over drops — for roughly a quarter of the cost, and it adds no materials economy, no recipe content and no parallel gear path.

| Feature | Verdict | Reason |
|---|---|---|
| Weapons and armor crafting (A9) | 🔷 **Cut for v1** | Duplicates the canon loot tables, which are the most complete part of canon |
| Crafting supplies at the Market (A5) | 🔷 **Cut with it** | It has no purpose without recipes |
| Salvaging (A8) | 🔷 **Ship a degenerate version** | Salvage yields G + Fittings. No materials, no recipes |
| Equipment upgrades (A7) | 🔷 **Ship** | See §10. Highest agency per engineering week in the whole document |

Degenerate salvage spec:

| Rule | Value |
|---|---|
| Where | Blacksmith (❓ A6 — if the Blacksmith is cut, salvage moves to the Market and the Blacksmith's absence costs the game nothing but a façade) |
| Gold yield | 25% of item value — deliberately **below** every sell rate (40–65%), so salvage is never the money-maximising move |
| Fittings yield | `max(1, floor(value / 20))` Fittings |
| Fittings | Non-purchasable, non-sellable, no G exchange rate, single shared pool, save field `guild.fittings` |
| Only use | Equipment upgrade ranks (§10) |
| Irreversible | Salvaged items do not enter the buy-back list. One confirm, wishlist warnings included (§6.3) |

The player's choice becomes: **sell for gold, salvage for upgrade capacity, or give it to a raider.** Three destinations for every drop, one new resource, no recipes. This is the recommendation.

## 10. Equipment upgrades ❓ OPEN

Canon: "Equipment upgrades < Maybe" (A7). If it ships, this is the spec. Its one hard requirement is that it must not invalidate the canon loot tables in [09 — Items & Loot](09-items-and-itemization.md).

### 10.1 Mechanics 🔷 PROPOSED

| Rule | Spec |
|---|---|
| What a rank does | +1 to the item's **existing primary stat** (AC for armor and shields, Damage for weapons), and +1 HP if the item already has HP |
| What a rank never does | **Never adds a stat the item does not already have.** Canon is explicit that "Power column is empty (—) on every Tier 1 Adventure armor piece; Power only begins appearing on Tier 1 Raid armor" — upgrading must not smuggle Power onto Adventure armor, or the tier identity of the tables dissolves |
| Rank cap (building) | Blacksmith L1 → +1, L2 → +2, L3 → +3 (doc 02 §11) |
| Rank cap (item) | `min(building_cap, next_step_headroom)` — see §10.2 |
| Cost | `0.5 × item value × rank` in G, plus `2 × rank` Fittings |
| Display | `Raider's Cuirass +2`, with the base stats and the upgrade delta shown separately, always |
| Transfer | Ranks live on the item, not the raider; the item can be re-equipped freely inside the guild |
| Refund | Salvaging an upgraded item refunds 50% of the Fittings spent (rounded down) and nothing in G |
| Loss | Nothing is ever lost on a wipe — doc 01 §6.3 explicitly rejects gear destruction |

### 10.2 The invariant that protects the loot tables

> **A fully upgraded item of step N may never exceed the base stats of the same slot's item at step N+1 on any stat.**

Implementation: `next_step_headroom = base_stat(step N+1, slot) − base_stat(step N, slot)`, clamped at 0. The cap is per stat and per slot, computed from the tables in doc 09 at load, never hand-entered.

Consequence, and the reason this rule exists rather than a flat +3: a flat cap of +3 **breaks canon immediately**. Iron Adventurer's Cuirass is 5 AC; +3 makes it 8 AC; Raider's Cuirass — a Boss 4 drop — is 7 AC. A raid drop would be strictly worse than a shop-upgraded starter piece. Headroom capping makes that structurally impossible.

Validation table over the two gear steps canon actually gives us (all stats verbatim from canon):

| Slot | Step 1 (Adventure) | Step 2 (Raid) | Headroom | Fully upgraded step 1 | Still beaten by the raid drop? |
|---|---|---|---|---|---|
| Warrior/Bard Head | Iron Adventurer's Helm 3 AC | Raider's Helm 5 AC / +1 Power | +2 | 5 AC | Yes — Power and HP |
| Warrior/Bard Chest | Iron Adventurer's Cuirass 5 AC | Raider's Cuirass 7 AC / +2 Power | +2 | 7 AC | Yes — Power and HP |
| Warrior/Bard Legs | Iron Adventurer's Greaves 4 AC | Raider's Greaves 5 AC / +1 Power | +1 | 5 AC | Yes — Power and HP |
| Warrior/Bard Feet | Iron Adventurer's Boots 3 AC | Raider's Boots 4 AC | +1 | 4 AC | Ties on AC, wins on HP (+3 vs +4) |
| Monk Head | Ironbound Headband 4 AC | Raider's Headband 5 AC | +1 | 5 AC | Ties on AC, wins on HP |
| Monk/Rogue Chest | Reinforced Leather Vest 4 AC | Raider's Vest 6 AC / +2 Power | +2 | 6 AC | Yes — Power |
| Monk/Rogue Legs | Reinforced Leather Leggings 3 AC | Raider's Leggings 5 AC / +1 Power | +2 | 5 AC | Yes — Power |
| Rogue Head | Reinforced Rogue Eyepatch 3 AC | Raider's Eyepatch 4 AC / +2 Power | +1 | 4 AC | Yes — Power |
| Healer Chest | Blessed Adventurer's Robe 3 AC / +5 Mana | Raider's Vestments 4 AC / +10 Mana | +1 | 4 AC / +5 Mana | Yes — Mana |
| Mage/Wizard Chest | Reinforced Spellweave Robe 2 AC / +6 Mana | Raider's Robe 4 AC / +12 Mana | +2 | 4 AC / +6 Mana | Yes — Mana |
| Monk 2H | Iron Adventurer's Staff +9 Damage | Basic Raid Staff +10 Damage | +1 | +10 Damage | Ties; Strong Raid Staff (+14) clears it |
| Mage 2H | Apprentice's Firestaff +10 Damage | Basic Raid Staff +11 Damage | +1 | +11 Damage | Ties; Strong (+15) clears it |
| Wizard 2H | Apprentice's Arcstaff +10 Damage | Basic Raid Staff +12 Damage | +2 | +12 Damage | Ties; Strong (+16) clears it |
| Warrior/Rogue/Bard 1H | Iron Adventurer's Sword +5 Damage | Basic Raid Dagger +4 Damage (Rogue) | **−1** | +5 Damage | ❗ **No** — see §14 Q6 |

Two structural notes fall straight out of that table:

1. **Ties are acceptable, headroom of 0 is not a bug.** Where a fully upgraded piece ties the next drop on the primary stat, the drop still wins on HP/Power/Mana. The upgrade path can pull level with the *next* step but never past it.
2. **The last tier is where +3 finally applies.** At the highest unlocked step there is no step N+1, so `next_step_headroom` is unbounded and the building cap governs. That is the correct place for the biggest upgrade to live: it is a sink for endgame gold with no tier to invalidate.

### 10.3 Cost worked example

Upgrading a Boss-4 Raider's Cuirass (value 55 G) to +2: rank 1 costs 0.5 × 55 × 1 = **30 G + 2 Fittings**; rank 2 costs 0.5 × 55 × 2 = **55 G + 4 Fittings**. Total 85 G and 6 Fittings for +2 AC / +2 HP on one piece. Six Fittings is roughly four salvaged Raid-tier items. Compare: a Straw Cot is 40 G. So a single upgrade pass to +2 over the two tanks' chest and head (4 items, ~280 G, 24 Fittings — two chests at 85 G each plus two Raider's Helms, value 35 G, at 20 + 35 = 55 G each) is a whole tier's discretionary budget — which is exactly why §4.3's affordable-catalogue share sits at 0.27.

## 11. Quest / achievement board 🔷 PROPOSED

✅ CANON places a "Quest/achievement board" in the Guildhall (A13) and says nothing else. Doc 02 §4.4 proposes it as a record wall of ~40 static achievements with an explicit non-goal of daily/weekly timers. This section adds the **reward faucet** spec (F4) and keeps that non-goal.

**Why this exists as a faucet:** encounter payouts pay for *repetition*; the board pays for *breadth*. It is the game's only lever for steering a player toward content they are avoiding — a second healer, an unskipped tutorial, a benched Common — without ever gating them behind it.

### 11.1 Entry types

| Type | Shape | Count at ship | Steers the player toward |
|---|---|---|---|
| Progress | "Clear Adventure 0" · "Clear Raid 1" | ~12 | Following the canon content order |
| Mastery | "Clear Raid 1 with 12/12 alive" · "Clear an encounter with no mistakes" | ~10 | Replaying content well rather than more |
| Roster | "Field one of every class" · "Recruit a Legendary" · "Keep a Common at 90+ morale" | ~8 | Using the whole class list and the morale system |
| Comedy | "Big Dumb — lose a Legendary raider to morale" · "Wipe on Encounter 1 five times" | ~6 | Nothing. Rewards failure, because failure is the game's genre |
| Economy | "Sell 100 items" · "Fully upgrade one item" | ~4 | Touching the systems in this doc at least once |

### 11.2 Reward kinds and scale

| Reward | Tier 1 scale | When to use it |
|---|---|---|
| Coin | 10 G (Progress) · 25 G (Mastery) · 40 G (Roster) · 120 G (a tier capstone) | Default. Roughly one raid clear's worth per tier, spread across ~8 entries |
| A Furnishing, granted | Straw Cot / Trophy Shelf | Roster and Comedy entries — thematic, and it seeds the morale economy for a player who has not found the Market's Comfort tab |
| Reputation points | doc 03 §6 owns rates | Only where doc 03 signs off; doc 02 §4.4 flags this as the sole non-mission reputation faucet |
| A town scene flag | Banner, statue | Free in G and the strongest reward in a game whose progression bar is the town |
| Consumable bundle | 5 Minor Healing Potions | Early Progress entries; teaches the consumable loop by giving it away once |

Rules: no timers, no repeatable entries, no random rewards. Total coin from the board across the whole game is capped at **~15% of lifetime income** — enough to feel like a faucet, never enough to substitute for playing content. Rewards are claimed manually at the board (so the player reads what they earned), and unclaimed rewards never expire.

## 12. Anti-exploit rules 🔷 PROPOSED

**Why this exists:** every rule in this doc creates a loop, and an unpriced loop is a money printer. Each rule below is stated as something a programmer can assert in a test.

### 12.1 Recruit-gear arbitrage

The exploit: ✅ canon says recruits at Known+ arrive with "1-2 pieces of basic adventure gear from your current raid tier" (A15). Hire an Uncommon for 60 G, strip their gear, dismiss them, keep the gear, repeat. Doc 04 owns dismissal; the money side is ours.

| Rule | Spec |
|---|---|
| R1 — Arrival gear is bound to the raider | Items a recruit arrives wearing are flagged `arrival_bound = true`. When that raider leaves or is dismissed, their still-equipped arrival gear leaves with them. Only gear the guild issued returns to the vault |
| R2 — Bound gear is unsellable and unsalvageable while bound | It becomes normal guild property (and sellable) once that raider has completed one mission, at which point the hire was not a laundering trick |
| R3 — Price floor | Assert in test: `hire_cost(rarity) ≥ 1.5 × expected_sale_value(arrival_gear(rarity))`, reading `hire_cost` from §4.2 S1 — the single price table — and never from doc 04 §3.3. At Uncommon: 60 G ≥ 1.5 × (2 × 6 G) = 18 G ✔ |
| R4 — Dismissal is not free | Doc 05 §7.2 already charges −2 morale to the whole roster per voluntary dismissal. Churn has a running cost that is not in G |

R1 alone kills the exploit; R3 is the regression test that keeps a future price change from reopening it.

### 12.2 Morale farming

| Exploit | Rule |
|---|---|
| Spam Indulgences to park everyone at 100 | Doc 05's 2-tick per-raider cooldown, plus the §8.3 per-tick purchase cap, plus the price. Doc 05 §7.6 already computes a sustainable ceiling of 80 without active play (50 + 12 + 10 + 8, for a Legendary with tier-3 facilities and the best backstory) |
| Buy a round every tick | Once per Day Tick, and priced per head so a large roster makes it expensive |
| Stockpile Indulgences cheaply at Tier 1 for use at Tier 5 | Consumable and Indulgence stack caps (20 per SKU), and tier variants: a Tier 1 Hot Bath Token gives the Tier 1 effect forever |
| Wishlist churn: sell, buy back, re-grant for the +12 | Buy-back never refunds morale (§6.3), and doc 05 caps wishlist grants at one per raider per 3 Day Ticks |
| Guild Feast + wishlist stacking to fake a high band | Guild Feast changes only the attempt's simulated morale, never stored morale, so it cannot feed leave checks or drift |

### 12.3 Vendor loops

| Rule | Spec |
|---|---|
| V1 — Buy-back is always a loss | Buy-back is 1.25 × the *sale* price (doc 02 §6.1). A sell-then-buy-back round trip at Unknown returns 40% and costs 50% of value: −10% per cycle. Assert `buyback_price > sell_price` for every rank |
| V2 — Consumables, Furnishings and Indulgences sell for 0 G and are absent from the Sell tab | Not merely a bad rate — **not sellable at all**. This is the single rule that removes every buy-low/sell-high loop from the game, because those are the only items with a buy price |
| V3 — Sell rate is always below 100% of value | Assert `max(sell_rate) = 0.65 < 1.0`. Gear cannot be arbitraged against itself across reputation ranks either, since buying gear is impossible: the Market never *sells* equipment. ❓ OPEN — if it ever does, V3 needs a companion rule that buy price > sell price at every rank |
| V4 — Salvage pays less than selling | 25% versus 40–65%. Salvage is a choice about Fittings, never a better way to get gold |
| V5 — Fittings have no exchange rate | Cannot be bought or sold (§3.2, §9.4). Salvage-refund on upgraded items is 50%, so upgrade-then-salvage churn is a net Fittings loss |

### 12.4 Repeat-content farming

| Rule | Spec |
|---|---|
| R5 — Repeat payout decay | F5: an encounter's gold payout decays 100% → 50% → 25% → floor 10% on successive clears, per encounter, resetting when a new tier unlocks. Mirrors doc 03's repeat-reputation halving so the two faucets decay together |
| R6 — Same-cycle re-clears pay 0 G | An encounter already cleared this town cycle pays nothing, so doc 01's checkpoint/retry system cannot be used as a coin pump |
| R7 — Retry fee starts at attempt 3 | S13's 25 G applies from the third attempt on an encounter-set within a town cycle. Doc 01 wants retry spam discouraged; charging attempt 2 punishes the considered retry doc 01 explicitly wants to protect, and at 4 retries a flat fee would eat 19% of Tier 1 income |
| R8 — Drops decay with payout | Doc 09 owns drop rates; the same decay curve must apply, or the player farms items to sell instead of coin directly |

## 13. Implementation notes

| Item | Spec |
|---|---|
| Single source of truth | One `economy.tres` resource: `tier_scalar = 2.4`, `value_weights`, `value_coeff` per step, `sell_rate` per rank, and a flat SKU table. No price literals in scene scripts |
| Derived, not stored | Item values, sell prices and upgrade caps are **computed** from doc 09's tables at load and cached. A retune of a stat block must not require a price edit, and must not invalidate a save |
| Save fields | `guild.coin` (int64), `guild.fittings` (int, only if §9.4 ships), `inventory[]` with `arrival_bound` and `upgrade_rank` per item, `board_claimed[]` |
| Feature flags | `FEATURE_BLACKSMITH`, `FEATURE_UPGRADES`, `FEATURE_SALVAGE`, `FEATURE_CRAFTING`, `FEATURE_WISHLIST`. Every ❓ OPEN system in this doc must be shippable-off, and the Market's Supplies tab and the Blacksmith façade both hide behind theirs |
| Test assertions | The named rules R1–R8 and V1–V5, plus the §10.2 invariant swept over every slot and step pair in doc 09 |
| Telemetry | Coin balance at each tier boundary (§4.4's 0–20% target), share of drops sold vs kept vs salvaged, number of purchases declined for affordability, wishlist items sold per tier |

## 14. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| 1 | Canon marks the Blacksmith "(Maybe)" (A6) yet the core loop states "You spend money at the blacksmith/Merchant" (A2). Is the Blacksmith optional or is it a canon money sink? | If it is cut, half of a ✅ CANON loop line has no building, and S9/S10 leave the ledger — about 25% of the Tier 3+ catalogue | Build it, upgrades only, no crafting. Concurs with doc 02 §8 M1 |
| 2 | Does crafting exist at all? Canon never says (A10), yet three features hang off the answer (A5, A8, A9) | It is a 5+ EW subsystem versus a 1.5 EW one, and it decides whether duplicate loot is gold or a resource | No full crafting for v1. Ship degenerate salvage + upgrades per §9.4 |
| 3 | What is the currency called? | It appears in every UI string, and the placeholder "Guild Coin / G" is already propagating through docs 01, 02 and 03 | Keep "Guild Coin (G)" as the placeholder until named; do not localise strings before it is decided |
| 4 | Are comfort items durable Furnishings (doc 02), consumed Indulgences (doc 05's +8 event), or both (§8.1)? | It decides whether the morale economy is a one-off purchase or a recurring bill — the difference between ~500 G and ~1,500 G of Tier 1–3 sinks | Both, as two SKU lines. The recurring line is what keeps gold relevant mid-tier |
| 5 | Canon's tutorial reward is "Like a +1 dps trinket or something" (A14), but the stat list is AC / Power / Mana with Damage on weapons. Is "+1 dps" +1 Power or +1 Damage? | It changes the trinket's value under §6.1 by 3.0 versus 2.5 per point, and doc 09 needs a real stat block. Three docs currently disagree on the same item | **+1 Power** — and [09 §10.1](09-items-and-itemization.md), which owns stat blocks, already proposes exactly that ("Cracked Charm of Power — +1 Power"). Canon puts Damage only on weapons and Power on trinkets ("Adventures Charm of Power — +2 Power"), and doc 09 notes the trinket is the *only* Adventure-tier Power source. Propagation owed, one line each: [01 §8.2](01-core-loop.md)'s "Trinket of Mild Competence — +1 Damage" and [10 §9.2](10-content-and-encounters.md)'s "+1 Damage" row both become **+1 Power** |
| 6 | Rogue's Tier 1 Adventure main hand is the shared Iron Adventurer's Sword at **+5 Damage**, but the Rogue's Tier 1 **Raid** main hand is Basic Raid Dagger at **+4 Damage** — the raid drop is worse per hand. Intended (dual-wield maths, or daggers carry something unstatted) or an error? | §10.2's headroom cap goes negative, so the Rogue's weapon cannot be upgraded at all; and a Boss 1 drop is a downgrade, which reads as a bug to players | Treat as canon and **do not fix**. Clamp headroom at 0 (no upgrade) and flag the Rogue weapon line for the designer. This is a doc 09 decision |
| 7 | How is Mana weighted against Power for pricing, given canon's "Mana = spell damage (Subject to change)" and healer weapons "unsure how much… we need to discuss if we want to have 2 variables or not"? | Mana appears on 20+ canon items; a wrong weight misprices every healer and caster drop in the game | 0.8 per point, revisited the moment the healing/mana formula lands. Isolated in one config field for exactly that reason |
| 8 | Unstatted canon items — Raid Trinket (all nine classes), Monk Final Headband, Rogue Final Eyepatch, Basic/Strong Healing Weapon, Cleric/Druid/Shaman Weapon, Mage Staff, Wizard Staff — cannot be priced by §6.1 | These are Boss 5 capstones: the most valuable drops in a tier have no sale price, no salvage yield and no upgrade cap | Interim rule: an unstatted item prices at 1.4 × the highest-value statted item of its step, flagged in a debug list, until doc 09 stats it |
| 9 | Sibling docs point at three different filenames for this document (`09-economy.md`, `07-economy-and-items.md`, `11-economy-and-currency.md`) and two for doc 04 | Broken cross-links in the doc set the team actually builds from | This file is `11-economy-and-crafting.md`. **CLOSED 2026-09-10** — the link pass over docs 01–08 landed and `tests/unit/test_docs_links.gd` now fails on a dead doc link. The three names above are kept as the record of what the stale links said |
| 10 | Is `tier_scalar = 2.4` the right slope, given the content list runs to Raid 5 and "This continues"? | Compounded over five tiers it is a 33× swing in every price. Too steep and early gear is worthless; too shallow and the player is gold-rich by Tier 4 | 2.4, tuned against the §4.4 telemetry target of a 0–20% carried balance at each tier boundary |

## Related documents

- [00 — Vision & Design Pillars](00-vision-and-pillars.md) — pillar A5 rules out premium currency, which is half of §3.2's argument.
- [01 — Core Loop & Session Flow](01-core-loop.md) — the wipe cost model this doc prices (S13), and the partial-credit rule that R6 has to defend against.
- [02 — The Town & Its Buildings](02-town-and-buildings.md) — the buildings, shop tabs, comfort item names and facility track whose price tags live here; also the source of the 100 G anchor.
- [03 — Guild Reputation](03-guild-reputation.md) — the rank → sell-rate and stock ladder §6.1 consumes, and the repeat-decay pattern R5 mirrors.
- [04 — Raiders & Recruitment](04-recruitment-and-roster.md) — recruit rarity and arrival gear behind §12.1, and the backstory tags the Personal Effect Furnishing needs.
- [05 — Morale](05-morale.md) — every morale number quoted in §8 and §6.3; if a delta moves, it moves there and the prices here stand.
- [09 — Items & Loot](09-items-and-itemization.md) — the stat tables §6.1 prices from and §10.2's upgrade caps are computed against.
