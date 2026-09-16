extends RefCounted
## The shared parts every screen is assembled from.
##
## art/ref/specs/06-ui-component-kit.md measured each of these on the reference
## concepts; this file is that document as constructors. Nothing here invents a
## style: a widget picks a `theme_type_variation` and Theme.gd supplies the
## StyleBox, font and colour. That indirection is the whole point — the art can
## be retuned in Theme.gd/Palette.gd without touching a screen.
##
## TEST CONTRACT (tests/unit/test_screens.gd and eight others): the tests read a
## screen by walking its subtree collecting `Label.text` and `Button.text`, and
## press buttons by text fragment. Therefore every widget that shows a string
## puts it in a real Label or Button — never a RichTextLabel, a texture or a
## _draw() call — and every pressable thing stays a Button subclass.
##
## The pre-art paper widgets (`title`, `section`, `body`, `meta`, `faint`,
## `button`, `wax_button`, `page`, `column`, `rule`) are kept with their exact
## old signatures so the ~559 existing call sites keep working while screens are
## converted one at a time. They now render in the reference's dark chrome.
##
## W1-KIT (build/plan/artaudit/00-plan.md §2) added the composites the wave-2
## screens consume: `reasoned`, `confirm_pair`, `stamp_box` + `stamp_press`,
## `damage_number` + `number_rise`, `pager`, `tab_row`, `slot_with_reason`,
## `sparkline`, the tailed `speech_plate`, the iconed/tailed `building_callout`,
## the `Motion` table. Every existing constructor keeps its signature and return
## type; theme variation names registered by W1-CHROME (`PanelStamp`,
## `PanelEmote`, `LabelDamage*`, `ButtonQuiet`) are named here as strings and
## fall back to their base type until that unit lands. Nothing here loads a new
## PNG path: textures arrive as `Texture2D` parameters (`game/ui/Icons.gd` is
## the only file that names icon paths).

const Palette = preload("res://game/ui/Palette.gd")
const Type = preload("res://game/ui/Type.gd")
const Fonts = preload("res://game/ui/Fonts.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Services = preload("res://game/core/Services.gd")
## W3-KIT2: the kit asks Icons for a glyph by ROLE and KEY (the padlock, a log
## kind) and still names no path — Icons.gd is the only file that does.
const Icons = preload("res://game/ui/Icons.gd")
const ICON_DIR := "res://game/assets/ui/icons/"

## Legacy names for the type scale (docs/13 §4 sizes, now from Type.gd).
const SIZE_TITLE := Type.SECTION
const SIZE_SECTION := Type.SECTION_SM
const SIZE_BODY := Type.BODY
const SIZE_META := Type.SMALL

const MARGIN := 24
const GAP := 10

# ---------------------------------------------------------------- geometry
## The measured frame of Concept 1 (01 §1). Screens position against these so a
## screenshot lands on the reference's own pixels.
const SCREEN := Vector2i(1536, 1024)
const HEADER_H := 74           ## header band, divider at y=74-75
const RAIL_W := 207            ## nav rail, right border core x=208
const RAIL_TOP := 77
const RAIL_ITEM_H := 55        ## 01 §6 / 03 §2: pitch 55, item 0 at y=105
const RAIL_ITEM_Y0 := 105
const SCENE := Rect2i(210, 77, 929, 640)
const SIDEBAR := Rect2i(1142, 79, 378, 635)
const STRIP_Y := 734
const STRIP_H := 262
const CARD_SIZE := Vector2i(215, 262)   ## 01 §3: build 215x262, pitch 224
const CARD_PITCH := 224
const CARD_X0 := 140
const SLOT := 47               ## 06 §2: the canonical item slot
const SLOT_PITCH := 56
const PORTRAIT_SLOT := 56
const MINI_CELL := 37          ## 01 §4.1
const MINI_PITCH := 44
const LOG_ROW_PITCH := 29      ## 01 §4.2

## The callout's and the speech plate's tail (03 §3 / 03 §7): 14 wide, 8 deep.
const TAIL_W := 14
const TAIL_H := 8
## 03 §3: a 32px icon column at fill.x+12, title and subtitle at x+60.
const CALLOUT_ICON := 32
const CALLOUT_ICON_X := 12
const CALLOUT_TEXT_X := 60
const CALLOUT_REASON_W := 200
## PIPE-15 / W4-CURSOR: the ring around a hovered or focused callout — its
## width in pixels and the shader that paints it (see `Outline`).
const OUTLINE_PX := 2
const OUTLINE_SHADER := "res://game/ui/shaders/outline.gdshader"
## docs/13 §7 StampBadge: rotated 2-7°, ~70-85% opacity, the word always readable.
const STAMP_ALPHA := 0.85
## CRITIC-G06: one "disabled with reason" treatment — dimmed to 0.55, one CAUTION line.
const REASONED_DIM := 0.55
## COMBAT-02 / PIPE-01: pooled floating numbers, +14px y stagger per simultaneous hit.
const NUMBER_POOL := 16
const NUMBER_STAGGER_PX := 14
## KIT-05: a CTA text wider than this wraps inside its plate instead of widening it;
## the plate grows from 70 to 88 when the label wraps.
const CTA_WRAP_W := 300
const CTA_H := 70
const CTA_H_WRAPPED := 88
## 03 §7: bubble text is 13px at a 19px line pitch.
const BUBBLE_PITCH := 19
## W3-KIT2 (handoff-W2-MARKET): a sub-tab's plate hugged its word ("Sell" in a
## 30x18 tab) because `NavItemActive`'s content margin is 0; every tab now has
## the size Market.gd was giving its own.
const TAB_MIN := Vector2(110, 32)
## W5-KIT3: one pip of the `pips` strip (HALL-17's volume ladder) and the gap
## between two.
const PIP_SIZE := Vector2i(12, 10)
const PIP_GAP := 3
## 06 §8: the two-line tooltip's maximum width.
const TOOLTIP_W := 260
## 06 §1 / KIT-09: the panel's corner ornament is a 16px sprite in each corner,
## inset one pixel from the 9-slice's outer line.
const ORNAMENT := 16
const ORNAMENT_INSET := 3
## 06 §6 / KIT-09: the callout's plate is a horizontal sweep from the base fill
## to the band's tone at this strength, the flourish (18x14) in its top-right.
const CALLOUT_SWEEP := 0.30
## The emote marker (handoff-W2-STAGE2): W1-ICONS' `emote_<kind>` glyphs are
## drawn as small tailed bubbles already, so a glyph is the WHOLE marker, at
## 2x, its tail's apex on the frame's own apex — never a bubble in a bubble.
const EMOTE_GLYPH_SCALE := 2


## docs/13 §12.2's motion table, in one place (CRITIC-G08). Milliseconds; every
## consumer passes them through `GameSettings.motion_duration(ms[, floor_ms])`,
## never through arithmetic of its own. `STAMP_PRESS_FLOOR` is docs/13 §13's one
## reduced-motion exception (the stamp keeps 60 ms so it still LANDS).
class Motion:
	const STAMP_PRESS := 120
	const STAMP_PRESS_FLOOR := 60
	const LOG_SETTLE := 90
	const NUMBER := 600
	const RISE_PX := 18
	const BUBBLE := 2400
	const HIT := 90
	const BURST := 350


## The 14x8 pointer under a callout or a speech plate (03 §3, 03 §7). A Node2D
## rather than a Control on purpose: a PanelContainer re-lays every Control
## child into its own rect (LESSONS), and a Node2D is left alone, draws in the
## plate's space, inherits its modulate, and — having no mouse filter at all —
## can never intercept a hotspot's click (CRITIC-C18's MOUSE_FILTER_IGNORE rule
## satisfied by construction). `apex` is where it points, in plate-local pixels;
## the base straddles `base_x` on the plate's bottom (or top) edge, and the fill
## paints over the plate's rim between the base points so the plate opens into
## the tail. Colours are the dark plate's own (W1-CHROME: callout_plate.png's
## fill and outer line), so the tail and the 9-slice read as one object.
class Tail extends Node2D:
	var apex := Vector2.ZERO
	var base_x := 0.0
	var base_y := 0.0
	var fill: Color = Palette.SURFACE_BUBBLE
	var rim: Color = Palette.EDGE_CALLOUT
	## UI-20: how far the tail reaches (0 = the kit's own TAIL_H). A plate
	## lifted clear of a crowd sends its tail down to the speaker, and a tail
	## five times its depth drawn at one base width is a needle: the base
	## widens with the square root of the length, to twice TAIL_W at most.
	var length := 0.0

	func _draw() -> void:
		var half := float(TAIL_W) * 0.5
		if length > float(TAIL_H):
			half *= clampf(sqrt(length / float(TAIL_H)), 1.0, 2.0)
		var l := Vector2(base_x - half, base_y)
		var r := Vector2(base_x + half, base_y)
		draw_colored_polygon(PackedVector2Array([l, r, apex]), fill)
		draw_line(l, apex, rim, 1.0)
		draw_line(r, apex, rim, 1.0)
		# Open the plate's edge: the rim pixel row between the base points is
		# repainted in the fill so the tail reads as part of the plate.
		var inward := -1.0 if apex.y > base_y else 1.0
		draw_line(Vector2(l.x + 1.0, base_y + inward * 0.5), Vector2(r.x - 1.0, base_y + inward * 0.5),
			fill, 1.0)


## The ring around a hovered or focused building callout (PIPE-15, W4-CURSOR):
## a Node2D drawn BEHIND its plate (`show_behind_parent`) that paints the
## plate's own `panel` 9-slice and its tail `OUTLINE_PX` larger through
## game/ui/shaders/outline.gdshader in silhouette mode (`fill` 1, `width` 0 —
## a nine-patch stretches its texels, so the copy grows by drawing larger, not
## by dilating), in `Palette.ACCENT_GOLD_LIGHT`; the plate and the tail then
## paint over its middle and only the 2px fringe shows, hugging the chamfers
## and the tail. It NEVER replaces the theme's `focus` StyleBox on the title
## Button — the EDGE_STEEL ring and this one both show (§0.5). A state, not a
## motion: shown while the Button holds focus or the plate/Button is hovered,
## hidden otherwise, no tween. A Node2D for the reasons `Tail` is: the
## PanelContainer leaves it where it is, it can take no click, and it draws
## in the plate's space. The stylebox and the size are read at draw time from
## the parent, so the theme's deferred arrival and every re-layout are seen.
class Outline extends Node2D:
	var tail: Tail = null
	var _focused := false
	var _hover := 0     # bit 1 the plate, bit 2 the title Button

	func _init() -> void:
		show_behind_parent = true
		visible = false
		var shader: Shader = load(OUTLINE_SHADER)
		if shader != null:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("color", Palette.ACCENT_GOLD_LIGHT)
			mat.set_shader_parameter("width", 0.0)
			mat.set_shader_parameter("fill", 1.0)
			material = mat

	func set_focused(on: bool) -> void:
		_focused = on
		_update()

	func set_hovered(bit: int, on: bool) -> void:
		_hover = (_hover | bit) if on else (_hover & ~bit)
		_update()

	func lit() -> bool:
		return _focused or _hover != 0

	func _update() -> void:
		var want := lit()
		if want != visible:
			visible = want
		if want:
			queue_redraw()

	func _draw() -> void:
		var plate := get_parent() as Control
		if plate == null or plate.size.x <= 0.0 or plate.size.y <= 0.0:
			return
		var px := float(OUTLINE_PX)
		var box: StyleBox = plate.get_theme_stylebox("panel")
		if box != null:
			draw_style_box(box, Rect2(Vector2(-px, -px), plate.size + Vector2(px, px) * 2.0))
		if tail != null:
			var half := float(TAIL_W) * 0.5
			var l := Vector2(tail.base_x - half, tail.base_y)
			var r := Vector2(tail.base_x + half, tail.base_y)
			var ink: Color = Palette.ACCENT_GOLD_LIGHT
			draw_colored_polygon(PackedVector2Array([l, r, tail.apex]), ink)
			draw_line(l, tail.apex, ink, px * 2.0)
			draw_line(r, tail.apex, ink, px * 2.0)
			draw_circle(tail.apex, px, ink)


## The "..." inside an emote bubble when no glyph is given (KIT-02): three 3px
## squares at a 6px pitch (15x3), drawn at the node's own origin — `speech_bubble`
## sets `position` so they sit centred on the frame's body. SceneStage's private
## Ellipsis draws the same squares at the OLD 33x32 bubble's pixels until
## handoff-W1-KIT §6 retires it.
class Dots extends Node2D:
	const SIZE := Vector2(15, 3)
	var ink: Color = Palette.TEXT_ON_BUBBLE

	func _draw() -> void:
		for i in 3:
			draw_rect(Rect2(i * 6, 0, 3, 3), ink)


## One bar per value, coloured by the band it lands in, on the kit's inset well.
## Promoted verbatim from RaiderDetail's private MoraleChart (RULES-12); the
## colour function is a parameter so a screen can hand it any band rule, and
## defaults to the morale ramp the chart was written for.
class Sparkline extends Control:
	const PITCH := 12
	const HEIGHT := 40
	var values: Array = []
	var color_fn: Callable = Callable(Palette, "morale_color")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.SURFACE_INSET)
		draw_rect(Rect2(Vector2.ZERO, size), Palette.EDGE_SLATE, false, 1.0)
		var n := values.size()
		if n == 0:
			return
		var pitch := minf(float(PITCH), size.x / float(n))
		var w := maxf(2.0, floorf(pitch) - 2.0)
		var inner := size.y - 4.0
		for i in n:
			var v := clampi(int(values[i]), 0, 100)
			var h := maxf(2.0, floorf(inner * v / 100.0))
			var c: Color = color_fn.call(v) if color_fn.is_valid() else Palette.morale_color(v)
			draw_rect(Rect2(Vector2(2.0 + i * pitch, size.y - 2.0 - h), Vector2(w, h)), c)


