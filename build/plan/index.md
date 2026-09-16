
## M3 saves — remaining autosave points, the Load/Save screen, and save-format freeze readiness  (10)
- [not-/S] **M3-SAVE-01** Town-screen-transition autosave (docs/14 §7.4 row 1, docs/00 §6.2)
- [not-/S] **M3-SAVE-02** `played_seconds` is declared, saved and never incremented — every load-menu slot reads "just started"
- [not-/M] **M3-SAVE-03** Attempt-start save AFTER the master seed is drawn (docs/07 §9, docs/14 §7.4 row 3, §7.1 `active_run`)
- [not-/M] **M3-SAVE-04** The Load/Save screen — three slots, archetype C on the art-pass Frame
- [not-/S] **M3-SAVE-05** "Quit to menu" is the unwired half of docs/14 §7.4's last row — only window close saves
- [not-/M] **M3-SAVE-06** The recruit board is not persisted, so every reload re-rolls the Tavern — docs/14 §7.1's `rng_town` row, and a free-reroll exploit
- [not-/M] **M3-SAVE-07** The migration chain has never been walked: no fixture save, no registered step, `OLDEST_MIGRATABLE == SAVE_VERSION`
- [not-/M] **M3-SAVE-08** `content_version` is written into every header and never read back — `reconcile_content` does not exist
- [part/XL] **M3-SAVE-09** Save-format freeze audit (BACKLOG M6): four of docs/14 §7.1's ten blocks are absent from `to_dict()`
- [not-/S] **M3-SAVE-10** docs/14 §7.1's rank/RP corruption canary is documented and not asserted

## M3 — tuning-data extraction (docs/03 §9) and the macro loop (reputation → town → recruits)  (11)
- [not-/S] **M3-TUNE-01** Rule the tuning file's format before extracting anything — docs/03 §9 says .tres, BACKLOG says .json, docs/14 flags the conflict OPEN
- [not-/S] **M3-TUNE-02** Reconcile §9's stated schema with the shape the code actually grew — four divergences and two omissions
- [not-/M] **M3-TUNE-03** Create data/reputation.json and its loader with §9's three load assertions, proved lossless against today's constants
- [not-/M] **M3-TUNE-04** Switch Reputation.gd and Recruitment.gd to read the data file, delete the constants, re-point the tests that assert on them
- [not-/S] **M3-TUNE-05** Settle the scope boundary the backlog line opens: the doc-04-owned recruitment tables §9 does not name
- [done/S] **M3-LOOP-01** Leg 1 of the macro loop — reputation → content unlock — is already closed
- [done/S] **M3-LOOP-02** Leg 2 of the macro loop — reputation → recruit quality — is already closed, including the free reroll on rank-up
- [part/M] **M3-LOOP-03** Leg 3 is the missing one — no town building is rank-gated on the town screen, and the Blacksmith has no ladder at all
- [not-/S] **M3-LOOP-04** The Adventure's Board's levels are dead data — the ladder exists, nothing advances it, nothing reads it
- [not-/M] **M3-LOOP-05** docs/02 §9's rank → visible town change has no mechanism at all — the camp scene is the same at Unknown and at Legendary
- [bloc/L] **M3-LOOP-06** The six authored town rank-states docs/02 §9.1 asks for cannot be produced by the build loop

