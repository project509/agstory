# q-W7-SAVE — the docs/15 row W7-SAVE owes

W7-SAVE does not own `docs/15-open-questions.md` this wave (W7-DOCS does), so the row it earns is proposed here rather than written. One row, at the next free `BL-` number; the ship plan's "Wave 7 handoffs expected" line calls it "the v17 BL row".

The row records a DECISION the loop took inside its contract, not a question: `save_version` 17 is the last bump before 1.0, and the escape hatch that makes that promise keepable is `flags`.

## The row

**Heading:** `BL-nnn — The save format is frozen at v17; a later feature's persisted mark is a key inside `flags`, never a new top-level key`

**Status cell:** `DECIDED (2026-09-15, W7-SAVE, under the wave-10 ship rule)`

**Body:**

> docs/14 §7.1 listed ten persisted blocks and the tree carried six of them. v17 landed the other four together — `active_run`, `log_tail`, `best_rounds`, `pending_deltas` (SHIP-02/03/15, M6-SAVE-01, M3-SAVE-03/09) — for one reason: so that waves 8-10 need no further bump. `tests/unit/test_savegame.gd` holds `FROZEN_AT_VERSION = 17` beside `FROZEN_SHAPE`, the exact top-level key set `GameState.to_dict()` emits, and the two move together or not at all; a fifth top-level key after this is a format change 1.0 does not make.
>
> The hatch is `flags`: a Dictionary, whose contents `FROZEN_SHAPE` does not enumerate. A later wave's "has the player seen it / when did it happen" mark is a key inside it, declared in `GameState.ONCE_FLAG_DEFAULTS` with a default that is also its TYPE (JSON has one number type; the loader coerces on the way in), read through `once_flag()` and written through `set_once_flag()`, and stored only when it differs from its default. Four are declared in v17 for W8-CRISIS: `last_rank_seen`, `disbanded_day`, `crisis_modal_seen`, `walk_in_id` (BL-143). `flag_enabled()` still refuses these ids — "was the rank-up callout shown" is not a feature flag.
>
> Recorded with it, because it was found by the freeze and is invisible until something re-rolls: **a 64-bit seed cannot be stored as a JSON number.** JSON's one number type is a float64, so a splitmix64 seed loses its low bits — measured, a `guild_seed` came back 32 off after a single round trip, and the replay of an attempt was a different fight (27 mistakes against 17) with the same round count. `guild_seed`, `active_run.master_seed` and `log_tail.seed` are written as TEXT and read back through `GameState._int64()`, which accepts either form, so a v16 save's number still loads with whatever precision that write left it. This had been true of every player guild since `guild_seed = Rng.hash64(name)` landed: `next_raid_seed()` and `_town_rng()` diverged after any reload.
>
> The alternative, and why it was not taken: versioning each later need as its own bump (v18, v19, …) is the honest shape for a project still finding its format, and the wrong one for a project four waves from 1.0 — every bump is a migration step, a fixture, a `FROZEN_SHAPE` edit and a regeneration of the whole fixture chain, and none of them would have carried a byte a player's save did not already imply.

**Cross-references to add where the row lands:** docs/14 §7.5 (the freeze, written this wave); the Q-53 row in this same file already names `active_run`'s shape and v17 by number.
