extends Control
## The small round icon badge on a log row (01 §4.2 / 06 §8).
##
## The references draw an 18px disc in one of four event colours with a lighter
## highlight and a dark glyph. This draws all three.
##
## THE GLYPH IS NOT DECORATION. docs/13 §13's first row is Blocking: Yes —
## "Colour is never the only signal" — and the combat log encodes docs/07
## §10.1's seven verbs as nothing but the disc's hue (RaidView.gd's `_row_style`). Under
## protanopia the log's DANGER and POSITIVE discs converge (measured in
## tests/unit/test_palette_cvd.gd), so "the boss healed" and "a raider died"
## became the same mark. A one-character glyph is the cheapest second channel
## that survives greyscale, an 18px size and a screenshot.
##
## It stays SMALL and DARK deliberately: the reference concepts show plain discs,
## so the glyph must not repaint the row. Per the standing rule the design wins
## where the reference does not fit — §13 is blocking and the reference's bare
## disc is not — but the disc should still read as the reference's at a glance.

const Palette = preload("res://game/ui/Palette.gd")
const Enums = preload("res://sim/model/Enums.gd")

## Combat-log event class -> glyph. Proposed by audit item M6-A11Y-07; the seven
## `icons/badge_*.png` sprites could NOT be reused here because they are typed to
## the guildhall log's kinds (failure, mishap, mood, recruit, level, loot, gold —
## spec 01 §4.2) and not to the raid log's verbs. Cards.event_log uses those.
##
## Directional pair on purpose: `>` is a raider swinging out, `<` is the boss
## swinging back, which is the distinction RaidView carried in hue alone
## (INFO vs CAUTION) and the one a player most needs.
##
## SEVEN, NOT SIX. `Enums.Verb` has seven members and docs/07 §10.1 lists all
## seven by name (`attack, heal, mechanic, mistake, state_change, phase, system`).
## An earlier version of this file said "six event classes" and left SYSTEM with a
## bare disc — and SYSTEM is not a quiet class: `RaidView._row_style` paints it
## DANGER on a wipe line and TEXT_MUTED otherwise, so the loudest line in the log
## was the one row still separated by hue alone. `=` is the sim speaking rather
## than a combatant; it is deliberately two strokes where PHASE's `-` is one,
## because at 18px the two sit in the same log a few rows apart.
const GLYPH_MISTAKE := "!"
const GLYPH_HEAL := "+"
const GLYPH_RAIDER_ATTACK := ">"
const GLYPH_BOSS_ATTACK := "<"
const GLYPH_MECHANIC := "*"
const GLYPH_PHASE := "-"
const GLYPH_SYSTEM := "="

@export var color: Color = Palette.BADGE_DANGER:
    set(v):
        color = v
        queue_redraw()

## One character, or "" for the bare reference disc. Anything longer is drawn as
## its first character — a two-character glyph is illegible at 18px and silently
## clipping it is worse than refusing it.
@export var glyph: String = "":
    set(v):
        glyph = v
        queue_redraw()


## The glyph for a raid-log entry's verb. `by_raider` splits ATTACK into the two
## directions; RaidView knows it as `not e.actor_id.is_empty()`.
static func glyph_for_verb(verb: int, by_raider: bool = true) -> String:
    match verb:
        Enums.Verb.MISTAKE, Enums.Verb.STATE_CHANGE:
            return GLYPH_MISTAKE
        Enums.Verb.HEAL:
            return GLYPH_HEAL
        Enums.Verb.ATTACK:
            return GLYPH_RAIDER_ATTACK if by_raider else GLYPH_BOSS_ATTACK
        Enums.Verb.MECHANIC:
            return GLYPH_MECHANIC
        Enums.Verb.PHASE:
            return GLYPH_PHASE
        Enums.Verb.SYSTEM:
            return GLYPH_SYSTEM
        _:
            return ""


