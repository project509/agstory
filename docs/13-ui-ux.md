# 13 — UI/UX & Frontend Design

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs every screen in the game — the information architecture, the widget kit, the typography, the interaction feel, and the accessibility floor — for a game that is 90% menus and therefore *is* its interface.

---

## 1. Scope

**This doc owns:**

| Owns | Detail |
|---|---|
| Screen inventory | Every screen, its entry points, its primary action, its exit |
| Information architecture | Navigation model, depth limits, what is persistent chrome |
| Widget kit | The finite parts list every screen is assembled from, with states |
| Typography | Faces, scale, line heights, the numeral rule |
| Morale display | The canon roster format, its sizing, colour coding, sort and filter |
| Raid prep | The layout of the game's central decision |
| Raid sim presentation | Log pacing, mistake highlighting, wipe presentation |
| Interaction feel | Latency budget, transitions, hover/focus, sound hook points |
| Input & controller support | The keyboard map (§13.1) and the gamepad map (§13.2), the focus model both drive, and the non-pointer equivalent of every pointer interaction. Routed here by [02 §1](02-town-and-buildings.md) |
| Accessibility | Colour-blind safety, text scale, keyboard nav, reduced motion |
| Settings inventory | §15.1 — every player-facing option in the project, its default, its owner, and where it persists |
| Localization readiness | String externalization, layout elasticity |

**This doc does NOT own:**

| Not owned | Owner |
|---|---|
| The palette's source, world/character art, sprites, post-processing stack, the 10-frame morale face sheet | [12 — Art Direction](12-art-direction.md) — this doc *consumes* its palette and names roles for it |
| Morale bands, the mistake-chance curve, the emoji-to-band mapping | [05 — Morale](05-morale.md) |
| Combat log *content* — templates, joke lines, verbosity tiers | [07 — Raid Simulation](07-combat-simulation.md) |
| Which panels each building screen contains | [02 — The Town & Its Buildings](02-town-and-buildings.md) |
| Item stats, tooltip *numbers* | [09 — Items & Itemization](09-items-and-itemization.md) |
| Scene tree, resolution scaling, font rasterization | [14 — Technical Architecture](14-technical-architecture.md) |

---

## 2. Design thesis 🔷 PROPOSED

> **⛔ SUPERSEDED 2026-09-09 by the art pass.** The lead designer supplied three master reference concepts (`ideaboard/Reference Concepts/`) that are a dark-fantasy dashboard — layered navy panels, bronze edges, one crimson commit control, an illustrated scene viewport — which is exactly the direction §2.4 below rejects. Because this thesis was PROPOSED and never CANON, the references legitimately replace it. M5 ("the desk does not move") survives: the router still has no transitions. The text below is kept as the record of the rejected direction and is no longer built against. Authority: `art/ref/specs/00-canon-reconciliation.md` §1.

### 2.1 The commitment

**The interface is the guild's own paperwork, seen on the guildmaster's desk under one lamp.** Every screen is a physical object made of cheap administrative stock: the roster is a bound registry page with printed rule lines and a smudged left margin; tonight's raid is chalked on a slate propped against the desk; missions are notices pinned to cork with the pin-holes of every previous notice still in them; a hire is a contract you press a wax seal onto; the raid itself arrives as a scribe's written account, filling in line by line while you read it. The camera never leaves that desk, the lamp is always upper-left, and every panel casts the shadow that light implies. There are no floating translucent HUD rectangles, no rounded cards, no icon grids, and no screen anywhere in the game that looks like a settings menu — including the settings menu, which is the printer's colophon at the back of the ledger.

### 2.2 Why this and not something else

| Argument | Detail |
|---|---|
| The menus are the game | A management game's player spends ~80% of session time in UI ([00 §6.2](00-vision-and-pillars.md) session shape: 20–40 min, "a town pass, a roster pass, one or two runs"). Treating menus as chrome around the raid inverts the actual time budget |
| It matches the canon fantasy exactly | ✅ CANON by derivation — canon gives the player only management verbs (canon: raw notes, Core things to do — earn money, spend money, recruit, take missions, improve the guild). A guild leader's verbs are *read, list, assign, sign, pay, file*. Paperwork is not a metaphor for those verbs; it is literally what they produce |
| It buys 2D-HD coherence for free | The 2D-HD look ✅ CANON ("2D-HD aesthetic similar to *Octopath Traveler*") is painted depth plus a crisp pixel layer. Paper, cork, slate and brass are *materials with depth and grain* — they sit inside that render stack instead of fighting it, which a flat vector UI cannot do |
| Comedy needs a straight man | The jokes are the raiders (doc 07's log templates). A deadpan bureaucratic frame around them is funnier than a UI that is also joking. The ledger never winks |
| Failure has a physical vocabulary | ✅ CANON premise — this is a clone of *It's A Wipe!*; wipes are the content. Stamps, blots, crossings-out, and a sealed post-mortem give failure a look that escalates without a single new system |

### 2.3 The five material rules (these are what make it buildable)

| # | Rule | Implementation |
|---|---|---|
| M1 | **One light, upper-left, always.** | Every panel gets a 1px light edge top/left and a 3px soft shadow bottom/right at 55% opacity, offset +2/+3px. No panel is unlit. No second light source anywhere in UI |
| M2 | **Every panel has a real edge.** | Paper = torn or cut edge with 2–4px fibre noise. Slate = wooden frame. Cork = brass tack corners. Nothing is a plain rectangle with a 1px border |
| M3 | **Ink is applied, not drawn.** | Text renders with a 1px ink-spread mask at ≥24px sizes; small text stays clean (see §4.5 legibility gate). Overprint only, never glow |
| M4 | **Colour means something or it is absent.** | Three semantic colour families only — morale (§8), rarity (doc 12 owns the frames), and the seal accent for commitment. Everything else is paper, ink, slate, brass |
| M5 | **The desk does not move.** | No screen slides in from off-camera. Screens are *pages*: they change in place. The only camera move in the whole UI is the town push-in ([02 §10.1](02-town-and-buildings.md)) |

### 2.4 Rejected directions, on the record

| Direction | Why rejected |
|---|---|
| Flat modern dark-mode game UI (panels, accent colour, icon grid) | It is the default for every management game and it makes the 2D-HD art look like a wallpaper behind a different product |
| Golden parchment fantasy RPG UI | It is the *other* default, and canon's guild is incompetent and broke — gilded parchment is the wrong class of object. Our paper is cheap, cool-toned ledger stock, not treasure-map vellum |
| Fully diegetic with no affordances (no scrollbars, no sort buttons, "find it on the page") | Fails the canon requirement to read 12 raiders at a glance. Diegesis loses to legibility every time they conflict; see §8 |
| Ledger metaphor extended to page-turn navigation | Fails the latency budget in §12.1. The page turn is reserved for exactly one moment (departure), which is why it lands |

---

## 3. Surface tokens 🔷 PROPOSED

> **⛔ SUPERSEDED 2026-09-09 by the art pass.** There is no paper. The token *roles* discipline (screens name a role, never a hex) is kept and is what made the repaint possible; the role SET is now the reference palette — four navy depths, bronze/slate/steel edges, a warm off-white text hierarchy, gold/gem/cyan accents, danger/caution/positive state. `seal.accent`'s one-control-per-screen rule survives as the crimson CTA. The text below is kept as the record of the rejected direction and is no longer built against. Authority: `art/ref/specs/04-palette.md` and `game/ui/Palette.gd` (legacy names remain as aliases until the last screen converts).

This doc owns the **roles**. [12 — Art Direction](12-art-direction.md) owns the hexes and may override any value here; the role names must survive that override.

| Token | Provisional | Role |
|---|---|---|
| `paper.high` | `#E8E6D6` | Lit page area, upper-left of any sheet |
| `paper.base` | `#D9D8C4` | Ledger stock — the default UI ground. Cool manila, deliberately not cream |
| `paper.low` | `#C4C3AC` | Page in shadow, disabled rows, inactive tabs |
| `rule.hair` | `#A9A891` | Printed rule lines, table dividers, column separators |
| `ink.body` | `#2B2A24` | Primary text. Iron-gall near-black with an olive cast |
| `ink.mid` | `#5C5A47` | Secondary text, units, column headers |
| `ink.faint` | `#8A8874` | Placeholder text, empty-state prose, disabled ink |
| `slate.base` | `#2F3A38` | Chalkboard ground (raid prep) |
| `chalk.body` | `#E9EEEA` | Chalk text on slate |
| `brass.base` | `#9A7B3F` | Tabs, clips, tack heads, focus ring |
| `seal.accent` | `#8E2B2B` | **Commitment only** — the wax seal. Sealing-wax oxblood, not terracotta |
| `stamp.ink` | `#A33127` | Rubber-stamp red: mistake stamps, AT RISK, WIPE |

**The one rule about `seal.accent`:** it appears on exactly one control per screen — the button that commits state the player cannot cheaply undo (Depart, Hire, Dismiss, Sell, Advance Day). If a screen has two red buttons, one of them is wrong.

### 3.1 Reconciliation with doc 12's UI accent set

[12 §4.2](12-art-direction.md) already publishes a six-value UI accent set. Mapping, so neither doc has to be rewritten:

| Doc 12 token | This doc's role | Status |
|---|---|---|
| Parchment `#E8DCC0` | `paper.high` / `paper.base` ground | ⚠️ Direction conflict — see OQ-11 |
| Ink `#1A1620` | `ink.body` | Adopt doc 12's value; it is cooler than mine and works |
| Primary / gold `#F2C14E` | `brass.base` — focus ring, tabs, tacks | Adopt, at a darkened step for the ring so it holds 3:1 on `paper.high` |
| Danger `#D2493C` | `stamp.ink` (stamps), and morale bands 0-2 in doc 12's 3-step reading | Adopt for stamps; see OQ-11 for morale |
| Caution `#E8A33D` | Morale bands 3-4 in doc 12's reading | See OQ-11 |
| Positive `#6FBF73` | Morale bands 6-9 in doc 12's reading | See OQ-11 |
| Rarity ×5 | Recruit-card frames (§9.4) | Adopt as-is; doc 12 owns rarity entirely |

No token in §3 is intended to compete with doc 12 — where the two disagree, doc 12 wins on hue and this doc wins on *how many steps there are and what carries them*, because band count and signal redundancy are legibility requirements (§8.3, §13), not palette choices.

---

## 4. Typography 🔷 PROPOSED

> **⛔ SUPERSEDED 2026-09-09 by the art pass.** The faces are now Grenze Gotisch (the wordmark only, wght 600) and Fira Sans (everything else) on a 12–34px scale measured from the references. §4.3's tabular-numeral rule is KEPT (`Fonts.ui_tabular()`); §4.5's legibility gate is kept and passes (every text token ≥ 4.5:1 on every surface). The text below is kept as the record of the rejected direction and is no longer built against. Authority: `art/ref/specs/05-typography.md`, `game/ui/Fonts.gd`, `game/ui/Type.gd`.

### 4.1 The faces

| Role | Face | Licence | Why |
|---|---|---|---|
| Display — screen titles, wordmark, seals | **IM FELL English** | OFL | A digitization of 17th-century Fell type that keeps the ink spread and the irregular baseline. It is the guild's own worn printing press. Used **rarely**: one per screen, plus the wipe stamp |
| Prose & the combat log | **EB Garamond** | OFL | The scribe's hand. Reads beautifully at 17px, has real italics for the joke lines, and ships lining + tabular figure sets. The log is a *written account*, so it must not be monospace |
| Data, tables, labels, all numerals in tables | **Fira Sans** | OFL | Designed for small-size legibility; `tnum` tabular figures; a humanist skeleton that does not read as corporate. This is the workhorse and it does the most work |
| In-world pixel type | **Departure Mono** (fallback: **Silkscreen**) | OFL | Only inside the world layer: chalk tallies, shop signage, floating damage numbers over sprites. Rendered at exact integer multiples of its native size, never scaled fractionally |

**Discipline note:** the working interface is a **two-family system** — EB Garamond + Fira Sans. IM Fell is the single indulgence and is capped at one line per screen; Departure Mono never appears on a UI panel. If the §4.5 gate fails IM Fell, substitute EB Garamond SemiBold at the same sizes and lose nothing structural.

### 4.2 Scale — authored at 1920×1080, scales per [14](14-technical-architecture.md)

| Style | Face / weight | Size / line-height | Tracking | Use |
|---|---|---|---|---|
| `title.page` | IM Fell English | 46 / 50 | 0 | Screen title. One per screen |
| `head.panel` | EB Garamond SemiBold | 24 / 30 | +0.5 | Panel headers, sentence case, never all-caps |
| `head.sub` | Fira Sans Medium | 17 / 24 | 0 | Sub-groups inside a panel (Tanks / Healers / DPS) |
| `body.prose` | EB Garamond Regular | 17 / 27 | 0 | Backstory bullets, contract text, empty states. Measure ≤ 74 characters |
| `log.line` | EB Garamond Regular | 17 / 26 | 0 | Combat log body |
| `log.joke` | EB Garamond Italic | 17 / 26 | 0 | The mistake flavour line, indented 24px |
| `table.row` | Fira Sans Regular | 15 / 22 | 0 | Every data row |
| `table.head` | Fira Sans Medium | 13 / 18 | +0.4 | Column headers, sentence case |
| `num.morale.lg` | Fira Sans SemiBold | 26 / 26, `tnum` | 0 | Morale value on Raid Prep |
| `num.morale.md` | Fira Sans SemiBold | 20 / 20, `tnum` | 0 | Morale value on Roster |
| `name.raider` | Fira Sans Medium | 18 / 22 | 0 | Raider name in a roster row |
| `meta` | Fira Sans Regular | 14 / 19 | 0 | Units, counts, timestamps. **14px is the floor for readable text** |
| `stamp` | IM Fell English | 12–72 / — | +2 | Decorative stamps only, and only where the same information also exists as readable text |

### 4.3 The numeral rule (non-negotiable)

| Rule | Detail |
|---|---|
| Tabular figures everywhere numbers stack | Tabular figures are set **per font resource**: one `FontVariation` per weight with `opentype_features = {"tnum": 1, "lnum": 1}`, referenced by the `num.morale.*`, `table.row`, `table.head` and `meta` theme styles in the single `Theme` ([14](14-technical-architecture.md) owns rasterization). CSS syntax such as `font-feature-settings: "tnum" 1, "lnum" 1` is **illustrative only** — Godot has no CSS. A 12-row roster with proportional digits mis-scans and is a genuine legibility failure, not a nicety |
| Old-style figures | Permitted **only** in EB Garamond prose that is not a list of values |
| Alignment | Integers right-aligned. Percentages decimal-aligned. Signed deltas get their own fixed-width column so `+7` and `−12` share a vertical rule |
| Deltas | Always signed, always with the stat name, never bare: `+5 AC`, not `5` |
| Thousands | Locale separator from the string table, never hard-coded. Gold shows `1,240g` in en-US |
| Morale | Integer, `floor(morale)` per [05 §10.1](05-morale.md). Never a percentage, never one decimal place |

**Consequence — the font-resource count is explicit.** Because features are per-resource, the `Theme` carries roughly nine font resources across the four §4.1 families, not four: Fira Sans Regular / Medium / SemiBold each as a `FontVariation` with `tnum`+`lnum`; EB Garamond Regular / Italic / SemiBold, plus a lining-figure `FontVariation` of EB Garamond Regular for §11.1's in-prose damage numbers; IM Fell English; Departure Mono (world layer only, no features). All of them live in the one `Theme` resource under `game/ui/` ([14 §4](14-technical-architecture.md)'s tree: `game/ui/` = "doc 13's widget library + one Theme resource"). Adding a weight is therefore a deliberate act with a listed cost, not a styling accident.

