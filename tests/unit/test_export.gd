extends "res://tests/TestCase.gd"
## The release export's CONFIGURATION, asserted the way everything else here is.
##
## docs/15 BL-74. `export_presets.cfg` and `tools/export_build.sh` are the two
## files in this repository that nothing could ever notice going wrong: they are
## read by the engine and by bash respectively, never by the suite, and the only
## thing that exercises them is a command somebody has to remember to run. Both
## landed unreviewed in the rename commit and sat for days.
##
## THE EXPORT ITSELF IS NOT A SUITE STAGE. It takes minutes, needs the export
## templates installed, and writes 130 MB. `./tools/export_build.sh` stays a
## command a person runs. What is asserted here is everything that can be checked
## for free — the four or five couplings that, when they break, break silently and
## are discovered by a player:
##
##   * the preset the documented build command names must exist, and be the one
##     the script points at (rename the product, forget one file, ship nothing);
##   * `embed_pck=false`, because the pck-hygiene gate (docs/14 §10.1 gate 6)
##     greps the pack's own strings and an embedded pack has none to grep;
##   * `export_console_wrapper=2`, because 1 is DEBUG-ONLY and this script only
##     ever runs `--export-release` — at 1 no wrapper is produced at all and the
##     launch check, the single most valuable step, silently has nothing to run;
##   * the icon `project.godot` names must be a file that exists (it named
##     `res://icon.svg` for months, and nothing loaded it, so nothing complained);
##   * the `.gdignore` markers docs/14 §10.3 requires, because a missing one puts
##     75 MB of scratch PNGs and a vendored Aseprite tree inside the shipped pack;
##   * the exported build's FIRST FRAME (build/plan/artaudit CRITIC-G01): a boot
##     splash of our own on Palette.GROUND_PAGE, the same colour as the clear
##     colour the letterbox bars are painted with, a square 256x256 window icon
##     and a real .ico on the Windows preset — none of which anything but a
##     player's first look at the .exe would ever exercise.

const PRESETS := "res://export_presets.cfg"
const SCRIPT := "res://tools/export_build.sh"
const PROJECT := "res://project.godot"
const Palette = preload("res://game/ui/Palette.gd")

## docs/14 §10.1's own build command names this path. The script and the preset
## have to agree about it or the export writes somewhere nothing looks.
const EXPORT_PATH := "build/exports/AGuildStory.exe"

## docs/14 §10.3's list, minus the two entries this project does not have:
## `content_src/` and `art/_ref/` were never created, so they are not owed.
## `build/` is not on doc 14's list and is the heaviest of them all — docs/16:107
## prices the whole job at "six empty files" against shipping the scratch tree.
const GDIGNORE_REQUIRED := ["Aseprite", "ideaboard", "docs", "art", "build"]

## docs/14 §5.4 assertion 10 plus docs/03 §5.6. Each of these in `data/` means
## unresolved content, and unresolved content does not ship. The export script
## holds the list; this holds the list the list must contain.
const PENDING_FLAGS := ["stats_pending", "shippable", "name_pending"]

var _cfg := ""
var _sh := ""


func before_each() -> void:
    if _cfg.is_empty():
        _cfg = _read(PRESETS)
    if _sh.is_empty():
        _sh = _read(SCRIPT)


func _read(path: String) -> String:
    if not FileAccess.file_exists(path):
        return ""
    return FileAccess.get_file_as_string(path)


# ---------------------------------------------------------------- the presets

func test_the_committed_preset_file_exists() -> void:
    # docs/14 §10.3's Commit row lists it by name. A preset file that is not
    # committed means the build is reproducible on exactly one machine.
    assert_true(not _cfg.is_empty(),
        "export_presets.cfg must exist and be readable at the project root")


