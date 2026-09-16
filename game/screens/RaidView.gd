extends Control
## S11 — the raid, watched (docs/13 §11), on Concept 2's frame.
##
## docs/13 opens §11 with the constraint that shapes everything here: *"The
## player is watching, not playing. This screen either carries the comedy or
## wastes it."* The sim finished before this screen opened (docs/15 Q-09 rules
## out mid-raid input), so this is a scribe's account being read back, and the
## only decisions available are how fast and how much detail. The pacing lives
## in `game/core/LogPlayer.gd` so it can be tested; this file is the stage the
## account is read on.
##
## The art pass puts that reading on Concept 2 (art/ref/specs/02): no rail and
## no chips — the arena full-bleed, the compact wordmark and an objective block
## top-left, the boss's HP plate top-centre, and along the bottom four combatant
## panels paged over the party beside the combat log. Every coordinate below is
## one 02 measured.
##
## Where the reference invents data canon does not have, it is not drawn
## (00 §2, 10 §2 R4/R5): there are no levels unless a raider carries one, no
## rage/mana bar, no ability grid (the cells show GEAR), no minimap. The HP bars
## are folded from the log's own `numbers.hp_after`, entry by entry, as the
## account is revealed — so at any moment they show exactly what has been read.

const Widgets = preload("res://game/ui/Widgets.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Cards = preload("res://game/ui/Cards.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Services = preload("res://game/core/Services.gd")
const LogPlayer = preload("res://game/core/LogPlayer.gd")
const Enums = preload("res://sim/model/Enums.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")
const Reputation = preload("res://sim/core/Reputation.gd")

const RESULTS := "res://game/screens/Results.tscn"
const BOARD := "res://game/screens/AdventureBoard.tscn"
const ICON := "res://game/assets/ui/icons/"
const PORTRAIT := "res://game/assets/portraits/"
const ENEMIES := "res://game/assets/enemies/"

# ---- 02's measured geometry -------------------------------------------------
const FRAME := Vector2(1536, 1024)
const STAGE_H := 735                          ## 02 §7: the scene is everything above the strip
const PLATE_AT := Vector2(0, 0)               ## the stage sits on the ground, full-bleed (02 §1)
## Which 735 rows of the 1536x1024 arena plate the stage shows when the scene
## carries no `marks.view` of its own. Both arena scenes do (W1-STAGE: the
## blocking lives in the JSON beside the plate it was measured on, read through
## `SceneStage.marks`), so this is the fallback for a scene that ships none.
## See `_stage()`.
const ARENA_OFFSET := Vector2(0, -280)

## spec 09 §4.3 row 5: the twelve combatants, as sprites on the arena floor.
##
## FALLBACK formation, in PLATE coordinates, used only when the arena scene's
## `marks.party` is absent. The shipped blocking is the scene's own — STAGE-01:
## the cave's twelve stand at 2x on the lower-left lantern floor (ranks y
## 692/654/616) facing the boss across the bridge — and it is data so that the
## fight moves with the plate, not with this file. These numbers are the
## pre-W1-STAGE plateau row (front edge y 418, x stopping short of the boss
## plate's chrome at 931), kept so a scene with no marks still gets a party.
##
## Rank order is the formation either way: tanks first, into the rank NEAREST
## the boss, then dps, then support, then healers at the back of the room. That
## is the shape docs/06 §6.5's comp check already describes in words, drawn.
const PARTY_RANKS := [
	{"y": 374, "xs": [630, 692, 754, 816]},
	{"y": 394, "xs": [660, 722, 784, 846]},
	{"y": 414, "xs": [630, 692, 754, 816]},
]

## spec 09 §4.3 row 4: where the enemy stands, in PLATE coordinates, when the
## scene's `marks.boss` is absent (the fallback beside PARTY_RANKS). The cave's
## mark puts it on the lower-right railed ledge, feet (1210, 800), facing the
## party across the bridge; this is the old right-gallery x.
const BOSS_X := 1190

## The boss's feet are computed from its own height, not fixed, because the
## sliced creatures run 77px to 152px tall. Two constraints, both hard:
##   - its head must clear the boss PLATE, which is chrome at screen y 53..118
##     (plate 333..398) across x 931..1315 — a creature with its head behind its
##     own HP bar reads as a bug, the same way a raider's would;
##   - its feet must land on the measured stone, plate y 481..556.
## So: feet = 404 + height, clamped into the stone. `404` is the first plate row
## whose screen y (124) is clear of the plate's bottom edge with a 6px margin.
const BOSS_HEAD_CLEAR := 404
const BOSS_FEET_RANGE := Vector2(481, 556)


## Where a creature of this height stands, in plate rows. Static so the rule
## can be tested without mounting the screen, for either arena.
##
## With a scene mark (both arenas): the mark's feet point, pushed down only if
## the creature's head (at the mark's boss scale) would otherwise rise past the
## chrome clearance — the boss plate's bottom edge in plate rows plus 6px of
## air — and always kept inside the mark's `floor` rect, the stone it may stand
## on. Without a mark: the old rule, feet = BOSS_HEAD_CLEAR + height clamped
## into BOSS_FEET_RANGE.
static func boss_feet_y(height: int, scene: String = SceneStage.DEFAULT_ARENA) -> float:
	var m := SceneStage.marks(scene)
	var boss = m.get("boss", null)
	if not (boss is Dictionary):
		return clampf(BOSS_HEAD_CLEAR + float(height), BOSS_FEET_RANGE.x, BOSS_FEET_RANGE.y)
	var view_y := ARENA_OFFSET.y
	var view = m.get("view", null)
	if view is Array and view.size() >= 2:
		view_y = float(view[1])
	var pos: Array = boss.get("pos", [BOSS_X, BOSS_FEET_RANGE.y])
	var sc := float(boss.get("scale", 1.0))
	var clear := BOSS_PLATE.position.y + BOSS_PLATE.size.y - view_y + 6.0
	var feet := maxf(float(pos[1]), clear + float(height) * sc)
	var floor_rect: Array = boss.get("floor", [])
	if floor_rect.size() >= 4:
		feet = clampf(feet, float(floor_rect[1]), float(floor_rect[1]) + float(floor_rect[3]))
	return feet
const HEADER_W := 352                         ## 02 §4.1: header plate 0,0,352,64
const HEADER_H := 64
const OBJECTIVE := Rect2(0, 88, 352, 106)     ## 02 §4.2
const BAR_Y := 675                            ## 02 §8: the control row, just above the strip
const BAR_H := 45
const SKIP_REASON_H := 22                     ## the skip button's reason line, above it (COMBAT-04)
const SKIP_W := 152                           ## the skip button with its padlock (COMBAT-04)
const BOSS_PLATE := Rect2(931, 53, 384, 65)   ## 02 §3.1
const BOSS_SIGIL := Rect2(943, 61, 48, 48)    ## 02 §3.2
const BOSS_BAR := Rect2(999, 85, 299, 24)     ## 02 §3.4
const STRIP_Y := 735                          ## 02 §0: strip plate 0,735,1536,289
const PANEL_Y := 741                          ## 02 §1.1
const PANEL_SIZE := Vector2(232, 240)
const PANEL_X0 := 23
const PANEL_PITCH := 254
const PANELS_PER_PAGE := 4
const LOG_RECT := Rect2(1044, 741, 474, 240)  ## 02 §2, aligned to the panels
const PAGER_Y := 988                          ## the strip's bottom band, under the panels (KIT-12)
const FOOTER_Y := 675                         ## 02 §8: the button row above the strip
## The two exits, sized so "Back to the board" and "The report" still fit
## at text_scale 150 (CRITIC-G15); 02 §8 measured 1150/1356 at 100.
const EXIT_BACK_X := 1108
const EXIT_ONWARD_X := 1330
## COMBAT-13's status row: panel-local, in the band 02 §1 leaves between the HP
## row (y 97..114) and the gear grid (y 149).
const STATUS_ROW := Rect2(38, 121, 182, 26)
const STATUS_GLYPH := 22
const BLOT_PITCH := 14
const LOG_AGE_ALPHA := 0.75                   ## spec 02 §2.2: rows older than the two newest
## W6-LOG (UI-19, UI-35, CONTENT-15, LOOP-11 — CRITIC-C2's one rule): every
## row of the live log is a whole number of `Type.LOG_ROW_PITCH`es tall and the
## scroll shows a whole number of them, so the scroll snaps by rows and the
## fold never slices a line. An ordinary row is one pitch and clips as spec 02
## §2.1 says; a MISTAKE is a header that leads with the type and wraps to a
## second pitch only if its words need one (never an ellipsis through the
## mistake's name), then its quote on up to QUOTE_LINES lines — a corpus line
## the column cannot hold in two takes a third (never cut) — at a fixed two
## pitches, so a mistake is three pitches and the account keeps its rhythm.
const HEADER_LINES := 2
const QUOTE_LINES := 2
const QUOTE_LINES_MAX := 3
const QUOTE_INDENT := 30
const LOG_VISIBLE_ROWS := 7                   ## 7 x 29 = 203 of the panel's 224 inner px

## 10 §2 R4: the strip follows the log to the page holding the newest actor,
## with a hold so it does not flicker between pages, and a manual arrow press
## keeps its page for a while before the log takes over again.
const PAGE_HOLD := 1.5
const MANUAL_HOLD := 6.0

var _router = null
var _state = null
var _player = null
var _built := false
var _settings = null
var _db = null
var _encounter = null
var _party: Array = []
var _stage_node = null
## The boss as `stage.place_boss` hands it back — a Node2D, never narrower: it
## is a Sprite2D today and W3-ENEMIES makes it an AnimatedSprite2D; every use
## here is through the stage's verbs and `modulate`, which both carry.
var _boss_sprite: Node2D = null
var _party_sprites: Dictionary = {}   ## raider id -> AnimatedSprite2D on the floor
## Raider id -> the screen clock at which its death act ends (the stage lerps
## the grey over that act; the fold's refresh leaves the tint alone until then).
var _dying: Dictionary = {}
## The boss has already toppled (its bar reached zero once this read).
var _boss_fallen := false

var _log_col: VBoxContainer = null
var _scroll: ScrollContainer = null
var _speed_button: Button = null
var _pause_button: Button = null
## CRITIC-G13: the "PAUSED — mistake" stamp the manual-advance dwell raises,
## built on the first dwell; `_dwelling` is true from that pause until the
## player resumes, so a pause the player chose does not wear the mistake's word.
var _paused_stamp: Label = null
var _dwelling := false
## COMBAT-14's exits and, under EXITS_GATED, the reasoned boxes holding them.
var _back_button: Button = null
var _onward_button: Button = null
var _exit_boxes: Array = []
var _exits_gated := false
var _tier_buttons: Dictionary = {}
var _mistake_counter: Label = null
var _round_label: Label = null
var _boss_bar: Control = null
var _panel_host: Control = null
var _panel_bars: Dictionary = {}     ## raider id -> Bar
var _panel_states: Dictionary = {}   ## raider id -> Label
var _panel_nodes: Dictionary = {}    ## raider id -> the panel
var _panel_glyphs: Dictionary = {}   ## raider id -> the status row's state glyph (COMBAT-13)
var _panel_blots: Dictionary = {}    ## raider id -> the status row's blot host (COMBAT-09)
var _mech_cells: Dictionary = {}     ## mechanic key -> the boss plate's affix cell (COMBAT-16)
var _raider_by_id: Dictionary = {}   ## raider id -> the Raider, for the overlays
var _page_label: Label = null
var _page := 0
var _page_hold := 0.0
var _manual_hold := 0.0

## COMBAT-16 / CRITIC-G08: the per-line UI-layer effects. `_lit_panel_id` is
## whose panel wears the actor rim; `_lit` holds every modulate lift (a sprite's
## 1.15 brighten, a mechanic cell, the boss's one-frame flash, a struck figure's
## flash) with the clock at which `_process` puts it back; `_effect_round` is
## the round the effects last fired in, for the once-per-round coalescing at 2x.
var _lit_panel_id := ""
var _lit: Array = []                 ## [{node, until, id}]
var _effect_round := -1
var _clock := 0.0
## Q07 (00-plan §0.6): the figures wearing a full over-head HP bar right now —
## the acting and the struck one; everyone else carries badge + pips only.
var _bar_ids: Array = []
## COMBAT-06's age ramp: the log's rows, oldest first; only the two newest are
## at full opacity.
var _log_rows: Array = []
## True while the account is being read live (`LogPlayer.advance`); false
## during `_on_skip()`'s `reveal_all`, where numbers and bubbles would be two
## hundred labels landing in one frame and the effects are off by G08's rule.
var _live := true
## Frames until `_on_skip`'s scroll-to-end runs (the column lays out first).
var _scroll_pending := 0
## The log's follow (docs/13 §11.1): `_stick` is true while the reader is
## riding the bottom of the log — set when a line lands with them there, cleared
## when they drag away — and while it is true every change of the scrollbar's
## range re-pins the view to the newest line. `_follow_queued` coalesces the
## deferred follow to one per frame however many lines land in it.
var _stick := false
var _follow_queued := false

var _tier: int = Enums.LogTier.PLAY_BY_PLAY
var _mistakes_seen: int = 0
## docs/13 §11.4's sequence, as its own table: each beat's documented offset in
## MILLISECONDS, in the doc's own order. The code below fires each once when the
## clock passes it, rather than awaiting — `_on_skip()` must be able to abort
## mid-sequence, because §11.4 says the whole thing is "fully skippable on any
## input" and an `await` chain cannot be interrupted.
##
## SIX BEATS, FIVE HERE (COMBAT-21 / RULES-04 — this block is the provenance):
##   * the 400ms INK BLEED at t=900 is `game/assets/ui/wipe_blot.png` and the
##     WAX SEAL at t=1,400 is `game/assets/ui/wax_seal.png`, both generated by
##     `tools/aseprite/gen_wipe.lua` (sources under art/src/ui/, re-authored by
##     W1-CHROME: a hard DANGER core with a dithered fibre edge; a bronze-lipped
##     seal with the emblem's silhouette) and checked byte-for-byte by
##     `tools/build_art.sh --check`. `_bleed_under()` and `_drop_seal()` place
##     them; test_wipe_sequence.gd asserts both paths resolve.
##   * t=1,800's "post-mortem sheet slides out from under" is the S12 Results
##     screen arriving, i.e. a SCREEN TRANSITION, and this project has none
##     (audit M6-JUICE-02; 00-plan Q09 holds `TRANSITION_MS = 0`). Doing it here
##     would mean building a second, private transition on one screen. The beat
##     waits on that ruling and the exits become active at t=2,400 as §11.4 asks.
const WIPE_BEAT_SILENCE_MS := 0
const WIPE_BEAT_LINE_MS := 400
const WIPE_BEAT_STAMP_MS := 900
const WIPE_BEAT_DIM_MS := 1400
const WIPE_BEAT_EXITS_MS := 2400

## §11.4's press: "180ms, 1.15 -> 1.00 scale, -7 degree rotation".
const WIPE_STAMP_MS := 180
const WIPE_STAMP_FROM := 1.15
const WIPE_STAMP_TILT_DEG := -7.0
## docs/13 §13's carve-out, in full: "Stamps still land (they carry state) but at
## 60ms with no rotation." So the press keeps a floor and loses its tilt, and
## `GameSettings.motion_duration()` is what applies both.
const WIPE_STAMP_FLOOR_MS := 60
## §11.4: "Page dims 12%".
const WIPE_DIM = 0.12

## §11.4's "400ms ink bleed into the paper fibre", and its texture.
const WIPE_BLEED_MS := 400
const WIPE_BLOT := "res://game/assets/ui/wipe_blot.png"
## The seal that drops "onto the lower-right corner" at t=1,400 — of the PAGE,
## which is the log panel (COMBAT-15): its rest straddles the panel's lower-right
## corner, the 72px seal's centre on the panel's bottom edge (LOG_RECT's 981)
## and its right edge 6px inside the panel's. Both of test_wipe_sequence's
## "right and low" checks (past half the frame on each axis) hold here.
const WAX_SEAL := "res://game/assets/ui/wax_seal.png"
const WAX_SEAL_REST := Vector2(1440, 946)
## Where the stamp presses: ACROSS THE LOG PANEL — the document the account was
## written on (docs/13 §11.4 "presses diagonally across the page"; COMBAT-15),
## not the arena. The rect is the panel's width, 40px under its top edge, so the
## box lands over the rows and the cost line fits beneath it inside the panel.
const WIPE_STAMP_RECT := Rect2(1044, 781, 474, 90)

## Q12c (00-plan §0.6, COMBAT-14): whether the two exits are locked while the
## account is still being read. `false` = docs/13 §11.4's reading (the result
## is already recorded; leaving costs nothing); `true` = docs/01 §9's — both
## exits disabled with EXITS_REASON as their Label until `is_finished()`, then
## released. The designer flips this; the code behind it is built and tested.
const EXITS_GATED := false
const EXITS_REASON := "The account is still being read"

## BL-141 (Q15 as ruled): on a tutorial slot ONE static `Widgets.callout` band
## sits above the log carrying the record's own `lesson` — never a literal
## here, so the writing pass owns the words (LOOP-30 / UI-55 / CRITIC-C3). No
## round timing and nothing persisted: the band is the lesson, the log is the
## proof. `false` is the recorded alternative (the Board's notice alone).
const TUTORIAL_BAND := true
## Where the band sits: the log's width, above the exit row (675) with a gap,
## over the arena's lower-right floor — the one strip of the stage no chrome
## and no figure uses (the boss stands left of x 1250, the party far left).
const LESSON_BAND_RECT := Rect2(1044, 594, 474, 70)

## BL-119: when the encounter carries a `title` ("The Doorman") the boss
## plate's title slot prints it and the canon ladder words drop to a subtitle
## ("Tutorial Raid · Main Boss") — the plate keeps 02 §3.1's 65px, so the HP
## bar steps down to this rect to make the second line's room. Without a
## title the plate is exactly what it was (`BOSS_BAR`).
const BOSS_BAR_TITLED := Rect2(999, 94, 299, 20)

## The stamp `log_manual_advance`'s dwell raises on the log panel (CRITIC-G13):
## its top-RIGHT corner (this is where the stamp's right edge goes, 12px inside
## the panel's), so the newest row — the mistake the account stopped on — stays
## readable under it.
const PAUSED_STAMP_AT := Vector2(1506, 745)

## spec 02 §9.2's affix row: 30px cells at pitch 34 from x 1001 (COMBAT-05).
const BOSS_AFFIX_CELL := 30
const BOSS_AFFIX_PITCH := 34

## STAGE-03 / STAGE-09 / PIPE-02: which stage verbs a line fires, per the
## actor's ROLE. PIPE-02 asks the designer for one attack family and one
## support family per CLASS (00-plan Q18); until that ruling this table is the
## role-based default it recommends — melee roles slash, casters and the
## healers bolt, everyone's heal is the sparkle — keyed by `Enums.ROLE_KEYS`.
## `attack`: "slash" (the arc strip over the target + a burst of `kind`) or
## "bolt" (the bolt strip from the actor to the target, landing a burst of
## `kind`). `support`: the burst kind a HEAL line lands on its target. A role
## missing from the table is treated as melee. The boss (no actor id) is
## BOSS_FAMILY: a burst on the struck raider and its recoil, nothing in its
## hands to slash with.
const VFX_FAMILY := {
	"main_tank": {"attack": "slash", "kind": "impact", "support": "heal"},
	"melee_dps_offtank": {"attack": "slash", "kind": "impact", "support": "heal"},
	"melee_dps": {"attack": "slash", "kind": "impact", "support": "heal"},
	"main_tank_healer": {"attack": "bolt", "kind": "arcane", "support": "heal"},
	"raid_healer": {"attack": "bolt", "kind": "arcane", "support": "heal"},
	"chain_healer": {"attack": "bolt", "kind": "arcane", "support": "heal"},
	"support": {"attack": "bolt", "kind": "arcane", "support": "heal"},
	"aoe_caster": {"attack": "bolt", "kind": "fire", "support": "heal"},
	"single_target_caster": {"attack": "bolt", "kind": "arcane", "support": "heal"},
}
const BOSS_FAMILY := {"attack": "burst", "kind": "impact", "support": "heal"}
## The burst a MECHANIC line lands at the boss's eye (spec 02 §3.5 paints the
## mechanic cells in the void family).
const MECHANIC_BURST := "void"

var _wipe_timer: float = 0.0
var _wipe_shown: bool = false
## Which beats have fired, so a beat cannot land twice when the clock is advanced
## in uneven deltas.
var _wipe_beats: Dictionary = {}
var _wipe_stamp_label: Label = null
var _retry_button: Button = null
var _wipe_dim: ColorRect = null
var _wipe_blot: TextureRect = null
var _wax_seal: TextureRect = null
var _finished_ui := false
var _last_row_round := -1
## LOOP-12: the log row of the sim's `wipe_cause` line ("It traces back to
## …"), kept so the wipe's final-line beat can bring the same entry the
## report's sentence names into view. Null on a clear or a loss nobody caused.
var _cause_row: Control = null

## The HP fold (10 §2 R5): the full Play-by-play stream, consumed up to the
## sequence number of whatever line was last revealed, whatever tier is shown.
var _full: Array = []
var _fold_index := 0
var _raider_hp: Dictionary = {}
var _raider_max: Dictionary = {}
var _raider_state: Dictionary = {}
## COMBAT-09: MISTAKE entries folded per actor — the ink each raider has spilt
## this attempt. Read by the panel's status row, the log row's margin blot and
## the pips over the figure's head.
var _raider_blots: Dictionary = {}
var _enemy_hp: Dictionary = {}
var _enemy_max := 0
var _round := 0

## docs/01 §9 (that doc's OQ#1 ruling, which governs): Instant and skip-to-result
## are "unlocked per encounter after first clear of that encounter". 1x/2x/4x and
## pause stay always available. Read ONCE at build time, before this attempt is
## recorded, or clearing an encounter would unlock skipping the very run that
## cleared it.
var _skip_unlocked := false


func _ready() -> void:
	build()


func build() -> void:
	if _built:
		return
	_built = true
	_router = Services.router(self)
	_state = Services.state(self)
	_settings = Services.find(self, "GameSettings")
	_skip_unlocked = _resolve_skip_unlocked()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Theme_.current(self)
	_resolve_data()
	_build()


## The attempt being read has ALREADY been recorded by the time this screen
## opens, so a first clear would have set `cleared` and unlocked skipping its own
## reveal. Subtract this attempt: skipping is unlocked only if the encounter had
## been cleared BEFORE it.
func _resolve_skip_unlocked() -> bool:
	if _state == null or _state.last_result == null:
		return false
	var enc_id: String = _state.last_result.encounter_id
	var clears: int = _state.clear_count(enc_id)
	if _state.last_result.cleared():
		clears -= 1
	return clears > 0


func _resolve_data() -> void:
	if _state == null:
		return
	_db = _state.content
	if _state.last_result != null and _db != null:
		_encounter = _db.encounter(_state.last_result.encounter_id)
	# The party that went (GameState.record_attempt keeps it), or, for an older
	# save that did not, whoever the result still names.
	_party = _state.last_party.duplicate() if not _state.last_party.is_empty() else []
	if _party.is_empty() and _state.last_result != null:
		for c in _state.last_result.survivors + _state.last_result.casualties:
			if c != null and c.raider != null:
				_party.append(c.raider)
	_raider_by_id.clear()
	for r in _party:
		_raider_by_id[String(r.id)] = r


# ---------------------------------------------------------------- the frame

func _build() -> void:
	add_child(Widgets.ground())
	_stage()
	_header()
	_objective()
	_controls()
	_boss_plate()
	_footer()
	_strip()
	_lesson_band()
	_reset_player()


## UI-33 / CRITIC-R4: where the keyboard lands on this screen — Pause, the one
## control a watching player needs (docs/13 §11: "the player is watching, not
## playing"). The router's `initial_focus_target()` asks for this by name;
## without it focus opened on the fast-forward chevron, the first button in
## tree order.
func default_focus() -> Control:
	return _pause_button


## SHIP-03's Esc rule (the attempts ruling, RULINGS §2 #6): while the account
## is still being read, Esc is THIS screen's — it means "skip to the
## post-mortem", never "pop the account" (the attempt is already recorded;
## leaving mid-read only leaves the report unread). The router defers to this
## by name; once the account has finished the answer is false and Esc is the
## router's again.
func handles_cancel() -> bool:
	return _player != null and not _player.is_finished()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if not handles_cancel():
		return
	_on_skip()
	if is_inside_tree():
		get_viewport().set_input_as_handled()


## BL-141: the tutorial's lesson, said where it happens — one static
## `Widgets.callout` band above the log, on a tutorial slot only, carrying the
## record's `lesson` verbatim. The callout's figure slot is empty by design (a
## lesson is a sentence, not a number) and dropped so the band is one Label
## the tests read; the headline wraps to the log's width. Nothing here is a
## literal: an encounter with no `lesson` gets no band.
func _lesson_band() -> void:
	if not TUTORIAL_BAND or _encounter == null:
		return
	if not Reputation.is_tutorial_slot(String(_encounter.slot)):
		return
	var lesson := String(_encounter.lesson)
	if lesson.is_empty():
		return
	var band := Widgets.callout(lesson, "", 100)
	band.name = "LessonBand"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col: Node = band.get_child(0)
	if col != null and col.get_child_count() >= 2:
		var fig: Node = col.get_child(1)
		col.remove_child(fig)
		fig.queue_free()
	if col != null and col.get_child_count() >= 1 and col.get_child(0) is Label:
		var l := col.get_child(0) as Label
		l.name = "Lesson"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		l.custom_minimum_size = Vector2(LESSON_BAND_RECT.size.x - 32, 0)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The Board's shape for a callout carrying a sentence: the column goes into
	# a padded margin so the rim clears the words.
	if col != null:
		var pad := MarginContainer.new()
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side in ["left", "right", "top", "bottom"]:
			pad.add_theme_constant_override("margin_" + side, 8)
		band.remove_child(col)
		pad.add_child(col)
		band.add_child(pad)
		band.move_child(pad, 0)
	add_child(band)
	band.position = LESSON_BAND_RECT.position
	band.size = LESSON_BAND_RECT.size


## 02 §7: no framed stage panel — the arena sits on the ground at 1:1 and the
## chrome floats over it.
##
## The 2026-09-11 directive: the BARE arena plate, with its lantern flames, its
## crystal light and its motes animating, instead of `arena_stage.png` — a crop
## of Concept 2 with a boss, two damage numbers and a row of label pills painted
## into it. This is the screen that watches a fight resolve, so a backdrop
## carrying somebody else's frozen fight was the worst place for it.
##
## The stage is 1536x735 of visible ground (the strip starts at STRIP_Y), and
## the scene's `marks.view` picks WHICH 735 rows: plate y 280..1015 is the arena
## half of the cave — the lantern floor, the rope bridge over the chasm, the
## railed ledge, the lower pool — rather than the ceiling. No dim: unlike raid
## prep, here the arena is the picture, and every chrome block that sits on it
## (the objective, the boss plate, the control row) carries its own 0.86 panel.
##
## The blocking — where the twelve stand, where the boss stands, at what scale,
## facing which way — is the scene's `marks` (STAGE-01), read here and nowhere
## else on this screen; `ARENA_OFFSET`, `PARTY_RANKS` and `BOSS_X` are the
## fallbacks for a scene that ships none.
func _stage() -> void:
	var arena := SceneStage.arena_for(_encounter)
	var stage := SceneStage.load(arena)
	var m := SceneStage.marks(arena)
	var view := ARENA_OFFSET
	var mv = m.get("view", null)
	if mv is Array and mv.size() >= 2:
		view = Vector2(float(mv[0]), float(mv[1]))
	stage.position = PLATE_AT + view
	stage.size = Vector2(FRAME.x, STAGE_H) - view
	add_child(stage)
	# spec 09 §4.3 row 5. The arena scenes ship `actors: []` on purpose — a scene
	# file cannot know which twelve departed — so the party is placed by the
	# SCREEN, through the stage, so that it gets the same contact shadows, phase
	# spread and reduced-motion switch as any other crowd in the game.
	_stage_node = stage
	_party_sprites = stage.place_party(_party_layout())
	# spec 09 §4.3 row 4. The same creature the boss plate's sigil and the
	# board's notice card show, so the thing on the floor and the thing in the
	# chrome are one enemy. Its feet point, scale and facing are the mark's.
	var boss_tex := _boss_sigil()
	if boss_tex != null:
		var bx := float(BOSS_X)
		var opts := {}
		var boss = m.get("boss", null)
		if boss is Dictionary:
			var pos: Array = boss.get("pos", [BOSS_X, 0])
			bx = float(pos[0])
			opts = {"flip": bool(boss.get("flip", false)), "scale": float(boss.get("scale", 1.0))}
		_boss_sprite = stage.place_boss(boss_tex,
			Vector2(bx, boss_feet_y(boss_tex.get_height())), opts)


## The departing party as an actor list: whoever went, in formation, each named
## by the figure canon's armour families assign to their class (docs/15 BL-68).
## A class with no figure is skipped rather than substituted — a cleric sprite
## standing in for a class nobody mapped would be a quiet lie about the roster.
##
## The formation, the figure scale and the facing come from the scene's
## `marks.party` (STAGE-01/02: the sliced strips face right, so `face: "right"`
## is no flip); `PARTY_RANKS` at 1x is the fallback for a scene without marks.
func _party_layout() -> Array:
	var ordered: Array = _party.duplicate()
	ordered.sort_custom(func(a, b) -> bool: return _formation_rank(a) < _formation_rank(b))
	var ranks: Array = PARTY_RANKS
	var sc := 1.0
	var flip := false
	var party = SceneStage.marks(SceneStage.arena_for(_encounter)).get("party", null)
	if party is Dictionary:
		var mr = party.get("ranks", null)
		if mr is Array and not mr.is_empty():
			ranks = mr
		sc = float(party.get("scale", 1.0))
		flip = String(party.get("face", "right")) == "left"
	var out: Array = []
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


## Tanks nearest the boss, healers furthest from it.
func _formation_rank(r) -> int:
	var cd = _db.class_of(r.class_id) if _db != null else null
	if cd == null:
		return 2
	match cd.role_group:
		Enums.RoleGroup.TANK:
			return 0
		Enums.RoleGroup.DPS:
			return 1
		Enums.RoleGroup.SUPPORT:
			return 2
		_:
			return 3


## 02 §4.1: emblem + the compact wordmark on a short plate, nothing else. The
## lockup is Frame's "33_compact" (COMBAT-12): the 65px skull crop at (22,12)
## and wordmark_33 at x 96, baseline 48, so the whole mark ends inside the
## 352px plate instead of running 20px past it onto the cave.
func _header() -> void:
	var plate := ColorRect.new()
	plate.color = Palette.GROUND_FRAME
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	plate.position = Vector2.ZERO
	plate.size = Vector2(HEADER_W, HEADER_H)
	_hairline(Vector2(0, HEADER_H), HEADER_W, Palette.EDGE_RAIL)
	Frame.draw_lockup(self, "33_compact")


## 02 §4.2: the objective block — the encounter as the title, then the two
## numbers the player is actually watching: mistakes and the round.
func _objective() -> void:
	var plate := ColorRect.new()
	plate.color = Color(Palette.SURFACE_PANEL, 0.86)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	plate.position = OBJECTIVE.position
	plate.size = OBJECTIVE.size
	_hairline(OBJECTIVE.position, OBJECTIVE.size.x, Palette.EDGE_RAIL)
	_hairline(OBJECTIVE.position + Vector2(0, OBJECTIVE.size.y), OBJECTIVE.size.x,
		Palette.EDGE_SLATE_LIGHT)

	var glyph := TextureRect.new()
	glyph.texture = load(ICON + "nav_missions.png")
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	glyph.modulate = Palette.ACCENT_GOLD
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glyph)
	glyph.position = Vector2(14, 96)
	glyph.size = Vector2(32, 32)

	var title := "The attempt"
	if _encounter != null:
		title = "%s — %s" % [_encounter.slot, _encounter.display_name]
	var t := Widgets.label_as(title, "LabelObjective")
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(t)
	t.position = Vector2(57, 98)
	t.size = Vector2(OBJECTIVE.size.x - 57 - 12, 28)
	# W5-SCALE: the plate is the concept's 352 at every text scale, so above
	# 100 the title steps its size down a pixel at a time until it fits its
	# 283 — never below the 100% size, never an ellipsis through an
	# encounter's name (docs/13 §14). Measured: 293px at 125, 351 at 150
	# (tests/unit/test_text_scale_layout.gd).
	var pct: int = Theme_.scale_of(self)
	if pct != Type.SCALE_DEFAULT:
		var tf: Font = Frame._theme_font(self, "LabelObjective")
		var px: int = Type.at(Type.OBJECTIVE, pct)
		while px > Type.OBJECTIVE \
				and tf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > t.size.x:
			px -= 1
		t.add_theme_font_size_override("font_size", px)
	_hairline(Vector2(16, 130), OBJECTIVE.size.x - 32, Palette.EDGE_SLATE)

	# "increments instantly, no tween" (docs/13 §11.3).
	_mistake_counter = Widgets.label_as("Mistakes this attempt  0", "LabelBody")
	add_child(_mistake_counter)
	_mistake_counter.position = Vector2(50, 138)

	_round_label = Widgets.label_as("Round 0", "LabelSmall")
	add_child(_round_label)
	_round_label.position = Vector2(62, 166)


