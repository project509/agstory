extends "res://tests/TestCase.gd"
## The save system (docs/14 §7).
##
## docs/14 §7's opening line is the reason this file is long: "this game will change every
## week for months. An unversioned save format costs weeks of lost test progress and,
## worse, produces bug reports nobody can trust."
##
## Three assertions carry most of the weight.
##
## `test_an_interrupted_write_leaves_the_previous_save_intact` is §7.2's atomic-rename
## rule, and it is the one that protects a real player: a crash mid-write must cost the
## last few minutes, never the whole guild.
##
## `test_a_newer_save_is_refused_and_never_partially_loaded` is §7.3's "Never partially
## load", which is the difference between a clear message and a corrupted campaign.
##
## `test_the_suite_never_writes_where_a_player_keeps_their_guild` is the safety one, and
## it exists because the autosave triggers made the test suite a save-writer.

const SaveGame = preload("res://game/core/SaveGame.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")

const TOWN := "res://game/screens/Town.tscn"
const TAVERN := "res://game/screens/Tavern.tscn"
const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const RAID_VIEW := "res://game/screens/RaidView.tscn"

var _db = null
var _made: Array = []
var _mounted: Array = []

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []
    _mounted = []
    SaveGame.purge_all()

func after_each() -> void:
    SaveGame.purge_all()
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


func _state(guild: String = "Test Guild", gold: int = 500):
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game(guild, 4242)
    s.gold = gold
    return s


func _blank():
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    return s


## A real router where the autoloads live, so a campaign built afterwards subscribes to
## it the way it does in the game — `GameState` finds it by name, never by the global
## identifier (BUILD_STATE invariant 7).
##
## The transitions below are EMITTED rather than navigated. What is under test is
## GameState's subscription and the rules it applies, not whether a screen scene builds;
## tests/unit/test_screens.gd owns that, and mounting Town here would make a save test
## fail whenever a screen's layout changed.
func _router():
    var loop := Engine.get_main_loop()
    if not (loop is SceneTree):
        return null
    var root: Node = (loop as SceneTree).root
    var existing := root.get_node_or_null("ScreenRouter")
    if existing != null:
        return existing
    var r = Router.new()
    r.name = "ScreenRouter"
    root.add_child(r)
    _mounted.append(r)
    return r


## The `sequence` in each rotation entry of slot 0, 0 where there is no file. Which
## entries MOVED is the whole question for the transition autosave.
func _sequences() -> Array:
    var out: Array = []
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        out.append(int(SaveGame.read_header(SaveGame.autosave_path(0, i))
            .get("sequence", 0)))
    return out


# =============================================== the safety rail

func test_the_suite_never_writes_where_a_player_keeps_their_guild() -> void:
    # The autosave triggers made this suite a save-writer. `tests/run_tests.gd` points the
    # directory somewhere disposable before any test runs, because `./tools/verify.sh`
    # overwriting a dev's own guild would be an unforgivable way to lose a bug report.
    assert_ne(SaveGame.SAVE_DIR, "user://saves",
        "the suite must not be pointed at the real save directory")
    assert_true(SaveGame.SAVE_DIR.contains("test"),
        "and the override must be obvious: %s" % SaveGame.SAVE_DIR)


# =============================================== docs/14 §7.2's format

func test_a_save_is_readable_json_with_a_header_a_human_can_read() -> void:
    # docs/14 §7.2 chose plain pretty JSON on purpose: "Debuggability beats obscurity in a
    # single-player premium game with no leaderboards. A tester can attach a save to a bug
    # report and an engineer can read it."
    var s = _state("Readable Guild")
    assert_eq(SaveGame.save_slot(0, s), "")

    var text := FileAccess.get_file_as_string(SaveGame.slot_path(0))
    assert_true(text.contains("\n"), "pretty-printed, not one line")
    assert_true(text.contains("Readable Guild"))
    var parsed = JSON.parse_string(text)
    assert_eq(typeof(parsed), TYPE_DICTIONARY)
    assert_true((parsed as Dictionary).has("header"))
    assert_true((parsed as Dictionary).has("body"))

func test_the_header_carries_every_documented_field() -> void:
    # docs/14 §7.1's header block, field by field.
    var s = _state("Header Guild")
    s.played_seconds = 3700.0
    SaveGame.save_slot(0, s)
    var header := SaveGame.read_header(SaveGame.slot_path(0))
    for key in SaveGame.HEADER_KEYS:
        assert_true(header.has(key), "the header must carry %s" % key)
    assert_eq(int(header["save_version"]), GameStateScript.SAVE_VERSION)
    assert_eq(String(header["guild_name"]), "Header Guild")
    assert_eq(int(header["played_seconds"]), 3700)
    assert_true(String(header["engine_version"]).length() > 0)

func test_a_missing_or_damaged_save_reads_as_nothing_rather_than_crashing() -> void:
    # docs/14 §7.1's whole reason for a header: "so the load menu can show an incompatible
    # save instead of crashing on it."
    assert_eq(SaveGame.read_header(SaveGame.slot_path(2)), {})

    var f := FileAccess.open(SaveGame.slot_path(1), FileAccess.WRITE)
    f.store_string("this is not json {{{")
    f.close()
    assert_eq(SaveGame.read_header(SaveGame.slot_path(1)), {})
    assert_true(SaveGame.incompatibility(SaveGame.slot_path(1)).contains("damaged"))

func test_an_interrupted_write_leaves_the_previous_save_intact() -> void:
    # docs/14 §7.2: "Temp file + fsync + atomic rename over the target. An interrupted
    # write must never destroy the previous save."
    #
    # Simulated by leaving a half-written temp file next to a good save: the good one must
    # still load, because nothing is ever written over it in place.
    var first = _state("First Guild", 999)
    assert_eq(SaveGame.save_slot(0, first), "")

    var tmp := FileAccess.open(SaveGame.slot_path(0) + ".tmp", FileAccess.WRITE)
    tmp.store_string('{"header": {"save_ver')
    tmp.close()

    var loaded = _blank()
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), loaded), [])
    assert_eq(loaded.guild_name, "First Guild")
    assert_eq(loaded.gold, 999, "the previous save is untouched")


# =============================================== docs/14 §7.3's versioning

func test_a_newer_save_is_refused_and_never_partially_loaded() -> void:
    # docs/14 §7.3: "Newer `save_version`: refuse with a clear message. Never partially
    # load." The refusal has to happen before anything is built, or "partially" is exactly
    # what happens.
    var s = _state("From The Future")
    SaveGame.save_slot(0, s)

    var path := SaveGame.slot_path(0)
    var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
    doc["header"]["save_version"] = GameStateScript.SAVE_VERSION + 5
    doc["body"]["save_version"] = GameStateScript.SAVE_VERSION + 5
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(doc, "  "))
    f.close()

    var refusal := SaveGame.incompatibility(path)
    assert_true(refusal.contains("newer build"), refusal)

    var target = _blank()
    var problems: Array = SaveGame.load_into(path, target)
    assert_eq(problems.size(), 1, "one reason, and nothing else attempted")
    assert_false(target.active, "and no campaign was built")
    assert_eq(target.guild_name, "", "not even the name leaked through")

