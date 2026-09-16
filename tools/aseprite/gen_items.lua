-- gen_items.lua - item icons for the gear slots the sliced sheets never drew.
--
-- The reference's own item icons (game/assets/ui/icons/item_gear_*, item_reward_*)
-- cover a sword, a cuirass, a bag, a tunic, a gem and a round shield-ish coin:
-- four of canon's seven slots. Head, legs, feet and the off-hand fell back to
-- their outline slot glyph, which is honest but flat beside painted icons.
--
-- Each icon here is a SHAPE drawn as a mask, then shaded the way the reference
-- icons are: a 1px dark warm outline with a soft halo, edge pixels one step
-- darker, a top-left rim light, a specular or two, and a gentle top-to-bottom
-- gradient. Three materials per slot — iron, leather, cloth — because canon's
-- item families split that way (WARBARD plate, MONK/ROGUE leather, HEALER and
-- MAGE/WIZ cloth). 39x39 like the sliced icons; the slot widget fits them.
--
-- Writes game/assets/ui/icons/item_<slot>_<material>.png and the .aseprite
-- sources under art/src/items/.

local L = dofile("tools/aseprite/lib.lua")
local SRC, OUT = "art/src/items/", "game/assets/ui/icons/"
local S = 39

-- ---------------------------------------------------------------- palette
-- Ramps sampled to sit beside the reference icons: base, dark edge, deep
-- shadow, rim light, specular. Outline is the reference's warm near-black.
local MAT = {
  iron    = { base = "#7C838E", dark = "#4A505B", deep = "#2C3038", rim = "#B9BFC7", spec = "#EEF1F4" },
  leather = { base = "#8A5A33", dark = "#5A3A1E", deep = "#36210F", rim = "#C08A55", spec = "#E9C08E" },
  cloth   = { base = "#4A5F8E", dark = "#2F3F62", deep = "#1D2740", rim = "#7D93C6", spec = "#C9D6F2" },
  wood    = { base = "#6E4526", dark = "#482C16", deep = "#2C1A0C", rim = "#A8744A", spec = "#D9A876" },
  gold    = { base = "#C9963C", dark = "#8A6222", deep = "#5A3F12", rim = "#F0CB6E", spec = "#FFF1B8" },
  gem_fire = { base = "#E0602A", dark = "#9A3A16", deep = "#5E1F0A", rim = "#FFA45C", spec = "#FFE9C4" },
  gem_arc  = { base = "#4C7FE0", dark = "#2C4E9A", deep = "#1A2E5E", rim = "#8FB5FF", spec = "#E4EEFF" },
  gem_life = { base = "#5FA65A", dark = "#3A6E38", deep = "#22421F", rim = "#9EDB92", spec = "#E8FFE0" },
  gem_red  = { base = "#D0383A", dark = "#8E1F22", deep = "#561013", rim = "#FF7A78", spec = "#FFE1DF" },
  gem_grey = { base = "#8E97A4", dark = "#5C6470", deep = "#363B44", rim = "#C8CFD8", spec = "#F2F5F8" },
}
local OUTLINE, HALO = L.hex("#0E1218"), L.hex("#0E121880")
local ACCENT = { brass = "#C9963C", brass_d = "#7C5A1E", strap = "#3A2414", stud = "#D8DCE2", gem = "#B24BD8" }

-- ---------------------------------------------------------------- masks
-- Shapes are lib.lua masks (L.mask_*) tagged with a material name; the
-- helpers below only add this file's coordinate scaling.
local function new_mask() return L.mask_new(S, S) end
-- The shapes below were sketched to fill ~28px; the reference icons fill ~34
-- of 39. Every shape helper scales its inputs about the centre by K.
local K, C = 1.18, 19.5
local function tx(v) return C + (v - C) * K end
local function tl(v) return v * K end

--- Filled ellipse centred (cx, cy), radii rx, ry. `v` is the material tag
--- (or false to erase).
local function ellipse(m, cx, cy, rx, ry, v)
  L.mask_ellipse(m, tx(cx), tx(cy), tl(rx), tl(ry), v)
