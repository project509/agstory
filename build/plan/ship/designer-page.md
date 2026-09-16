# The designer's page — every open question, one default each

_Written 2026-09-15 by W6-LEDGER at the close of wave 6, against the tree as it stands then (a Common recruit costs 15 G; docs/15 runs to BL-106 and Q-99; the audit queue is 120 done / 53 open / 17 blocked on this page). Source: `build/plan/ship/00-plan.md` §6 — its 67 rows, in the order DESIGNER.md asked them (wave 6 → wave 7 → wave 8 → any time), then the questions the other six reports and CRITIC raised. The question text is the plan's; the answer lines for rows #1-#48 are DESIGNER.md's own, verbatim._

## How to answer this page

- **One line per row is enough.** "As built", "take the default" or a bare number is a complete answer. Reply on this page (edit the answer line) or in any file; the loop propagates every answer through the unit each row names, strikes the docs/15 row, flips the switch or confirms it, and moves the pin test in the same commit (docs/15 §2.2).
- **Every row carries the ship default the loop takes if the row is unanswered by the wave it names.** That is the wave-10 ship rule (BUILD_STATE, Current focus): the default is taken by the unit named, in writing — a docs/15 row marked "taken under the wave-10 ship rule" — never silently. An answer that keeps the default costs nothing; a flip is the S/M unit the row names.
- **Rows marked ★ have no autonomous fallback that reaches a store.** With them unanswered the game ships to your own machine with the README saying so.
- **What the game looks like at wave 10 with zero answers:** Tier 1 only (S17 fires on the Raid 1 clear), A1-A3 and the tutorials re-sized for morale 45 by docs/08 §9.3's formula, eight Legendaries unfindable, no Blacksmith, no upkeep, no board reputation, quirks inert, no music (ambience only), the reference morale ramp with a colour-safe option, credits with one blank line, and the two content-review gates unpassed in writing. It ships; it is a smaller and less certain game than one answer per row would make it.
- **Nothing on this page was decidable by the loop.** Each row names a canon number, a canon-adjacent name, a doc-versus-doc conflict, a legal signature, or a taste call. What the loop could take, it took — behind switches, recorded in docs/15 BL-82..106 — and those rows are not here.

---

## A. Answer by the end of wave 6 — shipping

The build cannot leave the tree without these; everything in waves 7-9 is measured against a completable Tier 1 with named tiers.

### #1 · DESIGNER-01 / M6-BAL-04 / SIM-19 / CONTENT-08 / LOOP q2 — THE decision: a new guild is pinned at morale 45 and the on-ramp is a wall there

