extends Control
## S10 — Raid prep, "the screen that carries the game" (docs/13 §10).
##
## ✅ CANON names this screen's entire job in one sentence: *"Oh shit, Steve is
## at 14. Maybe I shouldn't bring him, unless he really wants to go and I know I
## can beat the raid with him messing up."* Everything here exists to make that
## sentence available in one look.
##
## docs/13 §10.4 lists what this screen must NOT do, and the two that shape the
## code are:
##   - **Depart is never blocked by a bad comp.** docs/06 §6.6: "Penalties
##     teach; locks do not." A one-tank raid can always leave; it just leaves
##     having been told exactly what it is walking into.
##   - **Morale is never a bar or a colour alone.** Every raider on both lists
##     carries the integer and the state word, on the bench as well as in the
##     twelve, with no click required to see it.
##
## The bench is sorted morale-ascending so the person you should be worrying
## about is the first person you read.

const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Icons = preload("res://game/ui/Icons.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Services = preload("res://game/core/Services.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Morale = preload("res://sim/core/Morale.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const Consumables = preload("res://sim/core/Consumables.gd")

## Which arena a fight is shown in is unspecified and is one constant, in
## SceneStage, shared with RaidView and Results — see its `DEFAULT_ARENA` and
## docs/15 Q-96.

## Where the arena's 1536x1024 plate sits in the 929x640 viewport when the
## scene ships no `marks.view` of its own. Both arena scenes do (STAGE-01: the
## blocking lives in the JSON beside the plate, read through `SceneStage.marks`)
## and RaidView reads the same key, so prep shows the rows the fight is fought
## on — the lantern floor, the bridge, the ledge — and not the ceiling. This is
## RaidView's own fallback, kept identical so a scene without marks still puts
## the two screens on the same band. See `arena_view()`.
const ARENA_OFFSET := Vector2(0, -280)
## The arena plates' size (both are 1536x1024; SceneStage's header says so).
## `arena_view` never lets the plate's edge show inside the host.
const PLATE := Vector2(1536, 1024)

## Dimmed so the readout stays the thing being read (09 §1.3). Was 0.55 against
## the crop; eased a step because the flames it is now dimming are ours.
const SCENE_DIM := Color(0.62, 0.62, 0.68)

## The readout panel (docs/13 §10.2's four readouts) is opaque from x 536 to
## 912 of the host, so the arena is really the column to its LEFT — and that is
## the column the fight band is centred in (`arena_view`).
const READOUT_X := 536
const READOUT_POS := Vector2(536, 12)
const READOUT_SIZE := Vector2(376, 616)

## STAGE-01, on this screen: the band RaidView fights on is the scene's
## `marks.party` ranks — the feet points grown by the tallest figure any canon
## class draws at the mark's scale (`fight_band`). The arena OUTSIDE it wears a
## second, lighter dim (`BAND_SCRIM_ALPHA` of GROUND_PAGE) and the band itself
## a 2px bronze rim, so "where the party stands" is read in the preview. The
## rim used to carry a caption saying so over an empty band (LOOP's C29); the
## caption is gone and the party itself stands there from W7-PREP. Every piece
## of it ignores the mouse.
const BAND_PAD := 12.0
const BAND_SCRIM_ALPHA := 0.32
const BAND_RIM_W := 2
const BAND_RIM_ALPHA := 0.85

## W7-PREP (UI-16 / LOOP-09): the chalked party STANDS on the band, placed
## through the stage exactly the way RaidView places the fight's twelve
## (`_party_layout` — the marks' ranks, tanks nearest the boss), so the preview
## and the fight are one picture. A mark nobody is chalked on is an empty
## SEAT: the figure's contact-shadow ellipse alone, in the greyed tone
## `SceneStage.party_state_style("downed")` gives a fallen figure, at this
## alpha — a spot on the floor, never a stand-in figure of a class nobody
## picked. The rim around the band is a focus outline now: it shows only
## while the strip (the cards and the bench) holds the keyboard focus.
const SEAT_ALPHA := 0.7
const SEAT_LIFT := Vector2(0, -2)

## UI-17: the risk meter is DRAWN — `RiskHatch` below, 4px diagonal stripes in
## the verdict band's tone over a muted track — and the band word sits beside
## it as its caption. `RaidPlan.risk_hatch()`'s typed "///...." stays for the
## log and the tests; both read `RaidPlan.risk_fill`, so they cannot disagree.
const HATCH_SIZE := Vector2(168, 10)
const HATCH_TRACK_ALPHA := 0.28

## UI-18: the Raid Team row shows this many faces, then a "+N" tile that turns
## the strip to the first card the row does not show.
const TEAM_FACES := 4

## docs/13 §12.4: `ui.chalk_bad` fires when the comp check TURNS invalid, "60 ms
## after the slot redraw". The number is the doc's; the wait is a tree timer
## (`_chalk_bad_later`), never an await.
const CHALK_BAD_DELAY_MS := 60

## KIT-08: the bench pads to the mini-grid's full 2x4 (Cards caps the grid at
## eight cells) so an empty bench shows empty seats, not a blank panel.
const BENCH_SEATS := 8

## G15 / TOWN-17, the widths a line may claim. The sidebar panel is 378 wide
## with an 18px pad and a 14px PanelWarm margin each side — 314 of content.
## The scroll bar the 150% scale brings is 8px and a ScrollContainer ADDS it
## to its child's minimum (probe: a 314 child made the scroll 322 and the
## panel 386), so nothing inside claims more than 306: the art well is 306
## and centred (a 4px inset each side at 100%), text wraps at 302. The
## readout is 376 with a 16px pad and PanelSteel's 14 — 316, less the same.
## The column's gap is 6 and the art 84 tall so the whole mission block sits
## in the 450px above the commit at 100% with no bar (probe: 451 of 450 at
## gap 8 / art 88 — one pixel over is a bar, and a bar is 8px of width).
const SIDEBAR_TEXT_W := 302
const SIDEBAR_ART := Vector2(306, 84)
const READOUT_TEXT_W := 304
const SIDEBAR_GAP := 6
## The strip's log slot (Cards.event_log's rect: x 1032, 474 wide, the strip's
## height), which holds the provisions on this screen; text inside wraps at
## the panel less its 14px pad and PanelRound's 6.
const PROVISIONS_POS := Vector2(1032, 0)
const PROVISIONS_SIZE := Vector2(474, Widgets.STRIP_H)
const PROVISIONS_TEXT_W := 434

const BOARD := "res://game/screens/AdventureBoard.tscn"
const RESULTS := "res://game/screens/Results.tscn"
const RAID_VIEW := "res://game/screens/RaidView.tscn"

var _router = null
var _state = null
var _encounter = null
var _chalked: Array = []
var _bench_host: VBoxContainer = null
var _group_host: VBoxContainer = null
var _readout: VBoxContainer = null
var _provisions: VBoxContainer = null
var _depart: Button = null
var _depart_host: VBoxContainer = null
var _provision_notice := ""
var _built := false
var _frame = null
var _strip: Control = null
var _verdict_host: VBoxContainer = null
var _team_host: HBoxContainer = null
var _page := 0
## The comp check's last verdict on its two HARD rows (slots, tanks), so
## `_build_readout` can hear it TURN invalid and not merely be invalid.
var _comp_ok := false
var _comp_seen := false
## The arena stage and its blocking, held from `_scene` so `_refresh` can
## re-place the party without rebuilding the plate (UI-16).
var _stage: Control = null
var _marks: Dictionary = {}
var _party_sprites: Dictionary = {}   # raider id -> AnimatedSprite2D
var _seats: Array = []                # Sprite2D per empty mark
var _rim: Panel = null


## UI-17: the drawn risk meter. `fill` is `RaidPlan.risk_fill` (0 at the
## baseline, 1 at the SEVERE ratio); the filled span wears 4px diagonal
## stripes in `tone` over a faint plate, the rest is an outlined track. An
## inner class, not a kit widget: nothing else draws one, and it is 20 lines.
class RiskHatch extends Control:
    const PITCH := 4.0
    const PLATE_ALPHA := 0.16
    const STRIPE_W := 1.5
    var fill := 0.0
    var tone := Color(0.9, 0.9, 0.9)
    var track := Color(0.9, 0.9, 0.9, 0.3)

    func _draw() -> void:
        var w := size.x
        var h := size.y
        draw_rect(Rect2(Vector2.ZERO, size), track, false, 1.0)
        var filled := floorf(w * clampf(fill, 0.0, 1.0))
        if filled <= 0.0 or h <= 0.0:
            return
        draw_rect(Rect2(Vector2.ZERO, Vector2(filled, h)),
            Color(tone, PLATE_ALPHA), true)
        # One stripe every PITCH px, rising left to right, each one
        # clipped to the filled span by its own parameter range.
        var x := -h
        while x < filled:
            var t0 := maxf(0.0, -x / h)
            var t1 := minf(1.0, (filled - x) / h)
            if t1 > t0:
                var a := Vector2(x, h)
                var d := Vector2(h, -h)
                draw_line(a + d * t0, a + d * t1, tone, STRIPE_W)
            x += PITCH


func _ready() -> void:
    build()


func build() -> void:
    if _built:
        return
    _built = true
    _router = Services.router(self)
    _state = Services.state(self)
    set_anchors_preset(Control.PRESET_FULL_RECT)
    theme = Theme_.current(self)
    _resolve_encounter()
    _auto_chalk()
    _build()


func _resolve_encounter() -> void:
    if _state == null or _state.content == null:
        return
    var id: String = _state.selected_encounter_id
    if id.is_empty():
        var first: Array = _state.content.raid_encounters(1)
        if not first.is_empty():
            _encounter = first[0]
            _state.selected_encounter_id = _encounter.id
        return
    _encounter = _state.content.encounter(id)


## Open with a suggested twelve rather than an empty slate — the player's job is
## to CHANGE this list, not to assemble one from nothing every night. Highest
## morale first, which is the choice a reasonable guild leader makes by default
## and therefore the one worth arguing with.
##
## docs/13 §10.4 forbids the screen reordering the chalked twelve on its own
## after this point; seeding the opening state is not the same thing.
## The suggestion itself lives in `RaidPlan` so this screen and
## `tools/playtest.gd` send the same party — a harness that chalked a different
## twelve would be measuring a game nobody plays (audit M6-PLAY-01).
func _auto_chalk() -> void:
    _chalked = RaidPlan.suggest_party(_state, _encounter)


## How many this encounter fields. An Adventure takes SIX (docs/10 §3); only a
## raid takes canon's twelve. Reading the rulebook instead of the encounter let
## the player send twelve on a six-person Adventure, which doubles the party DPS
## the Adventure HP was sized against.
func _party_cap() -> int:
    return RaidPlan.party_size(_encounter)


## The reference's HOME screen is really this one: Concept 1's sidebar reads
## "Current Raid -> success chance -> rewards -> SEND THEM ANYWAY", which is
## exactly raid prep. So this screen is archetype A (10 §3.9): the arena in the
## scene viewport, the mission and the commit in the sidebar, the chalked party
## as cards along the bottom, and the bench as the "Available" mini-grid.
func _build() -> void:
    _frame = Frame.build(self, {
        "nav": Frame.nav_items(_router), "active": "board", "framed": true,
    })
    Frame.wire_nav(_frame, _router, "board")
    _scene(_frame.scene)
    Frame.standard_chips(_frame, _state)
    _sidebar(Frame.sidebar(_frame))
    _strip = _frame.strip
    _refresh()


func _scene(host: Control) -> void:
    # 09 §1.3 and the 2026-09-11 directive: the arena you are about to walk
    # into, on the BARE plate, dimmed so the readout on top of it stays the
    # thing being read. The old crop was Concept 2's void arena with its boss,
    # its damage numbers and its label pills painted in — a screen showing a
    # fight that is not the fight you are about to have.
    #
    # STAGE-01: which rows of the plate, and where on them the party will
    # stand, is the scene's `marks` — the same data RaidView places the fight
    # by — so the preview and the fight are one picture. The view is the
    # mark's, shifted sideways only so the party band sits in the column the
    # readout leaves open; the band is framed and the rest of the arena dimmed
    # a second time (`_frame_band`).
    var arena := SceneStage.arena_for(_encounter)
    var m := SceneStage.marks(arena)
    var view := arena_view(m, host.size)
    var stage := SceneStage.load(arena)
    stage.position = view
    stage.size = host.size - view
    stage.modulate = SCENE_DIM
    host.add_child(stage)
    _stage = stage
    _marks = m
    _frame_band(host, m, view)
    # UI-16: the rim is a focus outline. The viewport says where the focus
    # went; off-tree (the test runner, tools/) there is no viewport and the
    # rim simply stays a hidden Panel the tests can still measure.
    if is_inside_tree() and get_viewport() != null:
        get_viewport().gui_focus_changed.connect(_on_focus_changed)

    # docs/13 §10.2's four readouts, none of them behind an interaction — at
    # 100%, where the column fits its 556px with room (a test does the
    # arithmetic). G15: at 150% the same lines are half again as tall and
    # cannot fit, so the column lives in a ScrollContainer whose bar shows
    # inside the rim only then (LESSONS: a bar the panel edge hides is no
    # fix); every line wraps at READOUT_TEXT_W so nothing is ever cut.
    var panel := Widgets.panel("PanelSteel", 16)
    panel.name = "Readout"
    host.add_child(panel)
    panel.position = READOUT_POS
    panel.size = READOUT_SIZE
    panel.clip_contents = true
    var scroll := ScrollContainer.new()
    scroll.name = "ReadoutScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    Widgets.content_of(panel).add_child(scroll)
    _readout = Widgets.column(4)
    _readout.name = "ReadoutCol"
    _readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_readout)

    var head := Widgets.column(2)
    head.position = Vector2(18, 18)
    host.add_child(head)
    var title := "Raid prep"
    if _encounter != null:
        title = "%s — %s" % [_encounter.slot, _encounter.display_name]
    var t := Widgets.label_as(title, "LabelObjective")
    t.custom_minimum_size = Vector2(500, 0)
    head.add_child(t)
    if _encounter != null:
        var line := Widgets.label_as(_encounter.comedy_line, "LabelSmall")
        line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        line.custom_minimum_size = Vector2(500, 0)
        head.add_child(line)