end
local function rect(m, x, y, w, h, v)
  local x0, y0 = math.floor(tx(x) + 0.5), math.floor(tx(y) + 0.5)
  local x1, y1 = math.floor(tx(x + w) + 0.5) - 1, math.floor(tx(y + h) + 0.5) - 1
  L.mask_rect(m, x0, y0, x1 - x0 + 1, y1 - y0 + 1, v)
end
--- Convex/concave polygon by scanline (even-odd). pts = {{x,y},...} in pixel centres.
local function poly(m, pts_in, v)
  local pts = {}
  for i, p in ipairs(pts_in) do pts[i] = { tx(p[1]), tx(p[2]) } end
  L.mask_poly(m, pts, v)
end

-- ---------------------------------------------------------------- shading
--- Paint mask `m` into a new 39x39 sprite with lib.lua's item treatment
--- (outline + halo outside, ramped fill inside, rim light up-left, shadow
--- down-right). `detail(img)` runs after the body so straps and studs sit on top.
local function render(m, detail)
  local spr = L.new_sprite(S, S)
  local img = L.img(spr)
  L.render_mask(img, m, MAT, {
    outline = OUTLINE, halo = HALO, shadow = L.hex("#05070AB0"),
    -- grain: leather and cloth are rougher than iron
    grain = function(tag) return tag == "iron" and 0.10 or 0.18 end,
  })
  if detail then detail(img, m) end
  return spr, img
end

local function spec(img, x, y, c)
  L.px(img, math.floor(tx(x) + 0.5), math.floor(tx(y) + 0.5), L.hex(c))
end
local function run(img, x, y, w, h, c)
  local x0, y0 = math.floor(tx(x) + 0.5), math.floor(tx(y) + 0.5)
  local x1, y1 = math.floor(tx(x + w) + 0.5) - 1, math.floor(tx(y + h) + 0.5) - 1
  L.fill(img, x0, y0, math.max(1, x1 - x0 + 1), math.max(1, y1 - y0 + 1), L.hex(c))
end

-- ---------------------------------------------------------------- shapes
local shapes = {}

