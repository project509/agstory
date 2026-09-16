# report-W7-AUD-AMB — five ambience beds through one door

Wave 7. Contract: `build/plan/ship/00-plan.md` §2 "W7-AUD-AMB". Findings AUDIO-07, AUDIO-14, AUDIO-17, AUDIO-10 (its Audio half lands by `handoff-W7-SAVE.md` at the close); rulings Q-98 (ii), BL-138. Audit M6-AUD-05 (generable half).

Owned: `game/core/Audio.gd`, `tools/audio/gen_amb.py` (new), `game/assets/audio/amb/*.wav` (+ `.import`), `tools/build_art.sh` (one block), `tools/audio/README.md` (second table), `tests/unit/test_audio.gd`, `tests/unit/test_audio_beds.gd` (new).

## Acceptance

- [x] `gen_amb.py --check` prints 5 AGREE and the loop-point wrap-around RMS check passes for each bed
  - `GEN_AMB CHECK OK (5 agree of 5)`; LOOP OK on all five (tail/head 125 ms within 3 dB; seam step ≤ 1.5× the bed's p99.99 step — e.g. cave 0.0000 vs 0.0237).
  - Levels: RMS −30.0..−30.1 dBFS, peak −20.0..−20.2 on every bed (BL-138).
- [x] the dungeon bed is not the camp's bytes (`--check` says DISTINCT)
  - `DISTINCT 5 beds, 5 distinct renders`; `test_the_dungeon_bed_is_not_the_camps_bytes` compares 64 kB of PCM against both the camp and the cave.
- [x] `build_art.sh --check` covers `amb/` (and `--gen` renders it)
  - `GEN_AMB CHECK OK (5 agree of 5)` inside `ART CHECK OK`; `test_the_build_runs_the_bed_gate_beside_the_sample_gate` reads both lines off the script.
- [x] `test_audio_beds.gd`: every scene JSON name resolves to a bed file that exists (and its `.import` loops)
  - First run: `loop_mode` came back 0 — the importer's enum is Detect/Disabled/Forward/…, so `edit/loop_mode=1` (AUDIO-07's text) is DISABLED; the records say `=2` and the streams load as `LOOP_FORWARD` (judgement call below).
- [x] `test_audio_beds.gd`: `play_bed` twice with different names leaves one playing after the crossfade
  - Tavern→Market: both up mid-fade at −3 dB each (sin/cos 45°), then one stream held. A third request mid-fade settles the first (the loser stops) — asserted too.
- [x] `test_audio_beds.gd`: `stop_bed` silences
  - a 600 ms fade-out, then both players empty; stopping nothing is a no-op.
- [x] `test_audio_beds.gd`: the beds ride the Music bus
  - two dedicated `Bed_0`/`Bed_1` players on Music, PROCESS_MODE_ALWAYS; the pool's Music ring stays empty (the tripwire in test_audio.gd pins that).
- [x] `test_audio.gd`'s mixer tests green; the no-op tripwire rewritten to "ambience, never a melodic bed"
  - `test_play_bed_plays_ambience_and_never_a_melodic_bed`: rank names are refused, every `BEDS` value begins `amb_`, the hook tape is untouched by a bed. Pool-count assertion gains `+ BED_PLAYERS`. 59 tests over the two files, the README assertion the only red before the README landed.
- [x] the door line + its test written to `handoff-W7-AUD-AMB.md` (applied at the close into `SceneStage.load()`)
  - §1 the eight-line `load()` (TABS), §2 the door test; dry-run parses and anchors on both.
- [x] `tools/audio/README.md` carries the beds table
  - five rows, every layer's numbers; `test_the_generator_is_in_the_tree_and_names_every_bed` asserts each bed is named in it.
- [x] parse check green; `verify.sh --fast` run; `lint_motion.sh` green
  - `PARSE_CHECK scanned 190 script(s) / PARSE_CHECK OK` (16:58; the SceneStage/RaidSim/LoadSave reds earlier in the hour were other units mid-edit and cleared). `MOTION LINT OK`.
  - `verify.sh --fast` (16:50): `PARSE_CHECK OK` · `COPY LINT OK` · `ART CHECK generators=7 runtime files: 204 agree 0 DIFFERS 0 MISSING` / `ART CHECK OK` (with `GEN_SFX CHECK OK (17 agree of 17)` and `GEN_AMB CHECK OK (5 agree of 5)`) · `TESTS FAILED 21/2204 failing [49035 ms]` · `VERIFY FAILED`. The 21: `test_golden.gd`/`test_raid_sim.gd`/`test_legendaries.gd`/`test_formulas.gd` (W7-SIM-EFFECTS, goldens mid-regeneration), `test_results_report.gd`/`test_tutorials.gd` (W7-REPORT), `test_savegame.gd` (W7-SAVE), `test_text_scale*.gd`/`test_scene_stage.gd` (W7-STAGE), and `test_docs_links.gd :: test_every_register_citation_resolves_to_a_declared_entry` (46 code citations of Q-96/Q-98 across the wave's files, ten of them this unit's — the guard's own rule is "the citing file joins the allow-list with the reason", and that file is W7-DOCS's this wave: `handoff-W7-AUD-AMB.md` §3). Both audio files: 59/59 green inside that run.