## Where the plate sits in a scene host of `host_size`, for a scene whose
## `marks` are `m`: the mark's `view` (RaidView's rows — `ARENA_OFFSET` when the
## scene has none), then shifted sideways so the fight band (`fight_band`) is
## centred in the column left of the readout, and clamped so no edge of the
## 1536x1024 plate ever shows. Static so a test can read it without a screen.
static func arena_view(m: Dictionary, host_size: Vector2) -> Vector2:
    var view := ARENA_OFFSET
    var mv = m.get("view", null)
    if mv is Array and mv.size() >= 2:
        view = Vector2(float(mv[0]), float(mv[1]))
    var band := fight_band(m)
    if band.size.x > 0.0:
        view.x = floorf(float(READOUT_X) * 0.5 - band.get_center().x)
    view.x = clampf(view.x, minf(0.0, host_size.x - PLATE.x), 0.0)
    view.y = clampf(view.y, minf(0.0, host_size.y - PLATE.y), 0.0)
    return view


## The band the party fights on, in PLATE pixels: every feet point of
## `marks.party.ranks`, grown upward by the tallest class figure and sideways
## by half the widest, both at the mark's `scale`, then `BAND_PAD` of air.
## An empty Rect2 for a scene with no party marks (every non-arena scene).
static func fight_band(m: Dictionary) -> Rect2:
    var party = m.get("party", null)
    if not (party is Dictionary):
        return Rect2()
    var ranks = party.get("ranks", null)
    if not (ranks is Array):
        return Rect2()
    var sc := float(party.get("scale", 1.0))
    var r := Rect2()
    var any := false
    for rank in ranks:
        if not (rank is Dictionary):
            continue
        var y := float(rank.get("y", 0))
        for x in rank.get("xs", []):
            var feet := Vector2(float(x), y)
            if any:
                r = r.expand(feet)
            else:
                r = Rect2(feet, Vector2.ZERO)
                any = true
    if not any:
        return Rect2()
    var fig := _figure_box()
    r = r.grow_individual(fig.x * sc * 0.5, fig.y * sc, fig.x * sc * 0.5, 0.0)
    return r.grow(BAND_PAD)


