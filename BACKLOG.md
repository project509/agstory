# BACKLOG — A Guild Story

> Ordered. Work top-down. Take the **first unchecked box**, finish it completely, tick it, commit.
> Ordering rule: **the game must be playable end-to-end as early as possible**, then deepened.
> If the loop stops at any moment, whatever is built should still run.
>
> Tick with `[x]`. If a task turns out to be bigger than one iteration, split it into sub-tasks
> *in this file* rather than half-finishing it. Add newly discovered work in the right milestone.
>
> **The authoritative queue is `build/plan/audit.json`** (190 audited items; 39 still open, and a
> further 15 that were blocked on a designer ruling — every one of them answered in
> `build/plan/ship/RULINGS.md`). This file is the milestone shape and the tick record; the audit is the
> work list, with evidence, remaining work, spec source, files to touch, size and risk per item.
> `build/plan/index.md` is the readable index. A blocked item gets a `docs/15` `Q-` row — never a guess.

---

> **The loop stopped for a designer review on 2026-09-11; the designer answered on 2026-09-15 by delegating
> every open decision to the loop.** `build/plan/review-2026-09-11.md` grouped the blocked items by the kind of
> answer each needed; `build/plan/ship/RULINGS.md` is the answer to all of them, and it binds waves 7-10. The
> one that outranked every box below — **the Tier 1 campaign is not completable** (`M6-BAL-04`), measured by
> `tools/playtest.gd` rather than suspected — is ruled: lever (c), the on-ramp re-sized by `docs/08` §9.3a's
> healed clock at stage 0, all-Common, morale 45, applied by W8-SIM-BALANCE and by nobody else.

---

## M0 — Foundations

- [x] Git repo, `.gitignore`, `project.godot`, directory skeleton
- [x] Test harness (`tests/TestCase.gd`, `tests/run_tests.gd`) + self-check tests
- [x] Parse checker (`tools/parse_check.gd`) and verify gate (`tools/verify.sh`)
- [x] Aseprite headless Lua pipeline verified
- [x] `tools/run_game.sh` — launch windowed; `tools/build_art.sh` — full art pipeline (generators → `.aseprite` → atlas+JSON, incremental, `--gen`/`--clean`)
- [x] `sim/core/Rng.gd` — xoshiro256** + SplitMix64 per `docs/14` §8, per-channel derived streams, basis-point gates, save/restore. 25 tests incl. known-answers from an independent Python implementation
- [x] `sim/model/Enums.gd` — CharClass(9), Rarity(5), Slot(7), StatKind(5), Role(9)+RoleGroup, ItemFamily(19)+claimants, EncounterKind, ReputationRank(6); stable string keys + display names. 19 tests incl. full canon-matrix reconstruction
- [x] `sim/model/Stats.gd` — AC/HP/Power/Mana/Damage value type: add/accumulate/subtract/scaled/sum, enum-keyed access, strict JSON parse with error reporting, ideaboard-style `describe()`. 27 tests incl. every canon armor/weapon/trinket total
- [x] `data/classes.json` — 9 classes: canon role + description, role group, head/body/main/off families, base HP from `docs/08` §6, primary/secondary stats, 2H and dual-wield flags, neutral rarity HP multipliers. 19 tests cross-validating against Enums and `docs/08`'s published totals
- [x] `data/items_t1_adventure.json` — 28 items: 17 armor (4 families), 4 canon weapons, 3 PROPOSED healer weapons, 4 trinkets. 20 tests incl. cell-for-cell canon stats and a cross-file test that equips each class and reproduces the ideaboard totals
- [x] `data/items_starting.json` — 22 pieces + 9 `starting_sets`; AC-only, armor-only, canon name collisions kept as distinct items. 15 tests incl. all nine canon AC totals
- [x] `data/items_t1_raid.json` — 48 items, 9 per-class Boss 1-5 tables, Boss 5 trinket pool. 24 tests incl. cell-for-cell canon stats, the drop pattern, and `docs/08`'s published armor totals
- [x] `sim/content/ContentDB.gd` + `sim/model/Item.gd` + `sim/model/ClassDef.gd` — loads and validates all four JSON files, indexes 98 items, derives eligibility, cross-checks every reference. 27 tests, half of them feeding it deliberately broken content
- [x] **Canon fidelity tests** — `tests/unit/test_canon_guard.gd`, 24 tests through ContentDB. Asserts loaded data reproduces every canon total exactly: starting AC 7/7/6/5/5/5/5/4/4; adventure totals 15/14/13/9/8 AC and +16/+14/+14/+12/+10 HP and +13/+17 Mana; every raid piece's AC/HP/Power/Mana. This test is the canon guard — it must never be weakened

## M1 — The Simulation (the heart)

- [x] `sim/model/Raider.gd` — the roster record per `docs/04` §4: identity, rarity, morale, mistake clamps, equipment by slot, backstory/wishlist/traits, counters, save round-trip. **No combat state** — see the Combatant task below. 21 tests
- [x] `sim/model/Combatant.gd` — per-encounter state: HP, Alive/Downed/Dead, threat, consequence tokens, overkill, resumable save. 27 tests. Split out of the Raider task: `docs/04` §4 requires the roster record stay free of combat state so it serialises mid-raid
- [x] `sim/model/Encounter.gd` + `data/encounters_t1.json` — all five Tier 1 encounters with enemy stat blocks, configured mechanics, loot slots and comedy lines; wired into ContentDB. 23 tests pinning them to `docs/08`'s budget
- [x] `sim/core/Formulas.gd` — `docs/08` §8.1-8.7: mitigation, melee, spell, healing, variance, threat, retarget. AC reading and Mana model each behind ONE named switch. 32 tests incl. every worked example and cross-checks against `docs/10`'s tables
- [x] **Mistake-chance equation** merged into `Formulas.gd`: `docs/05`'s shape and coefficients at `docs/08`'s ownership location. All 50 matrix cells pinned; consequence recorded as `docs/15` BL-20. ~~(`docs/08` §8.8)~~ — split out because `docs/08` and `docs/05` publish *forked* models that disagree by ~2x (a Very Upset Common is 81.6% vs 40%). `docs/15` Q-04/05 ruled `docs/08` §8.8 owns the equation and coefficients, importing `docs/05`'s per-rarity `sensitivity`. Read BOTH before implementing; the merge is the task
- [x] `sim/core/EventLog.gd` — structured event stream per `docs/07` §10: entry schema, four verbosity tiers as a *filter*, cascade provenance, fallback rendering, deterministic JSON for golden files. 17 tests
- [x] `sim/core/Mistakes.gd` — all 18 types as data, three roll sites, weighted type selection, margin-based severity, cascade attribution, anti-spam guards. 28 tests incl. end-to-end rates (Common ~24%, Legendary ~1%)
- [x] `sim/core/RaidSim.gd` — the eight-phase round loop, threat targeting, three healer archetypes, mechanics, three mistake roll sites, Downed/death, four outcomes. Pure and deterministic. 23 tests. **The game is simulatable.**
- [x] **Golden tests** — 4 scenarios spanning best/worst case, stored as summary + readable story + SHA-256 of the full stream. `tools/write_goldens.gd` regenerates deliberately. Verified to catch a one-point `AC_K` change
- [x] `tools/balance_sweep.gd` — 2,304 runs / 288 cells at the default 8 seeds (8 slots x 4 gear stages x 3 rarities x 3 morale bands; it was 1080 / 135 when first wired and grew with the adventure gear stages — reconciled by M6-FINAL-03): clear rates, mistakes per encounter, lever-balance readout. Wired into the full gate (skipped in `--fast`). **Answered BL-21, opened Q-22**
- [x] **First balance pass** — BL-21 resolved (`ROLL_SITE_WEIGHT` 0.55/0.55/0.15, worst cell 312->144 mistakes); sweep roster now wears a charm per `docs/08` §9.1's benchmark, which alone took Adventure-geared Commons at E3 from 0% to 100%. Goldens regenerated deliberately
- [x] **Second balance pass** — all three findings from the first pass turned out to be **measurement errors, not game bugs**. Corrected and re-measured:
  1. ~~best case kills E5 in 17 rounds vs 22~~ — **the loadout was impossible.** The sweep equipped Boss 5 capstones to fight Boss 5. `docs/08` §9.2 states the rule outright: *"the boss is fought in the gear the boss before it dropped"*, so Boss 5's DPS-at-attempt row is **After Boss 4 (325.0)**, not After Boss 5. Added a `raid_entry` gear tier (Boss 1-4 drops only); E5 now measures **22 rounds against a 22-round target**. This also **corrects my own earlier note**: I recorded that row as 286/round — §9.1's *After Boss 5* row totals **329.0**, and it was the wrong row to compare against regardless, so the "~28% overshoot" was doubly wrong and never existed.
  2. ~~raid gear trivialises the tier~~ — that *is* the farm state, and a cleared tier becoming farmable is correct. The real progression check is `raid_entry`, which is not trivial: morale-15 Commons clear E5 at **63%**, not 100%.
  3. **Q-22 re-measured** at an auto-detected unsaturated cell (E2/Adventure): **morale 100pp vs rarity 25pp** — the inverse of the original finding, and the direction canon wants. Recorded in `docs/15` Q-22, leaning to *accept*; re-check at T2.
  - Hardening shipped with it: `_cell()` used to return zeros for an unswept cell, so a mistyped morale printed a **fabricated** "0% clear" as though it were measured — it now fails the sweep. Gear-ladder monotonicity covers all four tiers. New golden `e5_first_clear`, plus a test that Boss 5 drops can never leak back into `raid_entry`.

