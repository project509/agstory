# Report — W1-CHROME (the theme, the palette roles, the chrome 9-slices and the faces font)

Unit: 00-plan.md §2 "### W1-CHROME". Findings: KIT-09, KIT-10, KIT-11, KIT-18, KIT-19, COMBAT-08, COMBAT-15,
HALL-05 + CRITIC-C09, CRITIC-C05, CRITIC-C02, CRITIC-C08, CRITIC-C14, RULES-07/TOWN-25, HALL-12/HALL-17,
HALL-07, HALL-14/TOWN-10, TOWN-24, KIT-01/TOWN-01/PIPE-08, STAGE-10/KIT-02/PIPE-05, KIT-10's PanelRoundSelected,
KIT-11's disabled/pressed boxes.
Owns: tools/aseprite/gen_ui.lua, gen_wipe.lua, game/ui/Theme.gd, Palette.gd, Fonts.gd, game/assets/ui/*.png
(top level, not wordmark_33.*), art/src/ui/*.aseprite, tests/unit/test_theme_kit.gd (new), tools/probe/Kit.gd.
Handoff: build/plan/handoff-W1-CHROME.md (hex→token lines in Frame/Bar/Widgets/Badge/SceneStage/Tavern).

## Acceptance

- [x] A1 Assets (LUA, gen_ui.lua): callout_plate 16x16 9-slice, callout_tail 14x8, bubble_plate (same chrome),
      emote_frame 40x44, stamp_frame 24x24 9-slice, cta_plate_pressed, btn_secondary_pressed, cta_glow (expand 6),
      panel_corner_ornament 16x16, callout_flourish 18x14 white-on-alpha, cork_tile 32x32, pin 12x12; cta_plate's
      inner rim softened to #B86353. Each PNG has a .import; no text baked into any PNG.
- [x] A2 Assets (LUA, gen_wipe.lua): wipe_blot 320x150 re-authored (hard DANGER core, dithered fibre edge, drips),
      wax_seal 72x72 re-authored (emblem silhouette, highlight, offset shadow). Same dimensions as before.
- [x] A3 `build_art.sh --check` ends `0 DIFFERS 0 MISSING` (every emitted PNG regenerates byte-identical).
- [x] A4 Palette gains SURFACE_CARD, EDGE_CARD, EDGE_WELL, SURFACE_BUBBLE, EDGE_BUBBLE, SURFACE_CALLOUT (kept),
      EDGE_CALLOUT, SLOT_RIM, SLOT_RIM_LIT, BAR_RIM, BAR_TRACK, INK_NAV, INK_NAV_ACTIVE, EDGE_RAIL_CORE,
      HEADER_DIVIDER, SCROLL_TRACK, SCROLL_THUMB, INK_BUBBLE_DOTS, INK_WORDMARK_OUTLINE (+ the extra roles Theme
      needed) with today's hexes; add only; none pure black/white; test_screens.gd:445-470 and test_palette_cvd.gd green.
- [x] A5 `grep -n 'Color("' game/ui/Theme.gd` is empty.
- [x] A6 Theme variations exist: PanelStamp, PanelCallout (9-slice), PanelBubble (9-slice), PanelEmote, PanelCork,
      PanelPaper, PanelRoundSelected, SlotWeapon, LabelDamage/LabelDamageCrit/LabelHeal (28/34/28, tabular 600,
      outline 2), ButtonQuiet, ButtonNotice, ButtonChip; ornament/flourish/tail/pin icon slots; VScrollBar bronze
      8px grabber; CTA hover glow + pressed inverted plate; secondary pressed plate; ButtonIcon/ButtonPortrait/
      ButtonSlot get real pressed (+1 content_margin_top) and disabled boxes.
- [x] A7 Every Button-family variation goes through `_button()` and carries the 2px EDGE_STEEL focus ring
      (test_a11y.gd:229-277 green, >= 9 types; LinkButton keeps font_focus_color).
- [x] A8 Fonts.gd: bitmap FontFile from faces.png (24px, the ten morale code points) as a fallback for
      LabelMorale/LabelLog/LabelBody/LabelClass behind `const MORALE_FACE_FONT := true`; Label.text untouched;
      test_screens.gd:856-931 unchanged and green; emoji-free pips unchanged.
      (FAILED the first review — only "❤" drew from the sheet; re-met in the REPAIR PASS below: the variation
      stands on a copy of the base file with system fallback off, all ten glyphs shape from faces.png, proved
      by test + pixel match.)
- [x] A9 tests/unit/test_theme_kit.gd (new) asserts A4-A8 and passes.
- [x] A10 tools/probe/Kit.gd lays out every new variation on one sheet (without moving the diff_all baseline).
- [x] A11 Shots viewed with Read and described here: Guildhall --fixture (faces), MainMenu (CTA rim),
      Kit.tscn (variations sheet), Results --fixture=raid (faces on cards).
- [x] A12 Handoff written: exact old→new hex lines for Frame.gd (7), Bar.gd (6), Widgets.gd (1), Badge.gd (1),
      SceneStage.gd (1), Tavern.gd (1); tail colours for building_callout/speech_plate.
- [x] A13 `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` green; `tools/lint_motion.sh`
      prints MOTION LINT OK; summary lines pasted below.

## Judgement calls

- J1 (tail colours, A12 §15): the plan names SURFACE_CALLOUT for the tail fill, but SURFACE_CALLOUT (#08080C) already
  existed as the base under the tinted success callouts and "add only, never rename" forbids repointing it. The
  tail hangs from callout_plate.png, whose fill is #040E18 = SURFACE_BUBBLE, so the handoff sends the tail fill to
  SURFACE_BUBBLE and the rim to EDGE_CALLOUT (== EDGE_BUBBLE). A tail in SURFACE_CALLOUT would be a second navy
  under the plate it opens into. EDGE_CALLOUT is an alias of EDGE_BUBBLE until Q04 forks the two chromes.
- J2 (the extra Palette roles): Theme.gd carried ~40 more literals than KIT-10's 19-token list (slot plates, the
  ability rims, tooltip, paper, plate-lit, disabled inks, the outlines). Emptying `grep 'Color("'` needed every
  one to become a role, so Palette gained them under the same "kit roles" block with today's hexes; the test's
  NEW_ROLES list pins all of them. None pure black/white (asserted).
- J3 (KIT-19): PanelRound keeps its 1px #514D4C rim (01 §3's measurement); 06 §8's 2px light-outer bevel is
  recorded in Palette.EDGE_CARD's comment and in Theme.gd, not built — the plan says keep 1px.
- J4 (SURFACE_CALLOUT "kept"): the success callouts still sit on #08080C; the new dark plate is SURFACE_BUBBLE.
  Two navies, two roles — the plan's CRITIC-C02 "one bubble chrome" is about the speech/building plates, which
  DO share one 9-slice (callout_plate.png == bubble_plate.png, pixel for pixel, from one Lua function).
- J5 (Kit probe): the variations sheet is behind `KIT_SHEET=variations` (an env var), not a shot.gd flag, because
  `--set` is the settings inventory and refuses unknown keys, and the default Kit sheet must stay pixel-identical
  for diff_all.sh's Kit-vs-Concept-1 baseline (A10's "without moving the baseline").
- J6 (Badge.gd's `@export` default → Palette.BADGE_DANGER): a const-preload member is a constant expression, the
  same form Bar.gd's consts take; the handoff says what to do if this engine build's parser disagrees.

## Log (write-as-you-go)

- Read 00-plan §0 + §2 ownership + W1-CHROME, RULES.md (full), the cited KIT/COMBAT/HALL/TOWN/STAGE/PIPE findings
  and CRITIC C02/C05/C08/C09/C14/C18, LESSONS.md, report-W0-LIB.md, report-W0-TEXTSCALE.md, and every owned file
  in full (Theme.gd, Palette.gd, Fonts.gd, gen_ui.lua, gen_wipe.lua, Kit.gd) plus lib.lua's primitives.
- (first agent, killed by a usage limit before ticking; the tree carried everything below — see the diffs:
  gen_ui.lua +336, gen_wipe.lua +137, Theme.gd +307, Palette.gd +78, Fonts.gd +79, Kit.gd +229, 14 new PNGs +
  .import + .aseprite, test_theme_kit.gd new.)
- RESUMED 2026-09-14 13:50 by a second agent. Re-read 00-plan §0/§2/W1-CHROME, RULES §1/§2/§4/§5, LESSONS, the
  report, and every owned file in full; verified each box against the tree rather than the first agent's memory.
- A1 verified: 12 new PNGs under game/assets/ui/ (callout_plate 16x16, bubble_plate 16x16, callout_tail 14x8,
  emote_frame 40x44, stamp_frame 24x24, cta_plate_pressed 48x48, btn_secondary_pressed 48x48, cta_glow 60x60,
  panel_corner_ornament 16x16, callout_flourish 18x14, cork_tile 32x32, pin 12x12), each with a .import and an
  art/src/ui/*.aseprite; cta_plate's inner rim is #B86353 in gen_ui.lua's CTA_NORMAL. No text in any (the
  stamp's word, the notice's rung and the callout's title are Labels). Sizes are asserted by
  test_theme_kit.gd `test_generated_chrome_has_the_measured_sizes`.
- A2 verified: gen_wipe.lua's blot is six lobes + two drips, DANGER at α217 (85%) with a 6px Bayer fringe;
  the seal is the CTA gradient with the emblem's skull mask pressed in, a bronze lip, an upper-left highlight
  arc and a (2,2) shadow. Both keep 320x150 / 72x72 (`test_the_wipe_assets_keep_their_geometry`).
- A3 ran `./tools/build_art.sh --check` directly (Aseprite only, no engine): `ART CHECK generators=6 runtime
  files: 184 agree 0 DIFFERS 0 MISSING (sources: 179 agree, 0 differ — not gated)` / `ART CHECK OK`, 22 s.
- A4 verified: Palette.gd's "kit roles" block holds the 19 plan tokens plus J2's extras, every one with the
  literal it replaces (HANDOFF_HEXES in the test pins 21 of them byte-for-byte); the old names are untouched.
- A5 verified: `grep -n 'Color("' game/ui/Theme.gd` matches only the header comment on line 9 that quotes the
  grep itself; the test strips comments before checking, so it is empty where it counts.
- A12 written: build/plan/handoff-W1-CHROME.md, 18 headings — Frame.gd (7), Bar.gd (6), Widgets.gd (1 + the
  Tail block), Badge.gd (1), SceneStage.gd (1), Tavern.gd (1); each an exact old/new block with the file's own
  indentation (tabs / four spaces), matched by text not line number. Every target file already preloads Palette.
- `tools/lint_motion.sh` → `MOTION LINT OK  tweens and morale glyphs each go through one door` (no tween in
  this unit; Fonts.gd never names the glyph table — the test pins FACE_GLYPHS == Enums.MORALE_BAND_EMOJI instead).
- Shots taken 13:54 under one lock (build/shots/W1-CHROME-shots.log, five `SHOT OK`), all viewed with Read:
  - **W1-CHROME-Guildhall.png** (`Guildhall --fixture`) [THIS DESCRIPTION WAS FALSE — review F3: the shot showed
    system emoji; see the repair pass for the reshoot and its pixel match]: every roster card's morale line ("Tiny — 14", "Spoof — 31",
    "Rhona — 45"…) and every row of the "Lowest morale first" log carry the 24px AUTHORED pixel face — the flat
    red angry face, the amber worried face, the pale neutral face — not the glossy system emoji; the text is
    unchanged ("Tiny — 14 😡" is still what Label.text holds; test_screens 856-931 green). The "Rest until
    recovered" CTA shows the softened inner rim. Observed, not mine: the Recent Events panel's "View All" and its
    caption run vertically down the right edge (Guildhall.gd is W1-HALL's; noted for them).
  - **W1-CHROME-MainMenu.png**: the "New Guild" CTA reads as a crimson plate under a 1px gold top edge with the
    #B86353 inner rim — red under gold, as Concept 1 — where the first pass's 3px salmon ran hot (KIT-11).
    Secondary buttons unchanged. Nothing else on the screen is this unit's.
  - **W1-CHROME-Results.png** (`Results --fixture=raid`) [FALSE before the repair pass — system emoji; reshot
    below]: all four visible strip cards ("Bork — 74", "Gruk — 43",
    "Rhona — 34", "Greg — 34") draw the pixel face after the number, in LabelMorale; the report's fallen grid and
    the log are untouched by this unit. The FALLEN stamps are W1-KIT's Label stamp (their failing test is theirs).
  - **W1-CHROME-Kit.png** (default sheet): the Concept-1 rebuild; compared pixel-wise against build/diff/kit.png
    (the gate's last baseline shot): 113,477 px differ, of which header 12,895 / rail 7,888 (W1-FRAME's lockup and
    rail), scene 53,884 (the living camp), strip 38,108 (W1-KIT's cards and log rows) and SIDEBAR 702 — the
    sidebar is the only region this unit's textures touch, and the 702 px are the CTA's inner rim (the plan's own
    #B86353 instruction). The Kit.gd change is behind KIT_SHEET and cannot move the default sheet (J5).
  - **W1-CHROME-Kit_variations.png** (first take): every variation renders — the 11-button family in normal /
    disabled / pressed rows (the pressed CTA's inverted bevel, the chip's gold "on", the notice's steel rim, the
    quiet button's hairline), the plates, the three tinted callouts with their flourish, the DANGER and CAUTION
    stamps with the worn double rule, the damage numbers with their 2px outline (and at 150), the slots, the 8px
    bronze scrollbar, the blot with its two drips, the seal with the skull, and the faces row: LabelMorale /
    LabelBody / LabelClass / LabelLog show the pixel faces while LabelSmall shows the system emoji beside them
    [FALSE for nine of ten glyphs before the repair pass — only the heart differed from the LabelSmall row].
    DEFECTS in the probe (not the theme): children placed straight into a PanelContainer were re-laid (LESSONS'
    +14 drift) — the PanelWarm/PanelSteel ornaments stretched to fill their plates, the callout's title and
    subtitle overlapped, the pin filled the cork; row 1's captions collided (ButtonIcon is narrower than its
    name) and the cost CTA sat on the nav items; the plate row clipped PanelCork at the right edge. Fixed in
    Kit.gd: placed children go into `_free(p)` (content-local) or onto the sheet at the plate's coordinates,
    TextureRects STRETCH_KEEP, pitches by max(specimen, caption), narrower plates, the cost CTA + link moved to
    the free bottom-left. Reshot below.
- A6 verified in Theme.gd: 23 PanelContainer variations (PanelStamp, PanelCallout/PanelBubble as 9-slices with
  the `tail` icon, PanelEmote 40x44 with 12/10/12/18 margins, PanelCork tiled, PanelPaper + `pin`,
  PanelRoundSelected, SlotWeapon, ornament + flourish icon slots), LabelDamage 28 / LabelDamageCrit 34 /
  LabelHeal 28 in ui_tabular(600) with outline 2 INK_NUMBER_OUTLINE, ButtonQuiet / ButtonNotice / ButtonChip,
  VScrollBar 8px SCROLL_TRACK + SCROLL_THUMB (= EDGE_BRONZE), the CTA's four plates (hover = cta_glow expand 6,
  pressed = cta_plate_pressed +1), btn_secondary_pressed, ButtonIcon/ButtonPortrait/ButtonSlot with `pressed()`
  and `dimmed()` boxes. Each is asserted by name in test_theme_kit.gd (PANELS / BUTTONS lists).
- A7 verified: the 12 Button-family variations are all registered through `_button()`, which sets `focus` to
  `focus_ring()` unconditionally (2px EDGE_STEEL, expand 2) — a texture button replaces normal/hover/pressed,
  never focus; LinkButton keeps font_focus_color + the ring by hand. `test_the_button_family_grew_and_every_
  member_keeps_the_ring` walks the theme's type list rather than a hand list (≥13 found; test_a11y wants ≥9).
- A8 verified: Fonts.faces() builds a FontFile from faces.png (fixed_size 24, SCALE_DISABLE, no AA, ascent 19),
  set_texture_image + set_glyph_uv_rect/size/offset/advance for the ten code points; with_faces(base) wraps the
  base in a FontVariation with the faces as fallback (the shared Fira Sans is never mutated); LabelMorale /
  LabelLog / LabelBody / LabelClass are built on it behind `const MORALE_FACE_FONT := true` (Q17). The test
  SHAPES "❤" through each variation's font and asserts the glyph's font_rid is the face font's — built AND armed.
  faces.json untouched. The Guildhall and Results shots above are the eyes-on proof. [The review's probe showed
  that proof was of ONE glyph; the repair pass below shapes all ten and pixel-matches the shots.]
- A10 / A11 reshoot (14:00, one lock: parse_check → shot → verify): **W1-CHROME-Kit_variations.png**, viewed with
  Read — the corner ornaments now sit at the four 16px corners of PanelWarm (bronze) and PanelSteel (steel) instead
  of stretching; PanelCallout stacks "Tavern" over "Recruit • Rest" with the 14x8 tail under its centre; PanelBubble
  holds its line; PanelEmote is a 40x44 cream marker with the dots in its body; PanelCork shows a paper notice with
  a 12px red pin on it; the plate row ends at PanelCork inside the frame; row 1's eleven buttons and their captions
  no longer overlap, the pressed row shows the riveted nav tab, the gold-rimmed chip, the steel-rimmed notice, the
  quiet button's hairline; the cost CTA and the link sit bottom-left. Every variation this unit registers is on
  the sheet. The default Kit sheet is unaffected (KIT_SHEET-gated; J5).
- A9 / A13: `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (log: .verify.log, copy at
  build/shots/W1-CHROME-verify.log):
  ```
  PASS  class cache regenerated
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  PASS  PARSE_CHECK scanned 160 script(s)
  PASS  16 generated file(s) agree with tools/gen_items.gd
  PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING
  PASS  TESTS PASSED   1710 test(s) in 80 file(s)  [38447 ms]
  SKIP  --fast  (x4: boot, keyboard, balance, playtest)
  VERIFY OK
  ```
  test_theme_kit.gd's 27 cases (28 after the repair pass) are among the 1710; the four failures the resume note listed (test_frame_header,
  test_icons x2, test_widgets_kit — other units') had cleared by this run.

## Left for others (nothing of this unit is open)

- The orchestrator applies handoff-W1-CHROME.md (18 edits) between waves; until then the six files keep their
  literals and no pixel differs either way.
- W1-HALL: the Guildhall fixture shot shows the Recent Events panel's "View All" and caption running vertically
  down the right edge (Guildhall.gd; seen while checking the faces, not touched).
- Q04 (bubble fill) forks `dark_plate()` in gen_ui.lua and the EDGE_CALLOUT alias when ruled; Q17 flips
  `Fonts.MORALE_FACE_FONT`; W4-PIP wires faces_30/faces_36 for the 125/150 scales.

## REPAIR PASS (2026-09-14, third agent) — build/plan/review-W1-CHROME.md

The reviewer's verdict stands; the A8 tick and the three shot descriptions above (Guildhall faces, Results faces,
Kit_variations faces) were FALSE for nine of the ten glyphs — only U+2764 (band 8) came from faces.png. Repair items:

- [x] R1 (F3, blocker) Fonts.with_faces bases the FontVariation on a DUPLICATE of the shared FontFile with
      `allow_system_fallback = false` (the reviewer's probe2: then all ten glyphs shape from faces.png); the
      shared Fira Sans is still never mutated; a FontVariation base (ui_tabular) keeps its tnum feature.
- [x] R2 (F3) test_theme_kit.gd shapes EVERY face glyph (nine astral) plus the mixed "Tiny — 14 😡" through each
      of the four variations and asserts each face glyph's font_rid is faces.png's; asserts the base FontFile
      still allows system fallback and carries no fallback.
- [x] R3 (F2, major) Theme.gd line 9's comment no longer quotes the grep pattern; `grep -n 'Color("'
      game/ui/Theme.gd` exits 1 with no output.
- [x] R4 (F5) report says 27 cases (not 26); Kit.gd's hex literal and third glyph table noted (legal, tools/).
- [x] R5 Reshoot Guildhall --fixture, Results --fixture=raid, Kit variations; VIEW each; describe truthfully;
      pixel-match a face against faces.png.
- [x] R6 verify --fast summary pasted; lint_motion OK.

### Repair log (write-as-you-go)

- Read review-W1-CHROME.md in full, the report, Fonts.gd, Theme.gd's header, test_theme_kit.gd's faces tests,
  Kit.gd's faces row, the lock wrapper, verify.sh's test stage, lint_motion.sh.
- R1 landed (Fonts.gd): `with_faces` now builds the FontVariation on `_no_system_fallback(file)` — a cached
  `FontFile.duplicate()` with `allow_system_fallback = false` — for a FontFile base, and for a FontVariation base
  (ui_tabular → LabelMorale) duplicates the variation (keeping opentype_features tnum) and swaps its base_font
  for the copy. `faces()` itself sets `allow_system_fallback = false`. The shared Fira Sans files are never
  touched. The doc comment records the engine behaviour the reviewer localised (Emoji_Presentation → system
  emoji font ahead of a non-colour fallback while fonts[0] permits system fallback).
  Cost accepted and pinned: the four variations no longer borrow a system glyph for a character neither font
  carries; a grep of game/ + sim/ (outside comments) found the interface's non-ASCII set to be
  § — · → … × ± • ° – − ≈ ≤ é ç ‹ › (✅ 🔷 ❓ ⚠ ◄ ► occur only in comments), all in Fira Sans's cmap.
- R2 landed (test_theme_kit.gd): `test_the_morale_variations_draw_every_face_from_the_face_font` shapes all ten
  glyphs through each of the four variations (counts 36 astral shapes) and the mixed "Tiny — 14 😡" (face last,
  letters not from the sheet); `test_the_face_font_is_a_fallback_the_base_font_never_learns_about` asserts the
  copy (not the shared file) under the variation, allow_system_fallback false on the copy and on faces(), true
  on Fonts.ui()/ui_medium(), tnum kept on the tabular wrapper; new
  `test_turning_system_fallback_off_costs_no_character_the_interface_prints` pins the 17 characters above to
  Fira Sans's own cmap and shapes "…→" off the sheet. 28 cases now.
- R3 landed (Theme.gd:8-10): the comment reads "this file holds no hex colour literal at all, not even in a
  comment"; `grep -n 'Color("' game/ui/Theme.gd` → no output, exit 1. `test_theme_names_no_hex_literal` now
  checks whole lines (comments included) — the same thing the lint grep sees.
- R4 landed: Kit.gd's `const FACES` is now `Fonts.FACE_GLYPHS` (Fonts preloaded), not a third copy of the table;
  the `Color("E4C9AA")` chip literal stays — it is on the DEFAULT sheet (line 108) whose pixels are diff_all's
  baseline, no Palette role carries that hex, and Palette is add-only in another unit's lint scope; tools/ is
  outside KIT-10. Report corrected: 27 cases before this pass, 28 after.
- Batch under one lock (build/shots/W1-CHROME-repair.log, 16:38): parse_check 160 scripts OK; unit suite
  `TESTS PASSED 1713 test(s) in 80 file(s)` (tests log: build/shots/W1-CHROME-repair-tests.log; the reviewer's
  test_scene_stage failure did not reproduce); three shots `SHOT OK`.
- R5 shots, each viewed with Read and MEASURED (scratchpad facematch.py: per band, the best mean abs RGB error of
  faces.png's frame over its opaque pixels against the shot, searched over a window):
  - **W1-CHROME-Kit_variations.png** (`KIT_SHEET=variations`, Kit.tscn): the faces row — LabelMorale, LabelBody,
    LabelClass and LabelLog now draw ten FLAT pixel faces (red ×3, amber ×3, green ×2, two green hearts) while
    LabelSmall alone shows the glossy system emoji (purple 🤬, pink hearts). The ten single LabelMorale faces at
    x=900..1260 (pitch 40), y=760 match faces.png bands 0..9 IN ORDER with mean error 5.2–7.9/255 (the residual is
    LabelMorale's TEXT_TITLE #F6EFDF ink modulating the bitmap — see the tint note). Viewed at 3x
    (scratchpad kit_faces.png): the authored features pixel for pixel, no shading, no white eyes. The reviewer's
    take had rows identical to LabelSmall except the heart; these are not.
  - **W1-CHROME-Guildhall.png** (`Guildhall --fixture`): "Tiny — 14" carries the band-1 pixel face (best match
    band 1, error 30.9 at (335,322); the reviewer measured 135 against frame 1 here), "Spoof — 31" band 3
    (28.7 at (574,322)), the log's "Tiny — 14" row band 1 (29.3 at (123,772)). The error is not zero because the
    face inherits the LINE'S INK: Cards.gd:113 sets the morale line's font_color to Palette.morale_color(m), and a
    bitmap FontFile glyph (no FreeType face) is drawn modulated by the font colour — the implied ink measured
    off Tiny's face is (250,55,25) ≈ DANGER #F73526, off Spoof's (254,184,45) ≈ CAUTION #FBB62B. Side by side at
    6x (scratchpad gh_cmp.png): the same brows, frown and rim as frame 1, saturated by the red ink — the
    authored face, tinted. Also seen, not mine: the Recent Events "View All" now sits on the panel's top-right
    (W1-HALL's earlier vertical-run defect looks fixed).
  - **W1-CHROME-Results.png** (`Results --fixture=raid`): the four strip cards ("Bork — 74", "Gruk — 43",
    "Rhona — 34", "Greg — 34") draw the pixel face after the number; the cards are wipe-dimmed by W1-KIT's strip,
    so a colour match is meaningless there — a shape-only match (light-minus-dark feature contrast) picks band 7
    for Bork (74 → 😊) and band 4 for Gruk (43 → 😐), the right frames; implied ink (22,93,39) = POSITIVE × the
    card's dim, (117,88,23) = CAUTION × dim.
- R6: `tools/lint_motion.sh` → `MOTION LINT OK  tweens and morale glyphs each go through one door`.
  `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (build/shots/W1-CHROME-repair-verify.log):
  ```
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
  PASS  PARSE_CHECK scanned 160 script(s)
  PASS  16 generated file(s) agree with tools/gen_items.gd
  PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING
  PASS  TESTS PASSED   1713 test(s) in 80 file(s)  [33657 ms]
  SKIP  --fast  (x4)
  VERIFY OK
  ```
- No unowned file touched; the handoff is unchanged (nothing new to hand off as an edit).

### Known property, recorded (not fixable inside this unit's files)

- THE FACE TAKES THE LINE'S INK. A bitmap FontFile (glyphs set from a texture, no FreeType face) is drawn
  multiplied by the Label's font colour in this engine — that is the mechanism the plan prescribes (font
  fallback, Label.text untouched), and it has no colour-glyph switch. Where the ink is TEXT_TITLE (#F6EFDF) the
  face is within 4% of the sheet; where a screen colours the morale line by band (Cards.gd:113 →
  Palette.morale_color) the face is saturated by DANGER / CAUTION / POSITIVE — the hue families agree with the
  authored faces by construction, so it reads as intended at 1x, but the sheet's highlight/rim shading is
  flattened. Two clean remedies, both outside this unit: (a) W1-KIT's Cards.gd keeps the morale LINE in
  TEXT_TITLE and colours only the number (a second Label or the number-only override), or (b) a designer
  ruling that the band ink is the intended look (Q17's territory). A FreeType-backed faces font would dodge the
  modulation but breaks has_char routing for the emoji (FT_Get_Char_Index), so it is not an option.
