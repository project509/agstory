extends Control
## S02 — Town (docs/13 §5), the hub.
##
## ✅ CANON: "the town will be improved by the raids you do… Instead of the guild
## simply being a menu between raids, make the town itself your progression
## engine" (raw notes, *Town as progression engine*). docs/02 §2.2 restates it:
## the town IS the progression bar.
##
## The art pass rebuilds this on the reference frame: Concept 3's camp — a
## full-bleed illustrated scene with the buildings called out on it as labelled
## plates, the header chips above, the nav rail at the left, the roster cards
## and the event log along the bottom. `art/ref/specs/03-concept3-camp-layout.md`
## measured every coordinate; `game/ui/Frame.gd` owns the shell.
##
## docs/02 §2.3: **five canon buildings, no sprawl.** A sixth needs one cut.
## The five stay exactly as they were — only their presentation changed. The
## Blacksmith remains a gated callout rather than a rail item, because canon
## calls it a "maybe"; its plate reads an in-world sentence (`blurb`, the one
## source — ship plan §6 #10's default, the Blacksmith out of 1.0) and never
## a word about the build (W6-COPY, tools/lint_copy.sh).
##
## This is also where docs/03 §7's Town-unlock column finally reaches a player.
## The column had been computed since the Reputation iteration and printed
## nowhere, so the rank was a word in a chip with no promise attached: reputation
## opened raid tiers (AdventureBoard.gd prints that half) and quietly opened
## nothing the player could see in the town. `_unlock_reason()` now asks docs/02
## §11's rank and price, and the sidebar says what the NEXT rank opens.
##
## W2-TOWN (TOWN-06, spec 10 §3.1): the right column is the hub's WORKING panel
## — the next mission (the pinned notice if it can still be taken, else the
## first rung the guild can climb) with its art, the one crimson control, the
## reputation promise, and a compact "Today" block — rather than a help page
## restating the callouts the player is already looking at.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Icons = preload("res://game/ui/Icons.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const Buildings = preload("res://sim/core/Buildings.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")
const Services = preload("res://game/core/Services.gd")
const Type = preload("res://game/ui/Type.gd")

const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const BOARD := "res://game/screens/AdventureBoard.tscn"
const RAID_PREP := "res://game/screens/RaidPrep.tscn"

## Q18 (the hub commit — 00-plan §6): what the sidebar's one crimson control
## does. "board" = "Open the board" (docs/13 §6.1's deliberate three clicks:
## Town → Board → mission → Depart); "prep" = "Go to prep" (Concept 3 puts the
## commit on the hub: pin the next mission and open prep). Flip the constant,
## nothing else — both branches are built below.
const HUB_CTA := "board"

## The width a sidebar Label may claim. `Frame.SIDEBAR_W` (378) less the
## PanelWarm rim (14) and the pad (18) on each side is 314; one unwrapped Label
## wider than that grew the whole panel to x=1536 (handoff-W1-FRAME, LESSONS
## "find the widest UNWRAPPED sibling first"), so every line here wraps and the
## art well is the only thing with a minimum width — and it is under the cap.
const SIDEBAR_TEXT_W := 310

