# 11 — Godot 4.7 rendering architecture for the overhaul

> **Status:** Decided (two items behind switches) · **Owner:** Art pass · **Updated:** 2026-09-09
> **Read:** project.godot, game/ui/Boot.gd, game/core/ScreenRouter.gd, game/ui/Widgets.gd, tools/verify.sh, tools/build_art.sh, tools/shot.gd

**In one line:** render at the reference's own 1536×1024, letterbox (`keep`) on wider displays so the concepts' composition survives — `expand` stays an opt-in switch —, filter linearly because the art is authored at display density, build one Theme from Aseprite-generated 9-slices, and gate every screen on a headless pixel-diff against its concept.

Invariants respected (BUILD_STATE): autoloads by node name never global identifier (Services.gd); screens are Controls with `build()`; no cross-file `class_name`; the verify gate stays green.

---

## 1. Resolution and stretch

The references are the target framebuffer at 1:1, so the base viewport **is** 1536×1024. The only real question is what happens on a 16:9 monitor (3:2 vs 16:9: at 1080p the window is 1920 wide but the reference frame scaled to 1080 tall is 1620 wide — 300px to account for).

| Option | What the player sees on 1920×1080 | Pixel-parity at 1536×1024 | Cost |
|---|---|---|---|
| (a) base 1536×1024, aspect `keep` | Reference frame scaled ×1.0547, 150px black bars each side | exact | Bars on every widescreen monitor — the common case |
| **(b) base 1536×1024, aspect `expand`** | Frame scaled ×1.0547; logical canvas becomes 1820×1024; header/nav/sidebar/strip anchored to edges so the **scene viewport and the bottom strip widen by 284 logical px** | exact (at 1536×1024 the canvas is 1536×1024 and every anchor resolves to the reference rect) | Every dashboard screen must be built with anchors, not fixed rects — which it must be anyway |
| (c) 16:9 base with the frame centred | Reference-shaped island in a wider field | needs offset handling in the diff | Looks like a port |

**Decision (revised 2026-09-10): (a) `keep`, with (b) `expand` as the opt-in switch.** The first decision was (b). A 1920×1080 shot of the Town overturned it: the scene plates are the concepts' own pixels at a fixed 1536 width, so when the frame widens the plate cannot, and Concept 3's baked-in sidebar showed through beside ours while the strip's fixed-x panels stopped short of the edge. Letterboxing presents the exact reference composition on every display, which is the standard the designer set; expand remains available for players who accept the plate edges. ~~(b) with (a) as `GameSettings.display_aspect = "keep"` for players who want the exact reference framing~~ — a genuine preference, so it goes behind a switch (project rule) rather than being chosen for them. Implemented at boot with `get_window().content_scale_aspect`.

```ini
[display]
window/size/viewport_width=1536
window/size/viewport_height=1024
window/size/window_width_override=1536
window/size/window_height_override=1024
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"   ; revised 2026-09-10, see §1
window/stretch/scale_mode="fractional"
```

`features` drops "Mobile" — it is a desktop game; see §6 for the renderer.

**Pixel-parity guarantee.** `tools/shot.gd` already renders the screen into a `SubViewport` of exactly 1536×1024 regardless of the OS window, so the diff is never affected by desktop size or the stretch mode above. That instrument is the contract: *a screen is correct when its fixture shot diffs against its concept within tolerance*.

## 2. Texture filtering

This is not chunky low-res pixel art scaled up; it is dense art authored at 1:1 display density (the concepts themselves have no pixel grid — `tools/art/refkit.py grid` found none). Nearest filtering is right only when texels map to whole screen pixels. Under (b) the scale is 1.0547 at 1080p and 1.4 at 1440p, and nearest sampling of dense art at non-integer scale produces irregular texel doubling — shimmer on every edge and in every gradient. Linear sampling of the same art produces a uniform softening indistinguishable from the AI-rendered source's own softness.

