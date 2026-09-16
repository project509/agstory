# report-W7-DOCS — docs/08 §8.8 publishes the one equation; the docs match the tree; the wave's rows land

Started 2026-09-15. Contract: `build/plan/ship/00-plan.md` §2 "W7-DOCS". Rulings: `build/plan/ship/RULINGS.md` §2, §3, §5. Handoff: `build/plan/handoff-W7-DOCS.md`.

State at start: commit 29ee204 already landed BL-110..BL-143 and Q-100 in docs/15 ("the amendments to existing rows (§5.2) stay W7-DOCS's").

## Acceptance

- [x] docs/08 §8.8 rewritten to the shipped equation (one table in bp, `ROLL_SITE_WEIGHT`, `SITUATIONAL_CAP_BP`; MORALE_MULT table and the "forked" paragraph gone); `grep -n "❓ OPEN" docs/08` shows nothing in §8.8
- [x] docs/05 §5.1-5.4 pointers, §5.6 deleted, §5.7 reversed (done); docs/03 §4.2 and docs/02/04 worked examples pointed (docs/02 done)
- [x] `test_canon_guard.gd` asserts §8.8's table equals `Formulas`' constants, and §11's `OVERKILL_MARGIN` row (SIM-23)
- [x] docs/07 §9 → docs/14 §8 pointer with the tree's channels (SIM-24 doc half)
- [x] docs/10 §9.1 HP column note (CONTENT-10), §9.2 and docs/01 §8.2 cite docs/09 §10.2; a BL row
- [x] docs/10 §10 M10 row silence-only; docs/08 §5.3 DECIDED-for-1.1 (CONTENT-27, BL-87)
- [x] docs/04 §11.2 → docs/07 §5.6 "Legendary quirks" (Q58-2)
- [x] docs/07 §3 has no "always available"; §7.3 Retreat row amended; docs/13 §5 S11 (CRITIC-M2, BL-95)
- [x] docs/13 §5 S13/S16 "struck (BL-97)"; §13.1 F1 row struck (CRITIC-M4, BL-97)
- [x] docs/13 §12.4 Audio pointer + twelfth hook; docs/14 §4 tree line (AUDIO-06, Q-98)
- [x] docs/14 §10.4 display defaults (SHIP-06); §12 status line (BL-105)
- [x] docs/15: every §5.2 amendment applied; `#q-31` duplicate anchor repaired
- [x] the remaining doc-side rows: BL-22, BL-42, BL-96, BL-98, BL-100..BL-107, BL-114, BL-119, BL-122..BL-131, BL-133, BL-135, BL-137, BL-142, Q-13, Q-14, Q-22, Q-33, Q-53, Q-96, Q-99; spec 00 §2.3/§2.5/§2.7
- [x] docs/09 §13.1 note (CONTENT-05, the 27/28 row count)
- [x] `test_docs_links.gd` green
- [x] audit.json: the wave's closes; `audit_stale.py --top 15` names no done row
- [x] BUILD_STATE wave-7 line, ≤ 250 lines (`test_build_state.gd`); BACKLOG
- [ ] `verify.sh --fast` green

## Log