## docs/02 §3.1, in canon's own spellings — "Adventure's Board", not
## "Adventurer's"; "Market" as the heading even though the core-loop list says
## "Merchant" (docs/02 §12 Q7 owns that naming pass).
##
## `anchor` is where the callout's TAIL lands, in SCREEN pixels: the building's
## foot on the camp plate as this screen frames it (CAMP_OFFSET below). The
## plate places itself above the anchor (Widgets.building_callout, 03 §3
## "production decision": the tail's apex sits on the building). `band`,
## when present, is the part of the scene the plate may occupy (screen pixels;
## default the whole scene band) — it slides a plate off a figure that stands
## at the building's door, and the tail slants to keep pointing. The figures'
## 2x body boxes at CAMP_OFFSET are what these were measured against
## (handoff-W1-STAGE; tests/unit/test_town_layout.gd asserts no plate
## touches one):
##   the guild's big tent (top-left): its right foot — the ranger and the
##     ginger variant stand in its mouth, so the plate hangs to the right;
##   the mess tent (top-right): the crate stack at its left foot — the knight
##     stands in its mouth, so the plate keeps 12px off him on the left;
##   the garden and the trade table (right): the beds' top corner — both
##     variants work the beds, so the plate hangs above them;
##   the stone forge with its kettle stand (below the mess tent): the foot of
##     its left face — the plate ends at the forge's edge so the forge stays
##     seen, above the brown variant's head, left of the Market's plate;
##   the bridge out of camp (bottom): its right railing post — a rogue stands
##     mid-bridge, so the plate hangs over the pines to the right of him.
const BUILDINGS := [
	{
		"id": "guildhall", "name": "Guildhall", "verb": "Maintain",
		"blurb": "The roster lives here. Morale, facilities, records.",
		"scene": "res://game/screens/Guildhall.tscn", "flag": "",
		"anchor": Vector2(405, 258), "band": Rect2(358, 77, 781, 640),
	},
	{
		"id": "tavern", "name": "Tavern", "verb": "Recruit",
		"blurb": "Recruits are found and managed here.",
		"scene": "res://game/screens/Tavern.tscn", "flag": "",
		"anchor": Vector2(866, 242), "band": Rect2(210, 77, 706, 640),
	},
	{
		"id": "market", "name": "Market", "verb": "Buy / Sell",
		"blurb": "Consumables in, salvage out.",
		"scene": "res://game/screens/Market.tscn", "flag": "",
		"anchor": Vector2(1052, 404),
	},
	{
		# The shut plate's second row (LOOP-02, UI-01, CRITIC-C4, ship plan §6
		# #10): the Blacksmith is out of 1.0 by the ship default, so the line is
		# a non-promise in-world sentence — "Under construction." read as a
		# promise the build cannot keep, and the old reason named the build.
		# Q-13 stays the designer's: their own line replaces this one, and if
		# the answer is "in", the flag flips and this row is never read.
		"id": "blacksmith", "name": "Blacksmith", "verb": "Improve gear",
		"blurb": "Closed. The smith took a better offer.",
		"scene": "res://game/screens/Blacksmith.tscn", "flag": "blacksmith",
		"anchor": Vector2(893, 498), "band": Rect2(210, 77, 690, 410),
	},
	{
		"id": "board", "name": "Adventure's Board", "verb": "Depart",
		"blurb": "Missions, in the order the guild is ready for them.",
		"scene": "res://game/screens/AdventureBoard.tscn", "flag": "",
		"anchor": Vector2(601, 662), "band": Rect2(561, 77, 578, 640),
	},
]

var _router = null
var _state = null
var _built := false


func _ready() -> void:
	build()


