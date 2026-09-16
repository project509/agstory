# Handoff — W2-RESULTS (key `W2-RESULTS`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Nothing here is applied by the unit.

Why: COMBAT-11's by-raider tally carries a "signed tabular morale delta". The plan names
`_state.last_wipe_penalty[id]` as the source, and that dictionary is the WIPE's only — on a clear
it is empty, so the clear branch's column read "—" for every raider (build/shots/W2R_Results_clear.png).
Results.gd already reads a `last_attempt_morale` ledger FIRST when GameState has one
(`_morale_delta_of`, through `_state.get(...)`, so it is null-safe until this lands), then
`last_wipe_penalty`, then the raider's own morale history. These four edits give GameState that
ledger: the net morale movement per party member for the attempt just resolved — brought + cleared
or wipe + knocked out — kept separately from `last_wipe_penalty` (whose contract the Rally Flask and
test_consumables.gd:328-352 pin) and lifted by the flask so the column stays true after it is used.
Owner: nobody this wave (`GameState.gd` → orchestrator, 00-plan §3 ownership table).

## 1. game/core/GameState.gd:352

old:
```
## docs/05 §7.1's wipe delta as actually applied, per raider, for the attempt just
## resolved — the number docs/11 §7's Rally Flask gives half of back.
var last_wipe_penalty: Dictionary = {}
```
new:
```
## docs/05 §7.1's wipe delta as actually applied, per raider, for the attempt just
## resolved — the number docs/11 §7's Rally Flask gives half of back.
var last_wipe_penalty: Dictionary = {}
## The attempt's NET morale movement per party member (brought + cleared, or
## brought + wipe + knocked out), raider id -> float, for the report's by-raider
## tally (docs/13 §11.4 "morale ledger preview"; Results.gd reads it first).
## Separate from `last_wipe_penalty` because the flask's refund is a share of
## the wipe hit alone; the flask adds what it gives back here too.
var last_attempt_morale: Dictionary = {}
```

## 2. game/core/GameState.gd:612

old:
```
    chosen_targets = {}
    last_wipe_penalty = {}
    facility_tier = 0
```
new:
```
    chosen_targets = {}
    last_wipe_penalty = {}
    last_attempt_morale = {}
    facility_tier = 0
```

## 3. game/core/GameState.gd:1251

old:
```
    last_wipe_penalty = {}
    _tick_notes = {}
    for r in last_party:
        _apply_morale(r, "brought")
        if won:
            _apply_morale(r, "cleared")
        else:
            # Recorded as applied, because docs/11 §7's Rally Flask gives half of this
            # exact number back and the player buys it AFTER seeing the wipe.
            var hit: float = _apply_morale(r, "wipe")
            if hit < 0.0:
                last_wipe_penalty[r.id] = hit

    # docs/05 §7.1: "Raider knocked out during a clear — -3, max -6 per attempt."
    if result != null:
        for c in result.casualties:
            if c != null and c.raider != null:
                _apply_morale(c.raider, "knocked_out")
```
new:
```
    last_wipe_penalty = {}
    last_attempt_morale = {}
    _tick_notes = {}
    for r in last_party:
        var net: float = _apply_morale(r, "brought")
        if won:
            net += _apply_morale(r, "cleared")
        else:
            # Recorded as applied, because docs/11 §7's Rally Flask gives half of this
            # exact number back and the player buys it AFTER seeing the wipe.
            var hit: float = _apply_morale(r, "wipe")
            if hit < 0.0:
                last_wipe_penalty[r.id] = hit
            net += hit
        last_attempt_morale[r.id] = net

    # docs/05 §7.1: "Raider knocked out during a clear — -3, max -6 per attempt."
    if result != null:
        for c in result.casualties:
            if c != null and c.raider != null:
                var ko: float = _apply_morale(c.raider, "knocked_out")
                last_attempt_morale[c.raider.id] = float(last_attempt_morale.get(c.raider.id, 0.0)) + ko
```

## 4. game/core/GameState.gd:2361

old:
```
        Morale.set_morale(who, Morale.morale_exact(who) + give)
        who.record_morale_day(day, int(who.morale), "rally_flask")
        lifted += give
```
new:
```
        Morale.set_morale(who, Morale.morale_exact(who) + give)
        who.record_morale_day(day, int(who.morale), "rally_flask")
        last_attempt_morale[raider_id] = float(last_attempt_morale.get(raider_id, 0.0)) + give
        lifted += give
```

## Observations (not edits)

- W3-KIT2 (`Cards.gd`): at `--set=text_scale=150` the kit card's class/band line ("Warrior — Quite Hap",
  "Cleric — Slightly Ann") runs off the 215px card on Results (build/shots/W2R_Results_t150.png, strip);
  a `text_overrun_behavior = TRIM_ELLIPSIS` on that Label, or a wrap, is the card's to add.
- W3-KIT2 (`Cards.gd`): `roster_strip`'s Available mini-grid shows at most 8 faces; on Results it is the
  party roll-call ("Party  12") and the twelve-strong raids show eight. Fine as a roll-call; noted so the
  cap is a known reading, not a surprise.
- `tools/fixture_reference.gd` (W0-SHOT's, orchestrator): the reference roster carries no prior
  `morale_log` rows, so on the `raid:clear` shot the tally's morale column stays "—" until edit §3 lands
  (in play, every Day Tick writes a row and the column reads the day's movement from the second tick on).