## docs/13 §11.1: three visible verbosity buttons, defaulting to Play-by-play
## (Debug is dev-build only, so it is not offered), then the pacing controls.
## 02 §8 puts the reference's cog and fast-forward pair bottom-left of the
## stage, just above the strip; our whole bar sits on that row — the chevrons
## are the speed, then pause, skip, and the three tiers — so nothing floats
## over the fight itself.
func _controls() -> void:
	# CRITIC-G15: the slots below were measured at 100%; the type on the buttons
	# scales with `text_scale` (`_bar_button`), so the slots scale with it, and
	# `_place_in_bar` reads each button's real width back so a word that still
	# outgrows its slot moves the next button along instead of being painted
	# over ("Play-by-pla" under "Numbers" at 150 — review F1).
	var s := float(Theme_.scale_of(self)) / 100.0
	var x := 4.0
	_speed_button = _bar_button("1x", load(ICON + "fast_forward_24.png"))
	_speed_button.tooltip_text = "Speed — 1x, 2x, 4x"
	_speed_button.pressed.connect(func() -> void:
		_player.cycle_speed()
		_sync_controls())
	x = _place_in_bar(_speed_button, x, 86.0 * s)

	_pause_button = _bar_button("Pause")
	_pause_button.pressed.connect(func() -> void:
		_player.toggle_pause()
		_sync_controls())
	x = _place_in_bar(_pause_button, x, 84.0 * s)

	# docs/01 §9's gate, with docs/13 §7's requirement that a locked control
	# states its reason as text: the kit's one disabled-with-reason treatment
	# (COMBAT-04, CRITIC-G06) — the button dimmed with the padlock, the sentence
	# its "Reason" Label. The Reason is moved ABOVE the button because the
	# control row sits 15px over the strip plate and a line under it would be
	# cut; the box is bottom-aligned so the button stays on the row either way.
	var skip := _bar_button("Skip to the end")
	skip.name = "Skip"
	skip.custom_minimum_size = Vector2(SKIP_W * s, BAR_H)
	# The reason line is wider than the button; the button keeps its own width
	# at the box's left rather than stretching under the sentence.
	skip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if _skip_unlocked:
		skip.pressed.connect(_on_skip)
	var reason := "" if _skip_unlocked else "Unlocks once you have cleared this one."
	# The padlock only while it IS locked: the kit puts the glyph on the button
	# before it looks at the reason, so an unlocked skip handed the lock would
	# wear it enabled (review F2).
	var lock: Texture2D = null if _skip_unlocked else Icons.at("lock", "16")
	var skip_box := Widgets.reasoned(skip, reason, lock)
	skip_box.alignment = BoxContainer.ALIGNMENT_END
	var why := skip_box.get_node_or_null("Reason")
	if why != null:
		skip_box.move_child(why, 0)
	add_child(skip_box)
	skip_box.size = Vector2(SKIP_W * s, BAR_H + SKIP_REASON_H)
	# `size` clamps to the box's minimum (the reason line is taller at 150), so
	# the bottom edge is pinned to the row's and the box grows upward.
	skip_box.position = Vector2(x, BAR_Y + BAR_H - skip_box.size.y)
	x += maxf(SKIP_W * s, skip.get_combined_minimum_size().x) + 6.0

	x += 14.0 * s
	for tier in [Enums.LogTier.STORY, Enums.LogTier.PLAY_BY_PLAY,
			Enums.LogTier.NUMBERS]:
		var b := _bar_button(Enums.LOG_TIER_NAMES[tier])
		var t: int = tier
		b.pressed.connect(func() -> void: _set_tier(t))
		_tier_buttons[tier] = b
		x = _place_in_bar(b, x, (64.0 if tier != Enums.LogTier.PLAY_BY_PLAY else 108.0) * s)