## Populate the page. Idempotent, and public because `_ready()` is not a
## reliable trigger everywhere this screen is used: a SceneTree script (the test
## runner, tools/) adds nodes to a root that is not itself "inside the tree", so
## `_ready` never fires and the screen would mount completely blank. The router
## calls this after mounting, which makes the two paths behave identically.
func build() -> void:
	if _built:
		return
	_built = true
	_router = Services.router(self)
	_state = Services.state(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Theme_.current(self)
	_build()


func _build() -> void:
	var f := Frame.build(self, {
		"nav": Frame.nav_items(_router), "active": "home", "framed": false,
	})
	Frame.wire_nav(f, _router, "home")

	_scene(f.scene)
	Frame.standard_chips(f, _state)
	_sidebar(Frame.sidebar(f))
	_strip(f.strip)


# ---------------------------------------------------------------- the camp

## Where the camp's 1536x1024 plate sits inside this screen's scene window.
##
## The window is what the chrome leaves: x 210..1141 between the rail and the
## sidebar, y 77..726 above the strip — 931x649 of a 1536x1024 plate. So the
## plate has to be OFFSET rather than placed at the origin, or the screen frames
## the top-left corner of a camp whose fire is at (720, 400) and whose bridge is
## at y 762. These two numbers put the fire just above the window's centre and
## bring the whole bridge inside the bottom edge — a figure sliced in half by the
## window's edge reads as a bug, so the edge lands below the last pair of feet.
## The five building callouts are anchored in the same screen pixels (see
## `BUILDINGS`): a plate pixel (px, py) is on screen at (px, py) + CAMP_OFFSET.
## They are a composition choice, checked with `tools/shot.gd`, and they belong
## to this SCREEN: the same plate is framed differently by every screen that
## stands on it, which is why the offset is not in the scene JSON.
const CAMP_OFFSET := Vector2(-46, -62)


func _scene(host: Control) -> void:
	# The 2026-09-11 directive: the screen stands on the BARE plate
	# (game/assets/bg/stage_camp.png) rather than on Concept 3's crop, which
	# carried painted people and a painted speech line. Everyone in the camp is
	# now an animated actor from game/assets/scenes/stage_camp.json, and the
	# callouts go on top of the stage.
	var stage := SceneStage.load("stage_camp")
	stage.position = CAMP_OFFSET
	stage.size = host.size - CAMP_OFFSET
	host.add_child(stage)
	# The camp's one speaking bubble says what the roster would: their own
	# backstory bullets (docs/03), so the line changes with the guild.
	if _state != null:
		var lines: Array = []
		for r in _state.roster:
			for bullet in r.backstory:
				var text := ""
				if typeof(bullet) == TYPE_DICTIONARY:
					text = String(bullet.get("text", ""))
				else:
					text = str(bullet)
				if not text.is_empty():
					lines.append(text)
		stage.set_lines(lines)
		if _state.last_result != null and not _state.last_result.cleared():
			stage.set_mood("wipe")

	var plates: Array = []
	for b in BUILDINGS:
		var plate := _callout(b)
		host.add_child(plate)
		plates.append(plate)
	_settle_callouts.call_deferred(plates)
	# UI-04 (W7-STAGE): the joke plate keeps clear of the five callouts — the
	# stage reads each plate's rect live (they settle a frame later) and
	# lifts or slides its speech off them (test_town_layout pins it).
	stage.set_keep_out(plates)


## A plate is laid out once BEFORE the theme reaches it — Godot resolves a
## Control's theme variations on a deferred notification after it enters the
## tree — and a Control never shrinks back below the size a layout pass gave
## it. The locked plate's reason row measured taller under the default theme
## than under ours, so the Blacksmith settled 17px taller than its neighbours
## (the W2-TOWN probe: size 101, minimum 84) while the enabled plates, whose
## first pass came out SMALLER, simply grew into place. One pass after the theme
## has landed returns every plate to the size its content asks for; the kit's
## own `item_rect_changed` hook then re-places it on its anchor.
func _settle_callouts(plates: Array) -> void:
	for p in plates:
		if is_instance_valid(p) and p is Control:
			(p as Control).size = (p as Control).get_combined_minimum_size()


## One building's plate (TOWN-01/02). The kit draws the plate, the icon column,
## the tail and the locked treatment (the title Button disabled, everything
## dimmed to 0.55, the reason in CAUTION inside the plate); this screen supplies
## the building's glyph (W1-ICONS' `building_<id>`), the padlock in its place
## when the door is shut, the anchor the tail lands on and the band the plate
## may occupy. A shut door also gives up its verb line: the reason takes that
## row, so the locked plate is the same two-row height as its neighbours
## (TOWN-02's acceptance) and "why" is the second thing read, not the third.
func _callout(b: Dictionary) -> Control:
	var reason := _unlock_reason(b)
	var locked := not reason.is_empty()
	var icon: Texture2D = Icons.at("lock", "16") if locked else Icons.at("building", String(b["id"]))
	var band: Rect2 = b.get("band", Rect2())
	var callout := Widgets.building_callout(
		String(b["name"]), String(b["verb"]), reason, icon, b["anchor"], band)
	callout.name = "Callout_%s" % String(b["id"])
	if locked:
		var verb := callout.find_child("Subtitle", true, false)
		if verb != null:
			verb.visible = false
		# One line, unwrapped (TOWN-02). The kit wraps the reason at 200px, and
		# a wrapping Label's first pass — before its column has given it a
		# width — breaks every word onto its own line, which grew the plate to
		# three rows' worth and a Control never shrinks back (W1-KIT shot 1,
		# the 125px Blacksmith). Unwrapped, the row is one line at any scale
		# and the plate widens for a long sentence instead of growing down.
		var why := callout.find_child("Reason", true, false)
		if why is Label:
			(why as Label).autowrap_mode = TextServer.AUTOWRAP_OFF
	var btn := Widgets.button_of(callout)
	if btn != null and not locked:
		var scene: String = String(b["scene"])
		btn.pressed.connect(func() -> void: _router.push(scene))
	return callout


# ---------------------------------------------------------------- sidebar

func _sidebar(host: Control) -> void:
	if host == null:
		return
	# The panel's 586px (650 less the rim and the pad) hold every row below at
	# text_scale 100 with room, and at 150 only because the rows were budgeted
	# for it (CRITIC-G15): the card's caption on its own art, a card whose art
	# well gives up height as the type grows, one-line copy in the Today
	# block, no separate "Today" heading, a tighter gap (5 between rows of
	# 25+, and 6 under the card's facts). Measured with the W2-TOWN probe:
	# 456 of 586 at 100, 578 at 150 — the facts line's second row (32px at
	# 150, docs/13 §4.4) is what the last of it buys.
	var pct: int = Theme_.scale_of(self)
	var col := Widgets.column(5 if pct >= 150 else 8)
	host.add_child(col)

	# The guild's name is the one line here that does not wrap (a heading);
	# trimmed instead, so a long name cannot widen the panel either. The
	# card's "Next mission" caption sits on the card's own art, so the name
	# has the whole row at every text scale (at 150 sharing the row cut it to
	# "A Guild S…").
	var name := ""
	if _state != null:
		name = String(_state.guild_name)
	var heading := Widgets.label_as(name if not name.is_empty() else "A Guild Story", "LabelSection")
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
	col.add_child(heading)

	# 1. The next mission (spec 10 §3.1's "Next mission" panel; TOWN-06).
	var e = _next_mission()
	col.add_child(_mission_card(e, pct))
	col.add_child(_hub_cta(e))

	# 2. The reputation promise — docs/03 §7's town column, one rung ahead.
	var promise := _wrapped(_town_unlock_line(), "LabelSmall")
	promise.add_theme_color_override("font_color", Palette.ACCENT_GOLD_LIGHT)
	col.add_child(promise)

	# 3. Today: the roster and its mood, then the log — one breath each.
	col.add_child(Widgets.rule())
	for line in _today_lines():
		col.add_child(_wrapped(line, "LabelSmall"))
	# The Adventure's Board's rungs were data nothing advanced and nothing
	# read. docs/02 §11 prices them at 0 and ✅ CANON says why — "New Tiers
	# can be unlocked by gaining reputations with the town" — so the level is
	# derived from the rank, and this is the first place a player can see it
	# has moved: §9.2's own L1→L2 delta ("post repaired, 2 notices") is art
	# that has not been drawn yet. The sentence after the colon is asserted
	# verbatim (test_screens); "Board" is the callout's own short name.
	if _state != null:
		for b in BUILDINGS:
			var id := String(b["id"])
			if Buildings.is_reputation_only(id):
				col.add_child(_wrapped("Board: Level %d of %d — reputation raises this, not gold."
					% [Buildings.reputation_level(id, _state.reputation_rank),
						Buildings.top_level(id)], "LabelMuted"))

	# 4. The way out, demoted (TOWN-31 / CRITIC-C14): a quiet Button, never a
	# LinkButton — `_texts()` reads Buttons and spec 10 §3.1 keeps it one.
	col.add_child(Widgets.rule())
	var back := Widgets.button("Back to menu")
	back.theme_type_variation = "ButtonQuiet"
	back.pressed.connect(_on_back)
	col.add_child(back)


## A sidebar line that wraps inside the panel instead of widening it.
func _wrapped(text: String, variation: String) -> Label:
	var l := Widgets.label_as(text, variation)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(SIDEBAR_TEXT_W, 0)
	return l


## The art well's height per text scale: the card gives up picture, never
## words, as the type grows (docs/13 §4.4 reflows by rows and never truncates
## a value — the facts line keeps its two rows at every scale, and at 150 that
## second row is the sidebar's last 25px; see `_sidebar`).
const ART_H := {100: 88, 125: 72, 150: 48}


## The Adventure's Board's card, reused: the encounter's art over its name and
## facts. With nothing to pin (no content, or a walked-out ladder) the well is
## empty and says so — the card keeps its shape so the column does not jump
## between a Day-1 guild and a Day-23 one.
func _mission_card(e, pct: int = 100) -> Control:
	var card := Widgets.panel("PanelCard", 0)
	card.name = "NextMission"
	card.clip_contents = true
	var cardcol := Widgets.column(0)
	var art := Cards.encounter_art(e, Vector2(SIDEBAR_TEXT_W, int(ART_H.get(pct, 88))))
	# The caption, on the picture: a small tag at the well's top-left, so the
	# column spends no row on it. LabelSmall, not LabelLabel: the thumbnail
	# (`encounter_art`) is centred in the well, and at 150 a LABEL-sized tag
	# reached the middle and sat on the picture; SMALL keeps the tag inside
	# the well's left 45% at every scale, so the thumbnail reads whole. The
	# well is a plain Control, so a positioned child stays where it is put
	# (LESSONS: containers re-lay theirs).
	var tag := Widgets.panel("", 0)
	tag.name = "Caption"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_stylebox_override("panel",
		Theme_.flat(Color(Palette.GROUND_FRAME, 0.82), Color(0, 0, 0, 0), 0, 3, 4))
	var caption := Widgets.label_as("Next mission", "LabelSmall")
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(caption)
	art.add_child(tag)
	tag.position = Vector2(6, 6)
	cardcol.add_child(art)
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 12)
	tm.add_theme_constant_override("margin_right", 12)
	tm.add_theme_constant_override("margin_bottom", 6 if pct >= 150 else 8)
	var tbox := Widgets.column(0)
	var title := Widgets.label_as(
		e.display_name if e != null else "Nothing pinned yet", "LabelSubject")
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.custom_minimum_size = Vector2(SIDEBAR_TEXT_W - 24, 0)
	tbox.add_child(title)
	var facts := Widgets.label_as(_facts_of(e), "LabelMuted")
	facts.name = "Facts"
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts.max_lines_visible = 2
	facts.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	facts.custom_minimum_size = Vector2(SIDEBAR_TEXT_W - 24, 0)
	tbox.add_child(facts)
	tm.add_child(tbox)
	cardcol.add_child(tm)
	card.add_child(cardcol)
	return card


