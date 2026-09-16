# review-W0-MANIFEST — adversarial review (written as I go)

Reviewer: subagent, 2026-09-14. Verifies the TREE, not the report. Nothing edited but this file.

## 1. Ownership / changed files
- [x] owned files diffed and read in full
  - `art/ref/manifests/all.json`: `git diff --stat` = 777 insertions, 0 deletions; read the whole diff.
    57 rows appended, all `category: "ui_crop"`, indices 0..56, each with sheet/x/y/w/h/proposed_name/
    ships/note; the 12 `mech_*` rows add `key`, `thresh`, `reproducible: false`. Python round-trip
    (`json.dumps(indent=1, ensure_ascii=False)`) reproduces the file byte-for-byte (237761 bytes),
    so no pre-existing row moved. 778 entries total. No duplicate names.
  - `game/assets/enemies/enemies.json` (new): six ranks, exports exactly the plan's table, each with
    `frame_w 0 / fps 0 / scale 1.0 / anchor [0.5,1.0] / tags {}` + `_note`, `export_dir`,
    `target_dir`, `manifest`. The note's "place_boss plants offset.y = -h/2" is true (SceneStage.gd:274).
  - `tools/art/place_enemies.py` (new): read in full; byte copy via `shutil.copyfile`, `--check`
    via `filecmp.cmp(shallow=False)`, `--rank` filter, manifest boss-row cross-check, exit 2 on
    table errors through `die()`.
  - `tests/unit/test_art_sources.gd` (new): read in full; 6 `test_` funcs; 0 tab characters
    (tests/ = four spaces, correct).