## 02 §8's button: chamfered near-black plate, bronze edge, small type.
func _bar_button(text: String, icon: Texture2D = null) -> Button:
	var b := Widgets.icon_button(text, icon)
	b.add_theme_font_size_override("font_size", Type.at(Type.SMALL, Theme_.scale_of(self)))
	return b


## Place a bar button in its slot and hand back the next slot's x. A Control
## clamps `size` to its minimum, so the width read back is the width drawn: a
## word wider than its slot pushes the next slot along rather than under it.
func _place_in_bar(b: Button, x: float, w: float) -> float:
	add_child(b)
	b.position = Vector2(x, BAR_Y)
	b.size = Vector2(w, BAR_H)
	var drawn := maxf(w, maxf(b.size.x, b.get_combined_minimum_size().x))
	return x + drawn + 6.0


## 02 §3: the boss health plate, top-centre over the boss's half of the stage.
## The HP is the encounter's whole roster of enemies (canon's thousands, not
## the reference's 120,000 — 00 §2.3), folded from the log as it is read.
func _boss_plate() -> void:
	if _encounter == null:
		return
	var plate := Widgets.panel("PanelCard", 0)
	add_child(plate)
	plate.position = BOSS_PLATE.position
	plate.size = BOSS_PLATE.size

	# 02 §3.2's sigil: a bare 48px family glyph per boss rank (W1-ICONS'
	# `sigil_<rank>` through the one lookup — COMBAT-05), never the whole body
	# shrunk into the slot; the body is the fallback for a rank with no glyph.
	var rank := _boss_rank_key()
	var glyph: Texture2D = (Icons.at("sigil", rank) if not rank.is_empty()
		and Icons.exists("sigil", rank) else _boss_sigil())
	var sigil := Widgets.slot(glyph, int(BOSS_SIGIL.size.x), "SlotAbility")
	sigil.name = "BossSigil"
	sigil.tooltip_text = _encounter.display_name
	add_child(sigil)
	sigil.position = BOSS_SIGIL.position
	sigil.size = BOSS_SIGIL.size

	# BL-119 (Q12a as ruled): the title slot prints the rung's role `title`
	# when the record carries one ("The Doorman"), with the canon ladder words
	# and the kind as the subtitle underneath ("Tutorial Raid · Main Boss");
	# with no title the plate prints `display_name` exactly as it always has.
	# The enemies' log names are content's placeholders either way.
	var title := String(_encounter.title)
	var titled := not title.is_empty()
	var name_l := Widgets.label_as(title if titled else _encounter.display_name, "LabelBossName")
	name_l.name = "BossTitle"
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(name_l)
	name_l.position = Vector2(1001, 55 if titled else 57)
	name_l.size = Vector2(BOSS_BAR.size.x - 4, 24 if titled else 26)
	var bar_rect := BOSS_BAR
	if titled:
		var sub := Widgets.label_as("%s · %s" % [_encounter.display_name,
			Enums.encounter_kind_name_of(int(_encounter.kind))], "LabelSmall")
		sub.name = "BossSubtitle"
		sub.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		sub.clip_text = true
		sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sub)
		sub.position = Vector2(1001, 76)
		sub.size = Vector2(BOSS_BAR.size.x - 4, 16)
		bar_rect = BOSS_BAR_TITLED

	_boss_bar = Widgets.bar(0, 1, "boss", "", Vector2i(bar_rect.size))
	add_child(_boss_bar)
	_boss_bar.position = bar_rect.position
	_boss_bar.size = bar_rect.size

	# 02 §3.5: the reference's four affix icons are the encounter's mechanics,
	# one cell each at §9.2's measured 30px and pitch 34 (W1-ICONS' mech_<key>
	# plate through the one lookup), the mechanic's name as the tooltip. Kept by
	# key so a MECHANIC line can light the cell that fired (COMBAT-16).
	var i := 0
	_mech_cells.clear()
	for spec in _encounter.mechanics:
		var key := _mechanic_key(spec)
		var icon: Texture2D = Icons.at("mech", key) if Icons.exists("mech", key) else null
		var cell := Widgets.slot(icon, BOSS_AFFIX_CELL, "SlotAbility")
		cell.tooltip_text = spec.name_of()
		add_child(cell)
		cell.position = Vector2(1001 + BOSS_AFFIX_PITCH * i, 122)
		cell.size = Vector2(BOSS_AFFIX_CELL, BOSS_AFFIX_CELL)
		if not _mech_cells.has(key):
			_mech_cells[key] = cell
		i += 1


## The rank key the sigil grid is named by (`boss_main`, `boss_mini_2`, …):
## read off the encounter sprite's own file name, so the one rule that picks
## a creature for an encounter (`Cards.encounter_sprite`) is not copied here.
func _boss_rank_key() -> String:
	var tex := _boss_sigil()
	if tex == null:
		return ""
	return String(tex.resource_path).get_file().get_basename()


## Enums.Mechanic's own key, lower-cased, is the icon's name: TANK_SWAP ->
## mech_tank_swap.png.
func _mechanic_key(spec) -> String:
	var kind := int(spec.mechanic)
	if kind < 0 or kind >= Enums.Mechanic.size():
		return ""
	return String(Enums.Mechanic.keys()[kind]).to_lower()


## The boss sprite that stands for this encounter (shared with the board and
## prep so the same creature is on every screen).
func _boss_sigil() -> Texture2D:
	return Cards.encounter_sprite(_encounter)


## 02 §8 puts a button pair just above the strip; ours are the two ways out.
func _footer() -> void:
	var back := Widgets.button("Back to the board")
	back.pressed.connect(func() -> void:
		if _router != null:
			_router.goto(BOARD))
	add_child(back)
	back.position = Vector2(EXIT_BACK_X, FOOTER_Y)
	back.size = Vector2(EXIT_ONWARD_X - 8 - EXIT_BACK_X, 45)
	# §11.4's beat at t=2,400 gives this one the focus, so the sequence needs a
	# handle on it.
	_retry_button = back
	_back_button = back

	# The commit control: reading the account is done, take the consequences.
	var onward := Widgets.wax_button("The report")
	onward.pressed.connect(func() -> void:
		if _router != null:
			_router.goto(RESULTS))
	add_child(onward)
	onward.position = Vector2(EXIT_ONWARD_X, FOOTER_Y)
	onward.size = Vector2(FRAME.x - 16 - EXIT_ONWARD_X, 45)
	_onward_button = onward
	if EXITS_GATED:
		_gate_exits()


## COMBAT-14 (behind EXITS_GATED, Q12c): lock both exits until the account has
## been read, each in the kit's one disabled-with-reason treatment — the button
## dimmed, EXITS_REASON its "Reason" Label (docs/13 §7: a locked control states
## its reason as text, never a tooltip). The reason sits ABOVE the button for
## the same reason the skip's does: the row is 15px over the strip plate. The
## buttons keep their own geometry inside the boxes. Callable after `_footer`
## (a test seam as much as the switch's door); `_release_exits` undoes it.
func _gate_exits() -> void:
	if _exits_gated:
		return
	_exits_gated = true
	for b in [_back_button, _onward_button]:
		if b == null or not is_instance_valid(b) or b.get_parent() != self:
			continue
		var at: Vector2 = b.position
		var sz: Vector2 = b.size
		remove_child(b)
		b.custom_minimum_size = sz
		var box := Widgets.reasoned(b, EXITS_REASON)
		box.name = "Gate"
		box.alignment = BoxContainer.ALIGNMENT_END
		var why: Node = box.get_node_or_null("Reason")
		if why != null:
			box.move_child(why, 0)
		add_child(box)
		box.size = Vector2(sz.x, sz.y + SKIP_REASON_H)
		box.position = Vector2(at.x, at.y + sz.y - box.size.y)
		_exit_boxes.append(box)


