extends "res://tests/TestCase.gd"
## Project-configuration invariants: what the importer is allowed to touch, what
## `config/icon` points at, and whether the source comments still describe the
## art that exists.
##
## These are the defects M6-EXP-03, M6-EXP-04, M6-FINAL-02 and m4t-13 recorded,
## and every one of them was invisible to the suite: a 75 MB scratch tree in the
## import database, an icon path with no file behind it, a `.uid` with no script,
## and a row of comments that told the next reader art was missing when it had
## already shipped. None of those breaks a screen, which is exactly why they need
## a test rather than a habit.
##
## Everything here walks the real project tree, so it is clone-safe: a directory
## that does not exist in a fresh checkout is skipped, never failed.

const Cards = preload("res://game/ui/Cards.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Enums = preload("res://sim/model/Enums.gd")

## docs/14 §4: every directory under the project root Godot must not import
## carries a `.gdignore`, and `.gitignore` does not stand in for it. `build/` is
## this project's addition to that list — docs/14 §10.2 reserves `build/atlas/`
## as the one thing the game may consume and nothing under `game/` loads from
## `res://build` today. `docs/` carries one for the same reason even though the
## engine imports no `.md`: §4 names it, and M6-EXP-02's step-5 gate greps the
## exported `.pck` for `res://docs/`. The marker does not hide the docs from the
## suite — `.gdignore` stops the importer, not FileAccess, so test_docs_links.gd
## still reads all eighteen files.
const MUST_NOT_IMPORT := ["art", "ideaboard", "Aseprite", "build", "docs"]

## A comment that denies art which exists is worse than no comment (m4t-13).
## Each row is [source file, the phrase that would be the lie, the asset whose
## existence makes it one].
##
## LIES is the guard: the phrase must be gone. LIES_OWED is the same defect in
## files this wave may not edit (build/plan/handoff-housekeeping.md §4), and its
## rows assert the lie is STILL there — so the loop that finally rewrites one of
## those comments is told to move its row up into LIES rather than leaving the
## file unguarded. m4t-13's failure mode is a stale comment surviving a loop
## unnoticed; a row that flips is the notice.
const LIES := [
    ["res://game/ui/Cards.gd", "class sprite sheets are cut into busts",
        "res://game/assets/portraits/class_bard.png"],
    ["res://game/ui/Cards.gd", "until their busts are authored",
        "res://game/assets/portraits/class_bard.png"],
    ["res://game/screens/RaidView.gd", "class bust when that set lands",
        "res://game/assets/portraits/class_wizard.png"],
    ["res://game/screens/Facilities.gd", "Raider Detail (S05) does not exist",
        "res://game/screens/RaiderDetail.tscn"],
    ["res://game/screens/RaiderDetail.gd", "gear placeholders until the item sheet lands",
        "res://game/assets/ui/icons/item_chest_leather.png"],
    ["res://game/screens/Results.gd", "reward glyph is a placeholder by index",
        "res://game/assets/ui/icons/item_chest_leather.png"],
    ["res://game/ui/Frame.gd", "emblem sprite is not authored yet",
        "res://game/assets/ui/emblem.png"],
    # W4-HYGIENE (RULES-04, COMBAT-21): the wipe's ink blot and wax seal were
    # "art that does not exist" / "has no blot" in RaidView's docstrings for a
    # week after gen_wipe.lua wrote both. W3-RAIDVIEW2 rewrote the docstrings
    # to name the PNGs; these rows keep the retired phrases retired.
    ["res://game/screens/RaidView.gd", "art that does not exist",
        "res://game/assets/ui/wipe_blot.png"],
    ["res://game/screens/RaidView.gd", "has no blot",
        "res://game/assets/ui/wipe_blot.png"],
    # W4-HYGIENE (RULES-05): MainMenu said the aerial's water, clouds and
    # sails were "none of which SceneStage can build" while stage_town.json
    # carried three shimmer rects; W3-MENU rewrote it, and its own interim
    # phrase ("cloud drift and sail motion are M4B-VFX-01") retired in turn
    # when W2-STAGE2's cloud strips landed. The first row is keyed on the
    # scene file that carries the shimmer, the second on the cloud strip.
    ["res://game/screens/MainMenu.gd", "none of which SceneStage can build",
        "res://game/assets/scenes/stage_town.json"],
    ["res://game/screens/MainMenu.gd", "cloud drift and sail motion are M4B-VFX-01",
        "res://game/assets/vfx/clouds_far.png"],
]

## Emptied 2026-09-10: all three rows were promoted into LIES when the comments
## were rewritten. The table stays because it is the right shape for the next
## wave that finds a lie in a file it may not touch.
const LIES_OWED := []


func _collect(dir: String, out: Array[String]) -> void:
    for f in DirAccess.get_files_at(dir):
        out.append(dir.path_join(String(f)))
    for d in DirAccess.get_directories_at(dir):
        var name := String(d)
        # `.godot/` and `.git/` are generated; they carry their own markers.
        if name.begins_with("."):
            continue
        _collect(dir.path_join(name), out)


func _all_files() -> Array[String]:
    var out: Array[String] = []
    _collect("res://", out)
    return out


## FileAccess.get_file_as_string returns "" for a path it cannot open, and every
## caller below asks `contains`, so a renamed or mistyped row in LIES would pass
## by reading nothing. Fail on the empty read instead.
func _source_of(path: String) -> String:
    var src: String = FileAccess.get_file_as_string(path)
    assert_true(src.length() > 0,
        "%s could not be read — this row guards nothing" % path)
    return src


func test_scratch_trees_carry_gdignore() -> void:
    for d in MUST_NOT_IMPORT:
        var dir: String = "res://%s" % d
        if not DirAccess.dir_exists_absolute(dir):
            continue
        assert_true(FileAccess.file_exists(dir + "/.gdignore"),
            "docs/14 §4: %s/ must carry a .gdignore or the importer ships it" % d)


func test_only_game_assets_are_imported() -> void:
    var strays: Array[String] = []
    var seen: Dictionary = {}
    for p in _all_files():
        for d in MUST_NOT_IMPORT:
            if p.begins_with("res://%s/" % d):
                seen[d] = int(seen.get(d, 0)) + 1
        if not p.ends_with(".import"):
            continue
        if not p.begins_with("res://game/"):
            strays.append(p)
    # If DirAccess cannot see a .gdignore'd tree, the loop above proves nothing
    # about it and the test would pass by being blind. Every tree that is on
    # disk must have shown up in the walk — every name on the list, not just
    # build/.
    for d in MUST_NOT_IMPORT:
        if not DirAccess.dir_exists_absolute("res://%s" % d):
            continue
        assert_true(int(seen.get(d, 0)) > 0,
            "res://%s exists but the walk saw nothing in it — this test is blind" % d)
    assert_eq(strays.size(), 0,
        "only game/ art may be imported; found %s" % str(strays))


func test_project_icon_resolves() -> void:
    var icon: String = String(ProjectSettings.get_setting("application/config/icon", ""))
    assert_ne(icon, "", "project.godot must name an application icon")
    assert_true(FileAccess.file_exists(icon),
        "config/icon points at %s, which does not exist" % icon)


func test_no_orphaned_uid_files() -> void:
    # Deleting a script without its `.uid` sibling leaves a uid the import cache
    # keeps resolving to nothing; the reverse of the trap that made
    # tools/probe/diag.gd's removal a two-file job.
    var orphans: Array[String] = []
    for p in _all_files():
        if not p.ends_with(".gd.uid"):
            continue
        if not FileAccess.file_exists(p.trim_suffix(".uid")):
            orphans.append(p)
    assert_eq(orphans.size(), 0, "uid files with no script: %s" % str(orphans))


func test_every_class_resolves_a_portrait() -> void:
    # The fact the three stale comments denied: four classes borrow the
    # reference's busts and the other five have their own class_*.png, so no
    # canon class falls through to a blank frame.
    for i in range(Enums.CLASS_KEYS.size()):
        var r = Raider.new()
        r.id = "hygiene_%d" % i
        # A name no portrait file is named after, so the class pass is what answers.
        r.display_name = "Nobody Of Nowhere"
        r.class_id = i
        assert_ne(Cards.portrait_for(r), null,
            "no bust resolves for %s" % String(Enums.CLASS_KEYS[i]))


func test_no_comment_denies_art_that_exists() -> void:
    for row in LIES:
        var path: String = String(row[0])
        var phrase: String = String(row[1])
        var asset: String = String(row[2])
        if not FileAccess.file_exists(asset):
            continue
        assert_false(_source_of(path).contains(phrase),
            "%s still says \"%s\" but %s exists" % [path.get_file(), phrase, asset])


func test_comments_owed_a_rewrite_are_still_owed() -> void:
    # The m4t-13 comments in files a wave does not own. Asserting they are still
    # there is what stops the debt going quiet: the day one is rewritten this
    # fails and asks for its row to be promoted into LIES. Empty today — the
    # three rows it held were promoted when their comments were rewritten.
    for row in LIES_OWED:
        var path: String = String(row[0])
        var phrase: String = String(row[1])
        var asset: String = String(row[2])
        assert_true(FileAccess.file_exists(asset),
            "%s is what makes that comment false; without it the row is wrong" % asset)
        assert_true(_source_of(path).contains(phrase),
            "%s no longer says \"%s\" — move this row out of LIES_OWED into LIES so it cannot come back" % [path.get_file(), phrase])
