# 06 — Classes, Roles & Raid Composition

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs the nine classes, what each one contributes to a single combat round, how a mistake by each class expresses itself, and how the player assembles a 12-person raid out of a random recruit pool.

## 1. Scope

**This doc owns:**

- The nine-class roster and the role each class fills.
- A per-class kit spec: round contribution, one distinguishing mechanic, failure mode, scaling stat.
- The Bard problem (canon leaves song effects TBD) and candidate directions.
- Raid composition: role splits, template comps, and the rules for a raid that cannot field an ideal comp.
- Class availability at game start, and how it interacts with the one-Legendary-per-class rule.

**This doc does NOT own:**

| Topic | Owner |
|---|---|
| Round order, action resolution, threat table mechanics, positioning as a global system | [07 — Combat Simulation](07-combat-simulation.md) |
| Damage, healing, mitigation and mistake-chance formulas; what a point of Mana is worth | [08 — Stats & Formulas](08-stats-and-formulas.md) |
| Item stat blocks, slot families, drop tables, upgrade paths | [09 — Items & Itemization](09-items-and-itemization.md) |
| Recruit rarity tiers, morale, backstories, mistake *chance* | [04 — Recruitment & Roster](04-recruitment-and-roster.md) |
| Reputation gating of recruit tiers | [03 — Guild Reputation & Unlocks](03-guild-reputation.md) |

**Boundary rule used throughout:** doc 04 decides *whether* a raider makes a mistake this round. This doc decides *what the mistake looks like* for that class. That split keeps the comedy content here and the probability math there.

---

## 2. The class roster ✅ CANON

Reproduced exactly as given (canon: raw notes, Classes section).

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

Also canon, same section:

- ✅ CANON — "I can go into LARGE amounts of detail when we get rdy to dive into classes. I have thoughts and plans, its a lot."
- ✅ CANON — "I've also decided I'd like the raid size to be 12, most fights normally requiring 2 tanks."

Canon stat definitions (canon: raw notes, Stat definitions):

| Stat | Canon definition |
|---|---|
| AC | "2 damage reduction" |
| Power | "+1 melee dmg" |
| Mana | "spell damage (Subject to change)" |

The parenthetical on Mana is canon and is preserved: nothing in this doc treats Mana as settled. See Open Questions #1.

---

## 3. Kit template — the frame, not the design

**Why this section exists:** canon states the lead designer has "LARGE amounts of detail" planned for classes and intends to dive in later. This document therefore does **not** attempt to pre-empt that design. Its job is to define a *consistent slot* that the coming detail drops into, so that whatever the designer specifies per class can be entered without re-architecting the sim. Everything in sections 4 and 5 marked 🔷 PROPOSED is a placeholder of the correct shape — it is meant to be overwritten, field by field, not defended.

🔷 **PROPOSED — the kit template.** Every class is described by exactly these seven fields, and no class gets more than four numbered rules.

| Field | What goes in it | Consumed by |
|---|---|---|
| Role | Canon role string, verbatim | UI, comp checker |
| Round contribution | The one thing it does every round if nothing goes wrong | Sim |
| Rules (2–4) | Implementable statements; no adjectives | Sim |
| Distinguishing mechanic | The single thing only this class does | Sim, tooltips |
| Failure mode | What the sim does instead when doc 04 rolls a mistake for this raider | Sim, combat log |
| Scaling stat | Primary / secondary stat the kit reads | Doc 09 itemization |
| Threat profile | Low / Medium / High / Tank multiplier | Doc 07 threat table |

🔷 **PROPOSED — the four-rule cap.** The canon design is a round-based simulation the player watches, not an action game they pilot. A class the player cannot hold in their head while reading a combat log is a class whose mistakes are not funny, because the player cannot tell that anything went wrong. Four rules is the cap; three is better.

🔷 **PROPOSED — shared vocabulary.** So the nine kits stay comparable:

| Term | Meaning here |
|---|---|
| Round | One tick of the fight. Every living raider resolves one action per round. |
| Assigned target | The enemy or ally a raider is acting on this round, chosen by the sim, not the player. |
| Threat | The value that decides which raider the boss attacks. Mechanics in doc 07. |
| Mistake | A per-raider, per-round event whose probability doc 04 owns. |
| Song / Stance / Ramp | Class-local state that persists between rounds. Only Bard, Monk and Wizard have any. |

---

## 4. Class kit specs 🔷 PROPOSED

Role strings and descriptions in each header are ✅ CANON. Everything under them is 🔷 PROPOSED unless marked otherwise.

### 4.1 Warrior — Main Tank

✅ CANON: "High survivability, high threat" (canon: raw notes, Classes).

| Field | Spec |
|---|---|
| Round contribution | Holds the boss's attention and absorbs its attacks; deals modest melee damage. |
| Distinguishing mechanic | **Threat Lock.** While the Warrior is the highest-threat raider, the boss attacks only the Warrior. |
| Failure mode | **Lost Aggro** — the Warrior's threat is zeroed for one round. The boss's attack this round retargets to the current second-highest-threat raider, which is normally a Wizard or Mage sitting on 8 AC. |
| Scaling stat | Primary AC and HP; secondary Power (Power funds both its damage and its threat). Families in doc 09. |
| Threat profile | Tank. |