## The four corner ornaments of a major panel (06 §1, KIT-09): one 16px sprite
## (the theme's `corner_ornament` icon on PanelWarm/PanelSteel, drawn for the
## top-left) flipped into each corner, tinted by the theme's `ornament_tint`.
## A Node2D, like `Tail`, because a PanelContainer re-lays every Control child
## into its content rect (LESSONS) and a Node2D is left where it is, draws in
## the panel's space and can never take a click. It follows the panel's
## `resized`; the panel's 9-slice is untouched (an ornament baked into a
## 9-slice would stretch).
class Ornaments extends Node2D:
	var sprite: Texture2D = null
	var tint: Color = Color.WHITE
	var inset: float = float(ORNAMENT_INSET)
	var box: Vector2 = Vector2.ZERO

	func _draw() -> void:
		if sprite == null or box.x < ORNAMENT * 2 or box.y < ORNAMENT * 2:
			return
		var s := Vector2(ORNAMENT, ORNAMENT)
		var i := inset
		# A negative size flips the sprite (draw_texture_rect's documented trick).
		draw_texture_rect(sprite, Rect2(Vector2(i, i), s), false, tint)
		draw_texture_rect(sprite, Rect2(Vector2(box.x - i, i), Vector2(-s.x, s.y)), false, tint)
		draw_texture_rect(sprite, Rect2(Vector2(i, box.y - i), Vector2(s.x, -s.y)), false, tint)
		draw_texture_rect(sprite, Rect2(Vector2(box.x - i, box.y - i), -s), false, tint)


## The success-chance callout's dressing (06 §6, KIT-09): the band's rim (the
## theme's flat box is replaced by the gradient plate, so the 2px rim is drawn
## here, on top) and the flourish in the top-right corner, tinted by the band.
## A Node2D for the same reason as `Ornaments`; it is added AFTER the column so
## `AdventureBoard._notice_callout`'s `box.get_child(0)` is still the column.
class Flourish extends Node2D:
	var sprite: Texture2D = null
	var tone: Color = Palette.DANGER
	var box: Vector2 = Vector2.ZERO

	func _draw() -> void:
		if box.x <= 4.0 or box.y <= 4.0:
			return
		draw_rect(Rect2(Vector2(1, 1), box - Vector2(2, 2)), tone, false, 2.0)
		if sprite != null:
			var s: Vector2 = sprite.get_size()
			draw_texture_rect(sprite, Rect2(Vector2(box.x - s.x - 4.0, 4.0), s), false, tone)


## The two-line tooltip (06 §8, KIT-22): a title in cream over a body in the
## muted ink, at most `TOOLTIP_W` wide, on the theme's TooltipPanel. Godot asks
## the control that CARRIES the tooltip text to build it, and that control is a
## screen's Button or slot whose class cannot change — so `tooltip_for` lays
## this transparent host over the control (MOUSE_FILTER_PASS: the hover and
## the click both reach the control underneath, and Godot's focus-on-click
## walks up through PASS to the Button) and the host answers the tooltip. The
## control's own `tooltip_text` is kept and set to the same two lines, so a
## reader that only knows `tooltip_text` (tests, a11y) still finds the words.
class TooltipHost extends Control:
	var title := ""
	var body := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		focus_mode = Control.FOCUS_NONE

	func _make_custom_tooltip(_for_text: String) -> Object:
		return build_tooltip()

	## The tooltip's content: a VBox of two Labels named "Title" and "Body".
	## Public so a test can read it without a mouse.
	func build_tooltip() -> Control:
		var v := VBoxContainer.new()
		v.name = "Tooltip"
		v.add_theme_constant_override("separation", 2)
		var t := Label.new()
		t.name = "Title"
		t.text = title
		t.theme_type_variation = "LabelLabel"
		t.add_theme_color_override("font_color", Palette.TEXT_TITLE)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(0, 0)
		v.add_child(t)
		if not body.is_empty():
			var b := Label.new()
			b.name = "Body"
			b.text = body
			b.theme_type_variation = "TooltipLabel"
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(b)
		# The width is capped, not fixed: a short tooltip stays short. Measured
		# on the kit's theme at the player's scale (the Labels are not in a
		# tree yet, so their own theme lookups would answer with the defaults).
		var th: Theme = Theme_.get_theme(Theme_.scale_of(self))
		var widest: float = 0.0
		for c in v.get_children():
			var l := c as Label
			var vn := String(l.theme_type_variation)
			var f: Font = th.get_font("font", vn) if th.has_font("font", vn) else th.default_font
			if f == null:
				f = ThemeDB.fallback_font
			var fs: int = th.get_font_size("font_size", vn) if th.has_font_size("font_size", vn) else th.default_font_size
			if fs <= 0:
				fs = ThemeDB.fallback_font_size
			widest = maxf(widest, f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		v.custom_minimum_size = Vector2(minf(widest + 2.0, float(TOOLTIP_W)), 0)
		# Pre-size the Labels to that width: Godot reads the tooltip Window's
		# size off get_contents_minimum_size() before any layout pass, and an
		# autowrap Label still 0 wide breaks every grapheme onto its own line —
		# the two-line tooltip came out 180x571 the first time one was shot
		# (W5-TOOLS `--hover`; probe: 571 -> 56 with this loop).
		for c in v.get_children():
			if c is Label:
				(c as Label).size = Vector2(v.custom_minimum_size.x, 0)
		return v


# ---------------------------------------------------------------- ground

## The dark ground every screen sits on. On scene screens the plate covers it.
static func ground() -> Control:
	var bg := ColorRect.new()
	bg.color = Palette.GROUND_PAGE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg


# ---------------------------------------------------------------- labels

static func _label(text: String, variation: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	return l


## The font and size the theme gives `variation` at `who`'s text scale
## (W0-TEXTSCALE's door for anything measured here). Returns [Font, int].
static func _font_of(variation: String, who: Node) -> Array:
	var th: Theme = Theme_.get_theme(Theme_.scale_of(who))
	var f: Font = null
	if th.has_font("font", variation):
		f = th.get_font("font", variation)
	elif th.default_font != null:
		f = th.default_font
	else:
		f = ThemeDB.fallback_font
	var s: int = 0
	if th.has_font_size("font_size", variation):
		s = th.get_font_size("font_size", variation)
	elif th.default_font_size > 0:
		s = th.default_font_size
	else:
		s = ThemeDB.fallback_font_size
	return [f, s]


## The public door to `_font_of` for the kit's other files (Cards measures the
## card's band line with it, W5-KIT3): [Font, int] for `variation` at `who`'s
## scale.
static func font_of(variation: String, who: Node) -> Array:
	return _font_of(variation, who)


static func _line_height(variation: String, who: Node) -> float:
	var fs: Array = _font_of(variation, who)
	return (fs[0] as Font).get_height(int(fs[1]))


static func _text_width(text: String, variation: String, who: Node) -> float:
	var fs: Array = _font_of(variation, who)
	return (fs[0] as Font).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs[1])).x


## One per screen (docs/13 §4).
static func title(text: String) -> Label:
	return _label(text, "LabelSection")


static func section(text: String) -> Label:
	return _label(text, "LabelSectionSm")


static func body(text: String) -> Label:
	return _label(text, "LabelBody")


## Secondary text: units, column headers, quiet annotations.
static func meta(text: String) -> Label:
	return _label(text, "LabelMuted")


