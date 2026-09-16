# review-W7-AUD-AMB — five ambience beds through one door

Brief review, 2026-09-15. Contract: `build/plan/ship/00-plan.md` "### W7-AUD-AMB". Shot: none (the contract says the one look is an ear) — main diff read instead.

## What I saw

- `game/core/Audio.gd`: `AMB`, `BEDS` (six scenes → five beds, `stage_town` → `amb_camp` with the BL-138 reason in the comment), `BED_IDS`, `BED_FADE_SECONDS = 0.6`, `BED_PLAYERS = 2`; `play_bed(name)` takes a scene name or a bed id, same bed = no restart, unknown name = `push_error`, mid-fade request settles the loser; `stop_bed()` fades out; two `Bed_0`/`Bed_1` players on `BUSES[1]` (Music), not the pool ring; the equal-power fade is stepped in `_process` beside the §12.4 duck (no `create_tween`, no `await` anywhere in the file) and `set_process(false)` now waits for both clocks. Headless guard: stream set, `play()` only `if incoming.is_inside_tree()`. That is what the contract describes.
- `tools/audio/gen_amb.py` (553 lines, numpy + stdlib, seeded per `sha256("<bed>:<layer>")`); five loops in `game/assets/audio/amb/` with `.import` at `edit/loop_mode=2` (Forward) + `compress/mode=2` (QOA). The report's judgement call — AUDIO-07's literal "=1" is DISABLED in Godot 4.7's enum, so 2 is the ruling's intent — is right and is recorded.
- `tools/build_art.sh` gains one `--gen` and one `--check` block mirroring the sfx gate; `tools/audio/README.md` gains the beds table (+84/−). Nothing broken in what I read.
- `python tools/apply_handoff.py build/plan/handoff-W7-AUD-AMB.md --dry-run` → APPLIED #1 `game/ui/SceneStage.gd`, #2 `tests/unit/test_audio_beds.gd`, #3 `tests/unit/test_docs_links.gd`; tree untouched.

## Test counts

- `RUN_TESTS_ONLY=test_audio_beds,test_audio.gd` through the lock → **TESTS PASSED 59 test(s) in 2 file(s) [710 ms]**, 0 failing. The ERROR lines in the run are the negative tests' expected `push_error`s (rank names refused, `stage_definitely_not_a_scene` refused).
- `python tools/audio/gen_amb.py --check` → 5 AGREE, 5 `LOOP OK` (tail/head within 1.7 dB, seam step 0.0000–0.0045 against p99.99 0.0112–0.1178, RMS −30.0..−30.1, peak −20.0..−20.2 per BL-138), `DISTINCT 5 beds, 5 distinct renders`, `GEN_AMB CHECK OK (5 agree of 5)`.

## Files outside the owned list

None of this unit's. `git status --porcelain` (96 entries, the wave's other agents) carries only these for W7-AUD-AMB: `M game/core/Audio.gd`, `M tests/unit/test_audio.gd`, `M tools/audio/README.md`, `M tools/build_art.sh`, `?? game/assets/audio/amb/`, `?? tools/audio/gen_amb.py`, `?? tests/unit/test_audio_beds.gd` (+ its Godot-written `.uid`), plus the report/handoff/this review.

## Audit closures

- **M6-AUD-05 (generable / ambience half): yes.** The generator, the five imported loops, `Audio.BEDS` + `play_bed`/`stop_bed` on the Music bus, and the `build_art.sh --check` gate are all in the tree, and `tests/unit/test_audio_beds.gd` (14 tests) + `test_audio.gd :: test_play_bed_plays_ambience_and_never_a_melodic_bed` hold them. The melodic half stays ruled elsewhere (Q-98 (i), W10-BUFFER); the row is for W7-DOCS to move to done-for-ambience.

## Notes (minor, no repair asked)

1. The door itself is not in the tree in-wave — it is `handoff-W7-AUD-AMB.md` §1 into `SceneStage.load()` (W7-STAGE's file), exactly as the contract's Build notes direct; until the orchestrator applies it nothing calls `play_bed`, so "the beds actually mount" is proved only by the direct-call tests. Same for §3: `test_docs_links.gd`'s register allow-list is red for this unit's ten Q-96/Q-98 citations until applied.
2. `game/assets/audio/amb/` adds ~11 MB of generable PCM to the repo (the sfx folder is 253 kB by comparison). Consistent with the sfx precedent and byte-reproducible under stage 2b, so it is a size note only.
3. The ear-check the contract asks for (`tools/run_game.sh`) was not done — a headless reviewer has no device; the loop/level numbers above stand in for it.

## Verdict

**PASS.** The headline change shows in the diff and does what the contract says; the unit's own two test files are 59/59 green; nothing owned breaks the parse.