Rules:

1. Each round the Warrior attacks the boss for weapon damage plus Power, and generates threat at a tank multiplier.
2. While it holds top threat, incoming boss single-target attacks resolve against the Warrior and are reduced by its AC.
3. On a mistake, apply Lost Aggro (above) for one round; the Warrior regains top threat automatically the following round.

**Why the failure mode is this:** a Warrior mistake should kill somebody else. That is the joke — the tank is fine, the tank is always fine, the Mage is a smear.

### 4.2 Cleric — Main Tank Healer

✅ CANON: "Efficient single-target healing" (canon: raw notes, Classes).

| Field | Spec |
|---|---|
| Round contribution | One large heal to one target, selected as the lowest-HP tank. |
| Distinguishing mechanic | **Focused Heal.** The largest single-target heal in the game, but it can only ever reach one raider per round. |
| Failure mode | **Wrong Target** — the heal resolves on a random raider at full HP instead. The heal is not lost, it is *wasted*, and the tank eats an unhealed round. |
| Scaling stat | Mana — RULED (Open Questions #1 → [08 §5.3](08-stats-and-formulas.md)); canon's healer weapons ("mana or power unsure how much") carry Mana. |
| Threat profile | Medium (healing generates threat; doc 07). |

Rules:

1. Each round the Cleric heals the lowest-HP raider whose role is Tank. If no tank is alive, it heals the lowest-HP raider overall.
2. Its heal per round is the highest single-target heal of the three healer classes.
3. On a mistake, apply Wrong Target (above).

### 4.3 Druid — Raid Healer

✅ CANON: "Small heal to the entire raid every round" (canon: raw notes, Classes).

| Field | Spec |
|---|---|
| Round contribution | A small heal to all 12 raid members, every round. No targeting decision. |
| Distinguishing mechanic | **Blanket Heal.** The only heal in the game with no target selection, therefore the only heal that cannot be mis-aimed. |
| Failure mode | **Fumbled Cast** — the blanket heal does not go out at all this round. Nobody dies from one missed tick; the raid dies from three of them, and the player does not notice until the third. |
| Scaling stat | Mana — RULED (#1 → [08 §5.3](08-stats-and-formulas.md)). |
| Threat profile | Medium. |

Rules:

1. Each round the Druid heals every living raid member for a small flat amount.
2. Its per-target heal is the smallest of the three healers; its total throughput is the largest.
3. On a mistake, the heal is skipped entirely for that round.

**Note on the failure mode:** Druid mistakes are deliberately the *quietest* in the game. It is the only class whose failure reads as "nothing happened", which is exactly why it needs a loud combat-log line (doc 07 owns log formatting).

### 4.4 Shaman — Chain Healer (bouncing heal)

✅ CANON: "Medium → medium → small healing" (canon: raw notes, Classes). The three magnitudes and their order are canon and must not be re-tuned into a smooth curve.

| Field | Spec |
|---|---|
| Round contribution | One heal that hits three raiders in sequence for medium, then medium, then small. |
| Distinguishing mechanic | **Bounce Order.** The chain seeks the lowest-HP raider first, then the lowest-HP raider it has not already hit, and so on for three hops. |
| Failure mode | **Bad Bounce** — the chain starts on a random raider instead of the lowest-HP one. The two medium hops land on people who did not need them and the raider who did need it receives, at best, the small third hop. |
| Scaling stat | Mana — RULED (#1 → [08 §5.3](08-stats-and-formulas.md)). |
| Threat profile | Medium. |

Rules:

1. Each round the Shaman casts a three-hop chain heal: hop 1 medium, hop 2 medium, hop 3 small (canon magnitudes).
2. Hop targets are resolved one at a time, always the lowest-HP living raider not yet hit by this cast.
3. On a mistake, hop 1 targets a uniformly random living raider; hops 2 and 3 then proceed by the normal rule.

### 4.5 Rogue — Melee DPS

✅ CANON: "Position-dependent burst DPS" (canon: raw notes, Classes).

Canon asserts positioning for the Rogue but no positioning system exists anywhere in either source. 🔷 PROPOSED below is the **smallest** model that satisfies the canon phrase; whether positioning becomes a global combat concept is doc 07's call, not this doc's.

| Field | Spec |
|---|---|
| Round contribution | Melee damage, multiplied by its positional state: 1.3× while Behind the boss, 0.77× while Front. |
| Distinguishing mechanic | **Behind / Front.** A two-state per-round flag feeding doc 08's `positional_mult`. Behind = full burst. Front = reduced damage and increased threat gain. |
| Failure mode | **Faced the Boss** — the Rogue flips to Front for two rounds: `positional_mult` drops 1.3 → 0.77 (a ~41% damage cut), and it generates threat as if it were trying to tank. |
| Scaling stat | Power. |
| Threat profile | Low while Behind, High while Front (that is the punishment). |

Rules:

1. The Rogue starts each fight Behind and stays Behind unless a mistake moves it.
2. Attack count does not change with position: the Rogue gets two swing windows per round, each producing a main-hand and an off-hand attack (four attacks), per [08 §8.2](08-stats-and-formulas.md) — canon dual-wield, per the ideaboard slot matrix: Main Hand and Off Hand are both `Warrior/Rogue/Bard 1H`.
3. Position sets `positional_mult` only: **Behind = 1.3**, **Front = 0.77**. These are doc 08's numbers — 08 §11 owns the tuning ([08 — Stats, Formulas & Numeric Model](08-stats-and-formulas.md), `CLASS_MELEE_COEF[Rogue]` row); do not re-derive them here.
4. On a mistake, apply Faced the Boss for two rounds, then return to Behind.

**Why two rounds, not one:** a one-round Rogue mistake is indistinguishable from noise in a 12-raider log. Two rounds is long enough for the player to read it and be annoyed at Greg specifically.

### 4.6 Monk — Melee DPS / Offtank

✅ CANON: "High DPS + emergency tank" (canon: raw notes, Classes).

| Field | Spec |
|---|---|
| Round contribution | The highest sustained melee damage in the game, until it is needed as a tank. |
| Distinguishing mechanic | **Stance Swap.** Two stances: Fists (full damage, low threat) and Guard (tank threat multiplier, AC treated as tank-grade, damage cut hard). Guard is an *emergency* state, not a standing assignment: the sim swaps to Guard only when the primary tank goes Downed or Dead, per doc 07 §8.3's Emergency Tank trigger. |
| Failure mode | **Panicked Stance** — the Monk swaps to the wrong stance. If tanks are healthy it swaps to Guard (throwing away the raid's best DPS for two rounds *and* fighting the Warrior for threat). If a tank has just died it stays in Fists, and the boss free-swings into the raid. |
| Scaling stat | Power primary; AC and HP matter only in Guard. |
| Threat profile | Low in Fists, Tank in Guard. |

Rules:

1. Default stance is Fists. In Fists the Monk deals the highest single-target melee damage of any class.
2. The sim swaps the highest-threat living Monk to Guard when the primary tank becomes Downed or Dead, and back to Fists when a Warrior is Alive and stable again. Trigger and exit condition are doc 07's — see [07 — Combat Simulation](07-combat-simulation.md) §8.3. A Monk never pre-emptively fills an empty second tank slot.
3. In Guard, Monk damage is reduced and it generates tank-grade threat.
4. On a mistake, invert the stance decision for two rounds (Panicked Stance, above).

**Comp consequence:** the Monk covers a *dead* tank, not a *missing* one. Because Guard only fires after the primary tank drops, section 6 counts a Monk as **zero** tanks in the comp check and treats extra Monks as post-death insurance instead of a second tank body.

### 4.7 Mage — AoE Caster

✅ CANON: "Raid spell buff + AoE damage" (canon: raw notes, Classes).

| Field | Spec |
|---|---|
| Round contribution | Maintains one raid-wide spell buff, and hits every enemy in the encounter each round. |
| Distinguishing mechanic | **Raid Spell Buff** (canon phrase). One flat spell-power buff applied to every caster in the raid. It does **not** stack — a second Mage adds AoE only. |
| Failure mode | **Overpull** — the AoE splashes something it should not have. Concretely: the Mage's AoE this round also strikes any untanked enemy group, and the Mage takes threat on all of them. It has the lowest AC in the game (8 AC in Tier 1 Adventure gear, tied with the Wizard, per the ideaboard). |
| Scaling stat | Mana. |
| Threat profile | Medium, spiking High on Overpull. |

Rules:

1. While at least one Mage is alive, all casters in the raid have the Raid Spell Buff. It does not stack across Mages.
2. Each round the Mage deals spell damage to every living enemy in the encounter.
3. On a mistake, apply Overpull (above) for one round.

**Where the Mage shines:** encounters with trash packs — canon's Encounter 1 (Trash) and Encounter 2 (Harder trash), and Adventure 1's "few trash encounters" (canon: raw notes, Adventure's Board / Raid Layout).

### 4.8 Wizard — Single-Target Caster

✅ CANON: "Very high single-target DPS" (canon: raw notes, Classes).

| Field | Spec |
|---|---|
| Round contribution | The largest single-target damage number in the game, and it grows the longer it is left alone. |
| Distinguishing mechanic | **Ramp.** Each consecutive round the Wizard attacks the same target it gains a stack (+10% spell damage per stack, cap 5 stacks 🔷). Changing target drops all stacks. |
| Failure mode | **Broke the Ramp** — the Wizard retargets for no reason, losing every stack, and the player watches a five-round investment evaporate in one log line. |
| Scaling stat | Mana. |
| Threat profile | Medium and rising with stacks — a fully ramped Wizard is second on the threat table, which is why Warrior mistakes kill Wizards. |

Rules:

1. Each round the Wizard deals spell damage to the boss (or, absent a boss, the highest-HP enemy).
2. Ramp: +10% per consecutive round on the same target, maximum 5 stacks. Target change or a skipped round resets to 0.
3. On a mistake, the Wizard targets a random other enemy and its stacks reset to 0.

### 4.9 Bard — Support

✅ CANON: "Random song effects TBD" (canon: raw notes, Classes). The TBD is canon. Section 5 treats it as an open design problem rather than filling it in silently.

| Field | Spec |
|---|---|
| Round contribution | One song per round, affecting the raid. Contents open — see section 5. |
| Distinguishing mechanic | Randomness itself: the Bard is the only class whose contribution the player cannot predict. |
| Failure mode | **Wrong Song** — rolls on a separate, actively harmful table (section 5.4). |
| Scaling stat | ❓ OPEN — canon puts +20 Mana on the Bard capstone while Bard armor carries Power. See section 5.1. |
| Threat profile | Low. |

---

## 5. The Bard problem ❓ OPEN

### 5.1 What canon actually says

Two canon facts, in tension:

1. ✅ CANON — Bard's role description is "Random song effects TBD" (canon: raw notes, Classes).
2. ✅ CANON — the Bard's Boss 5 capstone is **Bard Instrument — +20 Mana**, while every other Bard armour piece is shared Warrior/Bard armour carrying Power: Raider's Helm +1 Power, Raider's Cuirass +2 Power, Raider's Greaves +1 Power (canon: ideaboard, §3.2).
3. ✅ CANON, verbatim source note on that same table: *"Bard uses the same Warrior/Bard armor, so **Mana can appear on these pieces and compete with Power**."*

So canon has already identified the problem and declined to solve it. The Bard is the only class in the game whose gear tells it to scale on two different stats, and the only class whose mechanic is undefined. Those two facts are the same fact: you cannot pick the stat until you know what the songs do.

### 5.2 Three concrete directions

| # | Direction | Mechanic | Stat model | Pros | Cons |
|---|---|---|---|---|---|
| B1 | **Rotating random song** | Each round, roll d6 on a fixed song table. Effect lasts that round. | Mana sets song magnitude. Power is dead. | Matches canon's "random song effects" exactly. Highest comedy density. Cheap to author — new songs are table rows. | High variance; a bad streak feels unfair. Power on Warrior/Bard armour becomes a trap stat for Bards. |
| B2 | **Flat aura buffer** | Player picks one aura before the raid (e.g. +2 Power raid-wide). Constant, no rolls. | One stat, either. | Trivially balanceable and readable. Player agency. No variance complaints. | Discards the canon word "random". Boring — the Bard becomes a checkbox on the roster screen. |
| B3 | **Hybrid melee/support** | Bard auto-attacks with the shared 1H sword every round and carries one passive song. | Power funds the attack, Mana funds the song. | Makes both stats on Warrior/Bard armour live. Nothing on the loot table is wasted. | Weakest at both jobs. Two scaling stats = two balance curves for one class. Still no "random". |

### 5.3 Recommendation 🔷 PROPOSED

**Take B1's mechanic with B3's stat model.**

The argument:

1. Canon says "random song effects". Randomness is not a placeholder here — it is the single best thematic fit in the roster for a game whose premise is that your raiders make mistakes. Every other class is random only in *failing*; the Bard is random while *succeeding*. That is a genuinely distinct feel and it costs almost nothing to implement (one table, one roll).
2. B2 solves a balance problem the game does not have. This is a single-player sim; variance is content, not an injustice.
3. B3's stat model, bolted onto B1, is what closes the canon-flagged Power/Mana competition: **song magnitude scales on Mana, and the Bard also auto-attacks for Power damage at a reduced rate.** Mana is the Bard's primary; Power is a real but secondary contribution. A Warrior/Bard chest with Power on it is then a fine Bard piece and an excellent Warrior piece — which is exactly the contested-drop tension the shared armour family is *for*.
4. The comedy is loaded into the *mistake*, not the base table. All six songs are positive-or-neutral. A Bard mistake rolls the Wrong Song table instead, which is actively bad. So the Bard is fun to have and catastrophic to neglect.

### 5.4 Placeholder tables 🔷 PROPOSED

Explicitly a placeholder of the right shape, per section 3. Let `S = 1 + floor(Mana / 10)` (magnitude step; the divisor is doc 08's to set).

**Song table — roll d6 each round:**

| Roll | Song | Effect (this round) |
|---|---|---|
| 1 | Marching Song | +S Power to every melee raider |
| 2 | Hymn of Focus | +S spell damage to every caster |
| 3 | Rallying Chorus | Heal all living raiders for 2×S |
| 4 | Song of Warding | +S AC to every raider currently tanking |
| 5 | Drinking Song | −3 percentage points mistake chance, raid-wide |
| 6 | Ballad of Second Wind | Heal the single lowest-HP raider for 4×S |

**Wrong Song table — roll d4 on a Bard mistake:**

| Roll | Wrong Song | Effect |
|---|---|---|
| 1 | Song of Discord | Threat table shuffles: a random raider becomes top threat for one round |
| 2 | Off-Key Dirge | −S spell damage to every caster this round |
| 3 | The Song That Never Ends | Bard is locked into this song for 2 rounds and contributes nothing |
| 4 | Extremely Loud Solo | Bard's threat is set equal to the current tank's for one round |

Duplicate Bards do not stack their rolls; each Bard rolls independently and both effects apply. Two Bards therefore double the chance that *something* good happens and double the chance of a Wrong Song.

---

## 6. Raid composition

### 6.1 Canon constraints

- ✅ CANON — raid size is **12**.
- ✅ CANON — "most fights normally requiring 2 tanks".

Both from raw notes, Classes section. Everything else in section 6 is 🔷 PROPOSED.

### 6.2 Role classification 🔷 PROPOSED

**Why this exists:** the comp checker needs a machine-readable role per class, and canon's role strings are prose.

| Class | Role tag | Tank weight | Notes |
|---|---|---|---|
| Warrior | TANK | 1.0 | The only dedicated tank in the roster. |
| Monk | DPS / OFFTANK | 0.0 | Counts as **no** tank for comp purposes. Guard is an emergency state that only fires once the primary tank is Downed or Dead (4.6, doc 07 §8.3), so a Monk in a healthy raid never occupies the second tank slot. |
| Cleric | HEALER_ST | — | Canon role is specifically *Main Tank* Healer. |
| Druid | HEALER_RAID | — | |
| Shaman | HEALER_CHAIN | — | |
| Rogue | DPS_MELEE | — | |
| Mage | DPS_AOE | — | Also the raid spell buff carrier. |
| Wizard | DPS_ST | — | |
| Bard | SUPPORT | — | Counted in the DPS budget for comp purposes. |

**Consequence worth stating plainly:** with exactly one dedicated tank class, a two-tank requirement, and Monk tanking confined to the emergency state, every standard comp needs **two Warriors**. A one-Warrior roster is not a two-tank comp with a small shortfall; it is a **one-tank comp**, and it takes the full tank-coverage penalty in 6.5. Canon does not say whether duplicate classes in one raid are allowed; this doc assumes yes (section 6.6) because the alternative makes the canon two-tank requirement unsatisfiable outright.

This matches doc 07's OQ-3 default ("Warrior + Warrior standard; Monk emergency state stays emergency-only"). If that OQ ever resolves the other way — a designated Monk offtank that pre-emptively holds the second slot — this table's Monk tank weight and template B below are what change, and doc 07 §8.3's trigger changes with them.

### 6.3 Baseline split 🔷 PROPOSED

**Why this exists:** the player needs one number to aim at before they understand the game.

| Role | Baseline count | Range the sim should tolerate |
|---|---|---|
| Tanks | 2 | 1–3 |
| Healers | 3 | 2–5 |
| DPS + Support | 7 | 4–9 |
| **Total** | **12** | fixed |

"Tanks" here means raiders with tank weight ≥ 1.0 — in practice, Warriors. Monks do not count toward this row (6.2).

### 6.4 Template comps 🔷 PROPOSED

Four templates, each summing to 12. These ship as one-click presets on the raid screen; the comp checker validates against the fight, not against these.

**A — Standard (2/3/7).** The default. Two Warriors so a Lost Aggro (4.1) has a backstop.

| W | Mo | Ro | Cl | Dr | Sh | Ma | Wi | Ba | Total |
|---|---|---|---|---|---|---|---|---|---|
| 2 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 1 | 12 |

Reasoning: 2 tanks satisfies canon. One of each healer covers all three healing shapes (single-target, blanket, chain), which is the most forgiving healing mix against unknown damage patterns. Two Wizards for boss damage, one Mage for the raid spell buff plus trash coverage.

**B — One-Tank / Monk Backstop (1 Warrior).** For when the tavern has given you exactly one Warrior, which it will. This is a **one-tank comp**, not a two-tank comp with a Monk in the second slot.

| W | Mo | Ro | Cl | Dr | Sh | Ma | Wi | Ba | Total |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 2 | 2 | 1 | 1 | 1 | 1 | 2 | 1 | 12 |

Reasoning: tank weight = 1.0 against a required 2 — a full 1.0 shortfall, and the heaviest penalty in 6.5. The two Monks buy nothing before the Warrior dies; they are what stops the wipe *after* it, because Guard only fires on the primary tank going Downed or Dead (4.6, doc 07 §8.3). Two of them means the backstop itself has a backstop. Bring this comp knowing the fight is being run a tank short.

**C — Trash Clear / AoE lean.** For adventures and the early raid encounters — canon's Encounter 1 and 2 are both trash.

| W | Mo | Ro | Cl | Dr | Sh | Ma | Wi | Ba | Total |
|---|---|---|---|---|---|---|---|---|---|
| 2 | 2 | 1 | 1 | 1 | 1 | 3 | 1 | 0 | 12 |

Reasoning: three Mages means three full AoE volleys per round, and the raid spell buff still only applies once (4.7) — the extra Mages are pure area damage. Drops the Bard because single-round random buffs matter least when the fight is decided by clear speed.

**D — Attrition / high incoming damage (2/4/6).** For a boss that outputs more than three healers can cover.

| W | Mo | Ro | Cl | Dr | Sh | Ma | Wi | Ba | Total |
|---|---|---|---|---|---|---|---|---|---|
| 2 | 1 | 1 | 2 | 1 | 1 | 0 | 3 | 1 | 12 |

Reasoning: a second Cleric doubles tank-directed throughput, which is where the damage is going. Trades the Mage away entirely (single-target fight, no AoE value) and its raid spell buff, accepting lower caster damage in exchange for three Wizards ramping (4.8) on one target.

### 6.5 When the player cannot field an ideal comp 🔷 PROPOSED

**Why this exists:** recruits are random (canon: recruits are found at the Tavern; the pool available is gated by Guild Reputation). At Unknown reputation, canon says "you can only find the worst players to join your guild". A comp system that hard-gates on class will therefore soft-lock the player through no fault of their own. So: **no comp requirement is ever a hard block on starting a raid.** The Start Raid button is always enabled.

Instead, every fight declares requirements, and shortfalls apply escalating penalties, surfaced before the player commits.

| Check | Requirement | Shortfall measure | Penalty per unit of shortfall |
|---|---|---|---|
| Tank coverage | `tank_weight ≥ fight.tanks_required` (default 2) | `S = required − tank_weight` | Each round, `ceil(S)` boss single-target attacks retarget to a random non-tank raider, unmitigated by tank AC. Additionally raid-wide mistake chance +5 percentage points per full point of S. |
| Healer coverage | `healers ≥ fight.healers_recommended` (default 3) | `S = recommended − healers` | −25% to all raid healing per missing healer, capped at −75%. |
| Single-target damage | Fight flag `needs_st` | 0 Wizards **and** 0 Monks present | Fight timer pressure: boss enrages (doc 07) 3 rounds earlier. |
| AoE damage | Fight flag `needs_aoe` | 0 Mages present | Trash packs survive 2 extra rounds each, multiplying incoming damage. |
| Roster underfill | `raiders < 12` | `S = 12 − raiders` | No extra penalty. The missing bodies are the penalty. |

Worked example — the week-three raid, where the tavern has produced no Cleric:

| W | Mo | Ro | Cl | Dr | Sh | Ma | Wi | Ba | Total |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 4 | 0 | 2 | 1 | 1 | 1 | 1 | 12 |

- Tank weight = 1.0 (Warrior); the Monk contributes 0 outside its emergency state (6.2). Required 2. Shortfall **1.0** → `ceil(1.0)` = 1 boss attack per round retargets into the raid, unmitigated, **plus** +5 percentage points raid-wide mistake chance (one full point of S).
- Healers = 3 (Druid ×2, Shaman). Recommended 3. **No healing penalty** — but all three are raid/chain healers, so tank-directed throughput is thin. That is not a comp *violation*; it is a comp *shape* problem the player has to feel.
- The lone Monk is not covering the empty tank slot; it is standing by to take over if the Warrior dies.
- Verdict shown to the player: **"Reckless — one tank short: 1 loose boss attack per round, +5% mistakes, and nobody is watching the tank."**

🔷 **PROPOSED — Comp Preview panel.** Before Start Raid, show: role counts, tank weight vs required, each triggered penalty in plain language, and a single verdict word (Ready / Risky / Reckless / Suicidal). The player is allowed to lose; they are not allowed to be *surprised* that they lost. This is the screen that makes a wipe feel like their decision.

### 6.6 Comp vs. recruitment: soft requirements, not hard ones 🔷 PROPOSED

The tension in one line: the player fields 12 from a random pool, so any class the design *requires* is a class the tavern can refuse to give them.

**Recommendation: soft requirements with escalating penalties (as specced in 6.5). No hard class gates anywhere in the game.**

| | Hard requirement | Soft requirement + penalty |
|---|---|---|
| Player without a Cleric | Cannot start. Must wait for tavern rolls. Dead time. | Starts, sees "no dedicated tank healer", probably wipes, learns why. |
| Failure feels | Like the game locked them out | Like they gambled |
| Design cost | Needs a guaranteed-recruit system to be non-broken | Needs penalty tuning |
| Fits canon premise | Poorly — canon is about incompetent people you make do with | Well — "make do with what walks in" *is* the game |

The reasons, ranked:

1. **The premise is making do.** Canon's fantasy is a guild leader with bad options, illustrated in canon's own example: "Oh shit, Steve is at 14. Maybe I shouldn't bring him, unless he really wants to go and I know I can beat the raid with him messing up." That sentence only exists if bringing the bad option is *allowed*.
2. **Hard gates convert a design problem into a waiting problem.** A locked-out player's only verb is refreshing the tavern. That is not gameplay.
3. **Penalties teach; locks do not.** A player who wipes with three raid healers and no Cleric learns what a Cleric is for. A player who was never allowed to try learns nothing.
4. **Duplicate classes stay legal**, for the same reason: four Rogues must be a *bad* comp, never an *illegal* one.

🔷 **PROPOSED — one safety net, not a gate.** Because a total absence of tanks or healers is unrecoverable rather than merely bad, the tavern applies a pity rule: if the roster contains no raider with tank weight ≥ 1.0, or no HEALER_* raider at all, the next tavern refresh guarantees at least one of the missing role. This never guarantees a *specific class* — only that the roster cannot reach an unwinnable state. Tavern refresh cadence and offer count belong to doc 04.

---

## 7. Class availability ❓ OPEN

Canon does not say whether all nine classes are recruitable from the start. What canon does say (canon: raw notes, Guild Reputation):

- At Unknown, "you can only find the worst players to join your guild, they have 0 raid experience etc. (Common raiders)" — a statement about *quality*, not about *class*.
- "You can only ever find 1 Legendary per class - They are also named characters - IE Natsuna(the shaman) or something."

🔷 **PROPOSED — all nine classes recruitable from Unknown.**

| Option | Assessment |
|---|---|
| All 9 from the start | Recommended. Canon gates recruits by *quality* only, so gating by class as well is an invention that adds a second axis of denial on top of an already random pool. |
| Drip-feed classes by reputation rank | Rejected. Six reputation ranks and nine classes means a class arrives roughly every rank, and the player's comp is dictated by unlock order rather than by their own choices. It also makes the two-tank requirement unmeetable if Warrior is not rank-one. |
| All 9, but weight tanks and healers rarer | Rejected as the default. It is the same soft-lock as a hard gate, just probabilistic and therefore harder for the player to read. |

🔷 **PROPOSED — offer weighting.** Uniform-ish across the nine classes, with the 6.6 pity rule as the only correction. If tuning later shows the player drowning in Rogues, adjust weights — but keep every class reachable at every rank.

### 7.1 Interaction with the one-Legendary-per-class rule

✅ CANON: one Legendary per class, ever, and they are named characters (canon: raw notes, Guild Reputation; Legendary recruits appear at Renowned at "near 1% chance of mistake"). Details in [03 — Guild Reputation & Unlocks](03-guild-reputation.md) and [04 — Recruitment & Roster](04-recruitment-and-roster.md).

Consequences that land on *this* doc:

| # | Consequence |
|---|---|
| 1 | There are at most **9 Legendary raiders in the entire game** against **12 raid slots**. A fully Legendary raid is mathematically impossible. At least 3 slots are always fallible. This is a good property and should be treated as intentional. |
| 2 | There is exactly **one Legendary Warrior**. Since standard comps run two tanks, the second tank is always non-Legendary — so Lost Aggro (4.1) never fully leaves the game. |
| 3 | Duplicate-class comps (template C's three Mages) get exactly one Legendary Mage and two ordinary ones, which naturally caps how safe a stacked comp can be. No extra rule needed. |
| 4 | ❓ OPEN — if a class were gated behind a reputation rank, its Legendary would be gated too, and a player could pass Renowned before ever being able to roll that class's Legendary. This is the strongest argument for 7's "all nine from the start" proposal. |
| 5 | ❓ OPEN — is there a Legendary Bard? Canon's example Legendary is "Natsuna(the shaman)". A Legendary Bard cannot be designed until section 5 resolves. |

---

## 8. Quick reference: class × role × primary stat × armor family

Role column is ✅ CANON verbatim. Armor / Head / Main Hand / Off Hand columns are ✅ CANON from the ideaboard slot matrix (§1). Primary and Secondary stat columns are 🔷 PROPOSED, derived from the kits in section 4.

| Class | Role (canon) | Primary | Secondary | Chest/Legs/Feet family | Head family | Main Hand | Off Hand |
|---|---|---|---|---|---|---|---|
| Warrior | Main Tank | AC | HP, Power | Warrior/Bard | Warrior | Warrior/Rogue/Bard 1H | Warrior Shield |
| Monk | Melee DPS / Offtank | Power | AC, HP | Monk/Rogue | Monk Headband | 2H Monk Weapon | — |
| Rogue | Melee DPS | Power | HP | Monk/Rogue | Rogue Eyepatch | Warrior/Rogue/Bard 1H | Warrior/Rogue/Bard 1H |
| Cleric | Main Tank Healer | Mana ❓ | HP | Healer | Healer | Cleric Weapon | Healer Off-Hand |
| Druid | Raid Healer | Mana ❓ | HP | Healer | Healer | Druid Weapon | Healer Off-Hand |
| Shaman | Chain Healer (bouncing heal) | Mana ❓ | HP | Healer | Healer | Shaman Weapon | Healer Off-Hand |
| Bard | Support | Mana ❓ | Power ❓ | Warrior/Bard | Warrior/Bard | Warrior/Rogue/Bard 1H | Instrument |
| Mage | AoE Caster | Mana | HP | Mage/Wizard | Mage/Wizard | 2H Mage Staff | — |
| Wizard | Single-Target Caster | Mana | HP | Mage/Wizard | Mage/Wizard | 2H Wizard Staff | — |

### 8.1 Cross-check against the ideaboard equipment matrix

Verified against ideaboard §1, §2.5 and §3. Findings that affect class design:

| # | Finding |
|---|---|
| 1 | ✅ CANON — AC ordering by armor family at Tier 1 Adventure is Warrior/Bard 15 > Monk 14 > Rogue 13 > Healer 9 > Mage/Wizard 8. This ordering is what makes Lost Aggro (4.1) and Overpull (4.7) lethal rather than annoying: the classes standing behind the tank have roughly half its AC. |
| 2 | ✅ CANON — Power appears on **no** Tier 1 Adventure armor piece and only begins on Tier 1 Raid armor (ideaboard §5). Melee classes are therefore weapon-damage-only for the whole Adventure tier. Doc 09 owns whether that is intended. |
| 3 | ✅ CANON — the Healer armor family is shared by Cleric, Druid and Shaman with identical stats, so all three healers compete for every armor drop while their **weapons** are class-specific (Cleric Weapon / Druid Weapon / Shaman Weapon at Boss 5). Running three different healers therefore costs armor contention but no weapon contention. |
| 4 | ✅ CANON — Bard's Head is `Warrior/Bard` while Warrior's Head is `Warrior` alone (ideaboard §1), yet the raid tables give Bard the identical `Raider's Helm — 5 AC / +5 HP / +1 Power` as the Warrior (§3.1, §3.2). Flagged, not resolved — see Open Questions #4. |
| 5 | ✅ CANON — Bard's only Mana source in the entire Tier 1 Raid table is the Boss 5 `Bard Instrument — +20 Mana`. Under the section 5.3 recommendation, a Bard has effectively no primary stat until the final boss of the tier drops. That is a real problem for the tier's pacing and it belongs to doc 09's itemization pass. |
| 6 | ✅ CANON — Monk and Rogue share `Monk/Rogue` armor per the matrix, and their Legs and Feet drops are byte-identical (`Raider's Leggings — 5 AC / +6 HP / +1 Power`, `Raider's Boots — 4 AC / +4 HP`), but their Chest drops have different names with identical stats (`Raider's Vest` vs `Raider's Leather Vest`, both 6 AC / +7 HP / +2 Power). See Open Questions #5. |

---

## 9. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| 1 | Canon defines Mana as "spell damage (Subject to change)", but Cleric/Druid/Shaman gear is loaded with Mana and they deal no damage. Does Mana also drive healing, or do healers need a separate stat? | Decides the scaling stat for three of nine classes, and whether healer weapons carry "mana or power" as canon says is unsure. Blocks all healer tuning. | RULED ([08 §5.3](08-stats-and-formulas.md), [15 Q-02](15-open-questions.md#q-02) / [BL-87](15-open-questions.md#bl-87)): Mana drives both spell damage and healing magnitude; no fourth *gear* stat; one class-fixed resource (Focus) that never appears on gear, DECIDED for 1.1 and not in 1.0. |
| 2 | Canon says Rogue DPS is "position-dependent" but no positioning system exists in either canon source. Is positioning Rogue-local or a global combat concept? | If global, doc 07 needs a position model for all 12 raiders and every boss mechanic. If Rogue-local, it is a two-state flag and costs nothing. | Rogue-local Behind/Front flag (4.5). Revisit if any boss mechanic needs real positions. |
| 3 | What do Bard songs do? Canon says "Random song effects TBD". | The Bard is 1/9 of the roster and 1 of 12 raid slots, and its stat scaling cannot be decided first. | Section 5.3: B1 mechanic (d6 song table) with B3 stat model (Mana = magnitude, Power = small auto-attack). |
| 4 | Are duplicate classes allowed in one raid? Canon never says. | With one dedicated tank class and a canon two-tank requirement, forbidding duplicates makes the canon requirement unmeetable without a Monk. | Allowed and unpenalised. Non-stacking effects (Mage raid spell buff) handle the balance. |
| 5 | Are all nine classes recruitable at Unknown reputation? | Determines whether early comps are the player's choice or the unlock table's, and gates access to each class's unique Legendary. | Yes, all nine from the start (section 7), with the pity rule in 6.6 as the only correction. |
| 6 | How many tanks does a fight *actually* require? Canon says "most fights normally requiring 2 tanks" — "most" and "normally" are load-bearing hedges. | Every comp check reads `fight.tanks_required`. If some fights want 1 or 3, the comp checker must be per-fight, not global. | Per-fight `tanks_required` field, default 2. Tutorial and Adventure 0 default to 1. |
| 7 | Can a Monk hold the second tank slot pre-emptively, or only after the primary tank dies? Doc 07 §8.3 makes Guard an emergency state and its OQ-3 default is Warrior + Warrior; canon says "emergency tank". | Sets whether a one-Warrior roster is a 1.5-tank comp or a one-tank comp, and therefore how punishing the normal early-game state is. Owned jointly with doc 07 OQ-3 — one answer, both docs. | Emergency-only, tank weight **0** (6.2). A one-Warrior raid runs a tank short and pays 6.5's full penalty; the Monk is the backstop, not the substitute. If doc 07 OQ-3 flips to a designated Monk offtank, change doc 07 §8.3's trigger to `living tanks < fight.tanks_required` and this doc's Monk weight together. |
| 8 | Does a Legendary Bard exist? | Canon caps Legendaries at one per class; if Bard's design does not resolve, its Legendary cannot be authored. | Yes, but author it last, after Open Question #3 closes. |
| 9 | Do healers generate threat? | Decides whether a Cleric can be pulled off the tank by its own healing, and whether Lost Aggro can land on a healer. | Yes, at a low multiplier. Doc 07 owns the number. |

---

## Related documents

- [03 — Guild Reputation & Unlocks](03-guild-reputation.md) — the reputation ranks that gate which recruit tiers appear in the tavern, and where the one-Legendary-per-class rule lives.
- [04 — Recruitment & Roster](04-recruitment-and-roster.md) — owns mistake *chance* per raider; this doc only owns what a mistake *does*.
- [07 — Combat Simulation](07-combat-simulation.md) — round order, threat table, targeting, boss mechanics, and the combat log that has to make every failure mode in section 4 readable.
- [08 — Stats & Formulas](08-stats-and-formulas.md) — turns "medium → medium → small" and "+S per 10 Mana" into real numbers.
- [09 — Items & Itemization](09-items-and-itemization.md) — the armor families and stat blocks referenced in section 8, and the Bard Power-vs-Mana itemization problem from section 5.
- [14 — Technical Architecture](14-technical-architecture.md) — the Godot-side data shape the kit template in section 3 has to serialize into.
