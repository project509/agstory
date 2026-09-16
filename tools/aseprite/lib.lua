-- lib.lua - drawing primitives shared by every gen_*.lua asset generator.
--
-- WHY THIS EXISTS: the reference concepts build their whole interface out of a
-- small number of repeated shapes - a rounded dark panel with a 1px border, an
-- inset well, a bevelled slot, a gradient plate with corner notches. Hand-drawing
-- each one in the Aseprite GUI would be slow AND unrepeatable; when the palette
-- moves, every asset must move with it. Generating them from code means the whole
-- kit is one `./tools/build_art.sh --gen` away from being correct again.
--
-- All colours are passed as "#RRGGBB" or "#RRGGBBAA" strings and converted here,
-- so generators read like a spec sheet rather than like bit twiddling.
--
-- Families, top to bottom: colour · pixels/gradients · rounded and chamfered
-- shapes · panel/inset composites · 9-slice · sprites and io (every save
-- honours `--script-param out=<dir>`, which is how build_art.sh --check
-- regenerates into a scratch dir and byte-compares) · masks and the derived
-- treatments (outline, rim, depth ramp, glow) · strokes (line, arc) · fills
-- (ellipse, polygon, ordered dither) · strips (real frames + tag + one-row PNG).
-- tools/aseprite/_libtest.lua draws one of each onto build/_libtest.png.
--
-- Load with:  local L = dofile("tools/aseprite/lib.lua")

local L = {}

-- ---------------------------------------------------------------- colour

--- "#RRGGBB" / "#RRGGBBAA" -> packed Aseprite RGBA.
function L.hex(s)
  s = s:gsub("#", "")
  local r = tonumber(s:sub(1, 2), 16)
  local g = tonumber(s:sub(3, 4), 16)
  local b = tonumber(s:sub(5, 6), 16)
  local a = #s >= 8 and tonumber(s:sub(7, 8), 16) or 255
  return app.pixelColor.rgba(r, g, b, a)
end

function L.rgba(r, g, b, a) return app.pixelColor.rgba(r, g, b, a or 255) end

local function chan(c)
  return app.pixelColor.rgbaR(c), app.pixelColor.rgbaG(c),
         app.pixelColor.rgbaB(c), app.pixelColor.rgbaA(c)
end
L.chan = chan

--- Linear blend, t in 0..1. Used for every gradient in the kit.
function L.mix(c1, c2, t)
  local r1, g1, b1, a1 = chan(c1)
  local r2, g2, b2, a2 = chan(c2)
  local function m(x, y) return math.floor(x + (y - x) * t + 0.5) end
  return app.pixelColor.rgba(m(r1, r2), m(g1, g2), m(b1, b2), m(a1, a2))
end

--- Source-over composite of `src` onto `dst`. drawPixel replaces rather than
--- blends, so anything with soft edges (glows, shadows) must come through here.
function L.over(dst, src)
  local sr, sg, sb, sa = chan(src)
  if sa == 255 then return src end
  if sa == 0 then return dst end
  local dr, dg, db, da = chan(dst)
  local a = sa / 255
  local outA = sa + da * (1 - a)
  if outA <= 0 then return app.pixelColor.rgba(0, 0, 0, 0) end
  local function m(s, d)
    return math.floor((s * sa + d * da * (1 - a)) / outA + 0.5)
  end
  return app.pixelColor.rgba(m(sr, dr), m(sg, dg), m(sb, db), math.floor(outA + 0.5))
end

-- ---------------------------------------------------------------- pixels

function L.px(img, x, y, c)
  if x < 0 or y < 0 or x >= img.width or y >= img.height then return end
  img:drawPixel(x, y, c)
end

--- Alpha-correct plot. Prefer this over px for anything non-opaque.
function L.blend(img, x, y, c)
  if x < 0 or y < 0 or x >= img.width or y >= img.height then return end
  img:drawPixel(x, y, L.over(img:getPixel(x, y), c))
end

function L.fill(img, x, y, w, h, c)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do L.px(img, xx, yy, c) end
  end
end

function L.fill_blend(img, x, y, w, h, c)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do L.blend(img, xx, yy, c) end
  end
end