## The account is read (or skipped): the exits become active, as §11.4's
## t=2,400 beat says. A no-op unless `_gate_exits` ran.
func _release_exits() -> void:
	if not _exits_gated:
		return
	_exits_gated = false
	for box in _exit_boxes:
		if not is_instance_valid(box):
			continue
		var b: Button = Widgets.button_of(box)
		if b != null:
			b.disabled = false
			b.modulate = Color.WHITE
		var why: Node = (box as Control).get_node_or_null("Reason")
		if why is CanvasItem:
			(why as CanvasItem).visible = false
	_exit_boxes = []


# ---------------------------------------------------------------- the strip

## 02 §0/§1: a full-width plate carrying four combatant panels and the log.
func _strip() -> void:
	var plate := ColorRect.new()
	plate.color = Palette.GROUND_FRAME
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	plate.position = Vector2(0, STRIP_Y)
	plate.size = Vector2(FRAME.x, FRAME.y - STRIP_Y)
	var edge := ColorRect.new()
	edge.color = Palette.EDGE_RAIL
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge)
	edge.position = Vector2(0, STRIP_Y + 1)
	edge.size = Vector2(FRAME.x, 2)

	_panel_host = Control.new()
	_panel_host.name = "Combatants"
	_panel_host.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_panel_host)
	_panel_host.position = Vector2(0, PANEL_Y)
	_panel_host.size = Vector2(LOG_RECT.position.x, FRAME.y - PANEL_Y)

	_combat_log()
	_pager()
	_build_panels()


## 02 §2: the combat log, most recent last, autoscrolled — LOG_VISIBLE_ROWS
## whole rows (UI-35: the panel's 224 inner px held 7.7 pitches, so the
## auto-scroll's end sliced the top row through its glyphs; the scroll is now
## exactly seven pitches tall and the 21px left over is air under the last
## line, so its end lands on a row boundary by arithmetic — every row is a
## whole number of pitches, see HEADER_LINES).
func _combat_log() -> void:
	var panel := Widgets.panel("PanelRound", 0)
	panel.clip_contents = true
	add_child(panel)
	panel.position = LOG_RECT.position
	panel.size = LOG_RECT.size
	var body := Control.new()
	panel.add_child(body)

	_log_col = Widgets.column(0)
	_log_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.add_child(_log_col)
	body.add_child(_scroll)
	_scroll.position = Vector2(8, 8)
	_scroll.size = Vector2(LOG_RECT.size.x - 16, Widgets.LOG_ROW_PITCH * LOG_VISIBLE_ROWS)
	# The follow rides the scrollbar's own signals (see `_autoscroll`): the
	# range grows a deferred measurement after a row lands, whatever frame
	# pacing the caller has — one line a frame, or two hundred in one.
	var bar := _scroll.get_v_scroll_bar()
	if bar != null:
		bar.changed.connect(_on_log_range_changed)
		bar.value_changed.connect(_on_log_value_changed)


## 10 §2 R4: the pager for a party larger than four panels — the kit's
## captioned row (KIT-12: `‹ caption ›`, arrows named PagerPrev/PagerNext) in
## the strip's empty bottom band under the panels, so it never shares pixels
## with a card. With one page there is nothing to say and nothing drawn.
func _pager() -> void:
	if _pages() <= 1:
		return
	var row := Widgets.pager(_page, _pages(),
		func() -> void: _turn_page(-1),
		func() -> void: _turn_page(1), " ")
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(row)
	row.position = Vector2(PANEL_X0, PAGER_Y)
	row.size = Vector2(PANEL_PITCH * PANELS_PER_PAGE - 22, 28)
	_page_label = row.get_node_or_null("PageCaption") as Label


func _pages() -> int:
	return maxi(1, int(ceil(float(_party.size()) / float(PANELS_PER_PAGE))))


func _turn_page(delta: int) -> void:
	var pages := _pages()
	_page = (_page + delta + pages) % pages
	_manual_hold = MANUAL_HOLD
	_build_panels()


## The four panels of the current page. Rebuilt on a page turn; the bars they
## hold are refreshed from the fold every time a line lands.
func _build_panels() -> void:
	for c in _panel_host.get_children():
		_panel_host.remove_child(c)
		c.queue_free()
	_panel_bars.clear()
	_panel_states.clear()
	_panel_nodes.clear()
	_panel_glyphs.clear()
	_panel_blots.clear()

	if _party.is_empty():
		var why := Widgets.empty_state("Nobody went. Depart from the board to run an attempt.")
		_panel_host.add_child(why)
		why.position = Vector2(PANEL_X0, 8)
		why.size = Vector2(PANEL_PITCH * PANELS_PER_PAGE - 22, 40)
		return

	var pages := _pages()
	_page = clampi(_page, 0, pages - 1)
	for i in PANELS_PER_PAGE:
		var idx: int = _page * PANELS_PER_PAGE + i
		if idx >= _party.size():
			break
		var panel := _combatant_panel(_party[idx])
		_panel_host.add_child(panel)
		panel.position = Vector2(PANEL_X0 + PANEL_PITCH * i, 0)
		panel.size = PANEL_SIZE
	if _page_label != null:
		_page_label.text = "Party of %d  ·  page %d/%d" % [_party.size(), _page + 1, pages]
	_refresh_bars()
	_rerim()


## 02 §1.2-1.6's combatant panel, with canon's content: portrait, name, class
## (and a level only if the raider carries one), the HP bar folded from the log,
## and the raider's GEAR where the reference drew an ability grid it has no data
## for — the weapon in the tall slot, the six other slots as the grid.
func _combatant_panel(raider) -> Control:
	var panel := Widgets.panel("PanelRound", 0)
	panel.clip_contents = true
	var body := Control.new()
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(body)

	var portrait := Widgets.slot(_portrait_for(raider), Widgets.PORTRAIT_SLOT, "SlotBronze")
	if portrait.get_child_count() > 0 and portrait.get_child(0) is TextureRect \
			and portrait.get_child(0).texture.get_width() < 40:
		# A 24px face doubled: keep its pixels square rather than blur them.
		portrait.get_child(0).texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(portrait)
	portrait.position = Vector2(9, 9)
	portrait.size = Vector2(Widgets.PORTRAIT_SLOT, Widgets.PORTRAIT_SLOT)

	var name_l := Widgets.label_as(String(raider.display_name), "LabelName")
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(name_l)
	name_l.position = Vector2(77, 10)
	name_l.size = Vector2(92, 24)
	var cls := Widgets.label_as(Enums.class_name_of(raider.class_id), "LabelClass")
	body.add_child(cls)
	cls.position = Vector2(77, 35)
	# 00 §2.3: no levels in canon's model; shown only when something set one.
	if int(raider.level) > 0:
		var lv := Widgets.label_as("Lv. %d" % int(raider.level), "LabelLevel")
		body.add_child(lv)
		lv.position = Vector2(77, 56)

	# 02 §1.4's top-right status slot resolves to the raider's state word.
	var state_l := Widgets.label_as("", "LabelSmall")
	state_l.add_theme_color_override("font_color", Palette.DANGER)
	state_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.add_child(state_l)
	state_l.position = Vector2(PANEL_SIZE.x - 8 - 60, 12)
	state_l.size = Vector2(60, 20)
	_panel_states[String(raider.id)] = state_l

	# 02 §1.5: the HP row. Max from the raider's own sheet; if there is no
	# content to read it from the bar is not drawn rather than guessed.
	var max_hp: int = int(_raider_max.get(String(raider.id), 0))
	if max_hp <= 0 and _db != null:
		# The panel can be built before the fold has run; the sheet is the
		# same source the fold reads, so ask it directly rather than draw no bar.
		max_hp = int(raider.max_hp(_db))
		_raider_max[String(raider.id)] = max_hp
		if not _raider_hp.has(String(raider.id)):
			_raider_hp[String(raider.id)] = max_hp
	if max_hp > 0:
		# KIT-17: the reference's status glyph (a 24px shield) where "HP" was
		# printed; the word is the glyph's tooltip, no test reads it.
		var hp_cap := TextureRect.new()
		hp_cap.name = "HpGlyph"
		hp_cap.texture = Icons.at("bar", "hp")
		hp_cap.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		hp_cap.tooltip_text = "HP"
		hp_cap.mouse_filter = Control.MOUSE_FILTER_PASS
		body.add_child(hp_cap)
		hp_cap.position = Vector2(9, 93)
		hp_cap.size = Vector2(24, 24)
		var bar := Widgets.bar(max_hp, max_hp, "hp", "", Vector2i(182, 17))
		body.add_child(bar)
		bar.position = Vector2(38, 97)
		bar.size = Vector2(182, 17)
		_panel_bars[String(raider.id)] = bar
	_status_row(raider, body)

	# 02 §1.6: weapon slot 60x84 at (11, 149); the 3x2 grid of 38px cells at
	# pitch 46 from x 89. Slot order is canon's (Enums.Slot).
	var weapon := _gear_cell(raider, Enums.Slot.MAIN_HAND, 60)
	weapon.custom_minimum_size = Vector2(60, 84)
	body.add_child(weapon)
	weapon.position = Vector2(11, 149)
	weapon.size = Vector2(60, 84)
	var others := [Enums.Slot.OFF_HAND, Enums.Slot.HEAD, Enums.Slot.CHEST,
		Enums.Slot.LEGS, Enums.Slot.FEET, Enums.Slot.TRINKET]
	for i in others.size():
		var cell := _gear_cell(raider, others[i], 38)
		body.add_child(cell)
		cell.position = Vector2(89 + 46 * (i % 3), 149 + 46 * (i / 3))
		cell.size = Vector2(38, 38)

	_panel_nodes[String(raider.id)] = panel
	return panel


func _gear_cell(raider, slot: int, size: int) -> Control:
	var item = raider.item_in(_db, slot) if _db != null else null
	# An empty slot shows its own glyph, dimmed, so the grid reads as a body
	# with gaps rather than as holes.
	var icon := Cards.gear_icon(slot, item != null, item)
	var cell := Widgets.slot(icon, size)
	if item == null and cell.get_child_count() > 0:
		cell.get_child(0).modulate = Color(1, 1, 1, 0.38)
	cell.tooltip_text = ("%s — %s" % [Enums.slot_name_of(slot), String(item.name)]
		if item != null else "%s — empty" % Enums.slot_name_of(slot))
	if item != null:
		# KIT-22 / UI-49's sweep (handoff-W6-SHEETS): the kit's two-line plate
		# for a worn piece; `tooltip_text` re-set to the "slot — item" words
		# the tests read (tooltip_for writes "item — slot").
		Widgets.tooltip_for(cell, String(item.name), Enums.slot_name_of(slot))
		cell.tooltip_text = "%s — %s" % [Enums.slot_name_of(slot), String(item.name)]
	return cell


## COMBAT-13: the band 02 §1 left dead between the HP row and the gear grid,
## filled with what docs/13 §9.3's rail reads per raider — the morale figure
## with its glyph (`LabelMorale` carries the authored face font, and the glyph
## comes through `Cards.morale_glyph` so emoji-free still prints its pips in
## `Label.text`), the state glyph slot (spec 02 §1.4: a 22px `state_<key>`
## plate; the WORD stays top-right in `_panel_states` for the tests), and the
## blot row (COMBAT-09). The glyph and the blots are filled by `_refresh_status`.
func _status_row(raider, body: Control) -> void:
	var id := String(raider.id)
	var m: int = int(raider.morale)
	var morale := Widgets.label_as("%d %s" % [m, Cards.morale_glyph(self, m)], "LabelMorale")
	morale.name = "Morale"
	morale.clip_text = true
	morale.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	morale.add_theme_color_override("font_color", Palette.morale_color(m))
	morale.tooltip_text = "Morale %d — %s" % [m, Enums.morale_band_name(m)]
	morale.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(morale)
	morale.position = STATUS_ROW.position
	morale.size = Vector2(96, STATUS_ROW.size.y)

	var glyph := TextureRect.new()
	glyph.name = "StateGlyph"
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_PASS
	glyph.visible = false
	body.add_child(glyph)
	glyph.position = Vector2(STATUS_ROW.position.x + 102, STATUS_ROW.position.y + 2)
	glyph.size = Vector2(STATUS_GLYPH, STATUS_GLYPH)
	_panel_glyphs[id] = glyph

	var blots := Control.new()
	blots.name = "Blots"
	blots.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(blots)
	blots.position = Vector2(STATUS_ROW.position.x + 128, STATUS_ROW.position.y + 7)
	blots.size = Vector2(STATUS_ROW.size.x - 128, 12)
	_panel_blots[id] = blots


## The three blot silhouettes in turn, so a row of them does not tile.
func _blot_texture(index: int) -> Texture2D:
	return Icons.at("blot", ["a", "b", "c"][posmod(index, 3)])


## Fill a blot host with `count` 12px blots at BLOT_PITCH, clipped to the host's
## width (a fourth or fifth mistake is still counted in the tooltip).
func _fill_blots(host: Control, count: int) -> void:
	for c in host.get_children():
		host.remove_child(c)
		c.queue_free()
	var fit: int = maxi(0, int(host.size.x) / BLOT_PITCH)
	for i in mini(count, fit):
		var b := TextureRect.new()
		b.name = "Blot_%d" % i
		b.texture = _blot_texture(i)
		b.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(b)
		b.position = Vector2(BLOT_PITCH * i, 0)
		b.size = Vector2(12, 12)
	host.tooltip_text = ("%d mistake%s this attempt" % [count, "" if count == 1 else "s"]
		if count > 0 else "")


## Cards.portrait_for answers first, and now always does for a canon class: the
## five classes the reference does not depict have their own
## game/assets/portraits/class_<key>.png and the other four borrow its busts. The
## re-check below and the ten small faces are the fallback for a raider of no
## canon class, picked by the raider's MORALE BAND (HALL-05: the ten faces are
## the morale glyphs, so the face shown is the mood the raider is in — a face
## picked by id hash was a random expression) — never a wrong-class bust.
func _portrait_for(raider) -> Texture2D:
	var t := Cards.portrait_for(raider)
	if t != null:
		return t
	var by_class := PORTRAIT + "class_%s.png" % Enums.class_key(raider.class_id)
	if ResourceLoader.exists(by_class):
		return load(by_class)
	return Icons.at("face", "%d" % Enums.morale_band(int(raider.morale)))


func _hairline(at: Vector2, width: float, tone: Color) -> void:
	var r := ColorRect.new()
	r.color = tone
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	r.position = at
	r.size = Vector2(width, 1)


# ---------------------------------------------------------------- the fold

## Reset every bar to the fight's opening state.
func _reset_fold() -> void:
	_full = []
	_fold_index = 0
	_raider_hp.clear()
	_raider_max.clear()
	_raider_state.clear()
	_raider_blots.clear()
	_enemy_hp.clear()
	_enemy_max = 0
	_round = 0
	if _state != null and _state.last_result != null and _state.last_result.log != null:
		_full = _state.last_result.log.at_tier(Enums.LogTier.PLAY_BY_PLAY)
	for r in _party:
		var mx: int = r.max_hp(_db) if _db != null else 0
		_raider_max[String(r.id)] = mx
		_raider_hp[String(r.id)] = mx
	if _encounter != null:
		# RaidSim names a pack's members "<name> 1", "<name> 2"…; a lone block
		# keeps its bare name. Mechanic-spawned adds are not in the encounter's
		# roster and so count in neither the maximum nor the remainder.
		for block in _encounter.enemies:
			for i in block.count:
				var nm: String = block.name if block.count == 1 else "%s %d" % [block.name, i + 1]
				_enemy_hp[nm] = block.hp
			_enemy_max += block.total_hp()


