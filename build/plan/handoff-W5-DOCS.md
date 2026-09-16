# handoff — W5-DOCS

Exact edits in files this unit does not own. Apply with
`python tools/apply_handoff.py build/plan/handoff-W5-DOCS.md` (`--dry-run` first). Every
edit repoints a comment or note at a register entry docs/15 now declares (BL-79, BL-80,
BL-81; BL-59 corrected), or retires an exemption the fix made unnecessary. None changes
behaviour. Edits 1-3 (`game/core/GameState.gd`) and 4-6 (`data/reputation.json`) are in
W5-TESTS's files this wave; 7-9 (`sim/content/MistakeLines.gd`), 10 (`tests/unit/test_docs_links.gd`),
11 (`BUILD_STATE.md`, W5-TOOLS's), 12 (`docs/16`, outside this unit's two-pointer remit)
and 13-14 (`sim/core/Reputation.gd`) are the rest. Indentation: GameState.gd and MistakeLines.gd are four-space files; every
block below is a column-0 comment.

## 1. game/core/GameState.gd:893

The onboarding pointer the audit (M5-TUT-08) names. docs/15 declares BL-79 now, so
`test_every_register_citation_resolves_to_a_declared_entry` accepts the citation.

old:
```
## has not yet seen the game, not to reward clearing. Proposed docs/15
## build-loop entry in build/plan/q-tutorials.md.
```
new:
```
## has not yet seen the game, not to reward clearing. Recorded as docs/15
## BL-79 (promoted from build/plan/q-tutorials.md, 2026-09-15).
```

## 2. game/core/GameState.gd:1162

BL-59 row 2 now records the `BENCH_BREAKS_WIPE_STREAK` reading (from q-quirks BL-NEXT+7).

old:
```
## AMBIGUITY, BEHIND A SWITCH (house rule; proposed docs/15 entry in
## build/plan/q-quirks.md). The doc says "with them in the raid" and says nothing about a
```
new:
```
## AMBIGUITY, BEHIND A SWITCH (house rule; recorded in docs/15 BL-59, row 2,
## 2026-09-15). The doc says "with them in the raid" and says nothing about a
```

## 3. game/core/GameState.gd:1771

BL-59 now records the three readings of "triggered" and why (ii) ships.

old:
```
## AMBIGUITY, BEHIND A SWITCH (proposed docs/15 entry in build/plan/q-quirks.md).
```
new:
```
## AMBIGUITY, BEHIND A SWITCH (recorded in docs/15 BL-59, 2026-09-15).
```

## 4. data/reputation.json:5

`_notes[0]` cited Q-95 (the PowerShell ruling) for the format; the entry actually created is
BL-81. Line endings and the trailing comma stay as they are.

old:
```
    "FORMAT (docs/15 Q-95, proposed in build/plan/q-tuning.md): JSON, not the `.tres` docs/03 §9 proposes. docs/14 §5.1's own deciding row is 'Readable by sim/ without breaking §3 — .tres: No, requires ResourceLoader, which sim/ is forbidden to call', and the consumers here are sim/core/Reputation.gd and sim/core/Recruitment.gd. docs/15 Q-94's '.tres for tuning singletons' survives for the game/-side singletons §5.1 lists beside this one (the UI Theme); it does not reach a table the pure sim reads.",
```
new:
```
    "FORMAT (docs/15 BL-81): JSON, not the `.tres` docs/03 §9 used to propose. docs/14 §5.1's own deciding row is 'Readable by sim/ without breaking §3 — .tres: No, requires ResourceLoader, which sim/ is forbidden to call', and the consumers here are sim/core/Reputation.gd and sim/core/Recruitment.gd. docs/15 Q-94's '.tres for tuning singletons' survives for the game/-side singletons §5.1 lists beside this one (the UI Theme); it does not reach a table the pure sim reads.",
```

## 5. data/reputation.json:6

`_notes[1]` pointed at the parked proposal and the handoff; both now stand in the register
and in docs/03 §9 itself.

