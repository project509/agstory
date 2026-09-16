extends "res://tests/TestCase.gd"
## W4-PIP (00-plan.md §5): the emoji-free figure is even, and the faces scale.
## CRITIC-G09 — the ten-pip string "|||||....." is a LENGTH (the band without
## colour), and Fira Sans set "|" nearly twice as wide as ".", so the length
## lied. HALL-05 / CRITIC-C09 — the 24px face sheet served every text scale;
## at 125 / 150 the 30 / 36px sheets do.
##
## Static and pure: nothing here mounts a screen or touches an autoload. Every
## claim about a glyph is proved by SHAPING it through the theme's own font and
## reading what the text server gave back (which font, what advance) — not by
## asserting that a property was set (LESSONS: built vs armed).

const Theme_ = preload("res://game/ui/Theme.gd")
const Fonts = preload("res://game/ui/Fonts.gd")
const Type = preload("res://game/ui/Type.gd")
const Enums = preload("res://sim/model/Enums.gd")

## Every variation that carries the pip string today (grep Cards.morale_glyph(
## 2026-09-15: LabelMorale x6, LabelBody x1 via Widgets.body) plus the two the
## kit gives the glyph (LabelLog, LabelClass) and the small line handoff-W4-PIP
## moves the Tavern's seat card onto.
const PIP_VARIATIONS := ["LabelPip", "LabelMorale", "LabelBody", "LabelLog", "LabelClass"]
## The four of them that also carry the face sheet (HALL-05's list). LabelPip
## does not: the sheet sets a variation's line height (24 / 30 / 36) whether
## or not a face is on the line, and the Tavern's seat card has no room for
## that at 150 (report-W4-PIP, batch 6) — so LabelPip is LabelSmall plus the
## bar, and draws what LabelSmall draws when the option is off.
const FACE_VARIATIONS := ["LabelMorale", "LabelBody", "LabelLog", "LabelClass"]

## The text server keeps advances fractional up to 20px and rounds the RUNNING
## position above that (a 7.2px period lays out as 7, 7, 8, 7, 7 …), and the
## bar font, registered with the same raw advance, rounds the same way. So one
## glyph's reported advance can differ from the raw pitch by up to a pixel,
## and a position by a pixel where the bar run hands over to the dot run.
## "Even" is asserted the way a pixel can be even: every pip within one pixel
## of k × pitch; and a single bar against a single dot — both roundings of the
## same raw number — within half a pixel.
const HALF_PX := 0.5001
const ONE_PX := 1.0001


## Shape `text` through `font` at `size` exactly as a Label does (the font's
## own OpenType features included) and return [font_rid, advance, index] per glyph.
func _shaped(font: Font, text: String, size: int) -> Array:
    var ts := TextServerManager.get_primary_interface()
    var rid: RID = ts.create_shaped_text()
    ts.shaped_text_add_string(rid, text, font.get_rids(), size, font.get_opentype_features())
    ts.shaped_text_shape(rid)
    var out: Array = []
    for g in ts.shaped_text_get_glyphs(rid):
        out.append([g["font_rid"], float(g["advance"]), int(g["index"])])
    ts.free_rid(rid)
    return out


func _width(font: Font, text: String, size: int) -> float:
    var w := 0.0
    for g in _shaped(font, text, size):
        w += g[1]
    return w


## The pitch of Fira Sans's own period at `size`: the mean advance over a run
## of ten, which is the raw 0.24 em regardless of how the server rounds one.
func _pitch(font: Font, size: int) -> float:
    return _width(font, ".".repeat(Enums.MORALE_BAND_COUNT), size) / float(Enums.MORALE_BAND_COUNT)


## The pip string exactly as GameSettings.morale_glyph builds it for `band`
## (tests/unit/test_screens.gd:856-931 pins that door; this file does not touch
## the autoload, because a freshly made GameSettings writes user://settings.cfg
## when it dies).
func _pips(band: int) -> String:
    return "|".repeat(band + 1) + ".".repeat(Enums.MORALE_BAND_COUNT - band - 1)


# ------------------------------------------------------------------ the figure

