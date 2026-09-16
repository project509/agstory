extends "res://tests/TestCase.gd"
## The actor layer — the people in a scene, and the promise that they move.
##
## `art/ref/specs/09-background-plates.md` §4.1 row 4 and §4.2 row 8 both used
## to read the same way: *ambient patrons / ambient raiders — **baked** in v1*,
## against a debt (`bg-hall-patrons`, `bg-camp-figures`). On 2026-09-11 the lead
## designer called that debt in by supplying BARE plates, in his words so that
## the graphics stop "keeping in things in the background like static rendered
## dialog and unanimated characters" and start being "beautifully
## sliced/animated assets and effects" rendered over and on top of them.
##
## So "a figure exists" is not the thing worth testing. The thing worth testing
## is that **no figure is a statue** (every strip has more than one frame and
## the frames differ), that the crowd is not one object with many heads (the
## phases are spread), that a figure is planted by its FEET so a taller pose
## grows upward instead of sinking, and that `reduced_motion` can still hold
## the whole room still — because `docs/13` §13 promises that and a new
## animated layer is exactly where that promise gets quietly broken.
##
## `SceneStage.from_data` exists for these tests: a three-actor test scene has
## no business shipping in `game/assets/scenes/`.

const SceneStage = preload("res://game/ui/SceneStage.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Icons = preload("res://game/ui/Icons.gd")

const MANIFEST := "res://game/assets/actors/actors.json"
const ACTORS := "res://game/assets/actors/"
const SCENES := "res://game/assets/scenes/"

var _built: Array = []


func after_each() -> void:
    for stage in _built:
        if is_instance_valid(stage):
            stage.free()
    _built.clear()
    after_each_mounted()


func _stage(d: Dictionary) -> Control:
    var stage := SceneStage.from_data("test_actors", d)
    _built.append(stage)
    return stage


func _manifest() -> Dictionary:
    var text := FileAccess.get_file_as_string(MANIFEST)
    var parsed = JSON.parse_string(text)
    return parsed.get("actors", {}) if parsed is Dictionary else {}


func _actor_nodes(stage: Control) -> Array:
    var out: Array = []
    for child in stage.get_children():
        if child is AnimatedSprite2D and String(child.name).begins_with("Actor_"):
            out.append(child)
    return out


## ---------------------------------------------------------------- the strips

func test_the_manifest_and_the_strips_agree() -> void:
    # A manifest that has drifted from the PNGs beside it is worse than no
    # manifest: SceneStage cuts frames at `frame_w` and would silently slice a
    # figure in half rather than fail.
    var actors := _manifest()
    assert_true(actors.size() >= 12, "expected the sliced sets at least, got %d" % actors.size())
    var bad: Array[String] = []
    for key in actors:
        var geom: Dictionary = actors[key]
        var path := ACTORS + String(key) + ".png"
        if not ResourceLoader.exists(path):
            bad.append("%s: no strip at %s" % [key, path])
            continue
        var tex: Texture2D = load(path)
        var want_w := int(geom.get("frames", 0)) * int(geom.get("frame_w", 0))
        if tex.get_width() != want_w:
            bad.append("%s: strip is %dpx wide, manifest says %d frames x %dpx" % [
                key, tex.get_width(), int(geom.get("frames", 0)), int(geom.get("frame_w", 0))])
        if tex.get_height() != int(geom.get("frame_h", 0)):
            bad.append("%s: strip is %dpx tall, manifest says %d" % [
                key, tex.get_height(), int(geom.get("frame_h", 0))])
    assert_eq(bad.size(), 0, "manifest and strips disagree:\n      " + "\n      ".join(bad))


func test_no_actor_is_a_statue() -> void:
    # The directive, as an assertion. `moving_px` is the generator's own
    # measurement of how many pixels differ across the cycle; a figure with one
    # frame, or five identical frames, is what this forbids.
    var actors := _manifest()
    var statues: Array[String] = []
    for key in actors:
        var geom: Dictionary = actors[key]
        if int(geom.get("frames", 0)) < 2 or int(geom.get("moving_px", 0)) <= 0:
            statues.append("%s (%d frames, %d moving px)" % [
                key, int(geom.get("frames", 0)), int(geom.get("moving_px", 0))])
        if float(geom.get("fps", 0.0)) <= 0.0:
            statues.append("%s has fps %s" % [key, geom.get("fps", 0.0)])
    assert_eq(statues.size(), 0, "these figures do not move:\n      " + "\n      ".join(statues))


func test_the_pixels_back_the_measurement_up() -> void:
    # `moving_px` is written by the generator, so one independent read of the
    # actual pixels keeps the manifest from being able to lie about the art.
    # Three strips, one of each provenance: a sliced cycle, a set with a
    # dropped mis-cut frame, and a synthesised breath.
    for key in ["cleric", "warrior", "variant_r01_black"]:
        var geom: Dictionary = _manifest().get(key, {})
        assert_true(not geom.is_empty(), "%s is missing from the manifest" % key)
        var tex: Texture2D = load(ACTORS + key + ".png")
        var img := tex.get_image()
        assert_true(img != null, "%s: no image to read" % key)
        var fw := int(geom.get("frame_w", 0))
        var moved := 0
        for y in img.get_height():
            for x in fw:
                if img.get_pixel(x, y) != img.get_pixel(fw + x, y):
                    moved += 1
        assert_true(moved > 0, "%s: frame 2 is identical to frame 1" % key)


## ---------------------------------------------------------------- the layer

func test_the_actor_layer_builds_from_the_manifest() -> void:
    var stage := _stage({"actors": [
        {"who": "cleric", "pos": [400, 700]},
        {"who": "mage", "pos": [460, 700]},
    ]})
    var nodes := _actor_nodes(stage)
    assert_eq(nodes.size(), 2, "expected two figures")
    var cleric: AnimatedSprite2D = nodes[0]
    var geom: Dictionary = _manifest().get("cleric", {})
    assert_eq(cleric.sprite_frames.get_frame_count("idle"), int(geom.get("frames", 0)),
        "the strip was cut into the wrong number of frames")
    assert_true(cleric.is_playing(), "a figure that is not playing is a statue")


func test_depth_is_tree_order_back_to_front() -> void:
    # Not z_index: the bubbles and the speaking plate are Controls added after
    # the actors, and a z_index above zero would lift a figure over them. The
    # figure standing LOWER on the plate (bigger y) is in front, so it is added
    # last. Authoring order must not matter.
    var stage := _stage({"actors": [
        {"who": "cleric", "pos": [100, 700]},
        {"who": "mage", "pos": [200, 300]},
        {"who": "rogue", "pos": [300, 500]},
    ]})
    var ys: Array[float] = []
    for node in _actor_nodes(stage):
        ys.append(node.position.y)
    assert_eq(ys, [300.0, 500.0, 700.0] as Array[float],
        "figures must be added back to front, whatever order the scene lists them in")


func test_a_figure_is_planted_by_its_feet() -> void:
    # `pos` is where the figure STANDS. The generator bottom-aligns every frame
    # in a strip for the same reason: a taller pose must grow upward, not sink
    # through the floor.
    var stage := _stage({"actors": [{"who": "cleric", "pos": [640, 690]}]})
    var node: AnimatedSprite2D = _actor_nodes(stage)[0]
    var geom: Dictionary = _manifest().get("cleric", {})
    assert_eq(node.position, Vector2(640, 690), "the figure is not where the scene put it")
    assert_almost(node.offset.y, -float(geom.get("frame_h", 0)) / 2.0, 0.01,
        "the sprite is centred on its feet instead of standing on them")


func test_scale_flip_and_tint_are_honoured() -> void:
    var stage := _stage({"actors": [
        {"who": "cleric", "pos": [10, 10], "scale": 2, "flip": true, "tint": "#88AACC"},
    ]})
    var node: AnimatedSprite2D = _actor_nodes(stage)[0]
    assert_eq(node.scale, Vector2(2, 2), "scale ignored")
    assert_true(node.flip_h, "flip ignored")
    assert_almost(node.modulate.r, Color("#88AACC").r, 0.001, "tint ignored")


func test_a_crowd_does_not_breathe_in_lockstep() -> void:
    # Four copies of one figure starting on frame 0 with the same speed reads as
    # one object with four heads. The phase spread is by position in the scene,
    # so it is deterministic: the same scene looks the same on every run.
    var many: Array = []
    for i in 4:
        many.append({"who": "variant_r01_black", "pos": [100 + i * 40, 600 + i]})
    var nodes := _actor_nodes(_stage({"actors": many}))
    assert_eq(nodes.size(), 4, "expected four figures")
    var frames := {}
    var speeds := {}
    for node in nodes:
        frames[node.frame] = true
        speeds[snappedf(node.speed_scale, 0.001)] = true
    assert_true(frames.size() > 1 or speeds.size() > 1,
        "every figure starts on the same frame at the same speed")


func test_an_unknown_figure_is_skipped_rather_than_fatal() -> void:
    # A scene naming a figure that does not exist is an authoring mistake, and
    # the screen it is on must still come up: SceneStage's whole contract is
    # that bad data degrades to a quieter scene, never to a broken one.
    var stage := _stage({"actors": [
        {"who": "nobody_by_that_name", "pos": [10, 10]},
        {"who": "cleric", "pos": [20, 20]},
    ]})
    assert_eq(_actor_nodes(stage).size(), 1, "the real figure should still be there")


func test_actors_with_no_entry_at_all_build_an_empty_stage() -> void:
    assert_eq(_actor_nodes(_stage({})).size(), 0, "a scene with no actors should have none")


## --------------------------------------------------------- docs/13 §13 again

func test_reduced_motion_holds_every_figure_still() -> void:
    # §13's reduced-motion row. Every new animated layer is a fresh chance to
    # break this promise, which is why it is asserted per layer and not once.
    var stage := _stage({"actors": [
        {"who": "cleric", "pos": [100, 700]},
        {"who": "mage", "pos": [200, 600]},
    ]})
    stage.apply_settings(true, false)
    for node in _actor_nodes(stage):
        assert_false(node.is_playing(), "%s is still animating under reduced motion" % node.name)
        assert_eq(node.frame, 0, "%s did not return to its first frame" % node.name)
    assert_false(stage.is_processing(), "the stage is still ticking under reduced motion")


func test_reduced_effects_drops_the_glow_and_the_embers() -> void:
    var stage := _stage({
        "actors": [{"who": "cleric", "pos": [100, 700]}],
        "embers": [{"pos": [100, 690], "amount": 8}],
    })
    stage.apply_settings(false, true)
    for child in stage.get_children():
        if child is WorldEnvironment:
            assert_false(child.environment.glow_enabled, "glow survived reduced effects")
        if child is GPUParticles2D:
            assert_false(child.emitting, "embers survived reduced effects")
    for node in _actor_nodes(stage):
        assert_true(node.is_playing(), "reduced EFFECTS must not stop the figures")


## ------------------------------------------------------------- the scene data

func test_every_shipped_scene_names_figures_that_exist() -> void:
    # The guard on authoring: a scene JSON is data, and a typo in it would
    # otherwise show up as a missing person on a screen nobody screenshots.
    var actors := _manifest()
    var dir := DirAccess.open(SCENES)
    assert_true(dir != null, "no scene directory at %s" % SCENES)
    var missing: Array[String] = []
    var checked := 0
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        if name.ends_with(".json"):
            checked += 1
            var parsed = JSON.parse_string(FileAccess.get_file_as_string(SCENES + name))
            if parsed is Dictionary:
                for a in parsed.get("actors", []):
                    if a is Dictionary and not actors.has(String(a.get("who", ""))):
                        missing.append("%s names '%s'" % [name, a.get("who", "")])
        name = dir.get_next()
    dir.list_dir_end()
    assert_true(checked > 0, "no scene data found to check")
    assert_eq(missing.size(), 0, "scenes name figures with no strip:\n      " + "\n      ".join(missing))


## ------------------------------------------------- which figure is which class

## docs/15 BL-68: the class -> figure mapping is decided by canon's EQUIPMENT
## FAMILIES, because a full figure shows what it is wearing, and it therefore
## disagrees with `tools/art/derive_busts.py`'s pairing, which is decided by
## headgear because a bust is a face and a hat. These tests hold the rule that
## was chosen, not the one that is easier to satisfy.

const CLASS_ACTORS := "res://game/assets/actors/class_actors.json"
const ContentDB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")

var _db = null


## One ContentDB for the file: `load_all()` is static and returns the instance.
func _content():
    if _db == null:
        _db = ContentDB.load_all()
    return _db


func _class_map() -> Dictionary:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(CLASS_ACTORS))
    return parsed if parsed is Dictionary else {}


func test_every_canon_class_has_a_figure() -> void:
    # Nine classes, nine rows, and every row names a strip that exists. A class
    # with no figure is a class that cannot be drawn on an arena floor.
    var db = _content()
    var rows: Dictionary = _class_map().get("classes", {})
    var actors := _manifest()
    var missing: Array[String] = []
    for c in db.classes:
        var key := String(c.key)
        if not rows.has(key):
            missing.append("%s has no row" % key)
            continue
        var actor := String((rows[key] as Dictionary).get("actor", ""))
        if not actors.has(actor):
            missing.append("%s names '%s', which is not a strip" % [key, actor])
    assert_true(db.classes.size() >= 9, "expected canon's nine classes")
    assert_eq(missing.size(), 0, "class -> figure gaps:\n      " + "\n      ".join(missing))


func test_no_two_classes_wear_the_same_figure() -> void:
    # Two classes sharing a strip would make them indistinguishable on the
    # arena floor, which is the whole reason the pose variants exist.
    var rows: Dictionary = _class_map().get("classes", {})
    var seen := {}
    var clashes: Array[String] = []
    for key in rows:
        var actor := String((rows[key] as Dictionary).get("actor", ""))
        if seen.has(actor):
            clashes.append("%s and %s both use '%s'" % [seen[actor], key, actor])
        seen[actor] = key
    assert_eq(clashes.size(), 0, "figures shared between classes:\n      " + "\n      ".join(clashes))


func test_classes_in_one_armour_family_share_one_reference_figure() -> void:
    # THE rule, asserted against data/classes.json rather than against a copy of
    # it: warrior and bard wear `warrior_bard_armor`, so both are the warrior
    # figure; monk wears the rogue's leather, not the warrior's plate; mage and
    # wizard share; cleric, druid and shaman share. Any exception has to be
    # DECLARED in the file, with its reason, or this fails.
    var db = _content()
    var doc := _class_map()
    var rows: Dictionary = doc.get("classes", {})
    var declared: Dictionary = doc.get("family_exceptions", {})
    var figure_of_family := {}
    var broken: Array[String] = []
    for c in db.classes:
        var key := String(c.key)
        if not rows.has(key):
            continue
        var row: Dictionary = rows[key]
        # `body_family` is an Enums.ItemFamily int; the JSON names it by key.
        var family := Enums.family_key(c.body_family)
        var figure := String(row.get("figure", ""))
        # The row must also agree with classes.json about which family it is in,
        # or the `why` beside it is arguing from the wrong premise.
        if String(row.get("family", "")) != family:
            broken.append("%s says family '%s', classes.json says '%s'" % [
                key, row.get("family", ""), family])
        if declared.has(key):
            continue
        if figure_of_family.has(family) and figure_of_family[family] != figure:
            broken.append("%s (%s) uses figure '%s'; %s already uses '%s'" % [
                key, family, figure, family, figure_of_family[family]])
        else:
            figure_of_family[family] = figure
    assert_eq(broken.size(), 0, "the armour-family rule is broken:\n      " + "\n      ".join(broken))


func test_the_declared_exception_says_why() -> void:
    # An exception list is only honest if each entry carries its reason: the
    # next reader has to be able to disagree with it on the merits.
    var doc := _class_map()
    var declared: Dictionary = doc.get("family_exceptions", {})
    assert_true(declared.size() >= 1, "healer_armor has three classes and two poses; expected that exception")
    for key in declared:
        assert_true(String(declared[key]).length() > 20,
            "the exception for %s has no reason written next to it" % key)


func test_unclaimed_figures_are_named_and_really_unclaimed() -> void:
    # Twelve sliced figures, nine classes. The leftovers are recorded so that
    # "there is no figure for a tenth class" is a fact in a file rather than a
    # thing somebody has to rediscover by counting PNGs.
    var doc := _class_map()
    var rows: Dictionary = doc.get("classes", {})
    var unclaimed: Dictionary = doc.get("unclaimed", {})
    var used := {}
    for key in rows:
        used[String((rows[key] as Dictionary).get("actor", ""))] = true
    var actors := _manifest()
    var wrong: Array[String] = []
    for key in unclaimed:
        if not actors.has(String(key)):
            wrong.append("%s is not a strip at all" % key)
        if used.has(String(key)):
            wrong.append("%s is listed unclaimed but a class uses it" % key)
        if String(unclaimed[key]).length() <= 20:
            wrong.append("%s has no reason written next to it" % key)
    # Every SLICED figure is either claimed or listed. The 44 townsfolk are
    # crowd art and are deliberately not part of this accounting.
    for key in actors:
        var geom: Dictionary = actors[key]
        if String(geom.get("kind", "")) != "sliced":
            continue
        if not used.has(String(key)) and not unclaimed.has(String(key)):
            wrong.append("%s is a sliced figure that is neither claimed nor listed" % key)
    assert_eq(wrong.size(), 0, "the unclaimed list is wrong:\n      " + "\n      ".join(wrong))


func test_actor_for_class_reads_the_file() -> void:
    # The accessor a screen actually calls, and its honest answer for a class
    # that does not exist.
    assert_eq(SceneStage.actor_for_class("mage"), "mage", "the mage should be the mage figure")
    assert_eq(SceneStage.actor_for_class("monk"), "rogue_b",
        "canon dresses the monk in the rogue's leather (monk_rogue_armor)")
    assert_eq(SceneStage.actor_for_class("bard"), "warrior_b",
        "canon dresses the bard in the warrior's armour (warrior_bard_armor)")
    assert_eq(SceneStage.actor_for_class("necromancer"), "",
        "a class canon does not have must answer with nothing, not with a default")


## -------------------------------------------------- a screen's own cast

## spec 09 §4.3 row 5 gives RaidView twelve combatant sprites, and a scene file
## cannot know which twelve departed — so the screen places them THROUGH the
## stage. These tests hold the two things that would otherwise quietly rot: the
## party gets the same treatment as any other crowd, and it obeys reduced motion
## even though it arrives after the stage is already in the tree.

func test_a_screen_can_place_its_own_cast() -> void:
    var stage := _stage({})
    var by_id: Dictionary = stage.place_party([
        {"who": "warrior", "pos": [700, 414], "id": "r1"},
        {"who": "mage", "pos": [700, 374], "id": "r2"},
    ])
    assert_eq(by_id.size(), 2, "expected a sprite per raider, keyed by id")
    assert_true(by_id.has("r1") and by_id.has("r2"), "the ids are how a screen updates them later")
    var nodes := _actor_nodes(stage)
    assert_eq(nodes.size(), 2, "the cast should be on the stage")
    # Same depth rule as a scene's own actors: back to front.
    assert_eq(nodes[0].position.y, 374.0, "the further figure is added first")
    assert_true(by_id["r1"].is_playing(), "a placed raider breathes like anyone else")


