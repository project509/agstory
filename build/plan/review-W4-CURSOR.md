# Review — W4-CURSOR — the pointer and the outline

Reviewer: brief look, 2026-09-15. Verdict: **PASS** (with notes).

## Shots (build/shots/)

- `review-W4-CURSOR.png` — `Town --fixture --focus --tab=1` (1536x1024). The Guildhall callout carries a
  2px light-gold ring hugging the chamfered plate and wrapping the tail to its apex; inside it the theme's
  2px steel `focus` ring sits on the "Guildhall" title Button — both rings show, neither replaces the other
  (`review-W4-CURSOR-crop4x.png`, plate window 340,150 200x120 at 4x). Nothing overlaps, no text off the
  frame, no blank panel; the rest of the hub (rail, sidebar, roster strip, events) is as before.
- `review-W4-CURSOR-tab8.png` — the plan's literal `--tab=8`: the shot log prints `TAB 8 -> Nav_home` (rail),
  and the Guildhall plate shows NO ring at rest (`review-W4-CURSOR-tab8-crop4x.png`). This confirms the
  report's J4 (Town has 4 shell regions; Tab steps region to region) and that the outline is off when the
  callout is neither focused nor hovered.
- `review-W4-CURSOR-cursors8x.png` — the two 32x32 PNGs at 8x: cream arrow and pointing hand, 1px warm-dark
  ink, soft shadow down-right, one family. Tips at (1,1) / (12,1) with air above.

## Tests

- `scratchpad/run_review_W4-CURSOR.gd` (run_tests.gd's loop pinned to `tests/unit/test_w4_cursor.gd`):
  `TESTS PASSED 8 test(s) in 1 file(s) [160 ms]`. 8/8.
- Full suite / verify.sh not run here (orchestrator's gate). The report's verify --fast: 2/1942 failing, both
  in W4-PIP's untracked `test_pip_figure.gd` — not this unit's.

## Files

- Owned, modified (all additive): `tools/aseprite/gen_ui.lua` (+93), `project.godot` (+8, `[display]`
  mouse_cursor only), `game/ui/Widgets.gd` (+89), new `game/ui/shaders/outline.gdshader`,
  `game/assets/ui/cursor_arrow.png`/`cursor_hand.png` + `.import`.
- Outside the owned list but clearly this unit's (report says so): `tests/unit/test_w4_cursor.gd` (+.uid),
  `art/src/ui/cursor_arrow.aseprite`, `cursor_hand.aseprite` (LUA sources, rule 10), `outline.gdshader.uid`,
  `scratchpad/run_W4-CURSOR.gd`. Nothing reverted or reformatted.

## Notes (minor, no action requested)

- The hand cursor is not live until the orchestrator applies `handoff-W4-CURSOR.md` §1-§2 (Boot.gd
  `Input.set_custom_mouse_cursor`); only the arrow ships through project.godot. Expected by the plan's ownership.
- The plan's Shot line (`--tab=8`) does not reach a callout on Town; the unit's `--tab=1` is the right
  evidence. Worth a one-line fix in 00-plan.md by whoever owns it.
- Callout plate body is still not clickable (Town wires the title Button only) — the hover outline lights on
  the plate, which reads as an affordance. Observation carried in the handoff; a later-wave decision.