## The widest and tallest 1x frame among the figures canon's classes stand as
## (class_actors.json -> actors.json, the same two files SceneStage reads), so
## the band is sized by the strips that will actually be drawn on it and not by
## a number typed here.
static func _figure_box() -> Vector2:
    var classes = _json(SceneStage.CLASS_ACTORS).get("classes", {})
    var actors = _json(SceneStage.ACTOR_MANIFEST).get("actors", {})
    var box := Vector2.ZERO
    if not (classes is Dictionary) or not (actors is Dictionary):
        return box
    for key in classes:
        var c = classes[key]
        if not (c is Dictionary):
            continue
        var g = actors.get(String(c.get("actor", "")), null)
        if g is Dictionary:
            box.x = maxf(box.x, float(g.get("frame_w", 0)))
            box.y = maxf(box.y, float(g.get("frame_h", 0)))
    return box


static func _json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}


## The scrim over the arena outside the band and the band's rim — both
## host-local, both MOUSE_FILTER_IGNORE, added after the stage and before the
## readout so the panel and the title still draw over them. A scene with no
## band (or one whose band lies wholly outside the host) adds nothing. No
## caption: a sentence about where the party stands, over a band nobody stands
## on, was a screen admitting an unbuilt thing (LOOP C29).
func _frame_band(host: Control, m: Dictionary, view: Vector2) -> void:
    var band := fight_band(m)
    if band.size.x <= 0.0:
        return
    var r := Rect2(band.position + view, band.size).intersection(
        Rect2(Vector2.ZERO, host.size))
    if r.size.x <= 0.0 or r.size.y <= 0.0:
        return
    var scrim := Control.new()
    scrim.name = "BandScrim"
    scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    host.add_child(scrim)
    scrim.position = Vector2.ZERO
    scrim.size = host.size
    var tint := Color(Palette.GROUND_PAGE, BAND_SCRIM_ALPHA)
    var w := host.size.x
    var h := host.size.y
    var parts: Array = [
        Rect2(0.0, 0.0, w, r.position.y),
        Rect2(0.0, r.end.y, w, h - r.end.y),
        Rect2(0.0, r.position.y, r.position.x, r.size.y),
        Rect2(r.end.x, r.position.y, w - r.end.x, r.size.y),
    ]
    for part in parts:
        var c := ColorRect.new()
        c.color = tint
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        scrim.add_child(c)
        c.position = part.position
        c.size = part.size
    var rim := Panel.new()
    rim.name = "FightBand"
    rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var sb := StyleBoxFlat.new()
    sb.draw_center = false
    sb.border_color = Color(Palette.EDGE_BRONZE, BAND_RIM_ALPHA)
    sb.set_border_width_all(BAND_RIM_W)
    sb.set_corner_radius_all(3)
    rim.add_theme_stylebox_override("panel", sb)
    host.add_child(rim)
    rim.position = r.position
    rim.size = r.size
    # W7-PREP: the party stands here now, so the rim only says "this is what
    # the strip is editing" — shown while the strip has the focus, else hidden.
    rim.visible = false
    _rim = rim