func test_a_placed_raider_gets_a_contact_shadow() -> void:
    # The party must not be the one crowd in the game that floats.
    var stage := _stage({})
    stage.place_party([{"who": "warrior", "pos": [700, 414], "id": "r1"}])
    var shadows := 0
    for child in stage.get_children():
        if child is Sprite2D and String(child.name).begins_with("Shadow_"):
            shadows += 1
    assert_eq(shadows, 1, "expected one contact shadow under the figure")


func test_a_class_with_no_figure_is_skipped_not_substituted() -> void:
    # `actor_for_class` answers "" for a class nobody mapped, and a screen that
    # substituted a default would be lying about the roster.
    var stage := _stage({})
    var by_id: Dictionary = stage.place_party([
        {"who": SceneStage.actor_for_class("necromancer"), "pos": [700, 414], "id": "ghost"},
        {"who": SceneStage.actor_for_class("cleric"), "pos": [760, 414], "id": "real"},
    ])
    assert_eq(by_id.size(), 1, "only the mapped class should be on the floor")
    assert_true(by_id.has("real"), "and it should be the real one")


func test_reduced_motion_holds_a_cast_placed_after_the_switch() -> void:
    # The order that bites: a stage enters the tree (so `_ready` applies the
    # settings) BEFORE the screen places its party. Without the stage
    # remembering, every raider would breathe under reduced motion.
    var stage := _stage({})
    stage.apply_settings(true, false)
    assert_true(stage.motion_held(), "the stage should remember it was told to hold still")
    var by_id: Dictionary = stage.place_party([{"who": "warrior", "pos": [700, 414], "id": "r1"}])
    var spr: AnimatedSprite2D = by_id["r1"]
    assert_false(spr.is_playing(), "a raider placed after the switch must still hold still")
    assert_eq(spr.frame, 0, "and sit on its first frame")


func test_the_floor_follows_the_panels_for_a_fallen_raider() -> void:
    # 10 §2 R4's rule, as the one function both the panel and the figure read.
    var alive := SceneStage.party_state_style("")
    var downed := SceneStage.party_state_style("Downed")
    var dead := SceneStage.party_state_style("dead")
    assert_false(bool(alive["still"]), "a living raider breathes")
    assert_eq(alive["tint"], Color.WHITE, "and is not greyed")
    assert_true(bool(downed["still"]), "a downed raider stops breathing")
    assert_true(bool(dead["still"]), "so does a dead one")
    assert_true(dead["tint"].r < downed["tint"].r,
        "dead reads darker than downed, so the two states are distinguishable")
    assert_true(bool(dead["rewind"]), "a dead figure returns to its first frame")


## ------------------------------------------------------------- the enemy

## spec 09 §4.3 row 4. The sliced creatures are single textures rather than
## strips (77px to 152px tall), so the boss gets a bob instead of frames, and
## its FEET have to be computed from its own height or the tallest creature
## ends up with its head behind its own HP bar.

const RaidViewScreen = preload("res://game/screens/RaidView.gd")
const ENEMIES := "res://game/assets/enemies/"


const ENEMIES_TABLE := ENEMIES + "enemies.json"


## The boss table, {rank: row} (W0-MANIFEST's shape, W3-ENEMIES' slots).
func _boss_table() -> Dictionary:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(ENEMIES_TABLE))
    return parsed.get("ranks", {}) if parsed is Dictionary else {}


## A rank's still with NO strip behind it: the same pixels as an ImageTexture
## from nowhere (no resource path, so `place_boss` cannot find a rank). This
## is what a creature the table does not know looks like to the stage — the
## single-texture fallback the bob exists for.
func _still_only(rank: String) -> Texture2D:
    var tex: Texture2D = load(ENEMIES + rank + ".png")
    return ImageTexture.create_from_image(tex.get_image())


## The height of the frame a boss is drawn from (a strip's frame, or the still).
func _boss_frame_h(boss: Node2D) -> float:
    if boss is AnimatedSprite2D:
        return float(boss.sprite_frames.get_frame_texture(boss.animation, 0).get_height())
    return float((boss as Sprite2D).texture.get_height())


func test_the_boss_stands_on_the_floor_with_a_shadow() -> void:
    var stage := _stage({})
    var tex: Texture2D = load(ENEMIES + "boss_main.png")
    var boss: Node2D = stage.place_boss(tex, Vector2(1190, 523))
    assert_true(boss != null, "expected a boss sprite")
    assert_eq(String(boss.name), "Boss", "the creature is named Boss")
    assert_eq(boss.position, Vector2(1190, 523), "the boss is not where the screen put it")
    assert_almost(boss.offset.y, -_boss_frame_h(boss) / 2.0, 0.01,
        "`pos` is where it STANDS, so the sprite lifts by half its frame's height")
    var shadows := 0
    for child in stage.get_children():
        if child is Sprite2D and String(child.name) == "BossShadow":
            shadows += 1
    assert_eq(shadows, 1, "a creature with no contact shadow floats")
    # The strip's frames keep the still's bottom-centre at their own, so the
    # feet of a still and of its strip land on the same point (gen_boss_anims).
    var still := _still_only("boss_main")
    var again := _stage({})
    var plain: Node2D = again.place_boss(still, Vector2(1190, 523))
    assert_true(plain is Sprite2D, "a texture the table does not know is the single-texture boss")
    assert_eq(plain.position, boss.position, "still and strip stand on the same feet point")


func test_a_missing_creature_is_not_fatal() -> void:
    # Not every encounter has art for its rank; an arena with no enemy on it is
    # a quieter screen, not a broken one.
    var stage := _stage({})
    assert_true(stage.place_boss(null, Vector2(1190, 523)) == null,
        "placing nothing should answer nothing")


func test_the_boss_breathes_and_reduced_motion_stops_it() -> void:
    # The single-texture fallback: a creature with no strip bobs (STAGE-08
    # keeps the bob for exactly this case).
    var stage := _stage({})
    var boss: Node2D = stage.place_boss(_still_only("boss_main"), Vector2(1190, 523))
    assert_true(boss is Sprite2D, "no strip, so a Sprite2D")
    var base: float = boss.position.y
    stage._process(0.7)
    assert_ne(boss.position.y, base, "a single-texture boss must at least bob")
    stage.apply_settings(true, false)
    assert_almost(boss.position.y, base, 0.01,
        "reduced motion must put it back on its feet, not freeze it mid-bob")
    stage._process(0.7)
    assert_almost(boss.position.y, base, 0.01, "and must keep it there")


## ------------------------------------------------- W3-ENEMIES: the boss moves

func test_a_boss_with_a_strip_has_idle_and_hit_tags() -> void:
    # STAGE-08: the rank's still resolves, through enemies.json, to the strip
    # gen_boss_anims.lua derived from it — an AnimatedSprite2D with the
    # docs/12 §5.2 tags, breathing on `idle`, with its eye layer as a child
    # over-driven past 1.0 so the glow catches it.
    var stage := _stage({})
    var row: Dictionary = _boss_table().get("boss_main", {})
    assert_true(row.has("strip") and row.has("tags"), "enemies.json names a strip and tags for boss_main")
    var mark: Dictionary = SceneStage.marks("stage_arena_cave").get("boss", {})
    var mark_scale := float(mark.get("scale", 1.0))
    assert_almost(mark_scale, 2.0, 0.001, "BL-103: the boss stands at 2x on the cave's mark (Q02 'upscale ok')")
    var boss: Node2D = stage.place_boss(load(ENEMIES + "boss_main.png"), Vector2(1190, 523),
        {"flip": true, "scale": mark_scale})
    assert_true(boss is AnimatedSprite2D, "a rank with a strip is an AnimatedSprite2D")
    if not (boss is AnimatedSprite2D):
        return
    var anim := boss as AnimatedSprite2D
    var frames: SpriteFrames = anim.sprite_frames
    for tag in ["idle", "hit", "death"]:
        assert_true(frames.has_animation(tag), "the strip carries a %s tag" % tag)
        assert_true(stage.boss_has_tag(boss, tag), "and the stage knows it has %s" % tag)
        var span: Array = row["tags"].get(tag, [])
        assert_eq(frames.get_frame_count(tag), int(span[1]) - int(span[0]) + 1,
            "%s has the table's frame count" % tag)
        assert_almost(frames.get_animation_speed(tag), float(span[2]), 0.01, "%s runs at the tag's fps" % tag)
    assert_true(frames.get_animation_loop("idle"), "idle loops")
    assert_false(frames.get_animation_loop("hit"), "a hit runs once")
    assert_false(frames.get_animation_loop("death"), "a death runs once and holds")
    assert_eq(String(anim.animation), "idle", "it starts on idle")
    assert_true(anim.is_playing(), "and breathes")
    assert_true(anim.flip_h, "the mark's flip is honoured")
    assert_eq(anim.scale, Vector2(mark_scale, mark_scale),
        "the integer upscale is the mark's (BL-103): one pixel pitch with the 2x party")
    var glow: AnimatedSprite2D = anim.get_node_or_null("BossGlow")
    assert_true(glow != null, "the emissive eye layer is a child named BossGlow")
    if glow != null:
        assert_true(glow.modulate.r > 1.3, "over-driven past the 1.3 glow threshold (STAGE-08: 1.4-1.8)")
        assert_true(glow.flip_h, "the eyes flip with the face")
        assert_eq(String(glow.animation), "idle", "the eyes show the body's animation")
        assert_eq(glow.offset, anim.offset, "and stand on the same feet")
        assert_true(glow.sprite_frames.has_animation("death"), "the eyes die with the body")
    assert_true(stage.get_node_or_null("BossShadow") != null, "the shadow is still a sibling named BossShadow")


func test_every_boss_strip_matches_its_table() -> void:
    # The manifest is only worth reading if the PNGs beside it agree with it:
    # `frames * frame_w` by `frame_h`, the glow on the same canvas, every tag
    # inside the strip, and a frame 1 that differs from frame 0 (the breath is
    # a real change of pixels, not a manifest claim).
    var table := _boss_table()
    assert_true(table.size() >= 6, "six ranks")
    var bad: Array[String] = []
    for rank in table:
        var row: Dictionary = table[rank]
        if not row.has("strip"):
            bad.append("%s has no strip" % rank)
            continue
        var n := int(row.get("frames", 0))
        var fw := int(row.get("frame_w", 0))
        var fh := int(row.get("frame_h", 0))
        # The frame is the still plus equal padding each side, so the still's
        # bottom-centre is the frame's: a still and its strip share their feet.
        var still: Texture2D = load(ENEMIES + String(rank) + ".png")
        if fw < still.get_width() or (fw - still.get_width()) % 2 != 0 or fh < still.get_height():
            bad.append("%s: frame %dx%d does not hold the %dx%d still centred on its feet" % [
                rank, fw, fh, still.get_width(), still.get_height()])
        for key in ["strip", "glow"]:
            var path := ENEMIES + String(row.get(key, ""))
            if not ResourceLoader.exists(path):
                bad.append("%s: no %s at %s" % [rank, key, path])
                continue
            var tex: Texture2D = load(path)
            if tex.get_width() != n * fw or tex.get_height() != fh:
                bad.append("%s: %s is %dx%d, the table says %d x %d by %d" % [
                    rank, key, tex.get_width(), tex.get_height(), n, fw, fh])
        var tags: Dictionary = row.get("tags", {})
        for tag in ["idle", "hit", "death"]:
            if not tags.has(tag):
                bad.append("%s has no %s tag" % [rank, tag])
                continue
            var span: Array = tags[tag]
            if span.size() < 3 or int(span[0]) < 0 or int(span[1]) >= n or int(span[1]) < int(span[0]) or float(span[2]) <= 0.0:
                bad.append("%s: tag %s = %s is not [first, last, fps] inside %d frames" % [rank, tag, span, n])
        if int(tags.get("idle", [0, 0])[1]) - int(tags.get("idle", [0, 0])[0]) + 1 < 4:
            bad.append("%s: idle is shorter than four frames" % rank)
        var img := _raw(ENEMIES + String(row["strip"]))
        var moved := 0
        var glow_img := _raw(ENEMIES + String(row["glow"]))
        var hot := 0
        for y in fh:
            for x in fw:
                if img.get_pixel(x, y) != img.get_pixel(fw + x, y):
                    moved += 1
                var g := glow_img.get_pixel(x, y)
                if g.a > 0.5 and maxf(g.r, maxf(g.g, g.b)) >= 207.0 / 255.0:
                    hot += 1
        if moved == 0:
            bad.append("%s: frame 1 of idle is frame 0 — a statue" % rank)
        if hot == 0:
            bad.append("%s: no eye pixel bright enough to bloom at x1.6 over the 1.3 threshold" % rank)
    assert_eq(bad.size(), 0, "boss strips and enemies.json disagree:\n      " + "\n      ".join(bad))


func test_a_strip_boss_hit_and_death_play_their_tags() -> void:
    var stage := _stage({})
    var boss: Node2D = stage.place_boss(load(ENEMIES + "boss_main.png"), Vector2(1200, 800))
    var anim := boss as AnimatedSprite2D
    var glow: AnimatedSprite2D = anim.get_node("BossGlow")
    var tint: Color = anim.modulate
    assert_true(stage.hit(boss, {"from": Vector2(600, 800)}), "a strip boss can be hit")
    assert_eq(String(anim.animation), "hit", "the hit is the strip's own frames")
    assert_eq(String(glow.animation), "hit", "the eyes follow")
    stage._process(0.02)
    assert_eq(anim.position, Vector2(1200, 800), "no procedural recoil on top of the baked one")
    assert_eq(anim.modulate, tint, "no modulate flash on top of the baked one")
    # The strip's hit returns to idle by itself when it finishes.
    anim.animation_finished.emit()
    assert_eq(String(anim.animation), "idle", "back to idle after the hit")
    assert_true(anim.is_playing(), "and breathing")
    assert_true(stage.act(boss, "death"), "a strip boss can die")
    assert_eq(String(anim.animation), "death", "the death is the strip's own frames")
    assert_false(anim.sprite_frames.get_animation_loop("death"), "held on its last frame, never looped")
    assert_eq(String(glow.animation), "death", "the eyes go out with it")
    assert_true(anim.modulate.r < 0.6, "greyed like a fallen raider (party_state_style dead)")
    assert_almost(anim.rotation, 0.0, 0.001, "no procedural topple: the strip leans by itself")
    anim.animation_finished.emit()
    assert_eq(String(anim.animation), "death", "a finished death stays dead")
    # Under reduced motion: the eyes and the body hold frame 0, a hit is the
    # flash only (the tag cannot play), a death ARRIVES on its last frame.
    var held := _stage({})
    held.apply_settings(true, false)
    var b2: AnimatedSprite2D = held.place_boss(load(ENEMIES + "boss_main.png"), Vector2(1200, 800))
    var g2: AnimatedSprite2D = b2.get_node("BossGlow")
    assert_false(b2.is_playing(), "held still")
    assert_eq(b2.frame, 0, "on frame 0")
    assert_eq(g2.frame, 0, "the eyes too")
    held.hit(b2)
    assert_eq(String(b2.animation), "idle", "no frames play under reduced motion")
    assert_eq(b2.modulate, SceneStage.FLASH_COLOR, "the flash is information and stays")
    held._process(0.02)
    assert_eq(b2.position, Vector2(1200, 800), "and the figure never leaves its mark")
    held.act(b2, "death")
    assert_eq(String(b2.animation), "death", "the death arrives")
    assert_eq(b2.frame, b2.sprite_frames.get_frame_count("death") - 1, "on its last frame, at once")
    assert_eq(g2.frame, b2.frame, "eyes included")
    assert_false(b2.is_playing(), "and holds")
    # A stage held AFTER the boss was placed holds it too.
    var late := _stage({})
    var b3: AnimatedSprite2D = late.place_boss(load(ENEMIES + "boss_main_2.png"), Vector2(1200, 800))
    assert_true(b3.is_playing(), "breathing before the switch")
    late.apply_settings(true, false)
    assert_false(b3.is_playing(), "held after it")
    assert_eq(b3.frame, 0, "on frame 0")


func test_reduced_effects_unlights_the_boss_eyes_and_keeps_it_breathing() -> void:
    var stage := _stage({})
    var boss: AnimatedSprite2D = stage.place_boss(load(ENEMIES + "boss_mini.png"), Vector2(1200, 800))
    var glow: AnimatedSprite2D = boss.get_node("BossGlow")
    assert_true(glow.modulate.r > 1.0, "lit before the switch")
    stage.apply_settings(false, true)
    assert_eq(glow.modulate, Color(1, 1, 1, 1), "with the glow off the over-drive would clip (CRITIC-G17): 1.0")
    assert_true(boss.is_playing(), "reduced EFFECTS must not stop the creature")
    var late := _stage({})
    late.apply_settings(false, true)
    var b2: AnimatedSprite2D = late.place_boss(load(ENEMIES + "boss_mini.png"), Vector2(1200, 800))
    assert_eq((b2.get_node("BossGlow") as AnimatedSprite2D).modulate, Color(1, 1, 1, 1),
        "a boss placed after the switch is unlit too")


func test_a_new_speaker_retires_the_previous_plate() -> void:
    # handoff-W2-RAIDVIEW's observation: three jokes inside one hold stacked
    # three plates over a 64px-pitch rank. The stage rule: one bubble at a
    # time — a new line drops whatever plate is up, whoever said it.
    var stage := _stage({})
    var by_id: Dictionary = stage.place_party([
        {"who": "warrior", "pos": [400, 700], "id": "r1"},
        {"who": "cleric", "pos": [464, 700], "id": "r2"},
    ])
    stage.say_at(by_id["r1"], "I meant to do that.", 2400)
    stage.say_at(by_id["r2"], "Nobody meant to do that.", 2400)
    var overlay: Control = stage.get_node("Overlay")
    var plates: Array[String] = []
    for child in overlay.get_children():
        if String(child.name).begins_with("Say_"):
            plates.append(String(child.name))
    assert_eq(plates.size(), 1, "one plate on the stage at a time, got %s" % [plates])
    assert_true(plates.size() == 1 and plates[0] == "Say_" + String((by_id["r2"] as Node).name),
        "and it is the newest speaker's")


## Two strip pixels differ when either has alpha and they are not the same.
func _differs(a: Color, b: Color) -> bool:
    return (a.a > 0.0 or b.a > 0.0) and a != b


## The PNG file itself, never the imported texture: the importer's
## process/fix_alpha_border rewrites the edge pixels (test_art_sources.gd's rule).
func _raw(path: String) -> Image:
    var img := Image.load_from_file(ProjectSettings.globalize_path(path))
    assert_true(img != null and not img.is_empty(), "%s did not decode" % path)
    return img


