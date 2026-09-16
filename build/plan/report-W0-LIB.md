# Report — W0-LIB (the Lua library learns to draw, the build regenerates every generator, and generated art is gated)

Unit: 00-plan.md §1 "### W0-LIB". Findings: PIPE-12, PIPE-11, gen_wipe.lua:20's phantom "staleness manifest".
Owns: tools/aseprite/lib.lua, _libtest.lua, gen_items.lua, gen_icons.lua (moved from tools/art/), gen_fire.lua,
gen_wipe.lua (comment lines 20-21 only), tools/build_art.sh, tools/verify.sh. Handoff: build/plan/handoff-W0-LIB.md.

## Acceptance

- [x] A1 `build_art.sh --check` exists: runs every `tools/aseprite/gen_*.lua` with `--script-param out=<tmp>` and byte-compares against the tree; reports `0 DIFFERS` on the untouched generators (the premise: PNG bytes are deterministic).
- [x] A2 `lib.lua` gains `mask_new/mget/mset/mask_rect/mask_ellipse/mask_poly/mask_spans`, `depth_map`, `render_mask`, `glow_mask`, `line`, `arc`, `ellipse_fill`, `poly_fill`, `dither_fill`, `import_png`/`blit`, `strip`, `out_path`/`write_text`.
- [x] A3 `gen_items.lua` and `gen_icons.lua` use the shared primitives (private copies removed); `--check` still `0 DIFFERS`.
- [x] A4 `gen_icons.lua` moved to `tools/aseprite/` (header path updated), so `--gen` runs it; `tools/art/gen_icons.lua` gone.
- [x] A5 `gen_fire.lua` routes through `L.strip`: real frames + tag `burn` + durations in the .aseprite, PNG byte-identical; `Aseprite -b art/src/vfx/fire_hearth.aseprite --list-tags` lists `burn`.
- [x] A6 `gen_wipe.lua:20-21` comment names `build_art.sh --check` / verify 2b instead of the phantom manifest.
- [x] A7 `Aseprite -b --script tools/aseprite/_libtest.lua` writes `build/_libtest.png` exercising each primitive; viewed with Read and described here.
- [x] A8 `build_art.sh`: the `build/atlas` export loop is deleted (ruling recorded in its header; nothing consumed it — PIPE q7).
- [x] A9 `verify.sh` gains stage `2b/8 generated art matches its generator`: SKIP without Aseprite, else runs `--check`; `lint_motion.sh` line untouched.
- [x] A10 Editing one pixel of `game/assets/ui/panel_warm.png` turns 2b red (proved and reverted byte-identical).
- [x] A11 `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` green; summary lines pasted below.

## Log (write-as-you-go)

