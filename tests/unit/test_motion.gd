extends "res://tests/TestCase.gd"
## docs/13 §13's two motion rows, gated before there is anything to gate.
##
## `reduced_motion` had exactly ONE consumer for months — `SceneStage`, which
## stops its own flames — and there was not a single tween anywhere in the game,
## which is why the gap had cost nothing yet. Three M6 juice items are queued to
## add tweens to the screen change, the wipe sequence, the chalk slots and the
## stamp badges, and every one of them would have had to REMEMBER a setting
## nobody would have noticed them forgetting: an animation that ignores reduced
## motion looks exactly like one that respects it, unless you are the person the
## setting is for.
##
## So the rule is built first and enforced by a lint, and these are the tests
## that keep the rule honest:
##
##   * `motion_duration()` collapses to zero under reduced motion, so a call site
##     needs no branch — a 0.0 tween completes next frame and still applies its
##     final value, which is what makes "arrive instantly, and still arrive"
##     expressible at all (docs/13 §13: stamps still land, they carry state);
##   * the stamp's 60ms floor survives the collapse, because §13 names it;
##   * `Widgets.tween()` is the only door, and `tools/lint_motion.sh` is the lock.

const Settings = preload("res://game/core/GameSettings.gd")
const Widgets = preload("res://game/ui/Widgets.gd")

## docs/13 §12.2's motion table, the rows a tween will actually be written for.
const SCREEN_CHANGE_MS := 110
const STAMP_MS := 120
## docs/13 §13: "Stamps still land (they carry state) but at 60ms with no rotation"
const STAMP_FLOOR_MS := 60

var _s = null
var _made: Array = []


func before_each() -> void:
    _s = Settings.new()
    _made.append(_s)

func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []


# ---------------------------------------------------------- reduced motion

func test_motion_runs_at_full_length_by_default() -> void:
    assert_almost(_s.motion_scale(), 1.0)
    assert_almost(_s.motion_duration(SCREEN_CHANGE_MS), 0.110, 0.0001,
        "docs/13 §12.2's screen change, in the seconds a Tween wants")

func test_reduced_motion_collapses_a_duration_to_nothing() -> void:
    # Zero, not "skipped". The call site still tweens; Godot applies the final
    # value on the next frame. That is the difference between an accessibility
    # setting and a second code path nobody exercises.
    _s.set_value("reduced_motion", true)
    assert_almost(_s.motion_scale(), 0.0)
    assert_almost(_s.motion_duration(SCREEN_CHANGE_MS), 0.0, 0.0001)
    assert_almost(_s.motion_duration(900), 0.0, 0.0001, "the day advance too")

func test_the_stamp_keeps_its_floor_because_the_doc_names_it() -> void:
    # docs/13 §13's one carve-out: "Stamps still land (they carry state) but at
    # 60ms with no rotation." A stamp that vanished instantly would take the
    # state with it, which is the thing the row is protecting.
    _s.set_value("reduced_motion", true)
    assert_almost(_s.motion_duration(STAMP_MS, STAMP_FLOOR_MS), 0.060, 0.0001)

func test_the_floor_does_not_stretch_normal_motion() -> void:
    # A floor is a minimum, not an override: at full motion the stamp still takes
    # §12.2's own 120ms.
    assert_almost(_s.motion_duration(STAMP_MS, STAMP_FLOOR_MS), 0.120, 0.0001)

func test_a_zero_row_stays_zero_in_both_modes() -> void:
    # §12.2's morale chip: "**Instant.** No count-up". There is nothing for
    # reduced motion to reduce, and nothing that may creep back.
    assert_almost(_s.motion_duration(0), 0.0, 0.0001)
    _s.set_value("reduced_motion", true)
    assert_almost(_s.motion_duration(0), 0.0, 0.0001)

func test_a_negative_duration_is_not_an_error() -> void:
    assert_almost(_s.motion_duration(-50), 0.0, 0.0001)


# ------------------------------------------------------------- the one door

func test_the_sanctioned_tween_exists_and_refuses_a_loose_node() -> void:
    # A Tween bound to a node dies with it, so a screen's animation cannot
    # outlive the screen. A node outside the tree cannot bind one, and saying so
    # is better than handing back something that fails later.
    assert_eq(Widgets.tween(null), null)
    var loose := Control.new()
    _made.append(loose)
    assert_eq(Widgets.tween(loose), null, "a node outside the tree binds nothing")

