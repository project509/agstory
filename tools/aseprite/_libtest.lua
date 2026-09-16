-- Exercises every primitive in lib.lua once and exports a contact sheet so a
-- human (or a Read of the PNG) can confirm the shapes look like the kit's.
-- Not part of the build; run by hand from the project root:
--   Aseprite -b --script tools/aseprite/_libtest.lua
-- Writes build/_libtest.png (the sheet), build/_libtest_strip.png and
-- build/_libtest_strip.aseprite (the strip primitive's two outputs; check the
-- tag with `./tools/build_art.sh --tags build/_libtest_strip.aseprite`).
-- Nothing under game/ or art/ is touched.
local L = dofile("tools/aseprite/lib.lua")

local W, H = 400, 250
local spr = L.new_sprite(W, H)
local img = L.img(spr)

-- ground so glows have something to sit on
L.fill(img, 0, 0, W, H, L.hex("#0B1118"))

-- ================================================================ row 1: the kit shapes (original set)
-- panel with glow, gradient, inner highlight, border
L.panel(img, 8, 8, 96, 60, {
  radius = 5, fill = L.hex("#1A2430"), fill_bottom = L.hex("#0F161E"),
  border = L.hex("#3A4A5A"), inner = L.hex("#26333F80"),
  glow = L.hex("#000000"), glow_spread = 4, glow_alpha = 120,
})

-- inset well inside it
L.inset(img, 16, 16, 80, 24, { radius = 3, fill = L.hex("#080D12"), border = L.hex("#000000"), lip = L.hex("#2A3744") })

-- slot
L.panel(img, 16, 44, 20, 20, { radius = 3, fill = L.hex("#141C25"), border = L.hex("#4A5A6A") })
L.panel(img, 40, 44, 20, 20, { radius = 3, fill = L.hex("#141C25"), border = L.hex("#B98A24") })

-- CTA plate with notches and double border
L.panel(img, 120, 8, 120, 40, { radius = 2, fill = L.hex("#8E2B2B"), fill_bottom = L.hex("#5A1A1A"), border = L.hex("#E5BE4E") })
L.rrect_border(img, 122, 10, 116, 36, 1, L.hex("#3A0F0F"), 0)
L.notch(img, 120, 8, 120, 40, 4, L.hex("#0B1118"), L.hex("#E5BE4E"))

-- bar
L.inset(img, 120, 60, 120, 10, { radius = 2, fill = L.hex("#080D12"), border = L.hex("#000000") })
L.grad(img, 122, 62, 70, 6, L.hex("#7FE06A"), L.hex("#2E8B3A"))

-- nav active pill with accent bar
L.panel(img, 8, 80, 232, 30, { radius = 3, fill = L.hex("#1C3A4E"), fill_bottom = L.hex("#0F2230"), border = L.hex("#3E7A9A") })
L.fill(img, 8, 80, 3, 30, L.hex("#7FD8FF"))

-- horizontal gradient + chamfered rect on top of it
L.grad(img, 250, 8, 60, 100, L.hex("#E5BE4E"), L.hex("#4A2E12"), false)
L.chrect_fill(img, 256, 60, 48, 40, 6, L.hex("#0C1823"))
L.chrect_border(img, 256, 60, 48, 40, 6, L.hex("#4C83A2"), 0)
L.rivet(img, 296, 68, L.hex("#4C83A2"), L.hex("#8FC3DE"))

-- ================================================================ row 2: the W0-LIB primitives
local Y = 120

