# 00 — Vision & Design Pillars

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs what *A Guild Story* is, who it is for, the five pillars every other design doc must answer to, and the things this game explicitly refuses to be.

---

## 1. Scope

**This doc owns:**

| Owns | Meaning |
|---|---|
| The player fantasy | The one sentence the whole game serves |
| Design pillars | The 5 tests any feature must pass |
| Relationship to *It's A Wipe!* | What is kept, what is ours, what is required scope |
| Target player | Three named audiences and the pitch line for each |
| Scope & platform | Platform, session shape, content volume envelope |
| Anti-goals | What we refuse to build, so we stop re-litigating it |
| Success criteria | What "this works" means at vertical slice and at 1.0 |

**This doc does NOT own** — one line each, follow the link:

| Not owned here | Owner |
|---|---|
| Session pacing — how long an attempt, a town cycle and a tier take | [01 — Core Loop & Session Flow](./01-core-loop.md) |
| Town buildings, unlock order, facility upgrades | [02 — The Town & Its Buildings](./02-town-and-buildings.md) |
| Reputation rank effects and what each rank changes in town | [03 — Guild Reputation](./03-guild-reputation.md) |
| Recruit rarity rolls, the tavern pool, roster capacity | [04 — Recruitment & Roster Management](./04-recruitment-and-roster.md) |
| Morale numbers, bands, and back-story triggers | [05 — Morale](./05-morale.md) |
| The 9 classes, their roles, and the 12-slot composition rules | [06 — Classes, Roles & Raid Composition](./06-classes-and-roles.md) |
| Round structure, turn order, targeting, mechanics, mistake resolution | [07 — Raid Simulation & The Mistake System](./07-combat-simulation.md) |
| Stat definitions, the formula set, mistake-chance arithmetic, tuning levers | [08 — Stats, Formulas & Numeric Model](./08-stats-and-formulas.md) |
| Every item name and stat block | [09 — Items & Itemization](./09-items-and-itemization.md) |
| Encounter ladder, boss design, drop slots | [10 — Content Structure: Adventures, Raids & Encounters](./10-content-and-encounters.md) |
| Money, shop pricing, crafting and salvage | [11 — Economy, Shops & Crafting](./11-economy-and-crafting.md) |
| Sprites, palette, post-processing, the 2D-HD look | [12 — Art Direction & Aseprite Pipeline](./12-art-direction.md) |
| Screen layouts, the roster row's presentation, accessibility | [13 — UI/UX & Frontend Design](./13-ui-ux.md) |
| Engine choice, target hardware, build pipeline | [14 — Technical Architecture (Godot)](./14-technical-architecture.md) |

### 1.1 Canonical document index

✅ ADOPTED — this table **is** the set map Q1 asked about, and Q1 is now resolved (§9). These filenames are the shipped ones; every other doc's cross-references are corrected to match this table, and no doc renegotiates the numbering. Doc 13 OQ-10 and doc 11 Q9 both asked for this pass; it is owned here.

| # | File | Owns |
|---|---|---|
| 00 | `00-vision-and-pillars.md` | Vision, pillars, anti-goals, scope envelope, success criteria |
| 01 | `01-core-loop.md` | Core loop and session pacing at all three timescales |
| 02 | `02-town-and-buildings.md` | The town, the five canon buildings, unlock order |
| 03 | `03-guild-reputation.md` | The 6-rank Reputation ladder and its effects |
| 04 | `04-recruitment-and-roster.md` | Recruitment, recruit rarity, roster management |
| 05 | `05-morale.md` | Morale 0-100, bands, triggers, leave/disband rolls |
| 06 | `06-classes-and-roles.md` | The 9 classes, raid roles, 12-slot composition |
| 07 | `07-combat-simulation.md` | Raid simulation, round structure, the mistake system |
| 08 | `08-stats-and-formulas.md` | Stat definitions, formulas, numeric model, tuning levers |
| 09 | `09-items-and-itemization.md` | Items, slots, drop tables, itemization model |
| 10 | `10-content-and-encounters.md` | Adventures, raids, encounters, the content ladder |
| 11 | `11-economy-and-crafting.md` | Money, shops, crafting, salvage |
| 12 | `12-art-direction.md` | Art direction, sprite pipeline, the 10-frame morale face sheet |
| 13 | `13-ui-ux.md` | Screen layouts, UI flows, accessibility |
| 14 | `14-technical-architecture.md` | Godot architecture, data pipeline, build and export |

---

## 2. The fantasy

You are the guild leader. You are not in the raid.

You run a guild of people who are bad at this. You find them in the tavern, you put armour on them, you keep them from quitting, and you send them at a boss knowing — with real numeric confidence — roughly how badly they are going to screw it up. ✅ CANON: the premise is a guild-management game about incompetent raiders, and the raider's competence is expressed as a mistake chance that morale modifies (canon: raw notes, Morale: 0-100).

**The specific emotional beat this game is built around** is the roster screen the notes sketch out verbatim (canon: raw notes, Morale section):

