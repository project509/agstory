extends "res://tests/TestCase.gd"
## Audio: the four buses, the eleven named hooks, and the promise that none of
## it crashes on a machine with no sound card.
##
## THE HEADLESS RULE. `--headless` runs Godot's dummy audio driver, so nothing
## in here may assert on an audible result — only on the mixer's state, the
## hook table, and the files on disk. The one thing these tests DO assert about
## playback is that calling it neither crashes nor blocks, because a blocking
## audio call in an autoload would take all 1100+ tests down with it.

const AudioScript = preload("res://game/core/Audio.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")
const GEN = "tools/audio/gen_sfx.py"

## docs/13 §12.4's table, transcribed here in the doc's own row order so this
## file fails if game/core/Audio.gd ever drifts from the doc rather than
## agreeing with itself.
const DOCUMENTED_HOOKS := [
    "ui.tab", "ui.row_select", "ui.chalk", "ui.chalk_bad", "ui.stamp",
    "ui.seal", "ui.coin", "ui.page_turn", "ui.ledger_close", "ui.blot",
    "ui.silence",
]

## docs/13 §15.1: "Audio bus levels (master / music / UI / voice-of-the-scribe)".
const DOCUMENTED_BUSES := ["Master", "Music", "UI", "Voice"]

const LAYOUT := "res://default_bus_layout.tres"
const SFX_DIR := "res://game/assets/audio/sfx"

var _saved: Dictionary = {}


func before_each() -> void:
    _saved = {}
    var s := _settings()
    if s != null:
        for key in GameSettings.AUDIO_BUSES:
            _saved[key] = s.get_value(key)
    var a := _audio()
    if a != null:
        # An autoload's `_ready` does not run under `--script` (the runner owns
        # the root and quits without a frame), so the game's boot path is the
        # one thing a test has to do by hand. Audio.ensure_wired() is the same
        # idempotent init `_ready` calls.
        a.ensure_wired()
        a.debug_tape = true
        a.tape = []


func after_each() -> void:
    var s := _settings()
    if s != null:
        for key in _saved:
            s.set_value(String(key), _saved[key])
    var a := _audio()
    if a != null:
        a.debug_tape = false
        a.tape = []
        a.bed_tape = []
        a.advance_duck(999.0)
        a.stop_bed()
        a.advance_bed(999.0)
        a.apply_levels()


func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _audio() -> Node:
    var r := _root()
    return r.get_node_or_null("Audio") if r != null else null


func _settings() -> Node:
    var r := _root()
    return r.get_node_or_null("GameSettings") if r != null else null


# ---------------------------------------------------------------- the buses

func test_the_audio_autoload_is_registered() -> void:
    # Before this landed the project had three autoloads and a Settings screen
    # with a volume row wired to nothing.
    assert_ne(_audio(), null, "the Audio autoload must be registered in project.godot")

func test_the_bus_layout_resource_exists_where_project_godot_points() -> void:
    var configured := String(ProjectSettings.get_setting(
        "audio/buses/default_bus_layout", ""))
    assert_eq(configured, LAYOUT, "project.godot must name the layout explicitly")
    assert_true(FileAccess.file_exists(LAYOUT), "the layout resource must exist")

func test_the_layout_names_exactly_the_four_documented_buses() -> void:
    # docs/13 §15.1's four, and no invented fifth: an "SFX" bus would put a
    # level in the mixer that no setting in the closed inventory can move.
    var text := FileAccess.get_file_as_string(LAYOUT)
    assert_false(text.is_empty(), "the layout resource must be readable")
    for i in DOCUMENTED_BUSES.size():
        assert_true(text.contains('bus/%d/name = &"%s"' % [i, DOCUMENTED_BUSES[i]]),
            "bus %d must be %s" % [i, DOCUMENTED_BUSES[i]])
    assert_false(text.contains('bus/4/name'), "there is no fifth bus in §15.1")

func test_the_four_buses_are_live_on_the_audio_server_after_boot() -> void:
    # The headless dummy driver still builds the mixer, which is why this is
    # assertable at all — see M6-AUD-01's risk note.
    for name_of in DOCUMENTED_BUSES:
        assert_true(AudioServer.get_bus_index(String(name_of)) >= 0,
            "bus '%s' is missing from the running mixer" % name_of)
    assert_eq(AudioServer.get_bus_index("Master"), 0, "Master is bus 0")

func test_every_bus_but_master_sends_to_master() -> void:
    # docs/13 §15.1 gives master authority over the other three, which is also
    # what makes ui.silence's "ducks ALL buses" a one-bus operation.
    for i in range(1, DOCUMENTED_BUSES.size()):
        var idx := AudioServer.get_bus_index(String(DOCUMENTED_BUSES[i]))
        assert_eq(String(AudioServer.get_bus_send(idx)), "Master",
            "%s must route through Master" % DOCUMENTED_BUSES[i])

