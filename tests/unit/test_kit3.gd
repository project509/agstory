extends "res://tests/TestCase.gd"
## W5-KIT3 — the kit's small debts (BUILD_STATE 'Next task' (2)), asserted the
## way the kit is read: Label.text / Button.text, node names, theme slots, and
## — for anything about SIZE — the theme's own font heights added up the way a
## BoxContainer would. Nothing here is inside a tree (tests/run_tests.gd runs
## from `_initialize`), so a card's `get_combined_minimum_size()` answers its
## custom 262 whatever the content (a PanelContainer skips children that are
## not visible-in-tree) and a Label's `get_line_count()` answers 1; the kit
## measures with the font and a TextParagraph for the same reason, and so do
## these tests.

const Widgets = preload("res://game/ui/Widgets.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Type = preload("res://game/ui/Type.gd")
const Enums = preload("res://sim/model/Enums.gd")
const RaiderScript = preload("res://sim/model/Raider.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const RosterView = preload("res://game/screens/Roster.gd")
const Fonts = preload("res://game/ui/Fonts.gd")

## The two widths the card is asked about (the strip's 215 and a 262 cell),
## and the two scales the band names must print whole at.
const WIDTHS := [215, 262]
const SCALES := [100, 125]
## The widest class word and the one the wave-3 review caught ("Shaman —
## Slightly Annoy…"); every one of the ten bands is walked for each.
const CLASSES := [0, 5]

var _made: Array = []
var _mounted: Array = []
var _scale_was = null


class StateStub:
    var roster: Array = []
    var event_feed: Array = []


func before_each() -> void:
    _made = []
    _mounted = []
    _scale_was = null


func after_each() -> void:
    # The text scale is a persisted setting on a shared autoload: put it back
    # first, before anything else can abort the teardown (LESSONS).
    var gs = _settings()
    if gs != null and _scale_was != null:
        gs.set_value("text_scale", _scale_was)
    _scale_was = null
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []
    for n in _mounted:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _mounted = []


# ---------------------------------------------------------------- helpers

func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _settings() -> Node:
    var root := _root()
    return root.get_node_or_null("GameSettings") if root != null else null


## The GameSettings autoload, provided if `--script` did not (test_text_scale's
## shape), at `scale` — remembered once so after_each restores it.
func _at_scale(scale: int) -> Node:
    var gs = _settings()
    if gs == null:
        gs = SettingsScript.new()
        gs.name = "GameSettings"
        _root().add_child(gs)
        _mounted.append(gs)
    if _scale_was == null:
        _scale_was = gs.get_value("text_scale")
    gs.set_value("text_scale", scale)
    return gs


func _raider(i: int, cls: int, morale: int) -> RefCounted:
    var r = RaiderScript.new()
    r.id = "r%02d" % i
    r.display_name = "R%02d" % i
    r.class_id = cls
    r.morale = morale
    return r


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append(n)
    for c in n.get_children():
        _labels(c, out)
    return out


func _find(n: Node, name: String) -> Node:
    if String(n.name) == name:
        return n
    for c in n.get_children():
        var hit := _find(c, name)
        if hit != null:
            return hit
    return null


func _button(n: Node, text: String) -> Button:
    if n is Button and (n as Button).text == text:
        return n as Button
    for c in n.get_children():
        var hit := _button(c, text)
        if hit != null:
            return hit
    return null


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


## The font and size a Label will actually draw with: its overrides first,
## else the kit theme's variation at the player's scale (outside a tree the
## Label's own lookup answers with Godot's default theme, which is not what
## the game draws).
func _drawn_with(l: Label) -> Array:
    var fs: Array = Widgets.font_of(String(l.theme_type_variation), l)
    var font: Font = l.get_theme_font("font") if l.has_theme_font_override("font") else fs[0]
    var size: int = l.get_theme_font_size("font_size") if l.has_theme_font_size_override("font_size") else int(fs[1])
    return [font, size]


func _band_label(card: Control, cls: int) -> Label:
    var prefix := "%s — " % Enums.class_name_of(cls)
    for l in _labels(card):
        if String((l as Label).theme_type_variation) == "LabelClass" and (l as Label).text.begins_with(prefix):
            return l
    return null


## How many lines `l` needs at `width` in the font it draws with.
func _lines_at(l: Label, width: float) -> int:
    var fs: Array = _drawn_with(l)
    var tp := TextParagraph.new()
    tp.width = width
    tp.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
    tp.add_string(l.text, fs[0] as Font, int(fs[1]))
    return tp.get_line_count()


func _line_h(variation: String, who: Node) -> float:
    var fs: Array = Widgets.font_of(variation, who)
    return (fs[0] as Font).get_height(int(fs[1]))


# ------------------------------------------------------------ (1) the band line

func test_every_band_name_prints_whole_on_the_card_at_two_widths_and_two_scales() -> void:
    # docs/13 §8.1 never abbreviates a state word; §4.4 never truncates one at
    # any scale. Ten bands x two classes x two widths x two scales: the line
    # fits on one line in the font it draws with, or wraps to at most
    # Cards.BAND_LINES with every line visible — never the ellipsis.
    for scale in SCALES:
        _at_scale(int(scale))
        for width in WIDTHS:
            var inner: float = float(int(width) - 2 * Cards.CARD_PAD)
            for cls in CLASSES:
                for band in Enums.MORALE_BAND_COUNT:
                    var morale: int = int(band) * 10 + 5
                    var card := Cards.card(_raider(1, int(cls), morale), null)
                    _made.append(card)
                    card.size = Vector2(int(width), Widgets.CARD_SIZE.y)
                    var l := _band_label(card, int(cls))
                    var want := "%s — %s" % [Enums.class_name_of(int(cls)), Enums.morale_band_name(morale)]
                    assert_ne(l, null, "the band Label exists for %s" % want)
                    assert_eq(l.text, want, "the text shape the tests read is kept")
                    var fs: Array = _drawn_with(l)
                    var one_line: float = (fs[0] as Font).get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs[1])).x
                    if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
                        assert_true(one_line <= inner,
                            "%s at %d%% on a %d card: %.0f wide in %.0f" % [want, scale, width, one_line, inner])
                    else:
                        var lines: int = _lines_at(l, inner)
                        assert_true(lines <= Cards.BAND_LINES and lines <= l.max_lines_visible,
                            "%s at %d%% on a %d card wraps to %d lines (ceiling %d)" % [want, scale, width, lines, l.max_lines_visible])
                        assert_true(l.custom_minimum_size.y >= (fs[0] as Font).get_height(int(fs[1])) * float(lines),
                            "the wrapped line reserves its %d lines" % lines)
                    # The size never drops below the step under the variation's own
                    # (CLASS - 2 at the player's scale), so a wrapped line is still
                    # at least as large as the 100% line.
                    assert_true(int(fs[1]) >= Type.at(Type.CLASS - 2, int(scale)), "never smaller than CLASS-2 at %d%%" % scale)
                    assert_eq(l.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS, "the ellipsis stays as the last guard")
                    if int(scale) == 100:
                        assert_eq(l.autowrap_mode, TextServer.AUTOWRAP_OFF, "at 100%% every line is one line (%s)" % want)


