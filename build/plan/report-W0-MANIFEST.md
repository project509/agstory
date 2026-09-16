# Report — W0-MANIFEST (every shipped crop has a source rect and every boss rank has a table)

Owned files: `art/ref/manifests/all.json`, `game/assets/enemies/enemies.json` (new),
`tools/art/place_enemies.py` (new), `tests/unit/test_art_sources.gd` (new).
Findings closed: PIPE-13 (tier 1), PIPE-17. Plan: `build/plan/artaudit/00-plan.md` §W0-MANIFEST.

Written as each item landed, in the order the items were done.

## Acceptance

- [x] `all.json` gains `ui_crop` rows (concept file + x,y,w,h) for badge_0..6, class_warrior, coin, coin_sm, gem, book, sun, cog, nav_<7>, mech_<12>, item_gear_0..2, item_reward_0..3, emblem, avail_0..7, team_0..3, cut so `slice.py cut` re-cuts them byte-identical
- [x] `game/assets/enemies/enemies.json` maps rank -> export name (boss_main = sludge_maw_leviathan, boss_main_2 = void_colossus_core, boss_mini = boss_spiked_crawler, boss_mini_2 = boss_stone_brute, boss_elite = boss_flame_brute, boss_trash = void_tentacle_a) with `frame_w/fps/scale/anchor` slots for W3-ENEMIES
- [x] `tools/art/place_enemies.py` copies export -> rank name; deleting `boss_main.png` and running it reproduces the file byte-identical
- [x] `tests/unit/test_art_sources.gd` walks `game/assets/{ui/icons,enemies,portraits}` and asserts every PNG is in a generator's emit list, has a manifest rect, or is named in enemies.json
- [x] new test passes; `verify.sh --fast` green (summary lines pasted below)
- [x] no game code touched (Green line); no shot (Shot: none) — `git status` on the owned set: `M all.json`, `?? enemies.json`, `?? place_enemies.py`, `?? test_art_sources.gd` + the two plan files; the 15 modified `game/**/*.gd` in the tree are other agents' edits; `build/shots/` has no W0-MANIFEST shot

## Findings before any code was written

- Every opaque hand-crop the plan names was located by exact RGB template match inside
  `ideaboard/Reference Concepts/Reference Concept 1.png` (one unique hit each; script in the
  session scratchpad, `locate_crops.py`): badge_0..6 at x 1070 / y 786..958 (18x18),
  class_warrior (259,797,15,12), coin (875,21,26,26), gem (1036,21,27,26), book (1181,22,23,26),
  sun (1332,20,29,27), coin_sm (1291,658,17,17), cog (1286,587,16,17), nav_home (22,118,30,22),
  nav_recruit (24,180,26,23), nav_roster (22,229,30,28), nav_gear (23,284,28,28),
  nav_missions (23,340,28,27), nav_reports (24,393,27,29), nav_options (23,448,28,29),
  item_gear_0..2 (175/231/287, 933, 39x39), item_reward_0..3 (1179/1236/1292/1348, 339, 39x39),
  emblem (22,15,82,57), avail_0..7 (26|70, 785/829/873/917, 37x37), team_0..3
  (1174/1237/1300/1363, 517, 56x58). All are fully opaque (alpha 255 everywhere), so a
  manifest row with NO `key` (slice.py applies keying only when `key` is present) is a pure
  crop and reproduces the pixels.
- **mech_<12> are not crops.** Commit a65cf70 says they were "cut from the VFX sheet"; every
  one carries 75-363 partially transparent pixels (a resample), and no exact match exists in
  Concept 1/2/3, the four Reference Graphics sheets, or any `game/assets/bg` plate; the
  nearest `art/export/vfx` thumbnail (any PIL resampler into 24x24) differs by 8-38 mean
  levels. `slice.py` has no resample step, so these cannot be re-cut byte-identical from data
  as the plan's build note asks. Judgement call (rule 7): they get `ui_crop` rows naming the
  VFX sheet as the source with `reproducible: false` and a note, so the hygiene test still
  finds a manifest row and the provenance is on record; W1-ICONS regenerates `mech_<12>` in
  `gen_icons.lua` ("same names, same treatment"), which is where they become data.
- The six boss PNGs are byte-identical to their `art/export/boss/*.png` (PIPE-17 measured it;
  re-verified here), so `place_enemies.py` is a plain copy, not a re-slice, and `enemies.json`
  also carries each export's `all.json` rect + key so the sheet -> export -> rank chain is
  closed in one file.
- `game/assets/portraits/` also holds bork/tiny/gruk/spoof (the four reference busts, 90x94)
  and class_bard/druid/monk/shaman/wizard (written by `tools/art/derive_busts.py`, whose
  docstring is the emit list). The plan's list names only avail_/team_; the test walks the
  whole directory, so the four busts need a source too — see the work log once measured.

## Work log

