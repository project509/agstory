extends "res://tests/TestCase.gd"
## The Load/Save screen (`game/screens/LoadSave.gd`), mounted for real.
##
## docs/14 §7.2's three slots had no surface at all: `SaveGame.slot_summaries()` returned
## a ready-made row per slot and the only reader was MainMenu's Continue, which used one
## field of it. These tests are the contract that the rows reach the player.
##
## They mount the scene through the router rather than poking the script, because the
## failure worth catching is "the screen builds blank" — which only happens when scene,
## script and autoload disagree. Everything asserted is `Label.text` or `Button.text`,
## which is the whole of what a screen test may read.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const DB = preload("res://sim/content/ContentDB.gd")

const LOAD_SAVE := "res://game/screens/LoadSave.tscn"
const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const SETTINGS := "res://game/screens/Settings.tscn"
const TOWN := "res://game/screens/Town.tscn"
const RESULTS := "res://game/screens/Results.tscn"
const A1 := "t1_adv_a1"

var _db = null
var _root: Node = null
var _host: Control = null
var _router = null
var _state = null
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
    _state.reset()
    _state.set_content(_db)
    _host = Control.new()
    _host.name = "LoadSaveTestHost"
    _root.add_child(_host)
    _router.register_host(_host)
    SaveGame.purge_all()

func after_each() -> void:
    SaveGame.purge_all()
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


## Under `--script` the project's autoloads may not be instantiated. Provide them rather
## than skipping — a skipped screen test is a screen with no test.
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

## The test contract: only `Label.text` and `Button.text`.
func _texts(n: Node) -> Array:
    var out: Array = []
    for node in _nodes(n):
        if node is Label:
            out.append((node as Label).text)
        elif node is Button:
            out.append((node as Button).text)
    return out

func _joined(n: Node) -> String:
    return "\n".join(PackedStringArray(_texts(n)))

func _buttons(n: Node) -> Array:
    var out: Array = []
    for node in _nodes(n):
        if node is Button:
            out.append(node)
    return out

func _button(fragment: String):
    for b in _buttons(_screen()):
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

func _must_press(fragment: String) -> void:
    assert_true(_press(fragment), "no enabled button matching '%s'; the screen shows:\n%s"
        % [fragment, _joined(_screen())])

func _guild(name: String = "Slotted"):
    _state.new_game(name, 4242)
    return _state

func _mount() -> void:
    assert_true(_router.goto(LOAD_SAVE), "the slots screen must mount")


# ---------------------------------------------------------------- the rows

func test_the_screen_exists_and_mounts() -> void:
    assert_true(ResourceLoader.exists(LOAD_SAVE), "missing scene %s" % LOAD_SAVE)
    _mount()
    assert_eq(_router.current_path(), LOAD_SAVE)
    assert_true(_screen() is Control)

func test_every_slot_is_a_row_and_the_full_one_names_its_guild() -> void:
    _guild("Slotted")
    assert_eq(SaveGame.save_slot(0, _state), "")
    _mount()
    var shown := _joined(_screen())
    assert_true(shown.contains("Guild Slots"), shown)
    assert_true(shown.contains("Slot 1 — Slotted"), shown)
    assert_true(shown.contains("Slot 2 — empty"), shown)
    assert_true(shown.contains("Slot 3 — empty"), shown)
    for n in [1, 2, 3]:
        assert_ne(_button("Load — Slot %d" % n), null, "no Load button for slot %d" % n)
        assert_ne(_button("Save to Slot %d" % n), null, "no Save button for slot %d" % n)
        assert_ne(_button("Delete Slot %d" % n), null, "no Delete button for slot %d" % n)

func test_an_empty_slot_disables_load_with_its_reason_rather_than_hiding_it() -> void:
    # docs/13 §7: a disabled control is never a mystery, and a missing button teaches the
    # player the feature does not exist.
    _guild()
    _mount()
    var load_two = _button("Load — Slot 2")
    assert_ne(load_two, null, "the button must be present")
    assert_true(load_two.disabled, "and disabled")
    assert_true(_joined(_screen()).contains("Slot 2 is empty."),
        "with the reason as text:\n%s" % _joined(_screen()))

func test_a_damaged_slot_is_listed_with_its_reason_and_cannot_be_loaded() -> void:
    # docs/14 §7.1's header-first read exists "so the load menu can show an incompatible
    # save instead of crashing on it". This is that menu.
    _guild()
    SaveGame.save_slot(0, _state)
    var f := FileAccess.open(SaveGame.slot_path(1), FileAccess.WRITE)
    f.store_string("this is not json {{{")
    f.close()

    _mount()
    var shown := _joined(_screen())
    assert_true(shown.contains("damaged"), shown)
    var load_two = _button("Load — Slot 2")
    assert_ne(load_two, null, "the row is still offered")
    assert_true(load_two.disabled, "but its Load is refused")