## Consume the Play-by-play stream up to and including `sequence`, so the bars
## agree with the newest line the reader has been shown — at every tier.
func _fold_to(sequence: int) -> void:
	while _fold_index < _full.size() and _full[_fold_index].sequence <= sequence:
		var e = _full[_fold_index]
		_fold_index += 1
		_round = maxi(_round, e.round_no)
		match e.verb:
			Enums.Verb.ATTACK, Enums.Verb.HEAL:
				if e.numbers.has("hp_after"):
					if not e.target_id.is_empty():
						_raider_hp[e.target_id] = e.number("hp_after")
					elif _enemy_hp.has(e.target_name):
						_enemy_hp[e.target_name] = e.number("hp_after")
			Enums.Verb.STATE_CHANGE:
				if not e.actor_id.is_empty():
					_raider_state[e.actor_id] = String(e.params.get("state", ""))
			Enums.Verb.MISTAKE:
				# COMBAT-09: the ink is per raider. Every tier shows mistakes
				# (they are Story tier), so this count and the log agree.
				if not e.actor_id.is_empty():
					_raider_blots[e.actor_id] = int(_raider_blots.get(e.actor_id, 0)) + 1


## COMBAT-09's count for one raider, as folded so far.
func blots_of(id: String) -> int:
	return int(_raider_blots.get(id, 0))


## Whether a raider's death act is still running on this screen's clock.
func _dying_now(id: String) -> bool:
	return _dying.has(id) and _clock < float(_dying[id])


## The floor follows the panels. 10 §2 R4 greys a fallen combatant's panel and
## keeps it in its slot; the figure on the plateau does the same and stops
## breathing, because a body that is still breathing is the wrong kind of funny.
## Resuming is guarded by the stage's own reduced-motion state — otherwise this
## would quietly undo docs/13 §13 for exactly the figures the screen added.
func _refresh_party_sprites() -> void:
	var held: bool = _stage_node != null and _stage_node.motion_held()
	for id in _party_sprites:
		var spr: AnimatedSprite2D = _party_sprites[id]
		if not is_instance_valid(spr):
			continue
		var style := SceneStage.party_state_style(String(_raider_state.get(id, "")))
		# A figure mid-death owns its tint: the stage's `death` act lerps the
		# grey over its length, and a refresh writing the end state under it
		# flickered (STAGE-09). The fold's grey lands when the act is over.
		if not _dying_now(String(id)):
			spr.modulate = style["tint"]
		if bool(style["still"]):
			spr.stop()
			if bool(style["rewind"]):
				spr.frame = 0
		elif not held and not spr.is_playing():
			spr.play("idle")


func _refresh_bars() -> void:
	for id in _panel_bars:
		var bar = _panel_bars[id]
		var mx: int = int(_raider_max.get(id, 0))
		var hp: int = clampi(int(_raider_hp.get(id, mx)), 0, mx)
		bar.value = hp
		bar.maximum = mx
		bar.text = "%d/%d" % [hp, mx]
	_refresh_party_sprites()
	for id in _panel_states:
		var word := String(_raider_state.get(id, ""))
		_panel_states[id].text = word.capitalize()
		if _panel_nodes.has(id):
			# 10 §2 R4: fallen combatants stay in their slot, greyed.
			_panel_nodes[id].modulate = (Color(0.55, 0.55, 0.58)
				if word.to_lower() == "dead" else Color.WHITE)
		_refresh_status(id, word)
	_refresh_overheads()
	if _boss_bar != null:
		var left := 0
		for nm in _enemy_hp:
			left += int(_enemy_hp[nm])
		_boss_bar.maximum = _enemy_max
		_boss_bar.value = left
		_boss_bar.text = "%d / %d" % [left, _enemy_max]
		# The floor agrees with the bar: at zero the creature greys and stops
		# breathing, from the same function a fallen raider reads.
		if _boss_sprite != null and is_instance_valid(_boss_sprite):
			var style := SceneStage.party_state_style("dead" if left <= 0 and _enemy_max > 0 else "")
			_boss_sprite.modulate = style["tint"]
	if _round_label != null:
		_round_label.text = ("Round %d of %d  ·  enrage at %d" % [_round,
			_encounter.target_rounds, _encounter.enrage_round] if _encounter != null
			else "Round %d" % _round)


## COMBAT-13: the status row follows the fold — the state glyph shows for a
## downed or dead raider (the word stays top-right), the blot row grows with
## the raider's mistakes. Each half is redrawn only when its reading changes.
func _refresh_status(id: String, word: String) -> void:
	var key := word.to_lower()
	if _panel_glyphs.has(id):
		var glyph: TextureRect = _panel_glyphs[id]
		if String(glyph.get_meta("key", "")) != key:
			glyph.set_meta("key", key)
			var shown := not key.is_empty() and Icons.exists("state", key)
			glyph.visible = shown
			glyph.texture = Icons.at("state", key) if shown else null
			glyph.tooltip_text = word.capitalize() if shown else ""
	if _panel_blots.has(id):
		var host: Control = _panel_blots[id]
		var n := blots_of(id)
		if int(host.get_meta("count", -1)) != n:
			host.set_meta("count", n)
			_fill_blots(host, n)


## spec 02 §5.1 through the stage (COMBAT-03, STAGE-04, Q07's default): every
## figure wears its class badge with a blot pip per mistake; the 62x7 HP bar
## only on the acting or struck figure (`_bar_ids`). A downed or dead figure's
## badge is its `state_<key>` plate, and a downed one carries a "!" LABEL over
## it (CRITIC-C18 — the plate is a sprite, the mark is text). Rebuilt only when
## a figure's reading changes, so one line does not redraw twelve boxes.
func _refresh_overheads() -> void:
	if _stage_node == null or not is_instance_valid(_stage_node):
		return
	for id in _party_sprites:
		var spr = _party_sprites[id]
		if not is_instance_valid(spr):
			continue
		var mx: int = int(_raider_max.get(id, 0))
		var hp: int = clampi(int(_raider_hp.get(id, mx)), 0, mx)
		var state := String(_raider_state.get(id, "")).to_lower()
		var blots := blots_of(id)
		var with_bar: bool = id in _bar_ids
		var sig := "%s|%d|%d|%d|%s" % [state, blots, hp, mx, str(with_bar)]
		if String(spr.get_meta("overhead", "")) == sig:
			continue
		spr.set_meta("overhead", sig)
		var pips: Array = []
		for i in mini(4, blots):
			pips.append(_blot_texture(i))
		var plate: Texture2D = Icons.at("state", state) \
			if not state.is_empty() and Icons.exists("state", state) else null
		var box: Control = _stage_node.bar_for(spr, hp, mx, plate,
			{"bar": with_bar, "pips": pips})
		if box != null and plate == null:
			# The stage's bare plate carries the class glyph, centred, 1:1 —
			# a 16px cell resampled to the 24px slot would blur its pixels.
			var glyph := _class_glyph(id)
			var slot: Control = box.get_node_or_null("Badge")
			if glyph != null and slot != null:
				var g := TextureRect.new()
				g.name = "Glyph"
				g.texture = glyph
				g.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
				g.mouse_filter = Control.MOUSE_FILTER_IGNORE
				slot.add_child(g)
				g.position = Vector2.ZERO
				g.size = slot.size
		if box != null and state == "downed":
			var bang := Widgets.label_as("!", "LabelName")
			bang.name = "Bang"
			bang.add_theme_color_override("font_color", Palette.CAUTION)
			bang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bang.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			bang.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(bang)
			bang.position = Vector2.ZERO
			bang.size = Vector2(SceneStage.BAR_BADGE, SceneStage.BAR_BADGE)


## The raider's 16px class glyph (W1-ICONS' grid), or null for a class the
## grid does not carry.
func _class_glyph(id: String) -> Texture2D:
	var r = _raider_by_id.get(id, null)
	var key: String = Enums.class_key(int(r.class_id)) if r != null else ""
	if not Icons.exists("class", key):
		return null
	return Icons.at("class", key)


## The figure an entry's target is: a raider's sprite by id, or the boss for
## anything on the enemy side (a pack member or a mechanic's add stands where
## the boss stands — the one creature on the floor is the enemy side).
func _target_sprite(e) -> Node2D:
	if not String(e.target_id).is_empty():
		var spr = _party_sprites.get(String(e.target_id), null)
		return spr if spr != null and is_instance_valid(spr) else null
	if String(e.target_name).is_empty():
		return null
	if _boss_sprite != null and is_instance_valid(_boss_sprite):
		return _boss_sprite
	return null


# ---------------------------------------------------------------- effects

## COMBAT-16, under CRITIC-G08's rule. The per-line UI-layer effects (the
## actor's panel rim, the figure's brighten, the mechanic cell, the boss's
## flash, a struck figure's flash) fire per line at 1x, once per round at 2x,
## and not at all at 4x, Instant, during a skip or under `reduced_effects` —
## docs/13 §13's three-changes-a-second rule governs this layer (BL-75). The
## numbers, bubbles and bars are the world layer and are not gated here.
func _effects_allowed(e) -> bool:
	if not _live or _player == null:
		return false
	if _settings != null and bool(_settings.get_value("reduced_effects")):
		return false
	match _player.speed:
		LogPlayer.Speed.ONE:
			return true
		LogPlayer.Speed.TWO:
			if e.round_no == _effect_round:
				return false
			_effect_round = e.round_no
			return true
		_:
			return false


## Everything is a modulate or a StyleBox swap — no tween, so tools/lint_motion
## is untouched and nothing here has a duration the setting would need to scale.
## A lift with `hold` 0 lasts one frame: `_process` puts it back on its next
## call, which is what "flashes one frame" means at any frame rate.
func _line_effects(e) -> void:
	if not _effects_allowed(e):
		return
	var cadence: float = float(LogPlayer.LINE_CADENCE.get(_player.speed, 0.18))
	if cadence <= 0.0:
		cadence = 0.18
	var actor_id := String(e.actor_id)
	# The rim means "this line is theirs": a boss or system line clears it.
	_rim_panel(actor_id)
	if not actor_id.is_empty():
		var actor = _party_sprites.get(actor_id, null)
		# A fallen figure is not brightened: its state tint (and, for a death,
		# the stage's act) owns its colour, and a lift fighting that flickered.
		if actor != null and is_instance_valid(actor) \
				and String(_raider_state.get(actor_id, "")).is_empty():
			_lift(actor, Color(1.15, 1.15, 1.15), cadence, actor_id)
	# The struck figure's flash is the stage's own `hit` now (`_attack_beat`,
	# on the stage's clock for Motion.HIT), so COMBAT-07's interim one-frame
	# lift is gone rather than doubled.
	match e.verb:
		Enums.Verb.MECHANIC:
			var key := Icons.mech_key(String(e.params.get("mechanic", "")))
			if _mech_cells.has(key) and is_instance_valid(_mech_cells[key]):
				_lift(_mech_cells[key], Color(1.6, 1.6, 1.6), cadence, "")
			if _boss_sprite != null and is_instance_valid(_boss_sprite):
				_lift(_boss_sprite, Palette.TEXT_BODY, 0.0, "")


## The 2px ACCENT_GOLD rim marks whose line this is; it moves from panel to
## panel and comes off when the actor is off-page or not a raider.
func _rim_panel(id: String) -> void:
	if id == _lit_panel_id:
		return
	if _panel_nodes.has(_lit_panel_id) and is_instance_valid(_panel_nodes[_lit_panel_id]):
		_panel_nodes[_lit_panel_id].remove_theme_stylebox_override("panel")
	_lit_panel_id = ""
	if _panel_nodes.has(id) and is_instance_valid(_panel_nodes[id]):
		_panel_nodes[id].add_theme_stylebox_override("panel",
			Theme_.flat(Palette.SURFACE_CARD, Palette.ACCENT_GOLD, 2, 6, 0))
		_lit_panel_id = id


## Re-apply the rim after the panels were rebuilt (a page turn frees them).
func _rerim() -> void:
	var id := _lit_panel_id
	_lit_panel_id = ""
	if not id.is_empty():
		_rim_panel(id)


## A modulate lift on a node, restored by `_settle_lifts` once `hold` seconds
## have passed on this screen's clock (0 = the next `_process` call). A second
## lift on the same node replaces the first rather than stacking.
func _lift(node: CanvasItem, tint: Color, hold: float, id: String) -> void:
	for i in range(_lit.size() - 1, -1, -1):
		if _lit[i]["node"] == node:
			_lit.remove_at(i)
	node.modulate = tint
	_lit.append({"node": node, "until": _clock + hold, "id": id})


## Put every expired lift back to what the fold says it should be: a figure
## to its state tint, the boss to its bar's reading, a cell to plain white.
func _settle_lifts(all: bool = false) -> void:
	if _lit.is_empty():
		return
	var keep: Array = []
	for entry in _lit:
		var node = entry["node"]
		if not is_instance_valid(node):
			continue
		if not all and _clock < float(entry["until"]):
			keep.append(entry)
			continue
		if node == _boss_sprite:
			var left := 0
			for nm in _enemy_hp:
				left += int(_enemy_hp[nm])
			node.modulate = SceneStage.party_state_style(
				"dead" if left <= 0 and _enemy_max > 0 else "")["tint"]
		elif not String(entry["id"]).is_empty() and node is AnimatedSprite2D:
			if not _dying_now(String(entry["id"])):
				node.modulate = SceneStage.party_state_style(
					String(_raider_state.get(String(entry["id"]), "")))["tint"]
		else:
			node.modulate = Color.WHITE
	_lit = keep


## 10 §2 R4: the strip shows the page holding whoever the newest line is about.
func _follow(e) -> void:
	if _manual_hold > 0.0 or _page_hold > 0.0 or _pages() <= 1:
		return
	for id in [e.actor_id, e.target_id]:
		if String(id).is_empty():
			continue
		for i in _party.size():
			if String(_party[i].id) == String(id):
				var page: int = i / PANELS_PER_PAGE
				if page != _page:
					_page = page
					_page_hold = PAGE_HOLD
					_build_panels()
				return


# ---------------------------------------------------------------- the reveal

func _entries_for_tier() -> Array:
	if _state == null or _state.last_result == null \
			or _state.last_result.log == null:
		return []
	return _state.last_result.log.at_tier(_tier)


