extends RefCounted
## Font resources for the whole interface. art/ref/specs/05-typography.md owns
## the faces, weights and OpenType features; this file only hands them out.
##
## Two faces: Grenze Gotisch for the wordmark alone, Fira Sans for everything
## else (Regular for body and labels, Medium for names and values, SemiBold for
## section titles, the CTA and the big figures). Both are OFL — the licences
## ship beside the files in game/assets/fonts/.
##
## Plus one bitmap font: the ten morale faces (HALL-05, CRITIC-C09). A Label
## whose text carries a morale glyph keeps that glyph in `Label.text` — every
## test reads it there, the emoji-free option swaps it for pips there, and
## `Cards.morale_glyph` stays the one door that decides it — but the CHARACTER
## is drawn from game/assets/ui/faces.png instead of the system's colour-emoji
## font, so the roster, the strip and the log show the authored 24px pixel face.
## A font fallback is the only route that keeps every one of those contracts.
##
## Loaded lazily and cached, so tests and tools that never draw text pay nothing
## and a missing font is a runtime error at the first label, not a parse error
## in every script that mentions this file.

const DIR := "res://game/assets/fonts/"

## Q17 (00-plan §6): docs/12 §5.2's reading of canon's emoji notation as sprite
## art is PROPOSED. `true` draws the authored faces; `false` restores the
## system emoji with no other change — the text is the same either way.
const MORALE_FACE_FONT := true

## The sheet gen_icons.lua writes: ten 24x24 frames left to right, band 0..9,
## the same order as faces.json's `frames`. The 24px face is drawn at its
## native size in every Label (fixed_size, scale mode DISABLE — a scaled bitmap
## blurs), which is why there is one sheet PER TEXT SCALE (HALL-05, CRITIC-C09,
## W4-PIP): at 125 / 150 the same generator's faces_30 / faces_36 are the
## fallback, so a face on a line that grew keeps pace with the line. The three
## sizes are `Type.at(FACE_SIZE, scale)`; this file does not read Type, so
## tests/unit/test_pip_figure.gd pins the table to that arithmetic.
const FACES := "res://game/assets/ui/faces.png"
const FACE_SIZE := 24
const FACE_SHEETS := {
	100: "res://game/assets/ui/faces.png",
	125: "res://game/assets/ui/faces_30.png",
	150: "res://game/assets/ui/faces_36.png",
}
const FACE_SIZE_AT := {100: 24, 125: 30, 150: 36}
## The face sits 19 above and 5 below the baseline: on a 20px morale line
## (Fira Sans ascent ~18.7) the line height does not move; on a 15px body line
## it grows to what a colour emoji already cost. The larger sheets keep the
## same proportion (19/24 of the face above the baseline, rounded).
const FACE_ASCENT := 19
const FACE_ASCENT_AT := {24: 19, 30: 24, 36: 29}

## The ten code points, band 0..9, in faces.png's frame order. This is the same
## list as the sim's morale-band glyph table; tests/unit/test_theme_kit.gd pins
## the two equal, and this file does not read the table by name because
## tools/lint_motion.sh reserves that name for the one display door
## (Cards.morale_glyph) — a font maps characters to pixels, it never chooses one.
const FACE_GLYPHS := ["🤬", "😡", "😞", "😒", "😐", "🙂", "😄", "😊", "❤", "💖"]

static var _cache: Dictionary = {}


static func _file(name: String) -> Font:
	if not _cache.has(name):
		_cache[name] = load(DIR + name)
	return _cache[name]


static func ui() -> Font:
	return _file("FiraSans-Regular.ttf")


static func ui_medium() -> Font:
	return _file("FiraSans-Medium.ttf")


static func ui_semibold() -> Font:
	return _file("FiraSans-SemiBold.ttf")


static func ui_italic() -> Font:
	return _file("FiraSans-Italic.ttf")


## Tabular lining figures. docs/13 §4.3's numeral rule survives the repaint:
## every stacked numeric — HP, gold, the morale column — uses this so digits
## line up in columns. `weight` picks 400 / 500 / 600.
static func ui_tabular(weight: int = 500) -> Font:
	var key := "tnum_%d" % weight
	if not _cache.has(key):
		var v := FontVariation.new()
		if weight >= 600:
			v.base_font = ui_semibold()
		elif weight >= 500:
			v.base_font = ui_medium()
		else:
			v.base_font = ui()
		var ts := TextServerManager.get_primary_interface()
		v.opentype_features = {ts.name_to_tag("tnum"): 1}
		_cache[key] = v
	return _cache[key]