## Judgement calls

- **`edit/loop_mode=2`, not 1.** AUDIO-07's fix text says "set `edit/loop_mode=1` in each `.import`"; Godot 4.7's WAV importer enum is 0 Detect-from-WAV / 1 Disabled / 2 Forward / 3 Ping-pong / 4 Backward, and the first import at 1 produced streams that did not loop (`test_every_bed_is_a_mono_44k_forward_loop…` caught it). The ruling's intent is a forward loop; the records say 2.
- **QOA (`compress/mode=2`) for the beds**, the sfx's own compression and the importer default: ~450 kB per bed in the pack instead of 2.2 MB PCM. QOA frames carry their own LMS state, so a loop seek to sample 0 is exact; the loop point is on a frame boundary.
- **Per-layer normalisation and a 2.5σ rounding of continuous layers.** BL-138's RMS −30 / peak ≤ −20 leaves 10 dB of crest and Gaussian noise takes 12; the first render pressed every bed against the knee and the events had nowhere to stand. Continuous layers are rounded at 2.5σ (crest ≈ 8 dB — still noise), events are peak-normalised to +8..+11 dB over the bed's RMS, and the final tanh knee from −24 dB only touches the events. All numbers in `gen_amb.py`'s BEDS table; stated in the README.
- **The loop check compares the two sides of the seam, not the seam against the whole bed.** The market's first render had its cart at 12-16 s and a lull at the wrap; "wrap window within 6 dB of the bed" flagged a continuous lull as a bad loop. Tail-125 ms vs head-125 ms within 3 dB, plus the seam sample step against the bed's own p99.99 step (a click is an outlier), is what "no audible loop point" means.
- **`play_bed` accepts a scene name or a bed id**; the door passes the scene name (what `SceneStage.load()` holds), so no `BEDS_BY_SCENE` table lives in SceneStage and the stage learns nothing about audio beyond the one call.
- **The same bed asked for twice is left running** — Town, the Board, the Guildhall, the Completion and the main menu all resolve to `amb_camp`, and the fire must not restart at every door.

## Log

(appended as items land)