--- Vertical gradient. The kit's panels, plates and bars are all lit from the
--- top, so this is the default; pass horizontal=true for the rare exception.
function L.grad(img, x, y, w, h, top, bottom, horizontal)
  local n = horizontal and w or h
  for i = 0, n - 1 do
    local t = n > 1 and (i / (n - 1)) or 0
    local c = L.mix(top, bottom, t)
    if horizontal then L.fill(img, x + i, y, 1, h, c)
    else L.fill(img, x, y + i, w, 1, c) end
  end
end

-- ---------------------------------------------------------------- shapes

--- Which pixels a rounded rect covers. Corners are quantised to the pixel grid
--- deliberately: the references have hard 1px corner steps, not antialiasing.
local function rr_inside(x, y, w, h, r)
  if r <= 0 then return true end
  local cx, cy
  if x < r then cx = r - 0.5 elseif x >= w - r then cx = w - r - 0.5 else return true end
  if y < r then cy = r - 0.5 elseif y >= h - r then cy = h - r - 0.5 else return true end
  local dx, dy = x + 0.5 - cx, y + 0.5 - cy
  return (dx * dx + dy * dy) <= (r + 0.10) * (r + 0.10)
end
L.rr_inside = rr_inside

function L.rrect_fill(img, x, y, w, h, r, c)
  for yy = 0, h - 1 do
    for xx = 0, w - 1 do
      if rr_inside(xx, yy, w, h, r) then L.blend(img, x + xx, y + yy, c) end
    end
  end
end

function L.rrect_grad(img, x, y, w, h, r, top, bottom)
  for yy = 0, h - 1 do
    local t = h > 1 and (yy / (h - 1)) or 0
    local c = L.mix(top, bottom, t)
    for xx = 0, w - 1 do
      if rr_inside(xx, yy, w, h, r) then L.blend(img, x + xx, y + yy, c) end
    end
  end
end

--- 1px-thick outline of a rounded rect: a pixel that is inside but has an
--- outside 4-neighbour. Inset > 0 draws the inner highlight line the panels use.
function L.rrect_border(img, x, y, w, h, r, c, inset)
  inset = inset or 0
  local function ins(xx, yy)
    return xx >= inset and yy >= inset and xx < w - inset and yy < h - inset
       and rr_inside(xx - inset, yy - inset, w - inset * 2, h - inset * 2, math.max(0, r - inset))
  end
  for yy = 0, h - 1 do
    for xx = 0, w - 1 do
      if ins(xx, yy) then
        if not (ins(xx - 1, yy) and ins(xx + 1, yy) and ins(xx, yy - 1) and ins(xx, yy + 1)) then
          L.blend(img, x + xx, y + yy, c)
        end
      end
    end
  end
end

--- Outer glow: N rings of decreasing alpha outside the shape. The reference
--- panels sit on a faint bloom rather than a hard cut, and this is that bloom.
function L.rrect_glow(img, x, y, w, h, r, c, spread, a0)
  local cr, cg, cb = chan(c)
  for s = spread, 1, -1 do
    local a = math.floor((a0 or 60) * (1 - (s - 1) / spread) * 0.6)
    if a > 0 then
      local gx, gy, gw, gh = x - s, y - s, w + s * 2, h + s * 2
      L.rrect_border(img, gx, gy, gw, gh, r + s, app.pixelColor.rgba(cr, cg, cb, a), 0)
    end
  end
end

--- The kit's signature bevelled corner: a 45-degree cut with a lit inner edge,
--- as seen on the "Send Them Anyway" CTA and the active nav tab.
function L.notch(img, x, y, w, h, size, bg, edge)
  local corners = {
    { x, y, 1, 1 }, { x + w - 1, y, -1, 1 },
    { x, y + h - 1, 1, -1 }, { x + w - 1, y + h - 1, -1, -1 },
  }
  for _, c in ipairs(corners) do
    local ox, oy, sx, sy = c[1], c[2], c[3], c[4]
    for i = 0, size - 1 do
      for j = 0, size - 1 - i do
        L.px(img, ox + sx * i, oy + sy * j, bg)
      end
      if edge then L.px(img, ox + sx * i, oy + sy * (size - i), edge) end
    end
  end
