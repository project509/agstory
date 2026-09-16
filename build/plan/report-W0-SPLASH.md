# Report — W0-SPLASH (the exported build's first frame is ours)

Finding closed: CRITIC-G01. Plan: build/plan/artaudit/00-plan.md §1 "W0-SPLASH".
Owned: project.godot (additive keys + the config/icon value the plan mandates), export_presets.cfg,
tools/art/gen_wordmark.py, game/assets/ui/splash.png(+.import), game/assets/ui/icon_256.png(+.import),
game/assets/ui/icon.ico, tests/unit/test_export.gd. Companion: build/plan/handoff-W0-SPLASH.md.

## Acceptance

- [x] gen_wordmark.py emits splash.png (1536x1024, emblem + wordmark_58 + tagline on GROUND_PAGE), icon_256.png (256x256) and icon.ico; the three existing wordmark outputs stay byte-identical.
- [x] project.godot: `application/boot_splash/image`, `application/boot_splash/bg_color == Palette.GROUND_PAGE`, `rendering/environment/defaults/default_clear_color == Palette.GROUND_PAGE`, `config/icon` square 256x256.
- [x] export_presets.cfg: the Windows preset points `application/icon` at icon.ico.
- [x] .import files beside the two new PNGs (copied from a neighbour, fresh uids).
- [x] tests/unit/test_export.gd asserts all of the above and passes.
- [x] Shot: `MainMenu 1820x1024 --set=display_aspect=keep` shows GROUND_PAGE bars beside the frame (viewed with Read).
- [x] splash.png and icon_256.png viewed with Read; the emblem looked at at 32px (BL-67 asked for that look).
- [x] `verify.sh --fast` green (summary pasted below); `tools/lint_motion.sh` prints MOTION LINT OK.

## Judgement calls

- The splash's wordmark and tagline are RE-RENDERED from the fonts at 2x (outline/shadow/pad doubled), not the 1x bitmaps doubled; the emblem, sliced pixel art, is doubled NEAREST. The 1x pipeline is untouched: sha256 of wordmark_58/44/tagline .png+.json before == after.
- The emblem is an opaque crop whose ground is a noisy (7,14,22) — on GROUND_PAGE it showed as a faint box. Fixed by flood-keying only the border-connected region (tol 28, 1876 of 4674 px) to GROUND_PAGE; the eye sockets, the same navy but enclosed, keep the artist's pixels.
- icon_256 is the emblem at 3x NEAREST on a GROUND_PAGE plate, radius-36 corners, 2px EDGE_BRONZE rim: packaging, not a second mark (BL-67's worry). Colours are read from Palette.gd, never restated.
- .ico frames 256/128/64/48/32/24/16 are produced here (box-reduce for the integer sizes, Lanczos for 48/24), not by Pillow's resampler. The console wrapper gets the same .ico so Explorer shows one icon.
- Optical centre: the lockup block sits 1024/32 = 32px above geometric centre.
- The `.import` files are the emblem's with the dest md5 computed the way Godot does it (md5 of the res:// path — checked against the emblem's own) and fresh valid uids; Godot fills the ctex on the next --import.

## Log

- Generator: `python tools/art/gen_wordmark.py` prints the three legacy lines unchanged, then `splash: (1536, 1024) lockup x 379..1157 caps top 411 baseline 490 tagline baseline 540 ground (3, 11, 19) emblem px keyed 1876`, `icon_256: (256, 256) emblem x3 at 5,42`, `icon.ico: [256, 128, 64, 48, 32, 24, 16]`, `GEN_WORDMARK OK`. Diff of sha256 lists: BYTE-IDENTICAL.
- Viewed splash.png (Read): centred lockup — skull emblem, metallic blackletter "A Guild Story", tagline with the trailing rule — on flat navy; corners (3,11,19). First render showed the emblem's crop box; after keying, the box corner pixel reads (3,11,19) and the centre crop shows no box.
- Viewed icon_256 and the .ico's 48/32/16 frames at 8x: 256 is crisp on the plate with a bronze rim; 48 and 32 keep the skull, sockets and the ring of links; 16 is a dark rounded square with a bone-coloured skull blob — a silhouette, which is what 16px can carry from an 82x57 crop (BL-67's "look at it at 32px" done).
- project.godot: config/icon -> icon_256.png; boot_splash/image + bg_color under [application]; default_clear_color under [rendering]; comments rewritten to say why. export_presets.cfg: application/icon and console_wrapper_icon -> icon.ico.

## Resume (second agent, 2026-09-14)

