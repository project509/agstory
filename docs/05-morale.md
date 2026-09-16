# 05 — Morale

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs the single 0-100 morale value carried by every raider — its bands, its effect on mistake chance, what raises and lowers it, and when a raider leaves or the guild disbands.

---

## 1. Scope

**This doc owns:**

| Owns | Detail |
|---|---|
| The morale value | Storage, range, clamping, band lookup, baseline, drift |
| The canon band table | Reproduced exactly, plus the resolution of its two ambiguities |
| Morale → mistake chance: the band side only | The ten bands and the `band_delta` per band (§5.2). The equation and every other coefficient are [08 §8.8](08-stats-and-formulas.md)'s ([15 Q-04](15-open-questions.md#q-04)) |
| Morale sources | Every trigger that changes morale, its delta, its cap and its cooldown |
| Rarity resilience | How rarity scales incoming morale change and drift |
| Leave / disband checks | When evaluated, probability, warning escalation, hard safety rules |
| Wishlist / BiS module | Generation, surfacing, morale bonus (canon calls this a concept) |
| The roster display contract | The exact two-line format canon shows, and the emoji/state mapping |

**This doc does NOT own:**

| Not owned | Owner |
|---|---|
| The mistake-chance equation and its coefficients (base, sensitivity, floor, ceiling, situational cap, site weights) | [08 §8.8](08-stats-and-formulas.md) — this doc supplies the band, doc 08 converts it |
| How mistake chance resolves into a combat event (what a "mistake" *does*) | [08 — Stats & Formulas](08-stats-and-formulas.md) |
| How many mistake checks an encounter rolls per raider | [08 — Stats & Formulas](08-stats-and-formulas.md) |
| Item stat blocks and drop tables that wishlists are generated from | [09 — Items & Itemization](09-items-and-itemization.md) |
| Raider rarity distribution, backstories, recruitment | [04 — Recruitment & Roster](04-recruitment-and-roster.md) |
| Guildhall comfort items and facility upgrade costs / tiers | [02 — Town & Buildings](02-town-and-buildings.md) |
| The morale face sheet and the colour ramp's source palette | [12 — Art Direction](12-art-direction.md) |
| Screen layout of the roster row, and the colour-blind checks §10.3 defers | [13 — UI/UX](13-ui-ux.md) |

> Sibling filenames above are the canonical set in [00 §1.1](00-vision-and-pillars.md). The "13 — Art Direction & UI" this table used to name is two documents: doc 12 owns the sprite sheet and the palette (00 §1.1), doc 13 owns the ramp's application on screen ([13 §16](13-ui-ux.md) OQ-10).

---

## 2. The canon band table, reproduced exactly

✅ CANON — reproduced verbatim from the source table, including its duplicated state name and its overlapping boundaries. Nothing here is corrected. (canon: raw notes, "Morale: 0-100")

> Every raider has a single morale value.

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

Two further canon statements bind this table:

- ✅ CANON: "All values above are have within tier limits for mistakes based on their tier -" (canon: raw notes, Morale section — quoted with its typo intact). Read as: the band multiplier scales a **per-rarity base**, and the result is clamped so a raider never leaves its rarity's mistake range. Section 5 implements this.
- ✅ CANON: "the morale system itself stays extremely simple: one number, one state, one effect. The complexity comes from the stories and decisions surrounding it." (canon: raw notes, Morale section). This is a design constraint on this doc: no second morale bar, no per-raider mood sub-stats, no hidden loyalty counter.

---

## 3. The two canon quirks

### 3.1 ❓ OPEN — 70-80 and 80-90 are both named "Very Happy"

Canon, quoted from both sides:

| Band | Canon state |
|---|---|
| 70-80 | "Very Happy" |
| 80-90 | "Very Happy" |

Two bands with identical names cannot both be displayed, sorted, or logged unambiguously.

🔷 PROPOSED resolution — **rename 70-80, keep 80-90 as "Very Happy".** The tiebreaker is canon's own sample roster: "Natsuna — 87 ❤️ / Shaman — Very Happy" (canon: raw notes, example roster). 87 falls in 80-90, so 80-90 must be the band called "Very Happy" if the roster example is to stay correct.

| Band | Canon name | 🔷 PROPOSED name | Notes |
|---|---|---|---|
| 70-80 | Very Happy | **Quite Happy** | Renamed. Alternatives if rejected: "Really Happy", "Delighted" |
| 80-90 | Very Happy | **Very Happy** | Unchanged — locked by the Natsuna 87 example |

The implementation needs an unambiguous rule: **band state names must be unique**, because state name is a display string, a save-file token and a telemetry key. Until this is signed off, code should key off a band index (0-9), never the display name.

**"Quite Happy" is provisional wherever it appears.** This doc uses the proposed name in four downstream tables — §3.2, §5.2, §5.4 and §10.2 — for readability; every one of those uses is 🔷 PROPOSED and reverts to canon's "Very Happy" if the rename is rejected. Band **7** is the stable key in all four places.

**Blocked on one designer ruling, because four docs currently disagree:**

| Doc | Position today | Once signed off |
|---|---|---|
| This doc §3.1 | 🔷 Rename 70-80 to "Quite Happy" | Becomes ✅ CANON-adjacent (a signed-off resolution of a canon defect) |
| [00 — Vision & Pillars](00-vision-and-pillars.md) Q6 | "❓ OPEN — do not fix … must not silently rename it" | Records the ruling; the rename here is flagged, not silent |
| [04 — Recruitment & Roster](04-recruitment-and-roster.md) Q2 | "treat 70-90 as one displayed state with two internal steps" | Cite §3.1 instead — one displayed state re-creates the ambiguity in the UI |
| [13 — UI/UX](13-ui-ux.md) §8.3 | Renders bands 7 and 8 both as "Very Happy" | Band-7 State cell becomes "Quite Happy" (its OQ-1 already says it follows this doc) |

