extends "res://tests/TestCase.gd"
## The ambience beds (W7-AUD-AMB): five generated loops on the Music bus,
## keyed by scene, crossfading through `Audio.play_bed`, behind the one door
## in `SceneStage.load()` (Q-98 (ii), BL-138, AUDIO-07).
##
## THE HEADLESS RULE, as in test_audio.gd: no assertion on an audible result.
## Under `--script` the autoload's players are not inside a tree, so
## `AudioStreamPlayer.play()` is skipped by the autoload and `playing` is
## never true here; what a test CAN read is which stream each bed player
## holds and where its volume sits, through `Audio.bed_state()`, with the
## crossfade's clock driven by `advance_bed()` the way the duck's is by
## `advance_duck()` (the runner never draws a frame).

const AudioScript = preload("res://game/core/Audio.gd")
const GEN = "tools/audio/gen_amb.py"
const SCENES_DIR := "res://game/assets/scenes"
const AMB_DIR := "res://game/assets/audio/amb"

## BL-138's five, by name. The table in Audio.gd is what maps scenes to them;
## this list is what the generator renders, transcribed so the file fails if
## either side grows a bed the other does not know.
const DOCUMENTED_BEDS := ["amb_camp", "amb_tavern", "amb_market", "amb_cave", "amb_dungeon"]

## The loop lengths gen_amb.py's BEDS table states, in seconds. The contract
## says 20-30 s; the exact figures are the generator's and are read back off
## the imported stream so a re-render that changed one is noticed here.
const LOOP_BOUNDS := [20.0, 30.0]


func before_each() -> void:
    var a := _audio()
    if a != null:
        a.ensure_wired()
        a.debug_tape = true
        a.bed_tape = []
        a.stop_bed()
        a.advance_bed(999.0)


func after_each() -> void:
    var a := _audio()
    if a != null:
        a.stop_bed()
        a.advance_bed(999.0)
        a.debug_tape = false
        a.bed_tape = []


func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


func _audio() -> Node:
    var r := _root()
    return r.get_node_or_null("Audio") if r != null else null


func _scene_names() -> Array:
    var out: Array = []
    var d := DirAccess.open(SCENES_DIR)
    assert_ne(d, null, "the scenes directory must exist")
    d.list_dir_begin()
    var name := d.get_next()
    while name != "":
        if name.ends_with(".json"):
            out.append(name.get_basename())
        name = d.get_next()
    d.list_dir_end()
    out.sort()
    return out


func _bed_players(a: Node) -> Array:
    var out: Array = []
    for p in a.get_children():
        if p is AudioStreamPlayer and String(p.name).begins_with("Bed_"):
            out.append(p)
    return out


# ------------------------------------------------------------- the table


func test_every_scene_on_disk_has_a_bed_and_every_bed_file_exists() -> void:
    # The door passes the stage's own name and nothing else, so a scene JSON
    # with no row would be a stage that mounts in silence with an error in
    # the log — the state AUDIO-07 found six stages in.
    var scenes := _scene_names()
    assert_true(scenes.size() >= 6, "six scene files were in the tree at wave 7")
    for scene in scenes:
        assert_true(AudioScript.BEDS.has(String(scene)),
            "%s has no row in Audio.BEDS" % scene)
        var bed := String(AudioScript.BEDS[String(scene)])
        assert_true(bed in DOCUMENTED_BEDS, "%s -> %s is not one of BL-138's five" % [scene, bed])
        var path: String = AudioScript.bed_path(bed)
        assert_true(ResourceLoader.exists(path), "%s names a missing loop: %s" % [bed, path])
        assert_true(FileAccess.file_exists(path + ".import"),
            "%s has no .import record beside it (run --import)" % path)
    for scene in AudioScript.BEDS:
        assert_true(String(scene) in scenes,
            "Audio.BEDS names %s and no such scene is on disk" % scene)