-- HEAD ---------------------------------------------------------------------
shapes.head = {
  -- a closed helm: dome, brim band, nose guard, eye slit
  iron = function()
    local m = new_mask()
    ellipse(m, 19.5, 17, 12, 11, "iron")
    rect(m, 8, 17, 23, 9, "iron")
    rect(m, 6, 24, 27, 4, "iron")                      -- brim
    rect(m, 12, 27, 15, 5, "iron")                     -- cheek guards
    rect(m, 17, 27, 5, 2, false)
    return m, function(img)
      run(img, 10, 21, 19, 2, "#2C3038")               -- eye slit
      run(img, 18, 14, 3, 12, "#B9BFC7")               -- nose guard
      run(img, 19, 14, 1, 12, "#EEF1F4")
      run(img, 6, 24, 27, 1, ACCENT.brass)             -- brass brim line
      spec(img, 12, 10, "#EEF1F4"); spec(img, 13, 9, "#EEF1F4")
    end
  end,
  -- a hood: cowl with a shadowed face opening
  leather = function()
    local m = new_mask()
    poly(m, { { 19.5, 4 }, { 33, 22 }, { 31, 34 }, { 8, 34 }, { 6, 22 } }, "leather")
    ellipse(m, 19.5, 24, 7, 8, false)                  -- face opening
    return m, function(img)
      for y = 16, 31 do for x = 13, 26 do
        local dx, dy = (x + 0.5 - 19.5) / 7, (y + 0.5 - 24) / 8
        if dx * dx + dy * dy <= 1 then L.px(img, x, y, L.hex("#14100C")) end
      end end
      run(img, 9, 33, 21, 1, "#5A3A1E")
      run(img, 17, 6, 2, 4, "#C08A55")                 -- fold highlight
      spec(img, 16, 5, "#E9C08E")
    end
  end,
  -- an eyepatch: a big dark patch, a thin strap either side, a buckle
  -- (ROGUE_HEAD family). The patch interior is painted in the same scaled
  -- space the mask uses, so the two agree pixel for pixel.
  eyepatch = function()
    local m = new_mask()
    poly(m, { { 3, 16 }, { 36, 11 }, { 36, 14 }, { 3, 19 } }, "leather")      -- strap
    ellipse(m, 20, 20, 9.5, 9, "leather")                                      -- patch rim
    return m, function(img)
      local cx, cy, rx, ry = tx(20), tx(20), tl(7.6), tl(7.1)
      for y = 0, S - 1 do for x = 0, S - 1 do
        local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
        local r2 = dx * dx + dy * dy
        if r2 <= 1 then
          local c = "#14100C"
          if dx + dy < -0.9 then c = "#2E1E10" end                            -- a little sheen up-left
          if r2 > 0.78 then c = "#22160C" end                                  -- rolled edge
          L.px(img, x, y, L.hex(c))
        end
      end end
      run(img, 3, 17, 33, 1, "#36210F")                                        -- strap seam
      run(img, 7, 14, 3, 5, ACCENT.brass); run(img, 8, 15, 1, 3, ACCENT.brass_d)   -- buckle
      spec(img, 15, 15, "#C08A55")
    end
  end,
  -- a headband: a cloth ring seen from slightly above, knot and tails to the
  -- right (MONK_HEAD family)
  headband = function()
    local m = new_mask()
    ellipse(m, 18, 20, 13.5, 9.5, "leather")
    ellipse(m, 18, 19, 10, 6, false)                                           -- the opening
    ellipse(m, 31, 19, 3.5, 3.5, "leather")                                    -- knot
    poly(m, { { 32, 20 }, { 37, 27 }, { 35, 29 }, { 30, 22 } }, "leather")     -- tail
    poly(m, { { 33, 18 }, { 38, 23 }, { 37, 25 }, { 31, 20 } }, "leather")     -- tail
    return m, function(img)
      -- the opening is the wearer's head: keep it dark, not transparent
      local cx, cy, rx, ry = tx(18), tx(19), tl(10), tl(6)
      for y = 0, S - 1 do for x = 0, S - 1 do
        local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
        if dx * dx + dy * dy <= 1 then L.px(img, x, y, L.hex("#0E1218")) end
      end end
      run(img, 7, 26, 22, 1, "#C08A55")                                        -- the band's front fold
      run(img, 7, 28, 22, 1, "#36210F")
      spec(img, 30, 17, "#E9C08E")
    end
  end,
  -- a pointed hat with a brim and a band
  cloth = function()
    local m = new_mask()
    poly(m, { { 21, 3 }, { 30, 26 }, { 11, 26 } }, "cloth")
    ellipse(m, 19.5, 28, 16, 5, "cloth")               -- brim
    return m, function(img)
      run(img, 12, 23, 16, 3, ACCENT.brass_d)          -- band
      run(img, 12, 23, 16, 1, ACCENT.brass)
      spec(img, 20, 24, ACCENT.gem)                    -- buckle gem
      run(img, 18, 8, 1, 10, "#7D93C6")                -- fold
      spec(img, 21, 4, "#C9D6F2")
    end
  end,
}

