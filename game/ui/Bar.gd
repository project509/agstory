extends Control
## A health / resource bar, drawn rather than themed.
##
## art/ref/specs/06 §4 measured three bars in the references (boss HP, combatant
## HP, the blue secondary). They are one family, and two of their traits defeat
## Godot's ProgressBar: the fill is a HARD two-tone (a bright top band over a
## dark body, not a gradient), and the fill's right end is a square cut until it
## is nearly full, only then following the track's rounded end. Six lines of
## _draw() reproduce that exactly; a TextureProgressBar would need an asset per
## colour and still get the end wrong.

const Palette = preload("res://game/ui/Palette.gd")
const Type = preload("res://game/ui/Type.gd")
const Fonts = preload("res://game/ui/Fonts.gd")
const Theme_ = preload("res://game/ui/Theme.gd")

## "hp" | "mana" | "boss" — picks the two-tone pair (06 §4).
@export var kind: String = "hp":
    set(v):
        kind = v
        queue_redraw()

@export var value: float = 0.0:
    set(v):
        value = v
        queue_redraw()

@export var maximum: float = 1.0:
    set(v):
        maximum = maxf(1.0, v)
        queue_redraw()

## Drawn centred over the bar. Empty hides it.
@export var text: String = "":
    set(v):
        text = v
        queue_redraw()

const RADIUS := 5.0
const RIM := Palette.BAR_RIM
const TRACK := Palette.BAR_TRACK


func _colours() -> Array:
    match kind:
        "mana":
            return [Palette.BAR_MANA_LIGHT, Palette.BAR_MANA]
        "boss":
            return [Palette.BAR_BOSS_LIGHT, Palette.BAR_BOSS]
        _:
            return [Palette.BAR_HP_FILL_LIGHT, Palette.BAR_HP_FILL]


func _draw() -> void:
    var w := size.x
    var h := size.y
    if w <= 2.0 or h <= 2.0:
        return
    var r: float = minf(RADIUS, h * 0.5)
    draw_rect(Rect2(0, 0, w, h), TRACK, true)
    draw_rect(Rect2(0, 0, w, h), RIM, false, 1.0)

    var frac: float = clampf(value / maximum, 0.0, 1.0)
    var inner_w := (w - 2.0) * frac
    if inner_w >= 1.0:
        var c: Array = _colours()
        var ih := h - 2.0
        # The bright band is the top 5/13 of the fill — measured on C2's HP bar
        # (highlight y 840-844 over a body y 846-852).
        var hi := maxf(1.0, roundf(ih * 5.0 / 13.0))
        draw_rect(Rect2(1, 1, inner_w, hi), c[0], true)
        draw_rect(Rect2(1, 1 + hi, inner_w, ih - hi), c[1], true)
        # Only a nearly-full bar rounds its right end; otherwise it is cut square.
        if frac < 0.96:
            draw_rect(Rect2(1 + inner_w - 1.0, 1, 1.0, ih), c[1].darkened(0.25), true)
        else:
            draw_circle(Vector2(w - r - 1.0, h * 0.5), r - 1.0, c[1])

    if not text.is_empty():
        var f: Font = Fonts.ui_tabular(500)
        # W0-TEXTSCALE's door: a size set directly goes through Type.at at the
        # player's scale (CRITIC-G15), never a bare Type constant.
        var fs: int = Type.at(Type.SMALL, Theme_.scale_of(self))
        var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
        # 02 §3.4: the boss track keeps its numbers at the right end, where the
        # eye lands after the fill; every other bar centres them.
        var tx := (w - tw - 8.0) if kind == "boss" else (w - tw) * 0.5
        var pos := Vector2(roundf(tx), roundf(h * 0.5 + fs * 0.36))
        # 06 §4: the numerals carry a 1px dark outline so they survive on the
        # bright fill as well as on the dark track.
        draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Palette.INK_BAR_OUTLINE)
        draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.INK_BAR)
