extends "res://tests/TestCase.gd"
## W5-MOUNT: the mount budget's three strong caches, and the page turn's split.
##
## tools/perf_probe.gd (W4-PERF) found every screen 90-270 ms in `goto()`, and
## its `--split` line found where: the screen's script compiled again on every
## first visit (Godot's resource cache is weak — a freed screen drops its
## PackedScene and the GDScript with it), the 1536x1024 plate and every strip
## re-read from disk on every visit, actors.json parsed once PER ACTOR, and a
## Shader compiled per water quad, per pulse and per vignette (~6 ms each).
## The fixes are caches that hold for the life of the process; these tests
## pin that a second read is a hit, that the objects are the SAME objects,
## and that the one thing a shared SpriteFrames must never do — grow an
## animation under another sprite — is done on a private copy.

const SceneStage = preload("res://game/ui/SceneStage.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Frame = preload("res://game/ui/Frame.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
## For its SCREENS constant only (the one explicit list, LESSONS).
const Smoke = preload("res://tests/unit/a11y_smoke.gd")

const CAMP := "stage_camp"
const CAMP_PLATE := "res://game/assets/bg/stage_camp.png"
const WALKER := "variant_r02_black"
const MAIN_MENU := "res://game/screens/MainMenu.tscn"
const TOWN := "res://game/screens/Town.tscn"

var _root: Node = null
var _made: Array = []


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []


func after_each() -> void:
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


func _host() -> Control:
    var h := Control.new()
    h.name = "TestHost"
    _root.add_child(h)
    _made.append(h)
    return h


func _stage(name: String) -> Control:
    var s: Control = SceneStage.load(name)
    _made.append(s)
    return s


func _sprites(n: Node, out: Array = []) -> Array:
    if n is AnimatedSprite2D:
        out.append(n)
    for c in n.get_children():
        _sprites(c, out)
    return out


# ---------------------------------------------------------------- the same object twice

func test_the_strong_caches_return_the_same_object_for_the_same_path() -> void:
    var a: Texture2D = SceneStage.texture(CAMP_PLATE)
    var b: Texture2D = SceneStage.texture(CAMP_PLATE)
    assert_ne(a, null, "the camp plate loads")
    assert_true(a == b, "SceneStage.texture: one Texture2D per path, held")
    assert_true(ResourceLoader.has_cached(CAMP_PLATE),
        "and the engine's own cache still sees it — nothing has let it go")

    var ia: Texture2D = Icons.at("emote", "mug")
    var ib: Texture2D = Icons.at("emote", "mug")
    assert_ne(ia, null, "the emote glyph loads")
    assert_true(ia == ib, "Icons.at: one Texture2D per glyph, held")

    var wa := Frame.wordmark("wordmark_44")
    var wb := Frame.wordmark("wordmark_44")
    _made.append(wa)
    _made.append(wb)
    assert_ne(wa.texture, null, "the wordmark loads")
    assert_true(wa.texture == wb.texture, "Frame: one wordmark texture per name, held")
    assert_eq(Frame.wordmark_baseline("wordmark_44"), Frame.wordmark_baseline("wordmark_44"),
        "and its baseline metric is read once")


func test_a_missing_path_is_null_and_never_an_error() -> void:
    assert_eq(SceneStage.texture("res://game/assets/bg/no_such_plate.png"), null)
    assert_eq(SceneStage.texture(""), null)


# ---------------------------------------------------------------- the second load reads nothing

func test_loading_a_scene_twice_reads_no_png_and_parses_no_json_the_second_time() -> void:
    var first := _stage(CAMP)
    SceneStage.profile_reset()
    var second := _stage(CAMP)
    var p: Dictionary = SceneStage.profile
    assert_eq(int(p["builds"]), 1, "the counters saw exactly the second build")
    assert_eq(int(p["tex_misses"]), 0, "no texture was read from disk for the second camp")
    assert_true(int(p["tex_hits"]) > 0, "every texture the camp draws came from the cache")
    assert_eq(int(p["frames_misses"]), 0, "no strip was cut again")
    assert_eq(int(p["json_misses"]), 0, "no manifest or scene file was parsed again")
    assert_true(ResourceLoader.has_cached(CAMP_PLATE), "the plate is still held")

    # Not merely "cached somewhere": the second stage draws from the SAME
    # objects as the first — the plate, and every frame of every figure.
    var plate_a: TextureRect = first.get_node("Plate")
    var plate_b: TextureRect = second.get_node("Plate")
    assert_true(plate_a.texture == plate_b.texture, "the two plates are one texture")
    var sa := _sprites(first)
    var sb := _sprites(second)
    assert_true(sa.size() >= 12, "the camp has a crowd (%d sprites)" % sa.size())
    assert_eq(sb.size(), sa.size(), "the same crowd both times")
    var shared := 0
    for i in sa.size():
        var fa: SpriteFrames = (sa[i] as AnimatedSprite2D).sprite_frames
        var fb: SpriteFrames = (sb[i] as AnimatedSprite2D).sprite_frames
        var anim := String(fa.get_animation_names()[0])
        assert_true(fa.get_frame_texture(anim, 0) == fb.get_frame_texture(anim, 0),
            "sprite %d draws frame 0 from the same AtlasTexture both times" % i)
        if fa == fb:
            shared += 1
    assert_true(shared > 0, "the standing figures share their SpriteFrames outright (%d of %d)" % [shared, sa.size()])


func test_two_figures_from_one_strip_share_their_frames_and_keep_their_own_phase() -> void:
    var data := {"actors": [
        {"who": "cleric", "pos": [100, 300], "phase": 0},
        {"who": "cleric", "pos": [200, 320], "phase": 1},
    ]}
    var stage: Control = SceneStage.from_data("share_test", data)
    _made.append(stage)
    var sprites := _sprites(stage)
    assert_eq(sprites.size(), 2)
    var a: AnimatedSprite2D = sprites[0]
    var b: AnimatedSprite2D = sprites[1]
    assert_true(a.sprite_frames == b.sprite_frames, "one SpriteFrames for one strip and one cut")
    assert_ne(a.frame, b.frame, "the phase lives on the sprite, not in the shared frames")
    assert_ne(a.speed_scale, b.speed_scale, "so does the breathing rate")


func test_a_walker_extends_a_private_copy_and_leaves_the_shared_frames_alone() -> void:
    var data := {"actors": [{"who": WALKER, "pos": [100, 300]}],
        "paths": [{"who": WALKER, "points": [[100, 300], [400, 300]], "px_per_s": 20}]}
    var stage: Control = SceneStage.from_data("walk_test", data)
    _made.append(stage)
    var standing: AnimatedSprite2D = null
    var walker: AnimatedSprite2D = null
    for s in _sprites(stage):
        if String(s.name).begins_with("Walker_"):
            walker = s
        elif String(s.name).begins_with("Actor_"):
            standing = s
    assert_ne(walker, null, "the path built a walker")
    assert_ne(standing, null, "and the actor list a standing figure from the same strip")
    assert_true(walker.sprite_frames.has_animation("walk"), "the walker carries its walk")
    assert_false(standing.sprite_frames.has_animation("walk"),
        "the shared idle frames were not grown under the standing figure")
    assert_true(walker.sprite_frames != standing.sprite_frames, "the walker's frames are its own copy")
    assert_true(walker.sprite_frames.get_frame_texture("idle", 0) == standing.sprite_frames.get_frame_texture("idle", 0),
        "but its idle frames are still the shared textures")
    # Build it again: the copy must not have poisoned the cache.
    var again: Control = SceneStage.from_data("walk_test", data)
    _made.append(again)
    for s in _sprites(again):
        if String(s.name).begins_with("Actor_"):
            assert_false(s.sprite_frames.has_animation("walk"), "a second build's standing figure has no walk either")


# ---------------------------------------------------------------- one shader per source

func test_the_water_pulse_and_vignette_shaders_are_compiled_once() -> void:
    var data := {"shimmer": [{"rect": [0, 0, 100, 100]}, {"rect": [200, 0, 100, 100]}],
        "pulse": [{"rect": [0, 200, 50, 50]}, {"rect": [100, 200, 50, 50]}]}
    var a: Control = SceneStage.from_data("shader_a", data)
    var b: Control = SceneStage.from_data("shader_b", data)
    _made.append(a)
    _made.append(b)
    var s0: ShaderMaterial = a.get_node("Shimmer_0").material
    var s1: ShaderMaterial = a.get_node("Shimmer_1").material
    var s2: ShaderMaterial = b.get_node("Shimmer_0").material
    assert_true(s0 != s1, "each quad has its own material (its own uniforms)")
    assert_true(s0.shader == s1.shader and s1.shader == s2.shader, "and all of them one Shader")
    var p0: ShaderMaterial = a.get_node("Pulse_0").material
    var p1: ShaderMaterial = b.get_node("Pulse_1").material
    assert_true(p0.shader == p1.shader, "one pulse Shader")
    assert_true(p0.shader != s0.shader, "which is not the water's")
    var v0: ShaderMaterial = a.get_node("Vignette").material
    var v1: ShaderMaterial = b.get_node("Vignette").material
    assert_true(v0.shader == v1.shader, "one vignette Shader across stages")
    assert_true(s0.get_shader_parameter("noise_tex") == s2.get_shader_parameter("noise_tex"),
        "and one noise texture for every water quad")
    var sizes: Dictionary = SceneStage.cache_sizes()
    assert_true(int(sizes["shaders"]) >= 3, "the shader cache holds water, pulse and vignette")


# ---------------------------------------------------------------- the router

func test_the_router_holds_a_visited_scene_and_the_host_has_one_child_after_two_gotos() -> void:
    _ensure_autoloads()
    var r = Router.new()
    _made.append(r)
    var host := _host()
    r.register_host(host)
    assert_true(r.goto(MAIN_MENU))
    assert_true(r.goto(TOWN))
    assert_eq(host.get_child_count(), 1, "nothing but the current screen is parented to the host")
    assert_true(ResourceLoader.has_cached(MAIN_MENU),
        "the menu's PackedScene is still held after the menu was replaced")
    assert_true(r.goto(MAIN_MENU))
    assert_eq(host.get_child_count(), 1)
    var split: Dictionary = r.last_split()
    for k in ["load", "instantiate", "clear", "build", "on_enter", "focus", "total"]:
        assert_true(split.has(k), "last_split() names phase '%s'" % k)
    assert_true(int(split["load"]) < 5000,
        "a held scene's load phase is microseconds, not a compile (%d us)" % int(split["load"]))


func test_warm_compiles_the_list_ahead_and_then_has_nothing_to_do() -> void:
    _ensure_autoloads()
    var r = Router.new()
    _made.append(r)
    r.register_host(_host())
    var fresh: int = r.warm()
    assert_true(fresh >= 0 and fresh <= Router.WARM_SCENES.size())
    assert_eq(r.warm(), 0, "a second warm() finds every scene held")
    for p in Router.WARM_SCENES:
        assert_true(ResourceLoader.has_cached(String(p)), "%s is held after warm()" % String(p))
    assert_eq(r.warm(["res://game/screens/Nope.tscn"]), 0, "a missing path is skipped, never an error")


func test_stage_warm_holds_every_plate_a_screen_stands_on_and_then_has_nothing_to_do() -> void:
    var fresh: int = SceneStage.warm()
    assert_true(fresh >= 0)
    assert_eq(SceneStage.warm(), 0, "a second warm() loads nothing")
    for n in SceneStage.WARM_SCENES:
        var path := "res://game/assets/scenes/%s.json" % String(n)
        assert_true(FileAccess.file_exists(path), "%s is a scene file" % path)
        var data = JSON.parse_string(FileAccess.get_file_as_string(path))
        var plate := String((data as Dictionary).get("plate", ""))
        assert_true(ResourceLoader.has_cached(plate), "%s's plate %s is held after warm()" % [String(n), plate])
    assert_true(ResourceLoader.has_cached("res://game/assets/vfx/light_soft.png"), "and the light sprite")
    assert_eq(SceneStage.warm(["no_such_scene"]), 0, "an unknown scene loads nothing and is not an error")


func test_the_warm_list_is_the_smoke_list() -> void:
    assert_eq(Router.WARM_SCENES, Smoke.SCREENS,
        "ScreenRouter.WARM_SCENES and a11y_smoke.SCREENS are one list — a screen added to one is added to both")


func test_the_shell_focus_hooks_are_mirrored_in_the_router() -> void:
    assert_eq(Frame.META_FOCUS_ORDER, Router.SHELL_FOCUS_ORDER)
    assert_eq(Frame.META_FOCUS_ENTRY, Router.SHELL_FOCUS_ENTRY)


func test_the_probe_offers_split_and_warm() -> void:
    var probe := FileAccess.get_file_as_string("res://tools/perf_probe.gd")
    assert_true(probe.contains("--split") and probe.contains("last_split"),
        "perf_probe.gd prints goto()'s split")
    assert_true(probe.contains("--warm") and probe.contains("\"warm\""),
        "and can measure the game as Boot leaves it, scenes compiled ahead")