## The viewport's focus moved to `node`: the band's rim shows while the focus
## is anywhere in the strip (a card's Bench, a bench tile, the pager) and
## hides the moment it leaves for the sidebar or the rail.
func _on_focus_changed(node: Control) -> void:
    if _rim == null or not is_instance_valid(_rim):
        return
    _rim.visible = (node != null and _strip != null and is_instance_valid(_strip)
        and _strip.is_ancestor_of(node))


## UI-16 / LOOP-09: the chalked party on the band, and a greyed seat on every
## mark nobody is chalked on. Rebuilt on every `_refresh` — the old figures
## are taken off the stage first (and forgotten by it: `add_actor` keeps its
## own list, and a freed sprite left in it would trip the next
## `apply_settings`), then `place_party` stands the new ones exactly as
## RaidView's `_stage()` does. Each figure is renamed by its raider's id so
## a test can read who is standing where.
func _place_party() -> void:
    if _stage == null or not is_instance_valid(_stage):
        return
    _clear_party()
    var layout := _party_layout()
    _party_sprites = _stage.place_party(layout)
    for id in _party_sprites:
        var spr = _party_sprites[id]
        if is_instance_valid(spr):
            spr.name = "Actor_%s" % String(id)
    _place_seats(layout.size())


func _clear_party() -> void:
    var list = _stage.get("_actors")
    for id in _party_sprites:
        var spr = _party_sprites[id]
        if not is_instance_valid(spr):
            continue
        if list is Array:
            (list as Array).erase(spr)
        # `add_actor` adds the contact shadow as the sibling directly before
        # the figure; it goes with it.
        var i: int = spr.get_index()
        if i > 0:
            var shadow: Node = _stage.get_child(i - 1)
            if String(shadow.name).begins_with("Shadow_"):
                _stage.remove_child(shadow)
                shadow.queue_free()
        _stage.remove_child(spr)
        spr.queue_free()
    _party_sprites = {}
    for s in _seats:
        if is_instance_valid(s):
            _stage.remove_child(s)
            s.queue_free()
    _seats = []


## The chalked party as an actor list, built the way `RaidView._party_layout`
## builds the fight's: the marks' ranks in order, tanks nearest the boss,
## healers furthest, each named by the figure canon's armour families assign
## to their class (`SceneStage.actor_for_class`); a class with no figure is
## skipped, never substituted. Empty until a scene ships party marks.
func _party_layout() -> Array:
    var out: Array = []
    var party = _marks.get("party", null)
    if not (party is Dictionary):
        return out
    var ranks = party.get("ranks", null)
    if not (ranks is Array) or ranks.is_empty():
        return out
    var sc := float(party.get("scale", 1.0))
    var flip := String(party.get("face", "right")) == "left"
    var db = _state.content if _state != null else null
    var ordered: Array = _chalked.duplicate()
    ordered.sort_custom(func(a, b) -> bool:
        return _formation_rank(a, db) < _formation_rank(b, db))
    var i := 0
    for rank in ranks:
        if not (rank is Dictionary):
            continue
        for x in rank.get("xs", []):
            if i >= ordered.size():
                break
            var r = ordered[i]
            i += 1
            var who := SceneStage.actor_for_class(r.class_key())
            if who.is_empty():
                continue
            out.append({"who": who, "pos": [x, rank.get("y", 0)], "id": String(r.id),
                "scale": sc, "flip": flip})
    return out


## Tanks nearest the boss, healers furthest from it (RaidView's rule).
static func _formation_rank(r, db) -> int:
    if db == null:
        return 2
    match r.role_group(db):
        Enums.RoleGroup.TANK:
            return 0
        Enums.RoleGroup.DPS:
            return 1
        Enums.RoleGroup.SUPPORT:
            return 2
        _:
            return 3


## A greyed seat on every mark from `taken` onward: the soft ellipse the
## figures cast as a contact shadow, alone, in the fallen figure's grey. Added
## before the party's figures so they draw under them.
func _place_seats(taken: int) -> void:
    var party = _marks.get("party", null)
    if not (party is Dictionary) or not ResourceLoader.exists(SceneStage.LIGHT_TEX):
        return
    var ranks = party.get("ranks", null)
    if not (ranks is Array):
        return
    var sc := float(party.get("scale", 1.0))
    var fw: float = _figure_box().x
    var tex: Texture2D = SceneStage.texture(SceneStage.LIGHT_TEX)
    if tex == null or fw <= 0.0:
        return
    var soft_w := float(tex.get_width())
    var grey: Color = SceneStage.party_state_style("downed")["tint"]
    var n := 0
    var first_figure := _first_figure_index()
    for rank in ranks:
        if not (rank is Dictionary):
            continue
        for x in rank.get("xs", []):
            var k := n
            n += 1
            if k < taken:
                continue
            var seat := Sprite2D.new()
            seat.name = "Seat_%d" % k
            seat.texture = tex
            seat.scale = Vector2(fw * sc * 1.15 / soft_w, fw * sc * 0.42 / soft_w)
            seat.position = Vector2(float(x), float(rank.get("y", 0))) + SEAT_LIFT
            seat.modulate = Color(grey.r, grey.g, grey.b, SEAT_ALPHA)
            _stage.add_child(seat)
            if first_figure >= 0:
                _stage.move_child(seat, first_figure)
                first_figure += 1
            _seats.append(seat)


## Where the party's figures (and their shadows) begin among the stage's
## children, or the vignette / overlay if there are none — the index a seat
## is inserted at so it sits under the figures and under the stage's own
## top layers. -1 when nothing of the kind is there (the seat goes last).
func _first_figure_index() -> int:
    for c in _stage.get_children():
        var nm := String(c.name)
        if nm.begins_with("Shadow_") or nm.begins_with("Actor_") \
                or nm == "Vignette" or nm == "Overlay":
            return c.get_index()
    return -1