func _reset_player() -> void:
	var keep_speed: int = _player.speed if _player != null else _opening_speed()
	_player = LogPlayer.new(_entries_for_tier(), keep_speed)
	if _settings != null:
		# docs/13 §11.2's comedy brake is a player setting, default on.
		_player.comedy_brake = bool(_settings.get_value("comedy_brake"))
	_mistakes_seen = 0
	_wipe_timer = 0.0
	_wipe_shown = false
	_finished_ui = false
	_last_row_round = -1
	_cause_row = null
	_effect_round = -1
	_bar_ids = []
	_log_rows = []
	_stick = false
	_dwelling = false
	_settle_lifts(true)
	_rim_panel("")
	# A replay (a tier change) starts the fight over: whoever the stage's
	# `death` act toppled stands up again — the act has finished and left its
	# angle on the figure, which is the screen's to put back.
	_dying.clear()
	_boss_fallen = false
	for id in _party_sprites:
		var spr = _party_sprites[id]
		if spr != null and is_instance_valid(spr):
			spr.rotation = 0.0
	if _boss_sprite != null and is_instance_valid(_boss_sprite):
		_boss_sprite.rotation = 0.0
	if _mistake_counter != null:
		_mistake_counter.text = "Mistakes this attempt  0"
	for c in _log_col.get_children():
		_log_col.remove_child(c)
		c.queue_free()
	if _entries_for_tier().is_empty():
		_log_col.add_child(Widgets.empty_state(
			"No account was written. Depart from the board to run an attempt."))
	_reset_fold()
	_refresh_bars()
	_sync_controls()


## Changing detail rebuilds the page at the new tier and REPLAYS from the start.
## docs/13 §11.1 treats verbosity as a filter over one complete log, so switching
## is a re-read rather than a continuation — and a partial page at a new tier
## would be a page that never existed.
func _set_tier(tier: int) -> void:
	if tier == _tier:
		return
	_tier = tier
	_reset_player()


func _sync_controls() -> void:
	if _player == null:
		return
	if _speed_button != null:
		_speed_button.text = _player.speed_label()
	if _pause_button != null:
		_pause_button.text = "Resume" if _player.paused else "Pause"
	# CRITIC-G13: the dwell's stamp is up exactly while the account is stopped
	# on a mistake; Resume, a speed cycle, a tier change or a skip take it down.
	if not _player.paused:
		_dwelling = false
	if _paused_stamp != null and is_instance_valid(_paused_stamp):
		_paused_stamp.visible = _player.paused and _dwelling
	for tier in _tier_buttons:
		var b: Button = _tier_buttons[tier]
		b.add_theme_color_override("font_color",
			Palette.ACCENT_GOLD_LIGHT if tier == _tier else Palette.TEXT_MUTED)


## docs/01 §9: the stored speed is global and persisted, but Instant is capped
## away for an encounter that has never been cleared.
func _opening_speed() -> int:
	if _settings == null:
		return LogPlayer.Speed.ONE
	var stored: int = int(_settings.get_value("sim_speed"))
	if _skip_unlocked:
		return clampi(stored, LogPlayer.Speed.ONE, LogPlayer.Speed.INSTANT)
	return clampi(stored, LogPlayer.Speed.ONE, LogPlayer.Speed.FOUR)


## docs/13 §13's `log_manual_advance`: "the sim pauses at each mistake until
## dismissed, for players who read slower than 1x."
##
## CRITIC-G13: the pause has to be SEEN to be dismissed. The Pause button's
## word changing was the only cue; now the kit's stamp ("PAUSED — mistake", a
## Label so `_texts()` reads it, CAUTION ink, the 2-7° lean a static stamp
## carries and no press — it is a fact, not an event) lands on the log panel's
## corner and the Pause button takes the focus, so the key that resumes is the
## one under the player's thumb. `_sync_controls` takes the stamp down.
func _dwell_on(e) -> void:
	if _settings == null or _player == null:
		return
	if not bool(_settings.get_value("log_manual_advance")):
		return
	if e.is_mistake():
		_player.paused = true
		_dwelling = true
		_paused_stamp_up()
		_sync_controls()
		if _pause_button != null and is_instance_valid(_pause_button) \
				and _pause_button.is_inside_tree():
			_pause_button.grab_focus()


## The dwell's stamp, built once and then shown/hidden. A direct child of the
## screen after the log panel, so it sits on the page rather than in the column.
func _paused_stamp_up() -> void:
	if _paused_stamp != null and is_instance_valid(_paused_stamp):
		_paused_stamp.visible = true
		return
	_paused_stamp = Widgets.stamp("PAUSED — mistake", Palette.CAUTION)
	_paused_stamp.name = "PausedStamp"
	_paused_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paused_stamp)
	_paused_stamp.size = _paused_stamp.get_combined_minimum_size()
	_paused_stamp.pivot_offset = _paused_stamp.size * 0.5
	_paused_stamp.position = PAUSED_STAMP_AT - Vector2(_paused_stamp.size.x, 0)


func _process(delta: float) -> void:
	if _player == null:
		return
	_clock += delta
	_settle_lifts()
	if _scroll_pending > 0:
		_scroll_pending -= 1
		if _scroll_pending == 0:
			_scroll_to_end()
	_page_hold = maxf(0.0, _page_hold - delta)
	_manual_hold = maxf(0.0, _manual_hold - delta)

	if not _player.is_finished():
		for e in _player.advance(delta):
			_append_line(e)
			_dwell_on(e)
		return

	# docs/13 §11.4's wipe sequence, once the account has stopped.
	if not _finished_ui:
		_finished_ui = true
		_wipe_timer = 0.0
		# COMBAT-14: the account is read; a gated pair of exits opens.
		_release_exits()
	if _is_wipe() and not _wipe_shown:
		_wipe_timer += delta
		_run_wipe_sequence(_wipe_timer * 1000.0)


func _is_wipe() -> bool:
	if _state == null or _state.last_result == null:
		return false
	return not _state.last_result.cleared()


## docs/13 §11.4, beat by beat, driven by the clock in `_process` rather than by
## `await` so that `_on_skip()` can abort it mid-sequence.
##
## `elapsed_ms` is how long the account has been stopped. Each beat fires once.
func _run_wipe_sequence(elapsed_ms: float) -> void:
	_beat(WIPE_BEAT_SILENCE_MS, elapsed_ms, "_wipe_silence")
	_beat(WIPE_BEAT_LINE_MS, elapsed_ms, "_wipe_line")
	_beat(WIPE_BEAT_STAMP_MS, elapsed_ms, "_wipe_stamp")
	_beat(WIPE_BEAT_DIM_MS, elapsed_ms, "_wipe_dim_page")
	_beat(WIPE_BEAT_EXITS_MS, elapsed_ms, "_wipe_exits")


## Fire `method` once, when the clock first passes `at_ms`.
func _beat(at_ms: int, elapsed_ms: float, method: String) -> void:
	if _wipe_beats.has(method) or elapsed_ms < float(at_ms):
		return
	_wipe_beats[method] = true
	call(method)


## t=0. "The account stops. Every remaining animation halts on frame. Silence for
## 400ms — the only silence in the game."
##
## The stage's own motion is what "every remaining animation" means: `SceneStage`
## holds its flames and idles on frame, the same hold `reduced_motion` uses, so
## the world stops rather than each sprite being chased down. The silence is
## docs/13 §12.4's duck, and it is the whole 400ms to the next beat.
func _wipe_silence() -> void:
	if _stage_node != null and _stage_node.has_method("apply_settings"):
		_stage_node.apply_settings(true, true)
	# The hook, not a bare duck: `ui.silence` IS the −60 dB / 400 ms duck
	# (Audio.HOOKS), and going through `play` puts the beat on the debug tape
	# beside the stamp and the seal, so a test can read the sequence in order.
	var audio := Services.find(self, "Audio")
	if audio != null and audio.has_method("play"):
		audio.play("ui.silence")


## t=400. "The final line writes: `[R10] WIPE.` ... at 32px".
##
## It goes into the LOG, not over the stage: §11.1 makes the log a document, and
## the last line of the account is the account's own. The round number is the one
## the run actually ended on rather than the doc's illustrative 10.
func _wipe_line() -> void:
	var line := Widgets.label_as("[R%d] WIPE." % _round, "LabelLog")
	line.add_theme_font_size_override("font_size", Type.at(Type.FIGURE_XL, Theme_.scale_of(self)))
	line.add_theme_color_override("font_color", Palette.DANGER)
	# Two pitches: the 34px word is taller than one, and every row of the
	# column is a whole number of them so the scroll's end stays on a row.
	line.custom_minimum_size = Vector2(0, Widgets.LOG_ROW_PITCH * 2)
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _log_col != null:
		_log_col.add_child(line)
	_autoscroll()
	# LOOP-12: the beat points at the same entry the report's sentence names —
	# the sim's "It traces back to …" row, written a line or two above this
	# one. The follow already ends the page there; this is the promise kept
	# by name, after the follow has settled (a no-op when the row is in view).
	if _cause_row != null and is_instance_valid(_cause_row) \
			and _scroll != null and is_instance_valid(_scroll):
		_scroll.call_deferred("ensure_control_visible", _cause_row)


## t=900. "A large WIPE stamp presses diagonally across the page: 180ms,
## 1.15 -> 1.00 scale, -7° rotation, then a 400ms ink bleed into the paper fibre."
##
## The stamp is the kit's StampBadge (COMBAT-08, docs/13 §7): `Widgets.stamp_box`
## — the worn double rule around the word, leaning its own 2-7° — with the
## "WIPE." Label as the box's DIRECT child and the box a DIRECT child of this
## screen, added after the blot. test_wipe_sequence reads exactly that shape
## (`_wipe_stamp_label.get_parent().get_index()` against `_wipe_blot`'s), so
## the box is never wrapped one level deeper (CRITIC-C18).
##
## The press is a tween through `Widgets.tween()` with the duration from
## `GameSettings.motion_duration()`, which is what makes docs/13 §13's carve-out
## expressible: reduced motion collapses the 180ms to its 60ms floor and drops
## the tilt, and the stamp still LANDS because it carries state. It presses
## from the box's lean plus the doc's -7° down onto the lean, so under reduced
## motion there is no rotation MOTION while the static lean (a fact of the
## stamp, not an animation) stays. The bleed is `wipe_blot.png` (gen_wipe.lua),
## added first so the ink sits under the word.
##
## WHERE it presses is the log panel (COMBAT-15): §11.4's "page" is the
## document the account was written on, so the box lands across LOG_RECT
## (`WIPE_STAMP_RECT`), the word at Type.FIGURE_XL (the `LabelFigure`
## variation), the cost line in LabelSmall beneath it inside the panel, and the
## blot bleeds into the panel under both — not onto the arena.
func _wipe_stamp() -> void:
	# AUDIO-16 / docs/13 §12.4 "StampBadge land — exactly on frame 1 of the
	# press, never late": the mistake's sound, first, at its own pitch (no
	# jitter on the one stamp the wipe presses; a heavier voice is a number in
	# these opts, never a second sample). Once per wipe: `_beat` fires this
	# method once, skipped or watched.
	var audio := Services.find(self, "Audio")
	if audio != null and audio.has_method("play"):
		audio.play("ui.stamp", {"pitch_scale": 1.0})
	_wipe_shown = true
	var box := Widgets.stamp_box("WIPE.", "danger")
	box.name = "WipeStamp"
	_wipe_stamp_label = box.get_child(0) as Label
	_wipe_stamp_label.theme_type_variation = "LabelFigure"
	_wipe_stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The bleed goes in FIRST so it sits under the word: §11.4 has the ink
	# spreading into the page the stamp was pressed onto, not over the top of it.
	var at := WIPE_STAMP_RECT.position
	var of_size := WIPE_STAMP_RECT.size
	_bleed_under(at, of_size)
	add_child(box)
	box.size = box.get_combined_minimum_size()
	box.position = at + (of_size - box.size) * 0.5
	box.pivot_offset = box.size * 0.5
	# The word is pressed INTO the bleed: the same ink, so on the page's dark
	# ground a red word on a red blot vanished (W3RV2_all_log_x2.png, first
	# take). The pressed edge shows the paper through — a 3px outline in the
	# page's own ground, the device the damage numbers already use.
	_wipe_stamp_label.add_theme_constant_override("outline_size", 3)
	_wipe_stamp_label.add_theme_color_override("font_outline_color", Palette.GROUND_PAGE)
	# The cost line sits on its own strip of the page, or it lands across
	# whatever row is under it ("A wipe costs…" over "Rhona is DEAD.").
	var strip := ColorRect.new()
	strip.name = "WipeCostPlate"
	strip.color = Color(Palette.SURFACE_PANEL, 0.92)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	strip.position = Vector2(at.x + 8, at.y + of_size.y + 4)
	strip.size = Vector2(of_size.x - 16, 24)
	var why := Widgets.label_as(
		"A wipe costs time, consumables, morale and money — never the save.", "LabelSmall")
	why.name = "WipeCost"
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	why.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(why)
	why.position = Vector2(at.x, at.y + of_size.y + 6)
	why.size = Vector2(of_size.x, 20)

	var seconds := WIPE_STAMP_MS / 1000.0
	var tilt := 0.0
	if _settings != null:
		seconds = _settings.motion_duration(WIPE_STAMP_MS, WIPE_STAMP_FLOOR_MS)
		# "no rotation" under reduced motion is the doc's own words, and it is a
		# separate instruction from the duration — a 60ms spin is still a spin.
		tilt = deg_to_rad(WIPE_STAMP_TILT_DEG) * _settings.motion_scale()
	var lean := deg_to_rad(box.rotation_degrees)
	box.scale = Vector2(WIPE_STAMP_FROM, WIPE_STAMP_FROM)
	box.rotation = lean + tilt
	var t := Widgets.tween(box)
	if t != null:
		t.set_ease(Tween.EASE_OUT)
		t.set_parallel(true)
		t.tween_property(box, "scale", Vector2.ONE, seconds)
		t.tween_property(box, "rotation", lean, seconds)
	else:
		box.scale = Vector2.ONE
		box.rotation = lean
	_autoscroll()


## §11.4's "400ms ink bleed into the paper fibre", centred on the stamp it
## belongs to. docs/13 §13 names the bleed among the things reduced motion turns
## off, and `motion_duration()` with no floor is how that is said: the duration
## collapses to zero, the tween still applies its final alpha on the next frame,
## and the ink is simply THERE rather than arriving. The stamp keeps its floor
## because §13 gives it one; the bleed does not, because §13 does not.
func _bleed_under(at: Vector2, of_size: Vector2) -> void:
	var tex = load(WIPE_BLOT) if ResourceLoader.exists(WIPE_BLOT) else null
	if tex == null:
		return
	_wipe_blot = TextureRect.new()
	_wipe_blot.texture = tex
	_wipe_blot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wipe_blot.modulate = Color(1, 1, 1, 0)
	add_child(_wipe_blot)
	var blot_size: Vector2 = tex.get_size()
	_wipe_blot.size = blot_size
	_wipe_blot.position = at + (of_size - blot_size) * 0.5
	var seconds := float(WIPE_BLEED_MS) / 1000.0
	if _settings != null:
		seconds = _settings.motion_duration(WIPE_BLEED_MS)
	var t := Widgets.tween(_wipe_blot)
	if t != null:
		t.tween_property(_wipe_blot, "modulate:a", 1.0, seconds)
	else:
		_wipe_blot.modulate = Color.WHITE


