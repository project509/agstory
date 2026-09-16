# handoff-W7-SIM-EFFECTS — edits in files W7-SIM-EFFECTS does not own

Applied by the orchestrator at the wave's close (`GameState.gd` is W7-SAVE's this wave, `RaidPrep.gd` W7-PREP's, `Results.gd` W7-REPORT's, `Morale.gd` nobody's, docs/15 W7-DOCS's — who assigns the BL number). Each heading is one edit: an `old:` block and a `new:` block; `python tools/apply_handoff.py build/plan/handoff-W7-SIM-EFFECTS.md --dry-run` parses it. SPACES in every `.gd` below.

What the sim now reports, so the consumers below have something to read:

- `SimResult.deltas_queued[*].loot_call` — the number of MIS_LOOT_CALL mistakes that raider made this attempt (0 for everybody else; on every delta, beside `wipe_caused`).
- `SimResult.consumables_unspent` — an Array of `{"raider_id", "sku", "reason"}` for every provision a raider forgot (MIS_NO_CONSUMABLE, reason `no_consumable`): `sku` is `whetstone_kit`, `mana_draught` or `potion_of_steady_hands`. W8-SIM-BALANCE appends the `ninja_pulled` reason (BL-116).
- `RaidSim.run(roster, encounter, db, seed, loadout := {}, opts := {})` — the sixth parameter exists from this wave; the sim reads `opts["legendary_quirks"]` (default `Quirks.DEFAULT_ENABLED`). W7-SAVE's replay passes `difficulty_mult` / `ninja_pulled` through the same dictionary; W8 reads them.

## 1. sim/core/Morale.gd:184

docs/07 §5.2 row 17: MIS_LOOT_CALL "flags a post-encounter morale event (doc 01 owns the morale ledger)" and docs/07 OQ-8 rules it lands "at encounter end". No docs/05 row prices it, so this is a named default: the smallest negative loot row docs/05 §7.3 has (passed over, −3), once per attempt. The BL row in §9 records it.

old:
```
    "wipe_caused": {
```
new:
```
    "loot_call": {
        "delta": -3.0, "cap": Ledger.Cap.ONCE_SESSION,
        "doc": "Called loot before the boss died (docs/07 §5.2 row 17) — docs/05 §7.3's passed-over figure, once per attempt",
    },
    "wipe_caused": {
```

## 2. game/core/GameState.gd:1363

The sim's `loot_call` count becomes the ledger event, in the same session as the attempt's other raid-outcome rows.

old:
```
    _apply_bench_morale()
    _resolve_day_tick()
```
new:
```
    # docs/07 §5.2 row 17 / OQ-8: a loot call is a mid-fight mistake whose morale
    # lands at encounter end. The sim counts them per raider (`loot_call` on the
    # queued delta, W7-SIM-EFFECTS); the ledger's own ONCE_SESSION cap keeps it
    # to one hit per attempt however many times they typed.
    if result != null and typeof(result.get("deltas_queued")) == TYPE_ARRAY:
        for delta in result.deltas_queued:
            if typeof(delta) != TYPE_DICTIONARY or int((delta as Dictionary).get("loot_call", 0)) <= 0:
                continue
            var caller = raider(String((delta as Dictionary).get("raider_id", "")))
            if caller == null:
                continue
            var lc: float = _apply_morale(caller, "loot_call")
            last_attempt_morale[caller.id] = float(last_attempt_morale.get(caller.id, 0.0)) + lc

    _apply_bench_morale()
    _resolve_day_tick()
```

## 3. game/core/GameState.gd:2464

docs/07 §5.2 row 15: a forgotten consumable "is not consumed". The group buffs (kit, draught) were opened for the whole party and stay charged; the per-raider Steady Hands potion of a raider who forgot it comes home.

old:
```
func spend_loadout(potions_spent: int = -1) -> void:
    for key in chosen_consumables:
        var sku_id := Consumables.sku_of_key(String(key))
        var take := int(chosen_consumables[key])
        if sku_id == "minor_healing_potion" and potions_spent >= 0:
            take = mini(take, potions_spent)
```
new:
```
func spend_loadout(potions_spent: int = -1, unspent: Array = []) -> void:
    # docs/07 §5.2 row 15: a forgotten consumable "is not consumed". The sim
    # lists them (`result.consumables_unspent`, W7-SIM-EFFECTS); the group
    # buffs were opened for the party and stay charged, and each Steady Hands
    # potion a raider forgot comes back to the cupboard.
    var forgotten_potions := 0
    for row in unspent:
        if typeof(row) == TYPE_DICTIONARY and String((row as Dictionary).get("sku", "")) == "potion_of_steady_hands":
            forgotten_potions += 1
    for key in chosen_consumables:
        var sku_id := Consumables.sku_of_key(String(key))
        var take := int(chosen_consumables[key])
        if sku_id == "minor_healing_potion" and potions_spent >= 0:
            take = mini(take, potions_spent)
        if sku_id == "potion_of_steady_hands":
            take = maxi(0, take - forgotten_potions)
```

