# 03 — Guild Reputation

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs Guild Reputation — the guild's single primary stat — its six ranks, the recruit-quality probability matrix each rank produces, how reputation is earned, and everything a rank gates.

## 1. Scope

**This doc owns:**

- The six-rank reputation ladder and the starting rank.
- The **recruit-rarity-by-rank probability matrix**. This doc is its canon home. Doc 04 links here; it does not restate the numbers.
- The definition of the five raider rarity tiers as they relate to *finding* raiders.
- The Reputation Point (RP) economy: awards, diminishing returns, thresholds, pacing, and loss rules.
- The master table of what each rank gates.
- The uniqueness rule for Legendary raiders.

**This doc does NOT own:**

| Topic | Owner |
|---|---|
| Building interiors, upgrade trees, facility costs | [02 — Town & Buildings](02-town-and-buildings.md) |
| Tavern UI, recruit pool size, refresh cadence, class weighting, recruit cost, backstories | [04 — Recruitment & Roster](04-recruitment-and-roster.md) |
| Morale bands, morale gain/loss, mistake-chance formula | [05 — Morale](05-morale.md) |
| Encounter design, boss mechanics, loot tables | [10 — Content & Encounters](10-content-and-encounters.md) |
| Gold, item values, actual shop prices | [11 — Economy & Crafting](11-economy-and-crafting.md) |

> Sibling filenames above are the canonical set in [00 §1.1](00-vision-and-pillars.md), which is the only filename authority in the set — this doc used to name a standalone index file that was never written, as an escape clause for the stale slugs in the table above. Those were re-pointed on 2026-09-10, so the clause is gone.

---

## 2. Vocabulary — the two meanings of "rare"

🔷 PROPOSED. **Why this exists:** canon uses the word "rare" for two unrelated things in the same paragraph, and once uses "common" as a frequency adverb about the Common tier ("finding uncommon raiders is now common" — canon: raw notes, Guild Reputation). If the team does not split these terms the wrong one will get implemented.

| Term | Means | Type | Never say |
|---|---|---|---|
| **Rarity tier** | An intrinsic, permanent property of a raider: `Common \| Uncommon \| Rare \| Epic \| Legendary`. Drives base mistake chance, starting gear, morale resilience. | enum, set at generation | "rarity" alone |
| **Find chance** | The probability that one generated recruit rolls a given rarity tier. A property of the *guild's rank*, not of the raider. | per-mille integer weight | "rare chance" |

Rules for the team:

- In code, the enum is `RarityTier`; the table in §5 is `find_weights[rank][tier]`, integers out of 1000.
- In UI and text, always write the tier capitalised (**Rare**) and the probability as "find chance" or "appearance rate".
- A **Rare** raider is a rarity tier. A *rare* event is a low find chance. A Legendary raider can have a high find chance at a high rank; an Epic raider can have a low one. The two axes are independent.
- Canon's sentence "finding uncommon raiders is now common" translates to: *Uncommon becomes the modal find result at Respected.* It does **not** mean Uncommon changes tier.

---

## 3. The ladder

✅ CANON (canon: raw notes, Guild Reputation — "Your guild has a single primary stat: **Guild Reputation**").

| # | Rank | Canon status |
|---|---|---|
| 1 | Unknown | ✅ CANON — the starting rank ("You start at: Unknown") |
| 2 | Known | ✅ CANON |
| 3 | Respected | ✅ CANON |
| 4 | Established | ✅ CANON (name only — effects unspecified, see §5.4) |
| 5 | Renowned | ✅ CANON |
| 6 | Legendary | ✅ CANON (name only — effects unspecified, see §5.4) |

✅ CANON: "Reputation determines what starts appearing around town." ✅ CANON: recruiting "is all managed at the - Tavern."

🔷 PROPOSED: the ladder is a display of an underlying integer, **Reputation Points (RP)** (§6). Canon calls reputation "a single primary stat" but never defines a quantity; RP is our implementation of that stat, and the six names are thresholds on it.

⚠️ Naming note: **Legendary** is both the top *rank* and the top *rarity tier*. In code use `GuildRank.LEGENDARY` and `RarityTier.LEGENDARY` and never abbreviate either to `LEGENDARY` alone. In player-facing text the rank is always "Legendary guild"; the tier is always "Legendary raider."

---

## 4. Raider rarity tiers

Canon describes tiers only through what you find at each rank. Consolidated here so §5 can reference one row per tier.

| Tier | Mistake behaviour | Gear it arrives with | Morale resilience | Status |
|---|---|---|---|---|
| Common | "0 raid experience" | The full Worn/Damaged/Tattered starting armour set in canon: raw notes, *Starting armor for common recruits* (4–7 AC by class) | "Lower tier raiders will be hardest to keep happy" | ✅ CANON |
| Uncommon | "a small amount of experience" | "1-2 pieces of basic adventure gear from your current raid tier" | — | ✅ CANON (see tension in §11 Q1) |
| Rare | "decent and only make mistakes sometimes" | canon silent | — | ✅ CANON behaviour; 🔷 PROPOSED gear (§4.1) |
| Epic | "very good … rarely make a mistake" | "1-2 pieces of current raid gear" | — | ✅ CANON |
| Legendary | "basically perfect, near 1% chance of mistake" | "a few pieces of raid gear from your current tier" | "legendary raiders will not be bothered by many things easily" | ✅ CANON |

### 4.1 Starting-gear rule per tier

🔷 PROPOSED. **Why this exists:** canon gives gear for Uncommon, Epic and Legendary and skips Rare; a generator needs all five rows plus an exact meaning for "1-2 pieces."

| Tier | Pieces granted | Source table | Remaining slots |
|---|---|---|---|
| Common | 4 (Head/Chest/Legs/Feet) | Starting armour set (canon, raw notes) | Main hand empty |
| Uncommon | 1–2, roll `randi(1,2)` | Tier 1 Adventure armour for that class (canon: ideaboard §2) | Starting armour set fills the rest |
| Rare | 3–4, roll `randi(3,4)` | Same Adventure armour table | Starting armour set fills the rest |
| Epic | 1–2 | Current-tier **Raid** armour for that class (canon: ideaboard §3) | Adventure armour of the same tier fills the rest |
| Legendary | 3–4 ("a few") | Current-tier **Raid** armour | Adventure armour of the same tier fills the rest |

