# Review — W0-GATE (adversarial), 2026-09-14

Verified against the TREE. Written finding by finding as each check completes. Reviewer touched
nothing but this file and `build/shots/review-W0-GATE-*` (gitignored shots).

## 1. Ownership / files changed

`git status --porcelain` at 08:55. Owned files changed: `tools/shot_all.sh`, `tools/diff_all.sh`,
`tools/probe/Kit.gd`, `tools/art/contact_sheet.py`, the eight test files, `BUILD_STATE.md` — all in the
owned list. `build/plan/report-W0-GATE.md` and `handoff-W0-GATE.md` (empty handoff) exist.

Changed files NOT in this unit's owned list (other units' — nothing in this unit's diff or report claims
them): `BACKLOG.md`, `README.md`, `art/ref/manifests/all.json`, `art/src/vfx/fire_*.aseprite`,
`export_presets.cfg`, all 13 `game/screens/*.gd`, `game/ui/Boot.gd`, `game/ui/Theme.gd`, `project.godot`,
`tests/unit/test_export.gd`, `tools/art/gen_icons.lua` (D), `tools/art/gen_wordmark.py`,
`tools/aseprite/*.lua`, `tools/build_art.sh`, `tools/fixture_reference.gd`, `tools/shot.gd`, `tools/verify.sh`,
plus untracked `game/assets/enemies/enemies.json`, `game/assets/ui/icon*`, `splash.png*`,
`tests/unit/test_art_sources.gd`, `test_text_scale.gd`, `tools/art/place_enemies.py`, `tools/aseprite/gen_icons.lua`,
`aguildstory.zip`. The report attributes `tools/shot.gd` to W0-SHOT (its report exists) and touches no game/ file.
`git diff -- BUILD_STATE.md --stat` = 17 insertions, 0 deletions: HEAD + the one block, nothing else lost by the
truncation incident (W0-LIB kept its BUILD_STATE edits in its handoff, `handoff-W0-LIB.md:48,59`).

- Line endings: `git ls-files --eol` shows `BUILD_STATE.md` and `test_consumables/test_raider_detail/
  test_reputation/test_rest.gd` are now `w/crlf` against `attr eol=lf` (304/304, 454/454, 485/485, 654/654,
  350/350 lines carry CR — uniform, not mixed). Git normalises on commit (the diff is clean), Godot parses
  CRLF; the report's "with CRLF as the working copy had" cannot be true for an `eol=lf` checkout but the
  effect is nil. MINOR.

## 2. Diffs of owned files (read in full)

- `tools/shot_all.sh`: rewritten. `--sheet=NAME|all`, eleven sheets, `<out>/<sheet>/` per sheet, SKIPPED on
  (a) grep pre-check of the flag's spelling in `tools/shot.gd`, (b) engine exit 2, (c) engine exit 12
  (disabled `--press` target, reason echoed); FAIL + exit 1 otherwise; unknown sheet/flag exit 2. Self-wraps in
  the lock when run bare via an ancestor walk over `/proc/<pid>/cmdline`. `bash -n` clean; UTF-8 (the 0x97 byte
  is gone: `iconv` round-trips).