func test_label_pip_sets_bar_and_dot_at_one_advance() -> void:
    # The plan's acceptance line, verbatim: the LabelPip font's "|" and "."
    # advances are equal — at every text scale the theme can be built for.
    # Fira Sans alone sets them 6 against 3.1 at 13px (CRITIC-G09's uneven
    # figure); that gap is asserted too, so this test cannot pass on a theme
    # that dropped the bar font.
    for scale in Type.SCALES:
        var t: Theme = Theme_.get_theme(int(scale))
        var font: Font = t.get_font("font", "LabelPip")
        var size: int = t.get_font_size("font_size", "LabelPip")
        var bar := _width(font, "|", size)
        var dot := _width(font, ".", size)
        assert_true(bar > 0.0, "the bar has an advance at %d" % scale)
        assert_almost(bar, dot, HALF_PX, "LabelPip at %d: | is %.3f, . is %.3f" % [scale, bar, dot])
        var fira_bar := _width(Fonts.ui(), "|", size)
        assert_true(fira_bar - dot > ONE_PX,
            "Fira Sans's own bar (%.3f) is what the figure used to be set in" % fira_bar)


func test_every_morale_variation_sets_the_ten_pip_figure_evenly() -> void:
    # Ten characters, one pitch: for every band, in every variation that
    # prints the figure, at every scale, each pip stands within a pixel of
    # k × the period's pitch, and no glyph is off that pitch by more than the
    # half-pixel the server's rounding allows any glyph.
    for scale in Type.SCALES:
        var t: Theme = Theme_.get_theme(int(scale))
        for name in PIP_VARIATIONS:
            var font: Font = t.get_font("font", name)
            var size: int = t.get_font_size("font_size", name)
            var pitch := _pitch(font, size)
            assert_true(pitch > 2.0, "%s at %d: a period is wider than two pixels" % [name, scale])
            assert_almost(_width(font, "|", size), _width(font, ".", size), HALF_PX,
                "%s at %d: bar vs dot" % [name, scale])
            for band in Enums.MORALE_BAND_COUNT:
                var figure := _pips(band)
                assert_eq(figure.length(), Enums.MORALE_BAND_COUNT)
                var x := 0.0
                var k := 0
                for g in _shaped(font, figure, size):
                    k += 1
                    x += g[1]
                    assert_almost(g[1], pitch, ONE_PX,
                        "%s at %d, band %d: pip %d of '%s' is %.3f wide on a %.3f pitch" % [name, scale, band, k, figure, g[1], pitch])
                    assert_almost(x, pitch * k, ONE_PX,
                        "%s at %d, band %d: pip %d of '%s' ends at %.3f, not %.3f" % [name, scale, band, k, figure, x, pitch * k])
                assert_eq(k, Enums.MORALE_BAND_COUNT, "ten glyphs, one per character")