Nothing outside §3.1 may resolve this. If the designer rejects the rename, delete the five provisional uses above and key display off the band index alone.

### 3.2 ❓ OPEN — the band boundaries overlap at every tens value

As written, `0-10`, `10-20`, `20-30`, … `90-100`. The value 10 belongs to two bands, as do 20, 30, 40, 50, 60, 70, 80 and 90. There is no canon statement resolving this.

🔷 PROPOSED resolution — **half-open intervals `[lower, upper)`, with the top band closed to include 100.**

| Band index | Interval | State (post-3.1) |
|---|---|---|
| 0 | [0, 10) | Very Upset |
| 1 | [10, 20) | Upset |
| 2 | [20, 30) | Unhappy |
| 3 | [30, 40) | Annoyed |
| 4 | [40, 50) | Slightly Annoyed |
| 5 | [50, 60) | Content |
| 6 | [60, 70) | Happy |
| 7 | [70, 80) | Quite Happy |
| 8 | [80, 90) | Very Happy |
| 9 | [90, 100] | Loves Their Guild |

Reference implementation: `band_index = min(9, floor(morale / 10))`.

**Validation against the canon roster** — the half-open rule reproduces all four canon rows exactly:

| Canon row | Value | band_index | Band | Canon state | Match |
|---|---|---|---|---|---|
| Natsuna | 87 | 8 | [80, 90) | Very Happy | ✅ |
| Bob | 54 | 5 | [50, 60) | Content | ✅ |
| Greg | 31 | 3 | [30, 40) | Annoyed | ✅ |
| Steve | 14 | 1 | [10, 20) | Upset | ✅ |

This is the strongest available evidence for half-open over any other reading, and it costs nothing: no canon value moves band.

---

## 4. Data model and tick definitions 🔷 PROPOSED

**Why this exists:** the rest of the doc references a clock and a stored value; both need one definition.

| Field | Type | Range | Notes |
|---|---|---|---|
| `morale` | float, displayed as rounded int | 0.0 – 100.0, hard clamped | Stored as float so sub-1 drift accumulates |
| `baseline` | int | 20 – 80 | The value drift pulls toward (§8) |
| `band_index` | derived int | 0 – 9 | Never stored; always derived (§3.2) |
| `at_risk_strikes` | int | 0 – 99 | Consecutive Day Ticks spent in band 0-2 (§6) |
| `crisis_strikes` | int | 0 – 99 | Consecutive Day Ticks the guild has met crisis conditions (§6.3) |
| `wishlist` | array of item ids | 0 – 2 entries | §9, optional module |

**Day Tick** 🔷 PROPOSED — one advance of the town clock. It fires when the player resolves an Adventure or Raid attempt, or explicitly rests in town. All drift, leave checks and disband checks are evaluated **once per Day Tick, after all event-driven morale deltas for that tick have applied**. Order matters: never roll a leave check against a mid-update value.

❓ OPEN: whether the game has a day clock at all is not stated in canon. [02 — Town & Buildings](02-town-and-buildings.md) owns the clock; if it lands on "time only passes when you raid", every "per Day Tick" number here reads as "per raid attempt" and the drift values in §7 want roughly a 1.5× increase.

**Starting morale** 🔷 PROPOSED — a newly recruited raider starts at `baseline` (§8), not at 50. This makes rarity legible on the recruit screen: a Common walks in at 45, a Legendary at 62.

---

## 5. Effects, made numeric 🔷 PROPOSED

**Why this exists:** canon gives directions ("increased", "reduced") but exactly one number — "near 1% chance of mistake" for Legendaries (canon: raw notes, Guild Reputation, @renowned). A programmer cannot ship adjectives.

### 5.1 The formula