-- LEGS ---------------------------------------------------------------------
shapes.legs = {
  -- greaves: two plate shins with knee cops
  iron = function()
    local m = new_mask()
    poly(m, { { 9, 6 }, { 18, 6 }, { 17, 33 }, { 9, 33 } }, "iron")
    poly(m, { { 21, 6 }, { 30, 6 }, { 30, 33 }, { 22, 33 } }, "iron")
    ellipse(m, 13.5, 9, 5.5, 4, "iron")
    ellipse(m, 25.5, 9, 5.5, 4, "iron")
    return m, function(img)
      run(img, 9, 13, 9, 1, ACCENT.brass); run(img, 22, 13, 8, 1, ACCENT.brass)
      run(img, 12, 15, 1, 16, "#B9BFC7"); run(img, 25, 15, 1, 16, "#B9BFC7")
      run(img, 9, 32, 9, 1, "#2C3038"); run(img, 22, 32, 8, 1, "#2C3038")
      spec(img, 12, 8, "#EEF1F4"); spec(img, 24, 8, "#EEF1F4")
    end
  end,
  -- trousers: waistband, two legs, a belt
  leather = function()
    local m = new_mask()
    rect(m, 9, 6, 21, 6, "leather")
    poly(m, { { 9, 11 }, { 19, 11 }, { 18, 34 }, { 9, 34 } }, "leather")
    poly(m, { { 20, 11 }, { 30, 11 }, { 30, 34 }, { 21, 34 } }, "leather")
    rect(m, 18, 22, 3, 12, false)
    return m, function(img)
      run(img, 9, 6, 21, 3, ACCENT.strap)              -- belt
      run(img, 17, 6, 4, 3, ACCENT.brass)              -- buckle
      spec(img, 18, 7, "#E9C08E")
      run(img, 12, 14, 1, 17, "#C08A55"); run(img, 26, 14, 1, 17, "#C08A55")
      run(img, 10, 32, 8, 1, "#36210F"); run(img, 21, 32, 8, 1, "#36210F")
    end
  end,
  -- a robe skirt: waist sash, flared hem
  cloth = function()
    local m = new_mask()
    poly(m, { { 12, 6 }, { 27, 6 }, { 33, 34 }, { 6, 34 } }, "cloth")
    return m, function(img)
      run(img, 11, 6, 17, 4, ACCENT.brass_d)           -- sash
      run(img, 11, 6, 17, 1, ACCENT.brass)
      run(img, 15, 12, 1, 20, "#2F3F62"); run(img, 23, 12, 1, 20, "#2F3F62")
      run(img, 19, 12, 1, 20, "#7D93C6")
      run(img, 7, 32, 25, 1, "#7D93C6")                -- hem trim
      spec(img, 13, 8, "#C9D6F2")
    end
  end,
}

-- FEET ---------------------------------------------------------------------
local function boot(m, x, y, tall, tag)
  -- shaft
  rect(m, x, y, 8, tall, tag)
  -- foot pointing right
  rect(m, x, y + tall - 2, 14, 6, tag)
  ellipse(m, x + 13, y + tall + 1, 3, 3, tag)
end
shapes.feet = {
  iron = function()
    local m = new_mask()
    boot(m, 5, 8, 18, "iron"); boot(m, 19, 12, 14, "iron")
    return m, function(img)
      run(img, 5, 8, 8, 2, ACCENT.brass); run(img, 19, 12, 8, 2, ACCENT.brass)
      run(img, 5, 24, 14, 1, "#2C3038"); run(img, 19, 24, 14, 1, "#2C3038")
      run(img, 7, 11, 1, 12, "#B9BFC7"); run(img, 21, 15, 1, 8, "#B9BFC7")
      spec(img, 16, 27, "#EEF1F4"); spec(img, 30, 27, "#EEF1F4")
    end
  end,
  leather = function()
    local m = new_mask()
    boot(m, 5, 9, 17, "leather"); boot(m, 19, 13, 13, "leather")
    return m, function(img)
      run(img, 5, 9, 8, 2, ACCENT.strap); run(img, 19, 13, 8, 2, ACCENT.strap)
      run(img, 5, 17, 8, 1, ACCENT.strap); run(img, 19, 19, 8, 1, ACCENT.strap)
      spec(img, 9, 17, ACCENT.brass); spec(img, 23, 19, ACCENT.brass)
      run(img, 5, 29, 15, 1, "#36210F"); run(img, 19, 29, 15, 1, "#36210F")
      run(img, 7, 12, 1, 10, "#C08A55"); run(img, 21, 16, 1, 6, "#C08A55")
    end
  end,
  -- soft shoes: low boots with a turned cuff
  cloth = function()
    local m = new_mask()
    boot(m, 5, 14, 12, "cloth"); boot(m, 19, 17, 9, "cloth")
    return m, function(img)
      run(img, 5, 14, 8, 2, ACCENT.brass); run(img, 19, 17, 8, 2, ACCENT.brass)
      run(img, 5, 25, 15, 1, "#1D2740"); run(img, 19, 25, 15, 1, "#1D2740")
      run(img, 7, 17, 1, 7, "#7D93C6"); run(img, 21, 20, 1, 4, "#7D93C6")
      spec(img, 17, 28, "#C9D6F2"); spec(img, 31, 28, "#C9D6F2")
    end
  end,
}