## Empty-state prose and disabled explanations.
static func faint(text: String) -> Label:
	return _label(text, "LabelSmall")


static func label_as(text: String, variation: String) -> Label:
	return _label(text, variation)


## docs/13 §7: an empty list says why it is empty, in the panel's own voice.
##
## KIT-08: the line used to sit at the top of a 474x262 void. It now expands to
## fill whatever its column gives it and centres the sentence in that space; an
## optional 32px muted `glyph` sits above the text and an optional `hint` line
## below it (both anchored to the Label's centre, so a plain Label is still what
## comes back — the 25 existing call sites and the tests that read their text
## are untouched). The glyph is a `Texture2D` parameter: the quill/bench/shelf
## icons are W1-ICONS' and the call sites pass them (W3-KIT2, the screens).
##
## W5-KIT3: the glyph and the hint sit around the text's WHOLE block, not its
## first line. They used to be placed from one line's height, so a sentence
## that wrapped (RaiderDetail's "There is no kit to show. This guild has
## nobody in it." in a 300px column) had its hint drawn over its second line.
## The block is measured at the Label's width (`_wrapped_lines`, a
## TextParagraph with the Label's own font, size and wrap rule) every time the
## Label is resized — at construction it has no width yet, so the first
## placement is the one-line one and the resize that lays the Label out
## re-places both. `place_empty_state` is public so a test can ask for it.
static func empty_state(text: String, glyph: Texture2D = null, hint: String = "") -> Label:
	var l := _label(text, "LabelSmall")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if glyph != null:
		var t := TextureRect.new()
		t.name = "Glyph"
		t.texture = glyph
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.modulate = Color(1, 1, 1, 0.6)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.set_anchors_preset(Control.PRESET_CENTER)
		t.offset_left = -16
		t.offset_right = 16
		l.add_child(t)
	if not hint.is_empty():
		var h := _label(hint, "LabelSmall")
		h.name = "Hint"
		h.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.anchor_left = 0.0
		h.anchor_right = 1.0
		h.anchor_top = 0.5
		h.anchor_bottom = 0.5
		h.offset_left = 0
		h.offset_right = 0
		l.add_child(h)
	place_empty_state(l)
	l.resized.connect(func() -> void: place_empty_state(l))
	return l


## Put an empty state's "Glyph" above and its "Hint" below the text block the
## Label wraps to at its current width: the block is centred (the Label's
## vertical alignment), so the glyph's bottom sits 8px above the block's top
## and the hint's top 4px under its bottom — the same numbers as before for a
## one-line text, and the whole block's height for a wrapped one.
static func place_empty_state(l: Label) -> void:
	var variation := String(l.theme_type_variation)
	if variation.is_empty():
		variation = "LabelSmall"
	var line_h: float = _line_height(variation, l)
	var lines: int = _wrapped_lines(l)
	var block: float = line_h * float(lines) + float(l.get_theme_constant("line_spacing")) * float(lines - 1)
	var glyph := l.get_node_or_null("Glyph") as Control
	if glyph != null:
		glyph.offset_bottom = -(block * 0.5 + 8.0)
		glyph.offset_top = glyph.offset_bottom - 32.0
	var hint := l.get_node_or_null("Hint") as Control
	if hint != null:
		hint.offset_top = block * 0.5 + 4.0
		hint.offset_bottom = hint.offset_top + line_h * 2.0


## How many lines `l`'s text wraps to at its current width, measured with a
## TextParagraph in the Label's own font, size and word-wrap rule (the engine's
## `get_line_count()` answers 1 outside a tree, and the unit tests are never
## in one). No width yet, or no wrap: one line.
static func _wrapped_lines(l: Label) -> int:
	if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
		return 1
	var variation := String(l.theme_type_variation)
	if variation.is_empty():
		variation = "Label"
	var inner: float = l.size.x - l.get_theme_stylebox("normal").get_minimum_size().x
	if inner <= 0.0:
		return 1
	var fs: Array = _font_of(variation, l)
	var tp := TextParagraph.new()
	tp.width = inner
	tp.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	tp.add_string(l.text, fs[0] as Font, int(fs[1]))
	return maxi(1, tp.get_line_count())


# ---------------------------------------------------------------- stamps

## A rubber-stamp word: WIPE., CLEARED, MAY LEAVE, 1 OF 1 (06 §8; docs/13 §7).
##
## STILL A LABEL, ON PURPOSE. Four screens hold this return as a `Label`
## (`_wipe_stamp_label: Label`, Results' `var t: Label`), and a PanelContainer
## here would be a compile error in files this unit does not own. So the Label
## itself carries the stamp treatment docs/13 §7 asks for — rotated 2-7° about
## its centre, deterministically from the word so two stamps side by side never
## share an angle, at 85% opacity — and shrinks to its text so the tilt turns the
## word, not a column-wide box. No rim: a rim needs a box, and the box form is
## `stamp_box()` below (PanelStamp chrome, the Label its DIRECT child), which is
## what the wave-2/3 sites migrate to. No tween — a static stamp is a fact, the
## press (`stamp_press`) is for a stamp that lands live.
static func stamp(text: String, tone: Color = Palette.DANGER) -> Label:
	var l := _label(text, "LabelSectionSm")
	l.add_theme_color_override("font_color", tone)
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.modulate = Color(1, 1, 1, STAMP_ALPHA)
	l.rotation_degrees = stamp_angle(text)
	l.resized.connect(func() -> void: l.pivot_offset = l.size * 0.5)
	return l


