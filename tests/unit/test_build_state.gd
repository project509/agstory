extends "res://tests/TestCase.gd"
## BUILD_STATE.md is the loop's memory, and nothing held its shape: it had grown to
## 325 lines against its own "under ~250" three times over (audit M6-FINAL-03), it
## contradicted itself about how many stages verify.sh has, and the paths it named
## were checked by nobody. This file holds the length rule, the section set a new
## session is told to read, and that every path or command the file names exists.
##
## It asserts the SHAPE, not the truth of the prose (LESSONS: "do not write a test
## that asserts the plan is accurate") — a path that is gone is a fact, a paragraph
## that is stale is a judgement.

const PATH := "res://BUILD_STATE.md"
const MAX_LINES := 250
const MAX_RECENT := 12

## The headings a new session is sent to, in the order the file keeps them.
const SECTIONS := [
    "## Current focus",
    "## HANDOFF — read this first in a new session",
    "## Binding decisions (from `docs/15-open-questions.md` §9)",
    "## Invariants — never break these",
    "## Key commands",
    "## Key paths",
    "## Architecture at a glance",
    "## Environment notes",
    "## Recent progress",
    "## Open risks the loop should watch",
]

## Strings the file must carry after M6-FINAL-03's pass: the reconciled sweep count,
## the two rulings the ship tooling waits on (each as its register id AND its wording,
## so the id cannot quietly point at the wrong question), the export command with
## its dev flag. The ids are built, not written: test_docs_links.gd reads a literal
## Q-nn in code as a citation into the range where Q and BL overlap, and these are
## not citations, they are the strings the file is required to carry.
const MUST_MENTION := ["2,304 runs", "288 cells", "./tools/export_build.sh --dev",
    "Tiers 2-5", "Ship tooling",
    "Q-%d" % 53, "are attempts limited",
    "Q-%d" % 29, "rolled gear price the recruit"]

## Paths the file names AS ABSENT, with the sentence that says so; anything else
## that is missing is a dead citation.
const ALLOWED_ABSENT := {
    "build/exports/AGuildStory.exe": "is gone until `./tools/export_build.sh --dev`",
}

var _text := ""
var _lines: PackedStringArray = []


func before_each() -> void:
    _text = FileAccess.get_file_as_string(PATH).replace("\r\n", "\n")
    _lines = _text.split("\n")


func test_the_length_rule() -> void:
    var n := _lines.size()
    if _text.ends_with("\n"):
        n -= 1
    assert_true(n <= MAX_LINES, "BUILD_STATE.md is %d lines; its rule is under %d — move history to docs/_log/progress.md" % [n, MAX_LINES])
    assert_true(n > 100, "BUILD_STATE.md is %d lines — the read failed or the file was gutted" % n)


func test_the_sections_a_new_session_is_sent_to_are_present_in_order() -> void:
    var last := -1
    for h in SECTIONS:
        var i := _text.find("\n" + String(h) + "\n")
        assert_true(i >= 0, "BUILD_STATE.md lost its section: " + String(h))
        assert_true(i > last, "section out of order: " + String(h))
        last = i


func test_the_records_the_audit_asked_for_are_there() -> void:
    for m in MUST_MENTION:
        assert_true(_text.contains(String(m)), "BUILD_STATE.md no longer says: " + String(m))
    # One stage count, not two: verify.sh has ten hdr() stages and the file said 10, 8 and "8-stage" at once.
    assert_false(_text.contains("Eight stages") or _text.contains("8-stage"), "verify.sh has ten stages; the file still says eight somewhere")


func test_the_recent_progress_list_is_short() -> void:
    var i := _text.find("\n## Recent progress\n")
    var j := _text.find("\n## ", i + 1)
    var block := _text.substr(i, j - i)
    var entries := 0
    for l in block.split("\n"):
        if l.begins_with("- "):
            entries += 1
    assert_true(entries >= 1 and entries <= MAX_RECENT, "Recent progress has %d entries; the rule is 1..%d" % [entries, MAX_RECENT])