**Owned by [08 §8.8](08-stats-and-formulas.md)** — ✅ RULED, [15 Q-04 / Q-05](15-open-questions.md#q-04) (2026-09-15, W7-DOCS; audit DW-D1/DW-D2). Doc 08 publishes the equation once, in basis points, with every coefficient — `MISTAKE_BASE_BP`, `MISTAKE_SENSITIVITY`, `MISTAKE_FLOOR_BP`, `MISTAKE_CEIL_BP`, `SITUATIONAL_CAP_BP`, `ROLL_SITE_WEIGHT` — and `tests/unit/test_canon_guard.gd` holds its tables equal to `sim/core/Formulas.gd`. The shape doc 08 adopted is the one this section proposed, `base[rarity] × (1 + band_delta[band] × sensitivity[rarity])`, clamped per rarity; its three properties (a per-rarity base, a sensitivity that compresses the curve as rarity rises, hard clamps that make "within tier limits" testable) are stated there. This doc contributes one input to it, the band (§5.2), and prints no second copy of the rest.

### 5.2 Band delta (morale side of the curve)

This is the one table this doc owns for the mistake curve: doc 08 §8.8 imports it unchanged as `Formulas.MORALE_BAND_DELTA`, and the canon guard holds the two equal.

| Band | State | `band_delta` | Direction (canon) |
|---|---|---|---|
| 0 | Very Upset | +2.00 | Very high mistake chance |
| 1 | Upset | +1.40 | Increased |
| 2 | Unhappy | +0.90 | Increased |
| 3 | Annoyed | +0.50 | Noticeably higher |
| 4 | Slightly Annoyed | +0.20 | Slightly increased |
| 5 | Content | 0.00 | Base |
| 6 | Happy | −0.12 | Reduced |
| 7 | Quite Happy | −0.22 | Further reduced |
| 8 | Very Happy | −0.30 | Further reduced |
| 9 | Loves Their Guild | −0.35 | Lowest |

The curve is deliberately asymmetric: the punishment side has roughly 6× the range of the reward side. Falling apart is dramatic; being adored is a modest, reliable edge. That matches a game whose premise is that these people are bad at this — the drama has to live on the failure side. Do not tune by editing `band_delta` for a single mid band; it breaks monotonicity, and monotonicity is the one property canon's table asserts.

### 5.3 Per-rarity base, sensitivity and clamps

See [08 §8.8](08-stats-and-formulas.md)'s coefficient table. Rarity names are ✅ CANON (canon: raw notes, Guild Reputation — "Common raiders", "uncommon raiders", "rare raiders", "epic raiders", "Legendary raiders"); the five numeric columns this section used to print were adopted by doc 08 as its own and are published there once. Docs 02, 03 and 04, which once carried their own copies, point at the same section.

### 5.4 The effective mistake-chance matrix

See [08 §8.8](08-stats-and-formulas.md)'s matrix (rarity × band, ten rows). The readings below quote it.

### 5.5 Sanity check against the canon anchor

| Check | Result (08 §8.8's matrix) | Verdict |
|---|---|---|
| Legendary at 90-100 vs canon "near 1%" | 0.99% | ✅ On the nose |
| Legendary across all ten bands | 0.99% – 2.40% | A furious Legendary is still elite |
| Legendary worst (2.40%) vs Common best (13.9%) | 5.8× better | ✅ Satisfies "within tier limits" |
| Legendary worst (2.40%) vs Epic best (2.6%) | Legendary still better | Legendary is strictly dominant everywhere |
| Epic worst (8.4%) vs Rare best (5.5%) | Overlaps | See below |
| Common at 0-10 | 81.6% | Intentionally catastrophic — do not bring this raider |

**Adjacent-tier overlap is intentional and is now the ruling** ([15 Q-08](15-open-questions.md#q-08), [BL-20](15-open-questions.md#bl-20)). Legendary is strictly better than every other rarity in every morale state. Below Legendary, a miserable raider of tier N can be worse than a beloved raider of tier N−1 (a Very Upset Epic at 8.4% is worse than a Loves-Their-Guild Rare at 5.5%). That is what makes morale a real decision rather than a cosmetic. Removing the overlap would require flattening the curve for low rarities, which directly contradicts canon's "lower tier raiders will be hardest to keep happy"; doc 08's earlier "one step, never two" guarantee was given up for this reading (§12 Q3 is answered).

### 5.6 Tuning levers

Deleted — the levers live in [08 §11](08-stats-and-formulas.md) beside every other knob (they were a duplicate). The one rule that stays here: never edit one mid band of §5.2.

### 5.7 Handoff to doc 08

This doc produces one number per raider: the **morale band** (§2, §5.2). [08 §8.8](08-stats-and-formulas.md) converts it into a mistake chance and owns the equation, its base, sensitivity, floor, ceiling, situational cap and roll-site weights; this doc holds no copy of any of them. Doc 08 also owns everything downstream — how many checks are rolled and where ([07 §5.3](07-combat-simulation.md)'s three sites), what a mistake does, whether gear, potions or facilities modify the roll, and how mistakes cascade into a wipe. If doc 08 needs a second morale-derived input (for example a "panic" modifier during a wipe), it is requested here so morale stays one number.

---

## 6. Leaving and disbanding

### 6.1 The canon gates

✅ CANON (canon: raw notes, morale table):

| Band | Canon text | Consequence |
|---|---|---|
| 0-10 | "may cause guild disband" | Run-ending event possible |
| 10-20 | "may leave guild" | Raider departure possible |
| 20-30 | "may leave guild" | Raider departure possible |
| 30-40 | "Won't leave" | Departure impossible — a hard floor, not a low probability |
| 40-100 | (not mentioned) | Departure impossible |

✅ CANON, and it constrains the tuning: "Meaning you wont have to worry about losing your higher tier raiders unless you are BIG dumb" (canon: raw notes, Morale section).

### 6.2 The leave check 🔷 PROPOSED

**Why this exists:** canon says "may". A programmer needs when, how often, and how likely.

**When:** once per Day Tick, after all deltas for that tick have applied, evaluated per raider in roster order. A raider who leaves is removed before the next raider is checked (their departure feeds §7's "another raider leaves" delta on the following tick, never the same tick — no same-tick cascade).

```
p_leave = leave_rate[band] * leave_resilience[rarity]
```

| Band | State | `leave_rate` per Day Tick |
|---|---|---|
| 0 | Very Upset | 0.22 |
| 1 | Upset | 0.14 |
| 2 | Unhappy | 0.05 |
| 3-9 | Annoyed and above | 0.00 (hard zero, per canon "Won't leave") |

| Rarity | `leave_resilience` | Effective p_leave at Upset |
|---|---|---|
| Common | 1.30 | 18.2% |
| Uncommon | 1.10 | 15.4% |
| Rare | 0.85 | 11.9% |
| Epic | 0.55 | 7.7% |
| Legendary | 0.25 | 3.5% |

Worked expectation: a Common left at 14 morale departs within 4 Day Ticks about 55% of the time (1 − 0.818⁴). A Legendary at the same value departs within 4 ticks about 13% of the time — recoverable if the player reacts, which is what "unless you are BIG dumb" asks for.

**Hard rules:**

| Rule | Reason |
|---|---|
| A raider cannot leave on the same Day Tick they first entered band 0-2 | The player must get one tick to react |
| A raider cannot leave while `at_risk_strikes == 0` | Warning always precedes departure |
| A raider mid-raid never leaves | Departure resolves in town only |
| The last raider of a class flagged required by an unlocked raid still leaves | No plot armor; the player must recruit at the Tavern |

**Warning UX for departure:**

| `at_risk_strikes` | Roster row | Elsewhere |
|---|---|---|
| 1 | Amber left border, state word in amber | Tavern shows a rumour line about this raider |
| 2 | Red border + "AT RISK" tag beside the emoji | Non-blocking toast on entering town |
| 3+ | Red border, "MAY LEAVE" tag, row pinned to top of roster | Blocking confirm on starting a raid without addressing it |

### 6.3 Guild disband 🔷 PROPOSED

Canon attaches "may cause guild disband" to a **per-raider** band, but disbanding is a **guild-level, run-ending** event. That mismatch is a real canon ambiguity (§12 Q4). The proposal below treats a single raider at 0-10 as a *necessary* condition, not a sufficient one, because a run-ender that can fire off one bad raider is a rage-quit generator.

**Crisis conditions — all three must hold on the same Day Tick:**

| # | Condition |
|---|---|
| A | At least one raider is in band 0 (Very Upset, morale < 10) |
| B | Guild average morale across the full roster is below 25 |
| C | `crisis_strikes >= 3` (the three conditions have already held for two prior ticks) |

`crisis_strikes` increments on any tick where A and B both hold, and **resets to 0** on any tick where either fails.

**Disband probability, escalating:**

| `crisis_strikes` | p_disband on that tick | State shown to the player |
|---|---|---|
| 1 | 0% | "GUILD UNSTABLE" |
| 2 | 0% | "GUILD IN CRISIS" |
| 3 | 8% | "GUILD COLLAPSING" |
| 4 | 18% | "GUILD COLLAPSING" |
| 5+ | 30% (flat) | "GUILD COLLAPSING" |

**Absolute rule — disband can never fire without prior warning.** Enforced structurally, not by convention:

| Guarantee | Mechanism |
|---|---|
| At least two full Day Ticks of escalating warning before any roll | `crisis_strikes >= 3` gate, with 0% at strikes 1-2 |
| The warning is unmissable | Strike 2 raises a modal the player must acknowledge, listing every raider in band 0-1 and the specific actions available (comfort item, bench, facility upgrade, disband-them-yourself) |
| The warning names the number | The modal states the actual p_disband for the next tick |
| No disband during onboarding | Disabled until the player has completed Adventure 0 and the Tutorial Raid (canon: raw notes, Adventure's Board) |
| No silent state | If `crisis_strikes >= 1`, a persistent header banner is present on every town screen |
| Save-scummable | Autosave on entering town each Day Tick, before the roll |

**❓ OPEN:** whether disband ends the run outright or is a recoverable catastrophe. Canon says only "may cause guild disband". Proposed default in §12 Q5. Reputation is **not** this doc's to spend: [03 — Guild Reputation](03-guild-reputation.md) §6.5 owns the consequence and its monotonic-rank rule (rank never decreases; a disband costs −10% of RP earned inside the current rank, clamped to the rank floor). This doc fires the event and wipes the roster; doc 03 applies the RP penalty.

---

## 7. Morale sources 🔷 PROPOSED

**Why this exists:** canon names three sources (comfort items, facility upgrades, wishlist items) and says the rest comes from backstories. A build needs the full trigger list with caps, or morale becomes farmable and every raider parks at 100.

All deltas below are **pre-resilience**; §8 scales them per rarity. Deltas apply immediately; drift and checks resolve at tick end.

### 7.1 Raid outcomes

| Trigger | Delta | Cap / cooldown |
|---|---|---|
| Raid or Adventure cleared, raider participated | +6 | Once per encounter-set per Day Tick |
| Boss defeated for the first time ever, raider participated | +10 | Once per boss per raider, permanently |
| Wipe, raider participated | −8 | Max −16 per raid attempt session |
| Wipe directly caused by this raider's mistake | −4 additional | Once per attempt |
| Raider knocked out during a clear | −3 | Max −6 per attempt |
| Cleared an encounter that previously wiped the guild | +3 | Once per encounter per raider |

There is no tutorial exemption: a wiped Tutorial Raid pays the wipe row and the culprit's −4 like any wipe ([15 BL-112](15-open-questions.md#bl-112) — a wipe that costs nothing would teach that wipes cost nothing). The culprit rule itself is [BL-107](15-open-questions.md#bl-107)'s.

### 7.2 Roster decisions

| Trigger | Delta | Cap / cooldown |
|---|---|---|
| Brought on a raid | +3 | Once per Day Tick |
| Benched while healthy and the raid ran | −2 | Only from the 2nd consecutive benched tick; max −6 per 7 ticks |
| Benched when they had a wishlist item on the loot table | −4 | Replaces the −2, same cap |
| Another roster raider leaves | −4 to all remaining | Once per departure |
| Another roster raider leaves, same class | −6 instead of −4 | Once per departure |
| Player dismisses a raider voluntarily | −2 to all remaining | Once per dismissal; cheaper than a departure by design |
| Guild Reputation rank up | +5 to all | Once per rank (canon ranks: Unknown → Known → Respected → Established → Renowned → Legendary) |

### 7.3 Loot

| Trigger | Delta | Cap / cooldown |
|---|---|---|
| Received an item that is a stat upgrade for them | +5 | Max +10 per loot distribution |
| Received a wishlisted item | +12 (replaces the +5) | Max one wishlist grant per raider per 3 Day Ticks |
| Received an item that is not an upgrade (sidegrade / downgrade) | 0 | No morale from clutter |
| Passed over: an item they could use went to another raider | −3 | Max −6 per distribution |
| Passed over: a wishlisted item went to another raider | −5 (replaces the −3) | Counts toward the same −6 cap |
| Passed over: a wishlisted item was sold at the Market | −7 | Not capped — this is the player choosing gold over a person |

### 7.4 Town (canon-sourced triggers)

| Trigger | Delta | Cap / cooldown | Canon |
|---|---|---|---|
| Comfort item used in the Guildhall | +8 | One comfort item per raider per 2 Day Ticks | ✅ "Manage morale with comfort items" (raw notes, Guildhall) |
| Guild facility upgraded | Raises `baseline`, not a one-off spike | See §7.5 | ✅ "Upgrade guild facilities < better morale values" (raw notes, Guildhall) |
| Training completed | +2 | Once per training | ❓ Canon says "Train raiders < Maybe if we have level ups" — gated on that Maybe |
| Quest / achievement completed on the board | +3 to all | Once per quest | ✅ "Quest/achievement board" (raw notes, Guildhall) |

### 7.5 Baseline, facilities and drift

Facility upgrades are modelled as a **baseline shift**, because canon says "better morale values" (a standing improvement) rather than "a morale bonus" (a one-off).

```
baseline = 50 + rarity_offset[rarity] + facility_bonus + backstory_offset
```

| Guildhall facility tier | `facility_bonus` |
|---|---|
| 0 (starting) | +0 |
| 1 | +3 |
| 2 | +6 |
| 3 | +10 |

Facility tier counts and costs are owned by [02 — Town & Buildings](02-town-and-buildings.md); this doc only consumes the tier number.

**Drift** — every Day Tick, after all deltas:

```
morale += clamp(baseline - morale, -drift_step, +drift_step)
drift_step = 1.5 * drift_rate[rarity]
```

Drift is the anti-farm mechanism and the recovery mechanism at once: morale gained above baseline decays, and morale lost below baseline recovers, both at the rarity's own pace. A raider at exactly baseline does not move.

**`backstory_offset`** — ✅ CANON that backstories drive morale: "Gaining and losing Morale will be based on their back stories largely we can have bullet points for each raider that is recruited" (raw notes, Morale section). This doc exposes exactly two hooks and no more: a `backstory_offset` in the range −8..+8 on baseline, and named trigger tags that multiply a §7 delta by 1.5× or 0.5× (for example a `hates_wiping` tag on the wipe row). Backstory content, tag vocabulary and per-raider bullet points belong to [04 — Recruitment & Roster](04-recruitment-and-roster.md).

### 7.6 Anti-farm audit

| Exploit | Blocked by |
|---|---|
| Re-clear the tutorial raid forever for +6 | Clear bonus is once per encounter-set per tick, and drift pulls it back |
| Spam comfort items with gold | 2-tick per-raider cooldown, plus item cost (doc 06) |
| Bring everyone every time for +3 each | Raid size is 12 (canon), and bringing a low-morale raider raises wipe risk |
| Farm first-boss-kill bonuses across alt raiders | Once per boss **per raider**, permanent |
| Park the whole roster at 100 | Drift to baseline; baseline caps at 50 + 12 + 10 + 8 = 80 |

Maximum sustainable morale without ongoing events is therefore 80 (a Legendary, tier 3 facilities, best backstory) — the bottom of band 8, Very Happy. For a Common the ceiling is 63, band 6. Band 9 (Loves Their Guild) is reachable only by active play, for anyone. That is intentional: the top band should feel earned.

---

## 8. Rarity resilience

✅ CANON: "Lower tier raiders will be hardest to keep happy, while legendary raiders will not be bothered by many things easily." (canon: raw notes, Morale section)

🔷 PROPOSED implementation — four multipliers per rarity, applied at three different points:

| Rarity | `neg_mult` (incoming negatives) | `pos_mult` (incoming positives) | `drift_rate` | `rarity_offset` (baseline) |
|---|---|---|---|---|
| Common | ×1.35 | ×0.85 | ×0.75 | −5 |
| Uncommon | ×1.15 | ×0.95 | ×0.90 | −2 |
| Rare | ×1.00 | ×1.00 | ×1.00 | 0 |
| Epic | ×0.70 | ×1.05 | ×1.20 | +4 |
| Legendary | ×0.40 | ×1.10 | ×1.50 | +12 |

Reading the table: a Common is hit harder by bad news, rewarded less by good news, recovers slower, and sits lower to begin with — four compounding reasons they are "hardest to keep happy". A Legendary is the mirror.

**Worked comparison — one wipe (−8 base) from each rarity's own baseline:**

| Rarity | Baseline (tier 0 facilities, no backstory) | After one wipe | Band after | Ticks to return to baseline |
|---|---|---|---|---|
| Common | 45 | 45 − 10.8 = 34.2 | 3 Annoyed | 10 (drift 1.125/tick) |
| Uncommon | 48 | 48 − 9.2 = 38.8 | 3 Annoyed | 7 (drift 1.35/tick) |
| Rare | 50 | 50 − 8.0 = 42.0 | 4 Slightly Annoyed | 6 (drift 1.5/tick) |
| Epic | 54 | 54 − 5.6 = 48.4 | 4 Slightly Annoyed | 4 (drift 1.8/tick) |
| Legendary | 62 | 62 − 3.2 = 58.8 | 5 Content | 2 (drift 2.25/tick) |

One wipe never puts anyone in a leave band — that takes a run of them, or a wipe plus a passed-over wishlist item plus a bench. Note also that a single wipe knocks a Common into the "noticeably higher mistake chance" band (38.4% mistake chance, up from 29.8%), which is exactly the death-spiral pressure the game wants: bad raiders wipe, wiping makes them worse.

**Guard against the spiral being inescapable:** if a raider's morale would drop below 5 in a single tick, clamp the tick's net change so morale lands no lower than 5. A raider can sit at 5 for many ticks, but they cannot be flung to 0 by one bad night, which keeps §6.3's warning escalation meaningful.

---

## 9. Wishlists / best-in-slot ❓ OPEN (optional module)

✅ CANON, quoted in full, including its own hedge: "We could have raiders also know their bis and occasionally wishlist items for bonus morale. This is all just concepts and can easily be revisited, but that's the baseline for morale." (canon: raw notes, Morale section)

Canon calls this a **concept**, not a decision. The spec below is a complete, cut-able module: everything in §7.3's wishlist rows collapses to the plain +5 / −3 upgrade rows if it is cut, and nothing else in this doc depends on it.

### 9.1 BiS versus wishlist

| Term | Definition | Visible to player |
|---|---|---|
| **BiS** | The single strictly-best item for a slot among all items currently unlocked for that class, computed from the tables in [09 — Items & Itemization](09-items-and-itemization.md) | Yes, on the raider sheet, always |
| **Wishlist** | 1-2 specific items the raider currently *wants*, a subset of items reachable this tier | Yes, once revealed (§9.3) |

BiS is deterministic and derived. Wishlist is rolled, per raider, and is what carries the morale bonus.

### 9.2 Generation 🔷 PROPOSED

On recruit, and on each refresh:

1. List every item from doc 09 that (a) the raider's class can equip per the canon Equipment Slot Matrix, and (b) drops from an encounter the guild has unlocked or is one tier ahead.
2. Weight each candidate: ×3 if the raider's slot is empty, ×2 if their current piece is Adventure-tier and the candidate is Raid-tier, ×1 otherwise. Weight ×0 if it is not a stat upgrade for them.
3. Draw 1 item at Common/Uncommon rarity, 2 at Rare and above (better raiders have opinions).
4. Never draw an item with no stat block — this excludes Raid Trinket, Final Headband, Final Eyepatch, the healer weapons and the Boss 5 class staves, all of which canon leaves statless (canon: ideaboard, §5 "Values the source leaves undefined").

**Refresh triggers:** the item is obtained; the item is superseded by a newly unlocked tier; the raider has held the same wishlist for 10 Day Ticks. Refresh resolves at the next Day Tick, never mid-loot-distribution.

Worked example — a Rogue in full common starting gear, Tier 1 raid unlocked: candidates include Raider's Boots (feet empty of raid gear, ×2), Raider's Eyepatch (×2), Basic Raid Dagger ×2 (×2 each), Raider's Leather Vest (×2). Two are drawn; say Raider's Eyepatch and Basic Raid Dagger.

### 9.3 Surfacing 🔷 PROPOSED

| Surface | Treatment |
|---|---|
| Raider sheet | "Wants: Raider's Eyepatch, Basic Raid Dagger" with a star glyph |
| Roster row | Star glyph only if a wishlisted item is on the current raid's loot table |
| Loot distribution screen | Star beside each eligible raider who wishlisted this exact item, plus the morale delta preview (`+12` / `−5`) |
| Tavern recruit preview | **Not shown.** Wishlists reveal after recruiting — the recruit screen is about stats, not shopping lists |

### 9.4 Interaction with loot assignment

Wishlists **never** constrain the player's choice. They price it. The loot screen shows, for each candidate raider: stat delta, morale delta, and current band → resulting band. Giving the mathematically worse item to keep someone above a leave threshold must be a visible, deliberate trade, which is the guild-leader fantasy canon describes.

Loot assignment rules, distribution order and sell values are owned by [09 — Items & Itemization](09-items-and-itemization.md); this doc contributes only the morale preview values from §7.3.

---

## 10. Readability requirement

✅ CANON — the roster display format, reproduced exactly from the sample roster (canon: raw notes, "Your roster might show"):

```
Natsuna — 87 ❤️
Shaman — Very Happy

Bob — 54 🙂
Warrior — Content

Greg — 31 😒
Rogue — Annoyed

Steve — 14 😡
Mage — Upset
```

### 10.1 The display contract 🔷 PROPOSED (formalising the canon shape)

| Element | Rule |
|---|---|
| Line 1 | `{Name}` + space + em dash (U+2014) + space + `{morale as integer}` + space + `{emoji}` |
| Line 2 | `{Class}` + space + em dash + space + `{State}` |
| Rounding | `floor(morale)` — a raider at 14.9 displays 14 and is in band 1, consistently with §3.2 |
| Order | Morale value precedes the emoji, per canon. Never emoji-first |
| Never | Do not display a percentage, a bar without a number, or the band index |
| Always | Both the number and the state word are always present. Emoji is decoration, never the only signal |

Canon's own choice to put the *number* before the emoji and the *state word* on the second line is the readability spec: the player reads "14" and reacts, then confirms with "Upset". Preserve that hierarchy.

### 10.2 Emoji mapping

Four rows are pinned by canon; six are proposed.

| Band | State | Emoji | Source |
|---|---|---|---|
| 0 | Very Upset | 🤬 | 🔷 PROPOSED |
| 1 | Upset | 😡 | ✅ CANON (Steve — 14 😡) |
| 2 | Unhappy | 😠 | 🔷 PROPOSED |
| 3 | Annoyed | 😒 | ✅ CANON (Greg — 31 😒) |
| 4 | Slightly Annoyed | 😐 | 🔷 PROPOSED |
| 5 | Content | 🙂 | ✅ CANON (Bob — 54 🙂) |
| 6 | Happy | 😄 | 🔷 PROPOSED |
| 7 | Quite Happy | 😁 | 🔷 PROPOSED |
| 8 | Very Happy | ❤️ | ✅ CANON (Natsuna — 87 ❤️) |
| 9 | Loves Their Guild | 💖 | 🔷 PROPOSED |

Note the canon set is not a pure face ramp: 87 is a heart, not a face. Bands 8-9 are proposed as hearts and 0-7 as faces, which is the reading that keeps Natsuna's row correct.

🔷 PROPOSED, for the 2D-HD art direction: ship these as authored sprites in the game's own style rather than system emoji — a 10-frame morale face sheet. System emoji will not survive next to an *Octopath Traveler*-style presentation, and it renders differently per platform. [12 — Art Direction](12-art-direction.md) owns the sheet; this doc owns the 10 slots and their order.

### 10.3 Legibility on the raid-prep screen

**Requirement:** with 12 roster slots visible during raid prep (raid size is 12 — canon: raw notes, Classes), the player must identify every at-risk raider in under two seconds, without hovering, reading a tooltip, or opening a sheet.

| Requirement | Spec |
|---|---|
| Morale number size | At least as large as the raider's name; never smaller |
| Colour | 10-step ramp from the band index, but colour is never the only signal (number + word + glyph always present) |
| At-risk marking | Bands 0-2 carry a text tag ("AT RISK" / "MAY LEAVE"), not just a colour |
| Sort | Raid-prep roster sorts by morale ascending by default, so the problems are at the top |
| Bring-anyway path | Selecting a band 0-2 raider for a raid shows their `effective_mistake_chance` inline, so the canon thought — "unless he really wants to go and I know I can beat the raid with him messing up" — is an informed choice |
| Colour-blind safety | The ramp must pass deuteranopia and protanopia checks; verify in doc 13, not here |

Palette and the actual sprite work: [12 — Art Direction](12-art-direction.md). The layout that places them, and the colour-blind check this table defers, are [13 — UI/UX](13-ui-ux.md).

---

## 11. Worked example — the canon sample roster

Running canon's four raiders through §5. Morale values, names, classes and states are ✅ CANON. **Rarity is not stated in canon for Bob, Greg or Steve** and is 🔷 PROPOSED below; Natsuna is ✅ CANON as a Legendary ("You can only ever find 1 Legendary per class - They are also named characters - IE Natsuna(the shaman) or something" — raw notes, Guild Reputation).

| Raider | Class | Morale | Band | State | Rarity | Multiplier | Effective mistake chance |
|---|---|---|---|---|---|---|---|
| Natsuna | Shaman | 87 | 8 | Very Happy | Legendary ✅ | ×0.850 | **1.02%** |
| Bob | Warrior | 54 | 5 | Content | Uncommon 🔷 | ×1.000 | **15.0%** |
| Greg | Rogue | 31 | 3 | Annoyed | Common 🔷 | ×1.600 | **38.4%** |
| Steve | Mage | 14 | 1 | Upset | Common 🔷 | ×2.680 | **64.3%** |

### 11.1 Does this feel right?

Canon's stated goal for this exact roster: "Oh shit, Steve is at 14. Maybe I shouldn't bring him, unless he really wants to go and I know I can beat the raid with him messing up." (raw notes, Morale section)

| Reading | Evidence |
|---|---|
| Steve is a visible liability | 64.3% — roughly two mistake checks in three. "Oh shit" is the correct reaction |
| But he is not auto-excluded | 35.7% of the time he is fine, and the raid is 12 people — one bad mage is survivable if the tanks hold |
| Bob is unremarkable and that is right | 15.0% at Content. He is the mental baseline the player compares everyone against |
| Greg's 31 reads as a warning shot | 38.4%, and 31 morale is one band above leaving. The player should feel the pull to spend a comfort item |
| Natsuna is the reason you keep her happy | 1.02%. She is functionally reliable, and canon's "near 1%" is hit exactly |
| The spread is legible without maths | 1% / 15% / 38% / 64% — four numbers a player can hold in their head |

### 11.2 Steve's recovery path, as the player would experience it

Steve: Common Mage, 14 morale, baseline 45 (tier 0 facilities, no backstory offset), drift 1.125/tick.

| Day Tick | Action | Morale maths | End morale | Band |
|---|---|---|---|---|
| 0 | (start) | — | 14.0 | 1 Upset — leave roll 18.2%/tick |
| 1 | Comfort item (+8 × 0.85 = +6.8), benched (no penalty, 1st tick), drift +1.125 | 14.0 + 6.8 + 1.125 | 21.9 | 2 Unhappy — leave roll 6.5% |
| 2 | Comfort item on cooldown; brought on an easy Adventure and it clears (+3 +6, ×0.85 = +7.65), drift | 21.9 + 7.65 + 1.125 | 30.7 | 3 Annoyed — **cannot leave** |
| 3 | Comfort item (+6.8), drift | 30.7 + 6.8 + 1.125 | 38.6 | 3 Annoyed |
| 4 | Given a wishlisted Raider's Cap (+12 × 0.85 = +10.2), drift **−1.125** (48.8 is above baseline 45) | 38.6 + 10.2 − 1.125 | 47.7 | 4 Slightly Annoyed |
| 5 | Raid clears, he participated (+6 +3 = +9 × 0.85 = +7.65), drift −1.125 | 47.7 + 7.65 − 1.125 | 54.2 | 5 Content — 24.0% mistake chance |

Note the sign flip at tick 4: drift is `clamp(baseline − morale, ±drift_step)` (§7.5), so once Steve crosses his baseline of 45 the same mechanism that was helping him recover starts pulling him back down. Above baseline, every gain is taxed 1.125/tick.

Five to six Day Ticks of deliberate attention, two comfort items and a wishlist grant to move a Common from "may leave the guild" to "Content" — and his mistake chance falls 64.3% → 24.0% along the way. That is the pacing this doc is tuned for: recovery is possible, costly, and never automatic. Note the same journey for a Legendary takes two ticks, and for a Common with a bad backstory offset takes eight.

---

## 12. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| 1 | Bands 70-80 and 80-90 are both named "Very Happy" in canon. Which is renamed? **Needs one designer ruling — four docs disagree (§3.1).** | State name is a display string, save token and telemetry key; duplicates are unimplementable. Docs 00, 04 and 13 are each blocked on this one word | Rename 70-80 to "Quite Happy"; 80-90 keeps "Very Happy" because canon's Natsuna 87 row ties it there. On sign-off, apply the §3.1 table: doc 00 Q6 records the ruling, doc 04 Q2 cites §3.1, doc 13 §8.3's band-7 State cell becomes "Quite Happy". On rejection, strip the four provisional uses listed in §3.1 |
| 2 | Band boundaries overlap at every tens value (0-10, 10-20, …). Which band owns 10, 20, …? | Every band lookup in the codebase depends on it | Half-open `[lower, upper)`, top band `[90, 100]`; `band_index = min(9, floor(morale/10))` — validates all four canon roster rows |
| 3 | ~~Should adjacent rarity tiers be allowed to overlap in mistake chance?~~ RULED — yes, [15 Q-08](15-open-questions.md#q-08) / [BL-20](15-open-questions.md#bl-20); 08 §8.8 publishes the overlap | Determines whether morale is a real decision or cosmetic | Yes, overlap below Legendary; Legendary stays strictly dominant. Strict non-overlap would flatten the low-rarity curve and contradict "lower tier raiders will be hardest to keep happy" |
| 4 | Canon attaches "may cause guild disband" to one raider's band. Is one miserable raider enough to end a run? | A run-ender that fires off one raider is a rage-quit generator | No. Require a raider in band 0 **and** guild average below 25 **and** three consecutive crisis ticks (§6.3) |
| 5 | Does disband end the run, or demote the guild? | Changes the whole shape of failure and of the meta loop | Neither ends the run and nothing demotes: roster is wiped, gold and unlocked content kept; RP penalty −10% within the current rank, clamped to the rank floor — rank never decreases ([03 — Guild Reputation](03-guild-reputation.md) §6.5). Reversible failure suits a comedy game, and a rank loss would hand a struggling player worse recruits. [00 — Vision & Pillars](00-vision-and-pillars.md) Q4 and [01 — Core Loop](01-core-loop.md) OQ#2 should point here rather than propose their own answers |
| 6 | Is the wishlist / BiS module in or out? Canon calls it "just concepts" | Six rows of §7.3 and the whole of §9 depend on it | In, as an optional module built after the core loop ships. It is the highest-value morale lever for the least system weight |
| 7 | ~~What is a mistake check's cadence — per round, per encounter, per mechanic?~~ RULED — [15 Q-05](15-open-questions.md#q-05): per raider per roll site (action, mechanic, ambient — [07 §5.3](07-combat-simulation.md)), each site weighted by 08 §8.8's `ROLL_SITE_WEIGHT` so the per-round aggregate equals the published chance | The percentages are meaningless without it; 64% per round is very different from 64% per encounter | Per raider per mechanic event, roughly 2-4 per encounter. Doc 08 owns the final answer; if it lands on per-round, scale all bases down by ~3× |
| 8 | Does the town have a day clock, or does time only pass when you raid? | Every "per Day Tick" number here is anchored to it | Time advances on raid/adventure resolution or an explicit rest. If rest is cut, raise all drift values ~1.5× |
| 9 | Canon's severity adjectives are not strictly ordered: 10-20 and 20-30 are both "Increased mistake chance", and 30-40 is "noticeably higher" — is 30-40 meant to be worse than 20-30? | Monotonicity is the one property the canon table asserts, and the wording undercuts it | Treat the table as strictly monotonic by morale value: 20-30 is worse than 30-40 regardless of adjective. §5.2 implements this |
| 10 | Should morale be visible before recruiting at the Tavern? | Changes recruitment from a gamble to a shopping trip | Show it. Starting morale equals baseline (§4), so it is a rarity tell, not a surprise |
| 11 | Does a benched raider still gain the clear bonus? | Determines whether the roster splits into a raid team and a decaying bench | No clear bonus, and a bench penalty from the 2nd consecutive tick. The bench should hurt a little |
| 12 | Is there a morale cost to the player *choosing* to disband their own guild or fire a raider? | Prevents "fire the unhappy one" being strictly optimal | Voluntary dismissal is −2 to all remaining, versus −4 for a departure. Cheaper, but not free |

---

## Related documents

- [04 — Recruitment & Roster](04-recruitment-and-roster.md) — owns rarity distribution and the backstory bullet points that feed `backstory_offset` and the trigger tags in §7.5.
- [06 — Classes & Roles](06-classes-and-roles.md) — the nine canon classes named in the roster display contract (§10).
- [02 — Town & Buildings](02-town-and-buildings.md) — owns comfort items, Guildhall facility tiers and the day clock that §4's Day Tick depends on.
- [08 — Stats & Formulas](08-stats-and-formulas.md) — consumes `effective_mistake_chance` from §5 and owns everything downstream of the roll.
- [09 — Items & Itemization](09-items-and-itemization.md) — the item tables wishlists are generated from (§9.2) and the loot-assignment screen that shows §7.3's morale previews.
- [12 — Art Direction](12-art-direction.md) — owns the 10-frame morale face sheet §10.2 specifies the slots for, and the palette the colour ramp is drawn from.
- [13 — UI/UX](13-ui-ux.md) — owns the raid-prep roster layout in §10.3, the ramp's on-screen application, and the deuteranopia/protanopia check this doc requires but does not run.
