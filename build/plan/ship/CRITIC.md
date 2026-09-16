# CRITIC — adversarial review of the seven ship reports

_Written 2026-09-15 during wave 5, read-only on the tree at HEAD 106ac8d (the wave-5 close). Input to the waves 6-10 plan. Every claim here is the CRITIC's own grep or read; the reports' sheet evidence was accepted, their code evidence re-checked where a unit is sized on it._

## Executive summary

1. **Shippable today:** what the seven reports agree on — a deterministic Tier 1 loop that is walkable by buttons, saves, renders on the bare plates, and explains every disabled control. Not shippable: the first raid cannot be won (TR 1/20, A3 0/24), the campaign cannot be completed (M6-BAL-04), a dozen screens print sentences about the build, the report cuts the joke, eight of eleven sounds never play, tiers 2-5 are unnamed, and no .exe exists.
2. **The reports are sound where they measure and wrong where they schedule.** 27 CONFIRMED claims were spot-checked: 24 hold, one is overtaken (the 571px tooltip is fixed in the tree — UI-49), one is refuted (all six provision icons exist — LOOP-29), one is half-stale (UI-33). Ten audit rows the reports call "still stale" were closed by the wave-5 commit after they read. The wave columns, however, put 12-15 units into wave 6 and five L units into wave 7 against a measured capacity of seven afternoons per wave.
3. **Biggest gap 1 — the queue is half bookkeeping:** 38 of the 78 "open" audit rows are closable with evidence already in the reports (CRITIC-R3), six of the seven ids no report names are done in the tree (M3-TUNE-01/03/04, M4B-CONV-01/02), and the plan should be built on ~40 open + 17 blocked, not 95.
4. **Biggest gap 2 — one ruling, four defaults:** SIM-19, CONTENT-08, LOOP-24 and DESIGNER-01 each hand the designer a different "recommended default" for M6-BAL-04, and LOOP-24 adds a fifth canon number nobody else proposes. The page must carry one default (DESIGNER-01's lever (c), derived by CONTENT-08's formula) and one alternative (SIM-19's (a)), written after LOOP-19's recruit price lands so the gold it quotes is the shipped gold (CRITIC-C1, C7).
5. **Biggest gap 3 — three systems the docs promise that no report, audit row or docs/15 row names:** the `Forgiving Guild` assist toggle (docs/00 §6.4; docs/16's cut order forbids cutting it while Raid 5 and the achievement board ship), Retreat (docs/07 §3 "always available" — structurally impossible under the committed-attempt reading; strike it), and Traits (docs/04 §10 — a field and nothing else; cut it in writing). Plus S13/S16 unstruck, nine Legendary portraits that point at files that do not exist, and the store copy (CRITIC-M1..M7).
6. **Eighteen conflicts** (CRITIC-C1..C18): the same two log call sites owned by four units in three waves under two rules; three shapes for one tutorial band, one of which writes into the save format the SAVE unit is freezing; `Settings.ROWS` touched by seven findings across four waves; Focus built by SIM and shelved by CONTENT; the tier sweep scheduled before the sim it measures is final. Each has a resolution and an owner.
7. **The order:** wave 6 "Nothing lies" (sheets, copy, settings, log, cascade + drift gate, the designer's page, the ledger) → 7 "The fight reads" (prep, stage, report, sim effects, audio hooks, the v17 save, docs/08) → 8 "The numbers are ruled" (balance + Forgiving lever, crisis, keys, items, tutor, 150% part 1, facility) → 9 "Tiers and finish" (tiers or the honest Tier-1 ending, Bard, ambience, 150% part 2, art, polish, the human read) → 10 "Release" (export, README, delete, credits, the second-machine walk, buffer). 33 units; every L split or cut; no two-stage unit.
8. **The cut line** moves two things the reports put above it below it — Focus and the four PROPOSED class kits — and one thing below it above it — the Forgiving Guild toggle. Sixteen deferrals get a BL row in wave 6 so nothing ships half-built (BUILD_STATE invariant 5).
9. **The designer's part** is unchanged from the reports and is the schedule's only external dependency: the lever, the twenty words, the eight names, provenance, credits, the clear-rate curve, the review reads — by the end of wave 7, or waves 8-9 run on the recommended defaults and 1.0 is Tier 1 with the ending retimed.
10. **Counts:** 7 missing, 6 refuted/overtaken (R1-R6) plus the 24-row spot-check table, 18 conflicts, 33 units across five waves, 21 must-land lines, 6 polish lines, 16 deferrals, 5 new designer questions.

## Missing

### Audit walk (95 actionable ids vs the seven reports)

Every open or blocked id in `build/plan/audit.json` at HEAD (106ac8d) was grepped against SIM/CONTENT/LOOP/UI/AUDIO/SHIP/DESIGNER. 88 of 95 are named by at least one report. Seven are named by none:

| Orphan id | Status in audit | What the tree shows (checked 2026-09-15) | Verdict |
|---|---|---|---|
| M3-TUNE-01 | not-started | `docs/14:335` "RULED (build loop, BL-81) … the shipped file is `data/reputation.json`"; `grep reputation.tres docs/` = only the two history sentences | DONE — close, cite BL-81 |
| M3-TUNE-03 | not-started | `data/reputation.json` exists; `sim/core/Reputation.gd:31 DEFAULT_PATH := "res://data/reputation.json"`, `:94 reset_tables()`, `:643` "DERIVED from data/reputation.json" | DONE — close |
| M3-TUNE-04 | not-started | `sim/core/Recruitment.gd:38` "THE TABLE ITSELF LIVES IN data/reputation.json … this reads it"; `:370` "NOT A SECOND COPY" | DONE — close |
| M4B-CONV-01 | partial (XL) | `ls game/assets/bg/` = six `stage_*.png` only; `grep "_plate.png" game/screens game/ui` hits only Theme's 9-slice chrome (`callout_plate`, `cta_plate`) and two history comments | DONE — close (wave 2-5 converted all fourteen) |
| M4B-CONV-02 | partial (S) | `arena_stage.png` absent from `game/assets/bg/`; only comments at `RaidView.gd:436`, `Cards.gd:899` | DONE — close |
| M5-COMEDY-08 | not-started | CONTENT-11 covers it under the "-08" shorthand (repeat guard at `tests/unit/test_mistake_lines.gd:132`) | not an orphan; DONE — close |
| M5-OQ-1 | partial (S) | docs/15 still carries five OPEN/PARTIAL/DEFERRED BL headings (BL-58 :1443, BL-59 :1467, BL-53 :1523, BL-40 :2081, BL-42 :2121, BL-22 :2204) and one LEANING (:2247); DESIGNER-08/11/14/15/16/48 cover each individually, none names the sweep row | a docs unit's row; fold into the wave-6 DOCS unit (see Order) |

Net: six of the seven orphans are closable bookkeeping; the queue's true open count after the reporters' stale-row lists is well under 78 (see the Refuted section's tally).

Overtaken by the wave-5 close commit (106ac8d, written AFTER the reporters read): m5-m11-frontal-cleave, m5-m12-escalating-swing, m5-mechanic-dispatch-guard (SIM-01 lists them as still stale — now closed), M5-TUT-11/12/14 (SIM-28, CONTENT-07 — now closed), M5-COMEDY-05 (CONTENT-11 — now done), M6-A11Y-05 (SHIP-08 — now closed), Q59-4 (SIM-21 — now done), M6-PLAY-02 (LOOP-16/25, SHIP-13 cite it as open — now done), M3-SAVE-06, M3-TUNE-02. A wave-6 bookkeeping unit must re-diff the reporters' "close these rows" lists against HEAD before applying them.

### Docs walk (docs/00-16 tables of contents and docs/13 §5 S01-S18 vs the seven reports)

Screens: S01-S17 plus the Load/Save screen (SHIP-14 asks for an S18 row) are each named by at least one report. S13 (encounter interstitial) and S16 (Codex) are named only as questions (UI q4, SHIP-20, LOOP-22) — nobody sizes the docs strike; folded into CRITIC-M4 below. Systems named by no report (each checked in the tree):

### CRITIC-M1 — The `Forgiving Guild` assist toggle (docs/00 §6.4, docs/16 W3.12/R-12/C13) does not exist and no report, audit row or docs/15 row names it
**Status** CONFIRMED (missing from the tree AND from all seven reports).
**Evidence** `grep -rn -i "forgiving\|DIFFICULTY_MULT" sim/ game/ data/ docs/15-open-questions.md` = nothing; `game/screens/Settings.gd:78-115` ROWS has no difficulty key; docs/13 §15.1's option table has no row for it either. docs/00 §6.4: "one toggle — working name Forgiving Guild — off by default … scales raider mistake chance and boss HP via a single multiplier … a player inside either spiral has no way out that the game admits to". docs/16 W3.12 lists it as milestone-3 work; docs/16 §11 puts it at C13, the LAST cut, and states the rule "nothing lower is cut while something above it is still in" — C5 (achievement board) and C8 (Raid 5) ship, so by the roadmap's own rule the toggle cannot be cut without the designer overriding the cut order in writing.
**Doc** docs/00 §6.4 (🔷 PROPOSED, position taken), docs/08 §11 ("needs a DIFFICULTY_MULT lever … §11's current lever list has no global difficulty knob"), docs/14 §9.3 (sweep reports per setting). No docs/15 row; recommended default: build it — `Formulas.DIFFICULTY_MULT` (1.0 default, 0.75 under the toggle) applied at the `mistake_chance_bp` clamp and to boss `max_hp` in the enemy build; a `forgiving_guild` bool in `GameSettings.DEFAULTS`, one Settings row ("Forgiving Guild — fewer mistakes, softer bosses. Changes nothing else."), `balance_sweep.gd --forgiving` as a second axis. It is NOT a substitute for M6-BAL-04 (docs/00 says so) and must not be used to make the playtest green.
**Fix** as above. **Owns** `sim/core/Formulas.gd`, `sim/core/RaidSim.gd` (enemy build), `game/core/GameSettings.gd`, `game/screens/Settings.gd`, `tools/balance_sweep.gd`, `tests/unit/test_formulas.gd`, `tests/unit/test_settings.gd`, docs/13 §15.1 (one row), docs/15 (one BL row). **Size** M. **Wave** 8 (the balance wave — it is a sweep axis and lands with the re-baseline; the Settings row is S). **Audit** none — add `m6-forgiving-guild`.

### CRITIC-M2 — Retreat (docs/07 §3 "always available", docs/15 Q-09 "the sole exception") is neither built nor struck, and no report mentions it
**Status** CONFIRMED (a docs-vs-tree gap; the tree's reading is the right one).
**Evidence** `grep -rn -i retreat sim/core game/screens game/core` = two comments (`Reputation.gd:545`, `GameState.gd:1020`); no button, no outcome. docs/07 §3 :106 "Retreat is separate and always available: the player may abandon the attempt at any phase boundary"; docs/07 §7.3 :379 "Player Retreat → Abandoned attempt, not a wipe"; docs/15 Q-09 :270 "Retreat is the sole exception and is a whole-attempt action". But the attempt is resolved and recorded before RaidView plays a line (`RaidView.gd:386-388`, DESIGNER-06), so "abandon at a phase boundary" cannot exist without an incremental sim — which BUILD_STATE invariant 2 and Q-53's stronger reading rule out.
**Doc** docs/07 §3/§7.3, docs/15 Q-09. Recommended default: strike Retreat by a BL row ("the attempt is committed at Depart; leaving the account early is Skip, never Retreat"), amend docs/07 §3 :106 and the §7.3 outcome row, and docs/01 §6's cost table if it prices a retreat. No code.
**Owns** `docs/07-combat-simulation.md`, `docs/01-core-loop.md` §6, `docs/15` (BL row). **Size** S. **Wave** 6 (the DOCS unit). **Audit** none.

### CRITIC-M3 — Traits (docs/04 §10, six mechanical traits) have a field on the raider and nothing else; no report, audit row or docs/15 row
**Status** CONFIRMED (missing; PROPOSED; not on docs/16's cut list).
**Evidence** `sim/model/Raider.gd:112 var traits: Array = []` serialised at `:320`; `grep -rn "slow_learner\|cheap_date\|iron_stomach\|\.traits" sim/core game/` = nothing — no generation, no effect, no card row. docs/04 §10 table: `slow_learner`, `clutch`, `expensive`, `cheap_date`, `fragile_ego`, `iron_stomach`, 0-2 per raider. docs/16 §11 does not list traits as a cut, and docs/14 §5 schema carries the field.
**Doc** docs/04 §10 (🔷 PROPOSED). No docs/15 row. Recommended default: **cut for 1.0 by a BL row** (a sixth axis on recruits when the recruit price scale, Q-29's surcharge and the BIG-dumb counters are still unsettled) — the field stays serialised and empty. If the designer wants them: M (Recruitment rolls 0-2 by rarity; `Mistakes._situational_bp` reads `slow_learner`/`clutch`; `Recruitment.cost_of` reads `expensive`; `Comfort` reads `cheap_date`; `BackstoryPool` weights read the ego pair; one line on the Tavern card and RaiderDetail).
**Owns** docs/15 (BL row) — or, if built: `sim/core/Recruitment.gd`, `sim/core/Mistakes.gd`, `sim/core/Comfort.gd`, `sim/content/BackstoryPool.gd`, `game/screens/Tavern.gd`, `game/screens/RaiderDetail.gd`, `tests/unit/test_recruitment.gd`. **Size** S (cut) / M (build). **Wave** 6 (the BL row); 9 if built. **Audit** none. **Designer:** yes/no, one word.

### CRITIC-M4 — S13 (encounter interstitial) and S16 (Codex) are in docs/13 §5's inventory and in nobody's plan except as a question; the docs strike is unsized
**Status** CONFIRMED.
**Evidence** docs/13 §5 :199 S13, :202 S16 (🔷 PROPOSED); docs/13 §13.1 :751 `F1` Codex row; `project.godot` binds `nav_codex`; `ScreenRouter.CODEX_SCENE` does not exist (SHIP-07/20). BL-24 runs the raid one encounter per rung, so S13's "HP/mana carry-over, swap-ins, continue or bank" has no state to show. UI's question 4 and SHIP-20's "S16 out of 1.0" both recommend the cut; docs/16 C4 sanctions the Codex cut; nothing sanctions S13's cut except BL-24 by implication.
**Fix** One BL row striking both from docs/13 §5 with the reason (S13: BL-24; S16: docs/16 C4 — the Records tab and the Market's compare tooltip carry the "who can wear this" answer today), delete `nav_codex` (SHIP-20), drop docs/13 §13.1's F1 row. **Owns** `docs/13-ui-ux.md` §5/§13.1, `docs/15`, `project.godot`, `game/core/ScreenRouter.gd`. **Size** S. **Wave** 6 (DOCS) / 8 (the key, with SHIP-07). **Audit** none.

### CRITIC-M5 — The nine Legendary portraits (docs/16 W3.4 "one bespoke portrait each") do not exist; `portrait_set` in every legendary file points at assets that are not in the tree, and no report sizes the art
**Status** CONFIRMED.
**Evidence** `data/legendaries/warrior.json:16-18 "portrait_set": {"full": "portrait/legendary_warrior_full", …}`; `ls game/assets/portraits/` = 21 PNGs (bork/gruk/tiny/spoof, class_*, avail_*), none `legendary_*`; `grep -rn portrait_set game/ sim/content/LegendaryPool.gd` = nothing reads the field; `Cards.portrait_for()` (`Cards.gd:79-97`) falls through by display name → class bust, so a Legendary shows the same bust as every Common of its class. DESIGNER-03 notes "portraits pending art" in passing; UI/CONTENT do not mention Legendaries' look at all.
**Doc** docs/04 §11 (Legendaries as characters), docs/16 W3.4. Recommended default: derive nine busts with `tools/art/derive_busts.py` (the tool that made the five class busts — BACKLOG:144) from the class bust with a distinguishing hue/prop pass, named by `display_name` so `portrait_for`'s first pass finds them; a bespoke portrait is the designer's if wanted.
**Owns** `tools/art/derive_busts.py`, `game/assets/portraits/legendary_*.png`, `sim/content/LegendaryPool.gd` (read `portrait_set` or drop the dead field), `tests/unit/test_legendaries.gd`. **Size** M. **Wave** 9 (only reachable once tiers mount; after the names land so the files are named once). **Audit** none — relates M5-END-3.

### CRITIC-M6 — Store copy (docs/00 §4.4.2, docs/16 W4.12) and the player-facing first-run text are in no report except SHIP-16's `README-player.txt` line; nobody owns the words a player reads before launching
**Status** CONFIRMED (small; wave 10).
**Evidence** docs/16 W4.12 "Store copy conforming to doc 00 §4.4.2, explicitly filtering out players who want to play the raid"; `grep -rn "store copy\|itch\|steam" build/plan/ship/*.md` = nothing. SHIP-16 generates a `README-player.txt` (controls, saves path, limits) but names no author for the one-paragraph pitch.
**Fix** The wave-10 release unit drafts the pitch from docs/00 §2-§4 into `build/exports/README-player.txt` and docs/16 §8.2's checklist; the designer signs it with the credits. **Owns** `tools/export_build.sh` (the generated text), `docs/00` §4.4.2 (the source). **Size** S. **Wave** 10. **Audit** M6-FINAL-*.

### CRITIC-M7 — docs/14 §12 instrumentation (`--instrument`, JSONL run logs) is unbuilt and unmentioned — correctly deferrable, and the cut line should say so
**Status** CONFIRMED (deferrable).
**Evidence** no producer of `user://analytics` (`grep -rn "analytics\|instrument" game/ tools/*.gd` = nothing); docs/14 §12.1 "Off in release … gated behind a `--instrument` launch flag". SHIP-16's file-logging line is the player-side crash log and is separate.
**Fix** none for 1.0; one line in the cut register ("post-ship: docs/14 §12"). **Size** —. **Wave** — (deferred). **Audit** none.



## Refuted

Twenty-seven CONFIRMED claims were re-read against the tree at HEAD 106ac8d (the wave-5 close), chosen for being load-bearing (a unit is sized on them) or for smelling stale (files wave 5 was editing). Every line below is the CRITIC's own grep or read, 2026-09-15 ~12:40.

### Spot-checks that HOLD (24 rows)

| Finding | Claim | Tree at HEAD | Verdict |
|---|---|---|---|
| SIM-05 | `Mistakes.attribute()` is never called | `grep -rn "attribute(" sim/` = the definition at `Mistakes.gd:452` only | HOLDS |
| SIM-06 | `_situational_bp(c)` reads only the actor's own tokens | `RaidSim.gd:1935-1941` — `c.has_token(AGGRO)` +800, `c.has_token(DISTRACTION)` +500, no raid argument | HOLDS |
| SIM-08 | `_pick_enemy` returns the first alive enemy | `RaidSim.gd:1944` | HOLDS |
| SIM-12 | attrition at `enrage_round + 5` | `RaidSim.gd:2025-2026` | HOLDS |
| SIM-18 | verify.sh stage 6 runs the sweep without `--drift` | `tools/verify.sh:203` — no `--drift` argument; the word appears only in a comment at :99 | HOLDS |
| SIM-13 | E4's m05 has no `effect`, m08 is `rounds 5, every 5` | `data/encounters_t1.json` E4 mechanics: `m05 {round 4, every 5, requires_melee 1}`, `m08 {rounds 5, every 5}`, `m09 {reduction_pct 40, rounds 3, target active_tank}` | HOLDS |
| LOOP-04 / UI-02 | "%d enemies" with no plural | `Town.gd:468`, `AdventureBoard.gd:523` | HOLDS |
| LOOP-13 | no listener on `rank_advanced` / `reputation_changed` | grep over `game/ tools/` minus the `signal`/`emit` lines = nothing | HOLDS |
| LOOP-16 | "They are fine." gated on `morale >= 40` | `Roster.gd:627-628`, `RaiderDetail.gd:371-372` | HOLDS |
| LOOP-19 | recruits priced on doc 04's scale | `Recruitment.gd:59 COST_BASE := [60, 180, 450, 1100, 3000]` | HOLDS |
| LOOP-22 / SHIP-07 | three `is_action_pressed` handlers, all in the router; no screen `_unhandled_input` | `ScreenRouter.gd:198-204` only | HOLDS |
| LOOP-25 | no listener on `guild_crisis` / `guild_disbanded` | grep = nothing outside the signal lines | HOLDS |
| LOOP-07 | `_next_mission()` falls back to `ladder[0]` | `Town.gd:458` | HOLDS |
| UI-14 | rewards row pads to `max(2, n)` | `AdventureBoard.gd:623`, `RaidPrep.gd:456` `for i in maxi(2, n)` | HOLDS |
| UI-16 | "The party stands here" caption | `RaidPrep.gd:74` | HOLDS |
| UI-26 | `PointLight2D` with no cull mask; no `light_mask` on panels | `SceneStage.gd:2295`; `grep light_mask\|cull_mask game/ui` = nothing | HOLDS |
| UI-47 | `colourblind_safe` is not a setting | only `Palette.gd:20/193/260` name it; not in `GameSettings.DEFAULTS` or `Settings.ROWS` (:78-115) | HOLDS — BUILD_STATE HANDOFF's "a CVD switch" is the stale claim |
| AUDIO-03 | one game call site outside Audio.gd | `RaidView.gd:1728 audio.duck(...)` only (line moved from 1713) | HOLDS |
| CONTENT-12 | `break_phase` never set outside Mistakes.gd | grep = nothing | HOLDS |
| CONTENT-25c / LOOP-18 | no starter weapon anywhere | `items_starting.json:13` "CANON: no weapon, off-hand or trinket — a Common recruit shows up unarmed"; no Chipped/Splintered item | HOLDS |
| CONTENT-29 | 22 of 72 bullets gendered | re-counted: 22 of 112 strings over 15 chars carry he/his/him/she/her (the 72-bullet base is the reporter's; the 22 is exact) | HOLDS |
| SHIP-06 | no consumer of `window_mode`/`vsync` | only `GameSettings.gd:45` declares them; `project.godot` has no `window/size/mode` | HOLDS |
| DESIGNER-02 | T1 `raid_adj: "Basic"` would render "Basic Basic Sword" | `tier_words.json:41`; `gen_items.gd:526 "Basic %s Sword" % adj` | HOLDS — S loop fix before the designer fills the column |
| DESIGNER-07 | BUILD_STATE says Q-29 is at its default; it is not | `BUILD_STATE.md:102`; `Recruitment.cost_of` has no gear term | HOLDS |

### Refuted or overtaken (the wave-5 close commit 106ac8d landed AFTER the reporters read)

### CRITIC-R1 — UI-49 (the 180x571 tooltip) is FIXED in the tree; "a pending handoff" is stale
**Status** REFUTED (as an open defect); the test and the `hover` sheet sweep remain (S).
**Evidence** `game/ui/Widgets.gd:382-389` carries handoff-W5-TOOLS §2's exact loop ("Pre-size the Labels to that width … probe: 571 -> 56 with this loop"). What is still owed: the `test_widgets_kit.gd` assertion (`get_contents_minimum_size().y < 80`) and one `--hover` shot per tooltip site. **Wave** 6, S, inside the fixture/sheet unit.

### CRITIC-R2 — Ten audit rows the reporters list as "still stale" were closed by 106ac8d; a wave-6 bookkeeping unit must re-diff before applying any report's close-list
**Status** REFUTED (the rows, not the findings).
**Evidence** `git diff 106ac8d~1 106ac8d -- build/plan/audit.json` flips to done: M3-SAVE-06, M3-TUNE-02, m5-m11-frontal-cleave, m5-m12-escalating-swing, m5-mechanic-dispatch-guard, Q59-4, M5-COMEDY-05, M6-A11Y-05, M5-TUT-11, M5-TUT-12, M5-TUT-14, M6-PLAY-02. SIM-01 still lists the three m5 rows; SIM-28/CONTENT-07 list TUT-11/12/14; CONTENT-11 lists COMEDY-05; SHIP-08 lists A11Y-05; SIM-21 lists Q59-4; LOOP-16/LOOP-25/SHIP-13 cite M6-PLAY-02 as open (its "solvency invariant" is now `_can_still_make_progress` per W5-TESTS — SHIP-13's "grep = nothing" predates it; re-check `tools/playtest.gd` before sizing SHIP-13).

### CRITIC-R3 — The true open queue is roughly half the 78 "open" rows: 38 are closable bookkeeping the reports have already evidenced
**Status** CONFIRMED (a tally, not a defect).
**Evidence** Closable with evidence in a report or in this one, all verified by the CRITIC against HEAD: SIM-01/03 → m5-m01-tank-swap, m5-m03-ground-effect, m5-m05-interrupt-check, m5-m07-positioning, m5-m08-fixate, m5-m09-healing-debuff, m5-mech-roll-site, m5-m04-double-spawn, M5-T25-12 (with CONTENT-27's note) = 9; CONTENT-07/11/24 → M5-TUT-01/02/06/08, M5-COMEDY-03/04/08/13, M5-QAB-3 = 9; SHIP-01/09/10/11 + LOOP-28 + AUDIO-02 → M3-SAVE-01/02/07/08/10, M6-JUICE-07 (stage 8/8 exists at `verify.sh:269`), DW-A1/A2/A3/A4 (`tests/unit/test_docs_links.gd` exists), M6-AUD-01/02 = 12; UI-42/43/44 → M4B-VFX-01, m4t-12 (`Guildhall.gd:223 bare_stage`, `:265`), M6-A11Y-07 (24 `log_*` glyphs in `game/assets/ui/icons/grid/`, `Widgets.gd:1388`) = 3; this report → M3-TUNE-01/03/04, M4B-CONV-01/02 = 5. Total 38. Remaining truly open: ~40 rows + 17 blocked. The plan should be built on that number, not on 78 — and `audit_stale.py --top 15` should be run once after the close so the ranking stops pointing at finished work.

### CRITIC-R4 — UI-33's evidence is half-stale: the `default_focus()` hook EXISTS in the router; only the two screen-side declarations are missing
**Status** PARTLY REFUTED (the finding stands; the fix is smaller than written).
**Evidence** `game/core/ScreenRouter.gd:232-250 initial_focus_target()` already calls `screen.default_focus()` when declared; no screen under `game/screens/` defines it. UI-33's fix ("`Results.default_focus()` returns …") is exactly right; its evidence line "Frame.focus_entry walks FOCUS_REGIONS … no screen defines a hook" should cite the router, and the unit needs no Frame change. **Size** S (two functions, one a11y_smoke assertion).

### CRITIC-R5 — SIM-01's closure of `m5-m05-interrupt-check` is premature as a CONTENT fact: the arm exists but M05 lands nothing on any encounter (SIM-13), so the row's "no effect" clause is still true
**Status** PARTLY REFUTED (SIM-01 and SIM-13 disagree with each other about the same row).
**Evidence** SIM-01 lists `m5-m05-interrupt-check` among the ten rows to close; SIM-13 says "relates m5-m05-interrupt-check (the row's 'no effect' clause is still true as CONTENT)". `data/encounters_t1.json` E4 `m05` has no `effect`; `RaidSim._apply_interrupt_effect` returns on `amount <= 0`. Close the row as `partial` with SIM-13's residue, not `done`.

### CRITIC-R6 — LOOP-29's "three of six provision icons do not exist" is REFUTED: all six are in the tree
**Status** REFUTED (the icon half); the prep-button and Quarters-button binding half stands (= UI-39).
**Evidence** `ls game/assets/ui/icons/grid/` → `item_whetstone_kit.png`, `item_mana_draught.png`, `item_guild_feast.png`; `ls game/assets/ui/icons/` → `item_minor_healing_potion.png`, `item_potion_of_steady_hands.png`, `item_rally_flask.png`; `Icons.gd:17` "`path()` looks in grid/ first, then the top". LOOP-29 read only the top directory. UI-39's S fix (`b.icon = Icons.at("item", sku_id)`) is the whole job; no `gen_icons.lua` work, no m4t-03 reopen. **Size** S (not M). **Wave** 6.


## Conflicts

Where two reports fix the same thing two ways, or one report's fix breaks a contract another states. Each names the resolution the plan should take.

### CRITIC-C1 — M6-BAL-04: four reports hand the designer four different "recommended defaults" for one ruling
**Reports** SIM-19 → lever (a) Common baseline −5→0 PLUS (c) for A3 only. CONTENT-08 → fold M01 into `boss_auto_raw` (a formula change on every M01 carrier: TR, A3, E3, E5) plus "the audit's cheapest lever" for the 45 pin. LOOP-24 → TR winnable ≥ 8/20 (drop M01 or re-price) PLUS a new rule "a wiped tutorial costs no morale". DESIGNER-01 → (c) size A1-A3 and the tutorials for 45 from docs/08 §9; "do not split the difference".
**Why it matters** BUILD_STATE says this ruling outranks every open item; a page with four defaults is a page the designer sends back. LOOP-24's morale exemption is a fifth canon number (docs/05 §7.1) nobody else proposes; CONTENT-08's formula fold changes E3/E5 too, which SIM-19 and DESIGNER-01 do not cost.
**Resolution** One page, one default, one alternative: **default (c)** as DESIGNER-01 states it, with CONTENT-08's mechanism named as HOW (c) is derived (the docs/08 §9.3 swing priced with the mechanic term where M01 is authored — so TR and A3 move by formula, not by hand); **alternative (a)** as SIM-19 states it (one number, `Morale.RARITY_OFFSET[0]`). Drop LOOP-24's morale exemption from the page (it is a separate Q, filed but not bundled). The page is written AFTER LOOP-19 lands (C7 below) so the gold arithmetic it quotes is the shipped one.

### CRITIC-C2 — The log and report rows: four units, three waves, two rules for the same two call sites
**Reports** UI-19 (wave 6, S): only the MISTAKE header wraps to two lines in the live log, type leads. UI-23 (wave 6, M): the REPORT's quotes wrap; amend spec 02 §2.1 to "LIVE rows never wrap". UI-35 (wave 6, S): the live log scrolls by whole rows at a fixed `LOG_ROW_PITCH`. LOOP-11 (wave 7, M): EVERY log row wraps (`Widgets.log_row` AUTOWRAP) in RaidView AND Results — "row pitch becomes variable". CONTENT-15 (wave 8, S): the joke row wraps to two lines in the live log and in Results. CONTENT-13 (wave 8, M): Minor same-type rows fold — same `_append_line` and post-mortem sites.
**Why it matters** LOOP-11's variable pitch breaks UI-35's whole-row snap; CONTENT-15 re-does in wave 8 what UI-19/23 do in wave 6; four agents would edit `RaidView._append_line` and `Results.gd:1150-1200` across three waves.
**Resolution** ONE unit in wave 6 (`W6-LOG`) owning `RaidView._append_line`/`_mistake_header`, `Results.gd` post-mortem rows, `Widgets.log_row`, spec 02 §2.1 (one sentence + BL row): live log = header one line with the type leading + quote up to two lines at a fixed 3-line max pitch (so UI-35's snap holds); report = header one line + quote fully wrapped, fold snapped to a row. CONTENT-15 and LOOP-11 close on it. CONTENT-13's fold lands in wave 7 on the settled shape, not 8.

### CRITIC-C3 — The tutorial lesson surface: three shapes, two waves, one of them writes into the save format
**Reports** CONTENT-09 (wave 8, M): `game/ui/TutorialHints.gd`, five beats, a dismissed set "kept in GameState v17". UI-55 (wave 7, S): one `Widgets.callout_band` over the log behind `RaidView.TUTORIAL_BAND`. LOOP-30 (wave 7, S): the band plus a `lesson` key on the encounter record so the writing pass owns the words.
**Why it matters** CONTENT-09's persisted set collides with SHIP-02's "one v17 bump, three keys" freeze plan; three agents would build the same band.
**Resolution** LOOP-30's shape in wave 7 (data-driven `lesson`, band on RaidView at the scripted round and on TR's Results); CONTENT-09's five beats become the strings of that field (prep and loot beats as the existing board/strip empty-state copy, not new hint code); no save field — in-session dismissal only. Q15's default (yes) applies; if the designer says no, the field stays and the band is a const flip.

### CRITIC-C4 — The Blacksmith callout's second row: three sentences for one string, one of them still admits an unbuilt feature
**Reports** LOOP-02 → "Under construction." (the designer's own `blurb`). UI-01 → the blurb, with the maybe-string kept as the tooltip, OR "Maybe someday. Not in this build." DESIGNER-10 → "Under construction." READS AS A PROMISE; default (b) out of 1.0, copy becomes a non-promise ("Closed. The smith took a better offer." or the designer's line) and the two `reputation.json` unlock strings drop the Blacksmith.
**Why it matters** UI-01's alternative contains "this build" — the exact class of string wave 6 exists to remove; LOOP-02/UI-01 ship a promise DESIGNER-10 says the build cannot keep; LOOP-06's guard on the town's "Next at Respected: Blacksmith opens" line only works if the `reputation.json` strings are split (M3-TUNE-05's shape).
**Resolution** Wave 6 copy unit: DESIGNER-10 (b) — a non-promise sentence on the callout (proposed to the designer in the same page as Q-13, shipped as the loop's if unanswered), the `reputation.json` town_unlock strings filtered by flag (LOOP-06's helper), the three "maybe" pins retargeted. If Q-13 comes back "yes", the L unit is wave 8's and the copy flips back to the blurb.

### CRITIC-C5 — The reputation chip: LOOP-05 (pips in the Day chip, wave 7) and UI-53 (a sigil glyph with a `REP_ICON` flip, wave 8) rewrite `Frame.gd:595-610` two ways for one Q06
**Resolution** One unit, wave 7: UI-53's sigil + LOOP-05's tooltip ("320 reputation · 80 more to Known") on chip 2; chip 4 already carries the rank sigil; pips only if Q06 answers "pips". Both reports close on it.

### CRITIC-C6 — Provision icons: LOOP-29 (M, wave 7, new icons + `Widgets.slot` cells) vs UI-39 (S, wave 6, `b.icon` on the existing button) on the same `RaidPrep._provision_button`
**Resolution** UI-39 (the icons exist — CRITIC-R6); LOOP-29's Quarters-button and rewards-row notes fold into the same S unit; UI-14's "exactly n cells" wins over LOOP-29's "floor at one" for the rewards row.

### CRITIC-C7 — LOOP-19 (recruit price 60 → 15 G, wave 6) changes the arithmetic of DESIGNER-01's lever (b) and LOOP-25/SHIP-13's "free first hire" floor while the designer is being asked to cost them
**Why it matters** Lever (b) is "60 G purse vs 150 G facility"; at 15 G a Common the purse buys four recruits, which changes what "cannot afford a hire" means for the solvency floor and the disband after-state; DESIGNER-07's Q-29 surcharge (wave 7) edits the same `cost_of`.
**Resolution** LOOP-19 lands FIRST in wave 6 (it is the register's own default and both scales are PROPOSED), then the BAL-04 page is written against the shipped 15 G; Q-29's surcharge waits for wave 7 as DESIGNER-07 says; the solvency floor question (SHIP-13 q8) is asked on the same page with the 15 G figure.

### CRITIC-C8 — Focus: SIM-04 builds it (L, wave 7); CONTENT-27 says ship M10 as silence-only and reword docs/10 (S, wave 7)
**Why it matters** An L unit that needs designer numbers (SIM q3), moves every golden, and serves a mechanic (M10) whose first carrier is Tier 3 — which does not mount until the words land and the tier sweep runs (C14).
**Resolution** CONTENT-27 for 1.0: `MANA_BURN_DRAIN_ENABLED` stays false, docs/10 §10 M10 row reworded with a BL row, DW-C1/C2 closed as "post-1.0 with the row". SIM-04 goes below the cut line unless the designer supplies `focus_max`/`focus_per_cast` by the end of wave 6 AND wave 7 has a free unit — it will not.

### CRITIC-C9 — "One golden regeneration": every SIM wave moves the goldens, and SIM-16's E2/E4 goldens written in wave 6 will be rewritten in 7 and 8
**Reports** SIM-05/06/07/14/15/24/29 (wave 6), SIM-10 kits + SIM-17 (wave 7), LOOP-12's `wipe_cause` (wave 7), CONTENT-12's ninja roll (wave 7), SIM-08/12/13/19 + the BAL-04 lever (wave 8). Each says "regenerate once".
**Resolution** State it as three regenerations — one per SIM wave, each in one commit with before/after — and write SIM-16's two new goldens in wave 8's regeneration, not wave 6's. The drift gate (SIM-18) lands BEFORE the first one.

### CRITIC-C10 — `Settings.ROWS`: seven touches across four waves on one table with a row-count pin
**Reports** LOOP-26 (wave 6: hide 4 rows, drop the header count and the audio notes, wire or hide V-sync), UI-28 (wave 9: the same list), AUDIO-14 (wave 7: the two note strings + the Voice reason), AUDIO-07 (wave 7: the Music note becomes "Ambience, and music when it is written"), SHIP-06 (wave 6: add `window_mode`, enable V-sync), SHIP-11 (wave 10: "No music in this release"), UI-47 (wave 6: add `colourblind_safe`), CRITIC-M1 (wave 8: add `forgiving_guild`).
**Resolution** One Settings unit in wave 6 (`W6-SETTINGS`): LOOP-26's hides, SHIP-06's window/V-sync rows, UI-47's CVD row, and the audio rows relabelled "Audio — music and ambience" / "Audio — voice" with NO note (AUDIO-14's "the row is padlocked with a reason" only if Q-C says nothing is voiced — default per AUDIO-13 is exactly that, so padlock it now). Wave 8 adds one row (M1) by handoff line. UI-28's wave 9 is struck — the wave-6 directive does not allow the "13 of 17 live" header to survive three waves.

### CRITIC-C11 — Fixtures and sheets: LOOP-01 (`--fixture=new`), UI-15 (`--fixture=play`), UI-39 (fixture holds two of each consumable), UI-49 (a `hover` sheet), CRITIC-R1 (the tooltip assertion) — five S asks on `tools/fixture_reference.gd` / `shot.gd` / `shot_all.sh`
**Resolution** One instrument unit, first in wave 6 (`W6-SHEETS`), so every later "one look" review is on a state a player can reach. Not a conflict; a merge — listed because two reports each claim the file.

### CRITIC-C12 — The wipe's cause: LOOP-12 adds `SimResult.wipe_cause` and an extra −4 delta in `sim/core/RaidSim.gd` (wave 7) while SIM-05's cascade unit owns that file in wave 6 and does not set it
**Resolution** SIM's wave-6 cascade unit ALSO sets `wipe_cause` (the deepest live chain at the wipe round is the same data `attribute()` produces; LOOP-12's rule — last Severe before the first tank/healer death, else the deepest cascade, else "nobody" — is the tie-break) and queues the −4 behind a const with a BL row; LOOP-12's Results sentence and RaidView focus land in wave 7 reading a field that exists.

### CRITIC-C13 — Keyboard: LOOP-22 builds `1`-`4` sort handlers on Roster/Tavern/Market; SHIP-07 says no sort mode exists to bind and strikes the row by BL
**Resolution** SHIP-07. Space = pause, `1`-`4` = speeds on RaidView, Q/E on RaiderDetail, F on Records; the list-screen sort row is struck from docs/13 §13.1 with a BL row; `nav_codex` deleted (SHIP-20, CRITIC-M4). One unit, wave 8, M.

### CRITIC-C14 — Tiers 2-5: CONTENT-06 sweeps them in wave 7; SIM's balance-moving units (kits, targeting, attrition, E4 content, the BAL-04 lever) land in waves 7-8 — a wave-7 tier sweep measures a sim that changes the next wave
**Resolution** Split CONTENT-06: the tier THREADING (SIM-22's two call sites + TierScaling's budget rung, S-M, Tier 1 unchanged) lands in wave 7; the per-tier SWEEP and the docs/08 §9.6 regeneration land in wave 9 after the wave-8 re-baseline, in the same unit as the first tier-2 golden (SIM-16). LOOP-06's promise guard stays in regardless.

### CRITIC-C15 — Arena routing: UI-54 keys the arena on the encounter KIND (raid → dungeon); CONTENT-26 keys it on the TIER (`tier_words.json` `scene`); both replace the same three `DEFAULT_ARENA` sites in wave 7
**Resolution** One function, one owner: `SceneStage.arena_for(encounter)` = the tier's `scene` if the tier row names one, else UI-54's kind rule; land in wave 7 with UI-54's default (Q-96 per raid) and CONTENT-26's keys added to `tier_words.json` for tier 1 only. The art for per-tier arenas (CONTENT-26's "L+") is below the cut line (C8's Raid-5-equivalent: docs/16 W3.6 is the one XL art line the reports do not size).

### CRITIC-C16 — Wishlists: SIM-21 builds them in wave 9 (L); CONTENT-19 ships the flag off; LOOP-17 hides the sentence
**Resolution** CONTENT-19 + LOOP-17; docs/16 C3 sanctions the cut; SIM-21's generator is post-ship. Q59-3 → "cut for 1.0" with a BL row.

### CRITIC-C17 — Class kits: SIM-10's six units (L) are scheduled for wave 7 beside Focus (L), AUDIO-07 (L), CONTENT-06 (L), LOOP-25 (L), UI-32's second half, the v17 save bump (M+M) and CONTENT-03/12 (M+M) — twelve-plus units in a five-to-seven-unit wave
**Resolution** See Order and capacity: the three DECIDED kit rules (Q-57 Lost Aggro + Taunt/`should_retarget` = SIM-17, Q-58 healer threat = SIM-09, Q-46 Bard songs) are one M unit in wave 7; the four PROPOSED kits (Wizard ramp, Rogue positional, Monk guard, Mage buff/AoE) are one M unit in wave 8 if capacity, else a BL row deferring them — they are 🔷 and the classes function without them.

### CRITIC-C18 — Two reports own the "copy lint" (UI-27's `tools/lint_copy.sh`, LOOP's bar grep) and two own the feed (UI-51 collapses morale rows; LOOP-13 adds a reputation row) — same files, no conflict of intent
**Resolution** Copy lint → the wave-6 copy unit (one owner); the feed → LOOP-13's unit also does UI-51 (both in `Cards.recent_events`).


## Order and capacity

**The capacity fact.** Wave 5 ran seven units in one day under the brief-review rule (docs/_log/progress.md WAVE 5), each an agent-afternoon, each with absolute file ownership. Five waves is therefore ~35 units. The seven reports propose, by their own wave columns: wave 6 = 28 (UI) + 13 (CONTENT) + ~20 (LOOP) + 8 (SIM) + 3 (AUDIO) + 9 (SHIP) findings; wave 7 = at least five L units (SIM-04, SIM-10, CONTENT-06, LOOP-25, AUDIO-07) plus two M save units, two M UI passes and four M content/loop items. Even bundled by file, that is 12-15 units in wave 6 and 12+ in wave 7. **Every report front-loads as if its wave 6 were the only wave it gets.** The plan below bundles by OWNED FILE (the rule that made wave 5 work), holds each wave to seven units, never gives one file to two units in a wave, and puts every L unit either split in two waves or below the cut line. Two-stage units died to session limits before (memory: parallel-agent-waves); none is proposed here.

**The dependency spine (why this order):**
1. Instruments and honesty before anything is reviewed (sheets of a real guild; strings that admit unbuilt work gone; the queue's true count).
2. The drift gate BEFORE the first golden regeneration; one regeneration per SIM wave (C9).
3. LOOP-19's recruit price BEFORE the designer's page; the page BEFORE wave 8's balance unit; the words BEFORE the wave-9 mount; the names BEFORE the wave-10 export.
4. Rule fixes (cascade, effects) BEFORE the balance wave; the balance wave BEFORE the tier sweep (C14); the tier sweep BEFORE the export.
5. The audio GATE before the audio BEDS; the BEDS after W5-MOUNT's SceneStage has settled (it has).
6. Copy and layout settle in 6-7 BEFORE keyboard handlers target them in 8.
7. Save format: one bump in 7, frozen in 9.

### Wave 6 — "Nothing lies" (7 units)

| Unit | Owns (absolute) | Delivers | Size |
|---|---|---|---|
| **W6-SHEETS** | `tools/fixture_reference.gd`, `tools/shot.gd`, `tools/shot_all.sh`, `tests/unit/test_widgets_kit.gd` (the tooltip assertion only) | LOOP-01 `--fixture=new`, UI-15 `--fixture=play` (legal Known save, six feed rows, no `level`), UI-39's stocked cupboard in the fixture, the `hover` sheet (UI-49's sweep), CRITIC-R1's assertion; re-shoot all sheets at the close | S-M |
| **W6-COPY** | `game/screens/Town.gd`, `AdventureBoard.gd`, `Guildhall.gd` (TABS), `RaiderDetail.gd` (`_written`, Quarters line), `Completion.gd` (credits panel), `game/core/RaidPlan.gd` (`locked_reason`), `game/core/StartingRoster.gd` (backstory draw + CONTENT-20's pool), `game/ui/Cards.gd` (`view_all_reason`, `event_log` hint), `sim/core/Achievements.gd` (one string), `sim/core/Reputation.gd` (`town_unlock_for_build`), `tools/lint_copy.sh` (new), their test pins | LOOP-02/03/04/06(guard)/07/14/15/17/27, UI-01/02/12/27/50, CONTENT-20, CRITIC-C4's Blacksmith sentence, the copy lint; the LOOP C-table's HIDE/REWORD rows except Settings and RaidPrep | M |
| **W6-SETTINGS** | `game/screens/Settings.gd`, `game/core/GameSettings.gd`, `game/ui/Boot.gd` (`_apply_window_mode`), `project.godot` `[display]`, `tests/unit/test_settings.gd`, `test_options_layout.gd` | C10: LOOP-26/UI-28 hides, SHIP-06 window mode + V-sync live, UI-47 `colourblind_safe` row, AUDIO-14's audio rows relabelled with no notes (Voice padlocked per AUDIO-13's default) | M |
| **W6-LOG** | `game/screens/RaidView.gd` (`_append_line`, `_mistake_header`, the log scroll), `game/screens/Results.gd` (post-mortem rows, `_by_raider`), `game/ui/Widgets.gd` (`log_row` only), `art/ref/specs/02-*.md` §2.1, `tests/unit/test_log_player.gd`, `test_results_layout.gd` (new) | C2: UI-19/23/24/35, LOOP-11, CONTENT-15 — the reading surfaces, one rule, one BL row (handoff to W6-LEDGER) | M |
| **W6-SIM-CASCADE** | `sim/core/RaidSim.gd`, `sim/core/Mistakes.gd`, `sim/core/EventLog.gd`, `tools/verify.sh` (stage 6b), `tools/balance_sweep.gd` (`--drift` seeds), `tests/baselines/sweep_baseline.csv`, `tests/unit/test_raid_sim.gd`, `test_mistakes.gd`, `test_event_log.gd`, `tests/golden/*.json` | SIM-18 FIRST (the gate armed at 200 seeds), then SIM-05 (attribution) + C12's `wipe_cause` field + SIM-06 (healer/raid-wide tokens) + SIM-14 (no fire without fire) + SIM-24 (channel rename) + SIM-29 (debug fields); ONE regeneration with before/after | M-L (the largest unit of the wave; SIM-07/15/09 are deliberately NOT here) |
| **W6-PAGE** | `build/plan/ship/designer-page.md` (new), `PROVENANCE.md` (new), `tools/export_build.sh` (step 0 provenance hold only), `tools/gen_items.gd` (`raid_adj` semantics only), `data/tier_words.json` (columns, not words), `data/credits.json` (derivable attribution rows), `tools/corpus_review.py` (new), `build/plan/ship/corpus-review.md` | DESIGNER's answer sheet with ONE default per row (C1), the naming sheet (DESIGNER-02's five columns + leather + the eight names, CONTENT-04), the comedy/name review page (CONTENT-16/21, DESIGNER-08), SHIP-17's gate, DESIGNER-05's attribution draft, DESIGNER-02's `raid_adj` fix — written AFTER W6-LEDGER's LOOP-19 lands | M |
| **W6-LEDGER** | `build/plan/audit.json`, `docs/15-open-questions.md` (new rows only), `BUILD_STATE.md`, `BACKLOG.md`, `sim/core/Recruitment.gd` (`PRICE_SCALE` const only), `tests/unit/test_recruitment.gd`, `test_playtest_invariants.gd`, `build/plan/q-*.md` (mark consumed) | CRITIC-R2/R3's 38 closes (re-diffed against HEAD), M5-OQ-1's sweep, LOOP-19 (recruit price to doc 11 behind a switch — C7), the register rows the wave writes: SIM-27's twelve mech-arms/W5-SIM calls, AUDIO-06's two Q rows (renumbered), CRITIC-M2 Retreat strike, CRITIC-M3 traits cut, CRITIC-M4 S13/S16 strike, DESIGNER-06 Q-53 strike, DESIGNER-07 BUILD_STATE:102 fix, W6-LOG's spec-02 row, M6-JUICE-04 strike from BACKLOG | M |

Not in wave 6 although the reports asked: AUDIO-BIND (7 — it touches RaidView/RaidPrep/Widgets, all owned above), UI-26's light mask (7, SceneStage), UI-39's prep icons (7, RaidPrep), LOOP-13 (7, Results/GameState), CONTENT-05/25 (8, the regeneration wave), UI-30/31 (7, Frame/Cards), SIM-07/15/09 (7), SIM-11's docs/08 rewrite (7).

### Wave 7 — "The fight reads" (7 units)

| Unit | Owns | Delivers | Size |
|---|---|---|---|
| **W7-PREP** | `game/screens/RaidPrep.gd`, `game/core/RaidPlan.gd` (`risk_word`/`verdict`), `tests/unit/test_prep_layout.gd`, `test_raid_plan.gd` | UI-16/LOOP-09 the party on the band (the stage API only — no SceneStage edits), UI-17 drawn hatch, UI-39 provision icons (+ RaiderDetail Quarters by handoff), LOOP-08 one headline word + one delta, UI-14's exact-n rewards row (the `RaidPrep.gd:456` site here; the `AdventureBoard.gd:623` twin is W6-COPY's, done there) | M |
| **W7-STAGE** | `game/ui/SceneStage.gd`, `game/assets/scenes/*.json`, `game/ui/Widgets.gd` (`speech_plate`, `speech_bubble`), `game/ui/Frame.gd` (rail label floor, UI-30), `game/ui/Cards.gd` (ClassRow, UI-31), `tests/unit/test_scene_stage.gd`, `test_kit3.gd`, `test_text_scale_layout.gd` (allow-list rows it clears) | UI-26 light mask, UI-20/35b plate keep-out, UI-21 party spread + badge stack, UI-22 boss forward + shadow, UI-04/07 town/tavern plate placement, UI-34 number stagger + boss `head_of`, C15's `arena_for` (UI-54 kind rule + CONTENT-26's tier key, tier 1 only), UI-30/31 (the wave-5 leftovers BUILD_STATE names) | M-L (the wave's largest; if it must shed, UI-04/07 to wave 9) |
| **W7-REPORT** | `game/screens/Results.gd` (headline, tally, clear page, buttons, `default_focus`), `game/screens/RaidView.gd` (the wipe overlay's buttons + `default_focus` + the tutorial band — C3), `game/core/GameState.gd` (`_award_reputation`, `log_event` sites), `game/screens/Town.gd` (the rank-up callout only, by handoff line), `game/ui/Cards.gd` (`recent_events`), `game/ui/Icons.gd` (one glyph), `data/encounters_tutorial_t1.json` (`lesson` key), `sim/model/Encounter.gd` (loader), `tests/unit/test_wipe_sequence.gd`, `test_full_loop.gd`, `a11y_smoke.gd` | LOOP-12 the cause sentence (reads W6's `wipe_cause`), LOOP-13 reputation shown + rank-up beat, UI-51 feed collapse, UI-36 CLEARED stamp + crimson commit, UI-37 Try again (Q-53 default), UI-33 default focus, LOOP-30/UI-55 the tutorial band (C3) | M |
| **W7-SIM-EFFECTS** | `sim/core/RaidSim.gd`, `sim/core/Mistakes.gd`, `sim/model/Combatant.gd`, `sim/core/Formulas.gd` (`should_retarget` wiring), `tests/unit/test_raid_sim.gd`, `test_mistakes.gd`, `tests/golden/*.json` | SIM-07 (three healer outcomes), SIM-15 (AFK/LOOT_CALL/ARGUMENT/NO_CONSUMABLE; NINJAPULL retired by the row unless the designer answers CONTENT-12 "build"), SIM-09 (healer threat + chain skip, Q-58), SIM-17 + Q-57 (Taunt, `should_retarget`, Lost Aggro zeroing — the tank half of the kits), SIM-20's quirk hook threading (identity, S); the wave's ONE regeneration | M-L |
| **W7-AUD-BIND** | `game/core/Audio.gd`, `game/ui/Widgets.gd` (`_guard_cta`/`wax_button`/`tab_row` lambdas only), `game/screens/RaidView.gd` (`_append_line`'s stamp block, `_wipe_stamp` — ~10 lines, coordinated with W7-REPORT by function), `game/screens/RaidPrep.gd` (`_toggle`, `_on_depart` — by handoff to W7-PREP), `tools/audio/gen_sfx.py` (`--check`), `tools/build_art.sh`, `tests/unit/test_audio_binds.gd` (new), `test_audio.gd` | AUDIO-03/04/05/08/11/15/16/18: the eight hooks bound, the byte gate, the tape test; `ui.row_select` as three handoff lines | M |
| **W7-SAVE** | `game/core/GameState.gd` (`to_dict`/`from_dict`, `dismiss_raider`, `_autosave_transition`, `save_now`, `record_attempt`'s `active_run`), `game/core/SaveGame.gd`, `game/screens/MainMenu.gd` + `LoadSave.gd` (the Continue route), `game/screens/RaidView.gd` (`_unhandled_input` for `ui_cancel` only — SHIP-03's Esc rule), `tests/unit/test_savegame.gd`, `tests/fixtures/saves/v17_sample.json`, `docs/14` §7.1 notes | SHIP-02 (`pending_deltas`, `log_tail`, `best_rounds`), SHIP-03 (`active_run` + Esc = skip to the report), SHIP-15 (dismiss autosave, achievements on transition writes); v17 is the LAST bump before the freeze | M |
| **W7-DOCS** | `docs/08-stats-and-formulas.md`, `docs/05-morale.md`, `docs/03` §4.2, `docs/02`/`docs/04` worked examples, `docs/07` (§3 Retreat, §5.2 class-failure column, §9 channels, §10 M10), `docs/10` §9-§10, `docs/01` §8.2/§6/OQ-6, `docs/13` §5/§12.4/§13.1/§15.1, `docs/14` §4/§7.3/§10.4, `tests/unit/test_canon_guard.gd`, `tests/unit/test_docs_links.gd` | SIM-11 (§8.8 published once), SIM-23, SIM-24's doc half, CONTENT-10, CONTENT-27 (M10 silence-only — C8), DW-C1/C2 closed by the row, DESIGNER-06's propagation, CRITIC-M2/M4's doc edits, AUDIO-06's pointers, SHIP-01's path deviations, SHIP-06's display section | M |

### Wave 8 — "The numbers are ruled" (7 units; assumes the designer's page came back by the end of wave 7 — if not, W8-SIM-BALANCE runs on the recommended defaults per the ship rule and says so)

| Unit | Owns | Delivers | Size |
|---|---|---|---|
| **W8-SIM-BALANCE** | `sim/core/RaidSim.gd`, `sim/core/Formulas.gd` (`DIFFICULTY_MULT`), `sim/core/Morale.gd` OR `data/encounters_adventure_t1.json` + `encounters_tutorial_t1.json` (the lever), `data/encounters_t1.json` (E4 m05/m08/m09), `sim/model/Encounter.gd` (validator), `sim/core/Mistakes.gd` (per-slot tutorial rate — CONTENT-30), `tools/balance_sweep.gd` (`--forgiving`), `tools/verify.sh` (stage 7 → FAIL), `tests/unit/test_adventures.gd`, `test_tutorials.gd`, `test_encounters.gd`, goldens, baseline | SIM-08 targeting + Mage AoE, SIM-12 attrition, SIM-13 + SIM-27#2 E4 content, SIM-19 the ruled lever, CRITIC-M1's multiplier (the sim half), CONTENT-30, the two pins flipped, the regeneration + `--rebaseline` with numbers, the playtest 8/8 | L — but single-stage: every item is a number or a rule already written; the risk is the sweep time, not the session |
| **W8-CRISIS** | `game/ui/Frame.gd` (crisis stamp on the day chip), `game/screens/Town.gd` (sidebar at-risk block, the modal, the post-disband state), `game/core/GameState.gd` (`guild_crisis` listener wiring, the solvency sentence), `game/screens/AdventureBoard.gd` (the cannot-field sentence), `sim/core/Morale.gd` (three words), `tools/playtest.gd` (SHIP-13's (2) walk), `tests/unit/test_game_state.gd`, `test_screens.gd`, `test_full_loop.gd` | LOOP-25 banner + modal + after-state, SHIP-13 (2)(3), LOOP-16 Cheer-up gate, LOOP-24's skip copy; the solvency floor only if the designer said yes (default: the sentence and New Guild) | M-L |
| **W8-KEYS** | `game/screens/RaidView.gd` (`_unhandled_input` extended), `RaiderDetail.gd`, `Guildhall.gd` (Records filter), `Tavern.gd`/`Market.gd` (filter only), `game/core/ScreenRouter.gd` (codex removed), `project.godot` `[input]`, `game/screens/Settings.gd` (the Controller-glyphs reason, one string by handoff), `docs/13` §13.1, `docs/15` (three BL rows), `tests/unit/test_a11y.gd` | SHIP-07/20, LOOP-22's surviving rows (C13), CRITIC-M4's key | M |
| **W8-ITEMS** | `data/tier_words.json` (the words, if given), `data/items_t1_*.json`, `data/items_starting.json`, `data/items_t2..5_*.json` (regen), `data/legendaries/*.json` (`display_name`, if given), `tools/gen_items.gd`, `sim/content/ContentDB.gd` (`tier_scene` accessor), `sim/core/Buildings.gd` (starter shelf), `data/backstories.json`, `sim/content/BackstoryPool.gd`, `tests/unit/test_tier_scaling.gd`, `test_items.gd`, `test_market.gd`, `test_gen_items_merge.gd`, `test_names_and_backstories.gd` | CONTENT-05 (off-hands), CONTENT-25 (Q-42/Q-40/Q-28 + Q-43 twins), CONTENT-29 (pronouns), LOOP-18 (0-stat starter weapon behind a switch — the designer's default), CONTENT-03 (the 68 exception rows, if the words landed; else the template only), CONTENT-01/17 applied (words + names → `name_pending` clears), CONTENT-26's tier keys (tier 1) | M-L (if words landed) / M |
| **W8-TUTOR** | `game/screens/AdventureBoard.gd` (skip block copy, the walked-out sentence's second state), `game/core/GameState.gd` (`start_attempt` break roll — only if CONTENT-12 = build; else nothing), `sim/core/RaidSim.gd` (`run()` entry for `ninja_pulled` — by handoff to W8-SIM-BALANCE), `game/core/LogPlayer.gd` (`collapse`, CONTENT-13), `game/core/GameSettings.gd` (`LOG_COLLAPSE`), `tests/unit/test_log_player.gd`, `tests/golden/Scenarios.gd` (SIM-16's E2/E4 goldens, written in THIS wave's regeneration) | CONTENT-13 the fold, CONTENT-12's decision applied, SIM-16, LOOP-24's copy, the tutorial band's strings (C3) | M |
| **W8-SCALE-1** | `game/screens/RaidView.gd` (the header column + 150 log rule), `game/screens/Results.gd` (the one-column 150 layout), `tests/unit/test_text_scale_layout.gd` | UI-32's RaidView + Results halves; the allow-list rows they clear | M |
| **W8-FACILITY** | `tools/art/gen_facility_thumbs.py` or `patch_plate.py`, `game/assets/bg/facility_l1..l4.png`, `game/screens/Facilities.gd`, `game/screens/Market.gd` (LOOP-20's honest "Next:" prefix + UI-09's empty-window default + UI-10's fold snap), `game/assets/scenes/stage_camp.json` (tent prop by level), `game/ui/SceneStage.gd` (the level key — by handoff to nobody: W7-STAGE has closed, so this unit owns the file this wave), `tests/unit/test_art_sources.gd`, `test_market.gd` | UI-40 four tent states (Q18's default), LOOP-20 copy, M3-LOOP-05's mechanism, UI-09/10 Market first impression + fold | M |

### Wave 9 — "Tiers and finish" (7 units)

| Unit | Owns | Delivers | Size |
|---|---|---|---|
| **W9-TIERS** | `sim/core/RaidSim.gd` (the two `tier` call sites), `sim/content/TierScaling.gd`, `tools/gen_items.gd` (budget rows), `tools/balance_sweep.gd` (`--tier`), `tools/playtest.gd` (`--tier`), `sim/core/Economy.gd` (CONTENT-23's sell slope, behind a switch), `docs/08` §9.6 (regen), `tests/unit/test_tier_budget.gd`, `test_balance_sweep.gd`, `test_economy.gd`, `tests/golden/Scenarios.gd` (t2 carrier goldens), `docs/_log/progress.md` (the per-tier curve) | SIM-22 + CONTENT-06 (threading + the sweep, AFTER wave 8's sim is final — C14), CONTENT-23, SIM-16's tier goldens; walls recorded as rows, not tuned. **If the words never came:** this unit instead lands DESIGNER-02's honest default — Tier 1 only, `completed` retimed to the Raid 1 clear behind a switch, S17's copy saying so, a BL row and a README line | L if words / S if not |
| **W9-KITS** | `sim/core/RaidSim.gd`, `sim/core/Formulas.gd`, `sim/model/Combatant.gd`, `data/classes.json`, `tests/unit/test_class_kits.gd` (new), goldens, baseline (one re-baseline, folded into W9-TIERS's if both run) | The DECIDED Bard songs (Q-46, `BARD_S_DIVISOR := 10` proposed); the four PROPOSED kits (Wizard ramp, Rogue Behind/Front, Monk Guard, Mage buff) ONLY if the designer confirmed them on the page — else a BL row deferring them (C17) | M |
| **W9-AUD-AMB** | `tools/audio/gen_amb.py` (new), `game/assets/audio/amb/`, `game/core/Audio.gd` (`play_bed`/`stop_bed`/`BEDS`), `game/ui/SceneStage.gd` (ONE call in `load()`), `tools/build_art.sh` (one block), `tests/unit/test_audio_beds.gd` (new) | AUDIO-07 split to fit one afternoon: camp, tavern, market and one arena bed with the door and the crossfade; the dungeon/town beds and the rank layers are the wave-10 buffer's if there is one, else the camp bed plays under the arena too (a stated default) | M-L |
| **W9-SCALE-2** | `game/screens/RaidPrep.gd`, `Market.gd`, `RaiderDetail.gd` (their 150 layouts), `tests/unit/test_text_scale_layout.gd` | UI-32's other three screens; the allow-list EMPTY at 100/125/150 (the bar's line 1) | M |
| **W9-ART** | `tools/art/gen_actors.py`, `game/assets/actors/*` (regen), `tools/aseprite/gen_icons.lua`, `game/assets/ui/icons/grid/emote_*.png`, `game/ui/SceneStage.gd` (`set_fallen`, bubble scale), `game/ui/PaperDoll.gd`, `tools/art/derive_busts.py`, `game/assets/portraits/legendary_*.png`, `art/ref/specs/07-*.md` (the emote table), `tests/unit/test_art_sources.gd`, `test_icons.gd`, `test_legendaries.gd` | UI-38 the fallen lie down, UI-41 24px emotes + the mapping, UI-52 per-family silhouettes, CRITIC-M5 nine derived Legendary busts (only if named) | M-L |
| **W9-POLISH** | `game/screens/MainMenu.gd` (guild name), `data/names.json` (guild-name list), `game/screens/LoadSave.gd`, `game/ui/Frame.gd` (`nav_items`, chip 2 — C5), `game/screens/Completion.gd` + `stage_camp.json` (UI-48a/c), `game/screens/Tavern.gd` (UI-05/06/08), `game/screens/Guildhall.gd` + `RaiderDetail.gd` (UI-56 wide panel), `game/screens/Settings.gd` (UI-29 panel height), `game/ui/Type.gd` + the `%d G` sites (LOOP-21), `tests/unit/test_frame_wide.gd` (new, m4t-07), `test_type.gd`, `test_menu_lockup.gd`, `test_tavern.gd` | LOOP-23, SHIP-14, C5 the reputation chip, UI-48a/c, UI-05/06/08, UI-56, UI-29, LOOP-21, UI-13 (Board sidebar wrap — the Board file is free this wave), UI-18 | M (many S; the unit sheds UI-18/UI-29 first if it runs long) |
| **W9-REVIEW** | `build/plan/ship/corpus-review.md` (refresh with the 68 + 42 + tier-2 lines), `data/mistake_lines.json`, `data/legendaries/*.json` (barks), `data/names.json`, `docs/15` (BL-53 + the comedy row), `tests/unit/test_mistake_lines.gd` | CONTENT-16/21, DESIGNER-08: the page handed over ONCE with every line that will ever exist; the keep/rewrite/cut marks applied as they come; the tests re-run | S (instrument) + the designer's read |

### Wave 10 — "Release" (5 units + a buffer; a release wave needs slack)

| Unit | Owns | Delivers | Size |
|---|---|---|---|
| **W10-EXPORT** | `tools/export_build.sh` (steps 7-9), `export_presets.cfg`, `project.godot` (file logging, version), `tests/unit/test_export.gd`, `build/exports/README-player.txt` (generated) | SHIP-05 fresh-profile launch + the migration boot, SHIP-16 zip + OFL texts + no console wrapper + logging, SHIP-17's gate green (or the exact HOLD list printed), CRITIC-M6's pitch text; `EXPORT OK` or the honest `--dev` stamp | M |
| **W10-README** | `README.md`, `tests/unit/test_readme.gd`, `BUILD_STATE.md` (the budget line, SHIP-09b), `docs/16` §8.2 | SHIP-12, SHIP-09's stated budget, the licence line (designer) | S |
| **W10-DELETE** | the C3-C5 dead branches across `Town/AdventureBoard/Guildhall/Market/RaiderDetail/Roster/Settings/Frame/Cards/MainMenu.gd`, `game/core/ScreenRouter.gd` (`TRANSITION_MS` switch, UI-46), `BACKLOG.md`, `tests/unit/test_full_loop.gd:411`, `test_screens.gd:380` | LOOP's bar grep returns nothing; UI-46's switch; the last "not in this version" branch gone | S-M |
| **W10-CREDITS** | `data/credits.json`, `game/screens/Completion.gd` (print the roll), `docs/00` §4.4 (the designer's line), `docs/15` (Q-21, M5-END-4 closed) | The roll as signed; UI-48b; if unsigned, the derivable block under "Credits" and the README's status line | S |
| **W10-WALK** | `docs/_log/progress.md`, `tools/perf_probe.gd` (`--window`) | SHIP-19 the second-machine first-run walk, SHIP-09c the low-end perf rows, the record | S (needs a second laptop and a person) |
| **W10-BUFFER** | whatever wave 9 shed; the designer's re-tunes (audio PARAMS, corpus rewrites, the arena/boss answers) | — | the slack a release wave must have |

### What the reports mis-sized (beyond the wave columns)

- **SIM-10 (L, "six S/M units")** is six afternoons; the plan above lands the tank half (Q-57, SIM-17) in 7 with the effects, Bard in 9, the rest behind a BL row. A wave cannot absorb six sim units beside a regeneration.
- **CONTENT-06 (L)** is one unit in wave 9, not 7: the tier threading is two `RaidSim.gd` call sites that change nothing at Tier 1 (SIM-22's own note), so it lands in W9-TIERS beside the sweep it exists for, after the wave-8 sim is final (C14).
- **LOOP-25 (L)** is M once M6-PLAY-02's invariant (already landed) is subtracted; the after-state is a sentence unless the designer buys the floor.
- **AUDIO-07 (L)** ships four beds, not six, in one afternoon; say so.
- **UI-32 (L)** is two M units in two waves (8, 9), never one.
- **SHIP-06 (M)** is S once the Settings unit owns the rows anyway.
- **CONTENT-09 (M)** collapses to strings in LOOP-30's field (C3).
- **LOOP-29 (M)** is S (CRITIC-R6).
- **SIM-04 Focus (L)**, **SIM-21 wishlists (L)**, **CONTENT-26's art (L+)**, **UI-22's re-author (XL)**, **DESIGNER-10 (a) Blacksmith (L)**, **DESIGNER-02's "XL balance pass"** — none fits; all are below the line (next section) unless the designer buys one with a name.


## Cut line

"Shippable at wave 10" means: a player installs the zip on a second machine, starts a guild, is taught by two tutorials that can be won, climbs a Tier 1 ladder that can be completed, reads a wipe report that names why, hears the stamp, and reaches an ending — with no sentence on any screen about a build, a module, a doc or an audit. Everything above the line is what that sentence needs. Everything below it is polish or post-ship, and the plan says so in a docs/15 row rather than leaving it half-built (BUILD_STATE invariant 5).

### Must land (the game is not shippable without it)

| # | What | Unit | Depends on |
|---|---|---|---|
| 1 | No player-facing string admits unbuilt work; the copy lint is green | W6-COPY, W6-SETTINGS, W10-DELETE | — |
| 2 | Sheets of a real guild (new, play, hover); every later review on them | W6-SHEETS | — |
| 3 | The drift gate armed; cascade attribution; the wipe's cause in the result | W6-SIM-CASCADE | — |
| 4 | The log and the report never cut a mistake's name or a joke | W6-LOG | — |
| 5 | The designer's page with one default per row; the naming sheet; the review page; the provenance gate | W6-PAGE | LOOP-19 (W6-LEDGER) first |
| 6 | The queue tells the truth; the twelve unrecorded rulings are rows | W6-LEDGER | — |
| 7 | The prep screen shows the party and one risk sentence | W7-PREP | — |
| 8 | The report says why it wiped, what reputation was earned, and offers Try again; the tutorials say their lesson where it happens | W7-REPORT | 3 |
| 9 | Every named mistake has its consequence; healers generate threat; the tank loses aggro (Q-57/Q-58) | W7-SIM-EFFECTS | 3 |
| 10 | The eleven hooks fire and are gated; `ui.stamp` on frame 1 | W7-AUD-BIND | — |
| 11 | One v17 save bump (pending deltas, log tail, active run); Esc mid-replay ruled; then frozen | W7-SAVE | — |
| 12 | docs/08 §8.8 publishes the one equation; docs/07/10/13 match the tree | W7-DOCS | — |
| 13 | The Tier 1 campaign completable 8/8; TR ≥ 8/20; A3 > 0; the playtest FAIL not WARN; M05/M08/M09 land on E4; attrition ruled; the Forgiving Guild lever exists | W8-SIM-BALANCE | the ruling (page back by end of 7) |
| 14 | Disband has a banner, a modal and an after-state; a stuck guild reads a sentence | W8-CRISIS | 13's ruling (the wall moves first) |
| 15 | The keyboard map does what docs/13 §13.1 says, or the row is struck | W8-KEYS | 1, 7, 8 (screens settled) |
| 16 | Tier 1 items at the register's defaults; backstories pronoun-free; tiers 2-5 named if the words came | W8-ITEMS | the words |
| 17 | The fold, the E2/E4 goldens, the ninja decision | W8-TUTOR | 9 |
| 18 | 150% on all thirteen routes with an empty allow-list | W8-SCALE-1, W9-SCALE-2 | 4 |
| 19 | Tiers 2-5 swept and mounted — OR the honest Tier-1-only ending with the switch and the row | W9-TIERS | 13, 16 |
| 20 | The corpus and the names read by a person, marks applied | W9-REVIEW | 16 (every line that will exist) |
| 21 | `EXPORT OK` (or the exact HOLD list), fresh-profile boot, zip with licences, README, credits as signed, the second-machine walk | W10-* | 5's signatures |

### Polish (ships without it, worse — lands in the order listed if the waves hold)

| What | Unit | Why it is polish |
|---|---|---|
| The fight's picture at the built scale: party spread, plate keep-out, boss forward, numbers, light mask, arena by kind | W7-STAGE | UI says every item ships at the Q01/Q02 defaults; the picture is legible today, just crowded |
| Facility tent states and the Market's first impression | W8-FACILITY | docs/02 §9's visible change; the Market hazard is one confirm away from safe |
| Bard songs (Q-46) | W9-KITS | DECIDED, but the Bard fights today at 0.55 melee; the songs are flavour on top |
| Four ambience beds | W9-AUD-AMB | silence is honest; a bed is atmosphere |
| The fallen lie down; 24px emotes; per-family silhouettes; Legendary busts | W9-ART | statues and pictograms are legible, not pretty |
| Guild name; LoadSave rail; reputation chip; Tavern card folds; wide-expand panel; numerals; the ending's lines | W9-POLISH | each S; none blocks a player |

### Deferred to post-ship — say so in a BL row in wave 6 (W6-LEDGER) so nothing is half-built

| What | Report | Why deferred | The row's text |
|---|---|---|---|
| Focus (Q-02 Model A+), M10's drain half | SIM-04, CONTENT-27, DW-C1/C2 | L; needs designer numbers; first carrier is Tier 3 | "M10 ships as Silence; Focus is post-1.0; `MANA_BURN_DRAIN_ENABLED` stays false" |
| The four PROPOSED class kits (Wizard ramp, Rogue Behind/Front, Monk Guard, Mage buff/true AoE) | SIM-10 | 🔷; four afternoons; every one moves the sweep | "docs/06 §4.6-4.8 kits are post-1.0 unless the designer names them on the page" |
| Wishlists / BiS (Q59-3), the BIG-dumb warning surface's wishlist row | SIM-21, CONTENT-19, LOOP-17 | docs/16 C3; a leaf module | "wishlists are out of 1.0 (docs/16 C3); the flag stays declared off" |
| Traits (docs/04 §10) | CRITIC-M3 | never built; PROPOSED | "traits are post-1.0; the field stays empty" |
| Upkeep / payday (Q59-5, Q-31) | DESIGNER-11 | cadence fork unruled; docs/11 has no row | "no upkeep in 1.0" (DESIGNER-11's default) |
| Legendary quirk specs (BL-58) | SIM-20, CONTENT-18, DESIGNER-14 | nine specs are the designer's; the seam ships inert | "quirks display and do nothing in 1.0" |
| S13 interstitial, S16 Codex, `nav_codex` | CRITIC-M4, SHIP-20 | BL-24; docs/16 C4 | "struck from docs/13 §5" |
| Per-tier arenas, boss recolours, icon palettes (docs/16 W3.3/W3.6) | CONTENT-26 (art half) | L+ art; one arena per kind ships | "tiers 2-5 share the two arenas and the boss set; per-tier identity is post-1.0" |
| Boss / creature / raid names (Q12a, DESIGNER-25) | LOOP C24, CONTENT-28 | docs/10 §2 forbids inventing | "placeholders ship" |
| Music (Q-B), voice bus content (Q-C), world/combat sound (Q-D) | AUDIO-09/13, DESIGNER-46 | designer's; no owner | "no music in 1.0; the Music row carries ambience" |
| Blacksmith (Q-13) | DESIGNER-10, LOOP-02 | L; default (b) | "out of 1.0; the facade stays locked with non-promise copy" |
| Town rank-states beyond the tent (M3-LOOP-06), aerial figures (M4B-ACT-04) | DESIGNER-22/24, UI-40 | designer plates | "dressings only" |
| Gamepad glyphs and rebinding; a second language; pseudolocale pass | SHIP-20, LOOP-26, docs/16 W4.8/C6 | docs/16 C6; one language | "works unverified; not a supported input" |
| Code signing | SHIP-16 | money | "unsigned; README says so" |
| Instrumentation (docs/14 §12) | CRITIC-M7 | off in release by design | "post-ship" |
| The 2x-canvas re-author of party and bosses (Q01/Q02 XL) | UI-22, DESIGNER-26/27 | XL art | "1.0 ships at 2x integer scale, 1x boss" |
| Tier 2-5 balance if the words never come | DESIGNER-02, W9-TIERS | cannot be measured on unmounted content | "Tier 1 only; Completion retimed" |

### Two things the reports put above the line that this report moves below it, with the reason

1. **Focus (SIM-04, wave 7 L).** The sim's three "resource spent" heal mistakes and M10's drain are the only consumers; SIM-07 gives the heal mistakes distinct outcomes without a pool; M10 is Tier 3. The user's "every system functional" is met by the Silence reading plus the row — a system that ships half-built behind `false` is worse than one deferred in writing.
2. **The four PROPOSED kits (SIM-10).** The nine classes function and differ (coefficients, threat, healer shapes, the tank swap, the Bard's coefficient); the ramp/positional/guard/buff are docs/06's 🔷 proposals with no DECIDED row. Q-57 and Q-58 (DECIDED) stay above the line in W7-SIM-EFFECTS; Q-46 (Bard) is polish in W9-KITS.

### One thing the reports put below the line that this report moves above it

**The Forgiving Guild toggle (CRITIC-M1).** docs/16's cut order forbids cutting it while the achievement board and Raid 5 ship; docs/00 §6.4 says the two spirals are a design flaw without it; and it is the cheapest second sweep axis the balance wave can have. M, in W8-SIM-BALANCE, with the row saying it is not the BAL-04 fix.

## Questions for the designer

Only the ones no report asked and no default covers. The seven reports' questions stand; W6-PAGE merges them into one sheet with one default each (C1).

1. **The Forgiving Guild toggle (docs/00 §6.4, docs/16 C13):** in 1.0 as the docs say (recommended — M, wave 8), or struck from the cut order in writing?
2. **Traits (docs/04 §10):** cut for 1.0 (recommended) or built (M, wave 9)?
3. **Retreat (docs/07 §3, Q-09):** confirm it is struck — the attempt is committed at Depart and "leave early" is Skip.
4. **The four PROPOSED class kits (docs/06 §4.6-4.8):** post-1.0 (recommended) or name which of the four you want in wave 9 in place of the Bard songs.
5. **If the words and names are not back by the end of wave 7:** confirm that wave 8-9 proceed on the recommended defaults and that 1.0 is Tier 1 with the ending retimed — or say the release waits.

## Coverage

**Read in full:** the seven reports (SIM 386 lines, CONTENT 350, LOOP 433, UI 645, AUDIO 219, SHIP 272, DESIGNER 569 — 235 findings); BUILD_STATE.md (all); `build/plan/audit.json` at HEAD (all 178 ids, statuses; the seven orphan entries' full text; the status diff of 106ac8d); docs/_log/progress.md WAVE 5 entry; `build/shots/_w5_args.json` (unit keys); docs/16 §11 (the cut list) and the W3/W4 rows; docs/00 §6.3-6.4; docs/01 §9; docs/04 §10; docs/13 §5 (S01-S17), §13.1 fragments, :538-546; docs/14 §12.1-12.2; docs/15 status markers; docs/07 Retreat lines; the top-level headings of docs/01/02/03/04/05/09/11/14/16.

**Verified in the tree (grep or read, 2026-09-15 ~12:40, HEAD 106ac8d):** the 24 spot-checks in Refuted; the seven orphans; `data/` listing; `sim/content/` listing; `sim/core/Reputation.gd:31/94/643`, `Recruitment.gd:38/59/370`; `game/assets/bg/`, `portraits/`, `ui/icons/` + `grid/` listings; `Icons.gd:17/27/147`; `Cards.gd:70-110`; `Widgets.gd:347-389`; `ScreenRouter.gd:193-250`; `Settings.gd` ROWS keys; `GameSettings.gd:45`; `SceneStage.gd:2295`; `RaidSim.gd` at the cited lines; `Mistakes.gd:452`; `verify.sh` stage headers and :203; `test_text_scale_layout.gd` KNOWN list; `tools/playtest.gd:57/163/207`; `handoff-W5-TOOLS.md` §2; `data/encounters_t1.json` E4 mechanics; `data/backstories.json` pronoun count; `data/tier_words.json:41`; `gen_items.gd:145/498/526`; `data/legendaries/warrior.json:16-18`; `Raider.gd:112/320`.

**Not done:** no Godot run (the mutex is wave 5's) — no number here is re-measured; the contact sheets were NOT opened by this report (the UI/LOOP/CONTENT reporters' sheet reads were taken as given and only their code claims were re-checked); docs/02/03/05/06/09/11 bodies not re-read beyond the headings and the lines the reports cite; the 13 art-plan switches (spec 00 §2.7) not re-verified — DESIGNER's grep was trusted; the remaining ~170 CONFIRMED findings not spot-checked were accepted on their file:line evidence; `build/plan/report-W5-*.md` not read (their effects were read through the close commit's diff); tiers 2-5 data, the goldens and the sweep baseline not opened; nothing in `art/ref/specs/` read.
