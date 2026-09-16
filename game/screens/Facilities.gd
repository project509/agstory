extends Control
## S03's Facilities tab — the Guildhall itself, and the quarters inside it
## (docs/02 §4.5, docs/13 §5).
##
## ✅ CANON gives this screen its two jobs in one line each: "Upgrade guild
## facilities < better morale values" and "Manage morale with comfort items".
##
## docs/02 §4.5 specifies the Facilities tab as "Current level card, next level
## card, cost, delta table, exterior before/after thumbnails", and notes why the
## thumbnails are there: "Before/after thumbnails satisfy R1 by making the visual
## change part of the purchase pitch." The per-level art does not exist yet, so
## docs/02 §9's own "Visible change" column stands in as text — the pitch is the
## same sentence the artist will eventually draw — and the sidebar shows the
## guild's tent cropped from the bare camp plate (HALL_CARD_CROP, docs/15 BL-78).
##
## The quarters panel is docs/02 §4.5's right-hand column, moved into this tab
## rather than beside the roster. docs/13 OQ-4's split is now built on both sides:
## Roster.gd carries the quick-apply and S05 Raider Detail carries the full slot
## view. This panel is neither — it is §4.5's own column, and it is where docs/15
## BL-43's ruling lives: buying and placing are ONE action, so the furnishing
## buttons here call `buy_furnishing` with the price printed on them.
##
## The arithmetic strip is docs/02 §4.5's requirement verbatim: it shows
## `50 + rarity_offset + facility_bonus + items = baseline`, so a player can see
## exactly what their money bought.
##
## Art pass: archetype C inside the Guildhall's content panel. The ladder and the
## quarters are two PanelCards; the raider picker is the reference's portrait
## mini-grid (10 §2 R6) instead of a row of buttons wider than the screen.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Services = preload("res://game/core/Services.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Comfort = preload("res://sim/core/Comfort.gd")

const PORTRAIT := "res://game/assets/portraits/"

## The sidebar's hall card, until the per-level art exists (HALL-18, plan Q18):
## a crop of the BARE camp plate at the big guild tent — no painted figure in
## it. It used to crop the Concept 1 hall's bar, bartender and barmaid included,
## which is the "baked in" art docs/15 BL-78 removes from under every screen.
## The rect is the tent's roof and door on stage_camp.png (230..567, 110..214).
const HALL_CARD_PLATE := "res://game/assets/bg/stage_camp.png"
const HALL_CARD_CROP := Rect2(230, 110, 337, 104)
const PICKER_COLUMNS := 10
const TEXT_W := 820
const BLURB_W := 400

## Set by the Guildhall before build(); null means there is no sidebar to fill.
var sidebar_host: Control = null
var on_changed: Callable = Callable()

var _state = null
var _selected := ""
var _host: VBoxContainer = null
var _notice := ""
var _built := false


func _ready() -> void:
	build()


## See MainMenu.build() — `_ready` is not a reliable trigger under a SceneTree
## script, so the Guildhall calls this explicitly when it mounts the tab.
func build() -> void:
	if _built:
		return
	_built = true
	_state = Services.state(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_host = Widgets.column(10)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_host)
	add_child(scroll)
	_refresh()


func _refresh() -> void:
	if _host == null:
		return
	for c in _host.get_children():
		_host.remove_child(c)
		c.queue_free()

	if _state == null:
		_host.add_child(Widgets.faint("No guild loaded."))
		return

	if _selected.is_empty() and not _state.roster.is_empty():
		_selected = String(_state.roster[0].id)

	_host.add_child(_building_panel())
	_host.add_child(_quarters_panel())

	if not _notice.is_empty():
		var line := Widgets.label_as(_notice, "LabelBody")
		line.add_theme_color_override("font_color", Palette.ACCENT_GOLD_LIGHT)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(TEXT_W, 0)
		_host.add_child(line)

	_refresh_sidebar()
	if on_changed.is_valid():
		on_changed.call()