## The glyph for an icon-grid LOG KIND (Icons.LOG_KINDS; W3-KIT2, KIT-07):
## the disc is the fallback under a pixel badge the grid has not drawn, and it
## keeps the same one-character second channel per kind so a row never loses
## its meaning with its picture. The verb kinds map onto the verb glyphs; the
## hub's kinds get their own: a gain is `+`-like `^`, a loss `v`, loot and gold
## `$`, a recruit `&` (two strokes, a figure), a phase `-`, system `=`.
const GLYPH_FOR_KIND := {
    "mistake": GLYPH_MISTAKE, "heal": GLYPH_HEAL,
    "raider_attack": GLYPH_RAIDER_ATTACK, "boss_attack": GLYPH_BOSS_ATTACK,
    "mechanic": GLYPH_MECHANIC, "phase": GLYPH_PHASE, "system": GLYPH_SYSTEM,
    "morale_up": "^", "morale_down": "v", "loot": "$", "gold": "$", "recruit": "&",
}


static func glyph_for_kind(kind: String) -> String:
    return String(GLYPH_FOR_KIND.get(kind, ""))


## Whichever of the two bubble inks reads better on `fill`. Computed rather than
## fixed, because the six log hues run from CAUTION (light amber) to ARCANE (dark
## violet) and one ink cannot serve both — this is docs/13 §8.3's fill/ink logic
## applied to a disc instead of a chip.
static func ink_for(fill: Color) -> Color:
    var dark := Palette.TEXT_ON_BUBBLE
    var light := Palette.ACCENT_BUBBLE
    return dark if _contrast(fill, dark) >= _contrast(fill, light) else light


static func _contrast(a: Color, b: Color) -> float:
    var ya := _luminance(a)
    var yb := _luminance(b)
    return (maxf(ya, yb) + 0.05) / (minf(ya, yb) + 0.05)


## WCAG relative luminance: linearise, then Rec.709 weights.
static func _luminance(c: Color) -> float:
    return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


static func _lin(v: float) -> float:
    return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


## WHERE THE GLYPH GOES, AS ARITHMETIC A TEST CAN RUN.
##
## Pulled out of `_draw` because `_draw` needs a frame and this runner never
## reaches one (tests/run_tests.gd does all its work in `_initialize`), so the
## geometry was the one part of the second channel nothing could check. A wrong
## `px` or a baseline off by an ascent does not crash: it draws a glyph half
## outside its disc, in the shipped game and nowhere else.
##
## Returns `{"px": int, "pos": Vector2}` in the badge's own coordinates.
##   px   The glyph fills the disc's INNER SQUARE, not the disc: a character
##        sized to the full diameter overhangs a circle at every corner. The
##        inner square of a circle of radius r has side r*sqrt(2) ~= 1.41r, and
##        a font size is an em box taller than its own caps, so 1.25r sits just
##        inside it. Floored at 8px, below which the fallback font stops being a
##        shape at all.
##   pos  `get_char_size` gives an ADVANCE, so x centres on that; y is a
##        BASELINE, and it is the ascent of these ASCII glyphs that needs
##        centring, not the em box.
static func glyph_layout(box: Vector2, font: Font, one_glyph: String) -> Dictionary:
    var r: float = minf(box.x, box.y) * 0.5
    var px: int = maxi(8, int(round(r * 1.25)))
    var adv: Vector2 = font.get_char_size(one_glyph.unicode_at(0), px)
    var c := Vector2(box.x * 0.5, box.y * 0.5)
    return {
        "px": px,
        "pos": Vector2(c.x - adv.x * 0.5, c.y + font.get_ascent(px) * 0.5 - 1.0),
    }


func _draw() -> void:
    var r: float = minf(size.x, size.y) * 0.5
    if r <= 1.0:
        return
    var c := Vector2(size.x * 0.5, size.y * 0.5)
    draw_circle(c, r, color)
    draw_circle(c - Vector2(0, r * 0.28), r * 0.52, color.lightened(0.28))
    if glyph.is_empty():
        return
    var font := get_theme_default_font()
    if font == null:
        return
    var lay: Dictionary = glyph_layout(size, font, glyph)
    var pos: Vector2 = lay["pos"]
    var px: int = int(lay["px"])
    draw_char(font, pos, glyph.substr(0, 1), px, ink_for(color))