func test_the_aerial_plays_the_camp_bed_by_design_and_the_dungeon_its_own() -> void:
    # BL-138: the main menu's aerial is the guild's own camp from above, so
    # `stage_town` hears the fire; Raid 1's dungeon (Q-96) gets its own bed,
    # and `amb_cave` — never the camp — is what it would shed to.
    assert_eq(String(AudioScript.BEDS["stage_town"]), "amb_camp")
    assert_eq(String(AudioScript.BEDS["stage_camp"]), "amb_camp")
    assert_eq(String(AudioScript.BEDS["stage_arena_dungeon"]), "amb_dungeon")
    assert_eq(String(AudioScript.BEDS["stage_arena_cave"]), "amb_cave")
    assert_ne(String(AudioScript.BEDS["stage_arena_dungeon"]),
        String(AudioScript.BEDS["stage_camp"]), "a campfire under the dungeon lies")


func test_the_dungeon_bed_is_not_the_camps_bytes() -> void:
    # BL-138's own acceptance line: the dungeon is a recombination of the
    # cave's layers plus one event — it must be its own render, not a copy.
    var camp := FileAccess.get_file_as_bytes(AudioScript.bed_path("amb_camp"))
    var dungeon := FileAccess.get_file_as_bytes(AudioScript.bed_path("amb_dungeon"))
    var cave := FileAccess.get_file_as_bytes(AudioScript.bed_path("amb_cave"))
    assert_true(camp.size() > 44 and dungeon.size() > 44 and cave.size() > 44)
    assert_ne(dungeon.size(), camp.size(), "different loop lengths (25 s vs 26 s)")
    # A length can agree by accident; the bytes cannot.
    assert_ne(dungeon.slice(44, 44 + 65536), camp.slice(44, 44 + 65536))
    assert_ne(dungeon.slice(44, 44 + 65536), cave.slice(44, 44 + 65536),
        "the dungeon shares the cave's air model, not its bytes")


func test_every_bed_is_a_mono_44k_forward_loop_between_20_and_30_seconds() -> void:
    # The `.import` says `edit/loop_mode=2`; the imported stream says
    # LOOP_FORWARD. Both halves are asserted, because a hand-written record
    # that Godot then re-imported with defaults keeps the text and loses the
    # loop.
    for bed in DOCUMENTED_BEDS:
        var path: String = AudioScript.bed_path(String(bed))
        var record := FileAccess.get_file_as_string(path + ".import")
        assert_true(record.contains("edit/loop_mode=2"),
            "%s's .import must say edit/loop_mode=2 (forward)" % bed)
        var stream = load(path)
        assert_true(stream is AudioStreamWAV, "%s must import as an AudioStreamWAV" % bed)
        assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s must loop" % bed)
        assert_eq(stream.mix_rate, 44100, "%s mix rate" % bed)
        assert_false(stream.stereo, "%s must be mono" % bed)
        assert_in_range(stream.get_length(), LOOP_BOUNDS[0], LOOP_BOUNDS[1],
            "%s runs %.1fs; the contract says 20-30 s" % [bed, stream.get_length()])


func test_no_bed_file_is_an_orphan() -> void:
    # A .wav under amb/ that no scene maps to is dead weight the byte gate
    # would keep re-rendering — the same rule test_audio.gd holds over sfx/.
    var referenced := {}
    for scene in AudioScript.BEDS:
        referenced[String(AudioScript.BEDS[scene]) + ".wav"] = true
    var d := DirAccess.open(AMB_DIR)
    assert_ne(d, null, "the amb directory must exist")
    d.list_dir_begin()
    var name := d.get_next()
    var seen := 0
    while name != "":
        if name.ends_with(".wav"):
            seen += 1
            assert_true(referenced.has(name), "%s is played by no scene" % name)
        name = d.get_next()
    d.list_dir_end()
    assert_eq(seen, DOCUMENTED_BEDS.size(), "five loops on disk, each mapped")


# ------------------------------------------------------------- the door


