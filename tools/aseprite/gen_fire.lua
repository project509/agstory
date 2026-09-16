-- gen_fire.lua - the flame strips and the ember dot the scenes animate with.
--
-- art/ref/specs/09 s5 ranks fire first among the motion that gives a still
-- plate life per unit of work, and 11 s6 wants the flames emissive so the 2D
-- glow catches them. Nothing here is traced from a sheet: the fireplace in
-- Concept 1 is painted into the plate, so the sprite is authored to sit ON the
-- painted hearth and read as the same fire moving.
--
-- PAINTED, NOT SPECKLED (STAGE-12): Concept 1's hearth (330,380,90,90) and
-- Concept 3's campfire are four or five clean colour bands with a licking
-- outline. So each frame is 2-3 tongues rasterised as ONE filled silhouette,
-- banded from the outline inward (edge, tongue, body, hot, core — the core
-- sits low, over the coals), and the only noise is a +-1px jitter on the
-- outline itself, re-rolled every third row. Five colours a frame, one
-- connected shape, and a dark edge row at the seat so it reads as sitting on
-- the logs. The scenes' ember emitters supply the loose sparks.
--
-- Each strip goes through L.strip: the .aseprite carries real frames, a `burn`
-- tag and durations, and the PNG is the same frames in one row for SceneStage
-- to cut at the consumer's `frame_w` (scenes/*.json declares it, and the fps).
-- The PNG geometry is pinned — fire_hearth 64x56x8, fire_camp 40x52x8,
-- fire_torch 16x24x6 — by tests/unit/test_vfx_assets.gd, because every scene
-- JSON was authored against it. Deterministic: the jitter is a seeded LCG and
-- frames are painted in order, so a re-run reproduces the same pixels
-- (build_art.sh --check, verify.sh stage 2b).

local L = dofile("tools/aseprite/lib.lua")
local SRC, OUT = "art/src/vfx/", "game/assets/vfx/"

-- Warm ramp from the reference's own fire pixels (01 s8, 04 s5): core, hot,
-- body, tongue, edge. The edge is a dark warm line, never black.
local RAMP = {
  core = L.hex("#FFF4C0"), hot = L.hex("#FFC466"), body = L.hex("#F58A3C"),
  tongue = L.hex("#DE5A2E"), edge = L.hex("#4A1621"),
}

--- Deterministic per-frame noise: a tiny LCG so frames differ but re-runs do not.
local function rng(seed)
  local s = seed
  return function()
    s = (s * 1103515245 + 12345) % 2147483648
    return s / 2147483648
  end
end

--- One tongue's silhouette, OR-ed into the frame mask `m`. tg = {dx, w, h}:
--- the tongue's box sits at x = dx and is bottom-aligned in the frame. The
--- profile rises from a point, is widest near the seat and tapers a little at
--- the very bottom; the tip leans with a per-tongue phase (k) so the tongues do
--- not sway in step; the height breathes twice per loop. The jitter only ever
--- moves the outline by one pixel, and never at the tip.
local function tongue_mask(m, tg, f, frames, rnd, k)
  local x0, tw, th = tg[1], tg[2], tg[3]
  local H = m.h
  local phase = (f / frames) * 2 * math.pi
  local p1 = phase + k * 2.1
  local p2 = phase * 2 + k * 0.7
  local hh = th * (0.88 + 0.12 * (0.5 + 0.5 * math.sin(p2)))
  local top = H - hh
  local cx = x0 + tw / 2
  local hw_max = tw / 2 - 0.5
  local jl, jr = 0, 0
  local y_top = math.floor(top)
  for y = y_top, H - 1 do
    local t = (y - top) / math.max(1, hh - 1)          -- 0 at the tip, 1 at the seat
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local fw = t ^ 0.75
    if t > 0.75 then fw = fw * (1 - 0.35 * (t - 0.75) / 0.25) end   -- narrows again at the seat
    local hw = hw_max * fw
    local lean = (1 - t) ^ 1.4 * tw * 0.26 * math.sin(p1)
               + (1 - t) * tw * 0.07 * math.sin(p2 + t * 5.0)
    local c = cx + lean
    if (y - y_top) % 3 == 0 then
      local r = rnd(); jl = (r < 0.3) and -1 or ((r > 0.7) and 1 or 0)
      r = rnd(); jr = (r < 0.3) and -1 or ((r > 0.7) and 1 or 0)
    end
    if hw < 1.5 then jl, jr = 0, 0 end
    local left = math.floor(c - hw + jl + 0.5)
    local right = math.floor(c + hw + jr + 0.5)
    if right < left then left = math.floor(c + 0.5); right = left end
    for x = left, right do L.mset(m, x, y, true) end
  end
