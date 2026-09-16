extends "res://tests/TestCase.gd"
## W4-PERF: docs/13 §12.1's latency budget has an instrument, the gate runs it,
## and it warns rather than fails — the playtest's shape (verify.sh stage 7/8).
## Both files are read as text, the way test_motion.gd reads the motion lint:
## a stage nobody wired is the failure this unit exists to close (RULES-15,
## audit M6-JUICE-07 — "built" and "armed" are different states, LESSONS).


func test_verify_runs_the_latency_probe_after_the_playtest() -> void:
    var gate := FileAccess.get_file_as_string("res://tools/verify.sh")
    assert_true(gate.contains("res://tools/perf_probe.gd"),
        "tools/verify.sh must run the latency probe")
    assert_true(gate.contains("PERF OK"), "and read its verdict line")
    var playtest := gate.find("7/8  playtest")
    var perf := gate.find("8/8  latency budget")
    assert_true(playtest >= 0 and perf > playtest,
        "the latency stage is its own header, after the playtest")


func test_the_latency_stage_warns_and_never_fails_the_build() -> void:
    var gate := FileAccess.get_file_as_string("res://tools/verify.sh")
    var start := gate.find("8/8  latency budget")
    assert_true(start >= 0, "the stage header is in verify.sh")
    var stage := gate.substr(start)
    var end := stage.find("# ------")
    if end > 0:
        stage = stage.substr(0, end)
    # `bad` is the only thing in verify.sh that sets RC=1; the stage may not call it.
    assert_false(stage.contains("bad "), "the latency stage never calls bad()")
    assert_true(stage.contains("WARN"), "an over-budget probe is reported as WARN")
    assert_true(stage.contains("--fast"), "and skipped under --fast, as the playtest is")
    assert_false(stage.contains("--headless"),
        "the probe needs a real display server; headless renders nothing")


func test_the_probe_judges_the_documented_budget_on_the_smoke_list() -> void:
    var probe := FileAccess.get_file_as_string("res://tools/perf_probe.gd")
    assert_true(probe.contains("MOUNT_BUDGET_MS := 140.0"),
        "docs/13 §12.1 row 2: screen switch settled in 140 ms")
    assert_true(probe.contains("FRAME_BUDGET_MS := 16.6"),
        "the plan's mean-frame number at 1536x1024")
    assert_true(probe.contains("PERF OK") and probe.contains("PERF WARN"),
        "both verdict lines verify.sh reads")
    assert_true(probe.contains("res://tests/unit/a11y_smoke.gd"),
        "the screens are a11y_smoke.SCREENS — one explicit list, never a second one")
    assert_true(probe.contains("res://tools/fixture_reference.gd"),
        "the fixture is shot.gd's seam, never a second fixture")
    assert_true(probe.contains("33 s boosting"),
        "the clock caveat is printed with the numbers")
    var script = load("res://tools/perf_probe.gd")
    assert_true(script is GDScript and script.can_instantiate(),
        "the probe compiles (a SceneTree entry point parse_check cannot reload)")
