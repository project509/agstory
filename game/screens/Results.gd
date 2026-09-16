extends Control
## S12 — Results (docs/13 §5).
##
## ✅ CANON's title is *It's A Wipe!* and its thesis is that failure is content:
## a wipe has to be readable as a story, not reported as a score. So this screen
## leads with what happened in words — the encounter's own comedy line, the
## outcome, and the story-tier log the sim already produced — and puts the
## numbers underneath.
##
## docs/07 §2 and docs/15 Q-09: the player never had input during the fight, so
## this screen is where the decision they DID make (who they brought) is
## reconciled with what it cost. That is why the mistake count and the fallen
## are given by name.
##
## The loot window lives here because docs/09 §14.3 says it opens ONCE at the end
## of the raid — one list, all drops — rather than per encounter. That doc's
## resolution is Option A (the player assigns) with Option B (need-based) offered
## as a one-click **Suggested** default, and this screen implements exactly that:
## every row can be overridden, and a row that helps nobody is left alone rather
## than forced onto someone.
##
## SELL is live now that docs/11 §5-§6's valuation formula is implemented
## (`sim/core/Economy.gd`). Every price shown here is that formula at the guild's
## current reputation rank, so the number on the button is the number paid.
##
## The morale ledger is M3 (the docs/05 trigger table), and so is the wishlist
## collision docs/05 §7.3 prices at -7 morale for selling a wanted item.
##
## ART PASS — archetype B-end (10 §3.11): Concept 2's frame with the battle
## stage replaced by the outcome. No rail, no chips: the compact header and a
## report block top-left (02 §4), the arena plate dimmed behind a centred steel
## panel that holds the headline, the tally, the fallen and the loot window, and
## the kit's bottom strip (`Cards.roster_strip`, which pages itself — COMBAT-19)
## carrying the party as cards — the fallen greyed and stamped — with "What
## happened" in the combat log's position. Every asserted string stays in a
## Label or Button (10 §5).
##
## WAVE 2 (00-plan §3 W2-RESULTS): the right column reconciles the party by
## name — a by-raider tally of blots, morale and who stood (COMBAT-11) — the
## loot column never offers what it does not have (COMBAT-22), the compact
## header fits its plate (COMBAT-12), the rank sigil files the day line
## (COMBAT-18), the story rows carry the log glyphs (COMBAT-06) and the wipe
## headline and the FALLEN tag are docs/13 §7 stamps (COMBAT-08).