## Concept 1's sidebar, with canon's content (00 §2.3, 10 §2 R3/R7/R8).
func _sidebar(host: Control) -> void:
    if host == null:
        return
    # G15 / TOWN-17: the column is a ScrollContainer the SCREEN builds inside
    # the kit's panel, so the panel's minimum never carries the column and the
    # rim stays at y=714 whatever the scale. At 100% everything fits and no
    # bar shows (a test does the arithmetic); at 150% the mission block
    # scrolls, with the bar inside the rim where it can be seen (LESSONS: a
    # bar the panel edge hides is no fix). The commit stays OUT of the scroll:
    # Depart and the way back are a footer the player never has to find.
    var col := Widgets.column(SIDEBAR_GAP)
    col.name = "SidebarCol"
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    col.size_flags_vertical = Control.SIZE_EXPAND_FILL
    host.add_child(col)
    var scroll := ScrollContainer.new()
    scroll.name = "SidebarScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = true
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    col.add_child(scroll)
    var info := Widgets.column(SIDEBAR_GAP)
    info.name = "SidebarInfo"
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(info)

    info.add_child(Widgets.label_as("Current Raid", "LabelSection"))

    # The mission card: the art well at the column's full width and two
    # one-line captions under it, each trimmed with an ellipsis past the
    # column (docs/13 §14: a caption never wraps) — one uncapped Label here
    # used to widen the whole column past the rim (LESSONS).
    var card := Widgets.panel("PanelCard", 0)
    card.clip_contents = true
    var cardcol := Widgets.column(0)
    var art := Cards.encounter_art(_encounter, SIDEBAR_ART)
    art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    cardcol.add_child(art)
    var tm := MarginContainer.new()
    tm.add_theme_constant_override("margin_left", 12)
    tm.add_theme_constant_override("margin_right", 12)
    tm.add_theme_constant_override("margin_top", 2)
    tm.add_theme_constant_override("margin_bottom", 4)
    var tbox := Widgets.column(0)
    var title := Widgets.label_as(
        _encounter.display_name if _encounter != null else "No mission chosen",
        "LabelSubject")
    title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    title.custom_minimum_size = Vector2(SIDEBAR_TEXT_W - 24, 0)
    tbox.add_child(title)
    # LOOP C24 (interim, W6): the encounter's display_name is its only name;
    # the kind ("Main Boss", "Trash") is never printed as one. The sub-line
    # carries the fight's facts instead — the enemy count and the rounds the
    # encounter is sized for, both the encounter's own numbers — until Q12a
    # rules whether a boss gets a creature name.
    var facts := ""
    if _encounter != null:
        var n: int = _encounter.enemies.size()
        facts = "%d %s  ·  about %d rounds" % [
            n, "enemy" if n == 1 else "enemies", int(_encounter.target_rounds)]
    var kind := Widgets.label_as(facts, "LabelMuted")
    kind.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    kind.custom_minimum_size = Vector2(SIDEBAR_TEXT_W - 24, 0)
    tbox.add_child(kind)
    tm.add_child(tbox)
    cardcol.add_child(tm)
    card.add_child(cardcol)
    info.add_child(card)

    # 10 §2 R3: the row is data-driven from the encounter's own loot slots,
    # never a fixed four — and exactly the drops there are (UI-14): a
    # one-drop notice shows one icon, not an icon and a hole, and a notice
    # with nothing says so in words, the board's own way.
    info.add_child(Widgets.label_as("Potential Rewards", "LabelLabel"))
    var n: int = 0
    if _encounter != null:
        n = _encounter.loot_slots.size()
    if n == 0:
        var none := Widgets.label_as("Nothing worth carrying.", "LabelMuted")
        none.name = "NoRewards"
        info.add_child(none)
    else:
        var rewards := Widgets.row(9)
        rewards.name = "Rewards"
        for i in n:
            rewards.add_child(Widgets.slot(
                Cards.loot_slot_icon(String(_encounter.loot_slots[i]))))
        info.add_child(rewards)

    _verdict_host = Widgets.column(0)
    _verdict_host.name = "VerdictHost"
    info.add_child(_verdict_host)

    # UI-18: four faces and a "+N" tile — five 56px cells at a 6px gap is
    # 304, inside the 306 the scrolling block may claim (the G15 arithmetic
    # above).
    info.add_child(Widgets.label_as("Raid Team", "LabelLabelLg"))
    _team_host = Widgets.row(6)
    _team_host.name = "TeamRow"
    info.add_child(_team_host)

    # docs/13 §3: the one commit control. 10 §2 R7 — departing costs no gold,
    # so the sub-line inside the plate reports the party instead of inventing
    # a price. The button itself is built by `_rebuild_depart` on every
    # refresh, inside the kit's one "disabled with reason" treatment
    # (CRITIC-G06).
    _depart_host = Widgets.column(0)
    _depart_host.name = "DepartHost"
    col.add_child(_depart_host)

    var back := Widgets.button("Back to the board")
    back.pressed.connect(func() -> void:
        if _router != null:
            _router.goto(BOARD))
    col.add_child(back)


## docs/11 §7's commit point, made visible: "Pre-raid consumables are chosen at the
## raid-confirm screen and are only *spent* as the attempt begins. Doc 01 §6.2 says
## cancelling at confirm is free; that must stay true."
##
## So this panel chalks a selection and takes nothing. Walking away with the Back
## button costs the player exactly nothing, which a test asserts.
##
## WHERE IT LIVES (G15 / TOWN-17): on the strip, in the 474x262 slot the hub
## screens give the event log (`Cards.event_log`'s own rect — this screen has
## no log there). In the sidebar it was the block whose height depended on the
## cupboard, and the block that pushed Depart under the rim at 150%; here a
## full cupboard flows into a second row and the sidebar's commit stays put.
## Rebuilt with the strip on every refresh (the strip is cleared whole).
func _provisions_panel() -> Control:
    var panel := Widgets.panel("PanelRound", 14)
    panel.name = "Provisions"
    panel.clip_contents = true
    _provisions = Widgets.column(3)
    _provisions.name = "ProvisionsCol"
    _provisions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    Widgets.content_of(panel).add_child(_provisions)
    return panel


func _refresh_provisions() -> void:
    if _provisions == null:
        return
    for c in _provisions.get_children():
        _provisions.remove_child(c)
        c.queue_free()
    if _state == null:
        return

    _provisions.add_child(Widgets.section("Provisions"))
    var cupboard: Array = _cupboard()
    if cupboard.is_empty():
        # G15: this sentence was the one uncapped Label in the sidebar (386px
        # at 100%), and one is enough to widen the whole column (LESSONS).
        _provisions.add_child(_wrapped(Widgets.faint(
            "The cupboard is bare. The Market sells provisions.")))
        return

    # The buttons flow to a second row rather than widening the column.
    var row := HFlowContainer.new()
    row.add_theme_constant_override("h_separation", 8)
    row.add_theme_constant_override("v_separation", 4)
    for entry in cupboard:
        row.add_child(_provision_button(entry))
    _provisions.add_child(row)

    _provisions.add_child(_wrapped(_loadout_line()))
    if not _provision_notice.is_empty():
        var why := Widgets.faint(_provision_notice)
        why.add_theme_color_override("font_color", Palette.CAUTION)
        _provisions.add_child(_wrapped(why))