func test_the_settings_keys_and_the_buses_are_the_same_list() -> void:
    assert_eq(AudioScript.BUS_FOR_KEY.size(), GameSettings.AUDIO_BUSES.size())
    for key in GameSettings.AUDIO_BUSES:
        assert_true(AudioScript.BUS_FOR_KEY.has(key),
            "'%s' is in the settings inventory with no bus behind it" % key)


# ------------------------------------------------- the four keys move the buses

func test_each_settings_key_moves_its_own_bus_and_only_its_own() -> void:
    var a := _audio()
    var s := _settings()
    assert_ne(s, null, "the GameSettings autoload must be registered")
    for key in GameSettings.AUDIO_BUSES:
        for other in GameSettings.AUDIO_BUSES:
            s.set_value(String(other), 100)
        a.apply_levels()
        s.set_value(String(key), 50)
        a.apply_levels()
        assert_almost(a.level_db(String(key)), linear_to_db(0.5), 0.1,
            "%s must move its own bus" % key)
        for other in GameSettings.AUDIO_BUSES:
            if String(other) == String(key):
                continue
            assert_almost(a.level_db(String(other)), 0.0, 0.1,
                "%s moved when %s changed" % [other, key])

func test_a_setting_change_reaches_the_mixer_without_anyone_calling_apply() -> void:
    # Audio subscribes to GameSettings.changed, so an Apply on the options
    # screen is audible immediately rather than after a restart.
    var a := _audio()
    var s := _settings()
    s.set_value("audio_music", 100)
    assert_almost(a.level_db("audio_music"), 0.0, 0.1)
    s.set_value("audio_music", 25)
    assert_almost(a.level_db("audio_music"), linear_to_db(0.25), 0.1,
        "the bus must follow the setting with no explicit apply_levels()")

func test_zero_mutes_the_bus_rather_than_trusting_minus_infinity() -> void:
    # linear_to_db(0.0) is -inf and Godot clamps it to -80 dB, which is audible
    # on a loud system. "0" in the options menu has to mean silent.
    var a := _audio()
    var s := _settings()
    var idx := AudioServer.get_bus_index("Music")
    s.set_value("audio_music", 0)
    a.apply_levels()
    assert_true(AudioServer.is_bus_mute(idx), "0 must mute")
    s.set_value("audio_music", 80)
    a.apply_levels()
    assert_false(AudioServer.is_bus_mute(idx), "and any level above 0 must unmute")

func test_the_documented_defaults_land_as_the_documented_levels() -> void:
    # docs/13 §15.1: 100 / 80 / 80 / 100.
    var a := _audio()
    var s := _settings()
    var want := {"audio_master": 100, "audio_music": 80, "audio_ui": 80,
        "audio_voice": 100}
    for key in want:
        s.set_value(String(key), int(want[key]))
    a.apply_levels()
    for key in want:
        assert_almost(a.level_db(String(key)),
            linear_to_db(float(want[key]) / 100.0), 0.1, String(key))

func test_a_key_outside_the_four_is_refused() -> void:
    # Same discipline as GameSettings.get_value: never a silent fallback. The
    # refusal is NAN and not 0.0, because 0.0 dB is unity — a real answer for a
    # real bus at 100% — and the first version of this test asserted 0.0, which
    # meant deleting the guard entirely still passed it (a dict miss yields
    # null, get_bus_index("") is -1, and the `else 0.0` returned unity). The
    # push_error below is expected.
    var a := _audio()
    var s := _settings()
    assert_true(is_nan(a.level_db("audio_nonsense")),
        "a key with no bus behind it has no level, and must not read as unity")
    s.set_value("audio_ui", 100)
    a.apply_levels()
    assert_false(is_nan(a.level_db("audio_ui")),
        "and a real key at unity is 0.0 dB, which is not a refusal")
    assert_almost(a.level_db("audio_ui"), 0.0, 0.1)


# ---------------------------------------------------------------- the hooks

func test_the_hook_table_is_exactly_the_documented_eleven() -> void:
    # docs/13 §12.4 is a closed list of names handed to doc 14 to bind.
    var a := _audio()
    for hook in DOCUMENTED_HOOKS:
        assert_true(AudioScript.HOOKS.has(String(hook)),
            "docs/13 §12.4 names '%s' and Audio does not bind it" % hook)
    assert_eq(AudioScript.HOOKS.size(), DOCUMENTED_HOOKS.size(),
        "Audio binds a hook docs/13 §12.4 does not name")
    assert_ne(a, null)

