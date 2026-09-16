# RULINGS — the delegated determinations of A Guild Story, consolidated (2026-09-15)

Consolidated from `build/plan/ship/rulings/{BALANCE,COMBAT,CONTENT,GUILD,SCREENS,SHIP,STAGE,UX}.md` and `rulings/CRITIC.md` under the designer's 2026-09-15 delegation ("you make all of the determinations and decisions left for me, intelligently and based on the game's intended design inspirations"). Read-only on the tree except this file. Every row of `00-plan.md` §6 (67) and §7.1 (24 rows in the table; the plan's own count says 25) is ruled here; nothing below is open, TBD or the designer's. The critic's fourteen amendments are applied as written (§9 says where); none was refused. docs/_source is not edited — the one canon number moved (the daggers) is recorded in §4 and in Q-36's row.

Sections: §1 Headline · §2 The answered designer table · §3 The deferrals, ruled · §4 Canon numbers changed · §5 Register rows · §6 Plan edits · §7 The names · §8 Tensions · §9 The critic's amendments, applied.

Register numbering: docs/15 runs to BL-109 and Q-99 at HEAD; new rows are BL-110..BL-143 and Q-100, assigned in §6-order below; existing rows keep their ids and are amended (status line + text) rather than duplicated.

## 1. Headline

