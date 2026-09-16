-- gen_icons.lua - THE icon grid (00-plan §W1-ICONS, CRITIC-G07/C03, PIPE-13):
-- every glyph the kit and the screens need, at one fixed cell size per role,
-- emitted by this one generator and addressed only through game/ui/Icons.gd.
--
--   ./tools/build_art.sh --gen   (or)   Aseprite -b --script tools/aseprite/gen_icons.lua
--   (run from the project root; `build_art.sh --check` byte-compares the output)
--
-- The grid (role -> cell): class/emote/arrow/lock 16 · log 22 · state/mech/bar/
-- face 24 · rank 28 · building/empty/item/furnishing/slot 32 · sigil 48 · blot 12.
--
-- Every shape is authored as pixel SPANS ({y, x0, x1[, key]}) or as lib.lua
-- masks/strokes, never as ASCII art, because a span cannot be one character
-- short. Silhouettes go through render_* helpers that derive the 1px outline /
-- rim / highlight programmatically, so all icons in a group share one
-- treatment and a palette change is one line. No math.random anywhere: the
-- bytes are gated by verify.sh stage 2b.
--
-- Colours trace to game/ui/Palette.gd: DANGER/CAUTION/POSITIVE for the morale
-- ramp, TEXT_SLATE-family greys for the slot glyphs, ACCENT_GOLD/GEM for the
-- top ranks, TEXT_TITLE cream for the chevrons. Nothing here is #000000/#FFFFFF
-- and no glyph is text (docs/13 §14): numerals and "!" over a state plate are
-- Labels; the emote marks are pictures of punctuation, not font glyphs.
--
-- Outputs: game/assets/ui/icons/<name>.png for every name a screen already
-- loads by path (rank_*, mech_*, face_N, slot_*, item_* potions, arrows, cog,
-- fast_forward) and game/assets/ui/icons/grid/<name>.png for the new grid;
-- art/src/ui/icons/** mirrors both (source of truth); game/assets/ui/faces.png
-- + faces_30.png + faces_36.png (+ .json) are the morale face strips at the
-- three text scales; game/assets/ui/icons/grid/icons.json is the emit manifest
-- tests/unit/test_icons.gd reads (name, role, key, file, w, h).
--
-- WHY grid/: tests/unit/test_art_sources.gd walks the top level of icons/ against
-- a hand-transcribed emit list it owns; the new grid lives one directory down
-- where Icons.gd (the only file that names icon paths) finds it, and the
-- handoff extends that list.

local L = dofile("tools/aseprite/lib.lua")
local hex = L.hex
local SRC, OUT = "art/src/ui/icons/", "game/assets/ui/icons/"
local GRID_SRC, GRID_OUT = "art/src/ui/icons/grid/", "game/assets/ui/icons/grid/"

-- ---------------------------------------------------------------- helpers

-- the emit manifest (icons/grid/icons.json), in emission order
local MANIFEST, SHEETS = {}, {}
local function record(name, role, key, w, h, rel)
  MANIFEST[#MANIFEST + 1] = string.format(
    '    {"name": "%s", "role": "%s", "key": "%s", "file": "%s", "w": %d, "h": %d}',
    name, role, key, rel, w, h)
end

-- legacy names: the top level of icons/ (a screen loads these by path today)
local function emit(spr, name, role, key)
  record(name, role, key, spr.width, spr.height, name .. ".png")
  L.save_ase(spr, SRC .. name .. ".aseprite")
  L.save_png(spr, OUT .. name .. ".png")
  spr:close()
end

-- the grid: icons/grid/<name>.png, reached only through Icons.at(role, key)
local function emit_grid(spr, name, role, key)
  record(name, role, key, spr.width, spr.height, "grid/" .. name .. ".png")
  L.save_ase(spr, GRID_SRC .. name .. ".aseprite")
  L.save_png(spr, GRID_OUT .. name .. ".png")
  spr:close()
end

-- spans: list of {y, x0, x1[, key]}; pal maps key -> colour ("#" is the default)
local function spans(img, list, pal, ox, oy)
  ox, oy = ox or 0, oy or 0
  for _, s in ipairs(list) do
    local c = pal[s[4] or "#"]
    assert(c, "no colour for span key " .. tostring(s[4]))
    for x = s[2], s[3] do L.blend(img, ox + x, oy + s[1], c) end
  end
end

-- one-colour spans
local function sp(img, list, c, ox, oy) spans(img, list, { ["#"] = c }, ox, oy) end

-- append rows y0..y1 of x0..x1 to a span list
local function rows(list, y0, y1, x0, x1, key)
  for y = y0, y1 do list[#list + 1] = { y, x0, x1, key } end
  return list
end

-- a boolean mask (lib.lua), so outlines and rings can be derived rather than drawn
local mget, is_edge, touches_edge, bbox = L.mget, L.mask_is_edge, L.mask_touches_edge, L.mask_bbox
local function mask_spans(w, h, list)
  local m = L.mask_new(w, h)
  L.mask_spans(m, list, true)
  return m
end
local function mask_disc(w, h, cx, cy, r)
  local m = L.mask_new(w, h)
  L.mask_ellipse(m, cx, cy, r, r, true)
  return m
end

-- rounded rectangle into a mask (radius r, pixel-centre test)
local function mask_rrect(m, x, y, w, h, r, v)
  if v == nil then v = true end
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do
      local px, py = xx - x + 0.5, yy - y + 0.5
      local dx = math.max(r - px, px - (w - r), 0)
      local dy = math.max(r - py, py - (h - r), 0)
      if dx * dx + dy * dy <= r * r then L.mset(m, xx, yy, v) end
    end
  end
end

-- a mask from whatever `draw(img, c)` strokes onto a scratch image: the way
-- lines and arcs become silhouettes that the treatments below can outline
local function drawn_mask(w, h, draw)
  local im = Image(w, h, ColorMode.RGB)
  im:clear(L.rgba(0, 0, 0, 0))
  draw(im, L.rgba(200, 200, 200, 255))
  local m = L.mask_new(w, h)
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if app.pixelColor.rgbaA(im:getPixel(x, y)) > 0 then L.mset(m, x, y, true) end
    end
  end
  return m
end

local function mask_flip_y(m)
  local o = L.mask_new(m.w, m.h)
  for y = 0, m.h - 1 do for x = 0, m.w - 1 do if mget(m, x, y) then L.mset(o, x, m.h - 1 - y, true) end end end
  return o
end
local function mask_transpose(m)
  local o = L.mask_new(m.h, m.w)
  for y = 0, m.h - 1 do for x = 0, m.w - 1 do if mget(m, x, y) then L.mset(o, y, x, true) end end end
  return o
end

--- Sprite treatment: light body, `shade` where the down/right neighbour is
--- open (a lit-from-top-left read), a dark 1px ring OUTSIDE the mask. Two
--- tones when shade is nil (the class glyphs), three for the buildings.
local function sprite(img, m, fill, shade, outline, ox, oy)
  ox, oy = ox or 0, oy or 0
  for y = -1, m.h do
    for x = -1, m.w do
      if mget(m, x, y) then
        local open = not mget(m, x + 1, y) or not mget(m, x, y + 1)
        L.blend(img, ox + x, oy + y, (shade and open) and shade or fill)
      elseif outline and (mget(m, x - 1, y) or mget(m, x + 1, y) or mget(m, x, y - 1) or mget(m, x, y + 1)) then
        L.blend(img, ox + x, oy + y, outline)
      end
    end
  end
end

--- Badge treatment (faces, hearts, shields): 1px outline, vertical shade,
--- optional 1px inner rim, a highlight on the inner ring in the top-left wedge.
--- opts = {outline, top, bottom, inner, hi, hi_wedge}
local function render_badge(img, ox, oy, m, o)
  local x0, y0, x1, y1 = bbox(m)
  local cx, cy = (x0 + x1 + 1) / 2, (y0 + y1 + 1) / 2
  for y = y0, y1 do
    local t = (y1 > y0) and (y - y0) / (y1 - y0) or 0
    for x = x0, x1 do
      if mget(m, x, y) then
        if is_edge(m, x, y) then
          L.blend(img, ox + x, oy + y, o.outline)
        elseif o.inner and touches_edge(m, x, y) then
          L.blend(img, ox + x, oy + y, o.inner)
        else
          L.blend(img, ox + x, oy + y, L.mix(o.top, o.bottom, t))
        end
      end
    end
  end
  if o.hi then
    for y = y0, y1 do
      for x = x0, x1 do
        if mget(m, x, y) and not is_edge(m, x, y) and touches_edge(m, x, y) then
          local dx, dy = x + 0.5 - cx, y + 0.5 - cy
          if dx < 0 and dy < 0 and -dy > 0.45 * -dx and -dx > 0.45 * -dy then
            L.blend(img, ox + x, oy + y, o.hi)
          end
        end
      end
    end
  end
end

--- The plate treatment for every log/state/mech badge: one base colour, the
--- outline/top/bottom/highlight derived from it, so a family is one table row.
local INK_DARK, CREAM = hex("#040E18"), hex("#F6EFDF")
local function plate(img, m, base)
  render_badge(img, 0, 0, m, {
    outline = L.mix(base, hex("#060C12"), 0.62),
    top     = L.mix(base, hex("#F9F4E5"), 0.18),
    bottom  = L.mix(base, hex("#060C12"), 0.30),
    hi      = L.mix(base, hex("#F9F4E5"), 0.62),
  })
end

--- Soft outer glow around a mask: 1px ring at a0, 2px ring at a0/2 (lib.lua).
local glow = L.glow_mask

-- ---------------------------------------------------------------- 1. morale faces
-- One 24x24 badge per canon band (Enums.MORALE_BAND_NAMES). The disc colour is
-- Palette.morale_color()'s ramp: DANGER 0-2, CAUTION 3-5, POSITIVE 6-9. Bands
-- 8-9 are the heart of Enums.MORALE_BAND_EMOJI. Features are the reference's
-- dark navy (03 §: "#040E18 eyes + mouth"), never black.

local BAND_NAMES = { "Very Upset", "Upset", "Unhappy", "Annoyed", "Slightly Annoyed",
                     "Content", "Happy", "Quite Happy", "Very Happy", "Loves Their Guild" }
local DANGER, CAUTION, POSITIVE = hex("#F73526"), hex("#FBB62B"), hex("#32C24D")
local FACE_PAL = { d = hex("#040E18"), w = hex("#F6EFDF"), t = hex("#43DBF3"), s = hex("#F6EFDF") }

local EYES  = { {9,8,9,"d"}, {10,8,9,"d"}, {9,14,15,"d"}, {10,14,15,"d"} }
local BROWS = { {7,6,6,"d"}, {8,7,7,"d"}, {7,17,17,"d"}, {8,16,16,"d"} }
local FROWN = { {15,9,14,"d"}, {16,8,8,"d"}, {16,15,15,"d"}, {17,7,7,"d"}, {17,16,16,"d"} }
local SMILE = { {15,8,8,"d"}, {15,15,15,"d"}, {16,9,14,"d"} }
local function cat(...)
  local out = {}
  for _, l in ipairs({ ... }) do for _, s in ipairs(l) do out[#out + 1] = s end end
  return out
end

local FEATURES = {
  -- 0 Very Upset: furrowed brows, shouting mouth with gritted teeth
  cat(BROWS, EYES, { {14,7,16,"d"}, {15,6,7,"d"}, {15,8,8,"w"}, {15,9,9,"d"}, {15,10,10,"w"},
      {15,11,11,"d"}, {15,12,12,"w"}, {15,13,13,"d"}, {15,14,14,"w"}, {15,15,17,"d"},
      {16,7,16,"d"}, {17,8,15,"d"} }),
  -- 1 Upset: furrowed brows, deep frown
  cat(BROWS, EYES, FROWN),
  -- 2 Unhappy: frown, one tear
  cat(EYES, { {15,9,14,"d"}, {16,8,8,"d"}, {16,15,15,"d"}, {11,16,16,"t"}, {12,16,16,"t"} }),
  -- 3 Annoyed: half-lidded eyes, off-centre flat mouth with a down-tick
  { {10,7,9,"d"}, {10,14,16,"d"}, {15,9,13,"d"}, {16,14,14,"d"} },
  -- 4 Slightly Annoyed: neutral
  cat(EYES, { {15,8,15,"d"} }),
  -- 5 Content: slight smile
  cat(EYES, SMILE),
  -- 6 Happy: big open grin
  cat(EYES, { {14,7,16,"d"}, {15,7,7,"d"}, {15,8,15,"w"}, {15,16,16,"d"}, {16,8,15,"d"},
      {17,9,14,"d"}, {18,10,13,"d"} }),
  -- 7 Quite Happy: smiling (arched) eyes
  cat({ {9,8,9,"d"}, {10,7,7,"d"}, {10,10,10,"d"}, {9,14,15,"d"}, {10,13,13,"d"}, {10,16,16,"d"} }, SMILE),
  -- 8 Very Happy: the heart, no features
  {},
  -- 9 Loves Their Guild: heart + sparkles
  { {1,20,20,"s"}, {2,20,20,"s"}, {3,18,22,"s"}, {4,20,20,"s"}, {5,20,20,"s"},
    {14,3,3,"s"}, {15,2,4,"s"}, {16,3,3,"s"} },
}

local HEART = { {2,4,7}, {2,16,19}, {3,2,9}, {3,14,21}, {4,1,10}, {4,13,22} }
rows(HEART, 5, 10, 1, 22)
for i, x0 in ipairs({ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }) do
  HEART[#HEART + 1] = { 10 + i, x0, 23 - x0 }
end

local function band_color(b)
  if b <= 2 then return DANGER elseif b <= 5 then return CAUTION else return POSITIVE end
end

local function face_opts(base)
  return {
    outline = L.mix(base, hex("#060C12"), 0.62),
    top     = L.mix(base, hex("#F9F4E5"), 0.18),
    bottom  = L.mix(base, hex("#060C12"), 0.30),
    hi      = L.mix(base, hex("#F9F4E5"), 0.62),
  }
end

local function draw_face(img, ox, oy, band)
  local base = band_color(band)
  local m = (band >= 8) and mask_spans(24, 24, HEART) or mask_disc(24, 24, 12, 12, 11)
  render_badge(img, ox, oy, m, face_opts(base))
  spans(img, FEATURES[band + 1], FACE_PAL, ox, oy)
end

local function faces_json(size, file)
  local json = { string.format('{\n  "size": [%d, %d],\n  "ramp": {"0-2": "DANGER", "3-5": "CAUTION", "6-9": "POSITIVE"},\n  "frames": [', size, size) }
  for b = 0, 9 do
    local f = (size == 24) and string.format("icons/face_%d.png", b) or file
    json[#json + 1] = string.format('    {"band": %d, "name": "%s", "file": "%s", "x": %d, "y": 0, "w": %d, "h": %d}%s',
      b, BAND_NAMES[b + 1], f, b * size, size, size, b < 9 and "," or "")
  end
  json[#json + 1] = "  ]\n}\n"
  return table.concat(json, "\n")
end

print("faces")
do
  local strip = L.new_sprite(240, 24)
  local simg = L.img(strip)
  for b = 0, 9 do
    local spr = L.new_sprite(24, 24)
    draw_face(L.img(spr), 0, 0, b)
    emit(spr, "face_" .. b, "face", tostring(b))
    draw_face(simg, b * 24, 0, b)
  end
  L.save_ase(strip, "art/src/ui/faces.aseprite")
  L.save_png(strip, "game/assets/ui/faces.png")
  strip:close()
  L.write_text("game/assets/ui/faces.json", faces_json(24, "faces.png"))
  SHEETS[#SHEETS + 1] = '    {"file": "faces.png", "json": "faces.json", "cell": 24, "w": 240, "h": 24}'
end

-- ---------------------------------------------------------------- 1b. faces at 125 / 150 %
-- The same ten faces at the other two text scales (docs/13 §4.4: 100/125/150),
-- authored at native size so W4-PIP can swap a crisp sheet instead of scaling
-- the 24px one: the disc/heart are re-cut at the new radius, the features are
-- the 24-grid spans mapped onto the larger grid (a continuous nearest map, so
-- a 1px mouth stays a line and never breaks).

local function scaled_spans(list, s)
  local out = {}
  for _, e in ipairs(list) do
    local y0, y1 = math.floor(e[1] * s), math.floor((e[1] + 1) * s) - 1
    local x0, x1 = math.floor(e[2] * s), math.floor((e[3] + 1) * s) - 1
    for y = y0, y1 do out[#out + 1] = { y, x0, x1, e[4] } end
  end
  return out
end

local function heart_mask(S)
  local m = L.mask_new(S, S)
  local r = S * 0.24
  L.mask_ellipse(m, S * 0.30, S * 0.36, r, r * 0.92, true)
  L.mask_ellipse(m, S * 0.70, S * 0.36, r, r * 0.92, true)
  L.mask_poly(m, { { S * 0.06, S * 0.40 }, { S * 0.94, S * 0.40 }, { S * 0.5, S * 0.96 } }, true)
  return m
end

local function draw_face_at(img, ox, oy, band, S)
  local base = band_color(band)
  local s = S / 24
  local m = (band >= 8) and heart_mask(S) or mask_disc(S, S, S / 2, S / 2, S / 2 - 1)
  render_badge(img, ox, oy, m, face_opts(base))
  spans(img, scaled_spans(FEATURES[band + 1], s), FACE_PAL, ox, oy)
end

print("faces 30 / 36")
for _, S in ipairs({ 30, 36 }) do
  local strip = L.new_sprite(10 * S, S)
  local simg = L.img(strip)
  for b = 0, 9 do draw_face_at(simg, b * S, 0, b, S) end
  local name = "faces_" .. S
  L.save_ase(strip, SRC .. name .. ".aseprite")   -- under icons/: this unit's source dir
  L.save_png(strip, "game/assets/ui/" .. name .. ".png")
  strip:close()
  L.write_text("game/assets/ui/" .. name .. ".json", faces_json(S, name .. ".png"))
  SHEETS[#SHEETS + 1] = string.format('    {"file": "%s.png", "json": "%s.json", "cell": %d, "w": %d, "h": %d}', name, name, S, 10 * S, S)
end

-- ---------------------------------------------------------------- 2. slot-type glyphs
-- 32x32, a 24px silhouette centred, rendered as a 1px muted grey-blue line with a
-- faint darker interior so it reads as engraved into the empty slot (06 §2 Empty:
-- same chrome, fill NOT darkened - the glyph carries the "empty" read alone).
-- Order = Enums.SLOT_KEYS: main_hand, off_hand, head, chest, legs, feet, trinket.

local GLYPH_LINE = hex("#5F7284")
local GLYPH_FILL = hex("#18222CA0")

local function render_glyph(img, ox, oy, m, details)
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if mget(m, x, y) then
        L.blend(img, ox + x, oy + y, is_edge(m, x, y) and GLYPH_LINE or GLYPH_FILL)
      end
    end
  end
  if details then spans(img, details, { ["="] = GLYPH_LINE }, ox, oy) end
end

local GLYPHS = {}

-- main hand: a sword, point up
GLYPHS.main_hand = { sil = rows(rows({ {0,11,12} }, 1, 13, 10, 13), 16, 19, 10, 13),
                     det = rows({}, 2, 12, 11, 11, "=") }
rows(GLYPHS.main_hand.sil, 14, 15, 5, 18); rows(GLYPHS.main_hand.sil, 20, 21, 9, 14)

-- off hand: a heater shield with a cross
GLYPHS.off_hand = { sil = rows({ {0,4,19} }, 1, 10, 3, 20),
                    det = rows({ {6,5,18,"="} }, 2, 15, 11, 12, "=") }
do
  local s = GLYPHS.off_hand.sil
  for i, x0 in ipairs({ 4, 4, 5, 6, 7, 8, 9, 10, 11 }) do s[#s + 1] = { 10 + i, x0, 23 - x0 } end
end

-- head: a great helm with eye slits and a nose bar
GLYPHS.head = { sil = rows({ {2,8,15}, {3,6,17}, {4,5,18}, {5,4,19}, {6,4,19} }, 7, 16, 3, 20),
                det = rows({ {10,6,9,"="}, {10,14,17,"="} }, 10, 14, 11, 12, "=") }
do
  local s = GLYPHS.head.sil
  for _, r in ipairs({ {17,3,8}, {17,15,20}, {18,3,8}, {18,15,20}, {19,4,7}, {19,16,19} }) do s[#s + 1] = r end
end

-- chest: a breastplate, neck hole at the top, centre seam
GLYPHS.chest = { sil = rows({ {2,2,8}, {2,15,21}, {3,1,9}, {3,14,22} }, 4, 7, 1, 22),
                 det = rows({}, 7, 17, 11, 12, "=") }
do
  local s = GLYPHS.chest.sil
  s[#s + 1] = { 8, 2, 21 }; s[#s + 1] = { 9, 3, 20 }
  rows(s, 10, 17, 4, 19); s[#s + 1] = { 18, 5, 18 }; s[#s + 1] = { 19, 6, 17 }
end

-- legs: greaves, belt line
GLYPHS.legs = { sil = rows(rows(rows({}, 1, 7, 5, 18), 8, 21, 5, 10), 8, 21, 13, 18),
                det = { {3,6,17,"="} } }

-- feet: one boot, toe left, sole and strap lines
GLYPHS.feet = { sil = rows({ {13,11,19}, {14,9,19}, {15,7,19}, {16,5,19}, {20,5,18} }, 2, 12, 12, 19),
                det = { {18,5,18,"="}, {8,13,18,"="} } }
rows(GLYPHS.feet.sil, 17, 19, 4, 19)

-- trinket: a ring with a gem set on top
GLYPHS.trinket = { sil = { {0,11,12}, {1,10,13}, {2,9,14}, {3,9,14}, {4,7,16}, {5,6,17},
  {6,5,9}, {6,14,18}, {7,4,7}, {7,16,19}, {8,4,6}, {8,17,19},
  {14,4,6}, {14,17,19}, {15,4,7}, {15,16,19}, {16,5,9}, {16,14,18}, {17,6,17}, {18,7,16}, {19,9,14} },
  det = { {3,9,14,"="} } }
rows(GLYPHS.trinket.sil, 9, 13, 3, 5); rows(GLYPHS.trinket.sil, 9, 13, 18, 20)

print("slot glyphs")
for _, key in ipairs({ "main_hand", "off_hand", "head", "chest", "legs", "feet", "trinket" }) do
  local g = GLYPHS[key]
  local spr = L.new_sprite(32, 32)
  render_glyph(L.img(spr), 4, 4, mask_spans(24, 24, g.sil), g.det)
  emit(spr, "slot_" .. key, "slot", key)
end

-- ---------------------------------------------------------------- 2b. provisions
-- Full-colour 32x32 item icons for the consumables the shop sells (sim/core/
-- Consumables.gd keys) plus a generic sack for anything without art yet.

local ITEM_PAL = {
  o = hex("#1A1410"),                     -- outline
  k = hex("#8B5A2B"), K = hex("#5A3A1C"), -- cork
  G = hex("#3F5161"), g = hex("#6C8299"), H = hex("#DCE8F2"), -- glass, glass light, glint
  r = hex("#C9302C"), R = hex("#F05A4E"), q = hex("#8E1E1C"), -- red liquid
  b = hex("#1F7FC0"), B = hex("#43DBF3"),                     -- blue liquid
  y = hex("#D9A441"), Y = hex("#F4C066"), u = hex("#8C5A1E"), -- gold metal
  w = hex("#E8DCC4"), d = hex("#040E18"),                     -- label, ink
  s = hex("#8A6A3E"), S = hex("#A98550"), z = hex("#5C4529"), -- burlap
  -- W1-ICONS additions: stone, steel, meat, bone, iron, steam
  t = hex("#8E959D"), T = hex("#C6CCD4"), n = hex("#5A6470"),
  m = hex("#A8642E"), M = hex("#C98A48"), c = hex("#6E3E1A"),
  e = hex("#F6EFDF"), i = hex("#3F434B"), I = hex("#6B7078"), v = hex("#F6EFDF80"),
}

local ITEMS = {}

-- minor healing potion: round flask, red
do
  local p = { {1,10,13,"k"}, {2,10,13,"k"}, {2,10,10,"K"} }
  for y = 3, 6 do p[#p + 1] = { y, 9, 9, "o" }; p[#p + 1] = { y, 10, 13, "G" }; p[#p + 1] = { y, 14, 14, "o" } end
  p[#p + 1] = { 4, 10, 10, "H" }; p[#p + 1] = { 5, 10, 10, "H" }
  for i, x0 in ipairs({ 8, 7, 6, 5, 4 }) do
    local y = 6 + i
    p[#p + 1] = { y, x0, x0, "o" }; p[#p + 1] = { y, x0 + 1, 23 - x0 - 1, "G" }; p[#p + 1] = { y, 23 - x0, 23 - x0, "o" }
    if y >= 9 then p[#p + 1] = { y, x0 + 2, x0 + 2, "H" } end
  end
  p[#p + 1] = { 12, 4, 4, "o" }; p[#p + 1] = { 12, 5, 5, "G" }; p[#p + 1] = { 12, 6, 17, "R" }; p[#p + 1] = { 12, 18, 18, "G" }; p[#p + 1] = { 12, 19, 19, "o" }
  for y = 13, 17 do
    p[#p + 1] = { y, 3, 3, "o" }; p[#p + 1] = { y, 4, 4, "G" }; p[#p + 1] = { y, 5, 18, "r" }; p[#p + 1] = { y, 19, 19, "G" }; p[#p + 1] = { y, 20, 20, "o" }
  end
  p[#p + 1] = { 13, 6, 6, "R" }; p[#p + 1] = { 14, 6, 6, "R" }; p[#p + 1] = { 17, 5, 18, "q" }
  p[#p + 1] = { 18, 4, 4, "o" }; p[#p + 1] = { 18, 5, 5, "G" }; p[#p + 1] = { 18, 6, 17, "q" }; p[#p + 1] = { 18, 18, 18, "G" }; p[#p + 1] = { 18, 19, 19, "o" }
  p[#p + 1] = { 19, 4, 4, "o" }; p[#p + 1] = { 19, 5, 6, "G" }; p[#p + 1] = { 19, 7, 16, "q" }; p[#p + 1] = { 19, 17, 18, "G" }; p[#p + 1] = { 19, 19, 19, "o" }
  p[#p + 1] = { 20, 5, 5, "o" }; p[#p + 1] = { 20, 6, 8, "G" }; p[#p + 1] = { 20, 9, 14, "q" }; p[#p + 1] = { 20, 15, 17, "G" }; p[#p + 1] = { 20, 18, 18, "o" }
  p[#p + 1] = { 21, 6, 6, "o" }; p[#p + 1] = { 21, 7, 16, "G" }; p[#p + 1] = { 21, 17, 17, "o" }; p[#p + 1] = { 21, 8, 8, "g" }
  p[#p + 1] = { 22, 7, 16, "o" }
  ITEMS.minor_healing_potion = p
end

-- potion of steady hands: tall square vial, blue, a label with one steady line
do
  local p = { {0,9,14,"k"}, {1,9,14,"k"}, {1,9,9,"K"} }
  for y = 2, 4 do p[#p + 1] = { y, 10, 10, "o" }; p[#p + 1] = { y, 11, 12, "G" }; p[#p + 1] = { y, 13, 13, "o" } end
  p[#p + 1] = { 5, 8, 8, "o" }; p[#p + 1] = { 5, 9, 14, "G" }; p[#p + 1] = { 5, 15, 15, "o" }
  p[#p + 1] = { 6, 6, 6, "o" }; p[#p + 1] = { 6, 7, 16, "G" }; p[#p + 1] = { 6, 17, 17, "o" }
  for y = 7, 8 do p[#p + 1] = { y, 5, 5, "o" }; p[#p + 1] = { y, 6, 17, "G" }; p[#p + 1] = { y, 18, 18, "o" }; p[#p + 1] = { y, 7, 7, "H" } end
  for y = 9, 19 do
    p[#p + 1] = { y, 5, 5, "o" }; p[#p + 1] = { y, 6, 6, "G" }; p[#p + 1] = { y, 7, 16, "b" }; p[#p + 1] = { y, 17, 17, "G" }; p[#p + 1] = { y, 18, 18, "o" }
  end
  p[#p + 1] = { 9, 7, 16, "B" }; p[#p + 1] = { 10, 7, 7, "B" }; p[#p + 1] = { 11, 7, 7, "B" }
  for y = 12, 14 do p[#p + 1] = { y, 8, 15, "w" } end
  p[#p + 1] = { 13, 9, 14, "d" }
  p[#p + 1] = { 20, 6, 6, "o" }; p[#p + 1] = { 20, 7, 7, "G" }; p[#p + 1] = { 20, 8, 15, "b" }; p[#p + 1] = { 20, 16, 16, "G" }; p[#p + 1] = { 20, 17, 17, "o" }
  p[#p + 1] = { 21, 7, 16, "o" }
  ITEMS.potion_of_steady_hands = p
end

-- rally flask: a gold hip flask with an embossed diamond
do
  local p = { {1,10,13,"o"}, {2,10,10,"o"}, {2,11,12,"y"}, {2,13,13,"o"}, {3,9,14,"o"},
              {4,7,8,"o"}, {4,9,14,"y"}, {4,15,16,"o"},
              {5,6,6,"o"}, {5,7,16,"Y"}, {5,17,17,"o"} }
  for y = 6, 18 do
    p[#p + 1] = { y, 5, 5, "o" }; p[#p + 1] = { y, 6, 17, "y" }; p[#p + 1] = { y, 18, 18, "o" }; p[#p + 1] = { y, 17, 17, "u" }
  end
  for y = 6, 9 do p[#p + 1] = { y, 7, 7, "Y" } end
  for _, s in ipairs({ {9,11,12}, {10,10,10}, {10,13,13}, {11,9,9}, {11,14,14}, {12,8,8}, {12,15,15},
                       {13,9,9}, {13,14,14}, {14,10,10}, {14,13,13}, {15,11,12} }) do
    p[#p + 1] = { s[1], s[2], s[3], "u" }
  end
  p[#p + 1] = { 19, 5, 5, "o" }; p[#p + 1] = { 19, 6, 17, "u" }; p[#p + 1] = { 19, 18, 18, "o" }
  p[#p + 1] = { 20, 6, 6, "o" }; p[#p + 1] = { 20, 7, 16, "u" }; p[#p + 1] = { 20, 17, 17, "o" }
  p[#p + 1] = { 21, 7, 16, "o" }
  ITEMS.rally_flask = p
end

-- unknown item: a tied burlap sack with a question mark
do
  local p = { {2,10,13,"o"}, {3,9,9,"o"}, {3,10,13,"S"}, {3,14,14,"o"}, {4,9,9,"o"}, {4,10,13,"z"}, {4,14,14,"o"} }
  for i, x0 in ipairs({ 8, 7, 6, 5 }) do
    local y = 4 + i
    p[#p + 1] = { y, x0, x0, "o" }; p[#p + 1] = { y, x0 + 1, 23 - x0 - 1, "s" }; p[#p + 1] = { y, 23 - x0, 23 - x0, "o" }
  end
  for y = 9, 18 do
    p[#p + 1] = { y, 4, 4, "o" }; p[#p + 1] = { y, 5, 18, "s" }; p[#p + 1] = { y, 19, 19, "o" }
    p[#p + 1] = { y, 5, 5, "S" }; p[#p + 1] = { y, 18, 18, "z" }
  end
  p[#p + 1] = { 19, 5, 5, "o" }; p[#p + 1] = { 19, 6, 17, "z" }; p[#p + 1] = { 19, 18, 18, "o" }
  p[#p + 1] = { 20, 6, 17, "o" }
  for _, s in ipairs({ {9,10,13}, {10,9,9}, {10,14,14}, {11,14,14}, {12,13,13}, {13,11,12}, {14,11,12}, {16,11,12} }) do
    p[#p + 1] = { s[1], s[2], s[3], "w" }
  end
  ITEMS.unknown = p
end

print("provisions")
for _, key in ipairs({ "minor_healing_potion", "potion_of_steady_hands", "rally_flask", "unknown" }) do
  local spr = L.new_sprite(32, 32)
  spans(L.img(spr), ITEMS[key], ITEM_PAL, 4, 4)
  emit(spr, "item_" .. key, "item", key)
end

-- the three SKUs m4t-03 found missing (sim/core/Consumables.gd keys), same
-- construction: ink drawn into a 24x24 box offset (4,4), outline `o`.

-- whetstone kit: a grey hone on a leather strop, a small oil flask top-right
do
  local p = {}
  -- oil flask (x 17..22, y 0..9)
  p[#p + 1] = { 0, 19, 20, "k" }; p[#p + 1] = { 1, 19, 20, "k" }; p[#p + 1] = { 1, 19, 19, "K" }
  p[#p + 1] = { 2, 18, 18, "o" }; p[#p + 1] = { 2, 19, 20, "G" }; p[#p + 1] = { 2, 21, 21, "o" }
  p[#p + 1] = { 3, 17, 17, "o" }; p[#p + 1] = { 3, 18, 21, "G" }; p[#p + 1] = { 3, 22, 22, "o" }
  for y = 4, 8 do p[#p + 1] = { y, 17, 17, "o" }; p[#p + 1] = { y, 18, 18, "G" }; p[#p + 1] = { y, 19, 21, "y" }; p[#p + 1] = { y, 22, 22, "o" } end
  p[#p + 1] = { 4, 18, 18, "H" }; p[#p + 1] = { 5, 18, 18, "H" }
  p[#p + 1] = { 9, 18, 21, "o" }
  -- strop (leather band, y 15..20)
  p[#p + 1] = { 15, 1, 22, "o" }
  for y = 16, 19 do p[#p + 1] = { y, 0, 0, "o" }; p[#p + 1] = { y, 1, 22, "k" }; p[#p + 1] = { y, 23, 23, "o" } end
  p[#p + 1] = { 16, 1, 22, "s" }; p[#p + 1] = { 19, 1, 22, "K" }
  p[#p + 1] = { 20, 1, 22, "o" }
  -- hone (x 2..15, y 8..14): light top, mid body, dark base
  p[#p + 1] = { 7, 3, 14, "o" }
  p[#p + 1] = { 8, 2, 2, "o" }; p[#p + 1] = { 8, 3, 14, "T" }; p[#p + 1] = { 8, 15, 15, "o" }
  for y = 9, 12 do p[#p + 1] = { y, 2, 2, "o" }; p[#p + 1] = { y, 3, 14, "t" }; p[#p + 1] = { y, 15, 15, "o" } end
  p[#p + 1] = { 9, 4, 5, "T" }
  p[#p + 1] = { 13, 2, 2, "o" }; p[#p + 1] = { 13, 3, 14, "n" }; p[#p + 1] = { 13, 15, 15, "o" }
  p[#p + 1] = { 14, 3, 14, "o" }
  -- a spark on the hone's edge
  p[#p + 1] = { 6, 13, 13, "e" }; p[#p + 1] = { 5, 14, 14, "e" }
  ITEMS.whetstone_kit = p
end

-- mana draught: a round-bellied blue bottle, a cream band label
do
  local p = { {0,10,13,"k"}, {1,10,13,"k"}, {1,10,10,"K"} }
  for y = 2, 5 do p[#p + 1] = { y, 9, 9, "o" }; p[#p + 1] = { y, 10, 13, "G" }; p[#p + 1] = { y, 14, 14, "o" } end
  p[#p + 1] = { 3, 10, 10, "H" }; p[#p + 1] = { 4, 10, 10, "H" }
  local belly = { {6,8,15}, {7,6,17}, {8,5,18}, {9,4,19}, {10,3,20}, {11,3,20}, {12,2,21}, {13,2,21}, {14,2,21},
                  {15,2,21}, {16,2,21}, {17,3,20}, {18,3,20}, {19,4,19}, {20,5,18}, {21,6,17}, {22,8,15} }
  for _, r in ipairs(belly) do
    p[#p + 1] = { r[1], r[2], r[2], "o" }; p[#p + 1] = { r[1], r[3], r[3], "o" }
    if r[3] - r[2] >= 2 then
      local key = (r[1] >= 11) and "b" or "G"
      p[#p + 1] = { r[1], r[2] + 1, r[3] - 1, key }
      if r[1] >= 11 then p[#p + 1] = { r[1], r[2] + 1, r[2] + 1, "G" }; p[#p + 1] = { r[1], r[3] - 1, r[3] - 1, "G" } end
    end
  end
  p[#p + 1] = { 11, 4, 19, "B" }
  for y = 12, 14 do p[#p + 1] = { y, 5, 5, "B" } end
  for y = 8, 10 do p[#p + 1] = { y, 6, 7, "H" } end
  for y = 15, 17 do p[#p + 1] = { y, 8, 15, "w" } end
  p[#p + 1] = { 16, 10, 13, "d" }
  ITEMS.mana_draught = p
end

-- guild feast: a roast on a platter, one bone, steam
do
  local p = {}
  -- steam (translucent cream)
  for _, s in ipairs({ {0,6,6}, {1,7,7}, {2,6,6}, {0,12,12}, {1,13,13}, {2,12,12}, {3,13,13}, {1,17,17}, {2,18,18}, {3,17,17} }) do
    p[#p + 1] = { s[1], s[2], s[3], "v" }
  end
  -- roast (x 3..16, y 6..16), rounded
  local roast = { {6,7,12}, {7,5,14}, {8,4,15}, {9,3,16}, {10,3,16}, {11,3,16}, {12,3,16}, {13,3,16}, {14,4,15}, {15,5,14}, {16,7,12} }
  for _, r in ipairs(roast) do
    p[#p + 1] = { r[1], r[2], r[2], "o" }; p[#p + 1] = { r[1], r[3], r[3], "o" }
    if r[3] - r[2] >= 2 then p[#p + 1] = { r[1], r[2] + 1, r[3] - 1, (r[1] >= 14) and "c" or "m" } end
  end
  p[#p + 1] = { 7, 7, 10, "M" }; p[#p + 1] = { 8, 6, 8, "M" }; p[#p + 1] = { 9, 5, 6, "M" }
  -- bone (from the roast up-right)
  for _, s in ipairs({ {12,16,17}, {11,17,18}, {10,18,19}, {9,19,20}, {8,20,21} }) do p[#p + 1] = { s[1], s[2], s[3], "e" } end
  p[#p + 1] = { 7, 20, 20, "e" }; p[#p + 1] = { 7, 22, 22, "e" }; p[#p + 1] = { 6, 21, 22, "e" }; p[#p + 1] = { 8, 22, 22, "e" }
  p[#p + 1] = { 13, 15, 16, "o" }
  -- platter (an ellipse under everything, y 17..22)
  local plat = { {17,3,20}, {18,1,22}, {19,0,23}, {20,0,23}, {21,1,22}, {22,3,20} }
  for _, r in ipairs(plat) do
    p[#p + 1] = { r[1], r[2], r[2], "o" }; p[#p + 1] = { r[1], r[3], r[3], "o" }
    p[#p + 1] = { r[1], r[2] + 1, r[3] - 1, (r[1] <= 19) and "T" or "t" }
  end
  p[#p + 1] = { 22, 4, 19, "o" }
  ITEMS.guild_feast = p
end

for _, key in ipairs({ "whetstone_kit", "mana_draught", "guild_feast" }) do
  local spr = L.new_sprite(32, 32)
  spans(L.img(spr), ITEMS[key], ITEM_PAL, 4, 4)
  emit_grid(spr, "item_" .. key, "item", key)
end

-- ---------------------------------------------------------------- 3. rank sigils
-- 28x28 for Enums.REPUTATION_KEYS (KIT-16 re-author). One shield silhouette
-- with a 1px CREAM rim (>= 3:1 against the chip's #020B12 at every rank —
-- test_icons.gd pins it), the metal climbing iron -> bronze -> steel ->
-- silver -> gold, and a device per rank: blank shield, chevron, two chevrons,
-- star, laurel, crowned skull. Replaces the reference sun on the day chip
-- (00 §2.5). Same names, same 28px cell: Frame.gd loads rank_<name> by path.

local SHIELD = rows({ {2,5,22} }, 3, 14, 4, 23)
for i, x0 in ipairs({ 5, 6, 7, 8, 9, 10, 11, 12, 13 }) do SHIELD[#SHIELD + 1] = { 14 + i, x0, 27 - x0 } end

local CHEVRON = { {8,13,14}, {9,12,13}, {9,14,15}, {10,11,12}, {10,15,16}, {11,10,11}, {11,16,17} }
local function shifted(list, dy)
  local out = {}
  for _, s in ipairs(list) do out[#out + 1] = { s[1] + dy, s[2], s[3] } end
  return out
end
local STAR    = { {6,13,14}, {7,13,14}, {8,13,14}, {9,12,15}, {10,9,18}, {11,9,18}, {12,12,15}, {13,13,14}, {14,13,14}, {15,13,14} }
local CROWN   = { {5,9,9}, {5,13,14}, {5,18,18}, {6,8,10}, {6,12,15}, {6,17,19}, {7,8,19}, {8,8,19} }
local SKULL   = { {9,11,16}, {10,10,17}, {11,9,18}, {12,9,18}, {13,9,18}, {14,10,17}, {15,11,16}, {16,11,16}, {17,12,12}, {17,14,14}, {17,16,16} }
local SKULL_HOLES = { {12,11,12}, {13,11,12}, {12,15,16}, {13,15,16}, {15,13,14} }
-- the laurel: two arcs of leaves inside the shield
local function laurel(img, c)
  L.arc(img, 13, 13, 7, 120, 250, c, 1)
  L.arc(img, 14, 13, 7, 290, 420, c, 1)
  for _, s in ipairs({ {8,8,8}, {10,6,6}, {12,5,5}, {14,5,5}, {16,6,6}, {18,7,7}, {20,9,9},
                       {8,19,19}, {10,21,21}, {12,22,22}, {14,22,22}, {16,21,21}, {18,20,20}, {20,18,18} }) do
    sp(img, { s }, c)
  end
end

local RANKS = {
  { key = "unknown",     rim = "#C9C6C0", rim_dark = "#3E434A", top = "#3A4049", bot = "#23272D" },
  { key = "known",       rim = "#D9C7B0", rim_dark = "#5F4D3E", top = "#4A3526", bot = "#2B1E16",
    device = { { CHEVRON, "#D9B08C" } } },
  { key = "respected",   rim = "#DCE8F2", rim_dark = "#3D5F79", top = "#1C4A6C", bot = "#0F2A40",
    device = { { shifted(CHEVRON, -2), "#DCE8F2" }, { shifted(CHEVRON, 3), "#DCE8F2" } } },
  { key = "established", rim = "#E8E4DA", rim_dark = "#7B838E", top = "#4B535E", bot = "#2C323A",
    device = { { STAR, "#F6EFDF" } } },
  { key = "renowned",    rim = "#F6E3B0", rim_dark = "#9C6A22", top = "#7A4E1C", bot = "#43290E",
    laurel = "#9CC47A", device = { { { {11,13,14}, {12,12,15}, {13,11,16}, {14,12,15}, {15,13,14} }, "#F9F4E5" } } },
  { key = "legendary",   rim = "#FCD98A", rim_dark = "#B07A2A", top = "#8A5A20", bot = "#4A2E10",
    device = { { SKULL, "#F6EFDF" }, { SKULL_HOLES, "#4A2E10" }, { CROWN, "#FCB85D" } }, glow = "#ECA742" },
}

print("rank sigils")
for _, r in ipairs(RANKS) do
  local spr = L.new_sprite(28, 28)
  local img = L.img(spr)
  local m = mask_spans(28, 28, SHIELD)
  if r.glow then glow(img, 0, 0, m, hex(r.glow), 90) end
  render_badge(img, 0, 0, m, {
    outline = hex(r.rim), inner = hex(r.rim_dark),
    top = hex(r.top), bottom = hex(r.bot),
    hi = L.mix(hex(r.rim), hex("#F9F4E5"), 0.5),
  })
  if r.laurel then laurel(img, hex(r.laurel)) end
  for _, e in ipairs(r.device or {}) do sp(img, e[1], hex(e[2])) end
  emit(spr, "rank_" .. r.key, "rank", r.key)
end

-- ---------------------------------------------------------------- 5. arrows, cog, fast-forward
-- Cream (#F0E3D2 = TEXT_TITLE family) chevrons, 2px stroke. Cog matches the
-- existing 16px cog's #CAC7C6 grey; it is rasterised with 4x4 coverage so its
-- edges soften the way the sliced reference icons do.

local CREAM_ARROW = hex("#F0E3D2")

-- a chevron pointing left: apex column `ax`, arm length `n`, rows y0.. ; 2px thick
local function chevron_left(list, ax, y0, n)
  for i = 0, n - 1 do
    list[#list + 1] = { y0 + i, ax + (n - 1 - i), ax + (n - 1 - i) + 1 }
    list[#list + 1] = { y0 + n + i, ax + i, ax + i + 1 }
  end
  return list
end

print("arrows")
do
  local left = chevron_left({}, 5, 2, 6)
  local spr = L.new_sprite(16, 16)
  spans(L.img(spr), left, { ["#"] = CREAM_ARROW })
  emit(spr, "arrow_left", "arrow", "left")
  local right = {}
  for _, s in ipairs(left) do right[#right + 1] = { s[1], 15 - s[3], 15 - s[2] } end
  spr = L.new_sprite(16, 16)
  spans(L.img(spr), right, { ["#"] = CREAM_ARROW })
  emit(spr, "arrow_right", "arrow", "right")

  -- fast forward: two right-pointing chevrons, 12 tall, centred in 24
  local ff = {}
  for _, ax in ipairs({ 4, 13 }) do
    local l = chevron_left({}, 0, 6, 6)
    for _, s in ipairs(l) do ff[#ff + 1] = { s[1], ax + (6 - s[3]), ax + (6 - s[2]) } end
  end
  spr = L.new_sprite(24, 24)
  spans(L.img(spr), ff, { ["#"] = CREAM_ARROW })
  emit(spr, "fast_forward_24", "control", "fast_forward_24")

  -- COMBAT-19: up / down, the left chevron transposed (apex row 5, 12 wide)
  local up = mask_transpose(mask_spans(16, 16, left))
  spr = L.new_sprite(16, 16)
  L.mask_paint(L.img(spr), up, CREAM_ARROW)
  emit_grid(spr, "arrow_up", "arrow", "up")
  spr = L.new_sprite(16, 16)
  L.mask_paint(L.img(spr), mask_flip_y(up), CREAM_ARROW)
  emit_grid(spr, "arrow_down", "arrow", "down")
end

print("cog")
do
  local spr = L.new_sprite(24, 24)
  local img = L.img(spr)
  local cr, cg, cb = L.chan(hex("#CAC7C6"))
  local N, half = 8, math.rad(11.25)
  local function inside(px, py)
    local dx, dy = px - 12, py - 12
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 3.4 then return false end
    if d <= 8.0 then return true end
    if d > 11.0 then return false end
    local a = math.atan(dy, dx)
    local step = 2 * math.pi / N
    local off = ((a % step) + step) % step
    if off > step / 2 then off = step - off end
    return off <= half
  end
  for y = 0, 23 do
    for x = 0, 23 do
      local hits = 0
      for sy = 0, 3 do for sx = 0, 3 do
        if inside(x + (sx + 0.5) / 4, y + (sy + 0.5) / 4) then hits = hits + 1 end
      end end
      if hits > 0 then L.px(img, x, y, L.rgba(cr, cg, cb, math.floor(255 * hits / 16 + 0.5))) end
    end
  end
  emit(spr, "cog_24", "control", "cog_24")
end

-- ================================================================ THE GRID (W1-ICONS)

-- ---------------------------------------------------------------- 6. class glyphs 16x16
-- Two-tone (#7E6B6A dark ring outside, #A3B9C8 light body), docs/12 §5.1's
-- identifying silhouettes. The warrior is crossed swords by default and a
-- heater shield beside it (Icons.WARRIOR_GLYPH, Q18).

local CLASS_DARK, CLASS_LIGHT = hex("#7E6B6A"), hex("#A3B9C8")

local CLASS_DRAW = {}
-- warrior: crossed swords, hilts at the bottom
CLASS_DRAW.warrior = function(im, c)
  L.line(im, 12, 3, 5, 10, c, 1); L.line(im, 3, 9, 6, 12, c, 1); L.line(im, 4, 11, 2, 13, c, 1)
  L.line(im, 3, 3, 10, 10, c, 1); L.line(im, 12, 9, 9, 12, c, 1); L.line(im, 11, 11, 13, 13, c, 1)
end
-- warrior_shield: a heater shield (the docs/12 §5.1 reading)
CLASS_DRAW.warrior_shield = function(im, c)
  sp(im, rows({ {2,4,11} }, 3, 8, 3, 12), c)
  sp(im, { {9,3,12}, {10,4,11}, {11,5,10}, {12,6,9}, {13,7,8} }, c)
end
-- monk: a fist, thumb on the left
CLASS_DRAW.monk = function(im, c)
  sp(im, rows({ {4,5,6}, {4,8,9}, {4,11,12} }, 5, 12, 4, 12), c)
  sp(im, { {7,3,3}, {8,3,3}, {9,3,3} }, c)
end
-- rogue: one dagger, up-right
CLASS_DRAW.rogue = function(im, c)
  L.line(im, 12, 3, 7, 8, c, 3); L.line(im, 4, 8, 8, 12, c, 2); L.line(im, 5, 11, 2, 14, c, 2)
end
-- cleric: a flared cross
CLASS_DRAW.cleric = function(im, c)
  sp(im, rows({ {2,6,9}, {13,6,9} }, 3, 12, 7, 8), c)
  sp(im, rows({}, 5, 6, 3, 12), c); sp(im, { {4,3,3}, {7,3,3}, {4,12,12}, {7,12,12} }, c)
end
-- druid: a leaf with a midrib
CLASS_DRAW.druid = function(im, c)
  L.poly_fill(im, { { 2, 13 }, { 4, 8 }, { 8, 4 }, { 13, 2 }, { 12, 7 }, { 8, 12 }, { 4, 14 } }, c)
end
-- shaman: a carved totem with two wings
CLASS_DRAW.shaman = function(im, c)
  sp(im, rows({}, 2, 13, 5, 10), c)
  sp(im, { {3,3,4}, {4,3,3}, {3,11,12}, {4,12,12} }, c)
end
-- bard: a lute
CLASS_DRAW.bard = function(im, c)
  L.ellipse_fill(im, 6, 10.5, 4.2, 3.6, c); L.line(im, 8, 8, 13, 3, c, 2); sp(im, { {2,12,13}, {3,13,13} }, c)
end
-- mage: a floating orb, three sparks
CLASS_DRAW.mage = function(im, c)
  L.ellipse_fill(im, 8, 8.5, 4.6, 4.6, c)
  sp(im, { {1,12,12}, {2,11,13}, {3,12,12}, {3,2,2}, {4,1,3}, {5,2,2}, {13,12,12}, {14,11,13}, {15,12,12} }, c)
end
-- wizard: the pointed hat with a brim
CLASS_DRAW.wizard = function(im, c)
  L.poly_fill(im, { { 8.5, 1 }, { 12.5, 11 }, { 4.5, 11 } }, c); sp(im, rows({}, 11, 12, 2, 13), c)
end

local CLASS_DETAIL = {
  warrior_shield = { {4,7,8}, {5,7,8}, {6,4,11}, {7,7,8}, {8,7,8}, {9,7,8}, {10,7,8}, {11,7,8} },
  monk = { {5,7,7}, {6,7,7}, {7,7,7}, {5,10,10}, {6,10,10}, {7,10,10} },
  shaman = { {5,5,10}, {9,5,10}, {3,6,6}, {3,9,9} },
  bard = { {10,6,6}, {11,6,6} },
  mage = { {6,6,7}, {7,5,5}, {8,5,5} },
  wizard = { {9,5,11}, {10,5,11} },
  druid = { {12,3,3}, {11,4,4}, {10,5,5}, {9,6,6}, {8,7,7}, {7,8,8}, {6,9,9}, {5,10,10}, {4,11,11} },
}

print("class glyphs")
for _, key in ipairs({ "warrior", "warrior_shield", "monk", "rogue", "cleric", "druid", "shaman", "bard", "mage", "wizard" }) do
  local spr = L.new_sprite(16, 16)
  local img = L.img(spr)
  sprite(img, drawn_mask(16, 16, CLASS_DRAW[key]), CLASS_LIGHT, nil, CLASS_DARK)
  if CLASS_DETAIL[key] then sp(img, CLASS_DETAIL[key], CLASS_DARK) end
  emit_grid(spr, "class_" .. key, "class", key)
end

-- ---------------------------------------------------------------- 7. emotes 16x16
-- The A1-S8 outline style: a cream bubble (ACCENT_BUBBLE) with a 1px ink
-- outline (TEXT_ON_BUBBLE) and a short tail bottom-left, one mark inside.
-- SceneStage's `[x, y, "<icon>"]` bubble form and Widgets.speech_bubble get
-- these through Icons.at("emote", kind).

local BUBBLE_FILL, BUBBLE_INK = hex("#FAE1B9"), hex("#2A1F14")
local EMOTE_PAL = {
  i = BUBBLE_INK, r = hex("#D03E37"), R = hex("#F05A4E"), b = hex("#1F7FC0"), B = hex("#43DBF3"),
  y = hex("#D9A441"), u = hex("#8C5A1E"), w = hex("#F6EFDF"),
}
local EMOTES = {
  dots    = { {6,3,4,"i"}, {7,3,4,"i"}, {6,7,8,"i"}, {7,7,8,"i"}, {6,11,12,"i"}, {7,11,12,"i"} },
  exclaim = { {3,7,8,"r"}, {4,7,8,"r"}, {5,7,8,"r"}, {6,7,8,"r"}, {8,7,8,"r"}, {9,7,8,"r"}, {3,7,7,"R"}, {4,7,7,"R"} },
  question = { {3,6,9,"i"}, {4,5,5,"i"}, {4,10,10,"i"}, {5,10,10,"i"}, {6,9,9,"i"}, {7,8,8,"i"}, {9,8,8,"i"} },
  heart   = { {3,4,5,"r"}, {3,8,9,"r"}, {4,3,10,"r"}, {5,3,10,"r"}, {6,4,9,"r"}, {7,5,8,"r"}, {8,6,7,"r"}, {4,4,4,"R"}, {5,4,4,"R"} },
  zzz     = { {3,7,11,"i"}, {4,10,10,"i"}, {5,9,9,"i"}, {6,8,8,"i"}, {7,7,11,"i"}, {5,3,5,"i"}, {6,4,4,"i"}, {7,3,5,"i"} },
  sweat   = { {3,7,8,"b"}, {4,6,9,"b"}, {5,6,9,"b"}, {6,5,10,"b"}, {7,5,10,"b"}, {8,6,9,"b"}, {9,7,8,"b"}, {5,6,6,"B"}, {6,6,6,"B"} },
  skull   = { {3,5,10,"i"}, {4,4,11,"i"}, {5,4,11,"i"}, {6,4,4,"i"}, {6,7,8,"i"}, {6,11,11,"i"}, {7,4,4,"i"}, {7,7,8,"i"}, {7,11,11,"i"},
              {8,5,10,"i"}, {9,5,5,"i"}, {9,7,7,"i"}, {9,9,9,"i"} },
  mug     = { {3,4,9,"w"}, {2,5,5,"w"}, {2,8,8,"w"}, {4,4,9,"y"}, {5,4,9,"y"}, {6,4,9,"y"}, {7,4,9,"y"}, {8,4,9,"u"}, {9,4,9,"u"},
              {4,10,10,"u"}, {5,11,11,"u"}, {6,11,11,"u"}, {7,11,11,"u"}, {8,10,10,"u"}, {5,5,5,"w"}, {6,5,5,"w"} },
  note    = { {3,9,9,"i"}, {4,9,9,"i"}, {5,9,9,"i"}, {6,9,9,"i"}, {7,9,9,"i"}, {8,9,9,"i"}, {3,10,10,"i"}, {4,11,11,"i"}, {5,11,11,"i"},
              {8,6,8,"i"}, {9,5,9,"i"}, {10,6,8,"i"} },
  anger   = { {2,7,8,"r"}, {3,7,8,"r"}, {4,7,8,"r"}, {8,7,8,"r"}, {9,7,8,"r"}, {10,7,8,"r"}, {6,3,5,"r"}, {7,3,5,"r"}, {6,10,12,"r"}, {7,10,12,"r"} },
}

print("emotes")
do
  local bm = L.mask_new(16, 16)
  mask_rrect(bm, 1, 1, 14, 11, 2.5)
  L.mask_spans(bm, { {12,3,5}, {13,3,4}, {14,3,3} }, true)
  for _, key in ipairs({ "dots", "exclaim", "question", "heart", "zzz", "sweat", "skull", "mug", "note", "anger" }) do
    local spr = L.new_sprite(16, 16)
    local img = L.img(spr)
    for y = 0, 15 do
      for x = 0, 15 do
        if mget(bm, x, y) then L.blend(img, x, y, is_edge(bm, x, y) and BUBBLE_INK or BUBBLE_FILL) end
      end
    end
    spans(img, EMOTES[key], EMOTE_PAL)
    emit_grid(spr, "emote_" .. key, "emote", key)
  end
end

-- ---------------------------------------------------------------- 8. log-event badges 22x22
-- KIT-07: one disc per event kind (the Concept 1 column's coloured discs, 06 §8's
-- frown/gem/star/skull/check/coin family), a glyph in ink or cream on top.
-- `badge_<kind>` naming is retired; Cards.BADGE_FOR_KIND maps to these (W3-KIT2).

local function glyph_arrow_up(img, c, dy)
  dy = dy or 0
  sp(img, { {5+dy,10,11}, {6+dy,9,12}, {7+dy,8,13}, {8+dy,7,14} }, c); sp(img, rows({}, 9 + dy, 16 + dy, 10, 11), c)
end
local function glyph_frown(img, c)
  sp(img, { {7,7,8}, {8,7,8}, {7,13,14}, {8,13,14}, {14,8,13}, {15,7,7}, {15,14,14} }, c)
end
local function glyph_cross(img, c, x, y, arm, thick)
  sp(img, rows({}, y - arm, y + arm + thick - 1, x, x + thick - 1), c)
  sp(img, rows({}, y, y + thick - 1, x - arm, x + arm + thick - 1), c)
end
local function glyph_sword(img, c)
  L.line(img, 16, 5, 9, 12, c, 3); L.line(img, 5, 10, 10, 15, c, 2); L.line(img, 7, 13, 4, 16, c, 2)
end
local function glyph_eye(img, cx, cy, rx, ry, white, ink)
  L.ellipse_fill(img, cx, cy, rx, ry, white); L.ellipse_fill(img, cx, cy, ry * 0.55, ry * 0.55, ink)
end
local function glyph_cog(img, c, cx, cy, r)
  L.arc(img, cx, cy, r, 0, 360, c, 2)
  for k = 0, 7 do
    local a = math.rad(k * 45)
    local x, y = math.floor(cx + math.cos(a) * (r + 1.6) + 0.5), math.floor(cy + math.sin(a) * (r + 1.6) + 0.5)
    sp(img, { {y, x - 1, x}, {y + 1, x - 1, x} }, c)
  end
end
local function glyph_hourglass(img, c)
  sp(img, { {5,6,15}, {16,6,15}, {6,7,14}, {7,8,13}, {8,9,12}, {9,10,11}, {10,10,11}, {11,10,11}, {12,9,12}, {13,8,13}, {14,7,14}, {15,7,14} }, c)
end
local function glyph_scroll(img, paper, ink)
  sp(img, rows({}, 5, 16, 6, 15), paper); sp(img, { {5,5,5}, {5,16,16}, {16,5,5}, {16,16,16} }, paper)
  sp(img, { {8,8,13}, {10,8,13}, {12,8,13}, {14,8,11} }, ink)
end
local function glyph_gem(img, c, ink)
  local m = mask_spans(22, 22, { {6,8,13}, {7,7,14}, {8,6,15}, {9,6,15}, {10,7,14}, {11,8,13}, {12,9,12}, {13,10,11} })
  sprite(img, m, c, nil, ink)
  sp(img, { {8,6,15}, {9,10,11}, {10,10,11} }, ink)
end
local function glyph_coin(img, c)
  L.arc(img, 11, 11, 5, 0, 360, c, 2); sp(img, { {10,10,11}, {11,10,11} }, c)
end
local function glyph_bust(img, c)
  L.ellipse_fill(img, 11, 8, 3.2, 3.2, c); sp(img, { {12,9,12}, {13,7,14}, {14,6,15}, {15,5,16}, {16,5,16}, {17,5,16} }, c)
end

local LOG_KINDS = {
  { key = "mistake",       base = "#F73526", draw = function(img) glyph_frown(img, INK_DARK) end },
  { key = "heal",          base = "#32C24D", draw = function(img) glyph_cross(img, INK_DARK, 10, 10, 5, 2) end },
  { key = "raider_attack", base = "#4982A2", draw = function(img) glyph_sword(img, CREAM) end },
  { key = "boss_attack",   base = "#A672C8", draw = function(img) glyph_eye(img, 11, 11, 6, 3.6, CREAM, INK_DARK) end },
  { key = "mechanic",      base = "#7C86CC", draw = function(img) glyph_cog(img, CREAM, 11, 11, 4.5) end },
  { key = "phase",         base = "#856A57", draw = function(img) glyph_hourglass(img, CREAM) end },
  { key = "system",        base = "#9A9A9C", draw = function(img) glyph_scroll(img, CREAM, INK_DARK) end },
  { key = "morale_up",     base = "#6ED27E", draw = function(img) glyph_arrow_up(img, INK_DARK) end },
  { key = "morale_down",   base = "#E46F62", draw = function(img)
      local m = drawn_mask(22, 22, function(im, c) glyph_arrow_up(im, c) end)
      L.mask_paint(img, mask_flip_y(m), INK_DARK)
    end },
  { key = "loot",          base = "#B1A0F6", draw = function(img) glyph_gem(img, CREAM, INK_DARK) end },
  { key = "gold",          base = "#ECA742", draw = function(img) glyph_coin(img, INK_DARK) end },
  { key = "recruit",       base = "#B8CDDF", draw = function(img) glyph_bust(img, INK_DARK) end },
}

print("log badges")
for _, k in ipairs(LOG_KINDS) do
  local spr = L.new_sprite(22, 22)
  local img = L.img(spr)
  plate(img, mask_disc(22, 22, 11, 11, 10), hex(k.base))
  k.draw(img)
  emit_grid(spr, "log_" .. k.key, "log", k.key)
end

-- ---------------------------------------------------------------- 9. state + mechanic plates 24x24
-- PIPE-07: the sim's named per-raider states (state_<key>) and the twelve
-- mechanics (mech_<key>, same names RaidView loads today, regenerated from
-- resampled VFX crops into data) share one treatment: a 22px rounded-square
-- plate with the badge rim, a cream (or ink) glyph. swap_stack is a BARE plate:
-- its numeral is a Label (docs/13 §14). Mechanic plates are tinted by the role
-- group the mechanic stresses (Enums.MECHANIC_STRESSES): tank steel, healer
-- green, dps ember, support violet.

local function plate_rrect()
  local m = L.mask_new(24, 24)
  mask_rrect(m, 1, 1, 22, 22, 4)
  return m
end

local function glyph_skull(img, c, hole)
  sp(img, { {5,8,15}, {6,7,16}, {7,6,17}, {8,6,7}, {8,10,13}, {8,16,17}, {9,6,7}, {9,10,13}, {9,16,17}, {10,7,16}, {11,8,15},
            {12,9,9}, {12,11,12}, {12,14,14}, {13,9,9}, {13,11,12}, {13,14,14} }, c)
end
local function glyph_heart(img, c)
  sp(img, { {6,7,9}, {6,14,16}, {7,6,10}, {7,13,17}, {8,6,17}, {9,6,17}, {10,6,17}, {11,7,16}, {12,8,15}, {13,9,14}, {14,10,13}, {15,11,12} }, c)
end
local function glyph_shield(img, c)
  sp(img, { {5,7,16}, {6,6,17}, {7,6,17}, {8,6,17}, {9,6,17}, {10,6,17}, {11,6,17}, {12,6,17}, {13,7,16}, {14,8,15}, {15,9,14}, {16,10,13}, {17,11,12} }, c)
end
local function glyph_drop(img, c)
  sp(img, { {5,11,12}, {6,10,13}, {7,9,14}, {8,9,14}, {9,8,15}, {10,8,15}, {11,8,15}, {12,9,14}, {13,10,13}, {14,11,12} }, c)
end
local function slash(img, c) L.line(img, 6, 18, 18, 6, c, 2) end
-- downed: a figure on the floor line — head at the left, body flat, an arrow down above it
local function glyph_fallen(img, c)
  L.ellipse_fill(img, 6.5, 14.5, 2.5, 2.5, c); sp(img, rows({}, 13, 16, 10, 19), c); sp(img, rows({}, 18, 18, 4, 20), c)
  sp(img, { {4,11,12}, {5,11,12}, {6,11,12}, {7,11,12}, {8,8,15}, {9,9,14}, {10,10,13}, {11,11,12} }, c)
end
local function glyph_flame(img, c, core)
  sp(img, { {4,12,12}, {5,11,13}, {6,11,13}, {7,10,14}, {8,9,15}, {8,16,16}, {9,8,16}, {9,17,17}, {10,8,17}, {11,8,17}, {12,8,17}, {13,8,16},
            {14,9,15}, {15,10,14}, {16,11,13}, {6,7,7}, {7,7,8} }, c)
  if core then sp(img, { {11,12,12}, {12,11,13}, {13,11,13}, {14,11,13}, {15,12,12} }, core) end
end
local function glyph_swap(img, c)
  sp(img, { {8,5,15}, {6,14,14}, {7,14,15}, {9,14,15}, {10,14,14}, {8,16,16} }, c)
  sp(img, { {15,8,18}, {13,9,9}, {14,8,9}, {16,8,9}, {17,9,9}, {15,7,7} }, c)
end
local function glyph_burst(img, c)
  for k = 0, 7 do
    local a = math.rad(k * 45)
    L.line(img, 12 + math.cos(a) * 2.5, 12 + math.sin(a) * 2.5, 12 + math.cos(a) * 8, 12 + math.sin(a) * 8, c, 1)
  end
  L.ellipse_fill(img, 12, 12, 2, 2, c)
end
-- ground effect: a floor marker — two concentric rings on the ground, a mark at the centre
local function glyph_puddle(img, c, base)
  L.ellipse_fill(img, 12, 13, 9, 5, c); L.ellipse_fill(img, 12, 13, 7, 3.5, base)
  L.ellipse_fill(img, 12, 13, 4.5, 2, c); L.ellipse_fill(img, 12, 13, 2.5, 1, base)
  sp(img, { {5,11,12}, {6,11,12}, {7,11,12} }, c)
end
local function glyph_adds(img, c)
  for _, cx in ipairs({ 6.5, 12, 17.5 }) do
    local cy = (cx == 12) and 7.5 or 9.5
    L.ellipse_fill(img, cx, cy, 2, 2, c)
  end
  sp(img, { {11,11,13}, {12,10,14}, {13,4,19}, {14,4,19}, {15,4,19}, {16,4,19}, {17,5,18} }, c)
end
local function glyph_bolt(img, c)
  L.poly_fill(img, { { 14, 4 }, { 8, 13 }, { 12, 13 }, { 10, 20 }, { 17, 10 }, { 13, 10 } }, c)
end
local function glyph_crosshair(img, c)
  L.arc(img, 12, 12, 6, 0, 360, c, 1)
  sp(img, { {12,3,8}, {12,15,20}, {3,12,12}, {4,12,12}, {5,12,12}, {6,12,12}, {7,12,12}, {8,12,12}, {15,12,12}, {16,12,12}, {17,12,12}, {18,12,12}, {19,12,12}, {20,12,12} }, c)
  sp(img, { {12,12,12} }, c)
end
local function glyph_wedge(img, c, base)
  L.poly_fill(img, { { 5, 4.5 }, { 20, 12 }, { 5, 19.5 } }, c)
  L.poly_fill(img, { { 5, 9 }, { 14, 12 }, { 5, 15 } }, base)
end
local function glyph_stairs(img, c)
  sp(img, rows({}, 14, 18, 5, 8), c); sp(img, rows({}, 10, 18, 10, 13), c); sp(img, rows({}, 5, 18, 15, 18), c)
end

local STATE_PAL = { steel = "#4982A2", green = "#2F7A3F", ember = "#B33A2E", violet = "#7A4FA8" }
local STATES = {
  { key = "downed",         base = "#C98A22", draw = function(img) glyph_fallen(img, INK_DARK) end },
  { key = "dead",           base = "#4A2E33", draw = function(img) glyph_skull(img, CREAM) end },
  { key = "at_risk",        base = "#F73526", draw = function(img, base) glyph_heart(img, INK_DARK); sp(img, { {7,12,12}, {8,11,11}, {9,12,12}, {10,11,11}, {11,12,12}, {12,11,11}, {13,12,12} }, base) end },
  { key = "tanking",        base = STATE_PAL.steel, draw = function(img) glyph_shield(img, CREAM) end },
  { key = "swap_stack",     base = "#3F434B", draw = function(img) end },
  { key = "fixated",        base = STATE_PAL.violet, draw = function(img) glyph_eye(img, 12, 12, 7, 4, CREAM, INK_DARK) end },
  { key = "mana_burn",      base = "#006C9C", draw = function(img) glyph_drop(img, CREAM); slash(img, DANGER) end },
  { key = "healing_debuff", base = STATE_PAL.green, draw = function(img) glyph_cross(img, CREAM, 11, 11, 5, 2); slash(img, DANGER) end },
}

local MECHS = {
  { key = "tank_swap",        base = STATE_PAL.steel,  draw = function(img) glyph_swap(img, CREAM) end },
  { key = "raid_wide",        base = STATE_PAL.green,  draw = function(img) glyph_burst(img, CREAM) end },
  { key = "ground_effect",    base = STATE_PAL.ember,  draw = function(img, base) glyph_puddle(img, CREAM, base) end },
  { key = "add_spawns",       base = STATE_PAL.ember,  draw = function(img) glyph_adds(img, CREAM) end },
  { key = "interrupt_check",  base = STATE_PAL.ember,  draw = function(img) glyph_bolt(img, CREAM) end },
  { key = "enrage",           base = STATE_PAL.ember,  draw = function(img) glyph_flame(img, CREAM, CAUTION) end },
  { key = "positioning",      base = STATE_PAL.ember,  draw = function(img) glyph_crosshair(img, CREAM) end },
  { key = "fixate",           base = STATE_PAL.green,  draw = function(img) glyph_eye(img, 12, 12, 7, 4, CREAM, INK_DARK) end },
  { key = "healing_debuff",   base = STATE_PAL.green,  draw = function(img) glyph_cross(img, CREAM, 11, 11, 5, 2); slash(img, DANGER) end },
  { key = "mana_burn",        base = STATE_PAL.violet, draw = function(img) glyph_drop(img, CREAM); slash(img, DANGER) end },
  { key = "frontal_cleave",   base = STATE_PAL.steel,  draw = function(img, base) glyph_wedge(img, CREAM, base) end },
  { key = "escalating_swing", base = STATE_PAL.steel,  draw = function(img) glyph_stairs(img, CREAM) end },
}

print("state plates")
for _, s in ipairs(STATES) do
  local spr = L.new_sprite(24, 24)
  local img = L.img(spr)
  local base = hex(s.base)
  plate(img, plate_rrect(), base)
  s.draw(img, L.mix(base, hex("#F9F4E5"), 0.05))
  emit_grid(spr, "state_" .. s.key, "state", s.key)
end

print("mechanic plates")
for _, s in ipairs(MECHS) do
  local spr = L.new_sprite(24, 24)
  local img = L.img(spr)
  local base = hex(s.base)
  plate(img, plate_rrect(), base)
  s.draw(img, L.mix(base, hex("#F9F4E5"), 0.05))
  emit(spr, "mech_" .. s.key, "mech", s.key)
end

-- ---------------------------------------------------------------- 10. bar glyphs 24x24
-- KIT-17: Concept 2's shield (#E8433A) and drop (#3DA5D8) left of the two bars.
print("bar glyphs")
do
  local spr = L.new_sprite(24, 24)
  local m = mask_spans(24, 24, { {2,6,17}, {3,5,18}, {4,5,18}, {5,5,18}, {6,5,18}, {7,5,18}, {8,5,18}, {9,5,18}, {10,5,18}, {11,5,18}, {12,5,18},
    {13,6,17}, {14,7,16}, {15,8,15}, {16,9,14}, {17,10,13}, {18,11,12}, {19,11,12} })
  plate(L.img(spr), m, hex("#E8433A"))
  sp(L.img(spr), { {7,11,12}, {8,11,12}, {9,9,14}, {10,9,14}, {11,11,12}, {12,11,12} }, hex("#F9F4E5"))
  emit_grid(spr, "bar_hp", "bar", "hp")
  spr = L.new_sprite(24, 24)
  m = mask_spans(24, 24, { {2,11,12}, {3,10,13}, {4,10,13}, {5,10,13}, {6,9,14}, {7,9,14}, {8,8,15}, {9,8,15}, {10,8,15}, {11,7,16}, {12,7,16},
    {13,7,16}, {14,7,16}, {15,8,15}, {16,8,15}, {17,9,14}, {18,10,13}, {19,11,12} })
  plate(L.img(spr), m, hex("#3DA5D8"))
  emit_grid(spr, "bar_focus", "bar", "focus")
end

-- ---------------------------------------------------------------- 11. building glyphs 32x32
-- TOWN-01 / KIT-01: the five callout icons (spec 03 §3's icon reads 24-35px),
-- light grey three-tone sprites: hall banner, tankard, scales, anvil + hammers,
-- notice board. Consumed as `Icons.at("building", key)` by the callout kit.

local BLD = { fill = hex("#C6CCD4"), shade = hex("#8C949E"), dark = hex("#3A373A"), paper = hex("#E8E4DA") }
local BUILDINGS = {}
BUILDINGS.guildhall = function(im, c)
  sp(im, rows({ {3,3,3}, {3,28,28} }, 4, 5, 2, 29), c)
  sp(im, rows({}, 6, 20, 8, 23), c)
  sp(im, { {21,8,23}, {22,9,22}, {23,10,21}, {24,11,20}, {25,12,19}, {26,13,18}, {27,14,17}, {28,15,16} }, c)
end
BUILDINGS.tavern = function(im, c)
  sp(im, rows({}, 8, 27, 7, 21), c)
  L.arc(im, 22, 17, 5, 270, 450, c, 3)
  sp(im, rows({ {4,7,8}, {4,11,12}, {4,16,17}, {4,20,20} }, 5, 8, 6, 22), c)
end
BUILDINGS.market = function(im, c)
  sp(im, rows({}, 6, 26, 15, 16), c); sp(im, rows({}, 26, 28, 9, 22), c); sp(im, rows({}, 8, 9, 4, 27), c)
  L.line(im, 5, 10, 3, 18, c, 1); L.line(im, 9, 10, 11, 18, c, 1); L.line(im, 22, 10, 20, 18, c, 1); L.line(im, 26, 10, 28, 18, c, 1)
  L.ellipse_fill(im, 7, 19.5, 5, 2.2, c); L.ellipse_fill(im, 24, 19.5, 5, 2.2, c)
  sp(im, { {5,14,17}, {4,15,16} }, c)
end
BUILDINGS.blacksmith = function(im, c)
  sp(im, { {11,3,27}, {12,4,27}, {13,5,27}, {14,10,22}, {15,10,22}, {16,11,21}, {17,11,21}, {18,11,21}, {19,11,21}, {20,10,22} }, c)
  sp(im, rows({ {10,3,27}, {10,3,4} }, 21, 25, 7, 25), c)
  L.line(im, 8, 8, 14, 3, c, 2); sp(im, rows({}, 6, 9, 4, 8), c)
  L.line(im, 23, 8, 17, 3, c, 2); sp(im, rows({}, 6, 9, 23, 27), c)
end
BUILDINGS.board = function(im, c)
  sp(im, rows({}, 5, 21, 4, 27), c); sp(im, rows({}, 22, 29, 14, 17), c)
end
local BLD_DETAIL = {
  guildhall = { {12,14,17,"d"}, {13,13,18,"d"}, {14,13,18,"d"}, {15,14,17,"d"}, {6,8,23,"s"} },
  tavern = { {12,8,20,"s"}, {21,8,20,"s"} },
  market = { {18,4,9,"s"}, {18,21,26,"s"} },
  blacksmith = { {13,5,27,"s"}, {20,10,22,"s"}, {21,7,25,"s"} },
  board = { {8,7,14,"p"}, {9,7,14,"p"}, {10,7,14,"p"}, {11,7,14,"p"}, {12,7,14,"p"}, {13,7,14,"p"}, {14,7,14,"p"}, {15,7,14,"p"}, {16,7,14,"p"},
            {8,17,24,"p"}, {9,17,24,"p"}, {10,17,24,"p"}, {11,17,24,"p"}, {12,17,24,"p"}, {13,17,24,"p"}, {14,17,24,"p"}, {15,17,24,"p"}, {16,17,24,"p"},
            {7,10,11,"d"}, {7,20,21,"d"}, {10,9,12,"s"}, {12,9,12,"s"}, {14,9,12,"s"}, {10,19,22,"s"}, {12,19,22,"s"}, {14,19,22,"s"} },
}

print("building glyphs")
for _, key in ipairs({ "guildhall", "tavern", "market", "blacksmith", "board" }) do
  local spr = L.new_sprite(32, 32)
  local img = L.img(spr)
  sprite(img, drawn_mask(32, 32, BUILDINGS[key]), BLD.fill, BLD.shade, BLD.dark)
  spans(img, BLD_DETAIL[key], { d = BLD.dark, s = BLD.shade, p = BLD.paper })
  emit_grid(spr, "building_" .. key, "building", key)
end

-- ---------------------------------------------------------------- 12. empty-state glyphs 32x32
-- KIT-08: quill (a log with nothing in it), bench (no raiders), shelf (nothing
-- to sell) — the engraved slot-glyph treatment, muted, so an empty panel reads
-- as intentionally empty.

local EMPTY = {}
EMPTY.quill = function(im, c)
  L.poly_fill(im, { { 27, 3 }, { 23, 4 }, { 17, 8 }, { 12, 14 }, { 8, 21 }, { 7, 26 }, { 10, 23 }, { 14, 18 }, { 20, 11 }, { 26, 6 } }, c)
  L.line(im, 8, 24, 5, 28, c, 2)
end
EMPTY.bench = function(im, c)
  sp(im, rows({}, 14, 17, 4, 27), c); sp(im, rows({}, 18, 26, 6, 8), c); sp(im, rows({}, 18, 26, 23, 25), c)
  sp(im, rows({}, 8, 9, 4, 27), c); sp(im, rows({}, 10, 13, 6, 7), c); sp(im, rows({}, 10, 13, 24, 25), c)
end
EMPTY.shelf = function(im, c)
  sp(im, rows({}, 10, 11, 4, 27), c); sp(im, rows({}, 21, 22, 4, 27), c)
  sp(im, rows({}, 6, 26, 3, 3), c); sp(im, rows({}, 6, 26, 28, 28), c)
  sp(im, rows({}, 12, 14, 5, 6), c); sp(im, rows({}, 12, 14, 25, 26), c); sp(im, rows({}, 23, 25, 5, 6), c); sp(im, rows({}, 23, 25, 25, 26), c)
end
local EMPTY_DETAIL = { quill = { {20,11,11,"="}, {18,13,13,"="}, {16,15,15,"="}, {14,17,17,"="}, {12,19,19,"="}, {10,21,21,"="}, {8,23,23,"="} } }

print("empty-state glyphs")
for _, key in ipairs({ "quill", "bench", "shelf" }) do
  local spr = L.new_sprite(32, 32)
  render_glyph(L.img(spr), 0, 0, drawn_mask(32, 32, EMPTY[key]), EMPTY_DETAIL[key])
  emit_grid(spr, "empty_" .. key, "empty", key)
end

-- ---------------------------------------------------------------- 13. furnishings 32x32
-- TOWN-21 / m4t-03: one per Comfort furnishing key (sim/core/Comfort.gd
-- FURNISHINGS + GUILD_FURNISHINGS): straw_cot, feather_bed, hot_meal,
-- trophy_shelf, personal_effect, hot_meal_all. Full colour, ITEM_PAL.

local FURN = {}
-- straw cot: a low frame with a straw mound
FURN.straw_cot = {
  {20,4,27,"o"}, {21,3,3,"o"}, {21,4,27,"k"}, {21,28,28,"o"}, {22,3,3,"o"}, {22,4,27,"K"}, {22,28,28,"o"}, {23,4,27,"o"},
  {24,5,7,"K"}, {25,5,7,"K"}, {26,5,7,"o"}, {24,24,26,"K"}, {25,24,26,"K"}, {26,24,26,"o"},
  {13,11,20,"o"}, {14,8,23,"o"}, {14,9,22,"y"}, {15,6,25,"o"}, {15,7,24,"y"}, {16,5,26,"o"}, {16,6,25,"y"}, {17,5,26,"o"}, {17,6,25,"y"},
  {18,5,26,"o"}, {18,6,25,"u"}, {19,5,26,"o"}, {19,6,25,"u"},
  {15,9,10,"u"}, {16,13,13,"u"}, {17,17,18,"u"}, {16,21,22,"u"}, {15,16,16,"Y"}, {16,8,8,"Y"},
}
-- feather bed: headboard, mattress, pillow, red blanket
FURN.feather_bed = {
  {7,4,6,"o"}, {8,3,3,"o"}, {8,4,6,"k"}, {8,7,7,"o"}, {9,3,3,"o"}, {9,4,6,"k"}, {9,7,7,"o"}, {10,3,3,"o"}, {10,4,6,"k"}, {10,7,7,"o"},
  {11,3,3,"o"}, {11,4,6,"k"}, {11,7,7,"o"}, {12,3,3,"o"}, {12,4,6,"k"}, {13,3,3,"o"}, {13,4,6,"k"}, {14,3,3,"o"}, {14,4,6,"k"}, {15,3,3,"o"}, {15,4,6,"k"},
  {13,7,15,"o"}, {14,7,7,"o"}, {14,8,14,"e"}, {14,15,15,"o"}, {15,7,7,"o"}, {15,8,14,"w"}, {15,15,15,"o"},
  {16,7,28,"o"}, {17,3,3,"o"}, {17,4,6,"k"}, {17,7,27,"w"}, {17,28,28,"o"}, {18,3,3,"o"}, {18,4,6,"k"}, {18,7,27,"w"}, {18,28,28,"o"},
  {18,15,27,"q"}, {19,3,3,"o"}, {19,4,6,"k"}, {19,7,14,"w"}, {19,15,27,"r"}, {19,28,28,"o"}, {20,3,3,"o"}, {20,4,6,"K"}, {20,7,14,"w"}, {20,15,27,"r"}, {20,28,28,"o"},
  {21,3,3,"o"}, {21,4,6,"K"}, {21,7,14,"w"}, {21,15,27,"q"}, {21,28,28,"o"}, {22,3,3,"o"}, {22,4,27,"K"}, {22,28,28,"o"}, {23,4,27,"o"},
  {24,5,6,"K"}, {25,5,6,"K"}, {26,5,6,"o"}, {24,25,26,"K"}, {25,25,26,"K"}, {26,25,26,"o"},
}
-- hot meal: a bowl, three steam wisps
FURN.hot_meal = {
  {5,11,11,"v"}, {6,10,10,"v"}, {7,11,11,"v"}, {8,10,10,"v"}, {9,11,11,"v"},
  {4,16,16,"v"}, {5,15,15,"v"}, {6,16,16,"v"}, {7,15,15,"v"}, {8,16,16,"v"},
  {5,21,21,"v"}, {6,20,20,"v"}, {7,21,21,"v"}, {8,20,20,"v"}, {9,21,21,"v"},
  {13,7,24,"o"}, {14,6,6,"o"}, {14,7,24,"e"}, {14,25,25,"o"}, {15,5,5,"o"}, {15,6,25,"w"}, {15,26,26,"o"},
  {16,5,5,"o"}, {16,6,25,"m"}, {16,26,26,"o"}, {17,6,6,"o"}, {17,7,24,"m"}, {17,25,25,"o"}, {18,6,6,"o"}, {18,7,24,"m"}, {18,25,25,"o"},
  {19,7,7,"o"}, {19,8,23,"m"}, {19,24,24,"o"}, {20,8,8,"o"}, {20,9,22,"c"}, {20,23,23,"o"}, {21,9,9,"o"}, {21,10,21,"c"}, {21,22,22,"o"},
  {22,10,10,"o"}, {22,11,20,"c"}, {22,21,21,"o"}, {23,11,20,"o"}, {24,12,19,"o"}, {24,13,18,"c"}, {25,12,19,"o"},
  {16,7,9,"M"}, {17,8,8,"M"},
}
-- trophy shelf: a board with a skull on it
FURN.trophy_shelf = {
  {8,11,20,"o"}, {9,10,10,"o"}, {9,11,20,"e"}, {9,21,21,"o"}, {10,9,9,"o"}, {10,10,21,"e"}, {10,22,22,"o"},
  {11,9,9,"o"}, {11,10,21,"e"}, {11,22,22,"o"}, {12,9,9,"o"}, {12,10,21,"e"}, {12,22,22,"o"},
  {13,9,9,"o"}, {13,10,11,"e"}, {13,12,13,"o"}, {13,14,17,"e"}, {13,18,19,"o"}, {13,20,21,"e"}, {13,22,22,"o"},
  {14,9,9,"o"}, {14,10,11,"e"}, {14,12,13,"o"}, {14,14,17,"e"}, {14,18,19,"o"}, {14,20,21,"e"}, {14,22,22,"o"},
  {15,9,9,"o"}, {15,10,21,"e"}, {15,22,22,"o"}, {16,10,10,"o"}, {16,11,20,"e"}, {16,21,21,"o"},
  {17,11,11,"o"}, {17,12,19,"e"}, {17,20,20,"o"}, {18,11,11,"o"}, {18,12,12,"e"}, {18,13,13,"o"}, {18,14,14,"e"}, {18,15,15,"o"}, {18,16,16,"e"}, {18,17,17,"o"}, {18,18,18,"e"}, {18,19,19,"o"}, {18,20,20,"o"},
  {19,12,19,"o"},
  {20,4,27,"o"}, {21,3,3,"o"}, {21,4,27,"k"}, {21,28,28,"o"}, {22,3,3,"o"}, {22,4,27,"K"}, {22,28,28,"o"}, {23,4,27,"o"},
  {24,6,7,"K"}, {25,6,6,"K"}, {26,6,6,"o"}, {24,24,25,"K"}, {25,25,25,"K"}, {26,25,25,"o"},
}
-- personal effect: a locket on a chain, a small heart inside
FURN.personal_effect = {
  {3,15,16,"y"}, {4,14,14,"y"}, {4,17,17,"y"}, {5,14,14,"y"}, {5,17,17,"y"}, {6,15,16,"y"}, {7,15,16,"u"}, {8,15,16,"y"}, {9,15,16,"u"}, {10,15,16,"y"},
  {11,13,18,"o"}, {12,11,12,"o"}, {12,13,18,"y"}, {12,19,20,"o"}, {13,10,10,"o"}, {13,11,20,"y"}, {13,21,21,"o"},
  {14,9,9,"o"}, {14,10,11,"y"}, {14,12,19,"w"}, {14,20,21,"y"}, {14,22,22,"o"},
  {15,9,9,"o"}, {15,10,10,"y"}, {15,11,20,"w"}, {15,21,21,"y"}, {15,22,22,"o"},
  {16,8,8,"o"}, {16,9,10,"y"}, {16,11,20,"w"}, {16,21,22,"y"}, {16,23,23,"o"},
  {17,8,8,"o"}, {17,9,10,"y"}, {17,11,20,"w"}, {17,21,22,"y"}, {17,23,23,"o"},
  {18,8,8,"o"}, {18,9,10,"y"}, {18,11,20,"w"}, {18,21,22,"y"}, {18,23,23,"o"},
  {19,8,8,"o"}, {19,9,10,"y"}, {19,11,20,"w"}, {19,21,22,"y"}, {19,23,23,"o"},
  {20,9,9,"o"}, {20,10,10,"y"}, {20,11,20,"w"}, {20,21,21,"y"}, {20,22,22,"o"},
  {21,9,9,"o"}, {21,10,11,"u"}, {21,12,19,"w"}, {21,20,21,"u"}, {21,22,22,"o"},
  {22,10,10,"o"}, {22,11,20,"u"}, {22,21,21,"o"}, {23,11,12,"o"}, {23,13,18,"u"}, {23,19,20,"o"}, {24,13,18,"o"},
  {15,13,14,"R"}, {15,17,18,"R"}, {16,12,19,"r"}, {17,12,19,"r"}, {18,13,18,"r"}, {19,14,17,"r"}, {20,15,16,"r"}, {16,13,13,"R"},
  {12,14,15,"Y"}, {13,12,13,"Y"},
}
-- hot meal, guild-wide: a cauldron over its own fire, steam
FURN.hot_meal_all = {
  {2,13,13,"v"}, {3,12,12,"v"}, {4,13,13,"v"}, {2,18,18,"v"}, {3,19,19,"v"}, {4,18,18,"v"},
  {6,10,21,"o"}, {7,9,9,"o"}, {7,10,21,"I"}, {7,22,22,"o"}, {8,8,8,"o"}, {8,9,22,"i"}, {8,23,23,"o"},
  {9,7,7,"o"}, {9,8,23,"i"}, {9,24,24,"o"}, {10,6,6,"o"}, {10,7,24,"o"}, {10,25,25,"o"},
  {11,5,5,"o"}, {11,6,25,"i"}, {11,26,26,"o"}, {12,4,4,"o"}, {12,5,26,"i"}, {12,27,27,"o"}, {13,4,4,"o"}, {13,5,26,"i"}, {13,27,27,"o"},
  {14,4,4,"o"}, {14,5,26,"i"}, {14,27,27,"o"}, {15,4,4,"o"}, {15,5,26,"i"}, {15,27,27,"o"}, {16,4,4,"o"}, {16,5,26,"i"}, {16,27,27,"o"},
  {17,5,5,"o"}, {17,6,25,"i"}, {17,26,26,"o"}, {18,5,5,"o"}, {18,6,25,"I"}, {18,26,26,"o"}, {19,6,6,"o"}, {19,7,24,"I"}, {19,25,25,"o"},
  {20,7,7,"o"}, {20,8,23,"i"}, {20,24,24,"o"}, {21,8,23,"o"},
  {22,9,10,"i"}, {23,9,10,"o"}, {22,21,22,"i"}, {23,21,22,"o"},
  {11,7,8,"I"}, {12,6,7,"I"}, {13,6,6,"I"},
  {3,6,6,"o"}, {4,5,5,"o"}, {5,5,5,"o"}, {6,5,6,"o"}, {7,6,7,"o"}, {8,7,7,"o"}, {3,25,25,"o"}, {4,26,26,"o"}, {5,26,26,"o"}, {6,25,26,"o"}, {7,24,25,"o"}, {8,24,24,"o"},
  {2,7,24,"o"},
  {24,11,20,"Y"}, {25,10,21,"y"}, {26,9,22,"M"}, {27,10,21,"c"}, {24,15,16,"e"}, {25,14,17,"Y"},
}

print("furnishings")
for _, key in ipairs({ "straw_cot", "feather_bed", "hot_meal", "trophy_shelf", "personal_effect", "hot_meal_all" }) do
  local spr = L.new_sprite(32, 32)
  spans(L.img(spr), FURN[key], ITEM_PAL)
  emit_grid(spr, "furnishing_" .. key, "furnishing", key)
end

-- ---------------------------------------------------------------- 14. boss-rank sigils 48x48
-- COMBAT-05: a bare family glyph per rank in game/assets/enemies/enemies.json
-- (not a body): sludge maw, void core, spiked crawler, stone brute, flame
-- brute, void tentacle. Light steel three-tone so it sits on the boss plate.

local SIG = { fill = hex("#C6CCD4"), shade = hex("#8C949E"), dark = hex("#3A373A") }
local SIGILS = {}
SIGILS.boss_main = function(im, c)
  sp(im, { {8,14,33}, {9,10,37}, {10,8,39}, {11,6,41} }, c); sp(im, rows({}, 12, 18, 5, 42), c)
  for _, x in ipairs({ 8, 15, 22, 29, 36 }) do
    sp(im, { {19,x,x+3}, {20,x,x+3}, {21,x+1,x+2}, {22,x+1,x+2}, {23,x+1,x+2}, {24,x+1,x+1} }, c)
  end
  sp(im, rows({}, 33, 38, 7, 40), c); sp(im, { {39,9,38}, {40,12,35} }, c)
  for _, x in ipairs({ 12, 23, 34 }) do
    sp(im, { {27,x+1,x+1}, {28,x+1,x+2}, {29,x+1,x+2}, {30,x,x+3}, {31,x,x+3}, {32,x,x+3} }, c)
  end
end
-- void core: a hexagonal crystal with four rays
SIGILS.boss_main_2 = function(im, c)
  L.poly_fill(im, { { 24, 5 }, { 36, 15 }, { 36, 33 }, { 24, 43 }, { 12, 33 }, { 12, 15 } }, c)
  L.line(im, 24, 1, 24, 4, c, 2); L.line(im, 24, 44, 24, 47, c, 2); L.line(im, 4, 24, 10, 24, c, 2); L.line(im, 38, 24, 44, 24, c, 2)
end
-- spiked crawler: an oval body, spikes along the back, three leg pairs
SIGILS.boss_mini = function(im, c)
  L.ellipse_fill(im, 24, 27, 14, 9, c)
  for _, x in ipairs({ 12, 18, 24, 30, 36 }) do L.line(im, x, 20, x + (x < 24 and -2 or (x > 24 and 2 or 0)), 11, c, 3) end
  for _, x in ipairs({ 13, 24, 35 }) do L.line(im, x, 33, x - 5, 42, c, 3); L.line(im, x, 33, x + 5, 42, c, 3) end
end
SIGILS.boss_mini_2 = function(im, c)
  local m = L.mask_new(48, 48)
  mask_rrect(m, 9, 13, 30, 26, 6)
  for _, x in ipairs({ 11, 18, 25, 32 }) do mask_rrect(m, x, 8, 6, 9, 3) end
  L.mask_paint(im, m, c)
end
SIGILS.boss_elite = function(im, c)
  L.poly_fill(im, { { 24, 3 }, { 30, 12 }, { 36, 10 }, { 40, 22 }, { 38, 34 }, { 30, 42 }, { 18, 42 }, { 10, 34 }, { 8, 22 }, { 13, 12 }, { 18, 15 } }, c)
end
SIGILS.boss_trash = function(im, c)
  L.arc(im, 28, 30, 12, 60, 270, c, 8); L.arc(im, 18, 14, 8, 240, 420, c, 5); L.arc(im, 30, 12, 4, 60, 250, c, 3)
end
local SIG_DETAIL = {
  boss_main = { {14,12,15,"d"}, {15,11,16,"d"}, {14,32,35,"d"}, {15,31,36,"d"} },
  boss_main_2 = { {15,24,24,"s"}, {16,23,25,"s"}, {17,22,26,"s"}, {18,21,27,"s"}, {19,20,28,"s"}, {20,19,29,"s"}, {21,18,30,"s"}, {22,17,31,"s"},
                  {23,17,31,"s"}, {24,17,31,"s"}, {25,17,31,"s"}, {26,18,30,"s"}, {27,19,29,"s"}, {28,20,28,"s"}, {29,21,27,"s"}, {30,22,26,"s"}, {31,23,25,"s"}, {32,24,24,"s"},
                  {20,22,26,"d"}, {21,21,27,"d"}, {22,20,28,"d"}, {23,20,28,"d"}, {24,20,28,"d"}, {25,20,28,"d"}, {26,21,27,"d"}, {27,22,26,"d"}, {21,22,23,"s"} },
  boss_mini = { {24,14,16,"d"}, {25,14,16,"d"}, {24,32,34,"d"}, {25,32,34,"d"}, {29,20,28,"d"}, {30,19,29,"d"}, {21,15,33,"s"} },
  boss_mini_2 = { {20,14,14,"d"}, {21,15,15,"d"}, {22,16,16,"d"}, {23,17,17,"d"}, {26,28,28,"d"}, {27,29,29,"d"}, {28,30,30,"d"}, {29,31,31,"d"}, {30,32,32,"d"},
                  {18,12,16,"s"}, {18,19,23,"s"}, {18,26,30,"s"}, {18,33,37,"s"} },
  boss_elite = { {20,24,24,"s"}, {21,23,25,"s"}, {22,22,26,"s"}, {23,21,27,"s"}, {24,21,27,"s"}, {25,20,28,"s"}, {26,20,28,"s"}, {27,20,28,"s"},
                 {28,20,28,"s"}, {29,20,28,"s"}, {30,20,28,"s"}, {31,20,28,"s"}, {32,21,27,"s"}, {33,21,27,"s"}, {34,22,26,"s"}, {35,22,26,"s"}, {36,23,25,"s"},
                 {26,23,25,"d"}, {27,22,26,"d"}, {28,22,26,"d"}, {29,22,26,"d"}, {30,22,26,"d"}, {31,22,26,"d"}, {32,23,25,"d"}, {33,23,25,"d"}, {34,24,24,"d"} },
  boss_trash = { {28,17,18,"d"}, {33,17,18,"d"}, {38,20,21,"d"}, {41,26,27,"d"}, {24,20,21,"d"} },
}

print("boss sigils")
for _, key in ipairs({ "boss_main", "boss_main_2", "boss_mini", "boss_mini_2", "boss_elite", "boss_trash" }) do
  local spr = L.new_sprite(48, 48)
  local img = L.img(spr)
  sprite(img, drawn_mask(48, 48, SIGILS[key]), SIG.fill, SIG.shade, SIG.dark)
  spans(img, SIG_DETAIL[key], { d = SIG.dark, s = SIG.shade })
  emit_grid(spr, "sigil_" .. key, "sigil", key)
end

-- ---------------------------------------------------------------- 15. padlock 16x16, ink blots 12x12
-- TOWN-02 / TOWN-11: the lock that replaces a locked callout's icon and marks a
-- locked notice. COMBAT-09: three ink silhouettes at DANGER 80 % for a
-- mistake's blot on the combatant panel (a fixed lobe table per blot — no
-- randomness, so the bytes are the gate's).

print("lock")
do
  local spr = L.new_sprite(16, 16)
  local img = L.img(spr)
  local m = drawn_mask(16, 16, function(im, c)
    L.arc(im, 7.5, 6, 3.5, 180, 360, c, 2)
    sp(im, rows({}, 5, 6, 3, 4), c); sp(im, rows({}, 5, 6, 11, 12), c)
  end)
  sprite(img, m, hex("#B4B1AE"), hex("#7B838E"), hex("#3A373A"))
  local body = L.mask_new(16, 16)
  mask_rrect(body, 2, 7, 12, 8, 1.5)
  sprite(img, body, hex("#9A9A9C"), hex("#6B7078"), hex("#3A373A"))
  sp(img, { {7,3,12}, {9,7,8}, {10,7,8}, {11,7,8}, {12,7,8} }, hex("#C6CCD4"))
  sp(img, { {9,7,8}, {10,7,8}, {11,7,7}, {12,7,7} }, hex("#3A373A"))
  emit_grid(spr, "lock_16", "lock", "16")
end

print("blots")
do
  local BLOT_INK = hex("#F73526CC")
  local BLOTS = {
    a = { { 6, 6, 4, 3.4 }, { 3, 4, 1.6, 1.6 }, { 9, 8.5, 1.8, 1.6 }, { 10.5, 2.5, 0.9, 0.9 } },
    b = { { 5, 6, 3.4, 4 }, { 8.5, 3.5, 2, 2 }, { 9, 9, 1.6, 1.6 }, { 2, 10, 0.9, 0.9 }, { 11, 3, 0.7, 0.7 } },
    c = { { 6, 5, 4.2, 3 }, { 3.5, 8, 2, 2 }, { 10, 7, 1.6, 1.5 }, { 5, 10, 1.1, 1.1 }, { 1.5, 2, 0.8, 0.8 } },
  }
  for _, key in ipairs({ "a", "b", "c" }) do
    local spr = L.new_sprite(12, 12)
    local m = L.mask_new(12, 12)
    for _, e in ipairs(BLOTS[key]) do L.mask_ellipse(m, e[1], e[2], e[3], e[4], true) end
    L.mask_paint(L.img(spr), m, BLOT_INK)
    emit_grid(spr, "blot_12_" .. key, "blot", key)
  end
end

-- ---------------------------------------------------------------- 16. the manifest
-- icons/grid/icons.json: every file this generator wrote, with its role, key
-- and cell — what tests/unit/test_icons.gd walks and what Icons.SIZES must match.
do
  local roles = {
    { "class", 16 }, { "emote", 16 }, { "arrow", 16 }, { "lock", 16 }, { "blot", 12 }, { "log", 22 },
    { "state", 24 }, { "mech", 24 }, { "bar", 24 }, { "face", 24 }, { "control", 24 }, { "rank", 28 },
    { "building", 32 }, { "empty", 32 }, { "item", 32 }, { "furnishing", 32 }, { "slot", 32 }, { "sigil", 48 },
  }
  local rs = {}
  for _, r in ipairs(roles) do rs[#rs + 1] = string.format('    "%s": %d', r[1], r[2]) end
  local text = '{\n  "generator": "tools/aseprite/gen_icons.lua",\n  "dir": "game/assets/ui/icons/",\n  "roles": {\n'
    .. table.concat(rs, ",\n") .. '\n  },\n  "sheets": [\n' .. table.concat(SHEETS, ",\n")
    .. '\n  ],\n  "files": [\n' .. table.concat(MANIFEST, ",\n") .. '\n  ]\n}\n'
  L.write_text(GRID_OUT .. "icons.json", text)
end

print("GEN_ICONS OK")
