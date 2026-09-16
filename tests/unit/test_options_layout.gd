extends "res://tests/TestCase.gd"
## W3-OPTIONS: the Load/Save and Settings finish (00-plan §4; HALL-15, HALL-16,
## HALL-17, HALL-25, CRITIC-G05, CRITIC-G06, CRITIC-G16).
##
## What a shot shows and a string test cannot: nine slot Buttons at ONE size,
## one reason Label per empty row (each phrase once), a human timestamp and no
## ISO-8601 string, the kit's confirm pair standing in for a row's buttons, the
## Settings rows at one pitch, engaged values on the lit chip, the volume ladder
## as pips beside the number, the disabled rows' controls dimmed and padlocked
## with the reason still a Label in the row, both panels ending at their
## content, Apply off the crimson plate. Layout is never run under `--script`
## (LESSONS: `_ready` never fires, no frame is laid out), so everything here
## reads what the screens SET — `custom_minimum_size`, `size`, names, texts,
## `button_pressed` — not what a layout pass would produce.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const LoadSaveScript = preload("res://game/screens/LoadSave.gd")
const SettingsScript = preload("res://game/screens/Settings.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Type = preload("res://game/ui/Type.gd")

const LOAD_SAVE := "res://game/screens/LoadSave.tscn"
const SETTINGS := "res://game/screens/Settings.tscn"
const TOWN := "res://game/screens/Town.tscn"

var _db = null
var _root: Node = null
var _host: Control = null
var _router = null
var _state = null
var _settings = null
var _made: Array = []


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []
    _ensure_autoloads()
    _state = _root.get_node_or_null("GameState")
    _router = _root.get_node_or_null("ScreenRouter")
    _settings = _root.get_node_or_null("GameSettings")
    _state.reset()
    _state.set_content(_db)
    _settings.reset_all()
    _host = Control.new()
    _host.name = "OptionsLayoutHost"
    _root.add_child(_host)
    _router.register_host(_host)
    SaveGame.purge_all()


func after_each() -> void:
    SaveGame.purge_all()
    if _settings != null:
        _settings.reset_all()
    if _state != null:
        _state.reset()
        _state.set_content(null)
    if is_instance_valid(_host):
        if _host.get_parent() != null:
            _host.get_parent().remove_child(_host)
        _host.free()
    _host = null
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


func _ensure_autoloads() -> void:
    if _root == null:
        return
    if _root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        _root.add_child(s)
        _made.append(s)
    if _root.get_node_or_null("ScreenRouter") == null:
        var r = Router.new()
        r.name = "ScreenRouter"
        _root.add_child(r)
        _made.append(r)
    if _root.get_node_or_null("GameSettings") == null:
        var g = GameSettings.new()
        g.name = "GameSettings"
        _root.add_child(g)
        _made.append(g)


func _screen():
    return _router.current_screen()


func _nodes(n: Node, out: Array = []) -> Array:
    out.append(n)
    for c in n.get_children():
        _nodes(c, out)
    return out


func _texts(n: Node) -> Array:
    var out: Array = []
    for node in _nodes(n):
        if node is Label:
            out.append((node as Label).text)
        elif node is Button:
            out.append((node as Button).text)
    return out


func _buttons(n: Node) -> Array:
    var out: Array = []
    for node in _nodes(n):
        if node is Button:
            out.append(node)
    return out


func _button(root: Node, fragment: String):
    for b in _buttons(root):
        if b.text.contains(fragment):
            return b
    return null


func _press(fragment: String) -> bool:
    for b in _buttons(_screen()):
        if b.disabled:
            continue
        if b.text.contains(fragment):
            b.pressed.emit()
            return true
    return false


func _named(root: Node, name: String) -> Array:
    var out: Array = []
    for node in _nodes(root):
        if String(node.name) == name:
            out.append(node)
    return out


## The kit names its reason Label "Reason"; LoadSave names a second one on the
## same row "Reason2" (the engine would otherwise rename it "@Label@N"), so a
## row's reasons are the Labels whose name carries the word.
func _reason_labels(root: Node) -> Array:
    var out: Array = []
    for node in _nodes(root):
        if node is Label and String(node.name).contains("Reason"):
            out.append(node)
    return out


func _count(items: Array, exact: String) -> int:
    var n := 0
    for t in items:
        if String(t) == exact:
            n += 1
    return n


func _mount_loadsave(with_guild: bool = true, saved_slots: Array = [0]) -> void:
    if with_guild:
        _state.new_game("Slotted", 4242)
        for slot in saved_slots:
            assert_eq(SaveGame.save_slot(int(slot), _state), "")
    assert_true(_router.goto(LOAD_SAVE), "the slots screen must mount")


func _mount_settings() -> void:
    assert_true(_router.goto(SETTINGS), "the options screen must mount")


# ---------------------------------------------------------------- LoadSave: HALL-15

func test_the_nine_slot_buttons_share_one_size() -> void:
    _mount_loadsave()
    var want := Vector2(LoadSaveScript.BTN_W, LoadSaveScript.BTN_H)
    var seen := 0
    for n in [1, 2, 3]:
        for text in ["Load — Slot %d" % n, "Save to Slot %d" % n, "Delete Slot %d" % n]:
            var b = _button(_screen(), text)
            assert_ne(b, null, "no button '%s'" % text)
            if b == null:
                continue
            seen += 1
            assert_eq((b as Button).custom_minimum_size, want,
                "'%s' is not at the row's one size" % text)
            assert_eq((b as Button).focus_mode, Control.FOCUS_ALL, "'%s' takes focus" % text)
    assert_eq(seen, 9, "three rows of three")
    # Three buttons at BTN_W with two BTN_GAPs fit the panel's inner width
    # (PANEL_W less the pad and PanelWarm's own 14px margin on each side).
    assert_true(3 * LoadSaveScript.BTN_W + 2 * LoadSaveScript.BTN_GAP
        <= LoadSaveScript.PANEL_W - 2 * (LoadSaveScript.PANEL_PAD + 14),
        "the row overflows the panel")


func test_an_empty_row_prints_its_reason_once_adjacent_to_both_disabled_buttons() -> void:
    _mount_loadsave()
    var shown: Array = _texts(_screen())
    assert_eq(_count(shown, "Slot 2 is empty."), 1, "once, not under each button:\n%s"
        % "\n".join(PackedStringArray(shown)))
    assert_eq(_count(shown, "Slot 3 is empty."), 1)
    assert_eq(_count(shown, "Slot 1 is empty."), 0, "slot 1 is full")
    for n in [2, 3]:
        var rows: Array = _named(_screen(), "SlotRow%d" % n)
        assert_eq(rows.size(), 1, "one row node for slot %d" % n)
        if rows.is_empty():
            continue
        var row: Node = rows[0]
        # docs/13 §7 / CRITIC-G06: the kit's ONE reason Label, in the row.
        var reasons: Array = _reason_labels(row)
        assert_eq(reasons.size(), 1, "one reason Label in row %d" % n)
        if reasons.size() == 1:
            assert_true(reasons[0] is Label)
            assert_eq((reasons[0] as Label).text, "Slot %d is empty." % n)
        # Both buttons the reason is for are disabled, dimmed and padlocked.
        for text in ["Load — Slot %d" % n, "Delete Slot %d" % n]:
            var b = _button(row, text)
            assert_ne(b, null, text)
            if b == null:
                continue
            assert_true((b as Button).disabled, "%s is refused" % text)
            assert_almost((b as Button).modulate.a, Widgets.REASONED_DIM, 0.01,
                "%s wears the kit's dim" % text)
            assert_ne((b as Button).icon, null, "%s wears the padlock" % text)
        var save = _button(row, "Save to Slot %d" % n)
        assert_ne(save, null)
        if save != null:
            assert_false((save as Button).disabled, "an empty slot can be written")
            assert_eq((save as Button).icon, null, "an enabled button wears no lock")
    # The full row has no reason at all.
    var full: Array = _named(_screen(), "SlotRow1")
    assert_eq(full.size(), 1)
    if full.size() == 1:
        assert_eq(_reason_labels(full[0]).size(), 0, "slot 1 has nothing to explain")


func test_the_title_screen_side_prints_each_reason_once_per_row() -> void:
    # Two distinct reasons on one row (Load/Delete: empty; Save: no guild) —
    # each once. No guild: the row must not say "Slot 2 is empty." twice.
    assert_false(_state.active)
    _mount_loadsave(false)
    var shown: Array = _texts(_screen())
    for n in [1, 2, 3]:
        assert_eq(_count(shown, "Slot %d is empty." % n), 1)
        var row: Node = _named(_screen(), "SlotRow%d" % n)[0]
        var reasons: Array = _reason_labels(row)
        assert_eq(reasons.size(), 2, "empty + no guild, once each, on row %d" % n)
        var texts: Array = []
        for r in reasons:
            texts.append((r as Label).text)
        assert_true("No guild loaded." in texts, str(texts))
        assert_true(("Slot %d is empty." % n) in texts, str(texts))


# ---------------------------------------------------------------- LoadSave: HALL-25

func test_a_full_row_prints_a_human_timestamp_and_no_iso_string() -> void:
    _mount_loadsave()
    var shown: Array = _texts(_screen())
    var iso := RegEx.new()
    iso.compile("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}")
    var human := RegEx.new()
    human.compile("^Written \\d{1,2} [A-Z][a-z]{2}, \\d{2}:\\d{2}$")
    var written := 0
    for t in shown:
        assert_eq(iso.search(String(t)), null, "an ISO-8601 stamp reached the player: %s" % t)
        assert_false(String(t).contains("save format"), "the format version is not a row line")
        if human.search(String(t)) != null:
            written += 1
    assert_eq(written, 1, "the full row says when it was written:\n%s"
        % "\n".join(PackedStringArray(shown)))
    # The format version lives on the row's tooltip, for a bug report.
    var row: Node = _named(_screen(), "SlotRow1")[0]
    var line: Node = _named(row, "SlotLine")[0]
    assert_true((line as Label).tooltip_text.begins_with("Save format v"),
        (line as Label).tooltip_text)
    var empty_row: Node = _named(_screen(), "SlotRow2")[0]
    assert_eq((_named(empty_row, "SlotLine")[0] as Label).tooltip_text, "")


func test_written_words_is_local_and_human() -> void:
    var human := RegEx.new()
    human.compile("^Written \\d{1,2} [A-Z][a-z]{2}, \\d{2}:\\d{2}$")
    var words: String = LoadSaveScript.written_words("2026-09-12T18:37:59")
    assert_ne(human.search(words), null, words)
    assert_false(words.contains("2026"), "no year, no ISO")
    assert_eq(LoadSaveScript.written_words(""), "")
    assert_eq(LoadSaveScript.written_words("not a date"), "")
    # The UTC hour shifts by the machine's zone; the minute never does.
    assert_true(words.ends_with(":37"), words)


# ---------------------------------------------------------------- LoadSave: CRITIC-G05

func test_a_destructive_press_turns_the_rows_buttons_into_the_kits_confirm_pair() -> void:
    _mount_loadsave()
    assert_true(_press("Delete Slot 1"))
    var row: Node = _named(_screen(), "SlotRow1")[0]
    var plates: Array = _named(row, "Confirm")
    assert_eq(plates.size(), 1, "the kit's plate, once")
    if plates.size() != 1:
        return
    var plate: Control = plates[0]
    var yes = _button(plate, "Yes — delete Slot 1")
    var no = _button(plate, "Keep it")
    assert_ne(yes, null)
    assert_ne(no, null)
    assert_eq(Widgets.default_focus_of(plate), no, "the safe choice is the default focus")
    assert_eq(_button(row, "Load — Slot 1"), null, "the pair stands where the three stood")
    assert_eq(_button(row, "Save to Slot 1"), null)
    assert_true(_press("Keep it"))
    assert_ne(_button(_screen(), "Load — Slot 1"), null, "Keep it puts the three back")
    assert_ne(_button(_screen(), "Delete Slot 1"), null)
    assert_eq(_named(_screen(), "Confirm").size(), 0)


# ---------------------------------------------------------------- LoadSave: HALL-16

func test_the_slots_panel_ends_at_its_content() -> void:
    _mount_loadsave()
    var fit: Dictionary = _screen().panel_fit()
    assert_false(fit.is_empty(), "the panel seam")
    if fit.is_empty():
        return
    assert_true(float(fit["content_h"]) > 0.0)
    assert_true(float(fit["panel_h"]) - float(fit["content_h"]) <= 60.0,
        "panel %.0f vs content %.0f" % [fit["panel_h"], fit["content_h"]])
    assert_true(float(fit["panel_h"]) >= float(fit["content_h"]), "never shorter than its rows")
    assert_true(float(fit["panel_h"]) < float(fit["host_h"]),
        "the camp shows under the rows as well as beside them")
    assert_eq(float(fit["panel_w"]), float(LoadSaveScript.PANEL_W))


func test_every_visible_button_on_the_slots_screen_takes_focus() -> void:
    _mount_loadsave()
    for b in _buttons(_screen()):
        if (b as Button).is_visible_in_tree():
            assert_eq((b as Button).focus_mode, Control.FOCUS_ALL, (b as Button).text)


# ---------------------------------------------------------------- Settings: HALL-17

func test_every_option_row_has_the_same_pitch() -> void:
    _mount_settings()
    var fit: Dictionary = _screen().panel_fit()
    assert_eq(int(fit["row_h"]), Type.at(SettingsScript.ROW_H, 100))
    var rows := 0
    # W6-SETTINGS: ROWS is the table as shown; a hidden row (LOOP-26) sits in
    # HIDDEN_ROWS for its key and is never built.
    for row in SettingsScript.ROWS:
        var lines: Array = _named(_screen(), "Row_" + String(row["key"]))
        assert_eq(lines.size(), 1, "one row for %s" % row["key"])
        if lines.size() != 1:
            continue
        rows += 1
        assert_eq((lines[0] as Control).custom_minimum_size.y, float(fit["row_h"]),
            "%s is off the table's pitch" % row["key"])
    assert_eq(rows, SettingsScript.ROWS.size())
    for row in SettingsScript.HIDDEN_ROWS:
        assert_eq(_named(_screen(), "Row_" + String(row["key"])).size(), 0,
            "%s is hidden and not built" % row["key"])


func test_engaged_values_sit_on_the_lit_chip() -> void:
    _settings.set_value("sim_speed", 1)
    _settings.set_value("display_aspect", "keep")
    _mount_settings()
    var on_seen := 0
    var off_seen := 0
    for b in _buttons(_screen()):
        var btn: Button = b
        match btn.text:
            "On":
                on_seen += 1
                assert_eq(String(btn.theme_type_variation), "ButtonChip")
                assert_true(btn.toggle_mode and btn.button_pressed, "On is lit")
            "Off":
                off_seen += 1
                assert_eq(String(btn.theme_type_variation), "ButtonChip")
                assert_false(btn.button_pressed, "Off is not")
            "2x":
                assert_true(btn.button_pressed, "a non-default speed is lit")
            "Keep":
                assert_false(btn.button_pressed, "the default aspect is not")
            "100%":
                assert_false(btn.button_pressed, "the default scale is not")
    assert_true(on_seen >= 1, "comedy brake is On by default")
    assert_true(off_seen >= 3)
    # Pressing still cycles through the row's own handler (the toggle never drifts).
    assert_true(_press("2x"))
    assert_eq(int(_settings.get_value("sim_speed")), 2)
    assert_ne(_button(_screen(), "4x"), null, "the row was rebuilt with the new value")


func test_a_volume_row_draws_its_ladder_as_pips_beside_the_number() -> void:
    _settings.set_value("audio_music", 60)
    _settings.set_value("audio_ui", 0)
    _mount_settings()
    var steps: int = SettingsScript.VOLUME_STEPS.size() - 1
    var music: Array = _named(_screen(), "Volume_audio_music")
    assert_eq(music.size(), 1)
    if music.size() != 1:
        return
    var pips: Array = _named(music[0], "Pips")
    assert_eq(pips.size(), 1)
    assert_eq(pips[0].get_child_count(), steps, "one pip per audible step of the ladder")
    var lit := 0
    for pip in pips[0].get_children():
        assert_eq((pip as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE)
        if float(pip.get("value")) >= 1.0:
            lit += 1
    assert_eq(lit, 3, "60 lights 20, 40 and 60")
    var number = _button(music[0], "60")
    assert_ne(number, null, "the number stays Button.text")
    assert_eq((number as Button).focus_mode, Control.FOCUS_ALL)
    # The Voice row is hidden (W6-SETTINGS), so the mute strip is read off the
    # interface row.
    var ui: Node = _named(_screen(), "Volume_audio_ui")[0]
    var none := 0
    for pip in _named(ui, "Pips")[0].get_children():
        if float(pip.get("value")) >= 1.0:
            none += 1
    assert_eq(none, 0, "mute is an empty strip")
    assert_ne(_button(ui, "0"), null)
    assert_eq(_named(_screen(), "Volume_audio_voice").size(), 0,
        "the Voice row is hidden: nothing is voiced")


# ---------------------------------------------------------------- Settings: CRITIC-G06

func test_a_disabled_row_keeps_its_reason_in_the_row_and_its_control_dimmed() -> void:
    _mount_settings()
    # W6-SETTINGS (LOOP-26): no shipped row is padlocked any more — a row whose
    # subsystem is missing is hidden, and every visible row is live and silent.
    for row in SettingsScript.ROWS:
        assert_eq(String(row["reason"]), "", "%s is live" % row["key"])
        var line: Node = _named(_screen(), "Row_" + String(row["key"]))[0]
        assert_eq(_reason_labels(line).size(), 0, "%s is live and says nothing" % row["key"])
        var live: Button = Widgets.button_of(line)
        assert_ne(live, null, "%s has a control" % row["key"])
        if live != null:
            assert_false(live.disabled, "%s is not padlocked" % row["key"])
            assert_eq(live.icon, null, "%s wears no lock" % row["key"])
    # The treatment itself (CRITIC-G06) still holds for a row that IS disabled
    # for a reason: built through the row builder, since no shipped row is.
    var reason := "The desk is closed for the night."
    var line: Control = _screen()._option_row(
        {"key": "vsync", "label": "V-sync", "reason": reason, "note": ""})
    _made.append(line)
    var reasons: Array = _reason_labels(line)
    assert_eq(reasons.size(), 1, "one reason Label, in the row")
    if reasons.size() == 1:
        assert_eq((reasons[0] as Label).text, reason)
    var ctrl: Button = Widgets.button_of(line)
    assert_ne(ctrl, null, "the row has a control")
    if ctrl == null:
        return
    assert_true(ctrl.disabled)
    assert_ne(ctrl.icon, null, "wears the padlock")
    assert_almost(ctrl.modulate.a, Widgets.REASONED_DIM, 0.01, "is dimmed")


# ---------------------------------------------------------------- Settings: HALL-16 / CRITIC-G16

func test_the_options_panel_ends_at_its_last_row_above_the_stage_band() -> void:
    _mount_settings()
    var fit: Dictionary = _screen().panel_fit()
    assert_false(fit.is_empty())
    if fit.is_empty():
        return
    assert_true(float(fit["panel_h"]) - float(fit["content_h"]) <= 60.0,
        "panel %.0f vs content %.0f" % [fit["panel_h"], fit["content_h"]])
    assert_true(float(fit["panel_h"]) >= float(fit["content_h"]))
    assert_true(float(fit["panel_h"]) <= float(fit["host_h"]) - SettingsScript.BAND_H,
        "the stage's band under the panel is kept")


func test_apply_is_a_lit_secondary_and_the_screen_has_no_crimson_commit() -> void:
    _mount_settings()
    var apply = _button(_screen(), "Apply")
    assert_ne(apply, null)
    if apply != null:
        assert_eq(String((apply as Button).theme_type_variation), SettingsScript.APPLY_VARIATION)
        assert_false((apply as Button).disabled)
    for b in _buttons(_screen()):
        assert_false(String((b as Button).theme_type_variation).begins_with("ButtonCta"),
            "options spend nothing, so nothing here is crimson: %s" % (b as Button).text)
        if (b as Button).is_visible_in_tree():
            assert_eq((b as Button).focus_mode, Control.FOCUS_ALL, (b as Button).text)


func test_at_150_the_rows_scale_and_the_table_scrolls_inside_the_band() -> void:
    _settings.set_value("text_scale", 150)
    _mount_settings()
    var fit: Dictionary = _screen().panel_fit()
    assert_eq(int(fit["row_h"]), Type.at(SettingsScript.ROW_H, 150))
    for row in SettingsScript.ROWS:
        var line: Node = _named(_screen(), "Row_" + String(row["key"]))[0]
        assert_eq((line as Control).custom_minimum_size.y, float(fit["row_h"]))
    assert_true(float(fit["panel_h"]) <= float(fit["host_h"]) - SettingsScript.BAND_H,
        "the panel never eats the band; the table scrolls")
    _settings.set_value("text_scale", 100)