end

--- Euclidean distance from each set pixel to the nearest unset one (within
--- `reach`), so the bands follow the silhouette as round contours rather than
--- the square steps a Chebyshev depth would give.
local function edt(m, reach)
  local d = {}
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) then
        local best = reach * reach
        for oy = -reach, reach do
          for ox = -reach, reach do
            if not L.mget(m, x + ox, y + oy) then
              local q = ox * ox + oy * oy
              if q < best then best = q end
            end
          end
        end
        d[y * m.w + x] = math.sqrt(best)
      end
    end
  end
  return d
end

--- Bands from the outline inward. The outline is the UNION's edge (one
--- silhouette, one dark line), but the bands are each tongue's own — a pixel
--- takes the deepest band any tongue gives it — so the side licks keep their
--- own hot centres instead of dissolving into one wide blob. Depth is read as
--- a fraction of that tongue's half-width (a torch and a hearth get the same
--- look at their own size) and scaled down toward the tip, so the hot and
--- core bands sit low, over the coals.
local function paint_bands(img, m, masks, hws)
  local rim = edt(m, 3)                                      -- the union's own rim
  local depths = {}
  for k, tm in ipairs(masks) do depths[k] = edt(tm, math.ceil(hws[k]) + 1) end
  for y = 0, m.h - 1 do
    local t = y / (m.h - 1)                                  -- 1 at the seat
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) then
        local c
        if L.mask_is_edge(m, x, y) then c = RAMP.edge
        elseif rim[y * m.w + x] <= 2.0 then c = RAMP.tongue
        else
          local r = 0
          for k, dk in ipairs(depths) do
            local dd = dk[y * m.w + x]
            if dd then
              local rk = dd / hws[k] * (0.55 + 0.45 * t)
              if rk > r then r = rk end
            end
          end
          if r < 0.28 or t < 0.20 then c = RAMP.body
          elseif r < 0.55 or t < 0.40 then c = RAMP.hot
          else c = RAMP.core end
        end
        L.px(img, x, y, c)
      end
    end
  end
end

--- A strip is one row of frames. `tongues` lists sub-flames as {dx, w, h}
--- relative to the frame; a hearth fire is several tongues that merge into one
--- silhouette, a torch is one. `fps` is the source's own playback rate (what
--- the GUI shows); the scene JSON that mounts the strip still declares the
--- rate the game runs it at.
local function strip(name, w, h, frames, seed, tongues, fps)
  local rnd = rng(seed)
  tongues = tongues or { { 0, w, h } }
  local hws = {}
  for k, tg in ipairs(tongues) do hws[k] = tg[2] / 2 * 0.9 end
  L.strip(name, w, h, frames, fps, function(img, f)
    local m, masks = L.mask_new(w, h), {}
    for k, tg in ipairs(tongues) do
      masks[k] = L.mask_new(w, h)
      tongue_mask(masks[k], tg, f, frames, rnd, k)
      for i = 0, w * h - 1 do if masks[k][i] then m[i] = true end end
    end
    paint_bands(img, m, masks, hws)
  end, { tag = "burn", src_dir = SRC, out_dir = OUT })
end

-- The fireplace: wide and low, three tongues so it fills the painted hearth.
strip("fire_hearth", 64, 56, 8, 11, { { 2, 30, 36 }, { 32, 30, 40 }, { 13, 38, 56 } }, 9)
strip("fire_camp", 40, 52, 8, 23, { { 0, 22, 34 }, { 18, 22, 38 }, { 6, 28, 52 } }, 9)
strip("fire_torch", 16, 24, 6, 37, nil, 8)    -- wall torches, candles

-- Ember: a 4x4 soft dot the particles use. Core hot, edge warm, corners clear.
do
  local spr = L.new_sprite(4, 4)
  local img = L.img(spr)
  L.fill(img, 1, 1, 2, 2, RAMP.hot)
  L.px(img, 1, 0, RAMP.body); L.px(img, 2, 0, RAMP.body)
  L.px(img, 1, 3, RAMP.body); L.px(img, 2, 3, RAMP.body)
  L.px(img, 0, 1, RAMP.body); L.px(img, 0, 2, RAMP.body)
  L.px(img, 3, 1, RAMP.body); L.px(img, 3, 2, RAMP.body)
  L.save_ase(spr, SRC .. "ember.aseprite")
  L.save_png(spr, OUT .. "ember.png")
  spr:close()
end

