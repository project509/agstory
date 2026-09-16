# review-W4-PIP — the emoji-free figure is even, and the faces scale

Brief review (one look that the new thing shows). Shots and test taken under one lock hold
(scratchpad/batch_review_W4-PIP.sh); runner scratchpad/run_review_W4-PIP.gd.

## Shots (viewed with the Read tool)

- `build/shots/review-W4-PIP.png` — `Tavern --fixture --set=emoji_free=true`, SHOT OK 1536x1024.
  Whole screen sound: no overlap, nothing off the frame, no blank panel; the four seat cards, the
  bar panel, Recent Events and the footer all sit where they do at HEAD. The seat cards' "starts at
  46 |||||....." (crop `review-W4-PIP-crop-seats.png`, 3x) is STILL Fira's uneven figure — wide bars,
  tight dots. That is expected on the shipped tree: the site is Tavern.gd:527 on LabelSmall, which
  test_theme_kit pins to carry no fallback, so the plan's Tavern acceptance lands only when the
  orchestrator applies handoff-W4-PIP.md §1 (LabelSmall→LabelPip, one token; dry-run APPLIED #1/#2).
- The headline change on shipped sites: `build/shots/w4pip/crop_cards_before_after.png` (the
  implementer's Guildhall emoji crop; not a new shot) — top row bars ~1.7x the dot pitch, bottom row
  bars sit at the dot's own pitch so the ten-cell figure reads as one length. Visible and even.
- `build/shots/review-W4-PIP-guildhall150.png` — `Guildhall --fixture --set=text_scale=150`, SHOT OK.
  Crop `review-W4-PIP-crop-faces150.png` (3x): Tiny/Spoof/Rhona faces are crisp pixel faces sized to
  the 30px morale line (the 36px sheet) — no blurred 24px face on a big line. Headline change shows.
  Crop `review-W4-PIP-crop-sidebar150.png`: the sidebar Roster block clips the morale chart at 150 to
  a sliver with a cut glyph. The report says this was already clipped at HEAD and is worse now that
  face-carrying LabelBody lines are 36 tall; it is Guildhall.gd (not owned), recorded in the handoff
  Note for the screen owner.

## Tests

- `tests/unit/test_pip_figure.gd` through the one-file runner: `TESTS PASSED 9 test(s) in 1 file(s) [118 ms]`, rc=0.
- Suite/verify not run here (orchestrator's gate); the report pastes VERIFY OK 1956/96.

## Ownership / tree

- `git status --porcelain`: this unit's changes are game/ui/Fonts.gd, game/ui/Theme.gd,
  tests/unit/test_pip_figure.gd (+ .uid), report/handoff-W4-PIP.md, scratchpad/TavernPipPreview.* —
  all owned or scratchpad. No file added under game/assets/fonts (the font-layer bar route, no third
  TTF — a recorded judgement call). game/screens/Tavern.gd untouched.
- Both owned scripts load in the shots and the test run, so the tree parses.

## Notes (minor)

1. The plan's named Tavern shot does not show the even figure until handoff §1 is applied; the shipped
   tree shows it on every LabelMorale/LabelBody site (7 of 9). Orchestrator: apply handoff-W4-PIP.md §1-§2.
2. Guildhall sidebar Roster chart clipped at text_scale=150 (Guildhall.gd, screen-owner call; pre-existing).
3. The 2px bar stems at 100 are a little lighter than the dots beside them; readable, not broken.

## Verdict: PASS
