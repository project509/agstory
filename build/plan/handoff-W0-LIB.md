# Handoff — W0-LIB

Edits this unit needs in files it does not own. Nothing here has been applied. Each heading is one exact edit.
(Appended as the unit progresses.)

## 1. README.md:104

old:
```
./tools/build_art.sh          # incremental: art/**/*.aseprite -> build/atlas/*.png + *.json
./tools/build_art.sh --gen    # re-run the Lua generators first
./tools/build_art.sh --clean  # wipe build/atlas first
```
new:
```
./tools/build_art.sh --gen    # re-run every tools/aseprite/gen_*.lua -> art/src (sources) + game/assets (PNGs)
./tools/build_art.sh --check  # regenerate into build/artcheck/ and byte-compare with the tree (verify stage 2b)
./tools/build_art.sh --tags art/src/vfx/fire_hearth.aseprite   # list a source's animation tags
```

## 2. README.md:109

old:
```
`.aseprite` files under `art/` are the source of truth; `build/atlas/` is disposable and
gitignored. Most of the art is *generated*, not hand-drawn: the Lua generators in
`tools/aseprite/` (`gen_ui`, `gen_items`, `gen_fire`, on `lib.lua`) run headless through
```
new:
```
`.aseprite` files under `art/` are the source of truth and the PNGs under `game/assets/` are
what Godot loads; `--check` proves the PNGs still match their generators (there is no atlas
step — nothing consumed one). Most of the art is *generated*, not hand-drawn: the Lua generators in
`tools/aseprite/` (`gen_ui`, `gen_items`, `gen_icons`, `gen_fire`, `gen_wipe`, on `lib.lua`) run headless through
```

## 3. README.md:144

old:
```
art/        .aseprite sources (truth)  ->  build/atlas/ (artifacts)
```
new:
```
art/        .aseprite sources (truth)  ->  game/assets/ PNGs (tools/aseprite/gen_*.lua writes both)
```

## 4. BUILD_STATE.md:189  (W0-GATE owns BUILD_STATE this wave — apply after its block lands)

old:
```
./tools/build_art.sh         # rebuild all Aseprite sources -> build/atlas/
```
new:
```
./tools/build_art.sh --gen   # re-run every Lua generator (sources + PNGs); --check byte-compares them (verify stage 2b)
```

## 5. BUILD_STATE.md:225

old:
```
art/        .aseprite sources (truth)  ->  build/atlas/ (artifacts)
```
new:
```
art/        .aseprite sources (truth)  ->  game/assets/ PNGs (tools/aseprite/gen_*.lua writes both)
```

## 6. BACKLOG.md:145

old:
```
(`tools/art/gen_icons.lua`, `game/assets/ui/wordmark_*.png`)
```
new:
```
(`tools/aseprite/gen_icons.lua`, `game/assets/ui/wordmark_*.png`)
```

## 7. tests/unit/test_w0_lib.gd (NEW FILE, optional — the plan names no test for W0-LIB and this unit owns none)

LESSONS "built vs armed": a gate nobody can prove is wired is the failure this project keeps shipping.
test_motion.gd already reads verify.sh as text for the motion lint; this does the same for stage 2b.
Four-space indentation; no class_name.

old:
```
(none — new file)
```
new:
```
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
```
(`extends` copied from tests/unit/test_motion.gd:1.)

## Notes (no edit proposed)

- art/ref/specs/11-godot-architecture.md:80-83 still describes `build/atlas/` as kept and proposes an "install" stage copying from it; that spec predates the ruling in build_art.sh's header. Whoever next edits that spec should drop those lines.
- docs/12-art-direction.md §7 describes an atlas/export tree that PIPE-13 already flags as not matching the repo; unchanged here.
- W0-MANIFEST's `test_art_sources.gd` ("every PNG is in a generator's emit list") should read the generators from `tools/aseprite/gen_*.lua` — `tools/art/gen_icons.lua` no longer exists.
