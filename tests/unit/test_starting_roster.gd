extends "res://tests/TestCase.gd"
## The opening roster, and the Guildhall/Roster screens that read it.

const StartingRoster = preload("res://game/core/StartingRoster.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const RouterScript = preload("res://game/core/ScreenRouter.gd")
const RosterView = preload("res://game/screens/Roster.gd")
const GuildhallScript = preload("res://game/screens/Guildhall.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Morale = preload("res://sim/core/Morale.gd")

const GUILDHALL := "res://game/screens/Guildhall.tscn"

var _db = null
var _made: Array = []

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []

func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []

func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null

func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out

func _joined(n: Node) -> String:
    return "\n".join(PackedStringArray(_texts(n)))

# ---------------------------------------------------------------- composition

func test_the_opening_roster_can_field_a_raid() -> void:
    # The whole reason a starting roster exists: raid size is 12 (✅ CANON) and
    # docs/01's 60 G buys four Common hires at docs/11 §S1's 15 G. Starting
    # empty makes the first raid unreachable.
    assert_eq(StartingRoster.BENCHMARK_COMP.size(), Enums.RAID_SIZE)

func test_the_opening_roster_is_the_benchmark_composition() -> void:
    # docs/06 §6.4 Template A, adopted verbatim by docs/08 §9.1 and docs/10
    # §5.3. Starting the player here means the opening hours are the difficulty
    # the balance sweep actually measures.
    var comp := StartingRoster.composition()
    assert_eq(int(comp.get("warrior", 0)), 2, "canon: most fights need 2 tanks")
    assert_eq(int(comp.get("rogue", 0)), 2)
    assert_eq(int(comp.get("wizard", 0)), 2)
    for solo in ["monk", "bard", "mage", "cleric", "druid", "shaman"]:
        assert_eq(int(comp.get(solo, 0)), 1, "%s should appear once" % solo)

func test_all_three_healing_shapes_are_present() -> void:
    var comp := StartingRoster.composition()
    for healer in ["cleric", "druid", "shaman"]:
        assert_true(comp.has(healer), "missing healer shape %s" % healer)

# ---------------------------------------------------------------- generation

func test_twelve_commons_arrive_in_starting_armour() -> void:
    var roster := StartingRoster.build(_db, 12345)
    assert_eq(roster.size(), Enums.RAID_SIZE)
    for r in roster:
        assert_eq(r.rarity, Enums.Rarity.COMMON,
            "canon: at Unknown you find only the worst players")
        assert_eq(r.recruited_at_rank, Enums.ReputationRank.UNKNOWN)
        assert_true(r.equipment.size() > 0,
            "%s arrived with no gear" % r.display_name)
        for it in r.equipped_items(_db):
            assert_eq(it.source, "start",
                "%s is wearing non-starting gear" % r.display_name)

func test_everyone_starts_at_their_own_common_baseline() -> void:
    # docs/05 §8: a Common walks in at 45 — plus docs/05 §7.5's backstory
    # offset now that starters draw a past (LOOP-17), the way a hire does
    # (docs/05 §4). Every one of them is inside the "Slightly Annoyed" band.
    var seen := {}
    for r in StartingRoster.build(_db, 7):
        assert_eq(int(r.morale), Morale.baseline_of(r, 0), r.display_name)
        assert_eq(int(r.morale), 45 + int(r.backstory_offset))
        assert_eq(r.morale_band_name(), "Slightly Annoyed")
        seen[int(r.morale)] = true
    assert_true(seen.size() > 1, "different pasts, different openings: %s" % str(seen.keys()))

func test_generation_is_deterministic() -> void:
    var a := StartingRoster.build(_db, 999)
    var b := StartingRoster.build(_db, 999)
    for i in a.size():
        assert_eq(a[i].display_name, b[i].display_name)
        assert_eq(a[i].id, b[i].id)

func test_canon_named_examples_are_on_the_opening_roster() -> void:
    # Bob, Greg and Steve are the three raiders canon uses to explain morale.
    # Seeing them on day one is the game quoting its own design notes.
    var by_name := {}
    for r in StartingRoster.build(_db, 4242):
        by_name[r.display_name] = r
    for pair in [["Bob", "warrior"], ["Greg", "rogue"], ["Steve", "mage"]]:
        assert_true(by_name.has(pair[0]), "%s should be a starter" % pair[0])
        assert_eq(by_name[pair[0]].class_key(), pair[1],
            "%s is canon's %s" % [pair[0], pair[1]])

func test_natsuna_is_not_a_starting_common() -> void:
    # Canon makes her a NAMED LEGENDARY shaman, and "you can only ever find 1
    # Legendary per class". Handing her over on day one would delete the hunt.
    for r in StartingRoster.build(_db, 555):
        assert_ne(r.display_name, "Natsuna",
            "Natsuna is a Legendary to be found, not a starting Common")

func test_nobody_shares_a_name() -> void:
    var seen := {}
    for r in StartingRoster.build(_db, 31337):
        assert_false(seen.has(r.display_name),
            "duplicate raider name '%s'" % r.display_name)
        seen[r.display_name] = true

func test_the_other_nine_draw_from_the_one_name_register() -> void:
    # CONTENT-20: this file used to carry twenty-four literals of its own — a
    # second register nobody could ever hire from at the Tavern, twenty-two of
    # them never reviewed under docs/15 BL-53. docs/04 §7: "Pool is data, not
    # code" — every non-canon starter's name is rooted in data/names.json.
    var NamePool = load("res://sim/content/NamePool.gd")
    var pool = NamePool.load_from()
    assert_true(pool.is_valid(), "data/names.json loads: %s" % str(pool.errors))
    var given: Array = pool.given
    assert_true(given.size() >= 30, "the register docs/04 §7.1 sampled")
    for seed_value in [4242, 555, 31337, 8]:
        for r in StartingRoster.build(_db, seed_value):
            var name := String(r.display_name)
            if name in ["Bob", "Greg", "Steve"]:
                continue
            assert_true(given.has(pool.root_of(name)),
                "'%s' (seed %d) is not rooted in data/names.json" % [name, seed_value])
            assert_false(name.begins_with("Recruit "), "the placeholder never fires with the pool present")
    var source := FileAccess.get_file_as_string("res://game/core/StartingRoster.gd")
    assert_false(source.contains("const NAME_POOL"), "the literal pool is gone")

func test_every_starter_has_a_backstory_and_carries_its_offset() -> void:
    # LOOP-17: the starters drew no backstory, so every first-time raider's
    # detail page admitted an unbuilt module. They draw as a recruit does —
    # docs/04 §5 step 7, Common's guaranteed-negative first bullet included —
    # and the offset is the bullets' own (docs/05 §7.5), so the Quarters line
    # reads truthfully on day one.
    var BackstoryPool = load("res://sim/content/BackstoryPool.gd")
    for r in StartingRoster.build(_db, 4242):
        assert_true(r.backstory.size() >= 2,
            "%s has %d bullet(s); a Common draws two" % [r.display_name, r.backstory.size()])
        assert_eq(r.backstory_offset, BackstoryPool.offset_for(r.backstory),
            "%s's offset is the sum of their bullets" % r.display_name)
        assert_eq(String(r.backstory[0]["polarity"]), "negative",
            "a Common's first bullet is negative (docs/04 §8.1)")
        assert_eq(int(r.morale), Morale.baseline_of(r, 0),
            "%s opens at their own baseline, as a hire does (docs/05 §4)" % r.display_name)
        assert_eq(Enums.morale_band_name(int(r.morale)), "Slightly Annoyed",
            "a Common's past keeps them inside docs/05 §8's opening band")
    # And the same seed draws the same stories (docs/15 BL-23).
    var a := StartingRoster.build(_db, 99)
    var b := StartingRoster.build(_db, 99)
    for i in a.size():
        assert_eq(a[i].display_name, b[i].display_name)
        assert_eq(a[i].backstory, b[i].backstory)

func test_ids_are_unique() -> void:
    var seen := {}
    for r in StartingRoster.build(_db, 8):
        assert_false(seen.has(r.id), "duplicate id '%s'" % r.id)
        seen[r.id] = true

func test_an_absent_content_db_yields_nothing_rather_than_crashing() -> void:
    assert_eq(StartingRoster.build(null, 1).size(), 0)

# ---------------------------------------------------------------- game state

func test_a_new_game_hands_the_player_a_full_raid() -> void:
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Test Guild")
    assert_eq(s.roster.size(), Enums.RAID_SIZE)
    assert_true(s.can_field_a_raid(), "the first raid must be reachable")
    assert_false(s.roster_is_full(),
        "the roster starts under its cap of %d so hiring still matters"
        % s.roster_cap())

func test_the_same_guild_name_produces_the_same_guild() -> void:
    # Deriving the seed from the name makes a reported bug reproducible from a
    # screenshot of the title bar.
    var a = GameStateScript.new()
    var b = GameStateScript.new()
    _made.append(a)
    _made.append(b)
    for s in [a, b]:
        s.reset()
        s.set_content(_db)
        s.new_game("Ashfall Company")
    assert_eq(a.guild_seed, b.guild_seed)
    for i in a.roster.size():
        assert_eq(a.roster[i].display_name, b.roster[i].display_name)

func test_the_guild_seed_survives_a_save_round_trip() -> void:
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Seeded")
    var d: Dictionary = s.to_dict()
    var other = GameStateScript.new()
    _made.append(other)
    other.reset()
    var problems: Array = other.from_dict(d)
    assert_eq(problems.size(), 0, str(problems))
    assert_eq(other.guild_seed, s.guild_seed)
    assert_eq(other.roster.size(), Enums.RAID_SIZE)

# ---------------------------------------------------------------- the screens

func _mounted_guildhall():
    var root := _root()
    var host := Control.new()
    root.add_child(host)
    _made.append(host)
    var state = root.get_node_or_null("GameState")
    state.reset()
    state.set_content(_db)
    state.new_game("Ashfall Company")
    var r = RouterScript.new()
    _made.append(r)
    r.register_host(host)
    assert_true(r.goto(GUILDHALL), "the Guildhall must open")
    return r.current_screen()

func test_the_guildhall_opens_on_the_roster_tab() -> void:
    # docs/13 §6.1's depth rule: reading the roster is Town -> Guildhall ->
    # Roster tab, and it must be two clicks. Landing on the tab is that.
    var hall = _mounted_guildhall()
    assert_eq(hall.active_tab(), "roster")

func test_the_roster_prints_canons_two_line_format() -> void:
    # "Bob" / "Warrior — Slightly Annoyed" — canon's exact shape, with the
    # opening roster's baseline morale rather than its example values.
    var printed := _joined(_mounted_guildhall())
    assert_true(printed.contains("Bob"), "canon's Bob should be listed")
    assert_true(printed.contains("Warrior — Slightly Annoyed"),
        "the second line is '<Class> — <State>'")
    # The morale number leads the row — Bob's own baseline (45 plus his past).
    var root := _root()
    var bob = null
    for r in root.get_node_or_null("GameState").roster:
        if String(r.display_name) == "Bob":
            bob = r
    assert_true(bob != null)
    assert_true(printed.contains("Bob — %d " % int(bob.morale)), "morale and face lead the row: %s" % printed)

func test_the_roster_shows_every_starting_raider() -> void:
    var printed := _joined(_mounted_guildhall())
    assert_true(printed.contains("Showing 12 of 12"))
    for name in ["Bob", "Greg", "Steve"]:
        assert_true(printed.contains(name), "%s missing from the roster" % name)

func test_the_roster_footer_tallies_roles_and_risk() -> void:
    var printed := _joined(_mounted_guildhall())
    # The mean of twelve baselines that sit a point or three around 45.
    var total := 0
    var roster: Array = _root().get_node_or_null("GameState").roster
    for r in roster:
        total += int(r.morale)
    var mean := int(round(float(total) / float(roster.size())))
    assert_true(printed.contains("Roster average morale %d" % mean), printed)
    assert_true(absi(mean - 45) <= 3, "the opening mood is docs/05 §8's, give or take a past")
    assert_true(printed.contains("At risk 0"),
        "nobody starts in bands 0-2")
    assert_true(printed.contains("Tanks 2"), "the benchmark comp has two tanks")
    assert_true(printed.contains("Healers 3"), "all three healing shapes")

func test_shut_guildhall_tabs_say_why() -> void:
    # Three tabs (LOOP-14 / UI-50): the permanently disabled "Raid Group" tab is
    # gone — RaidPrep's strip is the raid group. Records is shut on a new guild
    # by a TRUE gate (docs/03 §7: the wall opens at Known) and says so in the
    # sim's one sentence (LOOP-15).
    var printed := _joined(_mounted_guildhall())
    assert_false(printed.contains("Raid Group"), "the dead tab is retired")
    assert_true(printed.contains("Facilities"))
    assert_true(printed.contains("Records"))
    assert_true(printed.contains("The record wall opens at Known."),
        "a disabled tab must never be a mystery: %s" % printed)
    assert_false(printed.contains("nothing to record"), "the false sentence is gone")

func test_an_empty_roster_reads_as_an_empty_state_not_a_blank_page() -> void:
    var root := _root()
    var host := Control.new()
    root.add_child(host)
    _made.append(host)
    var state = root.get_node_or_null("GameState")
    state.reset()
    state.set_content(_db)
    var view := RosterView.new()
    _made.append(view)
    host.add_child(view)
    view.build()
    var printed := _joined(view)
    assert_true(printed.contains("No raiders yet"),
        "an empty roster must explain itself")
    state.reset()