**Decision: `textures/canvas_textures/default_texture_filter = 1` (linear), mipmaps off.** At exactly 1536×1024 (the diff case) linear and nearest are identical, so the decision costs nothing where it is measured. Any future asset that *is* chunky pixel art (an 8× upscaled 16px icon, say) sets `texture_filter = NEAREST` on its own node.

## 3. Theme architecture

Screens are built procedurally (17 screens, 559 `Widgets./Palette.` call sites); a `.tres` Theme edited in the inspector would fight that. But per-control overrides sprinkled through screens is what made the paper UI hard to repaint.

**Decision: one `Theme` resource built in code at boot from `Palette` + `Fonts` + the generated 9-slice textures, applied to the screen host so every child inherits.**

```
game/ui/
  Palette.gd     tokens (04-palette.md)
  Fonts.gd       FontVariations: UI, UI_MEDIUM, UI_SEMIBOLD, UI_TABULAR, UI_ITALIC, DISPLAY (05-typography.md)
  Type.gd        the size constants (05 §7)
  Theme.gd       static build() -> Theme; one type variation per kit component:
                   Panel, PanelInset, Slot, SlotBronze, SlotRarity*, Chip, NavItem, NavItemActive,
                   CtaPrimary, ButtonSecondary, ButtonIcon, LinkButton, BarHp, BarMana, BarMorale,
                   CalloutDanger, CalloutCaution, Bubble, Tooltip, LabelTitle/Body/Label/Muted/Numeric/Slate/Small
  Widgets.gd     rebuilt kit: constructors that pick a type variation and set the right font/colour (06-ui-component-kit.md)
  Frame.gd       the dashboard archetype: header + nav + scene host + sidebar host + strip host, all anchored (01/03 specs)
  RosterCard.gd, CombatantPanel.gd, MissionPanel.gd, EventLog.gd, BuildingCallout.gd, SpeechBubble.gd  — composites
  SceneStage.gd  the illustrated scene (§5)
```

StyleBox choice per component follows `06-ui-component-kit.md` Table B. The rule of thumb that spec is asked to apply: **`StyleBoxFlat` wherever a flat fill + 1px border + radius reproduces the reference exactly** (insets, plain slots, dividers, bar tracks — StyleBoxFlat also does drop shadows, so panel glow can be flat too); **`StyleBoxTexture` 9-slice generated by `tools/aseprite/gen_ui.lua` wherever there is a gradient, a notch, a two-tone edge or an inner highlight** (panel with inner top highlight, CTA, active nav pill, chip, bar fills). Gradient fills specifically cannot be StyleBoxFlat.

## 4. Asset pipeline

```
art/src/**/*.aseprite         hand-authored sources (tracked)
tools/aseprite/gen_*.lua      generators -> art/src/ui/*.aseprite (regenerable, tracked for diffability)
art/export/                   slices cut from the reference sheets by tools/art/slice.py (tracked; source rects in art/ref/manifests/*.json)
game/assets/                  what the game loads (tracked PNG + JSON; .import files gitignored? NO — tracked, see below)
  ui/          9-slice textures + wordmark
  fonts/       Grenze Gotisch, Fira Sans + OFL.txt
  sprites/     raiders/, enemies/, bosses/, npcs/, vfx/, props/  — atlases + JSON from slice.py sheet
  bg/          background plates and parallax layers
  scenes/      per-scene layout data (§5)
build/atlas/                  disposable (existing build_art.sh output, kept for .aseprite exports)
```

`tools/build_art.sh` gains a third stage after export: **install** — copy `build/atlas/ui/*.png` → `game/assets/ui/` and run `slice.py cut` for every manifest. `.import` files are tracked (they are deterministic and small; untracked imports re-generate on `--import`, which verify.sh already runs when the class cache is stale — extend that trigger to "any png newer than its .import").

