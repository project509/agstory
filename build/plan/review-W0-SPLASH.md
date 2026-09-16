# Review — W0-SPLASH (the exported build's first frame is ours)

Adversarial review against the TREE, 2026-09-14. Reviewer edits nothing but this file (and writes
one shot to build/shots/review-W0-SPLASH-MainMenu_keep.png). Contract: build/plan/artaudit/00-plan.md
§1 "W0-SPLASH", §0.5; build/plan/artaudit/RULES.md. Every number below is something I ran or measured.

## 1. Tree vs ownership (git status / git diff)

Owned list: project.godot (additive), export_presets.cfg, tools/art/gen_wordmark.py,
game/assets/ui/splash.png(+.import), game/assets/ui/icon_256.png(+.import), game/assets/ui/icon.ico,
tests/unit/test_export.gd.

- `git status --porcelain`: the owned files present as ` M project.godot`, ` M export_presets.cfg`,
  ` M tools/art/gen_wordmark.py`, ` M tests/unit/test_export.gd`, `?? game/assets/ui/{icon.ico,
  icon_256.png, icon_256.png.import, splash.png, splash.png.import}`. build/shots is gitignored
  (`/build/*` with `!/build/plan/**`), so the shots never appear in status — as designed.
- project.godot diff read in full: `config/icon` value changed emblem.png -> icon_256.png (the plan's own
  acceptance mandates a 256 square, so this is the one non-additive line and it is the one the plan
  asks for); `boot_splash/image`, `boot_splash/bg_color=Color(0.011764706, 0.043137256, 0.07450981, 1)`
  added under [application]; `environment/defaults/default_clear_color` (same Color) added under
  [rendering]. That Color is (3,11,19) = Palette.GROUND_PAGE `Color("030B13")` (game/ui/Palette.gd:27).
  The InputMap block is untouched (test_a11y's concern). Comments rewritten only on the lines the unit
  replaced.
- export_presets.cfg diff read in full: only `application/icon` and `application/console_wrapper_icon`
  (both -> res://game/assets/ui/icon.ico) and the four comment lines above them; nothing else moved.
- gen_wordmark.py diff read in full: `wordmark()`/`tagline()` refactored into `render_mark(size, run_width,
  scale)` / `render_tagline(scale)` with scale=1 reproducing the old numbers (pad 6, MaxFilter 3, blur 1.0,
  roll 2); new `palette()` regex-reads Palette.gd; new `emblem_on()`, `splash()`, `_rounded_plate()`,
  `icon()`; main appends `splash()` and `icon()`. JSON key order preserved (baseline_y, cap_top_y, size,
  glyph_left; "condensed" popped before dump).
- test_export.gd diff read in full: six new cases + `_png_size()`; the pre-existing
  `test_the_preset_ships_the_same_icon_the_project_names` was REMOVED (replaced by
  `test_the_icon_is_a_256_square`). Its assertion (preset icon == config/icon string) cannot survive
  the plan's own acceptance (config/icon = PNG square, preset = .ico), so the removal is forced — but
  the report does not record it as a judgement call. Minor.
- Unowned files changed in the tree (cannot be attributed; other units own them): BACKLOG.md,
  BUILD_STATE.md, README.md, art/ref/manifests/all.json, art/src/vfx/*.aseprite, 13 game/screens/*.gd,
  game/ui/Boot.gd, game/ui/Theme.gd, 9 other tests/unit/test_*.gd, tools/art/contact_sheet.py,
  tools/art/gen_icons.lua (D), tools/aseprite/*.lua, tools/build_art.sh, diff_all.sh,
  fixture_reference.gd, probe/Kit.gd, shot.gd, shot_all.sh, verify.sh, plus untracked
  enemies.json, test_art_sources.gd, test_text_scale.gd, place_enemies.py, gen_icons.lua, aguildstory.zip.
  `git diff -- BACKLOG.md BUILD_STATE.md README.md docs/ | grep splash|icon.ico|icon_256|W0-SPLASH|
  boot_splash` returns nothing: this unit's fingerprints are in none of them. The record-truth edits
  it wanted (docs/15, q-housekeeping.md) are in the handoff, not applied — confirmed: both files' old
  blocks are still the live text (see §5).
- No unowned file touched by this unit. PASS.

## 2. Tests and verify --fast (observed)

- Generator determinism, checked by me: imported tools/art/gen_wordmark.py with OUT redirected to the
  scratchpad (emblem.png copied beside it) and ran all five stages. sha256 of every output equals the
  tree's: wordmark_58.png/.json, wordmark_44.png/.json, wordmark_tagline.png/.json, splash.png,
  icon_256.png, icon.ico — all IDENTICAL. The six legacy outputs also equal `git show HEAD:` byte for
  byte. The "byte-identical" claim is TRUE. (Note: tools/build_art.sh's ART CHECK only iterates
  tools/aseprite/gen_*.lua, so the PY outputs are not gated by verify — pre-existing, not this unit's.)
- Shot through the lock (own run): `shot.gd -- res://game/screens/MainMenu.tscn
  build/shots/review-W0-SPLASH-MainMenu_keep.png 40 1820x1024 --set=display_aspect=keep` printed
  `SETTINGS defaults + { "display_aspect": "keep" }` and `SHOT OK ... 1820x1024`.
- verify --fast: first run's tail was lost — another reviewer in the same session scratchpad wrote a
  file of the same name (review_run.log) and truncated mine mid-run. Re-run queued through the lock
  with output in the task's own file; result recorded in §2b below.

## 2b. verify --fast re-run (observed, 09:02:05 -> 09:03:41, rc=0)

```
== 0/8  PASS  LINT OK  no cross-file class_name references in sim/ or game/
         PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
== 1/8  PASS  PARSE_CHECK scanned 151 script(s)
== 2/8  PASS  16 generated file(s) agree with tools/gen_items.gd
== 2b/8 PASS  ART CHECK  generators=5  runtime files: 76 agree  0 DIFFERS  0 MISSING
== 3/8  PASS  TESTS PASSED   1604 test(s) in 72 file(s)  [32362 ms]
== 4-7   SKIP  --fast
VERIFY OK
```
tests/unit holds exactly 72 test_*.gd files (`ls | wc -l` = 72) and the runner has no filter, so
test_export.gd's 18 `func test_` cases (counted: 18) are inside the 1604 and none failed (the runner
prints `FAIL <name>` per failing test and printed none). .verify.log had already been overwritten by
another agent's run by the time I read it, so the per-file log is not quotable — the summary above is
my own run's stdout.

## 3. Shot re-taken and viewed

build/shots/review-W0-SPLASH-MainMenu_keep.png, 1820x1024, viewed with Read: the MainMenu (aerial town
plate, "A Guild Story" lockup + tagline, red New Guild CTA with focus ring, Continue disabled with
"No saved guild found.", Load Guild / Settings / Quit) sits centred at 1536 wide with a flat dark-navy
bar on each side. No engine grey anywhere.
Measured with Pillow: frame starts at x 142 = (1820-1536)/2. Left bar (cols 0..141): 145408 px, ONE
distinct colour, (0,13,18). Right bar (cols 1678..1819): 133095 of 145408 px are (0,13,18); the rest
sit in the 25 columns nearest the frame edge (1678..1702) with a deviation of up to 25 units per
channel — the scene's screen-space glow bleeding past the frame edge (a MainMenu/shot.gd property, not
the clear colour). Zero pixels within 12 units of the engine's default grey (77,77,77) in either bar.
(0,13,18) vs nominal (3,11,19): the HDR-2D/sRGB round trip; within 3 units per channel.
Verdict by eye and by number: the bars are GROUND_PAGE, ours. The implementer's shot
(build/shots/MainMenu_splash_keep.png) measures the same (left bar uniform; right-bar bleed 8258 px over
25 columns). The report's "the rest within 3 units next to the frame edge" understates the bleed
(up to 25 units, 25 columns) — a report inaccuracy, not a defect in this unit's files.

## 4. Acceptance lines

| Line (plan §1 W0-SPLASH) | Met | Evidence |
|---|---|---|
| test_export.gd asserts `application/boot_splash/image` | yes | tests/unit/test_export.gd `test_the_boot_splash_is_ours`: non-empty, file exists, IHDR 1536x1024, decoded pixel (0,0) is_equal_approx GROUND_PAGE |
| `application/boot_splash/bg_color == Palette.GROUND_PAGE` | yes | same test: `ProjectSettings.get_setting("application/boot_splash/bg_color")` is_equal_approx Palette.GROUND_PAGE; project.godot value (3,11,19) |
| `rendering/environment/defaults/default_clear_color == Palette.GROUND_PAGE` | yes | `test_the_letterbox_bars_are_ground_page`; project.godot:153 |
| `config/icon` square 256x256 | yes | `test_the_icon_is_a_256_square` reads the IHDR; Pillow: icon_256.png (256,256) RGBA |
| the Windows preset points at icon.ico | yes | export_presets.cfg `application/icon="res://game/assets/ui/icon.ico"`; `test_the_windows_preset_ships_a_real_ico` parses the ICONDIR (reserved 0, type 1, 7 entries 16/24/32/48/64/128/256 all 32bpp — I parsed the same bytes with Pillow) |
| tools/run_game.sh in a 16:9 window shows GROUND_PAGE bars (manual look, recorded in the commit) | unverifiable here | no interactive window in this run; the 1820x1024 keep shot is the instrument's equivalent and shows the bars (§3). The orchestrator's commit message must carry the look. |
| Shot: MainMenu 1820x1024 --set=display_aspect=keep shows GROUND_PAGE bars | yes | §3, my own shot |
| Assets: splash 1536x1024 emblem + wordmark_58 + tagline on GROUND_PAGE | yes | Pillow: (1536,1024), all four corners (3,11,19); content bbox x 379..1156 y 404..546; viewed with Read (whole frame and a 1x crop of the lockup): skull emblem, metallic blackletter "A Guild Story", "Bad People. Worse Decisions." with the trailing rule, on flat navy, centred 37px above geometric centre |
| icon_256 from the emblem; icon.ico via Pillow | yes | icon_256 viewed at 3x: skull + ring of links on a rounded navy plate with a bronze rim; rim pixel (133,106,87) = EDGE_BRONZE; corners transparent. .ico frames 48/32/24/16 viewed at 8x: 48 and 32 read as the mark, 24 soft, 16 a silhouette |
| No text beyond the pre-rendered logotype (+ tagline, which the plan's Assets line names) | yes | the splash carries the logotype and the tagline only; icon carries no text |
| Green: no screen touched | yes | no game/screens or game/ui file is in the owned list and none carries this unit's fingerprints |

## 5. Green / §0.5 contracts

- Label/Button texts and node names: no screen or kit file touched. N/A / PASS.
- Indentation: test_export.gd has 0 leading-tab lines (four spaces throughout). gen_wordmark.py is Python
  (spaces). PASS.
- `create_tween` / `reduced_motion` / `$GODOT` outside the lock: grep of both owned scripts returns
  nothing. PASS.
- Baked text in new PNGs: splash carries the pre-rendered logotype + tagline (the plan's stated exception);
  icon_256 carries none. PASS.
- .import files: splash.png.import and icon_256.png.import are the emblem's with fresh uids
  (uid://vxbiqf660bwc, uid://dicontw0page2 — both unique in the repo) and correct source/dest paths;
  .godot/imported/ holds the splash and icon_256 .ctex + .md5, so the engine has already imported them
  through the lock. PASS.
- Router host: nothing parented (no screens touched). N/A.
- Pure black/white: splash has 12 and icon_256 has 27 opaque pure-black pixels — every one of them is
  one of emblem.png's own 3 pure-black pixels doubled/tripled (at emblem x 20/43/64, inside the skull);
  inherited from the shipped emblem, not introduced here. Not a token; not a finding against this unit.
- Handoff: three edits, each `## N. <path>:<line>` with an `old:` and a `new:` fenced block. Verified the
  old blocks against the live files: docs/15-open-questions.md:2507 and :2527-2529 and
  build/plan/q-housekeeping.md:45 match character for character. Markdown, no indentation question.
  PASS.
- Plan §1 says "Wave 0 handoffs expected: none"; this unit's three are record-truth edits to two
  registers that still say the .ico is deferred. Reasonable and clearly labelled optional. Minor note.

## 6. Judgement calls vs the plan (§6 reservations)

- CRITIC.md:247 and 00-plan.md:471 both list "the splash/icon/clear colour (G01)" as decidable without
  the designer. Nothing here touches a §6 question. Q16 (is the logotype exempt from "no text in art")
  is left open by the plan itself and the plan's Assets line already names the splash's content.
- Re-rendering the wordmark/tagline at 2x from the fonts (not resampling the 1x bitmaps) — within the
  generator the unit owns; the 1x outputs are byte-identical (verified). OK.
- Flood-keying the emblem crop's border-connected ground to GROUND_PAGE — 1876 of 4674 px; the eye
  sockets are kept. Viewed: no crop box. OK. One consequence: a 1x3 bone-coloured speck at the crop's
  right edge (emblem.png column 81 rows 9..11, part of the ring of links cut by the crop) is real art,
  so the key leaves it; it shows as a small stray mark just left of the "A" on the splash
  (x 541..542, y 440..445) and near the icon's right rim (x 248..250, y 69..77). Cosmetic; minor.
- The console wrapper gets the same .ico; frame sizes chosen by the unit; a rounded plate with a rim —
  packaging choices inside the owned generator. OK.
- `boot_splash/use_filter` is left at Godot's default (true): the pixel-art emblem in the splash is
  bilinear-filtered when the window is not exactly 1536x1024, while the game itself uses nearest
  (`textures/canvas_textures/default_texture_filter=1`). Not in the plan's acceptance; a one-key
  follow-up. Minor.
- Nothing decided that the plan reserved for the designer. PASS.

## Minors (none blocking)

1. Report inaccuracy: right-bar bleed described as "within 3 units next to the frame edge"; measured up
   to 25 units over 25 columns in both the implementer's shot and mine. The bars are still GROUND_PAGE.
2. Removal of `test_the_preset_ships_the_same_icon_the_project_names` is unrecorded in the report
   (forced by the plan's acceptance; W0-GATE's report line 92 shows it was red for other agents for a
   window before test_export.gd caught up).
3. Stray 1x3 bone speck at the emblem crop's right edge, visible on the splash (left of the "A") and
   the icon (near the right rim). Inherited crop artefact; cosmetic.
4. `boot_splash/use_filter` left at default true (bilinear) against the game's nearest filter.
5. PY generator outputs (splash/icon/wordmarks) are not gated by ART CHECK (build_art.sh iterates
   gen_*.lua only) — pre-existing gap; my scratch regeneration proves determinism today.

## Verdict

**PASS.** No blocker; no unowned file touched; every acceptance line the unit could meet is met and
verified against the tree (generator reproduces every byte; keys pinned; shot re-taken and viewed; the
suite green in my own run). The one line marked unverifiable (the real-window 16:9 look via
tools/run_game.sh) is a human/orchestrator step the plan itself assigns to the commit message. False
claims in the report: none material — the "within 3 units" bleed figure is wrong (measured up to 25
units over 25 columns) but the conclusion it supports (the bars are GROUND_PAGE, not engine grey)
stands. Five minors listed above; none needs a code change before the wave merges.