## M5 — Boss mechanic library (docs/10 §10 M01–M12) as implemented in sim/core/RaidSim.gd  (15)
- [not-/L] **m5-mech-roll-site** Wire the mechanic-check roll site (docs/07 §5.3b) — it is never rolled, and five mistake types are unreachable
- [done/S] **m5-m02-raid-wide-ac** M02 Raid-Wide is implemented but mitigated by AC twice — the pulse is supposed to bypass armour
- [part/M] (sim side done; Encounter.gd load rejection + data cleanup handed off, build/plan/handoff-sim.md) **m5-m04-double-spawn** M04 Add Spawns double-spawns: the m04 mechanic and the authored spawn_round enemy block both fire on the same round
- [not-/M] **m5-add-target-priority** Adds are never focused: raider targeting returns the first enemy in array order, so m04 adds are only attacked after the boss dies
- [not-/M] **m5-m01-tank-swap** M01 Tank Swap is absent from the sim — it is configured on E3, E5 and Adventure A3 and does nothing
- [part/M] **m5-m03-ground-effect** M03 Avoidable Ground Effect is a stub: the tick loop exists but nothing ever puts a raider in the fire, and escape_chance_bp is unread
- [part/M] **m5-m05-interrupt-check** M05 Interrupt Check is a stub: it sets one context flag and has no cast, no position test and no effect
- [not-/M] **m5-m08-fixate** M08 Fixate is absent — it is configured on t1_raid_e4 and does nothing
- [not-/M] **m5-m09-healing-debuff** M09 Healing Debuff is absent — it is configured on t1_raid_e4 and does nothing
- [not-/M] **m5-m07-positioning** M07 Positioning Requirement is absent, and the position model it needs is an undecided open question
- [not-/M] **m5-m10-mana-burn** M10 Mana Burn is absent, and half of it has no resource to burn — the Focus pool from docs/15 Q-02 was never built
- [not-/S] **m5-m11-frontal-cleave** M11 Frontal Cleave is absent — the simplest of the twelve, and the melee predicate it needs already exists
- [not-/S] **m5-m12-escalating-swing** M12 Escalating Swing is absent — a five-line arm next to the ENRAGE branch
- [done/S] **m5-mechanic-dispatch-guard** Add a guard test that every Enums.Mechanic entry has a dispatch branch — the match in _apply_scheduled_mechanics silently skips nine of twelve
- [part/M] **m5-token-effects-and-cascade** docs/07 §6 token effects and cascade attribution are not wired — mechanics cannot invite the mistakes they are supposed to

## M5 — quest/achievement board and the endgame after Raid 5  (11)
- [not-/M] **M5-QAB-1** Achievement engine: sim/core/Achievements.gd + data/achievements.json + the record_attempt hook
- [not-/M] **M5-QAB-2** The ~40 achievement records themselves — conditions, names and the comedy pass
- [not-/M] **M5-QAB-3** S14 — the Records tab in the Guildhall, currently a disabled button
- [bloc/S] **M5-QAB-4** The reputation reward kind is an unpropagated ruling — doc 03 never accepted the faucet
- [not-/S] **M5-QAB-5** The ~15% caps have no denominator — no lifetime-income or lifetime-RP counter exists
- [not-/M] **M5-END-1** Completion state on the first clear of Raid 5 Encounter 5 — Q-88's answer is DECIDED, not open
- [not-/M] **M5-END-2** S17 — Completion / credits: the screen doc 10 assigns to doc 13, and doc 13 never gained
- [part/M] **M5-END-3** The completion phase itself: the three post-clear activities need surfaces, and two of the three already work
- [bloc/S] **M5-END-4** Credits content — who the game credits
- [bloc/S] **M5-END-5** docs/10 §13 row 3 — the Legendary 5% find rate at a rank with no content left to serve
- [part/S] **M5-OQ-1** docs/15 sweep: the questions still marked OPEN, and three rows that have gone stale

