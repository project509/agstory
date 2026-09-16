# handoff-W6-LEDGER

Edits W6-LEDGER needs in files it does not own this wave, applied by the orchestrator at the wave's close (`python tools/apply_handoff.py build/plan/handoff-W6-LEDGER.md --dry-run` parses it). Both files are W6-SIM-CASCADE's in wave 6, so the comment re-points SIM-27 asked for go here rather than in-wave. Every `BL-nn` named below is declared in `docs/15-open-questions.md` by W6-LEDGER (BL-82..BL-93), so `tests/unit/test_docs_links.gd::test_every_register_citation_resolves_to_a_declared_entry` holds them; apply docs/15 first or in the same commit. SPACES in both files. Comment-only: nothing here changes a constant, a signature or a golden. Closing these closes audit `m6-mech-arms-register`.

Line numbers are the tree's at 2026-09-15 (before W6-SIM-CASCADE's edits land); the `old:` text is the anchor.

## 1. sim/core/RaidSim.gd:63

The header: the switch block's proposals are now register entries.

old:
```
# rather than silent, so each one is a documented default behind a name, with a
# proposed docs/15 entry in build/plan/q-mech-arms.md (house rule 1).
```

new:
```
# rather than silent, so each one is a documented default behind a name, each
# recorded in docs/15 (BL-82..BL-89; the entries were promoted from
# build/plan/q-mech-arms.md at the wave-6 close — house rule 1).
```

## 2. sim/core/RaidSim.gd:69

Q-M05 → BL-83.

old:
```
## itself is never synthesised, so an unauthored effect is a demand with no
## teeth rather than a number this file invented.
const INTERRUPT_EFFECT_DEFAULT_KIND := "raid_damage"
```

new:
```
## itself is never synthesised, so an unauthored effect is a demand with no
## teeth rather than a number this file invented. docs/15 BL-83; E4's missing
## effect is audit m6-e4-m05-effect.
const INTERRUPT_EFFECT_DEFAULT_KIND := "raid_damage"
```

## 3. sim/core/RaidSim.gd:78

Q-M01 → BL-84.

old:
```
## swap threshold and there is nowhere left to swap to. One per round off duty
## mirrors one per hit on duty.
const TANK_DEBUFF_DECAY_PER_ROUND := 1
```

new:
```
## swap threshold and there is nowhere left to swap to. One per round off duty
## mirrors one per hit on duty. docs/15 BL-84 (which also records: no cap).
const TANK_DEBUFF_DECAY_PER_ROUND := 1
```

## 4. sim/core/RaidSim.gd:99

Q-M01b → BL-85 (the 'write-up was lost' sentence is no longer true).

old:
```
## question held for a designer. The write-up was lost with the plan file that
## carried it and has no `docs/15` row yet; audit `M6-BAL-03` owns the ruling,
## and `tests/unit/test_tutorials.gd` pins the measurement either way.
```

new:
```
## question held for a designer: docs/15 BL-85 records it (the ship plan's
## designer table, §6 rows #1 and #9, asks it); audit `M6-BAL-03` owns the
## ruling, and `tests/unit/test_tutorials.gd` pins the measurement either way.
```

## 5. sim/core/RaidSim.gd:113

Q-M11 → BL-88 / BL-93.

old:
```
## Warrior". The Warrior is the tank in every canon composition, so a reading
## that spares the tank contradicts the row's own second column.
const FRONTAL_CLEAVE_INCLUDES_TANK := true
```

new:
```
## Warrior". The Warrior is the tank in every canon composition, so a reading
## that spares the tank contradicts the row's own second column. docs/15 BL-88;
## who counts as "in front" is BL-93 (the one melee predicate).
const FRONTAL_CLEAVE_INCLUDES_TANK := true
```

## 6. sim/core/RaidSim.gd:122

Q-M10 → BL-87.

old:
```
## contradict the documented model, so the drain stays off and is written up as
## its own subsystem in build/plan/handoff-mech-arms.md.
const MANA_BURN_DRAIN_ENABLED := false
```

new:
```
## contradict the documented model, so the drain stays off: docs/15 BL-87
## (M10 ships as a Silence; Focus and the drain half are post-1.0 in writing).
const MANA_BURN_DRAIN_ENABLED := false
```

## 7. sim/core/RaidSim.gd:127

Q-M12 → BL-89.

old:
```
## rather than every round. Twenty lines of "the swing is bigger" is a wall, not
## a story beat; the swing itself grows every round regardless.
const ESCALATION_ANNOUNCE_EVERY := 5
```

new:
```
## rather than every round. Twenty lines of "the swing is bigger" is a wall, not
## a story beat; the swing itself grows every round regardless. docs/15 BL-89.
const ESCALATION_ANNOUNCE_EVERY := 5
```

## 8. sim/core/RaidSim.gd:297

Q-M07 → BL-82 (the stance default).

old:
```
        # docs/07 OQ-7's abstract position model (build/plan/q-mech-arms.md):
```