func test_the_windows_preset_is_there_exactly_once() -> void:
    assert_eq(_cfg.count("[preset.0]"), 1, "exactly one primary preset")
    assert_true(_cfg.contains('name="Windows Desktop"'),
        "the preset name must match the build command's argument")
    assert_true(_cfg.contains('platform="Windows Desktop"'))
    assert_true(_cfg.contains('binary_format/architecture="x86_64"'),
        "docs/14 §10.1: Windows Desktop, x86_64")


func test_the_linux_preset_ships_because_doc_14_asks_for_it_from_day_one() -> void:
    # It costs one preset and is the cheapest way to catch a platform-dependent
    # float or path bug. It is NOT launch-checked — there is no Linux runner on
    # this machine — and docs/15 BL-74 says so rather than implying otherwise.
    assert_eq(_cfg.count("[preset.1]"), 1, "docs/14 §10.1's second target")
    assert_true(_cfg.contains('platform="Linux"'))


func test_the_pack_stays_separate_from_the_executable() -> void:
    # THE load-bearing one. docs/14 §10.1 gate 6 greps the .pck's own strings for
    # paths that a missing .gdignore would have let in; an embedded pack hides
    # them inside the .exe and the gate silently passes on every build.
    assert_true(_cfg.contains("binary_format/embed_pck=false"),
        "embed_pck must stay false or the pck-hygiene gate stops working")


func test_the_console_wrapper_is_built_for_release_too() -> void:
    # 1 means "Debug only" and this project only ever runs --export-release, so
    # at 1 no wrapper exists and the launch check — the one step that separates a
    # build from an artifact — has nothing to run. 2 is "Debug and Release".
    assert_true(_cfg.contains("debug/export_console_wrapper=2"),
        "1 is debug-only; the launch check needs the wrapper in a release export")


func test_the_preset_writes_where_the_script_looks() -> void:
    # Two files, one product name. Renaming the game and updating only one of
    # them exports successfully to a path nothing then inspects.
    assert_true(_cfg.contains('export_path="%s"' % EXPORT_PATH),
        "the preset must write to docs/14 §10.1's documented path")
    assert_true(_sh.contains('EXE="$OUTDIR/AGuildStory.exe"'),
        "and tools/export_build.sh must look for the same file")


func test_the_committed_preset_carries_no_secret() -> void:
    # docs/14 §10.3, verbatim: this file is committed and must never hold a
    # keystore password. Signing credentials come from the environment.
    #
    # SETTING lines only. The file's own header comment states the rule, which a
    # whole-file grep reads as a violation of it — the same trap the register's
    # citation lint hit, where the file explaining the exceptions looked like one.
    for line in _cfg.split("\n"):
        var row := line.strip_edges()
        if row.is_empty() or row.begins_with(";") or row.begins_with("#"):
            continue
        var lower := row.to_lower()
        for banned in ["password", "keystore", "secret", "api_key", "token"]:
            assert_false(lower.contains(banned),
                "export_presets.cfg must never carry '%s': %s" % [banned, row])


# ---------------------------------------------------------------- the icon

func test_the_icon_the_project_names_is_a_file_that_exists() -> void:
    # `config/icon` read `res://icon.svg` for months against a file that was
    # never there. Nothing loaded it, so nothing complained — until an export
    # would have shipped the engine's default icon.
    var icon := _setting_of(_read(PROJECT), "config/icon")
    assert_false(icon.is_empty(), "project.godot must name an application icon")
    assert_true(FileAccess.file_exists(icon),
        "config/icon points at %s, which does not exist" % icon)


func test_the_icon_is_a_256_square() -> void:
    # CRITIC-G01: the emblem is 82x57, and Godot scaled it for the window and
    # the project list, where it read small and squashed. The plate
    # tools/art/gen_wordmark.py writes is 256x256 by construction; this reads
    # the PNG's IHDR so it holds whether or not the importer has run.
    var icon := _setting_of(_read(PROJECT), "config/icon")
    var dims := _png_size(icon)
    assert_eq(dims, Vector2i(256, 256),
        "config/icon must be a 256x256 square, got %s for %s" % [str(dims), icon])


