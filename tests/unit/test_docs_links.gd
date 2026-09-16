extends "res://tests/TestCase.gd"
## The doc-link lint.
##
## Docs 01-08 were drafted against guessed sibling filenames: 37 distinct slugs
## that were never shipped, 91 links, plus a `docs/00-index.md` named in prose as
## the filename authority and never written. Every one of them survived four
## milestones because nothing checked. This file is the check.
##
## Four separate failure modes, four tests:
##   file targets   — `](04-recruitment-and-roster.md)` must resolve on disk
##   fragments      — `](#q-31)` must match a heading slug or an <a id> in the target
##   prose mentions — an inline-code `09-economy.md` must be a real file too
##   plan files     — a `build/plan/<name>.md` named from CODE must resolve too
##
## The prose test exists because the dead `docs/00-index.md` was inline code, not
## a markdown link, so a link-only lint would have walked straight past it.
##
## The plan test exists because the same rot happened a second time, in the one
## directory this file did not watch. `build/plan/` is where the parallel agent
## waves wrote their handoffs; the waves were consolidated and the handoffs were
## renamed or never written at all, leaving EIGHT dead citations in shipped code —
## `handoff-debt.md` §1 was cited twice for a file that was never authored, and
## the work it described (audit M3-TUNE-04) sat untracked behind it for four
## milestones. A citation nobody can follow is worse than no citation: it reads as
## a reference and behaves as a dead end.

const DOC_DIRS := ["res://docs", "res://art/ref/specs"]

# Fragments that are knowingly dead. Empty since DW-A2 closed (2026-09-15): the
# registers were split (DW-A3), every `Q-nn` / `BL-nn` in docs/15 carries an
# explicit `<a id>`, and its `](#)` was repointed at BL-31 — so a row here is a
# regression to explain, never a backlog item.
const DEAD_FRAGMENTS_ALLOWED := {}

# Filenames named in prose on purpose: either the record of a slug that used to
# be wrong (removing the name would destroy the record) or a doc not yet written.
const PROSE_NAMES_ALLOWED := {
    # doc 11 Q9 and doc 13 OQ-10 are the register rows that filed this very bug.
    "res://docs/11-economy-and-crafting.md": ["09-economy.md", "07-economy-and-items.md", "11-economy-and-currency.md"],
    "res://docs/13-ui-ux.md": ["13-ui-presentation.md", "13-art-direction-and-ui.md", "13-ui-ux-and-frontend.md"],
    # a historical note recording a rename already made
    "res://docs/15-open-questions.md": ["06-town-and-guild-progression.md"],
    # docs/README §4 proposes these three; they are gaps, not typos
    "res://docs/README.md": ["17-audio-and-music.md", "18-playtest-plan.md", "19-narrative-and-copy.md"],
}

# 00 §1.1 is the adopted index; 15, 16 and README are the set's other real files.
const CANONICAL_SET := [
    "00-vision-and-pillars.md", "01-core-loop.md", "02-town-and-buildings.md",
    "03-guild-reputation.md", "04-recruitment-and-roster.md", "05-morale.md",
    "06-classes-and-roles.md", "07-combat-simulation.md", "08-stats-and-formulas.md",
    "09-items-and-itemization.md", "10-content-and-encounters.md",
    "11-economy-and-crafting.md", "12-art-direction.md", "13-ui-ux.md",
    "14-technical-architecture.md", "15-open-questions.md",
    "16-production-roadmap.md", "README.md",
]

var _files: Array[String] = []
var _anchors := {}
var _link_count := 0

func before_each() -> void:
    if _files.is_empty():
        for d in DOC_DIRS:
            _collect(d, _files)
        _files.sort()

func _collect(dir_path: String, out: Array[String]) -> void:
    var d := DirAccess.open(dir_path)
    if d == null:
        return
    d.list_dir_begin()
    var name := d.get_next()
    while name != "":
        var full := dir_path.path_join(name)
        if d.current_is_dir():
            _collect(full, out)
        elif name.ends_with(".md"):
            out.append(full)
        name = d.get_next()
    d.list_dir_end()

func _read(path: String) -> String:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return ""
    return f.get_as_text()

