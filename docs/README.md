# README — A Guild Story Design Set

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This is the front door to the design set — what the game is, how the documents relate, which one owns what, and where to start depending on who you are.

---

## 1. What this game is

*A Guild Story* is a guild-management game about running a raiding guild of people who are bad at raiding: you recruit them at the tavern, gear them, keep them from quitting, and send them at a boss knowing roughly how badly they will screw it up. You never press an ability button — you set up the roster, press Start, and watch a simulated raid where every raider's incompetence is one number (mistake chance) that morale and gear modify. Reputation earned in raids visibly rebuilds the town, and the better town is what finally sends you someone competent.

The set's own three-sentence pitch lives in [00 §2](00-vision-and-pillars.md); the five pillars every feature must answer to are in [00 §3](00-vision-and-pillars.md).

---

## 2. How this document set works

**The canon rule.** The two files under `docs/_source/` are the lead designer's own words — the raw notes and the ideaboard transcription. They are **never edited**, not even to fix a typo or "improve" a number. Every other document in this set is derived work and must trace each claim back to them with an inline citation (`canon: raw notes, Guild Reputation`). Where a document invents something canon is silent on, it says so.

**The legend.** Every claim in every doc carries one of three marks:

| Mark | Means | Who can move it |
|---|---|---|
| ✅ CANON | Decided. It is in `_source/`, quoted or directly implied. | Nobody — only the lead designer, by adding to `_source/`. |
| 🔷 PROPOSED | A design proposal that fills a canon gap. Implementable, but not signed off. | Lead designer sign-off promotes it to CANON. |
| ❓ OPEN | Undecided. No answer exists yet. | Whoever owns the question in [15](15-open-questions.md). |

**Say it plainly: anything not marked ✅ CANON has not been decided.** The docs are long and confident in tone; that tone is design intent, not authority. Roughly all the numbers, tiers 2–5, every screen layout, every formula coefficient and the entire art and tech stack are 🔷 PROPOSED. Do not cite a PROPOSED number in an argument as though it were settled, and do not treat a doc's length as consensus.

**One owner per topic.** Each doc has a Scope section listing what it owns and what it does not, with a link to the owner. If two docs state the same number, one of them is wrong — file it in [15](15-open-questions.md) rather than picking a side locally. (Known live collision: the mistake-chance equation, [08 §8.8](08-stats-and-formulas.md) vs [05 §5](05-morale.md).)

**Cross-links are linted, not trusted.** Docs 01–08 were written against guessed filenames, and their "does NOT own" tables and *Related documents* lists pointed at 37 slugs that were never shipped — 91 links, all repointed on 2026-09-10 against the index below. Some of the **numbers** moved too, not only the slugs: classes are doc 06 and recruitment doc 04, items doc 09 and economy doc 11, so a citation copied out of an older revision names the wrong document. `tests/unit/test_docs_links.gd` now fails the suite on any doc link, anchor or prose filename that does not resolve, which is what keeps this from coming back.

---

## 3. The index

