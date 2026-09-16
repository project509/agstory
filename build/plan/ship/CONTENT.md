# CONTENT — ship report (encounters, items, tutorials, comedy corpus, names)

_Reporter: CONTENT. Date: 2026-09-15. Read-only pass over data/, sim/content/, docs/04/07/09/10/11/14/15, audit.json rows M5-T25-*, M5-TUT-*, M5-COMEDY-*, Q58-*, Q59-3, M5-QAB-3._

## Executive summary

1. **Shippable today:** Tier 1 end to end — 5 raid + 3 adventure + 2 tutorial encounters, 22 + 28 + 48 + 2 items, 192 + 36 mistake lines across all 18 types with the repeat guard, 36 names, 18 backstory tags, 40 achievements, the Records tab — all authored, validated on load, and rendered (sheets confirm the joke line, the tutorial trinket and the Tavern bullets on screen).
2. **Not shippable:** the game ends at Raid 1. Tiers 2-5 are fully generated and authored (304 items, 32 encounters with mechanics and comedy lines) but do not mount because 20 tier words are unnamed (BL-69); the eight Legendaries are unnamed and, as a consequence of the first gap, unreachable anyway (Renowned needs 1,800 RP; Tier 1 pays 240).
3. **Not shippable:** the first raid a player fights cannot be won — the Tutorial Raid clears 1/20 and A3 0/24, both pinned by tests, both the same arithmetic (a swing priced without M01's 2.5x), plus the morale-45 pin (M6-BAL-04). No Q row exists for it yet. This outranks everything else in this report.
4. **Biggest gap 1 (designer, wave 6):** one sitting that answers the 20 words, the 8 names, the swing-vs-M01 formula and the morale lever — after which the loop can mount five tiers, flip two pins and run S17 in play.
5. **Biggest gap 2 (loop, wave 7):** tiers 2-5 have never been simulated — the sweep, the playtest and the goldens are Tier 1 only and the sim is tier-blind (`AC_K`/`MANA_TO_SPELL` switches exist, nothing passes a tier). Thread the tier, sweep each tier, expect walls, record them (CONTENT-06).
6. **Biggest gap 3 (writing, waves 7-9):** the 68 hand-authored exception items have numbers and no names or jokes; one type of 18 (Ninja-Pull) can never fire; the joke row is cut at ~62 characters on screen while the corpus averages 75; and nothing written has had its human read (CONTENT-03/-12/-15/-16).
7. **Audit hygiene:** 13 rows in my area are stale — M5-T25-09/-10 (encounters exist), M5-TUT-06/-08/-11/-12 (BL-79, rate, scripted mistake all landed), M5-COMEDY-03/-04/-08/-11/-13 (corpus, tests, BL-80 landed), M5-QAB-3 (Records built) — flip them in wave 6 so `audit_stale.py --top` stops pointing at finished work.
8. **Register defaults never applied:** Q-42 (charm possessive), Q-40 (one Vest), Q-28/Q-35 (starter weapons, Adventure off-hands), Q-43 (Warrior/Bard Mana twins) — one ITEMS unit in wave 6, before the words land so the designer names the final set once (CONTENT-05/-25).
9. **New content defects found:** two name pools (24 code literals on the starting roster never reviewed), 22 gendered backstory bullets against an 11-of-36 feminine pool ("Pauline … checking his own" is on the Tavern sheet), no tier keys for scene/boss/palette, an economy whose sell slope (x3.61/tier) outruns its sink slope (x2.4/tier) — all S-M, waves 6-8 (CONTENT-20/-23/-26/-29).
10. **Sizing:** 30 findings — 6 BLOCKED-designer, 4 REFUTED (stale audit), 20 CONFIRMED; loop work is roughly 19 S, 9 M, 2 L (CONTENT-06 tier threading + sweep; CONTENT-03 if the 68 jokes take a writer); nothing XL once the rulings land. Wave order: 6 = ask + hygiene + generator template; 7 = words land, tier threading, exceptions written, corpus fixes; 8 = tier sweeps, economy, hints, log fold; 9 = review page + human reads; 10 = the pins flip and the export gate clears.

## Findings

### CONTENT-01 — Tiers 2-5 items exist, are statted, and are held back only by the words
**Status:** CONFIRMED (the gap is a NAME gap, not a data gap)
**Evidence:** `data/items_t{2..5}_{adventure,raid}.json` — 28 + 48 rows per tier, 304 rows total, every row `name_pending: true`; zero `stats_pending` anywhere in `data/` (`grep -rlE '"stats_pending"\s*:\s*true' data/` returns nothing). Names render as the generator token: `data/items_t2_raid.json` row 1 `"name": "TIER2's Boots"`. `data/tier_words.json` tiers 2-5 carry `pending: true` with `candidates` only (Steel/Mithril/Adamant/Runegold, Vanquisher/Conqueror/Ascendant/Immortal). `tools/export_build.sh:83-86` PENDING list holds on `name_pending:true` — 8 item files + 8 legendary files = the 16 files BUILD_STATE names. `sim/content/ContentDB.gd` `tier_is_named()` skips a pending tier (BL-69, docs/15:2650).
**Doc:** docs/09 §11.4 (docs/09:609-632), docs/15 Q-41, BL-69. Canon is silent on the words; the register's recommended default is "designer names them" and the candidates are explicitly not to ship.
**Fix:** none for a build agent. The unit that lands the words is a data edit to `data/tier_words.json` (four `material`, four `cloth`, four `healer`, four `raid_title`, four `raid_adj`, and the leather-line decision — see CONTENT-04), then `tools/gen_items.gd` regenerates and `name_pending` clears itself. A pre-authored patch with the candidate words can be staged BEHIND the pending flag so the designer's act is one `pending: false` per tier.
**Owns:** `data/tier_words.json`, `tools/gen_items.gd` (regen only), `tests/unit/test_tier_scaling.gd`.
**Size:** S (once words are given). **Wave:** 6 — first, because every other tier 2-5 finding below is invisible in play until a tier mounts.
**Audit:** M5-T25-08 (blocked-needs-human — correct), M5-T25-05 (done — confirmed).

### CONTENT-02 — Raids 2-5 and Adventures 2-5 ARE authored; the audit rows saying "not-started" are stale
**Status:** REFUTED (audit M5-T25-09 / M5-T25-10 `actual_status: not-started`)
**Evidence:** `data/encounters_t{2..5}.json` hold 5 records each (20 raid records), `data/encounters_adventure_t{2..5}.json` hold 3 each (12 adventure records) — the 32 records BL-69's note counts. Each raid record carries mechanics (Tier 2: E1 m04; E2 m04+m02; E3 m01+m02+m11; E4 m03+m05+m07+m09; E5 m01+m02+m03+m11+m06 — one per star as `sim/model/Encounter.gd` demands), `mistakes_invited`, and an authored `comedy_line` (t2_raid_e1: "Two packs, one corridor, and a Mage who has learned exactly one lesson from Tier 1…"). Git: commit `3ae0eab` "the generator ran, and running it found two real defects" wrote them. `_notes` say "MECHANIC SELECTION AND COMEDY ARE AUTHORED, not generated" and "Names are canon placeholders; tier 2 has not been named (docs/10 §2)".
**Doc:** docs/10 §4/§6/§10, docs/08 §9.6.
**Fix:** flip M5-T25-09 and M5-T25-10 to `partial` with the honest remainder: (a) the files are written by `tools/gen_items.gd`, not the `tools/gen_encounters.gd` the rows name (that file does not exist); (b) the Adventure 2-5 acceptance test the row asks for (unhealed tank clock 5.5/4.3/3.5 ±0.2 at every tier) — see CONTENT-08; (c) the 32 comedy lines have never been through the human review gate (M5-COMEDY-12).
**Owns:** `build/plan/audit.json` (rows M5-T25-09/10).
**Size:** S. **Wave:** 6 (housekeeping in the same unit as CONTENT-01).
**Audit:** M5-T25-09, M5-T25-10.

### CONTENT-03 — The 68 hand-authored exceptions exist at the right numbers but none is authored
**Status:** CONFIRMED
**Evidence:** per tier 2-5, `items_t{n}_raid.json` holds 11 exception rows (7 `_FINAL` capstones, 4 `UNIV_TRINKET_*`) and `items_t{n}_adventure.json` 4 charms — 15 x 4 = 60; the Warrior Shield / Bard Instrument capstones are generated off-hand rows (Tier 1 shape `ITM_T1_RAID_SHIELD_OH`, `ITM_T1_RAID_INSTR_OH`, canon) — 68 with them. Measured `hand_authored: true` across all of `data/`: 0 (the 8 grep hits are the `_notes` sentence). docs/09 §13.5: "Hand-author, always: capstones (Boss 5), trinkets, and any item with a joke in it."
**Doc:** docs/09 §13.1 (85 = 45 + 20 + 20), §13.5.
**Fix:** after the words land, one writing unit claims the 68 rows: a name off §11.3's formula (`Final {BaseNoun}` / `{Class} {BaseNoun}` / `{RaidTitle}'s Charm of {Stat}`), a one-line `note` with the joke, `hand_authored: true`. `tests/unit/test_gen_items_merge.gd` already proves the merge survives regeneration. Stats stay as generated (derived, BL-70-floored). "A joke in it" is the designer's bar (M5-COMEDY-12) — the unit writes, the designer reads.
**Owns:** `data/items_t{2..5}_raid.json`, `data/items_t{2..5}_adventure.json` (the 68 rows only), `tests/unit/test_gen_items_merge.gd` (expectation 0 -> 68).
**Size:** M. **Wave:** 7 (after the words; before the review gate in wave 9).
**Audit:** M5-T25-07 (partial — confirmed accurate).

### CONTENT-04 — The leather-line word has no column, and the cloth/healer/raid_adj words are not even candidates
**Status:** BLOCKED-designer
**Evidence:** `data/tier_words.json` tier 1 carries five keys (`material`, `cloth`, `healer`, `raid_title`, `raid_adj`); tiers 2-5 candidates carry only `material` and `raid_title`. Accepting every candidate still leaves cloth (Spellweave->?), healer (Blessed->?) and raid_adj (Basic->?) unanswered, and the file's `_notes` record the leather wrinkle: canon T1 reads "Reinforced Leather Vest", not "Iron Leather Vest", so a T2 leather piece renders "<material> Leather Vest" unless a fifth column exists. docs/09:626-632 says the same.
**Doc:** docs/09 §11.4; docs/15 Q-41 — Q-41 lists only material and title. No row for cloth/healer/raid_adj or the leather column.
**Fix:** the designer question below lists the exact 20 words + 1 column decision. No recommended default can be given for lore words (docs/10 §2 forbids inventing them); the recommended default for the STRUCTURAL question is "leather shares the metal word from Tier 2 on" (no fifth column) because canon's T1 Monk/Rogue line already mixes `Ironbound`/`Reinforced`.
**Owns:** `data/tier_words.json`, docs/09 §11.4 (amend to five columns), docs/15 (Q-41 amended to list all five).
**Size:** S. **Wave:** 6 (the question must be asked in wave 6 for wave 7 to have anything to name).
**Audit:** M5-T25-08.

### CONTENT-05 — Q-35's three Adventure off-hands per rung are still in no data file
**Status:** CONFIRMED
**Evidence:** every `items_t{n}_adventure.json` has 28 rows and no `off_hand` slot (`items_t2_adventure.json`: 17 armour + 7 weapons + 4 charms). docs/09:733-735 says so itself ("The shipped data does not carry it yet … audit M5-T25-14"). docs/09 §10.2 proposes Iron Adventurer's Shield, Adventurer's Lute, Blessed Adventurer's Tome. In play: Warrior, Bard, Cleric, Druid, Shaman show an empty off-hand for the whole Adventure phase of every tier.
**Doc:** docs/15 Q-35 (recommended default: add both; adopted 2026-09-15, unsigned), docs/09 §10.2 / §13.1.
**Fix:** add the three T1 rows to `data/items_t1_adventure.json` at §10.2's stat blocks; add the off-hand template to `tools/gen_items.gd` so tiers 2-5 generate 31 Adventure rows; update the 28-row assertions in `tests/unit/test_tier_scaling.gd`; put the rows into A2's `loot_slots` in `data/encounters_adventure_t{1..5}.json` (docs/10 §8's legs row) with a one-line docs/10 §8 note.
**Owns:** `data/items_t1_adventure.json`, `tools/gen_items.gd`, `data/items_t{2..5}_adventure.json` (regen), `data/encounters_adventure_t*.json` (loot_slots only), `tests/unit/test_tier_scaling.gd`, docs/09 §13.1 note.
**Size:** M. **Wave:** 6 (it changes generated row counts; land before the words so the designer names the final set once).
**Audit:** M5-T25-14 (not-started — confirmed).

### CONTENT-06 — Tiers 2-5 have never been simulated: the sweep, the playtest and the goldens stop at Tier 1, and the tier is not threaded into the sim
**Status:** CONFIRMED
**Evidence:** `tools/balance_sweep.gd:43-45` — `SLOTS := ["A1","A2","A3","E1","E2","E3","E4","E5"]`, tier 1 only (288 cells x 8 seeds per BUILD_STATE). `tests/unit/test_tier_rules.gd` and `test_tier_budget.gd` check the DATA (ladder monotonicity, §9.6 reproduction) but never run `RaidSim` on a tier 2+ encounter; `tests/unit/test_raid_sim.gd:420` says "Tier 2-5 content will author its own" magnitudes. The sim is tier-blind: `sim/core/RaidSim.gd:1758` `Formulas.damage_after_ac(float(raw), int(p["ac"]))` passes no tier (default 1); `sim/content/TierScaling.gd:313/319/337/380` and `tools/gen_items.gd:865` call `Formulas.mitigation(tank_ac)` with no tier. `Formulas.gd:60` `AC_K_TIER_STEP := 1.5` and `:299` `MANA_TO_SPELL_TIER_DECAY := 0.85` exist as switches but nothing above tier 1 reaches them. So the 20 raid records were sized by a mitigation curve the sim will not use at their tier once they mount, and no clear-rate has ever been measured for them.
**Doc:** docs/08 §9.6 (the budget), docs/15 BL-72 ("implemented as switches, not yet threaded"), docs/14 §9.3 (the sweep's shape). No new row needed; BL-72 already records the intent.
**Fix:** one unit, both sides in one commit (the audit row is right that splitting sizes fights against a curve the sim does not use): thread `encounter.tier` into `RaidSim._apply_damage` and the spell path; thread the rung's tier into `TierScaling.boss_auto_raw / unhealed_clock / aoe_pulse_gross` and gen_items' budget rows; regenerate docs/08 §9.6 and the 8 tier files; assert Tier 1 unchanged in `test_tier_budget.gd`. THEN extend `balance_sweep.gd` with `--tier=N` (the gear stages per tier are `TierScaling`'s own rungs) and run one 8-seed pass per tier so wave 8 has a curve to look at. Expect the first pass to find a wall or an inversion — record it as a `docs/15` row, do not tune.
**Owns:** `sim/core/RaidSim.gd` (damage/spell call sites only), `sim/content/TierScaling.gd`, `tools/gen_items.gd`, `tools/balance_sweep.gd`, `tests/unit/test_tier_budget.gd`, `tests/unit/test_balance_sweep.gd`, docs/08 §9.6 (regen).
**Size:** L. **Wave:** 7 (needs CONTENT-01's words to be worth measuring in play, but the threading itself does not — start it in 6 if a SIM unit is free).
**Audit:** M5-T25-15 (not-started — confirmed), M6-BAL-01 (done for tier 1 — confirmed), M6-BAL-03.

### CONTENT-07 — The tutorial content is authored to spec; the two audit rows that still say "documentation half owed" are stale
**Status:** REFUTED (audit M5-TUT-06, M5-TUT-08 `partial`; M5-TUT-12 `partial`; M5-TUT-11 `not-started`)
**Evidence:** `data/encounters_tutorial_t1.json` — A0 (`t1_tut_a0`: party 4, tanks 1, 66 HP, 20x1, no mechanics, `force_mistake_round: 3`, `target_rounds` 6, enrage 9) and TR (`t1_tut_tr`: party 6, tanks 1, 198 HP, 15x2, m01 `stack_damage_pct 50 / swap_at 3`, target 12, enrage 17), each with a comedy_line; the file's 11 `_notes` derive every departure from docs/10 §9.1 (HP at stage 0, not §9.1's stage-A 350/1,055). `data/items_tutorial.json` holds the two docs/09 §10.2 G12 rows (Cracked Charm of Power +1, Cracked Charm of Health +2 HP). The board's skip lives on the tutorial's own paper (`game/screens/AdventureBoard.gd:685-707` `_skip_block`, "Skip the tutorial" button naming the forfeited trinket); `GameState.gd:850` `rung_resolved()`, `:862` `skip_tutorial()`, `:898-913` sets `onboarding_complete`. `sim/core/Mistakes.gd:42` `TUTORIAL_MISTAKE_MULT := 0.5`, `:47` `TUTORIAL_DISABLED_TYPES := ["MIS_FACEPULL","MIS_NINJAPULL"]` (M5-TUT-11's whole ask). `sim/core/RaidSim.gd:450` fires `force_mistake_round`; `tests/unit/test_tutorials.gd:163` asserts it on every seed (M5-TUT-12's "sim half"). docs/15 BL-79 (docs/15:3047) is the promoted register entry M5-TUT-06/08 said was owed; docs/13:195 S09 carries the addendum.
**Doc:** docs/10 §9, docs/01 §8, docs/15 BL-79, Q-51, Q-55.
**Fix:** flip M5-TUT-06, -08, -11, -12 to done. One residue: `game/core/GameState.gd:894` still says "Proposed docs/15 build-loop entry in build/plan/q-tutorials.md" — point it at BL-79 (one-line comment edit). M5-TUT-14's two test tightenings in `tests/unit/test_full_loop.gd` (exactly one pending_loot after A0; TR's skip warning scraped) remain owed and are S.
**Owns:** `build/plan/audit.json`, `game/core/GameState.gd:894` (comment), `tests/unit/test_full_loop.gd`.
**Size:** S. **Wave:** 6.
**Audit:** M5-TUT-06, M5-TUT-08, M5-TUT-11, M5-TUT-12, M5-TUT-14, M5-TUT-01 (partial -> done), M5-TUT-02 (partial -> done: Encounter.gd relaxes the star rule downward for the two tutorial slots per the file's `_notes`).

### CONTENT-08 — The Tutorial Raid clears 1 in 20 and A3 clears 0: both pinned, both waiting on one arithmetic ruling
**Status:** BLOCKED-designer
**Evidence:** `tests/unit/test_tutorials.gd:364` `TUTORIAL_RAID_CLEARS_AS_MEASURED := 1` with the measurement table at :341-346 (as authored 0/20; no m01 13/20; swing 15->10 10/20; after the 0.5 tutorial rate, 1/20). `tests/unit/test_adventures.gd:213` pins A3 at `rate == 0.0` (no mechanics 24/24, m01 only 0/24). Both trace to the same cause the test header states: docs/10 §9.1 / §8 price the boss swing against the autoattack alone and then add M01, whose stacks multiply damage taken by 2.5 at the swap threshold. BUILD_STATE "The two content defects that are deliberately PINNED, not tuned." M6-BAL-04 adds the third: morale pinned at 45 by docs/05 §8 makes A2 a stop for 6 of 8 guilds.
**Doc:** docs/10 §9.1 (TR: "a real fail state" — winnable AND losable), docs/10 §8 (A3), docs/08 §9.3 (`boss_auto_raw` formula has no mechanic term), docs/05 §8 (the 45 pin). Register: NO Q- row exists for the swing-vs-M01 pricing — M6-BAL-03 says "register Q- row" but none was written. Recommended default: price the swing WITH the mechanic — `boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK x (1 - mit) x M01_factor)` where `M01_factor` is the expected stack multiplier over the swap cadence (~1.5 for swap_at 3 at 50%), applied ONLY where m01 is authored. That keeps M01 (TR's teaching payload) and fixes A3 and TR with one formula change, no per-encounter judgement. For M6-BAL-04 the recommended default is the audit's cheapest lever (a facility-0 rest ceiling above 45, or Adventure gear counted toward the drift target) — whichever the designer picks is one docs/05 §8 number.
**Fix:** a designer session that writes three Q- rows (TR/A3 swing pricing; morale-45 pin; the tutorial rate 0.5 — `build/plan/q-W5-SIM.md`), then one SIM unit lands the formula in `sim/content/TierScaling.gd` + `tools/gen_items.gd`, regenerates A3/TR/E3/E5 swings, and flips the two pins to `>= 8` / `> 0.0`. Until then the campaign is not completable and no tutorial is "won" by a new player.
**Owns:** docs/15 (three new Q rows — designer), then `sim/content/TierScaling.gd`, `tools/gen_items.gd`, `data/encounters_tutorial_t1.json`, `data/encounters_adventure_t1.json`, `data/encounters_t1.json` (swings only), `tests/unit/test_tutorials.gd:364`, `tests/unit/test_adventures.gd:213`, `tests/golden/*`.
**Size:** M for the loop once ruled; the ruling itself is the blocker. **Wave:** 6 — the question must go to the designer in wave 6; nothing in waves 7-10 can produce "a completely shippable game" while the first raid a player fights cannot be won.
**Audit:** M6-BAL-03, M6-BAL-04, M5-TUT-10 (partial — the sim side is complete; the number is the residue).

### CONTENT-09 — Adventure 0 teaches five beats and the UI prompts none of them
**Status:** CONFIRMED
**Evidence:** docs/10 §9.1 "Teaches: Roster select -> confirm -> watch the sim -> read a mistake in the log -> equip a drop"; docs/01 §8.1 adds "Equip flow; the inventory" after A0 and "First town cycle: sell, buy a potion, repair one morale value, meet one recruit". In the tree the only tutorial-specific copy is the board's skip block (`AdventureBoard.gd:685-707`) and the "tutorial · skippable" facts line (`:528`); `grep -rn -i "callout|first_time|onboarding" game/screens/*.gd` finds no first-run hint on RaidPrep, RaidView, Results or the equip flow. A new player is handed A0 with the same prep board, risk readout and provisions strip as Raid 5. docs/13 has no tutorial-hint row (`grep -n -i tutorial docs/13-ui-ux.md` -> only S09's skip panel and one "not a tutorial" remark at :344).
**Doc:** docs/10 §9.1 / docs/01 §8.1 are 🔷 PROPOSED on the teaching order; canon says only "Just for learning". No docs/15 row on whether the tutorials carry guidance copy. Recommended default: yes, minimal — one dismissible callout per beat, keyed on `Reputation.is_tutorial_slot(slot)` and `onboarding_complete == false`, using the existing `Widgets.callout` and the `PanelCalloutPositive` style; text in `Label.text` so the screen-test contract can assert it; no new screen. Five strings: prep ("Chalk four names…"), depart, the round-3 scripted mistake ("There it is. Read the line."), Results loot ("Equip it; it is not good"), TR's wipe report ("This is the Wipe Report. You will see it often.").
**Fix:** a UI unit — `game/ui/TutorialHints.gd` (new, ~80 lines: which hint shows on which screen for which slot, dismissed set kept in `GameState` v17 or in-session only), mounted from RaidPrep / RaidView / Results; the copy proposed to the designer in `build/plan/q-tutorial-hints.md`; a screen test that a fresh guild on A0 sees each hint once and a guild past onboarding sees none.
**Owns:** `game/ui/TutorialHints.gd` (new), `game/screens/RaidPrep.gd`, `game/screens/RaidView.gd`, `game/screens/Results.gd` (mount points only), `tests/unit/test_screens.gd`, docs/13 §5 (one addendum row), docs/15 (one BL row recording the copy as the loop's).
**Size:** M. **Wave:** 8 (after CONTENT-08's ruling makes the TR winnable — a hint on a fight that cannot be won teaches the wrong lesson; and after the wave-6/7 UI debts so the callout style is final).
**Audit:** no row (new). Relates to M5-TUT-01, M6-PLAY-01.

### CONTENT-10 — docs/10 §9.1's HP column and docs/01 §8.2's trinket names contradict the shipped data and have not been amended
**Status:** CONFIRMED (doc drift, not data drift)
**Evidence:** docs/10:419-420 print 350 / 1,055 HP and "no tanks required"; the data ships 66 / 198 and `tanks_required: 1`, with the derivation in the file's `_notes` (stage-0 DPS 2.75/raider, BL-28's correction). docs/10 §9.2 names "Trinket of Mild Competence +1 Damage / Trinket of Faint Encouragement +1 AC"; docs/01 §8.2 repeats the first; the data ships docs/09 §10.2's "Cracked Charm of Power +1 Power / Cracked Charm of Health +2 HP", and docs/09:548 asks the two docs to cite its rows. Neither doc has been amended (docs/10 §9.1 still says "no tanks required" in the Party column).
**Doc:** docs/10 §9.1/§9.2, docs/01 §8.2 (both 🔷 PROPOSED, so amendable by the loop with a BL note); docs/09 §10.2 owns the stat blocks.
**Fix:** a DOCS unit rewrites docs/10 §9.1's table to the shipped numbers with a one-line "re-derived at stage 0, docs/15 BL-28" note, replaces §9.2's two rows with citations of docs/09 §10.2, and does the same at docs/01 §8.2; records the amendment as a BL row. Then the designer question is only the NAMES ("Cracked Charm of …" is the §11.3 template; docs/01's joke names are the alternative) — see Questions.
**Owns:** docs/10 §9, docs/01 §8.2, docs/15 (one BL row).
**Size:** S. **Wave:** 6.
**Audit:** M5-TUT-01, M5-TUT-04 (done — the data side), M5-TUT-13 (done).

### CONTENT-11 — The mistake-line corpus is written, budgeted, validated and rendered; six audit rows still say otherwise
**Status:** REFUTED (audit M5-COMEDY-03 / -04 / -08 / -13 `not-started`/`partial`; M5-COMEDY-05 `partial` is right only about its test)
**Evidence:** `data/mistake_lines.json` — 18 types, 192 variants (8 HOT types x 14 + 10 x 8: MIS_FIRE 14, MIS_AGGRO 14, MIS_TAUNT_LAPSE 14, MIS_HEAL_WRONG 14, MIS_AFK 14, MIS_MECHANIC_DROP 14, MIS_WRONG_TARGET 14, MIS_ARGUMENT 14; the other ten 8 each), plus 9 legendary blocks x 4 = 36 legendary variants (M5-COMEDY-04's ask). Every type's UNGATED subset is >= 6 (min measured: MIS_HEAL_CORPSE 6). `sim/content/MistakeLines.gd:37-39` holds the 6/14/8 budget, `:307 _check_budget`, `:328 _check_writing_rules` (2-sentence cap, 1-2 `{actor}` tokens, 148-char cap, banned mechanic words, no stray capital), `:447 _validate_coverage` (every `Mistakes.TYPES` key and every legendary def must have lines). `tests/unit/test_mistake_lines.gd` holds 11 tests including the repeat guard (`:132` no same variant twice running per type; `:153/:166` seed determinism; `:238` every type that fires in E1-E5 over 12 seeds draws a line). Rendering: `RaidView.gd:2010` prints the quoted joke under the MISTAKE header and `:2020 _bubble()` puts it over the figure; `Results.gd:1157` shows it in the post-mortem; sheet `build/shots/all/raid-advanced/_sheet_1.png` left tile, log column (x≈530-760, y≈420-500) shows "Nobody asked Tiny to go first, and nobody has ever needed to." under its header. docs/15 BL-80 (docs/15:3107) is the register entry M5-COMEDY-13 says is owed. All 42 encounters carry a `comedy_line` (measured: 0 missing).
**Doc:** docs/07 §10.3, docs/14 §5.3.5/§5.4 assertion 7, docs/13 §11.3, docs/15 BL-76, BL-80.
**Fix:** flip M5-COMEDY-03, -04, -08, -11, -13 to done; M5-COMEDY-05's remaining is one screen test in `tests/unit/test_log_player.gd` (a revealed mistake's Label equals `MistakeLines.fill(...)` of a corpus id) — S.
**Owns:** `build/plan/audit.json`, `tests/unit/test_log_player.gd`.
**Size:** S. **Wave:** 6.
**Audit:** M5-COMEDY-03, -04, -05, -08, -11, -13.

### CONTENT-12 — One of the 18 types can never fire: the sim has no break phase, so MIS_NINJAPULL's eight lines are dead by construction
**Status:** CONFIRMED
**Evidence:** `sim/core/Mistakes.gd:139-143` MIS_NINJAPULL `"requires": "break_phase"`; `Mistakes.gd:222` `var break_phase: bool = false`; `grep -rn "break_phase" sim/ game/` finds no assignment outside `Mistakes.gd` and `tests/unit/test_mistakes.gd:354/369` (the tests set it by hand). docs/07:130 Phase 6 and :227 row 14 define the type as "Break phase only … Next encounter starts immediately: consumables not applied, resources not restored". The game runs one encounter per attempt (BUILD_STATE "the encounter plays out line by line"; Q-52 checkpoint per encounter), so there is no break between encounters for the sim to roll in. Goldens: 0 occurrences; MIS_INTERRUPT_MISS / MIS_INTERRUPT_WRONG also 0 in goldens but DO have a live trigger (`RaidSim.gd:1868 ctx.interrupt_check`, E4 carries m05) — their absence is a golden-scenario gap (no E4 scenario in `tests/golden/Scenarios.gd:27-56`), not a dead type. The three other types M5-COMEDY-09 listed as never-firing now fire (MIS_FIRE 12, MIS_MECHANIC_DROP 10, MIS_AVOIDABLE_DEATH 1 in the goldens).
**Doc:** docs/07 §5 Phase 6 / §5.4 row 14. No docs/15 row on the break phase. Canon is silent (the raw notes describe "raid raid, adventure adventure" — no inter-encounter break). Recommended default: implement the break as a game-layer roll — when the player presses Depart on E(n+1) with E(n) cleared this town cycle, `GameState` rolls one ambient MIS_NINJAPULL check on the party (rate from `Mistakes`, x2 in low-morale bands) and, on a hit, starts the sim with `mstate.ninja_pulled = true`: provisions not applied and the first-round log line drawn from the type's own 8 variants. It costs one field, keeps the sim pure, and makes the eight lines readable.
**Fix:** (a) the break roll in `game/core/GameState.gd` (`start_attempt`) behind a `GameSettings` switch `BREAK_PHASE_ROLLS` default on; (b) `RaidSim.run()` honours `mstate.ninja_pulled` by skipping the provisions pass and emitting the mistake at round 1 through `_log_mistake`; (c) one golden scenario on E4 (`e4_interrupts`) so the interrupt pair and the ninja line are pinned; (d) if the designer prefers the type cut, delete its 8 lines and the TYPES row and record the cut — either way the corpus stops carrying a type nobody reads.
**Owns:** `game/core/GameState.gd` (start_attempt), `sim/core/RaidSim.gd` (run() entry only), `sim/core/Mistakes.gd` (no change unless cut), `tests/golden/Scenarios.gd` + one new golden, `tests/unit/test_mistakes.gd`.
**Size:** M. **Wave:** 7.
**Audit:** M5-COMEDY-09 (partial: 3 of the 6 named types now fire; the E4 golden is still owed).

### CONTENT-13 — docs/07 §5.5's log-collapse guard is still unimplemented
**Status:** CONFIRMED
**Evidence:** `sim/core/Mistakes.gd:30-32` implements three of the four guards (`PER_TYPE_COOLDOWN_ROUNDS`, `MAX_CRITICALS_PER_ROUND`, `MAX_CASCADE_DEPTH`); `grep -n "collapse|fold" game/core/LogPlayer.gd` returns nothing; docs/07:298-306 row 4 "Identical Minor events by different raiders in the same round collapse to one line with a count | doc 13 owns the widget". The worst golden (`e5_miserable_commons`, 64 mistakes in 16 rounds) is the case it exists for. Sheet `raid-advanced/_sheet_1.png` right tile shows the round-11 log at 25 mistakes with no folding.
**Doc:** docs/07 §5.5 (🔷 PROPOSED), docs/13 §11 (owns the widget; no row for it). No docs/15 row. Recommended default: collapse at DISPLAY time only (docs/07 §10 rule 2: the sim emits everything), Minor severity only, same round + same type, one joke drawn for the folded row.
**Fix:** `static func collapse(entries) -> Array` in `game/core/LogPlayer.gd` producing a synthetic entry with `count` and the actor names; `RaidView._append_line` renders "3 raiders — Went AFK" with one quoted line; `Results` post-mortem uses the same fold; behind `GameSettings.LOG_COLLAPSE` default on; tests in `test_log_player.gd` (two Minor same-type same-round entries fold; a Severe does not; a different round does not).
**Owns:** `game/core/LogPlayer.gd`, `game/screens/RaidView.gd` (`_append_line` only), `game/screens/Results.gd` (post-mortem list only), `game/core/GameSettings.gd`, `tests/unit/test_log_player.gd`.
**Size:** M. **Wave:** 8 (a readability polish; after the wave-7 sim work so the fold is tested against final event shapes).
**Audit:** M5-COMEDY-10 (not-started — confirmed).

### CONTENT-14 — docs/14 §5.4 assertion 7 is enforced by the corpus loader, not by ContentDB, and a broken corpus does not fail the boot
**Status:** CONFIRMED (M5-COMEDY-07 is half-stale: the assertion exists, its HOME and its failure mode do not match the doc)
**Evidence:** `MistakeLines.gd:307 _check_budget` + `:447 _validate_coverage` implement "every type >= 6" and the mirror "every row's type is a real TYPES key" — the assertion the row calls unimplemented. But `sim/content/ContentDB.gd` never loads or validates the corpus (`grep -n MistakeLines sim/content/ContentDB.gd` -> nothing), and `RaidSim.gd:46-49 _lines()` caches `MistakeLines.load_from()` without checking `is_valid()` — a corpus with a missing type loads with `_err` recorded and the sim runs, drawing nothing for that type (the joke is just empty). docs/14 §5.4 says a failed assertion is "a refusal to build a release"; only `tests/unit/test_mistake_lines.gd:68` (`test_the_corpus_loads_and_validates`) stands between a bad edit and a shipped build, and it does — verify.sh runs it — so this is a belt-and-braces gap, not a live defect.
**Doc:** docs/14 §5.4 assertion 7, §5.3.5.
**Fix:** `ContentDB.load_all()` loads the corpus once and folds `MistakeLines.error_report()` into its own `_err` channel so `is_valid()` covers it; `RaidSim._lines()` takes the pool from the db it is handed (it already receives `db`). One test in `test_content_db.gd`: a fixture corpus with 5 lines on one type fails the load and names the type.
**Owns:** `sim/content/ContentDB.gd`, `sim/core/RaidSim.gd:46-49`, `tests/unit/test_content_db.gd`.
**Size:** S. **Wave:** 7.
**Audit:** M5-COMEDY-07 (not-started -> partial).

### CONTENT-15 — The joke line is capped at 148 characters and the log column shows roughly 60 before the ellipsis
**Status:** CONFIRMED
**Evidence:** `MistakeLines.gd:82-83` `LOG_MEASURE_CHARS := 74`, `MAX_LINE_CHARS := 148`; `RaidView.gd:2011-2014` sets `clip_text = true`, `OVERRUN_TRIM_ELLIPSIS`, full text in `tooltip_text`. Sheet `raid-advanced/_sheet_1.png` left tile, log rows at y≈432 and y≈470: "Greg is now the most interesting person in the room and would …" and "Cindy assumed the tank would take it back, and the tank assum…" — both cut mid-clause at ~62 characters. The bubble over the figure carries the full line but fades. The joke is the payload (docs/07 §10 rule 1 "the joke is in the sentence"); a sentence whose punchline is in the tooltip is not read. Measured over the corpus with {actor}=Steve: mean 75 chars, 161 of 192 type lines exceed 62 chars, 101 exceed docs/13 §11.1's 74, max 109.
**Doc:** docs/13 §11.1 (74-char measure), docs/07 §10.3 rule 1. No docs/15 row. Recommended default: the joke row WRAPS to two lines in the log (docs/02 §2.1's "a row never wraps" is about event rows; the quote is a sub-row and is already indented), and the corpus cap stays at 148.
**Fix:** in `RaidView._append_line` give the joke Label `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` and `clip_text = false` with a 2-line max height; same in `Results.gd:1157`'s post-mortem row; re-shoot `raid-advanced`. If the UI area rejects wrapping, the alternative is a corpus pass tightening `MAX_LINE_CHARS` to 74 and rewriting the 101 lines over it — L and lossy; wrapping is the cheaper, better fix.
**Owns:** `game/screens/RaidView.gd` (joke row only), `game/screens/Results.gd` (post-mortem joke row), `tests/unit/test_log_player.gd`.
**Size:** S. **Wave:** 8 (with CONTENT-13, the same two call sites).
**Audit:** relates to M5-COMEDY-05; no row.

### CONTENT-16 — The corpus has never had its human read, and that gate is the only thing between "written" and "funny"
**Status:** BLOCKED-designer
**Evidence:** `data/mistake_lines.json` `_notes` last paragraph: "NOT CERTIFIED FUNNY … This corpus needs a human read before the backlog item is done." docs/16:477 R-3. docs/15 has no entry closing the gate (grep for "certified" / "comedy review" -> none; BL-80 records the budget, not the read). The 42 encounter `comedy_line`s and the 68 exception-item jokes (CONTENT-03, unwritten) go through the same gate. The name pool has the identical open gate (docs/15 BL-53).
**Doc:** docs/16 R-3, docs/07 §10.3 rules 2 and 5 (not machine-checkable), docs/04 §7 content-review standard, docs/15 BL-53.
**Fix:** not a loop task. What the loop CAN do (wave 9): produce the review instrument — `tools/corpus_review.py` that renders every line with `{actor}` filled by three pool names into one HTML/markdown page, grouped by type with the type's header and the line's severity gate, plus the 42 encounter lines and the tutorial/exception item notes, so the read is one sitting and the keep/rewrite/cut marks come back as a JSON the loop applies. Then the designer's read closes BL-53 and a new BL row together.
**Owns:** `tools/corpus_review.py` (new), `build/plan/ship/corpus-review.md` (the rendered page).
**Size:** S for the instrument; the read is the designer's. **Wave:** 9 (after every line that will ever exist — CONTENT-03's 68 and CONTENT-12's decision — is written, so the designer reads once).
**Audit:** M5-COMEDY-12 (blocked-needs-human — confirmed), BL-53.

### CONTENT-17 — The eight unnamed Legendaries are unreachable in play until tiers 2-5 mount, so the two name gaps are one gap
**Status:** CONFIRMED
**Evidence:** `data/legendaries/*.json` — 8 of 9 `display_name: null`, `name_pending: true`; `LegendaryPool.gd:149-155` renders "Legendary (Warrior) — name pending" as the display name. `data/reputation.json` ranks: `find_weights` Legendary column is 0 at Unknown/Known/Respected/Established and 15/1000 only at Renowned (1800 RP). Tier 1's whole first-clear RP is 240 (E1-E5 10+15+25+35+65, full-tier 50, A 25, tutorials 15; repeats halve every 5) — Renowned is arithmetically out of reach while `ContentDB.tier_is_named()` mounts only tier 1. So in the game that ships today, no player sees a name-pending Legendary, and the export gate's 16 files are one designer act (the tier words) plus one more (the eight names) that only matters after the first. Everything else on the nine files is authored: quirk name/reads_as, two backstory bullets, subscribed tags, gear grant, barks (`_notes` says so and `LegendaryPool._validate` checks it).
**Doc:** docs/03 §5.6 "DO NOT INVENT NAMES", docs/04 §11.1/§11.2, docs/15 Q-24 (find chance), BL-57.
**Fix:** none for the loop. The designer question lists the eight. If the designer wants to defer, the honest ship path is unchanged (tier 1 only) and nothing needs to move.
**Owns:** `data/legendaries/{warrior,monk,rogue,cleric,druid,mage,wizard,bard}.json` `display_name` only.
**Size:** S (data). **Wave:** 6 (ask), 7 (land).
**Audit:** BL-69 (docs/15), M5-T25-08.

### CONTENT-18 — The nine Legendary quirks are named, seamed and inert; the spec is a designer pass
**Status:** BLOCKED-designer
**Evidence:** `sim/core/Quirks.gd:58` `const SPECS := {}`; `:46` four hooks (`threat_multiplier`, `relief_bp_bonus`, `tank_priority`, `immune_to`) all identity while SPECS is empty; `GameState.gd:216-221 FLAG_DEFAULTS` `legendary_quirks` off. Each `data/legendaries/*.json` carries `quirk.{id,name,reads_as,status: "❓ OPEN … docs/15 BL-58"}`: Holds the Line / Reads the Room / Never Where the Boss Looks / One More Cast / Grows Into the Gap / The Totem Holds / Carries the Beat / Second Wind of Fire / Reads the Whole Fight. `grep -ci quirk docs/07-combat-simulation.md` = 0. The Tavern card and RaiderDetail would show `reads_as` as flavour (a promise the sim does not keep).
**Doc:** docs/04 §11.2 ("specced in doc 07, named here"), docs/15 BL-58 (OPEN), audit Q58-1/-3. Q58-2 (which doc owns the spec — docs/04 points at a filename that does not exist) is a one-line doc fix the loop can make.
**Fix:** the loop's part is done (Q58-4's seam). Recommended default for the designer: spec each quirk as ONE row of `Quirks.SPECS` using only the four existing hooks — e.g. warrior `tank_priority +1`, rogue `threat_multiplier 0.8`, cleric `relief_bp_bonus +500`, monk `immune_to MIS_MECHANIC_DROP`, wizard `immune_to MIS_AFK` — and accept that druid ("covers whichever role is short"), mage ("first spell after a wipe recovery"), bard ("through a phase change") and shaman ("buffs outlast the pull") name mechanics the sim does not have (Q58-3) and need either a reworded `reads_as` or a fifth hook. Five reword-able, four hook-able, is the cheapest spec that ships all nine.
**Owns:** designer -> docs/07 (new §, ~9 rows) -> `sim/core/Quirks.gd` SPECS + `GameState.FLAG_DEFAULTS` + `tests/unit/test_legendaries.gd` (the golden SHA will move once a quirk is live — expected).
**Size:** M once specced. **Wave:** 8 (after tiers mount — a quirk on a raider nobody can find is invisible; and after CONTENT-06 so the golden that moves is the final one).
**Audit:** Q58-1, Q58-2 (S, loop), Q58-3, Q58-4 (partial -> done for the seam).

### CONTENT-19 — Wishlists are a declared, flagged-off module; ship without them unless the designer says otherwise
**Status:** CONFIRMED (optional content; not a ship blocker)
**Evidence:** `sim/model/Raider.gd:111` `var wishlist: Array = []` (serialised at :319/:376); `sim/core/Morale.gd:205-248` four triggers (`benched_wishlist`, `loot_wishlist`, `passed_over_wishlist`, `wishlist_sold`) authored; `GameState.gd:221` `"wishlists": false`; `:1834-1861` BIG-dumb condition #3 `wishlist_insult_2` `live: false`. No generator, no insult counter, no UI. Canon: "This is all just concepts and can easily be revisited" (docs/04 §9 ❓ OPEN — "the game must be playable with the flag off", which it is).
**Doc:** docs/04 §9, docs/11 §6.3, docs/14 §5.3, docs/15 BL-59 (3 of 5 BIG-dumb conditions live). Recommended default: ship 1.0 with the flag off and the row recorded as post-1.0; if the designer wants it, the build is docs/04 §9's table verbatim (M: generator in `Recruitment.gd`, insult counter in `GameState`, one line on the raider card, the four triggers already exist).
**Fix:** (a) default path: a one-line note in docs/15 BL-59 and BUILD_STATE that wishlists are out of 1.0 by the designer's word; (b) if in: `sim/core/Recruitment.gd` (roll on generate), `GameState.record_attempt` (insult counter on loot assignment), `game/ui/Cards.gd` (one row), `tests/unit/test_game_state.gd`.
**Owns:** as above. **Size:** S (default) / M (build). **Wave:** 9 if built (polish tier; nothing depends on it).
**Audit:** Q59-3 (not-started — accurate), BL-59.

### CONTENT-20 — Two name pools: the starting roster draws 24 code-literal names that never went through BL-53's construction
**Status:** CONFIRMED
**Evidence:** `game/core/StartingRoster.gd:46-50` `NAME_POOL` = 24 literals (Dave, Cindy, Fern, Kel, Wanda, Zed, Pip, Lyra, Marge, Otto, Rhona, Clive, Bess, Nev, Dot, Hal, Peg, Cyril, Enid, Gus, Maud, Stan, Vera, Wilf) used at `:61-86` for nine of the twelve day-one raiders; `data/names.json` `given` = 36 names (Bob … Glenda) used by the Tavern through `NamePool` (`GameState.gd:2315`). Overlap: Dave, Clive. docs/04 §7 "Pool is data, not code"; BL-53's argument that the pool is safe rests on "every given name in the file appears in §7.1's own forty-sample table" — 22 of the 24 starting names do not. The sheets show the effect (`raid-advanced/_sheet_1.png`: Pip, Cindy, Hal, Nev, Clive, Rhona on the party strip; none of them can ever be hired at the Tavern), and the register the player reads is two registers.
**Doc:** docs/04 §7, docs/15 BL-53 (OPEN), BL-23 (the twelve).
**Fix:** `StartingRoster.build()` draws through `NamePool.pick(rng, taken)` after placing Bob/Greg/Steve; delete `NAME_POOL`; the seeded reproducibility BL-23 promises is preserved because `NamePool.pick` takes the rng. Update `tests/unit/test_starting_roster.gd` (names come from `data/names.json`), regenerate any fixture that pins "Pip" (`tests/golden/Scenarios.gd:23` has its own `NAMES` and is unaffected; `tools/probe/Kit.gd` uses reference names by design). Then BL-53's review is one list of 36 + 20 epithets, not two.
**Owns:** `game/core/StartingRoster.gd`, `tests/unit/test_starting_roster.gd`.
**Size:** S. **Wave:** 6 (so every sheet and every playtest after it shows the shipped register).
**Audit:** BL-53; no row (new).

### CONTENT-21 — The name pool's content review is a person's sign-off and is still open
**Status:** BLOCKED-designer
**Evidence:** docs/15:1523 BL-53 "OPEN - needs sign-off"; `data/names.json` `_notes` restate the gate. 36 given names, 20 epithets (8 suffix, 7 phrase, 5 prefix), 6 mangle rules; shape weights 620/260/120 per mille (docs/04 §7's 62/26/12). Tests cover the mechanical rules (no spaces, >= 2 chars, collision -> mangle -> numeric suffix at `NamePool.gd:84-109`).
**Doc:** docs/04 §7 content review gate; docs/15 BL-53.
**Fix:** none for the loop beyond CONTENT-20 (one pool to review). Fold into CONTENT-16's review page: render the 36 names, the 20 epithets and 40 sample shape-B/C outputs at three seeds so the reviewer sees combinations, not lists.
**Owns:** `tools/corpus_review.py` (shared with CONTENT-16). **Size:** S. **Wave:** 9.
**Audit:** BL-53.

### CONTENT-22 — Backstories: 18 tags x 4 variants, all listenable, and the four exclusion pairs are enforced
**Status:** CONFIRMED (complete for 1.0)
**Evidence:** `data/backstories.json` — 18 tags (docs/04 §8.3's list, `class_rival` parameterised), 4 variants each (§8.1 asks 3-6), `polarity` on every tag, 4 exclusion pairs, `_notes` "Every tag must be listenable, or it does not ship" with a `listens` column per tag. `sim/content/BackstoryPool.gd` loads it; `tests/unit/test_names_and_backstories.gd:171` checks variant counts. Legendaries carry two hand-authored bullets each and `subscribed_tags` (docs/04 §11.3).
**Doc:** docs/04 §8. Nothing open.
**Fix:** none. The bullets share CONTENT-16's human read (rule 5: never about a real person).
**Owns:** —. **Size:** —. **Wave:** 9 (review only).
**Audit:** none.

### CONTENT-23 — The economy's tier slope is two numbers that disagree, and tiers 2-5 have never been costed in play
**Status:** CONFIRMED
**Evidence:** `sim/core/Economy.gd:29` `STEP_RATIO := 1.9` per gear STEP (two steps per tier -> x3.61 per tier on every sale price: tier 5 raid gear carries coefficient 1.9^9 = 322), while docs/11 §4.3 scales every sink at `tier_scalar = 2.4` per tier (`Consumables.gd:78/116` implements 2.4) and its income table assumes gross income x2.4 per tier (520 -> 1,250 -> 3,000 -> 7,200 -> 17,300). With two thirds of ~30 drops sold per tier, sale income grows x3.61 against sinks at x2.4 — by tier 3 the catalogue is affordable and by tier 5 it is trivial (§4.4's own "gold-rich" failure). `tools/playtest.gd` walks tier 1 only (its `peak_gold`/`final_gold` columns exist). docs/11 §14 Q10 asks exactly this ("Is tier_scalar = 2.4 the right slope") and defaults to "tuned against the §4.4 telemetry target of a 0-20% carried balance at each tier boundary" — telemetry that cannot exist until a tier 2 runs.
**Doc:** docs/11 §4.3/§4.4/§5, §14 Q10. No docs/15 row (Q10 lives in docs/11 only). Recommended default: keep 1.9/step for VALUE (it prices items relative to each other, which is what the Market's compare tooltip needs) and make the SELL side tier-aware — `sell_rate(rank)` x `(2.4/3.61)^(tier-1)` — so realised gold tracks the 2.4 curve; one constant, one test.
**Fix:** wave 8 after CONTENT-06's tier sweep exists: extend `tools/playtest.gd` to walk a mounted tier N with a tier-N-geared roster and print the carried balance at the boundary; if it exceeds 35% (docs/11 §4.4), land the sell-side correction behind a `GameSettings` switch and record it as a BL row.
**Owns:** `sim/core/Economy.gd` (one function), `tools/playtest.gd` (`--tier`), `tests/unit/test_economy.gd`, docs/11 §5 (one paragraph), docs/15 (one BL row).
**Size:** M. **Wave:** 8.
**Audit:** no row; relates to M6-BAL-02/-03, BL-21 ("re-measure when Tier 2 ships").

### CONTENT-24 — M5-QAB-3 (the Records tab) is built; the row and one data `_doc` are stale
**Status:** REFUTED (audit M5-QAB-3 `not-started`)
**Evidence:** `game/screens/Guildhall.gd:51` tab `{"id": "records", "label": "Records"}`, `:388-390` `_records(_content_host)` / `_records_sidebar(_side_col)`; BUILD_STATE "the record wall is live". `data/achievements.json` holds 40 entries (12 progress / 10 mastery / 8 roster / 6 comedy / 4 economy = docs/11 §11.1's 12/10/8/6/4). One stale note: `com_big_dumb._doc` says "The emit is NOT wired … Achievements.evaluate() has no caller" while `GameState.gd:1703` calls `check_achievements({"name": "legendary_departed"})`. 15 of the 40 entries reference tiers 2-5 (`prog_raid_2..5`, `mast_no_one_died_t2..t5`, `mast_all_five_t2`, `mast_immaculate`, `rost_roof`) and are unreachable until the tiers mount — Locked rows that print their condition, which docs/13 §7 allows.
**Doc:** docs/13 §5 S14, docs/11 §11, docs/02 §4.4.
**Fix:** flip M5-QAB-3 to done; rewrite `com_big_dumb._doc` (one sentence). Check the sheet `tabs` shows the Records tab with a Locked tier-2 row printing its condition (the UI reporter's area; noted here because the rows are content).
**Owns:** `build/plan/audit.json`, `data/achievements.json` (`_doc` only).
**Size:** S. **Wave:** 6.
**Audit:** M5-QAB-3.

### CONTENT-25 — Tier 1's item data carries three register defaults that were never applied, and the generator copies them into four more tiers
**Status:** CONFIRMED
**Evidence:** (a) Q-42 — `data/items_t1_adventure.json` trinkets read "Adventure's Charm of Health/Armor/Mana/Power": canon's dropped apostrophe was fixed but the recommended normalisation to `Adventurer's` was not, and `tools/gen_items.gd` propagates it: `items_t2_adventure.json` "TIER2 Adventure's Charm of Health" beside "TIER2 Adventurer's Helm" — two possessives in one tier, forever. (b) Q-40 — `items_t1_raid.json` still carries `ITM_T1_RAID_MONKROGUE_CHEST_MONK` "Raider's Vest" AND `ITM_T1_RAID_MONKROGUE_CHEST_ROGUE` "Raider's Leather Vest" (byte-identical stats); the recommended default is one shared item; the generator writes both at every tier. (c) Q-28 / Q-35's second half — `items_starting.json` `starting_sets` are four armour ids, no weapon; `grep -rn "Chipped|Splintered|Bent Censer" game/ sim/ data/` -> nothing, so the Market sells no starter weapon and Commons swing `UNARMED_DAMAGE` (BL-27's floor) until A1 drops a sword — the recommended default ("cheap per-class starter weapon in the Market") is unbuilt.
**Doc:** docs/15 Q-42, Q-40, Q-28, Q-35; docs/09 §10.2 (starting weapons block, 🔷 unsigned). None has a BL row applying or declining the default.
**Fix:** one ITEMS unit: (a) rename the four T1 charms to `Adventurer's Charm of …` and fix the generator's trinket template (`{FamilyFiction}'s` = Adventurer's / Raider's), record as BL ("deliberate correction, not silent" — Q-42's own words); (b) EITHER merge the Vest into one `MONKROGUE_CHEST` row (and drop one from `class_tables`) OR record "two items, canon's names" as the ruling — the recommended default is merge; (c) add docs/09 §10.2's four starter weapons to `items_starting.json` with `source: "start"` and put them on the Market's tier-1 shelf (`sim/core/Buildings.gd` stock ladder) at ~40% of the Adventure weapon's value — behind the Q-35 switch that already exists for the off-hands. Tests: `test_items.gd` name-template check across all tiers; `test_market.gd` one starter per family on the Unknown shelf.
**Owns:** `data/items_t1_adventure.json` (4 names), `data/items_t1_raid.json` (Vest rows), `data/items_starting.json`, `tools/gen_items.gd`, `data/items_t{2..5}_*.json` (regen), `sim/core/Buildings.gd` or the Market stock table, `tests/unit/test_items.gd`, `tests/unit/test_market.gd`, docs/15 (BL rows).
**Size:** M. **Wave:** 6 (with CONTENT-05, before the words land — the designer names the final template once).
**Audit:** M5-T25-14, M5-T25-13 (Q-43 Mana variants on Warrior/Bard from T2 — same generator unit, S: one Mana-carrying twin per WARBARD slot per tier, the Bard's only Mana source before Boss 5).

### CONTENT-26 — Encounter records carry no visual identity, so five tiers share one arena, one boss set and one palette
**Status:** CONFIRMED (content contract; the art is the ART reporter's)
**Evidence:** docs/10 §6's 16-field template has no `scene`/`arena`/`boss_art`/`palette` field and none of the 42 records carries one; `SceneStage.gd:140` `DEFAULT_ARENA := "stage_arena_cave"` is the arena for every encounter (`RaidPrep.gd:206`, `RaidView.gd:453`, `Results.gd:70`); `stage_arena_dungeon` exists in `game/assets/bg/` and no encounter can ask for it; `game/assets/enemies/enemies.json` keys boss art by RANK (trash/elite/mini/main, with `_2` variants) not by tier; item icons `game/assets/ui/icons/item_*` are one palette. docs/10 §12.3's proposed constraint is "one palette, one boss silhouette, one environment identity per tier" and §12.2 "18 shapes x 5 palettes".
**Doc:** docs/10 §6, §12.2, §12.3; docs/12 §6.3. No docs/15 row on where tier identity is keyed. Recommended default: key it on the TIER, not the encounter — `data/tier_words.json` already is the per-tier record; add `scene`, `boss_set` and `icon_palette` keys per tier there (tier 1: `stage_arena_cave`, `boss_main`, `iron`), so an encounter needs no new field and a tier's identity is one row a designer can read.
**Fix:** CONTENT side (this report): the three keys in `tier_words.json` + `ContentDB.tier_scene(tier)` accessor + a test that every mounted tier's scene/boss_set exists on disk. ART side (handed off): the plates, the boss recolours, the icon palettes — sized there.
**Owns:** `data/tier_words.json`, `sim/content/ContentDB.gd` (one accessor), `game/ui/SceneStage.gd` (read the tier's scene instead of DEFAULT_ARENA — 3 call sites), `tests/unit/test_content_db.gd`.
**Size:** S (content), L+ (art). **Wave:** 7 (contract), 8-9 (art).
**Audit:** none; relates to the art plan's per-tier rows.

### CONTENT-27 — M10 Mana Burn ships as a silence only; the drain half waits on a Focus pool that does not exist
**Status:** CONFIRMED
**Evidence:** `sim/core/RaidSim.gd:124` `MANA_BURN_DRAIN_ENABLED := false` with the reason: "docs/15 Q-02's Focus pool … no pool exists: no field, no class-fixed values, no spend"; `:998-1003` notes the gap in the log (`mechanic_partial`) when the const is on. Tier 3 introduces M10 (`encounters_t3.json` `_notes`: "Tier 3 M10 and M12"), so from tier 3 the mechanic teaches half of itself. All eleven other mechanics have full arms (`RaidSim.gd:819-849`) — M5-T25-12's "seven missing" is down to this half.
**Doc:** docs/10 §10 M10 row; docs/15 Q-02 (Mana model: MAGNITUDE_PLUS_FOCUS, Focus "never appears on an item"), docs/08 §5.3. Recommended default: keep the silence-only reading for 1.0 and reword M10's row to "Silence" (docs/10 §10 is 🔷 PROPOSED, so a loop may amend it with a BL note); a Focus pool is a docs/08 subsystem, not a mechanic arm.
**Fix:** DOCS unit: amend docs/10 §10 M10's row and the tier-3 `_notes`; flip M5-T25-12 to done with the residue recorded as a post-1.0 row. If the designer wants the drain, it is M: `Combatant.focus` + class-fixed values in `data/classes.json` + spend in the cast path + the drain arm.
**Owns:** docs/10 §10, docs/15 (one BL row), `build/plan/audit.json`.
**Size:** S (default). **Wave:** 7.
**Audit:** M5-T25-12 (partial -> done with note).

### CONTENT-28 — The tier tables' `_notes` and docs/10 §2 both say "names are canon placeholders", but "Raid 2 — Encounter 1" / "Main Boss" / "Trash" is the text a player will read for four tiers
**Status:** BLOCKED-designer (a scope question, not a defect)
**Evidence:** all 42 `display_name`s are the canon ladder words ("Raid 2 — Encounter 1", "Adventure 3"); enemy `name`s are the rank words ("Trash", "Elite", "Mini Boss", "Main Boss", "Late Add", "Add"). docs/10 §2 (✅ binding): "ship the canon placeholder, do not invent lore names" — so this is correct by the project's rule, and the register never asks the designer whether raids, bosses or arenas get names. The RaidView boss plate (sheet `raid-advanced/_sheet_1.png`, top-centre plate reads "Raid 1 — Encounter 5") is where a player sees it.
**Doc:** docs/10 §2. No docs/15 row. Recommended default: ship as-is (the rule is canon's), and ask ONCE — with the eight Legendary names and the twenty tier words — whether the designer wants boss names too; if yes, it is a 25-boss + 20-trash list on the same review page as the tier words, S to land (one `display_name` per enemy row).
**Fix:** none unless answered; the question is in the list below.
**Owns:** `data/encounters_t*.json` (`enemies[].name`, `display_name`) if answered.
**Size:** S. **Wave:** 7 if answered with the words.
**Audit:** none.

### CONTENT-29 — 22 of the 72 backstory bullets say "he/his" and the name pool is a third feminine, so Pauline "checks the healing numbers before checking his own"
**Status:** CONFIRMED
**Evidence:** sheet `build/shots/all/tabs/_sheet_1.png`, Tavern_Manage tile, candidate card 2 (x≈950-1050, y≈390-500): "Pauline_4 — Wizard — Common … Checks the healing numbers before checking his own." `data/backstories.json`: 22 of 72 bullets carry he/his/him (e.g. `hates_being_benched` "Says he understands. He does not understand.", `glory_hound` "Wants his name said out loud after fights."); `data/names.json` `given` has 11 conventionally feminine names of 36 (Deb, Brenda, Sharon, Janice, Linda, Maureen, Sandra, Pauline, Yvonne, Beryl, Glenda); `sim/model/Raider.gd` has no pronoun/gender field (`grep -n pronoun|gender` -> none). The mistake corpus (192 + 36 lines) is pronoun-free by construction (0 hits) — the backstory file did not follow the same rule. Four of the eight unnamed Legendaries already carry a pronoun in their `reads_as`/bullets (monk she, rogue he, warrior he, wizard he) before they have a name.
**Doc:** docs/04 §8.1 (bullet format — "third person, about the raider"); docs/04 §7 review standard. No docs/15 row. Recommended default: rewrite the 22 bullets pronoun-free (the corpus's own house style: "Says they understand" is also fine, but the cleanest is the name-free imperative the other 50 bullets use); no pronoun field on the raider for 1.0.
**Fix:** a WRITING unit: 22 bullet rewrites in `data/backstories.json`; a `_check_pronouns` guard in `sim/content/BackstoryPool.gd` mirroring `MistakeLines._check_writing_rules`; one test. For the Legendaries: leave the four pronouns (a named character has a gender) but list them in the designer's naming question so the name fits.
**Owns:** `data/backstories.json`, `sim/content/BackstoryPool.gd`, `tests/unit/test_names_and_backstories.gd`.
**Size:** S. **Wave:** 6 (it is on the Tavern card in every sheet from here on).
**Audit:** none (new).

### CONTENT-30 — A0's fixture shows five mistakes in nine rounds for four raiders at the "reduced" tutorial rate
**Status:** CONFIRMED (a measurement for the designer, not a defect ruling)
**Evidence:** sheet `build/shots/all/raid-clear/_sheet_1.png`, Results_clear tile: "A0 — Adventure 0 · Rounds 9 · Mistakes 5 · Survivors 4 of 4", post-mortem "[R02] Rhona MISTAKE · Severe · Healed the Wrong Target", "[R07] Gruk MISTAKE · Moderate", "[R07] Rhona MISTAKE · Severe", "[R09] Gruk MISTAKE · Minor" — at `Mistakes.gd:42 TUTORIAL_MISTAKE_MULT 0.5`. docs/10 §9.1's design is ONE scripted mistake on round 3 "regardless of morale rolls" so "the player must see that in the first 30 seconds"; Q-51's reason for the reduced rate is that "a tutorial that rolls mistakes at full rate teaches the player the game is unfair before it teaches them what the game is". Five in nine rounds on a one-mob fight (and the fight still clears, 18+/20 pinned at `test_tutorials.gd:313`) is one fixture at one seed — but it is the seed the sheets show, and `build/plan/q-W5-SIM.md` already flags the 0.5 as the loop's number.
**Doc:** docs/10 §9.1, docs/15 Q-51 (DECIDED "reduced rate"; the magnitude was never ruled). Recommended default: A0 at 0 organic mistakes + the scripted one (the doc's own "exactly one encounter in the game" language), TR at 0.5 — expressed as a per-slot multiplier in `Mistakes.gd` (`{"A0": 0.0, "TR": 0.5}`) rather than one constant.
**Fix:** one constant becomes a two-entry table; re-measure A0's 20-seed clear (must stay >= 18) and TR's pinned count; record with CONTENT-08's ruling since the designer may want the rate and the swing together.
**Owns:** `sim/core/Mistakes.gd:42`, `tests/unit/test_mistakes.gd`, `tests/unit/test_tutorials.gd`, docs/15 (with CONTENT-08's row).
**Size:** S. **Wave:** 6 (ask), 7 (land).
**Audit:** M5-TUT-11, M6-BAL-03.

## Shippable bar

A reviewer ticks these for CONTENT before a release export is allowed past `tools/export_build.sh` gate 1/8:

**Items**
- [ ] `data/tier_words.json` tiers 2-5 `pending: false` with all five columns (material, cloth, healer, raid_title, raid_adj) and the leather-column decision recorded (CONTENT-01/-04)
- [ ] `grep -rlE '"name_pending"\s*:\s*true' data/` returns nothing; `gen_items.gd -- check` green (verify.sh stage 3)
- [ ] every Adventure rung has 31 rows (3 off-hands) and every tier's trinket/possessive template is one pattern (CONTENT-05/-25)
- [ ] the 68 exception rows carry `hand_authored: true`, a name off §11.3, and a note with the joke; `test_gen_items_merge.gd` expects 68 (CONTENT-03)
- [ ] Q-40 (one Vest or two) and Q-28 (starter weapons on the Unknown shelf) each have a BL row, applied or declined (CONTENT-25)
- [ ] `test_tier_scaling.gd`'s five invariants green at every rung after the final regen

**Encounters**
- [ ] 42 records load; every one carries a `comedy_line`; tier rules (`test_tier_rules.gd`) green
- [ ] the tier is threaded into RaidSim's damage/spell paths and TierScaling's budget (CONTENT-06); docs/08 §9.6 regenerated; Tier 1 numbers unchanged
- [ ] `balance_sweep.gd --tier=N` has run for N = 2..5 and each tier's curve is recorded in `docs/_log` with no unruled wall (CONTENT-06)
- [ ] the Tutorial Raid clears >= 8/20 and A3 clears > 0 at their authored gear stage, and the two pins are flipped with a docs/15 row naming the formula that moved (CONTENT-08)
- [ ] `tools/playtest.gd` reaches Raid 5's first clear (S17 fires) on at least 6 of 8 seeded guilds (M6-BAL-04 ruled)
- [ ] M10's row in docs/10 §10 matches what ships (CONTENT-27)
- [ ] each mounted tier names a scene / boss set / palette in `tier_words.json` and the assets exist (CONTENT-26)

**Tutorials**
- [ ] A0 and TR load at slots "A0"/"TR", pay their RP and gold, grant their trinket once, are skippable per tutorial with the forfeit named (`test_tutorials.gd` green)
- [ ] docs/10 §9.1/§9.2 and docs/01 §8.2 cite the shipped numbers and docs/09 §10.2's trinket rows (CONTENT-10)
- [ ] the five teaching beats have a first-run prompt each and a guild past onboarding sees none (CONTENT-09)
- [ ] the tutorial mistake rate is ruled per slot (CONTENT-30)

**Comedy corpus**
- [ ] 18 types, every ungated subset >= 6, hot eight >= 14, 9 legendary blocks >= 4; `MistakeLines.load_from().is_valid()` and the load folds into `ContentDB.is_valid()` (CONTENT-14)
- [ ] `test_mistake_lines.gd` repeat guard green; a golden on E4 pins the interrupt pair; MIS_NINJAPULL either fires from a break roll or is cut (CONTENT-12)
- [ ] the joke row wraps (or the corpus fits 74 chars) so no punchline lives only in a tooltip (CONTENT-15)
- [ ] Minor same-type same-round mistakes fold to one row (CONTENT-13)
- [ ] a named person has read all 192 + 36 + 42 + 68 lines and the review is a docs/15 row (CONTENT-16)

**Names, backstories, legendaries**
- [ ] one name pool: `StartingRoster` draws through `NamePool` (CONTENT-20); BL-53 signed (CONTENT-21)
- [ ] 0 gendered pronouns in `data/backstories.json`; `BackstoryPool` guards it (CONTENT-29)
- [ ] 9 of 9 Legendaries named (CONTENT-17) and their quirks either specced in `Quirks.SPECS` or reworded to what the hooks can do (CONTENT-18)
- [ ] wishlists: flag off and recorded as post-1.0, or built to docs/04 §9 (CONTENT-19)

**Economy**
- [ ] a tier-N playtest prints the carried balance at each boundary inside docs/11 §4.4's 0-20% band, or the sell-side slope is corrected with a BL row (CONTENT-23)

## Questions for the designer

These are the only content decisions a build agent may not make. Everything else in this report has a recommended default the loop can apply behind a switch.

1. **The twenty tier words** (docs/09 §11.4, Q-41). Per tier 2/3/4/5, one word each for: `material` (T1 Iron), `cloth` (T1 Spellweave), `healer` (T1 Blessed), `raid_title` (T1 Raider), `raid_adj` (T1 Basic — "Basic Raid Sword"/"Strong Raid Sword"). Candidates on file for material (Steel / Mithril / Adamant / Runegold) and raid_title (Vanquisher / Conqueror / Ascendant / Immortal); none for the other three. Plus: does the Monk/Rogue leather line keep its own word (T1 "Reinforced") — a fifth column — or share `material` from Tier 2 on? Until these land, tiers 2-5 do not mount and the game ends at Raid 1.
2. **The eight Legendary names** (docs/03 §5.6). Warrior (file already says "he"), Monk ("she"), Rogue ("he"), Cleric, Druid, Mage, Wizard ("he"), Bard. Natsuna the Shaman is canon. The files carry each one's quirk name, two backstory bullets and barks; only `display_name` is null. They are unreachable in play until question 1 is answered, so this can wait for the same sitting.
3. **The swing-vs-M01 pricing** (CONTENT-08; audit M6-BAL-03/-04; no Q row yet). The Tutorial Raid clears 1/20 and A3 0/24 because docs/08 §9.3 prices the boss swing on the autoattack and then M01 multiplies it by 2.5. Options: (a) fold the mechanic into the swing formula (recommended — one formula, no per-fight judgement); (b) drop M01 from TR (it stops teaching the swap); (c) lower TR's swing 15 -> 10 and A3's by hand. And the morale-45 pin: which of M6-BAL-04's four levers moves. Nothing in waves 7-10 makes the game "completely shippable" while the first raid cannot be won.
4. **The tutorial mistake rate** (CONTENT-30, `q-W5-SIM.md`): 0.5 for both, or A0 at "only the scripted one" and TR at 0.5?
5. **MIS_NINJAPULL** (CONTENT-12): build a break-phase roll at Depart so the type can fire, or cut the type and its eight lines?
6. **Quirk specs** (CONTENT-18, BL-58): accept the four-hook spec for warrior/rogue/cleric/monk/wizard and a reworded `reads_as` for druid/mage/bard/shaman, or write nine mechanics in docs/07?
7. **Wishlists** (CONTENT-19): out of 1.0 (recommended) or in?
8. **Names beyond the words**: do raids, bosses and arenas get names, or does "Raid 2 — Encounter 1" / "Main Boss" ship as docs/10 §2 says (recommended: ship as-is)? And the tutorial trinkets — docs/09's template names ("Cracked Charm of Power/Health") or docs/01's joke names ("Trinket of Mild Competence")?
9. **The human reads** (CONTENT-16/-21, BL-53): who reads the 192 + 36 mistake lines, the 42 encounter lines, the 68 item jokes once written, the 72 backstory bullets and the 36 + 20 names — and when? The loop will hand over one page.

## Coverage

**Read:** BUILD_STATE.md (Current focus, HANDOFF, pinned defects); `build/plan/audit.json` rows M5-T25-01..15, M5-TUT-01..15, M5-COMEDY-01..13, Q58-1..4, Q59-3, M5-QAB-3, M6-BAL-01..04; docs/09 §10-§13, docs/10 §2, §9, §10 (headers), §12; docs/07 §5.5, §6, §10.3 (via the corpus notes); docs/04 §7-§11; docs/11 §4-§6, §14; docs/01 §8; docs/15 §5.1-§5.3 tables, BL-23, BL-53, BL-69, BL-79, BL-80; `build/plan/q-W5-SIM.md` (head). Every file under `data/` (row counts, pending flags, names, notes) and `data/legendaries/*`; `sim/content/{ContentDB,MistakeLines,NamePool,LegendaryPool,TierScaling}.gd` (signatures + the cited lines); `sim/core/{Mistakes,RaidSim,Quirks,Economy,Formulas}.gd` (cited lines); `game/core/{StartingRoster,GameState}.gd`, `game/screens/{AdventureBoard,Guildhall,RaidView,Results,Tavern}.gd`, `game/ui/{Cards,SceneStage}.gd` (cited lines); `tools/export_build.sh` gate 1; `tools/balance_sweep.gd` slots; `tests/unit/{test_tutorials,test_adventures,test_mistake_lines,test_tier_rules,test_tier_budget,test_tier_scaling,test_raid_sim}.gd` (test lists + cited bodies); `tests/golden/Scenarios.gd` and the five goldens (type counts). Sheets: `raid-advanced/_sheet_1.png`, `raid-clear/_sheet_1.png`, `tabs/_sheet_1.png`.

**Measured:** 304 generated item rows (all `name_pending`), 0 `stats_pending`, 0 `hand_authored`; 42 encounters / 42 comedy lines; 192 + 36 corpus lines with per-type counts, ungated floor, and line lengths (mean 75, 161 > 62, 101 > 74); golden occurrences per mistake type (3 of 18 at zero: the interrupt pair and Ninja-Pull); 36 + 24 names in two pools; 72 backstory bullets, 22 gendered; 40 achievements (15 tier-2-5-gated); rank RP thresholds vs Tier 1's 240 RP.

**Not done:** no Godot run (mutex) — every clear-rate figure is quoted from a pinned test or a sheet, not re-measured; the balance sweep's Tier 1 CSV was not re-read; docs/10 §7's five worked Tier 1 encounters were not diffed against `encounters_t1.json` (BL-71 says doc 08 wins and `test_tier_budget.gd` pins it); docs/07 §10.3's five rules were not applied by eye to all 228 lines (that is the human gate, CONTENT-16); `tools/gen_items.gd`'s encounter-writing half was not read line by line (its output was); the `fixture`, `empty`, `focus`, `text150`, `emoji`, `reduced`, `wide-*` sheets were not opened (UI reporter's area); `docs/_log/progress.md` was not read; the Market's stock ladder for starter weapons (CONTENT-25c) was inferred from a negative grep, not from reading `Buildings.gd`.