- 16:12 `tools/audio/gen_amb.py` written (imports gen_sfx's DSP primitives; five beds, 22-28 s, seeded per `sha256("<bed>:<layer>")`, equal-power 600 ms fold, periodic LFOs, RMS −30 / knee −24 → peak ≤ −20). First `--check` failed on the market: the chatter sat 18 dB under the cart because the layers were summed at their natural levels; fixed by normalising each layer (continuous → unit RMS, event → unit peak) before its gain, and by rounding continuous layers at 2.5σ so the bed sits under the knee and the events are what reach it. Loop check re-shaped: tail vs head 125 ms windows within 3 dB (a lull on both sides is continuous) plus the seam sample step against the bed's p99.99 step. Rendered into `game/assets/audio/amb/`, `.import` stubs with `edit/loop_mode=1` + QOA (the sfx's compression), `--import` run under the lock: Godot kept loop_mode=1 and wrote the uid/path.
- 16:25 `Audio.gd`: `AMB`, `BEDS` (six scenes → five beds; `stage_town` → `amb_camp` by design), `BED_IDS`, `BED_FADE_SECONDS = 0.6`, `BED_PLAYERS = 2`; `play_bed(name)` (scene or bed id; same bed = no restart; mid-fade request settles first), `stop_bed()`, `bed_playing()`, `bed_for()`, `bed_path()`, `bed_state()`, `advance_bed()`; two `Bed_0`/`Bed_1` players on Music; the crossfade stepped in `_process` beside the duck (one clock, `set_process(false)` only when both idle — `_unduck()` no longer switches the callback off, or a duck during a fade would have frozen the fade). No Tween: `lint_motion.sh` OK. `_on_gold_changed`/`_coin_note` and the coin tests untouched (handoff-W7-SAVE §1 anchors there).
- 16:30 `tests/unit/test_audio_beds.gd` (14 tests) + `test_audio.gd` (tripwire rewritten, pool count + BED_PLAYERS, after_each stops the bed): `RUN_TESTS_ONLY=test_audio_beds,test_audio.gd` → `TESTS PASSED 59 test(s) in 2 file(s)`.
- 16:35 `build_art.sh`: a `--gen` block (`gen_amb.py --out game/assets/audio/amb`) and a `--check` block (`gen_amb.py --check`, greps DIFFERS|MISSING|ORPHAN|LOOP BAD|DUPLICATE on red). `./tools/build_art.sh --check` → `GEN_AMB CHECK OK (5 agree of 5)` … `ART CHECK OK` (204 agree, 0 DIFFERS, 0 MISSING).
- 16:40 `tools/audio/README.md`: title widened, the beds section with the second table (bed / s / scenes / layers with every number), the level and seam rules, the "NOT here" section rewritten to the Q-98 ruling (the lute is W10-BUFFER's; the aerial plays the camp).
- 16:45 `handoff-W7-AUD-AMB.md` §1 (the door: `SceneStage.load()` → `Services.find(stage, "Audio")` → `play_bed(name)`, TABS) and §2 (the door test into `test_audio_beds.gd`, anchored on the "the door (close)" marker). `apply_handoff.py --dry-run` → both APPLIED, tree untouched.
- The tree at this hour: `parse_check` reports `game/ui/SceneStage.gd` (W7-STAGE, mid-edit: `tier_scene`, `speech_plate` arity) — not this unit's; earlier in the hour LoadSave/MainMenu/RaidSim were red and cleared. `test_audio_binds.gd`'s four row-select/depart failures and `test_screens.gd`'s are that compile failure (every `SceneStage.load` → "Nonexistent function 'load' in base 'GDScript'"), not the beds.

## Audit closures

- **M6-AUD-05 (its generable half — the row stays split as W6-LEDGER left it):** the ambience half is DONE. `tools/audio/gen_amb.py` renders `amb_camp`, `amb_tavern`, `amb_market`, `amb_cave`, `amb_dungeon` (44.1 kHz mono 16-bit, 22-28 s, seeded per `sha256("<bed>:<layer>")`, RMS −30 / peak ≤ −20, 600 ms equal-power fold, `--check` = AGREE ×5 + LOOP ×5 + DISTINCT, wired into `build_art.sh --check`/`--gen` — verify stage 2b); `Audio.BEDS` keys every `game/assets/scenes/*.json` name to a bed (`stage_town` → `amb_camp` by design, BL-138), `play_bed`/`stop_bed` crossfade on two dedicated Music-bus players; the door is one line in `SceneStage.load()` by `handoff-W7-AUD-AMB.md` §1. Held by `tests/unit/test_audio_beds.gd` (14 tests) and `test_audio.gd :: test_play_bed_plays_ambience_and_never_a_melodic_bed`. The row's "rank-keyed / `Town.gd` picks its bed" wording is superseded by the ruling: beds are keyed by SCENE through the one door, not by rank through a screen (Q-98 (ii), BL-138). The melodic half is ruled too (Q-98 (i): the lute is W10-BUFFER's first item; ensemble/bell/cheer/leitmotif post-1.0) — the row can move from `blocked-needs-human` to done-for-ambience / planned-for-music when W7-DOCS closes it.
- **AUDIO-07 (finding):** CONFIRMED → landed as above; AUDIO-14's premise (the Music row's label from W6-SETTINGS — "Audio — music and ambience") is now true: the Music slider moves the beds (`test_the_beds_ride_the_music_bus_on_their_own_players`). AUDIO-17 holds: numpy + stdlib only, nothing downloaded.

## Left

- **The door itself and its test** are in `handoff-W7-AUD-AMB.md` §1/§2 (W7-STAGE's file this wave) — by the contract, applied at the close. In-wave the contract is proved by calling `play_bed` directly. Nothing else of the contract was left.
- **`test_docs_links.gd`'s register allow-list rows** for the three audio files (Q-96/Q-98 citations in the BL range) — `handoff-W7-AUD-AMB.md` §3 (W7-DOCS's file). Until applied that test is red for this unit's ten citations (and 36 others from the wave).
- **AUDIO-10's Audio half** (`_on_gold_changed` early return on `announcing`, the retargeted coin test) is W7-SAVE's `handoff-W7-SAVE.md` §1 INTO this unit's files at the close — deliberately untouched here so their anchors hold (`_on_gold_changed`, `_coin_note` and the three coin tests are byte-identical to the wave's start).
- **The ear.** The reviewer listens once through `tools/run_game.sh` (main menu = the camp fire; Tavern, Market; an adventure = the cave; Raid 1 = the dungeon once W7-STAGE's `arena_for` and the door both land). No shot — the contract says the one look is an ear. If a bed reads wrong, every number is in `gen_amb.py`'s `BEDS` table and the layer functions above it; re-render, `--import`, `--check`.
