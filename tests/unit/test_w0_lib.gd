extends "res://tests/TestCase.gd"

## W0-LIB: the generated-art gate exists and is wired, as text (the same shape
## as test_motion.gd's check of the motion lint). Bytes are proved by the gate
## itself; this only asserts the gate cannot be silently removed.


func test_verify_runs_the_generated_art_check() -> void:
    var gate := FileAccess.get_file_as_string("res://tools/verify.sh")
    assert_true(gate.contains("2b/8"), "verify.sh must carry stage 2b")
    assert_true(gate.contains("build_art.sh --check"), "and run build_art.sh --check")
    assert_true(gate.contains("ART CHECK OK"), "and read its verdict line")


func test_build_art_checks_through_the_script_param_redirect() -> void:
    var build := FileAccess.get_file_as_string("res://tools/build_art.sh")
    assert_true(build.contains("--script-param"), "--check redirects with --script-param out=")
    assert_false(build.contains("--sheet-type packed"), "the build/atlas export loop is gone (W0-LIB ruling)")
    var lib := FileAccess.get_file_as_string("res://tools/aseprite/lib.lua")
    assert_true(lib.contains("function L.out_path"), "lib.lua honours the out= prefix")
    assert_true(lib.contains("function L.strip"), "and authors real strips")


func test_gen_icons_lives_with_the_other_generators() -> void:
    assert_true(FileAccess.file_exists("res://tools/aseprite/gen_icons.lua"), "gen_icons.lua moved to tools/aseprite/")
    assert_false(FileAccess.file_exists("res://tools/art/gen_icons.lua"), "and the old path is gone")