func test_the_band_line_fit_takes_the_first_rung_that_fits() -> void:
    _at_scale(100)
    var fits := Widgets.label_as("Mage — Happy", "LabelClass")
    _made.append(fits)
    assert_eq(Cards.fit_band_line(fits, 187.0), 1)
    assert_false(fits.has_theme_font_size_override("font_size"), "a line that fits keeps the variation's size")
    assert_eq(fits.autowrap_mode, TextServer.AUTOWRAP_OFF)
    var narrower := Widgets.label_as("Shaman — Slightly Annoyed", "LabelClass")
    _made.append(narrower)
    assert_eq(Cards.fit_band_line(narrower, 187.0), 1)
    assert_eq(narrower.get_theme_font_size("font_size"), Type.at(Type.CLASS - 2, 100), "the second rung: CLASS-2 (13 at 100%)")
    assert_eq(narrower.autowrap_mode, TextServer.AUTOWRAP_OFF, "still one line")
    # The smaller rungs shape from the plain face (a with_pips variation drawn
    # at a size it was not built for corrupted every 16px glyph on the
    # Guildhall at 125% — Cards.fit_band_line's comment) on the variation's
    # own line, bottom-aligned, so the card's rows and baseline stay put.
    assert_true(narrower.has_theme_font_override("font"), "the plain face")
    assert_eq(narrower.get_theme_font("font"), Fonts.ui())
    assert_eq(narrower.vertical_alignment, VERTICAL_ALIGNMENT_BOTTOM)
    assert_almost(narrower.custom_minimum_size.y, ceilf(_line_h("LabelClass", narrower)), 0.001, "the variation's own line height")
    var wrapped := Widgets.label_as("Shaman — Slightly Annoyed", "LabelClass")
    _made.append(wrapped)
    assert_eq(Cards.fit_band_line(wrapped, 120.0), 2, "the third rung: two lines")
    assert_eq(wrapped.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
    assert_eq(wrapped.max_lines_visible, Cards.BAND_LINES)
    assert_true(wrapped.custom_minimum_size.y > 0.0, "the two lines are reserved")
    assert_true(wrapped.has_theme_font_override("font"), "shaped from the plain face (no face sheet behind it)")


# ------------------------------------------------------------ (2) the band

## The card's stack at 100%, added the way its VBox would: pad, the portrait
## row, the morale line, the band line, the slots, the band, the pad.
func _card_stack(card: Control, band_h: float) -> float:
    var pad: Control = Widgets.content_of(card as PanelContainer)
    var col := pad.get_child(0) as VBoxContainer
    var gap := float(col.get_theme_constant("separation"))
    var top := float(pad.get_theme_constant("margin_top"))
    var bottom := float(pad.get_theme_constant("margin_bottom"))
    var rows: float = 94.0 + _line_h("LabelMorale", card) + _line_h("LabelClass", card) + float(Widgets.SLOT) + band_h
    return top + rows + gap * 4.0 + bottom


func test_the_band_is_sized_to_its_content_with_and_without_a_reason() -> void:
    _at_scale(100)
    var th: Theme = Theme_.get_theme(100)
    var probe := Widgets.button("x")
    _made.append(probe)
    var button_h: float = _line_h("ButtonCardAction", probe) + th.get_stylebox("normal", "ButtonCardAction").get_minimum_size().y
    var reason_h: float = (Widgets.font_of("LabelSmall", null)[0] as Font).get_height(Type.at(Type.STACK, 100))

    var shut := Cards.card(_raider(1, 5, 45), null, {}, [
        {"text": "Cheer up", "reason": "They are fine."}, {"text": "Manage"}])
    _made.append(shut)
    var open := Cards.card(_raider(2, 5, 45), null, {}, [{"text": "Cheer up"}, {"text": "Manage"}])
    _made.append(open)
    var bare := Cards.card(_raider(3, 5, 45), null)
    _made.append(bare)

    # The buttons wear the card's own plate, the reason its caption size flush
    # under its button, and the column closes to the banded gap.
    for card in [shut, open]:
        for text in ["Cheer up", "Manage"]:
            var b := _button(card, text)
            assert_ne(b, null)
            assert_eq(b.theme_type_variation, StringName("ButtonCardAction"), "%s on the card's plate" % text)
        var col := Widgets.content_of(card as PanelContainer).get_child(0) as VBoxContainer
        assert_eq(col.get_theme_constant("separation"), Cards.CARD_GAP_BANDED, "a banded card closes its gaps")
    var band := _find(shut, "Actions") as HBoxContainer
    var why: Label = null
    for box in band.get_children():
        for c in box.get_children():
            if c is Label:
                why = c
                assert_eq((box as VBoxContainer).get_theme_constant("separation"), 0, "the reason sits flush under its button")
    assert_ne(why, null, "the reason is a Label in the band")
    assert_eq(why.text, "They are fine.")
    assert_eq(why.get_theme_font_size("font_size"), Type.at(Type.STACK, 100), "the reason at the caption size")
    var shut_pad: Control = Widgets.content_of(shut as PanelContainer)
    var open_pad: Control = Widgets.content_of(open as PanelContainer)
    assert_eq(shut_pad.get_theme_constant("margin_bottom"), Cards.CARD_PAD_REASONED, "a reasoned band takes the bottom pad down")
    assert_eq(open_pad.get_theme_constant("margin_bottom"), Cards.CARD_PAD, "no reason, the full pad")
    assert_eq(shut_pad.get_theme_constant("margin_top"), Cards.CARD_PAD, "only the bottom moves")

    # Both stacks fit the 262, the reasoned one by exactly the reason's line.
    var with_reason: float = _card_stack(shut, button_h + reason_h)
    var without: float = _card_stack(open, button_h)
    assert_true(with_reason <= float(Widgets.CARD_SIZE.y),
        "a card with a reasoned band asks for %.0f of %d" % [with_reason, Widgets.CARD_SIZE.y])
    assert_true(without <= float(Widgets.CARD_SIZE.y),
        "a card with a bare band asks for %.0f of %d" % [without, Widgets.CARD_SIZE.y])
    assert_true(button_h <= 29.0, "the card-action plate is 29 tall at 100%% (%.0f)" % button_h)

    # A card without a band is the card it was: gap 4, pad 14 all round.
    var bare_col := Widgets.content_of(bare as PanelContainer).get_child(0) as VBoxContainer
    assert_eq(bare_col.get_theme_constant("separation"), Cards.CARD_GAP)
    assert_eq(Widgets.content_of(bare as PanelContainer).get_theme_constant("margin_bottom"), Cards.CARD_PAD)


func test_rosters_interim_fit_band_is_a_no_op_on_the_kits_card() -> void:
    # Roster._fit_band tightens what the kit now tightens itself (the reason
    # at STACK, its box at 0, the column at 2); running it must change nothing
    # and break nothing — the same tree, the same texts.
    _at_scale(100)
    var card := Cards.card(_raider(1, 0, 45), null, {}, [
        {"text": "Cheer up", "reason": "They are fine."}, {"text": "Manage"}])
    _made.append(card)
    var before: Array = _texts(card)
    var col := Widgets.content_of(card as PanelContainer).get_child(0) as VBoxContainer
    var view := RosterView.new()
    _made.append(view)
    view._fit_band(card)
    assert_eq(_texts(card), before, "the walk reads the same tree")
    assert_eq(col.get_theme_constant("separation"), Cards.CARD_GAP_BANDED)
    var band := _find(card, "Actions")
    for box in band.get_children():
        for c in box.get_children():
            if c is Label:
                assert_eq((c as Label).get_theme_font_size("font_size"), Type.at(Type.STACK, 100))
                assert_eq((box as VBoxContainer).get_theme_constant("separation"), 0)
    assert_eq(Widgets.button_of(band as Control), _button(card, "Cheer up"))


# ------------------------------------------------------------ (3) empty state

func test_empty_state_keeps_its_hint_under_a_wrapped_text() -> void:
    var text := "There is no kit to show. This guild has nobody in it."
    var l := Widgets.empty_state(text, PlaceholderTexture2D.new(), "Recruits are found at the Tavern.")
    _made.append(l)
    var hint := _find(l, "Hint") as Control
    var glyph := _find(l, "Glyph") as Control
    assert_ne(hint, null)
    assert_ne(glyph, null)
    var line_h: float = _line_h("LabelSmall", l)
    # No width yet: the one-line placement, KIT-08's own numbers.
    assert_almost(hint.offset_top, line_h * 0.5 + 4.0, 0.01, "one line: the hint 4px under it")
    assert_almost(glyph.offset_bottom, -(line_h * 0.5 + 8.0), 0.01, "one line: the glyph 8px over it")
    assert_eq(Widgets._wrapped_lines(l), 1, "no width, one line")
    # Laid out narrow, the sentence wraps; the hint moves under the whole block
    # and the glyph above it. Outside a tree nothing lays out, so the resize is
    # emitted by hand (the same signal layout would send).
    l.size = Vector2(160, 120)
    l.resized.emit()
    var lines: int = Widgets._wrapped_lines(l)
    assert_true(lines >= 2, "the sentence wraps at 160px (%d lines)" % lines)
    var spacing := float(l.get_theme_constant("line_spacing"))
    var block: float = line_h * float(lines) + spacing * float(lines - 1)
    assert_almost(hint.offset_top, block * 0.5 + 4.0, 0.01, "the hint's top is 4px under the block's bottom")
    assert_true(hint.offset_top > line_h * 0.5 + 4.0, "and lower than the one-line placement")
    assert_almost(glyph.offset_bottom, -(block * 0.5 + 8.0), 0.01, "the glyph's bottom 8px over the block's top")
    assert_almost(glyph.offset_top, glyph.offset_bottom - 32.0, 0.01, "a 32px glyph")
    # RaiderDetail's split sentences: the text and the hint are still two
    # Labels the walk reads, and the text is untouched.
    assert_eq(l.text, text)
    assert_eq((hint as Label).text, "Recruits are found at the Tavern.")
    # Wide again, back to one line.
    l.size = Vector2(600, 120)
    l.resized.emit()
    assert_almost(hint.offset_top, line_h * 0.5 + 4.0, 0.01, "one line again")


# ------------------------------------------------------------ (4) reasoned placement

func test_reasoned_placement_below_is_the_old_box_and_beside_is_a_row() -> void:
    var below := Widgets.reasoned(Widgets.button("Delete"), "Nothing to delete.")
    _made.append(below)
    var explicit := Widgets.reasoned(Widgets.button("Delete"), "Nothing to delete.", null, 0, "below")
    _made.append(explicit)
    for box in [below, explicit]:
        assert_eq(box.get_child_count(), 2, "the control then the reason, direct children")
        assert_true(box.get_child(0) is Button)
        assert_eq(String(box.get_child(1).name), "Reason")
        assert_eq(box.get_node_or_null("Reason"), box.get_child(1), "the reason is the box's own child")
        assert_eq(box.get_theme_constant("separation"), 2)
        assert_true(Widgets.button_of(box).disabled)
        assert_almost(Widgets.button_of(box).modulate.a, Widgets.REASONED_DIM, 0.001)
    var beside := Widgets.reasoned(Widgets.button("Load — Slot 2"), "Slot 2 is empty.", null, 0, "beside")
    _made.append(beside)
    assert_eq(beside.get_child_count(), 1, "one row")
    var line := beside.get_child(0)
    assert_true(line is HBoxContainer, "the row is an HBox")
    assert_eq(String(line.name), "Row")
    assert_eq(line.get_child_count(), 2)
    assert_true(line.get_child(0) is Button)
    var why := line.get_child(1) as Label
    assert_eq(String(why.name), "Reason")
    assert_eq(why.text, "Slot 2 is empty.")
    assert_eq(why.get_theme_color("font_color"), Palette.CAUTION)
    assert_eq(why.size_flags_vertical, Control.SIZE_SHRINK_CENTER, "centred beside the control")
    assert_eq(why.autowrap_mode, TextServer.AUTOWRAP_OFF, "no width: the row grows")
    var b := Widgets.button_of(beside)
    assert_ne(b, null, "button_of still finds the Button through the row")
    assert_eq(b.text, "Load — Slot 2")
    assert_true(b.disabled)
    assert_ne(b.icon, null, "the padlock")
    var wide := Widgets.reasoned(Widgets.button("Hire"), "Unknown guilds cannot commission this.", null, 200, "beside")
    _made.append(wide)
    var wrapped := _find(wide, "Reason") as Label
    assert_eq(wrapped.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
    assert_almost(wrapped.custom_minimum_size.x, 200.0, 0.001)
    var fine := Widgets.reasoned(Widgets.button("Go"), "", null, 0, "beside")
    _made.append(fine)
    assert_eq(_find(fine, "Reason"), null, "no reason, no Label")
    assert_false(Widgets.button_of(fine).disabled)


# ------------------------------------------------------------ (5) pips

func test_pips_count_their_steps_and_light_up_to_the_value() -> void:
    var six := Widgets.pips(50.0, 100.0)
    _made.append(six)
    assert_eq(String(six.name), "Pips")
    assert_eq(six.get_child_count(), 6, "six steps by default")
    assert_eq(six.mouse_filter, Control.MOUSE_FILTER_IGNORE)
    var names: Array = []
    var lit := 0
    for p in six.get_children():
        names.append(String(p.name))
        assert_eq((p as Control).custom_minimum_size, Vector2(Widgets.PIP_SIZE), "each pip is PIP_SIZE")
        assert_eq((p as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE)
        assert_eq(String(p.get("kind")), "mana", "the kit's bar, the secondary tint")
        if float(p.get("value")) > 0.0:
            lit += 1
    assert_eq(names, ["Pip17", "Pip33", "Pip50", "Pip67", "Pip83", "Pip100"], "named by threshold")
    assert_eq(lit, 3, "50 of 100 in sixths lights three")
    assert_eq(six.get_theme_constant("separation"), Widgets.PIP_GAP)
    # Settings' ladder: five audible steps of twenty.
    var five := Widgets.pips(60.0, 100.0, 5)
    _made.append(five)
    var five_names: Array = []
    var five_lit := 0
    for p in five.get_children():
        five_names.append(String(p.name))
        if float(p.get("value")) > 0.0:
            five_lit += 1
    assert_eq(five_names, ["Pip20", "Pip40", "Pip60", "Pip80", "Pip100"], "Settings' own names")
    assert_eq(five_lit, 3, "60 lights 20, 40 and 60")
    var none := Widgets.pips(0.0, 100.0, 5)
    _made.append(none)
    for p in none.get_children():
        assert_almost(float(p.get("value")), 0.0, 0.0001, "0 is an empty strip")
    var full := Widgets.pips(100.0, 100.0, 5)
    _made.append(full)
    for p in full.get_children():
        assert_almost(float(p.get("value")), 1.0, 0.0001, "100 lights every pip")


# ------------------------------------------------------------ (6) event log rows

func test_event_log_rows_is_six_and_the_log_prints_no_more() -> void:
    assert_eq(Cards.ROWS, 6, "(262 - 28 - 36 - 1) / 29")
    assert_eq(Cards.ROWS, int((Widgets.STRIP_H - 2 * Cards.CARD_PAD - Cards.EVENT_HEAD_H - 1) / Widgets.LOG_ROW_PITCH))
    var st := StateStub.new()
    for i in 8:
        st.event_feed.append({"day": i + 1, "seq": i, "kind": "gold", "text": "Event %d" % (i + 1)})
    var host := Control.new()
    _made.append(host)
    Cards.event_log(host, st)
    var rows := 0
    for l in _labels(host):
        if String((l as Label).theme_type_variation) == "LabelLog":
            rows += 1
    assert_eq(rows, Cards.ROWS, "the default prints ROWS")
    var asked := Control.new()
    _made.append(asked)
    Cards.event_log(asked, st, 7)
    var seven := 0
    for l in _labels(asked):
        if String((l as Label).theme_type_variation) == "LabelLog":
            seven += 1
    assert_eq(seven, Cards.ROWS, "asking for seven still prints six")
    assert_eq(Cards.recent_events(st, 8).size(), 8, "the feed itself holds eight")


# ------------------------------------------------------------ UI-12: one empty-state voice

func test_the_empty_log_reads_the_hubs_hint_on_every_screen() -> void:
    # `event_log` took the hint per screen and only the Town passed one, so the
    # Market and the Tavern read a different empty state for the same panel.
    var st := StateStub.new()
    var host := Control.new()
    _made.append(host)
    Cards.event_log(host, st)
    var joined := "\n".join(PackedStringArray(_texts(host)))
    assert_true(joined.contains(Cards.EMPTY_TEXT), joined)
    assert_true(joined.contains(Cards.HUB_HINT), "the hub's line by default: %s" % joined)
    assert_eq(Cards.HUB_HINT, "Raids and rests write here.")
    var own := Control.new()
    _made.append(own)
    Cards.event_log(own, st, Cards.ROWS, "A better line.")
    assert_true("\n".join(PackedStringArray(_texts(own))).contains("A better line."),
        "a screen may still override it")


# ------------------------------------------------------------ UI-51: the feed folds morale rows

func _cleared_guild(count: int, day: int) -> StateStub:
    var st := StateStub.new()
    st.event_feed.append({"day": day, "seq": 1, "kind": "gold",
        "text": "Cleared Adventure 0 — 4 G."})
    for i in count:
        var r = _raider(i, 0, 51)
        r.display_name = "Raider%02d" % i
        r.record_morale_day(day, 51, "cleared")
        st.roster.append(r)
    return st


func test_a_twelve_raider_clear_is_one_sentence_under_the_raids_line() -> void:
    # "Bork: cleared / Gruk: cleared / …" twelve times pushed the raid's own
    # line off the six-row panel. Same note, same day: one sentence, and the
    # raid's line first.
    var st := _cleared_guild(12, 4)
    var rows: Array = Cards.recent_events(st, 20)
    var today: Array = []
    for e in rows:
        if int(e["day"]) == 4:
            today.append(e)
    assert_true(today.size() <= 3, "<= 3 rows for the day, got %d" % today.size())
    assert_eq(String(today[0]["text"]), "Cleared Adventure 0 — 4 G.", "the raid's line first")
    for e in today:
        assert_false(String(e["text"]).contains(": cleared"), String(e["text"]))
    assert_eq(String(today[1]["text"]), "12 raiders came home happier.")
    assert_eq(String(today[1]["kind"]), "morale_up", "the fold keeps the row's sign")
    assert_eq(String(today[1]["tone"].to_html()), Palette.POSITIVE.to_html())


func test_one_raiders_note_names_them_and_a_day_keeps_at_most_two_morale_rows() -> void:
    var st := _cleared_guild(1, 2)
    var rows: Array = Cards.recent_events(st, 20)
    # The one-raider row: the table's sentence once SINGLE_ROW_SENTENCE flips
    # (handoff-W6-COPY §4); the raw pair until then. Both forms are asserted so
    # the flip is one constant and one line here.
    assert_eq(Cards.morale_sentence("cleared", ["Raider00"], true), "Raider00 came home happier.")
    assert_eq(Cards.morale_sentence("cleared", ["Raider00"], false), "Raider00: cleared")
    assert_eq(String(rows[1]["text"]), Cards.morale_sentence("cleared", ["Raider00"]))
    assert_eq(String(rows[1]["note"]), "cleared", "the raw note rides along for readers that key on it")
    # Three different notes on one day: the two widest groups survive.
    var busy := StateStub.new()
    var notes := ["wipe", "wipe", "wipe", "wipe_caused", "brought"]
    for i in notes.size():
        var r = _raider(i, 0, 40)
        r.display_name = "R%02d" % i
        r.record_morale_day(6, 40, String(notes[i]))
        busy.roster.append(r)
    var day6: Array = Cards.recent_events(busy, 20)
    assert_eq(day6.size(), Cards.MORALE_ROWS_PER_DAY)
    assert_eq(String(day6[0]["text"]), "3 raiders are still upset about the wipe.")
    assert_eq(String(day6[0]["kind"]), "morale_down")
    assert_true(String(day6[1]["note"]) in ["wipe_caused", "brought"],
        "the second row is one of the single notes: %s" % String(day6[1]["text"]))
    assert_true(String(day6[1]["text"]).begins_with("R03") or String(day6[1]["text"]).begins_with("R04"))
    # A note nobody has written the sentence for falls back to the honest pair.
    assert_eq(Cards.morale_sentence("some_new_tag", ["Bob"]), "Bob: some_new_tag")
    assert_eq(Cards.morale_sentence("some_new_tag", ["Bob", "Greg"]), "2 raiders: some_new_tag")
    # Every trigger the sim can write has a sentence in both numbers.
    var Morale = load("res://sim/core/Morale.gd")
    for trigger in Morale.TRIGGERS:
        assert_true(Cards.MORALE_SENTENCES.has(trigger), "no sentence for '%s'" % trigger)
        assert_true(String(Cards.MORALE_SENTENCES[trigger][0]).contains("%s"), trigger)
        assert_true(String(Cards.MORALE_SENTENCES[trigger][1]).contains("%d"), trigger)
    for note in Cards.NOTE_SIGN:
        assert_true(Cards.MORALE_SENTENCES.has(note), "no sentence for '%s'" % note)


# ------------------------------------------------------------ (7) theme variations

func test_button_mini_picked_and_card_action_go_through_the_door() -> void:
    for scale in [100, 125]:
        var t: Theme = Theme_.get_theme(int(scale))
        for name in ["ButtonMiniPicked", "ButtonCardAction"]:
            for slot in ["normal", "hover", "pressed", "disabled", "focus"]:
                assert_true(t.has_stylebox(slot, name), "%s has no %s box at %d" % [name, slot, scale])
            var ring = t.get_stylebox("focus", name)
            assert_true(ring is StyleBoxFlat, "%s keeps the flat ring" % name)
            assert_eq((ring as StyleBoxFlat).border_color, Palette.EDGE_STEEL, name)
            assert_eq((ring as StyleBoxFlat).border_width_left, 2, name)
            assert_true((ring as StyleBoxFlat).expand_margin_left >= 2.0, name)
            assert_true(t.has_color("font_disabled_color", name), name)
        assert_eq(t.get_type_variation_base("ButtonMiniPicked"), StringName("ButtonMini"), "a mini tile")
        var picked = t.get_stylebox("pressed", "ButtonMiniPicked")
        assert_true(picked is StyleBoxFlat)
        assert_eq((picked as StyleBoxFlat).border_color, Palette.EDGE_READY_GOLD, "the 2px gold rim Facilities drew by hand")
        assert_eq((picked as StyleBoxFlat).border_width_top, 2)
        assert_eq((picked as StyleBoxFlat).bg_color, Palette.SURFACE_PLATE_LIT, "on the lit plate")
        assert_true(t.has_stylebox("hover_pressed", "ButtonMiniPicked"), "the rim stays under the pointer")
        assert_eq(t.get_stylebox("hover_pressed", "ButtonMiniPicked"), picked)
        assert_eq(t.get_stylebox("normal", "ButtonMiniPicked"), t.get_stylebox("normal", "ButtonMini"), "an unpicked tile is a mini tile")
        assert_eq(t.get_type_variation_base("ButtonCardAction"), StringName("Button"))
        var act: StyleBox = t.get_stylebox("normal", "ButtonCardAction")
        assert_eq(act.content_margin_top, 6.0, "6px top")
        assert_eq(act.content_margin_bottom, 6.0, "6px bottom")
        assert_eq(act.content_margin_left, 8.0, "the secondary's sides")
        assert_eq(t.get_stylebox("pressed", "ButtonCardAction").content_margin_top, 7.0, "pressed drops the label one pixel")
        assert_eq(t.get_font_size("font_size", "ButtonCardAction"), Type.at(Type.SMALL, int(scale)), "SMALL at the scale")


# ------------------------------------------------------------ (8) tab_row min_size

func test_tab_row_takes_a_screens_own_minimum_and_keeps_tab_min_by_default() -> void:
    var labels := ["Roster", "Raid Group", "Facilities", "Records"]
    var kit := Widgets.tab_row(labels, 0, ["", "not in this version yet", "", ""])
    _made.append(kit)
    for b in Widgets.tabs_of(kit):
        assert_eq((b as Button).custom_minimum_size, Widgets.TAB_MIN, "TAB_MIN by default")
    var hall := Widgets.tab_row(labels, 0, ["", "not in this version yet", "", ""], Vector2(110, 28))
    _made.append(hall)
    var tabs := Widgets.tabs_of(hall)
    assert_eq(tabs.size(), 4)
    for i in 4:
        assert_eq((tabs[i] as Button).custom_minimum_size, Vector2(110, 28), "the Guildhall's 110x28")
        assert_eq((tabs[i] as Button).text, labels[i], "texts unchanged")
    assert_true((tabs[1] as Button).disabled)
    assert_true("\n".join(PackedStringArray(_texts(hall))).contains("not in this version yet"), "the reason is still in the row")
    assert_eq(Widgets.TAB_MIN, Vector2(110, 32), "the kit's own floor is unchanged")


# ------------------------------------------------------- (9) the class word (UI-31)

## The NINE canon class names (Enums.CLASS_NAMES; the plan's line says "ten",
## which is the morale band count — the classes are nine, canon's *Classes*).
const CLASS_SCALES := [100, 125, 150]


## The card's class word and the row it sits in: `Cards.card` names the row
## "ClassRow" and the Label is its only Label (the glyph is a TextureRect).
func _class_word(card: Control) -> Label:
    var row := _find(card, "ClassRow")
    if row == null:
        return null
    for c in row.get_children():
        if c is Label:
            return c
    return null


func test_every_class_word_prints_whole_on_the_card_at_three_scales() -> void:
    # UI-31 / docs/13 §4.4: "Shama" and "Warri" beside the glyph on the 125
    # and 150 sheets. Nine classes x two card widths x three scales: the word
    # fits the column it is actually given — the card's inner width less the
    # portrait, the row's separation and the glyph — in the font and size the
    # Label draws with after `Cards.fit_class_word` has chosen its rung.
    for scale in CLASS_SCALES:
        _at_scale(int(scale))
        for width in WIDTHS:
            for cls in Enums.CLASS_NAMES.size():
                var card := Cards.card(_raider(1, int(cls), 55), null)
                _made.append(card)
                card.size = Vector2(int(width), Widgets.CARD_SIZE.y)
                var l := _class_word(card)
                var want: String = Enums.class_name_of(int(cls))
                assert_ne(l, null, "the class Label exists for %s" % want)
                if l == null:
                    continue
                assert_eq(l.text, want, "the text shape the tests read is the bare class name")
                var row: Control = l.get_parent()
                var top: Control = row.get_parent().get_parent()
                var glyph_w := 0.0
                for c in row.get_children():
                    if c is TextureRect and (c as TextureRect).texture != null:
                        glyph_w = float((c as TextureRect).texture.get_width()) \
                            + float(row.get_theme_constant("separation"))
                var avail: float = float(int(width) - 2 * Cards.CARD_PAD) - 90.0 \
                    - float(top.get_theme_constant("separation")) - glyph_w
                var fs: Array = _drawn_with(l)
                var drawn: float = (fs[0] as Font).get_string_size(
                    l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs[1])).x
                assert_true(drawn <= avail,
                    "%s at %d%% on a %d card: %.0f wide in %.0f" % [want, scale, width, drawn, avail])
                # Never smaller than the band line's own floor, and the
                # ellipsis stays as the last guard behind the ladder.
                assert_true(int(fs[1]) >= Type.at(Type.CLASS - 2, int(scale)),
                    "never smaller than CLASS-2 at %d%%" % scale)
                assert_eq(l.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS,
                    "the ellipsis is the last guard, not the fit")


func test_the_class_word_fit_takes_the_first_rung_that_fits() -> void:
    # The ladder itself (UI-31's three rungs), driven directly: a word that
    # fits keeps the variation's own size (1); one that does not drops to
    # CLASS-2 on the plain face (2); one that still does not asks the caller
    # for the two gutters (3). Rung 2 keeps the variation's line height so the
    # row does not jump.
    _at_scale(100)
    var l := Widgets.label_as("Warrior", "LabelClass")
    _made.append(l)
    var big: Array = Widgets.font_of("LabelClass", l)
    var whole: float = (big[0] as Font).get_string_size(
        "Warrior", HORIZONTAL_ALIGNMENT_LEFT, -1, int(big[1])).x
    assert_eq(Cards.fit_class_word(l, whole + 1.0, Cards.CLASS_ROW_GIVE), 1, "it fits as it is")
    assert_false(l.has_theme_font_size_override("font_size"), "and nothing was overridden")
    var l2 := Widgets.label_as("Warrior", "LabelClass")
    _made.append(l2)
    assert_eq(Cards.fit_class_word(l2, whole - 4.0, Cards.CLASS_ROW_GIVE), 2, "the small face fits")
    assert_eq(l2.get_theme_font_size("font_size"), Type.at(Type.CLASS - 2, 100), "at CLASS-2")
    assert_true(l2.custom_minimum_size.y >= (big[0] as Font).get_height(int(big[1])) - 0.01,
        "the row keeps the variation's line height")
    var l3 := Widgets.label_as("Warrior", "LabelClass")
    _made.append(l3)
    assert_eq(Cards.fit_class_word(l3, 8.0, Cards.CLASS_ROW_GIVE), 3, "the column has to give")


# ------------------------------------------ (10) the party's own number (UI-34)

func test_the_theme_carries_a_dealt_damage_variation_beside_the_taken_one() -> void:
    # UI-34: two directions of damage over one fight read as one colour today.
    # `LabelDamageDealt` is the party's harm ON the enemy — the CTA family's
    # lit warm tone, DANGER red kept for what the party TAKES — at the same
    # size and with the same 2px outline as its three siblings, so the kind
    # switch (RaidView's, by name) is a variation name and nothing else.
    var t: Theme = Theme_.build(100)
    assert_true(t.has_font_size("font_size", "LabelDamageDealt"), "the variation is in the theme")
    assert_eq(t.get_font_size("font_size", "LabelDamageDealt"), Type.DAMAGE,
        "the same size as the damage it answers")
    assert_eq(t.get_color("font_color", "LabelDamageDealt"), Palette.ACCENT_GOLD_LIGHT,
        "the CTA family's lit warm tone")
    assert_ne(t.get_color("font_color", "LabelDamage"), t.get_color("font_color", "LabelDamageDealt"),
        "taken and dealt are two colours")
    for n in ["LabelDamage", "LabelDamageCrit", "LabelHeal", "LabelDamageDealt"]:
        assert_eq(t.get_constant("outline_size", String(n)), 2, "%s keeps its 2px outline" % n)
        assert_eq(t.get_color("font_outline_color", String(n)), Palette.INK_NUMBER_OUTLINE,
            "%s outlines in the number ink" % n)