func test_a_save_older_than_the_migration_chain_is_refused_by_name() -> void:
    # docs/14 §7.3 asks for migrations "from day one". They did not exist before v10, so
    # anything below that is refused with the number rather than guessed at — the doc's own
    # rule is that a migration "may drop a field, never guess a value".
    var s = _state("Ancient Guild")
    SaveGame.save_slot(0, s)
    var path := SaveGame.slot_path(0)
    var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
    doc["header"]["save_version"] = 3
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(doc, "  "))
    f.close()

    var refusal := SaveGame.incompatibility(path)
    assert_true(refusal.contains("predates"), refusal)
    assert_true(refusal.contains("%d" % SaveGame.OLDEST_MIGRATABLE),
        "and it names the oldest readable version: %s" % refusal)

func test_the_migration_chain_has_a_step_for_every_version_it_can_read() -> void:
    # docs/14 §7.3's first non-negotiable: "Migrations ship from day one." For three
    # waves the chain shipped EMPTY while SAVE_VERSION moved 10 -> 11 -> 12, so every
    # step it could have walked was a hole it walked past instead. This is the assertion
    # that the holes are gone, and it is the one that fails on the next bare bump.
    assert_eq(SaveGame.chain_gaps(SaveGame.OLDEST_MIGRATABLE), [],
        "every version from %d up must have a registered step; register one in "
        % SaveGame.OLDEST_MIGRATABLE
        + "SaveGame.MIGRATIONS in the same commit as the SAVE_VERSION bump")
    for v in range(SaveGame.OLDEST_MIGRATABLE, GameStateScript.SAVE_VERSION):
        assert_true(SaveGame.MIGRATIONS.has(v), "no step registered for version %d" % v)

func test_migrating_stamps_the_body_forward_without_touching_the_original() -> void:
    # `migrate()` is handed the parsed save in the loader and a literal in tests. Editing
    # either in place would make a second call see a body that had already moved.
    var body := {"save_version": SaveGame.OLDEST_MIGRATABLE, "gold": 7}
    var moved = SaveGame.migrate(body, SaveGame.OLDEST_MIGRATABLE)
    assert_eq(typeof(moved), TYPE_DICTIONARY)
    assert_eq(int(moved["save_version"]), GameStateScript.SAVE_VERSION,
        "the walked body says which version it now is")
    assert_eq(int(moved["gold"]), 7, "and every step is additive-only, so nothing moved")
    assert_eq(int(body["save_version"]), SaveGame.OLDEST_MIGRATABLE,
        "the caller's dictionary was not edited under it")

    var same = SaveGame.migrate(body, GameStateScript.SAVE_VERSION)
    assert_eq(int(same["save_version"]), SaveGame.OLDEST_MIGRATABLE,
        "at the current version there is nothing to do, not even a copy")

func test_a_hole_in_the_chain_is_named_rather_than_passed_over() -> void:
    # The risk the empty chain hid: `migrate()` returns the body UNCHANGED when a version
    # has no step, which is honest for an ADDED field and silently wrong for a renamed or
    # reshaped one. The pass-through stays — refusing an otherwise-good save would cost a
    # guild — but the hole is now a sentence in the problems array.
    var s = _state("Holey Guild")
    SaveGame.save_slot(0, s)
    var path := SaveGame.slot_path(0)
    var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
    doc["header"]["save_version"] = SaveGame.OLDEST_MIGRATABLE
    doc["body"]["save_version"] = SaveGame.OLDEST_MIGRATABLE
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(doc, "  "))
    f.close()

    var registry: Dictionary = SaveGame.MIGRATIONS
    var removed = registry[SaveGame.OLDEST_MIGRATABLE]
    registry.erase(SaveGame.OLDEST_MIGRATABLE)
    var problems: Array = SaveGame.load_into(path, _blank())
    registry[SaveGame.OLDEST_MIGRATABLE] = removed

    var named := false
    for p in problems:
        if String(p).contains("No migration step is registered for version %d"
                % SaveGame.OLDEST_MIGRATABLE):
            named = true
    assert_true(named, "the hole must be reported: %s" % str(problems))
    assert_eq(SaveGame.chain_gaps(SaveGame.OLDEST_MIGRATABLE), [],
        "and the registry was put back")

func test_a_migrated_save_is_backed_up_before_it_is_touched() -> void:
    # docs/14 §7.3: "Older `save_version`: migrate on load. Write a `.bak` of the
    # pre-migration file FIRST." The migration is the step most likely to be wrong.
    var s = _state("Backup Guild")
    SaveGame.save_slot(0, s)
    var path := SaveGame.slot_path(0)
    var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
    doc["header"]["save_version"] = SaveGame.OLDEST_MIGRATABLE
    doc["body"]["save_version"] = SaveGame.OLDEST_MIGRATABLE
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(doc, "  "))
    f.close()

    # This used to take an early return, because OLDEST_MIGRATABLE and SAVE_VERSION were
    # both 10 and there was nothing to migrate. Two bumps later they differ, so the
    # branch is gone and the rule is actually exercised.
    assert_true(SaveGame.OLDEST_MIGRATABLE < GameStateScript.SAVE_VERSION,
        "there must be something to migrate for this test to mean anything")
    var target = _blank()
    SaveGame.load_into(path, target)
    assert_true(FileAccess.file_exists(path + ".bak"),
        "the pre-migration file must survive")
    var backed = JSON.parse_string(FileAccess.get_file_as_string(path + ".bak"))
    assert_eq(int(backed["header"]["save_version"]), SaveGame.OLDEST_MIGRATABLE,
        "and the backup is the PRE-migration file, not the migrated one")


# =============================================== round-trip fidelity

func test_a_whole_campaign_survives_the_round_trip() -> void:
    # Everything a campaign accumulates, through the file and back.
    var s = _state("Round Trip", 4242)
    s.reputation_rank = Enums.ReputationRank.RESPECTED
    s.reputation_points = 500
    s.facility_tier = 2
    s.tavern_tier = 3
    s.market_tier = 2
    s.recruit_pity = 9
    s.legendary_classes_found = [Enums.CharClass.SHAMAN]
    s.cleared = {"t1_raid_e1": 2}
    s.attempts = {"t1_raid_e1": 5}
    s.stalled = true
    s.tier_bonus_awarded = [1]
    assert_eq(s.buy_consumable("minor_healing_potion", 1, 3), "")
    assert_eq(s.buy_furnishing("straw_cot", s.roster[0].id), "")

    s.played_seconds = 600.0
    assert_eq(SaveGame.save_slot(1, s), "")
    var t = _blank()
    var problems: Array = SaveGame.load_into(SaveGame.slot_path(1), t)
    assert_eq(problems, [], "clean load: %s" % str(problems))

    assert_eq(t.guild_name, "Round Trip")
    assert_eq(t.gold, s.gold)
    assert_eq(t.reputation_rank, Enums.ReputationRank.RESPECTED)
    assert_eq(t.reputation_points, 500)
    assert_eq(t.facility_tier, 2)
    assert_eq(t.tavern_tier, 3)
    assert_eq(t.market_tier, 2)
    assert_eq(t.recruit_pity, 9)
    assert_eq(t.legendary_classes_found, [Enums.CharClass.SHAMAN])
    assert_eq(t.roster.size(), s.roster.size())
    assert_eq(t.consumable_count("minor_healing_potion", 1), 3)
    assert_eq(t.placed_for(s.roster[0].id), ["straw_cot"])
    assert_eq(t.played_seconds, 600.0)
    assert_true(t.active, "and the campaign is live")

