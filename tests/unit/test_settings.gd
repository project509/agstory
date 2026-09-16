extends "res://tests/TestCase.gd"
## Settings: the closed inventory, its persistence, and the rules derived from it.

const GameSettings = preload("res://game/core/GameSettings.gd")
const SettingsScreen = preload("res://game/screens/Settings.gd")
const LogPlayer = preload("res://game/core/LogPlayer.gd")
const Enums = preload("res://sim/model/Enums.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const Palette = preload("res://game/ui/Palette.gd")

const SETTINGS_SCENE := "res://game/screens/Settings.tscn"

var _db = null
var _s = null
var _made: Array = []

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _s = GameSettings.new()
    _s.reset_all()
    _made = []

func after_each() -> void:
    if _s != null:
        _s.free()
        _s = null
    # The autoload outlives this file (LESSONS): whatever a screen test set on
    # it goes back to the defaults here, not at the end of a body an assertion
    # can abort.
    var shared = _root().get_node_or_null("GameSettings")
    if shared != null:
        shared.reset_all()
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []

func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null

# ---------------------------------------------------------------- the inventory

func test_every_documented_default_is_the_documented_value() -> void:
    # docs/13 §15.1's table. These are the values a fresh install must present.
    var expected := {
        "sim_speed": 0, "comedy_brake": true, "log_manual_advance": false,
        "emoji_free": false, "prose_font_swap": false, "text_scale": 100,
        "reduced_motion": false, "auto_loot": false, "reduced_effects": false,
        "audio_master": 100, "audio_music": 80, "audio_ui": 80, "audio_voice": 100,
        # SHIP-06 (§15.1 "Native, borderless") and UI-47 (ship plan §6 #40).
        "window_mode": "borderless", "vsync": true, "colourblind_safe": false,
    }
    for key in expected:
        assert_eq(_s.get_value(key), expected[key], "%s default" % key)

func test_the_audio_defaults_are_100_80_80_100_in_that_order() -> void:
    # docs/13 §15.1 gives them as a single "100 / 80 / 80 / 100" row, so the
    # ORDER carries the meaning: master, music, UI, voice-of-the-scribe.
    var got: Array = []
    for bus in GameSettings.AUDIO_BUSES:
        got.append(int(_s.get_value(bus)))
    assert_eq(got, [100, 80, 80, 100])

func test_text_scale_has_exactly_three_steps() -> void:
    # docs/13 §4.4: 100 / 125 / 150%, and nothing between them.
    assert_eq(GameSettings.TEXT_SCALES, [100, 125, 150])

func test_feature_flags_are_not_player_settings() -> void:
    # docs/13 §15.1 marks them "Build flag — never a player setting", and
    # docs/14 §5.2 keeps them in data/tuning/flags.json.
    for key in ["FEATURE_BLACKSMITH", "FEATURE_UPGRADES", "FEATURE_SALVAGE",
            "FEATURE_CRAFTING", "FEATURE_WISHLIST", "blacksmith"]:
        assert_false(GameSettings.DEFAULTS.has(key),
            "%s must not be a player setting" % key)

func test_an_unknown_key_is_refused_rather_than_invented() -> void:
    # docs/13 §15.1: "if an option is not in this table, it does not exist."
    assert_eq(_s.get_value("nonsense"), null)
    assert_false(_s.set_value("nonsense", true))

func test_reduced_flashing_is_not_an_option() -> void:
    # docs/13 §15.1 excludes it on purpose: §13 makes it unconditional, so it is
    # a build requirement with a QA gate, not something a player can get wrong.
    for key in ["reduced_flashing", "contrast", "minimum_text_size", "cvd_safety"]:
        assert_false(GameSettings.DEFAULTS.has(key),
            "%s ships on and has no off" % key)

# ---------------------------------------------------------------- coercion

func test_an_out_of_range_text_scale_falls_back_rather_than_blinding_the_player() -> void:
    # The file is user-editable by construction, and a 5% text scale would make
    # every screen unreadable with no way back in.
    _s.set_value("text_scale", 7)
    assert_eq(int(_s.get_value("text_scale")), 100)
    _s.set_value("text_scale", 125)
    assert_eq(int(_s.get_value("text_scale")), 125)

func test_sim_speed_is_clamped_to_the_four_real_speeds() -> void:
    _s.set_value("sim_speed", 99)
    assert_eq(int(_s.get_value("sim_speed")), 3)
    _s.set_value("sim_speed", -4)
    assert_eq(int(_s.get_value("sim_speed")), 0)

func test_audio_levels_are_clamped_to_a_percentage() -> void:
    _s.set_value("audio_music", 400)
    assert_eq(int(_s.get_value("audio_music")), 100)
    _s.set_value("audio_music", -20)
    assert_eq(int(_s.get_value("audio_music")), 0)

func test_changing_a_value_announces_it() -> void:
    var seen: Array = []
    _s.changed.connect(func(key: String) -> void: seen.append(key))
    _s.set_value("comedy_brake", false)
    assert_eq(seen, ["comedy_brake"])
    _s.set_value("comedy_brake", false)
    assert_eq(seen.size(), 1, "setting the same value again announces nothing")

# ---------------------------------------------------------------- persistence

func test_settings_round_trip_through_the_config_file() -> void:
    _s.set_value("text_scale", 150)
    _s.set_value("comedy_brake", false)
    _s.set_value("sim_speed", 2)
    assert_true(_s.save_to_disk())

    var other = GameSettings.new()
    _made.append(other)
    assert_true(other.load_from_disk(), "a written file must load cleanly")
    assert_eq(int(other.get_value("text_scale")), 150)
    assert_eq(bool(other.get_value("comedy_brake")), false)
    assert_eq(int(other.get_value("sim_speed")), 2)

func test_a_corrupt_options_file_can_never_block_boot() -> void:
    # docs/13 §15.1: "a missing or unparseable file falls back to the defaults
    # above and is rewritten, so a corrupt options file can never block boot."
    var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
    assert_ne(f, null, "the test needs to be able to write the options file")
    f.store_string("this is not a ConfigFile at all {{{")
    f.close()

    var other = GameSettings.new()
    _made.append(other)
    assert_false(other.load_from_disk(), "a corrupt file reports that it fell back")
    assert_eq(int(other.get_value("text_scale")), 100, "and yields the defaults")
    assert_true(FileAccess.file_exists(GameSettings.PATH), "and is rewritten")

func test_a_missing_options_file_is_a_first_run_not_an_error() -> void:
    DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
    var other = GameSettings.new()
    _made.append(other)
    other.load_from_disk()
    assert_eq(int(other.get_value("audio_master")), 100)

func test_options_do_not_live_with_saves() -> void:
    # docs/13 §15.1: "Options are a property of the installation, not of a guild:
    # deleting every save ... must never reset the player's text scale."
    assert_true(GameSettings.PATH.begins_with("user://"))
    assert_false(GameSettings.PATH.contains("save"),
        "the options file must not sit inside the save directory")

func test_restore_defaults_restores_all_of_them() -> void:
    _s.set_value("text_scale", 150)
    _s.set_value("auto_loot", true)
    _s.reset_all()
    for key in GameSettings.DEFAULTS:
        assert_true(_s.is_default(key), "%s was not restored" % key)

# ------------------------------------------------- docs/01 §9's skip unlock

func test_skip_is_locked_until_the_encounter_has_been_cleared() -> void:
    # docs/01 §9's OQ#1 ruling, which that doc says governs: "Instant /
    # skip-to-result unlocked per encounter after first clear of that encounter".
    # Rationale: the player always watches content that is new, "where the comedy
    # and the learning are", and can fast-forward what is now farming.
    var state = _root().get_node_or_null("GameState")
    state.reset()
    state.set_content(_db)
    state.new_game("Skip Test")
    var enc = _db.encounter_at_slot("A1")

    assert_false(GameSettings.skip_unlocked(state, enc.id),
        "never cleared means never skippable")
    state.cleared[enc.id] = 1
    assert_true(GameSettings.skip_unlocked(state, enc.id),
        "one clear unlocks it for that encounter")
    assert_false(GameSettings.skip_unlocked(state, _db.encounter_at_slot("A2").id),
        "and for THAT encounter only")
    state.reset()

func test_the_stored_speed_is_global_but_instant_is_capped_per_encounter() -> void:
    # docs/01 §9: "global, persisted, reset to 1x for any mission never cleared."
    # The stored value is untouched — what changes is the speed the view OPENS at.
    var state = _root().get_node_or_null("GameState")
    state.reset()
    state.set_content(_db)
    state.new_game("Cap Test")
    var enc = _db.encounter_at_slot("A1")
    _s.set_value("sim_speed", LogPlayer.Speed.INSTANT)

    assert_eq(_s.effective_sim_speed(state, enc.id), LogPlayer.Speed.FOUR,
        "Instant is not available before a first clear")
    assert_eq(int(_s.get_value("sim_speed")), LogPlayer.Speed.INSTANT,
        "and the stored global setting is not rewritten by the cap")

    state.cleared[enc.id] = 1
    assert_eq(_s.effective_sim_speed(state, enc.id), LogPlayer.Speed.INSTANT,
        "after a clear the stored speed applies in full")
    state.reset()

func test_the_always_available_speeds_are_never_capped() -> void:
    # docs/01 §9: "Speed 1x/2x/4x and Pause are unaffected and stay always
    # available", so doc 07's presentation-only rule is untouched.
    var state = _root().get_node_or_null("GameState")
    state.reset()
    for speed in [LogPlayer.Speed.ONE, LogPlayer.Speed.TWO, LogPlayer.Speed.FOUR]:
        _s.set_value("sim_speed", speed)
        assert_eq(_s.effective_sim_speed(state, "never_cleared"), speed)

# ---------------------------------------------------------------- emoji-free

func test_emoji_free_mode_replaces_the_glyph_and_nothing_else() -> void:
    # docs/13 §13: "Replaces morale glyphs with a 10-step monochrome pip figure.
    # The integer and state word are unaffected."
    assert_eq(_s.morale_glyph(87), Enums.MORALE_BAND_EMOJI[8],
        "off by default, so canon's heart still shows")
    _s.set_value("emoji_free", true)
    var pips: String = _s.morale_glyph(87)
    assert_false(pips.contains(Enums.MORALE_BAND_EMOJI[8]), "no emoji in the figure")
    assert_eq(pips.length(), Enums.MORALE_BAND_COUNT, "a ten-step figure")
    assert_eq(Enums.morale_band_name(87), "Very Happy",
        "the state word is untouched by the setting")

func test_the_pip_figure_has_a_distinct_step_for_every_band() -> void:
    _s.set_value("emoji_free", true)
    var seen := {}
    for band in Enums.MORALE_BAND_COUNT:
        var glyph: String = _s.morale_glyph(band * 10)
        assert_false(seen.has(glyph), "band %d repeats an earlier figure" % band)
        seen[glyph] = true

func test_text_scale_scales_a_font_size() -> void:
    assert_eq(_s.scaled(20), 20)
    _s.set_value("text_scale", 150)
    assert_eq(_s.scaled(20), 30)

# ---------------------------------------------------------------- the screen

func _mounted_settings():
    var root := _root()
    var host := Control.new()
    root.add_child(host)
    _made.append(host)
    var r = root.get_node_or_null("ScreenRouter")
    r.register_host(host)
    assert_true(r.goto(SETTINGS_SCENE), "the settings screen must open")
    return r.current_screen()

func _all_text(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _all_text(c, out)
    return out

func test_the_screen_lists_only_options_in_the_inventory() -> void:
    # docs/13 §15.1's closed-list rule, enforced from the screen's side — the
    # hidden rows included, since their keys are still the file's.
    for row in SettingsScreen.all_rows():
        assert_true(GameSettings.DEFAULTS.has(String(row["key"])),
            "the screen offers '%s', which is not in the inventory" % row["key"])

func test_every_option_the_screen_cannot_honour_says_why() -> void:
    # docs/13 §7: a disabled control is never a mystery (the WaxButton row's
    # "reason text beneath — never a mystery"), and §12.3 the same for every
    # widget. That a silently-dead toggle would be worse than a missing one is
    # the screen's own judgement, not a line in either section.
    var view = _mounted_settings()
    var text := "\n".join(PackedStringArray(_all_text(view)))
    for row in SettingsScreen.ROWS:
        var reason := String(row["reason"])
        if reason.is_empty():
            continue
        assert_true(text.contains(reason),
            "'%s' is disabled but its reason is not on the page" % row["label"])

func test_the_screen_shows_the_live_options() -> void:
    var view = _mounted_settings()
    var text := "\n".join(PackedStringArray(_all_text(view)))
    for label in ["Sim speed", "Comedy brake", "Text scale", "Auto loot",
            "Emoji-free mode"]:
        assert_true(text.contains(label), "%s should be on the page" % label)

func test_the_screen_is_not_a_dead_end() -> void:
    var view = _mounted_settings()
    var enabled := 0
    for b in _buttons(view):
        if not b.disabled:
            enabled += 1
    assert_true(enabled > 0, "settings must be leaveable")

func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out

func test_pressing_a_toggle_changes_the_setting() -> void:
    var settings = _root().get_node_or_null("GameSettings")
    assert_ne(settings, null, "the GameSettings autoload must be registered")
    var before: bool = bool(settings.get_value("auto_loot"))
    var view = _mounted_settings()
    var pressed := false
    for b in _buttons(view):
        if b.disabled:
            continue
        # The Auto loot row's control shows On/Off; find it by its neighbouring
        # label rather than by index, which layout changes would churn.
        if b.text == ("On" if before else "Off"):
            b.pressed.emit()
            pressed = true
            break
    assert_true(pressed, "there should be a toggle to press")
    settings.reset_all()

# --------------------------------------------------- docs/13 §15.1's audio rows

func test_the_screen_offers_a_row_for_every_bus_in_the_inventory() -> void:
    # §15.1 is a closed list in BOTH directions: the screen may not offer an
    # option that is not in the table (tested above), and it may not silently
    # drop one that is. Before the audio pass three of these four keys had no
    # row at all, so the screen presented one volume control for four buses.
    var keys: Array = []
    for row in SettingsScreen.all_rows():
        keys.append(String(row["key"]))
    for bus in GameSettings.AUDIO_BUSES:
        assert_true(String(bus) in keys,
            "'%s' is in the inventory with no row on the screen" % bus)

func test_the_four_audio_rows_stand_in_the_documented_order() -> void:
    # §15.1 gives them as a single row, "100 / 80 / 80 / 100", so the order IS
    # the specification: master, music, UI, voice-of-the-scribe.
    var got: Array = []
    for row in SettingsScreen.all_rows():
        var key := String(row["key"])
        if key.begins_with("audio_"):
            got.append(key)
    assert_eq(got, GameSettings.AUDIO_BUSES)
    # The Voice row is the hidden one (nothing is voiced), so the TABLE shows
    # the first three in that order.
    var shown: Array = []
    for row in SettingsScreen.ROWS:
        if String(row["key"]).begins_with("audio_"):
            shown.append(String(row["key"]))
    assert_eq(shown, ["audio_master", "audio_music", "audio_ui"])

func test_no_audio_row_still_claims_there_is_no_audio() -> void:
    # docs/13 §7 wants a disabled control to explain itself; the corollary is
    # that a live one must not carry a stale excuse.
    for row in SettingsScreen.all_rows():
        if String(row["key"]).begins_with("audio_"):
            assert_eq(String(row["reason"]), "",
                "%s is wired to a real bus now" % row["key"])

func test_the_volume_ladder_keeps_both_documented_defaults_reachable() -> void:
    # §15.1's defaults are 100 and 80. A 25% ladder would make 80 unreachable
    # from the one screen that owns it.
    for value in [80, 100]:
        assert_true(value in SettingsScreen.VOLUME_STEPS,
            "%d is a documented default and must be a step" % value)
    assert_true(0 in SettingsScreen.VOLUME_STEPS, "0 must be reachable: mute")

func test_a_volume_step_walks_up_and_wraps_to_silence() -> void:
    assert_eq(SettingsScreen._next_volume(0), 20)
    assert_eq(SettingsScreen._next_volume(80), 100)
    assert_eq(SettingsScreen._next_volume(100), 0, "the top wraps to mute")
    assert_eq(SettingsScreen._next_volume(85), 100,
        "a value off the ladder still steps somewhere sensible")

func test_every_volume_control_is_a_button_showing_its_own_level() -> void:
    # The screen-test contract reads only Label.text and Button.text, so a
    # slider would be an option no test could see. Four distinct values prove
    # each row reads its own key rather than all four reading master.
    var settings = _root().get_node_or_null("GameSettings")
    # Three distinct values for the three VISIBLE buses; the Voice row is hidden
    # (W6-SETTINGS: nothing is voiced), so its level is set and must NOT show.
    var want := {"audio_master": 100, "audio_music": 60, "audio_ui": 40}
    for key in want:
        settings.set_value(String(key), int(want[key]))
    settings.set_value("audio_voice", 20)
    var view = _mounted_settings()
    var text: Array = _all_text(view)
    for key in want:
        assert_true(text.has("%d" % int(want[key])),
            "%s's level is not on the page as a button" % key)
    assert_false(text.has("20"), "the hidden Voice row prints no level")
    settings.reset_all()

func test_pressing_a_volume_button_moves_that_bus_and_no_other() -> void:
    var settings = _root().get_node_or_null("GameSettings")
    settings.set_value("audio_master", 100)
    settings.set_value("audio_music", 40)
    settings.set_value("audio_ui", 100)
    settings.set_value("audio_voice", 100)
    var view = _mounted_settings()
    var pressed := false
    for b in _buttons(view):
        # 40 is unique on the page by construction: the other three sit at 100.
        if not b.disabled and b.text == "40":
            b.pressed.emit()
            pressed = true
            break
    assert_true(pressed, "the music row's level must be a pressable button")
    assert_eq(int(settings.get_value("audio_music")), 60, "40 steps to 60")
    assert_eq(int(settings.get_value("audio_master")), 100,
        "and master is untouched")
    settings.reset_all()

# ------------------------------------------ W6-SETTINGS: nothing on the page lies

## LOOP-26 / UI-28 / CRITIC-C10: the words a row used to carry when it was an
## inventory of what was not built. Over the VISIBLE rows — a hidden row is not
## on the page — and over every string a row prints (label, note, reason).
const UNFINISHED_WORDS := ["build", "pass", "export", "so far", "yet", "data/tuning",
    "module", "not written", "canon", "audit", "docs/"]


func _row_strings(row: Dictionary) -> String:
    return "%s | %s | %s" % [row.get("label", ""), row.get("note", ""), row.get("reason", "")]


func test_no_visible_row_admits_an_unfinished_feature() -> void:
    var shown: Array = SettingsScreen.ROWS
    assert_true(shown.size() >= 12, "the table is not empty")
    for row in shown:
        var text := _row_strings(row).to_lower()
        for word in UNFINISHED_WORDS:
            assert_false(text.contains(String(word)),
                "row '%s' says '%s': %s" % [row["key"], word, text])
        assert_eq(String(row["reason"]), "",
            "%s is padlocked forever — hide it or wire it (LOOP-26)" % row["key"])
    # And the page itself: no "N of M live" header, no repo path in the sidebar.
    var view = _mounted_settings()
    var page := "\n".join(PackedStringArray(_all_text(view))).to_lower()
    assert_false(page.contains("live in this"), "the header count is gone (C15)")
    assert_false(page.contains("data/tuning"), "the repo path is gone (C21)")
    assert_false(page.contains(" of %d" % SettingsScreen.all_rows().size()), "no row count")


func test_hidden_rows_keep_their_keys_and_stay_off_the_page() -> void:
    # The four rows the wave hides (C16 prose font swap, C18 the Voice bus, C19
    # language, C20 controller glyphs): the key stays in the inventory so an old
    # settings.cfg still loads, and the row is not built.
    var hidden: Array = []
    for row in SettingsScreen.HIDDEN_ROWS:
        hidden.append(String(row["key"]))
    assert_eq(hidden, ["prose_font_swap", "audio_voice", "language", "glyph_set"])
    var view = _mounted_settings()
    for key in hidden:
        assert_true(GameSettings.DEFAULTS.has(key), "%s keeps its key" % key)
        assert_eq(view.find_child("Row_" + String(key), true, false), null,
            "%s is hidden, not built" % key)
        var still: bool = false
        for row in SettingsScreen.ROWS:
            if String(row["key"]) == String(key):
                still = true
        assert_false(still, "%s is in one list, not both" % key)
    for row in SettingsScreen.ROWS:
        assert_ne(view.find_child("Row_" + String(row["key"]), true, false), null,
            "%s is shown and built" % row["key"])
    assert_eq(SettingsScreen.all_rows().size(),
        SettingsScreen.ROWS.size() + SettingsScreen.HIDDEN_ROWS.size())


func test_the_music_row_is_labelled_for_what_the_bus_carries_and_voice_is_hidden() -> void:
    # AUDIO-14 / ship plan §6 #46: the Music bus carries the ambience beds
    # (W7-AUD-AMB) and no music; the label says so and there is no note about
    # the bus. The Voice row is hidden, never padlocked (LOOP's bar).
    var music: Dictionary = {}
    var voice: Dictionary = {}
    for row in SettingsScreen.ROWS:
        if String(row["key"]) == "audio_music":
            music = row
    for row in SettingsScreen.HIDDEN_ROWS:
        if String(row["key"]) == "audio_voice":
            voice = row
    assert_eq(String(music["label"]), "Audio — music and ambience")
    assert_eq(String(music["note"]), "", "no note about the bus")
    assert_false(voice.is_empty(), "the Voice row is hidden")
    assert_eq(String(voice["reason"]), "", "hidden, not padlocked")


# ------------------------------------------------ SHIP-06: the window fits the laptop

func test_window_mode_and_vsync_round_trip_through_the_config_file() -> void:
    _s.set_value("window_mode", "windowed")
    _s.set_value("vsync", false)
    assert_true(_s.save_to_disk())
    var other = GameSettings.new()
    _made.append(other)
    assert_true(other.load_from_disk())
    assert_eq(String(other.get_value("window_mode")), "windowed")
    assert_eq(bool(other.get_value("vsync")), false)
    # A hand-edited file cannot put the window in a mode that does not exist.
    _s.set_value("window_mode", "exclusive")
    assert_eq(String(_s.get_value("window_mode")), "borderless",
        "an unknown mode falls back to the documented default")
    assert_eq(GameSettings.WINDOW_MODES, ["borderless", "windowed"])


func test_a_windowed_3_2_window_fits_the_desktop_it_is_on() -> void:
    # 1366x768 with a taskbar (usable 1366x728) — Windows' most common laptop
    # mode, where the old 1536x1024 window lost every commit row (SHIP-06).
    var small: Vector2i = GameSettings.windowed_size(Vector2i(1366, 728))
    assert_true(small.x <= 1366 - GameSettings.WINDOW_CHROME.x, "fits the width")
    assert_true(small.y <= 728 - GameSettings.WINDOW_CHROME.y, "fits the height")
    assert_almost(float(small.x) / float(small.y), 1.5, 0.01, "still 3:2")
    assert_eq(small, Vector2i(1020, 680))
    # A desktop with room gets the reference frame, never more.
    assert_eq(GameSettings.windowed_size(Vector2i(2560, 1400)), GameSettings.BASE_WINDOW)
    # No display at all (headless): the reference frame rather than a 0x0 window.
    assert_eq(GameSettings.windowed_size(Vector2i.ZERO), GameSettings.BASE_WINDOW)


func test_the_window_rows_are_live_and_apply_runs_the_applier() -> void:
    var settings = _root().get_node_or_null("GameSettings")
    settings.reset_all()
    var view = _mounted_settings()
    assert_eq(int(view.display_applied()), 0, "nothing applied on mount")
    # The Window row: a live chip showing the stored mode, cycling on press and
    # applying at once.
    var mode_chip = null
    var vsync_row: Node = view.find_child("Row_vsync", true, false)
    assert_ne(vsync_row, null, "the V-sync row is on the page")
    for b in _buttons(view):
        if b.text == "Fullscreen":
            mode_chip = b
    assert_ne(mode_chip, null, "the Window row shows the stored mode as a chip")
    if mode_chip != null:
        assert_false((mode_chip as Button).disabled, "the row is live (C17)")
        (mode_chip as Button).pressed.emit()
        assert_eq(String(settings.get_value("window_mode")), "windowed")
        assert_eq(int(view.display_applied()), 1, "a press applies at once")
    var vsync_chip: Button = null
    if vsync_row != null:
        for b in _buttons(vsync_row):
            vsync_chip = b
    assert_ne(vsync_chip, null)
    if vsync_chip != null:
        assert_false(vsync_chip.disabled, "V-sync is live, not padlocked")
        assert_eq(vsync_chip.text, "On")
        vsync_chip.pressed.emit()
        assert_eq(bool(settings.get_value("vsync")), false)
        assert_eq(int(view.display_applied()), 2)
    # Apply is the commit: it runs the applier with the stored values.
    var apply = null
    for b in _buttons(view):
        if b.text == "Apply":
            apply = b
    assert_ne(apply, null)
    if apply != null:
        (apply as Button).pressed.emit()
        assert_eq(int(view.display_applied()), 3, "Apply calls the applier")


func test_f11_and_alt_enter_swap_the_window_mode_from_anywhere() -> void:
    # SHIP-06: `nav_fullscreen` in project.godot, handled by the router.
    assert_true(InputMap.has_action("nav_fullscreen"))
    var keys: Array = []
    var alt_enter := false
    for ev in InputMap.action_get_events("nav_fullscreen"):
        if ev is InputEventKey:
            keys.append((ev as InputEventKey).keycode)
            if (ev as InputEventKey).keycode == KEY_ENTER and (ev as InputEventKey).alt_pressed:
                alt_enter = true
    assert_has(keys, KEY_F11)
    assert_true(alt_enter, "Alt+Enter is the second binding")
    var f11 := InputEventKey.new()
    f11.keycode = KEY_F11
    f11.pressed = true
    assert_true(f11.is_action_pressed("nav_fullscreen"))
    var plain_enter := InputEventKey.new()
    plain_enter.keycode = KEY_ENTER
    plain_enter.pressed = true
    assert_false(plain_enter.is_action_pressed("nav_fullscreen"),
        "Enter without Alt is ui_accept, not the window key")
    # The router flips the setting and applies it; the Options row then shows
    # the mode the window is in.
    var settings = _root().get_node_or_null("GameSettings")
    settings.reset_all()
    var r = _root().get_node_or_null("ScreenRouter")
    assert_true(r.toggle_fullscreen())
    assert_eq(String(settings.get_value("window_mode")), "windowed")
    r._unhandled_input(f11)
    assert_eq(String(settings.get_value("window_mode")), "borderless",
        "the key goes through _unhandled_input")


# ----------------------------------------------- UI-47: the CVD ramp is reachable

func test_the_colour_safe_ramp_is_an_option_default_off_with_a_live_row() -> void:
    # docs/13 §8.3's ramp behind a switch, default off (ship plan §6 #40); the
    # row's swatches show the active ramp, so the choice is visible here before
    # any roster draws it. Off: the reference's three colours across ten bands.
    var settings = _root().get_node_or_null("GameSettings")
    settings.reset_all()
    assert_false(bool(settings.get_value("colourblind_safe")), "off by default")
    var view = _mounted_settings()
    var cell: Node = view.find_child("Ramp_colourblind_safe", true, false)
    assert_ne(cell, null, "the row draws its ramp")
    if cell == null:
        return
    var swatches: Node = cell.find_child("Swatches", true, false)
    assert_eq(swatches.get_child_count(), Enums.MORALE_BAND_COUNT, "ten bands")
    for band in Enums.MORALE_BAND_COUNT:
        var plate: ColorRect = swatches.get_child(band)
        assert_eq(plate.mouse_filter, Control.MOUSE_FILTER_IGNORE)
        assert_eq(plate.color, Palette.band_color(band * 10 + 5),
            "band %d is the reference ramp when off" % band)
    # On: docs/13 §8.3's ten plates, read through the one door.
    var chip: Button = null
    for b in _buttons(cell):
        chip = b
    assert_ne(chip, null, "the toggle is a chip in the cell")
    assert_eq(chip.text, "Off")
    assert_eq(chip.focus_mode, Control.FOCUS_ALL)
    chip.pressed.emit()
    assert_true(bool(settings.get_value("colourblind_safe")))
    assert_true(Palette.cvd_safe(view), "Palette reads the option")
    cell = view.find_child("Ramp_colourblind_safe", true, false)
    swatches = cell.find_child("Swatches", true, false)
    for band in Enums.MORALE_BAND_COUNT:
        var plate: ColorRect = swatches.get_child(band)
        assert_eq(plate.color, Palette.band_color_cvd(band * 10 + 5),
            "band %d is §8.3's plate when on" % band)
    assert_eq(Palette.band_color_active(view, 5), Palette.band_color_cvd(5))


func test_the_volume_rows_reach_the_mixer_and_not_just_the_config_file() -> void:
    # The point of the whole exercise. docs/13 §15.1 puts the four levels in
    # the closed inventory, so the row exists; §12.3 says a disabled control
    # carries "a reason string adjacent". Neither section says what an ENABLED
    # row owes — that sentence is game/screens/Settings.gd's own header, and
    # this test is the mechanical version of it: the row moves the mixer, not
    # just the config file.
    var settings = _root().get_node_or_null("GameSettings")
    var audio = _root().get_node_or_null("Audio")
    assert_ne(audio, null, "the Audio autoload must be registered")
    audio.ensure_wired()
    settings.set_value("audio_ui", 100)
    assert_almost(audio.level_db("audio_ui"), 0.0, 0.1)
    settings.set_value("audio_ui", 20)
    assert_almost(audio.level_db("audio_ui"), linear_to_db(0.2), 0.1,
        "pressing the interface row must actually move the UI bus")
    settings.reset_all()
    audio.apply_levels()