## 4. game/screens/RaidPrep.gd:940

old:
```
    _state.spend_loadout(result.potions_spent)
```
new:
```
    _state.spend_loadout(result.potions_spent, result.consumables_unspent)
```

## 5. game/screens/Results.gd:465

The report surfaces what was forgotten. One extra stat cell, only when there is something to say, so every existing "Mistakes N" read stays whole.

old:
```
    flow.add_child(_stat_cell("Mistakes %d" % result.mistake_count))
```
new:
```
    flow.add_child(_stat_cell("Mistakes %d" % result.mistake_count))
    if not result.consumables_unspent.is_empty():
        flow.add_child(_stat_cell("Provisions forgotten %d" % result.consumables_unspent.size()))
```

## 6. docs/15-open-questions.md:533

Q-57's "implemented" marker.

old:
```
**Swing 1 only retargets; swing 2 resolves on the Warrior** |
```
new:
```
**Swing 1 only retargets; swing 2 resolves on the Warrior** **Status (2026-09-15, W7-SIM-EFFECTS):** implemented — the active tank's `MIS_TAUNT_LAPSE` is Lost Aggro: `Combatant.lost_aggro_round` zeroes the tank's threat for the next Phase 1, swing 1 goes to the second-highest threat, swing 2 resolves on the tank (`RaidSim._phase_boss`); `Formulas.should_retarget`'s 1.10 / 1.30 hysteresis decides every organic switch in `_pick_enemy_target`; the active tank Taunts to 1.10 × highest when its 1.30 Tank Lead is lost (`RaidSim.TAUNT_COOLDOWN_ROUNDS = 2`); pinned by `test_raid_sim.gd::test_a_tanks_action_mistake_drops_aggro_for_one_round`, `::test_taunt_restores_the_lead`, `::test_the_boss_switches_only_past_the_hysteresis` |
```

## 7. docs/15-open-questions.md:534

Q-58's "implemented" marker.

old:
```
**Healer threat yes at a low multiplier (doc 07 owns the number); chain heal never repeats a target and skips anyone above 95% HP** |
```
new:
```
**Healer threat yes at a low multiplier (doc 07 owns the number); chain heal never repeats a target and skips anyone above 95% HP** **Status (2026-09-15, W7-SIM-EFFECTS):** implemented — `RaidSim._cast_heal` returns the healed total and the healer takes `Formulas.threat_from(cls, 0.0, healed)` (`HEAL_THREAT_COEF` 0.50, docs/08 §8.7); the Shaman's hops 2-3 go through `_neediest(..., skip_above = RaidSim.CHAIN_SKIP_ABOVE)` at 0.95 and a hop with nowhere to go is logged; pinned by `test_raid_sim.gd::test_a_clerics_threat_rises_with_healing` and `::test_the_shamans_hops_skip_full_targets` |
```

## 8. docs/15-open-questions.md:3976

BL-116's note: the `opts` seam W8-SIM-BALANCE reads `ninja_pulled` from exists as of wave 7.

old:
```
`Mistakes.NINJAPULL_REACHABLE` is not built; the type is never flagged unreachable; the eight lines stay.
```
new:
```
`Mistakes.NINJAPULL_REACHABLE` is not built; the type is never flagged unreachable; the eight lines stay. W7-SIM-EFFECTS landed nothing on the type itself; it opened the seam — `RaidSim.run(..., loadout, opts)`'s sixth parameter and `SimResult.consumables_unspent` (`{raider_id, sku, reason}`) — that W8-SIM-BALANCE's `ninja_pulled` branch writes into.
```

## 9. docs/15-open-questions.md:4169

One docs/15 row for the defaults this unit took where docs/07 §5.2 gave a direction and no number. W7-DOCS assigns the id: replace `BL-nnn` / `bl-nnn` with the next free number when applying.

