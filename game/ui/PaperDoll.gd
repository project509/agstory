## PaperDoll — RaiderDetail's kit composite (HALL-07; spec 11 §3's one
## screen-specific composite file): Concept 2's combatant panel read as a
## paper doll. The portrait at 2x nearest in a PortraitFrame well top-left; to
## its right the main hand as the 62x74 weapon slot (06 §2 "Weapon slot (C2)",
## the theme's `SlotWeapon` chrome on a `ButtonSlot`) beside a 3x2 grid of 47px
## slots — off hand, head, chest, legs, feet, trinket — each a
## `Widgets.slot_button` with `text` = the slot's name and the gear icon; a
## slot the class does not have (docs/13 §9.1 "hidden, not empty") is a blank
## well, so the grid always reads as 3x2.
##
## TEST CONTRACT: every slot is a Button (FOCUS_ALL by construction) named
## `Slot_<slot key>` whose `.text` is the slot name, so a walker reads the
## seven names and a keyboard reaches every slot. The caption sits in the
## Button's text the way the Market's picker tiles carry theirs: hidden behind
## the icon (every slot has one — the worn item's picture, or the slot's own
## glyph dimmed for an empty one), repeated in the tooltip, and printed in
## full by the legend RaiderDetail lays under the doll. Nothing here names an
## icon path: textures arrive as `Texture2D` parameters.
##
## Tooltips are the two-line title + body form (spec 06 §8, KIT-22), composed
## by the caller; the switch to `Widgets.tooltip_for` is handoff-W3-DETAIL's.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Enums = preload("res://sim/model/Enums.gd")

## 2x nearest of the 90x94 reference bust (HALL-07); the well is 2px larger
## so the picture never sits on the frame's 1px rim.
const PORTRAIT := Vector2i(180, 188)
const WELL := Vector2i(184, 192)
## 06 §2: the weapon slot is a taller instance of the ability slot.
const WEAPON := Vector2i(62, 74)
const CELL := Widgets.SLOT
const GRID_COLS := 3
const GRID_GAP := 5
const GAP := 8
## The dim on an empty slot's own glyph (the callers-dim-it rule of
## `Cards.gear_icon`), and the lift a hover or focus gives it back.
const EMPTY_GLYPH_ALPHA := 0.35
const EMPTY_GLYPH_LIT := 0.7
## The width the doll claims: well + gap + weapon + gap + the 3x2 grid.
const WIDTH := WELL.x + GAP + WEAPON.x + GAP + GRID_COLS * CELL + (GRID_COLS - 1) * GRID_GAP

## The grid's order, top-left to bottom-right (the weapon slot is the main
## hand and stands alone to the left of it).
const GRID_SLOTS := [
	Enums.Slot.OFF_HAND, Enums.Slot.HEAD, Enums.Slot.CHEST,
	Enums.Slot.LEGS, Enums.Slot.FEET, Enums.Slot.TRINKET,
]


## Builds the doll. `cells` maps a slot (Enums.Slot) to a Dictionary:
##   {"icon": Texture2D, "worn": bool, "tooltip": String, "on": Callable}
## A slot missing from `cells` is hidden — a blank well. `who` is any node in
## the screen (the theme's text scale is read through it). Returns the row;
## `slots_of(doll)` gives back {slot: Button} for wiring and tests.
static func build(portrait: Texture2D, cells: Dictionary, who: Node) -> Control:
	var row := Widgets.row(GAP)
	row.name = "PaperDoll"
	row.add_child(_well(portrait))

	var slots: Dictionary = {}
	var weapon := _slot(Enums.Slot.MAIN_HAND, cells.get(Enums.Slot.MAIN_HAND, {}), WEAPON, who)
	if weapon is Button:
		slots[Enums.Slot.MAIN_HAND] = weapon
	weapon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(weapon)

	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = GRID_COLS
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for slot in GRID_SLOTS:
		var cell := _slot(int(slot), cells.get(int(slot), {}), Vector2i(CELL, CELL), who)
		if cell is Button:
			slots[int(slot)] = cell
		grid.add_child(cell)
	row.add_child(grid)
	row.set_meta("slots", slots)
	return row


## {slot: Button} of a doll built here; empty for anything else.
static func slots_of(doll: Control) -> Dictionary:
	if doll == null or not doll.has_meta("slots"):
		return {}
	return doll.get_meta("slots")