end

-- ---------------------------------------------------------------- chamfered shapes
-- The references' major panels, the CTA, the nav tab and the day chip all cut
-- their corners at 45 degrees instead of rounding them (art/ref/specs/06 and
-- the 6x corner montage taken 2026-09-09). `cut` is the size of the cut on each
-- axis; `which` is a table of corner flags {tl=,tr=,bl=,br=} defaulting to all.
local function ch_inside(x, y, w, h, cut, which)
  which = which or {}
  local function on(k) return which[k] ~= false end
  if on("tl") and x + y < cut then return false end
  if on("tr") and (w - 1 - x) + y < cut then return false end
  if on("bl") and x + (h - 1 - y) < cut then return false end
  if on("br") and (w - 1 - x) + (h - 1 - y) < cut then return false end
  return true
end
L.ch_inside = ch_inside

function L.chrect_fill(img, x, y, w, h, cut, c, which)
  for yy = 0, h - 1 do
    for xx = 0, w - 1 do
      if ch_inside(xx, yy, w, h, cut, which) then L.blend(img, x + xx, y + yy, c) end
    end
  end
end

--- Gradient fill inside a chamfered rect; vertical by default.
function L.chrect_grad(img, x, y, w, h, cut, top, bottom, horizontal, which)
  for yy = 0, h - 1 do
    for xx = 0, w - 1 do
      if ch_inside(xx, yy, w, h, cut, which) then
        local t = horizontal and (w > 1 and xx / (w - 1) or 0) or (h > 1 and yy / (h - 1) or 0)
        L.blend(img, x + xx, y + yy, L.mix(top, bottom, t))
      end
    end
  end
end

--- 1px outline of a chamfered rect, optionally inset. `sides` = {l=,t=,r=,b=}
--- lets a border omit an edge (the nav tab has no left rim: it bleeds off-screen).
function L.chrect_border(img, x, y, w, h, cut, c, inset, which, sides)
  inset = inset or 0
  sides = sides or {}
  local function side_on(k) return sides[k] ~= false end
  local function ins(xx, yy)
    return xx >= inset and yy >= inset and xx < w - inset and yy < h - inset
       and ch_inside(xx - inset, yy - inset, w - inset * 2, h - inset * 2, math.max(0, cut - inset), which)
  end
  for yy = 0, h - 1 do
    for xx = 0, w - 1 do
      if ins(xx, yy) then
        local l, r, u, d = ins(xx - 1, yy), ins(xx + 1, yy), ins(xx, yy - 1), ins(xx, yy + 1)
        local edge = false
        if not l and side_on("l") then edge = true end
        if not r and side_on("r") then edge = true end
        if not u and side_on("t") then edge = true end
        if not d and side_on("b") then edge = true end
        -- the diagonal pixels of a chamfer have an outside 4-neighbour on two
        -- sides; count them as edge when either of those sides is enabled
        if edge then L.blend(img, x + xx, y + yy, c) end
      end
    end
  end
end

--- A small round rivet — the nav tab and icon buttons carry one in a corner.
function L.rivet(img, cx, cy, c, hi)
  L.px(img, cx, cy, c); L.px(img, cx - 1, cy, c); L.px(img, cx + 1, cy, c)
  L.px(img, cx, cy - 1, c); L.px(img, cx, cy + 1, c)
  if hi then L.px(img, cx - 1, cy - 1, hi) end
end

-- ---------------------------------------------------------------- composites

--- The kit's base container: optional glow, gradient (or flat) fill, 1px border,
--- and an optional inner top highlight that sells the "lit from above" read.
--- opts = {radius, fill, fill_bottom, border, inner, glow, glow_spread, glow_alpha}
function L.panel(img, x, y, w, h, opts)
  local r = opts.radius or 4
  if opts.glow then
    L.rrect_glow(img, x, y, w, h, r, opts.glow, opts.glow_spread or 3, opts.glow_alpha or 60)
  end
  if opts.fill_bottom then
    L.rrect_grad(img, x, y, w, h, r, opts.fill, opts.fill_bottom)
  elseif opts.fill then
    L.rrect_fill(img, x, y, w, h, r, opts.fill)
  end
  if opts.inner then L.rrect_border(img, x, y, w, h, r, opts.inner, 1) end
  if opts.border then L.rrect_border(img, x, y, w, h, r, opts.border, 0) end
