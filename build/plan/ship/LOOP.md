# LOOP — player journey, UX and mental model (ship report)

_Reporter: LOOP. Read-only pass on the tree during wave 5, 2026-09-15. Evidence is file:line or sheet/tile._

## Executive summary

1. **Shippable today:** the loop's spine. New Guild → Town → Board → prep → the account → the report → town is walkable by buttons (test_full_loop), every screen has an exit, every disabled control prints a reason, the empty states are in-world (LOOP-31), the canon morale format holds on every card, saves and the play clock work (LOOP-28 refutes two audit rows), and the Town/Board tell a Day-1 player exactly what to press first.
2. **Not shippable:** the first hour and the last. Six Commons at 45 cannot clear A2 (M6-BAL-04), the Tutorial Raid is 1/20 winnable so the taught path is "wipe it, then skip it" (LOOP-24), disband can then fire with no banner, no modal and no after-state (LOOP-25) — and past E5 the hub pins a CLEARED mission as "Next mission" while the board promises "Adventure 2 and Raid 2" that the build does not mount (LOOP-06, LOOP-07).
3. **The three biggest gaps:** (a) the mental model of risk and failure — the prep readout speaks two languages and a per-encounter "~58.5 mistakes" (LOOP-08), the wipe report never names why it wiped (LOOP-12), and reputation earned is shown nowhere (LOOP-13); (b) promises the build cannot keep — tiers, the Blacksmith, building looks (LOOP-06, LOOP-20) — plus the walked-out ladder (LOOP-07); (c) the crisis and solvency surface — LOOP-25, LOOP-16, LOOP-19.
4. **The copy sweep** found 31 distinct strings (C1-C31); 15 are reachable by a real player today and admit something unbuilt: the Blacksmith's "maybe … Disabled in this build" (the designer's own "Under construction." sits in a dead field), "wishlists with the loot module" on every starting raider, Settings' "13 of 17 live in this build" and four locked rows naming missing work, S17's status paragraph that cites docs/15 and an audit id, the Raid Group tab, "The party stands here". Every one has a HIDE/REWORD/BUILD row and its test pin named; a wave-6 unit can act on the table as written.
5. **Slot codes leak** into the sentences a blocked player reads first — "Clear A0 first.", "TR — Tutorial Raid", "A0 · a party of 4" (LOOP-03) — and "1 enemies" prints on every tutorial notice (LOOP-04).
6. **Cross-screen inconsistencies:** "Cheer up — They are fine." at 45 on the roster while the Market sells the same Hot Bath to the same raider (LOOP-16); three sentences for one Records gate (LOOP-15); recruit prices on doc 04's scale against docs/15 Q-60's recommended doc 11 (LOOP-19); "12,480 G" beside "12480 → 12480" and "7150 / 7150" (LOOP-21).
7. **No feedback:** Space/1-4/Q/E/F are bound and handled nowhere (LOOP-22; M6-A11Y-01 is stale); chalking changes nothing in the prep arena (LOOP-09); provisions are words on buttons (LOOP-29).
8. **Blocked on the designer** (11 questions at the end): Q12c exits, the TR/A2 numbers, Q-60, Commons armed?, Q06 chip, Q18 Raid Group, Q15 lesson bands, Q12a creature names, disband = game over?, the culprit rule, and the four content sign-offs (tier names, Legendary names, credits, music).
9. **Wave order this report recommends:** 6 = the copy table + LOOP-02/03/04/06(guard)/07/13/14/15/16/17/19/26/27 + the `new` sheet (LOOP-01) — all S, one afternoon each; 7 = prep and report mental model (LOOP-08/09/11/12/29/30) + crisis surface (LOOP-25) + names/numerals (LOOP-21/23/18); 8 = keyboard handlers (LOOP-22), the Raid Group answer; 8-9 = tiers 2-5 and building layers when named; 10 = delete the dead "not in this version" branches (C3-C5), verify the grep in the Shippable bar returns nothing.
10. **Coverage caveat:** every Day-1 claim here is from code, because no sheet shoots a new guild — the "empty" sheet is a contentless mount and the fixture carries "Lv." and "320 RP at Unknown" that no player sees (LOOP-01). Shoot the `new` sheet before wave 6's reviews.

## Findings

### LOOP-01 — No sheet shows the first-time player; "empty" is a contentless mount, not a new guild
**Status** CONFIRMED
**Evidence** `tools/shot_all.sh:20` — `empty <Screen> no fixture — the a11y "empty" sweep as images`; `build/shots/all/empty/Town.png` header chip reads "No guild loaded." (1310,37), sidebar "The guild has no content loaded to pin." (1187,270), strip "Available 0". A real new game is `GameState.new_game()` — six Commons, 60 G, Day 1, Unknown, A0 open (docs/01 §8.0) — and no sheet row shoots it. The fixture rows carry data no player ever sees: "Lv. 12" (`tools/fixture_reference.gd:29`; `Raider.level` is reserved and 0 in play, `sim/model/Raider.gd:126-128`; `Cards.gd:143` hides it at 0) and "320 reputation · 0 more to Known" at rank Unknown (`fixture/AdventureBoard.png` 1176,513 — rank only moves through `Reputation.rank_after()` at award time, `GameState.gd:1259`, so the state is unreachable in play).
**Doc** docs/13 §15 "Definition of done, per screen: has an authored empty state" — the empty state that matters is Day 1, not "no content". No docs/15 row.
**Fix** `tools/shot.gd` gains `--fixture=new` (calls `GameState.new_game("<name>")` through the seam `--fixture` uses) and `shot_all.sh` gains a `new` sheet over the 13 routes; every LOOP finding below is re-checked on it in wave 6 before UX units are cut. Drop `level` from the fixture cards, or note in the sheet header that "Lv." is fixture-only.
**Owns** tools/shot.gd, tools/shot_all.sh, tools/fixture_reference.gd
**Size** S
**Wave** 6 — first, because every later UX unit's "one look" review is otherwise looking at a state that does not exist.
**Audit** relates M6-PLAY-01, m4t-08