- `tools/diff_all.sh`: 14 TARGETS (kit + 13 screens) with `scene|concept|name|masks|flags`; Concept-3 rows
  masked `0,77,1536,649`, Concept-2 rows `210,77,928,640`, RaidView/Results `--fixture=raid`, MainMenu
  `region=0,300,520,420` (refdiff's existing `--region`, `tools/art/refdiff.py:59` — refdiff untouched). Same
  self-wrap. `bash -n` clean.
- `tools/probe/Kit.gd`: `SceneStage.load("stage_camp")` at `CAMP_OFFSET = Vector2(-46, -62)`,
  `size = f.scene.size - CAMP_OFFSET` — mirrors `Town.gd:134,144-145` exactly. Tabs throughout (0 space-led lines).
- `tools/art/contact_sheet.py`: `flow_key` sorts `<Screen>_<variant>` with its screen; size mismatch resized and
  announced. `ast.parse` ok.
- Eight test files: exactly `var survivors: Array = []` + `var mistake_count: int = 0` after the existing
  `casualties` line in every stub (10 stubs; RULES-01 verdict's field list, `casualties` not redeclared).
  Four-space, stub blocks only — no test body touched.
- `BUILD_STATE.md`: one 17-line "Art gate baselines (W0-GATE, 2026-09-13)" block after line 98.

## 3. Gate runs observed by the reviewer

- Engine-free dry run of `shot_all.sh`'s exit contract (scratchpad copy: fake engine, fake shot.gd; no lock,
  no Godot): flag-less shot.gd → focus/wide-keep/wide-expand/tabs/raid-advanced/raid-clear rows all
  `SKIPPED … (tools/shot.gd lacks --focus|--press=…|…)`, fixture/empty/text150/emoji/reduced still run, exit 0;
  engine exit 2 → `SKIPPED (shot.gd usage exit 2)`, exit 0; engine exit 12 → `SKIPPED (press target is
  disabled — …)`, exit 0; engine exit 1 → `FAIL (exit 1)`, exit 1; `--sheet=nope` → usage, exit 2; `--bogus`
  → exit 2; `--sheet=all` with a green engine = 13+13+13+13+13+26+13+13+5+2+1 = 125 rows; the
  `Town,RaidView` filter yields 4 rows on `reduced`. Matches the report's A5 claims.
- Ancestor-walk probe: a `bash -c` whose command TEXT merely mentions `with_godot_lock` (as every Bash-tool
  command that wraps one call does) makes `under_godot_lock` return true for a sibling BARE call in the same
  command — e.g. `tools/with_godot_lock.sh ./tools/verify.sh --fast && ./tools/diff_all.sh` would run the
  engine unguarded while another agent holds the lock. Reproduced: `FALSE-POSITIVE` printed with no
  with_godot_lock.sh running above. The plan's grammar (always wrapped) is unaffected; the bare path is the
  unit's own convenience. MINOR, but real — a `GODOT_LOCK_HELD` env marker exported by with_godot_lock.sh (a
  handoff, not this unit's file) would make it exact.
- Engine run (one lock hold, queued 08:57:59): Kit shot → `build/shots/review-W0-GATE-kit.png`;
  `shot_all.sh build/shots/review-W0-GATE-sheets --sheet=tabs`; `diff_all.sh build/shots/review-W0-GATE-diff`;
  `verify.sh --fast`. Results below when the lock is taken.

- Engine results (lock taken ~08:59:50, released 09:02:10; log in the reviewer's scratchpad — its first lines were
  clobbered by a sibling reviewer's runner writing the same scratchpad file, the steps below are intact):
  1. Kit probe shot → `build/shots/review-W0-GATE-kit.png` (08:59:57, 1536x1024). VIEWED: Concept-1 chrome
     (Home rail of seven, four chips "12,480 / 320 / 8/12 / Day 23 16:40", the Sludge Maw card, "17%", Send Them
     Anyway 2,400 G, four roster cards, seven Recent Events) over the BARE CAMP — two tents, the wagon, the fire
     ring with five figures, the waterfall, the "…" bubble and "I think I'm ready for a real raid this time!" —
     no guildhall building, no Concept-1 crop. A4's "stands on stage_camp" is true to the eye.
  2. `./tools/shot_all.sh build/shots/review-W0-GATE-sheets --sheet=tabs`: `ok Guildhall_Facilities`,
     `SKIPPED Guildhall_Records (press target is disabled — There is nothing to record until you have raided. The
     board opens at Known.)`, `ok Tavern_Manage`, `ok Market_Buy`, `ok Market_Comfort`; `sheet tabs: 4 ok, 1
     skipped, 0 failed`; rc 0. VIEWED `_sheet_1.png`: Facilities ("Leaking Guildhall — level 1 of 4",
     "Commission the work — 150 G", Quarters busts), Manage (eight Dismiss rows, "Ask around again — 50 G"),
     Buy (Minor — 8/30/35/35/40 G, Guild Feast), Comfort ("Furnishings for Bork", Straw Cot +3 · 40 G). The
     exit-12 branch is live, as the report says.
  3. `./tools/diff_all.sh build/shots/review-W0-GATE-diff`: 14 lines, rc 0 (09:01:04). Against the BUILD_STATE
     block: town/tavern/market/guildhall/raiderdetail/loadsave/settings/raidprep identical to two decimals;
     kit 25.245 (25.20), raidview 34.56 (34.51), results 32.366 (32.36) inside the block's ≤0.07 clause;
     board 28.708 (28.65, +0.06) and completion 28.261 (28.23, +0.03) also move but are NOT named by the clause;
     **mainmenu 36.35 / 0.0758 / 28.4 vs the block's 35.83 / 0.089 / 28.5 — +0.52 mae, outside any jitter.**
     Cause: MainMenu is shot bare, and today `user://` holds no save (another agent's test run cleared it —
     the report's own 08:48 note), so "Continue" is DISABLED with "No saved guild found." inside the scored
     region `0,300,520,420`; the block's number was taken with a save present ("Continue — A Guild Story").
     The mainmenu baseline therefore depends on `user://` state the gate does not control. MINOR — the number
     is honest for the state it was taken in, but the block should say which state, or the target needs a
     deterministic save state (shot.gd is W0-SHOT's file). A later "does not regress" reading of mainmenu
     will otherwise see a 0.5 swing that is the save, not the art.
  4. `./tools/verify.sh --fast`: `LINT OK`, `MOTION LINT OK`, `PARSE_CHECK scanned 151 script(s)`,
     `16 generated file(s) agree`, `ART CHECK … 76 agree 0 DIFFERS 0 MISSING`, `TESTS PASSED 1604 test(s) in
     72 file(s) [33163 ms]`, `VERIFY OK` (09:02:09). `.verify.log`: 0 `survivors` lines, 0 `SCRIPT ERROR` lines.
     Observed by the reviewer, not copied from the report.

## 4. Acceptance lines

| Line | Met | Evidence |
|---|---|---|
| `diff_all.sh` prints 13 lines and exits 0 | yes (14 lines) | reviewer run 09:01:04: 14 target lines, rc 0; §0.3 lists 14 targets (kit + 13 screens incl. MainMenu); the unit recorded the discrepancy |
| the first honest numbers are in BUILD_STATE | yes | `BUILD_STATE.md:99-115` block; 11 of 14 match the on-disk jsons to two decimals, the rest inside the disclosed jitter — except mainmenu (see §3.3, save-state dependent) |
| `verify.sh --fast` stage 3 prints zero `'survivors'` lines and `TESTS PASSED` | yes | reviewer run: `TESTS PASSED 1604 test(s) in 72 file(s)`, `grep -c survivors .verify.log` = 0 |
| `grep -rn 'load("guildhall")' tools` is empty | yes | reviewer: no output, rc 1 |
| Kit.gd → `SceneStage.load("stage_camp")`, kit re-baselined | yes | `tools/probe/Kit.gd:74-76`; `review-W0-GATE-kit.png` viewed (camp plate under Concept-1 chrome); kit 16.94 → 25.20 recorded with the reason |
| `diff_all.sh TARGETS` gains §0.3's rows; RaidView/Results `--fixture=raid`; masks per §0.3 | yes | `tools/diff_all.sh:54-79`: SCENE_BAND `0,77,1536,649` on the seven Concept-3 rows, ARENA `210,77,928,640` on RaidPrep/RaidView/Results, `--fixture=raid` on RaidView/Results |
| `shot_all.sh` sheets: fixture/empty/focus/text150/emoji/reduced/wide-keep/wide-expand/tabs/raid-advanced/raid-clear with the plan's rows | yes | `tools/shot_all.sh:104-137` rows match the build notes verbatim (reduced = two passes; wide = 1820x1024; tabs = the five presses; raid-advanced = all + 10; raid-clear = `raid:clear`); 11 sheet dirs on disk, 125 tiles |
| a row whose flag shot.gd rejects (exit 2) prints SKIPPED and the sheet exits 0 | yes | dry run (§3): exit 2 → SKIPPED, rc 0; flag-less shot.gd → SKIPPED via the grep pre-check, rc 0; exit 1 → FAIL rc 1 |
| Shot: `shot_all.sh build/shots/all` and each new sheet, looked at | yes | eleven sheets present and 100 % post-settings-reset (`SETTINGS defaults` in every log); the reviewer re-took `tabs` and spot-viewed tabs/wide-keep/emoji/text150/raid-clear — every description in the report matches |
| Green: test stubs gain fields only; no screen touched | yes | the eight test diffs are the two `var` lines per stub and nothing else; no `game/` path in the unit's diff |

## 5. §0.5 / Green line checks

- No game/ file in the unit's diff; no PNG added, so no .import question; nothing parented to the router host;
  no tween, no `reduced_motion` branch, no `class_name` (the unit adds no GDScript beyond Kit.gd's constant and
  three lines). Label/Button texts and node names: untouched (no screen edited).
- `grep -rn 'load("guildhall")' tools` → empty (rc 1). Confirmed by the reviewer.
- Handoff: empty by design; the three cross-unit observations are in the report. Fine — none is an edit this
  unit needs.
- Indentation: Kit.gd tabs; tests four-space; verified on the inserted lines.

## 6. Judgement calls vs the plan

- 14 lines not 13: §0.3's target list is 14 (kit + 13 screens incl. MainMenu "vs 3 chrome-only") while the
  acceptance line and the wave-end sentence say 13. The unit printed 14 and recorded why. Not a designer
  question; defensible. Noted, not a fail.
- RaidPrep vs Concept 2 (was 1): §0.3's own table. Both numbers recorded. OK.
- MainMenu "chrome-only" = the menu column region rather than the scene-band mask, after looking at the shot.
  Tooling decision; W3-MENU is not pre-empted (no pixel of the menu changed). OK.
- Kit probe mirrors Town's `CAMP_OFFSET`. Tooling; RULES-16 says "stage_camp or whichever the kit owner picks". OK.
- Exit 12 → SKIPPED (not in the plan; the plan names only exit 2). Keeps `--sheet=all` green while the fixture
  is at Unknown, and the row prints shot.gd's reason. Cost: a tab that a future regression DISABLES will skip
  with a printed reason instead of failing — a small weakening of the gate. The report's "HALL-24 is blocked"
  justification is off (Q11/HALL-24 is about levels on cards, not the fixture's rank), but changing the fixture
  is W0-SHOT's file, not this unit's. MINOR; recorded.
- Nothing in §6 (designer-reserved) was decided by this unit.

## 7. Report claims checked against the tree

- "every tile in build/shots/all now comes from one shot.gd, mtime 08:43:07": FALSE for 16 tiles —
  `wide-expand/*` (13), `raid-advanced/*` (2), `raid-clear/*` (1) are older than `tools/shot.gd`
  (`find … ! -newer tools/shot.gd`; oldest 08:35:59). The substantive claim — the settings reset in force —
  holds: `SETTINGS defaults` is in 13/13, 2/2, 1/1 of those logs (every sheet 100 %). MINOR false claim.
- "14 numbers match build/diff/*_diff.json digit for digit": true of the 20:58 run the block records; the
  jsons on disk are the 08:37 re-run (kit 25.268, raidview 34.444, results 32.39 vs the block's 25.20 / 34.51 /
  32.36), which the block's jitter clause discloses. Honest.
- Spot-viewed the implementer's sheets (Read): `tabs/_sheet_1` (Facilities / Manage / Buy / Comfort, 4 tiles,
  no Records), `wide-keep/_sheet_1` (1820-wide, frame centred on dark bars, "Continue" disabled with "No saved
  guild found."), `emoji/_sheet_1` (pip strings "Bork — 87 ||||||||.", no faces, type at 100 %),
  `text150/_sheet_1` (150 % real: Town's header row clipped after "Day 23", sidebar prose past the panel edge,
  MainMenu's tagline over the wordmark), `raid-clear/_sheet_1` ("Cleared. / A0 — Adventure 0", Payout 4 G, the
  Cracked Charm row with "Sell 1 G" + a Give dropdown, Survivors 4 of 4). All match the report's descriptions.

## Verdict

**PASS** — every acceptance line is met on the tree as observed by the reviewer (14-line diff_all rc 0; the block in
BUILD_STATE; 0 `survivors` lines and `TESTS PASSED 1604`; the guildhall grep empty; the sheets on disk and re-taken).
No blocker; no designer-reserved decision taken; ownership clean; the handoff is empty by design.

Minors (for the orchestrator / the next owner, none requires a re-run of this unit):
1. `under_godot_lock` is a substring match on ancestor cmdlines — a Bash-tool command whose TEXT mentions
   `with_godot_lock` makes a sibling bare `./tools/diff_all.sh` or `./tools/shot_all.sh` skip the lock (reproduced).
   Harmless under the plan's grammar; a `GODOT_LOCK_HELD` marker exported by `with_godot_lock.sh` would make it exact.
2. Exit 12 → SKIPPED keeps `--sheet=all` green today but will also skip (with a printed reason) a tab that a
   future regression disables; the report's HALL-24 citation for "the fixture is at Unknown by design" is off
   (Q11 is about levels on cards).
3. The mainmenu baseline (35.83) was taken with a save in `user://`; without one it scores 36.35 (Continue
   disabled) — the block does not say so.
4. The jitter clause names kit/raidview/results; board (+0.06) and completion (+0.03) also move.
5. Report claim "every tile … from one shot.gd (mtime 08:43:07)" is false for the 16 wide-expand / raid-advanced /
   raid-clear tiles (older); the settings-reset claim behind it is true (100 % of logs).
6. `BUILD_STATE.md` and four test files are CRLF in the working copy against `eol=lf`; git normalises on commit
   (diff = the block / the stub lines only).
7. "13 lines" vs 14: the plan is inconsistent with itself; the unit chose §0.3's list and said so.