-- OFF HAND -------------------------------------------------------------------
shapes.off_hand = {
  -- a round shield with a boss and rivets
  iron = function()
    local m = new_mask()
    ellipse(m, 19.5, 19.5, 15, 15, "iron")
    return m, function(img)
      for y = 0, S - 1 do for x = 0, S - 1 do                 -- rim ring
        local dx, dy = x + 0.5 - 19.5, y + 0.5 - 19.5
        local r = math.sqrt(dx * dx + dy * dy)
        if r > 12.5 and r <= 14.5 then L.px(img, x, y, L.hex(ACCENT.brass_d)) end
        if r > 12.5 and r <= 13.5 and dy < 0 then L.px(img, x, y, L.hex(ACCENT.brass)) end
        if r <= 4.5 then L.px(img, x, y, L.hex(r <= 2.5 and "#B9BFC7" or "#4A505B")) end
      end end
      for _, p in ipairs({ { 19, 8 }, { 19, 30 }, { 8, 19 }, { 30, 19 } }) do spec(img, p[1], p[2], ACCENT.stud) end
      spec(img, 18, 17, "#EEF1F4"); spec(img, 13, 12, "#B9BFC7")
    end
  end,
  -- a buckler: smaller, leather-faced, studded
  leather = function()
    local m = new_mask()
    ellipse(m, 19.5, 19.5, 13, 13, "leather")
    return m, function(img)
      for y = 0, S - 1 do for x = 0, S - 1 do
        local dx, dy = x + 0.5 - 19.5, y + 0.5 - 19.5
        local r = math.sqrt(dx * dx + dy * dy)
        if r > 10.5 and r <= 12.5 then L.px(img, x, y, L.hex("#4A505B")) end
        if r > 10.5 and r <= 11.5 and dy < 0 then L.px(img, x, y, L.hex("#7C838E")) end
        if r <= 3.5 then L.px(img, x, y, L.hex(r <= 1.5 and "#B9BFC7" or "#4A505B")) end
      end end
      for _, p in ipairs({ { 19, 9 }, { 19, 29 }, { 9, 19 }, { 29, 19 }, { 12, 12 }, { 26, 12 }, { 12, 26 }, { 26, 26 } }) do
        spec(img, p[1], p[2], ACCENT.stud)
      end
      spec(img, 15, 14, "#E9C08E")
    end
  end,
  -- a lute for the bard: pear body, neck, brass strings (INSTRUMENT family)
  instr = function()
    local m = new_mask()
    ellipse(m, 17, 25, 9, 8, "leather")
    ellipse(m, 17, 20, 6.5, 6, "leather")
    poly(m, { { 20, 16 }, { 23, 14 }, { 33, 4 }, { 35, 6 }, { 24, 17 } }, "leather")
    return m, function(img)
      for y = 20, 30 do for x = 12, 22 do
        local dx, dy = (x + 0.5 - 17) / 3.2, (y + 0.5 - 25) / 3.2
        if dx * dx + dy * dy <= 1 then L.px(img, math.floor(tx(x) + 0.5), math.floor(tx(y) + 0.5), L.hex("#14100C")) end
      end end
      for i = 0, 2 do run(img, 14 + i * 2, 12, 1, 18, ACCENT.brass) end
      run(img, 33, 4, 2, 2, ACCENT.brass_d)
      spec(img, 12, 21, "#E9C08E")
    end
  end,
  -- a tome: cover, spine, clasp, a sigil
  cloth = function()
    local m = new_mask()
    rect(m, 9, 6, 22, 28, "cloth")
    return m, function(img)
      run(img, 9, 6, 4, 28, "#2F3F62")                 -- spine
      run(img, 12, 6, 1, 28, "#7D93C6")
      run(img, 27, 8, 4, 24, "#E9E1CF")                -- pages
      run(img, 27, 8, 4, 1, "#FFFBEE")
      run(img, 24, 18, 6, 4, ACCENT.brass_d)           -- clasp
      run(img, 24, 18, 6, 1, ACCENT.brass)
      run(img, 17, 14, 6, 1, ACCENT.brass); run(img, 17, 24, 6, 1, ACCENT.brass)   -- sigil
      run(img, 17, 14, 1, 11, ACCENT.brass); run(img, 22, 14, 1, 11, ACCENT.brass)
      spec(img, 19, 19, ACCENT.gem)
    end
  end,
}

