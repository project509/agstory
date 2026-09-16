-- gen_ui.lua - the interface's 9-slice textures, generated from the specs.
--
-- art/ref/specs/06-ui-component-kit.md Table A decides which components need a
-- texture at all: only the ones StyleBoxFlat cannot draw - chamfered corners,
-- gradients, a rivet, a two-tone rim. Everything else (round panels, slots,
-- chips, wells, bars) is flat colour in game/ui/Theme.gd and has no asset.
--
-- Every hex here traces to a measurement in 01/03/06 or 04-palette.md. Sizes are
-- chosen so the 9-slice corners hold the whole chamfer and the stretchable
-- centre is at least 4px on each axis.
--
--   ./tools/build_art.sh --gen      (or)   Aseprite -b --script tools/aseprite/gen_ui.lua
--
-- Outputs: art/src/ui/<name>.aseprite (source of truth) and game/assets/ui/<name>.png
-- (what Godot loads). The .aseprite carries a 9-slice as an Aseprite slice so
-- the margins survive next to the pixels. `build_art.sh --check` (verify.sh
-- stage 2b) regenerates every one of these and byte-compares, so nothing in
-- this file may draw from math.random — the cork's speckle and the stamp's
-- wear use a seeded LCG.
--
-- NO TEXT IS BAKED INTO ANY OF THESE (docs/13 §14, RULES-14): a stamp's word,
-- a callout's title and a notice's rung are Labels over bare plates.
--
-- Wave 1 (W1-CHROME) added, below the original kit: the dark callout/bubble
-- plate and its tail (03 §3, CRITIC-C02), the cream emote frame (06 §8), the
-- stamp frame (docs/13 §7, CRITIC-C08), the CTA's pressed/hover plates and the
-- secondary's pressed plate (06 §3, KIT-11), the panel corner ornament and the
-- callout flourish (06 §1/§6, KIT-09), the cork tile and pin (TOWN-24).

local L = dofile("tools/aseprite/lib.lua")
local SRC, OUT = "art/src/ui/", "game/assets/ui/"

local function emit(spr, name, l, t, r, b)
  L.check_nine_slice(spr.width, spr.height, l, t, r, b)
  L.add_nine_slice(spr, name, l, t, r, b)
  L.save_ase(spr, SRC .. name .. ".aseprite")
  L.save_png(spr, OUT .. name .. ".png")
  spr:close()
end

--- A plain sprite (no 9-slice: tails, ornaments, the pin, the cork tile).
local function emit_sprite(spr, name)
  L.save_ase(spr, SRC .. name .. ".aseprite")
  L.save_png(spr, OUT .. name .. ".png")
  spr:close()
end

--- Seeded LCG (0..1). No math.random anywhere in the pipeline (LESSONS).
local function lcg(seed)
  local s = seed
  return function()
    s = (s * 1103515245 + 12345) % 2147483648
    return s / 2147483648
  end
end

--- Bayer 4x4 threshold at image coordinates, 0..1 (lib.lua keeps its own private;
--- the stamp's fibre needs it on a ring, not a rect).
local BAYER4 = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }
local function bayer(x, y) return (BAYER4[y % 4 + 1][x % 4 + 1] + 0.5) / 16 end

