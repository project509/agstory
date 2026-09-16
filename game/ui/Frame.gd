extends RefCounted
## The dashboard shell: header, nav rail, scene, sidebar, bottom strip.
##
## art/ref/specs/01 §1 measured this frame on Concept 1 and 03 §1 confirmed
## Concept 3 shares it — the same five regions, differing only in the rail's
## item count and whether the scene is framed or full-bleed. So it is one
## component with two modes, and every number below is one of those measured
## coordinates.
##
## LAYOUT IS EXPLICIT. Each region is created, parented, then given its
## `position`/`size` directly. Two tidier-looking alternatives were tried and
## both fail in Godot 4.7, each pinned with an isolated probe:
##   * anchoring a region with `anchor_left = anchor_right = 1.0` — every rect
##     reports correctly and nothing paints (tools/probe/Chips.tscn);
##   * routing rects through a helper that stores a Callable per node and
##     re-applies them — plain Controls survive it, Containers come out blank.
## Setting the rect at construction is what actually renders, and it is also
## what pixel-parity wants: the reference IS a fixed 1536x1024 layout.
##
## `Frame.relayout(parts)` recomputes every region for a new size; nothing
## calls it automatically.
##
##   var f := Frame.build(self, {"nav": items, "active": "town"})
##   f.scene / f.sidebar / f.strip / f.chips are the hosts to fill.

