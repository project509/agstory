-- gen_vfx.lua - the six combat strips the stage plays over the figures, and
-- the vfx.json manifest that pins every strip's geometry.
--
-- Spec 02 §9.1 measured the reference's spell VFX (arcane orb, muzzle flash,
-- red impact burst, cyan slash arc, void lightning) as footprints with 5-stop
-- ramps; 07 §4.2 groups the sheet's 36 stills into colour families (ice, fire,
-- void, smoke, sparkles). Nothing here is traced: every strip is drawn from
-- those ramps at the sizes 00-plan §W1-VFX fixes for 2x figures (PIPE-02 names
-- and sizes win — CRITIC-C04). No text, no pure black or white.
--
-- Each strip goes through L.strip: real frames + a `play` tag + durations in
-- the .aseprite, one row in the PNG. `frame_w` and `fps` stay the CONSUMER's
-- declaration (SceneStage.add_fx, W2-STAGE2); game/assets/vfx/vfx.json,
-- written at the bottom of this file, is the table tests/unit/test_vfx_assets.gd
-- checks every PNG against — the fires (gen_fire.lua) and the cloud layers
-- (tools/art/gen_clouds.py, Python, so build_art.sh --check does not run it)
-- are declared there too. Deterministic: one seeded LCG per strip, drawn in a
-- fixed order; every file is written through lib.lua so --check gates it.

local L = dofile("tools/aseprite/lib.lua")
local SRC, OUT = "art/src/vfx/", "game/assets/vfx/"

--- Deterministic noise: the same tiny LCG gen_fire.lua uses.
local function rng(seed)
  local s = seed
  return function()
    s = (s * 1103515245 + 12345) % 2147483648
    return s / 2147483648
  end
end

local function ramp(list)
  local t = {}
  for i, s in ipairs(list) do t[i] = L.hex(s) end
  return t
end

-- dark -> hot: index 1 is the rim, the last index the core.
local ARCANE = ramp{ "#443388", "#67599E", "#7769BE", "#9AA9F9", "#B3EEFD" } -- 02 §9.1 blue arcane orb
local FIRE   = ramp{ "#813D2A", "#D8622E", "#F3BE43", "#FCF4BA" }            -- 02 §9.1 muzzle flash; 07 §4.2 fire/orange
local IMPACT = ramp{ "#6A294C", "#A54980", "#D81830", "#FA9194", "#FD9FFD" } -- 02 §9.1 red impact burst
local SLASH  = ramp{ "#314476", "#4C5594", "#2C7AD7", "#75C0F9", "#B7F1FD" } -- 02 §9.1 cyan slash arc
local HOLY   = ramp{ "#3B6FE0", "#9FD8FF", "#F4FBFF" }                       -- 07 §4.2 sparkles: 4-point white/blue
local SMOKE  = ramp{ "#3A3D4A", "#6A6F80", "#A0A6B4" }                       -- 07 §4.2 smoke/grey 3-step

-- ---------------------------------------------------------------- helpers

--- Polar coordinates of a pixel centre about (cx, cy): distance and the screen
--- angle in degrees (0 = 3 o'clock, 90 = 6 o'clock, since y grows down).
local function polar(x, y, cx, cy)
  local dx, dy = x + 0.5 - cx, y + 0.5 - cy
  local a = math.deg(math.atan(dy, dx))
  if a < 0 then a = a + 360 end
  return math.sqrt(dx * dx + dy * dy), a
end

--- Signed shortest angular difference a - b, in (-180, 180].
local function adiff(a, b)
  local d = (a - b) % 360
  if d > 180 then d = d - 360 end
  return d
end

--- Euclidean distance from each set mask pixel to the nearest unset one
--- (within `reach`): round bands, which is what a burst or a puff wants.
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

--- A frame is a mask plus a colour per set pixel; setc sets both (bounds
--- checked), paint puts them on the image after the rim glow has gone down.
local function setc(m, col, x, y, c)
  if x < 0 or y < 0 or x >= m.w or y >= m.h then return end
  L.mset(m, x, y, true)
  col[y * m.w + x] = c
end

local function paint(img, m, col)
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) then L.px(img, x, y, col[y * m.w + x]) end
    end
  end
end

--- Ordered-dither erase: clear the set pixels whose Bayer threshold is under
--- t — the pixel-art way for a puff to thin out without a new alpha per pixel.
local BAYER4 = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }
local function dither_erase(m, t)
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) and (BAYER4[y % 4 + 1][x % 4 + 1] + 0.5) / 16 < t then
        L.mset(m, x, y, false)
      end
    end
  end