Import defaults (project.godot `[importer_defaults]`), so no per-file fiddling:
```ini
[importer_defaults]
texture={
"compress/mode": 0,            ; Lossless — 2D UI, no VRAM compression artefacts on 1px borders
"mipmaps/generate": false,
"process/fix_alpha_border": true,
"process/premult_alpha": false,
"detect_3d/compress_to": 0
}
```

Atlases: `slice.py sheet` packs each category into one PNG + JSON; sprites are drawn through `AtlasTexture` regions built from the JSON at load (`game/core/Atlas.gd`). One texture per category keeps 12 raiders + 20 VFX in a handful of draw calls.

## 5. Scene rendering (the illustrated viewport)

```
SceneStage (Control, clips)               the rect from the layout spec; anchors expand on wide displays
  SubViewportContainer? — NO. Plain Node2D hierarchy in a clipping Control: cheaper, no extra target.
  Plate         TextureRect  (bg plate at 1:1, centred; on wide displays the plate's own margins show — plates are exported 1820 wide where a source allows, else the extension is the letterbox colour + vignette)
  Far           Parallax2D   clouds / distant city / void glow  (scroll ratio 0.15, autoscroll for clouds)
  Mid           Node2D       buildings (interactive: Area2D + hover highlight), banners (AnimatedSprite2D)
  Lights        PointLight2D × ≤6  fireplace, torches, campfire, portal — energy noise via a tiny Ambience.gd
  Actors        Node2D       AnimatedSprite2D per raider; Ambulator.gd walks PathFollow2D along authored Path2Ds
  Fore          Node2D       foreground props, dust GPUParticles2D
  Overlay       Control      speech bubbles / emote markers (UI, so they use theme fonts) positioned from actor screen pos
```

Authored as **data, not code**: `game/assets/scenes/<scene>.json`
```json
{ "plate": "bg/guildhall_plate.png", "far": [{"tex": "bg/guildhall_far.png", "ratio": 0.15}],
  "props": [{"sprite": "props/fireplace", "pos": [345, 430], "anim": "burn", "light": {"color": "#FFB060", "energy": 1.2, "flicker": 0.25}}],
  "paths": [{"id": "bar_walk", "points": [[480,420],[640,410],[760,450]]}],
  "spawn": [{"path": "bar_walk", "count": 3}, {"pos": [700, 510], "pose": "sit"}],
  "callouts": [{"building": "tavern", "anchor": [500, 130]}] }
```
`SceneStage.load(json)` builds the tree. The Concept 1 sprite standing positions from `01-concept1-home-layout.md` §7 seed `spawn`.

## 6. Effects and the renderer

The project runs the **Mobile** renderer with `hdr_2d=true`. Mobile supports 2D lights, normal maps, GPUParticles2D and canvas shaders; 2D **glow** requires HDR 2D + `Environment.glow_enabled`.

**Verified 2026-09-09 (step 1, `tools/probe/Bloom.tscn` shot via `shot.gd`):** glow works on Mobile — an HDR `(3.0, 1.8, 0.7)` square renders with a wide soft yellow halo. An SDR `0.95` white square *also* bloomed at `glow_hdr_threshold = 1.0`, so production environments use **threshold 1.3**: UI and text (≤ 1.0) stay crisp, only deliberately emissive canvas items (fire, crystals, the portal, HDR-modulated sprites) bloom. **Decision: stay on Mobile.** No renderer switch is needed.

