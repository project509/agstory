# handoff-W5-TESTS

Edits W5-TESTS needs in files it does not own. Format: `## N. <path>:<line>` then `old:`/`new:` fenced blocks.

The one edit below is a REAL FINDING of the finished M6-PLAY-02 harness, not a harness workaround:
`GameState.rest_until_recovered()`'s "stalled" guard sums the roster's morale, and symmetric drift
cancels exactly — six raiders above baseline drift down 1.125 each while six below drift up 1.125 each
(the playtest's seed 1000, day 3: the A0/TR party at 58.05/51.5 and the bench at 43.425, all Commons at
baseline 45). The total is unchanged to the 4th decimal, the six below baseline DID move (43.425 -> 44.550),
and the rest stopped after ONE day with reason "stalled" — one tick short of recovery. The same function is
behind the town's rest button (BL-34), so the player sees it too: "Rested 1 day" and a bench still at 44.
The new harness rule (two "stalled"/"limit" rests in a row is stuck) reports seed 1000 STUCK on day 6 until
this lands; after it, that seed plays on to A2 like the other seven. Probe: the scratch script
`probe_seed1000.gd` printed every raider's morale/baseline before and after the rest (report-W5-TESTS.md).

## 1. game/core/GameState.gd:1434

The per-raider snapshot beside the name snapshot the departure check already keeps.

old:
```
        var before: Dictionary = {}
        for r in roster:
            before[r.id] = r.display_name
        var before_morale := _roster_morale_total()
```
new:
```
        var before: Dictionary = {}
        var before_exact: Dictionary = {}
        for r in roster:
            before[r.id] = r.display_name
            before_exact[r.id] = Morale.morale_exact(r)
```

## 2. game/core/GameState.gd:1458

Per raider, not as a total.

old:
```
        # A tick that moved nobody cannot be repeated into progress. Unreachable
        # while anyone is below baseline (drift always moves them), so this is a
        # guard against a future clamp, not an expected path.
        if absf(_roster_morale_total() - before_morale) < 0.0001:
            reason = "stalled"
            break
```
new:
```
        # A tick that moved nobody cannot be repeated into progress. PER RAIDER,
        # not as a roster total: six raiders drifting down to the baseline and six
        # drifting up cancel exactly (the playtest's seed 1000 on day 3, +/-1.125
        # each), and the total-based check this used to be called that "stalled"
        # one tick short of recovery — on the town's rest button too (W5-TESTS).
        # Unreachable while anyone is below baseline (drift always moves them), so
        # this is a guard against a future clamp, not an expected path.
        var moved := false
        for r in roster:
            var was: float = float(before_exact.get(r.id, Morale.morale_exact(r)))
            if absf(Morale.morale_exact(r) - was) >= 0.0001:
                moved = true
                break
        if not moved:
            reason = "stalled"
            break
```

After both edits `_roster_morale_total()` (GameState.gd:1480) has no caller left; leaving it is harmless,
deleting it is the orchestrator's call (W5-TESTS may not delete in a file it does not own).

## 3. tests/unit/test_game_state.gd:454

The regression test for #1/#2, handed off rather than landed because it is RED until #1/#2 are applied
(rule 7 — a same-wave behaviour change is a handoff, not a call) and a red test in the shared tree
mid-wave misleads every other unit's `verify --fast`. W5-TESTS owns this file; apply #3 in the same pass
as #1/#2 and it is green. Six Commons above baseline and six below by exactly one drift step — the mirror
the total-based guard could not see.

old:
```
# ---------------------------------------------------------------- serialization
```
new:
```
func test_a_rest_where_the_drift_cancels_across_the_roster_is_not_a_stall() -> void:
    # The finished playtest's first real finding (W5-TESTS, seed 1000 on day 3): six
    # raiders above baseline drifting DOWN and six below drifting UP by the same step
    # leave the roster TOTAL unchanged to the fourth decimal, and the old total-based
    # "stalled" guard ended the rest after one day with the bench still short. The
    # town's rest button runs this same loop (BL-34), so the player saw it too.
    _s.new_game("Mirror")
    for i in 12:
        _s.add_raider(_raider("r%d" % i))
    var base := float(Morale.baseline_of(_s.roster[0], _s.facility_tier))
    var step: float = Morale.BASE_DRIFT * float(Morale.DRIFT_RATE[Enums.Rarity.COMMON])
    for i in 12:
        Morale.set_morale(_s.roster[i], base + step * 2.0 if i < 6 else base - step * 2.0)
    var rest: Dictionary = _s.rest_until_recovered()
    assert_ne(String(rest["reason"]), "stalled",
        "twelve raiders all moving toward the baseline is the opposite of a stall")
    assert_eq(String(rest["reason"]), "rested")
    assert_eq(int(rest["days"]), 2, "two steps below baseline is two ticks of rest")
    assert_true(bool(rest["settled"]))
    for r in _s.roster:
        assert_true(Morale.is_recovered(r, _s.facility_tier), r.display_name)

# ---------------------------------------------------------------- serialization
```
