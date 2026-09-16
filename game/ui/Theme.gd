extends RefCounted
## Builds the ONE Theme the whole interface inherits.
##
## art/ref/specs/06-ui-component-kit.md Table B decides, per component, whether
## a StyleBoxFlat reproduces the reference exactly (round panels, slots, chips,
## wells, bar tracks) or whether hand-drawn pixel detail needs a texture
## (chamfered corners, gradients, the CTA's double rim, the nav tab's rivet).
## Textures come from tools/aseprite/gen_ui.lua and gen_wipe.lua; every colour
## here is a Palette ROLE — this file holds no hex colour literal at all, not
## even in a comment, and tests/unit/test_theme_kit.gd keeps it that way
## (KIT-10; W4-HYGIENE's lint greps for one). Screens never build
## a StyleBox — they set `theme_type_variation`. This file is the only one that
## names a 9-slice path (00-plan §0.2).
##
## Built once per text scale, on first use, and cached, so a test that never
## draws pays nothing. Screens reach it through ONE door, `current(self)`.

const Palette = preload("res://game/ui/Palette.gd")
const Fonts = preload("res://game/ui/Fonts.gd")
const Type = preload("res://game/ui/Type.gd")
const Services = preload("res://game/core/Services.gd")

const UI := "res://game/assets/ui/"

## One Theme PER TEXT SCALE. docs/13 §4.4's three steps are the only keys that can
## appear — `Type.step()` snaps anything else — so the cache is at most three entries
## and changing the scale is a lookup, not a rebuild of a singleton the process has
## already handed out to eleven screens.
static var _themes: Dictionary = {}


## docs/13 §13 marks text scaling **Blocking: Yes**. `scale` is one of §4.4's three
## steps; anything else falls back to 100, which is `GameSettings`' own documented
## recovery for the key (see `Type.step`).
##
## SCALE 100 IS BYTE-IDENTICAL TO THE UNSCALED THEME, by construction rather than by
## luck: `Type.at(size, 100)` returns `size` untouched, so the art pass's pixel-diff
## baselines (BUILD_STATE.md: Kit 16.9 / Town 26.3 / RaidPrep 20.2 MAE) cannot move.
## `tests/unit/test_a11y_legibility.gd` asserts that font-size by font-size, and
## `tests/unit/test_text_scale.gd` asserts it on a mounted screen.
static func get_theme(scale: int = Type.SCALE_DEFAULT) -> Theme:
	var pct: int = Type.step(scale)
	if not _themes.has(pct):
		_themes[pct] = build(pct)
	return _themes[pct]


## THE DOOR (RULES-02). `text_scale` was live on the options page and read by no
## screen: every `build()` called `get_theme()` bare and got 100 whatever the
## player had chosen. Now every screen, and Boot's overlay, sets
## `theme = Theme_.current(self)`, and this is the only place a screen learns
## the scale — `tests/unit/test_text_scale.gd` pins both halves, the arithmetic
## on a mounted Town and the source text of every screen naming this call.
##
## `who` may be outside the tree (the test runner, tools/): `Services.find` falls
## back to the main loop's root, and an absent autoload means 100 — the same
## answer `GameSettings` gives a missing settings file. A screen is rebuilt on
## every mount, so a scale changed on the options page reaches the next screen
## by construction; Settings re-mounts itself on Apply for the same reason.
static func current(who: Node) -> Theme:
	return get_theme(scale_of(who))


## The player's text scale as one of §4.4's steps. For the few sites that set a
## font size directly instead of through a variation — the CTA-adjacent meta
## buttons, the wipe stamp — the route is `Type.at(size, Theme_.scale_of(self))`,
## never a raw `Type.*` constant (CRITIC-G15).
static func scale_of(who: Node) -> int:
	var settings: Node = Services.find(who, "GameSettings")
	if settings == null:
		return Type.SCALE_DEFAULT
	return Type.step(int(settings.get_value("text_scale")))


# ---------------------------------------------------------------- style helpers