## M1 balance findings (from the goldens — feed these into the sweep)

- **Best case lands exactly on target.** Legendaries in raid gear clear E5 in **22 rounds**, which is precisely `docs/08` §9.2's derived `target_rounds`. Strong evidence the damage budget and boss HP agree.
- **Commons in Adventure gear cannot clear E3**: 26 rounds, attrition, 84 mistakes. `docs/08` sized E3 for 15 rounds at benchmark DPS — the shortfall is the mistake DPS tax biting far harder than the benchmark assumed, because the benchmark is a *nominal* figure. Either the tax is too steep (see BL-21) or Adventure-geared Commons are simply not meant to clear E3. **The sweep must decide which.**

## M2 — Playable end-to-end (programmer art)

- [x] `game/ui/Boot.tscn` + `Boot.gd` — loads and validates ContentDB, registers the screen host, routes to the menu. On invalid content it prints the validation report as a readable page instead of crashing. **The gate's headless-boot check is now live.**
- [x] `game/core/GameState.gd` — autoload: guild, gold, day, reputation, roster, flags. Canon-checked: 60 G opening balance (`docs/01` §8.0 Q-13), start at Unknown, roster caps 15-20 by rank (`docs/04` §12.1). Save-shaped `to_dict`/`from_dict` with version refusal; the save *service* is still M3.
- [x] `game/core/ScreenRouter.gd` — autoload: screen stack (`goto`/`push`/`pop`), no transitions by design (`docs/13` §2 M5, "the desk does not move"). Failed navigation is loud and leaves the current screen up.
- [x] `game/screens/MainMenu` — New Guild / Continue / Settings / Quit. Entries with no destination yet are disabled **with the reason printed** (`docs/13` §7) and re-enable themselves via a real `screen_exists()` check as each screen lands.
- [x] `game/screens/Roster` — canon's two-line readout (name + morale/face, then `<Class> — <State>`), sortable by morale/name/class/gear and filterable by at-risk/role, with the footer tally. The morale chip is the only filled colour in a row (`docs/13` §9.1). **Per-row [Bench] and [Detail] deliberately omitted rather than shown dead — they arrive with RaidPrep and S05.**
- [x] `game/screens/Guildhall` (S03) — brass tab rail down the left (`docs/13` §6.2), opening on the Roster tab so reading the roster is two clicks from town as `docs/13` §6.1 requires. Built this iteration because Roster is a *tab*, not a screen, and had no reachable home otherwise.
- [x] `sim/core/Morale.gd` (baseline half) — `docs/05` §8 baselines, rarity resilience multipliers and drift, pinned to the doc's worked table. **Triggers, leave checks and disband remain M3** and belong in this file.
- [x] `game/core/StartingRoster.gd` — the benchmark twelve, seeded and deterministic. Answers `docs/15` BL-23; a new guild cannot start empty because 60 G buys four hires and a raid needs twelve.
- [x] `game/screens/RaidPrep` — bench and twelve in canon's two-line format with the chip on both, comp check, gear coverage + AC/Damage/Mana (never one score), and the predicted-risk readout with baseline, hatch, word and named contributors. Depart is never blocked by a bad comp (`docs/06` §6.6).
- [x] `game/core/RaidPlan.gd` — the prep arithmetic, kept out of the UI so it can be tested against `docs/06` §6.5's worked example directly. Pinned: tank weight 1.0 for the no-Cleric week-three comp, +5pp per point of shortfall, -25%/healer capped at -75%.
- [x] `game/screens/AdventureBoard` (S09) — canon's spelling, the Tier 1 ladder, ordered gating on clears. Answers `docs/15` BL-24 (one rung = one encounter).
- [x] `game/screens/Results` — outcome in words first, then the tally, the fallen by name, and the sim's own story log. Loot and morale ledgers are M3.
- [x] `game/screens/RaidView` — the account, read as a document (`docs/13` §11): three verbosity tiers defaulting to Play-by-play, 1x/2x/4x/Instant with pause and skip, the mistake stamp + header + italic joke + accumulating margin blot, and the wipe sequence. Depart now lands here, and Results is the paperwork filed afterwards.
- [x] `game/core/LogPlayer.gd` — the pacing model, kept out of the screen so it can be tested: `docs/13` §11.2's cadences and holds verbatim, the 300ms mistake floor, 4x phase batching, and the comedy brake. 30 tests, including one asserting every speed reaches an identical line list — §11.2's "speed affects presentation only".
- [x] `game/screens/Town` — hub with the desk strip (`docs/13` §6.3) and the five canon buildings (`docs/02` §2.3), each disabled with an honest reason until its screen exists. Brought forward from its backlog position because MainMenu's New Guild had nowhere to go without it, and a menu whose primary action leads nowhere is the dead end the quality bar forbids. **The illustrated clickable town (`docs/02` §2.1 Rule of Visible Change) is M4 art; this is the information architecture under it.**
- [x] **Milestone gate: full loop playable.** `tests/unit/test_full_loop.gd` walks Boot -> town -> board -> prep -> depart -> raid view -> results -> town by finding the actual `Button` a player would click and emitting `pressed`, so it tests the WIRING and not just the state machine. Also asserts no screen is a dead end, the loop survives two laps, a clear pays `docs/11` §F2's rate, and clearing A1 opens A2. **Verified as a real gate**: cutting one navigation link fails 8 assertions.
- [x] **Party size respects the encounter.** Found by the gate: raid prep chalked twelve for *every* mission, so a player would have sent a full raid on a six-person Adventure (`docs/10` §3) — doubling the party DPS the Adventure HP in `docs/08` §9.1a was derived against and trivialising the whole on-ramp. `RaidPlan.party_size()` and `healers_recommended()` now read the encounter; healers floor to **1** at six, which is the assumption `docs/10` §8 and `docs/15` BL-29 both already used.

- [x] `game/screens/Settings` (S15) + `game/core/GameSettings.gd` — `docs/13` §15.1's **closed inventory** (all 18 keys), `user://settings.cfg` via `ConfigFile`, deliberately separate from saves so deleting a guild never resets a text scale, and corrupt-safe: an unparseable file yields defaults and is rewritten rather than blocking boot. Options with no subsystem yet are disabled **with their reason** (`docs/13` §7). Wired live: comedy brake, sim speed, log dwell, emoji-free mode, auto-loot, text scale.
- [x] **`docs/01` §9's skip gate, and the two doc edits it asked for by name.** Instant and Skip-to-result are **unlocked per encounter after a first clear** — RaidView had let you skip a first-ever attempt, deleting the comedy on exactly the content it was written for. `docs/07` §3.1 gains the Availability column and `docs/13` §11.2's Instant row gains the locked state, both of which `docs/01` §9 listed as owed.

## BLOCKING — the ladder has no bottom step (`docs/15` BL-26)