func test_the_windows_preset_ships_a_real_ico() -> void:
    # The .exe's resource icon is a Windows .ico, not a PNG: with only a PNG
    # Godot gave the window the image and left the engine default on the .exe
    # in Explorer (docs/15 BL-67 recorded the gap; CRITIC-G01 closed it). Read
    # as bytes: reserved word 0, type 1, then one 16-byte entry per frame whose
    # first byte is the width (0 meaning 256).
    var path := _setting_of(_cfg, "application/icon")
    assert_true(path.ends_with(".ico"),
        "the Windows preset's application/icon must be a .ico, is %s" % path)
    assert_true(FileAccess.file_exists(path), "%s does not exist" % path)
    if not FileAccess.file_exists(path):
        return
    var b := FileAccess.get_file_as_bytes(path)
    assert_true(b.size() >= 22, "an .ico header is 6 bytes plus one 16-byte entry")
    if b.size() < 22:
        return
    assert_eq(int(b[0]) | (int(b[1]) << 8), 0, ".ico reserved word")
    assert_eq(int(b[2]) | (int(b[3]) << 8), 1, ".ico type 1 is an icon; 2 is a cursor")
    var count := int(b[4]) | (int(b[5]) << 8)
    var widths: Array[int] = []
    for i in range(count):
        var at := 6 + i * 16
        if at >= b.size():
            break
        var w := int(b[at])
        widths.append(256 if w == 0 else w)
    assert_true(256 in widths,
        "the .ico needs a 256 frame for Explorer's large icons, has %s" % str(widths))
    assert_true(16 in widths and 32 in widths,
        "the .ico needs the title-bar and taskbar sizes, has %s" % str(widths))


func test_the_exe_and_its_console_wrapper_wear_the_same_ico() -> void:
    # Two executables land in build/exports (export_console_wrapper=2). One
    # icon, or Explorer shows the game beside an engine-grey twin.
    var ico := _setting_of(_cfg, "application/icon")
    assert_true(_cfg.contains('application/console_wrapper_icon="%s"' % ico),
        "the console wrapper must carry the same .ico: %s" % ico)


## Width and height out of a PNG's IHDR (bytes 16..23, big-endian), or (-1, -1).
func _png_size(path: String) -> Vector2i:
    if not FileAccess.file_exists(path):
        return Vector2i(-1, -1)
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return Vector2i(-1, -1)
    var b := f.get_buffer(24)
    if b.size() < 24:
        return Vector2i(-1, -1)
    var w := (int(b[16]) << 24) | (int(b[17]) << 16) | (int(b[18]) << 8) | int(b[19])
    var h := (int(b[20]) << 24) | (int(b[21]) << 16) | (int(b[22]) << 8) | int(b[23])
    return Vector2i(w, h)


# ---------------------------------------------------------------- the first frame

func test_the_boot_splash_is_ours() -> void:
    # CRITIC-G01: without these keys the exported build opens on the engine's
    # logo over the engine's grey. The image is the Home lockup on GROUND_PAGE
    # (tools/art/gen_wordmark.py) at the reference frame's 1536x1024, and its
    # ground pixel is the same colour as bg_color, so the splash has no edge
    # on any window shape.
    var text := _read(PROJECT)
    var image := _setting_of(text, "boot_splash/image")
    assert_false(image.is_empty(), "project.godot must name application/boot_splash/image")
    assert_true(FileAccess.file_exists(image),
        "boot_splash/image points at %s, which does not exist" % image)
    assert_eq(_png_size(image), Vector2i(1536, 1024), "the splash is the reference frame's size")
    if FileAccess.file_exists(image):
        # From the bytes, not the path: Image.load_from_file() warns on every
        # res:// path ("will not work on export") and the suite log is not
        # the place for a warning about a file the engine reads raw anyway.
        var img := Image.new()
        var decoded := img.load_png_from_buffer(FileAccess.get_file_as_bytes(image))
        assert_eq(decoded, OK, "the splash PNG must decode")
        if decoded == OK:
            assert_true(img.get_pixel(0, 0).is_equal_approx(Palette.GROUND_PAGE),
                "the splash's ground must be GROUND_PAGE, got %s" % img.get_pixel(0, 0).to_html(false))
    assert_true(text.contains("boot_splash/bg_color="),
        "project.godot must set application/boot_splash/bg_color")
    var bg: Color = ProjectSettings.get_setting("application/boot_splash/bg_color", Color.MAGENTA)
    assert_true(bg.is_equal_approx(Palette.GROUND_PAGE),
        "boot_splash/bg_color must be Palette.GROUND_PAGE %s, got %s"
            % [Palette.GROUND_PAGE.to_html(false), bg.to_html(false)])