## M5 content breadth — Tiers 2-5 (item scaling generator, Raids/Adventures 2-5, and the doc-08 fact that decides which)  (14)
- [not-/L] **M5-T25-01** docs/08 §9 stops at Tier 1 — publish a §9.6 Tier 2-5 boss budget before any encounter is authored
- [not-/M] **M5-T25-02** Tier 1's shipped boss numbers are stale against docs/08 §9.2/§9.3 — reconcile before extending the curve
- [not-/M] **M5-T25-03** AC_K and MANA_TO_SPELL are flat consts — the mitigation cap binds from tier 3 and casters run away
- [not-/M] **M5-T25-04** ContentDB cannot hold more than one tier: the encounter index and raid tables are keyed by slot/class, not by tier
- [not-/L] **M5-T25-05** Tier scaling generator — tools/gen_items.gd + sim/content/TierScaling.gd, producing 8 data files
- [not-/M] **M5-T25-06** The generator's invariant test — formalise 'no tier inverts power' as five separate assertions
- [not-/L] **M5-T25-07** The 85 hand-authored exceptions — capstones, Raid charms and Adventure charms for tiers 2-5
- [bloc/S] **M5-T25-08** Tier 2-5 material and title words — the designer must name them; nothing autonomous can close it
- [not-/L] **M5-T25-09** Raids 2-5 — 20 encounter records, numbers derived, mechanics and comedy hand-authored
- [not-/M] **M5-T25-10** Adventures 2-5 — 12 encounter records at the A1/A2/A3 shape, sized at each rung's own gear stage
- [part/M] **M5-T25-11** Tier-aware encounter validator — the escalation rule and the coverage rule are enforced for Tier 1 only
- [part/L] **M5-T25-12** Seven of the twelve mechanics have no behaviour in RaidSim, including three already shipped in Tier 1 data
- [not-/S] **M5-T25-13** Q-43 — Warrior/Bard Mana variants are 'Tier 2+ intent' and must be a generator rule, not an afterthought
- [not-/S] **M5-T25-14** Q-35 — the Adventure rung has no off-hands, so the generator's per-rung template is ambiguous (27 vs 28 items)

## M3 — Legendary quirks (Q-58) and the five BIG-dumb conditions (Q-59)  (10)
- [bloc/L] **Q58-1** docs/07 does not spec the nine Legendary quirks at all — this is a missing SPEC, not missing code
- [not-/S] **Q58-2** Which doc owns the quirk spec is ambiguous — docs/04's own cross-reference points at a filename that does not exist
- [bloc/L] **Q58-3** Five of the nine quirks name mechanics the sim does not have — the substrate audit the spec pass needs first
- [not-/M] **Q58-4** The inert-quirk seam: nothing loads, carries or dispatches a quirk today — build the plumbing behind a flag so the spec pass is a data change
- [part/M] **Q59-0** BIG-dumb condition #1 is NOT live: nothing anywhere increments `consecutive_benched`, so `big_dumb_active` can never become true in play
- [not-/M] **Q59-2** BIG-dumb condition #2 — the per-boss wipe streak counter does not exist (`attempts` counts totals, not runs-in-a-row-with-this-raider)
- [not-/L] **Q59-3** BIG-dumb condition #3 — wishlists are a declared-but-unbuilt module: the field and all four morale triggers exist, the generator and the insult counter do not
- [not-/M] **Q59-4** BIG-dumb condition #4 — per-tier backstory-trigger counts have no scope to live in; the morale ledger caps per tick/session/ever/window, never per tier
- [bloc/L] **Q59-5** BIG-dumb condition #5 — upkeep and payday do not exist in code OR in the doc that owns them; Q-31 says 'per-run' while §11.3 says 'payday'
- [not-/M] **Q59-6** docs/04 §11.4's warning surface is unbuilt — `big_dumb_active` is computed and saved but never shown to the player

