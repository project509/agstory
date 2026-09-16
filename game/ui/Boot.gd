extends Control
## The main scene. Loads content, then hands the window to the router.
##
## Boot owns two things and nothing else:
##   the SCREEN HOST every screen is mounted into (registered with the router)
##   the BOOT OVERLAY shown while content loads, and kept up if it fails
##
## docs/14 §5.4 requires `content_db` to validate on every boot and treats a
## failed assertion as a hard error. This screen is what "hard error" looks like
## to a player: the guild's paperwork with the validation report printed on it,
## not a silent black window and not a crash. A build that cannot read its own
## content must SAY SO, because that failure is otherwise invisible until some
## unrelated screen divides by a missing item.

const ContentDB = preload("res://sim/content/ContentDB.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Frame = preload("res://game/ui/Frame.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Services = preload("res://game/core/Services.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")

const MAIN_MENU := "res://game/screens/MainMenu.tscn"
## The two cards' widths at text scale 100 (CRITIC-G02: the failure card's
## typography goes through Type, so its column widens with the text; the
## loading card is sized to the pre-rendered lockup, which does not scale).
const CARD_W := 560
const FAILURE_CARD_W := 820
const FAILURE_TEXT_W := 760

var _host: Control = null
var _overlay: Control = null
var _status: Label = null

## Set true once content has loaded and the router has been handed the window.
## Tests read this rather than sleeping on a frame count.
var booted: bool = false
var boot_errors: Array = []


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    # CRITIC-G02: the display choice (GameSettings.display_aspect) is applied
    # before ANY frame paints — the boot card included — so a wide window never
    # flashes the other framing, not even for the one frame the loading card
    # is up. It used to be applied in `_boot()`, a frame after the overlay.
    _apply_display_aspect()
    _apply_window_mode()
    _apply_cursor_hand()
    _build_host()
    _build_overlay()
    # Boot on the next frame so the overlay actually paints first. Loading and
    # validating every content table is fast but not free, and a window that
    # shows nothing at all until it finishes reads as a hang.
    call_deferred("_boot")


func _build_host() -> void:
    _host = Control.new()
    _host.name = "ScreenHost"
    _host.set_anchors_preset(Control.PRESET_FULL_RECT)
    _host.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(_host)


## The loading card (10 §3.13): the darkest ground, one warm panel centred on
## it carrying the wordmark and the status line. Every string is a Label. The
## panel is the kit's own (`Widgets.panel("PanelWarm")`, 06 §1: the chamfered
## double line; KIT-09's four corner ornaments arrive through that same call
## when Widgets.panel overlays them — nothing here to switch), so the first
## frame is drawn in the same chrome as every screen after it (CRITIC-G02).
func _build_overlay() -> void:
    _overlay = Control.new()
    _overlay.name = "BootOverlay"
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.theme = Theme_.current(self)
    _overlay.add_child(Widgets.ground())

    var col := Widgets.column(10)
    col.alignment = BoxContainer.ALIGNMENT_CENTER

    # The same pre-rendered lockup the header uses (05 §"Wordmark"), centred.
    var t := Frame.wordmark("wordmark_58")
    t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
    col.add_child(t)
    var tag := Frame.wordmark("wordmark_tagline")
    tag.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
    col.add_child(tag)
    col.add_child(Widgets.rule())

    _status = Widgets.label_as("Reading the guild's paperwork…", "LabelMuted")
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(_status)

    _overlay.add_child(_card(col, Vector2(CARD_W, 0)))
    add_child(_overlay)


## GameSettings.display_aspect onto the window. Called from `_ready()` before
## the overlay exists; `Services.find` reaches the autoload by path, so under a
## harness with no GameSettings this is a no-op rather than a crash.
func _apply_display_aspect() -> void:
    var settings = Services.find(self, "GameSettings")
    if settings != null:
        GameSettings.apply_display_aspect(get_window(), String(settings.get_value("display_aspect")))


## SHIP-06: GameSettings.window_mode and vsync onto the window, in the same
## breath as the aspect and for the same reason — before any frame paints.
## project.godot opens the window fullscreen (`window/size/mode=3`) so a fresh
## install is never larger than its screen even before this runs; this is
## where a saved `windowed` choice, and V-sync either way, take effect. Same
## null tolerance as the aspect: no autoload, no-op.
func _apply_window_mode() -> void:
    var settings = Services.find(self, "GameSettings")
    if settings != null:
        GameSettings.apply_window_mode(get_window(),
            String(settings.get_value("window_mode")), bool(settings.get_value("vsync")))


## PIPE-15 (W4-CURSOR): the kit's pointing hand beside project.godot's arrow.
## `display/mouse_cursor/*` carries one image, so the hand — every BaseButton's
## default shape — is registered here, hotspot on the fingertip.
func _apply_cursor_hand() -> void:
    var hand: Texture2D = load("res://game/assets/ui/cursor_hand.png") as Texture2D
    if hand != null:
        Input.set_custom_mouse_cursor(hand, Input.CURSOR_POINTING_HAND, Vector2(12, 1))


## A PanelWarm centred on the overlay, `content` inside it. (Private: a
## `Widgets.centred_card()` would serve every modal notice the same way.)
func _card(content: Control, min_size: Vector2) -> Control:
    var centre := CenterContainer.new()
    centre.set_anchors_preset(Control.PRESET_FULL_RECT)
    centre.mouse_filter = Control.MOUSE_FILTER_PASS
    var panel := Widgets.panel("PanelWarm", 28)
    panel.custom_minimum_size = min_size
    Widgets.content_of(panel).add_child(content)
    centre.add_child(panel)
    return centre


# ---------------------------------------------------------------- boot sequence

func _boot() -> void:
    var db = ContentDB.load_all()
    if not db.is_valid():
        boot_errors = db.errors.duplicate()
        _show_content_failure(db)
        return

    var state := Services.state(self)
    if state != null:
        state.set_content(db)

    var router := Services.router(self)
    if router == null:
        boot_errors = ["ScreenRouter autoload is missing from project.godot"]
        _show_failure("The router is missing", boot_errors)
        return

    # The display choice was applied in `_ready()`, before the overlay painted.
    router.register_host(_host)
    # W5-MOUNT: the thirteen screens' scripts compile now (~1 s boosting) and
    # the five plates load (~0.2 s), behind the card, so no page turn pays for
    # them later — measured at 45-140 ms and ~37 ms of a first visit's mount
    # (build/plan/report-W5-MOUNT.md; tools/perf_probe.gd --warm --split).
    router.warm()
    SceneStage.warm()
    if not router.goto(MAIN_MENU):
        boot_errors = ["could not open %s" % MAIN_MENU]
        _show_failure("The main menu will not open", boot_errors)
        return

    _overlay.visible = false
    booted = true


func _show_content_failure(db) -> void:
    # db.errors is already the full validation report; showing the first dozen
    # keeps the page readable while the log keeps all of them.
    push_error("ContentDB failed validation:\n" + db.error_report())
    _show_failure("The guild's records do not add up", db.errors)


func _show_failure(headline: String, errors: Array) -> void:
    for c in _overlay.get_children():
        c.queue_free()
    _overlay.add_child(Widgets.ground())

    # CRITIC-G02: the card's typography is the theme's (every string a Label
    # variation, sized by Theme_.current) and its column widens with the text
    # scale through Type.at, so a 150% reader gets the same wrap, wider.
    var pct: int = Theme_.scale_of(self)
    var text_w: float = float(Type.at(FAILURE_TEXT_W, pct))
    var col := Widgets.column(8)

    # The headline in the failure colour; the report beneath it, each problem
    # its own Label so a reader (or a test) can pick one out.
    var t := Widgets.label_as(headline, "LabelSection")
    t.add_theme_color_override("font_color", Palette.DANGER)
    col.add_child(t)
    col.add_child(Widgets.rule())
    var why := Widgets.label_as(
        "The game cannot start until this is fixed. Each line below is one "
        + "problem found in data/ while loading.", "LabelBody")
    why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    why.custom_minimum_size = Vector2(text_w, 0)
    col.add_child(why)
    col.add_child(Widgets.label_as("%d problem(s):" % errors.size(), "LabelMuted"))

    var shown := mini(errors.size(), 12)
    for i in shown:
        var line := Widgets.label_as("  • " + String(errors[i]), "LabelSmall")
        line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        line.custom_minimum_size = Vector2(text_w, 0)
        col.add_child(line)
    if errors.size() > shown:
        col.add_child(Widgets.label_as("  … and %d more (see the console log)"
            % (errors.size() - shown), "LabelSmall"))

    col.add_child(Widgets.rule())
    var quit := Widgets.button("Quit")
    quit.custom_minimum_size = Vector2(160, 38)
    quit.pressed.connect(func() -> void: get_tree().quit(1))
    var row := Widgets.row()
    row.alignment = BoxContainer.ALIGNMENT_END
    row.add_child(quit)
    col.add_child(row)

    _overlay.add_child(_card(col, Vector2(Type.at(FAILURE_CARD_W, pct), 0)))
    _overlay.visible = true