func test_the_letterbox_bars_are_ground_page() -> void:
    # window/stretch/aspect="keep" letterboxes the 3:2 frame on a wider display
    # and paints the bars with the default clear colour — the engine's grey for
    # the whole session unless this key says otherwise. RULES §2's
    # display_aspect row had "none" in its test column; this is that test.
    assert_true(_read(PROJECT).contains("environment/defaults/default_clear_color="),
        "project.godot must set rendering/environment/defaults/default_clear_color")
    var clear: Color = ProjectSettings.get_setting(
        "rendering/environment/defaults/default_clear_color", Color.MAGENTA)
    assert_true(clear.is_equal_approx(Palette.GROUND_PAGE),
        "the clear colour must be Palette.GROUND_PAGE %s, got %s"
            % [Palette.GROUND_PAGE.to_html(false), clear.to_html(false)])


## The value of `key="value"` in a .cfg-shaped file, or "".
func _setting_of(text: String, key: String) -> String:
    for line in text.split("\n"):
        var row := line.strip_edges()
        if not row.begins_with(key + "="):
            continue
        return row.substr(key.length() + 1).strip_edges().trim_prefix("\"").trim_suffix("\"")
    return ""


# ---------------------------------------------------------------- .gdignore

func test_every_directory_that_must_not_be_imported_carries_its_marker() -> void:
    # docs/14 §4 and §10.3. A missing marker is invisible in the editor and costs
    # the vendored Aseprite tree and 75 MB of scratch PNGs inside the shipped
    # pack — which is exactly what docs/14 §10.1 gate 6 exists to catch, one
    # stage too late to be free.
    var checked := 0
    for dir_name in GDIGNORE_REQUIRED:
        var at := "res://%s" % dir_name
        if not DirAccess.dir_exists_absolute(at):
            continue
        checked += 1
        assert_true(FileAccess.file_exists(at + "/.gdignore"),
            "%s/ is importable — docs/14 §10.3 requires a .gdignore there" % dir_name)
    # A .gdignore'd directory is invisible to the IMPORTER, not to DirAccess — but
    # if that ever changed this test would skip every row and pass while asserting
    # nothing, which is the failure mode the whole file exists to prevent.
    assert_eq(checked, GDIGNORE_REQUIRED.size(),
        "every listed directory should exist and be checked, not skipped")


func test_the_only_generated_directory_the_game_may_read_is_not_read_yet() -> void:
    # `build/.gdignore` is a blanket ignore, and docs/14 §10.2 carves out exactly
    # one exception: `build/atlas/` is meant to be consumable. Nothing under
    # game/ or sim/ loads from there today, which is what makes the blanket safe
    # (docs/15 BL-66 is the same ruling from the .gitignore side). If this ever
    # goes red, the ignore moves DOWN to the sibling scratch directories rather
    # than the loader moving.
    var hits: Array[String] = []
    var seen: Array[String] = []
    _grep_for("res://build/", "res://game", hits, seen)
    _grep_for("res://build/", "res://sim", hits, seen)
    # The walk has to have walked. A typo in a directory name would otherwise
    # make this the most reassuring test in the suite and the emptiest. Anchored
    # on two files that exist rather than on a count, because a count is a number
    # nobody derived and it goes stale the first time a script is added or cut.
    for anchor in ["res://sim/core/RaidSim.gd", "res://game/ui/SceneStage.gd"]:
        assert_true(anchor in seen,
            "the walk never reached %s — it is broken, not the tree" % anchor)
    assert_eq(hits.size(), 0,
        "something now loads from build/ — the blanket .gdignore has to move: %s"
            % ", ".join(hits))