func test_the_bar_is_the_pip_font_s_and_the_dot_stays_fira_sans() -> void:
    # The mechanism, by shape: "|" is drawn by the one-glyph bar font that
    # stands in front of Fira Sans (the variation's base), "." and the letters
    # by the copy of Fira Sans behind it, the face by the sheet.
    var t: Theme = Theme_.get_theme()
    for name in PIP_VARIATIONS:
        var faced: bool = FACE_VARIATIONS.has(name)
        var font: Font = t.get_font("font", name)
        var size: int = t.get_font_size("font_size", name)
        assert_true(font is FontVariation, "%s is a variation" % name)
        var v := font as FontVariation
        assert_true(v.base_font is FontFile, "%s stands on the bar font" % name)
        assert_eq((v.base_font as FontFile).fixed_size, 0, "%s: the bar font is multi-size" % name)
        if faced:
            assert_false((v.base_font as FontFile).allow_system_fallback,
                "%s: the first font forbids system fallback, so the faces are drawn from the sheet" % name)
            assert_eq(v.fallbacks.size(), 2, "%s: the Fira copy, then the sheet" % name)
            assert_false((v.fallbacks[0] as FontFile).allow_system_fallback)
        else:
            assert_true((v.base_font as FontFile).allow_system_fallback,
                "%s: no sheet behind it, so the system's fonts stay reachable, as LabelSmall's are" % name)
            assert_eq(v.fallbacks, [Fonts.ui()], "%s: the shared Fira Sans itself, nothing else" % name)
        var pip_rids: Array = v.base_font.get_rids()
        var fira_rids: Array = v.fallbacks[0].get_rids()
        var shaped := _shaped(font, "Tiny — 14 |.", size)
        assert_true(shaped.size() >= 12, "%s shaped the line into %d glyphs" % [name, shaped.size()])
        var bar_seen := false
        var dot_seen := false
        for i in shaped.size():
            var g: Array = shaped[i]
            if i == shaped.size() - 2:
                assert_has(pip_rids, g[0], "%s: the bar comes from the pip font" % name)
                bar_seen = true
            elif i == shaped.size() - 1:
                assert_has(fira_rids, g[0], "%s: the period is Fira Sans's own" % name)
                dot_seen = true
            else:
                assert_has(fira_rids, g[0], "%s: glyph %d of the letters is Fira Sans's" % [name, i])
        assert_true(bar_seen and dot_seen)
        # the bar font owns exactly one character at the size it was registered
        var glyphs: PackedInt32Array = (v.base_font as FontFile).get_glyph_list(0, Vector2i(size, 0))
        assert_eq(glyphs.size(), 1, "%s: the pip font carries one glyph at %d" % [name, size])
        assert_eq(glyphs[0], "|".unicode_at(0))
        # drawn white-on-alpha so the Label's font colour (Palette.morale_color)
        # is what the bar shows — an RGBA8 glyph would be drawn as a colour glyph
        var img: Image = (v.base_font as FontFile).get_texture_image(0, Vector2i(size, 0), 0)
        assert_true(img != null)
        if img != null:
            assert_eq(img.get_format(), Image.FORMAT_LA8, "%s: the bar is a modulated glyph" % name)
        # The bar font stands where Fira Sans stood, so it carries Fira's line
        # metrics at the registered size: Guildhall's strip measures its pitch
        # off the variation's BASE font (`_line_h`), and a zero there stacked
        # the class line onto the morale line (seen in the first shot).
        var fira: Font = v.fallbacks[0]
        assert_almost(v.base_font.get_ascent(size), fira.get_ascent(size), 0.01, "%s: the bar font's ascent is the text's" % name)
        assert_almost(v.base_font.get_descent(size), fira.get_descent(size), 0.01, "%s: the bar font's descent is the text's" % name)
        assert_almost(v.base_font.get_height(size), fira.get_height(size), 0.01, "%s: the line is as tall as the text" % name)
        if faced:
            assert_almost(font.get_height(size), maxf(fira.get_height(size), Fonts.faces().get_height(size)), 0.01,
                "%s: the variation is as tall as its tallest font, as before" % name)
        else:
            assert_almost(font.get_height(size), fira.get_height(size), 0.01,
                "%s: no sheet, so the line is exactly the text's height" % name)


func test_a_size_nobody_registered_falls_back_to_fira_s_own_bar() -> void:
    # Graceful, not blank: a Label of a morale variation with a hand-set size
    # the theme never built still prints its "|" — Fira Sans's, uneven, visible.
    var t: Theme = Theme_.get_theme()
    var font: Font = t.get_font("font", "LabelMorale")
    var odd := 17
    var registered: Array = (font as FontVariation).base_font.get_size_cache_list(0)
    assert_false(registered.has(Vector2i(odd, 0)), "17px is not a size the theme registers")
    var shaped := _shaped(font, "|", odd)
    assert_eq(shaped.size(), 1)
    if shaped.size() == 1:
        assert_has((font as FontVariation).fallbacks[0].get_rids(), shaped[0][0],
            "an unregistered size shapes to Fira Sans's bar")
        assert_true(shaped[0][1] > 0.0)


