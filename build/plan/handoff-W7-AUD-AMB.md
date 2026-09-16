# handoff-W7-AUD-AMB

Edits W7-AUD-AMB needs in files it does not own, or that must not land until the door does. Apply with `python tools/apply_handoff.py build/plan/handoff-W7-AUD-AMB.md` at the wave's close, after `handoff-W7-STAGE.md` (both touch `game/ui/SceneStage.gd`; this one anchors on `load()`'s two lines, which W7-STAGE does not edit). `game/ui/SceneStage.gd` is TABS; `tests/unit/test_audio_beds.gd` is SPACES.

## 1. game/ui/SceneStage.gd:397

THE DOOR (AUDIO-07 (3), BL-138). `load()` is the one function every screen's stage comes through (`Town`, `AdventureBoard`, `Tavern`, `Market`, `MainMenu`, `Completion`, `RaidPrep`, `RaidView`, `Results`), so the bed follows the scene and no screen learns about audio. `from_data()` is left alone on purpose: it is the tests' seam and `Guildhall.bare_stage()`'s, and a hall or an options page opened over a screen keeps the bed underneath. `Services.find(stage, "Audio")` resolves the autoload from a node that is not yet in a tree (it falls back to the main loop's root), and `play_bed` is headless-safe and refuses an unknown name with its own error; a tool running without the autoload gets null and no call. The same bed asked for twice (the camp family) is left running by `Audio` itself.

old:
```
static func load(name: String) -> Control:
	return from_data(name, _read(SCENES + name + ".json"))
```
new:
```
static func load(name: String) -> Control:
	var stage: Control = from_data(name, _read(SCENES + name + ".json"))
	# The ambience door (W7-AUD-AMB, Q-98 (ii), BL-138): the bed follows the
	# scene through this one call, and no screen learns about audio. Null-safe
	# for a tool that runs without the autoload; `play_bed` is headless-safe.
	var audio: Node = Services.find(stage, "Audio")
	if audio != null:
		audio.play_bed(name)
	return stage
```

## 2. tests/unit/test_audio_beds.gd:318

The door's own test, held back until §1 lands (in-wave the contract is proved by calling `play_bed` directly). Anchored on the marker comment the file carries for it.

old:
```
# -------------------------------------------------------------- the door (close)
# The door itself — `SceneStage.load(name)` calling `play_bed(name)` — lands
# at the wave's close by handoff-W7-AUD-AMB.md §1, and its test lands with it
# (§2 of the same file, anchored here). Until then the contract above is
# proved by calling `play_bed` directly.
```
new:
```
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
```

## 3. tests/unit/test_docs_links.gd:314

`test_every_register_citation_resolves_to_a_declared_entry`: the beds cite the soundscape question as `Q-98` (its (ii) clause is the Music-bus ruling and its (i) clause is why nothing melodic is here) and the arena question as `Q-96`; BL-98 (docs/09 §14.3 / docs/11 §6.3) and BL-96 (traits post-1.0) also exist, so by the guard's own rule the citing files join the list with the reason. W7-DOCS owns the file this wave. Inserted after the playtest row — the last row is the file's own self-entry, which W7-DOCS may be extending.

old:
```
    "res://tools/playtest.gd": [90],
```
new:
```
    "res://tools/playtest.gd": [90],
    # Wave 7 (W7-AUD-AMB): the soundscape question, number 98 as a Q — (ii)
    # ambience rides the Music bus through five generated beds, (i) music is
    # the lute at W10-BUFFER, so nothing melodic is in Audio.gd (BL-98 is the
    # docs/09 §14.3 / docs/11 §6.3 row). Number 96 as a Q in the beds test is
    # the arena routing again (raids -> the dungeon, hence its own bed).
    "res://game/core/Audio.gd": [98],
    "res://tests/unit/test_audio.gd": [98],
    "res://tests/unit/test_audio_beds.gd": [96, 98],
```