func test_every_townsfolk_breathes_in_four_frames() -> void:
    # STAGE-16: the 44 single-pose figures used to tick (2 frames, 2 fps); now
    # every entry loops >= 4 frames, a breath runs at the sliced sets' 5 fps,
    # its frame 1 differs from frame 0 above the waist ONLY (the feet are
    # planted) and its frame 3 is frame 0 again (docs/12 §5.2: ping-pong).
    var actors := _manifest()
    var bad: Array[String] = []
    var breaths := 0
    for key in actors:
        var geom: Dictionary = actors[key]
        if int(geom.get("frames", 0)) < 4:
            bad.append("%s loops %d frames" % [key, int(geom.get("frames", 0))])
        if String(geom.get("kind", "")) != "breath":
            continue
        breaths += 1
        if float(geom.get("fps", 0.0)) != 5.0 or int(geom.get("frames", 0)) != 4:
            bad.append("%s: a breath is 4 frames at 5 fps, got %s at %s" % [key, geom.get("frames"), geom.get("fps")])
            continue
        var img := _raw(ACTORS + String(key) + ".png")
        var fw := int(geom.get("frame_w", 0))
        var fh := int(geom.get("frame_h", 0))
        var above := 0
        var feet := 0
        var back := 0
        var floor_row := int(fh * 0.6)
        for y in fh:
            for x in fw:
                if _differs(img.get_pixel(x, y), img.get_pixel(fw + x, y)):
                    if y < floor_row:
                        above += 1
                    else:
                        feet += 1
                if _differs(img.get_pixel(x, y), img.get_pixel(3 * fw + x, y)):
                    back += 1
        if above == 0:
            bad.append("%s: frame 1 is frame 0 — a statue" % key)
        if feet > 0:
            bad.append("%s: %d pixels moved below the waist — the feet must stay planted" % [key, feet])
        if back > 0:
            bad.append("%s: frame 3 is not frame 0 — the loop does not close" % key)
    assert_true(breaths >= 44, "expected the 44 townsfolk, found %d breath entries" % breaths)
    assert_eq(bad.size(), 0, "the crowd does not breathe as designed:\n      " + "\n      ".join(bad))


## The two arena scenes and the screen chrome their marks have to clear. The
## blocking is DATA (STAGE-01: `marks` in the scene JSON, read through
## `SceneStage.marks`), so these tests iterate both arenas' marks rather than
## hard-coding one plate's rows the way the old boss test did.
const ARENAS := ["stage_arena_cave", "stage_arena_dungeon"]


func _view_y(m: Dictionary) -> float:
    var view = m.get("view", null)
    if view is Array and view.size() >= 2:
        return float(view[1])
    return RaidViewScreen.ARENA_OFFSET.y


## A screen rect (RaidView's chrome) in plate rows for a scene's view.
func _plate_rect(m: Dictionary, screen_rect: Rect2) -> Rect2:
    return Rect2(screen_rect.position - Vector2(0, _view_y(m)), screen_rect.size)


func test_every_creature_the_sheet_can_produce_clears_the_chrome_and_lands_on_its_mark() -> void:
    # The two hard constraints, for all six creatures and BOTH arenas rather than
    # for the one the current encounter happens to use:
    #   - the head clears the boss plate — chrome at screen y 53..118, i.e. plate
    #     y 333..398 under a (0,-280) view — with 6px of air;
    #   - the feet land inside the mark's `floor` rect, the stone measured for
    #     the boss to stand on, and the feet point is inside the view band.
    var dir := DirAccess.open(ENEMIES)
    assert_true(dir != null, "no enemy art directory")
    var bad: Array[String] = []
    var checked := 0
    for scene in ARENAS:
        var m := SceneStage.marks(scene)
        assert_true(m.has("boss"), "%s has no boss mark" % scene)
        var boss: Dictionary = m["boss"]
        var floor_rect: Array = boss.get("floor", [])
        assert_eq(floor_rect.size(), 4, "%s: boss.floor must be [x, y, w, h]" % scene)
        var sc := float(boss.get("scale", 1.0))
        var clear := RaidViewScreen.BOSS_PLATE.position.y + RaidViewScreen.BOSS_PLATE.size.y - _view_y(m)
        var band_top := -_view_y(m)
        var band_bottom := band_top + float(RaidViewScreen.STAGE_H)
        dir.list_dir_begin()
        var name := dir.get_next()
        while name != "":
            if name.ends_with(".png"):
                checked += 1
                var tex: Texture2D = load(ENEMIES + name)
                var h := tex.get_height()
                var feet: float = RaidViewScreen.boss_feet_y(h, scene)
                var head := feet - float(h) * sc
                if head < clear:
                    bad.append("%s/%s (%dpx x%.1f) puts its head at plate y %d, behind the boss plate (clearance %d)" % [
                        scene, name, h, sc, int(head), int(clear)])
                if feet < float(floor_rect[1]) or feet > float(floor_rect[1]) + float(floor_rect[3]):
                    bad.append("%s/%s (%dpx) stands at plate y %d, off its floor %s" % [
                        scene, name, h, int(feet), floor_rect])
                if feet < band_top or feet > band_bottom:
                    bad.append("%s/%s stands at plate y %d, outside the view band %d..%d" % [
                        scene, name, int(feet), int(band_top), int(band_bottom)])
            name = dir.get_next()
        dir.list_dir_end()
        var pos: Array = boss.get("pos", [])
        assert_eq(pos.size(), 2, "%s: boss.pos must be [x, y]" % scene)
        if pos.size() == 2 and (float(pos[0]) < float(floor_rect[0])
                or float(pos[0]) > float(floor_rect[0]) + float(floor_rect[2])):
            bad.append("%s: the boss's feet x %s is outside its floor %s" % [scene, pos[0], floor_rect])
    assert_true(checked >= 12, "expected the sliced boss sheet's six creatures per arena, found %d" % checked)
    assert_eq(bad.size(), 0, "boss placement breaks its own rules:\n      " + "\n      ".join(bad))


func test_marks_place_the_party_and_boss_in_band() -> void:
    # STAGE-01's acceptance as data: every feet point of the party, at the
    # mark's scale and the tallest class strip, stands inside the rows RaidView
    # shows, with its head clear of the OBJECTIVE block and the boss plate, and
    # its feet above the control row; the boss's floor lies in the band too.
    var tallest := 0
    var rows: Dictionary = _class_map().get("classes", {})
    var actors := _manifest()
    for key in rows:
        var actor := String((rows[key] as Dictionary).get("actor", ""))
        tallest = maxi(tallest, int((actors.get(actor, {}) as Dictionary).get("frame_h", 0)))
    assert_true(tallest >= 38, "no class strip height found")
    var bad: Array[String] = []
    for scene in ARENAS:
        var m := SceneStage.marks(scene)
        assert_true(m.has("party"), "%s has no party mark" % scene)
        var party: Dictionary = m["party"]
        var sc := float(party.get("scale", 1.0))
        assert_true(sc >= 2.0, "%s: STAGE-02 puts the party at 2x, got %s" % [scene, sc])
        var band_top := -_view_y(m)
        var band_bottom := band_top + float(RaidViewScreen.BAR_Y)
        var objective := _plate_rect(m, RaidViewScreen.OBJECTIVE)
        var plate := _plate_rect(m, RaidViewScreen.BOSS_PLATE)
        var slots := 0
        for rank in party.get("ranks", []):
            var y := float(rank.get("y", 0))
            for x in rank.get("xs", []):
                slots += 1
                var head := Vector2(float(x), y - float(tallest) * sc)
                if y < band_top or y > band_bottom:
                    bad.append("%s: feet (%s, %s) outside the band %d..%d" % [scene, x, y, int(band_top), int(band_bottom)])
                if head.y < band_top:
                    bad.append("%s: head of the figure at (%s, %s) rises above the band" % [scene, x, y])
                if objective.has_point(head) or plate.has_point(head):
                    bad.append("%s: head of the figure at (%s, %s) is under the chrome" % [scene, x, y])
        assert_eq(slots, 12, "%s: a raid is twelve, the marks hold %d slots" % [scene, slots])
        var floor_rect: Array = (m["boss"] as Dictionary).get("floor", [0, 0, 0, 0])
        if float(floor_rect[1]) < band_top or float(floor_rect[1]) + float(floor_rect[3]) > band_top + float(RaidViewScreen.STAGE_H):
            bad.append("%s: the boss floor %s leaves the band" % [scene, floor_rect])
    assert_eq(bad.size(), 0, "the marks put the fight where the player cannot see it:\n      " + "\n      ".join(bad))


## ------------------------------------------------- water and crystal light

## spec 09 §5 row 4 (water shimmer) and row 5 (crystal pulse), with that
## section's own numbers: two noise textures at UV/64 scrolled 0.02 and -0.013
## UV/s, added as about ±6 of 255 value; the pulse ±10% on a 3-second period.
## The numbers are the spec's, so the tests hold them as the spec's.

func test_the_water_layer_carries_the_specs_numbers() -> void:
    var stage := _stage({"shimmer": [{"rect": [10, 20, 300, 120]}]})
    var quad: ColorRect = null
    for child in stage.get_children():
        if child is ColorRect and String(child.name).begins_with("Shimmer_"):
            quad = child
    assert_true(quad != null, "expected a shimmer quad")
    assert_eq(quad.position, Vector2(10, 20), "the quad is not on its rect")
    assert_eq(quad.size, Vector2(300, 120), "the quad is not the size of its rect")
    var mat: ShaderMaterial = quad.material
    assert_true(mat != null, "the water is a shader, not a tint")
    assert_almost(float(mat.get_shader_parameter("strength")), 0.024, 0.0001,
        "09 §5 row 4 adds about ±6 of 255 value")
    assert_almost(float(mat.get_shader_parameter("tex_scale")), 64.0, 0.01,
        "09 §5 row 4 samples at UV/64")
    assert_eq(mat.get_shader_parameter("speed_a"), Vector2(0.02, -0.013),
        "09 §5 row 4's two scroll speeds")
    assert_almost(float(mat.get_shader_parameter("motion")), 1.0, 0.001,
        "water moves unless the player asked it not to")


func test_reduced_motion_stops_the_water_and_the_pulse() -> void:
    # The shimmer is TIME-driven INSIDE the shader, where `set_process(false)`
    # cannot reach it — so the switch has to travel as a uniform.
    var stage := _stage({
        "shimmer": [{"rect": [0, 0, 100, 100]}],
        "pulse": [{"rect": [0, 0, 60, 60], "energy": 0.2}],
    })
    var quad: ColorRect = null
    var pulse: ColorRect = null
    for child in stage.get_children():
        if child is ColorRect and String(child.name).begins_with("Shimmer_"):
            quad = child
        if child is ColorRect and String(child.name).begins_with("Pulse_"):
            pulse = child
    stage._process(1.1)
    assert_ne(pulse.color.a, 0.2, "the crystal light should be swinging")
    stage.apply_settings(true, false)
    assert_almost(float(quad.material.get_shader_parameter("motion")), 0.0, 0.001,
        "reduced motion must reach inside the shader")
    assert_almost(pulse.color.a, 0.2, 0.0001, "and put the pulse back on its base value")
    stage._process(1.1)
    assert_almost(pulse.color.a, 0.2, 0.0001, "and keep it there")


func test_reduced_effects_removes_them_entirely() -> void:
    # §13's other switch: these are ambience, not information, so they go.
    var stage := _stage({
        "shimmer": [{"rect": [0, 0, 100, 100]}],
        "pulse": [{"rect": [0, 0, 60, 60]}],
    })
    stage.apply_settings(false, true)
    for child in stage.get_children():
        if child is ColorRect and (String(child.name).begins_with("Shimmer_")
                or String(child.name).begins_with("Pulse_")):
            assert_false(child.visible, "%s survived reduced effects" % child.name)


func test_every_shipped_water_rect_is_on_its_plate() -> void:
    # A rect authored off the plate renders nothing and looks like a bug in the
    # shader rather than a typo in a file, which is the worst kind of quiet.
    var dir := DirAccess.open(SCENES)
    var bad: Array[String] = []
    var counted := 0
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        if name.ends_with(".json"):
            var parsed = JSON.parse_string(FileAccess.get_file_as_string(SCENES + name))
            if parsed is Dictionary:
                for key in ["shimmer", "pulse"]:
                    for cfg in parsed.get(key, []):
                        if not (cfg is Dictionary):
                            continue
                        var r: Array = cfg.get("rect", [])
                        counted += 1
                        if r.size() < 4:
                            bad.append("%s: %s rect is not [x, y, w, h]" % [name, key])
                            continue
                        if float(r[0]) < 0.0 or float(r[1]) < 0.0:
                            bad.append("%s: %s rect starts off the plate" % [name, key])
                        if float(r[0]) + float(r[2]) > 1536.0 or float(r[1]) + float(r[3]) > 1024.0:
                            bad.append("%s: %s rect %s runs past the plate" % [name, key, r])
        name = dir.get_next()
    dir.list_dir_end()
    assert_true(counted >= 10, "expected the authored water and crystal rects, found %d" % counted)
    assert_eq(bad.size(), 0, "water rects off the plate:\n      " + "\n      ".join(bad))


## ------------------------------------------------- W1-STAGE: scale, marks, feather

func _scene_json(name: String) -> Dictionary:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(SCENES + name + ".json"))
    return parsed if parsed is Dictionary else {}


func _shipped_scenes() -> Array[String]:
    var out: Array[String] = []
    var dir := DirAccess.open(SCENES)
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        if name.ends_with(".json"):
            out.append(name.trim_suffix(".json"))
        name = dir.get_next()
    dir.list_dir_end()
    return out


func _first_child(stage: Control, prefix: String) -> Node:
    for child in stage.get_children():
        if String(child.name).begins_with(prefix):
            return child
    return null


func test_figure_scale_is_honoured() -> void:
    # STAGE-02: the SCENE says what a figure is drawn at; an actor's own `scale`
    # still wins, and a party placed through the stage inherits the scene's.
    var stage := _stage({"figure_scale": 2, "actors": [
        {"who": "cleric", "pos": [100, 690]},
        {"who": "mage", "pos": [200, 700], "scale": 1},
    ]})
    var nodes := _actor_nodes(stage)
    assert_eq(nodes[0].scale, Vector2(2, 2), "the scene's figure_scale was not applied")
    assert_eq(nodes[1].scale, Vector2(1, 1), "an actor's own scale must override the scene's")
    var shadow: Sprite2D = _first_child(stage, "Shadow_cleric")
    assert_true(shadow != null and shadow.scale.x > 1.0, "the contact shadow must scale with the figure")
    var by_id: Dictionary = stage.place_party([{"who": "warrior", "pos": [300, 700], "id": "r1"}])
    assert_eq(by_id["r1"].scale, Vector2(2, 2), "a party placed through the stage inherits figure_scale")
    assert_almost(stage.figure_scale(), 2.0, 0.001, "figure_scale() reports the scene's value")
    assert_almost(_stage({}).figure_scale(), 1.0, 0.001, "a scene without the key is 1x")
    # The shipped rule (00-plan §0.6): camp and both arenas 2, tavern and market 1.
    for name in ["stage_camp", "stage_arena_cave", "stage_arena_dungeon"]:
        assert_almost(float(_scene_json(name).get("figure_scale", 1.0)), 2.0, 0.001, "%s should be 2x" % name)
    for name in ["stage_tavern", "stage_market"]:
        assert_almost(float(_scene_json(name).get("figure_scale", 1.0)), 1.0, 0.001, "%s should be 1x" % name)


func test_head_of_is_above_the_feet_by_frame_h_times_scale() -> void:
    var stage := _stage({"actors": [{"who": "cleric", "pos": [100, 700], "scale": 2}]})
    var node: AnimatedSprite2D = _actor_nodes(stage)[0]
    var geom: Dictionary = _manifest().get("cleric", {})
    var head: Vector2 = stage.head_of(node)
    assert_almost(head.x, 100.0, 0.01, "the head is over the feet")
    assert_almost(head.y, 700.0 - float(geom.get("frame_h", 0)) * 2.0, 0.01,
        "the head is one frame above the feet, at the figure's scale")
    var boss: Node2D = stage.place_boss(load(ENEMIES + "boss_main.png"), Vector2(1210, 800), {"scale": 1.0})
    var bh: Vector2 = stage.head_of(boss)
    assert_almost(bh.y, 800.0 - _boss_frame_h(boss), 0.01, "a boss's head is its frame height up")
    var plain: Node2D = stage.place_boss(_still_only("boss_main"), Vector2(1210, 800), {"scale": 1.0})
    assert_almost(stage.head_of(plain).y, 800.0 - float((plain as Sprite2D).texture.get_height()), 0.01,
        "a single-texture boss's head is its texture height up")
    assert_eq(stage.head_of(null), Vector2.ZERO, "nothing has no head")


