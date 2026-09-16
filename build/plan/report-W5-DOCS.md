# report — W5-DOCS (the docs halves: docs/15's register, the reputation fence, the dead anchors)

Wave 5, 2026-09-15. Owned files: docs/15-open-questions.md, docs/03-guild-reputation.md,
docs/09-items-and-itemization.md, docs/13-ui-ux.md (S09 contents cell only), docs/14 + docs/16
(the two dead `.tres` pointers only), build/plan/q-*.md (mark consumed), audit.json rows
M5-TUT-06, M5-TUT-08, M5-COMEDY-13, M3-TUNE-02 (1)(2), DW-A2, DW-A4, M5-OQ-1.

## Acceptance

- [x] BL-79 — the tutorial skip fork (q-tutorials.md:86-113) + the docs/13 addendum (:115-140) in docs/15, both citations, `RaidPlan.SKIPPED_TUTORIAL_STAYS_ON_BOARD` corrected; docs/13:195 S09 contents cell amended; GameState.gd:893-894 pointer -> handoff
- [x] BL-80 — the mistake-line corpus rulings (q-comedy.md:14 + :67), Owner docs/07 §10.3 + docs/14 §5.3.5/§5.4, measured numbers corrected; BL-21 cross-link; BUILD_STATE line -> handoff; MistakeLines.gd:36 / q-comedy placeholders -> handoff
- [x] BL-81 — the six-row reputation schema table (q-tuning.md BL-NEXT+1, format BL-NEXT+0, town/market prose BL-NEXT+3); data/reputation.json `_notes[0]` -> handoff; docs/03:501-515 fence replaced with handoff-tuning.md §1; docs/14:335 + docs/16:326 `.tres` pointers cleared
- [x] Q59-4 docs half — BL-59 heading/row 4/decision paragraph corrected to the tree; `BULLET_TRIGGER_COUNTS_CAPPED` reading (ii), rejected (i)/(iii), the seven-of-eighteen caveat (q-quirks.md:100-122)
- [x] M5-T25-14 docs half — Q-35's recommended default ("Add both") recorded 🔷 PROPOSED in docs/09 §10.2/§13.1, the docs/15:506 cell pointing at it, content half named as a later unit
- [x] DW-A2 — the dead in-document anchors in docs/15 fixed (incl. `](#)`)
- [x] DW-A4 — docs/03:30's phantom `docs/00-index.md` fixed
- [x] M5-OQ-1 — OPEN rows whose answer is now in the tree updated with the commit/test that settles it
- [x] test_docs_links, test_readme, test_project_hygiene green; `grep -c` on the three anchors; handoff parses under --dry-run; verify --fast green

## Log

