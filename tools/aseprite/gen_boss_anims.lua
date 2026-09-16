-- gen_boss_anims.lua - the six boss ranks' animation strips, derived from the
-- sliced stills (STAGE-08, W3-ENEMIES), and the enemies.json table that names
-- them.
--
-- Spec 09 §4.3 row 4 wants HP/hit/death states on the enemy; spec 02 §7 and
-- §9.1 measure the reference boss idling with an emissive eye core. The six
-- shipped ranks are single slices (PIPE-17: byte copies of art/export/boss/*,
-- placed by tools/art/place_enemies.py and pinned by tests/unit/
-- test_art_sources.gd), so the rank PNGs stay exactly what they are and the
-- ANIMATION is derived from them here, into game/assets/enemies/anim/:
--
--   <rank>.png       body strip, 12 frames in one row, tags
--                      idle  [0,3]   4 frames: a 1px breath (head and chest
--                                    bands step down a pixel and back — the
--                                    townsfolk's cadence, gen_actors.py)
--                      hit   [4,5]   2 frames: docs/12 §5.2's #FFF6DC flash on
--                                    a 1px recoil, then the 2px recoil
--                      death [6,11]  6 frames: desaturate, a 12° topple about
--                                    the feet (docs/12 §3.3's death whitelist),
--                                    fade to half
--   <rank>_glow.png  the emissive eye/mouth layer on the SAME canvas, frames
--                    and tags, so SceneStage plays both with one tag: the
--                    still's own eye pixels lifted toward the creature's ramp
--                    core with a 1px halo, pulsing over the idle (lit, mid,
--                    dim, mid), lit through the hit, dying with the death. The
--                    stage draws it at modulate 1.6 (STAGE-08's 1.4-1.8) so the
--                    glow catches it — an 8-bit PNG cannot carry > 1.0.
--
-- The frame canvas is the still plus the room the topple and the recoil need
-- (padded equally left and right so the still's bottom-centre stays the
-- frame's bottom-centre — `anchor [0.5, 1.0]`, which is what place_boss plants
-- by). Nothing about the DESIGN is decided here: every body pixel is the
-- slice's, moved; the only paint is the glow layer, and where a creature's
-- slice has no lit eye (the flame brute's dark sockets) the socket pixels are
-- what is lit. Which pixels are the eyes is data in RANKS below, read off the
-- zoomed stills (build/plan/report-W3-ENEMIES.md).
--
-- Deterministic (no random anywhere), every file written through lib.lua, so
-- build_art.sh --check gates the strips AND enemies.json. The rank -> export
-- mapping (W0-MANIFEST) is the RANKS table here; enemies.json is written from
-- it, never hand-edited. Aseprite 1.3.7 headless: `"$ASEPRITE" -b --script
-- tools/aseprite/gen_boss_anims.lua`.

local L = dofile("tools/aseprite/lib.lua")
local EXPORTS = "art/export/boss/"
local SRC, OUT = "art/src/enemies/", "game/assets/enemies/anim/"
local TABLE = "game/assets/enemies/enemies.json"

local FPS_IDLE, FPS_HIT, FPS_DEATH = 5, 11, 9   -- docs/12 §5.2: 160 / 90 / 110 ms
local IDLE_N, HIT_N, DEATH_N = 4, 2, 6
local N = IDLE_N + HIT_N + DEATH_N
local TOPPLE_DEG = 12
local RECOIL_PX = 2
local DEATH_FADE = 0.55                         -- alpha left on the last frame
local GLOW_MODULATE = 1.6                       -- what the stage draws the glow layer at
local FLASH = L.hex("#FFF6DC")                  -- docs/12 §5.2 hit flash

-- Emissive ramps, dark -> core; stop 4 is the HOT stop the lit eye is pushed
-- to (>= 215 in its hue channel, so x1.6 clears the 1.3 glow threshold), stop
-- 3 the halo, stop 2 the dim stop (< 160 everywhere, so a dim frame does not
-- bloom). The void ramp is spec 02 §9.1's boss-eye ramp with its #FFFFFF core
-- pulled to #F8F0FF (docs/12 §4: no pure white); the others follow the
-- creature (a fire brute with magenta eyes would be wrong).
local RAMPS = {
  void = { "#301890", "#601890", "#9018C0", "#D848F0", "#F8F0FF" },
  red  = { "#4A0A10", "#8A1220", "#D8302C", "#FF7A5A", "#FFE0C8" },
  fire = { "#4A1621", "#813D2A", "#D8622E", "#F3BE43", "#FCF4BA" },
  moss = { "#1E3A16", "#3F7A22", "#8FCB3A", "#D8F58A", "#F4FFD8" },
}

-- Which still pixels are the eyes/mouth: picks = {x, y, w, h, rule[, r0, r1]}
-- in still pixels; `rule` filters the rect's pixels by the still's own colour
-- (see pick_rule); r0..r1 keeps only an annulus about the rect's centre (the
-- colossus's core is a ring round a dark centre). `waist` is where the breath
-- folds, as a share of the height (gen_actors.py's WAIST); `head` where the
-- head band ends.
local RANKS = {
  { rank = "boss_main", export = "sludge_maw_leviathan", ramp = "red",
    picks = { { 53, 20, 3, 4, "all" }, { 90, 18, 4, 4, "all" } } },
  { rank = "boss_main_2", export = "void_colossus_core", ramp = "void",
    picks = { { 64, 17, 23, 23, "magenta", 4, 10.5 } } },
  { rank = "boss_mini", export = "boss_spiked_crawler", ramp = "fire",
    picks = { { 45, 30, 4, 4, "red" }, { 55, 18, 14, 12, "yellow" } } },
  { rank = "boss_mini_2", export = "boss_stone_brute", ramp = "moss",
    picks = { { 23, 27, 5, 4, "bright" }, { 39, 23, 5, 4, "bright" } } },
  { rank = "boss_elite", export = "boss_flame_brute", ramp = "fire",
    picks = { { 32, 27, 2, 2, "all" }, { 40, 27, 2, 2, "all" } } },
  { rank = "boss_trash", export = "void_tentacle_a", ramp = "void",
    picks = { { 0, 0, 36, 77, "vivid" } } },
}
local HEAD, WAIST = 0.30, 0.55

-- ---------------------------------------------------------------- helpers

local function chan(c) return L.chan(c) end

local function pick_rule(rule, r, g, b, a)
  if a == 0 then return false end
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  if rule == "all" then return true end
  if rule == "bright" then return mx > 150 end
  if rule == "red" then return r > 120 and r > g + 50 and r > b + 50 end
  if rule == "magenta" then return r > 170 and b > 170 and g < 120 end
  if rule == "yellow" then return r > 230 and g > 150 end
  if rule == "vivid" then return mx > 220 and mx - mn > 90 end
  error("gen_boss_anims: unknown pick rule " .. tostring(rule))
end

--- The set of still pixels a rank's picks select: {[y*w+x] = true, list = {{x,y}, ...}}.
local function select_glow(still, picks)
  local set = { list = {} }
  for _, p in ipairs(picks) do
    local x0, y0, w, h, rule, r0, r1 = p[1], p[2], p[3], p[4], p[5], p[6], p[7]
    local cx, cy = x0 + w / 2, y0 + h / 2
    for y = y0, y0 + h - 1 do
      for x = x0, x0 + w - 1 do
        if x >= 0 and y >= 0 and x < still.width and y < still.height then
          local r, g, b, a = chan(still:getPixel(x, y))
          local ok = pick_rule(rule, r, g, b, a)
          if ok and r0 then
            local d = math.sqrt((x + 0.5 - cx) ^ 2 + (y + 0.5 - cy) ^ 2)
            ok = d >= r0 and d <= r1
          end
          if ok and not set[y * still.width + x] then
            set[y * still.width + x] = true
            set.list[#set.list + 1] = { x, y }
          end
        end
      end
    end
  end
  return set
end

--- The band a still row belongs to, and that band's vertical offset in an
--- idle frame: offs = {head, chest} (legs never move).
local function band_off(y, h, offs)
  if y < math.floor(h * HEAD) then return offs[1] end
  if y < math.floor(h * WAIST) then return offs[2] end
  return 0
end

local IDLE_OFFS = { { 0, 0 }, { 1, 1 }, { 1, 0 }, { 0, 0 } }
local GLOW_LEVEL = { 1.0, 0.7, 0.45, 0.7 }

--- Draw the still onto a frame at (ox, oy) with per-band breath offsets,
--- optionally shifted `dx` (the recoil) and flashed.
local function draw_body(img, still, ox, oy, offs, dx, flash)
  local h = still.height
  -- bands back to front: legs, chest, head — a band stepping down lands on
  -- the one below it (the 1px compression that IS the breath)
  for _, band in ipairs({ 3, 2, 1 }) do
    for y = 0, h - 1 do
      local b = (y < math.floor(h * HEAD)) and 1 or ((y < math.floor(h * WAIST)) and 2 or 3)
      if b == band then
        local off = band_off(y, h, offs)
        for x = 0, still.width - 1 do
          local c = still:getPixel(x, y)
          local _, _, _, a = chan(c)
          if a > 0 then
            if flash then
              local fr, fg, fb = chan(L.mix(c, FLASH, 0.6))
              c = L.rgba(fr, fg, fb, a)            -- the flash keeps the edge's own alpha
            end
            L.blend(img, ox + x + dx, oy + y + off, c)
          end
        end
      end
    end
  end
end

--- The death frame: the still rotated `deg` about its bottom-centre, desaturated
--- by `t` and faded to `alpha_mul`, sampled nearest (pixel art rotates hard).
local function draw_toppled(img, still, ox, oy, deg, t, alpha_mul, only_set, ramp_core)
  local w, h = still.width, still.height
  local px, py = ox + w / 2, oy + h              -- the feet-centre, in frame space
  local th = math.rad(deg)
  local cs, sn = math.cos(-th), math.sin(-th)
  for dy = 0, img.height - 1 do
    for dx = 0, img.width - 1 do
      -- inverse-rotate the destination pixel centre back into the still
      local vx, vy = dx + 0.5 - px, dy + 0.5 - py
      local sx = px + vx * cs - vy * sn
      local sy = py + vx * sn + vy * cs
      local ix, iy = math.floor(sx - ox), math.floor(sy - oy)
      if ix >= 0 and iy >= 0 and ix < w and iy < h then
        if not only_set or only_set[iy * w + ix] then
          local c = still:getPixel(ix, iy)
          local r, g, b, a = chan(c)
          if a > 0 then
            if ramp_core then
              c = L.mix(L.rgba(r, g, b), ramp_core, 0.9)
              r, g, b = chan(c)
            else
              local grey = math.floor(0.3 * r + 0.59 * g + 0.11 * b + 0.5)
              r = math.floor(r + (grey - r) * t + 0.5)
              g = math.floor(g + (grey - g) * t + 0.5)
              b = math.floor(b + (grey - b) * t + 0.5)
            end
            L.blend(img, dx, dy, L.rgba(r, g, b, math.floor(a * alpha_mul + 0.5)))
          end
        end
      end
    end
  end
end

--- The glow layer for one frame: the picked pixels pushed to the ramp's hot
--- stop (saturated, so at modulate 1.6 the creature's own hue blooms rather
--- than a white block), with a 1px halo of the stop below, at `level`
--- (1 = lit; a dim frame sinks toward the ramp's second stop, which stays
--- under the 1.3 glow threshold — that is the pulse).
local function draw_glow(img, still, set, ox, oy, offs, dx, ramp, level)
  local hot, mid, low = L.hex(ramp[4]), L.hex(ramp[3]), L.hex(ramp[2])
  local h = still.height
  local placed = {}
  for _, p in ipairs(set.list) do
    local x, y = p[1], p[2]
    local off = band_off(y, h, offs)
    local sr, sg, sb = chan(still:getPixel(x, y))
    local lit = L.mix(L.rgba(sr, sg, sb), hot, 0.9)
    local c = L.mix(low, lit, level)
    local fx, fy = ox + x + dx, oy + y + off
    L.px(img, fx, fy, c)
    placed[fy * img.width + fx] = true
  end
  local mr, mg, mb = chan(mid)
  local halo = L.rgba(mr, mg, mb, math.floor(110 * level + 0.5))
  for _, p in ipairs(set.list) do
    local x, y = p[1], p[2]
    local fx, fy = ox + x + dx, oy + y + band_off(y, h, offs)
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      local hx, hy = fx + d[1], fy + d[2]
      if not placed[hy * img.width + hx] then
        L.blend(img, hx, hy, halo)
        placed[hy * img.width + hx] = true   -- one halo pass, no double blend
      end
    end
  end
end

-- ---------------------------------------------------------------- the strips

local rows = {}

for _, R in ipairs(RANKS) do
  local still = L.import_png(EXPORTS .. R.export .. ".png")
  local w, h = still.width, still.height
  local ramp = RAMPS[R.ramp]
  local set = select_glow(still, R.picks)
  assert(#set.list > 0, "gen_boss_anims: " .. R.rank .. " picks nothing to light")
  -- the canvas: room for the topple's swing (the head moves h*sin, the far
  -- top corner rises w/2*sin) and the recoil, padded equally each side
  local sn = math.sin(math.rad(TOPPLE_DEG))
  local pad_x = math.ceil(h * sn) + RECOIL_PX + 1
  local pad_y = math.ceil(w / 2 * sn) + 1
  local fw, fh = w + pad_x * 2, h + pad_y
  local ox, oy = pad_x, pad_y

  local function paint_body(img, i)
    if i < IDLE_N then
      draw_body(img, still, ox, oy, IDLE_OFFS[i + 1], 0, false)
    elseif i < IDLE_N + HIT_N then
      local k = i - IDLE_N                       -- 0: flash + 1px, 1: 2px
      draw_body(img, still, ox, oy, IDLE_OFFS[1], -(k + 1), k == 0)
    else
      local k = i - IDLE_N - HIT_N + 1           -- 1..6
      local t = k / DEATH_N
      draw_toppled(img, still, ox, oy, -TOPPLE_DEG * t, t, 1 - (1 - DEATH_FADE) * t, nil, nil)
    end
  end

  local function paint_glow(img, i)
    if i < IDLE_N then
      draw_glow(img, still, set, ox, oy, IDLE_OFFS[i + 1], 0, ramp, GLOW_LEVEL[i + 1])
    elseif i < IDLE_N + HIT_N then
      local k = i - IDLE_N
      draw_glow(img, still, set, ox, oy, IDLE_OFFS[1], -(k + 1), ramp, 1.0)
    else
      local k = i - IDLE_N - HIT_N + 1
      local t = k / DEATH_N
      draw_toppled(img, still, ox, oy, -TOPPLE_DEG * t, t, 1 - t, set, L.hex(ramp[4]))
    end
  end

  -- one .aseprite per rank carries the body; the tag names are docs/12 §5.2's
  L.strip(R.rank, fw, fh, N, FPS_IDLE, paint_body, { tag = "idle", src_dir = SRC, out_dir = OUT })
  L.strip(R.rank .. "_glow", fw, fh, N, FPS_IDLE, paint_glow, { tag = "idle", src_dir = SRC, out_dir = OUT })
  rows[#rows + 1] = { rank = R.rank, export = R.export, fw = fw, fh = fh, glow = #set.list }
  print(string.format("  %-12s %3dx%-3d still -> %d frames of %dx%d, %d glow px", R.rank, w, h, N, fw, fh, #set.list))
end

-- ---------------------------------------------------------------- enemies.json
-- The rank table W0-MANIFEST wrote (PIPE-17), regenerated here so the strip
-- geometry can never drift from the PNGs beside it. place_enemies.py reads
-- export_dir/target_dir/manifest/ranks[].export; test_art_sources.gd pins the
-- typed slots; SceneStage.place_boss reads strip/glow/frame_w/frame_h/tags.
do
  local out = {
    "{",
    ' "_note": [',
    '  "The boss table (W0-MANIFEST, PIPE-17). Each rank the game loads by name (Cards.gd encounter_art,",',
    '  "RaidView.gd boss plate) is a byte copy of one sliced export: tools/art/place_enemies.py copies",',
    '  "art/export/boss/<export>.png -> game/assets/enemies/<rank>.png (--check compares instead).",',
    '  "The export\'s sheet rect lives ONLY in art/ref/manifests/all.json under its `export` name, so",',
    '  "the chain sheet -> export -> rank is one lookup per hop and no rect is stored twice.",',
    '  "W3-ENEMIES: this file is WRITTEN by tools/aseprite/gen_boss_anims.lua (build_art.sh --gen; --check",',
    '  "gates it) — never hand-edit. `strip` / `glow` are the animation strips derived from the still",',
    '  "(anim/<rank>.png body, anim/<rank>_glow.png the emissive eye layer drawn at `glow_modulate`),",',
    '  "`frames` x `frame_w` by `frame_h` in one row; `fps` is the idle rate; `tags` maps a tag name",',
    '  "-> [first_frame, last_frame, fps]; scale 1.0 = plate-native (Q02 rules whether an integer",',
    '  "upscale is ever allowed); anchor = [x, y] of the feet-centre in normalized frame space",',
    '  "(SceneStage.place_boss plants offset.y = -h/2, i.e. [0.5, 1.0]).",',
    '  "tests/unit/test_art_sources.gd asserts every rank here is byte-identical to its export."',
    ' ],',
    ' "export_dir": "art/export/boss",',
    ' "target_dir": "game/assets/enemies",',
    ' "manifest": "art/ref/manifests/all.json",',
    string.format(' "glow_modulate": %.1f,', GLOW_MODULATE),
    ' "ranks": {',
  }
  for i, r in ipairs(rows) do
    out[#out + 1] = string.format('  "%s": {', r.rank)
    out[#out + 1] = string.format('   "export": "%s",', r.export)
    out[#out + 1] = string.format('   "strip": "anim/%s.png",', r.rank)
    out[#out + 1] = string.format('   "glow": "anim/%s_glow.png",', r.rank)
    out[#out + 1] = string.format('   "frames": %d,', N)
    out[#out + 1] = string.format('   "frame_w": %d,', r.fw)
    out[#out + 1] = string.format('   "frame_h": %d,', r.fh)
    out[#out + 1] = string.format('   "fps": %d,', FPS_IDLE)
    out[#out + 1] = '   "scale": 1.0,'
    out[#out + 1] = '   "anchor": [0.5, 1.0],'
    out[#out + 1] = string.format('   "glow_px": %d,', r.glow)
    out[#out + 1] = string.format('   "tags": {"idle": [0, %d, %d], "hit": [%d, %d, %d], "death": [%d, %d, %d]}',
      IDLE_N - 1, FPS_IDLE, IDLE_N, IDLE_N + HIT_N - 1, FPS_HIT, IDLE_N + HIT_N, N - 1, FPS_DEATH)
    out[#out + 1] = (i < #rows) and "  }," or "  }"
  end
  out[#out + 1] = " }"
  out[#out + 1] = "}"
  L.write_text(TABLE, table.concat(out, "\n") .. "\n")
end

print("GEN_BOSS_ANIMS OK")