## Every `path/like/this` in inline code resolves on disk, relative to the project
## root: a file, a directory, a glob (`docs/00-*.md`), or a bare doc number
## (`docs/05` means docs/05-*.md). Placeholders (`<KEY>`), URL schemes, absolute
## machine paths and shell fragments with `//` are not paths and are skipped.
func test_every_path_the_file_names_exists() -> void:
    var seen := 0
    var missing: Array[String] = []
    for tok in _code_spans():
        var t := tok.strip_edges().trim_suffix(":").trim_suffix(",").trim_suffix(".")
        if not _looks_like_path(t):
            continue
        seen += 1
        if ALLOWED_ABSENT.has(t):
            assert_true(_text.contains("`%s` %s" % [t, ALLOWED_ABSENT[t]]), "%s is exempt only while the file says it is absent" % t)
            continue
        if not _resolves(t):
            missing.append(t)
    assert_true(seen >= 30, "only %d path-like code spans found — the scan is broken" % seen)
    assert_eq(missing.size(), 0, "BUILD_STATE.md names paths that are not in the tree: %s" % [missing])


## Every command in the ```bash block and every `./tools/x.sh` / `python tools/x.py`
## in prose names a script that exists (the audit's own acceptance line).
func test_every_command_the_file_names_exists() -> void:
    var cmds: Array[String] = []
    var in_bash := false
    for l in _lines:
        if l.begins_with("```bash"):
            in_bash = true
            continue
        if in_bash and l.begins_with("```"):
            in_bash = false
            continue
        if in_bash and not l.strip_edges().is_empty() and not l.begins_with("#"):
            cmds.append(l.strip_edges())
    for span in _code_spans():
        var s := span.strip_edges()
        if s.begins_with("./tools/") or s.begins_with("python tools/"):
            cmds.append(s)
    assert_true(cmds.size() >= 12, "only %d commands found — the scan is broken" % cmds.size())
    var missing: Array[String] = []
    for c in cmds:
        var words := c.split(" ", false)
        for w in words:
            var ww := String(w)
            var script := ""
            if ww.begins_with("./tools/") or ww.begins_with("tools/"):
                script = ww.trim_prefix("./")
            elif ww.begins_with("res://"):
                script = ww.trim_prefix("res://")
            if script.is_empty() or script.contains("<"):
                continue
            if not FileAccess.file_exists("res://" + script):
                missing.append(script)
    assert_eq(missing.size(), 0, "BUILD_STATE.md's commands name scripts that are not in the tree: %s" % [missing])


# ---------------------------------------------------------------- helpers

func _code_spans() -> Array[String]:
    var out: Array[String] = []
    var re := RegEx.new()
    re.compile("`([^`\\n]+)`")
    for m in re.search_all(_text):
        out.append(m.get_string(1))
    return out


func _looks_like_path(t: String) -> bool:
    if not t.contains("/"):
        return false
    if t.contains("<") or t.contains("://") or t.contains("//") or t.begins_with("/") or t.begins_with("-"):
        return false
    if t.begins_with("~") or t.contains("..") or t.contains("NN"):
        return false   # a home path, a range (`00..11`), a numbered-doc placeholder
    if t[0] == t[0].to_upper() and t[0] != t[0].to_lower():
        return false   # `M5-TUT-04/-05`: ids, not a path — every path here starts lower-case or with a dot
    if t.contains(" ") and not t.ends_with(".png"):
        return false   # a shell line, not a path (the one spaced path is an ideaboard glob)
    if t.begins_with("(") or t.contains("=") or t.contains("$"):
        return false
    return true


func _resolves(t: String) -> bool:
    var rel := t.trim_prefix("./")
    if rel.contains("*"):
        return _glob_hits(rel)
    if FileAccess.file_exists("res://" + rel) or DirAccess.dir_exists_absolute("res://" + rel):
        return true
    # `game/screens/RaidView` — a screen named without its extension (Binding decisions, verbatim).
    if FileAccess.file_exists("res://" + rel + ".gd") or FileAccess.file_exists("res://" + rel + ".tscn"):
        return true
    # `docs/05` — a doc by number; `docs/05-morale.md` is the file.
    var re := RegEx.new()
    re.compile("^docs/(\\d\\d)$")
    var m := re.search(rel)
    if m != null:
        return _glob_hits("docs/%s-*.md" % m.get_string(1))
    return false


## A one-star glob in the last path segment, matched against the directory listing.
func _glob_hits(pattern: String) -> bool:
    var dir := pattern.get_base_dir()
    var pat := pattern.get_file()
    if dir.contains("*"):
        return false
    var d := DirAccess.open("res://" + dir)
    if d == null:
        return false
    for name in d.get_files():
        if String(name).match(pat):
            return true
    for name in d.get_directories():
        if String(name).match(pat):
            return true
    return false