## The wordmark face at the reference's weight (05 §1.1: wght 600).
static func display() -> Font:
	if not _cache.has("display"):
		var v := FontVariation.new()
		v.base_font = _file("GrenzeGotisch.ttf")
		var ts := TextServerManager.get_primary_interface()
		v.variation_opentype = {ts.name_to_tag("wght"): 600}
		_cache["display"] = v
	return _cache["display"]


# ---------------------------------------------------------------- the faces

## The bitmap font: ten glyphs cut from faces.png. Built once. A bitmap
## FontFile's glyph index IS the code point (that is how Godot's own .fnt
## loader works), so the text server finds "❤" in it by the character alone.
## This is the 100% sheet; `faces_at(scale)` is the door the theme uses.
static func faces() -> FontFile:
	return faces_at(100)


## The face font for one of docs/13 §4.4's three text scales: 24px at 100, the
## 30px sheet at 125, the 36px sheet at 150 (HALL-05 / CRITIC-C09's "the same
## face must serve the strip, the cards and the combat status row" at every
## scale). An unknown scale is 100, which is `Type.step`'s own recovery. One
## FontFile per size, cached; `faces()` and `faces_at(100)` are the same object.
static func faces_at(scale: int = 100) -> FontFile:
	var size: int = int(FACE_SIZE_AT.get(scale, FACE_SIZE))
	var key := "faces" if size == FACE_SIZE else "faces_%d" % size
	if _cache.has(key):
		return _cache[key]
	var sheet := String(FACE_SHEETS.get(scale, FACES))
	var f := _face_font(sheet, size, int(FACE_ASCENT_AT.get(size, FACE_ASCENT)))
	_cache[key] = f
	return f


## One face font from one sheet: ten `size`-square frames left to right.
static func _face_font(sheet: String, size: int, ascent: int) -> FontFile:
	var f := FontFile.new()
	f.fixed_size = size
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_DISABLE
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.allow_system_fallback = false  # ten faces, nothing else, ever
	var key := Vector2i(size, 0)
	var tex: Texture2D = load(sheet)
	var img: Image = tex.get_image() if tex != null else null
	if img != null:
		if img.is_compressed():
			img.decompress()
		f.set_texture_image(0, key, 0, img)
		f.set_cache_ascent(0, size, ascent)
		f.set_cache_descent(0, size, size - ascent)
		for band in FACE_GLYPHS.size():
			var glyph: int = String(FACE_GLYPHS[band]).unicode_at(0)
			f.set_glyph_texture_idx(0, key, glyph, 0)
			f.set_glyph_uv_rect(0, key, glyph, Rect2(band * size, 0, size, size))
			f.set_glyph_size(0, key, glyph, Vector2(size, size))
			f.set_glyph_offset(0, key, glyph, Vector2(0, -ascent))
			f.set_glyph_advance(0, size, glyph, Vector2(size, 0))
	return f


## `base` with the faces as its first fallback — the font a glyph-carrying
## variation (LabelMorale, LabelLog, LabelBody, LabelClass) is built on. The
## base font itself is never modified: it is shared by every other variation.
## With MORALE_FACE_FONT off this is `base`, untouched.
##
## The variation stands on a COPY of the base's FontFile with system fallback
## switched off. This engine sends an Emoji_Presentation character (nine of
## the ten faces are astral emoji; only "❤" is text-presentation) to the
## system's colour-emoji font BEFORE it consults a non-colour fallback, as long
## as the first font in the list permits system fallback — so with the shared
## Fira Sans as the base only the heart ever came from faces.png (review
## W1-CHROME F3). With the copy's `allow_system_fallback` off the text server
## walks the list — Fira Sans, then the faces — and every face is drawn from
## the sheet. The cost is that these four variations no longer borrow a
## system glyph for a character neither font carries; tests/unit/
## test_theme_kit.gd pins every non-ASCII character the interface's Labels use
## to Fira Sans's own cmap, so nothing the game prints becomes a .notdef box.
##
## `scale` picks the sheet (`faces_at`): the theme built for 125 / 150 hands
## its scale in and gets the 30 / 36px faces behind the same copy of Fira Sans.
static func with_faces(base: Font, scale: int = 100) -> Font:
	if not MORALE_FACE_FONT:
		return base
	var key := "faces_on_%d" % base.get_instance_id()
	if scale != 100:
		key += "_at_%d" % scale
	if not _cache.has(key):
		var v: FontVariation
		if base is FontVariation:
			# ui_tabular: keep its tnum feature, swap the file underneath.
			v = (base as FontVariation).duplicate()
			v.base_font = _no_system_fallback((base as FontVariation).base_font)
		else:
			v = FontVariation.new()
			v.base_font = _no_system_fallback(base)
		v.fallbacks = [faces_at(scale)]
		_cache[key] = v
	return _cache[key]