## GitHub's heading-slug rule, which is what the long anchors in docs/15 were
## written against: lower-case, drop everything that is not a letter, digit,
## hyphen, underscore or space, then spaces become hyphens. Runs of hyphens are
## NOT collapsed — `BL-24 - What` really does slug to `q-24---what`.
func _slug(heading: String) -> String:
    var out := ""
    var low := heading.strip_edges().to_lower()
    for i in low.length():
        var c := low[i]
        var code := c.unicode_at(0)
        var alnum: bool = (code >= 48 and code <= 57) or (code >= 97 and code <= 122)
        if c == " ":
            out += "-"
        elif alnum or c == "-" or c == "_":
            out += c
    return out

func _anchors_of(path: String) -> Dictionary:
    if _anchors.has(path):
        var cached: Dictionary = _anchors[path]
        return cached
    var found := {}
    var id_re := RegEx.create_from_string("<a\\s+(?:id|name)=\"([^\"]+)\"")
    var in_fence := false
    for line in _read(path).split("\n"):
        var l: String = line
        if l.strip_edges().begins_with("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if l.begins_with("#"):
            var stripped := l.lstrip("#")
            if stripped.begins_with(" "):
                found[_slug(stripped)] = true
        for m in id_re.search_all(l):
            found[m.get_string(1).to_lower()] = true
    _anchors[path] = found
    return found

## Line-based on purpose: a fenced code block must not contribute phantom links,
## and fence state is a per-line thing. The cost is that a link whose text wraps
## across a newline is not seen (docs/15 has three; all three resolve).
func _links_of(path: String) -> Array:
    var out := []
    var re := RegEx.create_from_string("\\[[^\\]\\[]*\\]\\(\\s*([^)\\s]+)(?:\\s+\"[^\"]*\")?\\s*\\)")
    var in_fence := false
    var n := 0
    for line in _read(path).split("\n"):
        n += 1
        var l: String = line
        if l.strip_edges().begins_with("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for m in re.search_all(l):
            out.append({"line": n, "target": m.get_string(1)})
    return out

func _exists(path: String) -> bool:
    return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path)

# ============================================================================

func test_doc_set_is_intact() -> void:
    # A vacuous pass is the real risk here: if the walker finds nothing, every
    # other test below trivially succeeds.
    assert_true(_files.size() >= CANONICAL_SET.size(), "walked only %d .md files" % _files.size())
    for f in CANONICAL_SET:
        assert_true(FileAccess.file_exists("res://docs/" + f), "canonical doc missing: %s (00 §1.1)" % f)

func test_file_links_resolve() -> void:
    var dead: Array[String] = []
    for path in _files:
        var base := path.get_base_dir()
        for link in _links_of(path):
            var target: String = link["target"]
            if target.begins_with("#"):
                continue
            if target.begins_with("http://") or target.begins_with("https://") or target.begins_with("mailto:"):
                continue
            _link_count += 1
            var file_part := target
            var hash_at := target.find("#")
            if hash_at >= 0:
                file_part = target.substr(0, hash_at)
            if file_part == "":
                continue
            var resolved := base.path_join(file_part).simplify_path()
            if not _exists(resolved):
                dead.append("%s:%d -> %s" % [path, link["line"], target])
    assert_eq(dead.size(), 0, "dead doc links:\n      " + "\n      ".join(dead))
    assert_true(_link_count > 900, "only %d file links scanned; the extractor is probably broken" % _link_count)

func test_link_fragments_resolve() -> void:
    var dead: Array[String] = []
    for path in _files:
        var base := path.get_base_dir()
        for link in _links_of(path):
            var target: String = link["target"]
            if target.begins_with("http://") or target.begins_with("https://") or target.begins_with("mailto:"):
                continue
            var hash_at := target.find("#")
            if hash_at < 0:
                continue
            var frag := target.substr(hash_at + 1).to_lower()
            var file_part := target.substr(0, hash_at)
            var owner := path if file_part == "" else base.path_join(file_part).simplify_path()
            if not owner.ends_with(".md") or not FileAccess.file_exists(owner):
                continue  # a dead file target is test_file_links_resolve's report, not a second one
            if _anchors_of(owner).has(frag):
                continue
            var allowed: Array = DEAD_FRAGMENTS_ALLOWED.get(owner, [])
            if frag in allowed:
                continue
            dead.append("%s:%d -> %s" % [path, link["line"], target])
    assert_eq(dead.size(), 0, "dead anchors:\n      " + "\n      ".join(dead))

func test_prose_doc_filenames_exist() -> void:
    # `docs/00-index.md` in docs/03's prose claimed to be the filename authority
    # for four years' worth of nothing. Inline code, so no link lint would see it.
    var span := RegEx.create_from_string("`([^`\\n]+)`")
    var doc_name := RegEx.create_from_string("^(?:docs/)?(\\d\\d-[a-z0-9-]+\\.md)$")
    var dead: Array[String] = []
    for path in _files:
        var allowed: Array = PROSE_NAMES_ALLOWED.get(path, [])
        var n := 0
        for line in _read(path).split("\n"):
            n += 1
            for m in span.search_all(line):
                var inner := m.get_string(1).strip_edges()
                var hit := doc_name.search(inner)
                if hit == null:
                    continue
                var fname := hit.get_string(1)
                if fname in allowed:
                    continue
                # A bare `04-palette.md` means the sibling in art/ref/specs when
                # that is where the sentence lives, and docs/ everywhere else.
                if FileAccess.file_exists(path.get_base_dir().path_join(fname)):
                    continue
                if not FileAccess.file_exists("res://docs/" + fname):
                    dead.append("%s:%d names %s" % [path, n, inner])
    assert_eq(dead.size(), 0, "prose names a doc that does not exist:\n      " + "\n      ".join(dead))


## docs/15 carries TWO registers: `Q-nn`, the design questions awaiting a lead
## designer, and `BL-nn`, the rulings this build loop made. They overlapped on
## 19-67 when this was written, and the BL series has since marched through the
## Q-8x/9x range (BL-82..106 landed in wave 6), so the overlap GROWS with every
## ruling: a `Q-31` — or a `Q-96` — citation in code is VALID and may still name
## the wrong question, which is worse than the ambiguity it replaced, because a
## reader now trusts it. 152 citations were in exactly that state after the
## registers were split; this is the guard that stops it happening twice.
##
## The rule: inside the overlap, a `Q-nn` citation must be on this list. Each
## entry was read against both register entries before being added, and the
## reason is the entry. When a new BL id lands on a number code already cites
## as a Q, the citing file joins this list with the reason — never the other
## way round (renumbering a Q that docs 00-13 cite is the rot DW-A3 fixed).
const Q_IN_THE_BL_RANGE_THAT_REALLY_MEAN_Q := {
    "res://sim/core/Recruitment.gd": [30],   # Q-30 "is raid_experience combat
                                             # math or flavour" — cited for
                                             # display-only. BL-30 is the
                                             # Adventure curve. Both real.
    # GameState.gd's row is below with wave 7's (Q-31 "is there per-run upkeep",
    # cited by BIG-dumb #5 — BL-31 is duplicate protection; Q-88, Q-90 as wave 6).
    "res://sim/core/Achievements.gd": [69],  # Q-69 "does the achievement board
                                             # grant reputation, capped ~15%" —
                                             # which is what that file is FOR.
                                             # BL-69 (2026-09-11) is the ruling
                                             # that an unnamed tier does not
                                             # mount. Both real, read both.
    "res://tests/unit/test_achievements.gd": [69],  # the board's own cap test,
                                             # quoting Q-69's "capped ~15% of
                                             # total earned". BL-69 is the
                                             # unnamed-tier mount rule.
    "res://game/screens/Completion.gd": [21, 88],  # Q-21 "are the nine ideaboard
                                             # screenshots original work" — the
                                             # provenance signature the credits
                                             # roll waits on. BL-21 is the
                                             # mistakes-per-encounter count.
    "res://data/credits.json": [21],         # same question, same signature: the
                                             # file exists to say the roll is
                                             # unsigned and to name what signs it.
    # This file names the ids above to explain why they are here, which the
    # guard cannot tell from a real citation. Listing it is cheaper than
    # teaching the walk about comments, and the entries stay visible.
    "res://tests/unit/test_raid_plan.gd": [47], # Q-47 "how many tanks does a
                                             # fight require" — the tutorials'
                                             # tanks_required=1 tie-break.
                                             # BL-47 is the Rally Flask.
    # Wave 6 (W6-LEDGER): BL-88/90/94/96 landed on numbers these files cite as
    # design questions. Q-88 is "does clearing Raid 5 end the run, or open a
    # completion phase" (S17 and what follows it — the Completion screen's own
    # question; BL-88 is Frontal Cleave hitting the tank). Q-90 is "is skipping a tutorial permanent; how many attempts should
    # a first Raid 1 clear take" (the skip rule, the ladder, the playtest's
    # pacing bound; BL-90 is the tutorial mistake rate). Q-94 is "GDScript or C#;
    # JSON or .tres" (the reputation table's format; BL-94 is the recruit price
    # scale). Q-96 is "which arena is each encounter fought in" (the stage
    # routing; BL-96 is traits post-1.0). Every citation read; every one a Q.
    "res://data/encounters_tutorial_t1.json": [90],
    "res://data/reputation.json": [94],
    "res://game/assets/scenes/stage_arena_dungeon.json": [96],
    "res://game/core/RaidPlan.gd": [90],
    "res://game/screens/RaidPrep.gd": [96],
    "res://game/screens/Results.gd": [88, 96],
    "res://game/ui/SceneStage.gd": [96],
    "res://sim/core/Reputation.gd": [94],
    "res://tests/unit/test_completion.gd": [88],
    "res://tests/unit/test_full_loop.gd": [90],
    "res://tests/unit/test_ladder.gd": [90],
    "res://tests/unit/test_screens.gd": [21, 88],  # + Q-21, the provenance
                                             # signature the unsigned credits
                                             # roll waits on (W6-COPY's test of
                                             # the ending's silence about it).
    "res://tests/unit/test_tutorials.gd": [90],
    "res://tools/playtest.gd": [90],
    # Wave 7 (W7-AUD-AMB): the soundscape question, number 98 as a Q — (ii)
    # ambience rides the Music bus through five generated beds, (i) music is
    # the lute at W10-BUFFER, so nothing melodic is in Audio.gd (BL-98 is the
    # docs/09 §14.3 / docs/11 §6.3 row). Number 96 as a Q in the beds test is
    # the arena routing again (raids -> the dungeon, hence its own bed). The
    # three rows this unit's handoff asked for are in W7-DOCS's block below,
    # which landed first; a dictionary literal may not repeat a key.
    # Wave 7 (W7-DOCS): the rulings of 2026-09-15 landed as code comments that
    # cite the design questions they answer, and every one sits in the overlap.
    # Q-53 is "are attempts limited; the commit-at-Depart rule and active_run"
    # (BL-53 is the name pool's review gate). Q-57 is "aggro hysteresis, Lost
    # Aggro, Taunt" and Q-58 "healer threat and the chain's later hops" (BL-57 is
    # Natsuna's 87 morale, BL-58 the Legendary quirks — RaidSim's quirk seam
    # cites BL-58 by its own prefix). Q-69 is the record wall's reputation half
    # (BL-69 the unnamed-tier mount rule). Q-96 is the arena (BL-96 traits).
    # Q-98 is the soundscape (BL-98 wishlists). Every citation read; every one a Q.
    "res://data/achievements.json": [69],
    "res://data/tier_words.json": [96],
    "res://game/core/Audio.gd": [98],
    "res://game/core/GameState.gd": [31, 53, 69, 88, 90],
    "res://game/screens/LoadSave.gd": [53],
    "res://game/screens/MainMenu.gd": [53],
    "res://sim/content/ContentDB.gd": [96],  # the tier row's `scene` key (W7-STAGE)
    "res://sim/core/RaidSim.gd": [57, 58],
    "res://sim/model/Combatant.gd": [57],
    "res://tests/unit/test_audio.gd": [98],
    "res://tests/unit/test_audio_beds.gd": [96, 98],
    "res://tests/unit/test_content_db.gd": [96],  # the tier row's `scene` key
    "res://tests/unit/test_game_state.gd": [53, 69],
    "res://tests/unit/test_loadsave_screen.gd": [53],  # the owed report's route
    "res://tests/unit/test_menu_lockup.gd": [53],  # Continue opens that report
    "res://tests/unit/test_raid_sim.gd": [57, 58],
    "res://tests/unit/test_savegame.gd": [53],
    "res://tests/unit/test_scene_stage.gd": [96],  # `arena_for` (W7-STAGE)
    "res://tests/unit/test_docs_links.gd": [21, 30, 31, 47, 53, 57, 58, 69, 88, 90, 94, 96, 98],
}

const CODE_DIRS := ["res://sim", "res://game", "res://tests", "res://tools", "res://data"]

## Plan files a comment names on purpose without them existing yet — a handoff
## being written this iteration, say. Empty, and it should stay that way: the
## whole finding behind this test is that "it will exist soon" is how eight dead
## citations were born. Add a row only with the reason, the way
## `Q_IN_THE_BL_RANGE_THAT_REALLY_MEAN_Q` carries its own.
const PLAN_FILES_ALLOWED_TO_BE_MISSING: Array[String] = []


func _code_files(dir_path: String, out: Array[String]) -> void:
    var d := DirAccess.open(dir_path)
    if d == null:
        return
    for f in d.get_files():
        var name := String(f)
        if name.ends_with(".gd") or name.ends_with(".json"):
            out.append(dir_path.path_join(name))
    for sub in d.get_directories():
        _code_files(dir_path.path_join(String(sub)), out)


## Every id declared in docs/15, by register. Reads the file rather than
## hard-coding, so growing either register cannot make this test stale.
func _declared() -> Dictionary:
    var body := _read("res://docs/15-open-questions.md")
    var q := {}
    var bl := {}
    var anchor := RegEx.create_from_string("<a id=\"(q|bl)-0*([0-9]+)\"")
    for m in anchor.search_all(body):
        var into: Dictionary = q if m.get_string(1) == "q" else bl
        into[int(m.get_string(2))] = true
    var head := RegEx.create_from_string("(?m)^###\\s*~*\\s*(Q|BL)-0*([0-9]+)")
    for m in head.search_all(body):
        var into2: Dictionary = q if m.get_string(1) == "Q" else bl
        into2[int(m.get_string(2))] = true
    return {"q": q, "bl": bl}


func test_every_register_citation_resolves_to_a_declared_entry() -> void:
    var reg := _declared()
    var q: Dictionary = reg["q"]
    var bl: Dictionary = reg["bl"]
    assert_true(q.size() > 50, "read no Q ids out of docs/15 — this test is blind")
    assert_true(bl.size() > 20, "read no BL ids out of docs/15 — this test is blind")

    var files: Array[String] = []
    for d in CODE_DIRS:
        _code_files(d, files)
    var cite := RegEx.create_from_string("\\b(Q|BL)-([0-9]+)\\b")
    var bad: Array[String] = []
    var seen := 0
    for path in files:
        var allowed: Array = Q_IN_THE_BL_RANGE_THAT_REALLY_MEAN_Q.get(path, [])
        var n := 0
        for line in _read(path).split("
"):
            n += 1
            for m in cite.search_all(line):
                var kind := m.get_string(1)
                var id := int(m.get_string(2))
                seen += 1
                var declared_in: Dictionary = q if kind == "Q" else bl
                if not declared_in.has(id):
                    bad.append("%s:%d cites %s-%d, which docs/15 does not declare"
                        % [path, n, kind, id])
                elif kind == "Q" and bl.has(id) and not (id in allowed):
                    bad.append(("%s:%d cites Q-%d, and BL-%d also exists — say which, "
                        + "or add the file to Q_IN_THE_BL_RANGE_THAT_REALLY_MEAN_Q "
                        + "with the reason") % [path, n, id, id])
    assert_true(seen > 100, "found almost no citations — the walk is broken, not the code")
    assert_eq(bad.size(), 0, "register citations that name the wrong question:
      "
        + "
      ".join(bad))

## `build/plan/*.md` is the loop's own working memory: handoffs, question
## write-ups and reports that code comments point at for the reasoning behind a
## switch or a deprecation. Nothing checked it, and eight citations had rotted.
##
## Scope is deliberate: this walks CODE (sim/, game/, tests/, tools/, data/) and
## the docs, not `build/plan/` itself — plan files cross-referencing each other is
## their own business, and one of them naming a handoff still being written is
## normal. A shipped file pointing at nothing is not.
func test_every_plan_file_named_from_code_resolves() -> void:
    var files: Array[String] = []
    for d in CODE_DIRS:
        _code_files(d, files)
    for d in DOC_DIRS:
        _collect(d, files)
    var cite := RegEx.create_from_string("build/plan/([A-Za-z0-9_.-]+\\.md)")
    var bad: Array[String] = []
    var seen := 0
    for path in files:
        var n := 0
        for line in _read(path).split("\n"):
            n += 1
            for m in cite.search_all(line):
                var target := m.get_string(1)
                seen += 1
                if target in PLAN_FILES_ALLOWED_TO_BE_MISSING:
                    continue
                if not FileAccess.file_exists("res://build/plan/" + target):
                    bad.append("%s:%d names build/plan/%s, which does not exist"
                        % [path, n, target])
    # The walk has to have walked: these citations are the point of the test, and
    # a regex that matched nothing would pass it in silence.
    assert_true(seen > 10,
        "found %d plan citations — the walk is broken, not the code" % seen)
    assert_eq(bad.size(), 0, "dead plan-file citations:\n      "
        + "\n      ".join(bad))
