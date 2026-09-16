# W5-TESTS — the test halves the reconciliation left

Wave 5 follow-up unit. Owned: tests/unit/test_log_player.gd, test_full_loop.gd, test_tavern.gd,
test_legendaries.gd, test_game_state.gd, test_playtest_invariants.gd (new), test_reputation_schema.gd (new),
tools/playtest.gd, GameState.gd/SaveGame.gd (comments only), data/reputation.json (_notes only).

## Acceptance

- [x] M5-COMEDY-05: test_log_player.gd mounts via _mounted_view(), calls view._on_skip(), asserts a quoted Label equals a MistakeLines corpus line filled for the actor; fixture guarded (a mistake IS revealed)
- [x] M5-TUT-14 (1): first A0 clear puts EXACTLY one item in pending_loot (test_full_loop.gd)
- [x] M5-TUT-14 (2): TR skip-warning text 'Cracked Charm of Health' / '+2 HP' scraped from the board before the second skip
- [x] M5-TUT-14 (3): clause 1 — walk TR and A1 in the whole-loop test, or record the split as the accepted shape
- [x] M3-SAVE-06: screen-level regression test in test_tavern.gd (board_rolled true + empty board, mount real Tavern, board stays empty, gold unchanged, recruit_pity unchanged)
- [x] M3-SAVE-06: the two false "no entry for 10" comments corrected (GameState.gd, test_game_state.gd)
- [x] Q59-4 (a): three firings of a Legendary's own trigger in one tier set big_dumb_active with "bullet_3_this_tier"
- [x] Q59-4 (b): three firings spread across a tier change do NOT
- [x] Q59-4 (c): a trigger the subscription gate swallows does not count
- [x] Q59-4 docs wording for BL-59 in build/plan/q-W5-TESTS.md
- [x] M6-PLAY-02: _can_still_make_progress(state, db) -> String with the three solvency conditions
- [x] M6-PLAY-02: stuck rules (rest reason "limit"/"stalled" twice, empty roster)
- [x] M6-PLAY-02: unconditional dump on a stuck state
- [x] M6-PLAY-02: tests/unit/test_playtest_invariants.gd (roster=2 / gold=0 / empty inventory names it)
- [x] M3-TUNE-02 (3): tests/unit/test_reputation_schema.gd key-parity vs the docs/03 §9 fence, failing both ways, `_` keys exempt
- [x] M3-TUNE-02 (3): Reputation.market_stock_tier() gets a test (or noted for W5-DOCS)
- [x] Every test green under RUN_TESTS_ONLY and in the suite; each removal the entries describe turns its test red (line checked and recorded)
- [x] verify --fast green; playtest.gd run once, last lines pasted

## Log

(appended as items land)

- 11:40 Read LESSONS, BUILD_STATE focus, the six audit entries, every owned file. W5-DOCS has already landed the
  docs/03 §9 fence (`res://data/reputation.json` block at docs/03:503), so the parity test reads the real doc.
- 11:55 Wrote tests/unit/test_reputation_schema.gd (8 tests), tests/unit/test_playtest_invariants.gd (8 tests),
  `_can_still_make_progress` + `_cheapest_seat` + `_unsold_inventory_value` + `_mark_stuck` in tools/playtest.gd and
  wired the three call sites + the two-bad-rests rule + the STUCK tally; Q59-4's three tests in test_game_state.gd;
  the Tavern guard regression in test_tavern.gd; the corpus joke test in test_log_player.gd; test_full_loop's three
  clauses. Comments corrected: GameState.gd:2705/2727/2762 (all three said the chain had no entry), test_game_state:397.
- 12:05 parse_check OK (182 scripts). RUN_TESTS_ONLY over schema/invariants/game_state/tavern/log_player:
  TESTS PASSED 136 test(s) in 6 file(s) [2701 ms] — first run, all green (the joke fixture at A1/4242 does fumble).