func test_an_unknown_hook_is_an_error_not_a_silent_no_op() -> void:
    # This push_error is expected: a typo'd hook must fail where it is written.
    var a := _audio()
    a.tape = []
    a.play("ui.definitely_not_a_hook")
    assert_eq(a.tape.size(), 0, "an unknown hook must play nothing")

func test_every_hook_with_a_sample_names_a_file_that_is_really_there() -> void:
    # The generator and the hook table repeat each other's filenames, so one
    # of them drifting is the likeliest way this subsystem breaks.
    for hook in AudioScript.HOOKS:
        var paths: Array = AudioScript.HOOKS[hook]["streams"]
        for path in paths:
            assert_true(ResourceLoader.exists(String(path)),
                "%s names a missing sample: %s" % [hook, path])

func test_every_hook_but_silence_has_at_least_one_sample() -> void:
    # An empty stream list is legal, but it means a hook is inaudible, and the
    # only hook that is SUPPOSED to be inaudible is ui.silence.
    var a := _audio()
    for hook in DOCUMENTED_HOOKS:
        var got: int = a.streams_for(String(hook)).size()
        if String(hook) == "ui.silence":
            assert_eq(got, 0, "ui.silence is a duck, not a sample")
        else:
            assert_true(got > 0, "%s loaded no stream" % hook)

func test_no_generated_sample_is_an_orphan() -> void:
    # A .wav in the repo that no hook plays is dead weight the art/audio pass
    # would keep re-rendering.
    var referenced := {}
    for hook in AudioScript.HOOKS:
        for path in AudioScript.HOOKS[hook]["streams"]:
            referenced[String(path).get_file()] = true
    var d := DirAccess.open(SFX_DIR)
    assert_ne(d, null, "the sfx directory must exist")
    d.list_dir_begin()
    var name := d.get_next()
    var seen := 0
    while name != "":
        if name.ends_with(".wav"):
            seen += 1
            assert_true(referenced.has(name), "%s is played by no hook" % name)
        name = d.get_next()
    d.list_dir_end()
    assert_eq(seen, referenced.size(), "every hook's sample must be on disk")

func test_the_stamp_is_the_signature_sound_the_doc_specifies() -> void:
    # docs/13 §12.4: "short, dry, and never fatiguing: ≤ 140ms, three
    # round-robin variants, ±2 semitone random pitch."
    var a := _audio()
    var spec: Dictionary = AudioScript.HOOKS["ui.stamp"]
    assert_eq(int(spec["streams"].size()), 3, "three round-robin variants")
    assert_almost(float(spec["pitch_jitter_semitones"]), 2.0, 0.001,
        "±2 semitones")
    for stream in a.streams_for("ui.stamp"):
        assert_true(stream.get_length() <= 0.140,
            "a stamp variant runs %.3fs; §12.4 caps it at 140ms"
                % stream.get_length())

func test_the_two_indulgent_hooks_fit_inside_their_own_motions() -> void:
    # docs/13 §12.2 gives the two indulgent moments a duration each: the
    # departure page turn is 700ms and the day advance 900ms. §12.4 syncs
    # `ui.page_turn` to "Start of the turn" and `ui.ledger_close` to "Start of
    # the close", so each sample has to END before its motion does — a sound
    # still playing over a settled page is the one thing these two can get
    # wrong. Those two numbers are the doc's; the sample lengths (380 / 430 ms)
    # are the generator's choice inside them.
    var a := _audio()
    var motion_seconds := {"ui.page_turn": 0.700, "ui.ledger_close": 0.900}
    for hook in motion_seconds:
        var streams: Array = a.streams_for(String(hook))
        assert_true(streams.size() > 0, "%s must have a sample" % hook)
        for stream in streams:
            assert_true(stream.get_length() <= float(motion_seconds[hook]),
                "%s runs %.3fs; §12.2 gives its motion %.3fs"
                    % [hook, stream.get_length(), motion_seconds[hook]])

