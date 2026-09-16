# Review — W0-LIB (adversarial, against the tree)

Reviewer 2026-09-14 08:45-09:05. Every command below was run by the reviewer; nothing is quoted from
the report unless marked so. Verdict at the bottom: **PASS with two majors flagged for the orchestrator
and five minors.**

## 1. Tree vs ownership

`git status --porcelain` (08:45). Owned files present and changed: tools/aseprite/lib.lua (+467),
_libtest.lua, gen_items.lua (-120 net), gen_fire.lua, gen_wipe.lua (line 21 only — line 20 untouched),
tools/build_art.sh, tools/verify.sh (+24, stage 2b only); ` D tools/art/gen_icons.lua` and
`?? tools/aseprite/gen_icons.lua` (moved; `diff -u <HEAD copy> <new>` shows only the header path, the
private mask/glow helpers replaced by lib.lua calls, and faces.json via `L.write_text`).

Changed files NOT in the owned list, with attribution:

- `art/src/vfx/fire_hearth.aseprite`, `fire_camp.aseprite`, `fire_torch.aseprite` (binary, M) — made by
  THIS unit (report A5; content = gen_fire.lua's output). Not in the Owns list, but the Owns entry for
  gen_fire.lua reads "(route through `L.strip`, output byte-identical)", the build note says "real frames
  + a tag + durations in the .aseprite", and the acceptance line "`--list-tags` on
  `art/src/vfx/fire_hearth.aseprite` lists `burn`" cannot be met without regenerating them. No wave-0 unit
  owns `art/src/vfx/**` (the wave-0 ownership table names nobody; W1-VFX owns it next wave), so there is
  no collision. MAJOR (an ownership-list gap the plan itself created), not a blocker: deterministic output
  of an owned generator, disclosed in the report, demanded by the acceptance.
- `README.md` (M, mtime 09-14 08:29:51) and `BACKLOG.md` (M, same second) — carry handoff-W0-LIB items
  1, 2, 3 and 6 VERBATIM (`git diff -- README.md` is exactly the three handoff blocks; BACKLOG:145 has the
  new path). Items 4-5 (BUILD_STATE, marked "apply after W0-GATE's block lands") are NOT applied
  (BUILD_STATE.md:206/242 still say build/atlas). No other unit's handoff touches README/BACKLOG. The
  handoff file (mtime 09-13 21:00) says "Nothing here has been applied"; the report (08:42) says the edits
  "stay in the handoff for the orchestrator". Either the orchestrator applied 1-3+6 on resume and correctly
  deferred 4-5, or this unit edited two unowned files and misreported it. Neither the diff nor the report
  shows the unit did it; the same-second timestamps and the correctly deferred 4-5 fit an orchestrator
  pass. UNATTRIBUTABLE — orchestrator to confirm. If the unit did it: blocker, and the verdict flips.
- Everything else in the status (screens, Theme.gd, Boot.gd, project.godot, tests/unit/test_*.gd,
  tools/shot*.sh, diff_all.sh, fixture_reference.gd, probe/Kit.gd, art/ref/manifests, contact_sheet.py,
  gen_wordmark.py, export_presets.cfg, BUILD_STATE.md, the untracked splash/icon PNGs, test_art_sources,
  test_text_scale, place_enemies.py, enemies.json) belongs to W0-SHOT/GATE/TEXTSCALE/MANIFEST/SPLASH by the
  wave-0 table; grep of those diffs for `artcheck|out_path|L.strip|build_art|gen_icons` finds nothing —
  no W0-LIB fingerprints.
- `tools/aseprite/gen_ui.lua` is untouched (not in status), as the report claims.

## 2. Runs observed

- `bash -n tools/build_art.sh tools/verify.sh` → clean.
- `grep -c lint_motion.sh tools/verify.sh` → 2 (HEAD: 2). test_motion.gd:101-103 reads that string; intact.
- `./tools/build_art.sh` (no flag) → prints the header usage, exit 2.
- `./tools/build_art.sh --tags art/src/vfx/fire_{hearth,camp,torch}.aseprite` → `burn` / `burn` / `burn`.
  HEAD's fire_hearth.aseprite (extracted with `git show`) → `--list-tags` prints nothing.
- Aseprite inspect script (scratchpad/inspect.lua, `Sprite{fromFile}`): new hearth `frames=8 size=64x56`
  durations 0.1110×8, tag `burn 1..8`; camp `frames=8 40x52` 0.1110×8 `burn`; torch `frames=6 16x24`
  0.1250×6 `burn`. HEAD hearth: `frames=1 size=512x56` duration 0.1000, no tag.
- `grep saveAs|saveCopyAs|io.open|Export tools/aseprite/gen_*.lua` → no hits; lib.lua's three write sites
  (:337 saveCopyAs, :347 saveAs, :357 io.open) each go through `L.out_path`. So `--check` cannot write into
  the tree, and no generator escapes the gate.
- `grep -c '^function L\.' tools/aseprite/lib.lua` → 53 (the report's "43" is its header index, not
  checked, not load-bearing); each primitive the contract names
  (mask_new/mask_ellipse/mask_poly/mask_rect, render_mask, line, arc, ellipse_fill, poly_fill, glow_mask,
  import_png, dither_fill, strip) is a `function L.<name>(` line.
- `Aseprite -b --script tools/aseprite/_libtest.lua` → 3 files written, `LIBTEST OK`, exit 0;
  build/_libtest.png 400x250 RGBA, _libtest_strip.png 64x16, `--tags build/_libtest_strip.aseprite` → `grow`
  (inspect: 4 frames, 0.125 s each). Viewed at 3x — §3.
- Locked run (scratchpad/review_lock.sh under `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh`, queued
  ~9 min behind another agent, ran 08:57:15-08:59:49):
  1. clean `./tools/build_art.sh --check` → 5 generators, `runtime files: 76 agree 0 DIFFERS 0 MISSING`,
     `ART CHECK OK`, exit 0.
  2. PIL poke of panel_warm.png (4,4) (27,21,18,255) → magenta; `cmp` confirms bytes differ.
  3. `--check` poked → `DIFFERS  game/assets/ui/panel_warm.png`, `75 agree 1 DIFFERS 0 MISSING`,
     `ART CHECK FAILED`, exit 1.
  4. `./tools/verify.sh --fast` poked → 0/8 PASS+PASS, 1/8 PASS 151 scripts, 2/8 PASS 16 files,
     **2b/8 FAIL** "a generated PNG and its generator disagree" + the DIFFERS line + the re-run hint,
     3/8 PASS `TESTS PASSED 1604 test(s) in 72 file(s)`, 4-7 SKIP, `VERIFY FAILED`, exit 1. Only 2b red.
  5. trap restore → `RESTORED byte-identical`; `git status --porcelain -- panel_warm.png` empty after the
     run; build/artcheck removed.
  6. `./tools/verify.sh --fast` clean → 0/8 PASS+PASS (MOTION LINT OK), 1/8 PASS 151, 2/8 PASS 16,
     **2b/8 PASS `ART CHECK generators=5 runtime files: 76 agree 0 DIFFERS 0 MISSING`**, 3/8 PASS
     `TESTS PASSED 1604 test(s) in 72 file(s) [32926 ms]`, 4-7 SKIP, `VERIFY OK`, exit 0.
  7. `"$GODOT" --path . --script res://tools/shot.gd -- res://tools/probe/Kit.tscn
     build/shots/review-W0-LIB-Kit.png 40 1536x1024 --fixture` → `SHOT OK ... 1536x1024`, exit 0.

## 3. Shots (viewed with Read)

Contact sheet (build/_libtest.png at 3x → build/review-W0-LIB-libtest_x3.png): row 1 = the pre-existing
kit set (glowing panel with an inset well and two slots, the notched red plate with gold rim, green bar,
the wide steel-blue nav pill with a cyan left accent, a gold→brown horizontal gradient with a chamfered
blue-rimmed plate and one rivet on it). Row 2 = the W0-LIB primitives: an iron dome with a crest on a
leather band, ramp-shaded with outline, halo, drop shadow and grain and an erased eye hole (render_mask);
the same mask as a cream 1px outline (mask_outline) with the two span rows visible beneath; the same mask
flat slate with an amber glow ring (mask_paint + glow_mask); three parallel diagonals at 1/2/3 px in
cream/cyan/red plus a 1px gold horizontal — stepped, no soft pixels (line); a cyan 3px 200° crescent with
a thin inner arc (arc); an amber 2px ring with a cream inner circle (circle); a green ellipse
(ellipse_fill); a lavender 5-point concave star (poly_fill); a 25% Bayer and a 50% checker dither block
(dither_fill); a crimson→gold ordered-dither column (dither_grad). Row 3 = two green face_6 badges
(import_png + blit) and four growing orange dots (strip's returned row). Every primitive the contract
lists is on the sheet.

Kit.tscn (build/shots/review-W0-LIB-Kit.png, and _half.png): the Concept-1 chrome on the camp plate —
wordmark, four header chips with the rank sigil, the seven-item rail, the Current Raid panel with the
boss well, the four gen_items reward icons (sword, armour, gem, coin), the red 17% success plate, the
raid-team faces, the "Send Them Anyway" CTA, the roster strip with morale faces and gear icons, the
Recent Events feed with its glyphs. Every generated texture renders as before. Compared with today's
baseline build/diff/kit.png (W0-GATE's 08:36 run): 94,491 differing pixels, bbox (439,99)-(1519,836),
densest in x 768-1024 / y 192-512 — the campfire. The band side-by-side (review-W0-LIB-Kit_band_sbs.png)
shows the fire on a different frame, different ember particles and the "..." bubble at a different bob
height; the chrome, icons and panels on both sides are identical by eye. World-layer animation phase
(and particles are non-deterministic), plus Kit.gd (re-pointed at stage_camp), Theme.gd and shot.gd all
changed under other units since HEAD. Nothing traces to this unit, which modified no runtime PNG.
Pixel-for-pixel equality is not establishable in this moving tree; the stronger guard holds.

## 4. Acceptance lines (plan "### W0-LIB")

| Line | Verdict | Evidence |
|---|---|---|
| `_libtest.lua` writes the contact sheet exercising each primitive | MET | §2 run, §3 description |
| `build_art.sh --check` reports `0 DIFFERS` | MET | locked run step 1: `76 agree 0 DIFFERS 0 MISSING`, exit 0 |
| `--list-tags` on fire_hearth.aseprite lists `burn` | MET | `--tags` → `burn`; inspect: tag burn 1..8; HEAD had none |
| `verify.sh --fast` shows `2b/8 … SKIP` or a count | MET (count branch) | step 6: `2b/8 ... PASS ART CHECK ... 76 agree`. SKIP branch verified by reading verify.sh:123-125 only — env.sh is sourced inside verify.sh, so it cannot be exercised without editing an unowned file (unverifiable at runtime) |
| Editing one pixel of panel_warm.png turns 2b red | MET | steps 3-4: DIFFERS, 2b FAIL, VERIFY FAILED, only 2b red; restored byte-identical |
| Assets: every existing PNG byte-identical | MET | no `game/assets/**/*.png` modified in `git status`; 76 agree |
| Build note: lift the named primitives incl. `L.strip(name,w,h,n,fps,paint)` with real frames + tag + durations in the .aseprite and the one-row PNG | MET | lib.lua diff; inspect shows 8/8/6 frames, durations, `burn`; PNGs unchanged |
| Build note: `--check` runs every generator with `--script-param out=<tmp>` and byte-compares | MET | build_art.sh run_generators + cmp loop; `L.out_path` reads `app.params["out"]` |
| Build note: delete the build/atlas loop, note it in the header | MET | build_art.sh:23-28 RULING; `--sheet-type packed` loop gone |
| gen_icons.lua moved, header path updated, runs from `--gen` | MET | `?? tools/aseprite/gen_icons.lua`, header :5-6, `gen gen_icons.lua` in every run (5 generators) |
| gen_fire.lua through `L.strip`, output byte-identical | MET | diff; fire PNGs git-clean and in the 76 agree |
| gen_wipe.lua:20-21 comment only | MET | diff touches line 21 only |
| Shot guard: Kit.tscn unchanged pixel-for-pixel | MET by the stronger guard (no runtime PNG modified); pixel equality UNVERIFIABLE in the shared tree | §3 |
| Green: no game file touched; `lint_motion.sh` line intact | MET | status/fingerprint grep; count 2 = HEAD; MOTION LINT OK in step 6 |

## 5. §0.5 / Green line

- The unit adds no GDScript, so Label/Button text, node names, tweens, reduced_motion, class_name,
  _ready(), overlays and the router host are untouched by construction (fingerprint grep in §1).
- New PNGs under game/assets: none. build/_libtest*.png sit under build/ which carries .gdignore, so no
  .import is needed and Godot never sees them.
- `$GODOT` outside the lock: build_art.sh never calls Godot; verify.sh's `$GODOT` calls are the
  pre-existing pattern (verify.sh is what gets wrapped). No new unguarded engine call.
- Indentation: shell + two-space Lua as each file already used; no GDScript touched.
- Handoff shape: items 1-7 are `## N. <path>:<line>` with old/new fences. Old blocks checked against the
  tree: README items 1-3 and BACKLOG 6 now match the NEW text (already applied — §1); BUILD_STATE items
  4-5 old blocks match BUILD_STATE.md:206 and :242 by content (the handoff cites :189/:225 — W0-GATE's 17
  inserted lines moved them; minor). Item 7's test extends "res://tests/TestCase.gd" (= test_motion.gd:1),
  four-space, no class_name, reads files as text only.

## 6. Judgement calls vs plan §6

- (1) No test file: the plan names none for W0-LIB; offered as handoff item 7. Within the plan. Minor:
  until item 7 lands, the "armed" guard is the shell stage alone.
- (2) `.aseprite` sources compared but not gated: the acceptance is about PNG bytes; within the plan.
  Minor: a hand-edited source drifts silently from its generator (they are deterministic — 75 agree —
  so gating them would have cost nothing).
- (3) No Kit.tscn shot by the unit: the reviewer took it (§3); the stronger guard holds.
- (4) build/atlas loop deleted and `--clean` with it: the plan rules this explicitly as reversible
  tooling; recorded in the header as required. Not a §6 item.
- Nothing decided that §6 reserves for the designer: no canon number, no switch, no docs/_source edit.

## Findings

1. MAJOR (not a blocker) — three `art/src/vfx/fire_*.aseprite` regenerated outside the Owns list; the
   acceptance line demanded it and nobody else owns them this wave. Orchestrator: add `art/src/vfx/**`
   to W0-LIB's Owns in the record, or note the gap.
2. MAJOR / UNATTRIBUTABLE — README.md and BACKLOG.md already carry handoff items 1-3 and 6 while the
   handoff says nothing was applied. If the orchestrator applied them on resume: no issue (update the
   handoff header). If not: this unit edited two unowned files → blocker.
3. minor — handoff items 4-5 cite BUILD_STATE.md:189/:225; the text is now at :206/:242.
4. minor — the handoff's "Nothing here has been applied" header is stale either way.
5. minor — sources are reported, not gated (judgement call 2).
6. minor — the SKIP branch of 2b is verified by reading only.
7. minor — docs/12 §7, docs/14 §10.2/BL-66, art/ref/specs/11:80-83 and .gitignore's comment still
   describe build/atlas as the consumed output; the handoff notes the spec, not the docs. W4-HYGIENE
   territory; recorded here so it is not lost.

## Verdict

**PASS.** Every acceptance line the unit could meet is met and was reproduced by the reviewer under the
lock (0 DIFFERS; burn tag; 2b counts; one poked pixel turns 2b red and only 2b; VERIFY OK on the restored
tree, 1604 tests). No blocker is provable from the diff or the report. Two majors are flagged above for
the orchestrator; the verdict flips to FAIL only if the orchestrator confirms it did not itself apply
handoff items 1-3 and 6 to README.md/BACKLOG.md.