func test_the_pip_font_is_shared_per_weight_and_the_variation_per_base_and_scale() -> void:
    # One bar font per Fira file (Regular for body/log/class/pip, Medium under
    # the tabular morale line); the variation is cached, so two builds of one
    # scale hand the same object to the Label.
    var body: Font = Fonts.with_pips(Fonts.ui(), Type.BODY)
    assert_eq(Fonts.with_pips(Fonts.ui(), Type.BODY), body, "cached per base and scale")
    assert_eq(Fonts.with_pips(Fonts.ui(), Type.SMALL), body, "a second size on the same base shares the variation")
    assert_ne(Fonts.with_pips(Fonts.ui(), Type.BODY, 150), body, "another scale is another variation (other faces)")
    var morale: Font = Fonts.with_pips(Fonts.ui_tabular(500), Type.MORALE_VALUE)
    assert_ne(morale, body)
    assert_ne((morale as FontVariation).base_font, (body as FontVariation).base_font,
        "Medium's period is not Regular's, so each weight has its own bar font")
    var ts := TextServerManager.get_primary_interface()
    assert_has((morale as FontVariation).opentype_features, ts.name_to_tag("tnum"), "tabular figures kept")
    assert_eq((body as FontVariation).fallbacks.size(), 2, "the Fira copy, then the faces")
    assert_eq((body as FontVariation).fallbacks[1], Fonts.faces())
    assert_true((body as FontVariation).fallbacks[0] is FontFile)
    assert_false(((body as FontVariation).fallbacks[0] as FontFile).allow_system_fallback)
    assert_true((Fonts.ui() as FontFile).allow_system_fallback, "the shared Fira Sans is untouched")
    assert_eq(Fonts.ui().fallbacks.size(), 0)
    # the bare flavour (LabelPip): its own bar font, system fallback open, the
    # shared file behind it and no sheet — cached apart from the faced one
    var bare: Font = Fonts.with_pips(Fonts.ui(), Type.SMALL, 100, false)
    assert_ne(bare, body, "bare and faced are two variations on one base")
    assert_eq(Fonts.with_pips(Fonts.ui(), Type.SMALL, 100, false), bare, "cached")
    assert_ne((bare as FontVariation).base_font, (body as FontVariation).base_font,
        "the open bar font is not the closed one (the first font decides system fallback)")
    assert_true(((bare as FontVariation).base_font as FontFile).allow_system_fallback)
    assert_eq((bare as FontVariation).fallbacks, [Fonts.ui()])
    assert_eq(Fonts.with_pips(Fonts.ui(), Type.SMALL, 150, false), Fonts.with_pips(Fonts.ui(), Type.SMALL, 100, false),
        "no sheet, so no per-scale flavour: one bare variation serves every scale")


func test_label_pip_is_label_small_with_the_figure() -> void:
    # The small morale line: LabelSmall's size and colour, the bar and the
    # faces on top. LabelSmall itself keeps no fallback (test_theme_kit pins it).
    for scale in Type.SCALES:
        var t: Theme = Theme_.get_theme(int(scale))
        assert_eq(t.get_font_size("font_size", "LabelPip"), Type.at(Type.SMALL, int(scale)))
        assert_eq(t.get_font_size("font_size", "LabelPip"), t.get_font_size("font_size", "LabelSmall"))
        assert_eq(t.get_color("font_color", "LabelPip"), t.get_color("font_color", "LabelSmall"))
        assert_eq(t.get_type_variation_base("LabelPip"), "Label")
        var small: Font = t.get_font("font", "LabelSmall")
        assert_false(small is FontVariation and (small as FontVariation).fallbacks.size() > 0)
        # and LabelSmall's LINE HEIGHT, at every scale: no sheet behind the bar
        # (the 36px sheet under the 20px line at 150 pushed a Tavern seat
        # card's button off its plate), and the shared Fira Sans itself, system
        # fallback open, so with the option off the line draws what LabelSmall
        # draws today.
        var pip: Font = t.get_font("font", "LabelPip")
        var size: int = t.get_font_size("font_size", "LabelPip")
        assert_almost(pip.get_height(size), small.get_height(size), 0.01,
            "LabelPip at %d is exactly as tall as LabelSmall" % scale)
        assert_almost(pip.get_ascent(size), small.get_ascent(size), 0.01)
        assert_eq((pip as FontVariation).fallbacks, [small], "the bar, then LabelSmall's own font")
        var sheets: Array = []
        for s in Type.SCALES:
            sheets.append_array(Fonts.faces_at(int(s)).get_rids())
        for rid in pip.get_rids():
            assert_false(sheets.has(rid), "LabelPip at %d carries no face sheet" % scale)


# ------------------------------------------------------------------- the faces