## A provisions line that wraps at the panel's width (docs/13 §14 wraps prose;
## a line wider than its column used to push the sidebar's rim to x=1536).
static func _wrapped(l: Label) -> Label:
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size = Vector2(PROVISIONS_TEXT_W, 0)
    return l


## Everything held that can be taken on a raid, newest tier first so the best is the
## easiest to reach. docs/11 §7's Rally Flask is excluded: it is a post-wipe purchase.
func _cupboard() -> Array:
    var out: Array = []
    for key in _state.consumables:
        var sku_id := Consumables.sku_of_key(String(key))
        if Consumables.kind_of(sku_id) == Consumables.Kind.POST_WIPE:
            continue
        out.append({
            "key": String(key), "sku": sku_id,
            "tier": Consumables.tier_of_key(String(key)),
            "held": int(_state.consumables[key]),
        })
    out.sort_custom(func(a, b): return int(a["tier"]) > int(b["tier"]))
    return out


func _provision_button(entry: Dictionary) -> Control:
    var sku_id := String(entry["sku"])
    var tier := int(entry["tier"])
    var held := int(entry["held"])
    var chosen: int = _state.chosen_count(sku_id, tier)
    var label := "%s  %d/%d" % [
        Consumables.display_name(sku_id, tier), chosen, held]
    var b := Widgets.button(label)
    # UI-39 / m4t-04: the provision's own icon, the Market shelf's
    # (`Icons.at("item", sku)`), in the Button's leading slot — the text stays
    # verbatim, because the tests press these by their fragment.
    b.icon = Icons.at("item", sku_id)
    b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.expand_icon = false
    b.add_theme_font_size_override("font_size", Type.at(Widgets.SIZE_META, Theme_.scale_of(self)))
    if chosen > 0:
        b.add_theme_color_override("font_color", Palette.POSITIVE)
    b.pressed.connect(func() -> void:
        # Steady Hands is bought for a named raider; the lowest-morale member of the
        # chalked group is who the player is worrying about, so that is the default.
        var target := ""
        if String(Consumables.sku(sku_id).get("target", "")) == "one":
            target = _weakest_chalked_id()
        _provision_notice = _state.choose_consumable(sku_id, tier, target)
        _refresh())
    return b


## The chalked raider most likely to make a mistake, which is who a Potion of Steady
## Hands is for. docs/11 §7 prices it against the canon Steve decision by name.
func _weakest_chalked_id() -> String:
    var worst = null
    for r in _chalked:
        if worst == null or r.morale < worst.morale:
            worst = r
    return String(worst.id) if worst != null else ""


## What the committed loadout will actually do, in the sim's own numbers — so the
## player can see they are buying +1 Power rather than a vibe.
func _loadout_line() -> Label:
    var loadout: Dictionary = _state.build_loadout(_chalked)
    if Consumables.loadout_is_empty(loadout):
        return Widgets.faint(
            "    Nothing chalked. Provisions are only spent when the raid leaves.")
    var parts: Array = []
    if int(loadout["power_bonus"]) > 0:
        parts.append("+%d Power to the melee" % int(loadout["power_bonus"]))
    if int(loadout["mana_bonus"]) > 0:
        parts.append("+%d Mana to the casters" % int(loadout["mana_bonus"]))
    if int(loadout["morale_bonus"]) > 0:
        parts.append("fought at morale +%d" % int(loadout["morale_bonus"]))
    var relief: Dictionary = loadout["mistake_relief_bp"]
    for raider_id in relief:
        var who = _state.raider(String(raider_id))
        parts.append("%s steadier by %.0f points" % [
            who.display_name if who != null else "someone",
            float(relief[raider_id]) / 100.0])
    if int(loadout["potion_count"]) > 0:
        parts.append("%d potion%s, drunk below %d%% HP" % [
            int(loadout["potion_count"]),
            "" if int(loadout["potion_count"]) == 1 else "s",
            int(Consumables.POTION_TRIGGER_FRACTION * 100.0)])
    var line := Widgets.body("    " + "  ·  ".join(PackedStringArray(parts)))
    line.add_theme_color_override("font_color", Palette.POSITIVE)
    return line


# ---------------------------------------------------------------- rows

func _is_chalked(r) -> bool:
    for c in _chalked:
        if c.id == r.id:
            return true
    return false


## docs/13 §12.4: `ui.chalk` on a ChalkSlot fill or clear, "leading edge of the
## stroke" — so it plays here, before the redraw, on both branches. A chalk
## refused at the cap is not a fill; it is the other bad-chalk gesture, and
## gets the squeak (`ui.chalk_bad`) instead, at once.
func _toggle(raider_id: String) -> void:
    if _is_chalked_id(raider_id):
        for i in _chalked.size():
            if _chalked[i].id == raider_id:
                _chalked.remove_at(i)
                break
        _play("ui.chalk")
    else:
        if _chalked.size() >= _party_cap():
            _play("ui.chalk_bad")
            return
        var r = _state.raider(raider_id) if _state != null else null
        if r != null:
            _chalked.append(r)
            _play("ui.chalk")
    _refresh()


## The one door to the mixer on this screen. `Services.find`, never the global
## identifier (BUILD_STATE invariant 7); null-safe so a test that mounts the
## screen without the autoload still gets a screen.
func _play(hook: String) -> void:
    var audio: Node = Services.find(self, "Audio")
    if audio != null:
        audio.play(hook)


## `ui.chalk_bad` for the comp check turning invalid: §12.4 puts it
## `CHALK_BAD_DELAY_MS` after the slot redraw, so it rides a tree timer from
## the refresh that redrew the slots. Off-tree — the test runner, which never
## draws a frame and has no tree to time on — the press is recorded at once,
## and the test reads the constant instead of a wait it could never observe.
func _chalk_bad_later() -> void:
    var tree: SceneTree = get_tree() if is_inside_tree() else null
    if tree == null:
        _play("ui.chalk_bad")
        return
    tree.create_timer(float(CHALK_BAD_DELAY_MS) / 1000.0).timeout.connect(
        _play.bind("ui.chalk_bad"))