end

--- A recessed well: darker than its parent, with the light edge on the BOTTOM
--- instead of the top. That inversion is the only thing that makes it read as
--- carved in rather than raised.
function L.inset(img, x, y, w, h, opts)
  local r = opts.radius or 3
  L.rrect_fill(img, x, y, w, h, r, opts.fill)
  if opts.border then L.rrect_border(img, x, y, w, h, r, opts.border, 0) end
  if opts.lip then
    for xx = x + r, x + w - r - 1 do L.blend(img, xx, y + h - 1, opts.lip) end
  end
end

-- ---------------------------------------------------------------- 9-slice

--- Export a texture plus the 9-slice margins Godot's StyleBoxTexture needs.
--- Aseprite slices carry the 9-patch centre, so the margins survive the round
--- trip into build/atlas and nothing has to re-derive them by hand.
function L.add_nine_slice(spr, name, l, t, r, b)
  local s = spr:newSlice(Rectangle(0, 0, spr.width, spr.height))
  s.name = name
  s.center = Rectangle(l, t, spr.width - l - r, spr.height - t - b)
  return s
end

--- Sanity gate: a 9-slice whose corners overlap will smear when stretched.
function L.check_nine_slice(w, h, l, t, r, b)
  assert(l + r < w, string.format("9-slice h-margins %d+%d exceed width %d", l, r, w))
  assert(t + b < h, string.format("9-slice v-margins %d+%d exceed height %d", t, b, h))
end

-- ---------------------------------------------------------------- sprites/io

function L.new_sprite(w, h)
  local spr = Sprite(w, h, ColorMode.RGB)
  spr.cels[1].image:clear(app.pixelColor.rgba(0, 0, 0, 0))
  return spr
end

function L.img(spr) return spr.cels[1].image end

--- Every generator writes through save_png / save_ase / write_text, so ONE
--- prefix here redirects a whole run. `build_art.sh --check` passes
--- `--script-param out=build/artcheck`, regenerates everything under that
--- prefix and byte-compares it with the tree (verify.sh stage 2b). Generators
--- never know about it; a generator that writes a file by any other route is
--- invisible to the gate, so do not add one.
function L.out_path(path)
  local out = app.params and app.params["out"]
  if out and out ~= "" then
    out = out:gsub("[/\\]+$", "")
    return out .. "/" .. path
  end
  return path
end

--- Save a PNG, creating the directory if the caller has not.
function L.save_png(spr, path)
  path = L.out_path(path)
  local dir = path:match("^(.*)[/\\][^/\\]*$")
  if dir then app.fs.makeAllDirectories(dir) end
  spr:saveCopyAs(path)
  print(string.format("  %-58s %dx%d", path, spr.width, spr.height))
end

--- Save the editable .aseprite source. build_art.sh treats art/**/*.aseprite as
--- the source of truth, so generators must write one, not only a PNG.
function L.save_ase(spr, path)
  path = L.out_path(path)
  local dir = path:match("^(.*)[/\\][^/\\]*$")
  if dir then app.fs.makeAllDirectories(dir) end
  spr:saveAs(path)
  print(string.format("  %-58s %dx%d (source)", path, spr.width, spr.height))
end