func test_the_lint_that_keeps_it_the_only_door_is_wired() -> void:
    # The rule is a lint because it has to hold against code that is not written
    # yet. A lint nobody runs is the failure this whole item exists to prevent —
    # the same shape as the generator check that sat uncalled for months.
    var gate := FileAccess.get_file_as_string("res://tools/verify.sh")
    assert_true(gate.contains("lint_motion.sh"),
        "tools/verify.sh must run the motion lint")
    var lint := FileAccess.get_file_as_string("res://tools/lint_motion.sh")
    assert_true(lint.contains("MOTION LINT OK"), "and read its verdict line")
    assert_true(lint.contains("create_tween"), "and check for the thing it forbids")
    assert_true(lint.contains("game/ui/Widgets.gd"),
        "Widgets is the one place a tween may be made")
    # The same file grew a second rule, and for the same reason: docs/13 §13's
    # emoji-free option also had one consumer while seven screens read the raw
    # table past it. An accessibility option is only as live as its least careful
    # call site, so both go through one door and one lint watches both doors.
    assert_true(lint.contains("MORALE_BAND_EMOJI"),
        "the morale-glyph rule shares this lint")
    assert_true(lint.contains("game/ui/Cards.gd"),
        "Cards is the one place a morale glyph is chosen")


# --------------------------------------------------- docs/13 §13: flashing

func test_the_three_a_second_rule_is_the_docs_number() -> void:
    assert_almost(Settings.MAX_CHANGES_PER_SECOND, 3.0, 0.0001,
        "docs/13 §13: 'No element exceeds 3 changes per second'")

func test_the_rule_governs_the_ui_layer_under_either_reading() -> void:
    # Whatever the world layer turns out to be, the UI is covered. That half is
    # not ambiguous and nothing in docs/15 BL-75 touches it.
    assert_true(Settings.flash_rule_applies_to("ui"))

func test_the_shipped_reading_leaves_the_world_layer_to_doc_12() -> void:
    # docs/15 BL-75. docs/13 §12.2 closes with "ambient motion belongs to the
    # world layer and is doc 12's", which puts the flames outside §12's scope
    # before §13 speaks — and a fire cycling through near-identical frames is not
    # a "change" in the sense a photosensitivity rule means.
    assert_false(Settings.FLASH_RULE_COUNTS_WORLD_MOTION,
        "the shipped reading is UI-only")
    assert_false(Settings.flash_rule_applies_to("world"))

func test_the_literal_reading_would_cost_every_fire_in_the_game() -> void:
    # The other half of BL-75, held as a MEASUREMENT rather than an argument: if
    # "no element" really means no element, here is the bill. The switch is a
    # const so this reads the scene data directly rather than flipping it — the
    # point is the number, and the number is what a designer would be choosing.
    var over: Array = []
    for path in _scene_files():
        var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (doc is Dictionary):
            continue
        for key in ["props", "actors"]:
            for entry in ((doc as Dictionary).get(key, []) as Array):
                var fps := float((entry as Dictionary).get("fps", 0.0))
                if fps > Settings.MAX_CHANGES_PER_SECOND:
                    over.append("%s %s @ %.0f fps" % [path.get_file(), key, fps])
    assert_true(over.size() > 0,
        "if this is empty the world layer already obeys the literal reading and "
        + "BL-75 has stopped being a question")

func test_the_player_facing_escape_hatch_is_the_other_row_and_it_works() -> void:
    # Nothing in BL-75 weakens the accessibility guarantee: a player who needs
    # the motion stopped turns on reduced motion, and `SceneStage` halts the
    # world layer outright — flames, breathing lights, idles. This asserts the
    # consumer is still there, because it is the thing that makes the ruling safe.
    var stage := FileAccess.get_file_as_string("res://game/ui/SceneStage.gd")
    assert_true(stage.contains("func apply_settings(reduced_motion: bool"),
        "SceneStage must still consume the setting")
    assert_true(stage.contains("reduced_motion"),
        "and act on it, or BL-75's reasoning has no floor under it")


func _scene_files() -> Array:
    var out: Array = []
    var d := DirAccess.open("res://game/assets/scenes")
    if d == null:
        return out
    for f in d.get_files():
        if String(f).ends_with(".json"):
            out.append("res://game/assets/scenes/" + String(f))
    out.sort()
    return out
