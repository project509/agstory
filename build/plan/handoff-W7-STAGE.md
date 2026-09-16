# handoff-W7-STAGE

Edits this unit needs in files it does not own (00-plan §0.2). §1-§3 are the three `SceneStage.DEFAULT_ARENA` sites becoming `SceneStage.arena_for(encounter)` (Q-96, CRITIC-C15; `arena_for` lands in `game/ui/SceneStage.gd` this wave, so each line compiles the moment it is applied). §4 is the Q-96 row's status cell in docs/15 (RULINGS §5.2's text; W7-DOCS may land it first — then the dry run reports it SKIPPED/ALREADY APPLIED and nothing is lost). The orchestrator applies all four at the close.

`arena_for` takes the screen's encounter (an `Encounter`, or null → `DEFAULT_ARENA`), so every site passes the field the screen already resolves: RaidPrep's `_encounter` (set in `_resolve_encounter()`, before `_build()`), RaidView's `_encounter`, Results' `_encounter` (set at :419 from `last_result`, before `_stage()`).

## 1. game/screens/RaidPrep.gd:280
The prep stage is the arena the encounter fights in (SPACES). Two lines, one heading: W7-PREP is editing this file in-wave, so the anchor is the two `DEFAULT_ARENA` lines with the `arena_view` line between them, wherever they sit at the close.
old:
```
    var m := SceneStage.marks(SceneStage.DEFAULT_ARENA)
    var view := arena_view(m, host.size)
    var stage := SceneStage.load(SceneStage.DEFAULT_ARENA)
```
new:
```
    var arena := SceneStage.arena_for(_encounter)
    var m := SceneStage.marks(arena)
    var view := arena_view(m, host.size)
    var stage := SceneStage.load(arena)
```

## 2. game/screens/RaidView.gd:467
The fight's stage is the arena the encounter fights in (TABS).
old:
```
	var stage := SceneStage.load(SceneStage.DEFAULT_ARENA)
	var m := SceneStage.marks(SceneStage.DEFAULT_ARENA)
```
new:
```
	var arena := SceneStage.arena_for(_encounter)
	var stage := SceneStage.load(arena)
	var m := SceneStage.marks(arena)
```

## 3. game/screens/RaidView.gd:512
The party's formation reads the same arena's marks (TABS).
old:
```
	var party = SceneStage.marks(SceneStage.DEFAULT_ARENA).get("party", null)
```
new:
```
	var party = SceneStage.marks(SceneStage.arena_for(_encounter)).get("party", null)
```

## 4. game/screens/Results.gd:196
The report stands on the arena the fight was in (SPACES).
old:
```
    var stage := SceneStage.load(SceneStage.DEFAULT_ARENA)
    stage.position = ARENA_OFFSET
```
new:
```
    var stage := SceneStage.load(SceneStage.arena_for(_encounter))
    stage.position = ARENA_OFFSET
```

## 5. docs/15-open-questions.md:586
Q-96's status cell: the ruling (RULINGS §5.2), verbatim but for the tense of the handoff lines.
old:
```
| **Proposed:** a `backdrop` key on each encounter record, authored per fight, defaulting to the cave. Until it is authored, RaidPrep, RaidView and Results all name ONE arena in a single constant (`ARENA_SCENE`) rather than guessing a mapping for eight encounters — a wrong mapping is worse than an honest repetition, because it looks deliberate. Needs the designer to say whether the backdrop belongs to the ENCOUNTER (this boss lives in a dungeon) or to the RAID (a raid is one location, five fights) |
```
new:
```
| **RESOLVED (2026-09-15): the arena belongs to the RAID.** `SceneStage.arena_for(encounter)` is the one rule: the tier row's `scene` (per kind, `{"adventure": …, "raid": …}`) if `data/tier_words.json` names it, else raid encounters (E1-E5) in `stage_arena_dungeon` and adventures and tutorials (A0, TR, A1-A3) in `stage_arena_cave`; the three `DEFAULT_ARENA` sites became `arena_for` lines (W7-STAGE); no `backdrop` key on encounter records (this row's own proposal is superseded — a per-encounter key is a second truth for a fact the kind carries); the bed follows the same function. Fighting TR in the cave keeps the dungeon as the thing Raid 1 earns. Tiers 2-5 inherit the kind rule until a tier row names a plate; M4B-CONV-04 closes — ruled by the loop under the designer's 2026-09-15 delegation |
```