1. **The on-ramp lever is (c), by one written rule, and the numbers are these.** A0, TR, A1, A2 and A3 are re-sized for the roster a new guild actually brings — all-Common, stage 0 (canon starting armour), morale 45 — by docs/08's new §9.3a healed clock (`hp = stage-0 nominal DPS × target_rounds × 0.924`; `swing = (tank HP ÷ fight length at 29.8 % + HEAL_FLOOR 6) ÷ (1 − 18.9 % mitigation)`): A0 **61 HP · 20 raw**, TR **183 · 8 ×2 · M03 fire 13/rd 50 %** (M01 gone), A1 **3 × 41 · 7 ×3 · M04**, A2 **2 × 76 · 9 ×2 · M04 + M02 15/4**, A3 **183 · 8 ×2 · M02 · M03 · M04 {15 HP, r6}** (M01 gone; E3 is the first swap). The −5 Common offset, the 60 G purse, the 150 G Guildhall and the wipe deltas do not move; the attrition grace is named at **5** (load-bearing); Adventure rungs roll **2 items per loot slot**; the tutorial rate is **A0 0.0 / TR 0.5**; `SWING_PRICES_MECHANICS` is not built; the harness farms the Adventure before the raid door. W8-SIM-BALANCE, after W8-ITEMS's regeneration.
2. **The first wipe survives, and Tier 1 is completable.** Curve (first-attempt clear, 200 seeds): A0 ≥ 90 · TR 55 · A1 75 · A2 65 · A3 50 at morale 45 (the fresh guild; FAIL from wave 8) and E1 ≥ 90 · E2 ≥ 80 · E3 75 · E4 60 · E5 40 at morale 55 (the farmed guild; WARN until wave 9). P(a fresh guild reaches the raid door without a wipe) ≈ 13 %; P(E5 in ≤ 3 attempts) = 78 %. The Forgiving Guild toggle ships (`DIFFICULTY_MULT` 0.75, off by default) and is not the fix.
3. **Focus is out of 1.0 with its numbers decided; M10 ships as Silence.** `FOCUS_MAX` 100/100/100/100/100/60 (Cleric/Druid/Shaman/Mage/Wizard/Bard), regen 7/7/7/8/8/5, cast costs 9/14/12/11/10/the song's, class-fixed and never on gear; drain default 10 per round when the 1.1 unit lands; `FOCUS_ENABLED`/`MANA_BURN_DRAIN_ENABLED` stay false.
4. **Three kits come in; the Wizard Ramp stays out; the daggers rise one point; the ninja pull is built, not cut; the nine quirks are specced.** W9-KITS lands Monk Guard (threat 3.0, +7 AC, melee ×0.5, Taunt on entry), Rogue Front (0.77 while the boss faces him; Behind 1.0), Mage Raid Spell Buff (+2 spell damage per cast to every Mage/Wizard, non-stacking), and the Bard as Q-46 tables it (`BARD_S_DIVISOR` 10). Basic/Strong Raid Dagger +4/+6 → **+5/+7** (the one canon number changed, Q-36), `DAGGER_OFFSET` −1, no `DAGGER_SWINGS`. E4's M05 `raid_damage 27`, M08 `rounds 2 every 6`, M09 `round 3 every 6`. The break-phase MIS_NINJAPULL roll fires at Depart (W8-CRISIS) and the sim honours it (W8-SIM-BALANCE). Nine `Quirks.SPECS` rows ship on (W9-QUIRKS).
5. **The names are the loop's, in Natsuna's register.** Legendaries: Gunnar (Warrior) · Ottilie (Cleric) · Alder (Druid) · Natsuna (Shaman, canon) · Solenne (Mage) · Casimir (Wizard) · Tallis (Rogue) · Isaura (Monk) · Lorcan (Bard). Tier words T2-T5: Steel/Silvered/Adamant/Runegold · Runeweave/Starweave/Stormweave/Voidweave · Hallowed/Sanctified/Anointed/Exalted · Vanquisher/Conqueror/Ascendant/Immortal (`raid_adj` = `raid_title`) · leather Studded/Hardened/Masterwork/Flawless. Twenty-one boss-rung titles from The Doorman to The Last Word on the boss plate and the prep card; the log keeps "Main Boss". The currency is gold, "G". Pauline_4 stays Pauline_4.
6. **The Blacksmith is out; so are upkeep, wishlists and traits.** The facade stays locked behind "Closed. The smith took a better offer."; "Sharpened, Finally" becomes "Pocket Change" (ten items sold); the flag stays a declared post-1.0 door. Upkeep's fork is ruled for 1.1 (a payday every 7 Day Ticks; 1/1/2/3/4 G per raider by rarity; the bench pays) and stays out of 1.0 because the save freezes at v17. "Buy a round" is cut. The record wall pays 15 RP per reputation-kind record.
7. **Music is the generated sparse lute; the scribe's quill is real; the world stays silent.** `gen_music.py` (Karplus-Strong string, A minor pentatonic; Unknown rubato, Known adds a frame drum at 66 BPM; −34 dBFS RMS) plays under the camp family and the main menu behind `Audio.MUSIC_BED = true` — W10-BUFFER's first item, cut in writing if the buffer is consumed. `ui.quill` under every log line on the Voice bus ("Audio — the scribe", W8-AUD-OPT). Five ambience beds including `amb_dungeon` (W7-AUD-AMB); the WIPE stamp `ui.stamp` unjittered.
8. **Tiers 2-5 ship: 1.0 is the twelve-entry ladder, Adventure 0 through Raid 5.** S17 fires on the first clear of Raid 5; `tier_is_named` stays as a top-down valve (a tier proved uncompletable at its own gear stage over eight seeds flips its `pending`, never back to Tier 1). The town dresses to Legendary rank (walkers, lanterns, pennant → notice post → cobbles → statue + braziers → second tent, guards, crest pennants); the Legendary 5 % collection endgame is accepted; every enemy stands at 2x with the party (`marks.boss.scale` 2).
9. **Provenance is signed on the designer's behalf, and the export gate goes green.** The nine `ideaboard/` screenshots are the designer's own drafting tables (this game's classes and items, dated 2026-08-27, in a folder the designer named after themself), the six plates the designer's own; `PROVENANCE.md`'s eight rows carry the facts and `Signed: the build loop for the lead designer (Malkail), under the 2026-09-15 delegation`; the README and store copy disclose the AI-generated code, art, copy and sound and the image-model references. W10-EXPORT.
10. **The credits name someone.** Seven lines — "Malkail — lead designer" first, the build loop and tooling honestly, "Sound and music generated in-house from physical models" (or "Sound …" if the lute sheds), Godot MIT, the two OFL faces, and "The raiders would like it known that they did their best." `© 2026 Malkail`, version `1.0.0`; the .exe unsigned with the two SmartScreen clicks in `README-player.txt` and the zip's SHA-256 in the release record; a gamepad works unverified and unsupported; English only.

## 2. The answered designer table

§6 reproduced, with **Ruling** (one sentence) and **Register row** (the docs/15 id; new ids BL-110+ / Q-100, existing ids amended). "Applied by" is the unit after the critic's re-homing (A6-A13); where it differs from the plan the plan's unit is struck. The three rationale parts (inspiration / canon / cost) for every row are in the batch file named in the Ruling column's prefix; §5 carries the register text.

| # | Row | The question | Needed by | Ship default (wave 10) | Applied by | Ruling | Register row |
|---|---|---|---|---|---|---|---|
| 1 | DESIGNER-01 / M6-BAL-04 / SIM-19 / CONTENT-08 / LOOP q2 | Which lever moves so a new guild can climb the on-ramp: (a) Common baseline −5 → 0, (b) first facility at start, (c) size A1-A3 and the tutorials for 45, (d) smaller wipe delta — and the number | end of wave 7 | (c), derived by docs/08 §9.3's formula with the mechanic term (CONTENT-08's HOW); alternative (a) on the page; "taken under the wave-10 ship rule", a BL row, `Formulas.SWING_PRICES_MECHANICS` switch | W8-SIM-BALANCE (after W8-ITEMS's regeneration; `tools/playtest.gd` moves here — A12) | BALANCE #1: lever (c) — the five on-ramp rungs re-sized by docs/08 §9.3a's healed clock at stage 0 / all-Common / morale 45 (A0 61·20; TR 183·8×2; A1 3×41·7×3; A2 2×76·9×2; A3 183·8×2), the −5 / 60 G / 150 G / wipe deltas unchanged, `SWING_PRICES_MECHANICS` struck, the harness farms the Adventure before the raid, derived under an attrition grace of 5 (A11). | **BL-110** (new); BL-30 superseded; BL-28 stands |
| 1b | Loot.rolls_for (Adventures) / docs/10 §4.2 | (raised by BALANCE) How long the farm takes | — | — | W8-SIM-BALANCE (`sim/core/Loot.gd` added) | BALANCE #1b: an Adventure rung rolls two items per declared loot slot (`Loot.ADVENTURE_ROLLS_PER_SLOT = 2` — A1 4, A2 4 with the off-hand slot, A3 4); the raid's 2/2/2/3/3 untouched; 36 clears become 18. | **BL-111** (new) |
| 2 | DESIGNER-02 / BL-69 / CONTENT-04 / SHIP-04 / SHIP q3 | The twenty tier words (material / cloth / healer / raid_title / raid_adj × T2-T5) and whether leather keeps its own column | end of wave 7 | none inventable — Tier 1 only ships, S17 fires on the Raid 1 clear, the pending files move to `data/_pending/`, a BL row and a README line | W8-ITEMS (words, L branch certain) · W9-TIERS (long branch) | CONTENT #2: the words are ruled (§7) and leather keeps its own column (Reinforced · Studded · Hardened · Masterwork · Flawless), so all five tiers mount; the Tier-1-only fallback is not built. | Q-41 / BL-69 amended (RULED) |
| 3 ★ | DESIGNER-03 / CONTENT-17 / CONTENT q2 | The eight Legendary names; is "Natsuna" final | with #2 | unfindable: `name_pending` Legendaries never appear on the board; the meter reads N-of-named; Natsuna ships | W8-ITEMS | CONTENT #3: Natsuna is final and the eight are Gunnar, Ottilie, Alder, Solenne, Casimir, Tallis, Isaura, Lorcan — given names fitted to the files' own characters; the `name_pending` fallback is not built. | **BL-117** (new) |
| 4 ★ | DESIGNER-04 / Q-21 / SHIP-17 / SHIP q2 | Are the nine ideaboard screenshots and the six bare plates your own work, and under what terms may they ship | end of wave 9 | the gate holds; `--dev` ships to the designer's machine; README states "provenance unconfirmed" | W6-SHEETS (the gate) · W10-EXPORT (the signature; `PROVENANCE.md` added) · W10-CREDITS (docs/00 §4.4) | SHIP #4: yes — the screenshots are the designer's own drafting tables and the plates their own; every `PROVENANCE.md` row gets an `Answer:` and a `Signed:` line on the designer's behalf in wave 10, `test_export.gd:403-416` is deleted the same commit, the gate goes green, the README says "provenance recorded" and the store copy carries the AI-content disclosure. | Q-21 amended (RULED); C-32 closed |
| 5 ★ | DESIGNER-05 / M5-END-4 / SHIP q1 / UI q3 | Who the game credits (names, roles); approve the drafted attribution block; the copyright holder and the version string | end of wave 9 | the derivable block under "Credits" with no names; copyright "holder pending"; version 1.0.0 | W10-CREDITS · W10-EXPORT · W10-README | SHIP #5 (A5): the seven-line roll led by "Malkail — lead designer", line 4 "Sound and music generated in-house from physical models" while `Audio.MUSIC_BED` is true, closing "The raiders would like it known that they did their best."; `© 2026 Malkail`; `1.0.0`; the disclosure sentence in README/README-player/docs/00 §4.4.2. | **BL-132** (new); M5-END-4 closes |
| 6 | DESIGNER-06 / Q-53 / SHIP q4 / UI q5 | Attempts unlimited and the attempt committed before playback — confirm; Esc mid-replay skips to the report; reload after a mid-replay quit lands on Results; "Try again" on the wipe page | wave 7 | as built + the three recommendations | W7-REPORT · W7-SAVE | UX #6: kept in full — unlimited attempts committed at Depart, `Results.TRY_AGAIN = true` default-focused, Esc → the post-mortem, Continue re-runs the stored seed to Results (`active_run` now also carries `difficulty_mult` and `ninja_pulled` — A10); docs/01 §6.1's 25 G retry fee stays unbuilt. | Q-53 amended (RULED) |
| 7 | DESIGNER-07 / Q-29 | Does a recruit's rolled gear price the recruit: +15 %/piece, none, other | end of wave 7 | `Recruitment.GEAR_SURCHARGE_BP = 1500` default ON | W8-ITEMS | BALANCE #7: yes — +15 % per `raid`-source piece beyond the first, rounded to 10 G, "well-equipped" on the card; Commons through Rares never carry raid pieces so the Tier 1 walk does not move. | Q-29 amended (default taken) |
| 8 | DESIGNER-08 / BL-53 / M5-COMEDY-12 / CONTENT-16/21 / CONTENT q9 | The two human reads: sign the name pool; the comedy — sign / rewrite lines / cut lines; who reads and when | wave 9's close | ships as validated with a BL row stating the human gate was not passed | W9-REVIEW (M) | CONTENT #8: the loop is the named reviewer — W9-REVIEW's reviewing agent (not the writer) does the keep/rewrite/cut pass in-wave against docs/07 §10.3 and docs/04 §7, applies the marks, and BL-53 and the comedy gate close as reviewed-under-delegation with docs/16 R-3's residual risk recorded. | BL-53 RESOLVED; **BL-118** (new, the comedy gate) |
| 9 | DESIGNER-09 / M6-BAL-03 / SIM q2, q9 | The target clear-rate curve; TR's swing and M01 on a one-tank party | end of wave 7 | the proposed 100/100/100/100/75 curve; the switch stays true; A3 sized by #1's formula rather than swapped | W8-SIM-BALANCE (on-ramp bands FAIL) · W9-TIERS (raid bands FAIL) | BALANCE #9 (A3, A14): A0 ≥ 90 · TR 55 (40-70) · A1 75 (65-85) · A2 65 (55-75) · A3 50 (40-60) measured at morale 45, and E1 ≥ 90 · E2 ≥ 80 · E3 75 (60-90) · E4 60 (45-75) · E5 40 (30-55) measured at 55; the correction rule (too hard: swing −1 ×3 then the ½-pulse; too easy: `target_rounds` +2, two steps on the on-ramp, ONE on E1-E5); TR's M01 → M03 (the fire) and A3's M01 → M04; `TANK_SWAP_NEEDS_A_PARTNER` stays true and dormant; the validator refuses m01 below two tanks; A3 is expected to land under TR on the first pass. | **Q-100** (new); BL-85 closes; BL-91 closes |
| 10 | DESIGNER-10 / Q-13 / LOOP-02 / UI-01 / CRITIC-C4 | Is the Blacksmith in 1.0 (upgrades-only) or out; the callout's copy | end of wave 6 | (b) out: "Closed. The smith took a better offer." | W6-COPY (landed) · W7-SAVE (the achievement swap — A9) · W7-DOCS (the rows) | CONTENT #10: out of 1.0 — the line at `Town.gd:119` is final, the five Q-13 sub-rows close post-1.0, and the unreachable "Sharpened, Finally" record becomes "Pocket Change" (economy, ten items sold, the same five potions); §9's optional "Blacksmith yes" is recorded as not taken because canon's own line is "Maybe" three times. | Q-13 amended (RULED; §9's line not taken) |
| 11 | DESIGNER-11 / Q59-5 / Q-31 / SIM q12 | Upkeep and payday: not in 1.0 / per-run by rarity / payday every N ticks | wave 7 | not in 1.0 (condition 5 stays false) | W7-DOCS (the row; the `#q-31` duplicate anchor repaired) | BALANCE #11: not in 1.0, and the fork ruled for the first post-ship economy pass — a payday every 7 Day Ticks, Tier 1 wages 1/1/2/3/4 G per raider per payday by rarity × 2.4 per tier, the bench pays, an unpayable payday is paid to 0 G and counts a miss, two misses = condition 5. | Q-31 / BL-59 row 5 amended |
| 12 | DESIGNER-12 / M5-END-5 | The Legendary 5 % find rate at a rank with nothing left to serve | wave 7 | accept, recorded | W7-DOCS (the row) | GUILD #12: accept — the 9-of-9 collection is the endgame; the 5 % and the 3200 RP threshold stand (≈ 180 candidates, ≈ 30 boards); with five tiers mounted Renowned pays and nothing retimes. | **BL-122** (new); M5-END-5 closes |
| 13 | DESIGNER-13 / M5-QAB-4 / Q-69 | Does the achievement board pay reputation | wave 7 | no | ~~W7-DOCS~~ W7-SAVE (the data/flag/branch — A9) · W7-DOCS (docs/03 §6.1) | GUILD #13: yes — the two reputation-kind records pay 15 RP each, `FLAG_DEFAULTS.achievement_rp = true`, board RP live-capped at 15 % of RP earned; 2815 + 30 + 325 = 3170 < 3200 so Legendary still lands on Raid 5. | Q-69 amended (board half RULED); M5-QAB-4 closes |
| 14 | DESIGNER-14 / Q58-1 / Q58-3 / BL-58 / SIM q10 / CONTENT q6 | The nine Legendary quirks: inert / spec / edit | end of wave 8 | inert, displayed, flag off | W7-SIM-EFFECTS (the seam) · W9-QUIRKS (bought, M) · W9-TIERS (the flag flip) | COMBAT #14: all nine specced in the four-hook shape — Warrior tank_priority + immune TAUNT_LAPSE; Cleric immune HEAL_WRONG/HEAL_CORPSE; Shaman immune CHAIN_FIZZLE; Druid threat ×0.50; Mage (renamed "Lets Sleeping Adds Lie") immune BROKE_CC; Wizard immune WRONG_TARGET; Rogue threat ×0.80; Monk relief 300 bp; Bard immune WRONG_SONG — no quirk adds output; `legendary_quirks` ships on. | BL-58 amended (DECIDED) |
| 15 | DESIGNER-15 / BL-42 | Roster cap: rank / min(rank, hall) / hall | wave 7 | rank | W7-DOCS | GUILD #15: rank — `ROSTER_CAP_BY_RANK` 15..20 is the one cap; docs/02 §4.3's 14/18/22/26 column is struck. | BL-42 amended (DECIDED) |
| 16 | DESIGNER-16 / BL-22 | Rarity vs morale dominance — accept, held for a Tier 2 re-measure | wave 8 | accept | W7-DOCS · W9-TIERS (a WARN line) | BALANCE #16: accept — morale is the short-term lever, rarity the long-term axis; W9-TIERS prints the Tier 2 cell as a WARN reading, no coefficient moves. | BL-22 amended (DECIDED) |
| 17 | DESIGNER-17 / Q-36 / SIM q11 | The Rogue's first raid drop is a downgrade: extra swings / raise the dagger / leave | wave 8 | extra swings (`DAGGER_SWINGS = 2`) | ~~W9-KITS~~ W8-ITEMS (two rows + `DAGGER_OFFSET` through `gen_items.gd`) | COMBAT #17: raise the daggers one point — Basic +4 → +5, Strong +6 → +7 (canon numbers changed, §4), `TierScaling.DAGGER_OFFSET` −2 → −1, `MELEE_SWINGS` stays 2 for all; every swing route doubled the Rogue or dethroned the Wizard; the two item notes carry "lighter than the sword — the Rogue will tell you that is the point" (critic Spirit 2). | Q-36 amended (DECIDED) |
| 18 | DESIGNER-18 / Q-33 | The healer's 1-AC Worn Leggings: rename / keep and tag by family | wave 7 | keep, tag by family | W8-ITEMS | CONTENT #18: keep the canon string byte-identical and print the family beside every shared display name ("Worn Leggings · Healer"). | Q-33 amended (RULED) |
| 19 | DESIGNER-19 / Q-35 / LOOP q4 / CONTENT-05/25 | Adventure off-hands and starter weapons: sign both / off-hands only / neither | wave 7 | sign both | W8-ITEMS | CONTENT #19: sign both — three Adventure off-hands per rung (Shield 4 AC/+5 HP, Lute +12 Mana, Tome 1 AC/+3 Mana; T2-T5 through the words, the Lute on the leather column), four Market starters at +3/+4/+4/+4 Mana (Chipped Sword lifted from +2) at 5/10/10/5 G, and seven "Borrowed" loaners at the floors (damage 2, heal 6) so Commons arrive armed and no golden moves. | Q-28 / Q-35 amended (RULED) |
| 20 | DESIGNER-20 / Q-22 | What the Established rank does: (b) as built / (a)+(b) with Market L4 | wave 7 | as built | W7-DOCS (one data line, two doc cells) | GUILD #20: (a)+(b) — Rare modal at the Tavern AND the Market L4 / Guildhall L3 purchases the ladders already gate at rank 3, named in `reputation.json`'s Established `town_unlock`; the Legendary row's phantom "Guildhall upgrade IV" becomes "Perfect potions" + "Legendary raiders, one in twenty". | Q-22 amended (RULED); C-05 closes |
| 21 | DESIGNER-21 + 35 / Q-14 / Q11 | Levels: no level-ups; Drilling in 1.0 y/n; the "Lv." label dormant or retired | wave 7 | no level-ups; Drilling post-1.0; "Lv." dormant | W7-DOCS · W10-DELETE (the two branches — A1) | GUILD #21 (A1): no level-ups, no Drilling (canon's "Maybe if we have level ups" is a false conditional), and the "Lv." label is retired — `Cards.gd:150-153` and `RaidView.gd:1023-1024` deleted in W10-DELETE, `Raider.level`/`xp` serialised and unread; §9's optional "ship Drilling" recorded as not taken. | Q-14 amended (RULED; §9's line not taken) |
| 22 | DESIGNER-22 / M3-LOOP-06 / LOOP-20 | The town's rank-states: 1 plate + dressings / 3 plates / 6 plates | wave 7 | 1 plate + rank dressings | W8-FACILITY (ranks 0-3) · W9-ART (ranks 4-5 — A2) | SCREENS #22 (A2): one plate, six dressings as one table — walkers 0/1/2/3/4/5, lanterns 6/8/10/10/10+2 braziers/10+4; Unknown hides the banners; Known banners + a pennant on a pole beside the Board callout; Respected the notice post; Established the cobble band + pennant line; Renowned the statue + 2 brazier flames; Legendary the second tent, two `knight_unlabelled` guards, crest pennants on all four tents, 4 braziers. | BL-102 amended (the table) |
| 23 | DESIGNER-23 / Q-96 / M4B-CONV-04 / UI q7 / AUDIO Q-F | Which arena: per raid / per encounter; the bed follows | wave 7 | per raid — `arena_for()`'s kind rule | W7-STAGE · W7-AUD-AMB | STAGE #23: per raid by kind — E1-E5 in `stage_arena_dungeon`, A0/TR/A1-A3 in `stage_arena_cave`, the tier row's `scene` first; no `backdrop` key. | Q-96 amended (RESOLVED); M4B-CONV-04 closes |
| 24 | DESIGNER-24 / M4B-ACT-04 / PIPE-09 | The aerial town: still + motion / 10-14 px figures | wave 7 | as built | W7-DOCS | SCREENS #24: as built — motion, no figures; downsampled pixel art is blur. | **BL-123** (new) |
| 25 | DESIGNER-25 / Q12a / C-19 / CONTENT-28 / CONTENT q8 / LOOP q8 | Creature/encounter names; "Encounter N"; the tutorial trinkets' names | wave 7 | placeholders; "Encounter N"; the template names | ~~W9-POLISH~~ W7-REPORT (the field, TR's title, the boss-plate line) · W8-SIM-BALANCE (A3/E3/E4/E5 titles + the test) · W8-SCALE-1 (the prep-card sub-line) · W9-TIERS (tiers 2-5 through `gen_items.gd`) — A6 | CONTENT #25: the 21 boss rungs get a role title in spec 00 §2.3's optional `title` field (§7); trash, the ladder words and every enemy log name keep canon's placeholders; "Encounter N" in the UI, "Boss N" only as the loot key; the trinkets are Cracked Charm of Power / Health. | **BL-119** (new); BL-101 amended; Q-84 / C-19 closed |
| 26 | DESIGNER-26 / Q01 / UI q1 | Figure scale: as built / tavern 1.5x / re-author | wave 8 | as built | — (W7-DOCS the row) | STAGE #26: as built — 2 on camp and both arenas, 1 on tavern and market; 1.5 is not an integer and shimmers. | BL-103 amended (with #27) |
| 27 | DESIGNER-27 / Q02 | Boss mass: upscale ok / re-author | wave 7 | 1x; scale 2 ONLY if the designer says "upscale ok" | W7-STAGE | STAGE #27: "upscale ok" — `marks.boss.scale = 2` on both arenas for every enemy rank (Main Boss 262 px, Mini 210), one pixel pitch for everything on the floor; `test_scene_stage.gd:602` reads `Vector2(2, 2)`; the dungeon marks clear the front rank by ≥ 24 px with a boss up to 400 px wide. | BL-103 amended |
| 28 | DESIGNER-28 / Q03 | Hall framing: same / tight; margins / 3-column | wave 8 | as built | — | SCREENS #28: as built — `HALL_FRAMING = "same"`, margins-only; the hall is a panel over the camp. | **BL-124** (new) |
| 29 | DESIGNER-29 / Q04 | One bubble chrome; the emote map | wave 8 | one chrome; the proposed map | W9-ART (+ one handoff line into `RaidView._line_effects` for W9-SCALE-2; the Town mood pick to W9-POLISH) | STAGE #29: one chrome; `SceneStage.EMOTE_MAP` as two tables — fight: MINOR question · MODERATE sweat · SEVERE anger · CRITICAL exclaim · downed skull · Bard's song note; town moods wipe skull · cleared heart · at_risk (any raider < 40) sweat; the rest ambient decor. | **BL-136** (new) |
| 30 | DESIGNER-30 / Q05 + Q07 | Header lockup 44 + tagline; overhead bars | wave 8 | as built | — | STAGE #30: as built — the 44 px mark with "Questionable people. Worse decisions." on every framed screen; badge + pips on every figure, the full HP bar on the acting/struck figure only. | **BL-137** (new) |
| 31 | DESIGNER-31 / Q06 / UI-53 / LOOP-05 / LOOP q5 | The reputation chip: gem / sigil; the word "Rep" | wave 8 | gem | W9-POLISH | SCREENS #31: OVERTURNED — `Frame.REP_ICON = "sigil"` (the existing `rank_<name>.png`), no word, tooltip "N reputation · M more to <rank>"; the gem stays for trinkets. | **BL-125** (new); spec 00 §2.5 amended |
| 32 | DESIGNER-32 / Q08 | Depth of field: off / on at N | wave 8 | off | W7-DOCS (docs/12 §2.2, docs/00 VS7 — ownership added) | SCREENS #32: off — the plates are 1:1 pixel art and a blur softens the designer's pixels; no `dof` layer. | **BL-126** (new) |
| 33 | DESIGNER-33 / Q09 / M6-JUICE-02 / UI-46 | Does "the desk does not move" forbid a 110 ms dissolve; the wipe's slide | wave 8 | `TRANSITION_MS = 0`, no slide | ~~W9-POLISH / W10-DELETE~~ W8-KEYS (A7) | SCREENS #33 (A7): OVERTURNED — `ScreenRouter.TRANSITION_MS = 110`, a fade-in of the incoming page (opacity only, ease-out, inserted at t=0, 0 under `reduced_motion` and `shot.gd`), no cross-fade, no 6 px shift, no t=1,800 slide; a page changing in place is inside M5. | Q-99 amended (RULED) |
| 34 | DESIGNER-34 / Q10 | Town focus entry: rail-first / hotspot-first | wave 8 | rail-first | W7-DOCS | UX #34: rail-first as built; docs/13 §13.2's hotspot ring is amended so the rail is the ring. | **BL-142** (new); RULES-06 closes |
| 36 | DESIGNER-36 / Q12b + Q12c / LOOP-10 / LOOP q1 | The Results comedy line beside the tally; may the player leave mid-account | wave 8 | as built (both) | W7-REPORT (Q12b, S) | UX #36: Q12c as built (`EXITS_GATED = false`); Q12b OVERTURNED to (b) — the notice's line stays on every Results page as the epigraph under the eyebrow "The notice said:" (`Results.COMEDY_LINE = "epigraph"`), so the card never claims to report the attempt. | **BL-139** (new) |
| 37 | DESIGNER-37 / Q13 second half / UI q2 | Does "Pauline_4" stay: keep / "goes by" / drop | wave 8 | styled "goes by Pauline_4" | ~~W9-POLISH~~ — (nothing to build) | CONTENT #37: keep exactly as generated — the handle IS the name everywhere; no "goes by" line (Pillar 2's one-name row). | **BL-120** (new) |
| 38 | DESIGNER-38 / Q14 / KIT-20 | Settings controls: cycle buttons / toggle-segmented-slider | wave 8 | as built | — (W8-KEYS's Forgiving row uses the chip) | UX #38: as built — every row a lit cycle chip, the audio ladder as pips; the Forgiving Guild row is an Off/On cycle on the same chip. | **BL-140** (new) |
| 39 | DESIGNER-39 / Q15 / LOOP-30 / UI-55 / LOOP q7 | The tutorial lesson band on RaidView/Results | wave 7 | yes, tutorials only | W7-REPORT | UX #39 (A4): yes — A0 `lesson` "Round three: somebody does something stupid. Watch for the stamp — the log says who, and why."; TR `lesson` "One trick, one timer, one tank between six of them. When it goes wrong, the report says who."; TR `lesson_report` (wipe branch only) "This is the Wipe Report. Who, what, and which round — it is all under 'By raider'." | **BL-141** (new) |
| 40 | DESIGNER-40 / Q16 / M6-A11Y-06 / UI-47 / RULES-08/09 | CVD ramp and hexes; the text floor; `prose_font_swap`; the logotype | wave 8 | CVD option default off; floors as built; `prose_font_swap` retired; logotype exempt | ~~W6-SETTINGS~~ W8-KEYS (`Palette.gd` + `test_palette_cvd.gd` added — A8) · W7-DOCS · W10-DELETE | SCREENS #40 (A8): the only ramp is the corrected three-state triad `DANGER #F73526` / `CAUTION #E8A302` / `POSITIVE #AFEBA2` (every adjacent step ≥ 5 L* under all four simulations); `colourblind_safe` (default off) swaps only the third state to `#C6DDF1`; the ten-plate table is struck; `Type.SMALL 13` / `STACK 11` stay (14 px in §4.2's frame); `prose_font_swap` retired; the logotype exempt. | **BL-127** (new) |
| 41 | DESIGNER-41 / Q17 | Morale faces as an authored sprite font | wave 8 | as built | — | SCREENS #41: as built — `Fonts.MORALE_FACE_FONT = true`, ten authored faces, never system emoji. | **BL-128** (new) |
| 42 | DESIGNER-42 / Q18 bundle (a-k) / LOOP q6 / UI q6 | a-k | wave 7 | a/b/i as built · c dressings · d one figure · e trip/drop/wrong-target · f global light · h none · j retire · k reference density | W8-FACILITY (c, ranks 0-3) · W9-ART (b, e, ranks 4-5) · W10-DELETE (j) | STAGE #42: ten at the default and one flipped — **b `Icons.WARRIOR_GLYPH = "shield"`** (the tank's badge is canon's one shield); c the tent's four facility states + the rank dressings of #22; e `FUMBLE_BY_SEVERITY` trip/drop/wrong_target; j the Raid Group tab retired; a/d/f/h/i/k as built. | BL-106 amended (b, c, e, j, k added); BL-102 for c |
| 43 | DESIGNER-43 / M6-JUICE-04 | Strike "screen shake on wipes" | wave 6 | struck | W6-LEDGER (landed) | SCREENS #43: struck — the wipe's beat is the stamp, the 12 % dim and the seal. | **BL-129** (new); M6-JUICE-04 closes |
| 44 | DESIGNER-44 / spec 00 §4 / SHIP q5 | Aspect keep default, expand the option; borderless on first launch | wave 6 | as built | W6-SETTINGS (landed) | SCREENS #44: as built — `display_aspect = "keep"`, `window_mode = "borderless"`, F11 / Alt+Enter to a window. | **BL-130** (new) |
| 45 | DESIGNER-45 / spec 00 §2 | The reference-concept conflicts already ruled — confirm | any | confirmed | — (W7-DOCS notes it) | SCREENS #45: confirmed — Ranger → Rogue, no creature names or levels from the references (the loop's 21 role titles land through §2.3's own `title` field), twelve paged cards, "Day N · Rank", canon rail labels; §2.5's gem is ruled by #31. | **BL-131** (new) |
| 46 | DESIGNER-46 / M6-AUD-05 / AUDIO-09/13 / AUDIO Q-A..Q-E / SHIP q10 | Audio owner; music; the Voice bus; world sound; the WIPE stamp; ambience's slider | wave 7 | ambience only on the Music bus; no music; Voice deleted; world silent; `ui.stamp` unjittered | W7-AUD-AMB · W8-AUD-OPT (the quill only, S) · W10-BUFFER (the lute, L — A13) · W10-DELETE (the Voice row NOT deleted) | STAGE #46 (A13): the loop owns audio; ambience on the Music bus; MUSIC is the generated sparse lute at Unknown/Known (`gen_music.py`, `Audio.MUSIC_BED = true`, camp family + main menu) as W10-BUFFER's first item; the Voice bus is "the scribe" — `ui.quill` under every log line; the world layer silent; the WIPE stamp `ui.stamp` unjittered; the ensemble, bell, cheer and leitmotif post-1.0. | Q-98 amended ((i) and (iii)) |
| 47 | DESIGNER-47 / Q-61, Q-68, Q-39 | The currency; the string keys; Power on zero Adventure armour | any | "G"; as built; deliberate | — (W7-DOCS docs/11 §3) | CONTENT #47: the currency is gold, "G" on chips and "gold" in prose, final; Market / the Merchant / Adventure's Board as built (canon's apostrophe); Q-39 deliberate. | Q-61 / Q-68 / Q-39 amended (RULED) |
| 48 | DESIGNER-48 / BL-40 | "Buy a round": cut / +N morale, cooldown N | wave 7 | cut | W7-DOCS | BALANCE #48: cut — 96 G for a +2 that drifts away in two ticks is a trap purchase; the Hot Bath Token is the Indulgence line. | BL-40 CLOSED |
| 49 | CRITIC q1 / CRITIC-M1 | The Forgiving Guild toggle: built or struck | end of wave 7 | built | W8-SIM-BALANCE · W8-KEYS (the chip) · W8-CRISIS (`start_attempt`) · W7-SAVE (`active_run.difficulty_mult` — A10) | BALANCE #49 (A10): built — `Formulas.DIFFICULTY_MULT` 1.0 / 0.75 on mistake chance (before the clamp) and enemy `max_hp`, a run option stored on the attempt and in `active_run`, a sweep axis, one Options row, off by default, not the BAL-04 fix. | **BL-113** (new); m6-forgiving-guild closes |
| 50 | CRITIC q2 / CRITIC-M3 | Traits: cut or built | wave 6 | cut | W6-LEDGER (landed) · W7-DOCS | GUILD #50: cut — the person is the backstory bullet; `Raider.traits` serialised and empty. | BL-96 confirmed |
| 51 | CRITIC q3 / CRITIC-M2 | Retreat: confirm struck | wave 6 | struck | W6-LEDGER (landed) · W7-DOCS | UX #51: struck — the attempt is committed at Depart; the only "don't go" is the prep board's Back. | BL-95 confirmed |
| 52 | CRITIC q4 / SIM-10 / SIM q6, q7 | The four PROPOSED kits; the Bard's S; Monk Guard's AC | end of wave 8 | post-1.0 for the four; Bard as tabled | W9-KITS (L−; the Mage buff sheds to W10-BUFFER first) | COMBAT #52: Monk Guard (`GUARD_THREAT_COEF 3.0`, `GUARD_AC_BONUS +7` = the canon Shield's 7, `GUARD_DAMAGE_MULT 0.5`), Rogue Front (`ROGUE_FRONT_MULT 0.77`, Behind 1.0), Mage Raid Spell Buff (`MAGE_RAID_BUFF +2`) come in; the Wizard Ramp stays out; the Bard sings as Q-46 tables it with `BARD_S_DIVISOR = 10` and the canon Charm of Mana as its Tier 1 Mana (S = 2). | BL-99 amended |
| 53 | CRITIC q5 / SHIP q3 | If the words are late: proceed on Tier 1 or wait | end of wave 7 | proceed; Tier 1 | W9-TIERS (the long branch) · W10-EXPORT (no pending list) | CONTENT #53: void — the words and names are ruled; 1.0 is the five-tier ladder with S17 on Raid 5; the no-words branch, `data/_pending/` and the README "smaller game" line are not built; `tier_is_named` is a top-down valve only. | **BL-121** (new) |
| 54 | SIM q3 / SIM-04 / DW-C1 / CONTENT-27 | Focus: numbers per class, or post-1.0 | end of wave 6 | post-1.0 | W7-DOCS (docs/08 §5.3 DECIDED-for-1.1) | COMBAT #54: post-1.0 with the numbers decided (headline 3); M10 ships as Silence; an empty pool heals at `HEAL_FLOOR` / hits for the staff alone. | BL-87 amended |
| 55 | SIM q4, q5 / SIM-13 / SIM-27 #2 | M05's effect; E4's M08 window; M09's cadence | end of wave 7 | the recommendations | W8-SIM-BALANCE · W9-TIERS (tiers 2-5) | COMBAT #55: M05 `{raid_damage, 27}` on round 4 every 5; M08 `{rounds 2, every 6}` (5 → 6 so the fixate never overlaps the debuff); M09 `{40 %, rounds 3, round 3, every 6, active_tank}`; the validator refuses M05 without `amount` and M08 window ≥ period. | **BL-115** (new) |
| 56 | SIM q8 / SIM-12 | Attrition grace after enrage: none or N | end of wave 7 | none | W8-SIM-BALANCE (A11 — replaces the plan's SIM-12 line) | COMBAT #56 (A11): 5 rounds — `RaidSim.ATTRITION_GRACE_ROUNDS := 5`, overridable per record as `attrition_grace`, a Story line at `enrage_round`; the 40-round cap stays the safety; without it A2's tails fail. | **BL-114** (new) |
| 57 | CONTENT q4 / CONTENT-30 / q-W5-SIM | The tutorial mistake rate: 0.5 both, or A0 scripted-only | end of wave 7 | 0.5 / 0.5 | W8-SIM-BALANCE | BALANCE #57: `Mistakes.TUTORIAL_MISTAKE_MULT = {"A0": 0.0, "TR": 0.5}` — A0 shows exactly one idiot on round 3; TR keeps organic causes for its Wipe Report. | BL-90 amended; BL-91 closes |
| 58 | CONTENT q5 / CONTENT-12 / SIM-15 | MIS_NINJAPULL: build the break roll, or cut | end of wave 6 | cut | W8-CRISIS (the Depart roll) · W8-SIM-BALANCE (`run()` honours it) · W7-SAVE (`active_run.ninja_pulled` — A10); W7-SIM-EFFECTS builds no `NINJAPULL_REACHABLE`; W9-REVIEW keeps the eight lines | COMBAT #58 (A10): BUILT — when a raid encounter already has an attempt this cycle, Depart rolls one ambient check per living raider on the seeded `break` channel; the first NINJAPULL draw pulls; the fight starts with provisions unapplied and unconsumed and the mistake logged Critical at round 1 with its Distraction token; the result is stored on the record so the replay reproduces it. | **BL-116** (new) |
| 59 | CONTENT q7 / CONTENT-19 / Q59-3 / SIM-21 / LOOP-17 | Wishlists: out or in | wave 6 | out | W6-LEDGER (landed) · W7-DOCS | GUILD #59: out — the Master Looter's per-raider delta is the game knowing each raider's BiS; the flag declared off, the four morale rows unreachable data, BIG-dumb #3 inert. | BL-98 confirmed; Q59-3 closes |
| 60 | LOOP q9 / SHIP q8 / SHIP-13 / LOOP-25 | Disband: game over or recoverable; the bail-out | end of wave 7 | recoverable; no bail-out | W8-CRISIS (L) | UX #60: recoverable as built, and the bail-out is OVERTURNED IN as the walk-in — while `GameState.is_insolvent()` (roster < next rung's party size AND gold < the cheapest seat AND nothing worth that seat to sell) every board refresh carries one Common at 0 G, "A walk-in. Will raid for a bed."; no loan. | **BL-143** (new); SHIP-13 closes |
| 61 | LOOP q10 / LOOP-12 / CRITIC-C12 | The wipe's culprit rule; the extra −4 | end of wave 6 | the rule behind a const; −4 | W6-SIM-CASCADE (landed) · W7-REPORT (the sentence) | COMBAT #61: kept as built — the last Severe-or-worse before the first tank/healer death, else the deepest cascade, else nobody; `WIPE_CULPRIT_DELTA = -4` once per attempt. | BL-107 amended (🔷 → DECIDED) |
| 62 | LOOP q2 (second half) / LOOP-24 | Does a wiped TUTORIAL cost morale | end of wave 7 | no exemption | W7-DOCS | BALANCE #62: no exemption — a wiped TR pays −8 (×1.35) and the culprit's −4; LOOP-24's path is closed by #1 and #9, not by a free wipe. | **BL-112** (new) |
| 63 | LOOP q3 / Q-60 / LOOP-19 | The recruit price scale behind `PRICE_SCALE` | wave 6 | yes — landed | W6-LEDGER (landed) | BALANCE #63: doc 11's scale stays (Common 15 · Uncommon 60 · Rare 160 · Epic 420 · Legendary 1,000 G). | Q-60 / BL-94 confirmed |
| 64 | UI q4 / CRITIC-M4 / SHIP q6 / SHIP-20 | S13, S16, `nav_codex`; the 1-4 sort rows | wave 6 / wave 8 | both struck; `nav_codex` deleted | W6-LEDGER (landed) · W7-DOCS · W8-KEYS | UX #64: struck — `nav_codex` and `ScreenRouter.codex()` deleted; the map that ships is Space pause + 1-4 speeds on RaidView, Q/E on RaiderDetail, F on Records, Esc back. | BL-97 confirmed |
| 65 | SHIP q7 / SHIP-20 / LOOP-26 C20 | Gamepad: unverified or supported | wave 8 | unverified, unsupported | W10-DELETE (`glyph_set`) · W10-EXPORT (the README sentence) · W7-DOCS | SHIP #65: unverified and unsupported — the joypad events stay, the glyph row and key are deleted, `README-player.txt` says in one sentence what a pad does. | **BL-133** (new, with §7.1's language row) |
| 66 | SHIP q9 / SHIP-16 | Code signing | wave 10 | unsigned | W10-EXPORT · W10-README · W10-WALK | SHIP #66: unsigned — the README-player's two SmartScreen clicks, `export_build.sh` prints the zip's SHA-256, the release commit and BUILD_STATE carry it. | **BL-134** (new) |
| 67 | AUDIO Q-F / DESIGNER-23 | The arena bed per encounter or per raid | wave 7 | follows `arena_for` | W7-AUD-AMB (a fifth bed) | STAGE #67: follows the arena — `Audio.BEDS` keyed by scene, the dungeon gets `amb_dungeon`, `stage_town` plays `amb_camp` by design. | Q-98 (ii) confirmed; **BL-138** (new, the five beds) |
| 68 | UI-15 / LOOP-01 | May the fixture drop "Lv." and carry a legal Known state | wave 6 | yes | W6-SHEETS (landed) · W10-DELETE (the branches — A1) · W10-README (the re-record) | SHIP #68 (A1): yes — `new`/`play` carry no level; the reference `--fixture` keeps its four levels as DATA and they stop rendering when the branches go; `diff_all.sh` re-recorded at the wave-10 close with before/after in W10-README's entry. | **BL-135** (new) |

Every "as built" row above is a complete ruling (the plan's own reading) and gets its register row so no docs/15 reader has to infer it.

## 3. The deferrals, ruled

§7.1's table, row by row (24 rows). "In" names the wave and unit; "Out" keeps the row's text (amended where the ruling adds a clause). Eight come in, sixteen stay out, and one is struck as void.

| # | What (§7.1) | In / Out | Wave · unit | The row's text now | Register row |
|---|---|---|---|---|---|
| 1 | Focus (Q-02 Model A+) and M10's drain half | **Out** (numbers decided) | — (1.1, one L unit) | "M10 ships as Silence; Focus is post-1.0 with its numbers decided in BL-87; `FOCUS_ENABLED` and `MANA_BURN_DRAIN_ENABLED` stay false" | BL-87 amended |
| 2 | The four PROPOSED class kits | **In (three)** / Out (the Wizard Ramp) | wave 9 · W9-KITS (the Mage buff sheds to W10-BUFFER first; Guard and Front never) | "docs/06 §4.8's Wizard Ramp is post-1.0; §4.5-4.7's kits ship in the canon-line shape BL-99 records; no code ships behind `false`" | BL-99 amended |
| 3 | Wishlists / BiS (Q59-3), the BIG-dumb wishlist row | **Out** | — | unchanged: "wishlists are out of 1.0 (docs/16 C3); the flag stays declared off; RaiderDetail prints no wishlist sentence" | BL-98 confirmed |
| 4 | Traits (docs/04 §10) | **Out** | — | unchanged: "traits are post-1.0; `Raider.traits` stays serialised and empty" | BL-96 confirmed |
| 5 | Upkeep / payday (Q59-5, Q-31) | **Out** (fork ruled) | — (1.1; a v18 bump) | "no upkeep in 1.0; condition 5 stays false; the payday cadence and Tier 1 wages are ruled (Q-31) for the first post-ship economy pass" | Q-31 / BL-59 amended |
| 6 | Legendary quirk specs (BL-58) | **In** | wave 9 · W9-QUIRKS (M, bought); W9-TIERS flips `legendary_quirks` by handoff; W9-KITS threads the `WRONG_SONG` hook line | row struck — "the nine quirks are specced (BL-58) and ship on" | BL-58 amended |
| 7 | S13 encounter interstitial, S16 Codex, `nav_codex` | **Out** (struck, not deferred) | — (`nav_codex` deleted in W8-KEYS) | "S13 and S16 struck from docs/13 §5 (BL-97); `nav_codex` deleted (W8-KEYS); S16 revisited only with Tier 2+ content" | BL-97 confirmed |
| 8 | Per-tier arenas, boss recolours, icon palettes | **Out** | — (`tier_words.json`'s `scene` key is the door) | unchanged: "tiers 2-5 share the two arenas and the boss set; per-tier identity is post-1.0; the `scene` key exists for when it is authored" — now visible for four tiers | BL-100 confirmed |
| 9 | Boss / creature / raid names beyond the placeholders (Q12a, C-19) | **In (titles)** / Out (creature names, raid names, trash names) | wave 7 · W7-REPORT (the field, TR, the boss plate) · wave 8 · W8-SIM-BALANCE (A3/E3-E5) + W8-SCALE-1 (the prep card) · wave 9 · W9-TIERS (tiers 2-5) — A6 | "placeholders ship for trash, the ladder and the log; the 21 boss rungs carry a role title (BL-119) through spec 00 §2.3's `title` field" | BL-119 (new); BL-101 amended |
| 10 | Music (Q-B), the voice bus's content (Q-C), world/combat sound (Q-D) | **In (the lute; the quill)** / Out (the world layer; ensemble, bell, cheer, leitmotif) | wave 8 · W8-AUD-OPT (the quill, S) · wave 10 · W10-BUFFER's first item (the lute, L; cut in writing if the buffer is consumed) — A13 | "a generated sparse lute at Unknown/Known on the Music bus and the quill on the Voice bus ship; the ensemble, bell, cheer, leitmotif and the world layer are post-1.0" | Q-98 amended |
| 11 | The Blacksmith (Q-13) | **Out** | — (the achievement swap in W7-SAVE — A9) | "out of 1.0; the facade stays locked with in-world copy; the flag stays declared off; 'Sharpened, Finally' is replaced by 'Pocket Change'; Q-13's five sub-rows close post-1.0" | Q-13 amended |
| 12 | Town rank-states beyond derived dressings, aerial figures, the designer's plates | **Out** (the six derived dressings are in) | — (dressings: W8-FACILITY ranks 0-3, W9-ART ranks 4-5 — A2) | unchanged: "1 plate + rank dressings; 3 or 6 plates are the designer's, post-1.0" | BL-102 amended; BL-123 (new) |
| 13 | Gamepad glyphs and rebinding; a second language; a pseudolocale pass | **Out** | — (W10-DELETE the rows; W10-EXPORT the README sentences; W7-DOCS docs/13 §15.1) | "a pad works unverified and unsupported; one language (en-US); no pseudolocale pass — the 150 % sweep is the layout proof; the Language and Controller-glyphs rows and keys are gone" | BL-133 (new) |
| 14 | Code signing | **Out** | — (W10-EXPORT, W10-README, W10-WALK) | "unsigned; the README-player note says so; the zip's SHA-256 is in the release record" | BL-134 (new) |
| 15 | Instrumentation (docs/14 §12) | **Out** | — (W7-DOCS the status line) | unchanged: "post-ship: docs/14 §12"; docs/14 §12 gains its status line; the crash log is the only file the game writes about itself | BL-105 confirmed |
| 16 | The 2x-canvas re-author of the party families and the bosses (Q01/Q02) | **Out** (the boss upscales instead) | — (W7-STAGE's two integers) | "1.0 ships the party AND every enemy at 2x integer scale; the re-author at painted density is post-1.0 and a person's" | BL-103 amended |
| 17 | Tiers 2-5 if the words never come | **Struck (void)** — tiers 2-5 come in | wave 9 · W9-TIERS's long branch | row struck; the mechanism (`tier_is_named`, `COMPLETED_AT`) is retained only as BL-121's top-down valve; `data/_pending/` is never created | BL-121 (new) |
| 18 | Region-masked per-component diff scoring (m4t-06) | **Out** | — | unchanged: "m4t-06 closed as not required to ship; the whole-screen numbers are the record" | BL-104 confirmed |
| 19 | The perf stage as FAIL (UI-45's 3x promotion) | **Out** (stays WARN) | — (W10-README's budget line says "measured on the second machine") | "stage 8 stays WARN; the budget is stated in README and BUILD_STATE, measured on the second machine" | BL-104 confirmed |
| 20 | `prose_font_swap` (Q16) | **Out** (retired) | — (W10-DELETE) | unchanged: "retired; the row and key deleted (W10-DELETE); docs/13 §15.1's row struck" | BL-127 (new, item 3) |
| 21 | A per-class VFX family, normals, more state glyphs, HSV busts | **Out** (the Legendary busts are a NAMED pass, not a re-hue, and run in W9-ART) | — | "as built; per-class VFX, normals, further glyphs and per-rarity figures are post-1.0; the nine Legendary busts are drawn by `derive_busts.py`'s named pass" | BL-106 amended |
| 22 | The dungeon and town-aerial ambience beds beyond the camp bed | **In (the dungeon)** / Out (the aerial) | wave 7 · W7-AUD-AMB (a fifth bed, `amb_dungeon`) | "five beds ship — camp, tavern, market, cave, dungeon; the aerial main menu plays the camp bed by design; a town-aerial bed is post-1.0" | BL-138 (new) |
| 23 | A "Raid Group" read-only view (Q18j / HALL-21) | **Out** (retired) | — (W10-DELETE removes the remnants) | "retired; the tab is deleted (W10-DELETE)" — the "unless the page says read-only view" escape hatch is closed | BL-106 amended (j) |
| 24 | A soft-lock bail-out (a free Common, a loan) | **In (the walk-in)** / Out (a loan) | wave 8 · W8-CRISIS | "the bail-out is the walk-in: while `GameState.is_insolvent()` holds, one Common at 0 G on every board refresh; no loan" | BL-143 (new) |

## 4. Canon numbers changed

docs/_source is not edited. Under the delegation exactly **two canon numbers** move, both in one row, and the row says why:

| Canon number | docs/_source line | Was | Now | Reason | Where / row |
|---|---|---|---|---|---|
| Basic Raid Dagger damage | `ideaboard-transcription.md` §3.4 Rogue, Boss 1: "Basic Raid Dagger — +4 Damage" | +4 | **+5** | The first raid drop of the game must not read below the +5 Iron Adventurer's Sword the Rogue already holds (raw notes, Weapons: "Warrior / Rogue / Bard — Iron Adventurer's Sword +5 Damage"); docs/09 §10.2's own anchor (Boss 1 = Adventure +1..+2) less the designer's one-point dagger discount. Every swing alternative (`DAGGER_SWINGS = 2`, three windows, one extra off-hand swing) either doubled the Rogue or put him over the canon "Very high single-target DPS" Wizard at Boss 4/5 (docs/08 §9.1). The Rogue column becomes 24.2 / 24.2 / 28.0 / 35.6 / 49.9 — monotone, the Wizard on top at every rung. | `data/items_t1_raid.json` (W8-ITEMS); Q-36 |
| Strong Raid Dagger damage | `ideaboard-transcription.md` §3.4 Rogue, Boss 4: "Strong Raid Dagger — +6 Damage" | +6 | **+7** | The same anchor; keeps the dagger one under the sword (+8) so "daggers hit lighter" stays visible. | same |

Derived, not canon, moved with them: `TierScaling.DAGGER_OFFSET` −2 → −1 (so the Boss 1 dip never recurs at tiers 2-5).

Every other number the batches move is 🔷 PROPOSED (a doc's own number, not the designer's) and is recorded by its row; the ledger, for the drift gate and the canon guard:

| 🔷 number | Was | Now | Row |
|---|---|---|---|
| A0 HP · raw | 66 · 20 | 61 · 20 | BL-110 |
| TR HP · raw · mechanic | 198 · 15 ×2 · M01 | 183 · 8 ×2 · M03 (13/rd, escape 50 %) | BL-110, Q-100 |
| A1 HP · raw · add HP | 3 × 45 · 9 ×3 · 12 | 3 × 41 · 7 ×3 · 11 | BL-110 |
| A2 HP · raw · add HP | 2 × 275 · 19 ×2 · 44 | 2 × 76 · 9 ×2 · 12 | BL-110 |
| A3 HP · raw · mechanics | 700 · 25 ×2 · M01 M02 M03 | 183 · 8 ×2 · M02 M03 M04 {15 HP, swing 6, r6} | BL-110, Q-100 |
| The on-ramp sizing rule | docs/08 §9.3 unhealed 3.5-round clock at each rung's own stage (BL-28/BL-30) | §9.3a healed clock at stage 0, morale 45, HP × 0.924 | BL-110 |
| Adventure loot rolls per slot | 1 | 2 | BL-111 |
| `Mistakes.TUTORIAL_MISTAKE_MULT` | 0.5 (both) | {A0 0.0, TR 0.5} | BL-90 |
| `RaidSim.ATTRITION_GRACE_ROUNDS` | unstated +5 | 5, named, per-record `attrition_grace` | BL-114 |
| E4 M05 / M08 / M09 | E unnamed / permanent fixate / no cadence | `raid_damage 27` r4 every 5 / `rounds 2 every 6` / `40 %, rounds 3, round 3, every 6` | BL-115 |
| `Recruitment.GEAR_SURCHARGE_BP` | none | 1500 per raid piece beyond the first | Q-29 |
| `Formulas.DIFFICULTY_MULT` | none | 1.0 / 0.75 | BL-113 |
| The target clear-rate curve | none written | A0 ≥ 90 · TR 55 · A1 75 · A2 65 · A3 50 (at 45) · E1 ≥ 90 · E2 ≥ 80 · E3 75 · E4 60 · E5 40 (at 55) | Q-100 |
| Pins | A3 `== 0.0`; TR `== 1/20`; A0 `>= 18/20` | A3 `>= 0.40`; TR `>= 8/20`; A0 `>= 18/20`; A1 bite `<= 19/20` at 55 | BL-110, Q-100 |
| docs/09 §10.2 Chipped Sword | +2 | +3 (BL-27's floor of 2 had made +2 a null purchase) | Q-28 / Q-35 |
| Record-wall reputation records | 0 RP (inert) | 15 RP each, capped live at 15 % | Q-69 |
| `Palette.CAUTION` / `POSITIVE` | `#FBB62B` / `#32C24D` (spec 04's reference samples) | `#E8A302` / `#AFEBA2`; `POSITIVE_CVD #C6DDF1` | BL-127 |
| `ScreenRouter.TRANSITION_MS` | 0 | 110 (opacity only) | Q-99 |
| `marks.boss.scale` | 1 | 2 (both arenas, every rank) | BL-103 |
| `Frame.REP_ICON` | "gem" | "sigil" | BL-125 |
| `Icons.WARRIOR_GLYPH` | "swords" | "shield" | BL-106 |
| `Results.COMEDY_LINE` | "as_built" | "epigraph" | BL-139 |
| `Audio.MUSIC_BED` | (no music) | true — the lute, W10-BUFFER | Q-98 |
| `FLAG_DEFAULTS.legendary_quirks` / `achievement_rp` | false / — | true / true | BL-58, Q-69 |
| The walk-in's price | (no card) | 0 G | BL-143 |
| Version / copyright | `0.1.0` / "" | `1.0.0` / `© 2026 Malkail` | BL-132 |
| Upkeep (post-1.0 spec, not shipped) | unruled | payday every 7 ticks; 1/1/2/3/4 G × 2.4^(tier−1); bench pays | Q-31 |
| Focus (post-1.0 spec, not shipped) | 🔷 table | DECIDED-for-1.1 as docs/08 §5.3 tables it; drain 10 | BL-87 |

Kept deliberately (every batch): `Morale.RARITY_OFFSET` [−5, −2, 0, 4, 12]; docs/05 §7.1's wipe −8 / cap −16 / culprit −4; `STARTING_GOLD` 60; Guildhall L2 150 G; `PRICE_SCALE` doc 11; the raid's `RAID_ROLLS` 2/2/2/3/3; docs/08 §9.2/§9.3's raid HP and swings (E1-E5 untouched in wave 8); `TANK_SWAP_NEEDS_A_PARTNER` true; Legendary find weights [0,0,0,950,50] and threshold 3200; `ROSTER_CAP_BY_RANK` 15..20; `Type.SMALL 13` / `STACK 11`; `HALL_FRAMING "same"`; `figure_scale` 2/2/2/1/1; the four buses at 100/80/80/100; every canon display name byte-identical.

## 5. Register rows

docs/15-ready text. §5.1 is the new rows (BL-110..BL-143 in docs/15 §10's anchor + heading + Owner/Signal shape; Q-100 in the table shape of Q-96..Q-99, appended to the table that holds them). §5.2 is the status line and text for every existing row a ruling amends, confirms or closes. The owner of docs/15 in the wave named applies them (W7-DOCS the bulk; W8-SIM-BALANCE, W9-REVIEW and W10-CREDITS the rows their waves earn, as the plan already orders); a row that a unit lands in-wave goes in by that unit's handoff.

### 5.1 New rows

<a id="q-100"></a>
| Q-100 | **What is the target clear-rate curve, and what does a rung outside its band do?** [08 §9.2-§9.3](./08-stats-and-formulas.md) priced the raid and [10 §8-§9](./10-content-and-encounters.md) the on-ramp without a written target; the sweep measured and no row said what the number should be (audit M6-BAL-03; `build/plan/ship/00-plan.md` §6 row #9). | [08 §9.2, §9.3, §9.3a](./08-stats-and-formulas.md), [10 §8, §9.1](./10-content-and-encounters.md), [Q-90](#q-90), [BL-85](#bl-85), [BL-110](#bl-110) | **DECIDED (2026-09-15):** first-attempt clear for the benchmark six / twelve, all-Common, 200 seeds, each rung at the gear it is sized for. The on-ramp at morale **45** (the fresh guild): A0 ≥ 90 · TR 55 (40-70) · A1 75 (65-85) · A2 65 (55-75) · A3 50 (40-60) — the wave-8 completability gate (FAIL). The raid at morale **55** (`balance_sweep.gd`'s `REFERENCE_MORALE`, 08 §9.2's own Content costing, the state the farm delivers to the raid door): E1 ≥ 90 · E2 ≥ 80 · E3 75 (60-90) · E4 60 (45-75) · E5 40 (30-55) — WARN from wave 8, asserted from wave 9 with the tier pass; the morale-45 raid cells print beside the bands as the "after a wipe" reading, never as the gate. P(a fresh guild reaches the raid door without a wipe) ≈ 13 %; P(E5 in ≤ 3 attempts) = 78 % (Q-90's arithmetic). A rung outside its band moves by its formula lever only, each step one 200-seed sweep recorded in the row: too hard → the raw swing −1 per swing per re-measure (three steps at most), then its M02/M03 magnitude to 08 §9.5's ½-pulse rule (13 at stage 0); too easy → `target_rounds` +2 with HP re-derived — two steps at most on the on-ramp, ONE on E1-E5 (the mechanic lever having gone first — BL-115). BL-85 closes: no Tier 1 encounter authors M01 on one tank (TR carries M03 — the fire — and A3 M04; E3 is the tier's first swap; `TANK_SWAP_NEEDS_A_PARTNER` stays true and dormant) and `Encounter.validate()` refuses the combination. Because TR and A3 share one budget (183 HP, 8 ×2) with A3 carrying three mechanics to TR's one, A3 is EXPECTED to land under TR on the first pass; its band and the too-hard rule are the answer, not a wall. The first 200-seed pass is also expected to land A1 and A2 ABOVE band (the sim's site-weighted roll taxes DPS less than 08 §8.8's published tax the rows were derived under); the +2 arm then fires once — the rule working, not a mistake — ruled by the loop under the designer's 2026-09-15 delegation |

<a id="bl-110"></a>
### BL-110 - The on-ramp is sized by one rule for the roster a new guild brings: stage 0, all-Common, morale 45 *(DECIDED - lever (c) of M6-BAL-04, taken under the designer's delegation; W8-SIM-BALANCE lands the rows)*

**Owner:** [08 §9.3a](./08-stats-and-formulas.md) (new) / [10 §8, §9.1](./10-content-and-encounters.md) / [05 §8](./05-morale.md) - **Signal:** The playtest's "closed circuit" (M6-BAL-04): eight guilds walked A2 with a stage-0 party against a rung sized for a shod six

`RaidPlan.gear_label()` returns "T1A" the moment one chalked raider wears one Adventure piece, and `tools/playtest.gd` never farmed a cleared rung — so M6-BAL-04's "in full Tier 1 Adventure gear" was the label, not the gear: 550 HP at 16.5 × 0.70 is 48 rounds against an enrage of 14, and no morale number opens that. The wall was a gear stage the player was assumed to have and never handed; the 45 is real and second. Lever (c): A0, TR, A1, A2 and A3 are re-derived from a new 08 §9.3a for every encounter whose party carries ONE healer — `fight_len = target_rounds / TAX` (TAX = 1 − mistake_chance(Common, 45) = 0.702), `hp_total = nominal_dps(stage 0) × target_rounds × (TAX / TAX_CONTENT) = × 0.924`, `boss_auto_raw = (tank_max_hp / fight_len + HEAL_FLOOR) / (1 − mitigation(7 AC) = 18.9 %)` — the HEALED clock, because 08 §9.4's 3.5-round invariant was written to be unhealable solo for a twelve with three healers and a six has one. Tutorials take the lesser of the rule and their authored under-budget swing (10 §9.1: a tutorial demonstrates a fail state, it does not impose one). The rows (W8-SIM-BALANCE, hand-written in `data/encounters_tutorial_t1.json` and `data/encounters_adventure_t1.json`): A0 4-party, 1 × 61 HP, 20 raw ×1, no mechanic, target 6 / enrage 9 · TR 6-party, 183 HP, 8 ×2, M03 {13/rd, escape 50 %}, 12 / 17 · A1 3 × 41, 7 ×3, M04 {1 add, 11 HP, swing 5, round 5}, 8 / 12 · A2 2 × 76, 9 ×2, M04 {1, 12, 6, r6} + M02 15 every 4, 10 / 14 · A3 183, 8 ×2, M02 15/4 + M03 18/50 % + M04 {1, 15, 6, r6}, 12 / 17. Before/after: A0 66 · 20 → 61 · 20; TR 198 · 30 → 183 · 16; A1 135 · 27 → 123 · 21; A2 550 · 38 → 152 · 18; A3 700 · 50 → 183 · 16. The Common baseline (−5), the wipe deltas, the 60 G purse and the 150 G Guildhall are unchanged — the facility keeps its purpose because a Common still rests at 45; lever (a) would have spent the first facility's reason to exist on a wall gear built. Derived under an attrition grace of 5 rounds past enrage ([BL-114](#bl-114)) — without it A2's mean kill clock (13.1) runs into its enrage (14) and the tails fail. The 12-raid keeps §9.3 unchanged (its three healers are §9.4's own model). `Formulas.SWING_PRICES_MECHANICS` is NOT built — after Q-100 no one-tank rung carries M01, so there is nothing to price; `Encounter.validate()` refuses `m01` where `tanks_required < 2`. The harness now farms like a player: `tools/playtest.gd` (W8-SIM-BALANCE's file this wave) re-runs the Adventure rungs (A3 → A2 → A1, each a Day Tick) before a raid rung until no raider wears `start`-source armour or an unarmed main hand — 08 §9.2's E1 stage — and re-runs cleared raid rungs to `raid_entry` before E2-E5; farm runs are attempt rows, the 5-attempt cap applies only to the rung being sized; the stage predicate is a local function in `playtest.gd` (start / adventure / raid by `source` on worn items and an armed main hand). Pins: `test_adventures.gd:213` → `rate >= 0.40`; `test_tutorials.gd:364` → `cleared >= 8`; A0 stays `>= 18`; "A1 still bites" `<= 19/20` at 55. The drift baseline gains the five on-ramp rows at (stage 0, Common, 45) and `--rebaseline` runs once, AFTER W8-ITEMS's regeneration (the daggers, off-hands and loaners move `raid_entry`). BL-28's stage-0 finding stands; BL-30's staged swings are superseded and its row says so; docs/08 §9.3a and docs/10 §8/§9.1's tables move in the same unit, the docs commit before the data commit (`test_canon_guard.gd` reads docs/08's tables). Under this rule the on-ramp is winnable at stage 0 / 45 and the raid door (E1: 2,200 HP against full Adventure gear) is the first real wall, which is the designer's ladder: the Adventure is beatable on arrival and its loot is what you re-run it for — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-111"></a>
### BL-111 - An Adventure rung rolls two items per loot slot *(DECIDED - implemented; W8-SIM-BALANCE)*

**Owner:** [10 §4.2](./10-content-and-encounters.md) / [11 §4.3](./11-economy.md) - **Signal:** Silent; the raid's `raid_entry` stage was a 36-clear farm

docs/10 §4.2 counts the raid's rolls (E1:2 … E5:3) and says nothing of the Adventure's; the tree fell back to `loot_slots.size()`, one item per slot per clear, which made dressing the twelve for Raid 1 (12 feet + 12 weapons over two rolls, 12 legs over one, 24 head/chest over two) a 36-clear farm against docs/11 §4.3's ~9-attempt tier budget. `Loot.ADVENTURE_ROLLS_PER_SLOT = 2` (`sim/core/Loot.gd`) halves it to 18 — A1 4 rolls, A2 4 (two slots once the off-hand slot lands — Q-35), A3 4; the raid's `RAID_ROLLS` are untouched. BL-31's upgrade bias keeps the extra rolls from becoming a gold faucet until every raider is dressed; the Tier 1 boundary balance is re-read by the playtest's `peak_gold` column against docs/11 §4.4's 0-20 % band. The designer's Adventure hands out the tier's SET (the ideaboard's Tier 1 Adventure gear is a four-piece set per family plus weapons and charms, assigned to the Adventure, not to an encounter) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-112"></a>
### BL-112 - A wiped tutorial costs morale like any wipe *(DECIDED - the ship default kept; no code)*

**Owner:** [05 §7.1](./05-morale.md) / [10 §9.3](./10-content-and-encounters.md) - **Signal:** LOOP-24's first-hour path (wipe TR, skip it, six Commons at 34 cannot clear A2)

docs/05 §7.1 has no tutorial exemption and gains none: a wiped Tutorial Raid pays the wipe row (−8, ×1.35 for a Common) and the culprit's −4 ([BL-107](#bl-107)). The Tutorial Raid is the fight designed to be lost and its Wipe Report is read on the roster page too — "Oh shit, Steve is at 14" is the designer's own description of the game, and a wipe that costs nothing teaches that wipes cost nothing. With TR winnable at ~55 % (Q-100) the expected cost is one wipe, recovered by drift in ten ticks or two A0 re-runs (+6 cleared, +3 brought per tick; docs/10 §9.3 keeps a resolved tutorial replayable for gold). LOOP-24's path is closed by BL-110 (A2 sized for stage 0) and Q-100, not by a fifth canon number; `GameState._apply_raid_morale` keeps no tutorial branch — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-113"></a>
### BL-113 - The Forgiving Guild toggle ships: one multiplier, 0.75, on mistake chance and enemy HP *(DECIDED - built; W8-SIM-BALANCE · W8-KEYS · W8-CRISIS · W7-SAVE)*

**Owner:** [00 §6.4](./00-vision-and-pillars.md) / [08 §11](./08-stats-and-formulas.md) / [13 §15.1](./13-ui-ux.md) / [16 §11 C13](./16-production-roadmap.md) - **Signal:** CRITIC-M1: the docs' one relief valve was in the cut order's LAST slot and not in any wave

docs/00 §6.4 as written: off by default, switchable at any time, no achievement or content gating, touches only mistakes and boss HP. `Formulas.DIFFICULTY_MULT` (default 1.0; 0.75 under `forgiving_guild`) multiplies `mistake_chance_bp` BEFORE the clamp so the per-rarity floors hold (a Common at 45 reads 29.8 % × 0.75 = 22.4 %, above the 12 % floor) and enemy `max_hp` at build (rounded to 5); it arrives as `RaidSim.run(..., opts.difficulty_mult)` because the sim may not read GameSettings, is written into `active_run.difficulty_mult` and the attempt record by `record_attempt` so Results' stored-seed replay (Q-53) is the fight that happened, and is swept as a second axis (`balance_sweep.gd --forgiving`). `GameSettings.forgiving_guild: false`; one Options row on the kit's cycle chip — "Forgiving Guild — fewer mistakes, softer bosses. Changes nothing else."; docs/13 §15.1 gains the row; docs/16 C13 is not cut (C5 and C8 ship, and nothing lower is cut while something above it is in). It is a relief valve for the two named spirals and was NOT used to make the playtest green — the on-ramp is sized at 1.0 (BL-110). Achievements unlock under it; the Records tab prints nothing about it. Audit `m6-forgiving-guild` closes — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-114"></a>
### BL-114 - Wipe by attrition fires at the enrage round plus a named grace of 5; the 40-round cap stays the safety *(DECIDED - implemented; W8-SIM-BALANCE)*

**Owner:** [10 §5.2, §6](./10-content-and-encounters.md) / [07 §7.3](./07-combat-simulation.md) - **Signal:** SIM-12: an unstated `+ 5` every baseline clear rate was measured under; the plan's default deleted the DPS check from seven of Tier 1's eight fights

`RaidSim.ATTRITION_GRACE_ROUNDS := 5` — the value the tree has run since the mech-arms unit — now named and overridable per record as `attrition_grace` (validator `>= 0`); `_check_end` reads it; the 40-round cap (docs/07 §7.3) remains the safety property, not the rule. At `enrage_round` every fight without an authored M06 logs a Story line — "Round 17. The boss has stopped being careful. Five rounds before this stops being a fight." — so a loss on the clock reads as a countdown, not a crash. With Focus out of 1.0 healing is unlimited, so the enrage clock is the ONLY thing that stops a stable-but-weak raid grinding any fight to a win over 35 rounds; the baseline (A1 starting/Common/55: 57 of 200 outcomes on the clock; E5 raid_entry: 39 of 200) shows it is a live lever. It is load-bearing for BL-110: A2's mean kill clock at 45 is 13.1 rounds against an enrage of 14 — without the grace the tails fail and the on-ramp bands cannot hold. Pinned by `test_raid_sim.gd::test_attrition_fires_at_the_enrage_round_plus_the_grace` (replacing the plan's `test_attrition_only_at_the_round_cap`); docs/07 §7.3's table gains the row and docs/10 §6's "enrage expiry" gets the number — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-115"></a>
### BL-115 - E4's mechanics are authored, not implied: M05's effect, M08's window, M09's cadence *(DECIDED - implemented; W8-SIM-BALANCE for Tier 1, W9-TIERS through the generator for tiers 2-5)*

**Owner:** [10 §7.4, §10](./10-content-and-encounters.md) / [08 §9.5](./08-stats-and-formulas.md) - **Signal:** SIM-13: M05's "effect E" was never named; M08 authored as a permanent fixate by accident; handoff-mech-arms #2 never applied

M05 Interrupt Check carries `effect {"kind": "raid_damage", "amount": 27}` on `round 4, every 5` — the tier's M02 pulse, 08 §9.5's `AOE_BITE_FRACTION × cloth_max_hp` as the generator already computes it for E3 — so a missed interrupt is a second pulse the healers did not budget for; M08 Fixate is a window, `{"rounds": 2, "every": 6}` (the recommendation's 5 moved to 6 so the fixate never overlaps the debuff it would otherwise make decorative); M09 Healing Debuff recurs, `{"reduction_pct": 40, "rounds": 3, "round": 3, "every": 6, "target": "active_tank"}` — live while the boss is on the tank, never while it is chasing someone else. Over 17 rounds: M09 live 3-5 / 9-11 / 15-17, M08 6-7 / 12-13, M05 checks at 4 / 9 / 14 — the three mechanics visibly take turns, which is the fight a player can read coming (docs/07 §8.2). `Encounter.validate()` refuses an M05 spec without `effect.amount > 0` and an M08 `rounds` not strictly less than its `every`. E4 falls from its measured 200/200 at Common/raid_entry/55 — the ★★★★ buys teeth; its band is Q-100's 60 (45-75). Pinned by the `e4_rares_raid_entry` golden and `test_encounters.gd`; tiers 2-5 inherit the three rules through `gen_items.gd` (W9-TIERS) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-116"></a>
### BL-116 - The break phase exists, in `game/`: MIS_NINJAPULL is built, not cut *(DECIDED - implemented; W8-CRISIS the roll, W8-SIM-BALANCE the sim, W7-SAVE the key)*

**Owner:** [07 §4.1, §5.2 row 14](./07-combat-simulation.md) / [14 §3.1](./14-technical-architecture.md) / [BL-24](#bl-24) - **Signal:** CONTENT-12: eight of the corpus's best lines behind a type no path reached

When the player presses Depart on a raid encounter and the mission already has an attempt this town cycle (a clear or a wipe — either is a break), `GameState.start_attempt` rolls one ambient check per living party member on a new seeded channel `break` (derived from the attempt seed like the others) with `ctx.break_phase = true`; only a MIS_NINJAPULL draw counts, the first in slot order pulls, at most one per break. The sim receives `mstate.ninja_pulled` (a raider id) and starts the fight with the provisions unapplied and unconsumed (every item listed in `result.consumables_unspent` with reason `ninja_pulled` — the potions are still in the bag), the mistake emitted through `_log_mistake` at round 1 ROUND_OPEN at its base Critical band with `Token.DISTRACTION` live (+5pp raid-wide, 2 rounds) and a line from the type's own variants — the perfect culprit for BL-107: "It traces back to Greg — Ninja-Pulled During the Break, round 1." Adventures, the tutorials and a raid's first pull have no break (NINJAPULL is in `TUTORIAL_DISABLED_TYPES`). The roll's result is written into `active_run.ninja_pulled` (default "") and the attempt record, and passed back into `RaidSim.run(..., opts)` by Continue's re-run and Results' replay, so the replay is a pure function of what was stored (Q-53's commit rule). Expected rate per break with the type's ambient share: a full Common party at Content ≈ 48 %, Rare ≈ 21 %, Epic ≈ 9 %, Legendary ≈ 3 % — the worst guild pulls early every other break and it stops as the roster improves; `balance_sweep.gd` never sees it (it calls the sim), so Q-100's curve is measured without it, stated. `Mistakes.NINJAPULL_REACHABLE` is not built; the type is never flagged unreachable; the eight lines stay. Pinned by `test_raid_sim.gd::test_a_ninja_pull_starts_the_fight_unbuffed_and_names_the_puller` and `test_game_state.gd::test_the_break_rolls_only_after_a_first_pull` — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-117"></a>
### BL-117 - The nine Legendaries are named: Gunnar, Ottilie, Alder, Natsuna, Solenne, Casimir, Tallis, Isaura, Lorcan *(DECIDED - W8-ITEMS sets `display_name`; the `name_pending` fallback is not built)*

**Owner:** [03 §5.6](./03-reputation-and-town-progression.md) / [04 §7, §11.1](./04-raiders-recruitment-and-classes.md) - **Signal:** SHIP-04's eight legendary holds on the export gate

Canon: "You can only ever find 1 Legendary per class — They are also named characters — IE Natsuna(the shaman) or something." Natsuna (Shaman) is final; the eight are Gunnar the Warrior ("Front is where I stand. Move."), Ottilie the Cleric (has your old raid logs printed out), Alder the Druid (would raid naked; home is "somewhere with trees"), Solenne the Mage (notices when someone is wearing last tier), Casimir the Wizard (counts ninety seconds; was the only one laughing), Tallis the Rogue (keeps his own numbers; was behind it the whole time), Isaura the Monk (turns around three times before every boss), Lorcan the Bard (arrives as the pull starts; knows the tavern staff by name) — given names only, two or three syllables, from no single culture, none a surname, a public figure or a name in docs/04 §7's mundane pool, each fitted to the character its file already draws and sitting outside the Bob/Greg/Steve register as Natsuna does; the four pronouns the files carry are honoured; initials all distinct so the Records meter's nine rows scan. Grepped against `data/`, `game/`, `sim/`, docs: no collision. `data/legendaries/*.json` `display_name` set, `name_pending: false`, `name_status` "ruled by the loop, 2026-09-15 delegation"; docs/03 §5.6's two ❓ OPEN rows close; the Records meter reads 9-of-9; the `Recruitment` `name_pending` guard, the `_pending/` move and the N-of-named meter are dead branches and are not built. The nine busts are drawn by `derive_busts.py`'s named pass (W9-ART) — a named person, not a rarity re-hue — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-118"></a>
### BL-118 - The comedy gate and the name pool are reviewed by the loop, in one sitting, in W9-REVIEW *(DECIDED - the read is the loop's; BL-53 resolves with it)*

**Owner:** [04 §7](./04-raiders-recruitment-and-classes.md) / [07 §10.3](./07-combat-simulation.md) / [16 R-3](./16-production-roadmap.md) - **Signal:** M5-COMEDY-12 / CONTENT-16: two human reads with no reader

The name pool (36 given names, 20 epithets, six mangles) and the corpus (192 type lines, 36 Legendary lines, 42 encounter lines, 68 item notes, 72 backstory bullets, 40 achievement blurbs, plus the 21 boss titles, 20 tier words and 8 Legendary names ruled today) are rendered on one page by `tools/corpus_review.py` and read in one sitting by W9-REVIEW's reviewing agent — not the writer — against docs/04 §7's standard and docs/07 §10.3's five rules (never punches down, never blames the player, never lands on a real person); the keep / rewrite / cut marks are `build/plan/ship/corpus-review.md` and are applied in-wave by `--apply`, every rewrite re-validated by `MistakeLines._check_writing_rules` and the budget test. BL-53 → RESOLVED; `data/mistake_lines.json`, `names.json` and `achievements.json`'s `_notes` say who read them and when; the NINJAPULL lines are kept (BL-116). The residual risk docs/16 R-3 names — that a validated, reviewed line still does not land — is accepted in writing and answered after ship by player reports, not by a further gate; the page ships in the tree so the designer can file marks as a 1.0.x data patch. W9-REVIEW runs after W8-ITEMS's and W9-TIERS's regenerations — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-119"></a>
### BL-119 - The 21 boss rungs carry a role title through spec 00 §2.3's `title` field; everything else keeps canon's placeholders *(DECIDED - W7-REPORT the field and TR; W8-SIM-BALANCE A3/E3-E5; W8-SCALE-1 the prep card; W9-TIERS tiers 2-5)*

**Owner:** [10 §2](./10-content-and-encounters.md) / [art/ref/specs/00 §2.3](../art/ref/specs/00-reference-concepts.md) / [09 §10.2](./09-items-and-itemization.md) / [Q-84](#q-84), [C-19](#c-19) - **Signal:** "Main Boss" as the boss's only name on the plate; canon: "obviously they will need names later"

The vocabulary is "Encounter N" in every UI string and "Boss N" only as the loot tables' `boss` key; the ladder words ("Raid 1", "Adventure 2") and the enemies' log names ("Trash", "Elite", "Add", "Mini Boss", "Main Boss") are canon's placeholders shipped as final ([BL-101](#bl-101) stands for them). The boss rungs get a name in the optional `title` field spec 00 §2.3 defined (shown in the title slot, the ladder words dropping to the subtitle "Raid 1 — Encounter 5 · Main Boss"): Tutorial Raid **The Doorman**; A1 **The Gatekeeper** · A2 **The Tollkeeper** · A3 **The Cartographer** · A4 **The Groundskeeper** · A5 **The Lamplighter**; Raid 1 **The Understudy** (E3) · **The Orator** (E4) · **The Landlord** (E5); Raid 2 **The Sweeper** · **The Auditor** · **The Encore**; Raid 3 **The Librarian** · **The Choirmaster** · **The Creditor**; Raid 4 **The Censor** · **The Surveyor** · **The Chronicler**; Raid 5 **The Usher** · **The Proctor** · **The Last Word**. Roles rather than creatures because one boss set serves five tiers (BL-100) and a creature name would be a lie the art tells four times over; each is a job the guild is failing an interview for, in the record wall's register, and fits its mechanics (the Doorman teaches the door; the Librarian is Raid 3's silence; the Encore kept going nineteen rounds; the Last Word is the last boss and the log will still say Steve stood in something). Enemy `name`s are untouched so no golden moves. `sim/model/Encounter.gd` `title: String = ""`; the RaidView boss plate and the RaidPrep card sub-line (title over kind when present); `test_encounters.gd` asserts a non-empty `title` on every mini_boss/main_boss rung and none on trash; tiers 2-5 through `gen_items.gd`'s encounter table. The tutorial trinkets are docs/09 §10.2's "Cracked Charm of Power" / "Cracked Charm of Health" (docs/01 §8.2's and docs/10 §9.2's "Trinket of Mild Competence / Faint Encouragement" struck — "Cracked" is the register's word for crap and the template generates). Q-84 and C-19 close — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-120"></a>
### BL-120 - A shape-B handle is the raider's name everywhere; nothing restyles it *(DECIDED - no code; docs/04 §7 gains one sentence)*

**Owner:** [04 §7](./04-raiders-recruitment-and-classes.md) / [00 Pillar 2](./00-vision-and-pillars.md) - **Signal:** TOWN-20 / UI q2: "Pauline_4 reads as a collision suffix"

It is a collision suffix, in-fiction: Pauline was taken, so she is Pauline_4, and she has answered to it for nine years. The handle is the display name on the card, the roster, the log and the wipe report, and is never restyled ("goes by Pauline_4") or explained — a second name line breaks Pillar 2's `Name — NN <face>` row and puts two names on one person. Shape B produces it at ~4 % of hires, a running gag, not a generator; it is funnier in the log ("Pauline_4 stood in the fire") than on a card. `NamePool.gd:189-190` unchanged — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-121"></a>
### BL-121 - 1.0 is the twelve-entry canon ladder, Adventure 0 through Raid 5; `tier_is_named` is a top-down valve, never a return to Tier 1 *(DECIDED - W9-TIERS's long branch; the no-words branch is not built)*

**Owner:** [00 §6.3, §8.2 R1](./00-vision-and-pillars.md) / [BL-69](#bl-69) / [BL-73](#bl-73) - **Signal:** CRITIC q5 / SHIP q3: the release shape hung on words that have now come

With the tier words (Q-41) and the Legendary names (BL-117) ruled, W9-TIERS runs its "words came" branch: the 16 files regenerate, `--tier=N` sweeps at each tier's own gear stages, one golden per new mechanic's first carrier, the walls as rows, S17 on the first clear of Raid 5. The Tier-1-only ending survives only as the mechanism it already is (`ContentDB.tier_is_named`, `GameState.COMPLETED_AT = "last_named_tier"`): if the per-tier pass measures a tier uncompletable at its own gear stage over eight seeds, that tier's `pending` flips back to true (a one-key data edit), the ending retimes to the tier below and the row records the numbers — docs/00 §6.3's cut order ("Raid 5 and Adventure 5, shipping a 4-tier ladder"), top down, never Raid 2-4 and never back to Tier 1. `data/_pending/` is never created; W10-EXPORT's pending-file list is empty; the README's "smaller game" line is not written; Completion's copy is the five-tier line. The Legendaries become reachable (Renowned at 1,800 RP is arithmetic only tiers 4-5 pay) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-122"></a>
### BL-122 - The Legendary find rate is the endgame's clock, not a content gate *(DECIDED - accepted; nothing retimed)*

**Owner:** [03 §5.2, §5.4, §6.4](./03-reputation-and-town-progression.md) / [10 §13](./10-content-and-encounters.md) / [Q-23](#q-23), [Q-88](#q-88) - **Signal:** M5-END-5: 5 % at a rank with nothing left to serve

The 5 % at Legendary rank (`find_weights [0,0,0,950,50]`) and the 3200 RP threshold stand; the continuing activity after Raid 5 is the 9-of-9 collection (Q-88), whose expected length at 5 % per candidate is ≈ 180 generated candidates, ≈ 30 Tavern boards at six a board — the endgame's length, by design, and the designer's own trophy case ("one Legendary per class, named"; Octopath's eight travellers: the game is done when the party is). Retiming the rate earlier would spend the prize on a rank that still has raids to gate. docs/03 §5.4 gains one sentence saying so; docs/10 §13 row 3 closes "accepted"; the pacing tests are untouched; with five tiers mounted (BL-121) Renowned pays and the rule has a 1.0 player — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-123"></a>
### BL-123 - The aerial town is an establishing shot: motion, no figures *(DECIDED - as built; deferred in writing)*

**Owner:** [12 §3.2](./12-art-direction.md) / [art/ref/specs/09 §3](../art/ref/specs/09-background-plates.md) - **Signal:** M4B-ACT-04: the 21-48 px strips scaled to 0.3 destroyed the pixel art

The MainMenu's aerial plate carries sails, gulls, clouds, the fountain and the waterfall and no figures, because no sprite the project owns reads at 10-14 px and downsampled pixel art is blur ("nothing blurry"); Octopath's title pan has no ants either. Aerial-scale townsfolk are post-1.0 (`gen_townsfolk.lua`, PIPE-09). `stage_town.json`'s "no actors" note is the record — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-124"></a>
### BL-124 - Hall framing is "same" and the roster is margins-only *(DECIDED - as built)*

**Owner:** [13 §2 M5](./13-ui-ux.md) / [BL-78](#bl-78) - **Signal:** Q03

`Guildhall.HALL_FRAMING = "same"`: the hall family (Guildhall, Roster, RaiderDetail, Settings, LoadSave) is a panel over the hub's own camp framing — Town → Guildhall reads as a panel opening over the place you were already looking at, which is the desk not moving; the guild lives in the camp (BL-78). A 3-column roster spends 250 px of a 12-card roster on a fire ring. `FRAMINGS["tight"]` stays built as the recorded alternative — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-125"></a>
### BL-125 - Header chip 2 wears the rank sigil, not a gem, and never the word "Rep" *(DECIDED - `Frame.REP_ICON = "sigil"`; W9-POLISH; spec 00 §2.5 amended)*

**Owner:** [art/ref/specs/00 §2.5](../art/ref/specs/00-reference-concepts.md) / [13 §8.1](./13-ui-ux.md) - **Signal:** UI-53 / LOOP-05 / CRITIC-C5: a gem beside a number reads as a currency the player cannot spend

Canon has one guild stat ("Your guild has a single primary stat: Guild Reputation") and one currency, gold; a gem beside a number is a second currency. Chip 2 shows the reputation points beside the current rank's sigil (the existing `rank_<name>.png` — no new asset), carries no word, and its tooltip reads "320 reputation · 80 more to Known" (the word in full, docs/13 §8.1's discipline). `gem.png` stays for the Board's trinket row, which is a trinket, which is right. `test_frame_header.gd` asserts the tooltip contains "reputation" and the texture is `rank_<name>` — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-126"></a>
### BL-126 - No depth of field ships and none is owed *(DECIDED - off; docs/12 §2.2 row 6 and docs/00 VS7 amended)*

**Owner:** [12 §2.2, §3.1, §6.1](./12-art-direction.md) / [00 VS7](./00-vision-and-pillars.md) - **Signal:** Q08

The plates are the designer's own 1:1 pixel art at display density (docs/12 §3.1's supersession: no pixel pitch above 1); Octopath's tilt-shift blurs 3D planes, and a blur here would smear the designer's pixels — the one thing "nothing blurry" forbids. The vignette stays behind `reduced_effects`; the scene `dof` key stays absent as the post-1.0 hook. docs/12 §2.2 row 6 ("non-negotiable") → "optional, OFF — the plates are authored sharp at 1:1"; docs/00 VS7 → "lighting, parallax and ambient motion present; no depth-of-field on 1:1 plates" — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-127"></a>
### BL-127 - Accessibility: the three-state ramp is corrected and CVD-verified; the text floors stay; `prose_font_swap` is retired; the logotype is a mark *(DECIDED - W8-KEYS the palette; W7-DOCS the doc rows; W10-DELETE the key)*

**Owner:** [13 §8.3, §13, §14, §15.1](./13-ui-ux.md) / [art/ref/specs/04 §5](../art/ref/specs/04-palette.md) - **Signal:** M6-A11Y-06 / UI-47 / RULES-08/09: the reference's sampled trio was not lightness-ordered (amber L* 78.5 above green 69.3; 2.2 L* apart for a protanope)

(1) The ONLY morale/success ramp is the reference's red / amber / green family corrected so it is lightness-ordered: `DANGER #F73526` (unchanged), `CAUTION #E8A302`, `POSITIVE #AFEBA2` — L* 54.5 / 71.8 / 87.6, every adjacent step ≥ 5 L* and monotone under none, protanope (42.5 / 68.5 / 89.6), deuteranope (59.5 / 73.5 / 86.4), tritanope (72.4 / 78.6 / 84.9) and greyscale (`tools/art/cvd.py`, Brettel/Viénot); contrast on `SURFACE_INSET` 4.81 / 8.47 / 13.34. docs/13 §8.3's ten-plate table is struck (band 0's fill is 1.35:1 on `SURFACE_PANEL` and cannot be text on navy); the other seven bands ride the integer, the word and the glyph, which is §13's first row. `colourblind_safe` (default Off) stays and means a hue swap of the third state only — `POSITIVE_CVD #C6DDF1` (L* 85.8) for eyes that do not separate red from green; the Settings note: "Morale's third colour is sky instead of green, for eyes that do not tell red from green. The number and the state word are unaffected." The criterion, confirmed: ΔL* ≥ 5 between adjacent ramp steps under all five observers, monotone (the 3:1-per-step half is struck as arithmetically unreachable). `Palette.CAUTION`/`POSITIVE` take the hexes; `BAND_FILL_CVD`/`BAND_INK_CVD`/`band_ink_cvd` are deleted; `band_color_cvd` returns `[DANGER, CAUTION, POSITIVE_CVD]`; `morale_color` goes through `band_color_active`; `test_palette_cvd.gd` asserts the numbers; the art-gate baselines re-record at the wave-8 close inside the 0.07 jitter. (2) `Type.SMALL 13` / `STACK 11` stay: docs/13 §13's 14 px floor is read in §4.2's 1920-wide authoring frame (13 in the 1536 frame renders at 14 whole pixels at 1080p); the 125/150 text scale is the remedy. (3) `prose_font_swap` is retired — Fira Sans is the only body face and there is nothing to swap from; the row is hidden now and deleted with its key in W10-DELETE; §13's font-choice row and §15.1's row are struck. (4) The pre-rendered logotype (`gen_wordmark.py`, an OFL face) is a mark, not text, and exempt from §14's "no text in art"; the words are also a Label beside it. §15.1 gains "Colour-safe morale ramp | Off | §13 | Player | Global"; `test_a11y_legibility.gd`'s `BELOW_FLOOR_AT_1920` becomes the record of the ruling, not a defect list — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-128"></a>
### BL-128 - The morale faces are ten authored sprites, never system emoji *(DECIDED - as built; `Fonts.MORALE_FACE_FONT = true`)*

**Owner:** [12 §5.2](./12-art-direction.md) / [art/ref/specs/00 §2.1](../art/ref/specs/00-reference-concepts.md) - **Signal:** Q17

Canon's "Natsuna — 87 ❤️ … Steve — 14 😡" is the designer's shorthand for a face beside the number; in a 2D-HD frame the only reading is a pixel face at integer scale (Octopath's UI contains no system glyph; It's A Wipe! draws its mood faces). docs/12 §5.2's reading is confirmed; `emoji_free` keeps its pip figure — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-129"></a>
### BL-129 - "Screen shake on wipes" is struck *(DECIDED - BACKLOG carries the strike; M6-JUICE-04 closes)*

**Owner:** [13 §11.4, §12.2, §13](./13-ui-ux.md) - **Signal:** M6-JUICE-04

docs/13 §11.4 ("No 'You Failed', no red flash"), §12.2 ("Nothing in the UI loops, pulses, or breathes") and §13 (reduced flashing is unconditional) forbid it; a wipe is the joke, not the punishment, and the comedy lands on the report. The wipe's beat is the WIPE stamp press, the 12 % dim and the seal; the camp's fallen lie down (W9-ART) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-130"></a>
### BL-130 - The game opens borderless fullscreen and letterboxes the 1536×1024 frame *(DECIDED - as built by W6-SETTINGS; spec 00 §4's first item closed)*

**Owner:** [13 §15.1](./13-ui-ux.md) / [14 §10.4](./14-technical-architecture.md) / [art/ref/specs/00 §4, 11 §1](../art/ref/specs/00-reference-concepts.md) - **Signal:** SHIP-06: a first launch taller than a 1366×768 laptop hid the commit row

`window_mode = "borderless"` (F11 / Alt+Enter to a 3:2 window that fits the desktop) and `display_aspect = "keep"` — every player sees exactly the designer's 1536×1024 composition; `expand` is the opt-in for players who accept the plates' edges (spec 11 §1's revised decision, made on a 1920×1080 Town shot where expand exposed the plate's edge). SHIP's README line and export check state the same defaults — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-131"></a>
### BL-131 - Spec 00 §2's reference-concept conflicts are confirmed in canon's favour *(DECIDED - confirmed; §2.5's gem ruled by BL-125)*

**Owner:** [art/ref/specs/00 §2.2-§2.6](../art/ref/specs/00-reference-concepts.md) - **Signal:** DESIGNER-45

Tiny/Ranger → Rogue (nine classes, raw notes); no creature names or raider levels from the references — the loop's 21 role titles land through §2.3's own `title` field (BL-119) and `Raider.level` is never set (Q-14); twelve cards, paged; "Day N · Rank" in place of the clock; the rail's canon labels; §2.5's gem is the sigil (BL-125). The references set the art bar; where their content contradicts canon, canon wins — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-132"></a>
### BL-132 - The credits name the lead designer by the handle in the tree, the build loop and the tooling honestly, and close in the game's voice; `© 2026 Malkail`; version 1.0.0 *(DECIDED - W10-CREDITS · W10-EXPORT · W10-README; M5-END-4 closes)*

**Owner:** [00 §4.4.1, §4.4.2](./00-vision-and-pillars.md) / [13 §9.5](./13-ui-ux.md) - **Signal:** M5-END-4: no doc names a contributor; the only public name the designer wrote into the tree is the folder `screenshots from malkail the lead game designer`

`data/credits.json` `lines`, in order (the marker line deleted; `status` cleared): "Malkail — lead designer" · "Built from the designer's notes by an autonomous build loop (Claude)" · "Art drawn by script in Aseprite and Python from references the designer supplied" · "Sound and music generated in-house from physical models" (W10-CREDITS reads `Audio.MUSIC_BED` before it writes the line: "Sound generated in-house from physical models" if the lute was cut) · "Made with Godot Engine (MIT)" · "Fira Sans and Grenze Gotisch — SIL Open Font License 1.1" · "The raiders would like it known that they did their best." Seven Labels, none containing "pending"; the closer collides with nothing in `data/`. `project.godot` `config/version="1.0.0"`; `export_presets.cfg` `file_version`/`product_version` "1.0.0.0", `application/copyright="© 2026 Malkail"`, `company_name` "A Guild Story". README.md and `README-player.txt`: "© 2026 Malkail. All rights reserved. Made with Godot Engine (MIT). Fira Sans and Grenze Gotisch are used under the SIL Open Font License 1.1; the licence texts are beside the .exe." plus the disclosure the stores require, also docs/00 §4.4.2's last bullet: "The game's code, pixel art, copy and sound were generated by an AI build loop from the lead designer's own design and under their direction; the reference art was image-model output the designer supplied." — it names no other game and describes this one on its own terms. `test_export.gd` asserts version ≠ "0.1.0" and a non-empty copyright; `test_completion.gd` asserts seven lines. A real name replaces the handle by editing exactly three strings (`credits.json` line 1, `export_presets.cfg`'s copyright, the README line) — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-133"></a>
### BL-133 - 1.0 ships keyboard + mouse and one language: a pad works unverified and unsupported, no glyphs or rebinding, no second language, no pseudolocale pass *(DECIDED - W10-DELETE the rows and keys; W10-EXPORT the README sentences; W7-DOCS docs/13 §15.1)*

**Owner:** [00 §6.1](./00-vision-and-pillars.md) / [13 §15.1, OQ-12](./13-ui-ux.md) / [16 W4.8, C6](./16-production-roadmap.md) - **Signal:** SHIP-20 / LOOP-26 C19-C20: two hidden Settings rows with nothing behind them

The joypad events in `project.godot` stay (A/B/X/Y/Start bound; the D-pad steps focus through Godot's defaults — deleting them would be a regression for nothing); no glyph set, no rebinding, no Deck verification (docs/16 C6 prices all three as the Deck milestone, after 1.0 per docs/00 §6.1). `README-player.txt`'s Controls block ends: "A gamepad will steer the menus — D-pad to move, A to confirm, B to go back, Start for options — but is not a supported input in this release: no button glyphs, no rebinding, and nothing has been tested on a Steam Deck." One language, en-US — the only string table that exists; `TranslationServer` is called nowhere under `game/`; a translation of a comedy is a content project with its own reviewer (docs/16 W4.8). No `xx-LONG` pass: the 150 % text-scale sweep (`test_a11y_legibility.gd`) is the layout proof that stands in for it until a translation exists. `Settings.ROWS` loses `glyph_set` and `language`, `GameSettings.DEFAULTS` the two keys (an old `settings.cfg`'s unknown keys are ignored — asserted); docs/13 §15.1 loses both rows and gains "One language (en-US) and keyboard + mouse in 1.0; localization and pad support are docs/16 W4.8 / C6"; OQ-12 closes; "Known limits" lists "English only" — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-134"></a>
### BL-134 - 1.0 ships unsigned; the README-player tells the player the two clicks; the zip's SHA-256 is in the release record *(DECIDED - W10-EXPORT · W10-README · W10-WALK)*

**Owner:** [14 §10.1](./14-technical-architecture.md) / [00 §4.4.2, §6.1](./00-vision-and-pillars.md) - **Signal:** SHIP-16: no row on signing; a certificate is money and a legal identity the tree does not have

`README-player.txt`, under "Known limits": "The .exe is not code-signed. The first time you run it Windows may show 'Windows protected your PC' — click **More info**, then **Run anyway**. Nothing is installed; the game keeps its saves and settings under %APPDATA%\Godot\app_userdata\A Guild Story\." Step 9 of `export_build.sh` prints `sha256sum` of the zip as its last line; W10-README copies the hash into the release commit's message and BUILD_STATE's wave-10 entry (it cannot live inside the zip it describes); W10-WALK records the SmartScreen prompt as seen on the second machine. SmartScreen's reputation is earned by downloads, as every itch.io release earns it. A certificate is post-ship — one `signtool` line between steps 8 and 9, filed in BACKLOG — if the designer buys one under a legal name — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-135"></a>
### BL-135 - The `new` and `play` fixtures carry no level; the reference fixture keeps its four levels as data and they stop rendering *(DECIDED - W6-SHEETS; the branches go in W10-DELETE per Q-14; `diff_all.sh` re-recorded at the wave-10 close)*

**Owner:** [art/ref/specs/00 §2.3](../art/ref/specs/00-reference-concepts.md) / `tools/fixture_reference.gd` - **Signal:** UI-15 / LOOP-01: "Bork Lv. 12" on every review sheet

`--fixture=new` and `--fixture=play` (`apply_new`/`apply_play`) carry `level` 0 everywhere and a legal Known state earned through `record_attempt`; every wave's review sheet from wave 6 on is `new` or `play` (the reviewer's one look is `build/shots/all/new/_sheet_1.png` with no "Lv."). The plain `--fixture` reproduces the concepts and keeps its `CARDS` levels 12/11/9/10 as DATA (`test_w0_shot.gd:144` pins "the concept's Lv. stays on the reference"); when W10-DELETE deletes the two `Lv. N` branches (Q-14) the four glyph runs stop rendering, and `diff_all.sh` is re-recorded once at the wave-10 close with before/after numbers in W10-README's entry (four "Lv. 12" runs on a 1536-wide sheet sit inside the 0.07 jitter). Spec 00 §2.3's "the card shows `Lv. N` only when `level > 0`" becomes "no level is shown" — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-136"></a>
### BL-136 - One bubble chrome; `SceneStage.EMOTE_MAP` is the one emote table, in two halves *(DECIDED - W9-ART; the Town mood pick by handoff to W9-POLISH; the RaidView line by handoff to W9-SCALE-2)*

**Owner:** [12 §5.3](./12-art-direction.md) / [art/ref/specs/07](../art/ref/specs/07-assets-sheet-a.md) / [05 §5](./05-morale.md) - **Signal:** Q04: two loose proposals (DESIGNER-29's seven rows, UI-41's ten)

One chrome everywhere — Concept 3's dark callout plate. `EMOTE_MAP.FIGHT` (over the figure the log line names, for the line's dwell): MINOR → `question`, MODERATE → `sweat`, SEVERE → `anger`, CRITICAL → `exclaim`, downed → `skull` (stays while down), the Bard's song → `note` (over the Bard) — canon's ❤️ 🙂 😒 😡 ladder read for one mistake instead of one raider; docs/12 §5.3's "!" is reserved for the loudest line. `EMOTE_MAP.MOODS` (`Town.set_mood()`, one at a time, priority top-down): `wipe` → the camp's skull, `cleared` → a new heart bubble, `at_risk` (any roster raider below 40 — docs/05's "noticeably higher mistake chance" band) → the camp's sweat bubble, which stops being ambient; `question`, `anger`, `exclaim`, `note`, `mug`, `zzz`, `dots` are the scene author's ambient decor. `stage_camp.json` gains the `at_risk` tag on the sweat bubble and one `[x, y, "emote:heart", "cleared"]` entry; `RaidView._line_effects` calls `stage.emote(id, EMOTE_MAP.FIGHT[sev])` on a MISTAKE line under `_effects_allowed`; UI-41's 24 px glyphs and `figure_scale` bubble sizing land with it; the cards keep the morale faces (BL-128). `test_scene_stage.gd`: every `Severity` has a fight glyph and every mood a bubble on the camp — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-137"></a>
### BL-137 - The header lockup is the 44 px mark plus the tagline; overhead bars are badge + pips on every figure and the HP bar on the acting or struck figure only *(DECIDED - as built)*

**Owner:** [art/ref/specs/00 §2.7](../art/ref/specs/00-reference-concepts.md) / [13 §8](./13-ui-ux.md) - **Signal:** Q05 / Q07

`Frame.LOCKUP = "44_tagline"` — "Questionable people. Worse decisions." is the premise in five words and the designer's own sentence; it belongs on every framed page. The overhead rule (UI-21's extension of Q07): class badge + pips on every figure, the full HP bar only on the acting or struck figure, the stack hidden on back ranks except that figure — how twelve overheads stay off the floor — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-138"></a>
### BL-138 - Five generated ambience beds ship — camp, tavern, market, cave, dungeon — keyed by scene through one door; the aerial plays the camp bed by design *(DECIDED - W7-AUD-AMB; `amb_cave` is the dungeon's shed-fallback, never the camp)*

**Owner:** [Q-98 (ii)](#q-98) / [13 §12.4](./13-ui-ux.md) - **Signal:** AUDIO-07's table left the dungeon on a campfire

`amb_dungeon`: the cave's 40-120 Hz hollow rumble, a chain-creak (`stick_slip` at 2-4 Hz, 1.2 s, every 9-17 s) and a distant stone fall every 20-40 s; no drip; 25 s, the same loop fold; all beds 44.1 kHz mono 16-bit, RMS −30 dBFS / peak ≤ −20, 600 ms equal-power crossfade. `Audio.BEDS` = {camp, tavern, market → their own; `stage_arena_cave` → `amb_cave`; `stage_arena_dungeon` → `amb_dungeon`; `stage_town` → `amb_camp`}; the door is the one line in `SceneStage.load()`. Raid 1 is the dungeon's reveal (Q-96) and a campfire under it would tell the ear the plate lied; the main menu hearing the guild's own fire before the player sees it is the right first sound for "you are the guild leader" — the aerial is the camp from above, not a placeholder; a town-aerial bed is post-1.0. `gen_amb.py --check` prints 5 AGREE; the dungeon bed is not the camp's bytes — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-139"></a>
### BL-139 - The encounter's comedy line stays on every Results page as the notice's epigraph under "The notice said:"; RaidView's exits stay live from round 1 *(DECIDED - `Results.COMEDY_LINE = "epigraph"`, W7-REPORT; `EXITS_GATED = false` as built)*

**Owner:** [01 §9](./01-core-loop.md) / [13 §11.2](./13-ui-ux.md) / [10 §7](./10-content-and-encounters.md) / [Q-53](#q-53) - **Signal:** COMBAT-20 / LOOP-10: a line about round 21 over a tally that reads "Rounds 6"

Q12b: the comedy line is authored encounter content (the UI must not rewrite it — option (c) refused) and hiding it on early wipes hides the writing where it is needed most (option (a) refused); labelled as the notice's it is the mission-brief-versus-outcome gag — the board said what was supposed to happen, the report says what did, and the distance is the joke. `Results.gd`'s builder adds one `LabelMuted` "The notice said:" above the existing `LabelQuote`, on the clear page too; `test_results_screen.gd` asserts the eyebrow. Q12c: the record exists before the first line plays (Q-53), so a lock on the exits protects nothing; the first-clear gate keeps governing Instant and "Skip to the end", which shape the default path rather than bar the door; the skip lock's decorative reading (LOOP-10) is accepted in writing and LOOP-10's routing change is not taken — the attempt is in Records and `active_run` replays it on Continue — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-140"></a>
### BL-140 - The Options screen's controls are the kit's lit cycle chips, the audio ladders as pips; no toggle, segmented control or slider ships *(DECIDED - as built; the Forgiving Guild row is an Off / On cycle on the same chip)*

**Owner:** [13 §7, §15.1](./13-ui-ux.md) / [art/ref/specs/06 §7](../art/ref/specs/06-settings.md) - **Signal:** KIT-20 / Q14

The reference carries no slider and no switch, and the kit has one control for the job; a settings page in a paper-and-brass world that grows a modern slider would be the one screen that looks like a different game. `Settings._cycle_button()` and the `ROWS` table stay; W8-KEYS's `forgiving_guild` row uses `_cycle_button(key, false, ["Off", "On"])` with BL-113's sentence as its note; `test_options_layout.gd:370`'s count moves once per wave with the rows that wave adds (Forgiving, the scribe — one commit). Volume at six presses is accepted for 1.0 — the pips make the ladder legible; a slider is a 1.1 kit unit if players ask — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-141"></a>
### BL-141 - The two tutorials say their lesson where it happens: one band on RaidView, one line on the Tutorial Raid's wipe page *(DECIDED - `RaidView.TUTORIAL_BAND = true`, W7-REPORT; the words are data)*

**Owner:** [01 §8.1](./01-core-loop.md) / [10 §9](./10-content-and-encounters.md) / [BL-92](#bl-92) - **Signal:** Q15 / LOOP-30 / UI-55

Tutorials only: `RaidView._build()` adds one static `Widgets.callout` band above the log when `Reputation.is_tutorial_slot(encounter.slot)` and the record's `lesson` is non-empty (no round timing, nothing persisted); `Results` prints `lesson_report` above the tally on the Tutorial Raid's WIPE branch only (over a clear it would be false). The words, on `data/encounters_tutorial_t1.json`, never a literal in RaidView or Results: A0 `lesson` "Round three: somebody does something stupid. Watch for the stamp — the log says who, and why." (true by construction — BL-92's scripted round 3; if the scripted round ever moves, the word moves with it); TR `lesson` "One trick, one timer, one tank between six of them. When it goes wrong, the report says who."; TR `lesson_report` "This is the Wipe Report. Who, what, and which round — it is all under 'By raider'." — its last sentence dropped because TR's notice (Q-100) already ends "Read the Wipe Report; you will be seeing a lot of it." and the notice prints on the same page as the epigraph (BL-139): one punchline, once. `test_tutorials.gd` asserts the band's `Label.text` equals `lesson` on A0/TR and is absent on A1, and the Results line is absent on a clear — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-142"></a>
### BL-142 - Town focus entry is rail-first; the rail is the building ring *(DECIDED - as built; docs/13 §13.2 amended; RULES-06 closes)*

**Owner:** [13 §13, §13.2](./13-ui-ux.md) / [02 §10.2](./02-town-and-buildings.md) - **Signal:** Q10

Focus enters every screen on the rail's first item (`Frame.focus_entry` walks `FOCUS_REGIONS` rail-first; `a11y_smoke.gd` pins `rail[0]` on every route); the rail is the only element on all thirteen screens, so one habit serves the whole game, and it cycles the buildings docs/02 §10.2 asks the D-pad to cycle. The illustrated hotspots stay the mouse's door and are reachable by Tab into the scene region; they are not a second focus model; "last building visited" is not restored. docs/13 §13.2's hotspot-ring paragraph is rewritten in three sentences to say so — ruled by the loop under the designer's 2026-09-15 delegation.

<a id="bl-143"></a>
### BL-143 - Disband is recoverable, and an insolvent guild always finds a walk-in: one Common at 0 G per board refresh; no loan *(DECIDED - W8-CRISIS; `GameState.is_insolvent()` is the one predicate)*

**Owner:** [05 §6.3, §12 Q5](./05-morale.md) / [03 §6.5, §8.1 M1](./03-reputation-and-town-progression.md) / [00 A6](./00-vision-and-pillars.md) / [Q-10](#q-10) - **Signal:** SHIP-13 / LOOP-25: "recoverable" with New Guild as the only door is a run reset by another name

Disband as built: the roster is wiped; gold, buildings, unlocks and rank are kept; RP loses 10 % of what was earned inside the rank (`Reputation.rp_after_disband`); the Town says "The guild disbanded on day N. The tent is still yours, and so is the purse. The Tavern is up the road." with the Tavern as the one action; docs/05 §6.3's five guarantees land beside it. `GameState.is_insolvent()` = roster.size() < `RaidPlan.party_size(next_open_mission)` AND gold < the cheapest seat on the Tavern board (`Recruitment.cost_of` under `PRICE_SCALE` — 15 G for a Common at doc 11's; at Respected+ the cheapest seat is an Uncommon/Rare, which is exactly where the lock bites) AND `Economy.total_sell_price(pending_loot + worn gear, rank)` < that seat; `tools/playtest.gd:_can_still_make_progress` calls it (one owner). While it holds, `GameState.refresh_board()` appends one candidate beyond `board_slots()` itself — `Recruitment.generate(rng, Enums.Rank.UNKNOWN, tier)` (at Unknown the weights roll only Commons — canon's own rule, no forced-rarity parameter needed) — and records its id in `flags.walk_in_id` (the `flags` Dictionary W7-SAVE left open; no top-level save key, no field on `Raider`; `FROZEN_SHAPE` holds), so neither `sim/core/Recruitment.gd` (W8-ITEMS's file this wave) nor `sim/model/Raider.gd` (unowned) is edited; `GameState.hire()` skips the charge when the candidate's id is `flags.walk_in_id` and clears the flag; the Tavern card and the Board read the same flag; the card reads price "Free", quote "A walk-in. Will raid for a bed."; the Board prints "You cannot field a party and cannot afford a recruit. Someone at the Tavern will raid for a bed." Canon's "@Respected you no longer find common" describes who the guild FINDS; the walk-in finds the guild, and the card says so. A loan is refused — no debt ledger, no repayment mechanic, no field in a frozen save, and a guild in hock is not funny the way a walk-in is. A full roster with an empty purse never sees it (the roster clause), so it cannot become the on-ramp's crutch; the walk-in's morale is a rolled Common's, so a guild rebuilt from walk-ins is the slow, miserable, funny recovery the disband earned. Pinned by `test_game_state.gd` (roster 0 / gold 5 / empty inventory → one 0 G Common; hiring it costs nothing; a solvent board carries none) and `test_full_loop.gd` after a disband — ruled by the loop under the designer's 2026-09-15 delegation.

### 5.2 Existing rows amended, confirmed or closed

Each entry: the row · its new status marker (replacing the one in its heading or status cell) · the paragraph appended to it. Every paragraph ends with the delegation sentence so a reader can tell a ruling from a finding.

- **Q-13** (the Blacksmith) — status cell → **RULED (2026-09-15): out of 1.0.** No building, no upgrades, no crafting, no salvage (a drop's destinations are equip, keep, sell — docs/02 M4's own verdict); the facade stays on the town plate with the in-world line "Closed. The smith took a better offer." (`Town.gd:119`, final); the `blacksmith` flag stays declared off; `Buildings.gd`'s ladder and `reputation.json`'s two flagged unlock rows stay as post-1.0 data the Town never prints; the record wall's "Sharpened, Finally" (`econ_upgrade_one`, unreachable with the flag off) is replaced by "Pocket Change" (`econ_first_ten`, economy, `{"kind": "items_sold", "count": 10}`, the same five Minor Healing Potions; `achievements.json`'s `_notes` sentence about the eleven worked examples is reworded — ten ship verbatim and one is replaced by this row) so no achievement names a feature the executable lacks; docs/02 §7-8 and docs/11 §9-10 are the 1.1 spec and say so. §9's "next three" line ("Blacksmith yes at upgrades-only") is NOT taken: canon's own line is "Blacksmith (Maybe)" three times and its one hard sentence — "You spend money at the blacksmith/Merchant" — is kept true by the Merchant; a designer shipping would say "Maybe" a fourth time — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-14** (levels / Drilling) — → **RULED (2026-09-15): no level-ups, no Drilling in 1.0, the "Lv." label retired.** Canon made training conditional on level-ups ("Train raiders < Maybe if we have level ups") and the condition is false, so docs/02 §8.1 is post-1.0 and its Guildhall L3 note is struck; `Raider.level`/`xp` stay serialised and unread so a later yes is not a migration; `FLAG_DEFAULTS.level_ups` stays false; the two dormant "Lv. N" branches (`Cards.gd:150-153`, `RaidView.gd:1023-1024`) are deleted by W10-DELETE — a card that can print a stat the game never sets is a second truth, the reference's level is the concept's, and the design wins over the reference's UI; `LabelLevel` stays as a tabular style; the fixture keeps its levels as data (BL-135). §9's "ship Drilling" line is NOT taken, because canon's own line is conditional — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-21** (provenance) — → **RULED (2026-09-15).** The nine `ideaboard/` screenshots are captures of the lead designer's own drafting tables — this game's nine classes, slot matrix and item names in a chat renderer, dated 2026-08-27, in a folder the designer named `screenshots from malkail the lead game designer` — not captures of any other game; the six bare plates are the designer's own supplied plates (spec 09 §3). `PROVENANCE.md`'s eight rows carry an `Answer:` line each (row 1 the designer's plates, unedited; row 2 image-model references the designer supplied, two filenames naming the generator, nothing from another game, disclosed in row 8; row 3 the same material re-drawn by script; row 4 procedural, byte-for-byte by `build_art.sh`; row 5 both OFL texts in the zip; row 6 generated in-tree, `gen_sfx.py`/`gen_amb.py`/`gen_music.py`, nothing sampled; row 7 the designer's own drafting tables; row 8 read under the copy lint, nothing named after the premise's game) and every `Signed:` line reads `Signed: the build loop for the lead designer (Malkail), under the 2026-09-15 delegation — <wave-10 date>` — the words are kept whole; the designer overrules a row by rewriting its line. `test_export.gd:403-416` ("the manifest is unsigned in the tree") is deleted in the signing commit — its own comment names that day — and replaced by "every row signed AND answered"; the gate is green; README and README-player read "Provenance: every shipped asset family's origin is recorded and signed in PROVENANCE.md"; C-32 closes — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-22** (Established) — → **RULED (2026-09-15): (a)+(b).** At the Tavern, Rare becomes modal (Uncommon 350 / Rare 650, docs/03 §5.4's gap-fill, unchanged); in town, the Market's fourth level and the Guildhall's third open for purchase (docs/02 §11, `Buildings.LADDERS` — already gated at rank 3), and Blacksmith tier 2 with them only if Q-13 ever ships the building. `data/reputation.json`'s Established `town_unlock` becomes `[{guildhall, "Guildhall facility upgrade II"}, {market, "Market expansion"}, {blacksmith, "Blacksmith tier 2"}]` so the rank-up callout prints the Market line; the Legendary row's phantom "Guildhall facility upgrade IV" (no such rung — the ladder ends at L4 = Renowned's III) becomes `[{market, "Perfect potions"}, {tavern, "Legendary raiders, one in twenty"}]` — what that rank actually changes (`stock_tier 6`, `find_weights … 50`); docs/03 §5.4 is signed, its §7 Established and Legendary cells follow, the `_doc` string loses "THE LARGEST HOLE"; C-05 and M3-LOOP-06 step 1 close — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-28 / Q-35** (starters, off-hands, armed Commons) — → **RULED (2026-09-15): both signed.** Three Adventure off-hands per rung at docs/09 §10.2's stats (Iron Adventurer's Shield 4 AC/+5 HP; Adventurer's Lute +12 Mana; Blessed Adventurer's Tome 1 AC/+3 Mana), generated for tiers 2-5 — the Shield on `material`, the Tome on `healer`, the Lute on the `leather` craft-quality column ("Studded Adventurer's Lute"); the four Market starters on the tier-1 shelf at 5 / 10 / 10 / 5 G — Chipped Sword **+3** (raised from §10.2's +2, which BL-27's unarmed floor of 2 had made a null purchase), Cracked Staff +4, Splintered Wand +4, Bent Censer +4 Mana / heal_base 8; 80 G arms the opening twelve against 60 G in hand, so the player chooses whom to arm (Q-28's "Commons are a purchase decision"). Commons arrive ARMED with a guild loaner whose numbers are the floors themselves — Borrowed Sword / Borrowed Staff / Borrowed Wand / Borrowed Censer, `damage 2` (= `UNARMED_DAMAGE`), the censer `mana 0, heal_base 6` (= `HEAL_FLOOR`), `source: "start"`, sell 0 — so the card reads "Borrowed Sword · Damage 2" instead of "no weapon · Damage 0" and no sim number moves (asserted); the Rogue's loaner is main-hand only (the off-hand is never floored) and the second Chipped Sword is his first purchase. `StartingRoster.ARMED = true`; docs/09 §10.2, §13.1 (27 → 31 per rung), §5 amended. The SHELF is not neutral (+50 % on a melee Common, +200 % on a caster at A0/A1): W8-SIM-BALANCE sweeps with the shelf ON and the harness buying the cheapest starters first, and states which roster the curve assumes — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-29** (the gear surcharge) — → **default taken (2026-09-15).** `Recruitment.GEAR_SURCHARGE_BP = 1500`: `cost_of(rarity, ct, raid_pieces := 0)` gains `× (1 + 0.15 × max(0, raid_pieces − 1))`, rounded to 10 G (Epic with 2 raid pieces 420 → 480; Legendary with 3 / 4 → 1,300 / 1,450); the card says "well-equipped" whenever the surcharge is non-zero; Adventure pieces never price a recruit (canon calls them "basic adventure gear"), so Commons through Rares and the Tier 1 gold curve are unchanged; docs/11 §12.1 R3 only tightens. The brake it buys is against rerolling the board for the two-piece Epic — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-31 / BL-59 row 5** (upkeep) — → **not in 1.0; the fork ruled (2026-09-15).** No upkeep ships; condition 5 stays `live: false`; no key in the v17 save. When upkeep lands (post-1.0, one L unit, a v18 bump) it is a payday every 7 Day Ticks (docs/05 §7.2's own week), Tier 1 wages per raider per payday Common 1 · Uncommon 1 · Rare 2 · Epic 3 · Legendary 4 G, scaled × 2.4^(tier − 1) (docs/11 §4.3's one knob), the bench pays; an unpayable payday is paid down to 0 G and counts as a miss; two consecutive misses is BIG-dumb condition 5. "Small": an all-Common fifteen pays ~15 G a payday ≈ 60 G a tier ≈ 11 % of docs/11 §4.3's 520 G gross; a Renowned mix at Tier 4 ≈ 400 G a payday ≈ 22 % — rising with the roster's quality, which is what makes the cap and the bench bite. Out of 1.0 because the save freezes at v17 in wave 7 and a sink is measured on the opened on-ramp, not guessed on the closed one; the duplicate `#q-31` anchor is repaired by W7-DOCS — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-33** (Worn Leggings) — → **RULED (2026-09-15): nothing renamed.** Every canon display name stays byte-identical, including the healer's 1-AC "Worn Leggings"; identity is the ID; wherever two live items share a display name (Worn Leggings ×2, Worn Trousers ×2, Old Sandals ×2, Raider's Boots ×2, Raider's Leggings ×3, Basic/Strong Raid Staff ×3) the UI prints the family beside it through the existing "who can wear this" line — "Worn Leggings · Healer"; `test_canon_guard.gd` stays closed — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-36** (the Rogue's daggers) — → **DECIDED (2026-09-15): the daggers rise one point.** Basic Raid Dagger +4 → +5 and Strong Raid Dagger +6 → +7 (ideaboard §3.4's numbers, changed on the record — §4 of RULINGS.md; docs/_source untouched); `TierScaling.DAGGER_OFFSET` −2 → −1 so the dagger sits one under the sword at every tier and the Boss 1 dip never recurs; `MELEE_SWINGS` stays 2 for all melee and no per-class swing count is spent. docs/08 §9.1's Rogue column becomes 24.2 / 24.2 / 28.0 / 35.6 / 49.9 — monotone, the Wizard (36.0 / 38.2 / 40.5 / 50.2) the single-target ceiling at every rung as canon's "Very high single-target DPS" requires, by 0.3 at Boss 5, which is the margin that forbids any Behind bonus. The swing alternatives were costed against that table and every one either doubled the Rogue or dethroned the Wizard. After the fix the dagger is a sidegrade, not an upgrade — the Rogue's real Boss 1 upgrade is the shared Basic Raid Sword in the main hand — and the two item notes (W8-ITEMS) say so in the register ("Lighter than the sword. The Rogue will tell you that is the point."), so BL-32's "Suggested" never equipping the dagger is correct behaviour. Pinned by `test_items.gd` and `test_tier_scaling.gd`; docs/09 OQ-15, docs/08 Q10 and docs/11 Q6 close — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-39 / Q-61 / Q-68** (Power on Adventure armour; the currency; the string keys) — → **RULED (2026-09-15).** The currency is gold, written "G" on chips and prices and "gold" in prose, final (docs/11 §3's "Guild Coin (G)" → "gold (G)"; the copy lint may carry "no coin / Guild Coin / GC in player-facing strings"); the building is "Market", the vendor "the Merchant", the board "Adventure's Board" (canon's spelling, painted on the sign), one string-table key each; Power on zero Tier 1 Adventure armour, the Monk headband's none and the Rogue eyepatch's +2 are deliberate and reproduced exactly (ideaboard §5); Q-61's "do not localise" clause is moot under BL-133 — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-41 / BL-69** (the tier words) — → **RULED (2026-09-15).** The twenty words are: T2 Steel · Runeweave · Hallowed · Vanquisher · Vanquisher; T3 Silvered · Starweave · Sanctified · Conqueror · Conqueror; T4 Adamant · Stormweave · Anointed · Ascendant · Ascendant; T5 Runegold · Voidweave · Exalted · Immortal · Immortal (material · cloth · healer · raid_title · raid_adj, with `raid_adj` = `raid_title` per docs/09 §11.4's sanctioned collapse). The leather line keeps its own column — Reinforced (T1, canon) · Studded · Hardened · Masterwork · Flawless — so a Monk/Rogue Adventure piece never shares a display name with a Warrior/Bard one (`gen_items.gd` `WORD_COLUMN.monk`/`.rogue` → `"leather"`; docs/09 §11.4 widens to six columns). Tier 1's five words are canon's and untouched. The words stay STRAIGHT MMO words (the designer's own Tier 1 is "Basic Raid Sword", "Final Headband"): the joke is Bob and Steve wearing them, and the pompous title line — "Steve — 14 😡 — Immortal's Slippers" — is the roster-row joke played across five tiers. The register's own candidates are kept where good (Steel, Adamant, Runegold; the four titles) and Mithril was dropped for Silvered on docs/00 §4.4's originality gate. Grepped: no display-name collision (Flawless only as the `flawless_clear` condition id; Steel only as a palette name). `data/tier_words.json` is the one source; the regeneration clears `name_pending` on 304 rows and the export gate's eight item-file holds; BL-69's mount rule now mounts all five tiers — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-53** (attempts; Try again) — → **RULED (2026-09-15).** Attempts are unlimited and the attempt is committed at Depart: the sim resolves and `record_attempt()` autosaves before RaidView plays a line, so speed, pause, skip, Esc, quitting and reloading are presentation and cannot discard or reroll anything. "Try again" is the wipe page's default-focused button (`Results.TRY_AGAIN = true`; the Board→Prep route with the plan still pinned; "Costs a day and the provisions you chalk."), Esc mid-replay is the post-mortem (`handles_cancel()`), and Continue after a mid-replay quit replays the stored seed (`active_run` = {encounter_id, master_seed, party_ids, resolved, difficulty_mult, ninja_pulled} — save v17, no later key) to Results. docs/01 §6.1's 25 G retry fee is not built; the day, the chalked provisions and the morale ledger are the per-attempt cost; docs/01 OQ-6 and docs/07 OQ-5/6 close — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-60 / BL-94** (the recruit price) — → **confirmed (2026-09-15).** Doc 11 §4.2's table is the shipped recruit price (Common 15 · Uncommon 60 · Rare 160 · Epic 420 · Legendary 1,000 G); `PRICE_SCALE = "doc11"`; doc 04 §3.3's column is a pointer and the "doc04" row exists only so both tables stay under test; `STARTING_GOLD` 60 stays. A 60 G purse that buys one Common and nothing else is a Tavern the player cannot use on day one — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-69** (the board's reputation half) — → **RULED (2026-09-15): the record wall pays reputation.** Records of kind `reputation` (two ship: One of Each, Comfortable) pay 15 RP each — docs/03 §6.1's smallest award, the two tutorials' worth — claimed once, and the board's lifetime RP is capped live at 15 % of RP earned exactly as its coin is (`Achievements.rp_cap`; a claim past the share is blocked with "The town has heard its share for now — %d of the %d reputation it may pay against %d earned." rather than paid short). `FLAG_DEFAULTS.achievement_rp = true`; `GameState.gd:2920` reads the flag; `claim_grant()` gains the reputation branch; `describe_reward()`'s "(reputation is not signed off — …)" clause is deleted; docs/03 §6.1 gains the row "Record wall, reputation-kind records | — | 15 | 0". The ladder's proof is unmoved: +30 RP lifetime, never before Known (the cap at Known is ⌊0.15 × 120⌋ = 18 ≥ 15), and Legendary still lands on Raid 5's full-clear bonus (2815 + 30 + 325 = 3170 < 3200). "One of Each" is earned on day one (the starting twelve cover all nine classes) — that is the record's condition, accepted. LOOP-13's feed line reads "The town heard: +15 reputation" on a claim through `_award_reputation`'s signal; the rank-up callout listens to the same path (W8-CRISIS). All in W7-SAVE (owns `GameState.gd`, `test_achievements.gd`; `data/achievements.json` and `sim/core/Achievements.gd` added to it); M5-QAB-4 closes; the time-of-day half is unchanged — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-84 / C-19** (encounter vocabulary; boss names) — → closed by **BL-119** — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-96** (the arena) — → **RESOLVED (2026-09-15): the arena belongs to the RAID.** `SceneStage.arena_for(encounter)` is the one rule: the tier row's `scene` (per kind, `{"adventure": …, "raid": …}`) if `data/tier_words.json` names it, else raid encounters (E1-E5) in `stage_arena_dungeon` and adventures and tutorials (A0, TR, A1-A3) in `stage_arena_cave`; the three `DEFAULT_ARENA` sites become handoff lines; no `backdrop` key on encounter records (Q-96's own proposal is superseded — a per-encounter key is a second truth for a fact the kind carries); the bed follows the same function. Fighting TR in the cave keeps the dungeon as the thing Raid 1 earns. Tiers 2-5 inherit the kind rule until a tier row names a plate; M4B-CONV-04 closes — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-98** (the soundscape) — → **AMENDED (2026-09-15).** (i) MUSIC in 1.0 is the generated sparse lute docs/02 §9.1 asked for at Unknown and Known: `tools/audio/gen_music.py` in `gen_sfx.py`'s shape (numpy + `wave`, seeded per `sha256("music:<rank_bed>")`, `--check`/`--list`/`--out`) — a Karplus-Strong string (delay `fs/f0`, averaging loop filter, decay 0.996, pluck-position comb at 0.13, two strings ±3 cents, a body band-pass at 210 Hz Q 4 at −12 dB), A minor pentatonic A2-A4, a phrase walker (gaps mean 2.4 s clamped 0.6-6 s; step ±1 55 % / ±2 25 % / repeat 10 % / tonic 10 %; 20 % dyads on the nearest fifth; velocity 0.55-0.9; an 8 s rest after every 6-10 notes 15 % of the time), Unknown rubato, Known adds a frame drum (200 Hz low-passed noise thump, 90 ms, beats 1 and 3 of 4/4 at 66 BPM, beat 3 −6 dB) and quantises onsets to the eighth grid; `music_lute_unknown.wav` 90 s and `music_lute_known.wav` 87.27 s (24 bars at 66 BPM), 44.1 kHz mono 16-bit, tail folded over 600 ms, peak −24 / RMS ≈ −34 dBFS; `Audio.BEDS_MUSIC` (rank 0 Unknown, ranks 1-5 Known), `MUSIC_BY_SCENE = {"stage_camp", "stage_town"}` (the camp family and the main menu only), a second player pair on the Music bus with the beds' crossfade, behind `Audio.MUSIC_BED = true`; `test_audio_music.gd` replaces the `play_bed`-is-a-no-op tripwire. The ensemble, the bell toll, the cheer stinger and the leitmotif are post-1.0. It lands as **W10-BUFFER's first item** and is cut for 1.0 in writing if the buffer is consumed (the credits line follows — BL-132). (ii) Ambience rides the Music bus ("Audio — music and ambience") through five generated beds and the one door (BL-138); the arena bed follows `arena_for()`. (iii) The Voice bus is "the scribe": `ui.quill` — `stick_slip`, 85 ms, 1.8-6 kHz, grain 90 Hz, three round-robin variants, peak −27 dBFS, jitter 0 — under every log line at live speed (none at Instant or during a skip), the twelfth docs/13 §12.4 hook, bound beside the stamp's in `RaidView._append_line`; the Settings row returns as `{"key": "audio_voice", "label": "Audio — the scribe", "note": "The quill under each line of the account."}`; W8-AUD-OPT (S), the two lines by handoff to W8-KEYS; W10-DELETE does not delete the Voice row. (iv) The world layer is silent — failure is the content and hits and heals would bury the mistakes under the noise of competence. (v) The WIPE stamp is `ui.stamp` unjittered. The three interplay defaults and the coin as the clear's sound stand; the owner is the loop; nothing is downloaded (docs/00 §4.4 (5)); docs/02 §9.1's Audio column is amended to what ships — ruled by the loop under the designer's 2026-09-15 delegation.
- **Q-99** (the 110 ms dissolve) — → **RULED (2026-09-15): a page fades in.** `ScreenRouter.TRANSITION_MS = 110` — `_load_into_host` adds the new screen at t=0 (every `Label.text` read holds), sets `modulate.a = 0` and tweens to 1 over 110 ms `EASE_OUT`; the outgoing screen is freed at once (a fade-in, not a cross-fade — one screen in the tree); `TRANSITION_MS` reads 0 under `GameSettings.reduced_motion` and when `shot.gd` is driving (the sheets stay byte-stable); `ui.tab` fires on the fade's first frame. A dissolve is a page changing IN PLACE, which is docs/13 M5's own sentence; the 6 px tab shift is a slide and is struck; §11.4's t=1,800 post-mortem slide is struck — the report appears in place under the stamp. 110 < §12.1's 140 ms settle. Lands in W8-KEYS (owns `ScreenRouter.gd` and `test_a11y.gd` in wave 8; the pins go in `test_a11y.gd`); the docstring's "never will" becomes "110 ms, opacity only" there, and W10-DELETE's line is struck; docs/13 §12.2 row 1 → "Fade-in, opacity only | 110 ms | ease-out", §11.4 amended — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-22** (rarity vs morale) — → **DECIDED — accept.** Morale is the short-term lever that decides this raid; rarity is the long-term axis the reputation ladder controls; the E2/Adventure re-measure shows canon's intended order and no coefficient moves; W9-TIERS asserts at the first unsaturated Tier 2 cell that morale's span ≥ rarity's as a WARN with the two numbers printed, and only a reversal there reopens the row — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-40** ("Buy a round") — → **CLOSED — cut for 1.0.** docs/02's proposal priced by docs/11 (8 G × roster) and never given a morale number; at 96 G for a guild of twelve it out-prices a Raid 1 clear (70 G) for a spike drift erases in two ticks — a trap purchase in the first hour; canon puts morale management in the Guildhall and people at the Tavern; the Hot Bath Token is the Indulgence line. docs/11 §8.3's row and §4.2's S3 are struck; `Comfort.gd:258`'s comment goes — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-42** (the roster cap) — → **DECIDED — 04 wins.** One driver, reputation rank: 15/16/17/18/19/20 (`GameState.ROSTER_CAP_BY_RANK`, docs/04 §12.1, Q-12's default); docs/02 §4.3's 14/18/22/26 column is deleted and its Q8 cites docs/04 §12.1; docs/13 §9.1/§9.4 read "N of N" from the rank table; the Guildhall track keeps comfort floor and comfort slots; "min of both" is rejected as a second truth for one number — the bench must be small enough that "maybe I shouldn't bring Steve" hurts — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-53** (the name pool's signature) — → **RESOLVED** by BL-118 — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-58** (the Legendary quirks) — → **DECIDED — specced, in `Quirks.SPECS`, in the four-hook shape the seam documents; `legendary_quirks` ships on (W9-QUIRKS, M).** quirk_warrior "Holds the Line" `{"tank_priority": 1, "immune": ["MIS_TAUNT_LAPSE"]}` — "Never yields the main-tank slot, and never forgets to taunt, however badly the night is going."; quirk_cleric "One More Cast" `{"immune": ["MIS_HEAL_WRONG", "MIS_HEAL_CORPSE"]}` — "Every cast lands where it was meant to. Nothing she casts is wasted."; quirk_shaman "The Totem Holds" `{"immune": ["MIS_CHAIN_FIZZLE"]}` — "Her chain heal always finds its third target." (docs/04's own Natsuna example); quirk_druid "Grows Into the Gap" `{"threat_multiplier": 0.50}` — "Heals the whole room, and the boss never notices her doing it."; quirk_mage renamed **"Lets Sleeping Adds Lie"** `{"immune": ["MIS_BROKE_CC"]}` — "Has never once woken the wrong thing."; quirk_wizard "Reads the Whole Fight" `{"immune": ["MIS_WRONG_TARGET"]}` — "Never hits the wrong target. He read the fight before it started."; quirk_rogue "Never Where the Boss Looks" `{"threat_multiplier": 0.80}` — "Draws less attention than the numbers say he should."; quirk_monk "Reads the Room" `{"relief_bp": 300.0}` (the Potion of Steady Hands' own magnitude) — "Notices a mechanic one beat before anyone else does."; quirk_bard "Carries the Beat" `{"immune": ["WRONG_SONG"]}` (a pseudo-type the song site checks — W9-KITS threads `Quirks.immune_to(qid, "WRONG_SONG", enabled)`; the mistake still logs and her d6 song plays anyway) — "A Bard mistake is still a song. Hers just never becomes the wrong one." No quirk adds damage or healing — each removes one of its class's own mistakes, shaves its threat, or seats it first: canon's "basically perfect, near 1% chance of mistake", the one person on the roster you never have to watch; every "reads as" line says what the sim does. Budget (Q58-1): the benchmark twelve's Legendary clear rate moves ≤ 2 pp; the Tier 1 sweep is unmoved. `test_quirks.gd` one synthetic test per row; docs/07 §5.6 carries the table (W9-REVIEW's docs handoff) so `LegendaryPool._validate()` has its section; the Mage's new quirk name survives W8-ITEMS's `display_name` edit; Q58-1/2/3/4 close — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-85** (M01 on one tank) — → **closes** on Q-100 — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-87** (Focus / M10) — → **amended: Focus stays post-1.0 and its numbers are decided.** `FOCUS_MAX` 100 for Cleric, Druid, Shaman, Mage and Wizard and 60 for the Bard; `FOCUS_REGEN` 7 / 7 / 7 / 8 / 8 / 5 per round; primary cast costs 9 / 14 / 12 / 11 / 10 and the song's; class-fixed, never on gear (Q-02). An empty pool heals at `HEAL_FLOOR` or hits for the staff alone with Mana counted as 0; a wasted heal spends its full cast and the Focus token (docs/07 §6's Mana token, renamed) doubles the next heal's cost; M10's drain is `drain` Focus per round on the record, default 10, while the silence half ships now. The Bard's +20 Mana Instrument feeds song magnitude (Q-46), not a pool. docs/08 §5.3's table goes 🔷 → DECIDED-for-1.1 with its three riders answered; docs/10 §10's M10 row reads "Silence (`N` rounds); drain `X` Focus per round from 1.1"; DW-C1 closes with the numbers, DW-C2's edits land. At those numbers over E5's 22 rounds the Cleric never runs dry (100 + 7 × 22 = 254 ≥ 198), the Druid rations from round 15, the Shaman from 21 — the "dry at 20 %" beat lands only on the tier's last boss. `MAGNITUDE_ONLY` must reproduce the 1.0 goldens byte-for-byte when the 1.1 unit lands — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-90** (the tutorial rate) — → **amended: a two-entry table.** A0 rolls no organic mistakes and fires only its scripted round-3 one; the Tutorial Raid rolls at half rate — `Mistakes.TUTORIAL_MISTAKE_MULT = {"A0": 0.0, "TR": 0.5}` read by `Context.tutorial_slot`; the two pull types stay disabled on both. Q-51's "reduced" is read per tutorial: Adventure 0 teaches the player to read a mistake and shows exactly one, as docs/10 §9.1 and its own comedy line ("On the third round somebody will do something stupid, and that is the lesson.") promise — at 0.5 somebody does something stupid on round 2 and the line lies; the Tutorial Raid is the fight designed to be lost and keeps half rate so its Wipe Report has organic causes. `test_mistakes.gd`'s 60-cell check runs per slot; A0's pin stays `>= 18/20` (expected 20/20); the `raid-clear` sheet's A0 tile reads "Mistakes 1" — ruled by the loop under the designer's 2026-09-15 delegation. **BL-91** closes with it: TR's sizing (BL-110) was done at 0.5, so the coupling is answered in the same commit and the pin becomes `>= 8/20`.
- **BL-95** (Retreat) — → **CONFIRMED.** Retreat stays struck: the attempt is committed at Depart (Q-53), so there is no phase boundary at which to abandon it and no mid-fight verb (Q-09); leaving the account early is Skip or an exit; the whole-attempt "don't go" is the prep board's Back. W7-DOCS strikes docs/07 §3 :106's sentence ("There is no retreat: the attempt is committed at Depart; the prep board's Back is the only 'don't go'"), the §7.3 outcome row "Player Retreat → Abandoned attempt", docs/13 §5 S11's "retreat", and Q-09's "sole exception" gains "(historical: struck by BL-95)" — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-96** (traits) — → **confirmed.** The designer's texture axis for a raider is the backstory bullet (Pillar 3); the fight's inputs are rarity and morale; four of the six traits are bullets wearing a mechanic and the two that touch the fight are a sixth axis on a card already reading five things; `Raider.traits` stays serialised and empty; docs/04 §10 and docs/14 §5's row are marked post-1.0; no code behind a flag — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-97** (S13 / S16 / the keys) — → **CONFIRMED.** S13 struck outright (one rung is one encounter — BL-24); S16 out of 1.0 and revisited only if Tiers 2-5 ship item families the Market's compare tooltip and the paper-doll cannot explain; `F1` / `nav_codex` deleted from `project.godot` and `ScreenRouter.codex()`/`CODEX_SCENE` removed in W8-KEYS, not left inert; the `1`-`4` sort row on list screens and the list-screen filter row struck; the map that ships is Space pause and `1`-`4` speeds on RaidView (respecting `_skip_unlocked`), Q/E on RaiderDetail, F on the Records filter, Esc back — every other control is Tab-reachable — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-98** (wishlists) — → **confirmed.** Canon calls them "just concepts"; the 1.0 loot decision is Q-11's Master Looter, whose per-raider stat delta is the game knowing each raider's best-in-slot for the player; the flag stays declared off, `Raider.wishlist` serialised, the four authored morale rows unreachable data, BIG-dumb condition #3 declared and inert while 1, 2 and 4 ship live; docs/09 §14.3 and docs/11 §6.3 tagged post-1.0; Q59-3 closes as cut — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-99** (the four PROPOSED kits) — → **amended: three of doc 06's four kits are DECIDED in the shape canon's own class line requires and no wider (W9-KITS, L−).** Monk Guard (canon "emergency tank"): `Combatant.in_guard`, evaluated at Round Open — on when the Monk holds a tank flag at setup or when no Warrior is Alive and stable (Tank Lead 1.30, W7's `should_retarget`), off when one is; on entry a Taunt (1.10 × current highest); `GUARD_THREAT_COEF 3.0`, `GUARD_AC_BONUS +7` (the canon Warrior Shield's 7, the piece a Monk cannot carry; Monk Adventure 14 + 7 = 21 = docs/10 §5.4's E4 tank AC), `GUARD_DAMAGE_MULT 0.5`, one Story line each way ("{actor} drops into Guard. Somebody had to."); a Guard Monk counts as tanking for M09/M11/M01's holder rule and is never M01's partner (docs/06 §4.6). Rogue Front (canon "position-dependent"): `ROGUE_FRONT_MULT 0.77` in `_outgoing_damage` while the Rogue is the raider the boss targeted this round (organic threat, MIS_AGGRO, M08 Fixate), otherwise 1.0 — docs/08 §8.2's default, so no clean-run number moves; a Behind bonus of even 1.05 would put the Rogue over the Wizard at Boss 5. Mage Raid Spell Buff (canon phrase): `MAGE_RAID_BUFF +2` spell damage per cast to every Mage and Wizard while any Mage `is_alive()`, once regardless of Mage count; the Bard's Hymn of Focus stacks on top (≈ +2-3 % raid DPS). The Wizard Ramp stays post-1.0: canon's "Very high single-target DPS" is the 1.60 coefficient already and a five-stack ramp is a borrowing the notes never asked for. The Bard sings as Q-46 tables it — `BARD_S_DIVISOR = 10`, `data/classes.json` song params, the d6 on seeded channel `song`, the d4 Wrong Song on a Bard action mistake, Drinking Song as `relief_bp 300`, Discord through the retarget path, the Loud Solo through `add_threat` — with the canon Charm of Mana (+10) as its Tier 1 Mana (S = 2; 3 with the Instrument; 4 with both). Panicked Stance, Overpull and Faced-the-Boss are not built. `test_class_kits.gd` one test per rule; the wave's one regeneration; if W9-KITS must trim, the Mage buff moves to W10-BUFFER and Guard and Front do not move; docs/06 §4.5-4.7 amended to the built shapes, §4.8 stays 🔷 post-1.0 — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-100** (per-tier arenas) — → **stands**, now visible for four tiers: tiers 2-5 share the two arenas by kind, the Tier 1 boss set and one icon palette; per-tier plates, recolours and palettes are post-1.0 and land through `tier_words.json`'s `scene` key when painted; a `modulate` re-hue of a boss was tried and rejected (PIPE-16) and a tinted boss is the palette-swap the game parodies — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-101** (placeholder names) — → **amended:** stands for trash rungs, the ladder words and every enemy log name; the boss rungs' plate carries BL-119's role title above the placeholder — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-102** (one plate + dressings) — → **amended: the six dressings are a table.** Every layer gated `rank >= N` in `stage_camp.json`, props cut from the plate's or the sheets' own pixels, never painted: **0 Unknown** 0 walkers, 6 lantern flames, the two shipped banner props hidden · **1 Known** 1 walker, 8 flames, the banners return and one cloth pennant on a pole beside the Board callout (never on the tent — the tent's cloth banner is facility L2's) · **2 Respected** 2 walkers (the shipped scene), 10 flames, a notice post beside the Board callout, the pennant takes the crest colour · **3 Established** 3 walkers, 10, a cobble band on the main path (`patch_plate.py`) and a pennant line of 5 between the two big tents · **4 Renowned** 4 walkers, 10 + 2 brazier flames (`fire_camp` at 1x), a stone statue (one idle warrior frame, desaturated, on a 24×10 plinth) in the square · **5 Legendary** 5 walkers, 10 + 4 braziers, a second guild tent (a patch copy), two `knight_unlabelled` guards flanking it, crest pennants on all four tents. Ranks 0-3 in W8-FACILITY; ranks 4-5 in W9-ART (it owns `stage_camp.json` in wave 9). Every rank adds ≥ 3 deltas (docs/02 §2.1 R2) and a rank is readable from a screenshot (R5); docs/02 §9.1 is rewritten to this table under "one plate, six dressings" with the six painted states kept below as the post-1.0 plate brief; `test_scene_stage.gd` asserts rank 0..5 shows exactly the table — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-103** (the 2x/1x split) — → **amended: 1.0 ships the party AND every enemy at 2x integer scale on both arenas.** `marks.boss.scale = 2` in `stage_arena_cave.json` and `stage_arena_dungeon.json` for every enemy rank (main, mini, elite, trash and the `_2` variants): the Main Boss stands 262 px (155×131 at 2x), the Mini Boss 210, the stone brute 330, the elite 182, trash 164, beside 62-96 px raiders — Octopath's proportion (≈ 3.2× a raider), not the mockup's 6×; one pixel pitch on the floor, which is what closes the seam UI-22 measured ("the party is crunchier than its enemy"); spec 07 A1's "chunky" warning had 1:1 raiders as its premise and the raiders are 2x. The delegation is the "upscale ok" the row was waiting for. `place_boss()` already scales the contact shadow and `boss_feet_y()` the plate clearance; the boss mark's x moves so a 2x footprint (up to 400 px wide) clears the front rank by ≥ 24 px and the lantern entirely; `test_scene_stage.gd:602` reads `Vector2(2, 2)` from the mark; damage numbers and `head_of(boss)` follow the frame rect. `figure_scale` stays 2 on the camp and both arenas and 1 on the tavern and market — the tavern takes no 1.5x exception (a non-integer shimmers under nearest and blurs under linear); the tavern speaker's plate is sized to the 1x figure (UI-07). The 2x-canvas re-author of the four party families and six enemies at painted density is post-1.0 and a person's; spec 00 §2.7's `marks.boss.scale` row: default 2, the other branch 1 — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-104** (two gates stay records) — → **confirmed**, with one sentence: README's budget line reads "mount ≤ 140 ms warm, frame ≤ 16.6 ms, calibration loop ≤ 10 ms, on the reference laptop boosting — measured on the second machine at the native window (W10-WALK)", so WARN is never read as "not measured"; `test_perf_mount.gd`'s cache invariants are the FAIL that exists — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-105** (instrumentation) — → **confirmed**; docs/14 §12 gains the status line "🔷 PROPOSED, post-1.0; nothing under `game/` produces these events; the balance harness (§9.3) is the shipped instrument"; the only file the shipped game writes about itself is Godot's crash log (`debug/file_logging`, five files) — docs/00 §6.1's "no telemetry-driven tuning" — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-106** (the asset-scope bundle) — → **amended: b, c, e, j, k added.** **b** `Icons.WARRIOR_GLYPH = "shield"` — the Warrior's whole identity in canon is the shield (the matrix's only one), the badge exists so the player finds the two tanks at a glance, and a tank badge that says "swords" says DPS; Octopath's job icons name the role; the asset exists beside the swords; `test_icons.gd:122` asserts "shield" (W9-ART). **c** the guild tent is the guildhall with four states (L1 the patched tent · L2 + a cloth banner · L3 + a second tent and a lantern ring · L4 + a painted sign) and the camp dresses per rank as BL-102's table (W8-FACILITY). **e** `FUMBLE_BY_SEVERITY = {MINOR: "trip", MODERATE: "drop", SEVERE: "wrong_target", CRITICAL: "wrong_target"}` on three `fumble_*` frames (W9-ART). **j** the Raid Group tab is retired, not rebuilt as a read-only view or a "Chalked" filter — RaidPrep's strip is the raid group and the only truth about who is going tonight; the escape hatch is closed; W10-DELETE removes the `raid_group` remnants and retargets `test_roster_layout.gd:296,:319`, `test_starting_roster.gd:224`. **k** the party bodies stay at the sliced reference density (the bosses upscale — BL-103). a, d, f, h, i as built; the nine Legendary busts are a named pass through `derive_busts.py`, not a rarity re-hue, and are not barred by d — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-107** (the wipe's culprit) — → **🔷 → DECIDED.** The rule as W6-SIM-CASCADE built it stands: the last Severe-or-worse mistake logged before the first tank or healer is confirmed Dead; else the mistake with the deepest cascade depth (ties to the later one); else nobody — "Nobody in particular. The boss simply won." — the honest line and the DPS-check signal; `WIPE_CULPRIT_DELTA = -4` = `Morale.TRIGGERS["wipe_caused"]` once per attempt session (a test pins them equal), on top of the wipe's −8, so the culprit takes −12; the blame is the comedy, and BL-116's round-1 Critical is its best case — ruled by the loop under the designer's 2026-09-15 delegation.
- **BL-30** (the staged on-ramp swings) — → **superseded** by BL-110; BL-28 stands — ruled by the loop under the designer's 2026-09-15 delegation.

## 6. Plan edits

Handoff-style edits to `build/plan/ship/00-plan.md` §0.5 and §2-§5 (wave 6's §1 is running and is untouched), numbered from 101 so `tools/apply_handoff.py build/plan/ship/RULINGS.md --dry-run` parses only these (the document's own `## N.` section headings carry no `old:`/`new:` blocks). Each `old:` occurs exactly once in the plan at HEAD; the orchestrator applies them between waves 6 and 7. §6 and §7.1 themselves are re-pointed by 102 and 103 (a pointer to §2/§3 of this file) rather than rewritten row by row.

## 101. build/plan/ship/00-plan.md
§0.5 — the switch register as the rulings leave it.
old:
```
`Recruitment.PRICE_SCALE = "doc11"` (Q-60) · `Results.TRY_AGAIN = true` (Q-53) · `RaidView.TUTORIAL_BAND = true` (Q15) · `Results.COMEDY_LINE` / `RaidView.EXITS_GATED` unchanged (Q12b/c) · `Formulas.DIFFICULTY_MULT` 1.0 / 0.75 under `forgiving_guild` (CRITIC-M1) · `Mistakes.NINJAPULL_REACHABLE = false` (CONTENT-12) · `Formulas.FOCUS_ENABLED = false` and `MANA_BURN_DRAIN_ENABLED = false` (SIM-04/CONTENT-27) · `Recruitment.GEAR_SURCHARGE_BP = 1500` (Q-29) · `StartingRoster.ARMED = true` (LOOP-18/Q-35) · `LogPlayer.COLLAPSE = true` (CONTENT-13) · `SceneStage.arena_for()` = tier `scene` else kind rule (Q-96) · `GameSettings.colourblind_safe = false` (Q16) · `Economy.SELL_SLOPE_CORRECTION` (CONTENT-23, only if the tier walk trips it) · `GameState.COMPLETED_AT = "last_named_tier"` (DESIGNER-02's honest ending) · `Formulas.BARD_S_DIVISOR = 10` (Q-46) · `Quirks.SPECS` empty (BL-58) · `Frame.REP_ICON = "gem"` (Q06) · `ScreenRouter.TRANSITION_MS = 0` (Q09).
```
new:
```
Every switch below is RULED (`build/plan/ship/RULINGS.md`, 2026-09-15); the default named is the shipped value and "the other branch" is a recorded alternative, not a pending answer. Unchanged as planned: `Recruitment.PRICE_SCALE = "doc11"` (Q-60) · `Results.TRY_AGAIN = true` (Q-53) · `RaidView.TUTORIAL_BAND = true` (BL-141) · `RaidView.EXITS_GATED = false` (BL-139) · `Formulas.DIFFICULTY_MULT` 1.0 / 0.75 under `forgiving_guild` (BL-113) · `Formulas.FOCUS_ENABLED = false` and `MANA_BURN_DRAIN_ENABLED = false` (BL-87) · `Recruitment.GEAR_SURCHARGE_BP = 1500` (Q-29) · `StartingRoster.ARMED = true` (Q-28/Q-35) · `LogPlayer.COLLAPSE = true` (BL-109) · `SceneStage.arena_for()` = tier `scene` else kind rule (Q-96) · `GameSettings.colourblind_safe = false` (BL-127) · `Economy.SELL_SLOPE_CORRECTION` (CONTENT-23, only if the tier walk trips it) · `GameState.COMPLETED_AT = "last_named_tier"` (now resolves to tier 5 — BL-121) · `Formulas.BARD_S_DIVISOR = 10` (BL-99). Changed default: `Results.COMEDY_LINE = "epigraph"` (BL-139) · `Quirks.SPECS` = nine rows and `FLAG_DEFAULTS.legendary_quirks = true` (BL-58) · `Frame.REP_ICON = "sigil"` (BL-125) · `ScreenRouter.TRANSITION_MS = 110` (Q-99) · `marks.boss.scale = 2` on both arenas (BL-103) · `Icons.WARRIOR_GLYPH = "shield"` (BL-106). Struck: `Formulas.SWING_PRICES_MECHANICS` (BL-110 — no one-tank M01 carrier exists) · `Mistakes.NINJAPULL_REACHABLE` (BL-116 — built, never flagged). New: `Mistakes.TUTORIAL_MISTAKE_MULT = {"A0": 0.0, "TR": 0.5}` (BL-90) · `Loot.ADVENTURE_ROLLS_PER_SLOT = 2` (BL-111) · `RaidSim.ATTRITION_GRACE_ROUNDS = 5` + per-record `attrition_grace` (BL-114) · `TierScaling.DAGGER_OFFSET = -1` (Q-36) · `Audio.MUSIC_BED = true` (Q-98, W10-BUFFER) · `FLAG_DEFAULTS.achievement_rp = true` (Q-69) · `Palette.CAUTION #E8A302` / `POSITIVE #AFEBA2` / `POSITIVE_CVD #C6DDF1` (BL-127) · `GameState.is_insolvent()` + `flags.walk_in_id` (BL-143) · `Encounter.title` (BL-119) · `active_run.difficulty_mult` / `.ninja_pulled` (Q-53).
```

## 102. build/plan/ship/00-plan.md
§6 — the table is answered; point at the rulings.
old:
```
Every question DESIGNER.md carries (its 48 rows; 35 folds into 21 as that report folds it), then the questions the other six reports and CRITIC raised that DESIGNER.md does not carry. Columns: the row, the question in one line, the wave by which an answer is needed (after it the loop takes the default), the shippable default the loop takes at wave 10 if unanswered, and the unit that applies the answer or the default. "As built" is a complete answer. Rows marked ★ have no autonomous fallback that reaches a store — the game ships to the designer's own machine with the README saying so. W6-LEDGER writes this table into `build/plan/ship/designer-page.md` with the answer lines from DESIGNER.md verbatim.
```
new:
```
**Every row below is RULED** — `build/plan/ship/RULINGS.md` §2 reproduces this table with a Ruling and a Register-row column per row, and its "Applied by" supersedes the one here where the critic re-homed the work (A6-A13). Under the designer's 2026-09-15 delegation no row waits for a person, the ★ rows have their answers (provenance signed on the designer's behalf, the credits named, the Legendaries and the tier words ruled), and "taken under the wave-10 ship rule" is never written — a row is "ruled by the loop under the designer's 2026-09-15 delegation". The columns below are kept for the record of what was asked and what the default was. W6-LEDGER's `designer-page.md` stands as the page the rulings answered.
```

## 103. build/plan/ship/00-plan.md
§7.1 — the deferrals are ruled; point at the rulings.
old:
```
Two lists. The first is what is explicitly OUT of 1.0 and why — each gets a docs/15 BL row in W6-LEDGER (or the wave named) so nothing ships half-built (BUILD_STATE invariant 5) and no screen has to hide it.
```
new:
```
Two lists. The first is what is explicitly OUT of 1.0 and why — each gets a docs/15 BL row in W6-LEDGER (or the wave named) so nothing ships half-built (BUILD_STATE invariant 5) and no screen has to hide it. **Every row of 7.1 is ruled in `build/plan/ship/RULINGS.md` §3**: eight come in (three of the four kits → W9-KITS; the quirk specs → W9-QUIRKS; the boss titles → W7-REPORT/W8-SIM-BALANCE/W8-SCALE-1/W9-TIERS; the lute → W10-BUFFER's first item and the quill → W8-AUD-OPT; the dungeon bed → W7-AUD-AMB; the walk-in → W8-CRISIS; tiers 2-5 → W9-TIERS's long branch, the "words never come" row struck as void), sixteen stay out with their row text as §3 amends it. Where a 7.1 row below says "unless the page …", the page has answered.
```

## 104. build/plan/ship/00-plan.md
Wave 7 close — the page is answered.
old:
```
and the designer's page is due back — wave 8 runs on its answers or on §6's defaults.
```
new:
```
and the designer's page is answered by `build/plan/ship/RULINGS.md` — wave 8 runs on those rulings.
```

## 105. build/plan/ship/00-plan.md
Wave 7 ownership — W7-SAVE gains the achievement files (A9); W7-DOCS gains docs/00 VS7 and docs/12 (BL-126).
old:
```
GameState.gd, SaveGame.gd, MainMenu.gd, LoadSave.gd, tests/fixtures/saves/**, docs/14 §7, test_savegame.gd, test_game_state.gd, test_achievements.gd, test_loadsave_screen.gd, test_menu_lockup.gd → W7-SAVE
```
new:
```
GameState.gd, SaveGame.gd, MainMenu.gd, LoadSave.gd, tests/fixtures/saves/**, docs/14 §7, data/achievements.json, sim/core/Achievements.gd, test_savegame.gd, test_game_state.gd, test_achievements.gd, test_loadsave_screen.gd, test_menu_lockup.gd → W7-SAVE
```

## 106. build/plan/ship/00-plan.md
Wave 7 ownership — W7-DOCS's docs list.
old:
```
docs/01, 02, 03, 04, 05, 07, 08, 09 (§13.1 note), 10, 13, 14 (§4, §10.4, §11), docs/15, audit.json, BUILD_STATE.md, BACKLOG.md, test_canon_guard.gd, test_docs_links.gd, test_build_state.gd, test_audit_hygiene.gd → W7-DOCS
```
new:
```
docs/00 (VS7 only), 01, 02, 03, 04, 05, 07, 08, 09 (§13.1 note), 10, 12, 13, 14 (§4, §10.4, §11, §12 status line), docs/15, art/ref/specs/00 (§2.3, §2.5, §2.7 rows), audit.json, BUILD_STATE.md, BACKLOG.md, test_canon_guard.gd, test_docs_links.gd, test_build_state.gd, test_audit_hygiene.gd → W7-DOCS
```

## 107. build/plan/ship/00-plan.md
W7-STAGE — the boss at 2x (BL-103).
old:
```
UI-22's default (the boss mark moved in front of the fence line, the contact shadow from `place_boss`; `marks.boss.scale` stays 1 — Q02)
```
new:
```
UI-22 + BL-103 (the boss mark moved in front of the fence line, the contact shadow from `place_boss`; `marks.boss.scale` = 2 on BOTH arenas for EVERY enemy rank — Q02 ruled "upscale ok": the Main Boss 262 px, the Mini 210, one pixel pitch with the 2x party; the boss mark's x moves so a 2x footprint up to 400 px wide clears the front rank by ≥ 24 px and the lantern sprite entirely; `test_scene_stage.gd:602`'s `anim.scale == Vector2.ONE` becomes `Vector2(2, 2)` read from the mark; the ≤ 25 % overlap assertion covers the boss)
```

## 108. build/plan/ship/00-plan.md
W7-STAGE — the one look at 2x.
old:
```
`RaidView --fixture=raid` shows the boss in front of the fence, twelve visible heads, the plate clear of the header.
```
new:
```
`RaidView --fixture=raid` shows the boss at 2x in front of the fence, filling its floor, twelve visible heads, the plate clear of the header.
```

## 109. build/plan/ship/00-plan.md
W7-REPORT — the lesson strings as ruled (BL-141, A4), the title field (BL-119, A6), the epigraph (BL-139).
old:
```
TR's Results prints a second line above the tally: "This is the Wipe Report. Everything that went wrong is under 'By raider'."; CONTENT-09's five beats become the two `lesson` strings plus the existing prep/loot empty-state copy — no `TutorialHints.gd`, no persisted dismissal)
```
new:
```
the words are data (BL-141): A0 `lesson` "Round three: somebody does something stupid. Watch for the stamp — the log says who, and why."; TR `lesson` "One trick, one timer, one tank between six of them. When it goes wrong, the report says who."; TR `lesson_report`, printed above the tally on TR's WIPE branch only, "This is the Wipe Report. Who, what, and which round — it is all under 'By raider'." (no last sentence — the notice already says "you will be seeing a lot of it"); CONTENT-09's five beats become those strings plus the existing prep/loot empty-state copy — no `TutorialHints.gd`, no persisted dismissal), BL-119's Tier 1 half (A6: `Encounter.title: String = ""` read by the same loader; TR's record gains `"title": "The Doorman"`; RaidView's boss plate prints the title in the title slot with "Raid 1 — Encounter 5 · Main Boss" as the subtitle when a title is present, else as today — enemy `name`s untouched, no golden moves), BL-139's Q12b half (`Results.COMEDY_LINE := "epigraph"`: one `LabelMuted` "The notice said:" above the existing `LabelQuote` at `Results.gd:426-429`, on every outcome; `test_results_screen.gd` asserts the eyebrow)
```

## 110. build/plan/ship/00-plan.md
W7-REPORT — Owns follows.
old:
```
`data/encounters_tutorial_t1.json` (`lesson` on two records), `sim/model/Encounter.gd` (the loader reads `lesson`, SPACES)
```
new:
```
`data/encounters_tutorial_t1.json` (`lesson` on two records, `lesson_report` and `title` on TR), `sim/model/Encounter.gd` (the loader reads `lesson`, `lesson_report`, `title`, SPACES)
```

## 111. build/plan/ship/00-plan.md
W7-REPORT — Build notes: the epigraph is the default.
old:
```
`EXITS_GATED` stays `false` (Q12c); `COMEDY_LINE` stays "as_built" (Q12b).
```
new:
```
`EXITS_GATED` stays `false` (Q12c, BL-139); `Results.COMEDY_LINE := "epigraph"` and `_shows_comedy_line()` keeps returning true (Q12b, BL-139).
```

## 112. build/plan/ship/00-plan.md
W7-REPORT — Size.
old:
```
- Size: M (nine S; if it must shed, UI-39's rally line and UI-24 go to W9-POLISH).
```
new:
```
- Size: M+ (twelve S; if it must shed, UI-39's rally line and UI-24 go to W9-POLISH — the title, the epigraph and the lesson strings do not shed).
```

## 113. build/plan/ship/00-plan.md
W7-SIM-EFFECTS — Goal: NINJAPULL is built (BL-116).
old:
```
NINJAPULL is retired in writing or built by the designer's word;
```
new:
```
NINJAPULL stays a live type — its break roll is wave 8's (BL-116) and nothing here flags it;
```

## 114. build/plan/ship/00-plan.md
W7-SIM-EFFECTS — Findings: the BUILD branch.
old:
```
CONTENT-12's default (`Mistakes.NINJAPULL_REACHABLE := false`: the TYPES row keeps the name flagged `unreachable`, the corpus test skips its budget, the BL row via handoff to W7-DOCS; if the page says "build", W8-CRISIS rolls the break at Depart and W8-SIM-BALANCE honours `ninja_pulled` on `run()` — a dict key)
```
new:
```
CONTENT-12's BUILD branch (BL-116 — no `NINJAPULL_REACHABLE`, the type never flagged unreachable, no corpus skip written; W8-CRISIS rolls the break at Depart and W8-SIM-BALANCE honours `mstate.ninja_pulled` on `run()` — a dict key; nothing lands here)
```

## 115. build/plan/ship/00-plan.md
W7-SIM-EFFECTS — Owns: no corpus skip.
old:
```
`test_sweep_baseline.gd`, `test_mistake_lines.gd` (the `unreachable` skip only).
```
new:
```
`test_sweep_baseline.gd` (no `test_mistake_lines.gd` edit — nothing is skipped, BL-116).
```

## 116. build/plan/ship/00-plan.md
W7-SIM-EFFECTS — Acceptance.
old:
```
`test_mistake_lines.gd` green with NINJAPULL skipped by flag;
```
new:
```
`test_mistake_lines.gd` green with NINJAPULL's budget row intact;
```

## 117. build/plan/ship/00-plan.md
W7-SAVE — `active_run` carries the two replay keys (A10) and the achievement edits (A9).
old:
```
SHIP-03 + M3-SAVE-03 (`active_run = {encounter_id, master_seed, party_ids, resolved}` written by `record_attempt`
```
new:
```
SHIP-03 + M3-SAVE-03 (`active_run = {encounter_id, master_seed, party_ids, resolved, difficulty_mult, ninja_pulled}` — the last two default 1.0 / "" (BL-113, BL-116), written from the run options, carried on the `raid_history` attempt record too, and passed back into `RaidSim.run(..., opts)` by Continue's re-run and Results' stored-seed replay so the replay is the fight that happened — written by `record_attempt`
```

## 118. build/plan/ship/00-plan.md
W7-SAVE — the achievement half (A9: Q-69, Q-13).
old:
```
DESIGNER-06 (Q-53 as built — `active_run` is not a save-scum surface: the attempt is committed before playback).
```
new:
```
DESIGNER-06 (Q-53 as built — `active_run` is not a save-scum surface: the attempt is committed before playback), Q-69 + Q-13 (A9: `FLAG_DEFAULTS.achievement_rp = true` and `GameState.gd:2920` reads it; `Achievements.claim_grant()` gains the reputation branch its coin branch has — `rp_paid(claimed)` + `rp_cap(rp_earned_lifetime)` with the blocked sentence "The town has heard its share for now — %d of the %d reputation it may pay against %d earned."; `describe_reward()`'s "(reputation is not signed off — …)" clause deleted; `rost_one_of_each` and `rost_comfortable` gain `"rp": 15`; `econ_upgrade_one` "Sharpened, Finally" becomes `econ_first_ten` "Pocket Change" — type economy, blurb "Ten items sold. The Merchant has stopped inspecting them, which is either trust or fatigue.", condition `{"kind": "items_sold", "count": 10}`, the same five Minor Healing Potions; the `_notes` sentence about the eleven worked examples reworded — ten ship verbatim, one is replaced by Q-13's row).
```

## 119. build/plan/ship/00-plan.md
W7-SAVE — Owns.
old:
```
`docs/14-technical-architecture.md` §7, `tests/unit/test_savegame.gd`, `test_game_state.gd`, `test_achievements.gd`
```
new:
```
`docs/14-technical-architecture.md` §7, `data/achievements.json`, `sim/core/Achievements.gd`, `tests/unit/test_savegame.gd`, `test_game_state.gd`, `test_achievements.gd`
```

## 120. build/plan/ship/00-plan.md
W7-SAVE — Acceptance and Size; W7-AUD-AMB's heading.
old:
```
after an A1 clear the feed has a row of kind `reputation` whose text starts with "+"; `test_full_loop.gd` green.
- Shot: `LoadSave --fixture=play` (Continue reads the slot); the rest is tests.
- Green: `test_savegame.gd`'s existing 512+ lines green; no screen tree/name change; SPACES.
- Size: M.

### W7-AUD-AMB — four ambience beds through one door
```
new:
```
after an A1 clear the feed has a row of kind `reputation` whose text starts with "+"; a quit after `record_attempt` with `difficulty_mult` 0.75 and `ninja_pulled` set, then Continue, replays with both (same `outcome`, `rounds` and `consumables_unspent`); `test_achievements.gd`: a reputation-kind claim pays 15 RP, board RP ≤ 15 % of `rp_earned_lifetime` over the scripted full run, the "not signed off" note never prints, no record on the wall names an absent feature; `test_full_loop.gd` green.
- Shot: `LoadSave --fixture=play` (Continue reads the slot); the rest is tests.
- Green: `test_savegame.gd`'s existing 512+ lines green; no screen tree/name change; SPACES.
- Size: M+.

### W7-AUD-AMB — five ambience beds through one door
```

## 121. build/plan/ship/00-plan.md
W7-AUD-AMB — Goal.
old:
```
the camp, tavern, market and cave stages mount with a seamless loop on the Music bus (Q-A's default), crossfading on scene change; the dungeon and town aerial play the camp bed until W10-BUFFER authors theirs (a stated default);
```
new:
```
the camp, tavern, market, cave and dungeon stages mount with a seamless loop on the Music bus (Q-98 (ii)), crossfading on scene change; the town aerial plays the camp bed by design (BL-138 — the aerial is the guild's own camp from above);
```

## 122. build/plan/ship/00-plan.md
W7-AUD-AMB — the fifth bed.
old:
```
`amb_cave` drip + low air;
```
new:
```
`amb_cave` drip + low air, `amb_dungeon` the cave's 40-120 Hz hollow rumble + a chain-creak (`stick_slip` at 2-4 Hz, 1.2 s, every 9-17 s) + a distant stone fall every 20-40 s, no drip (BL-138 — a recombination of the cave's layers plus one event, S);
```

## 123. build/plan/ship/00-plan.md
W7-AUD-AMB — Q-F as ruled.
old:
```
Q-F's default (the arena bed follows `arena_for`: cave bed for the cave, camp bed for the dungeon until authored)
```
new:
```
Q-98 (ii) as ruled (the arena bed follows `arena_for`: `amb_cave` for the cave, `amb_dungeon` for the dungeon; `amb_cave` is the dungeon's shed-fallback, never the camp)
```

## 124. build/plan/ship/00-plan.md
W7-AUD-AMB — Assets, the BEDS comment, the check count.
old:
```
- Assets: four loops (PY, gen_amb.py).
```
new:
```
- Assets: five loops (PY, gen_amb.py).
```

## 125. build/plan/ship/00-plan.md
W7-AUD-AMB — the table's comment.
old:
```
`BEDS` maps every `game/assets/scenes/*.json` name to a bed (dungeon/town → `amb_camp`, stated in the table's comment).
```
new:
```
`BEDS` maps every `game/assets/scenes/*.json` name to a bed (`stage_town` → `amb_camp` by design, stated in the table's comment; the dungeon has its own).
```

## 126. build/plan/ship/00-plan.md
W7-AUD-AMB — Acceptance.
old:
```
`gen_amb.py --check` prints 4 AGREE and the loop-point wrap-around RMS check passes for each;
```
new:
```
`gen_amb.py --check` prints 5 AGREE and the loop-point wrap-around RMS check passes for each; the dungeon bed is not the camp's bytes;
```

## 127. build/plan/ship/00-plan.md
W7-DOCS — the rows it carries (RULINGS.md §5).
old:
```
DESIGNER-06/15/16/20/21/24/25/48 propagated as answered or at the §6 default (Q-53 as built; BL-42 rank; BL-22 accept; Q-22 as built; Q-14 no level-ups, Drilling post-1.0, "Lv." dormant; the aerial as built; encounter names placeholders; BL-40 "buy a round" cut from docs/11 §8.3 or given its number)
```
new:
```
the rulings propagated from `build/plan/ship/RULINGS.md` §5 — the new rows BL-112, BL-119 (its vocabulary half), BL-122, BL-123, BL-124, BL-126, BL-128, BL-129, BL-130, BL-131, BL-137, BL-142 and Q-100's text, and the amendments Q-13 and Q-14 ("§9's line not taken", with the reason), Q-22 (the two `reputation.json` `town_unlock` lines — the one data file this unit edits, by handoff to W7-SAVE which owns nothing in `data/` this wave either: the orchestrator applies it at the close), Q-31 (and the duplicate `#q-31` anchor), Q-33, Q-39/Q-61/Q-68 (docs/11 §3 "gold (G)"), Q-53, Q-96, Q-98 (i)/(iii) + docs/02 §9.1's Audio column + docs/13 §12.4's twelfth hook, Q-99 (docs/13 §12.2 row 1, §11.4), BL-22, BL-30 superseded, BL-40 (docs/11 §8.3, §4.2 S3), BL-42 (docs/02 §4.3's column, docs/13 §9.1/§9.4), BL-87 (docs/08 §5.3 DECIDED-for-1.1, docs/10 §10), BL-95 (docs/07 §3 :106, §7.3, docs/13 §5 S11), BL-96 (docs/04 §10, docs/14 §5), BL-97 (docs/13 §5 S13/S16, §13.1, §13.2), BL-98 (docs/09 §14.3, docs/11 §6.3), BL-100, BL-101, BL-102 (docs/02 §9.1 as the six-row table), BL-103 (and spec 00 §2.7's rows), BL-104, BL-105 (docs/14 §12's status line), BL-106, BL-107 (🔷 → DECIDED), BL-114 (docs/07 §7.3's grace row, docs/10 §6's number), BL-125 (spec 00 §2.5), BL-127 (docs/13 §8.3 three-row table, §13's criterion and text-size rows, §14's logotype line, §15.1's ramp row and the struck Language / Controller-glyphs / font-choice rows — BL-133), BL-126 (docs/12 §2.2 row 6, docs/00 VS7), Q-14's docs/02 §8.1/§11, BL-135 (spec 00 §2.3 "no level is shown"); docs/08 §9.3a and docs/10 §8/§9.1's tables are NOT drafted here — W8-SIM-BALANCE's, docs commit before data commit
```

## 128. build/plan/ship/00-plan.md
W7-DOCS — docs/07 §5.6 exists as a section with a pointer (the table is W9-REVIEW's handoff).
old:
```
Q58-2 (docs/04 §11.2's cross-reference → docs/07's new empty §5.6 "Legendary quirks — specs pending BL-58")
```
new:
```
Q58-2 (docs/04 §11.2's cross-reference → docs/07's new §5.6 "Legendary quirks" carrying a pointer to BL-58's ruled table, which W9-REVIEW's handoff fills)
```

## 129. build/plan/ship/00-plan.md
W7-DOCS — Owns and Size.
old:
```
- Owns: `docs/01`, `02`, `03`, `04`, `05`, `07`, `08`, `09` (§13.1 note only), `10`, `13`, `14` (§4, §10.4, §11), `docs/15-open-questions.md`
```
new:
```
- Owns: `docs/00` (VS7 only), `01`, `02`, `03`, `04`, `05`, `07`, `08`, `09` (§13.1 note only), `10`, `12`, `13`, `14` (§4, §10.4, §11, §12 status line), `art/ref/specs/00` (§2.3, §2.5, §2.7 rows), `docs/15-open-questions.md`
```

## 130. build/plan/ship/00-plan.md
W7-DOCS — Size.
old:
```
- Size: M.

Wave 7 handoffs expected:
```
new:
```
- Size: L (every item is a row already written in RULINGS.md §5; the risk is volume — write the rows first, the doc amendments after, `test_docs_links.gd` between).

Wave 7 handoffs expected:
```

## 131. build/plan/ship/00-plan.md
§3 intro — the wave-8 ship rule is answered; the inner order is load-bearing.
old:
```
**The ship rule for this wave:** if the page is not back, W8-SIM-BALANCE takes DESIGNER-01's default (c) and DESIGNER-09's proposed curve in writing ("taken under the wave-10 ship rule", a BL row with a switch), because a game whose first raid cannot be won is not shippable and the user's instruction is that §6's default is the loop's when the designer is silent. BUILD_STATE's "do not soften an encounter to make the playtest green" is honoured by the letter of the row: the swing is re-priced by docs/08 §9.3's own formula with the mechanic term (CONTENT-08's mechanism), not nudged.
```
new:
```
**The rule for this wave:** the page is answered (`build/plan/ship/RULINGS.md`): W8-SIM-BALANCE applies BL-110's §9.3a rule and Q-100's curve as ruled, with Q-100's correction rule as its only lever. BUILD_STATE's "do not soften an encounter to make the playtest green" is honoured by the letter of the row: the swing is re-priced by docs/08 §9.3a's own formula, never nudged, and every correction step is one 200-seed sweep recorded in the commit message. **The inner order is load-bearing:** W8-ITEMS's regeneration (the daggers, off-hands and loaners move `raid_entry`) commits before W8-SIM-BALANCE's sweep-and-rebaseline commit; the close's playtest runs once on the joined tree with BL-110's farm rule. The first 200-seed pass is EXPECTED to land A1/A2 above band and A3 under TR (Q-100 says why); the correction rule's step is the answer, not a re-derivation.
```

## 132. build/plan/ship/00-plan.md
Wave 8 ownership — W8-SIM-BALANCE gains `Loot.gd` and `playtest.gd` (A12); W8-CRISIS loses `playtest.gd`.
old:
```
sim/core/Morale.gd (only under lever (a)), sim/model/Encounter.gd, data/encounters_t1.json, data/encounters_adventure_t1.json, data/encounters_tutorial_t1.json, tools/balance_sweep.gd, tools/verify.sh (stage 7), tests/golden/**, sweep_baseline.csv, docs/05, docs/08 §9, docs/10 §8-§9, docs/15, tests: test_adventures.gd, test_tutorials.gd, test_encounters.gd, test_formulas.gd, test_mistakes.gd, test_raid_sim.gd, test_golden.gd, test_sweep_baseline.gd → W8-SIM-BALANCE · Frame.gd, Town.gd, AdventureBoard.gd, GameState.gd, tools/playtest.gd, tests: test_game_state.gd, test_screens.gd, test_full_loop.gd, test_town_layout.gd, test_frame_header.gd → W8-CRISIS
```
new:
```
sim/core/Loot.gd, sim/model/Encounter.gd, data/encounters_t1.json, data/encounters_adventure_t1.json, data/encounters_tutorial_t1.json, tools/balance_sweep.gd, tools/playtest.gd, tools/verify.sh (stage 7), tests/golden/**, sweep_baseline.csv, docs/08 §9 (+ §9.3a), docs/10 §8-§9, docs/15, tests: test_adventures.gd, test_tutorials.gd, test_encounters.gd, test_formulas.gd, test_mistakes.gd, test_raid_sim.gd, test_golden.gd, test_sweep_baseline.gd, test_loot.gd → W8-SIM-BALANCE · Frame.gd, Town.gd, AdventureBoard.gd, GameState.gd, Tavern.gd (the walk-in card's two strings only), tests: test_game_state.gd, test_screens.gd, test_full_loop.gd, test_town_layout.gd, test_frame_header.gd, test_tavern.gd (one assertion) → W8-CRISIS
```

## 133. build/plan/ship/00-plan.md
Wave 8 ownership — W8-KEYS gains the palette (A8); W8-AUD-OPT is the quill only (A13); the untouched list follows.
old:
```
Audio.gd, tools/audio/gen_music.py, gen_sfx.py, game/assets/audio/music/**, test_audio_music.gd → W8-AUD-OPT (conditional). Widgets.gd, Cards.gd, Theme.gd, Palette.gd, Type.gd, Icons.gd, LogPlayer.gd, SaveGame.gd, MainMenu.gd, LoadSave.gd, Roster.gd, Tavern.gd, Completion.gd, shot.gd, export_build.sh: untouched.
```
new:
```
Audio.gd (the `ui.quill` hook row), tools/audio/gen_sfx.py (one entry), game/assets/audio/sfx/ui_quill*.wav, test_audio_binds.gd → W8-AUD-OPT (the quill only, S — the lute is W10-BUFFER's). W8-KEYS also owns game/ui/Palette.gd and tests/unit/test_palette_cvd.gd (BL-127). Widgets.gd, Cards.gd, Theme.gd, Type.gd, Icons.gd, LogPlayer.gd, SaveGame.gd, MainMenu.gd, LoadSave.gd, Roster.gd, Completion.gd, Recruitment.gd (W8-ITEMS's — the walk-in needs no edit in it), Raider.gd, shot.gd, export_build.sh: untouched.
```

## 134. build/plan/ship/00-plan.md
W8-SIM-BALANCE — Goal.
old:
```
- Goal: the designer's lever (or the §6 default) applied by formula and recorded; A3 > 0 and TR ≥ 8/20 with the pins turned back into assertions; M05 buys an effect and M08's window is shorter than its period on every carrier; attrition fires only at the round cap; adds are focused and the Mage's AoE hits every enemy; the Forgiving Guild multiplier exists as a sim parameter and a sweep axis; the E2/E4 goldens exist; `tools/playtest.gd` clears 8/8 and verify stage 7 fails otherwise. ONE regeneration and one `--rebaseline` with the numbers.
```
new:
```
- Goal: BL-110's §9.3a rule applied to the five on-ramp rows and Q-100's curve written into the baseline header with its bands asserted (on-ramp FAIL at 45, raid WARN at 55); A3 ≥ 0.40 and TR ≥ 8/20 with the pins turned back into assertions; M05 buys an effect, M08's window is shorter than its period and M09 recurs on every carrier (BL-115); attrition fires at the enrage round plus a named grace of 5 (BL-114); adds are focused and the Mage's AoE hits every enemy; Adventures roll two per slot (BL-111); the tutorial rate is a two-entry table (BL-90); the Forgiving Guild multiplier exists as a sim parameter and a sweep axis (BL-113); `run()` honours `difficulty_mult` and `ninja_pulled` (BL-116); the E2/E4 goldens exist; the A3/E3/E4/E5 titles land (BL-119); `tools/playtest.gd` farms like a player and clears 8/8, and verify stage 7 fails otherwise. ONE regeneration and one `--rebaseline` with the numbers, AFTER W8-ITEMS's regeneration commit.
```

## 135. build/plan/ship/00-plan.md
W8-SIM-BALANCE — Findings, the lever and the curve as ruled.
old:
```
SIM-19 + DESIGNER-01 + CONTENT-08 + CRITIC-C1 (the lever: default (c) — A1-A3 and the two tutorials re-derived for morale 45 at each rung's own gear stage by docs/08 §9.3's swing formula carrying the mechanic term where M01 is authored; the three Adventure rows and TR's swing rewritten in the hand-authored Tier 1 files; docs/10 §8/§9.1 rows regenerated; alternative (a) `Morale.RARITY_OFFSET[0]` −5 → 0 if the page says so; either way ONE BL row with the switch `Formulas.SWING_PRICES_MECHANICS := true` so the other reading is one flip), DESIGNER-09 + M6-BAL-03 (the target curve: the page's numbers or the proposed 100/100/100/100/75 at Common/raid_entry/55 with A1-A3/TR at ≥ 75/60/40/40 — written into `tests/baselines/sweep_baseline.csv`'s header comment and the BL row; the pins `test_adventures.gd:213` → `rate > 0.0` (≥ 0.4 if the curve says so) and `test_tutorials.gd:364` → `cleared >= 8`), CONTENT-30 (`Mistakes.TUTORIAL_RATE` becomes a two-entry table per slot — the page's answer or 0.5/0.5; A0 stays ≥ 18/20), SIM-13 + SIM-27#2 (E4 `m05.effect.raid_damage` at the M02 pulse value 27 unless the page says otherwise; `m08` `rounds 2, every 5`; `m09` `round 3, every 6`; `Encounter.validate()` refuses an M05 without `effect.amount > 0` and an M08 window ≥ its period — FAIL from this wave; the tier 2-5 M05 specs are regenerated by W9-TIERS's gen_items pass, so the validator's tier 2-5 rows are WARN until then, stated), SIM-12 (attrition at `round_no >= ROUND_CAP` — the +5 gone; DESIGNER's Q "attrition grace" default none),
```
new:
```
BL-110 (the lever, ruled: A0, TR, A1, A2, A3 re-derived by docs/08 §9.3a — the healed clock at stage 0 / all-Common / morale 45 — to exactly the five rows in BL-110: A0 61 HP · 20 raw · 6/9; TR 183 · 8 ×2 · M03 {13/rd, 5000 bp} · 12/17; A1 3 × 41 · 7 ×3 · M04 {1, 11, 5, r5} · 8/12; A2 2 × 76 · 9 ×2 · M04 {1, 12, 6, r6} + M02 15/4 · 10/14; A3 183 · 8 ×2 · M02 15/4 + M03 18/5000 + M04 {1, 15, 6, r6} · 12/17; TR's `mistakes_invited ["stood_in_the_fire"]` and its comedy line "A boss with one trick, a timer, and a puddle somebody is going to stand in. Read the Wipe Report; you will be seeing a lot of it."; A3's `mistakes_invited ["stood_in_the_fire", "healer_oom", "warrior_lost_aggro"]` and "It has adds, a raid-wide and a puddle. Your six idiots have one healer and no Mana on any piece of armour they own."; docs/08 gains §9.3a (this unit drafts it — the docs commit before the data commit, `test_canon_guard.gd` reads the tables) and docs/10 §8/§9.1's rows follow; `Morale.RARITY_OFFSET` untouched; NO `SWING_PRICES_MECHANICS`; `Encounter.validate()` refuses `m01` where `tanks_required < 2`), Q-100 (the curve into `tests/baselines/sweep_baseline.csv`'s header: on-ramp bands at 45 asserted FAIL by `test_sweep_baseline.gd` from this wave, raid bands at 55 recorded WARN until W9-TIERS asserts them; `balance_sweep.gd` prints a `CURVE` line (rung, measured, band, in/out) and the morale-45 raid cells beside the Content rows; the correction rule applied as written — each step one 200-seed sweep in the commit message; the pins `test_adventures.gd:213` → `rate >= 0.40`, `test_tutorials.gd:364` → `cleared >= 8`, A0 `>= 18/20`, "A1 still bites" `<= 19/20` at 55), BL-90 (`Mistakes.TUTORIAL_MISTAKE_MULT := {"A0": 0.0, "TR": 0.5}` read by `Context.tutorial_slot`; `test_mistakes.gd`'s 60-cell check per slot, the hit-rate check on TR only), BL-111 (`Loot.ADVENTURE_ROLLS_PER_SLOT := 2` in `sim/core/Loot.gd` + one assertion; tier 1's A2 `loot_slots` line from W8-ITEMS's handoff), BL-115 (E4 `m05.effect {raid_damage, 27}` r4 every 5; `m08 {rounds 2, every 6}`; `m09 {reduction_pct 40, rounds 3, round 3, every 6, target active_tank}`; `Encounter.validate()` refuses an M05 without `effect.amount > 0` and an M08 window ≥ its period — FAIL from this wave; the tier 2-5 carriers are regenerated by W9-TIERS, so the validator's tier 2-5 rows are WARN until then, stated), BL-114 (`RaidSim.ATTRITION_GRACE_ROUNDS := 5`, `encounter.attrition_grace` read in `_check_end` with the validator `>= 0`, the Story line at `enrage_round` on fights without an authored M06 — "Round 17. The boss has stopped being careful. Five rounds before this stops being a fight."), BL-119's wave-8 half (A6: `"title"` on A3 "The Cartographer", E3 "The Understudy", E4 "The Orator", E5 "The Landlord" in the three files this unit rewrites; `test_encounters.gd` asserts a non-empty `title` on every mini_boss/main_boss rung and none on trash), BL-116's sim half (`run()` reads `mstate.ninja_pulled`: the provisions pass skipped and every item listed in `result.consumables_unspent` with reason `ninja_pulled`; the entry through `_log_mistake` at round 1 ROUND_OPEN at its Critical band with `Token.DISTRACTION`; `test_raid_sim.gd::test_a_ninja_pull_starts_the_fight_unbuffed_and_names_the_puller`), A12 (`tools/playtest.gd` is this unit's: the farm rule — before a raid rung re-run A3 → A2 → A1 until no raider wears `start`-source armour or an unarmed main hand, before E2-E5 re-run cleared raid rungs to `raid_entry`; farm runs are attempt rows; the 5-attempt cap applies only to the rung being sized; a local stage predicate (start / adventure / raid by `source` on worn items and an armed main hand) — no `RaidPlan.gd` edit; the harness buys the cheapest starters first and the sweep runs with the shelf ON, stated in the row; `_can_still_make_progress`'s insolvency line is W8-CRISIS's one handoff line, calling `GameState.is_insolvent()`),
```

## 136. build/plan/ship/00-plan.md
W8-SIM-BALANCE — Findings, the tail (M1, CONTENT-12, playtest ownership).
old:
```
CONTENT-12's build branch only if the page said "build" (`run()` honours `opts.ninja_pulled` — the roll is W8-CRISIS's), DESIGNER-17's Q-36 is NOT here (W9-KITS), the playtest promoted (`verify.sh` stage 7 WARN → FAIL; `tools/playtest.gd` is W8-CRISIS's file — its 8/8 is run, not edited, here),
```
new:
```
Q-36 is NOT here (W8-ITEMS's two rows; the `e5_*_raid` goldens with raid-geared Rogues move in THIS unit's regeneration, which is why it commits after W8-ITEMS), the playtest promoted (`verify.sh` stage 7 WARN → FAIL; `tools/playtest.gd` is this unit's file — A12),
```

## 137. build/plan/ship/00-plan.md
W8-SIM-BALANCE — Owns.
old:
```
- Owns: `sim/core/RaidSim.gd`, `sim/core/Formulas.gd`, `sim/core/Mistakes.gd`, `sim/core/Morale.gd` (only if lever (a)), `sim/model/Encounter.gd`, `data/encounters_t1.json`, `data/encounters_adventure_t1.json`, `data/encounters_tutorial_t1.json`, `tools/balance_sweep.gd`, `tools/verify.sh` (stage 7's verdict line only), `tests/golden/Scenarios.gd` + `tests/golden/*.json`, `tests/baselines/sweep_baseline.csv`, `docs/05-morale.md` (only under (a)), `docs/08` §9.3 (the formula's mechanic term, one paragraph), `docs/10` §8/§9.1 (the rows), `docs/15-open-questions.md`, `tests/unit/test_adventures.gd`, `test_tutorials.gd`, `test_encounters.gd`, `test_formulas.gd`, `test_mistakes.gd`, `test_raid_sim.gd`, `test_golden.gd`, `test_sweep_baseline.gd`.
```
new:
```
- Owns: `sim/core/RaidSim.gd`, `sim/core/Formulas.gd`, `sim/core/Mistakes.gd`, `sim/core/Loot.gd`, `sim/model/Encounter.gd`, `data/encounters_t1.json`, `data/encounters_adventure_t1.json`, `data/encounters_tutorial_t1.json`, `tools/balance_sweep.gd`, `tools/playtest.gd` (SPACES — A12), `tools/verify.sh` (stage 7's verdict line only), `tests/golden/Scenarios.gd` + `tests/golden/*.json`, `tests/baselines/sweep_baseline.csv`, `docs/08` §9.3a (the healed-clock paragraph, new) and §9.1's Rogue column note, `docs/10` §8/§9.1 (the rows) and §6 (the grace's number), `docs/15-open-questions.md`, `tests/unit/test_adventures.gd`, `test_tutorials.gd`, `test_encounters.gd`, `test_formulas.gd`, `test_mistakes.gd`, `test_raid_sim.gd`, `test_golden.gd`, `test_sweep_baseline.gd`, `test_loot.gd` (or the loot half of `test_raid_sim.gd`).
```

## 138. build/plan/ship/00-plan.md
W8-SIM-BALANCE — Build notes: the order.
old:
```
Order: the rule changes that do not need the ruling (SIM-08, SIM-12, SIM-13, M1's parameter, the validator) first, sweep, then the lever, sweep again, then the regeneration + `--rebaseline` in one commit whose message carries the before/after table, then the two pins, then stage 7 → FAIL. If the page came back with lever (a) or a curve, apply those; if not, the default, and the BL row's first line reads "taken under the wave-10 ship rule".
```
new:
```
Order: the rule changes (SIM-08, BL-114's grace, BL-115's three params and the validator, BL-113's parameter, BL-111's constant, BL-90's table, BL-116's `ninja_pulled` branch, the titles) first, sweep, then BL-110's five rows (docs/08 §9.3a's commit first), sweep at 45 and read Q-100's CURVE line, apply the correction rule's steps one 200-seed sweep at a time with each step in the commit message, then — after W8-ITEMS's regeneration has landed on the branch — the regeneration + `--rebaseline` in one commit whose message carries the before/after table, then the pins, then stage 7 → FAIL. The rows are BL-110 / Q-100 as RULINGS.md words them; nothing reads "taken under the wave-10 ship rule".
```

## 139. build/plan/ship/00-plan.md
W8-SIM-BALANCE — Build notes: the close.
old:
```
At the close the orchestrator runs the playtest AFTER W8-ITEMS's price change lands (§0.4); W8-ITEMS guards its own change against the walk.
```
new:
```
Inner order (§0.4, three clauses): W8-ITEMS's regeneration commits first → this unit's sweep-and-rebaseline commit → the close's playtest once on the joined tree with the farm rule; W8-ITEMS guards its own change against the walk before its last commit.
```

## 140. build/plan/ship/00-plan.md
W8-SIM-BALANCE — Acceptance.
old:
```
`test_raid_sim.gd::test_attrition_only_at_the_round_cap`, `::test_adds_are_focused_before_the_boss`, `::test_the_mages_aoe_hits_every_living_enemy`, `::test_difficulty_mult_scales_mistakes_and_boss_hp`; `balance_sweep.gd --forgiving` prints a second table; seven goldens byte-identical after the commit; the drift gate green against the new baseline; docs/15 carries the BAL-04 row, the curve row, the E4 rows and the M1 row.
```
new:
```
`test_raid_sim.gd::test_attrition_fires_at_the_enrage_round_plus_the_grace`, `::test_adds_are_focused_before_the_boss`, `::test_the_mages_aoe_hits_every_living_enemy`, `::test_difficulty_mult_scales_mistakes_and_boss_hp`, `::test_a_ninja_pull_starts_the_fight_unbuffed_and_names_the_puller`; `test_encounters.gd`: every mini_boss/main_boss rung has a `title`, no trash rung does, no `m01` below two tanks; `test_sweep_baseline.gd` asserts the five on-ramp bands and prints the five raid bands as WARN; `balance_sweep.gd --forgiving` prints a second table; seven goldens byte-identical after the commit; the drift gate green against the new baseline; docs/15 carries BL-110, BL-111, BL-113, BL-114, BL-115, BL-116, BL-90's amendment and Q-100 as RULINGS.md words them.
```

## 141. build/plan/ship/00-plan.md
W8-CRISIS — Goal.
old:
```
- Goal: docs/05 §6.3's five guarantees exist; after a disband the town says what happened and what to do; a guild that cannot field a party and cannot afford a hire reads why on the Board; the rank-up callout the reputation feed line promised appears on the next Town visit; the BIG-dumb warning shares the banner; the Forgiving Guild setting reaches the sim.
```
new:
```
- Goal: docs/05 §6.3's five guarantees exist; after a disband the town says what happened and what to do; an insolvent guild reads why on the Board and finds the walk-in on the Tavern board (BL-143); the break-phase ninja pull rolls at Depart (BL-116); the rank-up callout the reputation feed line promised appears on the next Town visit — also after a board claim (Q-69); the BIG-dumb warning shares the banner; the Forgiving Guild setting reaches the sim.
```

## 142. build/plan/ship/00-plan.md
W8-CRISIS — Findings: the walk-in and the break roll replace the conditionals.
old:
```
not game over — DESIGNER's default; the solvency floor only if the page said yes, else the sentence), SHIP-13 (2)(3) (`tools/playtest.gd` gains `_can_still_make_progress` calls after every attempt, rest and hire with WALL lines — CRITIC-R2 says the invariant exists since W5-TESTS; this extends where it is called; the Board sentence "You cannot field a party and cannot afford a recruit — sell gear at the Market or start a new guild." when roster < party size and gold < the cheapest hire; the bail-out question is §6's),
```
new:
```
not game over — BL-143; the after-state line "The guild disbanded on day N. The tent is still yours, and so is the purse. The Tavern is up the road."), BL-143 (the walk-in: `GameState.is_insolvent() -> bool` = roster.size() < `RaidPlan.party_size(next_open_mission)` AND gold < the cheapest seat on the board (`Recruitment.cost_of` under `PRICE_SCALE`) AND `Economy.total_sell_price(pending_loot + worn gear, rank)` < that seat; while it holds `refresh_board()` appends one candidate beyond `board_slots()` from `Recruitment.generate(rng, Enums.Rank.UNKNOWN, tier)` — a Common by canon's own weights, no `Recruitment.gd` edit — and records its id in `flags.walk_in_id`; `hire()` charges 0 for that id and clears the flag; the Tavern card reads price "Free" and "A walk-in. Will raid for a bed." (two strings in `Tavern.gd`, this unit's for that reason); the Board prints "You cannot field a party and cannot afford a recruit. Someone at the Tavern will raid for a bed."; no loan), BL-116's roll (at Depart on a raid encounter that already has an attempt this cycle, `start_attempt` rolls one `Mistakes.roll` per living party member at the AMBIENT site on the seeded channel `break` with `ctx.break_phase = true`; only a MIS_NINJAPULL draw counts, the first in slot order pulls, at most one per break; the result goes into the run options and `active_run.ninja_pulled`; `test_game_state.gd::test_the_break_rolls_only_after_a_first_pull`), SHIP-13 (2)(3) (`tools/playtest.gd` is W8-SIM-BALANCE's this wave — A12: its `_can_still_make_progress` insolvency line is this unit's ONE handoff line, `GameState.is_insolvent()`, applied at the close; the WALL lines print only for the disband/insolvency states),
```

## 143. build/plan/ship/00-plan.md
W8-CRISIS — the callout also on a board claim; no conditional break branch.
old:
```
CONTENT-12's build branch only if the page said "build" (the break roll at Depart behind `BREAK_PHASE_ROLLS`), `handoff-W7-SIM-EFFECTS.md` §1's consumers (already applied at wave 7's close — this unit only reads them), the Q row (bail-out) via handoff to W8-SIM-BALANCE's docs/15.
```
new:
```
Q-69's listener (the rank-up callout and LOOP-13's feed line hang off `_award_reputation`'s `reputation_changed` signal, so a board claim's +15 RP reaches them without a second log site), `handoff-W7-SIM-EFFECTS.md` §1's consumers (already applied at wave 7's close — this unit only reads them), BL-143 and BL-116's rows via handoff to W8-SIM-BALANCE's docs/15.
```

## 144. build/plan/ship/00-plan.md
W8-CRISIS — Owns and Size.
old:
```
- Owns: `game/ui/Frame.gd` (TABS — the chip stamp), `game/screens/Town.gd` (TABS), `game/screens/AdventureBoard.gd` (TABS — the one sentence), `game/core/GameState.gd` (SPACES — listeners, `start_attempt`'s option, the flags' writers; NO `to_dict` change: `flags` is a Dictionary), `tools/playtest.gd` (SPACES), `tests/unit/test_game_state.gd`, `test_screens.gd`, `test_full_loop.gd`, `test_town_layout.gd`, `test_frame_header.gd`.
```
new:
```
- Owns: `game/ui/Frame.gd` (TABS — the chip stamp), `game/screens/Town.gd` (TABS), `game/screens/AdventureBoard.gd` (TABS — the one sentence), `game/screens/Tavern.gd` (TABS — the walk-in card's price and quote only), `game/core/GameState.gd` (SPACES — listeners, `start_attempt`'s options and the break roll, `is_insolvent()`, `refresh_board()`'s sixth card, `hire()`'s free branch, the flags' writers; NO `to_dict` change: `flags` is a Dictionary), `tests/unit/test_game_state.gd`, `test_screens.gd`, `test_full_loop.gd`, `test_town_layout.gd`, `test_frame_header.gd`, `test_tavern.gd` (one assertion: the walk-in card's text).
```

## 145. build/plan/ship/00-plan.md
W8-CRISIS — Acceptance and Size.
old:
```
the Board with roster 3 and gold 5 prints the solvency sentence; `test_full_loop.gd`: `_can_still_make_progress()` green on every state the walk reaches, including after a disband;
```
new:
```
the Board with roster 3 and gold 5 prints the solvency sentence and the Tavern board carries exactly one 0 G Common ("Will raid for a bed."), hiring it costs nothing, and a solvent guild's board carries none; the break roll fires on a raid encounter's second Depart in a cycle and never on the first, never on an Adventure or a tutorial, and its result is in `active_run.ninja_pulled`; `test_full_loop.gd`: `_can_still_make_progress()` green on every state the walk reaches, including after a disband;
```

## 146. build/plan/ship/00-plan.md
W8-CRISIS — Size.
old:
```
- Size: M (L only if the page bought the solvency floor).
```
new:
```
- Size: L (the walk-in and the break roll are bought — BL-143, BL-116).
```

## 147. build/plan/ship/00-plan.md
W8-KEYS — Goal.
old:
```
- Goal: Space pauses the account and 1-4 set its speed; Q/E step the roster on RaiderDetail; F cycles the Records filter; the sort rows and the list-screen filter rows are struck from §13.1 by BL rows; `nav_codex` is gone with S16; the Forgiving Guild toggle has its row and key; the audit and BUILD_STATE record the wave.
```
new:
```
- Goal: Space pauses the account and 1-4 set its speed; Q/E step the roster on RaiderDetail; F cycles the Records filter; the sort rows and the list-screen filter rows are struck from §13.1 by BL rows; `nav_codex` is gone with S16; the Forgiving Guild toggle has its row and key; a page fades in over 110 ms (Q-99); the morale ramp is the corrected triad and the CVD option reaches the roster (BL-127); the scribe's row and bind land (Q-98 (iii)); the audit and BUILD_STATE record the wave.
```

## 148. build/plan/ship/00-plan.md
W8-KEYS — Findings: the fade (A7), the palette (A8), the quill lines, the chip.
old:
```
CRITIC-M1's Settings half (`forgiving_guild` in `GameSettings.DEFAULTS` default false; one row "Forgiving Guild — fewer mistakes, softer bosses. Changes nothing else."),
```
new:
```
BL-113's Settings half (`forgiving_guild` in `GameSettings.DEFAULTS` default false; one row on the kit's cycle chip — `_cycle_button(key, false, ["Off", "On"])` — "Forgiving Guild — fewer mistakes, softer bosses. Changes nothing else." — BL-140), Q-99 (A7: `ScreenRouter.TRANSITION_MS := 110`; `_load_into_host` adds the new screen at t=0, sets `modulate.a = 0` and tweens to 1 over `TRANSITION_MS` with `Tween.EASE_OUT` through `Widgets.tween`; the outgoing screen freed at once — a fade-in, not a cross-fade; `TRANSITION_MS` reads 0 when `GameSettings.reduced_motion` is true or `shot.gd` is driving; `ui.tab` fires on the fade's first frame; the docstring's "never will" becomes "110 ms, opacity only"; `test_a11y.gd` pins t=0 insertion and the 0 ms fade under `reduced_motion`), BL-127 (A8: `Palette.CAUTION #E8A302`, `POSITIVE #AFEBA2`, `POSITIVE_CVD #C6DDF1`; `BAND_FILL_CVD`/`BAND_INK_CVD`/`band_ink_cvd` deleted; `band_color_cvd` returns `[DANGER, CAUTION, POSITIVE_CVD]` by the `< 30 / < 65` bands; `morale_color` through `band_color_active` so the option reaches the roster; the Settings note "Morale's third colour is sky instead of green, for eyes that do not tell red from green. The number and the state word are unaffected."; `test_palette_cvd.gd` asserts the two triads' L* numbers and drops the §8.3-defect tests; the art-gate baselines re-record at the wave-8 close inside the 0.07 jitter — verify, do not assume), W8-AUD-OPT's two handoff lines (the `audio.play("ui.quill", {"live": live})` bind beside the stamp's in `RaidView._append_line`; the Settings row `{"key": "audio_voice", "label": "Audio — the scribe", "note": "The quill under each line of the account."}` — `test_options_layout.gd:370`'s count moves once for both new rows in one commit),
```

## 149. build/plan/ship/00-plan.md
W8-KEYS — Owns and Size.
old:
```
- Owns: `game/screens/RaidView.gd` (TABS — `_unhandled_input` only; the 150% pass is W9-SCALE-2's), `game/screens/RaiderDetail.gd`, `game/screens/Guildhall.gd` (TABS), `game/core/ScreenRouter.gd` (SPACES), `project.godot` (`[input]` — one action removed), `game/screens/Settings.gd`, `game/core/GameSettings.gd`, `docs/13-ui-ux.md` §13.1,
```
new:
```
- Owns: `game/screens/RaidView.gd` (TABS — `_unhandled_input` and the one `ui.quill` line; the 150% pass is W9-SCALE-2's), `game/screens/RaiderDetail.gd`, `game/screens/Guildhall.gd` (TABS), `game/core/ScreenRouter.gd` (SPACES — the fade and the docstring), `game/ui/Palette.gd`, `project.godot` (`[input]` — one action removed), `game/screens/Settings.gd`, `game/core/GameSettings.gd`, `docs/13-ui-ux.md` §13.1, `tests/unit/test_palette_cvd.gd`,
```

## 150. build/plan/ship/00-plan.md
W8-KEYS — Size.
old:
```
- Shot: `RaidView --fixture=raid --focus` (Pause ringed) and `Settings --fixture` (the new row).
- Green: `test_a11y.gd`'s existing binding tests green; a11y_smoke's rail rules; no tween.
- Size: M.
```
new:
```
- Shot: `RaidView --fixture=raid --focus` (Pause ringed) and `Settings --fixture` (the two new rows; the corrected amber and green on a morale word).
- Green: `test_a11y.gd`'s existing binding tests green; a11y_smoke's rail rules; no tween outside `Widgets.tween` (the fade goes through it).
- Size: M+ (four S: the fade, the palette, the quill lines, the chip).
```

## 151. build/plan/ship/00-plan.md
W8-ITEMS — Goal: the words and names are certain.
old:
```
the tier words and Legendary names land if the page carried them (else the honest fallbacks), the corpus loader's errors fail the boot.
```
new:
```
the twenty tier words, the leather column and the eight Legendary names land (Q-41, BL-117 — no fallback branch is built), the daggers rise one point (Q-36), the Commons arrive with a Borrowed loaner, the 68 item notes are written, the corpus loader's errors fail the boot.
```

## 152. build/plan/ship/00-plan.md
W8-ITEMS — Findings: the ruled words, names, starters, daggers, notes.
old:
```
Q-28/Q-35 docs/09 §10.2's four starter weapons in `items_starting.json` with `source: "start"` on the Market's tier-1 shelf at ~40% of the Adventure weapon's value behind the Q-35 switch), LOOP-18 (`StartingRoster.ARMED := true`: six 0-damage main-hands per class family equipped at `new_game`, sell price 0; the goldens are unmoved by a 0-stat item — asserted),
```
new:
```
Q-28/Q-35 as ruled: docs/09 §10.2's four starter weapons in `items_starting.json` with `source: "start"` on the Market's tier-1 shelf — Chipped Sword `wrb_one_hand` +3 (raised from +2, BL-27's floor), Cracked Staff `monk_two_hand` +4, Splintered Wand ×2 +4, Bent Censer ×3 +4 Mana / heal_base 8 — at 5 / 10 / 10 / 5 G), LOOP-18 as ruled (`StartingRoster.ARMED := true`: seven loaner rows, `source: "start"`, sell 0 — Borrowed Sword for `wrb_one_hand`, Borrowed Staff for `monk_two_hand`, Borrowed Wand ×2, Borrowed Censer ×3 (one name per healer weapon family, as "Adventurer's Healing Focus" ×3 already does) — `damage: 2` = `UNARMED_DAMAGE`, the censer `mana 0, heal_base 6` = `HEAL_FLOOR`; `starting_sets` gain the main hand; the Rogue's loaner is main-hand only; RaiderDetail prints "Borrowed Sword · Damage 2"; the goldens are unmoved because the loaner equals the floor — asserted), Q-36 (the two dagger rows `ITM_T1_RAID_W1H_MH_DAGGER_BASIC` 5 / `_STRONG` 7, `TierScaling.DAGGER_OFFSET := -1` carried through `gen_items.gd` so tiers 2-5 inherit it, the file's `_notes` line rewritten, docs/08 §9.1's Rogue column re-published 24.2 / 24.2 / 28.0 / 35.6 / 49.9; `test_items.gd` pins the two values, `test_tier_scaling.gd` the offset; `--drift` handed to W8-SIM-BALANCE — the `e5_*_raid` goldens move in ITS regeneration, which is why this unit's regeneration commits first),
```

## 153. build/plan/ship/00-plan.md
W8-ITEMS — Findings: the words came; the names came; no fallback.
old:
```
CONTENT-01/04/17 + SHIP-04 (if the words came: `tier_words.json` filled, `pending: false` per tier, `gen_items.gd` regenerated, `name_pending` clears itself; the eight `display_name`s; verify stage 2 proves it; if not: nothing), DESIGNER-03's fallback (if the names did not come: `name_pending` Legendaries are unfindable — one guard in `Recruitment`'s Legendary roll — and `ContentDB` does not mount `data/legendaries/_pending/`; the Records meter reads N-of-named; Natsuna ships), CONTENT-03 (the 68 exception rows named off §11.3's template with a one-line `note` joke and `hand_authored: true` — only if the words came; `test_gen_items_merge.gd` expectation 0 → 68),
```
new:
```
Q-41 (the words, ruled — `tier_words.json`: four tiers `pending: false`, `material` Steel / Silvered / Adamant / Runegold, `cloth` Runeweave / Starweave / Stormweave / Voidweave, `healer` Hallowed / Sanctified / Anointed / Exalted, `raid_title` = `raid_adj` Vanquisher / Conqueror / Ascendant / Immortal, `leather` Studded / Hardened / Masterwork / Flawless with `leather_column.decision` "its own word per tier"; `gen_items.gd` `WORD_COLUMN.monk` and `.rogue` → `"leather"`; the off-hand template takes `material` for the Shield, `healer` for the Tome, `leather` for the Lute; the 16 files regenerated, `name_pending` clears on 304 rows, verify stage 2 proves byte-identity; docs/09 §11.4 widens to six columns), BL-117 (the eight `display_name`s — Gunnar, Ottilie, Alder, Solenne, Casimir, Tallis, Isaura, Lorcan — `name_pending: false`, `name_status` "ruled by the loop, 2026-09-15 delegation"; `shaman.json`'s `name_status` → final; the `name_pending` guard, the `_pending/` move and the N-of-named meter are NOT built; `test_legendaries.gd` asserts every `display_name` set; the Mage file's `quirk.name` is W9-QUIRKS's — leave it), CONTENT-03 (the 68 exception rows named off §11.3's template with a one-line `note` joke and `hand_authored: true`; the two dagger notes carry the sidegrade reading — "Lighter than the sword. The Rogue will tell you that is the point." — so BL-32's "Suggested" never equipping the dagger reads as a choice; `test_gen_items_merge.gd` expectation 0 → 68),
```

## 154. build/plan/ship/00-plan.md
W8-ITEMS — the titles are not here; the surcharge is as ruled.
old:
```
CONTENT-28 (encounter `title`s only if the page listed them; else placeholders), the BL rows (Q-42/40/28/35/43/29/33, CONTENT-29) via handoff to W8-SIM-BALANCE's docs/15.
```
new:
```
(BL-119's titles are NOT here — W7-REPORT, W8-SIM-BALANCE, W8-SCALE-1, W9-TIERS), the BL rows (Q-42/40/28/35/43/29/33/36/41, BL-117, CONTENT-29) via handoff to W8-SIM-BALANCE's docs/15.
```

## 155. build/plan/ship/00-plan.md
W8-ITEMS — Acceptance and Size.
old:
```
`test_legendaries.gd`: `name_pending` Legendaries never appear on the board (fallback) or every `display_name` is set (names came);
```
new:
```
`test_legendaries.gd`: every `display_name` is set and none reads `name_pending`; `test_items_t1_raid.gd`: the two daggers read +5 / +7; verify stage 2 shows 304 rows without `name_pending`;
```

## 156. build/plan/ship/00-plan.md
W8-ITEMS — Size.
old:
```
- Size: L if the words landed (CONTENT-03's 68 rows are a writer's afternoon) / M if not.
```
new:
```
- Size: L (certain — the words landed; CONTENT-03's 68 notes trail the regeneration and may land as the unit's last commit).
```

## 157. build/plan/ship/00-plan.md
W8-SCALE-1 — the prep card's title sub-line (A6).
old:
```
UI-32's RaidPrep half (the verdict figure at `Type.at(FIGURE_XL)` only when it fits, else `FIGURE`; the strip card's action band folds into the card's "Manage" pattern),
```
new:
```
UI-32's RaidPrep half (the verdict figure at `Type.at(FIGURE_XL)` only when it fits, else `FIGURE`; the strip card's action band folds into the card's "Manage" pattern), BL-119's card line (A6: `RaidPrep.gd:446-448`'s sub-line prints the encounter's `title` over its kind when the field is non-empty — the field exists from wave 7; S),
```

## 158. build/plan/ship/00-plan.md
W8-FACILITY — the dressings as BL-102's table (A2).
old:
```
rank dressings = one prop per rank on the same mechanism — a pennant at Known, a notice post at Respected, a paved path at Established, a statue at Renowned),
```
new:
```
rank dressings for ranks 0-3 as BL-102's table on the same mechanism — walkers 0/1/2/3 and lantern flames 6/8/10/10 gated by rank; Unknown hides the two shipped banner props; Known returns them and adds one cloth pennant on a pole beside the Board callout (never on the tent — the tent's cloth banner is facility L2's); Respected adds the notice post beside the Board callout and the pennant takes the crest colour; Established adds the cobble band on the main path (`patch_plate.py`) and a pennant line of 5 between the two big tents; ranks 4-5 (the statue + 2 brazier flames; the second tent, two guards, crest pennants, 4 braziers) are W9-ART's, which owns `stage_camp.json` in wave 9 — the JSON keys are named now so the rows fall back harmlessly),
```

## 159. build/plan/ship/00-plan.md
W8-FACILITY — Assets and Size.
old:
```
- Assets: `facility_l1..l4.png` 337x104 (PY — cut from the camp plate + the dressing), `dressing_{pennant,post,path,statue}.png` and the stall props (PY/SLICE from the plates' own pixels; no new painting — the designer's plates are §7).
```
new:
```
- Assets: `facility_l1..l4.png` 337x104 (PY — cut from the camp plate + the dressing), `dressing_{pennant,post,path}.png` and the stall props (PY/SLICE from the plates' own pixels; no new painting — the designer's plates are §7); the statue, braziers, second tent and guards are W9-ART's cuts.
```

## 160. build/plan/ship/00-plan.md
W8-FACILITY — Acceptance and Size.
old:
```
`test_scene_stage.gd`: `stage_camp` at facility level 0..4 shows exactly the matching tent layer; rank 0..5 shows the matching dressing;
```
new:
```
`test_scene_stage.gd`: `stage_camp` at facility level 0..4 shows exactly the matching tent layer; rank 0..3 shows exactly BL-102's walkers, flames and props for that rank (ranks 4-5 asserted by W9-ART); `test_town.gd` asserts the Known pennant on `--fixture=play`;
```

## 161. build/plan/ship/00-plan.md
W8-FACILITY — Size.
old:
```
- Green: SceneStage contracts; no focusables added to the stage; `build_art.sh --check` 0 DIFFERS; `Market.gd`'s worn-by confirm strings ("take it off", "Keep them") intact.
- Size: M.
```
new:
```
- Green: SceneStage contracts; no focusables added to the stage; `build_art.sh --check` 0 DIFFERS; `Market.gd`'s worn-by confirm strings ("take it off", "Keep them") intact.
- Size: M+ (the walker and flame counts are two more gated layers on the mechanism the unit builds anyway).
```

## 162. build/plan/ship/00-plan.md
W8-AUD-OPT — the quill only (A13).
old:
```
### W8-AUD-OPT — only if the page bought it: the quill under the log, or the generated lute
- Goal: (a) `ui.quill` — a material texture under every log-line arrival on the Voice bus, so the Voice slider is real and its row returns; (b) `gen_music.py` — a deterministic sparse-lute bed per rank on the Music bus under the ambience.
- Findings: AUDIO-13 (a) (one `PARAMS` entry in `gen_sfx.py`, one `HOOKS` row, one line in `RaidView._append_line` — RaidView is W8-KEYS's this wave: a handoff line; the Settings row's return is a handoff to W8-KEYS), AUDIO-09 (ii) (`tools/audio/gen_music.py`: Karplus-Strong plucks on the designer's mode at 60-70 BPM, seeded, 60-90 s loops per rank; `Audio.BEDS_MUSIC`; Known adds a frame drum), DESIGNER-46.
- Owns: `game/core/Audio.gd`, `tools/audio/gen_sfx.py` (one entry), `tools/audio/gen_music.py` (new), `game/assets/audio/music/**`, `tools/build_art.sh` (one block), `tests/unit/test_audio_music.gd` (new), `test_audio.gd`.
- Assets: (a) one sample (PY); (b) five loops (PY).
- Acceptance: `--check` AGREE for every new file; the tape shows one `ui.quill` per revealed line at 1x and none at Instant; the music bed plays under the ambience bed on the Music bus with both sliders live.
- Shot: none (an ear).
- Green: no download; `sim/` silent.
- Size: S (a) / L (b). If neither was bought, the slot is the wave's slack and the two §6 rows record "cut for 1.0".
```
new:
```
### W8-AUD-OPT — the scribe: the quill under the log
- Goal: `ui.quill` — a material texture under every log-line arrival on the Voice bus, so the Voice slider is real and its row returns as "Audio — the scribe" (Q-98 (iii)). The lute is W10-BUFFER's first item (A13), not this unit's.
- Findings: Q-98 (iii) as ruled (one `PARAMS` entry in `gen_sfx.py` — model `stick_slip`, 85 ms, band 1.8-6 kHz, grain 90 Hz, 3 round-robin variants, peak −27 dBFS — the quietest sound in the game — jitter 0; one `HOOKS` row on the Voice bus; the bind `audio.play("ui.quill", {"live": live})` beside the stamp's in `RaidView._append_line` and the Settings row `{"key": "audio_voice", "label": "Audio — the scribe", "note": "The quill under each line of the account."}` — both handoff lines to W8-KEYS, which owns RaidView and Settings this wave; docs/13 §12.4's twelfth row — `ui.quill` | Log line arrival (live speed) | With the line's first pixel — by handoff to W7-DOCS's successor owner of docs/13 (W8-KEYS owns §13.1 only; the §12.4 row goes to the wave-9 docs owner, W9-REVIEW)), AUDIO-13 (a).
- Owns: `game/core/Audio.gd` (the `HOOKS` row), `tools/audio/gen_sfx.py` (one entry), `game/assets/audio/sfx/ui_quill_*.wav` (+ `.import`), `tools/build_art.sh` (the existing `--check` block covers it), `tests/unit/test_audio_binds.gd` (one `ui.quill` per revealed line at 1x, none at Instant or during a skip; `reduced_motion` never silences it), `test_audio.gd`.
- Assets: three samples (PY).
- Acceptance: `gen_sfx.py --check` AGREE for the three; the tape shows one `ui.quill` per revealed line at 1x and none at Instant; after W8-KEYS's handoff lands at the close the Voice slider moves the quill and the row reads "Audio — the scribe".
- Shot: none (an ear).
- Green: no download; `sim/` silent; the four buses unchanged.
- Size: S.
```

## 163. build/plan/ship/00-plan.md
Wave 8 handoffs and the close.
old:
```
Wave 8 handoffs expected: `handoff-W8-ITEMS.md` (tier 1's `loot_slots` line and `RaidSim._lines()` reading the db — both W8-SIM-BALANCE's files; the item BL rows), `handoff-W8-CRISIS.md` (the bail-out Q row), `handoff-W8-KEYS.md` (three BL rows), `handoff-W8-FACILITY.md` (DESIGNER-22's row), `handoff-W8-AUD-OPT.md` (if it ran). At the close, in this order: apply, `verify.sh` full — stage 7 is FAIL now — with the playtest run once on the joined tree (W8-ITEMS pre-checked its price change), `shot_all.sh`, `diff_all.sh`, the 14 numbers recorded, and the BAL-04 row's "taken under the ship rule" line kept or replaced by the designer's answer if it arrived mid-wave.
```
new:
```
Wave 8 handoffs expected: `handoff-W8-ITEMS.md` (tier 1's `loot_slots` line and `RaidSim._lines()` reading the db — both W8-SIM-BALANCE's files; the item BL rows), `handoff-W8-CRISIS.md` (the `_can_still_make_progress` insolvency line into `tools/playtest.gd` — W8-SIM-BALANCE's file; BL-143 and BL-116's rows), `handoff-W8-KEYS.md` (three BL rows; Q-99's and BL-127's rows), `handoff-W8-FACILITY.md` (BL-102's row), `handoff-W8-AUD-OPT.md` (the `ui.quill` bind and the scribe row into W8-KEYS's files — applied at the close; docs/13 §12.4's twelfth hook row). Inner order, load-bearing: W8-ITEMS's regeneration commit → W8-SIM-BALANCE's sweep-and-rebaseline commit → the close. At the close, in this order: apply, `verify.sh` full — stage 7 is FAIL now — with the playtest run once on the joined tree with the farm rule, `shot_all.sh`, `diff_all.sh` re-recorded for the palette (BL-127 — the delta asserted inside the 0.07 jitter) and the `raid-clear` sheet's "Mistakes 1" (BL-90), the 14 numbers recorded.
```

## 164. build/plan/ship/00-plan.md
§4 heading and intro — the branch is decided; W9-QUIRKS is bought.
old:
```
## 4. WAVE 9 — "Tiers and finish" (6 units + 1 conditional)

Why now: the tier sweep can only measure a sim that is final (wave 8's re-baseline — CRITIC-C14), and it is either the mount of tiers 2-5 or the honest Tier-1-only ending, decided by whether the words came; the Bard's songs and the Rogue's swings are the last DECIDED sim rules and move the goldens once more, in the same wave as the tier rows so there is one close; 150% must be empty-allow-list on every route before the export; the derived art (the fallen pose, the 24px emotes, the silhouettes, the Legendary busts) waits on Q01's sign-off and the names; the S polish bundle lands on screens no other unit owns this wave; and the corpus is read by a person once, after every line that will ever exist is written.
```
new:
```
## 4. WAVE 9 — "Tiers and finish" (7 units)

Why now: the tier sweep can only measure a sim that is final (wave 8's re-baseline — CRITIC-C14), and it is the mount of tiers 2-5 (the words came — Q-41, BL-121); the Bard's songs and the three ruled kits (BL-99) are the last DECIDED sim rules and move the goldens once more, in the same wave as the tier rows and the nine quirks (BL-58) so there is one close; 150% must be empty-allow-list on every route before the export; the derived art (the fallen pose, the 24px emotes, the silhouettes, the nine Legendary busts, the rank 4-5 dressings) lands on the ruled scale and names; the S polish bundle lands on screens no other unit owns this wave; and the corpus is read by the loop's reviewing agent once, after every line that will ever exist is written (BL-118). Shed order across the wave, if it must: W9-POLISH's UI-11/UI-29/UI-06 → W10-BUFFER first; the Mage buff second; the rank 4-5 dressings third — none is on the shippable bar; W9-QUIRKS and W9-REVIEW do not shed.
```

## 165. build/plan/ship/00-plan.md
Wave 9 ownership — `stage_camp.json` to W9-ART; W9-QUIRKS is not conditional.
old:
```
SceneStage.gd, Widgets.gd (`speech_bubble` only), Icons.gd, PaperDoll.gd, tools/art/gen_actors.py, derive_busts.py, tools/aseprite/gen_icons.lua, game/assets/actors/**, game/assets/ui/icons/**, game/assets/portraits/legendary_*.png, art/ref/specs/07-*.md, tests: test_art_sources.gd, test_icons.gd, test_scene_stage.gd, test_paper_doll.gd, test_legendaries.gd → W9-ART
```
new:
```
SceneStage.gd, game/assets/scenes/stage_camp.json (the rank 4-5 dressings and the two mood bubbles), Widgets.gd (`speech_bubble` only), Icons.gd, PaperDoll.gd, tools/art/gen_actors.py, derive_busts.py, tools/art/patch_plate.py, tools/aseprite/gen_icons.lua, game/assets/actors/**, game/assets/ui/icons/**, game/assets/vfx/dressing_*.png (statue, braziers, tent, guards), game/assets/portraits/legendary_*.png, art/ref/specs/07-*.md, tests: test_art_sources.gd, test_icons.gd, test_scene_stage.gd, test_paper_doll.gd, test_legendaries.gd → W9-ART
```

## 166. build/plan/ship/00-plan.md
Wave 9 ownership — W9-QUIRKS.
old:
```
sim/core/Quirks.gd, tests/unit/test_quirks.gd (new) → W9-QUIRKS (conditional).
```
new:
```
sim/core/Quirks.gd, data/legendaries/*.json (`quirk.name`, `quirk.status`, `reads_as` only — W9-REVIEW has the barks and bullets; the two units edit disjoint keys, joined at the close), tests/unit/test_quirks.gd (new) → W9-QUIRKS.
```

## 167. build/plan/ship/00-plan.md
W9-TIERS — Goal: the long branch only.
old:
```
- Goal (words came): the swing formula wave 8 ruled is applied to tiers 2-5 through the generator; the per-tier budget rung reaches `TierScaling`; `balance_sweep.gd --tier=N` and `playtest.gd --tier=N` exist; one 8-seed pass per tier records the curve; walls and inversions are ROWS, not tunes; one golden per new mechanic's first carrier; the tier-2 economy walk trips or clears CONTENT-23's slope; S17 fires on the first clear of tier 5. Goal (words did not come): `GameState.COMPLETED_AT := "last_named_tier"` makes S17 fire on the Raid 1 clear; Completion says so; the pending files are moved out of the mount so the export gate clears honestly; a BL row and a README line record the smaller game.
```
new:
```
- Goal: BL-110's §9.3a rule is applied to tiers 2-5's Adventures through the generator and §9.3's twelve-raid rule to their raids; the per-tier budget rung reaches `TierScaling`; `balance_sweep.gd --tier=N` and `playtest.gd --tier=N` exist; one 8-seed pass per tier records the curve and Q-100's raid bands are asserted at 55 (FAIL from this wave); walls and inversions are ROWS, not tunes, and a tier proved uncompletable at its own gear stage flips its `pending` top-down (BL-121); BL-115's three rules land on every tier 2-5 carrier; the tier 2-5 titles land (BL-119); one golden per new mechanic's first carrier; the tier-2 economy walk trips or clears CONTENT-23's slope; BL-22's Tier 2 WARN line prints; `FLAG_DEFAULTS.legendary_quirks` flips to true by W9-QUIRKS's handoff; S17 fires on the first clear of tier 5. There is no "words did not come" branch: `data/_pending/` is never created and the README's "smaller game" line is not written.
```

## 168. build/plan/ship/00-plan.md
W9-TIERS — Findings: the no-words branch struck; the ruled items named.
old:
```
M5-END-1/S17 (`completed` on the first clear of the last NAMED tier — both branches), DESIGNER-02's honest default (the no-words branch: `data/encounters_t{2..5}.json`, `items_t{2..5}_*.json` and `legendaries/_pending/*` excluded from the mount by `ContentDB.tier_is_named()` as today, and from the PACK by moving them to `data/_pending/` under a `.gdignore` (docs/14 §10.3's mechanism — `export_presets.cfg:32-34` says directories are never kept out by `exclude_filter`); `ContentDB.default_paths` follows the move (this unit owns `sim/content/ContentDB.gd` for that one function — nobody else touches it this wave) and the export gate's pending-file list follows it by handoff to W10-EXPORT; Completion's copy: "The guild cleared everything the town had to offer. The road past Raid 1 is not open yet."), UI-48a (an `ENDING_LINES` const of eight lines in the corpus voice passed to the existing `set_lines()` — no SceneStage change), UI-48c, DESIGNER-12's default (END-5 accept — the row), DESIGNER-16 (BL-22's Tier 2 re-measure done here or recorded as not possible), the walls as rows via handoff to W9-REVIEW's docs/15.
```
new:
```
M5-END-1/S17 (`completed` on the first clear of tier 5 — `COMPLETED_AT = "last_named_tier"` now resolves there; the top-down valve of BL-121: a tier that fails its 8-seed pass at its own gear stage has its `pending` flipped back to true, the ending retimes to the tier below and the row records the numbers — never Raid 2-4, never Tier 1), BL-119's tiers 2-5 (the titles through `gen_items.gd`'s encounter table — A4 "The Groundskeeper", A5 "The Lamplighter"; Raid 2 "The Sweeper" / "The Auditor" / "The Encore"; Raid 3 "The Librarian" / "The Choirmaster" / "The Creditor"; Raid 4 "The Censor" / "The Surveyor" / "The Chronicler"; Raid 5 "The Usher" / "The Proctor" / "The Last Word" — E3/E4/E5 of each raid and the Adventure's mini boss), BL-115's tiers 2-5 (M05 `effect.amount` on every carrier, M08 windows, M09's cadence through the generator; the validator's tier 2-5 rows flip to FAIL), Q-100's raid bands (asserted at 55 in `test_sweep_baseline.gd` from this wave; a raid rung outside its band takes at most ONE `target_rounds` +2 step in 1.0, the HP moved printed in the row), BL-58's flag flip (`GameState.FLAG_DEFAULTS.legendary_quirks = true` — W9-QUIRKS's handoff, this unit's file), UI-48a (an `ENDING_LINES` const of eight lines in the corpus voice passed to the existing `set_lines()` — no SceneStage change), UI-48c, BL-122 (the row), BL-22 (the Tier 2 cell's WARN line: morale's span ≥ rarity's, the two numbers printed), the walls as rows via handoff to W9-REVIEW's docs/15.
```

## 169. build/plan/ship/00-plan.md
W9-TIERS — Owns: no no-words ContentDB edit.
old:
```
`sim/core/Economy.gd`, `sim/content/ContentDB.gd` (`default_paths` only, no-words branch), `game/core/GameState.gd` (SPACES — `COMPLETED_AT` only),
```
new:
```
`sim/core/Economy.gd`, `game/core/GameState.gd` (SPACES — `COMPLETED_AT`'s resolution and the `legendary_quirks` flag flip only),
```

## 170. build/plan/ship/00-plan.md
W9-TIERS — Acceptance and Size: one branch.
old:
```
`test_game_state.gd`: `completed` fires on tier 5's last clear; `progress.md` carries the five-tier curve. Acceptance (no words): `test_game_state.gd`: `completed` fires on E5's first clear with tiers 2-5 unmounted; `Completion --completed` prints the honest line; `export_build.sh --dev` names no `name_pending` hold once W10-EXPORT applies the exclusion (this unit's handoff).
- Shot: `Completion --completed` (the one look, either branch).
- Green: RaidSim untouched; canon numbers untouched (every tier-N number is derived); the Tier-1 baseline untouched by this unit.
- Size: L if the words came / S if not.
```
new:
```
`test_game_state.gd`: `completed` fires on tier 5's last clear; `progress.md` carries the five-tier curve; every tier 2-5 boss rung has a `title`; `test_sweep_baseline.gd` asserts Q-100's raid bands; `export_build.sh --dev` names no `name_pending` hold (nothing is pending).
- Shot: `Completion --completed` (the one look).
- Green: RaidSim untouched; canon numbers untouched (every tier-N number is derived); the Tier-1 baseline untouched by this unit.
- Size: L.
```

## 171. build/plan/ship/00-plan.md
W9-KITS — heading, Goal and Findings as ruled (BL-99; the dagger half gone).
old:
```
### W9-KITS — the Bard sings, the Rogue's dagger swings, and the four PROPOSED kits only by the designer's name
- Goal: Q-46's DECIDED Bard songs (`S = 1 + floor(Mana / BARD_S_DIVISOR)`, the six songs and four Wrong Songs as tabled) are in the sim; the Rogue's dagger family swings twice (Q-36's default); the Wizard ramp, Rogue Behind/Front, Monk Guard and Mage buff/AoE land ONLY if the page named them, else their BL row stands (§7); one regeneration and one Tier-1 re-baseline.
- Findings: SIM-10's Bard half (`Formulas.BARD_S_DIVISOR := 10`; `data/classes.json` song params; the Bard's action picks a song by role need, a Wrong Song on a Bard action mistake — the Mistakes map already carries the type), DESIGNER-17 + docs/09 OQ-15 (`Formulas.DAGGER_SWINGS := 2` — the second swing at the same coefficient; the +4 dagger stays canon), SIM-10's four PROPOSED kits + CRITIC-C17 (each an S-M behind its own const if named: `Combatant.ramp_stacks` +10%/round cap 5; `positional_mult` 1.3 / 0.77; Monk Guard with the Warrior family's AC at the rung — Q "Monk Guard's AC" default; the Mage's raid spell buff — the AoE is already every-enemy since W8-SIM-BALANCE), SIM-17's Taunt is already in (W7), m6-kit-bard, m6-kit-proposed.
```
new:
```
### W9-KITS — the Bard sings, the Monk guards, the Rogue faces the boss, the Mage buffs the casters
- Goal: Q-46's DECIDED Bard songs (`S = 1 + floor(Mana / BARD_S_DIVISOR)`, the six songs and four Wrong Songs as tabled) are in the sim; BL-99's three ruled kits — Monk Guard, Rogue Front, Mage Raid Spell Buff — land in the canon-line shape and no wider; the Wizard Ramp is not written; the dagger half is gone (Q-36 landed in W8-ITEMS); one regeneration and one Tier-1 re-baseline.
- Findings: SIM-10's Bard half (`Formulas.BARD_S_DIVISOR := 10`; `data/classes.json` song params; the d6 on seeded channel `song` each round at the Bard's DPS-phase slot picks a song by role need; the d4 Wrong Song on a Bard action mistake — the Mistakes map already carries the type; Drinking Song as `relief_bp 300` for the round; Discord through the retarget path; the Loud Solo through `add_threat`; the canon Charm of Mana is the Tier 1 Bard's Mana — S = 2, 3 with the +20 Instrument, 4 with both; one line `Quirks.immune_to(qid, "WRONG_SONG", enabled)` at the Wrong Song roll for W9-QUIRKS — an immune Bard's mistake still logs and her song plays anyway), BL-99 (1) Monk Guard (`Combatant.in_guard`, evaluated at Round Open: on when the Monk holds a tank flag at setup or when no Warrior is Alive and stable — Tank Lead 1.30, W7's `should_retarget`; off when one is; on entry a Taunt at 1.10 × current highest; `GUARD_THREAT_COEF 3.0`, `GUARD_AC_BONUS +7` in `_apply_damage`, `GUARD_DAMAGE_MULT 0.5` in `_outgoing_damage`; one STORY line each way — "{actor} drops into Guard. Somebody had to."; a Guard Monk counts as tanking for M09 `active_tank`, M11 and M01's holder rule and is never M01's partner), (2) Rogue Front (`positional_mult = ROGUE_FRONT_MULT 0.77` in `_outgoing_damage` when the Rogue is the raider the boss targeted this round — organic threat, MIS_AGGRO, M08 Fixate — else 1.0; the NUMBERS-tier note "(facing the boss)"), (3) Mage Raid Spell Buff (`MAGE_RAID_BUFF +2` per cast for Wizards and per target for Mages while any Mage `is_alive()`, once regardless of Mage count; the Hymn of Focus stacks on top), the Wizard Ramp NOT written (BL-99), SIM-17's Taunt is already in (W7), m6-kit-bard, m6-kit-proposed.
```

## 172. build/plan/ship/00-plan.md
W9-KITS — Build notes and Acceptance.
old:
```
The kit consts are DECIDED-by-designer flips, not PROPOSED code shipped behind `false`: if the page did not name a kit, its code is not written (BUILD_STATE invariant 5).
- Acceptance: `test_class_kits.gd`: a Bard at Mana 30 sings at S = 4; a Bard action mistake produces a Wrong Song line; a Rogue with a dagger deals two swings' damage per action and a Rogue with a sword one; each named kit's rule has a test; goldens byte-identical after the commit; the Tier-1 drift stated.
```
new:
```
The three kits are DECIDED (BL-99), not PROPOSED code behind `false`; the Wizard Ramp's code is not written (BUILD_STATE invariant 5). Balance on a clean run: Guard and Front change nothing (they fire only when a tank is down or a Rogue is being hit); the buff adds ≈ +2-3 % raid DPS; the songs' mean is stated in the re-baseline. W9-TIERS's A3 measurement predates a Guard Monk; the re-baseline restates A3. If the unit must trim, the Mage buff moves to W10-BUFFER; Guard and Front do not move.
- Acceptance: `test_class_kits.gd`: a Bard at Mana 30 sings at S = 4 and at Mana 10 at S = 2; a Bard action mistake produces a Wrong Song line; a Monk with no living stable Warrior enters Guard, taunts, takes +7 AC and deals half, and leaves it when a Warrior is stable; a Rogue targeted by the boss deals 0.77 and an untargeted one 1.0; a Wizard's cast is +2 while a Mage lives and +0 when none does, and two Mages give +2, not +4; goldens byte-identical after the commit; the Tier-1 drift stated.
```

## 173. build/plan/ship/00-plan.md
W9-KITS — Size.
old:
```
- Green: the eighteen mistake types unchanged; the Q-57/Q-58 rules from wave 7 untouched (their tests green).
- Size: M.
```
new:
```
- Green: the eighteen mistake types unchanged; the Q-57/Q-58 rules from wave 7 untouched (their tests green); `TANK_SWAP_NEEDS_A_PARTNER` still true.
- Size: L− (the Bard + three kits; shed order: the Mage buff → W10-BUFFER).
```

## 174. build/plan/ship/00-plan.md
W9-SCALE-2 — the one handoff line for the fight emote (BL-136).
old:
```
LOOP-21's two sites in these files (`%d G` → `Type.gold()` in Market and RaiderDetail — by W9-POLISH's handoff, applied here since this unit owns the files), the last allow-list rows.
```
new:
```
LOOP-21's two sites in these files (`%d G` → `Type.gold()` in Market and RaiderDetail — by W9-POLISH's handoff, applied here since this unit owns the files), BL-136's one RaidView line (W9-ART's handoff: `_line_effects` calls `stage.emote(id, SceneStage.EMOTE_MAP.FIGHT[sev])` on a MISTAKE line under `_effects_allowed` — applied here since this unit owns RaidView), the last allow-list rows.
```

## 175. build/plan/ship/00-plan.md
W9-ART — Goal.
old:
```
- Goal: a fallen raider lies on the floor with a stretched shadow; the ten emotes are 24px in a frame that fits a 2x figure and the mapping from mood/event to glyph is a table; the empty main-hand silhouette matches the class family; the nine Legendaries have derived busts named by `display_name` (only if named — else §7); the reputation feed glyph is drawn.
```
new:
```
- Goal: a fallen raider lies on the floor with a stretched shadow; the ten emotes are 24px in a frame that fits a 2x figure and the mapping from severity/event and mood to glyph is BL-136's two tables; the three fumble flavours play by severity; the Warrior's badge is the shield (BL-106 b); the empty main-hand silhouette matches the class family; the nine Legendaries have derived busts named by `display_name` (BL-117 — certain); the reputation feed glyph is drawn; the camp's rank 4-5 dressings and its two mood bubbles land (BL-102, BL-136).
```

## 176. build/plan/ship/00-plan.md
W9-ART — Findings: the emote map, the glyph, the busts certain, the fumbles, the rank 4-5 dressings.
old:
```
UI-41 + DESIGNER-29's default (`emote_*.png` regenerated at 24px in the A1-S8 outline style through `gen_icons.lua`; `Widgets.speech_bubble` takes a `scale` from `figure_scale`; `SceneStage.EMOTE_MAP` — the proposed mood/event → glyph table recorded 🔷 in spec 07's table),
```
new:
```
UI-41 + BL-136 (`emote_*.png` regenerated at 24px in the A1-S8 outline style through `gen_icons.lua`; `Widgets.speech_bubble` takes a `scale` from `figure_scale`; `SceneStage.EMOTE_MAP` as two dictionaries — `FIGHT` {MINOR: question, MODERATE: sweat, SEVERE: anger, CRITICAL: exclaim, downed: skull, song: note} and `MOODS` {wipe: skull, cleared: heart, at_risk: sweat} — recorded in spec 07's table; `stage_camp.json`: the sweat bubble gains the `at_risk` tag and one `[x, y, "emote:heart", "cleared"]` entry is added; the RaidView call is a handoff line to W9-SCALE-2 and the Town mood pick — `wipe` if the last result wiped, `cleared` if it cleared, `at_risk` if `roster.any(morale < 40)`, else "" — three lines by handoff to W9-POLISH), BL-106 b (`Icons.WARRIOR_GLYPH := "shield"` in `game/ui/Icons.gd`; `tests/unit/test_icons.gd:122` asserts "shield"; no PNG — the glyph exists beside the swords), BL-102's ranks 4-5 (on `stage_camp.json`'s rank-gated mechanism from W8-FACILITY: Renowned 4 walkers, 10 + 2 brazier flames (`fire_camp` at 1x), the stone statue — one idle warrior frame, desaturated, on a 24×10 plinth — in the square; Legendary 5 walkers, 10 + 4 braziers, a second guild tent (a patch copy of the big tent), two `knight_unlabelled` actors flanking it, crest pennants on all four tents; `dressing_{statue,brazier,tent2}.png` cut from the plate's and the sheets' own pixels through `patch_plate.py`; `test_scene_stage.gd` asserts ranks 4 and 5 show exactly the table),
```

## 177. build/plan/ship/00-plan.md
W9-ART — the busts are certain; the fumbles by severity.
old:
```
CRITIC-M5 + m6-legendary-busts (nine busts via `tools/art/derive_busts.py` from the class bust with a distinguishing hue/prop pass, named by `display_name` so `Cards.portrait_for()`'s first pass finds them; `LegendaryPool` drops the dead `portrait_set` field — ONLY if the names came; else the row in §7 and the field stays), LOOP-13's glyph (`log_reputation.png` 22x22 drawn; `Icons.at("log","reputation")` re-pointed from the W7 stand-in), Q18e's default (the three fumble flavours — trip / drop / wrong-target — as three `fumble_*` frames on the same strip, played by the stage on a Minor/Moderate/Severe stamp; if the page edited the list, its three), STAGE-09/TOWN-26/PIPE-05's art halves.
```
new:
```
CRITIC-M5 + m6-legendary-busts + BL-117 (nine busts via `tools/art/derive_busts.py` from the class bust with a distinguishing hue/prop pass — a NAMED pass, not a rarity re-hue (BL-106 d does not bar it) — named by `display_name` (Gunnar, Ottilie, Alder, Natsuna, Solenne, Casimir, Tallis, Isaura, Lorcan) so `Cards.portrait_for()`'s first pass finds them; `LegendaryPool` drops the dead `portrait_set` field), LOOP-13's glyph (`log_reputation.png` 22x22 drawn; `Icons.at("log","reputation")` re-pointed from the W7 stand-in), BL-106 e (the three fumble flavours as three `fumble_*` frames on the same strip; `SceneStage.FUMBLE_BY_SEVERITY = {MINOR: "trip", MODERATE: "drop", SEVERE: "wrong_target", CRITICAL: "wrong_target"}`), STAGE-09/TOWN-26/PIPE-05's art halves.
```

## 178. build/plan/ship/00-plan.md
W9-ART — Owns, Assets, Size.
old:
```
- Owns: `game/ui/SceneStage.gd` (TABS — the fallen state, bubble scale, `EMOTE_MAP`, the fumble frames), `game/ui/Widgets.gd` (`speech_bubble` only), `game/ui/Icons.gd`, `game/ui/PaperDoll.gd`, `tools/art/gen_actors.py`, `tools/art/derive_busts.py`, `tools/aseprite/gen_icons.lua`, `game/assets/actors/**` (regen), `game/assets/ui/icons/**` (the emotes, the glyph), `game/assets/portraits/legendary_*.png` (new, if named), `sim/content/LegendaryPool.gd` (the field), `art/ref/specs/07-assets-sheet-a.md` (the emote table), `tests/unit/test_art_sources.gd`, `test_icons.gd`, `test_scene_stage.gd`, `test_paper_doll.gd`, `test_legendaries.gd` (the bust lookup).
- Assets: `actors/*` regenerated with `down` and three `fumble_*` frames (PY), `emote_<10>.png` 24x24 (LUA), `log_reputation.png` 22x22 (LUA), `legendary_<9>.png` busts (PY, conditional). All through `build_art.sh --check`.
```
new:
```
- Owns: `game/ui/SceneStage.gd` (TABS — the fallen state, bubble scale, `EMOTE_MAP`, `FUMBLE_BY_SEVERITY`, the fumble frames), `game/assets/scenes/stage_camp.json` (the rank 4-5 layers and the two mood bubbles), `game/ui/Widgets.gd` (`speech_bubble` only), `game/ui/Icons.gd`, `game/ui/PaperDoll.gd`, `tools/art/gen_actors.py`, `tools/art/derive_busts.py`, `tools/art/patch_plate.py`, `tools/aseprite/gen_icons.lua`, `game/assets/actors/**` (regen), `game/assets/ui/icons/**` (the emotes, the glyph), `game/assets/vfx/dressing_{statue,brazier,tent2}.png` (new), `game/assets/portraits/legendary_*.png` (new), `sim/content/LegendaryPool.gd` (the field), `art/ref/specs/07-assets-sheet-a.md` (the emote table), `tests/unit/test_art_sources.gd`, `test_icons.gd`, `test_scene_stage.gd`, `test_paper_doll.gd`, `test_legendaries.gd` (the bust lookup). Handoffs: the RaidView emote line (W9-SCALE-2), the Town mood pick (W9-POLISH).
- Assets: `actors/*` regenerated with `down` and three `fumble_*` frames (PY), `emote_<10>.png` 24x24 (LUA), `log_reputation.png` 22x22 (LUA), `legendary_<9>.png` busts (PY), the three rank-dressing cuts (PY). All through `build_art.sh --check`.
```

## 179. build/plan/ship/00-plan.md
W9-ART — Acceptance and Size.
old:
```
`Guildhall --fixture=play` (Renowned fixture if named) shows a Legendary bust that differs from its class bust; `test_icons.gd`: ten emotes at 24 and `log_reputation` at 22; `test_scene_stage.gd`: `party_state_style("fallen")` swaps the frame and the shadow's width; `build_art.sh --check` 0 DIFFERS.
- Shot: `RaidView --fixture=raid --advance=all` (the one look: the fallen).
- Green: SceneStage names and contracts; `Cards.morale_glyph` untouched; no tween.
- Size: M (L if the busts run).
```
new:
```
`Guildhall --fixture=play` shows a Legendary bust that differs from its class bust; `test_icons.gd`: ten emotes at 24, `log_reputation` at 22, the Warrior's glyph "shield"; `test_scene_stage.gd`: `party_state_style("fallen")` swaps the frame and the shadow's width, every `Severity` has a fight glyph and every mood a bubble on the camp, ranks 4 and 5 show exactly BL-102's props; `build_art.sh --check` 0 DIFFERS.
- Shot: `RaidView --fixture=raid --advance=all` (the one look: the fallen).
- Green: SceneStage names and contracts; `Cards.morale_glyph` untouched; no tween.
- Size: L (the busts run; the rank 4-5 dressings shed to W10-BUFFER third in the wave's order if the unit is long).
```

## 180. build/plan/ship/00-plan.md
W9-POLISH — the sigil; no "goes by"; the mood pick by handoff.
old:
```
UI-53 + LOOP-05 + CRITIC-C5 + DESIGNER-31's default (`Frame.REP_ICON := "gem"` — spec 00 §2.5's recorded choice — with the tooltip "N reputation · M more to Known" on chip 2 through `Widgets.tooltip_for`; `"sigil"` selects the existing `rank_<name>` icon so the flip is one constant with no new asset; pips only if Q06 says pips),
```
new:
```
UI-53 + LOOP-05 + CRITIC-C5 + BL-125 (`Frame.REP_ICON := "sigil"` — chip 2 wears the existing `rank_<name>` icon, no word, with the tooltip "N reputation · M more to <next rank>" through `Widgets.tooltip_for`; `test_frame_header.gd` asserts the tooltip contains "reputation" and the texture is `rank_<name>`; the gem stays for the Board's trinket row), BL-136's Town half (W9-ART's handoff: the mood pick — `wipe` / `cleared` / `at_risk` (any roster raider below 40) / "" — three lines where `Town.gd` sets `wipe` today),
```

## 181. build/plan/ship/00-plan.md
W9-POLISH — DESIGNER-37 is nothing to build.
old:
```
UI-04/UI-07/UI-24/UI-39/UI-51/UI-14 if shed by earlier units, DESIGNER-37's default ("Pauline_4" styled as "goes by Pauline_4" on the Tavern card).
```
new:
```
UI-04/UI-07/UI-24/UI-39/UI-51/UI-14 if shed by earlier units. NOT here: BL-120 (the handle stays as generated — no "goes by" styling), Q-99's fade (W8-KEYS), BL-119's title sites (W7-REPORT / W8-SCALE-1).
```

## 182. build/plan/ship/00-plan.md
W9-REVIEW — heading and Goal: the loop is the reviewer (BL-118).
old:
```
### W9-REVIEW — every line that will ever exist, on one page, read by a person once
- Goal: the corpus, the encounter lines, the item notes, the backstory bullets and the names are rendered on one page with sample fills so the designer's read is one sitting; the marks come back as JSON the loop applies; the NINJAPULL lines are deleted if the type stayed cut; the wave's rows and closes land.
```
new:
```
### W9-REVIEW — every line that will ever exist, on one page, read once by the loop's reviewing agent
- Goal: the corpus, the encounter lines, the item notes, the backstory bullets, the names, the 21 titles, the 20 tier words and the 9 Legendary names are rendered on one page with sample fills; a reviewing agent that is not the writer reads it in one sitting against docs/04 §7 and docs/07 §10.3's five rules and returns keep / rewrite / cut marks as JSON; the loop applies them in-wave; BL-53 and the comedy gate close as reviewed-under-delegation (BL-118); the NINJAPULL lines stay (BL-116); the wave's rows and closes land.
```

## 183. build/plan/ship/00-plan.md
W9-REVIEW — Findings.
old:
```
CONTENT-12's tail (the eight NINJAPULL lines deleted from `mistake_lines.json` if the type is still cut; the corpus test's budget row for it removed), CONTENT-22 (the bullets' rule-5 read is on the same page), DESIGNER-14's propagation if the page specced quirks (W9-QUIRKS's rows), the tier walls from W9-TIERS's handoff, the kits' row from W9-KITS, the S18 row from W9-POLISH, the audit closes this wave earns (M5-T25-07/09/10/15, M5-END-1, m6-kit-bard, m6-legendary-busts if run, M3-SAVE-04, m4t-07, Q59-3's cut confirmed, M5-COMEDY-09/12 as signed or "unsigned in writing"), BUILD_STATE's wave-9 line.
```
new:
```
BL-118 (the read itself — M: the reviewing agent's pass and `--apply marks.json` run in-wave; `data/mistake_lines.json`, `names.json` and `achievements.json`'s `_notes` rewritten to say who read them and when; every rewrite re-validated by `MistakeLines._check_writing_rules` and the budget test; the A3 notice's "no Mana on any piece of armour they own" re-read for its third reading in Adventure healer armour — a prophecy is allowed to be wrong later, the reviewer decides whether the joke survives), CONTENT-22 (the bullets' rule-5 read is on the same page), BL-58's docs (docs/07 §5.6 "Legendary quirks" filled with the nine-row table by this unit's docs handoff; docs/04 §11.2 points at it), docs/06 §4.5-4.7 amended to BL-99's built shapes and §4.8 marked post-1.0 (the docs handoff), docs/13 §12.4's twelfth hook row (`ui.quill`, from W8-AUD-OPT's handoff), the tier walls from W9-TIERS's handoff, the kits' row from W9-KITS, the S18 row from W9-POLISH, the audit closes this wave earns (M5-T25-07/09/10/15, M5-END-1, m6-kit-bard, m6-legendary-busts, M3-SAVE-04, m4t-07, Q59-3's cut confirmed, M5-COMEDY-09/12 as reviewed under the delegation), BUILD_STATE's wave-9 line.
```

## 184. build/plan/ship/00-plan.md
W9-REVIEW — Owns adds docs/06, 07, 13 for the handoff rows; Build notes; Acceptance; Size.
old:
```
- Build notes: the page is handed over ONCE, at this wave's close, after W9-TIERS's branch is known (the 68 notes exist or do not). The marks are applied as they come — in this wave if the read is fast, in W10-BUFFER if not. Every rewrite is re-validated by `MistakeLines._check_writing_rules` and the budget test.
- Acceptance: `corpus_review.py` renders the page with every line present (a count line at the top equals the corpus's); `--apply` on a fixture marks file rewrites one line, cuts one and leaves the tests green; `test_mistake_lines.gd` green with NINJAPULL's row gone (if cut); docs/15 carries BL-53's state and the comedy row; `audit_stale.py --top 15` names no done row; BUILD_STATE ≤ 250 lines.
- Shot: none (a page); the designer's read is the review.
- Green: no game file; the corpus's schema unchanged.
- Size: S (the instrument) + the designer's read.
```
new:
```
- Build notes: the page is rendered ONCE, after W8-ITEMS's and W9-TIERS's regenerations are on the branch (the 68 notes and the tier 2-5 titles exist), and read by a second agent in one sitting; the marks are applied in this wave, W10-BUFFER only if the rewrites overflow. Every rewrite is re-validated by `MistakeLines._check_writing_rules` and the budget test. `build/plan/ship/corpus-review.md` ships in the tree so the designer can file marks as a 1.0.x data patch. docs/06, docs/07 §5.6 and docs/13 §12.4 rows go by this unit's docs handoff (its docs/15 ownership is in-wave; the other docs are the close's).
- Acceptance: `corpus_review.py` renders the page with every line present (a count line at the top equals the corpus's); `--apply` on the reviewer's marks file rewrites and cuts as marked and leaves the tests green; `test_mistake_lines.gd` green with NINJAPULL's row intact; docs/15 carries BL-53 RESOLVED and BL-118; the three `_notes` name the reviewer and the date; `audit_stale.py --top 15` names no done row; BUILD_STATE ≤ 250 lines.
- Shot: none (a page); the reviewing agent's marks file is the review.
- Green: no game file beyond the corpus data; the corpus's schema unchanged.
- Size: M (the instrument is S; the read and the marks are the rest).
```

## 185. build/plan/ship/00-plan.md
W9-QUIRKS — bought (BL-58).
old:
```
### W9-QUIRKS — only if the page specced them: nine rows in `Quirks.SPECS`
- Goal: the nine Legendary quirks do what the designer's rows say through the four hooks W7-SIM-EFFECTS threaded; the ones that need a fifth hook are reworded per Q58-3 or deferred by name.
- Findings: SIM-20's designer half, CONTENT-18, DESIGNER-14, Q58-1/Q58-3 (as answered), BL-58.
- Owns: `sim/core/Quirks.gd`, `tests/unit/test_quirks.gd` (new). Handoffs: the `GameState.FLAG_DEFAULTS` flip (W9-TIERS's file) and the golden SHA assertion in W9-ART's legendaries test — the handoff carries the new SHA.
```
new:
```
### W9-QUIRKS — nine rows in `Quirks.SPECS`, and the cards tell the truth
- Goal: the nine Legendary quirks do what BL-58's rows say through the four hooks W7-SIM-EFFECTS threaded (plus the `WRONG_SONG` pseudo-type W9-KITS's song site checks); every `reads_as` line says what the sim does; `legendary_quirks` ships on.
- Findings: BL-58 as ruled (the nine `SPECS` rows: warrior `{"tank_priority": 1, "immune": ["MIS_TAUNT_LAPSE"]}`, cleric `{"immune": ["MIS_HEAL_WRONG", "MIS_HEAL_CORPSE"]}`, shaman `{"immune": ["MIS_CHAIN_FIZZLE"]}`, druid `{"threat_multiplier": 0.50}`, mage `{"immune": ["MIS_BROKE_CC"]}`, wizard `{"immune": ["MIS_WRONG_TARGET"]}`, rogue `{"threat_multiplier": 0.80}`, monk `{"relief_bp": 300.0}`, bard `{"immune": ["WRONG_SONG"]}`; the `quirk.status` line and the reworded `reads_as` in all nine `data/legendaries/*.json`; the Mage's `quirk.name` → "Lets Sleeping Adds Lie"; no quirk adds damage or healing; the benchmark twelve's Legendary clear rate moves ≤ 2 pp — asserted), SIM-20's designer half, CONTENT-18, Q58-1/2/3/4 (closed on the row).
- Owns: `sim/core/Quirks.gd`, `data/legendaries/*.json` (`quirk.name`, `quirk.status`, `reads_as` only), `tests/unit/test_quirks.gd` (new). Handoffs: the `GameState.FLAG_DEFAULTS.legendary_quirks = true` flip (W9-TIERS's file), the golden SHA assertion in W9-ART's legendaries test (the handoff carries the new SHA), docs/07 §5.6's table (W9-REVIEW's docs handoff).
```

## 186. build/plan/ship/00-plan.md
W9-QUIRKS — Size.
old:
```
- Size: M. If not bought: nothing; §7's row stands.
```
new:
```
- Size: M (bought — BL-58).
```

## 187. build/plan/ship/00-plan.md
Wave 9 close.
old:
```
At the close: apply; if W9-QUIRKS ran, `write_goldens.gd` once and the SHA recorded; full gate (both baseline files in stage 6b; stage 7 FAIL — and at `--tier` too if the words came), `shot_all.sh` all fourteen sheets, `diff_all.sh`, the numbers, and the corpus page to the designer.
```
new:
```
At the close: apply; `write_goldens.gd` once (W9-KITS and W9-QUIRKS both move `e5_legendaries_raid.json`; W8-ITEMS's `display_name` edit moved no golden — asserted) and the SHA recorded; full gate (both baseline files in stage 6b; stage 7 FAIL, and at `--tier` too), `shot_all.sh` all fourteen sheets, `diff_all.sh`, the numbers; the corpus page's marks are already applied (BL-118).
```

## 188. build/plan/ship/00-plan.md
§5 — wave 10 ownership: `PROVENANCE.md` and the lute.
old:
```
Ownership table (wave 10): tools/export_build.sh, export_presets.cfg, project.godot, build/exports/README-player.txt (generated), tests/unit/test_export.gd → W10-EXPORT ·
```
new:
```
Ownership table (wave 10): tools/export_build.sh, export_presets.cfg, project.godot, PROVENANCE.md, build/exports/README-player.txt (generated), tests/unit/test_export.gd → W10-EXPORT ·
```

## 189. build/plan/ship/00-plan.md
Wave 10 ownership — W10-BUFFER's first item.
old:
```
whatever wave 9 shed and the designer's re-tunes (each in the files its origin unit owned, never a file another wave-10 unit owns) → W10-BUFFER.
```
new:
```
the lute (Audio.gd, tools/audio/gen_music.py, game/assets/audio/music/**, tools/build_art.sh one block, tests/unit/test_audio_music.gd), then whatever wave 9 shed (each in the files its origin unit owned, never a file another wave-10 unit owns) → W10-BUFFER.
```

## 190. build/plan/ship/00-plan.md
W10-EXPORT — Goal: the provenance is signed.
old:
```
file logging is on; the version key is set; the provenance and pending-content gates are green or the HOLD list names exactly what is missing.
```
new:
```
file logging is on; the version key is `1.0.0` and the copyright `© 2026 Malkail`; `PROVENANCE.md`'s eight rows are answered and signed on the designer's behalf (Q-21) and the pending-content gate has nothing to hold (BL-121), so the release run prints `EXPORT OK`; the README-player carries the disclosure, the gamepad sentence, the SmartScreen clicks and "English only"; step 9 prints the zip's SHA-256.
```

## 191. build/plan/ship/00-plan.md
W10-EXPORT — Findings.
old:
```
SHIP-16 (step 9: the zip, the OFL texts beside the .exe, the wrapper excluded — kept for the launch check only; `debug/file_logging/enable_file_logging = true`, `max_log_files = 5`; `application/config/version` bumped; the copyright holder and signing are the designer's — DESIGNER-04/05; unsigned is stated in `README-player.txt`), SHIP-05's release run (step 7/7b re-run on the release export), SHIP-17's gate (green with the signature, or HOLD), SHIP-04 + DESIGNER-02/03's gate half (the `name_pending` hold clears by names or by W9-TIERS's `_pending/` move — the gate reads `data/_pending/` as "excluded, not pending" per `handoff-W9-TIERS.md`),
```
new:
```
SHIP-16 (step 9: the zip, the OFL texts beside the .exe, the wrapper excluded — kept for the launch check only; `debug/file_logging/enable_file_logging = true`, `max_log_files = 5`; `application/config/version = "1.0.0"`, `export_presets.cfg` `file_version`/`product_version` "1.0.0.0", `application/copyright = "© 2026 Malkail"` — BL-132; unsigned as BL-134 words it: the "Known limits" paragraph with the two SmartScreen clicks and the saves path; step 9's last line is the zip's `sha256sum`), Q-21 (the signing commit: each `PROVENANCE.md` row gains its `Answer:` line as Q-21's row words them and every `Signed:` line reads `Signed: the build loop for the lead designer (Malkail), under the 2026-09-15 delegation — <date>`; `test_export.gd:403-416` deleted the same commit and replaced by "every `Signed:` line is non-blank AND every row carries an `Answer:` line"; step 0 prints PASS with 8 rows; README and README-player read "Provenance: every shipped asset family's origin is recorded and signed in PROVENANCE.md"), BL-132's disclosure (README-player's licence block and the sentence "The game's code, pixel art, copy and sound were generated by an AI build loop from the lead designer's own design and under their direction; the reference art was image-model output the designer supplied."), BL-133 (the Controls block's gamepad sentence; "Known limits" lists "English only"), SHIP-05's release run (step 7/7b re-run on the release export), SHIP-17's gate (green — signed), BL-121's gate half (nothing pending: the `name_pending` hold has no files to hold on),
```

## 192. build/plan/ship/00-plan.md
W10-EXPORT — Owns and Acceptance.
old:
```
- Owns: `tools/export_build.sh`, `export_presets.cfg`, `project.godot` (`debug/file_logging/*`, `application/config/version` — additive), `build/exports/README-player.txt` (generated by the script; the template lives in the script), `tests/unit/test_export.gd`.
```
new:
```
- Owns: `tools/export_build.sh`, `export_presets.cfg`, `project.godot` (`debug/file_logging/*`, `application/config/version` — additive), `PROVENANCE.md` (the answers and signatures), `build/exports/README-player.txt` (generated by the script; the template lives in the script), `tests/unit/test_export.gd`.
```

## 193. build/plan/ship/00-plan.md
W10-EXPORT — Build notes and Acceptance: the known limits and the verdict.
old:
```
known limits (Tier 1 only if that branch shipped; unsigned binary; one language), and the pitch. Nothing under `build/exports` is committed.
- Acceptance: `test_export.gd`: the zip's member list equals {exe, pck, OFL-FiraSans.txt, OFL-GrenzeGotisch.txt, README-player.txt}; the wrapper is absent; `project.godot` has the two logging keys and a version ≠ "0.1.0"; `export_build.sh` (release) prints `EXPORT OK` or a HOLD list whose every line names a §6 row;
```
new:
```
known limits (unsigned binary with the two clicks; English only; a gamepad unverified), the licence block with the disclosure, and the pitch. Nothing under `build/exports` is committed.
- Acceptance: `test_export.gd`: the zip's member list equals {exe, pck, OFL-FiraSans.txt, OFL-GrenzeGotisch.txt, README-player.txt}; the wrapper is absent; `project.godot` has the two logging keys and version "1.0.0"; `export_presets.cfg`'s copyright is non-empty; every `PROVENANCE.md` row is signed and answered; `export_build.sh` (release) prints `EXPORT OK` and, as its last line, the zip's SHA-256;
```

## 194. build/plan/ship/00-plan.md
W10-README — the hash, the budget's provenance, the licence line.
old:
```
SHIP-09b (the budget line: "mount ≤ 140 ms warm, frame ≤ 16.6 ms on the reference laptop" in BUILD_STATE and README), DESIGNER-02's README line if the Tier-1-only branch shipped, the licence line (the designer's — else "All rights reserved, <holder pending>" stated as pending),
```
new:
```
SHIP-09b (the budget line: "mount ≤ 140 ms warm, frame ≤ 16.6 ms, calibration loop ≤ 10 ms, on the reference laptop boosting — measured on the second machine at the native window" in BUILD_STATE and README, so WARN is never read as "not measured" — BL-104), BL-134 (the zip's SHA-256 from `export_build.sh`'s last line copied into the release commit's message and BUILD_STATE's wave-10 entry), the licence line ("© 2026 Malkail. All rights reserved. Made with Godot Engine (MIT). Fira Sans and Grenze Gotisch are used under the SIL Open Font License 1.1; the licence texts are beside the .exe." — BL-132) and the status line "Provenance: every shipped asset family's origin is recorded and signed in PROVENANCE.md" (Q-21), BL-135's `diff_all.sh` re-record with before/after numbers in this unit's BUILD_STATE entry (the "Lv." glyph runs gone from the reference fixture's sheets),
```

## 195. build/plan/ship/00-plan.md
W10-README — Acceptance.
old:
```
- Acceptance: `test_readme.gd` green; `test_build_state.gd` green; `audit_stale.py --top 15` prints nothing actionable; every `blocked-needs-human` row left open names its §6 default as taken.
```
new:
```
- Acceptance: `test_readme.gd` green; `test_build_state.gd` green; `audit_stale.py --top 15` prints nothing actionable; no audit row reads `blocked-needs-human` — every one names its RULINGS.md row.
```

## 196. build/plan/ship/00-plan.md
W10-DELETE — Goal and Findings: the "Lv." branches, the Voice row kept, the docstring done in wave 8.
old:
```
- Goal: every dead defensive branch the lint's allow-list carried since wave 6 is deleted with its guard; every row hidden in wave 6 that no later wave built is deleted, not hidden; `tools/lint_copy.sh` runs with an EMPTY allow-list; the Q09 docstring stops saying "never".
```
new:
```
- Goal: every dead defensive branch the lint's allow-list carried since wave 6 is deleted with its guard; every row hidden in wave 6 that no later wave built is deleted, not hidden; the two dormant "Lv. N" branches are gone (Q-14, BL-135); `tools/lint_copy.sh` runs with an EMPTY allow-list.
```

## 197. build/plan/ship/00-plan.md
W10-DELETE — Findings.
old:
```
LOOP's C18's Voice row (deleted unless W8-AUD-OPT returned it), LOOP's C22 (the Raid Group `TABS` entry deleted unless Q18j said "read-only view" — then it was built in W10-BUFFER), UI-46 (the `TRANSITION_MS` docstring "never will" → "not by default"; the constant stays 0 — Q09's default; `BACKLOG.md:168` is W10-README's), the copy lint's allow-list emptied, DESIGNER-40's `prose_font_swap` retire,
```
new:
```
LOOP's C18's Voice row (KEPT — W8-AUD-OPT returned it as "Audio — the scribe"; verified, not deleted), LOOP's C22 (the Raid Group `TABS` entry's remnants deleted — BL-106 j: `Guildhall._tab_reason()`'s `raid_group` branch, the strings in `test_screens.gd` / `test_roster_layout.gd:296,:319` / `test_starting_roster.gd:224` / `test_kit3.gd:525-537` / `test_widgets_kit.gd:494-506` retargeted), Q-14 + BL-135 (the two `if level > 0: "Lv. %d"` branches at `Cards.gd:150-153` and `RaidView.gd:1023-1024` deleted — RaidView's line by handoff, since RaidView is frozen this wave: the orchestrator applies it at the close; `LabelLevel` stays in `Theme.gd` as a tabular style; `tools/fixture_reference.gd`'s four levels stay as data; `diff_all.sh` re-recorded at the close — W10-README records before/after), the copy lint's allow-list emptied, BL-127's `prose_font_swap` retire, BL-133's `language` and `glyph_set` rows and keys,
```

## 198. build/plan/ship/00-plan.md
W10-DELETE — Owns and Acceptance (the docstring is W8-KEYS's).
old:
```
`game/core/GameSettings.gd`, `game/core/ScreenRouter.gd` (the docstring), `tools/lint_copy.sh` (the allow-list),
```
new:
```
`game/core/GameSettings.gd`, `tools/lint_copy.sh` (the allow-list),
```

## 199. build/plan/ship/00-plan.md
W10-DELETE — Acceptance.
old:
```
`tools/lint_copy.sh` with `ALLOW=` empty prints `COPY LINT OK`; `Settings.ROWS` has no `hidden` entry;
```
new:
```
`tools/lint_copy.sh` with `ALLOW=` empty prints `COPY LINT OK`; `Settings.ROWS` has no `hidden` entry and still carries "Audio — the scribe"; `grep -rn '"Lv. %d"' game/` is empty;
```

## 200. build/plan/ship/00-plan.md
W10-CREDITS — the roll as ruled (BL-132, A5).
old:
```
### W10-CREDITS — the roll as signed, or the derivable block under "Credits"
- Goal: S17's Credits panel prints the roll the designer signed (names, roles, the attribution block) — or, unsigned, the derivable block alone under a "Credits" heading with no placeholder sentence; docs/00 §4.4 carries the designer's line; Q-21 and M5-END-4 close in docs/15 as signed or as "taken under the ship rule".
- Findings: DESIGNER-05 + M5-END-4 (the `lines` filled as signed; else the derivable rows from W6-LEDGER's draft and the `[designer credit pending]` marker removed — the heading stands over the block), UI-48b (the Completion print path: heading + lines, nothing else), DESIGNER-04 + Q-21 (the provenance signature's docs/15 close — the row reads "signed <date>" or "unsigned; the README's status says so and the export ships to the designer's machine only"), AUDIO-17 (the audio line stays "generated in-tree"), LOOP-27's fill half, the docs/15 rows this wave earns (M5-END-4, Q-21, M6-FINAL-05 from W10-WALK).
```
new:
```
### W10-CREDITS — the roll as ruled
- Goal: S17's Credits panel prints BL-132's seven lines under "Credits" with no placeholder sentence; docs/00 §4.4.2 carries the disclosure bullet and §4.4.1/§4.4.3 the provenance finding; Q-21 and M5-END-4 close in docs/15 as ruled.
- Findings: BL-132 (`data/credits.json` `lines`, in order: "Malkail — lead designer" · "Built from the designer's notes by an autonomous build loop (Claude)" · "Art drawn by script in Aseprite and Python from references the designer supplied" · "Sound and music generated in-house from physical models" — the unit reads `Audio.MUSIC_BED` before it writes this line and drops "and music" if W10-BUFFER cut the lute (A5) · "Made with Godot Engine (MIT)" · "Fira Sans and Grenze Gotisch — SIL Open Font License 1.1" · "The raiders would like it known that they did their best."; the marker line deleted; `status` cleared; the sidebar fit re-checked at 150 % on `Completion --completed`), UI-48b (the Completion print path: heading + lines, nothing else), Q-21 (docs/00 §4.4.3 and §9 Q14 close with the finding; docs/15's Q-21 row as RULINGS.md words it), the disclosure bullet as docs/00 §4.4.2's last bullet (BL-132), AUDIO-17 (nothing sampled — the line stands on the generators), LOOP-27's fill half, the docs/15 rows this wave earns (M5-END-4, Q-21, BL-133, BL-134, M6-FINAL-05 from W10-WALK).
```

## 201. build/plan/ship/00-plan.md
W10-CREDITS — Acceptance.
old:
```
- Acceptance: `Completion --completed` prints "Credits" and every `lines` entry as a Label; no Label contains "pending" or "not written"; `test_completion.gd` asserts the block's line count equals the file's non-marker lines; docs/15's Q-21 and M5-END-4 headings carry a state.
```
new:
```
- Acceptance: `Completion --completed` prints "Credits" and the seven lines as Labels, the first "Malkail — lead designer"; no Label contains "pending" or "not written"; `test_completion.gd` asserts the block's line count equals the file's lines (7) and that line 4 matches `Audio.MUSIC_BED`; docs/15's Q-21 and M5-END-4 headings carry RULED.
```

## 202. build/plan/ship/00-plan.md
W10-BUFFER — the first item is the lute (A13).
old:
```
### W10-BUFFER — the slack a release wave must have
- Goal: whatever wave 9 shed lands (UI-11/UI-29/UI-06 from W9-POLISH; UI-04/UI-07 if W7-STAGE shed them; the dungeon and town beds for W7-AUD-AMB's table; the Legendary busts if the names came after wave 9); the designer's re-tunes are applied (audio `PARAMS`, corpus marks from W9-REVIEW's page, the arena/boss answers as constant flips); names that arrived after wave 9's close run W9-TIERS's recipe — `gen_items.gd`, verify stage 2, `--tier` sweep, the walls as rows — and the `_pending/` move is reversed.
- Findings: whatever the wave-9 close's report names; DESIGNER-02/03 late; AUDIO-07's remaining beds; CONTENT-16's marks.
- Owns: per item, the files its origin unit owned, never a file another wave-10 unit owns (the beds: `Audio.gd`, `gen_amb.py`, `amb/`; the busts: W9-ART's list; the tiers: W9-TIERS's list; the marks: W9-REVIEW's list).
- Acceptance: each item's origin acceptance line, re-run.
- Size: the slack; if nothing was shed and nothing arrived, the buffer is the full gate run twice on two days.
```
new:
```
### W10-BUFFER — the lute first, then the slack a release wave must have
- Goal: first, the generated sparse lute (Q-98 (i), L): `tools/audio/gen_music.py` in `gen_sfx.py`'s shape — a Karplus-Strong string (delay `fs/f0`, averaging loop filter, decay 0.996, a pluck-position comb at 0.13 of the delay, two strings ±3 cents, a body band-pass at 210 Hz Q 4 at −12 dB), A minor pentatonic A2-A4, the phrase walker (gaps exponential mean 2.4 s clamped 0.6-6 s; step ±1 55 % / ±2 25 % / repeat 10 % / tonic 10 %; 20 % dyads on the nearest fifth; velocity 0.55-0.9; an 8 s rest after every 6-10 notes 15 % of the time), Unknown rubato, Known with the frame drum (200 Hz low-passed noise thump, 90 ms, beats 1 and 3 of 4/4 at 66 BPM, beat 3 −6 dB) and eighth-grid quantised onsets; `music_lute_unknown.wav` 90 s and `music_lute_known.wav` 87.27 s (24 bars), 44.1 kHz mono 16-bit, tail folded over 600 ms, peak −24 / RMS ≈ −34 dBFS; `Audio.BEDS_MUSIC` (rank 0 Unknown, 1-5 Known), `MUSIC_BY_SCENE = {"stage_camp", "stage_town"}`, a second player pair on the Music bus with the beds' crossfade, `Audio.MUSIC_BED := true`; `test_audio_music.gd` (both files exist and `--check` AGREEs; the lute plays under `stage_camp` and not under `stage_arena_cave`; the old `play_bed`-is-a-no-op tripwire rewritten). Then whatever wave 9 shed (W9-POLISH's UI-11/UI-29/UI-06; the Mage buff if W9-KITS shed it; the rank 4-5 dressings if W9-ART shed them; UI-04/UI-07 if W7-STAGE shed them) and any corpus marks that overflowed W9-REVIEW.
- Findings: Q-98 (i) as ruled; whatever the wave-9 close's report names.
- Owns: the lute's files (`game/core/Audio.gd`, `tools/audio/gen_music.py`, `game/assets/audio/music/**`, `tools/build_art.sh` one block, `tests/unit/test_audio_music.gd`) — no other wave-10 unit touches `Audio.gd`; then per item, the files its origin unit owned, never a file another wave-10 unit owns.
- Acceptance: `gen_music.py --check` 2 AGREE; the lute under the camp and the menu with both sliders live; then each shed item's origin acceptance line, re-run.
- Size: the lute is L and is the first thing cut, in writing, if the buffer is consumed by wave 9's sheds — W10-CREDITS's line 4 then drops "and music" (A5). The buffer must not become a seventh unit.
```

## 7. The names

Every name, word and line ruled, in one place. All grepped against `data/`, `game/`, `sim/` and docs/00-14 (2026-09-15): no display-name collision (the tier candidates already in `tier_words.json`'s `candidates` block are the ones kept; Natsuna is canon's).

**The nine Legendaries (BL-117)** — one per class, given names only:

| Class | Name | The file's own character, which the name was fitted to |
|---|---|---|
| Warrior | **Gunnar** | has died more times than he can count and finds that funny; "Front is where I stand. Move." |
| Cleric | **Ottilie** | has your old raid logs printed out; has notes |
| Druid | **Alder** | would raid naked; means "somewhere with trees" by home |
| Shaman | **Natsuna** | canon ("IE Natsuna(the shaman)") — final |
| Mage | **Solenne** | notices when someone is wearing last tier |
| Wizard | **Casimir** | counts ninety seconds; was the only one laughing |
| Rogue | **Tallis** | keeps his own numbers; was behind it the whole time |
| Monk | **Isaura** | turns around three times before every boss |
| Bard | **Lorcan** | arrives as the pull starts; knows the tavern staff by name |

**The twenty tier words and the leather column (Q-41)** — straight MMO words; the joke is who wears them:

| Tier | material | cloth | healer | raid_title (= raid_adj) | leather |
|---|---|---|---|---|---|
| 1 (canon) | Iron | Spellweave | Blessed | Raider | Reinforced |
| 2 | **Steel** | **Runeweave** | **Hallowed** | **Vanquisher** | **Studded** |
| 3 | **Silvered** | **Starweave** | **Sanctified** | **Conqueror** | **Hardened** |
| 4 | **Adamant** | **Stormweave** | **Anointed** | **Ascendant** | **Masterwork** |
| 5 | **Runegold** | **Voidweave** | **Exalted** | **Immortal** | **Flawless** |

Renders: "Steel Adventurer's Cuirass", "Studded Adventurer's Vest", "Runeweave Firestaff", "Hallowed Adventurer's Healing Focus", "Vanquisher's Greaves", "Basic Vanquisher Sword", "Vanquisher Final Headband", "Hallowed Vanquisher's Tome", "Vanquisher's Charm of Mana" … "Runegold Adventurer's Sword", "Flawless Adventurer's Eyepatch", "Voidweave Arcstaff", "Exalted Immortal's Tome", "Basic Immortal Dagger", "Immortal Wizard Staff". Mithril was dropped for Silvered (originality).

**The twenty-one boss-rung titles (BL-119)** — roles, not creatures, because one boss set serves five tiers; shown on the boss plate and the prep card, the canon ladder words as the subtitle; the log keeps "Main Boss":

| Rung | Title | | Rung | Title |
|---|---|---|---|---|
| Tutorial Raid | **The Doorman** | | Raid 3 E3 / E4 / E5 | **The Librarian** · **The Choirmaster** · **The Creditor** |
| Adventure 1 · 2 · 3 | **The Gatekeeper** · **The Tollkeeper** · **The Cartographer** | | Raid 4 E3 / E4 / E5 | **The Censor** · **The Surveyor** · **The Chronicler** |
| Adventure 4 · 5 | **The Groundskeeper** · **The Lamplighter** | | Raid 5 E3 / E4 / E5 | **The Usher** · **The Proctor** · **The Last Word** |
| Raid 1 E3 / E4 / E5 | **The Understudy** · **The Orator** · **The Landlord** | | | |
| Raid 2 E3 / E4 / E5 | **The Sweeper** · **The Auditor** · **The Encore** | | | |

Vocabulary: "Encounter N" in the UI; "Boss N" only as the loot tables' key; "Raid 1", "Adventure 2", "Trash", "Elite", "Add", "Mini Boss", "Main Boss" are canon's placeholders shipped as final. The tutorial trinkets: **Cracked Charm of Power**, **Cracked Charm of Health**.

**The starters and loaners (Q-28 / Q-35):** Market — **Chipped Sword** +3 (5 G), **Cracked Staff** +4 (10 G), **Splintered Wand** +4 (10 G), **Bent Censer** +4 Mana / heal 8 (5 G); loaners at the floors, sell 0 — **Borrowed Sword**, **Borrowed Staff**, **Borrowed Wand**, **Borrowed Censer** ("Borrowed Sword · Damage 2"). Adventure off-hands — **Iron Adventurer's Shield**, **Adventurer's Lute**, **Blessed Adventurer's Tome** (T2+: "Steel Adventurer's Shield", "Studded Adventurer's Lute", "Hallowed Adventurer's Tome").

**The nine quirks (BL-58):** Holds the Line · One More Cast · The Totem Holds · Grows Into the Gap · **Lets Sleeping Adds Lie** (the Mage's, renamed from Second Wind of Fire) · Reads the Whole Fight · Never Where the Boss Looks · Reads the Room · Carries the Beat — the "reads as" lines in §5.2's BL-58.

**The lines ruled (register-exact):**
- The Blacksmith's callout (Q-13): "Closed. The smith took a better offer."
- The record wall (Q-13): **Pocket Change** — "Ten items sold. The Merchant has stopped inspecting them, which is either trust or fatigue." (replaces "Sharpened, Finally").
- The walk-in (BL-143): price "Free"; "A walk-in. Will raid for a bed."; the Board: "You cannot field a party and cannot afford a recruit. Someone at the Tavern will raid for a bed."; the after-state: "The guild disbanded on day N. The tent is still yours, and so is the purse. The Tavern is up the road."
- The tutorial band (BL-141): A0 "Round three: somebody does something stupid. Watch for the stamp — the log says who, and why."; TR "One trick, one timer, one tank between six of them. When it goes wrong, the report says who."; TR's report line "This is the Wipe Report. Who, what, and which round — it is all under 'By raider'."
- The notices (BL-110): TR "A boss with one trick, a timer, and a puddle somebody is going to stand in. Read the Wipe Report; you will be seeing a lot of it."; A3 "It has adds, a raid-wide and a puddle. Your six idiots have one healer and no Mana on any piece of armour they own."
- The epigraph's eyebrow (BL-139): "The notice said:"
- The enrage line (BL-114): "Round 17. The boss has stopped being careful. Five rounds before this stops being a fight."
- Guard's line (BL-99): "{actor} drops into Guard. Somebody had to."
- The wipe-cause fallback (BL-107): "Nobody in particular. The boss simply won."
- The Forgiving Guild row (BL-113): "Forgiving Guild — fewer mistakes, softer bosses. Changes nothing else."; the scribe's row (Q-98): "Audio — the scribe" / "The quill under each line of the account."; the CVD note (BL-127): "Morale's third colour is sky instead of green, for eyes that do not tell red from green. The number and the state word are unaffected."
- The reputation chip's tooltip (BL-125): "N reputation · M more to <rank>" (never "Rep").
- The dagger notes (Q-36): "Lighter than the sword. The Rogue will tell you that is the point."
- The Legendary town line (Q-22): "Perfect potions" · "Legendary raiders, one in twenty"; Established: "Market expansion".
- The credits (BL-132): "Malkail — lead designer" · "Built from the designer's notes by an autonomous build loop (Claude)" · "Art drawn by script in Aseprite and Python from references the designer supplied" · "Sound and music generated in-house from physical models" · "Made with Godot Engine (MIT)" · "Fira Sans and Grenze Gotisch — SIL Open Font License 1.1" · "The raiders would like it known that they did their best." — `© 2026 Malkail`, version 1.0.0.
- The provenance signature (Q-21): "Signed: the build loop for the lead designer (Malkail), under the 2026-09-15 delegation — <date>".
- The currency (Q-61): "G" on chips, "gold" in prose. The handle (BL-120): Pauline_4 is Pauline_4.

## 8. Tensions

For the orchestrator — things a wave must prove, and two seams this consolidation closed that the batches and the critic did not name.

1. **The walk-in needed a file the critic did not check.** UX #60 as ruled edited `Recruitment.roll_board`/`hire()` and a `walk_in` key on the candidate; `Recruitment.gd` is W8-ITEMS's in wave 8 and `Raider.gd` is unowned. BL-143 and edits 142/144 re-home the whole thing into `GameState` (`refresh_board()` appends a sixth card from `Recruitment.generate(rng, Enums.Rank.UNKNOWN, tier)` — Unknown's weights roll only Commons, canon's own rule — and stores its id in `flags.walk_in_id`; `hire()` skips the charge for that id) plus two strings in `Tavern.gd`, which W8-CRISIS therefore takes for those two strings only (Tavern.gd was on wave 8's untouched list; W9-POLISH owns it in wave 9 — no overlap). If `Recruitment.generate` at rank Unknown ever rolls above Common (it cannot while `weights_for(0)` is Common-only), the fix is a `ctx.force_rarity` key by handoff to W8-ITEMS, not a W8-CRISIS edit.
2. **The "Lv." branch in `RaidView.gd` is a wave-10 handoff.** W10-DELETE owns Cards.gd but RaidView.gd is frozen in wave 10 (§5's untouched list); edit 197 makes RaidView's two-line deletion a handoff the orchestrator applies at the close, before the `diff_all.sh` re-record. If the orchestrator prefers, W9-SCALE-2 (RaidView's wave-9 owner) deletes it a wave early — the branch is unreachable either way.
3. **docs/13 §12.4's twelfth hook row has no wave-8 docs owner.** W8-KEYS owns §13.1 only; edit 162 routes the `ui.quill` row through W9-REVIEW's docs handoff. A wave-8 reader of docs/13 §12.4 will find eleven hooks and twelve sounds for one wave; stated here so it is not read as drift.
4. **The first 200-seed pass will not match Q-100 on the first try, by design** (critic tension 1): A1/A2 above band, A3 under TR. The correction rule's steps are the answer and each is one sweep in the commit message; the loop must not read the first table as "BALANCE was wrong". E4 after BL-115's teeth may land above its 45-75 band at 55 — then the ONE permitted `target_rounds` +2 step fires and its HP move is printed; no second step in 1.0.
5. **Wave 8's inner order is load-bearing** (critic tension 2): W8-ITEMS's regeneration → W8-SIM-BALANCE's rebaseline → the close's playtest with the farm rule and the shelf ON. Edit 131 and 139 say so; an orchestrator that runs the rebaseline first ships a stale baseline that §0.2 forbids re-running.
6. **Wave 9 is at capacity** (critic tension 3): TIERS L, KITS L−, ART L, POLISH L. The shed order is written into §4's intro (edit 164): POLISH's UI-11/UI-29/UI-06 → the Mage buff → the rank 4-5 dressings; QUIRKS and REVIEW never shed.
7. **W10-BUFFER's first item is the lute** (critic tension 4) and the buffer must not become a seventh unit; W10-CREDITS reads `Audio.MUSIC_BED` before it writes line 4.
8. **`e5_legendaries_raid.json` is touched by W8-ITEMS (names), W9-KITS and W9-QUIRKS** (critic tension 5): the wave-9 close's single `write_goldens.gd` covers the last two; W8-ITEMS asserts its `display_name` edit moved no golden. `data/legendaries/*.json` is also edited by W9-QUIRKS (`quirk.*`, `reads_as`) and W9-REVIEW (barks, bullets) in one wave — disjoint keys, joined at the close; edit 166 says so.
9. **Q-13 / Q-14 depart from §9's optional "next three"** (critic tension 6): recorded as "§9's line not taken, because canon's own line is conditional" in §5.2, never closed silently.
10. **The walk-in at Respected+ is a Common on a board canon says has none** (critic tension 7): accepted on the card's line; a player report is answered by the card, not the rule.
11. **The daggers are a sidegrade after the fix** (critic tension 8): the two item notes carry it; BL-32's "Suggested" preferring the shared sword is correct.
12. **BALANCE #11's payday spec is post-1.0 and must stay so** (critic tension 9): no `payday_misses` key in v17; nothing in waves 7-10 may cite wages as live.
13. **The `Signed:` lines keep their words** (critic tension 10): "the build loop for the lead designer (Malkail), under the 2026-09-15 delegation" — nothing in the tree shortens it to a bare name; the designer overrules a row by rewriting its line.
14. **One line to re-read at W9-REVIEW** (critic Spirit): A3's notice "…no Mana on any piece of armour they own" is false for the farming guild in Adventure healer armour; a prophecy is allowed to be wrong later, and the reviewing agent decides whether the joke survives its third reading (edit 183 puts it on the page).
15. **The §7.1 count.** The plan's text says 25 deferrals; its table carries 24 rows; §3 rules the 24. If a 25th was meant (the plan's §7.2 has the "two promises outside the C-table"), those are hidden-copy rows, not deferrals, and W6-COPY/W9-TIERS already own them.

## 9. The critic's amendments, applied

All fourteen applied; none refused.

| Amendment | Applied where |
|---|---|
| A1 the "Lv." branches deleted in W10-DELETE; SHIP #68 amended; `diff_all.sh` re-recorded at the wave-10 close | §2 #21/#68; Q-14, BL-135; edits 196-197, 194 |
| A2 one dressings table; ranks 0-3 W8-FACILITY, 4-5 W9-ART; the Known pennant on a pole | §2 #22/#42; BL-102, BL-106; edits 158-161, 165, 176 |
| A3 on-ramp bands at 45, raid bands at 55; ONE too-easy step on E1-E5 | §2 #9; Q-100; edits 134-135, 167-168 |
| A4 TR's `lesson_report` loses its last sentence | §2 #39; BL-141; edit 109 |
| A5 credits line 4 "Sound and music …" while `MUSIC_BED` is true | §2 #5; BL-132; edits 200-201 |
| A6 the titles re-homed (W7-REPORT / W8-SIM-BALANCE / W8-SCALE-1 / W9-TIERS); W9-POLISH carries none | §2 #25; BL-119; edits 109-110, 135, 154, 157, 168, 181 |
| A7 the fade in W8-KEYS; W10-DELETE's docstring line struck | §2 #33; Q-99; edits 147-150, 198 |
| A8 `Palette.gd` + `test_palette_cvd.gd` to W8-KEYS; the baselines re-recorded inside the jitter | §2 #40; BL-127; edits 133, 148-149, 163 |
| A9 the achievement edits in W7-SAVE (`achievements.json`, `Achievements.gd` added) | §2 #10/#13; Q-69, Q-13; edits 105, 118-119 |
| A10 `active_run.difficulty_mult` / `.ninja_pulled`; the replay passes both back | §2 #6/#49/#58; Q-53, BL-113, BL-116; edits 117, 120 |
| A11 the grace of 5 replaces the plan's SIM-12 line; BL-110 says it is derived under it | §2 #56; BL-110, BL-114; edits 134-135, 140 |
| A12 `tools/playtest.gd` to W8-SIM-BALANCE; the stage predicate local; W8-CRISIS's one handoff line | §2 #1/#60; BL-110, BL-143; edits 132, 135-137, 142-144, 163 |
| A13 W8-AUD-OPT = the quill only; the lute is W10-BUFFER's first item | §2 #46; Q-98; edits 133, 162, 189, 202 |
| A14 BL-110/Q-100 state that A3 is expected under TR on the first pass | Q-100's text; edit 131 |

Also carried from the critic's Spirit and Numbers sections: the dagger notes' sidegrade reading (Q-36; edit 153), README's "measured on the second machine" (BL-104; edit 194), BALANCE #1b's A2 = 4 rolls with the off-hand slot (BL-111), BALANCE #11's "per payday / per tier" wording (Q-31), CONTENT #19's "40 % of the value, rounded to 5" as the PRICE (Q-28/Q-35), and the note that the first sweep lands A1/A2 above band (Q-100). One consolidation-time correction beyond the critic's list: the walk-in's file ownership (§8 item 1), which the critic's A12 touched only for `playtest.gd`.