func test_every_other_hook_stays_inside_the_stamps_140ms() -> void:
    # THE BOUND AND WHERE IT COMES FROM, because the first version of this test
    # got it wrong in a way worth writing down. docs/13 gives a sample length
    # to exactly ONE hook: §12.4's `ui.stamp` is "≤ 140ms". §12.2's "Everything
    # else is under 140ms" is NOT a second source — that table bounds motion
    # durations, which is why the 700ms page turn and the 900ms ledger close
    # are in it at all. So this bound is 140 ms, the doc's own number applied
    # wider than the doc applies it, and that widening is a HOUSE CHOICE
    # recorded in tools/audio/README.md.
    #
    # It is written as an equality with the ceiling and not as a per-file
    # allowance: the earlier version of this test asserted 0.160, a literal
    # that traced to nothing and existed so `ui_seal.wav` (155 ms) could pass
    # while the comment above it quoted 140. The seal came down to 138 ms
    # instead. A bound with an exception for the file that broke it is not a
    # bound.
    var a := _audio()
    var indulgent := ["ui.page_turn", "ui.ledger_close"]
    var checked := 0
    for hook in DOCUMENTED_HOOKS:
        if String(hook) in indulgent:
            continue
        for stream in a.streams_for(String(hook)):
            checked += 1
            assert_true(stream.get_length() <= 0.140,
                "%s runs %.3fs; §12.4's ceiling for a UI one-shot is 140ms"
                    % [hook, stream.get_length()])
    # 17 samples on disk minus the two indulgent ones: 1 tab + 2 row_select +
    # 3 chalk + 1 chalk_bad + 3 stamp + 1 seal + 2 coin + 2 blot.
    assert_eq(checked, 15, "fifteen samples sit under the ceiling")

func test_only_the_stamp_carries_a_pitch_jitter() -> void:
    # docs/13 §12.4 specifies jitter for ui.stamp and only for ui.stamp.
    # Giving the others one would be inventing a number.
    for hook in AudioScript.HOOKS:
        var j := float(AudioScript.HOOKS[hook]["pitch_jitter_semitones"])
        if String(hook) == "ui.stamp":
            continue
        assert_almost(j, 0.0, 0.001,
            "%s has an undocumented pitch jitter" % hook)

func test_every_hook_plays_on_a_bus_that_exists() -> void:
    for hook in AudioScript.HOOKS:
        var bus := String(AudioScript.HOOKS[hook]["bus"])
        assert_true(AudioServer.get_bus_index(bus) >= 0,
            "%s routes to a bus that is not in the layout: %s" % [hook, bus])

func test_ui_sound_lives_on_the_ui_bus() -> void:
    # docs/13 §12.4 is the UI's sound list; ui.silence is the exception because
    # ducking "all buses" is a Master operation.
    for hook in AudioScript.HOOKS:
        var want := "Master" if String(hook) == "ui.silence" else "UI"
        assert_eq(String(AudioScript.HOOKS[hook]["bus"]), want, String(hook))


# ------------------------------------------------------------ headless safety

func test_playing_every_hook_headless_neither_crashes_nor_blocks() -> void:
    # THE IMPORTANT ONE. A headless run has no output device. If any of these
    # calls threw or waited on a driver, the whole suite would go with it.
    var a := _audio()
    a.tape = []
    var t0 := Time.get_ticks_msec()
    for hook in DOCUMENTED_HOOKS:
        a.play(String(hook))
    var dt := Time.get_ticks_msec() - t0
    assert_eq(a.tape.size(), DOCUMENTED_HOOKS.size(),
        "every hook must record a play, sample or not")
    assert_true(dt < 1000, "eleven one-shots took %d ms — something blocked" % dt)

func test_playing_the_same_hook_many_times_reuses_the_pool() -> void:
    # ui.stamp "fires dozens of times per raid" (§12.4). The pool is why that
    # does not allocate dozens of nodes.
    var a := _audio()
    var before := a.get_child_count()
    for _i in 50:
        a.play("ui.stamp")
    assert_eq(a.get_child_count(), before,
        "play() must not instance a player per press")
    assert_eq(before,
        AudioScript.POOL_PER_BUS * AudioScript.BUSES.size() + AudioScript.BED_PLAYERS,
        "one ring of %d players per bus, plus the two bed players (W7-AUD-AMB)"
            % AudioScript.POOL_PER_BUS)

func test_a_full_lap_of_the_ring_touches_every_player_exactly_once() -> void:
    # THE TRUNCATION TEST, and the reason the count above is not enough.
    # `_take()` reassigns `player.stream`, and reassigning a player that is
    # still sounding is a HARD CUT: the 6 ms out-fade `_finish()` writes is at
    # the end of the buffer, not at a stop. So the cursor must walk the whole
    # ring before it comes back to a player, or a burst cuts its own tail.
    #
    # The burst is reachable: docs/13 §12.2 puts log-line arrival at 90 ms,
    # the mistake line fires TWO hooks (ui.stamp + ui.blot, §12.4's "with the
    # stamp"), and the longest non-indulgent sample is 138 ms — so up to two
    # lines can still be sounding, four players deep, when the third arrives.
    var a := _audio()
    var seen := {}
    for _i in AudioScript.POOL_PER_BUS:
        var p: AudioStreamPlayer = a._take("UI")
        assert_ne(p, null, "the UI ring must hand out a player")
        seen[p.get_instance_id()] = true
    assert_eq(seen.size(), AudioScript.POOL_PER_BUS,
        "a lap of the ring must not reuse a player that may still be sounding")
    # POOL_PER_BUS traces to no doc section — no doc states a pool size — but it
    # has to clear the burst above with room to spare, and this is that
    # arithmetic rather than a number nobody can check.
    var longest_ms := 138.0                     # ui.seal, the longest one-shot
    var line_arrival_ms := 90.0                 # §12.2, "Log line arrival"
    var hooks_per_line := 2                     # §12.4: the stamp and the blot
    var concurrent := int(ceil(longest_ms / line_arrival_ms)) * hooks_per_line
    assert_true(AudioScript.POOL_PER_BUS >= concurrent * 2,
        "the pool (%d) must cover §12.2's burst (%d players) with headroom"
            % [AudioScript.POOL_PER_BUS, concurrent])

