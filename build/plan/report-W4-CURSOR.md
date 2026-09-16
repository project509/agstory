# Report — W4-CURSOR — the pointer and the outline

Started 2026-09-15. Finding: PIPE-15 (no custom cursor; the Town callouts' only hover treatment is a
text colour; the kit's 2px EDGE_STEEL focus ring exists and stays).
Owns: tools/aseprite/gen_ui.lua, project.godot (`display/mouse_cursor/*` only), game/ui/Widgets.gd (the
outline hook on `building_callout`'s plate only), game/ui/shaders/outline.gdshader (new),
game/assets/ui/cursor_arrow.png + cursor_hand.png (+ .import; LUA), tests/unit/test_w4_cursor.gd (new).
Handoff: build/plan/handoff-W4-CURSOR.md. Contract: 00-plan.md §W4-CURSOR, RULES §1-§2, PIPE-15.

## Acceptance

- [x] A1 gen_ui.lua emits `cursor_arrow.png` and `cursor_hand.png`, 32x32, cream #F4EEDD with the kit's
      warm-dark outline (#2A1E18), deterministic; `./tools/build_art.sh --check` prints `0 DIFFERS 0 MISSING`;
      both land in game/assets/ui/ with a .import beside each.
- [x] A2 project.godot: `display/mouse_cursor/custom_image` points at cursor_arrow.png with its hotspot on
      the arrow's tip; nothing else in project.godot touched.
- [x] A3 game/ui/shaders/outline.gdshader (new): an alpha-dilate outline canvas shader — `color`,
      `width` (texels), `fill` (silhouette mode) uniforms; no TIME, no motion, no branching on any setting.
- [x] A4 Widgets.building_callout: an "Outline" Node2D behind the plate (`show_behind_parent`) that draws
      the plate's 9-slice and the tail 2px larger through the shader in `Palette.ACCENT_GOLD_LIGHT`;
      shown while the title Button has focus OR the plate/Button is hovered; hidden otherwise; a locked
      plate never lights; no tween; every existing signature and node name unchanged; the theme's
      `focus` StyleBox on the Button untouched (both show).
- [x] A5 tests/unit/test_w4_cursor.gd (new, four-space) green: the two cursor PNGs exist at 32x32 with
      no pure black/white and the hotspot inside the image; the project setting names the arrow; the
      shader file parses and declares the uniforms; the callout's Outline node exists, is a Node2D behind
      the parent, is hidden at rest, shows on `focus_entered` and hides on `focus_exited`, shows on hover;
      the locked plate has no live outline; the Button's focus StyleBox is still the theme's.
- [x] S1 shot `Town --fixture --focus --tab=1` (the plan's `--tab=8` lands on the rail again — J4) viewed: the outline on the focused callout AND the
      EDGE_STEEL ring on its title.
- [x] S2 shot `Town --fixture` viewed: no outline at rest (nothing changed on the unfocused screen).
- [x] G1 `a11y_smoke` still reports focus leaving the rail (26 mounts); `test_a11y.gd:229-277` green;
      `verify.sh --fast` green (summary pasted below); `lint_motion.sh` → `MOTION LINT OK`.

## Judgement calls

- J1. The cursors are drawn from a MASK (silhouette → 1px-grown ring = the ink outline → cream fill →
  lip/shade by neighbour test → the ring again at +2,+2 as a soft shadow), the icons' own idiom, so the
  arrow and the hand are one family by construction. 1px ink, not the emote frame's 2px: a 32x32
  cursor with a 2px outline read as a sticker at 8x, and the 1px ring plus the shadow is what reads at
  native pixels.
- J2. The hotspot is the visible ink tip, (1,1) for the arrow, (12,1) for the hand's fingertip — one
  row and column of air kept above/left so the OS never clips the tip.
- J3. The hand cannot be set from project.godot (`display/mouse_cursor/*` carries ONE image, the
  arrow); `Input.set_custom_mouse_cursor(..., Input.CURSOR_POINTING_HAND, hotspot)` is runtime code in
  a file this unit does not own, so it is handoff §1 (Boot.gd `_ready`, beside `_apply_display_aspect`).
  The PNG and its .import land now so the handoff is a one-line edit with nothing to generate.
- J4. The plan's `--tab=8` is not a callout on Town: `FOCUS Nav_home (4 shell regions)` and, with
  `Frame.tab_steps_within_region` false (docs/13 §13.1's default), Tab steps REGION to region — TAB 1
  → the Guildhall title (418,182), TAB 2 → "Open the board", TAB 3 → PagerPrev, TAB 4 → Nav_home, so
  TAB 8 is Nav_home. The outline shot is `--tab=1`; the `--tab=8` shot was taken too and is the rail.
  Recorded in the handoff's observations; no file edited for it.
- J5. A shut door never lights: the locked plate's Button is disabled (cannot take focus) and the plate is
  not an affordance — its reason row already says why. The Outline node is still there (one tree shape
  for every plate); its signals are simply not connected when `reason` is non-empty.
- J6. Hover counts the plate AND the title Button, as two bits: a STOP-filtered child (the Button) is the
  hovered control when the pointer is on the title, and whether the plate's own `mouse_entered` fires
  then depends on the engine's hover-hierarchy rule, so listening to both is the reading that cannot
  flicker. The plate body is not itself clickable (Town wires only `btn.pressed`) — noted in the handoff
  as an observation for a later wave, not changed here (a `gui_input` plate would add an a11y_smoke warn).
- J7. Silhouette mode (`fill` 1, `width` 0) for the plate rather than texel dilation: a nine-patch
  stretches its centre texels, so "2 texels" is not "2 pixels" along its edges and nothing can be painted
  outside the control's own rect anyway; the copy is drawn `OUTLINE_PX` larger behind the plate instead
  (`show_behind_parent`), and the plate and tail cover its middle. The dilation (`width` > 0, `fill` 0)
  is the stage-sprite treatment PIPE-15 also names; SceneStage is W4-LIFE's this wave, so it is a
  handoff observation, not wired.
- J8. The tail's ring is `draw_colored_polygon` + two `draw_line`s of width 2·PX + a `draw_circle` at
  the apex under the same material — an exact 2px offset of a triangle at ANY slant (`_aim_tail` slants
  it), where an offset polygon would need per-edge intersections. Untextured draws sample the default
  white texture, so silhouette mode paints them in `color` too (seen in S1: the tail is ringed).

## Log

(appended as work lands)

- gen_ui.lua: a "wave 4 (W4-CURSOR)" section under the pin — `grow(mask)`, `cursor_paint(img, mask)`,
  the arrow (`mask_poly`, seven vertices: a 45° head 16 wide, a 3px tail, a 45° notch) and the hand
  (`mask_rect`/`mask_ellipse` unions: index finger, three stepped folded fingers, palm, thumb, cuff;
  1px shade joins). Palette: #F4EEDD fill, #FBF6E8 lip, #D8CFBB shade, #2A1E18 ink, shadow (11,10,12,110).
  Generated first to `--script-param out=build/w4cursor`, viewed at 8x (build/shots/W4CURSOR_cursor_arrow_8x.png,
  W4CURSOR_cursor_hand_8x.png): the arrow is the classic pointer, cream on ink with a lit left edge and a
  soft shadow down-right; the hand reads as a pointing hand — index up, three knuckles stepping down to
  the right, the thumb on the left, a cuff line. ASCII dump showed the first take's arrow tip at row 2
  and the hand's at row 0; both shapes moved one pixel so the tips are (1,1) and (12,1) with one row
  of air. No pure black/white in either (checked by pixel set).
- Written into the tree (`Aseprite -b --script tools/aseprite/gen_ui.lua`): only the two new PNGs and the
  two new .aseprite sources appear in `git status` — every other UI texture is byte-identical
  (deterministic). `.import` files copied from pin.png.import with the md5(res path) ctex name Godot
  uses. `./tools/build_art.sh --check` → `generators=7 runtime files: 199 agree 0 DIFFERS 0 MISSING`,
  `ART CHECK OK`.
- project.godot [display]: `mouse_cursor/custom_image="res://game/assets/ui/cursor_arrow.png"`,
  `mouse_cursor/custom_image_hotspot=Vector2(1, 1)`, with a comment; nothing else in the file touched.
- game/ui/shaders/outline.gdshader written (canvas_item; uniforms `color` source_color default #FCB85D,
  `width` 2.0, `fill` 0.0, `threshold` 0.5; a `tint` varying carries the vertex colour so a modulated
  plate's ring dims with it; 5x5 round kernel over TEXTURE_PIXEL_SIZE·width/2; `COLOR = mix(tex, color,
  k) * tint`). No TIME, no motion uniform, no setting.
- Widgets.gd (tabs): consts `OUTLINE_PX := 2`, `OUTLINE_SHADER` (the path); `class Outline extends
  Node2D` after `Tail` (show_behind_parent, hidden, ShaderMaterial with color/width 0/fill 1;
  `set_focused`, `set_hovered(bit, on)`, `lit()`, `_draw` = the parent's `panel` StyleBox at
  (-2,-2, size+4) + the tail's offset triangle); in `building_callout`, after the Tail: the Outline
  child named "Outline", `plate.resized -> queue_redraw`, and — only when `reason` is empty — the
  Button's `focus_entered/exited` and the plate's and Button's `mouse_entered/exited`. No signature
  changed, no node renamed, no tween, nothing else in the file touched. `grep '^ ' Widgets.gd` empty
  (no space-led line); parse_check OK (174 → 177 scripts as other units' files landed).
- Imports: `--import` under the lock: `reimport | cursor_arrow.png`, `reimport | cursor_hand.png`; the
  two .ctex now exist (the one `Failed loading resource: cursor_arrow.png` line in the parse-check log
  before the import was the .ctex not yet written — gone after).
- tests/unit/test_w4_cursor.gd (four-space, 8 tests) via scratchpad/run_W4-CURSOR.gd (run_tests.gd's
  loop pinned to the file): first run 7/8 — the shader test's "no TIME/motion" grep hit the shader's own
  header comment; the test now strips `//` lines. Second run `TESTS PASSED 8 test(s) in 1 file(s)`.
- Shots (build/shots/): W4CURSOR_Town.png (--fixture), W4CURSOR_Town_focus8.png (--focus --tab=8 →
  the rail, J4), W4CURSOR_Town_focus1.png (--focus --tab=1 → the Guildhall callout), plus _focus2.
  Crops at 4x of the Guildhall plate (340,150 200x120): W4CURSOR_Town_focus1_crop4x.png — a 2px light-gold
  ring hugging the plate's chamfered corners and wrapping the tail down to its apex, AND the theme's
  2px steel focus ring around the "Guildhall" title inside it; both show, the icon and "Maintain"
  untouched. W4CURSOR_Town_rest_crop4x.png — the same plate at rest: no ring, no gold (the gold-pixel
  count in that window: 865 focused vs 23 at rest — the 23 are the camp's lantern light). The full
  W4CURSOR_Town_focus8.png viewed too: the whole hub as before, no outline anywhere at rest, the
  callouts, sidebar, strip and events panel unchanged.
- Final gate, one lock (scratchpad/w4cursor_batch4.sh; logs scratchpad/w4cursor_verify.log,
  w4cursor_a11y.log): `./tools/verify.sh --fast` →
    PASS  class cache regenerated
    PASS  LINT OK  no cross-file class_name references in sim/ or game/
    PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
    PASS  PARSE_CHECK scanned 178 script(s)
    PASS  16 generated file(s) agree with tools/gen_items.gd
    PASS  ART CHECK  generators=7  runtime files: 204 agree  0 DIFFERS  0 MISSING
    FAIL  unit tests — TESTS FAILED   2/1942 failing  [238511 ms]
  The two failures are both `test_pip_figure.gd` (W4-PIP's new, untracked test file — "LabelPip at 125:
  a pip of band 9, expected ~3.84 got 4.0", a font-advance assertion against Theme.gd/Fonts.gd, which
  that unit is editing concurrently; nothing of mine touches a font). Every other file is green:
  test_a11y (the focus-ring family, :229-277), test_screens, test_widgets_kit, test_town_layout,
  test_w4_cursor (8). VERIFY FAILED is therefore W4-PIP's in-flight state, not this unit's — the
  orchestrator's post-wave gate decides.
  `a11y_smoke.gd` (skipped by --fast, run in the same lock): `A11Y SMOKE PASSED 26 screen mount(s)`;
  Town fixture row `owner='Camp' tab ring=4 rail=6 focusable=14 reachable=14 disabled=2` — focus still
  leaves the rail (tab ring 4 = rail, scene, sidebar, strip) and no new warn.
  `tools/lint_motion.sh` → `MOTION LINT OK`.
- Left undone, and why: nothing in the unit's own text. The hand cursor's runtime registration is
  handoff §1-§2 (Boot.gd, not owned); the stage-sprite use of the shader is W4-LIFE's file (observation).
