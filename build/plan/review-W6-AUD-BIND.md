# review-W6-AUD-BIND — brief look

## Shot
`build/shots/review-W6-AUD-BIND.png` (RaidPrep `--fixture=new`, 40 frames, 1536x1024), viewed. The bronze rim frames the lantern floor with nothing written inside it — the "The party stands here" caption is gone, the rim stays. The Current Raid card's sub-line reads "2 enemies · about 12 rounds" (no kind printed as a name). Comp check, verdict callout, Depart CTA ("12 of 12 chalked"), bench and Provisions all sit inside the frame; no overlap, no blank panels, nothing clipped.

## Tests
`RUN_TESTS_ONLY=test_audio,test_prep_layout` (3 files: test_audio.gd, test_audio_binds.gd, test_prep_layout.gd): TESTS PASSED 71 test(s), 0 FAIL [1699 ms]. The push_errors in the log are the expected unknown-key / unknown-hook refusals (test_audio.gd:190/215, test_audio_binds.gd:221/222).
`python tools/audio/gen_sfx.py --check`: GEN_SFX CHECK OK (17 agree of 17), rc 0.

## git status
Changed in owned files only: Audio.gd, RaidPrep.gd, test_audio.gd, test_prep_layout.gd, tools/audio/README.md, tools/audio/gen_sfx.py, tools/build_art.sh; new: tests/unit/test_audio_binds.gd (+ its Godot-generated .uid sibling), report-W6-AUD-BIND.md, handoff-W6-AUD-BIND.md. Nothing outside the owned list is this unit's.

## Audit closures
- M6-AUD-04 — yes: `Audio.play` live gate (Audio.gd:417), `day_advanced` -> `ui.ledger_close` (Audio.gd:264/521), boot-silent first change (Audio.gd:514), chalk / chalk_bad / page_turn sites in RaidPrep.gd (:662-670, :683+, `_on_depart`); `test_audio_binds.gd` reads the tape for each. The seal / in-screen tab / row_select binds are a handoff (§1-§8), not in the tree yet — the row closes once the orchestrator applies it.
- M6-AUD-03 — yes: `gen_sfx.py --check` (AGREE/DIFFERS/MISSING/ORPHAN, exit 1) is in the tree and `build_art.sh --check` runs it (tools/build_art.sh:138-142); `test_audio.gd` holds the .import siblings and the gate text; the red proof is recorded in the report.

## Notes (minor)
- The red proof's restore used `git checkout --` on the one flipped sample (disclosed in the report; the tree is byte-identical there, 17/17 agree).
- LOOP C24 interim applied without handoff-W6-COPY §1 — if W6-COPY's wording lands and differs, its `old:` anchor is gone (two-line edit in `RaidPrep._sidebar`).
- The 60 ms chalk_bad delay is asserted by constant + source line only; Depart's frame stacks page_turn + ledger_close + coin + tab (recorded for W7-AUD-POLISH).
- Report says verify --fast was red only on other units' in-flight files; not re-run here (orchestrator's gate).

## Verdict
PASS — the caption is gone in the shot, the hooks have sites, the byte gate runs, and the unit's own 71 tests are green.