## The one crimson control on the hub (06 §3: crimson = the screen's commit).
## `HUB_CTA` decides which door it is; either way a shut door prints why
## beneath itself (docs/13 §7, the `reasoned` treatment).
func _hub_cta(e) -> Control:
	var cta: Button
	var reason := ""
	if HUB_CTA == "prep":
		cta = Widgets.cta("Go to prep")
		reason = _prep_reason(e)
		if e != null:
			var enc_id: String = String(e.id)
			cta.pressed.connect(func() -> void: _on_prep(enc_id))
	else:
		cta = Widgets.cta("Open the board")
		if _router == null or not _router.screen_exists(BOARD):
			reason = "Not built in this version yet."
		cta.pressed.connect(func() -> void:
			if _router != null:
				_router.push(BOARD))
	var box := Widgets.reasoned(cta, reason)
	box.name = "HubCta"
	return box


## Why "Go to prep" cannot go yet: the build first (no prep screen), then the
## campaign's own gate (`RaidPlan.locked_reason`), then the empty ladder.
func _prep_reason(e) -> String:
	if _router == null or not _router.screen_exists(RAID_PREP):
		return "Raid prep is not in this version yet."
	if e == null:
		if _state != null and not RaidPlan.ladder(_state).is_empty():
			return "The ladder is walked out — nothing left to prepare for."
		return "Nothing to prepare for — the board has no notices."
	return RaidPlan.locked_reason(_state, e)