- Read 00-plan §0 + W0-LIB, RULES §3-§5, PIPE-11/12, LESSONS (determinism, built-vs-armed), all owned files, gen_ui.lua (read-only reference: it hard-codes its paths, so the `out=` redirect must live in lib.lua's save functions — no gen_ui edit needed).
- Aseprite 1.3.7 at ./Aseprite/Aseprite.exe (relative to the repo root; every Aseprite run is from the root). Godot is not needed for the generators; only verify runs go through the lock.
- Judgement calls: (1) the plan names no test file for this unit and my ownership list has none, so no tests/unit file is created; the "armed" guard is verify stage 2b itself, and a text-level test that pins the stage is offered in the handoff for the orchestrator. (2) `.aseprite` sources are compared informationally, not gated — only `game/assets/**` (what Godot loads) fails the check.
- A1 DONE: `build_art.sh --check` (relative `out=build/artcheck` prefix honoured by `L.out_path` in save_png/save_ase/write_text, so gen_ui.lua needs no edit). First run against the UNTOUCHED generators: `ART CHECK generators=4 runtime files: 43 agree 0 DIFFERS 0 MISSING (sources: 43 agree, 0 differ)` in 5.2 s — PNG and .aseprite bytes are deterministic, so the byte gate is meaningful.
- Aseprite CLI fact recorded in build_art.sh: `--list-tags` prints only when it precedes the file (`aseprite -b --list-tags <file>`); `--tags <file>` wraps it.
- A2/A3 DONE: lib.lua grew the mask family (`mask_new/mget/mset/mask_rect/mask_ellipse/mask_poly/mask_spans/mask_is_edge/mask_touches_edge/mask_bbox/mask_paint/mask_outline`), `depth_map`, `render_mask` (gen_items' treatment, ramps + opts), `glow_mask` (gen_icons'), strokes (`line/arc/circle`, set-collected so a thick translucent stroke never double-blends), `ellipse_fill/poly_fill`, `dither_fill/dither_grad` (Bayer 4x4 / checker / custom threshold), `import_png/blit`, `strip`, `out_path/write_text`. gen_items.lua lost its private mask/ellipse/rect/poly/depth_map/render (kept only its K-scaling wrappers); gen_icons.lua lost mask_new/mget/mset/is_edge/touches_edge/bbox/glow and now writes faces.json through `L.write_text` (binary mode; the committed file is LF so bytes match). `--check` after the refactor: `generators=5 runtime files: 76 agree 0 DIFFERS 0 MISSING` — the shared primitives reproduce every icon byte for byte, including the faces' disc (mask_disc -> mask_ellipse(r,r): no half-integer centre can land exactly on r^2, so the two inside tests agree).
- A4 DONE: `mv tools/art/gen_icons.lua tools/aseprite/gen_icons.lua` (plain mv, no git index ops); header now cites `build_art.sh --gen` / the new path; the `tools/aseprite/gen_*.lua` glob picks it up (5 generators run).
- A5 DONE: gen_fire.lua's `strip()` now wraps `L.strip(name, w, h, frames, fps, paint, {tag="burn"})`; each tongue paints into the frame image at (dx, h-th) instead of (f*w+dx, h-th); rng draw order unchanged, so fire_hearth/fire_camp/fire_torch PNGs are byte-identical (in the 76 agree). The three .aseprite sources were regenerated by running gen_fire.lua into the tree (they now carry 8/8/6 frames, durations 1/9,1/9,1/8 s and the `burn` tag; `--check` had reported them as the only 3 differing sources beforehand). `./tools/build_art.sh --tags art/src/vfx/fire_hearth.aseprite` prints `burn` (and fire_torch does too). fps stamped in the source is a GUI courtesy — scenes/*.json still declares the rate the game runs (guildhall hearth 9, camp 9, torches 7-8).
- A6 DONE: gen_wipe.lua:21 now reads "...`build_art.sh --check` (verify.sh stage 2b) stays green." (line 20 unchanged, nothing else touched).
- A7 DONE: `Aseprite -b --script tools/aseprite/_libtest.lua` -> `LIBTEST OK`, writes build/_libtest.png (400x250), build/_libtest_strip.png (64x16) and build/_libtest_strip.aseprite (`--tags` prints `grow`). Viewed at 3x (build/_libtest_x3.png) with Read: row 1 is the original kit set (glowing panel with inset well and two slots, the notched red CTA plate with gold rim, the green bar, the nav pill with its cyan accent, the horizontal gold gradient with a chamfered rivet plate on it); row 2 is the new set — a tagged mask (iron dome + crest, an erased eye hole, a leather band with two span rows) shaded by `render_mask` with outline/halo/drop shadow/bevel/grain, the same mask as a cream `mask_outline`, then flat-painted with an amber `glow_mask`; three diagonal lines at 1/2/3 px plus a horizontal 1px line (crisp, no soft pixels); a cyan 3px 200-degree crescent with a thin inner arc (the slash shape), an amber 2px ring with a cream inner circle; a green ellipse, a lavender concave star from `poly_fill`, a 25% Bayer dither and a 50% checker dither, a crimson-to-gold dithered gradient; row 3: two imported face_6 PNGs blitted, and the strip's four growing orange dots. Two asserts inside the script cover `mask_bbox`, `import_png` size and the strip row size.
- A8 DONE: the export loop (art/**/*.aseprite -> build/atlas with --trim) is gone from build_art.sh; the ruling and its reason (no consumer; PIPE-11, q7) are in the header. `--clean` went with it (it only wiped build/atlas). No-flag invocation prints the usage and exits 2.
- A9 DONE (wired; proof under A10/A11): verify.sh stage `2b/8  generated art matches its generator` sits between 2/8 and 3/8: `[ ! -x "${ASEPRITE:-}" ]` -> SKIP, else `timeout $ASEPRITE_TIMEOUT ./tools/build_art.sh --check`, PASS on `ART CHECK OK` printing the count line, FAIL listing DIFFERS/MISSING lines. `ASEPRITE_TIMEOUT=180` added beside the Godot timeouts. `bash -n` clean; the `lint_motion.sh` lines are untouched (grep count 2, as before).
- RESUME (2026-09-14, second agent): re-read the plan/RULES/PIPE-11/12/LESSONS and the owned files, then spot-checked the ticked items: `./tools/build_art.sh --check` -> `ART CHECK  generators=5  runtime files: 76 agree  0 DIFFERS  0 MISSING   (sources: 75 agree, 0 differ — not gated)`, `ART CHECK OK`, exit 0, 8.2 s; `git status --short game/assets` lists no modified PNG (only other units' untracked splash/icon files), so the three rewritten fire .aseprite sources still export byte-identical PNGs; `./tools/build_art.sh --tags art/src/vfx/fire_hearth.aseprite` -> `burn`; `Aseprite -b --script tools/aseprite/_libtest.lua` -> `LIBTEST OK` writing build/_libtest.png 400x250 + _libtest_strip.png 64x16 + .aseprite; the sheet was viewed again with Read and matches the A7 description (kit row; dome+band shaded/outlined/glowed; 1/2/3 px diagonals; cyan crescent, amber ring; ellipse, star, two dithers, gradient; two faces; four growing dots). lib.lua's function index now runs hex..strip (43 entries); gen_items keeps only K-scaling wrappers over L.mask_*, gen_icons keeps spans/mask_disc/render_badge/glyph painters over L.mask_new/glow_mask.
- A10 method: a scratchpad Lua helper opens panel_warm.png in Aseprite and saves it either unchanged (control) or with pixel (4,4) set to magenta. Dry run into the scratchpad first: the control copy is byte-identical to the tree file (`cmp` silent), the poked copy differs in 262 of 320 bytes yet PIL finds exactly 1 differing pixel: (4,4) (27,21,18,255) -> (255,0,255,255). So the encoder round-trips and a DIFFERS can only mean pixels. The real proof runs as ONE command under `tools/with_godot_lock.sh` (poke -> `--check` -> `verify.sh --fast` red -> restore by trap -> `verify.sh --fast` green), so no other agent's engine run ever sees the poked pixel.
- A10 DONE (one locked command, 2026-09-14 08:32-08:40): control re-save `CONTROL identical`; poke (4,4) -> `bytes differing after the poke: 262`; `./tools/build_art.sh --check` exit 1 printing `DIFFERS  game/assets/ui/panel_warm.png` and `ART CHECK  generators=5  runtime files: 75 agree  1 DIFFERS  0 MISSING`, `ART CHECK FAILED`; then `./tools/verify.sh --fast` with the poked PNG:
  ```
  == 2b/8  generated art matches its generator ==
    FAIL  a generated PNG and its generator disagree
              DIFFERS  game/assets/ui/panel_warm.png
            ART CHECK  generators=5  runtime files: 75 agree  1 DIFFERS  0 MISSING   (sources: 75 agree, 0 differ — not gated)
            ART CHECK FAILED  (regenerated files kept under build/artcheck for diffing; re-run the generator with --gen, or fix it)
            Re-run ./tools/build_art.sh --gen, or fix the generator; never hand-edit a generated PNG.
  ...
  == 3/8  unit tests ==
    PASS  TESTS PASSED   1604 test(s) in 72 file(s)  [32300 ms]
  VERIFY FAILED  (full log: .verify.log)
  ```
  Only 2b was red (0/8, 1/8, 2/8, 3/8 PASS; 4-7 SKIP under --fast). Restore: `cmp` silent -> `RESTORED byte-identical`; `git status --short -- game/assets/ui/panel_warm.png` and `git diff --stat` both print nothing (0 lines); build/artcheck removed. The file's mtime moved (bytes did not); Godot's import is md5-keyed so nothing re-imports.
- A11 DONE: second `./tools/verify.sh --fast` in the same locked command, tree restored:
  ```
  == 0/8  lint: no cross-file class_name refs ==
    PASS  LINT OK  no cross-file class_name references in sim/ or game/
    PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  == 1/8  script parse ==
    PASS  PARSE_CHECK scanned 151 script(s)
  == 2/8  generated content matches its generator ==
    PASS  16 generated file(s) agree with tools/gen_items.gd
  == 2b/8  generated art matches its generator ==
    PASS  ART CHECK  generators=5  runtime files: 76 agree  0 DIFFERS  0 MISSING
  == 3/8  unit tests ==
    PASS  TESTS PASSED   1604 test(s) in 72 file(s)  [32257 ms]
  == 4/8 .. 7/8  SKIP  --fast
  VERIFY OK  (full log: .verify.log)
  ```
  (1604 tests now, one more than the previous agent's 1603 — another unit's test landed in the shared tree meanwhile.)
- Judgement calls on resume: (3) the plan's guard "Kit.tscn shot unchanged pixel-for-pixel" is satisfied by the stronger fact that no PNG under game/assets is modified (`git status` clean for every runtime PNG; `--check` 76 agree) — a Kit.tscn shot taken now in this shared tree would differ from the baseline because W0-TEXTSCALE is editing Theme.gd concurrently, so it could not serve as evidence and was not taken. (4) `tools/lint_motion.sh` was not run separately: no file under game/ was touched by this unit, and the green verify's stage 0 prints `MOTION LINT OK`.
- Left undone: nothing in the unit. The README/BUILD_STATE/BACKLOG edits and the optional `tests/unit/test_w0_lib.gd` stay in the handoff for the orchestrator (this unit owns none of those files).