-- ---------------------------------------------------------------- major panel
-- 01 §1-2 + the 6x corner montage: a 45-degree chamfer of ~6px, a 1px lit rim
-- with a dark flank each side, a 5px moat, then a second 1px line 7px inside,
-- then the fill. Warm (bronze) tint for Home/Camp; a steel tint follows.
local function panel(name, rim, rim_hi, inner, fill)
  local W, H, CUT = 48, 48, 6
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  L.chrect_fill(img, 0, 0, W, H, CUT, fill)
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#1B1512"), 0)          -- outer dark flank
  L.chrect_border(img, 0, 0, W, H, CUT, rim, 1)                        -- the bronze/steel line
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#1B1512"), 2)          -- inner dark flank
  L.chrect_border(img, 0, 0, W, H, CUT, inner, 7)                      -- the second, quieter line
  -- lit lip: the top run of the rim is a shade brighter (01: top core #83542E vs left #6C5346)
  for x = CUT + 1, W - CUT - 2 do L.px(img, x, 1, rim_hi) end
  emit(spr, name, 12, 12, 12, 12)
end
panel("panel_warm",  L.hex("#7A5A42"), L.hex("#8A6448"), L.hex("#52463E"), L.hex("#060E17"))
panel("panel_steel", L.hex("#4A5869"), L.hex("#5A6A7C"), L.hex("#3F5161"), L.hex("#010D18"))

-- ---------------------------------------------------------------- primary CTA
-- 01 §2 / 06 §3: chamfer 7, outer 2px red rim with a gold top highlight and an
-- orange bottom, a 1px dark gap, a 1px inner rim at inset 4, and a vertical
-- plate gradient. 48 tall so the gradient has room to stretch.
--
-- Four plates from one painter (06 §3's state table): normal, pressed (gradient
-- inverted, the lit edge moves to the bottom, rims one step darker — the bevel
-- reads pushed in), and the hover plate that cta_glow wraps (one step brighter).
-- KIT-11: the inner rim is #B86353, not the #E7705E the first pass used — the
-- 3px salmon read hotter than Concept 1's, where the rim is red under a 1px
-- gold top edge.
local function cta_plate(img, ox, oy, s)
  local W, H, CUT = 48, 48, 7
  L.chrect_grad(img, ox, oy, W, H, CUT, s.top, s.bottom)
  L.chrect_border(img, ox, oy, W, H, CUT, L.hex("#020108"), 0)        -- hard shadow line
  L.chrect_border(img, ox, oy, W, H, CUT, s.rim_a, 1)                 -- outer rim
  L.chrect_border(img, ox, oy, W, H, CUT, s.rim_b, 2)
  L.chrect_border(img, ox, oy, W, H, CUT, L.hex("#4A262B"), 3)        -- gap
  L.chrect_border(img, ox, oy, W, H, CUT, s.inner, 4)                 -- inner rim
  for x = CUT, W - CUT - 1 do
    if s.lit_bottom then                                             -- pressed: light at the foot
      L.px(img, ox + x, oy + H - 2, L.hex("#FCB85D")); L.px(img, ox + x, oy + H - 3, L.hex("#E69451"))
      L.px(img, ox + x, oy + 1, L.hex("#B0402F")); L.px(img, ox + x, oy + 2, L.hex("#9E3A2E"))
    else                                                             -- lit gold top edge
      L.px(img, ox + x, oy + 1, L.hex("#FCB85D")); L.px(img, ox + x, oy + 2, L.hex("#E69451"))
      L.px(img, ox + x, oy + H - 2, L.hex("#F47A46")); L.px(img, ox + x, oy + H - 3, L.hex("#E2744D"))
    end
  end
end
local CTA_NORMAL = { top = L.hex("#601E28"), bottom = L.hex("#33131B"),
  rim_a = L.hex("#C9453A"), rim_b = L.hex("#D23D36"), inner = L.hex("#B86353") }
local CTA_PRESSED = { top = L.hex("#33131B"), bottom = L.hex("#601E28"),
  rim_a = L.hex("#A32A2B"), rim_b = L.hex("#B02A2B"), inner = L.hex("#8F4A40"), lit_bottom = true }
local CTA_HOVER = { top = L.hex("#7A2931"), bottom = L.hex("#43181F"),
  rim_a = L.hex("#D9483F"), rim_b = L.hex("#E94E4E"), inner = L.hex("#D0796A") }
do
  local spr = L.new_sprite(48, 48)
  cta_plate(L.img(spr), 0, 0, CTA_NORMAL)
  emit(spr, "cta_plate", 14, 14, 14, 14)
end
do
  local spr = L.new_sprite(48, 48)
  cta_plate(L.img(spr), 0, 0, CTA_PRESSED)
  emit(spr, "cta_plate_pressed", 14, 14, 14, 14)
end
-- Hover: the brighter plate inside a 6px #F27043 halo (06 §3: "6px outer glow
-- α0.30"). The halo is part of the texture and the theme's hover box draws it
-- OUTSIDE the control with expand_margin 6, so the plate lands exactly where the
-- normal plate was and no text moves. Margins 20 = 14 + the 6px halo.
do
  local W, H, G = 60, 60, 6
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local r, g, b = L.chan(L.hex("#F27043"))
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local dx = math.max(G - x, x - (W - 1 - G), 0)
      local dy = math.max(G - y, y - (H - 1 - G), 0)
      local d = math.max(dx, dy)
      if d > 0 then
        -- α0.30 at the rim falling to nothing at the 6th pixel, rounded corners
        -- by taking the diagonal a little further out than the sides
        local dd = d + 0.5 * math.min(dx, dy)
        local a = math.max(0, 0.30 * (1.0 - (dd - 1) / G))
        if a > 0.004 then L.blend(img, x, y, L.rgba(r, g, b, math.floor(a * 255 + 0.5))) end
      end
    end
  end
  cta_plate(img, G, G, CTA_HOVER)
  emit(spr, "cta_glow", 20, 20, 20, 20)
end

-- ---------------------------------------------------------------- secondary button
-- 06 §7.2: the CTA silhouette at a bronze rim over a navy plate, no inner rim.
-- Pressed (KIT-11): the gradient inverted and the lit line at the foot.
local function secondary(name, top, bottom, lit_y)
  local W, H, CUT = 48, 48, 7
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  L.chrect_grad(img, 0, 0, W, H, CUT, top, bottom)
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#0B0A0C"), 0)
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#886955"), 1)
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#5A4B44"), 2)
  for x = CUT, W - CUT - 1 do L.px(img, x, lit_y, L.hex("#A78B7A")) end
  emit(spr, name, 14, 14, 14, 14)
end
secondary("btn_secondary", L.hex("#1A2431"), L.hex("#0E161E"), 1)
secondary("btn_secondary_pressed", L.hex("#0E161E"), L.hex("#1A2431"), 46)

-- ---------------------------------------------------------------- icon button
-- 06 §7.2 (C2 cog / fast-forward): 1px steel rim, 2px bronze top, chamfer 5,
-- a rivet in the top-right cut. 46x46 is the reference size; margins 12.
do
  local W, H, CUT = 46, 46, 5
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  L.chrect_fill(img, 0, 0, W, H, CUT, L.hex("#010A17"))
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#484F5C"), 0)
  for x = CUT, W - CUT - 1 do L.px(img, x, 0, L.hex("#A78B7A")); L.px(img, x, 1, L.hex("#958177")) end
  L.rivet(img, W - 6, 6, L.hex("#8A93A3"), L.hex("#C7CFDB"))
  emit(spr, "btn_icon", 12, 12, 12, 12)
end

-- ---------------------------------------------------------------- nav tab (active)
-- 01 §6 / 06 §5.1: 54 tall, flush to the screen's left edge (no left rim),
-- horizontal gradient brightening toward the scene, 2px steel rim on the other
-- three sides, 6px chamfers on the right corners only, a rivet in the top-right.
-- The left 8px margin is inert; the right 20px margin holds the chamfer+rivet.
do
  local W, H, CUT = 48, 54, 6
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local which = { tl = false, bl = false }
  L.chrect_grad(img, 0, 0, W, H, CUT, L.hex("#0C1823"), L.hex("#20384B"), true, which)
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#4C83A2"), 0, which, { l = false })
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#3D6F8C"), 1, which, { l = false })
  L.rivet(img, W - 8, 7, L.hex("#4C83A2"), L.hex("#8FC3DE"))
  emit(spr, "nav_tab_active", 8, 8, 20, 8)
end

-- ---------------------------------------------------------------- day chip (chamfered)
-- 01 §5 chip 4: 2px bronze border #816B5B with ~6px chamfers, fill #020B12.
do
  local W, H, CUT = 48, 47, 6
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  L.chrect_fill(img, 0, 0, W, H, CUT, L.hex("#020B12"))
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#473F39"), 0)
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#816B5B"), 1)
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#4C4039"), 2)
  emit(spr, "chip_chamfer", 12, 12, 12, 12)
end

-- ---------------------------------------------------------------- speech bubble
-- 01 §7: one 33x32 cream bubble with a 1px near-black warm outline and a 6px
-- tail bottom-left. Authored as a sprite, never scaled; the glyph is drawn by
-- the game on top. Body 33x26 with 3px pixel-stepped corners.
do
  local W, H = 33, 32
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local body_h = 26
  L.rrect_fill(img, 0, 0, W, body_h, 3, L.hex("#EED0AB"))
  for x = 3, W - 4 do L.px(img, x, 1, L.hex("#F9E3BA")); L.px(img, x, body_h - 2, L.hex("#C0AB8E")) end
  L.rrect_border(img, 0, 0, W, body_h, 3, L.hex("#1A1512"), 0)
  -- tail: a 6px triangle pointing down-left from the body's bottom-left
  for i = 0, 5 do
    for j = 0, 5 - i do L.px(img, 8 + j, body_h - 1 + i, L.hex("#EED0AB")) end
    L.px(img, 8 + (5 - i) + 1, body_h - 1 + i, L.hex("#1A1512"))
    L.px(img, 7, body_h - 1 + i, L.hex("#1A1512"))
  end
  for x = 8, 13 do L.px(img, x, body_h - 1, L.hex("#EED0AB")) end
  L.px(img, 8, body_h + 5, L.hex("#1A1512"))
  L.save_ase(spr, SRC .. "speech_bubble.aseprite")
  L.save_png(spr, OUT .. "speech_bubble.png")
  spr:close()
end

-- ================================================================ wave 1 (W1-CHROME)

-- ---------------------------------------------------------------- callout / bubble plate
-- 03 §3, measured on Concept 3's signposts: fill #040E18 (flat, opaque), a
-- two-line border (#605A54 outer, #2A2E32 inner), corners chamfered 4px, no
-- radius. 16x16 with margins 6 holds the chamfer and both lines in each
-- corner; the centre is 4x4. The drop shadow 03 §3 measures (2px, offset 2,2)
-- is not in the texture: a StyleBoxTexture cannot offset, so the composite
-- lays a shadow under the plate (W1-KIT).
--
-- CRITIC-C02 / Q04: ONE chrome serves the building callouts and the speech
-- plate until the designer rules the fill, so bubble_plate.png is the same
-- pixels under the name Theme's PanelBubble loads — when Q04 lands, this is
-- the one function to fork.
local function dark_plate(name)
  local W, H, CUT = 16, 16, 4
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  L.chrect_fill(img, 0, 0, W, H, CUT, L.hex("#040E18"))
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#605A54"), 0)
  L.chrect_border(img, 0, 0, W, H, CUT, L.hex("#2A2E32"), 1)
  emit(spr, name, 6, 6, 6, 6)
end
dark_plate("callout_plate")
dark_plate("bubble_plate")

-- 03 §3 "Production decision": every plate gets the same 14 wide x 8 tall tail,
-- apex down. Rows 0-1 are fill only so a plate overlapping the tail by 2px
-- opens into it; the diagonals carry the outer line and, where there is room,
-- the inner one. The apex is a 2px pair, which is what reads at 1:1.
do
  local W, H = 14, 8
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local fill, outer, inner = L.hex("#040E18"), L.hex("#605A54"), L.hex("#2A2E32")
  for y = 0, H - 1 do
    local x0, x1 = y, W - 1 - y
    if y >= H - 2 then x0, x1 = 6, 7 end
    for x = x0, x1 do L.px(img, x, y, fill) end
    if y >= 1 then L.px(img, x0, y, outer); L.px(img, x1, y, outer) end
    if y >= 2 and x1 - x0 >= 5 then L.px(img, x0 + 1, y, inner); L.px(img, x1 - 1, y, inner) end
  end
  emit_sprite(spr, "callout_tail")
end

-- ---------------------------------------------------------------- emote frame
-- 06 §8 "Emote marker": ~40x44, 2px dark outline #2A1E18, cream fill #F4EEDD,
-- a 16px icon inside, 6px tail bottom-left. A sprite, never a StyleBox in the
-- reference's sense — Theme's PanelEmote wraps it with content margins that
-- centre a 16x16 glyph in the body (40x36 body + 8 rows of tail). The glyph is
-- drawn by the game; nothing is baked here.
do
  local W, H, BODY = 40, 44, 36
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local fill, lip, shade, ink = L.hex("#F4EEDD"), L.hex("#FBF6E8"), L.hex("#D8CFBB"), L.hex("#2A1E18")
  L.rrect_fill(img, 0, 0, W, BODY, 4, fill)
  for x = 4, W - 5 do L.px(img, x, 2, lip); L.px(img, x, BODY - 3, shade) end
  L.rrect_border(img, 0, 0, W, BODY, 4, ink, 0)
  L.rrect_border(img, 0, 0, W, BODY, 4, ink, 1)
  -- open the body's outline where the tail joins (x 10..13, the two outline rows)
  for y = BODY - 2, BODY - 1 do for x = 10, 13 do L.px(img, x, y, fill) end end
  -- the tail: down and to the left, 2px ink on each flank, a 2px ink apex
  local spans = { {8, 15}, {8, 14}, {7, 13}, {7, 12}, {6, 11}, {6, 10}, {5, 8}, {5, 6} }
  for i, s in ipairs(spans) do
    local y = BODY + i - 1
    local x0, x1 = s[1], s[2]
    for x = x0, x1 do
      local c = (x <= x0 + 1 or x >= x1 - 1) and ink or fill
      L.px(img, x, y, c)
    end
  end
  emit_sprite(spr, "emote_frame")
end

-- ---------------------------------------------------------------- stamp frame
-- docs/13 §7 StampBadge: "rotated 2-7°, ~70% opacity with worn edges. Carries a
-- word, always duplicated as readable text nearby" (the word is a Label,
-- docs/13 §14). A rubber-stamp border: a 2px outer rule, a 1px gap, a 1px
-- inner rule, rounded 3px; three worn gaps where the ink did not take, all
-- in the CORNER regions so they never stretch; a dithered fibre fringe either
-- side of the rules (gen_wipe's bleed idea at 1px). White-on-alpha at α180
-- (~70%): Theme's PanelStamp tints it DANGER through modulate_color, and a
-- CAUTION stamp is the same texture under another tint. 24x24, margins 8,
-- edges tiled (not stretched) by the theme so the fibre keeps its grain.
do
  local W, H, R = 24, 24, 3
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local ink = L.rgba(255, 255, 255, 180)
  L.rrect_border(img, 0, 0, W, H, R, ink, 0)
  L.rrect_border(img, 0, 0, W, H, R, ink, 1)
  L.rrect_border(img, 0, 0, W, H, R, ink, 3)
  -- fibre: the gap ring between the rules (inset 2) and the ring just inside
  -- the inner rule (inset 4), 3-in-8 Bayer at α110 — ink wicking into the paper
  local soft = L.rgba(255, 255, 255, 110)
  local function ins(x, y, k)
    return x >= k and y >= k and x < W - k and y < H - k
       and L.rr_inside(x - k, y - k, W - 2 * k, H - 2 * k, math.max(R - k, 0))
  end
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local gap = ins(x, y, 2) and not ins(x, y, 3)
      local inner = ins(x, y, 4) and not ins(x, y, 5)
      if (gap or inner) and bayer(x, y) < 0.375 and app.pixelColor.rgbaA(img:getPixel(x, y)) == 0 then
        L.px(img, x, y, soft)
      end
    end
  end
  -- the wear: three gaps, corners only (fixed regions of the 9-slice)
  local clear = L.rgba(0, 0, 0, 0)
  local gaps = { {4, 0}, {5, 0}, {4, 1}, {5, 1}, {4, 3},          -- top-left, on the top rule
                 {23, 6}, {22, 6}, {23, 7}, {20, 6},              -- top-right, on the right rule
                 {0, 17}, {1, 17}, {0, 18}, {1, 18}, {3, 17}, {3, 18},  -- bottom-left, on the left rule
                 {16, 23}, {17, 23}, {16, 22} }                   -- bottom-right, on the bottom rule
  for _, g in ipairs(gaps) do L.px(img, g[1], g[2], clear) end
  emit(spr, "stamp_frame", 8, 8, 8, 8)
end

-- ---------------------------------------------------------------- panel corner ornament
-- 06 §1 / KIT-09: the sidebar's four 16x16 corner ornaments (Concept 1
-- 1143,74). White-on-alpha; Widgets.panel overlays four TextureRects tinted
-- by the panel's edge colour, never baked into the 9-slice. A bracket along
-- two edges, a rivet at the corner, a curl at each end — the top-left
-- orientation; the other three are flips at the call site.
do
  local W, H = 16, 16
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local ink, soft = L.rgba(255, 255, 255, 255), L.rgba(255, 255, 255, 150)
  L.fill(img, 2, 1, 10, 1, ink)     -- top rule
  L.fill(img, 1, 2, 1, 10, ink)     -- left rule
  L.fill(img, 3, 2, 8, 1, soft)     -- their inner shadow lines
  L.fill(img, 2, 3, 1, 8, soft)
  -- curls: the rule ends turn in
  L.px(img, 12, 2, ink); L.px(img, 12, 3, ink); L.px(img, 11, 4, ink); L.px(img, 10, 4, soft)
  L.px(img, 2, 12, ink); L.px(img, 3, 12, ink); L.px(img, 4, 11, ink); L.px(img, 4, 10, soft)
  -- the corner rivet (a 3x3 diamond)
  L.px(img, 2, 1, ink); L.px(img, 1, 2, ink)
  L.px(img, 4, 4, ink); L.px(img, 3, 4, soft); L.px(img, 4, 3, soft); L.px(img, 5, 4, soft); L.px(img, 4, 5, soft)
  emit_sprite(spr, "panel_corner_ornament")
end

-- ---------------------------------------------------------------- callout flourish
-- 06 §6: the success-chance callout's top-right leaf/scroll ornament, ~18x14,
-- "tinted with the severity colour; authored once". White-on-alpha; Theme
-- registers it as the `flourish` icon on the three PanelCallout* variations
-- and the composite tints it by band.
do
  local W, H = 18, 14
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local ink, soft = L.rgba(255, 255, 255, 255), L.rgba(255, 255, 255, 140)
  -- the stem: a quarter arc from the bottom-left sweeping up to the top-right
  L.arc(img, 17, 13, 13, 180, 268, ink, 1)
  -- two leaves off the stem
  L.poly_fill(img, { {6, 9}, {9, 5}, {11, 7}, {8, 11} }, soft)
  L.px(img, 8, 8, ink); L.px(img, 9, 7, ink)
  L.poly_fill(img, { {11, 4}, {14, 1}, {15, 3}, {13, 6} }, soft)
  L.px(img, 13, 3, ink); L.px(img, 12, 4, ink)
  -- the curl at the tip
  L.arc(img, 15, 4, 2, 200, 400, ink, 1)
  emit_sprite(spr, "callout_flourish")
end

-- ---------------------------------------------------------------- cork tile
-- TOWN-24: the Adventure's Board is a board. A 32x32 tile in the bronze
-- family's browns (04 §edges: EDGE_BRONZE #856A57 / EDGE_BRONZE_SHADOW
-- #5F4D3E are the lights; the ground is darker so cream paper reads on it),
-- speckled by a seeded LCG with every speckle wrapped modulo 32 so the tile
-- is periodic. Theme's PanelCork tiles it (axis stretch TILE).
do
  local W, H = 32, 32
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  L.fill(img, 0, 0, W, H, L.hex("#2E2218"))
  local rnd = lcg(90210)
  local tones = { L.hex("#3B2B1F"), L.hex("#4A3627"), L.hex("#241A12"), L.hex("#5F4D3E"), L.hex("#3B2B1F"), L.hex("#1F160F") }
  for _ = 1, 110 do
    local x, y = math.floor(rnd() * W), math.floor(rnd() * H)
    local c = tones[math.floor(rnd() * #tones) + 1]
    local w = rnd() < 0.35 and 2 or 1
    for dy = 0, (rnd() < 0.3 and 1 or 0) do
      for dx = 0, w - 1 do L.px(img, (x + dx) % W, (y + dy) % H, c) end
    end
  end
  emit_sprite(spr, "cork_tile")
end

-- ---------------------------------------------------------------- pin
-- TOWN-24: a 12x12 round-headed pin for the notices. Red head (the CTA's
-- family, not DANGER — it is furniture, not a warning), a lit spot up-left, a
-- steel needle down-right, a 1px offset shadow so it sits ON the paper.
do
  local W, H = 12, 12
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local shadow = L.rgba(11, 10, 12, 130)
  L.ellipse_fill(img, 6.0, 5.5, 3.6, 3.6, shadow)                     -- shadow, offset (1,1)
  L.line(img, 8, 8, 11, 11, shadow, 1)
  L.line(img, 7, 7, 10, 10, L.hex("#8A93A3"), 1)                       -- the needle
  L.px(img, 10, 10, L.hex("#C7CFDB"))
  L.ellipse_fill(img, 5.0, 4.5, 3.6, 3.6, L.hex("#3A1210"))             -- head outline
  L.ellipse_fill(img, 5.0, 4.5, 2.6, 2.6, L.hex("#C9453A"))             -- head
  L.px(img, 4, 3, L.hex("#F0857A")); L.px(img, 3, 4, L.hex("#E27063"))  -- the lit spot
  L.px(img, 6, 6, L.hex("#8F2A26"))
  emit_sprite(spr, "pin")
end

-- ================================================================ wave 4 (W4-CURSOR)

-- ---------------------------------------------------------------- cursors
-- PIPE-15: the pointer over a 2D-HD scene is the kit's, not the OS's. Two
-- 32x32 sprites in the emote frame's family (06 §8): cream #F4EEDD, a 1px
-- warm-dark outline #2A1E18, a lit lip and a shade line inside, and a soft
-- 2px-offset shadow so the pointer sits ON the screen. Both are drawn from
-- a mask (the silhouette) the way the icons are: the outline is the mask
-- grown by one pixel, so the two read as one family whatever the shape.
--
-- project.godot's `display/mouse_cursor/custom_image` is the arrow with its
-- hotspot on the tip (1,1); the hand is Input.CURSOR_POINTING_HAND (every
-- BaseButton's default shape) with its hotspot on the fingertip (12,1) —
-- registered at runtime through Input.set_custom_mouse_cursor, since the
-- project setting carries one image only. A cursor is an OS image at native
-- pixels, never stretched with the canvas, so 32x32 is the size it shows at.
local CURSOR_FILL, CURSOR_LIP, CURSOR_SHADE, CURSOR_INK =
  L.hex("#F4EEDD"), L.hex("#FBF6E8"), L.hex("#D8CFBB"), L.hex("#2A1E18")
local CURSOR_SHADOW = L.rgba(11, 10, 12, 110)

--- The mask grown by one pixel on all eight sides: the outline ring is
--- grow(m) minus m, which is what keeps the ring OUTSIDE the cream.
local function grow(m)
  local g = L.mask_new(m.w, m.h)
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) then
        for dy = -1, 1 do for dx = -1, 1 do L.mset(g, x + dx, y + dy, true) end end
      end
    end
  end
  return g
end

--- Shadow, outline, fill, then the lip (fill pixels whose up-left neighbour
--- is outline) and the shade (fill pixels whose down-right neighbour is).
local function cursor_paint(img, m)
  local ring = grow(m)
  L.mask_paint(img, ring, CURSOR_SHADOW, 2, 2)
  L.mask_paint(img, ring, CURSOR_INK)
  L.mask_paint(img, m, CURSOR_FILL)
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) then
        if not L.mget(m, x - 1, y) or not L.mget(m, x, y - 1) then L.px(img, x, y, CURSOR_LIP)
        elseif not L.mget(m, x + 1, y) or not L.mget(m, x, y + 1) then L.px(img, x, y, CURSOR_SHADE) end
      end
    end
  end
end

-- The arrow: a 45-degree head 16 wide, a 3px tail, the notch at 45 degrees.
-- Fill vertices in pixel units (mask_poly samples pixel centres); the ink
-- ring lands one pixel outside, so the visible tip is (1,1) — the hotspot.
do
  local W, H = 32, 32
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local m = L.mask_new(W, H)
  L.mask_poly(m, { {2, 1}, {17, 16}, {10.5, 16}, {14.5, 25}, {10.5, 27}, {6.5, 18}, {2, 22.5} }, true)
  cursor_paint(img, m)
  emit_sprite(spr, "cursor_arrow")
end

-- The pointing hand: the index finger up (the hotspot is its tip, (12,1)),
-- three folded fingers stepping down to the right, the thumb on the left,
-- the palm and a cuff. Finger joins are 1px shade lines inside the cream.
do
  local W, H = 32, 32
  local spr = L.new_sprite(W, H)
  local img = L.img(spr)
  local m = L.mask_new(W, H)
  L.mask_rect(m, 10, 5, 5, 13, true)                 -- index finger
  L.mask_ellipse(m, 12.5, 5.0, 2.5, 2.6, true)       -- its rounded tip (top fill row y=3)
  L.mask_rect(m, 15, 12, 4, 7, true)                 -- middle
  L.mask_ellipse(m, 17.0, 12.0, 2.0, 2.0, true)
  L.mask_rect(m, 19, 14, 4, 6, true)                 -- ring
  L.mask_ellipse(m, 21.0, 14.0, 2.0, 2.0, true)
  L.mask_rect(m, 23, 16, 3, 5, true)                 -- pinky
  L.mask_ellipse(m, 24.5, 16.0, 1.5, 1.5, true)
  L.mask_rect(m, 8, 18, 18, 8, true)                 -- palm
  L.mask_ellipse(m, 7.0, 19.5, 3.0, 4.5, true)       -- thumb
  L.mask_rect(m, 9, 26, 16, 3, true)                 -- cuff
  cursor_paint(img, m)
  -- the joins: between the fingers, the thumb's crease, the cuff's line
  for y = 13, 18 do L.px(img, 15, y, CURSOR_SHADE) end
  for y = 15, 19 do L.px(img, 19, y, CURSOR_SHADE) end
  for y = 17, 20 do L.px(img, 23, y, CURSOR_SHADE) end
  for x = 10, 24 do L.px(img, x, 25, CURSOR_SHADE) end
  L.px(img, 9, 21, CURSOR_SHADE); L.px(img, 9, 22, CURSOR_SHADE); L.px(img, 10, 23, CURSOR_SHADE)
  emit_sprite(spr, "cursor_hand")
end

print("GEN_UI OK")