**The question:** which lever moves so a new guild can climb the on-ramp — (a) Common baseline −5 → 0, (b) first facility at start, (c) size A1-A3 and the tutorials for 45, (d) smaller wipe delta — and the number. Measured: `tools/playtest.gd` walks Tier 1 and 0 of 8 guilds clear it — six stop at A2, two at A1, all in full Tier 1 Adventure gear at morale 45 after five attempts; a facility-tier-0 Common roster rests to 45 (`Morale.RARITY_OFFSET[0] = −5`, docs/05 §8's drift stops dead at baseline) and never above. Every lever changes a shipped canon-derived number, so the loop may not pick one. The arithmetic below is at the shipped recruit price (a Common is 15 G; the 60 G purse buys four).

**Needed by:** the end of wave 7 (W8-SIM-BALANCE is the balance wave).

**Default:** **(c) — size A1-A3 and the two tutorials for morale 45**, as DESIGNER-01 states it ("the only lever that leaves the morale number meaning the same thing to the player, and docs/08 §9 is already the instrument; A3's pinned 0/24 and the Tutorial Raid's 1/20 are the same pass — do not split the difference"), derived by CONTENT-08's mechanism as HOW: price the boss swing WITH the mechanic — `boss_auto_raw = tank_max_hp / (TANK_DEATH_CLOCK × (1 − mit) × M01_factor)`, `M01_factor` the expected stack multiplier over the swap cadence (~1.5 for swap_at 3 at 50%), applied ONLY where m01 is authored — behind `Formulas.SWING_PRICES_MECHANICS`, so TR and A3 move by formula, not by hand, and E3/E5 move only if the switch is on for them. Applied by W8-SIM-BALANCE: the three Adventure rows and the two tutorial rows re-derived at each rung's own gear stage, `test_adventures.gd` / `test_tutorials.gd` re-pinned in the same commit (`> 0.0`, `>= 8`), `--rebaseline` with the numbers in the commit, verify stage 7 flipped from WARN to FAIL, a docs/15 row "taken under the wave-10 ship rule".

**The one alternative (SIM-19's):** **(a) at 0** — `Morale.RARITY_OFFSET[COMMON]` −5 → 0, so a new guild rests to 50 (Content, 24%) instead of 45 (29.8%): "the smallest edit, fixes the ceiling rather than the slope, keeps every encounter number canon" — PLUS (c) for A3 only (drop M03 from A3 or halve its `damage_per_round`), because A3 at 0/24 is a separate wall that (a) does not open. Cost: every band reading in docs/05 §8 and the morale chart's scale shift; the "Commons are hardest to keep happy" canon line is weakened at the start only. One number, one file. (Levers (b) and (d) are costed in SIM-19 and in audit `M6-BAL-04`; neither alone crosses the 50 line.)

**Answer line:** "BAL-04: lever ___ (a/b/c/d), number ___."

### #2 · DESIGNER-02 / BL-69 / CONTENT-04 / SHIP-04 / SHIP q3 — the twenty tier words

**The question:** the twenty tier words (material / cloth / healer / raid_title / raid_adj × T2-T5) and whether leather keeps its own column. Until they land, tiers 2-5 do not mount (`ContentDB.tier_is_named()`) and the export holds on 16 `name_pending` files. **The naming sheet is section E below.**

**Needed by:** the end of wave 7 (wave 9 at the latest for W9-TIERS's long branch; wave 10's buffer otherwise).

**Default:** none is inventable (docs/10 §2, BL-69) — **Tier 1 only ships**: S17 fires on the Raid 1 clear, the campaign ends where the named content ends, the pending files move to `data/_pending/` so the export gate clears honestly, a docs/15 row and a README line say so. Applied by W8-ITEMS (the words, if they come) · W9-TIERS (the branch) · W10-BUFFER (late).

**Answer line:** "T2: material/cloth/healer/raid_title/raid_adj = _/_/_/_/_; T3 …; T4 …; T5 …; leather: shares material | own word ___."

### #3 ★ · DESIGNER-03 / CONTENT-17 / CONTENT q2 — the eight Legendary names; is "Natsuna" final

**The question:** the eight Legendary names — Warrior, Cleric, Druid, Mage, Wizard, Rogue, Monk, Bard — one given name each (docs/04 §7's rule: given names only, no surnames, no public figures, nobody on the team) — and yes/no on Natsuna (Shaman), whose canon hedges ("IE Natsuna(the shaman) or something"). Each file already draws the character the name should fit; **the pronoun each file already uses is in section E.**

**Needed by:** with #2.

**Default:** unfindable — `name_pending` Legendaries never appear on the board (one guard in `sim/core/Recruitment.gd`), the 9-of-9 meter reads N-of-named, the eight files move to `data/legendaries/_pending/`; Natsuna ships. Applied by W8-ITEMS.

**Answer line:** "Warrior ___, Cleric ___, Druid ___, Mage ___, Wizard ___, Rogue ___, Monk ___, Bard ___; Natsuna final: yes/no."

### #4 ★ · DESIGNER-04 / Q-21 / SHIP-17 / SHIP q2 — provenance of the reference art

**The question:** are the nine ideaboard screenshots and the six bare plates your own work, and under what terms may they ship? docs/15 Q-21: "a thirty-second answer with an unbounded downside" — the legal gate on the whole item corpus.

**Needed by:** the end of wave 9.

**Default:** the gate holds — `tools/export_build.sh` step 0 holds on an unsigned `PROVENANCE.md` (W6-SHEETS); `--dev` ships to your own machine and stamps the build NOT SHIPPABLE; the README states "provenance unconfirmed". The one row with no autonomous fallback that reaches a store. Applied by W6-SHEETS (the gate) · W10-EXPORT (the verdict) · W10-CREDITS (the row). Signing is one line per asset family in `PROVENANCE.md`: `Signed: <name> <date>`.

**Answer line:** "Q-21: the nine ideaboard screenshots are my own work — yes / no."

### #5 ★ · DESIGNER-05 / M5-END-4 / SHIP q1 / UI q3 — who the game credits

**The question:** who the game credits (names, roles); approve the drafted attribution block; the copyright holder and the version string. The derivable block is drafted in `data/credits.json` `lines`: Godot Engine (MIT), Fira Sans (OFL 1.1), Grenze Gotisch (OFL 1.1), "Sound: generated from physical models, tools/audio (this project)" — every shipped sample is generated in-tree, nothing was sourced, so no third-party audio notice is owed. The one `[designer credit pending]` line is a marker the ending never prints.

**Needed by:** the end of wave 9.

**Default:** the derivable block under "Credits" with no names; copyright "holder pending" in the README; version 1.0.0. Applied by W6-LEDGER (the draft, done) · W10-CREDITS · W10-EXPORT.

**Answer line:** "Credits: [name] — [role]; …; attribution block: approved."

### #6 · DESIGNER-06 / Q-53 / SHIP q4 / UI q5 — attempts and quitting mid-sim: confirm as built

**The question:** attempts unlimited and the attempt committed before playback — confirm; Esc mid-replay skips to the report; reload after a mid-replay quit lands on Results; "Try again" on the wipe page. As built: the attempt is resolved and recorded before RaidView plays a line (`RaidView.gd:386`), so nothing mid-account can discard or reroll; attempts are unlimited; `RaidView.EXITS_GATED = false`. docs/15 Q-53 now carries "default taken, as built".

**Needed by:** wave 7.

**Default:** as built + the three recommendations — `Results.TRY_AGAIN = true`; Esc → the post-mortem, never back to prep; Continue after a mid-replay quit → Results by re-running the stored seed (`active_run`, one of W7-SAVE's v17 blocks). Applied by W7-REPORT · W7-SAVE; the doc propagation (01 OQ-6, 07 OQ-5/6) by W7-DOCS.

**Answer line:** "Q-53: confirm as built."

### #8 · DESIGNER-08 / BL-53 / M5-COMEDY-12 / CONTENT-16/21 / CONTENT q9 — the two human reads

**The question:** the two human content-review gates: sign the name pool (docs/15 BL-53: "ONE NAMED REVIEWER passes the mundane pool"); the comedy — sign / rewrite lines / cut lines (192 type lines + 36 legendary lines + 42 encounter lines, docs/07 §10.3's five rules); who reads and when. Every checkable rule is machine-checked (BL-80's budgets, the writing-rule validator); "genuinely funny" is the one thing a loop cannot tick.

**Needed by:** the page at wave 9's close; marks by wave 10.

**Default:** ships as validated with a docs/15 row stating the human gate was not passed — the risk accepted in writing. W9-REVIEW puts every line that will ever exist on one page with a tick column so the read is twenty minutes; W10-BUFFER applies the marks.

**Answer line:** "Names: signed. Comedy: signed / rewrite ___ / cut ___."

### #9 · DESIGNER-09 / M6-BAL-03 / SIM q2, q9 — the target clear-rate curve, and TR's swing versus M01

**The question:** the target clear-rate curve (one first-clear rate per encounter at the gear stage it is fought in: A1 A2 A3 TR E1-E5, ± a tolerance) — written nowhere, and every balance pass after wave 6 tunes to it; and TR's swing and M01 on a one-tank party — keep `RaidSim.TANK_SWAP_NEEDS_A_PARTNER` true (M01 needs a partner and says so; docs/15 BL-85), replace A3's M01 with M04? Both pins trace to canon pricing a boss swing against the autoattack and then adding M01 (×2.5 at the swap threshold); the 0.5 tutorial mistake rate moved TR's pin from 0/20 to 1/20 (BL-91), so a re-pricing should be done at the reduced rate.

**Needed by:** the end of wave 7.

**Default:** the proposed curve — 100 / 100 / 100 / 100 / 75 clears at Common / raid_entry / 55 for the raid; A1-A3 / TR ≥ 75 / 60 / 40 / 40 — written into the sweep baseline's header and a docs/15 row; the switch stays true; A3 sized by #1's formula rather than swapped. Applied by W8-SIM-BALANCE.

**Answer line:** "Curve: A1 __ A2 __ A3 __ TR __ E1-E5 __ (±__); or 'take the proposed'."

### #10 · DESIGNER-10 / Q-13 / LOOP-02 / UI-01 / CRITIC-C4 — is the Blacksmith in 1.0; the callout's copy

**The question:** is the Blacksmith in 1.0 (upgrades-only, +1..+3 per building level — an L unit) or out; and the callout's copy. "Under construction." was your own edit and reads as a promise; the hotspot pointed at a scene that does not exist; two reputation-rank unlock strings promised the building.

**Needed by:** the end of wave 6 (the copy) — the building sizes wave 8.

**Default:** (b) out — the callout reads an in-world non-promise (the loop's: "Closed. The smith took a better offer." — or your line), the two unlock strings drop the Blacksmith, the flag stays declared off, the facade stays locked. Applied by W6-COPY (done this wave). If (a): one L unit in wave 8's conditional slot and the copy flips back to the blurb.

**Answer line:** "Q-13: Blacksmith in 1.0 yes (upgrades-only) / no; callout copy: ___."

### #43 · DESIGNER-43 / M6-JUICE-04 — strike "screen shake on wipes": confirm

**The question:** BACKLOG's "screen shake on wipes" contradicts docs/13 §11.4 ("no red flash…"), §12.2 ("nothing in the UI loops, pulses, or breathes") and §13 (reduced flashing unconditional); the canon-compatible beat is the stamp press + 12% dim (M6-JUICE-03, built). The loop may not overrule a doc's tonal ruling on its own authority, so this is a one-word confirmation.

**Needed by:** wave 6.

**Default:** struck — the line is struck from BACKLOG with the citation (done this wave; audit `M6-JUICE-04` stays blocked until your word lands). Applied by W6-LEDGER.

**Answer line:** "JUICE-04: strike."

### #44 · DESIGNER-44 / spec 00 §4 / SHIP q5 — aspect and first-launch window

**The question:** aspect — keep (letterbox) default, expand as the option, as built; fullscreen borderless on first launch (on a 1366×768 laptop the windowed 1536×1024 put the commit row off-screen).

**Needed by:** wave 6.

**Default:** as built; borderless fullscreen as the first-launch default, a Borderless/Windowed row and a live V-sync row on Options (W6-SETTINGS, this wave). Applied by W6-SETTINGS.

**Answer line:** "Aspect: keep default (as built)."

### #50 · CRITIC q2 / CRITIC-M3 — traits (docs/04 §10): cut for 1.0 or built

**The question:** docs/04 §10's six mechanical traits (`slow_learner`, `clutch`, `expensive`, `cheap_date`, `fragile_ego`, `iron_stomach`, 0-2 per raider) have a serialised field on the raider and nothing else — no generation, no effect, no card row; they are on no cut list.

**Needed by:** wave 6.

**Default:** cut for 1.0; the field stays serialised and empty; docs/15 BL-96 records it. If "yes": M in wave 9 (Recruitment rolls them, Mistakes / cost / Comfort / the backstory weights read them, one card line). Applied by W6-LEDGER (the row, done) · §7.

**Answer line:** "Traits: cut for 1.0 | build them."

### #51 · CRITIC q3 / CRITIC-M2 — Retreat: confirm it is struck

**The question:** docs/07 §3 says Retreat is "always available" and docs/15 Q-09 calls it "the sole exception"; the tree has no button and no outcome, and cannot have one — the attempt is committed at Depart (Q-53's reading), so "abandon at a phase boundary" would need an incremental sim. Leaving early is Skip.

**Needed by:** wave 6.

**Default:** struck — docs/15 BL-95 records it; W7-DOCS amends docs/07 §3 / §7.3 and docs/01 §6. Applied by W6-LEDGER (the row, done) · W7-DOCS.

**Answer line:** "Retreat: struck (confirm) | keep as a whole-attempt 'don't go' at the prep board."

### #54 · SIM q3 / SIM-04 / DW-C1 / CONTENT-27 — Focus (Q-02 Model A+): the numbers, or post-1.0

**The question:** Focus — `focus_max` and `focus_per_cast` per class, and what an empty pool does — or post-1.0. Q-02 chose Model A+ (Mana a magnitude, Focus a class-fixed pool that never appears on gear); no pool exists, and M10's drain half and the three "resource still spent" heal mistakes have nothing to spend.

**Needed by:** the end of wave 6 (else post-1.0).

**Default:** post-1.0 — M10 ships as Silence; `RaidSim.MANA_BURN_DRAIN_ENABLED` and `Formulas.FOCUS_ENABLED` stay false; the heal mistakes get distinct outcomes without a pool (W7-SIM-EFFECTS); docs/15 BL-87; W7-DOCS amends docs/10 §10. Applied by W7-DOCS · §7.

**Answer line:** "Focus: post-1.0 | in 1.0 — focus_max per class ___, focus_per_cast ___, empty pool: ___."

### #58 · CONTENT q5 / CONTENT-12 / SIM-15 — MIS_NINJAPULL: build a break phase, or cut the type

**The question:** one of the 18 mistake types can never fire — the sim has no break phase, so `break_phase` is never true and MIS_NINJAPULL's eight lines are dead by construction. Build a break-phase roll at Depart so the type can fire, or cut the type and its eight lines?

**Needed by:** the end of wave 6 (else cut).

**Default:** cut — the type flagged unreachable in wave 7 (`Mistakes.NINJAPULL_REACHABLE = false`), the eight lines deleted in wave 9's review, a docs/15 row. Applied by W7-SIM-EFFECTS · W9-REVIEW · §7.

**Answer line:** "NINJAPULL: cut | build the break-phase roll at Depart."

### #59 · CONTENT q7 / CONTENT-19 / Q59-3 / SIM-21 / LOOP-17 — wishlists: out of 1.0 or in

**The question:** wishlists are a declared, flagged-off module (docs/16 C3 sanctions the cut); RaiderDetail printed "wishlists with the loot module" to the player; the BIG-dumb condition that reads them is inert.

**Needed by:** wave 6.

**Default:** out — docs/15 BL-98; the flag stays declared off; the sentence hidden (W6-COPY, this wave). Applied by W6-LEDGER (the row, done) · W6-COPY · §7.

**Answer line:** "Wishlists: out of 1.0 | in (docs/05 §11's rules signed first)."

### #61 · LOOP q10 / LOOP-12 / CRITIC-C12 — the wipe's culprit rule, and the extra −4

**The question:** docs/01 §6.1 names "the raider whose mistake triggered the wipe" without defining it. The proposed rule: the last Severe mistake before the first tank/healer death, else the deepest cascade, else "nobody"; and the extra −4 morale to that raider (docs/01 §6.1 names the number, the RULE is yours). Accept, or give the rule.

**Needed by:** the end of wave 6.

**Default:** the rule as stated, behind a const (`SimResult.wipe_cause`, W6-SIM-CASCADE this wave); `RaidSim.WIPE_CULPRIT_DELTA = −4`; the report's "why it wiped" sentence reads the field (W7-REPORT). Applied by W6-SIM-CASCADE · W7-REPORT.

**Answer line:** "Culprit: accept the rule | the rule is: ___; extra −4: yes / no / ___."

### #63 · LOOP q3 / Q-60 / LOOP-19 — the recruit price scale (landed)

**The question:** may the loop land docs/11's recruit price scale (Common 15 G) behind `PRICE_SCALE`? Three docs printed three tables; the tree had shipped doc 04's (60 G) with no switch; docs/15 Q-60's own default says doc 11 §4.2 S1 is authoritative.

**Needed by:** wave 6.

**Default:** yes — landed this wave: `Recruitment.PRICE_SCALE = "doc11"` selects `[15, 60, 160, 420, 1000]`, `"doc04"` keeps `[60, 180, 450, 1100, 3000]` selectable; docs/11 §12.1 R3 (the anti-arbitrage floor) is a test; docs/15 BL-94. The 60 G purse now buys four Commons — the arithmetic #1 and #60 quote. Applied by W6-LEDGER (done).

**Answer line:** "Price scale: doc 11 (as landed) | doc 04 (flip the switch)."

### #64 · UI q4 / CRITIC-M4 / SHIP q6 / SHIP-20 — S13, S16 and the keyboard map's dead rows

**The question:** S13 (the encounter interstitial) and S16 (the Codex) are in docs/13 §5's inventory and in nobody's plan: cut for 1.0, or build one of them in waves 8-10? And the keyboard map's dead rows (`1`-`4` sort on list screens, `F1` Codex): struck or built?

**Needed by:** wave 6 (the docs) · wave 8 (the keys).

**Default:** both screens struck (BL-24 runs one encounter per rung so S13 has no state; docs/16 C4 sanctions the Codex cut — the Records tab and the Market's compare tooltip carry its answers); the two rows struck; `nav_codex` deleted; `1`-`4` stay the raid speeds, Space is pause, Q/E step the subject, F cycles the Records filter. docs/15 BL-97. Applied by W6-LEDGER (the row, done) · W7-DOCS · W8-KEYS.

**Answer line:** "S13 / S16: both struck | build ___; sort keys: struck | build a sort mode."

### #68 · UI-15 / LOOP-01 — the fixture drops "Lv." and carries a legal Known state (landed)

**The question:** may the fixture drop "Lv." and carry a legal Known state (`--fixture=play`)? The reference fixture was not self-consistent (320 RP at Unknown, day 23 with an empty log, levels on four cards).

**Needed by:** wave 6.

**Default:** yes — `--fixture` stays byte-identical for the diff baselines; the `new` and `play` sheets carry the legal states and no "Lv." (W6-SHEETS, this wave). Applied by W6-SHEETS.

**Answer line:** "Fixtures: as landed."

---

## B. Answer by the end of wave 7 — balance, content and the rulings that size the art units

### #7 · DESIGNER-07 / Q-29 — does a recruit's rolled gear price the recruit

**The question:** does a recruit's rolled gear price the recruit: +15 %/piece (docs/15 Q-29's own default — "+15% cost per raid-tier piece beyond the first, surfaced as a 'well-equipped' label"), none, other? NOT implemented today — `Recruitment.cost_of()` has no gear term (BUILD_STATE's earlier "at its default" was wrong and is corrected); recruits arrive with no gear equipped at all until W8-ITEMS.

**Needed by:** the end of wave 7.

**Default:** `Recruitment.GEAR_SURCHARGE_BP = 1500`, default ON, "well-equipped" on the card — OFF with the reason stated if `tools/playtest.gd` breaks under it. Applied by W8-ITEMS (after #1 — it moves the Tier 1 gold curve).

**Answer line:** "Q-29: +15%/piece | no surcharge | other ___."

### #11 · DESIGNER-11 / Q59-5 / Q-31 / SIM q12 — upkeep and payday

**The question:** upkeep and payday — not in 1.0 / per-run by rarity / payday every N ticks. The game's only recurring gold sink is unspecified: docs/15 Q-31 says per-run, docs/04 §11.3 / §12.2 say "payday", docs/11 §4.2's sink table has no wages row; BIG-dumb condition 5 (`unpaid_2_paydays`) is `live: false`.

**Needed by:** wave 7.

**Default:** not in 1.0 — condition 5 stays false; docs/15 BL-59's status marker records it. The economy is a closed circuit today (#1) and a new sink would tighten it before the on-ramp is fixed. Applied by W6-LEDGER (the row, done) · §7.

**Answer line:** "Upkeep: not in 1.0 | per-run at __/__/__/__/__ G by rarity | payday every __ ticks at __."

### #12 · DESIGNER-12 / M5-END-5 — the Legendary 5% find rate lands on a rank with nothing left to serve

**The question:** the Legendary 5% find rate at a rank with nothing left to serve (Legendary rank lands exactly on the Raid 5 full clear): accept the collection endgame (9-of-9 IS the endgame — docs/15 Q-88 already says "Legendary collection to 9-of-9, no Tier 6 in 1.0") or retime the 5% / the 3200 threshold earlier (edits docs/03 §5.4 and §6.4 together and re-runs the pacing test)?

**Needed by:** wave 7.

**Default:** accept, recorded — one sentence in docs/03 §5.4. Applied by W9-TIERS (the row via W9-REVIEW).

**Answer line:** "END-5: accept | retime 5% to rank ___ / threshold ___."

### #13 · DESIGNER-13 / M5-QAB-4 / Q-69 — does the achievement board pay reputation

**The question:** does the achievement board pay reputation: no / yes at N RP per record, cap 15%? The reward kind is built and gated (`Achievements.gd`: "the achievement_rp switch is off"); docs/03 §6.1's award table has no board row and the ladder is tuned row by row to the Raid 5 clear.

**Needed by:** wave 7.

**Default:** no; the switch off; coin-equivalent fallback; recorded. Applied by W7-DOCS.

**Answer line:** "Q-69: board RP no | yes at ___ RP per record, cap 15%."

### #14 · DESIGNER-14 / Q58-1 / Q58-3 / BL-58 / SIM q10 / CONTENT q6 — the nine Legendary quirks

**The question:** the nine Legendary quirks have names and no spec; five name mechanics the sim does not have. Inert in 1.0 / spec the eight per Q58-3's restatements (shaman = the chain heal's third bounce never fizzles; cleric = immune to MIS_HEAL_CORPSE; mage = +X% spell damage while an ally is downed; wizard = +X% from the enrage round; druid = a valid main-tank fallback; warrior / rogue / monk have substrate) / edit; the Bard deferred (docs/06 §5 first).

**Needed by:** the end of wave 8.

**Default:** inert, displayed, flag off — the "reads as" line on the card, no invented combat effects; the seam threaded by W7-SIM-EFFECTS; W9-QUIRKS builds the nine only if specced. Applied by W7-SIM-EFFECTS (the seam) · W9-QUIRKS (if specced) · §7.

**Answer line:** "Quirks: inert in 1.0 | spec the eight per Q58-3's restatements (yes/edit) | bard: deferred."

### #15 · DESIGNER-15 / BL-42 — the roster cap

**The question:** roster cap: rank (as built — `GameState.ROSTER_CAP_BY_RANK = [15..20]`, docs/04 §12.1, Q-12's own default) / min(rank, hall) / hall (docs/02 §4.3's 14/18/22/26 by Guildhall level, not in code).

**Needed by:** wave 7.

**Default:** rank; docs/02 §4.3's column deleted; BL-42 closed. Applied by W7-DOCS.

**Answer line:** "Roster cap: rank (as built) | min(rank, hall) | hall."

### #16 · DESIGNER-16 / BL-22 — rarity versus morale dominance

**The question:** rarity vs morale dominance — accept now (morale the short-term lever, rarity the long-term axis; the sweep prints LEVER BALANCE every run and shows canon's intended order), held for a Tier 2 re-measure.

**Needed by:** wave 8.

**Default:** accept, recorded; re-measured by W9-TIERS if tiers mount (a test, not a ruling). Applied by W7-DOCS · W9-TIERS.

**Answer line:** "BL-22: accept."

### #17 · DESIGNER-17 / Q-36 / SIM q11 (docs/09 OQ-15) — the Rogue's first raid drop is a downgrade

**The question:** the Rogue's first raid drop (Basic Raid Dagger +4) is a downgrade from the +5 Adventure sword, and the generator propagates the −2 to every tier: extra swings for the Rogue (`Formulas` per-class swing count; canon numbers untouched — the register's recommendation) / raise the dagger to +5/+7 (a canon number moves) / leave (a visible "bug" at the first loot moment, ×5 tiers).

**Needed by:** wave 8.

**Default:** extra swings — `Formulas.DAGGER_SWINGS = 2`, recorded, goldens regenerated in W9-KITS's regeneration. Applied by W9-KITS.

**Answer line:** "Q-36: extra swings | raise dagger to +5/+7 | leave."

### #18 · DESIGNER-18 / Q-33 — the healer's 1-AC Worn Leggings

**The question:** the healer's 1-AC "Worn Leggings" shares its name with the 2-AC Warrior/Bard piece: rename to ___ (canon rule 1 forbids the loop renaming a canon item — the word is yours) / keep and tag by family in the UI ("Worn Leggings · Healer" — display, not a rename).

**Needed by:** wave 7.

**Default:** keep, tag by family. Applied by W8-ITEMS.

**Answer line:** "Q-33: healer Worn Leggings → '___' | keep, tag by family."

### #19 · DESIGNER-19 / Q-35 / LOOP q4 / CONTENT-05/25 — Adventure off-hands and starter weapons

**The question:** Adventure off-hands and starter weapons: sign both / off-hands only / neither — do Commons arrive armed? Today "no weapon" / "Main Hand — empty" / "Damage 0" on Day 1 with no way to buy one; docs/15 Q-35 records "add both" as the build's proposed default (three off-hand rows per rung, docs/09 §10.2's four starters), unsigned.

**Needed by:** wave 7.

**Default:** sign both: three off-hands per rung; docs/09 §10.2's four starters on the shelf; six 0-stat main-hands at New Guild behind `StartingRoster.ARMED = true`; goldens and the sweep re-baselined; the 27/28 discrepancy resolved in §13.1. Applied by W8-ITEMS.

**Answer line:** "Q-35: add both (sign) | off-hands only | neither."

### #20 · DESIGNER-20 / Q-22 — what the Established rank does

**The question:** what the Established rank does — the largest hole in docs/03: (b) as built (recruit-rank only, Rare modal; the town content is "Guildhall facility upgrade II" alone) / (a)+(b) with Market L4 (+Blacksmith L2 if #10 = yes).

**Needed by:** wave 7.

**Default:** as built; docs/03 §5.4 signed by the row. Applied by W7-DOCS.

**Answer line:** "Q-22: (b) as built | (a)+(b) with Market L4 (+Blacksmith L2 if DESIGNER-10 = yes)."

### #21 · DESIGNER-21 + 35 / Q-14 / Q11 — levels, Drilling, the "Lv." label

**The question:** levels — no level-ups in 1.0, confirm; does Drilling (0.75 EW, −2 pp mistake chance, hard-capped) ship in 1.0 or is "Train raiders" cut with the level-ups; the "Lv." label dormant or retired (no path sets `level > 0` outside the reference fixture).

**Needed by:** wave 7.

**Default:** no level-ups; no Drilling in 1.0 (morale is already the dominant lever; a third mistake-chance input to tune); "Lv." dormant — the fixture stops showing it (W6-SHEETS's `new` / `play` sheets carry no levels). Applied by W7-DOCS · W6-SHEETS.

**Answer line:** "Q-14: no level-ups; Drilling in 1.0 yes/no; Lv. label: dormant/retire."

### #22 · DESIGNER-22 / M3-LOOP-06 / LOOP-20 — the town's rank-states

**The question:** the town's rank-states (docs/02 §9.1 asks for six, from "Guildhall boarded, 3 idle townsfolk" to "statue of the guild, 26 townsfolk, stained glass and a tower"): 1 plate + rank dressings derived from the plate's own pixels / 3 plates (you supply, at the reference bar) / 6 plates (you supply).

**Needed by:** wave 7.

**Default:** 1 plate + rank dressings (docs/15 BL-102) — walkers, banners, a boarded tent, the four Guildhall tent states; docs/02 §9.1 amended 🔷 to "one plate, six dressings". Applied by W8-FACILITY · §7.

**Answer line:** "Town states: 1 plate + rank dressings | 3 plates (I supply) | 6 plates (I supply)."

### #23 · DESIGNER-23 / Q-96 / M4B-CONV-04 / UI q7 / AUDIO Q-F — which arena

**The question:** which arena each encounter is fought in: per raid (Adventures and the tutorials in the cave, Raid 1 in the dungeon — the dungeon plate is authored and unrouted) / per encounter (list); the arena's ambience bed follows.

**Needed by:** wave 7.

**Default:** per raid — `SceneStage.arena_for()`'s kind rule (the tier's `scene` key if a tier row names one, else the kind); the bed follows it (docs/15 BL-100). Applied by W7-STAGE · W7-AUD-AMB.

**Answer line:** "Q-96: per raid — Adventures cave / Raid 1 dungeon (yes/edit) | per encounter: ___."

### #24 · DESIGNER-24 / M4B-ACT-04 / PIPE-09 — the aerial town

**The question:** the aerial town (`stage_town`, the menu and the town push-in): still + motion (as built — sails, gulls, clouds; a person on that street would be 10-14 px and every strip we own is 21-48 px) / 10-14 px figures (you supply the sheet).

**Needed by:** wave 7.

**Default:** as built, recorded (BL-102). Applied by W7-DOCS · §7.

**Answer line:** "Aerial: still + motion (as built) | 10-14px figures (I supply the sheet)."

### #25 · DESIGNER-25 / Q12a / C-19 / CONTENT-28 / CONTENT q8 / LOOP q8 — creature and encounter names; the vocabulary; the trinkets' names

**The question:** creature/encounter names for 1.0: placeholders ("Raid 1 — Encounter 5" is canon's own word; docs/10 §2 forbids inventing) / a list; the vocabulary "Encounter N" (raw notes) or "Boss N" (ideaboard); the tutorial trinkets' names — docs/09's template ("Cracked Charm of Power / Health") or docs/01's joke names ("Trinket of Mild Competence").

**Needed by:** wave 7.

**Default:** placeholders — the display name only, never the kind as a name ("Main Boss" is a kind; W6-COPY's interim, docs/15 BL-101); "Encounter N"; the template names. Applied by W6-COPY · W7-DOCS · W8-ITEMS (names, if listed — `title` data on the records).

**Answer line:** "Encounter names for 1.0: no (placeholders) | yes — list: …; vocabulary: Encounter N."

### #27 · DESIGNER-27 / Q02 — boss mass

**The question:** boss mass — the Main Boss reads ~180 px on the 1536 frame beside 2x party figures and stands behind a fence; the reference's boss is ~580 px. Height in px; upscale ok (`marks.boss.scale` 2 — docs/12 §4.1 warns "chunky") / re-author the Main and Mini Boss at ~300 px (L, an art unit).

**Needed by:** wave 7.

**Default:** 1x on its own floor, moved IN FRONT of the fence with the party spread (W7-STAGE); `marks.boss.scale` 2 on the main/mini boss ONLY if you write "upscale ok" — never silently; the re-author is post-1.0 unless commissioned (docs/15 BL-103). Applied by W7-STAGE · §7.

**Answer line:** "Q02: boss height ___px; upscale ok / re-author."

### #42 · DESIGNER-42 / Q18 bundle (a-k) / LOOP q6 / UI q6 — the asset-scope bundle

**The question:** eleven small rulings that size the wave 8-9 art units — a hub CTA "board" · b warrior glyph swords · c the first visible-change tranche and the guildhall at four levels · d HSV busts vs drawn · e which three fumble flavours · f normals or a global light · h which sim states get a glyph · i one VFX family per class · j the Raid Group tab · k the combat body canvas.

**Needed by:** wave 7.

**Default:** a / b / i as built · c dressings per level (W8-FACILITY) · d one figure per class (no re-hue — tried and rejected) · e trip / drop weapon / wrong target (W9-ART) · f a global light · h none more · j retire (the tab hidden in wave 6, deleted in wave 10; RaidPrep's strip IS the raid group) · k the reference density. docs/15 BL-106. Applied by W8-FACILITY · W9-ART · W10-DELETE.

**Answer line:** "Q18: a as built · b as built · c dressings per level · d one figure/class · e trip/drop/wrong-target · f global · h none · i as built · j retire · k reference density — or edit: ___."

### #46 · DESIGNER-46 / M6-AUD-05 / AUDIO-09/13 / AUDIO Q-A..Q-E / SHIP q10 — audio: the owner, music, the voice bus, the world layer, the wipe stamp, ambience's slider

**The question:** who owns audio (a name, or "the loop, ambience only"); music — cut for 1.0 / licensed CC0 (you approve picks) / composed by ___ (five seamless 44.1 kHz loops plus a leitmotif the Legendary stinger can quote) / the generated lute (ii — accepted knowing it is "technically music"); the Voice bus ("the voice of the scribe", defined nowhere): retire the row / `ui.quill` under every log line; does the fight make world sound (hit / spell / heal under `_effects_allowed`); does the WIPE stamp use `ui.stamp`; which slider owns ambience (the Music bus, or a fifth bus that reopens a closed list). docs/15 Q-97 (the direction, as built) and Q-98 (this row) carry the whole soundscape.

**Needed by:** wave 7 (the owner) · the end of wave 7 (the rest).

**Default:** ambience only, on the Music bus ("Music and ambience" — W6-SETTINGS); no music; the Voice row hidden in wave 6 and deleted in wave 10 unless `ui.quill` is bought (audit `m6-quill-hook`); the world layer silent; the WIPE stamp uses `ui.stamp` unjittered; `reduced_motion` never silences a hook, nothing per-line fires at Instant, `reduced_effects` / `comedy_brake` do not touch audio; the clear's sound is the coin. Applied by W6-SETTINGS · W7-AUD-AMB · W8-AUD-OPT (if bought) · W10-DELETE.

**Answer line:** "Audio owner: ___; beds: cut for 1.0 | CC0 (I'll approve picks) | composed by ___ by wave ___; voice bus: retire row."

### #49 · CRITIC q1 / CRITIC-M1 — the Forgiving Guild toggle

**The question:** the Forgiving Guild assist toggle (docs/00 §6.4: one toggle, off by default, scaling raider mistake chance and boss HP by a single multiplier; docs/16 C13 — the LAST cut, and by docs/16 §11's own rule it cannot be cut while C5 and C8 ship): in 1.0 as the docs say, or struck from the cut order in writing? It is NOT the #1 fix and must not be used to make the playtest green.

**Needed by:** the end of wave 7.

**Default:** built — M: `Formulas.DIFFICULTY_MULT` 1.0 / 0.75 under `forgiving_guild`, a sweep axis, one Options row ("Forgiving Guild — fewer mistakes, softer bosses. Changes nothing else."), a docs/13 §15.1 row; audit `m6-forgiving-guild`. Applied by W8-SIM-BALANCE · W8-KEYS · W8-CRISIS.

**Answer line:** "Forgiving Guild: build it (docs/00 §6.4) | strike it from the cut order."

### #53 · CRITIC q5 / SHIP q3 — if the words and names are not back by wave 7's close

**The question:** if the twenty words (#2) and the eight names (#3) are not back by wave 7's close: confirm waves 8-9 proceed on the defaults and 1.0 is Tier 1 with the ending retimed to the Raid 1 clear — or the release waits.

**Needed by:** the end of wave 7.

**Default:** proceed; Tier 1; the ending retimed (#2's default). Applied by W9-TIERS.

**Answer line:** "If the names are late: proceed on Tier 1 | the release waits for them."

### #55 · SIM q4, q5 / SIM-13 / SIM-27 #2 — E4's three content fixes

**The question:** M05's effect E (recommended `raid_damage` at the tier's M02 pulse, E4: 27; else a boss self-heal or a tank one-shot per encounter — docs/10 names E and never says what it is; docs/15 BL-83); E4's M08 window (authored `rounds 5, every 5` tiles into a permanent fixate — recommended `rounds 2, every 5`); M09's cadence (a 3-round debuff with no cadence covers rounds 1-3 of a 17-round fight — recommended `round 3, every 6`).

**Needed by:** the end of wave 7.

**Default:** the recommendations (audit `m6-e4-m05-effect`, `m6-e4-m08-window`, `m6-e4-m09-cadence`), pinned by the E4 golden. Applied by W8-SIM-BALANCE · W9-TIERS (tiers 2-5).

**Answer line:** "E4: M05 effect ___ (raid_damage 27 / other), M08 window ___, M09 cadence ___ — or 'take the recommendations'."

### #56 · SIM q8 / SIM-12 — attrition grace after the enrage round

**The question:** wipe-by-attrition fires at `enrage_round + 5`, a rule no document states (docs/07 §7.3 says the 40-round cap; docs/10 §6 says "enrage expiry"): no grace (the 40-round cap is the safety) or N rounds?

**Needed by:** the end of wave 7.

**Default:** none. Applied by W8-SIM-BALANCE.

**Answer line:** "Attrition grace after enrage: none | ___ rounds."

### #57 · CONTENT q4 / CONTENT-30 / q-W5-SIM — the tutorial mistake rate

**The question:** the tutorial mistake rate (docs/15 Q-51 says "reduced" and no number; the sim runs 0.5 — docs/15 BL-90; A0's fixture shows five mistakes in nine rounds for four raiders at that rate): 0.5 for both, or A0 "only the scripted one" and TR 0.5? Coupled to #9: a re-pricing of TR's swing should be done at the rate the fight will be played at.

**Needed by:** the end of wave 7.

**Default:** 0.5 / 0.5 as a two-entry table. Applied by W8-SIM-BALANCE.

**Answer line:** "Tutorial rate: 0.5 / 0.5 | A0 scripted-only, TR 0.5 | ___."

### #60 · LOOP q9 / SHIP q8 / SHIP-13 / LOOP-25 — disband: game over or recoverable; the soft-lock bail-out

**The question:** disband — game over or recoverable? And the soft-lock bail-out when a guild cannot field a party and cannot afford a hire: a free Common when gold < one hire (15 G at the shipped scale), a loan, or only the sentence and New Guild? A bail-out is a new rule and needs your yes; docs/05 §6.3's banner and modal are unbuilt (W8-CRISIS builds them).

**Needed by:** the end of wave 7.

**Default:** recoverable; no bail-out — the Board's sentence and New Guild. Applied by W8-CRISIS.

**Answer line:** "Disband: recoverable | game over; bail-out: none | a free Common below 15 G | a loan of ___ G."

### #62 · LOOP q2 (second half) / LOOP-24 — does a wiped tutorial cost morale

**The question:** does a wiped TUTORIAL cost morale — a new exemption to docs/05 §7.1 (LOOP-24: the first-time path today is "wipe the Tutorial Raid, then skip it", six Commons at 45 who cannot clear A2)? Filed as its own row, not bundled with #1, because it is a fifth canon number nobody else proposes.

**Needed by:** the end of wave 7.

**Default:** no exemption (the current numbers). Applied by W8-SIM-BALANCE (only if "yes").

**Answer line:** "Tutorial wipes cost morale: yes (as now) | no — exempt."

### #67 · AUDIO Q-F / DESIGNER-23 — the arena bed per encounter or per raid

**The question:** is the arena's ambience bed per encounter or per raid? The same shape as #23.

**Needed by:** wave 7.

**Default:** follows `SceneStage.arena_for()` — whatever #23 decides, automatically; never a second mapping. Applied by W7-AUD-AMB.

**Answer line:** "Arena bed: follows the arena (as #23)."

---

## C. Answer by wave 8 — art and UI switches (a bare "as built" closes each)

All thirteen switches below exist at the stated default (spec 00 §2.7); a ruling that keeps the default costs nothing, a flip is the S/M unit named.

### #26 · DESIGNER-26 / Q01 / UI q1 — figure scale

**The question:** figure scale: as built (camp / cave / dungeon 2x, tavern / market 1x — the plates' own props set the numbers) / the tavern takes docs/12 §3.3's 1.5x exception; or commission the 2x-canvas re-author (XL).

**Needed by:** wave 8.

**Default:** as built (docs/15 BL-103). A flip is one integer per scene JSON (W9-ART) · §7 (the re-author).

**Answer line:** "Q01: as built | tavern 1.5x."

### #28 · DESIGNER-28 / Q03 — hall framing

**The question:** hall framing on the one camp plate: same (as built, `Guildhall.HALL_FRAMING = "same"`) / tight; the roster margins-only (as built) / a 3-column camp strip (M).

**Needed by:** wave 8.

**Default:** as built. Applied by W9-POLISH (a flip).

**Answer line:** "Q03: same | tight; roster: margins | 3-column."

### #29 · DESIGNER-29 / Q04 — one bubble chrome; the emote map

**The question:** one bubble chrome everywhere (the dark callout, as built) or the navy fight plate too; and which morale band or sim event drives each of mug / sweat / skull / zzz / heart / ! / ? — the loop's proposal: heart ≥ 80, mug 60-79 in the tavern, sweat on a mistake roll ≥ Moderate, ! on a mechanic call, ? on a Minor, zzz on the bench, skull on downed.

**Needed by:** wave 8.

**Default:** one chrome; the proposed map behind `SceneStage.EMOTE_MAP` 🔷. Applied by W9-ART.

**Answer line:** "Q04: one chrome; emote map: take the proposed | edit: ___."

### #30 · DESIGNER-30 / Q05 + Q07 — the header lockup and the overhead bars: confirm-only

**The question:** the header lockup at 44 px plus the tagline; overhead bars — badge + pips on every figure, the HP bar on the acting / struck figure — confirm.

**Needed by:** wave 8.

**Default:** as built. Applied by — (a flip is S each).

**Answer line:** "Q05/Q07: as built."

### #31 · DESIGNER-31 / Q06 / UI-53 / LOOP-05 / LOOP q5 — the reputation chip

**The question:** the reputation chip: the reference's purple gem (canon: "no gems" — it reads as a second currency to a new player) or a reputation sigil (the rank shield already on chip 4); does it carry the word "Rep"?

**Needed by:** wave 8.

**Default:** gem (spec 00 §2.5's recorded choice) with the tooltip "N reputation · M more to Known"; `Frame.REP_ICON` flips to the existing rank sigil on a word. Applied by W9-POLISH.

**Answer line:** "Q06: gem | sigil; label 'Rep': yes/no."

### #32 · DESIGNER-32 / Q08 — depth of field

**The question:** depth of field / tilt-shift: off (as built — the reference concepts show no blur; docs/12 §3 calls it non-negotiable) / on at strength N with a per-scene grade you supply (M).

**Needed by:** wave 8.

**Default:** off; docs/12 amended to "optional, off". Applied by W7-DOCS (the amendment).

**Answer line:** "Q08: off (as built) | on at strength ___; grade per scene: ___."

### #33 · DESIGNER-33 / Q09 / M6-JUICE-02 / UI-46 — does "the desk does not move" forbid a dissolve

**The question:** does docs/13 §2 M5's "the desk does not move" forbid a 110 ms opacity cross-dissolve on a screen change (docs/13 §12.2 asks for "cross-dissolve + active tab shifts 6px right, 110 ms"), or only spatial slides? Also gates docs/13 §11.4's t=1,800 post-mortem slide. docs/15 Q-99 carries it.

**Needed by:** wave 8.

**Default:** `ScreenRouter.TRANSITION_MS = 0`, no slide — screens cut, as today; the router's "never will" docstring softened to "not by default" (W10-DELETE). A "yes" is one constant (110, opacity only, through `Widgets.tween`); the 6px tab shift is a slide and stays out either way. Applied by W6-LEDGER (the row, done) · W10-DELETE (the docstring).

**Answer line:** "Q09: dissolve allowed (110ms, opacity only) | nothing moves."

### #34 · DESIGNER-34 / Q10 — town focus entry

**The question:** town focus entry: rail-first (as built, tested — the rail is the one element on every screen) / hotspot-first (docs/13 §13.2, PROPOSED).

**Needed by:** wave 8.

**Default:** rail-first; docs/13 §13.2 amended. Applied by W7-DOCS.

**Answer line:** "Q10: rail-first."

### #36 · DESIGNER-36 / Q12b + Q12c / LOOP-10 / LOOP q1 — the Results comedy line; leaving mid-account

**The question:** the Results comedy line beside the tally — as built (`Results.COMEDY_LINE = "as_built"`) or (a)/(b)/(c); may the player leave mid-account on a first attempt (`RaidView.EXITS_GATED = false` — "The report" and "Back to the board" are live from round 1, so the "Skip to the end" lock is decorative; LOOP-10 recommends gating the exits on a first attempt; the switch exists).

**Needed by:** wave 8.

**Default:** as built (both) — the skip lock's decorative reading is accepted with #6's default (a mandatory first watch is a UX cost with no integrity gain once the attempt is committed before playback). A flip is one constant each.

**Answer line:** "Q12b: as built | (a)/(b)/(c); Q12c: exits free | first watch mandatory."

### #37 · DESIGNER-37 / Q13 second half / UI q2 — "Pauline_4"

**The question:** does "Pauline_4" stay as the handle joke on the hiring board (docs/04 §7's `underscore_digit` shape; on a pixel-art board it reads as a collision suffix): keep as-is / style it — the card's quote line reads "goes by Pauline_4" while the name line shows "Pauline" / drop the shape.

**Needed by:** wave 8.

**Default:** styled "goes by Pauline_4". Applied by W9-POLISH.

**Answer line:** "Pauline_4: keep as-is | style 'goes by' | drop the shape."

### #38 · DESIGNER-38 / Q14 / KIT-20 — the Options controls

**The question:** Options controls: the lit cycle buttons (as built) / toggle-segmented-slider widgets the references lack (M, three widgets).

**Needed by:** wave 8.

**Default:** as built.

**Answer line:** "Q14: cycle buttons."

### #39 · DESIGNER-39 / Q15 / LOOP-30 / UI-55 / LOOP q7 — the tutorial lesson on RaidView / Results

**The question:** should A0's scripted round-3 mistake and TR's "read the Wipe Report" lesson be surfaced on RaidView / Results as a one-line callout band ("Round 3: this is the lesson." / "Read the report: it says who and why."), tutorials only — yes / no? The lesson today lives only on the board's notice.

**Needed by:** wave 7.

**Default:** yes, tutorials only, `RaidView.TUTORIAL_BAND = true`; the `lesson` field on the tutorial records stays either way (a "no" is a const flip). Applied by W7-REPORT.

**Answer line:** "Q15: callout band yes/no."

### #40 · DESIGNER-40 / Q16 / M6-A11Y-06 / UI-47 / RULES-08/09 — the four accessibility rulings

**The question:** CVD — a player option `colourblind_safe` (default off = the reference's red/amber/green) or docs/13 §8.3's red→ochre→olive→teal as the ONLY ramp, and the ten hexes (the loop computes an L*-ordered set); the text floor at the letterbox — Type.SMALL 13 / STACK 11 stay, or 14/12; what `prose_font_swap` means now that Fira Sans is the body face — retire, or redefine (a dyslexia-friendly face the loop would have to source, licence and credit); is the logotype exempt from §14's "no text in art".

**Needed by:** wave 8.

**Default:** the CVD option, default off (W6-SETTINGS, this wave — "Colour-safe morale ramp"); the Type floors as built (13/11); `prose_font_swap` retired (the row hidden in wave 6, deleted with its key in wave 10); the logotype exempt. Applied by W6-SETTINGS · W10-DELETE.

**Answer line:** "CVD: option (default off) | only ramp; text floor: 13/11 | 14/12; prose_font_swap: retire | ___; logotype: exempt."

### #41 · DESIGNER-41 / Q17 — morale faces as a sprite font

**The question:** morale faces as an authored sprite font (`Fonts.MORALE_FACE_FONT = true`; canon's emoji notation read per docs/12 §5.2; flipping restores system emoji) — confirm.

**Needed by:** wave 8.

**Default:** as built.

**Answer line:** "Q17: sprite faces."

### #52 · CRITIC q4 / SIM-10 / SIM q6, q7 — the four PROPOSED class kits; the Bard's magnitudes; Monk Guard's AC

**The question:** the four PROPOSED class kits (Wizard ramp, Rogue Behind/Front, Monk Guard, Mage buff) — post-1.0, or name which land in wave 9; the Bard song magnitudes (`S = 1 + floor(Mana/10)` as docs/15 Q-46 tables them); Monk Guard's AC (the Warrior family's at the rung). docs/15 BL-99 records the four as post-1.0 unless named; the three DECIDED rules (Lost Aggro + Taunt, healer threat, the Bard's songs) land regardless.

**Needed by:** the end of wave 8.

**Default:** post-1.0 for the four (no code behind `false`); the Bard as tabled behind `Formulas.BARD_S_DIVISOR = 10`. Applied by W9-KITS · §7.

**Answer line:** "Kits: all four post-1.0 | build ___ in wave 9; Bard S divisor: 10 (as tabled) | ___; Monk Guard AC: Warrior family's | ___."

### #65 · SHIP q7 / SHIP-20 / LOOP-26 C20 — gamepad for 1.0

**The question:** gamepad for 1.0: "works, unverified, unsupported" (the focus model already steers by pad; docs/16 C6 sanctions one input) or a supported input with glyphs (rebinding, a glyph set)?

**Needed by:** wave 8.

**Default:** unverified, unsupported; the "Controller glyphs" row hidden in wave 6 and deleted in wave 10; the README says so. Applied by W6-SETTINGS · W10-DELETE · W10-EXPORT.

**Answer line:** "Gamepad: unverified, unsupported | supported with glyphs."

---

## D. Any time — confirmations and naming leftovers

### #45 · DESIGNER-45 / spec 00 §2 — the reference-concept conflicts already ruled: confirm

**The question:** the reference-concept conflicts spec 00 §2.2-§2.6 already ruled — Tiny/Ranger → Rogue, no boss names, no levels, the Day·Rank chip instead of a clock, the rail labels canon's building names — confirm; a "reopen" would be a canon change. The one item in the set still open is the gem (#31).

**Needed by:** any.

**Default:** confirmed.

**Answer line:** "Spec 00 §2: confirmed."

### #47 · DESIGNER-47 / Q-61, Q-68, Q-39 — the currency, the building names, Power on zero Adventure armour

**The question:** the currency is "G" (docs/15 Q-61: "keep 'Guild Coin (G)' as an explicit placeholder until named"); Market / the Merchant / Adventure's Board as string-table keys (Q-68); Power on zero Adventure armour deliberate (Q-39: "confirm as deliberate and reproduce exactly, but say so in writing" — the melee classes' only Adventure Power source is the charm).

**Needed by:** any.

**Default:** "G"; as built; deliberate.

**Answer line:** "Currency: G | ___; buildings: as built; Q-39: deliberate."

### #48 · DESIGNER-48 / BL-40 — "Buy a round"

**The question:** "Buy a round" is priced (docs/11 §8.3: 8 G × roster) and has no morale number (docs/05 §7.4 owes the row; the Tavern shipped without the action): cut for 1.0 / +N morale to all, cooldown N ticks. One of the five genuine questions the loop cannot frame a default for beyond "cut": the loop's fallback if you want it kept is +2 capped, the same shape as Q-65's bench numbers.

**Needed by:** wave 7.

**Default:** cut; docs/11 §8.3's row struck; BL-40 closed. Applied by W7-DOCS.

**Answer line:** "Buy a round: cut | +__ morale to all, cooldown __ ticks."

### #66 · SHIP q9 / SHIP-16 — code signing

**The question:** an unsigned .exe trips SmartScreen on every first run: buy a certificate for 1.0, or ship unsigned with a README note?

**Needed by:** wave 10.

**Default:** unsigned; the README-player note. Applied by W10-EXPORT.

**Answer line:** "Code signing: unsigned + README note | a certificate (I'll supply it by wave ___)."

---

## E. The naming sheet (rows #2 and #3)

Twenty words in five columns, plus the leather decision; `data/tier_words.json` is where they go (`pending: false` per tier; every pending tier already lists all five columns and `leather`, null where no candidate exists). Grammar (docs/09 §11.1, §11.4): one capitalised word per cell; no possessive in the word (the template adds `'s`); `raid_title` must read as a person because it is used possessively ("Raider" → "Vanquisher"); `raid_adj` reads as a rank adjective of the title ("Raider" → "Raid": canon's "Basic Raid Sword", "Strong Raid Staff", the capstone prefix) and may equal `raid_title` per tier, collapsing the ask to sixteen words. Tier 1's row is canon's own and is the model.

| Tier | `material` (Adventure metal — Warrior/Bard, Monk, Rogue armour; the Adventure sword and staff) | `cloth` (Mage/Wizard Adventure armour; Firestaff, Arcstaff) | `healer` (healer Adventure armour; the raid Tome's prefix) | `raid_title` (every raid armour piece, possessive; the raid charms) | `raid_adj` ("Basic ___ Sword", "Strong ___ Staff"; "___ Final Headband", "___ Cleric Weapon") |
|---|---|---|---|---|---|
| 1 (canon) | Iron | Spellweave | Blessed | Raider | Raid |
| 2 | ___ (candidate: Steel) | ___ | ___ | ___ (candidate: Vanquisher) | ___ |
| 3 | ___ (candidate: Mithril) | ___ | ___ | ___ (candidate: Conqueror) | ___ |
| 4 | ___ (candidate: Adamant) | ___ | ___ | ___ (candidate: Ascendant) | ___ |
| 5 | ___ (candidate: Runegold) | ___ | ___ | ___ (candidate: Immortal) | ___ |

**Renders at Tier 2 as:** "___ Adventurer's Cuirass", "___ Adventurer's Robe", "___ Adventurer's Circlet", "___'s Greaves", "Basic ___ Sword", "___ Final Headband", "___ Vanquisher's Tome" (healer + raid_title).

**Leather (the sixth decision):** at Tier 1 the Monk/Rogue line reads *Reinforced* Leather Vest, not *Iron* Leather Vest. Either leather shares `material` from Tier 2 on (the recommended default — canon's own T1 line already mixes `Ironbound` and `Reinforced`), or the table gains a `leather` column: T2 ___, T3 ___, T4 ___, T5 ___. `data/tier_words.json`'s `leather_column` holds the answer.

**The eight Legendary names** (docs/03 §5.6: given names only, no surnames, no public figures, nobody on the team). Each file already carries the quirk name, two backstory bullets and the barks; the pronoun is the one the file's own text already uses:

| Class | Quirk (already named) | The file's pronoun | Name |
|---|---|---|---|
| Warrior | Holds the Line | he ("has died more times than he can count and finds that funny") | ___ |
| Cleric | One More Cast | none used | ___ |
| Druid | Grows Into the Gap | none used | ___ |
| Mage | Second Wind of Fire | none used | ___ |
| Wizard | Reads the Whole Fight | he | ___ |
| Rogue | Never Where the Boss Looks | he | ___ |
| Monk | Reads the Room | she | ___ |
| Bard | Carries the Beat | none used | ___ |
| Shaman | The Totem Holds | she | **Natsuna** — final: yes / no |

---

## F. The solvency floor (row #60, with the shipped number)

At the shipped price scale a Common costs **15 G** and the opening purse is **60 G** (docs/01 §8.0 — four Commons, or one Common and a facility down-payment). A guild is "stuck" when it cannot field the next open rung's party and cannot afford the cheapest seat on the board and has nothing to sell worth a fresh purse (`tools/playtest.gd`'s `_can_still_make_progress`, `tests/unit/test_playtest_invariants.gd`). The three doors are read, not guessed; what does not exist is a fourth: a bail-out. **Is there one — a free Common when gold < 15 G, a loan of N G against the next clear, or nothing but the Board's sentence and New Guild?** The default (#60) is nothing: the sentence names the state and the exit, and a new rule is yours.

---

## G. The answer sheet — one line each, in the order above

_A bare "as built" or "take the default" closes a row. Rows marked ★ have no autonomous fallback that reaches a store._

**Wave 6 — shipping**
1. **BAL-04** — lever (a) baseline / (b) first facility / (c) size A1-A3 for 45 / (d) wipe delta; and the number. _Ship default: (c), by docs/08 §9.3's formula with the mechanic term; alternative (a) at 0._
2. **Tier words** — T2/T3/T4/T5 × material / cloth / healer / raid_title / raid_adj (+ leather: shares material, or its own word). _Ship default: none — Tier 1 only ships._
3. **Legendary names** ★ — Warrior, Cleric, Druid, Mage, Wizard, Rogue, Monk, Bard; Natsuna final y/n. _Ship default: the eight are unfindable._
4. **Q-21** ★ — the nine ideaboard screenshots and the six bare plates are your own work: y/n.
5. **Credits** — names and roles; approve the drafted attribution block; copyright holder; version string. _Ship default: the derivable block, one blank line, 1.0.0._
6. **Q-53** — confirm as built (unlimited attempts; the attempt is committed before playback; Esc → the report; Continue → Results; Try again).
8. **Review gates** — sign the name pool; comedy: sign / rewrite lines ___ / cut lines ___. _Ship default: ships unsigned, in writing._
9. **Clear-rate curve** — A1 _ A2 _ A3 _ TR _ E1-E5 _ (±_), or "take the proposed"; keep `TANK_SWAP_NEEDS_A_PARTNER`; A3 by formula or M04. _Ship default: the proposed._
10. **Q-13 Blacksmith** — in 1.0 (upgrades-only) / out; the callout copy. _Ship default: out; the copy stops promising._
43. **JUICE-04** — strike "screen shake on wipes": y. _Ship default: struck._
44. **Aspect** — keep-default, borderless fullscreen on first launch. _Ship default: as built._
50. **Traits** — cut / build. _Ship default: cut._
51. **Retreat** — struck (confirm). _Ship default: struck._
54. **Focus** — post-1.0 / the numbers. _Ship default: post-1.0._
58. **NINJAPULL** — cut / build the break phase. _Ship default: cut._
59. **Wishlists** — out / in. _Ship default: out._
61. **The wipe's culprit rule** — accept / the rule; the extra −4. _Ship default: the rule as stated; −4._
63. **Price scale** — doc 11 (landed) / doc 04. _Ship default: doc 11._
64. **S13 / S16, the sort keys** — struck / build. _Ship default: struck._
68. **Fixtures** — as landed.

**Wave 7 — balance and content**
7. **Q-29** — +15% per raid piece / none / other. _Ship default: +15% behind a switch._
11. **Upkeep** — not in 1.0 / per-run at __ G by rarity / payday every __ ticks. _Ship default: not in 1.0._
12. **END-5** — accept the collection endgame / retime 5% to rank __. _Ship default: accept._
13. **Q-69** — board RP: no / yes at __ RP, cap 15%. _Ship default: no._
14. **Quirks** — inert in 1.0 / spec the eight per Q58-3's restatements / edit; bard deferred. _Ship default: inert, displayed._
15. **Roster cap** — rank (as built) / min(rank, hall) / hall. _Ship default: rank._
16. **BL-22** — accept. _Ship default: accept._
17. **Q-36** — Rogue: extra swings / dagger +5/+7 / leave. _Ship default: extra swings._
18. **Q-33** — the healer's 1-AC Worn Leggings → "___" / keep and tag by family. _Ship default: tag._
19. **Q-35** — Adventure off-hands + starter weapons: sign / off-hands only / neither. _Ship default: sign._
20. **Q-22** — Established: (b) as built / (a)+(b). _Ship default: as built._
21. **Q-14** — no level-ups; Drilling in 1.0 y/n; "Lv." label dormant/retire. _Ship default: no; no; dormant._
22. **Town states** — 1 plate + rank dressings / 3 plates (you supply) / 6 plates (you supply). _Ship default: dressings._
23. **Q-96** — arena per raid (Adventures cave, Raid 1 dungeon) / per encounter: list. _Ship default: per raid._
24. **Aerial** — still + motion / 10-14px figures (you supply). _Ship default: still._
25. **Encounter names** — placeholders / a list; vocabulary "Encounter N"; the trinkets' template names. _Ship default: placeholders._
27. **Q02 boss mass** — height __px; upscale ok / re-author. _Ship default: 1x in front of the fence; scale 2 only on "upscale ok"._
42. **Q18 bundle** — a · b · c · d · e · f · h · i · j · k as listed, or edits. _Ship default: as listed._
46. **Audio** — owner ___; beds: cut / CC0 / composed by ___; voice bus row: retire; world layer; the wipe stamp; ambience's slider. _Ship default: ambience only on the Music bus, no music, voice row retired, world silent, `ui.stamp`._
49. **Forgiving Guild** — build / strike. _Ship default: build._
53. **If the names are late** — proceed on Tier 1 / wait. _Ship default: proceed._
55. **E4** — M05 effect, M08 window, M09 cadence. _Ship default: the recommendations._
56. **Attrition grace** — none / N rounds. _Ship default: none._
57. **Tutorial rate** — 0.5 / 0.5, or A0 scripted-only. _Ship default: 0.5 / 0.5._
60. **Disband and the bail-out** — recoverable / game over; none / a free Common / a loan. _Ship default: recoverable; no bail-out._
62. **Tutorial wipes cost morale** — yes (as now) / exempt. _Ship default: no exemption._
67. **Arena bed** — follows the arena. _Ship default: follows #23._

**Wave 8 — art and UI switches (a bare "as built" closes each)**
26. Q01 figure scale · 28. Q03 hall framing · 29. Q04 bubble chrome + emote map · 30. Q05/Q07 lockup and bars · 31. Q06 gem or sigil (+ "Rep" label) · 32. Q08 DoF off/on · 33. **Q09 dissolve allowed / nothing moves** · 34. Q10 rail-first · 36. Q12b/c comedy line, exits · 37. Pauline_4 keep / style / drop · 38. Q14 cycle buttons · 39. Q15 tutorial callout y/n · 40. **Q16: CVD option (default off) / only ramp; text floor 13/11 or 14/12; prose_font_swap retire; logotype exempt** · 41. Q17 sprite faces · 52. the four kits post-1.0 / build ___; Bard divisor 10 · 65. gamepad unverified / supported.

**Any time**
45. Spec 00 §2 (Ranger→Rogue, no boss names, no levels, Day·Rank chip, rail labels): confirmed. · 47. Currency "G"; building names; Q-39 deliberate. · 48. Buy a round: cut / +__ morale, cooldown __. · 66. Code signing: unsigned / a certificate.

**Genuine questions the loop cannot frame a default for** (the only ones): 3 (the names), 4 (provenance), 5 (your credit), 46 (the audio owner's name), and 48 — "buy a round" is priced (docs/11) and has no morale number (docs/05 owes the row): _what does a round do to morale?_ (one integer per raider, once per town cycle; the loop's fallback is +2 capped, the same shape as Q-65's bench numbers).