func test_the_beds_ride_the_music_bus_on_their_own_players() -> void:
    # Q-98 (ii): "Audio — music and ambience" — the Music slider is what
    # moves the beds. Two dedicated players, never the pool's ring: `_take()`
    # reassigns streams, and a bed must not be reassigned under a listener.
    var a := _audio()
    assert_ne(a, null, "the Audio autoload must be registered")
    var players := _bed_players(a)
    assert_eq(players.size(), AudioScript.BED_PLAYERS, "two bed players")
    for p in players:
        assert_eq(String((p as AudioStreamPlayer).bus), "Music", "%s must sit on Music" % p.name)
        assert_eq(int((p as AudioStreamPlayer).process_mode), int(Node.PROCESS_MODE_ALWAYS))


func test_play_bed_takes_a_scene_name_and_lands_its_bed() -> void:
    # The door's contract: `SceneStage.load(name)` hands over the SCENE name.
    var a := _audio()
    a.play_bed("stage_tavern")
    assert_eq(String(a.bed_playing()), "amb_tavern")
    var st: Dictionary = a.bed_state()
    assert_eq(String(st["active"]), AudioScript.bed_path("amb_tavern"))
    assert_true(bool(st["fading"]), "a bed arrives on a crossfade, not a cut")
    assert_eq(a.bed_tape.size(), 1)
    assert_eq(String(a.bed_tape[0]["scene"]), "stage_tavern")
    assert_eq(String(a.bed_tape[0]["bed"]), "amb_tavern")
    a.advance_bed(AudioScript.BED_FADE_SECONDS + 0.01)
    st = a.bed_state()
    assert_false(bool(st["fading"]), "and the fade ends")
    assert_almost(float(st["active_db"]), 0.0, 0.05, "the bed lands at unity")
    assert_eq(String(st["outgoing"]), "", "nothing was playing before it")


func test_play_bed_twice_with_different_names_leaves_one_playing_after_the_crossfade() -> void:
    # The acceptance line. Tavern to Market: for 600 ms both loops are up
    # (equal-power, so the room does not dip), then the tavern's player is
    # stopped and emptied and only the market remains.
    var a := _audio()
    a.play_bed("stage_tavern")
    a.advance_bed(1.0)
    a.play_bed("stage_market")
    var st: Dictionary = a.bed_state()
    assert_eq(String(a.bed_playing()), "amb_market")
    assert_eq(String(st["active"]), AudioScript.bed_path("amb_market"))
    assert_eq(String(st["outgoing"]), AudioScript.bed_path("amb_tavern"),
        "the tavern is still up while the market arrives")
    assert_true(bool(st["fading"]))
    # Halfway: both at -3 dB (sin and cos of 45 degrees), the equal-power point.
    a.advance_bed(AudioScript.BED_FADE_SECONDS * 0.5)
    st = a.bed_state()
    assert_almost(float(st["active_db"]), linear_to_db(sin(PI / 4.0)), 0.1)
    assert_almost(float(st["outgoing_db"]), linear_to_db(cos(PI / 4.0)), 0.1)
    a.advance_bed(AudioScript.BED_FADE_SECONDS)
    st = a.bed_state()
    assert_false(bool(st["fading"]))
    assert_eq(String(st["active"]), AudioScript.bed_path("amb_market"))
    assert_eq(String(st["outgoing"]), "", "the tavern's player is released")
    var held := 0
    for p in _bed_players(a):
        if (p as AudioStreamPlayer).stream != null:
            held += 1
    assert_eq(held, 1, "exactly one loop remains after the crossfade")


func test_the_same_bed_twice_does_not_restart_the_loop() -> void:
    # Town, the Board, the Guildhall and the Completion all stand on
    # `stage_camp`, and the main menu's aerial maps to the same bed: walking
    # between them must not restart the fire at every door.
    var a := _audio()
    a.play_bed("stage_town")
    a.advance_bed(1.0)
    var before: Dictionary = a.bed_state()
    a.play_bed("stage_camp")
    var after: Dictionary = a.bed_state()
    assert_eq(String(a.bed_playing()), "amb_camp")
    assert_false(bool(after["fading"]), "the same bed asked for again starts no fade")
    assert_eq(String(after["active"]), String(before["active"]))
    assert_eq(String(after["outgoing"]), "")
    assert_eq(a.bed_tape.size(), 2, "both requests are on the tape; one moved the mixer")