## t=1,400. "Page dims 12%; a wax seal drops onto the lower-right corner."
##
## The dim is a full-rect ColorRect — it is added late, so it sits over the stage
## and the log, which is what "the page" dimming means. The seal is added after
## it, because a seal pressed onto a dimmed page is still a seal ON the page.
func _wipe_dim_page() -> void:
	_wipe_dim = ColorRect.new()
	_wipe_dim.color = Color(0, 0, 0, 0)
	_wipe_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wipe_dim)
	_wipe_dim.position = Vector2.ZERO
	_wipe_dim.size = FRAME
	var seconds := 0.0
	if _settings != null:
		seconds = _settings.motion_duration(WIPE_STAMP_MS)
	var t := Widgets.tween(_wipe_dim)
	if t != null:
		t.tween_property(_wipe_dim, "color", Color(0, 0, 0, WIPE_DIM), seconds)
	else:
		_wipe_dim.color = Color(0, 0, 0, WIPE_DIM)
	_drop_seal(seconds)


## The seal "drops onto the lower-right corner" — of the page, i.e. the log
## panel's (COMBAT-15: `WAX_SEAL_REST` straddles that corner, so the wax seals
## the document rather than landing on the words that just wrote "[R11] WIPE.").
## A drop is a fall and a settle, so it is one short slide down into place
## rather than a fade — wax lands. Under reduced motion the duration is zero
## and it is simply on the page, which is the correct reading of §13: the seal
## carries state (this run is filed) and the state is what has to survive, not
## the fall.
func _drop_seal(seconds: float) -> void:
	var tex = load(WAX_SEAL) if ResourceLoader.exists(WAX_SEAL) else null
	if tex == null:
		return
	# AUDIO-16: the same wax as a WaxButton's commit, so the same sound; once
	# per wipe, because `_wipe_dim_page` (this beat) fires once through `_beat`.
	var audio := Services.find(self, "Audio")
	if audio != null and audio.has_method("play"):
		audio.play("ui.seal")
	_wax_seal = TextureRect.new()
	_wax_seal.texture = tex
	_wax_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wax_seal)
	var seal_size: Vector2 = tex.get_size()
	_wax_seal.size = seal_size
	var rest := WAX_SEAL_REST
	_wax_seal.position = rest - Vector2(0, 18.0 if seconds > 0.0 else 0.0)
	var t := Widgets.tween(_wax_seal)
	if t != null:
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(_wax_seal, "position", rest, seconds)
	else:
		_wax_seal.position = rest


## t=2,400. "`Try again` (paper) and `Return to town` (wax) become active. `Try
## again` is left and default-focused."
##
## This screen's two exits are "Back to the board" (paper, left) and "The report"
## (wax, right), which are the same pair under this project's own names — the
## board is where a retry is chalked. Focus goes to the left one, which is what
## §11.4 asks for and what a keyboard player needs after 2.4 seconds of watching.
func _wipe_exits() -> void:
	# Guarded: the unit suite runs the beats on a screen nothing has put in a
	# tree, where grab_focus() only prints an error (the backtrace noise every
	# RaidView test used to carry).
	if _retry_button != null and is_instance_valid(_retry_button) \
			and _retry_button.is_inside_tree():
		_retry_button.grab_focus()


func _on_skip() -> void:
	# "fully skippable on any input" (docs/13 §11.4). The account is not being
	# watched: the fold, the panels and the badges land, the numbers, bubbles
	# and per-line effects do not (G08: off at Instant).
	_live = false
	for e in _player.reveal_all():
		_append_line(e)
	_live = true
	# A hundred rows landed in one frame; `_follow_bottom`'s "still at the
	# bottom" test cannot be true across that, so the page is turned to its
	# last line by hand once the column has laid out (two frames on) — the
	# account ends where the reader is.
	_scroll_pending = 2
	# §11.4: "fully skippable on any input". Every beat fires at once, in order,
	# so a skipped sequence leaves exactly the state a watched one does.
	if _is_wipe() and not _wipe_shown:
		_run_wipe_sequence(float(WIPE_BEAT_EXITS_MS))
	_release_exits()
	_sync_controls()


# ---------------------------------------------------------------- one line

## 02 §2's row: a badge and one line, red only for a raider's harm. A mistake is
## still "the loudest single event in the game's UI" (docs/13 §11.3): its row is
## the red one, and its joke follows as the indented, quoted line.
func _append_line(e) -> void:
	var is_mistake: bool = e.is_mistake()
	if is_mistake:
		# A folded row (LogPlayer.collapse) stands for `count` mistakes; the
		# counter counts the account, not the rows.
		_mistakes_seen += LogPlayer.count_of(e)
		if _mistake_counter != null:
			_mistake_counter.text = "Mistakes this attempt  %d" % _mistakes_seen

	# Rounds scan as a column (docs/13 §11.1) — here as a quiet divider row:
	# the word, then a 1px EDGE_SLATE rule running to the panel's right edge
	# (COMBAT-17; spec 02 §2's hairline language) so the rounds read as rules
	# across the page rather than as one more small line in it.
	if e.round_no != _last_row_round and e.round_no > 0:
		_last_row_round = e.round_no
		_log_col.add_child(_round_marker(e.round_no))

	# A PHASE line (the Numbers tier's "-- Pull --" dividers) is a heading like
	# the round marker, not a line of the account: no settle, no age ramp, no
	# verb, no bar switch (CRITIC-G13's Numbers-mode finding).
	if e.verb == Enums.Verb.PHASE:
		var phase := Widgets.label_as(_body_text(e), "LabelSmall")
		phase.add_theme_color_override("font_color", Palette.TEXT_SLATE)
		phase.custom_minimum_size = Vector2(0, Widgets.LOG_ROW_PITCH)
		phase.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		phase.clip_text = true
		phase.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_log_col.add_child(phase)
		_fold_to(e.sequence)
		_refresh_bars()
		_autoscroll()
		return

	var style := _row_style(e)
	var text := _mistake_header(e) if is_mistake else _body_text(e)
	# COMBAT-06: the reference's per-row glyph (W1-ICONS' log discs through the
	# one lookup) where the coloured dot was; the dot stays the fallback.
	var kind := _log_kind(e)
	var glyph: Texture2D = Icons.at("log", kind) if Icons.exists("log", kind) else null
	if is_mistake:
		# AUDIO-04(b) / docs/13 §12.4: the stamp's sound "exactly on frame 1 of
		# the press, never late" — BEFORE the row is built — and the blot one
		# layer under it. `live` is what Audio's per-line gate reads: false on a
		# skip (`_on_skip` clears `_live`) and at Instant, where the whole
		# account lands in one frame and a wall of stamps is not a fight.
		var audio := Services.find(self, "Audio")
		if audio != null and audio.has_method("play"):
			var live: bool = _live and (_player == null or _player.speed != LogPlayer.Speed.INSTANT)
			audio.play("ui.stamp", {"live": live})
			audio.play("ui.blot", {"live": live})
	var row := Widgets.log_row(text, style[0], style[1], glyph, "", HEADER_LINES if is_mistake else 0)
	var label := row.get_child(row.get_child_count() - 1) as Label
	if label != null and not is_mistake:
		# 02 §2.1: a long ordinary row ellipsizes, never wraps — the LIVE log's
		# rule; the mistake's header is the exception below (UI-19).
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.tooltip_text = text
	if is_mistake:
		# COMBAT-09: the permanent blot in the log's margin, left of the glyph;
		# COMBAT-08: the MISTAKE stamp on the line, pressed as it lands
		# (docs/13 §11.3 — "the loudest single event in the game's UI").
		var blot := TextureRect.new()
		blot.name = "Blot"
		blot.texture = _blot_texture(_mistakes_seen - 1)
		blot.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		blot.custom_minimum_size = Vector2(12, 12)
		blot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		blot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(blot)
		row.move_child(blot, 0)
		var stamp := Widgets.stamp_box("MISTAKE", "danger")
		stamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(stamp)
		row.move_child(stamp, row.get_child_count() - 2)
		if _live:
			Widgets.stamp_press(stamp)
		if label != null:
			# UI-19 / LOOP-11: the header wraps rather than clips — the type
			# leads, so the first line always carries the mistake's name — and
			# the row is one pitch, or two when the words need them, measured
			# against the width the column has once its scrollbar is up (the
			# narrower case: a row measured there is never cut when the bar
			# arrives). The names of a folded row are the tooltip, a courtesy.
			label.tooltip_text = LogPlayer.actors_of(e)
			var w := _row_text_width(row, label)
			label.size = Vector2(w, label.size.y)
			var fs: Array = Widgets.font_of("LabelLog", self)
			var lines := clampi(text_lines(fs[0], int(fs[1]), text, w), 1, HEADER_LINES)
			row.custom_minimum_size = Vector2(0, Widgets.LOG_ROW_PITCH * lines)
	# COMBAT-17: the row lands at full opacity with docs/13 §11.1's "90ms 1px
	# vertical settle" — inside a margin wrapper the column respects (a
	# position tween on a container's child is re-laid the same frame).
	var settled := _settle(row)
	_age_rows(settled)
	# LOOP-12: the sim's verdict row — the entry the wipe beat and the report
	# both point at. Keyed on the template the sim files it under, never on
	# its words (`is_wipe_line` keys the wipe beat on the word "wipe", and the
	# cause line never says it).
	if e.verb == Enums.Verb.SYSTEM and String(e.template_id) == "wipe_cause":
		_cause_row = settled

	if is_mistake:
		# docs/13 §11.3's joke line. The sim writes it onto the entry at emit time
		# (`EventLog.emit_mistake`); nothing wrote it before, so this branch had
		# never once run in a real raid and the omission was silent.
		var joke_text := String(e.joke())
		if not joke_text.is_empty():
			var quoted := '"%s"' % joke_text
			var joke := Widgets.label_as(quoted, "LabelQuote")
			# CONTENT-15 / LOOP-11: the joke wraps and is never cut — up to
			# QUOTE_LINES, a third only when the corpus line needs it — inside a
			# fixed two-pitch band so a mistake keeps its three-pitch rhythm.
			joke.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			joke.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			joke.clip_text = false
			joke.tooltip_text = joke_text
			var qw := _log_inner_width() - QUOTE_INDENT
			joke.size = Vector2(qw, joke.size.y)
			var qfs: Array = Widgets.font_of("LabelQuote", self)
			var need := clampi(text_lines(qfs[0], int(qfs[1]), quoted, qw), 1, QUOTE_LINES_MAX)
			joke.max_lines_visible = maxi(QUOTE_LINES, need)
			var indent := MarginContainer.new()
			indent.name = "Quote"
			indent.add_theme_constant_override("margin_left", QUOTE_INDENT)
			indent.custom_minimum_size = Vector2(0, Widgets.LOG_ROW_PITCH * maxi(QUOTE_LINES, need))
			indent.add_child(joke)
			_age_rows(_settle(indent))
			# COMBAT-03: the joke lands on the offender too — the bubble over
			# the figure carries the words, the log keeps the full line.
			_bubble(e.actor_id, joke_text)

	_fold_to(e.sequence)
	_bar_ids = []
	for id in [String(e.actor_id), String(e.target_id)]:
		if not id.is_empty() and _party_sprites.has(id):
			_bar_ids.append(id)
	_follow(e)
	# The floor performs the line before the fold's refresh writes the end
	# state, so a death's grey is the act's lerp and not a snap (STAGE-09).
	_stage_verbs(e)
	_refresh_bars()
	_number(e)
	_line_effects(e)
	_autoscroll()