static func flat(fill: Color, border: Color = Color(0, 0, 0, 0), width: int = 0,
		radius: int = 0, margin: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.anti_aliasing = false   # 1px reference lines, not softened
	return s


static func tex(file: String, l: int, t: int, r: int, b: int, margin: int = -1,
		modulate: Color = Color.WHITE, bottom: int = -1) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(UI + file)
	s.texture_margin_left = l
	s.texture_margin_top = t
	s.texture_margin_right = r
	s.texture_margin_bottom = b
	var m := margin if margin >= 0 else maxi(maxi(l, r), maxi(t, b))
	s.set_content_margin_all(m)
	if bottom >= 0:
		s.content_margin_bottom = bottom     # a plate with a second line under the label
	s.modulate_color = modulate
	return s


static func empty() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()


## docs/13 §12.3: "pressed = 1px inward offset". A copy of `s` whose content
## sits one pixel lower, so the label drops with the plate instead of floating
## over an inverted bevel (KIT-11). Every pressed box below goes through here.
static func pressed(s: StyleBox) -> StyleBox:
	var p: StyleBox = s.duplicate()
	p.content_margin_top = s.content_margin_top + 1
	return p


## A disabled box: the same silhouette, dimmed, so the layout never jumps when a
## control loses its reason to exist (06 §3 "keeps the silhouette").
static func dimmed(s: StyleBox, k: float = 0.5) -> StyleBox:
	var d: StyleBox = s.duplicate()
	if d is StyleBoxTexture:
		(d as StyleBoxTexture).modulate_color = Color(k, k, k)
	elif d is StyleBoxFlat:
		var f := d as StyleBoxFlat
		f.bg_color = f.bg_color.darkened(1.0 - k)
		f.border_color = f.border_color.darkened(1.0 - k)
	return d


## The keyboard focus ring — ONE shape for every focusable widget, because
## docs/13 §12.3 says so in as many words: "Identical shape on every widget.
## Always visible — no `:focus-visible` suppression."
##
## `expand_margin` is the load-bearing property. Without it a StyleBoxFlat's
## border draws INSIDE the control's rect, which is where this ring used to be
## (1px, inside) — §12.3 requires it "drawn *outside* the bounds so it never
## shifts layout", and an expand margin is the only way a StyleBox leaves its
## own rect. 2px wide, 2px out.
##
## Two departures from §12.3's wording, both deliberate:
##   * the hue is `edge.steel`, not doc 13's `brass.base`. The art pass
##     re-anchored the focus/selected role to the colour sampled off the
##     reference concepts (Palette.EDGE_STEEL, art/ref/specs/04 §5 row
##     `accent.steel`: "Selection, focus ring, active state"). It measures
##     4.7:1 on the panel ground, so §13's 3:1 floor for UI boundaries is met
##     and nothing is lost by keeping the reference's colour. Do not 'fix' this
##     back to brass — the 2px-and-outside half is what the design owns here.
##   * §12.3's "1px `ink.body` outer offset" is NOT drawn. It reads as a dark
##     outline separating brass from a light ground; on this dark chrome the
##     ink token is a near-white (Palette.TEXT_BODY #F7F1E1) and a 1px
##     near-white halo would be a glow, not an offset. build/plan/q-a11y-keys.md
##     carries the proposed docs/15 entry for the ruling.
static func focus_ring() -> StyleBoxFlat:
	var s := flat(Color(0, 0, 0, 0), Palette.EDGE_STEEL, 2, 3)
	s.set_expand_margin_all(2)
	return s


## `scale` is threaded rather than read from a static, so `build()` stays a pure function
## of its argument — two scales must be able to exist at once, which is the whole reason
## `_themes` is a dictionary. docs/13 §4.4 scales TYPE and nothing else; the `flat()` and
## `tex()` margins are chrome and are deliberately left alone.
static func _label(t: Theme, name: String, font: Font, size: int, color: Color,
		scale: int = Type.SCALE_DEFAULT) -> void:
	t.add_type(name)
	t.set_type_variation(name, "Label")
	t.set_font("font", name, font)
	t.set_font_size("font_size", name, Type.at(size, scale))
	t.set_color("font_color", name, color)


## A PanelContainer variation: the one line every plate below used to spell out.
static func _panel(t: Theme, name: String, box: StyleBox) -> void:
	t.add_type(name)
	t.set_type_variation(name, "PanelContainer")
	t.set_stylebox("panel", name, box)


## Same contract as `_label`: the caller passes an unscaled `Type.*` and this multiplies.
##
## EVERY Button-family variation is registered here and nowhere else (RULES §2,
## test_a11y.gd:229-277): the focus ring is set unconditionally, so a texture
## button may replace normal/hover/pressed/disabled and can never lose `focus`.
##
## `scale` is trailing, so most call sites below have to spell out the two
## colour defaults to reach it. That is deliberately ugly and deliberately explicit —
## `Color(0, 0, 0, 0)` is this function's own "same as `color`" sentinel, so writing it
## invents nothing, and the alternative (a static "scale currently being built") would
## make `build()` read a hidden global and stop two scales existing at once.
static func _button(t: Theme, name: String, base: String, normal: StyleBox, hover: StyleBox,
		pressed_box: StyleBox, disabled: StyleBox, font: Font, size: int, color: Color,
		hover_color: Color = Color(0, 0, 0, 0), disabled_color: Color = Color(0, 0, 0, 0),
		scale: int = Type.SCALE_DEFAULT) -> void:
	t.add_type(name)
	if base != "" and base != name:
		t.set_type_variation(name, base)
	t.set_stylebox("normal", name, normal)
	t.set_stylebox("hover", name, hover)
	t.set_stylebox("pressed", name, pressed_box)
	t.set_stylebox("disabled", name, disabled)
	t.set_stylebox("focus", name, focus_ring())
	t.set_font("font", name, font)
	t.set_font_size("font_size", name, Type.at(size, scale))
	t.set_color("font_color", name, color)
	t.set_color("font_hover_color", name, hover_color if hover_color.a > 0 else color)
	t.set_color("font_pressed_color", name, color)
	t.set_color("font_focus_color", name, color)
	t.set_color("font_disabled_color", name,
		disabled_color if disabled_color.a > 0 else Palette.TEXT_SLATE)


# ---------------------------------------------------------------- the theme

## docs/13 §4.4's text scale is applied HERE and only here: every size in this function
## goes through `Type.at()` inside `_label`/`_button`, so a screen never scales anything
## itself and cannot forget to. `scale` defaults to 100, at which `Type.at()` is the
## identity — see `get_theme()`.
static func build(scale: int = Type.SCALE_DEFAULT) -> Theme:
	var t := Theme.new()
	t.default_font = Fonts.ui()
	t.default_font_size = Type.at(Type.BODY, scale)
	t.set_color("font_color", "Label", Palette.TEXT_BODY)

	# ---- labels (05-typography.md §3) --------------------------------------
	_label(t, "LabelWordmark", Fonts.display(), Type.WORDMARK, Palette.TEXT_TITLE, scale)
	_label(t, "LabelWordmarkCompact", Fonts.display(), Type.WORDMARK_COMPACT, Palette.TEXT_TITLE, scale)
	# 01 §5: the wordmark carries a 1px dark warm outline, never black.
	for wm in ["LabelWordmark", "LabelWordmarkCompact"]:
		t.set_color("font_outline_color", wm, Palette.INK_WORDMARK_OUTLINE)
		t.set_constant("outline_size", wm, 1)
	_label(t, "LabelTagline", Fonts.ui(), Type.TAGLINE, Palette.TEXT_MUTED_WARM, scale)
	_label(t, "LabelSection", Fonts.ui_semibold(), Type.SECTION, Palette.TEXT_TITLE, scale)
	_label(t, "LabelSectionSm", Fonts.ui_semibold(), Type.SECTION_SM, Palette.TEXT_TITLE, scale)
	_label(t, "LabelSubject", Fonts.ui_medium(), Type.SUBJECT, Palette.TEXT_BODY, scale)
	_label(t, "LabelName", Fonts.ui_medium(), Type.NAME, Palette.TEXT_TITLE, scale)
	_label(t, "LabelLevel", Fonts.ui_tabular(400), Type.LEVEL, Palette.TEXT_NUMERIC, scale)
	# The variations that carry a morale glyph draw it from the authored face
	# sheet for THIS scale (HALL-05, CRITIC-C09; W4-PIP: faces_30 / faces_36 at
	# 125 / 150, so a face never sits 24px on a 36px line) and draw the
	# emoji-free figure's "|" at the period's own advance, so "|||||....." is
	# even (CRITIC-G09). Fonts.with_pips puts a one-glyph bar font in front of
	# Fira Sans and the faces behind it, and leaves the text — and every test
	# that reads it — alone. The size handed in is the scaled pixel size the
	# Label will ask for, which is where the bar is registered.
	var morale_font: Font = Fonts.with_pips(Fonts.ui_tabular(500), Type.at(Type.MORALE_VALUE, scale), scale)
	var body_font: Font = Fonts.with_pips(Fonts.ui(), Type.at(Type.BODY, scale), scale)
	var class_font: Font = Fonts.with_pips(Fonts.ui(), Type.at(Type.CLASS, scale), scale)
	var pip_font: Font = Fonts.with_pips(Fonts.ui(), Type.at(Type.SMALL, scale), scale, false)
	_label(t, "LabelClass", class_font, Type.CLASS, Palette.TEXT_SLATE, scale)
	_label(t, "LabelQuote", Fonts.ui_italic(), Type.QUOTE, Palette.TEXT_SLATE, scale)
	_label(t, "LabelLabel", Fonts.ui(), Type.LABEL, Palette.TEXT_LABEL, scale)
	_label(t, "LabelLabelLg", Fonts.ui(), Type.LABEL_LG, Palette.TEXT_MUTED, scale)
	_label(t, "LabelMuted", Fonts.ui(), Type.BODY, Palette.TEXT_MUTED, scale)
	_label(t, "LabelBody", body_font, Type.BODY, Palette.TEXT_BODY, scale)
	_label(t, "LabelSmall", Fonts.ui(), Type.SMALL, Palette.TEXT_LOG, scale)
	# LabelPip (CRITIC-G09, W4-PIP): LabelSmall's size, colour and line height
	# with the pip bar in front and NO face sheet — the small morale line
	# ("starts at 52 |||||.....") for a site that prints the figure at SMALL.
	# The sheet would make the line 36 tall at 150 and push the Tavern seat
	# card's button off its plate (report-W4-PIP); with the option off the
	# line draws what LabelSmall draws. LabelSmall itself stays plain
	# (tests/unit/test_theme_kit.gd: it carries no fallback).
	_label(t, "LabelPip", pip_font, Type.SMALL, Palette.TEXT_LOG, scale)
	_label(t, "LabelLog", body_font, Type.BODY, Palette.TEXT_MUTED_WARM, scale)
	_label(t, "LabelChip", Fonts.ui_tabular(500), Type.CHIP, Palette.TEXT_MUTED, scale)
	_label(t, "LabelFigure", Fonts.ui_tabular(600), Type.FIGURE_XL, Palette.DANGER, scale)
	_label(t, "LabelMorale", morale_font, Type.MORALE_VALUE, Palette.TEXT_TITLE, scale)
	_label(t, "LabelCtaCost", Fonts.ui_tabular(500), Type.CTA_COST, Palette.ACCENT_GOLD, scale)
	_label(t, "LabelBossName", Fonts.ui_semibold(), Type.BOSS_NAME, Palette.TEXT_BODY, scale)
	_label(t, "LabelObjective", Fonts.ui_semibold(), Type.OBJECTIVE, Palette.TEXT_TITLE, scale)
	_label(t, "LabelStack", Fonts.ui_semibold(), Type.STACK, Palette.TEXT_TITLE, scale)
	# Floating combat numbers (PIPE-01, CRITIC-C05: Type.gd's 28/34 are the ruling,
	# 05 §5's 2px outline). W1-KIT's damage_number() names these; the stage places them.
	_label(t, "LabelDamage", Fonts.ui_tabular(600), Type.DAMAGE, Palette.DANGER, scale)
	_label(t, "LabelDamageCrit", Fonts.ui_tabular(600), Type.DAMAGE_CRIT, Palette.CRIT, scale)
	_label(t, "LabelHeal", Fonts.ui_tabular(600), Type.DAMAGE, Palette.POSITIVE, scale)
	# UI-34 (W7-STAGE): the party's OWN damage on the enemy, so the two
	# directions read as two colours — the boss's harm is DANGER red, the
	# raiders' is the CTA family's lit warm tone (Concept 2's "-842" on the
	# boss is orange). CTA_TOP itself is the plate's dark fill and vanishes
	# on the cave; ACCENT_GOLD_LIGHT is that plate's lit top rule.
	_label(t, "LabelDamageDealt", Fonts.ui_tabular(600), Type.DAMAGE, Palette.ACCENT_GOLD_LIGHT, scale)
	for dn in ["LabelDamage", "LabelDamageCrit", "LabelHeal", "LabelDamageDealt"]:
		t.set_color("font_outline_color", dn, Palette.INK_NUMBER_OUTLINE)
		t.set_constant("outline_size", dn, 2)

	# ---- panels -------------------------------------------------------------
	# Major panel: chamfered double line (01 §2, corner montage) — a texture.
	_panel(t, "PanelWarm", tex("panel_warm.png", 12, 12, 12, 12, 14))
	_panel(t, "PanelSteel", tex("panel_steel.png", 12, 12, 12, 12, 14))
	# 06 §1 / KIT-09: the four corner ornaments are NOT baked into the 9-slice
	# (they would stretch); Widgets.panel overlays them from this icon slot,
	# tinted by `ornament_tint`. White-on-alpha, one sprite, flipped per corner.
	var ornament: Texture2D = load(UI + "panel_corner_ornament.png")
	t.set_icon("corner_ornament", "PanelWarm", ornament)
	t.set_color("ornament_tint", "PanelWarm", Palette.EDGE_BRONZE_LIT)
	t.set_icon("corner_ornament", "PanelSteel", ornament)
	t.set_color("ornament_tint", "PanelSteel", Palette.EDGE_ABILITY)
	# Round panel: roster cards, event log (01 §3/§4) — flat, radius 6, 1px rim.
	# KIT-19 records the conflict: 06 §8 measures a 2px light-outer bevel on the
	# same card that 01 §3 measures as this 1px #514D4C core; 1px is kept.
	_panel(t, "PanelRound", flat(Palette.SURFACE_CARD, Palette.EDGE_CARD, 1, 6, 0))
	# The selected card (KIT-10: Tavern hand-rolled this rim; the Roster can now share it).
	_panel(t, "PanelRoundSelected", flat(Palette.SURFACE_CARD, Palette.EDGE_STEEL, 1, 6, 0))
	# Well / inset (06 §7.1).
	_panel(t, "PanelInset", flat(Palette.SURFACE_WELL, Palette.EDGE_WELL, 1, 0, 0))
	# Boss-art card inside the sidebar (01 §2): radius 6, 1px grey rim.
	_panel(t, "PanelCard", flat(Palette.SURFACE_ART_CARD, Palette.EDGE_ART_CARD, 1, 6, 0))
	# Callouts (06 §6): 2px severity rim on the callout base; the top-right
	# flourish (KIT-09) is an icon slot the composite tints by band.
	_panel(t, "PanelCalloutDanger", flat(Palette.SURFACE_CALLOUT, Palette.EDGE_CALLOUT_DANGER, 2, 0, 12))
	_panel(t, "PanelCalloutCaution", flat(Palette.SURFACE_CALLOUT, Palette.CAUTION, 2, 0, 12))
	_panel(t, "PanelCalloutPositive", flat(Palette.SURFACE_CALLOUT, Palette.POSITIVE, 2, 0, 12))
	var flourish: Texture2D = load(UI + "callout_flourish.png")
	for cv in ["PanelCalloutDanger", "PanelCalloutCaution", "PanelCalloutPositive"]:
		t.set_icon("flourish", cv, flourish)
	# Resource chip (03 §1: chamfered octagon is the system choice).
	_panel(t, "PanelChip", tex("chip_chamfer.png", 12, 12, 12, 12, 0))
	# The building callout (03 §3) and the speech plate (STAGE-10, KIT-02) share
	# ONE chrome until Q04 rules the bubble's fill (CRITIC-C02): the chamfered
	# two-line 9-slice, fill SURFACE_BUBBLE, 8px content pad as before. The 14x8
	# tail is the `tail` icon; the composites (W1-KIT) place it on the anchor.
	_panel(t, "PanelCallout", tex("callout_plate.png", 6, 6, 6, 6, 8))
	_panel(t, "PanelBubble", tex("bubble_plate.png", 6, 6, 6, 6, 8))
	var tail: Texture2D = load(UI + "callout_tail.png")
	t.set_icon("tail", "PanelCallout", tail)
	t.set_icon("tail", "PanelBubble", tail)
	# The emote marker (06 §8): a 40x44 cream sprite whose body centres a 16px
	# glyph — content margins 12/10/12/18 leave exactly 16x16 inside.
	var emote := tex("emote_frame.png", 12, 10, 12, 18, 0)
	emote.content_margin_left = 12
	emote.content_margin_top = 10
	emote.content_margin_right = 12
	emote.content_margin_bottom = 18
	_panel(t, "PanelEmote", emote)
	# The stamp (docs/13 §7, CRITIC-C08): a worn double rule around a Label.
	# The texture is white-on-alpha at ~70%; DANGER is the default tint and
	# Widgets.stamp re-tints a copy for CAUTION. Edges TILE so the fibre keeps
	# its grain instead of stretching into streaks.
	var stamp := tex("stamp_frame.png", 8, 8, 8, 8, 6, Palette.DANGER)
	stamp.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	stamp.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	stamp.content_margin_left = 10
	stamp.content_margin_right = 10
	_panel(t, "PanelStamp", stamp)
	# The Adventure's Board (TOWN-24): cork behind, paper notices on it, a pin
	# on each — the pin is an icon slot on PanelPaper.
	var cork := tex("cork_tile.png", 0, 0, 0, 0, 12)
	cork.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	cork.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	_panel(t, "PanelCork", cork)
	_panel(t, "PanelPaper", flat(Palette.SURFACE_PAPER, Palette.EDGE_PAPER, 1, 0, 10))
	t.set_icon("pin", "PanelPaper", load(UI + "pin.png"))

	# ---- slots (06 §2) -----------------------------------------------------
	_panel(t, "Slot", flat(Palette.SURFACE_SLOT, Palette.SLOT_RIM, 2, 4, 0))
	_panel(t, "SlotBronze", flat(Palette.SURFACE_SLOT_BRONZE, Palette.EDGE_PORTRAIT_BRONZE, 2, 5, 0))
	_panel(t, "SlotAbility", flat(Palette.SURFACE_ABILITY, Palette.EDGE_ABILITY, 1, 3, 0))
	_panel(t, "SlotReady", flat(Palette.SURFACE_ABILITY, Palette.EDGE_READY_GOLD, 1, 3, 0))
	# 06 §2 "Weapon slot (C2) 62x74": a taller instance of the ability slot with a
	# 1px steel rim, radius 4 (HALL-07's paper doll).
	_panel(t, "SlotWeapon", flat(Palette.SURFACE_ABILITY, Palette.EDGE_STEEL_DIM, 1, 4, 0))
	# Portrait frame on the roster card (01 §3).
	_panel(t, "PortraitFrame", flat(Palette.SURFACE_PORTRAIT, Palette.EDGE_SLATE_LIGHT, 1, 6, 0))
	# Mini-grid cell (01 §4.1).
	_panel(t, "SlotMini", flat(Palette.SURFACE_MINI, Palette.EDGE_MINI, 1, 4, 0))

	# ---- buttons -----------------------------------------------------------
	# Primary CTA (06 §3, KIT-11): four plates. Hover is the brighter plate inside
	# its 6px glow — the glow texture is drawn OUTSIDE the control (expand 6) so
	# the plate lands where the normal one was; pressed is the inverted bevel
	# with the label one pixel lower; disabled keeps the silhouette, dimmed.
	var cta_n := tex("cta_plate.png", 14, 14, 14, 14, 8)
	var cta_h := tex("cta_glow.png", 20, 20, 20, 20, 8)
	cta_h.set_expand_margin_all(6)
	var cta_p := pressed(tex("cta_plate_pressed.png", 14, 14, 14, 14, 8))
	var cta_d := tex("cta_plate.png", 14, 14, 14, 14, 8, Color(0.45, 0.42, 0.42))
	_button(t, "ButtonCta", "Button", cta_n, cta_h, cta_p, cta_d,
		Fonts.ui_semibold(), Type.CTA, Palette.TEXT_ON_CTA, Palette.TEXT_TITLE,
		Palette.TEXT_DISABLED_ON_CTA, scale)
	# The CTA that carries a cost line INSIDE its plate (01 §2: label baseline
	# 646, cost baseline 672, in a 617–686 plate): a taller bottom margin lifts
	# the label; Widgets.cta parents the cost Label into the free band.
	var ctac_h := tex("cta_glow.png", 20, 20, 20, 20, 8, Color.WHITE, 30)
	ctac_h.set_expand_margin_all(6)
	_button(t, "ButtonCtaCost", "ButtonCta",
		tex("cta_plate.png", 14, 14, 14, 14, 8, Color.WHITE, 30),
		ctac_h,
		pressed(tex("cta_plate_pressed.png", 14, 14, 14, 14, 8, Color.WHITE, 30)),
		tex("cta_plate.png", 14, 14, 14, 14, 8, Color(0.45, 0.42, 0.42), 30),
		Fonts.ui_semibold(), Type.CTA, Palette.TEXT_ON_CTA, Palette.TEXT_TITLE,
		Palette.TEXT_DISABLED_ON_CTA, scale)
	# Secondary (06 §7.2): bronze rim, navy plate, same silhouette; pressed is
	# the inverted plate one pixel down.
	var sec_n := tex("btn_secondary.png", 14, 14, 14, 14, 8)
	var sec_h := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(1.22, 1.22, 1.22))
	var sec_p := pressed(tex("btn_secondary_pressed.png", 14, 14, 14, 14, 8))
	var sec_d := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(0.5, 0.5, 0.5))
	_button(t, "Button", "", sec_n, sec_h, sec_p, sec_d,
		Fonts.ui_medium(), Type.BODY, Palette.TEXT_TITLE, Palette.TEXT_TITLE,
		Palette.TEXT_DISABLED, scale)
	# Icon button (06 §7.2): cog / fast-forward chrome. Pressed darkens and drops
	# a pixel; disabled is the dimmed plate (KIT-11: it used to be `normal`).
	var ico_n := tex("btn_icon.png", 12, 12, 12, 12, 6)
	var ico_h := tex("btn_icon.png", 12, 12, 12, 12, 6, Color(1.25, 1.25, 1.25))
	var ico_p := pressed(tex("btn_icon.png", 12, 12, 12, 12, 6, Color(0.8, 0.8, 0.8)))
	_button(t, "ButtonIcon", "Button", ico_n, ico_h, ico_p, dimmed(ico_n),
		Fonts.ui_medium(), Type.SMALL, Palette.TEXT_MUTED_WARM,
		Color(0, 0, 0, 0), Color(0, 0, 0, 0), scale)
	# Portrait-slot-chromed button ("Team" / "Edit", 06 §7.2).
	var ps := flat(Palette.SURFACE_PLATE, Palette.EDGE_BRONZE_RIM, 2, 5, 4)
	var ps_h := flat(Palette.SURFACE_PLATE_LIT, Palette.EDGE_BRONZE_LIT, 2, 5, 4)
	var ps_p := pressed(flat(Palette.SURFACE_SLOT_BRONZE, Palette.EDGE_BRONZE_LIT, 2, 5, 4))
	_button(t, "ButtonPortrait", "Button", ps, ps_h, ps_p, dimmed(ps),
		Fonts.ui(), Type.SMALL, Palette.TEXT_MUTED_WARM,
		Color(0, 0, 0, 0), Color(0, 0, 0, 0), scale)
	# Nav rail item (01 §6 / 06 §5.1): active = riveted tab texture, inactive = nothing.
	var nav_a := tex("nav_tab_active.png", 8, 8, 20, 8, 0)
	var nav_h := tex("nav_tab_active.png", 8, 8, 20, 8, 0, Color(1, 1, 1, 0.4))
	_button(t, "NavItem", "Button", empty(), nav_h, nav_a, empty(),
		Fonts.ui_medium(), Type.NAV, Palette.INK_NAV, Palette.TEXT_TITLE, Palette.INK_NAV_DISABLED,
		scale)
	_button(t, "NavItemActive", "Button", nav_a, nav_a, nav_a, nav_a,
		Fonts.ui_medium(), Type.NAV, Palette.INK_NAV_ACTIVE, Palette.INK_NAV_ACTIVE,
		Color(0, 0, 0, 0), scale)
	# Plain slot as a button (interactive item slots — Market, Detail). Pressed
	# is the lit rim on the deep plate, one pixel down; disabled dims (KIT-11).
	var slot_b := flat(Palette.SURFACE_SLOT, Palette.SLOT_RIM, 2, 4, 0)
	var slot_bh := flat(Palette.SURFACE_SLOT_LIT, Palette.SLOT_RIM_LIT, 2, 4, 0)
	var slot_bp := pressed(flat(Palette.SURFACE_SLOT_BRONZE, Palette.SLOT_RIM_LIT, 2, 4, 0))
	_button(t, "ButtonSlot", "Button", slot_b, slot_bh, slot_bp, dimmed(slot_b),
		Fonts.ui(), Type.SMALL, Palette.TEXT_MUTED,
		Color(0, 0, 0, 0), Color(0, 0, 0, 0), scale)
	# Mini-grid tile as a button (01 §4.1).
	var mini_b := flat(Palette.SURFACE_MINI, Palette.EDGE_MINI, 1, 4, 0)
	var mini_h := flat(Palette.SURFACE_PLATE_LIT, Palette.EDGE_STEEL, 1, 4, 0)
	_button(t, "ButtonMini", "Button", mini_b, mini_h, pressed(mini_h), mini_b,
		Fonts.ui(), Type.SMALL, Palette.TEXT_MUTED,
		Color(0, 0, 0, 0), Color(0, 0, 0, 0), scale)
	# The picked mini tile (W5-KIT3, from Facilities' HALL-22 override): a
	# toggle held PRESSED wears the lit plate inside a 2px gold rim — spec 06
	# §2's ready rim, the token ButtonChip presses with — instead of the other
	# tiles being dimmed to hint at it. The same plate under the pointer
	# (`hover_pressed`), so the rim never blinks off on hover. No 1px drop: a
	# held toggle is a state, not a press. Facilities adopts this by name.
	var mini_picked := flat(Palette.SURFACE_PLATE_LIT, Palette.EDGE_READY_GOLD, 2, 4, 0)
	_button(t, "ButtonMiniPicked", "ButtonMini", mini_b, mini_h, mini_picked, mini_b,
		Fonts.ui(), Type.SMALL, Palette.TEXT_MUTED,
		Color(0, 0, 0, 0), Color(0, 0, 0, 0), scale)
	t.set_stylebox("hover_pressed", "ButtonMiniPicked", mini_picked)
	# The card's action button (W5-KIT3): the secondary plates at the SMALL
	# size with 6px top/bottom content margins — 29 tall at 100% — so a card's
	# band (Cheer up / Manage and a shut button's reason) fits the 262 card it
	# sits in. The 9-slice's 14px corners meet at 28, so 6 is the floor; the
	# side margins stay the secondary's 8.
	var act_n := tex("btn_secondary.png", 14, 14, 14, 14, 8)
	var act_h := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(1.22, 1.22, 1.22))
	var act_p := tex("btn_secondary_pressed.png", 14, 14, 14, 14, 8)
	var act_d := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(0.5, 0.5, 0.5))
	for act in [act_n, act_h, act_p, act_d]:
		(act as StyleBox).content_margin_top = 6
		(act as StyleBox).content_margin_bottom = 6
	_button(t, "ButtonCardAction", "Button", act_n, act_h, pressed(act_p), act_d,
		Fonts.ui_medium(), Type.SMALL, Palette.TEXT_TITLE, Palette.TEXT_TITLE,
		Palette.TEXT_DISABLED, scale)
	# The quiet button (CRITIC-C14): "Back to town" / "Back to menu" on the hub
	# sidebars — no plate, a hairline on hover, the same focus ring as every
	# other. A Button, not a LinkButton, because the tests read Button.text.
	var quiet_h := flat(Color(0, 0, 0, 0), Palette.EDGE_SLATE, 1, 3, 4)
	_button(t, "ButtonQuiet", "Button", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3, 4),
		quiet_h, pressed(flat(Color(0, 0, 0, 0), Palette.EDGE_STEEL_DIM, 1, 3, 4)),
		flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3, 4),
		Fonts.ui_medium(), Type.LINK, Palette.TEXT_MUTED_WARM, Palette.TEXT_TITLE,
		Palette.TEXT_DISABLED, scale)
	# The notice row (RULES-07, TOWN-25): the Adventure's Board's rows become
	# full-rect Buttons with the paper's chrome, so a keyboard can pin one.
	# Pressed = selected: the steel rim.
	var notice_n := flat(Palette.SURFACE_PAPER, Palette.EDGE_PAPER, 1, 0, 8)
	var notice_h := flat(Palette.SURFACE_PAPER_LIT, Palette.EDGE_BRONZE_LIT, 1, 0, 8)
	var notice_p := pressed(flat(Palette.SURFACE_PAPER_LIT, Palette.EDGE_STEEL, 1, 0, 8))
	_button(t, "ButtonNotice", "Button", notice_n, notice_h, notice_p, dimmed(notice_n, 0.7),
		Fonts.ui_medium(), Type.BODY, Palette.TEXT_TITLE, Palette.TEXT_TITLE,
		Palette.TEXT_MUTED, scale)
	# The chip (HALL-12, HALL-17): sort/filter toggles and Settings' engaged
	# values. A toggle button's pressed state is its "on": gold rim, lit plate,
	# gold text — state by chrome, not by font colour alone (docs/13 §8.5).
	var chip_n := flat(Palette.SURFACE_CHIP, Palette.EDGE_SLATE_LIGHT, 1, 4, 6)
	var chip_h := flat(Palette.SURFACE_PLATE_LIT, Palette.EDGE_BRONZE_LIT, 1, 4, 6)
	var chip_p := pressed(flat(Palette.SURFACE_PLATE_LIT, Palette.EDGE_READY_GOLD, 1, 4, 6))
	_button(t, "ButtonChip", "Button", chip_n, chip_h, chip_p, dimmed(chip_n),
		Fonts.ui_medium(), Type.SMALL, Palette.TEXT_MUTED_WARM, Palette.TEXT_TITLE,
		Palette.TEXT_DISABLED, scale)
	t.set_color("font_pressed_color", "ButtonChip", Palette.ACCENT_GOLD)
	# A toggled chip under the pointer draws `hover_pressed` (W3-OPTIONS): the
	# lit plate stays lit, gold text and all, instead of the engine's default.
	t.set_stylebox("hover_pressed", "ButtonChip", chip_p)
	t.set_color("font_hover_pressed_color", "ButtonChip", Palette.ACCENT_GOLD)
	# The lit secondary (CRITIC-G16, W3-OPTIONS): Settings' Apply — a commit
	# that spends no time, gold or raider, so not crimson. 06 §7.2's engaged
	# tint on the secondary silhouette: the bronze plate a step up at rest,
	# brighter still on hover, the inverted plate pressed, dimmed disabled.
	var lit_n := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(1.22, 1.22, 1.22))
	var lit_h := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(1.4, 1.4, 1.4))
	var lit_p := pressed(tex("btn_secondary_pressed.png", 14, 14, 14, 14, 8, Color(1.22, 1.22, 1.22)))
	var lit_d := tex("btn_secondary.png", 14, 14, 14, 14, 8, Color(0.5, 0.5, 0.5))
	_button(t, "ButtonSecondaryLit", "Button", lit_n, lit_h, lit_p, lit_d,
		Fonts.ui_semibold(), Type.BODY, Palette.TEXT_TITLE, Palette.TEXT_TITLE,
		Palette.TEXT_DISABLED, scale)
	# Text links (06 §7.3). LinkButton never passes through `_button()` — it takes
	# no styleboxes for its states — so its focus ring and focus colour have to be
	# set here by hand, and before this they were simply absent: a focused link
	# showed NOTHING, because its underline is bound to hover and a keyboard never
	# hovers. docs/13 §12.3's "identical shape on every widget" includes links.
	# Widgets.link() also turns the underline on for focus, so the link's own
	# signal stops being hover-only.
	t.set_color("font_color", "LinkButton", Palette.TEXT_MUTED_WARM)
	t.set_color("font_hover_color", "LinkButton", Palette.TEXT_TITLE)
	t.set_color("font_focus_color", "LinkButton", Palette.TEXT_TITLE)
	t.set_stylebox("focus", "LinkButton", focus_ring())
	t.set_font("font", "LinkButton", Fonts.ui_medium())
	t.set_font_size("font_size", "LinkButton", Type.at(Type.LINK, scale))

	# ---- misc controls -----------------------------------------------------
	t.set_stylebox("panel", "TooltipPanel",
		flat(Color(Palette.SURFACE_TOOLTIP, 0.95), Palette.EDGE_TOOLTIP, 1, 3, 8))
	t.set_color("font_color", "TooltipLabel", Palette.TEXT_MUTED_WARM)
	t.set_font_size("font_size", "TooltipLabel", Type.at(Type.QUOTE, scale))
	# The scrollbar (HALL-14, TOWN-10): an 8px track with a bronze grabber, so a
	# list that scrolls SAYS so. The track's side margins are the bar's width.
	var track := flat(Palette.SCROLL_TRACK, Color(0, 0, 0, 0), 0, 2)
	track.content_margin_left = 4
	track.content_margin_right = 4
	t.set_stylebox("scroll", "VScrollBar", track)
	var thumb := flat(Palette.SCROLL_THUMB, Color(0, 0, 0, 0), 0, 2)
	thumb.content_margin_top = 12
	thumb.content_margin_bottom = 12
	t.set_stylebox("grabber", "VScrollBar", thumb)
	t.set_stylebox("grabber_highlight", "VScrollBar", flat(Palette.SCROLL_THUMB_LIT, Color(0, 0, 0, 0), 0, 2))
	t.set_stylebox("grabber_pressed", "VScrollBar", flat(Palette.SCROLL_THUMB_LIT, Color(0, 0, 0, 0), 0, 2))
	t.set_stylebox("panel", "ScrollContainer", empty())
	return t