🔷 PROPOSED: slot selection is uniform without replacement across `[Head, Chest, Legs, Feet]`; weapons are never granted at recruitment (the Market/Blacksmith is the weapon path). "Current tier" = the highest raid tier the guild has **unlocked**, not the highest cleared.

### 4.2 Base mistake chance by tier

**See [08 §8.8](08-stats-and-formulas.md)** — the one published table ([15 Q-04](15-open-questions.md#q-04); this section's 25/15/8/3/1 copy was struck 2026-09-15, W7-DOCS). "Recruit quality" is meaningless without it, which is why the pointer is here; the numbers are not. The one canon-anchored row: Legendary is "near 1% chance of mistake" ✅ CANON, and 08 §8.8's Loves-Their-Guild Legendary reads 0.99%.

✅ CANON constraint doc 08 honours (relief and the floor are ordered for it): "All values above are have within tier limits for mistakes based on their tier" — i.e. morale modifies mistake chance *inside* a per-tier band; morale can never make a Common play like an Epic.

---

## 5. The recruit-quality matrix

This is the centre of the doc. Everything in §5.1 is extracted verbatim-in-substance from canon: raw notes, Guild Reputation. Everything numeric is 🔷 PROPOSED.

### 5.1 Canon constraints, itemised

| # | Constraint | Canon wording |
|---|---|---|
| C1 | At Unknown, Common is the only tier | "@Rank unknown you can only find the worst players to join your guild, they have 0 raid experience etc. (Common raiders)" |
| C2 | At Known, Uncommon first appears | "@Known you have a chance to find raiders that have a small amount of experience … (uncommon raiders)" |
| C3 | Common still appears at Known | Inferred, and only inferable, from C4 — canon never states Known's Common rate |
| C4 | At Respected, Common is gone | "@Respected you no longer find common" |
| C5 | At Respected, Uncommon is the modal result | "finding uncommon raiders is now common" |
| C6 | At Respected, Rare sometimes appears | "sometimes you find rare raiders … (rare raiders)" |
| C7 | Established: **canon says nothing at all** | — |
| C8 | At Renowned, Uncommon is gone | "@renowned you no longer find uncommon raiders" |
| C9 | At Renowned, Epic appears | "you have a chance to find raiders that very good … (epic raiders)" |
| C10 | At Renowned, Legendary appears at a *very small* find chance | "you also gain a VERY SMALL chance to find raiders that are basically perfect" |
| C11 | Legendary rank: **canon says nothing at all** | — |
| C12 | One Legendary per class, ever; Legendaries are named | "You can only ever find 1 Legendary per class - They are also named characters - IE Natsuna(the shaman) or something." |

> ❗ **C10 trap.** The number "1%" in canon belongs to the Legendary raider's *mistake* chance, not to the chance of finding one. Canon gives **no number** for the Legendary find chance — only "VERY SMALL." Do not implement 1% as a find chance because canon says 1% nearby. See §11 Q3.

### 5.2 The matrix

🔷 PROPOSED numbers, ✅ CANON structure. Integer weights per 1000 recruits generated. Rows sum to 1000.

| Rank | Common | Uncommon | Rare | Epic | Legendary |
|---|---|---|---|---|---|
| Unknown | **1000** | 0 | 0 | 0 | 0 |
| Known | **700** | 300 | 0 | 0 | 0 |
| Respected | 0 | **650** | 350 | 0 | 0 |
| Established | 0 | 350 | **650** | 0 | 0 |
| Renowned | 0 | 0 | **800** | 185 | 15 |
| Legendary | 0 | 0 | 0 | **950** | 50 |

Bold = the modal (most likely) tier at that rank.

Same table as percentages, for design conversation only — the per-mille integers above are the implementation values:

| Rank | Common | Uncommon | Rare | Epic | Legendary |
|---|---|---|---|---|---|
| Unknown | 100% | — | — | — | — |
| Known | 70% | 30% | — | — | — |
| Respected | — | 65% | 35% | — | — |
| Established | — | 35% | 65% | — | — |
| Renowned | — | — | 80% | 18.5% | 1.5% |
| Legendary | — | — | — | 95% | 5% |

**Single ownership of the Legendary find chance and the pity rule (🔷 PROPOSED figures, canon home ✅).** The values here — **15 per-mille (1.5%) at Renowned, 50 per-mille (5%) at Legendary rank**, with pity on Rare-or-better at **25 generated recruits** (§8.1 M2) — are the only set in the doc set. Two other docs currently fork them and must cross-reference this section instead of restating numbers: [02 — Town & Buildings](02-town-and-buildings.md) §12 Q1 (3% at Legendary rank, plus a "pity after 40 rolls per class" rule no other doc implements) and [04 — Recruitment & Roster](04-recruitment-and-roster.md) §Q1 ("roughly doubles", i.e. 3%). Both are superseded; §5.5's worked examples (`9 / 0.05` ≈ 180) are built on 5% and break at 3%. If a different rate is preferred, change it **here** and let the other docs follow.

### 5.3 Cell provenance — every cell marked

| Cell | Marker | Basis |
|---|---|---|
| Unknown / Common = 1000 | ✅ CANON | C1: "only … the worst players" — a hard 100% |
| Unknown / all others = 0 | ✅ CANON | C1 |
| Known / Common > 0 | ✅ CANON (inferred) | C3 — the *existence* of the cell is canon by implication; **700 is 🔷 PROPOSED** |
| Known / Uncommon > 0 | ✅ CANON | C2 — **300 is 🔷 PROPOSED** |
| Known / Rare, Epic, Legendary = 0 | ✅ CANON | C6/C9/C10 introduce them later |
| Respected / Common = 0 | ✅ CANON | C4, explicit |
| Respected / Uncommon is modal | ✅ CANON | C5 — **650 is 🔷 PROPOSED** |
| Respected / Rare > 0, minority | ✅ CANON | C6 "sometimes" — **350 is 🔷 PROPOSED** |
| Respected / Epic, Legendary = 0 | ✅ CANON | C9/C10 place them at Renowned |
| **Established — entire row** | 🔷 PROPOSED | C7: canon is silent. See §5.4 |
| Renowned / Uncommon = 0 | ✅ CANON | C8, explicit |
| Renowned / Epic > 0 | ✅ CANON | C9 — **185 is 🔷 PROPOSED** |
| Renowned / Legendary = "very small" | ✅ CANON | C10 — **15 (1.5%) is 🔷 PROPOSED**; canon gives no number |
| Renowned / Rare = 800 | 🔷 PROPOSED | Canon does not retire Rare at Renowned, so it stays and absorbs Uncommon's weight |
| Renowned / Common = 0 | ✅ CANON | C4 retired it two ranks earlier and nothing restores it |
| **Legendary — entire row** | 🔷 PROPOSED | C11: canon is silent. See §5.4 |

### 5.4 The Established and Legendary gap — flagged loudly

> ✅ **RULED ([15 Q-22](15-open-questions.md#q-22), 2026-09-15) — the gap-fill below is signed.** Canon specifies recruit effects for **four** of six ranks: Unknown, Known, Respected, Renowned, and says nothing about **Established** (rank 4) or **Legendary** (rank 6); the two rows below are the ruling. Established is (a)+(b): the Rare modal at the Tavern (Uncommon 350 / Rare 650, unchanged) AND, in town, the Market's fourth level and the Guildhall's third open for purchase ([02 §11](02-town-and-buildings.md), already gated at rank 3, named in `reputation.json`'s Established `town_unlock` so the rank-up callout prints them). Legendary's town line is what that rank actually changes — Perfect potions and "Legendary raiders, one in twenty" — not a phantom Guildhall rung (§7).

🔷 PROPOSED gap-fill, derived from the pattern canon *does* establish. Canon's four specified ranks each do one or both of two moves:

| Move | Where canon uses it |
|---|---|
| **Introduce** a new tier at a minority weight | Known introduces Uncommon; Respected introduces Rare; Renowned introduces Epic and Legendary |
| **Retire** the bottom tier, promoting the next one to modal | Respected retires Common and makes Uncommon modal; Renowned retires Uncommon |

Applying the pattern to the two silent ranks:

| Rank | 🔷 PROPOSED role | Matrix consequence |
|---|---|---|
| **Established** | The *consolidation* rank. No tier is introduced and none is retired; **Rare is promoted to modal** — the "becomes common" beat that canon gave Uncommon at Respected. | Uncommon 650→350, Rare 350→650 |
| **Legendary** | The *terminal* rank. **Rare is retired** (the last "no longer find" beat), Epic becomes modal, and the Legendary find chance rises from very small to merely uncommon. | Rare 800→0, Epic 185→950, Legendary 15→50 |

The 5% at Legendary rank and the 3200 RP threshold stand as the endgame's clock, not a content gate ([15 BL-122](15-open-questions.md#bl-122)): with Raid 5 cleared the continuing activity is the 9-of-9 Legendary collection, ≈ 180 generated candidates or ≈ 30 Tavern boards at that rate — the endgame's length by design, and retiming the rate earlier would spend the prize on a rank that still has raids to gate.

Why this shape and not another:

- It keeps canon's alternating rhythm intact, so Established is not a dead rank and Legendary is not a cosmetic one.
- It never contradicts a canon "no longer find" statement, and never introduces a tier earlier than canon introduces it.
- It gives Epic a two-rank life (Renowned minority → Legendary modal), mirroring Uncommon's and Rare's two-rank lives.

🔷 PROPOSED alternates, if the lead designer prefers a different feel — each a one-line change:

| Alternate | Change | Effect |
|---|---|---|
| **Early Epic** | Established = Uncommon 300 / Rare 620 / Epic 80 | Epic is previewed a rank early. Risks contradicting C9's implication that Renowned is where Epic starts. |
| **Soft top** | Legendary rank = Rare 250 / Epic 710 / Legendary 40 | Keeps some friction at the top rank; recruiting never becomes automatic. |
| **Hard top** | Legendary rank = Epic 900 / Legendary 100 | Top rank feels like a genuine victory lap; may trivialise the last tier. |

**This section is the gap-fill's single home; two other docs currently fill it differently and must defer to the rows above.** [02 — Town & Buildings](02-town-and-buildings.md) §12 Q2 has Established retiring Uncommon ("makes Rare the floor"), which the default here explicitly does **not** do — Established introduces and retires nothing (Uncommon 350 / Rare 650); doc 02 owns only Established's town unlocks (Market L4, Blacksmith L2). [04 — Recruitment & Roster](04-recruitment-and-roster.md) §Q1 gives Established "Epic gains a small chance", which is the rejected **Early Epic** alternate above, not the default, and states the Legendary-rank effect as a doubling rather than the per-mille figures in §5.2. Both should cross-reference this section rather than restate a recruit matrix.

### 5.5 The roll — implementable spec

🔷 PROPOSED. **Why this exists:** the matrix plus the one-Legendary-per-class rule can be implemented in two orders that produce different Legendary rates, so the order must be pinned.

```
func generate_recruit(rank: GuildRank) -> Raider:
    var weights := FIND_WEIGHTS[rank].duplicate()     # per-mille, sums to 1000

    # 1. If every class's Legendary is claimed, Legendary cannot roll.
    if unclaimed_legendary_classes().is_empty():
        weights[Epic] += weights[Legendary]            # redistribute, keep sum 1000
        weights[Legendary] = 0

    # 2. Pity override (§8, M2) can force the tier before any roll.
    var tier := pity_forced_tier(rank)
    if tier == null:
        tier = weighted_pick(weights)                  # roll RARITY FIRST

    # 3. Class second. Legendary draws only from unclaimed classes.
    var cls := (pick_unclaimed_legendary_class() if tier == Legendary
                else pick_class_for_roster())          # doc 04 owns the weighting

    # 4. Gear per §4.1, mistake band per §4.2, backstory per doc 04.
    return build_raider(tier, cls)
```

**Rarity is rolled before class.** The alternative (class first, then downgrade a Legendary whose class is taken) silently erodes the Legendary rate as classes get claimed — by the 9th Legendary the effective rate would be 1/9th of the table value. Rolling rarity first keeps the advertised 1.5% honest for the whole game.

**Worked examples**

| Question | Working | Answer |
|---|---|---|
| Recruits seen before the first Legendary at Renowned | `1 / 0.015` | ~67 recruits (mean); 50% chance within 46 |
| At 4 recruits per Tavern refresh (doc 04's number, provisional) | `67 / 4` | ~17 refreshes |
| Chance of *zero* Legendaries across 100 Renowned recruits | `0.985^100` | 22% |
| Recruits to collect all 9 Legendaries at Renowned only | coupon-collector on a fixed 1.5% with no class repeats: `9 / 0.015` | ~600 recruits — **too slow**; this is why the Legendary rank raises the rate to 5% (`9 / 0.05` ≈ 180) |
| Expected Rare-or-better rate at Respected | `350/1000` | 35% |
| Expected Rare-or-better rate at Established | `(350+650)/1000` minus Uncommon | 65% |

### 5.6 Legendary uniqueness and naming

| Rule | Status |
|---|---|
| At most one Legendary raider exists per class, for the entire save | ✅ CANON (C12) |
| Legendaries are named, authored characters — not procedurally generated | ✅ CANON (C12) |
| Canon example: **Natsuna**, the Shaman | ✅ CANON (C12), and Natsuna appears again at 87 morale in canon's example roster |
| "Ever" means *per save file*, and a Legendary who leaves or dies is **not** replaced and **not** re-findable | 🔷 PROPOSED — canon's "only ever find 1" is about finding, and is silent on loss. See §11 Q6 |
| The other 8 Legendary names | ❓ OPEN — naming pending. Use placeholders `Legendary (Warrior) — name pending`, etc. Do not invent names. |
| Whether "Natsuna" itself is final | ❓ OPEN — canon hedges: "IE Natsuna(the shaman) **or something**" |

🔷 PROPOSED: a `legendary_roster` data table with 9 authored rows (one per canon class: Warrior, Cleric, Druid, Shaman, Rogue, Monk, Mage, Wizard, Bard), each carrying name, portrait, morale-resilience overrides, and the bullet-point backstory canon calls for. Doc 04 owns the backstory schema.

---

## 6. How reputation is earned

> ❓ **OPEN.** Canon establishes the *mechanism* — "the town will be improved by the raids you do. Mostly by gaining reputation levels" and "New Tiers can be unlocked by gaining reputations with the town" — but gives **no rate, no threshold, no currency, and no loss rule**. Everything in §6 is 🔷 PROPOSED and needs sign-off.

### 6.1 Award table

🔷 PROPOSED. **Why this exists:** rank must advance from doing the thing the game is about — clearing encounters — at a rate the team can tune from one table.

Tier 1 base awards. Encounter names and difficulty stars are ✅ CANON (canon: raw notes, *Raid Layout and loot drops*).

| Encounter | Difficulty | First clear RP | Repeat base RP |
|---|---|---|---|
| Encounter 1 (Trash) | ★ | 10 | 2 |
| Encounter 2 (Harder trash) | ★★ | 15 | 3 |
| Encounter 3 (Mini boss) | ★★★ | 25 | 5 |
| Encounter 4 (Mini boss) | ★★★★ | 35 | 7 |
| Encounter 5 (Main boss of tier) | ★★★★★ | 65 | 13 |
| **Full-tier clear bonus** (all 5 in one lockout) | — | **50** | 10 |
| **Raid tier total, first time** | | **200** | |

Adventure and tutorial awards (content list is ✅ CANON; names pending per canon's placeholder note):

| Content | First clear RP | Repeat base RP |
|---|---|---|
| Adventure 0 (1 trash mob) | 5 | 1 |
| Tutorial Raid (1 boss) | 10 | 2 |
| Adventure 1 | 25 | 5 |
| Adventure 2 | 50 | 10 |
| Adventure 3 | 75 | 15 |
| Adventure 4 | 100 | 20 |
| Adventure 5 | 125 | 25 |
| Record wall, reputation-kind records ([02 §4.4](02-town-and-buildings.md); [15 Q-69](15-open-questions.md#q-69)) | — | 15 | 0 |

Reputation-kind records (two ship: One of Each, Comfortable) pay 15 RP each, claimed once, and the board's lifetime RP is capped live at 15% of RP earned exactly as its coin is (`Achievements.rp_cap`; a claim past the share is blocked, never paid short) — Q-69, `FLAG_DEFAULTS.achievement_rp = true`, W7-SAVE. The ladder's proof is unmoved: +30 RP lifetime, never before Known (⌊0.15 × 120⌋ = 18 ≥ 15), and Legendary still lands on Raid 5's full-clear bonus (2815 + 30 + 325 = 3170 < 3200).

✅ CANON: tutorials are skippable, the player is warned they forfeit an easy reward, and the forfeited reward is a minor trinket ("+1 dps trinket or something") — **not** reputation. 🔷 PROPOSED: skipping a tutorial therefore also forfeits its RP (15 RP total), which is deliberately trivial.

### 6.2 Tier scaling and obsolescence

🔷 PROPOSED:

```
award = base_award × encounter_tier × obsolescence × catchup × repeat_decay
```

| Factor | Rule |
|---|---|
| `encounter_tier` | Raid Tier 3 pays 3× the Tier 1 base. Keeps one table for all tiers. |
| `obsolescence` | `0.25` if `encounter_tier < highest_unlocked_tier − 1`, else `1.0`. Stops the player farming Raid 1 for Legendary rank. |
| `catchup` | `2.0` while the stall flag is set (§8, M3), else `1.0`. Applies to **adventure** content only. |
| `repeat_decay` | §6.3 |

### 6.2a Which table the tier factor applies to — raids only

🔷 PROPOSED, resolved during implementation and recorded here because the formula
above reads as though it applies to everything ([15 BL-37](./15-open-questions.md)).

`encounter_tier` multiplies the **raid** table only. §6.1 labels that table "Tier 1
base awards"; the adventure table carries no such label and its values already climb
(25 → 50 → 75 → 100 → 125). §6.4's pacing table settles it in writing: it prices
**Adventure 2 at 50** — the §6.1 number unchanged — in the same table where every
raid row *is* multiplied (Raid 2 Enc 1-3 = 50 × 2 = 100). Applying the factor twice
would inflate Adventure 5 from 125 RP to 625 and break the pacing the whole table was
solved for.

The tutorial rows (Adventure 0, Tutorial Raid) are flat for the same reason.

**One Adventure, three board rungs.** [15 BL-24](./15-open-questions.md) makes one
board rung one encounter and [10 §8](./10-content-and-encounters.md) gives each
Adventure three, so §6.1's single figure splits **20 / 30 / 50** across them — the
proportions [11 §F2](./11-economy-and-crafting.md)'s gold payout already uses, so RP
and gold agree about which rung is the payoff. The split is computed from cumulative
shares so the three rungs sum to §6.1's total exactly: 25 → 5/7/13, 50 → 10/15/25,
75 → 15/22/38, 100 → 20/30/50, 125 → 25/37/63.

### 6.3 Diminishing returns on repeats

🔷 PROPOSED. **Why this exists:** farming must stay a viable slow path (it is the catch-up valve) without becoming the fast path.

```
repeat_rp(n) = max(1, floor(repeat_base / 2 ** floor((n - 2) / 5)))     # n = total clears, n >= 2
```

Repeat payout halves every 5 repeats and floors at 1 RP — never zero, so a stuck player always inches forward.

Worked example, Tier 1 Encounter 5 (`repeat_base = 13`):

| Clear # | RP each | Subtotal | Running total incl. first clear (65) |
|---|---|---|---|
| 1 (first) | 65 | 65 | 65 |
| 2–6 | 13 | 65 | 130 |
| 7–11 | 6 | 30 | 160 |
| 12–16 | 3 | 15 | 175 |
| 17–21 | 1 | 5 | 180 |
| 22+ | 1 | +1 each | floor |

Twenty repeat clears of the tier's hardest boss yield 115 RP — less than one first clear of the next tier's boss 5 (130 RP at Tier 2). Progression beats farming, but farming is never worthless.

### 6.4 Thresholds and pacing

🔷 PROPOSED thresholds:

| Rank | RP required | Cumulative RP band |
|---|---|---|
| Unknown | 0 | 0–119 |
| Known | 120 | 120–399 |
| Respected | 400 | 400–899 |
| Established | 900 | 900–1799 |
| Renowned | 1800 | 1800–3199 |
| Legendary | 3200 | 3200+ |

Expected pacing on a clean, no-farm run — this is the pacing the numbers in §6.1 were solved for:

| Milestone | RP | Cumulative | Rank after |
|---|---|---|---|
| Adventure 0 + Tutorial Raid + Adventure 1 | 40 | 40 | Unknown |
| Raid 1 — Enc 1, 2, 3 | 50 | 90 | Unknown |
| Raid 1 — Enc 4 | 35 | **125** | **Known** |
| Raid 1 — Enc 5 + full-clear bonus | 115 | 240 | Known |
| Adventure 2 | 50 | 290 | Known |
| Raid 2 (×2) — Enc 1–3 | 100 | 390 | Known |
| Raid 2 — Enc 4 | 70 | **460** | **Respected** |
| Raid 2 — Enc 5 + bonus | 230 | 690 | Respected |
| Adventure 3 | 75 | 765 | Respected |
| Raid 3 (×3) — Enc 1–2 | 75 | 840 | Respected |
| Raid 3 — Enc 3 | 75 | **915** | **Established** |
| Raid 3 — Enc 4, 5 + bonus | 450 | 1365 | Established |
| Adventure 4 | 100 | 1465 | Established |
| Raid 4 (×4) — Enc 1–3 | 200 | 1665 | Established |
| Raid 4 — Enc 4 | 140 | **1805** | **Renowned** |
| Raid 4 — Enc 5 + bonus | 460 | 2265 | Renowned |
| Adventure 5 | 125 | 2390 | Renowned |
| Raid 5 (×5) — Enc 1–4 | 425 | 2815 | Renowned |
| Raid 5 — Enc 5 + bonus | 575 | **3390** | **Legendary** |

**The pacing contract, in one line:** *one rank per raid tier, arriving at boss 3–4 of that tier* — so the reward for a tier lands while the player is still inside it, and the next tier unlocks before the current one is finished (no dead time between tiers). Legendary rank lands on the full clear of Raid 5, which means Legendary rank cannot gate content — see §7 and §11 Q5.

### 6.5 Can reputation be lost?

> ❓ **OPEN — canon never addresses this.** Canon does establish two failure events: at morale 0–10 a raider "may cause guild disband", and at 10–30 a raider "may leave guild."

🔷 PROPOSED — **the monotonic-rank rule**: *Guild Reputation rank never decreases.* RP may be deducted, but never below the floor of the current rank.

| Event | RP effect | Rationale |
|---|---|---|
| Raid wipe | **0** | The game is named after wiping. Canon's whole premise is that raiders make mistakes; taxing the fantasy is a design error. |
| A raider leaves the guild (canon: morale 10–30) | **0** | Already punished by losing the raider and their gear. |
| A guild-disband event (canon: morale 0–10) | **−10% of RP earned inside the current rank**, clamped to the rank floor | The one failure with real weight. Cannot demote. |
| Abandoning a raid mid-lockout | **0** | Encourages retreating instead of feeding a wipe. |
| Dismissing/firing a raider | **0** | Roster churn is a core verb. |

Why rank is monotonic: reputation gates recruit quality (§5), so a rank *loss* would hand a struggling player worse raiders — the exact death spiral named in §8. Making rank one-way removes that spiral's steepest edge by construction. "Falling behind" should mean stalling, never regressing.

---

## 7. What each rank gates — master table

🔷 PROPOSED except where marked. Recruit column is ✅ CANON per §5.3. Buildings column is 🔷 PROPOSED gating of ✅ CANON buildings — [02 — Town & Buildings](02-town-and-buildings.md) owns what each building *does*. Raid-tier gating implements ✅ CANON "New Tiers can be unlocked by gaining reputations with the town."

| Rank | Recruit tiers found | Town unlock | Content unlocked | Market stock | Sell price | Consumable price |
|---|---|---|---|---|---|---|
| Unknown | Common only ✅ | Guildhall, Tavern, Market, Adventure's Board (all present at start) | Adventure 0, Tutorial Raid, Adventure 1, Raid 1 | Minor potions | 40% of item value | 100% |
| Known | Common, Uncommon ✅ | Guildhall facility upgrade I; Quest/achievement board | Adventure 2, Raid 2 | + Lesser potions | 45% | 100% |
| Respected | Uncommon, Rare ✅ | Tavern L3 ([02 §11](02-town-and-buildings.md)); the Blacksmith is post-1.0 ([15 Q-13](15-open-questions.md#q-13)) | Adventure 3, Raid 3 | + Standard potions (crafting supplies are post-1.0 with the Blacksmith) | 50% | 95% |
| Established | Uncommon, Rare (Rare modal) ✅ RULED Q-22 | Guildhall facility upgrade II (L3) and Market expansion (L4) open for purchase — `reputation.json`'s Established `town_unlock`; Blacksmith tier 2 only if Q-13 ever ships the building | Adventure 4, Raid 4 | + Greater potions | 55% | 90% |
| Renowned | Rare, Epic, Legendary ✅ | Guildhall facility upgrade III; Tavern expansion (larger recruit pool — doc 04) | Adventure 5, Raid 5 | + Major potions | 60% | 85% |
| Legendary | Epic, Legendary ✅ RULED Q-22 | Perfect potions; Legendary raiders, one in twenty (`stock_tier 6`, `find_weights … 50`) — the phantom "Guildhall facility upgrade IV" is struck: the ladder ends at L4 = Renowned's III | The 9-of-9 Legendary collection ([15 BL-122](15-open-questions.md#bl-122)); canon's content list ends at Raid 5 with "This continues" and 1.0's ladder ends there ([BL-121](15-open-questions.md#bl-121)) | + Perfect potions | 65% | 80% |

Notes on this table:

- ✅ CANON building list: Guildhall, Tavern, Market, Blacksmith (Maybe), Adventure's Board. No other buildings are canon; do not add any here.
- ✅ CANON: "Upgrade guild facilities < better morale values" — the Guildhall upgrade rungs above are the rank-gated delivery of that. Doc 02 owns the morale values.
- 🔷 PROPOSED: the four core buildings are all open at Unknown because canon's "Core things to do" loop (earn money → spend at blacksmith/merchant → recruit at tavern → take missions → improve the guild) requires all of them from minute one. Only the Blacksmith is gated, because canon itself marks it optional.
- Sell-price and consumable-price columns are 🔷 PROPOSED *shapes*; [11 — Economy & Crafting](11-economy-and-crafting.md) owns the real numbers. Potion tier names are 🔷 PROPOSED placeholders — canon says only "Buy consumables (Potions)".
- Content unlock ladder is 🔷 PROPOSED. Canon's ordering (Adventure N then Raid N) is ✅ CANON but canon explicitly flags the order as provisional: "This continues or can go raid raid, adventure adventure, obviously they will need names later, but this is a placeholder."

---

## 8. The design risk: the Recruit Quality Spiral

🔷 PROPOSED analysis. **Why this exists:** the mechanism canon specifies has a structural failure mode that must be named before it is built, not after playtest.

**The failure mode.** Reputation gates recruit quality. Recruit quality determines mistake rate. Mistake rate determines whether you clear content. Clearing content is the only source of reputation. So:

```
fall behind → lower rank than the content needs → worse recruits
           → more mistakes → fail the content → no reputation → fall further behind
```

This is a positive feedback loop on failure. It is worst at the rank boundaries, and worst of all for a player who reaches Raid 3 (which our pacing expects to be run by Rare-modal raiders at Established) while still stuck at Respected with an Uncommon-modal pool.

Three properties make it dangerous specifically here:

| Property | Consequence |
|---|---|
| Rarity is permanent | A Common raider cannot be trained into a Rare one — canon's Guildhall "Train raiders" line is itself marked "Maybe if we have level ups" ❓ |
| Morale cannot compensate | ✅ CANON: mistake values stay "within tier limits … based on their tier." A perfectly happy Common still misses ~14% of the time — [05 — Morale](05-morale.md) §5.4's band-9 value, against a floor of 12% |
| Reputation has one source | Raids and adventures. If you cannot clear them you have no other tap |

### 8.1 Mitigations

🔷 PROPOSED. Ship **M1 + M2**; keep **M3** behind a config flag and enable it if telemetry shows stalls.

| ID | Mitigation | Spec | Cost |
|---|---|---|---|
| **M1** | **Modal-tier floor** | Every Tavern refresh guarantees **at least one** recruit at the rank's modal tier (bold cells in §5.2). Implementation: generate the pool, then if no recruit is at-or-above the modal tier, force-reroll the lowest one at the modal tier. | Removes the "all four recruits are Uncommon at Established" run of bad luck. Cheap, invisible, no new UI. |
| **M2** | **Pity timer on Rare-and-above** | A save-persistent counter `pity`. Increment on every generated recruit below Rare; reset to 0 on any Rare-or-better. When `pity >= 25`, the next recruit is forced to Rare or better (pick from that rank's row with sub-Rare weights zeroed). Active from **Respected** onward, since Rare does not exist before then. | Worst case at Respected: 25 recruits ≈ 7 refreshes for a guaranteed Rare. Expected case is unaffected (35% natural rate hits far sooner). |
| **M3** | **Adventure catch-up reputation** | Set a `stalled` flag when the player has **attempted the same raid encounter 5+ times without clearing it**. While set, adventure content pays `catchup = 2.0` (§6.2). Clear the flag on the player's next raid first-clear. | A stuck player can grind adventures — content their current roster *can* beat — into the next rank, then return with better recruits. Chosen over an RP-curve comparison because "attempted 5× and failed" measures being stuck directly, needs no expected-progress table, and cannot be gamed by skipping content. |

### 8.2 Why the monotonic-rank rule is the fourth mitigation

§6.5's rule that rank never decreases is load-bearing here, not just a kindness. With rank loss, a disband cascade could drop a player from Established to Respected and hand them strictly worse raiders for content they had already unlocked — the spiral's steepest possible slope. Making rank one-way means the floor under a struggling player only ever rises.

### 8.3 Telemetry to instrument before ship

| Metric | Why | Alarm threshold |
|---|---|---|
| Attempts-per-first-clear, per encounter | Detects the spiral forming | > 6 attempts median |
| Time (real minutes) spent at each rank | Detects a dead rank — especially **Established**, whose whole row is our invention | > 2× the median of neighbouring ranks |
| Recruits generated per Rare-or-better acquired | Validates M2's threshold of 25 | > 20 median at Respected |
| % of saves that reach each rank | Funnel | < 40% reaching Established |
| M3 flag activation rate | Is the catch-up path actually used | — |
| Legendary acquisitions per save by rank | Validates the 15 / 50 per-mille split | < 2 Legendaries by Raid 5 clear |

---

## 9. Data shape for implementation

🔷 PROPOSED — one data file so design can tune without a code change. JSON rather than `.tres`, because [14 §5.1](14-technical-architecture.md)'s deciding row is "readable by `sim/` without breaking §3" and `.tres` needs `ResourceLoader`, which `sim/` may not call ([15 BL-81](15-open-questions.md#bl-81)).

```
res://data/reputation.json
  schema_version: int = 1
  ranks: Array                       # one row per canon rank, IN LADDER ORDER:
                                     #   key: String                 (matches Enums.REPUTATION_KEYS[i])
                                     #   rp_threshold: int           (§6.4)
                                     #   find_weights: Array[int]    (§5.2, 5 ints, sum 1000)
                                     #   max_raid_tier: int          (§7)
                                     #   max_adventure: int          (§7)
                                     #   sell_rate: float            (§7, a fraction)
                                     #   consumable_price: float     (§7, a multiplier)
                                     #   stock_tier: int             (§7, the potion rung)
                                     #   town_unlock: String         (§7, prose — see 15 BL-81)
                                     #   market_stock: String        (§7, prose)
  raid_awards: Dictionary            # slot "E1".."E5" -> [first, repeat]; TIER 1 BASES, §6.2 multiplies
  full_tier_bonus: Array[int]        # [first, repeat] — the pair BL-35 kept
  adventure_awards: Dictionary       # adventure tier "1".."5" -> [first, repeat]; ALREADY TIER-FINAL
  tutorial_awards: Dictionary        # slot "A0"/"TR" -> [first, repeat]
  rung_cumulative: Dictionary        # rung "A1".."A3" -> [lo, hi] cumulative share (BL-24, BL-37)
  repeat_halving_period: int = 5
  obsolescence_mult: float = 0.25
  catchup_mult: float = 2.0
  catchup_enabled: bool = true       # §8.1 M3's config flag (BL-36)
  stall_attempts: int = 5            # §8.1 M3's trigger
  pity_threshold: int = 25           # §8.1 M2
  pity_min_rank: int = 2             # §8.1 M2's other half — Respected
  disband_rp_penalty: float = 0.10   # §6.5, a FRACTION (the `_pct` suffix is dropped)

Keys beginning with `_` are provenance and are ignored by the loader. JSON has no
comments and these numbers are not defensible without their citations.
```

The shape above is the shipped file, not the original proposal: six of the first draft's keys (an id-list content gate, a `market` sub-block with `_pct` names, one `awards` dictionary, a scalar full-clear bonus, no `stall_attempts` / `catchup_enabled`, half of M2's pity rule) stopped describing the code once §6.2a, [15 BL-35](15-open-questions.md#bl-35) and [15 BL-37](15-open-questions.md#bl-37) landed. [15 BL-81](15-open-questions.md#bl-81) records each divergence and why the file wins, why `town_unlock` / `market_stock` stay prose, and what the file deliberately does not carry (doc 04's cost and experience tables).

Assertions to run on load: every `find_weights` row sums to 1000; thresholds are strictly increasing; no rank reintroduces a tier a lower rank had at 0 after retiring it (guards C4 and C8 against a bad tuning pass); and the ladder has exactly one row per canon rank, in the enum's order — a dropped row would silently shorten the ladder and clamp every rank above the gap to the wrong gate. All four are implemented at `sim/core/Reputation.gd::validate()` and each is a collected error naming the rank, never a crash. A key-parity test (audit `M3-TUNE-02` (3)) reads the fence above out of this section and holds it against the file in both directions, so a lever added to one has to be written into the other.

---

## 10. Worked scenario — one player, three ranks

🔷 PROPOSED illustration, using the tables above end to end.

The guild has cleared Raid 1 fully and Adventure 2 → 290 RP → **Known**. Recruit pool of 4 at the Tavern: weights 700/300 → expected 2.8 Common, 1.2 Uncommon. M1 guarantees at least one Uncommon (Known's modal is Common, so M1 is inert here — flagged as §11 Q7). The Uncommon arrives with `randi(1,2)` pieces of Tier 1 Adventure armour, e.g. *Iron Adventurer's Cuirass* (5 AC / +6 HP) and *Iron Adventurer's Boots* (3 AC / +3 HP), with the Worn starting set filling Head and Legs.

They clear Raid 2 bosses 1–4 → 460 RP → **Respected**. Common stops appearing entirely (C4). The next refresh rolls 650/350: expected 2.6 Uncommon, 1.4 Rare. `pity` begins counting.

They stall on Raid 2 boss 5 — 5 failed attempts sets the `stalled` flag. Adventure 3 now pays `75 × 2.0 = 150` RP instead of 75, taking them to 840. Two repeat clears of Raid 2 Encounter 4 (`repeat_base 7 × tier 2 = 14` each) add 28 → 868. Adventure 2 repeats (`10 × 1 = 10`, obsolescence inert since Tier 2 is highest unlocked) close the last 32 → **900 → Established**. Rare is now modal at 650: the next pool of 4 expects 2.6 Rare, and the boss 5 wall gets substantially easier. This is M3 working exactly as intended.

---

## 11. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| 1 | Canon: Uncommon raiders arrive with "1-2 pieces of basic **adventure** gear from your current **raid** tier." Does this mean the Adventure gear of the tier the player is currently raiding (ideaboard §2), or Raid gear? | Decides which of two canon stat tables the recruit generator reads. Adventure Tier 1 Warrior armour totals 15 AC; Raid Tier 1 totals ~21 AC + Power. | Adventure gear of the tier currently unlocked. §4.1 is built on this reading. |
| 2 | **Established and Legendary rank recruit effects — canon is entirely silent.** Is §5.4's pattern-derived fill (Established = Rare becomes modal; Legendary = Rare retires, Epic becomes modal, Legendary rises to 5%) correct? | Two of six matrix rows are ours. One full raid tier is spent at Established. Doc 04 cannot build the Tavern until this is signed off. | Ship §5.4's default; alternates listed there are one-line swaps. |
| 3 | What is the actual Legendary **find chance** at Renowned? Canon says "VERY SMALL" and gives no number. The nearby "near 1% chance of mistake" is about the raider's mistake rate, not the find rate. | Implementing 1% as a find chance is the single most likely misreading of canon. At 1.5% a Legendary takes ~67 recruits; at 0.5% it takes ~200 and most players never see one. | 1.5% (15 per-mille) at Renowned, 5% at Legendary rank. |
| 4 | Does Common still appear at Known, and at what rate? Canon states Common stops at Respected but never states its Known rate. | Sets the whole feel of the early game. At 700 the player is still mostly recruiting garbage at Known; at 400 Known feels like a real upgrade. | 700 Common / 300 Uncommon. |
| 5 | Legendary rank gates no content under §6.4's pacing (it lands on the Raid 5 full clear, and canon's content list ends there with "This continues"). Is Legendary a *content* rank or a *prestige* rank? | Determines whether Tier 6+ content must exist for the ladder to make sense, or whether Legendary's payoff is recruit quality plus town flourish. | Prestige rank: recruit quality, max Guildhall facilities, Market top tier. Revisit when post-Raid-5 content is designed. |
| 6 | If a Legendary raider leaves the guild or is dismissed, are they re-findable? Canon's "only ever find 1 Legendary per class" addresses finding, not losing. | Losing Natsuna permanently is a strong, memorable consequence; it is also potentially save-ruining given Legendaries are one-per-class-forever. | Gone for good, but Legendaries are canon-hard to upset ("will not be bothered by many things easily"), so this should require deliberate player negligence. |
| 7 | At Unknown and Known the modal tier is Common, so M1's modal-tier floor does nothing. Should M1 instead guarantee the *best available* tier from Known onward? | Without it, a Known player can roll 4 Commons repeatedly (24% chance per refresh at 700/300) and feel no rank-up at all. | Yes: from Known onward M1 guarantees at least one recruit **above** the floor tier of that rank, not merely at the modal tier. |
| 8 | Is the Blacksmith rank-gated at all? Canon marks the whole building "Maybe", and marks crafting and salvaging "Maybe"/"If we do crafting". | If the Blacksmith is cut, Respected loses its town unlock and needs a replacement, or the ladder has a hole at rank 3. | Blacksmith opens at Respected if it ships; if cut, Respected instead unlocks the Tavern expansion (moved down from Renowned). |
| 9 | Is "Natsuna" a final name? Canon writes "IE Natsuna(the shaman) **or something**." | Affects whether art and VO can start on the Shaman Legendary. | Treat Natsuna as canon-locked for the Shaman (it appears twice in canon, including the example roster at 87 morale); the other 8 names are pending. |
| 10 | ~~Do the 🔷 PROPOSED base mistake chances in §4.2 belong in doc 05, and are the bands acceptable?~~ ANSWERED ([15 Q-04](15-open-questions.md#q-04)): [08 §8.8](08-stats-and-formulas.md) owns the numbers; §4.2 is a cross-reference | They are the only thing that makes "recruit quality" mean something. | §4.2 is a cross-reference; doc 08 owns the numbers. Only the Legendary 1% row is canon-anchored. |
| 11 | Does the disband event's RP penalty (§6.5) survive playtest, or should failure cost zero reputation across the board? | The only reputation loss in the design. Zero-loss is safest against the spiral but leaves disbanding toothless. | Keep the −10%-within-rank penalty, clamped so it can never demote. Cut it if telemetry shows it correlates with churn. |

---

## Related documents

- [02 — Town & Buildings](02-town-and-buildings.md) — what each building rank-gated in §7 actually does, and the Guildhall facility upgrade tiers that carry canon's "better morale values."
- [04 — Recruitment & Roster](04-recruitment-and-roster.md) — the Tavern: recruit pool size, refresh cadence, class weighting, recruit cost, and backstories. Consumes §5's matrix; does not restate it.
- [05 — Morale](05-morale.md) — the 0–100 morale bands and the mistake-chance formula that §4.2's per-tier bands feed into.
- [10 — Content & Encounters](10-content-and-encounters.md) — the five-encounter structure and difficulty stars that §6.1's RP awards are keyed to.
- [11 — Economy & Crafting](11-economy-and-crafting.md) — the real gold values behind §7's sell-price and consumable-price columns.
- [14 — Technical Architecture](14-technical-architecture.md) — where the §9 resource file lives and how it is hot-reloaded for tuning.