## A private copy of `file` that never borrows a system font. Cached per
## source so the four face-carrying variations share one copy of Fira Sans
## Regular and one of Medium. A font that is not a FontFile (nothing today)
## is returned as it is.
static func _no_system_fallback(file: Font) -> Font:
	if not (file is FontFile):
		return file
	var key := "no_system_fallback_%d" % file.get_instance_id()
	if not _cache.has(key):
		var copy: FontFile = (file as FontFile).duplicate()
		copy.allow_system_fallback = false
		_cache[key] = copy
	return _cache[key]


# ---------------------------------------------------------------- the pips

## CRITIC-G09. With emoji-free on the glyph is the ten-character figure
## `"|||||....."` (GameSettings.morale_glyph), whose LENGTH is the band — a
## reading that needs no colour — and Fira Sans sets "|" nearly twice as wide
## as "." (9px against 4.8px at 20px; 6 against 3.1 at 13px), so the figure
## was uneven and the count hard to take in at a glance. The bar is now a
## glyph of its own: a one-character bitmap font that sits IN FRONT of Fira
## Sans in the morale variations and draws "|" as a plain pixel bar with
## exactly the advance Fira gives "." at the same size. The dot stays Fira's
## own period (prose keeps its period), and no displayed string in the game
## carries a "|" except the figure (grep, 2026-09-15), so nothing else changes.
## The string is still the string, in Label.text, and `Cards.morale_glyph` is
## still the one door that chooses it: a font maps a character to pixels.
##
## Multi-size: `fixed_size` 0 keys the glyph caches by the REQUESTED size, so
## one FontFile per Fira weight carries a bar at every size the theme
## registers through `with_pips`, and a size nobody registered shapes to Fira's
## own bar rather than to nothing. The price: `Font.has_char` and
## `get_char_size` consult one default cache and do not see the bar — measure
## it by shaping (`get_string_size`, the text server), as a Label does.
##
## The bar's geometry (px): width 1 / 2 / 3 by size band, height ~ Fira's cap
## height (0.69 em), standing on the baseline, centred in the advance.
const PIP_BAR := "|"
const PIP_CAP_HEIGHT := 0.69
## A size at which the text server reports fractional advances (it rounds
## above 20px); the period's em fraction is read here and scaled.
const PIP_MEASURE_SIZE := 16


## The pip-bar font for `file` (one of the shared Fira FontFiles), cached per
## file because the period's advance differs by weight — and per
## `system_fallback`: the first font in a variation decides whether the
## system's fonts are consulted at all (see with_faces), so the bar font that
## stands in front of the face sheet says never, and the one that stands in
## front of the bare, shared Fira Sans (LabelPip) says what Fira says.
static func _pip_font(file: Font, system_fallback: bool) -> FontFile:
	var key := "pips_%d_%s" % [file.get_instance_id(), "open" if system_fallback else "closed"]
	if not _cache.has(key):
		var pip := FontFile.new()
		pip.fixed_size = 0
		pip.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		# AUTO, as Fira's: fractional advances up to 20px and a rounded running
		# position above, so the bars are positioned by the same rule as the
		# dots at every size. (A bitmap glyph is drawn on whole pixels either
		# way; the shifted-index variants are a dynamic-font affair.)
		pip.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		pip.allow_system_fallback = system_fallback
		_cache[key] = pip
	return _cache[key]


## The advance Fira gives "." at `size`, in the text server's own 26.6 units.
##
## Read off a SHAPED glyph (not `get_string_size`, which rounds up: 3.125
## reads as 4 at 13px) at PIP_MEASURE_SIZE, where the server keeps advances
## fractional, then scaled: above 20px it rounds every advance it reports —
## the running position, not each glyph, so a 5.52px period lays out as
## 6, 5, 6, 5 … — and a bar registered with that ROUNDED 6 would drift half a
## pixel per pip against the dots. Registered raw, the bars round the same way
## the dots do. `features` are the variation's OpenType features, so a
## tabular base is measured as it is set. Cached per file and feature set.
static func _period_advance(file: Font, size: int, features: Dictionary) -> float:
	var key := "period_em_%d_%s" % [file.get_instance_id(), str(features)]
	if not _cache.has(key):
		var ts := TextServerManager.get_primary_interface()
		var rid: RID = ts.create_shaped_text()
		ts.shaped_text_add_string(rid, ".", file.get_rids(), PIP_MEASURE_SIZE, features)
		ts.shaped_text_shape(rid)
		var advance := 0.0
		for g in ts.shaped_text_get_glyphs(rid):
			advance += float(g["advance"])
		ts.free_rid(rid)
		_cache[key] = advance / float(PIP_MEASURE_SIZE)
	return floor(float(_cache[key]) * size * 64.0 + 0.5) / 64.0