func test_round_robin_walks_the_variants_rather_than_repeating_one() -> void:
    # "three round-robin variants" is a fatigue requirement, so the rotation
    # itself is the thing under test.
    var a := _audio()
    var got := {}
    for _i in 9:
        a.play("ui.stamp")
        for p in a.get_children():
            if p is AudioStreamPlayer and (p as AudioStreamPlayer).stream != null:
                got[(p as AudioStreamPlayer).stream.resource_path] = true
    assert_eq(got.size(), 3, "all three stamp variants must get used")


# ------------------------------------------------------------ §12.4 ui.silence

func test_silence_is_a_duck_and_not_a_sample() -> void:
    # docs/13 §12.4: "Ducks all buses to −60dB for 400ms."
    var spec: Dictionary = AudioScript.HOOKS["ui.silence"]
    assert_eq(int(spec["streams"].size()), 0)
    assert_almost(float(spec["duck_db"]), -60.0, 0.001)
    assert_almost(float(spec["duck_seconds"]), 0.4, 0.001)

func test_the_duck_lowers_master_and_then_gives_it_back() -> void:
    var a := _audio()
    var s := _settings()
    s.set_value("audio_master", 100)
    a.apply_levels()
    assert_false(a.is_ducked())
    a.play("ui.silence")
    assert_true(a.is_ducked(), "ui.silence must duck")
    assert_almost(a.level_db("audio_master"), -60.0, 0.1,
        "master must sit 60 dB down during the wipe")
    a.advance_duck(0.41)
    assert_false(a.is_ducked(), "and come back after 400ms")
    assert_almost(a.level_db("audio_master"), 0.0, 0.1,
        "restored to the player's own master level, not to unity by accident")

func test_the_duck_rides_on_top_of_the_players_master_setting() -> void:
    # A player at 50% master who triggers a wipe must end up at 50%, not 100%.
    var a := _audio()
    var s := _settings()
    s.set_value("audio_master", 50)
    a.apply_levels()
    var quiet := linear_to_db(0.5)
    a.duck(-24.0, 0.2)
    assert_almost(a.level_db("audio_master"), quiet - 24.0, 0.1)
    a.advance_duck(0.5)
    assert_almost(a.level_db("audio_master"), quiet, 0.1)

func test_a_zero_length_duck_is_a_restore_not_a_permanent_dip() -> void:
    var a := _audio()
    a.duck(-60.0, 0.4)
    a.duck(-60.0, 0.0)
    assert_false(a.is_ducked())


# ------------------------------------------------------- the trigger bindings

func test_the_router_owns_the_tab_sound_so_no_screen_has_to() -> void:
    # docs/13 §12.4: `ui.tab` is "Tab / screen change". Audio subscribes to
    # ScreenRouter.screen_changed itself, so a screen never learns about audio.
    var a := _audio()
    var r := _root().get_node_or_null("ScreenRouter")
    assert_ne(r, null, "the ScreenRouter autoload must be registered")
    assert_true(r.screen_changed.is_connected(Callable(a, "_on_screen_changed")),
        "Audio must bind ui.tab to the router, not to every screen")

func test_nothing_under_sim_reaches_for_audio() -> void:
    # BUILD_STATE invariant 2 and docs/14:123: the event-emitting layer emits
    # "no tween, sound, or particle". Every hook fires from game/.
    var offenders: Array = []
    _scan_for_audio("res://sim", offenders)
    assert_eq(offenders, [], "sim/ must not touch audio")

