extends SceneTree
## Loads every .gd under sim/, game/, tools/ and tests/ so that parse errors in
## files no test happens to touch still fail the build.

const ROOTS := ["res://sim", "res://game", "res://tools", "res://tests"]

## SceneTree entrypoints: reload() on the running script returns ERR_BUSY.
const SELF_EXCLUDED := [
    "res://tools/parse_check.gd",
    "res://tests/run_tests.gd",
    "res://tools/balance_sweep.gd",
]

func _initialize() -> void:
    var files: Array[String] = []
    for r in ROOTS:
        files.append_array(_walk(r))
    files.sort()
    var bad: Array[String] = []
    # Hoisted: this scans every project setting, and it does not change.
    var autoloads := _autoload_scripts()
    for f in files:
        # run_tests/parse_check are SceneTree entrypoints; loading is still valid.
        var res = load(f)
        if res == null:
            bad.append("%s (failed to load)" % f)
            continue
        # load() succeeds while a script still has parse errors — Godot surfaces
        # those on GDScript::reload(). That blind spot let seven type-inference
        # errors in RaidSim.gd pass this gate green, so reload() is the real
        # check. It was tried once before and reverted because it false-positives
        # on a script's own class_name; that is no longer an issue because sim/
        # constructs through _cls() and never names itself.
        # A script cannot reload itself while it is the one running, and the
        # other SceneTree entrypoints are executed directly rather than imported.
        if f in autoloads:
            # An autoload has a live instance for the whole run, and
            # GDScript::reload() refuses while instances exist (error 22).
            #
            # ResourceLoader.load(CACHE_MODE_IGNORE) is NOT a substitute: it was
            # tried here and returned a valid-looking GDScript for a file with a
            # type-inference error, i.e. it reproduced the exact false-green this
            # whole gate exists to prevent. Verified by reintroducing the bug.
            #
            # A detached GDScript built from the source has no instances, so
            # reload() runs and reports parse errors the same as anywhere else.
            var probe := GDScript.new()
            probe.source_code = FileAccess.get_file_as_string(f)
            var perr: int = probe.reload()
            if perr != OK:
                bad.append("%s (autoload compile error %d)" % [f, perr])
            continue
        if f in SELF_EXCLUDED:
            # Not skipped — probed the same way as an autoload. Skipping them
            # outright left a hole this gate exists to close: a type-inference
            # error sat in tools/balance_sweep.gd for two commits, invisible
            # here, and only surfaced as a FAILED STAGE 5 at the end of a
            # two-minute gate run. A detached GDScript has no instances, so
            # reload() reports its parse errors like any other script's.
            var self_probe := GDScript.new()
            self_probe.source_code = FileAccess.get_file_as_string(f)
            var self_err: int = self_probe.reload()
            if self_err != OK:
                bad.append("%s (compile error %d — run it standalone to see why)" % [f, self_err])
            continue
        if res is GDScript:
            var err: int = res.reload()
            if err != OK:
                bad.append("%s (compile error %d — run it standalone to see why)" % [f, err])
    print("PARSE_CHECK scanned %d script(s)" % files.size())
    if bad.is_empty():
        print("PARSE_CHECK OK")
        quit(0)
        return          # quit() only REQUESTS a quit; without this we fall
                        # through and print a bogus failure with exit code 1
    for b in bad:
        print("  PARSE FAIL  " + b)
    print("PARSE_CHECK FAILED (%d)" % bad.size())
    quit(1)

func _walk(dir_path: String) -> Array[String]:
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
                out.append_array(_walk(full))
        elif name.ends_with(".gd"):
            out.append(full)
        name = d.get_next()
    d.list_dir_end()
    return out


## Scripts registered as autoloads in project.godot. They cannot be reload()ed
## because their instance is alive for the entire run.
static func _autoload_scripts() -> Array:
    var out: Array = []
    for setting in ProjectSettings.get_property_list():
        var name: String = String(setting.get("name", ""))
        if not name.begins_with("autoload/"):
            continue
        var value := String(ProjectSettings.get_setting(name, ""))
        if value.begins_with("*"):
            value = value.substr(1)
        if value.ends_with(".gd"):
            out.append(value)
    return out