## The portrait well: PortraitFrame chrome, the bust at 2x with nearest
## filtering so its pixels stay pixels (01 §3's frame, HALL-07's size).
static func _well(portrait: Texture2D) -> Control:
	var well := PanelContainer.new()
	well.name = "Portrait"
	well.theme_type_variation = "PortraitFrame"
	well.custom_minimum_size = WELL
	well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if portrait != null:
		var t := TextureRect.new()
		t.name = "Bust"
		t.texture = portrait
		t.custom_minimum_size = PORTRAIT
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		well.add_child(t)
	return well


## One slot. A hidden slot (no entry in `cells`) is a blank `Widgets.slot`
## well, dimmed, never a Button — it is not a place a keyboard can go.
static func _slot(slot: int, cell: Dictionary, size: Vector2i, who: Node) -> Control:
	if cell.is_empty():
		var blank := Widgets.slot(null, size.y)
		blank.name = "Blank_%s" % Enums.slot_key(slot)
		blank.custom_minimum_size = size
		blank.modulate = Color(1, 1, 1, 0.45)
		blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return blank

	var icon: Texture2D = cell.get("icon", null)
	var worn: bool = bool(cell.get("worn", false))
	var b := Widgets.slot_button(Enums.slot_name_of(slot), icon, size.y)
	b.name = "Slot_%s" % Enums.slot_key(slot)
	b.custom_minimum_size = size
	b.clip_text = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if icon != null:
		# Native pixels, centred: the item icons are 39px and the slot glyphs
		# 32px, both inside a 47px cell, so nothing is resampled.
		b.expand_icon = false
		b.add_theme_color_override("font_color", Color(0, 0, 0, 0))
		b.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
		b.add_theme_color_override("font_focus_color", Color(0, 0, 0, 0))
		b.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
		if not worn:
			b.add_theme_color_override("icon_normal_color", Color(1, 1, 1, EMPTY_GLYPH_ALPHA))
			b.add_theme_color_override("icon_hover_color", Color(1, 1, 1, EMPTY_GLYPH_LIT))
			b.add_theme_color_override("icon_focus_color", Color(1, 1, 1, EMPTY_GLYPH_LIT))
			b.add_theme_color_override("icon_pressed_color", Color(1, 1, 1, EMPTY_GLYPH_LIT))
	else:
		b.add_theme_font_size_override("font_size",
			Type.at(Type.STACK, Theme_.scale_of(who)))
	var tip := String(cell.get("tooltip", ""))
	if not tip.is_empty():
		# KIT-22: the title line over the body line, drawn as two styles by
		# the kit's TooltipHost; `tooltip_text` stays set for a11y and tests.
		var parts: PackedStringArray = tip.split("\n", true, 1)
		Widgets.tooltip_for(b, parts[0], parts[1] if parts.size() > 1 else "")
		# The host draws the two styles; the Button keeps the two-LINE text the
		# a11y walk and test_paper_doll.gd read (the kit joins them with a dash).
		b.tooltip_text = tip
	var on: Callable = cell.get("on", Callable())
	if on.is_valid():
		b.pressed.connect(on)
	if slot == Enums.Slot.MAIN_HAND:
		_weapon_chrome(b, who)
	return b


## The weapon slot's chrome: the theme's `SlotWeapon` panel box as the
## Button's normal state (a taller, steel-rimmed ability slot), a lit copy for
## hover and the kit's 1px-down press. The focus ring stays `ButtonSlot`'s —
## every Button-family ring comes from Theme.gd's `_button()` and this adds no
## variation of its own.
static func _weapon_chrome(b: Button, who: Node) -> void:
	var th: Theme = Theme_.current(who)
	var normal: StyleBox = null
	if th != null and th.has_stylebox("panel", "SlotWeapon"):
		normal = th.get_stylebox("panel", "SlotWeapon")
	if normal == null:
		normal = Theme_.flat(Palette.SURFACE_ABILITY, Palette.EDGE_STEEL_DIM, 1, 4, 0)
	var hover: StyleBox = Theme_.flat(Palette.SURFACE_PLATE_LIT, Palette.EDGE_STEEL, 1, 4, 0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", Theme_.pressed(hover))
	b.add_theme_stylebox_override("disabled", Theme_.dimmed(normal))