func _grep_for(needle: String, dir_path: String, out: Array[String],
        seen: Array[String]) -> void:
    var d := DirAccess.open(dir_path)
    if d == null:
        return
    d.list_dir_begin()
    var entry := d.get_next()
    while entry != "":
        var at := dir_path + "/" + entry
        if d.current_is_dir():
            _grep_for(needle, at, out, seen)
        elif entry.ends_with(".gd"):
            seen.append(at)
            if FileAccess.get_file_as_string(at).contains(needle):
                out.append(at)
        entry = d.get_next()
    d.list_dir_end()


# ---------------------------------------------------------------- the script

func test_the_export_script_is_executable_and_holds_its_sentinels() -> void:
    # tools/verify.sh and every other script here are read by greps for a final
    # sentinel line. A script whose sentinel drifts reports success to a caller
    # that can no longer find it.
    assert_true(not _sh.is_empty(), "tools/export_build.sh must exist")
    for sentinel in ["EXPORT OK", "DEV EXPORT OK", "EXPORT FAILED"]:
        assert_true(_sh.contains(sentinel), "missing sentinel '%s'" % sentinel)


func test_the_pending_gate_names_every_flag_the_docs_forbid_shipping() -> void:
    # docs/14 §5.4 assertion 10 and docs/03 §5.6. The list keeps growing a new
    # name — `name_pending` arrived with the eight Legendaries nobody may name —
    # and each addition is one row in the script's PENDING array. This is the
    # test that notices when a flag is added to data/ and not to the gate.
    for flag in PENDING_FLAGS:
        assert_true(_sh.contains(flag),
            "tools/export_build.sh's pending gate must hold on \"%s\"" % flag)


func test_the_pck_hygiene_gate_covers_every_ignored_directory() -> void:
    # Gate 6 is only as good as its prefix list: a directory that gained a
    # .gdignore but was never added here would be checked by nothing.
    var covered := 0
    for dir_name in GDIGNORE_REQUIRED:
        if not DirAccess.dir_exists_absolute("res://%s" % dir_name):
            continue
        covered += 1
        assert_true(_sh.contains("res://%s/" % dir_name),
            "the pck-hygiene grep must cover res://%s/" % dir_name)
    assert_eq(covered, GDIGNORE_REQUIRED.size(), "every ignored directory is checked")


# ---------------------------------------------------------------- W6-SHEETS: the two new gates

const PROVENANCE := "res://PROVENANCE.md"
const V10_FIXTURE := "res://tests/fixtures/saves/v10_sample.json"


func test_the_provenance_manifest_exists_with_a_signature_line_per_family() -> void:
    # SHIP-17 / docs/00 §4.4.1: one row per shipped asset family, each with a
    # `Signed:` line. The gate reads exactly these lines, so the shape is pinned.
    var text := _read(PROVENANCE)
    assert_false(text.is_empty(), "PROVENANCE.md must exist at the repo root")
    var rows := 0
    var headings := 0
    for line in text.split("\n"):
        if line.begins_with("- Signed:"):
            rows += 1
        elif line.begins_with("## "):
            headings += 1
    assert_true(rows >= 5, "one Signed: line per family — plates, references, sprites, fonts, audio at least; got %d" % rows)
    assert_eq(rows, headings, "every family heading carries exactly one Signed: line")
    for needle in ["game/assets/bg/", "game/assets/fonts/", "game/assets/audio/", "ideaboard/"]:
        assert_true(text.contains(needle), "the manifest must name the %s family" % needle)