const Palette = preload("res://game/ui/Palette.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Type = preload("res://game/ui/Type.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Fonts = preload("res://game/ui/Fonts.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Reputation = preload("res://sim/core/Reputation.gd")

const BASE := Vector2(1536, 1024)           # the reference framebuffer
const HEADER_H := 74                        # 01 §1: band 0..73
const DIVIDER_Y := 74                       # 2px bronze rule
const RAIL_W := 207                         # rail 0..206, border core x=208
const RAIL_TOP := 77
const RULE_Y := 717                         # the shared horizontal rule
const SIDEBAR_W := 378                      # 01 §1: x 1142..1519
const SIDEBAR_TOP := 79
const SIDEBAR_BOTTOM := 714
const GUTTER := 16                          # page ground right of the sidebar
const SCENE_LEFT := 210
const STRIP_Y := 734
const STRIP_H := 262
const CHIPS_W := 880
const CHIPS_Y := 15
const CHIPS_H := 45
const CHIP_GAP := 24                        # the row's gap at text scale 100

# TOWN-04 / CRITIC-C13: canon's "Adventure's Board" is longer than any label the
# reference drew at x=73, and the design wins — the glyph column moves to x 16
# and the label to x 62; the label steps down to RAIL_LABEL_FLOOR (TOWN-04's
# "Type.NAV - 2") before it is ever clipped.
const RAIL_GLYPH_X := 16
const RAIL_LABEL_X := 62
const RAIL_LABEL_FLOOR := Type.NAV - 2

# TOWN-08 / 03 §9 layer 10: on the full-bleed camp the rail and header are
# gradients over the scene — rail opaque to x≈150 and gone by 200, header
# opaque to x=414 and gone by 440.
const RAIL_SCRIM_OPAQUE := 150
const RAIL_SCRIM_END := 200
const HEADER_SCRIM_OPAQUE := 414
const HEADER_SCRIM_END := 440

# 03 §6: the tagline's trailing rule ends where the logotype block right-aligns.
const TAGLINE_RULE_END := 374.0

## Q05 (00-plan §6): which lockup every framed screen draws. Spec 03 §6 rules
## SAMENESS — "do not let the logotype change size between screens" — and which
## of the two references it is belongs to the designer; both reports recommend
## Concept 3's 44px mark with the tagline, so that is the default. Flip to "58"
## for Concept 1's bare mark. The per-screen `tagline` opt no longer decides.
const LOCKUP := "44_tagline"

## Every lockup this shell can draw, by name: the mark's texture and where its
## left edge and baseline sit, whether the tagline hangs under it, and the
## emblem's position and crop. "33_compact" is Concept 2's header (02 §4.1,
## COMBAT-12): the mark at 0.76 (`wordmark_33`, tools/art/gen_wordmark.py) at
## x 96, baseline 48, and the skull cropped to its 65px width at (22, 12) so the
## whole lockup ends inside RaidView/Results' 352px plate. Those two screens
## draw it through `draw_lockup(host, "33_compact")`.
const LOCKUPS := {
	"58": {"mark": "wordmark_58", "mark_x": 104, "baseline_y": 60, "tagline": false,
		"emblem_pos": Vector2(22, 15), "emblem_region": Rect2()},
	"44_tagline": {"mark": "wordmark_44", "mark_x": 104, "baseline_y": 50, "tagline": true,
		"emblem_pos": Vector2(22, 15), "emblem_region": Rect2()},
	"33_compact": {"mark": "wordmark_33", "mark_x": 96, "baseline_y": 48, "tagline": false,
		"emblem_pos": Vector2(22, 12), "emblem_region": Rect2(0, 0, 65, 57)},
}

## 00 §2.6: canon's rail ids -> the reference's seven nav glyphs.
const GLYPH := {
	"home": "home", "town": "home", "camp": "home",
	"tavern": "recruit", "recruit": "recruit",
	"roster": "roster", "guildhall": "roster",
	"market": "gear", "gear": "gear",
	"board": "missions", "missions": "missions",
	"records": "reports", "reports": "reports",
	"options": "options", "settings": "options",
}


## The rail's item list for every archetype-A screen (00 §2.6 maps the
## reference's labels onto canon's buildings). Screens pass this as `nav` and
## name the lit item; Records and the Blacksmith are not rail items — the first
## has no screen yet, the second is a gated callout because canon calls it a
## "maybe" and a test pins that.
const NAV := [
	{"id": "home", "label": "Camp", "scene": ""},
	{"id": "tavern", "label": "Tavern", "scene": "res://game/screens/Tavern.tscn"},
	{"id": "roster", "label": "Roster", "scene": "res://game/screens/Guildhall.tscn"},
	{"id": "market", "label": "Market", "scene": "res://game/screens/Market.tscn"},
	{"id": "board", "label": "Adventure's Board", "scene": "res://game/screens/AdventureBoard.tscn"},
	{"id": "options", "label": "Options", "scene": "res://game/screens/Settings.tscn"},
]
const TOWN_SCENE := "res://game/screens/Town.tscn"


## Build the nav list for `router`, disabling items whose screen is not built,
## and after `build()` wire each button: the home item returns to the Town via
## goto (it is the stack's root), every other item pushes its screen.
static func nav_items(router) -> Array:
	var out: Array = []
	for item in NAV:
		var scene := String(item["scene"])
		var reason := ""
		if not scene.is_empty() and (router == null or not router.screen_exists(scene)):
			reason = "Not built in this version yet."
		out.append({"id": item["id"], "label": item["label"], "reason": reason})
	return out


static func wire_nav(p: Parts, router, current_id: String) -> void:
	if router == null:
		return
	for item in NAV:
		var id := String(item["id"])
		var b: Button = p.nav_buttons.get(id)
		if b == null or b.disabled or id == current_id:
			continue
		var scene := String(item["scene"])
		if id == "home":
			b.pressed.connect(func() -> void: router.goto(TOWN_SCENE))
		elif not scene.is_empty():
			b.pressed.connect(func() -> void: router.push(scene))


## The shell's own textures and metrics, held strongly (W5-MOUNT): the
## emblem, the wordmarks, the rail glyphs and the chip icons are loaded on
## every page turn, and Godot's weak cache had dropped them with the previous
## screen — so each goto() re-read a dozen small PNGs and parsed two .json
## files. Same objects every time; `profile` counts build() for the probe.
static var _tex_cache: Dictionary = {}       # res:// path -> Texture2D (null for a missing file)
static var _baseline_cache: Dictionary = {}  # wordmark name -> baseline_y
static var profile: Dictionary = {"build_usec": 0, "builds": 0}


## A texture by path through the strong cache; null when the file is missing
## (remembered too, so a missing glyph costs one exists() check, not one per
## page turn).
static func _tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[path] = tex
	return tex


static func profile_reset() -> void:
	profile["build_usec"] = 0
	profile["builds"] = 0


## Everything a screen needs to fill in.
class Parts extends RefCounted:
	var root: Control
	var header: Control           ## ColorRect when framed; a gradient scrim when full-bleed
	var divider: Control          ## the 2px bronze rule (a scrim on the full-bleed camp)
	var sidebar_rule: Control     ## full-bleed only: the same rule over the sidebar column
	var seam: ColorRect
	var shared_rule: ColorRect
	var chip_host: Control        ## plain host; call Frame.chips(p) to fill it
	var chips: HBoxContainer      ## set by Frame.chips(p)
	var rail: Control             ## ColorRect when framed; a gradient scrim when full-bleed
	var rail_edge: Control        ## the 1px border core; null on the full-bleed camp
	var scene: Control
	var expand_ground: ColorRect  ## inside `scene`: the extra width under `expand`
	var lockup_right: float = 0.0 ## where the emblem + mark (+ tagline) block ends
	var sidebar_host: Control     ## plain host; call Frame.sidebar(p) to fill it
	var sidebar: Control          ## set by Frame.sidebar(p) — put content here
	var sidebar_panel: Control    ## the panel itself, for relayout
	var strip: Control
	var nav_buttons: Dictionary = {}
	var framed: bool = true
	var has_sidebar: bool = true
	var tall: bool = false        ## no strip: scene and sidebar run to the page bottom


## `opts`:
##   nav      Array of {id, label, reason?} — the rail's items (00 §2.6)
##   active   id of the lit item
##   framed   true = Concept 1's bordered scene viewport; false = full-bleed (C3)
##   tagline  ignored since Q05 landed — `LOCKUP` decides, so every framed
##            screen draws the same lockup (03 §6; KIT-13, TOWN-05)
##   sidebar  false to omit the right panel and let the scene run to the gutter
static func build(host: Control, opts: Dictionary = {}) -> Parts:
	var t0 := Time.get_ticks_usec()
	var p := Parts.new()
	p.root = host
	p.framed = opts.get("framed", true)
	p.has_sidebar = opts.get("sidebar", true)
	p.tall = bool(opts.get("tall", false))

	host.add_child(Widgets.ground())

	# ---- scene ------------------------------------------------------------
	# Added first so every panel draws over it.
	if p.framed:
		p.seam = ColorRect.new()                    # 01 §1: 1px dark inset seam
		p.seam.color = Palette.GROUND_SEAM
		p.seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(p.seam)

	p.scene = Control.new()
	p.scene.name = "SceneHost"
	p.scene.clip_contents = true
	p.scene.mouse_filter = Control.MOUSE_FILTER_PASS
	host.add_child(p.scene)

	# CRITIC-G03: under `expand` the canvas is wider than the reference and the
	# scene host grows with it (relayout); where a plate ends, the extra width
	# is the rail's ground rather than the page's. Zero-width at the reference
	# size, so no 1536-wide pixel moves. First child: the screen's plate draws
	# over it.
	p.expand_ground = ColorRect.new()
	p.expand_ground.name = "ExpandGround"
	p.expand_ground.color = Palette.GROUND_RAIL
	p.expand_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.scene.add_child(p.expand_ground)

	if p.framed:
		p.shared_rule = ColorRect.new()             # 01 §1: the rule at y=717
		p.shared_rule.color = Palette.HEADER_RULE
		p.shared_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(p.shared_rule)

	# ---- header -----------------------------------------------------------
	# 01 §1: an opaque band on the framed screens. 03 §1/§9: on the full-bleed
	# camp the band is a gradient plate behind the lockup (opaque to x=414, gone
	# by 440) and the bronze rule exists only over that plate and over the
	# sidebar (TOWN-08). The opaque run is exactly GROUND_FRAME either way, so
	# the header region (0,0,400,74) is pixel-identical across every screen.
	var bronze := Palette.HEADER_DIVIDER            # 01 §1: 2px bronze
	if p.framed:
		var band := ColorRect.new()
		band.color = Palette.GROUND_FRAME
		p.header = band
		var rule := ColorRect.new()
		rule.color = bronze
		p.divider = rule
	else:
		p.header = _scrim(Palette.GROUND_FRAME, HEADER_SCRIM_OPAQUE, HEADER_SCRIM_END)
		p.divider = _scrim(bronze, HEADER_SCRIM_OPAQUE, HEADER_SCRIM_END)
		p.sidebar_rule = ColorRect.new()
		p.sidebar_rule.name = "SidebarRule"
		(p.sidebar_rule as ColorRect).color = bronze
		p.sidebar_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.header.name = "Header"
	p.header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unlit(p.header)
	host.add_child(p.header)
	p.divider.name = "Divider"
	p.divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(p.divider)
	if p.sidebar_rule != null:
		host.add_child(p.sidebar_rule)

	# KIT-13 / TOWN-05 / 03 §6: one lockup on every framed screen — LOCKUP, not
	# the screen's opt, decides (Q05 flips the constant).
	p.lockup_right = draw_lockup(host, LOCKUP)

	# 01 §5: chip 4's right edge aligns with the sidebar's, so the row is
	# right-aligned and keeps that alignment when the canvas widens.
	p.chip_host = Control.new()
	p.chip_host.name = "ChipHost"
	p.chip_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unlit(p.chip_host)
	host.add_child(p.chip_host)

	# ---- nav rail ---------------------------------------------------------
	# 01 §1: an opaque rail with its border core at x=208; on the full-bleed
	# camp (03 §9 layer 10, TOWN-08) a gradient opaque to x≈150 and gone by
	# 200, with no hard edge.
	if p.framed:
		var slab := ColorRect.new()
		slab.color = Palette.GROUND_RAIL
		p.rail = slab
		var edge := ColorRect.new()
		edge.color = Palette.EDGE_RAIL_CORE         # 01 §1: border core x=208
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.rail_edge = edge
	else:
		p.rail = _scrim(Palette.GROUND_RAIL, RAIL_SCRIM_OPAQUE, RAIL_SCRIM_END)
	p.rail.name = "Rail"
	p.rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unlit(p.rail)
	host.add_child(p.rail)
	if p.rail_edge != null:
		host.add_child(p.rail_edge)

	_nav(host, opts, p)

	# ---- sidebar ----------------------------------------------------------
	if p.has_sidebar:
		p.sidebar_host = Control.new()
		p.sidebar_host.name = "SidebarHost"
		p.sidebar_host.mouse_filter = Control.MOUSE_FILTER_PASS
		_unlit(p.sidebar_host)
		host.add_child(p.sidebar_host)

	# ---- bottom strip -----------------------------------------------------
	p.strip = Control.new()
	p.strip.name = "StripHost"
	p.strip.mouse_filter = Control.MOUSE_FILTER_PASS
	_unlit(p.strip)
	host.add_child(p.strip)

	relayout(p)
	_publish_focus_hooks(host, p)
	profile["build_usec"] = int(profile["build_usec"]) + int(Time.get_ticks_usec() - t0)
	profile["builds"] = int(profile["builds"]) + 1
	return p


## UI-26 (W7-STAGE): a panel host takes no stage light. The real fence is
## SceneStage's — its lights cull to the stage's own layer and no Control
## outside it is on that layer — so this is the belt to that brace: a host
## on layer 0 is lit by nothing whatever a later stage does with its masks.
static func _unlit(c: CanvasItem) -> void:
	if c != null:
		c.light_mask = 0


## The two meta keys the router reads. See `_publish_focus_hooks`.
const META_FOCUS_ORDER := "frame_focus_order"
const META_FOCUS_ENTRY := "frame_focus_entry"


## How docs/13 §13.1's reading order reaches the live game without editing
## eleven screens.
##
## `focus_order()` cannot be called from `build()` — the screen's content does
## not exist yet — and the router cannot call it directly either, because
## game/core must not depend on game/ui (nothing under game/core preloads
## game/ui, and this shell is not going to be the first). So `build()` leaves
## two Callables on the host and ScreenRouter invokes them after `on_enter()`,
## by which time the screen HAS built its content. A screen that does not use
## this shell has no meta and the router falls back to tree order, exactly as
## before.
##
## Metadata rather than a signal because the router needs the ANSWER (the entry
## control) synchronously, before it grabs focus, and because a screen may be
## rebuilt several times — re-calling is idempotent.
static func _publish_focus_hooks(host: Control, p: Parts) -> void:
	host.set_meta(META_FOCUS_ORDER, func() -> Array: return focus_order(p))
	host.set_meta(META_FOCUS_ENTRY, func() -> Control: return focus_entry(p))


## Recompute every region for a frame of `size` (default: the frame's current
## size, falling back to the reference's). Screens call this from a `resized`
## handler if they support a window other than the reference's.
static func relayout(p: Parts, size: Vector2 = Vector2.ZERO) -> void:
	if size == Vector2.ZERO:
		size = p.root.size if p.root.size.x > 0 else BASE
	var right_margin: float = (SIDEBAR_W + GUTTER + 4) if p.has_sidebar else GUTTER
	var right: float = size.x - right_margin
	# A screen with nothing to put in the strip (Options) runs its scene and
	# sidebar down to the page bottom instead of leaving a dark band.
	var rule_y: float = (size.y - GUTTER - 1) if p.tall else RULE_Y
	var side_bottom: float = (size.y - GUTTER - 4) if p.tall else SIDEBAR_BOTTOM

	if p.framed:
		p.seam.position = Vector2(SCENE_LEFT - 2, RAIL_TOP - 1)
		p.seam.size = Vector2(right + 2 - (SCENE_LEFT - 2), rule_y + 1 - (RAIL_TOP - 1))
		p.shared_rule.position = Vector2(0, rule_y)
		p.shared_rule.size = Vector2(size.x, 2)
		p.scene.position = Vector2(SCENE_LEFT, RAIL_TOP)
		p.scene.size = Vector2(right - SCENE_LEFT, rule_y - RAIL_TOP)
	else:
		# 03 §1: on the camp screen the plate is full-bleed and the rail and
		# sidebar float on top of it, so the scene takes the whole frame.
		p.scene.position = Vector2.ZERO
		p.scene.size = Vector2(size.x, STRIP_Y - 8)

	# CRITIC-G03: the scene's width at the reference size; everything the
	# canvas adds beyond it is GROUND_RAIL until a plate covers it.
	var base_scene_w: float = (BASE.x - right_margin - SCENE_LEFT) if p.framed else BASE.x
	p.expand_ground.position = Vector2(base_scene_w, 0)
	p.expand_ground.size = Vector2(maxf(0.0, p.scene.size.x - base_scene_w), p.scene.size.y)

	p.header.position = Vector2.ZERO
	p.divider.position = Vector2(0, DIVIDER_Y)
	if p.framed:
		p.header.size = Vector2(size.x, HEADER_H)
		p.divider.size = Vector2(size.x, 2)
	else:
		p.header.size = Vector2(HEADER_SCRIM_END, HEADER_H)
		p.divider.size = Vector2(HEADER_SCRIM_END, 2)
		p.sidebar_rule.position = Vector2(size.x - SIDEBAR_W - GUTTER, DIVIDER_Y)
		p.sidebar_rule.size = Vector2(SIDEBAR_W, 2)

	# The row is right-anchored and its host grows with the text scale (the
	# chips' numerals scale, their plates and icons do not), so at 150 the four
	# chips still end at the gutter instead of running off the frame.
	var chips_w: float = float(Type.at(CHIPS_W, _scale(p.root)))
	p.chip_host.position = Vector2(size.x - GUTTER - 1 - chips_w, CHIPS_Y)
	p.chip_host.size = Vector2(chips_w, CHIPS_H)
	if p.chips != null:
		p.chips.position = Vector2.ZERO
		p.chips.size = p.chip_host.size

	p.rail.position = Vector2(0, RAIL_TOP)
	p.rail.size = Vector2(RAIL_W if p.framed else RAIL_SCRIM_END, rule_y - RAIL_TOP)
	if p.rail_edge != null:
		p.rail_edge.position = Vector2(RAIL_W + 1, RAIL_TOP)
		p.rail_edge.size = Vector2(1, rule_y - RAIL_TOP)

	if p.has_sidebar:
		# TOWN-08: on the full-bleed camp the panel meets the header rule (the
		# rule is y 74..75, so the panel starts at 76 — measured: the row at
		# RAIL_TOP left one line of tent canvas showing) and the strip, so no
		# plate shows between them (the framed screens have their seam for that).
		var side_top: float = SIDEBAR_TOP if p.framed else (DIVIDER_Y + 2)
		var side_end: float = side_bottom if p.framed else (STRIP_Y - 8)
		p.sidebar_host.position = Vector2(size.x - SIDEBAR_W - GUTTER, side_top)
		p.sidebar_host.size = Vector2(SIDEBAR_W, side_end - side_top)
		if p.sidebar_panel != null:
			p.sidebar_panel.position = Vector2.ZERO
			p.sidebar_panel.size = p.sidebar_host.size

	p.strip.position = Vector2(13, STRIP_Y)
	p.strip.size = Vector2(size.x - 30, STRIP_H)
	p.strip.visible = not p.tall


static func _nav(host: Control, opts: Dictionary, p: Parts) -> void:
	var items: Array = opts.get("nav", [])
	var active: String = opts.get("active", "")
	for i in items.size():
		var item: Dictionary = items[i]
		var id := String(item.get("id", str(i)))
		var label := String(item.get("label", ""))
		var reason := String(item.get("reason", ""))
		var is_active := id == active

		var b := Button.new()
		b.name = "Nav_" + id
		b.text = label                          # the tests read this
		b.disabled = not reason.is_empty()
		b.theme_type_variation = "NavItemActive" if is_active else "NavItem"
		host.add_child(b)
		b.position = Vector2(0, Widgets.RAIL_ITEM_Y0 + Widgets.RAIL_ITEM_H * i)
		b.size = Vector2(RAIL_W + 4, Widgets.RAIL_ITEM_H)
		# The label is drawn by a child Label so it lands on the reference's
		# x=73 rather than wherever the button's own padding would put it; the
		# Button keeps its own text for the tests and hides its drawing of it.
		for role in ["font_color", "font_hover_color", "font_pressed_color",
				"font_focus_color", "font_disabled_color"]:
			b.add_theme_color_override(role, Color(0, 0, 0, 0))
		# 01 §6 measured the 32px glyph column at x=22 for the reference's own
		# labels; canon's are longer, so the column sits at RAIL_GLYPH_X and the
		# label at RAIL_LABEL_X (TOWN-04 / CRITIC-C13). 00 §2.6 maps canon's rail
		# onto the reference's seven glyphs (Recruit is the Tavern, ...).
		var glyph_name: String = GLYPH.get(id, id)
		var glyph_path := "res://game/assets/ui/icons/nav_%s.png" % glyph_name
		var glyph: Texture2D = _tex(glyph_path)
		if glyph != null:
			var g := TextureRect.new()
			g.name = "Glyph"
			g.texture = glyph
			g.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			g.mouse_filter = Control.MOUSE_FILTER_IGNORE
			g.modulate = (Palette.INK_NAV_GLYPH_ACTIVE if is_active else Palette.INK_NAV_GLYPH)
			b.add_child(g)
			g.position = Vector2(RAIL_GLYPH_X, 0)
			g.size = Vector2(32, Widgets.RAIL_ITEM_H)

		# The label is whole: its size is Type.NAV at the player's text scale,
		# stepped down (never below the floor AT THAT SCALE — UI-30: an
		# unscaled floor made "Adventure's Board" a 14px label between 24px
		# neighbours at 150) until the string fits the column; a string still
		# too wide at the floor wraps to two lines inside the item (`_rail_fit`),
		# and clip_text is the last guard so no glyph paints past the rail edge
		# at any scale (KIT-04). Button.text above is untouched.
		var lbl := Widgets.label_as(label, "LabelBody")
		lbl.name = "RailLabel"
		var avail: float = float(RAIL_W - RAIL_LABEL_X)
		var pct: int = _scale(host)
		var px: int = _rail_label_size(host, label, pct, avail)
		lbl.add_theme_font_size_override("font_size", px)
		lbl.add_theme_color_override("font_color",
			Palette.INK_NAV_ACTIVE if is_active else Palette.INK_NAV)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.clip_text = true
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_rail_fit(host, lbl, label, px, avail)
		b.add_child(lbl)
		lbl.position = Vector2(RAIL_LABEL_X, 0)
		lbl.size = Vector2(avail, Widgets.RAIL_ITEM_H)
		p.nav_buttons[id] = b


## The player's text scale, through the one door (W0-TEXTSCALE): 100 when no
## GameSettings is reachable, which is the tests' and the probes' case.
static func _scale(who: Node) -> int:
	return Theme_.scale_of(who)


## The rail label's font size: `Type.NAV` at the text scale, stepped down one
## pixel at a time while the string is wider than `avail`, never below
## `rail_label_floor(pct)` — RAIL_LABEL_FLOOR at that scale (UI-30). Measured
## with the theme's own LabelBody face so the answer does not depend on
## whether the host is in the tree yet.
static func _rail_label_size(host: Node, text: String, pct: int, avail: float) -> int:
	var font: Font = _theme_font(host, "LabelBody")
	var px: int = Type.at(Type.NAV, pct)
	var floor_px: int = rail_label_floor(pct)
	while px > floor_px \
			and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > avail:
		px -= 1
	return px


## The smallest a rail label may be drawn at the player's text scale: TOWN-04's
## `Type.NAV - 2`, scaled like every other size (16 / 20 / 24).
static func rail_label_floor(pct: int) -> int:
	return Type.at(RAIL_LABEL_FLOOR, pct)


## UI-30's second rung: a label still wider than the column at the floor
## wraps to two lines inside the 55px item — "Adventure's" over "Board" at
## 125 and 150, the one canon name longer than the reference's. The two lines
## shape from the plain Fira face (`Fonts.ui()`; the LabelBody variation
## carries the 24/30/36px face sheet, which would make each line a sheet
## tall — Cards.fit_band_line's rule), and the line spacing closes just enough
## for both lines to sit inside the item (at 24px two Fira lines are 60 in
## 55; the 6px taken is under the descender-to-ascender gap, so nothing
## touches). A label that fits on one line is left exactly as it was.
static func _rail_fit(host: Node, lbl: Label, text: String, px: int, avail: float) -> void:
	var face: Font = _theme_font(host, "LabelBody")
	if face.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= avail:
		return
	var plain: Font = Fonts.ui()
	lbl.add_theme_font_override("font", plain)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.max_lines_visible = 2
	var line_h: float = plain.get_height(px)
	var room: float = float(Widgets.RAIL_ITEM_H)
	lbl.add_theme_constant_override("line_spacing", mini(0, int(floorf(room - 2.0 * line_h))))


static func _theme_font(host: Node, variation: String) -> Font:
	var theme: Theme = Theme_.current(host)
	if theme != null and theme.has_font("font", variation):
		return theme.get_font("font", variation)
	if theme != null and theme.default_font != null:
		return theme.default_font
	return ThemeDB.fallback_font


## Fill the chip host with a right-aligned row. CALL THIS FROM THE SCREEN,
## after `build()` — never from inside `build()`.
##
## Containers created during `Frame.build()` and handed back lay out perfectly
## by every measurement (correct local and global rects, visible_in_tree, z 0,
## children present) and paint nothing; the identical container created by the
## screen after `build()` returns paints correctly. That was isolated by
## building the same PanelWarm both ways at the same coordinates. Until the
## cause is understood, Frame creates only plain Controls, ColorRects and
## Buttons — all of which render either way — and the screen makes the
## containers through these two helpers.
static func chips(p: Parts) -> HBoxContainer:
	var row := Widgets.row(chip_gap(_scale(p.root)))
	row.name = "Chips"
	row.alignment = BoxContainer.ALIGNMENT_END
	p.chip_host.add_child(row)
	row.position = Vector2.ZERO
	row.size = p.chip_host.size
	p.chips = row
	return row


## The chip row's gap at the player's text scale. The chips' plates, icons and
## margins are fixed pixels while their numerals grow (W0-TEXTSCALE), so at 150
## the four chips need ~1130px of the ~1145 between the lockup and the gutter;
## the gap gives back part of what the text takes (24 → 19 → 16). Identity at
## 100 by construction.
static func chip_gap(pct: int) -> int:
	return int(round(float(CHIP_GAP) * 100.0 / float(Type.step(pct))))


## Create the sidebar panel and return the node to put content in.
static func sidebar(p: Parts) -> Control:
	if not p.has_sidebar:
		return null
	var side := Widgets.panel("PanelWarm", 18)
	side.name = "Sidebar"
	side.clip_contents = true
	p.sidebar_host.add_child(side)
	side.position = Vector2.ZERO
	side.size = p.sidebar_host.size
	p.sidebar_panel = side
	p.sidebar = Widgets.content_of(side)
	return p.sidebar


## The four header chips every archetype-A screen shows (00 §2.5): gold, the
## one guild stat (Reputation), the roster against its cap, and the day with
## the rank — whose icon is the rank's sigil, not the reference's sun. The
## literal strings "60 G", "Day 1", "Roster 0 of 15" and "Unknown" are asserted
## by tests and all live in these Labels.
static func standard_chips(p: Parts, state) -> void:
	_fill_chips(chips(p), state)


## Rebuild the chip row in place for a screen's refresh path (the Market after
## a sale, the Tavern after a hire): the same four chips, the same tooltip, no
## second builder anywhere (KIT-03 / TOWN-05). Builds the row if the screen has
## not yet.
static func refresh_chips(p: Parts, state) -> void:
	if p.chips == null:
		standard_chips(p, state)
		return
	for c in p.chips.get_children():
		p.chips.remove_child(c)
		c.queue_free()
	_fill_chips(p.chips, state)


static func _fill_chips(row: HBoxContainer, state) -> void:
	if state == null or not bool(state.get("active")):
		row.add_child(Widgets.chip("No guild loaded."))
		return
	var icons := "res://game/assets/ui/icons/"
	# KIT-15 / docs/13 §4.3: numerals carry the thousands separator.
	row.add_child(Widgets.chip(Type.gold(state.gold), Palette.ACCENT_GOLD, _tex(icons + "coin.png")))
	row.add_child(Widgets.chip(Type.num(state.reputation_points), Palette.ACCENT_GEM,
		_tex(icons + "gem.png")))
	row.add_child(Widgets.chip("Roster %d of %d" % [state.roster.size(), state.roster_cap()],
		Palette.TEXT_MUTED, _tex(icons + "book.png")))
	var sigil := icons + "rank_%s.png" % String(state.rank_name()).to_lower()
	var sigil_tex: Texture2D = _tex(sigil)
	var day := Widgets.chip("Day %d  ·  %s" % [state.day, state.rank_name()], Palette.TEXT_MUTED,
		sigil_tex if sigil_tex != null else _tex(icons + "sun.png"))
	# KIT-23 / TOWN-30 / spec 10 §3.1: the HUD's only within-rank readout is
	# this tooltip; docs/02 §2.2 keeps the chip's own text to the rank name.
	day.name = "DayChip"
	day.tooltip_text = standing_tip(state)
	row.add_child(day)


## "N reputation · M more to <rank>" — the day chip's standing tooltip on every
## archetype-A screen. The Board prints the same countdown in a Label
## (AdventureBoard._standing(), test_screens.gd's "120 more to Known"); this is
## the hover copy of it, so it is not read by any `_texts()` walk.
static func standing_tip(state) -> String:
	if state == null or not bool(state.get("active")):
		return ""
	var rank: int = state.reputation_rank
	var rp: int = state.reputation_points
	var next_rp: int = Reputation.rp_for_next(rank)
	if next_rp < 0:
		return "%s reputation — the highest standing there is." % Type.num(rp)
	return "%s reputation · %s more to %s" % [
		Type.num(rp), Type.num(next_rp - rp), Enums.reputation_name_of(rank + 1)]


## Draw one of LOCKUPS onto `host` at the header's coordinates and return the
## block's right edge (the tagline rule's end, or the mark's). `build()` draws
## LOCKUP through this; RaidView and Results draw "33_compact" for their 352px
## plate (COMBAT-12). Both are authored art: the emblem is sliced pixel art, the
## marks pre-rendered by tools/art/gen_wordmark.py and placed by their own
## baseline metric.
static func draw_lockup(host: Control, kind: String = LOCKUP) -> float:
	var spec: Dictionary = LOCKUPS[kind]
	# 01 §5: emblem 22,15,82,57. 02 §4.1 crops it to the 65px skull for the
	# compact header (an AtlasTexture region; the PNG is untouched).
	var emblem_tex: Texture2D = _tex("res://game/assets/ui/emblem.png")
	var region: Rect2 = spec["emblem_region"]
	if region.size != Vector2.ZERO:
		var atlas := AtlasTexture.new()
		atlas.atlas = emblem_tex
		atlas.region = region
		emblem_tex = atlas
	var emblem := TextureRect.new()
	emblem.name = "Emblem"
	emblem.texture = emblem_tex
	emblem.stretch_mode = TextureRect.STRETCH_KEEP
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(emblem)
	emblem.position = spec["emblem_pos"]
	emblem.size = emblem_tex.get_size()

	# The mark is set by its BASELINE (01 §5 y=60 for the full mark, 03 §6 y=50
	# for the 44, 02 §4.1 y=48 for the compact one).
	var mark_name: String = spec["mark"]
	var mark := wordmark(mark_name)
	host.add_child(mark)
	var mark_x: float = float(spec["mark_x"])
	mark.position = Vector2(mark_x, float(spec["baseline_y"]) - wordmark_baseline(mark_name))
	var right: float = mark_x + mark.texture.get_width()
	if bool(spec["tagline"]):
		# 03 §6: baseline y=73, left edge on the "T" stem (x=104); the trailing
		# rule, 2px at y=67 from text.right+6 to x=374 so the tagline block
		# right-aligns with the logotype.
		var t := wordmark("wordmark_tagline")
		host.add_child(t)
		t.position = Vector2(mark_x, 73 - wordmark_baseline("wordmark_tagline"))
		var rule := ColorRect.new()
		rule.name = "TaglineRule"
		rule.color = Palette.HEADER_RULE_LIT
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(rule)
		var rule_x := mark_x + t.texture.get_width() + 6.0
		rule.position = Vector2(rule_x, 67)
		rule.size = Vector2(maxf(0.0, TAGLINE_RULE_END - rule_x), 2)
		# The block's edge is the rule's end: the mark's PNG carries a 1px
		# outline/shadow past its glyph run (03 §6: run x 97–372, texture to
		# 375), and the rule is drawn to 374 so the block right-aligns there.
		# A tagline wider than the mark (the designer's own copy, 2026-09-14,
		# is) leaves the rule nothing to fill: it is hidden, and the block's
		# edge is the tagline's.
		var tagline_right := mark_x + t.texture.get_width()
		if tagline_right + 6.0 >= TAGLINE_RULE_END:
			rule.visible = false
		right = maxf(TAGLINE_RULE_END, tagline_right)
	return right


## TOWN-08 / 03 §9 layer 10: a chrome plate that is a gradient over the scene
## rather than a slab — `ground` opaque up to `opaque_px`, gone by `end_px`. A
## GradientTexture2D sampled one texel per pixel (NEAREST), so the opaque run is
## exactly the token and the header region stays pixel-identical to the framed
## screens' ColorRect. Sized by relayout(); MOUSE_FILTER_IGNORE like every
## other overlay.
static func _scrim(ground: Color, opaque_px: int, end_px: int) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, float(opaque_px) / float(end_px), 1.0])
	g.colors = PackedColorArray([ground, ground, Color(ground, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = end_px
	tex.height = 1
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## The pre-rendered wordmark/tagline as a TextureRect. The texture's metrics
## live beside it in a .json written by tools/art/gen_wordmark.py, so a
## re-render never needs a code change to keep the baseline where 01 §5 put it.
static func wordmark(name: String) -> TextureRect:
	var t := TextureRect.new()
	t.name = name
	t.texture = _tex("res://game/assets/ui/%s.png" % name)
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func wordmark_baseline(name: String) -> int:
	if _baseline_cache.has(name):
		return int(_baseline_cache[name])
	var path := "res://game/assets/ui/%s.json" % name
	var baseline := 0
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		baseline = int(parsed.get("baseline_y", 0)) if parsed is Dictionary else 0
	_baseline_cache[name] = baseline
	return baseline


# ------------------------------------------------------------ keyboard focus
#
# docs/13 §13.1 asks for three things this shell has to supply, because none of
# them can be got from Godot's defaults:
#   * "Tab / Shift+Tab — next / previous focus group (rail -> list -> detail ->
#     commit)". Godot's Tab walks every focusable control in TREE order, and
#     tree order here is neither reading order nor region order: `build()` adds
#     the scene host FIRST so the panels draw over it, and the rail after it.
#     So the shell has to state the order rather than inherit it.
#   * "Arrows — move within the focused group".
#   * "focus order always follows reading order: rail, then header, then
#     content, then commit" — which is why the rail comes first below even
#     though the header band is painted above it.
# §13.2's ring rule — "it wraps, so there is no dead end" — is applied on both
# axes: Tab past the last region returns to the rail, and an arrow past a
# region's last member returns to its first.

## The shell's regions in §13.1's reading order. The doc's four names map onto
## Frame's five: `list` is the scene, `detail` is the sidebar, `commit` is the
## bottom strip, where 01 §2 puts the CTA.
const FOCUS_REGIONS := ["rail", "header", "scene", "sidebar", "strip"]

## What Tab means. FALSE is §13.1 read literally — Tab leaves the region and the
## arrows move inside it. TRUE is the desktop convention, where Tab visits every
## control and only a region's last member steps on to the next region. The doc
## names one behaviour and every other toolkit does the other, so it is a switch
## with the doc's answer as the default; build/plan/q-a11y-keys.md carries the
## proposed docs/15 entry.
static var tab_steps_within_region: bool = false


## Wire the whole shell for the keyboard and return the regions actually wired
## — an Array of non-empty Arrays of Control, in §13.1's order, so a test (or a
## screen) can assert the order instead of re-deriving it.
##
## CALL THIS FROM THE SCREEN, after its content is in the tree. Controls added
## afterwards are not wired; call it again. It is idempotent.
##
## `extra` adds controls the region walk cannot find on its own — a commit
## button parented outside the strip, say: `{"strip": [cta]}`. Names must be
## FOCUS_REGIONS entries.
static func focus_order(p: Parts, extra: Dictionary = {}) -> Array:
	var regions: Array = []
	for region_name in FOCUS_REGIONS:
		var members: Array = _region_members(p, region_name)
		var added: Array = extra.get(region_name, [])
		for c in added:
			if c is Control and _focusable(c) and not members.has(c):
				members.append(c)
		if not members.is_empty():
			regions.append(members)
	_wire_regions(regions)
	return regions


## The control that should hold focus when a screen built on this shell opens
## and has nothing more specific to say: the first thing in reading order.
## A screen's `default_focus()` hook can be one line — `return
## Frame.focus_entry(_parts)` — and the screens that docs/13 gives an explicit
## answer for (§11.4's "Try again", §13.2's last-visited building) return that
## instead.
static func focus_entry(p: Parts) -> Control:
	for region_name in FOCUS_REGIONS:
		var members: Array = _region_members(p, region_name)
		if not members.is_empty():
			return members[0]
	return null


## True when Godot's focus machinery will actually stop on this control. A
## disabled control is skipped: docs/13 §7 wants a disabled control to state its
## reason, and it does that in an adjacent Label the walk still reaches, so
## making the dead control itself a Tab stop only adds a stop that does nothing.
##
## The test is `== FOCUS_ALL`, not `!= FOCUS_NONE`, because there are four modes
## and only one of them is a Tab stop: `FOCUS_CLICK` (1) takes focus from a
## click and nothing else, and `FOCUS_ACCESSIBILITY` (3) — LinkButton's default
## in 4.7.1 — only while a screen reader is running. Measured: `grab_focus()` on
## either is refused with an engine warning and `find_next_valid_focus()` steps
## straight past them, so calling one focusable here produced a wired ring whose
## members the engine silently dropped, which is the dead end §13.2 forbids.
static func _focusable(c) -> bool:
	if not (c is Control) or not is_instance_valid(c):
		return false
	var ctl: Control = c
	if ctl.focus_mode != Control.FOCUS_ALL or not ctl.visible:
		return false
	if ctl is BaseButton and (ctl as BaseButton).disabled:
		return false
	return true


static func _region_members(p: Parts, region_name: String) -> Array:
	var out: Array = []
	if region_name == "rail":
		# The rail's buttons are children of the HOST, not of `p.rail` (the rail
		# is a ColorRect), so they are collected from the map in NAV order —
		# which is also the order they are drawn down the rail.
		for item in NAV:
			var b: Button = p.nav_buttons.get(String(item["id"]))
			if _focusable(b):
				out.append(b)
		return out
	var root: Control = null
	match region_name:
		"header": root = p.chip_host
		"scene": root = p.scene
		"sidebar": root = p.sidebar_host
		"strip": root = p.strip
	if root == null or not root.visible:
		return out
	_collect_focusable(root, out)
	return out


static func _collect_focusable(n: Node, out: Array) -> void:
	if n is Control and not (n as Control).visible:
		return
	if _focusable(n):
		out.append(n)
	for c in n.get_children():
		_collect_focusable(c, out)


static func _wire_regions(regions: Array) -> void:
	var n: int = regions.size()
	if n == 0:
		return
	for i in n:
		var members: Array = regions[i]
		var count: int = members.size()
		var entry_next: Control = regions[(i + 1) % n][0]
		var entry_prev: Control = regions[(i - 1 + n) % n][0]
		for j in count:
			var c: Control = members[j]
			var step_next: Control = members[(j + 1) % count]
			var step_prev: Control = members[(j - 1 + count) % count]
			if count > 1:
				# All four arrows are bound to the same within-region step
				# because §13.1 names no axis and the shell has both a vertical
				# region (the rail) and horizontal ones (the chip row, the
				# strip). Binding all four also stops Godot's geometric
				# fallback from wandering out of the region, which is the dead
				# end §13.2 forbids.
				c.focus_neighbor_top = c.get_path_to(step_prev)
				c.focus_neighbor_left = c.get_path_to(step_prev)
				c.focus_neighbor_bottom = c.get_path_to(step_next)
				c.focus_neighbor_right = c.get_path_to(step_next)
			else:
				# CLEARED, not left alone. This function is documented as
				# re-callable after a screen rebuilds a list, and a region that
				# shrinks to one member used to keep the neighbours it was
				# given when it had three — relative NodePaths to controls that
				# no longer exist. Godot resolves those to null and the arrow
				# does nothing, which reads as a dead control. An empty path is
				# the correct statement: there is nowhere else in this region.
				c.focus_neighbor_top = NodePath()
				c.focus_neighbor_left = NodePath()
				c.focus_neighbor_bottom = NodePath()
				c.focus_neighbor_right = NodePath()
			if tab_steps_within_region:
				c.focus_next = c.get_path_to(step_next if j < count - 1 else entry_next)
				c.focus_previous = c.get_path_to(step_prev if j > 0 else entry_prev)
			else:
				c.focus_next = c.get_path_to(entry_next)
				c.focus_previous = c.get_path_to(entry_prev)
