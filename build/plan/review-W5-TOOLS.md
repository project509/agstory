# review-W5-TOOLS — brief look (2026-09-15)

## What I saw

- `Town --fixture --hover=840,195` -> build/shots/review-W5-TOOLS.png (viewed). Prints
  `HOVER 840,195 -> Button<Button> at 829,166 71x38`. The Tavern callout wears the gold outline and its
  title is in the hover gold; every other callout is unhovered. Nothing overlapping, nothing off-frame.
  (`--headless` fails as expected — "a real display server is required" — the windowed call is the one
  shot_all.sh uses; not a defect.)
- `RaiderDetail --fixture --hover=584,167` -> build/shots/review-W5-TOOLS-2.png (viewed). Prints the
  tooltip text and `POPUP PopupPanel embedded=true at 594,177 180x571`. The two-line tooltip "Head — Worn
  Iron Cap / worth 1 G" is legible top-left of the popup — and the popup really is 571 px tall, an opaque
  plate from the head slot down to the roster strip, covering half the Kit panel and the Quarters column.
  That is the Widgets.gd build_tooltip() bug the instrument found (handoff §2, not this unit's file); the
  shot shows the game's real tooltip size, so the instrument is doing its job.
- shot_all.sh tabs sheet: build/shots/w5tools/tabs.log says `sheet tabs: 5 ok, 0 skipped, 0 failed`;
  the Guildhall_Records row is `--fixture=raid:clear --press=Records` (shot_all.sh:130).
- shot.gd: 135 insertions, zero tab-indented lines added — stays four-space.

## Tests

- `RUN_TESTS_ONLY=test_build_state,test_art_sources` -> TESTS PASSED 12 test(s) in 2 file(s). 0 failed.
- BUILD_STATE.md = 249 lines. BACKLOG.md:52 and BUILD_STATE.md:22-23 both say 288 cells x 8 seeds = 2,304.
- `grep -rn "_plate.png\|badge_[0-9]" game tools tests` -> only .import self-references, the surviving
  ui plates (bubble/callout/cta), history comments and the guard tests; Kit.gd:235 goes through
  `Cards.badge_icon(kind)`.

## git status

All D/M rows this unit reports are in its owned list (three bg plates + .import, shot.gd, shot_all.sh,
Kit.gd, spec 09, BUILD_STATE, BACKLOG, progress.md, test_build_state.gd(+.uid), test_art_sources.gd,
audit.json). Nothing outside the list is claimed by the report. game/assets/ui/icons/badge_0..6.png and
arena_stage.png are still on disk — deliberately, per handoff §1/§3.

## Audit closures

- M6-FINAL-02: yes — `git log --diff-filter=D -- tools/probe/diag.gd` = 40ebf32; nothing new to test.
- M6-FINAL-03: yes — 249 lines, sweep count reconciled, held by test_build_state.gd (6 green).
- m4t-09: yes as stated (stays done, note extended) — Kit.gd no longer loads badge_N; the files wait on
  handoff §1 because all.json pins them. test_art_sources green with pre-lowered floors.
- M4B-CONV-02: correctly left partial — arena_stage.png remains, handoff §3.

## Notes (minor)

- The handoff's Widgets.gd tooltip fix (§2) should land before any tooltip shot is used as design
  evidence; until then every `--hover` tooltip capture shows a 571 px plate.
- The seven badge_N.png files sit unreferenced by code but pinned by the manifest; handoff §1 is the
  paired removal.

## Verdict: PASS
