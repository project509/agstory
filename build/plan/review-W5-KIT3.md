# Review — W5-KIT3 (the kit's small debts)

Brief look, per the user's rule.

## Shots (viewed)
- build/shots/review-W5-KIT3.png — `Guildhall --fixture` at 100%. Headline change shows: Rhona's card prints "Shaman — Slightly Annoyed" whole (the CLASS-2 rung; the other seven cards keep their old size — "Rogue — Slightly Annoyed", "Monk — Slightly Annoyed" untouched). The action band is visibly tighter: "Cheer up" / "Manage" plates hug their labels and every "They are fine." reason sits inside the card rim, not over it. Recent Events empty state: glyph over the sentence, hint under it. Nothing broken — no overlap, no blank panel, no text off the frame.
- build/shots/review-W5-KIT3_results150.png — `Results --fixture=raid --set=text_scale=150` (the strip). Band lines wrap whole at two lines: "Warrior — Quite / Happy", "Cleric — Slightly / Annoyed", "Shaman — Annoyed", "Rogue — Annoyed". No ellipsis in any band line. Pre-existing and out of contract, as the report says: the ClassRow class word still trims ("Warri", "Shama") and the strip cards clip at their bottom as before.

## Tests
- `RUN_TESTS_ONLY=test_kit3,test_widgets_kit` → `TESTS PASSED 40 test(s) in 2 file(s)` (test_kit3 10/10, test_widgets_kit 30/30). Only engine RID-leak noise at exit, no test failures.
- The owned files parse (the runner loaded Widgets/Cards/Theme through test_kit3).

## Ownership
- `git status`: Cards.gd, Theme.gd, Widgets.gd modified; test_kit3.gd + .uid new; test_widgets_kit.gd untouched (not in the status, as reported). No file outside the owned list is claimed by this unit's report; the rest of the working tree is other units' in-flight work.
- Guard grep: no `create_tween` / `class_name` in Cards.gd or Theme.gd; `morale_glyph` / `MORALE_BAND_EMOJI` door intact; `const ROWS` present in Cards.gd:44.

## Audit closures
- audit_closed: none — no audit.json row names this unit; the contract source is BUILD_STATE.md 'Next task' (2). Nothing to check.

## Notes (minor, no action asked)
- The contract's shot line says `Results --fixture`; the report (and this review) used `--fixture=raid` so the strip has a party. Reasonable — a plain fixture strip is empty.
- verify --fast was red only in another unit's untracked test_text_scale_layout.gd per the report; not re-run here (orchestrator's gate at wave close).
- Left for later per the report: screen adoption recipes in handoff-W5-KIT3.md (no edits, only observations); the ClassRow class-word trim at 125/150 is a real class-name cut (docs/13 §4.4) but outside this contract — worth a BACKLOG line.

## Verdict
PASS. The headline change (whole band names at 100 and 150, the band sized to its content, reasons inside the rim) shows in both shots; the unit's own tests are green; the tree parses.