func test_the_roster_comes_back_raider_for_raider() -> void:
    var s = _state("Roster Trip")
    var names: Array = []
    var moods: Array = []
    for r in s.roster:
        names.append(r.display_name)
        moods.append(r.morale)
    SaveGame.save_slot(0, s)

    var t = _blank()
    SaveGame.load_into(SaveGame.slot_path(0), t)
    for i in t.roster.size():
        assert_eq(t.roster[i].display_name, String(names[i]))
        assert_eq(t.roster[i].morale, int(moods[i]))


# =============================================== docs/14 §7.4's autosaves

func test_a_resolved_encounter_autosaves() -> void:
    # docs/14 §7.4: "Encounter resolved (clear, wipe, or retreat), after deltas apply —
    # the moment most worth not losing."
    var s = _state("Autosave Guild")
    s.record_attempt("t1_adv_a1", _Lost.new(), s.roster.slice(0, 6))
    var found := false
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        if not SaveGame.read_header(SaveGame.autosave_path(0, i)).is_empty():
            found = true
    assert_true(found, "the attempt must have left a save behind")

func test_the_autosave_rotation_does_not_overwrite_itself() -> void:
    # docs/14 §7.2: "The rotation is the real backstop against a bad migration."
    var s = _state("Rotation Guild")
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        assert_eq(s.autosave(), "")
    var written := 0
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        if not SaveGame.read_header(SaveGame.autosave_path(0, i)).is_empty():
            written += 1
    assert_eq(written, SaveGame.AUTOSAVES_PER_SLOT,
        "each rotation slot must hold its own copy")

func test_an_inactive_campaign_does_not_autosave_over_a_good_one() -> void:
    var s = _state("Real Guild")
    assert_eq(s.autosave(), "")
    var blank = _blank()
    assert_eq(blank.autosave(), "", "and it says nothing went wrong")
    assert_false(SaveGame.read_header(SaveGame.autosave_path(0, 0)).is_empty(),
        "the real guild's autosave is still there")

class _Lost extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    func cleared() -> bool: return false


# ------------------------------------- docs/14 §7.4 row 1: town screen transitions

func test_a_town_transition_autosaves() -> void:
    # docs/14 §7.4's first row: "Any town screen transition — rotating. Doc 00 §6.2 asks
    # for it." It had no subscriber at all: the router emitted `screen_changed` and
    # nothing anywhere was listening.
    var router = _router()
    if router == null:
        return
    var s = _state("Transition Guild")
    router.emit_signal("screen_changed", TOWN)
    var found := false
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        if not SaveGame.read_header(SaveGame.autosave_path(0, i)).is_empty():
            found = true
    assert_true(found, "walking into town must leave a save behind")

func test_a_run_of_town_transitions_cannot_evict_the_encounter_autosave() -> void:
    # The hazard wiring row 1 creates. The rotation is only three deep (docs/14 §7.2), so
    # a fresh entry per transition means three trips to the Tavern and back destroy every
    # autosave in the slot — starting with the one §7.4 itself calls "the moment most
    # worth not losing". A RUN of transitions therefore coalesces onto ONE entry: the
    # state on disk stays current, but the rotation stays three DIFFERENT moments, which
    # is the only property that makes it a backstop. See build/plan/q-state-truth.md.
    var router = _router()
    if router == null:
        return
    var s = _state("Pacing Guild", 777)
    s.record_attempt("t1_adv_a1", _Lost.new(), s.roster.slice(0, 6))
    var before: Array = _sequences()
    s.gold = 111

    for i in 8:
        router.emit_signal("screen_changed", TOWN)
        router.emit_signal("screen_changed", TAVERN)

    var moved := 0
    var after: Array = _sequences()
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        if int(after[i]) != int(before[i]):
            moved += 1
    assert_eq(moved, 1,
        "sixteen town transitions may spend ONE rotation entry, not sixteen")

    var golds: Array = []
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        var t = _blank()
        if SaveGame.load_into(SaveGame.autosave_path(0, i), t).is_empty():
            golds.append(t.gold)
    assert_true(golds.has(777),
        "the resolved-encounter copy must survive the wandering: %s" % str(golds))
    assert_true(golds.has(111), "and the newest copy is where the player actually is")

func test_the_menu_and_the_raid_view_do_not_spend_a_rotation_entry() -> void:
    # RaidView is excluded because a write mid-attempt spends a rotation entry on a state
    # the player has not finished — and docs/14 §7.2 calls that rotation "the real
    # backstop against a bad migration". The menu is excluded because docs/14 §7.4 gives
    # quitting to it the MANUAL slot instead.
    var router = _router()
    if router == null:
        return
    var s = _state("Excluded Guild", 250)
    var before: Array = _sequences()
    router.emit_signal("screen_changed", RAID_VIEW)
    assert_eq(_sequences(), before, "no rotation entry may move mid-attempt")
    router.emit_signal("screen_changed", MAIN_MENU)
    assert_eq(_sequences(), before,
        "and quitting to the menu is not a rotating autosave")

func test_a_transition_with_no_campaign_writes_nothing() -> void:
    # Boot navigates before a guild exists. A write here would put an empty guild in a
    # slot and offer it behind Continue.
    var router = _router()
    if router == null:
        return
    var blank = _blank()
    router.emit_signal("screen_changed", TOWN)
    assert_eq(_sequences(), [0, 0, 0])
    assert_eq(SaveGame.read_header(SaveGame.slot_path(0)), {})


# --------------------------------- docs/14 §7.4 last row: quit to menu

func test_quitting_to_the_menu_writes_the_manual_slot() -> void:
    # docs/14 §7.4's last row is "Quit to menu / window close — manual-equivalent", and
    # only window close was wired. Town's own Back button and Settings' were bare
    # `goto(MAIN_MENU)`, so everything since the last autosave trigger was dropped and
    # the player found it gone behind Continue.
    #
    # It is answered here rather than in the two screens because EVERY route to the title
    # screen is a quit to the menu, including the ones that do not exist yet.
    var router = _router()
    if router == null:
        return
    var s = _state("Leaving Guild", 300)
    s.gold = 4321
    assert_eq(SaveGame.read_header(SaveGame.slot_path(0)), {}, "nothing manual yet")

    router.emit_signal("screen_changed", MAIN_MENU)
    assert_false(SaveGame.read_header(SaveGame.slot_path(0)).is_empty(),
        "leaving to the menu must write the manual slot")
    var t = _blank()
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), t), [])
    assert_eq(t.gold, 4321, "and it is the state the player was actually in")
    assert_true(s.active,
        "the campaign is deliberately left live in memory — build/plan/q-state-truth.md")


# --------------------------------- docs/14 §7.1's `played_seconds`

func test_played_seconds_moves_with_screen_transitions() -> void:
    # The field's own contract at game/core/GameState.gd says the router counts it. It
    # did not: `played_seconds` was written into every header and incremented by nothing,
    # so every Load/Save row read "just started" at any age.
    var router = _router()
    if router == null:
        return
    var s = _state("Clock Guild")
    assert_eq(s.played_seconds, 0.0)

    # The clock is wall time, so the only honest way to move it in a test is to move the
    # stamp it is measured against.
    s._last_transition_msec -= 5000
    router.emit_signal("screen_changed", TOWN)
    assert_true(s.played_seconds >= 5.0,
        "five seconds of thinking is five seconds played, got %f" % s.played_seconds)

    var counted: float = s.played_seconds
    s._last_transition_msec -= 6 * 60 * 60 * 1000
    router.emit_signal("screen_changed", TAVERN)
    assert_true(s.played_seconds - counted
            <= GameStateScript.PLAYED_SECONDS_PER_TRANSITION_CAP,
        "an overnight idle on one screen is not six hours of play")