## docs/13 §7's StampBadge as a box (KIT-18, COMBAT-08, HALL-13, CRITIC-C08):
## a PanelContainer typed `PanelStamp` (W1-CHROME's 9-slice with the worn double
## rule; until it is registered, a 2px rim in the tone) holding the word's Label
## as its DIRECT child, rotated 2-7° from `word.hash()`, at 85% opacity, no
## tween. `tone` is a name — "danger", "caution", "positive", "info" — so a
## caller never picks a hex.
##
## SIBLING ORDER IS THE CALLER'S CONTRACT (CRITIC-C18): test_wipe_sequence.gd
## reads `_wipe_stamp_label.get_parent().get_index()` against the ink blot's,
## so on RaidView this box must be added DIRECTLY to the screen, after the blot,
## and `_wipe_stamp_label` must be `stamp_box(...).get_child(0)`.
static func stamp_box(word: String, tone: String = "danger") -> PanelContainer:
	var box := PanelContainer.new()
	box.name = "Stamp"
	box.theme_type_variation = "PanelStamp"
	var colour := tone_color(tone)
	var th: Theme = Theme_.get_theme()
	if not th.has_stylebox("panel", "PanelStamp"):
		box.add_theme_stylebox_override("panel", Theme_.flat(Color(0, 0, 0, 0), colour, 2, 3, 4))
	elif tone != "danger":
		# The theme's frame is tinted DANGER; another tone re-tints a COPY, so
		# the shared resource is never touched and every other stamp keeps its red.
		var sb: StyleBox = th.get_stylebox("panel", "PanelStamp").duplicate()
		if sb is StyleBoxTexture:
			(sb as StyleBoxTexture).modulate_color = colour
		box.add_theme_stylebox_override("panel", sb)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate = Color(1, 1, 1, STAMP_ALPHA)
	box.rotation_degrees = stamp_angle(word)
	box.resized.connect(func() -> void: box.pivot_offset = box.size * 0.5)
	var l := _label(word, "LabelSectionSm")
	l.name = "Word"
	l.add_theme_color_override("font_color", colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	return box


## The 120 ms press a stamp makes when it lands LIVE (docs/13 §11.3: "scale
## 1.06→1.00"), for RaidView's MISTAKE rows and the wipe — never for a static
## card. Through the one door, at `motion_duration(120, 60)`: reduced motion
## keeps the 60 ms floor so the stamp still lands. Returns the Tween, or null
## outside a tree (then the box simply sits at 1.0 — arrive instantly).
static func stamp_press(box: Control) -> Tween:
	box.pivot_offset = box.size * 0.5
	var seconds := float(Motion.STAMP_PRESS) / 1000.0
	var settings: Node = Services.find(box, "GameSettings")
	if settings != null:
		seconds = settings.motion_duration(Motion.STAMP_PRESS, Motion.STAMP_PRESS_FLOOR)
	var t := tween(box)
	if t == null:
		box.scale = Vector2.ONE
		return null
	box.scale = Vector2(1.06, 1.06)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(box, "scale", Vector2.ONE, seconds)
	return t


## 2-7°, from the word: the same word always lands at the same angle (a shot is
## stable), two different words rarely share one. The sign alternates on the
## next hash bit so a row of stamps leans both ways, the way printed ones do.
static func stamp_angle(word: String) -> float:
	var h: int = absi(word.hash())
	var deg := 2.0 + float(h % 6)
	return deg if (h / 6) % 2 == 0 else -deg


## A tone NAME to its Palette colour. Unknown names are DANGER: a stamp with a
## misspelt tone is still a stamp, and red is what most of them are.
static func tone_color(tone: String) -> Color:
	match tone:
		"caution":
			return Palette.CAUTION
		"positive":
			return Palette.POSITIVE
		"info":
			return Palette.INFO
		_:
			return Palette.DANGER


# ---------------------------------------------------------------- buttons

## The ordinary control: bronze rim, navy plate, chamfered (06 §7.2).
static func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	return b


static func secondary(text: String) -> Button:
	return button(text)


## The commit control (06 §3). `Palette`'s crimson appears on exactly ONE
## control per screen — the action the player cannot cheaply undo.
##
## KIT-05: the text used to be the only thing sizing the plate, so a long label
## ("Back to town — the guild carries on") ran into both rims. The text now
## wraps inside the plate and trims with an ellipsis past that, and the plate
## grows to 88 when the label wraps. Godot zeroes a Button's minimum width the
## moment autowrap or trimming is on, so the width the text used to claim is
## put back explicitly — capped at `CTA_WRAP_W`, which is what makes the long
## label wrap while every shorter CTA keeps exactly the width it had.
static func cta(text: String, subline: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "ButtonCta"
	b.custom_minimum_size = Vector2(0, CTA_H)
	if not subline.is_empty():
		# 01 §2: the CTA's cost line sits INSIDE the plate under the label (label
		# baseline 646, cost baseline 672 in a 617–686 plate). The variation lifts
		# the label; the cost stays a separate Label so the tests read it on its
		# own and Depart can leave it empty (10 §2 R7).
		b.theme_type_variation = "ButtonCtaCost"
		var cost := _label(subline, "LabelCtaCost")
		cost.name = "Cost"
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		# W5-SCALE: the 22px slot scales with the text — the line is 34 tall
		# at 150 and grew 4px under the plate (test_text_scale_layout.gd).
		var pct: int = Theme_.scale_of(b)
		var slot: int = 22 if pct == Type.SCALE_DEFAULT else Type.at(24, pct)
		cost.offset_top = -(8 + slot)
		cost.offset_bottom = -8
		b.add_child(cost)
	_guard_cta(b)
	return b


## KIT-15's door for a priced commit control: the cost line is formatted by
## `Type.gold` ("2,400 G"), never by a "%d G" at the call site.
static func cta_priced(text: String, price: int) -> Button:
	return cta(text, Type.gold(price))


static func _guard_cta(b: Button) -> void:
	# docs/13 §12.4: `ui.seal` — "any WaxButton commit", "on press, not
	# release" — so `button_down`, never `pressed`. A disabled Button emits
	# no `button_down`, which is how a `reasoned` CTA stays silent (W6-AUD-BIND).
	b.button_down.connect(func() -> void:
		var audio: Node = Services.find(b, "Audio")
		if audio != null:
			audio.play("ui.seal"))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var text_w: float = ceilf(_text_width(b.text, b.theme_type_variation, b))
	var th: Theme = Theme_.get_theme(Theme_.scale_of(b))
	var style_w := 0.0
	if th.has_stylebox("normal", b.theme_type_variation):
		style_w = th.get_stylebox("normal", b.theme_type_variation).get_minimum_size().x
	b.custom_minimum_size.x = minf(text_w + style_w, float(CTA_WRAP_W))
	b.resized.connect(func() -> void:
		if b.size.x - style_w < text_w and b.custom_minimum_size.y < CTA_H_WRAPPED:
			b.custom_minimum_size.y = CTA_H_WRAPPED)


## The strip's page arrows (10 §2 R4): a mini plate with the sliced chevron,
## no caption — the page label beside them says where the reader is.
static func pager_button(next: bool) -> Button:
	var b := Button.new()
	b.theme_type_variation = "ButtonMini"
	b.icon = load(ICON_DIR + ("arrow_right.png" if next else "arrow_left.png"))
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.tooltip_text = "Next page" if next else "Previous page"
	b.custom_minimum_size = Vector2(32, 28)
	return b


## The pager composite (KIT-12, CRITIC-C11): ‹ caption › on one 28px row, the
## arrows named `PagerPrev` / `PagerNext` and FOCUS_ALL so a11y_smoke's ring
## closes through them, the caption a LabelSmall ("n/m" unless given). With one
## page the arrows are hidden — a hidden control is not a disabled one, so no
## reason line is owed. `Cards.roster_strip` draws its own pair in the strip's
## gutters; this row is for captioned sites (RaidView's "Party of 12 · page 1/3").
static func pager(page: int, pages: int, on_prev: Callable, on_next: Callable,
		caption: String = "") -> HBoxContainer:
	var h := row(6)
	h.name = "Pager"
	h.custom_minimum_size = Vector2(0, 28)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var prev := pager_button(false)
	prev.name = "PagerPrev"
	if on_prev.is_valid():
		prev.pressed.connect(on_prev)
	h.add_child(prev)
	var cap := _label(caption if not caption.is_empty() else "%d/%d" % [page + 1, pages], "LabelSmall")
	cap.name = "PageCaption"
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cap)
	var next := pager_button(true)
	next.name = "PagerNext"
	if on_next.is_valid():
		next.pressed.connect(on_next)
	h.add_child(next)
	if pages <= 1:
		prev.visible = false
		next.visible = false
	return h


## Kept: the old name for the commit control.
static func wax_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "ButtonCta"
	b.button_down.connect(func() -> void:
		var audio: Node = Services.find(b, "Audio")
		if audio != null:
			audio.play("ui.seal"))
	return b


static func icon_button(text: String, icon: Texture2D = null) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "ButtonIcon"
	if icon != null:
		b.icon = icon
	b.custom_minimum_size = Vector2(46, 46)
	return b


## A text link (06 §7.3). LinkButton is Button-derived, so tests still see it.
##
## Theme.gd gives LinkButton the §12.3 focus ring; this adds the link's OWN
## signal to focus as well. The underline is `ON_HOVER` and a keyboard never
## hovers, so a focused link was showing strictly less than a hovered one —
## docs/13 §13.2's rule ("no interaction may exist only as a pointer gesture")
## applied to the affordance rather than the action.
##
## `focus_mode` is set EXPLICITLY and this is not redundant: measured on Godot
## 4.7.1, `LinkButton.new().focus_mode` is `FOCUS_ACCESSIBILITY` (3), not
## `FOCUS_ALL` (2) as on Button. Godot's Tab walk stops only on FOCUS_ALL, so
## the default makes every link pointer-only — `grab_focus()` on one is refused
## with "This control can grab focus only when screen reader is active" and the
## focus ring below it can never be drawn. That was a live breach of §13.2 on
## the Adventure's Board, whose "Back to town" link was provably absent from
## the Tab chain.
##
## A DISABLED link keeps its own rest ink (review-W1-KIT F8): Theme.gd gives
## LinkButton no `font_disabled_color`, so Godot's default — near-black — took
## over the moment `reasoned()` disabled the event log's "View All", and the
## 0.55 dim on top made the word vanish on the dark panel, leaving its reason
## floating under nothing. The dim is the disabled treatment (docs/13 §7); the
## ink stays the theme's LinkButton `font_color` so the word is still read.
static func link(text: String, always_underline: bool = false) -> LinkButton:
	var l := LinkButton.new()
	l.text = text
	l.focus_mode = Control.FOCUS_ALL
	l.add_theme_color_override("font_disabled_color", _link_ink())
	l.underline = (LinkButton.UNDERLINE_MODE_ALWAYS if always_underline
		else LinkButton.UNDERLINE_MODE_ON_HOVER)
	if not always_underline:
		l.focus_entered.connect(func() -> void:
			l.underline = LinkButton.UNDERLINE_MODE_ALWAYS)
		l.focus_exited.connect(func() -> void:
			l.underline = LinkButton.UNDERLINE_MODE_ON_HOVER)
	return l


## The theme's LinkButton rest ink (TEXT_MUTED_WARM as Theme.gd registers it),
## read off the theme so a retone there reaches the disabled state too.
static func _link_ink() -> Color:
	var th: Theme = Theme_.get_theme()
	if th.has_color("font_color", "LinkButton"):
		return th.get_color("font_color", "LinkButton")
	return Palette.TEXT_MUTED_WARM


## docs/13 §7: a disabled control is "never a mystery" — the reason is printed
## beneath it. Returns the container holding both; the button is named "Button".
static func button_with_reason(text: String, reason: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var b := button(text)
	b.disabled = not reason.is_empty()
	b.name = "Button"
	box.add_child(b)
	if not reason.is_empty():
		box.add_child(faint(reason))
	return box


## THE ONE "disabled with reason" treatment (CRITIC-G06; docs/13 §7, docs/01 §9):
## the control dimmed to 0.55, its button disabled, an optional 16px `glyph`
## (the padlock, once W1-ICONS' `lock_16` is passed) in the button's leading
## slot, and ONE LabelSmall in CAUTION directly under it — never a tooltip,
## because `_texts()` reads Labels and a keyboard never hovers. Returns the box
## holding both; the reason Label is named "Reason". Pass an UNPARENTED control.
## Callouts and tabs print their reason INSIDE their own plate instead
## (`building_callout`, `tab_row`) with the same dim and the same colour.
## An empty reason leaves the control enabled and undimmed, so a screen can call
## this unconditionally the way it calls `button_with_reason`.
## The reason does NOT wrap (docs/13 §14: a line under a row or chip grows the
## row, never wraps) — a wrapping Label has a zero minimum width, and inside a
## shrinking box it collapsed to one letter per line (seen on the Town's event
## log, W1-KIT shot 1). A caller that wants a wrap passes `width` (> 0): the
## reason then wraps at that width (handoff-W2-TAVERN — the Tavern and the
## Market did this locally for a sentence wider than its column at 150%).
##
## W3-KIT2 (CRITIC-G06, handoff-W2-RAIDVIEW): the padlock is the DEFAULT —
## W1-ICONS' `lock_16` through `Icons.at`, so a caller passes nothing to get
## the one treatment — and it is put on the button ONLY WHILE THERE IS A
## REASON: an enabled control handed a glyph used to wear the lock anyway.
##
## W5-KIT3: `placement` says where the reason goes. "below" (the default) is
## the box above, byte for byte. "beside" puts the control and its reason on
## one row — an HBoxContainer named "Row" as the box's only child, the reason
## vertically centred beside the control, wrapping at `width` when given —
## for a table whose rows keep one pitch (Settings' option rows, LoadSave's
## slot rows moved the Label by hand for this). `button_of(box)` still finds
## the Button either way; the reason is `box.find_child("Reason", true, false)`.
static func reasoned(control: Control, reason: String, glyph: Texture2D = null,
		width: int = 0, placement: String = "below") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var b: BaseButton = control as BaseButton
	if b == null:
		b = button_of(control)
	if b != null:
		b.disabled = not reason.is_empty()
		if not reason.is_empty() and b is Button and (b as Button).icon == null:
			var lock: Texture2D = glyph if glyph != null else Icons.at("lock", "16")
			if lock != null:
				(b as Button).icon = lock
	if control is Button and (String(control.name).is_empty() or String(control.name).begins_with("@")):
		control.name = "Button"
	var host: Container = box
	if placement == "beside":
		var line := row(8)
		line.name = "Row"
		box.add_child(line)
		host = line
	host.add_child(control)
	if not reason.is_empty():
		control.modulate = Color(1, 1, 1, REASONED_DIM)
		var why := _label(reason, "LabelSmall")
		why.name = "Reason"
		why.add_theme_color_override("font_color", Palette.CAUTION)
		if width > 0:
			why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			why.custom_minimum_size = Vector2(width, 0)
		if placement == "beside":
			why.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		host.add_child(why)
	return box


## The destructive confirm, in ONE shape (CRITIC-G05; docs/02 §5.3/§6.3 name the
## consequence, docs/13 §7 defaults to the safe choice): a DANGER-rimmed plate
## holding both halves as Buttons ("Yes" in DANGER ink, expanding; "No" beside
## it) so `_texts()` and `_find_button` see the exact texts the screens'
## tests read ("Yes — overwrite Slot 1" / "Keep it", "take it off", "Keep them"
## — the strings are the caller's and stay theirs). The "no" half is the default
## focus: it is grabbed (deferred) when the plate enters a tree, and
## `default_focus_of(plate)` names it for anything that wires focus by hand.
static func confirm_pair(yes_text: String, no_text: String, on_yes: Callable,
		on_no: Callable) -> PanelContainer:
	var plate := PanelContainer.new()
	plate.name = "Confirm"
	plate.add_theme_stylebox_override("panel",
		Theme_.flat(Palette.SURFACE_PANEL, Palette.DANGER, 2, 4, 8))
	var h := row(8)
	var yes := button(yes_text)
	yes.name = "Yes"
	yes.add_theme_color_override("font_color", Palette.DANGER)
	yes.add_theme_color_override("font_hover_color", Palette.DANGER)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if on_yes.is_valid():
		yes.pressed.connect(on_yes)
	h.add_child(yes)
	var no := button(no_text)
	no.name = "No"
	if on_no.is_valid():
		no.pressed.connect(on_no)
	h.add_child(no)
	plate.add_child(h)
	plate.set_meta("default_focus", no)
	plate.tree_entered.connect(func() -> void:
		(func() -> void:
			if no.is_inside_tree() and no.is_visible_in_tree():
				no.grab_focus()).call_deferred())
	return plate


## The control a composite wants focused first (the confirm pair's "no"), or
## null when it has no opinion.
static func default_focus_of(c: Control) -> Control:
	if c == null or not c.has_meta("default_focus"):
		return null
	var target = c.get_meta("default_focus")
	return target as Control if is_instance_valid(target) else null


## The button inside a `button_with_reason` box -- or inside any composite
## that names its primary control "Button" (the building callout does).
static func button_of(box: Control) -> Button:
	var direct := box.get_node_or_null("Button")
	if direct != null:
		return direct as Button
	for child in box.get_children():
		if child is Control:
			var found := button_of(child as Control)
			if found != null:
				return found
	return null


# ---------------------------------------------------------------- tabs

## Set by a tab pressed while focused; read once by the next `tab_row` to enter a tree.
static var _tab_refocus := false


## In-panel sub-tabs (HALL-11; spec 10 §4 W18): flat Buttons on a shared
## baseline rule, the active one on the `nav_tab_active` plate (the theme's
## `NavItemActive`) with a 2px gold underline, the inactive ones `ButtonQuiet`
## (W1-CHROME's; plain Button until it lands), a disabled one dimmed with its
## reason printed under it in the row (the `reasoned` treatment, inside).
## `labels` are the Button texts verbatim — the tests press them. The Buttons
## come back through `tabs_of(row)` in order.
##
## W3-KIT2: every tab is at least `TAB_MIN` (handoff-W2-MARKET: the active
## plate hugged its word). And the row is a rebuild-per-switch idiom — the
## pressed tab is freed with the old row, which drops keyboard focus on the
## floor (handoff-W2-TAVERN) — so when a tab is pressed WHILE IT HOLDS FOCUS the
## kit remembers, and the next row to enter a tree hands focus to its active
## tab one frame later if nothing else owns it by then. Only then: a fresh
## mount (the router grabs the screen's own target in the same frame), a
## test's `pressed.emit()` and a shot's `--press` (no focus to keep) all leave
## the ring exactly where it was.
##
## W5-KIT3: `min_size` is the tab's floor, `TAB_MIN` unless a screen asks —
## the Guildhall keeps 110x28 (its content panel's fold: two card rows and the
## top of a third need the 4px, handoff-W3-ROSTER) and used to set it on every
## tab after `tabs_of()`.
static func tab_row(labels: Array, active: int, reasons: Array = [],
		min_size: Vector2 = TAB_MIN) -> VBoxContainer:
	var v := column(0)
	v.name = "TabRow"
	var h := row(4)
	var tabs: Array = []
	for i in labels.size():
		var b := button(String(labels[i]))
		b.theme_type_variation = "NavItemActive" if i == active else "ButtonQuiet"
		b.name = "Tab%d" % i
		b.custom_minimum_size = min_size
		b.pressed.connect(func() -> void:
			if b.has_focus():
				_tab_refocus = true
			# docs/13 §12.4 "Tab / screen change": the in-screen half (W6-AUD-BIND).
			var audio: Node = Services.find(b, "Audio")
			if audio != null:
				audio.play("ui.tab"))
		var reason := String(reasons[i]) if i < reasons.size() else ""
		var cell := column(0)
		cell.add_child(b)
		if i == active:
			var under := ColorRect.new()
			under.color = Palette.ACCENT_GOLD
			under.custom_minimum_size = Vector2(0, 2)
			under.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(under)
		if not reason.is_empty():
			b.disabled = true
			b.modulate = Color(1, 1, 1, REASONED_DIM)
			var why := _label(reason, "LabelSmall")
			why.name = "Reason"
			why.add_theme_color_override("font_color", Palette.CAUTION)
			# No wrap: a tab's reason grows the cell (docs/13 §14), as in `reasoned`.
			cell.add_child(why)
		h.add_child(cell)
		tabs.append(b)
	v.add_child(h)
	v.add_child(rule())
	v.set_meta("tabs", tabs)
	if active >= 0 and active < tabs.size():
		var live: Button = tabs[active]
		v.tree_entered.connect(func() -> void:
			if _tab_refocus:
				_tab_refocus = false
				_regrab_tab.call_deferred(live))
	return v


## `tab_row`'s deferred re-grab: the active tab takes focus only when the
## viewport has no focus owner at all (a tab freed under the keyboard), and
## only if it is still on screen and enabled.
static func _regrab_tab(tab: Button) -> void:
	if not is_instance_valid(tab) or not tab.is_inside_tree() or tab.disabled:
		return
	if not tab.is_visible_in_tree():
		return
	var vp := tab.get_viewport()
	if vp == null or vp.gui_get_focus_owner() != null:
		return
	tab.grab_focus()


static func tabs_of(row_box: Control) -> Array:
	if row_box == null or not row_box.has_meta("tabs"):
		return []
	return row_box.get_meta("tabs")


# ---------------------------------------------------------------- containers

## A printed rule line — in-panel dividers. Panel borders come from the theme.
static func rule() -> Control:
	var r := ColorRect.new()
	r.color = Palette.EDGE_SLATE
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func page(margin: int = MARGIN) -> MarginContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", margin)
	m.add_theme_constant_override("margin_right", margin)
	m.add_theme_constant_override("margin_top", margin)
	m.add_theme_constant_override("margin_bottom", margin)
	return m


static func column(gap: int = GAP) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	return v


static func row(gap: int = GAP) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	return h


## The kit's container (06 §1). `variation` picks the tint: PanelWarm for the
## dashboard's sidebar and cards, PanelSteel for the raid screen, PanelRound
## for the softer card/log panels, PanelInset for a recessed well.
##
## KIT-09: a major panel (any variation W1-CHROME gave a `corner_ornament`
## icon — PanelWarm and PanelSteel) carries the four corner ornaments as a
## Node2D child named "Ornaments" added AFTER the Pad, so `content_of()` and
## every `get_child(0)` reading still find the Pad first; the sprite and its
## tint are the theme's, never a path named here.
static func panel(variation: String = "PanelWarm", pad: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	if pad > 0:
		var m := MarginContainer.new()
		m.name = "Pad"
		m.add_theme_constant_override("margin_left", pad)
		m.add_theme_constant_override("margin_right", pad)
		m.add_theme_constant_override("margin_top", pad)
		m.add_theme_constant_override("margin_bottom", pad)
		p.add_child(m)
	var th: Theme = Theme_.get_theme()
	if th.has_icon("corner_ornament", variation):
		var o := Ornaments.new()
		o.name = "Ornaments"
		o.sprite = th.get_icon("corner_ornament", variation)
		if th.has_color("ornament_tint", variation):
			o.tint = th.get_color("ornament_tint", variation)
		p.add_child(o)
		p.resized.connect(func() -> void:
			o.box = p.size
			o.queue_redraw())
	return p


## Where a panel's children go — the pad margin if it has one, else the panel.
static func content_of(p: PanelContainer) -> Control:
	var pad := p.get_node_or_null("Pad")
	return pad if pad != null else p


# ---------------------------------------------------------------- slots

## The 47px item slot (06 §2). `interactive` makes it a Button so tests can
## press it and read its caption.
static func slot(icon: Texture2D = null, size: int = SLOT, variation: String = "Slot") -> Control:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	p.custom_minimum_size = Vector2(size, size)
	if icon != null:
		var t := TextureRect.new()
		t.texture = icon
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.add_child(t)
	return p


## An item slot the player can click. The caption stays in `Button.text` so
## `_button_named("Minor — 8 G")` still finds it (10 §5 rule 3).
static func slot_button(caption: String, icon: Texture2D = null, size: int = SLOT) -> Button:
	var b := Button.new()
	b.text = caption
	b.theme_type_variation = "ButtonSlot"
	b.custom_minimum_size = Vector2(size, size)
	if icon != null:
		b.icon = icon
		b.expand_icon = true
	return b


## `button_with_reason` for a slot cell (RULES-12, promoted verbatim from
## Market.gd): the slot chrome, the caption in the Button's text, and docs/13
## §7's reason printed under it at the cell's own width. The Button is named
## "Button" so `button_of()` finds it.
static func slot_with_reason(caption: String, reason: String, cell: Vector2,
		icon: Texture2D = null) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var b := slot_button(caption, icon, int(cell.y))
	b.custom_minimum_size = cell
	b.name = "Button"
	b.disabled = not reason.is_empty()
	b.add_theme_color_override("font_color", Palette.TEXT_BODY)
	box.add_child(b)
	if not reason.is_empty():
		var why := label_as(reason, "LabelSmall")
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size = Vector2(cell.x, 0)
		box.add_child(why)
	return box


## The two-line tooltip (KIT-22, 06 §8) on any control — a gear slot, a
## mechanic icon: `title` in cream over `body` in the muted ink, at most
## `TOOLTIP_W` wide, on the theme's TooltipPanel. A `TooltipHost` (see the
## class) is laid over the control and answers Godot's tooltip request; the
## control's own `tooltip_text` is set to the same words ("title — body") so
## the tests and the a11y walk still read them. Returns the host. Calling it
## again replaces the lines.
static func tooltip_for(control: Control, title: String, body: String = "") -> Control:
	var words := title if body.is_empty() else "%s — %s" % [title, body]
	control.tooltip_text = words
	var host: TooltipHost = control.get_node_or_null("TooltipHost") as TooltipHost
	if host == null:
		host = TooltipHost.new()
		host.name = "TooltipHost"
		host.set_anchors_preset(Control.PRESET_FULL_RECT)
		control.add_child(host)
	host.title = title
	host.body = body
	host.tooltip_text = words
	return host


## A rarity-bordered slot: the rim takes the rarity colour (06 §2 variants).
static func slot_rarity(rarity: int, icon: Texture2D = null, size: int = SLOT) -> Control:
	var p := slot(icon, size)
	var s := Theme_.flat(Palette.SURFACE_SLOT, Palette.rarity_color(rarity), 2, 4)
	p.add_theme_stylebox_override("panel", s)
	return p


# ---------------------------------------------------------------- bars

## HP / resource bar (06 §4). Godot's ProgressBar cannot do the reference's
## two-tone fill or its square-cut end, so this draws itself — six lines, exact.
static func bar(value: float, maximum: float, kind: String = "hp",
		text: String = "", size: Vector2i = Vector2i(204, 17)) -> Control:
	var b := preload("res://game/ui/Bar.gd").new()
	b.custom_minimum_size = size
	b.value = value
	b.maximum = maximum
	b.kind = kind
	b.text = text
	return b


## The pip strip (W5-KIT3; HALL-17's volume ladder, promoted from Settings'
## `_volume_control`): `steps` pips in a row named "Pips", the i-th (1-based)
## lit when `value` reaches `maximum * i / steps`, each the kit's bar
## (`Widgets.bar`, the secondary tint, `PIP_SIZE`) at `PIP_GAP`, so no new
## pixels; the strip and its pips never take the pointer. A pip is named by
## the threshold it stands for ("Pip20" .. "Pip100" for `pips(v, 100, 5)`,
## Settings' own names), so a screen that reads its ladder by name keeps
## reading it. Six steps by default (the 0..100 ladder in sixths).
static func pips(value: float, maximum: float, steps: int = 6) -> HBoxContainer:
	var strip := row(PIP_GAP)
	strip.name = "Pips"
	strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n: int = maxi(1, steps)
	for i in range(1, n + 1):
		var at: float = maximum * float(i) / float(n)
		var lit: bool = maximum > 0.0 and value >= at - 0.0001
		var pip := bar(1.0 if lit else 0.0, 1.0, "mana", "", PIP_SIZE)
		pip.name = "Pip%d" % int(round(at))
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(pip)
	return strip


## The morale sparkline (RULES-12, promoted verbatim from RaiderDetail's
## MoraleChart): one bar per value at a 12px pitch on a 40px inset well,
## coloured by `band_color_fn(value)` (the morale ramp by default). Sized to
## its values; a caller caps `custom_minimum_size.x` to its column.
static func sparkline(values: Array, band_color_fn: Callable = Callable()) -> Control:
	var s := Sparkline.new()
	s.name = "Sparkline"
	s.values = values.duplicate()
	if band_color_fn.is_valid():
		s.color_fn = band_color_fn
	s.custom_minimum_size = Vector2(maxi(1, values.size()) * Sparkline.PITCH, Sparkline.HEIGHT)
	return s


# ---------------------------------------------------------------- callout

## The success-chance box (06 §6): a headline label and a big figure, the whole
## box coloured by band. `band` is 0-100; below 30 danger, below 65 caution.
##
## KIT-09 (06 §6, Table B): the plate is a horizontal sweep from the theme's
## callout base to the band's tone (a GradientTexture2D in a StyleBoxTexture
## that keeps the theme box's content margins), and a Node2D named "Flourish"
## added AFTER the column draws the 2px rim and the theme's `flourish` icon in
## the top-right, tinted by the band. The column stays `get_child(0)`
## (AdventureBoard re-dresses it by that index).
static func callout(headline: String, figure: String, band: int) -> PanelContainer:
	var variation := "PanelCalloutDanger"
	var tone := Palette.DANGER
	if band >= 65:
		variation = "PanelCalloutPositive"
		tone = Palette.POSITIVE
	elif band >= 30:
		variation = "PanelCalloutCaution"
		tone = Palette.CAUTION
	var p := panel(variation, 0)
	var col := column(2)
	col.add_child(_label(headline, "LabelLabel"))
	var fig := _label(figure, "LabelFigure")
	fig.add_theme_color_override("font_color", tone)
	col.add_child(fig)
	p.add_child(col)
	var th: Theme = Theme_.get_theme()
	if th.has_stylebox("panel", variation):
		var base: StyleBox = th.get_stylebox("panel", variation)
		var fill: Color = (base as StyleBoxFlat).bg_color if base is StyleBoxFlat else Palette.SURFACE_CALLOUT
		var sweep := StyleBoxTexture.new()
		sweep.texture = _sweep_texture(fill, fill.lerp(tone, CALLOUT_SWEEP))
		sweep.content_margin_left = base.content_margin_left
		sweep.content_margin_top = base.content_margin_top
		sweep.content_margin_right = base.content_margin_right
		sweep.content_margin_bottom = base.content_margin_bottom
		p.add_theme_stylebox_override("panel", sweep)
		var f := Flourish.new()
		f.name = "Flourish"
		f.tone = tone
		if th.has_icon("flourish", variation):
			f.sprite = th.get_icon("flourish", variation)
		p.add_child(f)
		p.resized.connect(func() -> void:
			f.box = p.size
			f.queue_redraw())
	return p


## A 256x1 left-to-right gradient for the callout's plate (Table B); 64 wide
## it stepped visibly across the 337px plate (W3KIT2_RaidPrep_callout3x.png).
static func _sweep_texture(from: Color, to: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, from)
	g.set_color(1, to)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 1
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(1, 0)
	return t


# ---------------------------------------------------------------- log row

## One line of the event or combat log (06 §8): a coloured badge and a Label.
## The text stays a Label so the tests can read it.
##
## KIT-07 / COMBAT-06 (W3-KIT2): `kind` names an icon-grid log kind (mistake,
## heal, raider_attack, boss_attack, mechanic, phase, system, morale_up,
## morale_down, loot, gold, recruit) and resolves the 22px pixel badge through
## `Icons.at("log", kind)` when no `icon` is passed; a kind the grid has not
## drawn falls back to the `Badge` disc in `badge`, wearing that kind's
## one-character glyph — the a11y second channel stays whatever the art does.
## The badge cell is named "Badge" either way.
##
## `wrap` (W6-LOG, CRITIC-C2's one rule for the two reading surfaces): 0 = the
## Label clips as before (the caller sets its overrun); N > 0 = it wraps
## (`AUTOWRAP_WORD_SMART`) to at most N lines with no trimming; -1 = it wraps
## without bound. The row's minimum stays ONE pitch — a caller that needs a
## whole-pitch height for a taller row sets it (RaidView's live log snaps its
## scroll by the pitch), and the report lets its rows grow to their text.
static func log_row(text: String, tone: Color = Palette.TEXT_MUTED_WARM,
		badge: Color = Palette.INFO, icon: Texture2D = null, kind: String = "",
		wrap: int = 0) -> HBoxContainer:
	var h := row(12)
	h.custom_minimum_size = Vector2(0, LOG_ROW_PITCH)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	if icon == null and not kind.is_empty() and Icons.exists("log", kind):
		icon = Icons.at("log", kind)
	if icon != null:
		var t := TextureRect.new()
		t.name = "Badge"
		t.texture = icon
		t.custom_minimum_size = Vector2(18, 18)
		t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(t)
	else:
		var dot := preload("res://game/ui/Badge.gd").new()
		dot.name = "Badge"
		dot.custom_minimum_size = Vector2(18, 18)
		dot.color = badge
		if not kind.is_empty():
			dot.glyph = preload("res://game/ui/Badge.gd").glyph_for_kind(kind)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dot)
	var l := _label(text, "LabelLog")
	l.add_theme_color_override("font_color", tone)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wrap != 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		l.clip_text = false
		if wrap > 0:
			l.max_lines_visible = wrap
	h.add_child(l)
	return h


# ---------------------------------------------------------------- chips

## A header resource chip (06 §5.2). The value is a Label so "60 G", "Day 1"
## and "Roster 0 of 15" stay readable by the tests (10 §2 R11).
static func chip(value: String, tone: Color = Palette.TEXT_MUTED,
		icon: Texture2D = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = "PanelChip"
	p.custom_minimum_size = Vector2(96, 45)
	var h := row(10)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	if icon != null:
		var t := TextureRect.new()
		t.texture = icon
		t.custom_minimum_size = Vector2(26, 26)
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(t)
	var l := _label(value, "LabelChip")
	l.add_theme_color_override("font_color", tone)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	m.add_child(h)
	p.add_child(m)
	return p


# ---------------------------------------------------------------- numbers

## The floating damage / heal number (COMBAT-02, PIPE-01, CRITIC-C05): a Label
## named "DamageNumber" typed `LabelDamage` / `LabelDamageCrit` / `LabelHeal`
## (W1-CHROME registers them at Type.DAMAGE 28 / DAMAGE_CRIT 34 with the 2px
## outline; a plain Label until then), its value set ONCE here and never
## tweened (docs/13 §12.2 "numbers are instant"). `kind` is "hit", "crit" or
## "heal"; a heal prints "+N", the rest "-N", whatever sign the caller passed.
## Pooled to 16 (PIPE-01): a Label that `number_rise` has finished with is
## hidden and handed back on the next call, detached from wherever it was;
## when all 16 are in flight the oldest is recycled. The caller parents it —
## `SceneStage.number_at(spr, label)` this wave — and calls `number_rise`.
static var _numbers: Array = []

static func damage_number(amount: int, kind: String = "hit") -> Label:
	var l: Label = _pooled_number()
	l.name = "DamageNumber"
	match kind:
		"crit":
			l.theme_type_variation = "LabelDamageCrit"
		"heal":
			l.theme_type_variation = "LabelHeal"
		_:
			l.theme_type_variation = "LabelDamage"
	l.text = ("+%d" % absi(amount)) if kind == "heal" else ("-%d" % absi(amount))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.modulate = Color.WHITE
	l.scale = Vector2.ONE
	l.visible = true
	# Above the joke bubbles (handoff-W2-RAIDVIEW): a 600 ms number spawned into
	# the same overlay as a 2.4 s plate was drawn under it and never seen. Set
	# here, once, so every caller gets it and the pool cannot hand back a label
	# that lost it.
	l.z_index = 1
	return l


static func _pooled_number() -> Label:
	for i in range(_numbers.size() - 1, -1, -1):
		if not is_instance_valid(_numbers[i]):
			_numbers.remove_at(i)
	for n in _numbers:
		var l: Label = n
		if not l.visible:
			_detach_number(l)
			return l
	if _numbers.size() < NUMBER_POOL:
		var fresh := Label.new()
		_numbers.append(fresh)
		return fresh
	var oldest: Label = _numbers.pop_front()
	_numbers.append(oldest)
	_detach_number(oldest)
	return oldest


static func _detach_number(l: Label) -> void:
	if l.has_meta("rise_tween"):
		var t = l.get_meta("rise_tween")
		if t is Tween and (t as Tween).is_valid():
			(t as Tween).kill()
		l.remove_meta("rise_tween")
	var parent := l.get_parent()
	if parent != null:
		parent.remove_child(l)


## The number's rise and fade through the one door: `Motion.RISE_PX` up over
## `motion_duration(Motion.NUMBER)`, the fade over the same span with the hold
## written as `floor_ms` — under reduced motion the label arrives at its top
## instantly and fades over the 600 ms it would have taken (a hold, not a
## branch: CRITIC-C18). The text is never touched. Ends by hiding the label,
## which is what returns it to the pool. Returns the Tween, or null outside a
## tree (then the label is hidden at once — nothing to animate).
static func number_rise(label: Label) -> Tween:
	var rise := float(Motion.NUMBER) / 1000.0
	var hold := rise
	var settings: Node = Services.find(label, "GameSettings")
	if settings != null:
		rise = settings.motion_duration(Motion.NUMBER)
		hold = settings.motion_duration(Motion.NUMBER, Motion.NUMBER)
	var t := tween(label)
	if t == null:
		label.position.y -= float(Motion.RISE_PX)
		label.visible = false
		return null
	label.set_meta("rise_tween", t)
	t.set_parallel(true)
	var up := t.tween_property(label, "position:y", label.position.y - float(Motion.RISE_PX), rise)
	up.set_ease(Tween.EASE_OUT)
	var fade := t.tween_property(label, "modulate:a", 0.0, hold * 0.55)
	fade.set_delay(hold * 0.45)
	t.chain().tween_callback(func() -> void: label.visible = false)
	return t


## +14px per simultaneous number (COMBAT-02), so a raid-wide hit on twelve does
## not stack into one blob: the caller adds `number_stagger(i)` to the i-th y.
static func number_stagger(index: int) -> float:
	return float(NUMBER_STAGGER_PX * maxi(0, index))


# ---------------------------------------------------------------- speech

## The in-scene emote bubble (KIT-02, PIPE-05, CRITIC-C02): a fixed sprite,
## never scaled — `PanelEmote`'s 40x44 cream frame once W1-CHROME registers it
## (read off the theme's StyleBoxTexture, so no path is named here), today's
## 33x32 `speech_bubble.png` until then. `glyph` (16px, W1-ICONS' `emote_<kind>`
## through `Icons.at`) is centred in the body as a TextureRect named "Glyph";
## with no glyph and `kind == "dots"` the reference's "..." is drawn.
## For the camp screen's *text* bubble (03 §7) use `speech_plate`.
static func speech_bubble(kind: String = "dots", glyph: Texture2D = null) -> TextureRect:
	var t := TextureRect.new()
	t.name = "Emote"
	# Sibling names must be unique, so a stage with five bubbles keeps "Emote"
	# on the FIRST and Godot renames the rest "@TextureRect@N" (a different N
	# every run). Anything that counts or compares bubbles reads this meta.
	t.set_meta("emote", kind)
	var frame_tex: Texture2D = null
	# The body — where a glyph or the dots go — is the frame minus the theme's
	# content margins (12/10/12/18 on the 40x44 frame = 16x16), so the geometry
	# is the chrome's own and moves with it. The old 33x32 bubble's interior is
	# the fallback until PanelEmote is registered.
	var body := Rect2(8, 3, 17, 18)
	var th: Theme = Theme_.get_theme()
	if th.has_stylebox("panel", "PanelEmote"):
		var sb: StyleBox = th.get_stylebox("panel", "PanelEmote")
		if sb is StyleBoxTexture:
			frame_tex = (sb as StyleBoxTexture).texture
			var fs: Vector2 = frame_tex.get_size()
			body = Rect2(sb.content_margin_left, sb.content_margin_top,
				fs.x - sb.content_margin_left - sb.content_margin_right,
				fs.y - sb.content_margin_top - sb.content_margin_bottom)
	if frame_tex == null:
		frame_tex = load("res://game/assets/ui/speech_bubble.png")
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.custom_minimum_size = frame_tex.get_size()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if glyph != null:
		# handoff-W2-STAGE2 (option b): the emote glyphs are drawn as tailed
		# cream bubbles of their own, so one inside the frame read as a bubble
		# in a bubble. The glyph IS the marker: drawn alone at 2x (32px, nearest
		# — pixel art), the frame's texture dropped, its 40x44 footprint kept
		# so every scene's bubble still ends where the stage placed it (the
		# head-gap rule in test_scene_stage) and the glyph's tail apex lands on
		# the frame's own apex: the 16px glyph's apex is at (3, 14), the frame's
		# at (5, 43), so the 2x glyph sits at (0, 43 - 29).
		var g := TextureRect.new()
		g.name = "Glyph"
		g.texture = glyph
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(g)
		var side := float(Icons.size("emote") * EMOTE_GLYPH_SCALE)
		g.size = Vector2(side, side)
		g.position = emote_glyph_offset(frame_tex.get_size())
	else:
		t.texture = frame_tex
	if glyph == null and kind == "dots":
		var d := Dots.new()
		d.name = "Dots"
		d.position = body.position + ((body.size - Dots.SIZE) * 0.5).floor()
		t.add_child(d)
	return t


## Where the 2x emote glyph sits inside the frame's footprint (`speech_bubble`):
## its tail apex on the frame's apex. The 16px glyphs (gen_icons.lua's emote
## role) carry their apex at (3, 14); the 40x44 frame's is at (5, 43), i.e.
## 1px above its bottom edge, 5 in from the left. Whole pixels.
static func emote_glyph_offset(frame: Vector2) -> Vector2:
	var s := EMOTE_GLYPH_SCALE
	var apex := Vector2(3 * s + (s - 1), 14 * s + (s - 1))
	return Vector2(maxf(0.0, 5.0 - apex.x + 1.0), frame.y - 1.0 - apex.y).floor()


## The camp's text bubble (KIT-02, STAGE-10, CRITIC-C02): the `PanelBubble`
## plate (one chrome everywhere until Q04), the line left-aligned at 13px on a
## 19px pitch (03 §7), and — only when `tail_at` is finite — a child named
## "Tail" whose apex sits on `tail_at`, given in the plate's PARENT's
## coordinates (the stage's): W1-STAGE calls this one-arg and positions the
## plate; W2-STAGE2 passes the speaker's head. The tail follows the plate
## wherever it is moved or resized. The Label is the Pad's first child, which
## is how SceneStage finds it; the plate ignores the mouse so a hotspot under
## it still takes the click.
##
## `opts` (W7-STAGE, UI-07 / UI-20): `wrap` is the line's width in px (180;
## a 1x scene asks for 140 so a 40px figure is not under a plate five times
## its height) and `tail_len` the tail's reach in px (0 = TAIL_H; SceneStage
## writes the lift it chose so the tail is drawn as a wedge, `Tail.length`).
static func speech_plate(text: String, tail_at: Vector2 = Vector2.INF, opts: Dictionary = {}) -> PanelContainer:
	var p := panel("PanelBubble", 8)
	p.name = "Speech"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := _label(text, "LabelSmall")
	l.add_theme_color_override("font_color", Palette.TEXT_BODY)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(maxf(1.0, float(opts.get("wrap", 180))), 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gap: int = int(round(float(Type.at(BUBBLE_PITCH, Theme_.scale_of(l))) - _line_height("LabelSmall", l)))
	l.add_theme_constant_override("line_spacing", maxi(0, gap))
	content_of(p).add_child(l)
	if tail_at.is_finite():
		var tail := Tail.new()
		tail.name = "Tail"
		tail.length = maxf(0.0, float(opts.get("tail_len", 0.0)))
		p.add_child(tail)
		p.item_rect_changed.connect(func() -> void: _aim_tail(p, tail, tail_at))
		_aim_tail(p, tail, tail_at)
	return p


## Point `tail` (a child of `plate`) at `apex_parent`, a point in the plate's
## parent's space: the base sits on the bottom edge when the apex is below the
## plate's middle, on the top edge otherwise, and slides along that edge to
## stay under the apex (never nearer than a tail's width to a corner).
static func _aim_tail(plate: Control, tail: Tail, apex_parent: Vector2) -> void:
	var apex := apex_parent - plate.position
	var from_bottom := apex.y >= plate.size.y * 0.5
	tail.base_y = plate.size.y if from_bottom else 0.0
	tail.base_x = clampf(apex.x, float(TAIL_W), maxf(float(TAIL_W), plate.size.x - float(TAIL_W)))
	tail.apex = apex
	tail.queue_redraw()


# ---------------------------------------------------------------- callouts (town)

## A building label over the camp scene (03 §3; KIT-01, TOWN-01, PIPE-08). Title
## and subtitle are Labels/Buttons; the whole plate is the hotspot, the title a
## Button named "Button" inside a plate named "Callout" so the tests can press
## "Tavern" and read its name and `Widgets.button_of` finds it.
##
## The plate is `PanelCallout` (W1-CHROME's chamfered 9-slice; the flat rim
## until then) with a 32px icon column at fill.x+12 and the text at x+60; the
## width is 60 + the widest line + 16. `icon` is a Texture2D (W1-ICONS'
## `building_<id>` through `Icons.at`; the column is an empty inset well until
## a screen passes one, so the geometry does not move when the glyph arrives).
## A 14x8 tail hangs from the bottom edge: with `anchor` finite (a point in the
## plate's parent's space — the scene host's, where Town.gd places these) the
## plate positions ITSELF so the tail's apex sits on the building's foot,
## clamped inside the scene band, the tail sliding along the edge to keep
## pointing; with no anchor the tail is centred and the caller places the
## plate, which is only kept inside the same band. THE BAND IS THE SCENE RECT
## (`SCENE`, screen pixels) CARRIED INTO THE PARENT'S SPACE — see
## `_callout_bounds`: on a framed screen the scene host sits at SCENE.position,
## so the band is (0,0)-(929,640) host-local; on the Town's full-bleed host at
## (0,0) it is (210,77)-(1139,717), i.e. the callouts keep off the rail and the
## sidebar in SCREEN coordinates, which is how Town.gd places them
## (review-W1-KIT F7: the first cut clamped against (0,0)-(929,640) on every
## host and dragged three of the five plates into the middle of the camp).
## `bounds` (parent's space) overrides the derived band for a parent that is
## not the scene host. `reason` non-empty = docs/13 §7's locked callout: the
## title Button disabled, title and subtitle dimmed to 0.55, and the reason
## printed INSIDE the plate in CAUTION (the `reasoned` treatment; "maybe" stays
## a Label for test_screens).
static func building_callout(name_text: String, subtitle: String, reason: String = "",
		icon: Texture2D = null, anchor: Vector2 = Vector2.INF, bounds: Rect2 = Rect2()) -> Control:
	var plate := panel("PanelCallout", 0)
	plate.name = "Callout"
	var pad := MarginContainer.new()
	pad.name = "Pad"
	# 4/4, not 6/6 (handoff-W2-TOWN): the reference plate is 52-57 tall and
	# ours settled at 84 — the title Button's theme margins are the rest, and a
	# zero-margin title variation through Theme.gd's `_button()` is a handoff.
	pad.add_theme_constant_override("margin_left", 4)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 4)
	pad.add_theme_constant_override("margin_bottom", 4)
	plate.add_child(pad)
	var h := row(CALLOUT_TEXT_X - CALLOUT_ICON_X - CALLOUT_ICON)
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	pad.add_child(h)

	# The icon column: a well when nothing is passed, the glyph when it is.
	var col_icon: Control
	if icon != null:
		var t := TextureRect.new()
		t.texture = icon
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col_icon = t
	else:
		col_icon = slot(null, CALLOUT_ICON, "SlotMini")
		col_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col_icon.name = "Icon"
	col_icon.custom_minimum_size = Vector2(CALLOUT_ICON, CALLOUT_ICON)
	col_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(col_icon)

	var col := column(1)
	var b := Button.new()
	b.text = name_text
	b.name = "Button"
	b.flat = true
	b.disabled = not reason.is_empty()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", Fonts.ui_semibold())
	b.add_theme_font_size_override("font_size", Type.at(Type.CALLOUT_TITLE, Theme_.scale_of(b)))
	b.add_theme_color_override("font_color", Palette.TEXT_TITLE)
	b.add_theme_color_override("font_hover_color", Palette.ACCENT_GOLD_LIGHT)
	b.add_theme_color_override("font_disabled_color", Palette.TEXT_MUTED)
	col.add_child(b)
	var sub := _label(subtitle, "LabelSmall")
	sub.name = "Subtitle"
	col.add_child(sub)
	var title_w: float = Fonts.ui_semibold().get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		Type.at(Type.CALLOUT_TITLE, Theme_.scale_of(b))).x
	var widest: float = maxf(title_w, _text_width(subtitle, "LabelSmall", sub))
	if not reason.is_empty():
		# A shut door is TWO rows like its neighbours (handoff-W2-TOWN,
		# TOWN-02): the verb line gives up its row to the reason, which is one
		# unwrapped line (a wrapping Label's first pass, before its column has
		# a width, broke every word onto its own line and the plate never
		# shrank back). The Subtitle keeps its node — hidden — so Town's own
		# `find_child("Subtitle")` hide stays a no-op.
		b.modulate = Color(1, 1, 1, REASONED_DIM)
		sub.visible = false
		col_icon.modulate = Color(1, 1, 1, REASONED_DIM)
		var why := _label(reason, "LabelSmall")
		why.name = "Reason"
		why.add_theme_color_override("font_color", Palette.CAUTION)
		col.add_child(why)
		widest = maxf(title_w, _text_width(reason, "LabelSmall", why))
	h.add_child(col)
	plate.custom_minimum_size = Vector2(ceilf(float(CALLOUT_TEXT_X) + widest + 16.0), 0)

	var tail := Tail.new()
	tail.name = "Tail"
	plate.add_child(tail)
	# PIPE-15 (W4-CURSOR): the ring behind the plate, lit by the title's focus
	# or by the pointer over the plate or the title — the plate's own
	# `mouse_entered` does not fire while a STOP-filtered child (the Button)
	# is the hovered control, so both are listened to. A shut door never
	# lights: it is not an affordance, and its Button cannot take focus.
	var outline := Outline.new()
	outline.name = "Outline"
	outline.tail = tail
	plate.add_child(outline)
	plate.resized.connect(outline.queue_redraw)
	if reason.is_empty():
		b.focus_entered.connect(func() -> void: outline.set_focused(true))
		b.focus_exited.connect(func() -> void: outline.set_focused(false))
		plate.mouse_entered.connect(func() -> void: outline.set_hovered(1, true))
		plate.mouse_exited.connect(func() -> void: outline.set_hovered(1, false))
		b.mouse_entered.connect(func() -> void: outline.set_hovered(2, true))
		b.mouse_exited.connect(func() -> void: outline.set_hovered(2, false))
	if anchor.is_finite():
		plate.item_rect_changed.connect(func() -> void: _place_callout(plate, tail, anchor, bounds))
		_place_callout(plate, tail, anchor, bounds)
	else:
		plate.item_rect_changed.connect(func() -> void: _centre_tail(plate, tail, bounds))
		_centre_tail(plate, tail, bounds)
	# The plate settles ITSELF (handoff-W2-TOWN): its first layout pass runs
	# under the default theme, before the deferred THEME_CHANGED reaches it, and
	# a Control never shrinks below a size a pass gave it — so once the theme
	# has landed the plate is put back to the size its content asks for. Two
	# deferrals, so it runs after everything the entering frame queued.
	plate.tree_entered.connect(func() -> void:
		(func() -> void: _settle_plate.call_deferred(plate)).call_deferred())
	return plate


static func _settle_plate(plate: Control) -> void:
	if is_instance_valid(plate) and plate.is_inside_tree():
		plate.size = plate.get_combined_minimum_size()


## The meta key Frame.gd leaves on a screen built on the shell (its
## `META_FOCUS_ORDER`), mirrored here as a literal the way ScreenRouter mirrors
## it: Widgets must not preload Frame (Frame preloads Widgets). It marks the
## SCREEN ROOT, which is where `SCENE`'s pixels are measured from.
const SCREEN_ROOT_META := "frame_focus_order"


## The band a callout is kept inside, in the plate's PARENT's space. `bounds`
## wins when given. Otherwise it is `SCENE` (screen pixels: 210,77 929x640 —
## the rail's right edge to the sidebar, the header rule to the strip) carried
## into the parent's space by the parent's offset from the screen root: the
## offset is summed up the Control chain and STOPS at the screen (the node
## carrying Frame's focus meta), so a shot host that letterboxes the screen
## (tools/shot.gd's wide `keep`) is not counted. A framed scene host sits AT
## SCENE.position, so its band is (0,0)-(929,640); the Town's full-bleed host
## sits at (0,0), so its band is SCENE itself. The band is then cut to the
## parent's own rect (a framed host is 928 wide; a smaller parent keeps its
## plates inside itself). With no parent yet — construction, the unit tests —
## it is SCENE at the origin, the framed reading, and the real placement
## happens on the first `item_rect_changed` after the plate is parented (a
## PanelContainer's size is settled by layout, never at construction).
static func _callout_bounds(plate: Control, bounds: Rect2) -> Rect2:
	if bounds.has_area():
		return bounds
	var parent := plate.get_parent() as Control
	if parent == null:
		return Rect2(Vector2.ZERO, Vector2(SCENE.size))
	var offset := Vector2.ZERO
	var n: Node = parent
	while n is Control and not n.has_meta(SCREEN_ROOT_META):
		offset += (n as Control).position
		n = n.get_parent()
	var band := Rect2(Vector2(SCENE.position) - offset, Vector2(SCENE.size))
	if parent.size.x > 0.0 and parent.size.y > 0.0:
		var cut := band.intersection(Rect2(Vector2.ZERO, parent.size))
		if cut.has_area():
			band = cut
	return band


## `want` (the plate's top-left, parent's space) kept inside the band with a
## tail's depth spare under the plate. A plate wider or taller than the band
## sits at the band's origin.
static func _clamp_to_band(want: Vector2, plate: Control, band: Rect2) -> Vector2:
	var limit := band.position + band.size - plate.size - Vector2(0, float(TAIL_H))
	return Vector2(clampf(want.x, band.position.x, maxf(band.position.x, limit.x)),
		clampf(want.y, band.position.y, maxf(band.position.y, limit.y))).round()


## No anchor: the caller placed the plate, so only keep it inside the scene
## band (a locked callout is 60 + 200 + 16 wide and Town's Blacksmith sits at
## screen x=900, so its right rim ran under the sidebar at 1142 — W1-KIT shot 1;
## the band moves it to 863) and hang the tail from the middle of the bottom
## edge.
static func _centre_tail(plate: Control, tail: Tail, bounds: Rect2 = Rect2()) -> void:
	var want := _clamp_to_band(plate.position, plate, _callout_bounds(plate, bounds))
	if plate.position != want:
		plate.position = want
	tail.base_y = plate.size.y
	tail.base_x = plate.size.x * 0.5
	tail.apex = Vector2(plate.size.x * 0.5, plate.size.y + float(TAIL_H))
	tail.queue_redraw()


## The plate under its anchor: centred on it, one tail above it, clamped inside
## the scene band (in the parent's space, see `_callout_bounds`), the tail then
## aimed at the anchor so a clamped plate still points at its building.
static func _place_callout(plate: Control, tail: Tail, anchor: Vector2,
		bounds: Rect2 = Rect2()) -> void:
	var want := Vector2(anchor.x - plate.size.x * 0.5, anchor.y - plate.size.y - float(TAIL_H))
	want = _clamp_to_band(want, plate, _callout_bounds(plate, bounds))
	if plate.position != want:
		plate.position = want
	_aim_tail(plate, tail, anchor)


# ---------------------------------------------------------------- motion

## THE ONLY SANCTIONED WAY TO MAKE A TWEEN IN THIS PROJECT, and
## `tools/lint_motion.sh` fails the build on a `create_tween(` anywhere else.
##
## The reason is docs/13 §13's reduced-motion row, and the reason it is a LINT
## rather than a convention is that the setting had exactly one consumer for
## months — `SceneStage`, which stops its own flames — while three M6 juice items
## were queued to add tweens that would each have had to remember it. A setting
## every new animation must opt into is a setting that is wrong by default.
##
## The duration still comes from `GameSettings.motion_duration()`, because this
## cannot know which row of §12.2 a caller means, and §13's stamp exception has
## to be stated at the call site:
##
##     var t := Widgets.tween(badge)
##     t.tween_property(badge, "scale", Vector2.ONE, Settings.motion_duration(120, 60))
##
## Returns a real Tween bound to `node`, so it dies with the node rather than
## outliving the screen that made it.
static func tween(node: Node) -> Tween:
	if node == null or not node.is_inside_tree():
		return null
	return node.create_tween()