new:
```
        # docs/07 OQ-7's abstract position model (docs/15 BL-82):
```

## 9. sim/core/RaidSim.gd:1178

Q-M01 → BL-84 (the decay site).

old:
```
    # The debuff decays off duty (build/plan/q-mech-arms.md Q-M01): docs/10 says
```

new:
```
    # The debuff decays off duty (docs/15 BL-84): docs/10 says
```

## 10. sim/core/RaidSim.gd:1257

Q-M05 → BL-83 (the effect site).

old:
```
## authoring gap rather than an invisible invented one. See
## build/plan/q-mech-arms.md Q-M05 and the E4 request in handoff-mech-arms.md.
```

new:
```
## authoring gap rather than an invisible invented one. See docs/15 BL-83
## and audit m6-e4-m05-effect (E4's missing effect block).
```

## 11. sim/core/RaidSim.gd:1286

Q-M07 → BL-82 (the positioning site).

old:
```
## abstract position model (docs/07 OQ-7, build/plan/q-mech-arms.md Q-M07), and
```

new:
```
## abstract position model (docs/07 OQ-7, docs/15 BL-82), and
```

## 12. sim/core/RaidSim.gd:1540

W5-SIM's scripted-mistake pick → BL-92.

old:
```
## build/plan/q-W5-SIM.md records the choice.
static func _pick_forced_mistake_slot(rng, round_no: int, combatants: Array) -> int:
```

new:
```
## docs/15 BL-92 records the choice.
static func _pick_forced_mistake_slot(rng, round_no: int, combatants: Array) -> int:
```

## 13. sim/core/RaidSim.gd:1696

Q-M03 → BL-86 (the fire exit).

old:
```
            # rule — build/plan/q-mech-arms.md Q-M03 is the proposal, and this
            # is the only reading content can parameterise.
```

new:
```
            # rule — docs/15 BL-86 records it, and this
            # is the only reading content can parameterise.
```

## 14. sim/core/Mistakes.gd:37

W5-SIM's rate → BL-90 / BL-91.

old:
```
## the number; 0.5 is the
## build loop's choice, written up as a proposed docs/15 entry in
## build/plan/q-W5-SIM.md. Applied to the gate chance only — the taxonomy, the
```

new:
```
## the number; 0.5 is the build loop's choice, recorded as docs/15 BL-90 (the
## number itself is the designer's — the ship plan's §6 row #57 asks it; BL-91
## records what the halving did to the Tutorial Raid's pin). Applied to the gate
## chance only — the taxonomy, the
```

## 15. sim/core/Mistakes.gd:479

W5-SIM's forced-mistake shape → BL-92.

old:
```
## The choices are written up in build/plan/q-W5-SIM.md.
```

new:
```
## The choices are docs/15 BL-92.
```

## 16. sim/core/RaidSim.gd:139

W6-SIM-CASCADE's culprit row landed in docs/15 as BL-107 (applied by W6-LEDGER in-wave from `handoff-W6-SIM-CASCADE.md` §1 — see the note below); the comment can cite it.

old:
```
## `_wipe_cause` (ship plan §6 / the BL row handed to W6-LEDGER): the last
```

new:
```
## `_wipe_cause` (ship plan §6 row #61; docs/15 BL-107): the last
```

## Note for the orchestrator — handoff-W6-SIM-CASCADE.md §1 is ALREADY APPLIED as BL-107; do not run it

W6-LEDGER applied that handoff's docs/15 row in-wave (BL-107, `docs/15-open-questions.md` §10, after BL-106) and W6-LOG's two `q-W6-LOG.md` rows as BL-108 / BL-109. Their §1's `old:` anchor is the `## Related documents` tail, which survives the insert, so `apply_handoff.py handoff-W6-SIM-CASCADE.md` would insert a SECOND copy with a literal `BL-nnn` id. Skip that edit (`--only` with the other numbers, or leave the file unrun — it has one edit). `handoff-W6-LOG.md` carries no exact edits.

## Note for the orchestrator — spec 00 §2.7 (the switch register); a note, not a numbered edit

The ship plan's §0.5 says W6-LEDGER records the plan's switches in spec 00 §2.7 as well as in docs/15; spec 00 is not in W6-LEDGER's ownership list, so this is a note rather than an old/new block. The one switch that LANDED this wave is `Recruitment.PRICE_SCALE = "doc11"` (docs/15 BL-94); the other §0.5 switches belong to the waves that land them and their units record them. Add one row to §2.7's table: `Recruitment.PRICE_SCALE` — `"doc11"` — `[15, 60, 160, 420, 1000]`; `"doc04"` keeps `[60, 180, 450, 1100, 3000]` — BL-94 / the designer page's row #63. Two more rows from the same wave, named by their units' handoffs: `LogPlayer.COLLAPSE` — `true` — docs/15 BL-109 (W6-LOG); `RaidSim.WIPE_CULPRIT_DELTA` — `-4` — docs/15 BL-107 (W6-SIM-CASCADE).