- [x] **Author canon's Adventure content** (`A1`-`A3`) — authored verbatim from `docs/10` §8's table: party 6, 1 tank, 705/880/1055 HP, swings 9/17/21, and A3's 42 raw/round left untouched exactly as `docs/10` instructs. Loaded by `ContentDB.adventure_encounters()`, and the board now lists the Adventure ladder **before** Raid 1, which is the correct order per `docs/10` §3.
- [x] **`docs/15` BL-27 — the tier-0 output floor.** `UNARMED_DAMAGE = 2` and `HEAL_FLOOR = 6` in `Formulas`, published as `docs/08` §8.5a. Shipped as **floors, not addends**, which is why nothing geared moved: E5's first clear is still **22 rounds vs a target of 22**, and 3 of 5 goldens regenerated byte-identical. Adventure 1 went from **0% clear at any HP** to **50%**.
- [x] **`docs/15` BL-28 — publish the missing starting-gear DPS stage.** `docs/08` §9.1a: stage 0 = **16.5/round**, after A1 = 54.9, after A2 = 58.2. `docs/10` §8's ~88 was **5.3x too high for A1**, exactly as that doc's own ❓ OPEN warned. Adventure HP re-derived per rung at its own gear stage (135 / 550 / 700) and `docs/10` §8's table updated to match.

## Adventure tier — measured follow-ups