## M5 comedy content — the mistake log-line writing pass  (13)
- [done/M] **M5-COMEDY-01** The mistake log entry carries no template key, so no line can ever be looked up
- [not-/M] **M5-COMEDY-02** There is no mistake-line corpus and no loader: the exact data shape the writing pass fills
- [not-/L] **M5-COMEDY-03** The writing pass: 192 lines across 18 types, with a measured per-type budget, not the doc's flat 6
- [not-/M] **M5-COMEDY-04** Legendaries get their own mistake variants — the second half of rule 4, unwritten
- [bloc/M] (render path + tests done; blocked on M5-COMEDY-02/03 for a corpus, so NOT done) **M5-COMEDY-05** The joke line is never rendered anywhere: RaidView's branch is dead, describe() and Results omit it entirely
- [done/S] **M5-COMEDY-06** Severity is written as a Name and read as a key, so the comedy brake is dead and the mistake header prints '?'
- [not-/S] **M5-COMEDY-07** docs/14 §5.4 assertion 7 (every type has ≥6 templates) is not implemented anywhere
- [not-/M] **M5-COMEDY-08** The test that catches a repeat — tests/unit/test_mistake_lines.gd
- [not-/M] **M5-COMEDY-09** Six of the eighteen mistake types never fire in any golden, so a third of the corpus ships unexercised
- [not-/M] **M5-COMEDY-10** docs/07 §5.5's log-collapse guard is unimplemented, so identical Minor mistakes still stack as separate lines
- [part/S] **M5-COMEDY-11** Encounter comedy_line: 8 of 42 authored, and the three gates that check them disagree with each other and with the doc
- [bloc/S] **M5-COMEDY-12** 'Genuinely funny' cannot be self-certified: the comedy corpus needs a human review gate
- [not-/S] **M5-COMEDY-13** Record the two rulings this pass makes: the line budget above the doc floor, and one file instead of eighteen

## M6 polish — audio, juice, accessibility  (21)
- [not-/M] **M6-AUD-01** There is no audio subsystem at all: no bus layout, no Audio autoload, no player nodes
- [not-/M] **M6-AUD-02** GameSettings' four audio keys are dead: nothing reads them, and only one of the four has a Settings row
- [not-/L] **M6-AUD-03** Procedural SFX generator for docs/13 §12.4's eleven UI hooks — no sample exists and none can be sourced
- [not-/M] **M6-AUD-04** Bind the eleven §12.4 hooks to their actual trigger sites
- [bloc/L] **M6-AUD-05** Music beds, the per-rank town soundscape and the Legendary leitmotif — assign an owner, then compose
- [not-/S] **M6-AUD-06** Audio has no numbered decision in docs/15 — it is an unnumbered ownership gap, so no ruling is load-bearing
- [done/S] **M6-JUICE-01** Hover states are DONE — Theme.gd ships a per-variation hover stylebox for every button family
- [bloc/M] **M6-JUICE-02** docs/13 §12.2's motion table vs M5 'the desk does not move' is an unresolved contradiction — no transition can be built until it is ruled
- [part/M] **M6-JUICE-03** The §11.4 wipe sequence is one beat out of six: only the WIPE stamp lands, at the wrong time, with no press, bleed, dim or seal
- [bloc/S] **M6-JUICE-04** BACKLOG's 'screen shake on wipes' contradicts docs/13 and must not be built
- [not-/M] **M6-JUICE-05** Damage numbers: the type tokens exist, the renderer does not, and the reference's own '-842' was painted out of the plate
- [part/M] **M6-JUICE-06** reduced_motion has exactly one consumer and no enforcement — every new tween in M6 will silently ignore it
- [not-/M] **M6-JUICE-07** The §12.1 latency budget is specified as a perf test and no perf test exists
- [not-/XL] **M6-A11Y-01** docs/13 §13.1's keyboard map does not exist: zero input handlers and zero InputMap actions in the entire project
- [not-/L] **M6-A11Y-02** No screen sets an initial focus, a focus neighbour, or a focus group — Tab order is accidental tree order
- [part/S] **M6-A11Y-03** The focus ring is 1px inside the bounds instead of 2px outside, and LinkButton has no focus indicator at all
- [part/M] **M6-A11Y-04** emoji_free is honoured on exactly one of nine morale-glyph sites
- [not-/L] **M6-A11Y-05** text_scale is presented as a live setting and consumed by nothing — the Theme is a cached singleton built from raw Type constants
- [bloc/L] **M6-A11Y-06** Palette.band_color is a 3-step red/amber/green ramp — the exact axis docs/13 §8.3 rejects as CVD-unsafe — and no CVD verification exists anywhere
- [not-/M] **M6-A11Y-07** The combat-log badge is hue-only: an 18px coloured disc with no glyph, no icon and nothing in the row's text naming its class
- [part/S] **M6-A11Y-08** The Tavern recruit card shows a morale number and glyph with no state word — three of §13's four channels, not four