The first agent was cut off after the fourth box. Re-verified the four ticked items before touching anything:
- `git status game/assets/ui/` lists only the five new files (splash.png/.import, icon_256.png/.import, icon.ico); wordmark_58/44/tagline .png+.json are NOT modified, so the legacy outputs are byte-identical to HEAD (sha256 of wordmark_58.png 4b3736b2dd166b98…).
- splash.png: 1536x1024 RGBA, all four corner pixels (3,11,19) = GROUND_PAGE #030B13. Viewed with Read: the skull emblem, the metallic blackletter "A Guild Story", the tagline and its trailing rule sit as one centred lockup (x 379..1157) on flat navy, a hair above centre; no crop box around the emblem.
- icon_256.png: 256x256 RGBA, transparent corner (rounded), rim pixel (133,106,87) = EDGE_BRONZE #856A57, plate (3,11,19). Viewed with Read: the skull with its ring of links fills the plate, sockets dark, rim visible on every edge.
- icon.ico: Pillow reports frames 256/128/64/48/32/24/16; each frame decodes.
- project.godot diff: config/icon -> icon_256.png, boot_splash/image + bg_color under [application], default_clear_color under [rendering], both Color(0.011764706, 0.043137256, 0.07450981, 1) = #030B13. Every other key untouched (additive). export_presets.cfg: application/icon and console_wrapper_icon -> icon.ico, comment rewritten; nothing else in the preset moved.
- tools/shot.gd already carries the `display_aspect` branch (`_place_host`, `_display_aspect`; header lines 67-72) from W0-SHOT, so the wide-keep shot can be taken in this wave.
- Viewed the .ico's 48/32/24/16 frames side by side at 8x NEAREST (scratchpad ico_frames_8x.png, decoded from icon.ico with Pillow): 48 is crisp (skull, both sockets, nose, teeth, the ring of links); 32 keeps the skull, sockets and links with the links softening; 24 is a soft skull with two dark sockets; 16 is a bone-coloured skull silhouette in a dark rounded square with the bronze rim still a warm edge. Every frame reads as the same mark; nothing at 32 needs redrawing. Frame corners are transparent (rounded plate), centres are the navy plate, so the taskbar shows a rounded tile, not a square.
- Handoff (build/plan/handoff-W0-SPLASH.md) carries three record-truth edits, none applied here: docs/15 BL-67's heading marker and a "Landed" paragraph, and build/plan/q-housekeeping.md:45's marker — both registers still say the .ico is deferred. Checked before writing: BL-67 sits under an explicit `<a id="bl-67">` anchor (heading text is not a slug), and the new paragraph cites paths in backticks, not links, so test_docs_links has nothing new to resolve. W4-HYGIENE may take these instead.
- Shot taken through the lock: `shot.gd -- res://game/screens/MainMenu.tscn build/shots/MainMenu_splash_keep.png 40 1820x1024 --set=display_aspect=keep` printed `SETTINGS defaults + { "display_aspect": "keep" }` and `SHOT OK build/shots/MainMenu_splash_keep.png 1820x1024` (own filename; W0-SHOT's MainMenu_wide_keep.png left alone). Viewed with Read: the whole MainMenu — aerial town plate, "A Guild Story" lockup, the red New Guild CTA with its focus ring, Continue disabled with "No saved guild found." beside it, Load/Settings/Quit — sits centred at 1536 wide with a flat dark-navy bar on each side; no engine grey anywhere, no seam at the frame edge.
- Measured with Pillow: 1820x1024; columns 0..141 and 1678..1819 are uniform (0,13,18) (18176 of 18176 sampled left-bar pixels; 16614 of 16768 right-bar pixels, the rest within 3 units next to the frame edge — the stage's screen-space glow bleeding a few pixels past x 1678, LESSONS' known post-process). Nominal GROUND_PAGE is (3,11,19); (0,13,18) is what the HDR-2D mobile renderer makes of it after the sRGB round trip, the same shift every screen's own ground pixel takes — the bars are the clear colour, not a texture, and they are ours. The frame starts at x 142 exactly: (1820-1536)/2.

## Green (2026-09-14, through the lock)

`GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast`:
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
  PASS  TESTS PASSED   1604 test(s) in 72 file(s)  [33924 ms]
VERIFY OK  (full log: .verify.log)
```
`tools/lint_motion.sh`: `MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`.
tests/unit/ holds 72 test_*.gd files and the runner reported 72, so test_export.gd (18 `func test_`, the 6 first-frame/icon cases among them) is in the run; the suite has no filter, so its pass is inside TESTS PASSED. Stages 4-7 are --fast skips; the orchestrator's full gate runs them.

## Left for the orchestrator / a human

- The plan's "manual look" — `tools/run_game.sh` in a 16:9 window showing GROUND_PAGE bars — is a real-window observation the commit message is meant to record; it was not taken here (no interactive window in this run). The 1820x1024 `keep` shot above is the same composition through the instrument and is the evidence on disk.
- The exported .exe's first frame (Godot's splash stage) cannot be shot by shot.gd; the keys are pinned by test_export.gd and the image is viewed above. A real export (`tools/export_build.sh`, minutes, 130 MB) is the only way to see it live.
- The three handoff edits (docs/15 BL-67, build/plan/q-housekeeping.md) — record truth only.