func test_a_third_request_mid_fade_settles_the_fade_first() -> void:
    # Fast navigation: Tavern -> Market -> cave inside 600 ms. The loser of
    # the first fade is stopped, the market lands, and the cave fades from
    # the market — never three loops up at once.
    var a := _audio()
    a.play_bed("stage_tavern")
    a.advance_bed(1.0)
    a.play_bed("stage_market")
    a.advance_bed(0.1)
    a.play_bed("stage_arena_cave")
    var st: Dictionary = a.bed_state()
    assert_eq(String(a.bed_playing()), "amb_cave")
    assert_eq(String(st["active"]), AudioScript.bed_path("amb_cave"))
    assert_eq(String(st["outgoing"]), AudioScript.bed_path("amb_market"),
        "the cave fades from the market, which won the first fade")
    a.advance_bed(1.0)
    var held := 0
    for p in _bed_players(a):
        if (p as AudioStreamPlayer).stream != null:
            held += 1
    assert_eq(held, 1)


func test_stop_bed_silences() -> void:
    var a := _audio()
    a.play_bed("stage_arena_dungeon")
    a.advance_bed(1.0)
    a.stop_bed()
    assert_eq(String(a.bed_playing()), "", "no bed is in play once stopped")
    var st: Dictionary = a.bed_state()
    assert_true(bool(st["fading"]), "stop is a fade-out, not a cut")
    assert_eq(String(st["outgoing"]), AudioScript.bed_path("amb_dungeon"))
    a.advance_bed(AudioScript.BED_FADE_SECONDS + 0.01)
    for p in _bed_players(a):
        assert_eq((p as AudioStreamPlayer).stream, null, "%s must be empty" % p.name)
    assert_false(bool(a.bed_state()["fading"]))
    # And stopping nothing is a no-op, not an error.
    a.stop_bed()
    assert_false(bool(a.bed_state()["fading"]))


func test_an_unknown_name_is_an_error_not_a_silent_no_op() -> void:
    # The same discipline as `play()`: a scene added without a row must fail
    # where it is written. The push_error is expected.
    var a := _audio()
    a.play_bed("stage_arena_cave")
    a.advance_bed(1.0)
    a.bed_tape = []
    a.play_bed("stage_definitely_not_a_scene")
    assert_eq(a.bed_tape.size(), 0, "an unknown name tapes nothing")
    assert_eq(String(a.bed_playing()), "amb_cave", "and changes nothing")
    a.play_bed("")
    assert_eq(String(a.bed_playing()), "amb_cave", "an empty name is a no-op")


func test_a_bed_id_is_accepted_directly() -> void:
    # The table's values are legal names too, so a tool can ask for a bed by
    # its own id without inventing a scene.
    var a := _audio()
    a.play_bed("amb_dungeon")
    assert_eq(String(a.bed_playing()), "amb_dungeon")
    assert_eq(String(a.bed_state()["active"]), AudioScript.bed_path("amb_dungeon"))


func test_playing_every_bed_headless_neither_crashes_nor_blocks() -> void:
    # The same promise test_audio.gd makes for the hooks: no output device,
    # no wait, no throw — a bed request must never be the reason a screen
    # will not mount.
    var a := _audio()
    var t0 := Time.get_ticks_msec()
    for scene in AudioScript.BEDS:
        a.play_bed(String(scene))
        a.advance_bed(1.0)
    var dt := Time.get_ticks_msec() - t0
    assert_true(dt < 2000, "six bed changes took %d ms — something blocked" % dt)
    assert_eq(String(a.bed_playing()), String(AudioScript.BEDS[AudioScript.BEDS.keys().back()]))