- docs/08 §8.8: the section is the shipped equation in bp — coefficient table (2400/1500/800/350/120 · 1.20..0.50 · floors · ceilings), `MORALE_BAND_DELTA` imported from 05 §5.2, `SITUATIONAL_CAP_BP` 2000, `ROLL_SITE_WEIGHT` 0.55/0.55/0.15, the matrix moved from 05 §5.4, "one step never two" replaced by BL-20's overlap; MORALE_MULT table and the "forked" paragraph gone; §9.2's Content-Common column re-read at ÷0.76; §11 rows renamed to the code's names + `SITUATIONAL_CAP_BP`, `ROLL_SITE_WEIGHT`, `OVERKILL_MARGIN` 15 (SIM-23). `grep -n "❓ OPEN"` in §8.8: none. §5.3 → DECIDED-for-1.1 (BL-87) with the three riders answered; the switch names read what the tree has (`MANA_MODEL`, `MANA_BURN_DRAIN_ENABLED`) — `Formulas.FOCUS_ENABLED` does not exist yet, so the doc does not name it.
- docs/05: §1 ownership rows flipped (band side only); §5.1/§5.3/§5.4 pointers; §5.2 kept as the one table docs/05 owns; §5.5 reads 08's matrix; §5.6 deleted (pointer to 08 §11); §5.7 reversed; §7.1 gains the BL-112 no-exemption sentence; §12 Q3/Q7 struck as RULED. Every file's own line ending kept (docs 02/03/07/08 are CRLF; the helper preserves it).
- docs/02: §4.3 roster-cap column struck (BL-42, pointer to 04 §12.1); §7 post-1.0 (Q-13); §8 ruled line; §8.1 post-1.0 (Q-14) and the worked example points at 08 §8.8; §9.1 is BL-102's six-row dressing table with the Audio column as shipped (Q-98), the painted brief kept below as post-1.0; §11 Q-22's two rungs, Drilling struck, Blacksmith rows post-1.0; §12 Q8 cites 04 §12.1.

## Resume — 2026-09-15, session 2 (the first agent was killed by a usage limit at ~16:30)

Audited `git diff` against every acceptance line before writing anything. The first agent had landed
far more than its report ticked: rows 2-14 above are all present in the tree and are ticked now, each
verified by reading the amended section, not by trusting the log. What follows is what was genuinely
left.

- Verified and ticked without editing: `test_canon_guard.gd` (+161 lines; the §8.8 bp table against
  `Formulas`, `SITUATIONAL_CAP_BP`, `ROLL_SITE_WEIGHT`, `OVERKILL_MARGIN` 15) — green in the focused
  run; docs/07 §9's channel list and the "doc 14 §8 is the implementation spec" line; docs/10 §9.1's
  BL-28/BL-144 re-derivation and §9.2's doc 09 §10.2 trinkets with docs/01 §8.2 matching; docs/10 §10
  M10 silence-only; docs/04 §11.2's `quirk` row pointing at docs/07 §5.6 and BL-58; docs/07 :106 and
  §7.3's struck Retreat row (no "always available" anywhere in docs/07); docs/13 §5 S13/S16 and §13.1's
  `F1` row struck with BL-97; docs/13 §12.4's Audio.gd pointer and twelfth hook (`ui.quill`); docs/14
  §4's `game/core/` tree, §10.4's display-defaults table, §11's measured budget, §12's status line;
  docs/09 §13.1's 28 → 31 note; docs/03 §4.2's pointer, §5.4's signed gap-fill, §6.1's record-wall row;
  docs/12 §2.2 row 6 and docs/00 VS7 (BL-126); docs/13 §8.3 / §13 / §14 / §15.1 (BL-127, BL-133) and
  §13.2's rail-first model (BL-142); spec 00 §2.3 (BL-135), §2.5 (BL-125), §2.7 (BL-103).
- `test_docs_links.gd`: the three allow-list rows owed by `handoff-W7-AUD-AMB.md` §3 (Audio.gd,
  test_audio.gd, test_audio_beds.gd) were already applied by the first agent. The focused run found one
  row still missing — `test_scene_stage.gd` cites Q-96 twice (`arena_for`, W7-STAGE's new tests, which
  did not exist when the first agent wrote the block) — added with its reason.