| Effect | Technique |
|---|---|
| Wordmark metallic gradient + outline | pre-rendered texture (05 §5) — zero runtime cost, pixel-stable |
| Panel outer glow | baked into the 9-slice (lib.lua `rrect_glow`) or `StyleBoxFlat.shadow_*`; not a shader |
| Fire / torch flicker | `PointLight2D` energy = base + noise(t) (FastNoiseLite sampled in `_process`), texture a soft radial PNG; sprite is an `AnimatedSprite2D` 6–8 frames |
| Void portal pulse / rotation | `CanvasItem` shader on the portal sprite: UV rotation `sin(TIME)` + emissive modulate above 1.0 so the glow pass catches it |
| Floating damage numbers | `Label` + `LabelSettings` outline + `Tween` (05 §5); pooled |
| Screen shake | `Tween` on `Actors/Mid/Fore` offset with decaying noise, 180ms; never the UI layer |
| Button hover/press | theme styleboxes + 60ms `modulate`/`scale` tween in Widgets |
| Atmospherics | `GPUParticles2D`: embers (fireplace, 24), dust motes (scene, 40), void motes (raid, 60) |
| Depth-of-field / tilt-shift (docs/12 §2.2 item 6) | **deferred** — a `BackBufferCopy` + blur shader on Far/Fore; prototype after the screens diff clean. Not in the references' visible signature at 1:1. |

## 7. Performance budget (raid view, worst case)

Textures: plate 1536×1024 RGBA 6.3MB + 2 parallax layers ~8MB + boss atlas 1024² 4MB + raider atlas 2048² 16MB + VFX 1024² 4MB + UI atlas 1024² 4MB ≈ **43MB VRAM**. Draw calls: UI ~120 (batched per texture/material), scene ~40, 12 combatants ~24, VFX ~20, lights ×(lit items) ~60 → **< 300**. Trivial for any GPU from the last decade; the RTX 4050 here is irrelevant.

What would break it: per-sprite textures instead of atlases (batching collapses), > 8 `PointLight2D` (each multiplies lit draws), > 500 particles with collision, or a full-screen blur shader running per frame at 4K — hence DoF deferred.

## 8. Implementation plan (each step verified headlessly)

| # | Step | Verify |
|---|---|---|
| 1 | Bloom/renderer probe: a scene with one emissive quad, `WorldEnvironment` glow; shot it | shot shows soft bloom → keep Mobile; else switch to forward_plus and re-shot |
| 2 | project.godot: 1536×1024, keep, linear filter, importer defaults; `GameSettings.display_aspect` switch | `verify.sh --fast` green; `shot.gd` still 1536×1024 |
| 3 | `Palette.gd` (new tokens + legacy aliases), `Fonts.gd`, `Type.gd`; fonts installed under game/assets/fonts | tests `test_palette_*` green; a shot of any screen renders Fira |
| 4 | `gen_ui.lua` → 9-slices; `Theme.gd`; rebuilt `Widgets.gd` (kit) | a kit gallery scene shot vs crops from the concepts (per-component refdiff `--region`) |
| 5 | `Frame.gd` + header + nav + chips; Guildhall on the Frame with an empty scene | refdiff C1 masked to the frame regions; header/nav/chips IoU > 0.8 |
| 6 | Composites: RosterCard, EventLog, MissionPanel; bottom strip + sidebar | refdiff C1 with the scene rect masked |
| 7 | `SceneStage` + Guildhall plate + fire + actors | full C1 refdiff; target MAE < 14, IoU > 0.65 ("VERY CLOSE"), then iterate |
| 8 | Town/Camp on the Frame (C3 diff), RaidView (C2 diff) | refdiff C3, C2 |
| 9 | Archetype-C screens (Roster, Market, RaiderDetail, Settings, Tavern, AdventureBoard, RaidPrep, Results, Facilities) on the kit | shots reviewed by eye + kit-region diffs; `test_screens` green |
| 10 | Remove legacy Palette aliases; full `verify.sh` | 1019+ tests green, boot clean, sweep OK |

Headless capture is already proven: `tools/shot.gd` renders into an exact-size SubViewport and needs only a display server (not `--headless`); `tools/art/refdiff.py` scores it. Add `tools/diff_all.sh` to shoot Guildhall/Town/RaidView with `--fixture` and print the three verdicts — the art pass's own gate, run beside `verify.sh`.
