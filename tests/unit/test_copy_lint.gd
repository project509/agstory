extends "res://tests/TestCase.gd"
## The copy lint, in-process (W6-COPY; ship plan 00 §0.2).
##
## `tools/lint_copy.sh` is the gate (verify.sh stage 1) and this file is the same
## rule re-implemented in GDScript so `RUN_TESTS_ONLY=copy_lint` catches a new
## player-facing string about the build in seconds, without the shell. The two
## read ONE word list and ONE allow-list — both parsed out of the shell script's
## text between its WORDS-BEGIN/END and ALLOW-BEGIN/END markers — so they cannot
## drift apart; the rule itself (comment lines skipped, trailing comments cut,
## developer-output lines skipped, every "…" literal searched) is restated here
## line for line with the script's header.
##
## An allow-list entry that matches nothing is a failure here too: the allow-list
## is the only place those strings may live, and an entry with no string behind
## it is a lie about the tree.

const LINT := "res://tools/lint_copy.sh"
const ROOT := "res://game"
const DEV_OUTPUT := ["push_error(", "push_warning(", "printerr(", "printt(", "print(", "assert("]


func _lint_text() -> String:
    assert_true(FileAccess.file_exists(LINT), "the copy lint script exists")
    return FileAccess.get_file_as_string(LINT)


## The quoted entries between two marker lines of the script.
func _block(text: String, begin: String, end: String) -> Array:
    var at := text.find(begin)
    var stop := text.find(end, at)
    assert_true(at >= 0 and stop > at, "markers %s / %s in the script" % [begin, end])
    var out: Array = []
    for line in text.substr(at, stop - at).split("\n"):
        var s := String(line).strip_edges()
        if s.begins_with("\"") and s.ends_with("\""):
            out.append(s.substr(1, s.length() - 2))
    return out


func _words() -> Array:
    return _block(_lint_text(), "# WORDS-BEGIN", "# WORDS-END")


func _allow() -> Array:
    return _block(_lint_text(), "# ALLOW-BEGIN", "# ALLOW-END")


func _gd_files(dir: String, out: Array) -> void:
    var d := DirAccess.open(dir)
    if d == null:
        return
    d.list_dir_begin()
    var name := d.get_next()
    while name != "":
        var path := dir.path_join(name)
        if d.current_is_dir():
            if not name.begins_with("."):
                _gd_files(path, out)
        elif name.ends_with(".gd"):
            out.append(path)
        name = d.get_next()
    d.list_dir_end()


## The line with its trailing comment cut, or "" for a comment line.
func _code_of(line: String) -> String:
    if line.strip_edges().begins_with("#"):
        return ""
    var out := ""
    var inq := false
    for i in line.length():
        var c := line[i]
        if c == "\"":
            inq = not inq
        if c == "#" and not inq:
            break
        out += c
    return out


func _literals(code: String) -> Array:
    var out: Array = []
    var rx := RegEx.new()
    rx.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
    for m in rx.search_all(code):
        out.append(m.get_string(1))
    return out


## Every hit under game/: [{path, line, word, literal}].
func _hits(words: Array) -> Array:
    var files: Array = []
    _gd_files(ROOT, files)
    assert_true(files.size() > 20, "the walk found game/'s scripts (%d)" % files.size())
    assert_true(files.has("res://game/screens/Town.gd"), "the walk reaches the screens")
    var out: Array = []
    for path in files:
        var lines := FileAccess.get_file_as_string(path).split("\n")
        for i in lines.size():
            var code := _code_of(String(lines[i]))
            if code.is_empty():
                continue
            var dev := false
            for call in DEV_OUTPUT:
                if code.contains(call):
                    dev = true
            if dev:
                continue
            for lit in _literals(code):
                var low := String(lit).to_lower()
                for w in words:
                    if low.contains(String(w)):
                        out.append({"path": String(path).trim_prefix("res://"), "line": i + 1,
                            "word": String(w), "literal": String(lit)})
                        break
    return out


func test_the_word_list_is_the_plans() -> void:
    var words := _words()
    for w in ["this build", "this version", "not built", "not written", "module", "canon",
            "fixture", "audit", "docs/", "export build", "type pass", "arrive with",
            "arrives with", "sign-off", "name pending"]:
        assert_true(words.has(w), "ship plan §0.2's word '%s' is in the lint" % w)
    assert_eq(words.size(), 15, "and nothing else")


func test_no_player_facing_string_under_game_admits_an_unfinished_feature() -> void:
    var words := _words()
    var allow := _allow()
    var used := {}
    var bad: Array = []
    for h in _hits(words):
        var allowed := ""
        for entry in allow:
            var path := String(entry).get_slice("|", 0)
            var frag := String(entry).substr(path.length() + 1)
            if path == String(h["path"]) and String(h["literal"]).contains(frag):
                allowed = String(entry)
                break
        if allowed.is_empty():
            bad.append("%s:%d says \"%s\" — %s" % [h["path"], h["line"], h["word"], h["literal"]])
        else:
            used[allowed] = true
    assert_eq(bad, [], "a player has no build, no module, no docs and no audit:\n%s"
        % "\n".join(PackedStringArray(bad)))
    var stale: Array = []
    for entry in allow:
        if not used.has(entry):
            stale.append(String(entry))
    assert_eq(stale, [], "allow-list entries with no string behind them")


func test_the_lint_catches_a_reintroduced_sentence() -> void:
    # The detector, proved on the shape it exists for: a Label literal naming
    # the build, a docs path in a Button, a developer-output line that is NOT
    # a hit, a comment that is NOT a hit.
    var words := _words()
    var sample := [
        "\tvar l := Widgets.label_as(\"Disabled in this build.\", \"LabelSmall\")",
        "\tbtn.text = \"See docs/13 for the rest\"  # a trailing comment about canon",
        "\tpush_error(\"GameState: not a declared flag (docs/14 §5.2)\")",
        "\t# Canon lists this one as a maybe. Disabled in this build.",
        "\tvar ok := Widgets.label_as(\"Closed. The smith took a better offer.\", \"LabelSmall\")",
    ]
    var found: Array = []
    for line in sample:
        var code := _code_of(String(line))
        if code.is_empty():
            continue
        var dev := false
        for call in DEV_OUTPUT:
            if code.contains(call):
                dev = true
        if dev:
            continue
        for lit in _literals(code):
            for w in words:
                if String(lit).to_lower().contains(String(w)):
                    found.append(String(w))
                    break
    assert_eq(found, ["this build", "docs/"], str(found))


func test_verify_runs_the_lint_and_the_script_says_ok_or_failed() -> void:
    var verify := FileAccess.get_file_as_string("res://tools/verify.sh")
    assert_true(verify.contains("lint_copy.sh"), "stage 1 runs the copy lint")
    var text := _lint_text()
    assert_true(text.contains("COPY LINT OK"), "the verdict verify greps for")
    assert_true(text.contains("COPY LINT FAILED"))