old:
```
    "SCHEMA: §9's fence was written before docs/15 BL-35 and BL-37 changed the award tables, so six of its keys no longer describe the code. The reconciliation, divergence by divergence, is in build/plan/q-tuning.md; the corrected fence is in build/plan/handoff-tuning.md. In short: the content gate is tiers rather than an id list (docs/15 §2.3 closed rank->tier gating in §7's favour and had doc 10 delete its rival table); the one `awards` dictionary is four tables because BL-37 split an Adventure across three rungs and §6.2 multiplies only the raid table; `full_tier_bonus` keeps the repeat value BL-35 deliberately preserved.",
```
new:
```
    "SCHEMA: §9's fence was written before docs/15 BL-35 and BL-37 changed the award tables, so six of its keys no longer described the code. The reconciliation, divergence by divergence, is docs/15 BL-81; docs/03 §9's fence is the corrected one (2026-09-15). In short: the content gate is tiers rather than an id list (docs/15 §2.3 closed rank->tier gating in §7's favour and had doc 10 delete its rival table); the one `awards` dictionary is four tables because BL-37 split an Adventure across three rungs and §6.2 multiplies only the raid table; `full_tier_bonus` keeps the repeat value BL-35 deliberately preserved.",
```

## 6. data/reputation.json:7

old:
```
    "SCOPE: this file carries what docs/03 §9's fence claims, plus the three §8.1 scalars §9 forgot (stall_attempts, catchup_enabled, pity_min_rank) — each stated in §8.1's own prose, and pity_min_rank is the other half of the same two-number M2 rule §9 already carries half of. It does NOT carry docs/04's cost, experience or gear tables: see build/plan/q-tuning.md's boundary ruling.",
```
new:
```
    "SCOPE: this file carries what docs/03 §9's fence claims, plus the three §8.1 scalars the first draft forgot (stall_attempts, catchup_enabled, pity_min_rank) — each stated in §8.1's own prose, and pity_min_rank is the other half of the same two-number M2 rule §9 already carried half of. It does NOT carry docs/04's cost, experience or gear tables: docs/15 BL-81's boundary ruling.",
```

## 7. sim/content/MistakeLines.gd:28

The measurement the comment quoted was from a golden regenerated under BL-71; these are the
counts off the committed goldens (2026-09-15, `MISTAKE` header lines per type), and the
ruling now has a register id.

old:
```
## docs/07 §10.3 rule 4 and docs/14 §5.4 assertion 7 both say six. Six is not
## enough, and the goldens say so: `e1_commons_starting` fires "Forgot to Taunt"
## TWELVE times inside one 22-round encounter, and `e5_miserable_commons` fires
## "Went AFK" and "Attacked the Wrong Target" eleven times each in fourteen
## rounds. At six variants the player watches the same sentence twice in a fight
## they are watching tonight, which is docs/07 §5.5's own failure mode — it
## "reads as a bug, not a joke".
##
## So the floor stays, because two docs assert it, and a second constant carries
## the measured need. The ambiguity is a switch rather than a silent overrule;
## the ruling is written up in `build/plan/q-comedy.md` for docs/15.
```
new:
```
## docs/07 §10.3 rule 4 and docs/14 §5.4 assertion 7 both say six. Six is not
## enough, and the goldens say so (re-measured 2026-09-15 off the committed
## files): `e1_commons_starting` fires "Forgot to Taunt" TWELVE times inside one
## 22-round encounter (54 mistakes), `e3_commons_adventure` fires "Pulled Aggro
## Off the Tank" eleven times in 21 rounds, and `e5_miserable_commons` (11
## rounds, 44 mistakes) fires "Dropped a Mechanic" and "Pulled Aggro" seven
## times each. At six variants the player watches the same sentence twice in a
## fight they are watching tonight, which is docs/07 §5.5's own failure mode —
## it "reads as a bug, not a joke".
##
## So the floor stays, because two docs assert it, and a second constant carries
## the measured need. The ambiguity is a switch rather than a silent overrule;
## the ruling is docs/15 BL-80 (promoted from `build/plan/q-comedy.md`).
```