func test_a_save_from_a_newer_build_says_so_on_its_row() -> void:
    _guild("Tomorrow")
    SaveGame.save_slot(2, _state)
    var path := SaveGame.slot_path(2)
    var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
    doc["header"]["save_version"] = GameStateScript.SAVE_VERSION + 5
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(doc, "  "))
    f.close()

    _mount()
    assert_true(_joined(_screen()).contains("newer build"), _joined(_screen()))
    assert_true(_button("Load — Slot 3").disabled)


# ---------------------------------------------------------------- the presses

func test_loading_a_slot_restores_the_guild_and_lands_on_the_town() -> void:
    _guild("Recovered")
    _state.gold = 777
    assert_eq(SaveGame.save_slot(0, _state), "")
    _state.reset()
    _state.set_content(_db)
    assert_false(_state.active, "the test starts with nothing loaded")

    _mount()
    _must_press("Load — Slot 1")
    assert_eq(_router.current_path(), TOWN, "a good load opens the town")
    assert_eq(_state.guild_name, "Recovered")
    assert_eq(_state.gold, 777)

## One real attempt through the campaign's one door, the way RaidPrep departs:
## the chalked party, the folded loadout, a drawn seed, then `record_attempt`
## handed the loadout so `active_run` is the fight as it was run.
func _attempt(s):
    var enc = _db.encounter(A1)
    assert_ne(enc, null, "content has %s" % A1)
    var party: Array = s.roster.slice(0, mini(int(enc.party_size), s.roster.size()))
    var loadout: Dictionary = s.build_loadout(party)
    var result = s.run_attempt(party, enc, s.next_raid_seed(), loadout)
    s.record_attempt(A1, result, party, {"loadout": loadout})
    return result


func test_loading_a_guild_that_still_owes_a_report_lands_on_the_report() -> void:
    # SHIP-03 / Q-53, the route rather than the state: the attempt is committed
    # at Depart, so a quit between the account and the report used to lose the
    # only page that says what happened. `active_run` carries the fight as it
    # departed; Load replays it and opens the report, not the town.
    _guild("Interrupted")
    var lived = _attempt(_state)
    assert_true(_state.active_run_pending(), "the report is owed")
    assert_eq(SaveGame.save_slot(0, _state), "")
    _state.reset()
    _state.set_content(_db)
    assert_false(_state.active)

    _mount()
    _must_press("Load — Slot 1")
    assert_eq(_router.current_path(), RESULTS,
        "a guild that owes a report opens on it, not on the town")
    assert_ne(_state.last_result, null, "and the report has a fight to print")
    assert_eq(int(_state.last_result.outcome), int(lived.outcome), "the same outcome")
    assert_eq(int(_state.last_result.rounds), int(lived.rounds), "in the same rounds")
    assert_eq(int(_state.last_result.mistake_count), int(lived.mistake_count),
        "with the same mistakes — the seed came back whole")
    assert_eq(_state.guild_name, "Interrupted")


func test_loading_a_guild_with_nothing_owed_still_opens_the_town() -> void:
    # The other branch of the same door: a dismissed report is not a pending one,
    # and the ordinary load must not be re-routed by the new rule.
    _guild("Settled")
    _attempt(_state)
    _state.dismiss_active_run()
    assert_false(_state.active_run_pending())
    assert_eq(SaveGame.save_slot(0, _state), "")
    _state.reset()
    _state.set_content(_db)

    _mount()
    _must_press("Load — Slot 1")
    assert_eq(_router.current_path(), TOWN, "a settled guild opens the town")


func test_saving_over_a_full_slot_asks_before_it_writes() -> void:
    _guild("Careful")
    assert_eq(SaveGame.save_slot(0, _state), "")
    var before := int(SaveGame.read_header(SaveGame.slot_path(0))["sequence"])

    _mount()
    _must_press("Save to Slot 1")
    assert_eq(int(SaveGame.read_header(SaveGame.slot_path(0))["sequence"]), before,
        "the first press must not have written anything")
    var asked := _joined(_screen())
    assert_true(asked.contains("Yes — overwrite Slot 1"), asked)
    assert_true(asked.contains("Keep it"), asked)

    _must_press("Yes — overwrite Slot 1")
    assert_true(int(SaveGame.read_header(SaveGame.slot_path(0))["sequence"]) > before,
        "and the confirmed press does")

func test_backing_out_of_an_overwrite_leaves_the_slot_alone() -> void:
    _guild("Untouched")
    SaveGame.save_slot(0, _state)
    var before := int(SaveGame.read_header(SaveGame.slot_path(0))["sequence"])
    _mount()
    _must_press("Save to Slot 1")
    _must_press("Keep it")
    assert_eq(int(SaveGame.read_header(SaveGame.slot_path(0))["sequence"]), before)
    assert_ne(_button("Save to Slot 1"), null, "and the row went back to normal")