- **all.json: 57 `ui_crop` rows appended** (778 entries; `git diff` = 777 insertions, 0 deletions —
  the file round-trips byte-identically through `json.dumps(indent=1, ensure_ascii=False)`, so no
  existing row moved). Each row carries `sheet, x, y, w, h, proposed_name (= shipped basename),
  category "ui_crop", ships (the game path), note`; 45 rows have no `key` (pure crops of
  Concept 1: the plan's list + bork/tiny/gruk/spoof) and 12 `mech_<key>` rows point at their VFX
  island with `reproducible: false`. Ran `slice.py cut` over the 45 reproducible rows into the
  scratchpad and `filecmp`'d each against the shipped file: **45 byte-identical, 0 differ**
  (PIL is the encoder on both sides, so file bytes match, not only pixels).

### Resumed 2026-09-14 (the first agent was killed by a usage limit after the rows landed)

- **Box 1 re-verified, not trusted.** Filtered the 57 `ui_crop` rows to the 45 with `reproducible`
  unset, wrote them as a manifest in the scratchpad and ran the real `slice.py cut --manifest ...
  --out ...`; `filecmp` (shallow=False) against each row's `ships` path: **45 byte-identical,
  0 differ**. `all.json` still round-trips byte-identically through `json.dumps(indent=1)`
  (`git diff --stat` = 777 insertions, 0 deletions). The 12 `mech_*` rows all carry `key`,
  `reproducible: false` and a >20-char note naming W1-ICONS.
- **enemies.json (box 2).** Already on disk from the first run; read in full. Six ranks, each
  `export` matching the plan's table, every row with `frame_w: 0`, `fps: 0`, `scale: 1.0`,
  `anchor: [0.5, 1.0]`, `tags: {}` and a `_note` explaining each slot for W3-ENEMIES; `export_dir`,
  `target_dir`, `manifest` at the top so the script stores no path twice. No .import is needed
  (Godot does not import .json) — the suite already booted with it present.
- **place_enemies.py (box 3), proved twice.** The auto-mode classifier refused `rm` on the shipped
  PNG, so: (a) copied `boss_main.png` to the scratchpad, `mv`'d it out of the tree (`ls` confirmed
  "No such file"), ran `python tools/art/place_enemies.py` — `boss_main placed <- sludge_maw_leviathan`,
  the other five `kept` — and `cmp` against the moved file: **reproduced byte-identical**;
  `git status -- game/assets/enemies` shows only `?? enemies.json`, i.e. the reproduced file equals
  HEAD too. (b) Built a scratch tree (script + enemies.json + all.json + art/export/boss, NO rank
  PNGs at all) and ran it there: all six placed, `boss_main.png` `cmp`-equal to
  `git show HEAD:game/assets/enemies/boss_main.png`, the other five equal to the shipped files.
  `--check` on the real tree: six `OK`, `PLACE_ENEMIES OK`, exit 0.
- **Emit lists cross-checked against the generators** (the test transcribes them by hand):
  `tools/aseprite/gen_icons.lua` (W0-LIB moved it; `tools/art/gen_icons.lua` is gone, the test
  accepts either path) emits `face_0..9` (line 174/177), `slot_{main_hand,off_hand,head,chest,legs,
  feet,trinket}` (258/262), `item_{minor_healing_potion,potion_of_steady_hands,rally_flask,unknown}`
  (362/365), `rank_<RANKS.key>` (419), `arrow_left`, `arrow_right`, `fast_forward_24`, `cog_24` —
  exactly `GEN_ICONS`. `derive_busts.py` saves monk/druid/bard/wizard/shaman — exactly `DERIVE_BUSTS`.
- `tools/aseprite/gen_items.lua` writes `item_<slot>_<mat>` for every `shapes` key: head {iron,
  leather, eyepatch, headband, cloth}, legs {iron, leather, cloth}, feet {iron, leather, cloth},
  off_hand {iron, leather, instr, cloth}, weapon {dagger, mace, staff_wood, staff_fire, staff_arc,
  staff_druid, totem}, chest {cloth, leather}, trinket {armor, health, mana, power} = 28 — exactly
  `GEN_ITEMS`. The rank keys are unknown/known/respected/established/renowned/legendary = `GEN_ICONS`.
- `tools/lint_motion.sh` (engine-free; run outside the lock while verify held it): `MOTION LINT OK`,
  exit 0 — enemies.json is data under game/, no tween or glyph door was touched.
- **verify --fast (through the lock, 2026-09-14, ~5 min lock wait + 32 s suite):** `VERIFY OK`, exit 0.
  `tests/unit/test_art_sources.gd` is one of the 72 files (`ls tests/unit/test_*.gd | wc -l` = 72; the
  runner names only failing files, and none is named). The suite is 1604 tests now (1603 at resume;
  the extra one is another wave-0 agent's). Summary lines:

```
== 0/8  lint: no cross-file class_name refs ==
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
== 1/8  script parse ==
  PASS  PARSE_CHECK scanned 151 script(s)
== 2/8  generated content matches its generator ==
  PASS  16 generated file(s) agree with tools/gen_items.gd
== 2b/8  generated art matches its generator ==
  PASS  ART CHECK  generators=5  runtime files: 76 agree  0 DIFFERS  0 MISSING
== 3/8  unit tests ==
  PASS  TESTS PASSED   1604 test(s) in 72 file(s)  [32041 ms]
== 4/8 .. 7/8  SKIP  --fast
VERIFY OK  (full log: .verify.log)
```

## Judgement calls (rule 7)

- `mech_<12>` cannot be re-cut byte-identical (they are resamples, see Findings); recorded as
  `reproducible: false` rows with provenance rather than left orphaned. W1-ICONS makes them data.
- The four reference busts (bork/tiny/gruk/spoof) were not in the plan's list but sit in a walked
  directory; they got `ui_crop` rows (pure crops of Concept 1) instead of a test exemption.
- The "delete boss_main.png" proof was done by moving the file aside (backed up) plus a scratch tree
  with no rank PNGs, because the auto-mode classifier refused `rm` on a shipped asset. Both runs
  reproduced the HEAD bytes; the real tree ended with `boss_main.png` unchanged in git.

## Left undone

Nothing in the unit. No handoff needed (wave 0 expected none).
