# handoff-W6-SIM-CASCADE — edits in files W6-SIM-CASCADE does not own

Applied by the orchestrator at the wave's close (the docs/15 row by W6-LEDGER, which owns docs/15 this wave). Each heading is one edit: an `old:` block and a `new:` block; `python tools/apply_handoff.py build/plan/handoff-W6-SIM-CASCADE.md --dry-run` parses it.

## 1. docs/15-open-questions.md:3815

One docs/15 row (the wipe's culprit rule behind `RaidSim.WIPE_CULPRIT_DELTA`, and doc 07 §6's parent tie-break), inserted before "## Related documents". W6-LEDGER owns docs/15 this wave and assigns the id: replace `BL-nnn` / `bl-nnn` with the next free number when applying. The same text is in `build/plan/q-W6-SIM-CASCADE.md`. Once it lands, `sim/core/RaidSim.gd`'s comment at `WIPE_CULPRIT_DELTA` ("the BL row handed to W6-LEDGER") can cite the id.

old:
```
## Related documents

Filenames are the canonical ones from [00 §1.1](./00-vision-and-pillars.md).
```
new:
```
<a id="bl-nnn"></a>
### BL-nnn - The wipe's culprit is the last Severe-or-worse mistake before the first tank or healer death, else the deepest cascade, else nobody; the −4 is queued by the sim and applied by the game *(🔷 PROPOSED - implemented behind a named constant)*

**Owner:** [01 §6.1, §6.4](./01-core-loop.md) / [07 §6](./07-combat-simulation.md) / [05 §7.1](./05-morale.md) - **Signal:** Silent - doc 01 names the number and never defines "the raider whose mistake triggered the wipe"

Doc 01 §6.1 gives "an extra −4 to the raider whose mistake triggered the wipe" and §6.4 wants a
post-mortem "naming the raider at fault, the specific mistake". `Morale.TRIGGERS["wipe_caused"]`
has carried the −4 since the morale ledger landed and nothing ever named a raider, because no
document says which mistake "triggered" a wipe. LOOP-12 proposed the rule; CRITIC-C12 put it in the
sim's cascade unit so the report reads a field that exists.

**Taken (W6-SIM-CASCADE, `sim/core/RaidSim.gd` `_wipe_cause`, `WIPE_CULPRIT_DELTA := -4`):** on any
loss (wipe, soft wipe, attrition) the sim names ONE log entry —

1. the LAST mistake of severity Severe or Critical logged before the first tank or healer is
   confirmed Dead ("Severe" reads as Severe-or-worse: a Critical is a worse Severe);
2. else the mistake with the deepest `cascade_depth` (ties to the later one);
3. else nobody — `wipe_cause` is empty, the verdict line stands alone, and the report is expected to
   say the boss simply won.

`SimResult.wipe_cause = {actor_id, mistake_type, round, entry_seq}`; the log's last Story line on a
loss is `wipe_cause` ("It traces back to Cindy — Healed a Corpse, round 4."); the culprit's entry in
`deltas_queued` carries `wipe_caused: 1`. The sim REPORTS (doc 14 OQ-10): `game/` fires the ledger's
`wipe_caused` trigger from that flag (W7-REPORT), and `tests/unit/test_raid_sim.gd` pins
`WIPE_CULPRIT_DELTA` equal to the trigger's delta so the number lives in one place.

**Also taken here, doc 07 §6 rule 1's parent when several tokens are live (SIM-05's default):** the
live token whose "Effect on later rolls" column names THIS roll — the actor's Fire/Adds for
`MIS_AVOIDABLE_DEATH`, the raid's Aggro for a healer's roll, the raid's Distraction for an ambient
roll — else the OLDEST live token on the actor, else the mistake is a root. Only the actor's own
tokens count in the fallback: a raid-wide fallback would put every miserable raid at depth 3 and,
through the depth cap, stop most tokens from being emitted. A Downed holder's token still counts
(§6's worked cascade gives Cindy her +8pp in the round Greg drops); a Dead holder's does not.

**Alternatives** (for the designer, ship plan §6): (a) the FIRST Severe of the fight rather than the
last before the death — blames the opening of the slide instead of its last step; (b) the mistake
with the most descendants — needs a graph walk and reads the same as (2) in practice; (c) the
raider who died first — a consequence, not a mistake, and often the tank taking a boss swing.

---

## Related documents

Filenames are the canonical ones from [00 §1.1](./00-vision-and-pillars.md).
```
