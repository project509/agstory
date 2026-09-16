# Review — W4-LIFE (the camp walks, the sails turn, the gulls cross, the lanterns flame)

Brief look (user rule 2026-09-14): one look that the new thing shows, then move on.

## Shots (build/shots/, viewed)

- `review-W4-LIFE.a/.b.png` — `MainMenu --frames=1,60`. 72988 px differ; the windmill box (1240,270,1400,490) 5554.
  Crop `review-W4-LIFE_mills_ab.png` (3x): the upper mill's sail X turned clockwise, the lower's counter, no seam
  under either — the patched plate is hidden by the rotors. A gull sits over the harbour foam at ~(1445,900).
  Chrome (title, five buttons, "No saved guild found.", version) intact; nothing off the frame.
- `review-W4-LIFE-town.a/.b.png` — `Town --fixture --frames=1,60`. 132342 px differ; the walker band
  (300,470,720,600) 18789. Crop `review-W4-LIFE-town_walk2_ab.png` (2x): the grey-haired walker a few px further
  right with a foot lifted, the dark-haired one lower on the grass by the crates, the tent lantern's flame changes
  shape. The two banners hang at the top of the band (crop origins ~480,100 and ~830,55). No walker under a callout;
  no panel blank; the rail, the three-column bottom band and the right panel all intact.

## Tests

- `scratchpad/run_review_W4-LIFE.gd` (one-file runner) over `tests/unit/test_scene_stage.gd` through the lock:
  `REVIEW W4-LIFE TESTS 80 run, 0 failing [1688 ms]`.

## Tree

- `git status --porcelain`: the owned files as listed. Outside the plan's Owns line but this unit's by the report:
  `art/src/bg/stage_town_raw.png` (J2, the pristine plate the recorded patch step needs), `game/assets/actors/actors.json`
  and the six `*_walk.png` + `.import` (gen_actors.py outputs, J4). Both are generator outputs, not hand edits of
  another unit's file.

## Notes (minor)

- The life strips sit in `game/assets/vfx/life/` rather than `game/assets/vfx/` (J1, because test_vfx_assets.gd /
  vfx.json belong to W1-VFX); the handoff carries the move recipe. Fine as shipped.
- Two handoff edits wait for the orchestrator (build_art.sh's patch_plate --check gate; MainMenu.gd's _build comment).
- The Town walks are short (J7) — the callouts leave only two clear patches of dirt; visible but subtle at 60 frames.

## Verdict

PASS — the headline change shows in both shots (sails turn, gull present, walkers move, flames flicker, banners
placed), the unit's test file is 80/0, and the tree parsed for the shot runs.