old:
```
---

## Related documents
```
new:
```
---

<a id="bl-nnn"></a>
### BL-nnn - Every named mistake has its consequence: the numbers docs/07 §5.2 left to the sim *(🔷 PROPOSED - implemented behind named constants; W7-SIM-EFFECTS)*

**Owner:** [07 §5.2 rows 6-9, 15-17](./07-combat-simulation.md) / [07 §8.1-8.2](./07-combat-simulation.md) / [Q-57](#q-57) / [Q-58](#q-58) - **Signal:** SIM-07, SIM-15, SIM-17: eight types printed a line and changed nothing

docs/07 §5.2's effect column gives each type a direction; where it gives no number the sim
took one, each behind a name in `sim/core/RaidSim.gd` or `sim/core/Mistakes.gd`:

- **MIS_AFK** (row 9, "1-3 rounds, severity picks duration"): `RaidSim.AFK_ROUNDS_BY_SEVERITY`
  = Minor 1 / Moderate 2 / Severe 3 / Critical 3, the rounds AFTER the one the roll fell in
  (`Combatant.afk_until`); "Severe if tank or healer" is the taxonomy row's
  `severity_floor_if_tank_or_healer` applied in `Mistakes.roll`; "Aggro if tank" is
  `emits_if_tank`.
- **MIS_LOOT_CALL** (row 17): the raider's next action is skipped (`Combatant.skip_next_action`)
  and the sim counts it on the queued delta (`loot_call`); the post-encounter morale event
  is `Morale.TRIGGERS["loot_call"]` at −3, once per attempt — docs/05 §7.3's passed-over
  figure, the smallest negative loot row, because no doc prices a loot call.
- **MIS_ARGUMENT** (row 16, "both this raider and one random other"): the other is drawn on
  the seeded channel `argument` from the living raiders; both carry
  `Combatant.argument_penalty_bp` = `RaidSim.ARGUMENT_PENALTY_BP` 500 for the rest of the
  encounter, SET rather than stacked (a second argument does not double it — the cap on
  the situational term is docs/08's `SITUATIONAL_CAP_BP` and a stacking penalty would sit on
  it by round eight of a miserable raid).
- **MIS_NO_CONSUMABLE** (row 15): eligible only for a raider who CARRIES something
  (`Context.consumable_carried`), the same shape as MIS_FIRE's `zone_exists`; the kit /
  draught / Steady Hands bonus is stripped from that raider's profile and reported as
  `consumables_unspent` with reason `no_consumable`; the Guild Feast is eaten in town and is
  not a thing a raider carries.
- **MIS_HEAL_WRONG / MIS_HEAL_CORPSE / MIS_CHAIN_FIZZLE** (rows 6-8): the wrong-target heal
  lands on the highest-HP valid target (docs/07's wording over docs/06 §4.2's "random"), the
  corpse heal lands for 0 on the first corpse in slot order, the fizzled chain lands hop 1 on
  the neediest and hops 2-3 on the two fullest; every wasted heal is a NUMBERS-tier HEAL entry
  carrying `wasted`, and the healer takes threat only for what landed.
- **MIS_WRONG_TARGET** (row 11, "damage goes into a non-priority or immune target; priority
  target unharmed this round"): the swing lands on the first living ADD; with no add in the
  room the priority target is still unharmed and the swing is gone, as before. No number was
  taken — the raider's own `_outgoing_damage` is what lands. SIM-08's full priority table is
  wave 8's.
- **MIS_AGGRO** (row 2, "set above the current primary target"): the offender's threat becomes
  `ceil(top × threshold) + 1` at the offender's OWN `should_retarget` threshold (1.10 melee,
  1.30 ranged), so the pull always clears the hysteresis — SIM-17's `1.10 × top` would have
  left a Wizard's pull below the ranged bar.
- **Taunt** (docs/07 §8.1): the ACTIVE tank — the Warrior, or the Monk seated main tank when no
  Warrior came (docs/07 §8.3's auto-taunt) — spends its Phase 2 action on a Taunt when
  `tank_threat < 1.30 × highest_non_tank` (Tank Lead lost), setting threat to
  `ceil(1.10 × highest)`, cooldown `RaidSim.TAUNT_COOLDOWN_ROUNDS` 2; MIS_TAUNT_LAPSE on that
  tank is Lost Aggro ([Q-57](#q-57)).

Ruled by the loop under the designer's 2026-09-15 delegation; pinned in
`tests/unit/test_raid_sim.gd` (one test per row).

---

## Related documents
```