-- Light: a 64x64 soft radial falloff for PointLight2D. Alpha, not colour —
-- the light's own colour tints it.
do
  local spr = L.new_sprite(64, 64)
  local img = L.img(spr)
  for y = 0, 63 do
    for x = 0, 63 do
      local d = math.sqrt((x - 31.5) ^ 2 + (y - 31.5) ^ 2) / 32
      local a = d >= 1 and 0 or math.floor(255 * (1 - d) * (1 - d))
      L.px(img, x, y, app.pixelColor.rgba(255, 255, 255, a))
    end
  end
  L.save_ase(spr, SRC .. "light_soft.aseprite")
  L.save_png(spr, OUT .. "light_soft.png")
  spr:close()
end

-- ---------------------------------------------------------------- life (W4-LIFE)
-- The hub's small motions: a lantern flame, the camp's banners and a gull.
-- They live one directory down (game/assets/vfx/life/) with their own table,
-- life.json, because vfx.json is gen_vfx.lua's and a PNG that table does not
-- name fails tests/unit/test_vfx_assets.gd by name; tests/unit/
-- test_scene_stage.gd holds these to life.json the same way. The sails
-- (sail_a/b) are cut by tools/art/patch_plate.py (PY, its own --check) and
-- are declared here so one table covers the folder, as vfx.json declares the
-- clouds.
local LIFE_SRC, LIFE_OUT = "art/src/vfx/", "game/assets/vfx/life/"
local LIFE = {}   -- rows for life.json, in the order they are made
local function life_row(name, frames, w, h, fps, tag, gen)
  LIFE[#LIFE + 1] = { name, frames, w, h, fps, tag, gen }
end

-- spec 09 s5 rank 2: a dedicated 3-frame 6x8 flame for the lanterns (the
-- torch strip at 1/3 scale is "not allowed (pitch)"). A lantern's glass is
-- BRIGHT, so unlike the hearth there is no dark edge row: the outline is the
-- body tone, the inside is hot, and the seat is the core. The tongue leans
-- and breathes with the same phase machinery as the big fires.
do
  local w, h, frames = 6, 8, 3
  local rnd = rng(53)
  L.strip("flame_lantern", w, h, frames, 8, function(img, f)
    local m = L.mask_new(w, h)
    tongue_mask(m, { 0, w, h }, f, frames, rnd, 1)
    for y = 0, h - 1 do
      local t = y / (h - 1)
      for x = 0, w - 1 do
        if L.mget(m, x, y) then
          local c
          if L.mask_is_edge(m, x, y) then c = (t < 0.35) and RAMP.tongue or RAMP.body
          elseif t > 0.6 then c = RAMP.core
          else c = RAMP.hot end
          L.px(img, x, y, c)
        end
      end
    end
  end, { tag = "burn", src_dir = LIFE_SRC, out_dir = LIFE_OUT })
  life_row("flame_lantern", frames, w, h, 8, "burn", "tools/aseprite/gen_fire.lua")
end

-- spec 03 s9 layer 4 / TOWN-27: the camp's hanging banners, cut from the bare
-- plate's own pixels and waved. A banner is an OPAQUE crop of the plate (so at
-- rest it is the plate, pixel for pixel, and the reduced-motion frame is the
-- painting); the cloth rows — found per row as the crimson span, sigil
-- included — ride a travelling ripple that grows from nothing at the crossbar
-- to two pixels at the hem, written RELATIVE to the rest pose so frame 0 is
-- exactly the crop. The columns a shifted row vacates show the crop's own
-- background, inpainted across the cloth from the pixels either side.
local PLATE_CAMP = "game/assets/bg/stage_camp.png"
local function is_cloth(c)
  local r, g, b, a = L.chan(c)
  return a > 0 and r > 55 and r > g * 1.45 and r > b * 1.2
end