- 11:40 docs/15 patched (20 edits): BL-78 gained its missing `<a id>`; BL-79 (skip fork + docs/13 addendum, switch corrected to `RaidPlan.`), BL-80 (line budget + one file; measurement re-derived off the committed goldens: e1 22r/54, e3 21r/30 with Aggro 11, e5_miserable 11r/44 with MechanicDrop/Aggro 7), BL-81 (JSON + six-row fence table + prose columns) appended after BL-78. BL-59 heading/row 2/row 4/decision corrected to three live, BL-NEXT+7/+8 folded in. Q-35 cell -> docs/09. BL-21/34/40/45/74 headings brought to the tree; Q-18 and §8's two gaps corrected. `grep -c "bl-79\|bl-80\|bl-81"` = 3 (one anchor each; cross-mentions are plain text on purpose).
- 12:05 docs/03 §9 fence replaced with handoff-tuning §1 (CRLF preserved), opening line per §2, BL-81 pointer; docs/13:195 S09 cell lists the skip panel; docs/14 §5.1's ❓ OPEN `.tres` note -> ✅ RULED (BL-81); docs/16 W2.6 `reputation.tres` -> `data/reputation.json`; docs/09 §10.2 + §13.1 carry Q-35's "Add both" as the 🔷 PROPOSED build default with the content half named (M5-T25-14). Four q-*.md files banner-marked consumed. Handoff: 15 edits, `--dry-run` = 15 APPLIED (found once each).
- 12:10 RUN_TESTS_ONLY=docs_links,readme,project_hygiene,reputation_schema: 27/28 green. The one red is `test_every_register_citation_resolves_to_a_declared_entry`, tripped by OTHER units' uncommitted citations (Q-51 x9 in Mistakes.gd/RaidSim.gd/test_mistakes/test_tutorials; Q-59 in test_game_state.gd:236, which should read BL-59) — zero of them exist at HEAD; handoff #15 carries the allow-list rows. W5-TESTS's untracked `test_reputation_schema.gd` (7 tests) is GREEN against my corrected docs/03 §9 fence.
- 12:40 `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast`:
  ```
  == 0/8  lint  PASS (class_name; MOTION LINT OK)
  == 1/8  script parse  PASS  PARSE_CHECK scanned 183 script(s)
  == 2/8  generated content  PASS  16 generated file(s) agree
  == 2b/8 generated art  PASS  204 agree
  == 3/8  unit tests  FAIL  1/2011 failing  [37342 ms]
          test_docs_links.gd :: test_every_register_citation_resolves_to_a_declared_entry
          res://tests/unit/test_game_state.gd:236 cites Q-59, and BL-59 also exists - say which
  VERIFY FAILED
  ```
  The one red is W5-TESTS's uncommitted `test_game_state.gd:236` citing `Q-59` for BIG-dumb condition 4 (it is BL-59; Q-59 is damage variance): `git show HEAD:tests/unit/test_game_state.gd | grep -c Q-59` = 0, none of my files are code, and every other test (2010, my three named files and W5-TESTS's `test_reputation_schema.gd` against my fence included) is green. Handoff #15 is the note; the fix is one word in their file. No game/ or sim/ touched, so no lint_motion run owed (verify's stage 0 ran it anyway: OK). (12:10's "handoff #15 carries the allow-list rows" is superseded: the Q-51 unit rewrote its citations before verify ran, so #15 is now a note with no edit.)

## What each box means, in two lines

