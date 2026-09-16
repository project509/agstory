# Handoff — W1-STAGE (key `W1-STAGE`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Observations (no edit) are labelled as such.

(appended as the unit goes; empty means nothing was needed so far)

## Observation (no edit) — W2-TOWN: the Town callouts were measured against 1x bodies; at `figure_scale 2` they sit on figures
Measured from stage_camp.json at 2x against Town.gd's callout `at` positions (screen) + CAMP_OFFSET (-46,-62), 232x96 plates, plate pixels:
- Tavern callout plate rect (686,252)-(918,348) overlaps the cleric body (764..830 x 345..427), the mage (659..721 x 284..366) and the rogue (735..785 x 264..340).
- Market callout plate rect (906,476)-(1138,572) overlaps variant_r03_brown (1037..1083 x 553..625) and variant_r05_grey (1126..1174 x 560..640).
- Board callout plate rect (466,642)-(698,738) overlaps rogue_b (537..595 x 684..762).
- The speaking bubble now hangs over cleric_b (`speech.speaker: 4`, plate (364..546 x 445..521)); the Guildhall callout (270..502 x 354..450) overlaps its top 5 rows.
TOWN-07's two actor moves are in (rogue -> (760,340), brown variant -> (1060,625)); the remaining collisions are the callouts' to move (TOWN-07 fix option A: Tavern -> (640,150), Market -> (860,440), or re-measure all five against the 2x boxes above). Nothing in Town.gd was touched by this unit.

## Observation (no edit) — W2-MARKET / W2-TAVERN: `speech.speaker` exists; the market's line has no speaker yet
`SceneStage` now honours `speech.speaker` (an index into the scene's `actors`, authoring order): the speaking bubble's bottom-centre hangs 28px (`SAY_AIR`) above that figure's head. stage_camp.json names 4 (cleric_b by the tents) and stage_tavern.json names 12 (variant_r06_black at (1066,656)); stage_market.json's bubble at (960,780) is >190px from every head (nearest: warrior at (1232,858)) and is left on `pos` — pick its speaker when the market's crowd is re-placed (STAGE-15). W2-STAGE2 passes `tail_at` (Widgets.speech_plate's second argument) from the same anchor.

## Observation (no edit) — orchestrator: three wave-1 handoffs aimed at this unit's files are already applied
- handoff-W1-VFX.md §1 (stage_tavern.json `frame_w` 48 -> 64): in the tree (the first W1-STAGE agent's edit).
- handoff-W1-KIT.md §10 (SceneStage builds ambient bubbles through `Widgets.speech_bubble("dots", glyph)` and adds no dots of its own) and §11 (the private `Ellipsis` class deleted): applied by W1-STAGE on 2026-09-14 16:50 — the double "..." was in this unit's own Town acceptance shot. Their `old:` blocks will no longer match; nothing left to do.
- handoff-W1-CHROME.md §17 (SceneStage.gd `Color("#3B2F27")` -> `Palette.INK_BUBBLE_DOTS`): applied, then the line went with the Ellipsis class (§11 above). `grep -n 'Color("' game/ui/SceneStage.gd` is empty.
- The ambient bubbles of stage_camp/stage_tavern/stage_market are re-authored to the kit's 40x44 emote frame (tail apex 6px above the head, on the head's centre line); `tests/unit/test_scene_stage.gd::test_every_ambient_bubble_hangs_over_a_head` reads the REAL frame size, so a later change to `PanelEmote`'s texture fails that test and the JSONs are the place to re-author.
