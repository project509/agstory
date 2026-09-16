extends "res://tests/TestCase.gd"
## The root README is load-bearing, not decoration: docs/14 §2.5 makes it one of the
## three places the engine pin must agree, docs/14 §10.3 makes it the place a build
## machine learns it needs Aseprite at `Aseprite/Aseprite.exe`, and docs/15 Q-15
## repeats the pin. For a while the file simply did not exist and four documents
## pointed at nothing, which no test noticed.
##
## So this file checks two things a doc reference cannot: that the README still
## carries those facts, and that the facts are TRUE — the pin is read back out of
## project.godot rather than trusted, and every repo path the README cites has to
## exist. A renamed script or a renderer changed in project.godot fails here.

const README := "res://README.md"

var _text := ""
var _project := ""


func before_each() -> void:
    if _text == "":
        _text = _read(README)
    if _project == "":
        _project = _read("res://project.godot")


func _read(path: String) -> String:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return ""
    var s := f.get_as_text()
    f.close()
    return s


func _has(needle: String) -> bool:
    return _text.findn(needle) != -1


func _assert_mentions(needle: String, why: String) -> void:
    assert_true(_has(needle), "README must name %s — %s" % [needle, why])


func test_the_readme_exists_and_says_something() -> void:
    assert_true(FileAccess.file_exists(README), "no README.md at the repo root")
    assert_true(_text.length() > 2000, "README is a stub (%d chars)" % _text.length())
    assert_true(_has("A Guild Story"), "README must name the game")


func test_the_pin_matches_project_godot() -> void:
    # docs/14 §2.5 and docs/15 Q-15: project.godot, docs/14 and the README are the
    # three places, and a pin that disagrees with itself is worse than no pin.
    _assert_mentions("4.7.1", "docs/14 §2.5 — the engine pin")
    _assert_mentions("mono", "the installed build is mono; the project is GDScript only")

    var renderer := _project.get_slice("renderer/rendering_method=\"", 1).get_slice("\"", 0)
    assert_eq(renderer, "mobile", "project.godot's renderer moved; this test's premise did not")
    _assert_mentions(renderer, "the renderer pin, read out of project.godot")

    for key in ["window/size/viewport_width=", "window/size/viewport_height="]:
        var value := _project.get_slice(key, 1).get_slice("\n", 0).strip_edges()
        _assert_mentions(value, "the base viewport, read out of project.godot")


func test_the_build_machine_prerequisites_are_stated() -> void:
    # docs/14 §10.3: Aseprite is gitignored, so the README is the only place a fresh
    # machine is told it must supply the binary and where.
    _assert_mentions("Aseprite/Aseprite.exe", "docs/14 §10.3 — the vendored binary is gitignored")
    _assert_mentions("tools/env.sh", "the one file that knows where the engine is")


func test_the_commands_a_newcomer_needs_are_all_there() -> void:
    var required := {
        "tools/run_game.sh": "how to run it",
        "tools/verify.sh": "how to verify it",
        "tools/with_godot_lock.sh": "the engine mutex",
        "tools/build_art.sh": "how the art is built",
        "tools/diff_all.sh": "the art gate",
    }
    for path in required.keys():
        var why: String = required[path]
        _assert_mentions(path, why)
        assert_true(FileAccess.file_exists("res://" + path), "README cites a missing script: %s" % path)


func test_every_repo_path_the_readme_cites_exists() -> void:
    # The README's whole value is that its commands run as written. A path that no
    # longer exists makes it worse than nothing.
    var re := RegEx.new()
    re.compile("(docs|tools|tests|sim|game|data)/[A-Za-z0-9_./-]+\\.[a-z]+")
    var checked := 0
    for m in re.search_all(_text):
        var path: String = m.get_string()
        assert_true(FileAccess.file_exists("res://" + path), "README cites a path that does not exist: %s" % path)
        checked += 1
    assert_true(checked >= 15, "expected the README to cite real paths; found %d" % checked)


func test_the_reference_concepts_are_named_as_the_bar() -> void:
    _assert_mentions("ideaboard/Reference Concepts", "the quality bar, 1:1 at 1536x1024")
    var dir := DirAccess.open("res://ideaboard/Reference Concepts")
    assert_ne(dir, null, "the reference concepts directory is gone")
    if dir != null:
        assert_true(dir.get_files().size() >= 3, "three reference concepts are expected")


func test_the_working_discipline_a_newcomer_would_break_is_written_down() -> void:
    _assert_mentions("docs/_source/", "canon is never edited")
    _assert_mentions("docs/15-open-questions.md", "an ambiguity gets a numbered entry")
    _assert_mentions("switch", "an ambiguity ships behind one, with the documented default")
    _assert_mentions("BUILD_STATE.md", "the loop's memory")
    _assert_mentions("BACKLOG.md", "the ordered work")
    _assert_mentions("randi()", "docs/14 §3.2 — sim purity, seeded RNG only")
    _assert_mentions("Button.text", "the screen tests read Label and Button text, not node paths")