func _scan_for_audio(dir_path: String, out: Array) -> void:
    var d := DirAccess.open(dir_path)
    if d == null:
        return
    d.list_dir_begin()
    var name := d.get_next()
    while name != "":
        var full := dir_path.path_join(name)
        if d.current_is_dir():
            _scan_for_audio(full, out)
        elif name.ends_with(".gd"):
            var text := FileAccess.get_file_as_string(full)
            if text.contains("AudioServer") or text.contains("AudioStreamPlayer") \
                    or text.contains("\"Audio\""):
                out.append(full)
        name = d.get_next()
    d.list_dir_end()


# ------------------------------------------------------- ambience, not music

func test_play_bed_plays_ambience_and_never_a_melodic_bed() -> void:
    # THE TRIPWIRE, rewritten (AUDIO-07, Q-98, BL-138). Until wave 7
    # `play_bed` was a deliberate no-op because docs/02 §9.1's per-rank
    # Audio column — the lute, the drum, the bell, the leitmotif — is
    # authored melodic work. The ruling split it: the five AMBIENCE beds are
    # generated and ride the Music bus through `Audio.BEDS`; the lute is
    # W10-BUFFER's `BEDS_MUSIC` (Q-98 (i)) and the rest is post-1.0. So this
    # test now pins the boundary: a rank name is not a bed, every bed the
    # table names is an `amb_` loop, and the hook tape stays untouched by a
    # bed (a screen mount must never change a hook count another test reads).
    # The push_errors from the rank names are expected. The beds' own
    # behaviour is tests/unit/test_audio_beds.gd's.
    var a := _audio()
    a.tape = []
    a.bed_tape = []
    a.stop_bed()
    a.advance_bed(1.0)
    for rank in ["unknown", "known", "respected", "established", "renowned",
            "legendary", ""]:
        a.play_bed(String(rank))
    assert_eq(a.tape.size(), 0, "a bed is not a hook and must not tape as one")
    assert_eq(a.bed_tape.size(), 0, "a rank name is not a bed")
    assert_eq(String(a.bed_playing()), "", "nothing melodic plays")
    for scene in AudioScript.BEDS:
        assert_true(String(AudioScript.BEDS[scene]).begins_with("amb_"),
            "%s maps to %s, which is not an ambience bed" % [scene, AudioScript.BEDS[scene]])
    var music := AudioServer.get_bus_index("Music")
    assert_true(music >= 0, "the Music bus exists")
    # The pool's Music ring is untouched: the beds live on their own players.
    for p in a.get_children():
        if p is AudioStreamPlayer and String((p as AudioStreamPlayer).bus) == "Music" \
                and not String(p.name).begins_with("Bed_"):
            assert_eq((p as AudioStreamPlayer).stream, null,
                "the pooled Music players carry nothing; a bed is never pooled")


# ---------------------------------------------------------------- the generator

func test_the_generator_is_in_the_tree_and_documents_itself() -> void:
    # M6-AUD-03: the samples are generated, not sourced, and the model behind
    # each one is written down so a re-render is reproducible.
    assert_true(FileAccess.file_exists("res://" + GEN),
        "the sfx generator must ship with the samples it made")
    assert_true(FileAccess.file_exists("res://tools/audio/README.md"),
        "the per-hook synthesis model must be recorded")
    var gen := FileAccess.get_file_as_string("res://" + GEN)
    for hook in DOCUMENTED_HOOKS:
        assert_true(gen.contains('"%s"' % hook),
            "the generator does not account for %s" % hook)

func test_no_sample_is_stereo_or_off_rate() -> void:
    # 44.1 kHz mono, per M6-AUD-03. A stray stereo file would double every
    # one-shot's size for no audible gain on a UI click.
    var a := _audio()
    for hook in DOCUMENTED_HOOKS:
        for stream in a.streams_for(String(hook)):
            assert_eq(stream.mix_rate, 44100, "%s mix rate" % hook)
            assert_false(stream.stereo, "%s must be mono" % hook)

func test_no_sample_loops() -> void:
    # docs/13 §12.2: "Nothing in the UI loops, pulses, or breathes."
    var a := _audio()
    for hook in DOCUMENTED_HOOKS:
        for stream in a.streams_for(String(hook)):
            assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED,
                "%s must not loop" % hook)