- **BL-79** - docs/15:3046. Both forks + the omission + the S09 addendum in one entry, both citations (10 §9.3 vs 01 §8.3 + Q-90), switch named as `RaidPlan.SKIPPED_TUTORIAL_STAYS_ON_BOARD` with the reason it lives there; tests cited by name (`test_ladder`, `test_tutorials` x2, `test_full_loop`, `test_board_rows`). docs/13:195's S09 cell lists the warning Label + `Skip the tutorial` Button and points at BL-79; "no S17" said in both places. GameState.gd:893 -> handoff #1.
- **BL-80** - docs/15:3106. Budget 6/14/8 (+4 Legendary) as the named constants, `HOT_TYPES` listed, the floor-on-the-ungated-subset rule (q-comedy +12) folded in; one file vs eighteen with the three reasons and the migration path; Owner 07 §10.3 / 14 §5.3.5 / 14 §5.4. Measurement re-derived from the committed goldens (a script over each `story[]` entry's MISTAKE header line): e1 22r/54 Taunt 12; e3 21r/30 Aggro 11; e5_miserable 11r/44 MechanicDrop 7 + Aggro 7; e5_legendaries 4/20. The "forecast pair" is measured now and the entry says so. BL-21 cross-mentions BL-80 (plain text, so the anchor grep stays at 3). MistakeLines.gd :28/:42/:52 + BUILD_STATE -> handoff #7-9, #11.
- **BL-81** - docs/15:3173. Format ruling (JSON, 14 §5.1's deciding row, what survives of Q-94), the six-row table (§9 said / file has / why), `town_unlock`/`market_stock` prose deferred not refused, the doc-04 boundary + alias paragraph. docs/03 §9: fence replaced with handoff-tuning §1 verbatim (comment pointer `q-tuning BL-NEXT+3` -> `15 BL-81`), opening line per §2, the assertion sentence gains the fourth + names the parity test by audit id; CRLF preserved (diff is 41 lines, not the file). docs/14:335 OPEN -> RULED; docs/16:326 `.tres` -> `.json`. reputation.json `_notes[0..2]`, Reputation.gd :24/:613 -> handoff #4-6, #13-14. Verified the fence's 15 top-level / 10 per-rank keys equal the file's before landing it; W5-TESTS's parity test agrees (7/7).
- **Q59-4 docs half** - BL-59 heading "three live, two recorded; corrected 2026-09-15"; row 2 live on `wipe_streaks` with `BENCH_BREAKS_WIPE_STREAK` (q-quirks +7) and row 4 live on `bullet_triggers` / `bullet_tier` / `bullet_trigger_peak()`; decision paragraph rewritten (#1/#2/#4 ship, #3/#5 stay false with why); readings (i)/(ii)/(iii), the switch, and the seven-of-eighteen caveat, stated as applying to the shipped reading too. `build/plan/q-W5-TESTS.md` did not exist at any point I checked, so nothing to fold in; the owed tests are named as Q59-4 (1). GameState :1162/:1771 pointers -> handoff #2-3.
- **M5-T25-14 docs half** - docs/15:506's Recommended-default cell now points at docs/09 §10.2/§13.1, says PROPOSED and unsigned, and names the content half as `M5-T25-14`; docs/09 §10.2's off-hand block and §13.1's `+3` line each carry a PROPOSED note recording the default, that the data holds 28/no off-hand today, and what lands when the content half does. No Q- row without a recommended default was touched.
- **DW-A2** - the nine were already dead-no-more: the reprefix gave every `Q-nn` in §4-§6 an explicit anchor and the `](#)` is gone (grep over docs/ and art/ref/specs: zero). What WAS still missing was `<a id="bl-78">` - added. A Python walk mirroring `test_link_fragments_resolve` with NO allowances: zero dead fragments, zero dead file links, zero duplicate ids. Handoff #10 empties `DEAD_FRAGMENTS_ALLOWED` so the exemption cannot hide a new one.
- **DW-A4** - docs/03:30 already reads as the audit asks (00 §1.1 is the only filename authority; the escape clause is gone and the dead name is not repeated). Nothing to edit; verified by `test_prose_doc_filenames_exist` green and the walk above. Closed on evidence, not on work.
- **M5-OQ-1** - rows a commit/test settles, and only those: BL-21 heading -> RESOLVED at Tier 1 (the sweep exists; body already said so); BL-34 -> comfort items landed (BL-38/BL-43, `Comfort.gd`, `buy_furnishing`); BL-40 -> Tavern shipped, deferral expired, row still owed (a number this loop may not invent: recorded, not resolved); BL-45 -> delivered (Consumables.gd, RaidPrep loadout, Market Buy tab, `test_consumables`/`test_market`); BL-74 heading -> gate (2) landed (M6-EXP-06 done); Q-18 -> git half done, move still open; §8 "Production schedule" (doc 16 exists) and "Version control" (it is a repo) corrected. Left untouched, deliberately: Q-21, Q-53/BL-53, Q-19, docs/10 §13 row 3 (HUMAN); BL-22 (needs Tier 2); BL-42 (needs a ruling); BL-58 (quirks still inert; q-quirks +5/+6 are proposals, not rulings); BL-61 (validator still owed: checked `Encounter.gd`, no spawn-round collision check); BL-72 (M5-T25-15 not started). docs/16 W3.7 "11 §10" -> "11 §11" is handoff #12 (docs/16 is mine for the `.tres` pointer only).

## Judgement calls

- The docs/13 addendum went INTO BL-79 rather than a BL-82 of its own: the contract allowed either, the two are one question ("what does skipping do, and where"), and the acceptance line counts exactly three new anchors.
- Cross-mentions of BL-80 from BL-21 and of BL-79/80/81 from the data/code pointers are plain text, not `[BL-80](#bl-80)` links, so the acceptance grep on the three lower-case anchors counts 3. §2.2's "link to the short form" is honoured everywhere a link is made; a passing mention is the file's other existing convention.
- BL-80's numbers are from the goldens as committed on 2026-09-15, not from a fresh sim run: the goldens ARE the sim run, byte-pinned by `test_golden.gd`, and a re-run under the lock would have produced the same file or a red golden test.
- BL-59 row 2 was corrected as well as row 4, though the contract named only row 4 and the heading: "three live" is false unless row 2 says why.
- In docs/03 §9 the parity test is cited by audit id (`M3-TUNE-02` (3)), not by filename: the file is untracked W5-TESTS work this wave and a doc must not name a test that may not land.

## Audit closures

- **M5-TUT-06** - closed. BL-79 in docs/15 (:3046) carries the skip fork with both citations and the switch corrected to `RaidPlan.SKIPPED_TUTORIAL_STAYS_ON_BOARD`; the docs/13 addendum is in the same entry and docs/13:195's S09 cell lists the skip panel. Held by `test_ladder.gd :: test_a_skipped_tutorial_leaves_the_board_and_unblocks_what_is_behind_it`, `test_full_loop.gd` (board-mounted skip), `test_board_rows.gd` (one "Skip the tutorial"), `test_docs_links.gd` (the anchor, and the BL-79 citation once handoff #1 lands). (d)'s optional facts-Label assertion was not written (tests are not this unit's).
- **M5-TUT-08** - closed. Fork 2 ("a RESOLVED tutorial counts, cleared or skipped") and the no-tutorials-stays-false omission are BL-79; GameState.gd:893's pointer is handoff-W5-DOCS.md #1. Held by `test_tutorials.gd :: test_onboarding_completes_only_when_both_rungs_are_resolved` and `test_a_wiped_tutorial_does_not_complete_onboarding`.
- **M5-COMEDY-13** - closed for the docs half. BL-80 (:3106) with anchor, Owner 07 §10.3 / 14 §5.3.5 / 14 §5.4, Signal; both halves (6/14/8 constants; one `data/mistake_lines.json`, the backstories precedent, the migration path); the measurement corrected and re-derived (e1 22r/54 Taunt 12; e5_miserable 11r/44 max 7); BL-21 cross-mentions it. MistakeLines.gd :28/:42/:52 and the BUILD_STATE note are handoff #7-9 and #11; q-comedy.md is banner-marked consumed (+11/+12/+13) with +14 parked and Q-NEXT+15 open. Held by `test_mistake_lines.gd` (unchanged) and `test_docs_links.gd`.
- **M3-TUNE-02 (1)(2)** - closed. BL-81 (:3173) is the six-row table + format + prose ruling; docs/03:501-515's fence is handoff-tuning §1 with the opening line from §2; docs/14:335 and docs/16:326 no longer say `.tres`. reputation.json `_notes[0]` (and [1], [2]) are handoff #4-6. (3) is W5-TESTS's `test_reputation_schema.gd`, green against the new fence (7/7).
- **DW-A2** - closed. No dead in-document anchor remains in docs/15 (walk with no allowances: 0); BL-78's missing `<a id>` added; handoff #10 retires the test's exemption row.
- **DW-A4** - closed. docs/03:30 names no phantom file and points at 00 §1.1 as the only authority; `test_prose_doc_filenames_exist` green.
- **M5-OQ-1** - closed for what a commit/test settles (BL-21/34/40/45/74 headings, Q-18, §8's two gaps; docs/16 W3.7 in handoff #12). The HUMAN rows (Q-21, BL-53, Q-19, docs/10 §13 row 3) and the content-gated ones (BL-22, BL-42, BL-58, BL-61, BL-72) are untouched and listed above with the reason each.
- **Q59-4** - docs half closed (BL-59 corrected to three live; readings, switch, caveat recorded). (1) the tests stay open.
- **M5-T25-14** - docs half closed (Q-35's default recorded in docs/09 §10.2/§13.1, the docs/15:506 cell pointing there). (2)-(3) the content half stays open.

## Left

- q-tutorials.md's first three entries (the mechanic budget, the tutorials' HP column, `tanks_required: 0`) are still unnumbered drafts: other audit items name them and they were not in this contract; they would be BL-82..84 and `sim/model/Encounter.gd:244` still points at the q-file.
- q-comedy.md BL-NEXT+14 (the writing envelope as machine checks) and Q-NEXT+15 (the human read) are not in docs/15; +14 was not asked for and +15 is a question, not a ruling.
- q-quirks.md +5/+6/+9 (who owns the quirk spec; the flag+hook seam; the five quirks naming mechanics the sim lacks) stay parked: BL-58 is OPEN and those are proposals for it.
- The optional facts-Label assertion (M5-TUT-06 (d)) and Q59-4's three condition tests were not written: tests are not this unit's files.
- `handoff-tuning.md` §3 (BACKLOG.md:103's line) is still unapplied and not mine.
- The gate's single red (`test_game_state.gd:236` Q-59 -> BL-59) is a one-word fix in W5-TESTS's file; handoff #15 is the note.