const Widgets = preload("res://game/ui/Widgets.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Icons = preload("res://game/ui/Icons.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Services = preload("res://game/core/Services.gd")
const LogPlayer = preload("res://game/core/LogPlayer.gd")
## For `fold_height` only — the one arithmetic behind a scroll whose fold
## lands on a block boundary (W5-SCALE's `_snap_fold`), reused rather than
## re-derived here (UI-23: the report's fold snaps to a row).
const Guildhall = preload("res://game/screens/Guildhall.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Loot = preload("res://sim/core/Loot.gd")
const Economy = preload("res://sim/core/Economy.gd")
const Consumables = preload("res://sim/core/Consumables.gd")
const Reputation = preload("res://sim/core/Reputation.gd")

const BOARD := "res://game/screens/AdventureBoard.tscn"
const TOWN := "res://game/screens/Town.tscn"
## UI-37 / the attempts ruling (RULINGS §2 #6): "Try again" re-chalks the same
## encounter — the plan is still in `GameState.selected_encounter_id`, the way
## the Board pins it before it pushes prep.
const RAID_PREP := "res://game/screens/RaidPrep.tscn"
## S17 (docs/13 §5, spec in §9.5). Reached from here and, once it has been read,
## from the Guildhall's Records tab — docs/15 BL-73.
const COMPLETION := "res://game/screens/Completion.tscn"
const ICON := "res://game/assets/ui/icons/"
const PORTRAIT := "res://game/assets/portraits/"
## 09 §3.3's full-bleed cleaned arena has arrived, and it is the bare plate the
## designer supplied on 2026-09-11 rather than a painted-out crop: this screen
## used to name `raid_void.png`, a file that never existed (audit m4t-11), and
## fall back to centring the framed-scene crop. Which arena is `Q-96`, so the
## name lives once, in `SceneStage.DEFAULT_ARENA`.
##
## The offset matches RaidView's exactly, and that is the point: Results is the
## paperwork filed after the fight, so it is filed in the room the fight was in.
const ARENA_OFFSET := Vector2(0, -280)

## 09 §4.3: Results shows the arena DIMMED, so the report on top stays the thing
## being read. The report panel here is 820x616 and centred, so this takes more
## light out than raid prep's 0.62 does.
const SCENE_DIM := Color(0.55, 0.55, 0.62)

## How many story lines to print. The full log is always available to tooling;
## this is the readable account, not the transcript.
const MAX_STORY_LINES := 40

## COMBAT-20 / Q12b, RULED (docs/15 BL-139): the encounter's comedy line is
## canon content written to `target_rounds` ("Twenty-two rounds…"), and the
## tally on the same card prints the rounds the attempt actually ran. The
## ruling is option (b): the line stays on EVERY Results page as the notice's
## epigraph under the eyebrow EPIGRAPH_EYEBROW — the board said what was
## supposed to happen, the report says what did, and the distance is the joke.
##   "epigraph" — the line, always, labelled as the notice's (shipped).
##   "as_built" — the line, always, unlabelled (the pre-ruling behaviour).
##   "promise"  — COMBAT-20's option (a): the line only when the attempt ran at
##                least `target_rounds`, so it never contradicts the tally.
## Option (c) (outcome-aware lines) is a content decision and is not switched.
const COMEDY_LINE := "epigraph"
const EPIGRAPH_EYEBROW := "The notice said:"

## UI-37 / the attempts ruling (RULINGS §2 #6, docs/15 BL-139 carries the
## record): attempts are unlimited and committed at Depart, so the wipe page
## offers "Try again" — docs/13 §11.4's default-focused paper button — routing
## to prep with the same encounter pinned. `false` is the recorded alternative
## (a limited-attempts ruling): the button is not built and the exits stand.
const TRY_AGAIN := true
## docs/01's ledger for the attempt, under the button: what trying costs.
const TRY_AGAIN_COST := "costs a day and the provisions you chalk"
## The plate's width. `Widgets.cta` sizes a plate to the WORD on it and anchors
## the cost line across that width, so a cost line longer than its word paints
## straight over the button beside it (seen on the first shot, and the reason
## `_fit_cost_line` exists at all): the plate takes a width the sentence can
## wrap inside, and the exits flow stacks rather than widening the panel.
const TRY_AGAIN_W := 244.0

## LOOP-12: the sentence under the wipe stamp when the sim named nobody — a
## loss with no Severe mistake before the first tank or healer death and no
## cascade (docs/07 §7's rule, `RaidSim._wipe_cause`).
const NOBODY_LINE := "Nobody in particular. The boss simply won."

## UI-36: the clear's stamp and seal wear the ready gold, not the wipe's red —
## the same wax, a different verdict. The seal rests on the report panel's
## lower-right corner the way the wipe's rests on the log's (COMBAT-15).
const CLEAR_TONE := Palette.EDGE_READY_GOLD

## 02 §0/§1: Concept 2's frame. The stage is everything above y 735; the strip
## is the 289 px below it. Every rect is a measured framebuffer coordinate.
## The report panel is this screen's own (the concept has the arena there): it
## top-aligns with the report block at y 88 and stops 13px short of the strip,
## which is the height a twelve-body wipe needs once the right column carries
## the by-raider tally AND its exits without scrolling (COMBAT-11).
const STAGE_H := 735
const STRIP_H := 289
const HEADER_RECT := Rect2(0, 0, 352, 64)
const REPORT_RECT := Rect2(0, 88, 352, 106)
const PANEL_RECT := Rect2(358, 88, 820, 634)
const PANEL_PAD := 14
## The clear's seal (UI-36) straddles the report panel's lower-right corner:
## the 72px seal's centre on the panel's bottom edge, its right edge 12px
## inside the panel's — the wipe's `WAX_SEAL_REST` rule, on this page's paper.
const CLEAR_SEAL_REST := Vector2(1094, 686)
## The loot column's two acts (UI-36): the plate each one needs to read, and
## the width its reason line wraps at. Both are needed because the acts sit in
## a flow — a flow packs by MINIMUM width, so a control that declares none is
## squeezed into whatever the row has left (see `_wrapped_reason`).
const LOOT_ACT_W := 196.0
const LOOT_REASON_W := 300
const EMPTY_RECT := Rect2(508, 250, 520, 200)
const LEFT_COL_W := 392
## The strip host sits where Frame puts the hub's (x 13-14): the kit's strip
## draws its Available panel, four cards and gutter arrows at spec 10 §2 R1's
## screen pixels from there, and the log keeps Concept 2's slot at 1064.
const STRIP_X := 14
const CARD_Y := 6                 # strip-local; y 741 on the frame
const LOG_RECT := Rect2(1064, 6, 454, 262)
const FALLEN_TINT := Color(0.46, 0.48, 0.54)
const FALLEN_STAMP_AT := Vector2(14, 58)   # card-local: over the portrait's lower half
## The by-raider tally's row: a 24px portrait, and the blot glyph beside the
## count (COMBAT-09's three silhouettes, picked by name so a column of rows
## does not tile).
const TALLY_PORTRAIT := 24
const BLOT_KEYS := ["a", "b", "c"]

var _router = null
var _state = null
var _built := false
var _loot_host: VBoxContainer = null
var _loot_controls: VBoxContainer = null
var _handed_out := false
var _tally_host: VBoxContainer = null
var _flask_host: VBoxContainer = null
var _flask_notice := ""
var _strip_host: Control = null
var _card_host: Control = null
var _page := 0
## `EventLog` mistake id ("actor:rN:TYPE", `Mistakes.MistakeEvent.id()`) →
## the story entry, so a cascaded mistake's `caused_by` resolves to a name.
var _mistake_index: Dictionary = {}
## UI-24: the morale delta every raider shares this attempt (a wipe's flat
## penalty), or null when the column carries information. Set by
## `_refresh_by_raider`, read by `_refresh_morale`, which runs after it.
var _flat_delta = null
## UI-23: the report's log scroll and the spacer that snaps its fold to a row.
var _report_scroll: ScrollContainer = null
var _report_rows: VBoxContainer = null
var _report_spacer: Control = null
## UI-33 / UI-37: the two controls `default_focus()` can answer with — the
## wipe's "Try again" and the clear's suggested-split commit.
var _try_again: Button = null
var _split_cta: Button = null
## UI-36: the clear's stamp box (pressed on build) and its wax seal.
var _clear_stamp: Control = null
var _clear_seal: TextureRect = null
## LOOP-12: the raider `result.wipe_cause` names, so the tally can mark the row.
var _culprit_id := ""


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
    _build()


func _build() -> void:
    add_child(Widgets.ground())
    _stage()
    _header()

    var result = _state.last_result if _state != null else null
    var enc = null
    if result != null and _state.content != null:
        enc = _state.content.encounter(result.encounter_id)

    _report_block(result, enc)
    _strip_plate()
    if result == null:
        _empty_panel()
        _log_panel(null)
        return

    _outcome_panel(result, enc)
    _log_panel(result)
    _refresh_strip()
    if result.cleared():
        _drop_clear_seal()


## UI-33 / CRITIC-R4: where the keyboard lands. docs/13 §11.4 names it for
## the wipe ("`Try again` is left and default-focused"); on a clear the page's
## one commit is the loot's suggested split. The router asks by name and
## falls back to reading order when the answer is null or disabled.
func default_focus() -> Control:
    if _try_again != null and is_instance_valid(_try_again):
        return _try_again
    if _split_cta != null and is_instance_valid(_split_cta) and not _split_cta.disabled:
        return _split_cta
    return null


# ---------------------------------------------------------------- the frame

## 02 §7: the stage is the whole viewport above the strip — the arena the party
## just fought in, still burning, with the report filed over it.
func _stage() -> void:
    var result = _state.last_result if _state != null else null
    var enc = null
    if result != null and _state != null and _state.content != null:
        enc = _state.content.encounter(result.encounter_id)
    var stage := SceneStage.load(SceneStage.arena_for(enc))
    stage.position = ARENA_OFFSET
    stage.size = Vector2(Widgets.SCREEN.x, STAGE_H) - ARENA_OFFSET
    stage.modulate = SCENE_DIM
    add_child(stage)


## 02 §4.1: Concept 2's compact header — emblem and wordmark on a short plate,
## nothing else. The chips and the rail belong to archetype A.
func _header() -> void:
    var plate := ColorRect.new()
    plate.color = Palette.GROUND_FRAME
    plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(plate)
    plate.position = HEADER_RECT.position
    plate.size = HEADER_RECT.size

    var rule := ColorRect.new()
    rule.color = Palette.EDGE_RAIL
    rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(rule)
    rule.position = Vector2(0, HEADER_RECT.end.y)
    rule.size = Vector2(HEADER_RECT.size.x, 1)

    # COMBAT-12: the 0.76 mark at x 96, baseline 48, and the 65px skull crop —
    # Frame's compact lockup, whose right edge stays inside the 352 plate.
    Frame.draw_lockup(self, "33_compact")


## 02 §4.2's objective block, repurposed: this is the report's own filing line.
## Three Labels — the title, the day and standing, the attempt number — all of
## them numbers the game really keeps (10 §2: nothing invented). COMBAT-18: the
## standing word alone read as an unfilled field, so the rank sigil the header
## chips use (`Icons.at("rank", key)`) files it — the Label's text is untouched.
func _report_block(result, enc) -> void:
    var plate := ColorRect.new()
    plate.color = Color(Palette.SURFACE_PANEL, 0.9)
    plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(plate)
    plate.position = REPORT_RECT.position
    plate.size = REPORT_RECT.size
    for y in [REPORT_RECT.position.y, REPORT_RECT.end.y - 1]:
        var r := ColorRect.new()
        r.color = Palette.EDGE_RAIL
        r.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(r)
        r.position = Vector2(0, y)
        r.size = Vector2(REPORT_RECT.size.x, 1)

    # The three lines stack in a column so a larger text scale spaces them by
    # their own heights instead of colliding at fixed y (CRITIC-G15).
    var lines := Widgets.column(4)
    lines.name = "Filing"
    lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(lines)
    lines.position = Vector2(20, 96)
    lines.size = Vector2(REPORT_RECT.size.x - 40, 0)
    lines.add_child(Widgets.label_as("Raid report", "LabelObjective"))

    var line := "No guild loaded."
    var detail := ""
    var sigil: Texture2D = null
    if _state != null:
        line = "Day %d  ·  %s" % [_state.day, _state.rank_name()]
        sigil = Icons.at("rank", String(_state.rank_name()).to_lower())
        if result == null:
            detail = "•  Nothing has been run yet."
        elif enc != null:
            detail = "•  Attempt %d at %s" % [_state.attempt_count(enc.id), enc.slot]
    var filed := Widgets.row(8)
    filed.name = "Filed"
    filed.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lines.add_child(filed)
    if sigil != null:
        # Native 28px (the grid's rank cell): a 16px downscale of a pixel
        # sigil blurs, and the 28px row still clears the attempt line at 160.
        var t := TextureRect.new()
        t.name = "RankSigil"
        t.texture = sigil
        t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
        t.custom_minimum_size = Vector2(Icons.size("rank"), Icons.size("rank"))
        t.mouse_filter = Control.MOUSE_FILTER_IGNORE
        filed.add_child(t)
    var l := Widgets.label_as(line, "LabelBody")
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    filed.add_child(l)
    if not detail.is_empty():
        lines.add_child(Widgets.label_as(detail, "LabelSmall"))


## 02 §0: the strip is a full-width plate with a 2 px top edge, over a 1 px seam.
func _strip_plate() -> void:
    _strip_host = Control.new()
    _strip_host.name = "Strip"
    _strip_host.clip_contents = true
    _strip_host.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(_strip_host)
    _strip_host.position = Vector2(0, STAGE_H)
    _strip_host.size = Vector2(Widgets.SCREEN.x, STRIP_H)

    var plate := ColorRect.new()
    plate.color = Palette.GROUND_FRAME
    plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _strip_host.add_child(plate)
    plate.position = Vector2(0, 1)
    plate.size = Vector2(Widgets.SCREEN.x, STRIP_H - 1)

    var edge := ColorRect.new()
    edge.color = Palette.EDGE_RAIL
    edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _strip_host.add_child(edge)
    edge.position = Vector2(0, 1)
    edge.size = Vector2(Widgets.SCREEN.x, 2)

    # The kit's strip host: `Cards.roster_strip` lays the Available panel, the
    # cards and its own gutter arrows out from here at spec 10 §2 R1's pixels.
    _card_host = Control.new()
    _card_host.name = "Cards"
    _card_host.mouse_filter = Control.MOUSE_FILTER_PASS
    _strip_host.add_child(_card_host)
    _card_host.position = Vector2(STRIP_X, CARD_Y)
    _card_host.size = Vector2(Cards.PAGER_NEXT_X + Cards.PAGER_W, STRIP_H - CARD_Y)


# ---------------------------------------------------------------- the outcome

func _empty_panel() -> void:
    var panel := Widgets.panel("PanelSteel", 18)
    add_child(panel)
    panel.position = EMPTY_RECT.position
    panel.size = EMPTY_RECT.size
    var col := Widgets.column(8)
    col.add_child(Widgets.label_as("No attempt to report", "LabelSection"))
    var body := Widgets.label_as(
        "Nothing has been run yet. The board is where a raid starts.", "LabelBody")
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    col.add_child(body)
    col.add_child(Widgets.rule())
    col.add_child(_exit_row())
    Widgets.content_of(panel).add_child(col)


## The report itself: one steel panel in the stage, two columns. Left reads the
## story's shape (outcome, tally, fallen); right is the paperwork (loot, the
## mood, the exits). Each column scrolls on its own so a twelve-body wipe with
## three drops never grows the panel past its rect.
func _outcome_panel(result, enc) -> void:
    var panel := Widgets.panel("PanelSteel", PANEL_PAD)
    add_child(panel)
    panel.position = PANEL_RECT.position
    panel.size = PANEL_RECT.size
    panel.clip_contents = true

    var row := Widgets.row(24)
    # WITHOUT this the row is only as tall as its own minimum, so the two
    # ScrollContainers inside it are never given a bounded height — they grow to
    # their content instead of scrolling it, and the panel's `clip_contents`
    # turns the overflow into a row of raiders cut through the middle of their
    # names. A total wipe is twelve cells in a 4-wide flow, which is exactly
    # when it shows, and a wipe is the likeliest outcome in the tier that is
    # currently a wall.
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    Widgets.content_of(panel).add_child(row)
    var left := _scroll_column(row, LEFT_COL_W)

    # The right column: the paperwork scrolls when a big clear drops a long
    # list (a list of unknown length, and the bar is visible — LESSONS), but
    # the exits are PINNED under it, never below a fold. A twelve-body wipe
    # fits without scrolling at all; that is what PANEL_RECT is sized to.
    var right_wrap := Widgets.column(8)
    right_wrap.name = "RightColumn"
    right_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_child(right_wrap)
    var right := _scroll_column(right_wrap, 0)

    left.add_child(_headline(result, enc))
    left.add_child(Widgets.rule())
    var lesson := _lesson_line(result, enc)
    if lesson != null:
        left.add_child(lesson)
    left.add_child(Widgets.section("The tally"))
    left.add_child(_numbers(result, enc))
    left.add_child(Widgets.rule())
    left.add_child(Widgets.section("The fallen"))
    left.add_child(_fallen(result))

    right.add_child(_loot_section())
    right.add_child(Widgets.rule())
    right.add_child(_by_raider_section(result))
    right.add_child(Widgets.rule())
    right.add_child(_morale_section())
    right_wrap.add_child(Widgets.rule())
    right_wrap.add_child(_exit_row())


## A vertical-only ScrollContainer holding a column; `width` 0 = take the rest.
func _scroll_column(host: Container, width: int) -> VBoxContainer:
    var sc := ScrollContainer.new()
    sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    if width > 0:
        sc.custom_minimum_size = Vector2(width, 0)
    else:
        sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var col := Widgets.column(8)
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sc.add_child(col)
    host.add_child(sc)
    return col


func _headline(result, enc) -> Control:
    var box := Widgets.column(4)
    var word := _outcome_word(result)
    if result.cleared():
        # UI-36: the clear is the wipe's mirror — a filed report with a stamp
        # (docs/13 §7's word list has CLEARED), pressed with the same press
        # the wipe's gets, in the ready gold rather than the wipe's red. One
        # `ui.stamp` on the press (AUDIO-19: the clear's sound is the stamp
        # and the coin). The kit's tone names carry no gold, so the box is
        # built in the kit's shape and re-inked here.
        var stamp := Widgets.stamp_box("CLEARED", "positive")
        stamp.name = "Headline"
        stamp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        _ink_stamp(stamp, CLEAR_TONE)
        var t := stamp.get_child(0) as Label
        if t != null:
            t.add_theme_font_size_override("font_size",
                Type.at(Type.SECTION, Theme_.scale_of(self)))
        box.add_child(stamp)
        _clear_stamp = stamp
        var audio := Services.find(self, "Audio")
        if audio != null and audio.has_method("play"):
            audio.play("ui.stamp", {"pitch_scale": 1.0})
        # The press through the one door; a tween outside a tree answers null
        # and the stamp simply sits at 1.0 (arrive instantly, still arrive).
        Widgets.stamp_press(stamp)
        # The word canon uses for it, as a Label the tests still read.
        var said := Widgets.label_as(word, "LabelSmall")
        said.add_theme_color_override("font_color", Palette.TEXT_MUTED)
        box.add_child(said)
    else:
        # 06 §8 / docs/13 §7: the wipe is a rubber stamp — the kit's StampBadge
        # (COMBAT-08: rim, 2-7° lean, 85% ink), shrunk to its word so the tilt
        # turns the word and not the column. The text stays a Label.
        var stamp := Widgets.stamp_box(word, "danger")
        stamp.name = "Headline"
        stamp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        var t := stamp.get_child(0) as Label
        if t != null:
            t.add_theme_font_size_override("font_size",
                Type.at(Type.SECTION, Theme_.scale_of(self)))
        box.add_child(stamp)
        # LOOP-12: the one sentence under the stamp that says WHY — docs/01
        # §6.4's "the raider at fault, the specific mistake" in the round it
        # happened, then the excuse the log already quoted. Built from the
        # sim's own `wipe_cause` entry, never guessed here.
        var cause := Widgets.label_as(_cause_sentence(result), "LabelBody")
        cause.name = "WipeCause"
        cause.add_theme_color_override("font_color", Palette.TEXT_TITLE)
        cause.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        cause.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
        box.add_child(cause)
    if enc != null:
        box.add_child(Widgets.label_as("%s — %s" % [enc.slot, enc.display_name],
            "LabelName"))
        if _shows_comedy_line(result, enc):
            # BL-139 (Q12b as ruled): the line is the NOTICE's, and says so —
            # the eyebrow is what keeps a line about round 21 honest over a
            # tally that reads "Rounds 6". On every outcome.
            if COMEDY_LINE == "epigraph":
                var eyebrow := Widgets.label_as(EPIGRAPH_EYEBROW, "LabelMuted")
                eyebrow.name = "Eyebrow"
                box.add_child(eyebrow)
            var q := Widgets.label_as(enc.comedy_line, "LabelQuote")
            q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            box.add_child(q)
    return box


## Re-ink a kit stamp box in a tone the kit's names do not carry: the word and
## the rim, on a copy of the theme's frame so no other stamp changes colour.
static func _ink_stamp(box: PanelContainer, tone: Color) -> void:
    var word := box.get_child(0) as Label
    if word != null:
        word.add_theme_color_override("font_color", tone)
    var th: Theme = Theme_.get_theme()
    if th != null and th.has_stylebox("panel", "PanelStamp"):
        var copy: StyleBox = th.get_stylebox("panel", "PanelStamp").duplicate()
        if copy is StyleBoxTexture:
            (copy as StyleBoxTexture).modulate_color = tone
        box.add_theme_stylebox_override("panel", copy)
    else:
        box.add_theme_stylebox_override("panel", Theme_.flat(Color(0, 0, 0, 0), tone, 2, 3, 4))


## The wax seal is drawn in the wipe's crimson; the clear's is the same seal
## in the ready gold. A modulate only darkens (gold x crimson is mud), so the
## seal is re-inked by its own light: each pixel's luminance, in the tone.
## A static recolour, not an effect — it does not consult reduced_effects.
const GOLD_INK_SHADER := """
shader_type canvas_item;
uniform vec4 tone : source_color = vec4(1.0);
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    COLOR = vec4(tone.rgb * clamp(l * 3.2, 0.18, 1.15), c.a) * COLOR;
}
"""


static func _gold_ink(tone: Color) -> ShaderMaterial:
    var sh := Shader.new()
    sh.code = GOLD_INK_SHADER
    var m := ShaderMaterial.new()
    m.shader = sh
    m.set_shader_parameter("tone", tone)
    return m


## LOOP-12's sentence: "Round 4: Cindy — Healed a Corpse. "…the joke…"" from the
## entry `result.wipe_cause` points at, or NOBODY_LINE when the sim named no
## one. Reads the log through the recorded sequence, so the report and the
## live log's "It traces back to …" row name the same entry.
func _cause_sentence(result) -> String:
    _culprit_id = ""
    var e = _wipe_cause_entry(result)
    if e == null:
        return NOBODY_LINE
    _culprit_id = String(e.actor_id)
    var who := String(e.actor_name) if not String(e.actor_name).is_empty() else "Someone"
    var line := "Round %d: %s — %s." % [int(e.round_no), who, e.mistake_name()]
    var quip := String(e.joke()).strip_edges()
    if not quip.is_empty():
        line += ' "%s"' % quip
    return line


## The log entry `wipe_cause` names, or null: on a clear, on a loss nobody
## caused, on a result that carries no cause at all (an older stub).
static func _wipe_cause_entry(result):
    if result == null or result.log == null:
        return null
    var cause = result.get("wipe_cause")
    if not (cause is Dictionary) or (cause as Dictionary).is_empty():
        return null
    var seq: int = int(cause.get("entry_seq", -1))
    if seq < 0 or seq >= result.log.entries.size():
        return null
    var e = result.log.entries[seq]
    if e == null or not e.is_mistake():
        return null
    return e


## COMBAT-20's switch, read in one place. "epigraph" and "as_built" print the
## line whatever the attempt did; "promise" prints it only when the fight ran
## the rounds the line was written to, so the card never contradicts its own
## tally.
func _shows_comedy_line(result, enc) -> bool:
    if enc == null or String(enc.comedy_line).is_empty():
        return false
    if COMEDY_LINE == "promise":
        return int(result.rounds) >= int(enc.target_rounds)
    return true


## BL-141: the Tutorial Raid's WIPE page says what the page IS — the record's
## `lesson_report`, above the tally, on that branch only (over a clear it
## would be false). Null everywhere else; the words are the record's.
func _lesson_line(result, enc) -> Control:
    if enc == null or result == null or result.cleared():
        return null
    if not Reputation.is_tutorial_slot(String(enc.slot)):
        return null
    var line := String(enc.lesson_report)
    if line.is_empty():
        return null
    var p := Widgets.panel("PanelCalloutPositive", 8)
    p.name = "LessonReport"
    var l := Widgets.label_as(line, "LabelBody")
    l.name = "Lesson"
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    Widgets.content_of(p).add_child(l)
    return p


## UI-36: the clear's wax seal, in the ready gold, dropped onto the report
## panel's lower-right corner the way the wipe's lands on the log's — a short
## fall through the one door (zero under reduced motion: the seal carries
## state, the fall does not). Added to the SCREEN after the panel so it sits
## on the paper's edge rather than inside its clip.
func _drop_clear_seal() -> void:
    var tex = load("res://game/assets/ui/wax_seal.png") \
        if ResourceLoader.exists("res://game/assets/ui/wax_seal.png") else null
    if tex == null:
        return
    _clear_seal = TextureRect.new()
    _clear_seal.name = "ClearSeal"
    _clear_seal.texture = tex
    _clear_seal.material = _gold_ink(CLEAR_TONE)
    _clear_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_clear_seal)
    _clear_seal.size = tex.get_size()
    var settings = Services.find(self, "GameSettings")
    var seconds := 0.18
    if settings != null:
        seconds = settings.motion_duration(180)
    _clear_seal.position = CLEAR_SEAL_REST - Vector2(0, 18.0 if seconds > 0.0 else 0.0)
    var t := Widgets.tween(_clear_seal)
    if t != null:
        t.set_ease(Tween.EASE_OUT)
        t.tween_property(_clear_seal, "position", CLEAR_SEAL_REST, seconds)
    else:
        _clear_seal.position = CLEAR_SEAL_REST


## The four outcomes the sim can return, in the register canon uses.
func _outcome_word(result) -> String:
    match result.outcome_key():
        "victory":
            return "Cleared."
        "wipe":
            return "It's a wipe!"
        "soft_wipe":
            return "Called it. Barely."
        "attrition":
            return "Ran out of everything."
    return result.outcome_key()


## The tally as a row of recessed stat cells; each figure stays one Label so the
## tests read "Rounds N" whole.
func _numbers(result, enc = null) -> Control:
    var flow := HFlowContainer.new()
    flow.add_theme_constant_override("h_separation", 8)
    flow.add_theme_constant_override("v_separation", 8)
    flow.add_child(_stat_cell("Rounds %d" % result.rounds))
    flow.add_child(_stat_cell("Mistakes %d" % result.mistake_count))
    if not result.consumables_unspent.is_empty():
        flow.add_child(_stat_cell("Provisions forgotten %d" % result.consumables_unspent.size()))
    flow.add_child(_stat_cell("Damage dealt %d  ·  Healing done %d"
        % [result.damage_dealt, result.healing_done]))
    flow.add_child(_stat_cell("Survivors %d of %d"
        % [result.survivors.size(),
           result.survivors.size() + result.casualties.size()]))
    if result.cleared() and enc != null:
        # LOOP-13: what the town heard. The same pure call GameState's award
        # makes (`Reputation.award_for`), fed this clear's number — the attempt
        # is recorded before this page opens, so `clear_count` already counts
        # it. A wipe pays nothing and prints nothing (a "+0" is a wall).
        var rp := reputation_earned(_state, enc)
        var cell := _stat_cell("Reputation +%d" % rp)
        cell.name = "ReputationCell"
        flow.add_child(cell)
    return flow


## The reputation the clear on this page paid: `Reputation.award_for` with the
## inputs `GameState._award_reputation` gives it — the clear's ordinal (the
## record is in, so the count is post-record; a first clear is 1), the highest
## unlocked tier and the stall flag. Read post-record, so the obsolescence
## factor sees the rank AFTER the award; only a clear that itself carries the
## rank across a tier-unlock boundary can differ from the feed, and then by
## reading low. No state field: this is arithmetic on facts the state keeps.
static func reputation_earned(state, enc) -> int:
    if state == null or enc == null:
        return 0
    var clear_number: int = maxi(1, int(state.clear_count(String(enc.id))))
    return Reputation.award_for(enc, clear_number, int(state.highest_unlocked_tier()),
        bool(state.stalled))


static func _stat_cell(text: String) -> Control:
    var p := Widgets.panel("PanelInset", 8)
    Widgets.content_of(p).add_child(Widgets.label_as(text, "LabelBody"))
    return p


## THE CELL SIZE IS THE FIX for a real defect: at 92px wide, four to a row, a
## total wipe is twelve cells in three rows, and the last row was cut through the
## middle of its own names by the report panel's `clip_contents`. Scrolling was
## already in place and did not save it — the column scrolls, so the overflow was
## merely hidden instead of legible, with no scrollbar to say so.
##
## A total wipe is not the corner case: it is the likeliest outcome of the tier
## that is currently a wall, and docs/13 §11.4 makes the fallen the payload of
## the wipe sequence. So the grid FITS instead of scrolling — a compact cell
## whenever more than six went down, which puts twelve in the space four used to
## take and keeps every name whole.
##
## The compact width is not a
## taste: LEFT_COL_W is 392, so 60 wide at 4px separation is exactly six to a row
## (6x60 + 5x4 = 380, and a seventh would need 448), which puts twelve in TWO
## rows. Three rows do not fit under the headline and the tally — measured on the
## shot, a row costs ~86px and only ~245px are left below "The fallen".
const FALLEN_CELL := Vector2i(92, 44)          ## roomy: width, portrait size
const FALLEN_CELL_COMPACT := Vector2i(60, 36)  ## more than six of them
const FALLEN_GAP := 8                          ## separation at the roomy size
const FALLEN_GAP_COMPACT := 4


## Which cell a party of this many dead gets. Static so the arithmetic in the
## comment above can be held by a test instead of by whoever remembers it.
static func fallen_metrics(count: int) -> Vector2i:
    return FALLEN_CELL_COMPACT if count > 6 else FALLEN_CELL


static func fallen_gap(count: int) -> int:
    return FALLEN_GAP_COMPACT if count > 6 else FALLEN_GAP


func _fallen(result) -> Control:
    if result.casualties.is_empty():
        return Widgets.empty_state("Everyone came home. This is unusual.")
    # `result` is a sim object, so its fields are untyped and `:=` cannot infer
    # through them (LESSONS.md).
    var fallen_count: int = result.casualties.size()
    var metrics := fallen_metrics(fallen_count)
    # CRITIC-G15: the cell is a text width, so it scales with the text — at
    # 150% a 60px compact cell wrapped "Warrior" mid-word. Identity at 100%
    # keeps test_results_screen's six-to-a-row arithmetic exact; at 125/150
    # the flow drops to five/four a row and the column scrolls with its bar.
    metrics.x = Type.at(metrics.x, Theme_.scale_of(self))
    var flow := HFlowContainer.new()
    flow.add_theme_constant_override("h_separation", fallen_gap(fallen_count))
    flow.add_theme_constant_override("v_separation", 8)
    for c in result.casualties:
        flow.add_child(_fallen_cell(c, metrics))
    return flow


## One of the dead: a bronze portrait cell over the name and the class. Two
## lines rather than "name — class" on one, because a compact cell is narrower
## than that sentence and a wrapped em dash reads as a typo.
func _fallen_cell(c, metrics: Vector2i) -> Control:
    var cell := Widgets.column(2)
    cell.custom_minimum_size = Vector2(metrics.x, 0)
    var slot := Widgets.slot(_portrait(c.raider if c != null else null),
        metrics.y, "SlotBronze")
    slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    cell.add_child(slot)
    var l := Widgets.label_as("%s\n%s" % [_combatant_name(c), _combatant_class(c)],
        "LabelSmall")
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.max_lines_visible = 3
    l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    l.custom_minimum_size = Vector2(metrics.x, 0)
    cell.add_child(l)
    return cell


## The reference face by name, else the class bust being produced in parallel,
## else an empty frame — never a wrong-class face.
func _portrait(raider) -> Texture2D:
    if raider == null:
        return null
    var face := Cards.portrait_for(raider)
    if face != null:
        return face
    var by_class := PORTRAIT + "class_%s.png" % Enums.class_key(int(raider.class_id))
    if ResourceLoader.exists(by_class):
        return load(by_class)
    return null


## A Combatant wraps the persistent Raider record (sim/model/Combatant.gd), so
## read through it rather than duck-typing the Combatant itself.
func _combatant_name(c) -> String:
    if c == null or c.raider == null:
        return "someone"
    return String(c.raider.display_name)


func _combatant_class(c) -> String:
    if c == null or c.raider == null:
        return "?"
    return Enums.class_name_of(int(c.raider.class_id))


# ---------------------------------------------------------------- loot

## docs/09 §14.3's loot window.
func _loot_section() -> Control:
    var box := Widgets.column(6)
    box.add_child(Widgets.section("Loot"))

    if _state == null:
        box.add_child(Widgets.faint("No guild loaded."))
        return box

    if _state.last_payout > 0:
        # UI-36: the payout is the clear's figure — `Type.gold` for the digits
        # (LOOP-21's one door) at the figure size, in the CTA's gold. Clipped
        # rather than widening the column at 150 (LESSONS: one uncapped Label).
        var payout := Widgets.label_as("Payout  %s" % Type.gold(_state.last_payout), "LabelCtaCost")
        payout.name = "Payout"
        payout.add_theme_font_size_override("font_size",
            Type.at(Type.FIGURE_XL, Theme_.scale_of(self)))
        payout.clip_text = true
        payout.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        box.add_child(payout)
        var note := Widgets.faint(
            "Selling what nobody can wear is the other half of the income.")
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        box.add_child(note)
    elif _state.last_result != null and _state.last_result.cleared():
        box.add_child(Widgets.faint("No payout this time."))
    # A wipe says it once, under the control it disables (below), not as a
    # third line above it (COMBAT-22's "three lines say there is nothing").

    # The two bulk controls and the rows are rebuilt together: a hand-out
    # empties the list, and a control that still offers to hand out what is
    # no longer there is COMBAT-22's defect in a second form.
    _loot_controls = Widgets.column(6)
    _loot_controls.name = "LootControls"
    box.add_child(_loot_controls)
    _loot_host = Widgets.column(6)
    _loot_host.name = "LootRows"
    box.add_child(_loot_host)

    # docs/09 §14.3 item 5: `auto_loot` "applies the suggestion silently for
    # players who want the fast path."
    var settings = Services.find(self, "GameSettings")
    if settings != null and bool(settings.get_value("auto_loot")):
        if not _state.pending_loot.is_empty():
            _handed_out = true
        _state.assign_suggested_loot()

    _refresh_loot()
    return box


func _refresh_loot() -> void:
    if _loot_host == null or _loot_controls == null or _state == null:
        return
    for host in [_loot_controls, _loot_host]:
        for c in host.get_children():
            host.remove_child(c)
            c.queue_free()

    var empty: bool = _state.pending_loot.is_empty()
    _split_cta = null

    # COMBAT-22: the one-click default is disabled WITH ITS REASON when there is
    # nothing to give — the reasoned treatment, a Label under the control, never
    # a tooltip (docs/13 §7; test_full_loop presses it only with loot pending).
    #
    # UI-36: with drops pending it is the page's ONE commit (06 §3's crimson,
    # spec 06 §4) — "Give as Suggested — N drops" — with "Sell all unusable"
    # beside it. Empty, it is the plain control with its reason: a crimson
    # button that cannot be pressed would be the wrong kind of loud, and on a
    # wipe the page's commit is "Try again".
    var drops: int = _state.pending_loot.size()
    var accept: Button
    if empty:
        accept = Widgets.button("Suggested — give everything")
    else:
        accept = Widgets.cta("Give as Suggested — %s" % Type.count(drops, "drop", "drops"))
        _split_cta = accept
    accept.name = "Suggested"
    accept.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if not empty:
        accept.pressed.connect(func() -> void:
            _handed_out = true
            _state.assign_suggested_loot()
            _refresh_loot())
    var why := ""
    if empty:
        if _handed_out:
            why = "Nothing left to hand out."
        elif _state.last_result != null and not _state.last_result.cleared():
            why = "Nothing dropped — nothing was cleared."
        else:
            why = "Nothing dropped."
    # A flow, not a row: beside each other when the column has the width,
    # stacked when it does not (150% text, or a long drop count) — the same
    # shape as the exits, so nothing here ever widens the panel.
    accept.custom_minimum_size.x = maxf(accept.custom_minimum_size.x, LOOT_ACT_W)
    var accept_box := _wrapped_reason(Widgets.reasoned(accept, why), LOOT_REASON_W)
    if empty:
        _loot_controls.add_child(accept_box)
        return
    var controls := HFlowContainer.new()
    controls.name = "LootActs"
    controls.add_theme_constant_override("h_separation", 8)
    controls.add_theme_constant_override("v_separation", 6)
    controls.add_child(accept_box)
    _loot_controls.add_child(controls)

    # docs/02 §6.3's sell-all helper. Only gear NOBODY on the roster can wear, so
    # it cannot quietly sell a sidegrade someone wanted. Only offered while
    # there is a list to sell from; its reason is the same treatment. Beside
    # the commit (UI-36), the secondary plate.
    var junk_value: int = _state.unusable_loot_value()
    var sell_all := Widgets.button("Sell all unusable  (+%s)" % Type.gold(junk_value))
    sell_all.name = "SellAll"
    sell_all.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if junk_value > 0:
        sell_all.pressed.connect(func() -> void:
            _handed_out = true
            _state.sell_unusable_loot()
            _refresh_loot())
    sell_all.custom_minimum_size.x = LOOT_ACT_W
    var sell_box := _wrapped_reason(Widgets.reasoned(sell_all,
        "" if junk_value > 0 else "Everything here fits somebody."), LOOT_REASON_W)
    controls.add_child(sell_box)

    var i := 0
    for r in Loot.plan(_state.pending_loot.duplicate(), _state.content,
            _state.roster):
        _loot_host.add_child(_loot_row(r, i))
        i += 1


## `Widgets.reasoned`'s reason never wraps on its own ("a caller that wants a
## wrap gives the box a width"): this column is a fixed width, so the reason
## wraps inside it at a larger text scale rather than widening the panel.
##
## `width` is that width, and inside a FLOW it is not optional: a wrapped Label
## with no width reports its minimum height as if it wrapped at nothing — the
## first shot of this page had a 400px hole between the split and the rows,
## with the sell control squeezed a word wide beside it (LESSONS, the uncapped
## Label the other way round). A column can leave it 0; a flow cell cannot.
static func _wrapped_reason(box: VBoxContainer, width: int = 0) -> VBoxContainer:
    var why := box.get_node_or_null("Reason") as Label
    if why != null:
        why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        if width > 0:
            why.custom_minimum_size = Vector2(width, 0)
    return box


## One drop: what it is, who can use it, who should get it, and the override.
## Items carry no rarity in this game's data, so the slot is the plain 06 §2
## chrome; the glyph is the item's own, by slot and family (`Cards.gear_icon`).
func _loot_row(row: Dictionary, index: int) -> Control:
    var it = row["item"]
    var card := Widgets.panel("PanelInset", 8)
    var col := Widgets.column(6)

    var top := Widgets.row(10)
    top.add_child(Widgets.slot(Cards.gear_icon(int(it.slot), true, it)))
    var names := Widgets.column(0)
    names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    var name_label := Widgets.label_as(String(it.name), "LabelBody")
    name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    names.add_child(name_label)
    names.add_child(Widgets.label_as(Enums.slot_name_of(it.slot), "LabelSmall"))
    top.add_child(names)

    var eligible: Array = row["eligible"]
    if not eligible.is_empty():
        var sell := _sell_button(it)
        sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        top.add_child(sell)
    col.add_child(top)

    if eligible.is_empty():
        col.add_child(Widgets.faint("Nobody in this guild can wear it."))
        Widgets.content_of(card).add_child(col)
        return card

    # The override control. docs/09 §14.3 point 3: the player can accept the
    # suggestion or change any row. An OptionButton IS a Button, so the tests
    # still read the chosen raider's name off it.
    var bottom := Widgets.row(8)
    var pick := OptionButton.new()
    pick.theme_type_variation = "Button"
    pick.add_theme_font_size_override("font_size", Type.at(Type.SMALL, Theme_.scale_of(self)))
    pick.fit_to_longest_item = false
    pick.clip_text = true
    pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var suggested_index := 0
    for i in eligible.size():
        var r = eligible[i]
        var delta: int = Loot.upgrade_delta(it, _state.content, r)
        var mark := "+%d" % delta if delta > 0 else "%d" % delta
        pick.add_item("%s  ·  %s  (%s)" % [r.display_name,
            Enums.class_name_of(r.class_id), mark], i)
        if row["suggested"] != null and r.id == row["suggested"].id:
            suggested_index = i
    pick.selected = suggested_index
    bottom.add_child(pick)

    var give := Widgets.button("Give")
    var item_id: String = it.id
    give.pressed.connect(func() -> void:
        var chosen: int = pick.selected
        if chosen < 0 or chosen >= eligible.size():
            return
        _handed_out = true
        _state.assign_loot(item_id, eligible[chosen].id)
        _refresh_loot())
    bottom.add_child(give)
    col.add_child(bottom)

    if row["suggested"] == null:
        col.add_child(Widgets.faint("upgrades nobody"))
    Widgets.content_of(card).add_child(col)
    return card


## docs/09 §14.3 point 4's Sell target, priced by docs/11 §6.1 at this guild's
## reputation. The price is on the control, because a sell button that does not
## say what it pays is asking the player to guess.
func _sell_button(it) -> Button:
    var price: int = Economy.sell_price(it, _state.reputation_rank)
    var sell := Widgets.button("Sell  %d G" % price)
    var item_id: String = it.id
    sell.pressed.connect(func() -> void:
        _handed_out = true
        _state.sell_loot(item_id)
        _refresh_loot())
    return sell


# ---------------------------------------------------------------- by raider

## docs/13 §11.4's "mistake tally by raider" (COMBAT-11): the post-mortem is
## where the one decision the player made — who they brought — is reconciled
## by name, so this is the table that says who to bench. One row per party
## member: a 24px portrait, the name (a Label, so a test can count them), the
## mistake count with a blot beside it (the same ink RaidView leaves on the
## panel, COMBAT-09), the signed morale delta in tabular figures, and whether
## they stood or fell. Sorted by mistakes, worst first. Rebuilt with the mood
## section, because the Rally Flask changes the morale column.
func _by_raider_section(result) -> Control:
    var box := Widgets.column(4)
    box.name = "ByRaider"
    box.add_child(Widgets.section("By raider"))
    _tally_host = Widgets.column(0)
    _tally_host.name = "Tally"
    box.add_child(_tally_host)
    _refresh_by_raider(result)
    return box


## UI-24: the table names its columns (a header row in LabelSmall — "Raider ·
## Mistakes · Morale · State"), and a morale column that is the same number
## twelve times (a wipe's flat penalty, docs/05 §8) carries no information, so
## it collapses: the column is dropped here and the figure is printed once in
## "The mood afterwards" (`_flat_delta`).
func _refresh_by_raider(result = null) -> void:
    if _tally_host == null or _state == null:
        return
    for c in _tally_host.get_children():
        _tally_host.remove_child(c)
        c.queue_free()
    _flat_delta = null
    if result == null:
        result = _state.last_result
    if result == null:
        return
    var rows: Array = _by_raider(result)
    if rows.is_empty():
        _tally_host.add_child(Widgets.faint("Nobody went."))
        return
    _flat_delta = flat_delta_of(rows)
    var show_morale: bool = _flat_delta == null
    _tally_host.add_child(_tally_header(show_morale))
    for row in rows:
        _tally_host.add_child(_tally_row(row, show_morale))


## The one delta every row shares, or null when the deltas differ, any is
## unrecorded, or there is only one row (one number is not a wall).
static func flat_delta_of(rows: Array) -> Variant:
    if rows.size() < 2:
        return null
    var first = rows[0]["delta"]
    if first == null:
        return null
    for row in rows:
        if row["delta"] == null or int(row["delta"]) != int(first):
            return null
    return int(first)


## The column names, aligned to `_tally_row`'s cells: the portrait's width is
## left blank under "Raider", the count and the state take their fixed widths.
func _tally_header(show_morale: bool) -> Control:
    var h := Widgets.row(6)
    h.name = "TallyHeader"
    h.custom_minimum_size = Vector2(0, TALLY_PORTRAIT)
    var lead := Control.new()
    lead.custom_minimum_size = Vector2(TALLY_PORTRAIT, 0)
    lead.mouse_filter = Control.MOUSE_FILTER_IGNORE
    h.add_child(lead)
    var raider := Widgets.faint("Raider")
    raider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    raider.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    h.add_child(raider)
    var mistakes := Widgets.faint("Mistakes")
    mistakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    mistakes.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    mistakes.custom_minimum_size = Vector2(Icons.size("log") + 6 + 22, 0)
    h.add_child(mistakes)
    if show_morale:
        var morale := Widgets.faint("Morale")
        morale.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        morale.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        morale.custom_minimum_size = Vector2(44, 0)
        h.add_child(morale)
    var state := Widgets.faint("State")
    state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    state.custom_minimum_size = Vector2(50, 0)
    h.add_child(state)
    for c in h.get_children():
        if c is Label:
            (c as Label).add_theme_color_override("font_color", Palette.TEXT_MUTED)
    return h


## The table's data, sorted mistakes-desc then by name: one entry per party
## member — {raider, mistakes, delta, fallen}. Mistakes are counted off the
## account itself (`EventLog.mistakes()` by `actor_id`) so the column agrees
## with "What happened" rather than with a separate counter. The delta is
## `last_wipe_penalty` — the wipe cost the Rally Flask refunds half of — and,
## when a raider has no entry there (a clear, a flask already used), the
## day's movement in their own morale history; `null` when neither exists.
func _by_raider(result) -> Array:
    var blots: Dictionary = {}
    if result.log != null:
        for e in result.log.mistakes():
            var id := String(e.actor_id)
            if id.is_empty():
                continue
            blots[id] = int(blots.get(id, 0)) + 1
    var out: Array = []
    for entry in _party():
        var r = entry["raider"]
        var id := String(r.id)
        out.append({
            "raider": r,
            "mistakes": int(blots.get(id, 0)),
            "delta": _morale_delta_of(r),
            "fallen": bool(entry["fallen"]),
        })
    out.sort_custom(func(a, b) -> bool:
        if int(a["mistakes"]) != int(b["mistakes"]):
            return int(a["mistakes"]) > int(b["mistakes"])
        return String(a["raider"].display_name) < String(b["raider"].display_name))
    return out


## The morale movement this attempt cost (or paid) one raider, as an int, or
## null when nothing recorded it.
func _morale_delta_of(r) -> Variant:
    # `last_attempt_morale` is the per-attempt net ledger this unit asked
    # GameState for (build/plan/handoff-W2-RESULTS.md §1): present on both
    # branches once applied, absent — and harmlessly null — until then.
    var ledger = _state.get("last_attempt_morale")
    if ledger is Dictionary and (ledger as Dictionary).has(r.id):
        return int(round(float(ledger[r.id])))
    var hits: Dictionary = _state.last_wipe_penalty
    if hits.has(r.id):
        return int(round(float(hits[r.id])))
    var log: Array = r.morale_log if r.get("morale_log") != null else []
    if log.size() >= 2 and int(log[-1]["day"]) == int(_state.day):
        return int(log[-1]["morale"]) - int(log[-2]["morale"])
    return null


func _tally_row(row: Dictionary, show_morale: bool = true) -> Control:
    var r = row["raider"]
    var h := Widgets.row(6)
    h.name = "TallyRow"
    h.custom_minimum_size = Vector2(0, TALLY_PORTRAIT)

    var face := TextureRect.new()
    face.name = "Portrait"
    face.texture = _portrait(r)
    face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.custom_minimum_size = Vector2(TALLY_PORTRAIT, TALLY_PORTRAIT)
    face.mouse_filter = Control.MOUSE_FILTER_IGNORE
    h.add_child(face)

    var name_label := Widgets.label_as(String(r.display_name), "LabelSmall")
    name_label.name = "Name"
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    if row["fallen"]:
        name_label.add_theme_color_override("font_color", Palette.TEXT_MUTED)
    h.add_child(name_label)

    # LOOP-12: the raider the wipe traces back to wears the stamp on their
    # row — the kit's StampBadge at the row's own type size, beside the name,
    # so "who to bench" is answered where the tally answers it.
    if not _culprit_id.is_empty() and String(r.id) == _culprit_id:
        var stamp := Widgets.stamp_box("WIPE", "danger")
        stamp.name = "CulpritStamp"
        stamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        stamp.mouse_filter = Control.MOUSE_FILTER_PASS
        stamp.tooltip_text = "The mistake the wipe traces back to"
        var word := stamp.get_child(0) as Label
        if word != null:
            word.add_theme_font_size_override("font_size",
                Type.at(Type.STACK, Theme_.scale_of(self)))
        h.add_child(stamp)

    # Mistakes: the log's own MISTAKE glyph (UI-24 — the blot silhouette read
    # as a claw, the boss-attack icon, and here it means "mistakes"), shown
    # only when there is ink to show, and the count. The glyph's cell keeps
    # its width when hidden so the counts stay a column.
    var mistakes: int = int(row["mistakes"])
    var mark := TextureRect.new()
    mark.name = "Mark"
    mark.texture = Icons.at("log", "mistake") if Icons.exists("log", "mistake") else null
    mark.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
    mark.custom_minimum_size = Vector2(Icons.size("log"), Icons.size("log"))
    mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mark.modulate = Color(1, 1, 1, 1.0 if mistakes > 0 else 0.0)
    mark.tooltip_text = "%d mistakes this attempt" % mistakes
    h.add_child(mark)
    var count := _figure(str(mistakes), Palette.DANGER if mistakes > 0 else Palette.TEXT_MUTED)
    count.name = "Mistakes"
    count.custom_minimum_size = Vector2(22, 0)
    count.tooltip_text = mark.tooltip_text
    h.add_child(count)

    # Morale: signed, tabular, coloured by direction; "—" when nothing was
    # recorded rather than a zero that would read as "unchanged". Collapsed
    # (built, hidden) when every row would print the same figure (UI-24:
    # `_flat_delta` prints it once under "The mood afterwards") — the Label
    # stays in the tree because the per-raider cost is a fact of the account
    # and test_results_report reads it there.
    var delta = row["delta"]
    var delta_text := "—"
    var delta_tone := Palette.TEXT_MUTED
    if delta != null:
        var d: int = int(delta)
        delta_text = ("+%d" % d) if d > 0 else str(d)
        delta_tone = Palette.POSITIVE if d > 0 else (Palette.DANGER if d < 0 else Palette.TEXT_MUTED)
    var morale := _figure(delta_text, delta_tone)
    morale.name = "Morale"
    morale.custom_minimum_size = Vector2(44, 0)
    morale.tooltip_text = "Morale this attempt"
    morale.visible = show_morale
    h.add_child(morale)

    var state := Widgets.label_as("Fallen" if row["fallen"] else "Stood", "LabelSmall")
    state.name = "State"
    state.custom_minimum_size = Vector2(50, 0)
    state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    state.add_theme_color_override("font_color",
        Palette.DANGER if row["fallen"] else Palette.TEXT_MUTED)
    h.add_child(state)
    return h


## A right-aligned tabular figure for the tally's number columns.
func _figure(text: String, tone: Color) -> Label:
    var l := Widgets.label_as(text, "LabelLevel")
    l.add_theme_color_override("font_color", tone)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    return l


# ---------------------------------------------------------------- morale

## What the attempt did to the roster, and docs/11 §7's one post-hoc purchase.
##
## The Rally Flask is the only consumable filed "Post-wipe, town" — it acts on "the
## attempt just failed", so it cannot be committed in advance and belongs here, on the
## screen where the player has just seen the damage. That is also what makes it a real
## decision: the bill arrives after the bad news.
func _morale_section() -> Control:
    _flask_host = Widgets.column(4)
    _refresh_morale()
    return _flask_host


func _refresh_morale() -> void:
    if _flask_host == null:
        return
    for c in _flask_host.get_children():
        _flask_host.remove_child(c)
        c.queue_free()
    if _state == null:
        return
    # The flask rewrites `last_wipe_penalty`, which is the tally's morale column.
    _refresh_by_raider()

    _flask_host.add_child(Widgets.section("The mood afterwards"))
    var hits: Dictionary = _state.last_wipe_penalty
    if hits.is_empty():
        _flask_host.add_child(Widgets.faint(
            "Morale has already settled from this one."))
        if not _flask_notice.is_empty():
            var done := Widgets.body(_flask_notice)
            done.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            done.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
            _flask_host.add_child(done)
        return

    var total := 0.0
    for raider_id in hits:
        total += absf(float(hits[raider_id]))
    # One line: the by-raider tally above already shows the cost by name —
    # unless the cost was the same for everyone, in which case the tally
    # dropped its column and this line carries the figure once (UI-24:
    # "-12 each, 144 between them" instead of a wall of the same number).
    var line := "That cost %d morale between them." % int(round(total))
    if _flat_delta != null and int(_flat_delta) < 0:
        line = "That cost %d morale each — %d between them." % [
            -int(_flat_delta), int(round(total))]
    var cost := Widgets.body(line)
    cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _flask_host.add_child(cost)

    var tier: int = _best_flask_tier()
    if tier <= 0:
        var why := Widgets.faint(
            "A Rally Flask from the Market would give half of it back.")
        why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _flask_host.add_child(why)
        return

    var refund := Consumables.wipe_refund_at(tier)
    var box := Widgets.button_with_reason(
        "Break out the %s — give back %d%% of it"
            % [Consumables.display_name("rally_flask", tier),
                int(round(refund * 100.0))], "")
    var b := Widgets.button_of(box)
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    # UI-39 / m4t-04: the flask's own icon on its control — the grid's item
    # glyph through the one lookup, left of the text, never stretched; the
    # text stays verbatim.
    if Icons.exists("item", "rally_flask"):
        b.icon = Icons.at("item", "rally_flask")
        b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.expand_icon = false
    b.pressed.connect(func() -> void:
        var problem: String = _state.use_rally_flask(tier)
        _flask_notice = problem if not problem.is_empty() \
            else "The flask goes round. It does not fix the raid, but it helps."
        _refresh_morale())
    _flask_host.add_child(box)


## The best grade of Rally Flask in the cupboard, or 0 if there is none. Best rather
## than cheapest: the player bought the good one for a night like this.
func _best_flask_tier() -> int:
    for tier in range(Consumables.MAX_TIER, 0, -1):
        if _state.consumable_count("rally_flask", tier) > 0:
            return tier
    return 0


# ---------------------------------------------------------------- the strip

## Who went, in the order they went, each flagged if they did not come back.
func _party() -> Array:
    var result = _state.last_result
    var fallen := {}
    for c in result.casualties:
        if c != null and c.raider != null:
            fallen[String(c.raider.id)] = true
    var party: Array = _state.last_party.duplicate() if _state.get("last_party") != null else []
    if party.is_empty():
        for c in result.survivors + result.casualties:
            if c != null and c.raider != null:
                party.append(c.raider)
    var out: Array = []
    for r in party:
        out.append({"raider": r, "fallen": fallen.has(String(r.id))})
    return out


## The party as cards, in the kit's strip (10 §2 R1/R4, COMBAT-19): the
## party is twelve, so the strip pages in fours — and `Cards.roster_strip`
## pages ITSELF with its gutter arrows, so the stacked chevrons this screen used
## to draw in the gutter are gone. The strip's "Available" panel becomes the
## roll-call ("Party  12", faces of who went); each card is this screen's own
## composite (`card_builder`): the kit card, greyed and stamped when they fell.
func _refresh_strip() -> void:
    if _card_host == null or _state == null or _state.last_result == null:
        return
    for c in _card_host.get_children():
        _card_host.remove_child(c)
        c.queue_free()

    var party := _party()
    var raiders: Array = []
    var fallen: Dictionary = {}
    for entry in party:
        raiders.append(entry["raider"])
        if entry["fallen"]:
            fallen[String(entry["raider"].id)] = true
    var opts := {
        "cards": raiders,
        "available": raiders,
        "available_label": "Party",
        "card_builder": func(raider, _index: int) -> Control:
            return _strip_card(raider, fallen.has(String(raider.id))),
        "on_page": func(p: int) -> void:
            _page = p,
    }
    var pages: int = Cards.roster_strip(_card_host, _state, _page, opts)
    _page = clampi(_page, 0, pages - 1)


## One card of the strip: the kit card with the fallen greyed and stamped
## (COMBAT-08: docs/13 §7's StampBadge, not a coloured Label). The stamp hangs
## on the card's top-right by anchor so it never needs the word's width, and
## the whole thing is one Control the strip can place and size.
func _strip_card(raider, fell: bool) -> Control:
    var wrap := Control.new()
    wrap.mouse_filter = Control.MOUSE_FILTER_PASS
    var card := Cards.card(raider, _state.content)
    card.clip_contents = true
    wrap.add_child(card)
    card.set_anchors_preset(Control.PRESET_FULL_RECT)
    if fell:
        card.modulate = FALLEN_TINT
        # Across the portrait, the way a stamp lands on a file photo — the
        # name, level and class beside it stay readable.
        var stamp := Widgets.stamp_box("FALLEN", "danger")
        wrap.add_child(stamp)
        stamp.position = FALLEN_STAMP_AT
    return wrap



## "What happened" in the combat log's position (02 §2): the story-tier account,
## one log row per entry, mistakes in the reference's red.
func _log_panel(result) -> void:
    var log := Widgets.panel("PanelSteel", 14)
    log.clip_contents = true
    _strip_host.add_child(log)
    log.position = LOG_RECT.position
    log.size = LOG_RECT.size

    var lines: Array = []
    if result != null and result.log != null:
        lines = result.log.at_tier(Enums.LogTier.STORY)
    # Indexed BEFORE the fold, so a knock-on whose cause was folded into a
    # count still names it; printed AFTER it — the same fold the live log
    # shows (CONTENT-13: identical Minor rows in one round are one row).
    _mistake_index = _index_mistakes(lines)
    var shown_lines: Array = LogPlayer.collapse(lines)

    var col := Widgets.column(0)
    var head := Widgets.row(8)
    head.add_child(Widgets.label_as("What happened", "LabelSectionSm"))
    if not lines.is_empty():
        var count := Widgets.label_as("%d lines" % lines.size(), "LabelSmall")
        count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        head.add_child(count)
    col.add_child(head)
    col.add_child(Widgets.rule())

    var sc := ScrollContainer.new()
    sc.name = "ReportScroll"
    sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var rows := Widgets.column(0)
    rows.name = "ReportRows"
    rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if result == null:
        rows.add_child(Widgets.empty_state(
            "Nothing has been run yet. The board is where a raid starts."))
    elif result.log == null:
        rows.add_child(Widgets.empty_state("No account was written."))
    elif lines.is_empty():
        rows.add_child(Widgets.empty_state("Nothing worth writing down."))
    else:
        var shown: int = mini(shown_lines.size(), MAX_STORY_LINES)
        for i in shown:
            rows.add_child(_story_row(shown_lines[i]))
        if shown_lines.size() > shown:
            rows.add_child(Widgets.faint("… and %d more lines."
                % (shown_lines.size() - shown)))
    sc.add_child(rows)
    col.add_child(sc)
    # UI-23: the scroll's fold snaps to a whole row — W5-SCALE's `_snap_fold`
    # shape: after every sort of the rows the fold moves UP to the last row
    # that fits whole and the spacer takes the leftover, so no row is sliced
    # through its glyphs at the panel's clip. In-tree only (a column under a
    # SceneTree script never sorts; the spacer stays hidden there).
    _report_scroll = sc
    _report_rows = rows
    _report_spacer = Control.new()
    _report_spacer.name = "FoldSpacer"
    _report_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _report_spacer.visible = false
    col.add_child(_report_spacer)
    rows.sort_children.connect(_snap_report_fold)
    Widgets.content_of(log).add_child(col)


## The report's fold (UI-23), the same arithmetic as the Guildhall sidebar's:
## measured from the laid-out rows, the fold is `Guildhall.fold_height()` and
## the spacer is shown at the leftover — the same value on the next sort, so
## the layout settles in one pass.
func _snap_report_fold() -> void:
    if _report_rows == null or _report_scroll == null or _report_spacer == null:
        return
    if not is_inside_tree():
        return
    var col := _report_scroll.get_parent() as VBoxContainer
    if col == null:
        return
    var sep: float = float(col.get_theme_constant("separation"))
    var fixed := 0.0
    var gaps := 0
    for c in col.get_children():
        if c == _report_scroll or c == _report_spacer or not (c is Control):
            continue
        if not (c as Control).visible:
            continue
        fixed += (c as Control).get_combined_minimum_size().y
        gaps += 1
    var avail: float = col.size.y - fixed - sep * float(gaps)
    # The fold lands on a LINE, not a block: a mistake is a header, maybe a
    # cause, and a quote (`_story_row`'s stack), and the page shows whichever
    # of those fit whole rather than dropping the whole block below the fold
    # — measured, the block rule left two rows and ninety pixels of air.
    var heights: Array = []
    for c in _report_rows.get_children():
        _leaf_heights(c, heights)
    var fold: float = Guildhall.fold_height(heights,
        float(_report_rows.get_theme_constant("separation")), avail)
    var want: float = avail - fold - sep
    if fold < avail and want > 0.5:
        _report_spacer.custom_minimum_size = Vector2(0, want)
        _report_spacer.visible = true
    else:
        _report_spacer.visible = false


## The laid-out heights of a report row's LINES, in reading order: a plain
## row is one; a mistake's stack (or a knock-on's indented stack) yields its
## header, its cause line and its quote each as their own line. The column's
## gap is 0, so the lines' heights tile the column exactly.
static func _leaf_heights(n: Node, out: Array) -> void:
    if not (n is Control) or not (n as Control).visible:
        return
    var stack: bool = n is VBoxContainer
    if n is MarginContainer and n.get_child_count() == 1 and n.get_child(0) is VBoxContainer:
        stack = true
    if stack:
        for c in n.get_children():
            _leaf_heights(c, out)
        return
    out.append((n as Control).size.y)


## 02 §2.2: only raider harm is red. Everything else keeps the log's own grey,
## with the badge carrying the kind of line it is — the icon grid's log glyph
## (COMBAT-06, `Icons.at("log", kind)`) rather than a coloured dot, the same
## glyphs RaidView's live log carries. A cascaded mistake (docs/07 §6:
## `caused_by` / `cascade_depth` on the entry) is drawn as an indented row
## under its cause, with a line naming what set it up (COMBAT-11's chain).
func _story_row(e) -> Control:
    var tone := Palette.TEXT_MUTED_WARM
    var badge := Palette.INFO
    if e.is_mistake():
        tone = Palette.DANGER
        badge = Palette.DANGER
    else:
        match e.verb:
            Enums.Verb.HEAL:
                badge = Palette.POSITIVE
            Enums.Verb.STATE_CHANGE:
                badge = Palette.CAUTION
            Enums.Verb.MECHANIC:
                badge = Palette.ARCANE
            Enums.Verb.SYSTEM:
                tone = Palette.TEXT_TITLE
    # A mistake is a header plus its indented quoted joke, two rows (docs/13
    # §11.3). The header is the live log's own line (UI-19 / CRITIC-C2 — one
    # rule for both surfaces: `LogPlayer.mistake_header`, the type leading),
    # filed under its round the way every other row here is; `describe()` is
    # the plain fallback for everything else.
    var text: String = e.describe()
    var quip: String = e.joke() if e.is_mistake() else ""
    if e.is_mistake():
        text = "[R%02d] %s" % [int(e.round_no), LogPlayer.mistake_header(e)]
    # UI-23 / LOOP-11: the report is a reading surface (docs/13 §11.4 calls it
    # "the page"), so nothing on it ellipsizes — the header wraps to its words
    # and the joke wraps in full. Spec 02 §2.1's one-line rule is the LIVE
    # log's; the row grows to its text and the fold snaps to it.
    var r := Widgets.log_row(text, tone, badge, _log_icon(e), "", -1)
    var l := r.get_child(r.get_child_count() - 1) as Label
    if l != null:
        l.tooltip_text = LogPlayer.actors_of(e) if e.is_mistake() else text
        l.mouse_filter = Control.MOUSE_FILTER_PASS
    var depth: int = _cascade_depth(e)
    var cause: String = _cause_line(e)
    if quip.is_empty() and depth == 0 and cause.is_empty():
        return r
    var stack := Widgets.column(0)
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_child(r)
    if not cause.is_empty():
        var why := Widgets.label_as(cause, "LabelSmall")
        why.add_theme_color_override("font_color", Palette.TEXT_MUTED)
        why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        why.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
        why.tooltip_text = cause
        stack.add_child(_indented(why, 30))
    if not quip.is_empty():
        var joke := Widgets.label_as('"%s"' % quip, "LabelQuote")
        joke.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        joke.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
        joke.clip_text = false
        joke.tooltip_text = quip
        stack.add_child(_indented(joke, 30))
    if depth == 0:
        return stack
    # A knock-on sits one step in per link of the chain, under its cause.
    return _indented(stack, 18 * depth)


static func _indented(c: Control, px: int) -> MarginContainer:
    var m := MarginContainer.new()
    m.add_theme_constant_override("margin_left", px)
    m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    m.add_child(c)
    return m


## The icon grid's log glyph for an entry (KIT-07 Table A's kinds). Attacks
## are the raider's or the boss's by who acted — a raider entry carries an
## `actor_id`, the boss carries none. A state change (downed, dead) is the
## `state` role's plate, the same one RaidView's panel shows.
func _log_icon(e) -> Texture2D:
    if e.is_mistake():
        return Icons.at("log", "mistake")
    match e.verb:
        Enums.Verb.HEAL:
            return Icons.at("log", "heal")
        Enums.Verb.ATTACK:
            return Icons.at("log", "raider_attack" if not String(e.actor_id).is_empty() else "boss_attack")
        Enums.Verb.MECHANIC:
            return Icons.at("log", "mechanic")
        Enums.Verb.PHASE:
            return Icons.at("log", "phase")
        Enums.Verb.STATE_CHANGE:
            var key := String(e.params.get("state", "")).to_lower()
            if Icons.exists("state", key):
                return Icons.at("state", key)
            return Icons.at("log", "system")
        _:
            return Icons.at("log", "system")


## `Mistakes.MistakeEvent.id()` ("actor:rN:TYPE") for every mistake in the
## account, so `caused_by` on a knock-on resolves to the entry that set it up.
static func _index_mistakes(lines: Array) -> Dictionary:
    var out: Dictionary = {}
    for e in lines:
        if e.is_mistake():
            out[_mistake_id(e)] = e
    return out


static func _mistake_id(e) -> String:
    return "%s:r%d:%s" % [String(e.actor_id), int(e.round_no), String(e.mistake.get("type", ""))]


static func _cascade_depth(e) -> int:
    if not e.is_mistake():
        return 0
    return maxi(0, int(e.mistake.get("cascade_depth", 0)))


## "→ set up by Greg's Pulled Aggro Off the Tank", or "" when the entry is not
## a knock-on. A cause the account no longer holds still says it was one.
func _cause_line(e) -> String:
    if not e.is_mistake():
        return ""
    var cause_id := String(e.mistake.get("caused_by", ""))
    if cause_id.is_empty():
        return ""
    var parent = _mistake_index.get(cause_id, null)
    if parent == null:
        return "→ a knock-on from an earlier mistake"
    return "→ set up by %s's %s" % [String(parent.actor_name), parent.mistake_name()]


# ---------------------------------------------------------------- exits

## Two secondary buttons, and on a loss the page's one commit ahead of them:
## docs/13 §11.4's "Try again" (UI-37, behind TRY_AGAIN — the attempts
## ruling), crimson, default-focused, with docs/01's cost under it, routing to
## prep with the same encounter pinned. On a clear the commit is the loot's
## split (UI-36), so nothing here wears the crimson (06 §3's one-per-screen).
##
## EXCEPT on the clear that ends the campaign. Then there IS a single commit —
## the ending — and the row collapses to it, so the beat cannot be walked past by
## accident. docs/15 BL-73; the guard is `completion_seen`, so it happens once.
func _exit_row() -> Control:
    if _completion_pending():
        return _completion_row()
    # A flow, not a row: at 150% text the pair is wider than the column and a
    # row would widen the whole panel; a flow stacks them.
    var row := HFlowContainer.new()
    row.add_theme_constant_override("h_separation", 12)
    row.add_theme_constant_override("v_separation", 8)
    _try_again = null
    var result = _state.last_result if _state != null else null
    if TRY_AGAIN and result != null and not result.cleared() \
            and _state.content != null and _state.content.encounter(result.encounter_id) != null:
        var retry := Widgets.cta("Try again", TRY_AGAIN_COST)
        retry.name = "TryAgain"
        _fit_cost_line(retry, TRY_AGAIN_W)
        var enc_id: String = result.encounter_id
        retry.pressed.connect(func() -> void:
            _try_again_pressed(enc_id))
        row.add_child(retry)
        _try_again = retry
    var again := Widgets.button("Back to the board")
    again.pressed.connect(func() -> void:
        if _router != null:
            _router.goto(BOARD))
    row.add_child(again)
    var town := Widgets.button("Return to town")
    town.pressed.connect(func() -> void:
        if _router != null:
            _router.goto(TOWN))
    row.add_child(town)
    return row


## A CTA whose cost line is a SENTENCE rather than a figure: the kit anchors
## that Label across the plate (`Widgets.cta`, PRESET_BOTTOM_WIDE) and sizes
## the plate to the word above it, so a long line overflows sideways over
## whatever stands next to it. The plate takes `width`, the line wraps inside
## it, and the plate grows by one line-slot per extra row — measured off the
## theme's own `LabelCtaCost` face, so 125% and 150% get their own answer.
func _fit_cost_line(b: Button, width: float) -> void:
    var cost := b.get_node_or_null("Cost") as Label
    if cost == null:
        return
    b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, width)
    cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    cost.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
    var pct: int = Theme_.scale_of(self)
    var th: Theme = Theme_.get_theme(pct)
    var face: Font = null
    var size_px: int = Type.at(Type.CTA_COST, pct)
    if th != null:
        face = th.get_font("font", "LabelCtaCost") if th.has_font("font", "LabelCtaCost") \
            else th.default_font
        if th.has_font_size("font_size", "LabelCtaCost"):
            size_px = th.get_font_size("font_size", "LabelCtaCost")
    var text_w := 0.0
    if face != null:
        text_w = face.get_string_size(cost.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
    var rows: int = maxi(1, int(ceil(text_w / maxf(1.0, b.custom_minimum_size.x - 16.0))))
    # The kit's own slot arithmetic (`Widgets.cta`), one slot per wrapped row.
    var slot: int = 22 if pct == Type.SCALE_DEFAULT else Type.at(24, pct)
    cost.offset_top = -(8 + slot * rows)
    # TWO slots per extra row, not one: the variation centres the WORD in the
    # plate less the cost slot, so a plate that grows by one slot moves the
    # word down by half of it while the cost climbs by all of it — at one slot
    # the second row printed through "Try again" (the shot said so).
    b.custom_minimum_size.y = maxf(b.custom_minimum_size.y,
        float(Widgets.CTA_H + 2 * slot * (rows - 1)))


## "Try again" the way the Board does it: the encounter pinned on the state,
## then prep PUSHED over the Board so the stack is the one the Board leaves
## (Esc from prep returns to the Board, not to nothing). The attempt this page
## reports is already recorded — trying again is a new Depart with a new day
## and whatever the player chalks, exactly the cost line under the button.
func _try_again_pressed(enc_id: String) -> void:
    if _router == null or _state == null:
        return
    _state.selected_encounter_id = enc_id
    if _router.screen_exists(BOARD) and _router.goto(BOARD):
        _router.push(RAID_PREP)
    else:
        _router.goto(RAID_PREP)


## docs/10 §13 row 1 / docs/15 Q-88: the first clear of the last encounter of the
## last tier. `completed` is set by GameState at the clear; `completion_seen` is
## set by S17 when it builds, so this is true exactly once per save.
func _completion_pending() -> bool:
    if _state == null or _router == null:
        return false
    if not bool(_state.completed) or bool(_state.completion_seen):
        return false
    # Only off the back of an attempt. With nothing to report there is nothing
    # this screen is the ending OF, and the empty panel keeps its ordinary exits.
    if _state.last_result == null:
        return false
    return _router.screen_exists(COMPLETION)


func _completion_row() -> Control:
    var row := Widgets.row(12)
    var done := Widgets.cta("See how it ended")
    done.pressed.connect(func() -> void:
        if _router != null:
            _router.goto(COMPLETION))
    row.add_child(done)
    return row
