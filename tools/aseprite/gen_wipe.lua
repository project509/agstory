-- gen_wipe.lua - the two textures docs/13 §11.4's wipe sequence asks for and
-- the kit did not have: the ink bleed at t=900 and the wax seal at t=1,400.
--
--   ./tools/build_art.sh --gen   (or)   Aseprite -b --script tools/aseprite/gen_wipe.lua
--
-- Outputs: art/src/ui/<name>.aseprite (source of truth, per build_art.sh) and
-- game/assets/ui/<name>.png (what Godot loads).
--
-- BOTH COLOURS ARE THE KIT'S, NOT NEW ONES.
--   * the blot is `Palette.DANGER` (#F73526), which is what `Widgets.stamp()`
--     already inks a stamp with — §11.4 calls the bleed "into the paper fibre"
--     under that same stamp, so a second red would read as a different object.
--   * the seal is `Palette.CTA_TOP`/`CTA_BOTTOM` (#5B1D27 / #511924) with the
--     CTA plate's own bronze rim (#886955) and its near-black outline
--     (#0B0A0C). Those are the commit control's colours, and the commit control
--     is the thing this project already calls wax (`Widgets.wax_button()`). A
--     seal in a second wax would say the two are unrelated materials.
--
-- EVERYTHING IS DETERMINISTIC. No `math.random`: the blot's irregularity comes
-- from a fixed table of lobes and a sine-based edge wobble, so re-running this
-- produces the same bytes and `build_art.sh --check` (verify.sh stage 2b) stays green.
-- An ink blot that differed every build would show up as a diff nobody made.
--
-- SECOND PASS (W1-CHROME, COMBAT-15): the first blot was a gaussian salmon
-- cloud and the seal a rimmed disc with no device. Now the blot has a HARD core
-- at DANGER 85% with a 6px dithered fibre edge and two satellite drips (ink
-- that ran), and the seal carries the guild emblem's skull pressed into the
-- wax, a top-left highlight and a 2px offset shadow. Same 320x150 / 72x72 so
-- RaidView's placement (and test_wipe_sequence's seal-position checks) hold.

local L = dofile("tools/aseprite/lib.lua")
local SRC, OUT = "art/src/ui/", "game/assets/ui/"

local function emit(spr, name)
  L.save_ase(spr, SRC .. name .. ".aseprite")
  L.save_png(spr, OUT .. name .. ".png")
  spr:close()
end

-- Bayer 4x4 at image coordinates, 0..1 (lib.lua keeps its own private).
local BAYER4 = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }
local function bayer(x, y) return (BAYER4[y % 4 + 1][x % 4 + 1] + 0.5) / 16 end

-- ---------------------------------------------------------------- the bleed
-- §11.4: "then a 400ms ink bleed into the paper fibre". Paper fibre is the
-- reason this is not a disc: ink spreading into a surface wicks along the grain
-- and stops unevenly, so the shape is a few overlapping lobes with a wobbling
-- rim, a HARD core (wet ink is opaque) and a short dithered fringe where the
-- fibre drank it — an ordered dither, not a gaussian: a soft gradient reads as
-- a glow, which is a light, not ink.
--
-- Sized to sit behind the WIPE stamp's own box (520x90 in RaidView) with room
-- to spread past it, which is what makes it read as ink under the word rather
-- than a shape beside it.
local BLOT_W, BLOT_H = 320, 150

-- {cx, cy, r} in blot space. Fixed, not rolled: see the header.
local LOBES = {
  {160, 76, 62}, {104, 66, 44}, {214, 70, 46},
  {132, 96, 38}, {192, 98, 40}, {160, 50, 40},
}

-- The two drips: a small satellite lobe joined to the body by a thin run
-- ({x0, y0, x1, y1, r}: a capsule), where the ink ran downhill and stopped.
local DRIPS = {
  { lobe = {268, 116, 9}, run = {236, 96, 262, 112, 2.6} },
  { lobe = {54, 42, 7},   run = {84, 56, 60, 46, 2.2} },
}

local function seg_dist(x, y, x0, y0, x1, y1)
  local vx, vy = x1 - x0, y1 - y0
  local wx, wy = x - x0, y - y0
  local t = (vx * vx + vy * vy) > 0 and (wx * vx + wy * vy) / (vx * vx + vy * vy) or 0
  t = math.max(0, math.min(1, t))
  local px, py = x0 + t * vx, y0 + t * vy
  return math.sqrt((x - px) * (x - px) + (y - py) * (y - py))
end

--- Signed "insideness" in pixels: > 0 inside the ink, larger = deeper.
local function blot_inside(x, y)
  local best = -1e9
  for _, lb in ipairs(LOBES) do
    local dx, dy = x - lb[1], y - lb[2]
    -- The wobble: a fixed two-frequency ripple on the radius, so the rim is
    -- irregular the way a spread is and identical on every run.
    local ang = math.atan(dy, dx)
    local r = lb[3] * (1.0 + 0.055 * math.sin(ang * 3.0) + 0.022 * math.sin(ang * 7.0 + 1.7))
    local inside = r - math.sqrt(dx * dx + dy * dy)
    if inside > best then best = inside end
  end
  for _, d in ipairs(DRIPS) do
    local lb = d.lobe
    local dx, dy = x - lb[1], y - lb[2]
    local ang = math.atan(dy, dx)
    local r = lb[3] * (1.0 + 0.08 * math.sin(ang * 2.0 + 0.4))
    local inside = r - math.sqrt(dx * dx + dy * dy)
    if inside > best then best = inside end
    local run = d.run
    inside = run[5] - seg_dist(x, y, run[1], run[2], run[3], run[4])
    if inside > best then best = inside end
  end
  return best
end

local EDGE = 6.0        -- the fibre fringe, in pixels
local CORE_A = 217      -- DANGER at 85%: ink under a stamp, not a slab over the log

local function ink_blot()
  local spr = L.new_sprite(BLOT_W, BLOT_H)
  local img = L.img(spr)
  local r, g, b = L.chan(L.hex("#F73526"))
  local ink = L.rgba(r, g, b, CORE_A)
  for y = 0, BLOT_H - 1 do
    for x = 0, BLOT_W - 1 do
      local d = blot_inside(x, y)
      if d > EDGE then
        L.px(img, x, y, ink)
      elseif d > 0 then
        -- the fringe: the deeper the pixel, the more of the dither takes
        if bayer(x, y) < d / EDGE then L.px(img, x, y, ink) end
      end
    end
  end
  emit(spr, "wipe_blot")
end

-- ---------------------------------------------------------------- the seal
-- §11.4: "a wax seal drops onto the lower-right corner". Round, slightly
-- irregular at the rim the way poured wax is, with the CTA plate's gradient so
-- it is the same material as the commit control, a bronze ring for the press,
-- the guild's emblem (the skull, game/assets/ui/emblem.png) pressed into it as
-- the device, a highlight up-left and a 2px shadow down-right so it sits ON
-- the page.
local SEAL = 72
local SHADOW_DX, SHADOW_DY = 2, 2

local function seal_radius(ang)
  -- Poured wax is not a circle. One low-frequency wobble, fixed.
  return SEAL * 0.5 - 5.5 + 2.0 * math.sin(ang * 3.0 + 0.6)
end

--- The emblem's skull as a silhouette, 40 wide, nearest-sampled from the
--- 82x57 crop by luminance (the emblem is cream on a dark ground, not on
--- alpha). Read from the tree — an input, not an output, so `out=` does not
--- redirect it.
local DEVICE_W, DEVICE_H = 40, 28
local function device_mask()
  local em = L.import_png("game/assets/ui/emblem.png")
  local m = L.mask_new(DEVICE_W, DEVICE_H)
  for ty = 0, DEVICE_H - 1 do
    for tx = 0, DEVICE_W - 1 do
      local sx = math.floor((tx + 0.5) * em.width / DEVICE_W)
      local sy = math.floor((ty + 0.5) * em.height / DEVICE_H)
      local c = em:getPixel(sx, sy)
      local r, g, b, a = L.chan(c)
      local lum = 0.30 * r + 0.59 * g + 0.11 * b
      L.mset(m, tx, ty, a > 128 and lum > 118)
    end
  end
  return m
end

local function wax_seal()
  local spr = L.new_sprite(SEAL, SEAL)
  local img = L.img(spr)
  local cx, cy = SEAL * 0.5 - 0.5 - 1, SEAL * 0.5 - 0.5 - 1
  local top, bottom = L.hex("#5B1D27"), L.hex("#511924")
  local rim, outline = L.hex("#886955"), L.hex("#0B0A0C")
  local shadow = L.rgba(11, 10, 12, 150)
  local device = device_mask()
  local dx0, dy0 = math.floor(cx - DEVICE_W / 2 + 0.5), math.floor(cy - DEVICE_H / 2 + 0.5) + 1
  -- the shadow first, offset down-right
  for y = 0, SEAL - 1 do
    for x = 0, SEAL - 1 do
      local dx, dy = x - SHADOW_DX - cx, y - SHADOW_DY - cy
      if math.sqrt(dx * dx + dy * dy) <= seal_radius(math.atan(dy, dx)) then
        L.blend(img, x, y, shadow)
      end
    end
  end
  for y = 0, SEAL - 1 do
    for x = 0, SEAL - 1 do
      local dx, dy = x - cx, y - cy
      local d = math.sqrt(dx * dx + dy * dy)
      local r = seal_radius(math.atan(dy, dx))
      if d <= r then
        -- The body: the CTA's own vertical gradient, so a seal beside a wax
        -- button reads as the same stuff.
        local t = y / (SEAL - 1)
        local c = L.mix(top, bottom, t)
        if d > r - 1.6 then
          c = outline                      -- the poured edge, darkest
        elseif d > r - 3.2 then
          c = L.mix(rim, outline, 0.35)    -- the lit bronze lip
        elseif L.mget(device, x - dx0, y - dy0) then
          -- The impression: the emblem pressed in is thinner and darker, and
          -- its upper-left edge catches the light the way a struck edge does.
          c = L.mix(c, outline, 0.5)
          if not L.mget(device, x - dx0 - 1, y - dy0 - 1) then c = L.mix(c, rim, 0.45) end
        elseif d < r * 0.62 and L.mget(device, x - dx0 + 1, y - dy0 + 1) then
          c = L.mix(c, L.hex("#7A2931"), 0.5)   -- the raised lip beside the cut
        end
        L.px(img, x, y, c)
      end
    end
  end
  -- One highlight arc on the upper-left, the direction every other lit edge in
  -- the kit takes (01 §2's rim runs along the top), doubled at the crown.
  for a = 196, 326 do
    local rad = math.rad(a)
    local rr = seal_radius(rad) - 2.2
    local x = math.floor(cx + math.cos(rad) * rr + 0.5)
    local y = math.floor(cy + math.sin(rad) * rr + 0.5)
    L.px(img, x, y, L.hex("#A78B7A"))
    if a > 225 and a < 300 then
      local rr2 = rr - 1
      L.px(img, math.floor(cx + math.cos(rad) * rr2 + 0.5), math.floor(cy + math.sin(rad) * rr2 + 0.5),
        L.mix(L.hex("#A78B7A"), top, 0.5))
    end
  end
  emit(spr, "wax_seal")
end

ink_blot()
wax_seal()
print("gen_wipe: docs/13 §11.4's two art beats")