## 8. sim/content/MistakeLines.gd:42

All eight hot types are measured now; the "forecast pair" fires in `e5_miserable_commons`.

old:
```
## The eight types that need `HOT_VARIANTS`. Six of them are measured: every one
## fires five or more times inside a single shipped golden. `MIS_FIRE` and
## `MIS_MECHANIC_DROP` are the forecast pair — both are ungated by class and role
## and both sit at weight 8-9, so they are rare today only because Tier 1's
## mechanic checks are thin, and they go hot the moment docs/10's tier-2
## encounters land. Writing their fourteen now is cheaper than noticing later.
```
new:
```
## The eight types that need `HOT_VARIANTS`. All eight are measured: every one
## fires five or more times inside a single shipped golden (docs/15 BL-80 has
## the counts). `MIS_FIRE` and `MIS_MECHANIC_DROP` were written in as a forecast
## — ungated by class and role, weight 8-9, rare only while Tier 1's mechanic
## checks were thin — and `e5_miserable_commons` now fires them 6 and 7 times.
```

## 9. sim/content/MistakeLines.gd:52

old:
```
## docs/07 §10.3 rule 4's second sentence: "Legendary raiders get their own
## variants". Four each — `e5_legendaries_raid` records two mistakes across
## seventeen rounds, so four is already several fights' worth.
```
new:
```
## docs/07 §10.3 rule 4's second sentence: "Legendary raiders get their own
## variants". Four each — `e5_legendaries_raid` records four mistakes across
## twenty rounds, so four lines is already several fights' worth (docs/15 BL-80).
```

## 10. tests/unit/test_docs_links.gd:29

DW-A2 is closed: the registers were split, every id carries an explicit `<a id>` (BL-78's
was the last one missing and is added this wave), and the `](#)` is gone from docs/15. A
Python walk mirroring `test_link_fragments_resolve` with NO allowances finds zero dead
fragments across docs/ and art/ref/specs/, so the exemption row is retired and any future
dead fragment in docs/15 fails by name.

old:
```
# Fragments that are knowingly dead and are not this file's to fix: docs/15's
# short `#q-nn` anchors, tracked as DW-A2 and blocked on DW-A3 (five of those
# IDs name two different decisions each, so pinning an anchor now would pin it
# to whichever collides first). The empty "" is docs/15's `](#)`.
const DEAD_FRAGMENTS_ALLOWED := {
    "res://docs/15-open-questions.md": ["", "q-31", "q-34", "q-38", "q-44", "q-50", "q-54"],
}
```
new:
```
# Fragments that are knowingly dead. Empty since DW-A2 closed (2026-09-15): the
# registers were split (DW-A3), every `Q-nn` / `BL-nn` in docs/15 carries an
# explicit `<a id>`, and its `](#)` was repointed at BL-31 — so a row here is a
# regression to explain, never a backlog item.
const DEAD_FRAGMENTS_ALLOWED := {}
```

## 11. BUILD_STATE.md:1

The note audit M5-COMEDY-13 (5) asks for, widened to the three entries this unit landed.
Insert before the "build ships when the CONTENT does" paragraph; if W5-TOOLS has moved
that paragraph, put it anywhere under "Current focus".

old:
```
**The build ships when the CONTENT does.**
```
new:
```
**Wave 5 docs (W5-DOCS, 2026-09-15):** docs/15 gained BL-79 (the tutorial skip fork and the
S09 skip panel, switch `RaidPlan.SKIPPED_TUTORIAL_STAYS_ON_BOARD`), BL-80 (the mistake-line
budget 6/14/8 and the one-file corpus, measured off the committed goldens) and BL-81
(`data/reputation.json` is JSON; docs/03 §9's fence is now the shipped shape, which the
key-parity test reads); BL-59 says three BIG-dumb conditions are live and records the
`BULLET_TRIGGER_COUNTS_CAPPED` reading. The parked proposals in `build/plan/q-tutorials.md`
(:86-140), `q-comedy.md` (BL-NEXT+11/+13) and `q-tuning.md` (BL-NEXT+0/+1/+3) are consumed;
`q-comedy.md`'s Q-NEXT+15 (the human read of the corpus) is still open and stays there.
Q-35's "Add both" is recorded in docs/09 §10.2/§13.1 as the build's 🔷 PROPOSED default;
the three off-hand rows are still audit `M5-T25-14`.