func test_a_slot_row_says_the_play_time_in_words() -> void:
    # SaveGame's singular/plural branches, which nothing exercised while `played_seconds`
    # was always 0 — every row said "just started" and every other branch was dead code.
    var cases := [[0, "just started"], [59, "just started"], [60, "1 minute in"],
        [3599, "59 minutes in"], [3600, "1 hour in"], [7200, "2 hours in"]]
    for c in cases:
        var s = _state("Words Guild")
        s.played_seconds = float(c[0])
        assert_eq(SaveGame.save_slot(0, s), "")
        var label := String((SaveGame.slot_summaries()[0] as Dictionary)["label"])
        assert_true(label.ends_with(String(c[1])),
            "%d s should read '%s', got '%s'" % [int(c[0]), String(c[1]), label])


# --------------------------------- docs/14 §7.1's `rng_town`: the recruit board

func test_the_recruit_board_comes_back_off_the_disk_not_out_of_the_rng() -> void:
    # docs/14 §7.1's `rng_town` row states the reason in the doc itself: "Otherwise
    # reloading rerolls the recruit list." This is the exploit half of that: refreshing
    # also advances `recruit_pity`, so quit → Continue → Tavern was a free reroll past
    # docs/04 §3.2's `50g x 2^n` ladder AND a pity farm.
    var s = _state("Board Guild", 5000)
    s.refresh_board()
    assert_true(s.tavern_board.size() >= 4)
    assert_eq(s.hire(0), "")
    var seats: int = s.tavern_board.size()
    var ids: Array = []
    for c in s.tavern_board:
        ids.append(c.id)
    var pity: int = s.recruit_pity
    assert_eq(SaveGame.save_slot(0, s), "")

    var t = _blank()
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), t), [])
    assert_eq(t.tavern_board.size(), seats, "the post-hire seat count, not a full board")
    var back: Array = []
    for c in t.tavern_board:
        back.append(c.id)
    assert_eq(back, ids, "the same candidates, name for name")
    assert_eq(t.recruit_pity, pity, "and the pity counter did not advance on the way")
    assert_false(t.board_needs_first_roll(),
        "opening the Tavern on a loaded save must not refill it")

func test_the_reroll_ladder_survives_the_round_trip_with_the_board() -> void:
    # docs/04 §3.2: "price doubles each paid refresh within the same mission cycle."
    # The counter was already saved; the board it prices was not, which is what made the
    # ladder skippable.
    var s = _state("Ladder Guild", 5000)
    s.refresh_board()
    assert_eq(s.pay_to_reroll(), "")
    var price: int = s.reroll_cost()
    assert_eq(SaveGame.save_slot(0, s), "")
    var t = _blank()
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), t), [])
    assert_eq(t.reroll_cost(), price,
        "a reload must not walk the price back down to %d G" % GameStateScript.REROLL_BASE)


# =============================================== the load menu

func test_every_slot_is_described_even_when_empty() -> void:
    var rows: Array = SaveGame.slot_summaries()
    assert_eq(rows.size(), SaveGame.SLOTS, "docs/14 §7.2's three guild slots")
    for row in rows:
        assert_false(bool(row["exists"]))
        assert_true(String(row["label"]).contains("empty"), String(row["label"]))

func test_a_slot_says_the_guild_and_how_long_it_has_been_played() -> void:
    var s = _state("Long Guild")
    s.played_seconds = 7300.0
    SaveGame.save_slot(0, s)
    var rows: Array = SaveGame.slot_summaries()
    assert_true(bool(rows[0]["exists"]))
    assert_true(String(rows[0]["label"]).contains("Long Guild"))
    assert_true(String(rows[0]["label"]).contains("2 hours in"),
        String(rows[0]["label"]))

func test_an_autosave_newer_than_the_manual_save_is_the_one_offered() -> void:
    # It is what the player actually wants back.
    var s = _state("Newer Guild", 100)
    SaveGame.save_slot(0, s)
    s.gold = 900
    assert_eq(s.autosave(), "")
    var offered: Dictionary = SaveGame.newest_loadable()
    assert_false(offered.is_empty())

    var t = _blank()
    SaveGame.load_into(String(offered["path"]), t)
    assert_eq(t.gold, 900, "the newest state, not the oldest")

func test_continue_is_offered_only_when_something_is_loadable() -> void:
    assert_false(SaveGame.has_any_save())
    var s = _state("Loadable Guild")
    SaveGame.save_slot(0, s)
    assert_true(SaveGame.has_any_save())

func test_a_damaged_slot_is_listed_with_its_reason_not_hidden() -> void:
    var f := FileAccess.open(SaveGame.slot_path(0), FileAccess.WRITE)
    f.store_string("{ not a save")
    f.close()
    var rows: Array = SaveGame.slot_summaries()
    assert_true(String(rows[0]["label"]).contains("empty")
        or String(rows[0]["label"]).contains("damaged"),
        "a bad slot must still describe itself: %s" % String(rows[0]["label"]))
    assert_false(SaveGame.has_any_save(),
        "and it must not be offered as loadable")

func test_erasing_a_slot_takes_its_rotation_with_it() -> void:
    var s = _state("Doomed Guild")
    SaveGame.save_slot(0, s)
    s.autosave()
    SaveGame.erase_slot(0)
    assert_eq(SaveGame.read_header(SaveGame.slot_path(0)), {})
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        assert_eq(SaveGame.read_header(SaveGame.autosave_path(0, i)), {})


# =============================================== docs/14 §7.1: the frozen shape

## The v12 save shape, sorted, exactly as `GameState.to_dict()` emits it.
##
## This list and `FROZEN_AT_VERSION` move TOGETHER or not at all. That is the whole
## mechanism: adding a field to `to_dict()` fails the first assertion below, and bumping
## SAVE_VERSION fails the second, so the only way back to a green build is the deliberate
## act docs/14 §7.3 asks for — new key, new version, a registered migration step, and a
## committed fixture at the version being left behind.
##
## BUILD_STATE:159 already records this trick as the fix for the `reset()` class of bug:
## test it against the save shape, not field by field.
##
## v17 IS THE FREEZE (ship plan W7-SAVE, audit M6-SAVE-01): every block docs/14 §7.1
## lists has a key, and a later wave's persisted need is a key INSIDE `flags`
## (`GameState.ONCE_FLAG_DEFAULTS`), which this list does not enumerate. A fifth
## top-level key after this is a format change 1.0 does not make.
const FROZEN_AT_VERSION := 17
const FROZEN_SHAPE := [
    "achievements_claimed", "achievements_earned", "active_run",
    "attempts", "autosave_index", "best_rounds", "board_rolled", "bullet_tier",
    "bullet_triggers",
    "cleared", "completed", "completed_on_day",
    "completion_seen", "consumables", "crisis_strikes", "day", "facility_tier", "flags",
    "furnishings", "gold", "gold_earned_lifetime", "guild_furnishings", "guild_name",
    "guild_seed", "items_sold_lifetime",
    "legendary_classes_found", "legendary_warned", "log_tail", "market_tier",
    "morale_ledger",
    "onboarding_complete", "pending_deltas", "pending_loot", "played_seconds",
    "recruit_pity",
    "reputation_points", "reputation_rank", "rerolls_since_run", "roster",
    "rp_earned_lifetime",
    "save_counter", "save_slot", "save_version", "skipped_tutorials",
    "sold_recently", "stalled",
    "tavern_board", "tavern_tier", "tier_bonus_awarded", "town_flags",
    "trophy_witnesses", "wipe_streaks",
]