--- A sidecar text file (faces.json). Binary mode so the bytes are the same on
--- every platform — the gate compares bytes, not lines.
function L.write_text(path, text)
  path = L.out_path(path)
  local dir = path:match("^(.*)[/\\][^/\\]*$")
  if dir then app.fs.makeAllDirectories(dir) end
  local f = assert(io.open(path, "wb"))
  f:write(text)
  f:close()
  print(string.format("  %-58s %d bytes", path, #text))
end

--- A PNG (a sliced reference crop, a hand-painted key frame) as an Image the
--- other primitives can read from and blit.
function L.import_png(path)
  local im = Image{ fromFile = path }
  assert(im, "import_png: cannot read " .. tostring(path))
  return im
end

--- Composite `src` onto `dst` at (x, y), alpha-correct. Transparent source
--- pixels are skipped, so a blit never punches holes.
function L.blit(dst, src, x, y)
  for sy = 0, src.height - 1 do
    for sx = 0, src.width - 1 do
      local c = src:getPixel(sx, sy)
      if app.pixelColor.rgbaA(c) > 0 then L.blend(dst, x + sx, y + sy, c) end
    end
  end
end

-- ---------------------------------------------------------------- masks
-- A mask is the shape before the shading: a flat table {w=, h=, [y*w+x] = v}
-- where v is false (outside) or any truthy tag — `true` for a silhouette, a
-- material name ("iron", "leather") when render_mask has to pick a ramp per
-- pixel. Outlines, rims, glows and depth are DERIVED from the mask, which is
-- what keeps every icon in a family under one treatment.

function L.mask_new(w, h)
  local m = { w = w, h = h }
  for i = 0, w * h - 1 do m[i] = false end
  return m
end

function L.mget(m, x, y)
  if x < 0 or y < 0 or x >= m.w or y >= m.h then return false end
  return m[y * m.w + x]
end

function L.mset(m, x, y, v)
  if x >= 0 and y >= 0 and x < m.w and y < m.h then m[y * m.w + x] = v end
end

function L.mask_rect(m, x, y, w, h, v)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do L.mset(m, xx, yy, v) end
  end
end

--- Filled ellipse centred (cx, cy) with radii rx, ry, in pixel units: a pixel
--- is inside when its centre (x+0.5, y+0.5) is. Pass v=false to erase.
function L.mask_ellipse(m, cx, cy, rx, ry, v)
  for y = math.floor(cy - ry), math.ceil(cy + ry) do
    for x = math.floor(cx - rx), math.ceil(cx + rx) do
      local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
      if dx * dx + dy * dy <= 1 then L.mset(m, x, y, v) end
    end
  end
end

--- Polygon by scanline, even-odd rule, sampled at pixel centres.
--- pts = {{x, y}, ...} in pixel space; concave shapes are fine.
function L.mask_poly(m, pts, v)
  local miny, maxy = m.h, 0
  for _, p in ipairs(pts) do miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2]) end
  for y = math.floor(miny), math.ceil(maxy) do
    local yc = y + 0.5
    local xs = {}
    local n = #pts
    for i = 1, n do
      local a, b = pts[i], pts[i % n + 1]
      if (a[2] <= yc and b[2] > yc) or (b[2] <= yc and a[2] > yc) then
        xs[#xs + 1] = a[1] + (yc - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
      end
    end
    table.sort(xs)
    for i = 1, #xs - 1, 2 do
      for x = math.floor(xs[i] + 0.5), math.ceil(xs[i + 1] - 0.5) - 1 do L.mset(m, x, y, v) end
    end
  end
end

--- Pixel spans {y, x0, x1} — the way gen_icons authors its glyphs, because a
--- span cannot be one character short the way ASCII art can.
function L.mask_spans(m, list, v)
  if v == nil then v = true end
  for _, s in ipairs(list) do
    for x = s[2], s[3] do L.mset(m, x, s[1], v) end
  end
end

--- Inside the mask with an outside 4-neighbour: the 1px outline ring.
function L.mask_is_edge(m, x, y)
  return L.mget(m, x, y) and not (L.mget(m, x - 1, y) and L.mget(m, x + 1, y)
                                and L.mget(m, x, y - 1) and L.mget(m, x, y + 1))
end

--- One pixel inside the outline ring: where the inner rim and the highlight go.
function L.mask_touches_edge(m, x, y)
  return L.mask_is_edge(m, x - 1, y) or L.mask_is_edge(m, x + 1, y)
      or L.mask_is_edge(m, x, y - 1) or L.mask_is_edge(m, x, y + 1)
end

function L.mask_bbox(m)
  local x0, y0, x1, y1 = m.w, m.h, -1, -1
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) then
        if x < x0 then x0 = x end; if x > x1 then x1 = x end
        if y < y0 then y0 = y end; if y > y1 then y1 = y end
      end
    end
  end
  return x0, y0, x1, y1