- [x] non-owned changes listed and attributed
  - The tree carries ~50 other modified/untracked paths (BACKLOG/BUILD_STATE/README, 13 screens,
    Boot/Theme, project.godot, 9 tests, tools/*, art/src/vfx/*.aseprite, splash/icon PNGs,
    handoff/report files of the other five W0 units, `tools/art/gen_icons.lua` deleted and
    `tools/aseprite/gen_icons.lua` new = W0-LIB's move, `tests/unit/test_text_scale.gd` =
    W0-TEXTSCALE). `git diff` of BUILD_STATE/BACKLOG/README/verify.sh/build_art.sh contains no
    "MANIFEST", "enemies.json", "place_enemies", "art_sources" or "ui_crop" — no fingerprint of this
    unit outside its four files. `tests/unit/test_art_sources.gd.uid` is Godot's own by-product (the
    other 71 test .uid files are tracked), fine.
  - No consumer of all.json other than place_enemies.py and the new test exists in tools/, tests/
    or game/ (grep; the two hits are the substring "guildhall.json"), so the `ui_crop` category
    cannot perturb build_art.sh's ART CHECK or any other tool.

## 2. Tests and verify (observed by me, through the lock)
- [x] `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` → exit 0:
  `LINT OK`, `MOTION LINT OK`, `PARSE_CHECK scanned 151 script(s)`, `16 generated file(s) agree`,
  `ART CHECK generators=5 runtime files: 76 agree 0 DIFFERS 0 MISSING`,
  `TESTS PASSED 1604 test(s) in 72 file(s) [32867 ms]`, `VERIFY OK`.
- [x] test_art_sources.gd observed running by name — the suite runner names only failures, so I
  ran the file alone with a scratch SceneTree runner (scratchpad/run_one.gd, loads
  `res://tests/unit/test_art_sources.gd`, calls each `test_`) through the lock
  (`tools/with_godot_lock.sh "$GODOT" --headless --path . --script <scratch>/run_one.gd`):
  `REVIEW PASS test_every_shipped_png_names_its_source`, `… test_ui_crop_rows_are_well_formed`,
  `… test_reproducible_ui_crop_rows_are_the_shipped_pixels`,
  `… test_mech_icons_are_recorded_as_not_reproducible`,
  `… test_enemies_json_maps_each_rank_to_a_byte_identical_export`,
  `… test_the_placing_script_reads_the_table`; `REVIEW DONE 6 test(s), 0 failing`, exit 0.

## 3. Shot
The plan says `Shot: none` for this unit and it changes no pixel. As a sanity check that the
enemies/ and manifest data still let the game load its bosses I took
`RaidView --fixture=raid` → `build/shots/review-W0-MANIFEST-raidview.png`
(`tools/with_godot_lock.sh "$GODOT" --path . --script res://tools/shot.gd -- res://game/screens/RaidView.tscn
build/shots/review-W0-MANIFEST-raidview.png 40 1536x1024 --fixture=raid` → `SHOT OK … 1536x1024`, exit 0).
Viewed with Read: the cave arena; the boss_main maw (sludge_maw_leviathan) stands at ≈(1180,170)
right of the rail track; the boss plate top-right (≈935-1310, 55-150) shows its portrait
thumbnail, "Raid 1 — Encounter 5", the 7150/7150 bar and five 24px `mech_*` affix icons in a row
under the bar (≈1010-1150,135); the party cards along the bottom show the bork/gruk busts and the
`slot_*`/`item_*` glyphs; the log's badge dot sits at ≈(1060,763). Every asset family this unit
catalogued loads; nothing this unit could have moved has moved. (Lock note, not this unit's: the
run printed `godot-lock: breaking stale lock (1789394594s old)` — with_godot_lock.sh's own
stale-lock heuristic fired on a future-dated lock file; worth an orchestrator glance.)

## 4. Acceptance lines
- [x] **`test_art_sources.gd` walks `game/assets/{ui/icons,enemies,portraits}` and asserts every PNG
  is in a generator's emit list, has a manifest rect, or is named in enemies.json** — MET.
  - The three dirs hold 131 PNGs and no subdirectory (`find`). By hand: icons = 31 GEN_ICONS +
    28 GEN_ITEMS + 7 badge + 6 chip/cog + class_warrior + 7 item_gear/reward + 12 mech + 7 nav
    (all ui_crop rows); enemies = 6 ranks; portraits = 5 class_ (DERIVE_BUSTS) + 8 avail + 4 team +
    bork/tiny/gruk/spoof (ui_crop rows). Nothing uncovered.
  - Emit lists cross-checked against the generators: `tools/aseprite/gen_icons.lua` emits
    face_0..9 (:177), slot_{main_hand,off_hand,head,chest,legs,feet,trinket} (:262),
    item_{minor_healing_potion,potion_of_steady_hands,rally_flask,unknown} (:365), rank_<6 RANKS
    keys> (:419, :391-403), arrow_left (:443), arrow_right (:448), fast_forward_24 (:458),
    cog_24 (:488) = the test's 31. `gen_items.lua` shapes: head{iron,leather,eyepatch,headband,
    cloth} legs{iron,leather,cloth} feet{iron,leather,cloth} off_hand{iron,leather,instr,cloth}
    weapon{dagger,mace,staff_wood,staff_fire,staff_arc,staff_druid,totem} chest{cloth,leather}
    trinket{armor,health,mana,power} = the test's 28. `derive_busts.py` save() ×5 = DERIVE_BUSTS.
    The lists are neither over- nor under-inclusive.
  - The test also proves the pixels: `test_reproducible_ui_crop_rows_are_the_shipped_pixels`
    re-cuts each of the 45 pure crops from the sheet with `Image.get_region` and compares data.
  - Sheets are tracked (`git ls-files`: Concept 1, both Reference Graphics sheets, ideaboard/.gdignore),
    so the test holds on a fresh clone.
- [x] **deleting `boss_main.png` and running `place_enemies.py` reproduces it byte-identical** — MET.
  - I did it in a scratch copy of the tree (script + enemies.json + all.json + art/export/boss +
    the other five rank PNGs, `boss_main.png` removed — I edit nothing in the real tree):
    `boss_main placed <- sludge_maw_leviathan`, other five `kept`, exit 0; `cmp` against the real
    tree's `boss_main.png` and against `git show HEAD:game/assets/enemies/boss_main.png` both equal.
  - In the real tree: `cmp` shows all six rank PNGs byte-equal to their exports;
    `python tools/art/place_enemies.py --check` → six `OK`, `PLACE_ENEMIES OK`, exit 0;
    `git status -- game/assets/enemies` shows only `?? enemies.json`.
- Build note "ui_crop rows … cut so slice.py re-cuts them byte-identical":
  - I filtered the 45 `reproducible`-unset rows into a scratch manifest and ran the real
    `python tools/art/slice.py cut --manifest … --out …`: `cut 45 sprites`; `filecmp(shallow=False)`
    against each row's `ships` path: **45 byte-identical, 0 differ** (independent of the report).
  - The 12 `mech_<key>` rows are NOT byte-reproducible: every shipped mech PNG is 24x24 with
    75-363 partially-transparent pixels (a resample), while the island rects are 16x27..87x22;
    `slice.py` has no resample step and no tool in tools/ names any mech icon (grep), and commit
    a65cf70 only says "cut from the VFX sheet". So the plan's literal "re-cut byte-identical" is
    impossible for these 12 without a generator (which is W1-ICONS' unit). The rows carry the
    island rect + key + `reproducible: false` + a note naming W1-ICONS, and the test pins that
    state (`test_mech_icons_are_recorded_as_not_reproducible`). Judgement call recorded in the
    report; I accept it — see §6.

## 5. Green line / §0.5
- [x] no game code touched: the owned set has no `.gd` under game/; `enemies.json` is data.
  No Label/Button text, node name, tween, `reduced_motion`, `class_name`, `_ready`, overlay or
  router change is possible from these four files. No new PNG (nothing to view for baked text, no
  .import needed; Godot does not import .json). `place_enemies.py` never calls Godot. The test is
  four-space indented. Handoff file is deliberately empty and says so.

## 6. Judgement calls vs §6
- `mech_<12>` → `reproducible: false` with provenance: not a §6 question (Q18's icon questions
  are about the warrior glyph and which sim states get a glyph; PIPE-13 tier 2 hands mech_* to
  W1-ICONS). Justified — see §4.
- bork/tiny/gruk/spoof given `ui_crop` rows (the plan lists only avail_/team_ for portraits):
  the acceptance line walks the whole portraits dir, so these four needed a source; a pure crop
  of Concept 1 that re-cuts byte-identical is the strongest source available. Not a designer
  matter.
- "delete boss_main.png" proved by move-aside + scratch tree rather than `rm`: the outcome
  (HEAD bytes reproduced) is what the line asks for; I reproduced it the same way.

## Findings (by number)
1. minor — `place_enemies.py` docstring says "Exit codes: 0 ok, 1 differs/missing under --check,
   2 table error", but a per-rank ERROR in copy mode (no export named / no boss row / export
   file missing) returns 1, not 2; only `die()` (missing top-level keys, unknown `--rank`) exits 2.
   Harmless today (all six rows are well-formed); a caller distinguishing 1 from 2 would misread it.
2. minor — `tests/unit/test_art_sources.gd.uid` is untracked; commit it with the test (the other
   71 test .uid files are tracked) or Godot regenerates it on every boot.
3. info — the test's `test_ui_crop_rows_are_well_formed` lower bound `>= 57` and
   `checked >= 45` are floors, so a future unit adding rows does not break it; a future unit
   REMOVING a row does, which is the intent.

## Report claims checked against the tree
Every claim in `report-W0-MANIFEST.md` that I could test held: 57 rows / 777+0 / byte round-trip;
45 slice.py re-cuts byte-identical, 0 differ; 12 mech rows `reproducible: false` naming W1-ICONS and
each duplicating an existing `vfx` island's rect+key+thresh; six ranks per the plan's table with typed
slots; boss_main.png reproduced from the export byte-for-byte; `--check` six OK; verify --fast
`VERIFY OK 1604 test(s) in 72 file(s)`, `MOTION LINT OK`; emit lists match gen_icons.lua /
gen_items.lua / derive_busts.py line for line; no game code, no shot, no handoff. No false claims.

## Verdict: PASS (minors only)
- Acceptance line 1 (walk + assert every PNG sourced): MET — see §4.
- Acceptance line 2 (delete boss_main.png, place_enemies.py reproduces byte-identical): MET — see §4.
- Blockers: none. Unowned files touched by this unit: none.
- Minors: #1 place_enemies.py exit-code docstring vs copy-mode ERROR (returns 1, doc says 2);
  #2 commit `tests/unit/test_art_sources.gd.uid` alongside the test.