## The round divider: "Round N" then a hairline to the row's right edge.
func _round_marker(round_no: int) -> Control:
	var marker := HBoxContainer.new()
	marker.name = "Round_%d" % round_no
	marker.add_theme_constant_override("separation", 8)
	# One pitch (was 22): every row of the column is a whole number of them.
	marker.custom_minimum_size = Vector2(0, Widgets.LOG_ROW_PITCH)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var word := Widgets.label_as("Round %d" % round_no, "LabelSmall")
	word.add_theme_color_override("font_color", Palette.TEXT_SLATE)
	word.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	word.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marker.add_child(word)
	# The rule sits on the word's baseline band (6px up from the row's floor),
	# inside a margin box so the HBox's own alignment never moves it.
	var lift := MarginContainer.new()
	lift.add_theme_constant_override("margin_bottom", 6)
	lift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lift.size_flags_vertical = Control.SIZE_SHRINK_END
	lift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rule := ColorRect.new()
	rule.name = "Rule"
	rule.color = Palette.EDGE_SLATE
	rule.custom_minimum_size = Vector2(24, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lift.add_child(rule)
	marker.add_child(lift)
	return marker


## COMBAT-17 / docs/13 §12.2 "Log line arrival — 1px settle at full opacity —
## 90ms": the row goes into a MarginContainer whose top margin starts at 1px
## and goes to 0 over `Motion.LOG_SETTLE`, through the one door
## (`Widgets.tween` + `motion_duration`, no floor: under reduced motion the
## margin is 0 on the next frame and the row is simply there). The wrapper is
## what the age ramp dims, so the row's own modulate is never touched. Outside
## a tree (the unit suite) `Widgets.tween` answers null and the margin is 0 at
## once — arrive instantly, still arrive.
func _settle(row: Control) -> Control:
	var wrap := MarginContainer.new()
	wrap.name = "Settle"
	wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	wrap.add_child(row)
	_log_col.add_child(wrap)
	var seconds := float(Widgets.Motion.LOG_SETTLE) / 1000.0
	if _settings != null:
		seconds = _settings.motion_duration(Widgets.Motion.LOG_SETTLE)
	var t := Widgets.tween(wrap)
	if t == null or not _live:
		wrap.add_theme_constant_override("margin_top", 0)
		return wrap
	wrap.add_theme_constant_override("margin_top", 1)
	t.tween_method(func(v: float) -> void:
		if is_instance_valid(wrap):
			wrap.add_theme_constant_override("margin_top", int(round(v))), 1.0, 0.0, seconds)
	return wrap


# ---------------------------------------------------------------- the floor

## STAGE-03 / STAGE-09 / PIPE-02: the account, performed. Every line that names
## a figure fires the stage verb the Verb maps to (the table in this file's
## header comment and `VFX_FAMILY`); the verbs run on the stage's clock and
## hold themselves under reduced motion, so nothing here branches on it. The
## flourishes fire only while the account is being read LIVE (`_live`): a skip
## lands two hundred lines in one frame, and two hundred bursts is not a fight
## (G08). A death is a destination, not a flourish — it lands on a skip too,
## so the floor after "Skip to the end" shows who fell.
func _stage_verbs(e) -> void:
	if _stage_node == null or not is_instance_valid(_stage_node):
		return
	match e.verb:
		Enums.Verb.STATE_CHANGE:
			if LogPlayer.is_death(e):
				_death_beat(String(e.actor_id))
		Enums.Verb.ATTACK:
			if _live:
				_attack_beat(e)
			_boss_death_beat()
		Enums.Verb.HEAL:
			if _live:
				_heal_beat(e)
		Enums.Verb.MECHANIC:
			if _live:
				_mechanic_beat()
		Enums.Verb.MISTAKE:
			if _live:
				_fumble_beat(String(e.actor_id))


## The figure a line's actor is: a raider by id, or the boss for the enemy
## side (the one creature on the floor stands for every enemy name).
func _actor_sprite(e) -> Node2D:
	var id := String(e.actor_id)
	if not id.is_empty():
		var spr = _party_sprites.get(id, null)
		return spr if spr != null and is_instance_valid(spr) else null
	if String(e.actor_name).is_empty():
		return null
	if _boss_sprite != null and is_instance_valid(_boss_sprite):
		return _boss_sprite
	return null


## The middle of a figure's body in stage space: between its head (the stage's
## one anchor, `head_of`) and its feet (its position). Where a strike lands.
func _body_of(spr: Node2D) -> Vector2:
	return (_stage_node.head_of(spr) + spr.position) * 0.5


## The boss's eye: the upper quarter of its body — every one of the six slices
## carries its eye/mouth cluster there (J2).
func _eye_of(spr: Node2D) -> Vector2:
	var head: Vector2 = _stage_node.head_of(spr)
	return head + (spr.position - head) * 0.25


## The VFX family a line's actor fights in (VFX_FAMILY by role; the boss's own).
func _family_of(e) -> Dictionary:
	if String(e.actor_id).is_empty():
		return BOSS_FAMILY
	var r = _raider_by_id.get(String(e.actor_id), null)
	var cd = _db.class_of(r.class_id) if r != null and _db != null else null
	var role := Enums.role_key(int(cd.role)) if cd != null else ""
	return VFX_FAMILY.get(role, VFX_FAMILY["melee_dps"])


## ATTACK: the attacker lunges toward the target; the family's strike lands on
## the target's body at the target's own scale (a slash arc + burst, or a bolt
## that bursts where it lands); the target recoils away from the attacker and
## flashes (`hit`) — unless it has already fallen.
func _attack_beat(e) -> void:
	var attacker := _actor_sprite(e)
	var target := _target_sprite(e)
	if attacker == null and target == null:
		return
	var to: Vector2 = _body_of(target) if target != null else Vector2.ZERO
	if attacker != null:
		_stage_node.act(attacker, "attack", {"toward": to} if target != null else {})
	if target == null:
		return
	var from: Vector2 = _body_of(attacker) if attacker != null else to + Vector2(-64, 0)
	var sc: float = maxf(1.0, target.scale.y)
	var fam := _family_of(e)
	var kind := String(fam.get("kind", "impact"))
	match String(fam.get("attack", "slash")):
		"bolt":
			_stage_node.bolt(from, to, kind, {"scale": sc})
		"slash":
			_stage_node.slash(to, {"flip": from.x > to.x, "scale": sc})
			_stage_node.burst(to, kind, {"scale": sc})
		_:
			_stage_node.burst(to, kind, {"scale": sc})
	var fallen := not String(_raider_state.get(String(e.target_id), "")).is_empty()
	if target == _boss_sprite or not fallen:
		_stage_node.hit(target, {"from": from})


## HEAL: the healer casts (a rise and an emissive lift); the family's support
## burst — the sparkle — lands on whoever was healed.
func _heal_beat(e) -> void:
	var healer := _actor_sprite(e)
	var target := _target_sprite(e)
	if healer != null:
		_stage_node.act(healer, "cast", {})
	if target != null:
		_stage_node.burst(_body_of(target), String(_family_of(e).get("support", "heal")),
			{"scale": maxf(1.0, target.scale.y)})


## MECHANIC: the boss's eye flares — a void burst at the eye; the one-frame
## modulate flash and the affix cell's lift are `_line_effects`' (UI layer).
func _mechanic_beat() -> void:
	if _boss_sprite == null or not is_instance_valid(_boss_sprite):
		return
	_stage_node.burst(_eye_of(_boss_sprite), MECHANIC_BURST, {"scale": maxf(1.0, _boss_sprite.scale.y)})


## STATE_CHANGE dead: the stage's `death` — the grey and the 45° topple, kept.
func _death_beat(id: String) -> void:
	var spr = _party_sprites.get(id, null)
	if spr == null or not is_instance_valid(spr):
		return
	if _stage_node.act(spr, "death", {}):
		_dying[id] = _clock + float(SceneStage.ACTS["death"]["ms"]) / 1000.0


## The boss topples once its bar reaches zero (the same reading that greys it).
func _boss_death_beat() -> void:
	if _boss_fallen or _enemy_max <= 0:
		return
	var left := 0
	for nm in _enemy_hp:
		left += int(_enemy_hp[nm])
	if left > 0:
		return
	_boss_fallen = true
	if _boss_sprite != null and is_instance_valid(_boss_sprite):
		_stage_node.act(_boss_sprite, "death", {})


## MISTAKE: the offender fumbles toward the boss (STAGE-09's beat: commit,
## freeze with the "!" over the head, tilt, recover) — where the comedy lands.
func _fumble_beat(id: String) -> void:
	var spr = _party_sprites.get(id, null)
	if spr == null or not is_instance_valid(spr):
		return
	var opts := {}
	if _boss_sprite != null and is_instance_valid(_boss_sprite):
		opts["toward"] = _body_of(_boss_sprite)
	_stage_node.act(spr, "fumble", opts)


## KIT-07 Table A's log kinds for an entry, the key `Icons.at("log", …)` takes.
func _log_kind(e) -> String:
	match e.verb:
		Enums.Verb.MISTAKE:
			return "mistake"
		Enums.Verb.STATE_CHANGE:
			return "mistake"
		Enums.Verb.HEAL:
			return "heal"
		Enums.Verb.ATTACK:
			return "raider_attack" if not String(e.actor_id).is_empty() else "boss_attack"
		Enums.Verb.MECHANIC:
			return "mechanic"
		Enums.Verb.PHASE:
			return "phase"
		_:
			return "mistake" if LogPlayer.is_wipe_line(e) else "system"


## COMBAT-06's age ramp (spec 02 §2.2): the two newest rows at full opacity,
## everything older at 0.75. A row is a log row or a joke's indent.
func _age_rows(newest: Control) -> void:
	_log_rows.append(newest)
	var n := _log_rows.size()
	for i in n:
		var r = _log_rows[i]
		if not is_instance_valid(r):
			continue
		r.modulate = Color(1, 1, 1, 1.0 if i >= n - 2 else LOG_AGE_ALPHA)


## COMBAT-02 / PIPE-01: the number over the struck figure — the kit's Label
## (value set once, never tweened) placed by the stage over the head and
## staggered +14px per number already up there, then risen and faded through
## the one door. A raider's harm is DANGER, a crit CRIT, a heal POSITIVE; harm
## to the enemy side is the body cream (no pure white). Only while the account
## is being read live — a skip would land two hundred labels in one frame.
func _number(e) -> void:
	if not _live or _stage_node == null or not is_instance_valid(_stage_node):
		return
	if e.verb != Enums.Verb.ATTACK and e.verb != Enums.Verb.HEAL:
		return
	if not e.numbers.has("amount"):
		return
	var amount: int = e.number("amount")
	if amount <= 0:
		return
	var target := _target_sprite(e)
	if target == null:
		return
	var kind := "hit"
	if e.verb == Enums.Verb.HEAL:
		kind = "heal"
	elif bool(e.numbers.get("crit", false)):
		kind = "crit"
	var l := Widgets.damage_number(amount, kind)
	l.remove_theme_color_override("font_color")
	if kind == "hit" and String(e.target_id).is_empty():
		# UI-34: the party's own damage on the boss wears `LabelDamageDealt`
		# (a warm CTA_TOP tone at Type.DAMAGE — W7-STAGE registers it), so the
		# two directions read as two colours. A string-named variation falls
		# back to the base Label when the theme lacks it, which would drop the
		# damage size too — so the name is set only once the theme carries it
		# and the body-cream override stands until then.
		var th: Theme = Theme_.get_theme()
		if th != null and th.get_type_variation_base("LabelDamageDealt") != &"":
			l.theme_type_variation = "LabelDamageDealt"
		else:
			l.add_theme_color_override("font_color", Palette.TEXT_BODY)
	_stage_node.number_at(target, l)
	# Over any bubble already up: the number lives 600 ms, a bubble 2.4 s, and
	# a number under a plate is a number nobody saw.
	l.z_index = 1
	Widgets.number_rise(l)


## COMBAT-03: the mistake's joke over the offender's head for `Motion.BUBBLE`
## milliseconds, through the stage so the plate hangs where the numbers and
## bars do. Appearing is not motion (the hold runs under reduced motion too —
## the words are information); a skip shows none, the log has the line.
func _bubble(actor_id: String, line: String) -> void:
	if not _live or _stage_node == null or not is_instance_valid(_stage_node):
		return
	var spr = _party_sprites.get(String(actor_id), null)
	if spr == null or not is_instance_valid(spr):
		return
	_stage_node.say_at(spr, line, Widgets.Motion.BUBBLE)


## [text tone, badge tone] per line class (02 §2.2): raider harm is red, a heal
## green, the boss's own swings amber, mechanics arcane, everything else quiet.
func _row_style(e) -> Array:
	match e.verb:
		Enums.Verb.MISTAKE:
			return [Palette.DANGER, Palette.DANGER]
		Enums.Verb.STATE_CHANGE:
			return [Palette.DANGER, Palette.DANGER]
		Enums.Verb.HEAL:
			return [Palette.TEXT_LOG, Palette.POSITIVE]
		Enums.Verb.ATTACK:
			return [Palette.TEXT_LOG,
				Palette.INFO if not e.actor_id.is_empty() else Palette.CAUTION]
		Enums.Verb.MECHANIC:
			return [Palette.TEXT_LOG, Palette.ARCANE]
		Enums.Verb.PHASE:
			return [Palette.TEXT_SLATE, Palette.EDGE_SLATE]
		_:
			if LogPlayer.is_wipe_line(e):
				return [Palette.DANGER, Palette.DANGER]
			# LOOP-12: the cause line reads in the wipe's own ink — it is the
			# verdict, and the entry the report's sentence names.
			if e.verb == Enums.Verb.SYSTEM and String(e.template_id) == "wipe_cause":
				return [Palette.DANGER, Palette.DANGER]
			return [Palette.TEXT_MUTED_WARM, Palette.TEXT_MUTED]


## docs/13 §11.3's header — `Mistake name — Raider, Severity` (UI-19: the type
## leads). The one rule lives in `LogPlayer.mistake_header` so the report
## prints the same line (CRITIC-C2).
func _mistake_header(e) -> String:
	return LogPlayer.mistake_header(e)


func _body_text(e) -> String:
	return e.describe().trim_prefix("[R%02d]" % e.round_no).strip_edges()


# ---------------------------------------------------------------- row geometry

## How many lines `text` takes wrapped at `width` in `font` at `px` — the same
## break the Label makes (`AUTOWRAP_WORD_SMART`), computed here so the row's
## pitch is known when the row is built and so a test outside a tree (where a
## Label never lays out) can check the same arithmetic the screen used.
static func text_lines(font: Font, px: int, text: String, width: float) -> int:
	if font == null or text.is_empty():
		return 1
	var tp := TextParagraph.new()
	tp.width = maxf(1.0, width)
	tp.break_flags = TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE | TextServer.BREAK_MANDATORY
	tp.add_string(text, font, px)
	return maxi(1, tp.get_line_count())


## The column's width once the theme's scrollbar is up — the narrower of the
## scroll's two states, so a row measured against it is never cut when the
## bar arrives (it does, by the eighth line of any account).
func _log_inner_width() -> float:
	var w: float = LOG_RECT.size.x - 16.0
	if _scroll != null and is_instance_valid(_scroll):
		var bar := _scroll.get_v_scroll_bar()
		if bar != null:
			w -= bar.get_combined_minimum_size().x
	return w


## The width the row's expanding Label gets: the column less every other cell
## at its minimum and the row's separations.
func _row_text_width(row: HBoxContainer, label: Control) -> float:
	var w := _log_inner_width()
	var sep: float = float(row.get_theme_constant("separation"))
	for c in row.get_children():
		if c == label or not (c is Control):
			continue
		w -= (c as Control).get_combined_minimum_size().x
	w -= sep * float(maxi(0, row.get_child_count() - 1))
	return maxf(1.0, w)


## docs/13 §11.1: auto-scroll must never block incoming lines, and free drag to
## read back resumes on release. Whether the reader is at the bottom is read
## NOW, before the container has measured the new row — the scrollbar's range
## is still the one they were looking at, however many rows this frame lands
## (`_on_skip` lands two hundred; the shot tool's `--advance=N` feeds N lines'
## worth of `_process` in one frame and then freezes `_process`, so nothing
## here may wait for a later frame). If they were, the view sticks to the
## bottom: it is pinned once deferred, once more a deferred call later, and on
## every change of the range until the reader drags away (`_stick`).
func _autoscroll() -> void:
	if _scroll == null or not is_instance_valid(_scroll):
		return
	var bar := _scroll.get_v_scroll_bar()
	if bar == null:
		return
	if not _stick and not _at_bottom(bar):
		return
	_stick = true
	if _follow_queued:
		return
	_follow_queued = true
	call_deferred("_follow_bottom")


## "At the bottom" with a row's grace: a Range clamps its value to
## max - page, and one row of drift is the reader still reading the end.
func _at_bottom(bar: Range) -> bool:
	return bar.value >= bar.max_value - bar.page - 24.0


## UI-35: the end of the account, snapped DOWN to a row boundary. Every row
## is a whole number of pitches and the viewport is LOG_VISIBLE_ROWS of them,
## so the end IS a boundary; the snap is the guard for a column something
## else has put a stray height into (a Range clamps upward to `max - page`,
## so rounding up could not be trusted to land on a row).
func _scroll_to_end() -> void:
	if _scroll == null or not is_instance_valid(_scroll):
		return
	var bar := _scroll.get_v_scroll_bar()
	if bar != null:
		_scroll.scroll_vertical = snap_scroll(bar.max_value - bar.page)


## `v` rounded down to a multiple of the row pitch.
static func snap_scroll(v: float) -> int:
	var pitch: int = Widgets.LOG_ROW_PITCH
	return int(floor(maxf(0.0, v) / float(pitch))) * pitch


func _follow_bottom() -> void:
	_follow_queued = false
	if not _stick:
		return
	_scroll_to_end()
	# The container measures the new rows in its own deferred pass; settle once
	# more after it so the pin lands on the real end, not the old one.
	call_deferred("_settle_follow")


func _settle_follow() -> void:
	if _stick:
		_scroll_to_end()


## The range grew (a row was measured) or shrank (the column was cleared):
## while the reader rides the bottom, keep them there.
func _on_log_range_changed() -> void:
	if _stick:
		_scroll_to_end()


## A value below the bottom can only be the reader's own drag (this screen
## only ever pins to the end), so it releases the follow until they are back.
func _on_log_value_changed(value: float) -> void:
	if _scroll == null or not is_instance_valid(_scroll):
		return
	var bar := _scroll.get_v_scroll_bar()
	if bar != null and value < bar.max_value - bar.page - 24.0:
		_stick = false


# ---------------------------------------------------------------- test seams

func player():
	return _player


func mistakes_seen() -> int:
	return _mistakes_seen


func current_tier() -> int:
	return _tier