- docs/15, the §5.2 amendments that were still outstanding:
  - **Q-31 / BL-59 row 5** (the one §5.2 row the plan names W7-DOCS for by itself): the upkeep fork
    written into the Q-31 cell — no upkeep in 1.0, and the post-1.0 shape (payday every 7 Day Ticks,
    1/1/2/3/4 G by rarity × 2.4^(tier−1), the bench pays, two unpayable paydays = condition 5) with the
    11% / 22% share arithmetic; the BIG-dumb table's row 5 now reads "dead by ruling", not "needs a
    mechanism nobody wrote".
  - **the `#q-31` duplicate anchor: there is no duplicate.** Checked at HEAD and in the tree — every
    `<a id=…>` in docs/15 is unique and so is every heading slug (counted with a one-line
    `re.findall(r'<a id="([^"]+)"')` / heading-slug `Counter`, on the tree and on `git show HEAD:`). The row said
    so because the ruling was written from the register's memory; the Q-31 cell now records that the
    repair was looked for and not needed, which is the honest version of the instruction.
  - **BL-69** amended with Q-41: the valve stays, but no tier is pending any more, so all five mount and
    the Tier-1-only fallback (S17 on the Raid 1 clear, `data/_pending/`) is recorded as not built.
  - **Q-02** marked RULED and pointed at BL-87 / docs/08 §5.3. Judgement call: Q-02 is not in this
    unit's Findings list by name, but docs/08 §5.3 went DECIDED-for-1.1 in this same unit and the
    handoff's edits 6-9 cite `15 Q-02` as ruled — leaving the row reading "🔷 Recommended default" while
    four files cite it as settled is exactly the queue-that-lies failure in LESSONS. No new ruling: the
    cell restates BL-87 and names the handoff that propagates it.
- Everything else in §5.2 (Q-13, Q-14, Q-21, Q-22, Q-28/35, Q-29, Q-33, Q-36, Q-39/61/68, Q-41, Q-53,
  Q-60, Q-69, Q-84, Q-96, Q-98, Q-99, BL-22, BL-30, BL-40, BL-42, BL-53, BL-58, BL-85, BL-87, BL-90,
  BL-95..BL-107) was already applied; checked by asserting "2026-09-15" on each row's own line.
- `build/plan/audit.json` (this unit owns it): the wave's ten closes, then six more the detector named and I
  read one by one (LESSONS: "a detector that closes things is a judge, and this one must not be" — every hit
  cost one reading of the citing sentence, and four of the fifteen it named on the first run survived that
  reading as genuinely open). 120 done / 53 open / 17 blocked became **136 done / 39 open / 15 blocked**. The
  two blocked rows that closed are `M4B-CONV-04` and `M4B-ACT-04`, both by ruling rather than by code.