### LOOP-02 — The Blacksmith callout still admits an unbuilt feature; the designer's "Under construction." sits in a field nothing reads
**Status** CONFIRMED
**Evidence** `game/screens/Town.gd:110` `"blurb": "Under construction."` — `blurb` is never read by `_callout()` (Town.gd:238-270) nor by any file (`grep -rn blurb game/` hits only Facilities/Guildhall/Market's own dictionaries). What the player sees is `Town.gd:567` `"Canon lists this one as a maybe. Disabled in this build."` — on both sheets (`fixture/Town.png` 563,458; `empty/Town.png` same tile). Commit `cfd2c29` records the designer's edit as Q13's hub copy. Tests pinning the visible word "maybe": `tests/unit/test_screens.gd:311`, `:371`; `tests/unit/test_town_layout.gd:348`; the kit tests (`test_widgets_kit.gd:298/315/359/788`, `test_w4_cursor.gd:208`) pass their own string and are unaffected. `test_screens.gd:380` pins the fall-through "Not built in this version yet." for a flag-on, rank-met, screen-missing state — unreachable in a shipped build (the flag is off, `GameState.gd:217`).
**Doc** docs/13 §7 `BrassTab` "locked (with unlock condition as text)"; docs/13 OQ-9 default "Build the town hotspot as a locked, visible building"; docs/15 Q13 (00-plan §6: hub copy is the designer's). The designer's ruling for this report: hide or reword to in-world copy.
**Fix** `_unlock_reason()`'s flag-off branch returns the blurb — "Under construction." — so the locked plate reads "Blacksmith / Under construction." (two rows, TOWN-02's shape holds); delete the `blurb` indirection or make it the one source. Retarget the three screen tests from `contains("maybe")` to `contains("Under construction")`. Leave the `screen_exists` fall-through (unreachable with the flag off) or fold it into the same sentence.
**Owns** game/screens/Town.gd, tests/unit/test_screens.gd, tests/unit/test_town_layout.gd
**Size** S
**Wave** 6 — part of the copy-sweep unit.
**Audit** M3-LOOP-03 (partial; the Blacksmith gate), docs/15 Q13

### LOOP-03 — Slot codes ("A0", "TR", "E1") leak into player-facing copy: "Clear A0 first.", "A0 · a party of 4", "TR — Tutorial Raid"
**Status** CONFIRMED
**Evidence** `game/core/RaidPlan.gd:416` `"Clear %s first." % String(other.slot)`; `game/screens/AdventureBoard.gd:343` `Widgets.button("%s — %s" % [e.slot, e.display_name])`; `AdventureBoard.gd:640` `"%s  ·  a party of %d" % [e.slot, e.party_size]`. On `fixture/AdventureBoard.png`: "Clear A0 first." (283,545), "A0 · a party of 4" (1330,485), "TR — Tutorial Raid" (289,436). Slots are data keys (`data/encounters_t1.json` `slot: "E1"`; tutorial file `"A0"`/`"TR"`); a new player has never been told what "TR" is. Pins: `tests/unit/test_ladder.gd:82,89`, `tests/unit/test_raid_plan.gd:271-292` assert the exact "Clear A0 first." shape; `tools/playtest.gd` / `test_full_loop.gd` press notices by fragment (M5-TUT-14: "presses 'A1'").
**Doc** docs/13 OQ-8 default: render the placeholder verbatim (`Raid 1`, `Boss 3`) — the display names already do; nothing in docs/02 §11.1 or docs/13 §9 asks for the slot code on the notice. No docs/15 row for the reason string. Recommended default: display names in prose; slot code only as a muted stamp on the notice if the art wants it.
**Fix** `RaidPlan.locked_reason()` prints `other.display_name` ("Clear Adventure 0 first."); the CTA sub-line drops the slot ("A party of 4"); the notice title keeps the slot as a muted prefix only if the screen tests need it to press by — otherwise `display_name` alone. Update the four pinned assertions and any `--press=` fragment in shot_all/tests.
**Owns** game/core/RaidPlan.gd, game/screens/AdventureBoard.gd, tests/unit/test_ladder.gd, tests/unit/test_raid_plan.gd
**Size** S
**Wave** 6 — copy sweep; it is the first sentence a blocked player reads.
**Audit** relates M3-LOOP-04, M5-TUT-06

### LOOP-04 — "1 enemies": the encounter facts line has no plural
**Status** CONFIRMED
**Evidence** `game/screens/AdventureBoard.gd:523` and `game/screens/Town.gd:468` `"%s  ·  %d enemies  ·  about %d rounds"`; `fixture/Town.png` (1187,270) "Trash · 1 enemies · about 6 rounds"; `fixture/AdventureBoard.png` (283,292) same. Every tutorial rung (A0, TR) and every one-boss encounter prints it.
**Doc** docs/13 §14 "Plurals and gender — ICU MessageFormat".
**Fix** One helper (`Type.count(n, "enemy", "enemies")`; `Town._today_lines()` already hand-rolls "event%s") used by both callers; a test in test_screens asserts "1 enemy".
**Owns** game/ui/Type.gd, game/screens/AdventureBoard.gd, game/screens/Town.gd
**Size** S
**Wave** 6 — copy sweep.
**Audit** none (new)

### LOOP-05 — The reputation chip is a bare number beside a gem; nothing on the screen says it is reputation
**Status** CONFIRMED
**Evidence** `game/ui/Frame.gd:601-602` `Widgets.chip(Type.num(state.reputation_points), Palette.ACCENT_GEM, gem.png)` — no label, no tooltip on this chip (the standing tooltip is on the DAY chip, `Frame.gd:611-612`). `fixture/Town.png` (905,37) reads "320" beside a gem. The Board sidebar is the only place the word "reputation" attaches to the number (`fixture/AdventureBoard.png` 1176,513).
**Doc** docs/13 §6.3: the desk strip shows "Reputation rank (with a 6-step pip meter)… never a percentage bar"; docs/02 §2.2 keeps the HUD to the rank name. Neither asks for a raw RP number. 00-plan §6 Q06 asks the designer whether the chip keeps the gem and whether it carries the word "Rep" — so the FORM is blocked; the finding stands that the number is unlabeled today. Recommended default: rank word + pips (W5-KIT3 ships `Widgets.pips()` unused), RP number on hover.
**Fix** Replace the gem chip with a pip strip inside the Day·rank chip (or fold the number into that chip's tooltip, which already says "320 reputation · N more to Known"). Keep `reputation_points` in words on the Board where it is spent.
**Owns** game/ui/Frame.gd, tests/unit/test_screens.gd (chip text pins)
**Size** S
**Wave** 7 — after the pips form exists (W5-KIT3).
**Audit** relates M3-LOOP-01, M6-A11Y-08

### LOOP-06 — The board and the hub promise what the build cannot deliver: "Known… opens Adventure 2 and Raid 2", "Next at Respected: Blacksmith opens"
**Status** CONFIRMED (the content half is BLOCKED-designer)
**Evidence** `game/screens/AdventureBoard.gd:727-734` prints `"%d more to %s, which opens Adventure %d and Raid %d"` from `Reputation.max_raid_tier(next_rank)`; `data/reputation.json` ranks: known → max_raid_tier 2, respected → 3 …; but `sim/content/ContentDB.gd:158-163` mounts only tiers where `tier_is_named()` and `data/tier_words.json` marks tiers 2-5 `pending: true`. So at Known (120 RP — one A1 run at 25 plus E1-E3 at 10/15/25 gets there) the ladder shows no new rung and the sentence the player earned it with was false. `fixture/AdventureBoard.png` (1176,513) "0 more to Known, which opens Adventure 2 and Raid 2." The Town's promise line `Town.gd:519-525` prints `Reputation.town_unlock(rank+1)` verbatim: at Known it reads "Next at Respected: Blacksmith opens." while `GameState.gd:217` ships the Blacksmith flag off. `fixture/Town.png` (1176,382) shows the Known line "Guildhall facility upgrade I; Quest board" — that one is true (Facilities tab, Records tab).
**Doc** ✅ CANON "New Tiers can be unlocked by gaining reputations with the town"; docs/03 §7 master table; docs/15 BL-69 (tier names — designer); docs/14 §5.2 (completable with every flag off). Recommended default: a promise names only what THIS build mounts — the board's sentence asks `state.content` whether tier N exists, and the town's asks `Buildings`/flags; when nothing opens, say "more of the same, better paid" (the string `AdventureBoard.gd:726` already has).
**Fix** (a) Wave 6: `AdventureBoard._standing()` checks `state.content.has_tier(next_tier)` (or `raid_encounters(tier).is_empty()`) before naming it; `Town._town_unlock_line()` filters `town_unlock` through the feature flags (a `Reputation.town_unlock_for_build(rank, flags)` helper, or the data row split into building ids per M3-TUNE-05 so the filter is not string surgery). Tests: test_screens "120 more to Known" pin gains the mounted-tier clause. (b) Waves 8-9: tiers 2-5 named and mounted (M5-T25-08/09/10) makes the original sentence true again — leave the guard in, it costs nothing.
**Owns** game/screens/AdventureBoard.gd, game/screens/Town.gd, sim/core/Reputation.gd, tests/unit/test_screens.gd
**Size** S (guard) / XL (content, blocked on BL-69 names)
**Wave** 6 for the guard; 8-9 for the content.
**Audit** M5-T25-08 (blocked), M5-T25-09, M5-T25-10, M3-LOOP-01, M3-LOOP-03

### LOOP-07 — After Raid 1's last encounter the campaign has nothing to say: the hub pins a CLEARED mission as "Next mission" and no screen names the next goal
**Status** CONFIRMED
**Evidence** `game/screens/Town.gd:441-457` `_next_mission()`: when `RaidPlan.next_open_mission()` is null it returns `ladder[0]` — the hub's "Next mission" card then shows "Adventure 0 · CLEARED" over a live "Open the board" CTA. `Town._facts_of(null)`'s "The ladder is walked out — the board is up the road." (Town.gd:467) is unreachable while the ladder has any rung (`_next_mission` never returns null with content). `AdventureBoard._completion_goal()` (:764-782) prints "The campaign is finished. The guild is not." only when `state.completed`, which `GameState` sets on the first clear of tier 5's last encounter (M5-END-1) — impossible while tier 5 is unmounted. Every notice on the board reads CLEARED; the sidebar's standing line says what the next rank "opens" (LOOP-06). `tools/playtest.gd` stops at A2 for the balance reason (M6-BAL-04), so no harness has walked past E5 to see this state.
**Doc** docs/13 §5 S09/S17; docs/10 §13; docs/00 §6.3 (1.0 ends at Raid 5). No docs/15 row for "tier N cleared, tier N+1 not in this build". Recommended default: the board's goal block gains a second state — "Raid 1 is cleared. The road past it is not open yet." — used whenever `next_open_mission()` is null and `completed` is false, and the hub's card says the same instead of re-pinning A0.
**Fix** `Town._next_mission()` returns null when the ladder is walked out and `_mission_card(null)` prints the walked-out facts (the string exists); `_hub_cta` stays live (the board is where the goal is stated). `AdventureBoard._completion_goal()` handles the walked-out-but-not-completed case with one sentence. A test in test_screens mounts a state with every tier-1 rung cleared and asserts both sentences. When tiers 2-5 ship, the state is only reachable after Raid 5 and the sentence becomes S17's job.
**Owns** game/screens/Town.gd, game/screens/AdventureBoard.gd, tests/unit/test_screens.gd
**Size** S
**Wave** 6 — it is the first dead end a good player hits in the shipped tier.
**Audit** M5-END-1, M5-END-3, M6-PLAY-02

### LOOP-08 — The risk readout speaks two languages at once ("ELEVATED" and "Reckless") and its headline figure (~58.5 mistakes) is not a number a player can act on
**Status** CONFIRMED (a design judgement; thresholds are docs/15 BL-25)
**Evidence** `game/core/RaidPlan.gd:188-197` `risk_word()` LOW/ELEVATED/SEVERE by ratio to baseline; `:220-241` `verdict()` Ready/Risky/Reckless/Suicidal by a "trouble" count that folds the same risk word in. `game/screens/RaidPrep.gd:767-776` prints both: "Expected mistakes ~58.5 / encounter", hatch + "ELEVATED", "Baseline at this comp 44.4"; then `:788-808` "Verdict: Reckless" and a crimson callout "~58.5 mistakes" (`fixture/RaidPrep.png` 777,373 / 1187,389). The magnitude is per-encounter across 12 raiders × 2 sites × 22 rounds (`RaidPlan.gd:150-180`), so a Ready comp still reads "~44 mistakes"; docs/13 §10.3's worked example is "~4.6".
**Doc** docs/13 §10.3 (one number, one word, top-3 contributors, "this is what makes 4.6 mean something"); docs/06 §6.5 (the verdict word); docs/15 BL-25 (the ratio thresholds). OQ-2: no win percentage. The two docs each own a word; nothing says both go on one panel.
**Fix** One headline, one word: the callout carries the VERDICT word and the delta that drove it ("+14 mistakes over a content guild", i.e. expected − baseline), the readout keeps the hatch as the verdict's own meter, and "ELEVATED/SEVERE" becomes the hatch's caption only (or is dropped in favour of the verdict word). Keep the per-encounter figure in the Predicted-risk block as the second line. `test_prep_layout` / `test_raid_plan` pins on the strings move with it.
**Owns** game/screens/RaidPrep.gd, game/core/RaidPlan.gd, tests/unit/test_raid_plan.gd, tests/unit/test_prep_layout.gd
**Size** M
**Wave** 7 — after the copy sweep, with the LOOP-09 prep pass.
**Audit** relates M6-BAL-03 (the target curve), M6-A11Y-06

### LOOP-09 — Raid prep's arena shows an empty rectangle captioned "The party stands here": chalking has no visible effect in the scene
**Status** CONFIRMED
**Evidence** `game/screens/RaidPrep.gd:74` `const BAND_CAPTION := "The party stands here"`; `:336-380` `_frame_band()` draws a bronze rim and the caption over the dimmed arena; nothing calls `SceneStage.place_party()` here although RaidView does (`RaidView.gd` `_party_layout()`/`_stage()`; the stage's §0.5 contract lists `place_party`). `fixture/RaidPrep.png` (287,317) shows the caption over an empty band. Chalking a raider changes the strip and the readout, never the picture. No test pins the caption (`grep "stands here" tests/` — none).
**Doc** docs/13 §9.2 (the chalked twelve is the central decision); spec 09 §4.3 row 5 (the twelve combatants on the arena floor); 00-plan Q01/Q02 (figure scale — landed at 2x behind `figure_scale`). The prep arena is always `SceneStage.DEFAULT_ARENA` (RaidPrep.gd:206) — which arena per encounter is Q18/Q-96 (M4B-CONV-04, designer).
**Fix** Place the chalked party in the band with `stage.place_party(_chalked, marks)` on every `_refresh()` (facing the boss mark; the boss itself may stand at its mark too, since `Cards.encounter_sprite` exists), and drop the caption; an empty chalkboard shows the empty band with the existing strip empty-state doing the talking. Test: after `_toggle()` the stage has N party sprites.
**Owns** game/screens/RaidPrep.gd, tests/unit/test_prep_layout.gd
**Size** M
**Wave** 7.
**Audit** M4B-ACT-05 (partial), M4B-CONV-04 (arena routing, blocked)

### LOOP-10 — The "Skip to the end" lock is decorative: "The report" and "Back to the board" are live from round 1
**Status** BLOCKED-designer (Q12c) — recorded with the recommended default
**Evidence** `game/screens/RaidView.gd:292` `const EXITS_GATED := false`; `:768-788` both exits wired unconditionally; `:630-642` "Skip to the end" disabled with "Unlocks once you have cleared this one." on a first attempt. `fixture/RaidView.png`: the lock reason at (186,664), "The report" live at (1424,697), round 1 of 22 at (52,174). A first-time player can press "The report" at round 1 and never watch the account — the exact thing docs/01 §9's first-clear gate exists to prevent; and if they press "Back to the board" they never see the Results sheet for an attempt that has already been recorded (`RaidPrep.gd:867-889` records before the view opens).
**Doc** docs/01 §9 (OQ#1 ruling: skip unlocked per encounter after the first clear — governs); docs/13 §11.2 (Instant LOCKED until cleared once); docs/07 §3.1 (contradicts, "always available" — docs/01 owns availability). 00-plan §6 Q12c: "may the player leave mid-account, or is the first watch mandatory?" Recommended default: `EXITS_GATED = true` on a first attempt only (the switch already prints "The account is still being read"), released the moment the account finishes or the encounter has been cleared before — the same predicate as `_resolve_skip_unlocked()`.
**Fix** Flip the constant behind the same predicate (gate only when `not _skip_unlocked`), and make "Back to the board" after a finished account route through Results (or say on Results how to re-read the account). Test: `test_raid_beats` asserts the exits are reasoned on a first attempt and live on a repeat.
**Owns** game/screens/RaidView.gd, tests/unit/test_raid_beats.gd
**Size** S
**Wave** 6 if the designer answers Q12c; otherwise stays as built.
**Audit** relates M6-JUICE-03, docs/15 Q-53

### LOOP-11 — Log lines, mistake headers and joke lines ellipsize with the full text only in a tooltip
**Status** CONFIRMED
**Evidence** `game/screens/RaidView.gd:1975-1980` every log row `clip_text = true`, `OVERRUN_TRIM_ELLIPSIS`, `tooltip_text = text`; `:2011-2015` the joke line the same. `fixture/RaidView.png` (1207,815) "Greg (Rogue) — Severe — Dropped a Mecha…" — the mistake's NAME is the part cut. The comment cites spec 02 §2.1 "a long row ellipsizes, never wraps".
**Doc** docs/13 §11.1 "Body left-aligned, ragged right, measure ≤ 74 characters"; §14 "Two-line wrap permitted on … log.line"; §7 "A tooltip … may never be the only place a number lives"; §11.3 the header line is one of the four mistake signals. The user's rule (memory: reference concepts are a standard; where their UI does not fit the design, the design wins) settles the spec-02 conflict in favour of wrapping.
**Fix** `Widgets.log_row` Labels wrap (AUTOWRAP_WORD_SMART) with the round-marker gutter kept; the mistake header and joke never clip. Row pitch becomes variable — `_age_rows`/`_fold_to` already handle heights per row? verify; `test_log_player`/`test_raid_beats` pin no ellipsis on a mistake header. Same treatment on Results' account (`Results.gd` reuses `log_row`).
**Owns** game/ui/Widgets.gd (log_row), game/screens/RaidView.gd, game/screens/Results.gd, tests/unit/test_raid_beats.gd
**Size** M
**Wave** 7 — with the comedy corpus landing (M5-COMEDY-03), the lines get longer, not shorter.
**Audit** M5-COMEDY-05 (partial), M6-A11Y-07

### LOOP-12 — The wipe report never says WHY it wiped: no culprit, no triggering mistake, no cause line
**Status** CONFIRMED (the sim half is SIM's; the report half is LOOP's)
**Evidence** `sim/core/RaidSim.gd:161-188` `SimResult` carries outcome, rounds, log, survivors, casualties, mistake_count, damage, healing, potions — no "triggering mistake" or culprit field; `grep -n "culprit\|triggered the wipe\|extra -4" sim/core game/core` finds nothing, and the sheet's morale column is a uniform −12 (`fixture/Results.png` 1078,256-520). `game/screens/Results.gd:393-417` `_headline()` prints the stamp, the slot+name and the encounter's authored `comedy_line` (COMEDY_LINE "as_built", Q12b) — a line written BEFORE the fight, not about it. The cause bracket exists only per cascade row (`:1246-1260` `_cause_line`). What the player gets: "It's a wipe!", the tally, "By raider" mistake counts, then 52 log lines to read.
**Doc** docs/01 §6.1 "an extra −4 to the raider whose mistake triggered the wipe"; §6.4 "a post-mortem naming the raider at fault, the specific mistake, and a one-line in-character excuse … readable in under 15 seconds"; docs/13 §11.4 "cause chain, mistake tally by raider, rounds survived". No docs/15 row names the "triggering mistake" rule as decided; docs/07 §7 owns the wipe. Recommended default: the culprit is the last Severe mistake before the first death of a tank/healer, else the mistake with the highest cascade depth, else "nobody — the boss simply won" (an honest line the comedy can carry).
**Fix** SIM: `SimResult.wipe_cause: Dictionary` ({actor_id, mistake_type, round, entry_seq}) set by `RaidSim` when the outcome is a wipe (rule above, behind a named const, recorded as a BL row), and the `deltas_queued` extra −4 to that raider. LOOP: `Results._headline()` gains one sentence under the stamp — "Round 21: Steve stood in the fire. Everything after that was arithmetic." — built from the entry's header + its joke; the By-raider row of the culprit gets the stamp glyph; `RaidView`'s wipe beat points at the same entry. Tests: test_results asserts the sentence names the actor and the mistake for a golden wipe.
**Owns** sim/core/RaidSim.gd (SIM unit), game/screens/Results.gd, game/screens/RaidView.gd (the wipe beat's focus), tests/unit/test_results*.gd
**Size** M (S report + S sim)
**Wave** 7 — after the comedy corpus (M5-COMEDY-03) so the excuse line exists to quote.
**Audit** M6-JUICE-03 (the wipe sequence's post-mortem beat), M5-COMEDY-05, docs/15 Q12b

### LOOP-13 — Reputation earned is never shown: no "+25 reputation" on the report, no rank-up beat, no feed line
**Status** CONFIRMED
**Evidence** `game/core/GameState.gd:1238-1265` `_award_reputation()` adds RP, emits `reputation_changed` / `rank_advanced`; `grep -rn "rank_advanced\|reputation_changed" game/ tools/` finds NO listener outside the emit; `GameState.log_event()` call sites (:1006-2551) never write a reputation line; `Results.gd` mentions reputation only to price the sell button (:750-753). The clear feed line is "Cleared Adventure 0 — 4 G." (`:1030`). So the only trace of the macro loop's currency is the header gem number (LOOP-05) and the day chip's hover. `raid-clear/Results_clear.png` shows Payout 4 G (803,153) and nothing about the +5 RP or the rank moving Unknown → Known between this shot and `fixture/RaidPrep.png` (the chips differ: 1187,138 reads "Day 24 · Known").
**Doc** docs/01 §4.1/§4.2 `LootDistribution → ReputationUp : rank threshold crossed` (🔷 PROPOSED, an acknowledge beat); docs/03 §6.1 award table; docs/02 §2.1 Rule of Visible Change. No docs/15 row. Recommended default: a "Reputation +N" cell in the tally row on Results; a feed line "The town heard: +N reputation" on every award; on a rank-up, one `PinnedNote`-style callout on the next Town visit ("Known. The Quest board is open; Guildhall facility upgrade I is for sale.") — the town column's promise, cashed.
**Fix** `GameState._award_reputation()` stores `last_rp_award` and logs "+N reputation" (kind "system" or a new "reputation" log glyph — the icon grid has none; `Icons` gains one or reuses `rank_<key>`); `Results._numbers()` adds the cell; `Town._sidebar()` shows a one-visit callout when `rank_advanced` fired since the last town visit (a `rank_up_seen` flag on the state, saved). Tests: test_full_loop asserts the feed line and the callout after the A1 clear.
**Owns** game/core/GameState.gd, game/screens/Results.gd, game/screens/Town.gd, game/ui/Icons.gd (glyph), tests/unit/test_full_loop.gd
**Size** M
**Wave** 6 — the macro loop's only feedback; cheap.
**Audit** M3-LOOP-01 (closes the "no feedback" half), M3-LOOP-05 (relates), M5-QAB-4 (the reward kind)

### LOOP-14 — The Guildhall's "Raid Group" tab is permanently disabled: a dead control on the most-visited screen
**Status** BLOCKED-designer (Q18 / HALL-21: read-only view or retired) — hiding is allowed today
**Evidence** `game/screens/Guildhall.gd:47-49` `{"id": "raid_group", "label": "Raid Group", "reason": "Chalk tonight's twelve from the Adventure's Board."}` — the reason is static and nothing ever clears it (`_tab_reason()` :248-255 clears only `records`). `fixture/Guildhall.png` (398,112) greyed tab, reason at (343,133). docs/13 §5 S03 lists the tab; the chalking moved to S10. Pins: `tests/unit/test_kit3.gd:525-537` and `test_widgets_kit.gd:494-506` pass their own reason strings (kit-level); `tests/unit/test_screens.gd` / `test_roster_layout.gd` — check for "Raid Group" before removing.
**Doc** docs/13 §7 `BrassTab` locked "with unlock condition as text" — this one has no unlock condition, only a redirect; the designer's ruling for this report: hide unfinished features. 00-plan Q18 (HALL-21) asks whether it becomes a read-only view of the last chalked party or is retired.
**Fix** Wave 6: drop the tab from `TABS` (three tabs: Roster / Facilities / Records) — the reason's sentence survives as the strip empty-state on RaidPrep, which already says it. If Q18 answers "read-only view", wave 8 builds it from `state.last_party` (the ids `record_attempt` was handed).
**Owns** game/screens/Guildhall.gd, tests/unit/test_screens.gd, tests/unit/test_roster_layout.gd
**Size** S
**Wave** 6 (hide) / 8 (build, if ruled)
**Audit** none; 00-plan Q18 (HALL-21)

### LOOP-15 — Three gates for one wall: "Opens at Known.", "There is nothing to record until you have raided. The board opens at Known.", "The board opens at Known. The town has to have heard of you first."
**Status** CONFIRMED
**Evidence** `game/ui/Cards.gd:657-668` `view_all_reason()` → "Opens at Known."; `game/screens/Guildhall.gd:52` the Records tab's reason; `sim/core/Achievements.gd:720-724` `unlock_reason()` → "The board opens at %s. The town has to have heard of you first." (printed by `Guildhall.gd:493` inside the tab when a state reaches it locked). The middle one is false after the first raid at Unknown (raids ARE recorded — `Achievements.record_attempt`, and the feed shows "Wiped on …"). And the event log's "View All" (`Cards.gd:616`) routes to the RECORDS tab (`open_records`, :671-684), which is the achievement wall, not the full event log the link's placement suggests. Pins: `tests/unit/test_roster_layout.gd:320` ("nothing to record"), `tests/unit/test_starting_roster.gd:227-228`.
**Doc** docs/03 §7 (Quest/achievement board at Known); docs/13 §7 (reason text). No row on the wording. Recommended default: one sentence owned by `Achievements.unlock_reason()` and printed by all three sites — "The record wall opens at Known." — and "View All" either shows the whole feed (a scrolling event log) or is renamed "Records".
**Fix** `Guildhall.TABS[records].reason` and `Cards.view_all_reason()` both call `Achievements.unlock_reason(snap)`; the link's label becomes "Records" (or the link opens a full-feed view — the feed keeps twenty rows, `GameState.log_event` ring). Retarget the two pins.
**Owns** game/screens/Guildhall.gd, game/ui/Cards.gd, sim/core/Achievements.gd (string only), tests/unit/test_roster_layout.gd, tests/unit/test_starting_roster.gd
**Size** S
**Wave** 6 — copy sweep.
**Audit** M5-QAB-3 (relates)

### LOOP-16 — "Cheer up" says "They are fine." at morale 45 — the exact morale at which the campaign cannot be cleared — while the Market sells the same Hot Bath to the same raider with no such gate
**Status** CONFIRMED (the number underneath is M6-BAL-04, BLOCKED-designer)
**Evidence** `game/screens/Roster.gd:627-628` `elif not Morale.is_at_risk(r.morale) and r.morale >= 40: reason = "They are fine."`; `game/screens/RaiderDetail.gd:370-372` the same gate. `game/screens/Market.gd:1055-1083` (Comfort tab) and `GameState.use_indulgence()` (:1633-1657) have no morale gate — the Market sells the 20 G Hot Bath Token to a 45-morale raider (and RaiderDetail lists it at 2 places: the Quarters "Hot Bath Token · 20 G" button, `fixture/RaiderDetail.png` 733,277, right beside a disabled "Cheer up / They are fine." at 1330,308/1176,335). Meanwhile `BUILD_STATE.md:39-45`: a 45-morale roster in full T1 Adventure gear stops at A2 (6 of 8 guilds). `fixture/Guildhall.png` shows eight of twelve at 45 "Slightly Annoyed" with "Cheer up" disabled "They are fine." (each card, y=399/680).
**Doc** docs/13 OQ-4 (quick-apply from the roster row); docs/05 §7.4 (+8 spike); docs/05 §8 (Common baseline 45); docs/01 §5.2 (the Steve decision). No row sets 40 as "fine". Recommended default: the roster's quick-apply gates on the SAME predicate the Market uses (can it land? `_apply_morale` returns 0 on cooldown) — never on a fixed band — and the reason when it cannot land is the Market's own ("%s had one recently.").
**Fix** Remove the `>= 40` clause in both screens; the reason falls through to price / sold-out / cooldown (`GameState.use_indulgence` already returns the sentence). A test in test_roster_layout asserts a 45-morale raider's Cheer up is live with gold in hand. This does NOT fix M6-BAL-04 (a +8 spike decays) but it stops the screen contradicting the game.
**Owns** game/screens/Roster.gd, game/screens/RaiderDetail.gd, tests/unit/test_roster_layout.gd, tests/unit/test_raider_detail.gd
**Size** S
**Wave** 6.
**Audit** M6-BAL-04 (relates), M6-PLAY-02

### LOOP-17 — Every first-time raider's detail page admits two unbuilt modules: "Backstories arrive with the Tavern; wishlists with the loot module."
**Status** CONFIRMED
**Evidence** `game/core/StartingRoster.gd:55-100` builds the six Day-1 raiders with no backstory draw (`Recruitment.gd:256-260` draws one only for Tavern candidates); `game/screens/RaiderDetail.gd:751-760` prints, for a raider with neither, the empty state "Nothing is written down about them yet." + hint "Wants nothing in particular. Backstories arrive with the Tavern; wishlists with the loot module."; `:763-773` the split sentences "Backstories arrive with the Tavern." / "Wishlists arrive with the loot module." `fixture/RaiderDetail.png` (795,510-552). Wishlists are unbuilt (Q59-3, L, not-started). No test pins the sentence (`grep "loot module" tests/` — none).
**Doc** docs/05 §12 Q6 (wishlists "an optional module built after the core loop"); docs/04 §5 step 7 (backstory drawn at recruitment); docs/01 §8.0 (six pre-made raiders, "names pending"). Recommended default: the six starting raiders draw backstories from the same pool as recruits (it exists: `data/backstories.json`, `GameState._backstory_pool()`), and the wishlist line is hidden until the module exists.
**Fix** `StartingRoster.build()` takes the backstory pool (or `GameState.new_game()` draws after build, the way `refresh_board()` does for candidates); `RaiderDetail._written()` drops the wishlist sentence entirely (and the hint) while `Q59-3` is open — "Nothing is written down about them yet." alone is in-world. The morale arithmetic line (`:659-660` "+N their past") then also reads truthfully for starters.
**Owns** game/core/StartingRoster.gd, game/core/GameState.gd (new_game), game/screens/RaiderDetail.gd, tests/unit/test_starting_roster.gd, tests/unit/test_raider_detail.gd
**Size** S
**Wave** 6 — copy sweep + the one-line draw.
**Audit** Q59-3 (relates; the wishlist module itself is wave 8-9 or cut)

### LOOP-18 — "no weapon" / "Main Hand — empty" / "Damage 0" on Day 1, with no way to buy one
**Status** CONFIRMED (the ruling is ❓ OPEN — docs/04 Q3 / docs/09 §10.2)
**Evidence** `data/items_starting.json` + `ContentDB.starting_set()` equip armour only (`StartingRoster.gd:96-97`); `fixture/RaiderDetail.png` (614,359) "no weapon", (330,403) "Main Hand — empty"; `fixture/RaidPrep.png` (777,318) "AC 61 · Damage 0 · Mana 0" for a twelve-raider party. The Market's Buy tab sells consumables and furnishings only (`Market.gd` TABS :60-62; no gear SKU anywhere — `Consumables`, `Comfort`); weapons come only from drops (`Loot`). A new player reads "Damage 0" and has no screen that sells a sword.
**Doc** docs/01 §8.0 🔷 PROPOSED "the six starting raiders arrive with a 0-stat placeholder weapon so Adventure 0 is completable without a purchase"; the general question is docs/04 Q3 / docs/09 §10.2 ❓ OPEN ("do Commons arrive armed at all?"); ✅ CANON's starting list has four armour slots and no weapon. Recommended default: docs/01 §8.0's — a named 0-stat "Practice Sword"/"Borrowed Staff" per class family in `items_starting.json`, so the slot reads as a thing and "Damage" reads as a number the gear ladder improves.
**Fix** Behind a switch (`StartingRoster.ARMED := true`), six 0-damage main-hands in `data/items_starting.json` (one per class family; docs/09 owns the families) equipped at `new_game`; the sell price 0 so the Market cannot turn them into gold. The goldens and the sweep are unmoved by a 0-stat item (assert it). If the designer says "unarmed", the alternative is copy: "Main Hand — bare hands" and the readout's "Damage" becomes "Weapon damage 0".
**Owns** data/items_starting.json, game/core/StartingRoster.gd, tests/unit/test_starting_roster.gd
**Size** S
**Wave** 7 — ask with the M6-BAL-04 batch; both are Day-1 numbers.
**Audit** relates M5-TUT-04, M6-BAL-04

### LOOP-19 — Recruits cost docs/04's scale (Common 60 G) while docs/15 Q-60's recommended default is docs/11's (Common 15 G); a new guild's 60 G buys exactly one Common and nothing else
**Status** CONFIRMED
**Evidence** `sim/core/Recruitment.gd:59` `COST_BASE := [60, 180, 450, 1100, 3000]` (doc 04 §3.3); pinned cell-by-cell by `tests/unit/test_recruitment.gd:286-302`; `game/core/GameState.gd:91` `STARTING_GOLD := 60`. `fixture/Tavern.png` (1338,441) "Hire — 60 G" for a Common Mage; footer (140,1008) "Hiring Linda leaves 12,420 G". docs/15:541 Q-60: "Doc 11 §4.2's scale is authoritative; docs 04 and 13 render it" (recommended default, unimplemented, no switch). docs/15:829 lists "A Common hire costs 15 G" as a shipped fact.
**Doc** docs/11 §4.2 S1 (15/60/160/420/1,000); docs/01 §8.0 (60 G sized against a 15 G Common); docs/15 Q-60. Not a canon number — both scales are 🔷 PROPOSED — so the loop may land the register's default behind a switch.
**Fix** `Recruitment.PRICE_SCALE := "doc11"` selecting `[15, 60, 160, 420, 1000]` (doc 04's kept selectable); re-run docs/11 §12.1 R3 (anti-arbitrage: sell value of a recruit's kit < their price) as a test; update test_recruitment's table and `test_playtest_invariants.gd:94-108` (the solvency floor). Record as a BL row.
**Owns** sim/core/Recruitment.gd, tests/unit/test_recruitment.gd, tests/unit/test_playtest_invariants.gd, docs/15-open-questions.md (BL row)
**Size** S
**Wave** 6 — economy coherence before any balance ruling is costed.
**Audit** M3-TUNE-05 (relates), M6-BAL-04 (the gold leg of the circuit)

### LOOP-20 — Building levels promise a visible change ("Next: Second stall, crates, two shoppers") that nothing draws
**Status** CONFIRMED (the art is BLOCKED-designer under Q18 / M3-LOOP-06)
**Evidence** `game/screens/Market.gd:355` "Next: %s." from `Consumables.stall_look()` (:306-315: "Second stall, crates, two shoppers" …); `game/screens/Facilities.gd:163-166` "Next: <level name> — N G" + `next["look"]` prose; the hall card crops the camp plate at one fixed rect (`Facilities.gd:49` `HALL_CARD_CROP`, HALL-18 interim) for every level; `fixture/Market.png` (1176,485). `game/ui/SceneStage` scenes have no level layers (M3-LOOP-05 not-started; M3-LOOP-06 blocked). After paying 130 G the stall prose changes and the market plate does not.
**Doc** docs/02 §2.1 Rule of Visible Change; §9.2 obligation table ("every building level must claim at least one exterior asset"); m4t-10 (thumbnails "still a sentence of text"). 00-plan Q18 (TOWN-15: the first visible-change tranche).
**Fix** Wave 6 copy: prefix the prose honestly as what it is — the level's NAME and its effect (stock rows, comfort slots), and keep the "look" sentence only once its layer exists (a `has_layer` check on the scene JSON). Waves 8-9 art: one overlay layer per building per level on `stage_camp.json` / `stage_market.json` (the SceneStage layer model already toggles by key), the Facilities card crops the level's own layer (m4t-10). Blocked on Q18's tranche ruling for what the layers depict.
**Owns** game/screens/Market.gd, game/screens/Facilities.gd, game/assets/scenes/*.json, game/ui/SceneStage.gd, art (spec 09)
**Size** S (copy) / L (art)
**Wave** 6 (copy), 8-9 (art, designer)
**Audit** m4t-10, M3-LOOP-05, M3-LOOP-06

### LOOP-21 — Numerals disagree between screens: "12,480 G" in the chip, "(12480 → 12480)" on the Market's sell-all button, "7150 / 7150" on the boss bar
**Status** CONFIRMED
**Evidence** `game/ui/Frame.gd:600` uses `Type.gold()` (separator); `fixture/Market.png` (355,231) "Sell all nobody can wear — 0 G (12480 → 12480)"; `fixture/RaidView.png` (1253,97) "7150 / 7150"; `Market.gd:631-660` builds the sell-all label with `%d`. docs/13 §4.3 "Thousands — locale separator … never hard-coded".
**Doc** docs/13 §4.3.
**Fix** Route every player-facing gold/HP figure through `Type.num()`/`Type.gold()` (grep `%d G` across game/screens — Market, Facilities, RaiderDetail, Tavern, Results all hand-format); a lint test greps for `%d G"` in game/screens and fails on new ones. Drop the "(before → after)" parenthetical from a DISABLED sell-all (it is arithmetic about nothing).
**Owns** game/ui/Type.gd, game/screens/*.gd (format sites), tests/unit/test_type.gd
**Size** S
**Wave** 7.
**Audit** none (KIT-15's consumers)

### LOOP-22 — Half of docs/13 §13.1's keyboard map is bound and unhandled: Space, 1-4, Q/E and F do nothing on any screen
**Status** CONFIRMED (audit M6-A11Y-01 says "not-started, XL"; the bindings half IS done — the entry is stale)
**Evidence** `project.godot:100-146` defines `nav_toggle` (Space), `nav_prev_subject`/`nav_next_subject` (Q/E), `nav_cycle_filter` (F), `nav_sort_1..4`, `nav_codex` (F1), `nav_settings`; `tests/unit/test_a11y.gd:109-199` prove they are bound. `grep -rn "is_action_pressed" game/` finds exactly three handlers, all in `ScreenRouter.gd:200-204` (`ui_cancel`, `nav_codex`, `nav_settings`). Tab/arrows/Enter work through the focus model (`ScreenRouter.wire_shell_focus`, `test_a11y.gd:380-478`). So on RaidPrep a keyboard player focuses a bench face and presses Space (§13.1 "chalk/unchalk") — nothing; presses 1-4 on the Roster (sorts) or RaidView (speeds) — nothing; F (cycle filters) — nothing; F1 — nothing (S16 does not exist, `ScreenRouter.CODEX_SCENE`).
**Doc** docs/13 §13.1 (the map), §13 "Full keyboard navigation — blocking"; §13.2 non-pointer equivalents ("no interaction may exist only as a pointer gesture" — chalking IS reachable by Enter on the face Button, so the floor holds; the map does not).
**Fix** Per-screen `_unhandled_input` (or one `Frame` hook that dispatches to `screen.on_action(name)`): RaidPrep — nav_toggle chalks/unchalks the focused face; Roster/Tavern/Market — nav_sort_N presses the Nth sort chip, nav_cycle_filter the next filter chip; RaidView — nav_sort_1..4 = speed positions, nav_toggle = Pause; RaiderDetail — Q/E previous/next raider. F1: either build S16 (docs/13 marks it 🔷 PROPOSED; the itemization "who else can wear this?" question it answers is real) or drop the binding and the row from §13.1 in wave 10. Tests: one per screen in test_a11y, feeding `InputEventAction` through the viewport.
**Owns** game/screens/RaidPrep.gd, Roster.gd, Tavern.gd, Market.gd, RaidView.gd, RaiderDetail.gd, game/ui/Frame.gd, tests/unit/test_a11y.gd, build/plan/audit.json (M6-A11Y-01 → partial)
**Size** M
**Wave** 8 — after the screens settle (waves 6-7 rewrite copy and layouts these handlers would target).
**Audit** M6-A11Y-01 (stale: partial), M6-A11Y-02 (done by the focus model)

### LOOP-23 — Every guild is named "A Guild Story": S01 offers no name, so the guild's name is the game's title everywhere it prints
**Status** CONFIRMED
**Evidence** `game/screens/MainMenu.gd:356-360` `_on_new_game()` → `_state.new_game("A Guild Story")`; no LineEdit on the screen (`grep LineEdit game/screens/MainMenu.gd` — none). The Town sidebar heading (`Town.gd:191-197`) then repeats the wordmark ("A Guild Story" at 1176,121 under the lockup at 240,37 on `fixture/Town.png`); Completion says "A Guild Story cleared the last fight" (`fixture/Completion.png` 261,701); Continue reads "Continue — A Guild Story" (`MainMenu.gd:145`).
**Doc** docs/13 §5 S01 "Choose or create a guild save"; §6.3 the desk strip's first item is "Guild name"; docs/13 §9.1 wireframe "Ashfall Company". No docs/15 row. Recommended default: a one-field name prompt on New Guild with a generated default (two-word guild names from a small pool — the name pool machinery exists in `data/names.json`), Enter to accept.
**Fix** MainMenu: New Guild opens an inline name row (LineEdit + "Found the guild" CTA, Esc cancels) prefilled with a generated name; `GameState.new_game(name)` already takes it. Town's heading then means something; when the name equals the title, the sidebar heading is redundant and may be dropped.
**Owns** game/screens/MainMenu.gd, data/names.json (a guild-name list), tests/unit/test_menu_lockup.gd
**Size** S
**Wave** 7.
**Audit** none

### LOOP-24 — The first-time path is "wipe the Tutorial Raid, then skip it": the tutorial that teaches the Wipe Report also teaches that skipping is how you progress
**Status** BLOCKED-designer (M6-BAL-03 / the TR pin) — the UX consequence is recorded here
**Evidence** `tests/unit/test_tutorials.gd:363-372` pins TR at 1/20 clears as authored (`TUTORIAL_RAID_CLEARS_AS_MEASURED := 1`); `RaidPlan.locked_reason()` (:411-419) blocks A1 until TR is RESOLVED (cleared or skipped, `GameState.rung_resolved` :850); the board's only way past a wiped TR is "Skip the tutorial" (`AdventureBoard._skip_block`), which forfeits the Cracked Charm and prints "It is not a good trinket." So the intended lesson (docs/01 §8.1: "a full encounter with a real fail state; the Wipe Report") lands, and then the game asks the player to give up on it. Retrying costs a day and morale (−12 each, `fixture/Results.png`), which pushes the six Commons toward the leave bands before A1.
**Doc** docs/01 §8.1/§8.2; docs/10 §9; docs/15 (the TR ruling is a designer's: swing or M01). Recommended default (LOOP's, for the designer to accept or refuse): the Tutorial Raid is winnable at ≥ 8/20 with the pre-made six (drop M01 from TR or re-price the swing with the multiplier — test_tutorials.gd:338-347 has both measured), and a wiped tutorial costs NO morale (docs/05's tutorial-rate ruling already halves mistakes; a morale exemption is the same shape).
**Fix** Designer rules; then `test_tutorials.gd` flips to `>= 8`, `GameState._apply_raid_morale` gains a tutorial exemption (behind a const), and `tools/playtest.gd`'s walk covers A0 → TR → A1 without a skip. Until then: the skip block's copy could say the honest thing — "This one is hard. Skipping it forfeits the trinket and nothing else." — so the forced skip does not read as failure.
**Owns** sim/content (TR record), game/core/GameState.gd, tests/unit/test_tutorials.gd, game/screens/AdventureBoard.gd (copy)
**Size** S once ruled
**Wave** 6 (copy) / 7 (numbers, designer)
**Audit** M6-BAL-03, M5-TUT-10, M5-TUT-11

### LOOP-25 — A guild can disband with no warning and no screen: docs/05 §6.3's banner and modal are unbuilt, and after a disband the town simply has nobody in it
**Status** CONFIRMED (the mechanism is M5-TUT-09, XL, not-started)
**Evidence** `game/core/GameState.gd:106-107` `signal guild_crisis(strikes, p_disband_next)`, `signal guild_disbanded()` — `grep -rn "guild_crisis\|guild_disbanded" game/` finds no listener; the only trace is `log_event("mistake", "The guild disbanded.")` (:1471, :1721) — a feed row. Disband arms once both tutorials are RESOLVED (`:898-913`, skipping counts), i.e. right after LOOP-24's forced skip. After it: `Town._today_lines()` "Today: no raiders yet — the Tavern is up the road." (Town.gd:479), RaidPrep "No raiders to chalk. The Tavern has candidates." — with a Common at 60 G (LOOP-19) and whatever gold is left; `tools/playtest.gd`'s new `_can_still_make_progress` (W5-TESTS) is the first thing that will name this state.
**Doc** docs/05 §6.3 (five guarantees: two ticks of escalating warning, an unmissable modal at strike 2 naming the raiders and the actions, the number, no silent state — "a persistent header banner is present on every town screen", autosave before the roll); ❓ OPEN whether disband is game over (docs/05 §12 Q5, docs/01 OQ#2). Recommended default: not game over — the guild persists with its gold, buildings and reputation minus §6.5's penalty; the Town gets a "The guild disbanded on day N" callout with one action (the Tavern).
**Fix** (a) The crisis surface: `Frame.standard_chips` gains a crisis stamp on the day chip when `crisis_strikes >= 1` (GUILD UNSTABLE / IN CRISIS / COLLAPSING from `Morale`), and the Town sidebar prints the at-risk names with the three actions as links (Cheer up, bench — i.e. do not raid them, Facilities); (b) the strike-2 modal (`Widgets.confirm_pair` exists — `Market.gd:435`'s worn-by confirm uses it) on entering Town, stating `p_disband_next`; (c) a post-disband Town state with a way forward and a solvency floor (if gold < one Common, the Tavern's first hire is free — a rule the designer must accept; the alternative is a game-over sheet). Tests: test_game_state drives strikes 1-3 through `rest_in_town()` and asserts the banner text and the modal.
**Owns** game/ui/Frame.gd, game/screens/Town.gd, game/core/GameState.gd, sim/core/Morale.gd (the three words), tests/unit/test_game_state.gd, tests/unit/test_screens.gd
**Size** L
**Wave** 7 — before any balance ruling makes low morale common.
**Audit** M5-TUT-09, Q59-6 (the BIG-dumb warning surface shares the banner), M6-PLAY-02

### LOOP-26 — The Settings screen is an inventory of what is not built: "13 of 17 live in this build" and four locked rows that name the missing work
**Status** CONFIRMED
**Evidence** `game/screens/Settings.gd:290` header "%d of %d live in this build"; rows `:95` "The type pass ships the second family." (Prose font swap), `:102` "Display options arrive with the export build." (V-sync), `:112` "One language so far." (Language), `:115` "Gamepad support is not in this build." (Controller glyphs), notes `:106` "The bus is here and waiting; no music is written yet.", `:110` "…nothing is voiced yet."; sidebar `:616-617` "Nothing here is a build flag; those live in data/tuning." (a repo path). All on `fixture/Settings.png` (336,127; 449,464; 449,578; 449,660; 449,742; 449,792; 449,833; 1176,254). `tools/export_build.sh` exists and is green with `--dev` (BUILD_STATE HANDOFF 3), so the V-sync reason is stale. Pins: `tests/unit/test_options_layout.gd:360-368` counts `ROWS` (hiding a row must shrink ROWS or filter at build).
**Doc** docs/13 §15.1 "if an option is not in this table, it does not exist in the settings screen" — and, by the designer's ruling here, an option that does not work does not exist either. Q16 (prose_font_swap's meaning), OQ-12 (gamepad in 1.0?), M6-AUD-05 (music, designer).
**Fix** Wave 6: drop the header count and the "data/tuning" sentence; hide the Prose font swap, Language and Controller glyphs rows until each works (keep their GameSettings keys); wire V-sync (`DisplayServer.window_set_vsync_mode`, an S task) or hide it; drop the two audio notes (the sliders work; the buses being empty is not the player's business). Wave 10: whatever is still hidden is either built (gamepad map per OQ-12, a second language) or deleted from §15.1.
**Owns** game/screens/Settings.gd, game/core/GameSettings.gd (vsync), tests/unit/test_options_layout.gd
**Size** S
**Wave** 6.
**Audit** M6-AUD-05 (music, blocked), M6-A11Y-05 (done), OQ-12

### LOOP-27 — S17 prints the credits file's status line — a paragraph that cites "docs/15 Q-21 and audit M5-END-4" to the player
**Status** CONFIRMED (the content is BLOCKED-designer, M5-END-4)
**Evidence** `data/credits.json` `status`: "The credits are not written yet. Who this game credits — and the attribution its fonts, tools and any sourced assets owe — is a sign-off a person has to give, recorded as docs/15 Q-21 and audit M5-END-4."; `game/screens/Completion.gd:104` `CREDITS_MISSING` and the print path; `fixture/Completion.png` (1176,525-585). Pins: `tests/unit/test_menu_lockup.gd:319`, `tests/unit/test_screens.gd:577` (both `contains("not written yet")`). Also on that sheet: "at Unknown — just started" after 23 days — a fixture artifact (`played_seconds` DOES accrue in play, `GameState.gd:544-553`; audit M3-SAVE-02 is stale, see LOOP-28), and "12480 G" (LOOP-21).
**Doc** docs/13 §9.5 "until a person signs the roll off, that file says so in one line and the screen prints that line" — the doc chose honesty over hiding; the designer's ruling for this report supersedes it for the shipped build.
**Fix** Wave 6: the Credits panel prints "The guild" roster block and, with `lines` empty, nothing else (the status stays in the file as the record); retarget the two pins to "the status is NOT printed". Wave 9/10: the roll is signed (designer) and `lines` filled.
**Owns** game/screens/Completion.gd, tests/unit/test_menu_lockup.gd, tests/unit/test_screens.gd; data/credits.json (designer)
**Size** S
**Wave** 6 (hide) / 10 (fill)
**Audit** M5-END-4 (blocked)

### LOOP-28 — REFUTED: audit M3-SAVE-01 and M3-SAVE-02 ("not-started") — the town-transition autosave and the play clock are built
**Status** REFUTED (the audit rows are stale)
**Evidence** `game/core/GameState.gd:531-542` `_on_screen_changed()` — `save_now()` on any route to the main menu and `_autosave_transition()` on `TOWN_SCREENS` (a dedicated rotation index, `:567-577`, exactly the "better" option the M3-SAVE-01 entry proposes); `:544-553` `_accrue_played_time()` accrues `played_seconds` per transition with a cap; `tests/unit/test_savegame.gd:512+` covers the clock. The player-facing consequence the entries feared (a hire lost to a Back button) does not exist: Tavern hire `:2290`, loot `:2074`, skip `:880`, claim `:2962` all autosave, and the menu route saves.
**Doc** docs/14 §7.4 rows 1 and last.
**Fix** Mark M3-SAVE-01 and M3-SAVE-02 `done` in `build/plan/audit.json` (W5-TOOLS owns the queue this wave — a handoff line). Nothing to build.
**Owns** build/plan/audit.json
**Size** S
**Wave** 6 housekeeping.
**Audit** M3-SAVE-01, M3-SAVE-02, M3-SAVE-05

### LOOP-29 — Provisions are text-only on the prep board (the Market shelf has icons); three of six icons do not exist
**Status** CONFIRMED (m4t-04 is PARTIAL, not "not-started": the Market's Buy shelf loads `Icons.at("item", sku)` at `Market.gd:827`)
**Evidence** `game/screens/RaidPrep.gd:567-590` `_provision_button()` builds a plain `Widgets.button("<name>  chosen/held")` — no icon; RaiderDetail's Quarters buttons (`fixture/RaiderDetail.png` 733,234-277 "Straw Cot +3 · 40 G", "Hot Bath Token · 20 G") likewise. `game/assets/ui/icons/` holds `item_minor_healing_potion`, `item_potion_of_steady_hands`, `item_rally_flask` and no whetstone / mana draught / guild feast (m4t-03 still open for those three). A Day-1 guild holds 4 Minor Healing Potions (docs/01 §8.0) and sees four words on a button at prep. The rewards row (`AdventureBoard.gd:614-620`, `RaidPrep.gd:451-459`) floors at two slots, so a one-drop encounter shows an EMPTY slot beside the real one (`fixture/AdventureBoard.png` 1253,375) — it reads as a missing icon.
**Doc** docs/13 §9.2 "Consumables: 4 potions" / "Potions assigned 3/4"; docs/11 §7 (six SKUs); 00-plan W1-ICONS (`item_{whetstone,mana_draught,guild_feast}` 32x32 were in its emit list and did not land).
**Fix** RaidPrep's provision buttons become `Widgets.slot(icon)` + name + "chosen/held" numeral (the Market's `_buy_cell` shape, reused); RaiderDetail's Quarters buttons take the same icon; author the three missing icons through `gen_icons.lua`. The rewards row floors at ONE slot, or fills the second with the payout coin when the encounter pays gold.
**Owns** game/screens/RaidPrep.gd, game/screens/RaiderDetail.gd, game/screens/AdventureBoard.gd, game/ui/Icons.gd, tools/art/gen_icons.lua (+ the three PNGs), tests/unit/test_prep_layout.gd
**Size** M
**Wave** 7.
**Audit** m4t-03 (partial), m4t-04 (partial)

### LOOP-30 — The tutorials' lessons are stated only on the board's notice; nothing on RaidView or Results says "this is the round-3 mistake" or "read the Wipe Report"
**Status** BLOCKED-designer (Q15) — recommended default recorded
**Evidence** `data/encounters_tutorial_t1.json` comedy_line for A0 ("On the third round somebody will do something stupid, and that is the lesson.") and TR ("Read the Wipe Report; you will be seeing a lot of it.") print on the Board and as the prep header (`RaidPrep.gd:250-254`); `RaidView.gd` has no tutorial branch (`grep -n tutorial game/screens/RaidView.gd` — none) and `Results.gd` none. W5-SIM lands `force_mistake_round` (M5-TUT-12), so the scripted mistake WILL fire on round 3 — and the account will show it as any other MISTAKE stamp.
**Doc** docs/01 §8.1 (what each tutorial teaches); docs/10 §9; 00-plan Q15: "should A0's scripted round-3 mistake and TR's 'read the Wipe Report' be surfaced on RaidView/Results (a one-line callout band over the log), or stay as Board blurbs?" Recommended default: yes — one `Widgets.callout` band above the log on a tutorial encounter only, with the encounter's own lesson line, and on TR's Results a second line above the tally: "This is the Wipe Report. Everything that went wrong is under 'By raider'."
**Fix** RaidView `_build()` adds the band when `Reputation.is_tutorial_slot(encounter.slot)`; Results likewise; both strings come from the encounter record (a `lesson` field) so the writing pass owns them. Tests in test_raid_beats / test_results.
**Owns** game/screens/RaidView.gd, game/screens/Results.gd, data/encounters_tutorial_t1.json (a `lesson` key), sim/model/Encounter.gd (loader), tests/unit/test_tutorials.gd
**Size** S
**Wave** 7 if Q15 is answered yes.
**Audit** M5-TUT-12 (relates), 00-plan Q15 (CRITIC-G14)

### LOOP-31 — The empty states are honest and in-world (a positive finding, with the two that are not)
**Status** CONFIRMED
**Evidence** Read on the `empty` and `fixture` sheets: Town "Nothing on the log yet." / "Raids and rests write here." (Cards.gd:51 `DAY_ONE_EMPTY` "Day 1. Nothing yet — the board is up the road."); Roster "No raiders yet. The Tavern is where a guild finds people." (Roster.gd:488); RaidPrep "No one is chalked. / Press a face on the bench to chalk them." and "No raiders to chalk. / The Tavern has candidates." (RaidPrep.gd:728-741); Market "Nothing found yet — raid first." (:596); Tavern "Nobody is drinking." (:713), "Nobody to manage." (:906); Facilities "Nobody lives here yet." (:220); Results "Everyone came home. This is unusual." (:502); RaiderDetail "No history yet. It starts filling on the first day that passes." (:811). Each says where the thing comes from. The two that admit unbuilt work are C12-C14 (RaiderDetail's backstory/wishlist) — listed above.
**Doc** docs/13 §15 "has an authored empty state".
**Fix** None beyond C12-C14. Add the `new` sheet (LOOP-01) so these are reviewed in the state a player sees them.
**Owns** —
**Size** —
**Wave** —
**Audit** KIT-08 (done)

## Unfinished-feature copy

The designer's ruling: hide these for now (hide the control or the callout that carries it, or replace the sentence with in-world copy that does not admit an unbuilt feature); by wave 10 nothing unfinished should be left to hide. Method: `grep` over game/ for the word list in the brief plus "arrive with / ships with / this build / this version / sign-off / not written", then every screen's empty-state and reason Labels read on the fixture and empty sheets. "Reachable" = a real player can see it in the shipped build (all 13 scenes exist, the Blacksmith flag is off, tiers 2-5 are unmounted). Treatment key: HIDE (drop the control/callout), REWORD (in-world sentence), BUILD-N (build the feature in wave N), KEEP (a true gate or a genuinely empty state, in-world), DELETE-10 (a dead defensive branch; remove in wave 10's housekeeping).

| # | String | File:line | Screen · when a player sees it | Reachable | Test pin | Treatment |
|---|---|---|---|---|---|---|
| C1 | "Canon lists this one as a maybe. Disabled in this build." | game/screens/Town.gd:567 | Town · the Blacksmith callout, always | YES (every visit) | test_screens.gd:311, :371; test_town_layout.gd:348 | REWORD → "Under construction." (the designer's own Q13 copy, Town.gd:110); retarget 3 pins. LOOP-02. Wave 6 |
| C2 | "Under construction." | game/screens/Town.gd:110 (`blurb`, unread) | — (dead field) | no | — | Becomes C1's visible reason. Wave 6 |
| C3 | "Not built in this version yet." (nav rail / tab / hub fall-throughs) | Town.gd:413, :577; AdventureBoard.gd:142; Guildhall.gd:184; Market.gd:171; RaiderDetail.gd:122; Roster.gd:647; Settings.gd:218; Frame.gd:130; Cards.gd:669 | any archetype-A screen · only if a scene file is missing | NO (all 13 scenes exist; `ScreenRouter.screen_exists` guards) | test_screens.gd:380 (Town, flag-on state); test_a11y.gd:521/588 and test_kit3/test_widgets_kit (kit strings, own) | DELETE-10 with the guards, or KEEP as dead branches. Never shows |
| C4 | "Raid prep is not in this version yet." | Town.gd:426; AdventureBoard.gd:862 | Town/Board · only if RaidPrep.tscn missing | NO | — | DELETE-10 |
| C5 | "The town is not built in this version yet." / "The guild slots are not in this version yet." / "Settings are not in this version yet." | MainMenu.gd:125, :147, :161, :171; Settings.gd:634 | Main menu / Settings · only if a scene is missing | NO | test_full_loop.gd:411 (accepts either this or "No saved guild found.") | DELETE-10; loosen the loop test to "every disabled button has a Reason Label" |
| C6 | "Settings are unavailable in this build." / "Settings are unavailable — the GameSettings autoload is missing." | Settings.gd:650; :299 | Settings · only without the autoload | NO | — | KEEP (boot-failure copy) |
| C7 | "Development build" | MainMenu.gd:272 | Main menu footer · when the version key is unset | NO in an export (`export_build.sh` sets it; sheet reads "Version 0.1.0") | test_menu_lockup.gd:237, :241 | KEEP; verify the export sets the key (M6-EXP-02 acceptance) |
| C8 | "The credits are not written yet. Who this game credits — and the attribution its fonts, tools and any sourced assets owe — is a sign-off a person has to give, recorded as docs/15 Q-21 and audit M5-END-4." | data/credits.json `status`; Completion.gd:104 | S17 · every completion (and Records' re-read) | YES once tier 5 ships; today only via `--completed` | test_menu_lockup.gd:319; test_screens.gd:577 | HIDE the paragraph (print the roster block only) in wave 6; BUILD-10 = the designer signs the roll (M5-END-4). LOOP-27 |
| C9 | "There is nothing to record until you have raided. The board opens at Known." | Guildhall.gd:52 | Guildhall · Records tab reason at Unknown | YES (Day 1) | test_roster_layout.gd:320; test_starting_roster.gd:228 | REWORD → one sentence shared with C10/C11 ("The record wall opens at Known."). LOOP-15. Wave 6 |
| C10 | "Opens at Known." | Cards.gd:663, :667 | every hub screen · the event log's "View All" at Unknown | YES | — | KEEP (true gate); rename the link "Records" or route it to the full feed. LOOP-15 |
| C11 | "The board opens at %s. The town has to have heard of you first." | sim/core/Achievements.gd:723 | Records tab body · a locked state that reaches the tab | edge | — | REWORD to the shared sentence. Wave 6 |
| C12 | "Wants nothing in particular. Backstories arrive with the Tavern; wishlists with the loot module." | RaiderDetail.gd:760 | Raider detail · every starting raider (no backstory, no wishlist) | YES (Day 1, all six) | none | REWORD: drop the hint; draw backstories for starters (LOOP-17). Wishlists: BUILD-8/9 or cut (Q59-3). Wave 6 |
| C13 | "Nothing is written down about them yet. Backstories arrive with the Tavern." | RaiderDetail.gd:765 | Raider detail · a raider with a wishlist but no backstory | NO today (no wishlists exist) | none | REWORD to the first sentence only. Wave 6 |
| C14 | "Wants nothing in particular. Wishlists arrive with the loot module." | RaiderDetail.gd:773 | Raider detail · every recruit with a backstory (all Tavern hires) | YES | none | HIDE until the module exists. Wave 6 |
| C15 | "%d of %d live in this build" ("13 of 17 live in this build") | Settings.gd:290 | Settings header · always | YES | test_options_layout.gd:360-368 counts ROWS (not the header) | HIDE. LOOP-26. Wave 6 |
| C16 | "The type pass ships the second family." | Settings.gd:95 | Settings · Prose font swap row, always | YES | — | HIDE the row (Q16 owns what the option means). Wave 6 |
| C17 | "Display options arrive with the export build." | Settings.gd:102 | Settings · V-sync row, always | YES | — | REFUTED as a reason (the export exists): BUILD-6 (wire `DisplayServer.window_set_vsync_mode`; the key `vsync` exists, GameSettings.gd:48) or HIDE. Wave 6 |
| C18 | "The bus is here and waiting; no music is written yet." / "…nothing is voiced yet." | Settings.gd:106, :110 | Settings · the music and voice slider notes, always | YES | — | HIDE the notes (the sliders work). Music: BUILD-8/9 or cut (M6-AUD-05, designer). Wave 6 |
| C19 | "One language so far." | Settings.gd:112 | Settings · Language row, always | YES | — | HIDE the row until a second language exists. Wave 6 |
| C20 | "Gamepad support is not in this build." | Settings.gd:115 | Settings · Controller glyphs row, always | YES | — | HIDE the row; BUILD-8 if OQ-12 says 1.0 (the focus model is done; the button map is the S half). Wave 6 |
| C21 | "Disabled rows say why beside them. Nothing here is a build flag; those live in data/tuning." | Settings.gd:616-617 | Settings sidebar · always | YES | — | HIDE the second sentence (a repo path). Wave 6 |
| C22 | "Chalk tonight's twelve from the Adventure's Board." | Guildhall.gd:49 | Guildhall · the Raid Group tab, always disabled | YES | test_roster_layout.gd:296, :319; test_starting_roster.gd:224 (tab label list) | HIDE the tab (LOOP-14); retarget 3 pins. Q18/HALL-21 decides whether it ever returns. Wave 6 |
| C23 | "Legendary (%s) — name pending" / "%s %s — name pending" | sim/core/Recruitment.gd:295-299; data/legendaries/*.json `name_pending` | Tavern · a Legendary candidate (find weight 15/1000 at Renowned; unnamed recruits only if names.json is absent) | practically NO in tier 1 (Renowned = 1,800 RP) | test_legendaries.gd:79; test_recruitment.gd:335; test_names_and_backstories.gd:325 | BLOCKED-designer (docs/03 §5.6 forbids inventing). Ships when BL-69 names land (wave 8-9). Until then unreachable |
| C24 | "Main Boss" as the boss's only name (RaidPrep card sub-line, RaidView plate) | Enums.encounter_kind_name_of; RaidPrep.gd:446-448; RaidView boss plate | RaidPrep / RaidView · every E5 / TR | YES | — | BLOCKED-designer Q12a (COMBAT-05: may "Main Boss" become a creature name?). REWORD interim: print the encounter's display_name only, never the kind as a name. Wave 6 (interim) / 8 (names) |
| C25 | "Nothing has been run yet. The board is where a raid starts." / "No account was written." / "Nothing worth writing down." | Results.gd:249, :318, :1113-1117 | Results · without a result (tests/shots only) | NO | — | KEEP |
| C26 | "No guild loaded." / "The guild has no content loaded to pin." / "No notices — the guild has no content loaded to pin." / "Content is not loaded." / "This class has no equipment profile." | Frame.gd:596; Town.gd:463; AdventureBoard.gd:603, :879; RaiderDetail.gd:470, :477; Market.gd:537; Tavern.gd:265; Roster.gd:626 | any screen mounted without a state/content (the `empty` sheet) | NO in play (Boot loads content before routing) | test_screens empty-mount tests | KEEP (defensive) |
| C27 | "Your guild is not known enough for tier %d work yet." | RaidPlan.gd:408 | Board · a mounted tier above the rank | NO until tiers 2-5 mount | — | KEEP (in-world gate); becomes reachable with content |
| C28 | "Unlocks once you have cleared this one." | RaidView.gd:638 | RaidView · Skip to the end on a first attempt | YES | test_full_loop.gd:221 | KEEP (true gate) — but see LOOP-10: the gate is decorative while the exits are live (Q12c) |
| C29 | "The party stands here" | RaidPrep.gd:74 | RaidPrep · the empty arena band, always | YES | none | HIDE the caption; BUILD-7 the party on the floor (LOOP-09) |
| C30 | "Unknown guilds cannot commission this. Reach Known." / "Costs N G — you have M." / "Sold out for today." / "The roster is full at N." / "They are fine." | Tavern.gd:754-758; Market.gd:757-846; Facilities.gd:438-468; Roster.gd:624-637; Buildings.entry_blocker | every shop · true gates | YES | various | KEEP — except "They are fine." (LOOP-16: the gate is wrong, not the wording) |
| C31 | "Lv. N" | Cards.gd:143-144; RaidView.gd:991-992 | cards · only when `raider.level > 0` (fixture only) | NO in play | — | KEEP; Q11 decides; the fixture misleads reviewers (LOOP-01) |

Not in game/ but printed by it: `data/tier_words.json` tiers 2-5 `pending: true` (nothing prints them — the tiers are not mounted); `data/encounters_t2..5.json` `stats_pending`/`name_pending` (same); `data/mistake_lines.json` (the corpus — SIM/COMEDY's area; any template that reads as a placeholder is theirs to list).

## Shippable bar

A reviewer ticks these on a NEW guild (the `new` sheet, LOOP-01), not on the fixture.

**A first-time player reaches the Tier 1 ending without reading a doc**
- [ ] `tools/playtest.gd` walks New Guild → A0 → TR → A1 → A2 → A3 → E1..E5 without a skip and without a stuck state (M6-BAL-04, M6-BAL-03 ruled; LOOP-24).
- [ ] After E5 the board and the hub say what is next — the next tier (waves 8-9) or an honest end-of-road sentence (LOOP-07); the hub never pins a CLEARED mission as "Next mission".
- [ ] No screen promises content or a building the build does not mount (LOOP-06).
- [ ] The guild has a name the player chose or was given (LOOP-23).

**Never a dead control without a reason**
- [ ] A gate test over all 13 routes on a new guild: every disabled `Button` has a "Reason" Label in its `reasoned` box or adjacent (extend `test_full_loop.test_every_disabled_control_explains_itself` from the menu to every screen; C5).
- [ ] No permanently disabled control exists (Raid Group tab, Prose font swap, Language, Controller glyphs, V-sync — hidden or working; LOOP-14, LOOP-26).
- [ ] A locked control's reason is a condition the player can meet ("Reach Known", "Costs 130 G — you have 60", "Unlocks once you have cleared this one"), never a statement about the build.
- [ ] The RaidView skip lock and the exits agree (Q12c; LOOP-10).

**Never a state with no way forward**
- [ ] `_can_still_make_progress()` (W5-TESTS) is green on every state the playtest and the loop tests reach, including after a disband and after a departure.
- [ ] Disband is preceded by the §6.3 banner and modal; after it the town states what happened and what to do (LOOP-25).
- [ ] "Cheer up" is never refused on a fixed band; rest says when it cannot help (LOOP-16).
- [ ] The Tavern can always sell a first hire to a broke guild, or the rule that prevents that is the designer's (LOOP-19, LOOP-25).

**Every screen answers "where am I, what can I do, what happens if I do it"**
- [ ] Town: the next mission, the one crimson control, the rank's next promise (true), the roster's mood, the log.
- [ ] Board: notices by display name, the selected notice's facts (plural-correct, LOOP-04), its rewards, the reason it is locked in words a player has been taught (LOOP-03), the reputation countdown.
- [ ] Prep: comp / gear / risk with ONE headline word and ONE number that mean something (LOOP-08); the party visible on the arena (LOOP-09); provisions with icons (LOOP-29); Depart always available.
- [ ] RaidView: the mistake header and joke never cut (LOOP-11); a tutorial says what it is teaching (LOOP-30, Q15).
- [ ] Results: the cause of the wipe in one sentence (LOOP-12); reputation earned (LOOP-13); loot with a suggested split; a way back to the board and to town.
- [ ] Guildhall / Roster / Detail: morale in the canon two-line format everywhere (holds today); backstories on every raider (LOOP-17); no sentence about a module.
- [ ] Tavern / Market: prices on one scale (LOOP-19), numerals with separators (LOOP-21), building levels that show their change or do not promise one (LOOP-20).
- [ ] Settings: only options that work (LOOP-26). Completion: no status paragraph (LOOP-27).
- [ ] Header: gold, roster, day, rank — and the reputation number labeled or replaced by pips (LOOP-05, Q06).

**Copy**
- [ ] `grep -rniE "not in this version|this build|not built|not written yet|name pending|loot module|arrive with|arrives with the|maybe" game/screens game/ui game/core` returns only C3-C7 (dead branches) or nothing (wave 10).
- [ ] Every string in the Unfinished-feature table is HIDE-d, REWORD-ed or BUILT, and the test that pinned it was retargeted, not deleted.

**Keyboard**
- [ ] Every §13.1 binding does something on the screens the row names, or the row is struck from §13.1 (LOOP-22).

## Questions for the designer

Only the ones this report cannot answer with a recommended default. Each names the finding and the register row.

1. **Q12c — may the player leave the account mid-fight on a first attempt?** Today "The report" and "Back to the board" are live from round 1 and the skip lock is decorative (LOOP-10). Recommended: gate the exits on a first attempt (the switch exists). If "no", strike docs/01 §9's first-clear rule for Instant and unlock "Skip to the end" always.
2. **The Tutorial Raid (M6-BAL-03) and the morale floor (M6-BAL-04).** LOOP-24 records what the shipped numbers do to the first hour: wipe TR, skip it, disband armed, six Commons at 45 who cannot clear A2. Both are yours; the report recommends TR winnable at ≥ 8/20 and tutorial wipes costing no morale, and leaves the A2 lever to you.
3. **Q-60 — recruit price scale.** The register recommends doc 11's (Common 15 G); the tree ships doc 04's (60 G) with no switch. May the loop land the register's default behind `PRICE_SCALE`? (LOOP-19)
4. **docs/04 Q3 / docs/09 §10.2 — do Commons arrive armed?** "no weapon" and "Damage 0" on Day 1 (LOOP-18). Recommended: docs/01 §8.0's 0-stat placeholder weapon, named per class family.
5. **Q06 — the reputation chip.** Gem or sigil; does it carry a word ("Rep") or become the six pips? (LOOP-05)
6. **Q18 / HALL-21 — the Raid Group tab.** Retire it, or a read-only view of the last chalked party? Hidden either way in wave 6 (LOOP-14).
7. **Q15 — tutorial lessons on RaidView/Results.** Yes/no to the one-line band (LOOP-30).
8. **Q12a — creature names.** "Main Boss" is the boss's only name on prep and in the fight (C24). Interim: print the encounter name only.
9. **Disband: game over or recoverable?** (docs/05 §12 Q5, docs/01 OQ#2.) LOOP-25 recommends recoverable with a solvency floor (a free first hire when gold < one Common) — that floor is a new rule and needs your yes.
10. **The wipe's culprit rule.** docs/01 §6.1 names "the raider whose mistake triggered the wipe" without defining it. LOOP-12 proposes: the last Severe mistake before the first tank/healer death, else the deepest cascade, else "nobody". Accept, or give the rule.
11. **Tiers 2-5 names (BL-69), the eight Legendary names (docs/03 §5.6), the credits roll (M5-END-4), music (M6-AUD-05).** Not new; listed because every one of them is a string a player will otherwise see (C8, C23) or a promise the board makes (LOOP-06).

## Coverage

**Read (docs):** BUILD_STATE.md (Current focus, HANDOFF, binding decisions); docs/13 in full (§5 inventory, §6-§7, §8, §9 wireframes, §10-§12, §13/§13.1/§13.2, §14-§16); docs/01 §4 (state machine), §5.3, §6, §8 (onboarding), §9; docs/02 §9-§11; docs/03 §7; docs/05 §6.1-6.3; docs/11 §4.2/S1; docs/15 Q-29, Q-60, the §9 register note on Recruitment; build/plan/artaudit/00-plan.md §0.6 and §6 (the 18 designer questions); build/shots/_w5_args.json.
**Read (code):** game/core/ScreenRouter.gd (all), GameState.gd (new_game, _on_screen_changed, autosave sites, _award_reputation, rest_until_recovered, use_indulgence, rung_resolved, log_event sites), RaidPlan.gd (all), StartingRoster.gd; game/screens Town.gd (all), AdventureBoard.gd (rung, facts, sidebar, skip, standing, completion goal, selection, locked_reason), RaidPrep.gd (scene, sidebar, provisions, refresh, readout, depart), RaidView.gd (exits, skip gate, log line construction), Results.gd (headline, empty states, cause line), Guildhall.gd (tabs, reasons), Roster.gd (rest, cheer up, manage), RaiderDetail.gd (written, cheer up), Market.gd (reasons, placement, stall), Facilities.gd (hall card), Tavern.gd (reasons), Settings.gd (ROWS, header, sidebar), MainMenu.gd (reasons, new game), LoadSave.gd (blurbs), Completion.gd (credits); game/ui Frame.gd (chips, standing tip), Cards.gd (recent_events, view_all, level), SceneStage.set_lines; sim/core Reputation.gd (thresholds, unlock), Recruitment.gd (cost, placeholder name, pity), RaidSim.gd (SimResult), Achievements.unlock_reason, Comfort (indulgences), Consumables.stall_look, ContentDB (tier_is_named, default_paths); data/reputation.json, tier_words.json, credits.json, encounters_t1/tutorial, legendaries/*, stage_camp.json (speech); project.godot InputMap.
**Read (tests):** test_full_loop.gd (walk, dead-end and disabled-control tests), test_tutorials.gd (the TR pin and its history), test_ladder/test_raid_plan (locked_reason pins), test_screens (Blacksmith, "120 more to Known"), test_town_layout, test_roster_layout, test_starting_roster, test_menu_lockup, test_recruitment (cost table), test_legendaries, test_a11y (bindings, focus), test_options_layout (ROWS), test_kit3/test_widgets_kit (kit strings), test_savegame (played_seconds).
**Read (sheets):** fixture: Town, AdventureBoard, RaidPrep, RaidView, Results, Guildhall, RaiderDetail, Tavern, Market, Settings, Completion; empty: Town, MainMenu; raid-clear: Results_clear. Not opened: LoadSave (either sheet), the empty sheet for the other 11 screens (they are "No guild loaded" mounts — C26), focus, text150, emoji, reduced, wide-keep, wide-expand, tabs (Facilities/Records/Manage/Buy/Comfort), raid-advanced (the WIPE beat).
**Not done:** no Godot run (the mutex); no new-guild sheet exists to read (LOOP-01) — every Day-1 claim is from code, not a picture; tools/playtest.gd was not re-read beyond BUILD_STATE's account of where it stops; the Facilities tab, Records tab, Tavern Manage and Market Comfort/Buy tabs were read in code only; LoadSave and the 150%/emoji/reduced/wide variants were not judged; the mistake-line corpus and encounter comedy lines were not swept for placeholder wording (COMEDY/SIM's); the gamepad map was not assessed beyond "bound, unhandled"; Legendary quirk copy (Q58) and the achievement records' names/blurbs (M5-QAB-2) were not read.

