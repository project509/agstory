# Report — W4-PERF (the latency budget gets an instrument)

Owned files: `tools/perf_probe.gd` (new, four spaces), `tools/verify.sh` (one WARN stage after
the playtest, in the playtest stage's shape). No test file is named by the plan for this unit
("Shot: none"; the acceptance is the probe's own output plus `test_motion.gd:97-116` staying
green); `tests/` is outside the ownership list, so the guard test is delivered through the
handoff (W0-SHOT J7's precedent) and run here from a scratch runner.

Written as each item finished.

## Acceptance (00-plan §W4-PERF, verbatim)

- [x] A1 the probe prints per-screen numbers and `PERF OK` / a WARN table — 15 `PERF  <screen> mount … frame … gpu … n=` rows (warm-up Town, the thirteen of a11y_smoke.SCREENS, RaidView revisited), then `PERF clock` lines, then `PERF OK` or `PERF WARN n row(s) over budget:` + one `  WARN` line per crossed budget. Two full runs and one `--only=RaidView --frames=30` run in the log below; exit 1 on WARN, 0 on OK, 4 under `--headless`, 2 on an unknown flag (all three exercised).
- [x] A2 RaidView ≤ 140 ms mount, ≤ 16.6 ms mean frame at 1536x1024 (or the WARN names the screen) — the WARN names it: `RaidView mount 238.1 / 271.0 ms > 140 ms` (two runs, boosting); frame 1.44 ms mean (6.3-6.7 max, GPU 0.92 ms) is inside the frame budget with a ~10x margin. Twelve of fourteen judged rows miss the MOUNT budget (Settings 130-135 and LoadSave 105-109 pass); `goto()` is ~90% of every mount. Recorded as the instrument's first honest reading in the handoff's observation, not fixed here (rule 8).
- [x] A3 `test_motion.gd:97-116` (verify.sh text) green — `lint_motion.sh` line untouched; the stage adds text only (verify.sh grew `GODOT_PERF_TIMEOUT` and the 8/8 block; nothing renamed). Confirmed by the final `verify.sh --fast` (TESTS PASSED below).
- [x] A4 verify runs the probe as a WARN stage after the playtest — WARN only, never fails — `hdr "8/8  latency budget — mount and frame time per screen"` after the 7/8 playtest block, in its shape (`--fast` → SKIP; file missing → SKIP; `PERF OK` → PASS; else WARN with the verdict line and a "not a build defect" note; no `bad` call, so RC never moves). Exercised verbatim (scratchpad/stage_W4-PERF.sh slices the stage text out of verify.sh by its own markers and evals it): FAST=0 printed the WARN line, the note and the 16 rows, `RC after stage: 0`; FAST=1 printed `SKIP  --fast`.
- [x] G1 the whole probe stays under ~60 s on the slow clock; the numbers and the clock caveat are printed — 5.9-6.0 s of probe time (8.4 s wall with engine boot) for 15 rows boosting (calibration 9-11 ms); at 5x that is ~30 s. Each screen's window is capped at `SCREEN_CAP_MS = 2500` and n is printed, so the ceiling is 15 × 2.5 s + mounts ≈ 45 s even at 80 ms frames. `GODOT_PERF_TIMEOUT` 300 s. The caveat prints as `PERF clock  caveat: this laptop ran the suite in 33 s boosting and 177 s at base clock — …` beside the calibration figure.
- [x] G2 `parse_check` OK after every edit (batch 2: `PARSE_CHECK scanned 174 script(s)` / `PARSE_CHECK OK`; batch 1's only PARSE FAIL was `game/screens/RaidPrep.gd` mid-edit by W4-PREP, not this unit's file, and gone by batch 2); `verify.sh --fast` summary pasted below.

## Judgement calls (decided inside the plan's text)

- J1 The stage SKIPs under `--fast`, exactly as the playtest does ("in the playtest stage's shape"; the wave-2 note sizes the probe for the FULL gate: "so verify.sh does not grow by more than that"). The stage's own text was exercised with FAST=0 and FAST=1 from a scratch harness rather than by holding the engine for a full gate run during a fourteen-agent wave; the orchestrator's wave-close `verify.sh` is the first full run.
- J2 Mounting goes through the real `ScreenRouter` autoload's `goto()` (register_host on a probe host, as Boot and shot.gd do), not a private router: RULES-15's Fix says goto(), the budget row is "screen / tab switch fully settled", and LESSONS says screens resolve the AUTOLOAD router. The mount number therefore includes the previous screen's `on_exit`/`remove_child`/`queue_free`, exactly as a page turn does in the game. The `goto` sub-figure (the synchronous part) is printed beside it.
- J3 Mount = wall time from the `goto()` call to the start of the next `_process` — i.e. through the first draw (shader compile, texture upload, the SubViewport's present). Three warm-up frames follow before the mean is taken, so the mean is the steady state and the one-off costs sit in the mount number where §12.1's "fully settled" wants them.
- J4 Vsync off, `Engine.max_fps = 0`, `low_processor_usage_mode = false` — the frame period must be the frame's own cost, not the monitor's 16.7 ms. Measured means of 0.6-1.5 ms confirm it took (a vsynced run would sit at ~16.7).
- J5 The fixture is `Fixture.apply(state, null, true)` (the raid recorded) for every screen — a11y_smoke's fixture pass does the same, and RaidView/Results/RaidPrep need the log. `GameSettings.reset_all()` after it (a player's `reduced_motion=true` would hold every tween and shimmer and flatter the frame numbers — shot.gd's header), `SaveGame.SAVE_DIR = "user://perf_saves"` + purge before the fixture records (shot.gd J6), and `_quit()` reloads user://settings.cfg before quit (review-W0-SHOT F12) — all three copied from shot.gd, the seam the note names.
- J6 The screen list is `a11y_smoke.gd`'s `SCREENS`, preloaded for the constant only (RULES-15: "for each screen in a11y_smoke.SCREENS"; LESSONS: one explicit list, no walk). A warm-up mount of Town (printed, not judged) pays the shared theme/font/kit cold load once — the first row would otherwise be 500-700 ms of cold cache on whichever screen happened to be first. RaidView is mounted once more at the end (judged) because it is the screen the acceptance names and the cold/revisit gap separates loading from building.
- J7 A row over budget is a `!` marker on the row plus a `WARN` line; verify prints the rows and the verdict, and leaves the per-row WARN table to `.verify.log` — the rows already carry the mark, and RULES-01 was a gate buried in repeated lines.
- J8 The per-screen measuring window is capped (`SCREEN_CAP_MS = 2500`) with `n` printed — at base clock 120 frames of 80 ms would be 10 s a screen and 130 s a run; a capped window with a visible n is an honest short sample, an uncapped one is a two-minute gate stage.
- J9 The probe cannot run headless (the dummy rasteriser renders nothing — a frame time there is a number about nothing), so it says so and exits 4, and the stage runs it WITHOUT `--headless` (the window flashes up, as for shot_all.sh). A machine with no display gets a WARN with the SKIP line, never a FAIL.
- J10 The guard test (`tests/unit/test_w4_perf.gd`) is delivered in the handoff, not written into `tests/` (rule 1 vs §0.2 — W0-SHOT J7's precedent); it was run green from `scratchpad/run_W4-PERF.gd` (a one-file copy of run_tests.gd's loop, rule 2). Its assertions read verify.sh and perf_probe.gd as text the way test_motion reads the lint: probe wired after the playtest, no `bad` call in the stage, `--fast` skip, no `--headless`, the two budget constants, the smoke list and the fixture as the only sources, the caveat text, and that the probe compiles.
- J11 Not widened: the twelve over-budget mounts are a finding for the screens' owners (handoff observation with the numbers and the suspects), not a change here.

## Log

### 2026-09-15 start
- Read: 00-plan §0 + §5 ownership + §W4-PERF, RULES.md (§1 a11y_smoke/test_motion, §3, §4, RULES-15),
  audit M6-JUICE-07, LESSONS.md, BUILD_STATE's machine note, report/handoff-W0-SHOT, verify.sh,
  shot.gd, fixture_reference.gd, a11y_smoke.gd's mount code, ScreenRouter.goto/_load_into_host,
  docs/13 §12.1.
- Handoff file created (empty) before any code.
- Design: SceneTree script; SubViewport 1536x1024 `UPDATE_ALWAYS` (`disable_3d`, opaque) with `viewport_set_measure_render_time` on for the GPU column; a TOP_LEFT host Control with an explicit size (LESSONS: never FULL_RECT under a SubViewport — the router mounts the screen FULL_RECT inside that host, and `_pin_screen()` re-pins it shot.gd's way and would print a `note` line if the root's size disagreed with the host; it never did); the autoload router's `register_host` + `goto`; phases mount → first → warm → measure per queued row.
- Wrote tools/perf_probe.gd (four spaces, 0 tabs), the verify.sh stage (`GODOT_PERF_TIMEOUT` beside the other timeouts + the 8/8 block after the playtest, before the verdict), scratchpad/test_w4_perf.gd + run_W4-PERF.gd (the runner), scratchpad/batch_W4-PERF_1.sh.

### batch 1 (one lock hold: parse_check, the probe, --headless, --bogus, the scratch test)
- parse_check: `PARSE FAIL res://game/screens/RaidPrep.gd` (arena_view()/ICON not found — W4-PREP mid-edit, not this unit's file); my file parsed (the probe ran).
- Probe, first run (boosting; Vulkan / Forward Mobile / RTX 4050 Laptop): `calibration loop 9 ms`, `fixture 52 ms`, 15 rows in 6.0 s (8.4 s wall), exit 1:
  ```
  PERF  warm-up Town (not judged)        mount   680.6 ms   frame   1.73 ms mean   10.49 max   gpu  0.92 ms   (n=120, goto 564.4 ms)
  PERF  MainMenu                         mount   181.2 ms   frame   0.82 ms mean    1.38 max   gpu  0.22 ms   (n=120, goto 158.1 ms)
  PERF  Town                             mount   192.7 ms   frame   1.23 ms mean    1.52 max   gpu  0.74 ms   (n=120, goto 174.4 ms)
  PERF  AdventureBoard                   mount   164.4 ms   frame   1.08 ms mean    1.23 max   gpu  0.62 ms   (n=120, goto 137.4 ms)
  PERF  Tavern                           mount   200.5 ms   frame   1.32 ms mean    2.84 max   gpu  0.83 ms   (n=120, goto 186.3 ms)
  PERF  Guildhall                        mount   281.8 ms   frame   1.10 ms mean    1.22 max   gpu  0.65 ms   (n=120, goto 255.4 ms)
  PERF  Market                           mount   258.2 ms   frame   0.63 ms mean    1.35 max   gpu  0.18 ms   (n=120, goto 221.9 ms)
  PERF  RaidPrep                         mount   237.2 ms   frame   1.64 ms mean    4.91 max   gpu  0.88 ms   (n=120, goto 211.5 ms)
  PERF  RaiderDetail                     mount   205.0 ms   frame   1.07 ms mean    1.29 max   gpu  0.62 ms   (n=120, goto 183.8 ms)
  PERF  RaidView                         mount   238.1 ms   frame   1.44 ms mean    6.32 max   gpu  0.92 ms   (n=120, goto 216.8 ms)
  PERF  Results                          mount   208.8 ms   frame   1.47 ms mean    2.34 max   gpu  0.99 ms   (n=120, goto 177.9 ms)
  PERF  Completion                       mount   181.2 ms   frame   1.14 ms mean    1.31 max   gpu  0.67 ms   (n=120, goto 159.9 ms)
  PERF  Settings                         mount   134.5 ms   frame   1.22 ms mean    1.54 max   gpu  0.75 ms   (n=120, goto 114.1 ms)
  PERF  LoadSave                         mount   105.2 ms   frame   1.15 ms mean    1.38 max   gpu  0.68 ms   (n=120, goto 89.3 ms)
  PERF  RaidView (revisit, assets warm)  mount   160.7 ms   frame   1.43 ms mean    5.96 max   gpu  0.92 ms   (n=120, goto 143.9 ms)
  PERF WARN  12 row(s) over budget (14 screen(s) judged):   (every row above 140 except Settings and LoadSave; no frame row)
  SETTINGS restored from user://settings.cfg
  ```
  Read: the frame budget is met everywhere by ~10x; the MOUNT budget is missed by twelve rows, and `goto` (the synchronous instantiate + build + on_enter + focus wiring, plus the previous screen's on_exit/free) is ~90% of each mount. The `%-32s` left-justify and `%7.1f` widths format as intended.
- `--headless`: `PERF SKIP  headless: run without --headless …` + push_error, exit 4. `--bogus`: usage + exit 2. Scratch test: `TESTS PASSED 3 test(s) in 1 file(s)`.
- Engine noise not this unit's: `Unable to open file: res://.godot/imported/cursor_arrow.png-….ctex` (W4-CURSOR's new PNG without its import) — recorded in the handoff for the orchestrator.
- Edits after batch 1: `goto_ms` is now taken BEFORE `_pin_screen()` (the pin is the probe's, not the game's); each row carries a `  ! mount > 140` / `  ! frame > 16.6` marker; verify prints the rows + the verdict and leaves the WARN table to the log (J7).

### batch 2 (one lock hold: parse_check, the stage text verbatim FAST=0 and FAST=1, --only=RaidView --frames=30, the scratch test)
- `PARSE_CHECK scanned 174 script(s)` / `PARSE_CHECK OK`.
- Stage 8/8 as verify.sh runs it (38 lines sliced from verify.sh by its own `# --- 8/8 latency` / `# --- verdict` markers, evaled with verify's hdr/ok/bad and FAST=0): header, `WARN  PERF WARN  12 row(s) over budget (14 screen(s) judged):`, the note, then the 15 rows + calibration line indented; `RC after stage: 0`. FAST=1: `SKIP  --fast`, RC 0. Second full reading (boosting, calibration 11 ms, fixture 40 ms, 5.9 s): MainMenu 160.2 (goto 139.1), Town 196.0 (179.9), AdventureBoard 169.1 (142.5), Tavern 202.6 (189.0), Guildhall 293.2 (267.2), Market 243.7 (211.7), RaidPrep 215.8 (192.0), RaiderDetail 207.9 (185.3), RaidView 271.0 (247.8; frame 1.44 mean, 6.66 max, gpu 0.92), Results 210.4 (180.2), Completion 189.4 (168.1), Settings 130.5 (112.3), LoadSave 108.8 (91.8), RaidView revisit 169.7 (149.5); warm-up Town 567.9 (514.4, max frame 18.89). Same twelve rows over; run-to-run spread ~10-15% at the same calibration figure.
- `--only=RaidView --frames=30`: warm-up Town 524.2; RaidView 227.2 (goto 205.6) `! mount > 140`; RaidView revisit 88.2 (goto 69.8) — a RaidView-to-RaidView switch is ~70 ms because the previous instance (queue_free'd, still alive during goto) keeps its textures cached; after twelve other screens the same revisit is ~150: the resource cache is weak, so a freed screen's own plates and strips are reloaded on every later visit. Header and the revisit label updated to say so ("RaidView (revisit)", no longer "assets warm"). `PERF WARN 1 row(s)`, exit 1. Scratch test `TESTS PASSED 3 test(s)`.
- Handoff written: the test file as edit §1 (`apply_handoff.py --dry-run`: `CREATED #1 tests/unit/test_w4_perf.gd`, rc 0, nothing written) plus the two observations (the twelve over-budget mounts with suspects; the cursor ctex).

### final gate
- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (the whole suite, once, after every edit; the engine was shared with the other wave-4 agents, so the suite ran at the slow clock):
  ```
  == 0/8  lint: no cross-file class_name refs ==   PASS  LINT OK / PASS  MOTION LINT OK
  == 1/8  script parse ==                          PASS  PARSE_CHECK scanned 177 script(s)
  == 2/8  generated content ==                     PASS  16 generated file(s) agree with tools/gen_items.gd
  == 2b/8 generated art ==                         PASS  ART CHECK  generators=7  runtime files: 199 agree  0 DIFFERS  0 MISSING
  == 3/8  unit tests ==                            PASS  TESTS PASSED   1933 test(s) in 95 file(s)  [237648 ms]
  == 4/8 .. 7/8 ==                                 SKIP  --fast
  == 8/8  latency budget — mount and frame time per screen ==   SKIP  --fast
  VERIFY OK
  ```
- `bash -n tools/verify.sh` clean; `tools/perf_probe.gd` has 0 tabs. `lint_motion.sh` not run separately: no file under game/ was touched (its line inside the gate passed above).
- Scratch files removed at the end (scratchpad/ is untracked and shared by the wave's agents; only this unit's `*W4-PERF*` files and `test_w4_perf.gd` were deleted — the test's text lives in the handoff, the probe logs' content is in this report).

## What is left
- Nothing in the unit. The twelve over-budget mounts are the finding the instrument exists to make and are filed in the handoff for the screens' owners; the guard test lands when the orchestrator applies `handoff-W4-PERF.md` §1.