**The build ships when the CONTENT does.**
```

## 12. docs/16-production-roadmap.md:385

Audit M5-OQ-1's last clause: W3.7 cites "11 §10" (equipment upgrades) for the board; the
board is docs/11 §11. Outside this unit's docs/16 remit (the `.tres` pointer only), so it is
handed off rather than applied.

old:
```
| W3.7 | The quest / achievement board: five entry types, five reward kinds, no timers, no repeatables, hard-capped at ~15% of lifetime income so it can never substitute for playing content | 11 §10, 02 §4.4 | M |
```
new:
```
| W3.7 | The quest / achievement board: five entry types, five reward kinds, no timers, no repeatables, hard-capped at ~15% of lifetime income so it can never substitute for playing content | 11 §11, 02 §4.4 | M |
```

## 13. sim/core/Reputation.gd:24

The file's header cited the parked proposal for the format ruling and the six divergences;
both are docs/15 BL-81 now.

old:
```
## docs/03 §9's tuning file. JSON rather than the `.tres` §9 proposes, because
## docs/14 §5.1's deciding row is "readable by `sim/` without breaking §3" and
## `.tres` is not — it needs `ResourceLoader`, which `sim/` is forbidden to call.
## docs/15 Q-94's ".tres for tuning singletons" keeps the game/-side singletons
## §5.1 lists beside this one; it does not reach a table the pure sim reads. The
## reasoning in full, and the six schema divergences from §9's fence, are in
## build/plan/q-tuning.md.
```
new:
```
## docs/03 §9's tuning file. JSON rather than the `.tres` §9 used to propose, because
## docs/14 §5.1's deciding row is "readable by `sim/` without breaking §3" and
## `.tres` is not — it needs `ResourceLoader`, which `sim/` is forbidden to call.
## docs/15 Q-94's ".tres for tuning singletons" keeps the game/-side singletons
## §5.1 lists beside this one; it does not reach a table the pure sim reads. The
## reasoning in full, and the six schema divergences from §9's old fence, are
## docs/15 BL-81; §9's fence is the shipped shape now.
```

## 14. sim/core/Reputation.gd:613

old:
```
## `unlocks_building: Array[StringName]` instead, and that is deferred rather than
## refused: docs/02 owns the building ids and docs/03 §7 never names one, so a
## structured list would have to invent six sets of ids. See build/plan/q-tuning.md.
```
new:
```
## `unlocks_building: Array[StringName]` instead, and that is deferred rather than
## refused: docs/02 owns the building ids and docs/03 §7 never names one, so a
## structured list would have to invent six sets of ids. See docs/15 BL-81.
```

## 15. (note, no edit) tests/unit/test_game_state.gd:236

Not this unit's file and not an edit here — recorded because the wave's gate trips on it:
the working tree's `tests/unit/test_game_state.gd:236` reads `docs/04 §11.3 condition 4
(docs/15 Q-59)`. Condition 4 is BIG-dumb, which is **BL-59**; Q-59 is damage variance and
`MELEE_SWINGS`. `test_every_register_citation_resolves_to_a_declared_entry` refuses the
ambiguous form, and the fix is the one-word citation change in W5-TESTS's file (BL-59 is
declared, so no allow-list row is needed). The nine `Q-51` citations that tripped the same
test earlier in the wave were already rewritten by their unit before `verify --fast` ran.