func _on_prep(encounter_id: String) -> void:
	if _state != null:
		_state.selected_encounter_id = encounter_id
	if _router != null:
		_router.push(RAID_PREP)


## The mission the hub points at: what the guild last pinned, if it is still on
## the board and can be taken; otherwise the next rung it can climb. Null with
## no content (the contentless states the screen tests mount) — and null when
## the ladder is WALKED OUT (LOOP-07): every rung resolved and nothing mounted
## past them. It used to fall back to `ladder[0]`, which pinned "Adventure 0 ·
## CLEARED" under a "Next mission" caption over a live commit — the first dead
## end a good player hits, dressed as a mission. `_mission_card(null)` prints
## the walked-out sentence instead, and the board (where the goal is stated)
## says what the road past Raid 1 is waiting on.
func _next_mission():
	if _state == null:
		return null
	var ladder: Array = RaidPlan.ladder(_state)
	if ladder.is_empty():
		return null
	var chosen: String = String(_state.selected_encounter_id)
	if not chosen.is_empty() and not _state.rung_resolved(chosen):
		for e in ladder:
			if String(e.id) == chosen and RaidPlan.locked_reason(_state, e).is_empty():
				return e
	return RaidPlan.next_open_mission(_state)


## The notice's facts line, as the Adventure's Board prints it (kind, size,
## rounds; CLEARED when it is). Two lines at most on the card.
func _facts_of(e) -> String:
	if e == null:
		if _state == null or _state.content == null:
			return "The guild has no content loaded to pin."
		return "The ladder is walked out — the board is up the road."
	var facts := "%s  ·  %s  ·  about %d rounds" % [
		Enums.encounter_kind_name_of(e.kind),
		Type.count(e.enemies.size(), "enemy", "enemies"), e.target_rounds]
	if _state != null and _state.has_cleared(String(e.id)):
		facts += "  ·  CLEARED"
	elif _state != null and _state.skipped_tutorials.has(String(e.id)):
		facts += "  ·  SKIPPED"
	return facts