| # | Document | Owns | Read if you are |
|---|---|---|---|
| — | [_source/lead-designer-notes-raw.md](_source/lead-designer-notes-raw.md) | **CANON.** The lead designer's verbatim notes: premise, town, reputation ladder, morale table, stats, raid structure. Never edited. | all |
| — | [_source/ideaboard-transcription.md](_source/ideaboard-transcription.md) | **CANON.** Transcription of the nine ideaboard screenshots: the equipment slot matrix and every Tier 1 gear table. Numbers here beat numbers anywhere else. | all |
| 00 | [00-vision-and-pillars.md](00-vision-and-pillars.md) | The player fantasy, the five design pillars, the three target audiences, anti-goals, scope envelope, success criteria, the canonical doc index. | all |
| 01 | [01-core-loop.md](01-core-loop.md) | The three nested loops (one attempt / one town cycle / one tier), the phase state machine, the per-cycle decision list, the pacing budget, new-game starting state, tutorial threading. | designer, engineer |
| 02 | [02-town-and-buildings.md](02-town-and-buildings.md) | The town hub and its five buildings — services, unlock conditions, upgrade levels and costs — plus the rank → visible-town-change contract. | designer, artist |
| 03 | [03-guild-reputation.md](03-guild-reputation.md) | The six-rank reputation ladder, the RP economy (awards, diminishing returns, thresholds, loss), the recruit-rarity-by-rank matrix, and what each rank gates. | designer |
| 04 | [04-recruitment-and-roster.md](04-recruitment-and-roster.md) | The Tavern loop, the raider data model field by field, per-rarity generation recipes, name and backstory generation, the hand-authored Legendaries, roster operations. | designer, engineer |
| 05 | [05-morale.md](05-morale.md) | The single 0-100 morale value: bands, baseline and drift, every trigger that moves it, rarity resilience, leave/disband rolls, wishlists, the roster row format. | designer |
| 06 | [06-classes-and-roles.md](06-classes-and-roles.md) | The nine classes — round contribution, distinguishing mechanic, failure mode, scaling stat — and the rules for filling 12 raid slots from a random pool. | designer |
| 07 | [07-combat-simulation.md](07-combat-simulation.md) | How an encounter resolves after Start: round order, the mistake system (taxonomy, roll sites, severity, cascade), threat, death and wipes, determinism, the combat log. | designer, engineer |
| 08 | [08-stats-and-formulas.md](08-stats-and-formulas.md) | Every stat and every formula — damage, healing, mitigation, threat, and the mistake-chance equation with all its coefficients — plus tier scaling and the tuning-lever map. | designer, engineer |
| 09 | [09-items-and-itemization.md](09-items-and-itemization.md) | The slot model, item families and drop competition, the Tier 1 tables from the ideaboard, the rule that generates Tiers 2–5, loot routing at drop time. | designer |
| 10 | [10-content-and-encounters.md](10-content-and-encounters.md) | The content ladder, Adventure vs Raid, encounter anatomy, the reusable boss-mechanic vocabulary, tutorial content and the skip rule, farming policy, the Tier 1–5 content budget. | designer, artist |
| 11 | [11-economy-and-crafting.md](11-economy-and-crafting.md) | The currency, the faucet/sink ledger, vendor buy/sell pricing, consumables, the price tags on comfort items and upgrades, and whether crafting/salvage ships at all. | designer |
| 12 | [12-art-direction.md](12-art-direction.md) | What "2D-HD" means technically, render and sprite resolutions, the master palette, character/environment art rules, the `art/` tree and the Aseprite export pipeline. | artist, engineer |
| 13 | [13-ui-ux.md](13-ui-ux.md) | Every screen and its primary action, the widget kit, typography, the morale roster display, raid-prep and raid-sim presentation, input maps, the accessibility floor, the settings inventory. | all |
| 14 | [14-technical-architecture.md](14-technical-architecture.md) | Engine and renderer, the sim/presentation split, project layout, every content and save schema, the docs → data pipeline, RNG plumbing, tests and balance sweeps, the build. | engineer |
| 15 | [15-open-questions.md](15-open-questions.md) | The master decision register: every ❓ OPEN question in the set in one place, with owner, what it blocks, and the decision needed. | all |
| 16 | [16-production-roadmap.md](16-production-roadmap.md) | The build plan: milestones anchored to the vertical slice, the consolidated engineering-week and art-unit totals, sequencing, and the cut ladder. | all |

---

## 4. Reading paths

**If you are the lead designer** — you are checking that the derived docs did not drift from your notes.
`_source/lead-designer-notes-raw.md` → `_source/ideaboard-transcription.md` → **00** → **15** (sign off the blockers) → **01** → **03** → **05** → **04** → **06** → **07** → **08** → **09** → **10** → **11** → **02** → **16**.
Read 15 early. Most of the set is waiting on you.

**If you are a programmer** — you want schemas and the sim boundary, not prose.
**14** (project layout, schemas, determinism, tests) → **07** (what the sim must produce) → **08** (the arithmetic it runs) → **04 §8** (the raider record) → **09** + **10** (content schemas) → **01 §4** (the phase state machine) → **13** (what the UI must bind to) → **12 §7** (the art import contract) → **15** → **16**.
Note the invariant before you write a line: `sim/` is pure and deterministic and may never import `game/`.

**If you are an artist** — you want counts, sizes and the pipeline.
**12** (the whole doc; it is the bible) → **02 §9** (rank → town deltas, your largest single obligation) → **10 §12** (the asset counts you are being asked for) → **13** (screen frames your art sits in) → **06** (class silhouettes and per-class fumbles) → **03** (what the rank ladder means) → **16**.

**If you are new to the project** — 30 minutes, in this order.
`_source/lead-designer-notes-raw.md` (the whole thing; it is short) → **00 §2–§3** (the fantasy and the five pillars) → **01 §3** (the three loops) → **05 §1–§5** (morale, which is the game) → **07 §1–§4** (why a raid needs no player input) → then jump to your own lane above.

---

## 5. Where to start right now

1. **[15 — Open Questions](15-open-questions.md).** The decision register. Nothing downstream can be finalised until the blocking questions are answered — does the Blacksmith exist and does crafting ship, who owns the mistake-chance equation, is the raid sim attended or skippable, and what the tiers and bosses are actually called.
2. **[16 — Production Roadmap](16-production-roadmap.md).** What to build first, in what order, against which milestone.
3. If you are about to write code, read **[14](14-technical-architecture.md)** before you open the editor, and check `BUILD_STATE.md` and `BACKLOG.md` in the project root for the current task.

---

## 6. Project state