-- WEAPONS --------------------------------------------------------------------
-- Every weapon runs bottom-left to top-right like the reference sword, so the
-- set reads as one family in a row of slots.
local function haft(m, x0, y0, x1, y1, w, tag)
  -- a thick line from (x0,y0) to (x1,y1) as a rotated rectangle
  local dx, dy = x1 - x0, y1 - y0
  local len = math.sqrt(dx * dx + dy * dy)
  local nx, ny = -dy / len * w / 2, dx / len * w / 2
  poly(m, { { x0 + nx, y0 + ny }, { x1 + nx, y1 + ny }, { x1 - nx, y1 - ny }, { x0 - nx, y0 - ny } }, tag)
end
shapes.weapon = {
  dagger = function()
    local m = new_mask()
    haft(m, 8, 31, 14, 25, 3, "leather")                                      -- grip
    ellipse(m, 7, 32, 2, 2, "iron")                                           -- pommel
    haft(m, 12, 27, 18, 21, 7, "iron")                                        -- crossguard (short)
    poly(m, { { 14, 25 }, { 17, 22 }, { 34, 5 }, { 35, 9 }, { 19, 27 } }, "iron")  -- blade
    return m, function(img)
      run(img, 20, 20, 1, 1, "#EEF1F4"); run(img, 26, 14, 1, 1, "#EEF1F4")
      spec(img, 8, 30, "#C08A55")
    end
  end,
  mace = function()
    local m = new_mask()
    haft(m, 6, 33, 22, 17, 3.5, "wood")
    ellipse(m, 26, 13, 7.5, 7.5, "iron")                                      -- head
    for _, p in ipairs({ { 26, 4 }, { 35, 13 }, { 26, 22 }, { 17, 13 }, { 32, 7 }, { 32, 19 }, { 20, 7 }, { 20, 19 } }) do
      ellipse(m, p[1], p[2], 1.8, 1.8, "iron")                                -- flanges
    end
    ellipse(m, 6, 33, 2, 2, "iron")
    return m, function(img)
      run(img, 24, 11, 2, 2, "#EEF1F4")
      run(img, 12, 26, 1, 1, "#A8744A")
    end
  end,
  staff_wood = function()
    local m = new_mask()
    haft(m, 5, 34, 33, 6, 3.5, "wood")
    ellipse(m, 33, 6, 3, 3, "iron"); ellipse(m, 6, 33, 2.5, 2.5, "iron")     -- iron caps
    haft(m, 17, 22, 21, 18, 5, "leather")                                     -- grip wrap
    return m, function(img)
      spec(img, 32, 5, "#EEF1F4"); run(img, 10, 28, 1, 1, "#A8744A")
    end
  end,
  staff_fire = function()
    local m = new_mask()
    haft(m, 5, 34, 29, 10, 3.5, "wood")
    ellipse(m, 30, 8, 5, 5, "gem_fire")                                       -- ember stone
    poly(m, { { 26, 12 }, { 30, 3 }, { 34, 12 } }, "gem_fire")                -- flame tip
    haft(m, 15, 24, 19, 20, 5, "leather")
    return m, function(img)
      run(img, 29, 7, 1, 1, "#FFE9C4"); run(img, 30, 4, 1, 1, "#FFE9C4")
    end
  end,
  staff_arc = function()
    local m = new_mask()
    haft(m, 5, 34, 28, 11, 3.5, "wood")
    poly(m, { { 30, 2 }, { 35, 9 }, { 30, 15 }, { 25, 9 } }, "gem_arc")       -- crystal
    haft(m, 15, 24, 19, 20, 5, "leather")
    return m, function(img)
      run(img, 29, 6, 1, 1, "#E4EEFF"); run(img, 30, 8, 1, 3, "#8FB5FF")
    end
  end,
  staff_druid = function()
    local m = new_mask()
    haft(m, 5, 34, 30, 9, 3.5, "wood")
    ellipse(m, 31, 8, 3.5, 3.5, "gem_life")                                   -- living stone
    poly(m, { { 27, 12 }, { 22, 6 }, { 29, 8 } }, "gem_life")                 -- a leaf
    poly(m, { { 33, 12 }, { 38, 15 }, { 34, 9 } }, "gem_life")
    return m, function(img)
      run(img, 30, 7, 1, 1, "#E8FFE0"); run(img, 12, 27, 1, 1, "#A8744A")
    end
  end,
  totem = function()
    local m = new_mask()
    haft(m, 7, 33, 27, 13, 3.5, "wood")
    poly(m, { { 22, 15 }, { 28, 4 }, { 36, 10 }, { 30, 20 } }, "wood")        -- carved head
    poly(m, { { 26, 8 }, { 24, 2 }, { 28, 6 } }, "cloth")                     -- feathers
    poly(m, { { 32, 6 }, { 36, 1 }, { 35, 7 } }, "cloth")
    return m, function(img)
      run(img, 27, 10, 2, 2, "#14100C"); run(img, 31, 12, 2, 2, "#14100C")    -- eyes
      run(img, 28, 15, 4, 1, "#14100C")                                       -- mouth
      run(img, 25, 8, 1, 1, "#E9C08E")
    end
  end,
}