- `BUILD_STATE.md`: the wave-7 line in Current focus, the queue's new counts, and the paragraph that still read
  "**AWAITING A HUMAN DECISION** … `M6-BAL-04`" rewritten to what is now true — the campaign's on-ramp is RULED
  (lever (c), docs/08 §9.3a's healed clock, W8-SIM-BALANCE applies it and nobody else). The Open-risks bullet
  that said the A3 balance was "a designer decision the loop must not quietly take" says it is ruled. 250 → 249
  lines: the wave-7 sentences are paid for by compressing the wave-6 recital and the M6-BAL-04 paragraph, which
  is the only way to add to a file already sitting exactly on its own limit.
- `BACKLOG.md`: the header's counts; the 2026-09-11 "the loop stopped for a designer review" block now says the
  designer answered by delegating; three Discovered-work bullets struck as resolved — including the one DW-D1
  was raised against, which **had the resolution backwards** ("Implement `Mistakes.gd` from docs/08 §8.8") and
  cost a reading twice. Its replacement says which way round it actually went and names the test that stops the
  two forking again.

## Audit closures

- **M3-SAVE-03** — done. `GameState.active_run` persists the attempt as it departed (encounter, seed, party,
  resolved, difficulty_mult, ninja_pulled) in save v17, and Continue after a mid-replay quit replays that seed
  to Results. Held by `tests/unit/test_savegame.gd` (`added_in_v17` at :790; the `active_run` assertions at
  :1028-1072) and by `test_loadsave_screen.gd` / `test_menu_lockup.gd`'s route tests.
- **M3-SAVE-09** — done. All four absent docs/14 §7.1 blocks (`active_run`, `log_tail`, `best_rounds`,
  `pending_deltas`) landed in ONE v17 bump with a registered step, FROZEN_SHAPE moved with it, and a committed
  `tests/fixtures/saves/v17_sample.json`. Held by `test_savegame.gd`.
- **M6-SAVE-01** — done. The freeze itself: `FROZEN_AT_VERSION := 17` (`test_savegame.gd:672`) moved together
  with FROZEN_SHAPE; the format is frozen for 1.0.
- **M5-T25-12** — already `done` in the queue; the doc half landed here (docs/10 §10's M10 row reads
  silence-only with the drain post-1.0).
- **DW-C1** — done by RULING, not by code (BL-87): Focus is DECIDED for 1.1 with its numbers, so the four
  deliverables are deliberately unbuilt rather than owed. Held by docs/08 §5.3, docs/07 §5.2/§6/§10 and
  docs/10 §10, and by `MANA_BURN_DRAIN_ENABLED := false` in the tree.
- **DW-C2** — done. docs/07's Focus propagation landed in this unit; docs/06 and docs/09 are
  `build/plan/handoff-W7-DOCS.md` §6-§9 (both unowned this wave). Held by `test_docs_links.gd`.
- **DW-D1** — done. docs/08 §8.8 is the shipped equation in basis points, term for term against
  `Formulas.gd:424-449`. Held by `tests/unit/test_canon_guard.gd`, which reads the doc's own table and asserts
  it against `Formulas`' constants — so the doc cannot drift from the code again without a red gate.
- **DW-D2** — done. One table, one owner: docs/05 §5.1/§5.3/§5.4 are pointers, §5.6 is deleted, §5.7 reversed,
  docs/03 §4.2's copy struck, docs/02 and docs/04's worked examples pointed. Held by `test_canon_guard.gd` and
  `test_docs_links.gd`.
- **Q58-2** — done. The owner is docs/07 §5.6 (not docs/06, and the reason is recorded: a quirk is an immunity
  to one of docs/07's own mistake types); docs/04 §11.2's `quirk` row points there and at BL-58.
- **M4B-CONV-04** — done by RULING (Q-96): the arena belongs to the raid, `SceneStage.arena_for()` is the one
  rule, and the item's own `backdrop`-key proposal is superseded in writing. Held by `test_scene_stage.gd`.
- **M4B-ACT-04** — done by RULING (BL-123): the aerial is an establishing shot — motion, no figures.
- **M6-EXP-07** — done (W6-SETTINGS's code; the item's own note said it closes on that report).
  `GameSettings.apply_window_mode()` / `windowed_size()`, `project.godot window/size/mode=3`, `nav_fullscreen`.
  Held by `test_settings.gd:502-510`; published in docs/14 §10.4.
- **M6-AUD-03** — done; the last thing owed was the build wiring and `tools/build_art.sh` now runs
  `gen_sfx.py` in `gen` mode and byte-gates the samples in stage 2b. One documented divergence: no `--audio`
  flag, with the reason written in the file. (`build_art.sh` is W7-AUD-AMB's this wave — cross-check.)
- **M6-AUD-04** — done. Every §12.4 hook is at its trigger site and by signal where one exists; no screen names
  a WAV. Held by `test_audio.gd` / `test_audio_binds.gd`.
- **M6-AUD-06** — done. Q-97 and Q-98 are the numbered decisions, the §8 gap row points at its own resolution,
  and docs/14 §4's tree listing is corrected to `game/core/Audio.gd` by this unit.
- **M5-COMEDY-10** — done. `LogPlayer.collapse()` at display time (never the sim), called from `Results.gd` and
  rendered as one folded row by RaidView. Held by `test_log_player.gd:519-566`.
- **M5-TUT-10** — done. M01 Tank Swap executes and is pinned by `test_raid_sim.gd:593-688`; the two divergences
  from the prescribed implementation are written at `RaidSim.gd:1107-1113`.
- **M5-OQ-1** — NOT closed, remaining_work updated: its two human gates (Q-21 provenance, the names/comedy
  review) are ruled, so what is left is the two Tier-2 re-measures and the rest of its list.

## Judgement calls

1. **Q-02 was amended although the contract does not name it.** docs/08 §5.3 went DECIDED-for-1.1 inside this
   unit and the handoff's edits 6-9 cite `15 Q-02` as ruled; a register row still reading "🔷 Recommended
   default" while four files cite it as settled is the queue-that-lies failure. The cell restates BL-87 and
   names the handoff — it rules nothing new.
2. **The `#q-31` duplicate anchor does not exist.** Checked at HEAD and in the tree: one `<a id="q-31">`, zero
   duplicate anchors, zero duplicate heading slugs in all 4,250 lines. Recorded in the row rather than silently
   dropped, so nobody goes looking for it again.
3. **Six audit rows were closed beyond the ten the contract names**, because the acceptance line is
   "`audit_stale.py --top 15` names no done row" and six of the fifteen it named were finished. Each was closed
   only after reading its own citing sentence against the tree, and each note names the file and line that
   proves it. Four rows the detector named *survived* that reading and stay open (`M3-LOOP-04`'s two unwired
   GameState seams, `Q59-6`'s unarmed `big_dumb_reasons`, `M5-OQ-1`'s Tier-2 re-measures, `M6-BAL-02`'s report
   shape) — which is the detector working as designed.
4. **BL-69 and BL-94 were treated differently.** BL-69 got a full amendment (its valve now passes all five
   tiers, and the Tier-1-only fallback is recorded as not built); BL-94 got none, because its heading already
   reads "DECIDED - Q-60's own default, landed" and RULINGS §5.2 only *confirms* it — adding a paragraph that
   says "still true" is noise in a register that is read for changes.

## Left

- **Not done, by ownership:** the docs/06, docs/09-outside-§13.1, docs/11, `data/reputation.json`,
  `sim/core/Comfort.gd` and `tests/unit/test_reputation.gd` propagations. They are `build/plan/handoff-W7-DOCS.md`
  §1-§15 (parses under `python tools/apply_handoff.py … --dry-run`) and land at the wave-7 close in the
  orchestrator's order, after this unit's own commit.
- **Not done, by scope:** docs/08 §9.3a and docs/10 §8/§9.1's re-sized tables. The contract says explicitly they
  are NOT drafted here — they are W8-SIM-BALANCE's, docs committing before data. docs/10 §9.1 says so in place.
- **Not done, deliberately:** the `q-W7-DOCS.md` file. Nothing in this unit needed a new docs/15 row that
  RULINGS.md had not already written; every row it touched already existed or landed at the wave's start.
- **Carried by other units:** `m6-ambient-effects`, `m6-e4-m05-effect`, `m6-e4-m08-window` (W7-SIM-EFFECTS /
  W8), `M5-T25-07` and `M5-T25-14` (W8-ITEMS's regeneration), `m6-kit-bard` (W9-KITS), `M6-BAL-02`
  (W8-SIM-BALANCE). Left open on purpose; each is somebody's contract, not a stale row.
- **A standing hazard for the orchestrator:** `test_docs_links.gd`'s
  `Q_IN_THE_BL_RANGE_THAT_REALLY_MEAN_Q` allow-list is a file-level list, and every unit in this wave that
  writes a new test citing Q-53 / Q-57 / Q-58 / Q-69 / Q-96 / Q-98 adds a row to it. It went red three times
  during this unit for tests that did not exist an hour earlier (`test_scene_stage.gd`, then `test_content_db.gd`,
  `test_game_state.gd`, `test_loadsave_screen.gd`, `test_menu_lockup.gd`). If it is red at the close, the fix is
  one row per citing file with its reason — never a loosened guard.