end

--- Paint every set pixel of a mask in one colour (silhouettes, glyph fills).
function L.mask_paint(img, m, c, ox, oy)
  ox, oy = ox or 0, oy or 0
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) then L.blend(img, ox + x, oy + y, c) end
    end
  end
end

--- Paint only the outline ring of a mask.
function L.mask_outline(img, m, c, ox, oy)
  ox, oy = ox or 0, oy or 0
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mask_is_edge(m, x, y) then L.blend(img, ox + x, oy + y, c) end
    end
  end
end

--- Depth = Chebyshev distance to the nearest outside pixel (1 = touching the
--- edge), searched within `reach` (default 3); deeper than that reads 99.
function L.depth_map(m, reach)
  reach = reach or 3
  local d = L.mask_new(m.w, m.h)
  for y = 0, m.h - 1 do
    for x = 0, m.w - 1 do
      if L.mget(m, x, y) then
        local best = 99
        for oy = -reach, reach do
          for ox = -reach, reach do
            if not L.mget(m, x + ox, y + oy) then
              local dist = math.max(math.abs(ox), math.abs(oy))
              if dist < best then best = dist end
            end
          end
        end
        d[y * m.w + x] = best
      end
    end
  end
  return d
end

local function col(v) return type(v) == "string" and L.hex(v) or v end