- 12:20 `tools/playtest.gd` run once (full 8 seeds). Seed 1000 comes back STUCK on day 6 — and it is NOT a dead end,
  it is a GameState bug the finished harness found: `rest_until_recovered()`'s "stalled" guard sums the roster's
  morale, and six raiders drifting down while six drift up by the same 1.125 cancel to the 4th decimal. Probed with
  a scratch script (every raider's morale/baseline before/after the rest): after TR the party sits at 58.05/51.5,
  the bench at 43.425, all baseline 45; one tick later 56.9/50.4 and 44.55 — total 595.8000 -> 595.8000 — and the
  rest ended after ONE day as "stalled" with the bench still short. The town's rest button runs the same loop
  (BL-34). Fix = per-raider movement check: handoff-W5-TESTS.md #1/#2 (GameState.gd:1434/:1458), regression test
  as #3 (tests/unit/test_game_state.gd, handed off because it is red until #1/#2 land). `--dry-run` parses 3/3.
- 12:30 The register lint caught my "docs/15 Q-59" (BL-59 also exists) — cited BL-59. Playtest dump moved from
  print-at-the-moment to a `run["dump"]` printed under the run's row (the state is freed before `_report`).
- 12:40 `tools/lint_motion.sh`: MOTION LINT OK. Final `verify --fast` below.

## The playtest's last lines (one run, 8 seeds, after the change)

```
  1000           6         3      0    76      12    52.0  STUCK — rest_until_recovered() came back 'stalled' 2 times in a row — the roster cannot recover
      at the wall: Start, party morale 55
      day 6, gold 76, board 4 seat(s), inventory would sell for 54 G
      roster (12): Bob warrior 62, Fern warrior 62, Zed cleric 62, Dave druid 62, Cindy shaman 56, Greg rogue 56, Bess rogue 44, Vera monk 44, Steve mage 44, Wilf wizard 44, Lyra wizard 44, Pip bard 44
      cleared: { "A0": 2, "TR": 3, "A1": 5 }
      attempts 3, wipes 0, skipped: []
  8919          73        11      8    76      12    45.0  5 attempts at A2 without a clear
  ... (six more rows: 5 attempts at A1/A2 without a clear, party morale 45 — M6-BAL-04's wall, unchanged)
  0 of 8 guild(s) cleared Tier 1 — 7 needed
  WALL  A1 stopped 5 guild(s)
  WALL  A2 stopped 3 guild(s)
  STUCK  1 guild(s) reached a state they could not play on from
  A STUCK run is a solvency finding (audit M6-PLAY-02): the candidate
  answers go to docs/15, not into this harness.
PLAYTEST FAILED (8 of 8)
```
The playtest stays WARN-only in verify (stage 7/8 greps `PLAYTEST OK` / `cleared Tier 1` / `^  WALL`; all three
lines kept verbatim; the `STUCK` line is new and additive). The seven M6-BAL-04 rows are exactly what they were.

## Judgement calls (recorded, not asked)

- **M6-PLAY-02 door (b)** reads the CHEAPEST SEAT ACTUALLY ON THE BOARD against the purse (`_cheapest_seat`,
  the figure `hire()` charges and `_try_hire()` compares) rather than the literal `cost_of(COMMON, 1)` floor: at
  Respected the board holds no Commons, and "15 G and a seat" would call a guild solvent that cannot buy anyone.
  At Tier 1 / Unknown the two are the same number. `test_a_board_full_of_people_the_purse_cannot_cover_is_not_a_door`
  pins the floor case too.
- **Door (c)'s 60** is `GameState.STARTING_GOLD` (docs/01 §8.0's opening purse, = 60) so the threshold moves with
  the owning constant (LESSONS: derive, don't hardcode). "Unsold inventory" = `pending_loot` + every equipped piece
  (`sell_equipped` exists, so the roster's gear is on the shelf too), at the rank's `Economy.sell_price`.
- **"Twice in a row"** counts consecutive `rest_until_recovered()` calls; the harness attempts between rests, so
  it is two consecutive town cycles, which is the audit's sentence read literally.
- **Q59-4's tests live in test_game_state.gd** (the counter is GameState's; the file already had the BIG-dumb block
  and `_result()` fixture); Natsuna's bullets are read from the definition file, not typed. Test (c) is inherently
  double-guarded: `Morale.apply`'s `Ledger_hears` gate and `_count_bullet_triggers`'s own-bullet intersection are
  the same predicate, so removing only Morale.gd:315 leaves (c) green — the test asserts the observable (she is
  never credited), which is what condition 4 promises.
- **M5-TUT-14 clause 1**: the split (`test_the_ladder_opens_once_the_tutorials_are_played` walks A0->TR->A1 via
  `_clear_rung`) is recorded as the accepted shape, in the test's own comment; folding 25-lap farming into the
  flagship would bury its assertions.
- **M3-SAVE-06 comments**: the entry names GameState.gd:2762; :2705 ("no entry for 11") and :2727 ("needs no
  entry") made the same false claim about `_v11_to_v12` / `_v12_to_v13`, so all three were corrected (comments only).
  SaveGame.gd's own comments were already true — no edit there.
- **stock_tier**: given a test (`market_stock_tier == Consumables.top_potion_tier` at all six ranks — the promise in
  its own docstring) rather than asking W5-DOCS to drop the column.
- **The 8 `ensure_control_visible` stderr lines** in test_full_loop are pre-existing (same 8 in the 10:52 green
  `.verify.log` before any of my edits; AdventureBoard.gd:890/:920's deferred call after a rebuild) — not mine.

## Audit closures

- **M5-COMEDY-05** — `tests/unit/test_log_player.gd :: test_a_real_raids_jokes_reach_the_screen_from_the_corpus`:
  mounts via `_mounted_view()` (A1, seed 4242), `view._on_skip()` (RaidView.gd:1913 `reveal_all()` -> `_append_line`),
  guards the fixture (at least one revealed mistake carries `e.joke()` — it does at 4242), then asserts every quoted
  Label equals `corpus.render(template, e.actor_name)` for a revealed mistake whose `mistake["template"]` names that
  corpus id AND every drawn joke reached a Label AND equals `MistakeLines.fill(text, actor)`. Removal check: RaidSim.gd:1737
  `_draw_joke` (or :212 `mstate["jokes"]`) gone -> `ev.log_line` stays "" -> `emit_mistake(..., "")` never sets
  `params["text"]` -> `joked` empty -> the guard `assert_true(joked.size() > 0)` is red.
- **M5-TUT-14** — (1) `_clear_rung` asserts `pending_loot.size() == 1` on the lap a TUTORIAL rung first falls, before
  "Suggested" (test_full_loop.gd:139-146), and the flagship's step 9 is `assert_eq(..., 1)` (was `<= 1`) — green today,
  red if `_grant_tutorial_trinket` (GameState.gd:1087) hands over nothing. (2) `_skip_the_tutorials` scrapes the board
  after the first skip and asserts "Cracked Charm of Health" and "+2 HP" before the second press, then that a third
  press finds nothing. (3) the split is the accepted shape (comment at `test_the_ladder_opens_once_the_tutorials_are_played`).
  (4) ORCHESTRATOR: the entry's acceptance text should read "on the Adventure's Board" (AdventureBoard.gd:685 is where
  the skip block lives; q-tutorials.md:98) — audit.json is not mine.
- **M3-SAVE-06** — `tests/unit/test_tavern.gd :: test_an_emptied_board_stays_empty_when_the_door_is_opened_again`:
  `_live_state` -> `refresh_board()` -> dismiss all -> `from_dict(to_dict())` on the live autoload (the loaded state the
  door is opened on) -> `_tavern()` (real `build()`) -> board still empty, `gold` unchanged, `recruit_pity` unchanged,
  sidebar still renders. Removal check: Tavern.gd:130 back to `tavern_board.is_empty()` -> `refresh_board()` runs on the
  emptied board -> `assert_true(st.tavern_board.is_empty())` red (and pity advances at Unknown: no Rare on the board).
  Comments corrected: GameState.gd:2705/:2727/:2762, test_game_state.gd:397.
- **Q59-4 (1)** — three tests in test_game_state.gd (names in q-W5-TESTS.md §1). (a) three wipes on three different
  rungs -> peak 3, `big_dumb_active`, reasons has `bullet_3_this_tier` and not `wiped_3`, warning line carries row 4's
  wording; (b) two wipes at Tier 1, `reputation_rank = KNOWN` (Tier 2), third wipe -> `bullet_tier` 2, peak 1, not
  big dumb (exercises GameState.gd:1895-1897); (c) four benched runs fire "benched" three times — the control Common
  with `hates_being_benched` is credited, Natsuna is not, no row opened. Removal check: `_count_bullet_triggers` body
  gone -> (a) red at `assert_eq(peak, 3)`; the :1895-1897 reset gone -> (b) red at `assert_eq(peak, 1)`.
  (2) the docs half: wording in build/plan/q-W5-TESTS.md §1 for W5-DOCS (their BL-59 correction already says the
  tests "are owed with this correction, not by it" — that sentence is what §1 replaces).
- **M6-PLAY-02** — `_can_still_make_progress(state, db) -> String` (static, tools/playtest.gd), three doors + the
  empty-roster rule; called after every hire / attempt / rest in `_play()`; two consecutive "limit"/"stalled" rests
  are stuck; `_mark_stuck` captures the dump (gold, board, inventory sell value, roster, the cleared set, attempts)
  and `_report` prints it under the row unconditionally and fails the gate on any stuck run (`done >= need and
  stuck == 0`). `tests/unit/test_playtest_invariants.gd` (8 tests) — the roster=2/gold=0/empty-inventory fixture is
  named ("2 of 4 needed for A0, 0 G in the purse (nobody on the board), and 0 G of unsold inventory..."); each door
  opened and closed one coin/one item either side; the wiring pinned by reading the source. Step (6): the finished
  harness found ONE stuck seed and it is a code bug, not a dead end (handoff-W5-TESTS.md #1-#3; q-W5-TESTS.md §2) —
  no docs/15 row opened, no candidate picked. Removal check: a `_can_still_make_progress` returning "" ->
  `test_two_raiders_no_gold_and_nothing_to_sell_is_named_as_stuck` red.
- **M3-TUNE-02 (3)** — `tests/unit/test_reputation_schema.gd` (9 tests): top-level and per-rank key parity against
  the docs/03 §9 fence (W5-DOCS had landed the corrected `res://data/reputation.json` fence at docs/03:503 by the
  time the test ran, so it reads the real doc), failing both ways — proved on a synthetic fence wrong in all four
  directions (`test_the_parity_fails_in_both_directions`); `_`-prefixed keys exempt at both levels and shown to be
  dropped by `normalize()`; the loader's columns vs the file's (the doc-independent third side); `_notes[3]`'s
  sentence still names this test; `stock_tier` armed by `market_stock_tier == Consumables.top_potion_tier` at every rank.
  (1) and (2) are W5-DOCS's and appear landed in the working tree.

## Left

- The GameState `rest_until_recovered()` fix and its regression test are a HANDOFF (#1-#3), not landed: rule 1
  (comments-only ownership of GameState.gd) and rule 7 (a same-wave behaviour change). Until the orchestrator applies
  it, the playtest reports seed 1000 STUCK (WARN-only in verify; the gate is already red on M6-BAL-04). After it,
  seed 1000 plays on to A2 like the other seven.
- `_roster_morale_total()` (GameState.gd:1480) becomes caller-less after the handoff — the orchestrator's delete.
- test_legendaries.gd was not edited (Q59-4's tests fit test_game_state.gd's fixture); no shots (test/tools unit).
- Condition #2 (`wiped_3`) still has no per-condition test of its own (only asserted NOT to fire in (a)); not in
  this unit's contract.

## verify --fast (final, 12:50)

```
  PASS  class cache regenerated
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  PASS  PARSE_CHECK scanned 183 script(s)
  PASS  16 generated file(s) agree with tools/gen_items.gd
  PASS  ART CHECK  generators=7  runtime files: 204 agree  0 DIFFERS  0 MISSING
  PASS  TESTS PASSED   2012 test(s) in 101 file(s)  [36666 ms]
VERIFY OK
```
(2012 tests across the shared tree at that moment; this unit added 8 + 8 + 3 + 1 + 1 + the schema file's 9 = 30 and
tightened three existing ones. No sim/ edit, no canon number, no golden moved, no rebaseline.)