func test_the_coin_follows_the_gold_signal_that_already_existed() -> void:
    # docs/13 §12.4: `ui.coin` fires when "Gold changes", "On the value write".
    #
    # The audit said to add a `gold_changed` signal to GameState. It was
    # already there (GameState.gd:68), so subscribing needed no edit over
    # there — but subscribing is NOT the whole binding, which is what the next
    # two tests are about.
    var a := _audio()
    var state := _root().get_node_or_null("GameState")
    assert_ne(state, null, "the GameState autoload must be registered")
    assert_true(state.gold_changed.is_connected(Callable(a, "_on_gold_changed")),
        "Audio must bind ui.coin to the value write, not to every gold screen")
    assert_true(state.roster_changed.is_connected(Callable(a, "_on_roster_changed")),
        "and to roster_changed, which keeps the coin's watermark current")
    var was: int = int(state.gold)
    a.tape = []
    # Priming the watermark and asserting the no-op case are the same step: a
    # write of the total the state already holds is not a gold CHANGE.
    state.gold_changed.emit(state.gold)
    assert_eq(a.tape.size(), 0, "a write that does not move the total is silent")
    state.add_gold(7)
    assert_eq(a.tape.size(), 1, "a reward rings once, on the value write")
    assert_eq(String(a.tape[0]["hook"]), "ui.coin")
    state.add_gold(0)
    assert_eq(a.tape.size(), 1,
        "add_gold(0) is a write with no change and must not ding")
    assert_true(state.spend_gold(7), "the guild can afford what it was just given")
    assert_eq(a.tape.size(), 2, "and a spend rings once")
    assert_eq(int(state.gold), was, "this test leaves the purse where it found it")

func test_a_campaign_arriving_does_not_ring_the_coin() -> void:
    # THE MISSING TEST. `GameState.gold_changed` has FOUR emit sites and only
    # two are a gold change: `add_gold` (:609) and `spend_gold` (:618).
    # `new_game` (:532) and the tail of `from_dict` (:2376) emit so the gold
    # labels redraw when a whole campaign appears — and docs/13 §12.4's trigger
    # is "Gold changes", which a restore is not. The old test asserted only
    # that the signal was connected and that one emit records one play, so it
    # passed either way and a save load rang a 135 ms coin chime.
    #
    # `Audio._coin_note` is the decision all four sites pass through, and it is
    # driven directly here: `new_game`/`from_dict` on the autoload would need a
    # content database to build a real roster from, and would leave the shared
    # campaign every other screen test mounts against in pieces.
    var a := _audio()
    # (total, guild_seed, day, roster-head object id)
    assert_false(a._coin_note(60, 4242, 1, 900001),
        "new_game announces a campaign; it is not a transaction")
    assert_true(a._coin_note(560, 4242, 1, 900001), "a reward inside it rings")
    assert_false(a._coin_note(560, 4242, 1, 900001), "a no-op write does not")
    # The quickload: same campaign, same day, different gold. `reset()` empties
    # the roster and `from_dict` rebuilds it, so the head is a new object even
    # when it is the same twelve people — which is the only fact that separates
    # this case from a spend.
    assert_false(a._coin_note(60, 4242, 1, 900002),
        "restoring a save must not ring, even mid-campaign")
    assert_false(a._coin_note(1200, 777, 9, 900003),
        "and loading a different campaign must not ring")
    assert_true(a._coin_note(1300, 777, 9, 900003), "then play resumes")
    assert_false(a._coin_note(1400, 777, 4, 900003),
        "day 4 arriving after day 9 is a load, whatever the roster says")

    # AUDIO-10, landed: the state now SAYS which emit this is, so the handler is
    # driven directly. `announcing` is true for the whole of `new_game()` and
    # `from_dict()` (GameState, W7-SAVE) and false everywhere else.
    var was_state = a._state
    var stand_in := _AnnouncingState.new()
    a._state = stand_in
    a.tape = []
    stand_in.announcing = true
    a._on_gold_changed(500)
    assert_eq(a.tape.size(), 0, "a campaign announcing itself does not ring")
    stand_in.announcing = false
    a._on_gold_changed(560)
    assert_eq(a.tape.size(), 1, "and the first real change after it does")
    a._state = was_state


## The two fields `_on_gold_changed` reads off the state, and the flag under test.
class _AnnouncingState extends RefCounted:
    var guild_seed: int = 777
    var day: int = 9
    var announcing: bool = false

func test_a_hire_or_a_departure_does_not_cost_the_next_chime() -> void:
    # The other half of the guard: the roster head changes legitimately when
    # someone joins or leaves, and if Audio only refreshed its watermark on
    # gold writes, the next real gold change would look like a campaign
    # arriving and go silent. `roster_changed` is subscribed for exactly this.
    var a := _audio()
    a._coin_note(100, 55, 3, 900010)
    assert_true(a._coin_note(140, 55, 3, 900010), "a reward mid-campaign rings")
    # Someone leaves: GameState emits roster_changed and Audio re-reads the
    # head, so the next gold write still looks like the same campaign.
    a._coin_head = 900011
    assert_true(a._coin_note(80, 55, 3, 900011),
        "a spend right after a departure must still ring")
    # And the refresh reads the roster rather than inventing a value.
    a._on_roster_changed()
    assert_eq(a._coin_head, a._roster_head(),
        "roster_changed must leave the watermark agreeing with the roster")