func _say(text: String) -> void:
	_notice = text


func _wrapped(text: String, variation: String, width: int = TEXT_W) -> Label:
	var l := Widgets.label_as(text, variation)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


# ---------------------------------------------------------------- the building

func _building_panel() -> Control:
	var p := Widgets.panel("PanelCard", 14)
	var col := Widgets.column(6)
	Widgets.content_of(p).add_child(col)
	var tier: int = _state.facility_tier

	var head := Widgets.row(10)
	head.add_child(Widgets.label_as("The Guildhall", "LabelSectionSm"))
	var lvl := Widgets.label_as("Level %d of %d" % [tier + 1, Comfort.LEVELS.size()],
		"LabelMuted")
	lvl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(lvl)
	col.add_child(head)

	# Current level card.
	var now := Comfort.level_at(tier)
	col.add_child(Widgets.label_as("%s — level %d of %d" % [
		String(now["name"]), int(now["level"]), Comfort.LEVELS.size()], "LabelSubject"))
	col.add_child(_wrapped(String(now["look"]), "LabelSmall"))
	col.add_child(Widgets.label_as("%+d morale baseline for everyone  ·  %d comfort %s per raider"
		% [Morale.facility_bonus_for(tier), Comfort.slots_for(tier),
			"slot" if Comfort.slots_for(tier) == 1 else "slots"], "LabelMuted"))

	if tier >= Comfort.MAX_TIER:
		col.add_child(Widgets.faint(
			"There is nothing left to build. The hall is finished."))
		return p

	# Next level card, with the delta table docs/02 §4.5 asks for.
	var next := Comfort.level_at(tier + 1)
	var cost := Comfort.upgrade_cost(tier)
	col.add_child(Widgets.rule())
	col.add_child(Widgets.label_as("Next: %s — %d G" % [String(next["name"]), cost],
		"LabelBody"))
	# LOOP-20: the next level's name and its effect (the delta line below) are
	# the promise; its LOOK ("Roof patched, door replaced, 3 lit windows") is
	# printed only once the camp plate carries a layer for that level, because
	# a sentence about a change nothing draws is a promise the screen breaks
	# on the day the player pays for it (W8-FACILITY lands the layers).
	if Cards.scene_has_level_layer("stage_camp", "guildhall", int(next["level"])):
		col.add_child(_wrapped(String(next["look"]), "LabelSmall"))

	var bonus_delta := Morale.facility_bonus_for(tier + 1) - Morale.facility_bonus_for(tier)
	var slot_delta := Comfort.slots_for(tier + 1) - Comfort.slots_for(tier)
	var delta := Widgets.label_as("%+d morale baseline  ·  %+d comfort slot%s  ·  %s"
		% [bonus_delta, slot_delta, "" if slot_delta == 1 else "s",
			_per_point_line(cost, bonus_delta)], "LabelMuted")
	delta.add_theme_color_override("font_color", Palette.POSITIVE)
	col.add_child(delta)

	# docs/11 §8.4: "the Guildhall screen must show which of the two is blocking."
	# Commissioning is this tab's one commit, so it takes the crimson plate (06 §3).
	var blocker := Comfort.upgrade_blocker(tier, _state.gold, _state.reputation_rank)
	var box := Widgets.button_with_reason("Commission the work — %d G" % cost, blocker)
	var btn := Widgets.button_of(box)
	btn.theme_type_variation = "ButtonCta"
	btn.custom_minimum_size = Vector2(339, 56)
	btn.pressed.connect(_on_upgrade)
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(box)
	return p


## docs/11 §8.4's own unit of comparison — "G per point per raider" — printed on the
## card, because that is the number the player is meant to weigh against a
## Furnishing. docs/11's stated arc is that the building wins early and loses late.
func _per_point_line(cost: int, bonus_delta: int) -> String:
	var heads: int = maxi(1, _state.roster.size())
	if bonus_delta <= 0:
		return "no morale change"
	var per_point := float(cost) / (float(bonus_delta) * float(heads))
	return "%.1f G per point per raider" % per_point