## M4 art tail — class glyphs, provision icons, the diff loop, and the remaining placeholders  (13)
- [part/M] **m4t-01** Author the nine class glyphs (8 missing) and give them a generator
- [not-/M] **m4t-02** Wire the class glyph into the class row — today nothing loads it
- [part/M] **m4t-03** Three of the six provision icons are missing (whetstone, mana draught, guild feast)
- [not-/M] **m4t-04** No screen loads any provision icon — the shelves and the chalkboard are text-only
- [done/S] **m4t-05** Page arrows: already drawn and already wired — backlog line is stale
- [not-/L] **m4t-06** Replace the whole-screen diff verdict with region-masked per-component scoring
- [not-/M] **m4t-07** Define and build the expand-mode wide-screen check
- [part/M] **m4t-08** The art gate scores 3 targets; 11 screens are on the frame
- [part/M] **m4t-09** The seven event-badge glyphs exist but the real event log never uses them
- [part/M] **m4t-10** Facilities' before/after exterior thumbnails are still a sentence of text
- [part/M] **m4t-11** Results' full-bleed arena plate (raid_void.png) is referenced but does not exist
- [part/M] **m4t-12** The guildhall living scene is authored but no shipping screen plays it
- [done/S] **m4t-13** Three 'until the art exists' comments are now false and will mislead the next loop

## M5 tutorials — Adventure 0 and the Tutorial Raid (docs/10 §9)  (15)
- [not-/M] **M5-TUT-01** Author data/encounters_tutorial_t1.json — A0 and TR, with HP re-derived off docs/08 §9.1a stage 0
- [not-/S] **M5-TUT-02** The encounter validator refuses Adventure 0 as docs specifies it — 'no mechanics' vs one-mechanic-per-star
- [not-/S] **M5-TUT-03** ContentDB must load and index the tutorial file and expose tutorial_encounters()
- [not-/S] **M5-TUT-04** Author the two crap trinkets from docs/09 §10.2 — not docs/10 §9.2's names or stats
- [part/M] **M5-TUT-05** Loot: tutorials pay 0 gold and can drop nothing — add the payout rows and the guaranteed, once-only trinket
- [part/M] **M5-TUT-06** The board must list the tutorial rungs, gate the ladder on 'resolved' not 'cleared', and offer skip-with-warning
- [not-/S] **M5-TUT-07** GameState needs skip state, a rung_resolved() predicate, and a save-version bump
- [not-/S] **M5-TUT-08** Set onboarding_complete when both tutorials are resolved — nothing writes it today
- [part/XL] **M5-TUT-09** Arming disband exposes docs/05 §6.3's warning guarantees, none of which are built
- [not-/L] **M5-TUT-10** M01 Tank Swap is declared and inert — it is the Tutorial Raid's entire teaching payload
- [not-/S] **M5-TUT-11** Tutorials must run the mistake system at a reduced rate with Facepull and Ninja-Pull disabled
- [not-/M] **M5-TUT-12** Adventure 0's scripted round-3 mistake (force_mistake_round) does not exist in the encounter model or the sim
- [not-/S] **M5-TUT-13** tanks_required: 0 silently becomes 2, and two docs disagree on Adventure 0's tank count
- [not-/S] **M5-TUT-14** The milestone loop test presses 'A1' and will break the moment tutorials sit ahead of it
- [done/S] **M5-TUT-15** Tutorial reputation is already fully built — BACKLOG.md's open line is stale for this part