func _is_chalked_id(raider_id: String) -> bool:
    for c in _chalked:
        if c.id == raider_id:
            return true
    return false


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
    if _strip == null:
        _refresh_provisions()
        return
    for c in _strip.get_children():
        _strip.remove_child(c)
        c.queue_free()
    for host in [_readout, _verdict_host, _team_host]:
        if host == null:
            continue
        for c in host.get_children():
            host.remove_child(c)
            c.queue_free()

    var bench: Array = []
    for r in (_state.roster if _state != null else []):
        if not _is_chalked(r):
            bench.append(r)
    bench.sort_custom(func(a, b) -> bool: return a.morale < b.morale)

    # The bench is the mini-grid and tonight's party are the cards; both keep
    # the reference's shapes while the counts stay canon's (10 §2 R1). The
    # strip pages itself (KIT-12: its gutter arrows, never over a card) and the
    # bench pads to its seats (KIT-08).
    if _state != null:
        var pages := Cards.roster_strip(_strip, _state, _page, {
            "cards": _chalked, "available": bench,
            "available_label": "Bench",
            "seats": BENCH_SEATS,
            "card_action": func(r) -> void: _toggle(String(r.id)),
            "card_action_text": "Bench",
            "grid_action": func(r) -> void: _toggle(String(r.id)),
            "on_page": func(p: int) -> void: _page = p,
        })
        _page = clampi(_page, 0, pages - 1)
        if _chalked.is_empty():
            _strip_empty(bench.is_empty())

    # docs/11 §7's provisions, in the strip's log slot (see _provisions_panel).
    var prov := _provisions_panel()
    _strip.add_child(prov)
    prov.position = PROVISIONS_POS
    prov.size = PROVISIONS_SIZE
    _refresh_provisions()

    # The Raid Team portraits are the first of tonight's party; the rest are
    # a "+N" tile (UI-18) that turns the strip to the first card the row
    # does not show, so twelve never reads as four.
    if _team_host != null:
        for i in mini(TEAM_FACES, _chalked.size()):
            _team_host.add_child(Widgets.slot(Cards.portrait_for(_chalked[i]),
                Widgets.PORTRAIT_SLOT, "SlotBronze"))
        var more: int = _chalked.size() - TEAM_FACES
        if more > 0:
            _team_host.add_child(_more_tile(more))

    # UI-16: the party on the band.
    _place_party()

    _build_readout()

    # The cards and the Depart box are new nodes on every refresh, and the
    # shell wires the keyboard ring once, at entry (ScreenRouter). Re-run it
    # the way Cards._turn_page does — idempotent, and nothing before the shell
    # has published its hook.
    if has_meta(Frame.META_FOCUS_ORDER):
        var cb = get_meta(Frame.META_FOCUS_ORDER)
        if cb is Callable and (cb as Callable).is_valid():
            (cb as Callable).call()


## UI-18: the fifth Raid Team tile, "+N" for the chalked raiders the row's
## faces do not show. Pressing it turns the strip to the page holding the
## first of them (card TEAM_FACES, zero-based), where the cards say who they
## are; the text is the tile's own so the walker reads "+8".
func _more_tile(more: int) -> Button:
    var t := Widgets.slot_button("+%d" % more, null, Widgets.PORTRAIT_SLOT)
    t.name = "MoreTile"
    t.theme_type_variation = "ButtonMini"
    t.tooltip_text = "%d more on the strip" % more
    t.pressed.connect(func() -> void:
        _page = int(floor(float(TEAM_FACES) / float(Cards.PAGE)))
        _refresh())
    return t


## KIT-08: with nothing chalked the card band is 875px of nothing, so it says
## why under the kit's bench glyph, and where the raiders are. One line each —
## `Widgets.empty_state` hangs its hint under a single line of text.
func _strip_empty(no_roster: bool) -> void:
    var text := "No one is chalked."
    var hint := "Press a face on the bench to chalk them."
    if no_roster:
        text = "No raiders to chalk."
        hint = "The Tavern has candidates."
    var e := Widgets.empty_state(text, Icons.at("empty", "bench"), hint)
    e.name = "StripEmpty"
    e.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _strip.add_child(e)
    var x0 := float(Widgets.CARD_X0 - 13)
    e.position = Vector2(x0, 0)
    e.size = Vector2(float(Cards.PAGER_NEXT_X) - x0, float(Widgets.STRIP_H))


## docs/13 §10.2's four things, none of them behind an interaction.
func _build_readout() -> void:
    var db = _state.content if _state != null else null
    var a := RaidPlan.analyse(_chalked, db, _encounter)

    # docs/13 §12.4: `ui.chalk_bad` when the comp check TURNS invalid — the
    # two HARD rows (slots and tanks; healers are only recommended). A
    # transition, never a state: a comp that opens invalid, or stays invalid
    # across a chalk, squeaks nothing. `_toggle` already plays the stroke.
    var now_ok: bool = (int(a["slots_filled"]) >= int(a["slots_required"])
        and float(a["tank_weight"]) >= float(a["tanks_required"]))
    if _comp_seen and _comp_ok and not now_ok:
        _chalk_bad_later()
    _comp_ok = now_ok
    _comp_seen = true

    _line(Widgets.section("Comp check"))
    _line(Widgets.body("Slots %d / %d"
        % [a["slots_filled"], a["slots_required"]]))
    _line(Widgets.body("Tanks %.0f / %d required"
        % [a["tank_weight"], a["tanks_required"]]))
    _line(Widgets.body("Healers %d / %d recommended"
        % [a["healers"], a["healers_recommended"]]))
    _line(Widgets.meta("DPS %d  ·  Support %d"
        % [a["dps"], a["support"]]))

    _readout.add_child(Widgets.rule())
    _line(Widgets.section("Gear"))
    _line(Widgets.body("%s %d / %d slots"
        % [a["gear_label"], a["gear_filled"], a["gear_visible"]]))
    _line(Widgets.meta("AC %d  ·  Damage %d  ·  Mana %d"
        % [a["sum_ac"], a["sum_damage"], a["sum_mana"]]))

    # 10 §2 R8 / LOOP-08: the verdict word drives the band, the same way
    # morale does — the callout's plate and the hatch's stripes read one tone.
    var band := 80
    match String(a["verdict"]):
        "Reckless", "Suicidal":
            band = 10
        "Risky", "Dicey":
            band = 45

    _readout.add_child(Widgets.rule())
    _line(Widgets.section("Predicted risk"))
    # A word AND a hatch density, never colour alone (docs/13 §10.3). The
    # hatch is drawn (UI-17) and is the verdict's own meter; the band word is
    # its caption. The per-encounter figure is the block's second line.
    _readout.add_child(_hatch_row(float(a["risk_fill"]), String(a["risk_word"]), band))
    _line(Widgets.body("Expected mistakes  ~%.1f / encounter"
        % a["expected_mistakes"]))
    _line(Widgets.faint("Baseline at this comp      %.1f"
        % a["baseline_mistakes"]))

    var contributors: Array = a["contributors"]
    if not contributors.is_empty():
        _line(Widgets.meta("Biggest contributors"))
        for c in contributors:
            _line(Widgets.faint("  %s   %s   %s   +%.1f"
                % [c["name"], c["class_name"], c["state"], c["excess"]]))

    _readout.add_child(Widgets.rule())
    var verdict := Widgets.section("Verdict: %s" % a["verdict"])
    if String(a["verdict"]) in ["Reckless", "Suicidal"]:
        verdict.add_theme_color_override("font_color", Palette.DANGER)
    _line(verdict)
    for w in a["warnings"]:
        _line(Widgets.faint("• " + String(w)))

    # 10 §2 R8 / LOOP-08: the reference's percentage has no canon source, so
    # the callout carries ONE word and ONE number — the verdict, and the
    # delta that drove it: expected less the same comp at Content, signed, in
    # mistakes ("+14.1 mistakes" / "over a content guild"). The per-encounter
    # total stays in the readout, where its baseline sits under it.
    if _verdict_host != null:
        var delta := float(a["risk_delta"])
        var callout := Widgets.callout(String(a["verdict"]),
            "%s mistakes" % String(a["risk_delta_text"]), band)
        # G15: the figure is the widest thing in the sidebar and at 150% it
        # ran past the rim; it wraps to a second line there instead (the kit's
        # column is `get_child(0)`, the AdventureBoard reads it the same way).
        var figure = _figure_of(callout)
        if figure != null:
            figure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var against := Widgets.label_as(
            "over a content guild" if delta >= 0.0 else "under a content guild",
            "LabelSmall")
        against.name = "Against"
        against.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        callout.get_child(0).add_child(against)
        _verdict_host.add_child(callout)

    # docs/13 §10.4 / docs/06 §6.6 — warn loudly, always allow departure.
    _rebuild_depart()