func _on_upgrade() -> void:
	var problem: String = _state.upgrade_guildhall()
	if problem.is_empty():
		_say("The %s is yours. Everyone settles a little higher from now on."
			% Comfort.level_name(_state.facility_tier))
	else:
		_say(problem)
	_refresh()


# ---------------------------------------------------------------- the quarters

func _quarters_panel() -> Control:
	var p := Widgets.panel("PanelCard", 14)
	var col := Widgets.column(6)
	Widgets.content_of(p).add_child(col)
	col.add_child(Widgets.label_as("Quarters", "LabelSectionSm"))

	if _state.roster.is_empty():
		# KIT-08: the empty quarters say so under the kit's glyph; the sentence
		# stays the Label test_comfort reads.
		var empty := Widgets.empty_state("Nobody lives here yet.", Icons.at("empty", "bench"))
		empty.custom_minimum_size = Vector2(0, 96)
		col.add_child(empty)
		return p

	col.add_child(_picker())

	var who = _state.raider(_selected)
	if who == null:
		col.add_child(Widgets.faint("Pick a raider."))
		return p

	# Canon's two lines for whoever is picked (00 §2.1), so the arithmetic
	# below is read against the number it produces.
	var m: int = int(who.morale)
	var line1 := Widgets.label_as("%s — %d %s" % [String(who.display_name), m,
		Cards.morale_glyph(self, m)], "LabelMorale")
	line1.add_theme_color_override("font_color", Palette.morale_color(m))
	col.add_child(line1)
	col.add_child(Widgets.label_as("%s — %s" % [Enums.class_name_of(who.class_id),
		Enums.morale_band_name(m)], "LabelClass"))

	col.add_child(_arithmetic_strip(who))
	col.add_child(_slot_list(who))
	col.add_child(Widgets.rule())
	col.add_child(Widgets.label_as("Furnishings — bought and placed in one go", "LabelLabel"))
	for id in Comfort.FURNISHINGS:
		col.add_child(_furnishing_row(String(id), who))

	col.add_child(Widgets.rule())
	col.add_child(Widgets.label_as("Standing orders — bought once, felt by everyone", "LabelLabel"))
	for id in Comfort.GUILD_FURNISHINGS:
		col.add_child(_guild_row(String(id)))

	col.add_child(Widgets.rule())
	col.add_child(Widgets.label_as(
		"Indulgences — a one-off lift, not a change of address", "LabelLabel"))
	for id in Comfort.INDULGENCES:
		col.add_child(_indulgence_row(String(id), who))
	return p


## A raider's face for the picker: the reference face by name, then the class
## portrait if it has been produced, then the tile's own text.
static func _portrait(r) -> Texture2D:
	var t := Cards.portrait_for(r)
	if t != null:
		return t
	var path := PORTRAIT + "class_%s.png" % String(r.class_key())
	if ResourceLoader.exists(path):
		return load(path)
	return null