const FIXTURE_DIR := "res://tests/fixtures/saves"


## Copy a committed fixture somewhere writable and return the new path.
##
## Loading it in place would write a `.bak` into `res://`, which is read-only in an
## export build and dirty in this one — and would leave the fixture's own directory
## carrying a file nobody committed.
func _fixture_copy(version: int) -> String:
    var src := "%s/v%d_sample.json" % [FIXTURE_DIR, version]
    assert_true(FileAccess.file_exists(src),
        "no committed fixture at %s — docs/14 §7.3's second non-negotiable wants one "
        % src + "for every version this build can read (make it with "
        + "tests/fixtures/make_save_fixtures.gd, and read that file's warning first)")
    if not DirAccess.dir_exists_absolute(SaveGame.SAVE_DIR):
        DirAccess.make_dir_recursive_absolute(SaveGame.SAVE_DIR)
    var dst := "%s/fixture_v%d.json" % [SaveGame.SAVE_DIR, version]
    var f := FileAccess.open(dst, FileAccess.WRITE)
    assert_ne(f, null, "could not stage the fixture at %s" % dst)
    if f == null:
        return ""
    f.store_string(FileAccess.get_file_as_string(src))
    f.close()
    return dst


func test_the_save_shape_is_frozen_until_the_version_moves() -> void:
    var s = _state("Frozen Guild")
    var keys: Array = s.to_dict().keys()
    keys.sort()
    assert_eq(keys, FROZEN_SHAPE,
        "to_dict() no longer emits the frozen v%d key set. A shape change needs all "
        % FROZEN_AT_VERSION
        + "four in one commit: the new key here, SAVE_VERSION bumped, a step in "
        + "SaveGame.MIGRATIONS, and a committed fixture at the old version.")
    assert_eq(GameStateScript.SAVE_VERSION, FROZEN_AT_VERSION,
        "SAVE_VERSION moved and this record did not. Update FROZEN_SHAPE and "
        + "FROZEN_AT_VERSION together, and commit a fixture at the version left behind.")
    assert_eq(SaveGame.chain_gaps(SaveGame.OLDEST_MIGRATABLE), [],
        "and the chain must be able to walk every version it claims to read")

func test_a_fixture_is_committed_for_every_version_this_build_can_read() -> void:
    # docs/14 §7.3 non-negotiable 2: "Every migration gets a test with a committed
    # fixture save at the old version." The set is every version between the oldest
    # readable and the current one, inclusive, because each of them is a shape some
    # player's guild is sitting at.
    for v in range(SaveGame.OLDEST_MIGRATABLE, GameStateScript.SAVE_VERSION + 1):
        var path := "%s/v%d_sample.json" % [FIXTURE_DIR, v]
        assert_true(FileAccess.file_exists(path), "missing fixture %s" % path)
        assert_eq(int(SaveGame.read_header(path).get("save_version", -1)), v,
            "%s does not claim to be version %d" % [path, v])

func test_the_oldest_readable_fixture_loads_clean_and_is_backed_up_first() -> void:
    # The migration chain, walked end to end on a file this build did not write.
    var path := _fixture_copy(SaveGame.OLDEST_MIGRATABLE)
    var t = _blank()
    var problems: Array = SaveGame.load_into(path, t)
    assert_eq(problems, [], "a committed v%d save must come forward clean: %s"
        % [SaveGame.OLDEST_MIGRATABLE, str(problems)])
    assert_true(t.active, "and the campaign is live")
    assert_eq(t.guild_name, "The Least Worst")
    assert_true(t.roster.size() > 0, "with a roster")
    assert_true(t.attempts.size() > 0, "and the encounters it attempted")
    assert_true(FileAccess.file_exists(path + ".bak"),
        "docs/14 §7.3: the pre-migration file is backed up BEFORE the chain runs")
    assert_eq(int(SaveGame.read_header(path + ".bak").get("save_version", -1)),
        SaveGame.OLDEST_MIGRATABLE, "and the backup is the original, not the result")

func test_every_committed_fixture_loads_into_a_live_campaign() -> void:
    for v in range(SaveGame.OLDEST_MIGRATABLE, GameStateScript.SAVE_VERSION + 1):
        var t = _blank()
        var problems: Array = SaveGame.load_into(_fixture_copy(v), t)
        assert_eq(problems, [], "v%d fixture did not load clean: %s" % [v, str(problems)])
        assert_true(t.active, "v%d fixture produced no campaign" % v)
        assert_eq(t.guild_name, "The Least Worst", "v%d fixture lost the guild name" % v)
        assert_eq(t.day, 18, "v%d fixture lost the day" % v)

func test_the_current_version_fixture_is_not_migrated_and_writes_no_backup() -> void:
    var path := _fixture_copy(GameStateScript.SAVE_VERSION)
    SaveGame.load_into(path, _blank())
    assert_false(FileAccess.file_exists(path + ".bak"),
        "a save already at the current version must not be rewritten or backed up")

func test_each_fixture_carries_exactly_the_keys_its_version_shipped() -> void:
    # Proof that the older fixtures are genuinely older, and not the current shape with
    # a smaller number written on it. The key sets below are the shape `to_dict()`
    # emitted at commits f2bc62a (v10), 2618989 (v11) and 22edc80 (v12), read out of git,
    # and they are the same lists `tests/fixtures/make_save_fixtures.gd` downgrades by —
    # if the two ever disagree, the fixtures are not what this test thinks they are.
    var added_in_v11 := ["tavern_board", "board_rolled"]
    var added_in_v12 := ["wipe_streaks", "bullet_triggers", "bullet_tier",
        "legendary_warned"]
    var added_in_v13 := ["skipped_tutorials"]
    var added_in_v14 := ["completed", "completed_on_day", "completion_seen"]
    var added_in_v15 := ["gold_earned_lifetime", "rp_earned_lifetime",
        "items_sold_lifetime"]
    var added_in_v16 := ["achievements_earned", "achievements_claimed", "town_flags"]
    var added_in_v17 := ["active_run", "log_tail", "best_rounds", "pending_deltas"]

    var v16_shape: Array = []
    for k in FROZEN_SHAPE:
        if not (k in added_in_v17):
            v16_shape.append(k)
    var v15_shape: Array = []
    for k in v16_shape:
        if not (k in added_in_v16):
            v15_shape.append(k)
    var v14_shape: Array = []
    for k in v15_shape:
        if not (k in added_in_v15):
            v14_shape.append(k)
    var v13_shape: Array = []
    for k in v14_shape:
        if not (k in added_in_v14):
            v13_shape.append(k)
    var v12_shape: Array = []
    for k in v13_shape:
        if not (k in added_in_v13):
            v12_shape.append(k)
    var v11_shape: Array = []
    for k in v12_shape:
        if not (k in added_in_v12):
            v11_shape.append(k)
    var v10_shape: Array = []
    for k in v11_shape:
        if not (k in added_in_v11):
            v10_shape.append(k)

    assert_eq(_fixture_body_keys(10), v10_shape, "the v10 fixture is not v10-shaped")
    assert_eq(_fixture_body_keys(11), v11_shape, "the v11 fixture is not v11-shaped")
    assert_eq(_fixture_body_keys(12), v12_shape, "the v12 fixture is not v12-shaped")
    assert_eq(_fixture_body_keys(13), v13_shape, "the v13 fixture is not v13-shaped")
    assert_eq(_fixture_body_keys(14), v14_shape, "the v14 fixture is not v14-shaped")
    assert_eq(_fixture_body_keys(15), v15_shape, "the v15 fixture is not v15-shaped")
    assert_eq(_fixture_body_keys(16), v16_shape, "the v16 fixture is not v16-shaped")
    assert_eq(_fixture_body_keys(GameStateScript.SAVE_VERSION), FROZEN_SHAPE,
        "the current fixture is not the current shape")