-- 1. masks + render_mask: a tagged mask (iron dome on a leather band) shaded
--    with gen_items' ramps, then its outline alone, then a glow
local RAMP = {
  iron    = { base = "#7C838E", dark = "#4A505B", deep = "#2C3038", rim = "#B9BFC7" },
  leather = { base = "#8A5A33", dark = "#5A3A1E", deep = "#36210F", rim = "#C08A55" },
}
local m = L.mask_new(40, 40)
L.mask_ellipse(m, 20, 18, 14, 12, "iron")
L.mask_rect(m, 4, 22, 32, 8, "leather")
L.mask_poly(m, { { 20, 2 }, { 26, 8 }, { 14, 8 } }, "iron")   -- a crest
L.mask_ellipse(m, 20, 16, 4, 3, false)                           -- erase: an eye hole
L.mask_spans(m, { { 33, 6, 33 }, { 34, 8, 31 } }, "leather")    -- two span rows
L.render_mask(img, m, RAMP, {
  ox = 8, oy = Y, outline = L.hex("#0E1218"), halo = L.hex("#0E121880"),
  shadow = L.hex("#05070AB0"), grain = function(tag) return tag == "iron" and 0.10 or 0.18 end,
})
L.mask_outline(img, m, L.hex("#F0E3D2"), 52, Y)
L.mask_paint(img, m, L.hex("#3F5161"), 96, Y)
L.glow_mask(img, 96, Y, m, L.hex("#ECA742"), 90)
local bx0, by0, bx1, by1 = L.mask_bbox(m)
assert(bx0 == 4 and bx1 == 35 and by0 >= 2 and by1 == 34, "mask_bbox: " .. bx0 .. "," .. by0 .. "," .. bx1 .. "," .. by1)
assert(L.depth_map(m)[20 * 40 + 20] == 99 or L.depth_map(m)[20 * 40 + 20] >= 1, "depth_map")

-- 2. strokes: lines at 1/2/3 px, a crescent arc (the slash shape), a ring
L.line(img, 150, Y + 2, 190, Y + 38, L.hex("#F0E3D2"), 1)
L.line(img, 158, Y + 2, 198, Y + 38, L.hex("#7FD8FF"), 2)
L.line(img, 166, Y + 2, 206, Y + 38, L.hex("#F73526"), 3)
L.line(img, 150, Y + 40, 206, Y + 40, L.hex("#B98A24"), 1)     -- horizontal
L.arc(img, 230, Y + 20, 16, 200, 40, L.hex("#43DBF3"), 3)        -- 200-degree crescent
L.arc(img, 230, Y + 20, 12, 220, 20, L.hex("#DCE8F2"), 1)
L.circle(img, 268, Y + 20, 14, L.hex("#FBB62B"), 2)
L.circle(img, 268, Y + 20, 6, L.hex("#F6EFDF"), 1)

-- 3. fills: ellipse, polygon (a concave star), dither fill and dither gradient
L.ellipse_fill(img, 310, Y + 12, 18, 10, L.hex("#5FA65A"))
L.poly_fill(img, {
  { 350, Y + 2 }, { 355, Y + 14 }, { 368, Y + 14 }, { 358, Y + 22 },
  { 362, Y + 36 }, { 350, Y + 28 }, { 338, Y + 36 }, { 342, Y + 22 },
  { 332, Y + 14 }, { 345, Y + 14 },
}, L.hex("#B1A0F6"))
L.dither_fill(img, 292, Y + 26, 36, 14, L.hex("#1C3A4E"), L.hex("#7FD8FF"), 0.25)
L.dither_fill(img, 292, Y + 42, 36, 8, L.hex("#1C3A4E"), L.hex("#7FD8FF"), 0.5, "checker")
L.dither_grad(img, 372, Y + 2, 20, 48, L.hex("#601E28"), L.hex("#FCB85D"))

-- 4. import + blit: a shipped icon composited onto the sheet
local face = L.import_png("game/assets/ui/icons/face_6.png")
assert(face.width == 24 and face.height == 24, "import_png size")
L.blit(img, face, 8, Y + 50)
L.blit(img, face, 36, Y + 50)

-- 5. strip: four real frames of a growing dot + a tag, saved under build/ only,
--    and the returned composed row blitted onto the sheet
local row = L.strip("_libtest_strip", 16, 16, 4, 8, function(f, i)
  L.ellipse_fill(f, 8, 8, 2 + i * 1.5, 2 + i * 1.5, L.hex("#F58A3C"))
  L.px(f, 8, 8, L.hex("#FFF4C0"))
end, { tag = "grow", src_dir = "build/", out_dir = "build/" })
assert(row.width == 64 and row.height == 16, "strip row size")
L.blit(img, row, 70, Y + 50)

-- 9-slice bookkeeping (unchanged)
L.add_nine_slice(spr, "panel", 8, 8, 8, 8)
L.check_nine_slice(96, 60, 8, 8, 8, 8)

L.save_png(spr, "build/_libtest.png")
print("LIBTEST OK")
