# Handoffs from agent `state-truth`

Changes my items need in files I do not own. Each is small and each is described so it can
be applied without re-reading the audit. Nothing here is a blocker: the items they belong
to are landed and tested, these close the last gap in each.

---

## 1. `game/screens/Tavern.gd:89` — the last free board refresh (M3-SAVE-06)

Current:

```gdscript
	if _state != null and _state.tavern_board.is_empty():
		_state.refresh_board()
```

Requested:

```gdscript
	if _state != null and _state.board_needs_first_roll():
		_state.refresh_board()
```

**Why.** `GameState.board_needs_first_roll()` is new and returns `not board_rolled and
tavern_board.is_empty()`. The board is now persisted, so the reload exploit is closed by
that alone — a loaded save comes back with its candidates and the `is_empty()` guard does
not fire. The remaining hole is the one docs/04 §3.4 names: "dismissing a candidate from
the board is free and instant; the slot stays empty until the next refresh." Dismiss every
candidate, leave the Tavern, walk back in, and the `is_empty()` guard rolls a whole new
board for free — bypassing docs/04 §3.2's `50g × 2^n` ladder and farming `recruit_pity`.
That predates the save work and lives entirely in this line.

Covered from the state side by `test_a_board_the_player_emptied_stays_empty_across_a_load`
in `tests/unit/test_game_state.gd`. `tests/unit/test_tavern.gd:390` ("nobody has looked
yet") still passes: a new campaign has `board_rolled == false`.

---

## 2. `docs/15-open-questions.md:1417`, `BACKLOG.md:106`, `BUILD_STATE.md:246` — a false claim

All three state that BIG-dumb condition 1 is **Live** because `Raider.consecutive_benched`
"already counts it exactly". Nothing counted it; the field was written by nobody. It is
live now. The replacement wording, with the evidence, is in
`build/plan/q-state-truth.md` under "CORRECTION to Q-59, row 1". House rule 1 forbids me
editing `docs/15` directly, and I own neither of the other two files.

---

## 3. `game/screens/MainMenu.gd` — surface a failed quit-to-menu write

Quitting to the menu now writes the manual slot (docs/14 §7.4's last row, wired in
`GameState._on_screen_changed`). When that write fails, the reason is left in
`GameState.last_save_problem` (a plain `String`, `""` on success, not saved). MainMenu
already has a `_notice` line for exactly this kind of message (`MainMenu.gd:148-151`).

Requested: when building the menu, if `_state.last_save_problem` is non-empty, show it in
the notice Label and clear it. It must be a Label, not a tooltip — house rule 2.

Today the reason is recorded and shown nowhere, which is one step better than the previous
behaviour (no write at all) and one step short of loud.

---

## 4. `game/screens/Town.gd` / `game/screens/Settings.gd` — no change requested

The audit's `remaining_work` for M3-SAVE-05 proposed calling `_state.save_now()` in
`Town._on_back()` and in `Settings._on_back()`'s `goto(MAIN_MENU)` branch. **Do not add
it.** The write is now made by `GameState._on_screen_changed` for every transition to
MainMenu, so adding it in the screens as well would write the manual slot twice per quit.
Reasoning recorded as Q-NEW-D in `build/plan/q-state-truth.md`.

---

## 5. `game/core/SaveGame.gd` — `MIGRATIONS` deliberately left with no v10 entry

`GameState.SAVE_VERSION` is bumped 10 → 11 by the board block. No `MIGRATIONS[10]` entry
was added, and this is a decision rather than an omission: `SaveGame.migrate()`'s own
comment says a gap "hands the body to `from_dict`, which defaults every field it does not
find and reports what it could not restore", and docs/14 §7.3's rule is that a migration
"may drop a field, never guess a value". A v10 body has no board block; `board_rolled`
defaulting to false says exactly what a v10 save can tell us — this guild has never rolled
a board — and the first look at the Tavern fills it as it did before. The step is written
out and commented at the point where the defaults are applied, in
`GameState.from_dict()`.

`OLDEST_MIGRATABLE` stays 10, so v10 saves still load. Pinned by
`test_a_save_written_before_the_board_existed_still_loads` in
`tests/unit/test_game_state.gd`.

If the orchestrator would rather the chain be walked explicitly, the entry is one line in
`SaveGame.MIGRATIONS`: `10: func(b): b["board_rolled"] = false; b["tavern_board"] = [];
return b`. It changes no behaviour. I did not add it because I do not own the file.
