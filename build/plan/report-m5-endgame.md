# report — m5-endgame (M5-QAB-1..5, M5-END-1..3)

Agent key: `m5-endgame`. Files owned: `sim/core/Achievements.gd`, `data/achievements.json`,
`game/screens/Guildhall.gd`, `game/screens/Completion.gd`, `game/screens/Completion.tscn`,
`game/core/ScreenRouter.gd`, `tests/unit/test_achievements.gd`, `tests/unit/test_completion.gd`.
Also created `data/credits.json` (the task text instructs it explicitly for M5-END-4).

Companion files: `build/plan/handoff-m5-endgame.md` (every edit outside my ownership, exact
old -> new), `build/plan/q-m5-endgame.md` (the proposed docs/15 BL entries — docs/15 not edited).

Written as I went. Sections below are appended in completion order.

---

## 0. What the audit got right and what it did not

Verified before acting:

- **M5-QAB-1 evidence is correct.** `grep -rni achievement game/ sim/ data/ tests/` returns
  only the two comment hits the audit names (`sim/core/Morale.gd:261`,
  `sim/core/Reputation.gd:120`). There is no engine and no data file.
- **M5-END-1 is DECIDED, not open** — confirmed. `docs/15-open-questions.md:578` carries Q-88
  with the answer already written into its own column: "A completion beat (doc 13 gains S17),
  then the save continues: Legendary collection to 9-of-9, achievements, flat repeat clears.
  No Tier 6 in 1.0". `docs/10-content-and-encounters.md:568-571` asserts rows 1, 2 and 4
  outright. Implemented as written, not treated as a fork.
- **M5-QAB-4 is genuinely blocked** — confirmed. `docs/03-guild-reputation.md:434` carries the
  "Quest/achievement board" only in the *Town unlock* column for rank **Known**. §6.1's award
  tables carry no board row. There is no RP rate to implement.
- **CORRECTION to M5-QAB-1's `files_to_touch`.** It lists `sim/content/ContentDB.gd` and a
  `_load_achievements()`/accessor pair. I did not do that, and not only because I do not own
  the file: `sim/core/Reputation.gd:63-105` is the closer precedent — a `sim/core` module that
  owns its own JSON table, loads it lazily by `DEFAULT_PATH`, caches it statically and exposes
  `override_tables()`/`reset_tables()` for tests. ContentDB is the *world*; the achievement
  wall is a tuning-shaped table with one consumer. This removes a handoff entirely.
- **CORRECTION to M5-QAB-1's risk note.** It says per-boss wipe counts are "NOT evaluable …
  the same four counters docs/15 BL-59 decided NOT to approximate". True of wipe *streaks*
  (consecutive), which is what BL-59 is about. NOT true of docs/11 §11.1's own Comedy example,
  "Wipe on Encounter 1 five times", which is a lifetime total and is exactly
  `attempt_count(id) - clear_count(id)` — both already persisted (`GameState.gd:672`, `:665`).
  No approximation. That entry ships live.
- **CORRECTION to M5-QAB-3's plan.** It calls for a new `game/screens/Records.gd`. That path is
  not in my ownership list, so the Records view is built inside `game/screens/Guildhall.gd`.

---