## The "Today" block: how many are on the roster and how they feel, then how
## much the log holds. Every number is the state's own; the mood word is
## `Enums.morale_band_name` of the roster's mean, so it is a word under
## emoji_free too (RULES §2). Short on purpose — each line is one row at 100
## and two at 150, which is what keeps "Back to menu" on the panel.
func _today_lines() -> Array:
	var out: Array = []
	if _state == null:
		out.append("Today: no guild loaded.")
		return out
	if _state.roster.is_empty():
		out.append("Today: no raiders yet — the Tavern is up the road.")
	else:
		var total := 0
		for r in _state.roster:
			total += int(r.morale)
		var mean := int(round(float(total) / float(_state.roster.size())))
		out.append("Today: %d raiders · morale %d · %s" % [
			_state.roster.size(), mean, Enums.morale_band_name(mean).to_lower()])
	# The number the strip's log SHOWS (W5-SCALE): the rows that fit under the
	# head inside the 262 strip, Cards.event_log's own arithmetic — six — not a
	# count of its own (the sidebar said "7 recent events" over a six-row log).
	var fit: int = int((Widgets.STRIP_H - 28 - Cards.EVENT_HEAD_H - 1) / Widgets.LOG_ROW_PITCH)
	var events: Array = Cards.recent_events(_state, fit)
	if events.is_empty():
		out.append("Nothing on the log yet.")
	else:
		out.append("%d recent event%s on the log." % [events.size(), "" if events.size() == 1 else "s"])
	return out


