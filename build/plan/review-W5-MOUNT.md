# Review — W5-MOUNT (brief)

## What I saw
- No shot required by the contract; read the main diff instead. `git diff -- game/core/ScreenRouter.gd`:
  `_scenes` strong PackedScene cache consulted in `_load_into_host` (load() only on a miss, then held),
  seven `Time.get_ticks_usec()` reads into `_split` / `last_split()`, `warm(WARM_SCENES)` for Boot.
  SceneStage.gd adds static `_tex_cache/_frames_cache/_json_cache/_shader_cache` + one noise texture,
  `texture()`, `warm()`, `cache_sizes()`, `_copy_frames()` for the walker mutator. Icons/Frame/probe
  diffs are small (+22/+56/+70). This is what the contract asked for: strong caches in the loaders,
  the goto() phase split in the probe (`--split`), no screen file touched.
- Report has the before/after table (boosting, calibration 8-9 ms): cold 12 WARN rows -> 6; with
  `--warm` 0 of 14. Acceptance's three: RaidView 240.7->41.9, Guildhall 291->72.3, Market 217.4->63.9
  (warm); cold-only they are -33/-28/-16%, the rest being the script compile + plate that only Boot's
  warm-up (handoff §1-§3, Boot.gd + verify.sh not owned) can move. Held-still PIL diff: IDENTICAL both screens.

## Tests
- `RUN_TESTS_ONLY=test_perf_mount` through the lock: `TESTS PASSED   12 test(s) in 1 file(s)  [1732 ms]`,
  0 failed. One expected push_warning (the warm test feeds a missing scene name on purpose).

## git status
- Owned/modified: ScreenRouter.gd, SceneStage.gd, Icons.gd, Frame.gd, perf_probe.gd; new
  tests/unit/test_perf_mount.gd (+ .uid), report, handoff. Nothing outside the owned list is this unit's.
  `apply_handoff.py --dry-run` parses all 3 edits (Boot.gd x2, verify.sh); neither file is modified in the tree.

## Audit closures
- audit_closed is empty; the report says M6-JUICE-07 stays open as W4-PERF left it (WARN-only stage). Agreed.

## Notes (minor)
- The >= 40% acceptance on RaidView/Guildhall/Market is met only with `--warm`, i.e. once handoff §1-§3
  (Boot warms the router + stage behind its overlay; verify.sh stage 8/8 passes `--warm`) is applied.
  Cold, the same three drop 33/28/16%. The report says so plainly; the orchestrator should apply the handoff.
- The shader/noise cache sits slightly outside the "texture/strip cache" ownership wording; J2 records
  why and the held-still diff is identical, so no concern.
- A test loads the router's PackedScene cache for the life of the process; the test runner's later files
  now see warm scenes (harmless, but timing-sensitive tests elsewhere would read faster than a cold game).

## Verdict
PASS. Headline change shows in the diff and the probe tables; the unit's 12 tests pass; tree parses.
