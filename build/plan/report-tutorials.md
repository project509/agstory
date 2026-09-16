# Report — M5 tutorials (Adventure 0 and the Tutorial Raid), key `tutorials`

Owned files: `data/encounters_tutorial_t1.json` (new), `sim/model/Encounter.gd`,
`sim/content/ContentDB.gd`, `game/core/GameState.gd`, `game/screens/AdventureBoard.gd`,
`tests/unit/test_tutorials.gd` (new), `tests/unit/test_content_db.gd`,
`tests/unit/test_encounters.gd`, `tests/unit/test_full_loop.gd`.

Written as each item finished, in the order the items were done.

## Findings before any code was written

- **The audit's own citation for the HP re-derivation is the wrong register.** M5-TUT-01
  cites "docs/15 Q-28" for the 5.3x stage-A error. `docs/15-open-questions.md:494` Q-28 is
  *"Do Common recruits arrive with a weapon?"*. The entry that actually found and fixed the
  5.3x error is **BL-28** (`docs/15:1034-1035`, "Doc 08 never published a starting-gear DPS
  stage"). Everything authored here cites BL-28. This is auditor claim #4 caught wrong.
- **`tests/unit/test_docs_links.gd:284` walks `res://data` and `.json` too.** So a `Q-nn` or
  `BL-nn` token in a data file is linted like code. Inside the 19-67 overlap a bare `Q-nn`
  fails unless the file is on `Q_IN_THE_BL_RANGE_THAT_REALLY_MEAN_Q` — which I do not own.
  Q-47, Q-51, Q-55 and Q-28 all have live BL twins, so this slice cites their **source**
  docs (docs/06 Q6/Q7, docs/07 OQ-9, docs/10 §9.1) by section instead of by register id.
  New rulings are NOT cited by a BL number anywhere in code or data, because docs/15 does
  not declare them yet and the lint would fail the suite the moment it did.
- **M5-TUT-03's evidence is stale.** `ContentDB.DEFAULT_PATHS` (`sim/content/ContentDB.gd:26`)
  holds only `classes` and `starting`; the per-tier files come from `tier_paths()` (:94) and
  a manifest. `adventure_encounters` is at :492, not :377. The fix landed as a DEFAULT_PATHS
  entry (tutorials exist once for the whole game, like starting gear), not a tier_paths entry.
- **M5-TUT-10 is already done.** M01 Tank Swap is fully armed in `sim/core/RaidSim.gd`
  (:582 demand check, :1090 `_phase_mechanic_checks` stack/decay, :1105 `_attempt_tank_swap`,
  :1282 `_phase_boss` damage multiplier). Params are `stack_damage_pct` (default 50) and
  `swap_at` (default 3), and the one-tank degradation the audit worried about is explicit at
  RaidSim.gd:1113 ("has nobody to swap with and holds it at N stacks"). The Tutorial Raid is
  authored against the shipped behaviour, not against the audit's proposed behaviour.
- **A hazard the audit missed: `loot_slots: ["trinket"]` would have made the tutorials drop a
  real Adventure charm.** `Loot.drop_pool` (`sim/core/Loot.gd:99-109`) takes the non-raid
  branch for A0/TR, maps `"trinket"` to `Slot.TRINKET` (:55) and returns every
  `source == "adventure"`, `tier == 1` trinket — i.e. Adventure's Charm of Health **+7 HP**
  and Charm of Power **+2 Power** (`data/items_t1_adventure.json:298-338`). Those are the very
  items docs/10 §9.2 says the crap trinkets must be "visibly worse than", so the tutorials
  would have paid *better* loot than Adventure 1 and made the skip warning a lie. Fixed in
  `GameState.record_attempt` by short-circuiting the roll for a tutorial slot entirely (see
  M5-TUT-05 below); `sim/core/Loot.gd` is not mine and is untouched.