```
Natsuna — 87 ❤️        Bob — 54 🙂        Greg — 31 😒        Steve — 14 😡
Shaman — Very Happy    Warrior — Content  Rogue — Annoyed     Mage — Upset
```

And the thought the notes say the player has, quoted exactly:

> "Oh shit, Steve is at 14. Maybe I shouldn't bring him, unless he really wants to go and I know I can beat the raid with him messing up."

✅ CANON — That is the game. Not the raid, not the loot table: the two seconds where you look at a number next to a person's name and decide whether to bench him. The notes call this "very appropriate for the guild-leader fantasy" (canon: raw notes, Morale section). Everything else in this project exists to make that decision matter more: the loot exists so benching Steve costs you a Mage-shaped hole in the raid; the town exists so the raid you're benching him for is one you spent money to unlock; the reputation ladder exists so that at Unknown rank, Steve at 14 is the *only* Mage you have. ✅ CANON on the ladder (canon: raw notes, Guild Reputation); 🔷 PROPOSED on the causal framing.

**The three-sentence pitch:**

> Your guild is terrible. Keep them happy enough to function, gear them well enough to survive their own mistakes, and turn the reputation you earn into a town that finally sends you someone competent. You will never once press an ability button.

---

## 3. Design pillars

Five pillars. Each has an intent line, a **says no to** clause (the pillar's real job — killing features), and a build test a programmer or designer can actually apply in review.

### Pillar 1 — The town is the progression bar

✅ CANON (canon: raw notes, Town as progression engine — "Instead of the guild simply being a menu between raids, make the town itself your progression engine.")

- **Why this exists:** Progress is legible as *place*, not as a level number. Raids raise Guild Reputation; Reputation unlocks what appears around town; a richer town produces better raiders, better goods, and better missions.
- **This pillar says no to:** a guild screen that is a menu with buttons. It says no to any progression reward that is only a stat increase with no visible change in the town. It says no to unlocking content directly from a boss kill when the same unlock could route through Reputation.
- **Build test:** for every reward in the game, name the building it changes. If you cannot, it is the wrong reward.
- **Canon anchors:** Guildhall, Tavern, Market, Blacksmith (Maybe), Adventure's Board (canon: raw notes, Town as progression engine); "New Tiers can be unlocked by gaining reputations with the town."

### Pillar 2 — One number per raider

✅ CANON (canon: raw notes, Morale — "the morale system itself stays extremely simple: one number, one state, one effect")

- **Why this exists:** The player reads a roster of up to a dozen people in one glance. One 0-100 morale value, one named state, one gameplay effect. Guild Reputation is the same idea one level up: "Your guild has a single primary stat: **Guild Reputation**" (canon: raw notes, Guild Reputation).
- **This pillar says no to:** a second morale-like axis (loyalty, stress, fatigue, trust, relationships-with-other-raiders). It says no to hidden morale sub-scores. It says no to a morale UI that needs a tooltip to be read.
- **Build test:** can the roster row be rendered as `Name — NN <face>` plus class and state, and can the player predict the raid consequence from that alone? If a feature breaks that row, the feature loses.
- **Watch item:** ❓ OPEN — the stat set (AC / Power / Mana) is not yet settled at this level of discipline. Canon says "Mana = spell damage (Subject to change)" and, on healer weapons, "we need to discuss if we want to have 2 variables or not" (canon: raw notes, Stat definitions; Weapons). Pillar 2 argues for one, not two. Decision belongs to [08 — Stats, Formulas & Numeric Model](./08-stats-and-formulas.md) §5.3.

### Pillar 3 — Complexity lives in stories, not systems

✅ CANON (canon: raw notes, Morale — "The complexity comes from the stories and decisions surrounding it.")

- **Why this exists:** Depth is bought with content, not with mechanics. The mechanic is a number going up and down. The reason it moves is a person: "Gaining and losing Morale will be based on their back stories largely we can have bullet points for each raider that is recruited" (canon: raw notes, Morale). Lower-tier raiders are hardest to keep happy; Legendary raiders are hard to upset (canon: same).
- **This pillar says no to:** a new subsystem where a new back-story trigger, wishlist item, or event would do the job. It says no to mechanical solutions to flavour problems.
- **Build test:** the fix for "morale feels flat" is more written triggers per raider, not a morale decay curve rewrite. If a proposal adds a system, it must show why a content answer cannot work.
- **Canon anchor:** ❓ OPEN — "We could have raiders also know their bis and occasionally wishlist items for bonus morale. This is all just concepts and can easily be revisited" (canon: raw notes, Morale). Wishlists are a candidate, not a commitment.

### Pillar 4 — You manage, you do not play the raid

✅ CANON by derivation — the notes describe every player verb as a management verb and never once give the player a combat input (canon: raw notes, Core things to do — "You earn money. You spend money at the blacksmith/Merchant. You recruit people at the tavern as needed. You take missions from the adventure board. You improve the guild/raid team.")

- **Why this exists:** All player agency is spent *before* the raid — who goes, what they wear, what consumables they carry, whether they are happy enough to go at all. The raid then resolves and you watch what your decisions were worth. The 12-raider size (canon: raw notes, Classes — "I'd like the raid size to be 12, most fights normally requiring 2 tanks") is a roster-composition puzzle, not a control load.
- **This pillar says no to:** clicking abilities, targeting, interrupts, positioning during the fight, pausing to issue orders, "just one" quick-time event. It says no to any raid UI element that is a button the player must press to win.
- **Build test:** if you unplug all input during raid resolution, does the raid still play correctly to a result? It must.
- **Boundary:** ❓ OPEN — whether the player can retreat, re-slot, or spend a consumable mid-raid is not addressed in canon. Pillar 4's default is no. See §9, Q3.

### Pillar 5 — Failure is the content, not the fail state

🔷 PROPOSED — this pillar is derived from the premise, not stated in canon. Sign-off needed.

- **Why this exists:** The premise is a guild of people who make mistakes. A mistake must therefore be *interesting to watch and attributable to a person*, not just a hidden damage penalty. Greg missing a move you can name and blame is the game's comedy engine and its feedback channel — it tells the player what to fix in town.
- **This pillar says no to:** silent DPS multipliers standing in for mistakes. It says no to wipes that the player cannot trace to a specific raider and a specific decision they made in the guildhall. It says no to punishing failure with a hard loss of progress (see anti-goals).
- **Build test:** after any wipe, the post-raid screen can name the raider, the mistake, and the town action that would have prevented it.
- **Canon support:** the mistake chance is the single mechanical output of morale across all ten bands (canon: raw notes, Morale table), and raider rarity is defined by mistake frequency — "only make mistakes sometimes" (rare), "rarely make a mistake" (epic), "near 1% chance of mistake" (Legendary) (canon: raw notes, Guild Reputation).

**Pillar conflict order** — 🔷 PROPOSED. When two pillars collide, resolve in this order: 4 (you manage) > 2 (one number) > 1 (town) > 3 (stories) > 5 (failure). Rationale: 4 and 2 define the genre and the readability of the core screen; breaking either produces a different game. 5 is the most negotiable because it is a presentation promise.

---

## 4. Relationship to *It's A Wipe!*

Stated plainly, because the team needs to plan around it rather than around a euphemism.

✅ CANON, verbatim (canon: raw notes, Premise):

> "Clone of *It's A Wipe!* by Parody Games LLC, rebuilt with a 2D-HD aesthetic similar to *Octopath Traveler*."

### 4.1 What is being kept

| Kept | Source |
|---|---|
| Premise: you manage a guild of incompetent raiders rather than raiding yourself | ✅ CANON (Premise) |
| The loop: roster → morale → gear → send at a boss → loot → repeat | ✅ CANON (Core things to do) |
| Raider-quality-as-progression and morale management as the central pressure | ✅ CANON (Morale; Guild Reputation) |

### 4.2 What is genuinely ours

| Ours | Status | Source |
|---|---|---|
| 2D-HD presentation in the *Octopath Traveler* register; "really awesome frontend design" as a stated priority | ✅ CANON | raw notes, Premise; Direction given alongside the notes |
| The town as the progression engine — Guildhall, Tavern, Market, Blacksmith, Adventure's Board, each unlocking and upgrading | ✅ CANON | raw notes, Town as progression engine |
| A 6-rank Guild Reputation ladder (Unknown → Known → Respected → Established → Renowned → Legendary) that gates *recruit quality*, not just content access | ✅ CANON | raw notes, Guild Reputation |
| Named, unique Legendary raiders — one per class, ever ("IE Natsuna(the shaman)") | ✅ CANON | raw notes, Guild Reputation |
| 9 classes with defined raid roles, in a 12-raider raid built around 2 tanks | ✅ CANON | raw notes, Classes |
| A five-encounter tier structure with a fixed slot-per-encounter drop pattern | ✅ CANON | raw notes, Raid Layout; ideaboard §4 |
| Per-raider back-story bullet points as the source of morale movement | ✅ CANON (concept), ❓ OPEN (extent) | raw notes, Morale |

### 4.3 Recommendation: treat the differentiators as required scope

🔷 PROPOSED — the four items below move from "nice-to-have" to **must-ship**, on the same footing as the raid loop:

1. Town-as-progression-engine (all five buildings, with Reputation-gated unlocks).
2. The Reputation ladder gating recruit rarity.
3. The 9-class / 12-slot raid composition puzzle.
4. 2D-HD presentation to the stated quality bar.

**Why, in build terms rather than moral ones:** a clone that reproduces the loop and changes only the art has one axis of quality — art — and competes directly on the original's strongest ground. A clone whose *progression structure* is its own has a different shape of game to review, to market, and to iterate: the town, the ladder, and the composition puzzle are where our content budget compounds, and they are what makes our tier-2 content a different job from re-skinning tier-1. Cutting them under schedule pressure does not produce a smaller version of this game; it produces a re-skin. So they should be scheduled, not deferred.

### 4.4 Production constraint

🔷 PROPOSED — binding on all content authoring from day one:

- All names, art, copy, audio, and UI text are original to this project. No assets, strings, tables, or text are taken from *It's A Wipe!*.
- Where canon reuses a generic MMO term (Warrior, Cleric, morale, wipe), that is generic vocabulary, kept.
- Placeholder names in canon (Raid 1, Adventure 2, Boss 3) are placeholders; final naming is pending and is an original-naming task, not a translation task (canon: raw notes, Adventure's Board — "obviously they will need names later, but this is a placeholder").
- ❓ OPEN — whether a formal rights review happens, and when, is a team decision. This document does not give legal advice and does not make that call; it only flags that original naming/art/copy is a production constraint the content pipeline must assume from the start.

**The three items below make the constraint checkable rather than aspirational.** They are process and provenance items, not a legal opinion; the disclaimer above still stands.

#### 4.4.1 The originality audit — the procedure behind R8

🔷 PROPOSED. §8.2 R8 currently asserts an audit with no owner, checklist or timing. It gets all three:

| Item | Value |
|---|---|
| Owner | Design lead (the doc-set owner), signed off once per milestone — not delegated to whoever is exporting |
| Timing | At vertical-slice sign-off, then as a **pre-export gate** on every release build |
| Checklist | (1) every shipping string in the strings table; (2) every item, class, building, encounter and boss **name**; (3) every asset **filename** and directory name; (4) every sprite's authorship — who drew it, from what reference; (5) all audio; (6) all store, README and marketing copy (§4.4.2) |
| Pass condition | Each of the six categories has a named author or a recorded original-work provenance. Anything unattributed fails the gate |
| Recorded where | A checked-in manifest, one row per asset/string family, diffable so the audit is incremental after the first pass |
| Cross-reference | This gate must be added to [14 — Technical Architecture](./14-technical-architecture.md) §10.1's pre-export gate list, which currently omits it |

#### 4.4.2 How the game may describe itself publicly

🔷 PROPOSED. §5 already assumes store copy exists, and the ✅ CANON premise line names *It's A Wipe!* and Parody Games LLC — so the rule must be stated rather than left to whoever writes the page:

- The premise line in `_source/` is an **internal** design statement. It is canon for the design docs and is never shipped copy.
- Marketing, store copy, the README, trailers and press material describe the game **only on its own terms** — guild management, incompetent raiders, morale, the town. They do not name *It's A Wipe!* or Parody Games LLC, and do not use "clone of", "inspired by", "like X but", or a comparison shot.
- Genre framing is fine and expected: "guild-management sim", "auto-resolving raids", "management roguelite-adjacent". Naming a comparison title in copy is not.
- This is a positioning decision as much as a caution: §4.3's whole argument is that our differentiators are the product, and copy that leads with the original concedes that ground.

#### 4.4.3 Provenance of the ideaboard screenshots

❓ OPEN — see §9, Q14. `_source/ideaboard-transcription.md` records only that the nine screenshots were "provided by the lead designer", [14](./14-technical-architecture.md) §10.3 commits `ideaboard/` to the repo as canon source alongside the design docs, and §4.4 above specifically bans taking *tables* from the original. The entire Tier 1 item corpus derives from those nine images, so their authorship must be recorded before the corpus is treated as ours.

---

## 5. Target player

| Audience | Who they are | Pitch line |
|---|---|---|
| **Ex-raiders / lapsed MMO players** | People who ran a guild, or suffered one. They recognise Steve at 14 immediately. | "You already know this guy. Now you get to bench him." |
| **Management-sim players** | *Football Manager*, *Rimworld*, *Two Point*, *Blood Bowl* coaches. They want a roster, constraints, and consequences — not twitch. | "A roster of nine specialists, twelve slots, and one number that tells you who is about to cost you the raid." |
| **Idle / auto-battler audience** | *Loop Hero*, *Slice & Dice*, TFT, auto-chess players. They enjoy setting up and watching it resolve. | "Build the team, press go, and find out what your decisions were worth." |

🔷 PROPOSED — primary audience is **management-sim players**; ex-raiders are the loudest early adopters and the source of word-of-mouth, but they are a smaller pool and their expectations skew toward MMO fidelity, which Pillar 4 refuses. The idle/auto-battler audience sets our expectations for readability of the resolution screen: they will watch it hundreds of times.

🔷 PROPOSED — **not** the target: players who want to raid. If they only want a raid, we are the wrong product and should say so in the store copy rather than losing them in hour two.

---

## 6. Scope & platform

🔷 PROPOSED — all of §6. Canon states only "Likely engine: Godot" and "Aseprite is in the project root" (canon: raw notes, Direction given alongside the notes).

### 6.1 Platform

| Item | Proposal | Note |
|---|---|---|
| Primary platform | PC (Windows first) | Aseprite is vendored in-repo at `Aseprite/Aseprite.exe`; toolchain is already Windows-shaped |
| Engine | Godot | ✅ CANON says "Likely" — see [14](./14-technical-architecture.md) for the actual decision |
| Input | Keyboard + mouse | Mouse-first; full keyboard navigation of every menu as a hard requirement |
| Mode | Single player, offline, no account | |
| Monetisation | Premium, one purchase, no live service | No gacha, no battle pass, no ads, no telemetry-driven tuning |
| Resolution target | 1920×1080 native, scaling to 2560×1440 and 3840×2160 | 2D-HD needs a fixed pixel-art layer at a known scale; see [12](./12-art-direction.md) |
| Later platforms | Steam Deck as a stretch goal; consoles out of scope for 1.0 | Deck implies gamepad nav, which the keyboard requirement mostly buys us |

### 6.2 Session shape

| Item | Proposal |
|---|---|
| Session length | 20-40 minutes: a town pass, a roster pass, one or two runs |
| Save model | Single continuous save per guild slot, autosaved on every town transition and after every encounter resolution |
| Run length | Adventure ≈ 3-4 min; a full 5-encounter raid **attempt** ≈ 3-8 min of sim ([01](./01-core-loop.md) §3.1's micro loop); 10-20 min for a **town cycle** containing 1-3 attempts ([01](./01-core-loop.md) §3.2); resumable between encounters |
| Fail state | A wipe costs time, consumables, morale, and repair/replacement money — never the save (see anti-goals) |

> **Dependency, stated so it stops drifting:** [01](./01-core-loop.md) owns session pacing; this row restates its numbers and must not diverge from them. [10](./10-content-and-encounters.md) §5.2's 4 s round-length constant is back-solved from doc 01's 3-8 min attempt across 5 encounters, and every encounter's `target_rounds`, `hp_total = 70 × target_rounds` and `enrage_round` follows from it. An earlier draft of this row read "a full 5-encounter raid ≈ 10-20 minutes", which would put a round at ~8-15 s and roughly double every HP figure in doc 10 §5.4, §7 and §8. That reading is **withdrawn**: 10-20 min is the town cycle, not the attempt.

### 6.3 Content volume envelope, derived from the canon ladder

The ladder, ✅ CANON verbatim (canon: raw notes, Adventure's Board): Adventure 0 · Tutorial Raid · Adventure 1 · Raid 1 · Adventure 2 TBD · Raid 2 · Adventure 3 · Raid 3 · Adventure 4 · Raid 4 · Adventure 5 · Raid 5, with the note "This continues or can go raid raid, adventure adventure".

🔷 PROPOSED 1.0 scope: **ship the ladder exactly as listed and stop at Raid 5.** That gives a countable envelope:

| Quantity | Count | Derivation |
|---|---|---|
| Ladder entries | 12 | Canon list, Adventure 0 through Raid 5 |
| Raid tiers | 5 | Raid 1 - Raid 5 |
| Raid encounters | 25 | 5 tiers × 5 encounters (canon: Raid Layout — Trash, Harder trash, Mini boss, Mini boss, Main boss) |
| Adventures | 6 | Adventure 0 - Adventure 5 |
| Tutorial raids | 1 | Tutorial Raid, 1 boss |
| Adventure encounters | ~20 | Adventure 0 = 1 trash mob ✅ CANON; Adventure 1 = "a few trash encounters and a mini boss" ✅ CANON; Adventures 2-5 estimated at 4 each 🔷 |
| Classes | 9 | ✅ CANON, Classes table |
| Raid slots | 12 | ✅ CANON, "raid size to be 12" |
| Reputation ranks | 6 | ✅ CANON, Unknown → Legendary |
| Recruit rarities | 5 | ✅ CANON — Common, uncommon, rare, epic, Legendary |
| Unique named Legendary raiders | 9 | ✅ CANON — "You can only ever find 1 Legendary per class" |
| Distinct items, Tier 1 only | ~84 | Counted from canon: 19 starting-armor pieces + ~25 Tier 1 Adventure items + ~40 Tier 1 Raid items (ideaboard §2, §3; raw notes Starting armor, Weapons, Trinkets) |
| Distinct items, 1.0 | ~350-450 | Tier 1 count × 5 raid tiers, minus reuse across the 5 shared armour families 🔷 |
| Buildings | 5 | ✅ CANON — Guildhall, Tavern, Market, Blacksmith (Maybe), Adventure's Board |

🔷 PROPOSED cut lines, in the order they should be cut, if the item count above proves unaffordable: (1) Blacksmith crafting and salvage — canon already marks these "Maybe" / "If we do crafting"; (2) raider level-ups and training — canon marks "Train raiders < Maybe if we have level ups"; (3) Raid 5 and Adventure 5, shipping a 4-tier ladder. Do **not** cut from §4.3.

### 6.4 Difficulty modes and assist options

🔷 PROPOSED — the position, taken here because nothing in the set takes it and it is expensive to retrofit after the sim is balanced against a single tuning set. Note that everywhere else in the docs "difficulty" means the per-encounter ★ rating (✅ CANON: raw notes, Raid Layout), which is a content label, not a player setting. This is the other thing.

**Position: one default difficulty, plus one named assist option.** Not a preset ladder (Easy/Normal/Hard), which would triple the balance surface and force every table in [10](./10-content-and-encounters.md) to be swept three times.

| Item | Proposal |
|---|---|
| Default | A single tuned difficulty. All canon numbers, all balance sweeps, and all pacing targets are stated against it |
| Assist option | One toggle — working name **Forgiving Guild** — off by default, switchable at any time, no achievement or content gating attached |
| What it scales | Raider mistake chance and boss HP, via a single multiplier, so it needs one lever and not a second balance pass |
| What it does *not* touch | Morale bands, recruit rarity, drop tables, prices, the ladder — nothing that would make a save's numbers incomparable |
| Why it exists | Two named spirals in the design have no player-side relief valve: [03](./03-guild-reputation.md) §8's Recruit Quality Spiral (whose mitigations M1-M3 are all invisible and automatic) and [05](./05-morale.md) §8's morale spiral, where one wipe pushes a Common into a higher mistake band. A player who is inside either has no way out that the game admits to |
| Relationship to accessibility | [13](./13-ui-ux.md) §13's accessibility floor is presentation-only; its two optional aids (`log_manual_advance`, emoji-free mode) do not touch difficulty. This row is the difficulty half, and is *not* a substitute for that floor |
| Implementing lever | Cross-reference only, not owned here: [08](./08-stats-and-formulas.md) §11 needs a `DIFFICULTY_MULT` lever applied to `BASE_MISTAKE` and boss HP, with a safe range, and [14](./14-technical-architecture.md) §9.3's balance sweep must report clear rates per setting. §11's current lever list has no global difficulty knob at all |

Rejected alternative, recorded so it is not re-argued: an explicit anti-goal "no difficulty presets" was considered. It was not taken because the two spirals above are structural, not tuning artefacts — refusing any relief valve makes them a design flaw rather than a stated choice.

---

## 7. Anti-goals

What this game refuses to be. Each line is a decision already made, so it does not get re-argued in review.

| # | Anti-goal | Why | Authority |
|---|---|---|---|
| A1 | Not a real-time raid game | Pillar 4. All agency is pre-raid. | ✅ CANON by derivation (Core things to do) |
| A2 | No player-controlled raider abilities | Pillar 4. The player never targets, casts, interrupts, or repositions. | Pillar 4 |
| A3 | No twitch input, no QTEs, no reflex checks | Pillar 4; also excludes the management-sim audience if broken | Pillar 4 |
| A4 | Not an MMO, not multiplayer, no co-op, no online | Single-player offline is the whole product | 🔷 PROPOSED §6.1 |
| A5 | Not a gacha; no loot boxes, no premium currency, no energy timers | Recruit rarity is gated by Reputation earned in play, not by spend | ✅ CANON (Guild Reputation gates rarity) |
| A6 | No permadeath of the save, no roguelike run wipe | A wipe is a setback the player recovers from in town, not a reset | 🔷 PROPOSED |
| A7 | No second morale-like stat | Pillar 2 | ✅ CANON ("one number, one state, one effect") |
| A8 | No player avatar in the raid, no "guild leader joins the fight" mode | You are the leader, not a raider | Pillar 4 |
| A9 | Not a comedy game about nothing — the jokes are the mechanics reporting themselves | Pillar 5; a mistake the player cannot trace is not funny, it is noise | 🔷 PROPOSED |
| A10 | No procedurally generated raid encounters for 1.0 | Encounters are hand-authored; the drop-slot pattern per encounter is canon and specific | ✅ CANON (Raid Layout; ideaboard §4) |
| A11 | No always-online, no accounts, no telemetry required to play | | 🔷 PROPOSED |
| A12 | Not a re-skin — see §4.3 | The differentiators are required scope | 🔷 PROPOSED |

**Guarded exception to A6:** ✅ CANON says morale 0-10 "may cause guild disband" (canon: raw notes, Morale table). Disband is a *canon* consequence and is therefore not covered by A6. ❓ OPEN — whether disband ends the save or is a recoverable catastrophe is undecided. See §9, Q4.

---

## 8. Success criteria

🔷 PROPOSED — all of §8. These are the acceptance gates, written so they can be tested rather than felt.

### 8.1 Vertical slice

The slice is: **the town at Reputation `Unknown` and `Known`, plus Adventure 0, the Tutorial Raid, Adventure 1, and all five encounters of Raid 1.** Tier 1 is fully specified in canon, so the slice needs no invented numbers.

| # | Criterion | How it is tested |
|---|---|---|
| VS1 | A new player reaches the roster screen and, unprompted, benches or brings a low-morale raider on purpose | Playtest, think-aloud. Target: 8 of 10 testers name the morale number as their reason |
| VS2 | The roster row is readable at a glance | Tester correctly reads name, class, morale value and state from a 2-second exposure, 12 rows |
| VS3 | Raid 1 resolves end to end with zero player input during resolution | Automated: input disabled, run all 5 encounters to a result, 1000 seeded runs, no hangs |
| VS4 | Every wipe is attributable | Post-raid screen names the raider, the mistake, and one town action that would have helped, in 100% of wipes |
| VS5 | Reputation Unknown → Known is felt as a change in the town, not a notification | Tester can name at least two things that changed in town after the promotion |
| VS6 | Tier 1 numbers in the build match canon exactly | Data check: every item, AC/HP/Power/Mana value, morale band and class role diffs clean against the two canon files |
| VS7 | The presentation reads as 2D-HD, not as flat pixel art | Art review against the *Octopath Traveler* reference board; lighting, parallax and glow present in the town scene. Depth-of-field is off and none is owed ([15 BL-126](15-open-questions.md#bl-126); the plates are 1:1 pixel art and a blur softens the designer's pixels) |
| VS8 | 40 minutes of play with no dead time | No screen where the player has nothing to decide for more than 30 seconds |

### 8.2 1.0

| # | Criterion | Target |
|---|---|---|
| R1 | Full canon ladder shippable | Adventure 0 through Raid 5, 12 entries, all 25 raid encounters |
| R2 | All 9 classes are chosen by real players in real compositions | Telemetry-free proxy: in playtest, no class is unpicked by more than 80% of testers across a full run |
| R3 | The 12-slot / 2-tank composition is a live puzzle | At least 3 viable compositions clear each raid tier in balance sim |
| R4 | All 6 Reputation ranks have distinct, nameable town consequences | Design review: each rank has ≥2 town changes and a stated recruit-rarity change |
| R5 | 9 unique Legendary raiders exist, named, one per class, findable once | Content check |
| R6 | Morale movement is story-driven | ≥8 back-story triggers per raider archetype; no raider whose morale only moves from generic events |
| R7 | A full run is completable in a defined budget | 🔷 25-40 hours to clear Raid 5 from a fresh guild |
| R8 | Original content only | The §4.4.1 audit passes — six checklist categories, design-lead sign-off, manifest checked in, running as a pre-export gate (§4.4.1); public copy conforms to §4.4.2 |
| R9 | Zero canon drift | Final data diff against `_source/` shows only changes with a signed-off Open Question resolution behind them |

---

## 9. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| ~~Q1~~ | ~~Is the 15-doc set map in §1 the right decomposition, and are the numbers fixed?~~ | ~~Every doc's "not my lane" links depend on it; renumbering later breaks all cross-references~~ | **RESOLVED — adopted.** §1.1 is the canonical index. The 15 filenames there are fixed, all sibling docs' links are corrected to them, and the map is not renegotiated per doc. This closes doc 13 OQ-10 and doc 11 Q9 |
| Q2 | Do the four differentiators in §4.3 become required scope, or can any be cut? | Determines whether the town, the ladder, and the 12-slot puzzle are scheduled in the slice or deferred | All four required; cut order is §6.3 instead |
| Q3 | Can the player act during raid resolution at all — retreat, swap, use a consumable? | Pillar 4's hardest edge; changes the whole raid UI and the resolution architecture | No mid-raid input. Consumables are assigned pre-raid and fire automatically |
| Q4 | Morale 0-10 "may cause guild disband" — is disband a game over, or a recoverable catastrophe? | A6 says no save loss; canon says disband. One of them has to bend | Recoverable: disband dissolves the roster and drops Reputation one rank; the save continues |
| Q5 | The ladder note says "This continues or can go raid raid, adventure adventure" (canon: Adventure's Board). Does 1.0 stop at Raid 5? | Sets the entire content budget in §6.3 | 1.0 ships the 12 listed entries and stops at Raid 5; further tiers are post-launch |
| Q6 | Two morale bands are both named "Very Happy" (70-80 and 80-90) (canon: Morale table). Intentional, or should 80-90 have its own name? | The state name is one third of Pillar 2's readable row; two identical names make one band invisible | ❓ OPEN — do not fix. Flagged for the designer; [05 — Morale](./05-morale.md) must not silently rename it |
| Q7 | The morale bands share endpoints (0-10, 10-20, 20-30 …). Which band owns exactly 10, 20, 30? | Ten off-by-one bugs and a visibly wrong state label at every boundary | ❓ OPEN — needs a designer ruling. Implementation default pending: lower bound inclusive, upper exclusive, top band 90-100 inclusive |
| Q8 | "All values above are have within tier limits for mistakes based on their tier" (canon: Morale) — does raider rarity clamp the morale-driven mistake range? | Decides whether a Legendary at 14 morale is still better than a Common at 87, which is a core fantasy question | Read as yes: rarity sets a min/max mistake-chance window and morale moves within it. Needs confirmation |
| Q9 | Reputation has 6 ranks but only 4 (Unknown, Known, Respected, renowned) have described effects; `Established` and `Legendary` have none (canon: Guild Reputation) | Two of six progression rungs are undefined; R4 cannot pass | ❓ OPEN — [03 — Guild Reputation](./03-guild-reputation.md) proposes effects, designer signs off. Do not assume they are decorative |
| Q10 | Is `Mana` one stat or do healers need a second variable? Canon: "Mana = spell damage (Subject to change)" and "we need to discuss if we want to have 2 variables or not" | Pillar 2 pushes for one; healer weapons cannot be statted until this closes, and Tier 1 healer weapons are already blocked on it | ❓ OPEN — one stat, held open. Owned by [08 — Stats, Formulas & Numeric Model](./08-stats-and-formulas.md) §5.3 |
| Q11 | Is the primary audience management-sim players rather than ex-raiders? | Sets the store page, the tutorial's assumed vocabulary, and how much MMO literacy we may assume | Management-sim primary; ex-raiders as the launch amplifier |
| Q12 | Is premium / offline / no-live-service confirmed as a business decision, not just a design preference? | A5 and A11 are written as hard anti-goals and are expensive to reverse late | Confirmed premium, single purchase |
| Q13 | Do difficulty presets or assist options ship? [03](./03-guild-reputation.md) §8's recruit-quality spiral and [05](./05-morale.md) §8's morale spiral have no player-facing relief, and [08](./08-stats-and-formulas.md) §11 has no global difficulty lever | Retrofitting difficulty after the sim is swept against one tuning set means re-sweeping every table in [10](./10-content-and-encounters.md); and until this closes, nothing in the set decides whether a stuck player has any way out | §6.4: one default difficulty plus one assist toggle scaling mistake chance and boss HP, implemented as a single `DIFFICULTY_MULT` lever in [08](./08-stats-and-formulas.md) §11 |
| Q14 | Are the nine `ideaboard/` screenshots original mockups authored for this project? | §4.4 bans taking tables from the original and [14](./14-technical-architecture.md) §10.3 commits them to the repo; their provenance is recorded nowhere, and the whole Tier 1 item corpus derives from them | ❓ OPEN — designer to confirm authorship in writing. Assume original until told otherwise, but do not ship the corpus on that assumption (§4.4.3) |

---

## Related documents

Filenames below are the canonical ones from §1.1.

- [01 — Core Loop & Session Flow](./01-core-loop.md) — the minute-to-minute shape of a session; read it to see how the fantasy in §2 becomes a sequence of screens, and for the pacing numbers §6.2 restates.
- [02 — The Town & Its Buildings](./02-town-and-buildings.md) — the five canon buildings and their unlocks; read it to see Pillar 1 made concrete.
- [03 — Guild Reputation](./03-guild-reputation.md) — the 6-rank ladder; read it for the answer to Q9 and for the Recruit Quality Spiral behind §6.4 and Q13.
- [04 — Recruitment & Roster Management](./04-recruitment-and-roster.md) — the 5 recruit rarities, the tavern pool, and the roster the §2 screen renders.
- [05 — Morale](./05-morale.md) — the 0-100 bands and the back-story triggers; read it for Q6, Q7, Q8, and for the morale spiral behind §6.4.
- [06 — Classes, Roles & Raid Composition](./06-classes-and-roles.md) — the 9 classes and the 12-slot composition puzzle in §4.3.
- [07 — Raid Simulation & The Mistake System](./07-combat-simulation.md) — how a mistake becomes an event you can name, which is Pillar 5's build test.
- [08 — Stats, Formulas & Numeric Model](./08-stats-and-formulas.md) — the stat set behind Pillar 2's watch item, the Q10 resolution, and the tuning levers Q13's `DIFFICULTY_MULT` joins.
- [09 — Items & Itemization](./09-items-and-itemization.md) — every canon item and stat block, including the naming collisions the ideaboard contains, and the ~84 Tier 1 count in §6.3.
- [10 — Content Structure: Adventures, Raids & Encounters](./10-content-and-encounters.md) — the canon ladder and the five-encounter drop pattern; read it for the content envelope in §6.3 and the round-length dependency in §6.2.
- [11 — Economy, Shops & Crafting](./11-economy-and-crafting.md) — money, prices, and the Blacksmith crafting that heads §6.3's cut list.
- [12 — Art Direction & Aseprite Pipeline](./12-art-direction.md) — the *Octopath Traveler* reference and the Aseprite workflow; read it for VS7.
- [13 — UI/UX & Frontend Design](./13-ui-ux.md) — the roster row Pillar 2's build test describes, and the accessibility floor §6.4 sits beside.
- [14 — Technical Architecture (Godot)](./14-technical-architecture.md) — Godot, the input-free resolution requirement behind VS3, and the pre-export gates §4.4.1 adds to.