func test_a_bed_fade_does_not_end_the_ducks_clock_and_vice_versa() -> void:
    # Both run on the one `_process`; the duck's restore used to switch the
    # callback off, which would have frozen a crossfade mid-way.
    var a := _audio()
    a.play_bed("stage_camp")
    a.duck(-60.0, 0.4)
    a.advance_duck(0.5)
    assert_false(a.is_ducked())
    assert_true(bool(a.bed_state()["fading"]), "the fade outlives the duck")
    assert_true(a.is_processing(), "and the clock keeps running for it")
    a.advance_bed(1.0)
    assert_false(bool(a.bed_state()["fading"]))


# -------------------------------------------------------------- the door


func test_loading_a_stage_lands_its_bed_without_the_screen_knowing() -> void:
    # THE DOOR (AUDIO-07 (3), landed by handoff-W7-AUD-AMB.md §1 at the
    # wave-7 close): `SceneStage.load(name)` is the one call, so Town, the
    # Tavern, the Market and the fight all mount with a bed and none of them
    # names Audio. `from_data` stays silent — it is the tests' seam and the
    # hall's bare stage, and a page opened over a screen keeps the bed under.
    var a := _audio()
    var SceneStage = load("res://game/ui/SceneStage.gd")
    var stage: Control = SceneStage.load("stage_tavern")
    assert_ne(stage, null)
    assert_eq(String(a.bed_playing()), "amb_tavern", "the tavern's stage brings its bed")
    stage.free()
    a.advance_bed(1.0)
    stage = SceneStage.load("stage_arena_dungeon")
    assert_eq(String(a.bed_playing()), "amb_dungeon", "the fight's stage brings the dungeon")
    assert_eq(String(a.bed_state()["outgoing"]), AudioScript.bed_path("amb_tavern"),
        "crossfading from the tavern")
    stage.free()
    a.advance_bed(1.0)
    var quiet: Control = SceneStage.from_data("test_scene", {})
    assert_eq(String(a.bed_playing()), "amb_dungeon", "from_data is not the door")
    quiet.free()
    assert_eq(a.bed_tape.size(), 2, "two loads, two bed requests, and nothing else")
    for screen in ["Town.gd", "Tavern.gd", "Market.gd", "RaidView.gd"]:
        var text := FileAccess.get_file_as_string("res://game/screens/" + screen)
        assert_false(text.contains("play_bed"), "%s must not name the bed door" % screen)


# ---------------------------------------------------------------- the generator


func test_the_generator_is_in_the_tree_and_names_every_bed() -> void:
    assert_true(FileAccess.file_exists("res://" + GEN),
        "the bed generator must ship with the loops it made")
    var gen := FileAccess.get_file_as_string("res://" + GEN)
    for bed in DOCUMENTED_BEDS:
        assert_true(gen.contains('"%s"' % bed), "the generator does not render %s" % bed)
    for word in ["AGREE", "DIFFERS", "MISSING", "ORPHAN", "LOOP OK", "DISTINCT"]:
        assert_true(gen.contains(word), "--check must report %s" % word)
    assert_true(gen.contains('"--check"'), "gen_amb.py must offer --check")
    var readme := FileAccess.get_file_as_string("res://tools/audio/README.md")
    for bed in DOCUMENTED_BEDS:
        assert_true(readme.contains("`%s`" % bed), "README must document %s" % bed)


func test_the_build_runs_the_bed_gate_beside_the_sample_gate() -> void:
    # AUDIO-05's shape, extended: `build_art.sh --check` runs
    # `gen_amb.py --check` (stage 2b turns red on a stale or hand-edited
    # loop) and `--gen` renders the beds into the tree.
    var build := FileAccess.get_file_as_string("res://tools/build_art.sh")
    assert_false(build.is_empty(), "tools/build_art.sh must be readable")
    assert_true(build.contains("tools/audio/gen_amb.py --check"),
        "build_art.sh --check must run the bed gate")
    assert_true(build.contains("tools/audio/gen_amb.py --out game/assets/audio/amb"),
        "build_art.sh --gen must render the beds into the tree")