func _fixture_body_keys(version: int) -> Array:
    var src := "%s/v%d_sample.json" % [FIXTURE_DIR, version]
    var doc = JSON.parse_string(FileAccess.get_file_as_string(src))
    if typeof(doc) != TYPE_DICTIONARY:
        return []
    var keys: Array = (doc.get("body", {}) as Dictionary).keys()
    keys.sort()
    return keys


# =============================================== docs/14 §7.3: reconcile_content

func test_a_vanished_item_leaves_an_empty_slot_and_a_sentence() -> void:
    # docs/14 §7.3's table row: "Item / class / encounter id no longer exists —
    # `reconcile_content` moves the reference to `orphaned[]`, logs it, and continues.
    # Never crash, never silently equip nothing."
    var s = _state("Ghost Gear")
    SaveGame.save_slot(0, s)
    var path := SaveGame.slot_path(0)
    var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
    # A different content set is what triggers reconciliation at all (§7.3's pseudocode
    # reads `if header.content_version != CURRENT_CONTENT`).
    doc["header"]["content_version"] = SaveGame.CONTENT_VERSION + 1
    var slot_key := String((doc["body"]["roster"][0]["equipment"] as Dictionary).keys()[0])
    doc["body"]["roster"][0]["equipment"][slot_key] = "no_such_item"
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(doc, "  "))
    f.close()

    var t = _blank()
    var problems: Array = SaveGame.load_into(path, t)
    var named := false
    for p in problems:
        if String(p).contains("no_such_item"):
            named = true
    assert_true(named, "the orphaned id must be named: %s" % str(problems))
    assert_true(t.active, "and the campaign still loads — never crash")
    assert_eq(String(t.roster[0].equipment.get(Enums.slot_from_key(slot_key), "")), "",
        "the slot is empty, not holding a phantom")

func test_a_vanished_encounter_is_moved_out_of_the_progress_tables() -> void:
    var s = _state("Ghost Boss")
    s.cleared = {"t1_raid_e1": 1, "no_such_encounter": 3}
    s.attempts = {"no_such_encounter": 4}
    SaveGame.save_slot(0, s)
    var path := SaveGame.slot_path(0)
    var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
    doc["header"]["content_version"] = 0
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(doc, "  "))
    f.close()

    var t = _blank()
    var problems: Array = SaveGame.load_into(path, t)
    var named := 0
    for p in problems:
        if String(p).contains("no_such_encounter"):
            named += 1
    assert_eq(named, 2, "once for `cleared` and once for `attempts`: %s" % str(problems))
    assert_false(t.cleared.has("no_such_encounter"), "the dead id is gone")
    assert_eq(t.clear_count("t1_raid_e1"), 1, "and the live one is untouched")

func test_reconciliation_only_runs_when_the_content_set_changed() -> void:
    # §7.3's pseudocode gates it on the header. A save written against THIS content set
    # has nothing to reconcile, and paying for the walk on every load would be a cost
    # with no reader.
    var s = _state("Same Content")
    s.cleared = {"no_such_encounter": 1}
    SaveGame.save_slot(0, s)
    var t = _blank()
    var problems: Array = SaveGame.load_into(SaveGame.slot_path(0), t)
    assert_eq(problems, [], "no reconciliation at a matching content_version")
    assert_true(t.cleared.has("no_such_encounter"),
        "and nothing was walked, so nothing was moved")

func test_reconcile_content_keeps_a_vanished_class_rather_than_guessing_one() -> void:
    # §7.3: a migration "may DROP a field, never guess a value". A raider with a class
    # this build does not have is reported; picking one for them would be a guess
    # wearing their name.
    var s = _state("Ghost Class")
    var body: Dictionary = s.to_dict()
    body["roster"][0]["class_id"] = "no_such_class"
    var problems: Array = SaveGame.reconcile_content(body, _db)
    var named := false
    for p in problems:
        if String(p).contains("no_such_class"):
            named = true
    assert_true(named, "the class must be reported: %s" % str(problems))
    assert_eq(String(body["roster"][0]["class_id"]), "no_such_class",
        "and left exactly as written")
    assert_true(body.has("orphaned"), "with the reference recorded")

func test_reconcile_content_leaves_the_code_owned_stores_alone() -> void:
    # `consumables` and `furnishings` are keyed by `Consumables.SKUS` and
    # `Comfort.FURNISHINGS`, which are code constants and not `data/`. CONTENT_VERSION
    # describes the content set, so putting those two under it would put one field's
    # fate under two version counters at once.
    var s = _state("Code Stores")
    var body: Dictionary = s.to_dict()
    body["consumables"] = {"no_such_sku@1": 2}
    body["furnishings"] = {"nobody": ["no_such_furnishing"]}
    var problems: Array = SaveGame.reconcile_content(body, _db)
    assert_eq(problems, [], "neither store is the content set's business: %s"
        % str(problems))
    assert_true((body["consumables"] as Dictionary).has("no_such_sku@1"))


# =============================================== docs/14 §7.1: the rank/RP canary

func test_a_rank_below_what_its_points_bought_is_reported_as_corruption() -> void:
    # docs/14 §7.1's `guild` row: "Rank is derived from RP but stored anyway, and the
    # loader asserts they agree — a cheap corruption canary."
    var s = _state("Bent Ledger")
    s.reputation_points = 1800
    s.reputation_rank = Enums.ReputationRank.UNKNOWN
    SaveGame.save_slot(0, s)

    var t = _blank()
    var problems: Array = SaveGame.load_into(SaveGame.slot_path(0), t)
    var named := false
    for p in problems:
        if String(p).contains("Rank and reputation disagree"):
            named = true
    assert_true(named, "the disagreement must be reported: %s" % str(problems))
    assert_true(t.active, "and the campaign still loads")
    assert_eq(t.reputation_rank, Enums.ReputationRank.UNKNOWN,
        "docs/14 §7.3: the saved value is kept, never repaired by a guess")

func test_a_rank_held_above_its_points_is_not_a_false_alarm() -> void:
    # docs/03 §6.5's monotonic rank: a disband costs RP and leaves the rank standing, so
    # a legitimate save routinely carries a rank ABOVE the one its RP would buy today.
    # `rank_for_rp` alone would call every post-disband guild corrupt; `rank_after` is
    # why the comparison is one-sided.
    var s = _state("Fallen On Hard Times")
    s.reputation_points = 10
    s.reputation_rank = Enums.ReputationRank.RENOWNED
    SaveGame.save_slot(0, s)

    var t = _blank()
    var problems: Array = SaveGame.load_into(SaveGame.slot_path(0), t)
    assert_eq(problems, [], "a held rank above its points is legal: %s" % str(problems))
    assert_eq(t.reputation_rank, Enums.ReputationRank.RENOWNED)