## Register the bar at `size` in `pip`: a white-on-alpha LA8 bar the Label's
## font colour modulates (an RGBA8 texture would be drawn as a colour glyph,
## the way the faces are). The size's ascent and descent are Fira's own at
## that size: the bar font stands where the text font stood in the variation,
## and a screen that measures a line by its base font (Guildhall's strip
## pitch, `_line_h`) must read the text's height, not a bitmap's zero.
static func _register_pip(pip: FontFile, file: Font, size: int, features: Dictionary) -> void:
	var key := Vector2i(size, 0)
	var glyph: int = PIP_BAR.unicode_at(0)
	if pip.get_size_cache_list(0).has(key) and pip.get_glyph_list(0, key).has(glyph):
		return
	var advance := _period_advance(file, size, features)
	var w: int = 1 if size < 18 else (2 if size < 28 else 3)
	var h: int = maxi(2, int(round(size * PIP_CAP_HEIGHT)))
	var img := Image.create(w + 2, h + 2, false, Image.FORMAT_LA8)
	img.fill(Color(1, 1, 1, 0))
	img.fill_rect(Rect2i(1, 1, w, h), Color(1, 1, 1, 1))
	pip.set_texture_image(0, key, 0, img)
	pip.set_cache_ascent(0, size, file.get_ascent(size))
	pip.set_cache_descent(0, size, file.get_descent(size))
	pip.set_glyph_texture_idx(0, key, glyph, 0)
	pip.set_glyph_uv_rect(0, key, glyph, Rect2(1, 1, w, h))
	pip.set_glyph_size(0, key, glyph, Vector2(w, h))
	pip.set_glyph_offset(0, key, glyph, Vector2(floor((advance - w) / 2.0), -h))
	pip.set_glyph_advance(0, size, glyph, Vector2(advance, 0))


## THE MORALE LINE'S FONT: `base` (Fira Sans, plain or tabular) with the pip
## bar in front of it and the text scale's face sheet behind it, at `size`
## (the theme's already-scaled pixel size, so the bar is registered for the
## size the Label will ask for). Cached per base and scale; sizes accumulate on
## the shared pip font, so two variations on one base at two sizes share one
## variation object and both shape evenly.
##
## The shape is with_faces' with one more font in front:
##   pip bar → a copy of the base's file with system fallback off → the faces
## (`with_faces` itself is unchanged; tests/unit/test_theme_kit.gd pins it.)
## With MORALE_FACE_FONT off (Q17), or `faces` false, the sheet is dropped and
## the base's own file, system fallback and all, stands behind the bar.
##
## `faces` false is LabelPip's shape: the bar and nothing else. A font's line
## height is its tallest font, and the sheet is 24 / 30 / 36 tall, so a
## variation that carries it is that tall whether or not a face is on the
## line — right for the four variations HALL-05 named, which already paid it,
## and wrong for the small seat-card line the Tavern prints at SMALL: at 150
## the 36px sheet under a 20px line pushed a card's button off its plate
## (report-W4-PIP, batch 6). So LabelPip is LabelSmall's exact height at
## every scale and, with the option off, draws the character LabelSmall
## draws today; the authored face on that line is the screen owner's call.
static func with_pips(base: Font, size: int, scale: int = 100, faces: bool = true) -> Font:
	var file: Font = (base as FontVariation).base_font if base is FontVariation else base
	var features: Dictionary = (base as FontVariation).opentype_features if base is FontVariation else {}
	var faced: bool = faces and MORALE_FACE_FONT
	var pip := _pip_font(file, not faced)
	_register_pip(pip, file, size, features)
	# No sheet, no scale: one bare variation serves every theme.
	var key := "pips_on_%d_bare" % base.get_instance_id()
	if faced:
		key = "pips_on_%d_at_%d" % [base.get_instance_id(), scale]
	if not _cache.has(key):
		var v := FontVariation.new()
		v.base_font = pip
		if base is FontVariation:
			v.opentype_features = features
			v.variation_opentype = (base as FontVariation).variation_opentype
		if faced:
			v.fallbacks = [_no_system_fallback(file), faces_at(scale)]
		else:
			v.fallbacks = [file]
		_cache[key] = v
	return _cache[key]