## UI-17: the drawn hatch and its caption on one row — the `RiskHatch` at
## HATCH_SIZE (`fill` = RaidPlan.risk_fill, stripes in the verdict band's
## tone) and the band word as a meta Label beside it, so the word survives in
## text for the tests and the greyscale reading both. The row is named so a
## test can find it; the hatch inside it is "RiskHatch".
func _hatch_row(fill: float, word: String, band: int) -> HBoxContainer:
    var row := Widgets.row(10)
    row.name = "RiskRow"
    row.alignment = BoxContainer.ALIGNMENT_BEGIN
    var hatch := RiskHatch.new()
    hatch.name = "RiskHatch"
    hatch.fill = fill
    hatch.tone = Palette.band_color(band)
    hatch.track = Color(Palette.TEXT_MUTED, HATCH_TRACK_ALPHA)
    hatch.custom_minimum_size = HATCH_SIZE
    hatch.size = HATCH_SIZE
    hatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    hatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(hatch)
    var caption := Widgets.meta(word)
    caption.name = "RiskWord"
    caption.add_theme_color_override("font_color",
        Palette.DANGER if word == "SEVERE" else Palette.TEXT_MUTED)
    row.add_child(caption)
    return row


## One readout line: wrapped at the column's width, never trimmed (docs/13
## §4.4 reflows by rows; §10.2's numbers may not be cut). Returns the Label.
func _line(l: Label) -> Label:
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size = Vector2(READOUT_TEXT_W, 0)
    _readout.add_child(l)
    return l


## The callout's big figure Label (the kit's LabelFigure inside its column),
## or null for a plate shaped some other way.
static func _figure_of(callout: Control) -> Label:
    if callout.get_child_count() == 0:
        return null
    for c in callout.get_child(0).get_children():
        if c is Label and (c as Label).theme_type_variation == "LabelFigure":
            return c
    return null


## Why Depart is shut, or "" when the raid can leave. Never the comp — docs/06
## §6.6: "Penalties teach; locks do not." Only "nowhere to go" and "nobody to
## send" shut it, and each says so beside the button.
func _depart_reason() -> String:
    if _encounter == null:
        return "No mission chosen. Pick one on the board."
    if _chalked.is_empty():
        return "Chalk at least one raider."
    return ""


## The crimson commit (docs/13 §3; `Widgets.cta` is the CTA chrome, and its
## sub-line INSIDE the plate is 10 §2 R7's "N of M chalked" — the party, since
## departing costs no gold), inside the kit's one "disabled with reason"
## treatment (CRITIC-G06): `Widgets.reasoned` dims it, puts the padlock in its
## leading slot and prints the reason as ONE LabelSmall directly under it — a
## Label, so the tests and the keyboard both reach it. Rebuilt whole on every
## refresh because the box is built around an unparented control and the
## sub-line changes with every chalk.
func _rebuild_depart() -> void:
    if _depart_host == null:
        return
    for c in _depart_host.get_children():
        _depart_host.remove_child(c)
        c.queue_free()
    _depart = Widgets.cta("Depart", "%d of %d chalked" % [_chalked.size(), _party_cap()])
    _depart.pressed.connect(_on_depart)
    _depart_host.add_child(Widgets.reasoned(_depart, _depart_reason(), null,
        SIDEBAR_TEXT_W))


func _on_depart() -> void:
    if _state == null or _router == null or _encounter == null:
        return
    if _chalked.is_empty():
        return
    # docs/13 §12.4: `ui.page_turn` on Departure, "start of the turn" — the
    # press itself, before the sim runs (§12.1's 80 ms: the ear hears the page
    # go at once). The desk does not move (§2 M5), so the sound IS the turn.
    # The attempt's Day Tick inside `record_attempt` rings `ui.ledger_close`
    # through Audio's own subscription in the same frame; both are the doc's
    # events and both are once per raid.
    _play("ui.page_turn")
    var seed_value: int = _state.next_raid_seed()
    # docs/11 §7's commit point: the loadout is resolved and the cupboard is opened
    # HERE, as the attempt begins, and not one screen earlier.
    var loadout: Dictionary = _state.build_loadout(_chalked)
    var result = RaidSim.run(_chalked, _encounter, _state.content, seed_value,
        loadout)
    _state.spend_loadout(result.potions_spent, result.consumables_unspent)
    # Hand the party along: loot rolls and the Suggested split are computed
    # against the raiders who actually went (docs/15 BL-32, BL-33).
    _state.record_attempt(_encounter.id, result, _chalked)
    # Depart lands on the ACCOUNT, not the report: docs/13 §11 is where the raid
    # is actually experienced, and Results is the filed paperwork afterwards.
    # If that screen is missing, go straight to the report rather than nowhere.
    if _router.screen_exists(RAID_VIEW):
        _router.goto(RAID_VIEW)
    else:
        _router.goto(RESULTS)


## Test seam: the chalked twelve this screen would depart with.
func chalked_ids() -> Array:
    var out: Array = []
    for r in _chalked:
        out.append(r.id)
    return out