local function banner(name, x0, y0, w, h, frames, fps, wavelength, amp)
  local plate = L.import_png(PLATE_CAMP)
  -- the crop, and per row the cloth span (or nil)
  local crop, span = {}, {}
  for y = 0, h - 1 do
    local l, r = nil, nil
    for x = 0, w - 1 do
      local c = plate:getPixel(x0 + x, y0 + y)
      crop[y * w + x] = c
      if is_cloth(c) then
        if not l then l = x end
        r = x
      end
    end
    if l and r - l >= 2 then span[y] = { l, r } end
  end
  -- the background under the cloth: a lerp across the span from its two rims
  local bg = {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do bg[y * w + x] = crop[y * w + x] end
    local s = span[y]
    if s then
      local l, r = s[1], s[2]
      local cl = crop[y * w + math.max(0, l - 1)]
      local cr = crop[y * w + math.min(w - 1, r + 1)]
      for x = l, r do
        bg[y * w + x] = L.mix(cl, cr, (x - l + 1) / (r - l + 2))
      end
    end
  end
  local top = nil
  for y = 0, h - 1 do if span[y] and not top then top = y end end
  top = top or 0
  local hem = 0
  for y = 0, h - 1 do if span[y] then hem = y end end
  L.strip(name, w, h, frames, fps, function(img, f)
    for y = 0, h - 1 do
      for x = 0, w - 1 do L.px(img, x, y, bg[y * w + x]) end
    end
    local phase = f / frames * 2 * math.pi
    for y = 0, h - 1 do
      local s = span[y]
      if s then
        local drop = (y - top) / math.max(1, hem - top)
        local a = amp * drop ^ 1.5
        local th = 2 * math.pi * y / wavelength
        local dx = math.floor(a * (math.sin(th - phase) - math.sin(th)) + 0.5)
        for x = s[1], s[2] do
          local nx = x + dx
          if nx >= 0 and nx < w then L.px(img, nx, y, crop[y * w + x]) end
        end
      end
    end
  end, { tag = "wave", src_dir = LIFE_SRC, out_dir = LIFE_OUT })
  life_row(name, frames, w, h, fps, "wave", "tools/aseprite/gen_fire.lua")
end

-- The camp's north banner over the fire ring, and the one by the west tent
-- (crops measured at 4x — W4-LIFE report; the east banner is off every
-- consumer's band). stage_camp.json places each as a `props` entry anchored
-- top-left at the crop's origin.
banner("banner_wave", 866, 80, 40, 80, 4, 6, 40, 2.0)
banner("banner_wave_b", 526, 158, 40, 88, 4, 6, 40, 2.0)

-- STAGE-14's gull: 12x6, three frames of a wingbeat — up, level, down — for
-- the aerial's `flyers` layer. Off-white, never pure; grey at the tips; a
-- slate underside one pixel below the wing (the wing's own shadow), so the
-- bird reads over the harbour's foam as well as over the forest — the first
-- MainMenu pair lost it on the white water (W4-LIFE report).
do
  local w, h, frames = 12, 6, 3
  local BODY, TIP, UNDER = L.hex("#E6E2D6"), L.hex("#6E727C"), L.hex("#3E424C")
  L.strip("gull", w, h, frames, 5, function(img, f)
    local cx, cy = 5, 3
    -- wing tips: up, level, down
    local ty = ({ 0, 2, 5 })[f + 1]
    L.line(img, cx - 1, cy + 1, 1, ty + 1, UNDER)
    L.line(img, cx + 2, cy + 1, 10, ty + 1, UNDER)
    L.line(img, cx - 1, cy, 1, ty, BODY)
    L.line(img, cx + 2, cy, 10, ty, BODY)
    L.px(img, 1, ty, TIP); L.px(img, 10, ty, TIP)
    -- the body: two pixels, a shade darker at the tail
    L.px(img, cx, cy, BODY); L.px(img, cx + 1, cy, BODY)
    L.px(img, cx, cy + 1, TIP)
  end, { tag = "fly", src_dir = LIFE_SRC, out_dir = LIFE_OUT })
  life_row("gull", frames, w, h, 5, "fly", "tools/aseprite/gen_fire.lua")
end

-- The sails: tools/art/patch_plate.py's cut (96x96 stills, the axle at the
-- canvas centre); declared here so life.json covers the folder.
life_row("sail_a", 1, 96, 96, 0, "", "tools/art/patch_plate.py")
life_row("sail_b", 1, 96, 96, 0, "", "tools/art/patch_plate.py")

do
  local out = {
    "{",
    ' "note": [',
    '  "Every PNG under game/assets/vfx/life and the geometry its generator wrote it at",',
    '  "(W4-LIFE: the lantern flame, the camp banners, the gull, the windmill sails). Same",',
    '  "shape as ../vfx.json; written by tools/aseprite/gen_fire.lua - never hand-edit;",',
    '  "tests/unit/test_scene_stage.gd holds every PNG here to its row."',
    ' ],',
    ' "strips": {',
  }
  for i, r in ipairs(LIFE) do
    out[#out + 1] = string.format(
      '  "%s": {"frames": %d, "frame_w": %d, "frame_h": %d, "fps": %d, "tag": "%s", "generator": "%s"}%s',
      r[1], r[2], r[3], r[4], r[5], r[6], r[7], (i < #LIFE) and "," or "")
  end
  out[#out + 1] = " }"
  out[#out + 1] = "}"
  L.write_text(LIFE_OUT .. "life.json", table.concat(out, "\n") .. "\n")
end

print("GEN_FIRE OK")