## 10 §2 R6: the picker is the reference's portrait mini-grid (01 §4.1), one
## tile per raider, the chosen one lit. Each tile stays a Button whose text is
## the name, so the tests can read and press it.
##
## HALL-22: the chosen tile is a toggle held PRESSED, so it wears a pressed
## StyleBox — the lit plate inside a 2px gold rim (spec 06 §2's ready rim, the
## token the kit's ButtonChip presses with) — instead of the other tiles being
## dimmed to hint at it. Every face stays at full strength; the focus ring is
## the theme's, untouched.
func _picker() -> Control:
	var row := Widgets.row(10)
	row.add_child(Widgets.label_as("Whose", "LabelLabel"))
	var grid := GridContainer.new()
	grid.name = "Picker"
	grid.columns = PICKER_COLUMNS
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	for r in _state.roster:
		var face := _portrait(r)
		var b := Widgets.slot_button(String(r.display_name), face, Widgets.MINI_PITCH)
		b.theme_type_variation = "ButtonMini"
		b.clip_text = true
		if face != null:
			b.add_theme_color_override("font_color", Color(0, 0, 0, 0))
		b.tooltip_text = "%s — %d %s" % [r.display_name, int(r.morale),
			Enums.morale_band_name(int(r.morale))]
		var chosen := String(r.id) == _selected
		b.toggle_mode = true
		b.set_pressed_no_signal(chosen)
		if chosen:
			# The engaged rim is the kit's "ready" gold (06 §2; the same token
			# ButtonChip presses with) at 2px, over the lit plate: a 1px steel
			# line around a 37px portrait did not read at 1x.
			b.add_theme_stylebox_override("pressed", Theme_.flat(
				Palette.SURFACE_PLATE_LIT, Palette.EDGE_READY_GOLD, 2, 4, 0))
		var rid: String = r.id
		b.pressed.connect(func() -> void:
			_selected = rid
			_notice = ""
			_refresh())
		grid.add_child(b)
	row.add_child(grid)
	return row


## docs/02 §4.5, verbatim: "Shows `50 + rarity_offset + facility_bonus + items =
## baseline` as an arithmetic strip, per doc 05 §7.5." Printed as the sum it is, so
## the player can see which term their next purchase moves.
func _arithmetic_strip(who) -> Control:
	var col := Widgets.column(2)
	var tier: int = _state.facility_tier
	var rarity_offset: int = Morale.RARITY_OFFSET[who.rarity]
	var facility: int = Morale.facility_bonus_for(tier)
	var items: int = int(who.comfort_floor)
	var past: int = int(who.backstory_offset)
	var baseline: int = Morale.baseline_of(who, tier)

	var terms := "%d base  %+d %s  %+d Guildhall  %+d furnishings" % [
		Morale.BASE_BASELINE, rarity_offset,
		Enums.rarity_name_of(who.rarity), facility, items]
	if past != 0:
		terms += "  %+d their past" % past
	col.add_child(Widgets.label_as("%s  =  %d baseline" % [terms, baseline], "LabelBody"))

	var raw := Morale.BASE_BASELINE + rarity_offset + facility + items + past
	if raw > baseline:
		# docs/05 §7.6's ceiling. Saying so beats a purchase that silently does
		# nothing.
		var capped := _wrapped(
			"Capped at %d — the happiest anyone settles. %d of that spending does nothing."
				% [Morale.BASELINE_CEILING, raw - baseline], "LabelSmall")
		capped.add_theme_color_override("font_color", Palette.CAUTION)
		col.add_child(capped)

	var now := int(who.morale)
	if now < baseline:
		col.add_child(Widgets.faint("At %d now — %d day%s of rest from settled."
			% [now, Morale.rest_ticks_for(who, tier),
				"" if Morale.rest_ticks_for(who, tier) == 1 else "s"]))
	else:
		col.add_child(Widgets.faint("At %d now — settled, or better." % now))
	return col


func _slot_list(who) -> Control:
	var held: Array = _state.placed_for(who.id)
	var slots: int = Comfort.slots_for(_state.facility_tier)
	var lines: Array = []
	for id in held:
		var f := Comfort.furnishing(String(id))
		lines.append("%s (+%d)" % [String(f["name"]), int(f["floor"])])
	for i in range(held.size(), slots):
		lines.append("empty")
	if _state.guild_furnishings.size() > 0:
		for id in _state.guild_furnishings:
			var g := Comfort.furnishing(String(id))
			lines.append("%s (+%d, guild)" % [String(g["name"]), int(g["floor"])])
	return _wrapped("Slots: %s" % ", ".join(PackedStringArray(lines)), "LabelMuted")