func test_step_zero_holds_while_the_manifest_is_unsigned_and_dev_passes() -> void:
    # The gate is the same shape as the pending-content hold: a HOLD line, a
    # --dev SKIP that stamps NOT SHIPPABLE, otherwise a FAIL before anything is
    # exported. Grepped from the script rather than run, like every other gate
    # coupling in this file — running the export is minutes and 130 MB.
    assert_true(_sh.contains('PROVENANCE="PROVENANCE.md"'), "the script names the manifest")
    assert_true(_sh.contains("^- Signed:"), "and counts its Signed: lines")
    assert_true(_sh.contains("PROV_UNSIGNED"), "holding on the unsigned count")
    assert_true(_sh.contains("provenance unsigned"), "the stamp names the provenance hold")
    assert_true(_sh.contains("unresolved content"), "beside the pending-content hold")
    # The rule the script enforces, applied to the committed manifest: today it
    # is unsigned, so a release export HOLDS. This assertion goes red the day the
    # designer signs — which is the day to delete it, not weaken the gate.
    var signed := 0
    var rows := 0
    for line in _read(PROVENANCE).split("\n"):
        if not line.begins_with("- Signed:"):
            continue
        rows += 1
        if not line.substr("- Signed:".length()).strip_edges().is_empty():
            signed += 1
    assert_true(signed < rows,
        "the manifest is unsigned in the tree (%d of %d): the gate must be red until a person signs" % [signed, rows])


func test_the_launch_check_boots_from_an_empty_profile() -> void:
    # SHIP-05. Godot 4.7.1 has no --user-data-dir flag, so the fresh profile is
    # the engine's own data-path variables pointed at a temp directory — and the
    # step asserts the engine created its app_userdata there, because a
    # redirect nothing honoured boots the developer's profile and looks the same.
    assert_true(_sh.contains("fresh_profile()"), "a fresh profile per launch")
    assert_true(_sh.contains('APPDATA="$win_profile"'), "Windows: %APPDATA% redirected")
    assert_true(_sh.contains('XDG_DATA_HOME="$profile"'), "Linux: $XDG_DATA_HOME redirected")
    assert_true(_sh.contains('USERDATA_WIN="Godot/app_userdata/A Guild Story"'),
        "the path the engine derives from config/name, asserted after the boot")
    assert_true(_sh.contains('[ ! -d "$USERDIR" ]'), "a boot that did not use the profile is a FAIL")
    assert_true(_sh.contains("--user-data-dir"),
        "the script says out loud that the flag SHIP-05 named does not exist in this engine")


func test_step_7b_boots_with_the_oldest_migratable_fixture_in_the_profile() -> void:
    # The fixture line: the v10 sample copied into the temp profile's saves/ as
    # slot 0 before a second boot. The fixture itself must exist and be v10, or
    # the step would be seeding the profile with something else.
    assert_true(_sh.contains('V10_FIXTURE="tests/fixtures/saves/v10_sample.json"'),
        "7b seeds the profile with the v10 fixture")
    assert_true(_sh.contains('cp "$V10_FIXTURE" "$USERDIR/saves/slot_0.json"'),
        "copied as slot 0, where newest_loadable() looks")
    assert_true(_sh.contains("7b/8"), "the step is labelled")
    assert_true(FileAccess.file_exists(V10_FIXTURE), "%s must exist" % V10_FIXTURE)
    var parsed = JSON.parse_string(_read(V10_FIXTURE))
    assert_true(typeof(parsed) == TYPE_DICTIONARY, "the fixture parses")
    if typeof(parsed) == TYPE_DICTIONARY:
        assert_eq(int((parsed.get("header", {}) as Dictionary).get("save_version", 0)), 10,
            "and is the v10 sample")
    # A boot never migrates (SaveGame.load_into runs on Continue), so the step
    # proves the file comes back byte-identical and no .bak was written.
    assert_true(_sh.contains('cmp -s "$V10_FIXTURE"'), "the save must come back untouched")
    assert_true(_sh.contains("*.bak"), "and no migration backup written by a boot")