-- CHESTS (cloth and leather; plate is the reference's own cuirass) ---------
shapes.chest = {
  cloth = function()
    local m = new_mask()
    rect(m, 10, 7, 20, 27, "cloth")                                           -- body
    ellipse(m, 11, 9, 5, 4, "cloth"); ellipse(m, 29, 9, 5, 4, "cloth")        -- shoulders
    rect(m, 6, 9, 5, 9, "cloth"); rect(m, 29, 9, 5, 9, "cloth")               -- sleeves
    poly(m, { { 16, 7 }, { 24, 7 }, { 20, 13 } }, false)                      -- the V of the collar
    return m, function(img)
      run(img, 12, 20, 16, 3, ACCENT.brass_d); run(img, 12, 20, 16, 1, ACCENT.brass)   -- sash
      run(img, 20, 13, 1, 7, "#2F3F62"); run(img, 20, 23, 1, 10, "#2F3F62")     -- the fall of the cloth
      run(img, 11, 32, 18, 1, "#7D93C6")
      spec(img, 13, 10, "#C9D6F2")
    end
  end,
  leather = function()
    local m = new_mask()
    poly(m, { { 11, 6 }, { 16, 4 }, { 23, 4 }, { 28, 6 }, { 31, 12 }, { 30, 33 }, { 9, 33 }, { 8, 12 } }, "leather")
    poly(m, { { 16, 4 }, { 23, 4 }, { 19.5, 11 } }, false)
    return m, function(img)
      for i = 0, 3 do run(img, 18, 13 + i * 4, 3, 1, ACCENT.strap) end        -- laces
      for i = 0, 3 do spec(img, 17, 13 + i * 4, ACCENT.brass); spec(img, 21, 13 + i * 4, ACCENT.brass) end
      run(img, 9, 9, 1, 22, "#C08A55"); run(img, 29, 9, 1, 22, "#36210F")
      run(img, 10, 31, 20, 1, "#36210F")
    end
  end,
}

-- TRINKETS: one medallion, four stones (canon's charms of Armor / Health / Mana / Power)
local function charm(gem)
  return function()
    local m = new_mask()
    poly(m, { { 17, 3 }, { 22, 3 }, { 22, 8 }, { 17, 8 } }, "gold")           -- bail
    ellipse(m, 19.5, 21, 12, 12, "gold")
    ellipse(m, 19.5, 21, 7.5, 7.5, gem)
    return m, function(img)
      run(img, 18, 4, 1, 3, "#FFF1B8")
      run(img, 16, 17, 2, 2, "#FFFFFF"); run(img, 15, 19, 1, 1, "#FFFFFF")    -- the stone's glint
    end
  end
end
shapes.trinket = {
  armor = charm("gem_grey"), health = charm("gem_red"), mana = charm("gem_arc"), power = charm("gem_fire"),
}

-- ---------------------------------------------------------------- export
for slot, mats in pairs(shapes) do
  for mat, make in pairs(mats) do
    local m, detail = make()
    local spr = render(m, detail)
    local name = "item_" .. slot .. "_" .. mat
    L.save_ase(spr, SRC .. name .. ".aseprite")
    L.save_png(spr, OUT .. name .. ".png")
    spr:close()
  end
end
print("GEN_ITEMS OK")