## Discovered work (BACKLOG.md bottom section) — doc/math integrity  (11)
- [not-/M] **DW-A1** Dead relative doc links: 37 distinct bad targets, 91 occurrences across 8 docs
- [not-/S] **DW-A2** Nine dead in-document anchors in docs/15 (`#q-31`, `#q-34`, `#q-44`, `#q-50`, `#q-54`, `#q-38`, and one empty `](#)`)
- [not-/M] **DW-A3** docs/15 reuses Q-19..Q-59 for two entirely different decision sets — 41 colliding IDs, cited 141 times from code
- [not-/S] **DW-A4** docs/03:30 names `docs/00-index.md` as the authoritative filename index; no such file exists
- [done/S] **DW-B1** AC Reading 3 is already the shipped default and all four readings are enumerated — the backlog item is stale; only the docs/15 and docs/08 records are missing
- [part/S] **DW-B2** The AC_READING switch is not actually selectable: `mitigation()` returns 0.0 for both flat readings while callers use it directly
- [not-/L] **DW-C1** Focus does not exist in the simulation: Model A+ is declared by a comment and an enum label, and nothing spends it
- [not-/M] **DW-C2** Docs 06, 07 and 09 still publish the pre-Model-A+ Mana answers; docs/07 spends a Mana pool no document defines
- [part/M] **DW-D1** Mistakes.gd implements docs/05 §5.1-5.4, not docs/08 §8.8 — the backlog item states the resolution backwards, and docs/08 §8.8 still publishes the superseded equation as live
- [not-/M] **DW-D2** docs/05 still restates the mistake equation and claims ownership; docs/03 §4.2 and docs/02/04 worked examples still print three more rival coefficient sets
- [done/S] **DW-E1** Head-family asymmetry is resolved and shipped — `warrior_head` never existed in the current Enums.gd; only docs/09 §4.4 still says OPEN

## M6 ship-readiness (export, playtest sweep, balance pass 2, README/final pass, save freeze)  (16)
- [not-/S] **M6-EXP-01** export_presets.cfg — the Windows Desktop x86_64 preset does not exist
- [not-/M] **M6-EXP-02** tools/export_build.sh — the release export script and the exported-.exe launch check
- [part/S] **M6-EXP-03** .gdignore coverage is 3 of 6 — Aseprite/, build/ and docs/ are still importable, and build/ alone is 75 MB of scratch PNGs already in the import DB
- [not-/S] **M6-EXP-04** project.godot points config/icon at res://icon.svg, which does not exist
- [not-/S] **M6-EXP-05** docs/14 §10.1's pre-export gate list names five tools that do not exist in this project — reconcile it in docs/15 rather than silently dropping the gates
- [part/L] **M6-PLAY-01** Playtest sweep — no campaign-level harness exists; the existing gate walks A1 only
- [not-/M] **M6-PLAY-02** No invariant asserts the campaign cannot reach an unrecoverable state (roster below party size with no way to buy one back)
- [part/S] **M6-BAL-01** The balance sweep never sweeps the Adventure rungs A1-A3, which are the on-ramp the whole campaign stands on
- [part/L] **M6-BAL-02** The sweep report is missing most of docs/14 §9.3's specified shape, and there is no committed baseline for the >5pp drift gate
- [bloc/XL] **M6-BAL-03** Balance pass 2 as written cannot be done — the target clear-rate curve is documented nowhere, and 'all tiers' needs content that does not exist
- [not-/S] **M6-DOC-01** README.md at repo root — does not exist; four docs cite it as the place three specific facts live
- [done/S] **M6-FINAL-01** "Resolve remaining TODOs" — there are none; this half of the final-pass item is already true
- [not-/S] **M6-FINAL-02** Dead code — the audit finds exactly one provably unreferenced file, tools/probe/diag.gd
- [part/M] **M6-FINAL-03** BUILD_STATE.md is stale at the top and past its own length rule — it still says the milestone is M4
- [not-/S] **M6-FINAL-04** docs/08 has ten dead cross-references — BACKLOG already files this under M6 polish
- [part/M] **M6-SAVE-01** Save-format freeze + migration test — the chain exists and is walked, but no migration has ever run and no fixture save is committed