### 4.4 Elastic type sizes

Three user text scales — 100% / 125% / 150% — applied as a multiplier to every style except `stamp`. At 150% every layout in §9 must still fit its panel by reducing row count (scrolling), never by truncating a morale value, a state word, or a class name.

### 4.5 Legibility gate (QA, blocking)

1. Every style must pass a 4.5:1 contrast check against every surface it is drawn on. `ink.faint` on `paper.low` fails and is therefore forbidden — that pair must not exist in a scene.
2. IM Fell English must be legible at 46px on `paper.base` in a screenshot downscaled to 50%. If not, substitute per §4.1.
3. Screenshot every screen in greyscale; all state must remain readable (§13).

---

## 5. Screen inventory

Entry points assume the town scene is the hub ([02 §10.1](02-town-and-buildings.md), clickable illustrated scene).

| # | Screen | Purpose | Entry points | Primary action | Exit |
|---|---|---|---|---|---|
| S01 | Title / Guild select | Choose or create a guild save | Launch | Continue | Quit |
| S02 | **Town** (hub) | ✅ CANON — the progression bar you can see. Building hotspots | S01, any building exit, post-raid | Click a building | S01 |
| S03 | **Guildhall** | ✅ CANON — roster lives here, morale maintained, facilities upgraded, records shown | S02 | Open a tab (Roster / Facilities / Records — the Raid Group tab is retired, [15 BL-106](15-open-questions.md#bl-106) j: S10's strip is the raid group) | S02 |
| S04 | **Roster** | Read all rostered raiders at a glance; select one | S03 tab, S09 "manage" | Select a raider | S03 |
| S05 | **Raider detail** | One raider: gear paper-doll, backstory bullets, wishlist, morale history | S04 row, S09 card, S12 row | Equip / apply comfort item | S04 |
| S06 | **Tavern** | ✅ CANON — "Recruits are found and managed here" | S02 | Hire a recruit | S02 |
| S07 | **Market** | ✅ CANON — buy consumables, sell loot, (crafting supplies "Maybe") | S02 | Buy / Sell | S02 |
| S08 | **Blacksmith** — post-1.0 ([15 Q-13](15-open-questions.md#q-13)) | ✅ CANON heading is literally "Blacksmith (Maybe)"; out of 1.0 — the facade is a locked hotspot on the town plate with "Closed. The smith took a better offer." and no screen behind it | S02 (hover only) | — | — |
| S09 | **Adventure's Board** | ✅ CANON spelling. The mission ladder: Adventure 0, Tutorial Raid, Adventure 1, Raid 1 … Also the tutorial skip panel, in the selected notice beneath *Go to prep*: a warning Label naming the forfeited trinket and its stat plus a `Skip the tutorial` Button — doc 01 §4's `TutorialSkipPrompt` folded into this screen rather than a screen of its own ([15 BL-79](15-open-questions.md#bl-79); no S17 for it) | S02 | Select a mission | S02 |
| S10 | **Raid prep** | Chalk tonight's 12 from the bench. **The central decision** | S09 mission select | Depart | S09 |
| S11 | **Raid sim** | Watch the attempt. Speed, pause, skip; `Esc` is the report ([15 Q-53](15-open-questions.md#q-53)). No Calls (Q-09) and no retreat ([BL-95](15-open-questions.md#bl-95)): the attempt is committed at Depart | S10 Depart | (watching) Skip | S12 |
| S12 | **Results & loot** | Post-mortem, morale ledger, one loot list for the whole raid | S11 encounter end / wipe | Assign loot, then Return to town | S02 |
| ~~S13~~ | ~~**Encounter interstitial**~~ **struck ([15 BL-97](15-open-questions.md#bl-97))** | One rung of the board is one encounter ([BL-24](15-open-questions.md#bl-24)), so there is no between-encounters state to show — no carry-over, no swap-ins, no bank | — | — | — |
| S14 | **Quest / achievement board** | ✅ CANON — sits inside the Guildhall | S03 tab | Claim a completed quest | S03 |
| S15 | **Settings** | Video, audio, text scale, accessibility, controls, language — the full option list, its defaults and its persistence are inventoried in §15.1 | Anywhere via `Esc` | Apply | Back |
| ~~S16~~ | ~~**Codex**~~ **struck ([15 BL-97](15-open-questions.md#bl-97))** | Out of 1.0 (docs/16 C4): the Records tab and the Market's compare tooltip carry the "who can wear this" answer; revisited only if Tiers 2-5 ship item families those cannot explain. `F1` / `nav_codex` are deleted (W8-KEYS) | — | — | — |
| S17 | **Completion / credits** 🔷 PROPOSED | The first clear of Raid 5's last encounter: the run's report, the credits, then the save continues | S12 on the completing clear; S03 → Records, to re-read it | Continue | S02 |

S16 was proposed because canon's itemization is a sharing matrix (nine classes competing over shared families, ideaboard §1); the shipped answer to "who else can wear this?" is the "who can wear this" line on every item tooltip and the Market's compare tooltip, which is why the screen is struck rather than deferred.

🔷 PROPOSED — S17 is the row [10 §13](10-content-and-encounters.md) row 1 says this doc "must gain": doc 10 asserts only that the beat exists and where it fires, and assigns the screen here. The propagation is recorded as [15 BL-73](15-open-questions.md#bl-73). It is a **report**, not a victory screen — [15 Q-88](15-open-questions.md#q-88) rules that the save continues past it, so nothing on S17 ends, resets or locks a campaign, and the only way out of it is S02. Spec in §9.5.

---

## 6. Information architecture

### 6.1 Depth rule 🔷 PROPOSED

**Nothing the player does every cycle may be more than two clicks from the town.** Measured:

| Task | Path | Clicks |
|---|---|---|
| Read the roster | Town → Guildhall → Roster tab | 2 |
| Send a raid | Town → Board → mission → Depart | 3 (the one exception; departure *should* need a deliberate act) |
| Hire | Town → Tavern → Hire | 2 |
| Sell junk | Town → Market → Sell all unusable | 2 |
| Fix a raider's morale | Town → Guildhall → raider → comfort slot | 3 ❓ OPEN — see OQ-4 |

### 6.2 The tab rail

Brass tabs down the **left edge** of the ledger, not across the top. Vertical tabs take the label at a readable size without truncation, survive a +30% localization stretch (§14), and are the one place the ledger metaphor and the affordance agree perfectly. Active tab is `paper.high` and sits 6px further right than the others; inactive tabs are `paper.low`.

### 6.3 Persistent desk strip

A 56px strip across the top of every screen except S01, S11 and S15:

`Guild name · Reputation rank (with a 6-step pip meter) · Gold · Day · roster count n/cap · [Esc] menu`

Reputation is shown as **rank word + 6 pips**, never a percentage bar: ✅ CANON gives six named ranks (Unknown, Known, Respected, Established, Renowned, Legendary) and no numeric scale, so a percentage would be an invention presented as fact. Progress within a rank is a fill on the current pip. [03 — Guild Reputation](03-guild-reputation.md) owns the earn rates.

---

## 7. Widget kit

The finite parts list. Any screen that needs a widget not on this list needs a review, not an improvisation.

| Widget | Spec | States |
|---|---|---|
| `LedgerRow` | 3-line data row on `paper.base`, 84px tall, `rule.hair` divider, alternating `paper.high` wash at 40% on even rows | default / hover (row lifts 1px, `paper.high`) / selected (2px `brass.base` left bar) / disabled (`paper.low`) |
| `MoraleChip` | See §8. Filled swatch, integer + glyph, fixed 72×34px at `num.morale.md` | 10 band variants + `at-risk` stamp overlay |
| `StampBadge` | Rotated 2–7°, `stamp.ink`, ~70% opacity with worn edges. Carries a word, always duplicated as readable text nearby | MISTAKE / AT RISK / MAY LEAVE / WIPE / CLEARED / SKIPPED |
| `WaxButton` | The commit control. `seal.accent` wax disc + `title.page` label. One per screen | default / hover (disc lifts, +6% lightness) / pressed (disc flattens 1px) / disabled (grey wax, reason text beneath — never a mystery) |
| `PaperButton` | Every non-commit action. Ruled rectangle, `ink.body` label, no fill | default / hover / pressed / disabled |
| `BrassTab` | §6.2 | active / inactive / hover / locked (with unlock condition as text) |
| `ChalkSlot` | Raid-prep composition slot on `slate.base`. Chalk outline, role label, drop target | empty / filled / invalid (chalk box redrawn in `stamp.ink`) / locked |
| `StatDelta` | `−4 AC  +9 HP  +12 Mana` in fixed-width columns, signed, `tnum` | positive (`ink.body`, ▲) / negative (`ink.body`, ▼) / neutral |
| `RiskReadout` | §10.3. Numeric expected-mistakes figure + top-3 contributors | low / elevated / severe (word + number + hatch density, never colour alone) |
| `PinnedNote` | Non-modal message pinned to the page with a tack. Persists until dismissed | info / warning |
| `ContractModal` | The only modal. Paper sheet over a dimmed desk, prose terms, `WaxButton` + Cancel | — |
| `SpeedDial` | Raid-sim pacing control: 1× / 2× / 4× / Instant + Pause | 5 positions, current position stamped |

**No tooltips as a primary information channel.** A tooltip may *elaborate* on a value that is already on screen. It may never be the only place a number lives. This rule is what §10 enforces on the raid-prep screen.

---

## 8. The morale display contract

### 8.1 The canon format, honoured exactly

✅ CANON (canon: raw notes, Morale section — "Your roster might show"):

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

The contract is fixed by [05 §10.1](05-morale.md) and this doc does not renegotiate it: line 1 is `Name — value glyph`, line 2 is `Class — State`. The number precedes the glyph. The state word is always present. **This is the most-read piece of information in the game and it is never abbreviated, never collapsed to a bar, and never replaced by a colour.**

### 8.2 Sizing 🔷 PROPOSED

| Context | Name | Morale value | Glyph | Line 2 | Row height |
|---|---|---|---|---|---|
| Roster (S04) | `name.raider` 18 | `num.morale.md` 20 | 24px | `table.row` 15 | 84px |
| Raid prep bench (S10) | `name.raider` 18 | `num.morale.lg` 26 | 28px | `table.row` 15 | 76px |
| Raid prep chalked slot | 16 chalk | 22 chalk | 24px | 14 chalk | 64px |
| Raid sim rail (S11) | 14 | 18 | 20px | class only | 48px |
| Tavern card (S06) | 20 | 26 | 28px | 15 | — |

[05 §10.3](05-morale.md) requires the morale number to be at least as large as the name. Satisfied in every row above (20 > 18, 26 > 18, 22 > 16, 18 > 14).

### 8.3 The band ramp — three states, DECIDED

**[15 BL-127](15-open-questions.md#bl-127) (2026-09-15).** The only morale / success ramp in the game is the reference's red / amber / green family, corrected so it is lightness-ordered and verified under every simulation. The ten-plate table this section used to carry is struck: band 0's fill was 1.35:1 on `SURFACE_PANEL` and could never be text on navy, and the other seven bands ride the integer, the state word and the glyph — §13's first row. `Palette.DANGER` / `CAUTION` / `POSITIVE` hold the hexes (W8-KEYS; `test_palette_cvd.gd` asserts the numbers).

| State | Bands | `hex` | L* | Protanope | Deuteranope | Tritanope | Contrast on `SURFACE_INSET` |
|---|---|---|---|---|---|---|---|
| Danger | 0-2 (Very Upset, Upset, Unhappy) | `DANGER #F73526` | 54.5 | 42.5 | 59.5 | 72.4 | 4.81 |
| Caution | 3-4 (Annoyed, Slightly Annoyed) | `CAUTION #E8A302` | 71.8 | 68.5 | 73.5 | 78.6 | 8.47 |
| Positive | 5-9 (Content and up) | `POSITIVE #AFEBA2` | 87.6 | 89.6 | 86.4 | 84.9 | 13.34 |

Every adjacent step is ≥ 5 L* apart and monotone under none, protanope, deuteranope, tritanope and greyscale (`tools/art/cvd.py`, Brettel/Viénot). `colourblind_safe` (default Off, §15.1) is a hue swap of the **third state only** — `POSITIVE_CVD #C6DDF1` (L* 85.8), sky instead of green, for eyes that do not separate red from green; the Settings note reads "Morale's third colour is sky instead of green, for eyes that do not tell red from green. The number and the state word are unaffected."

Ranges, state words, and the four glyphs at bands 1, 3, 5 and 8 are ✅ CANON via [05](05-morale.md); the other six glyphs are 🔷 PROPOSED there, and doc 12 ships all ten as authored sprites, never system emoji ([BL-128](15-open-questions.md#bl-128)). The reference concepts set the family; the correction is the loop's.

### 8.4 At-risk marking

✅ CANON consequence: 0-10 "may cause guild disband"; 10-20 and 20-30 "may leave guild". Therefore:

| Band | Marking |
|---|---|
| 0 | `StampBadge` **AT RISK** across the row + the row's left margin carries an ink blot |
| 1–2 | `StampBadge` **MAY LEAVE** beside the chip |
| 3–4 | No stamp. The chip's weight is the signal |
| 5–9 | No stamp |

Never a bare exclamation icon: a stamp carrying a word survives greyscale, small sizes, and colour blindness at once.

### 8.5 Sort and filter

| Affordance | Spec |
|---|---|
| Default sort, Roster | Morale **ascending** — the problems are at the top. Never alphabetical by default |
| Default sort, Raid prep bench | Morale ascending ([05 §10.3](05-morale.md)) |
| Sort keys | Morale · Class · Role · Gear coverage · Name · Recent mistakes. Single-key sort with a stable secondary on name |
| Sort control | Four `PaperButton` chips, not a dropdown. Sort is used constantly; hiding it behind a click is wrong |
| Filters | Role (Tank / Healer / DPS) · At risk (bands 0-2) · Benched · Missing gear at current tier · Wants to go |
| Filter state | Always visible as text: `Showing 6 of 17 · At risk`. A filtered list that looks unfiltered is a bug that reads as data loss |
| Persistence | Sort and filter persist per screen for the session, reset on load |

### 8.6 The two-second test (acceptance criterion)

With 12+ rows on screen, a player who has never seen this roster must name every at-risk raider in under two seconds, no hover, no scroll, no tooltip. Test method: screenshot, 2-second exposure, five naive testers, ≥ 90% recall of bands 0-2. If it fails, the fix is chip weight and row rhythm — not a tutorial.

---

## 9. Wireframes

1920×1080. Boxes are panels; `···` marks a repeating pattern.

### 9.1 S04 — Roster

```
+==========================================================================================+
| Ashfall Company   Rank: Respected  (o o o . . .)      1,240g   Day 34   17/17   [Esc]    |
+=====+====================================================================================+
|     |  Roster                                                        Showing 17 of 17    |  <- N of cap; the cap is 04 §12.1's by rank (BL-42)
| Ros |  ---------------------------------------------------------------------------------  |
| ter |  Sort  [Morale v] [Class] [Gear] [Name] [Mistakes]                                  |
|     |  Filter [All roles v] [At risk 3] [Benched] [Missing gear] [Wants to go]            |
| Raid|  ---------------------------------------------------------------------------------  |
| Grp |  Raider                        Morale        Gear            Last 3    Group        |
|     |  ---------------------------------------------------------------------------------  |
| Fac |  +----+ Steve                 +--------+   T1A 3/6         x x .    [ Bench  ]     |
| ilit|  |port| Mage - Upset          |  14 (o)|   AC 8  Dmg 10             [ Detail ]     |
| ies |  +----+ Common               +--------+  (MAY LEAVE)                              |
|     |  ---------------------------------------------------------------------------------  |
| Rec |  +----+ Greg                  +--------+   T1A 5/7         x . .    [ Bench  ]     |
| ords|  |port| Rogue - Annoyed       |  31 (o)|   AC 13 Dmg 8              [ Detail ]     |
|     |  +----+ Common               +--------+                                           |
| ----|  ---------------------------------------------------------------------------------  |
| Que |  +----+ Bob                   +--------+   T1A 7/7         . . .    [ Chalked ]    |
| sts |  |port| Warrior - Content     |  54 (o)|   AC 15 Dmg 5              [ Detail  ]    |
|     |  +----+ Uncommon             +--------+                                           |
|     |  ---------------------------------------------------------------------------------  |
|     |  +----+ Natsuna              +--------+   T1R 6/7         . . .    [ Chalked ]    |
|     |  |port| Shaman - Very Happy  |  87 (o)|   AC 21 Mana 44            [ Detail  ]    |
|     |  +----+ Legendary  1 of 1    +--------+                                           |
|     |  ···  (13 more rows, same shape, scrolls)                                          |
|     |  ---------------------------------------------------------------------------------  |
|     |  Roster average morale 48  ·  At risk 3  ·  Tanks 3  Healers 4  DPS 10             |
+=====+====================================================================================+
```

Notes: the morale chip is the only filled colour block in the row. `T1A 5/7` = slots filled with Tier 1 Adventure gear out of that raider's **visible** slot count — seven slots per raider, six for Monk / Mage / Wizard, whose off-hand is *hidden, not empty* ([09 §3.2, §3.3](09-items-and-itemization.md) own the slot model; the readout is coverage, not a score — see §10.2). Steve is a Mage, hence `/6`. `x x .` = mistakes in the last three attempts, oldest right. Rarity sits on line 3 because it is a hiring-time fact, not a nightly one.

### 9.2 S10 — Raid prep

```
+==========================================================================================+
|  Raid 1  -  Encounter 1 of 5  (*)     [naming pending]        Consumables: 4 potions     |
+==========================================================================================+
| BENCH  (sorted by morale, low first)     |  TONIGHT'S TWELVE            [chalk on slate] |
| ---------------------------------------- |  -------------------------------------------- |
| Steve      14 (o)  Mage      T1A 3/6  >> |  TANKS  2 / 2 required                        |
|   MAY LEAVE   wants to go                |   [1] Bob        54 (o) Warrior  T1A 7/7  x   |
| Greg       31 (o)  Rogue     T1A 5/7  >> |   [2] Dara       62 (o) Warrior  T1A 6/7  x   |
| Carl       44 (o)  Cleric    T1A 5/7  >> |  HEALERS  3 / 3 recommended                   |
| Brenda     58 (o)  Druid     T1A 7/7  >> |   [3] Natsuna    87 (o) Shaman   T1R 6/7  x   |
| ···                                      |   [4] Wren       66 (o) Cleric   T1A 7/7  x   |
| ---------------------------------------- |   [5] Ivo        51 (o) Druid    T1A 6/7  x   |
| [ Suggest a group ]  [ Clear board ]     |  DPS                                          |
|                                          |   [6] Steve      14 (o) Mage     T1A 3/6  x   |
| PREDICTED RISK                           |        MAY LEAVE - kept in the group          |
| ---------------------------------------- |   [7] ···                                     |
| Expected mistakes    ~4.6 / encounter    |   [8..11] ···                                 |
|   //////////////////......  ELEVATED     |   [12] EMPTY  - drag a raider here            |
| Baseline at this comp      2.1           |  -------------------------------------------- |
| ---------------------------------------- |  COMP CHECK                                   |
| Biggest contributors                     |   Tanks       2/2   ok                        |
|  Steve   Mage    Upset       +1.4        |   Healers     3/3   ok                        |
|  Greg    Rogue   Annoyed     +0.7        |   Slots      11/12  1 empty  -8% raid output  |
|  Carl    Cleric  Slightly A  +0.3        |   Mage buff   present                         |
| ---------------------------------------- |  -------------------------------------------- |
| Group gear   T1A 61/74 slots   AC 148    |            [[ WAX SEAL:  DEPART ]]            |
| Potions assigned  3 / 4                  |            or  [ Back to the board ]          |
+==========================================================================================+
```

Note on the group gear denominator: it is `sum of visible slots across the raiders currently chalked` — 7 per raider, 6 for Monk / Mage / Wizard, whose off-hand is hidden rather than empty ([09 §3.2, §3.3](09-items-and-itemization.md)). It is **not** a constant: it shrinks with every empty chalk slot, which is why it reads `74` here (11 chalked, three of them 2H classes) rather than the 81 a full twelve with one Monk, one Mage and one Wizard would give. A denominator of `12 × 7 = 84` is the absolute ceiling and is only reachable by a comp with no 2H class in it at all.

### 9.3 S11 — Raid sim

```
+==========================================================================================+
| Raid 1  Encounter 4  (****)     Round 07        [1x] [2x] [4x] [Inst]  [Pause] [Retreat] |
+=========================+================================================+===============+
| THE TWELVE              |  THE ACCOUNT                                   | BOSS 4        |
| ----------------------- |  -------------------------------------------   | [name pending]|
| Bob      Warr  |||||... |  [R06] Bob strikes Boss 4.                     |  HP 3,118      |
|          54 (o)  AGGRO  |  [R06] Wren heals Bob for 88.                  |  |||||||||.... |
| Dara     Warr  ||||||.. |  [R07] Boss 4 winds up [mechanic pending].     |  Phase 2 of 3  |
|          62 (o)         |                                                |               |
| Natsuna  Sham  |||||||| |  [R07]  ####  MISTAKE  ####    (stamped)       | THREAT        |
|          87 (o)         |         Greg (Rogue) - Severe                  |  1 Bob  1,442 |
| Wren     Cler  |||||||. |         Pulled Aggro Off the Tank              |  2 Greg 1,586 |
|          66 (o)         |         "Greg saw a big number, chased a       |    ^ pulled   |
| Ivo      Drui  ||||||.. |          bigger one, and is now the big        |  3 Dara 1,201 |
|          51 (o)         |          number."                              | ------------- |
| Steve    Mage  ||||.... |                                                | CALLS  3 left |
|      *   14 (o)  BLOT   |  [R07] Boss 4 turns on Greg (Rogue).           | [ FOCUS UP! ] |
| Greg     Rogu  ||...... |  [R07] Greg (Rogue) is DOWNED.                 | [ HEAL TANK ] |
|      *   31 (o)  DOWNED |                                                | [ BACK OFF! ] |
| ···                     |  ···  (auto-scrolls; drag to read back)        |  cooldown 0   |
| ----------------------- |  -------------------------------------------   | ------------- |
| Mistakes this attempt 4 |  Detail  [Story] [Play-by-play] [Numbers]      | Attempt 2     |
+=========================+================================================+===============+
```

`*` = this raider has an ink blot in the margin (has made a mistake this attempt). The rail is ordered by role, not by morale, and never reorders mid-fight.

### 9.4 S06 — Tavern

```
+==========================================================================================+
| Ashfall Company   Rank: Respected  (o o o . . .)      1,240g   Day 34   17/17   [Esc]    |
+==========================================================================================+
|  The Tavern                                        [ Recruits ]  [ Manage roster ]       |
|  ---------------------------------------------------------------------------------------  |
|  At Respected you no longer meet Common adventurers.        Board refreshes in 2 days     |
|  ---------------------------------------------------------------------------------------  |
|  +---------------+ +---------------+ +---------------+ +=================+                |
|  | UNCOMMON      | | UNCOMMON      | | RARE          | | LEGENDARY 1 of 1|                |
|  |  +---------+  | |  +---------+  | |  +---------+  | |  +-----------+  |                |
|  |  | portrt  |  | |  | portrt  |  | |  | portrt  |  | |  |  portrait |  |                |
|  |  +---------+  | |  +---------+  | |  +---------+  | |  |  (unique) |  |                |
|  | Hilda         | | Odo           | | Marguerite    | |  +-----------+  |                |
|  | Monk          | | Wizard        | | Cleric        | | Natsuna         |                |
|  | Starts 52 (o) | | Starts 47 (o) | | Starts 61 (o) | | Shaman          |                |
|  | Content       | | Slightly Ann. | | Happy         | | Starts 74 (o)   |                |
|  | ------------- | | ------------- | | ------------- | | Very Happy      |                |
|  | Arrives with  | | Arrives with  | | Arrives with  | | --------------- |                |
|  | Ironbound     | | Spellweave    | | Blessed Adv.  | | Arrives with    |                |
|  |  Headband 4AC | |  Leggings 2AC | |  Robe 3AC     | | Raider's Circlet|                |
|  | Reinf.Leather | |  +4 Mana      | |  +5 Mana      | | Raider's Shoes  |                |
|  |  Boots 3AC    | |               | | Blessed Adv.  | | --------------- |                |
|  | ------------- | | ------------- | |  Circlet 2AC  | | "Near 1% chance |                |
|  | - Keeps a food| | - Reads during| | ------------- | |  of mistake."   |                |
|  |   diary       | |   fights      | | - Blames the  | | - [3 bullets]   |                |
|  | - Hates dawn  | | - Owes money  | |   healers     | | --------------- |                |
|  |   starts      | |               | | - Hums        | |                 |                |
|  | ------------- | | ------------- | | ------------- | | --------------- |                |
|  |     60g       | |     60g       | |    160g       | |     1,000g      |                |
|  | [[ SEAL:HIRE ]| | [[SEAL:HIRE ]]| | [[SEAL:HIRE ]]| | [[ SEAL: HIRE ]]|                |
|  +---------------+ +---------------+ +---------------+ +=================+                |
|  ---------------------------------------------------------------------------------------  |
|  Roster 17 of 20  ·  Missing role: none  ·  Hiring Marguerite leaves 1,080g              |
+==========================================================================================+
```

Card contents follow [02 §5.3](02-town-and-buildings.md). The Legendary card is full-height and framed differently because ✅ CANON makes it a one-per-class named character.

**Costs shown are the S1 row of [11 §4.2](11-economy-and-crafting.md)** — Common 15g · Uncommon 60g · Rare 160g · Epic 420g · Legendary 1,000g at Tier 1 — which that doc declares "the only recruit price table in the project" and which supersedes the base-cost column in [04 §3.3](04-recruitment-and-roster.md) (doc 04 itself defers, calling its gold values "placeholders until doc 11 sets the earn rate"). This doc owns only their **placement**; if doc 11's ladder moves, this wireframe's figures are illustrative and follow it. Doc 11 asks doc 13 for `<cost>` placeholders instead of figures — real numbers are kept here only so the footer arithmetic (`1,240g` − Marguerite's `160g` = `1,080g`) demonstrates the layout.

The Legendary descriptor is canon's Legendary wording, not Epic's: "basically perfect, near 1% chance of mistake" (canon: raw notes, Guild Reputation). "Rarely make a mistake" is the **Epic** descriptor and must never appear on a Legendary card. Marguerite is Rare, so she arrives with adventure-set pieces only — per [04 §6.2](04-recruitment-and-roster.md), Epic is "the first rarity that arrives with raid gear", which is why no Raider's/Basic Raid item appears on a Rare card.

---

### 9.5 S17 — Completion

Archetype **C** (`art/ref/specs/10-screen-audit.md` §1): the chrome, with the scene viewport
replaced by one panel filling the same rectangle. No new container type, and no new component —
the whole screen is Labels, one rule, and one button.

```
+==========================================================================================+
| Ashfall Company                                    1,240g   17   17/19   Day 91 · Renowned|
+==========================================================================================+
| [home]  | The guild is finished.                          | Credits                       |
| [tavrn] | Ashfall Company cleared the last fight on       | -----------------------       |
| [rostr] | day 91, at Renowned. 6 hours in.                | A Guild Story                 |
| [markt] | ------------------------------------------      | <credits block, read from     |
| [board] | The run                                          |  data/credits.json, printed   |
| [optns] |   Encounters cleared          38                 |  verbatim>                    |
|         |   Days spent                  91                 |                               |
|         |   Raiders on the books        17                 |                               |
|         |   Gold in the strongbox    1,240 G               |                               |
|         | ------------------------------------------      |                               |
|         | What is left                                     |                               |
|         |   Legendaries 4 of 9  ·  Records 22 of 40        | -----------------------       |
|         | The save continues. Nothing is taken away.       | [ Back to town — the guild   |
|         |                                                  |   carries on ]                |
+==========================================================================================+
```

**Every figure on it is already kept by the campaign** — guild name, `day` (or `completed_on_day`
when they differ), `played_seconds`, the `cleared` tally, `rank_name()`, `roster`, `gold`, and the
two meters §13's sibling screens already print. Nothing here is a second source of truth for what
the run was, and nothing on this screen may be the only place a number lives.

**It fires once.** Entry is from S12 on the completing clear and the screen marks itself seen, so a
reload does not replay somebody's ending at them. It stays re-readable from S03's Records tab,
because a report you can never open again is a cutscene.

**The credits block is data, never prose in the screen.** It is read from `data/credits.json` and
printed verbatim; until a person signs the roll off, that file says so in one line and the screen
prints that line. A build loop cannot invent who made a game.

**No victory framing.** [10 §13](10-content-and-encounters.md) row 4 and [00 §6.3](00-vision-and-pillars.md)
both stop 1.0 at Raid 5, and doc 10 refuses to invent a Tier 6 or a heroic mode to fill the gap —
so S17 states the remaining goal and gets out of the way. It carries no prestige button, no
difficulty toggle and no "New Game+".

---

## 10. Raid prep — the screen that carries the game

### 10.1 What it is for, in one line

🔷 PROPOSED — **Why this exists:** ✅ CANON names the decision explicitly — *"Oh shit, Steve is at 14. Maybe I shouldn't bring him, unless he really wants to go and I know I can beat the raid with him messing up."* This screen's entire job is to make that sentence available to the player in one look.

### 10.2 The four things visible without any interaction

| # | Thing | How it is shown | Sourced from |
|---|---|---|---|
| 1 | **Comp validity** | `COMP CHECK` block: tanks `n/required`, healers `n/recommended`, slots `n/12`, plus the numeric penalty of each shortfall | [06 §6.5](06-classes-and-roles.md) |
| 2 | **Morale at a glance** | Full canon two-line format with the §8 chip on **both** the bench and the chalked twelve. Bench sorted morale-ascending | [05 §10](05-morale.md) |
| 3 | **Gear power** | Two honest numbers, never one opaque score: **slot coverage** (`T1A 61/74` — filled over *visible* slots, 7 per raider and 6 for Monk / Mage / Wizard per [09 §3.2, §3.3](09-items-and-itemization.md); the denominator tracks who is actually chalked) and **summed AC / Damage / Mana** | [09](09-items-and-itemization.md) |
| 4 | **Predicted risk** | §10.3 | [08 §8.8](08-stats-and-formulas.md), [07 §5](07-combat-simulation.md) |

**On gear power:** a single "gear score" is rejected. Canon's itemization is a family-sharing matrix where a Mage's `+17 Mana` and a Warrior's `15 AC` are not commensurable, so any single number would be a weighted guess presented with false authority — and it would hide exactly the thing the player must see, which is *which slots are empty*. Coverage plus raw stat sums is more useful and cannot lie.

### 10.3 The risk readout

```
Expected mistakes    ~4.6 / encounter
  //////////////////......  ELEVATED
Baseline at this comp      2.1
Biggest contributors
  Steve   Mage    Upset       +1.4
  Greg    Rogue   Annoyed     +0.7
```

| Rule | Detail |
|---|---|
| The number | `sum(effective_mistake_chance)` across the twelve × mistake checks per round, from [08 §8.8](08-stats-and-formulas.md) (the band is [05 §5.2](05-morale.md)'s). One decimal place, `tnum` |
| The baseline | The same figure with every raider at band 5 *Content*. This is what makes 4.6 mean something |
| The band word | LOW / ELEVATED / SEVERE — a word and a hatch density, never colour alone |
| Contributors | Top three by contribution, named, with class and state word. This is what turns a number into a decision about a person |
| Bench-delta preview | Hovering or focusing a chalked raider shows the readout recomputed without them, inline, as a ghosted second figure. No modal, no tooltip-only |
| Not shown | A single win-probability percentage. ❓ OPEN — see OQ-2 |

### 10.4 What this screen must NOT do

| Prohibited | Why |
|---|---|
| Hide the risk figure behind a hover, an expander, or an "advanced" toggle | The trade-off *is* the game. A hidden cost is not a choice |
| Show morale as a bar, a colour, or an icon without the integer and the state word | Breaks the canon display contract and destroys §8.6 |
| Require a click to see a benched raider's morale | ✅ CANON's fantasy is reading a roster and reacting. A click is a different, worse feeling |
| Block Depart on an invalid comp | [06 §6.6](06-classes-and-roles.md) is explicit: "Penalties teach; locks do not." Warn loudly, always allow departure |
| Auto-bench low-morale raiders, or reorder the chalked twelve on its own | The screen must never make this decision for the player, even helpfully |
| Show `wants to go` only in a tooltip | It is the flag that makes the canon sentence true. It belongs on the bench row, in text |
| Animate the risk figure counting up | It gets read constantly. Number changes are instant (§12.2) |

---

## 11. Raid simulation view

The player is watching, not playing ([07 §2](07-combat-simulation.md)). This screen either carries the comedy or wastes it.

### 11.1 The log is a document, not a terminal

| Choice | Spec |
|---|---|
| Face | EB Garamond 17/26 — the scribe's account. Not monospace: a mono log reads as a debug console and kills the diegesis |
| Structure | Round marker `[R07]` in `ink.mid` at a fixed 56px gutter, so rounds scan as a column. Body left-aligned, ragged right, measure ≤ 74 characters |
| Joke line | `log.joke` italic, indented 24px under its mistake header, in quotation marks. Content and templates: [07 §10.3](07-combat-simulation.md) |
| Numbers | Lining tabular figures inside the prose so damage columns line up between adjacent lines |
| Verbosity | Three visible buttons — Story / Play-by-play / Numbers — defaulting to Play-by-play. Debug tier is dev-build only ([07 §10.2](07-combat-simulation.md)) |
| Ink settle | Each line arrives at full opacity with a 90ms 1px vertical settle. **No slide-up, no fade-in, no typewriter.** Typewriter reveal is the obvious choice and it is wrong: it makes reading speed a function of animation speed |
| Scrollback | Free drag to read back at any time; auto-scroll resumes on release. Never blocks incoming lines |

### 11.2 Pacing

| Speed | Round duration | Line cadence | Mistake hold | Notes |
|---|---|---|---|---|
| 1× | 2.6s | 180ms | 700ms | Default |
| 2× | 1.3s | 110ms | 500ms | |
| 4× | 0.65s | batched per phase | 300ms | Non-mistake lines appear in phase blocks |
| Instant | — | — | — | Full log + post-mortem, no reveal ([07 §3.1](07-combat-simulation.md)). **LOCKED until this encounter has been cleared once** — [01 §9](01-core-loop.md)'s OQ#1 ruling. `SpeedDial` renders it as a fourth position in a locked state whose unlock condition is stated **as text** beside it, per §7; it is never hidden and never silently inert. `Skip to the end` carries the same gate. 1×/2×/4× and Pause stay always available |

**The comedy brake** 🔷 PROPOSED: at 2× and 4×, a mistake of severity *Severe*, any death, and the wipe line drop to 1× cadence for that line only, then resume. Rationale: a joke needs a beat, and the player chose 4× to skip the arithmetic, not the story. `Setting: comedy_brake`, default on.

**Floors that speed may never cross:** a mistake line is never below 300ms, is never batched with other lines, and is never skipped by a speed change mid-reveal. Speed affects presentation only and can never affect outcome ([07 §3.1](07-combat-simulation.md)).

### 11.3 How a mistake is highlighted

Four simultaneous signals, none of them colour alone:

| Signal | Spec |
|---|---|
| The stamp | `StampBadge` **MISTAKE** lands on the log line with a 120ms press — scale 1.06 → 1.00, 3° rotation, no bounce. The stamp is the loudest single event in the game's UI and it is used for nothing else |
| The header line | `Raider (Class) — Severity — Mistake name` in `ink.body` Medium, above the italic joke line |
| The margin blot | A permanent ink blot appears in the log's left margin at that line, and beside that raider in the rail. Blots accumulate: a bad attempt is *visibly* a messy page |
| The hold | The reveal pauses for the §11.2 hold before the next line, so the joke is read before the consequence lands |

The rail's `Mistakes this attempt` counter increments instantly, no tween. Where a mistake caused a cascade ([07 §6](07-combat-simulation.md)), the caused lines are connected to their cause by a thin `rule.hair` bracket down the gutter — the page shows the chain without prose explaining it.

### 11.4 How a wipe is presented

A sequence, once, ~2.4s total, fully skippable on any input:

| t | Beat |
|---|---|
| 0ms | The account stops. Every remaining animation halts on frame. Silence for 400ms — the only silence in the game |
| 400ms | The final line writes: `[R10] WIPE.` in `title.page` at 32px, in `stamp.ink` |
| 900ms | A large **WIPE** stamp presses diagonally across the page: 180ms, 1.15 → 1.00 scale, −7° rotation, then a 400ms ink bleed into the paper fibre |
| 1,400ms | Page dims 12%; a wax seal drops onto the lower-right corner |
| 1,800ms | The post-mortem sheet appears in place under the stamp — ~~slides out from under the ledger page~~ struck ([15 Q-99](15-open-questions.md#q-99)): a page changing in place is M5's own sentence, and the UI has no slide |
| 2,400ms | `Try again` (paper) and `Return to town` (wax) become active. `Try again` is left and default-focused |

The post-mortem is a filed report, not a defeat screen: cause chain, mistake tally by raider, rounds survived, damage taken, morale ledger preview. No "You Failed", no red flash, no lost-progress language — a wipe costs time, consumables, morale and money, never the save ([00 §6.2](00-vision-and-pillars.md)), and the screen's tone must match that.

---

## 12. Interaction & feel 🔷 PROPOSED

### 12.1 Latency budget (treat as a perf test, not a guideline)

| Interaction | Budget |
|---|---|
| Input → first visible change | ≤ 80ms |
| Screen / tab switch fully settled | ≤ 140ms |
| List sort or filter reflow | ≤ 100ms, no animation over 120ms |
| Hover state | ≤ 40ms, no layout shift, ever |
| Number recompute (risk readout, gold preview, stat delta) | Same frame. Instant. Never tweened |
| Modal open | ≤ 120ms |
| Town → building push-in | ≤ 260ms, interruptible |
| Any queued animation | Interruptible by the next input. Nothing is ever uncancellable |

A management game is a series of small reads and small commits. Every frame of ceremony between "I want to see the roster" and seeing the roster is a tax the player pays hundreds of times per session.

### 12.2 Motion table

| Element | Motion | Duration | Curve |
|---|---|---|---|
| Screen / tab change | Fade-in of the incoming page, opacity only ([15 Q-99](15-open-questions.md#q-99); `ScreenRouter.TRANSITION_MS`; 0 under reduced motion and when `shot.gd` drives). No cross-fade, no 6px tab shift | 110ms | ease-out |
| Row hover | 1px lift, `paper.high` wash | 40ms | linear |
| Row select | Brass left bar wipes downward | 90ms | ease-out |
| `WaxButton` press | Wax disc flattens 1px, 4% darken | 60ms | ease-in |
| Morale chip value change | **Instant.** No count-up | 0 | — |
| `ChalkSlot` fill | Chalk scratches in, 2 strokes | 130ms | linear |
| `StampBadge` land | Scale 1.06 → 1.00, rotate to rest | 120ms | ease-out, no overshoot |
| Log line arrival | 1px settle at full opacity | 90ms | ease-out |
| Wipe sequence | §11.4 | 2,400ms | — |
| **Departure page turn** | The ledger page turns; the raid begins on its reverse | 700ms | ease-in-out |
| **Day advance** | Ledger closes and reopens on a new page | 900ms | ease-in-out |

Only the last two are indulgent, and both are once-per-cycle commitments. Everything else is under 140ms. Nothing in the UI loops, pulses, or breathes; ambient motion belongs to the world layer and is doc 12's.

### 12.3 Hover, focus, pressed

| State | Treatment |
|---|---|
| Hover | Surface lightens one step (`paper.base` → `paper.high`), 1px lift. Never a colour change, never a scale change |
| Focus (keyboard) | 2px `brass.base` ring with a 1px `ink.body` outer offset, drawn *outside* the bounds so it never shifts layout. Identical shape on every widget. Always visible — no `:focus-visible` suppression |
| Hover + focus | Both, simultaneously. They are different facts |
| Pressed | 1px inward offset + 4% darken |
| Disabled | `paper.low` ground, `ink.mid` text, **and a reason string adjacent**. A disabled control that does not say why is a dead end |

### 12.4 Sound hook points

Names bound in `game/core/Audio.gd` (the fourth autoload, [14 §4](14-technical-architecture.md)); the direction and the mix are the loop's under [15 Q-97](15-open-questions.md#q-97) and [Q-98](15-open-questions.md#q-98) (every one-shot generated by `tools/audio/gen_sfx.py`, the 140 ms ceiling on every non-indulgent hook). All UI sound is *material*: paper, chalk, brass, wax, coin. No synthesized blips.

| Hook | Trigger | Sync |
|---|---|---|
| `ui.tab` | Tab / screen change | On first pixel of the dissolve |
| `ui.row_select` | Row select | On the brass bar wipe |
| `ui.chalk` | ChalkSlot fill / clear | Leading edge of the stroke |
| `ui.chalk_bad` | Comp check turns invalid | 60ms after the slot redraw |
| `ui.stamp` | `StampBadge` land — **the mistake sound** | Exactly on frame 1 of the press. Must never be late |
| `ui.seal` | Any `WaxButton` commit | On press, not release |
| `ui.coin` | Gold changes | On the value write |
| `ui.page_turn` | Departure | Start of the turn |
| `ui.ledger_close` | Day advance | Start of the close |
| `ui.blot` | Ink blot appears | With the stamp, one layer under it |
| `ui.silence` | Wipe, t=0 | Ducks all buses to −60dB for 400ms |
| `ui.quill` | Every log line at live speed — the scribe (Voice bus, Q-98 (iii); W8-AUD-OPT) | With the line's arrival; none at Instant or during a skip |

`ui.stamp` is the game's signature sound. It fires dozens of times per raid and must be short, dry, and never fatiguing: ≤ 140ms, three round-robin variants, ±2 semitone random pitch — except the WIPE stamp, which is `ui.stamp` unjittered (Q-98 (v)).

---

## 13. Accessibility

Not a settings tab bolted on — three of these are structural and must be built in from the first screen.

| Requirement | Spec | Blocking? |
|---|---|---|
| **Colour is never the only signal** | Every morale reading carries four channels: the integer, the state word, the glyph, and the chip's lightness. Bands 0-2 add a worded stamp. Removing colour entirely loses no information | Yes |
| CVD verification | Simulate every screen under protanopia, deuteranopia, tritanopia and full greyscale. The criterion ([15 BL-127](15-open-questions.md#bl-127)): ΔL* ≥ 5 between adjacent ramp steps under all five observers, monotone (§8.3's three states; the earlier ten-band / 3:1-per-step half is struck as arithmetically unreachable) | Yes |
| Contrast | 4.5:1 for all readable text against its own ground; 3:1 for UI boundaries and focus rings | Yes |
| Minimum text size | 14px at 1920×1080 for anything the player must read, read in §4.2's 1920-wide authoring frame: `Type.SMALL 13` / `STACK 11` stay, because 13 in the 1536 frame renders at 14 whole pixels at 1080p ([15 BL-127](15-open-questions.md#bl-127)); the 125 / 150% text scale is the remedy for smaller eyes. 12px permitted only for decorative stamps whose content is duplicated in readable text | Yes |
| Text scaling | 100 / 125 / 150%. Layouts reflow by reducing rows, never by truncating a morale value, state word or class name | Yes |
| Full keyboard navigation | Every screen operable with no mouse. 🔷 PROPOSED ([00 §6.1](00-vision-and-pillars.md), itself marked PROPOSED — canon states only "Likely engine: Godot" and the Aseprite note, so the keyboard requirement is the doc set's, not canon's). Blocking on our own authority: a game that is 90% menus and cannot be driven from the keyboard cannot be driven on a Deck either (§13.2) | Yes |
| Gamepad navigation | §13.2. A pad steers the menus through Godot's focus defaults and is **unverified and unsupported in 1.0** ([15 BL-133](15-open-questions.md#bl-133)): no glyphs, no rebinding, nothing tested on a Deck. Keyboard + mouse is the supported input | No (1.0) |
| Reduced motion | Every tween arrives instantly: one door (`Widgets.tween`, `GameSettings.motion_duration` = 0), no second code path — the page turn, the ledger close, the fade-in, the wipe sequence's bleed and doc 12's ambient drift all complete on the next frame. Stamps still land (they carry state). No depth-of-field exists to shift ([BL-126](15-open-questions.md#bl-126)) | Yes |
| Reduced flashing | No element exceeds 3 changes per second. Nothing flashes at all |  Yes |
| Log dwell | Optional `log_manual_advance`: the sim pauses at each mistake until dismissed, for players who read slower than 1× | No |
| ~~Font choice~~ | ~~Optional swap of EB Garamond → Fira Sans for prose and log~~ Struck ([15 BL-127](15-open-questions.md#bl-127) (3)): Fira Sans is the only body face, so there is nothing to swap from; `prose_font_swap` is retired and its key deleted in W10-DELETE | — |
| Emoji-free mode | Replaces morale glyphs with a 10-step monochrome pip figure. The integer and state word are unaffected | No |

### 13.1 Keyboard map

| Key | Action |
|---|---|
| `Tab` / `Shift+Tab` | Next / previous focus group (rail → list → detail → commit) |
| Arrows | Move within the focused group |
| `Enter` | Primary action on the focused item |
| `Space` | Toggle — chalk/unchalk a raider, check/uncheck a filter |
| `1`–`4` | Speed settings on S11 (respecting the skip unlock). ~~Sort keys on any list screen~~ struck ([15 BL-97](15-open-questions.md#bl-97)) |
| `Q` / `E` | Previous / next raider while a detail panel is open |
| `F` | Cycle the Records filter |
| `Esc` | Back one level; from the town, opens Settings; mid-account on S11, the report ([15 Q-53](15-open-questions.md#q-53)) |
| ~~`F1`~~ | ~~Codex (S16)~~ struck ([15 BL-97](15-open-questions.md#bl-97)); `nav_codex` deleted in W8-KEYS |
| `Space` (S11) | Pause / resume |

Focus never traps in a modal without a visible way out, and focus order always follows reading order: rail, then header, then content, then commit.

### 13.2 Gamepad map 🔷 PROPOSED — unverified and unsupported in 1.0

**[15 BL-133](15-open-questions.md#bl-133) (2026-09-15):** the joypad events in `project.godot` stay (A/B/X/Y/Start bound; the D-pad steps focus through Godot's defaults), so the map below mostly works, and none of it is verified, glyphed or rebindable; `README-player.txt` says so in one sentence. Docs/16 C6 prices glyphs, rebinding and the Deck pass as the post-1.0 Deck milestone. The **focus model** below is 1.0 and is what the keyboard uses.

Assigned to this doc by [02 §1](02-town-and-buildings.md) ("Screen chrome, widget library, input, controller support") and required by [02 §10.2](02-town-and-buildings.md): *"Needs a hotspot + focus model that works on gamepad (D-pad cycles buildings) as well as mouse. No free cursor dependency."* [00 §6.1](00-vision-and-pillars.md) lists Steam Deck as a stretch goal and notes "Deck implies gamepad nav". Xbox button names are used as the canonical labels; the string table carries a PlayStation and a Nintendo variant of every glyph (§14).

| Binding | Action | Keyboard equivalent |
|---|---|---|
| D-pad / left stick | Move within the focused group — rows, cards, slots, town hotspots | Arrows |
| `A` | Primary action on the focused item; enter a building from the town | `Enter` |
| `B` | Back one level; exit a building to the town; cancel a modal | `Esc` |
| `X` | Toggle — chalk / unchalk the focused raider, check / uncheck the focused filter | `Space` |
| `Y` | Cycle filters | `F` |
| `LB` / `RB` | Previous / next focus group (rail → list → detail → commit) | `Shift+Tab` / `Tab` |
| `LT` / `RT` | Previous / next raider while a detail panel is open | `Q` / `E` |
| Right stick, vertical | Scroll the focused list; on S11, free scrollback through the log | drag / `PgUp`–`PgDn` |
| `Start` | Settings (S15) | `Esc` from the town |
| `A` on S11 | Pause / resume | `Space` (S11) |
| D-pad left/right on S11 | Step the `SpeedDial` down / up (1× ↔ Instant) | `1`–`4` |

**The town focus model is rail-first, and the rail is the building ring** ([15 BL-142](15-open-questions.md#bl-142), as built). Focus enters every screen on the rail's first item (`Frame.focus_entry` walks `FOCUS_REGIONS` rail-first; `a11y_smoke.gd` pins `rail[0]` on every route), and on the town the rail cycles the buildings 02 §10.2 asks the D-pad to cycle — one habit serves all thirteen screens. The illustrated hotspots stay the mouse's door and are reachable by Tab into the scene region; they are not a second focus model, and "last building visited" is not restored.

**Non-pointer equivalents — required, because there is no free cursor:**

| Pointer interaction | Non-pointer equivalent |
|---|---|
| Drag-to-chalk on S10 (§9.2) | Focus a bench raider, `X` to chalk into the first legal slot for their role, `X` again to unchalk. The drag is a convenience, never the only path — this is the `Space` binding already in §13.1 |
| Free-drag log scrollback on S11 (§11.1) | Right stick vertical scrolls the account; releasing to centre resumes auto-scroll, exactly as releasing the drag does. Never blocks incoming lines |
| Hover-based bench-delta preview (§10.3) | The preview is bound to **focus**, not hover — §10.3 already reads "Hovering or focusing a chalked raider". Focus is the primitive; hover merely also sets focus |

Rule: **no interaction may exist only as a pointer gesture.** If a screen needs a gesture that has no focus-plus-button equivalent, the gesture is wrong, not the map.

---

## 14. Localization & scaling readiness

| Requirement | Spec |
|---|---|
| No literal strings in scenes | Every string is a key in a table. `ui.roster.sort.morale`, `morale.state.slightly_annoyed`, `log.mistake.aggro.v3` |
| No concatenation | Never `name + " — " + value`. The roster line is one template: `roster.line1 = "{name} — {morale} {glyph}"`, so a locale may reorder it |
| The em dash is layout, not content | ✅ CANON's format uses an em dash. It ships as part of the *template*, letting a CJK locale substitute its own separator without breaking the contract's meaning. ❓ OPEN — see OQ-5 |
| Plurals and gender | ICU MessageFormat. `{n, plural, one {# mistake} other {# mistakes}}` |
| Numbers and currency | Locale-formatted separators; the `g` gold suffix is a translatable affix, not a hard-coded character |
| **+30% elasticity** | Every label field is authored so that a 30% longer string still fits, at 125% text scale, without truncation |
| Longest-string sizing | Column widths derive from the longest *string in the table*, not the longest English string. Worked example: the longest morale state is "Loves Their Guild" (17 chars); +30% = 22 chars; the state column reserves **22 characters** at `table.row`, so German and Finnish fit without re-layout |
| Name truncation | Raider names are player- and generator-facing and unbounded. Column reserves 22 characters, truncates with an ellipsis, and exposes the full name via the detail panel — never *only* a tooltip |
| Wrapping | Two-line wrap permitted on `head.panel`, `body.prose`, `log.line`. Forbidden on `table.row`, `MoraleChip`, `ChalkSlot` labels — those grow the row instead |
| ~~Pseudolocale in CI~~ | Not in 1.0 ([15 BL-133](15-open-questions.md#bl-133)): one language ships (en-US, the only string table that exists; `TranslationServer` is called nowhere under `game/`), so the 150% text-scale sweep (`test_a11y_legibility.gd`) is the layout proof that stands in for `xx-LONG` until a translation exists — a translation of a comedy is a content project with its own reviewer (docs/16 W4.8) |
| Text in art | No baked-in text on any sprite or panel background. Two exceptions: shop signage in the world layer, a swappable layer ([12](12-art-direction.md)); and the pre-rendered logotype (`gen_wordmark.py`, an OFL face), which is a **mark**, not text — the words are also a Label beside it ([15 BL-127](15-open-questions.md#bl-127) (4)) |
| RTL | Out of scope for 1.0, but no hard-coded left/right anchors — use start/end. ❓ OPEN — see OQ-6 |

---

## 15. Build order

| Phase | Deliverable | Why first |
|---|---|---|
| 1 | `MoraleChip`, `LedgerRow`, `StampBadge`, the type scale, the token set | Every screen is made of these. Build them wrong and rebuild everything |
| 2 | S04 Roster, in full, passing §8.6's two-second test | It is the most-read screen and it validates the whole kit |
| 3 | S10 Raid prep with a stubbed risk readout | The central decision; the earliest point the game is testable as a game |
| 4 | S11 Raid sim log presentation at 1× only | Validates that the comedy lands before pacing work begins |
| 5 | S02 Town, S06 Tavern, S09 Board | Navigation and the loop close |
| 6 | S12 Results, wipe sequence (S13 struck — BL-97) | Failure presentation, once failure exists to present |
| 7 | S05, S07, S14, S15 (S16 struck — BL-97) | Depth |
| 8 | Accessibility verification, the 150% sweep (no pseudolocale pass in 1.0 — BL-133), latency profiling | Verification, not implementation — the requirements were built in from phase 1 |

**Definition of done, per screen:** passes the §12.1 latency budget; fully keyboard-operable; legible in greyscale and under three CVD simulations; survives 150% text scale; has an authored empty state; every disabled control states its reason.

### 15.1 Settings inventory 🔷 PROPOSED

S15 is one row in §5, but the options themselves are defined across six documents with no single list. This is that list. **The rule: if an option is not in this table, it does not exist in the settings screen.** Values are owned by the doc in the Owner column — this doc owns only the inventory, the defaults where no other doc states one, and the persistence policy.

| Option | Default | Owner | Kind | Scope |
|---|---|---|---|---|
| Sim speed — 1× / 2× / 4× / Instant | 1× | [01 §9](01-core-loop.md), [07 §3.1](07-combat-simulation.md) | Player | **Global, persisted**, but *reset to 1× for any mission never cleared* ([01 §9](01-core-loop.md)) — that "never cleared" set is save data, so the reset rule is **per-save** while the stored value is global |
| `comedy_brake` | On | §11.2 | Player | Global |
| `log_manual_advance` | Off | §13 | Player | Global |
| Emoji-free mode | Off | §13 | Player | Global |
| ~~Prose font swap (EB Garamond → Fira Sans)~~ | struck — retired ([15 BL-127](15-open-questions.md#bl-127); the row is hidden now and the key goes in W10-DELETE) | §13 | — | — |
| Text scale — 100 / 125 / 150% | 100% | §4.4 | Player | Global |
| Reduced motion | Off | §13 | Player | Global |
| `auto_loot` | Off | [09 §14.3](09-items-and-itemization.md) item 5 | Player | Global |
| Reduced effects (graphics) | Off, auto-suggested on a failed perf probe | [14 §11](14-technical-architecture.md), [12](12-art-direction.md) | Player | Global |
| Resolution / window mode / vsync | Native, borderless (window mode: borderless fullscreen or a 3:2 window sized to the desktop; `F11` / `Alt+Enter` swap them) | [14](14-technical-architecture.md) | Player | Global |
| Colour-safe morale ramp (`colourblind_safe`) — swaps §8.3's third state to `POSITIVE_CVD #C6DDF1` | Off ([15 BL-127](15-open-questions.md#bl-127)) | §8.3, §13 | Player | Global |
| Forgiving Guild (`forgiving_guild`) — "fewer mistakes, softer bosses. Changes nothing else.": `Formulas.DIFFICULTY_MULT` 0.75 on mistake chance and enemy HP, stored on the attempt | Off ([15 BL-113](15-open-questions.md#bl-113); W8-KEYS's row on the kit's Off / On cycle chip) | [08 §11](08-stats-and-formulas.md), [00 §6.4](00-vision-and-pillars.md) | Player | Global |
| Audio bus levels (master / music / UI / voice-of-the-scribe) | 100 / 80 / 80 / 100 | Audio | Player | Global |
| ~~Language~~ | struck ([15 BL-133](15-open-questions.md#bl-133)) — one language (en-US) and keyboard + mouse in 1.0; localization and pad support are docs/16 W4.8 / C6; the row and its key go in W10-DELETE | §14 | — | — |
| ~~Controller glyph set — Xbox / PlayStation / Nintendo~~ | struck (BL-133) — no glyph set ships; the row and its key go in W10-DELETE | §13.2 | — | — |
| `FEATURE_BLACKSMITH`, `FEATURE_UPGRADES`, `FEATURE_SALVAGE`, `FEATURE_CRAFTING`, `FEATURE_WISHLIST` | Per build | [11 §13](11-economy-and-crafting.md) | **Build flag — never a player setting** | Build |

**Reduced flashing is not on this list on purpose.** §13 makes it unconditional — nothing in the game flashes, and no element exceeds three changes per second in *any* configuration — so it is a build requirement with a QA gate, not a toggle the player can get wrong. Same reasoning excludes the §13 items marked Yes/blocking: contrast and minimum text size ship on by default and have no "off". CVD safety is the exception, as an option (the row above): the corrected three-state ramp is the default and is CVD-verified on its own ([15 BL-127](15-open-questions.md#bl-127)); `colourblind_safe` swaps only the third state's hue for eyes that do not separate red from green.

**Where settings live:** `user://settings.cfg`, a Godot `ConfigFile`, deliberately **separate from [14 §7.2](14-technical-architecture.md)'s `user://saves/slot_{n}.json`**. Options are a property of the installation, not of a guild: deleting every save, or a save migration failing, must never reset the player's text scale or ramp choice. Written on Apply and on quit, never on every keystroke; a missing or unparseable file falls back to the defaults above and is rewritten, so a corrupt options file can never block boot.

**Cross-reference owed elsewhere:** [14 §7](14-technical-architecture.md) currently documents save slots only and needs one row for `user://settings.cfg` (path, `ConfigFile` format, not versioned with `save_version`) so the technical doc has a home for it. That row is doc 14's to write; this doc does not import it.

---

## 16. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| OQ-1 | ✅ CANON's morale bands overlap at every tens boundary (`0-10`, `10-20`, …) and two bands share the state word "Very Happy". Which band does a raider at exactly 20 render as, and how does the roster distinguish 70-80 from 80-90 when the word is identical? | The display contract puts the state *word* on line 2. If two bands share a word, the word carries less information than the number, and the chip colour becomes the only differentiator — which §13 forbids as a sole signal | Follow [05](05-morale.md)'s resolution: lower-bound-inclusive bands, and rename one "Very Happy" for display purposes only. This doc cannot decide it; it is blocked on doc 05 |
| OQ-2 | Does raid prep show a single predicted win percentage? | One number flattens the decision into a threshold check and invites reload-until-favourable. But without it, players may not grasp the stakes at all. [01 §5.2](01-core-loop.md) already publishes illustrative percentages (55% / 30% / 40% / 65%) | **No win percentage.** Ship expected-mistakes plus contributors (§10.3). Revisit after the first playtest measures whether players understand the risk |
| OQ-3 | Do we ship a "recommend a group" button that fills all twelve? | It is the single biggest quality-of-life win in the game, and also the fastest way to delete the decision canon calls "very appropriate for the guild-leader fantasy" | Ship it, but it optimizes for **comp validity only** and deliberately ignores morale, so the player must still make the Steve call. Label it "Suggest a group", never "Optimal" |
| OQ-4 | Are comfort items applied from the Roster screen or only from Raider Detail? | Decides whether morale repair is a 2-click or 3-click loop. It is done many times per cycle | Allow a quick-apply from the Roster row's context action, with the full slot view in Raider Detail. Requires doc 02's comfort-slot model to be per-raider. **Placement recorded 2026-09-14 (art pass W3-ROSTER):** the row's two actions — the quick-apply "Cheer up" and "Manage" — sit INSIDE the roster card's rim as its bottom band (`Cards.card(actions)`), the reason a disabled one gives printed under it inside the same rim. The earlier reading that placed them beneath the card (`Roster.gd`, wave 1) is reversed, not silently: a card is a closed frame (`art/ref/specs/01-concept1-home-layout.md` §3), and a row is one card tall, so the roster shows two full rows at twelve |
| OQ-5 | Is the em dash in the canon roster line a hard character or a localizable separator? | ✅ CANON prints `Natsuna — 87 ❤️`. If the dash is content, CJK and RTL locales inherit a Western typographic convention; if it is layout, the "exactly reproduced" canon format is technically parameterized | Localizable separator inside the template, defaulting to U+2014 with spaces. The canon format is exact in every shipped English build |
| OQ-6 | Is RTL in scope after 1.0? | Retrofitting bidirectional layout is expensive; building start/end anchors now is nearly free | Not in 1.0. Use start/end anchors throughout anyway |
| OQ-7 | ✅ CANON names the shop "Market" in its heading but "Merchant" in the core-loop list, and spells the board "Adventure's Board". Which strings ship? | These are screen titles, tab labels, and town signage — they need to be right before art is baked | Use canon's heading spellings verbatim ("Market", "Adventure's Board") pending doc 02's naming pass; keep all three in the string table as one key each so a rename is a data change |
| OQ-8 | ✅ CANON leaves the ladder unnamed: "obviously they will need names later, but this is a placeholder". How do S09 and S11 label content until then? | Every screen header, log line and results sheet needs a mission and boss name | Render the placeholder verbatim (`Raid 1`, `Boss 3`) with a small `[name pending]` marker in dev builds only. The marker must not ship |
| OQ-9 | Does the Blacksmith screen (S08) exist? | It is a fifth town hotspot, a full screen, and its own widget set. ✅ CANON heading is "Blacksmith (Maybe)" | Build the town hotspot as a locked, visible building; build no S08 until doc 02's §7 conditional resolves |
| OQ-10 | Sibling docs reference doc 13 under four different filenames (`13-ui-presentation.md`, `13-art-direction-and-ui.md`, `13-ui-ux-and-frontend.md`, and this file, `13-ui-ux.md`), and doc 05 assigns the morale face sheet and colour ramp to "13 — Art Direction & UI" while this assignment gives palette ownership to doc 12 | Every cross-link in the doc set is currently broken, and morale-ramp ownership is claimed by two docs | Adopt one index: this file is `13-ui-ux.md`; doc 12 is `12-art-direction.md` and owns the face sheet and palette source; doc 13 owns the ramp's *application*. **CLOSED 2026-09-10** — the doc-set-wide link pass landed (91 links across docs 01–08), doc 05's §1 table now splits the sheet to 12 and the layout to 13, and `tests/unit/test_docs_links.gd` fails on a dead doc link. The four names above are kept as the record of what the stale links said |
| OQ-11 | [12 §4.2](12-art-direction.md) specifies a **3-step** morale colour set (Positive `#6FBF73` / Caution `#E8A33D` / Danger `#D2493C`) on a warm Parchment `#E8DCC0` ground. §8.3 here specifies a **10-step** lightness-ordered ramp on cool `paper.base`, and rejects the green↔red axis outright | Two conflicts. (a) 10 canon bands cannot be shown by 3 colours if colour is to distinguish them at all. (b) Green/amber/red is the one axis that fails deuteranopia and protanopia, which §13 makes a blocking gate. Also a tonal disagreement: golden parchment reads as treasure-map vellum, and canon's guild is broke | **Keep doc 12's hues as the anchors at bands 1, 4 and 7 and interpolate the remaining seven along the L* ladder in §8.3**, shifting the high end from pure green toward teal so the ramp survives CVD. Ground: needs a call from the lead designer — warm parchment (doc 12) or cool ledger stock (§2.3). This doc will adopt whichever ships |
| ~~OQ-12~~ | CLOSED ([15 BL-133](15-open-questions.md#bl-133)): the focus model is 1.0; a pad is unverified and unsupported; glyphs, rebinding and the Deck pass are docs/16 C6. ~~Is gamepad support (§13.2) a 1.0 requirement, or does it ship with the Steam Deck stretch goal?~~ | [02 §1](02-town-and-buildings.md) routes controller support to this doc and [02 §10.2](02-town-and-buildings.md) asks for a gamepad hotspot model outright, but [00 §6.1](00-vision-and-pillars.md) puts the Deck in "later platforms" and only claims the keyboard requirement "mostly buys us" gamepad nav. The answer decides whether the §13.2 map is a build gate or a backlog item, and whether S15 ships a rebinding UI in 1.0 | **The focus model is 1.0; the button map is cheap after it.** Build every screen focus-first with no free-cursor dependency (that is already required by the keyboard row in §13, so the cost is zero), ship §13.2's default bindings in 1.0, and defer *rebinding UI* and Deck-specific layout/text-scale verification to the Deck milestone. Rebinding is the only part that is genuinely extra work |

---

## Related documents

- [00 — Vision & Design Pillars](00-vision-and-pillars.md) — the platform, resolution and input targets every layout in §9 is authored against, and the keyboard-navigation and Steam Deck lines behind §13 and §13.2 (all of doc 00 §6 is 🔷 PROPOSED, so those inputs are proposals this doc chooses to treat as blocking, not canon).
- [01 — Core Loop & Session Flow](01-core-loop.md) — the Roster Select information contract in its §5.3, which §10.2 implements, and the session-time budget that justifies §12.1.
- [02 — The Town & Its Buildings](02-town-and-buildings.md) — the panel contents of every building screen in §5, and the clickable-scene navigation model this doc's chrome sits on top of.
- [03 — Guild Reputation](03-guild-reputation.md) — the six-rank ladder rendered as pips in the desk strip (§6.3).
- [04 — Recruitment & Roster Management](04-recruitment-and-roster.md) — the roster cap that sets the row count in §9.1, and the recruit-card data in §9.4.
- [05 — Morale](05-morale.md) — the band table, the emoji mapping, the display contract and the legibility requirement that §8 executes.
- [06 — Classes, Roles & Raid Composition](06-classes-and-roles.md) — the comp checks and shortfall penalties shown in §9.2 and §10.2.
- [07 — Raid Simulation & The Mistake System](07-combat-simulation.md) — the log schema, verbosity tiers and template writing rules whose presentation §11 owns.
- [09 — Items & Itemization](09-items-and-itemization.md) — the slot model behind the gear-coverage readout, and the loot-assignment list on S12.
- [11 — Economy & Crafting](11-economy-and-crafting.md) — the S1 recruit price table the §9.4 Tavern cards display, and the `FEATURE_*` build flags §15.1 keeps out of the settings screen.
- [12 — Art Direction](12-art-direction.md) — the palette this doc consumes, the 10-frame morale face sheet, the rarity frames, and the post-processing that §13's reduced-motion option disables.
- [14 — Technical Architecture](14-technical-architecture.md) — resolution scaling, font rasterization, the string-table format, and the sound-hook bindings named in §12.4.
