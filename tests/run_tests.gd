extends SceneTree
## Headless test runner.  Usage:
##   Godot --headless --path . --script res://tests/run_tests.gd

const UNIT_DIR := "res://tests/unit"

func _initialize() -> void:
    # The autosave triggers mean the suite writes real save files. Point them somewhere
    # disposable BEFORE any test runs, or a dev machine's own guild gets overwritten by
    # `./tools/verify.sh` — see docs/15 BL-56.
    var SaveGame = load("res://game/core/SaveGame.gd")
    SaveGame.SAVE_DIR = "user://test_saves"
    SaveGame.purge_all()
    # Same for the options file: GameSettings saves on PREDELETE, and the
    # autoload's PREDELETE is the runner's quit — so without this every
    # verify.sh run left the developer's settings.cfg holding whatever the last
    # test set (measured: text_scale 100, reduced_motion true). Not under
    # test_saves/: test_settings.gd pins that options never live with saves.
    var GameSettings = load("res://game/core/GameSettings.gd")
    GameSettings.PATH = "user://test_settings.cfg"
    DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))

    var files := _discover(UNIT_DIR)
    files.sort()
    # RUN_TESTS_ONLY=<substring>[,<substring>] keeps only the files whose name
    # contains one of them (e.g. RUN_TESTS_ONLY=test_audit_hygiene). The whole
    # suite is ~1 to 3 minutes on this machine; one file is seconds, and every
    # wave's agents had been writing their own one-file runners around that.
    var only := OS.get_environment("RUN_TESTS_ONLY")
    if not only.is_empty():
        var wanted: PackedStringArray = only.split(",", false)
        var kept: Array[String] = []
        for f in files:
            for w in wanted:
                if String(f).get_file().contains(w.strip_edges()):
                    kept.append(f)
                    break
        files = kept
        print("RUN_TESTS_ONLY=%s -> %d file(s)" % [only, files.size()])

    var total := 0
    var failed_tests := 0
    var failures: Array[String] = []
    var t0 := Time.get_ticks_msec()

    # RUN_TESTS_TIMING=1 prints the slowest files at the end (a five-fold slowdown
    # once hid inside two new files; a whole-suite number cannot say where).
    var timing := OS.get_environment("RUN_TESTS_TIMING") != ""
    var per_file: Array = []
    for path in files:
        var tf := Time.get_ticks_msec()
        var script = load(path)
        if script == null:
            failures.append("%s :: could not load script" % path)
            failed_tests += 1
            continue
        if not (script is GDScript) or not script.can_instantiate():
            failures.append("%s :: script failed to compile" % path)
            failed_tests += 1
            continue
        var inst = script.new()
        if inst == null:
            failures.append("%s :: could not instantiate" % path)
            failed_tests += 1
            continue
        for m in inst.get_method_list():
            var mname: String = m.name
            if not mname.begins_with("test_"):
                continue
            total += 1
            inst._reset()
            if inst.has_method("before_each"):
                inst.before_each()
            inst.call(mname)
            if inst.has_method("after_each"):
                inst.after_each()
            var errs: Array = inst.get_failures()
            if errs.size() > 0:
                failed_tests += 1
                for e in errs:
                    failures.append("%s :: %s\n      %s" % [path.get_file(), mname, e])
        per_file.append([path.get_file(), Time.get_ticks_msec() - tf])

    var dt := Time.get_ticks_msec() - t0
    if timing:
        per_file.sort_custom(func(a, b): return a[1] > b[1])
        print("slowest files:")
        for row in per_file.slice(0, 12):
            print("  %6d ms  %s" % [row[1], row[0]])

    print("")
    print("──────────────────────────────────────────────")
    if failures.is_empty():
        print("TESTS PASSED   %d test(s) in %d file(s)  [%d ms]" % [total, files.size(), dt])
        print("──────────────────────────────────────────────")
        quit(0)
    else:
        for f in failures:
            print("  FAIL  " + f)
        print("")
        print("TESTS FAILED   %d/%d failing  [%d ms]" % [failed_tests, total, dt])
        print("──────────────────────────────────────────────")
        quit(1)

func _discover(dir_path: String) -> Array[String]:
    var out: Array[String] = []
    var d := DirAccess.open(dir_path)
    if d == null:
        return out
    d.list_dir_begin()
    var name := d.get_next()
    while name != "":
        var full := dir_path.path_join(name)
        if d.current_is_dir():
            if not name.begins_with("."):
                out.append_array(_discover(full))
        elif name.begins_with("test_") and name.ends_with(".gd"):
            out.append(full)
        name = d.get_next()
    d.list_dir_end()
    return out