# ------------------------------------------------------- §12.4 relative levels

func test_the_blot_is_mixed_under_the_stamp_in_the_samples_themselves() -> void:
    # docs/13 §12.4: `ui.blot` plays "With the stamp, one layer under it".
    #
    # NOTHING WAS ASSERTING THIS. There is no mix trim doing it — `play()` sets
    # `volume_db` to 0.0 for both — so the relationship lives entirely in the
    # rendered samples (PARAMS peaks -26 vs -14 dBFS), and a re-render with the
    # blot as loud as the stamp passed every other test in this file. "One
    # layer under" is not a number, so this asserts only what the doc says:
    # strictly under, which is what equal levels would fail.
    var stamp := _peak_dbfs_of("ui.stamp")
    var blot := _peak_dbfs_of("ui.blot")
    assert_true(stamp > -80.0, "the stamp samples must be readable")
    assert_true(blot > -80.0, "the blot samples must be readable")
    assert_true(blot < stamp,
        "the blot peaks at %.1f dBFS and the stamp at %.1f — it must sit under"
            % [blot, stamp])

## The loudest peak across a hook's variants, in dBFS, read from the SOURCE
## .wav files rather than the loaded streams: the WAV importer compresses to
## QOA (`compress/mode=2` in every .import), so `AudioStreamWAV.data` is not
## PCM and cannot be measured. The files on disk are 16-bit mono PCM, written
## by tools/audio/gen_sfx.py.
func _peak_dbfs_of(hook: String) -> float:
    var worst := 0.0
    for path in AudioScript.HOOKS[hook]["streams"]:
        var b := FileAccess.get_file_as_bytes(String(path))
        if b.size() < 44:
            return -INF
        # Walk the RIFF chunks rather than assuming a 44-byte header.
        var at := 12
        while at + 8 <= b.size():
            var id := b.slice(at, at + 4).get_string_from_ascii()
            var size := int(b.decode_u32(at + 4))
            if id == "data":
                var i := at + 8
                var last: int = mini(i + size, b.size())
                while i + 1 < last:
                    var v := absf(float(b.decode_s16(i)) / 32768.0)
                    if v > worst:
                        worst = v
                    i += 2
                break
            at += 8 + size + (size & 1)
    return linear_to_db(worst) if worst > 0.0 else -INF


# ------------------------------------------------------------ the byte gate

func test_every_sample_has_its_import_record_beside_it() -> void:
    # AUDIO-05 (4): a `.wav` without a sibling `.wav.import` is invisible to
    # `ResourceLoader.exists()` on a fresh clone — the generator's README says
    # to run `--import` after a render, and this is what notices when someone
    # did not. The gate over the BYTES is `gen_sfx.py --check`, run by
    # `build_art.sh --check` (verify stage 2b); the record is the other half.
    var d := DirAccess.open(SFX_DIR)
    assert_ne(d, null, "the sfx directory must exist")
    d.list_dir_begin()
    var name := d.get_next()
    var seen := 0
    while name != "":
        if name.ends_with(".wav"):
            seen += 1
            assert_true(FileAccess.file_exists(SFX_DIR.path_join(name + ".import")),
                "%s has no .import record beside it (run --import)" % name)
        name = d.get_next()
    d.list_dir_end()
    assert_eq(seen, 17, "seventeen samples, each with its record")


func test_the_generator_carries_the_byte_check_the_build_runs() -> void:
    # M6-AUD-03's last clause: the instrument is complete and something calls
    # it. `gen_sfx.py --check` re-renders every sample into a temp dir and
    # byte-compares it with the tree (AGREE / DIFFERS / MISSING / ORPHAN);
    # `build_art.sh --check` runs it beside the three art generators, and
    # `--gen` renders it. Asserted as text, the way test_motion.gd reads the
    # motion lint — the run itself is verify stage 2b's.
    var gen := FileAccess.get_file_as_string("res://" + GEN)
    assert_true(gen.contains('"--check"'), "gen_sfx.py must offer --check")
    for word in ["AGREE", "DIFFERS", "MISSING", "ORPHAN"]:
        assert_true(gen.contains(word), "--check must report %s per file" % word)
    var build := FileAccess.get_file_as_string("res://tools/build_art.sh")
    assert_false(build.is_empty(), "tools/build_art.sh must be readable")
    assert_true(build.contains("tools/audio/gen_sfx.py --check"),
        "build_art.sh --check must run the sample gate")
    assert_true(build.contains("tools/audio/gen_sfx.py --out game/assets/audio/sfx"),
        "build_art.sh --gen must render the samples into the tree")