## docs/03 §7's Town-unlock column, one rung ahead. The Adventure's Board already
## prints the Content column the same way ("what Known buys"), so the town prints
## the town half rather than leaving the rank a name with nothing behind it.
##
## docs/02 §2.2 keeps the HUD to the rank NAME only, and this obeys it: no
## reputation number appears here. The countdown stays on the chip's tooltip and
## on the Board, where the player is deciding what to run.
##
## `rp_for_next()` is the top-of-ladder test rather than a rank comparison,
## because docs/03 §7's own table clamps — asking `town_unlock(rank + 1)` at
## Legendary would print Legendary's row a second time as if it were still ahead.
##
## The promise names only what THIS build mounts (LOOP-06): the row is read
## through `Reputation.town_unlock_for_build()`, which drops every item whose
## building is behind a feature flag that is off — so a Known guild is not told
## "Next at Respected: Blacksmith opens" by an executable that ships the
## Blacksmith flag off. When nothing in town opens at the next rank the line
## says what a rank always buys (docs/03 §7's sell-rate and price columns move
## every rung) rather than promising a building.
func _town_unlock_line() -> String:
	if _state == null:
		return "Reputation decides what opens next."
	var rank: int = _state.reputation_rank
	var flags := _building_flags()
	if Reputation.rp_for_next(rank) < 0:
		var here := Reputation.town_unlock_for_build(rank, flags)
		if here.is_empty():
			here = "better rates at the Market"
		return "%s: %s — the highest standing there is." % [
			Enums.reputation_name_of(rank), here]
	var opens := Reputation.town_unlock_for_build(rank + 1, flags)
	if opens.is_empty():
		opens = "better rates at the Market"
	return "Next at %s: %s." % [Enums.reputation_name_of(rank + 1), opens]


## Building id -> whether its feature flag is on, for every building in
## BUILDINGS that has one. Read off `state.flags` the way `_unlock_reason`
## reads it (absent = off), so the promise line and the plate agree.
func _building_flags() -> Dictionary:
	var out := {}
	for b in BUILDINGS:
		var flag := String(b["flag"])
		if flag.is_empty():
			continue
		out[String(b["id"])] = _state != null and bool(_state.flags.get(flag, false))
	return out


# ---------------------------------------------------------------- bottom strip

## The strip pages itself (TOWN-16: `Cards.roster_strip` draws its own ◄ ►);
## the log's empty state carries the hub's hint (TOWN-23 / KIT-08).
func _strip(host: Control) -> void:
	if _state == null:
		return
	Cards.roster_strip(host, _state, 0)
	Cards.event_log(host, _state, 7, "Raids and rests write here.", Icons.at("empty", "quill"))


# ---------------------------------------------------------------- gates

## Why a building cannot be entered, or "" when it can. Three gates, asked in
## the order the player can act on them: the canon "Maybe" feature flag
## (docs/14 §5.2 — the game must be completable with every flag off), then
## docs/02 §11's rank and price, then whether the screen has been built yet.
##
## The flag has to be asked FIRST. A flagged-off building is not rank-locked, it
## is absent from the build — telling a Known guild to "Reach Respected" for a
## smithy this executable does not contain is a gate that lies about what
## meeting it would do, and it would replace the sentence a test already pins.
##
## Only the rank/price gate is new here, and only the Blacksmith trips it: §11
## opens the other four at Unknown for free, so `entry_blocker` returns "" for
## them by construction rather than by a special case.
##
## ONE line each (TOWN-02): the reason takes the plate's second row, and the
## kit's Reason Label is unwrapped, so a two-sentence string is still one
## line. The flagged-off reason is the building's own `blurb` — the one
## source for the shut plate's sentence (CRITIC-C4: three sentences for one
## string was two too many) — and test_screens pins it through
## `TownScript.BUILDINGS`, never a literal here.
func _unlock_reason(b: Dictionary) -> String:
	var flag := String(b["flag"])
	if not flag.is_empty():
		var on: bool = _state != null and bool(_state.flags.get(flag, false))
		if not on:
			return String(b["blurb"])
	if _state != null:
		# docs/11 §8.4's rank-then-price sentence — the same two strings the
		# Guildhall's facility gate prints, because sim/core/Buildings.gd owns
		# both halves and the town must not grow a second voice for them.
		var standing := Buildings.entry_blocker(
			String(b["id"]), _state.gold, _state.reputation_rank)
		if not standing.is_empty():
			return standing
	if _router == null or not _router.screen_exists(String(b["scene"])):
		return "Not built in this version yet."
	return ""


func _on_back() -> void:
	if _router != null:
		_router.goto(MAIN_MENU)