func test_the_face_sheet_follows_the_text_scale() -> void:
    # 24 at 100, 30 at 125, 36 at 150: Type.at's own arithmetic on the 24px
    # face, and the sheets gen_icons.lua writes at exactly those sizes.
    for scale in Type.SCALES:
        var want: int = Type.at(Fonts.FACE_SIZE, int(scale))
        assert_eq(int(Fonts.FACE_SIZE_AT[scale]), want, "the size table is Type.at(24, %d)" % scale)
        var f: FontFile = Fonts.faces_at(int(scale))
        assert_eq(f.fixed_size, want, "faces_at(%d)" % scale)
        assert_eq(f.fixed_size_scale_mode, TextServer.FIXED_SIZE_SCALE_DISABLE, "never scaled: a scaled bitmap blurs")
        assert_false(f.allow_system_fallback)
        for g in Fonts.FACE_GLYPHS:
            var cp: int = String(g).unicode_at(0)
            assert_true(f.has_char(cp), "faces_at(%d) has no glyph for U+%X" % [scale, cp])
        assert_false(f.has_char("A".unicode_at(0)))
        assert_almost(f.get_string_size("❤", HORIZONTAL_ALIGNMENT_LEFT, -1, want).x, float(want), 0.01)
        var sheet: Texture2D = load(String(Fonts.FACE_SHEETS[scale]))
        assert_true(sheet != null, "the sheet for %d loads" % scale)
        if sheet != null:
            assert_eq(sheet.get_size(), Vector2(want * Enums.MORALE_BAND_COUNT, want))
        # the face keeps its proportion above the baseline (19 of 24)
        var ascent: int = int(Fonts.FACE_ASCENT_AT[want])
        assert_eq(ascent, int(round(Fonts.FACE_ASCENT * want / 24.0)))
        assert_almost(f.get_ascent(want), float(ascent), 0.01)
        assert_almost(f.get_descent(want), float(want - ascent), 0.01)
    assert_eq(Fonts.faces_at(100), Fonts.faces(), "the 24px sheet is the one faces() always was")
    assert_eq(Fonts.faces_at(110), Fonts.faces(), "an unknown scale is 100, as Type.step recovers")
    assert_ne(Fonts.faces_at(125), Fonts.faces_at(150))


func test_the_scaled_themes_draw_every_face_from_their_own_sheet() -> void:
    # test_theme_kit proves this at 100; here the 125 and 150 themes shape all
    # ten faces through each morale variation and the glyph must come from
    # THAT scale's sheet — not the 24px one, not a system font.
    for scale in [125, 150]:
        var t: Theme = Theme_.get_theme(scale)
        var sheet_rids: Array = Fonts.faces_at(scale).get_rids()
        var small_rids: Array = Fonts.faces().get_rids()
        for name in FACE_VARIATIONS:
            var font: Font = t.get_font("font", name)
            var size: int = t.get_font_size("font_size", name)
            for g in Fonts.FACE_GLYPHS:
                var shaped := _shaped(font, g, size)
                assert_eq(shaped.size(), 1, "%s at %d shaped %s into %d glyphs" % [name, scale, g, shaped.size()])
                if shaped.size() == 1:
                    assert_has(sheet_rids, shaped[0][0], "%s at %d drew %s off the wrong sheet" % [name, scale, g])
                    assert_false(small_rids.has(shaped[0][0]))
                    assert_almost(shaped[0][1], float(Fonts.FACE_SIZE_AT[scale]), 0.01,
                        "the face is one em of its sheet's size")
            # the mixed line, as the roster prints it
            var mixed := _shaped(font, "Tiny — 14 😡", size)
            assert_true(mixed.size() >= 10)
            if mixed.size() >= 2:
                assert_has(sheet_rids, mixed[mixed.size() - 1][0])
                assert_false(sheet_rids.has(mixed[0][0]))
        # LabelPip shapes a face to no sheet at all — whatever the system
        # gives LabelSmall for it, it gives LabelPip (the seat card's line is
        # LabelSmall's with an even figure, nothing more)
        var pip: Font = t.get_font("font", "LabelPip")
        var pip_size: int = t.get_font_size("font_size", "LabelPip")
        for g in Fonts.FACE_GLYPHS:
            for shaped in _shaped(pip, g, pip_size):
                assert_false(sheet_rids.has(shaped[0]), "LabelPip at %d drew %s off the %d sheet" % [scale, g, scale])
                assert_false(small_rids.has(shaped[0]), "LabelPip at %d drew %s off the 24px sheet" % [scale, g])


func test_with_faces_serves_the_scale_too() -> void:
    # The pinned door keeps its shape (test_theme_kit) and learns the scale:
    # the 125 / 150 wrapper stands on the same copy with the larger sheet behind.
    var base: Font = Fonts.ui()
    var at100: Font = Fonts.with_faces(base)
    assert_eq(Fonts.with_faces(base, 100), at100, "scale 100 is the unscaled wrapper")
    for scale in [125, 150]:
        var faced: Font = Fonts.with_faces(base, scale)
        assert_ne(faced, at100)
        assert_true(faced is FontVariation)
        assert_eq((faced as FontVariation).base_font, (at100 as FontVariation).base_font, "one copy of Fira Sans")
        assert_eq((faced as FontVariation).fallbacks.size(), 1)
        assert_eq((faced as FontVariation).fallbacks[0], Fonts.faces_at(scale))
        assert_eq(Fonts.with_faces(base, scale), faced, "cached per base and scale")
