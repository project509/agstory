# Review — W4-PERF (the latency budget gets an instrument)

Brief look, 2026-09-15. Plan says `Shot: none`, so the "shot" is the probe's own output,
taken as verify 8/8 takes it (windowed, through the lock, one hold with the test).

## What showed
- `"$GODOT" --path . --script res://tools/perf_probe.gd` printed the header (1536x1024
  SubViewport, vsync off, mobile renderer), the budget line, the fixture/calibration line
  (fixture 38 ms, calibration 10 ms), 15 `PERF  <screen>` rows (warm-up Town, the thirteen
  smoke screens, RaidView revisit) each with mount / goto / frame mean+max / gpu / n and a
  `! mount > 140` marker on 12 rows, two `PERF clock` lines with the 33 s / 177 s caveat,
  `PERF WARN  12 row(s) over budget (14 screen(s) judged):` and a 12-line WARN table.
  Exit 1 as designed. 5.8 s of probe time.
- Reading matches the report's: frame budget met ~10x everywhere (0.6-1.5 ms mean, RaidView
  1.44 mean / 6.65 max); mount budget missed by the same 12 rows (RaidView 267.5 ms, goto
  243.4; revisit 163.3). Settings 128.4 and LoadSave 109.7 pass.
- verify.sh:250-287 stage `8/8  latency budget` sits after the playtest block, before the
  verdict; `--fast` → SKIP, `PERF OK` → ok, else WARN line + note + the rows; no `bad` call.
  `GODOT_PERF_TIMEOUT=300` at :20.

## Tests
- The unit's guard test lives only in handoff §1 (tests/ not owned). Extracted it verbatim
  to scratchpad/test_review_w4_perf.gd and ran it with scratchpad/run_review_W4-PERF.gd:
  `TESTS PASSED   3 test(s) in 1 file(s)  [207 ms]`, rc 0.
- Whole suite not run here (orchestrator's gate).

## Notes (minor, no repair asked)
- At probe exit: `ERROR: 1 RID allocations of type 'TextureStorage::Texture' were leaked`
  / `WARNING: 2 RIDs of type "Texture" were leaked` — the SubViewport/host is not freed
  before `quit()`. Cosmetic (exit code and verdict unaffected), but it adds two ERROR lines
  to `.verify.log` on every full run.
- tools/perf_probe.gd.uid is untracked beside the probe; commit with it (report says so).
- Files outside the owned list touched by this unit: none (git status shows only
  tools/verify.sh M, tools/perf_probe.gd + .uid ??, and the two plan files).

## Verdict
PASS. The instrument exists, prints per-screen numbers and a WARN table, is wired into the
gate as a WARN-only stage, and its guard test is green.
