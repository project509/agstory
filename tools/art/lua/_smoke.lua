-- Smoke test: can we create, draw, palette, and export from the CLI?
local spr = Sprite(32, 32, ColorMode.RGB)
spr.filename = "smoke.aseprite"
local img = spr.cels[1].image
for y = 0, 31 do
  for x = 0, 31 do
    img:drawPixel(x, y, app.pixelColor.rgba(x * 8 % 256, y * 8 % 256, 128, 255))
  end
end
-- 9-slice style border test
local function rect(im, x0, y0, w, h, c)
  for x = x0, x0 + w - 1 do im:drawPixel(x, y0, c); im:drawPixel(x, y0 + h - 1, c) end
  for y = y0, y0 + h - 1 do im:drawPixel(x0, y, c); im:drawPixel(x0 + w - 1, y, c) end
end
rect(img, 0, 0, 32, 32, app.pixelColor.rgba(255, 200, 80, 255))
-- second frame, to prove animation authoring works
spr:newEmptyFrame()
app.command.SaveFileCopyAs { filename = "smoke_out.png" }
print("ASEPRITE_LUA_OK frames=" .. #spr.frames .. " size=" .. spr.width .. "x" .. spr.height)