- **These docs are the deliverable so far.** They turn the lead designer's loose notes into a spec that can be built against. They are drafts, not sign-off.
- **Effectively no code exists.** The project root holds a Godot 4.7 skeleton only: `project.godot`, `sim/core/Rng.gd`, `sim/model/Enums.gd`, a test harness under `tests/`, and `tools/verify.sh`. Every system described in this set is unimplemented.
- **Not a git repository yet.** There is no version history, so there is no safety net behind an edit to a doc. Initialising the repo is an early task.
- **Aseprite is vendored** at `Aseprite/Aseprite.exe`, per the canon direction to use it heavily.
- **The configured Aseprite MCP server failed to connect this session** (`plugin:pixel-plugin:aseprite`, connection closed). Because of that, [12](12-art-direction.md) documents a command-line Aseprite fallback (`--batch` invocations driven by `tools/build_art.sh`) as the pipeline of record. Treat MCP as a convenience, never as a dependency.
- **Docs 15 and 16 are written last in this pass.** If either is missing from your copy, it has not landed yet — the rest of the set does not depend on them being present.

---

## 7. How to change these docs

1. **Never edit `_source/`.** If the designer makes a new decision, it is **appended** to `_source/lead-designer-notes-raw.md` — new section, dated — never rewritten, reordered or "tidied". The ideaboard transcription changes only if a screenshot was transcribed wrong.
2. **Promote, do not overwrite.** When a 🔷 PROPOSED item is signed off, change the mark to ✅ CANON and add a note in place: `✅ CANON — signed off 2026-09-08, promoted from PROPOSED`. Keep the original wording so the trail survives. Same for ❓ OPEN → 🔷 PROPOSED.
3. **Close the question where it lives.** Answering an open question means editing both the owning doc and its row in [15](15-open-questions.md), in the same pass. A question answered in only one of the two is not answered.
4. **Respect ownership.** Change a number only in the doc that owns it; everywhere else, link. If you need a number a doc does not own, add a cross-reference, not a copy.
5. **Update the header.** Bump the `Updated:` date in the blockquote on any doc you touch.

---

## 8. Proposed additions

The completeness audit found work that six docs already depend on and no doc owns. These are **not written**; they are listed here so the gaps are visible. Numbering continues from 16.

| Proposed doc | Why it is needed | Would be referenced by |
|---|---|---|
| `17-audio-and-music.md` | **[high]** No doc owns audio; the word "music" appears nowhere in the set — yet [13 §12.4](13-ui-ux.md) already names eleven UI sound hooks (including `ui.stamp` as "the game's signature sound" and `ui.silence`'s −60dB duck) and defers mixing "to audio's call" with no audio to call; [02 §9.1](02-town-and-buildings.md) promises a per-rank soundscape; [14 §4](14-technical-architecture.md) lists a bare `audio.gd`. Would own the music plan (one town theme per art state, one combat bed per tier, the wipe cue), the SFX inventory keyed to 13's hook names, bus and ducking structure, per-class mistake flavour, settings exposure, and the middleware question. | 02, 12, 13, 14 |
| `18-playtest-plan.md` | **[high]** Eight docs defer decisions "to playtest" and nothing plans one — [00 §8](00-vision-and-pillars.md) VS1/VS5/VS8 and R2, [13 §8.6](13-ui-ux.md), [04](04-recruitment-and-roster.md) Q11, [07](07-combat-simulation.md) OQ-2/OQ-4, [08 §8.6](08-stats-and-formulas.md), [12](12-art-direction.md) Q8, [03 §8.1](03-guild-reputation.md) M3. Would own the test ladder from sim sweeps to vertical slice, cohort sizes and recruiting, a table mapping each deferred question to the test and threshold that closes it, build cadence and instrumentation, and who may change a number on the results. | 00, 03, 04, 07, 08, 12, 13 |
| `19-narrative-and-copy.md` | **[medium]** A large body of comedy writing is required by six docs and owned by none: ≥6 log-line variants for each of 18 mistake types (build-asserted in [14 §5.4](14-technical-architecture.md)), 3–6 bullet variants per backstory tag, barks for nine Legendaries, ~40 achievement names, flavour on ~360 items, a mandatory `comedy_line` per encounter for 42 encounters, tutorial skip copy, and empty-state prose for every screen. [07 §10.3](07-combat-simulation.md) supplies five writing rules for log lines only. Would own the tone-of-voice statement, a string budget so the load is schedulable, per-archetype voice notes, the naming brief for pending canon placeholders, and a review gate for player-facing strings. | 04, 07, 09, 10, 11, 13 |

**Also from the audit, folded into doc 16 rather than a new file:** [10 §1 and §12](10-content-and-encounters.md) hand scheduling to `16-production-roadmap.md` and produce its inputs (42 encounters, 21 boss actors, ~360 item records, 90 icon renders, 254 animation clips); [02 §8](02-town-and-buildings.md) prices six features in engineering weeks and [12](12-art-direction.md) in art units. Doc 16 must consolidate those totals, respect 12 §2.2's "prove the shader stack in week one" and 13 §15's phase order, carry [00 §6.3](00-vision-and-pillars.md)'s cut ladder with a trigger per cut, and add the release checklist nobody owns today — depot upload, platform achievements mapped from 02 §4.4's ~40 in-game ones, and cloud saves against 14 §7.2's `user://saves/` layout.

---

## Related documents

- Every numbered doc above, and the two canon files under [_source/](_source/).
- Project root: `BUILD_STATE.md` (the current task and the build invariants), `BACKLOG.md` (the task queue).