func test_the_canary_says_nothing_about_a_rank_key_it_cannot_read() -> void:
    # An unknown key is `from_dict`'s error to report. Two problems for one field would
    # send a bug report chasing a rank/RP mismatch that is really a typo.
    var problems: Array = SaveGame.rank_canary(
        {"reputation_rank": "gloriously_unknown", "reputation_points": 9999})
    assert_eq(problems, [], "the canary stays out of it: %s" % str(problems))


# =============================================== v17: the four blocks, and the freeze

const A1 := "t1_adv_a1"
const RESULTS := "res://game/screens/Results.tscn"


## One real attempt through the campaign's one door, the way RaidPrep departs:
## the chalked party, the folded loadout, a drawn seed, then `record_attempt`
## handed the loadout and the run options so `active_run` is the fight as run.
func _attempt(s, encounter_id: String = A1, opts: Dictionary = {}):
    var enc = _db.encounter(encounter_id)
    assert_ne(enc, null, "content has %s" % encounter_id)
    var party: Array = s.roster.slice(0, mini(int(enc.party_size), s.roster.size()))
    var loadout: Dictionary = s.build_loadout(party)
    var result = s.run_attempt(party, enc, s.next_raid_seed(), loadout, opts)
    var record_opts: Dictionary = opts.duplicate()
    record_opts["loadout"] = loadout
    s.record_attempt(encounter_id, result, party, record_opts)
    return result


## The newest rotation entry of slot 0, parsed, or {}.
func _newest_autosave_body() -> Dictionary:
    var best: Dictionary = {}
    var best_seq := -1
    for i in SaveGame.AUTOSAVES_PER_SLOT:
        var path := SaveGame.autosave_path(0, i)
        var header := SaveGame.read_header(path)
        if header.is_empty() or int(header.get("sequence", 0)) <= best_seq:
            continue
        var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
        if typeof(doc) == TYPE_DICTIONARY and typeof(doc.get("body", null)) == TYPE_DICTIONARY:
            best = doc["body"]
            best_seq = int(header.get("sequence", 0))
    return best


func test_the_v17_sample_round_trips_with_every_block_docs_14_lists() -> void:
    # docs/14 §7.1's ten rows, all present at last (SHIP-02): the four v17 blocks
    # are in the committed sample, and the sample survives a write and a read
    # without changing shape or content.
    var t = _blank()
    assert_eq(SaveGame.load_into(_fixture_copy(GameStateScript.SAVE_VERSION), t), [],
        "the current fixture loads clean")
    var first: Dictionary = t.to_dict()
    for key in ["active_run", "log_tail", "best_rounds", "pending_deltas"]:
        assert_true(first.has(key), "v17 carries %s" % key)
    assert_true(bool((first["active_run"] as Dictionary).get("resolved", false)),
        "the sample's last attempt still owes its report")
    assert_true(((first["log_tail"] as Dictionary).get("lines", []) as Array).size() > 0,
        "and its report has lines")
    var u = _blank()
    assert_eq(u.from_dict(first), [], "the body a v17 state writes reads back clean")
    assert_eq(u.to_dict(), first, "byte for byte")


func test_a_v10_save_walks_the_whole_chain_to_v17_and_says_so() -> void:
    # The chain, step by step: every stamp between the oldest readable version
    # and the freeze, in order, and the load names the walk in one line.
    var body := {"save_version": SaveGame.OLDEST_MIGRATABLE, "guild_name": "Walker"}
    var v: int = SaveGame.OLDEST_MIGRATABLE
    var walked: Dictionary = body.duplicate(true)
    while v < GameStateScript.SAVE_VERSION:
        walked = (SaveGame.MIGRATIONS[v] as Callable).call(walked)
        v += 1
        assert_eq(int(walked["save_version"]), v, "step %d stamps %d" % [v - 1, v])
    assert_eq(v, 17, "the chain ends at the frozen version")

    var path := _fixture_copy(SaveGame.OLDEST_MIGRATABLE)
    var t = _blank()
    assert_eq(SaveGame.load_into(path, t), [], "the v10 fixture comes forward clean")
    assert_true(SaveGame.last_migration_note.contains("from save version 10 to 17"),
        "the walk is one readable line: '%s'" % SaveGame.last_migration_note)
    assert_true(SaveGame.last_migration_note.contains("(7 steps)"))
    assert_eq(t.to_dict().keys().size(), FROZEN_SHAPE.size(),
        "and what comes out is the frozen shape")
    # A save already at v17 needs no walk and says nothing.
    SaveGame.load_into(_fixture_copy(GameStateScript.SAVE_VERSION), _blank())
    assert_eq(SaveGame.last_migration_note, "")


func test_a_quit_between_the_account_and_the_report_still_lands_on_the_report() -> void:
    # SHIP-03 / Q-53: the attempt is committed at Depart, so what a mid-replay
    # quit could lose was the wipe report. Now the save carries the attempt as
    # it departed, and Continue replays it — the same outcome, the same rounds.
    var s = _state("Interrupted")
    var lived = _attempt(s)
    assert_true(s.active_run_pending(), "the report is owed until it is dismissed")
    assert_eq(String(s.active_run["encounter_id"]), A1)
    assert_eq(int(s.active_run["master_seed"]), int(lived.seed_used))
    assert_eq((s.active_run["party_ids"] as Array).size(), (s.active_run["party"] as Array).size(),
        "the party is snapshotted as it departed")
    assert_eq(s.save_now(), "", "quit to the menu writes the manual slot")

    var t = _blank()
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), t), [])
    assert_true(t.active_run_pending(), "the loaded guild still owes the report")
    var again = t.replay_active_run()
    assert_ne(again, null, "Continue replays the stored attempt")
    assert_eq(int(again.outcome), int(lived.outcome), "the same outcome")
    assert_eq(int(again.rounds), int(lived.rounds), "in the same number of rounds")
    assert_eq(int(again.mistake_count), int(lived.mistake_count), "with the same mistakes")
    assert_eq(t.last_result, again, "and Results reads it as the last result")
    assert_eq(t.last_party.size(), (t.active_run["party_ids"] as Array).size(),
        "the loot split is offered to the live raiders who went")


func test_the_report_is_dismissed_by_leaving_it_for_the_town_and_not_by_a_detour() -> void:
    var s = _state("Dismissed")
    _attempt(s)
    var r = _router()
    assert_ne(r, null)
    s._ensure_router_connected()
    r.screen_changed.emit(RAID_VIEW)
    r.screen_changed.emit(RESULTS)
    assert_true(s.active_run_pending(), "reading the report does not dismiss it")
    r.screen_changed.emit("res://game/screens/Settings.tscn")
    r.screen_changed.emit(RESULTS)
    assert_true(s.active_run_pending(), "nor does a detour to Options and back")
    r.screen_changed.emit(MAIN_MENU)
    assert_true(s.active_run_pending(), "nor a quit to the menu from the report")
    r.screen_changed.emit(RESULTS)
    r.screen_changed.emit(TOWN)
    assert_false(s.active_run_pending(), "leaving the report for the town does")
    assert_false(bool(_newest_autosave_body().get("active_run", {}).get("resolved", false)),
        "and the transition write already says so")