func _furnishing_row(id: String, who) -> Control:
	var f := Comfort.furnishing(id)
	var head := Widgets.row(10)
	var label := "%s  +%d  ·  %d G" % [String(f["name"]), int(f["floor"]),
		int(f["price"])]
	var blocker := _placement_reason(id, who)
	var box := Widgets.button_with_reason(label, blocker)
	var btn := Widgets.button_of(box)
	btn.custom_minimum_size = Vector2(320, 0)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var rid: String = who.id
	btn.pressed.connect(func() -> void: _on_buy(id, rid))
	head.add_child(box)
	head.add_child(_wrapped(String(f.get("blurb", "")), "LabelSmall", BLURB_W))
	return head


## The reason a purchase is refused, computed the same way `GameState` will refuse
## it — so the button and the outcome can never disagree. Gold is checked here too,
## because "you cannot afford it" is the most common reason and the least useful to
## discover by clicking.
func _placement_reason(id: String, who) -> String:
	var held: Array = _state.placed_for(who.id)
	var slot := Comfort.furnishing_slot(id)
	var occupant := ""
	for other in held:
		if Comfort.furnishing_slot(String(other)) == slot:
			occupant = String(other)
			break

	if occupant != "":
		if occupant == id:
			return "%s already has one." % who.display_name
		var mine := int(Comfort.furnishing(id).get("floor", 0))
		var theirs := int(Comfort.furnishing(occupant).get("floor", 0))
		if mine <= theirs:
			return "The %s they already have is no worse." % \
				String(Comfort.furnishing(occupant)["name"])
	else:
		var blocker := Comfort.placement_blocker(
			id, held, _state.facility_tier, who)
		if not blocker.is_empty():
			return blocker

	var price := Comfort.furnishing_price(id)
	if _state.gold < price:
		return "Costs %d G — you have %d." % [price, _state.gold]
	return ""


func _on_buy(id: String, raider_id: String) -> void:
	var problem: String = _state.buy_furnishing(id, raider_id)
	if problem.is_empty():
		var who = _state.raider(raider_id)
		var name := String(Comfort.furnishing(id)["name"])
		_say("%s moves into %s's quarters." % [name,
			who.display_name if who != null else "the raider"])
	else:
		_say(problem)
	_refresh()


func _guild_row(id: String) -> Control:
	var f := Comfort.furnishing(id)
	var reason := ""
	if _state.guild_furnishings.has(id):
		reason = "The guild already has that standing order."
	elif _state.gold < int(f["price"]):
		reason = "Costs %d G — you have %d." % [int(f["price"]), _state.gold]
	var box := Widgets.button_with_reason("%s  +%d each  ·  %d G"
		% [String(f["name"]), int(f["floor"]), int(f["price"])], reason)
	var btn := Widgets.button_of(box)
	btn.custom_minimum_size = Vector2(320, 0)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func() -> void:
		var problem: String = _state.buy_guild_furnishing(id)
		_say(problem if not problem.is_empty()
			else "The whole guild eats now. Even the ones who did not ask.")
		_refresh())
	var head := Widgets.row(10)
	head.add_child(box)
	head.add_child(_wrapped(String(f.get("blurb", "")), "LabelSmall", BLURB_W))
	return head


func _indulgence_row(id: String, who) -> Control:
	var item := Comfort.indulgence(id)
	var reason := ""
	if _state.gold < int(item["price"]):
		reason = "Costs %d G — you have %d." % [int(item["price"]), _state.gold]
	elif _state.indulgences_today >= Comfort.indulgence_cap(_state.roster.size()):
		reason = "The Market has sold out for today."

	var row := Widgets.row(10)
	var box := Widgets.button_with_reason("%s for %s  ·  %d G"
		% [String(item["name"]), who.display_name, int(item["price"])], reason)
	var btn := Widgets.button_of(box)
	btn.custom_minimum_size = Vector2(320, 0)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var rid: String = who.id
	btn.pressed.connect(func() -> void:
		var problem: String = _state.use_indulgence(id, rid)
		_say(problem if not problem.is_empty()
			else "An hour in hot water. It helps, for a day or two.")
		_refresh())
	row.add_child(box)
	row.add_child(_wrapped(String(item.get("blurb", "")), "LabelSmall", BLURB_W))
	return row