func test_overlays_sit_above_the_figures_and_carry_labels() -> void:
    # STAGE-04 / CRITIC-C07: bars, numbers and in-fight speech are stage children
    # in an "Overlay" layer that stays above every figure — including one placed
    # AFTER the stage was built — and their words are Labels a screen test can read.
    var stage := _stage({"actors": [{"who": "cleric", "pos": [100, 700]}]})
    var by_id: Dictionary = stage.place_party([{"who": "warrior", "pos": [300, 700], "id": "r1"}])
    var spr: AnimatedSprite2D = by_id["r1"]
    var overlay: Control = stage.get_node("Overlay")
    assert_true(overlay != null, "expected an Overlay layer")
    assert_true(overlay.get_index() > spr.get_index(), "the overlay must draw over a figure placed after it")
    assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, "an overlay must not eat hotspot input")
    # say_at: the kit's plate, its tail's apex TAIL_AIR above the head and so its
    # bottom edge SAY_AIR (= TAIL_AIR + the tail's depth) above it, one per speaker.
    var plate: PanelContainer = stage.say_at(spr, "Has anyone seen my other boot?", 2400)
    assert_true(plate != null and plate.get_parent() == overlay, "the bubble lives in the overlay")
    var label: Label = null
    for child in plate.find_children("*", "Label", true, false):
        label = child
    assert_true(label != null and label.text == "Has anyone seen my other boot?", "the line is a Label")
    assert_almost(SceneStage.SAY_AIR, SceneStage.TAIL_AIR + float(Widgets.TAIL_H), 0.01,
        "SAY_AIR is the tail's air plus the tail's depth")
    assert_almost(plate.position.y + plate.size.y, stage.head_of(spr).y - SceneStage.SAY_AIR, 0.01,
        "the bubble's bottom edge is SAY_AIR above the head")
    var tail = plate.get_node_or_null("Tail")
    assert_true(tail != null, "an in-fight line has a tail (STAGE-10)")
    assert_almost((plate.position + tail.apex).distance_to(stage.head_of(spr)), SceneStage.TAIL_AIR, 0.01,
        "the tail's apex is TAIL_AIR above the head")
    stage.say_at(spr, "Second line.", 0)
    var plates := 0
    for child in overlay.get_children():
        if String(child.name).begins_with("Say_"):
            plates += 1
    assert_eq(plates, 1, "one bubble per speaker: the second line replaces the first")
    # The hold expires through the stage's own clock, not a tween.
    stage.say_at(spr, "Brief.", 500)
    stage._process(0.3)
    assert_true(is_instance_valid(stage.get_node_or_null("Overlay/Say_" + spr.name)), "still up at 0.3s")
    stage._process(0.3)
    assert_true(stage.get_node_or_null("Overlay/Say_" + spr.name) == null, "gone after its hold")
    # number_at: the caller's Label, centred over the head, staggered when stacked.
    var n1 := Label.new()
    n1.text = "-317"
    var n2 := Label.new()
    n2.text = "-42"
    stage.number_at(spr, n1)
    stage.number_at(spr, n2)
    assert_true(n1.get_parent() == overlay and n2.get_parent() == overlay, "numbers live in the overlay")
    assert_eq(n1.text, "-317", "the value is set once and never touched")
    assert_almost(n1.position.y - n2.position.y, n1.size.y + SceneStage.NUMBER_AIR, 0.01,
        "UI-34: a second number stacks a whole label higher, not a fixed 14px under a 35px glyph")
    assert_false(Rect2(n1.position, n1.size).intersects(Rect2(n2.position, n2.size)),
        "two numbers over one figure never overlap")
    assert_true(n1.position.y + n1.size.y <= stage.head_of(spr).y, "the number sits above the head")
    # bar_for: 96x23, badge + pips + a 62x7 bar when there is a maximum.
    var bar: Control = stage.bar_for(spr, 48.0, 128.0, null, {"pips": [Color.RED, Color.BLUE]})
    assert_eq(bar.size, Vector2(96, 23), "spec 02 §5.1's footprint")
    assert_true(bar.get_node_or_null("Badge") != null, "a badge slot, bare when no texture is given")
    assert_true(bar.get_node_or_null("Pip_1") != null and bar.get_node_or_null("Pip_2") == null, "two pips")
    var hp: Control = bar.get_node_or_null("HP")
    assert_true(hp != null and hp.size == Vector2(62, 7), "a 62x7 HP bar")
    assert_almost(bar.position.y + bar.size.y, stage.head_of(spr).y - 6.0, 0.01, "6px above the head")
    var bare: Control = stage.bar_for(spr, 0.0, 0.0, null)
    assert_true(bare.get_node_or_null("HP") == null, "no maximum, no bar — badge and pips only (CRITIC-C06)")
    var bars := 0
    for child in overlay.get_children():
        if String(child.name).begins_with("Bar_"):
            bars += 1
    assert_eq(bars, 1, "one bar per figure: the second call replaces the first")
    # Nothing in the overlay may take focus (a11y_smoke counts focusables).
    for child in overlay.find_children("*", "Control", true, false):
        assert_eq((child as Control).focus_mode, Control.FOCUS_NONE, "%s must not be focusable" % child.name)


func test_pulse_is_feathered() -> void:
    # STAGE-05: the quad keeps its `color.a` value pulse (the tests above read
    # it) and gains a ShaderMaterial that feathers its edges.
    var stage := _stage({"pulse": [{"rect": [0, 0, 60, 60], "energy": 0.2}]})
    var pulse: ColorRect = _first_child(stage, "Pulse_")
    assert_true(pulse != null, "expected a pulse quad")
    assert_true(pulse.material is ShaderMaterial, "the pulse must be a shader, not a bare additive rect")
    assert_true(float(pulse.material.get_shader_parameter("feather")) > 0.0, "feather must be positive")
    assert_almost(float(pulse.material.get_shader_parameter("feather")), 0.35, 0.001, "the default feather is 0.35")
    assert_almost(pulse.color.a, 0.2, 0.0001, "the base energy still lives in color.a")
    assert_true(pulse.material.shader.code.contains("feather"), "the shader reads the uniform")


func test_every_prop_frame_w_divides_its_strip() -> void:
    # STAGE-11: a strip cut at a width that does not divide it makes every
    # window after the first straddle two painted frames.
    var bad: Array[String] = []
    var counted := 0
    for name in _shipped_scenes():
        for p in _scene_json(name).get("props", []):
            if not (p is Dictionary):
                continue
            var strip := String(p.get("strip", ""))
            if not ResourceLoader.exists(strip):
                bad.append("%s: no strip at %s" % [name, strip])
                continue
            counted += 1
            var tex: Texture2D = load(strip)
            var fw := int(p.get("frame_w", 0))
            if fw <= 0 or tex.get_width() % fw != 0:
                bad.append("%s: %s is %dpx wide, cut at %d" % [name, strip.get_file(), tex.get_width(), fw])
    assert_true(counted > 0, "no props found in any scene")
    assert_eq(bad.size(), 0, "props cut off their frame grid:\n      " + "\n      ".join(bad))


func test_every_arena_pulse_and_emitter_is_in_the_view_band() -> void:
    # STAGE-06 / STAGE-21: an arena's animated cold light is worth nothing
    # authored above the rows the raid screens show or under the boss plate.
    var bad: Array[String] = []
    var counted := 0
    for scene in ARENAS:
        var d := _scene_json(scene)
        var m := SceneStage.marks(scene)
        var band := Rect2(0, -_view_y(m), 1536, float(RaidViewScreen.STAGE_H))
        var plate := _plate_rect(m, RaidViewScreen.BOSS_PLATE)
        for cfg in d.get("pulse", []):
            var r: Array = cfg.get("rect", [])
            if r.size() < 4:
                continue
            counted += 1
            var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
            if not band.encloses(rect):
                bad.append("%s: pulse %s leaves the band %s" % [scene, r, band])
            if rect.intersects(plate):
                bad.append("%s: pulse %s is under the boss plate %s" % [scene, r, plate])
        for em in d.get("embers", []):
            var pos: Array = em.get("pos", [])
            if pos.size() < 2:
                continue
            counted += 1
            var at := Vector2(float(pos[0]), float(pos[1]))
            if not band.has_point(at):
                bad.append("%s: ember emitter at %s is outside the band %s" % [scene, at, band])
            if plate.has_point(at):
                bad.append("%s: ember emitter at %s is under the boss plate" % [scene, at])
    assert_true(counted >= 4, "expected the arenas' pulses and emitters, found %d" % counted)
    assert_eq(bad.size(), 0, "arena light authored where the player cannot see it:\n      " + "\n      ".join(bad))


func test_ember_colour_is_data() -> void:
    # STAGE-19: the ramp was hard-coded to the campfire's; the cave's motes are
    # a preset and any entry may name its own birth colour.
    var stage := _stage({"embers": [
        {"pos": [10, 10], "amount": 4},
        {"pos": [20, 20], "amount": 4, "preset": "motes"},
        {"pos": [30, 30], "amount": 4, "color": "#00FF00", "emissive": 1.0},
    ]})
    var parts: Array = []
    for child in stage.get_children():
        if child is GPUParticles2D:
            parts.append(child)
    assert_eq(parts.size(), 3, "expected three emitters")
    var warm: Color = parts[0].process_material.color_ramp.gradient.get_color(0)
    var cool: Color = parts[1].process_material.color_ramp.gradient.get_color(0)
    var green: Color = parts[2].process_material.color_ramp.gradient.get_color(0)
    assert_true(warm.r > warm.b, "the campfire preset is warm")
    assert_true(cool.b > cool.r, "the motes preset is cool")
    assert_true(warm.r > 1.0 and cool.b > 1.0, "both are emissive at birth so they bloom")
    assert_true(green.g > green.r and green.g > green.b, "an entry's own colour wins")
    assert_true(parts[1].lifetime > parts[0].lifetime, "motes live longer than embers")
    assert_true(parts[1].process_material.scale_max < parts[0].process_material.scale_max, "and are smaller")


func test_reduced_motion_holds_lights_and_bubbles() -> void:
    # STAGE-20: `set_process(false)` is not the switch — another layer can turn
    # processing back on — so the flicker, the line rotation and the bubble
    # shuffle are gated on the held flag like the pulses and the boss.
    var stage := _stage({
        "lights": [{"pos": [10, 10], "energy": 0.4, "flicker": 0.5}, {"pos": [50, 10], "energy": 0.2}],
        "bubbles": [[0, 0], [40, 0], [80, 0], [120, 0], [160, 0]],
        "bubble_visible": 2,
        "speech": {"pos": [0, 0], "size": [174, 62], "backing": false, "lines": ["one", "two", "three"]},
    })
    stage.apply_settings(true, false)
    stage.set_process(true)
    var up_before: Array = []
    for child in stage.get_children():
        if child is TextureRect and child.visible and child != stage.get_node_or_null("Plate"):
            up_before.append(child.name)
    var label: Label = null
    for child in stage.find_children("*", "Label", true, false):
        if child.get_parent() != stage.get_node_or_null("Overlay"):
            label = child
    var line_before: String = label.text if label != null else ""
    var lights: Array = []
    for child in stage.get_children():
        if child is PointLight2D:
            lights.append(child)
    assert_eq(lights.size(), 2, "expected two lights")
    for i in 3:
        stage._process(1.0)
    assert_almost(lights[0].energy, 0.4, 0.0001, "a held light keeps its base energy")
    assert_almost(lights[1].energy, 0.2, 0.0001, "and so does the other")
    var up_after: Array = []
    for child in stage.get_children():
        if child is TextureRect and child.visible and child != stage.get_node_or_null("Plate"):
            up_after.append(child.name)
    assert_eq(up_after, up_before, "the bubbles that are up stay up under reduced motion")
    if label != null:
        assert_eq(label.text, line_before, "the speaking bubble keeps its line under reduced motion")
    # And the FIRST pick is the scene's, not the run's: two builds of one scene
    # show the same bubbles (W1-ICONS saw the camp's set differ between two
    # held shots — the global RNG chose it), and with motion on, the same
    # shuffles at the same ticks.
    var data := {"bubbles": [[0, 0], [40, 0], [80, 0], [120, 0], [160, 0], [200, 0], [240, 0]],
        "bubble_visible": 2}
    var runs: Array = []
    for _k in 2:
        var s := _stage(data)
        s.set_process(true)
        var seen: Array = []
        for tick in 4:
            var up: Array = []
            for child in s.get_children():
                if child is TextureRect and child.visible:
                    up.append(child.get_index())   # sibling Emotes are auto-renamed; the index is stable
            seen.append(up)
            s._process(3.0)
        runs.append(seen)
    assert_eq(runs[0], runs[1], "two runs of one scene must pick the same bubbles at the same ticks")
    var first: Array = runs[0]
    assert_eq((first[0] as Array).size(), 2, "bubble_visible of them are up")
    assert_true(first[0] != first[1] or first[1] != first[2], "and the set does change with motion on")


