# DESIGNER — every decision that blocks shipping, in one sitting

_Ship-plan report, area DESIGNER. Written 2026-09-15 during wave 5 (read-only on the tree)._

## Executive summary

1. **48 findings; 46 are rulings only the designer can make (one is confirm-only, one folds into another), sorted so they can be answered in one sitting with one line each (the answer sheet is "Questions for the designer"). 17 are the audit's `blocked-needs-human` rows, 18 are the art plan's Q01-Q18 (13 already landed behind a switch at a recommended default), the rest are docs/15 rows whose "default" is an instruction ("designer names them") or a BL- still owed.**
2. **Shippable today:** a Tier 1 campaign that is playable end to end but NOT completable (`tools/playtest.gd`: 0 of 8 guilds clear it — morale is pinned at 45 by canon and A1-A3 are a wall there), with a `--dev` export only: `tools/export_build.sh` holds on exactly 16 `name_pending` files (8 generated tier tables, 8 unnamed Legendaries).
3. **Not shippable without a signature:** Tiers 2-5 (twenty tier words — five per tier, not the two docs/09 §11.4 tabulates, plus an optional leather word), the eight Legendary names, and Q-21 (are the ideaboard screenshots the designer's own work — the legal gate on the whole item corpus). Nothing the loop can do invents any of these.
4. **The three biggest gaps:** (i) **M6-BAL-04** — which of four canon numbers moves so a new guild can climb the on-ramp; recommended lever (c), re-size A1-A3 and the tutorials for morale 45 from docs/08 §9; (ii) **the tier words + Legendary names** — the export gate and the whole second half of the game; (iii) **the target clear-rate curve (M6-BAL-03)** — every balance pass after wave 6 tunes to it and it is written nowhere.
5. **Every row has a wave-10 ship default** the loop takes without inventing canon; the risk register (after the urgency matrix) says what that game looks like with zero answers: Tier 1 only, eight Legendaries unfindable, no Blacksmith, no upkeep, no music, credits with one blank line. It ships; it is smaller.
6. **Two things were REFUTED while reading:** `BUILD_STATE.md:101` says Q-29 (recruit gear pricing) is at its recommended default — `Recruitment.cost_of()` has no gear term; and `tier_words.json`'s Tier 1 `raid_adj: "Basic"` would render "Basic Basic Sword" through `gen_items.gd`'s template — a loop fix (S) that must land before the designer fills the column.
7. **The Blacksmith needs a yes/no now** (DESIGNER-10): "Under construction." is the designer's own copy, the hotspot points at a scene that does not exist, the flag is off, and two reputation-rank unlock strings promise the building — the answer sizes an L unit in wave 8 or a copy change in wave 6.
8. **Music has no owner and the shipped Settings screen says so** ("The bus is here and waiting; no music is written yet."); the ambience half is loop work for wave 8; the melodic half is cut / CC0 / composed — the designer's line.
9. **Order of answering:** wave 6 (10 rows: the lever, the names, provenance, credits, Q-53, the two review gates, the curve, the Blacksmith, the shake strike) → wave 7 (19 rows of balance/content that size the art units) → wave 8 (15 switch confirmations, most "as built") → any time (naming leftovers).
10. **Coverage:** every audit blocked row, every spec 00 §2.7 switch, every 00-plan §6 question, every docs/15 instruction-default and owed BL- is cross-checked in the Shippable bar; not verified: the ten non-fixture sheet sets and docs/06/07 in full (cited through the audit).

## Findings

_Reading key: every finding is one designer ruling. **Answer line** is the one line the designer writes back. **Meanwhile** is what the loop does today. **Ship default** is what the loop takes at wave 10 if no answer comes — every row has one, because the user asked for a shippable game by then. Groups: A shipping · B balance · C content · D art · E audio. "Wave" is the wave the ruling must land BEFORE._

---

**A. SHIPPING — rule before wave 6 (the build cannot leave the tree without these)**

### DESIGNER-01 — M6-BAL-04: a new guild is pinned at morale 45 and the Adventure ladder is a wall there — THE decision
**Status:** BLOCKED-designer (CONFIRMED as measured).
**Evidence:** `BUILD_STATE.md:39-45` ("AWAITING A HUMAN DECISION, and it outranks every open build item"); `sim/core/Morale.gd:25` `BASE_BASELINE := 50`, `:30` `RARITY_OFFSET := [-5, -2, 0, 4, 12]` (Common = 45), `:54` `FACILITY_BONUS := [0, 3, 6, 10]`, `:402` `is_recovered()` = at-or-above baseline, so `rest_until_recovered()` never exceeds 45 at facility tier 0; `game/core/GameState.gd:91` `STARTING_GOLD := 60`; docs/11 §8.4 table (`docs/11-economy-and-crafting.md:306-308`) Guildhall L2 = 150 G; `sim/core/Morale.gd:180-186` wipe −8 (cap −16/session) + wipe_caused −4. Audit `M6-BAL-04`: 0/8 guilds clear Tier 1 (six stop at A2, two at A1, all in full T1A gear at morale 45 after 5 attempts); at the rung's own gear stage a Common party clears A1 50% / A2 63% / A3 0% at morale 55 and 0% everywhere at 15.
**Doc:** docs/05 §7.5 and §8 (baseline; drift stops dead at baseline), docs/01 §8.0 (60 G), docs/11 §8.4 (150 G), docs/10 §3 (A1-A3), docs/08 §9 (budget). **No docs/15 row yet** — the audit says "record the ruling in docs/15"; recommended: file the next free BL- with the four levers.
**The exact question:** which canon number moves so a facility-tier-0 Common roster can climb the on-ramp?

| Lever | What changes | Cost |
|---|---|---|
| (a) Raise the Common baseline | `Morale.RARITY_OFFSET[0]` −5 → 0/+5 (docs/05 §7.5/§8; every band reading and the morale-history scale shift) | S code, M docs; changes what "45" means everywhere the player reads morale |
| (b) Make the first facility reachable | `STARTING_GOLD` 60 → ≥150, or Guildhall L2 150 G → ≤60 G (docs/01 §8.0 / docs/11 §8.4); roster starts at 48 (+3) — +3 alone may not clear A3 (0% at 55 for Commons) | S code; re-runs docs/11 §4.3's income curve |
| (c) Size A1-A3 for 45 | `data/encounters_adventure_t1.json` re-derived from docs/08 §9 at morale 45; A3's 0/24 pin (`test_adventures.gd`) moves deliberately | M; admits the on-ramp was costed against a morale the player cannot reach |
| (d) Pay morale for a wipe differently | `Morale.gd:180-186` wipe −8/−16, wipe_caused −4 (docs/05 §7) so retries do not drag the roster to the floor | S code; changes the rhythm of every retry |

**Recommended default:** **(c)** — the only lever that leaves the morale number meaning the same thing to the player, and docs/08 §9 is already the instrument; A3's pinned 0/24 and the Tutorial Raid's 0/20 (DESIGNER-09) are the same pass. Do not split the difference (the audit's own rule).
**Meanwhile:** `tools/verify.sh` stage 6/8 prints the ladder; the playtest is WARN-only; nothing is softened.
**Ship default (wave 10 if unanswered):** (c), sized for 45 at each rung's own gear stage, recorded as a BL- "taken under the wave-10 ship rule", with the playtest promoted from WARN to FAIL so it stays fixed.
**Fix:** re-derive A1-A3 and the Tutorial Raid from docs/08 §9 at morale 45; move the pins in `test_adventures.gd` / `test_tutorials.gd` in the same commit; re-run `tools/playtest.gd` (8 seeds) and `balance_sweep.gd --drift` then `--rebaseline`.
**Owns:** `data/encounters_adventure_t1.json`, `data/encounters_tutorial_t1.json`, `docs/10` §3/§9, `docs/15` (new BL-), `tests/unit/test_adventures.gd`, `tests/unit/test_tutorials.gd`, `tests/baselines/sweep_baseline.csv`, `tests/golden/*`.
**Size:** M (L under lever (a)). **Wave:** 6 — every downstream measurement (Tier 2-5, the curve, the playtest gate) assumes a completable Tier 1.
**Audit:** M6-BAL-04 (closes), M6-BAL-03 (depends), M6-BAL-01/02 (instruments).
**Answer line:** "BAL-04: lever ___ (a/b/c/d), number ___."

### DESIGNER-02 — BL-69 / Q-41 / M5-T25-08: the twenty tier words that mount Tiers 2-5
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `data/tier_words.json` tiers 2-5 `pending: true` (candidates only, nothing reads them); `sim/content/ContentDB.gd:136-160` `tier_is_named()` skips a pending tier, so the campaign ends at Tier 1 and S17 cannot fire in play; `tools/export_build.sh:76-78` PENDING gate holds on `name_pending:true` — `grep -rl` finds exactly 16 files: `data/items_t{2..5}_{adventure,raid}.json` (8) + eight `data/legendaries/*.json` (DESIGNER-03). `tools/gen_items.gd:145` reads FIVE columns per tier — `material, cloth, healer, raid_title, raid_adj` — not the two docs/09 §11.4 tabulates; `:138-139` maps warrior_bard/monk/rogue → material, healer → healer, mage_wizard → cloth. Generated T2 names today: "TIER2 Adventurer's Helm", "TIER2's Boots", "Basic TIER2 Sword", "TIER2 Final Headband", "TIER2 TIER2's Tome".
**Doc:** docs/09 §11.1 template `{QualityWord}? {TierWord} {FamilyWord}? {BaseNoun}`; §11.3 rung formulas; §11.4 the word table; §12.1 IDs are permanent (renaming changes `name`, never `id`) so the words are pure data. docs/15 Q-41 (line 512): "Designer names them"; docs/10 §2: do not invent lore names.
**The exact list to name (one word per cell; Tier 1's canon word is the model):**

| Column (`tier_words.json` key) | Fills | T1 (canon) | Renders at T2 as |
|---|---|---|---|
| `material` | Adventure armour for Warrior/Bard, Monk, Rogue; the Adventure sword and staff; the Adventure charms' fiction | Iron | "___ Adventurer's Cuirass", "___ Adventurer's Sword", "___ Adventure's Charm of Power" |
| `cloth` | Mage/Wizard Adventure armour, Firestaff, Arcstaff | Spellweave | "___ Adventurer's Robe", "___ Firestaff" |
| `healer` | Healer Adventure armour + Healing Focus; the prefix of the raid Tome | Blessed | "___ Adventurer's Circlet", "___ <raid_title>'s Tome" |
| `raid_title` | every raid armour piece (possessive) and the raid charms | Raider | "___'s Greaves", "___'s Charm of Mana" |
| `raid_adj` | the weapon adjective in "Basic ___ Sword" / "Strong ___ Staff" / "Basic ___ Healing Weapon" and the capstone prefix "___ Warrior Shield", "___ Bard Instrument", "___ Final Headband/Eyepatch", "___ Cleric Weapon" | Raid (canon "Basic Raid Sword") — `tier_words.json` T1 holds `"raid_adj": "Basic"`, which would render "Basic Basic Sword" if T1 were generated; harmless today (T1 is read, never generated) but the column's meaning must be fixed BEFORE the designer fills it: **S loop fix, wave 6** | "Basic ___ Sword", "___ Final Headband" |
| (optional) `leather` | the Monk/Rogue line, which at T1 reads "Reinforced Leather Vest", not "Iron Leather Vest" (docs/09 §11.4's wrinkle) | Reinforced | if absent, leather shares `material` from T2 on |

**Grammar (docs/09 §11.1):** one capitalised word per cell; no possessive in the word (the template adds `'s`); `raid_title` must read as a person ("Raider" → "Vanquisher") because it is used possessively; `raid_adj` reads as a rank adjective — the designer may set `raid_adj` = `raid_title` per tier, collapsing the ask to 4 tiers × 4 words = 16 (+4 optional leather).
**Candidates on record (nothing reads them):** material Steel / Mithril / Adamant / Runegold; raid_title Vanquisher / Conqueror / Ascendant / Immortal. None exist for cloth, healer, raid_adj, leather.
**Meanwhile:** tiers 2-5 generated, tested (`tests/unit/test_tier_scaling.gd`), unmounted.
**Ship default (wave 10 if unanswered):** the loop may NOT invent lore names (docs/10 §2, BL-69). The honest default is **Tier 1 only**, S17 firing on the Raid 1 clear — the campaign ends where the named content ends — recorded as a BL- and a README line. This is the row where "no answer" ships a smaller game, never a placeholder one.
**Fix once answered:** fill `data/tier_words.json` (`pending:false`), run `tools/gen_items.gd`; BL-69's rule mounts the tier; then the Tier 2-5 balance pass (DESIGNER-09 half 2).
**Owns:** `data/tier_words.json`, `tools/gen_items.gd` (`raid_adj` semantics), `docs/09` §11.4 (widen to five columns), `docs/15` Q-41 (strike).
**Size:** S for the words; XL for the balance pass they unlock. **Wave:** 6 (words); 7-9 (the pass).
**Audit:** M5-T25-08 (closes), M5-T25-01/05 (unblocks), M6-BAL-03 half 2.
**Answer line:** "T2: material/cloth/healer/raid_title/raid_adj = _/_/_/_/_; T3 …; T4 …; T5 …; leather: shares material | own word ___."

### DESIGNER-03 — The eight Legendary names, and whether "Natsuna" is final
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `data/legendaries/{bard,cleric,druid,mage,monk,rogue,warrior,wizard}.json` `display_name: null, name_pending: true`; `data/legendaries/shaman.json` `display_name: "Natsuna"` with `name_status: "✅ CANON … canon hedges even this: 'IE Natsuna(the shaman) or something.'"`; `tools/export_build.sh:78` holds the release on `name_pending:true`; docs/03 §5.6 (`docs/03-guild-reputation.md:260-272`): "The other 8 Legendary names ❓ OPEN — Do not invent names" and "Whether 'Natsuna' itself is final ❓ OPEN". Everything else on the nine files is authored (portraits pending art; quirk inert — DESIGNER-14; backstory bullets; barks).
**Doc:** docs/03 §5.6, docs/04 §11.1-11.2. No Q- row of its own — recommended: a BL- listing the nine slots.
**The exact list:** Warrior · Cleric · Druid · Mage · Wizard · Rogue · Monk · Bard — one given name each (docs/04 §7's rule: given names only, no surnames, no public figures, nobody on the team) — plus yes/no on **Natsuna (Shaman)**. Each file's `backstory[].text` and `dialogue_barks` already draw a character the name should fit (warrior: "Has died more times than he can count and finds that funny" / "Takes the worst raider aside after every wipe").
**Meanwhile:** the loader renders "Legendary (Warrior) — name pending"; the Tavern can roll one at Renowned.
**Ship default (wave 10 if unanswered):** none is inventable. Fallback that ships: `name_pending` Legendaries become **unfindable** (one guard in `sim/core/Recruitment.gd`), the 9-of-9 meter reads N-of-named, and the eight files move to `data/legendaries/_pending/` which `ContentDB` does not mount, so the export gate clears honestly. Natsuna ships. Recorded as a BL-.
**Owns:** `data/legendaries/*.json` (eight `display_name`s), `docs/03` §5.6 (strike two rows). **Size:** S. **Wave:** 6.
**Audit:** M5-END-3 (the meter), M5-END-4 (same signature), Q58-* (the quirks are a separate ruling).
**Answer line:** "Warrior ___, Cleric ___, Druid ___, Mage ___, Wizard ___, Rogue ___, Monk ___, Bard ___; Natsuna final: yes/no."

### DESIGNER-04 — Q-21: are the nine ideaboard screenshots original work? (the legal gate on the whole item corpus)
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** docs/15 Q-21 (`docs/15-open-questions.md:470-478`): "Blocks: shipping the entire Tier 1 item corpus … a thirty-second answer with an unbounded downside"; `data/credits.json` `_source` names it as the same signature as the credits; docs/00 §4.4 is where the confirmation goes.
**Doc:** docs/15 Q-21; recommended default on record: "designer confirms authorship in writing".
**Meanwhile:** assumed original; no release export has been cut.
**Ship default (wave 10):** the loop cannot assert provenance. Fallback: the release export prints the Q-21 line in its log and the README's status carries "item corpus provenance unconfirmed" — it ships to the designer's own machine only. **The one row with no autonomous fallback that reaches a store.**
**Owns:** `docs/00` §4.4 (one sentence), `docs/15` Q-21 (strike). **Size:** S. **Wave:** 6. **Audit:** M5-END-4.
**Answer line:** "Q-21: the nine ideaboard screenshots are my own work — yes / no."

### DESIGNER-05 — M5-END-4: who the game credits, and the third-party attribution block
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `data/credits.json` `lines: []`, `status: "The credits are not written yet…"`, printed verbatim by `game/screens/Completion.gd`; no CREDITS / LICENSE / THIRD_PARTY in the root; bundled fonts (Fira Sans as the body face per 00-plan §6 Q16), the Aseprite pipeline and any CC0 audio each carry terms.
**Doc:** docs/10 §13 row 1; docs/16 §8.2 has no credits row. No Q- row (audit only).
**The exact ask:** (1) the roll — names and roles, lead designer at minimum; (2) whether the roll names the tooling; (3) approval of a drafted attribution block (the loop can list every font file under `game/assets/fonts/` with its licence text — S, wave 6 — it cannot decide who is credited).
**Meanwhile:** S17 prints the status line.
**Ship default (wave 10):** the loop drafts `lines` with only what is derivable — the font licences, "Made with Godot Engine" (MIT) — and one literal "[designer credit pending]" line. No attribution is omitted; the designer's own name is the only blank.
**Owns:** `data/credits.json`, `docs/16` §8.2 (checklist row). **Size:** S. **Wave:** 6 (draft), 10 (final). **Audit:** M5-END-4 (closes).
**Answer line:** "Credits: [name] — [role]; …; attribution block: approved."

### DESIGNER-06 — Q-53: are attempts limited, and can the player quit mid-sim?
**Status:** CONFIRMED implemented at the recommended default; needs the signature and one doc propagation.
**Evidence:** `game/screens/RaidView.gd:386-388` "The attempt being read has ALREADY been recorded by the time this screen opens" — the sim resolves in full and `GameState.record_attempt` (`GameState.gd:945`) + `autosave()` land before playback, so leaving mid-account cannot discard or reroll; `RaidView.EXITS_GATED := false` (`:292`); attempts are unlimited — `Reputation.STALL_ATTEMPTS` (`sim/core/Reputation.gd:657`) drives the stall hint, not a cap. BUILD_STATE HANDOFF names Q-53 as what `export_build.sh` "waits on".
**Doc:** docs/15 Q-53 (line 529) default "Unlimited attempts with a per-attempt economic cost; resume from the stored seed and round index" — the tree implements the stronger reading (the attempt is committed before the first line plays), which closes alt-F4 outright. docs/01 OQ-6 still says "quitting discards it" — propagation owed.
**Meanwhile / Ship default:** as built. No change at wave 10.
**Fix:** strike Q-53 with a pointer to `RaidView.gd:386`; amend docs/01 OQ-6 and docs/07 OQ-5/6. No code.
**Owns:** `docs/15`, `docs/01`, `docs/07`. **Size:** S. **Wave:** 6. **Audit:** M6-EXP-* (the gate's stated wait).
**Answer line:** "Q-53: confirm as built."

### DESIGNER-07 — Q-29: does a recruit's rolled gear price the recruit?
**Status:** CONFIRMED open; the register's default is NOT implemented — **REFUTES** `BUILD_STATE.md:101`'s "Q-29 … at their recommended defaults".
**Evidence:** `grep -rn "well.equipped\|Q-29" sim/ game/ tests/` → no hits; `sim/core/Recruitment.gd:58,205` `cost_of(rarity, content_tier)` = `base(rarity) × (1 + 0.6 × (CT − 1))` — rarity and tier only, no gear term — so the tree ships the "Don't" option (board-reroll grinding possible; the paid reroll is the only brake). Also stale: audit `M6-BAL-03`'s remaining_work cites "Q-29 … the one balance value changed on judgement alone (BUILD_STATE.md:47)" — BUILD_STATE:104 now correctly says **BL-29** (raid-wide magnitude); the audit text should follow.
**Doc:** docs/15 Q-29 (line 495): "+15% cost per raid-tier piece beyond the first, surfaced as a 'well-equipped' label".
**Ship default (wave 10):** implement the register's default behind `Recruitment.GEAR_SURCHARGE_BP := 1500` (0 = today), default ON, "well-equipped" label on the card; both branches tested.
**Owns:** `sim/core/Recruitment.gd`, `game/screens/Tavern.gd`, `game/ui/Cards.gd`, `tests/unit/test_recruitment.gd`, `docs/04` §6/Q7, `BUILD_STATE.md:101` (say "Q-29 unimplemented"), `build/plan/audit.json` M6-BAL-03 (the prefix). **Size:** S. **Wave:** 7 (after BAL-04 — it moves the Tier 1 gold curve). **Audit:** M6-EXP-*.
**Answer line:** "Q-29: +15%/piece | no surcharge | other ___."

### DESIGNER-08 — The two human content-review gates: BL-53 (name pool) and M5-COMEDY-12 (228 mistake lines)
**Status:** BLOCKED-designer (CONFIRMED) — the only two gates a build loop cannot close by being careful.
**Evidence:** docs/15 BL-53 (`:1523-1556`) "ONE NAMED REVIEWER passes the mundane pool" — `data/names.json` (given names from docs/04 §7.1's own table + 20 epithets; the `underscore_digit` handle shape from `sim/content/NamePool.gd:189-190`, e.g. "Pauline_4"); audit M5-COMEDY-12: 192 type lines + 36 legendary lines in `data/mistake_lines.json` / `data/legendaries/*.json` against docs/07 §10.3's five rules (rule 5 never blame the player, rule 2 the raider has a reason), plus one 1x read of `e5_miserable_commons` (64 mistakes over 16 rounds).
**Doc:** docs/04 §7; docs/07 §10.3; docs/16 R-3.
**Meanwhile:** validators pass (BL-80 budgets); the backlog's "genuinely funny" is not ticked.
**Ship default (wave 10):** ship as validated with a BL- stating the human gate was not passed — every checkable rule is machine-checked; the risk is accepted in writing.
**The exact ask:** a keep/rewrite/cut pass — the loop can produce `build/plan/ship/comedy-review.md` (all 228 lines + the name pool on one page with a tick column; S, wave 6) so the review is a 20-minute read.
**Owns:** `data/mistake_lines.json`, `data/legendaries/*.json` (barks), `data/names.json`, `docs/15` (BL-53 strike + new BL- for the comedy gate), `BACKLOG.md`. **Size:** S (sheet); designer-time M. **Wave:** 6 (sheet), 9 (rewrites). **Audit:** M5-COMEDY-12, BL-53.
**Answer line:** "Names: signed. Comedy: signed / rewrite ___ / cut ___."

### DESIGNER-09 — M6-BAL-03: the target clear-rate curve nobody has written, and the two pinned walls (A3 0/24, Tutorial Raid 0/20)
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** audit M6-BAL-03: `grep -rn 'clear rate' docs/*.md` → four hits, none a curve; `tools/balance_sweep.gd:31-33` bounds "deliberately loose"; BUILD_STATE HANDOFF pins A3 at 0.0 (`test_adventures.gd`: no mechanics 24/24, m01 only 0/24, m02 only 3/24, m03 only 9/24) and the Tutorial Raid at 0/20 (`test_tutorials.gd`: as authored 0/20, without m01 13/20, swing 15→10 10/20); both trace to canon pricing a boss swing against the autoattack and then adding M01 (×2.5). Canon fixes target ROUNDS per boss (docs/08 §9.2) and a 1-5 star ramp (docs/01:90-93), never a clear rate.
**Doc:** docs/08 §9.2, docs/03 §6.4 (19-row pacing table, reproduced by `sim/core/Reputation.gd`), docs/16 W3.11. No Q- row — the audit asks for one.
**The exact question:** one first-clear rate per encounter at the gear stage it is fought in (A1, A2, A3, TR, E1-E5) with a tolerance band. The loop can PROPOSE a derivation (docs/15 Q-90's "3-5 attempts across 2-3 town cycles for a first Raid 1 clear" → ~25-35% per attempt at E5 in E4's gear; Adventures ~50-65%; tutorials ~70%+).
**Meanwhile:** WARN-only playtest; both pins hold.
**Ship default (wave 10):** the loop's proposed curve, 🔷 "taken under the wave-10 ship rule", Tier 1 tuned with DESIGNER-01, Tiers 2-5 only if DESIGNER-02 lands; the two pins move in the ruling's commit.
**Owns:** `docs/15` (new Q- with the curve), `docs/08` §9.2, `tools/balance_sweep.gd` (bounds → the curve), `data/encounters_*.json`, the two pin tests, goldens, baseline. **Size:** M (Tier 1) / XL (all tiers). **Wave:** 6 (curve signed) → 7 (Tier 1) → 8-9 (Tiers 2-5). **Audit:** M6-BAL-03, M6-BAL-04, M5-TUT-*.
**Answer line:** "Curve: A1 __ A2 __ A3 __ TR __ E1-E5 __ (±__); or 'take the proposed'."

---

**B. BALANCE AND SYSTEMS — rule before wave 7 (each changes a shipped number or turns a flagged system on)**

### DESIGNER-10 — Q-13: is the Blacksmith in 1.0? ("Under construction." was the designer's own edit)
**Status:** BLOCKED-designer (CONFIRMED) — the tree carries BOTH readings and neither is finished.
**Evidence:** `game/screens/Town.gd:109-111` hotspot `"blacksmith"`, blurb `"Under construction."` (designer edit, commit `cfd2c29`), `scene: "res://game/screens/Blacksmith.tscn"` — **that scene does not exist** (`ls game/screens/` has no Blacksmith.*); `flag: "blacksmith"` and `GameState.FLAG_DEFAULTS.blacksmith = false` (`GameState.gd:217`); `Town.gd:567` lock reason "Canon lists this one as a maybe. Disabled in this build." pinned by `tests/unit/test_screens.gd:290-311`; `sim/core/Buildings.gd:48-56` prices a blacksmith ladder behind the flag; `data/reputation.json:48,61` town_unlock strings "Blacksmith opens" (Respected) and "Blacksmith tier 2" (Renowned) — a rank-up promises a building the build cannot open. Spec 00 §2.6/§4: not a rail item; "a Blacksmith rail item once built — behind GameSettings when it comes up".
**Doc:** docs/15 Q-13 (`:329-346`) recommended default "Blacksmith yes at upgrades-only scope; crafting no; salvage as a gold-only stub" — five rows, one signature. Canon: "Blacksmith (Maybe)" vs the core verb "You spend money at the blacksmith/Merchant".
**The exact question:** "Under construction." reads as a promise. Is the building (a) in 1.0 — upgrades-only screen (+1..+3 per building level, docs/02 §8 M1-M5; 1.5 EW + 1.0 AU by the register's own costing = an L unit) — or (b) out of 1.0, in which case the callout copy becomes a cut ("Boarded up." / stays a locked facade), the two `reputation.json` unlock strings change, and `Buildings.gd`'s ladder stays dormant?
**Recommended default:** (b) for 1.0 — the register's own cut-consequence column says the only loss is "gold has nothing to do between tiers", and DESIGNER-11 (upkeep) is a cheaper sink that canon already names. Keep the facade and the flag.
**Meanwhile:** locked facade, flag off, copy "Under construction."
**Ship default (wave 10):** (b) — the copy changes to something that is not a promise ("Closed. The smith took a better offer." or the designer's line), the two unlock strings drop the Blacksmith, the flag stays declared. If (a): one L unit owning `game/screens/Blacksmith.gd/.tscn`, `sim/core/Upgrades.gd`, `data/upgrades.json`, `docs/02` §8, `docs/11` §9, plus Q13's callout copy.
**Owns:** `game/screens/Town.gd:110`, `data/reputation.json` (two strings), `docs/15` Q-13 (strike), `docs/02` §8, `tests/unit/test_screens.gd:290-311` (the "maybe" pin stays either way).
**Size:** S for (b); L for (a). **Wave:** 6 to rule (it sizes wave 7-8); (a)'s unit in 8. **Audit:** none open on it directly; 00-plan Q13; spec 00 §4.
**Answer line:** "Q-13: Blacksmith in 1.0 yes (upgrades-only) / no; callout copy: ___."

### DESIGNER-11 — Q59-5 / Q-31: upkeep and payday — the game's only recurring gold sink is unspecified (cadence fork)
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `grep -rn 'upkeep\|payday' game sim` → `GameState.gd:1835,1872-1873` only (BIG-dumb row 5 `unpaid_2_paydays`, `live: false`); docs/11 §4.2's sink table S1-S14 has no wages row; docs/15 Q-31 (line 497) "Small per-run upkeep scaling with rarity, charged on benched raiders too. Magnitudes owned by doc 11" vs docs/04 §11.3 condition 5 / §12.2 "payday" (per-run has no cadence, so "2 consecutive paydays" is unexpressible). Two Q-31 anchors collide (`docs/15:454` vs the BL-31 duplicate-protection entry) — W5-DOCS is repairing dead anchors this wave; verify after.
**Doc:** docs/11 §4.2-4.4 (which do not cover it), docs/04 §11.3/§12.2/Q8, docs/15 Q-31, BL-59 row 5.
**The exact question:** (1) cadence — per run, or a payday every N Day Ticks (give N); (2) Tier-1 magnitudes per rarity (docs/11 §4.2 gains S15) and whether the bench pays; (3) whether it ships in 1.0 at all — the roster cap of 15 is docs/04 §12.1's stated reason for wanting it.
**Cost:** per-run: S code, M re-tune of docs/11 §4.3's curve (a recurring sink across 12-15 raiders is large next to ~100 G per Raid 1 clear); payday: same + a Day-Tick counter and a save bump.
**Recommended default:** **not in 1.0** — Q-59 already records condition 5 as false; the economy is a closed circuit today (DESIGNER-01) and a new sink would tighten it further before the on-ramp is fixed.
**Meanwhile / Ship default (wave 10):** condition 5 stays false; no upkeep. Recorded in the BL-59 correction W5-DOCS is landing.
**Owns (if yes):** `docs/11` §4.2 (S15), `docs/15` Q-31 (fix the collision), `docs/04` §11.3, `sim/core/Economy.gd`, `game/core/GameState.gd` (`_resolve_payday`, SAVE_VERSION bump), `tests/unit/test_economy.gd`, `test_legendaries.gd`. **Size:** L. **Wave:** 7 to rule; 8 to build if yes. **Audit:** Q59-5 (closes), BL-59.
**Answer line:** "Upkeep: not in 1.0 | per-run at __/__/__/__/__ G by rarity | payday every __ ticks at __."

### DESIGNER-12 — M5-END-5: the Legendary 5% find rate lands on a rank with nothing left to serve — retime or accept the collection endgame
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `data/reputation.json` Renowned `find_weights [0,0,800,185,15]` (1.5% Legendary), Legendary rank `[0,0,0,950,50]` (5%) with `_doc` "🔷 ENTIRELY PROPOSED"; `sim/core/Reputation.gd:24` `THRESHOLDS [0,120,400,900,1800,3200]` — Legendary rank lands exactly on the Raid 5 full clear (docs/03 §6.4, proven by the pacing test); docs/10 §13 row 3 "Unresolved, deliberately". docs/15 Q-23 settled the RANK as prestige, not the rate. Pity: `Recruitment.gd:52-55, 109-127` reads `pity_threshold`/`pity_min_rank` from the same file.
**Doc:** docs/03 §5.2/§5.4/§6.4; docs/10 §13 row 3, §14 Q1; docs/15 Q-23, Q-24.
**The exact question:** (a) RETIME — 5% (and/or the 3200 threshold) earlier so the reward has content to spend on; edits docs/03 §5.4 and §6.4 together and re-runs the pacing test; or (b) ACCEPT — the collection metagame (9-of-9) IS the endgame; docs/03 §5.4 gains one sentence.
**Recommended default:** (b). It changes no number, docs/15 Q-88 already says "Legendary collection to 9-of-9 … No Tier 6 in 1.0", and (a) re-tunes the whole ladder.
**Meanwhile / Ship default (wave 10):** (b), recorded as a BL-.
**Owns:** `docs/03` §5.4 (one sentence), `docs/10` §13, `docs/15` (BL-). **Size:** S. **Wave:** 7. **Audit:** M5-END-5 (closes), M5-END-3.
**Answer line:** "END-5: accept | retime 5% to rank ___ / threshold ___."

### DESIGNER-13 — M5-QAB-4 / Q-69: does the achievement board pay reputation? (doc 03 never accepted the faucet)
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `sim/core/Achievements.gd:777` `why = "the achievement_rp switch is off (docs/15 Q-69 is still open)"` — the reward kind is built and gated; docs/03 §6.1's award table (`docs/03:279-308`) has no board row and §6 opens "❓ OPEN … Everything in §6 is 🔷 PROPOSED"; docs/15 Q-69 (line 550) "Board yes, capped at ~15%".
**Doc:** docs/02 §4.4; docs/11 §11.2; docs/03 §6; docs/15 Q-69.
**The exact question:** add a board-award row to docs/03 §6.1 (an RP number per record and the ~15%-of-RP-earned cap), or say no (board is coin and goods only).
**Cost:** yes = S (one row + flip the switch + the ≤15% test); no = S (the switch stays off, docs/15 struck).
**Recommended default:** no for 1.0 — the ladder is already tuned row by row to the Raid 5 clear (DESIGNER-12) and a second faucet moves every threshold's arrival.
**Meanwhile / Ship default:** switch off, coin-equivalent fallback; recorded.
**Owns:** `docs/03` §6.1, `docs/15` Q-69, `sim/core/Achievements.gd` (flip), `tests/unit/test_achievements.gd`. **Size:** S. **Wave:** 7. **Audit:** M5-QAB-4 (closes).
**Answer line:** "Q-69: board RP no | yes at ___ RP per record, cap 15%."

### DESIGNER-14 — Q58-1 / Q58-3 / BL-58: the nine Legendary quirks have names and no spec; five name mechanics the sim does not have
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `grep -ci quirk docs/07-combat-simulation.md` → 0; `data/legendaries/*.json` `quirk.status "❓ OPEN … Inert until it does"`; `GameState.FLAG_DEFAULTS.legendary_quirks = false` (`:222`); `sim/core/Quirks.gd` exists (the seam, Q58-4). Audit Q58-3's substrate audit: HAS substrate — warrior (`RaidSim._assign_tanks` + MIS_AGGRO/MIS_TAUNT_LAPSE), rogue (`Formulas.threat_from`), monk (`Mistakes.roll` `relief_bp`); NO substrate — shaman (no buff durations), bard (no kit; docs/06 §5 B1/B2/B3 unchosen; docs/07 OQ-10 "not shippable until the class doc lands"), cleric (mana is a magnitude, Q-02 Model A+), mage (no in-encounter recovery event), wizard (no pre-enrage decision), druid (role fixed by class).
**Doc:** docs/04 §11.2 (the contract), docs/07 (absent), docs/06 §5 (Bard), docs/15 BL-58 (OPEN), Q-46.
**The exact question, per quirk:** trigger (round/phase, roll site, mechanic id or mistake type), magnitude (bp or coefficient), always-on or once-per-encounter, and what it must not do (a budget band on the benchmark twelve's wipe rate). For the five without substrate: restate against a mechanic that exists (audit Q58-3's proposals: shaman = chain heal's third bounce never fizzles — docs/04:397's Natsuna example ALREADY says exactly this and the data file disagrees with it; cleric = immune to MIS_HEAL_CORPSE; mage = +X% spell damage while an ally is downed; wizard = +X% from the enrage round; druid = valid main-tank fallback) or build the subsystem (an order of magnitude more).
**Recommended default:** ship 1.0 with the quirks **inert and displayed** ("reads as" line on the card, flag off) — BL-58's own ruling — and rule the eight restated shapes for a 1.1; bard deferred outright (docs/06 §5 first).
**Meanwhile / Ship default (wave 10):** inert, displayed, flag off. No invented combat effects.
**Owns (if specced):** `docs/07` §12 (new), `docs/06` §5, `docs/15` BL-58, `sim/core/Quirks.gd`, `sim/core/RaidSim.gd` (the seam), nine data files, `tests/golden/e5_legendaries_raid.json`, sweep baseline. **Size:** L (spec) + M (code). **Wave:** 7 to rule; 9 to build if in 1.0. **Audit:** Q58-1, Q58-3 (close), Q58-2/4.
**Answer line:** "Quirks: inert in 1.0 | spec the eight per Q58-3's restatements (yes/edit) | bard: deferred."

### DESIGNER-15 — BL-42: two docs cap the roster by two different things
**Status:** CONFIRMED open (docs/15 BL-42 "OPEN — needs one ruling").
**Evidence:** `game/core/GameState.gd:98` `ROSTER_CAP_BY_RANK := [15,16,17,18,19,20]` (docs/04 §12.1, by rank) vs docs/02 §4.3's 14/18/22/26 by Guildhall level (not in code — `grep roster_cap sim/core/Buildings.gd` → nothing).
**Doc:** docs/04 §12.1 vs docs/02 §4.3; docs/15 Q-12 (default: rank-driven 15→20) and BL-42 (recommendation: min of both).
**Recommended default:** as built (rank) — Q-12's own default; strike BL-42 with "04 wins, 02 §4.3's column deleted".
**Meanwhile / Ship default:** rank. **Owns:** `docs/02` §4.3, `docs/15` Q-12/BL-42. **Size:** S. **Wave:** 7. **Audit:** none.
**Answer line:** "Roster cap: rank (as built) | min(rank, hall) | hall."

### DESIGNER-16 — BL-22: rarity vs morale dominance — leaning "accept", held open for a Tier 2 re-measure
**Status:** CONFIRMED open by design (docs/15 BL-22 "OPEN — design", re-measured "LEANING option 3, accept").
**Evidence:** `docs/15:2204-2275`; the sweep prints `LEVER BALANCE` every run; at E2/Adventure morale moves clear rate 0→100%, rarity 75→100% — canon's intended order. Audit M6-BAL-03 says Q-22/BL-22 "must not be closed by a Tier 1 pass".
**The exact question:** confirm "accept" now (morale = short-term lever, rarity = long-term axis) so the Tier 2-5 pass has a target, or hold for the Tier 2 measurement.
**Recommended default:** accept now; the Tier 2 re-measure is a test, not a ruling.
**Ship default:** accept, recorded. **Owns:** `docs/15` BL-22, `docs/05`/`docs/03` one line each. **Size:** S. **Wave:** 8 (with the Tier 2 pass). **Audit:** M6-BAL-03.
**Answer line:** "BL-22: accept."

### DESIGNER-17 — Q-36: the Rogue's first raid drop is a downgrade (Basic Raid Dagger +4 vs the +5 Adventure sword)
**Status:** CONFIRMED open ("Designer's call, not ours").
**Evidence:** docs/15 Q-36 (line 507); `sim/core/Formulas.gd:241` `MELEE_SWINGS := 2` for all melee (Q-59's default — no per-class swings); `tools/gen_items.gd` propagates the −2 to every tier ("keeps canon's −2 against the sword at every rung (docs/09 OQ-15: do not silently fix it)"), so the downgrade recurs at each Boss 1 for Tiers 2-5.
**Doc:** docs/09 OQ-15, docs/08 Q10, docs/11 Q6.
**Options:** leave canon (a visible "bug" at the first loot moment, ×5 tiers) · raise to +5/+7 (a canon number moves) · extra swings for the Rogue (`Formulas.gd` per-class swing count; canon numbers untouched — the register's recommendation).
**Recommended default:** extra swings (Rogue `MELEE_SWINGS` 3) behind a per-class table, default ON.
**Ship default (wave 10):** extra swings, recorded as a BL-; goldens regenerated.
**Owns:** `sim/core/Formulas.gd`, `docs/08` §7, `docs/09` OQ-15, `tests/unit/test_formulas.gd`, goldens/baseline. **Size:** S. **Wave:** 7 (before the Tier 1 balance pass). **Audit:** none.
**Answer line:** "Q-36: extra swings | raise dagger to +5/+7 | leave."

### DESIGNER-18 — Q-33: two naming calls inside the item corpus (Raider's Boots ×2; the healer Worn Leggings)
**Status:** CONFIRMED open (the IDs are done; the two display-name calls are not).
**Evidence:** docs/15 Q-33 (line 504) "Two decisions still needed from you"; docs/09 §12.1 worked keys already give `ITM_T1_RAID_WARBARD_FEET` and `ITM_T1_RAID_MONKROGUE_FEET` both named "Raider's Boots" — two items, one string; healer "Worn Leggings" at 1 AC shares its name with the 2 AC Warrior/Bard piece.
**Recommended default (register's):** two family-qualified items (as built); the healer's 1-AC Worn Leggings gets its own name — **the designer must supply the word** (canon rule 1 forbids the loop renaming a canon item). Fallback that ships: keep the canon strings and disambiguate in the UI by family tag ("Worn Leggings · Healer"), which is display, not a rename.
**Owns:** `data/items_starting.json` (one `name`), `docs/09` §9.1. **Size:** S. **Wave:** 7. **Audit:** none.
**Answer line:** "Q-33: healer Worn Leggings → '___' | keep, tag by family."

### DESIGNER-19 — Q-35: Adventure-tier off-hands and starting weapons — recorded as the build's proposed default by W5-DOCS, content not yet authored
**Status:** CONFIRMED proposed, unsigned; the content half is audit M5-T25-14.
**Evidence:** docs/15 Q-35 (line 506, rewritten this wave): "Add both — recorded as the build's default in 09 §10.2 (the three off-hand blocks, the four starting weapons) and 09 §13.1 (the 27-per-rung template), 🔷 PROPOSED and unsigned … today's data files carry 28 Adventure rows with no off-hand, which is why §13.1 says 27 and the tests say 28"; `tools/gen_items.gd` T2 adventure = 28 rows, none `off_hand`.
**Doc:** docs/09 OQ-7, §10.2, §13.1.
**The exact question:** sign "Add both" — three T1 Adventure off-hand rows (Shield / Instrument / Tome at Adventure stats, docs/09 §10.2's blocks) and the four per-class starter weapons (Q-28) — or leave the off-hand empty until the Tier 1 raid.
**Recommended default:** sign; then the generator template gains the three rows per tier.
**Ship default (wave 10):** as proposed (add both), goldens/sweep re-baselined, the 27/28 discrepancy resolved in §13.1.
**Owns:** `data/items_t1_adventure.json`, `data/items_starting.json`, `tools/gen_items.gd`, `docs/09` §10.2/§13.1, `tests/unit/test_items*.gd`. **Size:** M. **Wave:** 7. **Audit:** M5-T25-14 (closes).
**Answer line:** "Q-35: add both (sign) | off-hands only | neither."

### DESIGNER-20 — Q-22 / C-05: what the Established rank does (the largest hole in docs/03) — a ruling the six town states also wait on
**Status:** CONFIRMED proposed, unsigned.
**Evidence:** `data/reputation.json` Established row `_doc: "🔷 ENTIRELY PROPOSED … 'THE LARGEST HOLE IN THIS DOC'"`, `find_weights [0,350,650,0,0]` (Rare modal), `town_unlock "Guildhall facility upgrade II; Blacksmith tier 2"`; docs/15 Q-22 (line 488) default "Both (a) and (b): Rare modal AND Market L4 + Blacksmith L2"; audit M3-LOOP-06 step (1) needs this signed before two of the six town states have content to draw.
**Doc:** docs/03 §5.4, docs/02 §12 Q2, docs/15 Q-22.
**Recommended default:** (b) recruit-rank only (Rare modal, as built), because (a)'s Blacksmith half depends on DESIGNER-10 — if the Blacksmith is out, Established's town content is "Guildhall facility upgrade II" alone, and that is what the tree already shows.
**Ship default:** as built. **Owns:** `docs/03` §5.4 (sign), `data/reputation.json` (the unlock string), `docs/15` Q-22. **Size:** S. **Wave:** 7. **Audit:** M3-LOOP-06 (step 1).
**Answer line:** "Q-22: (b) as built | (a)+(b) with Market L4 (+Blacksmith L2 if DESIGNER-10 = yes)."

### DESIGNER-21 — Q-14 / reference conflict: raider levels — none in canon, `Lv. N` on four fixture cards, `Raider.level` display-only
**Status:** CONFIRMED ruled by the loop (display-only, shown only when `level > 0`); the yes/no on level-ups is still the designer's.
**Evidence:** spec 00 §2.3 "there are no raider levels in canon's recruitment model, only rarity. `Raider.level` exists (display-only); the card shows `Lv. N` only when `level > 0`"; `game/ui/Cards.gd:144` `"Lv. %d"`; `tools/fixture_reference.gd:27-32` gives Bork/Tiny/Gruk/Spoof levels 12/11/9/10 for the reference diff; `GameState.FLAG_DEFAULTS.level_ups = false`; no Drilling in the tree (`grep -rln drill sim/ game/` → nothing) although docs/15 Q-14's default is "no level-ups; ship Drilling".
**Doc:** docs/15 Q-14; docs/02 §8.1 (Drilling); 00-plan Q11.
**The exact question:** (1) no level-ups in 1.0 — confirm; (2) does Drilling (0.75 EW, −2 pp mistake chance, hard-capped) ship in 1.0, or is "Train raiders" cut with the level-ups; (3) does the `Lv.` label ever show in the shipped game (it cannot — no path sets `level > 0` outside the fixture) — retire it from the card or keep the dormant branch?
**Recommended default:** no level-ups; **no Drilling in 1.0** (the sweep says morale is the dominant lever already; Drilling adds a third mistake-chance input to tune); `Lv.` stays dormant (zero cost, spec 00's own ruling).
**Ship default:** as recommended. **Owns:** `docs/15` Q-14 (strike), `docs/02` §8.1 (mark Drilling post-1.0). **Size:** S. **Wave:** 7. **Audit:** none open.
**Answer line:** "Q-14: no level-ups; Drilling in 1.0 yes/no; Lv. label: dormant/retire."

---

**C. CONTENT AND WORLD — rule before wave 7 (they size art units in waves 8-9)**

### DESIGNER-22 — M3-LOOP-06: the six town rank-states docs/02 §9.1 asks for (one camp plate exists)
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `game/assets/scenes/stage_camp.json` is the one town plate (cut from the designer's reference concept); docs/02 §9.1 specifies six states (Unknown "Guildhall boarded … 3 idle townsfolk" → Legendary "Statue of the guild … 26 townsfolk … stained glass and a tower") and §2.1 R5 makes them acceptance criteria; the memory rule (2026-09-10) says the reference concepts set the bar — five more plates at that bar, not generated approximations. W4-LIFE landed additive life on the one plate (walkers, sails, gulls, lanterns), which is M3-LOOP-05's mechanism for props-per-rank.
**Doc:** docs/02 §9.1, §12 Q2; docs/03 §5.4; docs/15 Q-22 (DESIGNER-20).
**The exact question:** (1) six plates, or three visible states (Unknown / Respected / Renowned) with the other ranks as additive prop layers on the nearest plate; (2) who paints them — the designer supplies/commissions at the reference bar, or the loop composes prop layers from the existing sheets (the only thing it can do at that bar).
**Cost:** six plates = XL and not the loop's to draw; three states + props = L (the prop layers are `stage_camp.json` entries, no new plate).
**Recommended default:** ONE plate + additive prop layers per rank (M3-LOOP-05's gates are data): Unknown = fewer walkers, a boarded Guildhall tent; Known/Respected = the shipped scene; Renowned/Legendary = more walkers, banners, a statue prop if a sheet has one. docs/02 §9.1 is amended to "one plate, six dressings".
**Meanwhile:** one plate, life on; docs/02 §2.1 R5 unmet.
**Ship default (wave 10):** the recommended default; docs/02 §9.1 amended 🔷 and R5 restated as "the town visibly changes at every rank" (props count).
**Owns:** `game/assets/scenes/stage_camp.json` (per-rank prop gates), `game/screens/Town.gd` (rank read), `docs/02` §9.1, `docs/15` (BL-), `tests/unit/test_town.gd`. **Size:** L. **Wave:** 7 to rule, 8-9 to dress. **Audit:** M3-LOOP-06 (closes), M3-LOOP-05.
**Answer line:** "Town states: 1 plate + rank dressings | 3 plates (I supply) | 6 plates (I supply)."

### DESIGNER-23 — M4B-CONV-04 / Q-96: which arena each encounter is fought in (the dungeon plate is authored and unrouted)
**Status:** BLOCKED-designer (CONFIRMED; the question is in the register as Q-96, with a proposal).
**Evidence:** `game/ui/SceneStage.gd:140` `DEFAULT_ARENA := "stage_arena_cave"` read by RaidPrep, RaidView and Results; `game/assets/scenes/stage_arena_dungeon.json` exists with marks (`:354,364`) and nothing routes to it; `sim/model/Encounter.gd` has no `backdrop` field; docs/15 Q-96 (line 586) proposes a per-encounter `backdrop` key defaulting to the cave.
**Doc:** art/ref/specs/09-background-plates.md §2; docs/10 §8; docs/15 Q-96.
**The exact question:** does the backdrop belong to the ENCOUNTER (this boss lives in a dungeon) or to the RAID (one location, five fights; Adventures another)? And, for Tier 1: which of A0/TR/A1-A3/E1-E5 fight in the dungeon?
**Recommended default:** per RAID — Adventures (A0-A3) + TR in the cave, Raid 1 (E1-E5) in the dungeon; Tiers 2-5 alternate cave/dungeon per docs/15 Q-54's "alternate as listed". It is a data key with a validator; nothing else moves.
**Meanwhile:** one constant, honestly one constant.
**Ship default (wave 10):** the recommended mapping as `backdrop` on each encounter record, 🔷, validated.
**Owns:** `data/encounters_*.json` (the key), `sim/model/Encounter.gd`, `game/screens/RaidPrep.gd`, `RaidView.gd`, `Results.gd` (read it off the encounter), `tools/validate_content*.gd`, `docs/15` Q-96 (strike). **Size:** S. **Wave:** 7. **Audit:** M4B-CONV-04 (closes), 00-plan Q18 (routing half), STAGE-06.
**Answer line:** "Q-96: per raid — Adventures cave / Raid 1 dungeon (yes/edit) | per encounter: ___."

### DESIGNER-24 — M4B-ACT-04: the aerial town has no figures at any scale we own — establishing shot, or aerial-scale sprites?
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `stage_town.png` is an aerial (a house ~90px; a person would be 10-14px); every actor strip is 21-48px wide; `game/assets/scenes/stage_town.json` records "no actors" in its own note; W4-LIFE gave the plate motion (sails, gulls, clouds) instead. MainMenu tile of `build/shots/all/fixture/_sheet_1.png` (0,0)-(768,520) shows the aerial with no figures and reads as a still.
**Doc:** art/ref/specs/09-background-plates.md §3.4, §5; 00-plan Q18 (PIPE-09).
**Recommended default:** establishing shot with motion (as built) — it is the menu and the town push-in only; nobody plays on it.
**Ship default:** as built, recorded in docs/15. **Owns:** `docs/15` (BL-), `game/assets/scenes/stage_town.json` (note). **Size:** S. **Wave:** 7. **Audit:** M4B-ACT-04 (closes).
**Answer line:** "Aerial: still + motion (as built) | 10-14px figures (I supply the sheet)."

### DESIGNER-25 — Q12a / C-19: may "Main Boss" become a creature name, and which encounter vocabulary is canonical ("Encounter N (Trash)" vs "Boss N")?
**Status:** CONFIRMED open; the loop keeps canon's placeholders.
**Evidence:** `data/encounters_t1.json:26-111` `display_name "Raid 1 — Encounter 1..5"`; the fixture sheet's Current Raid panel (RaidPrep tile, ~(1435,650)) reads "Raid 1 — Encounter 5 / Main Boss"; spec 00 §2.3 adds an optional `title` field (fixture-only today); docs/15 C-19 (line 608): raw notes say "Encounter 5 (Main boss)", the ideaboard says "Boss 5", so the trash pull is "Boss 1" in every loot table; docs/15 Q-84 default: render placeholders verbatim, `[name pending]` in dev builds only.
**Doc:** docs/10 §2 (no invented names), docs/13 OQ-8, docs/15 C-19/Q-84, 00-plan Q12a.
**The exact question:** (1) do the 8 Tier 1 encounters (and 32 more at Tiers 2-5) get creature/encounter names from the designer for 1.0, or ship as "Raid 1 — Encounter 5 / Main Boss"; (2) the vocabulary: "Encounter N" (raw notes) or "Boss N" (ideaboard) in UI and loot tables.
**Recommended default:** ship the placeholders (they are canon's own words — Q-84's ruling); vocabulary "Encounter N" in UI, "Boss N" only inside the loot tables' `boss` key (as built).
**Ship default:** as built. **Owns:** `data/encounters_*.json` (`title` if supplied), `docs/10` §2/§8, `docs/15` Q-84/C-19. **Size:** S (names are data). **Wave:** 7 if names come; else none. **Audit:** COMBAT-05.
**Answer line:** "Encounter names for 1.0: no (placeholders) | yes — list: …; vocabulary: Encounter N."

---

**D. ART AND UI — the switches (00-plan §6 Q01-Q18; spec 00 §2.7) — confirm before wave 8, because the art units of 8-9 build on whichever branch stands**

_All thirteen switches below are CONFIRMED to exist at the stated default (grep, 2026-09-15): `figure_scale` (`stage_camp.json:53` 2, `stage_arena_cave.json:34` 2, `stage_arena_dungeon.json:27` 2, `stage_tavern.json:23` 1, `stage_market.json:24` 1); `marks.boss.scale` 1 (`stage_arena_cave.json:289`, `stage_arena_dungeon.json:364`); `Guildhall.HALL_FRAMING := "same"` (`:125`); `Frame.LOCKUP := "44_tagline"` (`:75`); `Town.HUB_CTA := "board"` (`:55`); `RaidView.EXITS_GATED := false` (`:292`); `Results.COMEDY_LINE := "as_built"` (`:94`); `Fonts.MORALE_FACE_FONT := true` (`:27`); `Icons.WARRIOR_GLYPH := "swords"` (`:34`); `ScreenRouter.gd:6` "no transition animation and never will"; `SceneStage.VIGNETTE_SHADER` (`:2013`), no `dof` key; `SceneStage.DEFAULT_ARENA` (`:140`). A ruling that keeps the default costs nothing; a flip is the "other branch" cost below._

### DESIGNER-26 — Q01: figure scale — 2x on camp and both arenas, 1x on tavern/market; does the tavern take the 1.5x exception?
**Status:** CONFIRMED landed behind `figure_scale`; sign-off wanted.
**Evidence:** the fixture sheet Town tile (768,0)-(1536,520): campfire figures ~60px tall against ~210px tents — reads right; Tavern (sheet 2) at 1x against ~22px stools. docs/12 §3.3 allows a 1.5x exception; the plates' own props set today's numbers.
**Ship default:** as built. **Flip cost:** one integer per scene JSON (S). **Wave:** 8. **Audit:** STAGE-02, COMBAT-01, PIPE-04.
**Answer line:** "Q01: as built | tavern 1.5x."

### DESIGNER-27 — Q02: boss mass — 192 art-px, ~300px, or the reference's ~580px on the 1536 frame; upscale or re-author?
**Status:** CONFIRMED landed at 1x; the boss reads small.
**Evidence:** RaidView tile of `_sheet_1.png` (0,1060)-(768,1440): the Main Boss is the purple creature at ~(690,1310), roughly 90px tall on a 768-wide tile (≈180px at 1536) beside 2x party figures — it does not dominate the arena the way the reference's ~580px boss does; `marks.boss.scale: 1`; docs/12 §4.1 warns 2x "reads as chunky".
**Options:** stay 1x (S, nothing) · `marks.boss.scale` 2 (S; chunky, the doc's own warning) · re-author the seven Tier 1 boss/trash sprites at ~300px (L, an art unit, COMBAT-07) · the reference's 580px (XL).
**Recommended default:** re-author the Main Boss and Mini Boss at ~300px for Tier 1 (two sprites), trash stays 1x — the two fights the player reads most; Tiers 2-5 reuse with palette variants (BL-68's rule).
**Ship default (wave 10):** `marks.boss.scale` 2 on main/mini boss only if no re-author lands — chunky beats invisible.
**Owns:** `game/assets/actors/boss_*.png` + `.json`, `game/assets/scenes/stage_arena_*.json` (`marks.boss`), `tools/art/*` generators, `tests/unit/test_scene_stage.gd`. **Size:** L. **Wave:** 8 (art unit), rule in 7. **Audit:** PIPE-03, STAGE-01, COMBAT-01/07.
**Answer line:** "Q02: boss height ___px; upscale ok / re-author."

### DESIGNER-28 — Q03: hall vs hub on one camp plate — same framing, or a distinct framing/tint; roster margins-only or a 3-column camp strip?
**Status:** CONFIRMED landed (`HALL_FRAMING = "same"`, margins-only). BL-78 (the designer's 2026-09-13 ruling) fixed the PLATE; the framing is the loop's default.
**Evidence:** `Guildhall.gd:125-126` `"same"` / `FRAMINGS` holds `"tight"`; RaiderDetail/LoadSave/Settings read `Guildhall.framing()`; Guildhall tile of `_sheet_2.png`.
**Ship default:** as built. **Flip cost:** one constant (S) for `"tight"`; the 3-column roster is M (HALL-02b). **Wave:** 8. **Audit:** TOWN-14, HALL-02.
**Answer line:** "Q03: same | tight; roster: margins | 3-column."

### DESIGNER-29 — Q04: one bubble chrome everywhere (dark callout) or the navy fight plate; and the emote vocabulary beyond "…"
**Status:** CONFIRMED landed (one chrome; ten glyphs drawn; mapping of band/event → emote NOT ruled).
**Evidence:** `Widgets.speech_plate` / `PanelBubble`; the RaidView tile shows the dark bubble at ~(265,1215) "The boss did the thing the boss does…"; the emote glyphs exist (BUILD_STATE "the emote glyphs still pictograms" — housekeeping (4)).
**The exact question:** (1) one chrome or two; (2) which morale band or sim event drives each of mug / sweat / skull / zzz / heart / ! / ? — a 7-row table the designer fills (the loop's proposal: heart ≥80, mug 60-79 in the tavern, sweat on a mistake roll ≥ Moderate, ! on a mechanic call, ? on a Minor, zzz on the bench, skull on downed).
**Ship default (wave 10):** one chrome; the proposed mapping 🔷, behind `SceneStage.EMOTE_MAP`. **Owns:** `game/ui/SceneStage.gd` (map), `game/ui/Widgets.gd`, `game/assets/ui/emotes*.png`, `docs/12` §5.x. **Size:** S (map) + S (glyph redraw, housekeeping). **Wave:** 8. **Audit:** KIT-02, STAGE-10, PIPE-05.
**Answer line:** "Q04: one chrome; emote map: take the proposed | edit: ___."

### DESIGNER-30 — Q05 + Q07: header lockup (44px + tagline) and overhead bars (badge + pips on all, HP bar on the acting/struck figure) — confirm-only
**Status:** CONFIRMED landed; both reports recommended the defaults.
**Evidence:** every framed tile of `_sheet_1.png` shows the 44px mark + "Questionable people. Worse decisions." (e.g. Town tile (790,25)); `Frame.LOCKUPS` holds `"58"` and `"33_compact"`; RaidView party strip (0,1450)-(520,1560) shows HP bars on the strip cards and badge+pips on the floor figures.
**Ship default:** as built. **Flip cost:** S each. **Wave:** 8. **Audit:** KIT-13, TOWN-05, COMBAT-03, STAGE-04.
**Answer line:** "Q05/Q07: as built."

### DESIGNER-31 — Q06: the reputation chip — the reference's purple gem, or a reputation sigil (canon: "no gems"); does it carry the word "Rep"?
**Status:** CONFIRMED open; nothing landed (the gem stays).
**Evidence:** Town tile header chip 2 at ~(1215,37) of `_sheet_1.png`: a purple gem + "320", no word; spec 00 §2.5: "chip 2 = Reputation points (canon's single guild stat; the gem icon stays)"; canon has "no gems" (§2.5's own reading of the reference).
**Recommended default:** a reputation sigil (the rank shield already on chip 4) — the gem reads as a second currency to a new player, which is the one thing the header must not say.
**Ship default (wave 10):** gem stays (spec 00 §2.5's recorded choice) with a tooltip "Reputation" (`tools/shot.gd --hover` can verify). **Owns:** `game/ui/Frame.gd` (chip icon), `game/ui/Icons.gd`, `docs/13` §5. **Size:** S. **Wave:** 8. **Audit:** KIT-14.
**Answer line:** "Q06: gem | sigil; label 'Rep': yes/no."

### DESIGNER-32 — Q08: depth of field / tilt-shift — references show none, docs/12 calls it non-negotiable; vignette ships behind `reduced_effects`
**Status:** CONFIRMED landed with `dof` absent.
**Evidence:** `SceneStage.gd:2013` vignette shader; no `dof` key in any scene JSON; docs/12 §3 "tilt-shift non-negotiable" vs the concepts (no blur).
**Recommended default:** off (as built) — the reference concepts are the standard (memory rule) and they show no blur; docs/12 amended to "optional, off".
**Ship default:** off; docs/12 amended. **Flip cost:** M (a blur layer with strength + per-scene grade values — the designer must supply the grade). **Wave:** 8. **Audit:** STAGE-07, PIPE-10.
**Answer line:** "Q08: off (as built) | on at strength ___; grade per scene: ___."

### DESIGNER-33 — Q09 / M6-JUICE-02: does "the desk does not move" forbid a 110ms opacity cross-dissolve, or only spatial slides? (also gates the wipe's t=1,800 post-mortem slide)
**Status:** BLOCKED-designer (CONFIRMED).
**Evidence:** `game/core/ScreenRouter.gd:4-7` "this router has no transition animation and never will" (M5's reading) vs docs/13 §12.2 (`docs/13-ui-ux.md:628`) "Screen / tab change | Cross-dissolve + active tab shifts 6px right | 110ms | ease-out" and the 2026-09-09 supersession note (`:45`) "the router still has no transitions"; a `TRANSITION_MS` constant does NOT exist yet (`grep TRANSITION_MS ScreenRouter.gd` → nothing; 00-plan §0.6 "TRANSITION_MS = 0 stays" describes the absence).
**Doc:** docs/13 §2 M5 vs §12.2; audit M6-JUICE-02 (the switch shape); JUICE-03 (the wipe stamp) and the `ui.tab` hook wait on it.
**Recommended default:** a dissolve is NOT the desk moving — allow 110ms opacity only, no position change, gated on `reduced_motion`; the 6px tab shift is a slide and stays out.
**Ship default (wave 10):** `TRANSITION_MS := 0` (today) — no dissolve is built without the word; the docstring's "never will" is softened to "not by default".
**Owns:** `game/core/ScreenRouter.gd`, `docs/13` §2/§12.2, `docs/15` (new Q-), `tests/unit/test_screens.gd` (t=0 insertion must hold). **Size:** M. **Wave:** 8. **Audit:** M6-JUICE-02 (closes), RULES-03, JUICE-03.
**Answer line:** "Q09: dissolve allowed (110ms, opacity only) | nothing moves."

### DESIGNER-34 — Q10: town focus entry — rail-first (as built, tested) or hotspot-first (docs/13 §13.2, PROPOSED)
**Status:** CONFIRMED landed rail-first.
**Evidence:** `tests/unit/test_a11y.gd:469-473` pins `rail[0]` as the first tab stop; `a11y_smoke.gd` likewise; docs/13 §13.2 proposes hotspot-first.
**Recommended default:** rail-first (as built) — the rail is the only element that exists on every screen, so one habit serves all.
**Ship default:** as built; docs/13 §13.2 amended. **Flip cost:** S (two tests + `Frame.META_FOCUS_ENTRY`). **Wave:** 8. **Audit:** RULES-06.
**Answer line:** "Q10: rail-first."

### DESIGNER-35 — Q11: levels on cards — see DESIGNER-21 (folded; the fixture shows "Lv. 12" on four cards, the game never sets `level > 0`)
**Status:** folded into DESIGNER-21. Evidence: `_sheet_1.png` Town tile card "Bork Lv. 12" at ~(905,405); `Cards.gd:144`. Ship default: dormant.

### DESIGNER-36 — Q12b + Q12c: the Results comedy line beside the tally (as built vs COMBAT-20's (a)/(b)/(c)); may the player leave mid-account (`EXITS_GATED = false`)
**Status:** CONFIRMED landed at the defaults.
**Evidence:** `Results.COMEDY_LINE := "as_built"` (`:94`); Results tile of `_sheet_1.png` (768,1060)-(1536,1440): "It's a wipe!" stamp, the line under the title at ~(1050,1170), the tally below; `RaidView.EXITS_GATED := false` (`:292`) with the unlock-after-first-clear rule for "Skip to the end" (`RaidView.gd:386-395`, visible greyed at ~(155,1425)).
**Recommended default:** both as built — Q-53's committed-before-playback (DESIGNER-06) makes a mandatory first watch a UX cost with no integrity gain.
**Ship default:** as built. **Flip cost:** S each. **Wave:** 8. **Audit:** COMBAT-14, COMBAT-20.
**Answer line:** "Q12b: as built | (a)/(b)/(c); Q12c: exits free | first watch mandatory."

### DESIGNER-37 — Q13 (second half): does "Pauline_4" stay as the handle joke on the hiring board?
**Status:** CONFIRMED open (the copy half was answered by the designer's own edit — DESIGNER-10).
**Evidence:** `sim/content/NamePool.gd:189-190` `"%s_%d" % [base, 1 + rng.next_below(9)]` — docs/04 §7's `underscore_digit` shape; TOWN-20: on a pixel-art board it reads as a collision suffix, not a joke; `data/names.json:22` has "Pauline".
**Recommended default:** keep the shape, style it — the card's quote line reads "goes by Pauline_4" while the name line shows "Pauline" (TOWN-20's own suggestion); S.
**Ship default (wave 10):** the styled reading. **Owns:** `game/ui/Cards.gd`, `game/screens/Tavern.gd`, `docs/04` §7. **Size:** S. **Wave:** 8. **Audit:** TOWN-20.
**Answer line:** "Pauline_4: keep as-is | style 'goes by' | drop the shape."

### DESIGNER-38 — Q14: settings controls — the recorded cycle buttons (lit when engaged) or toggle/segmented/slider widgets the references lack
**Status:** CONFIRMED landed (cycle buttons; W5-KIT3 is adding `Widgets.pips` this wave for the 6-step strip).
**Evidence:** Settings tile of `_sheet_2.png`; `Widgets.gd`; 00-plan Q14 "HALL-17's lit cycle buttons land; nothing else".
**Recommended default:** as built. **Ship default:** as built. **Flip cost:** M (three widgets). **Wave:** 8. **Audit:** KIT-20, CRITIC-C16.
**Answer line:** "Q14: cycle buttons."

### DESIGNER-39 — Q15: should A0's scripted round-3 mistake and TR's "read the Wipe Report" lesson be surfaced on RaidView/Results as a one-line callout band, or stay as Board blurbs?
**Status:** CONFIRMED open; nothing landed. W5-SIM is landing the scripted round-3 mistake in the sim THIS wave (`force_mistake_round`), so the lesson will exist to point at.
**Evidence:** AdventureBoard tile of `_sheet_1.png` (0,540)-(768,900): the A0 notice text at ~(240,680) carries the lesson ("On the third round somebody will do something stupid, and that is the lesson"); RaidView shows no callout band; 00-plan Q15 "if 'no', record it in q-tutorials.md".
**Recommended default:** yes — one callout band over the log on the tutorial encounters only ("Round 3: this is the lesson." / "Read the report: it says who and why."), reduced to nothing outside tutorials. The tutorial is the one place the game may teach out loud.
**Ship default (wave 10):** the band, tutorials only, behind `RaidView.TUTORIAL_CALLOUT := true`. **Owns:** `game/screens/RaidView.gd`, `game/screens/Results.gd`, `data/encounters_tutorial_t1.json` (a `lesson` string), `tests/unit/test_tutorials.gd`. **Size:** S. **Wave:** 8. **Audit:** CRITIC-G14, M5-TUT-12.
**Answer line:** "Q15: callout band yes/no."

### DESIGNER-40 — Q16 + M6-A11Y-06: the four accessibility rulings — CVD ramp (option or the only ramp; the ten hexes), the text floor at the letterbox, what `prose_font_swap` means now, the pre-rendered logotype vs "no text in art"
**Status:** BLOCKED-designer (CONFIRMED) — the CVD half is a standing conflict between two authorities; the other three are one-word each.
**Evidence:** `game/ui/Palette.gd:19-20` "the two authorities disagree in writing"; `:245` `band_color_cvd` built; `:260` `OPT_CVD_SAFE := "colourblind_safe"`; `:272-283` `cvd_safe()` returns false unless `GameSettings.DEFAULTS` has the key — and `GameSettings.gd:35-55` DEFAULTS does NOT (docs/13 §15.1's "if an option is not in this table, it does not exist"), so the §8.3 ramp is **unreachable in the shipped game**; `:290` `band_color_active` has "no shipping call site". docs/13 §8.3 (`:312`) rejects red→green; §13's CVD row is Blocking: Yes; no CVD simulation tool or test exists. `GameSettings.DEFAULTS.prose_font_swap = false` (`:40`) while Fira Sans is already the body face (Q16's note). Type.SMALL 13 / STACK 11 at the 1.0547 letterbox vs docs/13's floor.
**Doc:** docs/13 §8.3, §13, §15.1; docs/15 Q-79; art/ref/specs/04-palette.md §5/§7; BACKLOG.md:169.
**The exact questions:** (1) CVD: a player option `colourblind_safe` (default off = the reference's red/amber/green) — needs a docs/13 §15.1 row — or §8.3's red→ochre→olive→teal as the ONLY ramp (the design wins over the reference: "the most-read element in the game"); and the ten hexes (docs/13 §8.3 misses its own ΔL* promise — the loop can compute an L*-ordered set and hand it over); (2) text floor: which authority wins at the letterbox — Type.SMALL 13 / STACK 11 stay, or the floor rises to 14/12; (3) `prose_font_swap`: retire the option (its purpose is served) or redefine it (e.g. swap to a dyslexia-friendly face — which the loop would have to source, licence and credit — DESIGNER-05); (4) is the logotype exempt from §14's "no text in art"?
**Recommended defaults:** (1) option, default OFF, §15.1 row added, the loop builds `tools/art/cvd.py` + `tests/unit/test_palette_cvd.gd` (both ramps must pass ΔL* ≥ 5 and deuteranope ≥ 3:1); (2) 13/11 stay (the sheets at text150 show them legible); (3) retire `prose_font_swap`; (4) exempt (the logotype is a mark, and Q16's note already calls it pre-rendered).
**Ship default (wave 10):** the recommended defaults; the §15.1 row is the only doc edit that unlocks the switch.
**Owns:** `docs/13` §8.3/§13/§15.1, `game/core/GameSettings.gd` (DEFAULTS row), `game/screens/Settings.gd` (the control), `game/ui/Palette.gd` (call sites → `band_color_active`), `game/ui/Type.gd`, `tools/art/cvd.py` (new), `tests/unit/test_palette_cvd.gd` (new), `docs/15` (new Q- for the conflict). **Size:** L. **Wave:** 8 (the option + tooling), 9 (call sites). **Audit:** M6-A11Y-06 (closes), RULES-08/09/14, CRITIC-G10.
**Answer line:** "CVD: option (default off) | only ramp; text floor: 13/11 | 14/12; prose_font_swap: retire | ___; logotype: exempt."

### DESIGNER-41 — Q17: morale faces as an authored sprite font — confirm docs/12 §5.2's reading of canon's emoji notation
**Status:** CONFIRMED landed (`Fonts.MORALE_FACE_FONT := true`; flipping restores system emoji). Canon C-29: 87 is ❤️, 54/31/14 are faces, six of ten bands unspecified.
**Evidence:** the fixture cards show the authored faces ("Bork — 87 ❤" at ~(880,445) of `_sheet_1.png`); the `emoji` sheet exists for the flip.
**Recommended default:** as built. **Ship default:** as built. **Wave:** 8. **Audit:** HALL-05, COMBAT-10, CRITIC-C09.
**Answer line:** "Q17: sprite faces."

### DESIGNER-42 — Q18 (the asset-scope bundle): eleven small rulings that size the wave 8-9 art units
**Status:** mixed — five landed behind switches (confirm-only), six open.
**Evidence/Doc:** 00-plan §6 Q18 row; spec 00 §2.7 (`Town.HUB_CTA`, `Icons.WARRIOR_GLYPH`); `class_actors.json` records a re-hue was tried and rejected (HALL-06/PIPE-16).

| # | Ruling | State | Recommended / ship default | Size if flipped |
|---|---|---|---|---|
| 18a | Hub crimson control — "Open the board" (`HUB_CTA = "board"`) or "Go to prep" | landed | as built — the board is where the player chooses; prep is downstream | S |
| 18b | Warrior glyph — crossed swords (`WARRIOR_GLYPH = "swords"`) or docs/12 §5.1's shield (`class_warrior_shield.png` emitted) | landed | as built | S |
| 18c | First visible-change tranche on the camp (TOWN-15) and what the guildhall IS on the plate with its four levels (HALL-18) | open | folds into DESIGNER-22's dressings: the big guild tent gains a banner / a second tent / a lantern ring / a painted sign per level | M (in the LOOP-06 unit) |
| 18d | HSV-derived variant busts and figures vs drawn ones (HALL-06, PIPE-16) | open | drawn variants only where a sheet has them; otherwise ONE figure per class (no re-hue — already rejected by trial) | L if the designer wants per-rarity figures (an art unit) |
| 18e | Which three fumble flavours first (STAGE q5) | open | trip / drop weapon / wrong target — the three the log's Minor/Moderate/Severe lines describe most | S |
| 18f | Normals or a global light (STAGE-17) | open | global light (Q-75's own fallback); normals only if a single class prototype shows an obvious gain at 1440p | M |
| 18g | Aerial townsfolk (PIPE-09) | open | DESIGNER-24 | — |
| 18h | Which sim states get a glyph beyond the eight named (PIPE-07) | open | none more for 1.0; the log line carries the rest | S |
| 18i | One attack + one support VFX family per class (PIPE-02) — a role-based default landed in W3-RAIDVIEW2 | landed | as built (role-based) — per-class families are a 1.1 art unit | L |
| 18j | Raid Group tab — read-only view or retired (HALL-21) | open | retire — RaidPrep's strip IS the raid group; a second view is a second truth | S |
| 18k | Combat body canvas — 64x80 art-px or the reference's 40-60px density (PIPE q2, COMBAT q2) | open | keep the reference density (memory rule) unless DESIGNER-27 re-authors the bosses, in which case bosses take a larger canvas and party bodies stay | — |

**Wave:** 7 to rule (they size the wave 8-9 art units). **Audit:** TOWN-15, HALL-18, HALL-06, PIPE-16, STAGE-09/17, PIPE-06/07/02, HALL-21, PIPE-04, COMBAT-07.
**Answer line:** "Q18: a as built · b as built · c dressings per level · d one figure/class · e trip/drop/wrong-target · f global · h none · i as built · j retire · k reference density — or edit: ___."

### DESIGNER-43 — M6-JUICE-04: BACKLOG's "screen shake on wipes" contradicts docs/13 §11.4/§12.2/§13 — confirm the strike
**Status:** BLOCKED-designer (CONFIRMED) — a one-word confirmation; the loop may not overrule a doc's tonal ruling on its own authority.
**Evidence:** `BACKLOG.md:168` "screen shake on wipes"; `grep -rni shake docs/` → 0; docs/13 §11.4 (`:602`) "No 'You Failed', no red flash…", §12.2 (`:640`) "Nothing in the UI loops, pulses, or breathes", §13 (`:688`) reduced flashing unconditional; the canon-compatible beat is JUICE-03's stamp press + 12% dim (visible on the Results tile: "It's a wipe!" stamp at ~(990,1145)).
**Ship default (wave 10):** struck, with the note; the stamp is the beat. **Owns:** `BACKLOG.md:168`, `BUILD_STATE.md` (log). **Size:** S. **Wave:** 6 (housekeeping). **Audit:** M6-JUICE-04 (closes).
**Answer line:** "JUICE-04: strike."

### DESIGNER-44 — spec 00 §4's two undecided items: 3:2 letterbox vs extend on 16:9 (`display_aspect` keep|expand), and a Blacksmith rail item once built
**Status:** CONFIRMED: `display_aspect` is a shipped player option (`GameSettings.gd:46` `"keep"` default; `wide-keep` / `wide-expand` sheets shot 2026-09-15); the rail item is moot unless DESIGNER-10 = yes.
**Recommended default:** keep (letterbox) as the default, expand as the option — as built. **Ship default:** as built. **Wave:** 8. **Size:** 0.
**Answer line:** "Aspect: keep default (as built)."

### DESIGNER-45 — The reference-concept conflicts spec 00 already RULED (Ranger, named bosses, levels, gems, the clock) — confirm-only, no decision owed
**Status:** CONFIRMED ruled by spec 00 §2.2-§2.6; listed so the designer sees they were taken, not to reopen them.
**Evidence:** §2.2 Tiny/Ranger → Rogue (no Ranger in `Enums.CharClass`); §2.3 "The Sludge Maw — Level 18+ · 1-4 Raiders" → `display_name` + `kind`, no levels (DESIGNER-21/25); §2.4 four cards → twelve, paged; §2.5 chips: gold · reputation (gem — DESIGNER-31) · raiders/12 · "Day N · Rank" instead of a clock (visible: Town tile chip 4 "Day 23 · Unknown" at ~(1455,37)); §2.6 rail labels canon's building names.
**The one item still open in this set is the gem (DESIGNER-31).** Everything else: no answer needed; a "reopen" would be a canon change.
**Answer line:** "Spec 00 §2: confirmed."

---

**E. AUDIO — rule before wave 8 (an owner first, then the beds; the ambience half is not blocked)**

### DESIGNER-46 — M6-AUD-05 / docs/15 §8: music — an owner, then composed / licensed CC0 / cut for 1.0; the five rank beds and the Legendary leitmotif
**Status:** BLOCKED-designer (CONFIRMED). The shipped Settings screen says it out loud.
**Evidence:** Settings tile of `build/shots/all/fixture/_sheet_2.png` (768,1060)-(1536,1560): "Audio — music · The bus is here and waiting; no music is written yet." at ~(1130,1408) and "Audio — voice of the scribe · The bus is here and waiting; nothing is voiced yet." at ~(1130,1449); `game/core/Audio.gd:28` "NO MUSIC. `play_bed()` is deliberately a no-op", `:567-573`; `game/assets/audio/sfx/` holds 15 generated UI one-shots (`tools/audio/gen_sfx.py`) and no bed; `tools/audio/README.md:107-120` "No music, and no ambience yet … gen_amb.py" (not written); docs/02 §9.1 (`docs/02-town-and-buildings.md:349-354`) commits an Audio column per rank: Unknown "Wind, one dog, sparse lute" → Known "Lute gains a drum" → Respected "Anvil ring loop, market chatter" → Established "Full ensemble; crowd murmur bed" → Renowned "Bell toll on entry" → Legendary "Cheer stinger on entry; leitmotif"; docs/15 §8 (`:635`) "The word 'music' appears nowhere in the doc set … Assign an owner"; spec 00 §4 "Sound. None of the references imply any".
**Doc:** docs/02 §9.1; docs/13 §12.4 (eleven UI hooks — built) and §15.1 (four buses — built); docs/15 §8; docs/16 W6.
**The exact questions:** (1) who owns audio (a name, or "the loop, ambience only"); (2) the five melodic beds and the leitmotif — composed (the designer or a person they name delivers five seamless 44.1 kHz loops + a motif the Legendary stinger can quote), licensed CC0 (the loop can source and credit — DESIGNER-05 — but not choose the game's voice), or **cut for 1.0** (ambience only; the Music bus stays with its honest note); (3) the "voice of the scribe" bus — is anything ever voiced in 1.0, or is the bus retired from Settings ("13 of 17 live in this build" is what the player reads today at ~(950,1140)).
**Not blocked, and the loop should do it regardless (M6-AUD-05's split):** the ambience half — `tools/audio/gen_amb.py` producing rank-keyed 30-60s loops (wind, dog, crowd murmur, anvil, bell) the way `gen_sfx.py` produces one-shots; `Town.play_bed(rank)`; the anvil only if DESIGNER-10 = yes. M, wave 8.
**Recommended default:** (1) the loop for ambience, the designer for melody; (2) cut melodic beds for 1.0 — a generated arpeggio is worse than silence (the audit's own words); (3) retire the voice bus row from Settings (keep the bus).
**Ship default (wave 10):** ambience loops per rank, no music, the Settings note reads "No music in this build." (not "written yet" — a promise), voice row hidden; docs/02 §9.1's Audio column amended 🔷 to what shipped.
**Owns:** `tools/audio/gen_amb.py` (new), `game/assets/audio/amb/` (new), `game/core/Audio.gd` (`play_bed`), `game/screens/Town.gd`, `game/screens/Settings.gd:105-110` (notes), `docs/02` §9.1, `docs/15` §8 + new Q-, `data/credits.json` (if CC0). **Size:** M (ambience) / XL (composed). **Wave:** 7 to rule; 8 ambience; 9 beds if any. **Audit:** M6-AUD-05 (closes), M6-AUD-01/06.
**Answer line:** "Audio owner: ___; beds: cut for 1.0 | CC0 (I'll approve picks) | composed by ___ by wave ___; voice bus: retire row."

---

**F. NAMING LEFTOVERS — one line each, any wave (they ship as placeholders that are canon's own words)**

### DESIGNER-47 — Q-61 (the currency is "G"), Q-68 (Market / the Merchant / Adventure's Board as string-table keys), Q-39 (Power on zero Adventure armour — "confirm as deliberate")
**Status:** CONFIRMED at their register defaults; each is a confirmation, not a decision the loop could take.
**Evidence:** every header chip reads "12,480 G" (`_sheet_1.png` Town tile ~(1140,37)); docs/15 Q-61 (line 542) "Keep 'Guild Coin (G)' as an explicit placeholder until named"; Q-68 (line 549) the three strings as keys; Q-39 (line 510) "Confirm as deliberate and reproduce exactly, but say so in writing" — `data/items_t1_adventure.json` carries no `power` on armour, so the melee classes' only Adventure Power source is the charm.
**Ship default:** "G", the three names as built, Q-39 confirmed by the loop's own audit note. **Size:** S each. **Wave:** any. **Audit:** none.
**Answer line:** "Currency: G | ___; buildings: as built; Q-39: deliberate."

### DESIGNER-48 — BL-40: "Buy a round" is priced (8 G × roster) and has no morale number — the Tavern shipped without it
**Status:** CONFIRMED owed (docs/15 BL-40 "DEFERRED … the row is still owed", status line dated 2026-09-15).
**Evidence:** `docs/15:2081-2099`; `sim/core/Comfort.gd:258` carries only the comment; `Comfort.INDULGENCES` has one entry (Hot Bath Token, 20 G, +8); docs/11 §8.3 prices the round and says "doc 05 owns the number"; docs/05 §7.4 has no row; `grep -rn "buy a round" game/screens/Tavern.gd` → nothing — the action does not exist on the shipped Tavern.
**The exact question:** one integer — the guild-wide morale delta of a round (and its cooldown; the Hot Bath Token's is the model). Or: cut the round (it is a docs/02 §5.1 proposal, not canon).
**Recommended default:** cut for 1.0 — the Indulgence line already has a fully specified member and the Tavern's sidebar is full.
**Ship default (wave 10):** cut; docs/11 §8.3's row struck, BL-40 closed. **Owns:** `docs/05` §7.4, `docs/11` §8.3, `docs/15` BL-40, `sim/core/Comfort.gd` (+ `Tavern.gd` if yes). **Size:** S. **Wave:** 7. **Audit:** none (BL only).
**Answer line:** "Buy a round: cut | +__ morale to all, cooldown __ ticks."

---

### Urgency matrix — what must be ruled before which wave

| Rule before | Findings | Why that order |
|---|---|---|
| **Wave 6** (shipping) | 01 BAL-04 lever · 02 tier words · 03 Legendary names · 04 Q-21 provenance · 05 credits · 06 Q-53 (sign) · 08 the two review gates (the sheet) · 09 the curve · 10 Blacksmith in/out · 43 JUICE-04 strike | Everything in waves 7-9 is measured against a completable Tier 1 with named tiers; the Blacksmith answer sizes wave 8; the review sheets take a wave to produce |
| **Wave 7** (balance/content) | 07 Q-29 · 11 upkeep · 12 END-5 · 13 Q-69 · 14 quirks · 15 roster cap · 16 BL-22 · 17 Q-36 · 18 Q-33 · 19 Q-35 · 20 Q-22 · 21 Q-14 · 22 town states · 23 Q-96 · 24 aerial · 25 encounter names · 27 boss mass · 42 the Q18 bundle · 46 audio owner | The Tier 1 balance pass (7) needs 07/17/19 first; the art units of 8-9 are sized by 22/27/42; the ambience unit needs an owner line |
| **Wave 8** (art/UI switches) | 26 · 28 · 29 · 30 · 31 · 32 · 33 · 34 · 36 · 37 · 38 · 39 · 40 · 41 · 44 | A ruling that keeps the default costs nothing; a flip is an S-M unit inside wave 8's polish |
| **Any** | 45 (confirm-only) · 47 | Placeholders that are canon's own words |

**Ship-default risk register (what the game looks like at wave 10 with zero answers):** Tier 1 only (S17 on the Raid 1 clear), A1-A3 and the tutorials re-sized for morale 45 by the loop under the ship rule, eight Legendaries unfindable, no Blacksmith, no upkeep, no board RP, quirks inert, no music (ambience only), the reference red/amber/green ramp with a CVD option, credits with one blank line, and the two content-review gates unpassed in writing. It ships; it is a smaller and less certain game than one answer per row would make it.

## Shippable bar

A reviewer ticks these for the DESIGNER area before the game ships:

- [ ] **Completeness — audit.** All 17 `blocked-needs-human` rows in `build/plan/audit.json` appear above: M6-BAL-04 (01), M5-T25-08 (02), M5-END-4 (05), M5-COMEDY-12 (08), M6-BAL-03 (09), Q59-5 (11), M5-END-5 (12), M5-QAB-4 (13), Q58-1 + Q58-3 (14), M3-LOOP-06 (22), M4B-CONV-04 (23), M4B-ACT-04 (24), M6-JUICE-02 (33), M6-A11Y-06 (40), M6-JUICE-04 (43), M6-AUD-05 (46). The 18th of the 2026-09-11 review, M4B-CONV-03 (the hall plate), was RULED by the designer 2026-09-13 (BL-78) — closed, not listed.
- [ ] **Completeness — switches.** All 13 switches of `art/ref/specs/00-canon-reconciliation.md` §2.7 appear: `figure_scale` (26), `marks.boss.scale` (27), `HALL_FRAMING` (28), bubble chrome (29), `Frame.LOCKUP` (30), overhead bars (30), `dof`/vignette (32), transitions (33), `Town.HUB_CTA` (42a), `RaidView.EXITS_GATED` (36), `Results.COMEDY_LINE` (36), `Fonts.MORALE_FACE_FONT` (41), `Icons.WARRIOR_GLYPH` (42b); plus §2.7's three "not switches": `DEFAULT_ARENA` (23), the Blacksmith gating (10), BL-78 (28); and spec 00 §4's two undecided items (44).
- [ ] **Completeness — 00-plan §6.** All eighteen: Q01 (26) · Q02 (27) · Q03 (28) · Q04 (29) · Q05 (30) · Q06 (31) · Q07 (30) · Q08 (32) · Q09 (33) · Q10 (34) · Q11 (35→21) · Q12a (25), Q12b/c (36) · Q13 (10, 37) · Q14 (38) · Q15 (39) · Q16 (40) · Q17 (41) · Q18 (42, 23, 24).
- [ ] **Completeness — docs/15.** Every Q- row whose recommended default is an instruction rather than a value is here: Q-21 (04), Q-33 (18), Q-36 (17), Q-41 (02), Q-39/Q-61/Q-68 (47); every BL- still marked OPEN/PARTIAL/DEFERRED-owed: BL-58 (14), BL-59 (11), BL-53 (08), BL-42 (15), BL-22 (16), BL-40 ("buy a round" has no morale number — see Coverage); the register's §8 ownership gaps: audio (46), playtest (08/09 — the review gates and the curve ARE the playtest), staffing (05).
- [ ] **Completeness — BACKLOG.** BACKLOG.md's only "blocked" language points at the audit (line 11-13) and at the 16 pending files (line 361) — both covered (02/03).
- [ ] **Nothing here is the loop's to decide.** Each row names a canon number, a canon-adjacent name, a doc-vs-doc conflict, a legal signature, or a taste call the reference-concept rule reserves for the designer. Rows the loop COULD have taken were not listed: the `raid_adj` column bug (02, "S loop fix"), the ambience loops (46), the CVD tooling (40), the comedy review sheet (08), the credits attribution draft (05) — each is marked as loop work inside its finding.
- [ ] **Every row has a ship default** that the loop can take at wave 10 without inventing canon; the two that cannot reach a store without a signature (Q-21, the Legendary names) say so.
- [ ] **Every answered row is propagated per docs/15 §2.2** — the ruling lands in the owning doc, the register row is struck, the switch (if any) is flipped or its default confirmed, and the pin test moves in the same commit.
- [ ] **The wave-10 playtest is FAIL, not WARN**, on a completable Tier 1 (01/09).
- [ ] **`tools/export_build.sh` (no `--dev`) prints `EXPORT OK`** — the 16 `name_pending` files are named or moved out of the mount (02/03).

## Questions for the designer

The answer sheet. One line per row is enough; "as built" or "take the default" is a complete answer. Rows marked ★ have no autonomous fallback that reaches a store.

**Wave 6 — shipping**
1. **BAL-04** — lever (a) baseline / (b) first facility / (c) size A1-A3 for 45 / (d) wipe delta; and the number. _Default: (c)._
2. **Tier words** — T2/T3/T4/T5 × material / cloth / healer / raid_title / raid_adj (+ leather: shares material, or its own word). _Default: none — Tier 1 only ships._
3. **Legendary names** ★ — Warrior, Cleric, Druid, Mage, Wizard, Rogue, Monk, Bard; Natsuna final y/n. _Default: the eight are unfindable._
4. **Q-21** ★ — the nine ideaboard screenshots are your own work: y/n.
5. **Credits** — names and roles; approve the drafted attribution block. _Default: one blank line._
6. **Q-53** — confirm as built (unlimited attempts; the attempt is committed before playback).
7. **Review gates** — sign the name pool; comedy: sign / rewrite lines ___ / cut lines ___. _Default: ships unsigned, in writing._
8. **Clear-rate curve** — A1 _ A2 _ A3 _ TR _ E1-E5 _ (±_), or "take the proposed". _Default: the proposed._
9. **Q-13 Blacksmith** — in 1.0 (upgrades-only) / out; the callout copy. _Default: out; copy stops promising._
10. **JUICE-04** — strike "screen shake on wipes": y. _Default: struck._

**Wave 7 — balance and content**
11. **Q-29** — +15% per raid piece / none / other. _Default: +15% behind a switch._
12. **Upkeep** — not in 1.0 / per-run at __ G by rarity / payday every __ ticks. _Default: not in 1.0._
13. **END-5** — accept the collection endgame / retime 5% to rank __. _Default: accept._
14. **Q-69** — board RP: no / yes at __ RP, cap 15%. _Default: no._
15. **Quirks** — inert in 1.0 / spec the eight per Q58-3's restatements / edit; bard deferred. _Default: inert, displayed._
16. **Roster cap** — rank (as built) / min(rank, hall) / hall. _Default: rank._
17. **BL-22** — accept. _Default: accept._
18. **Q-36** — Rogue: extra swings / dagger +5/+7 / leave. _Default: extra swings._
19. **Q-33** — the healer's 1-AC Worn Leggings → "___" / keep and tag by family. _Default: tag._
20. **Q-35** — Adventure off-hands + starter weapons: sign / off-hands only / neither. _Default: sign._
21. **Q-22** — Established: (b) as built / (a)+(b). _Default: as built._
22. **Q-14** — no level-ups; Drilling in 1.0 y/n; "Lv." label dormant/retire. _Default: no; no; dormant._
23. **Town states** — 1 plate + rank dressings / 3 plates (you supply) / 6 plates (you supply). _Default: dressings._
24. **Q-96** — arena per raid (Adventures cave, Raid 1 dungeon) / per encounter: list. _Default: per raid._
25. **Aerial** — still + motion / 10-14px figures (you supply). _Default: still._
26. **Encounter names** — placeholders / a list; vocabulary "Encounter N". _Default: placeholders._
27. **Q02 boss mass** — height __px; upscale ok / re-author. _Default: re-author main+mini at ~300px; else scale 2._
28. **Q18 bundle** — a · b · c · d · e · f · h · i · j · k as listed, or edits. _Default: as listed._
29. **Audio** — owner ___; beds: cut / CC0 / composed by ___; voice bus row: retire. _Default: ambience only, no music._

**Wave 8 — art and UI switches (a bare "as built" closes each)**
30. Q01 figure scale · 31. Q03 hall framing · 32. Q04 bubble chrome + emote map · 33. Q05/Q07 lockup and bars · 34. Q06 gem or sigil (+ "Rep" label) · 35. Q08 DoF off/on · 36. **Q09 dissolve allowed / nothing moves** · 37. Q10 rail-first · 38. Q12b/c comedy line, exits · 39. Pauline_4 keep / style / drop · 40. Q14 cycle buttons · 41. Q15 tutorial callout y/n · 42. **Q16: CVD option (default off) / only ramp; text floor 13/11 or 14/12; prose_font_swap retire; logotype exempt** · 43. Q17 sprite faces · 44. aspect keep-default.

**Any time**
45. Spec 00 §2 (Ranger→Rogue, no boss names, no levels, Day·Rank chip, rail labels): confirmed. · 46. Currency "G"; building names; Q-39 deliberate.

**Genuine questions the loop cannot frame a default for** (the only ones): 3 (names), 4 (provenance), 5 (your credit), 29 (the owner's name), and BL-40 — "buy a round" is priced (docs/11) and has no morale number (docs/05 owes the row; the Tavern shipped without it): _what does a round do to morale?_ (one integer per raider, once per town cycle; the loop's fallback is +2 capped, the same shape as Q-65's bench numbers).

## Coverage

**Read (2026-09-15, wave 5 running; tree read-only):** `BUILD_STATE.md` Current focus + HANDOFF + invariants; `build/plan/audit.json` (178 items; all 17 `blocked-needs-human` in full; status counts: 62 done, 57 not-started, 33 partial, 9 done-backlog-stale); `build/plan/artaudit/00-plan.md` §0.6 and §6 (Q01-Q18) and the headings of §1-§5; `build/plan/review-2026-09-11.md` §4 (the earlier 18-item grouping); `build/shots/_w5_args.json` (seven W5 units and their contracts, W5-DOCS and W5-SIM in full); `art/ref/specs/00-canon-reconciliation.md` §2.1-§2.7 and §4; `docs/15-open-questions.md` §1-§3, §4 (Q-01 to Q-21 status lines; Q-13/Q-14 in full), §5-§6 (every Q-22..Q-96 row's ID, owner and default), §7 (C-01..C-32), §8, §9, BL-22, BL-42, BL-53, BL-58, BL-59 (head), BL-69; `docs/09` §11-§12.1; `docs/03` §5.6; `docs/02` §9.1 (the Audio column); `docs/11` §8.2/§8.4; `data/tier_words.json`, `data/legendaries/*.json` (warrior in full; the nine `display_name`/`name_pending`/`name_status` fields), `data/credits.json`, `data/reputation.json` (find weights, unlocks), `data/items_t2_*.json` (row shape; every name pattern), `data/encounters_t1.json` (display names); `tools/gen_items.gd` (word columns and name templates), `tools/export_build.sh` (the PENDING gate; the 16 files by grep), `sim/content/ContentDB.gd` (mount rule), `sim/core/Morale.gd` (baseline, offsets, facility bonus, wipe deltas), `sim/core/Recruitment.gd` (cost, pity), `sim/core/Formulas.gd` (MELEE_SWINGS), `sim/core/Achievements.gd:777`, `game/core/GameState.gd` (STARTING_GOLD, ROSTER_CAP_BY_RANK, FLAG_DEFAULTS, payday rows), `game/core/GameSettings.gd` (DEFAULTS), `game/core/Audio.gd` (no-op beds), `game/core/ScreenRouter.gd:4-7`, `game/ui/Palette.gd:19-290`, `game/ui/Cards.gd:144`, `game/ui/Frame.gd`, `game/ui/Fonts.gd`, `game/ui/Icons.gd`, `game/ui/SceneStage.gd` (DEFAULT_ARENA, VIGNETTE_SHADER), `game/screens/Town.gd` (hotspots, HUB_CTA, the lock reason), `RaidView.gd` (EXITS_GATED, the committed-attempt comment), `Results.gd`, `Guildhall.gd`, `Settings.gd:105-110`, `game/assets/scenes/*.json` (figure_scale, boss scale), `tests/unit/test_screens.gd:290-311`, `test_a11y.gd:469-473`, `tools/fixture_reference.gd:27-32`; contact sheets `build/shots/all/fixture/_sheet_1.png` and `_sheet_2.png` (all 14 screens at the fixture).

**Not read / not verified:** `_sheet_3.png` and the other ten sheet sets (empty, focus, text150, emoji, reduced, wide-keep/expand, tabs, raid-advanced/clear) — the switches were verified by grep, not by every sheet; docs/07, docs/06 §5 (the Bard problem) and docs/04 §11 in full — cited through the audit entries and docs/15; the W5 reports/handoffs now landing (W5-DOCS may have re-numbered docs/15 lines cited here — every docs/15 citation above carries its ID as well as its line, and the ID is the durable key); `BACKLOG.md` beyond its header and the two "blocked" lines; the `build/plan/q-*.md` drafts; the nine Legendary files other than warrior/shaman in full; whether `tools/validate_content*.gd` exists under that name (DESIGNER-23 names it as the validator's home — adjust to the real file). No Godot was run (the mutex is the wave's).

**Refuted / corrected while reading:** `BUILD_STATE.md:101` "Q-29 … at their recommended defaults" (DESIGNER-07: unimplemented); audit M6-BAL-03's "Q-29 … the one balance value changed on judgement alone" (should read BL-29); `tier_words.json` T1 `raid_adj: "Basic"` vs the generator's "Basic %s Sword" template (DESIGNER-02); the 2026-09-11 review's count of 18 blocked (now 17 — BL-78 closed one).