- [x] **`docs/15` BL-30 — the inverted curve, fixed by the doc's own formula.** Each rung's swing recomputed at the stage it is actually fought: A2 34 -> **38** raw/rd, A3 42 -> **50**. **A1 needed no change** (27 authored vs 26.9 needed) — it is the one rung genuinely fought at stage 0, which is why `docs/10` §8 got A1 right and only the geared rungs wrong. The ★★★ mini boss went from **90% (the tier's easiest) to 29% at Content** — a gate, not a wall. Pinned by tests that derive each swing from the formula rather than hardcoding it.
- [x] **`sim/core/Loot.gd` — Adventure gear actually drops.** Canon's drop table (`docs/10` §4.1-4.2), the raid tier indexed by each item's own `drop_encounter`, `docs/11` §F1/§F2 payouts (70 G per full Raid 1, 20 G across Adventure 1) with §F5's repeat decay, and `docs/09` §14.3's loot window on Results: Suggested pre-fill with a per-row override. **Measured end to end: farming A1 arms the six and takes A2 from 0/24 to 6/24.**
- [x] **`docs/15` BL-33 explained — and it was BL-32.** Not a loot bug: A1's pool is rolled uniformly, but canon's family-sharing matrix makes `ITM_T1_ADV_W1H_MH` wanted by **5** raiders while every caster weapon is wanted by **1**, so melee arm 5x more slowly. BL-31's bias should have absorbed that, and did not — because it was computed against the whole twelve-raider roster, so benched raiders' needs kept every entry in the pool and it never narrowed to what the six in the field were short of.
- [x] **`docs/15` BL-32 — Suggested is party-first.** `record_attempt()` takes the departing party; rolls and the Suggested split are computed against it, falling back to the roster. Still need-based per `docs/09` §14.3 Option B — it just reads "need" as the need of the raiders in the field. **Measured: 15 clears armed 4 of 6 with 20 items stranded and neither Rogue holding a weapon; now 8 clears arm all six, both Rogues, nothing stranded.**
- [x] **Selling loot** — `sim/core/Economy.gd` implements `docs/11` §6.1's valuation (`raw = 2·AC + 1·HP + 3·Power + 0.8·Mana + 2.5·Damage`, times `docs/11` §5's step coefficient, times `docs/03` §7's sell rate) and **all twelve of `docs/11` §6.2's worked canon rows reproduce exactly**, including the 1 G floor. Sell is live in the loot window with the price on the button, plus `docs/02` §6.3's sell-all-unusable helper — which sells only gear NOBODY on the roster can wear, never a sidegrade somebody wanted.

## M3 — Meta systems

- [x] `sim/core/Morale.gd` + `sim/core/MoraleLedger.gd` — **`docs/05` §7's trigger table, complete**: all 22 rows with their documented deltas and all eight cap shapes the doc uses (once-per-tick, once-per-session, once-ever-per-subject, session total, rolling window, cooldown, uncapped). Caps round-trip through a save, because a cap you can reset by quitting to the menu is not a cap. `docs/05` §7.6's five-exploit anti-farm audit is now five tests. Also fixed a real fidelity gap: `docs/05` §4 says morale is "stored as float so sub-1 drift accumulates" but `Raider.morale` was an int, so a Common's 1.125/tick drift truncated and lost an eighth of its recovery every tick.
- [x] `sim/core/Morale.gd` — **`docs/05` §6's leave and disband checks.** Leave rates 0.22/0.14/0.05 with a hard zero above band 2 per canon's "Won't leave", resilience 1.30→0.25, and the doc's own worked odds reproduce (a Common at 14 departs within four ticks 55% of the time, a Legendary 13%). All four hard rules, including the one that is an absence: the last raider of a required class has **no plot armour**. Disband needs three simultaneous conditions and cannot fire below 3 strikes — asserted by 900 rolls that must all decline. Wired: raid outcomes now move morale, and a Day Tick resolves after.
- [x] **`docs/15` BL-34 — "Rest until recovered", on the Guildhall's roster tab.** ✅ CANON puts morale maintenance in the Guildhall, so the control sits directly above the morale numbers it moves. It prices itself first (`Morale.rest_ticks_needed()` — "9 days of rest will settle the roster") and a test asserts the forecast equals the days it then costs. It is **not shelter**: `docs/05` §6's leave checks fire on every tick, so the rest stops on a departure and names who left, and the forecast warns in advance. **No morale number was changed** — raising the drift rate stays rejected until comfort items exist.
- [x] **`sim/core/Comfort.gd` — comfort items, both product lines, and the Guildhall facility track.** Canon's one line ("Manage morale with comfort items") was read three ways by three docs; `docs/11` §8.1's split resolves it and `docs/15` BL-38 records the ruling. **Furnishings** are `docs/02` §4.2's durable placed baseline shift, **Indulgences** are `docs/05` §7.4's +8 spike on its own 2-tick cooldown, and a test from each end keeps them apart. Facility track is `docs/02` §4.3's levels and slots with `docs/11` §8.4's 150/500/1400 G, rank-gated per `docs/03` §7, with the blocker naming which of the two gates it is. **BL-39**: `docs/11` §8.4's floor column (45/50/55/60) loses to `docs/05` §7.5's +0/+3/+6/+10 by both other docs' own words — and the "build first, then the people" arc was re-measured and survives the correction. Acceptance test passes: `docs/02`'s worked Steve reaches **62**.
- [x] **The Guildhall's Facilities tab — the comfort system has a screen.** `docs/02` §4.5's spec in full: current level card, next level card, cost, and the delta table, with `docs/02` §9's own "Visible change" wording standing in for the before/after thumbnails until the art exists. `docs/11` §8.4's "the Guildhall screen must show which of the two is blocking" is live — rank first, then price, each naming the number. Quarters panel carries `docs/02` §4.5's **arithmetic strip verbatim** (`50 base -5 Common +3 Guildhall +6 furnishings = 54 baseline`), the slot list, the whole catalogue with prices, and a warning when spending would hit `docs/05` §7.6's ceiling and do nothing. BL-43 records why buying and placing are one action. **Found and fixed a real bug:** `reset()` never cleared `facility_tier`, `_trophy_witnesses` or `_pending_departures`, so a second New Guild inherited the first one's Guildhall.
- [x] **`game/screens/Market` — the last canon building the core loop was missing.** Sell tab carries `docs/02` §6.3's inventory with the **"worn by" column and the confirm it exists to force** (a refusal would make raid upgrades unsellable forever; a silent sale would let a misclick strip a tank), the sell-all helper with the before→after preview on the button, and `docs/02` §6.1's **buy-back shelf** — last 6 sold, at 1.25x, newest first, saved. Comfort tab is the Market's entry to the same buy-and-place verb, gated by `docs/02` §6.2's stall shelf. `sim/core/Consumables.gd` ships `docs/11` §7's six SKUs complete: prices, x2.4 per tier, x1.8 effect, the 20 stack cap, and the `kind` that says where each is spent. BL-44 splits the two stock ladders by what each is finer at; Q-45 records why the Buy tab is shut.
- [x] **`docs/11` §7's six consumable effects, the commit point, and the Market's Buy tab.** All six do what the doc says: the Whetstone and the Draught fold into the gear profile (melee-only / caster-only), the Guild Feast simulates at morale +5 **without storing it**, Steady Hands is a new `relief_bp` term through `Formulas` that respects ✅ CANON's per-rarity floor, the healing potion is a new sim phase after the healers, and the Rally Flask is a post-wipe purchase on the Results screen that gives back half of the penalty it just watched land. **`docs/11` §7's commit point holds**: choosing costs nothing, departing spends, and potions the sim never drank come home. The empty-loadout path is asserted byte-identical by SHA-256 against the goldens' own hash. BL-46 (group buffs once per attempt) and Q-47 (the flask's tier scaling contradicted its own effect column) recorded.
- [x] **`game/screens/RaiderDetail` (S05) and `docs/13` OQ-4's two-click repair.** The gear paper-doll lists every slot the class can fill, marks the empty ones, and offers the best upgrade in the loot window **with its delta on the button** — chosen by the same `item_worth` the Suggested split uses, so the screen and the one-click helper cannot disagree. Comfort is the full slot view OQ-4 asks for; the roster row carries the quick-apply, which spends an **Indulgence** rather than a Furnishing (Q-49 — a durable one-off is not "done many times per cycle", and that button would disable itself forever after one press). Q-48 records what stands in for the two contents `docs/13` §5 names that have no data yet: **nothing invented**, and `docs/02` §4.5's baseline arithmetic where the morale history would go.
- [x] **Morale history, and the day clock it caught (`docs/13` §5, BL-50, BL-51).** Thirty Day Ticks per raider — `{day, morale, note}`, one row per tick, the biggest mover named, a repeat day overwriting rather than appending so `docs/05` §7.2's deferred peer deltas cannot draw a spike that never happened. Drawn on S05 as a **sparkline plus the three biggest moves in words** ("day 4 -11 a wipe · day 7 +7 a hot bath"), because the question is directional. **It immediately caught a six-iteration-old bug (BL-51):** `record_attempt` resolved a Day Tick without advancing `day`, so twelve raids all happened on day 1 — invisible until something read the date. `_resolve_day_tick()` now advances the clock itself. No golden or sweep cell moved.
- [x] `sim/core/Reputation.gd` — **the 6-rank ladder, the earning rules and the gates (`docs/03` §3, §6, §7, §8.1, §9).** Thresholds 0/120/400/900/1800/3200, §6.2's `base × tier × obsolescence × catchup × repeat_decay`, §6.3's halving-every-5 repeat curve, §6.5's monotonic-rank rule and its one RP loss (a disband, clamped to the rank floor), and §7's per-rank gates. **`docs/03` §6.4's nineteen-row pacing table is reproduced row by row** — RP *and* rank after every row — because the doc says it is "the pacing the numbers in §6.1 were solved for", which makes the table the spec. Wired live: clears pay RP, the rank advances and announces itself, a disband taxes it, the board draws itself from the unlocked tier and prints what the next rank opens. Ships §8.1's M3 catch-up valve (BL-36).
- [x] **`sim/core/Recruitment.gd` — the recruit-quality matrix, the roll, and what a candidate arrives with.** `docs/03` §5.2's per-mille table with every canon "no longer find" asserted as a zero, and §5.5's **rarity-before-class order** measured rather than assumed: with eight of nine Legendary classes claimed the observed find rate is still ~1.5%, which is the whole reason the doc pins that order. `docs/03` §5.1's ❗trap has a test named after it — canon's "1%" is the Legendary's MISTAKE chance, not its find chance. Both `docs/03` §8.1 mitigations: M2's pity at 25 (forcing what the rank can actually produce, so the top rank forces Epic rather than a retired Rare) and M1's modal-tier floor, asserted across 40 boards. Gear recipes grant armour only — `docs/03` §4.1: "weapons are never granted at recruitment". Cost table reproduces `docs/04` §3.3 cell by cell. Q-52 records the two injected seams.
- [x] **`docs/03` §9's tuning file — extract reputation *and* recruitment tables to `data/reputation.json`.** Deliberately deferred until `Recruitment.gd` exists: §9's shape puts `find_weights` (recruit quality, `docs/03` §5) in the same file as the ladder, and extracting half a table now means churning it next iteration. Bring §9's load assertions with it — the two already asserted on the constants (thresholds strictly increasing; no rank reintroduces a rarity a lower rank retired) plus "every `find_weights` row sums to 1000".  **DONE ee5b64b** — the reputation *and* recruitment tables now live in `data/reputation.json`.
- [x] **`data/names.json` + `data/backstories.json`, and the two pools that read them.** Names are `docs/04` §7's three weighted shapes — 62% bare mundane, 26% mangled, 12% epithet — with both collision rules live, including the subtle one (**no `Steve` AND `Steev`**), which needed a `root_of()` that can trace a mangled or epithet name back to its mundane origin. Backstories are all eighteen of `docs/04` §8.3's tags at four variants each, with every draw rule asserted: no tag twice, the exclusion graph, **a Common always has something to be unhappy about** (canon's "hardest to keep happy"), and an Epic at most one complaint. Both of `docs/05` §7.5's backstory hooks are now live — the ±8 `backstory_offset` (scale derived from the extreme, so the documented limit is reachable) and the 1.5x/0.5x trigger scaling, mapped from `docs/04` §8.3's own "Listens for" column. Q-53 records the one gate a build loop cannot close.
- [x] **`game/screens/Tavern` (S07), and `docs/02` §11's building table as one source.** The card is `docs/04` §3.5's whole decision surface with **every backstory bullet face up** — the doc's own reason is that "the joke only lands if the player knowingly hires the guy whose bullet says he quits when benched", so a test walks the board and asserts not one is hidden. §3.2's refresh rules all three (free on run resolve, free on rank up, `50g × 2^n` capped at 400 and reset by raiding), §3.4's free candidate dismissal, and §5.3's Manage tab whose confirm **names the -2** before charging it. ✅ C12 is claimed on HIRE rather than on appearance, so rerolling past a Legendary cannot burn the class. **BL-54 corrects BL-44**: the Market stall is priced in `docs/02` §11 after all, so it is a purchase now, `sim/core/Buildings.gd` owns the table, and the Market sells its own upgrade.
- [x] **The nine Legendaries — `data/legendaries/<class>.json`, one file per class as `docs/04` §11.2 asks (not the single file this line used to say).** Natsuna is the Shaman because ✅ CANON says so; **the other eight are deliberately unnamed** and render `docs/03` §5.6's own placeholder, with a test that fails the moment somebody invents one. All three of `docs/04` §11.3's mechanisms are live: subscription (an event reaches them only if one of their OWN bullets listens — ✅ CANON A11's "not bothered by many things easily"), the 0.35 negative multiplier, and the floor of 40 that a test hammers with 80 negative triggers. BL-57: nobody starts at canon's 87, which is a mid-campaign snapshot and not an arrival value. BL-58: quirks are named and inert until `docs/07` specs them. BL-59: one of five BIG-dumb conditions is live and the other four are recorded rather than approximated.
- [ ] **`docs/07`'s nine Legendary quirk specs, then turn them on (BL-58).** Each file already carries the id, the name and the intent; what is missing is the combat effect and its balance pass against the sweep.
- [ ] **The four remaining BIG-dumb conditions (BL-59).** All four land in `GameState._refresh_big_dumb()`; each needs a counter first — a per-boss wipe streak, wishlists, per-tier trigger counts, and a payday.
- [x] **`game/core/SaveGame.gd` — versioned saves, and a safety bug it exposed.** `docs/14` §7.2's atomic write (temp + rename, so an interrupted write cannot destroy the previous save — asserted with a half-written temp file beside a good one), §7.1's header-first read, §7.3's refusal of a newer save **before anything is built** ("never partially load"), the `.bak` before a migration, a real-but-empty migration chain, and §7.2's three slots with three rotating autosaves each. `docs/14` §7.4's triggers are wired at the three moments that doc names, Continue on the main menu opens the newest loadable slot by name, and the window-close save runs before Godot accepts the quit. **BL-56**: wiring those triggers made the TEST SUITE a save-writer, which would have overwritten a dev's own guild on every `verify.sh` — the directory is now redirected and a test asserts it. Two real defects found on the way: `played_seconds` living in two places, and same-second saves tying so the load menu offered the older one.
- [x] **`docs/14` §7.4's remaining autosave points, and manual save slots on a screen.** Still owed: the town-screen-transition autosave (`docs/00` §6.2 asks for it), the attempt-start save *after* the master seed is drawn (`docs/07` §9 needs the seed persisted before round 1 or the save-scum policy is unenforceable), and a Load/Save screen that shows all three slots with `SaveGame.slot_summaries()` — which already returns everything such a screen needs.  **DONE e4bbba9** — every §7.4 point wired, S16 Load/Save shipped, v13 frozen with a v10-v13 fixture chain and a damaged-slot readout.
- [x] Wire reputation → town unlocks → recruit quality; the full macro loop closes  **DONE 4a5b09a** — the town reads the rank; gates and recruit quality follow it.

## M4 — Art & the 2D-HD pass

> **Reframed 2026-09-09.** The lead designer supplied three master reference concepts (`ideaboard/Reference Concepts/`);
> they are the target framebuffer at 1:1 (1536×1024) and set the quality bar. Where their UI does not fit the design,
> the design wins (`art/ref/specs/00-canon-reconciliation.md`). The pre-existing tasks below that assumed a 640×360
> grid or the parchment set are struck through; the live list is the art-pass block that follows.

- [x] **Instruments** — `tools/art/refkit.py` (measure), `refdiff.py` (score a shot), `slice.py` (721 sprites cut from the sheets), `tools/shot.gd --fixture` (exact-size capture seeded with the concepts' data), `tools/diff_all.sh` (the art gate). Baseline MAE 171.8
- [x] **Specs** — `art/ref/specs/00..11`: canon reconciliation, three concept layouts, palette, type, component kit, two asset inventories, background plates, screen audit, engine architecture
- [x] **Engine layer** — 1536×1024 base + expand, linear filter, importer defaults, bloom verified on Mobile; `Palette.gd` (reference tokens + legacy aliases), `Fonts.gd`, `Type.gd`, `Theme.gd` (one code-built Theme), `Widgets.gd` (the kit), `Frame.gd` (the dashboard shell), `Cards.gd` (card / paged strip / event log), `Bar.gd`, `Badge.gd`; `tools/aseprite/gen_ui.lua` 9-slice chrome
- [x] **Town** on the frame (Concept 3, full-bleed) — RECOGNISABLY THE SAME DESIGN, IoU 0.44
- [x] **RaidPrep** on the frame (Concept 1's sidebar is this screen) — strip pages in fours (R1), rewards from `loot_slots` (R3), verdict callout not an invented % (R8), no fabricated cost (R7)
- [x] **Tavern** — candidate board as cards, selected candidate in the sidebar with every backstory bullet face-up, "Hire — N G" as the one CTA
- [x] **AdventureBoard** — rung list in the scene, selected rung as the mission panel, "Go to prep"
- [x] **Guildhall + Roster + Facilities** — archetype C: content panel over the hall plate, card grid, in-panel sub-tabs, portrait mini-grid picker (R6)
- [x] **RaidView** (Concept 2) — boss bar, four combatant panels auto-paged, combat log; fold `hp_after` from the PLAY_BY_PLAY stream (R5)
- [x] **Results** — Concept 2's frame, outcome stamp, survivors/fallen cards, loot rows as slots
- [x] **Market**, **RaiderDetail** — slot grids and mini-grid pickers on the C chrome
- [x] **Settings**, **MainMenu** (menu plate + wordmark + CTA stack), **Boot overlay**
- [x] **Class portraits ×5** (monk, druid, shaman, bard, wizard) — DERIVED, not drawn: `tools/art/derive_busts.py` re-hues a reference bust's defining regions in HSV (luminance kept, so the painted shading survives) and adds a few silhouette pixels (druid's leaf, bard's feather, shaman's paint). Druid/bard/shaman read; monk and wizard were the weakest and got a second pass 2026-09-10: the wizard is now spoof grown old (violet robes, grey sideburns, a stamped white beard and moustache, a star on the hat); the monk keeps bork's paint with brown hair, a saffron-flattened robe and canon's headband stamped across the brow — three attempts at shaving the painted hair by mask all failed (halo, or the brows went with it). Two earlier routes were rejected by eye (3× sheet upscales, Concept 1 figure crops; `art/export/portraits_rejected/`). Still open: **8 class glyphs**
- [x] **Icon set** — 10 morale faces, 7 slot-type glyphs, 6 rank sigils, cog/fast-forward 24px, pre-rendered wordmark 58/44 + tagline (`tools/aseprite/gen_icons.lua`, `game/assets/ui/wordmark_*.png`); provision icons and page arrows DONE (all six provision icons are in `game/assets/ui/icons/` — CRITIC-R6; page arrows `gen_icons.lua` -> `Widgets.pager_button`)
- [x] **SceneStage** — plate + animated fire/torches + PointLight2D flicker + embers + wandering bubbles, data-driven from `game/assets/scenes/*.json`; RaidView boss painted out of the arena plate (09 §1.3) — DONE 2026-09-10: `game/ui/SceneStage.gd` + `game/assets/scenes/{guildhall,camp}.json`; flames from `tools/aseprite/gen_fire.lua`; lights at a third energy (the plates carry their own light); painted bubbles/lines inpainted out of the plates (`tools/art/patch_bubbles.py`). Honours `reduced_motion` / `reduced_effects`.
- [x] **Remove the twelve legacy `Palette` aliases** once the last screen converts; update `test_no_pure_black_or_white_in_the_palette` to the new names — DONE 2026-09-10.
- [ ] **Diff loop to VERY CLOSE** on Town / Guildhall (Kit) / RaidView with `tools/diff_all.sh`; then the expand-mode wide-screen check — 2026-09-10: Kit 16.9 MAE / IoU 0.28 (sidebar pixel-aligned; the residual is font shapes and the living scene), Town 26.3 / 0.41, RaidPrep 20.2 chrome-masked. VERY CLOSE needs IoU > 0.65, which the reference's different UI font makes unreachable on text-heavy regions; the useful next step is region-masked scoring per component rather than more whole-screen passes.
- [x] **Item art for the three slots without any** — DONE 2026-09-10 (`tools/aseprite/gen_items.lua`: head/legs/feet/off-hand × iron/leather/cloth, a lute for INSTRUMENT; `Cards.gear_icon` picks the material from the item's family). Was: (head, legs, feet; off-hand borrows a reward icon) — `Cards.gear_icon` falls back to the outline slot glyph, which is honest but flat beside the sword/armour icons; author ~47px icons per slot × a few tiers (the sliced sheets have none) so a worn cap looks like a cap


- [ ] ~~`art/palette.gpl` — master palette from `docs/12` (ramps + UI accents). Loadable in Aseprite~~ — superseded by the art-pass block above
- [x] `tools/aseprite/lib.lua` — shared Lua: colour, blend, rounded/chamfered rects, gradients, glow, notch, rivet, 9-slice export
- [ ] ~~`tools/aseprite/gen_raiders.lua` — generate all 9 class sprites, silhouette-distinct per `docs/12`, with idle/attack/cast/hit/death/**fumble** tags~~ — superseded by the art-pass block above
- [ ] ~~`tools/aseprite/gen_portraits.lua` — roster portraits per class × rarity visual tier~~ — superseded by the art-pass block above
- [ ] ~~`tools/aseprite/gen_ui.lua` — 9-slice panels, buttons, frames, the diegetic parchment/corkboard set from `docs/13`~~ — superseded by the art-pass block above
- [ ] ~~`tools/aseprite/gen_items.lua` — item icons by slot/family/tier~~ — superseded by the art-pass block above
- [ ] ~~`tools/aseprite/gen_town.lua` — town buildings + reputation-tier variants (`docs/02`)~~ — superseded by the art-pass block above
- [ ] ~~`tools/aseprite/gen_backdrops.lua` — encounter backdrops with layered depth planes~~ — superseded by the art-pass block above
- [x] `tools/build_art.sh` — done in M0; this milestone just needs the generators below to exist
- [ ] ~~`game/theme/` — Godot Theme resource: typography (`docs/13`), 9-slice panels, colours from the palette, tabular figures for tables~~ — superseded by the art-pass block above
- [ ] ~~Swap all programmer art for generated art across every screen~~ — superseded by the art-pass block above
- [ ] ~~2D-HD presentation pass: layered parallax backdrops, `WorldEnvironment` bloom, tilt-shift/DOF on near+far planes, light shafts, particle atmospherics (`docs/12`)~~ — superseded by the art-pass block above

## M4b — the bare stages (the 2026-09-11 art directive)

> The designer's ruling: stop matching the mockups where the mockup carries **painted people**, **baked
> speech bubbles**, **baked damage numbers** or **label pills**. Six bare plates are installed as
> `game/assets/bg/stage_*.png`; the figures and effects are now **ours**, rendered and animated over them.
> `art/ref/specs/09-background-plates.md` §4 lists the animated layers per plate, in order, with
> coordinates — that table is the build order, and its "keep as ambient / baked v1" rows are what this
> milestone deletes.

- [x] **`SceneStage` gains an actor layer.** DONE (audit `M4B-ACT-01`). `tools/art/gen_actors.py` turns the
      reference's own sliced idle frames into 56 strips + `game/assets/actors/actors.json` (12 real cycles,
      44 synthesised breaths for the single-pose townsfolk); three of the cut rects turned out to be mis-cuts
      rather than poses and are dropped by name. Figures are placed by their FEET, sorted back to front by
      tree order rather than `z_index` (the bubbles are Controls added after them), and phase-spread so a
      crowd is not one object with many heads. `apply_settings()` came out of `_ready()` so both `docs/13`
      §13 switches are testable; `tests/unit/test_scene_stage.gd` has 13 tests, one of which reads the actual
      pixels so the manifest cannot lie about the art.
- [x] **One scene JSON per stage** — DONE (audit `M4B-ACT-02`): `stage_camp` (12 figures), `stage_tavern`
      (14), `stage_market` (12), `stage_arena_cave` and `stage_arena_dungeon` (fire and light only — spec 09
      §4.3 row 5 gives the twelve combatants to the raid screen, so an arena that shipped its own crowd
      would put strangers in the fight), and `stage_town` (a plate and an explanation: it is an aerial, a
      person on that street is 10-14px, and every strip we own is 21-48px — `M4B-ACT-04`).
      `tools/art/preview_scene.py` composites the same stack in PIL, so a placement is checkable without
      booting the engine; each file carries a `note` array with its own reasoning.
- [x] **Water shimmer and crystal pulse** — DONE (audit `M4B-VFX-01`, spec 09 §5 rows 4 and 5, with that
      section's own numbers). Authored into five scenes; the reduced-motion switch travels as a shader
      uniform because the animation is TIME-driven inside the shader.
- [x] ~~**The layers that need ART rather than code** (still `M4B-VFX-01`)~~ — CLOSED 2026-09-15 (W6-LEDGER, UI-42): the
      airship row is RETIRED with the crop it lived on (the shipping plate is the designer's bare `stage_camp.png`,
      which has no harbour); row 3's rotating core has no subject until an encounter has a portal; the cloud
      drift ships as the `scroll` layer. `M4B-VFX-01` closed with W4-LIFE's layer list.
- [ ] **Convert the screens, one per commit, each with its own `tools/diff_all.sh` shot**, replacing the
      old `*_plate.png` crop with the bare plate + `SceneStage`:
      ~~Town~~ (done: `stage_camp` at offset -46,-62, callouts moved off the figures) ·
      ~~Tavern~~ (done: `stage_tavern` at offset -320,-130, dim eased to 0.86) ·
      ~~Market~~ (done: `stage_market` at offset -330,-240 — it had been showing the CAMP) · MainMenu ·
      ~~RaidPrep~~ (done: `stage_arena_cave` at offset -30,-120; which arena a fight uses is now Q-96) ·
      ~~RaidView~~ (done: the same bare cave full-bleed at offset 0,-280, no dim) ·
      ~~Results~~ (done: the same cave at RaidView's offset — it also settles `m4t-11`) ·
      ~~AdventureBoard~~ (done: `stage_camp` at offset -20,-80 — it had been showing the HALL) ·
      ~~MainMenu~~ (done: the bare aerial `stage_town`, mounted as a stage so it wakes up with `M4B-VFX-01`) ·
      Guildhall · Roster · Facilities · RaiderDetail · LoadSave · Settings — **all six are the guildhall
      crop, so all six wait on `M4B-CONV-03`**
- [ ] **Retire the old crops** (`camp_plate`, `tavern_plate`, `arena_plate`, `guildhall_plate`,
      `menu_plate`, `arena_stage`) once nothing loads them, and drop the paint-out lists from spec 09 §3.
- [ ] **The Guildhall interior has no bare plate** — the six supplied are camp / market / tavern /
      town_world / encounter_cave / encounter_dungeons. Either the camp stage serves the guild's home
      (which is what `docs/02` §9's rank-progression scene wants anyway, audit `M3-LOOP-05`) or the
      interior needs one. **Ask; do not paint over the reference.**
- [x] **Which sliced figure is which canon class** — DONE (audit `M4B-ACT-03`, ruling `docs/15` BL-68):
      canon's equipment families decide, because a figure shows what it is wearing. Four armour families,
      four labelled reference figures; `game/assets/actors/class_actors.json` carries a row per class with
      its reason and `SceneStage.actor_for_class()` reads it. It disagrees with the busts' pairing on
      purpose — a bust pairs by headgear, a figure by armour — and BL-68 says so.
- [x] **The twelve combatants as sprites on the arena floor** — DONE for row 5 (audit `M4B-ACT-05`):
      three ranks of four on the cave's measured plateau, tanks nearest the boss, healers at the back,
      placed by the SCREEN through the stage so the party gets the same contact shadow, phase spread and
      reduced-motion switch as any other crowd. A fallen raider greys and stops breathing — the same rule
      10 §2 R4 gives the panel, read from one function by both.
- [x] **The boss sprite** — DONE (spec 09 §4.3 row 4, `M4B-ACT-05`). A single texture rather than a strip,
      so it gets a 3px/4s bob instead of frames; its feet are computed from its own height
      (`404 + height`, clamped to the right gallery's measured stone) because the sliced creatures run
      77px to 152px and a fixed y puts the tallest one's head behind its own HP bar. It greys when the
      bar reaches zero. A test walks every creature in `game/assets/enemies/` and holds both constraints.
- [x] **Results' fallen grid fits a full wipe** — DONE (audit `M4B-CONV-05`): more than six dead switches
      to a compact cell that puts exactly six in a row, so twelve are two rows instead of three and no
      name is cut. Scrolling was already there and was not the fix — it hid the overflow instead.
- [ ] **Damage numbers, the wipe sequence and the event-badge glyphs become real renderers** rather than
      baked pixels (audit `M6-JUICE-05`, `M6-JUICE-03`, `m4t-09`).

## M5 — Content breadth

- [x] Adventure 0 + Tutorial Raid, with canon's skippable-with-warning rule and the two "crap trinket" rewards  **DONE c797491 + 0e8a5e4** — A0, the Tutorial Raid and the skip gate landed first; **the two rewards did not, and this line said they had.** The grant, its once-only guard and the drop-pool bypass were all written against two item ids that resolved to null, and both tutorials paid 0 G because docs/11 §F2's row was in neither payout table. Both fixed (audit `M5-TUT-04`, `M5-TUT-05`; ruling `docs/15` BL-77). The Tutorial Raid is still UNWINNABLE and pinned as such by `test_tutorials.gd` (0/20); see BUILD_STATE.
- [ ] Adventure 1 and the full Tier 1 raid content polished (5 encounters, real mechanics from `docs/10`'s vocabulary)
- [x] Mistake log-line writing pass — every mistake type gets several varied, genuinely funny lines. This is where the comedy lives; treat it as content, not filler  **DONE a8a2673** — 228 lines and the loader that picks them. Still owed: `M5-COMEDY-09` (six of eighteen types never fire in any golden) and `M5-COMEDY-12` (a human review gate — 'genuinely funny' cannot be self-certified).
- [x] **`docs/08` §9.6 — the Tiers 2-5 boss budget** — DONE (audit `M5-T25-01`), and it is the gate the
      encounters were waiting on. Generated by `tools/gen_items.gd -- budget`, with Tier 1 derived by the
      same method and landing on §9.2/§9.3's hand-published numbers, which is the argument that the upper
      tiers are canon's curve continued. `tests/unit/test_tier_budget.gd` holds that agreement.
- [x] **Tier scaling generator — 412 records written and checked** (audit `M5-T25-05` + `M5-T25-06`).
      Running it turned up two real defects, both now ruled and tested: the first generated rung INVERTED
      at the slot level (`docs/15` BL-70 — a rising family total does not stop §13.4's re-split leaving one
      slot behind), and generating the files SHIPPED 336 items called "TIER2's Boots" into the live content
      set, because the loader discovers tiers by filename (BL-69 — a tier mounts only once its words are
      answered). `tests/unit/test_tier_scaling.gd` asserts monotonicity per slot, per family, across rungs,
      and in the numbers that reach the sim. power
- [x] **Tier 1's shipped numbers reconciled to `docs/08` §9** (audit `M5-T25-02`, ruling `docs/15` BL-71).
      The data and `docs/10` had been carrying an earlier §9.2 — the one from before the +2 Power
      correction on the Boss-4 chests. Goldens regenerated deliberately; `e5_first_clear` went 21 to 25
      rounds and the sweep's lever readout moved from morale 88pp / rarity 38pp to 100pp / 13pp.
- [x] **The tier-aware encounter validator** (audit `M5-T25-11`): coverage, docs/10 §473's escalation
      rule, a slot-by-slot ladder check and orphan mechanics, as a pure function so each rule is tested
      by a tier that breaks it. All five tiers pass — the first evidence the generated encounters are
      legal content and not just well-formed JSON.
- [ ] Raids 2–5 + Adventures 2–5 encounter definitions — the generator wrote them and the validator
      accepts them; what is still hand-authored is the judgement `docs/10` §6 asks for
- [x] Boss mechanic library implemented (tank swap, raid damage, ground effects, adds, interrupts, enrage, positioning)  **DONE 729b8ea** — `MECHANICS_WITH_NO_BEHAVIOUR := []`. All twelve armed, the roll site is `_phase_mechanic_checks()`, and only M01/M03/M05/M07 demand a response per `docs/10` §10.
- [x] **`AC_K` and `MANA_TO_SPELL` stop being flat** (audit `M5-T25-03`, ruling `docs/15` BL-72). Both are
      functions of the tier behind a named step, defaulting to tier 1 so nothing shipped moves. Two of
      `docs/08` §9's own claims were corrected by measurement: the cap binds at Tier 5, not Tier 3, and the
      step is per TIER — read per rung it over-shoots to 11% tank mitigation by Tier 4. Threading it into
      the sim and the budget together is `M5-T25-15`.
- [ ] **The 85 hand-authored exceptions** (audit `M5-T25-07`) — the generator writes the capstones and
      charms at the right values, `gen_items` now MERGES rows marked `hand_authored` rather than
      clobbering them, and the Boss 5 trinket pool is finally drawn from (three of every four trinkets
      could not drop). What is left is the names and the jokes, blocked on the tier words.
- [x] **The reward caps get their denominator** (audit `M5-QAB-5`). `docs/11` §11.2 caps board coin
      at "~15% of lifetime income" and nothing counted lifetime anything — `Achievements.coin_cap()`
      had been dividing by a zero fallback since it was written, so every cap was zero. Three
      persisted counters that only ever rise, save v15 with its migration step, its moved freeze
      record and a committed v14 fixture. The opening 60 G is seed capital, not income, and a test
      says so because the other reading is defensible.
- [x] **The achievement board is connected** (audit `M5-QAB-6`). 988 lines of engine, 40 validated
      records and a whole reward-cap model were load-bearing for nothing: `Achievements.evaluate()`
      had no caller and GameState had no field to write an earned record into, so every row read
      Locked forever and no reward had ever been paid. Now: earned state (with the day), the claim
      set, town flags, save v16, evaluation at the attempt (the only moment the event-only records
      can be decided) and at every §7.4 save point, all five reward kinds applied, and the Records
      tab's claim button. Board coin does not count as income, or the cap would widen itself.
- [x] **The generated content is gated against its generator** (audit `M6-EXP-06`, `docs/15` BL-74's
      one owed pre-export gate). `gen_items.gd -- check` had existed from the day the generator was
      written and had never been called; it is now `verify.sh` stage 2/8, so a hand edit to one of
      the 412 generated rows — or a `TierScaling` rule change nobody re-ran — fails the build and
      names the file. Proven by reintroduction. All six of `docs/14` §10.1's gates run now.
- [x] **Every encounter's comedy line is gated, and the doc that governs them is honest**
      (audit `M5-COMEDY-11`, ruling `docs/15` BL-76). Three gates checked `comedy_line` and no two
      agreed — 40 characters, 20 characters, and non-empty — so the corpus passed all three by
      accident. One constant now, read by all three, and two checks nobody had made: every
      encounter in `data/` carries a line, and no two share one. `docs/10` §6 said "one sentence"
      while half the shipped lines were two; the doc moved, because they are the better writing.
- [ ] Legendaries: hand-authored quirks and unique morale rules
- [x] **The achievement board, tested at last** (audit `M5-QAB-1` + `M5-QAB-2`). 988 lines of engine and
      40 records had no test and were already wired into the Records tab. Now: the type split against
      docs/11 §11.1, the no-dailies rule, the Known gate, the earned/claimed walk, the 15% coin cap and a
      claim that is REFUSED rather than quietly paid smaller — plus the eight records that shipped without
      citing their source, which now do.
- [x] **Endgame state after Raid 5** — DONE (audit `M5-END-1`, ruling `docs/15` Q-88). Three fields on
      GameState set by the FIRST clear of the encounter `Achievements.is_completion_encounter()` names,
      save v14 with its migration step, fixture and frozen-shape record.
- [x] **S17 — the Completion screen** — DONE (audit `M5-END-2`, ruling `docs/15` BL-73). docs/10 §13 row 1
      said doc 13 "must gain" the row and doc 13 never did; the inventory now carries S17 and §9.5 carries
      its panel spec. The screen is a report and a door back to town, built from figures the campaign
      already keeps, fired once from Results on the completing clear and re-readable from the Records tab.
      The credits block is read from `data/credits.json`, which ships saying the roll is unsigned — who the
      game credits is `M5-END-4`, a person's signature.
- [x] **The post-clear surfaces** — DONE (audit `M5-END-3`). docs/10 §13 row 2's three continuing
      activities: repeat clears and the Legendary collection were both already ENGINE-complete and
      completely invisible. The collection meter is now on the Tavern, where Legendaries are found, and
      beside the record wall on the Guildhall's Records tab; the Adventure's Board states the goal under
      its own subtitle once `completed` is true. Nine is never typed — `Achievements.legendary_goal()` is
      the class list's length — and one phrasing serves all four surfaces. A test bans the words Tier 6,
      heroic, prestige, New Game+ and difficulty from the post-clear board, because docs/16 R-4 calls
      doc 10 §13 a standing invitation to invent an endgame and lists those as cut.

## M6 — Polish & ship

- [x] Audio: UI clicks, hit/heal/death cues, ambience per screen, music beds. Generate procedurally or source CC0; wire a bus layout with volume settings  **DONE 756081a** — synthesised with numpy rather than sourced. Music beds and the per-rank town soundscape remain (`M6-AUD-05`, needs an owner).
- [ ] Juice pass: transitions, easing, hover/focus states, damage numbers, ~~screen shake on wipes~~ (STRUCK 2026-09-15 under the ship plan's §6 row #43 — `docs/13` §11.4 "no red flash", §12.2 "nothing in the UI loops, pulses, or breathes", §13 reduced flashing unconditional; the stamp press + 12% dim is the beat; audit `M6-JUICE-04` waits on the designer's one word), latency budget from `docs/13`
      — **the §11.4 wipe sequence is the first beat built on it** (audit `M6-JUICE-03`): five of its
      six beats now land at their documented offsets, driven by a clock rather than `await` because
      §11.4 requires the whole thing be abortable on any input. The stamp press is the first tween
      in the game and goes through `Widgets.tween()`, so §13's "60ms with no rotation" carve-out
      falls out of the gate rather than being remembered. The ink bleed and wax seal are art and are
      **and the two art beats landed too** (`M6-JUICE-08`): `tools/aseprite/gen_wipe.lua` authors the
      ink blot in the stamp's own red and the wax seal in the commit control's wax, both
      deterministic. The post-mortem slide is a screen transition and belongs to `-02`.
      — **the motion gate is built first** (audit `M6-JUICE-06`): `GameSettings.motion_duration()` turns
      `docs/13` §12.2's milliseconds into seconds and applies §13's reduced-motion setting in one place,
      `Widgets.tween()` is the only sanctioned way to make a tween, and `tools/lint_motion.sh` fails the
      build on any other `create_tween(`. A setting each new animation must opt INTO is wrong by default,
      so it is a lint and it landed while the count of tweens in the game was still zero.
- [x] Settings screen: resolution, fullscreen, volumes, text scale, reduced motion, colourblind-safe morale coding  **DONE** in M3 — `GameSettings` holds all 18 of `docs/13` §15.1's closed inventory. The `text_scale` Theme half remains (audit `M6-A11Y`).
- [x] Full accessibility pass per `docs/13` — keyboard navigation everywhere, no hue-only information  **DONE 24eeb2b + d860cf4** — keyboard navigation everywhere, a CVD switch with `tools/art/cvd.py`, and the focus check became gate stage 4 (`tests/unit/a11y_smoke.gd`).
      **Emoji-free mode joined it** (audit `M6-A11Y-04`): the option had one consumer out of eight,
      so turning it on changed one panel and left emoji on the Roster, raid prep, the Market and the
      Guildhall. Every site goes through `Cards.morale_glyph()` now and `tools/lint_motion.sh` fails
      the build on anything that reads the raw table. The focus ring (`M6-A11Y-03`) and the Tavern
      card's state word (`M6-A11Y-08`) turned out to have landed already.
- [x] **The Adventure ladder is swept at the stages it is actually played at** (audit `M6-BAL-01`).
      `docs/08` §9.1a's two intermediate kits — feet + first weapon, then legs — could not be built
      by `Scenarios.gd`, so no cell in the sweep ever sat on the stage a rung is sized for. Both
      exist now, the Adventure table marks that diagonal, and the measurement is the evidence
      `M6-BAL-04` was missing: a Common party clears A1 at 50% and A2 at 63% at morale 55, and
      neither at morale 15. A new guild's ceiling is 45.
- [ ] Balance pass 2 using `balance_sweep` across all tiers; tune to target clear-rate curve
      — **the drift gate is armed** (audit `M6-BAL-02` pieces 1-2): `tests/baselines/sweep_baseline.csv`
      is committed at 4,000 runs, and `./tools/balance_sweep.gd -- --drift` now fails past `docs/14`
      §9.3's 5 percentage points instead of answering "NO BASELINE". Proven by halving `AC_K`, which
      moves E5 by +9.8pp and is named. **Never re-baseline to go green** — `--rebaseline` exists so a
      balance change is a reviewed diff with a receipt, the same discipline the goldens keep.
- [x] Save-format freeze + migration test  **DONE e4bbba9** — see the autosave row above.
- [x] `tools/export_build.sh` — Windows release export via installed templates; verify the exported `.exe` launches  **DONE** (audit `M6-EXP-01`..`-05`, ruling `docs/15` BL-74). Both files landed unreviewed in the
      rename commit and had never been run; the whole chain is now verified end to end — sim purity,
      the 6-stage gate, import, Windows **and** Linux presets, five pck-hygiene greps at zero, and the
      exported build booting clean for 180 frames from the pack. `docs/14` §10.1's gate list named five
      tools this project never grew; BL-74 maps all six gates onto the command that runs each and
      corrects four rows of §10.1 in place. `tests/unit/test_export.gd` gates the configuration.
      **A release is blocked on CONTENT, correctly**: 16 files carry `stats_pending`/`name_pending`
      (the generated tiers and the eight Legendaries nobody may name), so a plain run HOLDS and
      `--dev` stamps its output NOT SHIPPABLE.
- [x] **Playtest sweep** — `tools/playtest.gd` plays the whole Tier 1 campaign, eight guilds, driving
      the campaign rather than the UI; the ladder and the party suggestion moved out of the screens
      into `RaidPlan` so the harness and the game walk the same one. Gate stage 6/7. **It is not
      completable today and that is a measured finding, not a harness bug:** a new guild's morale
      ceiling is 45 (`docs/05` §8's Common baseline, where rest stops dead) and at 45 the Adventure
      ladder stops 6 of 8 guilds at A2 in full T1 Adventure gear. Filed as `M6-BAL-04`, the third
      pinned balance defect and the first found end to end.
- [x] `README.md` at repo root — what the game is, how to run it, how to build it  **DONE** — `README.md` at the repo root.
- [x] **Citations to the loop's own plan files are checked** (audit `M6-DOC-06`). `build/plan/` is where
      the parallel agent waves wrote their handoffs; the waves were consolidated and eight citations in
      shipped code were left pointing at files that had been renamed or never written — including a
      `handoff-debt.md` §1 cited twice for a document that does not exist, with real untracked work
      behind it. Thirteen sites repointed at what now holds each decision, and `test_docs_links.gd`
      gained a fourth failure mode so it cannot happen a third time.
- [x] **The queue can be checked against the tree** (audit `M6-DOC-07`). Thirteen open items were found
      already finished in one week, and twice that cost the iteration's PICK rather than only its
      orientation. `python tools/audit_stale.py` ranks open items by how much of what they NAME
      already exists; `tests/unit/test_audit_hygiene.gd` holds the queue's shape (unique ids, a
      status the brief can act on, an open item that says what is left, a done one that says what it
      did, a source on everything). Eight more items reconciled in the same pass.
- [ ] Final pass: update `BUILD_STATE.md` to a handover summary once the ship tooling's rulings land (M6-FINAL-03 cut it to its length rule and stated the three gaps in W5-TOOLS; the row stays open until then). Dead code and TODOs are DONE and need no second hunt: the by-basename reference audit of every `.gd`/`.tscn` under game/ sim/ tools/ found exactly one unreferenced file, `tools/probe/diag.gd`, deleted in 40ebf32, and the TODO/FIXME grep across game sim tools tests data returned nothing (M6-FINAL-02)

---

## Discovered work

*(The loop appends newly found tasks here, then files them into the right milestone.)*

- ~~**`docs/08` cross-references are broken.**~~ RESOLVED — and then made unrepeatable: `tests/unit/test_docs_links.gd` walks `docs/`, `art/ref/specs/` and `build/plan/` and fails on a path or an anchor that does not resolve, so a dead cross-reference is now a red gate rather than a sweep somebody has to remember.
- **AC reading is effectively decided.** `docs/08` §3 works three readings against a "window proof" and recommends **Reading 3**: `mitigation = (AC*2)/((AC*2)+AC_K)`, `AC_K=60`, clamped at `MITIGATION_CAP=0.75`. Implement as the default value of the switch in `Formulas.gd`; keep readings 1/1b/2 selectable. Record in `docs/15`.
- ~~**Mana is decided as Model A+.**~~ RESOLVED 2026-09-15 (wave 7, audit `DW-C1`/`DW-C2`; `docs/15` BL-87). Mana is a magnitude stat and **Focus** is class-fixed, never on gear — and Focus is DECIDED for 1.1, not built in 1.0, with its numbers written down. `docs/07`'s three wasted-heal mistakes read "Focus (1.1)" and cost the round and their token in 1.0; docs 06 and 09 are reconciled by `build/plan/handoff-W7-DOCS.md` §6-§9.
- ~~**Ownership collision: mistake-chance equation.**~~ RESOLVED 2026-09-15 (wave 7, audit `DW-D1`/`DW-D2`). **The line above had it backwards and cost a reading twice:** `Mistakes.gd`/`Formulas.gd` ship `docs/05`'s shape and coefficients at `docs/08`'s ownership location (`docs/15` BL-20), which is the right answer and always was. `docs/08` §8.8 now publishes *that* equation in basis points and `docs/05` §5.1-5.4 are pointers to it, keeping only §5.2's band deltas; `docs/03` §4.2's copy of the table is struck. `test_canon_guard.gd` reads the doc's table and asserts it against `Formulas`, so the two cannot fork again.

- **Head-family asymmetry (`docs/09` §4.4, OPEN).** `Enums.gd` encodes both `warrior_head` and `warrior_bard_head` because the canon matrix splits them but the Tier 1 Adventure table ships a single shared `Iron Adventurer's Helm`. When `items_t1_adventure.json` is authored, decide which family the helm belongs to and record the call in `docs/15-open-questions.md`. Loot routing depends on it.
- ~~**Test suite runtime.**~~ RESOLVED in iter 8: the suite ran slowly because Godot had no global class cache and fell back on every script resolution. `verify.sh` now regenerates it; runtime went 3.8s -> 0.39s with more tests.