end

--- A tapered ray from (cx, cy) at `ang` degrees: length `len`, half-width
--- `hw` at the root shrinking to a point. colour_of(u) picks the colour along
--- it (u = 0 root .. 1 tip); u < from is left open (a ray breaking up).
local function ray(m, col, cx, cy, ang, len, hw, from, colour_of)
  if len <= 0 then return end
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      local d, a = polar(x, y, cx, cy)
      local da = math.rad(adiff(a, ang))
      if math.abs(da) < math.pi / 2 then
        local along, perp = d * math.cos(da), math.abs(d * math.sin(da))
        local u = along / len
        if u >= from and u <= 1 and perp <= hw * (1 - u) + 0.5 then
          setc(m, col, x, y, colour_of(u))
        end
      end
    end
  end
end

local function disc(m, col, cx, cy, r, c)
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      local dx, dy = x + 0.5 - cx, y + 0.5 - cy
      if dx * dx + dy * dy <= r * r then setc(m, col, x, y, c) end
    end
  end
end

-- The manifest rows: every strip this file emits records itself; the other
-- generators' files are declared below by hand, and the test holds each PNG
-- to its row.
local ROWS = {}
local function row(name, frames, fw, fh, fps, tag, gen)
  ROWS[#ROWS + 1] = { name, frames, fw, fh, fps, tag, gen }
end

local function emit(name, w, h, n, fps, paint_frame)
  L.strip(name, w, h, n, fps, paint_frame, { tag = "play", src_dir = SRC, out_dir = OUT })
  row(name, n, w, h, fps, "play", "tools/aseprite/gen_vfx.lua")
end

-- ---------------------------------------------------------------- fx_spark_hit
-- 32x32x4: a warm starburst that flares, throws its rays and breaks into
-- sparks — the melee hit (07 §4.2 fire/orange: Warrior hit).
do
  local rnd = rng(101)
  local N = 7
  local ang, len = {}, {}
  for i = 1, N do
    ang[i] = (i - 1) * 360 / N + (rnd() - 0.5) * 24
    len[i] = 0.8 + rnd() * 0.4
  end
  local CORE  = { 3.6, 3.0, 2.0, 1.0 }
  local REACH = { 5, 10, 14, 15 }
  local HALFW = { 1.8, 1.5, 1.0, 0.6 }
  emit("fx_spark_hit", 32, 32, 4, 16, function(img, f)
    local m, col = L.mask_new(32, 32), {}
    local cx, cy = 16, 16
    for i = 1, N do
      ray(m, col, cx, cy, ang[i], REACH[f + 1] * len[i], HALFW[f + 1], (f == 3) and 0.55 or 0, function(u)
        if f == 3 then return FIRE[2] end
        return (u < 0.35) and FIRE[4] or ((u < 0.7) and FIRE[3] or FIRE[2])
      end)
    end
    disc(m, col, cx, cy, CORE[f + 1] + 1.2, FIRE[3])
    disc(m, col, cx, cy, CORE[f + 1], FIRE[4])
    if f >= 2 then                                   -- tip sparks once the rays have flown
      for i = 1, N do
        local r = REACH[f + 1] * len[i] + ((f == 3) and 1 or 0)
        local sx = math.floor(cx + math.cos(math.rad(ang[i])) * r)
        local sy = math.floor(cy + math.sin(math.rad(ang[i])) * r)
        setc(m, col, sx, sy, FIRE[3])
        if f == 2 then setc(m, col, sx + 1, sy, FIRE[3]) end
      end
    end
    L.glow_mask(img, 0, 0, m, FIRE[1], (f < 3) and 170 or 90)
    paint(img, m, col)
  end)
end

-- ---------------------------------------------------------------- fx_slash_arc
-- 64x48x5: a 200° cyan crescent sweeping from upper-left to lower-right,
-- thicker at the leading edge, with a dotted afterimage (02 §9.1 slash).
do
  local rnd = rng(202)
  local cx, cy, R = 30.5, 25.5, 18.5
  local A0, A1 = 225, 425
  local SPAN  = { { 0, 0.38 }, { 0, 0.72 }, { 0, 1.0 }, { 0.42, 1.0 }, { 0.78, 1.0 } }
  local THICK = { 1.0, 1.0, 1.0, 0.7, 0.45 }
  local FADE  = { 0, 0, 0, 1, 2 }
  local DOTS  = { false, false, false, { 0.08, 0.42 }, { 0.40, 0.78 } }
  emit("fx_slash_arc", 64, 48, 5, 15, function(img, f)
    local m, col = L.mask_new(64, 48), {}
    local u0, u1 = SPAN[f + 1][1], SPAN[f + 1][2]
    for y = 0, 47 do
      for x = 0, 63 do
        local d, a = polar(x, y, cx, cy)
        if a < A0 then a = a + 360 end
        local u = (a - A0) / (A1 - A0)
        if u >= u0 and u <= u1 then
          local th = (2.2 + 6.2 * u ^ 1.3) * THICK[f + 1]
          local q = math.abs(d - R) / (th / 2)
          if q <= 1 then
            local i = (q < 0.3) and 5 or ((q < 0.62) and 4 or ((q < 0.86) and 3 or 2))
            if u < u0 + 0.18 then i = i - 1 end          -- the trailing end dims
            i = i - FADE[f + 1]
            if i < 1 then i = 1 end
            setc(m, col, x, y, SLASH[i])
          end
        end
      end
    end
    if DOTS[f + 1] then                                  -- the dotted afterimage
      local k = 0
      for u = DOTS[f + 1][1], DOTS[f + 1][2], 0.045 do
        k = k + 1
        if k % 2 == 1 then
          local ang = math.rad(A0 + u * (A1 - A0))
          local rr = R + (rnd() - 0.5) * 3
          setc(m, col, math.floor(cx + math.cos(ang) * rr), math.floor(cy + math.sin(ang) * rr),
               SLASH[(f == 3) and 2 or 1])
        end
      end
    end
    L.glow_mask(img, 0, 0, m, SLASH[1], (f < 3) and 150 or 70)
    paint(img, m, col)
  end)
end

-- ---------------------------------------------------------------- fx_bolt_arcane
-- 24x48x4: the mage's orb — a lighter off-centre core that pulses, four
-- satellite sparks and a tapering tail. Authored pointing UP; the consumer
-- rotates it toward the target. (02 §9.1 arcane orb.)
do
  local rnd = rng(303)
  local sparks = {}
  for i = 1, 4 do sparks[i] = rnd() * 360 end
  local CORE = { 2.6, 3.4, 2.6, 1.8 }
  emit("fx_bolt_arcane", 24, 48, 4, 12, function(img, f)
    local m, col = L.mask_new(24, 48), {}
    local hx, hy = 12, 13.5
    L.mask_ellipse(m, hx, hy, 7.5, 8.5, true)
    for y = 20, 45 do                                  -- the tail, wobbling with the frame
      local t = (y - 20) / 25
      local hw = 5.5 * (1 - t) ^ 1.25
      local c = hx + 1.6 * math.sin(y / 5.5 + f * 1.571)
      for x = math.floor(c - hw + 0.5), math.floor(c + hw + 0.5) - 1 do L.mset(m, x, y, true) end
    end
    local d = edt(m, 8)
    for y = 0, 47 do
      for x = 0, 23 do
        if L.mget(m, x, y) then
          local dd = d[y * 24 + x]
          local i = (dd <= 1) and 1 or ((dd <= 2.3) and 2 or ((dd <= 4) and 3 or ((dd <= 6) and 4 or 5)))
          if y > 22 and i > 3 then i = 3 end           -- the tail never outshines the head
          col[y * 24 + x] = ARCANE[i]
        end
      end
    end
    disc(m, col, 10.5, 11.5, CORE[f + 1], ARCANE[5])
    for i = 1, 4 do
      local ang = math.rad(sparks[i] + f * 38)
      local rr = 10.5 + (i % 2)
      setc(m, col, math.floor(hx + math.cos(ang) * rr), math.floor(hy + math.sin(ang) * rr), ARCANE[4])
    end
    L.glow_mask(img, 0, 0, m, ARCANE[1], 90)
    paint(img, m, col)
  end)
end

-- fx_bolt_trail 8x2: the streak behind the bolt (a still, stretched by the
-- consumer). Alpha and colour both rise toward the head at x = 7.
do
  local spr = L.new_sprite(8, 2)
  local img = L.img(spr)
  for x = 0, 7 do
    local t = x / 7
    local r, g, b = L.chan(L.mix(ARCANE[1], ARCANE[4], t))
    L.px(img, x, 0, L.rgba(r, g, b, math.floor(70 + 170 * t)))
    local r2, g2, b2 = L.chan(L.mix(ARCANE[1], ARCANE[3], t))
    L.px(img, x, 1, L.rgba(r2, g2, b2, math.floor(40 + 120 * t)))
  end
  L.save_ase(spr, SRC .. "fx_bolt_trail.aseprite")
  L.save_png(spr, OUT .. "fx_bolt_trail.png")
  spr:close()
  row("fx_bolt_trail", 1, 8, 2, 0, "", "tools/aseprite/gen_vfx.lua")
end

-- ---------------------------------------------------------------- fx_heal_sparkle
-- 32x32x6: a four-point glint that opens on the axes, turns onto the
-- diagonals and lets three motes rise off (07 §4.2 sparkles; A1
-- sparkle_white_a as the reference shape).
do
  local rnd = rng(404)
  local motes = {}
  for i = 1, 3 do motes[i] = { math.floor(7 + rnd() * 18), 0.6 + rnd() * 0.8 } end
  local AX   = { 4, 9, 13, 7, 3, 2 }
  local DG   = { 0, 0, 4, 10, 6, 0 }
  local CORE = { 2.0, 3.0, 3.4, 3.0, 2.0, 1.3 }
  local function holy(u) return (u < 0.4) and HOLY[3] or ((u < 0.75) and HOLY[2] or HOLY[1]) end
  emit("fx_heal_sparkle", 32, 32, 6, 12, function(img, f)
    local m, col = L.mask_new(32, 32), {}
    local cx, cy = 16, 16
    for k = 0, 3 do ray(m, col, cx, cy, k * 90, AX[f + 1], 1.6, 0, holy) end
    for k = 0, 3 do ray(m, col, cx, cy, 45 + k * 90, DG[f + 1], 1.4, 0, holy) end
    disc(m, col, cx, cy, CORE[f + 1], HOLY[3])
    if f >= 2 then
      for i, mt in ipairs(motes) do
        local my = math.floor(27 - (f - 2) * 3 * mt[2] - i * 2)
        setc(m, col, mt[1], my, HOLY[2]); setc(m, col, mt[1] + 1, my, HOLY[2])
        if f <= 4 then setc(m, col, mt[1], my + 1, HOLY[1]) end
      end
    end
    L.glow_mask(img, 0, 0, m, HOLY[1], 110)
    paint(img, m, col)
  end)
end

-- ---------------------------------------------------------------- fx_burst_impact
-- 64x64x5: the red hit burst — a core, twelve ragged spikes, a ring that opens
-- as the core hollows, and sparks that fall (02 §9.1 red impact burst).
do
  local rnd = rng(505)
  local N = 12
  local ang, len, wid = {}, {}, {}
  for i = 1, N do
    ang[i] = (i - 1) * 360 / N + (rnd() - 0.5) * 20
    len[i] = 0.7 + rnd() * 0.5
    wid[i] = 0.8 + rnd() * 0.5
  end
  local sparks = {}
  for i = 1, 8 do sparks[i] = { math.rad(15 + rnd() * 150), 4 + rnd() * 4 } end
  local CORE   = { 7, 12, 14, 11, 5 }
  local REACH  = { 0.35, 0.75, 1.0, 1.0, 0.85 }
  local HOLLOW = { 0, 0, 6, 11, 14 }
  local HALFW  = { 3.2, 3.2, 2.6, 1.7, 1.0 }
  local FADE   = { 0, 0, 0, 1, 2 }
  emit("fx_burst_impact", 64, 64, 5, 15, function(img, f)
    local m, col = L.mask_new(64, 64), {}
    local cx, cy, base = 32, 32, 28
    for y = 0, 63 do
      for x = 0, 63 do
        local d, a = polar(x, y, cx, cy)
        local inside, u = false, 0
        if d < CORE[f + 1] then inside, u = true, d / (base * REACH[f + 1]) end
        for i = 1, N do
          local da = math.rad(adiff(a, ang[i]))
          if math.abs(da) < math.pi / 2 then
            local along, perp = d * math.cos(da), math.abs(d * math.sin(da))
            local reach = base * len[i] * REACH[f + 1]
            local uu = along / reach
            if uu >= 0 and uu <= 1 and perp <= HALFW[f + 1] * wid[i] * (1 - uu) + 0.5 then
              inside = true
              if uu > u then u = uu end
            end
          end
        end
        if inside and d >= HOLLOW[f + 1] then
          local i = (u < 0.25) and 5 or ((u < 0.5) and 4 or ((u < 0.75) and 3 or 2))
          if d < CORE[f + 1] then i = (d < CORE[f + 1] * 0.55) and 5 or 4 end
          i = i - FADE[f + 1]
          if i < 1 then i = 1 end
          setc(m, col, x, y, IMPACT[i])
        end
      end
    end
    if f >= 1 then                                       -- the falling sparks
      for _, s in ipairs(sparks) do
        local r = s[2] + 6 * f
        local sx = math.floor(cx + math.cos(s[1]) * r)
        local sy = math.floor(cy + math.sin(s[1]) * r + 1.2 * f * f)
        local c = (f <= 2) and IMPACT[4] or IMPACT[2]
        setc(m, col, sx, sy, c)
        if f <= 2 then setc(m, col, sx + 1, sy, c) end
      end
    end
    L.glow_mask(img, 0, 0, m, IMPACT[1], (f < 3) and 200 or 110)
    paint(img, m, col)
  end)
end

-- ---------------------------------------------------------------- fx_poof_smoke
-- 48x48x5: the death poof — six grey-blue blobs that swell, rise, drift and
-- dither away (07 §4.2 smoke/grey; A1 smoke_puff_grey as the reference).
do
  local rnd = rng(606)
  local blobs = {}
  for i = 1, 6 do
    blobs[i] = { (rnd() - 0.5) * 20, (rnd() - 0.5) * 12, 5 + rnd() * 3.5, (rnd() - 0.5) * 1.6 }
  end
  local ERASE = { 0, 0, 0.18, 0.45, 0.72 }
  emit("fx_poof_smoke", 48, 48, 5, 10, function(img, f)
    local m, col = L.mask_new(48, 48), {}
    local e = 1 + 0.14 * f
    local cx, cy = 24, 29 - 2.2 * f
    for _, b in ipairs(blobs) do
      L.mask_ellipse(m, cx + b[1] * e + b[4] * f, cy + b[2] * e, b[3] * e, b[3] * e * 0.8, true)
    end
    local d = edt(m, 6)
    for y = 0, 47 do
      for x = 0, 47 do
        if L.mget(m, x, y) then
          local dd = d[y * 48 + x]
          local c
          if dd <= 1 then c = SMOKE[1]
          elseif dd <= 2.3 then c = SMOKE[2]
          elseif (y - cy) + 0.4 * (x - cx) < 1 then c = SMOKE[3]   -- lit from the upper-left
          else c = SMOKE[2] end
          col[y * 48 + x] = c
        end
      end
    end
    if f <= 2 then L.glow_mask(img, 0, 0, m, SMOKE[1], 60) end
    dither_erase(m, ERASE[f + 1])
    paint(img, m, col)
  end)
end

-- ---------------------------------------------------------------- vfx.json
-- The other generators' files, declared here so one table covers the folder.
row("fire_hearth", 8, 64, 56, 9, "burn", "tools/aseprite/gen_fire.lua")
row("fire_camp", 8, 40, 52, 9, "burn", "tools/aseprite/gen_fire.lua")
row("fire_torch", 6, 16, 24, 8, "burn", "tools/aseprite/gen_fire.lua")
row("ember", 1, 4, 4, 0, "", "tools/aseprite/gen_fire.lua")
row("light_soft", 1, 64, 64, 0, "", "tools/aseprite/gen_fire.lua")
row("clouds_far", 1, 1536, 220, 0, "", "tools/art/gen_clouds.py")
row("clouds_near", 1, 1536, 220, 0, "", "tools/art/gen_clouds.py")

do
  local out = {
    "{",
    ' "note": [',
    '  "Every PNG under game/assets/vfx and the geometry its generator wrote it at. frame_w is",',
    '  "the width of ONE frame; the PNG is frames * frame_w wide and frame_h tall (one row).",',
    '  "fps is the source rate stamped in the .aseprite; the scene JSON that mounts a strip",',
    '  "declares the rate the game runs it at. Written by tools/aseprite/gen_vfx.lua — never",',
    '  "hand-edit; tests/unit/test_vfx_assets.gd holds every PNG to its row."',
    ' ],',
    ' "strips": {',
  }
  for i, r in ipairs(ROWS) do
    out[#out + 1] = string.format(
      '  "%s": {"frames": %d, "frame_w": %d, "frame_h": %d, "fps": %d, "tag": "%s", "generator": "%s"}%s',
      r[1], r[2], r[3], r[4], r[5], r[6], r[7], (i < #ROWS) and "," or "")
  end
  out[#out + 1] = " }"
  out[#out + 1] = "}"
  L.write_text(OUT .. "vfx.json", table.concat(out, "\n") .. "\n")
end

print("GEN_VFX OK")