func test_vignette_hides_under_reduced_effects() -> void:
    # STAGE-07's shipped half (CRITIC-C17): the 8% edge darken is an effect —
    # present, mouse-transparent, and gone under `reduced_effects` along with the
    # flame props' over-drive (CRITIC-G17).
    var stage := _stage({"props": [
        {"strip": "res://game/assets/vfx/fire_torch.png", "frame_w": 16, "fps": 8, "pos": [10, 30], "emissive": 1.2},
    ]})
    var vig: ColorRect = stage.get_node_or_null("Vignette")
    assert_true(vig != null, "expected a Vignette layer")
    assert_true(vig.material is ShaderMaterial, "the vignette is a canvas shader")
    assert_almost(float(vig.material.get_shader_parameter("strength")), 0.08, 0.001, "8% edge darken")
    assert_eq(vig.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a full-stage rect must not eat hotspot input")
    assert_true(vig.visible, "on by default")
    assert_true(vig.get_index() < stage.get_node("Overlay").get_index(), "under the overlays, over the world")
    var prop: AnimatedSprite2D = null
    for child in stage.get_children():
        if child is AnimatedSprite2D and not String(child.name).begins_with("Actor_"):
            prop = child
    assert_true(prop != null and prop.modulate.r > 1.0, "a flame prop is over-driven for the glow")
    stage.apply_settings(false, true)
    assert_false(vig.visible, "the vignette must hide under reduced effects")
    assert_almost(prop.modulate.r, 1.0, 0.001, "with the glow off the flame returns to modulate 1.0")
    assert_true(prop.is_playing(), "reduced EFFECTS still lets the flame burn")
    # Reduced motion alone leaves it on: it is not motion.
    var other := _stage({})
    other.apply_settings(true, false)
    assert_true((other.get_node("Vignette") as ColorRect).visible, "reduced motion does not touch the vignette")
    # It covers the rows the SCREEN shows, not the whole plate: RaidView offsets
    # the stage by (0,-280) and sizes it to (1536, 1015), so the visible band is
    # plate rows 280..1015 and the vignette's top edge must be there.
    other.position = Vector2(0, -280)
    other.size = Vector2(1536, 1015)
    other._fit_vignette()
    var fitted: ColorRect = other.get_node("Vignette")
    assert_eq(fitted.position, Vector2(0, 280), "the vignette starts where the visible band starts")
    assert_eq(fitted.size, Vector2(1536, 735), "and ends at the stage's far edge")


func test_speech_anchors_to_its_speaker() -> void:
    # TOWN-03's anchor half: `speech.speaker` is an index into the JSON's actors
    # (authoring order); the speaking bubble's bottom-centre then hangs 28px
    # above that figure's head, wherever the screen offsets the plate. Without
    # a speaker `pos` still rules. The camp names one, so its line has a mouth.
    var stage := _stage({"actors": [
        {"who": "cleric", "pos": [100, 700]},
        {"who": "mage", "pos": [400, 500], "scale": 2},
    ], "speech": {"pos": [10, 10], "size": [182, 76], "backing": false, "speaker": 1,
        "lines": ["I think I'm ready for a real raid this time!"]}})
    var speaker: AnimatedSprite2D = null
    for node in _actor_nodes(stage):
        if String(node.name).begins_with("Actor_mage"):
            speaker = node
    assert_true(speaker != null, "the speaker built")
    var plate: PanelContainer = null
    for child in stage.get_children():
        if child is PanelContainer:
            plate = child
    assert_true(plate != null, "the speaking bubble built")
    var head: Vector2 = stage.head_of(speaker)
    assert_almost(plate.position.x + plate.size.x / 2.0, head.x, 0.01, "bottom-centre over the speaker's x")
    assert_almost(plate.position.y + plate.size.y, head.y - SceneStage.SAY_AIR, 0.01,
        "SAY_AIR above the speaker's head")
    stage.set_lines(["Nobody said there would be fire."])
    plate = _speech_plate(stage)
    assert_almost(plate.position.y + plate.size.y, head.y - SceneStage.SAY_AIR, 0.01, "a new line keeps the anchor")
    var loose := _stage({"actors": [{"who": "cleric", "pos": [100, 700]}],
        "speech": {"pos": [10, 10], "size": [182, 76], "lines": ["Hm."]}})
    var loose_plate: PanelContainer = _speech_plate(loose)
    assert_eq(loose_plate.position, Vector2(10, 10), "no speaker: the authored pos rules")
    assert_true(loose_plate.get_node_or_null("Tail") == null, "and no tail points at nobody")
    for name in ["stage_camp", "stage_tavern", "stage_market"]:
        var d := _scene_json(name)
        var sp: Dictionary = d.get("speech", {})
        assert_true(sp.has("speaker"), "%s's line names its speaker(s)" % name)
        var n := (d.get("actors", []) as Array).size()
        for who in SceneStage._as_list(sp.get("speaker", null)):
            assert_true(int(who) >= 0 and int(who) < n, "%s: speaker %s is an actor index" % [name, who])


## The scene's speaking plate: the one PanelContainer that is a direct child of
## the stage (the in-fight `say_at` plates live in the Overlay).
func _speech_plate(stage: Control) -> PanelContainer:
    for child in stage.get_children():
        if child is PanelContainer:
            return child
    return null


func test_every_ambient_bubble_hangs_over_a_head() -> void:
    # STAGE-02's acceptance for the "..." bubbles, against the REAL emote frame
    # (the kit's PanelEmote, 40x44 with the tail at the bottom — it grew from
    # 33x32 in this wave, which had put every bubble's tail on a face): in each
    # shipped scene that has figures, a bubble's bottom edge is 4-10px above
    # the head of the figure it hangs over, and that head is under the frame.
    var manifest := _manifest()
    var bad: Array[String] = []
    var counted := 0
    for name in _shipped_scenes():
        var d := _scene_json(name)
        var actors: Array = d.get("actors", []) if d.get("actors", []) is Array else []
        var bubbles: Array = d.get("bubbles", []) if d.get("bubbles", []) is Array else []
        if actors.is_empty() or bubbles.is_empty():
            continue
        var stage := SceneStage.from_data(name, d)
        _built.append(stage)
        var fs := float(d.get("figure_scale", 1.0))
        var heads: Array = []
        for a in actors:
            var geom: Dictionary = manifest.get(String(a.get("who", "")), {})
            var pos: Array = a.get("pos", [0, 0])
            var sc := float(a.get("scale", fs))
            heads.append(Vector2(float(pos[0]), float(pos[1]) - float(geom.get("frame_h", 0)) * sc))
        for child in stage.get_children():
            # Sibling Emotes get engine-unique names; the kit's `emote` meta says what it is.
            if not (child is TextureRect) or not child.has_meta("emote"):
                continue
            counted += 1
            # Outside a tree a Control's `size` is not laid out yet; the frame's own size is the minimum.
            var fsz: Vector2 = child.size.max(child.get_combined_minimum_size())
            var bottom := Vector2(child.position.x + fsz.x / 2.0, child.position.y + fsz.y)
            var head: Vector2 = heads[0]
            for h in heads:
                if bottom.distance_to(h) < bottom.distance_to(head):
                    head = h
            var gap := head.y - bottom.y
            if gap < 4.0 or gap > 10.0:
                bad.append("%s: bubble at %s ends %dpx above the head at %s (want 4..10)" % [name, child.position, int(gap), head])
            if head.x < child.position.x or head.x > child.position.x + fsz.x:
                bad.append("%s: bubble at %s does not span the head at %s" % [name, child.position, head])
    assert_true(counted >= 10, "expected the camp, tavern and market bubbles, found %d" % counted)
    assert_eq(bad.size(), 0, "ambient bubbles off their heads:\n      " + "\n      ".join(bad))


## ------------------------------------------------- W2-STAGE2: the verbs

## STAGE-03 / STAGE-09. The verbs are world-layer motion driven from the
## stage's own clock (`_process`), the way the boss bob and the held speech
## are: nothing here is inside a tree (run_tests.gd runs from `_initialize`),
## so `Widgets.tween` would answer null and a Tween could never be stepped —
## the clock is what makes "recoils AND returns" an assertion rather than a
## hope. Beats collapse to their floors under reduced motion through the same
## arithmetic `GameSettings.motion_duration` uses, read from the stage's own
## switch (`apply_settings`, RULES §2's world-layer door).

func _lone(stage: Control) -> AnimatedSprite2D:
    var by_id: Dictionary = stage.place_party([{"who": "warrior", "pos": [400, 700], "id": "r1"}])
    return by_id["r1"]


func test_hit_recoils_and_returns() -> void:
    var stage := _stage({})
    var spr := _lone(stage)
    var base: Vector2 = spr.position
    var tint: Color = spr.modulate
    assert_true(stage.hit(spr), "a figure on the floor can be hit")
    stage._process(0.02)
    assert_true(spr.position.x < base.x, "the strips face right, so with no attacker named the recoil steps BACK (-x)")
    assert_true(absf(spr.position.x - base.x) <= 2.0 + 0.001, "docs/12 §5.2: a 2px recoil, no more")
    assert_eq(spr.modulate, SceneStage.FLASH_COLOR, "and the one-beat flash is on")
    stage._process(0.5)
    assert_eq(spr.position, base, "the figure returns to its mark")
    assert_eq(spr.modulate, tint, "and its colour")
    # The attacker's side decides the direction: struck from the left, it goes right.
    stage.hit(spr, {"from": Vector2(100, 700)})
    stage._process(0.02)
    assert_true(spr.position.x > base.x, "struck from the left, the recoil is to the right")
    stage._process(0.5)
    assert_eq(spr.position, base, "and it returns again")


func test_reduced_motion_makes_hit_a_flash_only() -> void:
    var stage := _stage({})
    var spr := _lone(stage)
    stage.apply_settings(true, false)
    var base: Vector2 = spr.position
    stage.hit(spr)
    assert_eq(spr.modulate, SceneStage.FLASH_COLOR, "the flash is information and stays")
    for i in 6:
        stage._process(0.01)
        assert_eq(spr.position, base, "under reduced motion the figure never leaves its mark")
    stage._process(0.2)
    assert_ne(spr.modulate, SceneStage.FLASH_COLOR, "the flash still ends on the clock")
    assert_eq(spr.position, base, "position unchanged throughout")


func test_burst_is_one_shot_and_frees_itself() -> void:
    var stage := _stage({})
    var node: Node2D = stage.burst(Vector2(500, 600), "impact")
    assert_true(node != null, "a burst makes something")
    var particles: GPUParticles2D = null
    var strip: AnimatedSprite2D = null
    for child in stage.get_children():
        if child is GPUParticles2D and String(child.name).begins_with("Burst_"):
            particles = child
        if child is AnimatedSprite2D and String(child.name).begins_with("Fx_fx_burst_impact"):
            strip = child
    assert_true(particles != null, "STAGE-03: a burst is a GPUParticles2D")
    assert_true(particles.one_shot, "one shot")
    assert_true(particles.emitting, "emitting now")
    assert_almost(particles.explosiveness, 0.9, 0.001, "explosiveness 0.9")
    assert_almost(particles.lifetime, float(Widgets.Motion.BURST) / 1000.0, 0.001, "the kit's BURST ms")
    assert_true(strip != null, "and the impact kind plays W1-VFX's fx_burst_impact strip over it")
    assert_true(strip.material is CanvasItemMaterial and strip.material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD,
        "the strip glows (additive)")
    assert_false(strip.sprite_frames.get_animation_loop("play"), "a one-shot strip does not loop")
    assert_eq(strip.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "pixel art stays crisp")
    assert_true(strip.get_index() < stage.get_node("Overlay").get_index(), "effects draw under the overlays")
    stage._process(0.2)
    assert_true(is_instance_valid(particles) and particles.get_parent() == stage, "still up at 0.2s")
    stage._process(0.5)
    var left := 0
    for child in stage.get_children():
        if child is GPUParticles2D or (child is AnimatedSprite2D and String(child.name).begins_with("Fx_")):
            left += 1
    assert_eq(left, 0, "a burst frees itself when its lifetime is over")


func test_reduced_motion_holds_a_burst_as_one_frame_and_reduced_effects_drops_it() -> void:
    # STAGE-03 / PIPE-02: under reduced motion the strike still LANDS — the
    # strip's last frame, held — but nothing moves; under reduced effects there
    # is no VFX at all.
    var held := _stage({})
    held.apply_settings(true, false)
    var node: Node2D = held.burst(Vector2(500, 600), "impact")
    assert_true(node is AnimatedSprite2D, "the held burst is the strip, not particles")
    var count := 0
    for child in held.get_children():
        if child is GPUParticles2D:
            count += 1
    assert_eq(count, 0, "particles are motion: none under reduced motion")
    var spr: AnimatedSprite2D = node
    assert_false(spr.is_playing(), "the strip does not play")
    assert_eq(spr.frame, spr.sprite_frames.get_frame_count("play") - 1, "it holds its LAST frame")
    held._process(0.1)
    assert_true(is_instance_valid(spr) and spr.get_parent() == held, "held for FX_HOLD")
    held._process(SceneStage.FX_HOLD)
    assert_true(spr.get_parent() == null or not is_instance_valid(spr), "then gone")
    var quiet := _stage({})
    quiet.apply_settings(false, true)
    assert_true(quiet.burst(Vector2(500, 600), "impact") == null, "reduced effects: no burst")
    assert_true(quiet.slash(Vector2(500, 600)) == null, "no slash")
    assert_true(quiet.bolt(Vector2(100, 600), Vector2(500, 600)) == null, "no bolt")
    assert_true(quiet.add_fx("fx_spark_hit", 0, 0.0, Vector2(500, 600)) == null, "no strip at all")


func test_add_fx_reads_the_manifest_and_frees_on_its_clock() -> void:
    var stage := _stage({})
    var spr: AnimatedSprite2D = stage.add_fx("fx_slash_arc", 0, 0.0, Vector2(300, 300), {"additive": true})
    assert_true(spr != null, "a manifest key resolves to its strip")
    assert_eq(spr.sprite_frames.get_frame_count("play"), 5, "vfx.json: fx_slash_arc is 5 frames")
    assert_almost(spr.sprite_frames.get_animation_speed("play"), 15.0, 0.01, "at the manifest's 15 fps")
    assert_true(spr.is_playing(), "playing")
    assert_eq(spr.position, Vector2(300, 300), "where it was asked for")
    var by_path: AnimatedSprite2D = stage.add_fx("res://game/assets/vfx/fx_spark_hit.png", 32, 16.0, Vector2(1, 1))
    assert_true(by_path != null and by_path.sprite_frames.get_frame_count("play") == 4, "a res:// path with explicit geometry works too")
    assert_true(stage.add_fx("no_such_strip", 0, 0.0, Vector2.ZERO) == null, "an unknown strip is a warning, not a crash")
    stage._process(5.0 / 15.0 + 0.1)
    assert_true(spr.get_parent() == null or not is_instance_valid(spr),
        "outside a tree a strip never finishes its animation, so the clock frees it after frames/fps")
    var looped: AnimatedSprite2D = stage.add_fx("fx_bolt_arcane", 0, 0.0, Vector2.ZERO, {"once": false})
    assert_true(looped.sprite_frames.get_animation_loop("play"), "once=false loops")
    stage._process(10.0)
    assert_true(is_instance_valid(looped) and looped.get_parent() == stage, "and a looping strip is the caller's to free")


func test_bolt_travels_then_lands_a_burst() -> void:
    var stage := _stage({})
    var spr: AnimatedSprite2D = stage.bolt(Vector2(100, 600), Vector2(500, 600), "arcane")
    assert_true(spr != null, "a bolt is made")
    assert_eq(spr.position, Vector2(100, 600), "it starts at `from`")
    assert_almost(spr.rotation, PI / 2.0, 0.001, "the strip is drawn nose-up, so a bolt going +x turns 90°")
    var trails := 0
    for child in stage.get_children():
        if child is Sprite2D and String(child.name).begins_with("Trail_"):
            trails += 1
    assert_eq(trails, SceneStage.BOLT_TRAIL, "three ghosts behind it")
    stage._process(0.09)
    assert_true(spr.position.x > 100.0 and spr.position.x < 500.0, "half way at half the travel")
    stage._process(0.2)
    assert_true(spr.get_parent() == null or not is_instance_valid(spr), "the bolt is gone when it lands")
    var bursts := 0
    trails = 0
    for child in stage.get_children():
        if child is GPUParticles2D and String(child.name).begins_with("Burst_arcane"):
            bursts += 1
            assert_eq(child.position, Vector2(500, 600), "the burst is at `to`")
        if child is Sprite2D and String(child.name).begins_with("Trail_"):
            trails += 1
    assert_eq(bursts, 1, "and it lands a burst of its kind")
    assert_eq(trails, 0, "the ghosts go with it")
    # Under reduced motion the travel is zero-length: the burst's held frame is what lands.
    var held := _stage({})
    held.apply_settings(true, false)
    held.bolt(Vector2(100, 600), Vector2(500, 600), "arcane")
    var moving := 0
    for child in held.get_children():
        if child is AnimatedSprite2D and String(child.name).begins_with("Fx_fx_bolt"):
            moving += 1
    assert_eq(moving, 0, "no bolt is ever seen moving under reduced motion")


func test_a_fumble_holds_still_under_reduced_motion() -> void:
    # STAGE-09: the "!" is the joke, so it shows; the ±12° is a flourish, so it
    # is multiplied by the motion scale — 0 — and the figure never tilts.
    var stage := _stage({})
    var spr := _lone(stage)
    stage.apply_settings(true, false)
    var base: Vector2 = spr.position
    assert_true(stage.act(spr, "fumble"), "fumble is a verb")
    var mark: Label = stage.get_node_or_null("Overlay/Mark_" + spr.name)
    assert_true(mark != null and mark.text == "!", "a '!' Label over the head (never a baked glyph)")
    assert_eq(mark.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the mark ignores the mouse")
    assert_true(mark.position.y + mark.size.y <= stage.head_of(spr).y - SceneStage.BAR_AIR + 0.01, "6px above the head")
    for i in 5:
        stage._process(0.03)
        assert_almost(spr.rotation, 0.0, 0.0001, "rotation stays 0 under reduced motion")
        assert_eq(spr.position, base, "and the lunge is zero-length")
        assert_true(is_instance_valid(mark) and mark.get_parent() != null, "the '!' holds through the freeze floor")
    stage._process(0.3)
    assert_true(stage.get_node_or_null("Overlay/Mark_" + spr.name) == null, "and goes when the beat is over")
    assert_almost(spr.rotation, 0.0, 0.0001, "upright at the end")


func test_a_fumble_tilts_and_recovers_with_motion_on() -> void:
    var stage := _stage({})
    var spr := _lone(stage)
    var base: Vector2 = spr.position
    stage.act(spr, "fumble")
    stage._process(0.1)
    assert_true(spr.position.x != base.x, "the commit lunge moves the figure")
    stage._process(0.12 + 0.2 + 0.08)
    assert_true(absf(spr.rotation) > 0.05, "then it tilts")
    assert_true(absf(spr.rotation) <= deg_to_rad(12.0) + 0.001, "by no more than 12°")
    assert_true(stage.get_node_or_null("Overlay/Mark_" + spr.name) != null, "with the '!' up")
    stage._process(1.0)
    assert_almost(spr.rotation, 0.0, 0.0001, "recovered upright")
    assert_eq(spr.position, base, "back on its mark")
    assert_true(stage.get_node_or_null("Overlay/Mark_" + spr.name) == null, "mark gone")


func test_attack_and_cast_return_and_death_stays() -> void:
    var stage := _stage({})
    var spr := _lone(stage)
    var base: Vector2 = spr.position
    var tint: Color = spr.modulate
    stage.act(spr, "attack", {"toward": Vector2(800, 700)})
    stage._process(0.09)
    assert_true(spr.position.x > base.x, "the lunge is toward the target")
    assert_true(spr.position.x - base.x <= 6.0 + 0.001, "6px at most")
    stage._process(0.5)
    assert_eq(spr.position, base, "and back")
    stage.act(spr, "cast")
    stage._process(0.15)
    assert_true(spr.position.y < base.y, "a cast rises")
    assert_true(spr.modulate.b > 1.0, "with an emissive lift")
    stage._process(0.5)
    assert_eq(spr.position, base, "then settles")
    assert_eq(spr.modulate, tint, "in its own colour")
    stage.act(spr, "death")
    stage._process(1.0)
    assert_almost(absf(spr.rotation), deg_to_rad(45.0), 0.001, "a dead figure lies at 45°")
    assert_true(spr.modulate.r < 0.6, "greyed (party_state_style dead)")
    assert_false(spr.is_playing(), "and still")
    var again := _stage({})
    var s2 := _lone(again)
    again.apply_settings(true, false)
    again.act(s2, "death")
    again._process(0.01)
    assert_almost(absf(s2.rotation), deg_to_rad(45.0), 0.001,
        "under reduced motion the topple ARRIVES at once — a fallen body is a destination, not a flourish")
    assert_false(stage.act(spr, "moonwalk"), "an unknown verb is refused")
    assert_false(stage.act(null, "attack"), "and so is nobody")


func test_a_verb_on_the_boss_composes_with_its_bob() -> void:
    # The boss's bob rewrites position.y every frame; a hit on it must neither
    # freeze the bob nor snap it — the act writes DELTAS.
    var stage := _stage({})
    var boss: Sprite2D = stage.place_boss(_still_only("boss_main"), Vector2(1200, 800))
    stage.hit(boss, {"from": Vector2(600, 800)})
    stage._process(0.02)
    assert_true(boss.position.x > 1200.0, "the boss recoils away from the party")
    stage._process(0.5)
    assert_almost(boss.position.x, 1200.0, 0.001, "and returns in x")
    var y1 := boss.position.y
    stage._process(0.5)
    assert_ne(boss.position.y, y1, "while the bob carries on")


## ------------------------------------------------- W2-STAGE2: the mouth

func test_the_speaking_bubble_follows_its_speaker() -> void:
    # STAGE-10 / KIT-02: a speech entry with a speaker yields a "Tail" whose
    # apex is within 6px of the head, and the plate's bottom-centre is the
    # tail's depth above that.
    var stage := _stage({"actors": [
        {"who": "cleric", "pos": [100, 700]},
        {"who": "mage", "pos": [400, 500], "scale": 2},
    ], "speech": {"pos": [10, 10], "size": [182, 76], "speaker": 1, "lines": ["Nobody said there would be fire."]}})
    var plate := _speech_plate(stage)
    assert_true(plate != null, "the plate built")
    var tail = plate.get_node_or_null("Tail")
    assert_true(tail != null, "a speech entry with a speaker yields a node named Tail")
    var speaker: AnimatedSprite2D = null
    for node in _actor_nodes(stage):
        if String(node.name).begins_with("Actor_mage"):
            speaker = node
    var head: Vector2 = stage.head_of(speaker)
    var apex: Vector2 = plate.position + tail.apex
    assert_true(apex.distance_to(head) <= 6.0 + 0.001,
        "the tail's apex is within 6px of the head (got %.1f)" % apex.distance_to(head))
    assert_almost(apex.x, head.x, 0.01, "on the head's centre line")
    assert_true(apex.y < head.y, "and above it")
    # The speaker moves (a verb): the plate follows on the stage's clock.
    stage.act(speaker, "attack", {"toward": Vector2(800, 500)})
    stage._process(0.09)
    plate = _speech_plate(stage)
    assert_almost(plate.position.x + plate.size.x / 2.0, speaker.position.x, 0.01, "the plate rides with the figure")
    assert_eq(plate.mouse_filter, Control.MOUSE_FILTER_IGNORE, "and never eats a click")
    assert_eq(Widgets.content_of(plate).mouse_filter, Control.MOUSE_FILTER_IGNORE, "nor does its Pad (say_at's rule)")


func test_the_speaker_rotates_by_line_and_hides_when_absent() -> void:
    var stage := _stage({"actors": [
        {"who": "cleric", "pos": [100, 700]},
        {"who": "mage", "pos": [400, 500]},
        {"who": "rogue", "pos": [700, 600]},
    ], "speech": {"pos": [10, 10], "size": [182, 76], "speaker": [0, "rogue"],
        "lines": ["one", "two", "three", "four", "five", "six", "seven", "eight"]}})
    var seen := {}
    for line in ["one", "two", "three", "four", "five", "six", "seven", "eight"]:
        stage.set_lines([line])
        var plate := _speech_plate(stage)
        assert_true(plate.visible, "a line with a speaker shows")
        var x := plate.position.x + plate.size.x / 2.0
        assert_true(is_equal_approx(x, 100.0) or is_equal_approx(x, 700.0),
            "the mouth is one of the named speakers (index or who), got x %.0f" % x)
        seen[int(x)] = true
        assert_true(plate.get_node_or_null("Tail") != null, "each rebuilt plate has its tail")
    assert_eq(seen.size(), 2, "over eight lines the hash reaches both mouths")
    var plates := 0
    for child in stage.get_children():
        if child is PanelContainer:
            plates += 1
    assert_eq(plates, 1, "one plate at a time, however often the speaker changes")
    # Twice the same data, same line: the same mouth (a shot is stable).
    var a := _stage({"actors": [{"who": "cleric", "pos": [100, 700]}, {"who": "rogue", "pos": [700, 600]}],
        "speech": {"pos": [0, 0], "speaker": [0, 1], "lines": ["Do we still get paid if we run?"]}})
    var b := _stage({"actors": [{"who": "cleric", "pos": [100, 700]}, {"who": "rogue", "pos": [700, 600]}],
        "speech": {"pos": [0, 0], "speaker": [0, 1], "lines": ["Do we still get paid if we run?"]}})
    assert_eq(_speech_plate(a).position, _speech_plate(b).position, "deterministic by line")
    # A named speaker that did not build: the line hides (a line with no mouth is a tooltip).
    var orphan := _stage({"actors": [{"who": "cleric", "pos": [100, 700]}],
        "speech": {"pos": [10, 10], "speaker": 7, "lines": ["Hm."]}})
    var op := _speech_plate(orphan)
    assert_true(op != null and not op.visible, "KIT-02: hide the plate when the speaker is absent")


## ------------------------------------------------- W2-STAGE2: emotes, drift, smoke

func test_a_bubble_with_an_emote_key_shows_that_icon() -> void:
    # TOWN-26 / PIPE-05: [x, y, "emote:mug"] shows the icon grid's mug inside
    # the kit's frame; the glyph's texture IS Icons.at("emote", "mug").
    var stage := _stage({"bubbles": [[10, 10, "emote:mug"], [60, 10, "skull"], [110, 10]], "bubble_visible": 3})
    var kinds: Array = []
    var glyphs := {}
    for child in stage.get_children():
        if child is TextureRect and child.has_meta("emote"):
            kinds.append(String(child.get_meta("emote")))
            var g: TextureRect = child.get_node_or_null("Glyph")
            glyphs[String(child.get_meta("emote"))] = g.texture if g != null else null
    assert_eq(kinds, ["mug", "skull", "dots"], "the kind is the key, with or without the emote: prefix")
    assert_true(glyphs["mug"] != null and glyphs["mug"].resource_path == Icons.path("emote", "mug"),
        "the mug bubble carries icons/grid/emote_mug.png")
    assert_true(glyphs["skull"] != null and glyphs["skull"].resource_path == Icons.path("emote", "skull"), "and the skull its own")
    assert_true(glyphs["dots"] == null, "a bare [x, y] is the reference's dots")
    # The shipped scenes: the tavern has mugs, the camp a sweat drop and a skull, and at least two glyph kinds each.
    for name in ["stage_camp", "stage_tavern", "stage_market"]:
        var keys: Array = []
        for b in _scene_json(name).get("bubbles", []):
            if b.size() > 2:
                var k := String(b[2]).trim_prefix("emote:")
                assert_true(Icons.exists("emote", k), "%s names an emote the grid has: %s" % [name, k])
                keys.append(k)
        assert_true(keys.size() >= 2, "%s has at least two glyph bubbles" % name)
    assert_true("mug" in _emote_keys("stage_tavern"), "TOWN-26: mugs in the tavern")
    assert_true("sweat" in _emote_keys("stage_camp"), "a sweat drop by the stew pot")
    assert_true("skull" in _emote_keys("stage_camp"), "a skull after a wipe")


func _emote_keys(name: String) -> Array:
    var out: Array = []
    for b in _scene_json(name).get("bubbles", []):
        if b.size() > 2:
            out.append(String(b[2]).trim_prefix("emote:"))
    return out


func test_the_camp_raises_two_glyph_bubbles_whatever_the_pick() -> void:
    # W2-STAGE2's Town acceptance: "at least two glyph bubbles" in the shot. The
    # shuffle is seeded but the frame it lands on is not this test's to know, so
    # the camp's data must make EVERY pick show two: `bubble_visible` 3 over
    # ambient bubbles of which at most one is a bare "..." (the review's shot
    # had one glyph + one dots at bubble_visible 2).
    var d := _scene_json("stage_camp")
    var ambient := 0
    var dots := 0
    for b in d.get("bubbles", []):
        if b.size() > 3:
            continue
        ambient += 1
        if b.size() < 3 or String(b[2]).trim_prefix("emote:") == "dots":
            dots += 1
    var up := int(d.get("bubble_visible", 2))
    assert_true(up >= 3, "three ambient bubbles are up at a time (got %d)" % up)
    assert_true(up - dots >= 2, "a pick of %d over %d ambient (%d dots) always holds two glyphs" % [up, ambient, dots])
    var stage := SceneStage.from_data("stage_camp", d)
    _built.append(stage)
    for i in 8:
        var glyphs := 0
        for child in stage.get_children():
            if not (child is TextureRect and child.has_meta("emote") and child.visible):
                continue
            if child.get_node_or_null("Glyph") != null:
                glyphs += 1
        assert_true(glyphs >= 2, "shuffle %d: %d glyph bubbles up" % [i, glyphs])
        stage._process(3.0)


func test_a_mood_bubble_shows_only_under_its_mood() -> void:
    # The camp's skull: a fourth entry names a mood; the bubble is never in
    # the ambient pick and is always up while the screen has set that mood.
    var stage := _stage({"bubbles": [[0, 0], [40, 0], [80, 0, "emote:skull", "wipe"]], "bubble_visible": 2})
    var skull: TextureRect = null
    for child in stage.get_children():
        if child is TextureRect and child.has_meta("emote") and String(child.get_meta("emote")) == "skull":
            skull = child
    assert_true(skull != null, "the skull built")
    assert_false(skull.visible, "no mood: the skull is down")
    for i in 6:
        stage._process(3.0)
        assert_false(skull.visible, "and never in the ambient shuffle")
    stage.set_mood("wipe")
    assert_true(skull.visible, "the wipe mood raises it")
    for i in 6:
        stage._process(3.0)
        assert_true(skull.visible, "and it stays up through the shuffles")
    stage.set_mood("")
    assert_false(skull.visible, "clearing the mood lowers it")
    var camp := _scene_json("stage_camp")
    var moods: Array = []
    for b in camp.get("bubbles", []):
        if b.size() > 3:
            moods.append(String(b[3]))
    assert_eq(moods, ["wipe"], "the camp's skull is the wipe's")


func test_scroll_layer_stops_under_reduced_motion() -> void:
    # STAGE-14: `scroll` is a new layer type — JSON key, apply_settings
    # handling, this test. The drift is TIME-driven inside the shader, so the
    # switch travels as the `motion` uniform, like the water's.
    var stage := _stage({"scroll": [
        {"tex": "res://game/assets/vfx/clouds_far.png", "rect": [0, 0, 1536, 200], "px_per_s": 2.5, "opacity": 0.65},
        {"tex": "res://game/assets/vfx/clouds_near.png", "rect": [0, 0, 1536, 200], "px_per_s": 4.5},
    ]})
    var quads: Array = []
    for child in stage.get_children():
        if child is ColorRect and String(child.name).begins_with("Scroll_"):
            quads.append(child)
    assert_eq(quads.size(), 2, "two drift layers")
    var q: ColorRect = quads[0]
    assert_eq(q.position, Vector2(0, 0), "on its rect")
    assert_eq(q.size, Vector2(1536, 200), "the rect's size (the 220-tall strip is cropped, not squashed: the shader samples 1:1)")
    assert_eq(q.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a sky must not eat a click")
    var mat: ShaderMaterial = q.material
    assert_true(mat != null and mat.shader.code.contains("TIME"), "the drift is shader time")
    assert_almost(float(mat.get_shader_parameter("px_per_s")), 2.5, 0.001, "at the authored speed")
    assert_almost(float(mat.get_shader_parameter("opacity")), 0.65, 0.001, "and opacity")
    assert_almost(float(mat.get_shader_parameter("motion")), 1.0, 0.001, "moving")
    assert_true(mat.get_shader_parameter("tex") is Texture2D, "carrying the strip")
    assert_true(q.get_index() < stage.get_node("Overlay").get_index(), "under the overlays")
    stage.apply_settings(true, false)
    for quad in quads:
        assert_almost(float(quad.material.get_shader_parameter("motion")), 0.0, 0.001,
            "reduced motion stops the drift inside the shader")
        assert_true(quad.visible, "but the clouds are still there")
    var quiet := _stage({"scroll": [{"tex": "res://game/assets/vfx/clouds_far.png", "rect": [0, 0, 100, 100]}]})
    quiet.apply_settings(false, true)
    for child in quiet.get_children():
        if child is ColorRect and String(child.name).begins_with("Scroll_"):
            assert_false(child.visible, "an effect: gone under reduced effects")
    assert_true(_stage({}).add_scroll(null, Rect2(0, 0, 10, 10), 1.0) == null, "no texture, no layer")
    # The town ships both strips over its sky rows.
    var town := _scene_json("stage_town")
    var rows: Array = town.get("scroll", [])
    assert_eq(rows.size(), 2, "stage_town drifts clouds_far and clouds_near")
    for r in rows:
        assert_true(ResourceLoader.exists(String(r.get("tex", ""))), "the strip exists: %s" % r.get("tex", ""))
        var rect: Array = r.get("rect", [])
        assert_true(float(rect[1]) + float(rect[3]) <= 200.0, "over the sky rows only (0-200, STAGE-14)")


func test_smoke_holds_under_reduced_motion_and_goes_under_reduced_effects() -> void:
    # STAGE-14's chimneys: a `smoke` preset — grey, not emissive, born formed;
    # every emitter is HELD (speed_scale 0) under reduced motion so two held
    # frames match, and off under reduced effects.
    var stage := _stage({"embers": [
        {"pos": [10, 10], "preset": "smoke"},
        {"pos": [50, 50], "amount": 4},
    ]})
    var parts: Array = []
    for child in stage.get_children():
        if child is GPUParticles2D:
            parts.append(child)
    assert_eq(parts.size(), 2, "two emitters")
    var smoke: GPUParticles2D = parts[0]
    var birth: Color = smoke.process_material.color_ramp.gradient.get_color(0)
    assert_true(birth.r < 1.0 and absf(birth.r - birth.b) < 0.1, "smoke is grey and not emissive")
    assert_true(smoke.preprocess > 0.0, "and born formed, so a held stage still shows a plume")
    assert_true(smoke.process_material.direction.x > 0.0, "drifting +x")
    assert_almost(smoke.speed_scale, 1.0, 0.001, "moving")
    stage.apply_settings(true, false)
    for p in parts:
        assert_almost(p.speed_scale, 0.0, 0.001, "%s is held under reduced motion" % p.name)
        assert_true(p.emitting, "but still there")
    stage.apply_settings(false, true)
    for p in parts:
        assert_false(p.emitting, "%s is off under reduced effects" % p.name)
    var town := _scene_json("stage_town")
    var chimneys := 0
    for em in town.get("embers", []):
        if String(em.get("preset", "")) == "smoke":
            chimneys += 1
    assert_eq(chimneys, 3, "three chimneys smoke on the aerial")


## ------------------------------------------------- W2-STAGE2: the dead files

func test_the_mockup_crop_scenes_are_gone() -> void:
    # STAGE-13 / RULES-10 / RULES-16: camp.json and guildhall.json staged the
    # Concept crops with painted people; nothing loads them and they are gone,
    # plates and all. Every shipped scene stands on a bare stage_* plate.
    for name in ["camp", "guildhall"]:
        assert_false(FileAccess.file_exists(SCENES + name + ".json"), "%s.json must be deleted" % name)
        assert_false(FileAccess.file_exists("res://game/assets/bg/%s_plate.png" % name),
            "%s_plate.png must be deleted" % name)
        var stage := SceneStage.load(name)
        _built.append(stage)
        assert_true(stage.get_node_or_null("Plate") == null, "loading it degrades to a bare stage, not a crash")
    for name in _shipped_scenes():
        assert_true(name.begins_with("stage_"), "only bare stages ship: %s" % name)
        var plate := String(_scene_json(name).get("plate", ""))
        assert_true(plate.begins_with("res://game/assets/bg/stage_"), "%s stands on a bare plate: %s" % [name, plate])
        assert_false((_scene_json(name).get("speech", {}) as Dictionary).has("backing"),
            "%s: the `backing` switch is gone with the crops" % name)
    var src := FileAccess.get_file_as_string("res://game/ui/SceneStage.gd")
    assert_false(src.contains("backing"), "SceneStage no longer carries the crop-era backing branch")
    assert_false(src.contains("create_tween"), "and still makes no Tween of its own")


func test_market_shoppers_stand_in_the_band_the_screen_shows() -> void:
    # STAGE-15: five whole 1x figures inside the right-hand band W2-MARKET
    # leaves beside its ledger (plate x 980..1349, y 300..940), and the top
    # strip the pre-W2 layout shows keeps three whole figures (y 240..306).
    var manifest := _manifest()
    var d := _scene_json("stage_market")
    var right := 0
    var top := 0
    for a in d.get("actors", []):
        var pos: Array = a.get("pos", [0, 0])
        var h := float((manifest.get(String(a.get("who", "")), {}) as Dictionary).get("frame_h", 0))
        var feet := Vector2(float(pos[0]), float(pos[1]))
        var head_y := feet.y - h
        if feet.x >= 980.0 and feet.x <= 1349.0 and head_y >= 300.0 and feet.y <= 940.0:
            right += 1
        if feet.x >= 330.0 and feet.x <= 1259.0 and head_y >= 240.0 and feet.y <= 306.0:
            top += 1
    assert_true(right >= 5, "five whole shoppers in the right band, found %d" % right)
    assert_true(top >= 3, "three whole figures in the top strip, found %d" % top)
    assert_true((d.get("actors", []) as Array).size() <= 8, "the rest were dropped")


## ------------------------------------------------- W4-LIFE: motion on paths
## TOWN-27 / STAGE-14: the camp walks, the sails turn, the gulls cross, the
## lanterns flame. Three new layer types (`paths`, `rotor`, `flyers`), each
## with its apply_settings handling pinned here; the banners and the lantern
## flames are props. Every traveller is held by reduced motion and left alone
## by reduced effects (they are the world, not an effect).

const LIFE := "res://game/assets/vfx/life/"
const LIFE_JSON := LIFE + "life.json"
const GULL := LIFE + "gull.png"


func _life_rows() -> Dictionary:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(LIFE_JSON))
    return parsed.get("strips", {}) if parsed is Dictionary else {}


func _walkers(stage: Control) -> Array:
    var out: Array = []
    for child in stage.get_children():
        if child is AnimatedSprite2D and String(child.name).begins_with("Walker_"):
            out.append(child)
    return out


func test_a_walker_walks_its_path_and_faces_the_way_it_goes() -> void:
    var stage := _stage({"paths": [
        {"who": "variant_r02_black", "points": [[500, 650], [560, 650]], "px_per_s": 20},
    ]})
    var walkers := _walkers(stage)
    assert_eq(walkers.size(), 1, "one walker from one path")
    var w: AnimatedSprite2D = walkers[0]
    assert_true(w.sprite_frames.has_animation("walk"), "the walk strip gen_actors.py derived is its walk animation")
    assert_eq(w.sprite_frames.get_frame_count("walk"), 4, "four frames of it")
    assert_true(w.sprite_frames.has_animation("idle"), "and the idle is still there")
    assert_eq(String(w.animation), "walk", "it walks")
    assert_true(w.is_playing(), "and is playing")
    assert_eq(w.position, Vector2(500, 650), "starting at the path's first point")
    assert_false(w.flip_h, "heading +x, unflipped (the strips face right)")
    var shadow := stage.get_child(w.get_index() - 1)
    assert_true(String(shadow.name).begins_with("Shadow_"), "its contact shadow rides just before it")
    stage._process(0.5)
    assert_almost(w.position.x, 510.0, 0.01, "20 px/s for half a second")
    assert_almost(w.position.y, 650.0, 0.01, "along the path")
    assert_almost((shadow as Node2D).position.x, 510.0, 0.01, "the shadow came along")
    for i in 4:
        stage._process(1.0)
    # 4.5 s x 20 px/s = 90 px on a 60 px path: turned back at the end, 30 px in
    assert_almost(w.position.x, 530.0, 0.01, "ping-pong: back the way it came")
    assert_true(w.flip_h, "and facing -x now")
    var loop := _stage({"paths": [
        {"who": "variant_r02_black", "points": [[0, 0], [100, 0]], "px_per_s": 50, "loop": true, "phase": 0.5},
    ]})
    var lw: AnimatedSprite2D = _walkers(loop)[0]
    assert_eq(lw.position, Vector2(50, 0), "phase 0.5 starts halfway")
    loop._process(1.2)
    assert_almost(lw.position.x, 10.0, 0.01, "a loop wraps to the start instead of turning")
    assert_false(lw.flip_h, "still heading +x")
    assert_true(_stage({"paths": [{"who": "variant_r02_black", "points": [[1, 1]]}]}).add_walker({"who": "cleric", "points": []}) == null,
        "a path needs two points")
    assert_eq(_walkers(_stage({"paths": [{"who": "nobody", "points": [[0, 0], [9, 9]]}]})).size(), 0, "an unknown figure is skipped, not fatal")


func test_a_walker_without_a_walk_strip_still_walks_on_its_idle() -> void:
    var stage := _stage({"paths": [{"who": "cleric", "points": [[10, 10], [90, 10]], "px_per_s": 10}]})
    var w: AnimatedSprite2D = _walkers(stage)[0]
    assert_false(w.sprite_frames.has_animation("walk"), "the cleric has no _walk row")
    assert_eq(String(w.animation), "idle", "so it moves on its idle")
    assert_true(w.is_playing(), "playing")
    stage._process(1.0)
    assert_almost(w.position.x, 20.0, 0.01, "and moves all the same")


func test_a_walker_keeps_the_back_to_front_order_while_it_moves() -> void:
    # Depth is tree order (no z_index): a figure whose feet are lower is drawn
    # later. A walker crossing the crowd has to keep that true every tick.
    var stage := _stage({
        "actors": [{"who": "mage", "pos": [400, 600]}, {"who": "cleric", "pos": [400, 700]}],
        "paths": [{"who": "variant_r02_black", "points": [[500, 560], [500, 760]], "px_per_s": 100}],
    })
    var mage: Node = stage.get_node("Actor_mage_0")
    var cleric: Node = stage.get_node("Actor_cleric_1")
    var w: AnimatedSprite2D = _walkers(stage)[0]
    assert_true(w.get_index() < mage.get_index(), "at y 560 the walker is behind the mage (600)")
    stage._process(0.9)   # y 650: between them
    assert_true(w.get_index() > mage.get_index() and w.get_index() < cleric.get_index(),
        "at y %d the walker sits between the mage and the cleric" % int(w.position.y))
    assert_true(String(stage.get_child(w.get_index() - 1).name).begins_with("Shadow_"), "its shadow moved with it")
    stage._process(0.9)   # y 740: in front of both
    assert_true(w.get_index() > cleric.get_index(), "at y %d it is in front of the cleric (700)" % int(w.position.y))
    for i in 2:
        stage._process(1.0)   # to the end (760) and back up to y 580
    assert_true(w.get_index() < mage.get_index(), "back at y %d it is behind the mage again" % int(w.position.y))
    # the standing figures never moved in the tree relative to each other
    assert_true(mage.get_index() < cleric.get_index(), "the crowd's own order is untouched")


func test_a_rotor_turns_about_its_centre() -> void:
    var stage := _stage({})
    var tex: Texture2D = load(LIFE + "sail_a.png")
    var r: Sprite2D = stage.add_rotor(tex, Vector2(300, 200), 0.5)
    assert_true(r != null and r.name == "Rotor_0", "a rotor")
    assert_true(r.centered and r.offset == Vector2.ZERO, "turning about its centre: the axle is the canvas centre (patch_plate.py)")
    assert_eq(r.position, Vector2(300, 200), "on its axle")
    assert_almost(r.rotation, 0.0, 0.0001, "at rest it is the painting")
    stage._process(1.0)
    assert_almost(r.rotation, 0.5, 0.0001, "rad_per_s, per second")
    var back: Sprite2D = stage.add_rotor(tex, Vector2(0, 0), -0.25, {"phase": 1.0})
    assert_almost(back.rotation, 1.0, 0.0001, "a phase")
    stage._process(2.0)
    assert_almost(back.rotation, 0.5, 0.0001, "and a negative rate turns the other way")
    assert_true(stage.add_rotor(null, Vector2.ZERO, 1.0) == null, "no texture, no rotor")
    assert_true(r.get_index() < stage.get_node("Overlay").get_index(), "under the overlays")
    # The town ships both sails on the axles patch_plate.py cut them at, and the
    # sprite's centre pixel is the hub (opaque) — the cut is centred on the axle.
    var town := _scene_json("stage_town")
    var rows: Array = town.get("rotor", [])
    assert_eq(rows.size(), 2, "two windmills turn on the aerial")
    for row in rows:
        var path := String(row.get("tex", ""))
        assert_true(ResourceLoader.exists(path), "the sail exists: %s" % path)
        var img: Image = (load(path) as Texture2D).get_image()
        assert_eq(img.get_width(), img.get_height(), "a square canvas")
        assert_true(img.get_pixel(img.get_width() / 2, img.get_height() / 2).a > 0.99, "the hub at its centre is opaque")
        assert_true(absf(float(row.get("rad_per_s", 0.0))) > 0.0, "and it turns")
        var pos: Array = row.get("pos", [])
        assert_true(pos.size() == 2 and float(pos[0]) > 1200.0 and float(pos[1]) > 250.0 and float(pos[1]) < 500.0,
            "on the right ridge where the plate paints the mills (STAGE-14)")


func test_a_flyer_rides_a_closed_spline() -> void:
    var stage := _stage({})
    var pts := [[0, 0], [100, 0], [100, 100], [0, 100]]
    var f: AnimatedSprite2D = stage.add_flyer(GULL, pts, 50.0)
    assert_true(f != null and f.name == "Flyer_0", "a flyer")
    assert_true(f.sprite_frames.has_animation("fly"), "flapping")
    assert_eq(f.sprite_frames.get_frame_count("fly"), 3, "the 3-frame gull")
    assert_true(f.is_playing(), "playing")
    assert_eq(f.position, Vector2(0, 0), "starting at the first point")
    assert_eq(f.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "a sprite, drawn crisp")
    stage._process(1.0)
    assert_true(f.position.x > 30.0 and f.position.x < 70.0 and absf(f.position.y) < 20.0,
        "about 50 px along the first leg after a second: %s" % f.position)
    var box := Rect2(-30, -30, 160, 160)
    for i in 20:
        stage._process(0.7)
        assert_true(box.has_point(f.position), "a closed spline through the points never leaves them far: %s" % f.position)
    assert_true(stage.add_flyer(GULL, [[0, 0]], 1.0) == null, "a spline needs two points")
    assert_true(stage.add_flyer("res://nowhere.png", pts, 1.0) == null, "no strip, no flyer")
    var town := _scene_json("stage_town")
    var rows: Array = town.get("flyers", [])
    assert_true(rows.size() >= 3, "three gulls over the aerial, found %d" % rows.size())
    for row in rows:
        assert_true(ResourceLoader.exists(String(row.get("strip", ""))), "the gull strip exists")
        assert_true((row.get("points", []) as Array).size() >= 3, "on a spline of at least three points")
        assert_true(float(row.get("px_per_s", 0.0)) > 0.0, "and moving")


func test_travellers_hold_under_reduced_motion_and_stay_under_reduced_effects() -> void:
    var d := {
        "paths": [{"who": "variant_r02_black", "points": [[500, 650], [560, 650]], "px_per_s": 20}],
        "rotor": [{"tex": LIFE + "sail_a.png", "pos": [300, 200], "rad_per_s": 0.5}],
        "flyers": [{"strip": GULL, "points": [[0, 0], [100, 0], [100, 100]], "px_per_s": 40}],
    }
    var stage := _stage(d)
    var w: AnimatedSprite2D = _walkers(stage)[0]
    var r: Sprite2D = stage.get_node("Rotor_0")
    var f: AnimatedSprite2D = stage.get_node("Flyer_0")
    stage._process(0.3)
    var wp := w.position
    var rr := r.rotation
    var fp := f.position
    assert_true(wp != Vector2(500, 650) and rr > 0.0 and fp != Vector2.ZERO, "everything moved before the switch")
    stage.apply_settings(true, false)
    assert_false(w.is_playing(), "reduced motion: the walker stops")
    assert_eq(w.frame, 0, "on the pose (frame 0 of the walk is the pose)")
    assert_false(f.is_playing(), "the gull stops")
    assert_eq(f.frame, 0, "on its first frame")
    for i in 5:
        stage._process(0.4)
    assert_eq(w.position, wp, "the walker stands where the switch found it")
    assert_almost(r.rotation, rr, 0.0001, "the sail keeps its angle")
    assert_eq(f.position, fp, "the gull hangs where it was")
    assert_true(w.visible and r.visible and f.visible, "held, not hidden")
    # A walker placed AFTER the switch is held too, like a figure the screen places.
    var late: AnimatedSprite2D = stage.add_walker({"who": "variant_r04_brown", "points": [[0, 0], [50, 0]], "px_per_s": 20})
    assert_false(late.is_playing(), "a walker added to a held stage is held")
    stage._process(1.0)
    assert_eq(late.position, Vector2(0, 0), "and does not move")
    var effects := _stage(d)
    effects.apply_settings(false, true)
    var ew: AnimatedSprite2D = _walkers(effects)[0]
    var er: Sprite2D = effects.get_node("Rotor_0")
    var ef: AnimatedSprite2D = effects.get_node("Flyer_0")
    assert_true(ew.is_playing() and ef.is_playing(), "reduced effects: they are the world, not an effect — still moving")
    assert_true(ew.visible and er.visible and ef.visible, "and still there (hiding a sail would bare the plate's patch)")
    effects._process(0.5)
    assert_true(er.rotation > 0.0 and ew.position.x > 500.0, "turning and walking")


func test_a_banner_is_an_untinted_topleft_prop_and_a_flame_is_over_driven() -> void:
    var stage := _stage({"props": [
        {"strip": LIFE + "banner_wave.png", "frame_w": 40, "fps": 6, "pos": [866, 80], "anchor": "topleft"},
        {"strip": LIFE + "flame_lantern.png", "frame_w": 6, "fps": 8, "pos": [100, 100], "anchor": "bottom", "emissive": 1.25},
    ]})
    var props: Array = []
    for child in stage.get_children():
        if child is AnimatedSprite2D:
            props.append(child)
    assert_eq(props.size(), 2, "two props")
    var banner: AnimatedSprite2D = props[0]
    var flame: AnimatedSprite2D = props[1]
    assert_false(banner.centered, "a topleft prop is not centred")
    assert_eq(banner.position, Vector2(866, 80), "its pos is the crop's origin")
    assert_eq(banner.offset, Vector2.ZERO, "and it is not lifted")
    assert_eq(banner.modulate, Color(1, 1, 1, 1), "no `emissive`: drawn as the plate's own pixels, untinted")
    assert_eq(banner.sprite_frames.get_frame_count("burn"), 4, "four frames of wave")
    assert_true(flame.centered, "a bottom-anchored prop keeps the fires' way")
    assert_eq(flame.offset, Vector2(0, -4), "lifted half its 8 px")
    assert_true(flame.modulate.r > 1.0, "an `emissive` prop is over-driven for the glow")
    assert_eq(flame.sprite_frames.get_frame_count("burn"), 3, "three frames of flame")
    stage.apply_settings(true, false)
    assert_false(banner.is_playing() or flame.is_playing(), "both held")
    assert_eq(banner.frame, 0, "the banner on its rest frame — the plate itself")


func test_the_life_strips_match_their_table() -> void:
    # life.json is to game/assets/vfx/life what vfx.json is to its folder
    # (test_vfx_assets.gd walks one directory only): every PNG has a row, every
    # row a PNG at its geometry, every PNG an .import.
    var rows := _life_rows()
    assert_true(rows.size() >= 6, "the flame, two banners, the gull and two sails, found %d rows" % rows.size())
    var pngs: Array[String] = []
    for f in DirAccess.get_files_at(LIFE):
        if String(f).ends_with(".png"):
            pngs.append(String(f).get_basename())
    var bad: Array[String] = []
    for n in pngs:
        if not rows.has(n):
            bad.append("%s.png has no life.json row" % n)
        if not FileAccess.file_exists(LIFE + n + ".png.import"):
            bad.append("%s.png has no .import" % n)
    for name in rows:
        var row: Dictionary = rows[name]
        var path := LIFE + String(name) + ".png"
        if not ResourceLoader.exists(path):
            bad.append("%s: no PNG" % name)
            continue
        var tex: Texture2D = load(path)
        var want := Vector2i(int(row.get("frames", 0)) * int(row.get("frame_w", 0)), int(row.get("frame_h", 0)))
        if Vector2i(tex.get_width(), tex.get_height()) != want:
            bad.append("%s: PNG is %dx%d, life.json says %s" % [name, tex.get_width(), tex.get_height(), want])
    assert_eq(bad.size(), 0, "life strips and their table disagree:\n      " + "\n      ".join(bad))
    assert_eq(Vector2i(int(rows["flame_lantern"]["frame_w"]), int(rows["flame_lantern"]["frame_h"])), Vector2i(6, 8),
        "spec 09 §5 rank 2: a 6x8 flame")
    assert_eq(int(rows["flame_lantern"]["frames"]), 3, "in three frames")
    assert_eq(Vector2i(int(rows["gull"]["frame_w"]), int(rows["gull"]["frame_h"])), Vector2i(12, 6), "STAGE-14: a 12x6 gull")
    assert_eq(int(rows["gull"]["frames"]), 3, "in three frames")
    assert_eq(int(rows["banner_wave"]["frames"]), 4, "TOWN-27: a 4-frame wave")


func test_the_banners_rest_on_the_plates_own_pixels() -> void:
    # A banner is an opaque crop of the camp plate: frame 0 at its `pos` IS the
    # plate (so reduced motion shows the painting), the later frames differ.
    var plate := _raw("res://game/assets/bg/stage_camp.png")
    var banners := 0
    for p in _scene_json("stage_camp").get("props", []):
        if String(p.get("anchor", "")) != "topleft":
            continue
        banners += 1
        var strip := _raw(String(p.get("strip", "")))
        var fw := int(p.get("frame_w", 0))
        var pos: Array = p.get("pos", [0, 0])
        var same := 0
        var moved := 0
        for y in strip.get_height():
            for x in fw:
                var c := strip.get_pixel(x, y)
                if c.a < 0.99:
                    fail("%s: a banner crop must be opaque (alpha %.2f at %d,%d)" % [p.get("strip"), c.a, x, y])
                    return
                if c.is_equal_approx(plate.get_pixel(int(pos[0]) + x, int(pos[1]) + y)):
                    same += 1
                if _differs(c, strip.get_pixel(fw + x, y)):
                    moved += 1
        assert_eq(same, fw * strip.get_height(), "%s frame 0 is the plate at %s" % [p.get("strip"), pos])
        assert_true(moved > 100, "%s frame 1 ripples (%d px differ)" % [p.get("strip"), moved])
    assert_eq(banners, 2, "the north and west banners wave")


func test_the_camp_lanterns_flame_and_two_townsfolk_walk() -> void:
    var d := _scene_json("stage_camp")
    var lights: Array = d.get("lights", [])
    var flames := 0
    var orphan: Array[String] = []
    for p in d.get("props", []):
        if not String(p.get("strip", "")).ends_with("flame_lantern.png"):
            continue
        flames += 1
        var pos: Array = p.get("pos", [0, 0])
        var near := false
        for l in lights:
            var lp: Array = l.get("pos", [0, 0])
            if Vector2(float(pos[0]), float(pos[1])).distance_to(Vector2(float(lp[0]), float(lp[1]))) <= 16.0:
                near = true
        if not near:
            orphan.append("%s" % [pos])
        assert_true(float(p.get("fps", 0.0)) > 3.0, "a flame runs above the flash rule's 3 fps (test_motion.gd:139-156 wants one)")
    assert_true(flames >= 10, "every tent lantern carries a flame: %d" % flames)
    assert_eq(orphan.size(), 0, "a flame sits on a lantern (within 16 px of its light): " + ", ".join(orphan))
    var paths: Array = d.get("paths", [])
    assert_true(paths.size() >= 2, "two townsfolk walk the camp")
    var manifest := _manifest()
    for w in paths:
        var who := String(w.get("who", ""))
        assert_true(manifest.has(who + "_walk"), "%s has a walk strip" % who)
        assert_true((w.get("points", []) as Array).size() >= 2 and float(w.get("px_per_s", 0.0)) > 0.0, "%s has somewhere to go" % who)
    var stage := SceneStage.load("stage_camp")
    _built.append(stage)
    var walkers := _walkers(stage)
    assert_eq(walkers.size(), paths.size(), "every path built its walker")
    for w in walkers:
        assert_eq(String((w as AnimatedSprite2D).animation), "walk", "%s walks" % w.name)


func test_every_walk_strip_is_the_pose_with_a_lifted_foot() -> void:
    # gen_actors.py's bob walk: frame 0 the pose (the idle's frame 0), frame 2
    # the pose again, frames 1 and 3 each a different step with fewer pixels in
    # the bottom four rows than the pose (a foot is up: a leg lifted two rows
    # leaves two of its rows empty there, whichever row its foot stood on).
    var actors := _manifest()
    var walks := 0
    var bad: Array[String] = []
    for key in actors:
        var geom: Dictionary = actors[key]
        if String(geom.get("kind", "")) != "walk":
            continue
        walks += 1
        var of := String(geom.get("walk_of", ""))
        var pose: Dictionary = actors.get(of, {})
        if pose.is_empty():
            bad.append("%s: walk_of %s is not in the manifest" % [key, of])
            continue
        if int(geom.get("frames", 0)) != 4 or int(geom.get("frame_w", 0)) != int(pose.get("frame_w", -1)) or int(geom.get("frame_h", 0)) != int(pose.get("frame_h", -1)):
            bad.append("%s: 4 frames at the pose's geometry, got %s x %sx%s" % [key, geom.get("frames"), geom.get("frame_w"), geom.get("frame_h")])
            continue
        var walk := _raw(ACTORS + String(key) + ".png")
        var idle := _raw(ACTORS + of + ".png")
        var fw := int(geom.get("frame_w", 0))
        var fh := int(geom.get("frame_h", 0))
        var f0_is_pose := true
        var f2_is_f0 := true
        var d01 := 0
        var d13 := 0
        var floor := [0, 0, 0, 0]
        for y in fh:
            for x in fw:
                var c0 := walk.get_pixel(x, y)
                if _differs(c0, idle.get_pixel(x, y)):
                    f0_is_pose = false
                if _differs(c0, walk.get_pixel(2 * fw + x, y)):
                    f2_is_f0 = false
                if _differs(c0, walk.get_pixel(fw + x, y)):
                    d01 += 1
                if _differs(walk.get_pixel(fw + x, y), walk.get_pixel(3 * fw + x, y)):
                    d13 += 1
                if y >= fh - 4:
                    for f in 4:
                        if walk.get_pixel(f * fw + x, y).a > 0.0:
                            floor[f] += 1
        if not f0_is_pose:
            bad.append("%s: frame 0 is not the pose" % key)
        if not f2_is_f0:
            bad.append("%s: frame 2 is not frame 0" % key)
        if d01 == 0 or d13 == 0:
            bad.append("%s: the steps do not differ (%d, %d)" % [key, d01, d13])
        if floor[1] >= floor[0] or floor[3] >= floor[0]:
            bad.append("%s: a step must lift a foot off the floor (bottom-four-row counts %s)" % [key, floor])
    assert_true(walks >= 6, "six townsfolk have a walk (TOWN-27's 4-6), found %d" % walks)
    assert_eq(bad.size(), 0, "the walks are not as designed:\n      " + "\n      ".join(bad))


## ------------------------------------------------- W7-STAGE: the fight's picture

## UI-26, UI-20/35, UI-21, UI-22/BL-103, UI-07, UI-34, UI-54/Q-96 — the seven
## rules the stage now keeps, each read off the real scene files or a stage
## built from them, never off a shot.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const Fixture = preload("res://tools/fixture_reference.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const GUILDHALL := "res://game/screens/Guildhall.tscn"
## The widest and tallest class strip (the wizard's mage_b, 39x45): the
## worst case for the marks, stood in every slot.
const WIDEST := "mage_b"

var _mounted: Array = []


## Everything the party tests need in one place: the marks of `scene`, the
## widest class figure in every slot at the mark's scale, back to front.
func _party_on(scene: String) -> Array:
    var party: Dictionary = SceneStage.marks(scene).get("party", {})
    var sc := float(party.get("scale", 1.0))
    var out: Array = []
    var i := 0
    for rank in party.get("ranks", []):
        for x in rank.get("xs", []):
            out.append({"who": WIDEST, "pos": [x, rank.get("y", 0)], "id": "r%02d" % i, "scale": sc})
            i += 1
    return out


## A figure's body rect in stage space: its frame at its scale, planted by
## the feet (what `add_actor` draws).
func _body_rect(spr: Node2D) -> Rect2:
    var w := 0.0
    var h := 0.0
    if spr is AnimatedSprite2D:
        var tex: Texture2D = spr.sprite_frames.get_frame_texture(spr.animation, 0)
        w = float(tex.get_width())
        h = float(tex.get_height())
    elif spr is Sprite2D:
        w = float(spr.texture.get_width())
        h = float(spr.texture.get_height())
    return Rect2(spr.position.x - w * spr.scale.x / 2.0, spr.position.y - h * spr.scale.y,
        w * spr.scale.x, h * spr.scale.y)


## The top third of a body rect — where a plate must not sit.
func _head_rect(spr: Node2D) -> Rect2:
    var b := _body_rect(spr)
    return Rect2(b.position, Vector2(b.size.x, b.size.y / 3.0))


func _overlap_share(a: Rect2, b: Rect2) -> float:
    var i := a.intersection(b)
    if i.size.x <= 0.0 or i.size.y <= 0.0:
        return 0.0
    return i.get_area() / minf(a.get_area(), b.get_area())


func test_every_stage_light_culls_to_the_stage_layer_and_the_world_is_on_it() -> void:
    # UI-26: the camp's lanterns lit every panel drawn later in the canvas
    # (a 190px disc inside the Quarters panel). The lights now reach only the
    # stage's own layer, and everything the stage builds for the world — the
    # plate, the props, the figures and their shadows, the boss and its eyes,
    # the effects — is on that layer; the overlays are not.
    var lights := 0
    var world := 0
    for name in _shipped_scenes():
        var stage := SceneStage.from_data(name, _scene_json(name))
        _built.append(stage)
        for n in stage.find_children("*", "PointLight2D", true, false):
            lights += 1
            assert_eq((n as PointLight2D).range_item_cull_mask, SceneStage.LIGHT_LAYER,
                "%s: a stage light lights the stage layer only" % name)
        for c in stage.get_children():
            # A Light2D IS a CanvasItem, but its `light_mask` says which lights
            # fall on IT, which is meaningless for a lamp — `range_item_cull_mask`
            # above is the one that matters and is asserted there.
            if not (c is CanvasItem) or c is Light2D:
                continue
            var chrome: bool = c.name == "Overlay" or c.name == "Vignette" or c.name == "Speech" or c.has_meta("emote")
            if chrome:
                continue
            world += 1
            assert_eq((c as CanvasItem).light_mask, SceneStage.LIGHT_LAYER,
                "%s/%s is a world item and takes the stage's light" % [name, c.name])
        var overlay: Control = stage.get_node_or_null("Overlay")
        assert_true(overlay != null and (overlay.light_mask & SceneStage.LIGHT_LAYER) == 0,
            "%s: the overlay is not lit by the world's lanterns" % name)
    assert_true(lights >= 30, "expected the six scenes' lights, found %d" % lights)
    assert_true(world >= 40, "expected the six scenes' plates, props and figures, found %d" % world)
    # A figure and a boss a SCREEN places after the build get the same layer.
    var stage := _stage({})
    var by_id: Dictionary = stage.place_party([{"who": "warrior", "pos": [300, 700], "id": "r1"}])
    assert_eq((by_id["r1"] as CanvasItem).light_mask, SceneStage.LIGHT_LAYER)
    assert_eq((stage.get_node("Shadow_warrior_0") as CanvasItem).light_mask, SceneStage.LIGHT_LAYER)
    var boss: Node2D = stage.place_boss(load(ENEMIES + "boss_main.png"), Vector2(1000, 800), {"scale": 2.0})
    assert_eq(boss.light_mask, SceneStage.LIGHT_LAYER, "the boss is lit")
    assert_eq((stage.get_node("BossShadow") as CanvasItem).light_mask, SceneStage.LIGHT_LAYER)
    var glow: CanvasItem = boss.get_node_or_null("BossGlow")
    assert_true(glow != null and glow.light_mask == SceneStage.LIGHT_LAYER, "and its eyes")


func test_no_control_outside_the_stage_on_a_mounted_hall_takes_the_lanterns_light() -> void:
    # UI-26's other half, read off the real screen: mount the Guildhall on the
    # reference fixture and walk every CanvasItem that is not under the stage
    # — the panels, the sidebar, the strip, the rail, every Label — none may
    # be on the layer the stage's lights reach, and the Frame's panel hosts
    # are on no light layer at all.
    var view := _mount_screen(GUILDHALL)
    assert_true(view != null, "the Guildhall mounts on the fixture")
    if view == null:
        return
    var stages: Array = []
    var lit: Array[String] = []
    var walked := 0
    for n in view.find_children("*", "", true, false):
        if String(n.name).begins_with("SceneStage_"):
            stages.append(n)
    assert_true(stages.size() >= 1, "the hall stands on a stage")
    for n in view.find_children("*", "CanvasItem", true, false):
        var under_stage := false
        for st in stages:
            if n == st or (st as Node).is_ancestor_of(n):
                under_stage = true
        if under_stage:
            continue
        walked += 1
        if ((n as CanvasItem).light_mask & SceneStage.LIGHT_LAYER) != 0:
            lit.append(String(n.get_path()))
    assert_true(walked > 100, "walked the screen's chrome (%d items)" % walked)
    assert_eq(lit.size(), 0, "chrome on the stage's light layer: " + ", ".join(lit))
    for host_name in ["Header", "Rail", "SidebarHost", "StripHost", "ChipHost"]:
        var host: Node = view.find_child(host_name, true, false)
        assert_true(host is CanvasItem and (host as CanvasItem).light_mask == 0,
            "Frame's %s is on no light layer" % host_name)


## Mount a screen the way Boot does — the real autoload router, a host under
## the root, the reference fixture on the shared GameState — and hand back the
## screen. Everything is undone in after_each_mounted (called from after_each).
func _mount_screen(path: String) -> Control:
    var loop := Engine.get_main_loop()
    var root: Node = (loop as SceneTree).root if loop is SceneTree else null
    if root == null:
        return null
    if root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        root.add_child(s)
        _mounted.append(s)
    if root.get_node_or_null("GameSettings") == null:
        var gs = SettingsScript.new()
        gs.name = "GameSettings"
        root.add_child(gs)
        _mounted.append(gs)
    var st = root.get_node("GameState")
    st.reset()
    Fixture.apply(st, null, true)
    var host := Control.new()
    host.name = "StageTestHost"
    host.set_anchors_preset(Control.PRESET_TOP_LEFT)
    host.position = Vector2.ZERO
    host.size = Vector2(1536, 1024)
    root.add_child(host)
    _mounted.append(host)
    var router = Router.new()
    router.name = "StageTestRouter"
    root.add_child(router)
    _mounted.append(router)
    router.register_host(host)
    if not router.goto(path):
        return null
    return router.current_screen()


func after_each_mounted() -> void:
    if _mounted.is_empty():
        return
    for n in _mounted:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _mounted = []
    var loop := Engine.get_main_loop()
    var root: Node = (loop as SceneTree).root if loop is SceneTree else null
    var st = root.get_node_or_null("GameState") if root != null else null
    if st != null:
        SaveGame.purge_all()
        st.reset()
        st.content = null


func test_the_plate_lifts_clear_of_every_head_and_every_keep_out_rect() -> void:
    # UI-20 / UI-35: a front-rank speaker's plate used to sit over the two
    # ranks behind it and four of their badges; now it lifts CROWD_AIR above
    # the topmost head it would cover and clear of the screen's chrome rects,
    # and its tail reaches down to the speaker.
    var stage := SceneStage.from_data("stage_arena_cave", _scene_json("stage_arena_cave"))
    _built.append(stage)
    stage.position = Vector2(0, -280)
    var by_id: Dictionary = stage.place_party(_party_on("stage_arena_cave"))
    assert_eq(by_id.size(), 12, "twelve on the marks")
    # The front rank is the lowest row; its first slot is the leftmost figure,
    # the one nearest RaidView's objective block.
    var front: AnimatedSprite2D = null
    for id in by_id:
        var spr: AnimatedSprite2D = by_id[id]
        if front == null or spr.position.y > front.position.y:
            front = spr
        elif spr.position.y == front.position.y and spr.position.x < front.position.x:
            front = spr
    # RaidView's header, objective and boss plate, in stage rows under the (0,-280) view.
    var keep_out: Array = [Rect2(0, 280, 352, 64), Rect2(0, 368, 352, 106), Rect2(931, 333, 384, 65)]
    var plate: PanelContainer = stage.say_at(front,
        "The boss did the thing the boss does, and I was standing where it does it.", 2400, keep_out)
    assert_true(plate != null)
    var rect := Rect2(plate.position, plate.size)
    for id in by_id:
        var spr: AnimatedSprite2D = by_id[id]
        if spr == front:
            continue
        assert_false(rect.intersects(_head_rect(spr)),
            "the plate %s covers the head of %s at %s" % [rect, id, _head_rect(spr)])
    for r in keep_out:
        assert_false(rect.intersects(r), "the plate %s is over the chrome %s" % [rect, r])
    assert_true(rect.position.y >= 280.0, "the plate stays inside the rows the screen shows")
    var tail = plate.get_node_or_null("Tail")
    assert_true(tail != null, "the tail is still there")
    assert_almost((plate.position + tail.apex).distance_to(stage.head_of(front)), SceneStage.TAIL_AIR, 0.01,
        "and still points at the speaker's head")
    assert_true(tail.length >= stage.head_of(front).y - SceneStage.TAIL_AIR - rect.end.y - 0.01,
        "the tail's length is the lift the stage chose (the kit draws it as a wedge)")
    # A boss speaker with the boss plate over its head speaks from under it.
    var boss: Node2D = stage.place_boss(load(ENEMIES + "boss_main.png"), Vector2(1030, 790),
        {"scale": 2.0, "flip": true})
    var head: Vector2 = stage.head_of(boss)
    var over := Rect2(head.x - 100, head.y - 80, 300, 60)
    var bp: PanelContainer = stage.say_at(boss, "I am the boss.", 2400, [over])
    assert_eq(bp.position, Vector2(over.position.x, over.end.y + SceneStage.CROWD_AIR),
        "a boss speaker hangs its plate at the boss plate's bottom-left")
    # `set_keep_out` covers every later line without the caller repeating it.
    stage.set_keep_out([Rect2(0, 280, 352, 200)])
    var again: PanelContainer = stage.say_at(front, "Again.", 2400)
    assert_false(Rect2(again.position, again.size).intersects(Rect2(0, 280, 352, 200)),
        "the stage's own keep-out list applies to a call that passes none")


func test_no_two_figures_on_the_marks_overlap_by_more_than_a_quarter() -> void:
    # UI-21 / BL-103: the widest class strip in every slot of both arenas, and
    # the 2x Main Boss on its mark — no two body rects overlap by more than a
    # quarter of the narrower, so twelve figures read as twelve and the boss
    # stands clear of the front rank.
    for scene in ARENAS:
        var stage := SceneStage.from_data(scene, _scene_json(scene))
        _built.append(stage)
        var by_id: Dictionary = stage.place_party(_party_on(scene))
        var m: Dictionary = SceneStage.marks(scene)
        var bm: Dictionary = m["boss"]
        var sc := float(bm.get("scale", 1.0))
        assert_almost(sc, 2.0, 0.001, "%s: the boss is 2x (BL-103)" % scene)
        var pos: Array = bm["pos"]
        var tex: Texture2D = load(ENEMIES + "boss_main.png")
        var feet: float = RaidViewScreen.boss_feet_y(tex.get_height(), scene)
        var boss: Node2D = stage.place_boss(tex, Vector2(float(pos[0]), feet),
            {"scale": sc, "flip": bool(bm.get("flip", false))})
        var bodies: Dictionary = {}
        for id in by_id:
            bodies[id] = _body_rect(by_id[id])
        bodies["boss"] = _body_rect(boss)
        var bad: Array[String] = []
        var ids: Array = bodies.keys()
        for i in ids.size():
            for j in range(i + 1, ids.size()):
                var share := _overlap_share(bodies[ids[i]], bodies[ids[j]])
                if share > 0.25:
                    bad.append("%s: %s and %s overlap by %d%%" % [scene, ids[i], ids[j], int(share * 100.0)])
        assert_eq(bad.size(), 0, "figures on the marks overlap: " + "; ".join(bad))
        # BL-103's two numbers: a 400px footprint clears the front rank by 24
        # and, on the cave, the ledge lantern's flame sprite entirely.
        var front_right := -INF
        var front_y := -INF
        for id in by_id:
            front_y = maxf(front_y, (by_id[id] as Node2D).position.y)
        for id in by_id:
            var spr: Node2D = by_id[id]
            if spr.position.y >= front_y - 1.0:
                front_right = maxf(front_right, _body_rect(spr).end.x)
        var wide_left := float(pos[0]) - 200.0
        assert_true(wide_left - front_right >= 24.0,
            "%s: a 400px boss (from x %.0f) clears the front rank's right edge %.0f by 24" % [scene, wide_left, front_right])
        if scene == "stage_arena_cave":
            var flames := 0
            for prop in _scene_json(scene).get("props", []):
                var pp: Array = prop.get("pos", [0, 0])
                if int(pp[0]) == 1244:
                    flames += 1
                    var flame := Rect2(float(pp[0]) - 8.0, float(pp[1]) - 24.0, 16.0, 24.0)
                    assert_false(Rect2(wide_left, flame.position.y, 400.0, 24.0).intersects(flame),
                        "the cave boss's 400px footprint clears the ledge lantern's flame")
            assert_eq(flames, 1, "the ledge lantern is still on the cave")
        # In front of the fence: the boss stands on its mark's floor.
        assert_true(boss.position.y >= float((bm["floor"] as Array)[1]), "%s: on its floor" % scene)


func test_the_overhead_stack_hides_on_a_back_rank_unless_the_figure_acts() -> void:
    # BL-137 (UI-21's extension of Q07): badge + pips on every figure, but a
    # figure behind the front rank shows its stack only when it carries the
    # bar (the acting or struck one); the front rank always shows.
    var stage := SceneStage.from_data("stage_arena_cave", _scene_json("stage_arena_cave"))
    _built.append(stage)
    var by_id: Dictionary = stage.place_party(_party_on("stage_arena_cave"))
    var front_y := -INF
    for id in by_id:
        front_y = maxf(front_y, (by_id[id] as Node2D).position.y)
    var shown_front := 0
    var hidden_back := 0
    for id in by_id:
        var spr: Node2D = by_id[id]
        var box: Control = stage.bar_for(spr, 40.0, 100.0, null, {"bar": false, "pips": [Color.RED]})
        if spr.position.y >= front_y - 1.0:
            assert_false(stage.in_back_rank(spr))
            assert_true(box.visible, "%s stands in the front rank and wears its badge" % id)
            shown_front += 1
        else:
            assert_true(stage.in_back_rank(spr))
            assert_false(box.visible, "%s stands behind and its stack hides" % id)
            hidden_back += 1
            var acting: Control = stage.bar_for(spr, 40.0, 100.0, null, {"bar": true})
            assert_true(acting.visible, "the acting or struck figure shows its stack wherever it stands")
    assert_eq(shown_front, 4, "one front rank of four")
    assert_eq(hidden_back, 8, "two ranks behind it")
    # A figure the screen places on its own is never 'behind'.
    var lone := _stage({})
    var one: Dictionary = lone.place_party([{"who": "warrior", "pos": [300, 700], "id": "x"}])
    assert_true(lone.bar_for(one["x"], 1.0, 2.0, null, {"bar": false}).visible)


func test_the_boss_head_is_the_top_of_its_frame_at_its_scale() -> void:
    # UI-34: `head_of` on the strip boss is the top of the AnimatedSprite2D's
    # frame rect (at 2x), so the numbers land on the creature, not 60px off it.
    var stage := _stage({})
    var boss: Node2D = stage.place_boss(load(ENEMIES + "boss_main.png"), Vector2(1030, 790),
        {"scale": 2.0, "flip": true})
    assert_true(boss is AnimatedSprite2D)
    var frame := _body_rect(boss)
    var head: Vector2 = stage.head_of(boss)
    assert_true(head.y >= frame.position.y - 0.01 and head.y <= frame.position.y + 10.0,
        "the head %s lies in the frame rect's top 10px (%s)" % [head, frame])
    assert_almost(head.x, frame.get_center().x, 0.01, "centred on the creature")
    # And the numbers stack there, disjoint.
    var n1 := Label.new()
    n1.text = "-842"
    var n2 := Label.new()
    n2.text = "-4"
    stage.number_at(boss, n1)
    stage.number_at(boss, n2)
    assert_false(Rect2(n1.position, n1.size).intersects(Rect2(n2.position, n2.size)))
    assert_true(n1.position.y + n1.size.y <= head.y + 0.01, "over the frame's top")


func test_no_tavern_figure_stands_on_the_furniture() -> void:
    # UI-07: the speaker stood on the long table's bench. `furniture` lists the
    # plate's table tops, the long tables' benches and the bar as [x,y,w,h];
    # no actor mark lies inside one (strictly — a mark on an edge is beside it).
    var d := _scene_json("stage_tavern")
    var furniture: Array = d.get("furniture", [])
    assert_true(furniture.size() >= 6, "the tavern names its tables and its bar")
    var bad: Array[String] = []
    for f in furniture:
        assert_true(f is Array and f.size() == 4, "a furniture rect is [x, y, w, h]")
        var r := Rect2(float(f[0]), float(f[1]), float(f[2]), float(f[3]))
        assert_true(Rect2(0, 0, 1536, 1024).encloses(r), "on the plate")
        for a in d.get("actors", []):
            var pos: Array = a.get("pos", [0, 0])
            var x := float(pos[0])
            var y := float(pos[1])
            if x > r.position.x and x < r.end.x and y > r.position.y and y < r.end.y:
                bad.append("%s at %s stands on %s" % [a.get("who", "?"), pos, f])
    assert_eq(bad.size(), 0, "figures on the furniture: " + "; ".join(bad))
    # The speaker's plate is sized for a 1x figure: the SMALL face, a 140px wrap.
    var stage := SceneStage.from_data("stage_tavern", d)
    _built.append(stage)
    var speaker: AnimatedSprite2D = _actor_nodes(stage)[0]
    var plate: PanelContainer = stage.say_at(speaker, "I have killed a rat. Professionally.", 2400)
    var label: Label = Widgets.content_of(plate).get_child(0) as Label
    assert_eq(label.custom_minimum_size.x, float(SceneStage.SAY_WRAP_1X), "a 1x scene wraps the line at 140")
    assert_eq(String(label.theme_type_variation), "LabelSmall", "at Type.SMALL")
    var scene_plate := _speech_plate(stage)
    assert_true(scene_plate != null, "the tavern's own speaking plate is built")
    if scene_plate != null:
        # The scene's own plate carries the SAME line width as `say_at`'s on a
        # 1x scene: `speech.size` is the authored box and `_place_speech` hands
        # the Label `size.x - 16`. (The outer plate lands wider than the box —
        # PanelBubble's stylebox adds 20px a side — which is why the LINE is
        # what is asserted; a plate's outer width is the kit's arithmetic.)
        var scene_label: Label = Widgets.content_of(scene_plate).get_child(0) as Label
        assert_eq(scene_label.custom_minimum_size.x, float(SceneStage.SAY_WRAP_1X),
            "the scene's line wraps where say_at's does on a 1x scene")
        assert_true(scene_plate.size.x < 196.0,
            "and the plate is narrower than the 2x scenes' floor, got %s" % scene_plate.size)


func test_arena_for_sends_raids_to_the_dungeon_and_the_rest_to_the_cave() -> void:
    # UI-54 / Q-96 (RESOLVED) / CRITIC-C15: the tier row's `scene` when it
    # names one, else the kind rule — E-slots in the dungeon, A-slots and the
    # tutorials in the cave; null falls back to DEFAULT_ARENA.
    var db = _content()
    assert_true(db != null)
    var raids: Array = db.raid_encounters(1)
    var adventures: Array = db.adventure_encounters(1)
    var tutorials: Array = db.tutorial_encounters(1)
    assert_true(raids.size() >= 5 and adventures.size() >= 3 and tutorials.size() >= 2, "Tier 1's twelve")
    for e in raids:
        assert_eq(SceneStage.arena_for(e), "stage_arena_dungeon", "%s fights in the dungeon" % e.slot)
    for e in adventures + tutorials:
        assert_eq(SceneStage.arena_for(e), "stage_arena_cave", "%s fights in the cave" % e.slot)
    assert_eq(SceneStage.arena_for(null), SceneStage.DEFAULT_ARENA, "no encounter, the fallback")
    # Both answers are scene files on disk, and the tier row agrees with the rule.
    assert_true(FileAccess.file_exists(SCENES + "stage_arena_dungeon.json"))
    assert_true(FileAccess.file_exists(SCENES + "stage_arena_cave.json"))
    assert_eq(ContentDB.tier_scene(1, "raid"), "stage_arena_dungeon")
    assert_eq(ContentDB.tier_scene(1, "adventure"), "stage_arena_cave")
    assert_eq(ContentDB.tier_scene(2, "raid"), "", "a pending tier names no plate and inherits the kind rule")
    # A tier with no row falls through to the kind rule.
    var stub := StubEncounter.new()
    stub.slot = "E9"
    stub.tier = 9
    assert_eq(SceneStage.arena_for(stub), "stage_arena_dungeon")
    stub.slot = "A9"
    assert_eq(SceneStage.arena_for(stub), "stage_arena_cave")
    stub.slot = "TR"
    assert_eq(SceneStage.arena_for(stub), "stage_arena_cave")


class StubEncounter extends RefCounted:
    var slot := ""
    var tier := 1