func test_the_replayed_report_keeps_its_payout_and_the_log_tail_its_lines() -> void:
    # docs/14 §7.1's `log_tail`: "lets the post-mortem survive a reload". The
    # header facts are the report's own, and the lines are the rendered
    # play-by-play — strings, so no content edit can strand a template.
    var s = _state("Tailed")
    var lived = _attempt(s)
    var tail: Dictionary = s.log_tail
    assert_eq(String(tail["encounter_id"]), A1)
    assert_eq(int(tail["rounds"]), int(lived.rounds))
    assert_eq(bool(tail["cleared"]), lived.cleared())
    assert_eq(int(tail["payout"]), int(s.last_payout))
    assert_true((tail["lines"] as Array).size() > 0, "the tail has lines")
    assert_true((tail["lines"] as Array).size() <= GameStateScript.LOG_TAIL_CAP,
        "and never more than the cap")
    for line in tail["lines"]:
        assert_eq(typeof(line), TYPE_STRING, "every line is rendered text")
    assert_eq(s.save_now(), "")
    var t = _blank()
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), t), [])
    assert_eq(t.log_tail["lines"], tail["lines"], "the lines survive the reload")
    t.replay_active_run()
    assert_eq(int(t.last_payout), int(s.last_payout), "and the payout the report prints")


func test_a_queued_departure_survives_a_quit_between_ticks() -> void:
    # docs/14 §7.1's `pending_deltas`: "so quitting between encounters cannot eat
    # a consequence". docs/05 §7.2's peer hit lands on the tick AFTER a departure;
    # a save written between the two used to drop it.
    var s = _state("Grieving")
    assert_true(s.roster.size() >= 2)
    var gone = s.roster[0]
    var gone_id := String(gone.id)
    var gone_class: int = int(gone.class_id)
    s._pending_departures.append({"id": gone_id, "class_id": gone_class})
    assert_eq(s.save_now(), "")
    var t = _blank()
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), t), [])
    assert_eq(t.pending_deltas(), [{"id": gone_id, "class_id": gone_class}],
        "the queued departure came back off the disk")
    var before: Array = []
    for r in t.roster:
        before.append(float(r.morale))
    t.rest_in_town()
    assert_eq(t.pending_deltas(), [], "the next tick applied it")
    var moved := false
    for i in t.roster.size():
        if absf(float(t.roster[i].morale) - float(before[i])) > 0.001:
            moved = true
    assert_true(moved, "and somebody felt it")


func test_best_rounds_records_the_fastest_clear_only() -> void:
    var s = _state("Timed")
    assert_eq(s.best_rounds, {}, "nothing cleared, nothing recorded")
    # Two hand-shaped results: a slow clear, a faster one, then a wipe that must
    # not move the figure.
    var slow := _Outcome.new()
    slow.won = true
    slow.rounds = 9
    s.record_attempt(A1, slow, s.roster.slice(0, 6))
    assert_eq(int(s.best_rounds[A1]), 9)
    var quick := _Outcome.new()
    quick.won = true
    quick.rounds = 6
    s.record_attempt(A1, quick, s.roster.slice(0, 6))
    assert_eq(int(s.best_rounds[A1]), 6, "a faster clear replaces it")
    var wipe := _Outcome.new()
    wipe.rounds = 3
    s.record_attempt(A1, wipe, s.roster.slice(0, 6))
    assert_eq(int(s.best_rounds[A1]), 6, "a wipe does not")
    assert_eq(s.save_now(), "")
    var t = _blank()
    SaveGame.load_into(SaveGame.slot_path(0), t)
    assert_eq(t.best_rounds, {A1: 6})


## The smallest thing `record_attempt` accepts: an outcome and a round count.
class _Outcome extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    var deltas_queued: Array = []
    var rounds: int = 0
    var won: bool = false
    func cleared() -> bool: return won


func test_dismissing_a_raider_writes_a_rotation_entry_with_the_ledger_line() -> void:
    # SHIP-15: docs/14 §7.4's "Recruit hired / raider fired" row was half-wired —
    # a hire autosaved and a dismissal did not, so a dismissal followed by a
    # process kill lost both the raider and the -2 the rest took.
    var s = _state("Firing")
    var before := _sequences()
    var gone_id := String(s.roster[s.roster.size() - 1].id)
    assert_eq(s.dismiss_raider(gone_id), "")
    var after := _sequences()
    assert_ne(after, before, "the dismissal spent a rotation entry")
    var body := _newest_autosave_body()
    assert_false(body.is_empty(), "and the entry is readable")
    var ids: Array = []
    for entry in body.get("roster", []):
        ids.append(String((entry as Dictionary).get("id", "")))
    assert_false(ids.has(gone_id), "the raider is gone from the file")
    assert_true(JSON.stringify(body.get("morale_ledger", {})).contains("peer_dismissed"),
        "and the ledger line the rest of the roster took is inside it")


func test_a_transition_write_carries_what_was_just_earned() -> void:
    # SHIP-15's second hole: `_autosave_transition()` and `save_now()` wrote the
    # state without re-checking the wall, so a snapshot record earned on the
    # Market lit on the next raid rather than the next screen.
    var s = _state("Earning")
    var r = _router()
    assert_ne(r, null)
    s._ensure_router_connected()
    # `rost_one_of_each` is earned by the starting twelve (they cover all nine
    # classes); nothing has checked the wall since `new_game`.
    assert_false(s.achievements_earned.has("rost_one_of_each"))
    r.screen_changed.emit(TOWN)
    assert_true(s.achievements_earned.has("rost_one_of_each"),
        "the transition write noticed the record")
    var earned = _newest_autosave_body().get("achievements_earned", {})
    assert_true((earned as Dictionary).has("rost_one_of_each"),
        "and wrote it: %s" % str(earned))
    var t = _state("Quitting")
    assert_false(t.achievements_earned.has("rost_one_of_each"))
    assert_eq(t.save_now(), "")
    var doc = JSON.parse_string(FileAccess.get_file_as_string(SaveGame.slot_path(0)))
    assert_true(((doc["body"] as Dictionary).get("achievements_earned", {}) as Dictionary)
        .has("rost_one_of_each"), "the manual write carries it too")


func test_a_once_flag_rides_inside_flags_without_a_bump() -> void:
    # The freeze's escape hatch: a later wave's "has the player seen it" mark is
    # a key inside `flags`, declared in ONCE_FLAG_DEFAULTS, typed by its default,
    # and never a top-level key.
    var s = _state("Marked")
    assert_eq(s.once_flag("last_rank_seen"), 0, "a fresh guild has seen Unknown")
    assert_true(s.set_once_flag("last_rank_seen", 2))
    assert_true(s.set_once_flag("disbanded_day", 41))
    assert_true(s.set_once_flag("crisis_modal_seen", true))
    assert_eq(s.save_now(), "")
    var t = _blank()
    assert_eq(SaveGame.load_into(SaveGame.slot_path(0), t), [], "no dropped-flag problem")
    assert_eq(t.once_flag("last_rank_seen"), 2)
    assert_eq(typeof(t.once_flag("last_rank_seen")), TYPE_INT, "an int comes back an int")
    assert_eq(t.once_flag("disbanded_day"), 41)
    assert_eq(t.once_flag("crisis_modal_seen"), true)
    assert_eq(t.once_flag("walk_in_id"), "", "an unset mark reads its default")
    assert_false(GameStateScript.FLAG_DEFAULTS.has("last_rank_seen"),
        "a mark is not a feature flag")
    var keys: Array = t.to_dict().keys()
    keys.sort()
    assert_eq(keys, FROZEN_SHAPE, "and the top-level shape did not move")