func test_saving_to_an_empty_slot_needs_no_confirm() -> void:
    _guild("Fresh")
    _mount()
    _must_press("Save to Slot 2")
    assert_eq(String(SaveGame.read_header(SaveGame.slot_path(1)).get("guild_name", "")),
        "Fresh", "an empty slot has nothing to lose, so it just writes")
    assert_true(_joined(_screen()).contains("Slot 2 — Fresh"),
        "and the row is rebuilt from disk:\n%s" % _joined(_screen()))

func test_saving_writes_the_manual_slot_and_never_the_rotation() -> void:
    # docs/14 §7.2's manual-vs-rotating split is the backstop against a bad migration.
    # `row["path"]` is the NEWEST file in the slot, which is usually an autosave — a Save
    # wired to it would spend a rotation entry.
    _guild("Manual")
    _state.autosave()
    var rotation_before: Array = []
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        rotation_before.append(int(SaveGame.read_header(SaveGame.autosave_path(0, i))
            .get("sequence", 0)))

    _mount()
    # The slot already holds an autosave, so the row reads as full and Save asks first.
    _must_press("Save to Slot 1")
    _must_press("Yes — overwrite Slot 1")
    var rotation_after: Array = []
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        rotation_after.append(int(SaveGame.read_header(SaveGame.autosave_path(0, i))
            .get("sequence", 0)))
    assert_eq(rotation_after, rotation_before, "the rotation must be untouched")
    assert_eq(String(SaveGame.read_header(SaveGame.slot_path(0)).get("guild_name", "")),
        "Manual", "and the manual file is the one that moved")

func test_deleting_a_slot_asks_first_and_then_takes_the_rotation_with_it() -> void:
    _guild("Doomed")
    SaveGame.save_slot(0, _state)
    _state.autosave()

    _mount()
    _must_press("Delete Slot 1")
    assert_true(_joined(_screen()).contains("Yes — delete Slot 1"), _joined(_screen()))
    assert_true(FileAccess.file_exists(SaveGame.slot_path(0)),
        "asking is not deleting")

    _must_press("Yes — delete Slot 1")
    assert_false(FileAccess.file_exists(SaveGame.slot_path(0)))
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        assert_false(FileAccess.file_exists(SaveGame.autosave_path(0, i)),
            "erase_slot takes the whole rotation, or the row stays full")
    assert_true(_joined(_screen()).contains("Slot 1 — empty"), _joined(_screen()))


# ---------------------------------------------------------------- no guild

func test_with_no_guild_the_chrome_degrades_honestly() -> void:
    # The screen is reachable from the title, where there is no campaign. 00 §2.5's chips
    # and the rail both say so instead of printing zeros or opening onto nothing.
    assert_false(_state.active)
    _mount()
    var shown := _joined(_screen())
    assert_true(shown.contains("No guild loaded."), shown)
    var save_one = _button("Save to Slot 1")
    assert_ne(save_one, null, "the button stays")
    assert_true(save_one.disabled, "and is refused with its reason")
    for label in ["Camp", "Tavern", "Roster", "Market"]:
        var rail = _button(label)
        assert_ne(rail, null, "the rail keeps %s" % label)
        assert_true(rail.disabled, "%s must not open onto nothing" % label)

func test_a_slot_is_still_loadable_from_the_title_screen_side() -> void:
    _guild("Titled")
    SaveGame.save_slot(1, _state)
    _state.reset()
    _state.set_content(_db)
    _mount()
    assert_false(_button("Load — Slot 2").disabled,
        "loading is the one thing this screen does without a guild")


# ---------------------------------------------------------------- the two doors

func test_the_title_screen_offers_a_way_into_the_slots() -> void:
    # docs/13 §5 S01 is "Title / Guild select"; Continue only ever opens the newest save,
    # so the other two slots need a door of their own.
    assert_false(_state.active, "no autosave is provoked by opening the menu")
    assert_true(_router.goto(MAIN_MENU))
    var shown := _joined(_screen())
    assert_true(shown.contains("Load Guild"), shown)
    var b = _button("Load Guild")
    assert_false(b.disabled, "the screen it points at exists, so it is live")

func test_the_options_screen_is_the_in_game_door() -> void:
    # docs/13 §5 gives the in-game half of saving no S-number and 00 §2.6's rail is a
    # closed list, so it hangs off Options. docs/13 §5 has no row for the screen yet;
    # audit `M3-SAVE-04` owns it.
    assert_true(_router.goto(SETTINGS))
    var shown := _joined(_screen())
    assert_true(shown.contains("Save / Load"), shown)
    assert_false(_button("Save / Load").disabled)