# ---------------------------------------------------------------- sidebar

## Concept 1's sidebar image slot holds the boss; here it holds the hall — the
## bare camp's big tent (HALL_CARD_CROP), cropped to the card until the four
## level plates are drawn. The level name and what the next rung costs sit
## under it, the way the reference's title block does.
func _refresh_sidebar() -> void:
	var side := sidebar_host
	if side == null:
		return
	for c in side.get_children():
		side.remove_child(c)
		c.queue_free()
	var tier: int = _state.facility_tier

	side.add_child(Widgets.label_as("The Guildhall", "LabelSection"))
	var card := Widgets.panel("PanelCard", 0)
	card.custom_minimum_size = Vector2(339, 150)
	var cardcol := Widgets.column(0)
	var art := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(HALL_CARD_PLATE)
	atlas.region = HALL_CARD_CROP
	art.texture = atlas
	art.custom_minimum_size = Vector2(337, 104)
	art.stretch_mode = TextureRect.STRETCH_KEEP
	cardcol.add_child(art)
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 14)
	var tbox := Widgets.column(0)
	tbox.add_child(Widgets.label_as(Comfort.level_name(tier), "LabelSubject"))
	tbox.add_child(Widgets.label_as("Level %d of %d" % [tier + 1, Comfort.LEVELS.size()],
		"LabelMuted"))
	tm.add_child(tbox)
	cardcol.add_child(tm)
	card.add_child(cardcol)
	side.add_child(card)

	side.add_child(Widgets.label_as("%+d morale baseline for everyone"
		% Morale.facility_bonus_for(tier), "LabelLabel"))
	side.add_child(Widgets.label_as("%d comfort %s per raider" % [Comfort.slots_for(tier),
		"slot" if Comfort.slots_for(tier) == 1 else "slots"], "LabelMuted"))

	if tier < Comfort.MAX_TIER:
		var next := Comfort.level_at(tier + 1)
		side.add_child(Widgets.rule())
		side.add_child(Widgets.label_as("Next: %s — %d G" % [String(next["name"]),
			Comfort.upgrade_cost(tier)], "LabelBody"))
		var blocker := Comfort.upgrade_blocker(tier, _state.gold, _state.reputation_rank)
		if not blocker.is_empty():
			side.add_child(_wrapped(blocker, "LabelSmall", 300))
	side.add_child(Widgets.rule())
	side.add_child(_ladder(tier))

	if not _notice.is_empty():
		side.add_child(Widgets.rule())
		var line := _wrapped(_notice, "LabelBody", 300)
		line.add_theme_color_override("font_color", Palette.ACCENT_GOLD_LIGHT)
		side.add_child(line)


## docs/02 §4.5's ladder, every rung: what the hall is now, what it was, and
## what the next ones cost (HALL-09's "no sidebar half empty", here with the
## sim's own numbers — `Comfort.LEVELS`, `upgrade_cost`, `facility_bonus_for`).
## The current rung is the bright one; passed rungs are muted, the ones ahead
## carry their price.
func _ladder(tier: int) -> Control:
	var col := Widgets.column(2)
	col.name = "Ladder"
	col.add_child(Widgets.label_as("The ladder", "LabelLabel"))
	for t in Comfort.LEVELS.size():
		var lvl: Dictionary = Comfort.level_at(t)
		var line := "%d  %s  ·  %+d baseline" % [t + 1, String(lvl["name"]),
			Morale.facility_bonus_for(t)]
		if t > tier:
			line += "  ·  %d G" % Comfort.upgrade_cost(t - 1)
		var l := _wrapped(line, "LabelBody" if t == tier else "LabelSmall", 300)
		l.name = "Rung%d" % (t + 1)
		if t < tier:
			l.modulate = Color(1, 1, 1, Widgets.REASONED_DIM)
		col.add_child(l)
	return col


func selected_raider_id() -> String:
	return _selected
