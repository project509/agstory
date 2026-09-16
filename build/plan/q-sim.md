# Proposed docs/15 entries — sim/comedy-pipeline slice

Do not paste these into `docs/15-open-questions.md` directly; the orchestrator merges.

---

## Q-01 rider — "does AC apply to raid-wide damage?" is now implemented, not just proposed

**Where it lives today:** `docs/15-open-questions.md:97` (the rider under Q-01) and
`docs/10-content-and-encounters.md:189`'s `❓ OPEN` block in §5.4, which is cross-referenced
from §10's M02 row (`docs/10:459`, "ignores AC (❓ §5.4)") and flagged as docs/10 §14 #3.

**Status change to record:** the rider's proposed answer — *raid-wide and spell damage ignore
AC* — was never in the code. `sim/core/Formulas.raid_wide_damage()` carried the docstring
"Raid-wide and spell damage bypass armour (docs/10 §5.4)" and returned the raw number
unchanged, and `RaidSim` then routed that number through `_apply_damage`'s AC path, so the
pulse was mitigated after all. `data/encounters_t1.json` has carried `"ignores_ac": true` on
every M02 spec since it was authored, and `tests/unit/test_encounters.gd:127` asserted the
flag — but no file under `sim/` read it.

As of this pass the pulse bypasses armour:

- **The switch:** `spec.params["ignores_ac"]` per M02 spec, read in
  `sim/core/RaidSim._apply_scheduled_mechanics`'s RAID_WIDE branch. Default when the key is
  absent is `true`, i.e. the documented assumption. Setting it `false` on an encounter
  restores the old AC-mitigated pulse for that encounter only.
- **The mechanism:** `RaidSim._apply_damage(..., ignores_ac: bool = false)`. Default `false`,
  so every other damage source is byte-identical; only the M02 branch passes `true`.
- **The test:** `tests/unit/test_raid_sim.gd::test_the_raid_wide_pulse_bypasses_armour`
  (a roster spanning several AC values all take the pulse's raw value) plus
  `test_an_ordinary_boss_swing_still_scales_with_armour` for the negative half.

**Suggested wording for the rider:** append *"DECIDED and implemented under R3: raid-wide
damage ignores AC. Switch: `params.ignores_ac` per M02 spec (default true), read in
`sim/core/RaidSim._apply_scheduled_mechanics`. Spell damage is a separate half of this rider
and is still unimplemented — `Formulas.spell_damage_total` output goes to enemies, which have
no AC, so nothing exercises it yet."*

**Balance consequence, for the record:** the pulse got harder everywhere it appears (E2, E3,
E5 in Tier 1). It did not move a single clear-rate cell on its own, because the same pass
removed a duplicate add spawn that was pushing the other way — see the delta table in the
slice report. Do not read the flat clear rates as "the AC fix was free".

---

## M04 vs `spawn_round`: which one owns an add spawn — a ruling worth recording

Not currently a numbered docs/15 question, and it probably should be one.

**The ambiguity:** `docs/10 §6`'s encounter template gives an `EnemyBlock` a `spawn_round`
AND `docs/10 §10 M04` defines add spawning as a mechanic ("`count` adds of `hp`/`swing` on
round `R`, repeating every `N`"). Nothing in the doc set says what happens when both target
the same round, and Tier 1's data configures both for the same round on E1, E2 and E3 — so
the shipped game spawned adds twice (E1 round 5: two adds where the card promises one; E2
round 4: six).

**Ruling taken here, from the doc rather than from convenience:** M04 owns it. `docs/10 §6`
prices one mechanic per star and the star is what the encounter card promises the player, and
`docs/10 §10` is explicit that content *configures* a mechanic docs/07 implements once. An
authored block scheduled onto a round M04 also fires is therefore a duplicate and stays
inactive for the whole fight; a block on a round M04 does *not* fire still arrives, because
that is a scripted reinforcement rather than a duplicate.

**Suggested question text:** *"Can an encounter author schedule an add through
`EnemyBlock.spawn_round` when the encounter also carries M04? Proposed default: no — M04 owns
add spawning, and `sim/model/Encounter.from_dict` should reject the pair on load rather than
letting `RaidSim` silently suppress one of them."*

The suppression is currently in `sim/core/RaidSim._spawn_scheduled`, which is the wrong place
for it long-term: a bad encounter should fail to load, not quietly behave. The load-time
validation and the data cleanup are requested in `build/plan/handoff-sim.md`.

---

## Rider on the rider — what `ignores_ac: false` actually does, and what §5.4 says it should

Correcting my own switch note above. docs/10 §5.4 offers exactly two readings, and
the switch's OFF position is neither of them:

- **ON (`true`, the default):** raid-wide damage ignores AC. The authored 26/27/28
  land raw. This is §5.4's stated assumption and what ships.
- **§5.4's alternative:** *"if AC does apply, use doc 08 §9.5's grossed-up raw
  (33 → 41) instead and every M02 magnitude in §7 changes with it."*
- **OFF (`false`, as implemented):** re-applies AC to the authored 26/27/28. That
  is a **third** behaviour the doc does not describe — a strictly weaker pulse,
  not the doc's alternative — and it is only there because it is the old,
  pre-fix code path.

Per the project's switch rule the off position should either gross the magnitude
up per §9.5 or say plainly that it does not implement the alternative reading.
It cannot gross up without a per-encounter grossed-up magnitude, and inventing
one would be inventing a number, so the honest form is the second: **`ignores_ac:
false` is a regression switch, not §5.4's alternative reading.** If §5.4 is ever
DECIDED the other way, the work is authoring the grossed-up magnitudes in
`data/encounters_t1.json`, not flipping this flag.

**Suggested wording for the rider:** append *"The `false` position of
`params.ignores_ac` re-applies AC to the authored magnitude and is a regression
switch only; §5.4's alternative reading (AC applies, magnitudes grossed up per
doc 08 §9.5) is NOT implemented and would need new authored magnitudes."*

---

## A ruling I took against the audit's prescription: which tier a dev note lives at

`audit.json`'s `m5-mechanic-dispatch-guard` `remaining_work` asks for the
unimplemented-mechanic note at `Enums.LogTier.NUMBERS`. It ships at
`LogTier.DEBUG` instead, because docs/07 §10.2 is explicit about what those two
tiers are for: tier 2 Numbers is *"players who want to tune gear"* — and
`game/screens/RaidView.gd:302-309` really does draw a Numbers button for them —
while tier 3 Debug is *"dev builds and bug reports only"*. A line reading
"Fixate (m08) is configured but has no behaviour in the sim yet" is a note about
the sim, not about the fight, so on the doc's own definitions it is tier 3. docs/
is canon and the audit is a plan, so the doc won.

Consequence for anyone reading the note: it is invisible in the running game (no
Debug verbosity button exists) and visible in `log.transcript(LogTier.DEBUG)` and
in `full_log_sha256`. `tests/unit/test_raid_sim.gd::_assert_no_player_tier_shows`
pins both halves — absent from all three player-selectable tiers, present at
Debug. No docs/15 entry proposed; this is a doc being followed, not an ambiguity.