--- The item-icon treatment (the reference's own icons, measured): outside the
--- shape a 1px outline with a soft halo and a 1px drop shadow down-right;
--- inside, a ramp by depth (edge darkest, then two bevel steps, then the body)
--- with a top-to-bottom light falloff, deterministic grain, a rim light where
--- the up-left is open and a deep shadow where the down-right is.
---   ramp[tag] = {base=, dark=, deep=, rim=}   ("#RRGGBB" strings or packed)
---   opts = {outline=, halo=, shadow=, grain=function(tag)->amplitude, ox=, oy=}
--- Anything the treatment does not own (straps, studs, glints) is painted by
--- the caller afterwards.
function L.render_mask(img, m, ramp, opts)
  opts = opts or {}
  local ox, oy = opts.ox or 0, opts.oy or 0
  local outline, halo, shadow, grain = opts.outline, opts.halo, opts.shadow, opts.grain
  local W, H = m.w, m.h
  local mget = L.mget
  local d = L.depth_map(m)
  -- halo then outline
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if not mget(m, x, y) then
        local near1, near2 = false, false
        for dy = -2, 2 do
          for dx = -2, 2 do
            if mget(m, x + dx, y + dy) then
              if math.max(math.abs(dx), math.abs(dy)) == 1 then near1 = true else near2 = true end
            end
          end
        end
        if near1 then
          if outline then L.px(img, ox + x, oy + y, outline) end
        elseif near2 then
          if halo then L.blend(img, ox + x, oy + y, halo) end
        end
      end
    end
  end
  -- drop shadow: the reference icons sit a pixel proud of their well
  if shadow then
    for y = 0, H - 1 do
      for x = 0, W - 1 do
        if not mget(m, x, y) and mget(m, x - 1, y - 1) then L.blend(img, ox + x, oy + y, shadow) end
      end
    end
  end
  -- body
  local function noise(x, y)                          -- deterministic grain
    local n = math.sin(x * 12.9898 + y * 78.233) * 43758.5453
    return n - math.floor(n)
  end
  local cache = {}
  local function ramp_of(tag)
    local P = cache[tag]
    if not P then
      local R = assert(ramp[tag], "render_mask: no ramp for tag " .. tostring(tag))
      P = { base = col(R.base), dark = col(R.dark), deep = col(R.deep), rim = col(R.rim) }
      cache[tag] = P
    end
    return P
  end
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local tag = mget(m, x, y)
      if tag then
        local P = ramp_of(tag)
        local depth = d[y * W + x]
        local t = y / (H - 1)                              -- top-to-bottom light falloff
        local base, dark, deep, rim = P.base, P.dark, P.deep, P.rim
        local c
        if depth <= 1 then c = L.mix(dark, deep, 0.3 + 0.6 * t)
        elseif depth == 2 then c = L.mix(base, dark, 0.45 + 0.4 * t)
        elseif depth == 3 then c = L.mix(base, dark, 0.15 + 0.45 * t)
        else c = L.mix(L.mix(base, rim, 0.12), dark, 0.55 * t) end
        if grain then
          local g = (noise(x, y) - 0.5) * grain(tag)
          c = L.mix(c, g > 0 and rim or deep, math.abs(g))
        end
        -- a two-pixel bevel: rim light where the up-left is open, deep shadow
        -- where the down-right is
        local ul_open = not mget(m, x - 1, y - 1)
        local dr_open = not mget(m, x + 1, y + 1)
        if depth <= 1 and ul_open and not dr_open then c = rim
        elseif depth == 2 and not mget(m, x - 2, y - 2) and not dr_open then c = L.mix(c, rim, 0.45)
        elseif depth <= 1 and dr_open then c = deep
        elseif depth == 2 and not mget(m, x + 2, y + 2) then c = L.mix(c, deep, 0.5) end
        L.px(img, ox + x, oy + y, c)
      end
    end
  end
end

--- Soft outer glow around a mask: a 1px ring at a0, a 2px ring at a0/2. The
--- legendary rank sigil and every emissive glyph sit on one of these.
function L.glow_mask(img, ox, oy, m, c, a0)
  local r, g, b = L.chan(c)
  local function near(x, y, d)
    for yy = -d, d do
      for xx = -d, d do
        if L.mget(m, x + xx, y + yy) then return true end
      end
    end
    return false
  end
  for y = -2, m.h + 1 do
    for x = -2, m.w + 1 do
      if not L.mget(m, x, y) then
        if near(x, y, 1) then L.blend(img, ox + x, oy + y, L.rgba(r, g, b, a0))
        elseif near(x, y, 2) then L.blend(img, ox + x, oy + y, L.rgba(r, g, b, math.floor(a0 / 2))) end
      end
    end
  end
end

-- ---------------------------------------------------------------- strokes
-- Lines and arcs collect their pixels into a set first and paint each once,
-- so a translucent stroke never double-blends where a thick brush overlaps.

local function round(v) return math.floor(v + 0.5) end

local function brush(set, x, y, thick)
  local half = math.floor((thick - 1) / 2)
  for oy = -half, -half + thick - 1 do
    for ox = -half, -half + thick - 1 do
      set[(x + ox) .. "," .. (y + oy)] = true
    end
  end
end

local function paint_set(img, set, c)
  for k, _ in pairs(set) do
    local x, y = k:match("^(-?%d+),(-?%d+)$")
    L.blend(img, tonumber(x), tonumber(y), c)
  end
end

--- Bresenham line, `thick` px square brush (default 1). Endpoints are pixel
--- coordinates and are rounded, so a diagonal stays 1px stepped, never soft.
function L.line(img, x0, y0, x1, y1, c, thick)
  thick = thick or 1
  x0, y0, x1, y1 = round(x0), round(y0), round(x1), round(y1)
  local set = {}
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    brush(set, x0, y0, thick)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
  paint_set(img, set, c)
end

--- Arc of radius r about pixel (cx, cy) from a0 to a1 degrees, sweeping
--- clockwise on screen (0 = 3 o'clock, 90 = 6 o'clock, since y grows down).
--- A slash crescent is an arc with `thick` 2-3; a full ring is 0..360.
function L.arc(img, cx, cy, r, a0, a1, c, thick)
  thick = thick or 1
  if a1 < a0 then a1 = a1 + 360 end
  local set = {}
  local steps = math.max(1, math.ceil((a1 - a0) / 360 * 2 * math.pi * r * 2))
  for i = 0, steps do
    local a = math.rad(a0 + (a1 - a0) * i / steps)
    brush(set, round(cx + math.cos(a) * r), round(cy + math.sin(a) * r), thick)
  end
  paint_set(img, set, c)
end

function L.circle(img, cx, cy, r, c, thick) L.arc(img, cx, cy, r, 0, 360, c, thick) end

--- Filled ellipse straight onto the image; same inside rule as mask_ellipse.
function L.ellipse_fill(img, cx, cy, rx, ry, c)
  for y = math.floor(cy - ry), math.ceil(cy + ry) do
    for x = math.floor(cx - rx), math.ceil(cx + rx) do
      local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
      if dx * dx + dy * dy <= 1 then L.blend(img, x, y, c) end
    end
  end
end

--- Filled polygon straight onto the image (mask_poly's rule).
function L.poly_fill(img, pts, c)
  local m = L.mask_new(img.width, img.height)
  L.mask_poly(m, pts, true)
  L.mask_paint(img, m, c)
end

-- ---------------------------------------------------------------- dither
-- Ordered dither between two colours: the pixel-art way to fade without a
-- new colour per row. `t` is the share of `b` (0 = all a, 1 = all b);
-- pattern = "bayer4" (default), "checker", or function(x, y) -> threshold
-- in 0..1. Thresholds are read at IMAGE coordinates so adjacent fills tile.
local BAYER4 = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }

local function threshold_fn(pattern)
  if type(pattern) == "function" then return pattern end
  if pattern == "checker" then return function(x, y) return ((x + y) % 2) * 0.5 end end
  return function(x, y) return (BAYER4[y % 4 + 1][x % 4 + 1] + 0.5) / 16 end
end

function L.dither_fill(img, x, y, w, h, a, b, t, pattern)
  local thr = threshold_fn(pattern)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do
      L.blend(img, xx, yy, thr(xx, yy) < t and b or a)
    end
  end
end

--- A dithered gradient a -> b, vertical by default (the kit is lit from the top).
function L.dither_grad(img, x, y, w, h, a, b, horizontal, pattern)
  local thr = threshold_fn(pattern)
  local n = horizontal and w or h
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do
      local i = horizontal and (xx - x) or (yy - y)
      local t = n > 1 and (i / (n - 1)) or 0
      L.blend(img, xx, yy, thr(xx, yy) < t and b or a)
    end
  end
end

-- ---------------------------------------------------------------- strips
--- An animation strip authored as REAL frames: the .aseprite carries n frames,
--- a tag and per-frame durations (so the GUI and pixel-mcp open it as an
--- animation), and the runtime PNG is the same n frames side by side, left to
--- right, which is what SceneStage._strip_frames() cuts. `frame_w` stays the
--- CONSUMER's declaration (scenes/*.json, actors.json) — the PNG carries no
--- sidecar. paint(frame_img, i) draws frame i (0-based, in order, so a seeded
--- generator draws the same pixels every run).
---   opts = {tag="burn", src_dir="art/src/vfx/", out_dir="game/assets/vfx/", save=true}
--- Returns a copy of the composed strip Image (for contact sheets).
function L.strip(name, w, h, n, fps, paint, opts)
  opts = opts or {}
  local src_dir = opts.src_dir or "art/src/vfx/"
  local out_dir = opts.out_dir or "game/assets/vfx/"
  local clear = app.pixelColor.rgba(0, 0, 0, 0)
  local spr = L.new_sprite(w, h)
  local layer = spr.layers[1]
  for i = 2, n do spr:newEmptyFrame(i) end
  local imgs = {}
  for i = 1, n do
    local cel = layer:cel(i) or spr:newCel(layer, i)
    cel.image:clear(clear)
    imgs[i - 1] = cel.image
  end
  for i = 0, n - 1 do paint(imgs[i], i) end
  for i = 1, n do spr.frames[i].duration = 1 / fps end
  local tag = spr:newTag(1, n)
  tag.name = opts.tag or "loop"
  tag.aniDir = AniDir.FORWARD
  -- the runtime PNG: one row, every frame `w` wide
  local sheet = L.new_sprite(w * n, h)
  local simg = L.img(sheet)
  for i = 0, n - 1 do
    local fi = imgs[i]
    for y = 0, h - 1 do
      for x = 0, w - 1 do simg:drawPixel(i * w + x, y, fi:getPixel(x, y)) end
    end
  end
  if opts.save ~= false then
    L.save_ase(spr, src_dir .. name .. ".aseprite")
    L.save_png(sheet, out_dir .. name .. ".png")
  end
  local result = Image(simg)
  spr:close()
  sheet:close()
  return result
end

return L
