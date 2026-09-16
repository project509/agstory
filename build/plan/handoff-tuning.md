# handoff — tuning

Exact edits in files the tuning extraction did not own. `data/reputation.json`'s
`_notes[1]` cites this file for one thing specifically: **the corrected `docs/03` §9
fence.** That is §1. §2 is the doc-side follow-up §1 implies.

Nothing here is applied. `docs/` is canon and this wave may not edit it (house rule 1).

---

## 1. `docs/03-guild-reputation.md` §9 — replace the fence

`docs/03` §9's fence (the block starting `res://data/reputation.tres`) describes a file
that was never written. Six of its keys do not describe `data/reputation.json`; the
divergence-by-divergence reasoning is `build/plan/q-tuning.md` BL-NEXT+1, and the format
ruling is BL-NEXT+0.

old:

```
res://data/reputation.tres
  ranks: Array[RankDef]              # name, rp_threshold, find_weights (5 ints, sum 1000),
                                     # unlocks_content: Array[StringName],
                                     # unlocks_building: Array[StringName],
                                     # market: {stock_tier, sell_pct, buy_pct}
  awards: Dictionary                 # encounter_id -> {first: int, repeat: int}
  full_clear_bonus_base: int = 50
  repeat_halving_period: int = 5
  obsolescence_mult: float = 0.25
  catchup_mult: float = 2.0
  pity_threshold: int = 25
  disband_rp_penalty_pct: float = 0.10
```

new:

```
res://data/reputation.json
  schema_version: int = 1
  ranks: Array                       # one row per canon rank, IN LADDER ORDER:
                                     #   key: String                 (matches Enums.REPUTATION_KEYS[i])
                                     #   rp_threshold: int           (§6.4)
                                     #   find_weights: Array[int]    (§5.2, 5 ints, sum 1000)
                                     #   max_raid_tier: int          (§7)
                                     #   max_adventure: int          (§7)
                                     #   sell_rate: float            (§7, a fraction)
                                     #   consumable_price: float     (§7, a multiplier)
                                     #   stock_tier: int             (§7, the potion rung)
                                     #   town_unlock: String         (§7, prose — see q-tuning BL-NEXT+3)
                                     #   market_stock: String        (§7, prose)
  raid_awards: Dictionary            # slot "E1".."E5" -> [first, repeat]; TIER 1 BASES, §6.2 multiplies
  full_tier_bonus: Array[int]        # [first, repeat] — the pair BL-35 kept
  adventure_awards: Dictionary       # adventure tier "1".."5" -> [first, repeat]; ALREADY TIER-FINAL
  tutorial_awards: Dictionary        # slot "A0"/"TR" -> [first, repeat]
  rung_cumulative: Dictionary        # rung "A1".."A3" -> [lo, hi] cumulative share (BL-24, BL-37)
  repeat_halving_period: int = 5
  obsolescence_mult: float = 0.25
  catchup_mult: float = 2.0
  catchup_enabled: bool = true       # §8.1 M3's config flag (BL-36)
  stall_attempts: int = 5            # §8.1 M3's trigger
  pity_threshold: int = 25           # §8.1 M2
  pity_min_rank: int = 2             # §8.1 M2's other half — Respected
  disband_rp_penalty: float = 0.10   # §6.5, a FRACTION (the `_pct` suffix is dropped)

Keys beginning with `_` are provenance and are ignored by the loader. JSON has no
comments and these numbers are not defensible without their citations.
```

The assertion sentence under the fence is correct as written and gains a fourth:

old:

    Assertions to run on load: every `find_weights` row sums to 1000; thresholds are strictly increasing; no rank reintroduces a tier a lower rank had at 0 after retiring it (guards C4 and C8 against a bad tuning pass).

new:

    Assertions to run on load: every `find_weights` row sums to 1000; thresholds are strictly increasing; no rank reintroduces a tier a lower rank had at 0 after retiring it (guards C4 and C8 against a bad tuning pass); and the ladder has exactly one row per canon rank, in the enum's order — a dropped row would silently shorten the ladder and clamp every rank above the gap to the wrong gate.

All four are implemented at `sim/core/Reputation.gd::validate()` and each is a collected
error naming the rank, never a crash.

---

## 2. `docs/03` §9's opening line

old:

    🔷 PROPOSED — one resource file so design can tune without a code change.

new:

    🔷 PROPOSED — one data file so design can tune without a code change. JSON rather than `.tres`, because `docs/14` §5.1's deciding row is "readable by `sim/` without breaking §3" and `.tres` needs `ResourceLoader`, which `sim/` may not call.

---

## 3. `BACKLOG.md:103` — the line cannot be checked off yet

The line reads "extract reputation *and* recruitment tables". The reputation half is done;
the doc-04-owned half (`COST_BASE`, `COST_PER_TIER`, `EXPERIENCE_BANDS`) is deliberately
not, and `build/plan/q-tuning.md` BL-NEXT+2 is the ruling that says so. Suggested rewrite,
so the line stops describing work that will not happen in this shape:

old:

    extract reputation *and* recruitment tables

new:

    extract the docs/03 tables (done — `data/reputation.json`); the docs/04 cost/experience tables ship as a sibling `data/recruitment.json` with the economy sweep (q-tuning BL-NEXT+2)
